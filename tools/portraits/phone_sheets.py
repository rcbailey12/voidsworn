# Phone-friendly review sheets (sandbox): 1080 px wide, big cells, plain labels, one image per group.
#   python3 tools/portraits/phone_sheets.py <out_dir>        e.g. docs/shots/portraits/<sha>/
# Writes 01_admirals.webp (the painted admirals as the game shows them, with a tag on factions whose look is in review),
# then 02_nemesis_<faction>.webp for every faction with a published Nemesis pool (pool portrait, then each painted scar,
# each with the red-black Nemesis frame as in game).
import os, sys, json
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.dirname(os.path.dirname(HERE))
PD = os.path.join(REPO, 'godot', 'portraits')
sys.path.insert(0, HERE)
from post import font
from make_edits import KINDS
W = 1080; BG = (14, 14, 18)
NAME = {'matriarch': 'The Matriarch', 'mending': 'The Mending Throng', 'vex': 'Admiral Roderic Vex', 'kassar': 'First Admiral Ilsa Kassar',
        'grax': 'Grax Steelgrin', 'aelith': 'Tamsa of the Clear Aperture', 'nekhet': 'Nadir Aurex, Ninth Frame'}   # rename_map_final.md section 6
FAC = {'voidsworn': 'Sunward Crusade', 'hegemony': 'Hegemony Navy', 'corsair': 'Ashfall Hullbreakers', 'chorus': 'The Chorus', 'ithar': 'The Glasswrights', 'deathless': 'Eclipse'}
IN_REVIEW = set()   # lore approved Oct 27 (R59): every look is final; admiral names follow rename_map_final.md when it lands

def header(h, title, sub):
    im = Image.new('RGB', (W, h), BG); d = ImageDraw.Draw(im)
    d.text((28, 24), title, fill=(240, 240, 240), font=font(40, True))
    d.text((28, 78), sub, fill=(170, 170, 170), font=font(24))
    return im, d

def admirals(out):
    idx = json.load(open(os.path.join(PD, 'index.json')))['painted']
    keys = list(idx); cols, gap = 2, 16; c = (W - gap * (cols + 1)) // cols; lab = 92; top = 130
    rows = (len(keys) + cols - 1) // cols
    im, d = header(top + rows * (c + lab + gap), 'Painted admirals', 'As the game shows them today. Amber tag: that faction\'s look is changing.')
    for i, k in enumerate(keys):
        e = idx[k]; x = gap + (i % cols) * (c + gap); y = top + (i // cols) * (c + lab + gap)
        im.paste(Image.open(os.path.join(PD, e['pick'])).convert('RGB').resize((c, c), Image.LANCZOS), (x, y))
        d.text((x, y + c + 8), NAME.get(k, k), fill=(255, 255, 255), font=font(30, True))
        d.text((x, y + c + 48), FAC[e['faction']], fill=(190, 190, 190), font=font(24))
        if e['faction'] in IN_REVIEW:
            d.rounded_rectangle((x + c - 230, y + c + 46, x + c, y + c + 80), 8, fill=(120, 80, 10))
            d.text((x + c - 218, y + c + 50), 'look changing', fill=(255, 220, 140), font=font(22, True))
    p = os.path.join(out, '01_admirals.webp'); im.save(p, 'WEBP', quality=82, method=6); print(p, im.size)

def nemesis(out):
    nem = json.load(open(os.path.join(PD, 'index.json'))).get('nemesis', {})
    for fac in FAC:
        ids = sorted((k for k, v in nem.items() if v['faction'] == fac), key=lambda k: int(k.split('_')[2]))
        if not ids: continue
        fr = Image.open(os.path.join(PD, 'nemesis', 'frame_%s.png' % fac)).convert('RGBA')
        kinds = KINDS[fac]; cols = 1 + len(kinds); gap = 10; c = (W - gap * (cols + 1)) // cols; lab = 40; top = 130
        im, d = header(top + len(ids) * (c + lab + gap), '%s: Nemesis' % FAC[fac],
                       'Left: as first met. Then the same Nemesis with each painted scar.' + ('  Look changing.' if fac in IN_REVIEW else ''))
        for r, nid in enumerate(ids):
            e = nem[nid]; cells = [('no scar', e['pick'])] + [(k, e['baked'][k]) for k in kinds if k in e['baked']]
            y = top + r * (c + lab + gap)
            d.text((gap, y), 'Nemesis %s' % nid.split('_')[2], fill=(255, 220, 60), font=font(26, True))
            for j, (k, rel) in enumerate(cells):
                x = gap + j * (c + gap)
                p = Image.open(os.path.join(PD, rel)).convert('RGBA').resize((1024, 1024), Image.LANCZOS)
                p = Image.alpha_composite(p, fr).convert('RGB').resize((c, c), Image.LANCZOS)
                im.paste(p, (x, y + lab))
                if j: d.text((x + 8, y + lab + 8), k, fill=(255, 255, 255), font=font(24, True), stroke_width=3, stroke_fill=(0, 0, 0))
        p = os.path.join(out, '02_nemesis_%s.webp' % fac); im.save(p, 'WEBP', quality=80, method=6); print(p, im.size)

if __name__ == '__main__':
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    admirals(out); nemesis(out)
