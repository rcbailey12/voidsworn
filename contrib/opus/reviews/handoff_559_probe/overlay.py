import json, sys
from PIL import Image, ImageDraw, ImageFont
D = json.load(open('/mnt/user-data/uploads/voidsworn_test/opus559/out_g/probe559.json'))
G = '/mnt/user-data/uploads/voidsworn_test/opus559/out_g/'
try:
    F = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 20)
    FS = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 16)
except Exception:
    F = FS = ImageFont.load_default()
def ring(d, p, r, c, w=3): d.ellipse([p[0]-r, p[1]-r, p[0]+r, p[1]+r], outline=c, width=w)
def x(d, p, r, c, w=3): d.line([p[0]-r, p[1]-r, p[0]+r, p[1]+r], fill=c, width=w); d.line([p[0]-r, p[1]+r, p[0]+r, p[1]-r], fill=c, width=w)
def plus(d, p, r, c, w=3): d.line([p[0]-r, p[1], p[0]+r, p[1]], fill=c, width=w); d.line([p[0], p[1]-r, p[0], p[1]+r], fill=c, width=w)
RED, YEL, ORA, CYA, WHI, BLU, MAG, GRN, LIM = (255,60,60), (255,230,0), (255,150,30), (0,230,255), (255,255,255), (80,140,255), (255,60,255), (60,255,120), (200,255,0)
def guns(code, shot, out, title):
    s = D[code]['shots'][shot]; im = Image.open(G + f'{code}_{shot}.jpg').convert('RGB'); d = ImageDraw.Draw(im)
    for k, p in s['hp'].items():
        if k.startswith('hp_w'): ring(d, p, 9, RED)
        elif k.startswith('hp_eng'): ring(d, p, 12, ORA)
        elif k == 'hp_core': ring(d, p, 12, GRN)
    for side, p in s['mounts']: x(d, p, 9, YEL)
    x(d, s['bow'], 11, YEL)
    for p in s['nozzles']: d.ellipse([p[0]-4, p[1]-4, p[0]+4, p[1]+4], fill=CYA)
    x(d, s['core_game'], 12, LIM)
    for k, arr in s['puffs'].items():
        for p in arr: plus(d, p, 12, WHI)
    im.save(out, quality=92); return im
def breach(code, shot, out):
    s = D[code]['shots'][shot]; im = Image.open(G + f'{code}_{shot}.jpg').convert('RGB'); d = ImageDraw.Draw(im)
    for k, p in s['hp'].items():
        if k.startswith('hp_breach'): ring(d, p, 12, BLU, 4)
    for k, p in s['anchors'].items():
        if k[0] in 'ab': x(d, p, 11, MAG, 4)
    im.save(out, quality=92); return im
for code in D:
    guns(code, 'clean60', f'/home/claude/t559/comp/{code}_hp60.jpg', '')
    guns(code, 'puffs', f'/home/claude/t559/comp/{code}_puffs_mk.jpg', '')
    breach(code, 'damage60', f'/home/claude/t559/comp/{code}_breach60.jpg')
print('ok')
