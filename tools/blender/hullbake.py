# Voidsworn per-hull bake: game mesh + high-poly Hunyuan GLB -> UV'd game JSON + normal map + AO/curvature map.
# usage: blender -b --factory-startup -P hullbake.py -- <high.glb> <ref.json> <out_dir> <res> [ops,comma,separated]
#   ref.json = the current game hull (hulls_hi/CODE.json). Output: out_dir/CODE.json (adds 'u' uvs), CODE_n.webp, CODE_m.webp
#   ops: flat / tall / swapxz / flipx (same meaning as r11/fix.py; only needed if auto-alignment fails)
import sys, os, json, base64, math, time
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
if argv and argv[0].endswith('.py'): argv = argv[1:]
HIGH, REF, OUT, RES = argv[0], argv[1], argv[2], int(argv[3]); OPS = (argv[4].split(',') if len(argv) > 4 and argv[4] else [])
import bpy, bmesh, numpy as np
from mathutils import Vector, Matrix
from mathutils.kdtree import KDTree
CODE = os.path.splitext(os.path.basename(REF))[0]; os.makedirs(OUT, exist_ok=True); T0 = time.time()
def log(*a): print('[bake]', CODE, *a, flush=True)

# ---------- reference game mesh ----------
j = json.load(open(REF)); ext = np.array(j['ext'])
P = np.frombuffer(base64.b64decode(j['p']), np.int16).reshape(-1, 3).astype(np.float64) / 32767 * ext
N = np.frombuffer(base64.b64decode(j['q']), np.int8).reshape(-1, 3).astype(np.float64) / 127
I = np.frombuffer(base64.b64decode(j['i']), np.uint32 if j.get('i32') else np.uint16).reshape(-1, 3).astype(np.int64)
A = np.frombuffer(base64.b64decode(j['a']), np.uint8).astype(np.float64) / 255 if 'a' in j else None
from mathutils.bvhtree import BVHTree
bvh = BVHTree.FromPolygons([Vector(p) for p in P.tolist()], I.tolist(), all_triangles=True)
class _KD:
    def find(self, x):
        r = bvh.find_nearest(Vector(x));
        return (np.array(r[0][:]) if r[0] is not None else np.array(x), None, r[3] if r[0] is not None else 9.0)
kd = _KD()

# ---------- high-poly, aligned into the game frame ----------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=HIGH)
ms = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in bpy.context.scene.objects: o.select_set(o.type == 'MESH')
bpy.context.view_layer.objects.active = ms[0]
if len(ms) > 1: bpy.ops.object.join()
hi = bpy.context.view_layer.objects.active; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if 'keep_main' in OPS:  # drop detached extra parts (same rule as r11/fix.py): keep the biggest piece and pieces centred inside its box
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.mesh.separate(type='LOOSE'); bpy.ops.object.mode_set(mode='OBJECT')
    parts = [o for o in bpy.context.scene.objects if o.type == 'MESH']; parts.sort(key=lambda o: len(o.data.polygons), reverse=True)
    def box(o): V = np.array([v.co[:] for v in o.data.vertices]); return V.min(0), V.max(0), V.mean(0)
    lo0, hi0, _ = box(parts[0]); pad = (hi0 - lo0) * .08; keep = [parts[0]]
    for o in parts[1:]:
        c_ = box(o)[2]
        (keep.append(o) if np.all((c_ >= lo0 - pad) & (c_ <= hi0 + pad)) else bpy.data.objects.remove(o))
    log('keep_main kept', len(keep), 'of', len(parts), 'pieces')
    for o in keep: o.select_set(True)
    bpy.context.view_layer.objects.active = keep[0]
    if len(keep) > 1: bpy.ops.object.join()
    hi = bpy.context.view_layer.objects.active
H = np.array([v.co[:] for v in hi.data.vertices]); c = H.mean(0); Q = H - c
def bexport_frame(Q, flat):  # same maths as scripts/bexport.py
    if flat:
        w3, V3 = np.linalg.eigh(np.cov(Q.T)); ex, ey = V3[:, 2], V3[:, 0]; ez = np.cross(ex, ey)
        A_ = np.stack([Q @ ex, Q @ ey, Q @ ez], 1)
        if (A_[:, 1] ** 3).sum() < 0: A_[:, 1] *= -1; A_[:, 2] *= -1
    else:
        H2 = Q[:, :2]; w2, V2 = np.linalg.eigh(np.cov(H2.T)); ax = V2[:, np.argmax(w2)]
        ang = math.atan2(ax[1], ax[0]); ca, sa = math.cos(-ang), math.sin(-ang)
        gx = Q[:, 0] * ca - Q[:, 1] * sa; gz = -(Q[:, 0] * sa + Q[:, 1] * ca); gy = Q[:, 2]; A_ = np.stack([gx, gy, gz], 1)
    lo, hi_ = np.percentile(A_[:, 0], [8, 92]); sp = lambda m: np.ptp(A_[m][:, 2]) + np.ptp(A_[m][:, 1]) if m.sum() > 10 else 1e9
    if sp(A_[:, 0] > hi_) > sp(A_[:, 0] < lo): A_[:, 0] *= -1; A_[:, 2] *= -1
    mn, mx = A_.min(0), A_.max(0); A_ = A_ - (mn + mx) / 2; return A_ / (mx - mn)[0]
rng = np.random.default_rng(1); samp = rng.choice(len(H), min(4000, len(H)), replace=False)
def err(X):  # mean distance from sampled high verts to the game mesh verts (robust: median)
    return float(np.median([kd.find(X[k])[2] for k in samp]))
def fit(X, rot=True):  # refine a similarity transform (rotation, uniform scale, translation) against the game mesh surface
    for it in range(8):
        S = X[samp]; nn = np.array([kd.find(s)[0] for s in S]); d = np.linalg.norm(S - nn, axis=1); m = d < max(.004, np.percentile(d, 70))
        if m.sum() < 50: break
        a, b = S[m], nn[m]; ca_, cb = a.mean(0), b.mean(0); a0, b0 = a - ca_, b - cb
        R = np.eye(3)
        if rot:
            U_, s_, Vt = np.linalg.svd(a0.T @ b0); D = np.eye(3); D[2, 2] = np.sign(np.linalg.det(Vt.T @ U_.T)); R = Vt.T @ D @ U_.T
        s = np.sqrt((b0 ** 2).sum() / max(1e-9, (a0 ** 2).sum()))
        X = ((X - ca_) @ R.T) * s + cb
    return X
import itertools
ROTS = []
for perm in itertools.permutations(range(3)):
    for sg in itertools.product((1, -1), repeat=3):
        M = np.zeros((3, 3))
        for r, c_ in enumerate(perm): M[r, c_] = sg[r]
        if np.linalg.det(M) > 0: ROTS.append(M)
cands = []
for flat in (False, True):
    B = bexport_frame(Q, flat)
    for M in ROTS:
        X = B @ M.T
        if 'tall' in OPS:
            w, V = np.linalg.eigh(np.cov((X - X.mean(0)).T)); ey, ex = V[:, 2], V[:, 1]; ez = np.cross(ex, ey); X = (X - X.mean(0)) @ np.stack([ex, ey, ez]).T
        X = X - (X.min(0) + X.max(0)) / 2; X = X / np.ptp(X, 0).max() * np.ptp(P, 0).max()
        cands.append((err(X), flat, False, M, X))
cands.sort(key=lambda t: t[0]); best = None
for e0, flat, sw, f, X in cands[:4]:
    Xf = fit(X); e1 = err(Xf)
    if best is None or e1 < best[1]: best = (e0, e1, flat, f, Xf)
e0, e1, flat, f, X = best
log('align', 'flat' if flat else 'std', f.astype(int).tolist(), 'err %.4f -> %.4f' % (e0, e1))
for i, v in enumerate(hi.data.vertices): v.co = X[i].tolist()
hi.data.update(); hi.name = 'high'
if e1 > .02: log('WARNING alignment error high, bake may be poor')

# ---------- low-poly game mesh with fresh UVs (xatlas charts when available, else Blender smart project) ----------
VMAP = None
if 'u' in j:  # UVs prepared outside Blender (uvprep.py, xatlas)
    VMAP = np.arange(len(P)); I_uv = I; UV = np.frombuffer(base64.b64decode(j['u']), np.uint16).reshape(-1, 2).astype(np.float64) / 65535; log('using prepared UVs')
if VMAP is not None:
    PV = P[VMAP]; me = bpy.data.meshes.new('low'); me.from_pydata(PV.tolist(), [], I_uv.tolist()); me.update()
    uvl_ = me.uv_layers.new(name='UVMap')
    for poly in me.polygons:
        for li in poly.loop_indices: uvl_.data[li].uv = UV[me.loops[li].vertex_index]
else:
    me = bpy.data.meshes.new('low'); me.from_pydata(P.tolist(), [], I.tolist()); me.update()
lo = bpy.data.objects.new('low', me); bpy.context.collection.objects.link(lo)
for p in me.polygons: p.use_smooth = True
bpy.ops.object.select_all(action='DESELECT'); lo.select_set(True); bpy.context.view_layer.objects.active = lo
if VMAP is None:
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.004, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    try: bpy.ops.uv.pack_islands(margin=0.004, rotate=True)
    except Exception as ex: log('pack skipped', ex)
    bpy.ops.object.mode_set(mode='OBJECT')

# ---------- bake setup ----------
sc = bpy.context.scene; sc.render.engine = 'CYCLES'
try:
    pr = bpy.context.preferences.addons['cycles'].preferences
    for t in ('OPTIX', 'CUDA', 'HIP', 'METAL'):
        try:
            pr.compute_device_type = t; pr.get_devices()
            if any(d.type == t for d in pr.devices):
                for d in pr.devices: d.use = d.type == t
                sc.cycles.device = 'GPU'; log('device', t); break
        except Exception: pass
except Exception: pass
sc.cycles.samples = 16; sc.render.bake.margin = max(4, RES // 256)
def make_img(name, col=False):
    im = bpy.data.images.new(name, RES, RES, alpha=False, float_buffer=False); im.colorspace_settings.name = 'sRGB' if col else 'Non-Color'; return im
mat = bpy.data.materials.new('bake'); mat.use_nodes = True; lo.data.materials.append(mat)
nt = mat.node_tree; tex = nt.nodes.new('ShaderNodeTexImage'); nt.nodes.active = tex
def bake(kind, img, **kw):
    tex.image = img; t = time.time()
    bpy.ops.object.select_all(action='DESELECT')
    if kw.get('sel'):
        hi.select_set(True)
    lo.select_set(True); bpy.context.view_layer.objects.active = lo
    sc.render.bake.use_selected_to_active = bool(kw.get('sel'))
    if kw.get('sel'):
        sc.render.bake.cage_extrusion = kw.get('ext', .012); sc.render.bake.max_ray_distance = kw.get('ray', .03)
    bpy.ops.object.bake(type=kind, **({'normal_space': 'TANGENT'} if kind == 'NORMAL' else {}))
    log('baked', kind, '%.1fs' % (time.time() - t))
imN = make_img(CODE + '_n'); bake('NORMAL', imN, sel=True)
sc.cycles.samples = 64; hi.hide_render = True
imA = make_img(CODE + '_ao'); bake('AO', imA)
hi.hide_render = False

# ---------- post: curvature from the normal map, pack AO + curvature ----------
def arr(im): return np.array(im.pixels[:], dtype=np.float32).reshape(RES, RES, 4)
n = arr(imN)[..., :3] * 2 - 1; ao = arr(imA)[..., 0]
dx = np.roll(n[..., 0], -1, 1) - np.roll(n[..., 0], 1, 1); dy = np.roll(n[..., 1], -1, 0) - np.roll(n[..., 1], 1, 0)
curv = np.clip(.5 + (dx + dy) * 2.5, 0, 1)
cov = (np.abs(n[..., 2]) > .05)  # texels the bake touched
m = np.zeros((RES, RES, 4), np.float32); m[..., 0] = np.where(cov, ao, 1); m[..., 1] = np.where(cov, curv, .5); m[..., 2] = 1; m[..., 3] = 1
imM = bpy.data.images.new(CODE + '_m', RES, RES, alpha=False); imM.colorspace_settings.name = 'Non-Color'; imM.pixels[:] = m.ravel()
st = sc.render.image_settings
def save(im, path, res):
    st.file_format = 'WEBP'; st.quality = 90; st.color_mode = 'RGB'
    if res != RES:
        a = np.array(im.pixels[:], np.float32).reshape(RES, RES, 4); k = RES // res
        a = a.reshape(res, k, res, k, 4).mean((1, 3)); im2 = bpy.data.images.new(im.name + '_s', res, res, alpha=False)
        im2.colorspace_settings.name = im.colorspace_settings.name; im2.pixels[:] = a.ravel(); im = im2
    im.save_render(path, scene=sc)
for r, suf in ((RES, ''), (RES // 2, '_lo')):
    save(imN, os.path.join(OUT, CODE + '_n' + suf + '.webp'), r); save(imM, os.path.join(OUT, CODE + '_m' + suf + '.webp'), r)

# ---------- export: unique (vertex, uv) pairs ----------
if VMAP is not None:
    nv = np.asarray(VMAP, np.int64); U = np.clip(UV, 0, 1); P2 = P[nv]; N2 = N[nv]; I2 = I_uv.ravel()
else:
    uvl = me.uv_layers.active.data; keys = {}; nv = []; nu = []; idx = []
    for poly in me.polygons:
        for li in poly.loop_indices:
            vi = me.loops[li].vertex_index; uv = uvl[li].uv; k = (vi, round(uv[0] * 65535), round(uv[1] * 65535))
            if k not in keys: keys[k] = len(nv); nv.append(vi); nu.append((uv[0], uv[1]))
            idx.append(keys[k])
    nv = np.array(nv); U = np.clip(np.array(nu), 0, 1); P2 = P[nv]; N2 = N[nv]; I2 = np.array(idx, np.int64)
o = dict(j); o['n'] = len(P2); o['t'] = len(I2) // 3; o['i32'] = len(P2) >= 65535
o['p'] = base64.b64encode(np.round(P2 / ext * 32767).astype(np.int16).tobytes()).decode()
o['q'] = base64.b64encode(np.round(N2 * 127).astype(np.int8).tobytes()).decode()
o['i'] = base64.b64encode(I2.astype(np.uint32 if o['i32'] else np.uint16).tobytes()).decode()
o['u'] = base64.b64encode(np.round(U * 65535).astype(np.uint16).tobytes()).decode()
if A is not None: o['a'] = base64.b64encode(np.round(A[nv] * 255).astype(np.uint8).tobytes()).decode()
o['tex'] = {'res': RES, 'v': 1}
json.dump(o, open(os.path.join(OUT, CODE + '.json'), 'w'))
log('done verts', len(P), '->', len(P2), 'tris', o['t'], '%.1fs' % (time.time() - T0))
