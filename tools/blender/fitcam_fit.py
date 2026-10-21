# Step 2 of concept registration: pick the rig camera whose silhouette best matches the concept cut-out, fit scale/offset in 2D,
# write the concept re-framed into that camera (1024 square, black) + mask + json {az, el, iou}.
# usage: python fitcam_fit.py sil_dir concept_cut.png out_prefix
import sys, os, glob, json, numpy as np
from PIL import Image
sd, cpt, outp = sys.argv[1:4]
ci = Image.open(cpt).convert('RGBA'); ca = np.asarray(ci)[..., 3] > 128; ys, xs = np.nonzero(ca); crop = ci.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)); cm = crop.getchannel('A')
def place(S, sx, dx, dy):
    R = S.shape[0]; ys, xs = np.nonzero(S); w = (xs.max() - xs.min() + 1) * sx; s = w / crop.width; h = crop.height * s
    cx = (xs.min() + xs.max()) / 2 + dx * R / 1024; cy = (ys.min() + ys.max()) / 2 + dy * R / 1024
    m = Image.new('L', (R, R), 0); m.paste(cm.resize((max(1, round(w)), max(1, round(h)))), (round(cx - w / 2), round(cy - h / 2))); return np.asarray(m) > 127, (cx, cy, w, h)
def iou(A, B): return (A & B).sum() / max(1, (A | B).sum())
best = None
for f in glob.glob(os.path.join(sd, 'sil_*.png')):
    S = np.asarray(Image.open(f).convert('L')) > 40
    if S.sum() < 50: continue
    az, el = map(float, os.path.basename(f)[4:-4].split('_'))
    for sx in (0.94, 1.0, 1.06):
        for dx in (-16, 0, 16):
            for dy in (-16, 0, 16):
                v = iou(S, place(S, sx, dx, dy)[0])
                if best is None or v > best[0]: best = (v, az, el, sx, dx, dy, f)
v, az, el, sx, dx, dy, f = best
S = np.asarray(Image.open(f).convert('L').resize((1024, 1024), Image.NEAREST)) > 40
M, (cx, cy, w, h) = place(S, sx, dx, dy)
img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 255)); img.alpha_composite(crop.resize((max(1, round(w)), max(1, round(h))), Image.LANCZOS), (round(cx - w / 2), round(cy - h / 2)))
img.convert('RGB').save(outp + '.png'); Image.fromarray((M * 255).astype(np.uint8)).save(outp + '_mask.png')
Image.fromarray(np.dstack([S * 255, M * 255, np.zeros_like(M)]).astype(np.uint8)).save(outp + '_overlap.png')
r = {'az': az, 'el': el, 'iou': float(v), 'sx': sx, 'dx': dx, 'dy': dy}; json.dump(r, open(outp + '.json', 'w')); print('FIT', json.dumps(r))
