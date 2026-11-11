"""Issue 505: before-above-after motion strips and measurements from capture.gd runs (crop, resize and labels only).
Usage: python pack.py <raw dir with before\\<kind> and after\\<kind>> <out dir>"""
import json, math, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

RAW, OUT = Path(sys.argv[1]), Path(sys.argv[2])
OUT.mkdir(parents=True, exist_ok=True)
try:
    FONT = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 17)
    SMALL = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 13)
except OSError:
    FONT = SMALL = ImageFont.load_default()
KINDS = ['straight', 'turn', 'final', 'side', 'back']
CLASSES = ['Frigate', 'Cruiser', 'Dreadnought']
FW, FH = 212, 160


def text(d, xy, s, f=SMALL):
    d.text(xy, s, font=f, fill='white', stroke_width=2, stroke_fill='black')


def load(side, kind):
    p = RAW / side / kind / 'motion.json'
    return {r['cls']: r for r in json.loads(p.read_text())} if p.exists() else {}


def measure(row):
    ts = row['telemetry']
    last = max((p['t'] for p in ts if p['moving']), default=ts[-1]['t'])
    ts = [p for p in ts if p['t'] <= last + 0.15]
    vel, yaw = [], []
    for a, b in zip(ts, ts[1:]):
        dt = max(b['t'] - a['t'], 1e-6)
        vel.append((b['t'], math.dist(a['p'], b['p']) / dt))
        dy = (b['rot'][1] - a['rot'][1] + math.pi) % (2 * math.pi) - math.pi
        yaw.append(abs(math.degrees(dy)) / dt)
    pk = max(v for _, v in vel) if vel else 0
    full = next((t for t, v in vel if v >= pk * 0.95), None)
    lastfull = max((t for t, v in vel if v >= pk * 0.95), default=0)
    stop = next((t for t, v in vel if t > lastfull and v <= pk * 0.05), ts[-1]['t'])
    mv = [p for p in ts if p['moving'] and not p.get('after_shot') and p['frame_ms'] > 0]
    return {'move_s': round(last, 3), 'to_95pct_speed_s': None if full is None or pk < 1 else round(full, 3),
            'stop_95_to_5pct_s': None if pk < 1 else round(stop - lastfull, 3), 'peak_speed_units_s': round(pk, 2),
            'peak_turn_deg_s': round(max(yaw, default=0), 1), 'max_roll_deg': round(max(abs(math.degrees(p['rot'][0])) for p in ts), 3),
            'peak_live_jet_sprites': max(p.get('puffs', 0) for p in ts),
            'mean_frame_ms_moving': round(sum(p['frame_ms'] for p in mv) / max(len(mv), 1), 2),
            'end_xyz': [round(x, 3) for x in ts[-1]['p']], 'end_yaw': round(ts[-1]['rot'][1] % (2 * math.pi), 4)}, ts


def frames(side, kind, cls, ts):
    folder = RAW / side / kind / cls
    have = sorted(int(f.stem) for f in folder.glob('*.jpg'))
    have = [n for n in have if n < len(ts)]
    T = ts[-1]['t']
    picks = []
    for i in range(6):
        want = T * i / 5
        n = min(have, key=lambda n: abs(ts[n]['t'] - want))
        picks.append(n)
    return [(folder / ('%05d.jpg' % n), ts[n]) for n in picks]


def label(p, after):
    a = 't %.2f s   drive %.2f' % (p['t'], p['drive'])
    if not after:
        return a, 'jets: turn puffs on spin speed only'
    j = []
    for k, nm in (('retro', 'retro'), ('aft', 'aft')):
        if p[k] > 0.18: j.append('%s %.2f' % (nm, p[k]))
    if abs(p['side']) > 0.18: j.append('side %s%.2f' % ('+' if p['side'] > 0 else '-', abs(p['side'])))
    if abs(p['turn']) > 0.18: j.append('turn %s%.2f' % ('+' if p['turn'] > 0 else '-', abs(p['turn'])))
    return a, 'jets: ' + (', '.join(j) if j else 'none')


meas = []
for kind in KINDS:
    B, A = load('before', kind), load('after', kind)
    for cls in CLASSES:
        rb, ra = B.get(cls), A.get(cls)
        if not rb or not ra or 'telemetry' not in rb or 'telemetry' not in ra:
            meas.append({'class': cls, 'kind': kind, 'unavailable': True}); continue
        mb, tb = measure(rb)
        ma, ta = measure(ra)
        meas.append({'class': cls, 'kind': kind, 'path': ra['path'], 'before': mb, 'after': ma,
                     'same_end': mb['end_xyz'] == ma['end_xyz'] and abs(mb['end_yaw'] - ma['end_yaw']) < 1e-3})
        pts = [p['screen'] for p in tb + ta]
        cx = (min(p[0] for p in pts) + max(p[0] for p in pts)) / 2
        cy = (min(p[1] for p in pts) + max(p[1] for p in pts)) / 2
        w = max(560, max(p[0] for p in pts) - min(p[0] for p in pts) + 300)
        h = max(420, max(p[1] for p in pts) - min(p[1] for p in pts) + 220)
        w = max(w, h * FW / FH); h = w * FH / FW
        box = (int(cx - w / 2), int(cy - h / 2), int(cx + w / 2), int(cy + h / 2))
        sheet = Image.new('RGB', (1280, 470), '#10151c')
        d = ImageDraw.Draw(sheet)
        text(d, (10, 6), '%s, %s move | camera 170 | top: BEFORE (main), bottom: AFTER (issue 505) | same route, same end hex and facing' % (cls, kind), FONT)
        for r, (side, ts, m) in enumerate((('before', tb, mb), ('after', ta, ma))):
            y0 = 34 + r * 218
            text(d, (8, y0), '%s: move %.2f s, peak turn %.0f deg/s, to speed %s s, stop %s s' % (
                'BEFORE' if r == 0 else 'AFTER', m['move_s'], m['peak_turn_deg_s'], m['to_95pct_speed_s'], m['stop_95_to_5pct_s']))
            for i, (f, p) in enumerate(frames(side, kind, cls, ts)):
                im = Image.open(f).crop(box).resize((FW, FH))
                x = i * 213
                sheet.paste(im, (x, y0 + 20))
                l1, l2 = label(p, r == 1)
                text(d, (x + 3, y0 + 20 + FH + 1), l1)
                text(d, (x + 3, y0 + 20 + FH + 16), l2)
        sheet.save(OUT / ('%s_%s.jpg' % (cls.lower(), kind)), quality=90)
(OUT / 'movement_measurements.json').write_text(json.dumps(meas, indent=1))
print('PACK_DONE', len(meas))
