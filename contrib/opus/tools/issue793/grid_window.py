# Issue 793: issue 738's grid.py with the azimuth and elevation search held to a window (AZ_LO, AZ_HI, EL_LO, EL_HI, degrees; env), for a concept whose
# outline alone is ambiguous (KB1C-C's front-above view also fits a craft turned side-on); otherwise unchanged.
# coarse camera grid for fit.py (it only refines): for each view angle, the blockout's outline is scaled and moved onto the
# mask's box and scored (IoU); the best angle is turned into a fit.py camera (dist 60, the lens and shift that frame it)
# usage: python grid.py TRIS.npz MASK.png OUT_CAMERA.json   (then fit.py TRIS MASK BEAUTY OUT OUT_CAMERA.json --fit)
import sys, json, math, numpy as np
from PIL import Image, ImageDraw
T = np.load(sys.argv[1])['tris'].astype(float)
T = T[np.random.default_rng(0).choice(len(T), min(len(T), 40000), replace=False)]
mask = np.asarray(Image.open(sys.argv[2]).convert('L').resize((384, 256))) > 127
H, W = mask.shape
ys, xs = np.where(mask); mb = (xs.min(), ys.min(), xs.max(), ys.max())


def basis(az, el, roll):
    a, e = math.radians(az), math.radians(el)
    d = np.array([math.cos(e) * math.cos(a), math.cos(e) * math.sin(a), math.sin(e)])
    f = -d; right = np.cross(f, [0, 0, 1]); right /= np.linalg.norm(right); up = np.cross(right, f)
    rr = math.radians(roll)
    right, up = right * math.cos(rr) + up * math.sin(rr), up * math.cos(rr) - right * math.sin(rr)
    return d, f, right, up


def score(az, el, roll, dist=60.0):
    d, f, r, u = basis(az, el, roll)
    loc = d * dist
    P = T.reshape(-1, 3) - loc
    zc = P @ f; x = (P @ r) / zc; y = -(P @ u) / zc
    x0, x1, y0, y1 = x.min(), x.max(), y.min(), y.max()
    s = min((mb[2] - mb[0]) / (x1 - x0), (mb[3] - mb[1]) / (y1 - y0))
    u_ = (x - x0) * s + mb[0]; v_ = (y - y0) * s + mb[1]
    im = Image.new('L', (W, H), 0); dr = ImageDraw.Draw(im)
    for t in np.stack([u_, v_], 1).reshape(-1, 3, 2):
        dr.polygon([tuple(p) for p in t], fill=255)
    rr = np.asarray(im) > 127
    return (rr & mask).sum() / max(1, (rr | mask).sum()), s, x0, y0


best = None
import os
for az in range(int(os.environ.get('AZ_LO', 0)), int(os.environ.get('AZ_HI', 360)), 5):
    for el in range(int(os.environ.get('EL_LO', 10)), int(os.environ.get('EL_HI', 59)), 4):
        for roll in (-30, -20, -10, 0, 10, 20, 30):
            sc = score(az, el, roll)
            if best is None or sc[0] > best[0][0]:
                best = (sc, az, el, roll)
print('coarse', best)
sc, az, el, roll = best
for daz in (-5, -2.5, 0, 2.5, 5):
    for de in (-4, -2, 0, 2, 4):
        for dr_ in (-5, -2.5, 0, 2.5, 5):
            s2 = score(az + daz, el + de, roll + dr_)
            if s2[0] > best[0][0]:
                best = (s2, az + daz, el + de, roll + dr_)
print('fine', best)
(iou, s, x0, y0), az, el, roll = best
# a fit.py camera: the image is 1536 x 1024; scale s maps normalised coordinates to 384-px pixels, so f(px, full) = 4 s
Wf, Hf = 1536, 1024
fpx = 4 * s
mm = fpx / Wf * 36.0
# u = W/2 + fpx * x + sx * W; we want u(x0) = 4 * mb[0]
sx = (4 * mb[0] - Wf / 2 - fpx * x0) / Wf
sy = -(4 * mb[1] - Hf / 2 - fpx * y0) / Wf
json.dump(dict(az=az, el=el, roll=roll, dist=60.0, mm=mm, target=[0.0, 0.0, 0.0], sx=sx, sy=sy, res=[Wf, Hf]), open(sys.argv[3], 'w'), indent=1)
print('camera', sys.argv[3], 'iou', iou)
