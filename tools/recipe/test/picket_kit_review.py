"""CPU Blender review for issue 1888.

blender -b --python-exit-code 1 -P tools/recipe/test/picket_kit_review.py -- OUTPUT_DIR
With the cloud bpy wheel, run python tools/recipe/test/picket_kit_review.py OUTPUT_DIR.
Use --selftest in place of OUTPUT_DIR to run the geometry checks without rendering.
"""

import json
from math import ceil
from pathlib import Path
import sys
from tempfile import TemporaryDirectory

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'contrib/codex/picket_astra_1122'
for folder in (ROOT / 'tools', ROOT / 'tools/blender/build_sheets', ROOT / 'tools/recipe', SOURCE):
    sys.path.insert(0, str(folder))

import contract
import hegemony_H7A as astra
import variants
from hull_methods import (FlatSoleLoft, belly_cover, broken_stripe, loft_module,
                          mount_service_part, plate_region, slatted_cassette)
from picture_provenance import stamp_file

SPANS = dict(drive=(astra.STATIONS[0][0], astra.SEAMS[0]), mission=astra.SEAMS,
             fore=(astra.SEAMS[1], 2.94), casemate=(2.94, astra.STATIONS[-1][0]))
FACETS = {0: 'deck', 1: 'port shoulder', 3: 'port lower facet', 4: 'port chine',
          5: 'sole', 6: 'starboard chine', 7: 'starboard lower facet', 9: 'starboard shoulder'}
PANEL_PREFIXES = tuple(f'{label}_panels_' for label in SPANS)


def picket_plate_land(p, radius):
    # H7A leaves land under its central belly trunk, receiver and dorsal barbette.
    return (p.z < -.31 and abs(p.y) < .18 and -2.6 < p.x < 2.45
            or p.z > .14 and abs(p.y) < .10 + radius and abs(p.x - 1.10) < .22 + radius
            or p.z > .14 and abs(p.y) < .31 and abs(p.x + .81) < .44)


def fit_service_parts(kit, profile):
    sole = profile.sole
    for i, side in enumerate((-1, 1)):
        for j, x in enumerate((-2.22, -1.17, .02, 1.10, 2.12)):
            cassette = slatted_cassette(length=.32, width=.19, depth=.055, rim=.026,
                                        seat=.014, slats=5, slat_width=.024,
                                        materials=('dark', 'htrim', 'hgrey'))
            y = side * profile.ring(x)[2][1] * .49
            mount_service_part(kit, f'cooler{i}_{j}', cassette, kind='vent',
                               pos=(x, y, sole - .002), normal=(0, 0, -1), note='belly cooler cassette')
    for i, (a, b) in enumerate(((-2.65, -1.80), (-1.72, -.61), (-.57, .53), (.57, 1.53), (1.61, 2.48))):
        cover = belly_cover(length=b - a, width=.23, depth=.036, rim=.022, seat=.014, gap=.006,
                            materials=('htrim', 'hmetal'))
        mount_service_part(kit, f'belly_spine_{i}', cover, kind='cover',
                           pos=((a + b) / 2, 0, sole), normal=(0, 0, -1), note='removable belly cover')


def rebuild_with_shared_methods(kit):
    # Replace only the pieces exercised by this proof. The original sheet builds
    # the gun face, module bands, machinery, insides and all hard points.
    prefixes = ('belly_spine_', 'sole_runner_') + tuple(
        f'{label}_{piece}_' for label in SPANS for piece in ('panels', 'race', 'light'))
    shells = {f'shell_{label}' for label in SPANS}
    for obj in list(kit.coll.objects):
        if obj.name in shells or obj.name.startswith(prefixes) or obj.get('grp', '').startswith('cooler'):
            bpy.data.objects.remove(obj, do_unlink=True)
    old_coolers = {tuple(row['pos']) for row in kit.features if row['id'].startswith('cooler')}
    kit.keepouts[:] = [(p, r) for p, r in kit.keepouts if tuple(p) not in old_coolers]
    for rows in (kit.features, kit.built, kit.fitdata):
        rows[:] = [row for row in rows if not row['id'].startswith('cooler')]

    profile = FlatSoleLoft(astra.STATIONS, sole=astra.SOLE, flank=(-.09, .036),
                           chine_height=.055, widths=(.83, .87, .77))
    fit_service_parts(kit, profile)
    for label, (start, end) in SPANS.items():
        pressure = loft_module(kit, f'shell_{label}', profile, 'hgrey2', thickness=astra.SHELL,
                               start=start, end=end, cap=label != 'casemate')
        assert pressure.name == f'shell_{label}'
        xs = [ring[0][0] for ring in profile.rings(start, end)]
        grid = [start]
        for a, b in zip(xs, xs[1:]):
            count = max(1, round((b - a) / .32))
            grid.extend(a + (b - a) * i / count for i in range(1, count + 1))
        plate_region(kit, f'{label}_panels', [profile.ring(x) for x in grid], FACETS,
                     pv=.29, gap=.009, unit=.31, t_big=.015, t_small=.011, keep=picket_plate_land)
        stripe_xs = [start + .014, *(x for x in xs if start + .014 < x < end - .014), end - .014]
        for side in (-1, 1):
            def sample(x):
                beam = profile.ring(x)[2][1]
                return (x, side * (beam + .003), -.028), (0, side, 0)

            broken_stripe(kit, f'{label}_{side}', stripe_xs, [(-.10, .14)], sample, clearance=.05,
                          race=(.081, .008, 'htrim'), stripe=(.023, .004, 'hblue'))


def facet_coverage(kit):
    """Share of each Astra facet with plate geometry above its pressure skin."""
    vertices, faces = [], []
    for obj in kit.coll.objects:
        if obj.name.startswith(PANEL_PREFIXES):
            offset = len(vertices)
            vertices.extend(obj.matrix_world @ vertex.co for vertex in obj.data.vertices)
            faces.extend(tuple(offset + i for i in face.vertices) for face in obj.data.polygons)
    if not faces:
        raise AssertionError('Picket has no plate geometry')
    surface = BVHTree.FromPolygons(vertices, faces)
    coverage = {}
    for facet, name in FACETS.items():
        area = plated = 0.0
        for start, end in SPANS.values():
            xs = [start, *(x for x, _, _ in astra.STATIONS if start < x < end), end]
            rings = [list(map(Vector, astra.ring(x))) for x in xs]
            for first, second in zip(rings, rings[1:]):
                edge = (facet + 1) % len(first)
                a, b, c, d = first[facet], first[edge], second[edge], second[facet]
                normal = (d - a).cross(b - a).normalized()
                strip_area = ((d - a).cross(b - a).length + (b - c).cross(d - c).length) / 2
                # Sample the plate footprint on the reference hull, including the narrow gaps.
                rows = ceil(max((d - a).length, (c - b).length) / .008)
                cols = ceil(max((b - a).length, (c - d).length) / .008)
                hits = 0
                for i in range(rows):
                    u = (i + .5) / rows
                    left, right = a.lerp(d, u), b.lerp(c, u)
                    for j in range(cols):
                        point = left.lerp(right, (j + .5) / cols)
                        hit, _, _, _ = surface.ray_cast(point + normal * .08, -normal, .08)
                        hits += hit is not None
                area += strip_area
                plated += strip_area * hits / (rows * cols)
        coverage[name] = plated / area
    return coverage


def check_coverage(before, after):
    errors = []
    for name, original in before.items():
        rebuilt = after[name]
        assert original > 0, f'Astra reference has no coverage on {name}'
        change = abs(rebuilt - original) / original
        print(f'Plate coverage {name}: {original:.2%} -> {rebuilt:.2%} ({change:.2%} relative change)', flush=True)
        if change > .05:
            errors.append(name)
    assert not errors, f'Plate coverage exceeds the 5% tolerance on {", ".join(errors)}'


def build(use_shared):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    ship = json.loads((SOURCE / (astra.CODE + '.json')).read_text(encoding='utf-8'))
    kit = variants.build(astra, ship['game_ship'])
    if use_shared:
        rebuild_with_shared_methods(kit)
    bpy.context.view_layer.update()
    coverage = facet_coverage(kit)
    record = contract.to_recipe(kit, ship)
    scene = bpy.context.scene
    depsgraph = bpy.context.evaluated_depsgraph_get()
    triangles = 0
    for obj in scene.objects:
        if obj.type == 'MESH':
            mesh = obj.evaluated_get(depsgraph).data
            mesh.calc_loop_triangles()
            triangles += len(mesh.loop_triangles)
            obj.hide_render = obj.get('role') == 'interior'
    print(f'{"after" if use_shared else "before"}: {triangles} pre-bake triangles; {record}', flush=True)
    return scene, record, coverage


def render(scene, directory, label):
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 16
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 600
    scene.render.resolution_y = 460
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.world = bpy.data.worlds.new('Review studio')
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes['Background']
    background.inputs['Color'].default_value = (.28, .32, .39, 1)
    background.inputs['Strength'].default_value = .55
    for name, ray, power in (('Key', (-.5, -.8, -.7), 3), ('Belly fill', (.4, -.7, .55), 2.2)):
        light = bpy.data.lights.new(name, 'SUN')
        light.energy = power
        obj = bpy.data.objects.new(name, light)
        scene.collection.objects.link(obj)
        obj.rotation_euler = Vector(ray).to_track_quat('-Z', 'Y').to_euler()
    lens = bpy.data.cameras.new('Review camera')
    lens.type, lens.ortho_scale = 'ORTHO', 1.16
    camera = bpy.data.objects.new('Review camera', lens)
    scene.collection.objects.link(camera)
    scene.camera = camera
    sheet = Image.new('RGB', (1200, 460))
    with TemporaryDirectory(prefix='picket-kit-review-') as scratch:
        for i, direction in enumerate(((.85, 2, 1.45), (.15, 1.45, -2))):
            camera.location = Vector(direction)
            camera.rotation_euler = (-camera.location).to_track_quat('-Z', 'Y').to_euler()
            scene.render.filepath = str(Path(scratch) / f'view_{i}.png')
            bpy.ops.render.render(write_still=True)
            with Image.open(scene.render.filepath) as view:
                sheet.paste(view, (600 * i, 0))
    path = directory / f'{astra.CODE}_{label}_Blender_review.png'
    sheet.save(path)
    stamp_file(path, 'cloud direction check', repo=ROOT, new_render=True)


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    if len(args) != 1:
        raise SystemExit(__doc__)
    output = None if args == ['--selftest'] else Path(args[0]).resolve()
    before, base, base_coverage = build(False)
    if output is not None:
        output.mkdir(parents=True, exist_ok=True)
        render(before, output, 'before')
    after, shared, shared_coverage = build(True)
    for field in ('length_world', 't_lines', 'turrets', 'muzzles', 'engines', 'points', 'interior_objects'):
        assert base[field] == shared[field], field
    check_coverage(base_coverage, shared_coverage)
    if output is not None:
        render(after, output, 'after')
