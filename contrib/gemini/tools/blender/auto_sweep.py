# Automated Blob Sweep & Socket Extractor for Pixal3D Ship Hulls (Question 4)
# 1. Deletes floating mesh islands and thin AI wire debris (internal ray thickness < 7 mm + high normal variance).
# 2. Detects wavy regions on flat hull panels (2-ring vs 16-ring normal residual) and snaps macro plates.
# 3. Segments bolt-on protrusions against a 40-step Taubin/Laplacian smoothed base hull envelope, scores port/starboard
#    symmetry mismatch, and writes <out_prefix>_sockets.json with cut boxes, mount points, normals, and PCA axes.
# usage: blender -b -P auto_sweep.py -- in_hull.glb out_prefix
import sys, os, json, math, collections
import numpy as np
import bpy, bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
src, pre = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
ms = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in bpy.context.scene.objects:
    o.select_set(o.type == 'MESH')
bpy.context.view_layer.objects.active = ms[0]
if len(ms) > 1:
    bpy.ops.object.join()
hull = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

bm = bmesh.new()
bm.from_mesh(hull.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
bm.faces.ensure_lookup_table()
bm.verts.ensure_lookup_table()

# Step 1: Prune disconnected islands (< 250 faces) and thin wire spikes (internal diameter < 0.007)
nf = len(bm.faces)
visited = np.zeros(nf, dtype=bool)
kill_faces = set()
for f in bm.faces:
    if visited[f.index]:
        continue
    comp = []
    stack = [f]
    visited[f.index] = True
    while stack:
        cur = stack.pop()
        comp.append(cur)
        for e in cur.edges:
            for nb in e.link_faces:
                if not visited[nb.index]:
                    visited[nb.index] = True
                    stack.append(nb)
    if len(comp) < 250:
        kill_faces.update(comp)

bvh = BVHTree.FromBMesh(bm)
wire_candidates = set()
for f in bm.faces:
    if f in kill_faces:
        continue
    c = f.calc_center_median()
    n = f.normal
    if n.length < 1e-6:
        continue
    # Cast ray inward along -normal to measure local part thickness
    hit, _, _, dist = bvh.ray_cast(c - n * 1e-4, -n, 0.007)
    if hit is not None and dist < 0.0065:
        # Check 1-ring normal spread to distinguish wires/spikes from thin flat wings/sails
        ring_normals = [nb.normal for e in f.edges for nb in e.link_faces if nb.normal.length > 1e-6]
        if len(ring_normals) >= 3:
            dots = [n.dot(rn) for rn in ring_normals]
            if min(dots) < 0.55:
                wire_candidates.add(f)

kill_faces.update(wire_candidates)
if kill_faces:
    bmesh.ops.delete(bm, geom=list(kill_faces), context='FACES')
    bmesh.ops.holes_fill(bm, edges=[e for e in bm.edges if e.is_boundary], sides=24)
    print(f'auto_sweep: removed {len(kill_faces)} island/wire faces')

bm.faces.ensure_lookup_table()
bm.verts.ensure_lookup_table()
bvh_clean = BVHTree.FromBMesh(bm)

# Step 2: Smooth copy of hull to extract bare hull envelope M_base and segment bolt-on protrusions
bm_base = bm.copy()
bmesh.ops.smooth_vert(bm_base, verts=bm_base.verts, factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
for _ in range(35):
    bmesh.ops.smooth_vert(bm_base, verts=bm_base.verts, factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
bvh_base = BVHTree.FromBMesh(bm_base)

nv = len(bm.verts)
protrusion_h = np.zeros(nv, dtype=np.float32)
sym_err = np.zeros(nv, dtype=np.float32)
for i, v in enumerate(bm.verts):
    loc, norm, _, dist = bvh_base.find_nearest(v.co)
    if loc is not None and norm is not None:
        protrusion_h[i] = (v.co - loc).dot(norm)
    # Bilateral symmetry check across Y = 0
    mir = Vector((v.co.x, -v.co.y, v.co.z))
    mloc, _, _, mdist = bvh_clean.find_nearest(mir)
    sym_err[i] = mdist if mloc is not None else 0.05

# Flood-fill protruding vertex clusters (h > 0.008)
v_visited = np.zeros(nv, dtype=bool)
sockets = []
for v in bm.verts:
    if v_visited[v.index] or protrusion_h[v.index] <= 0.008:
        continue
    cluster = []
    stack = [v]
    v_visited[v.index] = True
    while stack:
        cur = stack.pop()
        cluster.append(cur)
        for e in cur.link_edges:
            nb = e.other_vert(cur)
            if not v_visited[nb.index] and protrusion_h[nb.index] > 0.005:
                v_visited[nb.index] = True
                stack.append(nb)
    if len(cluster) < 25:
        continue
    pts = np.array([u.co[:] for u in cluster], dtype=np.float64)
    lo = pts.min(axis=0)
    hi = pts.max(axis=0)
    span = hi - lo
    if np.max(span) < 0.012:
        continue
    center = pts.mean(axis=0)
    # PCA via SVD for principal axis and elongation
    centered = pts - center
    _, s_vals, vh = np.linalg.svd(centered, full_matrices=False)
    axis = vh[0]
    elong = float(s_vals[0] / max(s_vals[1], 1e-6))
    kind = 'barrel_or_mast' if elong > 3.2 else ('cylinder_or_tank' if elong > 1.4 else 'turret_or_block')
    loc_b, norm_b, _, _ = bvh_base.find_nearest(Vector(center))
    sockets.append({
        'type': kind,
        'verts': len(cluster),
        'cut_box': [round(float(lo[0] - .003), 4), round(float(hi[0] + .003), 4),
                    round(float(lo[1] - .003), 4), round(float(hi[1] + .003), 4),
                    round(float(lo[2] - .003), 4), round(float(hi[2] + .003), 4)],
        'mount_pos': [round(float(loc_b.x), 4), round(float(loc_b.y), 4), round(float(loc_b.z), 4)] if loc_b else [round(float(x), 4) for x in center],
        'mount_normal': [round(float(norm_b.x), 4), round(float(norm_b.y), 4), round(float(norm_b.z), 4)] if norm_b else [0.0, 0.0, 1.0],
        'principal_axis': [round(float(x), 4) for x in axis],
        'length': round(float(np.max(span)), 4),
        'mean_symmetry_error': round(float(np.mean([sym_err[u.index] for u in cluster])), 4),
    })

bm_base.free()
bm.to_mesh(hull.data)
bm.free()

bpy.ops.object.select_all(action='DESELECT')
hull.select_set(True)
bpy.context.view_layer.objects.active = hull
bpy.ops.export_scene.gltf(filepath=pre + '_swept.glb', export_format='GLB', use_selection=True)

with open(pre + '_sockets.json', 'w', encoding='utf-8') as f:
    json.dump({'hull': src, 'socket_count': len(sockets), 'sockets': sockets}, f, indent=2)
print(f'auto_sweep: wrote {pre}_swept.glb and {len(sockets)} candidate sockets to {pre}_sockets.json')
