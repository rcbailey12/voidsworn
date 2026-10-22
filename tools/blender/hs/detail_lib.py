# Reusable surface-detail and weathering pass for the clean hand-built ships (owner, Oct 22 2026: "we do need to add a lot more detail
# across the board... plane seams, small vents, pipes, variation in paint and rust, weathered details... bumps, divots, damage and repairs...
# less like pieces bolted on and more like a cohesive ship, and then the jankiness associated with Corsair... like ork ships or reavers").
# Owner picks: Corsair heavy ork/Reaver jank, moderate battle damage, mixed detail (real 3D for plates, pipes, vents, patches, girders;
# paint for dents' grime, scorch and scratches), built as a kit every ship can use.
#
# What it adds, laid out on a grid over the hull's own surface (ray casts), never on top of an existing part:
#   - plating: raised and inset plates of slightly different heights and tones, so the hull reads as many plates with real seams;
#   - repairs: welded patch plates with weld beads, a few degrees off square (Corsair: salvaged plates in mismatched colours);
#   - pipe runs with brackets along the flanks, breaking around parts; junction boxes where they end; vent grilles; small greebles;
#   - mount flanges where big parts meet the hull, so they look built in rather than stuck on;
#   - dents (real geometry, pushed into the hull) and moderate battle damage;
#   - Corsair only: spikes, scrap armour welded on at angles, exposed girder sections, hazard-striped plates, lopsided placement.
# Non-Corsair ships are mirrored (same choice on both sides); Corsair picks each side separately.
import math, random, bpy, bmesh
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
import hs_lib

def bvh_of(objs):
    bm = bmesh.new(); dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        oe = o.evaluated_get(dg); me = oe.to_mesh(); t = bmesh.new(); t.from_mesh(me); t.transform(o.matrix_world)
        tm = bpy.data.meshes.new('tmp'); t.to_mesh(tm); t.free(); bm.from_mesh(tm); bpy.data.meshes.remove(tm); oe.to_mesh_clear()
    b = BVHTree.FromBMesh(bm); bm.free(); return b

def frame(n, along=Vector((1, 0, 0))):
    n = n.normalized(); t = along - n * along.dot(n)
    if t.length < 1e-4: t = Vector((0, 1, 0)) - n * n.y
    t.normalize(); b = n.cross(t); return t, b, n

def obox(name, c, t, b, n, size, bevel=.0005, rot=0.):
    """box centred at c, local axes t (length), b (width), n (thickness), optionally spun by rot radians about n"""
    if rot:
        R = Matrix.Rotation(rot, 3, n); t = R @ t; b = R @ b
    M = Matrix((t, b, n)).transposed().to_4x4(); bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts); bmesh.ops.transform(bm, matrix=M, verts=bm.verts); bmesh.ops.translate(bm, verts=bm.verts, vec=c)
    return hs_lib._obj(name, bm, bevel, seg=1)

def tube(name, a, b_, r, seg=10):
    d = (b_ - a); L = d.length
    if L < 1e-5: return None
    R = d.normalized().to_track_quat('X', 'Z').to_matrix(); return hs_lib.cyl(name, (a + b_) / 2, r, L, axis='X', seg=seg, rot=R, bevel=0)

class Surface:
    """the hull surfaces details may sit on (targets) and everything they must keep clear of (parts)"""
    def __init__(self, targets, parts):
        self.T = bvh_of(targets); self.P = bvh_of(parts) if parts else None
    def hit(self, o, d, clear):
        h = self.T.ray_cast(o, d, 2.0)
        if h[0] is None: return None, None
        if self.P is not None:
            hp = self.P.ray_cast(o, d, 2.0)
            if hp[0] is not None and (hp[0] - o).length < (h[0] - o).length + .001: return None, None  # a part is in front
            q = self.P.find_nearest(h[0], clear)
            if q[0] is not None: return None, None  # too close to a part
        n = Vector(h[1]).normalized(); n = n if n.dot(-d) > 0 else -n; return Vector(h[0]), n

PAL = dict(steel=(.13, .13, .14), dark=(.03, .03, .033), gun=(.07, .07, .075), rust=(.14, .05, .02), weld=(.20, .17, .14),
           salvage=[(.33, .24, .03), (.11, .11, .12), (.06, .085, .05), (.16, .09, .05), (.08, .10, .13), (.30, .30, .28)],
           hazard=((.40, .30, .02), (.02, .02, .02)), bare=(.17, .165, .16), belly=(.06, .06, .065))

# ---------------------------------------------------------------------------------------------------------------------------------------
# v14 plating (owner, Oct 22: "it's always squares and some of the squares run over the ship edge instead of being cut to match... the
# squares are all kind of in a pattern/orderly, especially on the underside of the prow... the linework through the plates is all the same").
# Plates are now cut in mixed shapes (rectangles, cut corners, trapezoids, L-shapes, slanted sheets), scattered rather than gridded, bent to
# follow the hull (every vertex is projected onto the surface) and trimmed where the hull turns away, so nothing overhangs an edge. Each plate
# gets its own edge treatment: plain, a weld bead, a rivet row, or both. The belly gets fewer, bigger, scorched armour slabs.
def outline(kind, w, h, r):
    W, H = w / 2, h / 2
    if kind == 'chamfer':
        c = min(w, h) * r.uniform(.18, .38); pts = [(-W, -H), (W - c, -H), (W, -H + c), (W, H), (-W + c, H), (-W, H - c)]
        if r.random() < .5: pts = [(-W, -H), (W - c, -H), (W, -H + c), (W, H), (-W, H)]
        return pts
    if kind == 'trap':
        k = r.uniform(.55, .85); o = r.uniform(-.25, .25) * w; return [(-W, -H), (W, -H), (W * k + o, H), (-W * k + o, H)]
    if kind == 'L':
        nx, ny = w * r.uniform(.35, .55), h * r.uniform(.35, .55); sx, sy = r.choice((1, -1)), r.choice((1, -1))
        pts = [(-W, -H), (W, -H), (W, H - ny), (W - nx, H - ny), (W - nx, H), (-W, H)]
        return [(x * sx, y * sy) for x, y in pts] if sx * sy > 0 else [(x * sx, y * sy) for x, y in reversed(pts)]
    if kind == 'slant':
        sh = h * r.uniform(-.4, .4); return [(-W - sh / 2, -H), (W - sh / 2, -H), (W + sh / 2, H), (-W + sh / 2, H)]
    return [(-W, -H), (W, -H), (W, H), (-W, H)]

def conform_plate(S, name, p, n, t, b, pts, lift, th, seg=.008, keep=.55, clear=.0016):
    """a plate cut to the outline pts (local t/b units), bent onto the target surface and trimmed where it would overhang. Returns the
    trimmed outline as surface points (for beads and rivets) or None when too little of it sits on the hull."""
    bm = bmesh.new(); vs = [bm.verts.new(p + t * u + b * v) for u, v in pts]
    try: f = bm.faces.new(vs)
    except Exception: bm.free(); return None
    bmesh.ops.triangulate(bm, faces=[f]); L_ = max(max(u for u, v in pts) - min(u for u, v in pts), max(v for u, v in pts) - min(v for u, v in pts))
    cuts = max(1, min(6, int(L_ / seg))); bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True)
    bmesh.ops.triangulate(bm, faces=bm.faces[:]); bad = set()
    for v in bm.verts:
        o = v.co + n * .03; h = S.T.ray_cast(o, -n, .07)
        if h[0] is None: bad.add(v); continue
        hn = Vector(h[1]).normalized(); hn = hn if hn.dot(n) > 0 else -hn
        if hn.dot(n) < .62 or (Vector(h[0]) - v.co).length > .018: bad.add(v); continue
        if S.P is not None and S.P.find_nearest(Vector(h[0]), clear)[0] is not None: bad.add(v); continue
        v.co = Vector(h[0]) + hn * lift
    nf = len(bm.faces); dead = [f_ for f_ in bm.faces if any(v in bad for v in f_.verts)]
    if len(dead) > nf * (1 - keep): bm.free(); return None
    bmesh.ops.delete(bm, geom=dead, context='FACES'); bmesh.ops.dissolve_degenerate(bm, dist=2e-5, edges=bm.edges[:]); loose = [v for v in bm.verts if not v.link_faces]
    if loose: bmesh.ops.delete(bm, geom=loose, context='VERTS')
    for f_ in bm.faces:
        if f_.normal.dot(n) < 0: f_.normal_flip()
    edge = [(e.verts[0].co.copy(), e.verts[1].co.copy()) for e in bm.edges if e.is_boundary]
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    sm = o.modifiers.new('sd', 'SOLIDIFY'); sm.thickness = th; sm.offset = -1; sm.use_even_offset = False; sm.use_rim = True  # even offset blew a folded sliver out to 2 m (v14)
    bv = o.modifiers.new('bv', 'BEVEL'); bv.width = min(.0004, th * .3); bv.segments = 1; bv.limit_method = 'ANGLE'; bv.angle_limit = math.radians(40)
    hs_lib.PARTS.append(o); return edge

def edge_dress(name, edge, n, style, r, cen):
    """weld bead and/or rivets along a plate's trimmed edge, built as one mesh per plate; style: 0 plain, 1 bead, 2 rivets, 3 both"""
    if style == 0 or not edge: return 0
    bm = bmesh.new(); k = 0; Rn = Vector((0, 0, 1)).rotation_difference(n).to_matrix().to_4x4()
    if style in (1, 3):
        for a, b_ in edge:
            d = b_ - a; L_ = d.length
            if L_ < 1e-5 or r.random() < .12: continue  # broken weld
            M = Matrix.Translation((a + b_) / 2 + n * .0004) @ d.normalized().to_track_quat('Z', 'Y').to_matrix().to_4x4()
            bmesh.ops.create_cone(bm, cap_ends=False, segments=5, radius1=.00065, radius2=.00065, depth=L_ * 1.05, matrix=M); k += 1
    if style in (2, 3):
        acc, step = 0., r.uniform(.0035, .006)
        for a, b_ in edge:
            d = (b_ - a); L_ = d.length
            while acc < L_:
                q = a + d * (acc / max(L_, 1e-9)); q = q + (cen - q).normalized() * .0016
                if r.random() > .1: bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=.0007, radius2=.0006, depth=.001, matrix=Matrix.Translation(q + n * .0003) @ Rn); k += 1
                acc += step
            acc -= L_
    if k: hs_lib._obj(name, bm, 0)
    else: bm.free()
    return k

def scatter_plates(S, tag, region, ray, accept, base_col, r, corsair, count, sizes, th=.0018, kinds=None, slab=False, tint=None, name='sp'):
    """region: callable(rnd)->ray origin; ray: direction; accept(n): bool. sizes: [(weight, (w0,w1), (h0,h1))]"""
    kinds = kinds or ((('rect', .30), ('chamfer', .22), ('trap', .14), ('L', .16), ('slant', .18)) if corsair else (('rect', .55), ('chamfer', .3), ('trap', .15)))
    placed = []; made = 0; tries = 0; tot = sum(w for w, _, _ in sizes)
    while made < count and tries < count * 12:
        tries += 1; u = r.uniform(0, tot)
        for wgt, wr, hr in sizes:
            if u <= wgt: break
            u -= wgt
        w, h = r.uniform(*wr), r.uniform(*hr); rad = math.hypot(w, h) * .42
        o = region(r); p, n = S.hit(o, ray, .002)
        if p is None or not accept(n): continue
        lay = 0; ok = True
        for q, rq, lq in placed:
            d = (q - p).length
            if d < (rad + rq) * (.55 if corsair else .8): ok = False; break   # too much on top of another plate
            if d < (rad + rq) * .95: lay = max(lay, lq + 1)                  # partly overlapping: sits on top of it
        if not ok or lay > 2: continue
        t, b, n = frame(n, Vector((1, 0, 0)))
        rot = math.radians(r.uniform(-14, 14) if corsair else r.uniform(-2, 2)); R = Matrix.Rotation(rot, 3, n); t, b = R @ t, R @ b
        kw = r.uniform(0, sum(k[1] for k in kinds))
        for kind, kp in kinds:
            if kw <= kp: break
            kw -= kp
        lift = -.0003 + lay * th * .9  # the bottom sits just inside the hull: no light gap under the plate
        edge = conform_plate(S, f'{name}{made}', p, n, t, b, outline(kind, w, h, r), lift + th, th)
        if edge is None: continue
        bc = base_col(p)
        if tint: col = tint(p, r)
        elif corsair and r.random() < .10: col = tuple(a * .65 + b * .35 for a, b in zip(r.choice(PAL['salvage']), bc))  # mismatched salvage, but not black holes
        elif r.random() < .08: col = PAL['bare']
        else: col = tuple(min(1., c * r.uniform(.74, 1.16)) for c in bc)
        tag(col)
        st = r.choice((0, 0, 1, 2, 3)) if not slab else r.choice((2, 2, 3, 0))
        if edge_dress(f'{name}{made}e', edge, n, st, r, p): tag(PAL['weld'] if st == 1 else PAL['steel'])
        placed.append((p, rad, lay)); made += 1
    return made

def accents(S, tag, region, ray, accept, r, count, name='ac'):
    """small fittings scattered on the plating: vent grilles, inset hatches, junction boxes. Each needs flat-enough ground at its corners."""
    made = 0; tries = 0
    while made < count and tries < count * 10:
        tries += 1; p, n = S.hit(region(r), ray, .004)
        if p is None or not accept(n): continue
        t, b, n = frame(n); kind = r.random(); w, h = (r.uniform(.012, .022), r.uniform(.008, .014))
        flat = True
        for cu, cv in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
            q = S.T.ray_cast(p + t * cu * w / 2 + b * cv * h / 2 + n * .02, -n, .05)
            if q[0] is None or Vector(q[1]).normalized().dot(n) * (1 if Vector(q[1]).dot(n) > 0 else -1) < .93: flat = False; break
        if not flat: continue
        if kind < .45:
            obox(f'{name}v{made}', p + n * .0007, t, b, n, (w, h, .0016), bevel=.0003); tag(PAL['gun'])
            for k in range(int(w / .004)): obox(f'{name}vs{made}_{k}', p + n * .0016 + t * (-w / 2 + .002 + k * .004), t, b, n, (.0015, h * .8, .001), bevel=0)
            tag(PAL['dark'])
        elif kind < .75:
            obox(f'{name}h{made}', p - n * .0001, t, b, n, (w, h, .0012), bevel=0); tag(PAL['dark'])
            obox(f'{name}hp{made}', p + n * .0003, t, b, n, (w - .002, h - .002, .0012), bevel=.0003); tag(PAL['steel'])
        else:
            obox(f'{name}j{made}', p + n * .0025, t, b, n, (w * .5, h * .6, .005), bevel=.0006); tag(PAL['steel'])
        made += 1
    return made

def detail_pass(targets, parts, tag, base_col, bounds, corsair=False, seed=7, cell=(.034, .022), damage=1.0, flanges=()):
    """targets: hull objects to cover; parts: objects to keep clear of; tag(rgb) colours everything made since the last call;
    base_col: the hull's paint colour (plates vary around it); bounds: (x0, x1, z0, z1) of the hull; flanges: [(centre, size)] mount pads"""
    S = Surface(targets, parts); x0, x1, z0, z1 = bounds; made = 0; pre_names = {o.name for o in hs_lib.PARTS}
    def rnd(*k): return random.Random(hash((seed,) + k) & 0xffffffff)
    BC = base_col if callable(base_col) else (lambda p: base_col)
    pipes_y = []
    SZ = [(.35, (.034, .060), (.020, .034)), (.45, (.018, .034), (.012, .022)), (.20, (.009, .018), (.007, .013))]  # v14c: bigger panels lead, fewer chips
    for s_ in (1, -1):
        r = rnd(1, s_ if corsair else 0)
        # ---- 1. flank plating: mixed shapes, scattered, bent onto the hull and trimmed at its edges ----
        made += scatter_plates(S, tag, lambda r_: Vector((r_.uniform(x0, x1), s_ * .6, r_.uniform(z0, z1))), Vector((0, -s_, 0)),
                               lambda n: abs(n.y) > .3 and n.z > -.4, BC, r, corsair, 115, SZ, name=f'fp{s_}_')
        made += accents(S, tag, lambda r_: Vector((r_.uniform(x0, x1), s_ * .6, r_.uniform(z0, z1))), Vector((0, -s_, 0)), lambda n: abs(n.y) > .45 and n.z > -.3, r, 26, name=f'fa{s_}_')
        # ---- 2. pipe runs along the flank, broken around parts, brackets every few metres, junction boxes at the ends ----
        r = rnd(99, s_ if corsair else 0)
        for zr in (z0 + (z1 - z0) * f for f in (.30, .62)):
            zr += r.uniform(-.006, .006) if corsair else 0
            run = []
            for k in range(int((x1 - x0) / .012) + 1):
                x = x0 + k * .012; p, n = S.hit(Vector((x, s_ * .6, zr)), Vector((0, -s_, 0)), .006)
                if p is None:
                    if len(run) > 3: pipes_y.append(run)
                    run = []; continue
                run.append(p + n * .0045)
            if len(run) > 3: pipes_y.append(run)
    for q, run in enumerate(pipes_y):
        for k in range(len(run) - 1): tube(f'pipe{q}_{k}', run[k], run[k + 1], .0022)
        tag(PAL['gun'])
        for k in range(0, len(run), 4):  # brackets: each built in its own right-handed frame (a mirrored frame turned them inside out)
            p = run[k]; nn = Vector((0, 1 if p.y > 0 else -1, 0)); t_, b_, nn = frame(nn); obox(f'pbr{q}_{k}', p, t_, b_, nn, (.003, .006, .006), bevel=0)
        for p in (run[0], run[-1]):
            nn = Vector((0, 1 if p.y > 0 else -1, 0)); t_, b_, nn = frame(nn); obox(f'pjb{q}_{id(p) % 9999}', p, t_, b_, nn, (.010, .009, .008), bevel=.0008)
        tag(PAL['steel']); made += 1
    # ---- 3. deck and superstructure tops (rays down): the same mixed plating ----
    r = rnd(7)
    made += scatter_plates(S, tag, lambda r_: Vector((r_.uniform(x0, x1), r_.uniform(-.15, .15), .5)), Vector((0, 0, -1)), lambda n: n.z > .45,
                           BC, r, corsair, 110, SZ, name='dk')
    made += accents(S, tag, lambda r_: Vector((r_.uniform(x0, x1), r_.uniform(-.15, .15), .5)), Vector((0, 0, -1)), lambda n: n.z > .6, r, 18, name='da')
    # ---- 3b. belly and the underside of the prow (rays up): fewer, bigger, scorched armour slabs (owner pick, Oct 22) ----
    r = rnd(8)
    def belly_tint(p, r_):
        if corsair and r_.random() < .12: return tuple(c * .8 for c in r_.choice(PAL['salvage']))
        k = r_.uniform(.55, 1.1); return (PAL['belly'][0] * k * 1.25, PAL['belly'][1] * k, PAL['belly'][2] * k)
    made += scatter_plates(S, tag, lambda r_: Vector((r_.uniform(x0, x1), r_.uniform(-.14, .14), -.6)), Vector((0, 0, 1)), lambda n: n.z < -.4,
                           BC, r, corsair, 30, [(.6, (.055, .10), (.030, .055)), (.4, (.035, .055), (.022, .034))], th=.0035,
                           kinds=(('rect', .45), ('chamfer', .35), ('trap', .2)), slab=True, tint=belly_tint, name='bs')
    # ---- 4. mount flanges: a thick pad with bolts where each big part meets the hull, so it reads built in ----
    for k, (c, sz) in enumerate(flanges):
        for s_ in ((1, -1) if c.y != 0 else (0,)):
            cc = Vector((c.x, abs(c.y) * s_, c.z)); d = Vector((0, -s_, 0)) if s_ else Vector((0, 0, -1)); o = cc - d * .3
            h = S.T.ray_cast(o, d, 1.)
            if h[0] is None: continue
            n = Vector(h[1]).normalized(); n = n if n.dot(-d) > 0 else -n; t, b, n = frame(n)
            obox(f'fl{k}{s_}', Vector(h[0]) + n * .001, t, b, n, (sz[0] + .010, sz[1] + .010, .0035), bevel=.001); tag(PAL['gun'])
            for e in range(8):
                a_ = e * math.pi / 4; obox(f'flb{k}{s_}{e}', Vector(h[0]) + n * .003 + t * math.cos(a_) * (sz[0] / 2 + .003) + b * math.sin(a_) * (sz[1] / 2 + .003), t, b, n, (.0018, .0018, .0018), bevel=0)
            tag(PAL['steel'])
    # ---- 5. Corsair: ork/Reaver jank ----
    if corsair:
        r = rnd(1234)
        for k in range(16):  # spikes along the upper edges, pointing out and a little forward, lopsided
            s_ = 1 if r.random() < .5 else -1; x = r.uniform(x0 + .02, x1 - .05); z = r.uniform(z0 + (z1 - z0) * .55, z1)
            p, n = S.hit(Vector((x, s_ * .6, z)), Vector((0, -s_, 0)), .006)
            if p is None: continue
            d = (n + Vector((-.6, 0, .25))).normalized(); L = r.uniform(.014, .032)
            hs_lib.cyl(f'spike{k}', p + d * L / 2, .0035, L, axis='X', seg=8, r2=.0002, rot=d.to_track_quat('X', 'Z').to_matrix(), bevel=0)
            obox(f'spikebase{k}', p, *frame(n), (.008, .008, .003), bevel=0)
        tag(PAL['steel'])
        for k in range(5):  # scrap armour slabs welded on at odd angles, in salvaged colours
            s_ = 1 if k % 2 else -1; x = r.uniform(x0 + .04, x1 - .06); z = r.uniform(z0 + .01, z1 - .02)
            p, n = S.hit(Vector((x, s_ * .6, z)), Vector((0, -s_, 0)), .012)
            if p is None: continue
            t, b, n = frame(n); rot = math.radians(r.uniform(-25, 25)); sz = (r.uniform(.04, .07), r.uniform(.022, .04), .004)
            obox(f'scrap{k}', p + n * .004, t, b, n, sz, bevel=.0008, rot=rot); tag(r.choice(PAL['salvage']))
            for e in range(4):  # crude bolts at the corners
                R = Matrix.Rotation(rot, 3, n); obox(f'scrapb{k}{e}', p + n * .0065 + R @ (t * sz[0] * (.4 if e % 2 else -.4) + b * sz[1] * (.35 if e // 2 else -.35)), t, b, n, (.003, .003, .0025), bevel=0)
            tag(PAL['weld'])
        for k in range(3):  # exposed girder lattice bolted over a gap
            s_ = -1 if k == 1 else 1; x = x0 + (x1 - x0) * (.25 + .25 * k); z = z0 + (z1 - z0) * .45
            p, n = S.hit(Vector((x, s_ * .6, z)), Vector((0, -s_, 0)), .01)
            if p is None: continue
            t, b, n = frame(n); o = p + n * .006
            for e in (-1, 1): obox(f'gird{k}{e}', o + b * e * .010, t, b, n, (.050, .0025, .005), bevel=0)
            for e in range(5): obox(f'girx{k}{e}', o + t * (-.020 + e * .010), t, b, n, (.0022, .020, .004), bevel=0, rot=math.radians(35 if e % 2 else -35))
            tag(PAL['rust'])
        for k in range(2):  # hazard-striped plates near the prow
            s_ = 1 if k == 0 else -1; x = x0 + .02; z = z0 + (z1 - z0) * .4
            p, n = S.hit(Vector((x, s_ * .6, z)), Vector((0, -s_, 0)), .006)
            if p is None: continue
            t, b, n = frame(n)
            for e in range(6): obox(f'haz{k}{e}', p + n * .0012 + t * (-.0125 + e * .005), t, b, n, (.005, .016, .0016), bevel=0, rot=math.radians(30)); tag(PAL['hazard'][e % 2])
    # guard: nothing the pass made may reach far off the hull (a folded sliver once became a 2 m spike)
    dg = bpy.context.evaluated_depsgraph_get(); X0, X1 = x0 - .08, x1 + .08; drop = 0
    for o in list(hs_lib.PARTS):
        if o.name in pre_names: continue
        try: bb = [o.evaluated_get(dg).matrix_world @ Vector(c) for c in o.evaluated_get(dg).bound_box]
        except Exception: continue
        lo = Vector((min(c.x for c in bb), min(c.y for c in bb), min(c.z for c in bb))); hi = Vector((max(c.x for c in bb), max(c.y for c in bb), max(c.z for c in bb)))
        if (hi - lo).length > .2 or lo.x < X0 or hi.x > X1 or abs(lo.y) > .4 or abs(hi.y) > .4 or lo.z < -.5 or hi.z > .5:
            hs_lib.PARTS.remove(o); bpy.data.objects.remove(o); drop += 1
    print('detail pass:', made, 'cells dressed,', len(pipes_y), 'pipe runs, dropped', drop, 'strays')

def dents(obj, spots, seed=3):
    """push a few smooth dents into a dense hull mesh (moderate battle damage). spots: [(centre, radius, depth)]"""
    me = obj.data; bm = bmesh.new(); bm.from_mesh(me); bm.normal_update(); mw = obj.matrix_world; inv = mw.inverted()
    for c, rad, dep in spots:
        cl = inv @ c
        for v in bm.verts:
            d = (v.co - cl).length
            if d < rad: v.co -= v.normal * dep * (1 - d / rad) ** 2 * (3 - 2 * (1 - d / rad)) * .5
    bm.to_mesh(me); bm.free(); me.update()
