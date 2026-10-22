# Bake-off entry E: keep every Hunyuan detail, but find the big near-flat plates (hull sides, deck, tower faces), fit a true plane to each
# and snap the lumpy vertices onto it; vertices between two plates snap to their crease line. Small parts (pipes, tanks, greebles) are left alone.
# usage: python3 planesnap.py in.glb out.blend [angle_deg=14] [tol=0.006] [min_area=0.0015]
import sys, math, collections, numpy as np, bpy
src, out = sys.argv[1], sys.argv[2]; ANG = math.radians(float(sys.argv[3]) if len(sys.argv) > 3 else 14)
TOL = float(sys.argv[4]) if len(sys.argv) > 4 else .006; AMIN = float(sys.argv[5]) if len(sys.argv) > 5 else .0015
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
ms = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in bpy.context.scene.objects: o.select_set(o.type == 'MESH')
bpy.context.view_layer.objects.active = ms[0]
if len(ms) > 1: bpy.ops.object.join()
o = bpy.context.view_layer.objects.active; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.mesh.remove_doubles(threshold=1e-5); bpy.ops.mesh.quads_convert_to_tris(); bpy.ops.object.mode_set(mode='OBJECT')
me = o.data; V = np.array([v.co[:] for v in me.vertices]); F = np.array([p.vertices[:] for p in me.polygons])
nv, nf = len(V), len(F); print('verts', nv, 'faces', nf, flush=True)
def fnorm(V):
    c = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]]); a = np.linalg.norm(c, axis=1); return c / np.maximum(a[:, None], 1e-12), a / 2
N, A = fnorm(V)
# smoothed face normals (two rings) so voxel ripple does not break a plate into fragments
vn = np.zeros((nv, 3)); np.add.at(vn, F.ravel(), np.repeat(N * A[:, None], 3, 0)); vn /= np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-12)
Ns = vn[F].mean(1); Ns /= np.maximum(np.linalg.norm(Ns, axis=1, keepdims=True), 1e-12)
# face adjacency through shared edges
E = np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]]); E.sort(1); fid = np.tile(np.arange(nf), 3)
key = E[:, 0].astype(np.int64) * nv + E[:, 1]; order = np.argsort(key); ks = key[order]; fo = fid[order]
same = ks[1:] == ks[:-1]; pairs = np.stack([fo[:-1][same], fo[1:][same]], 1)
adj = [[] for _ in range(nf)]
for a, b in pairs: adj[a].append(b); adj[b].append(a)
C = V[F].mean(1); cosA = math.cos(ANG)
region = -np.ones(nf, np.int64); planes = []; seeds = np.argsort(-A)
for s in seeds:
    if region[s] != -1: continue  # visited (accepted >= 0, rejected <= -2): the old >= 0 test re-grew rejected regions (Codex audit)
    n0 = Ns[s]; d0 = n0 @ C[s]; rid = len(planes); members = [s]; region[s] = rid; q = collections.deque([s]); area = A[s]; nsum = Ns[s] * A[s]
    while q:
        f = q.popleft()
        for g in adj[f]:
            if region[g] != -1: continue
            if Ns[g] @ n0 < cosA or abs(n0 @ C[g] - d0) > TOL * 1.5: continue
            region[g] = rid; members.append(g); q.append(g); area += A[g]; nsum += Ns[g] * A[g]
            if len(members) % 200 == 0:  # refit the plane as the region grows
                m = np.array(members); w = A[m]; cen = (C[m] * w[:, None]).sum(0) / w.sum(); n0 = nsum / np.linalg.norm(nsum); d0 = n0 @ cen
    if area < AMIN:
        region[np.array(members)] = -2 - rid; planes.append(None); continue  # too small: a detail, leave it
    m = np.array(members); w = A[m]; cen = (C[m] * w[:, None]).sum(0) / w.sum(); X = C[m] - cen
    _, _, vt = np.linalg.svd(X * np.sqrt(w)[:, None], full_matrices=False); n = vt[2]; n = n if n @ (nsum) > 0 else -n
    planes.append((n, n @ cen))
big = [i for i, p in enumerate(planes) if p is not None]; print('plates', len(big), 'of', len(planes), 'regions', flush=True)
# each vertex: the plates its faces belong to (and their neighbours' plates within the tolerance)
vp = [set() for _ in range(nv)]
for f in range(nf):
    r = region[f]
    if r >= 0:
        for v in F[f]: vp[v].add(r)
ring = [set() for _ in range(nv)]
for a, b, c in F: ring[a].update((b, c)); ring[b].update((a, c)); ring[c].update((a, b))
W = V.copy(); snapped = 0; crease = 0
for v in range(nv):
    cand = set(vp[v])
    for u in ring[v]: cand |= vp[u]
    cand = [r for r in cand if abs(planes[r][0] @ V[v] - planes[r][1]) < TOL]
    if not cand: continue
    cand.sort(key=lambda r: abs(planes[r][0] @ V[v] - planes[r][1])); cand = cand[:2]
    if len(cand) == 2 and abs(planes[cand[0]][0] @ planes[cand[1]][0]) > .9: cand = cand[:1]  # nearly parallel plates: no crease, just the nearer
    p = V[v].copy()
    for _ in range(6):  # alternating projections onto one plate, or onto the crease line of two
        for r in cand: n, d = planes[r]; p = p - (n @ p - d) * n
    if np.linalg.norm(p - V[v]) < TOL * 1.6: W[v] = p; snapped += 1; crease += len(cand) == 2
print('snapped', snapped, 'crease', crease, flush=True)
for i, v in enumerate(me.vertices): v.co = W[i]
me.update()
bpy.ops.object.shade_auto_smooth(angle=math.radians(40))
wn = o.modifiers.new('wn', 'WEIGHTED_NORMAL'); wn.keep_sharp = True; wn.weight = 100; bpy.ops.object.modifier_apply(modifier='wn')
bpy.ops.wm.save_as_mainfile(filepath=out)
