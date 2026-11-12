"""Issue 362 job F: one picture for Ryan, the Eclipse ships at camera 60 (true pixels, never scaled), four columns.

Usage: python3 eclipse_cam60.py --before F60BEFORE_DIR --after F60_DIR --rows ROWS_F.json --out FILE.jpg
  columns: main (before), lift 3.2 (now), lift 2.2 (the pick), lift 1.8 (darker, out of the band)
  rows: D9, D20, D21 (a window round the hull's middle) and D22 the Tomb-ark (a window on its front right ring);
  each window is cut at 1 to 1 from the probe's 1440x840 crop at the same place in every column.
  The lit side and edge under each code are measure.py's numbers at camera 170 (the battle camera) on the darkest sky.
"""
import argparse
import json
import os

from PIL import Image, ImageDraw, ImageFont

BG = (14, 15, 18)
FG = (225, 228, 232)
DIM = (165, 170, 178)
RED = (235, 110, 100)
COLW, GAP, HEAD = 314, 8, 52
# code: (window centre x, centre y, height) in the 1440x840 crop; width is COLW
ROWS = [("D9_23", 719, 421, 70), ("D20_23", 719, 463, 220), ("D21_23", 719, 434, 180), ("D22_23", 1110, 560, 160)]
COLS = [("before", "cur", "main (before): old fix", None), ("after", "e320", "lift 3.2 (now)", "e320"),
        ("after", "e220", "lift 2.2 (pick)", "e220"), ("after", "e180", "lift 1.8 (out of band)", "e180")]


def font(size):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "C:/Windows/Fonts/arial.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def files(d):
    p = json.load(open(os.path.join(d, "probe.json")))
    return {(s["variant"], s["code"]): os.path.join(d, s["file"]) for s in p["stills"] if s["sky"] == "world"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--before", required=True)
    ap.add_argument("--after", required=True)
    ap.add_argument("--rows", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    src = {"before": files(a.before), "after": files(a.after)}
    meas = {(r["variant"], r["code"]): r for r in json.load(open(a.rows)) if r["sky"] == "world"}
    W = 4 * COLW + 3 * GAP
    H = HEAD + sum(r[3] for r in ROWS) + GAP * (len(ROWS) - 1)
    assert W <= 1280 and H <= 720, (W, H)
    page = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(page)
    fb, fs = font(17), font(13)
    dr.text((6, 4), "Eclipse at camera 60, true pixels, darkest sky (the Tomb-ark D22: its front right ring)", font=fb, fill=FG)
    for ci, (_, _, lab, _) in enumerate(COLS):
        dr.text((ci * (COLW + GAP) + 4, 30), lab, font=fs, fill=RED if "out of band" in lab else FG)
    y = HEAD
    for code, cx, cy, h in ROWS:
        box = (cx - COLW // 2, cy - h // 2, cx - COLW // 2 + COLW, cy - h // 2 + h)
        for ci, (side, var, _, mv) in enumerate(COLS):
            im = Image.open(src[side][(var, code)]).convert("RGB")
            x = ci * (COLW + GAP)
            page.paste(im.crop(box), (x, y))
            r = meas.get((mv, code)) if mv else None
            txt = code + ("   lit %.0f, edge %.2f" % (r["lit"], r["edge"]) if r else "")
            tw = dr.textlength(txt, font=fs)
            dr.rectangle((x, y, x + tw + 8, y + 17), fill=BG)
            dr.text((x + 4, y + 1), txt, font=fs, fill=RED if r and r["lit"] < 100 else DIM)
        y += h + GAP
    page.save(a.out, quality=92)
    print("saved", a.out, page.size)


if __name__ == "__main__":
    main()
