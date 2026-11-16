# Issue 781 (R256, Ryan Nov 15 2026: S8 paint "Lighten a step"): the hull tone of the S8 concept and of the painted S8, at the
# sheet's fitted camera and at the battle camera (34 degrees, the camera issue 756's audits.py measured). Sandbox only, not a
# standing check.
#   fitted   the painted ship's own silhouette at the fitted beauty camera (paint_beauty.png, the camera fitted to the concept)
#            (its dark plates kept: the holes filled) and the concept's own silhouette, both eroded 10 pixels: the median of the concept's pixels and of the paint's pixels inside
#            it, the ember light left out of both (the same hot test as audits.py)
#   battle   the painted ship at the battle camera (paint_battle.png), the ember left out: audits.py's figure
#   target   halfway from the battle median before (the 2048 bake of PR 772, (26,27,28)) to the concept's fitted median
# usage: python measure.py PREVIEW_DIR OUT_JSON [before=26,27,28] [erode=10] [overlay=PATH]     (python with numpy and Pillow)
import os, sys, json
import numpy as np
from PIL import Image

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
PV, OUT = sys.argv[1], sys.argv[2]
kw = dict(x.split('=', 1) for x in sys.argv[3:] if '=' in x)
ERODE = int(kw.get('erode', 10))
BEFORE = [int(v) for v in kw.get('before', '26,27,28').split(',')]
CONCEPT = os.path.join(REPO, 'contrib/codex/design/concept_round5_2026_11/voidsworn_S8_beauty.jpg')


def hot(a):
    return (a[..., 0] > a[..., 2] * 1.6) & (a[..., 0] > 90)       # the ember light, not the iron (audits.py)


con = Image.open(CONCEPT).convert('RGB')
bea = Image.open(os.path.join(PV, 'paint_beauty.png')).convert('RGB').resize(con.size, Image.LANCZOS)
b = np.asarray(bea).astype(np.float64); c = np.asarray(con).astype(np.float64)
from scipy import ndimage
sil = ndimage.binary_fill_holes(ndimage.binary_closing(b.max(2) > 10, iterations=8))    # the silhouette, its dark plates kept
sil = ndimage.binary_erosion(sil, iterations=ERODE)
# and the concept's own silhouette (off its local background), so no background between the prongs or at the edge counts
L = c.mean(2); bg = ndimage.median_filter(L[::8, ::8], size=25); bg = np.kron(bg, np.ones((8, 8)))[:L.shape[0], :L.shape[1]]
cs = ndimage.binary_opening(ndimage.binary_fill_holes(ndimage.binary_closing(np.abs(L - bg) > 14, iterations=6)), iterations=4)
lab, n = ndimage.label(cs); cs = lab == (1 + int(np.argmax(ndimage.sum(cs, lab, range(1, n + 1)))))     # the flagship, not the escort
m = sil & ndimage.binary_erosion(cs, iterations=ERODE) & ~hot(b) & ~hot(c)
res = dict(fitted=dict(px=int(m.sum()), concept_median=[int(v) for v in np.median(c[m], 0)],
                       paint_median=[int(v) for v in np.median(b[m], 0)]))
a = np.asarray(Image.open(os.path.join(PV, 'paint_battle.png')).convert('RGB')).astype(np.float64)
s = (a.max(2) > 10) & ~hot(a)
res['battle'] = dict(px=int(s.sum()), paint_median=[int(v) for v in np.median(a[s], 0)])
res['before_battle_2048'] = BEFORE
res['target_battle'] = [int(round((x + y) / 2)) for x, y in zip(BEFORE, res['fitted']['concept_median'])]
if kw.get('overlay'):        # the mask laid on the concept in green, to check it sits on the ship
    o = c * .6; o[m] = o[m] * .5 + np.array([0, 255, 0]) * .5
    Image.fromarray(o.clip(0, 255).astype(np.uint8)).resize((c.shape[1] * 3 // 4, c.shape[0] * 3 // 4)).save(kw['overlay'], quality=88)
json.dump(res, open(OUT, 'w'), indent=1)
print(json.dumps(res))
