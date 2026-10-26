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
        m = re.match(r'(.+?)_(zit|qie|qref)_s(\d+)_\d+_\.png$', os.path.basename(p))
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
    cmd_phone_sheets(idx)

def cmd_phone_sheets(idx=None):
    """one tall WebP per faction for Ryan's phone: each painted admiral big (framed as in game) with its alternates under it,
    then the crests of the faction's other admirals. 1080 px wide."""
    import io, cairosvg
    sys.path.insert(0, HERE); from crests import NAMES, ADM
    idx = idx or json.load(open(os.path.join(PD, 'index.json')))
    W = 1080; tf, nf, sf = font(40, True), font(30, True), font(22)
    for fac in FACORDER:
        painted = [(a, e) for a, e in idx['painted'].items() if e['faction'] == fac]
        others = [a for a, (f, _) in ADM.items() if f == fac and a not in dict(painted)]
        blocks = []                                                 # (height, draw function)
        for adm, e in painted:
            def draw(im, d, y, adm=adm, e=e):
                d.text((24, y), NAMES.get(adm, adm), fill=(240, 232, 210), font=nf)
                im.paste(Image.open(os.path.join(PD, e['pick'])).convert('RGB').resize((W - 48, W - 48), Image.LANCZOS), (24, y + 46))
                y2 = y + 46 + W - 48 + 14; n = max(1, len(e['alts'])); cw = (W - 48 - (n - 1) * 12) // max(n, 4)
                if e['alts']: d.text((24, y2), 'Alternates (swap by editing "pick" in godot/portraits/index.json)', fill=(170, 170, 170), font=sf)
                for i, a in enumerate(e['alts']):
                    im.paste(Image.open(os.path.join(PD, a)).convert('RGB').resize((cw, cw), Image.LANCZOS), (24 + i * (cw + 12), y2 + 32))
            n = max(1, len(e['alts'])); cw = (W - 48 - (n - 1) * 12) // max(n, 4)
            blocks.append((46 + W - 48 + 14 + (32 + cw if e['alts'] else 0) + 40, draw))
        if others:
            cw = (W - 48 - 3 * 12) // 4
            def drawc(im, d, y, others=others, cw=cw):
                d.text((24, y), 'Crests (admirals without a painting)', fill=(170, 170, 170), font=sf)
                for i, a in enumerate(others):
                    png = cairosvg.svg2png(url=os.path.join(PD, 'crests', a + '.svg'), output_width=cw, output_height=cw)
                    t = Image.open(io.BytesIO(png)).convert('RGBA'); x = 24 + (i % 4) * (cw + 12); yy = y + 34 + (i // 4) * (cw + 40)
                    im.paste(t, (x, yy), t); d.text((x, yy + cw + 4), NAMES.get(a, a), fill=(220, 220, 220), font=sf)
            blocks.append((34 + ((len(others) + 3) // 4) * (cw + 40) + 20, drawc))
        H = 90 + sum(h for h, _ in blocks)
        im = Image.new('RGB', (W, H), (14, 14, 18)); d = ImageDraw.Draw(im)
        d.rectangle([0, 0, W, 8], fill=TRIM[fac]); d.text((24, 24), fac.capitalize() + ' admirals', fill=(255, 255, 255), font=tf)
        y = 90
        for h, fn in blocks: fn(im, d, y); y += h
        out = os.path.join(SHEETS, fac + '_portraits.webp'); im.save(out, 'WEBP', quality=82, method=6); print(out, im.size)

if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == 'sheets': cmd_sheets(a[1], a[2] if len(a) > 2 else 'b1')
    elif a[0] == 'publish': cmd_publish(a[1], a[2])
    elif a[0] == 'phone': cmd_phone_sheets()
