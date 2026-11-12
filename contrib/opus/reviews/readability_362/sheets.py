"""Issue 362: the before and after sheets from two readability probe runs, and the per-ship table.

Usage: python3 sheets.py --before DIR --after DIR --rows-before B.json --rows-after A.json --out OUTDIR
  DIR: a probe run (readability_probe.gd); its variant "cur" is used. rows: measure.py output for that run.
Writes, in OUTDIR:
  fleet_<sky>_before_after.jpg   the bench fleet sheet, before and after side by side, every cell 1 to 1 (400x240), the
                                 lit side, edge and clip numbers under each pair (bench layout: 3 pairs a row)
  phone_<sky>_<n>.jpg            for Ryan's phone: 1280 wide, no taller than 720, ships cut out of their own cell at 1 to 1
                                 pixels (never scaled), before on the left half and after on the right half in the same
                                 places; capitals do not fit two to a half, so they get one page before and one page after
  table.md                       per ship and sky: lit side, edge, clip, halo and lines, before and after, band marks
"""
import argparse
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

BG = (14, 15, 18)
FG = (225, 228, 232)
DIM = (150, 155, 162)
RED = (235, 90, 80)
GREEN = (120, 205, 130)
BAND = (100.0, 190.0)
EDGE_MIN = 0.60
CLIP_MAX = 0.02
NAMES = {"voidsworn": "Sunward Crusade", "corsair": "Ashfall Hullbreakers", "ithar": "Glasswrights", "deathless": "Eclipse",
         "chorus": "Chorus", "hegemony": "Hegemony Navy", "craft": "craft", "obj": "object"}
CAPITAL = {"Super-dreadnought", "Dreadnought", "Battle-barge", "Bio-titan", "Ark", "Tomb-ark"}


def font(size):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "C:/Windows/Fonts/arial.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


F = font(14)
FS = font(12)
FB = font(19)


def cur_rows(path):
    return {(r["sky"], r["code"]): r for r in json.load(open(path)) if r["variant"] == "cur"}


def in_band(r):
    return BAND[0] <= r.get("lit", 0) <= BAND[1]


def fleet_sheet(a, rb, ra, sky, out):
    items = [r for (s, c), r in ra.items() if s == sky]
    items.sort(key=lambda r: r["file"])
    cw, ch, lab = 400, 240, 40
    per = 3
    unit = cw * 2 + 6
    rows_n = (len(items) + per - 1) // per
    W = per * (unit + 8)
    H = 44 + rows_n * (ch + lab + 8)
    sheet = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(sheet)
    lv = {"world": "darkest sky (world region, 19.7)", "frontier": "brightest sky (frontier region, 50.3)",
          "storm": "storm map (64.8)"}.get(sky, sky)
    dr.text((8, 10), "Issue 362: fleet at the battle camera (170), true pixel size, %s.  Each pair: BEFORE (main) | AFTER.  "
            "Band for the lit side: %d to %d." % (lv, BAND[0], BAND[1]), font=FB, fill=FG)
    for i, r in enumerate(items):
        x = (i % per) * (unit + 8)
        y = 44 + (i // per) * (ch + lab + 8)
        b = rb.get((sky, r["code"]))
        ia = Image.open(os.path.join(a.after, r["file"])).convert("RGB")
        if b is not None:
            ib = Image.open(os.path.join(a.before, b["file"])).convert("RGB")
            sheet.paste(ib, (x, y + lab))
        sheet.paste(ia, (x + cw + 6, y + lab))
        dr.text((x + 4, y + 2), "%s  %s %s" % (r["code"], NAMES.get(r["faction"], r["faction"]), r["class"]), font=F, fill=FG)
        if b is not None:
            dr.text((x + 4, y + 20), "lit %.0f  edge %.2f  clip %.3f  halo %.0f" % (b["lit"], b["edge"], b["clip"], b.get("halo", 0)),
                    font=FS, fill=(GREEN if in_band(b) else RED) if r["faction"] not in ("craft", "obj") else DIM)
        dr.text((x + cw + 10, y + 20), "lit %.0f  edge %.2f  clip %.3f  halo %.0f" % (r["lit"], r["edge"], r["clip"], r.get("halo", 0)),
                font=FS, fill=(GREEN if in_band(r) else RED) if r["faction"] not in ("craft", "obj") else DIM)
    sheet.save(os.path.join(out, "fleet_%s_before_after.jpg" % sky), quality=90)


def cutout(run_dir, r, pad=14):
    """the ship cut out of its own cell at 1 to 1 with its glow, its edge feathered into the page's sky (alpha)"""
    im = Image.open(os.path.join(run_dir, r["file"])).convert("RGB")
    mk = Image.open(os.path.join(run_dir, r["file"][:-4] + "_mask.png")).convert("L")
    x0, y0, x1, y1 = r["bbox"]
    box = (max(0, x0 - pad), max(0, y0 - pad), min(im.width, x1 + pad + 1), min(im.height, y1 + pad + 1))
    a = mk.crop(box).point(lambda v: 255 if v > 100 else 0).filter(ImageFilter.MaxFilter(17)).filter(ImageFilter.GaussianBlur(3))
    c = im.crop(box).convert("RGBA")
    c.putalpha(a)
    return c


def shelf(boxes, width, gap=8, label=16):
    """places (w, h) boxes left to right in rows; returns positions and the height"""
    pos, x, y, rowh = [], 0, 0, 0
    for w, h in boxes:
        if x > 0 and x + w > width:
            x, y, rowh = 0, y + rowh + gap, 0
        pos.append((x, y))
        x += w + gap
        rowh = max(rowh, h + label)
    return pos, y + rowh


def sky_canvas(run_dir, rows, sky, size):
    """the sky behind the ships: the open sky of the craft cell (a 2 pixel fighter), tiled"""
    c = [r for r in rows.values() if r["sky"] == sky and r["code"] == "S1_51"]
    tile = Image.open(os.path.join(run_dir, c[0]["file"])).convert("RGB") if c else Image.new("RGB", (400, 240), (8, 8, 10))
    # blank out the fighter itself (its cell centre)
    arr = np.asarray(tile).copy()
    arr[105:135, 185:215] = arr[10:40, 10:40]
    tile = Image.fromarray(arr)
    can = Image.new("RGB", size)
    for j, yy in enumerate(range(0, size[1], tile.height)):
        for i, xx in enumerate(range(0, size[0], tile.width)):
            t = tile.transpose(Image.FLIP_LEFT_RIGHT) if i % 2 else tile
            t = t.transpose(Image.FLIP_TOP_BOTTOM) if j % 2 else t
            can.paste(t, (xx, yy))   # mirrored tiles: no seams
    return can


def phone_pages(a, rb, ra, sky, out):
    items = [r for (s, c), r in ra.items() if s == sky and r["faction"] != "obj" or (s == sky and r["code"] in ("O2_37", "O3_11"))]
    items.sort(key=lambda r: r["file"])
    small = [r for r in items if r["class"] not in CAPITAL]
    caps = [r for r in items if r["class"] in CAPITAL]
    order = {"Frigate": 0, "fighter": 0, "bomber": 0, "spore": 0, "Destroyer": 1, "Cruiser": 2, "Carrier": 3, "Battleship": 4,
             "transport": 5, "beacon": 5}
    small.sort(key=lambda r: (order.get(r["class"], 9), r["file"]))
    pages = []
    # side by side pages: left half before, right half after, same places
    half = 632
    group, groups = [], []
    for r in small:
        trial = group + [r]
        _, h = shelf([(cutout(a.after, x).width, cutout(a.after, x).height) for x in trial], half)
        if h > 720 - 50 and group:
            groups.append(group)
            group = [r]
        else:
            group = trial
    if group:
        groups.append(group)
    for g in groups:
        cuts_a = [cutout(a.after, r) for r in g]
        cuts_b = [cutout(a.before, rb[(sky, r["code"])]) for r in g]
        boxes = [(max(ca.width, cb.width), max(ca.height, cb.height)) for ca, cb in zip(cuts_a, cuts_b)]
        pos, h = shelf(boxes, half)
        H = min(720, h + 50)
        page = sky_canvas(a.after, ra, sky, (1280, H))
        dr = ImageDraw.Draw(page)
        dr.rectangle((0, 0, 1280, 36), fill=BG)
        dr.rectangle((638, 36, 641, H), fill=BG)
        dr.text((8, 8), "BEFORE (main)", font=FB, fill=FG)
        dr.text((650, 8), "AFTER (issue 362)", font=FB, fill=FG)
        dr.text((330, 12), "camera 170, true pixel size, %s" % sky, font=FS, fill=DIM)
        for r, (x, y), cb, ca in zip(g, pos, cuts_b, cuts_a):
            for img, x0 in ((cb, 4), (ca, 648)):
                page.paste(img, (x0 + x, 42 + y), img)
                dr.text((x0 + x, 42 + y + img.height), r["code"], font=FS, fill=DIM)
        pages.append(page)
    # capitals: one page before, one after, the same places
    if caps:
        cuts = {r["code"]: (cutout(a.before, rb[(sky, r["code"])]), cutout(a.after, r)) for r in caps}
        boxes = [(max(cuts[r["code"]][0].width, cuts[r["code"]][1].width), max(cuts[r["code"]][0].height, cuts[r["code"]][1].height)) for r in caps]
        pos, h = shelf(boxes, 1272)
        for k, title in ((0, "BEFORE (main): capitals"), (1, "AFTER (issue 362): capitals")):
            H = min(720, h + 50)
            page = sky_canvas(a.after, ra, sky, (1280, H))
            dr = ImageDraw.Draw(page)
            dr.rectangle((0, 0, 1280, 36), fill=BG)
            dr.text((8, 8), title, font=FB, fill=FG)
            dr.text((420, 12), "camera 170, true pixel size, %s" % sky, font=FS, fill=DIM)
            for r, (x, y) in zip(caps, pos):
                img = cuts[r["code"]][k]
                page.paste(img, (4 + x, 42 + y), img)
                dr.text((4 + x, 42 + y + img.height), r["code"], font=FS, fill=DIM)
            pages.append(page)
    for i, p in enumerate(pages):
        p.save(os.path.join(out, "phone_%s_%d.jpg" % (sky, i + 1)), quality=88)
    return len(pages)


def table(rb, ra, out):
    lines = ["| Ship | Faction | Class | Sky | Lit before | Lit after | Edge before | Edge after | Clip after | Halo before | Halo after | Lines before | Lines after |",
             "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for sky in ("world", "frontier", "storm"):
        for (s, c), r in sorted(ra.items(), key=lambda kv: kv[1]["file"]):
            if s != sky:
                continue
            b = rb.get((s, c), {})
            mark = "" if r["faction"] in ("craft", "obj") else (" ok" if in_band(r) else " OUT")
            lines.append("| %s | %s | %s | %s | %.0f | %.0f%s | %.2f | %.2f | %.3f | %.0f | %.0f | %.0f | %.0f |" % (
                c, NAMES.get(r["faction"], r["faction"]), r["class"], sky, b.get("lit", 0), r["lit"], mark, b.get("edge", 0),
                r["edge"], r["clip"], b.get("halo", 0), r.get("halo", 0), b.get("lines", 0), r["lines"]))
    open(os.path.join(out, "table.md"), "w").write("\n".join(lines) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--before", required=True)
    ap.add_argument("--after", required=True)
    ap.add_argument("--rows-before", required=True)
    ap.add_argument("--rows-after", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--phone-sky", default="world")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    rb, ra = cur_rows(a.rows_before), cur_rows(a.rows_after)
    for sky in ("world", "frontier", "storm"):
        if any(s == sky for s, _ in ra):
            fleet_sheet(a, rb, ra, sky, a.out)
    n = phone_pages(a, rb, ra, a.phone_sky, a.out)
    table(rb, ra, a.out)
    print("sheets done, phone pages", n)


if __name__ == "__main__":
    main()
