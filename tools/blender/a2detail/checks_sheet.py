# A2 max-detail ships: contact sheets from the check renders (needs PIL; runs in the cloud inline, or on the PC through pack_glb.py --sheets)
import os, json
from PIL import Image, ImageDraw, ImageFont
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
V = ('side', 'q', 'below', 'close'); VL = ('side (bow right)', 'three-quarter top', 'three-quarter below', 'close-up')
KEYS = [(r, v) for r in ('bow', 'mid', 'stern') for v in ('top', 'side', 'below')]


def font(n):
    for f in (FONT, 'C:/Windows/Fonts/arial.ttf', 'arial.ttf'):
        try: return ImageFont.truetype(f, n)
        except Exception: pass
    return ImageFont.load_default()


def sheet(paths, out, title, cols, labels, cell=(560, 324)):
    F, f = font(22), font(17); rows = (len(paths) + cols - 1) // cols; TH, LH = 44, 26
    img = Image.new('RGB', (cell[0] * cols, TH + rows * (cell[1] + LH)), (18, 18, 22)); d = ImageDraw.Draw(img); d.text((12, 10), title, fill=(235, 230, 220), font=F)
    for i, (p, lab) in enumerate(zip(paths, labels)):
        x, y = (i % cols) * cell[0], TH + (i // cols) * (cell[1] + LH); d.text((x + 10, y + 3), lab, fill=(200, 195, 185), font=f)
        if p and os.path.exists(p): img.paste(Image.open(p).convert('RGB').resize(cell), (x, y + LH))
    img.save(out, quality=88); return out


def make(chk, code):
    r = os.path.join(chk, '_r_' + code); info = json.load(open(os.path.join(r, 'info.json'))); fac, res = info['faction'], info['res']
    P = lambda pre, v: os.path.join(r, f'{pre}_{v}.png')
    sheet([P('clay', v) for v in V] + [P('paint', v) for v in V], os.path.join(chk, f'{code}_views.webp'), f'{code} ({fac}) max-detail: clay (top row), painted {res}px bake (bottom row)', 4,
          [f'clay {l}' for l in VL] + [f'painted {l}' for l in VL])
    for pre, nm in (('sclay', 'clay'), ('spaint', 'painted')):
        sheet([P(pre, f'{a}_{b}') for a, b in KEYS], os.path.join(chk, f'{code}_sweep_{nm}.webp'), f'{code} blob sweep, {nm}: rows bow / mid / stern, columns top / side / below', 3,
              [f'{a} {b}' for a, b in KEYS], cell=(512, 320))


def make_barge(chk):
    r = os.path.join(chk, '_r_C19_51'); res = json.load(open(os.path.join(r, 'info.json')))['res']
    sheet([os.path.join(r, f'paint_{v}.png') for v in V] + [os.path.join(r, f'dark_{v}.png') for v in V], os.path.join(chk, 'C19_51_views.webp'),
          f'C19_51 Pyre-Barge v15, {res}px re-bake: painted (top row), emissive check with the studio lights at 8 percent (bottom row)', 4, [f'painted {l}' for l in VL] + [f'lights down {l}' for l in VL])
