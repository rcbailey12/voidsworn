"""Issue 1361 (World V2, R419): faceted multi-crystal clusters for crystal fields (godot/world/rocks/crystal_NN.glb).

Replaces rockgen.py's 216-tri clusters. Each cluster is a rough mineral host collar with 8 to 14 hexagonal quartz/beryl
prisms bursting out of it at varied height and lean, with pointed (sometimes skewed) terminations and a thin bevel on
every edge so the facets catch the sun. Same frame as before: base on y = 0, tallest tip at y = 1, about 1 across, so
world.gd's placement and scales are unchanged.

Vertex colour (CRYSTAL_SHADER in world_rocks.gd):
  R  1 = crystal, 0 = host rock collar
  G  height along the prism (0 at its root, 1 at its tip) times the prism's share of the hero's length
  B  a per-prism value (inner depth and brightness variety)
  A  1

Blender 4.5 (the PC's LTS; in a cloud thread the pip bpy 4.5.4 wheel). Run:
  blender -b -P crystal_kit.py -- OUT_DIR [count]      or      python crystal_kit.py OUT_DIR [count]   (bpy wheel)
"""
import sys, math, random
from pathlib import Path
import bpy, bmesh
from mathutils import Vector, Matrix, noise

SEEDS = [1361, 2361, 3361, 4361]


def args():
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    return Path(a[0]), int(a[1]) if len(a) > 1 else len(SEEDS)


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def build(seed, out):
    rnd = random.Random(seed)
    clear()
    # host collar: a flattened, noise-broken rock the prisms grow out of
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=4, radius=1.0)
    collar = bpy.context.object
    collar.name = 'collar'
    sx, sy, sz = rnd.uniform(0.42, 0.52), rnd.uniform(0.38, 0.5), rnd.uniform(0.15, 0.2)
    off = Vector((rnd.uniform(0, 50), rnd.uniform(0, 50), rnd.uniform(0, 50)))
    cuts = [(Vector((rnd.gauss(0, 1), rnd.gauss(0, 1), rnd.gauss(0, 0.4))).normalized(), rnd.uniform(0.7, 0.9)) for _ in range(4)]
    for v in collar.data.vertices:
        p = v.co.copy()
        d = 1.0 + 0.22 * noise.fractal(p * 1.6 + off, 0.6, 2.0, 4) + 0.06 * noise.noise(p * 6.0 + off)
        p *= d
        for n, c in cuts:  # flat fracture planes, like a broken boulder
            t = p.dot(n)
            if t > c:
                p -= n * (t - c)
        v.co = Vector((p.x * sx, p.y * sy, max(p.z * sz + 0.05, 0.0)))
    # crystals
    me = bpy.data.meshes.new('prisms')
    bm = bmesh.new()
    col = bm.verts.layers.float_color.new('Col')
    count = rnd.randint(8, 14)
    hero_len = 1.0
    specs = []
    for i in range(count):
        hero = i == 0
        lean = 0.0 if hero else rnd.uniform(0.25, 0.85)
        az = rnd.uniform(0, math.tau)
        axis = Vector((math.sin(lean) * math.cos(az), math.sin(lean) * math.sin(az), math.cos(lean)))
        rr = rnd.uniform(0.0, 0.28) if not hero else rnd.uniform(0.0, 0.05)
        root = Vector((rr * math.cos(az + rnd.uniform(-0.6, 0.6)) * 1.3, rr * math.sin(az + rnd.uniform(-0.6, 0.6)), 0.04))
        size = 1.0 if hero else rnd.uniform(0.22, 0.8) ** 1.2
        radius = (0.085 if hero else 0.07) * (0.55 + 0.45 * size) * rnd.uniform(0.85, 1.2)
        length = hero_len * size * rnd.uniform(0.72, 0.82)
        tip = radius * rnd.uniform(1.3, 2.4)
        specs.append((root, axis, radius, length, tip, rnd.uniform(-0.5, 0.5), rnd.uniform(0, 1), rnd.uniform(0.2, 1.0), size))
    for root, axis, radius, length, tip, skew, twist, b, share in specs:
        axis = axis.normalized()
        side = axis.orthogonal().normalized()
        side.rotate(Matrix.Rotation(twist * math.pi, 3, axis))
        other = axis.cross(side).normalized()
        wob = [1.0 + rnd.uniform(-0.12, 0.12) for _ in range(6)]
        def ring(h, rr):
            return [root + axis * h + (side * math.cos(k * math.pi / 3) + other * math.sin(k * math.pi / 3)) * rr * wob[k] for k in range(6)]
        vb = [bm.verts.new(p) for p in ring(-0.08, radius)]
        vt = [bm.verts.new(p) for p in ring(length, radius * rnd.uniform(0.92, 1.04))]
        va = bm.verts.new(root + axis * (length + tip) + side * skew * radius)
        bm.faces.new(list(reversed(vb)))
        for k in range(6):
            n = (k + 1) % 6
            bm.faces.new([vb[k], vb[n], vt[n], vt[k]])
            bm.faces.new([vt[k], vt[n], va])
        total = length + tip + 0.08
        for v in vb + vt + [va]:
            h = ((v.co - root).dot(axis) + 0.08) / total
            v[col] = (1.0, max(0.0, min(1.0, h)) * share, b, 1.0)
    bm.to_mesh(me)
    bm.free()
    prisms = bpy.data.objects.new('prisms', me)
    bpy.context.collection.objects.link(prisms)
    bev = prisms.modifiers.new('bevel', 'BEVEL')
    bev.width = 0.006
    bev.segments = 1
    bev.limit_method = 'ANGLE'
    bev.angle_limit = math.radians(25)
    # collar colour: rock (R 0), its brightness in B for a little mottling
    cme = collar.data
    cattr = cme.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT')
    for v in cme.vertices:
        cattr.data[v.index].color = (0.0, 0.0, 0.5 + 0.5 * noise.noise(v.co * 4.0 + off), 1.0)
    for p in cme.polygons:
        p.use_smooth = True
    # join, apply, fit into the old frame (base y 0, tallest tip 1)
    bpy.ops.object.select_all(action='DESELECT')
    prisms.select_set(True)
    collar.select_set(True)
    bpy.context.view_layer.objects.active = prisms
    bpy.ops.object.convert(target='MESH')
    bpy.ops.object.join()
    ob = bpy.context.object
    zs = [v.co.z for v in ob.data.vertices]
    lo, hi = min(zs), max(zs)
    k = 1.0 / (hi - max(lo, 0.0))
    for v in ob.data.vertices:
        v.co.z = max(v.co.z, 0.0)
        v.co *= k
    ob.data.color_attributes.active_color = ob.data.color_attributes['Col']
    ob.data.update()
    tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    path = out / ('crystal_%02d.glb' % SEEDS.index(seed))
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=False, export_materials='NONE',
                              export_vertex_color='ACTIVE', export_normals=True, export_texcoords=False, export_yup=True,
                              export_apply=True)
    print(path.name, 'triangles', tris, 'prisms', count)
    return tris


if __name__ == '__main__':
    out, n = args()
    out.mkdir(parents=True, exist_ok=True)
    for s in SEEDS[:n]:
        build(s, out)
