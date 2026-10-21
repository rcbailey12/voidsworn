# TRELLIS.2 painted GLB -> game hull: welded + decimated low mesh, fresh UVs, baked concept paint (albedo), tangent normal map
# and AO/curvature map from the full-detail TRELLIS mesh. Output matches hullbake.py (CODE.json with 'u'+'tex', _n/_m webp)
# plus the painted albedo (_a webp, 'alb' flag; the albedo shares the 'u' UVs).
# usage: python3 trellis_bake.py in.glb ref_game.json|- out_dir CODE TRIS RES   (env FLAT=1: stations, thin axis up; YAW=0..3 forces the heading)
import sys, os, json, base64, math, time, numpy as np, bpy, bmesh
from scipy.spatial import cKDTree
src, ref, outd, CODE, TRIS, RES = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5]), int(sys.argv[6])
os.makedirs(outd, exist_ok=True); T0 = time.time()
def log(*a): print('[tbake]', CODE, *a, '%.0fs' % (time.time() - T0), flush=True)
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
ms = [x for x in bpy.context.scene.objects if x.type == 'MESH']
for x in bpy.context.scene.objects: x.select_set(x.type == 'MESH')
bpy.context.view_layer.objects.active = ms[0]
if len(ms) > 1: bpy.ops.object.join()
hi = bpy.context.view_layer.objects.active; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True); hi.name = 'high'
H = np.array([v.co[:] for v in hi.data.vertices])

# ---------- heading: same as the current game hull (so turrets, engines and gameplay bow stay put) ----------
def to_game(V, yaw):
    c, s = math.cos(yaw * math.pi / 2), math.sin(yaw * math.pi / 2); R = np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])
    W = V @ R.T; return np.stack([W[:, 0], W[:, 2], -W[:, 1]], 1)
yaw = int(os.environ['YAW']) if os.environ.get('YAW') else None
if yaw is None:
    yaw = 0
    if ref != '-' and not os.environ.get('FLAT'):
        j = json.load(open(ref)); RP = np.frombuffer(base64.b64decode(j['p']), np.int16).reshape(-1, 3) / 32767 * np.array(j['ext']); t = cKDTree(RP); best = None; S = H[::7]
        for y in range(4):
            G = to_game(S, y); lo_, hi_ = G.min(0), G.max(0)
            if hi_[0] - lo_[0] < (hi_ - lo_).max() * .9 and not os.environ.get('ANYLEN'): continue  # length runs along the bow axis
            G = (G - (lo_ + hi_) / 2) / (hi_[0] - lo_[0]); dd = t.query(G)[0].mean() + cKDTree(G).query(RP[::5])[0].mean()
            log('yaw', y, 'fit %.4f' % dd)
            if best is None or dd < best[0]: best = (dd, y)
        if best is None: log('no heading has the length along x; using 0'); best = (0, 0)
        yaw = best[1]
G = to_game(H, yaw); lo_, hi_ = G.min(0), G.max(0); G = (G - (lo_ + hi_) / 2) / (hi_[0] - lo_[0])  # game frame: length 1 along x, centred
hi.data.vertices.foreach_set('co', G.ravel()); hi.data.update(); log('yaw', yaw, 'hi faces', len(hi.data.polygons))

# ---------- paint source: the GLB base colour as emission (bakes the paint exactly, whatever the metal/rough settings) ----------
for mt in hi.data.materials:
    nt = mt.node_tree; bc = next((n for n in nt.nodes if n.type == 'TEX_IMAGE' and n.outputs[0].links and n.outputs[0].links[0].to_socket.name == 'Base Color'), None)
    if bc is None: continue
    em = nt.nodes.new('ShaderNodeEmission'); out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL'); nt.links.new(bc.outputs[0], em.inputs[0]); nt.links.new(em.outputs[0], out.inputs[0])

# ---------- low mesh: weld the UV-seam splits (else decimation tears the islands apart), decimate, smooth, fresh UVs ----------
lo = hi.copy(); lo.data = hi.data.copy(); lo.name = 'low'; bpy.context.collection.objects.link(lo)
lo.data.materials.clear()
bm = bmesh.new(); bm.from_mesh(lo.data); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=2e-5)
bm.to_mesh(lo.data); bm.free(); lo.data.update(); log('welded verts', len(lo.data.vertices))
bpy.ops.object.select_all(action='DESELECT'); lo.select_set(True); bpy.context.view_layer.objects.active = lo
n0 = len(lo.data.polygons)
if n0 > TRIS:
    d = lo.modifiers.new('dc', 'DECIMATE'); d.ratio = TRIS / n0; d.use_collapse_triangulate = True; bpy.ops.object.modifier_apply(modifier='dc')
tr = lo.modifiers.new('tr', 'TRIANGULATE'); bpy.ops.object.modifier_apply(modifier='tr')
for p in lo.data.polygons: p.use_smooth = True
bpy.ops.object.shade_auto_smooth(angle=math.radians(45))
for m in list(lo.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
while lo.data.uv_layers: lo.data.uv_layers.remove(lo.data.uv_layers[0])
import xatlas  # charts + packing far tighter than Blender's smart project on a decimated scan-like mesh
me = lo.data; LP = np.array([v.co[:] for v in me.vertices], np.float32); LI = np.array([[me.loops[li].vertex_index for li in p.loop_indices] for p in me.polygons], np.uint32)
at = xatlas.Atlas(); at.add_mesh(LP, LI)
co_ = xatlas.ChartOptions(); co_.max_iterations = 2; co_.normal_deviation_weight = 2.0; co_.max_cost = 2.0
po = xatlas.PackOptions(); po.resolution = RES; po.padding = max(2, RES // 512); po.bilinear = True; po.blockAlign = True
at.generate(co_, po); vm, Iu, UVx = at[0]; Iu = np.asarray(Iu); UVx = np.asarray(UVx, np.float64); log('xatlas charts', at.chart_count, 'util %.2f' % at.utilization)
uvl_ = me.uv_layers.new(name='UVMap'); LU = UVx[Iu.ravel()]  # xatlas keeps face order and corner order
uvl_.data.foreach_set('uv', LU.ravel().astype(np.float32))
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.object.mode_set(mode='OBJECT'); log('low tris', len(lo.data.polygons))

# ---------- bakes ----------
sc = bpy.context.scene; sc.render.engine = 'CYCLES'
try:
    pr = bpy.context.preferences.addons['cycles'].preferences
    for t_ in ('OPTIX', 'CUDA', 'HIP', 'METAL'):
        try:
            pr.compute_device_type = t_; pr.get_devices()
            if any(d.type == t_ for d in pr.devices):
                for d in pr.devices: d.use = d.type == t_
                sc.cycles.device = 'GPU'; log('device', t_); break
        except Exception: pass
except Exception: pass
sc.cycles.samples = 4; sc.render.bake.margin = max(4, RES // 256)
def make_img(name, col=False):
    im = bpy.data.images.new(name, RES, RES, alpha=False, float_buffer=False); im.colorspace_settings.name = 'sRGB' if col else 'Non-Color'; return im
mat = bpy.data.materials.new('bake'); mat.use_nodes = True; lo.data.materials.append(mat)
tex = mat.node_tree.nodes.new('ShaderNodeTexImage'); mat.node_tree.nodes.active = tex
def bake(kind, img, sel=True, **kw):
    tex.image = img; bpy.ops.object.select_all(action='DESELECT')
    if sel: hi.select_set(True)
    lo.select_set(True); bpy.context.view_layer.objects.active = lo
    sc.render.bake.use_selected_to_active = sel
    if sel: sc.render.bake.cage_extrusion = .006; sc.render.bake.max_ray_distance = .02
    bpy.ops.object.bake(type=kind, **kw); log('baked', kind)
imC = make_img(CODE + '_a', True); bake('EMIT', imC)
imN = make_img(CODE + '_n'); bake('NORMAL', imN, normal_space='TANGENT')
sc.cycles.samples = 48; hi.hide_render = True
imA = make_img(CODE + '_ao'); bake('AO', imA, sel=False); hi.hide_render = False

def arr(im): return np.array(im.pixels[:], dtype=np.float32).reshape(RES, RES, 4)
n = arr(imN)[..., :3] * 2 - 1; ao = arr(imA)[..., 0]
dx = np.roll(n[..., 0], -1, 1) - np.roll(n[..., 0], 1, 1); dy = np.roll(n[..., 1], -1, 0) - np.roll(n[..., 1], 1, 0)
curv = np.clip(.5 + (dx + dy) * 2.5, 0, 1); cov = (np.abs(n[..., 2]) > .05)
m = np.zeros((RES, RES, 4), np.float32); m[..., 0] = np.where(cov, ao, 1); m[..., 1] = np.where(cov, curv, .5); m[..., 2] = 1; m[..., 3] = 1
imM = bpy.data.images.new(CODE + '_m', RES, RES, alpha=False); imM.colorspace_settings.name = 'Non-Color'; imM.pixels[:] = m.ravel()
st = sc.render.image_settings; st.file_format = 'WEBP'; st.quality = 90; st.color_mode = 'RGB'
for im, suf in ((imC, '_a'), (imN, '_n'), (imM, '_m')): im.save_render(os.path.join(outd, CODE + suf + '.webp'), scene=sc)
if os.path.exists(os.environ.get('CONCEPT') or '/nonexistent'):  # lift the paint toward the concept art's brightness (TRELLIS de-lights it about 2.5x too dark)
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import paint_level; log('paint level', paint_level.level(os.path.join(outd, CODE + '_a.webp'), os.environ['CONCEPT']))

# ---------- export: unique (vertex, normal, uv) ----------
me = lo.data; uvl = me.uv_layers.active.data; co = np.array([v.co[:] for v in me.vertices]); keys = {}; P = []; N = []; U = []; I = []
for poly in me.polygons:
    tri = []
    for li in poly.loop_indices:
        l = me.loops[li]; nn = l.normal[:]; uv = uvl[li].uv[:]; k = (l.vertex_index, round(nn[0], 2), round(nn[1], 2), round(nn[2], 2), round(uv[0] * 65535), round(uv[1] * 65535))
        if k not in keys: keys[k] = len(P); P.append(co[l.vertex_index]); N.append(nn); U.append(uv)
        tri.append(keys[k])
    I.append(tri)
P = np.array(P); N = np.array(N); N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-6); U = np.clip(np.array(U), 0, 1); I = np.array(I)
ext = np.abs(P).max(0); i32 = len(P) >= 65535
J = {'v': 1, 'ext': ext.tolist(), 'n': len(P), 't': len(I), 'i32': i32, 'src': 'trellis2', 'yaw': yaw,
     'p': base64.b64encode(np.round(P / ext * 32767).astype(np.int16).tobytes()).decode(),
     'q': base64.b64encode(np.round(N * 127).astype(np.int8).tobytes()).decode(),
     'i': base64.b64encode(I.astype(np.uint32 if i32 else np.uint16).ravel().tobytes()).decode(),
     'u': base64.b64encode(np.round(U * 65535).astype(np.uint16).tobytes()).decode(), 'tex': {'res': RES, 'v': 1}, 'alb': {'res': RES, 'v': 1}}
json.dump(J, open(os.path.join(outd, CODE + '.json'), 'w'))
log('done verts', len(P), 'tris', len(I), 'ext', ext.round(3).tolist())
