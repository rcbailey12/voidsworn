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
# The plating uses the faction kit's mixed-size welded patchwork (plating.py, R289) and plate slab
# (tools/blender/kits/hullbreakers/parts.py); the craft parts (the bomb tubes, the drives, the bays, the slit) are
# tools/blender/kits/hullbreakers/craft.py, added to the kit for this build by craft.install. R275 (Nov 15 2026 21:28 CST)
# sent the wide sheet back for one shape pass: the sloped glacis ramp and the patchwork plating.
import math
import os
import importlib.util

_ps = importlib.util.spec_from_file_location('hullbreaker_plating',
    os.path.join(os.path.dirname(__file__), '..', '..', 'kits', 'hullbreakers', 'plating.py'))
_plating = importlib.util.module_from_spec(_ps); _ps.loader.exec_module(_plating)

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
SHEET = dict(version=5, round='R304 run 3: long integrated bomb barrels, issue 903', date='2026-11-16', blend='issue903r3', px_per_unit=900, view_pad=0.12, label_scale=1.5, bar_units=0.5, tq_zoom=0.70,
             blend_where='rebuilt on Ryan\'s PC; docs/shots/look_bench/corsair_KB1CC/shape_r294/reproduce.py records the sheet and paint proof',
             before='First full layout', before_note='The first complete layout, built with the Hullbreaker kit\'s plating and the new craft parts (craft.py), run through the fit check before any fix. R275 reshaped the top into the glacis ramp and replaced the course plating with the patchwork; the fit check found nothing new.',
             during='The table above is every finding, in the order the check made them.')


def U(v):
    """a share of the craft's length in world units"""
    return v * LENGTH


# ---------------------------------------------------------------------------------------------------- the masses
# The central body (the sheet kit's octagon loft, shares of LENGTH): (n, half-beam, belly, top, top chamfer, belly chamfer). R275
# R294 corrects the R275 interpretation: a tapered toe, a rising glacis, then a substantial level upper deck.
BODY = [
    (0.500, 0.205, -0.028, -0.008, 0.004, 0.006),
    (0.445, 0.245, -0.044, 0.004, 0.006, 0.010),
    (0.300, 0.302, -0.048, 0.045, 0.010, 0.012),
    (0.100, 0.306, -0.050, 0.104, 0.012, 0.014),
    (-0.035, 0.300, -0.050, 0.144, 0.014, 0.014),
    (-0.100, 0.296, -0.050, 0.144, 0.014, 0.014),
    (-0.355, 0.276, -0.049, 0.144, 0.016, 0.014),
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
SHOULDER_X = {1: [(0.430, 0.55, 0.45), (0.330, 1.0, 1.0), (-0.230, 1.0, 1.0), (-0.360, 0.92, 0.86)],
              -1: [(0.420, 0.5, 0.45), (0.320, 0.93, 1.0), (-0.230, 0.93, 1.0), (-0.350, 0.86, 0.86)]}


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
    return _plating.patchwork(K, HP, name, rings, spec)


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector, Matrix
    HP = _k.HP
    sp = importlib.util.spec_from_file_location('hb_craft', os.path.join(_k._KITS, 'hullbreakers', 'craft.py'))
    CR = importlib.util.module_from_spec(sp); sp.loader.exec_module(CR)
    from geom import Part, block, revolve, moved
    CR.install(HP)
    # R299 is specific to KB1CC. Reuse the kit's bomb collar, bands and fit
    # records, but seat the round mouth in corner armour with its payload deep
    # behind a dim red bore liner. No engine plug, flare or aft exhaust marker.
    rocket_rack = HP.rocket_rack
    def corner_bomb(rows, cols, cell, depth, variant=0):
        # Keep Run 2's collar, mouth, bomb nose and red liner at their exact
        # depths. Only the barrel behind them grows, to the magazine breech.
        mouth_depth = U(.20)
        part = rocket_rack(rows, cols, cell, mouth_depth, variant=variant)
        r = cell * .3
        for c in part.comps:
            if c['name'] == 'warhead':
                v, f = revolve([(-mouth_depth*.71, r*.78), (-mouth_depth*.65, r*.48), (-mouth_depth*.61, .0001)], 24)
                c.update(verts=[Vector(x) for x in v], faces=f)
            elif c['name'] == 'warheadband':
                v, f = revolve([(-mouth_depth*.70, r*.78), (-mouth_depth*.70, r*.83), (-mouth_depth*.68, r*.83), (-mouth_depth*.68, r*.78)], 24, closed=True)
                c.update(verts=[Vector(x) for x in v], faces=f)
            elif c['name'] == 'housing':
                # A continuous hollow barrel, with no cap behind the short mouth.
                # Its long cylindrical run remains visible beside the glacis.
                v, f = revolve([(-r*.70, r*1.45), (-U(.16), r*1.22),
                                (-depth, r*1.20), (-depth, r*.98)], 24)
                c.update(verts=[Vector(x) for x in v], faces=f)
            elif c['name'] == 'bore':
                v, f = revolve([(0, r), (-U(.16), r), (-depth, r*.98)], 32)
                c.update(verts=[Vector(x) for x in v], faces=f)
            elif c['name'] == 'boreback':
                v, f = revolve([(-depth, r*.98), (-depth, .0001)], 32)
                c.update(verts=[Vector(x) for x in v], faces=f)
            elif c['name'].startswith('band') or c['name'] == 'patch':
                c['faces'] = []  # replaced below by straps sized to the long barrel
        part.comps = [c for c in part.comps if c['faces']]
        for j, distance in enumerate((.105, .285, .455, .525)):
            x = -U(distance)
            rr = r * (1.37 if j == 0 else 1.25)
            part.add('band_barrel%d' % j, 'mount', 'iron',
                     revolve([(x+U(.009), rr), (x+U(.009), rr+U(.008)),
                              (x-U(.009), rr+U(.008)), (x-U(.009), rr)], 16, closed=True))
            for a in (math.pi*.25, math.pi*.5, math.pi*.75):
                part.add('strap_bolt%d' % j, 'mount', 'iron',
                         CR._stud((x, (rr+U(.008))*math.cos(a), (rr+U(.008))*math.sin(a)),
                                  (0, math.cos(a), math.sin(a)), U(.003)))
        # Curved armour laps over the rear barrel, then down into the shoulder.
        # These are armour on the tube, not another rectangular note on the hull.
        for j, (xa, xb) in enumerate(((.34, .435), (.465, .54))):
            rr, t = r*1.22, U(.007)
            angles = [math.radians(-20 + i*220/16) for i in range(17)]
            vv = [(x, rad*math.cos(a), rad*math.sin(a))
                  for x in (-U(xa), -U(xb)) for rad in (rr, rr+t) for a in angles]
            nn = len(angles)
            ff = []
            for i in range(nn-1):
                ff += [(i, i+1, 2*nn+i+1, 2*nn+i),
                       (nn+i, 3*nn+i, 3*nn+i+1, nn+i+1),
                       (i, nn+i, nn+i+1, i+1),
                       (2*nn+i, 2*nn+i+1, 3*nn+i+1, 3*nn+i)]
            ff += [(0, 2*nn, 3*nn, nn), (nn-1, 2*nn-1, 4*nn-1, 3*nn-1)]
            part.add('barrel_armour%d' % j, 'mount', 'rust' if j == 0 else 'blood', (vv, ff))
        # The liner must clear the flats of the kit's 16-sided dark bore.
        # A near-coincident 32-sided sleeve crossed those flats and made red
        # stripes. Only the lower half glows, behind a long cold entrance.
        v, f = revolve([(-mouth_depth*.58, r*.93), (-mouth_depth*.69, r*.93)], 32)
        f = [q for q in f if sum(v[i][2] for i in q) < 0]
        part.add('borelight', 'mount', 'light', (v, f))
        return part
    HP.rocket_rack = corner_bomb
    K.hull_sections = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), U(r[4]), U(r[5])) for r in BODY]
    # R275: the Hullbreaker patchwork (patchwork() above): fewer, bigger, uneven plates of mixed size and angle, never small even
    # squares in rows; big trophy patches among them (R252), rust and dried blood the main tones (the concept's red), soot and
    # bare iron between; the colours as the sheet had them before R275
    # R292: keep the irregular cuts and overlaps, but bed them close to the
    # skin. The old 0.5 to 1.4 percent relief made these small plates look loose.
    PL = dict(size=(U(0.095), U(0.23)), thick=(U(0.002), U(0.005)), gap=U(0.0016), skip=0.06, turn=12.0, hard=0.35, stack=0.45,
              rivets_share=0.07, rivet_r=U(0.0018),
              mats={'rust': 12, 'blood': 7, 'soot': 1.3, 'iron': 1, 'soot2': .7, 'steel': .3})
    PATCH = []   # (name, rings, spec): plated last, once every mount has claimed its keep-out
    ns = sorted({r[0] for r in BODY} | {round(0.46 - 0.04 * i, 3) for i in range(24) if 0.46 - 0.04 * i > X_END}, reverse=True)
    bsecs = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), U(r[4]), U(r[5])) for r in [sec(BODY, n) for n in ns]]
    body = K.loft(CODE + '_body', bsecs, 'rust', shell=U(0.004))
    PATCH.append((CODE + '_body', [[(s_[0], y, z) for (y, z) in _k._octa(*s_[1:7])] for s_ in bsecs],
                  dict(PL, seed=31, faces=[1, 3, 7, 5], inv=['glacis_plates', 'belly_plates'])))
    K.mass('Hull: the central body (the glacis ramp and the stern housing)', body, 'soot and patched plate',
           note='R294: a narrower tapered bow toe, a rising glacis ending at station -0.035, a level upper deck through -0.355, then the stern bank housing; flat belly with chines')
    K.mark('body', 'hull', ['bevel', 'step', 'overhang'])
    shoulders = {}
    for side in (1, -1):
        nm = 'port' if side > 0 else 'starboard'
        rs = [shoulder_ring(side, n, k, w) for (n, k, w) in SHOULDER_X[side]]
        ob = K.loft_rings('KB1CC_shoulder_%s' % nm[0], rs, 'rust')
        PATCH.append(('KB1CC_shoulder_%s' % nm[0], rs, dict(PL, size=(U(.065), U(.14)), seed=40 + side,
                                                                      faces=[0, 1, 5], inv='shoulder_plates')))
        md = ob.modifiers.new('shell', 'SOLIDIFY'); md.thickness = U(0.004); md.offset = -1; md.use_rim = True
        shoulders[side] = ob
        K.mass('Shoulder, %s' % nm, ob, 'dark soot and patched plate', note='the %s side body behind the corner pod, its top sloping down and out to a thin edge: the bomb row\'s magazine and the hoist bay%s' % (
            nm, '' if side > 0 else '; a touch lower and shorter than the port one (lopsided)'))
    K.mark('shoulders', 'tier', ['face', 'roof', 'opening'])

    # ---------------- the glacis rails: armoured edge frames running diagonally up the ramp's two edges ----------------
    RW, RH = 0.014, 0.026
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
    LX0, LX1, LTOP = -0.330, -0.372, 0.173
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
    R_M = 0.064
    TUBE_DEPTH = .54
    tube_clearances = {}
    for side, fid in ((1, 'BT1'), (-1, 'BT2')):
        y = side * 0.495
        z = .059 if side > 0 else .056
        K.launcher(fid, (U(0.430), U(y), U(z)), 1, 1, cell=U(R_M / 0.3), depth=U(TUBE_DEPTH), yaw=0.0, pitch=0.0,
                   slot='T', weapon='bombs', inv='bomb_tubes', variant='bomb%d' % (1 if side > 0 else 2),
                   note='R304: the %s long bomb barrel runs .54 LENGTH from the unchanged dark mouth to its magazine breech, wrapped by curved armour and riveted straps; Run 2 bore light and bomb nose; bombs T, one shot from each tube every volley' % (
                       'port' if side > 0 else 'starboard'))
        K.features[-1]['what'] = 'integrated bomb barrel %.3f long, mouth %.2f across' % (U(TUBE_DEPTH), 2 * U(R_M))
        c_, r_ = K.keepouts[-1]
        K.keepouts[-1] = (c_, U(0.115))
        # Join the lower drum to the shoulder with a plated wedge, entirely
        # behind the collar. Its top ends below the bore, leaving a real opening.
        rings = []
        for n, half, zt in ((.382, .087, .039), (.320, .101, .047), (.230, .095, .044)):
            yc = side*.495
            rings.append([(U(n), U(yy), U(zz)) for yy, zz in
                          ((yc-half, -.043), (yc-half, zt), (yc+half, zt), (yc+half, -.043))])
        corner = K.loft_rings('KB1CC_corner_%s' % fid, rings, 'rust')
        cavity = K._obj('bomb_bore_cut', *moved(revolve([(U(.432), U(R_M*1.002)), (U(.283), U(R_M*1.002))],
                                                       32, cap0=True, cap1=True),
                                               Matrix.Translation((0, U(y), U(.059 if side > 0 else .056)))), 'dark')
        for skin in (corner, shoulders[side]):
            bpy.context.view_layer.objects.active = skin
            if skin.modifiers.get('shell'):
                bpy.ops.object.modifier_apply(modifier='shell')
            md = skin.modifiers.new('R299 open bomb bore', 'BOOLEAN')
            md.operation = 'DIFFERENCE'; md.solver = 'EXACT'; md.object = cavity
            bpy.ops.object.modifier_apply(modifier=md.name)
        bpy.data.objects.remove(cavity, do_unlink=True)
        K.keepouts.append((Vector((U(.324), U(y), U(.059 if side > 0 else .056))), U(.105)))
        # Relieve the shoulder and the bay's outer wall around the barrel. The
        # bay, pipes and hoist keep their Run 2 locations and dimensions.
        clearance = K._obj('barrel_channel_%s' % fid,
                          *moved(revolve([(U(.275), U(R_M*1.23)), (U(-.116), U(R_M*1.23))],
                                         32, cap0=True, cap1=True), Matrix.Translation((0, U(y), U(z)))), 'dark')
        ob = shoulders[side]
        bpy.context.view_layer.objects.active = ob
        md = ob.modifiers.new('R304 embedded barrel channel', 'BOOLEAN')
        md.operation = 'DIFFERENCE'; md.solver = 'EXACT'; md.object = clearance
        bpy.ops.object.modifier_apply(modifier=md.name)
        tube_clearances[side] = clearance
        for n in (.19, .08, -.035, -.105):
            K.keepouts.append((Vector((U(n), U(y), U(z))), U(.098)))
    HP.rocket_rack = rocket_rack

    # R294: actual cut-out wells, not the old depth=0.004 panels on an uncut shoulder.
    # The kit's Part format keeps the bay in the normal inventory, paint and contract routes.
    for side, fid in ((1, 'Y1'), (-1, 'Y2')):
        n0, n1 = 0.205, -0.180
        nc = (n0 + n1) / 2
        (y0_, z0_), (y1_, z1_) = (shoulder_in(nc), SHOULDER[0][1]), SHOULDER[1]
        yc = 0.408
        nrm = Vector((0.0, side * (z0_ - z1_), (y1_ - y0_))).normalized()
        wid = 0.145
        w, h, d, f = U(n0 - n1), U(wid), U(0.071), U(0.009)
        p = Part('machbay'); p.type = 'machbay'
        def slab(name, mat, x0, x1, y0, y1, z0, z1):
            p.add(name, 'mount', mat, block(x0, x1, (y1-y0)/2, (z1-z0)/2,
                                         min(f*.25, (z1-z0)*.2), yo=(y0+y1)/2, zo=(z0+z1)/2))
        slab('back', 'dark', -w/2, w/2, -h/2, h/2, -d-f, -d)
        for ya, yb in ((-h/2-f, -h/2), (h/2, h/2+f)):
            slab('frame', 'soot2', -w/2-f, w/2+f, ya, yb, -d-f, f)
        for xa, xb in ((-w/2-f, -w/2), (w/2, w/2+f)):
            slab('frame', 'iron', xa, xb, -h/2, h/2, -d-f, f)
        for j, yy in enumerate((-h*.30, h*.06, h*.32)):
            rr = U(.006 if j != 1 else .009)
            p.add('pipe', 'mount', 'steel' if j != 1 else 'iron',
                  moved(revolve([(-w*.46, rr), (w*.45, rr)], 10, cap0=True, cap1=True), Matrix.Translation((0, yy, -d*.46))))
            for xx in (-w*.30, w*.10, w*.32):
                p.add('pipe_collar', 'mount', 'iron', moved(revolve([(xx-f*.25, rr*1.35), (xx+f*.25, rr*1.35)], 10, cap0=True, cap1=True), Matrix.Translation((0, yy, -d*.46))))
        slab('hoist', 'soot', -w*.29, -w*.02, -h*.37, h*.36, -d*.9, -d*.16)
        slab('hoistarm', 'iron', -w*.10, w*.21, -h*.14, h*.08, -d*.27, -d*.13)
        slab('door', 'blood' if side > 0 else 'rust', w*.29, w*.48, -h*.47, h*.47, f, f*1.5)
        for yy in (-h*.29, h*.29):
            slab('hinge', 'iron', w*.28, w*.34, yy-f/2, yy+f/2, f*1.5, f*2)
        pos = Vector((U(nc), side*U(yc), shoulder_top(side, yc, nc)))
        M = HP.frame(pos, (1, 0, 0), nrm)
        # Apply the thin shell before cutting it. The well's own back and walls close the opening.
        ob = shoulders[side]
        bpy.context.view_layer.objects.active = ob
        if ob.modifiers.get('shell'):
            bpy.ops.object.modifier_apply(modifier='shell')
        cutter = K._obj('bay_cut', *moved(block(-w/2, w/2, h/2, d, 0, zo=-d*.35), M), 'dark')
        md = ob.modifiers.new('R294 real bay opening', 'BOOLEAN'); md.operation = 'DIFFERENCE'; md.solver = 'EXACT'; md.object = cutter
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.modifier_apply(modifier=md.name)
        bpy.data.objects.remove(cutter, do_unlink=True)
        # The bay wall also clears the straps, with a real gap rather than
        # coincident boolean faces. Pipe and hoist positions remain unchanged.
        clearance = tube_clearances[side]
        for v in clearance.data.vertices:
            v.co.y = U(side*.495) + (v.co.y-U(side*.495)) * 1.47 / 1.23
            z = U(.059 if side > 0 else .056)
            v.co.z = z + (v.co.z-z) * 1.47 / 1.23
        clearance.data.update()
        bpy.context.view_layer.update()
        # Seat each solid separately before emit merges pieces by material.
        # A merged pipe/collar mesh self-intersects and cannot be cut reliably.
        for component in p.comps:
            ob = K._obj('tube_seat_work', [M @ v for v in component['verts']], component['faces'], 'dark')
            bpy.context.view_layer.objects.active = ob
            md = ob.modifiers.new('R304 tube seat in outer bay wall', 'BOOLEAN')
            md.operation = 'DIFFERENCE'; md.solver = 'EXACT'; md.object = tube_clearances[side]
            bpy.ops.object.modifier_apply(modifier=md.name)
            component['verts'] = [M.inverted() @ v.co for v in ob.data.vertices]
            component['faces'] = [tuple(f.vertices) for f in ob.data.polygons]
            bpy.data.objects.remove(ob, do_unlink=True)
        bpy.data.objects.remove(tube_clearances[side], do_unlink=True)
        K._surface_part(fid, p, tuple(pos), tuple(nrm), (1, 0, 0), 'hoist_bays',
                        'sunken machinery well, pipes and bomb hoist', 'bay', 'picture',
                        'R294: real opening through the shoulder skin, dark floor and walls, three coupled pipes, hoist and hinged partial cover; R304 barrel seat in outer wall')
        c_, r_ = K.keepouts.pop()
        for f_ in (-.43, -.22, 0, .22, .43):
            K.keepouts.append((c_ + Vector((w*f_, 0, 0)), U(.085)))

    # R294: the large round nacelles were omitted when the original sheet interpreted both concept mouths as weapons.
    # R299 keeps these aft-facing drives but reduces radii 19/18 percent and lowers centres by .016/.014 LENGTH,
    # leaving the enlarged forward weapons as the dominant round features in the paint_full view.
    for side, fid, radius in ((1, 'E6', .078), (-1, 'E7', .074)):
        K.engine(fid, (U(-.494), U(side*.489), U(.050 if side > 0 else .046)), U(radius), U(.150), bell=1,
                 kw=dict(craft=True, craft_len=U(.090), seed=6 if side > 0 else 7), inv='nacelles',
                 note='R294: large round aft-facing main drive, dark armoured drum, cooling bands and a red-orange throat; the housing is welded into the shoulder')

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
    K.colour('weathered steel, iron and blood-red salvage patches', U(0.5), U(-0.5), 'R294: the small pale and violet squares reassigned to the existing weathered zones')
    K.colour('red-orange stern engines; dim deep red inside the forward bomb bores, dark collars', U(-0.46), U(-0.5), 'main drives and thruster bank; factions.md: runs dark')

    # ---------------- INSIDE: the magazine rows (the bomber's story), kept small ----------------
    def room(name, kind, n0, n1, y0, y1, z0, z1, note=''):
        K.room(name, kind, U(min(n0, n1)), U(max(n0, n1)), U(y0), U(y1), U(z0), U(z1), note=note)
    feed_notes = []
    for side in (1, -1):
        y = side * 0.42
        room('magazine_%s' % ('p' if side > 0 else 's'), 'magazine', 0.26, -0.1, y - 0.04, y + 0.04, -0.036, 0.014,
             note='the %s bomb row in the shoulder: salvaged bombs racked nose forward, fed by the hoist to the tube' % ('port' if side > 0 else 'starboard'))
        # The existing magazine row feeds a covered lifting cradle at the rear
        # of the long barrel. These hidden parts add no weapon or room.
        nm = 'p' if side > 0 else 's'
        z = .059 if side > 0 else .056
        path = [(-.11, side*.495, z), (-.085, side*.495, -.011), (-.065, side*.42, -.011)]
        for j, (a, b) in enumerate(zip(path, path[1:])):
            a, b = Vector([U(v) for v in a]), Vector([U(v) for v in b])
            M = Matrix.Translation(a) @ (b-a).to_track_quat('X', 'Z').to_matrix().to_4x4()
            K._obj('in_bomb_feed_%s%d' % (nm, j),
                   *moved(revolve([(0, U(.025)), ((b-a).length, U(.025))], 12), M),
                   'iron', inside=True)
        feed_notes.append(dict(kind='note', name='bomb_feed_'+nm,
                             barrel_start=(U(.43), U(side*.495), U(z)),
                             barrel_end=(U(-.11), U(side*.495), U(z)),
                             feed_path=[tuple(U(v) for v in p) for p in path],
                             magazine='magazine_'+nm,
                             note='R304: continuous .54 LENGTH barrel to a covered breech and lifting cradle, ending inside the unchanged magazine row'))
    room('crew', 'crew', -0.258, -0.35, -0.06, 0.06, -0.02, 0.12, note='the pilot and the bombardier under the lip at the top of the ramp, behind the vision slit')
    room('reactor', 'core', -0.04, -0.19, -0.09, 0.09, -0.035, 0.06, note='the drive reactor, under the ramp')
    room('drive_room', 'engroom', -0.37, -0.44, -0.13, 0.13, -0.035, 0.14, note='the drive room and the bank\'s feeds, in the stern housing')
    K.armour('glacis', U(0.008), 'the heaviest plate, over the crew and the bow')
    K.armour('body and shoulders', U(0.004), 'patched plate')
    reach = 0.61
    K.break_line('B-1', U(-0.237), 'the crew and stern block tears from the body at a weld (Hullbreakers: at the seams; only for the recipe\'s records: the game never breaks a craft)',
                 path=[(U(-0.237), U(reach)), (U(-0.237), U(0.2)), (U(-0.229), U(0.12)), (U(-0.245), U(0.04)), (U(-0.23), U(-0.05)), (U(-0.246), U(-0.14)),
                       (U(-0.237), U(-0.2)), (U(-0.237), U(-reach))])
    # Layout writes notes after the break-line rows. Keep those table rows
    # contiguous so the manifest can read the sheet's existing B-1 seam.
    K.inside.extend(feed_notes)
    K.inside.append(dict(kind='note', name='insides', note='A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. The magazine rows are here because the build contract needs an inside (tools/blender/build_sheets/contract.py) and because the magazine is the bomber\'s story; they cost few triangles.'))
    K.point('core', 'hp_core', (U(-0.115), 0.0, U(0.01)))

    # ---------- the patchwork, last: every mount has claimed its keep-out by now ----------
    for nm_, rings_, spec_ in PATCH:
        patchwork(K, HP, nm_, rings_, spec_)
    # The small pale cover on the port bomb drum also read as a loose note (R294).
    # Reassign only this craft's pale material slots to the existing weathered iron zone.
    for ob in K.coll.objects:
        if ob.type == 'MESH':
            for slot in ob.material_slots:
                if slot.material and slot.material.name == 'pale':
                    slot.material = _k.mat('iron')

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('R304 run 3: each bomb mouth continues into a .54 LENGTH hollow barrel, with rear armour laps, four riveted straps and a covered feed to its existing magazine row',
             'Ryan: the tubes must be actual tubes running into the ship. Run 2 stopped the drum after .20 LENGTH. Mouths, bomb noses, bore light, rust-red paint inputs, engines, bays, pipes, rails, taper and plateau stay; only the tube seats relieve the shoulder and outer bay wall')
    K.change('Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as every craft; beam about 1.2 of the length, the render\'s width',
             'docs/playbooks/scale.md, Squadron rows, binding; R273, Ryan, Nov 15: "Wider for sure": the round 3 beam guard (60 to 65 percent) is lifted for this craft. The first sheet held it at 0.61 and read far narrower than the render')
    K.change('R299: two large forward bomb mouths in dark armoured collars, radius .064 LENGTH (was .026), bore .144 LENGTH deep with the bomb nose behind a dim red liner',
             'Ryan R299: the concept and previous build lost their bombing/torpedo-tube read. The lower drums blend into plated corner wedges; actual bores cut those wedges and the shoulder skins. Both bombs T mounts still fire every volley')
    K.change('The tubes are fixed forward in their pods, not on a turning mount',
             'a craft turns onto its target on a strafing run; weapon_match.py FITS bombs: a bomb tube on a launcher (the Board\'s reading of rule 11 for craft); two tubes for the 2 shots, both fire every volley')
    K.change('R294: in shares of LENGTH, the bow narrows from 0.302 half-beam to 0.205 at its toe; the glacis rises to x=-0.035, then stays level to x=-0.355; raised edge frames follow both planes',
             'R275 was interpreted as one slope all the way aft and kept a full-width bow station. That simplified away the concept\'s taper and plateau; R294 restores both')
    K.change('The flank bays are the bomb hoists, one a side in the shoulder\'s sloped top: a heavy frame, a dark back, pipes and the hoist block inside, an armoured door over the fore part',
             'every part has a job (R221): the hoist walks the next bomb from the shoulder\'s magazine row into its tube; on the slope they face the battle camera; the doors carry a two-tone value shift so they survive 32 px (Qwen)')
    K.change('The stern thruster bank is five mismatched salvaged bells, the centre one the largest, in a recess (a hood, cheeks and a sill) in the stern housing',
             'the concept\'s row of stern thrusters; factions.md: mismatched bells with a red-orange glow, one often larger than the rest; the owner\'s rule for craft: nozzle clusters inside armoured blocks')
    K.change('The starboard shoulder sits a touch lower and shorter than the port one; the plating is a patchwork of fewer, bigger, uneven plates of mixed size and angle (rust, dried blood, soot and iron with big trophy patches), laid by the faction kit\'s welded plater, never courses',
             'factions.md: lopsided, bolted, patched; R240 and R275: the patchwork never reads even or in rows. R294 reassigns this craft\'s isolated pale and violet squares to weathered metal and blood red without changing the faction stack')
    K.change('Issue 875 (R289, R292): mixed-size turned plates and welded laps, bedded close to the skin; dark iron and weathered rust red from the faction stack',
             'The first patchwork proof still read as clean salmon slabs. The craft-only bright palette and reduced dirt hid its seams and wear; thicker relief made the small patches stand off the hull')
    K.change('R299: two smaller and lower round main drives aft, plus the unchanged five stern thrusters; the two enlarged forward bomb tubes remain the only weapons',
             'R294 restored the drives. R299 reduces their radii from .096/.090 to .078/.074 LENGTH and lowers centres from .066/.060 to .050/.046. Forward weapons have straight red-lined bores; stern drives have orange flared throats and glowing plugs')
    K.change('R294: the nacelle drums end aft of B-1; the same ragged seam extends to the shoulders\' full beam',
             'a drive must ride whole with its piece (R226). The first long nacelle drum crossed the seam; shortening its mounting drum keeps the engine whole without moving the existing inside rooms')
    K.change('R294: the side machinery bays are cut through the shoulder skin, with sunken floors, coupled pipes, hoists and partial hinged doors',
             'The old machbay depth of 0.004 length and the uncut skin made the pipes look like flat slats on a panel. The openings now have actual depth and their own dark lining')
    K.change('R294: isolated small pale and violet plate zones become weathered steel and blood red; the little pale bomb-drum cover becomes iron',
             'Ryan named the remaining light grey and purple squares as stuck-on notes. The PR 898 craft paint stack, its geometry masks, wear and colours are unchanged; only this design\'s zone assignments change')
    K.change('R299: larger armour plates, 85 percent rust/blood zone weight (was 49 percent); main body and shoulders use rust underpaint',
             'Ryan asked for the concept\'s rust red and a minority of grey trophies. Only KB1CC plate sizes, material weights and skin zones change; the PR 898 faction stack, worn rims and dark seams stay intact')
    K.change('No dishes, claws, antennas, lamps or hangar', 'below what the battle camera shows on a 3.84 unit craft, and nothing hangs off (factions.md); bold and simple')
    K.change('A small inside: two magazine rows in the shoulders, the crew cell, the reactor, the drive room; one seam (B-1)',
             'the game shows a craft\'s death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam')
    K.open_item('The rust, soot, trophy colours and the red running lights are the Hullbreaker paint stack (tools/blender/kits/hullbreakers/stack.py), applied later')
    K.open_item('How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here')
