# Voidsworn asteroid library: sculpted high-poly rocks (GLB) + game low-poly (hull JSON format) per rock type.
# usage (bpy module): python3 rockgen.py <out_dir> [types] [count]
import sys, os, json, base64, math, random
OUT = sys.argv[1]; TYPES = (sys.argv[2].split(',') if len(sys.argv) > 2 else ['carbon', 'stone', 'crystal', 'ice']); COUNT = int(sys.argv[3]) if len(sys.argv) > 3 else 8
SUB = int(os.environ.get('ROCK_SUB', '0'))
import bpy, bmesh, numpy as np
from mathutils import Vector, Matrix, noise
os.makedirs(OUT, exist_ok=True)
# per type: base subdiv, elongation range, big-shape noise, crater count/size, strata, fine roughness, crystal spikes, low-poly tris
P = {
 'carbon':  dict(sub=7, elong=(1.0, 1.7), lump=.32, lumpf=1.3, craters=(10, 22), crad=(.08, .3), strata=0, rough=.035, spikes=0, tris=2400),
 'stone':   dict(sub=7, elong=(1.1, 2.0), lump=.26, lumpf=1.0, craters=(4, 10), crad=(.1, .35), strata=.06, rough=.025, spikes=0, tris=2400, facet=.22),
 'crystal': dict(sub=6, elong=(1.0, 1.5), lump=.22, lumpf=1.2, craters=(3, 7), crad=(.08, .25), strata=0, rough=.02, spikes=(7, 14), tris=3000, facet=.12),
 'ice':     dict(sub=7, elong=(1.0, 1.6), lump=.2, lumpf=.9, craters=(2, 6), crad=(.12, .4), strata=0, rough=.012, spikes=0, tris=2000, cracks=.03),
}
def fbm(p, oct=5, lac=2.0, g=.5):
    a, f, s = 1.0, 1.0, 0.0
    for _ in range(oct): s += a * noise.noise(p * f); a *= g; f *= lac
    return s
def make_rock(kind, seed):
    q = P[kind]; rnd = random.Random(seed); off = Vector((rnd.uniform(-99, 99), rnd.uniform(-99, 99), rnd.uniform(-99, 99)))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=(SUB or q['sub']), radius=1.0)
    el = rnd.uniform(*q['elong']); sq = rnd.uniform(.7, 1.0)
    craters = [(Vector((rnd.gauss(0, 1), rnd.gauss(0, 1), rnd.gauss(0, 1))).normalized(), rnd.uniform(*q['crad'])) for _ in range(rnd.randint(*q['craters']))]
    sdir = Vector((rnd.gauss(0, 1), rnd.gauss(0, 1), rnd.gauss(0, 1))).normalized()
    facets = [(Vector((rnd.gauss(0, 1), rnd.gauss(0, 1), rnd.gauss(0, 1))).normalized(), rnd.uniform(.72, .95)) for _ in range(rnd.randint(3, 7))] if q.get('facet') else []
    for v in bm.verts:
        n = v.co.normalized(); p = n * 1.0
        r = 1.0 + q['lump'] * fbm(p * q['lumpf'] + off, 4)
        # chunky planar breaks (fractured faces) for stone/crystal
        for fn, d in facets:  # planar fracture faces: clamp the surface onto the plane n.fn = d
            h = n.dot(fn)
            if h > .05 and r * h > d: r = d / h + q['facet'] * .04 * fbm(p * 14 + off, 2)
        # craters: bowl + raised rim
        for cn, cr in craters:
            a = math.acos(max(-1, min(1, n.dot(cn)))) / cr
            if a < 1.0: r -= .12 * cr * (1 - a * a) ** 1.5 * 3
            elif a < 1.6: r += .05 * cr * math.sin((a - 1) / .6 * math.pi) * 3
        if q['strata']: r += q['strata'] * (abs(math.sin(n.dot(sdir) * 22 + fbm(p * 3 + off, 2) * 2)) - .5) * .5
        if q.get('cracks'): r -= q['cracks'] * max(0, .08 - abs(noise.noise(p * 4 + off))) * 12
        r += q['rough'] * fbm(p * 9 + off, 4) + q['rough'] * .5 * fbm(p * 30 + off, 3)
        v.co = Vector((n.x * r * el, n.y * r * sq, n.z * r))
    me = bpy.data.meshes.new('rock'); bm.to_mesh(me); bm.free(); ob = bpy.data.objects.new('rock', me); bpy.context.collection.objects.link(ob)
    if q['spikes']:  # crystal clusters growing out of the rock
        for i in range(rnd.randint(*q['spikes'])):
            bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=rnd.uniform(.08, .2), radius2=0.0, depth=rnd.uniform(.4, .9))
            c = bpy.context.active_object; d = Vector((rnd.gauss(0, 1), rnd.gauss(0, 1), rnd.gauss(0, 1))).normalized()
            c.rotation_mode = 'QUATERNION'; c.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d)
            dep = c.dimensions.z; c.location = Vector((d.x * el, d.y * sq, d.z)) * (.95 + q['lump'] * .3) + d * dep * .25
        for o in bpy.context.scene.objects: o.select_set(True)
        bpy.context.view_layer.objects.active = ob; bpy.ops.object.join(); bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return ob
def to_json(ob, path, tris):
    me = ob.data; P0 = np.array([v.co[:] for v in me.vertices])
    mn, mx = P0.min(0), P0.max(0); c = (mn + mx) / 2; L = (mx - mn)[0]
    for v in me.vertices: v.co = ((np.array(v.co[:]) - c) / L).tolist()
    me.update(); hp = os.path.splitext(path)[0] + '_hi.glb'
    bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=hp, use_selection=True, export_format='GLB', export_normals=True, export_apply=True)
    d = ob.modifiers.new('dec', 'DECIMATE'); d.ratio = min(1.0, tris / max(1, len(me.polygons))); bpy.ops.object.modifier_apply(modifier='dec')
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.triangulate(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = True
    me.update()
    pos = np.array([v.co[:] for v in me.vertices], np.float32); nor = np.array([v.normal[:] for v in me.vertices], np.float32)
    idx = np.array([list(p.vertices) for p in me.polygons], np.uint32).ravel(); nv = len(pos)
    ext = np.abs(pos).max(0) + 1e-6
    js = {'v': 1, 'ext': ext.tolist(), 'size': (pos.max(0) - pos.min(0)).tolist(), 'n': nv, 't': int(len(idx) // 3), 'i32': nv >= 65535, 'rock': 1,
          'p': base64.b64encode(np.round(pos / ext * 32767).astype(np.int16).tobytes()).decode(), 'q': base64.b64encode(np.round(nor * 127).astype(np.int8).tobytes()).decode(),
          'i': base64.b64encode((idx.astype(np.uint16) if nv < 65535 else idx).tobytes()).decode()}
    json.dump(js, open(path, 'w')); return js['t']
for kind in TYPES:
    for i in range(COUNT):
        code = 'R%s%02d' % (kind[:2].upper(), i); ob = make_rock(kind, sum(map(ord, kind)) * 1000 + i * 7919)
        t = to_json(ob, os.path.join(OUT, code + '.json'), P[kind]['tris']); print('rock', code, kind, 'tris', t, flush=True)
