# Issue 1373: the Glasswright craft options sheet for Ryan (one picture, code names on it, no taller than 720 px).
#   python options_sheet.py RENDERS BEFORE.png OUT.jpg REV
import sys
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

src, before, out, rev = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
W, H = 1280, 720
sheet = Image.new('RGB', (W, H), (11, 14, 20))
d = ImageDraw.Draw(sheet)


def font(size, bold=False):
    for name in ('DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf',):
        for root in ('/usr/share/fonts/truetype/dejavu/', ''):
            try:
                return ImageFont.truetype(root + name, size)
            except OSError:
                pass
    return ImageFont.load_default()


def crop(im):
    """trim the empty sky around the craft"""
    g = im.convert('L').point(lambda v: 255 if v > 24 else 0)
    box = g.getbbox() or (0, 0) + im.size
    pad = 24
    return im.crop((max(0, box[0] - pad), max(0, box[1] - pad), min(im.width, box[2] + pad), min(im.height, box[3] + pad)))


def fit(im, w, h):
    im = crop(im)
    k = min(w / im.width, h / im.height)
    return im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)


d.text((20, 12), 'Glasswright strike craft: three options from the Glasswright kit', fill=(235, 238, 245), font=font(26, True))
d.text((20, 46), f'Issue 1373 (R362) | rev {rev} | stage: BLOCKOUT + PAINT PREVIEW (cloud Blender, kit materials), not in game yet',
       fill=(160, 170, 185), font=font(15))
cols = [('NOW IN GAME', 'code-built craft (boxes and blades)', None),
        ('GF1  The Needle', 'slim spindle, six ribbons twist to one point, three stern stones', 'GF1'),
        ('GF2  The Twin Lance', 'short core, two pearl lances forward (the Ark in small)', 'GF2'),
        ('GF3  The Bud', 'plump seed closed by broad petals, one big bow lens', 'GF3')]
cw = (W - 20) // 4
for i, (title, note, code) in enumerate(cols):
    x = 10 + i * cw
    d.rectangle((x + 4, 80, x + cw - 4, H - 40), outline=(40, 48, 60))
    d.text((x + 14, 90), title, fill=(255, 214, 150) if code else (200, 200, 210), font=font(18, True))
    for k, line in enumerate(textwrap.wrap(note, 34)):
        d.text((x + 14, 116 + 18 * k), line, fill=(170, 178, 190), font=font(13))
    big = Image.open(before) if code is None else Image.open(src / f'{code}_threequarter.png')
    im = fit(big.convert('RGB'), cw - 28, 250)
    sheet.paste(im, (x + (cw - im.width) // 2, 180))
    if code:
        for j, view in enumerate(('top', 'side')):
            v = fit(Image.open(src / f'{code}_{view}.png').convert('RGB'), cw - 28, 95)
            sheet.paste(v, (x + (cw - v.width) // 2, 450 + j * 105))
    # how it reads at the battle camera: the same picture at about the size a craft takes on screen at c170
    tiny = fit(big.convert('RGB'), 48, 30)
    d.text((x + 14, H - 70), 'battle size:', fill=(140, 150, 165), font=font(12))
    sheet.paste(tiny, (x + 100, H - 78))
d.text((20, H - 30), 'Pick one family look; the bomber is built in the same family after the pick. Colours follow the Glasswright kit, so the warmer look in PR 1283 reaches these too.',
       fill=(150, 160, 175), font=font(13))
sheet.save(out, quality=92)
