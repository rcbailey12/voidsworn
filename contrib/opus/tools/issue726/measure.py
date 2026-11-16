# Issue 726 (not a standing check): how big and pale the trophy patches read, on the A20 concept and on a painted A20 render at
# the sheet's fitted beauty camera. Thresholds fixed from the concept before any tuning:
#   ship     a render: its alpha (preview.py renders with a transparent film); a picture with no alpha: brightness over 16,
#            opened, closed, holes filled, the largest piece (the concept's black sky)
#   glow     red over 1.6 x blue and 1.4 x green and over 90 (engine glow, running lights), left out of everything
#   value    the mean of the brightest channel (HSV value, 0 to 255) over the ship
#   pale     saturation under 0.16 and value 110 or more; violet: blue over 1.15 x green, blue at least 0.95 x red, value 60 or more
#   patches  the pale and violet pixels opened by a 5 px square at 960 px wide (scrapes, bare edges and thin wear drop out), so
#            only plate-sized pieces count; area share of the ship, and the size of each piece as a share of the ship
# Every picture is scaled to 960 px wide first.
# usage: python measure.py NAME=PICTURE [NAME=PICTURE ...] [--json OUT]      (PICTURE may be PATH@x0,y0,x1,y1 to crop first)
import sys, json
import numpy as np
from PIL import Image
from scipy import ndimage as nd


def load(spec):
    box = None
    if '@' in spec: spec, b = spec.split('@'); box = tuple(int(v) for v in b.split(','))
    im = Image.open(spec)
    if box: im = im.crop(box)
    k = 960 / im.width; im = im.resize((960, max(1, round(im.height * k))), Image.LANCZOS)
    a = np.asarray(im.convert('RGBA')).astype(np.float64)
    return a[..., :3], (a[..., 3] > 127 if im.mode == 'RGBA' else None)


def ship_mask(rgb, alpha):
    if alpha is not None: return alpha
    m = rgb.mean(2) > 16; m = nd.binary_opening(m, iterations=2); m = nd.binary_closing(m, iterations=6); m = nd.binary_fill_holes(m)
    lab, n = nd.label(m); s = nd.sum(m, lab, range(1, n + 1)); return lab == (np.argmax(s) + 1)


def measure(rgb, alpha):
    ship = ship_mask(rgb, alpha); r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    V = rgb.max(2); sat = (V - rgb.min(2)) / np.maximum(V, 1)
    glow = (r > 1.6 * b) & (r > 1.4 * g) & (r > 90)
    s = ship & ~glow
    pale = s & (sat < .16) & (V >= 110)
    vio = s & (b > 1.15 * g) & (b >= .95 * r) & (V >= 60)
    st = np.ones((5, 5), bool)
    P = nd.binary_opening(pale, st); Vi = nd.binary_opening(vio, st); T = P | Vi
    lab, n = nd.label(T); sizes = np.sort(nd.sum(T, lab, range(1, n + 1)))[::-1] if n else np.zeros(0)
    N = float(s.sum())
    return dict(ship_px=int(N), mean_value=round(float(V[s].mean()), 1), median_value=round(float(np.median(V[s])), 1),
                pale_px_share=round(float(pale.sum() / N), 4), violet_px_share=round(float(vio.sum() / N), 4),
                patch_share=round(float(T.sum() / N), 4), pale_patch_share=round(float(P.sum() / N), 4), violet_patch_share=round(float(Vi.sum() / N), 4),
                patches=int(n), patch_size_median_pct=round(float(np.median(sizes) / N * 100), 3) if n else 0.0,
                patch_size_weighted_pct=round(float((sizes ** 2).sum() / max(sizes.sum(), 1) / N * 100), 3) if n else 0.0,
                largest10_mean_pct=round(float(sizes[:10].mean() / N * 100), 3) if n else 0.0)


if __name__ == '__main__':
    a = sys.argv[1:]; out = None
    if '--json' in a: i = a.index('--json'); out = a[i + 1]; a = a[:i] + a[i + 2:]
    res = {}
    for spec in a:
        name, path = spec.split('=', 1); res[name] = measure(*load(path)); print(name, res[name], flush=True)
    if out: json.dump(res, open(out, 'w'), indent=1)
