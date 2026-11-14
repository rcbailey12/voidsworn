# Copy one ship's laid-out sheet into the repo (issue 532): python publish.py <code> <render dir> <layout dir> <outline overlay jpg> <repo>
import sys, shutil
from PIL import Image, ImageDraw, ImageFont
s, R, O, ov, REPO = sys.argv[1:6]
D = '%s/docs/ship_pipeline/build_sheets/%s' % (REPO, s)
import os; os.makedirs(D, exist_ok=True)
for n in ['side', 'top', 'underside', 'bow', 'stern', 'cutaway', 'threequarter']:
    Image.open('%s/%s.png' % (O, n)).convert('RGB').save('%s/%s.jpg' % (D, n), quality=88)
Image.open('%s/sheet.jpg' % O).save('%s/sheet.jpg' % D, quality=85)
for n in ('preview.jpg', 'feature_table.md', 'checks.json', 'manifest.json', 'fit_view.jpg', 'fit_report.md', 'side_by_side.jpg',
          'cells.jpg', 'cells.json', 'inventory.md'):
    shutil.copy('%s/%s' % (O, n), '%s/%s' % (D, n))
im = Image.open(ov); im.resize((im.width * 720 // im.height, 720)).save('%s/outline_check.jpg' % D, quality=85)
beauty = [l for l in open('%s/tools/blender/build_sheets/ships/%s.py' % (REPO, s)) if l.startswith('BEAUTY')][0].split("'")[1]
a = Image.open('%s/%s' % (REPO, beauty)).convert('RGB').resize((540, 360))
b = Image.open('%s/beauty_cam.png' % R).convert('RGBA'); bg = Image.new('RGBA', b.size, (58, 58, 60, 255)); bg.alpha_composite(b)
b = bg.convert('RGB').resize((540, 360))
c = Image.new('RGB', (540, 720)); c.paste(a, (0, 0)); c.paste(b, (0, 360))
d = ImageDraw.Draw(c); d.text((8, 8), s + ' accepted beauty', fill=(255, 255, 255)); d.text((8, 368), s + ' blockout at the fitted beauty camera', fill=(255, 255, 255))
c.save('%s/beauty_vs_blockout.jpg' % D, quality=85)
shutil.copy('%s/%s_fit.json' % (R, s), '%s/fit.json' % D)
shutil.copy('%s/%s_weapon_match.json' % (R, s), '%s/weapon_match.json' % D)
# R241 review picture: one named item, 1280 by 720, with the actual slot/mount table beside the concept comparison.
import json
wm = json.load(open('%s/%s_weapon_match.json' % (R, s)))


def review_font(size):
    for path in ('C:/Windows/Fonts/arial.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            pass
    return ImageFont.load_default()


review = Image.new('RGB', (1280, 720), (44, 44, 46)); rd = ImageDraw.Draw(review)
rd.text((20, 12), s + ' | R241 weapon match ' + wm['result'], fill=(240, 230, 210), font=review_font(30))
for x, label, src in ((20, 'Concept reference', '%s/%s' % (REPO, beauty)), (650, 'Unpainted blockout', '%s/beauty_cam.png' % R)):
    im = Image.open(src).convert('RGBA'); im.thumbnail((610, 398), Image.Resampling.LANCZOS)
    review.paste(im, (x + (610 - im.width) // 2, 82 + (398 - im.height) // 2), im)
    rd.text((x, 53), label, fill=(205, 200, 190), font=review_font(20))
rd.text((20, 497), 'Data slots | shots per volley | visible mounts (muzzles)', fill=(240, 180, 90), font=review_font(21))
for i, row in enumerate(wm['slots']):
    mounts = ', '.join('%s (%d)' % (m['id'], m['muzzles']) for m in row['mounts'])
    line = '%d: %s %s | %d shots | %s' % (row['slot'], row['weapon'], row['arc'], row['shots'], mounts)
    rd.text((20, 533 + 32 * i), line, fill=(230, 225, 215), font=review_font(21))
rd.text((20, 689), 'Each mount fires on every volley; muzzles, arcs and turret hierarchy checked against the built ship.',
        fill=(180, 180, 175), font=review_font(18))
review.save('%s/weapon_review.jpg' % D, quality=90)
# R221: each weapon type alone (the sheet's weapon row), weapon_<data.js id>.jpg
import glob
for w in sorted(glob.glob('%s/weapon_*.png' % R)):
    a_ = Image.open(w).convert('RGBA'); bg_ = Image.new('RGBA', a_.size, (58, 58, 60, 255)); bg_.alpha_composite(a_)
    bg_.convert('RGB').save('%s/%s.jpg' % (D, os.path.basename(w)[:-4]), quality=88)
print('published', D)
