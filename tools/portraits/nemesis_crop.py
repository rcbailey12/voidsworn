# Nemesis pool portraits (sandbox): bust crops of the picked renders, so faces and scars read at portrait size.
#   python3 tools/portraits/nemesis_crop.py <render_root> <out_dir>
# render_root holds n1\, n2\ and nfix\ as on the PC (comfy_io\PORTRAITS\). Writes <out_dir>/nem_<fac>_<n>.png (1024 px crops,
# the sources for the painted scar edits) and prints the crop box and the scar anchor per Nemesis (anchors.json beside them).
# FACE: face centre (x, y) and face height in the full render, read by eye off a gridded sheet (Oct 26); creatures use their
# focal point. The crop is a square of side S with the face a third of the way down, clamped to the image.
import os, sys, json
from PIL import Image, ImageFilter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_edits import NEM_PICKS, FIXES

FACE = {
 'nem_voidsworn_1': (0.50, 0.17, 0.17), 'nem_voidsworn_2': (0.51, 0.21, 0.14), 'nem_voidsworn_3': (0.50, 0.17, 0.16),
 'nem_voidsworn_4': (0.52, 0.19, 0.17), 'nem_voidsworn_5': (0.54, 0.28, 0.17), 'nem_voidsworn_6': (0.50, 0.20, 0.16),
 'nem_hegemony_1': (0.50, 0.17, 0.17), 'nem_hegemony_2': (0.50, 0.21, 0.18), 'nem_hegemony_3': (0.50, 0.18, 0.16),
 'nem_hegemony_4': (0.50, 0.20, 0.16), 'nem_hegemony_5': (0.50, 0.20, 0.16), 'nem_hegemony_6': (0.53, 0.21, 0.18),
 'nem_corsair_1': (0.50, 0.22, 0.16), 'nem_corsair_2': (0.50, 0.20, 0.16), 'nem_corsair_3': (0.51, 0.25, 0.16),
 'nem_corsair_4': (0.51, 0.25, 0.15), 'nem_corsair_5': (0.51, 0.26, 0.18), 'nem_corsair_6': (0.51, 0.25, 0.16),
}
S = 0.62

def box(nid):
    fx, fy, fh = FACE[nid]
    left = min(max(fx - S / 2, 0), 1 - S); top = min(max(fy - S / 3, 0), 1 - S)
    return left, top, (round((fx - left) / S, 3), round((fy - top) / S, 3), round(fh / S, 3))

def src(root, nid):
    fac = nid.split('_')[1]; n = int(nid.split('_')[2]); folder, seeds = NEM_PICKS[fac]
    if nid in FIXES: return os.path.join(root, 'nfix', '%s_fix_s11_00001_.png' % nid)
    return os.path.join(root, folder, '%s_zit_s%d_00001_.png' % (nid, seeds[n - 1]))

def crop(path, nid, size=1024):
    im = Image.open(path).convert('RGB'); w, h = im.size; left, top, anc = box(nid)
    c = im.crop((int(left * w), int(top * h), int((left + S) * w), int((top + S) * h))).resize((size, size), Image.LANCZOS)
    return c.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2)), anc

if __name__ == '__main__':
    root, out = sys.argv[1], sys.argv[2]; os.makedirs(out, exist_ok=True); A = {}
    for nid in FACE:
        p = src(root, nid)
        if not os.path.exists(p): print('missing', p); continue
        im, anc = crop(p, nid); im.save(os.path.join(out, nid + '.png')); A[nid] = {'anchor': list(anc), 'crop': [round(v, 3) for v in box(nid)[:2]] + [S],
                                                                                    'source': os.path.relpath(p, root).replace(os.sep, '/')}
        print(nid, A[nid])
    json.dump(A, open(os.path.join(out, 'anchors.json'), 'w'), indent=1)
