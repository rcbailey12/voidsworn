# R68 varied portraits (Ryan, Nov 1 07:37): publish the v64 round, every faction, from the PC renders.
#   python3 tools/portraits/v64_publish.py admirals <render_root>            painted/<adm>.webp (cropped to head and shoulders, framed), index.json
#   python3 tools/portraits/v64_publish.py crops <render_root> <out> [fac]   Nemesis bust crops + anchors.json (upload to comfy_io\PORTRAITS\ncrop68\)
#   python3 tools/portraits/v64_publish.py scars <render_root> <out>         picked scar seeds copied as the s11 files nemesis_publish.py reads
#   python3 tools/portraits/nemesis_publish.py <crops_dir> <scars_dir>
#   python3 tools/portraits/v64_publish.py sheet <render_root> <out.webp> <fac>   review sheet: admirals and Nemesis as the game frames them
# render_root holds the PC's comfy_io\PORTRAITS\ subfolders (v64\, v64b\, e64\, s68\). Picks are vetoable calls, read by eye at full size.
# The admiral card draws the painting at 84 px, so a full-figure render is cropped to head and shoulders here (CROP box: centre x,
# centre y, side, as fractions of the render); the setting still shows round the figure. The painting it replaces is kept in alts\.
import os, sys, json, shutil
from PIL import Image, ImageFilter, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from post import framed, PD, font

# admiral -> (faction, render (relative to render_root, without _00001_.png), crop box or None, note)
ADM = {
 # Glasswrights (v64g faceless Qwen designs, light oil pass from v64g2; faceless checked at full size)
 'aelith': ('ithar', 'v64b/ithar_aelith_s11_oil30_zi2i_s11', (0.5, 0.375, 0.75),
            'R68 (Nov 1): Tamsa in the carrier hangar launching her glass starlings; faceless gem head; oil 0.30 (0.5 painted a face in).'),
 'thorne': ('ithar', 'v64b/ithar_thorne_s11_oil30_zi2i_s11', (0.5, 0.375, 0.75),
            'R68: Vell in the hall of mirrors, looking back over its shoulder; oil 0.30 (0.40 drew a face profile).'),
 'mirelle': ('ithar', 'v64b/ithar_mirelle_s11_oil40_zi2i_s11', (0.5, 0.375, 0.75),
             'R68: Brin on its command chair before the Hollow Sun; oil 0.40.'),
 'vaelen': ('ithar', 'v64b/ithar_vaelen_nf1_edit_s23', (0.5, 0.42, 0.86),
            'R68: Saro (vaelen) in the observatory, focusing a beam through a lens; faceless edit of the s73 render (v64g3 nf1 s23).'),
 # Hullbreakers (v64h2 bodies and settings, v64h4 matte living scales on the head, v64h5 horns and tusks taken off)
 'grax': ('corsair', 'v64b/corsair_grax_nohorn_s11', (0.55, 0.37, 0.72), 'R68: Grax slumped on a scrap throne under hanging trophies (v64h5 s11).'),
 'sable': ('corsair', 'v64b/corsair_sable_nohorn_s23', (0.71, 0.33, 0.58), 'R68: Sable in a red-lit airlock corridor with a long knife (v64h5 s23).'),
 'mott': ('corsair', 'v64b/corsair_mott_nohorn_s11', (0.70, 0.35, 0.60), 'R68: Mott in a hangar of salvage, sparks and a gutted hull (v64h5 s11).'),
 'vesh': ('corsair', 'v64b/corsair_vesh_nohorn_s11', (0.69, 0.33, 0.60), 'R68: Vesh at a forge bench welding with a blue arc (v64h5 s11).'),
 'kassar': ('hegemony', 'e64/kassar_v64_s83', (0.5, 0.36, 0.62),
            'R68: Kassar in a white council chamber high in orbit, hands behind her back before a ringed gas giant (e64e s83).'),
 # Crusade, Chorus and Eclipse: their approved paintings moved into new settings by an edit (e64)
 'matriarch': ('chorus', 'e64/matriarch_v64_s11', None, 'R68: the Matriarch above a planet it is consuming, spores falling into the air.'),
 'mending': ('chorus', 'e64/mending_v64_s11', None, 'R68: the Mending nested in the gutted hull of a captured warship.'),
 'nekhet': ('deathless', 'e64/nekhet_v64_s11', None, 'R68: Nekhet in a machine hall of siphon arrays draining a star.'),
 'vex': ('voidsworn', 'e64/vex_v64_s51', (0.5, 0.42, 0.84), 'R68: Vex in a frost-rimed war room, fists on a table lit by an ember star chart (e64c).'),
}
# Nemesis -> (render, face box (centre x, centre y, face height) as fractions of the render[, crop side])
NEM = {
 'nem_ithar_1': ('v64b/nem_ithar_1_s11_oil40_zi2i_s11', (0.55, 0.17, 0.30)),
 'nem_ithar_3': ('v64b/nem_ithar_3_s11_oil40_zi2i_s11', (0.44, 0.14, 0.25)),
 'nem_ithar_4': ('v64b/nem_ithar_4_s11_oil40_zi2i_s11', (0.47, 0.14, 0.24)),
 'nem_ithar_5': ('v64b/nem_ithar_5_s11_oil40_zi2i_s11', (0.56, 0.18, 0.30)),
 'nem_ithar_6': ('v64b/nem_ithar_6_s23_oil40_zi2i_s23', (0.49, 0.15, 0.25)),
 # e64 edits of the round 8 bust crops: the head stayed where it was, so the full frame is the crop and the old anchor holds
 'nem_voidsworn_1': ('e64/nem_voidsworn_1_v64_s23', (0.5, 0.274, 0.274), 1.0),
 'nem_voidsworn_2': ('e64/nem_voidsworn_2_v64_s23', (0.5, 0.333, 0.226), 1.0),
 'nem_hegemony_1': ('e64/nem_hegemony_1_v64_s11', (0.5, 0.274, 0.274), 1.0),
 'nem_hegemony_2': ('e64/nem_hegemony_2_v64_s11', (0.5, 0.333, 0.29), 1.0),
 'nem_hegemony_3': ('e64/nem_hegemony_3_v64_s23', (0.5, 0.29, 0.258), 1.0),
 'nem_hegemony_4': ('e64/nem_hegemony_4_v64_s23', (0.5, 0.333, 0.274), 1.0),
 'nem_hegemony_6': ('e64/nem_hegemony_6_v64_s11', (0.5, 0.333, 0.29), 1.0),
 'nem_chorus_2': ('e64/nem_chorus_2_v64_s23', (0.5, 0.5, 0.333), 1.0),
 'nem_chorus_3': ('e64/nem_chorus_3_v64_s23', (0.5, 0.5, 0.333), 1.0),
 'nem_chorus_4': ('e64/nem_chorus_4_v64_s23', (0.5, 0.5, 0.333), 1.0),
 'nem_chorus_5': ('e64/nem_chorus_5_v64_s23', (0.5, 0.5, 0.333), 1.0),
 'nem_chorus_6': ('e64/nem_chorus_6_v64_s23', (0.5, 0.5, 0.333), 1.0),
 'nem_deathless_3': ('e64/nem_deathless_3_v64_s23', (0.5, 0.242, 0.242), 1.0),
 'nem_deathless_4': ('e64/nem_deathless_4_v64_s11', (0.5, 0.258, 0.242), 1.0),
 'nem_deathless_5': ('e64/nem_deathless_5_v64_s23', (0.5, 0.333, 0.242), 1.0),
 'nem_deathless_6': ('e64/nem_deathless_6_v64_s11', (0.5, 0.5, 0.333), 1.0),
 # Hullbreakers (v64h5 picks; Nemesis 3 from v64h4) and the two v64g3 / e64d late picks
 'nem_corsair_1': ('v64b/nem_corsair_1_nohorn_s11', (0.38, 0.25, 0.32)),
 'nem_corsair_2': ('v64b/nem_corsair_2_nohorn_s11', (0.60, 0.27, 0.30)),
 'nem_corsair_3': ('v64b/nem_corsair_3_horn_s11', (0.27, 0.26, 0.27)),
 'nem_corsair_5': ('v64b/nem_corsair_5_nohorn_s11', (0.66, 0.26, 0.30)),
 'nem_corsair_4': ('v64b/nem_corsair_4_h6scale_s23', (0.63, 0.21, 0.25)),
 'nem_corsair_6': ('v64b/nem_corsair_6_h6fix_s23', (0.50, 0.21, 0.24)),
 'nem_ithar_2': ('v64b/nem_ithar_2_nf2_edit_s23', (0.53, 0.23, 0.30)),
 'nem_voidsworn_3': ('e64/nem_voidsworn_3_v64_s73', (0.53, 0.35, 0.23)),
 # e64c redraws (seeds 37, 51)
 'nem_voidsworn_4': ('e64/nem_voidsworn_4_v64_s51', (0.5, 0.306, 0.274), 1.0),
 'nem_voidsworn_5': ('e64/nem_voidsworn_5_v64_s51', (0.5, 0.333, 0.274), 1.0),
 'nem_voidsworn_6': ('e64/nem_voidsworn_6_v64_s51', (0.5, 0.333, 0.274), 1.0),
 'nem_hegemony_5': ('e64/nem_hegemony_5_v64_s51', (0.43, 0.33, 0.29), 1.0),
 'nem_chorus_1': ('e64/nem_chorus_1_v64_s37', (0.5, 0.5, 0.333), 1.0),
 'nem_deathless_1': ('e64/nem_deathless_1_v64_s37', (0.5, 0.21, 0.242), 1.0),
 'nem_deathless_2': ('e64/nem_deathless_2_v64_s37', (0.5, 0.23, 0.12), 0.6),
}
# Nemesis scar picks: nid -> {kind: seed} in SCAR_DIR
SCAR = {
 # s68g (Glasswrights; Nemesis 1 burn painted a human face on both seeds, redone in s68i)
 'nem_ithar_1': {'burn': 37, 'porcelain': 23}, 'nem_ithar_3': {'burn': 11, 'porcelain': 11}, 'nem_ithar_4': {'burn': 23, 'porcelain': 23},
 'nem_ithar_5': {'burn': 23, 'porcelain': 11}, 'nem_ithar_6': {'burn': 23, 'porcelain': 23},
 # s68h (Glasswright Nemesis 2; Hullbreaker Nemesis 1, 2, 3, 5: their implant plates grew into riveted face masks on 1, 3 and 5,
 # redone in s68i with a small eye-socket ring; Crusade Nemesis 3)
 'nem_ithar_2': {'burn': 23, 'porcelain': 23},
 'nem_corsair_1': {'burn': 11, 'cyber': 51, 'eye': 11}, 'nem_corsair_2': {'burn': 11, 'cyber': 23, 'eye': 11},
 'nem_corsair_3': {'burn': 11, 'cyber': 37, 'eye': 23}, 'nem_corsair_5': {'burn': 11, 'cyber': 37, 'eye': 11},
 'nem_corsair_4': {'burn': 11, 'cyber': 11, 'eye': 11}, 'nem_corsair_6': {'burn': 11, 'cyber': 11, 'eye': 23},  # s68i
 'nem_voidsworn_3': {'burn': 23, 'eye': 11},
 # s68a, s68c (Sunward Crusade: burn and eye, no implant scar)
 'nem_voidsworn_1': {'burn': 11, 'eye': 23}, 'nem_voidsworn_2': {'burn': 23, 'eye': 23}, 'nem_voidsworn_4': {'burn': 23, 'eye': 23},
 'nem_voidsworn_5': {'burn': 23, 'eye': 11}, 'nem_voidsworn_6': {'burn': 23, 'eye': 23},
 # s68a, s68c (Hegemony)
 'nem_hegemony_1': {'burn': 23, 'cyber': 23, 'eye': 23}, 'nem_hegemony_2': {'burn': 23, 'cyber': 23, 'eye': 11},
 'nem_hegemony_3': {'burn': 11, 'cyber': 23, 'eye': 11}, 'nem_hegemony_4': {'burn': 11, 'cyber': 23, 'eye': 11},
 'nem_hegemony_5': {'burn': 11, 'cyber': 23, 'eye': 11}, 'nem_hegemony_6': {'burn': 11, 'cyber': 23, 'eye': 23},
 # s68b, s68c (Chorus; seeds that kept the background clean, no block noise or speckle)
 'nem_chorus_1': {'burn': 23, 'carapace': 11}, 'nem_chorus_2': {'burn': 23, 'carapace': 23}, 'nem_chorus_3': {'burn': 11, 'carapace': 11},
 'nem_chorus_4': {'burn': 11, 'carapace': 11}, 'nem_chorus_5': {'burn': 23, 'carapace': 11}, 'nem_chorus_6': {'burn': 11, 'carapace': 11},
 # s68b, s68c (Eclipse)
 'nem_deathless_1': {'burn': 11, 'machine': 23}, 'nem_deathless_2': {'burn': 11, 'machine': 23}, 'nem_deathless_3': {'burn': 11, 'machine': 11},
 'nem_deathless_4': {'burn': 23, 'machine': 23}, 'nem_deathless_5': {'burn': 11, 'machine': 11}, 'nem_deathless_6': {'burn': 23, 'machine': 23},
}
SCAR_DIR = 's68'
# crops whose scars were painted on a fixed crop (S68_FIX in make_edits.py): the fixed crop is the pool portrait
FIXED = {'nem_ithar_1': 's68/nem_ithar_1_fix_s11', 'nem_ithar_3': 's68/nem_ithar_3_fix_s11'}
FACE_IN_CROP = 0.36   # the face's height as a share of the bust crop (the round 8 and p64 pools sit at 0.33 to 0.39)


def _png(root, rel): return os.path.join(root, rel + '_00001_.png')


def crop_box(im, box):
    if not box: return im
    w, h = im.size; cx, cy, s = box; s = min(s, 1.0)
    l = min(max(cx - s / 2, 0), 1 - s); t = min(max(cy - s / 2, 0), 1 - s)
    return im.crop((int(l * w), int(t * h), int((l + s) * w), int((t + s) * h))).resize((1024, 1024), Image.LANCZOS)


def admirals(root, only=None):
    idx_path = os.path.join(PD, 'index.json'); idx = json.load(open(idx_path))
    for adm, (fac, rel, box, note) in ADM.items():
        if only and fac != only: continue
        old = os.path.join(PD, 'painted', adm + '.webp'); prev = idx['painted'].get(adm, {})
        A = [a for a in prev.get('alts', []) if os.path.exists(os.path.join(PD, a))]
        if os.path.exists(old):
            keep = 'alts/%s_pre68.webp' % adm
            if not os.path.exists(os.path.join(PD, keep)): shutil.copyfile(old, os.path.join(PD, keep))
            if keep not in A: A.insert(0, keep)
        im = crop_box(Image.open(_png(root, rel)).convert('RGB'), box)
        framed(im, fac).save(old, 'WEBP', quality=88, method=6)
        idx['painted'][adm] = {'faction': fac, 'pick': 'painted/%s.webp' % adm, 'alts': A, 'source': rel + '_00001_.png',
                               'crop': list(box) if box else None, 'note': note}
        print('published', adm)
    json.dump(idx, open(idx_path, 'w'), indent=1)


def crops(root, out, fac=None):
    os.makedirs(out, exist_ok=True); A = {}
    only = fac.split(',') if fac and fac.startswith('nem_') else None
    for nid, e in NEM.items():
        if only and nid not in only: continue
        if fac and not only and nid.split('_')[1] != fac: continue
        rel, (fx, fy, fh) = e[0], e[1]
        im = Image.open(_png(root, rel)).convert('RGB'); w, h = im.size
        S = e[2] if len(e) > 2 else min(1.0, max(0.42, fh / FACE_IN_CROP))
        left = min(max(fx - S / 2, 0), 1 - S); top = min(max(fy - S / 3, 0), 1 - S)
        c = im.crop((int(left * w), int(top * h), int((left + S) * w), int((top + S) * h))).resize((1024, 1024), Image.LANCZOS)
        if S < 0.9: c = c.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))
        if nid in FIXED: c = Image.open(_png(root, FIXED[nid])).convert('RGB').resize((1024, 1024), Image.LANCZOS)
        c.save(os.path.join(out, nid + '.png'))
        A[nid] = {'anchor': [round((fx - left) / S, 3), round((fy - top) / S, 3), round(fh / S, 3)], 'crop': [round(left, 3), round(top, 3), round(S, 3)],
                  'source': rel + '_00001_.png'}
    json.dump(A, open(os.path.join(out, 'anchors.json'), 'w'), indent=1)
    print(len(A), 'crops in', out)


def scar_dir(root, out):
    os.makedirs(out, exist_ok=True)
    for nid, P in SCAR.items():
        for k, sd in P.items():
            shutil.copyfile(os.path.join(root, SCAR_DIR, '%s_%s_s%d_00001_.png' % (nid, k, sd)), os.path.join(out, '%s_%s_s11_00001_.png' % (nid, k)))


def sheet(root, out, fac, crops_dir=None, title=None):
    """the faction's admirals (cropped and framed as published) and its Nemesis bust crops (with the red Nemesis frame)"""
    cells = []
    for adm, (f, rel, box, _n) in ADM.items():
        if f == fac: cells.append((adm, framed(crop_box(Image.open(_png(root, rel)).convert('RGB'), box), f)))
    fr = Image.open(os.path.join(PD, 'nemesis', 'frame_%s.png' % fac)).convert('RGBA')
    for nid in NEM:
        if nid.split('_')[1] != fac: continue
        p = os.path.join(crops_dir, nid + '.png') if crops_dir else None
        im = Image.open(p).convert('RGBA').resize((1024, 1024)) if p and os.path.exists(p) else None
        if im is None: continue
        cells.append(('Nemesis ' + nid.split('_')[-1], Image.alpha_composite(im, fr).convert('RGB')))
    c = 330; cols = 5; rows = (len(cells) + cols - 1) // cols
    W = Image.new('RGB', (cols * c, 64 + rows * (c + 28)), (14, 14, 18)); d = ImageDraw.Draw(W)
    d.text((14, 16), title or fac, fill=(240, 240, 240), font=font(24, True)); f = font(17)
    for i, (lab, im) in enumerate(cells):
        x, y = (i % cols) * c, 64 + (i // cols) * (c + 28)
        W.paste(im.resize((c - 14, c - 14), Image.LANCZOS), (x + 7, y)); d.text((x + 10, y + c - 10), lab, fill=(255, 214, 90), font=f)
    W.save(out, 'WEBP', quality=86); print('sheet', out)


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == 'admirals': admirals(a[1], a[2] if len(a) > 2 else None)
    elif a[0] == 'crops': crops(a[1], a[2], a[3] if len(a) > 3 else None)
    elif a[0] == 'scars': scar_dir(a[1], a[2])
    elif a[0] == 'sheet': sheet(a[1], a[2], a[3], a[4] if len(a) > 4 else None, a[5] if len(a) > 5 else None)
