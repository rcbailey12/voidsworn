# Outline fit for build sheets (issue 532). Plain python with numpy, scipy and Pillow (no Blender).
#   python fit.py <tris.npz> <beauty mask png> <beauty jpg> <out prefix> [camera json to start from] [--fit]
# Projects the blockout's triangles through a pinhole camera (the same camera build.py's look_cam makes), fills them,
# scores the overlap with the beauty's cut-out (intersection over union, the recipe's outline gate measure) and, with
# --fit, searches the camera only (never the ship) to the best overlap. Writes <out>_overlay.jpg and <out>_camera.json.
import sys, json, math
import numpy as np
from PIL import Image, ImageDraw
from scipy.optimize import minimize

trisf, maskf, beautyf, outp = sys.argv[1:5]
start = sys.argv[5] if len(sys.argv) > 5 and not sys.argv[5].startswith('--') else None
T = np.load(trisf)['tris'].astype(float)
mask_full = Image.open(maskf).convert('L')
W, H = mask_full.size
S = 4  # work at a quarter size
mask = np.asarray(mask_full.resize((W // S, H // S))) > 127


def basis(az, el, roll):
    a, e = math.radians(az), math.radians(el)
    d = np.array([math.cos(e) * math.cos(a), math.cos(e) * math.sin(a), math.sin(e)])
    f = -d; right = np.cross(f, [0, 0, 1]); right /= np.linalg.norm(right); up = np.cross(right, f)
    rr = math.radians(roll)
    right, up = right * math.cos(rr) + up * math.sin(rr), up * math.cos(rr) - right * math.sin(rr)
    return d, f, right, up


def project(c, w, h, tri=None):
    d, f, right, up = basis(c['az'], c['el'], c.get('roll', 0))
    loc = np.array(c['target']) + d * c['dist']
    P = (T if tri is None else tri).reshape(-1, 3) - loc
    zc = P @ f; xc = P @ right; yc = P @ up
    fpx = c['mm'] / 36.0 * w  # sensor fit horizontal
    u = w / 2 + fpx * (xc / zc) + c.get('sx', 0) * w
    v = h / 2 - fpx * (yc / zc) - c.get('sy', 0) * w
    return np.stack([u, v], 1).reshape(-1, 3, 2)


def raster(c, w, h):
    im = Image.new('L', (w, h), 0); dr = ImageDraw.Draw(im)
    for tri in project(c, w, h):
        dr.polygon([tuple(p) for p in tri], fill=255)
    return np.asarray(im) > 127


def iou(c):
    r = raster(c, W // S, H // S)
    return (r & mask).sum() / max(1, (r | mask).sum()), r


c = json.load(open(start)) if start else dict(az=48.0, el=28.0, roll=0.0, dist=60.0, mm=70.0, target=[0.5, 0.0, 0.0], sx=0.0, sy=0.0, res=[W, H])
c['res'] = [W, H]
if '--fit' in sys.argv:
    keys = ['az', 'el', 'roll', 'mm', 'sx', 'sy', 'dist']
    x0 = np.array([c[k] for k in keys])
    scale = np.array([3, 3, 2, 8, 0.02, 0.02, 8])
    if "--fix-angles" in sys.argv:  # hold the view angles and fit the framing only
        keys = ["mm", "sx", "sy", "dist"]; scale = np.array([8, 0.02, 0.02, 8]); x0 = np.array([c[k] for k in keys])

    def obj(x):
        cc = dict(c); cc.update({k: float(v) for k, v in zip(keys, x0 + x * scale)})
        return -iou(cc)[0]
    best = None
    for trial in range(2):
        r = minimize(obj, np.zeros(len(keys)), method='Nelder-Mead', options=dict(maxiter=300, xatol=1e-3, fatol=1e-5, initial_simplex=np.vstack([np.zeros(len(keys)), np.eye(len(keys))])))
        x0 = x0 + r.x * scale
        c.update({k: float(v) for k, v in zip(keys, x0)})
        print('pass', trial, 'iou', -r.fun)
score, r = iou(c)
from scipy.ndimage import binary_opening
st = np.ones((7, 7), bool)
mb, rbody = binary_opening(mask, st), binary_opening(r, st)
body = (mb & rbody).sum() / max(1, (mb | rbody).sum())
print('BODY IOU %.4f (thin parts under 7 px at quarter size, about 28 px full size, removed from both outlines)' % body)
c['iou'] = round(float(score), 4); c['body_iou'] = round(float(body), 4)
print('IOU %.4f' % score, json.dumps({k: (round(v, 4) if isinstance(v, float) else v) for k, v in c.items()}))
json.dump(c, open(outp + '_camera.json', 'w'), indent=1)
# overlay: beauty dimmed, concept outline cyan, blockout outline orange
b = Image.open(beautyf).convert('RGB')
rb = Image.fromarray((raster(c, W, H) * 255).astype('uint8'))
from PIL import ImageFilter
edge = np.asarray(rb.filter(ImageFilter.FIND_EDGES)) > 0
medge = np.asarray(mask_full.filter(ImageFilter.FIND_EDGES)) > 0
a = np.asarray(b).astype(float) * 0.75
k = np.ones((3, 3))
from scipy.ndimage import binary_dilation
a[binary_dilation(medge, iterations=2)] = (0, 220, 255)
a[binary_dilation(edge, iterations=2)] = (255, 140, 0)
o = Image.fromarray(a.astype('uint8'))
ImageDraw.Draw(o).text((20, 20), '%s outline: cyan = picture, orange = blockout   IoU %.1f%%  mass outline IoU %.1f%%' % (outp.split('/')[-1], score * 100, body * 100), fill=(255, 255, 255))
import os
mk = trisf.replace('_tris.npz', '_marks.json')
if mk == trisf:
    mk = ''
if os.path.exists(mk):
    dr = ImageDraw.Draw(o)
    for f in json.load(open(mk)):
        (u0, v0), (u1, v1), _ = project(c, W, H, np.array([[f['pos'], f['tip'], f['tip']]], dtype=float))[0]
        dr.line([(u0, v0), (u1, v1)], fill=(255, 255, 0), width=2)
        dr.text((u0 + 4, v0 - 12), f['id'], fill=(255, 255, 0))
o.save(outp + '_overlay.jpg', quality=88)
full = raster(c, W, H); mk2 = np.asarray(mask_full) > 127
dif = np.zeros((H, W, 3), 'uint8'); dif[full & mk2] = (90, 90, 90); dif[mk2 & ~full] = (0, 200, 255); dif[full & ~mk2] = (255, 140, 0)
Image.fromarray(dif).save(outp + '_diff.png')
