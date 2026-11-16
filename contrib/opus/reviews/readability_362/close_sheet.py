"""Issue 362 job F: Eclipse close pictures for Ryan, one ship per page, every setting side by side at 1 to 1 pixels.

Usage: python3 close_sheet.py --before DIR --after DIR --out OUTDIR [--sky world] [--rows ROWS.json] [--tag close60]
  --before  a probe run of main (readability_probe.gd with --cam 60 --factions deathless); its variant "cur" is used
  --after   a probe run of the branch with variants (variants_f.json); every variant is used, in the file's order
  --rows    optional measure.py rows of the camera 170 run of the same variants: the lit side and edge on the darkest sky
            go under each picture (the band is judged at camera 170, the battle camera)
Writes OUTDIR/<tag>_<code>_<n>.jpg: 1280 wide, no taller than 720. Each picture is the ship cut out of its own crop
(the box round every setting's hull mask, plus a margin), never scaled. A hull cut wider than 632 pixels keeps its
middle 632, so two settings sit side by side; the label then says "middle".
"""
import argparse
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

BG = (14, 15, 18)
FG = (225, 228, 232)
DIM = (150, 155, 162)
PAGE_W, PAGE_H, HEAD, LAB, GAP, MARGIN, MAXW, MINW = 1280, 720, 36, 36, 8, 10, 632, 300
LABELS = {"cur": "main (before)", "e320": "now, lift 3.2", "e260": "lift 2.6", "e220": "lift 2.2", "e180": "lift 1.8",
          "e220_rim27": "lift 2.2, rim 0.27"}


def font(size):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "C:/Windows/Fonts/arial.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


FS, FB = font(13), font(18)


def stills(d, sky, variant=None):
    probe = json.load(open(os.path.join(d, "probe.json")))
    out = {}
    for st in probe["stills"]:
        if st["sky"] == sky and (variant is None or st["variant"] == variant) and st["what"].startswith("deathless|"):
            out.setdefault(st["variant"], {})[st["code"]] = os.path.join(d, st["file"])
    names = [v["name"] for v in probe["variants"]]
    return out, names, probe


def bbox(png):
    m = np.asarray(Image.open(png[:-4] + "_mask.png").convert("L")) > 100
    ys, xs = np.nonzero(m)
    return (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1) if xs.size else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--before", required=True)
    ap.add_argument("--after", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--sky", default="world")
    ap.add_argument("--rows")
    ap.add_argument("--tag", default="close60")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    bs, _, bp = stills(a.before, a.sky, "cur")
    av, names, ap_ = stills(a.after, a.sky)
    rows = {}
    if a.rows:
        for r in json.load(open(a.rows)):
            if r["sky"] == a.sky:
                rows[(r["variant"], r["code"])] = r
    cols = [("cur", bs.get("cur", {}))] + [(n, av.get(n, {})) for n in names]
    codes = list(av.get(names[0], {}))
    made = []
    for code in sorted(codes, key=lambda c: int(c[1:].split("_")[0])):
        files = [(n, v[code]) for n, v in cols if code in v]
        boxes = [b for b in (bbox(f) for _, f in files) if b]
        if not boxes:
            continue
        x0 = max(0, min(b[0] for b in boxes) - MARGIN)
        y0 = max(0, min(b[1] for b in boxes) - MARGIN)
        x1 = max(b[2] for b in boxes) + MARGIN
        y1 = max(b[3] for b in boxes) + MARGIN
        middle = False
        if x1 - x0 < MINW:   # room for the label: more sky either side, never a scaled ship
            cx = (x0 + x1) // 2
            x0, x1 = max(0, cx - MINW // 2), max(0, cx - MINW // 2) + MINW
        if x1 - x0 > MAXW:
            cx = (x0 + x1) // 2
            x0, x1, middle = cx - MAXW // 2, cx + MAXW // 2, True
        cw, chh = x1 - x0, y1 - y0
        per_row = max(1, (PAGE_W + GAP) // (cw + GAP))
        rows_per_page = max(1, (PAGE_H - HEAD) // (chh + LAB + GAP))
        per_page = per_row * rows_per_page
        for pi in range(0, len(files), per_page):
            chunk = files[pi:pi + per_page]
            nrows = (len(chunk) + per_row - 1) // per_row
            H = min(PAGE_H, HEAD + nrows * (chh + LAB + GAP))
            page = Image.new("RGB", (PAGE_W, H), BG)
            dr = ImageDraw.Draw(page)
            dr.text((8, 8), "Eclipse %s, camera %d, true pixels, %s sky%s" % (
                code, int(ap_.get("cam", 60)), a.sky, " (middle of the hull)" if middle else ""), font=FB, fill=FG)
            for i, (n, f) in enumerate(chunk):
                im = Image.open(f).convert("RGB")
                cut = im.crop((x0, y0, min(x1, im.width), min(y1, im.height)))
                x = (i % per_row) * (cw + GAP)
                y = HEAD + (i // per_row) * (chh + LAB + GAP)
                page.paste(cut, (x, y))
                dr.text((x + 2, y + chh + 2), LABELS.get(n, n), font=FS, fill=DIM if n == "cur" else FG)
                r = rows.get((n, code))
                if r:
                    dr.text((x + 2, y + chh + 18), "camera 170: lit %.0f, edge %.2f" % (r["lit"], r["edge"]), font=FS, fill=DIM)
            name = "%s_%s_%d.jpg" % (a.tag, code, pi // per_page + 1)
            page.save(os.path.join(a.out, name), quality=92)
            made.append(name)
    print("close pages", len(made), " ".join(made))


if __name__ == "__main__":
    main()
