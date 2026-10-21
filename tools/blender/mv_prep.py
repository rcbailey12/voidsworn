# Prepare four generated views (front/left/back/right) for Pixal3D multi-view: cut the ship off its plain backdrop, put every view
# on one shared scale (the ship's height is the same in all four eye-level views; its length, from the side views, spans 1/1.1 of
# the frame as on the upstream rig), centre on the bounding box, 1024 square on black.
# usage: python3 mv_prep.py out_dir CODE front.png left.png back.png right.png [length_scale]
#   length_scale (optional, e.g. 1.1) stretches the side views' length before framing (owner length correction).
import sys, os, numpy as np
from PIL import Image, ImageFilter
out, code = sys.argv[1], sys.argv[2]; files = {k: f for k, f in zip(['front', 'left', 'back', 'right'], sys.argv[3:7]) if f != '-'}; ls = float(sys.argv[7]) if len(sys.argv) > 7 else 1.0  # '-' = no view; 'mirror:path' = flipped image
os.makedirs(out, exist_ok=True); S = 1024; PAD = 1.1
def cut(path):
    mir = path.startswith('mirror:'); im = Image.open(path[7:] if mir else path).convert('RGB')
    if mir: im = im.transpose(Image.FLIP_LEFT_RIGHT)
    a = np.asarray(im).astype(np.float32)
    bg = np.median(np.concatenate([a[:8].reshape(-1, 3), a[-8:].reshape(-1, 3), a[:, :8].reshape(-1, 3), a[:, -8:].reshape(-1, 3)]), 0)
    d = np.abs(a - bg).max(2); m = (d > 18).astype(np.uint8) * 255
    mi = Image.fromarray(m).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(5)).filter(ImageFilter.MaxFilter(3))
    m = np.asarray(mi) > 127
    from scipy import ndimage
    lab, n = ndimage.label(m)
    if n > 1:  # keep the ship: the biggest blob plus anything close to it
        sz = ndimage.sum(m, lab, range(1, n + 1)); big = np.argmax(sz) + 1; keep = sz > sz.max() * .01
        m = np.isin(lab, np.nonzero(keep)[0] + 1)
    m = ndimage.binary_fill_holes(m) & (d > 6) | m
    ys, xs = np.nonzero(m); return im, m, (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
V = {k: cut(f) for k, f in files.items()}
H = {k: v[2][3] - v[2][1] for k, v in V.items()}; Wd = {k: v[2][2] - v[2][0] for k, v in V.items()}
sides = [k for k in ('left', 'right') if k in V]; ends = [k for k in ('front', 'back') if k in V]
L_side = np.mean([Wd[k] * ls / H[k] for k in sides]) if sides else 1.0  # length in units of height
W_fr = np.mean([Wd[k] / H[k] for k in ends]) if ends else 0.0
ext = max(L_side, W_fr, 1.0); hpx = S / PAD / ext  # ship height in pixels, shared by all views
print(code, 'length/height %.2f  width/height %.2f  height px %.0f' % (L_side, W_fr, hpx))
for k, (im, m, (x0, y0, x1, y1)) in V.items():
    k_s = hpx / (y1 - y0); sx = k_s * (ls if k in ('left', 'right') else 1.0)
    rgba = np.dstack([np.asarray(im), (m * 255).astype(np.uint8)])[y0:y1, x0:x1]
    t = Image.fromarray(rgba, 'RGBA').resize((max(1, round((x1 - x0) * sx)), max(1, round((y1 - y0) * k_s))), Image.LANCZOS)
    c = Image.new('RGBA', (S, S), (0, 0, 0, 255)); c.alpha_composite(t, ((S - t.width) // 2, (S - t.height) // 2))
    c.convert('RGB').save(os.path.join(out, f'{code}_{k}.png'))
sheet = Image.new('RGB', (S * 2, S * 2)); [sheet.paste(Image.open(os.path.join(out, f'{code}_{k}.png')), ((i % 2) * S, (i // 2) * S)) for i, k in enumerate(['front', 'left', 'back', 'right']) if k in V]
sheet.resize((S, S)).save(os.path.join(out, f'{code}_mv_sheet.png'))
