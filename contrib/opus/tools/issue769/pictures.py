# Issue 769 helper (sandbox only): the named pictures for the Sunward craft sheets, each 1280 x 720 with its code name on it:
# per craft the sheet overview and the whole concept beside the build (R229); for the pair, the two craft beside the S8 flagship at
# true game scale and the battle camera read at game size (the weapon reviews come from publish.py).
# usage: python pictures.py SF3_RENDER_DIR SB4_RENDER_DIR SCALE_PNG BATTLE_PNG
#   the render dirs are build.py's render folders (beauty_cam.png from the fitted camera); SCALE_PNG and BATTLE_PNG come from
#   game_view.py (the scale view with GV_FULL=1 and a closer camera; the battle view at the battle camera, its middle third)
import os, sys, json
from PIL import Image, ImageDraw, ImageFont

R = {'SF3': sys.argv[1], 'SB4': sys.argv[2]}
SCALE, BATTLE = sys.argv[3], sys.argv[4]
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
D = {c: REPO + '/docs/ship_pipeline/build_sheets/voidsworn_' + c for c in R}
CON = {c: REPO + '/contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/%s.jpg' % c for c in R}
GREY = (44, 44, 46); INK = (240, 232, 218); DIM = (190, 186, 178); ACC = (240, 170, 80)


def F(n):
    return ImageFont.truetype(next((f_ for f_ in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf') if os.path.exists(f_)), None), n)


def on_grey(path):
    im = Image.open(path).convert('RGBA'); bg = Image.new('RGBA', im.size, (58, 58, 60, 255)); bg.alpha_composite(im); return bg.convert('RGB')


def alpha_crop(path, pad=16):
    im = Image.open(path).convert('RGBA'); x0, y0, x1, y1 = im.getchannel('A').getbbox()
    im = im.crop((max(0, x0 - pad), max(0, y0 - pad), min(im.width, x1 + pad), min(im.height, y1 + pad)))
    bg = Image.new('RGBA', im.size, (58, 58, 60, 255)); bg.alpha_composite(im); return bg.convert('RGB')


def paste(c, im, x, y, w, h):
    im = im.copy(); im.thumbnail((w, h), Image.Resampling.LANCZOS); c.paste(im, (x + (w - im.width) // 2, y + (h - im.height) // 2))


LINES = {
    'SF3': ('voidsworn_SF3 | Spire Dart fighter (data.js fighter), first sheet (issue 769)',
            ['One forged blade, a thin knife edge, no wings', 'Interceptor guns: three barrels on a traverse ring (guns T)',
             'One radiator spire, ember fins (the flagship\'s spire line, reduced to one)', 'Two deep bells in armoured cowls',
             'No canopy: an armoured sensor slit', 'Length 1.6 (drawn 3.84 on the board, scale.md)']),
    'SB4': ('voidsworn_SB4 | Magazine Block bomber (data.js bomber), first sheet (issue 769)',
            ['One faceted block built round its magazine', 'Bomb payload: two big tube mouths in the bow cassette (bombs T)',
             'Two magazine ridges, armour belts on the flanks', 'Four deep bells in armoured cowls',
             'No canopy, no bombs outside the hull', 'Length 1.6 (drawn 3.84 on the board, scale.md)']),
}
for c, rd in R.items():
    # 1. the sheet overview
    im = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(im)
    d.text((18, 10), LINES[c][0], fill=INK, font=F(24))
    d.text((18, 44), 'One Blender blockout, every view at one scale. Fit check 0, weapon match PASS, contract and audit PASS. Unpainted.', fill=DIM, font=F(16))
    paste(im, alpha_crop(rd + '/side.png'), 18, 74, 820, 200); d.text((22, 76), 'TRUE SIDE (bow left)', fill=ACC, font=F(15))
    paste(im, alpha_crop(rd + '/top.png').rotate(90, expand=True), 18, 280, 820, 230); d.text((22, 282), 'TRUE TOP (bow left, port down)', fill=ACC, font=F(15))
    paste(im, alpha_crop(rd + '/cutaway.png'), 18, 516, 820, 190); d.text((22, 518), 'INSIDE (cutaway): small, for the build contract', fill=ACC, font=F(15))
    paste(im, on_grey(rd + '/threequarter.png'), 850, 74, 412, 260); d.text((854, 76), 'THREE-QUARTER', fill=ACC, font=F(15))
    paste(im, alpha_crop(rd + '/stern.png'), 850, 340, 200, 170); d.text((854, 342), 'ENGINE END', fill=ACC, font=F(15))
    paste(im, alpha_crop(rd + '/bow.png'), 1062, 340, 200, 170); d.text((1066, 342), 'BOW-ON', fill=ACC, font=F(15))
    y = 524
    for line in LINES[c][1]:
        d.text((856, y), '- ' + line, fill=INK, font=F(14)); y += 30
    im.save(D[c] + '/voidsworn_%s_sheet_overview.jpg' % c, quality=90)
    # 2. the whole concept beside the build (R229): the picture and the blockout at the camera fitted to it, whole
    cam = json.load(open(REPO + '/tools/blender/build_sheets/ships/voidsworn_%s_camera.json' % c))
    im = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(im)
    d.text((18, 10), 'voidsworn_%s | the whole concept beside the build (R229)' % c, fill=INK, font=F(26))
    paste(im, Image.open(CON[c]).convert('RGB'), 18, 90, 615, 420)
    b = Image.open(rd + '/beauty_cam.png').convert('RGBA'); bg = Image.new('RGBA', b.size, (14, 14, 16, 255)); bg.alpha_composite(b)
    paste(im, bg.convert('RGB'), 647, 90, 615, 420)
    d.text((22, 62), '%s (concept of record, R255)' % c, fill=ACC, font=F(17))
    d.text((651, 62), 'Build, unpainted, at the camera fitted to %s (outline overlap %d percent)' % (c, round(cam['iou'] * 100)), fill=ACC, font=F(16))
    notes = {'SF3': ['Kept: the forged blade, the gun cluster in the bow, one spire on the stern block, two drives in the stern face.',
                     'Changed: the spire is square-topped with fins out to the sides (never a tail fin); the bells shrunk and dimmed, sunk in armoured',
                     'cowls (production notes); an armoured sensor slit for the pilot; the guns turn on a traverse ring (data.js arc T).',
                     'Paint (the frost-white edge stripe, trim) is the Sunward stack, applied later (issue 756).'],
             'SB4': ['Kept: the massive faceted block, two big bow mouths with heavy rims, the sight slit between them, two dorsal ridges,',
                     'ember drives in the stern. Changed: the four drives are bells sunk in armoured cowls in the stern face; the flank panels',
                     'became one forged belt a side (bold, never fine greeble); the tubes are fixed forward, the bomber turns to aim.',
                     'Paint (the frost-white oath band, ember trim) is the Sunward stack, applied later (issue 756).']}[c]
    y = 530
    for line in notes:
        d.text((22, y), line, fill=INK, font=F(16)); y += 28
    im.save(D[c] + '/voidsworn_%s_compare_%s.jpg' % (c, c), quality=90)

# 3. the two craft beside the S8 flagship at true game scale: an orthographic view (every length on the picture to scale), the
# lengths measured off the picture itself, and the craft enlarged x4 below
import numpy as np
from scipy import ndimage
im = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(im)
sc = Image.open(SCALE).convert('RGB'); a = np.asarray(sc).astype(int); bgc = np.median(a.reshape(-1, 3), axis=0)
fg = ndimage.binary_closing(np.abs(a - bgc).sum(2) > 20, np.ones((5, 5))); lab, n = ndimage.label(fg)
objs = ndimage.find_objects(lab); sz = ndimage.sum(fg, lab, range(1, n + 1)); big = [objs[i] for i in np.argsort(-sz)[:3]]
s8 = max(big, key=lambda o: o[1].stop - o[1].start); cr = [o for o in big if o is not s8]
ppu = sc.width / float(os.environ.get('GV_ORTHO', 72))
L8 = (s8[1].stop - s8[1].start) / ppu; Lc = [(o[1].stop - o[1].start) / ppu for o in cr]
y0 = min(o[0].start for o in big) - 20; y1 = max(o[0].stop for o in big) + 20
band = sc.crop((max(0, s8[1].start - 20), y0, min(sc.width, max(o[1].stop for o in big) + 20), y1))
k = min(1260 / band.width, 1.0); band = band.resize((int(band.width * k), int(band.height * k)), Image.Resampling.LANCZOS)
im.paste(band, (10, 76))
d.text((18, 10), 'voidsworn_SF3 and voidsworn_SB4 beside voidsworn_S8 at true game scale (board units, orthographic)', fill=INK, font=F(22))
d.text((18, 42), 'Measured on this picture: S8 %.1f long, the two craft %.1f and %.1f (game: 43.2 and 3.84; scale.md). Unpainted.' % (L8, Lc[0], Lc[1]),
       fill=DIM, font=F(16))
cx0 = min(o[1].start for o in cr) - 12; cx1 = max(o[1].stop for o in cr) + 12; cy0 = min(o[0].start for o in cr) - 12; cy1 = max(o[0].stop for o in cr) + 12
ins = sc.crop((cx0, cy0, cx1, cy1)); f4 = min(4, 600 // ins.width, (720 - 100 - band.height - 70) // ins.height)
ins = ins.resize((ins.width * f4, ins.height * f4), Image.Resampling.LANCZOS)
Y = 76 + band.height + 40
im.paste(ins, (1270 - ins.width, Y)); d.rectangle((1269 - ins.width, Y - 1, 1270, Y + ins.height), outline=ACC, width=1)
d.text((1270 - ins.width, Y - 22), 'the two craft enlarged x%d (fighter above, bomber below)' % f4, fill=ACC, font=F(15))
yy = Y
for line in ('A craft is about a twelfth of the flagship\'s length.', 'Both craft are the same length (scale.md Squadron rows);',
             'the bomber is about twice as wide and three times as deep.', 'Wings fly in fours (godot/render/squadron_wing.gd).'):
    d.text((18, yy), line, fill=INK, font=F(17)); yy += 30
im.save(D['SF3'] + '/voidsworn_SF3_SB4_true_scale.jpg', quality=90)
print('scale: S8 %.2f, craft %s' % (L8, ', '.join('%.2f' % v for v in Lc)))

# 4. the battle camera: the game's own pixel size (the frame at 1:1), then each wing enlarged with whole pixels (no smoothing)
import numpy as np
im = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(im)
bt = Image.open(BATTLE).convert('RGB')
d.text((18, 10), 'voidsworn_SF3 and voidsworn_SB4 | battle camera, game size, wings of four (unpainted)', fill=INK, font=F(22))
d.text((18, 38), 'The game camera: fov 45, range 170, 34 degrees above the board. Left: the middle of a 1080p screen at 1:1. Right: each wing x4.', fill=DIM, font=F(15))
im.paste(bt, (10, 90)); d.rectangle((9, 89, 10 + bt.width, 90 + bt.height), outline=ACC, width=1)
d.text((12, 66), 'native pixels (1:1)', fill=ACC, font=F(15))
a = np.asarray(bt).astype(int); bgc = np.median(a.reshape(-1, 3), axis=0); fg = np.abs(a - bgc).sum(2) > 18
for k_, (lab, half) in enumerate((('voidsworn_SF3 fighters, x4', slice(0, bt.width // 2)), ('voidsworn_SB4 bombers, x4', slice(bt.width // 2, bt.width)))):
    ys, xs = np.where(fg[:, half]); x0 = xs.min() + half.start; x1 = xs.max() + half.start; y0, y1 = ys.min(), ys.max()
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2; w, h = 148, 76
    crop = bt.crop((cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2)).resize((w * 4, h * 4), Image.Resampling.NEAREST)
    X, Y = 670, 90 + k_ * 320
    im.paste(crop, (X, Y)); d.rectangle((X - 1, Y - 1, X + crop.width, Y + crop.height), outline=ACC, width=1)
    d.text((X, Y - 22), lab, fill=ACC, font=F(15))
y = 470
for line in ('Fighter: a slim dark dart, one ember point (the spire) and two', 'small ember drives. Bomber: a broad dark block, four ember',
             'drives aft, the sight slit glowing between the bow mouths.', 'They read apart by mass and outline at every heading shown;',
             'the bomber\'s two mouths themselves show only at the close cameras.'):
    d.text((14, y), line, fill=INK, font=F(16)); y += 28
im.save(D['SF3'] + '/voidsworn_SF3_SB4_battle_cam.jpg', quality=92)
print('pictures written')
