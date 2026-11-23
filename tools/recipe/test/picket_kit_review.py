"""Cloud CPU review for issue 1888.

blender -b --python-exit-code 1 -P tools/recipe/test/picket_kit_review.py -- OUTPUT_DIR
With the cloud bpy wheel, run python tools/recipe/test/picket_kit_review.py OUTPUT_DIR.
"""

import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory

import bpy
from mathutils import Vector
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
    spans = dict(drive=(astra.STATIONS[0][0], astra.SEAMS[0]), mission=astra.SEAMS,
                 fore=(astra.SEAMS[1], 2.94), casemate=(2.94, astra.STATIONS[-1][0]))
    prefixes = ('belly_spine_', 'sole_runner_') + tuple(
        f'{label}_{piece}_' for label in spans for piece in ('panels', 'race', 'light'))
    shells = {f'shell_{label}' for label in spans}
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
    plate_regions = 0
    for label, (start, end) in spans.items():
        pressure = loft_module(kit, f'shell_{label}', profile, 'hgrey2', thickness=astra.SHELL,
                               start=start, end=end, cap=label != 'casemate')
        assert pressure.name == f'shell_{label}'
        xs = [ring[0][0] for ring in profile.rings(start, end)]
        grid = [start]
        for a, b in zip(xs, xs[1:]):
            count = max(1, round((b - a) / .32))
            grid.extend(a + (b - a) * i / count for i in range(1, count))
            grid.append(b)
        plates = plate_region(kit, f'{label}_cut_plates', [profile.ring(x) for x in grid],
                              (0, 1, 3, 4, 5, 6, 7, 9), 'hgrey', pitch=.29,
                              gap=.022, depth=.027, seat=.009, bevel=.006)
        plate_regions += plates is not None
        stripe_xs = [start + .014, *(x for x in xs if start + .014 < x < end - .014), end - .014]
        for side in (-1, 1):
            def sample(x):
                beam = profile.ring(x)[2][1]
                return (x, side * (beam + .003), -.028), (0, side, 0)

            broken_stripe(kit, f'{label}_{side}', stripe_xs, [(-.10, .14)], sample, clearance=.05,
                          race=(.081, .008, 'htrim'), stripe=(.023, .004, 'hblue'))
    assert plate_regions > 0, 'every plate region was reserved for fittings'


def build(use_shared):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    ship = json.loads((SOURCE / (astra.CODE + '.json')).read_text(encoding='utf-8'))
    kit = variants.build(astra, ship['game_ship'])
    if use_shared:
        rebuild_with_shared_methods(kit)
    bpy.context.view_layer.update()
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
    return scene, record


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
    output = Path(args[0]).resolve()
    output.mkdir(parents=True, exist_ok=True)
    before, base = build(False)
    render(before, output, 'before')
    after, shared = build(True)
    for field in ('length_world', 't_lines', 'turrets', 'muzzles', 'engines', 'points', 'interior_objects'):
        assert base[field] == shared[field], field
    render(after, output, 'after')
