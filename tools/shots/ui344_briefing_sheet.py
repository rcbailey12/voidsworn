"""Issue #344, the campaign map's Briefing layout (FINDINGS R165): the committed stills and the before and after sheet.

Usage: python3 -I tools/shots/ui344_briefing_sheet.py <capture folder with 1080/ and 1440/> <repo root>
Writes docs/shots/ui_redesign/briefing/1080/*.jpg and 1440/*.jpg (the PC captures, as jpg), the two reached files, and
docs/shots/ui_redesign/briefing/before_after.jpg: rollout 1's map (docs/shots/ui_redesign/rollout1/1080/01_map.jpg)
beside the new map at the same moment of the same seeded run, at 1080, then the picked mockup beside the new map with
three next jumps. Only reads the capture folder and the two reference pictures; writes only under the briefing folder.
"""
import os
import shutil
import sys
from PIL import Image, ImageDraw, ImageFont

NAMES = ["01_map_jump0", "02_map_three_routes", "02b_route_two_picked", "03_far_stop_hover", "03b_nemesis_stop_hover",
         "04_dossier", "05_map_key", "06_damaged_fleet"]
BG = (9, 12, 9)
LIME = (200, 245, 58)
SAGE = (232, 238, 224)
DIM = (124, 134, 116)


def main():
    src, root = sys.argv[1], sys.argv[2]
    out = os.path.join(root, "docs", "shots", "ui_redesign", "briefing")
    fdir = os.path.join(root, "godot", "ui", "theme", "fonts")
    head = ImageFont.truetype(os.path.join(fdir, "ChakraPetch-Bold.ttf"), 44)
    cap = ImageFont.truetype(os.path.join(fdir, "ChakraPetch-SemiBold.ttf"), 30)
    small = ImageFont.truetype(os.path.join(fdir, "ChakraPetch-Regular.ttf"), 24)
    have = {}
    for res in ("1080", "1440"):
        os.makedirs(os.path.join(out, res), exist_ok=True)
        d = os.path.join(src, res)
        if not os.path.isdir(d):
            continue
        for name in NAMES:
            p = os.path.join(d, name + ".png")
            if os.path.exists(p):
                im = Image.open(p).convert("RGB")
                im.save(os.path.join(out, res, name + ".jpg"), quality=88, optimize=True)
                have.setdefault(res, {})[name] = im
        r = os.path.join(d, "reached.txt")
        if os.path.exists(r):
            shutil.copyfile(r, os.path.join(out, "reached_%s.txt" % res))
    shots = have.get("1080", {})
    before = os.path.join(root, "docs", "shots", "ui_redesign", "rollout1", "1080", "01_map.jpg")
    mock = os.path.join(root, "contrib", "opus", "ui_map_design", "map_option_C_briefing.jpg")
    if "01_map_jump0" not in shots or not os.path.exists(before):
        print("no 1080 map capture or no rollout 1 map; no sheet")
        return 1
    pw, ph, m, gap, cap_h = 1920, 1080, 48, 40, 64
    rows = [[(Image.open(before).convert("RGB"), "BEFORE  rollout 1, the first jump of the seeded run (the picture Ryan called busy)", DIM),
             (shots["01_map_jump0"], "AFTER  the Briefing layout, the same moment of the same run (real game capture on Ryan's PC)", LIME)]]
    if "02_map_three_routes" in shots and os.path.exists(mock):
        rows.append([(Image.open(mock).convert("RGB"), "THE PICK  Ryan's option C, the flat mockup of the layout", DIM),
                     (shots["02_map_three_routes"], "AFTER  the same layout over the real 3D map, one jump in, three routes to pick from", LIME)])
    W = m * 2 + pw * 2 + gap
    H = m + 70 + len(rows) * (ph + cap_h + gap) + 30
    sheet = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(sheet)
    dr.text((m, m - 12), "EMBERS OF THE HOLLOW SUN  CAMPAIGN MAP: BEFORE AND AFTER (THE BRIEFING LAYOUT, 1920x1080)", font=head, fill=SAGE)
    y = m + 70
    for row in rows:
        x = m
        for im, text, col in row:
            if im.size != (pw, ph):
                im = im.resize((pw, ph), Image.LANCZOS)
            sheet.paste(im, (x, y))
            dr.rectangle([x, y, x + pw - 1, y + ph - 1], outline=col if col == LIME else (40, 50, 40), width=3 if col == LIME else 1)
            dr.text((x, y + ph + 14), text, font=cap, fill=col if col == LIME else SAGE)
            x += pw + gap
        y += ph + cap_h + gap
    miss = [n for n in NAMES if n not in shots]
    dr.text((m, H - 40), "Not captured on this run: " + (", ".join(miss) if miss else "none") + ".", font=small, fill=DIM)
    sheet.save(os.path.join(out, "before_after.jpg"), quality=88, optimize=True)
    print("sheet", sheet.size, "pictures", len(shots), "missing", miss)
    return 0


if __name__ == "__main__":
    sys.exit(main())
