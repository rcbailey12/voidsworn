# A4 composite hulls (Oct 27, Ryan on the Pyre-Barge: "very different from the other hullbreaker ships, not in a good way. I like the
# design of the others more"). A war-barge built the Corsair way: captured hulls of its own line welded together, lopsided. Each part is
# an AI hull from hulls_hi with its own ship-file cuts applied in its own frame, then scaled, turned and placed; the parts' AI maps
# (AO and curvature, normal) are tiled into one 2x2 atlas so the bake reads every part's own surface detail.
# Works on the raw arrays (Blender working frame: x bow, y port, z up); the maps are tiled with Blender's image API (bpy).
import os
import numpy as np
import frame, cuts

TILE = 2048


def load(root, cfg, tmpdir, ships_mod):
    """cfg['compose'] = [dict(code, scale, at=(x, y, z), yaw_extra=0, cuts=True)]. Returns the dict frame.load gives (pos, nor, idx, uv2,
    tex, flipped) for the welded whole, plus parts=[(code, first_vertex, n_vertices)]"""
    os.makedirs(tmpdir, exist_ok=True)
    tiles = {'n': np.zeros((TILE * 2, TILE * 2, 4), np.float32), 'm': np.zeros((TILE * 2, TILE * 2, 4), np.float32)}
    tiles['n'][...] = (.5, .5, 1., 1.); tiles['m'][...] = (.78, .5, 0., 1.)
    P, N, I, U, parts, boxes = [], [], [], [], [], []; off = 0
    for k, part in enumerate(cfg['compose']):
        code = part['code']; pc = ships_mod.SHIPS.get(code, {})
        h = frame.load(root, code, pc.get('yaw', ships_mod.YAWS.get(code, 0)) + part.get('yaw_extra', 0))
        idx = h['idx']
        own = (pc.get('cuts', []) if part.get('cuts', True) else []) + list(part.get('cuts_extra', []))  # extra: in the part's own frame
        idx, _, _ = cuts.apply(h['pos'], idx, own)  # its own cuts, and its loose AI debris
        s = float(part.get('scale', 1.0)); at = np.array(part.get('at', (0, 0, 0)), float)
        for c in own:  # the holes those cuts leave get filled like the barge's own (a4_ship.fill_holes reads these boxes)
            if 'box' in c and 'dir' not in c and c.get('cover', True) is not False:
                bx = [c['box']] + ([(c['box'][0], c['box'][1], -c['box'][3], -c['box'][2], c['box'][4], c['box'][5])] if c.get('mirror') else [])
                for x0, x1, y0, y1, z0, z1 in bx: boxes.append((x0 * s + at[0], x1 * s + at[0], y0 * s + at[1], y1 * s + at[1], z0 * s + at[2], z1 * s + at[2]))
        pos = h['pos'] * s + at
        used = np.unique(idx.ravel()); remap = -np.ones(len(pos), np.int64); remap[used] = np.arange(len(used))
        col, row = k % 2, k // 2
        uv = h['uv2'][used].copy(); uv[:, 0] = (uv[:, 0] + col) / 2; uv[:, 1] = (uv[:, 1] + row) / 2
        P.append(pos[used]); N.append(h['nor'][used]); U.append(uv); I.append(remap[idx] + off)
        parts.append((code, off, len(used))); off += len(used)
        for key, path in (('n', h['tex'][0]), ('m', h['tex'][1])):  # rows of the array run bottom-up (Blender pixel order)
            px = _read(path); r0 = (1 - row) * TILE; tiles[key][r0:r0 + TILE, col * TILE:(col + 1) * TILE] = px
    pn = os.path.join(tmpdir, 'compose_n.png'); pm = os.path.join(tmpdir, 'compose_m.png'); _write(tiles['n'], pn); _write(tiles['m'], pm)
    pos = np.concatenate(P).astype(np.float32); idx = np.concatenate(I)
    if cfg.get('hide_inside', True): idx = drop_hidden(pos, idx, parts)
    return dict(pos=pos, nor=np.concatenate(N).astype(np.float32), idx=idx, uv2=np.concatenate(U).astype(np.float32), tex=(pn, pm),
                flipped=False, parts=parts, cut_boxes=boxes)


def _read(path):
    """an image as float RGBA, TILE x TILE, rows bottom-up (Blender's image API: Blender's own Python has no PIL; the bpy module in the
    cloud works the same way)"""
    import bpy
    im = bpy.data.images.load(path, check_existing=False); im.colorspace_settings.name = 'Non-Color'
    if tuple(im.size) != (TILE, TILE): im.scale(TILE, TILE)
    px = np.empty(TILE * TILE * 4, np.float32); im.pixels.foreach_get(px); bpy.data.images.remove(im)
    return px.reshape(TILE, TILE, 4)


def _write(arr, path):
    import bpy
    H, W = arr.shape[:2]; im = bpy.data.images.new(os.path.basename(path), W, H, alpha=False, float_buffer=False)
    im.colorspace_settings.name = 'Non-Color'; im.pixels.foreach_set(arr.ravel()); im.filepath_raw = path; im.file_format = 'PNG'; im.save()
    bpy.data.images.remove(im)


def drop_hidden(pos, idx, parts, dirs=((0, 0, 1), (0, 0, -1), (0, 1, 0), (0, -1, 0), (1, 0, 0))):
    """Oct 27 (Opus: the barge at 475k triangles is too heavy): each part's triangles buried inside another part are dropped. Inside is
    a majority vote of ray parity in five directions against the other parts (the AI meshes are open in places, so one ray can lie)."""
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    owner = np.zeros(len(pos), np.int64)
    for k, (_, o, n) in enumerate(parts): owner[o:o + n] = k
    tri_owner = owner[idx[:, 0]]; keep = np.ones(len(idx), bool); dropped = 0
    for k in range(len(parts)):
        mine = np.nonzero(tri_owner == k)[0]; others = idx[tri_owner != k]
        if not len(mine) or not len(others): continue
        T = BVHTree.FromPolygons([tuple(map(float, v)) for v in pos], [tuple(map(int, t)) for t in others])
        C = pos[idx[mine]].mean(1)
        lo = pos[others.ravel()].min(0) - .01; hi = pos[others.ravel()].max(0) + .01
        cand = np.nonzero(np.all((C > lo) & (C < hi), 1))[0]  # only centroids inside the other parts' box can be buried
        for j in cand:
            c = Vector(C[j].tolist()); votes = 0
            for d in dirs:
                dv = Vector(d); o_ = c.copy(); hits = 0
                for _ in range(24):
                    h = T.ray_cast(o_, dv, 2.0)
                    if h[0] is None: break
                    hits += 1; o_ = h[0] + dv * 1e-5
                votes += hits % 2
            if votes >= 3: keep[mine[j]] = False; dropped += 1
    print(f'[compose] dropped {dropped} buried triangles of {len(idx)}', flush=True)
    return idx[keep]
