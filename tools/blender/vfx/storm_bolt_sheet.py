"""Issue 1360: the storm bolt variants sheet for Ryan, from the packed atlases (bake_storm_bolts.py).

python storm_bolt_sheet.py ATLAS_DIR OUT.png      (any Python 3 with Pillow and numpy)

One row per variant, its code name on the left, then six frames of the strike in order. Each cell is coloured the way the
game's BOLT_FLIP_SHADER colours it (world_living.gd), with the one line style's storm roles (render/line_style.gd
bolt_core, bolt_skirt, bolt_corona), added onto a dark storm-gas backdrop and tone-mapped. A flat preview of the baked
asset, not an in-battle capture. A 100 px band at the bottom keeps the provenance stamp (tools/picture_provenance.py
stamp) off the frames; the sheet stays under 720 px tall.
"""
import json, pathlib, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

CORE = np.array([2.2, 2.1, 2.4]); SKIRT = np.array([0.005, 0.8, 2.0]); CORONA = np.array([0.40, 0.72, 1.10])
SKIRT_K, CORONA_K, FORK_K = 0.30, 0.22, 0.85   # BOLT_FLIP_SHADER's weights
SHOW = [1, 2, 3, 5, 7, 10]
CELL = 190
LABEL = 190
HEAD = 44
FOOT = 100   # room for the provenance stamp strip (98 px)

src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
man = json.loads((src / 'bake_manifest.json').read_text())
keys = list(man['variants'].keys())
grid, cell = man['grid'], man['cell']
W = LABEL + CELL * len(SHOW)
H = HEAD + CELL * len(keys) + FOOT
sheet = Image.new('RGB', (W, H), (12, 14, 20))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype('arial.ttf', 22); small = ImageFont.truetype('arial.ttf', 15)
except OSError:
    font = small = ImageFont.load_default()
d.text((12, 12), 'Issue 1360 storm bolts: baked flipbook variants (flat preview; frame numbers count from 0, 35 ms apart)', fill=(225, 230, 240), font=small)
yy, xx = np.mgrid[0:cell, 0:cell] / cell
back = np.dstack([0.010 + 0.012 * yy, 0.022 + 0.020 * (1 - xx * yy), 0.040 + 0.028 * yy])   # dim teal storm gas
for r, key in enumerate(keys):
    v = man['variants'][key]
    atlas = np.asarray(Image.open(src / v['file']).convert('RGBA'), np.float32) / 255.0
    y0 = HEAD + r * CELL
    d.text((12, y0 + CELL // 2 - 30), v['code'], fill=(240, 244, 250), font=font)
    d.text((12, y0 + CELL // 2 + 2), v['name'], fill=(170, 190, 210), font=small)
    for c, f in enumerate(SHOW):
        gy, gx = divmod(f, grid)
        s = atlas[gy * cell:(gy + 1) * cell, gx * cell:(gx + 1) * cell]
        core = np.maximum(s[..., 0], s[..., 1] * FORK_K)
        corona = np.maximum(s[..., 3] - s[..., 2] * 0.5, 0.0)
        col = back + core[..., None] * CORE + s[..., 2:3] * SKIRT * SKIRT_K + corona[..., None] * CORONA * CORONA_K
        rgb = 1.0 - np.exp(-1.6 * col)
        rgb = np.where(rgb <= 0.0031308, rgb * 12.92, 1.055 * np.power(np.clip(rgb, 0, 1), 1 / 2.4) - 0.055)
        im = Image.fromarray(np.uint8(np.clip(rgb, 0, 1) * 255)).resize((CELL - 4, CELL - 4), Image.Resampling.LANCZOS)
        sheet.paste(im, (LABEL + c * CELL + 2, y0 + 2))
        d.text((LABEL + c * CELL + 8, y0 + 6), 'f%d' % f, fill=(150, 160, 175), font=small)
sheet.save(out)
print('sheet', out, sheet.size)
