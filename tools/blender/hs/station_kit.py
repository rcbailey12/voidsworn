"""Issue 61 station blockouts. Blender 4.5, X spine, Y lateral, Z up.

Run through tools/pc/jobs/station_blockout.bat. Output is review material only.
The owner must approve the turntables before detailing or swapping the live prop.
One shared spine supplies fleet and refinery variants; dimensions are world units.
"""
import argparse
import json
import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, os.path.dirname(__file__))
import hs_lib as hs

PARTS = []
GUNS = []
MATS = {}


def material(name, color, metal=0.45, emission=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bs = m.node_tree.nodes['Principled BSDF']
    bs.inputs['Base Color'].default_value = (*color, 1)
    bs.inputs['Metallic'].default_value = metal
    bs.inputs['Roughness'].default_value = 0.58
    if emission:
        bs.inputs['Emission Color'].default_value = (*color, 1)
        bs.inputs['Emission Strength'].default_value = emission
    return m


def part(o, mat='structure', group='static'):
    o.data.materials.append(MATS[mat])
    o['kit_group'] = group
    PARTS.append(o)
    return o


def box(name, center, size, mat='structure', group='static'):
    return part(hs.box(name, center, size, bevel=0.08), mat, group)


def cyl(name, center, radius, length, mat='structure', axis='Z', group='static'):
    return part(hs.cyl(name, center, radius, length, axis=axis, bevel=0.08), mat, group)


def beam(name, start, end, width=1.2, mat='structure'):
    a, b = Vector(start), Vector(end)
    o = box(name, (0, 0, 0), (width, width, (b - a).length), mat)
    o.location = (a + b) * 0.5
    o.rotation_euler = (b - a).to_track_quat('Z', 'Y').to_euler()
    return o


def antenna_array(name, x, y, base):
    # Broad flat sensor panels on paired posts, rather than a naval crossbar mast.
    box(name + '_foot', (x, y, base + 0.4), (4, 3, 1), 'armor')
    for side in (-1, 1):
        box(name + '_post_%s' % side, (x + side * 1.4, y, base + 1.7), (1, 1.2, 2.8))
        box(name + '_panel_%s' % side, (x + side * 1.4, y, base + 3.2), (2.2, 1.4, 3), 'armor')


def service_truss(name, half_length, y, base, top):
    # Open bays over four units high. Both feet overlap real end-cap mounts.
    for side in (-1, 1):
        x = side * half_length
        box(name + '_foot_%s' % side, (x, y, base), (3, 2.4, 2), 'armor')
        beam(name + '_upright_%s' % side, (x, y, base), (x, y, top))
        beam(name + '_brace_%s' % side, (x, y, base), (side * 6, y, top))
    beam(name + '_header', (-half_length, y, top), (half_length, y, top), 1.4, 'armor')


def spine():
    # The five modules touch at their bulkheads. Blunt ends never suggest a bow.
    for i, x in enumerate((-18.4, -9.2, 0, 9.2, 18.4)):
        box('spine_%02d' % i, (x, -4, 0), (8.8 if abs(x) > 18 else 9.2, 6, 4))
    for x in (-13.8, -4.6, 4.6, 13.8):
        box('bulkhead_coupler_%s' % x, (x, -4, 0), (1, 6.4, 4.4), 'armor')
    for x in (-21, 21):
        box('end_cap_%s' % x, (x, -4, 0), (4, 8, 5), 'armor')
    for x in (-13, 13):
        for side in (-1, 1):
            # Arms sit on the flank, with mounting collars, not floating pods.
            box('arm_%s_%s' % (x, side), (x, -4 + side * 5, -0.8), (3, 6, 2.4))
            box('arm_collar_%s_%s' % (x, side), (x, -4 + side * 3, -0.8), (4, 2, 3), 'armor')


def fleet():
    spine()
    # 36 clear units along the cradle; 12 across. Sparse underside ties leave
    # the entire working face open above, so the real Battleship can be seen.
    for x in (-19.5, 19.5):
        box('cradle_end_%s' % x, (x, 5, -1.3), (3, 18, 2.2))
    box('cradle_outer_rail', (0, 13, -1.5), (41.6, 1.8, 2))
    for x in (-13, 13):
        box('cradle_under_tie_%s' % x, (x, 5, -2.8), (2, 18, 1))
        # Two service-side Frigate slots, 12 clear along X, 6 deep.
        box('frigate_berth_back_%s' % x, (x, -13, -0.7), (16.4, 2, 2.6))
        for s in (-1, 1):
            box('frigate_jaw_%s_%s' % (x, s), (x + s * 7, -10, -0.8), (2, 6, 2.4))
    # Four symmetric twin batteries. Their barrels default to +X, the game
    # forward direction. Rings and cowlings remain separate from the static hull.
    for x in (-11.5, 11.5):
        for s in (-1, 1):
            group = 'battery_%s_%s' % (x, s)
            cyl(group + '_barbette', (x, -4, s * 2.2), 2, 0.6, 'armor')
            cyl(group + '_pivot', (x, -4, s * 2.9), 1.6, 0.8, group=group)
            box(group + '_cowling', (x, -4, s * 3.4), (3, 3, 1.2), 'accent', group)
            for lateral in (-0.65, 0.65):
                cyl(group + '_barrel_%s' % lateral, (x + 2, -4 + lateral, s * 3.4),
                    0.3, 2.5, 'armor', axis='X', group=group)
                GUNS.append((group, Vector((1, 0, 0))))
    # R91 shape pass only: a high service skyline leaves the working cradle clear.
    # Keep every tower and fin behind the battery lanes at Y=-4 +/- 0.65.
    box('control_tower_mount', (0, -6.6, 2.4), (6, 4, 1), 'armor')
    box('control_tower', (0, -6.6, 6.4), (4.8, 3.4, 7.2))
    box('control_tower_crown', (0, -6.6, 10.4), (6.8, 4, 2), 'armor')
    antenna_array('control_sensors', 0, -6.6, 11.4)
    box('secondary_tower_mount', (-18, -5, 2.5), (5, 4.8, 1), 'armor')
    box('secondary_sensor_tower', (-18, -5, 5.4), (3.8, 3.4, 5.2))
    antenna_array('secondary_sensors', -18, -5, 8)
    service_truss('fleet_service_frame', 18, -7.5, 1, 8.5)
    for side in (-1, 1):
        x = side * 6
        box('radiator_saddle_%s' % side, (x, -6, 2.2), (3, 4, 1), 'armor')
        box('radiator_fin_%s' % side, (x, -8, 5.2), (1.4, 6, 5.6), 'armor')


def refinery():
    spine()
    # Intake, single cracking tower, output: four-unit gaps between masses.
    for x, label in ((-16, 'intake'), (16, 'output')):
        box(label + '_saddle', (x, 2, -0.7), (8, 11.6, 2.6))
        cyl(label + '_drum', (x, 5, 1.8), 3, 6, 'armor', axis='Y')
    box('tower_saddle', (0, 1.5, -0.8), (7, 11, 2.4))
    cyl('cracking_tower', (0, 4, 6.6), 3, 12.4, 'armor')
    cyl('tower_top_band', (0, 4, 12.6), 3.1, 0.8, 'accent')
    # Pipe bridges physically meet the drum/tower surfaces.
    for x in (-8, 8):
        cyl('process_bridge_%s' % x, (x, 4, 2), 0.55, 16, axis='X')
    for x in (-13, 13):
        box('tank_mount_%s' % x, (x, -11, -0.7), (5, 8, 2.6))
        cyl('service_tank_%s' % x, (x, -12, 1.2), 2, 4, 'armor')
    # A taller single processing tower, with its sensors on the same structure.
    # The truss is a low open service frame, not a second tower or a ship bow.
    antenna_array('process_sensors', 0, 4, 13)
    service_truss('refinery_service_frame', 18, -7.5, 1, 9.5)
    for side in (-1, 1):
        x = side * 13
        box('heat_fin_saddle_%s' % side, (x, -6, 2.2), (4, 4, 1), 'armor')
        box('heat_radiator_%s' % side, (x, -8, 6.2), (2, 6, 7.6), 'armor')


def audit():
    """BVH contact graph, gun directions, finite bounds and GLB round trip."""
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    trees, bounds = {}, {}
    for o in PARTS:
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        vs = [o.matrix_world @ v.co for v in me.vertices]
        trees[o] = BVHTree.FromPolygons(vs, [tuple(p.vertices) for p in me.polygons])
        bounds[o] = ([min(v[i] for v in vs) for i in range(3)],
                     [max(v[i] for v in vs) for i in range(3)])
        ev.to_mesh_clear()
    connected = {PARTS[0]}
    edges = []
    for i, a in enumerate(PARTS):
        for b in PARTS[i + 1:]:
            al, ah = bounds[a]
            bl, bh = bounds[b]
            if any(al[k] > bh[k] + 0.0015 or bl[k] > ah[k] + 0.0015 for k in range(3)):
                continue
            contact = trees[a].overlap(trees[b])
            if not contact:
                contact = any((lambda hit: hit[0] is not None and hit[3] <= 0.0015)(
                    trees[b].find_nearest(a.matrix_world @ v.co)) for v in a.data.vertices)
            if contact:
                edges.append((a, b))
    for _ in PARTS:
        for a, b in edges:
            if a in connected or b in connected:
                connected.update((a, b))
    floating = [o.name for o in PARTS if o not in connected]
    assert not floating, 'Disconnected parts: ' + ', '.join(floating)
    assert all(d.x >= 0 and d.length > 0 for _, d in GUNS), 'Backward gun'
    # The taller skyline must not obstruct the existing forward battery lanes.
    for barrel in [o for o in PARTS if '_barrel_' in o.name]:
        bl, bh = bounds[barrel]
        muzzle = Vector((bh[0] + 0.01, (bl[1] + bh[1]) / 2, (bl[2] + bh[2]) / 2))
        for o in PARTS:
            if o['kit_group'] == 'static':
                assert trees[o].ray_cast(muzzle, Vector((1, 0, 0)))[0] is None, ('Blocked gun', barrel.name, o.name)
    lo = [min(bounds[o][0][i] for o in PARTS) for i in range(3)]
    hi = [max(bounds[o][1][i] for o in PARTS) for i in range(3)]
    assert abs(hi[0] - lo[0] - 46) < 0.01, (lo, hi)
    assert hi[2] >= 15, 'R91 skyline must rise above the flat blockout'
    assert all(math.isfinite(v) for v in lo + hi)
    return {'parts': len(PARTS), 'contact_edges': len(edges), 'guns': len(GUNS),
            'bounds': [lo, hi], 'attachment_audit': 'PASS', 'gun_clearance': 'PASS'}


def merge_export(path):
    # Static geometry is one mesh with material slots; the four turret nodes
    # retain their origins at the rings for the later Godot traverse hook.
    groups = {}
    for o in PARTS:
        groups.setdefault(o['kit_group'], []).append(o)
    merged = []
    for group, objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
            for mod in list(o.modifiers):
                bpy.ops.object.modifier_apply(modifier=mod.name)
        if group == 'static':
            # Remove internal and coincident faces at the modular joins. Joining
            # objects alone leaves black seams, especially on the underside.
            slots = list(MATS.values())
            for o in objects:
                original = list(o.data.materials)
                indices = [slots.index(original[p.material_index]) for p in o.data.polygons]
                o.data.materials.clear()
                for m in slots:
                    o.data.materials.append(m)
                for p, index in zip(o.data.polygons, indices):
                    p.material_index = index
            operands = bpy.data.collections.new('static_union_operands')
            bpy.context.scene.collection.children.link(operands)
            for o in objects[1:]:
                operands.objects.link(o)
            bpy.context.view_layer.objects.active = objects[0]
            union = objects[0].modifiers.new('sealed_static_joins', 'BOOLEAN')
            union.operation = 'UNION'
            union.operand_type = 'COLLECTION'
            union.collection = operands
            union.solver = 'EXACT'
            bpy.ops.object.modifier_apply(modifier=union.name)
            assert len(objects[0].data.polygons) > 0, 'Empty static union'
            for o in objects[1:]:
                bpy.data.objects.remove(o, do_unlink=True)
            bpy.data.collections.remove(operands)
            objects = objects[:1]
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1:
            bpy.ops.object.join()
        o = bpy.context.object
        o.name = group
        if group != 'static':
            bpy.context.scene.cursor.location = (o.location.x, -4, o.location.z)
            bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        merged.append(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in merged:
        o.select_set(True)
    want = sum(len(p.vertices) - 2 for o in merged for p in o.data.polygons)
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True)
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    imported = set(bpy.context.scene.objects) - before
    got = sum(len(p.vertices) - 2 for o in imported if o.type == 'MESH' for p in o.data.polygons)
    assert got == want, ('GLB triangle mismatch', want, got)
    assert all(math.isfinite(c) for o in imported if o.type == 'MESH' for v in o.data.vertices for c in v.co)
    for o in imported:
        bpy.data.objects.remove(o, do_unlink=True)
    return want


def ship(path, length, center):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    objects = set(bpy.context.scene.objects) - before
    meshes = [o for o in objects if o.type == 'MESH']
    bpy.context.view_layer.update()
    verts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    lo = Vector(tuple(min(v[i] for v in verts) for i in range(3)))
    hi = Vector(tuple(max(v[i] for v in verts) for i in range(3)))
    scale = length / (hi.x - lo.x)
    # GLB imports Y-up game assets into Blender Z-up, so use world bounds.
    parent = bpy.data.objects.new('scale_reference_' + path.stem, None)
    bpy.context.scene.collection.objects.link(parent)
    for o in objects:
        if o.parent not in objects:
            o.parent = parent
    parent.scale = Vector((scale,) * 3)
    parent.location = Vector(center) - (lo + hi) * 0.5 * scale
    return {'code': path.stem, 'length': length, 'width': (hi.y - lo.y) * scale,
            'height': (hi.z - lo.z) * scale}


def studio(out, variant, ship_root, underside_only=False):
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 16
    sc.cycles.use_denoising = True
    # Lane A owns the GPU for this render job. Do not fall back to CPU silently.
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type = 'OPTIX'
    prefs.get_devices()
    devices = [d for d in prefs.devices if d.type == 'OPTIX']
    assert devices, 'Lane A station renders require an OptiX GPU'
    for device in prefs.devices:
        device.use = device in devices
    sc.cycles.device = 'GPU'
    sc.render.resolution_percentage = 100
    sc.world = bpy.data.worlds.new('studio')
    sc.world.use_nodes = True
    sc.world.node_tree.nodes['Background'].inputs[0].default_value = (0.025, 0.035, 0.055, 1)
    sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.5
    for energy, angle in ((3, (35, -20, -35)), (1.5, (75, 0, 140))):
        light = bpy.data.objects.new('studio_light', bpy.data.lights.new('studio_light', 'SUN'))
        light.data.energy = energy
        light.rotation_euler = [math.radians(v) for v in angle]
        sc.collection.objects.link(light)
    underfill = bpy.data.objects.new('underside_review_fill', bpy.data.lights.new('underside_review_fill', 'SUN'))
    underfill.data.energy = 2
    underfill.rotation_euler = [math.radians(v) for v in (145, -20, 30)]
    sc.collection.objects.link(underfill)
    cam = bpy.data.objects.new('camera', bpy.data.cameras.new('camera'))
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = 65

    def render(name, az, el, width=1600, height=1000):
        # Inspection light for the underside cells only, not a change to paint.
        underfill.hide_render = '_below' not in name
        a, e = math.radians(az), math.radians(el)
        target = Vector((0, 0, 2))
        cam.location = target + Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))) * 100
        cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
        sc.render.resolution_x, sc.render.resolution_y = width, height
        sc.render.filepath = str(out / name)
        bpy.ops.render.render(write_still=True)

    for name, az, el in (('working', 205, 38), ('service', 25, 30), ('top', 0, 90),
                         ('side', 0, 0), ('below', 0, -45), ('end', 90, 0)):
        if underside_only and name != 'below':
            continue
        render(variant + '_' + name + '.png', az, el)
    if underside_only:
        return []
    frames = out / (variant + '_turntable')
    frames.mkdir(exist_ok=True)
    for i in range(24):
        render(variant + '_turntable/%03d.png' % i, i * 15, 30, 960, 600)
    refs = []
    for code, length, center in (('H10_23', 33.6, (0, 6, 1.5) if variant == 'fleet' else (0, 20, 2)),
                                  ('H7_23', 10.4, (-13, -10 if variant == 'fleet' else -19, 2))):
        p = ship_root / code / (code + '.glb')
        if not p.is_file():
            raise FileNotFoundError('Required real ship reference: ' + str(p))
        refs.append(ship(p, length, center))
    cam.data.ortho_scale = 80
    render(variant + '_ships_4k.png', 205, 48, 3840, 2160)
    # Both cluster sizes are captured by station_preview.gd with the actual
    # perspective battle camera, rather than an orthographic studio substitute.
    return refs


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ships', type=Path, required=True)
    parser.add_argument('--underside-only', action='store_true', help='Relight saved blockouts for underside inspection')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    args.out.mkdir(parents=True, exist_ok=True)
    if args.underside_only:
        for name in ('fleet', 'refinery'):
            bpy.ops.wm.open_mainfile(filepath=str(args.out / (name + '_blockout.blend')))
            studio(args.out, name, args.ships, underside_only=True)
        return
    report = {'phase': 'R91 height and silhouette blockout, awaiting owner review', 'variants': {}}
    for name, build in (('fleet', fleet), ('refinery', refinery)):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        PARTS.clear()
        GUNS.clear()
        hs.PARTS.clear()
        MATS.clear()
        MATS.update(structure=material('neutral_structure', (0.16, 0.19, 0.23)),
                    armor=material('neutral_armor', (0.29, 0.32, 0.36)),
                    accent=material('faction_cowling', (0.44, 0.16, 0.06)))
        build()
        result = audit()
        result['triangles_roundtrip'] = merge_export(args.out / (name + '_blockout.glb'))
        bpy.ops.wm.save_as_mainfile(filepath=str(args.out / (name + '_blockout.blend')))
        result['real_ship_references'] = studio(args.out, name, args.ships)
        report['variants'][name] = result
        (args.out / 'blockout_audit.json').write_text(json.dumps(report, indent=2) + '\n')
        print('[station-kit]', name, json.dumps(result))


if __name__ == '__main__':
    main()
