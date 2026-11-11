# Issue 209 round 1, Arm B: AI generation at four granularities, all at one scale and with texture off, assembled in Blender on the same
# hard points as Arm A and fitted with the same break structure, paint, audit and report (common.py).
#   B0  the whole hull in one TRELLIS.2 generation (the control cell)
#   B1  3 bare hull sections + generated parts            B2  6 bare hull sections + generated parts
#   B3  generated parts only, on a hand-built structural core (Arm A's hull lofts without their detail)
# Thin parts (sensor array, radiators) and the command tower are hand-built in every B cell: generators drop thin parts (#214 note).
# usage: python armB.py -- CELL GEN3D_DIR B0_GLB OUT_DIR
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import common as C
import bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import box, cyl
import armA as A

YAW = 19.8          # TRELLIS.2 lays the concept's 3/4 view down about 20 degrees off the x axis; every crop shares that camera
DENSITY = 300000    # triangles per unit of ship length for generated hull (the mid-ladder scale for this round)
SLOTS = {'B1': [.50, .10, -.22, -.50], 'B2': [.50, .335, .17, .015, -.145, -.31, -.50]}
# per-generation fixes found by eye in the assembly check (yaw quarter turns, mirror), the cleanup cost Arm B pays
FIX = json.load(open(os.path.join(HERE, 'armB_fix.json'))) if os.path.exists(os.path.join(HERE, 'armB_fix.json')) else {}

def envelope(x0, x1):
    st = [A.at(x) for x in np.linspace(x0, x1, 6)]
    return max(s[3] for s in st), min(s[6] for s in st), max(s[2] for s in st)

def decimate(o, target):
    me = o.data; me.calc_loop_triangles(); n = len(me.loop_triangles)
    if n > target:
        m = o.modifiers.new('dec', 'DECIMATE'); m.ratio = target / n
        bpy.context.view_layer.objects.active = o; bpy.ops.object.modifier_apply(modifier='dec')
    me.calc_loop_triangles(); return n, len(me.loop_triangles)

def fit(o, lo, hi, name):
    """turn the generation into the ship frame (shared yaw plus any per-generation fix) and fit its 2-98 percentile box into lo..hi"""
    f = FIX.get(name, {}); M = Matrix.Rotation(math.radians(f.get('yaw', YAW) + 90 * f.get('quarter', 0)), 4, 'Z')
    if f.get('roll'): M = Matrix.Rotation(math.radians(90 * f['roll']), 4, 'X') @ M
    if f.get('pitch'): M = Matrix.Rotation(math.radians(90 * f['pitch']), 4, 'Y') @ M
    o.data.transform(M)
    if f.get('flipx'): o.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
    if f.get('flipy'): o.data.transform(Matrix.Scale(-1, 4, (0, 1, 0)))
    if f.get('flipx') or f.get('flipy'): o.data.flip_normals()
    if f.get('auto'):  # turn the longest horizontal axis onto x (sections come out of TRELLIS standing across the view)
        v = np.array([x.co[:] for x in o.data.vertices]); xy = v[:, :2] - v[:, :2].mean(0); w, e = np.linalg.eigh(np.cov(xy.T)); ax = e[:, 1]
        o.data.transform(Matrix.Rotation(-math.atan2(ax[1], ax[0]), 4, 'Z'))
        if f.get('nose'):  # the bow section: the narrower end goes forward (+x)
            v = np.array([x.co[:] for x in o.data.vertices]); x0, x1 = np.percentile(v[:, 0], 5), np.percentile(v[:, 0], 95); L = x1 - x0
            wid = lambda m: np.ptp(v[m, 1]) if m.sum() > 10 else 0
            if wid(v[:, 0] > x1 - L * .15) > wid(v[:, 0] < x0 + L * .15): o.data.transform(Matrix.Rotation(math.pi, 4, 'Z'))
        else:  # otherwise lay it lengthwise or crosswise, whichever squashes it least into its slot
            v = np.array([x.co[:] for x in o.data.vertices]); e = np.percentile(v, 98, 0) - np.percentile(v, 2, 0); slot = np.array(hi) - np.array(lo)
            aniso = lambda ex, ey: max(slot[0] / ex, slot[1] / ey) / min(slot[0] / ex, slot[1] / ey)
            if aniso(e[1], e[0]) < aniso(e[0], e[1]): o.data.transform(Matrix.Rotation(math.pi / 2, 4, 'Z'))
    v = np.array([x.co[:] for x in o.data.vertices]); a = np.percentile(v, 2, 0); b = np.percentile(v, 98, 0)
    s = (np.array(hi) - np.array(lo)) / np.maximum(b - a, 1e-6)
    for x in o.data.vertices: x.co = Vector(np.array(lo) + (np.array(x.co[:]) - a) * s)
    return [float(k) for k in s]

def gen(path, name, target, lo, hi, r, notes):
    o = C.import_glb(path, name); n0, n1 = decimate(o, target); sc = fit(o, lo, hi, os.path.basename(path)[:-4])
    o['role'] = r; notes.append(dict(part=name, source=os.path.basename(path), tris_raw=n0, tris=n1, stretch=[round(k, 3) for k in sc])); return o

def mirror_y(o):
    o.data.transform(Matrix.Scale(-1, 4, (0, 1, 0))); o.data.flip_normals()

def ai_parts(G, notes, made, hull):
    """the generated parts on Arm A's hard points (same sizes as Arm A's hand-built parts), mounted on this cell's real flank"""
    P = lambda nm: os.path.join(G, f'p_{nm}.glb'); T = C.bvh(hull)
    def flank(x, z):  # half-width of this cell's hull at (x, z), from a ray cast in from port
        h = T.ray_cast(Vector((x, .6, z)), Vector((0, -1, 0)), .6)
        return h[0].y if h[0] is not None else A.at(x)[3]
    deckz = deck_of(T)
    for i, x in enumerate((.300, .175)):
        for s in (1, -1):
            wc = flank(x, .004)
            o = gen(P('casemate'), f'casemate_{i}{"p" if s > 0 else "s"}', 15000, (x - .042, wc - .004, -.036), (x + .042, wc + .066, .044), 'part', notes)
            if s < 0: mirror_y(o)
            made.append(o)
    for nm, (x, y, L, W, H) in (('drums_f', (.145, 0, .070, .14, .040)), ('drums_m', (-.085, 0, .095, .165, .046)), ('drums_a', (-.300, 0, .064, .12, .036))):
        zt = deckz(x)
        if os.path.exists(P('drumrack')) and os.path.getsize(P('drumrack')) > 1000:
            made.append(gen(P('drumrack'), nm, 20000, (x - L / 2, y - W / 2, zt - .003), (x + L / 2, y + W / 2, zt + H), 'part', notes))
        else:  # the generator failed on this part (out of GPU memory): Arm A's hand-built drums stand in, and the report says so
            notes.append(dict(part=nm, source='hand-built fallback (generation failed)'))
            k = 3 if nm == 'drums_m' else 2
            for j in range(k): A.drum(f'{nm}{j}', x, (j - (k - 1) / 2) * W / k, zt + H * .5, H * .45, L * .9)
    zt = deckz(.375); made.append(gen(P('bowguns'), 'bowguns', 12000, (.330, -.050, zt - .003), (.445, .050, zt + .032), 'part', notes))
    for s in (1, -1):
        wc = flank(-.115, -.06); y0, y1 = wc - .004, wc + .056
        o = gen(P('cargo'), f'cargo_{"p" if s > 0 else "s"}', 20000, (-.195, y0, -.094), (-.035, y1, -.032), 'part', notes)
        if s < 0: mirror_y(o)
        made.append(o)
    gx = -.548
    if os.path.exists(P('sternblock')) and os.path.getsize(P('sternblock')) > 1000:
        made.append(gen(P('sternblock'), 'sternblock', 25000, (-.545, -.110, -.075), (-.470, .110, .060), 'part', notes))
    else:  # generation failed: Arm A's hand-built engine bells stand in, and the report says so
        import barge_shapes as B
        notes.append(dict(part='sternblock', source='hand-built fallback (generation failed)'))
        for y, z, r in ((0, -.025, .046), (.062, .022, .028), (-.062, .022, .028)): B.engine_bell((-.492, y, z), r, .050, axis_dir=Vector((-1, 0, 0)))
        gx = -.530
    if gx > -.54:  # glow discs only on the hand-built fallback bells; the generated nozzles do not line up with fixed discs (left unlit)
        for nm, (y, z, r) in (('main', (0, -.025, .041)), ('portb', (.062, .022, .025)), ('stbdb', (-.062, .022, .025))):
            n0 = len(hs_lib.PARTS); cyl(f'glow{nm}', (gx, y, z), r, .002, axis='X', seg=28, bevel=0); hs_lib.PARTS[n0]['role'] = 'glow'

def deck_of(T):
    """deck height of this cell's hull at x along the centreline (ray cast down), Arm A's table where the ray misses"""
    def f(x, y=0):
        h = T.ray_cast(Vector((x, y, .6)), Vector((0, 0, -1)), 1.0)
        return h[0].z if h[0] is not None else A.at(x)[2]
    return f

def thin_parts(hull):
    """hand-built in every B cell: command tower, sensor array, radiators (generators drop thin parts), seated on this cell's deck"""
    import barge_shapes as B
    deckz = deck_of(C.bvh(hull)); zt = deckz(.02); cyl('tower', (.020, 0, zt + .034), .046, .072, seg=32, bevel=.003)
    box('bridge', (.032, 0, zt + .082), (.070, .074, .026), bevel=.003)
    B.antenna_array(.020, 0, zt + .095, h=.085)
    B.radiator_pair(-.420, 0, deckz(-.42), n=2, L=.070, H=.048)

def build(cell, G, b0, out):
    t0 = time.time(); bpy.ops.wm.read_factory_settings(use_empty=True); hs_lib.PARTS.clear(); notes = []; made = []
    if cell == 'B0':
        o = C.import_glb(b0, 'b0_whole'); n0, n1 = decimate(o, DENSITY); C.ai_align(o, YAW); o['role'] = 'ai'; hull = [o]
        notes.append(dict(part='whole hull', source=os.path.basename(b0), tris_raw=n0, tris=n1))
    elif cell[:2] in SLOTS:
        xs = SLOTS[cell[:2]]; hull = []
        for k, (x1, x0) in enumerate(zip(xs, xs[1:])):
            wc, zb, zt = envelope(x0, x1); ov = .006  # neighbours overlap a little; the collar hides the joint
            o = gen(os.path.join(G, f'{cell.lower()}_s{k}.glb'), f'{cell.lower()}_s{k}', int(DENSITY * (x1 - x0)), (x0 - ov, -wc, zb), (x1 + ov, wc, zt), 'ai', notes)
            hull.append(o)
        T = C.bvh(hull)
        for k, x in enumerate(xs[1:-1]):  # hand-built seam collars at every joint (a joint on a break line already has its rim band)
            if min(abs(x - t) for t in C.T_LINES) < .01: continue
            pts = C.fill_outline(C.outline(T, x))
            if pts: made.append(C.ring_band(f'collar{k}', C.inset(pts, -.004), C.inset(pts, .006), x - .009, x + .009, r='part'))
        thin_parts(hull); ai_parts(G, notes, made, hull)
    elif cell == 'B3':
        hull = A.shells(); thin_parts(hull); ai_parts(G, notes, made, hull)
    for o in hs_lib.PARTS:
        if 'role' not in o: o['role'] = 'part'
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    parts = [o for o in made + hs_lib.PARTS if o.get('role') != 'glow']
    au = C.audit(hull, parts, [])
    brk, fit_notes = C.breakable(hull)
    allobj = hull + made + list(hs_lib.PARTS) + brk
    C.paint(allobj, hull)
    rep = C.report(allobj)
    meta = dict(cell=cell, build_seconds=round(time.time() - t0, 1), audit=au, break_fit=fit_notes, generations=notes, **rep)
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f'{cell}.blend'))
    json.dump(meta, open(os.path.join(out, f'{cell}.json'), 'w'), indent=1); print('[209]', cell, json.dumps(meta)[:1500], flush=True)

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:]
    build(a[0], a[1], a[2], a[3])
