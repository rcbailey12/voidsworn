# chorus_C10: The Ninefold Maw, the Chorus flagship (class Bio-titan, 28.0 world units). Issue 623, the Chorus build sheets.
# Accepted picture: contrib/muse/design/concept_round8b_2026_11/chorus_C10_beauty.jpg and _sheet.jpg (R204).
# data.js b_boss: bioplasma F, bioplasma F, tendril T, spores T; hangar 3 (ability launch: spore swarms); regen 20; no shields.
# Designer of record: Opus (R205, R207). The concept guides; it is not traced. Built and judged from the WHOLE pictures first (R229).
# Measured off the round 8b sheet's true views (bow LEFT in both; side view 59.3 px a unit, plan 58.7, the mouth's front to the
# tail's end 24.6 units, the membranes trail on to the full 28.0): the head and mouth mass 4.9 wide and 3.9 tall, the body
# 4.7 wide and 3.7 deep through the middle, tapering from 60 percent to a tail that rises toward the back line; three big sacs
# a side on the lower flanks (2.9, 2.2 and 1.7 across), five small sacs hanging on necks under the belly (three built, R241), the tendril crown at
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
SHEET = dict(version=7, round='uneven folded flesh lips (issue 921 run 2, R306)', date='2026-11-17', blend='issue921\\chorus_C10',
             blend_where='Rebuild from tools/blender/build_sheets/ships/chorus_C10.py on CPU; current checks are in issue921_proof.json',
             before='Main 51ec81bb; run 1 8e9def50', before_note='Main and run 1 rebuilt on this PC at the same cameras and light.')

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
# issue 1291 (R349): the armadillo shell covers the body from behind the head to the tail, so only the head's scar stays
SCARS = ((10.6, 1.0, 0.36, 1),)   # on the head, ahead of the bands (Ryan Nov 20: armour almost everywhere)


def skin_sections():
    """Subdivide the original loft without changing its section curve or insides."""
    out = []
    for a, b in zip(HULL, HULL[1:]):
        n = max(1, math.ceil((a[0] - b[0]) / 0.1))
        out.extend(tuple(u + (v - u) * k / n for u, v in zip(a, b)) for k in range(n))
    return out + [HULL[-1]]


def flesh_relief(x, th):
    """Continuous folded hide, not a layer of pads. Lengthwise tension wrinkles
    sweep into the shoulders and sag round the brood sacs. These are geometry;
    pore grain, colour, wetness and fine scar mottling belong to the future stack.
    Keep the folds shallow at the widest line so the accepted outline carries.
    """
    side = abs(math.cos(th))
    flank = side ** 0.7
    phase = 23 * th + 0.6 * x + 1.7 * math.sin(x * 0.8 + 6 * th) + 0.5 * math.sin(1.9 * x - 9 * th)
    long_fold = (0.5 + 0.5 * math.sin(phase)) ** 4
    fine_fold = 0.14 * math.sin(45 * th + 1.8 * x + 2 * math.sin(phase * 0.4))
    strength = (0.075 + 0.10 * flank) * min(1.0, max(0.15, (x + 10.2) / 3))
    # Leave both pairs of siphons' embedded collars clear of the new folds.
    angle = math.atan2(math.sin(th), abs(math.cos(th)))
    clear = 1 - math.exp(-((x + 7.4) / 0.65) ** 2 - ((angle - 0.55) / 0.3) ** 2)
    clear *= 1 - math.exp(-((x - 8.6) / 0.7) ** 2 - ((angle + 0.45) / 0.35) ** 2)
    relief = clear * strength * (long_fold + fine_fold - 0.12)
    for sx, st, sr, ss in SCARS:
        angle = th - (st if ss > 0 else math.pi - st)
        angle = math.atan2(math.sin(angle), math.cos(angle))
        u = (x - sx) / (sr * 1.35)
        v = (2.5 * angle - 0.06 * math.sin(u * 4)) / 0.075
        relief -= 0.075 * math.exp(-u ** 6 - v * v)
    return relief


def open_maw(HP, seed):
    """C10's held-open folded mouth, assembled from the Chorus throat anatomy.
    The bespoke lip replaces the closing coils; the bore and working organs keep
    their kit roles. No mesh spans the opening in front of the recessed gland.
    """
    from mathutils import Vector
    L, r = 2.65, 1.3
    part = HP.spinal(L, r=r, style='folded', rolls=0, teeth=9, gland_at=0.38, seg=48, seed=seed)
    part.comps = [c for c in part.comps if c['name'] not in ('root', 'lip0') and not c['name'].startswith('bore')]
    # Continuous, slightly wrinkled wall from the opening back to the muscle root.
    V, F = HP.revolve([(-0.7, 1.6), (0, 1.78), (0.8, 1.7), (1.6, 1.55), (L - 0.25, 1.44),
                       (L - 0.12, 1.32), (L - 0.23, 1.22)], 96)
    V = [(x + 0.035 * math.sin(5 * math.atan2(z, y) + 2 * x),
          y * (1 + 0.055 * math.sin(17 * math.atan2(z, y) + 2.7 * x)),
          z * (1 + 0.055 * math.sin(17 * math.atan2(z, y) + 2.7 * x))) for x, y, z in V]
    part.add('root', 'mount', 'flesh', (V, F))
    # One continuous funnel, with material bands sharing vertices at their ends.
    # No overlapping bore liners, struts across the opening or luminous front cap.
    for mat_, lo, hi in (('tissue', 0, 0.4), ('bilewet', 0.4, 0.7), ('gland', 0.7, 1)):
        V, F = [], []
        for j in range(13):
            t = lo + (hi - lo) * j / 12
            x = (L - 0.23) * (1 - t) + L * 0.38 * t
            for k in range(96):
                a = 2 * math.pi * k / 96
                rr = (1.22 * (1 - t) + 0.78 * t) * (1 + 0.045 * math.sin(13 * a + t * 5 + seed) * math.sin(math.pi * t))
                V.append((x + 0.035 * math.sin(5 * a + 2 * x) * (1 - t), rr * math.cos(a), rr * math.sin(a)))
        for j in range(12):
            for k in range(96):
                a, b = j * 96 + k, j * 96 + (k + 1) % 96
                F.append((a, b, b + 96, a + 96))
        part.add('bore_' + mat_, 'mount', mat_, (V, F))
    # A continuous cheek-to-throat sheet, rather than a tube round the mouth.
    # Its back edge is buried in the existing cheek and its inner edge meets the
    # unchanged bore. Broad unequal gathers make the upper lip and jowls heavy;
    # the lower lip stays thinner. There is no repeated cross-rim rib geometry.
    def bump(a, centre, width):
        delta = math.atan2(math.sin(a - centre), math.cos(a - centre))
        return math.exp(-(delta / width) ** 2)

    phase = 0.43 if seed == 3 else -0.62
    V, F = [], []
    bands = 48
    around = 160
    for j in range(bands + 1):
        t = j / bands
        # The roll turns back into the mouth after its forward crest.
        xx = 0.66 + 2.05 * math.sin(t * math.pi * 0.67)
        rr = 1.7 - 0.48 * t + 0.20 * math.sin(math.pi * t)
        env = math.sin(math.pi * t) ** 1.1
        for k in range(around):
            a = 2 * math.pi * k / around
            hood = bump(a, 1.4 + phase * 0.4, 0.8)
            cheek = bump(a, 0.08 + phase, 0.55) + 0.75 * bump(a, 2.95 + phase * 0.4, 0.65)
            gather = (0.24 * hood + 0.13 * cheek + 0.055 * math.sin(3 * a + phase)
                      + 0.035 * math.sin(7 * a + 2 * phase)) * env
            # Unequal sweeping furrows run back into the cheek. They are valleys
            # in the flesh itself, not small bars laid across a circular tyre.
            furrow = sum(depth * bump(a, centre + bend * t + 0.08 * math.sin(7 * t + centre), width)
                         for centre, bend, width, depth in
                         ((0.24 + phase, 0.9, 0.055, 0.08), (1.0 - phase * 0.3, -0.6, 0.075, 0.12),
                          (2.0 + phase, 0.7, 0.09, 0.10), (3.2 - phase, -0.8, 0.065, 0.08),
                          (4.4 + phase * 0.4, 0.5, 0.08, 0.06), (5.7 - phase, -0.65, 0.06, 0.09)))
            ripple = 0.025 * math.sin(13 * a + 5 * t + 1.7 * math.sin(4 * a + phase))
            radius = rr + gather - env * furrow + env * ripple
            x = xx + env * (0.17 * hood + 0.11 * cheek + 0.08 * math.sin(3 * a + phase) - furrow)
            # Exact run 1 funnel join at t=1, so the depth and throat are kept.
            x += t ** 10 * ((L - 0.23) - (0.66 + 2.05 * math.sin(math.pi * 0.67)))
            x += 0.035 * math.sin(5 * a + 2 * x) * t ** 10
            V.append((x, radius * math.cos(a), radius * math.sin(a)))
    for j in range(bands):
        for k in range(around):
            a, b = j * around + k, j * around + (k + 1) % around
            F.append((a, b, b + around, a + around))
    part.add('lip_fold', 'body', 'flesh', (V, F))

    # Wide overlapping lappets: a top hood, one split side fold, an oblique
    # smaller hood and a low sag. Each dies into the cheek at both ends. The two
    # mouths have separate layouts, not mirrored or equally spaced segments.
    folds = (((-0.15, 2.75, 0.41, 0.22, 0.1), (2.15, 4.1, 0.34, -0.04, -0.4),
              (0.45, 1.9, 0.28, -0.32, 0.5), (4.0, 5.65, 0.23, 0.05, 0.2))
             if seed == 3 else
             ((0.3, 2.5, 0.48, 0.08, -0.3), (-1.4, 0.85, 0.35, -0.14, 0.4),
              (1.75, 3.5, 0.26, -0.35, -0.2), (3.45, 5.05, 0.21, 0.02, -0.5)))
    for fi, (start, end, width, setback, sweep) in enumerate(folds):
        V, F = [], []
        steps, cross = 80, 16
        for j in range(steps + 1):
            t = j / steps
            a = start + (end - start) * t
            taper = math.sin(math.pi * t) ** 0.65
            radius = 1.57 + 0.16 * math.sin(a + phase) + 0.10 * math.sin(2.3 * a + fi)
            if fi == 2:
                radius += 0.28  # a second hood lies outside and behind the first
            centre_x = 1.05 + 1.54 * taper + setback * taper
            # Ends descend into the cheek. The crest wanders inward and curls
            # back down toward the open funnel, making a loose drape of tissue.
            radius = 1.60 * (1 - taper) + radius * taper + sweep * 0.12 * math.sin(math.pi * t)
            for k in range(cross):
                q = 2 * math.pi * k / cross
                w = width * taper * (1 + 0.15 * math.sin(5 * a + phase)) + 0.008
                furrows = (0.018 * math.sin(19 * a + 1.2 * math.sin(4 * a + fi) + 2 * q)
                           + 0.012 * math.sin(31 * a - 3 * q + phase)) * taper
                rlocal = radius + (w + furrows) * math.cos(q)
                x = centre_x + (w * 0.9 + furrows) * math.sin(q) + 0.055 * taper * math.sin(7 * a + fi)
                V.append((x, rlocal * math.cos(a), rlocal * math.sin(a)))
        for j in range(steps):
            for k in range(cross):
                a, b = j * cross + k, j * cross + (k + 1) % cross
                F.append((a, b, b + cross, a + cross))
        F.extend((tuple(range(cross))[::-1], tuple(range(steps * cross, (steps + 1) * cross))))
        part.add('lip_lappet%d' % fi, 'body', 'flesh', (V, F))
    for c in part.comps:
        if c['name'].startswith('tooth'):
            # Spines sit against the wall, leaving the centre of the maw open.
            for v in c['verts']:
                rr = math.hypot(v.y, v.z)
                if rr:
                    v.y *= (rr + 0.24) / rr
                    v.z *= (rr + 0.24) / rr
        if c['name'] == 'gland':
            c['mat'] = 'gland'  # the broad gland has readable flesh, with a small hot centre
            for v in c['verts']:
                v.x += 0.11 * math.sin(8 * v.y + seed) * math.cos(9 * v.z - seed)
    part.add('gland_core', 'mount', 'bile', HP.blob(0.12, 0.25, 0.23, centre=(L * 0.38 + 0.24, 0, 0), seed=seed, amp=0.16))
    part.fit['radius'] = 1.65
    return part

GLANDS = (4.9, 0.2, -5.1)                      # the spore glands' stations under the belly (R241, issue 676: three, one pore-muzzle each)
SACS = ((5.06, 1.25, -0.8), (0.34, 1.0, -0.82), (-3.6, 0.75, -0.8))   # brood sacs: station, radius, section angle (port) where the neck grows out   # brood sacs: station, radius, section angle (port)


def build(K):
    import kit as _k
    from mathutils import Vector, Matrix
    import sys
    if _k._KITS not in sys.path:
        sys.path.append(_k._KITS)
    from chorus import plates, body
    HP = _k.HP

    # issue 1291 (R349, C13 round G accepted Nov 20): lumpy fused swellings grown into the skin behind the head (body.field), calm
    # round every organ's foot (the organs keep the original surface), the folds faded under the armadillo shell
    def mirror(spots):
        return [(x, t, r) for (x, t0, r) in spots for t in (t0, math.pi - t0)]
    calm = mirror([(1.7, math.pi / 2, 1.6), (8.6, -0.45, 0.9), (-7.4, 0.55, 0.9)])
    calm += [(x, -math.pi / 2, 1.3) for x in GLANDS]
    calm += mirror([(x, th, r * 1.5) for (x, r, th) in SACS])
    calm += [(-9.6, t, 1.3) for t in (0.0, math.pi / 2, math.pi, -math.pi / 2)]
    swell = body.field(921, 9.4, -8.9, swell=34, folds=40, wrinkles=200, sweeps=56, depth=0.3, height=(0.2, 0.45),
                       size=(1.0, 2.0), keep=calm, shell=(9.6, -8.6, plates.WRAP))

    # The loft and its grown folds read the same relief. Working organs and inside
    # anatomy retain the original surface datum. No other Chorus sheet changes.
    body_wobble = K.wob
    K.wob = lambda x, th: body_wobble(x, th) + flesh_relief(x, th) + swell(x, th)
    hull = K.hull(skin_sections(), 'flesh', shell=0.3, rounded=True, pexp=PEXP, n=192, smooth=True, wobble=WOBBLE)
    K.hull_sections = HULL
    relief_wobble = K.wob
    K.wob = body_wobble  # preserve the existing organs and their mounts exactly
    K.mass('Hull: the long body', hull, 'dark olive flesh', note='broad flat back, rounder belly, tapering to a tail that rises to the back line')
    K.mark('body', 'hull', ['ridge', 'fold', 'pore'])
    K.mark('hide', 'hull', ['ridge', 'fold', 'pore'])

    def side_th(th, side):
        return th if side > 0 else math.pi - th

    # ---------------- the double mouth: two bile spitters (bioplasma F, F) ----------------
    for i, side in enumerate((1, -1)):
        fid = 'M%d' % (i + 1)
        maw = open_maw(HP, 3 + i)
        K.gun(fid, (11.27, 1.45 * side, -0.3), 0, 0, barrels=1, cal=2 * maw.fit['bore'], fixed=True,
                 part=maw, slot='F', weapon='bioplasma', inv='throats',
                 note='%s great open round maw: an outward rolled lip, open sphincter, recessed spines and a bile gland 1.6 units down the wet throat'
                      % ('port' if side > 0 else 'starboard'))
        K.features[-1].update(fixed=True, route='hand-built', what='spine volley, held-open round maw (fixed)')
    K.allow_touch('M1', 'M2', 'the outer lips share a narrow flesh bridge; both round throat voids stay open')
    import bpy as _bpy
    # Register both forward lanes from the actual foremost lip, clear of the
    # shared flesh bridge. Their width includes the whole mouth opening.
    mouth_front = max((ob.matrix_world @ v.co).x for ob in K.coll.objects
                      if ob.type == 'MESH' and ob.get('grp') in ('M1', 'M2') for v in ob.data.vertices)
    for fd in K.fitdata:
        if fd['id'] in ('M1', 'M2'):
            fd['lanes'] = [dict(apex=(mouth_front + 0.02, fd['ring'][1], fd['ring'][2]), dir=(1, 0, 0),
                                u=(0, 1, 0), w=(0, 0, 1), hu=1.3, hw=1.3, half=4.0, length=LENGTH * 0.8, what='firing lane')]
    K.mass('Mouth, port throat', _bpy.data.objects['M1_mount_flesh'], 'flesh folds', note='the port lobe of the double mouth')
    K.mass('Mouth, starboard throat', _bpy.data.objects['M2_mount_flesh'], 'flesh folds', note='the starboard lobe')

    # ---------------- the tendril crown (tendril T) ----------------
    K.gun('T1', (1.7, 0.0, K.deck_z(1.7, 0.0) - 0.06), 0, 0, barrels=3, cal=0.17, blen=3.7, size=1.07, slot='T', weapon='tendril', inv='crown',
          kw=dict(count=13, spread=1.0, seed=5), note='boarding tendrils: a crown of fourteen hooked tendrils on a muscle mound; it leans toward its prey (turns)')
    K.mass('Tendril crown', _bpy.data.objects['T1_mount_flesh'], 'flesh mound, tendrils', note='a muscle mound with radial welts, the crown on it')

    # ---------------- the spore glands under the belly (spores T) ----------------
    for i, x in enumerate(GLANDS):
        zb = K.hpt(x, -math.pi / 2)[0].z   # the belly's skin, swell included
        K.gun('G%d' % (i + 1), (x, 0.0, zb - 0.04), 0, 0, barrels=1, cal=0.06, blen=0.6, size=1.15, normal=(0, 0, -1), slot='T', weapon='spores',
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
    K.wob = relief_wobble
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
            for j in range(49):
                t = j / 48
                x = 11.55 - 1.9 * t * (0.85 + 0.15 * math.sin(k * 1.7))   # the head only: the bands start behind it
                th = th0 + (0.62 - th0) * t ** 1.4 * 0.55 + 0.05 * math.sin(t * 10 + k)
                p_, n_ = K.hpt(x, side_th(th, side), out=-0.02); pts.append(p_); nrms.append(n_)
                fade = math.sin(math.pi * (0.015 + 0.97 * t)) ** 0.4
                ws.append((0.54 * (1 - 0.75 * t) + 0.06) * fade * (1 + 0.18 * math.sin(t * 18 + k)))
                hs.append((0.29 * (1 - 0.8 * t) + 0.03) * fade *
                          (1 + 0.14 * math.sin(t * 43 + k) + 0.08 * math.sin(t * 79 + 2 * k)))
            vv, ff = HP.welt(pts, nrms, ws, hs, n=7)
            o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
        hf = K.hull_detail('head_folds_%s' % ('p' if side > 0 else 's'), (V, F), 'flesh2' if side > 0 else 'flesh', inv='head_folds', kind='welt', subs=['welt'])
        K.mass('Head folds (%s)' % ('port' if side > 0 else 'starboard'), hf, 'flesh folds', note='fold rolls running back over the head')
    # pore fields: the head behind the mouths, round the vent crown
    for name, x0, x1, t0, t1, nper in (('head', 9.7, 11.3, -0.3, 1.45, 30), ('tail', -9.9, -8.7, -0.6, 1.5, 14)):
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
    # issue 1291 (R349): the flank veins are gone; they lay where the armadillo bands now lie
    # scars: regrowth patches with knit ridges
    for k, (x, th, r, side) in enumerate(SCARS):
        # A regrowth seam sunk into the actual wrinkled skin, with puckered lips.
        # The cut is also in flesh_relief, so it remains a recess without colour.
        V, F = [], []
        for j in range(33):
            u = -1.2 + 2.4 * j / 32
            xx = x + u * r * 1.1
            bend = 0.06 * math.sin(u * 4)
            width = 0.022 + 0.07 * max(0, math.sin(math.pi * j / 32))
            for offset in (-1, -0.5, 0, 0.5, 1):
                p_, n_ = K.hpt(xx, side_th(th + (bend + width * offset) / 2.5, side), out=0.003)
                V.append(tuple(p_ + n_ * 0.025 * abs(offset)))
        for j in range(32):
            for q in range(4):
                a = j * 5 + q
                F.append((a, a + 1, a + 6, a + 5))
        K.hull_detail('scar%d_patch' % k, (V, F), 'tissue', inv='scars', kind='scar', subs=['patch', 'knit'])
        for edge in (-1, 1):
            pts, nrms = [], []
            for j in range(33):
                u = -1.2 + 2.4 * j / 32
                tt = th + (0.06 * math.sin(u * 4) + edge * 0.11) / 2.5
                p_, n_ = K.hpt(x + u * r * 1.1, side_th(tt, side), out=-0.005)
                pts.append(p_); nrms.append(n_)
            hs = [0.065 * math.sin(math.pi * j / 32) ** 0.5 * (1 + 0.25 * math.sin(j * 1.3 + k)) for j in range(33)]
            K.hull_detail('scar%d_knit%s' % (k, edge), HP.welt(pts, nrms, 0.10, hs, n=6), 'flesh2')
        # Draw short puckered wrinkles into each scar, with unequal lengths.
        for b in range(9):
            pts = []; nrms = []
            a = 2 * math.pi * b / 9 + 0.18 * math.sin(b * 2.1 + k)
            for j in range(9):
                f = j / 8
                xx = x + math.cos(a) * r * (0.7 + f * (0.65 + 0.2 * math.sin(b)))
                tt = th + math.sin(a) * r * (0.7 + f * 0.8) / 2.5
                p_, n_ = K.hpt(xx, side_th(tt, side), out=-0.015)
                pts.append(p_); nrms.append(n_)
            hs = [0.075 * (1 - j / 9) for j in range(9)]
            K.hull_detail('scar%d_pucker%d' % (k, b), HP.welt(pts, nrms, 0.085, hs, n=5), 'flesh')
    # tail folds: wrinkle welts converging on the vent crown
    V, F = [], []
    for k in range(10):
        th0 = -0.9 + 2 * math.pi * k / 10
        pts = []; nrms = []
        for j in range(8):
            x = -8.7 - 0.18 * j
            p_, n_ = K.hpt(x, th0 + 0.04 * j, out=0.0); pts.append(p_); nrms.append(n_)
        vv, ff = HP.welt(pts, nrms, 0.12, 0.06, n=5)
        o = len(V); V.extend(vv); F.extend([tuple(q + o for q in f) for f in ff])
    K.hull_detail('tail_folds', (V, F), 'flesh2', inv='tail_folds', kind='welt', subs=['welt'])

    # ---------------- the armour (issue 1291, R349, the C13 round G look on the shared kit) ----------------
    # armadillo bands of grown chitin from behind the head to the tail, wrapping down both flanks to the keel (the kit's
    # default, Ryan Nov 20: "c10 needs the armor all around ... run it down low too"); broken only round the flank folds, the
    # crown, the brood sacs, the spore glands, the siphons and the tail. The head folds, head pores and the scar sit ahead of the
    # bands, the tail folds behind them. The brood sacs stay uncapped: their birth slits must stay clear (fit check EXIT)
    plates.armadillo(K, _k, 9.6, -8.6, seed=1352, band=1.25, lap=1.45, thick=0.19,
                     keep=('flank_fold', 'head_folds', 'pores_', 'tail_folds', 'scar'),
                     note='armadillo bands of grown chitin from behind the head to the tail, down to the keel, lips aft; broken round the flank folds, the crown, the brood sacs, glands, siphons and vents; hide rolled at the edges')

    # ---------------- colour zones ----------------
    K.colour('dark olive flesh, callused olive hide, dark red veins (paint stage, R349)', 14.0, -10.2, 'whole body')
    K.colour('grown chitin, bone to horn, over olive-brown hide (R349)', 9.6, -8.6, 'the armadillo bands, down to the keel')
    K.colour('ochre chitin', 8.2, -8.0, 'the edge of each flank fold')
    K.colour('bile yellow-green light', 14.0, 12.0, 'the throat glands, deep in the mouths')
    K.colour('bile yellow-green light', -10.2, -14.0, 'the vents and the light in the membranes')
    K.colour('dim bile', 10.6, 0.4, 'the veins, the sac windows, the acid pores')
    K.colour('pale regrowing scar', 9.3, -6.0, 'scar patches')

    # ---------- INSIDE: flesh, bone and organs (R98, R209; factions.md: "Inside: flesh and bone, wet and lit from within") ----------
    K.wob = body_wobble
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
                 path=[(7.5, 7.5), (7.5, 2.7), (6.9, 1.6), (7.6, 0.6), (6.8, -0.5), (7.5, -1.5), (7.0, -2.7), (7.0, -7.5)])
    K.break_line('B-2', -1.6, 'behind the tendril crown: the body tears open across the heart vat\'s aft end and the second stomach',
                 path=[(-1.9, 7.5), (-1.9, 2.6), (-1.45, 1.4), (-1.6, 0.0), (-1.4, -1.4), (-1.95, -2.6), (-1.95, -7.5)])
    K.break_line('B-3', -6.4, 'ahead of the tail: the tail and the vent crown tear free, opening the pulse bladder',
                 path=[(-6.1, 7.5), (-6.1, 1.6), (-6.7, 0.7), (-6.2, -0.2), (-6.6, -1.0), (-6.2, -1.6), (-6.2, -7.5)])
    K.inside.append(dict(kind='note', name='insides', note='Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, '
                                                          'membrane septa for decks, organs and chambers that never reach the skin. The Chorus bursts and tears: sacs rupture first, '
                                                          'then the body tears open along ragged lines (R186).'))
    K.point('core', 'hp_core', (0.1, 0.0, -0.05))
    # nine breach anchors (Bio-titan base 8, Chorus +1 on the big ones): prow 3, mid 3, engine 3, alternating sides, next to the sacs
    for i, (x, th, sec, side) in enumerate(((9.6, -0.35, 'prow', 1), (8.0, -0.45, 'prow', -1), (6.6, 0.95, 'prow', 1),
                                            (2.9, -0.15, 'mid', -1), (-1.0, -0.2, 'mid', 1), (-2.2, 0.85, 'mid', -1),
                                            (-4.9, -0.1, 'eng', 1), (-7.0, 0.55, 'eng', -1), (-8.9, -0.45, 'eng', 1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('breach', 'hp_breach_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd', section=sec, note='open hide beside a sac or the trim')
    for i, (x, th, side) in enumerate(((8.6, -0.45, 1), (8.6, -0.45, -1), (-7.4, 0.55, 1), (-7.4, 0.55, -1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('rcs', 'hp_rcs_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')
    # launch mouths (hangar 3): each brood sac's birth slit, on its skin, launching along the sac's hang (out and down)
    for i, (x, r, th) in enumerate(SACS):
        for side in (1, -1):
            fid = 'B%d%s' % (i + 1, 'p' if side > 0 else 's')
            ob = _bpy.data.objects['%s_body_maw' % fid]
            vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
            c = sum(vs, Vector()) / len(vs); q = min(vs, key=lambda v: (v - c).length)
            pos, nrm = K.hpt(x, side_th(th, side), out=-0.05)
            hang = (Vector(nrm) * 0.7 + Vector((0, 0, -0.9))).normalized()
            K.point('bay', 'hp_bay_%d' % (2 * i + (side < 0)), tuple(q), side='port' if side > 0 else 'stbd', note='brood sac birth slit', dir=tuple(hang))
    # boarding origins (export7: one port, one starboard on the mid hull): where the boarding tendrils' parties leave the body
    for i, side in enumerate((1, -1)):
        pos, nrm = K.hpt(2.0, side_th(0.35, side), out=0.02)
        K.point('board', 'hp_board_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('Armour almost everywhere: the armadillo bands run from behind the head (x 9.6) to the tail (x -8.6) and down both flanks to the keel (the kit default plates.WRAP); the fused belly clusters removed (the belly is banded); the head folds shortened to the head, the head pores, the scar and the tail folds moved clear of the bands',
             'Ryan, Nov 20 4:18 PM CT, on run C: "c10 needs the armor all around, it randomly stops near the top of the spine? run it down low too. we should cover the chorus ships in armor almost everywhere"')
    K.change('The C13 round G look on the shared kit: lumpy swellings grown into the skin behind the head (body.field), armadillo bands of grown '
             'chitin over the back down to the flank folds, fused chitin clusters on the lower flanks and belly; the flank veins and body scars removed, '
             'the head, its folds and the maws as accepted (R302, R306); the brood sacs uncapped so the birth slits stay clear',
             'Ryan, Nov 20 (R349; C13 round G accepted in game, PR 1308): armour across the entire body, grown not tiled; issue 1291 brings C10 to C12 to the same kit calls')
    K.change('Colour: bile yellow-green light over dark olive flesh and ochre chitin', 'R204 and the lore: the colour is fixed in the build; the picture came out grey with amber light (README 8b)')
    K.change('R306: replace the ring rims and repeated ribs with continuous gathered flesh and unequal overlapping lip folds',
             'Issue 921 run 2: thick top hoods and side folds curl into the unchanged open throats and blend back into the cheeks. '
             'Each mouth has its own fold layout. Run 1 bore, spines, glands, glow, hull relief and all other anatomy are kept')
    K.change('R302: the two maws stay open, with 2.6-unit mouth bores and the bile glands recessed 1.6 units',
             'Issue 921: replace the constricting coils with outward rolled, creased flesh lips; keep the two forward weapon slots and their real muzzles. '
             'The mouth centres spread 0.09 units each; firing lanes begin past the actual front of the lips')
    K.change('R302: continuous wrinkled hide, gathered head folds and puckered regrowth scars are modelled relief',
             'Issue 921: remove the separate callus-pad layer. Preserve the original loft curve, tendrils, sacs, vents, mounts and insides. '
             'The future Chorus stack owns fine pore grain, mottling, wetness, scar colour and final maw emission, and must preserve the open voids and relief')
    K.change('The two mouths are the two bile spitters (bioplasma F, F)', 'data.js b_boss carries two Spine volleys forward; a weapon is an organ (factions.md). Each throat gets an inner sphincter, a ring of chitin spines (the spines it spits) and its glowing bile gland; the picture shows only the glow')
    K.change('The tendril cluster is the boarding tendrils (tendril T), a crown on a muscle mound that turns', 'the slot is all round; the profile (the view of record for anatomy, README 8b) curls them up, the plan splays them flat; built as the profile with the tips splayed')
    K.change('The belly row is three spore glands (spores T) on necks, spouts forward', 'the picture\'s small hanging sacs; spaced so the B-2 seam passes behind the crown and between two glands (R226)')
    K.change('Spore glands cut from five to three, one firing pore each (G1 at 4.9, G2 at 0.2, G3 at -5.1)',
             'R241 (Ryan, Nov 13 2026: "all ships should have weapons that match their actual weapons in game"; issue 676 weapon-match check): '
             'spores fires 3 shots a volley; five glands of two pores each left every gland silent on some volleys, so the shots did not split '
             'the same way every time. Three glands of one pore each fire on every volley')
    K.change('The big flank sacs are brood sacs, the hangar (hangar 3), with birth slits', 'the picture\'s crease on each sac becomes the slit the spore swarms are born through; a launch opening kept clear (fit check EXIT). They hang below the lower flank as heavy lobes on soft necks, so from above only their curve shows (the Board on PR 628)')
    K.change('The long ridge down each flank is a raised membrane fold with an ochre chitin edge', 'the picture\'s long flank ridge, given height; the lore\'s ochre chitin trim on its edge; it is also where the hide tears first')
    K.change('The tail ends in a crown of three pulse vents with trailing membranes', 'factions.md: no nozzles, pulsing vents or trailing membranes; the picture\'s spike with three or four glow points and long wisps. The membranes are about two thirds of the picture\'s wisps so the whole ship is 28.0, mouth to membrane tip')
    K.change('Siphons added, a pair behind the mouths and a pair on the tail', 'a ship in space must turn; the picture shows none; siphons, not nozzles')
    K.change('Pore fields on the head and round the tail, veins along the flanks', 'the Chorus has no eyes: it tastes (lore 5.8); the veins carry bile to the throats (README 8b: C9\'s vein tracery faded in this pass)')
    K.change('Scars carry knit ridges', 'regrowing scar tissue (lore 5.3; regen 20): the wound pulling shut')
    K.change('The belly seam B-4 is gone; B-1 to B-3 run on straight past the flanks (issue 623, the recipe)', 'the game\'s longitudinal seam is one level plane over its whole compartment that takes everything above it (fx_death.gd); at the belly it would cut through the lower septum, the brood chambers, the heart vat and the spore stores and leave their halves outside the torn hull (death_seam_check: 1512 triangles). The transverse paths end in straight runs to 7.5 off the axis, as E11\'s do: the game weighs the tear\'s height by how far across the path it is, so a path that stops at the flank tears the insides and the plating at different places near the flanks. The body still bursts at its sacs and tears across in four pieces')
    K.change('Six launch mouths, one per brood sac\'s birth slit, launching out and down along the sac (issue 623)', 'data.js hangar 3; the export needs a hp_bay on the mesh for each mouth')
    K.change('Boarding origins on the mid flanks at x 2.0; the throats\' hard points are the bile glands\' faces deep in the throats (issue 623)', 'the game contract needs one boarding origin a side; the mouth\'s centre is open air, which the export check refuses as off the mesh, so the shot leaves from the gland and the arcs and the firing lane are still taken from the mouth')
    K.change('Breach anchors 6 to 8 moved to x -4.9, -7.0 (higher on the flank) and -8.9 (issue 623)', 'the export puts each anchor on open hull 0.03 of the length clear of every part and apart from the others; at -5.6, -7.0 and -8.6 the last one found no open hull left beside the vents')
    K.open_item('The belly between the sacs is designed here; the sheet has no underside view (its side view shows the belly row)')
    # fixes found by the fit check on the first full layout are listed by K.fix as they are made
