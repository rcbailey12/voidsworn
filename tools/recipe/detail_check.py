# Stage 5: the surface-detail check (issue 1291; Ryan, Nov 19 2026 on C13 in game: "the flesh just looks like red clay" with no
# detail; issue 1517, Nov 21 2026: Navy O2 and O3 went to Ryan for a publish OK at normal relief 1.54 and 1.45 against the 3.5
# floor, because only Chorus ships were gated: "Just make sure the level of detail is on both so they don't look like clay").
# A flat clay finish passed every stage 5 check, because nothing measured the surface itself. This reads the baked atlases
# inside the painted blend (images CELL_hull_* and CELL_parts_* for normal, albedo and orm: the very bake stage 7 exports,
# never a file on disk; outside Blender, the self-test's fixture files) and measures, over the texels of the visible outside
# skin (every outside object on the hull and parts atlases, read from the blend's UVs; a surface covered by another within
# 3 percent of the ship's length, such as the bare shell under authored panels, is left out, and so are glow and insides):
#   normal   the relief in the detail normal map: the mean angle (degrees) between each texel's normal and the local average
#            over a few texels round it (rivets, seams, wrinkles, pores and cracks; a smooth bump is not detail)
#   albedo   the colour's local contrast: the mean absolute difference of luminance from its local average, over the mean
#            luminance (a painted mottle with no fine detail stays low)
#   rough    the roughness map's spread (standard deviation): never one even sheen
# and fails when any of them is under the faction's floor (FLOORS below). Every ship of every faction is gated (issue 1517).
# A ship json may raise a floor with "surface_detail": {"normal": 4.0}. Lowering a floor, or skipping the check, needs a dated
# opt-out with Ryan's own words in the same dict: "surface_detail": {"opt_out": {"date": "2026-11-21", "ryan": "<his words>"}}.
# A bare "surface_detail": false is refused (it was the old opt-out).
# Prints exactly one verdict line: "PASS detail check: ...", "detail check FAIL: ..." or "OPT-OUT detail check: ...", and writes
# JOB/detail_check.json. tools/recipe/offer_sheet.py and tools/recipe/publish_ship.py read that line (detail_verdict below).
# usage: blender -b JOB/CELL.blend -P detail_check.py -- JOB CELL SHIP_JSON      (numpy and Pillow, as blink.py)
import json
import os
import re
import sys

# The floors per faction (issue 1517), each 80 percent of the least-detailed ship Ryan accepted in game, measured the way this
# file measures on a cloud 1024 bake of that ship (docs/ship_pipeline/detail_floors.md has every ship's numbers). On the
# hard-plate factions the colour's local contrast is the number that tells clay from finished: Navy O2 0.12 and O3 0.07
# against Dominion H10 0.19 and Iron Mandate IM5 0.20.
FLOORS = {
    'chorus': dict(normal=3.5, albedo=0.04, rough=0.08),      # issue 1291 floors kept; round G C10, C12 least 7.0/0.065/0.158
    'voidsworn': dict(normal=0.94, albedo=0.26, rough=0.13),  # Sunward S8, S9, S10, S11 least 1.18/0.328/0.165
    'hegemony': dict(normal=0.95, albedo=0.15, rough=0.12),   # Navy H10, IM5 least 1.19/0.193/0.151
    'hullbreakers': dict(normal=1.31, albedo=0.30, rough=0.17),  # A18, A19 least 1.64/0.375/0.223
    'eclipse': dict(normal=0.62, albedo=0.37, rough=0.13),    # E11 0.78/0.466/0.162
    'ithar': dict(normal=0.6, albedo=0.02, rough=0.01),       # Glasswrights, smooth pearl glass by design: CD5, GV2, GW4 least
                                                              # 0.76/0.030/0.016
}
DEFAULT = dict(FLOORS['hegemony'])                            # a faction with no accepted new-format ship: the Navy floor
KEYS = ('normal', 'albedo', 'rough')
# Every atlas is measured at this size, whatever the bake's own (a box downsample), so the numbers and the floors mean the
# same detail at any bake resolution. Nov 20: the same round 10 paint measured 0.063 albedo contrast at the cloud's 1024
# bake and 0.021 at the PC's 4096, because a few texels of a 4096 atlas are a quarter of the skin a 1024 one covers.
REF = 1024
VERDICT = re.compile(r'^(PASS detail check|detail check FAIL|OPT-OUT detail check)\b', re.M)


def _to_ref(im):
    from PIL import Image
    import numpy as np
    im = im.convert('RGB')
    if im.size != (REF, REF):
        im = im.resize((REF, REF), Image.BOX)
    return np.asarray(im).astype(np.float32) / 255.0


def _load(path, mode='RGB'):
    from PIL import Image
    return _to_ref(Image.open(path))


def _blend_atlas(name):
    """the baked atlas the open blend's materials sample (image `name`), at REF size, or None when the blend has no such
    image or it holds no pixels. Issue 1517 (Artoo on PR 1521): stage 5 measures the bake it just made, inside the blend
    stage 7 exports, never a file looked up on disk (the PC's Glasswright and KF1 runs had no atlas files in the job root,
    and an older export's atlas must never stand in)."""
    import numpy as np
    import bpy
    from PIL import Image
    im = bpy.data.images.get(name)
    if im is None:
        return None
    w, h = im.size
    if w < 1 or h < 1:
        return None
    px = np.empty(w * h * im.channels, dtype=np.float32)
    im.pixels.foreach_get(px)
    a = px.reshape(h, w, im.channels)[::-1, :, :3]
    return _to_ref(Image.fromarray(np.clip(np.round(a * 255.0), 0, 255).astype(np.uint8), 'RGB'))


def _box(a, r):
    """the local average over a (2r+1) square, by an integral image (edges clamped)"""
    import numpy as np
    p = np.pad(a, ((r + 1, r), (r + 1, r)) + ((0, 0),) * (a.ndim - 2), mode='edge')
    c = p.cumsum(0).cumsum(1)
    k = 2 * r + 1
    return (c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]) / (k * k)


def _atlas(o, cell):
    """'hull' or 'parts' for the baked atlas this object's material samples, None when it samples neither (glow, insides)"""
    found = None
    for sl in o.material_slots:
        m = sl.material
        if m and m.use_nodes:
            for n in m.node_tree.nodes:
                if n.type != 'TEX_IMAGE' or not n.image:
                    continue
                name = n.image.name
                if name.startswith(cell + '_hull_'):
                    return 'hull'
                if name.startswith(cell + '_parts_'):
                    found = 'parts'
    return found


COVER = 0.03   # a skin point with any surface within this share of the ship's length straight out from it is covered


def skin_texels(cell, res, info=None):
    """{atlas: (rows, cols)} of the texels of the visible outside skin: every outside object on the hull atlas and the parts
    atlas (Board on PR 1521: the cargo containers and other parts are what Ryan sees too), sampled at four points in every
    UV triangle. A triangle whose centre has another surface straight out from it within COVER of the ship's length (the
    bare hull shell under authored panels, Board on PR 1521: 28 percent of O2's old sample) is hidden in game and left out.
    info, a dict, gets the counts."""
    import numpy as np
    import bpy
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    outside = [o for o in bpy.data.objects if o.type == 'MESH' and o.get('role') != 'interior' and len(o.data.polygons)]
    verts, polys = [], []
    for o in outside:
        mw = o.matrix_world
        base = len(verts)
        verts.extend(mw @ v.co for v in o.data.vertices)
        polys.extend([base + i for i in p.vertices] for p in o.data.polygons)
    if not verts:
        return {}
    tree = BVHTree.FromPolygons(verts, polys)
    va = np.array([tuple(v) for v in verts], dtype=np.float64)
    reach = COVER * float((va.max(0) - va.min(0)).max())
    out = {}
    seen = hidden = 0
    for o in outside:
        if not o.data.uv_layers or o.get('emissive_zone'):
            continue
        atlas = _atlas(o, cell)
        if atlas is None:
            continue
        me = o.data
        me.calc_loop_triangles()
        nt = len(me.loop_triangles)
        if not nt:
            continue
        li = np.zeros(nt * 3, dtype=np.int32)
        me.loop_triangles.foreach_get('loops', li)
        vi = np.zeros(nt * 3, dtype=np.int32)
        me.loop_triangles.foreach_get('vertices', vi)
        co = np.zeros(len(me.vertices) * 3, dtype=np.float64)
        me.vertices.foreach_get('co', co)
        mw = np.array(o.matrix_world)
        w = co.reshape(-1, 3) @ mw[:3, :3].T + mw[:3, 3]
        tri = w[vi].reshape(nt, 3, 3)
        cen = tri.mean(1)
        nrm = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
        ln = np.linalg.norm(nrm, axis=1)
        keep = np.zeros(nt, bool)
        for i in np.nonzero(ln > 1e-12)[0]:
            n = Vector(nrm[i] / ln[i])
            hit = tree.ray_cast(Vector(cen[i]) + n * (reach * 0.02), n, reach)
            keep[i] = hit[0] is None
        seen += nt
        hidden += int((~keep).sum())
        if not keep.any():
            continue
        uv = np.zeros(len(me.loops) * 2, dtype=np.float32)
        me.uv_layers.active.data.foreach_get('uv', uv)
        t = uv.reshape(-1, 2)[li].reshape(nt, 3, 2)[keep]
        pts = [t.mean(1)] + [(t.mean(1) + t[:, k]) / 2 for k in range(3)]
        p = np.concatenate(pts)
        col = np.clip((p[:, 0] * res).astype(int), 0, res - 1)
        row = np.clip(((1.0 - p[:, 1]) * res).astype(int), 0, res - 1)
        a, b = out.get(atlas, (np.zeros(0, int), np.zeros(0, int)))
        out[atlas] = (np.concatenate([a, row]), np.concatenate([b, col]))
    if info is not None:
        info.update(triangles=seen, covered=hidden)
    return out


def measure(job, cell, r=3, masks=None):
    """the three numbers over the skin's texels. masks: {atlas: bool array REF x REF} instead of the open blend's UVs (the
    self-test's fixtures); without either, outside Blender, every texel of the atlas counts"""
    import numpy as np
    if masks is None:
        try:
            import bpy  # noqa: F401
            inside = True
        except ImportError:
            inside = False
        cover = {}
        texel_idx = skin_texels(cell, REF, cover) if inside else None
    else:
        inside, texel_idx, cover = 'mask', None, {}
    sums = dict(normal=[], albedo=[], lum=[], rough=[])
    texels = 0
    for atlas in ('hull', 'parts'):
        if inside is True:      # inside Blender: the open blend's own baked images, the ones stage 7 exports
            maps = [_blend_atlas('%s_%s_%s' % (cell, atlas, k)) for k in ('normal', 'albedo', 'orm')]
            if any(m is None for m in maps):
                continue
            nrm, alb, orm = maps
        else:                   # the self-test's fixtures, or a folder of atlas files outside Blender
            base = os.path.join(job, '%s_%s_' % (cell, atlas))
            if not os.path.exists(base + 'normal.png'):
                continue
            nrm, alb, orm = _load(base + 'normal.png'), _load(base + 'albedo.png'), _load(base + 'orm.png')
        res = nrm.shape[0]
        if masks is not None:
            if atlas not in masks:
                continue
            sel = np.nonzero(masks[atlas])
        elif texel_idx is not None:
            idx = texel_idx.get(atlas)
            if idx is None:
                continue
            flat = np.unique(idx[0] * res + idx[1])
            sel = (flat // res, flat % res)
        else:
            sel = np.nonzero(np.ones(nrm.shape[:2], bool))
        n = nrm * 2.0 - 1.0
        nl = n / np.maximum(np.linalg.norm(n, axis=2, keepdims=True), 1e-6)
        avg = _box(nl, r)
        avg /= np.maximum(np.linalg.norm(avg, axis=2, keepdims=True), 1e-6)
        ang = np.degrees(np.arccos(np.clip((nl * avg).sum(2), -1, 1)))
        lum = alb[..., 0] * 0.2126 + alb[..., 1] * 0.7152 + alb[..., 2] * 0.0722
        la = _box(lum, r)
        sums['normal'].append(ang[sel]); sums['albedo'].append(np.abs(lum - la)[sel]); sums['lum'].append(lum[sel])
        sums['rough'].append(orm[..., 1][sel])
        texels += len(sel[0])
    if texels < 1000:
        return None
    cat = {k: np.concatenate(v) for k, v in sums.items()}
    return dict(normal=float(cat['normal'].mean()), albedo=float(cat['albedo'].mean() / max(1e-4, cat['lum'].mean())),
                rough=float(cat['rough'].std()), texels=int(texels), from_uvs=inside,
                covered_share=round(cover['covered'] / max(1, cover['triangles']), 3) if cover else None)


def floors_for(ship):
    """(floors, opt_out, problem) for a ship json dict: the faction's floors, raised by the ship's own "surface_detail" dict;
    opt_out is Ryan's dated record or None; problem is why the json's key is refused, or None"""
    fac = ship.get('faction') or ''
    floors = dict(FLOORS.get(fac, DEFAULT))
    base = dict(floors)
    want = ship.get('surface_detail', True)
    if want is True:
        return floors, None, None
    if not isinstance(want, dict):
        return floors, None, ('"surface_detail": %s is not an opt-out any more (issue 1517): it needs {"opt_out": {"date": '
                              '"YYYY-MM-DD", "ryan": "<his words>"}}' % json.dumps(want))
    opt = want.get('opt_out')
    if opt is not None:
        ok = (isinstance(opt, dict) and re.match(r'^\d{4}-\d\d-\d\d$', str(opt.get('date', '')))
              and len(str(opt.get('ryan', '')).strip()) >= 3)
        if not ok:
            return floors, None, 'the surface_detail opt_out needs a "date" (YYYY-MM-DD) and "ryan" (his own words)'
    for k in KEYS:
        if k in want:
            floors[k] = float(want[k])
    lowered = [k for k in KEYS if floors[k] < base[k]]
    if lowered and opt is None:
        return base, None, 'surface_detail lowers the %s floor (%s) without a dated opt_out from Ryan' % (
            fac or 'default', ', '.join(lowered))
    return floors, opt, None


def detail_verdict(text):
    """'PASS', 'FAIL', 'OPT-OUT' or None (no verdict line) from a log_detail.txt's text"""
    m = VERDICT.search(text or '')
    if not m:
        return None
    return {'PASS detail check': 'PASS', 'detail check FAIL': 'FAIL', 'OPT-OUT detail check': 'OPT-OUT'}[m.group(1)]


def detail_line(text):
    """the verdict line itself, for a sheet's caption"""
    for line in (text or '').splitlines():
        if VERDICT.match(line):
            return line.strip()
    return None


def main(job, cell, ship_json, masks=None):
    try:
        with open(ship_json, encoding='utf-8') as f:
            ship = json.load(f)
    except (OSError, ValueError) as e:
        print('detail check FAIL: the ship json %s could not be read (%s)' % (ship_json, e))
        return 1
    floors, opt, problem = floors_for(ship)
    m = measure(job, cell, masks=masks)
    rec = dict(faction=ship.get('faction'), floors=floors, opt_out=opt, problem=problem, measured=m)
    if m is None:
        line = 'no outside skin to measure: the blend has no baked %s_hull_normal, _albedo and _orm images over hull UVs' % cell
        low = list(KEYS)
    else:
        low = [k for k in KEYS if m[k] < floors[k]]
        line = 'normal relief %.2f deg (floor %.2f), albedo contrast %.3f (floor %.3f), roughness spread %.3f (floor %.3f), %d texels' % (
            m['normal'], floors['normal'], m['albedo'], floors['albedo'], m['rough'], floors['rough'], m['texels'])
    if problem:
        verdict, msg = 'FAIL', 'detail check FAIL: %s; %s' % (problem, line)
    elif low and opt:
        verdict, msg = 'OPT-OUT', 'OPT-OUT detail check: %s under the floor, Ryan %s: "%s"; %s' % (
            ', '.join(low), opt['date'], opt['ryan'], line)
    elif low:
        verdict, msg = 'FAIL', 'detail check FAIL: a flat clay surface (%s under the %s floor): %s' % (
            ', '.join(low), ship.get('faction') or 'default', line)
    else:
        verdict, msg = 'PASS', 'PASS detail check: ' + line
    rec.update(low=low, verdict=verdict, line=msg)
    with open(os.path.join(job, 'detail_check.json'), 'w', encoding='utf-8') as f:
        json.dump(rec, f, indent=1)
    print(msg)
    return 1 if verdict == 'FAIL' else 0


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    sys.exit(main(*args[:3]))
