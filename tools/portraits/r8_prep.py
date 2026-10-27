# Round 8 Nemesis sources (sandbox): the bust crops the round 8 scars are painted on (comfy_io\PORTRAITS\ncrop8\ on the PC).
#   python3 tools/portraits/r8_prep.py <render_root> <out_dir>
# render_root holds r8\ and r8e\ as on the PC. New pools (Hullbreakers, Glasswrights, Eclipse) are cropped from the picked r8
# render with a face box read by eye (same rule as nemesis_crop.py); touched-up pools (Crusade, Hegemony, Chorus) are already
# bust crops (r8e edits of ncrop\), so they are copied as they are and keep their old scar anchors.
# Writes <out_dir>/nem_<fac>_<n>.png and anchors.json (the format nemesis_publish.py reads).
import os, sys, json, shutil
from PIL import Image, ImageFilter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nemesis_crop as NC

# picked r8 render seed per new Nemesis, and its face box (centre x, centre y, face height, as fractions of the render) read
# off a gridded sheet; None = a machine or ring composed to fill the frame (light crop round the centre)
PICK8 = {}
FACE8 = {}
TOUCHED = ('voidsworn', 'hegemony', 'chorus')

def main(root, out):
    os.makedirs(out, exist_ok=True); A = {}
    for nid, seed in PICK8.items():
        src = os.path.join(root, 'r8', '%s_zit_s%d_00001_.png' % (nid, seed))
        face = FACE8.get(nid)
        im = Image.open(src).convert('RGB'); w, h = im.size
        if face is None:
            S = NC.S_CREATURE; fx, fy, fh = 0.5, 0.48, 0.3
        else:
            S = NC.S_HUMAN; fx, fy, fh = face
        left = min(max(fx - S / 2, 0), 1 - S); top = min(max(fy - (S / 2 if face is None else S / 3), 0), 1 - S)
        c = im.crop((int(left * w), int(top * h), int((left + S) * w), int((top + S) * h))).resize((1024, 1024), Image.LANCZOS)
        c.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2)).save(os.path.join(out, nid + '.png'))
        A[nid] = {'anchor': [round((fx - left) / S, 3), round((fy - top) / S, 3), round(fh / S, 3)], 'crop': [round(left, 3), round(top, 3), S],
                  'source': 'r8/%s_zit_s%d_00001_.png' % (nid, seed)}
    old = json.load(open(os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'godot', 'portraits', 'index.json'))).get('nemesis', {})
    for fac in TOUCHED:
        for n in range(1, 7):
            nid = 'nem_%s_%d' % (fac, n); src = os.path.join(root, 'r8e', '%s_r8_s11_00001_.png' % nid)
            if not os.path.exists(src): print('missing', src); continue
            shutil.copyfile(src, os.path.join(out, nid + '.png'))
            A[nid] = {'anchor': old.get(nid, {}).get('anchor', [0.5, 0.42, 0.3]), 'crop': [0, 0, 1], 'source': 'r8e/%s_r8_s11_00001_.png' % nid}
    json.dump(A, open(os.path.join(out, 'anchors.json'), 'w'), indent=1)
    print(len(A), 'sources in', out)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
