# Issue 726, R274 helper (sandbox only, not a standing check): one 1280 by 720 picture of a painted Hullbreaker ship beside its
# concept, the code name on it: up to four panels in a 2 by 2 grid (the concept, the stack before R274, after, a close), each
# labelled, and a few lines of notes under the title.
# usage: python r274_pictures.py OUT.jpg "TITLE" "NOTE LINE|NOTE LINE" LABEL=PICTURE [LABEL=PICTURE ...]    (Pillow)
import os, sys
from PIL import Image, ImageDraw, ImageFont
GREY = (24, 24, 26); INK = (240, 232, 218); DIM = (190, 186, 178); ACC = (240, 170, 80)


def F(n):
    return ImageFont.truetype(next((f_ for f_ in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf') if os.path.exists(f_)), None), n)


out, title, notes = sys.argv[1:4]
panels = [a.split('=', 1) for a in sys.argv[4:]]
im = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(im)
d.text((14, 8), title, fill=INK, font=F(21))
y = 38
for line in [n for n in notes.split('|') if n]:
    d.text((14, y), line, fill=DIM, font=F(14)); y += 20
top = y + 8
W, H = 626, (720 - top - 12) // 2 - 22
for i, (lab, path) in enumerate(panels[:4]):
    x0 = 10 + (i % 2) * (W + 8); y0 = top + (i // 2) * (H + 24)
    d.text((x0, y0), lab, fill=ACC, font=F(15))
    p = Image.open(path).convert('RGBA'); bg = Image.new('RGBA', p.size, (14, 14, 16, 255)); bg.alpha_composite(p); p = bg.convert('RGB')
    p.thumbnail((W, H), Image.Resampling.LANCZOS)
    im.paste(p, (x0 + (W - p.width) // 2, y0 + 20))
im.save(out, quality=90)
print('wrote', out)
