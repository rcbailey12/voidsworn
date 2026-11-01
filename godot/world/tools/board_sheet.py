"""Comparison sheets for the board look trial (world/board_look.gd).

    python3 board_sheet.py SHOTS_DIR OUT_DIR [setting ...]

SHOTS_DIR holds world_shots.gd --looks captures (<setting>_<look>_1_default.jpg and _2_zoomed_out.jpg). Writes, per
setting, <setting>_looks.jpg (five rows: today, A, B, C, C tactical; battle camera left, zoomed out right) and
all_battle_camera.jpg (every setting side by side, battle camera only).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

LOOKS = [("today", "TODAY"), ("holo", "A  HOLO WAR-TABLE"), ("living", "B  LIVING TERRAIN"), ("cine", "C  CINEMATIC (default view)"),
         ("tac", "C  TACTICAL GRID UP (Z key or Grid button)")]
SETTINGS = ["frontier_belt", "nebula_storm", "deadstar"]
NICE = {"frontier_belt": "Frontier belt", "nebula_storm": "Nebula storm", "deadstar": "Dead star"}


def font(size):
    for f in ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "DejaVuSans-Bold.ttf"]:
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def label(im, text, size):
    d = ImageDraw.Draw(im)
    f = font(size)
    box = d.textbbox((0, 0), text, font=f)
    d.rectangle([0, 0, box[2] + 16, box[3] + 12], fill=(0, 0, 0))
    d.text((8, 4), text, font=f, fill=(255, 255, 255))


def cell(path, w, h):
    if os.path.exists(path):
        return Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS)
    im = Image.new("RGB", (w, h), (40, 0, 0))
    label(im, "missing: " + os.path.basename(path), 20)
    return im


def main():
    src, out = sys.argv[1], sys.argv[2]
    sets = sys.argv[3:] or SETTINGS
    os.makedirs(out, exist_ok=True)
    W, H = 960, 540
    for s in sets:
        sheet = Image.new("RGB", (W * 2, H * len(LOOKS)))
        for row, (lk, name) in enumerate(LOOKS):
            for col, (sh, cam) in enumerate([("1_default", "battle camera"), ("2_zoomed_out", "zoomed out")]):
                im = cell(os.path.join(src, "%s_%s_%s.jpg" % (s, lk, sh)), W, H)
                label(im, "%s   %s" % (name, cam), 24)
                sheet.paste(im, (col * W, row * H))
        sheet.save(os.path.join(out, "%s_looks.jpg" % s), quality=88)
    w, h = 640, 360
    sheet = Image.new("RGB", (w * len(sets), h * len(LOOKS)))
    for col, s in enumerate(sets):
        for row, (lk, name) in enumerate(LOOKS):
            im = cell(os.path.join(src, "%s_%s_1_default.jpg" % (s, lk)), w, h)
            label(im, "%s  %s" % (NICE.get(s, s), name.split("(")[0].strip()), 17)
            sheet.paste(im, (col * w, row * h))
    sheet.save(os.path.join(out, "all_battle_camera.jpg"), quality=88)


if __name__ == "__main__":
    main()
