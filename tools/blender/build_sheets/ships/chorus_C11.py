# chorus_C11: the bladeback, the Chorus cruiser (class Cruiser, 14.5 world units). Issue 623, the Chorus build sheets.
# Accepted picture: contrib/muse/design/concept_round8b_2026_11/chorus_C11_beauty.jpg and _sheet.jpg (R204).
# data.js b_razor (Chorus bladeback): tendril T, bioplasma F; ability frenzy; regen 6; no shields.
# Designer of record: Opus (R205, R207). The concept guides; it is not traced. Built and judged from the WHOLE pictures first (R229).
# Measured off the round 8b sheet's true views (bow LEFT; side 90.3 px a unit, plan 89.5; the throats' rims to the stern nodes
# 12.85 units, the filaments trail on to the full 14.5): the body 5.2 wide and 4.4 deep, blunt at the bow where two throats
# 2.2 across sit side by side, widest at 40 percent, tapering hard from 70 percent; three domed sacs a side, 1.9 across, on
# the flanks below the shoulder; the bone blade row down the centre of the back from 27 to 90 percent; hull length to beam 2.5,
# length to height 2.9 (C10 is 5.2 and 6.5: two classes).
# +X bow, +Y port, +Z up. Throat rims x = +7.25, vent mouths x = -5.6, filament tips about x = -7.25.
import math

CODE = 'chorus_C11'
NAME = 'The bladeback (Chorus cruiser)'
FACTION = 'The Chorus (chorus)'
CLASS = 'Cruiser'
LENGTH = 14.5
GAME = "data.js b_razor (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5"
BEAUTY = 'contrib/muse/design/concept_round8b_2026_11/chorus_C11_beauty.jpg'
KIT = 'chorus'
CONCEPT_SHEET = 'contrib/muse/design/concept_round8b_2026_11/chorus_C11_sheet.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(100, 40, 1730, 665), largest=True, flip=False), side=dict(box=(110, 730, 1740, 1250), largest=True, flip=False))
CROPS = [('bow (the two throats)', (100, 650, 1000, 1250)), ('midships (blades and sacs)', (480, 250, 1380, 1050)), ('stern (mane and vents)', (1050, 0, 1920, 750))]
SHEET = dict(version=4, round='the recipe (issue 623)', date='2026-11-13', blend='opus623\\chorus_C11',
             before='First full layout', before_note='The first complete C11 layout with the Chorus kit, run through the check before any fix.')

PEXP = (2.0, 1.9)    # round over the top and round in the belly: no flat faces (the Board on PR 628)
FACE_D = 1.5         # the face: a dome of flesh 1.6 forward of the hull's front section, the throats flush in it
THROATS = ((1.22, -0.28), (-1.22, -0.28))   # throat centres (y, z) in the face
R_THROAT = 0.82
WOBBLE = (0.09, 2.1)  # the body's unevenness
# a bulbous seed: widest and tallest in the front third, rounding over and narrowing aft; the head is the body's own swell
KEY = [
    (5.7, 2.6, 2.6, -2.18, 2.0),
    (4.6, 2.92, 2.92, -2.42, 2.38),
    (3.4, 2.97, 2.97, -2.46, 2.44),
    (2.0, 2.86, 2.86, -2.36, 2.33),
    (0.4, 2.55, 2.55, -2.1, 2.08),
    (-1.4, 2.04, 2.04, -1.72, 1.74),
    (-3.2, 1.44, 1.44, -1.25, 1.32),
    (-4.5, 0.95, 0.95, -0.85, 0.95),
    (-5.25, 0.7, 0.7, -0.62, 0.72),
]


def dense(key, step=0.3):
    out = []
    for i in range(len(key) - 1):
        a, b = key[i], key[i + 1]
        p0 = key[max(0, i - 1)]; p3 = key[min(len(key) - 1, i + 2)]
        n = max(1, int(round((a[0] - b[0]) / step)))
        for k in range(n):
            t = k / n
            row = []
            for c in range(5):
                P0, P1, P2, P3 = p0[c], a[c], b[c], p3[c]
                row.append(0.5 * ((2 * P1) + (-P0 + P2) * t + (2 * P0 - 5 * P1 + 4 * P2 - P3) * t * t + (-P0 + 3 * P1 - 3 * P2 + P3) * t ** 3))
            out.append(tuple(row) + (0, 0))
    out.append(tuple(key[-1]) + (0, 0))
    return out


HULL = dense(KEY)
PL = dict(size=(0.4, 0.85), thick=(0.02, 0.045), skip=0.15, stack=0.0, mats={'flesh': 5, 'hide': 3, 'flesh2': 2, 'scar': 0.3},
          rivet_mat='pore', subs=['pad', 'pore'], rivets=True, rr=0.03)
SACS = (2.54, -0.14, -2.66)
VENTS = 6


def build(K):
    import kit as _k
    from mathutils import Vector, Matrix
    import bpy as _bpy
    import random
    HP = _k.HP

    hull = K.hull(HULL, 'flesh', shell=0.25, plates=dict(PL, seed=21, inv='hide'), rounded=True, pexp=PEXP, n=40, smooth=True, wobble=WOBBLE)
    K.mass('Hull: the short broad body', hull, 'dark olive flesh', note='blunt at the bow, widest at 40 percent, tapering hard aft')
    K.mark('body', 'hull', ['ridge', 'fold', 'pore'])

    def side_th(th, side):
        return th if side > 0 else math.pi - th

    # ---------------- the face and the two throats (bioplasma F) ----------------
    # the face: a dome of flesh over the hull's front section, with two holes where the throats open flush in it (round 3, the
    # Board: "fleshy rimmed holes flush in the face: thick lips, a dark wet throat, the glow deep inside")
    s0 = _k.sec_at(HULL, HULL[0][0]); xf = s0[0] - 0.04
    hw0, zb0, zt0 = s0[1] * 0.995, s0[3] * 0.995, s0[4] * 0.995
    zc0 = (zb0 + zt0) / 2; hz0 = (zt0 - zb0) / 2

    def dome(y, z):
        e = min(1.0, ((abs(y) / hw0) ** 2 + (abs(z - zc0) / hz0) ** 2) ** 0.5)
        return xf + FACE_D * max(0.0, 1 - e * e) ** 0.55
    hx = [dome(y, z) for (y, z) in THROATS]

    def face_x(y, z):
        x = dome(y, z)
        for (ty, tz), hx_ in zip(THROATS, hx):
            d = math.hypot(y - ty, z - tz); w = min(1.0, max(0.0, (d - R_THROAT) / (R_THROAT * 0.7)))
            w = w * w * (3 - 2 * w)
            x = hx_ * (1 - w) + x * w
        return x
    NR, NT = 44, 112
    V, F, idx = [], [], {}
    for i in range(NR + 1):
        rho = i / NR
        for j in range(NT):
            t = 2 * math.pi * j / NT; c, sn = math.cos(t), math.sin(t)
            y = rho * hw0 * math.copysign(abs(c) ** (2 / PEXP[0 if sn >= 0 else 1]), c)
            z = zc0 + rho * hz0 * math.copysign(abs(sn) ** (2 / PEXP[0 if sn >= 0 else 1]), sn)
            idx[(i, j)] = len(V); V.append((face_x(y, z), y, z))
    for i in range(NR):
        for j in range(NT):
            q = [idx[(i, j)], idx[(i, (j + 1) % NT)], idx[(i + 1, (j + 1) % NT)], idx[(i + 1, j)]]
            cy = sum(V[k][1] for k in q) / 4; cz_ = sum(V[k][2] for k in q) / 4
            if any(math.hypot(cy - ty, cz_ - tz) < R_THROAT * 1.02 for ty, tz in THROATS):
                continue
            F.append(tuple(q))
    face = K.hull_detail('face', (V, F), 'flesh')
    K.mass('Head: the face', face, 'flesh', note='the dome of the face, the throats flush in it')
    for i, (ty, tz) in enumerate(THROATS):
        side = 1 if ty > 0 else -1
        L_ = 1.6
        K.spinal('M%d' % (i + 1), (hx[i] - (L_ - 0.12 * R_THROAT), ty, tz), L_, r=R_THROAT, slot='F', weapon='bioplasma', inv='throats', style='flush', lip_r=R_THROAT * 1.15,
                 teeth=11, seed=7 + i, side=side, gland_at=0.42, note='%s throat: a fleshy rimmed hole flush in the face, a dark wet throat, the bile gland glowing deep inside'
                                                       % ('port' if side > 0 else 'starboard'))
    K.allow_touch('M1', 'M2', 'the two throats\' rims meet at the bow\'s centre (the picture\'s throats side by side)')

    # ---------------- the mane (tendril T, fixed) ----------------
    x0m, Lm = -0.95, 2.7
    z0 = K.deck_z(x0m, 0.0); z1 = K.deck_z(x0m - Lm, 0.0)
    K.gun('T1', (x0m, 0.0, z0 + 0.15), 0, 0, barrels=3, cal=0.07, blen=4.2, size=1.0, slot='T', weapon='tendril', inv='mane', fixed=True,
          kw=dict(count=30, seed=9, mane_len=Lm, mane_drop=z0 - z1),
          note='boarding tendrils: a mane of twenty-six hooked tendrils on a muscle crest behind the blade row, streaming up and aft (fixed: a mane reaches every way at once)')
    K.mass('Mane', _bpy.data.objects['T1_mount_flesh'], 'flesh crest, tendrils', note='the plume rising from the back behind the blades')

    # ---------------- the bile sacs (domes on the flanks) ----------------
    for i, x in enumerate(SACS):
        for side in (1, -1):
            sn = 'p' if side > 0 else 's'
            pos, nrm = K.hpt(x, side_th(-0.42, side), out=-0.02)
            # a dome half sunk into the lower flank, bulging out of the hide (round 3)
            fid = 'S%d%s' % (i + 1, sn)
            K.organ(fid, HP.sac(0.98, h=0.98 * 1.06, seed=60 + 2 * i + (side > 0), kind='sac', glow=1, rim=1.0), pos, nrm, fwd=(1, 0, 0), inv='bile_sacs',
                    what='bile sac, 1.9 across', note='a bile reservoir in a wrinkled socket, fed forward to the throats by the veins')
            K.mass('Bile sac %d (%s)' % (i + 1, 'port' if side > 0 else 'starboard'), _bpy.data.objects['%s_mount_flesh' % fid], 'flesh dome', note='a dome on the flank below the shoulder')

    # ---------------- siphons ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        pos, nrm = K.hpt(4.55, side_th(-0.62, side), out=-0.03)
        K.thruster('Q1' + sn, tuple(pos), tuple(nrm), r=0.24, inv='siphons', note='siphon below the head: swings the bow')
        pos, nrm = K.hpt(-3.95, side_th(0.25, side), out=-0.03)
        K.thruster('Q2' + sn, tuple(pos), tuple(nrm), r=0.22, inv='siphons', note='siphon aft: swings the stern')

    # ---------------- the vent ring (engines) ----------------
    for k in range(VENTS):
        a = 2 * math.pi * (k + 0.5) / VENTS
        y, z = 0.6 * math.cos(a), 0.02 + 0.52 * math.sin(a)
        K.engine('E%d' % (k + 1), (-5.6, y, z), 0.17, 0.8, bell=1.0, body_r=0.23, inv='vents', src='picture',
                 kw=dict(trail='filament', trails=1, trail_len=1.5, out_dir=(0, math.cos(a), math.sin(a)), seed=k),
                 note='pulse vent with three glowing filaments splayed outward')
    K.mass('Vent ring', _bpy.data.objects['E1_mount_flesh'], 'flesh', note='six pulse vents round the stern\'s end')

    rnd = random.Random(611)
    # ---------------- the blade row, the side blades and the wound they grow from ----------------
    wound = [K.hpt(x, math.pi / 2, out=-0.02) for x in [4.7 - 0.3 * k for k in range(20)]]
    K.hull_detail('wound_channel', HP.welt([p_ for p_, n_ in wound], [n_ for p_, n_ in wound], 0.46, 0.04, n=6), 'tissue', inv='wound', kind='wound',
                  subs=['channel', 'lip', 'tissue'])
    for sg in (1, -1):
        lip = [K.hpt(x, math.pi / 2 - sg * 0.12, out=-0.02) for x in [4.8 - 0.3 * k for k in range(20)]]
        K.hull_detail('wound_lip_%d' % (sg > 0), HP.welt([p_ for p_, n_ in lip], [n_ for p_, n_ in lip], 0.18, 0.1, n=6), 'flesh2')
    # the back: knuckled bone crests of uneven size, with gaps, growing out of the wound (never a neat sawtooth row)
    items = []
    x = 4.7
    for k in range(9):
        # big, jagged, broken bone plates along the spine, uneven and leaning; the tallest about a fifth of the body's height
        ln = rnd.uniform(0.9, 1.8); hh = rnd.uniform(0.55, 1.0) * (1.0 - 0.3 * k / 8)
        yaw = rnd.uniform(-35, 35)
        span = abs(ln * math.cos(math.radians(yaw)))
        if x - span < -0.5:
            break   # the plates stop short of the mane
        xc = x - span / 2
        pos, nrm = K.hpt(xc, math.pi / 2 + rnd.uniform(-0.1, 0.1), out=-0.06)
        fw = Vector((math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), 0))
        lean = rnd.choice((1, -1)) * math.radians(rnd.uniform(8, 25))
        up = (Vector(nrm) * math.cos(lean) + fw.cross(Vector(nrm)).normalized() * math.sin(lean)).normalized()
        items.append((HP.bone_crest(ln, hh, w=rnd.uniform(0.28, 0.42), knuckles=3 + k % 3, seed=k, jagged=0.28), HP.frame(pos, fw, up)))
        x -= span * rnd.uniform(0.55, 0.95)   # plates overlap or leave gaps, never evenly spaced
    K.grown_hull('blade_row', items, inv='blade_row', kind='spine')
    K.mass('Bone crest', _bpy.data.objects['blade_row_bone'], 'pale bone', note='knuckled bone crests down the back')
    for side in (1, -1):
        items = []
        for k, x in enumerate([3.6 - 1.15 * j + rnd.uniform(-0.25, 0.25) for j in range(5)]):
            th = side_th(0.95 - 0.03 * k + rnd.uniform(-0.1, 0.1), side)
            pos, nrm = K.hpt(x, th, out=-0.05)
            # smaller knuckled shards lying along the shoulder (the plan's separate pale plates), no two alike
            items.append((HP.bone_crest(rnd.uniform(0.6, 1.2), rnd.uniform(0.3, 0.55), w=rnd.uniform(0.25, 0.36), knuckles=2 + k % 2, seed=20 + k, jagged=0.25),
                          HP.frame(pos, (1, side * rnd.uniform(0.5, 1.2), 0), nrm)))
        K.grown_hull('side_blades_%s' % ('p' if side > 0 else 's'), items, inv='side_blades', kind='spine')
        K.mass('Shoulder crests (%s)' % ('port' if side > 0 else 'starboard'), _bpy.data.objects['side_blades_%s_bone' % ('p' if side > 0 else 's')], 'pale bone', note='shards along the shoulder')
    # pore fields: the head and the upper flanks (dense, as the picture)
    for name, x0, x1, t0, t1, nper in (('head', 3.2, 6.4, 0.2, 1.45, 260), ('flank', -1.8, 4.2, 0.18, 0.62, 160)):
        V, F = [], []
        for side in (1, -1):
            for _ in range(nper):
                x = rnd.uniform(x0, x1); th = rnd.uniform(t0, t1)
                pos, nrm = K.hpt(x, side_th(th, side), out=0.0)
                vv, ff = HP.pore(pos, nrm, rnd.uniform(0.02, 0.045), n=6)
                o = len(V); V += vv; F += [tuple(q + o for q in f) for f in ff]
        K.hull_detail('pores_' + name, (V, F), 'pore', inv='pore_fields', kind='pore', subs=['rim', 'pit'])
    # veins: from the sacs forward to the throats
    for side in (1, -1):
        V, F = [], []

        def run(pts_xt, w):
            pts = []; nrms = []
            for x, th in pts_xt:
                p_, n_ = K.hpt(x, side_th(th, side), out=0.0); pts.append(p_); nrms.append(n_)
            vv, ff = HP.welt(pts, nrms, w, w * 0.5, n=5)
            o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
        run([(3.45 + 0.3 * k, -0.28 + 0.02 * math.sin(k)) for k in range(9)], 0.09)
        run([(-2.4 + 0.35 * k, 0.17 + 0.03 * math.sin(k)) for k in range(17)] + [(3.6 + 0.3 * k, 0.17 - 0.1 * k) for k in range(1, 5)], 0.07)
        K.hull_detail('veins_%s' % ('p' if side > 0 else 's'), (V, F), 'vein', inv='veins', kind='vein', subs=['vein', 'branch'])
    # flank folds: skin wrinkles in broken runs, swept back from the throats above and below the sacs (never a long rope)
    V, F = [], []
    for side in (1, -1):
        for k in range(26):
            th0 = rnd.choice((rnd.uniform(0.18, 0.8), rnd.uniform(-1.35, -0.82)))
            xa = rnd.uniform(-3.6, 6.0); ln = rnd.uniform(1.2, 2.8)
            pts = []; nrms = []; ws = []; hs = []
            for j in range(10):
                t = j / 9
                x = xa - ln * t
                if x < -4.5 or any(abs(x - sx) < 0.65 and abs(th0 - st) < 0.4 for sx, st in ((4.55, -0.62), (-3.95, 0.25))):
                    break   # stop short of the siphons
                th = th0 + 0.02 * math.sin(j * 1.1 + k) + (0.05 * t if th0 > 0 else -0.04 * t)
                p_, n_ = K.hpt(x, side_th(th, side), out=-0.02); pts.append(p_); nrms.append(n_)
                env = math.sin(math.pi * (0.08 + 0.84 * t))
                ws.append(0.34 * env + 0.04); hs.append(0.075 * env + 0.01)
            if len(pts) < 4:
                continue
            vv, ff = HP.welt(pts, nrms, ws, hs, n=5)
            o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
    K.hull_detail('flank_folds', (V, F), 'flesh2', inv='flank_folds', kind='welt', subs=['welt'])
    for k, (x, th, r, side) in enumerate(((5.0, 1.05, 0.35, -1), (1.2, 0.95, 0.4, 1), (-1.0, 0.55, 0.32, -1), (-3.0, 1.2, 0.36, 1), (3.0, -1.0, 0.33, 1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.0)
        (pv, pf), (kv, kf) = HP.scar(pos, nrm, r, seed=10 + k, knits=3)
        K.hull_detail('scar%d_patch' % k, (pv, pf), 'scar', inv='scars', kind='scar', subs=['patch', 'knit'])
        K.hull_detail('scar%d_knit' % k, (kv, kf), 'tissue')

    # ---------------- colour zones ----------------
    K.colour('dark olive flesh, callused olive hide (paint stage)', 7.25, -5.6, 'whole body')
    K.colour('pale ochre bone', 4.6, -2.3, 'the blade rows')
    K.colour('raw transition tissue', 4.8, -1.2, 'the wound along the spine')
    K.colour('bile yellow-green light', 7.25, 6.4, 'the throat glands')
    K.colour('bile yellow-green light', -5.6, -7.25, 'the vents and the filament nodes')
    K.colour('dim bile', 6.0, -2.5, 'the veins, the sac windows, the acid pores')

    # ---------- INSIDE: flesh, bone and organs ----------
    K.septum('lower', -1.0, 5.5, -3.0)
    K.septum('upper', 0.75, 5.5, -3.6)
    for i, x in enumerate((5.45, 4.7, 3.9, 2.3, 1.2, 0.1, -1.6, -2.6, -3.6, -4.6)):
        K.hoop('F%d' % i, x)
    K.organ_room('bile_gland_p', 'gland', (5.0, 1.0, -0.15), (0.65, 0.5, 0.5), note='the port throat\'s bile gland: the shot\'s magazine', seed=1)
    K.organ_room('bile_gland_s', 'gland', (5.0, -1.0, -0.15), (0.65, 0.5, 0.5), note='the starboard throat\'s bile gland', seed=2)
    K.organ_room('ganglion', 'ganglion', (4.1, 0.0, 1.0), (0.55, 0.45, 0.35), note='the Node: the knot of nerve that steers the body', seed=3)
    K.organ_room('ram_muscle', 'organ', (1.8, 0.0, 1.35), (2.3, 0.5, 0.32), note='the muscle under the blade row (it drives the blades into a hull)', seed=4)
    for i, x in enumerate(SACS):
        for side in (1, -1):
            K.organ_room('bile_store_%d%s' % (i + 1, 'p' if side > 0 else 's'), 'gland', (x, side * (1.25 - 0.2 * i), -0.4), (0.55 - 0.05 * i, 0.42, 0.38),
                         note='the bile store behind the sac', seed=10 + i)
    K.organ_room('heart_vat', 'vat', (0.6, 0.0, -0.05), (0.95, 0.75, 0.65), note='the heart vat: the core (hp_core), lit bile-green', seed=20)
    K.organ_room('gut_fore', 'gut', (2.8, 0.0, -1.0), (1.5, 0.85, 0.55), note='the gut', seed=21)
    K.organ_room('gut_aft', 'gut', (-1.6, 0.0, -0.75), (1.2, 0.8, 0.5), note='the second stomach', seed=22)
    K.organ_room('regrowth_p', 'organ', (-2.7, 0.85, 0.55), (0.5, 0.38, 0.32), note='regrowth tissue (regen 6)', seed=23)
    K.organ_room('regrowth_s', 'organ', (-2.7, -0.85, 0.55), (0.5, 0.38, 0.32), note='regrowth tissue', seed=24)
    K.organ_room('mane_muscle', 'organ', (-2.2, 0.0, 0.9), (0.85, 0.4, 0.26), note='the mane\'s root muscle', seed=25)
    K.organ_room('pulse_bladder', 'engroom', (-4.35, 0.0, 0.0), (0.65, 0.55, 0.45), note='the pulse bladder: fills and squeezes the six vents (the engine room)', seed=26)
    K.armour('head and throats', 0.4, 'the thickest flesh, over the throat roots')
    K.armour('back (the blade row)', 0.35, 'bone under the wound channel')
    K.armour('flanks and sacs', 0.25, 'thin over the sacs: they rupture first')
    K.armour('belly', 0.25, '')
    K.armour('stern', 0.2, '')
    K.break_line('B-1', 3.0, 'behind the head: the throats and the brow tear away, opening the bile glands and the Node',
                 path=[(3.3, 6.0), (3.3, 2.6), (2.7, 1.4), (3.25, 0.3), (2.75, -0.8), (3.2, -1.7), (2.8, -2.6), (2.8, -6.0)])
    K.break_line('B-2', -0.6, 'ahead of the mane: the stern half tears away through the heart vat\'s aft end, the sacs bursting first',
                 path=[(-0.3, 6.0), (-0.3, 2.5), (-0.85, 1.4), (-0.45, 0.2), (-0.9, -0.9), (-0.35, -2.5), (-0.35, -6.0)])
    K.inside.append(dict(kind='note', name='insides', note='Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, '
                                                          'membrane septa for decks, organs and chambers that never reach the skin. The Chorus bursts and tears: sacs rupture first, '
                                                          'then the body tears open along ragged lines (R186).'))
    K.point('core', 'hp_core', (0.6, 0.0, -0.05))
    # four breach anchors (Cruiser base 4; the Chorus extra is for the big ones only): prow, mid, mid, engine, alternating sides
    for i, (x, th, sec, side) in enumerate(((4.0, 0.1, 'prow', 1), (1.3, -0.75, 'mid', -1), (-1.4, -0.75, 'mid', 1), (-3.4, -0.4, 'eng', -1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('breach', 'hp_breach_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd', section=sec, note='open hide beside a sac')
    for i, (x, th, side) in enumerate(((4.55, -0.62, 1), (4.55, -0.62, -1), (-3.95, 0.25, 1), (-3.95, 0.25, -1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('rcs', 'hp_rcs_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')
    # boarding origins (export7: one port, one starboard on the mid hull): where the boarding tendrils' parties leave the body
    for i, side in enumerate((1, -1)):
        pos, nrm = K.hpt(0.8, side_th(0.12, side), out=0.02)
        K.point('board', 'hp_board_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('Colour: bile yellow-green light over dark olive flesh, pale ochre bone and ochre chitin', 'R204 and the lore: the colour is fixed in the build; the picture\'s hide is green-brown with amber light')
    K.change('The two throats are one battery, the Spine volley (bioplasma F): fleshy rimmed holes flush in a domed face', 'data.js b_razor has one bioplasma slot; both throats fire it (two muzzles, one slot). R184\'s single throat stays a later fleet-sheet question; the accepted picture has two')
    K.change('The plume of hair on the back is the boarding tendrils (tendril T), a fixed mane on a muscle crest', 'the slot is all round; a mane reaches every way at once, so it is fixed, not a turret. Its roots stop well forward of the stern so no tendril hangs in a vent\'s jet')
    K.change('The bone ridge is a run of knuckled bone crests of uneven size growing from an open wound channel, with smaller crests along each shoulder', 'the bladeback closes and cuts (Razormaw); the plan draws separate pale plates, the profile a row (README 8b: the profile is the view of record)')
    K.change('The domes are bile sacs feeding the throats; veins run forward to them', 'every part has a job (R221): the picture\'s domes become the throats\' reservoirs')
    K.change('The stern ends in a ring of six pulse vents, each with three glowing filaments splayed outward', 'factions.md: no nozzles; the picture\'s amber nodes and filament plume. The filaments are cut to about a third of the picture\'s so the ship is 14.5 throat rim to filament tip, and splayed so none hangs in a neighbour\'s jet')
    K.change('Siphons added, a pair forward and a pair aft', 'a ship in space must turn; the picture shows none')
    K.change('The small spines along the lower stern are cut', 'no job (R221)')
    K.change('B-1 and B-2 run on straight past the flanks to 6.0 off the axis (issue 623, the recipe)', 'the game weighs the tear\'s height by how far across the path it is, so a path that stops at the flank tears the septa and the liner at different places from the plating near the flanks (death_seam_check: 171 triangles outside their piece); E11\'s paths run on the same way')
    K.change('Boarding origins on the flanks at x 0.8; the throats\' hard points are the bile glands\' faces deep in the throats (issue 623)', 'the game contract needs one boarding origin a side; the mouth\'s centre is open air, which the export check refuses as off the mesh, so the shot leaves from the gland and the arcs and the firing lane are still taken from the mouth')
    K.open_item('The belly is designed here; the sheet has no underside view')
