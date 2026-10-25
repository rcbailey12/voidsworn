# Contact sheets for the A1 silhouette pick: one overview (rows = today + options, columns = views) and a black silhouette strip.
# usage: python3 sheet.py render_dir out_dir
import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageOps
src, out = sys.argv[1], sys.argv[2]
ROWS = [('v14', 'Today (v14)', 'Boat hull: V keel, long low foredeck, crossbar mast, two funnels'),
        ('optA', 'A. Armoured slab', 'Closest to v14. Flat armoured belly, flat deck, blunt nose plate, antenna array, radiators'),
        ('optB', 'B. Salvage spine', 'Corsair junk. Stolen hammerhead bow, cargo pod and donor engine hung off a spine, radiator wings'),
        ('optC', 'C. Double-sided hulk', 'No up or down. Diamond bow, matching blocks top and bottom, side engine pods, fins up and down')]
COLS = [('side', 'Side'), ('q', 'Three-quarter, above'), ('below', 'Three-quarter, below'), ('front', 'Front'), ('top', 'Top')]
try:
    F = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 30); f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 21)
except Exception:
    F = f = ImageFont.load_default()
W, H, LW, TH = 520, 300, 400, 46
img = Image.new('RGB', (LW + W * len(COLS), TH + H * len(ROWS)), (18, 18, 22)); d = ImageDraw.Draw(img)
for c, (_, lab) in enumerate(COLS): d.text((LW + c * W + 12, 10), lab, fill=(220, 215, 205), font=f)
for r, (key, name, note) in enumerate(ROWS):
    y = TH + r * H; d.text((14, y + 20), name, fill=(240, 235, 225), font=F)
    words, line, yy = note.split(), '', y + 70
    for w in words:
        if d.textlength(line + ' ' + w, font=f) > LW - 28: d.text((14, yy), line.strip(), fill=(185, 180, 170), font=f); line, yy = '', yy + 27
        line += ' ' + w
    d.text((14, yy), line.strip(), fill=(185, 180, 170), font=f)
    for c, (v, _) in enumerate(COLS):
        p = os.path.join(src, f'{key}_{v}.png')
        if os.path.exists(p): img.paste(Image.open(p).convert('RGB').resize((W, H)), (LW + c * W, y))
img.save(os.path.join(out, 'a1_options_overview.webp'), quality=90)
# silhouette test: side and top views as solid black shapes on white, the way they read at battle zoom
SW, SH = 560, 320; LW = 400; sil = Image.new('RGB', (LW + SW * 2, TH + SH * len(ROWS)), (255, 255, 255)); d = ImageDraw.Draw(sil)
for c, lab in enumerate(('Side silhouette', 'Top silhouette')): d.text((LW + c * SW + 12, 10), lab, fill=(30, 30, 30), font=f)
for r, (key, name, _) in enumerate(ROWS):
    y = TH + r * SH; d.text((14, y + 20), name, fill=(20, 20, 20), font=F)
    for c, v in enumerate(('side', 'top')):
        p = os.path.join(src, f'{key}_{v}.png')
        if not os.path.exists(p): continue
        g = Image.open(p).convert('L'); bg = g.getpixel((2, 2))
        m = g.point(lambda px: 0 if abs(px - bg) > 6 else 255)
        sil.paste(m.convert('RGB').resize((SW, SH)), (LW + c * SW, y))
sil.save(os.path.join(out, 'a1_options_silhouettes.webp'), quality=90)
print('ok')
