"""Check every Glasswright interior part against a single containing enclosure.

blender -b SHIP.blend --python-exit-code 1 -P room_skin_check.py -- [ithar_GS1] [--selftest]
The sheet argument defaults to the identity recorded in a recipe blend.
Run --selftest on a GP1 build to exercise the split pods and an authored bridge.
"""
import argparse
import importlib.util
import math
from pathlib import Path
import sys

from mathutils import Vector
from mathutils.bvhtree import BVHTree

EPS = 1e-5  # mesh/ray float roundoff, in design units
BRIDGE_KEY = 'room_skin_bridge'


def radial_overrun(bvh, limit, start, u, v, axis):
    """Cast from a section's centre to its first wall, with a seam-ray fallback."""
    r = math.hypot(u, v)
    du, dv = (u / r, v / r) if r else (1.0, 0.0)
    def direction(a, b):
        return (0, a, b) if axis == 'x' else (a, 0, b)
    _, _, _, dist = bvh.ray_cast(start, direction(du, dv), limit)
    if dist is None:
        _, _, _, dist = bvh.ray_cast(start, direction(du - 1e-5 * dv, dv + 1e-5 * du), limit)
    return r - dist if dist is not None else math.inf


class InnerSkin:
    def __init__(self, core, skin, scale=1.0):
        """The sheet's section axis and its tessellated inner wall, in design units."""
        import bpy
        self.skin = skin
        self.name = core.name
        me = core.data
        mod = core.modifiers.get('skin') or core.modifiers.get('shell')
        ev = None
        if mod:
            # Craft use Solidify, which appends the back layer on evaluation.
            n = len(me.vertices)
            bpy.context.view_layer.update()
            ev = core.evaluated_get(bpy.context.evaluated_depsgraph_get())
            me = ev.to_mesh()
        else:
            # thick_shell appends the back layer in the same order.
            n = len(me.vertices) // 2
        try:
            if len(me.vertices) != 2 * n:
                raise ValueError(f'{core.name} has no matching inner glass vertices')
            world = core.matrix_world
            verts = [world @ me.vertices[i].co / scale for i in range(n, 2 * n)]
            faces = [tuple(i - n for i in p.vertices) for p in me.polygons if min(p.vertices) >= n]
            if not faces:
                raise ValueError(f'{core.name} has no inner glass faces')
        finally:
            if ev is not None:
                ev.to_mesh_clear()
        mid = (min(v.x for v in verts) + max(v.x for v in verts)) / 2
        self.y0 = skin(mid, math.pi / 2)[1]
        self.z0 = skin(mid, 0.0)[2]
        self.bvh = BVHTree.FromPolygons(verts, faces)
        self.limit = 2 * max(v.length for v in verts)

    def overrun(self, x, y, z):
        return radial_overrun(self.bvh, self.limit, (x, self.y0, self.z0), y - self.y0, z - self.z0, 'x')

    def tuck(self, p, clearance):
        """Pull an existing deck, frame or waveguide vertex inside along its section ray."""
        return self.radial_scale(p, self.tuck_factor(p, self.overrun(*p) + clearance))

    def tuck_factor(self, p, d):
        if d <= 0:
            return 1.0
        r = math.hypot(p.y - self.y0, p.z - self.z0)
        if not math.isfinite(d) or d > r:
            raise ValueError(f'no interior clearance at {tuple(p)}')
        return 1 - d / r

    def radial_scale(self, p, factor):
        if factor == 1:
            return p
        return Vector((p.x, self.y0 + (p.y - self.y0) * factor, self.z0 + (p.z - self.z0) * factor))


class BridgeSkin:
    """An authored bridge tube, sectioned across the ship rather than along it."""
    def __init__(self, bridge, centre, scale=1.0):
        import bpy
        self.name = bridge.name
        self.centre = centre
        ev = bridge.evaluated_get(bpy.context.evaluated_depsgraph_get())
        me = ev.to_mesh()
        try:
            verts = [ev.matrix_world @ v.co / scale for v in me.vertices]
            self.bvh = BVHTree.FromPolygons(verts, [tuple(f.vertices) for f in me.polygons])
        finally:
            ev.to_mesh_clear()
        self.limit = 2 * max(v.length for v in verts)

    def overrun(self, x, y, z):
        cx, cz = self.centre(y)
        return radial_overrun(self.bvh, self.limit, (cx, y, cz), x - cx, z - cz, 'y')


def containing_skin(points, skins):
    """Pick once per part, breaking ties by the sheet's skin order."""
    if len(skins) == 1:
        return skins[0]
    return max(skins, key=lambda skin: sum(skin.overrun(*p) <= EPS for p in points))


def samples(mesh, points):
    for i, p in enumerate(points):
        yield f'vertex {i}', p, (i,)
    for e in mesh.edges:
        a, b = (points[i] for i in e.vertices)
        for t in (0.25, 0.5, 0.75):
            yield f'edge {e.index} at {t}', a.lerp(b, t), e.vertices
    for f in mesh.polygons:
        centre = sum((points[i] for i in f.vertices), Vector((0, 0, 0))) / len(f.vertices)
        yield f'face {f.index} centre', centre, f.vertices


def check(objects, skins, scale=1.0, bridges=None):
    """Check evaluated geometry, including deck solidify and added dressing."""
    import bpy
    bridges = bridges or {}
    deps = bpy.context.evaluated_depsgraph_get()
    failures = sampled = count = 0
    for ob in sorted(objects, key=lambda o: o.name):
        if ob.type != 'MESH':
            continue
        count += 1
        ev = ob.evaluated_get(deps)
        me = ev.to_mesh()
        try:
            points = [ev.matrix_world @ v.co / scale for v in me.vertices]
            bridge = ob.get(BRIDGE_KEY)
            if bridge is not None and bridge not in bridges:
                print(f'  {ob.name} names an unknown bridge enclosure: {bridge!r}')
                failures += 1
                continue
            skin = bridges[bridge] if bridge is not None else containing_skin(points, skins)
            worst = EPS
            for label, p, _ in samples(me, points):
                sampled += 1
                d = skin.overrun(*p)
                if d > worst:
                    worst, where, point = d, label, p
            if worst > EPS:
                failures += 1
                print(f'  {ob.name} [{where}] ({point.x:.5f}, {point.y:.5f}, {point.z:.5f}) '
                      f'past {skin.name} by {worst:.5f}')
        finally:
            ev.to_mesh_clear()
    return failures, count, sampled


def fit_structure_samples(mesh, points, skin, clearance):
    """Tuck a dip between vertices by moving only the vertices that support it."""
    for attempt in range(4):
        factors = [1.0] * len(points)
        for _, p, indices in samples(mesh, points):
            d = skin.overrun(*p)
            if d > EPS:
                f = skin.tuck_factor(p, d + clearance)
                for i in indices:
                    factors[i] = min(factors[i], f)
        least = min(factors, default=1.0)
        if least == 1:
            return points
        if attempt == 3:
            # Uniform radial scaling commutes with the sample interpolation.
            # Use it only if local moves still leave an overrun.
            factors = [least] * len(points)
        points = [skin.radial_scale(p, f) for p, f in zip(points, factors)]
    return points


def tuck_structure(ob, skins, length):
    """Fit existing glass structure only where it protrudes. Keep its faces and materials."""
    import bpy
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(deps)
    world = ev.matrix_world.copy()
    # A twin hull's structure belongs to the pod in which it was authored.
    center = sum((world @ Vector(c)).y for c in ev.bound_box) / 8
    skin = min(skins, key=lambda s: abs(s.y0 - center))
    clearance = 0.002 * length
    me = ev.to_mesh()
    try:
        points = [skin.tuck(world @ v.co, clearance) for v in me.vertices]
        points = fit_structure_samples(me, points, skin, clearance)
        changed = any((p - (world @ v.co)).length_squared > 1e-12 for p, v in zip(points, me.vertices))
    finally:
        ev.to_mesh_clear()
    if changed:
        fitted = bpy.data.meshes.new_from_object(ev, depsgraph=deps)
        local = world.inverted()
        for v, p in zip(fitted.vertices, points):
            v.co = local @ p
        fitted.update()
        ob.data = fitted
        ob.modifiers.clear()


def selftest(sheet, skins, bridges):
    """Exercise the old false pass and prove that a named bridge is still checked."""
    import bpy

    def box(name, x, y, z, dx, dy, dz):
        points = [(x + i * dx, y + j * dy, z + k * dz) for k in (-1, 1)
                  for i, j in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(points, [], faces)
        ob = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(ob)
        bpy.context.view_layer.update()
        return ob, points

    split, points = box('fixture_open_cleft', 0, 0, 0, .06, sheet.YP, .04)
    # All eight corners pass the old union test, four in each pod.
    if not all(any(s.overrun(*p) <= EPS for s in skins) for p in points):
        raise ValueError('cleft fixture must pass the old vertex-only union test')
    if any(sum(s.overrun(*p) <= EPS for p in points) != 4 for s in skins):
        raise ValueError('cleft fixture must place four corners in each pod')
    if check([split], skins, bridges=bridges) != (1, 1, 50):
        raise ValueError('open-cleft box must fail with all 50 samples checked')

    aft, fwd = bridges
    x, z = bridges[aft].centre(0)
    span, _ = box('fixture_real_bridge', x, 0, z - .03, .06, .8, .02)
    if check([span], skins, bridges=bridges)[0] != 1:
        raise ValueError('a part spanning the cleft must name its enclosure')
    span[BRIDGE_KEY] = aft
    if check([span], skins, bridges=bridges) != (0, 1, 50):
        raise ValueError('the box should fit inside its named bridge')
    span[BRIDGE_KEY] = fwd
    if check([span], skins, bridges=bridges)[0] != 1:
        raise ValueError('the same box must fail against the wrong bridge')
    print('PASS room skin selftest: open-cleft box refused; real bridge box fits its named enclosure only', flush=True)


def main():
    import bpy
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('code', nargs='?')
    parser.add_argument('--selftest', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    sc = bpy.context.scene
    code = args.code or sc.get('r209_sheet')
    if not code or not code.startswith('ithar_'):
        raise SystemExit('room skin check needs a Glasswright sheet name')
    if sc.get('r209_sheet', code) != code:
        raise SystemExit(f'{code} does not match the blend sheet {sc["r209_sheet"]}')
    here = Path(__file__).resolve().parent
    sys.path.insert(0, str(here))
    spec = importlib.util.spec_from_file_location(code, here / 'ships' / f'{code}.py')
    sheet = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sheet)
    scale = float(sc.get('r209_scale', 1.0))
    if hasattr(sheet, 'pod'):
        skins = [InnerSkin(sc.objects[f'{sheet.CODE}_{tag}_pane_hull'], sheet.pod(side), scale)
                 for side, tag in ((1, 'port'), (-1, 'stbd'))]
    else:
        skin = getattr(sheet, 'skin', None) or sheet.core
        skins = [InnerSkin(sc.objects[f'{sheet.CODE}_mosaic_core'], skin, scale=scale)]
    bridges = sheet.bridge_skins(sc.objects, scale) if hasattr(sheet, 'bridge_skins') else {}
    if args.selftest:
        if code != 'ithar_GP1':
            parser.error('--selftest needs a GP1 blend')
        selftest(sheet, skins, bridges)
        return 0
    objects = [ob for ob in sc.objects if ob.name.startswith('in_') or ob.get('inside') or ob.get('role') == 'interior']
    bad, count, sampled = check(objects, skins, scale, bridges)
    print(f'{"PASS" if count and not bad else "FAIL"} room skin {code}: '
          f'{bad} of {count} inside parts past their containing skin ({sampled} samples checked)', flush=True)
    return 0 if count and not bad else 1


if __name__ == '__main__':
    sys.dont_write_bytecode = True
    sys.exit(main())
