# Hard-surface kit for scripted Blender ships: every part is a closed mesh with bevelled edges (crisp highlights), built in ship space
# (X forward to the bow, Y to port, Z up, length about 2). Parts join into one object at the end.
import bpy, bmesh, math, random
from mathutils import Vector, Matrix
PARTS = []
def _obj(name, bm, bevel=.006, seg=2, ang=30):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    if bevel > 0:
        b = o.modifiers.new('bv', 'BEVEL'); b.width = bevel; b.segments = seg; b.limit_method = 'ANGLE'; b.angle_limit = math.radians(ang); b.harden_normals = True; b.miter_outer = 'MITER_ARC'
    PARTS.append(o); return o
def loft(name, secs, bevel=.008, cap=True):
    """secs: list of (x, [(y,z),...]) closed cross-sections with the same point count, ordered around the loop."""
    bm = bmesh.new(); rings = [[bm.verts.new((x, y, z)) for (y, z) in pts] for x, pts in secs]; n = len(rings[0])
    for a, b in zip(rings, rings[1:]):
        for i in range(n): bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
    if cap: bm.faces.new(list(reversed(rings[0]))); bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return _obj(name, bm, bevel)
def frustum(name, c, bot, top, h, rz=0, bevel=.006, shear=(0, 0)):
    """box with a smaller top: bot/top = (half x, half y); shear moves the top face."""
    cx, cy, cz = c; bm = bmesh.new(); V = []
    for (hx, hy), z, s in ((bot, 0, (0, 0)), (top, h, shear)):
        for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)): V.append(bm.verts.new((sx * hx + s[0], sy * hy + s[1], z)))
    for f in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)): bm.faces.new([V[i] for i in f])
    bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(rz, 3, 'Z')); bmesh.ops.translate(bm, verts=bm.verts, vec=(cx, cy, cz))
    return _obj(name, bm, bevel)
def box(name, c, s, rot=(0, 0, 0), bevel=.004):
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1)
    bmesh.ops.scale(bm, vec=s, verts=bm.verts); bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(rot[0], 3, 'X') @ Matrix.Rotation(rot[1], 3, 'Y') @ Matrix.Rotation(rot[2], 3, 'Z'))
    bmesh.ops.translate(bm, verts=bm.verts, vec=c); return _obj(name, bm, bevel)
def cyl(name, c, r, h, axis='Z', seg=24, r2=None, bevel=.003, rot=None):
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=h)
    R = {'Z': Matrix.Identity(3), 'X': Matrix.Rotation(math.pi / 2, 3, 'Y'), 'Y': Matrix.Rotation(math.pi / 2, 3, 'X')}[axis]
    if rot is not None: R = rot @ R
    bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=R); bmesh.ops.translate(bm, verts=bm.verts, vec=c); return _obj(name, bm, bevel, seg=1, ang=50)
def tank(name, c, r, h):  # upright tank with domed ends
    o = cyl(name, c, r, h, seg=28, bevel=0); bm = bmesh.new()
    for s in (1, -1):
        bmesh.ops.create_uvsphere(bm, u_segments=28, v_segments=10, radius=r)
    for v in bm.verts: v.co.z *= .45
    bmesh.ops.translate(bm, verts=[v for v in bm.verts], vec=(c[0], c[1], c[2] + h / 2)); _obj(name + 'cap', bm, 0); return o
def tubes(name, c, nx, ny, r, L, pitch, axis_rot):  # rocket pod: a bundle of tubes with dark bores
    for i in range(nx):
        for j in range(ny):
            off = Vector((0, (i - (nx - 1) / 2) * pitch, (j - (ny - 1) / 2) * pitch)); p = Vector(c) + axis_rot @ off
            cyl(f'{name}{i}{j}', p, r, L, axis='X', seg=16, rot=axis_rot); cyl(f'{name}{i}{j}b', p + axis_rot @ Vector((L / 2 + .001, 0, 0)), r * .72, .01, axis='X', seg=16, rot=axis_rot, bevel=0)
def barrel(name, base, d, L, r):  # gun barrel from base along unit vector d, with a muzzle collar
    d = Vector(d).normalized(); R = d.to_track_quat('X', 'Z').to_matrix()
    cyl(name, Vector(base) + d * L / 2, r, L, axis='X', seg=14, rot=R); cyl(name + 'm', Vector(base) + d * (L - .015), r * 1.5, .03, axis='X', seg=14, rot=R)
def greebles(name, region, n, top_z, seed, size=(.012, .05)):
    """scatter small blocks on a deck region ((x0,x1),(y0,y1)) at height top_z (callable x,y->z or a number)"""
    r = random.Random(seed)
    for k in range(n):
        x = r.uniform(*region[0]); y = r.uniform(*region[1]); z = top_z(x, y) if callable(top_z) else top_z
        if z < -.5: continue
        sx, sy, sz = r.uniform(*size), r.uniform(*size), r.uniform(size[0] * .6, size[1] * .6)
        if r.random() < .25: cyl(f'{name}{k}', (x, y, z + sz / 2), min(sx, sy) * .6, sz, seg=12)
        else: box(f'{name}{k}', (x, y, z + sz / 2), (sx, sy, sz), rot=(0, 0, r.choice((0, 0, math.pi / 4))), bevel=.0015)
def vents(name, c, n, w, d, gap, rz=0):  # a row of slats
    for k in range(n): box(f'{name}{k}', (c[0] + (k - (n - 1) / 2) * gap * math.cos(rz), c[1] + (k - (n - 1) / 2) * gap * math.sin(rz), c[2]), (gap * .55, w, d), rot=(0, 0, rz), bevel=.001)
def finish(name):
    for o in PARTS:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers): bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    for o in bpy.context.scene.objects: o.select_set(o in PARTS)
    bpy.context.view_layer.objects.active = PARTS[0]; bpy.ops.object.join(); o = bpy.context.view_layer.objects.active; o.name = name
    for p in o.data.polygons: p.use_smooth = True
    return o
