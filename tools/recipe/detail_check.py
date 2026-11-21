# Stage 5: the surface-detail check (issue 1291; Ryan, Nov 19 2026 on C13 in game: "the flesh just looks like red clay" with no
# detail). A flat clay finish passed every stage 5 check, because nothing measured the surface itself. This reads the baked
# atlases a stage 5 bake writes (JOB/CELL_hull_normal.png, _albedo.png, _orm.png and the parts' set) and measures, over the
# texels the soft flesh covers (objects whose zone is flesh, flesh2, hide, tissue, vein or scar, and the hull skin itself; read
# from the painted blend's UVs, so the dilated margins and the armour do not count):
#   normal   the relief in the detail normal map: the mean angle (degrees) between each texel's normal and the local average
#            over a few texels round it (wrinkles, pores and cracks; a smooth bump is not detail)
#   albedo   the colour's local contrast: the mean absolute difference of luminance from its local average, over the mean
#            luminance (a painted mottle with no fine detail stays low)
#   rough    the roughness map's spread (standard deviation): matte skin wet in its folds, never one even sheen
# and fails when any of them is under the ship's floor. A ship opts in with "surface_detail" in its recipe json: true for the
# family floors below, or a dict that overrides one of them. A ship without the key is reported, never failed.
# usage: blender -b JOB/CELL.blend -P detail_check.py -- JOB CELL SHIP_JSON      (numpy and Pillow, as blink.py)
import json
import os
import sys

FLOORS = dict(normal=3.5, albedo=0.04, rough=0.08)   # Nov 20: the R341 C13 flesh measured 1.1, 0.066, 0.023; round 10 6.6, 0.063, 0.185
# Every atlas is measured at this size, whatever the bake's own (a box downsample), so the numbers and the floors mean the
# same detail at any bake resolution. Nov 20: the same round 10 paint measured 0.063 albedo contrast at the cloud's 1024
# bake and 0.021 at the PC's 4096, because a few texels of a 4096 atlas are a quarter of the skin a 1024 one covers.
REF = 1024


def _load(path, mode):
    from PIL import Image
    import numpy as np
    im = Image.open(path).convert(mode)
    if im.size != (REF, REF):
        im = im.resize((REF, REF), Image.BOX)
    return np.asarray(im).astype(np.float32) / 255.0


def _box(a, r):
    """the local average over a (2r+1) square, by an integral image (edges clamped)"""
    import numpy as np
    p = np.pad(a, ((r + 1, r), (r + 1, r)) + ((0, 0),) * (a.ndim - 2), mode='edge')
    c = p.cumsum(0).cumsum(1)
    k = 2 * r + 1
    return (c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]) / (k * k)


SOFT = ('flesh', 'flesh2', 'hide', 'tissue', 'vein', 'scar')


def soft_texels(cell, res):
    """{atlas: (rows, cols)} of the texels the soft flesh covers, sampled at four points in every UV triangle of every soft
    object in the open blend (an object's zone is the last word of its name; the hull skin is <ship>_hull)"""
    import bpy
    import numpy as np
    out = {}
    for o in bpy.data.objects:
        if o.type != 'MESH' or not o.data.uv_layers or o.get('role') == 'interior':
            continue
        zone = o.name.rsplit('_', 1)[-1]
        if not (zone in SOFT or o.name.endswith('_hull')):
            continue
        atlas = None
        for sl in o.material_slots:
            m = sl.material
            if m and m.use_nodes:
                for n in m.node_tree.nodes:
                    if n.type == 'TEX_IMAGE' and n.image and n.image.name.startswith(cell + '_'):
                        atlas = 'hull' if '_hull_' in n.image.name else 'parts'
        if atlas is None:
            continue
        me = o.data
        me.calc_loop_triangles()
        nt = len(me.loop_triangles)
        if not nt:
            continue
        li = np.zeros(nt * 3, dtype=np.int32)
        me.loop_triangles.foreach_get('loops', li)
        uv = np.zeros(len(me.loops) * 2, dtype=np.float32)
        me.uv_layers.active.data.foreach_get('uv', uv)
        t = uv.reshape(-1, 2)[li].reshape(nt, 3, 2)
        pts = [t.mean(1)] + [(t.mean(1) + t[:, k]) / 2 for k in range(3)]
        p = np.concatenate(pts)
        col = np.clip((p[:, 0] * res).astype(int), 0, res - 1)
        row = np.clip(((1.0 - p[:, 1]) * res).astype(int), 0, res - 1)
        a, b = out.get(atlas, (np.zeros(0, int), np.zeros(0, int)))
        out[atlas] = (np.concatenate([a, row]), np.concatenate([b, col]))
    return out


def measure(job, cell, r=3):
    import numpy as np
    try:
        import bpy  # noqa: F401
        inside = True
    except ImportError:
        inside = False
    sums = dict(normal=[], albedo=[], lum=[], rough=[])
    texels = 0
    for atlas in ('hull', 'parts'):
        base = os.path.join(job, '%s_%s_' % (cell, atlas))
        if not os.path.exists(base + 'normal.png'):
            continue
        nrm = _load(base + 'normal.png', 'RGB')
        alb = _load(base + 'albedo.png', 'RGB')
        orm = _load(base + 'orm.png', 'RGB')
        res = nrm.shape[0]
        if inside:
            idx = soft_texels(cell, res).get(atlas)
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
                rough=float(cat['rough'].std()), texels=int(texels), from_uvs=inside)


def main(job, cell, ship_json):
    try:
        with open(ship_json, encoding='utf-8') as f:
            ship = json.load(f)
        # issue 1291: every Chorus ship is gated by default (the grown look is the family's skin since R349); another
        # faction opts in, and a ship can opt out with "surface_detail": false
        want = ship.get('surface_detail', True if ship.get('faction') == 'chorus' else None)
    except (OSError, ValueError):
        want = None
    floors = dict(FLOORS)
    if isinstance(want, dict):
        floors.update({k: float(v) for k, v in want.items() if k in FLOORS})
    m = measure(job, cell)
    if m is None:
        print('detail check FAIL: no hull atlas to measure in %s (%s_hull_normal.png)' % (job, cell))
        return 1 if want else 0
    low = [k for k in FLOORS if m[k] < floors[k]]
    line = 'normal relief %.2f deg (floor %.2f), albedo contrast %.3f (floor %.3f), roughness spread %.3f (floor %.3f), %d texels' % (
        m['normal'], floors['normal'], m['albedo'], floors['albedo'], m['rough'], floors['rough'], m['texels'])
    with open(os.path.join(job, 'detail_check.json'), 'w', encoding='utf-8') as f:
        json.dump(dict(measured=m, floors=floors, gated=bool(want), low=low), f, indent=1)
    if not want:
        print('detail check (reported, this ship has no surface_detail floor): ' + line)
        return 0
    if low:
        print('detail check FAIL: a flat surface (%s under the floor): %s' % (', '.join(low), line))
        return 1
    print('PASS detail check: ' + line)
    return 0


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    sys.exit(main(*args[:3]))
