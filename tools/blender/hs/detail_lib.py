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
           hazard=((.40, .30, .02), (.02, .02, .02)))

def detail_pass(targets, parts, tag, base_col, bounds, corsair=False, seed=7, cell=(.034, .022), damage=1.0, flanges=()):
    """targets: hull objects to cover; parts: objects to keep clear of; tag(rgb) colours everything made since the last call;
    base_col: the hull's paint colour (plates vary around it); bounds: (x0, x1, z0, z1) of the hull; flanges: [(centre, size)] mount pads"""
    S = Surface(targets, parts); x0, x1, z0, z1 = bounds; cx, cz = cell; made = 0
    def rnd(*k): return random.Random(hash((seed,) + k) & 0xffffffff)
    def tone(c, f): return tuple(min(1., v * f) for v in c)
    BC = base_col if callable(base_col) else (lambda p: base_col)
    sides = (1, -1)
    # ---- 1. plating on the flanks: one cell at a time, mirrored unless Corsair ----
    nx, nz = int((x1 - x0) / cx), int((z1 - z0) / cz)
    pipes_y = []
    for s_ in sides:
        for i in range(nx):
            for j in range(nz):
                x = x0 + (i + .5) * cx; z = z0 + (j + .5) * cz; r = rnd(i, j, s_ if corsair else 0)
                p, n = S.hit(Vector((x, s_ * .6, z)), Vector((0, -s_, 0)), min(cx, cz) * .55)
                if p is None or abs(n.y) < .3: continue
                t, b, n = frame(n); u = r.random()
                if u < .38:   # raised plate, a shade off the base paint
                    obox(f'pl{s_}_{i}_{j}', p + n * .0006, t, b, n, (cx - .0028, cz - .0028, .0018), bevel=.0004); tag(tone(BC(p), r.uniform(.78, 1.14))); made += 1
                elif u < .50:  # inset darker panel
                    obox(f'pi{s_}_{i}_{j}', p - n * .0002, t, b, n, (cx * .7, cz * .6, .0010), bevel=0); tag(tone(BC(p), .55)); made += 1
                elif u < .58 or (corsair and u < .68):  # welded repair patch
                    sal = corsair and r.random() < .7; col = r.choice(PAL['salvage']) if sal else tone(BC(p), r.uniform(.7, 1.0))
                    w_, h_ = cx * r.uniform(.55, 1.15), cz * r.uniform(.6, 1.3); rot = math.radians(r.uniform(-9, 9) if corsair else r.uniform(-2, 2))
                    obox(f'pt{s_}_{i}_{j}', p + n * .0012, t, b, n, (w_, h_, .0024), bevel=.0006, rot=rot); tag(col)
                    R = Matrix.Rotation(rot, 3, n); tt, bb = R @ t, R @ b
                    for e, (o_, sz) in enumerate(((tt * w_ / 2, (.0012, h_, .0014)), (-tt * w_ / 2, (.0012, h_, .0014)), (bb * h_ / 2, (w_, .0012, .0014)), (-bb * h_ / 2, (w_, .0012, .0014)))):
                        obox(f'pw{s_}_{i}_{j}_{e}', p + n * .0024 + o_, tt, bb, n, sz, bevel=0)
                    tag(PAL['weld']); made += 1
                elif u < .64:  # vent grille
                    obox(f'vg{s_}_{i}_{j}', p + n * .0007, t, b, n, (cx * .55, cz * .55, .0016), bevel=.0003); tag(PAL['gun'])
                    for k in range(4): obox(f'vs{s_}_{i}_{j}_{k}', p + n * .0016 + t * (-cx * .2 + k * cx * .133), t, b, n, (.0016, cz * .45, .0010), bevel=0)
                    tag(PAL['dark']); made += 1
                elif u < .68:  # small greeble box
                    obox(f'gb{s_}_{i}_{j}', p + n * .003, t, b, n, (cx * r.uniform(.25, .45), cz * r.uniform(.3, .55), .006), bevel=.0006); tag(PAL['steel']); made += 1
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
        for k in range(0, len(run), 4):
            p = run[k]; obox(f'pbr{q}_{k}', p, Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1 if p.y > 0 else -1, 0)), (.003, .006, .006), bevel=0)
        for p in (run[0], run[-1]):
            obox(f'pjb{q}_{id(p) % 9999}', p, Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1 if p.y > 0 else -1, 0)), (.010, .009, .008), bevel=.0008)
        tag(PAL['steel']); made += 1
    # ---- 3. plating on the decks and the superstructure top (rays down) ----
    for i in range(nx):
        for j in range(int(.30 / cx)):
            y = -.15 + (j + .5) * cx; x = x0 + (i + .5) * cx
            if not corsair and y < 0: continue
            for yy in ((y,) if corsair else (y, -y)):
                r = rnd(i, j, 7, yy if corsair else 0); p, n = S.hit(Vector((x, yy, .5)), Vector((0, 0, -1)), cx * .5)
                if p is None or n.z < .45: continue
                t, b, n = frame(n); u = r.random()
                if u < .40: obox(f'dp{i}_{j}_{yy:.3f}', p + n * .0006, t, b, n, (cx - .003, cx - .003, .0016), bevel=.0004); tag(tone(BC(p), r.uniform(.75, 1.12)))
                elif u < .48: obox(f'dh{i}_{j}_{yy:.3f}', p + n * .0008, t, b, n, (cx * .5, cx * .5, .0018), bevel=.0004); tag(PAL['steel'])
                elif u < .55 or (corsair and u < .62):
                    col = r.choice(PAL['salvage']) if corsair else tone(BC(p), .7)
                    obox(f'dr{i}_{j}_{yy:.3f}', p + n * .0012, t, b, n, (cx * r.uniform(.5, 1.1), cx * r.uniform(.5, 1.1), .0022), bevel=.0005, rot=math.radians(r.uniform(-10, 10) if corsair else 0)); tag(col)
                made += 1
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
    print('detail pass:', made, 'cells dressed,', len(pipes_y), 'pipe runs')

def dents(obj, spots, seed=3):
    """push a few smooth dents into a dense hull mesh (moderate battle damage). spots: [(centre, radius, depth)]"""
    me = obj.data; bm = bmesh.new(); bm.from_mesh(me); bm.normal_update(); mw = obj.matrix_world; inv = mw.inverted()
    for c, rad, dep in spots:
        cl = inv @ c
        for v in bm.verts:
            d = (v.co - cl).length
            if d < rad: v.co -= v.normal * dep * (1 - d / rad) ** 2 * (3 - 2 * (1 - d / rad)) * .5
    bm.to_mesh(me); bm.free(); me.update()
