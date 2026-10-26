# A4 Ithar: hand-lofted spindle hulls for the ships the AI could not mesh (I8_37: the generator made one curved sheet with a stub of body,
# FINDINGS R28 "Ithar broken in both (asset)"). Blender working frame (x bow, y port, z up), ship length 1 along x like the hulls_hi meshes.
# The spindle is faceted porcelain: a flattened polygon section (crisp edges, one strip of vertices per facet so the facets stay flat),
# pointed at both ends, with a swelling hub where the sails root. Returns the same dict frame.load gives (pos, nor, idx, uv, tex) so the
# rest of the A4 chain (kit, dress, bake, export) runs unchanged; tex points at neutral maps (no AI occlusion or curvature to carry).
import os, math
import numpy as np


def profile(t, sp):
    """radius at t (0 = stern, 1 = bow tip): a long double taper with a hub bulge; stern=k leaves a flat stern face k times the radius
    (for the engine bells) instead of a point"""
    tt = np.clip(t, 0, 1); st = sp.get('stern', 0.); tp = sp.get('taper', .9)
    off = math.asin(min(st, .99) ** (1 / tp)) / math.pi if st else 0.  # start the sine part where it already has the stern's radius
    body = np.sin(np.pi * (off + (1 - off) * tt)) ** tp
    hub = sp.get('hub', .6) * np.exp(-((t - sp.get('hub_t', .5)) / sp.get('hub_w', .07)) ** 2)
    return sp['r'] * (body + hub)


def loft(sp, tmp):
    """sp: dict(r=max radius, facets=6, ys=1.3 (width scale), zs=.75 (height scale), n=180 sections, x=(-.5, .5), taper, hub, hub_t, hub_w,
    twist=0 (radians the facets turn bow to stern, a little spiral reads as hand-made))"""
    F = sp.get('facets', 6); N = sp.get('n', 180); x0, x1 = sp.get('x', (-.5, .5)); ys, zs = sp.get('ys', 1.3), sp.get('zs', .75)
    t = np.linspace(0, 1, N); xs = x0 + (x1 - x0) * t; r = profile(t, sp); r[-1] = 0.0
    st = sp.get('stern', 0.)
    if not st: r[0] = 0.0
    ang = [2 * math.pi * k / F for k in range(F + 1)]  # facet corners: for F=6 the edges run along port and starboard, flat faces on top and below
    # (a ray cast straight down a seam between two facet strips can slip through, so mounts sit on faces, not on the ridges)
    pos, uv, idx = [], [], []
    for k in range(F):
        a0, a1 = ang[k], ang[k + 1]; base = len(pos)
        for i in range(N):
            tw = sp.get('twist', 0.) * t[i]
            for a in (a0 + tw, a1 + tw):
                pos.append((xs[i], r[i] * ys * math.cos(a), r[i] * zs * math.sin(a))); uv.append((t[i], (k + (a - tw - a0) / (a1 - a0)) / F))
        for i in range(N - 1):
            p0, p1, p2, p3 = base + 2 * i, base + 2 * i + 1, base + 2 * i + 3, base + 2 * i + 2
            if i == 0 and not st: idx.append((p0, p3, p2))
            elif i == 0: idx += [(p0, p1, p2), (p0, p2, p3)]
            elif i == N - 2: idx.append((p0, p1, p3))
            else: idx += [(p0, p1, p2), (p0, p2, p3)]
    if st:  # the flat stern face: a fan per facet edge to the centre
        c0 = len(pos); pos.append((xs[0], 0., 0.)); uv.append((0., .5))
        for k in range(F):
            b0 = k * 2 * N; idx.append((c0, b0 + 1, b0))
    pos = np.array(pos, np.float64); idx = np.array(idx, np.int64); uv = np.array(uv, np.float64)
    # outward winding check and flat facet normals (each facet strip owns its vertices)
    P = pos[idx]; fn = np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0]); cen = P.mean(1)
    if (np.einsum('ij,ij->i', fn, cen * np.array([0, 1, 1])) < 0).sum() > len(idx) / 2: idx = idx[:, ::-1].copy(); fn = -fn
    if st:  # the stern cap faces aft, whatever the strips decided
        cap = np.nonzero((idx == len(pos) - 1).any(1))[0]
        P = pos[idx[cap]]; fx = np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0])[:, 0]; idx[cap[fx > 0]] = idx[cap[fx > 0]][:, ::-1]
        P = pos[idx]; fn = np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0])
    nor = np.zeros_like(pos)
    for c in range(3): np.add.at(nor, idx[:, c], fn)
    nor /= np.maximum(np.linalg.norm(nor, axis=1, keepdims=True), 1e-12)
    uv[:, 1] = uv[:, 1] * .98 + .01; uv[:, 0] = uv[:, 0] * .98 + .01
    return dict(pos=pos, nor=nor, idx=idx, uv=uv, uv2=uv, tex=neutral_maps(tmp), flipped=False)


def neutral_maps(tmp):
    """flat normal map and an occlusion/curvature map with nothing in it (R occlusion 1, G curvature .5), written once"""
    os.makedirs(tmp, exist_ok=True); nm = os.path.join(tmp, 'ithar_n.png'); mm = os.path.join(tmp, 'ithar_m.png')
    if not (os.path.exists(nm) and os.path.exists(mm)):
        import bpy
        for path, col in ((nm, (.5, .5, 1., 1.)), (mm, (1., .5, .5, 1.))):
            im = bpy.data.images.new(os.path.basename(path), 16, 16, alpha=False); im.pixels[:] = list(col) * 256
            im.filepath_raw = path; im.file_format = 'PNG'; im.save(); bpy.data.images.remove(im)
    return nm, mm
