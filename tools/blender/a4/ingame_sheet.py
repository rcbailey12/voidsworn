# A4 in-game before/after sheets (feel pass, Nov 1): from two a4_shots.tscn capture folders (Downloads\voidsworn_test\a4\ingame\<tag>),
# one WebP per faction: the battle-camera line and the zoomed line, before over after, then each ship's three-quarter, side and below views
# (before left, after right) beside its concept. Phone-width friendly (1600 px), labelled in plain words.
#   python3 ingame_sheet.py BEFORE_DIR AFTER_DIR OUT_DIR [--facs hegemony,voidsworn] [--concepts DIR]
#   python3 ingame_sheet.py --battle BEFORE_SHOTS AFTER_SHOTS OUT.webp   (the real battle scene, shots\a4_cp2_*\<before|after>\<fac>\)
#   python3 ingame_sheet.py --props AFTER_DIR OUT.webp                    (board station and hulks: today against a4_props.gd)
#   python3 ingame_sheet.py --sweep DIR CODE OUT.webp [--label TEXT]      (9-cell blob sweep: bow, middle, stern from above, side, below)
import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
CONCEPTS = os.path.join(HERE, '..', '..', '..', 'docs', 'ship_pipeline', 'concepts')
FACS = [('hegemony', 'Hegemony Navy', 'H4_11 H10_23 H9_23 H8_23 H7_23'),
        ('voidsworn', 'Sunward Crusade', 'V1b_r_23 V17_37 V18_51 V16_37 V15_37 V14_23'),
        ('corsair', 'Ashfall Hullbreakers', 'C19_51 C16s_23 C15s_23 C14s_23 C13s_23'),
        ('chorus', 'Chorus', 'B16_23 B22_11 B21_11 B20_11 B19_11'),
        ('ithar', 'Glasswrights', 'I8_37 I16_11 I15_11 I11_37 I14_23'),
        ('deathless', 'Eclipse', 'D22_23 D21_23 D20_23 D9_23'),
        ('other', 'Objectives and craft', 'O1_37 O2_37 O3_11 S2_23 S1_51 B23_51')]
W = 1600


def font(sz):
    for p in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/segoeui.ttf'):
        if os.path.exists(p): return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def load(p, w):
    if not os.path.exists(p): return None
    im = Image.open(p).convert('RGB'); return im.resize((w, round(im.size[1] * w / im.size[0])), Image.LANCZOS)


def concept(code, w, h):
    p = os.path.join(CONCEPTS, code + '.webp')
    if not os.path.exists(p): return None
    im = Image.open(p).convert('RGBA'); bg = Image.new('RGBA', im.size, (12, 13, 17, 255)); bg.alpha_composite(im)
    s = min(w / im.size[0], h / im.size[1]); im = bg.convert('RGB').resize((round(im.size[0] * s), round(im.size[1] * s)), Image.LANCZOS)
    out = Image.new('RGB', (w, h), (12, 13, 17)); out.paste(im, ((w - im.size[0]) // 2, (h - im.size[1]) // 2)); return out


def sheet(bdir, adir, fac, title, codes, out, views=('q', 's', 'b')):
    f1, f2 = font(34), font(22); rows = []
    head = Image.new('RGB', (W, 96), (18, 18, 22)); d = ImageDraw.Draw(head)
    d.text((24, 12), f'{title}: in the game, before and after', font=f1, fill=(240, 236, 228))
    d.text((24, 58), 'Left: before (paint v1, as Ryan played it).  Right: after (concept paint).  Battle lights and camera.', font=f2, fill=(190, 190, 196))
    rows.append(head)
    if fac != 'other':
        for nm, lab in ((f'{fac}_battle', 'the line at the battle camera'), (f'{fac}_battle_near', 'zoomed in')):
            a, b = load(os.path.join(bdir, nm + '.jpg'), W // 2), load(os.path.join(adir, nm + '.jpg'), W // 2)
            if a is None or b is None: continue
            r = Image.new('RGB', (W, a.size[1] + 34), (18, 18, 22)); d = ImageDraw.Draw(r); d.text((12, 4), lab, font=f2, fill=(220, 220, 225))
            r.paste(a, (0, 34)); r.paste(b, (W // 2, 34)); rows.append(r)
    cw = W // 5
    for code in codes.split():
        tiles = []
        for v in views:
            a, b = load(os.path.join(bdir, f'{code}_{v}.jpg'), (W - cw) // 2), load(os.path.join(adir, f'{code}_{v}.jpg'), (W - cw) // 2)
            if a is None or b is None: continue
            tiles.append((v, a, b))
        if not tiles: continue
        th = tiles[0][1].size[1]
        r = Image.new('RGB', (W, 34 + th * len(tiles)), (18, 18, 22)); d = ImageDraw.Draw(r)
        d.text((12, 4), f'{code}: concept, then three-quarter, side and below', font=f2, fill=(220, 220, 225))
        c = concept(code, cw, min(th * 2, cw * 2))
        if c: r.paste(c, (0, 34))
        for k, (v, a, b) in enumerate(tiles): r.paste(a, (cw, 34 + k * th)); r.paste(b, (cw + a.size[0], 34 + k * th))
        rows.append(r)
    H = sum(x.size[1] for x in rows); S = Image.new('RGB', (W, H), (18, 18, 22)); y = 0
    for x in rows: S.paste(x, (0, y)); y += x.size[1]
    S.save(out, 'WEBP', quality=82, method=6); print('sheet', out, S.size)


def battle_sheet(bdir, adir, out, facs=('hegemony', 'corsair', 'chorus', 'ithar', 'deathless', 'voidsworn'), shot='01_start'):
    """the real battle scene (battle.tscn --shots), the Crusade fleet against each faction: before left, after right"""
    f1, f2 = font(34), font(22); rows = []
    head = Image.new('RGB', (W, 96), (18, 18, 22)); d = ImageDraw.Draw(head)
    d.text((24, 12), 'The battle itself, before and after', font=f1, fill=(240, 236, 228))
    d.text((24, 58), 'Left: before.  Right: after.  The game\'s own battle screen at its opening view.', font=f2, fill=(190, 190, 196))
    rows.append(head)
    for fac in facs:
        a, b = load(os.path.join(bdir, fac, shot + '.png'), W // 2), load(os.path.join(adir, fac, shot + '.png'), W // 2)
        if a is None or b is None: continue
        nm = dict(FACS_NAMES).get(fac, fac)
        r = Image.new('RGB', (W, a.size[1] + 34), (18, 18, 22)); d = ImageDraw.Draw(r); d.text((12, 4), f'against the {nm}', font=f2, fill=(220, 220, 225))
        r.paste(a, (0, 34)); r.paste(b, (W // 2, 34)); rows.append(r)
    stack(rows, out)


def props_sheet(adir, out):
    f1, f2 = font(34), font(22); rows = []
    head = Image.new('RGB', (W, 96), (18, 18, 22)); d = ImageDraw.Draw(head)
    d.text((24, 12), 'Board station and wrecks', font=f1, fill=(240, 236, 228))
    d.text((24, 58), 'Left: as the board draws them today (plain grey and black).  Right: the painted ships (a4_props.gd).', font=f2, fill=(190, 190, 196))
    rows.append(head)
    for nm, lab in (('props', 'battle camera'), ('props_near', 'closer')):
        a, b = load(os.path.join(adir, nm.replace('props', 'props_old') + '.jpg'), W // 2), load(os.path.join(adir, nm.replace('props', 'props_a4') + '.jpg'), W // 2)
        if a is None or b is None: continue
        r = Image.new('RGB', (W, a.size[1] + 34), (18, 18, 22)); d = ImageDraw.Draw(r); d.text((12, 4), lab, font=f2, fill=(220, 220, 225))
        r.paste(a, (0, 34)); r.paste(b, (W // 2, 34)); rows.append(r)
    stack(rows, out)


def sweep_sheet(dir_, code, out, label=''):
    """9 cells: rows from above (_t), from the side (_s), from below (_u); columns bow, middle, stern (bow is on the left in all three)"""
    f1, f2 = font(30), font(22); rows = []
    head = Image.new('RGB', (W, 90), (18, 18, 22)); d = ImageDraw.Draw(head)
    d.text((24, 10), f'{code}: blob sweep in the game {label}'.strip(), font=f1, fill=(240, 236, 228))
    d.text((24, 52), 'Columns: bow, middle, stern.  Rows: from above, from the side, from below.', font=f2, fill=(190, 190, 196))
    rows.append(head)
    for v, lab in (('t', 'from above'), ('s', 'from the side'), ('u', 'from below')):
        p = os.path.join(dir_, f'{code}_{v}.jpg')
        if not os.path.exists(p): continue
        im = Image.open(p).convert('RGB'); w_, h_ = im.size
        # a4_shots._close frames the ship from its own length: half the screen height is .62 * .62 = .384 of the length, so at 16:9
        # the length spans .73 of the width, centred (13.4% to 86.6%); a little margin either side
        x0, x1 = int(.11 * w_), int(.89 * w_)
        y0, y1 = (int(.30 * h_), int(.70 * h_)) if v == 's' else (int(.22 * h_), int(.78 * h_))
        cw = (x1 - x0) / 3; tw = W // 3; r = Image.new('RGB', (W, 0), (18, 18, 22)); cells = []
        for k in range(3):
            c = im.crop((int(x0 + k * cw) - 10, y0, int(x0 + (k + 1) * cw) + 10, y1)); c = c.resize((tw - 8, round(c.size[1] * (tw - 8) / c.size[0])), Image.LANCZOS); cells.append(c)
        h = max(c.size[1] for c in cells); r = Image.new('RGB', (W, h + 30), (18, 18, 22)); d = ImageDraw.Draw(r); d.text((12, 2), lab, font=f2, fill=(220, 220, 225))
        for k, c in enumerate(cells): r.paste(c, (k * tw + 4, 30)); d.text((k * tw + 14, 36), ('bow', 'middle', 'stern')[k], font=f2, fill=(255, 210, 120))
        rows.append(r)
    stack(rows, out)


FACS_NAMES = [('hegemony', 'Hegemony Navy'), ('voidsworn', 'Sunward Crusade'), ('corsair', 'Ashfall Hullbreakers'), ('chorus', 'Chorus'),
              ('ithar', 'Glasswrights'), ('deathless', 'Eclipse')]


def stack(rows, out):
    H = sum(x.size[1] for x in rows); S = Image.new('RGB', (W, H), (18, 18, 22)); y = 0
    for x in rows: S.paste(x, (0, y)); y += x.size[1]
    S.save(out, 'WEBP', quality=82, method=6); print('sheet', out, S.size)


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == '--battle': battle_sheet(a[1], a[2], a[3]); raise SystemExit
    if a[0] == '--props': props_sheet(a[1], a[2]); raise SystemExit
    if a[0] == '--sweep': sweep_sheet(a[1], a[2], a[3], a[a.index('--label') + 1] if '--label' in a else ''); raise SystemExit
    bdir, adir, odir = a[:3]; os.makedirs(odir, exist_ok=True)
    only = a[a.index('--facs') + 1].split(',') if '--facs' in a else None
    if '--concepts' in a: CONCEPTS = a[a.index('--concepts') + 1]
    for fac, title, codes in FACS:
        if only and fac not in only: continue
        sheet(bdir, adir, fac, title, codes, os.path.join(odir, f'{fac}_ingame_before_after.webp'))
