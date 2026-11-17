"""Rebuild the sheet and labeled R283 pictures from real CPU renders.

Use Blender's bundled Python (Pillow, numpy, scipy):
python assemble_R283.py BEFORE_RENDER_DIR AFTER_RENDER_DIR TEMP_SHEET_DIR CONTRACT_DIR
Copy only the resulting JPG, JSON and MD files to this sheet's repository folder.
The before design is main's corsair_A20.py before issue 861; raw output stays in TEMP.
"""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps
from scipy import ndimage

REPO = Path(__file__).resolve().parents[4]
BEFORE, AFTER, OUT, CONTRACT = map(Path, sys.argv[1:5])
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
Image.open(OUT / 'sheet.jpg').save(OUT / 'sheet.jpg', quality=85, optimize=True)
assert (OUT / 'sheet.jpg').stat().st_size < 8_000_000, 'Full construction sheet exceeds delivery limit'
for src, dst in (('corsair_A20_fit.json', 'fit.json'), ('corsair_A20_model.json', 'model.json'),
                 ('corsair_A20_weapon_match.json', 'weapon_match.json'), ('R283_geometry.json', 'R283_geometry.json')):
    shutil.copy2(AFTER / src, OUT / dst)
shutil.copy2(BEFORE / 'R283_geometry.json', OUT / 'R283_before_geometry.json')
shutil.copy2(CONTRACT / 'sheet_contract_selftest.json', OUT / 'R283_contract.json')

# Re-measure the silhouette at the existing concept camera; the saved IoU is older.
beauty = Image.open(REPO / 'contrib/muse/design/class_family_corsair_2026_11/corsair_A20_beauty.jpg').convert('RGB')
grey = np.asarray(beauty.convert('L'))
mask = ndimage.binary_opening(grey > 19, np.ones((3, 3)))
labels, _ = ndimage.label(mask)
sizes = np.bincount(labels.ravel()); sizes[0] = 0
mask = ndimage.binary_fill_holes(labels == sizes.argmax())


def overlap(folder):
    alpha = Image.open(folder / 'beauty_cam.png').getchannel('A')
    pred = np.asarray(alpha.resize(beauty.size, Image.Resampling.NEAREST)) > 8
    return round(100 * (pred & mask).sum() / (pred | mask).sum(), 2)


checks = json.loads((OUT / 'checks.json').read_text())
checks['outline_iou_percent'] = overlap(AFTER)
checks['outline_before_iou_percent'] = overlap(BEFORE)
checks.pop('mass_outline_iou_percent', None)
checks['outline_measure'] = 'Existing concept camera; luminance >19, 3x3 opening, largest component, filled holes; render alpha >8; reported, not a gate'
(OUT / 'checks.json').write_text(json.dumps(checks, indent=1) + '\n', encoding='utf-8')
overlay = np.asarray(beauty).copy()
pred = np.asarray(Image.open(AFTER / 'beauty_cam.png').getchannel('A').resize(beauty.size)) > 8
overlay[pred & ~mask] = (60, 170, 225)
overlay[mask & ~pred] = (225, 95, 65)
Image.fromarray(overlay).resize((1080, 720)).save(OUT / 'outline_check.jpg', quality=91)

# Prove that no other mesh, material assignment, transform or inside was changed.
before = json.loads((BEFORE / 'R283_geometry.json').read_text())
after = json.loads((AFTER / 'R283_geometry.json').read_text())
a, b = before['objects'], after['objects']
changed = [n for n in a if n not in b or a[n] != b[n]]
added = [n for n in b if n not in a]
allowed = ('A20_cheek_H1', 'A20_cheek_H2', 'L0_', 'L3_')
unexpected = [n for n in changed + added if not n.startswith(allowed)]
insides = [n for n in a if a[n]['role'] == 'inside']
fit = json.loads((OUT / 'fit.json').read_text())
match = json.loads((OUT / 'weapon_match.json').read_text())
contract = json.loads((OUT / 'R283_contract.json').read_text())
bm = json.loads((BEFORE / 'corsair_A20_model.json').read_text())
am = json.loads((AFTER / 'corsair_A20_model.json').read_text())
assert not unexpected, 'Unexpected geometry changes: ' + ', '.join(unexpected)
assert all(a[n] == b[n] for n in insides), 'An inside changed'
assert bm['inside'] == am['inside'] and bm['points'] == am['points'], 'Inside or hard point records changed'
assert all(f == next(g for g in am['features'] if g['id'] == f['id'])
           for f in bm['features'] if f['id'] not in ('L0', 'L3')), 'A fitting other than the two cheek lamps changed'
assert before['class_length'] == after['class_length'] == 16.5
assert before['model_length'] == after['model_length']
assert not any(fit['counts'].values()), fit['counts']
assert match['result'] == 'PASS' and contract['ok'] and checks['PASS']
validation = dict(issue=861, ruling='R283', code='corsair_A20', result='PASS', device=after['device'],
                  design_sha256=hashlib.sha256((SHEETS / 'ships/corsair_A20.py').read_bytes()).hexdigest(),
                  class_length=after['class_length'], extent_before=before['model_length'], extent_after=after['model_length'],
                  triangles_before=before['triangles'], triangles_after=after['triangles'],
                  exterior_meshes=after['exterior_meshes'], exterior_materials=after['exterior_materials'],
                  geometry_scope=dict(changed=changed, added=added, unexpected=unexpected,
                                      unchanged_meshes=len(a) - len(changed), unchanged_inside_meshes=len(insides),
                                      hardpoints_unchanged=True, bay_and_craft_unchanged=True,
                                      other_fittings_unchanged=True),
                  fit=dict(result='PASS', counts=fit['counts'], tested=fit['tested']),
                  contract=dict(result='PASS', checks=len(contract['rows'])), weapon_match=match,
                  sheet_measurements=checks,
                  method='A20 design file and the existing Hullbreaker sheet kit; Cycles CPU, 12 samples; unchanged insides and paint stack')
(OUT / 'R283_validation.json').write_text(json.dumps(validation, indent=1) + '\n', encoding='utf-8')

BG, INK, DIM, ACC = (28, 31, 36), (235, 234, 227), (179, 184, 190), (240, 177, 88)


def font(size):
    return ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size)


def paste(canvas, im, box):
    im = ImageOps.contain(im.convert('RGBA'), box[2:], Image.Resampling.LANCZOS)
    canvas.paste(im, (box[0] + (box[2] - im.width) // 2, box[1] + (box[3] - im.height) // 2), im)


for side in ('port', 'starboard'):
    canvas = Image.new('RGB', (1280, 720), BG)
    draw = ImageDraw.Draw(canvas)
    draw.text((18, 12), 'A20 / THE DEN / R283 / ' + side.upper() + ' HANGAR CHEEK', font=font(26), fill=INK)
    draw.text((18, 51), 'ACCEPTED CONCEPT DETAIL', font=font(20), fill=ACC)
    draw.text((442, 51), 'BEFORE / MERGED R244', font=font(20), fill=ACC)
    draw.text((866, 51), 'AFTER / FACETED CHEEK', font=font(20), fill=ACC)
    # This is the same near mouth and shoulder Ryan circled in his marked picture.
    paste(canvas, beauty.crop((1120, 515, 1665, 1055)), (12, 92, 400, 510))
    for folder, x in ((BEFORE, 438), (AFTER, 862)):
        # Identical sub-frustum and scale, preserving the actual concept camera.
        im = Image.open(folder / ('cheek_' + side + '.png')).convert('RGBA')
        paste(canvas, im.crop((0, 0, im.width, int(im.height * 0.84))), (x, 92, 400, 510))
    draw.text((18, 615), 'Broad bevel, layered plates, lower lip.', font=font(18), fill=DIM)
    draw.text((442, 615), 'Flat wall beside the bay opening.', font=font(18), fill=DIM)
    draw.text((866, 615), 'Sloped shoulder and stepped lower facets.', font=font(18), fill=DIM)
    caption = 'Port: existing concept camera. Same camera and light before/after. Sheet colours; paint remains issue 726.'
    if side == 'starboard':
        caption = 'Starboard: mirrored concept camera. Concept detail is the near port cheek; light is unchanged.'
    draw.text((18, 680), caption, font=font(18), fill=DIM)
    name = 'A20_hangar_R283_before_after.jpg' if side == 'port' else 'A20_hangar_starboard_R283_before_after.jpg'
    canvas.save(OUT / name, quality=94)

canvas = Image.new('RGB', (1280, 720), BG)
draw = ImageDraw.Draw(canvas)
draw.text((18, 14), 'A20 / THE DEN / R283 / FULL THREE-QUARTER', fill=INK, font=font(26))
paste(canvas, Image.open(AFTER / 'threequarter.png'), (8, 55, 1264, 610))
draw.text((18, 679), 'Both hangar cheeks faceted. Carrier class length 16.5. CPU build sheet; existing paint stack unchanged.', fill=DIM, font=font(18))
canvas.save(OUT / 'A20_R283_threequarter.jpg', quality=94)
canvas = Image.new('RGB', (1280, 720), BG)
draw = ImageDraw.Draw(canvas)
draw.text((18, 14), 'A20 / THE DEN / WHOLE CONCEPT AND R283 BUILD', fill=INK, font=font(26))
draw.text((18, 76), 'ACCEPTED CONCEPT', fill=ACC, font=font(21))
draw.text((658, 76), 'AFTER / CPU BUILD SHEET', fill=ACC, font=font(21))
paste(canvas, beauty, (12, 112, 616, 520))
paste(canvas, Image.open(AFTER / 'beauty_cam.png'), (652, 112, 616, 520))
draw.text((18, 678), 'R283 geometry at the existing concept camera. Paint and in-game captures below predate this cheek correction.', fill=DIM, font=font(18))
canvas.save(OUT / 'beauty_vs_blockout.jpg', quality=94)
print('PASS R283 sheet, geometry scope and labeled 1280 x 720 pictures:', OUT)
