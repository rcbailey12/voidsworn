# chorus_C14: the brood-sac, the Chorus carrier (class Carrier, 16.5 world units). Issue 1155.
# Accepted picture: contrib/muse/design/class_family_chorus_2026_11/chorus_C14_brood_sac_v11.jpg and chorus_C14_brood_sac_sheet_v5.jpg
# (issue 631, Ryan accepted Nov 13 2026); designs.md governs where a picture differs.
# data.js b_brood (Chorus brood-sac): bioplasma F, spores T; ability launch, hangar 3; regen 6; speed 2; no shields.
# Designer of record: Opus (R205, R207). The concept guides; it is not traced. Built and judged from the WHOLE pictures first (R229).
# Measured off the v5 sheet's true views (side view bow LEFT, plan bow DOWN, front view): the sac is as long as it is wide in plan
# (about 545 by 540 px with the rim openings, the body alone about 470 wide) and two thirds as tall as long in profile (435 by
# 290 px); the front is blunt, skin folds creased in toward one puckered mouth; five launch openings on thick necks stand round
# the rim (one on the back aft, a pair high on the aft shoulders, a pair low on the forward flanks: the front view's five round
# the axis, the plan's five round the disc); a sunk honeycomb of pores on the upper front, off the centre line; a fringe of teardrop sacs
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
SHEET = dict(version=7, round='blockout v7, the sacs capped lighter (16 scutes a bulb; R341, issue 1155)', date='2026-11-19', blend='opus1155\\chorus_C14',
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
R_THROAT = 0.42       # the spine pore: a small dark pinch where the folds meet, no ring lip (Board v2 note 1); one modest weapon (designs.md)
# the five launch openings (hangar 3): (id, station x, section angle, lean along x); the front view's five round the axis
MOUTHS = (('L1', -3.6, math.pi / 2, -0.36),         # on the back at the stern, leaning aft
          ('L2', -1.8, 0.34, -0.3), ('L3', -1.8, math.pi - 0.34, -0.3),    # high on the aft shoulders
          ('L4', 2.85, 0.06, 0.3), ('L5', 2.85, math.pi - 0.06, 0.3))          # on the rim at the forward corners (all five read from above)
R_MOUTH = 1.05        # as big as the beauty's (Board v1 note 3), on taller necks with fat round lips
NECK = 0.8           # short necks: fat round rings close to the rim (Board v2 note 5)
# the honeycomb field round the spore patch (Board v1 note 4): on the upper front, about a fifth of the top, sunk in a raised rim
# (centre station x, centre section angle, half length along x, half width across in world units); the patch turns at its front
FIELD = (2.55, math.pi / 2 + 0.12, 1.75, 2.35)
PATCH = (3.05, math.pi / 2 + 0.08, 0.72)    # the turning cluster: station x, section angle, radius
# the teardrop sacs under the belly (spore feed and regrowth flesh): (station, section angle on the port side, radius)
# Board v1 note 5: bigger, longer teardrops in a fringe low on the belly's edge, so they hang below the outline at the beauty camera
# Board v3 note 1: one clear row of long pale teardrops hanging well below the hull, spaced apart, each on a long thin neck
SACS = ((3.85, -1.0, 0.4), (2.8, -0.96, 0.46), (1.75, -1.04, 0.5), (0.7, -0.96, 0.52), (-0.35, -1.04, 0.52),
        (-1.4, -0.96, 0.52), (-2.45, -1.04, 0.5), (-3.5, -0.98, 0.46), (-4.45, -1.06, 0.4))
SAC_HANG = (5.2, 4.4, 5.6, 4.6, 5.4, 4.5, 5.5, 4.7, 5.0)   # each sac's length as a share of its radius: long necks, uneven drop
SIPHONS = ((0.6, -0.6, 0.3), (-3.1, -0.5, 0.27))
VENTS = ((0.0, 0.62, 0.2, 2, (0, 0, 1)), (0.55, 0.05, 0.19, 3, (0, 1, 0.1)), (-0.55, 0.05, 0.19, 3, (0, -1, 0.1)), (0.0, -0.5, 0.17, 2, (0, 0, -1)))


def build(K):
    import kit as _k
    from mathutils import Vector
    import bpy as _bpy
    import random
    import sys
    if _k._KITS not in sys.path:
        sys.path.append(_k._KITS)
    from chorus import plates
    HP = _k.HP
    plates.register(_k)   # the armour shell's materials (R341)

    hull = K.hull(HULL, 'flesh', shell=0.3, rounded=True, pexp=PEXP, n=56, smooth=True, wobble=WOBBLE)
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
    K.spinal('M1', (hx - (L_ - 0.12 * R_THROAT), THR[0], THR[1]), L_, r=R_THROAT, slot='F', weapon='bioplasma', inv='spine_pore', style='pinch',
             lip_r=R_THROAT * 1.2, pinch=R_THROAT * 2.6, teeth=9, seed=14, side=1, gland_at=0.4,
             note='the spine pore: one small fleshy rimmed hole set in the front folds, a dark wet throat, the bile gland glowing deep inside')
    # the front skin (Board v1 note 1): one skin of the hull's own flesh over the face and the front quarter, folded by deep
    # creases that start at the rim and sink in toward the mouth (the beauty's puckered front); grooves cut in, nothing added
    rnd = random.Random(1155)
    # Board v3 note 2: fewer, bigger, uneven lobes (not even pumpkin segments), the folds pulling round toward the mouth
    NCR = 6
    GAPS = (1.45, 0.75, 1.2, 0.85, 1.05, 0.7)   # the lobes' widths round the mouth, as shares of an even split
    creases = []
    a_ = 0.35
    for k in range(NCR):
        creases.append((a_, rnd.uniform(-0.45, 0.45), rnd.uniform(1.7, 1.98), rnd.uniform(0.95, 1.15), rnd.uniform(0.85, 1.25)))
        a_ += 2 * math.pi * GAPS[k] / sum(GAPS)

    def x_back(t):   # where the skin ends behind the front: further forward on top, where the honeycomb field begins
        return 3.65 + 0.75 * max(0.0, math.sin(t)) ** 3
    rho0 = R_THROAT * 1.05 / min(hw0, hz0)
    EYE = (5.38, math.pi / 2 + 0.2, 0.15)   # the small eye-hole above the mouth (x, section angle, radius): a sense pit
    fwd_mouths = [(x, th) for _, x, th, _ in MOUTHS if x > 1.0]

    def skin(s_, t):
        """(point, normal, offset) on the front skin: s_ 0 to 1 over the face from the mouth's lip to its rim, 1 to 2 back over the hull"""
        c, sn = math.cos(t), math.sin(t)
        if s_ < 1.0:
            rho = rho0 + (1 - rho0) * s_
            y = rho * hw0 * math.copysign(abs(c) ** (2 / PEXP[0 if sn >= 0 else 1]), c)
            z = zc0 + rho * hz0 * math.copysign(abs(sn) ** (2 / PEXP[0 if sn >= 0 else 1]), sn)
            q = Vector((face_x(y, z), y, z)); n_ = Vector((1.0, 0.25 * y / hw0, 0.25 * (z - zc0) / hz0)).normalized(); rad = rho * (hw0 + hz0) / 2
        else:
            x = HULL[0][0] - 0.01 - (HULL[0][0] - 0.01 - x_back(t)) * (s_ - 1)
            q, n_ = K.hpt(x, t, out=0.0); q = Vector(q); n_ = Vector(n_); rad = _k.sec_at(HULL, x)[1]
        # the swell of the cushions (Board v2 note 2): pinched down into the mouth, fat over the face and the front, sinking into
        # the hull at the back edge
        u_ = min(1.0, s_ / 0.7)
        a = 0.02 + 0.5 * u_ * u_ * (3 - 2 * u_)
        if s_ > 1.5:
            a = 0.52 - 0.6 * min(1.0, (s_ - 1.5) / 0.5)
        for cx, ct in fwd_mouths:   # the skin gives way round the forward openings' necks
            if s_ > 1.0:
                d = math.hypot(q.x - cx, rad * math.atan2(math.sin(t - ct), math.cos(t - ct)))
                a = min(a, -0.07 + 0.32 * min(1.0, max(0.0, (d - 2.0) / 0.8)))
        g = 0.0
        for a0, tw, reach, dep, wk in creases:
            if s_ > reach:
                continue
            fade = min(1.0, (reach - s_) / 0.25)
            ang = a0 + tw * s_ * s_ * 0.6 + 0.05 * math.sin(4 * s_ + a0 * 3)
            dw = rad * abs(math.atan2(math.sin(t - ang), math.cos(t - ang)))
            w = rad * 2 * math.pi / 11 * 0.2 * wk   # each lobe a rounded cushion between two deep folds
            g = max(g, dep * fade * math.exp(-(dw / w) ** 2))
        if a > 0:   # each lobe swells by its own amount, so no two match
            a *= 0.6 + 0.4 * (0.5 + 0.3 * math.sin(2 * t + 1.3) + 0.2 * math.sin(3 * t + 0.4))
        off = a - (a + 0.1) * min(1.0, g)
        return q + n_ * off, n_, off
    NS, NT2 = 46, 300
    V, F, grid = [], [], {}
    for i in range(NS + 1):
        s_ = 2.0 * i / NS
        for j in range(NT2):
            q, n_, off = skin(s_, 2 * math.pi * j / NT2)
            grid[(i, j)] = len(V); V.append(tuple(q))
    eye_c, eye_n = K.hpt(EYE[0], EYE[1], out=0.0)
    for i in range(NS):
        for j in range(NT2):
            f = (grid[(i, j)], grid[(i, (j + 1) % NT2)], grid[(i + 1, (j + 1) % NT2)], grid[(i + 1, j)])
            cen = sum((Vector(V[k]) for k in f), Vector()) / 4
            if (cen - Vector(eye_c)).length < EYE[2] * 1.05:
                continue   # the eye-hole goes through the skin
            F.append(f)
    front = K.hull_detail('front_lobes', (V, F), 'flesh2', inv='front_lobes', kind='welt', subs=['welt'])
    # the folds run dark: a thin wet line down the bottom of every crease
    V, F = [], []
    for a0, tw, reach, dep, wk in creases:
        pts = []; rads = []
        for j in range(30):
            s_ = 0.04 + (reach - 0.2) * j / 29
            ang = a0 + tw * s_ * s_ * 0.6 + 0.05 * math.sin(4 * s_ + a0 * 3)
            q, n_, off = skin(s_, ang); pts.append(q + n_ * 0.01); rads.append(0.035 + 0.035 * math.sin(math.pi * j / 29))
        vv, ff = HP.tube(pts, rads, n=6, flat=0.5)
        o = len(V); V += vv; F += [tuple(x + o for x in f_) for f_ in ff]
    K.hull_detail('front_crease_lines', (V, F), 'maw')
    K.mass('Front folds', front, 'skin folds parted by deep creases', note='creases from the rim sinking in to the spine pore')
    # the eye-hole: a small dark sense pit above the mouth (the beauty's small upper hole); it tastes, it does not see (lore 5.8)
    q, n_, off = skin(1.0 + (HULL[0][0] - EYE[0]) / max(0.01, HULL[0][0] - x_back(EYE[1])), EYE[1])
    ev, ef = HP.pore(q, n_, EYE[2] * 0.8, depth=0.5, n=14)
    K.hull_detail('eye_hole', (ev, ef), 'pore', inv='pore_fields', kind='pore', subs=['rim', 'pit'])
    # pores over the folds (the front's pore field rides on the skin, not under it)
    V, F = [], []
    for _ in range(90):
        s_ = rnd.uniform(0.5, 1.85); t = rnd.uniform(0, 2 * math.pi)
        q, n_, off = skin(s_, t)
        if off < 0.25:
            continue   # on the cushions, never in a fold
        vv, ff = HP.pore(q, n_, rnd.uniform(0.05, 0.09), n=10)
        o = len(V); V += vv; F += [tuple(x + o for x in f_) for f_ in ff]
    K.hull_detail('pores_front', (V, F), 'pore', inv='pore_fields', kind='pore', subs=['rim', 'pit'])

    # ---------------- the honeycomb field and the spore patch (spores T) on the upper front ----------------
    fx, ft, fl, fw = FIELD

    def in_field(x, t, grow=0.0):
        rad = max(2.5, _k.sec_at(HULL, x)[4])
        u = (x - fx) / (fl + grow); v = rad * math.atan2(math.sin(t - ft), math.cos(t - ft)) / (fw + grow)
        return u * u + v * v
    px_, pt_, pr = PATCH
    ppos, pnrm = K.hpt(px_, pt_, out=-0.03)
    V, F = [], []
    cells = []
    tries = 0
    while len(cells) < 330 and tries < 20000:
        tries += 1
        x = fx + fl * rnd.uniform(-1, 1); t = ft + rnd.uniform(-1, 1) * fw / max(2.5, _k.sec_at(HULL, fx)[4])
        e = in_field(x, t)
        if e > 1.0:
            continue
        q, n_ = K.hpt(x, t, out=0.01); q = Vector(q)
        if (q - Vector(ppos)).length < pr * 1.45:
            continue   # the patch turns in the field's front
        rr = rnd.uniform(0.07, 0.2) * (1.25 - 0.6 * e)
        if any((q - c).length < (rr + cr) * 1.28 for c, _, cr in cells):
            continue
        cells.append((q, Vector(n_), rr))
    for q, n_, rr in cells:
        vv, ff = HP.pore(q, n_, rr, depth=rr * 1.6, n=9)
        o = len(V); V += vv; F += [tuple(x + o for x in f_) for f_ in ff]
    K.hull_detail('spore_field', (V, F), 'pore', inv='spore_field', kind='pore', subs=['rim', 'pit'])
    # the raised rim of skin round the field, so the field reads sunk into the body
    pts = []; nrms = []; ws = []; hs = []
    for k in range(97):
        a = 2 * math.pi * k / 96
        rr_ = 1.0 + 0.06 * math.sin(5 * a + 1) + 0.04 * math.sin(11 * a)
        x = fx + (fl + 0.28) * rr_ * math.cos(a)
        rad = max(2.5, _k.sec_at(HULL, x)[4]); t = ft + (fw + 0.28) * rr_ * math.sin(a) / rad
        q, n_ = K.hpt(x, t, out=-0.04); pts.append(q); nrms.append(n_)
        ws.append(0.36 + 0.08 * math.sin(3 * a)); hs.append(0.2 + 0.05 * math.sin(4 * a + 2))
    vv, ff = HP.welt(pts, nrms, ws, hs, n=7)
    K.hull_detail('spore_field_rim', (vv, ff), 'flesh', inv='body_folds', kind='welt', subs=['welt'])   # the roll of skin the field sinks in
    K.gun('G1', tuple(ppos), 0, 0, barrels=3, cal=0.12, blen=0.5, size=1.0, normal=tuple(pnrm), slot='T', weapon='spores', inv='spore_patch',
          kw=dict(patch=pr, seed=31), note='the spore cloud: the ragged cluster at the front of the honeycomb field, leaning its cloud toward the craft (turns)')
    K.mass('Spore field and patch', _bpy.data.objects['G1_mount_flesh'], 'a sunk honeycomb of pores, the turning cluster at its front',
           note='over the upper front, off the centre line')

    # ---------------- the five launch openings (the hangar, hangar 3) ----------------
    for fid, x, th, lean in MOUTHS:
        pos, nrm = K.hpt(x, th, out=-0.05)
        ax = (Vector(nrm) + Vector((lean, 0, 0))).normalized()
        part = HP.launch_mouth(R_MOUTH, 2.2, neck=NECK, lip=1.5, flare=0.75, seed=int(fid[1]) * 13)
        K.organ(fid, part, pos, ax, fwd=(1, 0, 0), inv='launch_mouths', kind='hangar',
                what='launch opening, %.1f across, on a neck of flesh; empty, a dim glow deep inside' % (2 * R_MOUTH),
                note='a spore squadron is born deep in the chamber below and leaves through the mouth', aperture=(2.5, 0.0))
        K.mass('Launch opening %s' % fid, _bpy.data.objects['%s_mount_flesh' % fid], 'flesh neck and lip', note='thick fleshy rim, drawn empty')

    # ---------------- the teardrop sacs under the belly (spore feed storage, regrowth flesh) ----------------
    caps = []   # R341, Ryan (Nov 20, "armour the sacs"): each bulb capped in small scutes, as C11 and C12
    for i, (x, th, r) in enumerate(SACS):
        for side in (1, -1):
            sn = 'p' if side > 0 else 's'
            pos, nrm = K.hpt(x, side_th(th, side), out=-0.05)
            hang = (Vector(nrm) * 0.3 + Vector((0, 0, -1))).normalized()   # straight down, a little out
            fid = 'S%d%s' % (i + 1, sn)
            sac = HP.sac(r, h=r * SAC_HANG[i], seed=70 + 2 * i + (side > 0), kind='sac', glow=1, hang=3.0, creases=1, veins=2, armour=True)
            for c_ in sac.comps:   # pale smooth teardrops (Board v2 note 4): the bulb in pale hide, nothing standing off it
                if c_['name'] == 'sac':
                    c_['mat'] = 'hide'
            cz_ = r * SAC_HANG[i] - r
            # the neck: the sac hangs from the belly on a thin soft stalk that swells into the bulb (a teardrop, never a ball floating free)
            sac.add('root_neck', 'mount', 'flesh', HP.tube([Vector((0, 0, -0.05)), Vector((0, 0, cz_ * 0.3)), Vector((0, 0, cz_ * 0.55)), Vector((0, 0, cz_ * 0.75)), Vector((0, 0, cz_ * 0.9)), Vector((0, 0, cz_ - r * 0.2))],
                                                          [r * 0.5, r * 0.24, r * 0.3, r * 0.45, r * 0.68, r * 0.88], n=14))
            # the bare neck under the caps keeps its detail: two veins running down it into the bulb, a crease ring where it swells
            def neck_r(z):   # the stalk's radius at height z (the root_neck profile above)
                zs = [0.0, cz_ * 0.3, cz_ * 0.55, cz_ * 0.75]; rs = [r * 0.5, r * 0.24, r * 0.3, r * 0.45]
                for k_ in range(3):
                    if z <= zs[k_ + 1]:
                        u_ = (z - zs[k_]) / max(1e-6, zs[k_ + 1] - zs[k_]); return rs[k_] + (rs[k_ + 1] - rs[k_]) * u_
                return rs[-1]
            for k_, a_ in enumerate((0.7 + i, 3.9 + i)):
                pts_ = [Vector((math.cos(a_ + 0.15 * j) * neck_r(cz_ * (0.36 + 0.36 * j / 7)) * 1.02, math.sin(a_ + 0.15 * j) * neck_r(cz_ * (0.36 + 0.36 * j / 7)) * 1.02,
                                cz_ * (0.36 + 0.36 * j / 7))) for j in range(8)]
                sac.add('vein%d' % k_, 'body', 'bilewet' if k_ else 'flesh2', HP.tube(pts_, [r * 0.035] * 8, n=5))
            zc_ = cz_ * 0.62
            sac.add('crease0', 'body', 'flesh2', HP.tube([Vector((neck_r(zc_) * math.cos(2 * math.pi * j / 24), neck_r(zc_) * math.sin(2 * math.pi * j / 24), zc_)) for j in range(25)],
                                                    [r * 0.04] * 25, n=5, cap0=False, cap1=False))
            K.organ(fid, sac, pos, hang, fwd=(1, 0, 0), inv='teardrop_sacs',
                    what='teardrop sac, %.1f across' % (2 * r), note='spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly')
            caps.append(((fid + '_mount_hide',), tuple(Vector(pos) + hang * cz_), tuple(hang), r, 1.75, 0.5))   # the bulb, crown at its foot, the bile slit open
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
                 kw=dict(trail='veil', trails=2, trail_len=4.59, veil=3.6, fan=0.785, splay=30.0, out_dir=od, seed=k + 3),   # the family's veils (C12, R333)
                 note='pulse vent with two wide trailing veils lit from within (the family\'s veil, as C12), splayed away from the stern\'s centre')
    K.mass('Vents', _bpy.data.objects['E1_mount_flesh'], 'flesh', note='four pulse vents at the stern, the membranes streaming aft')

    # R341 (Ryan, Nov 19): the whole body is armoured, so the stretch folds, body folds, wrinkles, shoulder pores and scar
    # patches of v4 are gone: they lay where the scutes now lie. The wet hide shows only round the fittings and between scutes.

    # ---------------- the armour shell (R341): banded scutes over the whole body, every fitting in an open socket ----------------
    # the front's creased lobes and spine pore (the maw), the honeycomb field and its rim (the spore cloud) stay bare; the five
    # launch necks, the sacs' necks, the siphons and the vents stand in open sockets; the shell runs from the front skin's
    # sunk back edge to the stern. The teardrop sacs are capped in smaller scutes (Ryan, Nov 20).
    plates.dome_caps(K, _k, caps, seed=1356, counts=(7, 9))   # 16 scutes a bulb: 36 bulbs at the default 39 cost about 400k triangles (the Board, Nov 20)
    shells = plates.armour(K, _k, 4.3, -5.0, seed=1355, keep=('front_', 'face', 'eye_hole', 'pores_front', 'spore_field'), rows=9, scute=0.95, thick=0.2,
                  note='banded keratin scutes from belly to back, lips aft, half a scute offset per band; the creased front and spine pore, '
                       'the honeycomb field, the five launch necks, siphons and vents stand clear, the sacs capped in smaller scutes')
    # where the stern falls away under a leaning launch lip, or a band wraps low past a sac's neck, a scute would run into it: leave that
    # scute off (the kit trims by the fitting's foot; the lip stands out of its reach)
    import bmesh
    from mathutils.bvhtree import BVHTree
    lips = [ob for ob in K.coll.objects if ob.type == 'MESH' and ob.name[:1] in 'LS' and ob.name[1:2].isdigit() and '_body_' in ob.name]
    trees = [BVHTree.FromPolygons([ob.matrix_world @ v.co for v in ob.data.vertices], [p_.vertices for p_ in ob.data.polygons]) for ob in lips]
    for sh in shells:
        bm = bmesh.new(); bm.from_mesh(sh.data)
        M = sh.matrix_world
        st = BVHTree.FromPolygons([M @ v.co for v in bm.verts], [[v.index for v in f.verts] for f in bm.faces])
        bm.faces.ensure_lookup_table()
        hit = {j for t in trees for _, j in st.overlap(t)}
        for f in bm.faces:   # and a scute the lip sits inside, or nearly touches
            c = M @ f.calc_center_median()
            if any(t.find_nearest(c, 0.3)[0] is not None for t in trees):
                hit.add(f.index)
        seen = set(); drop = set()
        for j in hit:   # the whole scute: every face linked to the one that touches the lip
            if j in seen:
                continue
            stack = [bm.faces[j]]
            while stack:
                f = stack.pop()
                if f.index in seen:
                    continue
                seen.add(f.index); drop.add(f)
                stack.extend(g for e in f.edges for g in e.link_faces if g.index not in seen)
        if drop:
            bmesh.ops.delete(bm, geom=list(drop), context='FACES')
            bm.to_mesh(sh.data); sh.data.update()
            print('[armour] %s: %d scute faces left off under the launch lips and the sac necks' % (sh.name, len(drop)))
        bm.free()

    # ---------------- colour zones ----------------
    K.colour('warm brown flesh (paint stage)', 6.2, -5.15, 'whole body')
    K.colour('brown keratin scutes over warm brown hide (R341)', 4.3, -5.0, 'the armour shell, belly to back')
    K.colour('raw transition tissue', 3.0, -2.5, 'the lips of the five openings and the spore patch walls')
    K.colour('wet dark maw, dim bile at the floor', 3.0, -2.5, 'inside the five openings')
    K.colour('bile yellow-green light', 6.2, 5.4, 'the spine pore\'s gland')
    K.colour('bile yellow-green light', -5.15, -10.3, 'the vents and the light in the membranes')
    K.colour('dim bile', 4.0, -3.0, 'the sac windows, the pores')

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
    K.organ_room('spore_store', 'gland', (2.7, -0.35, 1.6), (0.8, 0.6, 0.38), note='the spore store under the honeycomb field', seed=20)
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
    for i, (x, th, sec, side) in enumerate(((3.45, -0.55, 'prow', 1), (3.3, 0.75, 'prow', -1), (0.2, -0.05, 'mid', 1), (-0.4, -0.4, 'mid', -1),
                                            (-1.3, -0.35, 'mid', 1), (-2.8, 0.55, 'eng', -1), (-3.9, -0.6, 'eng', 1))):
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
        floor = min(vs, key=lambda v: (v - (Vector(pos) - ax * 2.2)).length)
        K.point('bay', 'hp_bay_%d' % i, tuple(floor), side='port' if pos[1] > 0.1 else 'stbd' if pos[1] < -0.1 else 'top', note='launch opening %s floor' % fid, dir=tuple(ax))
    for i, side in enumerate((1, -1)):
        pos, nrm = K.hpt(0.4, side_th(-0.45, side), out=0.02)
        K.point('board', 'hp_board_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('An armour shell of banded overlapping keratin scutes over the whole sac (seven bands, lips aft); the stretch folds, body folds, wrinkles, shoulder pores and scar patches of v4 removed; the creased front, the spine pore, the honeycomb field and the launch necks stay bare; each teardrop sac capped in smaller scutes (Ryan, Nov 20)',
             'Ryan, Nov 19 (R341): the Chorus armour covers the entire body like a pangolin or armadillo, minus the spine, maw, engines and weapons; the shared kit (plates.armour, R333) as C11, C12 and C13; Ryan on v5 (Nov 20): "Accept, but armour the sacs"')
    K.change('No modelled hide pads (their pores read as rivets and their edges as panel seams, the Board on v2); the hide\'s grown plates are paint (stage 5). Colour: dark olive flesh with hard chitin hide, bile yellow-green light; the openings dark inside with a dim bile glow at the floor',
             'R204 and the lore: the colour is fixed in the build; the picture renders the family\'s grey-amber anchor palette. R325: hard chitin with a little wet-flesh variety')
    K.change('Five launch openings on necks of flesh, one on the back at the stern, a pair high on the aft shoulders, a pair on the rim at the forward corners',
             'designs.md: five openings round the rim, evenly dispersed with wide stretches of plain flesh; the front view draws them round the axis, '
             'the plan round the disc; placed so each launches clear of every other part (fit check EXIT) and none sits in the vents\' jets. '
             'The job text said two openings; designs.md, the beauty and the sheet all draw five, so five are built (flagged to the Board)')
    K.change('The openings are drawn empty: a deep dark chamber 2.2 deep, a dim glow at its floor, nothing in it; 2.1 across, fat round lips on short necks 0.6 tall close to the rim (the Board on v1 note 3 and v2 note 5)',
             'Ryan, Nov 13: no pods shown; squadron capacity (hangar 3) is an internal fact, a brood chamber under each opening')
    K.change('One spine pore (bioplasma F): a small dark pinch where the front\'s cushioned folds meet, no ring lip; the small hole above it is a sense pit (an eye-hole that tastes)',
             'data.js b_brood has one bioplasma slot: one throat; blockout v3 (the Board on v2, notes 1 and 2): the v2 ring lip read as a porthole, so the mouth is a pinch; the front is rounded cushions between deep dark folds; blockout v4 (the Board on v3, note 2): six lobes, not eleven, uneven in width and swell, the folds curving round toward the mouth')
    K.change('The honeycomb is a sunk field of pores over the upper front (about a fifth of the top) in a raised rim; the spore cloud (spores T) is the ragged cluster at its front that leans toward the craft (a turret)',
             'the weapon-match table puts spores on a turning spore organ, and a turret the size of the field could not turn on a curved body; the three biggest pores fire the three shots of each volley. Blockout v2, the Board\'s note 4')
    K.change('Eighteen pale teardrop sacs in one spaced row low on the belly\'s edge (nine a side), each on a long thin neck that swells into the bulb, hanging well below the hull (blockout v2 note 5, v4 note 1)',
             'designs.md: a row of teardrop sacs, spore feed and regrowth flesh (regen 6); the picture\'s count (about fourteen) does not settle counts')
    K.change('Four pulse vents at the stern, the membranes cut to about 0.4 of the body\'s length',
             'factions.md: no nozzles, pulsing vents or trailing membranes; the picture\'s membranes are nearly as long again as the body, which would make '
             'the sac a small part of a 16.5 ship; cut so the whole ship is 16.5 front to membrane tip')
    K.change('Siphons added, a pair low on the flanks amidships and a pair low aft', 'a ship in space must turn; the picture shows none; siphons, not nozzles')
    K.change('Insides: a brood chamber under each opening, the spore store under the patch, the heart vat, two guts, spore feed stores over the sacs, regrowth tissue and the pulse bladder',
             'R209, R215: flesh, bone and organs through the whole body; the hangar is the body\'s own chambers')
    K.open_item('The belly between the sacs is designed here; the sheet has no underside view')
