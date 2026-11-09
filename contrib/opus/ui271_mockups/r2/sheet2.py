# Contact sheet and 20-ship sheet for #271 round 2. Run from the repo root: python3 sheet2.py <folder with r2_*.png>
import sys
from PIL import Image, ImageDraw, ImageFont
OUT = sys.argv[1] if len(sys.argv) > 1 else '.'
F = 'godot/ui/'
ox = lambda s: ImageFont.truetype(F + 'campaign/fonts/Oxanium-Variable.ttf', s)
brr = lambda s: ImageFont.truetype(F + 'battle/fonts/BarlowSemiCondensed-Regular.ttf', s)
GILT, BONE, BONE2 = (208, 166, 75), (230, 220, 196), (179, 170, 149)
PICK = ('C', 'b')
rows = [('A', 'Solid Slab', 'threat as contour lines  |  no unacted set (option a)  |  one solid column'),
        ('B', 'Glass Cards', 'threat as a lavender tint  |  unacted set in roster order  |  separate glass panes'),
        ('C', 'Glass Shell', 'threat as hatching  |  unacted set, ships in reach first  |  glass shell, solid text wells')]
W, TW, TH, G = 1960, 960, 540, 14
H = 170 + len(rows) * (TH + 200) + 10
sh = Image.new('RGB', (W, H), (10, 14, 24)); d = ImageDraw.Draw(sh)
d.text((G + 6, 20), 'BATTLE SCREEN, ROUND 2: MOCKUP 2B REVISED (ISSUE 271)', font=ox(46), fill=BONE)
d.text((G + 6, 84), 'Three versions of 2B with all of Muse\'s numbered changes, each restrained (left) and bold (right).', font=brr(32), fill=BONE2)
d.text((G + 6, 122), 'They differ in three open choices: threat shading, the unacted ships, glass or solid. Opus picks C bold.', font=brr(32), fill=BONE2)
y = 176
for v, name, desc in rows:
    d.text((G + 6, y), f'{v}  {name.upper()}', font=ox(44), fill=GILT)
    d.text((G + 6, y + 54), desc, font=brr(32), fill=BONE)
    y += 102
    for j, m in enumerate('rb'):
        x = G + j * (TW + G + 12); pick = (v, m) == PICK
        lab = ('RESTRAINED' if m == 'r' else 'BOLD') + ('   OPUS PICK' if pick else '')
        tw = d.textlength(lab, font=ox(30))
        if pick: d.rectangle((x, y, x + tw + 20, y + 42), fill=GILT)
        d.text((x + (10 if pick else 2), y + 4), lab, font=ox(30), fill=(28, 20, 5) if pick else BONE)
    y += 50
    for j, m in enumerate('rb'):
        x = G + j * (TW + G + 12); pick = (v, m) == PICK
        im = Image.open(f'{OUT}/r2_{v}{m}.png').convert('RGB').resize((TW, TH), Image.LANCZOS)
        sh.paste(im, (x, y))
        d.rectangle((x - 1, y - 1, x + TW, y + TH), outline=GILT if pick else (60, 72, 96), width=5 if pick else 1)
    y += TH + 48
sh.save(f'{OUT}/contact_sheet.jpg', quality=90)
# 20-ship stress of the pick: full screen plus a close crop of the roster and the top bar
im = Image.open(f'{OUT}/r2_stress_{PICK[0]}{PICK[1]}.png').convert('RGB')
S = Image.new('RGB', (W, 170 + TH + 30), (10, 14, 24)); d = ImageDraw.Draw(S)
d.text((G + 6, 20), 'THE PICK (C BOLD) WITH 20 SHIPS', font=ox(44), fill=BONE)
d.text((G + 6, 84), 'All 20 roster rows fit at 1080 with no scrolling; the turn pips shrink so the top bar stays one line.', font=brr(32), fill=BONE2)
S.paste(im.resize((TW, TH), Image.LANCZOS), (G, 150))
x0 = G + TW + G + 12  # the roster at full size, in two halves
S.paste(im.crop((0, 80, 262, 80 + TH)), (x0, 150)); S.paste(im.crop((0, 80 + TH - 60, 262, 80 + 2 * TH - 60)), (x0 + 280, 150))
d.text((x0 + 580, 160), 'Roster at full size,', font=brr(28), fill=BONE2); d.text((x0 + 580, 196), 'top and bottom half', font=brr(28), fill=BONE2)
S.save(f'{OUT}/stress_20_ships.jpg', quality=90)
print(sh.size, S.size)
