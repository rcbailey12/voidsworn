# the named pictures for issue 768 (each 1280 x 720, its code name on it): the sheet overview, the whole-concept compare beside
# IM5 (R229), the battle camera view; the weapon review comes from publish.py. Adapted from contrib/opus/tools/issue759/pictures.py.
# usage: python pictures.py RENDER_DIR IOU   (the build.py render folder, with beauty_cam_battle.png from the beauty mode;
#        IOU the outline overlap at the fitted camera, in percent, for the compare's caption)
import os, sys
from PIL import Image, ImageDraw, ImageFont
R = sys.argv[1]
IOU = sys.argv[2] if len(sys.argv) > 2 else '?'
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
D = REPO + '/docs/ship_pipeline/build_sheets/hegemony_IM5'
C = REPO + '/contrib/muse/design/iron_mandate_2026_11/round_2/'
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
d.text((18, 10), 'hegemony_IM5 | The Iron Mandate build sheet, first sheet (issue 768)', fill=INK, font=F(26))
d.text((18, 44), 'One Blender blockout, every view at one scale. Length 31.0 (game). Fit check 0, weapon match PASS, audit PASS.', fill=DIM, font=F(16))
paste(c, alpha_crop(R + '/side.png'), 18, 74, 820, 170); d.text((22, 76), 'TRUE SIDE (bow left)', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/top.png').rotate(90, expand=True), 18, 250, 820, 330); d.text((22, 252), 'TRUE TOP (bow left, port down)', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/cutaway.png'), 18, 586, 820, 130); d.text((22, 588), 'INSIDE (cutaway at the centreline)', fill=ACC, font=F(15))
paste(c, on_grey(R + '/threequarter.png'), 850, 74, 412, 260); d.text((854, 76), 'THREE-QUARTER', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/stern.png'), 850, 340, 200, 150); d.text((854, 342), 'ENGINE END', fill=ACC, font=F(15))
paste(c, alpha_crop(R + '/bow.png'), 1062, 340, 200, 150); d.text((1066, 342), 'BOW-ON', fill=ACC, font=F(15))
y = 506
for line in ('One broad wedge, an armoured canyon down its spine', 'Three low bridge decks, flush with the ridges',
             'Heavy lances sunk in shoulder pits (hturbo P, S)', 'Plasma lance on the mid bridge (turbo T)',
             'Picket lasers on the stern bridge (flak T)', 'Ion trench in the bow face (ion F); one low fin',
             'Six rectangular nozzles in one row; full insides'):
    d.text((856, y), '- ' + line, fill=INK, font=F(14)); y += 29
c.save(D + '/hegemony_IM5_sheet_overview.jpg', quality=90)

# 2. the whole-concept compare beside IM5 (R229): the accepted picture and the build, whole, at the fitted camera and at the
# standard three-quarter; then IM5's top view beside the blockout's, each whole (IM5 has no side view)
c = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(c)
d.text((18, 10), 'hegemony_IM5 | whole concept beside the build (R229)', fill=INK, font=F(26))
d.text((22, 46), 'IM5 (Ryan\'s pick, R255)', fill=ACC, font=F(15))
d.text((448, 46), 'Build at the camera fitted to IM5 (overlap %s%%)' % IOU, fill=ACC, font=F(15))
d.text((874, 46), 'Build, standard three-quarter', fill=ACC, font=F(15))
paste(c, Image.open(C + 'IM5.jpg').convert('RGB'), 18, 68, 414, 290)
paste(c, on_grey(R + '/beauty_cam.png'), 444, 68, 414, 290)
paste(c, on_grey(R + '/threequarter.png'), 870, 68, 392, 290)
top = Image.open(D + '/concept_IM5_top_bow_left.jpg').convert('RGB').crop((2, 30, 718, 350))
bt = alpha_crop(R + '/top.png', 6).rotate(90, expand=True)
d.text((22, 372), 'IM5 top view (turned: bow left; its own label covers the bow)', fill=DIM, font=F(14))
d.text((651, 372), 'build top, bow left, unpainted', fill=DIM, font=F(14))
paste(c, top, 18, 394, 615, 310)
paste(c, bt, 647, 394, 615, 310)
d.text((22, 700), 'unpainted blockout; the Hegemony paint stack is a later job', fill=DIM, font=F(13))
c.save(D + '/hegemony_IM5_compare_IM5.jpg', quality=90)

# 3. the battle camera
c = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(c)
paste(c, alpha_crop(R + '/beauty_cam_battle.png', 40), 10, 56, 1260, 660)
d.text((18, 10), 'hegemony_IM5 | battle camera (34 degrees above the board, port beam, range 170; unpainted)', fill=INK, font=F(22))
c.save(D + '/hegemony_IM5_battle_cam.jpg', quality=90)
print('pictures written')
