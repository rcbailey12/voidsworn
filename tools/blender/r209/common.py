# Issue 209 round 1: shared code for every cell (Arm A and Arm B0 to B3), so the cells differ only in how the hull was built.
# Frame (same as the A4 ship files): x to the bow, y to port, z up, ship length 1.0 (x from -0.5 at the stern to +0.5 at the bow).
# What every cell gets from here, identically:
#   - breakable by design (R98, R99): real hull thickness (solidify), two transverse break lines and one longitudinal, a bulkhead with
#     frame ribs on each side of every transverse line, rim bands at the lines, two internal decks per segment;
#   - the same paint: the current best Hullbreaker recipe (tools/blender/hull_repair/round6_material.py, PR #196), bands set by geometry;
#   - the same audit and cost report (triangles, draw calls, surfaces, gaps, parts crossing break lines, guns aimed backward).
import os, sys, math, json
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (os.path.join(HERE, '..', 'hs'), os.path.join(HERE, '..', 'a1'), os.path.join(HERE, '..', 'hull_repair'), HERE):
    if p not in sys.path: sys.path.insert(0, p)
import bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

T_LINES = (.10, -.22)            # transverse break lines (x): bow piece / mid piece / aft piece
L_LINE = (-.02, -.22, .10)       # longitudinal break line: z, from x0 to x1 (splits the mid piece into upper and lower)
DECKS = (-.065, .005)            # internal deck heights
SKIN = .005                      # hull thickness (ship units; about 0.2 game units on a 41.6 unit hull)

def set_break(t_lines, l_line, decks):
    """round 2: the break lines follow each build's structural joints; stored on the scene so render.py cuts the same pieces"""
    global T_LINES, L_LINE, DECKS
    T_LINES, L_LINE, DECKS = tuple(t_lines), tuple(l_line), tuple(decks)
    sc = bpy.context.scene; sc['r209_t_lines'] = list(T_LINES); sc['r209_l_line'] = list(L_LINE); sc['r209_decks'] = list(DECKS)

def role(o, r):
    o['role'] = r; return o

def mesh_objs(): return [o for o in bpy.context.scene.objects if o.type == 'MESH']

def bvh(objs):
    bm = bmesh.new(); dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        oe = o.evaluated_get(dg); me = oe.to_mesh(); t = bmesh.new(); t.from_mesh(me); t.transform(o.matrix_world)
        tm = bpy.data.meshes.new('tmp'); t.to_mesh(tm); t.free(); bm.from_mesh(tm); bpy.data.meshes.remove(tm); oe.to_mesh_clear()
    b = BVHTree.FromBMesh(bm); bm.free(); return b

def new_obj(name, bm, r=None):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    if r: role(o, r)
    return o

# ---------------------------------------------------------------- hull sampling by ray casts (works on any mesh, hand-built or AI)
def outline(T, x, n=48, cz=-.02, R=.6):
    """outer section of the hull at x: rays cast inward from a circle of radius R around (x, 0, cz); returns [(y, z)] or None per ray"""
    out = []
    for k in range(n):
        a = 2 * math.pi * k / n; d = Vector((0, math.cos(a), math.sin(a)))
        h = T.ray_cast(Vector((x, 0, cz)) + d * R, -d, R)
        out.append(None if h[0] is None else (h[0].y, h[0].z))
    return out

def fill_outline(pts, cz=-.02):
    """missing rays take the neighbours' radius (keeps the polygon closed); returns a clean list or None if almost nothing hit"""
    n = len(pts); ok = [p for p in pts if p]
    if len(ok) < n * .5: return None
    rad = [None if p is None else math.hypot(p[0], p[1] - cz) for p in pts]
    for k in range(n):
        if rad[k] is None:
            j = 1
            while rad[(k - j) % n] is None and rad[(k + j) % n] is None: j += 1
            rad[k] = rad[(k - j) % n] if rad[(k - j) % n] is not None else rad[(k + j) % n]
    return [(rad[k] * math.cos(2 * math.pi * k / n), cz + rad[k] * math.sin(2 * math.pi * k / n)) for k in range(n)]

def inset(pts, d, cz=-.02):
    return [(y - d * y / max(math.hypot(y, z - cz), 1e-6), z - d * (z - cz) / max(math.hypot(y, z - cz), 1e-6)) for y, z in pts]

def ring_band(name, outer, inner, x0, x1, r='trim'):
    """a closed ring: outer and inner loops, extruded from x0 to x1 (the rim band at a break line)"""
    bm = bmesh.new(); n = len(outer)
    L = [[bm.verts.new((x, y, z)) for y, z in loop] for x, loop in ((x0, outer), (x1, outer), (x1, inner), (x0, inner))]
    for a, b in ((0, 1), (1, 2), (2, 3), (3, 0)):
        for i in range(n): bm.faces.new((L[a][i], L[a][(i + 1) % n], L[b][(i + 1) % n], L[b][i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return new_obj(name, bm, r)

def plate(name, loop, x, th, r='interior'):
    """a flat plate in the y-z plane at x, polygon loop, thickness th along x"""
    bm = bmesh.new(); a = [bm.verts.new((x - th / 2, y, z)) for y, z in loop]; b = [bm.verts.new((x + th / 2, y, z)) for y, z in loop]
    bm.faces.new(list(reversed(a))); bm.faces.new(b); n = len(loop)
    for i in range(n): bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return new_obj(name, bm, r)

def deck(T, name, z, x0, x1, step=.02):
    """an internal deck at height z between x0 and x1: its edge follows the hull (rays cast inward from both sides), inset by the skin"""
    rows = []
    for k in range(int((x1 - x0) / step) + 1):
        x = min(x0 + k * step, x1); ys = []
        for s in (1, -1):
            h = T.ray_cast(Vector((x, s * .6, z)), Vector((0, -s, 0)), 1.2); ys.append(None if h[0] is None else abs(h[0].y))
        if None not in ys and min(ys) > .02: rows.append((x, min(ys) - SKIN * 2))
    if len(rows) < 2: return None
    bm = bmesh.new(); L = [(bm.verts.new((x, w, z - .0015)), bm.verts.new((x, -w, z - .0015)), bm.verts.new((x, -w, z + .0015)), bm.verts.new((x, w, z + .0015))) for x, w in rows]
    for a, b in zip(L, L[1:]):
        for i in range(4): bm.faces.new((a[i], a[(i + 1) % 4], b[(i + 1) % 4], b[i]))
    bm.faces.new(list(reversed(L[0]))); bm.faces.new(L[-1]); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return new_obj(name, bm, 'interior')

def strake(T, name, z, x0, x1, step=.01):
    """the rim band along the longitudinal break line: a square bar riding the hull at height z on both flanks"""
    bm = bmesh.new()
    for s in (1, -1):
        prev = None
        for k in range(int((x1 - x0) / step) + 1):
            x = x0 + k * step; h = T.ray_cast(Vector((x, s * .6, z)), Vector((0, -s, 0)), .6)
            if h[0] is None: prev = None; continue
            c = Vector(h[0]) + Vector((0, s * .0015, 0)); q = [bm.verts.new(c + Vector(o)) for o in ((0, -.003, -.003), (0, .003, -.003), (0, .003, .003), (0, -.003, .003))]
            if prev:
                for i in range(4): bm.faces.new((prev[i], prev[(i + 1) % 4], q[(i + 1) % 4], q[i]))
            prev = q
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return new_obj(name, bm, 'trim')

def breakable(hull_objs):
    """Fit the standard break structure to a hull (any route). Returns (made objects, fit notes)."""
    T = bvh(hull_objs); made = []; notes = {}
    for o in hull_objs:  # real thickness: every outer shell gets an inner skin (R99: thick where it shows)
        m = o.modifiers.new('skin', 'SOLIDIFY'); m.thickness = SKIN; m.offset = -1; m.use_even_offset = False; m.material_offset = 0
    for i, x in enumerate(T_LINES):
        raw = outline(T, x); pts = fill_outline(raw)
        miss = sum(1 for p in raw if p is None); notes[f'T{i + 1}_rays_missed'] = miss
        if pts is None: notes[f'T{i + 1}'] = 'no section found'; continue
        # how ragged is the section? the spread of the radius change between neighbouring rays
        rr = [math.hypot(y, z + .02) for y, z in pts]; jag = float(np.percentile([abs(rr[k] - rr[k - 1]) for k in range(len(rr))], 90))
        notes[f'T{i + 1}_jag'] = round(jag, 4)
        made.append(ring_band(f'rim_T{i + 1}', inset(pts, -.002), inset(pts, .004), x - .006, x + .006))
        inner = inset(pts, SKIN + .001)
        for s in (-1, 1):  # one bulkhead each side of the line, so each broken piece is closed with its own face
            made.append(plate(f'bulk_T{i + 1}_{"f" if s > 0 else "a"}', inner, x + s * .004, .003))
            ys = [p[0] for p in inner]; zs = [p[1] for p in inner]
            for k, zz in enumerate(np.linspace(min(zs) + .02, max(zs) - .02, 3)):  # frame ribs on the bulkhead faces
                made.append(role(box_obj(f'rib_T{i + 1}{s}{k}', (x + s * .008, 0, zz), (.004, (max(ys) - min(ys)) * .7, .004)), 'interior'))
    ends = [-.49] + sorted(T_LINES) + [.49]
    for a, b in zip(ends, ends[1:]):
        for z in DECKS:
            d = deck(T, f'deck_{a:+.2f}_{z:+.3f}', z, a + .012, b - .012)
            if d: made.append(d)
    z, x0, x1 = L_LINE; made.append(strake(T, 'rim_L1', z, x0, x1))
    return made, notes

def box_obj(name, c, s):
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1); bmesh.ops.scale(bm, vec=s, verts=bm.verts); bmesh.ops.translate(bm, verts=bm.verts, vec=c)
    return new_obj(name, bm)

# ---------------------------------------------------------------- paint (one recipe for every cell)
_MATS = {}
def mats():
    if _MATS: return _MATS
    import round6_material as R6
    for band in (0, 1, 2, 3, 12):
        _MATS[band] = R6.make_material(None, band)[0]
    m = bpy.data.materials.new('interior'); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (.020, .016, .014, 1); b.inputs['Roughness'].default_value = .8; _MATS['interior'] = m
    m = bpy.data.materials.new('clay'); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (.16, .16, .16, 1); b.inputs['Roughness'].default_value = .55; m.use_fake_user = True; _MATS['clay'] = m
    return _MATS

def paint(objs, hull_objs):
    """Bands by geometry, the round 6 way: belly and undersides darkest (0), the forward hull one coat (1), the aft hull the lighter
    grey coat (3), red only on trim (2), engine glow (12). Small parts take the band of the hull face they sit on."""
    M = mats(); T = bvh(hull_objs) if hull_objs else None
    hull_band = {}
    def hband(c, n):
        if n.z < -.45 or c.z < -.10: return 0
        return 1 if c.x > -.08 else 3
    for o in objs:
        r = o.get('role', 'part'); me = o.data
        if r in ('interior',):
            me.materials.clear(); me.materials.append(M['interior']); continue
        if r in ('trim', 'glow', 'dark'):
            me.materials.clear(); me.materials.append(M[{'trim': 2, 'glow': 12, 'dark': 0}[r]]); continue
        ids = []
        mw = o.matrix_world; nm = mw.to_3x3().inverted_safe().transposed()
        for p in me.polygons:
            c = mw @ p.center; n = (nm @ p.normal).normalized()
            if r in ('hull', 'ai'):
                b = hband(c, n)
            else:
                b = 1
                if T is not None:
                    h = T.find_nearest(c)
                    if h[0] is not None: b = hband(Vector(h[0]), Vector(h[1]))
                if n.z < -.6: b = 0
            ids.append(b)
        me.materials.clear(); order = sorted(set(ids)); loc = {b: k for k, b in enumerate(order)}
        for b in order: me.materials.append(M[b])
        me.polygons.foreach_set('material_index', np.array([loc[b] for b in ids], np.int32))

# ---------------------------------------------------------------- audit and cost report
def tris(o):
    dg = bpy.context.evaluated_depsgraph_get(); oe = o.evaluated_get(dg); me = oe.to_mesh(); me.calc_loop_triangles(); n = len(me.loop_triangles); oe.to_mesh_clear(); return n

def audit(hull_objs, part_objs, guns=()):
    """parts: gap or intersection with the hull and other parts, parts crossing a break line; guns: (name, direction) never aimed back"""
    probs = []; T = bvh(hull_objs); cross = []
    for nm, d in guns:
        if d.x < -.05: probs.append(f'gun {nm} aims backward (x {d.x:+.2f})')
    allp = list(part_objs)
    for o in allp:
        w = [o.matrix_world @ Vector(b) for b in o.bound_box]; lo = Vector([min(v[i] for v in w) for i in range(3)]); hi = Vector([max(v[i] for v in w) for i in range(3)])
        for x in T_LINES:
            if lo.x < x - .002 and hi.x > x + .002: cross.append(o.name)
        if lo.x < L_LINE[2] and hi.x > L_LINE[1] and lo.z < L_LINE[0] - .002 < L_LINE[0] + .002 < hi.z: cross.append(o.name)
        P = bvh([o])
        if T.overlap(P): continue
        others = [q for q in allp if q is not o]
        if others and bvh(others).overlap(P): continue
        dmin = 9
        for v in list(o.data.vertices)[::max(1, len(o.data.vertices) // 150)]:
            h = T.find_nearest(o.matrix_world @ v.co)
            if h[0] is not None: dmin = min(dmin, h[3])
        if dmin > .002: probs.append(f'part {o.name} floats {dmin * 41.6:.2f} game units off the hull')
    return dict(problems=probs, parts=len(allp), crossing_break_lines=sorted(set(cross)))

def report(objs):
    """triangles, and the draw calls and surfaces of the cell exported as one merged mesh (one surface per material)"""
    t = sum(tris(o) for o in objs); used = set()
    for o in objs:
        for s in o.material_slots:
            if s.material: used.add(s.material.name)
    return dict(triangles=t, objects=len(objs), surfaces=len(used), draw_calls_merged=len(used))

# ---------------------------------------------------------------- normalise an AI mesh into the ship frame
def ai_align(o, yaw_deg, length=1.0, centre=None):
    """rotate an imported AI mesh about z so its long axis is x, then scale and centre it"""
    # round 2 fix: turn the mesh data itself. Round 1 set rotation_euler, but glTF imports use quaternion rotation mode, so the yaw
    # was silently dropped and B0 (and the station table measured off it) sat about 20 degrees off the ship axis.
    o.data.transform(Matrix.Rotation(math.radians(yaw_deg), 4, 'Z'))
    v = np.array([x.co[:] for x in o.data.vertices]); lo, hi = v.min(0), v.max(0)
    s = length / (hi[0] - lo[0]); c = (lo + hi) / 2 if centre is None else centre
    if centre is None:  # centre y on the hull's own midline (slab midpoints in a band around the waist), not on the lopsided bounding box
        band = v[np.abs(v[:, 2] - (lo[2] + hi[2]) / 2) < .04 / s]; mids = []
        for x0 in np.linspace(lo[0], hi[0], 21)[:-1]:
            q = band[(band[:, 0] >= x0) & (band[:, 0] < x0 + (hi[0] - lo[0]) / 20)]
            if len(q) > 50: mids.append((np.percentile(q[:, 1], 3) + np.percentile(q[:, 1], 97)) / 2)
        if mids: c = np.array([c[0], float(np.median(mids)), c[2]])
    for x in o.data.vertices: x.co = Vector(((x.co.x - c[0]) * s, (x.co.y - c[1]) * s, (x.co.z - c[2]) * s))
    return s

def import_glb(path, name):
    before = set(bpy.context.scene.objects); bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.context.scene.objects if o not in before and o.type == 'MESH']
    for o in [o for o in bpy.context.scene.objects if o not in before and o.type != 'MESH']: bpy.data.objects.remove(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in new: o.select_set(True)
    bpy.context.view_layer.objects.active = new[0]
    if len(new) > 1: bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active; o.parent = None; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    o.name = name; o.data.materials.clear()
    for a in list(o.data.color_attributes): o.data.color_attributes.remove(a)
    return o
