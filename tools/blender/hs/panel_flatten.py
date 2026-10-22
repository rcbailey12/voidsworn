# Gentle flattening of the AI hull's wavy plates (owner, Oct 22: "maybe flatten them a bit?"). Finds the big near-flat plates exactly as
# wavy_report.py does, and for the ones over the waviness threshold moves each vertex part of the way (FLAT, default 0.6) toward the plate's
# fitted plane. Plate borders stay put (so creases and neighbours are untouched) and the next ring in moves half as far. Duplicated vertices
# at UV seams move together, so no cracks. Paint/UVs are kept; the GLB is re-exported with its texture.
# usage: blender -b -P panel_flatten.py -- in.glb out.glb   (env FLAT=0.6)
import sys, os, math, collections, numpy as np, bpy
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
src, dst = argv[0], argv[1]; FLAT = float(os.environ.get('FLAT', '.6'))
ANG, TOL, AMIN = math.radians(14), .006, .0015; RMS_BAD, P95_BAD = .0012, .0025  # same as wavy_report.py
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]; me = o.data; me.calc_loop_triangles()
V = np.zeros(len(me.vertices) * 3); me.vertices.foreach_get('co', V); V = V.reshape(-1, 3)
F = np.zeros(len(me.loop_triangles) * 3, np.int64); me.loop_triangles.foreach_get('vertices', F); F = F.reshape(-1, 3)
L = V[:, 0].max() - V[:, 0].min(); nv, nf = len(V), len(F); print('verts', nv, 'tris', nf, flush=True)
key = np.round(V / (L * 1e-5)).astype(np.int64); _, wid = np.unique(key, axis=0, return_inverse=True); wid = wid.reshape(-1); FW = wid[F]; nw = wid.max() + 1
W0 = np.zeros((nw, 3)); W0[wid] = V
c = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]]); A = np.linalg.norm(c, axis=1) / 2; N = c / np.maximum(2 * A[:, None], 1e-12)
wn = np.zeros((nw, 3)); np.add.at(wn, FW.ravel(), np.repeat(N * A[:, None], 3, 0)); wn /= np.maximum(np.linalg.norm(wn, axis=1, keepdims=True), 1e-12)
Ns = wn[FW].mean(1); Ns /= np.maximum(np.linalg.norm(Ns, axis=1, keepdims=True), 1e-12)
E = np.concatenate([FW[:, [0, 1]], FW[:, [1, 2]], FW[:, [2, 0]]]); E.sort(1); fid = np.tile(np.arange(nf), 3)
k2 = E[:, 0] * nw + E[:, 1]; order = np.argsort(k2); ks = k2[order]; fo = fid[order]; same = ks[1:] == ks[:-1]
pa, pb = fo[:-1][same], fo[1:][same]; ptr = np.zeros(nf + 1, np.int64); np.add.at(ptr, np.concatenate([pa, pb]) + 1, 1); ptr = np.cumsum(ptr)
nb = np.zeros(ptr[-1], np.int64); fill = ptr[:-1].copy()
for a, b in zip(pa, pb): nb[fill[a]] = b; fill[a] += 1; nb[fill[b]] = a; fill[b] += 1
C = W0[FW].mean(1); cosA = math.cos(ANG); tol = TOL * L; amin = AMIN * L * L
region = -np.ones(nf, np.int64); good = []; rid = 0
for s in np.argsort(-A):
    if region[s] != -1: continue
    n0 = Ns[s]; d0 = n0 @ C[s]; mem = [s]; region[s] = rid; q = collections.deque([s]); area = A[s]; nsum = Ns[s] * A[s]
    while q:
        f = q.popleft()
        for g in nb[ptr[f]:ptr[f + 1]]:
            if region[g] != -1 or Ns[g] @ n0 < cosA or abs(n0 @ C[g] - d0) > tol * 1.5: continue
            region[g] = rid; mem.append(g); q.append(g); area += A[g]; nsum += Ns[g] * A[g]
            if len(mem) % 200 == 0:
                m = np.array(mem); w = A[m]; cen = (C[m] * w[:, None]).sum(0) / w.sum(); n0 = nsum / np.linalg.norm(nsum); d0 = n0 @ cen
    m = np.array(mem)
    if area >= amin:
        w = A[m]; cen = (C[m] * w[:, None]).sum(0) / w.sum(); _, _, vt = np.linalg.svd((C[m] - cen) * np.sqrt(w)[:, None], full_matrices=False); n = vt[2]
        vi = np.unique(FW[m]); r = np.abs((W0[vi] - cen) @ n) / L
        if np.sqrt((r ** 2).mean()) > RMS_BAD or np.percentile(r, 95) > P95_BAD: good.append((rid, m, n, n @ cen))
    rid += 1
print('wavy plates', len(good), 'of', rid, 'regions', flush=True)
reg_of = region  # face -> region
inplate = np.zeros(nw, np.int64) - 1; disp = np.zeros((nw, 3)); moved = 0
for r_, m, n, d in good:
    vi = np.unique(FW[m]); inside = np.zeros(nw, bool); inside[vi] = True
    # border: plate vertices that also touch a face outside the plate
    other = np.unique(FW[reg_of != r_]); border = np.zeros(nw, bool); border[other] = True; border &= inside
    ring1 = np.zeros(nw, bool); fb = border[FW[m]].any(1); ring1[np.unique(FW[m][fb])] = True; ring1 &= inside & ~border
    wgt = np.where(border, 0., np.where(ring1, .5, 1.))[vi] * FLAT
    off = -((W0[vi] @ n) - d)[:, None] * n * wgt[:, None]
    disp[vi] += off; moved += int((wgt > 0).sum())
W1 = W0 + disp; V2 = W1[wid]; me.vertices.foreach_set('co', V2.ravel()); me.update()
print('moved', moved, 'vertices; max move %.4f L' % (np.linalg.norm(disp, axis=1).max() / L), flush=True)
bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB', use_selection=True, export_image_format='JPEG', export_jpeg_quality=95); print('wrote', dst)
