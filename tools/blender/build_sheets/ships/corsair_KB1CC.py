# corsair_KB1CC: the Ashfall Hullbreaker bomber wing craft, the Wide Glacis (data.js bomber: cls 'Squadron', bombs T; hp 28, sp 5).
# Issue 793; widened by R273 (Ryan, Nov 15 2026 18:46 CST: "Yes, I agree with your take on the bomber. Wider for sure."). His
# white-plates call widened into R274 (18:50 CST), a rule for every Hullbreaker ship in the paint stack (issue 726), not this sheet.
# Concept of record: contrib/muse/design/squadron_concepts_2026_11/hullbreakers/round_3/KB1CC.jpg (design_notes_785_round3.md;
# Ryan, Nov 15 2026, R259: KB1C-C "the best by far"; still a space bomber, never a boat, barge, platform or ground vehicle). The
# written sheet governs where the render drifts, except where Ryan ruled for the render: the sheet's terms (the mouths at the
# glacis's extreme corners in dark collars, the armoured lip) stand; its beam guard (60 to 65 percent) is lifted by R273, so the
# craft takes the render's width.
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): KB1C-C is a base, not a trace.
# Ryan's words that bind (R254, R259): no canopy, no swept aero wings, no tail fins, nothing hung under a hull; drives are nozzle
# clusters inside armoured blocks; bombers chunkier and visibly built around what they carry; each faction its own bomber (R253).
# Size: docs/playbooks/scale.md, Squadron row (binding): CLS_LEN['Squadron'] 1.6 long, drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84.
# Every station and size below is a share of LENGTH (the U() helper). +X bow, +Y port, +Z up. Bow toe x = +0.8, the bells x = -0.8.
# The plating is this file's own patchwork plater (patchwork(), R275) using the Hullbreaker kit's plate slab
# (tools/blender/kits/hullbreakers/parts.py); the craft parts (the bomb tubes, the drives, the bays, the slit) are
# tools/blender/kits/hullbreakers/craft.py, added to the kit for this build by craft.install. R275 (Nov 15 2026 21:28 CST)
# sent the wide sheet back for one shape pass: the sloped glacis ramp and the patchwork plating.
import math
import os
import importlib.util

CODE = 'corsair_KB1CC'
NAME = 'Wide Glacis bomber (Ashfall Hullbreaker bomber wing craft)'
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Squadron'
LENGTH = 1.6
GAME = "data.js bomber (cls 'Squadron', the Hullbreaker wing: corsair sq 'bomber'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = 'contrib/muse/design/squadron_concepts_2026_11/hullbreakers/round_3/KB1CC.jpg'
KIT = 'hullbreakers'
CONCEPT_SHEET = BEAUTY
CONCEPT_VIEWS = dict(top=dict(box=(20, 120, 1070, 600)), side=dict(box=(20, 120, 1070, 600)))
CROPS = [('bow (the glacis and the two corner mouths)', (20, 200, 620, 600)), ('midships (the ramp, the rails, the flank bays)', (250, 130, 900, 500)),
         ('stern (the thruster bank)', (520, 110, 1070, 420))]
SHEET = dict(version=1, round='first sheet', date='2026-11-15', blend='opus793', px_per_unit=900, view_pad=0.12, label_scale=1.5, bar_units=0.5,
             blend_where='rendered in the issue 793 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py corsair_KB1CC <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Hullbreaker kit\'s plating and the new craft parts (craft.py), run through the fit check before any fix. R275 reshaped the top into the glacis ramp and replaced the course plating with the patchwork; the fit check found nothing new.',
             during='The table above is every finding, in the order the check made them.')


def U(v):
    """a share of the craft's length in world units"""
    return v * LENGTH


# ---------------------------------------------------------------------------------------------------- the masses
# The central body (the sheet kit's octagon loft, shares of LENGTH): (n, half-beam, belly, top, top chamfer, belly chamfer). R275
# (Ryan, Nov 15 2026 21:28 CST, sending the wide sheet back: the top must be the concept's sloped glacis): its top is one long
# glacis ramp, low at the bow lip and rising all the way aft to the armoured lip and the stern housing that holds the thruster bank.
BODY = [
    (0.500, 0.319, -0.036, -0.008, 0.004, 0.006),
    (0.465, 0.324, -0.046, 0.004, 0.006, 0.010),
    (0.300, 0.314, -0.048, 0.033, 0.010, 0.012),
    (0.100, 0.306, -0.050, 0.069, 0.012, 0.014),
    (-0.100, 0.296, -0.050, 0.104, 0.014, 0.014),
    (-0.300, 0.282, -0.049, 0.140, 0.016, 0.014),
    (-0.355, 0.276, -0.049, 0.150, 0.016, 0.014),
    (-0.372, 0.272, -0.049, 0.168, 0.020, 0.014),
    (-0.460, 0.246, -0.046, 0.168, 0.022, 0.014),
]
# a shoulder either side (the side bodies behind the corner pods): its top slopes down and out from the body's wall to a thin
# outer edge, so the craft's section is a flattened six-sided wedge, never a box on two track-like sponsons. Port half points
# (y, z) of its section, shares of LENGTH, and the stations (n, scale of the slope's height). The starboard shoulder sits a touch
# lower and shorter: the Hullbreakers are lopsided (factions.md), never mirror-even.
# R273 (Ryan, Nov 15 2026: "Wider for sure"): the shoulders reach out to the render's width, the craft about a fifth wider than it is long
SHOULDER = [(0.270, 0.064), (0.499, 0.031), (0.585, 0.013), (0.600, 0.001), (0.600, -0.022), (0.546, -0.046), (0.270, -0.048)]
# (n, k: the slope's height as a share of its full height, w: the shoulder's reach out from the body as a share): in plan the
# craft tapers aft from the wide front (the two corner mouths) to the narrower stern housing, a wedge, never a rectangle
SHOULDER_X = {1: [(0.494, 0.55, 0.92), (0.455, 1.0, 1.0), (-0.230, 1.0, 1.0), (-0.370, 0.92, 0.74), (-0.440, 0.66, 0.6)],
              -1: [(0.494, 0.5, 0.92), (0.455, 0.93, 1.0), (-0.230, 0.93, 1.0), (-0.350, 0.86, 0.76), (-0.425, 0.62, 0.62)]}


def shoulder_in(n):
    """R275: the shoulder's inner edge at station n (share), on the body's flank, so the glacis rails stand clear at the foot of
    the shoulder's wall where the ramp runs low (the bow) and the ramp stands above the shoulders aft"""
    return sec(BODY, max(min(n, BODY[0][0]), X_END))[1] - 0.004


def shoulder_ring(side, n, k, w):
    """the shoulder's section at station n: its heights scaled by k toward the belly line, its reach by w (the ends taper)"""
    zb = -0.048 if side > 0 else -0.05
    yin = shoulder_in(n)
    pts = []
    for i, (y, z) in enumerate(SHOULDER):
        zz = zb + (z - zb) * k - (0.0 if side > 0 else 0.003)
        yy = yin if i in (0, len(SHOULDER) - 1) else yin + (y - yin) * w
        pts.append((U(n), U(side * yy), U(zz)))
    return pts


def shoulder_top(side, y, n=0.0):
    """the shoulder's sloped top at y (share, positive) for the full-height stations, world z"""
    (y0, z0), (y1, z1) = (shoulder_in(n), SHOULDER[0][1]), SHOULDER[1]
    k = SHOULDER_X[side][1][1]; zb = -0.048 if side > 0 else -0.05
    z = z0 + (z1 - z0) * (y - y0) / (y1 - y0)
    return U(zb + (z - zb) * k - (0.0 if side > 0 else 0.003))


X_END = -0.46


def sec(tab, n):
    s = sorted(tab, key=lambda r: -r[0])
    if n >= s[0][0]:
        return list(s[0])
    if n <= s[-1][0]:
        return list(s[-1])
    for a, b in zip(s, s[1:]):
        if a[0] >= n >= b[0]:
            t = (a[0] - n) / (a[0] - b[0])
            return [a[i] + (b[i] - a[i]) * t for i in range(len(a))]


def top(n):
    """the central body's top at station n, world units"""
    return U(sec(BODY, n)[3])


HULL = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), 0.0, 0.0) for r in BODY]


def patchwork(K, HP, name, rings, spec):
    """R275 (Ryan, Nov 15 2026 21:28 CST; R240: "super even and ordered" is wrong for the Hullbreakers): the Hullbreaker
    patchwork on a mass's faces, in this ship file so the kit's own plating (kit.py, the A16 fixture) stays as it is. Each face
    strip (one ring edge followed the mass's whole length) is cut by random guillotine splits into cells of mixed size (world
    units, spec size), so no seam runs in courses or rows; each plate is turned a few degrees (a share of them hard), its
    corners pushed out of square, set a touch bigger than its cell so neighbours lap over each other at their own heights,
    and a share of cells is left bare (the soot hull between). Rivets on a few plates only; a smaller patch on some.
    spec: seed, size=(lo, hi), thick=(lo, hi), faces=[ring edge indices], mats={mat: weight}, skip, turn (degrees), hard (share
    turned hard), stack, rivets_share, rivet_r, gap, inv"""
    import random
    from mathutils import Vector
    rnd = random.Random(spec.get('seed', 1))
    lo, hi = spec['size']; tlo, thi = spec['thick']; g = spec.get('gap', 0.004)
    mats = spec['mats']; names = list(mats); wts = [mats[k] for k in names]
    n = len(rings[0]); R = [[Vector(v) for v in r] for r in rings]
    cen = [sum(r, Vector()) / n for r in R]
    buckets = {k: ([], []) for k in names}
    RV, RF = [], []
    kept = 0
    for j in spec['faces']:
        A = [r[j] for r in R]; B = [r[(j + 1) % n] for r in R]
        mids = [(a + b) / 2 for a, b in zip(A, B)]
        S = [0.0]
        for p0, p1 in zip(mids, mids[1:]):
            S.append(S[-1] + (p1 - p0).length)
        L = S[-1]
        W = [(b - a).length for a, b in zip(A, B)]
        if L < lo * 0.5 or max(W) < lo * 0.45:
            continue

        def at(s):
            # the ring interval and fraction at arc length s
            s = max(0.0, min(L, s))
            for i in range(len(S) - 1):
                if s <= S[i + 1] or i == len(S) - 2:
                    f = (s - S[i]) / max(S[i + 1] - S[i], 1e-9)
                    return i, max(0.0, min(1.0, f))

        def P(s, v):
            i, f = at(s)
            return A[i].lerp(A[i + 1], f).lerp(B[i].lerp(B[i + 1], f), v)

        def width(s):
            i, f = at(s)
            return W[i] + (W[i + 1] - W[i]) * f

        def normal(s):
            i, f = at(s)
            nrm = (B[i] - A[i]).cross(A[i + 1] - A[i])
            if nrm.length < 1e-9:
                nrm = (B[i + 1] - A[i + 1]).cross(A[i + 1] - A[i])
            nrm.normalize()
            if nrm.dot((A[i] + B[i + 1]) / 2 - (cen[i] + cen[i + 1]) / 2) < 0:
                nrm = -nrm
            return nrm
        # the guillotine: split the longer side of a cell at a random point until it is under its own drawn size
        cells, todo = [], [(0.0, L, 0.0, 1.0)]
        while todo:
            s0, s1, v0, v1 = todo.pop()
            ds = s1 - s0; dw = (v1 - v0) * max(width((s0 + s1) / 2), 1e-6); m = rnd.uniform(lo, hi)
            if max(ds, dw) <= m:
                cells.append((s0, s1, v0, v1)); continue
            f = rnd.uniform(0.3, 0.7)
            if min(ds, dw) < lo * 0.5 and max(ds, dw) < hi * 1.4:
                cells.append((s0, s1, v0, v1)); continue   # no slivers: a narrow cell stays one long plate
            if ds * rnd.uniform(0.8, 1.25) >= dw:
                sm = s0 + ds * f; todo += [(s0, sm, v0, v1), (sm, s1, v0, v1)]
            else:
                vm = v0 + (v1 - v0) * f; todo += [(s0, s1, v0, vm), (s0, s1, vm, v1)]
        rank = list(range(len(cells))); rnd.shuffle(rank)
        # the colours by shuffled quota from the weights, so each face carries the sheet's mix and no seed runs dark
        tot = sum(wts); quota = []
        for k_, w_k in zip(names, wts):
            quota += [k_] * int(round(len(cells) * w_k / tot))
        while len(quota) < len(cells):
            quota.append(rnd.choices(names, wts)[0])
        rnd.shuffle(quota)
        tally = dict(cells=len(cells), kept=0, keepout=0, skip=0)
        dt = (thi - tlo) / max(1, len(cells))
        for c_i, (s0, s1, v0, v1) in enumerate(cells):
            r_skip, r_turn, r_hard, r_stack, r_riv = rnd.random(), rnd.uniform(-1, 1), rnd.random(), rnd.random(), rnd.random()
            k = quota[c_i]; grow = rnd.uniform(1.0, 1.14)
            jit = [(rnd.uniform(-1, 1), rnd.uniform(-1, 1)) for _ in range(4)]
            sc, vc = (s0 + s1) / 2, (v0 + v1) / 2
            w_ = width(sc)
            if r_skip < spec.get('skip', 0.08) or w_ < 1e-6:
                tally['skip'] += 1; continue
            hs = max(0.0, (s1 - s0) / 2 * grow - g); hw = max(0.0, (v1 - v0) * w_ / 2 * grow - g)
            if hs < g or hw < g:
                continue
            pc = P(sc, vc)
            # a plate near a mount shrinks off it before it is dropped (big plates would otherwise clear wide rings round every mount)
            for _ in range(3):
                if not any((pc - c).length < r + 0.7 * min(hs, hw) for c, r in K.keepouts):
                    break
                hs, hw = hs * 0.6, hw * 0.6
            else:
                tally['keepout'] += 1; continue
            if hs < g or hw < g:
                tally['keepout'] += 1; continue
            ang = math.radians(spec.get('turn', 6) * r_turn * (2.6 if r_hard < spec.get('hard', 0.3) else 1.0))
            ca, sa = math.cos(ang), math.sin(ang)
            bot = []
            for (qs, qw), (js, jw) in zip(((-hs, -hw), (hs, -hw), (hs, hw), (-hs, hw)), jit):
                qs += js * hs * 0.1; qw += jw * hw * 0.1
                rs_, rw_ = qs * ca - qw * sa, qs * sa + qw * ca
                ss = min(L - g, max(g, sc + rs_)); vv = min(1.0 - g / w_, max(g / w_, vc + rw_ / w_))
                bot.append(P(ss, vv))
            nrm = normal(sc)
            t = tlo + rank[c_i] * dt
            riv = r_riv < spec.get('rivets_share', 0.15)
            (V, F), (rv, rf) = HP.plate_slab(bot, nrm, t, rivets=riv, rr=spec.get('rivet_r', 0.035))
            bv, bf = buckets[k]; o = len(bv); bv.extend(V); bf.extend([tuple(x + o for x in f) for f in F])
            if riv:
                o = len(RV); RV.extend(rv); RF.extend([tuple(x + o for x in f) for f in rf])
            kept += 1; tally['kept'] += 1; tally[k] = tally.get(k, 0) + 1
            if r_stack < spec.get('stack', 0.15):
                # a smaller patch bolted over part of this plate, a second thickness step
                fu, fv = rnd.uniform(0.3, 0.55), rnd.uniform(0.3, 0.6)
                cu, cv = rnd.uniform(-0.5 + fu / 2, 0.5 - fu / 2), rnd.uniform(-0.5 + fv / 2, 0.5 - fv / 2)
                q = [bot[0].lerp(bot[1], 0.5 + cu + du).lerp(bot[3].lerp(bot[2], 0.5 + cu + du), 0.5 + cv + dv) + nrm * t
                     for du, dv in ((-fu / 2, -fv / 2), (fu / 2, -fv / 2), (fu / 2, fv / 2), (-fu / 2, fv / 2))]
                (V, F), _ = HP.plate_slab(q, nrm, tlo * 0.8, rivets=False)
                k2 = quota[(c_i + 7) % len(quota)]; bv, bf = buckets[k2]; o = len(bv); bv.extend(V); bf.extend([tuple(x + o for x in f) for f in F])
    for k, (V, Fc) in buckets.items():
        if V:
            K._obj('%s_plates_%s' % (name, k), V, Fc, k, grp='hull')
    if RV:
        K._obj('%s_rivets' % name, RV, RF, 'iron', grp='hull')
    for iid in ([spec['inv']] if isinstance(spec.get('inv'), str) else spec.get('inv', [])):
        K.built.append(dict(id=name + '_plates', kind='plate', inv=[iid], shaped=True, detailed=kept > 0, subs=['slab', 'step', 'bevel', 'rivet']))
    return kept


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector
    HP = _k.HP
    sp = importlib.util.spec_from_file_location('hb_craft', os.path.join(_k._KITS, 'hullbreakers', 'craft.py'))
    CR = importlib.util.module_from_spec(sp); sp.loader.exec_module(CR)
    CR.install(HP)
    K.hull_sections = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), U(r[4]), U(r[5])) for r in BODY]
    # R275: the Hullbreaker patchwork (patchwork() above): fewer, bigger, uneven plates of mixed size and angle, never small even
    # squares in rows; big trophy patches among them (R252), rust and dried blood the main tones (the concept's red), soot and
    # bare iron between; the colours as the first sheet had them
    PL = dict(size=(U(0.075), U(0.19)), thick=(U(0.0022), U(0.0052)), gap=U(0.0016), skip=0.06, turn=5.0, hard=0.3, stack=0.14,
              rivets_share=0.07, rivet_r=U(0.0018),
              mats={'rust': 5, 'soot': 4, 'blood': 3, 'iron': 2, 'soot2': 2, 'pale': 0.6, 'violet': 0.4})
    PATCH = []   # (name, rings, spec): plated last, once every mount has claimed its keep-out
    ns = sorted({r[0] for r in BODY} | {round(0.46 - 0.04 * i, 3) for i in range(24) if 0.46 - 0.04 * i > X_END}, reverse=True)
    bsecs = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), U(r[4]), U(r[5])) for r in [sec(BODY, n) for n in ns]]
    body = K.loft(CODE + '_body', bsecs, 'soot', shell=U(0.004))
    PATCH.append((CODE + '_body', [[(s_[0], y, z) for (y, z) in _k._octa(*s_[1:7])] for s_ in bsecs],
                  dict(PL, seed=31, faces=[1, 3, 7, 5], inv=['glacis_plates', 'belly_plates'])))
    K.mass('Hull: the central body (the glacis ramp and the stern housing)', body, 'soot and patched plate',
           note='one wide low body: its top one long glacis ramp, low at the bow lip and rising aft to the armoured lip and the stern housing that holds the thruster bank; flat belly with chines')
    K.mark('body', 'hull', ['bevel', 'step', 'overhang'])
    for side in (1, -1):
        nm = 'port' if side > 0 else 'starboard'
        rs = [shoulder_ring(side, n, k, w) for (n, k, w) in SHOULDER_X[side]]
        ob = K.loft_rings('KB1CC_shoulder_%s' % nm[0], rs, 'soot2')
        PATCH.append(('KB1CC_shoulder_%s' % nm[0], rs, dict(PL, seed=40 + side, faces=[0, 1, 5], inv='shoulder_plates')))
        md = ob.modifiers.new('shell', 'SOLIDIFY'); md.thickness = U(0.004); md.offset = -1; md.use_rim = True
        K.mass('Shoulder, %s' % nm, ob, 'dark soot and patched plate', note='the %s side body behind the corner pod, its top sloping down and out to a thin edge: the bomb row\'s magazine and the hoist bay%s' % (
            nm, '' if side > 0 else '; a touch lower and shorter than the port one (lopsided)'))
    K.mark('shoulders', 'tier', ['face', 'roof', 'opening'])

    # ---------------- the glacis rails: armoured edge frames running diagonally up the ramp's two edges ----------------
    RW, RH = 0.011, 0.012
    for side in (1, -1):
        nm = 'p' if side > 0 else 's'
        rs = []
        for n in [0.49 - 0.04 * i for i in range(23) if 0.49 - 0.04 * i > -0.39] + [-0.388]:
            hw = sec(BODY, n)[1] - 0.006 - sec(BODY, n)[4] * 0.6
            zt = sec(BODY, n)[3] - 0.003
            y0, y1 = side * (hw - 2 * RW), side * hw
            ya, yb = min(y0, y1), max(y0, y1)
            c = RW * 0.35
            rs.append([(U(n), U(y), U(z)) for (y, z) in ((ya, zt), (ya, zt + RH - c), (ya + c, zt + RH), (yb - c, zt + RH), (yb, zt + RH - c), (yb, zt))])
        K.loft_rings('KB1CC_rail_%s' % nm, rs, 'iron')
        # clamp brackets bolted along the rail every few plates
        for n in (0.42, 0.3, 0.18, 0.02, -0.14, -0.3):
            hw = sec(BODY, n)[1] - 0.006 - sec(BODY, n)[4] * 0.6; zt = sec(BODY, n)[3]
            K.box('KB1CC_railclamp_%s%d' % (nm, int(n * 100)), U(n - 0.012), U(n + 0.012), U(side * (hw - 2 * RW) - 0.004) if side > 0 else U(-hw - 0.004),
                  U(hw + 0.004) if side > 0 else U(-(hw - 2 * RW) + 0.004), U(zt), U(zt + RH + 0.004), 'steel', ch=U(0.002), grp='hull')
    K.mark('rails', 'rib', ['rib'])

    # ---------------- the armoured lip at the top of the ramp, against the stern housing, and the crew's vision slit in its face ----------------
    # R275: the lip moves from mid-body to the ramp's top end, where the glacis meets the stern housing; its face looks forward down the ramp
    LX0, LX1, LTOP = -0.288, -0.372, 0.173
    secs = []
    for n, zt_ in ((LX0, top(LX0) / LENGTH + 0.002), (LX0 - 0.014, LTOP - 0.002), (LX1, LTOP)):
        hw = sec(BODY, n)[1] - 0.006 - sec(BODY, n)[4] * 0.6 - 2 * RW - 0.002
        secs.append((U(n), U(hw), U(hw), U(sec(BODY, n)[3] - 0.006), U(zt_), U(0.005), 0.0))
    lip = K.loft('KB1CC_lip', secs, 'soot2')
    PATCH.append(('KB1CC_lip', [[(s_[0], y, z) for (y, z) in _k._octa(*s_[1:7])] for s_ in secs], dict(PL, seed=61, faces=[1], size=(U(0.055), U(0.12)), inv=[])))
    K.mass('The armoured lip', lip, 'dark soot plate', note='an armoured lip across the top of the glacis ramp, against the stern housing: it ends the slope, so the glacis reads as armour on a hull, the crew under it')
    K.mark('lip', 'tier', ['face', 'roof', 'opening'])
    z0_, z1_ = top(LX0) / LENGTH + 0.002, LTOP - 0.002
    sn = Vector((z1_ - z0_, 0, 0.014)).normalized()
    ax, az = U(LX0 - 0.007), U((z0_ + z1_) / 2)
    K._surface_part('W1', CR.slit(U(0.07), U(0.0042), U(0.0022), U(0.0022)), (ax, U(0.02), az), tuple(sn), (0, 0, 1), 'vision_slit',
                    'vision slit %.2f x %.3f' % (U(0.07), U(0.0042)), 'slit', 'designed',
                    'the crew\'s vision slit in the lip\'s face, a little to port, looking forward down the ramp (the bombardier aims the craft at its target)', aperture=U(0.2))

    # ---------------- the two bomb tubes: one in each front corner pod, at the glacis's extreme corners ----------------
    R_M = 0.04
    for side, fid in ((1, 'BT1'), (-1, 'BT2')):
        y = side * 0.535
        K.launcher(fid, (U(0.5 - 0.004), U(y), U(0.019 if side > 0 else 0.017)), 1, 1, cell=U(R_M / 0.3), depth=U(0.215), yaw=0.0, pitch=0.0,
                   slot='T', weapon='bombs', inv='bomb_tubes', variant='bomb%d' % (1 if side > 0 else 2),
                   note='the bomb payload (data.js bombs T, 2 shots): the %s bomb tube in its corner pod, a dark armoured collar round the mouth; one bomb from each tube every volley' % (
                       'port' if side > 0 else 'starboard'))
        K.features[-1]['what'] = 'bomb tube in a corner pod, mouth %.2f across' % (2 * U(R_M))
        c_, r_ = K.keepouts[-1]
        K.keepouts[-1] = (c_, U(0.07))   # the pod's own plate keep-out (the kit's default reaches its whole drum)

    # ---------------- the hoist bays: the bomb hoists, behind armoured doors, in the shoulders' sloped tops ----------------
    for side, fid in ((1, 'Y1'), (-1, 'Y2')):
        n0, n1 = -0.0, -0.215
        nc = (n0 + n1) / 2
        (y0_, z0_), (y1_, z1_) = (shoulder_in(nc), SHOULDER[0][1]), SHOULDER[1]
        yc = 0.39
        nrm = Vector((0.0, side * (z0_ - z1_), (y1_ - y0_))).normalized()
        wid = (Vector((y1_ - y0_, z1_ - z0_)).length) * 0.62
        K._surface_part(fid, CR.machbay(U(n0 - n1), U(wid), U(0.004), door=0.42 if side > 0 else 0.5, seed=1 if side > 0 else 2),
                        (U(nc), side * U(yc), shoulder_top(side, yc, nc) + U(0.0005)), tuple(nrm), (1, 0, 0), 'hoist_bays',
                        'hoist bay %.2f x %.2f, armoured door' % (U(n0 - n1), U(wid)), 'bay', 'picture',
                        'the %s bomb hoist: the machinery that walks the next bomb from the shoulder\'s magazine row into its tube, behind an armoured door (the concept\'s recessed side bay)' % (
                            'port' if side > 0 else 'starboard'))
        c_, r_ = K.keepouts.pop()   # the bay is long and narrow: three small keep-outs along it instead of one circle round it all
        for f_ in (-0.32, 0.0, 0.32):
            K.keepouts.append((c_ + Vector((U((n0 - n1) * f_), 0, 0)), U(0.05)))

    # ---------------- the thruster bank: five mismatched drives in a recess in the stern housing ----------------
    BANK = [(0.104, 0.117, 0.017), (0.057, 0.121, 0.021), (-0.003, 0.115, 0.028), (-0.062, 0.12, 0.02), (-0.107, 0.112, 0.016)]   # (y, z, bell radius); R275: raised to the top of the housing, at the top of the ramp
    XB = X_END - 0.036
    for i, (y, z, r) in enumerate(BANK):
        K.engine('E%d' % (i + 1), (U(XB), U(y), U(z)), U(r), U(0.07), bell=1.0, kw=dict(craft=True, craft_len=U(0.034), seed=i), inv='drives',
                 note='%s drive: a salvaged bell with a red-orange glow on a short drum%s' % (('first', 'second', 'centre', 'fourth', 'fifth')[i],
                                                                                              ', the big one' if r > 0.025 else ''))
    # the recess round the bank: a hood over it, cheeks at its sides, a sill under it, all welded to the stern housing
    zb_, zt_ = sec(BODY, X_END)[2], sec(BODY, X_END)[3]
    hw_ = sec(BODY, X_END)[1]
    HZ = 0.152   # the hood's underside, over the bells
    K.box('KB1CC_bankhood', U(X_END - 0.03), U(X_END + 0.004), U(-hw_ + 0.006), U(hw_ - 0.006), U(HZ), U(zt_ - 0.004), 'soot2', ch=U(0.004), grp='hull')
    PATCH.append(('KB1CC_bankhood', [[(x_, y, z) for (y, z) in _k._octa(U(hw_ - 0.006), U(hw_ - 0.006), U(HZ), U(zt_ - 0.004), U(0.004), U(0.002))]
                                     for x_ in (U(X_END + 0.004), U(X_END - 0.03))], dict(PL, seed=55, faces=[1], size=(U(0.035), U(0.09)), inv=[])))
    for side in (1, -1):
        K.box('KB1CC_bankcheek_%s' % ('p' if side > 0 else 's'), U(X_END - 0.03), U(X_END + 0.004), U(0.136) if side > 0 else U(-hw_ + 0.006),
              U(hw_ - 0.006) if side > 0 else U(-0.142), U(zb_ + 0.006), U(HZ), 'iron', ch=U(0.003), grp='hull')
    K.box('KB1CC_banksill', U(X_END - 0.03), U(X_END + 0.004), U(-0.142), U(0.136), U(zb_ + 0.006), U(0.06), 'soot2', ch=U(0.003), grp='hull')
    K.mark('bank_recess', 'pylon', ['web', 'plate'])
    K.fix('The corner pods hung below the belly (the collars\' bottoms at -0.07 against a belly of -0.04): side-on they read as front rollers (seen on the sheet\'s side view, not the fit check)',
          'the mouths a step smaller (0.08 across) and raised to mid-height on the corners, the collars\' bottoms on the belly line, the bow\'s belly a touch deeper; nothing hangs under the hull')
    K.fix('E2, E3 and E4: neighbouring bells touching at their lips, each in the next one\'s exhaust cone (CLASH 2, EXHAUST 3)',
          'the bells shrunk a step (the centre one 0.045 across, still the largest) and spread so each lip clears the next by 0.008')

    # ---------------- colour zones ----------------
    K.colour('rust and dried-blood plate in a patchwork of big uneven plates, soot and bare iron between', U(0.5), U(-0.5), 'whole hull')
    K.colour('trophy patches: pale Hegemony grey, violet Eclipse plate', U(0.5), U(-0.5), 'scattered, big (R252; R274: the Hullbreaker paint stack turns the pale ones dark grey metal, issue 726)')
    K.colour('red-orange glow only in the five bells; the mouths dark; no bright light', U(-0.46), U(-0.5), 'the thruster bank; factions.md: runs dark')

    # ---------------- INSIDE: the magazine rows (the bomber's story), kept small ----------------
    def room(name, kind, n0, n1, y0, y1, z0, z1, note=''):
        K.room(name, kind, U(min(n0, n1)), U(max(n0, n1)), U(y0), U(y1), U(z0), U(z1), note=note)
    for side in (1, -1):
        y = side * 0.42
        room('magazine_%s' % ('p' if side > 0 else 's'), 'magazine', 0.26, -0.1, y - 0.04, y + 0.04, -0.036, 0.014,
             note='the %s bomb row in the shoulder: salvaged bombs racked nose forward, fed by the hoist to the tube' % ('port' if side > 0 else 'starboard'))
    room('crew', 'crew', -0.258, -0.35, -0.06, 0.06, -0.02, 0.12, note='the pilot and the bombardier under the lip at the top of the ramp, behind the vision slit')
    room('reactor', 'core', -0.04, -0.19, -0.09, 0.09, -0.035, 0.06, note='the drive reactor, under the ramp')
    room('drive_room', 'engroom', -0.37, -0.44, -0.13, 0.13, -0.035, 0.14, note='the drive room and the bank\'s feeds, in the stern housing')
    K.armour('glacis', U(0.008), 'the heaviest plate, over the crew and the bow')
    K.armour('body and shoulders', U(0.004), 'patched plate')
    reach = 0.4
    K.break_line('B-1', U(-0.237), 'the crew and stern block tears from the body at a weld (Hullbreakers: at the seams; only for the recipe\'s records: the game never breaks a craft)',
                 path=[(U(-0.237), U(reach)), (U(-0.237), U(0.2)), (U(-0.229), U(0.12)), (U(-0.245), U(0.04)), (U(-0.23), U(-0.05)), (U(-0.246), U(-0.14)),
                       (U(-0.237), U(-0.2)), (U(-0.237), U(-reach))])
    K.inside.append(dict(kind='note', name='insides', note='A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. The magazine rows are here because the build contract needs an inside (tools/blender/build_sheets/contract.py) and because the magazine is the bomber\'s story; they cost few triangles.'))
    K.point('core', 'hp_core', (U(-0.115), 0.0, U(0.01)))

    # ---------- the patchwork, last: every mount has claimed its keep-out by now ----------
    for nm_, rings_, spec_ in PATCH:
        patchwork(K, HP, nm_, rings_, spec_)

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as every craft; beam about 1.2 of the length, the render\'s width',
             'docs/playbooks/scale.md, Squadron rows, binding; R273, Ryan, Nov 15: "Wider for sure": the round 3 beam guard (60 to 65 percent) is lifted for this craft. The first sheet held it at 0.61 and read far narrower than the render')
    K.change('The two round mouths at the front corners are bomb tubes: dark armoured collars round dark bores with the next bomb\'s nose seated deep inside, no glow',
             'the round 3 sheet: the mouths at the glacis\'s extreme corners, each in a dark armoured collar; the render lights them red like engines, which would read as drives facing forward; the glow belongs to the bank aft')
    K.change('The tubes are fixed forward in their pods, not on a turning mount',
             'a craft turns onto its target on a strafing run; weapon_match.py FITS bombs: a bomb tube on a launcher (the Board\'s reading of rule 11 for craft); two tubes for the 2 shots, both fire every volley')
    K.change('The top is one long glacis ramp, low at the bow and rising aft to an armoured lip against the stern housing, with the crew\'s vision slit in the lip\'s face; the ramp is framed by armoured edge rails with bolted clamps that run diagonally up it',
             'R275 (Ryan, Nov 15 2026 21:28 CST, sending the wide sheet back): the top must be the concept\'s sloped glacis, not a flat slab; the round 3 sheet (DeepSeek) put the lip where the slope ends so it reads as armour on a hull; no canopy (R254), so the crew looks out through a slit; the rails are the concept\'s raised glacis edges')
    K.change('The flank bays are the bomb hoists, one a side in the shoulder\'s sloped top: a heavy frame, a dark back, pipes and the hoist block inside, an armoured door in a second tone over the fore part',
             'every part has a job (R221): the hoist walks the next bomb from the shoulder\'s magazine row into its tube; on the slope they face the battle camera; the doors carry a two-tone value shift so they survive 32 px (Qwen)')
    K.change('The stern thruster bank is five mismatched salvaged bells, the centre one the largest, in a recess (a hood, cheeks and a sill) in the stern housing',
             'the concept\'s row of stern thrusters; factions.md: mismatched bells with a red-orange glow, one often larger than the rest; the owner\'s rule for craft: nozzle clusters inside armoured blocks')
    K.change('The starboard shoulder sits a touch lower and shorter than the port one; the plating is a patchwork of fewer, bigger, uneven plates of mixed size and angle (rust, dried blood, soot and iron with big trophy patches), laid by the sheet\'s own plater, never courses',
             'factions.md: lopsided, bolted, patched, plates torn from every other faction; R240 and R275: the patchwork never reads even or in rows (the kit\'s courses read as tidy squares on a craft); R252: big trophy patches (R274: the pale ones become dark grey metal in the Hullbreaker paint stack for every ship, issue 726; the sheet keeps the pale zone)')
    K.change('No dishes, claws, antennas, lamps or hangar', 'below what the battle camera shows on a 3.84 unit craft, and nothing hangs off (factions.md); bold and simple')
    K.change('A small inside: two magazine rows in the shoulders, the crew cell, the reactor, the drive room; one seam (B-1)',
             'the game shows a craft\'s death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam')
    K.open_item('The rust, soot, trophy colours and the red running lights are the Hullbreaker paint stack (tools/blender/kits/hullbreakers/stack.py), applied later')
    K.open_item('How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here')
