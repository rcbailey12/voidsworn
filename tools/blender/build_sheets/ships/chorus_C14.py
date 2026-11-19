# chorus_C14: the brood-sac, the Chorus carrier (class Carrier, 16.5 world units). Issue 1155.
# Accepted picture: contrib/muse/design/class_family_chorus_2026_11/chorus_C14_brood_sac_v11.jpg and chorus_C14_brood_sac_sheet_v5.jpg
# (issue 631, Ryan accepted Nov 13 2026); designs.md governs where a picture differs.
# data.js b_brood (Chorus brood-sac): bioplasma F, spores T; ability launch, hangar 3; regen 6; speed 2; no shields.
# Designer of record: Opus (R205, R207). The concept guides; it is not traced. Built and judged from the WHOLE pictures first (R229).
# Measured off the v5 sheet's true views (side view bow LEFT, plan bow DOWN, front view): the sac is as long as it is wide in plan
# (about 545 by 540 px with the rim openings, the body alone about 470 wide) and two thirds as tall as long in profile (435 by
# 290 px); the front is blunt, a pucker of swollen lobes round one small pore; five launch openings on thick necks stand round
# the rim (one on the back aft, a pair high on the aft shoulders, a pair low on the forward flanks: the front view's five round
# the axis, the plan's five round the disc); a ragged pore patch on the back, off the centre line; a fringe of teardrop sacs
# under the belly; the membranes stream from the stern, nearly as long again as the body in the picture (cut to about 0.4 of it).
# +X bow, +Y port, +Z up. Throat lip x = +6.2, vent mouths x = -5.15, membrane tips about x = -10.3.
import math

CODE = 'chorus_C14'
NAME = 'The brood-sac (Chorus carrier)'
FACTION = 'The Chorus (chorus)'
CLASS = 'Carrier'
LENGTH = 16.5
GAME = "data.js b_brood (cls 'Carrier'); length from godot/render/hull_table.gd CLS_LEN['Carrier'] = 16.5"
BEAUTY = 'contrib/muse/design/class_family_chorus_2026_11/chorus_C14_brood_sac_v11.jpg'
KIT = 'chorus'
CONCEPT_SHEET = 'contrib/muse/design/class_family_chorus_2026_11/chorus_C14_brood_sac_sheet_v5.jpg'
# the sheet's true side view (bow LEFT) and its plan, drawn with the bow DOWN: turned 90 degrees clockwise to bow left (turn -90)
CONCEPT_VIEWS = dict(top=dict(box=(20, 40, 590, 680), largest=True, flip=False, rot=-90), side=dict(box=(605, 120, 1180, 700), largest=True, flip=False))
CROPS = [('bow (the front folds and the spine pore)', (605, 200, 900, 560)), ('midships (the openings and the pore patch)', (760, 120, 1060, 640)),
         ('stern (membranes)', (950, 20, 1600, 560))]
SHEET = dict(version=1, round='first layout (issue 1155)', date='2026-11-19', blend='opus1155\\chorus_C14',
             before='First full layout', before_note='The first complete C14 layout with the Chorus kit, run through the check before any fix.')

PEXP = (2.1, 2.0)    # a domed back, a round belly: a sac, no flat face anywhere
WOBBLE = (0.16, 3.3)  # folded, scarred, uneven flesh
# the sac: blunt at the front, widest just aft of the middle, a rounded back, the stern drawn in to the vents
# (x, half-beam port, half-beam starboard, belly, back)
KEY = [
    (5.75, 1.55, 1.55, -1.25, 1.35),
    (5.2, 3.0, 3.0, -2.35, 2.45),
    (4.3, 3.85, 3.85, -2.95, 3.0),
    (3.0, 4.35, 4.35, -3.25, 3.35),
    (1.3, 4.6, 4.6, -3.35, 3.55),
    (-0.5, 4.55, 4.55, -3.25, 3.55),
    (-2.1, 4.15, 4.15, -2.95, 3.3),
    (-3.4, 3.3, 3.3, -2.35, 2.75),
    (-4.4, 2.15, 2.15, -1.55, 1.95),
    (-4.95, 1.2, 1.2, -0.85, 1.15),
    (-5.15, 0.75, 0.75, -0.5, 0.75),
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
PL = dict(size=(0.5, 1.05), thick=(0.02, 0.05), skip=0.15, stack=0.0, mats={'flesh': 5, 'hide': 3, 'flesh2': 2, 'scar': 0.3},
          rivet_mat='pore', subs=['pad', 'pore'], rivets=True, rr=0.035)
FACE_D = 0.32         # the front: a low dome of flesh over the hull's front section, the throat flush at its centre
R_THROAT = 0.46       # the spine pore: deliberately modest (designs.md: "C14 is all chamber, its front deliberately modest")
# the five launch openings (hangar 3): (id, station x, section angle, lean along x); the front view's five round the axis
MOUTHS = (('L1', -3.5, math.pi / 2, -0.75),         # on the back at the stern, leaning aft
          ('L2', -1.6, 0.34, -0.25), ('L3', -1.6, math.pi - 0.34, -0.25),    # high on the aft shoulders
          ('L4', 2.6, 0.06, 0.3), ('L5', 2.6, math.pi - 0.06, 0.3))          # on the rim at the forward corners (all five read from above)
R_MOUTH = 0.84
PATCH = (-0.15, 1.15, 1.15)    # the spore patch: station x, port offset y, radius
# the teardrop sacs under the belly (spore feed and regrowth flesh): (station, section angle on the port side, radius)
SACS = ((3.1, -1.3, 0.42), (2.0, -1.33, 0.5), (0.85, -1.27, 0.56), (-0.4, -1.32, 0.5), (-1.7, -1.26, 0.55), (-3.0, -1.32, 0.44),
        (0.25, -0.97, 0.4), (-1.1, -0.93, 0.46), (-2.45, -0.96, 0.38))
SIPHONS = ((0.9, -0.62, 0.3), (-3.0, -0.2, 0.27))
VENTS = ((0.0, 0.62, 0.2, 2, (0, 0, 1)), (0.55, 0.05, 0.19, 3, (0, 1, 0.1)), (-0.55, 0.05, 0.19, 3, (0, -1, 0.1)), (0.0, -0.5, 0.17, 2, (0, 0, -1)))


def build(K):
    import kit as _k
    from mathutils import Vector
    import bpy as _bpy
    import random
    HP = _k.HP

    hull = K.hull(HULL, 'flesh', shell=0.3, plates=dict(PL, seed=55, inv='hide'), rounded=True, pexp=PEXP, n=56, smooth=True, wobble=WOBBLE)
    K.mass('Hull: the giant sac', hull, 'dark olive flesh', note='as long as it is wide, two thirds as tall: one central chamber of folded flesh')
    K.mark('body', 'hull', ['ridge', 'fold', 'pore'])

    def side_th(th, side):
        return th if side > 0 else math.pi - th

    # ---------------- the front: a low dome with the spine pore flush at its centre (bioplasma F) ----------------
    s0 = _k.sec_at(HULL, HULL[0][0]); xf = s0[0] - 0.04
    hw0, zb0, zt0 = s0[1] * 0.995, s0[3] * 0.995, s0[4] * 0.995
    zc0 = (zb0 + zt0) / 2; hz0 = (zt0 - zb0) / 2
    THR = (0.0, zc0 - 0.05)

    def dome(y, z):
        e = min(1.0, ((abs(y) / hw0) ** 2 + (abs(z - zc0) / hz0) ** 2) ** 0.5)
        return xf + FACE_D * max(0.0, 1 - e * e) ** 0.55
    hx = dome(*THR)

    def face_x(y, z):
        d = math.hypot(y - THR[0], z - THR[1]); w = min(1.0, max(0.0, (d - R_THROAT) / (R_THROAT * 0.8)))
        w = w * w * (3 - 2 * w)
        return hx * (1 - w) + dome(y, z) * w
    NR, NT = 30, 96
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
            if math.hypot(cy - THR[0], cz_ - THR[1]) < R_THROAT * 1.02:
                continue
            F.append(tuple(q))
    face = K.hull_detail('face', (V, F), 'flesh')
    K.mass('Front: the puckered face', face, 'flesh', note='a low dome of flesh closing the front, the spine pore flush in it')
    L_ = 1.0
    K.spinal('M1', (hx - (L_ - 0.12 * R_THROAT), THR[0], THR[1]), L_, r=R_THROAT, slot='F', weapon='bioplasma', inv='spine_pore', style='flush',
             lip_r=R_THROAT * 1.15, teeth=9, seed=14, side=1, gland_at=0.4,
             note='the spine pore: one small fleshy rimmed hole set in the front folds, a dark wet throat, the bile gland glowing deep inside')
    # the front lobes: swollen pillows of flesh radiating from the pore and running back over the front quarter (the picture's
    # puckered front), uneven in width and reach
    rnd = random.Random(1155)
    V, F = [], []
    for k in range(8):
        th0 = 2 * math.pi * (k + 0.5) / 8 + rnd.uniform(-0.15, 0.15)
        reach = rnd.uniform(1.6, 2.4); fat = rnd.uniform(0.85, 1.2)
        pts = []; nrms = []; ws = []; hs = []
        for j in range(24):
            t = j / 23
            x = 5.72 - reach * t
            th = th0 + 0.1 * math.sin(2.5 * t + k)
            p_, n_ = K.hpt(x, th, out=-0.05); pts.append(p_); nrms.append(n_)
            env = math.sin(math.pi * (0.06 + 0.88 * t)) ** 0.35   # a swollen pillow: fat to both ends, never a spike
            ws.append((1.05 + 0.55 * math.sin(math.pi * t)) * env * fat + 0.05)
            hs.append((0.3 + 0.22 * math.sin(math.pi * t)) * env * fat + 0.02)
        vv, ff = HP.welt(pts, nrms, ws, hs, n=9)
        o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
    lobes = K.hull_detail('front_lobes', (V, F), 'flesh2', inv='front_lobes', kind='welt', subs=['welt'])
    K.mass('Front lobes', lobes, 'swollen flesh folds', note='pillows of flesh radiating from the spine pore')

    # ---------------- the spore patch (spores T): a ragged honeycomb of pores on the back, off the centre line ----------------
    px, py, pr = PATCH
    pos, nrm = K.hpt(px, math.pi / 2 - 0.28, out=-0.03)   # about 1.2 to port of the centre line, aft of the middle
    K.gun('G1', tuple(pos), 0, 0, barrels=3, cal=0.12, blen=0.5, size=1.0, normal=tuple(nrm), slot='T', weapon='spores', inv='spore_patch',
          kw=dict(patch=pr, seed=31), note='the spore cloud: a ragged patch of pores on the back that leans its cloud toward the craft (turns)')
    K.mass('Spore patch', _bpy.data.objects['G1_mount_flesh'], 'hide mound, honeycomb of pores', note='off the centre line, forward of the middle')

    # ---------------- the five launch openings (the hangar, hangar 3) ----------------
    for fid, x, th, lean in MOUTHS:
        pos, nrm = K.hpt(x, th, out=-0.05)
        ax = (Vector(nrm) + Vector((lean, 0, 0))).normalized()
        part = HP.launch_mouth(R_MOUTH, 1.9, neck=1.0, seed=hash(fid) % 97)
        K.organ(fid, part, pos, ax, fwd=(1, 0, 0), inv='launch_mouths', kind='hangar',
                what='launch opening, %.1f across, on a neck of flesh; empty, a dim glow deep inside' % (2 * R_MOUTH),
                note='a spore squadron is born deep in the chamber below and leaves through the mouth', aperture=(2.5, 0.0))
        K.mass('Launch opening %s' % fid, _bpy.data.objects['%s_mount_flesh' % fid], 'flesh neck and lip', note='thick fleshy rim, drawn empty')

    # ---------------- the teardrop sacs under the belly (spore feed storage, regrowth flesh) ----------------
    for i, (x, th, r) in enumerate(SACS):
        for side in (1, -1):
            sn = 'p' if side > 0 else 's'
            pos, nrm = K.hpt(x, side_th(th, side), out=-0.05)
            hang = (Vector(nrm) * 0.35 + Vector((0, 0, -1))).normalized()
            fid = 'S%d%s' % (i + 1, sn)
            sac = HP.sac(r, h=r * 3.3, seed=70 + 2 * i + (side > 0), kind='sac', glow=1, hang=2.4)
            cz_ = r * 3.3 - r
            # the drip: each teardrop draws out to a point at its free end (the picture's hanging drops)
            sac.add('crease_drip', 'body', 'flesh2', HP.tube([Vector((0, 0, cz_ + r * 0.82)), Vector((0, 0, cz_ + r * 1.2)), Vector((0, 0, cz_ + r * 1.6))],
                                                            [r * 0.42, r * 0.16, r * 0.02], n=10))
            K.organ(fid, sac, pos, hang, fwd=(1, 0, 0), inv='teardrop_sacs',
                    what='teardrop sac, %.1f across' % (2 * r), note='spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly')
    K.mass('Teardrop sacs', _bpy.data.objects['S3p_mount_flesh'], 'flesh sacs', note='a fringe of teardrops under the belly')

    # ---------------- siphons ----------------
    for k, (x, th, r) in enumerate(SIPHONS):
        for side in (1, -1):
            pos, nrm = K.hpt(x, side_th(th, side), out=-0.03)
            K.thruster('Q%d%s' % (k + 1, 'p' if side > 0 else 's'), tuple(pos), tuple(nrm), r=r, inv='siphons',
                       note='siphon %s: swings the %s' % ('forward' if x > 0 else 'aft', 'front' if x > 0 else 'stern'))

    # ---------------- the stern: four pulse vents and their membranes ----------------
    for k, (y, z, r, nt, od) in enumerate(VENTS):
        K.engine('E%d' % (k + 1), (-5.5, y, z), r, 0.9, bell=1.0, body_r=r * 1.35, inv='vents', src='picture',
                 kw=dict(trail='veil', trails=2, trail_len=4.78, veil=3.6, fan=0.785, splay=30.0, out_dir=od, seed=k + 3),   # the family's veils (C12, R333)
                 note='pulse vent with two wide trailing veils lit from within (the family\'s veil, as C12), splayed away from the stern\'s centre')
    K.mass('Vents', _bpy.data.objects['E1_mount_flesh'], 'flesh', note='four pulse vents at the stern, the membranes streaming aft')

    # ---------------- grown detail on the hull ----------------
    # stretch wrinkles: the skin drawn up into each opening's neck
    V, F = [], []
    for fid, x0, th0, lean in MOUTHS:
        for k in range(12):
            a = 2 * math.pi * (k + rnd.uniform(-0.25, 0.25)) / 12
            ln = rnd.uniform(1.0, 1.8)
            pts = []; nrms = []; ws = []; hs = []
            for j in range(9):
                t = j / 8
                rr = 1.9 + ln * t
                rad = _k.sec_at(HULL, x0)[1]
                x = x0 + rr * math.cos(a); th = th0 + rr * math.sin(a) / max(2.5, rad)
                if x > 5.4 or x < -4.6:
                    break
                p_, n_ = K.hpt(x, th, out=-0.02); pts.append(p_); nrms.append(n_)
                env = math.sin(math.pi * (0.1 + 0.8 * t))
                ws.append(0.22 * env + 0.04); hs.append(0.07 * env + 0.01)
            if len(pts) < 4:
                continue
            vv, ff = HP.welt(pts, nrms, ws, hs, n=5)
            o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
    K.hull_detail('stretch_folds', (V, F), 'flesh2', inv='stretch_folds', kind='welt', subs=['welt'])
    # the folded sac: long broken fold rolls running fore and aft over the body between the openings (never a band or segment)
    V, F = [], []
    keep_clear = [(x, th) for _, x, th, _ in MOUTHS] + [(PATCH[0], math.pi / 2 - 0.28)] + [(x, side_th(th, s)) for x, th, _ in SIPHONS for s in (1, -1)]
    for k in range(40):
        th0 = rnd.uniform(-1.0, math.pi + 1.0)
        xa = rnd.uniform(-3.4, 3.6); ln = rnd.uniform(1.5, 3.4)
        pts = []; nrms = []; ws = []; hs = []
        for j in range(12):
            t = j / 11
            x = xa - ln * t
            th = th0 + 0.06 * math.sin(j * 0.9 + k)
            if x < -4.4 or any(abs(x - cx) < 2.0 and abs(math.atan2(math.sin(th - ct), math.cos(th - ct))) < 0.55 for cx, ct in keep_clear):
                break
            p_, n_ = K.hpt(x, th, out=-0.03); pts.append(p_); nrms.append(n_)
            env = math.sin(math.pi * (0.06 + 0.88 * t))
            ws.append(0.5 * env + 0.05); hs.append(0.12 * env + 0.01)
        if len(pts) < 4:
            continue
        vv, ff = HP.welt(pts, nrms, ws, hs, n=5)
        o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
    K.hull_detail('body_folds', (V, F), 'flesh2', inv='body_folds', kind='welt', subs=['welt'])
    # pore fields round the front and over the shoulders (the Chorus has no eyes: it tastes)
    for name, x0, x1, t0, t1, nper in (('front', 3.6, 5.6, -1.3, 4.4, 160), ('shoulder', -3.0, 3.0, 1.0, 2.1, 120)):
        V, F = [], []
        for _ in range(nper):
            x = rnd.uniform(x0, x1); th = rnd.uniform(t0, t1)
            if any(abs(x - cx) < 2.0 and abs(math.atan2(math.sin(th - ct), math.cos(th - ct))) < 0.5 for cx, ct in keep_clear):
                continue
            pos, nrm = K.hpt(x, th, out=0.0)
            vv, ff = HP.pore(pos, nrm, rnd.uniform(0.03, 0.06), n=6)
            o = len(V); V += vv; F += [tuple(q + o for q in f) for f in ff]
        K.hull_detail('pores_' + name, (V, F), 'pore', inv='pore_fields', kind='pore', subs=['rim', 'pit'])
    # veins: from the belly sacs up the flanks to the openings' chambers
    for side in (1, -1):
        V, F = [], []
        for x0, x1 in ((1.0, 2.55), (-1.7, -1.45), (-0.35, -2.25)):
            pts = []; nrms = []
            for j in range(14):
                t = j / 13
                x = x0 + (x1 - x0) * t
                th = side_th(-1.3 + (0.85 if x1 != -2.25 else 1.2) * t, side) + 0.05 * math.sin(j)
                p_, n_ = K.hpt(x, th, out=0.0); pts.append(p_); nrms.append(n_)
            vv, ff = HP.welt(pts[:-3], nrms[:-3], 0.08, 0.04, n=5)
            o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
        K.hull_detail('veins_%s' % ('p' if side > 0 else 's'), (V, F), 'vein', inv='veins', kind='vein', subs=['vein', 'branch'])
    # scars: regrowth patches with knit ridges (the picture's scarred flesh)
    for k, (x, th, r) in enumerate(((3.9, 0.9, 0.45), (0.9, 2.55, 0.5), (-0.6, -0.4, 0.42), (-3.4, 1.9, 0.4), (2.0, -0.2, 0.38), (-2.6, 2.9, 0.36))):
        pos, nrm = K.hpt(x, th, out=0.0)
        (pv, pf), (kv, kf) = HP.scar(pos, nrm, r, seed=40 + k, knits=3)
        K.hull_detail('scar%d_patch' % k, (pv, pf), 'scar', inv='scars', kind='scar', subs=['patch', 'knit'])
        K.hull_detail('scar%d_knit' % k, (kv, kf), 'tissue')

    # ---------------- colour zones ----------------
    K.colour('dark olive flesh, hard chitin hide in grown irregular plates (paint stage, R325)', 6.2, -5.15, 'whole body')
    K.colour('raw transition tissue', 3.0, -2.5, 'the lips of the five openings and the spore patch walls')
    K.colour('wet dark maw, dim bile at the floor', 3.0, -2.5, 'inside the five openings')
    K.colour('bile yellow-green light', 6.2, 5.4, 'the spine pore\'s gland')
    K.colour('bile yellow-green light', -5.15, -10.3, 'the vents and the light in the membranes')
    K.colour('dim bile', 4.0, -3.0, 'the veins, the sac windows, the pores')

    # ---------- INSIDE: flesh, bone and organs; the hangar is the sac's own chambers ----------
    K.septum('lower', -1.3, 4.8, -4.0)
    K.septum('upper', 1.25, 4.7, -4.1)
    for i, x in enumerate((5.0, 3.5, 2.75, 1.0, -0.3, -1.6, -2.8, -4.3)):   # clear of the three seams
        K.hoop('F%d' % i, x)
    K.organ_room('spine_gland', 'gland', (4.85, 0.0, -0.1), (0.55, 0.45, 0.45), note='the spine pore\'s bile gland: the shot\'s magazine', seed=1)
    K.organ_room('ganglion', 'ganglion', (4.0, 0.0, 1.9), (0.6, 0.5, 0.38), note='the Node: the knot of nerve that steers the body (no bridge)', seed=2)
    for fid, x, th, lean in MOUTHS:
        pos, nrm = K.hpt(x, th, out=0.0)
        c = Vector(pos) - Vector(nrm) * 2.9
        K.organ_room('brood_%s' % fid, 'brood', tuple(c), (0.85, 0.75, 0.7), note='brood chamber under opening %s: the squadrons grow here (hangar 3)' % fid, seed=10 + int(fid[1]))
    K.organ_room('spore_store', 'gland', (-0.15, 0.95, 1.95), (0.8, 0.6, 0.38), note='the spore store under the patch', seed=20)
    K.organ_room('heart_vat', 'vat', (0.1, 0.0, 0.0), (1.1, 0.95, 0.75), note='the heart vat: the core (hp_core), lit bile-green', seed=21)
    K.organ_room('gut_fore', 'gut', (2.4, 0.0, -2.0), (1.4, 1.2, 0.55), note='the gut: it feeds the brood', seed=22)
    K.organ_room('gut_aft', 'gut', (-1.6, 0.0, -2.0), (1.3, 1.1, 0.5), note='the second stomach', seed=23)
    for i, x in enumerate((0.9, -1.4)):
        for side in (1, -1):
            K.organ_room('feed_%d%s' % (i + 1, 'p' if side > 0 else 's'), 'organ', (x, side * 2.3, -2.0), (0.6, 0.45, 0.4), note='spore feed store over the teardrop sacs', seed=30 + i)
    K.organ_room('regrowth_p', 'organ', (-2.9, 1.5, 0.3), (0.55, 0.4, 0.4), note='regrowth tissue (regen 6)', seed=34)
    K.organ_room('regrowth_s', 'organ', (-2.9, -1.5, 0.3), (0.55, 0.4, 0.4), note='regrowth tissue', seed=35)
    K.organ_room('pulse_bladder', 'engroom', (-4.0, 0.0, 0.05), (0.6, 0.6, 0.5), note='the pulse bladder: fills and squeezes the four vents (the engine room)', seed=36)
    K.armour('front and the spine pore', 0.4, 'the thickest flesh round the throat root')
    K.armour('back and shoulders', 0.3, 'hard chitin hide over the chambers')
    K.armour('flanks and openings', 0.3, 'the necks are thick muscle')
    K.armour('belly and sacs', 0.25, 'thin over the teardrop sacs: they rupture first')
    K.armour('stern', 0.2, '')
    K.break_line('B-1', 4.3, 'behind the front: the front folds tear away, opening the spine gland and the Node',
                 path=[(4.45, 7.0), (4.45, 2.9), (4.1, 1.8), (4.55, 0.7), (4.1, -0.4), (4.5, -1.5), (4.15, -2.6), (4.15, -7.0)])
    K.break_line('B-2', 1.95, 'across the middle, ahead of the pore patch: the sac tears open through the heart vat\'s front and the gut, the teardrops bursting first',
                 path=[(2.1, 7.0), (2.1, 3.2), (1.9, 1.6), (2.05, 0.0), (1.85, -1.6), (2.0, -3.2), (2.0, -7.0)])
    K.break_line('B-3', -3.65, 'ahead of the stern: the vents and the membranes tear free, opening the pulse bladder',
                 path=[(-3.5, 7.0), (-3.5, 2.2), (-3.85, 1.2), (-3.45, 0.2), (-3.9, -0.9), (-3.55, -2.0), (-3.55, -7.0)])
    K.inside.append(dict(kind='note', name='insides', note='Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, '
                                                          'membrane septa for decks, organs and chambers that never reach the skin; a brood chamber under each opening. '
                                                          'The Chorus bursts and tears: sacs rupture first, then the body tears open along ragged lines (R186).'))
    K.point('core', 'hp_core', (0.1, 0.0, 0.0))
    # seven breach anchors (Carrier base 6, the Chorus +1 on the big ones): front 2, middle 3, stern 2, beside the sacs and folds
    for i, (x, th, sec, side) in enumerate(((3.6, -0.15, 'prow', 1), (3.9, 1.1, 'prow', -1), (0.6, 0.35, 'mid', 1), (0.2, -0.9, 'mid', -1),
                                            (-0.9, -0.5, 'mid', 1), (-2.8, 0.55, 'eng', -1), (-3.9, -0.6, 'eng', 1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('breach', 'hp_breach_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd', section=sec, note='open hide between the folds')
    k = 0
    for x, th, r in SIPHONS:
        for side in (1, -1):
            pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
            K.point('rcs', 'hp_rcs_%d' % k, tuple(pos), side='port' if side > 0 else 'stbd'); k += 1
    # launch mouths (hangar 3): one bay point on each opening's floor, launching out along its neck
    for i, (fid, x, th, lean) in enumerate(MOUTHS):
        pos, nrm = K.hpt(x, th, out=-0.05)
        ax = (Vector(nrm) + Vector((lean, 0, 0))).normalized()
        ob = _bpy.data.objects['%s_mount_maw' % fid]
        vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
        floor = min(vs, key=lambda v: (v - (Vector(pos) - ax * 1.9)).length)
        K.point('bay', 'hp_bay_%d' % i, tuple(floor), side='port' if pos[1] > 0.1 else 'stbd' if pos[1] < -0.1 else 'top', note='launch opening %s floor' % fid, dir=tuple(ax))
    for i, side in enumerate((1, -1)):
        pos, nrm = K.hpt(0.4, side_th(-0.45, side), out=0.02)
        K.point('board', 'hp_board_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('Colour: dark olive flesh with hard chitin hide, bile yellow-green light; the openings dark inside with a dim bile glow at the floor',
             'R204 and the lore: the colour is fixed in the build; the picture renders the family\'s grey-amber anchor palette. R325: hard chitin with a little wet-flesh variety')
    K.change('Five launch openings on necks of flesh, one on the back at the stern, a pair high on the aft shoulders, a pair on the rim at the forward corners',
             'designs.md: five openings round the rim, evenly dispersed with wide stretches of plain flesh; the front view draws them round the axis, '
             'the plan round the disc; placed so each launches clear of every other part (fit check EXIT) and none sits in the vents\' jets. '
             'The job text said two openings; designs.md, the beauty and the sheet all draw five, so five are built (flagged to the Board)')
    K.change('The openings are drawn empty: a deep dark chamber 1.9 deep, a dim glow at its floor, nothing in it',
             'Ryan, Nov 13: no pods shown; squadron capacity (hangar 3) is an internal fact, a brood chamber under each opening')
    K.change('One spine pore (bioplasma F) at the centre of the front folds; the picture\'s second, lower radial pucker is where the lobes meet round it',
             'data.js b_brood has one bioplasma slot: one throat; the beauty\'s small upper pore and its radial pucker are read as one organ, so nothing pictured is left without a job (R221)')
    K.change('The pore patch is the spore cloud (spores T): a ragged honeycomb of pores on a low mound that leans toward the craft (a turret)',
             'the weapon-match table puts spores on a turning spore organ; the three biggest pores fire the three shots of each volley')
    K.change('Eighteen teardrop sacs in two rows under the belly (nine a side), clear of the low openings\' launch lanes',
             'designs.md: a row of teardrop sacs, spore feed and regrowth flesh (regen 6); the picture\'s count (about fourteen) does not settle counts')
    K.change('Four pulse vents at the stern, the membranes cut to about 0.4 of the body\'s length',
             'factions.md: no nozzles, pulsing vents or trailing membranes; the picture\'s membranes are nearly as long again as the body, which would make '
             'the sac a small part of a 16.5 ship; cut so the whole ship is 16.5 front to membrane tip')
    K.change('Siphons added, a pair low on the flanks amidships and a pair low aft', 'a ship in space must turn; the picture shows none; siphons, not nozzles')
    K.change('Insides: a brood chamber under each opening, the spore store under the patch, the heart vat, two guts, spore feed stores over the sacs, regrowth tissue and the pulse bladder',
             'R209, R215: flesh, bone and organs through the whole body; the hangar is the body\'s own chambers')
    K.open_item('The belly between the sacs is designed here; the sheet has no underside view')
