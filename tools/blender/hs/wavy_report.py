# Wavy-panel report (detection only, owner Oct 22: "show me first"): finds the big near-flat plates on an AI hull the same way planesnap.py
# does, fits a plane to each, and measures how far the surface wanders from it. Nothing is changed. Writes a heat-map render sheet
# (grey = curved or small, blue = flat enough, yellow to red = wavy and worth flattening) and a text list placed in the 9-cell blob grid.
# usage: blender -b -P wavy_report.py -- hull.glb out_prefix [angle_deg=14] [tol=0.006] [min_area=0.0015]
import sys, os, math, collections, json, numpy as np, bpy, mathutils
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
src, pre = argv[0], argv[1]; ANG = math.radians(float(argv[2]) if len(argv) > 2 else 14); TOL = float(argv[3]) if len(argv) > 3 else .006; AMIN = float(argv[4]) if len(argv) > 4 else .0015
RMS_BAD, P95_BAD = .0012, .0025  # in ship lengths; first guesses, to be tuned on C19 against the owner's own calls (side blocks wavy, bow wavy)
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]; bpy.context.view_layer.objects.active = o; o.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
me = o.data; me.calc_loop_triangles()
V = np.zeros(len(me.vertices) * 3); me.vertices.foreach_get('co', V); V = V.reshape(-1, 3)
F = np.zeros(len(me.loop_triangles) * 3, np.int64); me.loop_triangles.foreach_get('vertices', F); F = F.reshape(-1, 3)
L = V[:, 0].max() - V[:, 0].min(); nv, nf = len(V), len(F); print('verts', nv, 'tris', nf, 'length', round(L, 3), flush=True)
c = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]]); A = np.linalg.norm(c, axis=1) / 2; N = c / np.maximum(2 * A[:, None], 1e-12)
vn = np.zeros((nv, 3)); np.add.at(vn, F.ravel(), np.repeat(N * A[:, None], 3, 0)); vn /= np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-12)
Ns = vn[F].mean(1); Ns /= np.maximum(np.linalg.norm(Ns, axis=1, keepdims=True), 1e-12)
# weld by position so the GLB's UV-seam splits don't cut plates apart
key = np.round(V / (L * 1e-5)).astype(np.int64); _, wid = np.unique(key, axis=0, return_inverse=True); FW = wid.reshape(-1)[F]; nw = FW.max() + 1
E = np.concatenate([FW[:, [0, 1]], FW[:, [1, 2]], FW[:, [2, 0]]]); E.sort(1); fid = np.tile(np.arange(nf), 3)
k2 = E[:, 0] * nw + E[:, 1]; order = np.argsort(k2); ks = k2[order]; fo = fid[order]; same = ks[1:] == ks[:-1]
adj = [[] for _ in range(nf)]
for a, b in zip(fo[:-1][same], fo[1:][same]): adj[a].append(b); adj[b].append(a)
C = V[F].mean(1); cosA = math.cos(ANG); tol = TOL * L; amin = AMIN * L * L
region = -np.ones(nf, np.int64); plates = []
for s in np.argsort(-A):
    if region[s] != -1: continue
    n0 = Ns[s]; d0 = n0 @ C[s]; rid = len(plates); mem = [s]; region[s] = rid; q = collections.deque([s]); area = A[s]; nsum = Ns[s] * A[s]
    while q:
        f = q.popleft()
        for g in adj[f]:
            if region[g] != -1 or Ns[g] @ n0 < cosA or abs(n0 @ C[g] - d0) > tol * 1.5: continue
            region[g] = rid; mem.append(g); q.append(g); area += A[g]; nsum += Ns[g] * A[g]
            if len(mem) % 200 == 0:
                m = np.array(mem); w = A[m]; cen = (C[m] * w[:, None]).sum(0) / w.sum(); n0 = nsum / np.linalg.norm(nsum); d0 = n0 @ cen
    m = np.array(mem)
    if area < amin: region[m] = -2 - rid; plates.append(None); continue
    w = A[m]; cen = (C[m] * w[:, None]).sum(0) / w.sum(); _, _, vt = np.linalg.svd((C[m] - cen) * np.sqrt(w)[:, None], full_matrices=False); n = vt[2]; n = n if n @ nsum > 0 else -n  # outward, like its faces
    vi = np.unique(F[m]); r = np.abs((V[vi] - cen) @ n) / L
    plates.append(dict(id=rid, faces=m, area=area / (L * L), rms=float(np.sqrt((r ** 2).mean())), p95=float(np.percentile(r, 95)), cen=cen, n=n))
P = [p for p in plates if p]; print('plates', len(P), flush=True)
x0, x1 = V[:, 0].min(), V[:, 0].max(); z0, z1 = V[:, 2].min(), V[:, 2].max()
def cell(p):  # bow is -x in this frame
    t = (p['cen'][0] - x0) / (x1 - x0); along = 'bow' if t < 1 / 3 else ('midship' if t < 2 / 3 else 'stern')
    nz = p['n'][2]; face = 'top' if nz > .6 else ('below' if nz < -.6 else 'side'); return along, face
heat = np.full((nf, 3), .35)
rows = []
for p in P:
    bad = p['rms'] > RMS_BAD or p['p95'] > P95_BAD; sev = min(1., max(p['rms'] / RMS_BAD, p['p95'] / P95_BAD) / 3)
    heat[p['faces']] = (1., 1. - .85 * sev, .1) if bad else (.25, .45, .9)
    if bad: rows.append((p['rms'], cell(p), p))
rows.sort(key=lambda r: -r[0])
lines = [f'Wavy-panel report for {src}: {len(P)} big flat plates, {len(rows)} wavy (RMS > {RMS_BAD} L or 95th percentile > {P95_BAD} L).']
for i, (rms, (al, fa), p) in enumerate(rows):
    lines.append(f'{i + 1:2d}. {al}, {fa}: {100 * p["area"]:.2f}% of the hull area, waviness RMS {p["rms"]:.4f} L, worst 5% {p["p95"]:.4f} L, centre ({p["cen"][0]:.3f}, {p["cen"][1]:.3f}, {p["cen"][2]:.3f})')
open(pre + '_wavy.txt', 'w').write('\n'.join(lines) + '\n'); print('\n'.join(lines[:25]))
json.dump([dict(n=i + 1, cell=list(cl), area=p['area'], rms=p['rms'], p95=p['p95'], cen=p['cen'].tolist(), normal=p['n'].tolist()) for i, (_, cl, p) in enumerate(rows)], open(pre + '_wavy.json', 'w'), indent=1)
# heat map as per-corner colours, rendered from the standard angles
# heat map as five flat materials per triangle-owning polygon (robust in every Blender build): grey, blue, yellow, orange, red
mats = []
for nm, rgb in (('curved', (.30, .30, .32)), ('flat', (.15, .35, .85)), ('wavy1', (1., .85, .1)), ('wavy2', (1., .45, .05)), ('wavy3', (.95, .08, .05))):
    mt = bpy.data.materials.new(nm); mt.diffuse_color = (*rgb, 1)
    try:
        mt.use_nodes = True; mt.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (*rgb, 1); mt.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = .6
    except Exception: pass
    mats.append(mt)
me.materials.clear()
for mt in mats: me.materials.append(mt)
bucket = np.zeros(nf, np.int64)
for p in P:
    bad = p['rms'] > RMS_BAD or p['p95'] > P95_BAD; sev = max(p['rms'] / RMS_BAD, p['p95'] / P95_BAD)
    bucket[p['faces']] = (2 if sev < 1.5 else 3 if sev < 2.2 else 4) if bad else 1
pi = np.zeros(len(me.loop_triangles), np.int64); me.loop_triangles.foreach_get('polygon_index', pi)
pm = np.zeros(len(me.polygons), np.int64); np.maximum.at(pm, pi, bucket); me.polygons.foreach_set('material_index', pm)
if os.environ.get('KIT'):  # show the hand-built parts too (in plain white), so the cut edges where they attach don't read as damage
    before = set(bpy.context.scene.objects); bpy.ops.import_scene.gltf(filepath=os.environ['KIT']); wm = bpy.data.materials.new('kitwhite'); wm.diffuse_color = (.85, .85, .85, 1)
    try: wm.use_nodes = True; wm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (.85, .85, .85, 1)
    except Exception: pass
    for ob in set(bpy.context.scene.objects) - before:
        if ob.type == 'MESH': ob.data.materials.clear(); ob.data.materials.append(wm); [setattr(pl, 'material_index', 0) for pl in ob.data.polygons]
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 12; sc.render.resolution_x, sc.render.resolution_y = 900, 600
try:
    pr = bpy.context.preferences.addons['cycles'].preferences
    for t_ in ('OPTIX', 'CUDA'):
        try:
            pr.compute_device_type = t_; pr.get_devices()
            if any(d.type == t_ for d in pr.devices):
                for d in pr.devices: d.use = d.type == t_
                sc.cycles.device = 'GPU'; break
        except Exception: pass
except Exception: pass
sc.world = bpy.data.worlds.new('w'); sc.world.use_nodes = True; sc.world.node_tree.nodes['Background'].inputs[0].default_value = (.06, .065, .08, 1)
for en, rot in ((5., (math.radians(50), 0, math.radians(30))), (2., (math.radians(70), 0, math.radians(200)))):
    l = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); l.data.energy = en; l.rotation_euler = rot; sc.collection.objects.link(l)
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam
ctr = mathutils.Vector(((x0 + x1) / 2, 0, (z0 + z1) / 2)); d = L * 1.9
for k, (az, el) in enumerate(((146, 14), (90, 4), (90, 85), (270, 4), (90, -60), (20, 20))):
    a, e = math.radians(az), math.radians(el); cam.location = ctr + mathutils.Vector((math.cos(a) * math.cos(e), -math.sin(a) * math.cos(e), math.sin(e))) * d
    cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler(); sc.render.filepath = f'{pre}_wavy{k}.png'; bpy.ops.render.render(write_still=True)
print('wrote', pre + '_wavy.txt')
