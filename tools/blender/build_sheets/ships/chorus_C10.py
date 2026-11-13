# chorus_C10: The Ninefold Maw, the Chorus flagship (class Bio-titan, 28.0 world units). Issue 623, the Chorus build sheets.
# Accepted picture: contrib/muse/design/concept_round8b_2026_11/chorus_C10_beauty.jpg and _sheet.jpg (R204).
# data.js b_boss: bioplasma F, bioplasma F, tendril T, spores T; hangar 3 (ability launch: spore swarms); regen 20; no shields.
# Designer of record: Opus (R205, R207). The concept guides; it is not traced. Built and judged from the WHOLE pictures first (R229).
# Measured off the round 8b sheet's true views (bow LEFT in both; side view 59.3 px a unit, plan 58.7, the mouth's front to the
# tail's end 24.6 units, the membranes trail on to the full 28.0): the head and mouth mass 4.9 wide and 3.9 tall, the body
# 4.7 wide and 3.7 deep through the middle, tapering from 60 percent to a tail that rises toward the back line; three big sacs
# a side on the lower flanks (2.9, 2.2 and 1.7 across), five small sacs hanging on necks under the belly, the tendril crown at
# about half length on the back, a raised ridge line along each shoulder; hull length to beam 5.2, length to height 6.5.
# +X bow, +Y port, +Z up. Mouth front x = +14.0, vent mouths x = -10.45, membrane tips x = -13.95.
import math

CODE = 'chorus_C10'
NAME = 'The Ninefold Maw (Chorus flagship)'
FACTION = 'The Chorus (chorus)'
CLASS = 'Bio-titan'
LENGTH = 28.0
GAME = "data.js b_boss (cls 'Bio-titan'); length from godot/render/hull_table.gd CLS_LEN['Bio-titan'] = 28.0"
BEAUTY = 'contrib/muse/design/concept_round8b_2026_11/chorus_C10_beauty.jpg'
KIT = 'chorus'
CONCEPT_SHEET = 'contrib/muse/design/concept_round8b_2026_11/chorus_C10_sheet.jpg'
# the true views on the 8b sheet (x0, y0, x1, y1), bow on the LEFT already; the escort (right) is a separate shape, left out
CONCEPT_VIEWS = dict(top=dict(box=(75, 30, 1840, 600), largest=True, flip=False), side=dict(box=(65, 600, 1860, 1195), largest=True, flip=False))
CROPS = [('bow (the double mouth)', (90, 480, 1000, 1010)), ('midships (crown and sacs)', (560, 60, 1450, 960)), ('stern (vent crown and membranes)', (1150, 30, 1920, 700))]
SHEET = dict(version=4, round='round 4, the body', date='2026-11-12', blend='opus623\\chorus_C10',
             before='First full layout', before_note='The first complete C10 layout with the Chorus kit, run through the check before any fix.')

PEXP = (2.3, 2.0)   # a soft back, a round belly: no flat top, no parallel sides (the Board on PR 628)
WOBBLE = (0.12, 1.3)   # the body's unevenness: no flat faces and no straight lines
# key sections (x, half-beam port, half-beam starboard, belly, back): the head swells tallest just behind the mouth's fold
# lips (round 3: face first); behind it the body is broad and low, a flattened oval about 1.4 wide to 1 tall with a soft
# dorsal dome (round 4), swelling a little just behind the head and tapering in one smooth curve to a thin tail
KEY = [
    (11.75, 2.25, 2.25, -2.25, 1.7),
    (11.2, 2.8, 2.8, -2.75, 2.25),
    (10.2, 2.98, 2.98, -2.9, 2.5),
    (8.0, 3.05, 3.05, -2.3, 2.15),
    (5.0, 2.87, 2.87, -1.96, 1.96),
    (2.0, 2.57, 2.57, -1.74, 1.86),
    (-1.0, 2.2, 2.2, -1.42, 1.7),
    (-4.0, 1.71, 1.71, -0.96, 1.5),
    (-6.5, 1.16, 1.16, -0.42, 1.26),
    (-8.4, 0.78, 0.78, -0.12, 1.18),
    (-9.6, 0.58, 0.58, 0.1, 1.12),
    (-10.15, 0.48, 0.48, 0.24, 1.04),
]


def dense(key, step=0.4):
    """the key sections smoothed (Catmull-Rom through every column), so the grown body has no kinks"""
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
PL = dict(size=(0.5, 1.1), thick=(0.02, 0.045), skip=0.18, stack=0.0, mats={'flesh': 5, 'hide': 3, 'flesh2': 2, 'scar': 0.35},
          rivet_mat='pore', subs=['pad', 'pore'], rivets=True, rr=0.03)

GLANDS = (4.9, 2.55, 0.2, -2.9, -5.1)          # the spore glands' stations under the belly
SACS = ((5.06, 1.25, -0.8), (0.34, 1.0, -0.82), (-3.6, 0.75, -0.8))   # brood sacs: station, radius, section angle (port) where the neck grows out   # brood sacs: station, radius, section angle (port)


def build(K):
    import kit as _k
    from mathutils import Vector, Matrix
    HP = _k.HP

    hull = K.hull(HULL, 'flesh', shell=0.3, plates=dict(PL, seed=11, inv='hide'), rounded=True, pexp=PEXP, n=40, smooth=True, wobble=WOBBLE)
    K.mass('Hull: the long body', hull, 'dark olive flesh', note='broad flat back, rounder belly, tapering to a tail that rises to the back line')
    K.mark('body', 'hull', ['ridge', 'fold', 'pore'])

    def side_th(th, side):
        return th if side > 0 else math.pi - th

    # ---------------- the double mouth: two bile spitters (bioplasma F, F) ----------------
    for i, side in enumerate((1, -1)):
        fid = 'M%d' % (i + 1)
        K.spinal(fid, (11.27, 1.36 * side, -0.3), 2.3, r=0.86, slot='F', weapon='bioplasma', inv='throats', style='folded', lip_r=1.2,
                 rolls=2, teeth=11, seed=3 + i, side=side, gland_at=0.6,
                 note='%s throat of the double mouth: rolled fold lips, an inner sphincter, a ring of spines, the bile gland glowing deep inside'
                      % ('port' if side > 0 else 'starboard'))
    K.allow_touch('M1', 'M2', 'the two throats grow from one fused mouth mass (the picture\'s folded double mouth)')
    import bpy as _bpy
    K.mass('Mouth, port throat', _bpy.data.objects['M1_mount_flesh'], 'flesh folds', note='the port lobe of the double mouth')
    K.mass('Mouth, starboard throat', _bpy.data.objects['M2_mount_flesh'], 'flesh folds', note='the starboard lobe')

    # ---------------- the tendril crown (tendril T) ----------------
    K.gun('T1', (1.7, 0.0, K.deck_z(1.7, 0.0) - 0.06), 0, 0, barrels=3, cal=0.17, blen=3.7, size=1.07, slot='T', weapon='tendril', inv='crown',
          kw=dict(count=13, spread=1.0, seed=5), note='boarding tendrils: a crown of fourteen hooked tendrils on a muscle mound; it leans toward its prey (turns)')
    K.mass('Tendril crown', _bpy.data.objects['T1_mount_flesh'], 'flesh mound, tendrils', note='a muscle mound with radial welts, the crown on it')

    # ---------------- the spore glands under the belly (spores T) ----------------
    for i, x in enumerate(GLANDS):
        zb = K.hpt(x, -math.pi / 2)[0].z   # the belly's skin, swell included
        K.gun('G%d' % (i + 1), (x, 0.0, zb - 0.04), 0, 0, barrels=2, cal=0.06, blen=0.6, size=1.15, normal=(0, 0, -1), slot='T', weapon='spores',
              inv='spore_glands', kw=dict(seed=20 + i), note='spore gland on its neck under the belly, the spout curled forward to a rosette of pores')
        K.mass('Spore gland %d' % (i + 1), _bpy.data.objects['G%d_turn_flesh' % (i + 1)], 'flesh sac', note='hanging on its neck under the belly')

    # ---------------- brood sacs: the hangar (hangar 3) ----------------
    for i, (x, r, th) in enumerate(SACS):
        for side in (1, -1):
            sn = 'p' if side > 0 else 's'
            pos, nrm = K.hpt(x, side_th(th, side), out=-0.05)
            # the sac hangs: its axis leans from the flank's normal toward straight down, so from above only its curve shows
            hang = (Vector(nrm) * 0.7 + Vector((0, 0, -0.9))).normalized()
            fid = 'B%d%s' % (i + 1, sn)
            part = HP.sac(r, h=r * 1.9, seed=40 + i * 2 + (side > 0), kind='brood', slit=0.55, glow=2, hang=1.45)
            K.organ(fid, part, pos, hang, fwd=(1, 0, 0), inv='brood_sacs', what='brood sac, %.1f across, birth slit' % (2 * r),
                    note='brood sac on the lower flank: the spore swarms grow in it and are born through the slit', aperture=(2.0, 0.0))
            K.mass('Brood sac %d (%s)' % (i + 1, 'port' if side > 0 else 'starboard'), _bpy.data.objects['%s_mount_flesh' % fid], 'flesh sac',
                   note='bulging out and down from the lower flank')

    # ---------------- siphons (attitude) ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        pos, nrm = K.hpt(8.6, side_th(-0.45, side), out=-0.03)
        K.thruster('Q1' + sn, tuple(pos), tuple(nrm), r=0.3, inv='siphons', note='siphon behind the mouth: swings the head')
        pos, nrm = K.hpt(-7.4, side_th(0.55, side), out=-0.03)
        K.thruster('Q2' + sn, tuple(pos), tuple(nrm), r=0.26, inv='siphons', note='siphon on the tail: swings the stern')

    # ---------------- the vent crown (engines) ----------------
    for fid, y, z, r, nt, od, sd in (('E1', 0.0, 0.82, 0.18, 3, (0, 0, 1), 1), ('E2', 0.3, 0.42, 0.14, 2, (0, 1, -0.6), 2), ('E3', -0.3, 0.42, 0.14, 2, (0, -1, -0.6), 3)):
        K.engine(fid, (-10.45, y, z), r, 1.0, bell=1.0, body_r=r * 1.35, inv='vents', src='picture',
                 kw=dict(trail='membrane', trails=nt, trail_len=3.5, out_dir=od, seed=sd),
                 note='pulse vent with %d trailing membrane veils, splayed away from the crown\'s centre' % nt)
    K.mass('Vent crown', _bpy.data.objects['E1_mount_flesh'], 'flesh', note='three pulse vents at the tail\'s end')

    # ---------------- grown detail on the hull ----------------
    import random
    rnd = random.Random(623)
    # the flank fold: a raised fold of membrane running down each flank from behind the head to the tail (the picture's long
    # ridge), with height, wandering, its edge armoured with ochre chitin (round 3: "give it a real fold with height")
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        xs = [8.2 - 0.25 * k for k in range(66)]
        rings = []; edge = []
        for k, x in enumerate(xs):
            f = k / (len(xs) - 1)
            thx = 0.04 + 0.05 * math.sin(x * 0.45 + 0.5) + 0.02 * math.sin(x * 1.3)   # on the widest line, like a ray's edge
            b, nrm = K.hpt(x, side_th(thx, side), out=-0.05)
            b2 = K.hpt(x - 0.05, side_th(thx, side), out=-0.05)[0]
            tang = (b2 - b).normalized(); nrm = Vector(nrm)
            d = (nrm * 0.95 + Vector((0, 0, 0.08))).normalized()   # it stands straight out from the widest line
            sv = tang.cross(d).normalized()
            env = math.sin(math.pi * min(1.0, f * 1.15)) ** 0.5
            hgt = (0.12 + 0.5 * env) * (1 + 0.15 * math.sin(x * 2.3 + side))
            w = 0.34 * (0.6 + 0.4 * env)
            tip = b + d * hgt + sv * 0.04 * math.sin(x * 3.1)
            rings.append([b - sv * w / 2, b + d * hgt * 0.45 - sv * w * 0.32, tip - sv * 0.03, tip + sv * 0.03, b + d * hgt * 0.45 + sv * w * 0.32, b + sv * w / 2])
            edge.append(tip + d * 0.02)
        V = [tuple(q) for r_ in rings for q in r_]; n_ = 6; F = []
        for j in range(len(rings) - 1):
            for q in range(n_):
                a_, b_ = j * n_ + q, j * n_ + (q + 1) % n_
                F.append((a_, b_, b_ + n_, a_ + n_))
        F.append(tuple(range(n_))[::-1]); F.append(tuple(range((len(rings) - 1) * n_, len(rings) * n_)))
        fold = K.hull_detail('flank_fold_' + sn, (V, F), 'flesh2', inv='flank_fold', kind='welt', subs=['welt'])
        K.hull_detail('flank_fold_edge_' + sn, HP.tube(edge, [0.045] * len(edge), n=6), 'chitin')
        K.mass('Flank fold (%s)' % ('port' if side > 0 else 'starboard'), fold, 'flesh fold, ochre edge', note='the raised membrane fold down the flank')
    # the head folds: heavy fold rolls running back from the mouths over the head, converging into the shoulders (the
    # picture's coiled bow: the folds reach about a fifth of the length back)
    for side in (1, -1):
        V, F = [], []
        for k, th0 in enumerate((-0.75, -0.35, 0.05, 0.42, 0.78, 1.12, 1.42)):
            pts = []; nrms = []; ws = []; hs = []
            for j in range(12):
                t = j / 11
                x = 11.9 - 4.2 * t * (0.85 + 0.15 * math.sin(k * 1.7))
                th = th0 + (0.62 - th0) * t ** 1.4 * 0.55 + 0.05 * math.sin(j * 0.9 + k)
                p_, n_ = K.hpt(x, side_th(th, side), out=-0.02); pts.append(p_); nrms.append(n_)
                ws.append((0.62 * (1 - 0.75 * t) + 0.06) * (1 + 0.18 * math.sin(j * 1.9 + k))); hs.append((0.3 * (1 - 0.8 * t) + 0.03) * (1 + 0.25 * math.sin(j * 1.3 + 2 * k)))
            vv, ff = HP.welt(pts, nrms, ws, hs, n=7)
            o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
        hf = K.hull_detail('head_folds_%s' % ('p' if side > 0 else 's'), (V, F), 'flesh2' if side > 0 else 'flesh', inv='head_folds', kind='welt', subs=['welt'])
        K.mass('Head folds (%s)' % ('port' if side > 0 else 'starboard'), hf, 'flesh folds', note='fold rolls running back over the head')
    # pore fields: the head behind the mouths, round the vent crown
    for name, x0, x1, t0, t1, nper in (('head', 8.0, 11.3, -0.3, 1.45, 46), ('tail', -9.9, -7.7, -0.6, 1.5, 22)):
        V, F = [], []
        for side in (1, -1):
            for _ in range(nper):
                x = rnd.uniform(x0, x1); th = rnd.uniform(t0, t1)
                if name == 'head' and abs(x - 8.6) < 0.55 and abs(th + 0.45) < 0.3:
                    continue   # clear of the siphon
                pos, nrm = K.hpt(x, side_th(th, side), out=0.0)
                vv, ff = HP.pore(pos, nrm, rnd.uniform(0.035, 0.07))
                o = len(V); V += vv; F += [tuple(q + o for q in f) for f in ff]
        K.hull_detail('pores_' + name, (V, F), 'pore', inv='head_pores', kind='pore', subs=['rim', 'pit'])
    # veins: from the heart vat forward along the upper flank, dropping under the siphon to the throat glands, branches to the sacs
    for side in (1, -1):
        V, F = [], []

        def run(pts_xt, w):
            pts = []; nrms = []
            for x, th in pts_xt:
                p_, n_ = K.hpt(x, side_th(th, side), out=0.0); pts.append(p_); nrms.append(n_)
            vv, ff = HP.welt(pts, nrms, w, w * 0.5, n=5)
            o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
        main = [(x, -0.24 + 0.04 * math.sin(x * 1.3)) for x in [0.4 + 0.35 * k for k in range(19)]]
        main += [(7.0 + 0.35 * k, -0.24) for k in range(1, 4)]
        run(main, 0.1)
        for bx in (5.3, 2.2, -0.2):
            run([(bx + 0.25 * k, -0.24 - 0.1 * k) for k in range(5)], 0.06)
        run([(0.4 - 0.3 * k, -0.24 + 0.02 * k) for k in range(8)], 0.07)
        K.hull_detail('veins_%s' % ('p' if side > 0 else 's'), (V, F), 'vein', inv='veins', kind='vein', subs=['vein', 'branch'])
    # scars: regrowth patches with knit ridges
    for k, (x, th, r, side) in enumerate(((9.3, 1.15, 0.42, 1), (6.4, 1.45, 0.55, -1), (3.7, 0.95, 0.45, 1), (-0.4, 1.3, 0.5, -1), (-2.6, 0.38, 0.4, 1),
                                         (-4.6, 1.2, 0.48, -1), (-6.0, 0.5, 0.36, 1), (5.9, -0.15, 0.4, -1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.0)
        (pv, pf), (kv, kf) = HP.scar(pos, nrm, r, seed=k, knits=3)
        K.hull_detail('scar%d_patch' % k, (pv, pf), 'scar', inv='scars', kind='scar', subs=['patch', 'knit'])
        K.hull_detail('scar%d_knit' % k, (kv, kf), 'tissue')
    # tail folds: wrinkle welts converging on the vent crown
    V, F = [], []
    for k in range(10):
        th0 = -0.9 + 2 * math.pi * k / 10
        pts = []; nrms = []
        for j in range(8):
            x = -7.9 - 0.3 * j
            p_, n_ = K.hpt(x, th0 + 0.04 * j, out=0.0); pts.append(p_); nrms.append(n_)
        vv, ff = HP.welt(pts, nrms, 0.12, 0.06, n=5)
        o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
    K.hull_detail('tail_folds', (V, F), 'flesh2', inv='tail_folds', kind='welt', subs=['welt'])

    # ---------------- colour zones ----------------
    K.colour('dark olive flesh, callused olive hide (paint stage)', 14.0, -10.2, 'whole body')
    K.colour('ochre chitin', 8.2, -8.0, 'the edge of each flank fold')
    K.colour('bile yellow-green light', 14.0, 12.0, 'the throat glands, deep in the mouths')
    K.colour('bile yellow-green light', -10.2, -14.0, 'the vents and the light in the membranes')
    K.colour('dim bile', 10.6, 0.4, 'the veins, the sac windows, the acid pores')
    K.colour('pale regrowing scar', 9.3, -6.0, 'scar patches')

    # ---------- INSIDE: flesh, bone and organs (R98, R209; factions.md: "Inside: flesh and bone, wet and lit from within") ----------
    K.septum('lower', -0.9, 10.4, -1.4)
    K.septum('upper', 0.85, 10.2, -7.0)
    for i, x in enumerate((10.6, 8.9, 6.2, 4.4, 2.6, 0.8, -0.6, -2.5, -4.2, -5.4, -7.4, -8.8)):
        K.hoop('F%d' % i, x)
    K.organ_room('bile_gland_p', 'gland', (10.1, 1.0, -0.35), (0.85, 0.6, 0.6), note='the port throat\'s bile gland: the shot\'s magazine', seed=1)
    K.organ_room('bile_gland_s', 'gland', (10.1, -1.0, -0.35), (0.85, 0.6, 0.6), note='the starboard throat\'s bile gland', seed=2)
    K.organ_room('ganglion', 'ganglion', (8.3, 0.0, 0.75), (0.7, 0.55, 0.42), note='the Node: the knot of nerve that steers the body (no bridge)', seed=3)
    K.organ_room('regrowth_fore_p', 'organ', (6.8, 1.35, 0.95), (0.75, 0.42, 0.38), note='regrowth tissue: knits the hull back (regen)', seed=4)
    K.organ_room('regrowth_fore_s', 'organ', (6.8, -1.35, 0.95), (0.75, 0.42, 0.38), note='regrowth tissue', seed=5)
    K.organ_room('gut_fore', 'gut', (4.3, 0.0, 0.25), (1.9, 1.05, 0.7), note='the gut: it eats anything, wrecks and the dead included', seed=6)
    for i, (x, r, th) in enumerate(SACS):
        for side in (1, -1):
            K.organ_room('brood_chamber_%d%s' % (i + 1, 'p' if side > 0 else 's'), 'brood', (x, side * (0.95 - 0.12 * i), -0.75 + 0.18 * i),
                         (0.8 - 0.15 * i, 0.5 - 0.06 * i, 0.4 - 0.05 * i), note='brood chamber feeding the sac beside it (hangar 3)', seed=10 + i)
    for i, x in enumerate(GLANDS):
        zb = _k.sec_at(HULL, x)[3]
        K.organ_room('spore_store_%d' % (i + 1), 'gland', (x, 0.0, zb + 0.62), (0.55, 0.42, 0.3), note='spore store over the gland below', seed=20 + i)
    K.organ_room('tendril_muscle', 'organ', (1.7, 0.0, 1.0), (0.7, 0.6, 0.35), note='the crown\'s root muscle', seed=30)
    K.organ_room('heart_vat', 'vat', (0.1, 0.0, -0.05), (1.15, 0.9, 0.75), note='the heart vat: the core (hp_core), lit bile-green', seed=31)
    K.organ_room('gut_aft', 'gut', (-2.9, 0.0, 0.35), (1.6, 0.95, 0.65), note='the second stomach', seed=32)
    K.organ_room('regrowth_aft_p', 'organ', (-5.0, 0.52, 0.6), (0.55, 0.3, 0.28), note='regrowth tissue', seed=33)
    K.organ_room('regrowth_aft_s', 'organ', (-5.0, -0.52, 0.6), (0.55, 0.3, 0.28), note='regrowth tissue', seed=34)
    K.organ_room('pulse_bladder', 'engroom', (-7.8, 0.0, 0.62), (1.0, 0.4, 0.32), note='the pulse bladder: fills and squeezes the vents (the engine room)', seed=35)
    K.armour('head and mouth folds', 0.45, 'the thickest flesh: the folds close over the throats')
    K.armour('back and shoulders', 0.35, 'callused hide; the flank folds over the organs')
    K.armour('flanks and sacs', 0.25, 'thin over the brood sacs: they rupture first')
    K.armour('belly', 0.25, '')
    K.armour('tail', 0.2, '')
    K.break_line('B-1', 7.2, 'behind the head: the mouth mass tears away, opening the glands and the Node',
                 path=[(7.5, 2.7), (6.9, 1.6), (7.6, 0.6), (6.8, -0.5), (7.5, -1.5), (7.0, -2.7)])
    K.break_line('B-2', -1.6, 'behind the tendril crown: the body tears open across the heart vat\'s aft end and the second stomach',
                 path=[(-1.9, 2.6), (-1.45, 1.4), (-1.6, 0.0), (-1.4, -1.4), (-1.95, -2.6)])
    K.break_line('B-3', -6.4, 'ahead of the tail: the tail and the vent crown tear free, opening the pulse bladder',
                 path=[(-6.1, 1.6), (-6.7, 0.7), (-6.2, -0.2), (-6.6, -1.0), (-6.2, -1.6)])
    K.break_line('B-4', 0.0, 'the belly tears away along the brood sacs\' roots, the sacs bursting first (factions.md: sacs rupture first, then the body tears open)',
                 path=[(7.6, -1.0), (5.5, -0.75), (3.5, -1.0), (0.0, -0.75), (-3.5, -0.6), (-6.0, -0.3)], kind='long')
    K.inside.append(dict(kind='note', name='insides', note='Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, '
                                                          'membrane septa for decks, organs and chambers that never reach the skin. The Chorus bursts and tears: sacs rupture first, '
                                                          'then the body tears open along ragged lines (R186).'))
    K.point('core', 'hp_core', (0.1, 0.0, -0.05))
    # nine breach anchors (Bio-titan base 8, Chorus +1 on the big ones): prow 3, mid 3, engine 3, alternating sides, next to the sacs
    for i, (x, th, sec, side) in enumerate(((9.6, -0.35, 'prow', 1), (8.0, -0.45, 'prow', -1), (6.6, 0.95, 'prow', 1),
                                            (2.9, -0.15, 'mid', -1), (-1.0, -0.2, 'mid', 1), (-2.2, 0.85, 'mid', -1),
                                            (-5.6, -0.1, 'eng', 1), (-7.0, 0.9, 'eng', -1), (-8.6, -0.2, 'eng', 1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('breach', 'hp_breach_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd', section=sec, note='open hide beside a sac or the trim')
    for i, (x, th, side) in enumerate(((8.6, -0.45, 1), (8.6, -0.45, -1), (-7.4, 0.55, 1), (-7.4, 0.55, -1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('rcs', 'hp_rcs_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('Colour: bile yellow-green light over dark olive flesh and ochre chitin', 'R204 and the lore: the colour is fixed in the build; the picture came out grey with amber light (README 8b)')
    K.change('The two mouths are the two bile spitters (bioplasma F, F)', 'data.js b_boss carries two Spine volleys forward; a weapon is an organ (factions.md). Each throat gets an inner sphincter, a ring of chitin spines (the spines it spits) and its glowing bile gland; the picture shows only the glow')
    K.change('The tendril cluster is the boarding tendrils (tendril T), a crown on a muscle mound that turns', 'the slot is all round; the profile (the view of record for anatomy, README 8b) curls them up, the plan splays them flat; built as the profile with the tips splayed')
    K.change('The belly row is five spore glands (spores T) on necks, spouts forward', 'the picture\'s small hanging sacs; the last two moved about one unit aft so the B-2 seam passes behind the crown and between two glands (R226)')
    K.change('The big flank sacs are brood sacs, the hangar (hangar 3), with birth slits', 'the picture\'s crease on each sac becomes the slit the spore swarms are born through; a launch opening kept clear (fit check EXIT). They hang below the lower flank as heavy lobes on soft necks, so from above only their curve shows (the Board on PR 628)')
    K.change('The long ridge down each flank is a raised membrane fold with an ochre chitin edge', 'the picture\'s long flank ridge, given height; the lore\'s ochre chitin trim on its edge; it is also where the hide tears first')
    K.change('The tail ends in a crown of three pulse vents with trailing membranes', 'factions.md: no nozzles, pulsing vents or trailing membranes; the picture\'s spike with three or four glow points and long wisps. The membranes are about two thirds of the picture\'s wisps so the whole ship is 28.0, mouth to membrane tip')
    K.change('Siphons added, a pair behind the mouths and a pair on the tail', 'a ship in space must turn; the picture shows none; siphons, not nozzles')
    K.change('Pore fields on the head and round the tail, veins along the flanks', 'the Chorus has no eyes: it tastes (lore 5.8); the veins carry bile to the throats (README 8b: C9\'s vein tracery faded in this pass)')
    K.change('Scars carry knit ridges', 'regrowing scar tissue (lore 5.3; regen 20): the wound pulling shut')
    K.open_item('The belly between the sacs is designed here; the sheet has no underside view (its side view shows the belly row)')
    # fixes found by the fit check on the first full layout are listed by K.fix as they are made
