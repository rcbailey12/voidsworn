# Round 3 sheet extras (issue 532; R217, R218, R219). Plain python with Pillow and numpy (no Blender).
#   python sheet_extras.py <code> <render dir> <repo> <out dir> [<round 2 fit json>]
# Reads <render dir>/<code>_model.json, <code>_fit.json and the renders build.py wrote, and writes into <out dir>:
#   fit_view.jpg      top and side views with every gun's firing arc (data.js slot), each turret's sweep circle, every engine
#                     and thruster exhaust cone, launcher exits and the other apertures drawn on the blockout
#   fit_report.md     every clash the check found on the round 2 layout, how round 3 fixed it, and the round 3 result
#   side_by_side.jpg  the accepted concept left, the blockout right, at the camera fitted to the concept, the full view and
#                     the bow, midships and stern crops at the same windows (the Board's part-by-part look, R198, R213)
#   cells.jpg         the nine blob-sweep cells: the concept sheet's top and side views over the blockout's, cut into bow,
#                     midships and stern thirds, the underside below, and each cell's inventory ticks (R218)
import sys, os, json, math, glob, textwrap
import numpy as np
from PIL import Image, ImageDraw, ImageFont

CODE, RD, REPO, OUT = sys.argv[1:5]
R2 = sys.argv[5] if len(sys.argv) > 5 else None
os.makedirs(OUT, exist_ok=True)
M = json.load(open(os.path.join(RD, CODE + '_model.json')))
FIT = json.load(open(os.path.join(RD, CODE + '_fit.json')))
ARCS = {'F': (-60.0, 60.0), 'P': (30.0, 150.0), 'S': (-150.0, -30.0), 'T': (-180.0, 180.0)}
INK = (232, 228, 218); DIM = (160, 158, 150); GREY = (58, 58, 60)
GREEN = (90, 220, 120); CYAN = (90, 200, 235); ORANGE = (255, 150, 50); YELLOW = (250, 220, 60); RED = (235, 70, 55)


def font(n):
    for f in ('DejaVuSans.ttf', 'consola.ttf', 'arial.ttf'):
        for d in ('/usr/share/fonts/truetype/dejavu/', 'C:/Windows/Fonts/', ''):
            try:
                return ImageFont.truetype(d + f, n)
            except OSError:
                pass
    return ImageFont.load_default()


F_S, F_M, F_L = font(22), font(30), font(44)


def flat(name, bg=GREY):
    im = Image.open(os.path.join(RD, name + '.png')).convert('RGBA')
    b = Image.new('RGBA', im.size, bg + (255,)); b.alpha_composite(im)
    return b.convert('RGB'), np.asarray(im)[..., 3] > 8


def proj(view, p):
    v = M['views'][view]; k = v['px_per_unit']; W, H = v['res']
    d = np.array(p, float) - np.array(v['centre'])
    return (W / 2 + k * float(np.dot(d, v['right'])), H / 2 - k * float(np.dot(d, v['up'])))


def overlay(base, draw_fn):
    """translucent shapes: draw on a layer, blend"""
    lay = Image.new('RGBA', base.size, (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    draw_fn(d)
    out = base.convert('RGBA'); out.alpha_composite(lay)
    return out.convert('RGB')


# ---------------------------------------------------------------- fit view
def fit_view():
    top, _ = flat('top'); side, _ = flat('side')
    k = M['views']['top']['px_per_unit']

    def wedge_pts(view, c, a0, a1, r, up=(0, 0, 1), elev=None):
        pts = [proj(view, c)]
        a = a0
        while a <= a1 + 1e-6:
            ar = math.radians(a)
            if elev is None:
                q = (c[0] + r * math.cos(ar), c[1] + r * math.sin(ar), c[2])
            else:  # a fan in the vertical plane through the bearing elev[0] (side view)
                br = math.radians(elev[0])
                q = (c[0] + r * math.cos(ar) * math.cos(br), c[1] + r * math.cos(ar) * math.sin(br), c[2] + r * math.sin(ar) * (1 if up[2] >= 0 else -1))
            pts.append(proj(view, q)); a += 3
        return pts

    def draw_top(d):
        for a in FIT['arcs']:
            lo, hi = ARCS.get(a['slot'] or 'T', (-180, 180))
            r = max(2.2, a['reach'] * 1.15)
            blocked = [b for b, e in a['bearings'] if e is None]
            col = (RED + (90,)) if blocked else (GREEN + (55,))
            d.polygon(wedge_pts('top', a['pivot'], lo, hi, r), fill=col, outline=GREEN + (200,))
            if a['mount'] != 'casemate':
                c = proj('top', a['pivot']); rr = a['reach'] * k
                d.ellipse((c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr), outline=CYAN + (230,), width=2)
        for c in FIT['cones']:
            ap = c['apex']; dd = c['dir']; L = c['length']; t = math.tan(math.radians(c['half']))
            u = (-dd[1], dd[0], 0.0); n = math.hypot(u[0], u[1])
            if n < 1e-6:  # vertical thruster: a circle
                p = proj('top', ap); rr = (c['r0'] + L * t) * k
                d.ellipse((p[0] - rr, p[1] - rr, p[0] + rr, p[1] + rr), outline=ORANGE + (220,), width=2); continue
            u = (u[0] / n, u[1] / n, 0.0)
            p0 = [ap[i] + u[i] * c['r0'] for i in range(3)]; p1 = [ap[i] - u[i] * c['r0'] for i in range(3)]
            e = [ap[i] + dd[i] * L for i in range(3)]
            q0 = [e[i] + u[i] * (c['r0'] + L * t) for i in range(3)]; q1 = [e[i] - u[i] * (c['r0'] + L * t) for i in range(3)]
            d.polygon([proj('top', p0), proj('top', q0), proj('top', q1), proj('top', p1)], fill=ORANGE + (70,), outline=ORANGE + (230,))
        for a in FIT['apertures']:
            L = min(a['length'], 0.3 * M['length']) if a['kind'] in ('launcher', 'tube') else min(a['length'], 1.2)
            e = [a['pos'][i] + a['dir'][i] * L for i in range(3)]
            d.line([proj('top', a['pos']), proj('top', e)], fill=YELLOW + (230,), width=3 if a['kind'] in ('launcher', 'tube') else 2)

    def draw_side(d):
        for a in FIT['arcs']:
            band = [e for b, e in a['bearings'] if e is not None]
            lo, hi = ARCS.get(a['slot'] or 'T', (-180, 180))
            for b in (lo, hi) if a['slot'] != 'T' else (0, 180):
                emin, emax = (-10, 20) if a['mount'] == 'casemate' else (0, 60 if a['slot'] == 'T' else 30)
                d.polygon(wedge_pts('side', a['pivot'], emin, emax, max(1.8, a['reach']), up=a['up'], elev=(b,)), fill=GREEN + (45,), outline=GREEN + (160,))
        for c in FIT['cones']:
            ap = c['apex']; dd = c['dir']; L = c['length']; t = math.tan(math.radians(c['half']))
            if abs(dd[2]) > 0.9 or abs(dd[1]) > 0.9:
                continue
            e = [ap[i] + dd[i] * L for i in range(3)]
            d.polygon([proj('side', (ap[0], ap[1], ap[2] + c['r0'])), proj('side', (e[0], e[1], e[2] + c['r0'] + L * t)),
                       proj('side', (e[0], e[1], e[2] - c['r0'] - L * t)), proj('side', (ap[0], ap[1], ap[2] - c['r0']))],
                      fill=ORANGE + (70,), outline=ORANGE + (230,))
        for a in FIT['apertures']:
            if a['kind'] not in ('launcher', 'tube'):
                continue
            L = min(a['length'], 0.3 * M['length'])
            e = [a['pos'][i] + a['dir'][i] * L for i in range(3)]
            d.line([proj('side', a['pos']), proj('side', e)], fill=YELLOW + (230,), width=3)

    t2 = overlay(top, draw_top); s2 = overlay(side, draw_side)
    dt = ImageDraw.Draw(t2)
    for a in FIT['arcs']:
        x, y = proj('top', a['pivot']); dt.text((x + 6, y - 10), a['id'], font=F_S, fill=INK)
    for c in FIT['cones']:
        x, y = proj('top', c['apex']); dt.text((x - 30, y + 4), c['id'], font=F_S, fill=ORANGE)
    ds = ImageDraw.Draw(s2)
    for c in FIT['cones']:
        if abs(c['dir'][2]) < 0.9 and abs(c['dir'][1]) < 0.9:
            x, y = proj('side', c['apex']); ds.text((x - 40, y - 12), c['id'], font=F_S, fill=ORANGE)
    W = t2.width + s2.width + 60; H = max(t2.height, s2.height) + 280
    sh = Image.new('RGB', (W, H), (40, 40, 42)); d = ImageDraw.Draw(sh)
    cnt = FIT['counts']
    d.text((20, 15), '%s FIT VIEW, round 3. Left: clashes %d, mounts %d, arcs %d, sweeps %d, exhaust %d, exits %d' % (
        CODE, cnt['CLASH'], cnt['MOUNT'], cnt['ARC'], cnt.get('SWEEP', 0), cnt['EXHAUST'], cnt['EXIT']), font=F_L, fill=INK)
    d.text((20, 75), 'green: each gun\'s data.js firing arc (red if a bearing is blocked); cyan circle: a turret\'s sweep (R219, every bearing turned and tested)', font=F_S, fill=DIM)
    d.text((20, 100), 'orange: exhaust cones (12 deg engines, 20 deg thrusters); yellow: launcher cell and tube exits, other apertures', font=F_S, fill=DIM)
    d.text((20, 125), 'tested: %s' % ', '.join('%s %s' % (v, k_.replace('_', ' ')) for k_, v in FIT['tested'].items()), font=F_S, fill=DIM)
    sh.paste(t2, (20, 170)); sh.paste(s2, (t2.width + 40, 170))
    d.text((20, 170 + t2.height + 10), 'TOP (bow up, port left)', font=F_M, fill=INK)
    d.text((t2.width + 40, 170 + s2.height + 10), 'SIDE (port beam, bow left): elevation fans at each arc limit, cones, exits', font=F_M, fill=INK)
    sh.save(os.path.join(OUT, 'fit_view.jpg'), quality=88)


# ---------------------------------------------------------------- fit report
def fit_report():
    L = ['# %s fit report (round 3; RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)\n' % CODE,
         'Made by `tools/blender/build_sheets/clash.py` on the built blockout (it runs inside every `build.py ... render` and on its own',
         'with `build.py <code> <out> fit`). What it tests, on every part of every type:\n',
         '1. **CLASH**: no part intersects another part; no non-mount piece (barrel, bell, blade, lid, slat, lens) sits inside the hull.',
         '   Mount pieces (rings, collars, plates, saddles, sunk tubes) may sit into the hull, never into another part.',
         '2. **MOUNT**: every part touches the hull through a mount piece.',
         '3. **ARC**: every gun, at every bearing of its data.js slot arc (core.js inArc: F 60 degrees either side of the bow, P and S',
         '   30 to 150 off the bow, T all round, 5 degree steps), has a clear line at an elevation it can reach (turrets 0 to 30, flak',
         '   0 to 60, casemates -10 to +20), out to 60 percent of the ship\'s length.',
         '4. **SWEEP** (R219): every turret\'s turning pieces turned through every bearing of its arc touch nothing; no two turrets meet',
         '   when both turn through their arcs.',
         '5. **EXHAUST**: nothing in any engine or thruster exhaust cone.',
         '6. **EXIT**: no launcher cell, tube mouth, dish beam, hatch, lamp, vent or slit is covered.\n',
         'Turret marking for issue 560 (R219): each turret is an empty named `<id>_turret` at the ring centre (local +Z = the mount',
         'normal), with custom properties `turret=1`, `slot`, `weapon`, `arc_lo`, `arc_hi`, `arc_deg` (bearings from the bow, + to port, as',
         'core.js inArc), `rest_yaw`, `rest_pitch`; its turning meshes `<id>_turn_<material>` are its children (mesh in the pivot frame,',
         'also `turret=1`); its fixed ring and bolt ring `<id>_mount_<material>` stay on the hull. Casemates are single fixed parts',
         '(`turret=0`, `gun_fixed=1`).\n']
    if R2 and os.path.exists(R2):
        B = json.load(open(R2))
        L.append('## Round 2 layout, checked (before)\n')
        L.append('The round 2 design (`tools/blender/build_sheets/ships/r2/%s.py`, the PR 547 layout) built with the round 3 kit parts and run'
                 ' through the same check. Counts: %s.\n' % (CODE, ', '.join('%s %d' % kv for kv in B['counts'].items())))
        L.append('| Check | Part | Against | Hits | What |\n|---|---|---|---:|---|')
        for c in B['clashes']:
            L.append('| %s | %s | %s | %d | %s |' % (c['check'], c['part'], c['other'], c['n'], c['detail'].replace('|', '/')))
    L.append('\n## How round 3 fixed them\n')
    L.append('| Clash (round 2) | Fix (round 3) |\n|---|---|')
    for a, b in FIT['fixes']:
        L.append('| %s | %s |' % (a, b))
    L.append('\nWhile designing round 3 the check also caught (and the design fixed) plates swallowing slits and lamps, casemate breeches pushed')
    L.append('into the hull, a pipe through a pod, chains through casemates, dishes too low on their posts, and, once turrets turned (R219),')
    L.append('neighbouring deck-edge turrets meeting when trained aft (the middle ones now superfire on barbettes) and antennas inside a')
    L.append('turret\'s swept circle (moved out).\n')
    L.append('## Round 3 (after)\n')
    L.append('Counts: %s. Tested: %s.\n' % (', '.join('%s %d' % kv for kv in FIT['counts'].items()),
                                            ', '.join('%s %s' % (v, k_.replace('_', ' ')) for k_, v in FIT['tested'].items())))
    if FIT['clashes']:
        L.append('| Check | Part | Against | What |\n|---|---|---|---|')
        for c in FIT['clashes']:
            L.append('| %s | %s | %s | %s |' % (c['check'], c['part'], c['other'], c['detail']))
    else:
        L.append('**Zero clashes left.** No clash is left in as intended.\n')
    L.append('| Turret | Slot | Arc (bearings) | Sweep steps clear |\n|---|---|---|---:|')
    for s in FIT.get('sweeps', []):
        L.append('| %s | %s | %d to %d | %d |' % (s['id'], s['slot'] or 'T', s['arc'][0], s['arc'][1], s['clear_steps']))
    L.append('\nPicture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).')
    open(os.path.join(OUT, 'fit_report.md'), 'w').write('\n'.join(L) + '\n')


# ---------------------------------------------------------------- side by side
CROPS = {'corsair_A16': [('bow', (60, 380, 900, 1160)), ('midships', (560, 220, 1400, 900)), ('stern', (1150, 20, 1920, 700))],
         'corsair_A17': [('bow', (60, 380, 900, 1120)), ('midships', (600, 120, 1400, 800)), ('stern', (1100, 120, 1700, 800))]}


def side_by_side():
    con = Image.open(os.path.join(REPO, M['beauty'])).convert('RGB')
    b = Image.open(os.path.join(RD, 'beauty_cam.png')).convert('RGBA')
    bg = Image.new('RGBA', b.size, (14, 14, 16, 255)); bg.alpha_composite(b); bld = bg.convert('RGB').resize(con.size)
    W = 1920; half = W // 2
    rows = [('full view', con.resize((half, half * con.height // con.width)), bld.resize((half, half * con.height // con.width)))]
    for nm, box in CROPS.get(CODE, []):
        a = con.crop(box); c = bld.crop(box)
        h = half * a.height // a.width
        rows.append((nm, a.resize((half, h)), c.resize((half, h))))
    H = 90 + sum(r[1].height + 50 for r in rows)
    out = Image.new('RGB', (W + 30, H), (30, 30, 32)); d = ImageDraw.Draw(out)
    d.text((10, 10), '%s: CONCEPT (left) and BUILD SHEET BLOCKOUT round 3 (right), same camera, same windows' % CODE, font=F_M, fill=INK)
    d.text((10, 50), 'camera: fitted to the concept outline (ships/%s_camera.json, refit in round 3); blockout: flat colour, no paint or texture yet (recipe stages 4 and 5)' % CODE,
           font=F_S, fill=DIM)
    y = 90
    for nm, a, c in rows:
        d.text((10, y + 8), nm, font=F_M, fill=YELLOW)
        out.paste(a, (10, y + 45)); out.paste(c, (20 + half, y + 45))
        y += a.height + 50
    out.save(os.path.join(OUT, 'side_by_side.jpg'), quality=88)


# ---------------------------------------------------------------- nine cells
def ship_box(im, bg):
    from scipy import ndimage
    a = np.asarray(im.convert('RGB')).astype(int)
    d = np.abs(a - np.array(bg)).sum(2) > 40
    d = ndimage.binary_opening(d, np.ones((5, 5)))
    lab, n = ndimage.label(d)
    sizes = ndimage.sum(d, lab, range(1, n + 1)); objs = ndimage.find_objects(lab)
    return objs, sizes


def cells():
    sheet = Image.open(os.path.join(REPO, M['beauty'].replace('_beauty.jpg', '_sheet.jpg'))).convert('RGB')
    a = np.asarray(sheet).astype(int); bgc = np.median(a[5:40, 5:40].reshape(-1, 3), axis=0)
    objs, sizes = ship_box(sheet, bgc)
    big = sorted([(sizes[i], objs[i]) for i in range(len(objs))], key=lambda t: -t[0])[:2]
    big = sorted(big, key=lambda t: t[1][0].start)   # upper first: the top view, then the side view
    cview = {}
    for nm, (_, o) in zip(('top', 'side'), big):
        cview[nm] = sheet.crop((o[1].start, o[0].start, o[1].stop, o[0].stop))

    def build_view(name, rot):
        im = Image.open(os.path.join(RD, name + '.png')).convert('RGBA')
        if rot:
            im = im.rotate(90, expand=True)
        al = np.asarray(im)[..., 3] > 8
        ys, xs = np.where(al)
        im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        b = Image.new('RGBA', im.size, GREY + (255,)); b.alpha_composite(im)
        return b.convert('RGB')
    bview = {'top': build_view('top', True), 'side': build_view('side', False), 'below': build_view('underside', True)}
    rows_json = json.load(open(os.path.join(OUT, 'cells.json')))['rows'] if os.path.exists(os.path.join(OUT, 'cells.json')) else []
    Wst = 1500
    blocks = []
    for v in ('top', 'side', 'below'):
        c = cview.get(v); b = bview[v]
        cs = c.resize((Wst, Wst * c.height // c.width)) if c else None
        bs = b.resize((Wst, Wst * b.height // b.width))
        blocks.append((v, cs, bs))
    TW = 1100
    H = 80 + sum((x[1].height if x[1] else 60) + x[2].height + 120 for x in blocks)
    out = Image.new('RGB', (Wst + TW + 60, H), (36, 36, 38)); d = ImageDraw.Draw(out)
    d.text((20, 15), '%s: the nine blob-sweep cells, concept over blockout, and each cell\'s inventory (R218)' % CODE, font=F_M, fill=INK)
    d.text((20, 52), 'concept: the round 8 sheet\'s top and side views (their boxes include engine plumes and loose guns); it has no underside view', font=F_S, fill=DIM)
    y = 90
    for v, cs, bs in blocks:
        y0 = y
        d.text((20, y), v.upper(), font=F_M, fill=YELLOW); y += 40
        if cs:
            out.paste(cs, (20, y)); d.text((26, y + 4), 'concept', font=F_S, fill=INK); y += cs.height + 8
        else:
            d.text((20, y), '(no concept view: designed from the side view\'s lower edge and data.js)', font=F_S, fill=DIM); y += 40
        out.paste(bs, (20, y)); d.text((26, y + 4), 'blockout', font=F_S, fill=INK); y += bs.height
        for k_ in (1, 2):
            x = 20 + Wst * k_ // 3
            d.line((x, y0 + 40, x, y), fill=YELLOW, width=3)
        for k_, nm in enumerate(('BOW', 'MIDSHIPS', 'STERN')):
            d.text((20 + Wst * k_ // 3 + 10, y + 6), nm, font=F_S, fill=YELLOW)
        # the table for this view's three cells
        ty = y0 + 40; tx = Wst + 50
        for reg in ('bow', 'mid', 'stern'):
            cell = '%s/%s' % (reg, v)
            rs = [r for r in rows_json if r['cell'] == cell]
            d.text((tx, ty), '%s: %d lines, %d present, shaped and detailed' % (cell, len(rs), sum(1 for r in rs if r['present'] and r['shaped'] and r['detailed'])),
                   font=F_S, fill=INK); ty += 28
            line = ', '.join('%s %s' % (r['id'], 'Y' if (r['present'] and r['shaped'] and r['detailed']) else 'n') for r in rs) or 'nothing listed'
            for ln in textwrap.wrap(line, 70):
                d.text((tx + 16, ty), ln, font=F_S, fill=DIM); ty += 26
            ty += 8
        y = max(y + 60, ty + 20)
    out = out.crop((0, 0, out.width, y + 20))
    out.save(os.path.join(OUT, 'cells.jpg'), quality=86)


fit_view()
fit_report()
side_by_side()
cells()
print('extras written', OUT)
