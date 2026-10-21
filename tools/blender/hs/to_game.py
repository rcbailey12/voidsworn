# Hunyuan-frame Blender model (length along Y) -> decimated game JSON, oriented to match the current game hull (chamfer fit over 4 yaw choices).
# usage: python3 to_game.py model.blend ref_game.json out.json [tris=38000]
import sys, json, base64, math, subprocess, numpy as np, bpy
from scipy.spatial import cKDTree
src, ref, out = sys.argv[1], sys.argv[2], sys.argv[3]; TRIS = int(sys.argv[4]) if len(sys.argv) > 4 else 38000
bpy.ops.wm.open_mainfile(filepath=src); o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]
bpy.context.view_layer.objects.active = o; o.select_set(True)
for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
n0 = len(o.data.polygons); d = o.modifiers.new('dc', 'DECIMATE'); d.ratio = min(1, TRIS / n0); bpy.ops.object.modifier_apply(modifier='dc')
bpy.ops.object.shade_auto_smooth(angle=math.radians(40))
for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
j = json.load(open(ref)); ext = np.array(j['ext']); RP = np.frombuffer(base64.b64decode(j['p']), np.int16).reshape(-1, 3) / 32767 * ext
V = np.array([v.co[:] for v in o.data.vertices]); best = None
for yaw in (0, 1, 2, 3):
    for flip in (1, -1):
        R = np.array([[math.cos(yaw * math.pi / 2), -math.sin(yaw * math.pi / 2), 0], [math.sin(yaw * math.pi / 2), math.cos(yaw * math.pi / 2), 0], [0, 0, 1]])
        W = V @ R.T; W[:, 1] *= flip; G = np.stack([W[:, 0], W[:, 2], -W[:, 1]], 1); lo, hi = G.min(0), G.max(0)
        if hi[0] - lo[0] < (hi - lo).max() * .9: continue  # length must run along x
        G = (G - (lo + hi) / 2) / (hi[0] - lo[0]); t = cKDTree(RP); dd = t.query(G[::7])[0].mean() + cKDTree(G).query(RP[::7])[0].mean()
        if best is None or dd < best[0]: best = (dd, yaw, flip)
print('fit', best)
dd, yaw, flip = best; R = np.array([[math.cos(yaw * math.pi / 2), -math.sin(yaw * math.pi / 2), 0], [math.sin(yaw * math.pi / 2), math.cos(yaw * math.pi / 2), 0], [0, 0, 1]])
M = np.diag([1, flip, 1]) @ R
import mathutils
o.data.transform(mathutils.Matrix(np.pad(M, ((0, 1), (0, 1))).tolist())); o.data.transform(mathutils.Matrix.Identity(4))
if flip < 0: o.data.flip_normals()
o.data.update(); tmp = out + '.blend'; bpy.ops.wm.save_as_mainfile(filepath=tmp)
subprocess.run([sys.executable, __import__('os').path.join(__import__('os').path.dirname(__file__), 'export_json.py'), tmp, out], check=True)
