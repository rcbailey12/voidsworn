# Nemesis pool for the game (sandbox): bust crops plus their painted scar edits -> godot/portraits/nemesis/pool/.
#   python3 tools/portraits/nemesis_publish.py <crops_dir> <edits_dir>
# crops_dir: nemesis_crop.py output (nem_<fac>_<n>.png + anchors.json). edits_dir: comfy_io\PORTRAITS\n1s\ renders
# (nem_<fac>_<n>_<kind>_s11_00001_.png). Writes per Nemesis:
#   pool/nem_<fac>_<n>.webp                  the pool portrait (768 px)
#   pool/nem_<fac>_<n>_<kind>.webp           that Nemesis with one painted scar (the first scar it earns)
#   pool/nem_<fac>_<n>_<kind>_patch.webp     just the scarred region of that painting, feathered alpha, with its offset in
#                                            index.json, so a second and third scar are pasted from the same painting style
# and updates godot/portraits/index.json "nemesis" (pick, baked, patch, anchor) and writes sheets/nemesis_<fac>.webp.
import os, sys, json, glob
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.dirname(os.path.dirname(HERE))
PD = os.path.join(REPO, 'godot', 'portraits'); POOL = os.path.join(PD, 'nemesis', 'pool'); SHEETS = os.path.join(PD, 'sheets')
SIZE = 768
sys.path.insert(0, HERE)
from make_edits import KINDS

def scar_mask(base, edit, anchor):
    """where the edit painted the scar: big local change, cleaned, kept near the subject, feathered (0..1 float, SIZE px)"""
    a = np.asarray(base.convert('RGB').resize((SIZE, SIZE), Image.LANCZOS), np.float32)
    b = np.asarray(edit.convert('RGB').resize((SIZE, SIZE), Image.LANCZOS), np.float32)
    d = ndimage.gaussian_filter(np.abs(a - b).sum(2), 3)
    thr = max(40.0, float(np.percentile(d, 92)))            # the edit re-renders everything a little; the scar is the big change
    m = d > thr
    m = ndimage.binary_opening(m, iterations=2); m = ndimage.binary_closing(m, iterations=4)
    lab, n = ndimage.label(m)
    if n == 0: return None
    ax, ay = anchor[0] * SIZE, anchor[1] * SIZE; keep = np.zeros_like(m)
    sizes = ndimage.sum(m, lab, range(1, n + 1)); cms = ndimage.center_of_mass(m, lab, range(1, n + 1))
    for i, (s, (cy, cx)) in enumerate(zip(sizes, cms), 1):
        if s > 400 and np.hypot(cx - ax, cy - ay) < SIZE * 0.45: keep |= lab == i
    if keep.sum() < 400: return None
    keep = ndimage.binary_dilation(keep, iterations=10)
    return np.clip(ndimage.gaussian_filter(keep.astype(np.float32), 8) * 1.4, 0, 1)

def main(crops, edits):
    os.makedirs(POOL, exist_ok=True); os.makedirs(SHEETS, exist_ok=True)
    A = json.load(open(os.path.join(crops, 'anchors.json')))
    idx_path = os.path.join(PD, 'index.json'); idx = json.load(open(idx_path)) if os.path.exists(idx_path) else {}
    nem = idx.setdefault('nemesis', {}); report = []
    for nid in sorted(A):
        fac = nid.split('_')[1]; base = Image.open(os.path.join(crops, nid + '.png')).convert('RGB')
        base.resize((SIZE, SIZE), Image.LANCZOS).save(os.path.join(POOL, nid + '.webp'), 'WEBP', quality=84, method=6)
        e = {'faction': fac, 'pick': 'nemesis/pool/%s.webp' % nid, 'anchor': A[nid]['anchor'], 'source': A[nid]['source'], 'baked': {}, 'patch': {}}
        for k in KINDS[fac]:
            p = os.path.join(edits, '%s_%s_s11_00001_.png' % (nid, k))
            if not os.path.exists(p): report.append((nid, k, 'no edit')); continue
            ed = Image.open(p).convert('RGB').resize((SIZE, SIZE), Image.LANCZOS)
            ed.save(os.path.join(POOL, '%s_%s.webp' % (nid, k)), 'WEBP', quality=84, method=6)
            e['baked'][k] = 'nemesis/pool/%s_%s.webp' % (nid, k)
            m = scar_mask(base, ed, A[nid]['anchor'])
            if m is None: report.append((nid, k, 'no clear scar region')); continue
            ys, xs = np.where(m > 0.02); x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
            rgba = np.dstack([np.asarray(ed)[y0:y1, x0:x1], (m[y0:y1, x0:x1] * 255).astype(np.uint8)])
            Image.fromarray(rgba, 'RGBA').save(os.path.join(POOL, '%s_%s_patch.webp' % (nid, k)), 'WEBP', quality=88, method=6)
            e['patch'][k] = {'file': 'nemesis/pool/%s_%s_patch.webp' % (nid, k), 'x': round(x0 / SIZE, 4), 'y': round(y0 / SIZE, 4),
                             'area': round(float((m > 0.5).mean()), 3)}
            report.append((nid, k, 'patch %.1f%% of the frame' % (100 * (m > 0.5).mean())))
        nem[nid] = e
    json.dump(idx, open(idx_path, 'w'), indent=1)
    for r in report: print(*r)
    sheets(nem)

def sheets(nem):
    """per faction: each Nemesis as pool portrait, then each painted scar, framed as in game"""
    sys.path.insert(0, HERE); import nemesis_fx as N
    from post import font
    f = font(22, True); c = 300
    for fac in ['voidsworn', 'hegemony', 'corsair', 'chorus', 'ithar', 'deathless']:
        ids = sorted(k for k, v in nem.items() if v['faction'] == fac)
        if not ids: continue
        cols = 1 + len(KINDS[fac]); W = Image.new('RGB', (cols * c, 60 + len(ids) * c), (14, 14, 18)); d = ImageDraw.Draw(W)
        d.text((14, 16), '%s Nemesis pool: portrait, then each painted scar' % fac.capitalize(), fill=(255, 255, 255), font=f)
        fr = Image.open(os.path.join(PD, 'nemesis', 'frame_%s.png' % fac)).convert('RGBA')
        for r, nid in enumerate(ids):
            e = nem[nid]; cells = [('', e['pick'])] + [(k, e['baked'][k]) for k in KINDS[fac] if k in e['baked']]
            for j, (k, rel) in enumerate(cells):
                im = Image.open(os.path.join(PD, rel)).convert('RGBA').resize((1024, 1024)); im = Image.alpha_composite(im, fr)
                W.paste(im.convert('RGB').resize((c - 6, c - 6), Image.LANCZOS), (j * c + 3, 60 + r * c + 3))
                d.text((j * c + 30, 60 + r * c + 26), nid[4:] + (' ' + k if k else ''), fill=(255, 220, 60), font=font(16, True))
        out = os.path.join(SHEETS, 'nemesis_%s.webp' % fac); W.save(out, 'WEBP', quality=80, method=6); print(out, W.size)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
