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


# R100 detail builders. The R94 builders and their audit above stay unchanged.
# Use --detail for the review build; the old blockout command still works.
def process_pipe(name, start, end):
    a, b = Vector(start), Vector(end)
    o = part(hs.cyl(name, (0, 0, 0), .5, (b-a).length, seg=12, bevel=.04))
    o.location = (a+b)/2
    o.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    return o


def equipment_housing(name, x, y, base, top, width=3, depth=1.6):
    box(name, (x, y, (base + top) / 2), (width, depth, top - base), 'armor')
    # One-unit sensor heads are secondary read, never silhouette claims.
    cyl(name + '_sensor_base', (x, y, top + 0.5), 0.65, 1, 'accent')


def fleet_detail():
    for i, (x, top) in enumerate(((-12, 4.5), (-4, 5), (4, 4), (12, 6.5))):
        equipment_housing('dorsal_%d' % i, x, -5.9, 2, top)
    for y in (-2, -6):
        box('gantry_leg_%s' % y, (3.5, y, 5), (2, 1.4, 6))
    box('gantry_crossbeam', (3.5, -4, 8), (3, 5.4, 2), 'armor')
    # A sensor cross-arm, attached to the existing panels, on the service side.
    box('secondary_cross_arm', (-18, -8, 9.5), (2.4, 6, 2), 'armor')
    box('secondary_cross_head', (-18, -11, 10), (3, 2, 2), 'accent')
    box('extra_fin_mount', (-8, -6, 2.5), (4, 2, 1), 'armor')
    fin = box('extra_fin_blade', (-8.4, -8.5, 5.2), (1.4, 6, 5.6), 'armor')
    # hs primitives store their positions in vertices. Rotate about the mount.
    from mathutils import Matrix
    pivot = Vector((-8.4, -6, 2.4))
    rotation = Matrix.Rotation(math.radians(12), 3, 'Z')
    for v in fin.data.vertices: v.co = pivot + rotation @ (v.co - pivot)
    box('radiator_cowl_plus', (6, -6.4, 3.5), (4, 3, 2.6), 'armor')
    # The +14 service extension starts at the back rail and runs away from the
    # berth, leaving its twelve-unit opening and six-unit depth clear.
    box('service_dock_arm', (14, -17, -0.5), (2.4, 8, 2))
    box('service_dock_lip', (14, -21, 0), (2.4, 2, 2), 'accent')
    for x in (-15, 15):
        box('cradle_clamp_%s' % x, (x, 12.5, 0), (2, 2, 1), 'armor')
    for x in (-13, 13):
        # Frames rest on the back rails, not inside the six-unit berth depth.
        box('berth_lip_%s' % x, (x, -13, 1), (10, 2, 1), 'accent')


def refinery_detail():
    # Curved drum crowns support the caps through a broad saddle housing.
    box('intake_cap_saddle', (-16, 5, 5.1), (4, 4, 2), 'armor')
    box('intake_cap_lower', (-16, 5, 6.6), (4, 4, 2), 'armor')
    box('intake_cap_upper', (-16, 5, 8), (2.4, 3, 2), 'accent')
    box('output_flange', (16, 5, 5.8), (5, 5, 2.4), 'armor')
    box('process_column_mount', (7, -5.5, 2.5), (4, 3, 1), 'armor')
    cyl('secondary_process_column', (7, -5.5, 6.7), 1.5, 8.6, 'armor')
    # One-unit pipes are secondary lines, not silhouette additions.
    for name, a, b in (
            ('column_feed', (7, -5.5, 3), (0, 4, 3)),
            ('column_output', (7, -5.5, 3), (16, 5, 3)),
            ('raised_pipe', (0, 4, 8), (-16, 5, 8))):
        process_pipe(name, a, b)
    for x, top in ((-13, 6.2), (13, 5.2)):
        box('tank_cap_%s' % x, (x, -12, (3.2 + top) / 2), (3, 3, top - 3.2), 'armor')
    box('extra_heat_mount', (-15.5, -6, 2.5), (3, 2, 1), 'armor')
    box('extra_heat_blade', (-16, -8.5, 6.2), (1.4, 6, 7.6), 'armor')


def locked_snapshot():
    """Exact primitive coordinates, transforms and modifiers, before any bake."""
    import hashlib
    return {o.name: hashlib.sha256(repr((
        [tuple(v.co) for v in o.data.vertices],
        [tuple(p.vertices) for p in o.data.polygons],
        [tuple(row) for row in o.matrix_world],
        [(m.type, getattr(m, 'width', None), getattr(m, 'segments', None))
         for m in o.modifiers])).encode()).hexdigest() for o in PARTS}


def station_palette(faction):
    # Read the shipping ship paint, including its current v2 overrides.
    import importlib.util
    path = Path(__file__).parents[1] / 'a4' / 'bakemat4.py'
    spec = importlib.util.spec_from_file_location('station_ship_palette', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    palettes = {k: dict(v) for k, v in module.FAC.items()}
    # Section 6 explicitly pins these two station palettes in the approved brief.
    palettes['ithar'].update(hull='#eef3f1', trim='#d7c88a', win=hex_linear('#9fffd2'))
    palettes['corsair'].update(hull='#6a2c22', trim='#b8402a', win=hex_linear('#e0402c'))
    return palettes[faction], palettes


def hex_linear(value):
    rgb = [int(value[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4 for c in rgb)


def save_pixels(path, pixels, color=False):
    import numpy as np
    h, w = pixels.shape[:2]
    im = bpy.data.images.new(path.stem, width=w, height=h, alpha=True)
    im.colorspace_settings.name = 'sRGB' if color else 'Non-Color'
    if pixels.shape[2] == 3:
        pixels = np.concatenate((pixels, np.ones((h, w, 1), np.float32)), axis=2)
    im.pixels.foreach_set(np.ascontiguousarray(pixels, dtype=np.float32).ravel())
    im.filepath_raw = str(path); im.file_format = 'PNG'; im.save()
    return im


def shared_trim(out):
    """One 2048 sheet: plate, windows, guide, heat, hatch, lip, damage, frame.

    RGB contains height, light mask and trim mask. No small detail is geometry.
    A separately saved normal is derived from that very same height field.
    """
    import numpy as np
    path = out / 'station_trim_2048.png'
    if path.exists():
        images = [bpy.data.images.load(str(p)) for p in (path, out / 'station_trim_normal_2048.png')]
        for im in images: im.colorspace_settings.name = 'Non-Color'
        return tuple(images)
    y, x = np.mgrid[0:2048, 0:2048]
    band = y // 256; u = x % 192; v = y % 256
    seam = ((u < 3) | (v % 96 < 3)).astype(float)
    height = .5 - seam * .10
    light = np.zeros_like(height); trim = np.zeros_like(height)
    light[(band == 1) & (u > 25) & (u < 95) & (v % 64 > 24) & (v % 64 < 36)] = .65
    light[(band == 2) & (v > 100) & (v < 108)] = .8
    heat = band == 3
    height[heat] -= ((u[heat] % 24) < 4) * .08
    light[heat] = (v[heat] / 255) ** 5 * .08
    radius = np.sqrt(((x % 256) - 128) ** 2 + (v - 128) ** 2)
    height[(band == 4) & (abs(radius - 74) < 4)] -= .12
    trim[(band == 5) & ((x // 30 + y // 30) % 2 == 0)] = .7
    damage = band == 6
    height[damage] -= np.sin(x[damage] * .17 + y[damage] * .11) ** 2 * .12
    trim[(band == 6) & (v < 25)] = .9
    light[(band == 6) & (v < 9)] = .3
    trim[(band == 7) & (v % 64 < 8)] = .65
    source = save_pixels(path, np.stack((height, light, trim), axis=2))
    gy, gx = np.gradient(height)
    normal = np.stack((-gx * 3, -gy * 3, np.ones_like(height)), axis=2)
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    return source, save_pixels(out / 'station_trim_normal_2048.png', normal * .5 + .5)


def paint_station(out, name, faction, reuse_local=False):
    """Bake real per-element masks, assembly AO, then the three-slot PBR stack."""
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'; sc.cycles.samples = 8
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type = 'OPTIX'; prefs.get_devices()
    devices = [d for d in prefs.devices if d.type == 'OPTIX']
    assert devices, 'Station paint requires the PC OptiX GPU'
    for d in prefs.devices: d.use = d in devices
    sc.cycles.device = 'GPU'
    palette, palettes = station_palette(faction)
    trim, normal = shared_trim(out)
    # Apply the existing bevels before curvature and UVs are baked. Coordinates
    # were already compared against the locked snapshot before this step.
    bpy.ops.object.select_all(action='DESELECT')
    for o in PARTS:
        o.select_set(True); bpy.context.view_layer.objects.active = o
        for mod in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=mod.name)
        o.select_set(False)
        o.data.uv_layers.new(name='surface')
        uv = o.data.uv_layers.new(name='trim')
        kind = (3 if ('fin' in o.name or 'radiator' in o.name) else
                2 if ('rail' in o.name or 'berth' in o.name) else
                1 if ('tower' in o.name or 'housing' in o.name or 'cap' in o.name or 'dorsal' in o.name) else
                4 if 'sensor_base' in o.name else 5 if ('clamp' in o.name or 'lip' in o.name) else 0)
        for p in o.data.polygons:
            axis = max(range(3), key=lambda a: abs(p.normal[a]))
            axes = [a for a in range(3) if a != axis]
            coords = [o.data.vertices[o.data.loops[i].vertex_index].co for i in p.loop_indices]
            low = min(c[axes[1]] for c in coords); high = max(c[axes[1]] for c in coords)
            for i, c in zip(p.loop_indices, coords):
                uv.data[i].uv = (c[axes[0]] / 1.5 * (192 / 2048),
                    (kind + .025 + .95 * (c[axes[1]] - low) / max(high - low, .001)) / 8)
        o.data.uv_layers.active_index = 0
    for o in PARTS: o.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=.003, area_weight=.35)
    bpy.ops.object.mode_set(mode='OBJECT')
    # Work-face wear weighting is a per-element attribute, baked into the mask.
    for o in PARTS:
        a = o.data.attributes.new('work_wear', 'FLOAT', 'POINT')
        strength = 1 if any(k in o.name for k in ('cradle', 'berth', 'cap', 'flange', 'lip')) else .25
        a.data.foreach_set('value', [strength] * len(o.data.vertices))
    from importlib.util import spec_from_file_location, module_from_spec
    spec = spec_from_file_location('station_paint_nodes', Path(__file__).parents[1] / 'hull_repair' / 'round4_material.py')
    graph = module_from_spec(spec); spec.loader.exec_module(graph)
    n, mathn, mix = graph.node, graph.mathnode, graph.mix
    outputs = {}
    for key, mat in MATS.items():
        nt = mat.node_tree; nt.nodes.clear()
        outnode = n(nt, 'ShaderNodeOutputMaterial')
        geo = n(nt, 'ShaderNodeNewGeometry')
        local = n(nt, 'ShaderNodeAmbientOcclusion', samples=8, only_local=True)
        local.inputs['Distance'].default_value = .7
        ao = n(nt, 'ShaderNodeAmbientOcclusion', samples=8, only_local=False)
        ao.inputs['Distance'].default_value = 3
        bevel = n(nt, 'ShaderNodeBevel', samples=3); bevel.inputs['Radius'].default_value = .035
        dot = n(nt, 'ShaderNodeVectorMath', operation='DOT_PRODUCT')
        nt.links.new(geo.outputs['Normal'], dot.inputs[0]); nt.links.new(bevel.outputs[0], dot.inputs[1])
        edge = mathn(nt, 'MINIMUM', mathn(nt, 'MULTIPLY', mathn(nt, 'SUBTRACT', 1, dot.outputs['Value']), 20), 1)
        work = n(nt, 'ShaderNodeAttribute', attribute_name='work_wear')
        wear = mathn(nt, 'MULTIPLY', edge, work.outputs['Fac'])
        masks = n(nt, 'ShaderNodeCombineColor', mode='RGB')
        for i, socket in enumerate((local.outputs['AO'], geo.outputs['Pointiness'], wear)):
            nt.links.new(socket, masks.inputs[i])
        outputs[key] = {'mat': mat, 'output': outnode, 'local_masks': masks.outputs[0], 'assembly_ao': ao.outputs['AO']}
    images = {}

    def bake(kind, normal_bake=False):
        im = bpy.data.images.new(name + '_' + kind, width=2048, height=2048, alpha=True)
        im.colorspace_settings.name = 'sRGB' if kind in ('base', 'emission') else 'Non-Color'
        for key, data in outputs.items():
            nt = data['mat'].node_tree
            target = n(nt, 'ShaderNodeTexImage'); target.image = im; nt.nodes.active = target
            if normal_bake: nt.links.new(data['bsdf'].outputs[0], data['output'].inputs[0])
            else:
                emit = n(nt, 'ShaderNodeEmission')
                nt.links.new(data[kind], emit.inputs[0]); nt.links.new(emit.outputs[0], data['output'].inputs[0])
        sc.render.bake.margin = 6; sc.render.bake.use_clear = False
        bpy.ops.object.bake(type='NORMAL' if normal_bake else 'EMIT', normal_space='TANGENT')
        im.filepath_raw = str(out / (name + '_' + kind + '.png')); im.file_format = 'PNG'; im.save()
        images[kind] = im
        print('[station-paint]', name, kind, flush=True)
    import hashlib
    stamp = hashlib.sha256(repr([(o.name, [tuple(row) for row in o.matrix_world], [tuple(v.co) for v in o.data.vertices],
        [tuple(v.uv) for v in o.data.uv_layers[0].data]) for o in PARTS]).encode()).hexdigest()
    stamp_path = out / (name + '_local_masks.sha256')
    if (reuse_local and (out / (name + '_local_masks.png')).exists()
            and stamp_path.exists() and stamp_path.read_text() == stamp):
        images['local_masks'] = bpy.data.images.load(str(out / (name + '_local_masks.png')))
        images['local_masks'].colorspace_settings.name = 'Non-Color'
    else:
        bake('local_masks')
        stamp_path.write_text(stamp)
    # Local masks above are baked per element. The assembly and final passes
    # share a temporary joined proxy, avoiding one GPU scene upload per part.
    # Original objects, groups and UVs are kept for the locked export path.
    bpy.ops.object.select_all(action='DESELECT')
    copies = []
    for o in PARTS:
        duplicate = o.copy(); duplicate.data = o.data.copy()
        bpy.context.scene.collection.objects.link(duplicate)
        duplicate.select_set(True); copies.append(duplicate)
        o.hide_render = True
    bpy.context.view_layer.objects.active = copies[0]; bpy.ops.object.join()
    proxy = bpy.context.object; proxy.name = 'station_bake_proxy'
    bake('assembly_ao')
    for key, data in outputs.items():
        nt = data['mat'].node_tree
        mask = n(nt, 'ShaderNodeTexImage'); mask.image = images['local_masks']
        split = n(nt, 'ShaderNodeSeparateColor'); nt.links.new(mask.outputs[0], split.inputs[0])
        ao = n(nt, 'ShaderNodeTexImage'); ao.image = images['assembly_ao']
        uv = n(nt, 'ShaderNodeUVMap', uv_map='trim')
        sheet = n(nt, 'ShaderNodeTexImage'); sheet.image = trim; nt.links.new(uv.outputs[0], sheet.inputs[0])
        strips = n(nt, 'ShaderNodeSeparateColor'); nt.links.new(sheet.outputs[0], strips.inputs[0])
        noise = n(nt, 'ShaderNodeTexNoise'); noise.inputs['Scale'].default_value = 3
        geo = n(nt, 'ShaderNodeNewGeometry'); nt.links.new(geo.outputs['Position'], noise.inputs[0])
        neutral = (.12, .145, .17, 1) if key == 'structure' else (*hex_linear(palette['hull']), 1)
        if key == 'accent': neutral = (*hex_linear(palette['trim']), 1)
        # Thin faction bands and cowlings over neutral structure, identical masks.
        base = mix(nt, neutral, (*hex_linear(palette['trim']), 1), mathn(nt, 'MULTIPLY', strips.outputs['Blue'], .55))
        seam = mathn(nt, 'LESS_THAN', strips.outputs['Red'], .46)
        base = mix(nt, base, (.025, .032, .040, 1), mathn(nt, 'MULTIPLY', seam, .62))
        # Broad plate tone changes, kept identical for every faction.
        tone = mathn(nt, 'ADD', .72, mathn(nt, 'MULTIPLY', noise.outputs['Fac'], .2))
        base = mix(nt, (.008, .010, .013, 1), base, tone)
        grime = mathn(nt, 'MULTIPLY', split.outputs['Red'], ao.outputs[0])
        base = mix(nt, (.008, .010, .013, 1), base, mathn(nt, 'ADD', .35, mathn(nt, 'MULTIPLY', grime, .65)))
        soot = mathn(nt, 'MULTIPLY', mathn(nt, 'GREATER_THAN', noise.outputs['Fac'], .68), .2)
        base = mix(nt, base, (.009, .008, .007, 1), soot)
        rust = mathn(nt, 'MULTIPLY', mathn(nt, 'SUBTRACT', 1, split.outputs['Red']), .2 if faction == 'corsair' else .035)
        base = mix(nt, base, (.15, .043, .015, 1), rust)
        curve = mathn(nt, 'ADD', .3, mathn(nt, 'MULTIPLY', split.outputs['Green'], .7))
        wear = mathn(nt, 'MULTIPLY', split.outputs['Blue'], curve)
        data['base'] = mix(nt, base, (.30, .33, .35, 1), mathn(nt, 'MULTIPLY', wear, .5))
        orm = n(nt, 'ShaderNodeCombineColor', mode='RGB')
        nt.links.new(ao.outputs[0], orm.inputs[0])
        nt.links.new(mathn(nt, 'SUBTRACT', .78, mathn(nt, 'MULTIPLY', wear, .2)), orm.inputs[1])
        nt.links.new(mathn(nt, 'ADD', .25, mathn(nt, 'MULTIPLY', wear, .45)), orm.inputs[2])
        data['orm'] = orm.outputs[0]
        data['emission'] = mix(nt, (0, 0, 0, 1), (*palette['win'], 1), strips.outputs['Green'])
        bs = n(nt, 'ShaderNodeBsdfPrincipled'); data['bsdf'] = bs
        nt.links.new(data['base'], bs.inputs['Base Color'])
        nmtex = n(nt, 'ShaderNodeTexImage'); nmtex.image = normal; nt.links.new(uv.outputs[0], nmtex.inputs[0])
        nm = n(nt, 'ShaderNodeNormalMap', uv_map='trim'); nt.links.new(nmtex.outputs[0], nm.inputs['Color'])
        nt.links.new(nm.outputs[0], bs.inputs['Normal'])
    for kind in ('base', 'orm', 'emission', 'normal'): bake(kind, kind == 'normal')
    # Runtime materials retain the three original slots, with no procedural
    # lighting or concept projection baked into albedo.
    for key, data in outputs.items():
        nt = data['mat'].node_tree; nt.nodes.clear()
        bs = n(nt, 'ShaderNodeBsdfPrincipled'); output = n(nt, 'ShaderNodeOutputMaterial')
        nt.links.new(bs.outputs[0], output.inputs[0])
        textures = {}
        for kind in ('base', 'orm', 'emission', 'normal'):
            tex = n(nt, 'ShaderNodeTexImage'); tex.image = images[kind]; textures[kind] = tex
        nt.links.new(textures['base'].outputs[0], bs.inputs['Base Color'])
        nt.links.new(textures['emission'].outputs[0], bs.inputs['Emission Color'])
        bs.inputs['Emission Strength'].default_value = .7
        split = n(nt, 'ShaderNodeSeparateColor'); nt.links.new(textures['orm'].outputs[0], split.inputs[0])
        nt.links.new(split.outputs['Green'], bs.inputs['Roughness']); nt.links.new(split.outputs['Blue'], bs.inputs['Metallic'])
        group = bpy.data.node_groups.get('glTF Material Output')
        if group is None:
            group = bpy.data.node_groups.new('glTF Material Output', 'ShaderNodeTree')
            group.interface.new_socket(name='Occlusion', in_out='INPUT', socket_type='NodeSocketFloat')
        gn = n(nt, 'ShaderNodeGroup'); gn.node_tree = group; nt.links.new(split.outputs['Red'], gn.inputs['Occlusion'])
        nm = n(nt, 'ShaderNodeNormalMap'); nt.links.new(textures['normal'].outputs[0], nm.inputs['Color'])
        nt.links.new(nm.outputs[0], bs.inputs['Normal'])
    bpy.data.objects.remove(proxy, do_unlink=True)
    for o in PARTS: o.hide_render = False; o.select_set(True)
    return {'faction': faction, 'palettes': palettes, 'resolution': 2048,
            'per_element_masks': [o.name for o in PARTS], 'station_wide_ao': True,
            'maps': {k: {'path': im.filepath_raw, 'bytes': Path(im.filepath_raw).stat().st_size} for k, im in images.items()},
            'shared_trim': ['station_trim_2048.png', 'station_trim_normal_2048.png'],
            'export_slots': list(MATS), 'ai_texturing': False, 'concept_projection': False}


def break_variants(out, name, faction):
    """Authored junction cuts, hollow liners and decks, exported separately.

    The intact R94 solids are never cut. Full interiors belong to wreck masters.
    Frame cuts use the R100 decal exemption rather than invented frame decks.
    """
    import bmesh
    import numpy as np
    palette, _ = station_palette(faction)
    # Damage extends the same baked masks. It does not add an export slot.
    masks = bpy.data.images.load(str(out / (name + '_local_masks.png')), check_existing=True)
    pixels = np.empty(2048 * 2048 * 4, np.float32); masks.pixels.foreach_get(pixels)
    pixels = pixels.reshape(2048, 2048, 4)
    y, x = np.mgrid[0:2048, 0:2048]
    ragged = np.sin(x * .041) * .016 + np.sin(x * .133) * .008
    v = y / 2048
    rim = (v < .07 + ragged).astype(np.float32)
    band = (v < .22 + ragged).astype(np.float32)
    damage = np.zeros((2048, 2048, 3), np.float32) + (.009, .011, .014)
    damage += band[:, :, None] * np.array((.055, .049, .042), np.float32)
    damage += rim[:, :, None] * np.array((.17, .12, .065), np.float32)
    damage *= .6 + .4 * pixels[:, :, :1]
    damage_image = save_pixels(out / (name + '_damage_base.png'), damage, True)
    hot = rim[:, :, None] * np.array(palette['win'], np.float32)[None, None, :] * .2
    damage_emission = save_pixels(out / (name + '_damage_emission.png'), hot, True)
    damage_orm = save_pixels(out / (name + '_damage_orm.png'), np.stack((
        pixels[:, :, 0], .9 - rim * .12, .12 + rim * .4), axis=2))
    height = pixels[:, :, 1] * .02 - band * .04 + rim * .08
    gy, gx = np.gradient(height)
    cap_normal = np.stack((-gx * 3, -gy * 3, np.ones_like(height)), axis=2)
    cap_normal /= np.linalg.norm(cap_normal, axis=2, keepdims=True)
    damage_normal = save_pixels(out / (name + '_damage_normal.png'), cap_normal * .5 + .5)
    originals = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    source = next(o for o in originals if o.name == 'static')
    for o in originals: o.hide_render = True; o.hide_set(True)
    definitions = ([('a', 'radial_arm_x_minus_11_5', (-15.5, -30, -8), (-9.5, -7, 14)),
                    ('b', 'axial_cradle_junction', (-24, -1, -8), (24, 18, 8))] if name == 'fleet' else
                   [('a', 'intake_drum_mount', (-20.5, -1, -8), (-11.5, 12, 11)),
                    ('b', 'plus_x_tank_mount', (10, -20, -8), (16, -7, 8))])
    results = []

    def boolean(obj, cutter, operation):
        bpy.context.view_layer.objects.active = obj
        mod = obj.modifiers.new('authored_' + operation, 'BOOLEAN')
        mod.operation = operation; mod.solver = 'EXACT'; mod.object = cutter
        mod.use_self = True; mod.use_hole_tolerant = True
        bpy.ops.object.modifier_apply(modifier=mod.name)

    def volume(label, low, high):
        lo, hi = Vector(low), Vector(high)
        o = hs.box(label, (lo + hi) / 2, hi - lo, bevel=0)
        for m in source.data.materials: o.data.materials.append(m)
        for p in o.data.polygons: p.material_index = min(2, len(o.data.materials) - 1)
        return o

    for line, anchor, low, high in definitions:
        master = source.copy(); master.data = source.data.copy()
        bpy.context.scene.collection.objects.link(master); master.hide_set(False)
        master.hide_render = False
        # A quarter-unit wall in every spine module. Bulkhead lands stay solid.
        for i, cx in enumerate((-18.4, -9.2, 0, 9.2, 18.4)):
            half = (8.8 if abs(cx) > 18 else 9.2) / 2 - .25
            cutter = volume('liner_cavity', (cx-half, -6.75, -1.75), (cx+half, -1.25, 1.75))
            boolean(master, cutter, 'DIFFERENCE'); bpy.data.objects.remove(cutter, do_unlink=True)
        # Hollow the actual mount at the chosen cut, keeping .25-unit walls.
        if name == 'fleet' and line == 'b':
            cavities = [((-20.7, -3.7, -2.15), (-18.3, 13.7, -.45)),
                        ((18.3, -3.7, -2.15), (20.7, 13.7, -.45))]
        else:
            cx = -13 if name == 'fleet' else (-16 if line == 'a' else 13)
            width = 3 if name == 'fleet' else (8 if line == 'a' else 5)
            cavities = [((cx-width/2+.25, -13 if line == 'b' else -10, -1.7),
                         (cx+width/2-.25, 6 if name == 'refinery' and line == 'a' else -2, .2))]
        for lo, hi in cavities:
            cutter = volume('mount_liner', lo, hi)
            boolean(master, cutter, 'DIFFERENCE'); bpy.data.objects.remove(cutter, do_unlink=True)
        # Variant materials keep three slots. Cap bands and scorch use the same
        # baked mask set, with the hot strip available for the game-side cooldown.
        mats = [m.copy() for m in source.data.materials]
        for mat in mats:
            nt = mat.node_tree; bs = nt.nodes.get('Principled BSDF')
            if bs is None: bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
            bs.inputs['Emission Strength'].default_value = 0
        interior_bs = next(n for n in mats[0].node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        for socket in ('Base Color', 'Roughness'):
            for link in list(interior_bs.inputs[socket].links): mats[0].node_tree.links.remove(link)
        interior_bs.inputs['Base Color'].default_value = (.009, .011, .014, 1)
        interior_bs.inputs['Roughness'].default_value = .9
        damage_mat = mats[2]
        nt = damage_mat.node_tree; bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
        for tex in [n for n in nt.nodes if n.type == 'TEX_IMAGE']:
            if tex.image and tex.image.name.startswith(name + '_orm'): tex.image = damage_orm
            if tex.image and tex.image.name.startswith(name + '_normal'): tex.image = damage_normal
        for socket, im in (('Base Color', damage_image), ('Emission Color', damage_emission)):
            tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = im
            nt.links.new(tex.outputs[0], bs.inputs[socket])
        bs.inputs['Emission Strength'].default_value = .3
        # Replacing slots preserves polygon indices; clearing slots resets them.
        for index, mat in enumerate(mats): master.data.materials[index] = mat
        interiors = []
        for cx in (-18.4, -9.2, 0, 9.2, 18.4):
            for z in (-.85, .85):
                deck = hs.box('interior_deck', (cx, -4, z), (8.3, 5.6, .22), bevel=0)
                deck.data.materials.append(mats[0]); interiors.append(deck)
        for cx in (-13.8, -4.6, 4.6, 13.8):
            bulk = hs.box('interior_bulkhead', (cx, -4, 0), (.25, 5.6, 3.6), bevel=0)
            bulk.data.materials.append(mats[0]); interiors.append(bulk)
        # Recessed bulkheads on BOTH sides of the junction prevent a cut mount
        # from exposing an empty tube. The intervening rim shows the real wall.
        cut_y = -1 if (name == 'fleet' and line == 'b') or (name == 'refinery' and line == 'a') else -7
        for lo, hi in cavities:
            lo, hi = Vector(lo), Vector(hi)
            if lo.y < cut_y < hi.y:
                for offset in (-.4, .4):
                    cap = hs.box('junction_bulkhead', ((lo.x+hi.x)/2, cut_y+offset, (lo.z+hi.z)/2),
                                 (hi.x-lo.x, .25, hi.z-lo.z), bevel=0)
                    cap.data.materials.append(mats[2]); interiors.append(cap)
                deck = hs.box('junction_deck', ((lo.x+hi.x)/2, (lo.y+hi.y)/2, (lo.z+hi.z)/2),
                              (hi.x-lo.x, hi.y-lo.y, .2), bevel=0)
                deck.data.materials.append(mats[0]); interiors.append(deck)
        bpy.ops.object.select_all(action='DESELECT')
        master.select_set(True)
        for o in interiors: o.select_set(True)
        bpy.context.view_layer.objects.active = master; bpy.ops.object.join()
        cutter = volume('junction_cut', low, high)
        cutter.data.materials.clear()
        for mat in mats: cutter.data.materials.append(mat)
        for polygon in cutter.data.polygons: polygon.material_index = 2
        detached = master.copy(); detached.data = master.data.copy()
        bpy.context.scene.collection.objects.link(detached)
        boolean(detached, cutter, 'INTERSECT'); boolean(master, cutter, 'DIFFERENCE')
        bpy.data.objects.remove(cutter, do_unlink=True)
        pieces = [master, detached]
        for o, label in zip(pieces, ('remaining', 'detached')):
            assert len(o.data.materials) == 3, 'Break must retain three material slots'
            o.name = '%s_break_%s_%s' % (name, line, label)
            # UVs on new cap faces use the damage bands. Exterior UVs stand.
            uv = o.data.uv_layers.active
            if uv is None: uv = o.data.uv_layers.new(name='surface')
            for p in o.data.polygons:
                if p.material_index == 2:
                    for li in p.loop_indices:
                        co = o.data.vertices[o.data.loops[li].vertex_index].co
                        uv.data[li].uv = ((co.x * .17) % 1, min(.98, abs(co.z) / 4))
            bm = bmesh.new(); bm.from_mesh(o.data)
            boundary = sum(e.is_boundary for e in bm.edges)
            bm.free()
            assert boundary == 0, ('Uncapped break', o.name, boundary)
            bpy.ops.object.select_all(action='DESELECT'); o.select_set(True)
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_VOLUME', center='MEDIAN')
        bpy.ops.object.select_all(action='DESELECT')
        for o in pieces: o.select_set(True)
        want = sum(len(p.vertices)-2 for o in pieces for p in o.data.polygons)
        path = out / ('%s_break_%s.glb' % (name, line))
        bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True)
        before = set(bpy.context.scene.objects); bpy.ops.import_scene.gltf(filepath=str(path))
        imported = set(bpy.context.scene.objects) - before
        got = sum(len(p.vertices)-2 for o in imported if o.type == 'MESH' for p in o.data.polygons)
        assert got == want, ('Break round trip', want, got)
        for o in imported | set(pieces): bpy.data.objects.remove(o, do_unlink=True)
        results.append({'line': line, 'anchor': anchor, 'cut_box': [low, high],
                        'triangles_roundtrip': want, 'boundary_edges': 0, 'wall': .25,
                        'decks': [-.85, .85], 'bulkheads': [-13.8, -4.6, 4.6, 13.8],
                        'frame_exemption': 'R100 damage texture bands on cut truss surfaces',
                        'piece_origins': 'centre of volume', 'file': path.name})
    for o in originals: o.hide_render = False; o.hide_set(False)
    return results


def detail_main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--detail', action='store_true')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--faction', default='ithar')
    parser.add_argument('--finish-breaks', action='store_true')
    parser.add_argument('--reuse-local-masks', action='store_true', help='Reuse a retained per-element bake after an interrupted run; geometry must be identical')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    args.out.mkdir(parents=True, exist_ok=True)
    if args.finish_breaks:
        report = json.loads((args.out / 'detail_audit.json').read_text())
        for name in ('fleet', 'refinery'):
            bpy.ops.wm.open_mainfile(filepath=str(args.out / (name + '_detail.blend')))
            report['variants'][name]['breaks'] = break_variants(args.out, name, args.faction)
        (args.out / 'detail_audit.json').write_text(json.dumps(report, indent=2) + '\n')
        return
    report = {'phase': 'R100 additions only, review gate; no shipping swap', 'variants': {}}
    for name, build, detail in (('fleet', fleet, fleet_detail), ('refinery', refinery, refinery_detail)):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        PARTS.clear(); GUNS.clear(); hs.PARTS.clear(); MATS.clear()
        MATS.update(structure=material('neutral_structure', (0.16, 0.19, 0.23)),
                    armor=material('neutral_armor', (0.29, 0.32, 0.36)),
                    accent=material('faction_cowling', (0.44, 0.16, 0.06)))
        build()
        frozen = locked_snapshot()
        detail()
        current = locked_snapshot()
        assert all(current[k] == v for k, v in frozen.items()), 'R94 primitive changed'
        if name == 'fleet':
            tops = [max(v.co.z for v in bpy.data.objects['dorsal_%d' % i].data.vertices) for i in range(4)]
            assert tops == [4.5, 5.0, 4.0, 6.5] and all(z - 2 >= 2 for z in tops)
            assert max(v.co.z for v in bpy.data.objects['gantry_crossbeam'].data.vertices) == 9
        else:
            assert max(v.co.z for v in bpy.data.objects['secondary_process_column'].data.vertices) < 12
        result = audit()
        result['locked_primitives'] = len(frozen)
        result['locked_primitive_hashes'] = frozen
        result['locked_geometry'] = 'PASS: exact vertex, polygon, transform and bevel hashes'
        result['paint'] = paint_station(args.out, name, args.faction, args.reuse_local_masks)
        result['triangles_roundtrip'] = merge_export(args.out / (name + '_detail.glb'))
        assert result['triangles_roundtrip'] <= (40000 if name == 'fleet' else 45000)
        bpy.ops.wm.save_as_mainfile(filepath=str(args.out / (name + '_detail.blend')))
        result['breaks'] = break_variants(args.out, name, args.faction)
        report['variants'][name] = result
        (args.out / 'detail_audit.json').write_text(json.dumps(report, indent=2) + '\n')
        print('[station-detail]', name, json.dumps(result), flush=True)


if __name__ == '__main__':
    if '--detail' in sys.argv:
        detail_main()
    else:
        main()
