"""Issue 426: measure rendered pixels and build before-above-after strips from the kept bench runs.

python rebake_evidence.py --before DIR --after DIR --measure DIR --out DIR
All measurements read rendered PNGs. The lit-edge threshold is 30/255 over the black measurement background.
"""
import argparse
import json
import pathlib
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

p = argparse.ArgumentParser()
for flag in ['before', 'after', 'measure', 'out']:
    p.add_argument('--' + flag, required=True, type=pathlib.Path)
a = p.parse_args()
a.out.mkdir(parents=True, exist_ok=True)
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 20)
small = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 16)
targets = {'macro': [56, .12], 'torpedo': [154, .16], 'frigate': [216, .18], 'cruiser': [302, .20], 'capital': [423, .22],
           'macro_reduced': [56, .42], 'torpedo_reduced': [154, .50], 'frigate_reduced': [216, .55],
           'cruiser_reduced': [302, .60], 'capital_reduced': [423, .65], 'macro_body': [48, .50], 'torpedo_body': [140, .90]}
measurements = {}
for name, (px, life) in targets.items():
    frames = []
    raster_frames = []
    for file in sorted((a.measure / name).glob('*.png')):
        arr = np.asarray(Image.open(file).convert('RGB'))[100:980, 300:1620]
        if np.count_nonzero(arr.max(-1) > 1) >= 12:
            raster_frames.append(int(file.stem))
        components, count = ndimage.label(arr.max(-1) > 30)
        sizes = np.bincount(components.ravel())
        keep = sizes >= 12   # discard isolated spark/debris points; the table measures the flash and gas
        keep[0] = False
        yy, xx = np.nonzero(keep[components])
        width = int(max(xx.max() - xx.min() + 1, yy.max() - yy.min() + 1)) if len(xx) else 0
        frames.append({'frame': int(file.stem), 'pixels': width})
    peak = max(frames, key=lambda x: x['pixels'])
    alive = [r['frame'] for r in frames if r['pixels']]
    measurements[name] = {'target_px': px, 'target_life': life, 'peak_px': peak['pixels'], 'peak_frame': peak['frame'],
                          'bright_seconds': (max(alive) - min(alive) + 1) / 60 if alive else 0,
                          'visible_seconds': (max(raster_frames) - min(raster_frames) + 1) / 60 if raster_frames else 0,
                          'within_size_tolerance': abs(peak['pixels'] - px) <= .15 * px, 'frames': frames}
(a.out / 'measurements.json').write_text(json.dumps(measurements, indent=2) + '\n')

runs = [json.loads((d / 'bench.json').read_text()) for d in [a.before, a.after]]
labels = ['Before', 'After: B core']
overview = []
for row in runs[1]['stills']:
    if row.get('part') != 'moments': continue
    old = next(r for r in runs[0]['stills'] if r.get('id') == row['id'] and r.get('cam') == row['cam'])
    rows = []
    for root, meta, label in zip([a.before, a.after], [old, row], labels):
        img = Image.open(root / meta['file']).convert('RGB')
        cw = img.width // len(meta['cells'])
        strip = Image.new('RGB', (img.width, img.height + 58), '#0c1013')
        strip.paste(img, (0, 58))
        draw = ImageDraw.Draw(strip)
        for i, cell in enumerate(meta['cells']):
            draw.text((i * cw + 8, 7), '%s  %.3f s' % (label, cell['t']), font=font, fill='#dce4d8')
        rows.append(strip)
    sheet = Image.new('RGB', (max(x.width for x in rows), sum(x.height for x in rows)), '#0c1013')
    sheet.paste(rows[0], (0, 0)); sheet.paste(rows[1], (0, rows[0].height))
    sheet.save(a.out / ('%s_c%d_all.jpg' % (row['id'], row['cam'])), quality=88)
    if row['cam'] == 170 and row['id'] in ['w_torp_void_hull', 'd_cruiser']:
        cw = rows[1].width // len(row['cells'])
        # Three early frames at original source resolution, then one cell after the flash.
        indices = [2, 3, 5] if row['id'].startswith('w_') else [1, 2, 4]
        panel = Image.new('RGB', (cw * 3, rows[0].height * 2 + 40), '#0c1013')
        draw = ImageDraw.Draw(panel)
        draw.text((12, 8), row['id'] + ' | battle camera 170 | original pixels', font=font, fill='#e7eacb')
        for ri, strip in enumerate(rows):
            for ci, idx in enumerate(indices):
                panel.paste(strip.crop((idx * cw, 0, (idx + 1) * cw, strip.height)), (ci * cw, 40 + ri * strip.height))
        overview.append(panel)
        panel.save(a.out / (row['id'] + '_battle.jpg'), quality=92)
if overview:
    image = Image.new('RGB', (max(im.width for im in overview), sum(im.height for im in overview)), '#0c1013')
    y = 0
    for panel in overview:
        image.paste(panel, (0, y)); y += panel.height
    image.save(a.out / 'rebake_battle.jpg', quality=92)
print(json.dumps({k: {q: v for q, v in d.items() if q != 'frames'} for k, d in measurements.items()}, indent=2))
