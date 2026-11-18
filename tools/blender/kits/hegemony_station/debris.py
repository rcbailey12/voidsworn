"""Refs #863. T2 pressure hull, docking structure and fittings after a tear."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector
from mathutils.geometry import tessellate_polygon

RNG = random.Random(863)
MATS = {}
TINTS = {
    'paint': (0.86, 0.82, 0.75),
    'panel': (0.78, 0.74, 0.68),
    'tear': (0.55, 0.46, 0.37),
    'scorch': (0.48, 0.36, 0.28),
}

# Different parent shapes: swept shielding, a curled strip and a corner of a
# pressure door. A missing bite and split tips identify the fracture sides.
OUTLINES = [
    [(-.56, -.21), (-.30, -.30), (.12, -.34), (.48, -.08), (.24, .03),
     (.49, .12), (.16, .16), (.22, .34), (-.16, .30), (-.36, .39), (-.50, .17)],
    [(-.55, -.17), (-.24, -.24), (.55, -.12), (.20, -.01), (.43, .12),
     (.09, .08), (-.11, .26), (-.23, .13), (-.52, .21)],
    [(-.50, -.46), (-.11, -.42), (-.18, -.29), (.16, -.18), (.48, .02),
     (.30, .07), (.53, .30), (.09, .24), (-.14, .45), (-.49, .17)],
]


def mesh_part(name, vertices, faces, zones):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    ob = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(ob)
    materials = list(dict.fromkeys(zones))
    for zone in materials:
        mesh.materials.append(MATS[zone])
    for face, zone in zip(mesh.polygons, zones):
        face.material_index = materials.index(zone)
    return ob


def station_paint(source, tint):
    material = bpy.data.materials['T2_painted_' + source]
    tree = material.node_tree
    bsdf = next(node for node in tree.nodes if node.type == 'BSDF_PRINCIPLED')
    base = bsdf.inputs['Base Color']
    texture = base.links[0].from_socket
    multiply = tree.nodes.new('ShaderNodeMix')
    multiply.data_type = 'RGBA'
    multiply.blend_type = 'MULTIPLY'
    inputs = {socket.identifier: socket for socket in multiply.inputs}
    output = next(socket for socket in multiply.outputs if socket.identifier == 'Result_Color')
    inputs['Factor_Float'].default_value = 1.0
    inputs['B_Color'].default_value = (*tint, 1.0)
    tree.links.new(texture, inputs['A_Color'])
    tree.links.new(output, base)
    return material


def beam(name, start, end, width, height, zone='scorch', split=False):
    direction = Vector(end) - Vector(start)
    section = [(-.5, -.5), (.5, -.5), (.5, .5), (-.5, .5)]
    basis = direction.to_track_quat('Z', 'Y')
    vertices = [
        Vector(start) + basis @ Vector((x * width, y * height, along))
        for along in (0.0, direction.length)
        for x, y in section
    ]
    if split:
        vertices[4] -= direction * .13
        vertices[5] += direction * .09
        vertices[7] -= direction * .05
    faces = [(3, 2, 1, 0), (4, 5, 6), (4, 6, 7)]
    faces += [(i, (i+1) % 4, (i+1) % 4 + 4, i+4) for i in range(4)]
    return mesh_part(name, vertices, faces, ['tear'] * 3 + [zone] * 4)


def plate(size, variant, detailed=True):
    points = [
        Vector((x + RNG.uniform(-.025, .025), y + RNG.uniform(-.025, .025), 0))
        for x, y in OUTLINES[variant]
    ]
    thickness = min(.15, size * .08)
    folds = [RNG.uniform(-.06, .06) for _ in points]

    def surface(x, y):
        # The shell is sprung across the tear and rolled back at the longest tip.
        return size * (.39 * abs(x + .09) + .17 * y + .11 * x * y)

    vertices = [
        (v.x * size, v.y * size, surface(v.x, v.y) + folds[i] * size + offset)
        for offset in (-thickness, 0.0)
        for i, v in enumerate(points)
    ]
    count = len(points)
    triangles = tessellate_polygon([points])
    faces = [tuple(reversed(face)) for face in triangles]
    faces += [tuple(i + count for i in face) for face in triangles]
    faces += [(i, (i+1) % count, (i+1) % count + count, i + count) for i in range(count)]
    if not detailed:
        mesh_part('small skin fragment', vertices, faces, ['tear'] * len(faces))
        return
    outer = ['panel' if variant == 1 else 'paint'] * len(triangles)
    mesh_part('rolled pressure skin', vertices, faces,
              ['scorch'] * len(triangles) + outer + ['tear'] * count)

    # L-section ribs buckle away from the backside; one projects beyond the skin.
    for x, ends in ((-.28, (-.19, .31)), (.03, (-.17, .18))):
        root = Vector((x * size, ends[0] * size, surface(x, ends[0]) - thickness))
        kink = Vector(((x + .04) * size, 0.02 * size, surface(x, 0) - .10 * size))
        tip = Vector(((x - .035) * size, ends[1] * size, surface(x, ends[1]) - .16 * size))
        for a, b in ((root, kink), (kink, tip)):
            beam('burnt rib web', a, b, .055 * size, .12 * size, split=b == tip)
            beam('torn return flange', a - Vector((0, 0, .057 * size)),
                 b - Vector((0, 0, .057 * size)), .14 * size, .026 * size, 'tear', b == tip)
    # Remnant of the original cover seam, above the painted side.
    a = (-.38 * size, -.12 * size, surface(-.38, -.12) + .047 * size)
    b = (-.16 * size, -.10 * size, surface(-.16, -.10) + .047 * size)
    beam('surviving cover lip', a, b, .047 * size, .027 * size, 'panel', True)


def girder(size, variant):
    # Bent T2 docking truss: two deep chords, an open bay, one missing brace
    # and a web peeled out of the broken end. Openings survive at camera 60.
    width = size * (.17 if variant else .22)
    roots = [Vector((-.53 * size, -.08 * size, -.06 * size)),
             Vector((-.11 * size, 0, 0)), Vector((.49 * size, .16 * size, .19 * size))]
    for side in (-1, 1):
        chord = [p + Vector((0, side * width * .5, side * width * i * .21))
                 for i, p in enumerate(roots)]
        for i, (a, b) in enumerate(zip(chord, chord[1:])):
            for z in (-.057, .057):
                offset = Vector((0, 0, z * size))
                beam('peeled chord flange', a + offset, b + offset, .055 * size,
                     .023 * size, 'paint' if side == 1 else 'tear', i == 1)
            beam('burnt chord web', a, b, .018 * size, .115 * size, split=i == 1)
    for i, p in enumerate(roots[:2]):
        a = p - Vector((0, width / 2, 0))
        b = roots[i + 1] + Vector((0, width * .45, width * .12))
        if i == 1:
            b = a.lerp(b, .68)
        beam('diagonal cross brace', a, b, size * .032, size * .045, 'tear', i == 1)
        beam('end tie', a, p + Vector((0, width / 2, width * .13)),
             size * .038, size * .042)


def pod(size):
    sides = 16
    rings = [(-.49, .15), (-.36, .22), (-.31, .245), (-.25, .22),
             (.20, .22), (.22, .251), (.27, .248), (.31, .21), (.22, .17), (-.30, .17)]
    vertices = []
    for j, (height, radius) in enumerate(rings):
        for i in range(sides):
            angle = math.tau * i / sides
            ripped = (i % 5 - 2) * .031 if j >= 7 else 0
            vertices.append((math.cos(angle) * radius * size,
                             math.sin(angle) * radius * size, (height + ripped) * size))
    faces = [tuple(reversed(range(sides)))]
    zones = ['panel']
    for j in range(len(rings)-1):
        for i in range(sides):
            if j >= 4 and i in (12, 13, 14):
                continue
            a, b = j * sides + i, j * sides + (i+1) % sides
            faces.append((a, b, b + sides, a + sides))
            zones.append('scorch' if j >= 8 else 'tear' if j in (1, 2, 5, 6, 7) else 'panel')
    mesh_part('split pressure pod with burnt liner', vertices, faces, zones)
    for x in (-.12, .17):
        beam('severed cradle foot', (x*size, -.19*size, -.30*size),
             (x*size, -.34*size, .13*size), .066*size, .055*size, 'tear', True)


def antenna(size):
    vertices = [(0, 0, -.11 * size)]
    for radius, height in ((.17, -.055), (.32, .04), (.40, .16)):
        for i in range(12):
            a = math.tau * i / 12
            vertices.append((radius * size * math.cos(a), radius * size * math.sin(a),
                             (height + (i % 3 - 1) * .026) * size))
    faces = [(0, 1 + i, 1 + (i + 1) % 12) for i in range(12) if i != 8]
    zones = ['panel'] * len(faces)
    for start in (1, 13):
        for i in range(12):
            if i in (7, 8, 9) or (start == 13 and i in (0, 5)):
                continue
            a, b = start + i, start + (i + 1) % 12
            faces.append((a, a + 12, b + 12, b))
            zones.append('panel')
    backside = [(x, y, z - .018 * size) for x, y, z in vertices]
    back = len(vertices)
    mesh_part('broken sensor reflector', vertices + backside,
              faces + [tuple(i + back for i in reversed(face)) for face in faces],
              zones + ['scorch'] * len(faces))
    beam('folded antenna neck', (0, 0, -.08*size), (-.15*size, 0, -.32*size),
         .078*size, .070*size, 'tear')
    beam('broken antenna mount', (-.15*size, 0, -.32*size), (-.45*size, .11*size, -.29*size),
         .073*size, .057*size, 'panel', True)
    beam('surviving feed', (0, 0, -.06*size), (.06*size, -.08*size, .24*size),
         .035*size, .039*size, 'tear', True)


def finish(group, name):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in group:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = group[0]
    bpy.ops.object.join()
    ob = bpy.context.object
    ob.name = name
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    radius = max(v.co.length for v in ob.data.vertices)

    uv = ob.data.uv_layers.new(name='station world-density paint')
    for poly in ob.data.polygons:
        axis = max(range(3), key=lambda j: abs(poly.normal[j]))
        u, v = [j for j in range(3) if j != axis]
        for li in poly.loop_indices:
            p = ob.data.vertices[ob.data.loops[li].vertex_index].co
            uv.data[li].uv = (p[u] / 2, p[v] / 2)
    return ob, radius


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--station', type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    args.out.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(args.station))
    for zone, source in [('paint', 'hgrey'), ('panel', 'hpanel'), ('tear', 'hmetal'), ('scorch', 'dark')]:
        MATS[zone] = station_paint(source, TINTS[zone])
    # Remove Blender's imported objects from the export scene; the source GLB stays untouched.
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    # World units. Blender -Y follows the stub. The heavy fragments define a
    # loose diagonal, with smaller material dispersed beyond both ends.
    specs = [
        ('plate', 4.5, (-5.4, -49.0, -22.5)), ('girder', 5.3, (0.9, -50.8, -24.8)),
        ('plate', 3.8, (-9.2, -52.8, -25.0)), ('pod', 2.5, (-1.9, -55.5, -22.0)),
        ('girder', 4.5, (-8.2, -59.0, -22.6)), ('plate', 3.2, (4.7, -56.7, -26.0)),
        ('antenna', 3.0, (-4.7, -62.1, -25.3)), ('girder', 3.1, (5.7, -63.0, -23.8)),
        ('plate', 2.6, (-11.3, -64.5, -28.0)), ('plate', 1.9, (2.5, -68.7, -25.0)),
    ]
    specs += [('chip', RNG.uniform(.30, 1.16), None) for _ in range(22)]
    rows = []
    plate_variant = 0
    for i, (kind, size, anchor) in enumerate(specs):
        before = set(bpy.context.scene.objects)
        if kind == 'plate':
            plate(size, plate_variant % len(OUTLINES))
            plate_variant += 1
        elif kind == 'girder':
            girder(size, i % 2)
        elif kind == 'pod':
            pod(size)
        elif kind == 'antenna':
            antenna(size)
        elif i % 3:
            plate(size, i % len(OUTLINES), detailed=False)
        else:
            beam('sheared rail sliver', (0, 0, 0), (size, .23 * size, .10 * size),
                 .18 * size, .12 * size, 'tear', True)
        group = sorted(set(bpy.context.scene.objects) - before, key=lambda ob: ob.name)
        ob, radius = finish(group, 'T2_debris_%02d_%s' % (i+1, kind))
        for _ in range(1000):
            if anchor is not None:
                position = Vector(anchor)
            else:
                distance = RNG.uniform(47, 73)
                position = Vector((RNG.uniform(-12.5, 7.5) - .10 * (distance - 52),
                                   -distance, RNG.uniform(-29, -22)))
            position.y += .6  # Lead the cloud from the edge of the damaged side.
            position.z -= 11.25  # Full tumble clearance below the fitted flagship hulls.
            if all((position - Vector(row['position_blender'])).length >
                   radius + row['radius'] + .28 for row in rows):
                break
            if anchor is not None:
                raise RuntimeError('Hero piece overlaps another full tumble envelope: ' + ob.name)
        else:
            raise RuntimeError('Cannot place separated tumble envelopes')
        ob.location = position
        ob.rotation_euler = [RNG.uniform(-1.2, 1.2) for _ in range(3)]
        if kind == 'plate' and plate_variant % 3 == 0:
            ob.rotation_euler.x += 2.4  # Present one burnt backing at the first pose.
        axis = Vector([RNG.uniform(-1, 1) for _ in range(3)]).normalized()
        ob['debris_kind'] = kind
        ob['debris_axis'] = list(axis)
        ob['debris_rate'] = math.radians(RNG.uniform(.12, .38))
        ob['debris_radius'] = radius
        ob.data.calc_loop_triangles()
        rows.append(dict(name=ob.name, kind=kind, triangles=len(ob.data.loop_triangles),
                         radius=radius, position_blender=list(position)))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(args.out/'station_T2_debris.glb'), export_format='GLB',
        use_selection=True, export_extras=True, export_yup=True, export_animations=False,
        export_vertex_color='NONE')
    report = dict(code='station_T2_debris', pieces=rows, triangles=sum(r['triangles'] for r in rows),
                  material_source_sha256=hashlib.sha256(args.station.read_bytes()).hexdigest(),
                  generator_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  method='Detached T2 pressure skin, docking truss and fittings; run 3 PBR tiles with burnt backs and torn edges')
    (args.out/'debris_manifest.json').write_text(json.dumps(report, indent=2)+'\n')
    print('T2 DEBRIS BUILT', len(rows), 'pieces;', report['triangles'], 'triangles', flush=True)


if __name__ == '__main__':
    main()
