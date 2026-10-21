# Blender model (X to the bow, Z up) -> game hull JSON (x to the bow, y up, length 1, centred), hard edges kept as split vertices.
# usage: python3 export_json.py model.blend out.json [glb_out]
import sys, json, base64, bpy, numpy as np
src, out = sys.argv[1], sys.argv[2]; glb = sys.argv[3] if len(sys.argv) > 3 else None
bpy.ops.wm.open_mainfile(filepath=src)
o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]; bpy.context.view_layer.objects.active = o; o.select_set(True)
m = o.modifiers.new('tri', 'TRIANGULATE'); m.keep_custom_normals = True; bpy.ops.object.modifier_apply(modifier='tri')
me = o.data; me.calc_loop_triangles() if hasattr(me, 'calc_loop_triangles') else None
co = np.array([v.co[:] for v in me.vertices]); keys = {}; P = []; N = []; I = []
for poly in me.polygons:
    tri = []
    for li in poly.loop_indices:
        l = me.loops[li]; n = l.normal[:]; k = (l.vertex_index, round(n[0], 2), round(n[1], 2), round(n[2], 2))
        if k not in keys: keys[k] = len(P); P.append(co[l.vertex_index]); N.append(n)
        tri.append(keys[k])
    I.append(tri)
P = np.array(P); N = np.array(N); I = np.array(I)
G = np.stack([P[:, 0], P[:, 2], -P[:, 1]], 1); GN = np.stack([N[:, 0], N[:, 2], -N[:, 1]], 1)  # Blender -> game axes
lo, hi = G.min(0), G.max(0); G = (G - (lo + hi) / 2) / (hi[0] - lo[0]); ext = np.abs(G).max(0)
GN /= np.maximum(np.linalg.norm(GN, axis=1, keepdims=True), 1e-6)
i32 = len(G) >= 65535
J = {'v': 1, 'ext': ext.tolist(), 'size': (hi - lo).tolist(), 'n': len(G), 't': len(I), 'i32': i32,
     'p': base64.b64encode(np.round(G / ext * 32767).astype(np.int16).tobytes()).decode(),
     'q': base64.b64encode(np.round(GN * 127).astype(np.int8).tobytes()).decode(),
     'i': base64.b64encode(I.astype(np.uint32 if i32 else np.uint16).ravel().tobytes()).decode()}
json.dump(J, open(out, 'w')); print('verts', len(G), 'tris', len(I), 'ext', ext.round(3))
if glb: bpy.ops.export_scene.gltf(filepath=glb, export_format='GLB', use_selection=True)
