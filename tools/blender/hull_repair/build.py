"""Cumulative repair of today's unquantised C19 mesh, never a clean shell.

Blender frame is +X bow, +Y port, +Z up. Derived from the region-growth
method in hs/panel_flatten.py. Plate boundaries and small detail are held.
"""
import argparse
import collections
import json
import math
from pathlib import Path
import sys
import time

import bpy
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent/'surface_bakeoff'))
import round2_build as kit
lib = kit.lib
REPO = HERE.parents[2]
STAGES = ['S1', 'S2', 'S3', 'S4a', 'S4b', 'S5']


def ai_manifest(work):
    rows=json.loads((work/'ai/parts.json').read_text())
    packed=json.loads((work/'ai/packed.json').read_text())
    for name,row in rows.items():
        assert packed[name]['source_mesh']==row['mesh'],'Stale native AI pack: '+name
        row.update(packed[name])
    return rows


def regions(v, f):
    length = np.ptp(v[:, 0])
    cross = np.cross(v[f[:, 1]]-v[f[:, 0]], v[f[:, 2]]-v[f[:, 0]])
    area = np.linalg.norm(cross, axis=1)/2
    normal = cross/np.maximum(2*area[:, None], 1e-12)
    vn = np.zeros_like(v)
    np.add.at(vn, f.ravel(), np.repeat(normal*area[:, None], 3, axis=0))
    vn /= np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-12)
    smooth = vn[f].mean(1)
    smooth /= np.maximum(np.linalg.norm(smooth, axis=1, keepdims=True), 1e-12)
    edges = np.concatenate([f[:, [0, 1]], f[:, [1, 2]], f[:, [2, 0]]])
    edges.sort(1)
    order = np.argsort(edges[:, 0]*len(v)+edges[:, 1])
    keys = (edges[:, 0]*len(v)+edges[:, 1])[order]
    face_ids = np.tile(np.arange(len(f)), 3)[order]
    same = keys[1:] == keys[:-1]
    pairs = np.stack([face_ids[:-1][same], face_ids[1:][same]], 1)
    adj = [[] for _ in f]
    for a, b in pairs:
        adj[a].append(b); adj[b].append(a)
    centres = v[f].mean(1)
    labels = np.full(len(f), -1, np.int32)
    groups = []
    for seed in np.argsort(-area):
        if labels[seed] != -1:
            continue
        rid = len(groups)
        members = [seed]; labels[seed] = rid
        queue = collections.deque([seed]); n0 = smooth[seed]; d0 = n0@centres[seed]
        nsum = smooth[seed]*area[seed]
        while queue:
            face = queue.popleft()
            for other in adj[face]:
                if labels[other] != -1 or smooth[other]@n0 < math.cos(math.radians(14)):
                    continue
                if abs(n0@centres[other]-d0) > .009*length:
                    continue
                labels[other] = rid; members.append(other); queue.append(other)
                nsum += smooth[other]*area[other]
                if len(members) % 200 == 0:
                    m = np.array(members); w = area[m]
                    cen = (centres[m]*w[:, None]).sum(0)/w.sum()
                    n0 = nsum/max(np.linalg.norm(nsum), 1e-12); d0 = n0@cen
        groups.append(np.array(members))
    flat = v.copy(); accepted = []; big = np.zeros(len(groups), bool)
    for rid, m in enumerate(groups):
        if area[m].sum() < .0015*length*length:
            continue
        big[rid] = True
        if len(m) < 3:
            continue  # A two-triangle fitting has no unique centre-plane SVD.
        w = area[m]; cen = (centres[m]*w[:, None]).sum(0)/w.sum()
        _, _, vt = np.linalg.svd((centres[m]-cen)*np.sqrt(w[:, None]), full_matrices=False)
        n = vt[2]; ids = np.unique(f[m]); deviation = (v[ids]-cen)@n
        rms = float(np.sqrt(np.mean(deviation**2))/length)
        p95 = float(np.percentile(abs(deviation), 95)/length)
        if rms <= .0012 and p95 <= .0025:
            continue
        # UV duplicate vertices were welded by source(), so they move together.
        boundary = np.zeros(len(v), bool)
        boundary[np.unique(f[labels != rid])] = True
        ring = boundary.copy()
        weight = np.ones(len(v))
        weight[boundary] = 0
        for amount in [.33, .66]:
            expanded = ring.copy()
            expanded[np.unique(f[m][ring[f[m]].any(1)])] = True
            weight[expanded & ~ring] = amount
            ring = expanded
        delta = -deviation[:, None]*n*weight[ids, None]
        flat[ids] += delta
        after = (flat[ids]-cen)@n
        accepted.append(dict(region=rid, faces=len(m), area=float(w.sum()),
            rms_before=rms, p95_before=p95,
            rms_after=float(np.sqrt(np.mean(after**2))/length),
            interior_rms_after=float(np.sqrt(np.mean(after[weight[ids] == 1]**2))/length)
                if (weight[ids] == 1).any() else None,
            border_max_move=float(np.linalg.norm(delta[weight[ids] == 0], axis=1).max())
                if (weight[ids] == 0).any() else 0,
            moved=int((weight[ids] > 0).sum())))
    # Only large accepted regions become manufactured plates. Tiny machinery
    # stays in semantic remainder groups instead of receiving random colours.
    piece = np.zeros(len(f), np.int32)
    number = 1
    for rid, m in enumerate(groups):
        if big[rid]:
            piece[m] = number; number += 1
    print('[repair129] panels', len(accepted), 'large regions', number-1, flush=True)
    return flat, piece, accepted, vn


def segmented(v, f, piece, vn):
    # A narrow physical V groove follows manufactured region boundaries.
    count = np.zeros(len(v), np.int32)
    first = np.full(len(v), -1, np.int32)
    for j in range(3):
        ids = f[:, j]
        first[ids] = piece
    for j in range(3):
        np.add.at(count, f[:, j], first[f[:, j]] != piece)
    boundary = count > 0
    vertex_big = np.zeros(len(v), bool); vertex_big[np.unique(f[piece > 0])] = True
    boundary &= vertex_big
    result = v.copy(); result[boundary] -= vn[boundary]*.00045
    seam_faces = boundary[f].sum(1) >= 2
    return result, seam_faces, dict(groove_depth=.00045, groove_vertices=int(boundary.sum()),
        seam_faces=int(seam_faces.sum()), pieces=int(piece.max()),
        method='large near-flat regions grown across low curvature; retained small-detail remainder')


def seam_bands(v, f, piece):
    """Narrow dark groove floors and adjacent wear, rather than whole faces."""
    edges = np.concatenate([f[:, [0, 1]], f[:, [1, 2]], f[:, [2, 0]]])
    edges.sort(1)
    labels = np.tile(piece, 3)
    order = np.argsort(edges[:, 0]*len(v)+edges[:, 1])
    edges, labels = edges[order], labels[order]
    shared = (edges[1:] == edges[:-1]).all(1)
    selected = shared & (labels[1:] != labels[:-1]) & (np.maximum(labels[1:], labels[:-1]) > 0)
    edges = edges[:-1][selected]
    normals = np.zeros_like(v)
    cross = np.cross(v[f[:, 1]]-v[f[:, 0]], v[f[:, 2]]-v[f[:, 0]])
    for i in range(3):
        np.add.at(normals, f[:, i], cross)
    normals /= np.maximum(np.linalg.norm(normals, axis=1, keepdims=True), 1e-12)
    a, b = v[edges[:, 0]], v[edges[:, 1]]
    n = normals[edges].mean(1)
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    side = np.cross(n, b-a)
    side /= np.maximum(np.linalg.norm(side, axis=1, keepdims=True), 1e-12)
    vertices, faces, bands = [], [], []
    for left, right, band in [(-.00018, .00018, 5), (.00018, .00038, 4)]:
        q = np.stack([a+side*left, b+side*left, b+side*right, a+side*right], 1)
        q += n[:, None, :]*.000025
        offset = len(v)+sum(len(x) for x in vertices)
        idx = np.arange(len(edges))*4+offset
        faces.append(np.stack([idx, idx+1, idx+2], 1))
        faces.append(np.stack([idx, idx+2, idx+3], 1))
        vertices.append(q.reshape(-1, 3))
        bands.extend([np.full(len(edges), band, np.int32)]*2)
    return np.concatenate([v]+vertices), np.concatenate([f]+faces), np.concatenate(bands)


def finish_hull(v, f, piece, seam, stage, shared):
    varied = stage not in ['S1', 'S2']
    original_faces = len(f)
    extra_bands = np.empty(0, np.int32)
    if varied:
        v, f, extra_bands = seam_bands(v, f, piece)
        piece = np.concatenate([piece, np.zeros(len(extra_bands), np.int32)])
    obj = lib.mesh('retained_today_geometry', v, f)
    for variant, value in enumerate([1., .88, 1.08, .96, .31, 1.18]):
        mat = lib.material(shared, 'trim_')
        mat.name = 'trim_piece_'+str(variant)
        bs = mat.node_tree.nodes.get('Principled BSDF')
        # The exporter ignores a connected socket's default value. Its
        # recognised RGBA Multiply pattern exports an actual colour factor.
        nt = mat.node_tree
        source = bs.inputs['Base Color'].links[0].from_socket
        multiply = nt.nodes.new('ShaderNodeMix')
        multiply.data_type = 'RGBA'; multiply.blend_type = 'MULTIPLY'
        multiply.inputs[0].default_value = 1
        multiply.inputs[7].default_value = (value, value, value, 1)
        nt.links.new(source, multiply.inputs[6])
        nt.links.new(multiply.outputs[2], bs.inputs['Base Color'])
        group = bpy.data.node_groups.get('glTF Material Output')
        if group is None:
            group = bpy.data.node_groups.new('glTF Material Output', 'ShaderNodeTree')
            group.interface.new_socket(name='Occlusion', in_out='INPUT', socket_type='NodeSocketFloat')
        output = nt.nodes.new('ShaderNodeGroup'); output.node_tree = group
        separate = next(n for n in nt.nodes if n.type == 'SEPARATE_COLOR')
        nt.links.new(separate.outputs['Red'], output.inputs['Occlusion'])
        obj.data.materials.append(mat)
    me = obj.data
    coords = v[f]
    n = np.cross(coords[:, 1]-coords[:, 0], coords[:, 2]-coords[:, 0])
    axis = np.abs(n).argmax(1)
    # Red armour, soot recesses, selective bone salvage panels. Stable physical
    # coordinates preserve texture scale across triangle sizes and all stages.
    cen = coords.mean(1)
    band = np.where(cen[:, 2] < -.12, 3, 1)
    band[(np.abs(cen[:, 1]) > .19) & (cen[:, 2] > -.10)] = 2
    band[(axis == 2) & (cen[:, 2] > .13)] = 1
    if varied:
        band[original_faces:] = extra_bands
    uv = np.empty((len(f), 3, 2), np.float32)
    for a, axes in [(0, (1, 2)), (1, (0, 2)), (2, (0, 1))]:
        mask = axis == a
        # Wrap at each face centre. Wrapping each corner separately stretches
        # an entire trim tile across triangles that cross a repeat boundary.
        u = coords[mask, :, axes[0]]*2.4+.5
        t = coords[mask, :, axes[1]]*3+.5
        uv[mask, :, 0] = u-np.floor(u.mean(1, keepdims=True)/.96)*.96+.02
        uv[mask, :, 1] = (band[mask, None]+.25+
            t-np.floor(t.mean(1, keepdims=True)/.48)*.48)/8
    layer = me.uv_layers.new(name='shared_trim')
    layer.data.foreach_set('uv', uv.ravel())
    values = np.mod(piece*17, 4) if varied else np.zeros(len(f), np.int32)
    if varied:
        values[original_faces:] = np.where(extra_bands == 5, 4, 0)
    me.polygons.foreach_set('material_index', values)
    me.polygons.foreach_set('use_smooth', np.ones(len(f), bool))
    me.set_sharp_from_angle(angle=math.radians(38 if varied else 180))
    if varied:
        # Split loops at the same explicit part boundaries as the grooves.
        bm = bmesh.new(); bm.from_mesh(me)
        bm.faces.ensure_lookup_table()
        split = [e for e in bm.edges if len(e.link_faces) == 2 and
                 piece[e.link_faces[0].index] != piece[e.link_faces[1].index] and
                 max(piece[e.link_faces[0].index], piece[e.link_faces[1].index]) > 0]
        for edge in split:
            edge.smooth = False
        bmesh.ops.split_edges(bm, edges=split)
        bm.to_mesh(me); bm.free(); me.update()
    return obj


def mask_parts(v, f):
    c = v[f].mean(1); x, y, z = c.T
    masks = {
        'engine': (x < -.432) & (abs(y) < .081) & (z > -.137) & (z < .012),
        'bridge': (x > -.30) & (x < -.085) & (abs(y) < .055) & (z > .126),
        'gun': (x > .045) & (x < .17) & (abs(y) > .216) & (z > -.095) & (z < .015),
    }
    return masks


def mount(core, name, guess, size, sign=1, axis=2):
    tree = BVHTree.FromObject(core, bpy.context.evaluated_depsgraph_get())
    start = Vector(guess); start[axis] = sign*1.2
    direction = Vector((0, 0, 0)); direction[axis] = -sign
    p, n, _, _ = tree.ray_cast(start, direction, 3)
    if p is None:
        p, n, _, _ = tree.find_nearest(Vector(guess))
    assert p is not None, 'No hull surface for '+name
    n = n.normalized()
    kit.TREE = tree; kit.CORE = core
    obj, tangent, bitangent = kit.mounted(name+'_mount', p, n, size, 3)
    return p, n


def hand_parts(core, wanted):
    parts = {}
    timings = {}
    if 'bridge' in wanted:
        started = time.perf_counter()
        start = len(kit.PARTS)
        p, n = mount(core, 'bridge', (-.19, 0, .12), (.145, .085, .009))
        for k, (length, width) in enumerate([(.13, .076), (.105, .063), (.078, .051)]):
            at = p+Vector((.008*k, 0, .009+.013*k))
            kit.box('bridge_armour_tier', at, (length, width, .020), 1, .0012)
            kit.box('bridge_shadow_seam', at+Vector((0, 0, .009)),
                    (length*.97, width*.97, .002), 5, .0003)
            for side in [-1, 1]:
                for x in np.linspace(-length*.36, length*.36, 6):
                    kit.box('bridge_window', at+Vector((x, side*(width/2+.0002), .003)),
                            (.006, .001, .003), 7, .0002)
        for y in [-.020, .020]:
            c = p+Vector((-.008, y, .052))
            kit.cyl('sensor_root', c, .004, .012, band=3)
            kit.cyl('antenna', c+Vector((0, 0, .015)), .0016, .022, band=4, sides=8)
            kit.box('sensor_array', c+Vector((.004, 0, .024)), (.013, .005, .008), 3)
        parts['bridge'] = kit.PARTS[start:]
        timings['bridge'] = dict(construction_seconds=time.perf_counter()-started,cleanup_seconds=0.0)
    if 'engine' in wanted:
        started = time.perf_counter()
        start = len(kit.PARTS)
        p, n = mount(core, 'engine', (-.43, 0, -.064), (.115, .10, .012), -1, 0)
        kit.box('engine_armoured_block', p+Vector((-.015, 0, 0)), (.035, .12, .093), 3, .002)
        for y in [-.032, .032]:
            centre = p+Vector((-.037, y, .006))
            kit.cyl('engine_bell', centre, .024, .034, (-1, 0, 0), 4, 24)
            kit.cyl('engine_recess', centre+Vector((-.0175, 0, 0)), .019, .001, (-1, 0, 0), 5, 24)
            kit.cyl('engine_throat', centre+Vector((-.0182, 0, 0)), .009, .001, (-1, 0, 0), 7, 24)
            for a in np.linspace(0, math.tau, 10, endpoint=False):
                c = centre+Vector((0, .024*math.cos(a), .024*math.sin(a)))
                kit.link('engine_rib', c+Vector((-.013, 0, 0)), c+Vector((.018, 0, 0)), .0014, 3)
        for y in [-.054, .054]:
            for z in [-.025, -.014, -.003, .008, .019]:
                kit.box('engine_cooling_fin', p+Vector((-.017, y, z)), (.028, .007, .003), 4, .0004)
        parts['engine'] = kit.PARTS[start:]
        timings['engine'] = dict(construction_seconds=time.perf_counter()-started,cleanup_seconds=0.0)
    if 'gun' in wanted:
        started = time.perf_counter()
        start = len(kit.PARTS)
        for side in [-1, 1]:
            p, n = mount(core, 'gun', (.10, side*.225, -.045), (.063, .049, .009), side, 1)
            c = p+Vector((0, side*.006, 0))
            kit.cyl('gun_trunnion', c, .023, .025, (0, side, 0), 3, 20)
            d = Vector((.45, side*.89, .025)).normalized()
            for z in [-.007, .007]:
                a = c+Vector((.003, side*.003, z))
                kit.cyl('gun_barrel', a+d*.013, .0044, .030, d, 4, 20)
                kit.cyl('gun_sleeve', a+d*.010, .0062, .019, d, 3, 20)
                kit.cyl('gun_muzzle', a+d*.030, .0065, .009, d, 4, 20)
                kit.cyl('gun_bore', a+d*.035, .0043, .0007, d, 5, 20)
                kit.GUNS.append(list(d))
        parts['gun'] = kit.PARTS[start:]
        timings['gun'] = dict(construction_seconds=time.perf_counter()-started,cleanup_seconds=0.0)
    # Every hero gets physical access panels, seams, unions and fasteners at
    # the same scale as the retained fine machinery, not broad plain boxes.
    for name, group in parts.items():
        started = time.perf_counter()
        for obj in list(group):
            if 'armour' not in obj.name and 'block' not in obj.name:
                continue
            b = obj.location; size = obj.dimensions
            for s in [-1, 1]:
                for t in [-1, 1]:
                    kit.cyl('hero_fastener', b+Vector((s*size.x*.34, t*size.y*.34, size.z*.51)),
                            .0012, .0015, band=4, sides=8)
        timings[name]['detail_seconds'] = time.perf_counter()-started
    return timings


def ai_part(core, name, row):
    # Native meshes are assembled in Godot. Loading three 20M-face parts into
    # BMesh together would exceed this PC's RAM. The array packer preserves
    # their topology, adds normals/trim UVs and records the actual cleanup time.
    instances = []
    if name == 'engine':
        p, n = mount(core, 'AI_engine', (-.43, 0, -.064), (.12, .105, .01), -1, 0)
        instances.append(dict(path=row['packed_mesh'], position=[p.x-.025, p.z, -p.y], yaw=math.pi))
    elif name == 'bridge':
        p, n = mount(core, 'AI_bridge', (-.19, 0, .12), (.153, .083, .01))
        instances.append(dict(path=row['packed_mesh'],
            position=[p.x, p.z+row['fitted_godot_dimensions'][1]/2+.004, -p.y], yaw=0))
    elif name == 'gun':
        for side in [-1, 1]:
            p, n = mount(core, 'AI_gun', (.10, side*.225, -.045), (.065, .050, .01), side, 1)
            # Put the generated pedestal's bottom on the visible side flange.
            # Its native +Y becomes the outward mount normal; +X remains
            # forward. A yaw-only fit left the pedestal hanging below it.
            offset=row['fitted_godot_dimensions'][1]/2+.0095
            instances.append(dict(path=row['packed_mesh'], position=[p.x+.005,p.z,-p.y-side*offset],
                                  yaw=0,pitch=-side*math.pi/2))
            kit.GUNS.append([1,0,0])
    return dict(part=name, triangles=row['triangles'], raw_faces=row['raw_triangles'],
                cleanup_seconds=row['cleanup_seconds'], source=row['mesh'],
                source_dimensions=row['source_dimensions'],
                fitted_godot_dimensions=row['fitted_godot_dimensions'], instances=instances,
                intended_gun_axes_only=name=='gun')


def midships_trial(work, data, shared):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    v, f, piece, seam = data['separate'], data['f'], data['piece'], data['seam']
    c = v[f].mean(1)
    cut = (c[:, 0] > .18) & (c[:, 0] < .30) & (abs(c[:, 1]) < .105)
    core = finish_hull(v, f[~cut], piece[~cut], seam[~cut], 'S3', shared)
    row = ai_manifest(work)['midships']
    folder = work/'C19_51'/'Midships'; folder.mkdir(exist_ok=True)
    meta = lib.export([core], folder, 'Midships')
    meta['native_instances'] = [dict(path=row['packed_mesh'],position=[.24,-.025,0],yaw=0)]
    meta['hull_triangles'] = meta['triangles']
    meta['triangles'] += row['triangles']
    meta.update(join_cut_planes=[.18,.30],section_dimensions=row['fitted_godot_dimensions'],
                watertight=False, verdict='separate end contours; inspect both joins; not welded')
    (folder/'build.json').write_text(json.dumps(meta,indent=2)+'\n')
    (work/'midships.json').write_text(json.dumps(meta,indent=2)+'\n')


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--pc', type=Path, required=True)
    ap.add_argument('--work', type=Path, required=True)
    ap.add_argument('--stage', choices=STAGES+['trim', 'analyse'], required=True)
    args = ap.parse_args(sys.argv[sys.argv.index('--')+1:])
    start = time.perf_counter(); work = args.work; shared = work/'shared'
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if args.stage == 'trim':
        kit.trim(shared)
        assert lib.sha(shared/'trim_base.png') == lib.sha(REPO/'docs/shots/ship_pipeline/issue75b/Hullbreaker_trim.png')
        return
    source = args.pc/'a4/out/C19_51/C19_51_ship.npz'
    cache = work/'analysis.npz'
    analysis_path = work/'analysis.json'
    cached = json.loads(analysis_path.read_text()) if analysis_path.exists() else {}
    if not cache.exists() or cached.get('analysis_version') != 2:
        high, _, v, f = kit.source(args.pc)
        bpy.data.objects.remove(high, do_unlink=True)
        cross = np.cross(v[f[:, 1]]-v[f[:, 0]], v[f[:, 2]]-v[f[:, 0]])
        valid = np.linalg.norm(cross, axis=1) >= 1e-12
        collapsed = int((~valid).sum()); f = f[valid]
        flat, piece, accepted, vn = regions(v, f)
        separate, seam, separation = segmented(flat, f, piece, vn)
        np.savez_compressed(cache, v=v, f=f, flat=flat, separate=separate, piece=piece, seam=seam)
        (work/'analysis.json').write_text(json.dumps(dict(analysis_version=2,
            source=str(source), source_sha256=lib.sha(source), zero_area_faces_removed=collapsed,
            source_triangles=len(f), source_bounds=[v.min(0).tolist(), v.max(0).tolist()],
            thresholds=dict(angle_degrees=14, distance_fraction=.009, min_area_fraction=.0015,
                            rms_fraction=.0012, p95_fraction=.0025),
            flatten=accepted, separation=separation), indent=2)+'\n')
    if args.stage == 'analyse':
        return
    data = np.load(cache); v = data['v']; f = data['f']; stage = args.stage
    pos = data['v'] if stage == 'S1' else (data['flat'] if stage == 'S2' else data['separate'])
    piece, seam = data['piece'], data['seam']
    cuts = {}; ai_records = []; hand_timings = {}
    if stage in ['S4a', 'S4b', 'S5']:
        cuts = mask_parts(pos, f)
        keep = ~np.logical_or.reduce(list(cuts.values()))
    else:
        keep = np.ones(len(f), bool)
    core = finish_hull(pos, f[keep], piece[keep], seam[keep], stage, shared)
    kit.PARTS.clear(); kit.CONTACTS.clear(); kit.GUNS.clear()
    kit.MAT = lib.material(shared, 'trim_'); kit.MAT.name = 'Hullbreaker_shared_trim'
    if stage in ['S4a', 'S4b', 'S5']:
        # Seal the removed upper tier with a structural plinth. Close both
        # gun cuts with visible armour bulkheads before raycasting the mounts;
        # an open cut can otherwise let a port ray hit the starboard hull.
        kit.box('bridge_structural_plinth', (-.1925, 0, .123), (.224, .116, .014), 1, .0015)
        for side in [-1, 1]:
            kit.box('gun_cut_bulkhead', (.1075, side*.208, -.040), (.136, .016, .120), 3, .001)
            for x in [.061,.154]:
                kit.box('bulkhead_access_panel', (x,side*.2165,-.071), (.024,.003,.018), 1,.0006)
                for z in [-.079,-.063]:
                    kit.cyl('bulkhead_fastener', (x,side*.219,z),.0012,.0012,(0,side,0),4,8)
        core = kit.join([core]+kit.PARTS[:], 'retained_hull_with_cut_closures')
        kit.PARTS.clear()
    kit.CORE = core; kit.TREE = kit.tree(core)
    choices = dict(engine='hand', gun='hand', bridge='hand')
    choice_file = work/'choices.json'
    if stage == 'S5' and choice_file.exists():
        choices.update(json.loads(choice_file.read_text()))
    if stage == 'S4b':
        choices = {name: 'ai' for name in choices}
    if stage in ['S4a', 'S4b', 'S5']:
        hand_timings = hand_parts(core, [k for k, method in choices.items() if method == 'hand'])
        if 'ai' in choices.values():
            manifest = ai_manifest(work)
            for name, method in choices.items():
                if method == 'ai':
                    ai_records.append(ai_part(core, name, manifest[name]))
    objects = [core]
    if kit.PARTS:
        hardware = kit.join(kit.PARTS[:], 'mounted_replacement_parts')
        if stage == 'S5':
            kit.weighted(hardware)
        objects.append(hardware)
    # Keep the whole experiment within today's hull+kit bounds. No automatic
    # rescaling to hide an oversized bolt-on. Record all constrained vertices.
    lo, hi = v.min(0), v.max(0); clipped = 0
    for obj in objects[1:]:
        for vert in obj.data.vertices:
            p = obj.matrix_world@vert.co
            clamped = Vector(np.clip(np.array(p), lo, hi))
            if (clamped-p).length > 1e-7:
                clipped += 1; vert.co = obj.matrix_world.inverted()@clamped
    if stage == 'S5':
        # Angle limits preserve small rounded machinery, while the already
        # split manufactured creases keep their hard shading breaks.
        kit.weighted(core)
    folder = work/'C19_51'/stage; folder.mkdir(parents=True, exist_ok=True)
    meta = lib.export(objects, folder, stage)
    meta['hull_triangles'] = meta['triangles']
    meta['native_instances'] = [i for part in ai_records for i in part['instances']]
    meta['triangles'] += sum(part['triangles']*len(part['instances']) for part in ai_records)
    meta.update(stage=stage, source=str(source), source_sha256=lib.sha(source),
        seconds=time.perf_counter()-start, no_decimation=True,
        removed_faces={k: int(m.sum()) for k, m in cuts.items()},
        choices=choices if stage in ['S4a', 'S4b', 'S5'] else {},
        ai_parts=ai_records, hand_timings=hand_timings,
        mount_anchors=kit.CONTACTS, gun_directions=kit.GUNS,
        constrained_replacement_vertices=clipped,
        retained_geometry='today A4 unquantised intact mesh; no clean shell or concept paint',
        shared_trim_sha256={p.name: lib.sha(p) for p in shared.glob('*.png')})
    assert all(d[0] >= 0 for d in kit.GUNS)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'prototype.blend'))
    (folder/'build.json').write_text(json.dumps(meta, indent=2)+'\n')
    print('[repair129] BUILD PASS', stage, meta['triangles'], flush=True)
    if stage == 'S4b':
        midships_trial(work, data, shared)


if __name__ == '__main__':
    main()
