"""Refs #863. Detached T2 fittings, using the installed station's PBR paint.

Blender Z up. The damaged arm points along -Y. Export only these new parts;
never rebuild, simplify or repaint the approved station.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
RNG = random.Random(863)
MATS = {}


def box(name, centre, size, mat='hmetal'):
    bpy.ops.mesh.primitive_cube_add(size=1, location=centre)
    ob = bpy.context.object
    ob.name = name
    ob.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.data.materials.append(MATS[mat])
    bevel = ob.modifiers.new('worn solid edges', 'BEVEL')
    bevel.width = min(size) * .18
    bevel.segments = 2
    return ob


def beam(a, b, width, depth):
    ob = box('bent structural flange', (Vector(a)+Vector(b))/2,
             (width, depth, (Vector(b)-Vector(a)).length))
    ob.rotation_euler = (Vector(b)-Vector(a)).to_track_quat('Z', 'Y').to_euler()


def plate(size):
    # A folded, thick shell with a jagged break, exposed edge and back ribs.
    outline = [(-.52,-.43),(-.08,-.50),(.49,-.37),(.44,.12),(.28,.25),
               (.35,.43),(.09,.32),(-.06,.49),(-.30,.38),(-.48,.12)]
    outline = [(x+RNG.uniform(-.04,.04),y+RNG.uniform(-.04,.04)) for x,y in outline]
    fold = RNG.uniform(.08,.23)
    thickness = min(.13,size*.10)
    vv = [(x*size,y*size,(fold*abs(x)+.09*y)*size+z)
          for z in (-thickness/2,thickness/2) for x,y in outline]
    n = len(outline)
    faces = [tuple(reversed(range(n))),tuple(range(n,n*2))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh = bpy.data.meshes.new('thick torn pressure plate')
    mesh.from_pydata(vv,[],faces)
    ob = bpy.data.objects.new('folded torn plate',mesh)
    bpy.context.collection.objects.link(ob)
    mesh.materials.append(MATS['hgrey'])
    mesh.materials.append(MATS['hmetal'])
    for p in mesh.polygons:
        if p.index > 1: p.material_index = 1
    if size < 1.0: return
    for x in (-.24,.12):
        box('exposed stiffener',(x*size,-.03*size,-.12),(.10,.57*size,.16))
    for x,y in ((-.35,-.28),(.29,-.24),(-.30,.18)):
        box('retained fastener',(x*size,y*size,.10),(.10,.10,.07))


def girder(size):
    # Two kinked I-section chords, shear webs and torn diagonal ties.
    for y in (-.22,.22):
        for a,b in [((-size/2,y,0),(0,y,.12)),((0,y,.12),(size/2,y,.63))]:
            for z in (-.17,.17):
                beam(Vector(a)+Vector((0,0,z)),Vector(b)+Vector((0,0,z)),.16,.10)
            beam(a,b,.06,.35)
    for x in (-.33*size,0,.28*size):
        beam((x,-.22,.05),(x+.15,.22,.25),.08,.08)


def pod(size):
    # An unpowered pressure canister: end caps, bands, ribs and severed feet.
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=size*.23, depth=size)
    ob = bpy.context.object
    ob.name = 'detached pressure pod'
    ob.data.materials.append(MATS['hgrey'])
    for z in (-.43*size,.43*size):
        bpy.ops.mesh.primitive_torus_add(major_segments=20,minor_segments=6,
            major_radius=size*.235,minor_radius=.065,location=(0,0,z))
        bpy.context.object.data.materials.append(MATS['hmetal'])
    for x,y in ((1,0),(-1,0),(0,1),(0,-1)):
        box('canister rib',(x*size*.23,y*size*.23,0),(.09,.09,size*.82))
    box('dark access hatch',(0,0,size*.51),(.35,.30,.08),'dark')
    for x in (-.25,.25):
        box('torn cradle',(x*size,0,-size*.30),(.13,size*.62,.13))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--station',type=Path,required=True)
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    args.out.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(args.station))
    for zone in ('hgrey','hmetal','dark'):
        MATS[zone] = bpy.data.materials['T2_painted_'+zone]
    # Imported geometry is only a material source. File on disk stays untouched.
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    rows = []
    specs = [('plate',s) for s in (3.9,3.1,2.5,2.2,1.8,1.4)]
    specs += [('girder',s) for s in (4.8,3.7,2.8,2.2)]
    specs += [('pod',s) for s in (2.6,1.9,1.5)]
    specs += [('chip',RNG.uniform(.20,.85)) for _ in range(21)]
    for i,(kind,size) in enumerate(specs):
        before = set(bpy.context.scene.objects)
        if kind in ('plate','chip'): plate(size)
        elif kind == 'girder': girder(size)
        else: pod(size)
        group = list(set(bpy.context.scene.objects)-before)
        bpy.ops.object.select_all(action='DESELECT')
        for ob in group: ob.select_set(True)
        bpy.context.view_layer.objects.active = group[0]
        bpy.ops.object.convert(target='MESH')
        bpy.ops.object.join()
        ob = bpy.context.object
        ob.name = 'T2_debris_%02d_%s' % (i+1,kind)
        # Centre the true mesh before bounding its complete tumble envelope.
        bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY',center='BOUNDS')
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        radius = max(v.co.length for v in ob.data.vertices)
        # Shared PBR tiles repeat every two world units, as on station_T2.
        uv = ob.data.uv_layers.new(name='station world-density paint')
        colours = ob.data.color_attributes.new(name='debris wear',type='FLOAT_COLOR',domain='CORNER')
        for poly in ob.data.polygons:
            axis = max(range(3),key=lambda j:abs(poly.normal[j]))
            xy = [j for j in range(3) if j != axis]
            for li in poly.loop_indices:
                v = ob.data.vertices[ob.data.loops[li].vertex_index].co
                uv.data[li].uv = (v[xy[0]]/2,v[xy[1]]/2)
                colours.data[li].color = (.64,.61,.58,1)
        # All positions are outside the 27.33-unit circumcircle of the seven
        # live cells, even with any station bearing and the entire sphere.
        for attempt in range(1000):
            x = RNG.uniform(-10,11)
            distance = RNG.uniform(32,44) if i < 13 else RNG.uniform(32,50)
            position = Vector((x,-distance,-34-radius-RNG.uniform(0,7)))
            if all((position-Vector(row['position_blender'])).length > radius+row['radius']+.3
                   for row in rows):
                break
        else:
            raise RuntimeError('Cannot place separated tumble envelopes')
        ob.location = position
        ob.rotation_euler = [RNG.uniform(-2.4,2.4) for _ in range(3)]
        axis = Vector([RNG.uniform(-1,1) for _ in range(3)]).normalized()
        ob['debris_kind'] = kind
        ob['debris_axis'] = list(axis)
        ob['debris_rate'] = math.radians(RNG.uniform(.12,.38))
        ob['debris_radius'] = radius
        ob.data.calc_loop_triangles()
        rows.append(dict(name=ob.name,kind=kind,triangles=len(ob.data.loop_triangles),
                         radius=radius,position_blender=list(ob.location)))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(args.out/'station_T2_debris.glb'),export_format='GLB',
        use_selection=True,export_extras=True,export_yup=True,export_animations=False)
    report = dict(code='station_T2_debris',pieces=rows,triangles=sum(r['triangles'] for r in rows),
                  material_source_sha256=hashlib.sha256(args.station.read_bytes()).hexdigest(),
                  generator_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  method='Thick broken station fittings; existing T2 Hegemony PBR tiles at two-unit repeat; no base geometry changed')
    (args.out/'debris_manifest.json').write_text(json.dumps(report,indent=2)+'\n')
    print('T2 DEBRIS BUILT',len(rows),'pieces;',report['triangles'],'triangles',flush=True)


if __name__ == '__main__': main()
