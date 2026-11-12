"""Issue 362: measure each hull's brightness from the readability probe's fleet stills (camera 170, 1 to 1 pixels).

Usage: python3 measure.py PROBE_DIR [PROBE_DIR ...] --out rows.json
Each PROBE_DIR is a probe run (readability_probe.gd): <variant>/<sky>/<nn>_<code>.png with <nn>_<code>_mask.png beside it.

The numbers (the band and the rules are stated in docs/shots/look_bench/readability/README.md before any change):
  level      luminance of a pixel, 0 to 255, Rec. 709 weights on the sRGB values as drawn (what the eye sees on screen)
  hull       the mask's pixels (the hull drawn unshaded white, everything else black): mask level over 100
  lit        the hull's lit side: the mean level of its interior pixels (hull eroded by one pixel, so no pixel is half sky)
             from the 75th to the 98th percentile (the brightest quarter, the top 2 percent of specks left out)
  clip       share of hull pixels with any channel at 250 or more (burnt out to white)
  edge       share of the hull's outline pixels (the hull minus its one-pixel erosion) at least 12 levels brighter than
             the sky just outside it (the median level of the ring 2 to 4 pixels out)
  body       median level of the interior minus the median level of the sky ring (how far the hull stands off the sky)
  lines      standard deviation of the interior levels (how much line and panel detail is left; a burnt-out hull is flat)
"""
import argparse
import json
import os
import re
import sys

import numpy as np
from PIL import Image

LUMA = np.array([0.2126, 0.7152, 0.0722])


def shift_or(m, k):
    out = m.copy()
    for dy in range(-k, k + 1):
        for dx in range(-k, k + 1):
            out |= np.roll(np.roll(m, dy, 0), dx, 1)
    return out


def erode(m, k=1):
    return ~shift_or(~m, k)


def measure(png, mask_png):
    c = np.asarray(Image.open(png).convert("RGB")).astype(float)
    mk = np.asarray(Image.open(mask_png).convert("L")).astype(float)
    hull = mk > 100
    n = int(hull.sum())
    y = c @ LUMA
    row = {"px": n}
    if n == 0:
        return row
    ys, xs = np.nonzero(hull)
    row["w"] = int(xs.max() - xs.min() + 1)
    row["h"] = int(ys.max() - ys.min() + 1)
    inner = erode(hull, 1)
    if inner.sum() < 8:
        inner = hull
    outline = hull & ~erode(hull, 1)
    ring = shift_or(hull, 4) & ~shift_or(hull, 1)
    sky = float(np.median(y[ring])) if ring.any() else 0.0
    vi = y[inner]
    p75, p98 = np.percentile(vi, [75, 98])
    top = vi[(vi >= p75) & (vi <= p98)]
    row["lit"] = round(float(top.mean() if top.size else vi.max()), 1)
    row["median"] = round(float(np.median(vi)), 1)
    row["clip"] = round(float((c[hull].max(1) >= 250).mean()), 4)
    row["sky"] = round(sky, 1)
    row["edge"] = round(float((y[outline] >= sky + 12).mean()), 3) if outline.any() else 0.0
    row["body"] = round(float(np.median(vi)) - sky, 1)
    row["lines"] = round(float(vi.std()), 1)
    row["bbox"] = [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]
    return row


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dirs", nargs="+")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    rows = []
    for d in a.dirs:
        probe = json.load(open(os.path.join(d, "probe.json")))
        for st in probe["stills"]:
            png = os.path.join(d, st["file"])
            mpng = png[:-4] + "_mask.png"
            if not (os.path.exists(png) and os.path.exists(mpng)):
                continue
            fac, cls = st["what"].split("|")
            r = {"run": os.path.basename(os.path.normpath(d)), "variant": st["variant"], "sky": st["sky"],
                 "code": st["code"], "faction": fac, "class": cls, "file": st["file"]}
            r.update(measure(png, mpng))
            rows.append(r)
    json.dump(rows, open(a.out, "w"), indent=1)
    print("rows", len(rows))


if __name__ == "__main__":
    sys.exit(main())
