"""Build and verify the two review sheets from the second capture pass."""

import argparse
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO / "tools"))
from picture_provenance import Review, stamp_file, verify


SETUPS = (
    ("today", "Today's light", "Battle baseline"),
    ("bright_sky", "Brighter sky", "512 map, brighter reflections"),
    ("nebula_map", "Nebula reflections", "Brighter gas and two stars"),
    ("edge_light", "Cool edge light", "A light behind the hull"),
    ("light_strip", "Pale light strip", "A broad reflected band"),
)
GLASS_ROWS = (
    ("I8_37", 170, 0, "Radius 170", "Side 1"),
    ("I8_37", 170, 1, "Radius 170", "Side 2"),
    ("I8_37", 26, 0, "Radius 26", "Side 1 detail"),
    ("I8_37", 26, 1, "Radius 26", "Side 2 detail"),
)
CONTROL_ROWS = (
    ("C19_51", 170, 0, "C19_51", "Radius 170"),
    ("B21_11", 170, 0, "C11", "Radius 170"),
    ("C19_51", 26, 0, "C19_51", "Radius 26 detail"),
    ("B21_11", 26, 0, "C11", "Radius 26 detail"),
)
FONT = Path("C:/Windows/Fonts")
STAGE = "installed in game"
WIDTH, HEIGHT = 1920, 720
CELL = 350
CELL_X = 128
GAP = 8


def write(draw, text, point, size, color="#ede8dd", bold=False):
    face = FONT / ("segoeuib.ttf" if bold else "segoeui.ttf")
    draw.text(point, text, fill=color, font=ImageFont.truetype(str(face), size))


def cell(image, height, zoom=1.0, x=960, y=540):
    width, crop_height = round(CELL * zoom), round(height * zoom)
    left, top = x - width // 2, y - crop_height // 2
    crop = image.crop((left, top, left + width, top + crop_height))
    if zoom != 1.0:
        return crop.resize((CELL, height), Image.Resampling.LANCZOS)
    return crop


def load_frames(path):
    with Image.open(path) as image:
        if image.size != (1920, 1080):
            raise ValueError(f"Expected a native 1080p frame: {path}")
        return image.convert("RGB")


def check_captures(frames):
    for side in (0, 1):
        baseline = load_frames(frames / f"sky_today_s{side}.png")
        for key, _, _ in SETUPS[1:]:
            other = load_frames(frames / f"sky_{key}_s{side}.png")
            diff = ImageChops.difference(baseline, other)
            maximum = max(high for _, high in diff.getextrema())
            print(f"Sky side {side + 1}, {key}: maximum channel difference {maximum}")
            if maximum != 0:
                raise ValueError("The visible sky changed between setups")
    for code, radius, side, _, _ in GLASS_ROWS + CONTROL_ROWS:
        baseline = load_frames(frames / f"{code}_today_r{radius}_s{side}.png")
        for key, _, _ in SETUPS[1:]:
            other = load_frames(frames / f"{code}_{key}_r{radius}_s{side}.png")
            diff = ImageChops.difference(baseline, other)
            print(f"{code} r{radius} side {side + 1} {key}: mean RGB delta "
                  f"{sum(ImageStat.Stat(diff.crop((700, 425, 1220, 655))).mean) / 3:.2f}")
            if diff.getbbox() is None:
                raise ValueError(f"{code} did not respond to {key}")


def read_picture(review, frames, name):
    path = frames / f"{name}.png"
    stamp_file(path, STAGE, REPO)
    return review.open(path).convert("RGB")


def sheet(frames, destination, glass):
    review = Review(STAGE)
    canvas = Image.new("RGB", (WIDTH, HEIGHT), "#101820")
    draw = ImageDraw.Draw(canvas)
    title = "CD5  The Unfinished / I8_37" if glass else "C19_51  Metal  |  C11  Chitin / B21_11"
    write(draw, title, (15, 6), 25, bold=True)
    for col, (key, name, description) in enumerate(SETUPS):
        x = CELL_X + (CELL + GAP) * col
        write(draw, name, (x, 38), 19, "#edc68e", True)
        write(draw, description, (x, 63), 14, "#bdc9d2")
        rows = GLASS_ROWS if glass else CONTROL_ROWS
        height = 108 if glass else 125
        for row, (code, radius, side, row_name, detail) in enumerate(rows):
            y = 84 + (height + 5) * row
            frame = read_picture(review, frames, f"{code}_{key}_r{radius}_s{side}")
            zoom = 1.0 if radius == 170 else 2.35
            x_center = 950 if code == "C19_51" else 960
            y_center = 542 if code == "B21_11" else 540
            canvas.paste(cell(frame, height, zoom, x_center, y_center), (x, y))
            if col == 0:
                write(draw, row_name, (15, y + 24), 16, bold=True)
                write(draw, detail, (15, y + 47), 14, "#bdc9d2")
        if glass:
            frame = read_picture(review, frames, f"I8_37_{key}_reference")
            canvas.paste(cell(frame, 84, 2.80), (x, 535))
    if glass:
        write(draw, "Plain glass", (15, 557), 16, bold=True)
        write(draw, "Rod + sphere", (15, 580), 14, "#bdc9d2")
    name = "CD5_lighting.jpg" if glass else "C19_51_C11_lighting.jpg"
    target = destination / name
    record = review.save(canvas, target, quality=94, subsampling=0)
    if record["stamp_box"][1] < 619:
        raise ValueError("Provenance stamp overlaps a comparison frame")
    verify(target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("frames", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    check_captures(args.frames)
    sheet(args.frames, args.destination, glass=True)
    sheet(args.frames, args.destination, glass=False)


if __name__ == "__main__":
    main()
