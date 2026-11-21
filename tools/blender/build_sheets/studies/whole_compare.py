# The whole-concept compare for a build sheet (R229, Ryan Nov 12 2026: build and judge from the whole concept and every sheet view
# first): one named picture, 1280 by 720. Top row: the whole accepted beauty beside the blockout at the camera fitted to it. Bottom
# rows: the concept sheet's plan and side view (the boxes the ship file names in CONCEPT_VIEWS) beside the blockout's true top and
# side views, each pair at the same width so their proportions compare. Plain python with Pillow (no Blender).
#   python whole_compare.py <code> <render dir> <repo> <out jpg>
import sys, os, json
from PIL import Image, ImageDraw, ImageFont
import numpy as np

code, rd, repo, out = sys.argv[1:5]
M = json.load(open(os.path.join(rd, code + '_model.json')))
GREY = (58, 58, 60)


def font(n):
    for p in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf'):
        try:
            return ImageFont.truetype(p, n)
        except OSError:
            pass
    return ImageFont.load_default()


def flat(path, rot=False):
    im = Image.open(path).convert('RGBA')
    if rot:
        im = im.rotate(90, expand=True)
    a = np.asarray(im)[..., 3] > 8; ys, xs = np.where(a)
    im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    b = Image.new('RGBA', im.size, GREY + (255,)); b.alpha_composite(im)
    return b.convert('RGB')


def fit(im, w, h):
    im = im.copy(); im.thumbnail((w, h), Image.Resampling.LANCZOS); return im


W, H = 1280, 720
o = Image.new('RGB', (W, H), (36, 36, 38)); d = ImageDraw.Draw(o)
d.text((14, 8), '%s | whole concept beside the blockout (R229)' % code, fill=(240, 230, 210), font=font(24))
beauty = Image.open(os.path.join(repo, M['beauty'])).convert('RGB')
cam = flat(os.path.join(rd, 'beauty_cam.png')) if os.path.exists(os.path.join(rd, 'beauty_cam.png')) else None
y0 = 44; bh = 330
for x, im, lab in ((14, beauty, 'accepted beauty (whole)'), (654, cam, 'blockout at the camera fitted to it')):
    if im is None:
        continue
    t = fit(im, 612, bh - 26); o.paste(t, (x + (612 - t.width) // 2, y0 + 24))
    d.text((x, y0), lab, fill=(205, 200, 190), font=font(17))
sheet = Image.open(os.path.join(repo, M['concept_sheet'])).convert('RGB') if M.get('concept_sheet') else None
cv = M.get('concept_views') or {}
rows = [('top', flat(os.path.join(rd, 'top.png'), rot=True), 'plan, bow left'), ('side', flat(os.path.join(rd, 'side.png')), 'side, bow left')]
y = y0 + bh + 8; rh = (H - y - 8) // 2
for nm, bimg, lab in rows:
    c = None
    if sheet is not None and nm in cv:
        c = sheet.crop(tuple(cv[nm]['box']))
        if cv[nm].get('rot'):   # issues 1153 and 1155: a view drawn bow up or down, turned to bow left
            c = c.rotate(int(cv[nm]['rot']), expand=True)
        if cv[nm].get('flip'):
            c = c.transpose(Image.FLIP_LEFT_RIGHT)
    for x, im, l2 in ((14, c, 'concept sheet ' + lab), (654, bimg, 'blockout ' + lab + ', one scale')):
        if im is None:
            d.text((x, y + rh // 2), '(the concept sheet has no such view)', fill=(160, 158, 150), font=font(16)); continue
        t = fit(im, 612, rh - 22); o.paste(t, (x + (612 - t.width) // 2, y + 20))
        d.text((x, y), l2, fill=(205, 200, 190), font=font(16))
    y += rh
o.save(out, quality=90)
print('WROTE', out)
