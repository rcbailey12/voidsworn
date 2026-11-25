"""Check every Glasswright interior vertex against the baked core's inner glass.

blender -b SHIP.blend --python-exit-code 1 -P room_skin_check.py -- [ithar_GS1]
The sheet argument defaults to the identity recorded in a recipe blend.
"""
import importlib.util
import math
from pathlib import Path
import sys

from mathutils import Vector
from mathutils.bvhtree import BVHTree


class InnerSkin:
    def __init__(self, core, skin, scale=1.0):
        """The sheet's section axis and its tessellated inner wall, in design units."""
        import bpy
        self.skin = skin
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
        # At fixed x, cast out from the section axis to the first inner wall.
        # A small angular fallback avoids a ray exactly on a tessellation edge.
        r = math.hypot(y - self.y0, z - self.z0)
        dy, dz = ((y - self.y0) / r, (z - self.z0) / r) if r else (1.0, 0.0)
        start = (x, self.y0, self.z0)
        _, _, _, dist = self.bvh.ray_cast(start, (0, dy, dz), self.limit)
        if dist is None:
            _, _, _, dist = self.bvh.ray_cast(start, (0, dy - 1e-5 * dz, dz + 1e-5 * dy), self.limit)
        if dist is None:
            return math.inf
        return r - dist

    def tuck(self, p, clearance):
        """Pull an existing deck, frame or waveguide vertex inside along its section ray."""
        d = self.overrun(*p) + clearance
        if d <= 0:
            return p
        y, z = p.y - self.y0, p.z - self.z0
        r = math.hypot(y, z)
        if not math.isfinite(d) or d > r:
            raise ValueError(f'no interior clearance at {tuple(p)}')
        f = 1 - d / r
        return Vector((p.x, self.y0 + y * f, self.z0 + z * f))


def check(objects, skins, scale=1.0):
    """Report every failing evaluated vertex, including deck solidify and dressing."""
    import bpy
    deps = bpy.context.evaluated_depsgraph_get()
    failures = vertices = count = 0
    for ob in sorted(objects, key=lambda o: o.name):
        if ob.type != 'MESH':
            continue
        count += 1
        ev = ob.evaluated_get(deps)
        me = ev.to_mesh()
        try:
            vertices += len(me.vertices)
            bad = False
            for v in me.vertices:
                p = ev.matrix_world @ v.co / scale
                d = min(s.overrun(*p) for s in skins)
                if d > 1e-5:   # mesh/ray float roundoff, in design units
                    bad = True
                    print(f'  {ob.name}[{v.index}] ({p.x:.5f}, {p.y:.5f}, {p.z:.5f}) past inner skin by {d:.5f}')
            failures += bad
        finally:
            ev.to_mesh_clear()
    return failures, count, vertices


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


def main():
    import bpy
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    sc = bpy.context.scene
    code = args[0] if args else sc.get('r209_sheet')
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
    objects = [ob for ob in sc.objects if ob.name.startswith('in_') or ob.get('inside') or ob.get('role') == 'interior']
    bad, count, vertices = check(objects, skins, scale)
    print(f'{"PASS" if count and not bad else "FAIL"} room skin {code}: '
          f'{bad} of {count} inside parts past the inner skin ({vertices} vertices checked)', flush=True)
    return 0 if count and not bad else 1


if __name__ == '__main__':
    sys.dont_write_bytecode = True
    sys.exit(main())
