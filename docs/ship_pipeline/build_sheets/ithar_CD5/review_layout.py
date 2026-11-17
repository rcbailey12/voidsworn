"""CD5 review pages and measured fit overlay. Usage: python THIS_FILE TEMP_RENDER_OUT.

All geometry and weapon facts come from the design and its fit/model records.
"""
import importlib.util
import json
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
DEST = Path(__file__).resolve().parent
ROOT = DEST.parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
from PIL import Image, ImageDraw, ImageFont
from picture_provenance import save_picture

src = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location('cd5_design', ROOT / 'tools/blender/build_sheets/ships/ithar_CD5.py')
design = importlib.util.module_from_spec(spec)
spec.loader.exec_module(design)
design.layout(src, DEST)
fit = json.loads((src / 'fit.json').read_text())
model = json.loads((src / 'model.json').read_text())
im = Image.new('RGB', (1280, 720), '#09111c')
d = ImageDraw.Draw(im)
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 18)
small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 15)
title = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 27)
ink, arc_colour, drive_colour = '#dce7ec', '#9bd3c7', '#c6b6e6'
d.text((24, 14), 'ITHAR CD5 / fit: top and side', fill=ink, font=title)
d.text((24, 51), 'R298 | r3 | design ' + model['design_sha256'][:12] + ' | SHEET BUILT | actual sampled arcs and clearance cones', fill='#a9bdc9', font=small)
# Both views use the same scale. Crop empty studio background, not the ship.
for view, y, crop in [('top', 88, (0, 70, 820, 340)), ('side', 355, (0, 80, 820, 290))]:
    raw = Image.open(src / (view + '.png')).resize((820, 410), Image.Resampling.LANCZOS)
    im.paste(raw.crop(crop), (300, y))
for y, text, colour in [(100, 'TOP', ink), (132, 'T: full 360-degree bearing', arc_colour),
                         (156, 'F: forward +/-60 degrees', arc_colour), (195, 'Drive cones: 5 units aft', drive_colour),
                         (219, '10-degree half angle', drive_colour), (252, '5-degree bearing samples', ink),
                         (276, 'Clear elevation in fit.json', ink), (355, 'SIDE / same scale', ink),
                         (390, 'Low round lenses in swells', ink), (414, 'No sweep collisions', ink),
                         (451, 'No allow-touch exemptions', ink)]:
    d.text((24, y), text, fill=colour, font=font if text in ('TOP', 'SIDE / same scale') else small)
scale = 820 / 29

def xy(p, view):
    return (710 + p[0] * scale, (223 - p[1] * scale) if view == 'top' else (480 - p[2] * scale))

for view in ('top', 'side'):
    for cone in fit['cones']:
        x, y = xy(cone['apex'], view)
        end = x - cone['length'] * scale
        r = cone['r0'] * scale
        spread = r + cone['length'] * math.tan(math.radians(cone['half'])) * scale
        d.line([(x, y-r), (end, y-spread), (end, y+spread), (x, y+r)], fill=drive_colour, width=1)
    for arc in fit['arcs']:
        x, y = xy(arc['pivot'], view)
        if view == 'top':
            radius = 26 if arc['slot'] == 'T' else 45
            lo, hi = (-180, 180) if arc['slot'] == 'T' else (-60, 60)
            d.arc((x-radius, y-radius, x+radius, y+radius), lo, hi, fill=arc_colour, width=2)
            d.line((x, y, x+radius, y), fill=arc_colour, width=1)
        else:
            d.line((x, y, x+65, y-12), fill=arc_colour, width=1)
            d.ellipse((x-3, y-3, x+3, y+3), fill=arc_colour)
        d.text((x-11, y+8), arc['id'], fill=ink, font=small)
counts = ' | '.join(k + ' ' + str(v) for k, v in fit['counts'].items())
d.text((24, 575), counts, fill=ink, font=font)
d.text((24, 603), 'Full turn: 73 clear bearing steps per secondary optic. Rays may elevate above another optic; they do not pass through it.', fill=ink, font=small)
save_picture(im, DEST / 'fit_view.jpg', 'sheet built', quality=94)
# The deep r3 hull needs a little more margin than the r1 five-view layout.
# Keep every view at one scale and leave the full beam clear of the view labels.
im = Image.new('RGB', (1280, 720), '#09111c'); d = ImageDraw.Draw(im)
d.text((24, 14), 'ITHAR CD5 / true views / one model, one scale', fill=ink, font=title)
d.text((24, 51), 'R298 | r3 | design ' + model['design_sha256'][:12] + ' | SHEET BUILT | glass colour zones', fill='#a9bdc9', font=small)
for view, label, x, y in [('top', 'TOP', 30, 112), ('side', 'SIDE', 660, 112),
                           ('underside', 'UNDERSIDE', 30, 300), ('bow', 'BOW', 660, 300),
                           ('stern', 'STERN', 660, 488)]:
    raw = Image.open(src / (view + '.png')).resize((500, 250), Image.Resampling.LANCZOS)
    im.paste(raw.crop((0, 40, 500, 210)), (x, y))
    d.text((x, y - 25), label, fill=ink, font=font)
d.line((48, 548, 48 + round(5 * 500 / 29), 548), fill=ink, width=3)
d.text((48, 566), '5 world units / 17.24 px per unit in every view', fill=ink, font=small)
d.text((48, 598), 'Ark 26.0 long / drawn 41.6 on the board', fill=ink, font=font)
save_picture(im, DEST / 'sheet.jpg', 'sheet built', quality=94)
print('CD5 review pages and measured top/side fit diagram saved')
