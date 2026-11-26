# Six-faction interior lineup (R420, Ryan Nov 22; contrib/opus/plans/global_cohesion_standard.md 6.1.5; issue 1743): one strip
# with every faction's cut-open ship side by side at one exposure, so Ryan judges the interiors together, never one ship's lift
# alone. Each blend goes through cutaway.py (the same world, lights, view transform and samples for all, so the exposure
# matches) for its centreline section and its midships close cutaway; the strip puts each pair in a cell, three across, its code
# name and faction on it, 1280 wide and no taller than 720 (RULEBOOK 1.2), stamped with revision and stage.
# usage (bpy python):  python cutaway_lineup.py OUT_DIR "<title>" BLEND [BLEND ...] [stage=cloud direction check] [samples=24]
import os, sys, subprocess
from pathlib import Path
sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p for p in HERE.parents if (p / 'tools/picture_provenance.py').is_file()) / 'tools'))
from picture_provenance import Review
from PIL import Image, ImageDraw, ImageFont

args = [a for a in sys.argv[1:] if '=' not in a]; opts = dict(a.split('=', 1) for a in sys.argv[1:] if '=' in a)
OUT, TITLE, BLENDS = args[0], args[1], args[2:]
STAGE = opts.get('stage', 'cloud direction check'); SAMPLES = opts.get('samples', '24')
os.makedirs(OUT, exist_ok=True)
cells = []
for b in BLENDS:
    code = os.path.splitext(os.path.basename(b))[0]; d = os.path.join(OUT, code)
    r = subprocess.run([sys.executable, str(HERE / 'cutaway.py'), b, d, code, 'stage=' + STAGE, 'samples=' + SAMPLES,
                        'views=section,close', 'sheet=0'], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit('[lineup] cutaway.py failed on %s:\n%s' % (b, r.stdout[-2000:] + r.stderr[-2000:]))
    cells.append((code, os.path.join(d, code + '_cut_section.png'), os.path.join(d, code + '_cut_close.png')))

R = Review(STAGE)
W, H, top, cols = 1280, 720, 34, 3
rows = (len(cells) + cols - 1) // cols
cw = W // cols; ch = (H - top) // rows
f = g = None
for p in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf'):
    if os.path.exists(p):
        f = ImageFont.truetype(p, 17); g = ImageFont.truetype(p, 13); break
sheet = Image.new('RGB', (W, H), (14, 15, 18)); dr = ImageDraw.Draw(sheet)
dr.text((12, 8), TITLE, fill=(230, 230, 232), font=f)
for k, (code, sec, clo) in enumerate(cells):
    x0 = (k % cols) * cw; y0 = top + (k // cols) * ch
    dr.text((x0 + 8, y0 + 2), code, fill=(200, 204, 210), font=g)
    s_im = R.open(sec); c_im = R.open(clo)
    s_im = s_im.resize((cw - 8, max(1, int(s_im.height * (cw - 8) / s_im.width))))
    room = ch - 22 - s_im.height - 4
    c_im = c_im.resize((cw - 8, max(1, int(c_im.height * (cw - 8) / c_im.width))))
    if c_im.height > room:
        c_im = c_im.crop((0, (c_im.height - room) // 2, c_im.width, (c_im.height - room) // 2 + room))
    sheet.paste(s_im, (x0 + 4, y0 + 20)); sheet.paste(c_im, (x0 + 4, y0 + 22 + s_im.height))
R.save(sheet, os.path.join(OUT, 'interior_lineup.jpg'), quality=92)
print('[lineup] wrote', os.path.join(OUT, 'interior_lineup.jpg'))
