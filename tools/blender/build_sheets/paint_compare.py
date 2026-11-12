# The painted sheet ship beside its concept, as pictures for Ryan (issue 601; RULEBOOK 1.2: one picture per item, its code name
# on it, 1280 wide, no taller than 720). Plain Python with Pillow (Blender's own python has it after the recipe's env.bat).
# Inputs: the paint_sheet.py renders (paint_beauty at the sheet's concept camera, side, far side, top, below), the concept, and
# optionally the game's own shots (a4_shots.gd: CODE_cam170.jpg, CODE_cam60.jpg, true game pixels, never scaled).
# usage: python paint_compare.py PAINT_DIR CONCEPT_JPG SHOTS_DIR|- GAME_CODE OUT_DIR [name=A16]
import os, sys
from PIL import Image, ImageDraw, ImageFont

BG = (14, 15, 18); FG = (225, 228, 232); DIM = (165, 170, 178)
# region windows (fractions of the concept camera's frame), the same on the concept and the render
WIN = dict(bow=(.02, .22, .46, .95), midships=(.25, .08, .73, .72), stern=(.53, .0, 1.0, .64))


def font(size):
    for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf']:
        if os.path.exists(p): return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def head(img, title, sub):
    d = ImageDraw.Draw(img); d.text((12, 8), title, fill=FG, font=font(22)); d.text((12, 36), sub, fill=DIM, font=font(15))


def fit(im, w, h):
    im = im.copy(); im.thumbnail((w, h)); c = Image.new('RGB', (w, h), BG); c.paste(im, ((w - im.width) // 2, (h - im.height) // 2)); return c


def pair(a, b, title, sub, out, w=640, maxh=660):
    h = min(maxh, int(w * a.height / a.width))
    img = Image.new('RGB', (2 * w, h + 60), BG); head(img, title, sub)
    img.paste(fit(a, w - 4, h), (0, 60)); img.paste(fit(b, w - 4, h), (w + 4, 60)); img.save(out, quality=90); return out


def main():
    a = sys.argv[1:]; P, CON, SH, CODE, OUT = a[:5]
    kw = dict(x.split('=', 1) for x in a[5:] if '=' in x); N = kw.get('name', 'A16')
    os.makedirs(OUT, exist_ok=True)
    con = Image.open(CON).convert('RGB'); bea = Image.open(os.path.join(P, 'paint_beauty.png')).convert('RGB').resize(con.size)
    made = [pair(con, bea, f'{N} paint: concept (left) and the painted build (right), same camera',
                 'Hullbreaker paint stack (issue 601): game light, battle lift 1.25; colours sampled from the concept, never projected',
                 os.path.join(OUT, f'{N}_paint_full.jpg'))]
    W, H = con.size
    for k, (x0, y0, x1, y1) in WIN.items():
        box = (int(x0 * W), int(y0 * H), int(x1 * W), int(y1 * H))
        made.append(pair(con.crop(box), bea.crop(box), f'{N} paint, {k}: concept (left), painted build (right)', 'same camera, same window',
                         os.path.join(OUT, f'{N}_paint_{k}.jpg')))
    views = [('side (port)', 'paint_side.png'), ('far side (starboard)', 'paint_side_s.png'), ('top', 'paint_top.png'), ('below', 'paint_below.png')]
    img = Image.new('RGB', (1280, 60 + 2 * 300), BG); head(img, f'{N} paint: the four flat views', 'bow left on the port side, top and below; the far side shows the bow on the right')
    for i, (lab, f) in enumerate(views):
        p = os.path.join(P, f)
        if not os.path.exists(p): continue
        t = fit(Image.open(p).convert('RGB'), 636, 280); x, y = (i % 2) * 644, 60 + (i // 2) * 300
        img.paste(t, (x, y + 18)); ImageDraw.Draw(img).text((x + 8, y), lab, fill=DIM, font=font(14))
    p = os.path.join(OUT, f'{N}_paint_views.jpg'); img.save(p, quality=90); made.append(p)
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
