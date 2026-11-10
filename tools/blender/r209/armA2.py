# Issue 209 round 2, Arm A: structure first (Ryan on round 1, FINDINGS R140: "the hand built shape doesn't actually fully align.
# There's so much less variety in the shape and structure of it, so it's not just adding but almost removal").
# The massing is traced from B0's whole-hull generation (yaw fixed in round 2, see common.ai_align) and the concept views, block by
# block, keeping the concept's variety: the deep blunt bow block with its raised glacis, the tall side sponsons and lower module
# blocks at midship, the tiered superstructure, the low aft body on twin ventral rails with flank module blocks, the stacked stern
# modules, the twin ventral fins under the bow. Dropped: naval tells only (lattice masts become a sensor array and radiators,
# railings left off, the single chin fin becomes twin canted fins with sensor pods) and melted AI surface.
# Space, not naval: flat bellies with chines, no keel, no raked stem, guns forward or out, matched pairs.
# usage: blender -b -P armA2.py -- OUT_DIR RUNG       RUNG 0 = structure only (the massing compare), 2 = round 2 detail rung
import os, sys, math, json, time, random
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import common as C
import bpy, bmesh
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import loft, frustum, box, cyl

# Break structure for round 2 (authored on the structural joints): bow block | midship (split lengthwise) | aft body
BREAK = dict(t_lines=(.178, -.125), l_line=(-.045, -.125, .178), decks=(-.100, -.035))

# Core hull stations: x, deck half-width, deck z, flank half-width, chine z, belly half-width, belly z (bow is +x).
# Measured off B0 (yaw fixed) by ray casts every 0.005, symmetrised (B0 is lopsided: its bow leans to port), squared off.
CORE = [(.500, .030, -.030, .036, -.072, .024, -.098), (.490, .046, -.012, .052, -.082, .036, -.114), (.475, .052, -.004, .059, -.090, .042, -.126),
        (.450, .069, .010, .078, -.096, .056, -.141), (.420, .087, .018, .096, -.101, .068, -.152), (.390, .100, .022, .110, -.105, .078, -.160),
        (.350, .112, .024, .121, -.108, .086, -.164), (.300, .121, .025, .129, -.110, .092, -.166), (.240, .127, .026, .134, -.112, .096, -.168),
        (.185, .130, .027, .137, -.115, .098, -.171), (.120, .130, .028, .138, -.118, .100, -.176), (.000, .128, .028, .136, -.118, .100, -.177),
        (-.090, .124, .028, .132, -.115, .098, -.172), (-.110, .122, .028, .130, -.108, .096, -.160), (-.128, .112, .028, .118, -.050, .086, -.074),
        (-.250, .108, .028, .114, -.048, .084, -.072), (-.340, .102, .028, .108, -.046, .082, -.070), (-.352, .100, .028, .106, -.040, .082, -.056),
        (-.470, .096, .028, .102, -.038, .080, -.054), (-.500, .092, .026, .098, -.036, .076, -.050)]

def sec(s):
    x, wd, zt, wc, zc, wb, zb = s
    half = [(wd, zt), (wc, zt - .012), (wc, zc), (wb, zb)]
    return (x, [(0, zt)] + half + [(0, zb)] + [(-y, z) for y, z in reversed(half)])

def at(x):
    for a, b in zip(CORE, CORE[1:]):
        if b[0] <= x <= a[0]:
            t = (x - b[0]) / (a[0] - b[0]); return tuple(b[i] + (a[i] - b[i]) * t for i in range(7))
    return CORE[0] if x > CORE[0][0] else CORE[-1]

GUNS = []
def gun(name, base, d, L, r):
    d = Vector(d).normalized(); GUNS.append((name, d)); hs_lib.barrel(name, base, d, L, r)

def tag(r, since, kind=None):
    for o in hs_lib.PARTS[since:]:
        o['role'] = r
        if kind: o['kind'] = kind

def mloop(half, ztop, zbot):
    return [(0, ztop)] + half + [(0, zbot)] + [(-y, z) for y, z in reversed(half)]

def trap(x, wb, wt, zb, zt, c=.004):
    """a mirrored block section: bottom half-width wb at zb, top half-width wt at zt, chamfer c on the top edge"""
    return (x, mloop([(wt - c, zt), (wt, zt - c), (wb, zb)], zt, zb))

def side(x, yi, yo, zb, zt, c=.008, s=1):
    """an off-centre block section on side s: inner face at yi, outer at yo, chamfered outer corners"""
    pts = [(yi, zt), (yo - c, zt), (yo, zt - c), (yo, zb + c), (yo - c, zb), (yi, zb)]
    return (x, [(s * y, z) for y, z in (pts if s > 0 else list(reversed(pts)))])

def hull_obj(o, kind):
    o['role'] = 'hull'; o['kind'] = kind; hs_lib.PARTS.remove(o); return o

# ------------------------------------------------------------------------------------------------ structure (the massing)
def structure():
    """every hull block of the corrected massing; returns the hull objects (role hull, used by the break structure and paint)"""
    H = []
    o = loft('core', [sec(s) for s in reversed(CORE)], bevel=.003); H.append(hull_obj(o, 'core'))
    # bow: raised glacis on the centreline, sloped front face, carries the twin bow guns
    o = loft('glacis', [trap(.398, .058, .046, .020, .030, .002), trap(.384, .064, .056, .020, .052), trap(.300, .071, .061, .021, .060),
                        trap(.222, .078, .067, .022, .068)], bevel=.002); H.append(hull_obj(o, 'glacis'))
    for s in (1, -1):
        # midship sponsons: the tall side block (rounded leading edge, top just above the bow deck) and a lower module block behind it
        o = loft(f'sponson{s}', [side(.176, .10, .150, -.118, .032, .012, s), side(.168, .10, .172, -.132, .042, .012, s),
                                 side(.020, .10, .178, -.136, .044, .010, s), side(.014, .10, .170, -.128, .036, .010, s)], bevel=.002)
        H.append(hull_obj(o, 'sponson'))
        o = loft(f'module{s}', [side(.006, .10, .160, -.124, .004, .010, s), side(.000, .10, .168, -.126, .010, .010, s),
                                side(-.098, .10, .168, -.122, .010, .010, s), side(-.106, .10, .156, -.112, .002, .010, s)], bevel=.002)
        H.append(hull_obj(o, 'module'))
        # aft body: twin ventral rails (the concept's dark underside spines) with the channel between them
        o = loft(f'rail{s}', [side(-.092, .040, .080, -.070, -.064, .004, s), side(-.110, .038, .084, -.122, -.064, .006, s),
                              side(-.330, .038, .084, -.122, -.064, .006, s), side(-.346, .040, .080, -.074, -.064, .004, s)], bevel=.002)
        H.append(hull_obj(o, 'rail'))
    # tiered superstructure: deckhouse tier, upper tier, tower (the command tower carries the bridge and the sensor array)
    o = loft('tier1', [trap(.176, .070, .060, .027, .040, .004), trap(.166, .088, .080, .027, .062), trap(-.088, .084, .076, .027, .062),
                       trap(-.098, .072, .064, .027, .050, .004)], bevel=.002); H.append(hull_obj(o, 'tier'))
    o = loft('tier2', [trap(.128, .052, .046, .060, .082, .004), trap(.118, .060, .054, .060, .094), trap(.010, .060, .054, .060, .094),
                       trap(.002, .054, .048, .060, .086, .004)], bevel=.002); H.append(hull_obj(o, 'tier'))
    # aft deck: a low dorsal spine; stern: stacked modules (full-width lower block, upper block)
    o = loft('spine', [trap(-.136, .046, .036, .027, .040, .003), trap(-.146, .052, .046, .027, .050), trap(-.330, .052, .046, .027, .050),
                       trap(-.340, .046, .036, .027, .040, .003)], bevel=.002); H.append(hull_obj(o, 'spine'))
    o = loft('stern1', [trap(-.350, .074, .062, .027, .050, .004), trap(-.362, .086, .080, .027, .068), trap(-.492, .086, .080, .027, .068)],
             bevel=.002); H.append(hull_obj(o, 'stern'))
    o = loft('stern2', [trap(-.374, .046, .036, .066, .080, .004), trap(-.384, .054, .048, .066, .094), trap(-.468, .054, .048, .066, .094),
                        trap(-.474, .050, .044, .066, .090, .003)], bevel=.002); H.append(hull_obj(o, 'stern'))
    for o in H:
        bpy.context.view_layer.objects.active = o; o.select_set(True)
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
        o.select_set(False)
    return H

def top_z(x, y=0.0):
    """deck height of the structure at (x, y), by the block tables (for seating parts)"""
    z = at(x)[2]
    if .222 <= x <= .398 and abs(y) < .065: z = .030 + (.068 - .030) * min(1, (.398 - x) / .03) if x > .368 else .052 + (.068 - .052) * (.384 - x) / .162
    if -.088 <= x <= .166 and abs(y) < .080: z = .062
    if .002 <= x <= .118 and abs(y) < .054: z = .094
    if .02 <= x <= .168 and .10 <= abs(y) <= .17: z = .044
    if -.098 <= x <= 0 and .10 <= abs(y) <= .16: z = .010
    if -.33 <= x <= -.146 and abs(y) < .046: z = .050
    if -.492 <= x <= -.362 and abs(y) < .080: z = .068
    if -.468 <= x <= -.384 and abs(y) < .048: z = .094
    return z

# ------------------------------------------------------------------------------------------------ hard-point parts (shared layout)
def drum(nm, x, y, z, r, L, rung):
    n0 = len(hs_lib.PARTS); cyl(nm, (x, y, z), r, L, axis='X', seg=28, bevel=.0015)
    if rung >= 1:
        for k, xx in enumerate((x - L * .3, x + L * .3)): cyl(f'{nm}band{k}', (xx, y, z), r * 1.04, L * .06, axis='X', seg=28, bevel=0)
        tag('trim', n0 + 1)
        n1 = len(hs_lib.PARTS); cyl(f'{nm}bore', (x + L / 2 + .0005, y, z), r * .72, .002, axis='X', seg=24, bevel=0); tag('dark', n1)
    if rung >= 2:  # round 2 rung: a capped nose ring, feed line and lifting lugs on each drum
        cyl(f'{nm}nose', (x + L / 2 - .002, y, z), r * 1.06, .004, axis='X', seg=28, bevel=.0005)
        cyl(f'{nm}tail', (x - L / 2 - .002, y, z), r * .55, .006, axis='X', seg=20, bevel=.0008)
        for xx in (x - L * .15, x + L * .15): box(f'{nm}lug{xx:.3f}', (xx, y, z + r), (.006, .004, .004), bevel=.0006)
    for k, xx in enumerate((x - L * .3, x + L * .3)):  # cradle saddles down to the deck below
        zt = top_z(xx, y); box(f'{nm}saddle{k}', (xx, y, (z - r * .6 + zt) / 2), (L * .10, r * 1.6, max(.004, z - r * .6 - zt + .006)), bevel=.001)

def casemate(i, x, s, rung, ai=False):
    """octagonal casemate plate on the bow flank with a ball mount and twin barrels aimed forward and out"""
    fw = at(x)[3]; y = s * (fw + .002); z = -.046
    n0 = len(hs_lib.PARTS); cyl(f'cplate{i}{s}', (x, y, z), .036, .008, axis='Y', seg=8, bevel=.0015); tag('trim', n0)
    cyl(f'cring{i}{s}', (x, y + s * .006, z), .024, .006, axis='Y', seg=24, bevel=.001)
    cyl(f'cball{i}{s}', (x, y + s * .013, z), .017, .015, axis='Y', seg=24, bevel=.004)
    d = Vector((.55, s * .83, .05))
    for k in (-1, 1): gun(f'cgun{i}{s}{k}', Vector((x, y + s * .015, z + k * .007)), d, .060, .0046)
    if rung >= 2:
        for a in range(8):  # bolt heads round the octagon and a shutter lip over the mount
            t = (a + .5) * math.pi / 4; box(f'cbolt{i}{s}{a}', (x + .031 * math.cos(t), y + s * .005, z + .031 * math.sin(t)), (.004, .003, .004), bevel=.0005)
        box(f'clip{i}{s}', (x, y + s * .010, z + .024), (.040, .010, .004), bevel=.0008)

def parts(rung):
    """hand-built parts at the shared hard points. rung 0: envelopes only (the massing compare); 1 and up: round 1 kit; 2: round 2 rung"""
    P = hs_lib.PARTS; ai_slots = {}
    # bow guns on the glacis front
    for s in (1, -1):
        box(f'bowmount{s}', (.384, s * .030, .060), (.024, .022, .018), bevel=.002)
        gun(f'bowgun{s}', (.392, s * .030, .062), (1, 0, 0), .075, .0062)
        if rung >= 2: cyl(f'bowshroud{s}', (.405, s * .030, .062), .0105, .022, axis='X', seg=20, bevel=.001)
    for i, x in enumerate((.368, .248)):
        for s in (1, -1): casemate(i, x, s, rung)
    # command tower on the upper tier, bridge, sensor array (replaces the lattice mast)
    n0 = len(P); cyl('tower', (.058, 0, .094 + .030), .034, .060, seg=32, bevel=.003); tag('part', n0, 'tower')
    if rung >= 1:
        n0 = len(P); cyl('towerband', (.058, 0, .094 + .046), .0355, .007, seg=32, bevel=0); tag('trim', n0)
    box('bridge', (.068, 0, .094 + .068), (.058, .070, .022), bevel=.003)
    n0 = len(P); box('bridgeglass', (.098, 0, .094 + .070), (.004, .056, .007), bevel=.0005); tag('dark', n0)
    import barge_shapes as B
    B.antenna_array(.058, 0, .094 + .079, h=.080)
    # missile drums: a pair on the deckhouse tier ahead of the tower, a pair on each sponson, one on each aft module, a pair on the aft deck
    for s in (1, -1): drum(f'fdrum{s}', .146, s * .040, .062 + .017, .016, .040, rung)
    for s in (1, -1):
        for k, yy in enumerate((.124, .156)): drum(f'sdrum{s}{k}', .092, s * yy, .044 + .016, .0145, .085, rung)
        drum(f'mdrum{s}', -.050, s * .134, .010 + .019, .018, .080, rung)
    for s in (1, -1): drum(f'adrum{s}', -.290, s * .070, .028 + .015, .014, .060, rung)
    # stern: radiators on the upper stern module (replace the aft lattice mast); engines on the stern face
    B.radiator_pair(-.426, 0, .094, n=2, L=.070, H=.046)
    for nm, (y, z, r) in (('main', (0, -.013, .030)), ('portb', (.056, -.012, .020)), ('stbdb', (-.056, -.012, .020)),
                          ('upp', (.040, .047, .012)), ('ups', (-.040, .047, .012))):
        B.engine_bell((-.492 if z < .03 else -.488, y, z), r, .040 if r > .015 else .026, axis_dir=Vector((-1, 0, 0)))
        n0 = len(P); cyl(f'glow{nm}', (-.522 if z < .03 else -.512, y, z), r * .9, .002, axis='X', seg=28, bevel=0); tag('glow', n0)
    # flank module blocks on the aft body (the concept's cargo blocks), a matched pair
    for s in (1, -1):
        n0 = len(P); loft(f'cargo{s}', [side(-.146, .100, .150, -.092, -.016, .008, s), side(-.154, .100, .158, -.108, -.010, .008, s),
                                         side(-.292, .100, .158, -.108, -.010, .008, s), side(-.300, .100, .150, -.092, -.016, .008, s)], bevel=.002)
        tag('part', n0, 'cargo')
        for xx in (-.170, -.275): box(f'cargoarm{s}{xx}', (xx, s * .104, -.004), (.016, .012, .016), bevel=.001)
        if rung >= 1:
            for k in range(7): box(f'cargorib{s}{k}', (-.160 - k * .012, s * .159, -.059), (.005, .004, .090), bevel=0)
        if rung >= 2:
            for k in range(5): box(f'cargorib2{s}{k}', (-.244 - k * .010, s * .159, -.059), (.004, .004, .090), bevel=0)
            box(f'cargohatch{s}', (-.236, s * .159, -.054), (.020, .003, .060), bevel=.0006)
    # twin canted ventral fins under the bow with sensor pods at the tips (the concept's chin fin, made space-side: two fins, no keel)
    for s in (1, -1):
        n0 = len(P); R = Matrix.Rotation(math.radians(s * -18), 3, 'X')
        bm = bmesh.new(); prof = [(.402, -.150), (.288, -.160), (.300, -.232), (.360, -.236)]
        vs = [[bm.verts.new(Vector((x, s * .040, 0)) + R @ Vector((0, k * .005, z + .150)) + Vector((0, 0, -.150))) for x, z in prof] for k in (-1, 1)]
        bm.faces.new(vs[0][::-1]); bm.faces.new(vs[1])
        for i in range(4): bm.faces.new((vs[0][i], vs[0][(i + 1) % 4], vs[1][(i + 1) % 4], vs[1][i]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces); hs_lib._obj(f'vfin{s}', bm, .0015)
        tip = Vector((.330, s * .040, 0)) + R @ Vector((0, 0, -.084)) + Vector((0, 0, -.150))
        cyl(f'vpod{s}', tip, .009, .060, axis='X', seg=16, r2=.007, bevel=.001)
        tag('part', n0, 'fin')
    # ventral thruster pods on the aft rails
    for s in (1, -1):
        cyl(f'vthr{s}', (-.300, s * .060, -.132), .012, .050, axis='X', seg=20, bevel=.002)
        box(f'vthrpylon{s}', (-.300, s * .060, -.124), (.030, .008, .008), bevel=.001)

def detail(S, hard, rung):
    """surface detail on the corrected structure. rung 1 is round 1's count; rung 2 roughly doubles it (plates, accents, vents, hatches)"""
    import detail_lib as D
    Sf = D.Surface(S, hard); r = random.Random(209); base = lambda p: (.1, .04, .02); tg = lambda rgb: None
    k = 2 if rung >= 2 else 1
    big = [(.6, (.05, .09), (.030, .055)), (.4, (.030, .055), (.020, .036))] if k == 2 else [(.6, (.06, .10), (.035, .060)), (.4, (.035, .06), (.025, .040))]
    for s_ in (1, -1):
        D.scatter_plates(Sf, tg, lambda r_: Vector((r_.uniform(-.48, .46), s_ * .6, r_.uniform(-.13, .03))), Vector((0, -s_, 0)), lambda n: abs(n.y) > .5,
                         base, r, True, 16 * k, big, th=.0026, kinds=(('rect', .45), ('chamfer', .35), ('slant', .20)), name=f'fl{s_}_')
    D.scatter_plates(Sf, tg, lambda r_: Vector((r_.uniform(-.48, .44), r_.uniform(-.16, .16), .5)), Vector((0, 0, -1)), lambda n: n.z > .6,
                     base, r, True, 18 * k, big, th=.0026, kinds=(('rect', .4), ('chamfer', .35), ('trap', .25)), name='top')
    D.scatter_plates(Sf, tg, lambda r_: Vector((r_.uniform(-.48, .44), r_.uniform(-.15, .15), -.6)), Vector((0, 0, 1)), lambda n: n.z < -.6,
                     base, r, True, 10 * k, big, th=.0030, kinds=(('rect', .5), ('chamfer', .5)), name='belly')
    for s_ in (1, -1):
        D.accents(Sf, tg, lambda r_: Vector((r_.uniform(-.46, .42), s_ * .6, r_.uniform(-.12, .03))), Vector((0, -s_, 0)), lambda n: abs(n.y) > .6, r, 8 * k, name=f'acc{s_}_')
    if rung >= 2:
        D.accents(Sf, tg, lambda r_: Vector((r_.uniform(-.46, .40), r_.uniform(-.14, .14), .5)), Vector((0, 0, -1)), lambda n: n.z > .7, r, 14, name='acct_')
        # sponson faces: vertical armour seams and a vent bank; module faces: access hatches
        for s_ in (1, -1):
            for xx in (.130, .090, .050): box(f'spseam{s_}{xx}', (xx, s_ * .1785, -.046), (.003, .002, .150), bevel=0)
            hs_lib.vents(f'spvent{s_}', (.120, s_ * .179, .010), 6, .003, .010, .008)
            for xx in (-.020, -.070): box(f'mhatch{s_}{xx}', (xx, s_ * .1685, -.060), (.026, .002, .034), bevel=.0006)
            for xx in (-.200, -.260): box(f'railplate{s_}{xx}', (xx, s_ * .060, -.1225), (.040, .040, .002), bevel=.0005)
        # deck runs: pipe bundle along the aft spine, hatches on the bow deck
        for yy in (-.030, .030): D.tube(f'spinepipe{yy}', Vector((-.150, yy, .052)), Vector((-.325, yy, .052)), .0028)
        for xx in (.430, .200): box(f'bowhatch{xx}', (xx, .090 if xx > .3 else -.095, at(xx)[2] + .001), (.022, .016, .003), bevel=.0006)

def build(out, rung, cell=None, hull_detail=True, before_paint=None):
    t0 = time.time(); bpy.ops.wm.read_factory_settings(use_empty=True); hs_lib.PARTS.clear(); GUNS.clear()
    C.set_break(**BREAK)
    S = structure(); parts(rung)
    if before_paint: S = before_paint.prepare(S)
    hard = list(hs_lib.PARTS)
    for o in hard:
        if 'role' not in o: o['role'] = 'part'
    n0 = len(hs_lib.PARTS)
    if rung >= 1 and hull_detail: detail(S, [o for o in hard if not o.name.startswith('glow')], rung)
    for o in hs_lib.PARTS[n0:]: o['role'] = 'part'
    for o in hs_lib.PARTS:
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    allparts = list(hs_lib.PARTS)
    au = C.audit(S, [o for o in hard if not o.name.startswith('glow')], GUNS)
    made, notes = C.breakable(S)
    C.paint(S + allparts + made, S)
    extra = before_paint.finish(S) if before_paint else {}
    rep = C.report(S + allparts + made)
    hull_t = sum(C.tris(o) for o in S)
    cell = cell or ('A2s' if rung == 0 else 'A2')
    meta = dict(cell=cell, route='hand build, structure traced from B0 (yaw fixed) and the concept', rung=rung, build_seconds=round(time.time() - t0, 1),
                audit=au, break_fit=notes, break_lines=BREAK, hull_blocks=len(S), hull_triangles_with_skin=hull_t, hand_parts=len(hard),
                detail_parts=len(allparts) - len(hard), **extra, **rep)
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f'{cell}.blend'))
    json.dump(meta, open(os.path.join(out, f'{cell}.json'), 'w'), indent=1); print('[209]', cell, json.dumps(meta)[:1500], flush=True)

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    build(a[0], int(a[1]) if len(a) > 1 else 2)
