"""Issue 281 vent review clips and contact sheets.

The vent probe (godot/fx/test/vent_look_probe.gd) writes one raw RGB frame per captured step plus clip.json, and the
stills the sheet is built from. This script turns each raw folder into a short MP4 (H.264, 640x360, 12 fps) and lays
the stills out on one contact sheet per camera range, with plain labels. It needs Pillow and imageio-ffmpeg (both
installed on Ryan's PC); without ffmpeg it falls back to a Pillow GIF.

  python godot/fx/test/vent_clip.py RAW_OUT [DEST]

RAW_OUT is the VENT_OUT folder the probe wrote (or $VENT_OUT). DEST defaults to RAW_OUT/deliver. Writes:
  DEST/clips/<label>_<range>.mp4     a few seconds, 12 fps, 640x360
  DEST/vent_sheet_close.png          the quality pick: every variant, five moments, close range
  DEST/vent_sheet_battle.png         the same at the battle camera (readability at distance)
  DEST/clips.json                    frame counts and file sizes
"""
import glob
import json
import os
import shutil
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw, ImageFont

VARIANTS = [
    ("before", "before (today)"),
    ("after", "after (Cone B)"),
]
COLUMNS = [
    ("macro_muzzle", "macro salvo (muzzle)"),
    ("macro_hit", "macro hull hit"),
    ("hull_hit", "heavy hull hit"),
]
CELL_W, CELL_H = 384, 216
ROW_LABEL_W = 210
PAD = 10
HEADER_H = 78
CAPTION_H = 30


def font(size):
    for path in ("C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            pass
    return ImageFont.load_default()


def load_clip(folder):
    meta = json.load(open(os.path.join(folder, "clip.json"), encoding="utf-8"))
    w, h = int(meta["w"]), int(meta["h"])
    frames = sorted(glob.glob(os.path.join(folder, "frame_*.rgb")))
    imgs = []
    for f in frames:
        raw = np.fromfile(f, dtype=np.uint8)
        if raw.size != w * h * 3:
            continue
        imgs.append(Image.fromarray(raw.reshape(h, w, 3), "RGB").resize((640, 360), Image.LANCZOS))
    return meta, imgs


def find_ffmpeg():
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        return shutil.which("ffmpeg")


def mp4_from_raw(ffmpeg, folder, meta, path):
    w, h = int(meta["w"]), int(meta["h"])
    fps = int(meta.get("fps", 12))
    tmp = tempfile.mkdtemp(prefix="vent_clip_")
    try:
        n = 0
        for f in sorted(glob.glob(os.path.join(folder, "frame_*.rgb"))):
            raw = np.fromfile(f, dtype=np.uint8)
            if raw.size != w * h * 3:
                continue
            im = Image.fromarray(raw.reshape(h, w, 3), "RGB").resize((640, 360), Image.LANCZOS)
            im.save(os.path.join(tmp, "frame_%05d.png" % n))
            n += 1
        subprocess.run([ffmpeg, "-y", "-v", "error", "-framerate", str(fps),
                        "-i", os.path.join(tmp, "frame_%05d.png"),
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20",
                        "-movflags", "+faststart", path], check=True)
        return n
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def make_clips(root, dest):
    clips_dir = os.path.join(dest, "clips")
    os.makedirs(clips_dir, exist_ok=True)
    ffmpeg = find_ffmpeg()
    rows = []
    for folder in sorted(glob.glob(os.path.join(root, "raw_*"))):
        if not os.path.isfile(os.path.join(folder, "clip.json")):
            continue
        meta, imgs = load_clip(folder)
        if not imgs:
            continue
        name = os.path.basename(folder).replace("raw_", "")
        if ffmpeg:
            path = os.path.join(clips_dir, name + ".mp4")
            n = mp4_from_raw(ffmpeg, folder, meta, path)
        else:
            # no ffmpeg: a Pillow GIF is bigger but still shows the motion
            path = os.path.join(clips_dir, name + ".gif")
            duration = max(40, int(round(1000.0 / float(meta.get("fps", 12)))))
            imgs[0].save(path, save_all=True, append_images=imgs[1:], duration=duration, loop=0,
                         optimize=True, disposal=1)
            n = len(imgs)
        rows.append({"clip": os.path.basename(path), "frames": n, "bytes": os.path.getsize(path),
                     "label": meta.get("label"), "range": meta.get("range"), "look": meta.get("look")})
        print("[clip] %s %d frames %.1f KB" % (path, n, os.path.getsize(path) / 1024.0))
    with open(os.path.join(dest, "clips.json"), "w", encoding="utf-8") as f:
        json.dump(rows, f, indent=2)


def sheet(stills, dest, range_name, title, suffix=""):
    cols = len(COLUMNS)
    width = PAD * 2 + ROW_LABEL_W + cols * (CELL_W + PAD)
    height = PAD * 2 + HEADER_H + len(VARIANTS) * (CELL_H + CAPTION_H + PAD)
    img = Image.new("RGB", (width, height), (14, 14, 18))
    d = ImageDraw.Draw(img)
    f_title = font(26)
    f_head = font(17)
    f_row = font(19)
    f_cap = font(15)
    d.text((PAD, PAD), title, font=f_title, fill=(235, 235, 240))
    for c, (_, label) in enumerate(COLUMNS):
        x = PAD + ROW_LABEL_W + c * (CELL_W + PAD)
        d.text((x, PAD + 40), label, font=f_head, fill=(170, 200, 230))
    for r, (key, label) in enumerate(VARIANTS):
        y = PAD + HEADER_H + r * (CELL_H + CAPTION_H + PAD)
        d.text((PAD, y + CELL_H // 2 - 10), label, font=f_row, fill=(225, 225, 230))
        for c, (kind, _) in enumerate(COLUMNS):
            x = PAD + ROW_LABEL_W + c * (CELL_W + PAD)
            path = os.path.join(stills, "%s_%s_%s%s.png" % (key, range_name, kind, suffix))
            if os.path.isfile(path):
                im = Image.open(path).convert("RGB").resize((CELL_W, CELL_H), Image.LANCZOS)
                img.paste(im, (x, y))
            else:
                d.rectangle([x, y, x + CELL_W - 1, y + CELL_H - 1], outline=(70, 70, 80))
                d.text((x + 10, y + 10), "missing", font=f_cap, fill=(160, 80, 80))
            d.text((x, y + CELL_H + 6), "%s / %s" % (key, kind.replace("_", " ")), font=f_cap,
                   fill=(150, 150, 160))
    out = os.path.join(dest, "vent_sheet_%s.png" % range_name)
    img.save(out)
    print("[sheet] %s %dx%d" % (out, width, height))


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    root = sys.argv[1]
    dest = sys.argv[2] if len(sys.argv) > 2 else os.path.join(root, "deliver")
    os.makedirs(dest, exist_ok=True)
    make_clips(root, dest)
    stills = os.path.join(root, "stills")
    sheet(stills, dest, "close", "Issue 281: vent gas before/after, close crop on the vent (Cone B)", "_crop")
    sheet(stills, dest, "battle", "Issue 281: vent gas before/after at the battle camera (Cone B)")
    print("CLIPS_DONE")


if __name__ == "__main__":
    main()
