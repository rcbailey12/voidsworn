# Portrait post-processing (sandbox): PC renders -> framed 1024 px WebP in godot/portraits/, plus contact sheets.
#   python3 tools/portraits/post.py sheets <png_dir> [batch]      contact sheets of every candidate (raw renders, labelled)
#   python3 tools/portraits/post.py publish <png_dir> picks.json   framed WebP for picks and alternates, index.json, final sheets
# picks.json: {"chorus_mending": {"admiral": "mending", "pick": "chorus_mending_zit_s23", "alts": ["chorus_mending_zit_s11", ...]}, ...}
# The thin faction-trim frame line (art_direction_rey.md Part E) is drawn here, identical on every portrait.
import os, sys, json, glob, re
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.dirname(os.path.dirname(HERE))
PD = os.path.join(REPO, 'godot', 'portraits'); SHEETS = os.path.join(PD, 'sheets')
TRIM = {'voidsworn': '#c8501f', 'hegemony': '#3a78d0', 'corsair': '#b8402a', 'chorus': '#a4913a', 'ithar': '#d7c88a', 'deathless': '#1fbf4a'}
FACORDER = ['chorus', 'voidsworn', 'hegemony', 'corsair', 'ithar', 'deathless']
def font(sz, bold=False):
    try: return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if bold else ''), sz)
    except Exception: return ImageFont.load_default()

def framed(im, fac, size=1024):
    im = im.convert('RGB').resize((size, size), Image.LANCZOS); d = ImageDraw.Draw(im); c = TRIM[fac]
    s = size / 1024
    d.rectangle([0, 0, size - 1, size - 1], outline=(8, 8, 10), width=int(10 * s))          # dark edge
    d.rectangle([int(14 * s), int(14 * s), size - 1 - int(14 * s), size - 1 - int(14 * s)], outline=c, width=max(2, int(4 * s)))  # thin trim line
    return im

def candidates(png_dir):
    out = {}
    for p in sorted(glob.glob(os.path.join(png_dir, '*.png'))):
        m = re.match(r'(.+?)_(zit|qie)_s(\d+)_\d+_\.png$', os.path.basename(p))
        if m: out.setdefault(m.group(1), []).append((m.group(1) + '_' + m.group(2) + '_s' + m.group(3), p))
    return out

def sheet(items, out, title, cell=340, cols=4, marks=None):
    rows = (len(items) + cols - 1) // cols; W = cols * cell; H = 56 + rows * (cell + 30)
    im = Image.new('RGB', (W, H), (14, 14, 18)); d = ImageDraw.Draw(im); f = font(17); tf = font(24, True)
    d.text((14, 14), title, fill=(232, 232, 232), font=tf)
    for i, (label, p) in enumerate(items):
        x, y = (i % cols) * cell, 56 + (i // cols) * (cell + 30)
        t = Image.open(p).convert('RGB').resize((cell - 16, cell - 16), Image.LANCZOS); im.paste(t, (x + 8, y))
        if marks and label in marks:
            d.rectangle([x + 6, y - 2, x + cell - 10, y + cell - 14], outline=(255, 214, 90), width=5)
        d.text((x + 10, y + cell - 12), ('PICK  ' if marks and label in marks else '') + label, fill=(255, 214, 90) if marks and label in marks else (200, 200, 200), font=f)
    im.save(out, 'WEBP', quality=86); return out

def fac_of(key): return key.split('_')[0]

def cmd_sheets(png_dir, batch='b1'):
    os.makedirs(SHEETS, exist_ok=True); C = candidates(png_dir); by = {}
    for k, v in C.items(): by.setdefault(fac_of(k), []).extend(v)
    for fac in FACORDER:
        if fac in by:
            print(sheet(by[fac], os.path.join(SHEETS, '%s_%s_candidates.webp' % (fac, batch)), '%s: %s candidates (z = Z-Image Turbo, qie = Qwen-Image-Edit)' % (fac.capitalize(), batch), cols=4))

def cmd_publish(png_dir, picks_path):
    P = json.load(open(picks_path)); C = candidates(png_dir); lut = {lab: p for v in C.values() for lab, p in v}
    os.makedirs(os.path.join(PD, 'painted'), exist_ok=True); os.makedirs(os.path.join(PD, 'alts'), exist_ok=True)
    idx_path = os.path.join(PD, 'index.json'); idx = json.load(open(idx_path)) if os.path.exists(idx_path) else {'painted': {}}
    for key, e in P.items():
        fac = fac_of(key); adm = e['admiral']
        if e.get('pick') not in lut: print('missing pick', key, e.get('pick')); continue
        framed(Image.open(lut[e['pick']]), fac).save(os.path.join(PD, 'painted', adm + '.webp'), 'WEBP', quality=88, method=6)
        alts = []
        for n, a in enumerate(e.get('alts', [])):
            if a in lut:
                fn = '%s_alt%d.webp' % (adm, n + 1); framed(Image.open(lut[a]), fac).save(os.path.join(PD, 'alts', fn), 'WEBP', quality=80, method=6); alts.append('alts/' + fn)
        idx['painted'][adm] = {'faction': fac, 'pick': 'painted/' + adm + '.webp', 'alts': alts, 'source': e['pick'], 'alt_sources': e.get('alts', []),
                               'note': e.get('note', '')}
        print('published', adm, '+', len(alts), 'alts')
    json.dump(idx, open(idx_path, 'w'), indent=1)
    # final per-faction sheets: the pick first, then the alternates, framed as in game
    by = {}
    for adm, e in idx['painted'].items():
        by.setdefault(e['faction'], []).append(('%s PICK' % adm, os.path.join(PD, e['pick'])))
        for a in e['alts']: by[e['faction']].append((os.path.basename(a)[:-5], os.path.join(PD, a)))
    for fac in FACORDER:
        if fac in by:
            print(sheet(by[fac], os.path.join(SHEETS, fac + '_portraits.webp'), '%s portraits: picks and alternates' % fac.capitalize(), cols=4))

if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == 'sheets': cmd_sheets(a[1], a[2] if len(a) > 2 else 'b1')
    elif a[0] == 'publish': cmd_publish(a[1], a[2])
