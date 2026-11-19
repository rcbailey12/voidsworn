# chorus_C13: the spitter, the Chorus destroyer (class Destroyer, 9.5 world units). Issue 1154, from the accepted concept of
# issue 631 (Ryan accepted it Nov 13 2026). Accepted pictures: contrib/muse/design/class_family_chorus_2026_11/
# chorus_C13_spitter_v7.jpg (beauty) and chorus_C13_spitter_sheet_v1.jpg (top, side and bow-on views, bow LEFT); designs.md
# governs where a picture differs.
# data.js b_spitter (Chorus spitter): bioplasma T, bioplasma F; ability regrow; regen 4; no shields; size 0.6.
# Designer of record: Opus (R205, R207). The concept guides; it is not traced. Built and judged from the WHOLE pictures first (R229).
# Read off the sheet (bow LEFT; about 125 px a unit on the top and side views): the body is 7.6 nose to vents, broad in the
# middle (widest at 55 percent), short at the tail, the trailing membranes on to the full 9.5; a rounded nose bulb with the
# prow gland in it; a lumpy back of knolls, two of them carrying vents; round bile sacs along the lower flanks and smaller
# sacs hanging under the belly. Length to beam 2.8 overall (C11 is 2.5, C10 5.2: the family's broad short hunter, smallest
# of the three).
# +X bow, +Y port, +Z up. Nose x = +4.75, vent mouths x = -2.95, membrane tips about x = -4.75.
import math

CODE = 'chorus_C13'
NAME = 'The spitter (Chorus destroyer)'
FACTION = 'The Chorus (chorus)'
CLASS = 'Destroyer'
LENGTH = 9.5
GAME = "data.js b_spitter (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5"
BEAUTY = 'contrib/muse/design/class_family_chorus_2026_11/chorus_C13_spitter_v7.jpg'
KIT = 'chorus'
CONCEPT_SHEET = 'contrib/muse/design/class_family_chorus_2026_11/chorus_C13_spitter_sheet_v1.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(20, 60, 1270, 660), largest=True, flip=False), side=dict(box=(20, 700, 1270, 1240), largest=True, flip=False))
CROPS = [('bow (the prow gland)', (100, 650, 1000, 1250)), ('midships (dorsal glands and sacs)', (550, 100, 1450, 1050)),
         ('stern (spine bed and membranes)', (1150, 30, 1920, 900))]
SHEET = dict(version=2, round='shaping pass v2 (issue 1154, the Board on v1)', date='2026-11-19', blend='opus1154\\chorus_C13',
             before='First full layout', before_note='The first complete C13 layout with the Chorus kit, run through the check before any fix.')

PEXP = (2.0, 1.85)    # round over the back, round in the belly: no flat faces (the family's rule from PR 628)
WOBBLE = (0.12, 3.4)  # lumpier than C11: the spitter is the scarred, asymmetric one
# (x, half-width port, half-width starboard, z bottom, z top): a rounded nose bulb, a slight waist behind it, broad in the
# middle, short at the tail; port a little fuller than starboard (asymmetric, as the picture)
KEY = [
    (4.4, 0.42, 0.41, -0.52, 0.12),
    (4.1, 0.68, 0.66, -0.72, 0.36),
    (3.5, 0.8, 0.76, -0.82, 0.52),
    (2.7, 1.0, 0.95, -0.97, 0.74),
    (1.7, 1.26, 1.2, -1.15, 1.02),
    (0.6, 1.42, 1.35, -1.28, 1.24),
    (-0.5, 1.45, 1.38, -1.3, 1.28),
    (-1.5, 1.3, 1.24, -1.2, 1.15),
    (-2.25, 0.98, 0.94, -0.92, 0.88),
    (-2.75, 0.66, 0.63, -0.62, 0.6),
    (-3.0, 0.45, 0.44, -0.42, 0.42),
]


def dense(key, step=0.32):
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
PL = dict(size=(0.3, 0.62), thick=(0.018, 0.04), skip=0.15, stack=0.0, mats={'flesh': 5, 'hide': 3, 'flesh2': 2, 'scar': 0.4},
          rivet_mat='pore', subs=['pad', 'pore'], rivets=True, rr=0.024)
# the glands: (id, slot, mouth point, aim, opening radius, knoll radius, spines)
GLAND_R = 0.25
GLANDS = (
    ('W1', 'F', (4.52, 0.02, 0.02), (0.92, 0.0, 0.38), 0.25, 0.5, 14),     # the prow gland, low in the nose bulb behind its round front
    ('W2', 'T', (1.75, 0.2, 1.48), (0.3, 0.12, 0.95), GLAND_R, 0.62, 16),  # the fore dorsal knoll
    ('W3', 'T', (-0.1, -0.26, 1.72), (0.0, -0.1, 0.99), GLAND_R, 0.68, 16),  # the great dorsal knoll amidships (aimed straight up: the stage 4 audit refuses a gun aimed backward)
)
# bile sacs on the lower flanks: (x, section angle, radius) per side; port and starboard differ (asymmetric)
SACS = {1: ((2.5, -0.55, 0.4), (1.2, -0.32, 0.7), (-0.45, -0.52, 0.68), (-1.85, -0.3, 0.48)),
        -1: ((2.3, -0.4, 0.44), (0.75, -0.58, 0.7), (-0.85, -0.32, 0.62), (-2.1, -0.6, 0.38))}
HANGING = ((1.85, 0.25, 0.38), (0.1, -0.22, 0.46), (-1.45, 0.25, 0.4))   # (x, y, radius): sacs hanging under the belly
VENTS = ((0.0, 0.18, 0.16), (0.36, -0.16, 0.14), (-0.36, -0.16, 0.14))  # (y, z, radius) at the stern


def build(K):
    import kit as _k
    from mathutils import Vector
    import bpy as _bpy
    import random
    HP = _k.HP
    rnd = random.Random(1154)

    hull = K.hull(HULL, 'flesh', shell=0.22, plates=dict(PL, seed=31, inv='hide'), rounded=True, pexp=PEXP, n=40, smooth=True, wobble=WOBBLE)
    K.mass('Hull: the broad lumpy body', hull, 'dark olive flesh', note='a rounded nose bulb, broad in the middle, short at the tail')
    K.mark('body', 'hull', ['ridge', 'fold', 'pore'])

    def side_th(th, side):
        return th if side > 0 else math.pi - th

    # ---------------- the spine glands (the two spine volleys) ----------------
    for fid, slot, mouth, aim, r, rk, ns in GLANDS:
        a = Vector(aim).normalized(); L_ = 0.95
        root = Vector(mouth) - a * L_
        what = ('the prow gland: a knoll grown into the nose bulb, a puckered vent at its crown, short spines round it; it spits forward' if slot == 'F' else
                'a dorsal spine gland: a puckered vent at the crown of a knoll on the back, short spines out of the knoll round it; it faces up and spits every way')
        K.spinal(fid, tuple(root), L_, r=r, slot=slot, weapon='bioplasma', inv='glands_f' if slot == 'F' else 'glands_t', style='gland', aim=tuple(a),
                 band=(-10, 0, 10, 20) if slot == 'F' else (20, 35, 50, 70), knoll=rk, spines=ns, seed=40 + int(fid[1:]), gland_at=0.5, note=what)
        K.mass('Spine gland %s' % fid, _bpy.data.objects['%s_mount_flesh' % fid], 'flesh knoll', note=what.split(':')[0])

    # ---------------- the spine bed (regrowth of spent spines) ----------------
    pos, nrm = K.hpt(-1.55, math.pi / 2 + 0.18, out=-0.12)
    K.organ('SB1', HP.spine_bed(0.58, spines=15, seed=7), pos, nrm, fwd=(1, 0, 0), inv='spine_bed', what='spine bed, 1.2 across',
            note='a knoll aft of the glands studded with growing spines: the spent spines regrow here (regrow, regen 4)')
    K.mass('Spine bed', _bpy.data.objects['SB1_mount_flesh'], 'flesh knoll', note='the knoll aft of the dorsal glands')
    # the lumps of the back and shoulders: knolls of grown flesh between the glands (the picture's lumpy mass)
    items = []
    for k, (x, th, rr) in enumerate(((2.9, 1.1, 0.55), (0.9, 2.0, 0.7), (-0.9, 0.95, 0.75), (-0.75, 2.3, 0.62), (2.55, 2.15, 0.5), (-2.0, 1.5, 0.5),
                                     (0.8, 0.55, 0.55), (-1.35, 2.75, 0.5), (3.4, 1.7, 0.38),
                                     (0.1, 0.3, 0.62), (-0.4, 2.85, 0.6))):   # the mid-body's side blisters bulge out (the Board on v2)
        pos, nrm = K.hpt(x, th, out=-rr * 0.5)
        items.append((HP.knoll(rr, seed=70 + k), HP.frame(pos, (1, 0, 0), nrm)))
    K.grown_hull('knolls', items, inv='knolls', kind='knoll')
    K.mass('Back and shoulder knolls', _bpy.data.objects['knolls_flesh'], 'flesh', note='lumps of grown flesh over the back and shoulders')

    # ---------------- the bile sacs (round, along the lower flanks) and the hanging sacs ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        for i, (x, th, rr) in enumerate(SACS[side]):
            pos, nrm = K.hpt(x, side_th(th, side), out=0.0)
            fid = 'S%d%s' % (i + 1, sn)
            K.organ(fid, HP.sac(rr, h=rr * 1.05, seed=60 + 2 * i + (side > 0), kind='sac', glow=1, rim=0.45), pos, nrm, fwd=(1, 0, 0), inv='bile_sacs',
                    what='bile sac, %.1f across' % (2 * rr), note='a round bile sac bulging from the lower flank; it swells before a volley')
            K.mass('Bile sac %d (%s)' % (i + 1, 'port' if side > 0 else 'starboard'), _bpy.data.objects['%s_mount_flesh' % fid], 'flesh dome')
    for a_, b_ in (('S1p', 'S2p'), ('S2p', 'S3p'), ('S3p', 'S4p'), ('S1s', 'S2s'), ('S2s', 'S3s'), ('S3s', 'S4s'), ('S2s', 'H2'), ('S2p', 'H1'), ('S3p', 'H3')):
        K.allow_touch(a_, b_, 'the bile sacs grow in a cluster along the flank, swelling into each other (the picture\'s merged sacs)')
    for i, (x, y, rr) in enumerate(HANGING):
        s = _k.sec_at(HULL, x); zb = s[3]
        th = -math.pi / 2 + (0.2 if y > 0 else -0.2)
        pos, nrm = K.hpt(x, th, out=-0.06)
        hang = (Vector(nrm) * 0.4 + Vector((0, 0, -1))).normalized()
        fid = 'H%d' % (i + 1)
        K.organ(fid, HP.sac(rr, h=rr * 1.35, seed=80 + i, kind='sac', glow=1, rim=0.45, hang=1.3), pos, hang, fwd=(1, 0, 0), inv='hanging_sacs',
                what='hanging sac, %.1f across' % (2 * rr), note='a bile sac hanging under the belly: the spitter\'s deep reserve')
        K.mass('Hanging sac %d' % (i + 1), _bpy.data.objects['%s_mount_flesh' % fid], 'flesh sac')

    # ---------------- siphons ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        pos, nrm = K.hpt(3.55, side_th(-0.15, side), out=-0.03)
        K.thruster('Q1' + sn, tuple(pos), tuple(nrm), r=0.17, inv='siphons', note='siphon behind the nose: swings the bow')
        pos, nrm = K.hpt(-2.45, side_th(0.35, side), out=-0.03)
        K.thruster('Q2' + sn, tuple(pos), tuple(nrm), r=0.15, inv='siphons', note='siphon aft: swings the stern')

    # ---------------- the vents and their trailing membranes (engines) ----------------
    for k, (y, z, r) in enumerate(VENTS):
        od = (0, 0.2, 1) if k == 0 else (0, 0.6 if y > 0 else -0.6, -0.8)
        K.engine('E%d' % (k + 1), (-3.25, y, z), r, 0.6, bell=1.0, body_r=r * 1.35, inv='vents', src='picture',
                 kw=dict(trail='veil', trails=2, trail_len=1.45, out_dir=od, seed=k + 3, veil=3.0, fan=0.785, splay=26.0),
                 note='pulse vent with two wide trailing veils, fanned away from the stern\'s centre')
    K.mass('Vents', _bpy.data.objects['E1_mount_flesh'], 'flesh', note='three pulse vents at the short stern')

    # ---------------- grown detail on the hull ----------------
    # pore fields: the nose bulb and the upper flanks
    for name, x0, x1, t0, t1, nper in (('nose', 3.0, 4.5, -0.3, 1.4, 55), ('flank', -2.2, 2.8, 0.1, 0.75, 45)):
        V, F = [], []
        for side in (1, -1):
            for _ in range(nper):
                x = rnd.uniform(x0, x1); th = rnd.uniform(t0, t1)
                if any(abs(x - sx) < 0.4 and abs(th - st) < 0.35 for sx, st in ((3.55, -0.15), (-2.45, 0.35))):
                    continue   # clear of the siphons
                pos, nrm = K.hpt(x, side_th(th, side), out=0.0)
                vv, ff = HP.pore(pos, nrm, rnd.uniform(0.018, 0.04), n=6)
                o = len(V); V += vv; F += [tuple(q + o for q in f) for f in ff]
        K.hull_detail('pores_' + name, (V, F), 'pore', inv='pore_fields', kind='pore', subs=['rim', 'pit'])
    # veins: from the flank sacs forward and up to the glands
    for side in (1, -1):
        V, F = [], []

        def run(pts_xt, w):
            pts = []; nrms = []
            for x, th in pts_xt:
                p_, n_ = K.hpt(x, side_th(th, side), out=0.0); pts.append(p_); nrms.append(n_)
            vv, ff = HP.welt(pts, nrms, w, w * 0.5, n=5)
            o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
        run([(2.1 + 0.2 * k, -0.3 + 0.03 * k) for k in range(6)], 0.07)
        run([(-1.9 + 0.32 * k, -0.05 + 0.04 * math.sin(k)) for k in range(13)] + [(2.3 + 0.2 * k, 0.05 + 0.13 * k) for k in range(1, 5)], 0.06)
        K.hull_detail('veins_%s' % ('p' if side > 0 else 's'), (V, F), 'vein', inv='veins', kind='vein', subs=['vein', 'branch'])
    # skin folds: broken runs swept back from the nose, wrapping the knolls (the picture's wrinkled flesh)
    V, F = [], []
    for side in (1, -1):
        for k in range(34):
            th0 = rnd.choice((rnd.uniform(0.05, 1.3), rnd.uniform(-1.25, -0.75)))
            xa = rnd.uniform(-1.6, 4.4); ln = rnd.uniform(1.6, 3.6)
            pts = []; nrms = []; ws = []; hs = []
            for j in range(10):
                t = j / 9
                x = xa - ln * t
                if x < -2.6 or any(abs(x - sx) < 0.45 and abs(th0 - st) < 0.4 for sx, st in ((3.55, -0.15), (-2.45, 0.35))) or \
                        any(abs(x - sx) < sr * 1.15 and abs(th0 - st) < 0.45 for sx, st, sr in SACS[side]):
                    break   # stop short of the siphons and the flank sacs
                th = th0 + 0.03 * math.sin(j * 1.1 + k) + (0.06 * t if th0 > 0 else -0.04 * t)
                p_, n_ = K.hpt(x, side_th(th, side), out=-0.015); pts.append(p_); nrms.append(n_)
                env = math.sin(math.pi * (0.08 + 0.84 * t))
                ws.append(0.36 * env + 0.04); hs.append(0.12 * env + 0.01)
            if len(pts) < 4:
                continue
            vv, ff = HP.welt(pts, nrms, ws, hs, n=5)
            o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
    K.hull_detail('skin_folds', (V, F), 'flesh2', inv='skin_folds', kind='welt', subs=['welt'])
    # regrown hide: ragged scar patches on the shoulders and flanks (regen 4)
    for k, (x, th, r, side) in enumerate(((2.9, 0.95, 0.34, 1), (1.6, 0.85, 0.4, -1), (-0.4, 0.7, 0.36, 1), (-1.8, 0.95, 0.3, -1), (0.9, -0.2, 0.28, 1),
                                          (3.0, 0.5, 0.24, -1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.0)
        (pv, pf), (kv, kf) = HP.scar(pos, nrm, r, seed=20 + k, knits=3)
        K.hull_detail('scar%d_patch' % k, (pv, pf), 'scar', inv='scars', kind='scar', subs=['patch', 'knit'])
        K.hull_detail('scar%d_knit' % k, (kv, kf), 'tissue')

    # ---------------- colour zones ----------------
    K.colour('dark olive flesh, callused olive hide (paint stage)', 4.75, -2.95, 'whole body')
    K.colour('pale ochre bone', 4.7, -2.0, 'the spines of the glands and the spine bed')
    K.colour('raw transition tissue', 4.7, -2.0, 'the vent lips and the spine collars')
    K.colour('bile yellow-green light', 4.7, 0.0, 'deep in the three gland vents')
    K.colour('bile yellow-green light', -2.95, -4.75, 'the vents and the membranes\' roots')
    K.colour('dim bile', 3.0, -2.5, 'the veins, the sac windows, the pores')

    # ---------- INSIDE: flesh, bone and organs ----------
    K.septum('lower', -0.75, 4.1, -2.5)
    K.septum('upper', 0.55, 3.6, -2.4)
    for i, x in enumerate((4.05, 3.35, 2.6, 1.8, 0.95, 0.1, -0.75, -1.6, -2.35)):
        K.hoop('F%d' % i, x)
    K.organ_room('spine_sac_f', 'gland', (3.7, 0.0, -0.1), (0.5, 0.42, 0.36), note='the prow gland\'s spine sac and bile gland: the forward volley\'s magazine', seed=1)
    K.organ_room('spine_sac_t1', 'gland', (2.0, 0.15, 0.95), (0.42, 0.38, 0.28), note='the fore dorsal gland\'s spine sac', seed=2)
    K.organ_room('spine_sac_t2', 'gland', (0.3, -0.2, 1.05), (0.48, 0.42, 0.25), note='the great dorsal gland\'s spine sac', seed=3)
    K.organ_room('ganglion', 'ganglion', (2.9, 0.0, 0.25), (0.42, 0.35, 0.28), note='the Node: the knot of nerve that aims the glands', seed=4)
    K.organ_room('heart_vat', 'vat', (0.7, 0.0, 0.05), (0.75, 0.6, 0.5), note='the heart vat: the core (hp_core), lit bile-green', seed=5)
    K.organ_room('bile_main', 'gland', (1.1, 0.0, -0.8), (1.1, 0.75, 0.35), note='the main bile store, fed by the flank sacs', seed=6)
    for i, (x, sg) in enumerate(((1.0, 1), (-0.75, 1), (0.7, -1), (-1.0, -1))):
        K.organ_room('bile_store_%d' % i, 'gland', (x, sg * 1.0, -0.55), (0.42, 0.32, 0.3), note='the bile store behind a flank sac', seed=10 + i)
    K.organ_room('gut', 'gut', (-0.6, 0.0, -0.3), (1.0, 0.7, 0.45), note='the gut', seed=20)
    K.organ_room('regrowth_p', 'organ', (-1.5, 0.75, 0.45), (0.42, 0.32, 0.26), note='regrowth tissue (regen 4)', seed=21)
    K.organ_room('regrowth_s', 'organ', (-1.5, -0.75, 0.45), (0.42, 0.32, 0.26), note='regrowth tissue', seed=22)
    K.organ_room('pulse_bladder', 'engroom', (-2.25, 0.0, 0.0), (0.45, 0.42, 0.36), note='the pulse bladder: fills and squeezes the three vents (the engine room)', seed=23)
    K.armour('nose bulb and prow gland', 0.32, 'the thickest flesh, over the prow gland\'s root')
    K.armour('back (the dorsal knolls)', 0.28, 'knoll flesh over the spine sacs')
    K.armour('flanks and sacs', 0.2, 'thin over the sacs: they rupture first')
    K.armour('belly', 0.2, '')
    K.armour('stern', 0.18, '')
    # two break lines (Destroyer: 2), torn by the Chorus rule: sacs rupture first, then the body tears open on ragged lines
    K.break_line('B-1', 3.0, 'behind the nose bulb: the prow gland and the nose tear away, opening the spine sac and the Node',
                 path=[(3.3, 6.0), (3.3, 2.2), (2.8, 1.2), (3.2, 0.3), (2.75, -0.7), (3.15, -1.6), (2.85, -6.0)])
    K.break_line('B-2', -1.3, 'behind the great dorsal knoll: the stern tears away through the gut and the regrowth tissue, the aft sacs bursting first',
                 path=[(-1.1, 6.0), (-1.1, 2.4), (-1.55, 1.3), (-1.15, 0.3), (-1.6, -0.8), (-1.2, -2.3), (-1.2, -6.0)])   # 0.35 aft of v2: the stage 4 audit found the great gland W3 across it
    K.inside.append(dict(kind='note', name='insides', note='Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, '
                                                          'membrane septa for decks, organs and chambers that never reach the skin. The Chorus bursts and tears: sacs rupture first, '
                                                          'then the body tears open along ragged lines (R186).'))
    K.point('core', 'hp_core', (0.7, 0.0, 0.05))
    # three breach anchors (Destroyer base 3; the Chorus extra is for the big ones only): prow, mid, engine, alternating sides
    for i, (x, th, sec, side) in enumerate(((3.6, 0.2, 'prow', 1), (0.5, -0.1, 'mid', -1), (-2.0, 0.15, 'eng', 1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('breach', 'hp_breach_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd', section=sec, note='open hide between the sacs')
    for i, (x, th, side) in enumerate(((3.55, -0.15, 1), (3.55, -0.15, -1), (-2.45, 0.35, 1), (-2.45, 0.35, -1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('rcs', 'hp_rcs_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')
    # boarding origins (export7: one port, one starboard on the mid hull): where a boarding party leaves the body
    for i, side in enumerate((1, -1)):
        pos, nrm = K.hpt(1.3, side_th(0.45, side), out=0.02)
        K.point('board', 'hp_board_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('Colour: bile yellow-green light over dark olive flesh, pale ochre bone', 'R204 and the lore: the colour is fixed in the build; the picture\'s hide is grey-brown with amber light')
    K.change('Three spine glands: one in the nose bulb (bioplasma F) and two on the dorsal knolls (both mounts of bioplasma T)',
             'data.js b_spitter has two bioplasma slots; the picture shows three vents (nose, fore knoll, great knoll). The two dorsal vents share the all-round slot, '
             'two muzzles for its two shots, so each fires on every volley (R241 SPLIT)')
    K.change('The dorsal glands are fixed organs facing up, not turrets', 'the slot is all round (T); a vent at the crown of a knoll spits every way at once, as C11\'s mane reaches '
             'every way (the Board\'s reading of R241 for organs, weapon_match FITS bioplasma: fixed)')
    K.change('Spines only round the three vents and on one spine bed aft of them; the long quills at the stern quarter and under the stern are cut',
             'every part has a job (R221): the spines round a vent are the shot it spits, the bed regrows them; the stern quills had none and would sit in the vents\' wash')
    K.change('Bile sacs: four a side along the lower flank, port and starboard at different sizes, three more hanging under the belly',
             'the picture\'s round sacs; uneven sides keep the asymmetric, scarred read (designs.md); every sac stores bile for the volleys')
    K.change('Three pulse vents with two wide veils each at the short stern (the kit\'s veil trail, shared with C12, R333)', 'factions.md: no nozzles; the picture\'s three glow points and ragged membranes. The veils are cut '
             'to about 1.4 so the ship is 9.5 nose to veil tip, and fanned so none hangs in a neighbour\'s jet')
    K.change('Siphons added, a pair forward and a pair aft', 'a ship in space must turn; the picture shows none')
    K.change('Boarding origins on the upper flanks at x 1.3, though b_spitter carries no tendril', 'the export contract needs one boarding origin a side on every ship (check_export.py); the stinger variant (b_spitter_s, tendril T) is its own job')
    K.open_item('The variant b_spitter_s (Spitter stinger: bioplasma T, tendril T) is not built here; it needs a named variant (ships.md, issue 812)')
