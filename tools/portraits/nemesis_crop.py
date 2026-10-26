# Nemesis pool portraits (sandbox): bust crops of the picked renders, so faces and scars read at portrait size.
#   python3 tools/portraits/nemesis_crop.py <render_root> <out_dir>
# render_root holds n1\, n2\ and nfix\ as on the PC (comfy_io\PORTRAITS\). Writes <out_dir>/nem_<fac>_<n>.png (1024 px crops,
# the sources for the painted scar edits) and prints the crop box and the scar anchor per Nemesis (anchors.json beside them).
# FACE: face centre (x, y) and face height in the full render, read by eye off a gridded sheet (Oct 26); creatures use their
# focal point. The crop is a square of side S with the face a third of the way down, clamped to the image.
import os, sys, json
from PIL import Image, ImageFilter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_edits import NEM_PICKS, FIXES, pick_path

FACE = {
 'nem_voidsworn_1': (0.50, 0.17, 0.17), 'nem_voidsworn_2': (0.51, 0.21, 0.14), 'nem_voidsworn_3': (0.50, 0.17, 0.16),
 'nem_voidsworn_4': (0.52, 0.19, 0.17), 'nem_voidsworn_5': (0.54, 0.28, 0.17), 'nem_voidsworn_6': (0.50, 0.21, 0.17),
 'nem_hegemony_1': (0.50, 0.17, 0.17), 'nem_hegemony_2': (0.50, 0.21, 0.18), 'nem_hegemony_3': (0.50, 0.18, 0.16),
 'nem_hegemony_4': (0.53, 0.21, 0.17), 'nem_hegemony_5': (0.54, 0.21, 0.17), 'nem_hegemony_6': (0.53, 0.21, 0.18),
 'nem_corsair_1': (0.51, 0.21, 0.16), 'nem_corsair_2': (0.54, 0.24, 0.18), 'nem_corsair_3': (0.51, 0.25, 0.16),
 'nem_corsair_4': (0.51, 0.25, 0.15), 'nem_corsair_5': (0.51, 0.26, 0.18), 'nem_corsair_6': (0.51, 0.25, 0.16),
 'nem_ithar_1': (0.50, 0.16, 0.15), 'nem_ithar_2': (0.50, 0.15, 0.15), 'nem_ithar_3': (0.52, 0.13, 0.15),
 'nem_ithar_4': (0.53, 0.14, 0.15), 'nem_ithar_5': (0.50, 0.14, 0.15), 'nem_ithar_6': (0.55, 0.15, 0.15),
}
# Chorus and Deathless are whole organisms or machines composed to fill the frame: a light crop round the centre, the
# scar anchor on the subject's middle
for _f in ('chorus', 'deathless'):
    for _n in range(1, 7): FACE['nem_%s_%d' % (_f, _n)] = (0.5, 0.48, 0.3)
S_HUMAN, S_CREATURE = 0.62, 0.9

def side(nid): return S_CREATURE if nid.split('_')[1] in ('chorus', 'deathless') else S_HUMAN

def box(nid):
    fx, fy, fh = FACE[nid]; S = side(nid)
    left = min(max(fx - S / 2, 0), 1 - S)
    top = min(max(fy - (S / 2 if S == S_CREATURE else S / 3), 0), 1 - S)
    return left, top, (round((fx - left) / S, 3), round((fy - top) / S, 3), round(fh / S, 3))

def src(root, nid):
    if nid in FIXES: return os.path.join(root, 'nfix', '%s_fix_s11_00001_.png' % nid)
    return os.path.join(root, pick_path(nid).replace('/', os.sep))

def crop(path, nid, size=1024):
    im = Image.open(path).convert('RGB'); w, h = im.size; left, top, anc = box(nid); S = side(nid)
    c = im.crop((int(left * w), int(top * h), int((left + S) * w), int((top + S) * h))).resize((size, size), Image.LANCZOS)
    return c.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2)), anc

if __name__ == '__main__':
    root, out = sys.argv[1], sys.argv[2]; os.makedirs(out, exist_ok=True); A = {}
    for nid in FACE:
        p = src(root, nid)
        if not os.path.exists(p): print('missing', p); continue
        im, anc = crop(p, nid); im.save(os.path.join(out, nid + '.png')); A[nid] = {'anchor': list(anc), 'crop': [round(v, 3) for v in box(nid)[:2]] + [side(nid)],
                                                                                    'source': os.path.relpath(p, root).replace(os.sep, '/')}
        print(nid, A[nid])
    json.dump(A, open(os.path.join(out, 'anchors.json'), 'w'), indent=1)
