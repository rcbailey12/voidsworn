"""Comparison sheets for the board look trial (world/board_look.gd).

    python3 board_sheet.py SHOTS_DIR OUT_DIR [setting ...]

    python3 board_sheet.py --ba BEFORE_DIR AFTER_DIR OUT_DIR [setting ...]

Step 2 (--ba): before and after look C for every setting. Writes <setting>_ba.jpg (rows before, after; columns battle
camera, zoomed out, tactical grid up), all_before_after.jpg (every setting at the battle camera, before left, after
right) and, when AFTER_DIR has world_shots --terrain shots, terrain_close.jpg.

SHOTS_DIR holds world_shots.gd --looks captures (<setting>_<look>_1_default.jpg and _2_zoomed_out.jpg). Writes, per
setting, <setting>_looks.jpg (five rows: today, A, B, C, C tactical; close, battle camera, zoomed out) and
all_battle_camera.jpg (every setting side by side, battle camera only).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

LOOKS = [("today", "TODAY"), ("holo", "A  HOLO WAR-TABLE"), ("living", "B  LIVING TERRAIN"), ("cine", "C  CINEMATIC (default view)"),
         ("tac", "C  TACTICAL GRID UP (Z key or Grid button)")]
SETTINGS = ["frontier_belt", "nebula_storm", "deadstar"]
ALL = ["frontier_belt", "frontier_station", "nebula_storm", "nebula_crystal_belt", "world_planet", "world_belt_ice",
       "boneyard_graveyard", "deep_storm", "open_iron", "deadstar"]
NICE = {"frontier_belt": "Frontier belt", "nebula_storm": "Nebula storm", "deadstar": "Dead star",
        "frontier_station": "Frontier station", "nebula_crystal_belt": "Nebula crystal belt", "world_planet": "World planet",
        "world_belt_ice": "World ice belt", "boneyard_graveyard": "Boneyard graveyard", "deep_storm": "Deep storm",
        "open_iron": "Open iron"}


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


def before_after(bdir, adir, out, sets):
    os.makedirs(out, exist_ok=True)
    W, H = 800, 450
    cols = [("cine_1_default", "battle camera"), ("cine_2_zoomed_out", "zoomed out"), ("tac_1_default", "tactical grid up (Z)")]
    for s in sets:
        sheet = Image.new("RGB", (W * len(cols), H * 2))
        for row, (d, tag) in enumerate([(bdir, "BEFORE"), (adir, "AFTER")]):
            for col, (sh, cam) in enumerate(cols):
                im = cell(os.path.join(d, "%s_%s.jpg" % (s, sh)), W, H)
                label(im, "%s  %s  %s" % (tag, NICE.get(s, s), cam), 18)
                sheet.paste(im, (col * W, row * H))
        sheet.save(os.path.join(out, "%s_ba.jpg" % s), quality=86)
    w, h = 640, 360
    sheet = Image.new("RGB", (w * 2, h * len(sets)))
    for row, s in enumerate(sets):
        for col, (d, tag) in enumerate([(bdir, "BEFORE"), (adir, "AFTER")]):
            im = cell(os.path.join(d, "%s_cine_1_default.jpg" % s), w, h)
            label(im, "%s  %s" % (tag, NICE.get(s, s)), 16)
            sheet.paste(im, (col * w, row * h))
    sheet.save(os.path.join(out, "all_before_after.jpg"), quality=86)
    tiles = []
    for s in sets:
        for kind, nm in [("neb", "nebula"), ("storm", "ion storm"), ("debris", "debris")]:
            f = os.path.join(adir, "%s_cine_4_%s.jpg" % (s, kind))
            if os.path.exists(f):
                tiles.append((f, "%s  %s close" % (NICE.get(s, s), nm)))
    if tiles:
        n = 3
        sheet = Image.new("RGB", (W * n, H * ((len(tiles) + n - 1) // n)))
        for i, (f, t) in enumerate(tiles):
            im = cell(f, W, H)
            label(im, t, 18)
            sheet.paste(im, ((i % n) * W, (i // n) * H))
        sheet.save(os.path.join(out, "terrain_close.jpg"), quality=86)


def main():
    if sys.argv[1] == "--ba":
        before_after(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5:] or ALL)
        return
    src, out = sys.argv[1], sys.argv[2]
    sets = sys.argv[3:] or SETTINGS
    os.makedirs(out, exist_ok=True)
    W, H = 800, 450
    shots = [("3_close", "close"), ("1_default", "battle camera"), ("2_zoomed_out", "zoomed out")]
    for s in sets:
        sheet = Image.new("RGB", (W * len(shots), H * len(LOOKS)))
        for row, (lk, name) in enumerate(LOOKS):
            for col, (sh, cam) in enumerate(shots):
                im = cell(os.path.join(src, "%s_%s_%s.jpg" % (s, lk, sh)), W, H)
                label(im, "%s   %s" % (name.split("(")[0].strip(), cam), 20)
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
