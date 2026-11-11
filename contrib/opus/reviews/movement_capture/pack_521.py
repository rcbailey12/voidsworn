"""Issue 521: before-above-after strips and measurements from capture.gd runs (crop, resize and labels only).
Usage: python pack.py <raw dir with before\\<kind> and after\\<kind>> <out dir>
Every strip carries its code name in its top line and is 1280 x 470 (under the 720 px limit)."""
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
MOVE_KINDS = ['long', 'turn', 'straight']
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
    vel, yaw, skate = [], [], []
    for a, b in zip(ts, ts[1:]):
        dt = max(b['t'] - a['t'], 1e-6)
        v = math.dist(a['p'], b['p']) / dt
        vel.append((b['t'], v))
        dy = (b['rot'][1] - a['rot'][1] + math.pi) % (2 * math.pi) - math.pi
        yaw.append(abs(math.degrees(dy)) / dt)
        dx, dz = b['p'][0] - a['p'][0], b['p'][2] - a['p'][2]
        if math.hypot(dx, dz) > 1e-6:
            course = math.atan2(-dz, dx)
            off = abs((course - b['rot'][1] + math.pi) % (2 * math.pi) - math.pi)
            skate.append((v, math.degrees(off)))
    pk = max(v for _, v in vel) if vel else 0
    full = next((t for t, v in vel if v >= pk * 0.95), None)
    lastfull = max((t for t, v in vel if v >= pk * 0.95), default=0)
    stop = next((t for t, v in vel if t > lastfull and v <= pk * 0.05), ts[-1]['t'])
    fast = [o for v, o in skate if v > 0.5 * pk]
    return {'move_s': round(last, 3), 'to_95pct_speed_s': None if full is None or pk < 1 else round(full, 3),
            'stop_95_to_5pct_s': None if pk < 1 else round(stop - lastfull, 3), 'peak_speed_units_s': round(pk, 2),
            'peak_turn_deg_s': round(max(yaw, default=0), 1),
            'nose_off_course_under_way_deg': round(max(fast, default=0), 1),
            'peak_live_jet_sprites': max(p.get('puffs', 0) for p in ts),
            'end_xyz': [round(x, 3) for x in ts[-1]['p']], 'end_yaw': round(ts[-1]['rot'][1] % (2 * math.pi), 4)}, ts


def picks(folder, ts, times):
    have = sorted(int(f.stem) for f in folder.glob('*.jpg'))
    have = [n for n in have if n < len(ts)]
    return [(folder / ('%05d.jpg' % n), ts[n]) for n in (min(have, key=lambda n: abs(ts[n]['t'] - w)) for w in times)]


def label(p):
    a = 't %.2f s   drive %.2f' % (p['t'], p['drive'])
    j = []
    for k in ('retro', 'aft'):
        if p[k] > 0.18: j.append('%s %.2f' % (k, p[k]))
    if abs(p['side']) > 0.18: j.append('side %.2f' % abs(p['side']))
    if abs(p['turn']) > 0.18: j.append('turn %.2f' % abs(p['turn']))
    return a, 'jets: ' + (', '.join(j) if j else 'none')


meas = []
for kind in MOVE_KINDS:
    B, A = load('before', kind), load('after', kind)
    for cls in CLASSES:
        rb, ra = B.get(cls), A.get(cls)
        if not rb or not ra or 'telemetry' not in rb or 'telemetry' not in ra:
            meas.append({'class': cls, 'kind': kind, 'unavailable': True}); continue
        mb, tb = measure(rb)
        ma, ta = measure(ra)
        meas.append({'class': cls, 'kind': kind, 'path': ra['path'], 'before': mb, 'after': ma,
                     'same_end': mb['end_xyz'] == ma['end_xyz'] and abs(mb['end_yaw'] - ma['end_yaw']) < 1e-3})
        if kind != 'long':
            continue
        name = 'M521_%s_long_diagonal' % cls.lower()
        pts = [p['screen'] for p in tb + ta]
        cx = (min(p[0] for p in pts) + max(p[0] for p in pts)) / 2
        cy = (min(p[1] for p in pts) + max(p[1] for p in pts)) / 2
        w = max(560, max(p[0] for p in pts) - min(p[0] for p in pts) + 260)
        h = max(420, max(p[1] for p in pts) - min(p[1] for p in pts) + 200)
        w = max(w, h * FW / FH); h = w * FH / FW
        box = (int(cx - w / 2), int(cy - h / 2), int(cx + w / 2), int(cy + h / 2))
        sheet = Image.new('RGB', (1280, 470), '#10151c')
        d = ImageDraw.Draw(sheet)
        text(d, (10, 6), '%s | %s, %d-hex diagonal | top BEFORE (main), bottom AFTER (issue 521) | same route, end hex, facing' % (
            name, cls, sum(1 for s in ra['path'] if not s.get('rot'))), FONT)
        for r, (side, ts, m) in enumerate((('before', tb, mb), ('after', ta, ma))):
            y0 = 34 + r * 218
            text(d, (8, y0), '%s: move %.2f s, to speed %s s, nose off course under way up to %.0f deg' % (
                'BEFORE' if r == 0 else 'AFTER', m['move_s'], m['to_95pct_speed_s'], m['nose_off_course_under_way_deg']))
            T = ts[-1]['t']
            for i, (f, p) in enumerate(picks(RAW / side / kind / cls, ts, [T * k / 5 for k in range(6)])):
                sheet.paste(Image.open(f).crop(box).resize((FW, FH)), (i * 213, y0 + 20))
                l1, l2 = label(p)
                text(d, (i * 213 + 3, y0 + 20 + FH + 1), l1)
                text(d, (i * 213 + 3, y0 + 20 + FH + 16), l2)
        sheet.save(OUT / (name + '.jpg'), quality=90)

kills = []
for kind, cls, tier in (('kill_cruiser', 'Cruiser', 'cruiser'), ('kill_capital', 'Dreadnought', 'capital')):
    B, A = load('before', kind).get(cls), load('after', kind).get(cls)
    if not B or not A or 'telemetry' not in B or 'telemetry' not in A:
        kills.append({'kind': kind, 'unavailable': True}); continue
    core = A['core_flash_fx_s']
    row = {'kind': kind}
    for side, R in (('before', B), ('after', A)):
        ts = R['telemetry']
        held = [p['t'] for p in ts if p['cut_in']]
        slow = [p['t'] for p in ts if p['fx_speed'] < 0.6]
        core_t = next((p['t'] for p in ts if p['fx_t'] >= core), None) if core and core > 0 else None
        row[side] = {'cut_in_released_s': round(max(held), 2) if held else None, 'core_flash_s': round(core_t, 2) if core_t else None,
                     'slow_motion_s': [round(min(slow), 2), round(max(slow), 2)] if slow else None}
    kills.append(row)
    name = 'K521_kill_%s' % tier
    sheet = Image.new('RGB', (1280, 470), '#10151c')
    d = ImageDraw.Draw(sheet)
    text(d, (10, 6), '%s | %s kill, Key moments cut-in | top BEFORE (main), bottom AFTER (issue 521: hold and slow)' % (name, cls), FONT)
    ca = row['after']['core_flash_s'] or 1.7
    times = [0.4, ca - 0.25, ca + 0.05, ca + 0.3, 1.75 if ca > 2.0 else ca + 0.6, (row['after']['cut_in_released_s'] or ca + 0.8) + 0.25]
    times = sorted(times)
    for r, (side, R) in enumerate((('before', B), ('after', A))):
        ts = R['telemetry']
        y0 = 34 + r * 218
        info = row[side]
        text(d, (8, y0), '%s: cut-in lets go at %s s, core flash at %s s, slow motion %s' % (
            'BEFORE' if r == 0 else 'AFTER', info['cut_in_released_s'], info['core_flash_s'] or row['after']['core_flash_s'],
            ('%s to %s s' % tuple(info['slow_motion_s'])) if info['slow_motion_s'] else 'none'))
        folder = RAW / side / kind / cls
        have = sorted(int(f.stem) for f in folder.glob('*.jpg'))
        byn = {p['frame']: p for p in ts}
        for i, want in enumerate(times):
            n = min(have, key=lambda n: abs(byn.get(n, {'t': 99})['t'] - want))
            p = byn[n]
            sx, sy = p.get('screen', [960, 540])
            cw, ch = 760, 570   # a box around the dying ship, the same aspect as the cells
            x0 = int(min(max(sx - cw / 2, 0), 1920 - cw)); y1 = int(min(max(sy - ch / 2, 0), 1080 - ch))
            sheet.paste(Image.open(folder / ('%05d.jpg' % n)).crop((x0, y1, x0 + cw, y1 + ch)).resize((FW, FH)), (i * 213, y0 + 20))
            text(d, (i * 213 + 3, y0 + 20 + FH + 1), 't %.2f s  %s' % (p['t'], 'CUT-IN' if p['cut_in'] else 'board view'))
            text(d, (i * 213 + 3, y0 + 20 + FH + 16), 'effects clock x%.2f%s' % (p['fx_speed'], '  SLOW' if p['fx_speed'] < 0.6 else ''))
    sheet.save(OUT / (name + '.jpg'), quality=90)

(OUT / 'measurements.json').write_text(json.dumps({'moves': meas, 'kills': kills}, indent=1))
print('PACK_DONE', len(meas), len(kills))
