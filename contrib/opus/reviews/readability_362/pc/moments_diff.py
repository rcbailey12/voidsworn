"""Issue 362: did any effect or shield look change, or only the hulls? Runs on the PC (ComfyUI's portable Python: numpy, Pillow).

Usage: python moments_diff.py --before RUN --after RUN --out DIR [--tol 2.0]
RUN: a look bench run made with --part moments (bench.json, moments.json, moments/<id>_<cam>.png strips).

The readability pass changes hull materials and adds a light that only hulls see, so a hull is expected to differ in every
moment. What must not differ is everything else: shells, beams, hits, smoke, flashes, shields, the sky. For each strip:
  hull mask   the pixels that differ (more than 6 levels in any channel) in the strip's first cell, which every row takes
              before its effect starts (hulls and sky only), grown by 3 pixels: where the hulls are
  diff        the bench's own number: mean absolute difference over every pixel and channel (0 to 255)
  off_hull    the same mean over the pixels outside the hull mask only
  changed     how many pixels outside the hull mask differ by more than 12 levels
Writes DIR/moments_diff.csv (one row per cell), DIR/moments_worst.jpg (the 16 cells with the largest off_hull: before,
after, and the difference with the hull mask in blue) and prints a summary per group.
"""
import argparse
import csv
import json
import os

import numpy as np
from PIL import Image, ImageDraw


def cells_of(path, cell, n):
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.int16)
    return [a[:, i * cell[0]:(i + 1) * cell[0]] for i in range(min(n, a.shape[1] // cell[0]))]


def grow(m, k):
    out = m.copy()
    for dy in range(-k, k + 1):
        for dx in range(-k, k + 1):
            out |= np.roll(np.roll(m, dy, 0), dx, 1)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--before", required=True)
    ap.add_argument("--after", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--tol", type=float, default=2.0)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    rb = json.load(open(os.path.join(a.before, "bench.json")))
    ra = json.load(open(os.path.join(a.after, "bench.json")))
    mom = json.load(open(os.path.join(a.after, "moments.json")))
    cell = tuple(mom.get("cell", [384, 216]))
    group = {r["id"]: r["group"] for r in mom["rows"]}
    sb = {(s["id"], s["cam"]): s for s in rb["stills"] if s.get("part") == "moments"}
    rows, worst = [], []
    for s in ra["stills"]:
        if s.get("part") != "moments" or (s["id"], s["cam"]) not in sb:
            continue
        n = len(s.get("cells", []))
        A = cells_of(os.path.join(a.after, s["file"]), cell, n)
        B = cells_of(os.path.join(a.before, sb[(s["id"], s["cam"])]["file"]), cell, n)
        if not A or not B:
            continue
        hull = grow(np.abs(A[0] - B[0]).max(2) > 6, 3)
        for i, (ca, cb) in enumerate(zip(A, B)):
            d = np.abs(ca - cb)
            off = ~hull
            row = {"id": s["id"], "group": group.get(s["id"], ""), "cam": s["cam"], "cell": i,
                   "diff": round(float(d.mean()), 3), "off_hull": round(float(d[off].mean()) if off.any() else 0.0, 3),
                   "changed": int((d.max(2) > 12)[off].sum()), "hull_share": round(float(hull.mean()), 3)}
            rows.append(row)
            worst.append((row["off_hull"], row, cb, ca, d, hull))
    with open(os.path.join(a.out, "moments_diff.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    groups = sorted(set(r["group"] for r in rows))
    lines = []
    for g in groups:
        gr = [r for r in rows if r["group"] == g]
        lines.append("%-28s cells %4d  diff over tol %4d  max diff %6.2f  off_hull over tol %3d  max off_hull %5.2f  mean off_hull %5.3f" % (
            g, len(gr), sum(r["diff"] > a.tol for r in gr), max(r["diff"] for r in gr), sum(r["off_hull"] > a.tol for r in gr),
            max(r["off_hull"] for r in gr), sum(r["off_hull"] for r in gr) / len(gr)))
    open(os.path.join(a.out, "summary.txt"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))
    worst.sort(key=lambda t: -t[0])
    top = worst[:16]
    W, H = cell[0] * 3 + 12, (cell[1] + 20) * len(top)
    sheet = Image.new("RGB", (W, max(H, 1)), (14, 15, 18))
    dr = ImageDraw.Draw(sheet)
    for k, (v, row, cb, ca, d, hull) in enumerate(top):
        y = k * (cell[1] + 20)
        dr.text((4, y + 3), "%s cam %d cell %d   diff %.2f   off hull %.2f   changed px %d" % (row["id"], row["cam"], row["cell"], row["diff"], v, row["changed"]), fill=(225, 228, 232))
        dm = np.clip(d.max(2) * 4, 0, 255).astype(np.uint8)
        vis = np.stack([dm, dm, dm], 2)
        vis[hull] = (vis[hull] * 0.5).astype(np.uint8) + np.array([0, 0, 90], np.uint8)
        for j, im in enumerate([cb.astype(np.uint8), ca.astype(np.uint8), vis]):
            sheet.paste(Image.fromarray(im), (j * (cell[0] + 6), y + 20))
    sheet.save(os.path.join(a.out, "moments_worst.jpg"), quality=88)


if __name__ == "__main__":
    main()
