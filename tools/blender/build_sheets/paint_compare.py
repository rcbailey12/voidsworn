# The painted sheet ship beside its concept, as pictures for Ryan (issue 601; RULEBOOK 1.2: one picture per item, its code name
# on it, 1280 wide, no taller than 720). Plain Python with Pillow (Blender's own python has it after the recipe's env.bat).
# Inputs: the paint_sheet.py renders (paint_beauty at the sheet's concept camera, side, far side, top, below), the concept, and
# optionally the game's own shots (a4_shots.gd: CODE_cam170.jpg, CODE_cam60.jpg, true game pixels, never scaled).
# usage: python paint_compare.py PAINT_DIR CONCEPT_JPG SHOTS_DIR|- GAME_CODE OUT_DIR [name=A16] [stack=Hullbreaker] [issue=601]
import os, sys
from PIL import Image, ImageDraw, ImageFont

BG = (14, 15, 18); FG = (225, 228, 232); DIM = (165, 170, 178)
# region windows (fractions of the concept camera's frame), the same on the concept and the render
WIN = dict(bow=(.02, .22, .46, .95), midships=(.25, .08, .73, .72), stern=(.53, .0, 1.0, .64))


# what the engines picture shows, per faction stack (issue 642: the Eclipse engine is a ring of pale light round a dark disc)
ENGINE_NOTE = {'Hullbreaker': 'the throat glow: hot core in the centre, hot spots and soot, each engine its own; the lip dark',
               'Eclipse': 'the eclipse ring: pale light round a black shade disc, hot spots and dim gaps, each engine its own; no flame'}


def font(size):
    for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf']:
        if os.path.exists(p): return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def head(img, title, sub):
    d = ImageDraw.Draw(img); d.text((12, 8), title, fill=FG, font=font(22)); d.text((12, 36), sub, fill=DIM, font=font(15))


def fit(im, w, h):
    k = min(w / im.width, h / im.height); im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    c = Image.new('RGB', (w, h), BG); c.paste(im, ((w - im.width) // 2, (h - im.height) // 2)); return c


def concept_thirds(con, rwin):
    """the concept's own bow, midships and stern windows: its ship (the largest shape over luminance 28, as the build sheets cut
    it) split in thirds along the ship's axis as the render shows it (stern window centre to bow window centre), so each crop
    holds the same part of the ship on both sides even where the build and the picture do not sit on the same pixels"""
    import numpy as np
    from scipy import ndimage
    a = np.asarray(con.convert('L')); m = a > 28; lab, n = ndimage.label(ndimage.binary_closing(m, iterations=3))
    if n == 0: return None
    big = 1 + int(np.argmax(ndimage.sum(np.ones_like(lab), lab, range(1, n + 1)))); ys, xs = np.nonzero(lab == big)
    H, W = a.shape
    cen = lambda w: np.array([(w[0] + w[2]) / 2 * W, (w[1] + w[3]) / 2 * H])      # noqa: E731
    ax = cen(rwin['bow']) - cen(rwin['stern']); ax /= (np.linalg.norm(ax) or 1)
    t = (xs - xs.mean()) * ax[0] + (ys - ys.mean()) * ax[1]; lo, hi = np.percentile(t, 1), np.percentile(t, 99); third = (hi - lo) / 3
    out = {}
    for k, (a0, a1) in (('stern', (lo, lo + third)), ('midships', (lo + third, hi - third)), ('bow', (hi - third, hi))):
        sel = (t >= a0) & (t <= a1); px, py = xs[sel], ys[sel]; pad = .04
        out[k] = [max(0, px.min() / W - pad), max(0, py.min() / H - pad), min(1, px.max() / W + pad), min(1, py.max() / H + pad)]
    return out


def pair(a, b, title, sub, out, w=640, maxh=660):
    h = min(maxh, int(w * a.height / a.width))
    img = Image.new('RGB', (2 * w, h + 60), BG); head(img, title, sub)
    img.paste(fit(a, w - 4, h), (0, 60)); img.paste(fit(b, w - 4, h), (w + 4, 60)); img.save(out, quality=90); return out


def main():
    a = sys.argv[1:]; P, CON, SH, CODE, OUT = a[:5]
    kw = dict(x.split('=', 1) for x in a[5:] if '=' in x); N = kw.get('name', 'A16')
    os.makedirs(OUT, exist_ok=True)
    con = Image.open(CON).convert('RGB'); bea = Image.open(os.path.join(P, 'paint_beauty.png')).convert('RGB').resize(con.size)
    js0 = os.path.join(P, 'paint_shots.json')
    lift = __import__('json').load(open(js0)).get('lift', 1.25) if os.path.exists(js0) else 1.25
    stack, issue = kw.get('stack', 'Hullbreaker'), kw.get('issue', '601')
    made = [pair(con, bea, f'{N} paint: concept (left) and the painted build (right), same camera',
                 f'{stack} paint stack (issue {issue}): game light, battle lift {lift:g}; colours sampled from the concept, never projected',
                 os.path.join(OUT, f'{N}_paint_full.jpg'))]
    W, H = con.size
    js = os.path.join(P, 'paint_shots.json')
    win = dict(WIN)
    if os.path.exists(js): win.update(__import__('json').load(open(js)).get('windows', {}))     # measured on the render's own camera
    cwin = None
    try: cwin = concept_thirds(con, win)
    except Exception as e: print('[601] concept thirds not measured:', e)
    def square(w):
        """the window as a square round its centre, as wide as its longer side (both sides of a pair fill the same frame)"""
        x0, y0, x1, y1 = w[0] * W, w[1] * H, w[2] * W, w[3] * H; cx, cy = (x0 + x1) / 2, (y0 + y1) / 2; h = max(x1 - x0, y1 - y0) / 2
        cx = min(max(cx, h), W - h) if 2 * h < W else W / 2; cy = min(max(cy, h), H - h) if 2 * h < H else H / 2
        return (int(cx - h), int(cy - h), int(cx + h), int(cy + h))
    for k in ('bow', 'midships', 'stern'):
        box = square(win[k])
        cbox = square(cwin[k]) if cwin else box
        made.append(pair(con.crop(cbox), bea.crop(box), f'{N} paint, {k}: concept (left), painted build (right)',
                         'the same third of the ship on each side, at the same camera' if cwin else 'same camera, same window',
                         os.path.join(OUT, f'{N}_paint_{k}.jpg')))
    views = [('concept', None), ('side (port)', 'paint_side.png'), ('far side (starboard)', 'paint_side_s.png'), ('top', 'paint_top.png'),
             ('below', 'paint_below.png'), ('bow on', 'paint_bow.png'), ('stern on', 'paint_stern.png')]
    img = Image.new('RGB', (1280, 60 + 2 * 326), BG)
    head(img, f'{N} paint: the six views beside the concept', 'bow left on the port side, top and below; the far side shows the bow on the right')
    for i, (lab, f) in enumerate(views):
        src = con if f is None else (Image.open(os.path.join(P, f)).convert('RGB') if os.path.exists(os.path.join(P, f)) else None)
        if src is None: continue
        t = fit(src, 316, 300); x, y = (i % 4) * 321, 60 + (i // 4) * 326
        img.paste(t, (x, y + 22)); ImageDraw.Draw(img).text((x + 6, y + 2), lab, fill=DIM, font=font(14))
    p = os.path.join(OUT, f'{N}_paint_views.jpg'); img.save(p, quality=90); made.append(p)
    zs, bl = os.path.join(P, 'paint_stern_zoom.png'), os.path.join(P, 'paint_bell.png')
    if os.path.exists(zs) and os.path.exists(bl):      # the engines up close: every bell stern-on, and the biggest bell at a close camera
        img = Image.new('RGB', (1280, 60 + 600), BG)
        head(img, f'{N} engines: every bell stern-on (left), the biggest bell up close (right)', ENGINE_NOTE.get(stack, ENGINE_NOTE['Hullbreaker']))
        img.paste(fit(Image.open(zs).convert('RGB'), 636, 600), (0, 60)); img.paste(fit(Image.open(bl).convert('RGB'), 636, 600), (644, 60))
        p = os.path.join(OUT, f'{N}_paint_engines.jpg'); img.save(p, quality=92); made.append(p)
    cr, cc = os.path.join(P, 'paint_close_rim.png'), os.path.join(P, 'paint_close_core.png')
    if os.path.exists(cr) and os.path.exists(cc):      # issue 642: the glow a faction stack asks to see close (the corona line, the core)
        img = Image.new('RGB', (1280, 60 + 600), BG)
        head(img, f'{N} close: the corona line on a shade rim (left), the core in its port or cage (right)', f'game light, battle lift {lift:g}; the green is a thin line on the rim and the core, never pooled in hollows')
        img.paste(fit(Image.open(cr).convert('RGB'), 636, 600), (0, 60)); img.paste(fit(Image.open(cc).convert('RGB'), 636, 600), (644, 60))
        p = os.path.join(OUT, f'{N}_paint_close.jpg'); img.save(p, quality=92); made.append(p)
    if SH != '-':
        for cam in ('cam170', 'cam60'):
            g = os.path.join(SH, f'{CODE}_{cam}.jpg')
            if not os.path.exists(g): continue
            gi = Image.open(g).convert('RGB'); cw, ch = 880, 660
            cx, cy = gi.width // 2, gi.height // 2
            crop = gi.crop((cx - cw // 2, cy - ch // 2, cx + cw // 2, cy + ch // 2))     # true game pixels, never scaled
            img = Image.new('RGB', (1280, 720), BG)
            head(img, f'{N} in the game, camera {cam[3:]}: concept (left), the game at true pixels (right)',
                 f'{CODE}, a4_shots.gd set cams, the battle camera\'s angle; centre {cw} x {ch} of the 1920 x 1080 frame, not scaled')
            img.paste(fit(con, 392, 660), (0, 60)); img.paste(crop, (400, 60))
            p = os.path.join(OUT, f'{N}_ingame_{cam}.jpg'); img.save(p, quality=90); made.append(p)
    for m in made: print('[601] picture', m)


if __name__ == '__main__':
    main()
