"""Compose issue 1076's stamped sheets and compress its frame-locked clips."""

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[2] / "tools"))
from picture_provenance import Review, verify

STAGE = "installed in game"
BACKGROUND = "#101923"
INK = "#edf3f7"
MUTED = "#b5c7d4"
ACCENT = "#f3ac79"
LABELS = {
    "fitted": "Fitted shield hit",
    "egg": "Egg shield hit",
    "failure": "Shield failure",
    "macro": "Macro shell on hull",
    "lance": "Lance on hull",
    "stage1": "Stage 1 / 80%",
    "stage2": "Stage 2 / 60%",
    "stage3": "Stage 3 / 40%",
    "stage4": "Stage 4 / 20%",
    "fatal": "Fatal torpedo hit",
    "tell": "Power loss and chain blasts",
    "split": "Hull separation",
    "wreck": "Cooling wreck",
    "cold": "After cooling",
}
TILES = tuple(key for key in LABELS if key not in {"tell", "cold"})
STORM = [("calm", "Calm"), ("lightning", "Ambient lightning"), ("tick", "Shield-drain flare"), ("reduced", "Reduced lightning")]


def font(size, bold=False):
    win_fonts = Path(os.environ["WINDIR"]) / "Fonts"
    return ImageFont.truetype(str(win_fonts / ("segoeuib.ttf" if bold else "segoeui.ttf")), size)


def center_crop(image, width, height):
    x = (image.width - width) // 2
    y = (image.height - height) // 2
    return image.crop((x, y, x + width, y + height))


def caption(draw, x, y, label, message_font):
    width = int(message_font.getlength(label)) + 16
    draw.rectangle((x, y, x + width, y + 23), fill=BACKGROUND)
    draw.text((x + 8, y + 2), label, font=message_font, fill=INK)


def stamped_input(review, path, commit):
    source = verify(path)
    if source["source_commit"] != commit or source["source_dirty"] or source["stage"] != STAGE:
        raise ValueError(f"Wrong source on {path.name}")
    return review.open(path)


def moment_label(key, subject):
    if subject["shielded"]:
        return LABELS[key]
    absent = {"egg": "Egg setting / hull hit", "fitted": "Fitted setting / hull hit", "failure": "No shield to fail"}
    return absent.get(key, LABELS[key])


def ship_sheet(folder, pictures, data, egg_first):
    row = json.loads((folder / "timeline.json").read_text())
    if len(row["stages"]) != 4 or not all(key in row["stills"] for key in LABELS):
        raise ValueError(f"Incomplete capture in {folder.name}")
    subject = data_subject(data, row["subject"]["id"])
    radius = row["radius"]
    reduced = row["reduced"]
    mode = "Reduced flashing" if reduced else "Standard flashing"
    revision = data["source_commit"][:12]
    plate = Image.new("RGB", (1280, 720), BACKGROUND)
    draw = ImageDraw.Draw(plate)
    title_font, detail_font, label_font = font(25, True), font(17), font(16, True)
    draw.text((14, 7), f'{subject["id"]}  {subject["name"]}  /  {mode}', fill=INK, font=title_font)
    draw.text((1265, 13), f'Radius {radius}', fill=ACCENT, font=detail_font, anchor="ra")
    review = Review(STAGE)
    tiles = (("egg", "fitted") + TILES[2:]) if egg_first else TILES
    for index, key in enumerate(tiles):
        x = 10 + index % 3 * 422
        y = 43 + index // 3 * 144
        source = stamped_input(review, folder / (key + ".png"), data["source_commit"])
        if radius == 170:
            tile = center_crop(source, 416, 140)
        else:
            tile = center_crop(source, 1920, 646).resize((416, 140), Image.Resampling.LANCZOS)
        plate.paste(tile, (x, y))
        caption(draw, x, y, moment_label(key, subject), label_font)
    draw.text((572, 640), f'Installed hull     {subject["code"]}/{subject["code"]}.glb', fill=INK, font=detail_font)
    draw.text((572, 666), f'Commit {revision}    |    Manifest {data["manifest_sha256"][:12]}', fill=MUTED, font=detail_font)
    scale = "Native-pixel crops from the 1080p battle view" if radius == 170 else "Centered crops from the close view"
    draw.text((572, 691), scale, fill=MUTED, font=detail_font)
    output = pictures / f'BATTLE1076_{folder.name}.jpg'
    review.save(plate, output, quality=93, subsampling=0)
    verify(output)
    return row


def ffmpeg_path():
    if os.environ.get("FFMPEG"):
        return os.environ["FFMPEG"]
    import imageio_ffmpeg

    return imageio_ffmpeg.get_ffmpeg_exe()


def data_subject(data, subject_id):
    return next(subject for subject in data["subjects"] if subject["id"] == subject_id)


def clip(out, source, rows, data):
    subject = data_subject(data, rows[0]["subject"]["id"])
    radius = rows[0]["radius"]
    title = font(23, True)
    detail = font(16)
    revision = data["source_commit"]
    manifest = data["manifest_sha256"]
    comment = f'Source {revision}; manifest {manifest}; installed hull {subject["code"]}/{subject["code"]}.glb'
    command = [
        ffmpeg_path(), "-hide_banner", "-loglevel", "error", "-y", "-f", "rawvideo", "-pixel_format", "rgb24",
        "-video_size", "1280x720", "-framerate", "30", "-i", "-", "-an", "-c:v", "libx264", "-preset", "fast",
        "-threads", "4", "-crf", "22", "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-metadata", f"comment={comment}",
        str(out / f'BATTLE1076_{subject["id"]}_c{radius}.mp4'),
    ]
    with subprocess.Popen(command, stdin=subprocess.PIPE) as encoder:
        for row in rows:
            variant = "reduced" if row["reduced"] else "standard"
            folder = source / f'{subject["id"]}_c{radius}_{variant}'
            marker = 0
            chapters = row["chapters"]
            for index in range(row["frames"]):
                while marker + 1 < len(chapters) and index >= chapters[marker + 1]["frame"]:
                    marker += 1
                key = chapters[marker]["name"]
                label = moment_label(key, subject)
                with Image.open(folder / f"frame_{index:04d}.jpg") as saved:
                    image = saved.convert("RGB")
                draw = ImageDraw.Draw(image)
                draw.rectangle((0, 0, 1280, 66), fill=BACKGROUND)
                draw.text((14, 6), f'{subject["id"]}  {subject["name"]}  /  {variant.title()} flashing', font=title, fill=INK)
                draw.text((14, 36), label, font=detail, fill=ACCENT)
                draw.text((1266, 9), f'Radius {radius}  |  {subject["code"]}/{subject["code"]}.glb', font=detail, fill=INK, anchor="ra")
                draw.text((1266, 35), f'{revision[:12]}  |  Manifest {manifest[:12]}', font=detail, fill=MUTED, anchor="ra")
                pixels = image.tobytes()
                encoder.stdin.write(pixels)
                if index == row["frames"] - 1:
                    for _ in range(20):
                        encoder.stdin.write(pixels)
        encoder.stdin.close()
        if encoder.wait():
            raise RuntimeError("FFmpeg failed to encode a review clip")


def storm_sheets(source, pictures, data):
    stats = json.loads((source / "storm.json").read_text())
    commit = data["source_commit"]
    for index, patch in enumerate(stats["patches"], start=1):
        review = Review(STAGE)
        page = Image.new("RGB", (1280, 720), BACKGROUND)
        draw = ImageDraw.Draw(page)
        draw.text((13, 7), f'Ion storm / Patch {index} / {patch["hexes"]} storm hexes', font=font(25, True), fill=INK)
        for tile, (key, name) in enumerate(STORM):
            x, y = 10 + tile % 2 * 632, 44 + tile // 2 * 287
            image = stamped_input(review, source / f"storm_{index:02d}_{key}.png", commit)
            page.paste(center_crop(image, 626, 280), (x, y))
            caption(draw, x, y, name, font(17, True))
        code = stats["subject"]["code"]
        draw.text((572, 638), f'Seed {stats["seed"]}  |  {stats["storm_hexes"]} storm and {stats["nebula_hexes"]} nebula hexes', font=font(17), fill=INK)
        draw.text((572, 663), f'Radius 170  |  {commit[:12]}  |  Manifest {data["manifest_sha256"][:12]}', font=font(17), fill=MUTED)
        draw.text((572, 687), f'Installed hull     {code}/{code}.glb', font=font(17), fill=MUTED)
        output = pictures / f"BATTLE1076_storm_{index:02d}.jpg"
        review.save(page, output, quality=93, subsampling=0)
        verify(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scratch", type=Path)
    parser.add_argument("pictures", type=Path)
    parser.add_argument("clips", type=Path)
    parser.add_argument("--close", type=int, choices=[26, 60], default=26)
    parser.add_argument("--only", choices=["A16", "IM5", "E11", "storm"])
    parser.add_argument("--egg-first", action="store_true")
    args = parser.parse_args()
    args.pictures.mkdir(parents=True, exist_ok=True)
    args.clips.mkdir(parents=True, exist_ok=True)
    data = json.loads((HERE / "ships.json").read_text())
    if args.only in {None, "storm"}:
        storm_sheets(args.scratch, args.pictures, data)
    for subject in data["subjects"]:
        if args.only not in {None, subject["id"]}:
            continue
        for radius in (170, args.close):
            rows = [ship_sheet(args.scratch / f'{subject["id"]}_c{radius}_{variant}', args.pictures, data, args.egg_first)
                    for variant in ("standard", "reduced")]
            clip(args.clips, args.scratch, rows, data)


if __name__ == "__main__":
    main()
