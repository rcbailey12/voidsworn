# the named pictures for issue 759 (each 1280 x 720, its code name on it): the sheet overview, the whole-concept compare beside
# H10 (R229), the battle camera view; the weapon review comes from publish.py. Adapted from contrib/opus/tools/issue738/pictures.py.
# usage: python pictures.py RENDER_DIR IOU   (the build.py render folder, with beauty_cam_battle.png from the beauty mode;
#        IOU the outline overlap at the fitted camera, in percent, for the compare's caption)
import os, sys
from PIL import Image, ImageDraw, ImageFont
R = sys.argv[1]
IOU = sys.argv[2] if len(sys.argv) > 2 else '?'
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
D = REPO + '/docs/ship_pipeline/build_sheets/hegemony_H10'
C = REPO + '/contrib/muse/design/concept_round7_2026_11/'
GREY = (44, 44, 46); INK = (236, 236, 240); DIM = (186, 190, 198); ACC = (120, 190, 245)


def F(n):
    return ImageFont.truetype(next((f_ for f_ in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf') if os.path.exists(f_)), None), n)


def on_grey(path):
    im = Image.open(path).convert('RGBA')
    bg = Image.new('RGBA', im.size, (58, 58, 60, 255)); bg.alpha_composite(im)
    return bg.convert('RGB')


def fit(im, w, h):
    im = im.copy(); im.thumbnail((w, h), Image.Resampling.LANCZOS); return im


def paste(c, im, x, y, w, h):
    im = fit(im, w, h); c.paste(im, (x + (w - im.width) // 2, y + (h - im.height) // 2))


def alpha_crop(path, pad=20):
    im = Image.open(path).convert('RGBA'); x0, y0, x1, y1 = im.getchannel('A').getbbox()
    im = im.crop((max(0, x0 - pad), max(0, y0 - pad), min(im.width, x1 + pad), min(im.height, y1 + pad)))
    bg = Image.new('RGBA', im.size, (58, 58, 60, 255)); bg.alpha_composite(im); return bg.convert('RGB')


os.makedirs(D, exist_ok=True)
# 1. the sheet overview
c = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(c)
d.text((18, 10), 'hegemony_H10 | Dominion dreadnought build sheet, first sheet (issue 759)', fill=INK, font=F(26))
d.text((18, 44), 'One Blender blockout, every view at one scale. Length 21.0 (game). Fit check 0, weapon match PASS, audit PASS.', fill=DIM, font=F(16))
paste(c, alpha_crop(R + '/side.png'), 18, 74, 820, 200); d.text((22, 76), 'TRUE SIDE (bow left)', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/top.png').rotate(90, expand=True), 18, 280, 820, 300); d.text((22, 282), 'TRUE TOP (bow left, port down)', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/cutaway.png'), 18, 586, 820, 130); d.text((22, 588), 'INSIDE (cutaway at the centreline)', fill=ACC, font=F(15))
paste(c, on_grey(R + '/threequarter.png'), 850, 74, 412, 260); d.text((854, 76), 'THREE-QUARTER', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/stern.png'), 850, 340, 200, 170); d.text((854, 342), 'ENGINE END', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/bow.png'), 1062, 340, 200, 170); d.text((1066, 342), 'BOW-ON', fill=ACC, font=F(15))
y = 524
for line in ('Two heavy plasma lance turrets, sunk low (hturbo P, S)', 'Ion cannon: a trench in the blunt bow face (ion F)',
             'Two twin picket laser turrets on the belly (flak T)', 'One low sensor fin; flush armoured drone doors',
             'Four rectangular nozzles in one flat row', 'Full insides: corridors, reactor, hangar, racks'):
    d.text((856, y), '- ' + line, fill=INK, font=F(15)); y += 30
c.save(D + '/hegemony_H10_sheet_overview.jpg', quality=90)

# 2. the whole-concept compare beside H10 (R229): the accepted shape and the build, whole, at the fitted camera; then the H10 sheet's
# true views over the blockout's at one length
c = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(c)
d.text((18, 10), 'hegemony_H10 | whole concept beside the build (R229)', fill=INK, font=F(26))
paste(c, Image.open(C + 'hegemony_H10_beauty.jpg').convert('RGB'), 18, 70, 615, 300)
paste(c, on_grey(R + '/beauty_cam.png'), 647, 70, 615, 300)
d.text((22, 48), 'H10 (shape of record, R198)', fill=ACC, font=F(17)); d.text((651, 48), 'Build, unpainted, at the camera fitted to H10 (outline overlap %s percent)' % IOU, fill=ACC, font=F(15))
sh = Image.open(C + 'hegemony_H10_sheet.jpg').convert('RGB')
st = sh.crop((125, 92, 1790, 740)).transpose(Image.Transpose.FLIP_LEFT_RIGHT); ss = sh.crop((125, 838, 1790, 1166)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
bt = alpha_crop(R + '/top.png', 6).rotate(90, expand=True); bs = alpha_crop(R + '/side.png', 6)
W = 615
y = 382
for a, b, nm, hmax in ((st, bt, 'top', 200), (ss, bs, 'side', 82)):
    a = a.resize((W, int(a.height * W / a.width))); b = b.resize((W, int(b.height * W / b.width)))
    d.text((22, y), 'H10 sheet %s (flipped: bow left)' % nm, fill=DIM, font=F(14)); d.text((651, y), 'build %s, same length' % nm, fill=DIM, font=F(14))
    c.paste(a.crop((0, max(0, (a.height - hmax) // 2), W, max(0, (a.height - hmax) // 2) + min(hmax, a.height))), (18, y + 20))
    c.paste(b.crop((0, max(0, (b.height - hmax) // 2), W, max(0, (b.height - hmax) // 2) + min(hmax, b.height))), (647, y + 20))
    y += hmax + 30
c.save(D + '/hegemony_H10_compare_H10.jpg', quality=90)

# 3. the battle camera
c = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(c)
paste(c, alpha_crop(R + '/beauty_cam_battle.png', 40), 10, 56, 1260, 660)
d.text((18, 10), 'hegemony_H10 | battle camera (34 degrees above the board, port beam, range 170; unpainted)', fill=INK, font=F(22))
c.save(D + '/hegemony_H10_battle_cam.jpg', quality=90)
print('pictures written')
