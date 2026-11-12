# Issue 560: the turret sheets in docs/shots/turrets/ from the look bench's kept run (bench_b2 on the PC, commit 1878cf02).
# python sheets560.py BENCH_DIR OUT_DIR
import sys, os, json
from PIL import Image, ImageDraw, ImageFont
B, OUT = sys.argv[1], sys.argv[2]
CW, CH = 384, 216
rep = json.load(open(os.path.join(B, 'bench.json')))
def font(n):
    for f in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', '/usr/share/fonts/dejavu/DejaVuSans.ttf'):
        if os.path.exists(f): return ImageFont.truetype(f, n)
    return ImageFont.load_default()
F, FH = font(15), font(20)
PH = ['fire order', '', '', '', '', '', 'first shot lands', '', '', 'back at rest']
PH_FIXED = ['fire order', '', 'first shot lands', '']
def cells(row, cam):
    im = Image.open(os.path.join(B, 'moments', f'{row}__c{cam}.png')); im.load()
    st = next(s for s in rep['stills'] if s['id'] == row and s['cam'] == cam)
    return [im.crop((i * CW, 0, (i + 1) * CW, CH)) for i in range(im.size[0] // CW)], [c['t'] for c in st['cells']]
def sheet(name, title, rows, ncol):
    lab = 22
    W = CW * ncol; H = 40 + sum(lab + CH for _ in rows)
    out = Image.new('RGB', (W, H), (14, 14, 18)); d = ImageDraw.Draw(out)
    d.text((10, 9), title, font=FH, fill=(255, 225, 190))
    y = 40
    for caption, pics, labels in rows:
        d.text((10, y + 3), caption, font=F, fill=(220, 220, 220))
        y += lab
        for i, (p, l) in enumerate(zip(pics, labels)):
            out.paste(p, (i * CW, y)); d.rectangle((i * CW, y, i * CW + CW - 1, y + CH - 1), outline=(40, 40, 50))
            d.text((i * CW + 6, y + CH - 22), l, font=F, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
        y += CH
    assert H <= 720, H
    out.save(os.path.join(OUT, name), quality=90); print(name, out.size)
def lab(ts, names, i): return f'{ts[i]:.2f} s  {names[i]}'.rstrip()
for row, what in (('t_turrets_port_aft', 'target to port, behind the beam'), ('t_turrets_stbd_bow', 'target to starboard, ahead of the beam')):
    c, ts = cells(row, 26)
    L = [lab(ts, PH, i) for i in range(len(c))]
    sheet(f'{row}_c26.jpg', f'560 turrets: C15s_23 {row}, closest camera (26), true pixels; turA centre, turS left under the stern gantry',
          [(f'flak (slot 3), {what}: the turrets turn, fire, hold 0.9 s, swing back (seconds from the fire order)', c[:5], L[:5]), ('', c[5:], L[5:])], 5)
pick = [0, 3, 6, 8, 9]
rows60, rows170, zoom = [], [], []
for row, what in (('t_turrets_port_aft', 'target to port, aft'), ('t_turrets_stbd_bow', 'target to starboard, forward')):
    c, ts = cells(row, 60)
    rows60.append((f'{row}: {what}', [c[i] for i in pick], [lab(ts, PH, i) for i in pick]))
    c, ts = cells(row, 170)
    rows170.append((f'{row}: {what}, true pixels', [c[i] for i in pick], [lab(ts, PH, i) for i in pick]))
sheet('turrets_c60.jpg', '560 turrets: C15s_23 at camera 60, true pixels (the aft deck centred)', rows60, 5)
c, ts = cells('t_turrets_port_aft', 170)
z = [c[i].crop((CW // 2 - 64, CH // 2 - 36, CW // 2 + 64, CH // 2 + 36)).resize((CW, CH), Image.NEAREST) for i in pick]
sheet('turrets_c170.jpg', '560 turrets: C15s_23 at the battle camera (170)',
      [rows170[0], ('the same cells, the aft deck magnified 3 times (nearest pixel, nothing added)', z, [lab(ts, PH, i) for i in pick])], 5)
r = []
for cam in (26, 60):
    c, ts = cells('t_casemates_fixed', cam)
    r.append((f'camera {cam}: the port casemates (forward, out of this aft crop) fire scatter (slot 0); the deck turrets are not asked and stay at rest', c, [lab(ts, PH_FIXED, i) for i in range(len(c))]))
sheet('casemates_fixed.jpg', '560 turrets: C15s_23 t_casemates_fixed, true pixels', r, 4)
