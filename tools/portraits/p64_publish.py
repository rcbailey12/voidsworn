# R64 repaint (Nov 1): Hullbreaker and Glasswright admirals and Nemesis from the p64 renders.
#   python3 tools/portraits/p64_publish.py admirals <render_root>          painted/<adm>.webp (framed), alternates, index.json
#   python3 tools/portraits/p64_publish.py crops <render_root> <out_dir> [fac]   Nemesis bust crops + anchors.json (upload to comfy_io\PORTRAITS\ncrop64\)
#   python3 tools/portraits/p64_publish.py scars <render_root> <out_dir>         picked scars as s11 files, then:
#   python3 tools/portraits/nemesis_publish.py <crops_dir> <scars_dir>
# render_root holds p64\ as on the PC. Then the scars: make_edits.py s64h / s64g on the PC, and nemesis_publish.py with the crops
# and the picked scar seed of each kind copied as the s11 file (S64_PICK below).
# The round 8 painting an admiral had before (Grax, Tamsa) is kept as alts/<adm>_r8.webp. Picks are vetoable calls.
import os, sys, json, shutil
from PIL import Image, ImageFilter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from post import framed, PD

# admiral -> (faction, picked render stem, alternate stems, note); a stem without a folder means p64\<stem>, else <folder>/<stem>
PICKS = {
 'grax': ('corsair', 'corsair_grax_s11_oil50_zi2i_s11', ['corsair_grax_s51_oil50_zi2i_s51'],
          'R64 void hunter (Nov 1): grey-streaked black mane, iron maw plate, chain harness, boarding hook. s23 and s37 showed a bare chest.'),
 'sable': ('corsair', 'corsair_sable_s11_oil50_zi2i_s11', ['corsair_sable_s51_oil50_zi2i_s51'],
           'R64 void hunter: lean, glossy black mane, green eyes, scrap blade held low, close black harness.'),
 'mott': ('corsair', 'corsair_mott_s11_oil50_zi2i_s11', ['corsair_mott_s51_oil50_zi2i_s51'],
          'R64 void hunter: ragged white mane, worn pale face plates, junk fighter craft hung from chains.'),
 'vesh': ('corsair', 'corsair_vesh_s23_oil50_zi2i_s23', ['corsair_vesh_s51_oil50_zi2i_s51'],
          'R64 void hunter: rust mane, a harness of collected plates (crystal, violet machine plating), welding torch. s11 face read as a metal helmet.'),
}
# Nemesis -> (picked render stem, face box (centre x, centre y, face height) as fractions of the render, read by eye)
NEM = {  # Hullbreakers: seed 11 except Nemesis 2 (s51: its s11 face read as a visor); every s37 had a bare bodybuilder chest
 'nem_corsair_1': ('nem_corsair_1_s11_oil50_zi2i_s11', (0.38, 0.28, 0.24)),
 'nem_corsair_2': ('nem_corsair_2_s51_oil50_zi2i_s51', (0.40, 0.24, 0.24)),
 'nem_corsair_3': ('nem_corsair_3_s11_oil50_zi2i_s11', (0.38, 0.29, 0.22)),
 'nem_corsair_4': ('nem_corsair_4_s11_oil50_zi2i_s11', (0.35, 0.30, 0.22)),
 'nem_corsair_5': ('nem_corsair_5_s11_oil50_zi2i_s11', (0.40, 0.30, 0.22)),
 'nem_corsair_6': ('nem_corsair_6_s11_oil50_zi2i_s11', (0.38, 0.30, 0.22)),
}
# Nemesis scar picks: nid -> {kind: seed} in s64\
S64_PICK = {  # Nov 1 review: the burn that stays a burn (N6 s11 and N3 s11 repainted the head), the smaller cyber plate, one blind eye
 'nem_corsair_1': {'burn': 23, 'cyber': 23, 'eye': 11}, 'nem_corsair_2': {'burn': 11, 'cyber': 23, 'eye': 11},
 'nem_corsair_3': {'burn': 23, 'cyber': 23, 'eye': 23}, 'nem_corsair_4': {'burn': 11, 'cyber': 23, 'eye': 11},
 'nem_corsair_5': {'burn': 11, 'cyber': 11, 'eye': 11}, 'nem_corsair_6': {'burn': 23, 'cyber': 11, 'eye': 11},
}
SCAR_DIR = 's64'
S_CROP = 0.62   # same bust crop as the round 8 pools (nemesis_crop.S_HUMAN): the face a third of the way down


def _src(root, stem):
    rel = stem if '/' in stem else 'p64/' + stem
    return os.path.join(root, rel + '_00001_.png'), rel + '_00001_.png'


def admirals(root):
    idx_path = os.path.join(PD, 'index.json'); idx = json.load(open(idx_path))
    for adm, (fac, pick, alts, note) in PICKS.items():
        old = os.path.join(PD, 'painted', adm + '.webp')
        if os.path.exists(old) and not os.path.exists(os.path.join(PD, 'alts', adm + '_r8.webp')):
            shutil.copyfile(old, os.path.join(PD, 'alts', adm + '_r8.webp'))
        framed(Image.open(_src(root, pick)[0]), fac).save(old, 'WEBP', quality=88, method=6)
        A = []
        for n, a in enumerate(alts):
            fn = 'alts/%s_p64alt%d.webp' % (adm, n + 1)
            framed(Image.open(_src(root, a)[0]), fac).save(os.path.join(PD, fn), 'WEBP', quality=80, method=6)
            A.append(fn)
        if os.path.exists(os.path.join(PD, 'alts', adm + '_r8.webp')): A.append('alts/%s_r8.webp' % adm)
        idx['painted'][adm] = {'faction': fac, 'pick': 'painted/%s.webp' % adm, 'alts': A, 'source': _src(root, pick)[1],
                               'alt_sources': [_src(root, a)[1] for a in alts], 'note': note}
        print('published', adm)
    json.dump(idx, open(idx_path, 'w'), indent=1)


def crops(root, out, fac=None):
    os.makedirs(out, exist_ok=True); A = {}
    for nid, (stem, (fx, fy, fh)) in NEM.items():
        if fac and nid.split('_')[1] != fac: continue
        im = Image.open(_src(root, stem)[0]).convert('RGB'); w, h = im.size; S = S_CROP
        left = min(max(fx - S / 2, 0), 1 - S); top = min(max(fy - S / 3, 0), 1 - S)
        c = im.crop((int(left * w), int(top * h), int((left + S) * w), int((top + S) * h))).resize((1024, 1024), Image.LANCZOS)
        c.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2)).save(os.path.join(out, nid + '.png'))
        A[nid] = {'anchor': [round((fx - left) / S, 3), round((fy - top) / S, 3), round(fh / S, 3)], 'crop': [round(left, 3), round(top, 3), S],
                  'source': _src(root, stem)[1]}
    json.dump(A, open(os.path.join(out, 'anchors.json'), 'w'), indent=1)
    print(len(A), 'crops in', out)


def scar_dir(root, out):
    """the picked scar seed of each kind copied as the s11 file nemesis_publish.py reads"""
    os.makedirs(out, exist_ok=True)
    for nid, P in S64_PICK.items():
        for k, sd in P.items():
            shutil.copyfile(os.path.join(root, SCAR_DIR, '%s_%s_s%d_00001_.png' % (nid, k, sd)), os.path.join(out, '%s_%s_s11_00001_.png' % (nid, k)))


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == 'admirals': admirals(a[1])
    elif a[0] == 'scars': scar_dir(a[1], a[2])
    elif a[0] == 'crops': crops(a[1], a[2], a[3] if len(a) > 3 else None)
