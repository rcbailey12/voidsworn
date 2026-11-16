# the four named pictures for issue 738 (each 1280 x 720, its code name on it): the sheet overview, the whole-concept compare
# beside S8 (R229), the battle camera view; the weapon review comes from publish.py
import json
from PIL import Image, ImageDraw, ImageFont
import os, sys
# usage: python pictures.py RENDER_DIR   (the build.py render folder, with beauty_cam_battle.png from the beauty mode)
R = sys.argv[1]
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
D = REPO + '/docs/ship_pipeline/build_sheets/voidsworn_S8'
GREY = (44, 44, 46); INK = (240, 232, 218); DIM = (190, 186, 178); ACC = (240, 170, 80)


def F(n):
    return ImageFont.truetype(next((f_ for f_ in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf') if os.path.exists(f_)), None), n)


def on_grey(path, box=None):
    im = Image.open(path).convert('RGBA')
    if box:
        im = im.crop(box)
    bg = Image.new('RGBA', im.size, (58, 58, 60, 255)); bg.alpha_composite(im)
    return bg.convert('RGB')


def fit(im, w, h):
    im = im.copy(); im.thumbnail((w, h), Image.Resampling.LANCZOS); return im


def paste(c, im, x, y, w, h):
    im = fit(im, w, h); c.paste(im, (x + (w - im.width) // 2, y + (h - im.height) // 2))


def tight(im, pad=12):
    a = im.convert('RGBA'); bb = a.getbbox() if a.mode == 'RGBA' else None
    return im


def alpha_crop(path, pad=20):
    im = Image.open(path).convert('RGBA'); bb = im.getchannel('A').getbbox()
    x0, y0, x1, y1 = bb; im = im.crop((max(0, x0 - pad), max(0, y0 - pad), min(im.width, x1 + pad), min(im.height, y1 + pad)))
    bg = Image.new('RGBA', im.size, (58, 58, 60, 255)); bg.alpha_composite(im); return bg.convert('RGB')


# 1. the sheet overview
c = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(c)
d.text((18, 10), 'voidsworn_S8 | Daybreak dreadnought build sheet, first sheet (issue 738)', fill=INK, font=F(26))
d.text((18, 44), 'One Blender blockout, every view at one scale. Length 27.0 (game). Fit check 0, weapon match PASS, audit PASS.', fill=DIM, font=F(16))
paste(c, alpha_crop(R + '/side.png'), 18, 74, 820, 250); d.text((22, 76), 'TRUE SIDE (bow left)', fill=ACC, font=F(15))
top = alpha_crop(R + '/top.png').rotate(90, expand=True)
paste(c, top, 18, 330, 820, 250); d.text((22, 332), 'TRUE TOP (bow left, port down)', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/cutaway.png'), 18, 586, 820, 130); d.text((22, 588), 'INSIDE (cutaway)', fill=ACC, font=F(15))
paste(c, on_grey(R + '/threequarter.png'), 850, 74, 412, 260); d.text((854, 76), 'THREE-QUARTER', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/stern.png'), 850, 340, 200, 180); d.text((854, 342), 'ENGINE END', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/bow.png'), 1062, 340, 200, 180); d.text((1066, 342), 'BOW-ON', fill=ACC, font=F(15))
y = 530
for line in ('Five heavy sear broadside guns a side (hbattery P, S)', 'Two Sear turrets, two spark flak twins (turret T, flak T)',
             'Seven radiator spires, four profiles', 'Two big ember bells, deep-set', 'Spearhead bow (no fork, no lance)',
             'Full insides: gun galleries, reactor, decks, frames'):
    d.text((856, y), '- ' + line, fill=INK, font=F(15)); y += 30
c.save(D + '/voidsworn_S8_sheet_overview.jpg', quality=90)

# 2. the whole-concept compare beside S8 (R229): the accepted shape and the build, whole, at the fitted camera; then the S8 sheet's
# true views over the blockout's at one length
c = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(c)
d.text((18, 10), 'voidsworn_S8 | whole concept beside the build (R229)', fill=INK, font=F(26))
paste(c, Image.open(REPO + '/contrib/codex/design/concept_round5_2026_11/voidsworn_S8_beauty.jpg').convert('RGB'), 18, 70, 615, 300)
paste(c, on_grey(R + '/beauty_cam.png'), 647, 70, 615, 300)
d.text((22, 48), 'S8 (shape of record, R185)', fill=ACC, font=F(17)); d.text((651, 48), 'Build, at the camera fitted to S8 (outline overlap 86 percent)', fill=ACC, font=F(17))
sh = Image.open(REPO + '/contrib/codex/design/concept_round5_2026_11/voidsworn_S8_sheet.jpg').convert('RGB')
st = sh.crop((15, 150, 1485, 500)).transpose(Image.Transpose.FLIP_LEFT_RIGHT); ss = sh.crop((15, 590, 1485, 850)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
bt = alpha_crop(R + '/top.png', 6).rotate(90, expand=True); bs = alpha_crop(R + '/side.png', 6)
W = 615
y = 382
for row, (a, b, nm, hmax) in enumerate(((st, bt, 'top', 150), (ss, bs, 'side', 112))):
    a = a.resize((W, int(a.height * W / a.width))); b = b.resize((W, int(b.height * W / b.width)))
    d.text((22, y), 'S8 sheet %s (flipped: bow left)' % nm, fill=DIM, font=F(14)); d.text((651, y), 'build %s, same length' % nm, fill=DIM, font=F(14))
    c.paste(a.crop((0, max(0, (a.height - hmax) // 2), W, max(0, (a.height - hmax) // 2) + min(hmax, a.height))), (18, y + 20))
    c.paste(b.crop((0, max(0, (b.height - hmax) // 2), W, max(0, (b.height - hmax) // 2) + min(hmax, b.height))), (647, y + 20))
    y += hmax + 30
c.save(D + '/voidsworn_S8_compare_S8.jpg', quality=90)

# 3. the battle camera
c = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(c)
paste(c, alpha_crop(R + '/beauty_cam_battle.png', 40), 10, 56, 1260, 660)
d.text((18, 10), 'voidsworn_S8 | battle camera (34 degrees above the board, port beam, range 170; unpainted)', fill=INK, font=F(22))
c.save(D + '/voidsworn_S8_battle_cam.jpg', quality=90)
print('pictures written')
