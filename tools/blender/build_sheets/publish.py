# Copy one ship's laid-out sheet into the repo (issue 532): python publish.py <code> <render dir> <layout dir> <outline overlay jpg> <repo>
import sys, shutil
from PIL import Image, ImageDraw
s, R, O, ov, REPO = sys.argv[1:6]
D = '%s/docs/ship_pipeline/build_sheets/%s' % (REPO, s)
import os; os.makedirs(D, exist_ok=True)
for n in ['side', 'top', 'underside', 'bow', 'stern', 'cutaway', 'threequarter']:
    Image.open('%s/%s.png' % (O, n)).convert('RGB').save('%s/%s.jpg' % (D, n), quality=88)
Image.open('%s/sheet.jpg' % O).save('%s/sheet.jpg' % D, quality=85)
for n in ('preview.jpg', 'feature_table.md', 'checks.json'):
    shutil.copy('%s/%s' % (O, n), '%s/%s' % (D, n))
im = Image.open(ov); im.resize((im.width * 720 // im.height, 720)).save('%s/outline_check.jpg' % D, quality=85)
beauty = [l for l in open('%s/tools/blender/build_sheets/ships/%s.py' % (REPO, s)) if l.startswith('BEAUTY')][0].split("'")[1]
a = Image.open('%s/%s' % (REPO, beauty)).convert('RGB').resize((540, 360))
b = Image.open('%s/beauty_cam.png' % R).convert('RGBA'); bg = Image.new('RGBA', b.size, (58, 58, 60, 255)); bg.alpha_composite(b)
b = bg.convert('RGB').resize((540, 360))
c = Image.new('RGB', (540, 720)); c.paste(a, (0, 0)); c.paste(b, (0, 360))
d = ImageDraw.Draw(c); d.text((8, 8), s + ' accepted beauty', fill=(255, 255, 255)); d.text((8, 368), s + ' blockout at the fitted beauty camera', fill=(255, 255, 255))
c.save('%s/beauty_vs_blockout.jpg' % D, quality=85)
print('published', D)
