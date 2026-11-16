"""Assemble the R244 sheet and 1280 x 720 comparisons from real CPU captures.

Use Blender's bundled Python (Pillow, numpy, scipy):
python assemble_R244.py BEFORE_RENDER_DIR AFTER_RENDER_DIR OUTPUT_DIR
The render script is render_R244.py beside this file. Keep raw renders in TEMP.
"""
from pathlib import Path
import json
import shutil
import subprocess
import sys
import textwrap

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps
from scipy import ndimage

REPO = Path(__file__).resolve().parents[4]
BEFORE, AFTER, OUT = map(Path, sys.argv[1:4])
OUT.mkdir(parents=True, exist_ok=True)
SHEETS = REPO / 'tools/blender/build_sheets'
for command in (
    ['inventory.py', 'corsair_A20', str(REPO), str(OUT), str(AFTER / 'corsair_A20_model.json')],
    ['sheet_extras.py', 'corsair_A20', str(AFTER), str(REPO), str(OUT), str(BEFORE / 'corsair_A20_fit.json')],
    ['layout.py', str(AFTER), str(REPO), str(OUT)],
):
    subprocess.run([sys.executable, str(SHEETS / command[0]), *command[1:]], check=True, cwd=REPO)
for name in ('side', 'top', 'underside', 'bow', 'stern', 'cutaway', 'threequarter'):
    Image.open(OUT / (name + '.png')).convert('RGB').save(OUT / (name + '.jpg'), quality=92)
Image.open(AFTER / 'weapon_turret.png').convert('RGB').save(OUT / 'weapon_turret.jpg', quality=92)
for src, dst in (('corsair_A20_fit.json', 'fit.json'), ('corsair_A20_model.json', 'model.json'),
                 ('R244_geometry.json', 'R244_geometry.json')):
    shutil.copy2(AFTER / src, OUT / dst)
shutil.copy2(BEFORE / 'R244_geometry.json', OUT / 'R244_before_geometry.json')

# Re-score at the existing concept camera. Its saved IoU belongs to an older hull.
beauty = Image.open(REPO / 'contrib/muse/design/class_family_corsair_2026_11/corsair_A20_beauty.jpg').convert('RGB')
grey = np.asarray(beauty.convert('L'))
mask = ndimage.binary_opening(grey > 19, np.ones((3, 3)))
labels, count = ndimage.label(mask)
sizes = np.bincount(labels.ravel()); sizes[0] = 0
mask = ndimage.binary_fill_holes(labels == sizes.argmax())
def overlap(folder):
    alpha = Image.open(folder / 'beauty_cam.png').getchannel('A')
    pred = np.asarray(alpha.resize(beauty.size, Image.Resampling.NEAREST)) > 8
    return round(100 * (pred & mask).sum() / (pred | mask).sum(), 2)
checks = json.loads((OUT / 'checks.json').read_text())
checks['outline_iou_percent'] = overlap(AFTER)
checks.pop('mass_outline_iou_percent', None)
checks['outline_before_iou_percent'] = overlap(BEFORE)
checks['outline_measure'] = 'same existing camera; beauty luminance >19, 3x3 opening, largest component, filled holes; render alpha >8; reported, not a gate'
(OUT / 'checks.json').write_text(json.dumps(checks, indent=1) + '\n', encoding='utf-8')
Image.open(AFTER / 'beauty_cam.png').convert('RGBA').save(OUT / 'outline_render.png')
overlay = np.asarray(beauty).copy()
pred = np.asarray(Image.open(AFTER / 'beauty_cam.png').getchannel('A').resize(beauty.size)) > 8
overlay[pred & ~mask] = (60, 170, 225)
overlay[mask & ~pred] = (225, 95, 65)
Image.fromarray(overlay).resize((1080, 720)).save(OUT / 'outline_check.jpg', quality=91)

BG, INK, DIM, ACCENT = (28, 31, 36), (235, 234, 227), (179, 184, 190), (240, 177, 88)
def font(size):
    return ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size)
def raw(folder, name):
    im = Image.open(folder / (name + '.png')).convert('RGBA')
    bbox = im.getchannel('A').getbbox()
    return im.crop(bbox) if bbox else im
def paste(canvas, im, box):
    im = ImageOps.contain(im, (box[2], box[3]), Image.Resampling.LANCZOS).convert('RGBA')
    canvas.paste(im, (box[0] + (box[2] - im.width) // 2, box[1] + (box[3] - im.height) // 2), im)
def notes(draw, x, y, message):
    for line in textwrap.wrap(message, 39):
        draw.text((x, y), line, fill=DIM, font=font(19)); y += 24
for view in ('bow', 'side'):
    canvas = Image.new('RGB', (1280, 720), BG)
    d = ImageDraw.Draw(canvas)
    d.text((18, 10), 'A20 / THE DEN / R244 / ' + ('BOW OPENINGS' if view == 'bow' else 'ANGULAR FLANKS'), fill=INK, font=font(26))
    d.text((18, 48), 'ACCEPTED CONCEPT', fill=ACCENT, font=font(20))
    d.text((442, 48), 'BEFORE', fill=ACCENT, font=font(20))
    d.text((866, 48), 'AFTER / CPU BUILD SHEET', fill=ACCENT, font=font(20))
    for x in (426, 850):
        d.line((x, 48, x, 672), fill=(65, 70, 78), width=2)
    paste(canvas, beauty, (12, 80, 400, 268))
    crop = (110, 735, 830, 1230) if view == 'bow' else (1150, 220, 1890, 910)
    paste(canvas, beauty.crop(crop), (12, 375, 400, 260))
    for folder, x in ((BEFORE, 438), (AFTER, 862)):
        if view == 'bow':
            im = Image.open(folder / 'bow_detail.png').convert('RGBA')
            paste(canvas, im.crop((275, 180, 1160, 635)), (x, 83, 400, 285))
            paste(canvas, im.crop((370, 305, 800, 520)), (x, 395, 400, 205))
        else:
            paste(canvas, raw(folder, 'flank_detail'), (x, 85, 400, 260))
            top = raw(folder, 'top').transpose(Image.Transpose.ROTATE_90)
            paste(canvas, top, (x, 395, 400, 205))
    d.text((18, 350), 'Concept detail', fill=DIM, font=font(18))
    d.text((442, 367), 'Intake detail' if view == 'bow' else 'Plan / bow left', fill=DIM, font=font(18))
    d.text((866, 367), 'Intake detail' if view == 'bow' else 'Plan / bow left', fill=DIM, font=font(18))
    notes(d, 442, 610, 'Bores closed after 0.14 units.' if view == 'bow' else 'Straight walls and a constant-width slab.')
    notes(d, 866, 610, '2.08 units clear to the rear baffles; stepped rings and rolled lips.' if view == 'bow' else 'Broad shoulder facets, lower chines, a recessed waist and stepped armour.')
    d.text((18, 686), 'Same cameras and light. Geometry proof in sheet colours; GPU paint and in-game review follow with the Board.', fill=DIM, font=font(18))
    canvas.save(OUT / ('A20_' + view + '_R244_before_after.jpg'), quality=94)

for name in ('bow_detail', 'flank_detail', 'flank_starboard'):
    canvas = Image.new('RGB', (1280, 720), BG)
    paste(canvas, Image.open(AFTER / (name + '.png')), (0, 32, 1280, 668))
    ImageDraw.Draw(canvas).text((18, 8), 'A20 / R244 / ' + name.replace('_', ' ').upper() + ' / CPU BUILD SHEET', fill=INK, font=font(23))
    canvas.save(OUT / ('A20_' + name + '_after.jpg'), quality=94)
canvas = Image.new('RGB', (1280, 720), BG)
d = ImageDraw.Draw(canvas)
d.text((18, 14), 'A20 / THE DEN / WHOLE CONCEPT AND R244 BUILD', fill=INK, font=font(26))
d.text((18, 76), 'ACCEPTED CONCEPT', fill=ACCENT, font=font(21))
d.text((658, 76), 'AFTER / CPU BUILD SHEET', fill=ACCENT, font=font(21))
paste(canvas, beauty, (12, 112, 616, 520))
paste(canvas, Image.open(AFTER / 'beauty_cam.png'), (652, 112, 616, 520))
d.text((18, 678), 'R244 geometry proof. Same concept camera; the accepted Hullbreaker paint stack is queued separately by the Board.', fill=DIM, font=font(18))
canvas.save(OUT / 'beauty_vs_blockout.jpg', quality=94)
print('R244 sheet and labeled 1280 x 720 comparisons:', OUT)
