# A4: height profiles of a hull (first hit from above, below and the sides on a grid), to set cut boxes and seat parts by numbers
# instead of by eye. Blender working frame (x bow, y port, z up).
# usage: python3 probe.py CODE [top|below|port|stbd] [x0 x1 dx] [y-or-z values...]
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, '..', 'a2detail'), os.path.join(HERE, '..', 'hs')):
    if p not in sys.path: sys.path.insert(0, p)
import numpy as np
import bpy  # noqa: loads mathutils with the bpy module
from mathutils import Vector
from mathutils.bvhtree import BVHTree
import frame


def bvh(code, root=None, yaw=0):
    root = root or os.environ.get('A4_ROOT') or os.path.abspath(os.path.join(HERE, '..', '..', '..'))
    h = frame.load(root, code, yaw)
    return BVHTree.FromPolygons([tuple(map(float, v)) for v in h['pos']], [tuple(map(int, f)) for f in h['idx']]), h


def profile(T, side, xs, cs):
    d = {'top': ((0, 0, 2), (0, 0, -1)), 'below': ((0, 0, -2), (0, 0, 1)), 'port': ((0, 2, 0), (0, -1, 0)), 'stbd': ((0, -2, 0), (0, 1, 0))}[side]
    rows = []
    for c in cs:
        row = []
        for x in xs:
            o = Vector(d[0]); o.x = x
            if side in ('top', 'below'): o.y = c
            else: o.z = c
            h = T.ray_cast(o, Vector(d[1]), 4)
            row.append(None if h[0] is None else (h[0].z if side in ('top', 'below') else h[0].y))
        rows.append(row)
    return rows


if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    code = a[0]; side = a[1] if len(a) > 1 else 'top'
    x0, x1, dx = (float(v) for v in a[2:5]) if len(a) > 4 else (-.5, .5, .05)
    cs = [float(v) for v in a[5:]] or [0.0]
    import ships
    yaw = ships.SHIPS.get(code, {}).get('yaw', ships.YAWS.get(code, 0))
    T, h = bvh(code, yaw=yaw)
    xs = np.arange(x0, x1 + 1e-9, dx)
    print(f'{code} {side}: first hit {"z" if side in ("top", "below") else "y"} per x (columns), rows at {"y" if side in ("top", "below") else "z"} =', cs)
    print('      x ' + ' '.join(f'{x:+6.3f}' for x in xs))
    for c, row in zip(cs, profile(T, side, xs, cs)):
        print(f'{c:+7.3f} ' + ' '.join('   -  ' if v is None else f'{v:+6.3f}' for v in row))
