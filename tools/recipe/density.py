# R224, measured: every part type carries the hull's detail density, in the mesh and in the paint (issue 601; ships.md 2c;
# RULEBOOK 4.11). Ryan, Nov 12 2026, on the Eclipse weapons: "They also just look smoother and less detailed, maybe slightly less
# poly than the rest of the ship". Runs inside Blender on a painted stage 5 scene (tools/blender/r209/bake_sheet.py calls it).
# Per part type (the kit's part_kind; the hull is its own row), per square ship unit of surface:
#   mesh   triangles, and edge features (edges whose faces meet at more than 30 degrees: seams, steps, bevels, greebles)
#   paint  texels (the atlas resolution on that surface), and paint detail: the share of the surface whose baked albedo is as
#          busy as the busiest PAINT_TOP share of the hull's (the contrast of the albedo per ship unit along the surface: scuffs,
#          rivets, plate tones, rust, wear), sampled at random points; so the hull reads PAINT_TOP by definition and a part type
#          painted smoother, or at a lower resolution, reads less
# A part type more than 25 percent under the hull on any of the four is flagged (R224: flagged on the sheet, fixed in the build).
# Reported, never a pass bar of its own: the sheet carries the table.
import math
import numpy as np
import bpy

PAINT_TOP = .30        # the hull's busiest 30 percent sets the bar for paint detail
SHARP = math.radians(30)
UNDER = .75            # a part type under 0.75 of the hull is flagged
SAMPLES = 4000         # random surface points per part type (area weighted)


def _lum(path):
    im = bpy.data.images.load(path, check_existing=True); w, h = im.size
    a = np.empty(w * h * 4, np.float32); im.pixels.foreach_get(a); a = a.reshape(h, w, 4)
    L = np.log(a[..., 0] * .2126 + a[..., 1] * .7152 + a[..., 2] * .0722 + .02)      # contrast, so a dark ship's detail counts
    gy, gx = np.gradient(L)
    return np.hypot(gx, gy), w


def _tris(o):
    me = o.data; me.calc_loop_triangles(); M = o.matrix_world
    V = np.array([M @ v.co for v in me.vertices], np.float64) if len(me.vertices) else np.zeros((0, 3))
    T = np.array([t.vertices[:] for t in me.loop_triangles], np.int64).reshape(-1, 3)
    uvl = me.uv_layers.active.data if me.uv_layers.active else None
    UV = np.array([[uvl[l].uv[:] for l in t.loops] for t in me.loop_triangles], np.float64).reshape(-1, 3, 2) if uvl else None
    return V, T, UV


def _sharp_edges(o):
    me = o.data; n = 0
    import bmesh
    bm = bmesh.new(); bm.from_mesh(me)
    for e in bm.edges:
        if len(e.link_faces) == 2 and e.calc_face_angle(0) > SHARP: n += 1
        elif len(e.link_faces) == 1: n += 1      # an open rim is an edge feature too
    bm.free(); return n


def measure(scene, hull_albedo, parts_albedo):
    gH, RH = _lum(hull_albedo); gP, RP = _lum(parts_albedo)
    rng = np.random.default_rng(224)
    rows = {}
    for o in scene.objects:
        if o.type != 'MESH': continue
        role = o.get('role')
        if role == 'interior' or not o.data.uv_layers: continue
        mat = o.data.materials[0].name if o.data.materials else ''
        if mat.startswith('p3_glow'): continue
        kind = 'hull' if role == 'hull' else (o.get('part_kind') or 'part')
        V, T, UV = _tris(o)
        if not len(T): continue
        a = np.linalg.norm(np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]]), axis=1) / 2
        r = rows.setdefault(kind, dict(area=0.0, tris=0, sharp=0, tri_area=[], tri_uv=[], g=None, R=None))
        r['area'] += float(a.sum()); r['tris'] += len(T); r['sharp'] += _sharp_edges(o)
        if UV is not None:
            ua = np.abs((UV[:, 1, 0] - UV[:, 0, 0]) * (UV[:, 2, 1] - UV[:, 0, 1]) - (UV[:, 2, 0] - UV[:, 0, 0]) * (UV[:, 1, 1] - UV[:, 0, 1])) / 2
            r['tri_area'].append(a); r['tri_uv'].append((ua, UV, 'H' if role == 'hull' else 'P'))
    out = {}; vals = {}
    for kind, r in rows.items():
        if r['area'] <= 0: continue
        A = np.concatenate(r['tri_area']); ua = np.concatenate([x[0] for x in r['tri_uv']]); UV = np.concatenate([x[1] for x in r['tri_uv']])
        grp = r['tri_uv'][0][2]; g, R = (gH, RH) if grp == 'H' else (gP, RP)
        tex = float((ua * R * R).sum() / A.sum())
        p = A / A.sum(); idx = rng.choice(len(A), SAMPLES, p=p)
        u = rng.random((SAMPLES, 2)); s = u.sum(1) > 1; u[s] = 1 - u[s]
        uv = UV[idx, 0] * (1 - u[:, :1] - u[:, 1:]) + UV[idx, 1] * u[:, :1] + UV[idx, 2] * u[:, 1:]
        px = np.clip((uv[:, 0] * R).astype(int), 0, R - 1); py = np.clip((uv[:, 1] * R).astype(int), 0, R - 1)
        tpu = np.sqrt(np.maximum(ua[idx] * R * R / np.maximum(A[idx], 1e-12), 1e-9))     # texels per ship unit, along the surface
        vals[kind] = g[py, px] * tpu
        out[kind] = dict(area=round(r['area'], 5), triangles=r['tris'], tris_per_unit2=round(r['tris'] / r['area'], 1),
                         edges_per_unit2=round(r['sharp'] / r['area'], 1), texels_per_unit2=round(tex, 1), atlas='hull' if grp == 'H' else 'parts')
    bar = float(np.quantile(vals['hull'], 1 - PAINT_TOP)) if 'hull' in vals else 0.0
    for kind, v in vals.items(): out[kind]['paint_detail_share'] = round(float((v > bar).mean()), 3)
    hull = out.get('hull')
    flags = []
    if hull:
        for kind, d in out.items():
            if kind == 'hull': continue
            for k in ('tris_per_unit2', 'edges_per_unit2', 'texels_per_unit2', 'paint_detail_share'):
                ratio = d[k] / max(hull[k], 1e-9); d[k + '_vs_hull'] = round(ratio, 2)
                if ratio < UNDER: flags.append(f'{kind}: {k} {d[k]} is {ratio:.2f} of the hull\'s {hull[k]}')
    summary = dict(paint_flags=[f for f in flags if 'texels' in f or 'paint' in f], mesh_flags=[f for f in flags if 'tris' in f or 'edges' in f],
                   hull=hull, rule='R224: a part type more than 25 percent under the hull is flagged', paint_bar_per_unit=round(bar, 2), paint_top=PAINT_TOP)
    return dict(summary=summary, types=out)
