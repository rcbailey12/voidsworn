"""Bake issue 876's review pictures from before and after build.py render folders.

Usage: python r289_review.py BEFORE AFTER REPO OUT
Pillow only. The accepted beauty and saved camera are unchanged.
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

before, after, repo, out = map(Path, sys.argv[1:5])
out.mkdir(parents=True, exist_ok=True)
bg = (36, 36, 38)
ink = (238, 232, 220)
dim = (195, 192, 185)
accent = (238, 177, 100)


def font(size):
    for p in ('C:/Windows/Fonts/arial.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'):
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            pass
    return ImageFont.load_default()


def flat(path):
    im = Image.open(path).convert('RGBA')
    base = Image.new('RGBA', im.size, bg + (255,))
    base.alpha_composite(im)
    return base.convert('RGB')


def place(canvas, im, box):
    x, y, w, h = box
    im = im.copy()
    im.thumbnail((w, h), Image.Resampling.LANCZOS)
    canvas.paste(im, (x + (w - im.width) // 2, y + (h - im.height) // 2))


concept = flat(repo / 'contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg')
old = flat(before / 'beauty_cam.png')
new = flat(after / 'beauty_cam.png')
sheet = Image.new('RGB', (1280, 720), bg)
d = ImageDraw.Draw(sheet)
d.text((16, 12), 'corsair_A17 | raised rocket spine | issue 876 / R289', font=font(28), fill=ink)
for x, label, im in ((16, 'Accepted concept', concept), (440, 'Before issue 876', old), (864, 'After issue 876', new)):
    d.text((x, 54), label, font=font(22), fill=accent)
    place(sheet, im, (x, 86, 400, 267))
    d.text((x, 366), 'Support detail, same crop', font=font(20), fill=dim)
    place(sheet, im.crop((500, 150, 1200, 620)), (x, 398, 400, 269))
d.text((16, 680), 'Stage: unpainted sheet | same beauty camera | raised outer support; fitted insides and weapons unchanged',
       font=font(20), fill=ink)
sheet.save(out / 'r289_before_after.jpg', quality=91)

sheet = Image.new('RGB', (1280, 720), bg)
d = ImageDraw.Draw(sheet)
d.text((16, 12), 'corsair_A17 | spine continuity | issue 876 / R289', font=font(28), fill=ink)
d.text((16, 55), 'Accepted concept', font=font(22), fill=accent)
d.text((452, 55), 'After: standard three-quarter', font=font(22), fill=accent)
place(sheet, concept, (16, 86, 410, 275))
place(sheet, flat(after / 'threequarter.png'), (452, 86, 812, 300))
for x, label, folder in ((16, 'Before: true side', before), (654, 'After: true side', after)):
    d.text((x, 400), label, font=font(22), fill=accent)
    place(sheet, flat(folder / 'side.png'), (x, 436, 610, 240))
d.text((16, 684), 'Stage: unpainted sheet | side views share one scale | the fore block joins the ramp and mid block',
       font=font(20), fill=ink)
sheet.save(out / 'r289_side_threequarter.jpg', quality=91)
print('WROTE', out / 'r289_before_after.jpg', out / 'r289_side_threequarter.jpg')
