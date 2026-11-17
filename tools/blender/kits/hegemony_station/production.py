"""Refs #975. Station recipe stages 5, 6 and 7, without rebuilding its shape.

The faction stack supplies the paint. Repeating PBR tiles supply resolution;
mesh-derived cavity/edge masks and the authored joints supply local wear.
Run in Blender through production_run.bat, never directly on the GPU.
"""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import sys

import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / 'shared'))
sys.path.insert(0, str(REPO / 'tools/blender/r209'))
import review
from scale import contract
import paint_stack as PS

spec = importlib.util.spec_from_file_location('hegemony_paint', HERE.parent / 'hegemony/stack.py')
H = importlib.util.module_from_spec(spec)
spec.loader.exec_module(H)

RES = 2048
TILE_WORLD = 2.0
ZONE = dict(plate='hgrey', plate2='hpanel', trim='htrim', edge='hmetal',
            frame='hmetal', deck='dark', liner='dark', rack='dark',
            recess='dark', glazing='dark', frost='hpanel')


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')


def signature(objs):
    """All evaluated vertices and triangle indices, including the insides."""
    result = {}
    deps = bpy.context.evaluated_depsgraph_get()
    for ob in objs:
        ev = ob.evaluated_get(deps)
        me = ev.to_mesh()
        me.calc_loop_triangles()
        vv = np.array([v.co[:] for v in me.vertices], dtype='<f4')
        tt = np.array([t.vertices[:] for t in me.loop_triangles], dtype='<u4')
        result[ob.name] = dict(vertices=len(vv), triangles=len(tt), inside=bool(ob['inside']),
                               sha256=hashlib.sha256(vv.tobytes() + tt.tobytes()).hexdigest())
        ev.to_mesh_clear()
    return result


def tile_maps(out, reference_length):
    """Bake small flat coupons through the actual Hegemony/shared paint stack.

    Coupons lie between module joints. The station's real joint rings stay
    modelled and use htrim; no fake ship band is substituted for those joints.
    """
    tiles = {k: PS.np_image('station_trim_' + k, v) for k, v in H.trim_sheet().items()}
    H.write_textures(str(out), H.trim_sheet(), H.decal_atlas(code='T2'))
    masks = PS.new_image('coupon_masks', 8, False, (1, 0, 1, 1))
    bpy.ops.mesh.primitive_plane_add(size=TILE_WORLD / reference_length)
    plane = bpy.context.object
    plane.name = 'paint_coupon'
    # Mesh coordinates are the same normalized ship units as a cruiser bake.
    for v in plane.data.vertices:
        v.co.x += TILE_WORLD / reference_length / 2
        v.co.y += TILE_WORLD / reference_length / 2
        v.co.z = .08
    result = {}
    for zone in sorted(set(ZONE.values())):
        # A repeating coupon is a part tile, not a complete ship hull. The
        # faction's part path draws the same ordered grid without requesting
        # ship-wide module-band boxes. Actual station joints remain geometry.
        mat = PS.zone_material(H, zone, 'P', masks, tiles, [], None)
        plane.data.materials.clear()
        plane.data.materials.append(mat)
        maps = {}
        for channel, output in [('albedo', 'ALBEDO'), ('orm', 'ORM'), ('normal', None)]:
            im = PS.new_image('T2_' + zone + '_' + channel, RES, channel == 'albedo')
            PS._target([mat], im)
            PS._emit_switch(mat, output)
            PS.bake(plane, 'NORMAL' if channel == 'normal' else 'EMIT', 0)
            PS.save(im, str(out), 'T2_' + zone + '_' + channel)
            maps[channel] = im
        result[zone] = maps
        print('T2 TILE', zone, flush=True)
    bpy.data.objects.remove(plane, do_unlink=True)
    return result


def finish_material(zone, maps):
    m = bpy.data.materials.new('T2_painted_' + zone)
    m.use_nodes = True
    m['rim_soft'] = True
    m['paint_stack'] = 'hegemony'
    m['tile_world_units'] = TILE_WORLD
    bs = m.node_tree.nodes.get('Principled BSDF')
    nt = m.node_tree
    tex = {}
    for key, im in maps.items():
        node = nt.nodes.new('ShaderNodeTexImage')
        node.image = im
        node.extension = 'REPEAT'
        tex[key] = node
    # glTF exports this multiply as COLOR_0, preserving the geometry masks.
    colour = nt.nodes.new('ShaderNodeVertexColor')
    colour.layer_name = 'T2_geometry_wear'
    mul = nt.nodes.new('ShaderNodeMixRGB')
    mul.blend_type = 'MULTIPLY'
    mul.inputs[0].default_value = 1
    nt.links.new(tex['albedo'].outputs['Color'], mul.inputs[1])
    nt.links.new(colour.outputs['Color'], mul.inputs[2])
    nt.links.new(mul.outputs[0], bs.inputs['Base Color'])
    separate = nt.nodes.new('ShaderNodeSeparateColor')
    nt.links.new(tex['orm'].outputs[0], separate.inputs[0])
    nt.links.new(separate.outputs[1], bs.inputs['Roughness'])
    nt.links.new(separate.outputs[2], bs.inputs['Metallic'])
    normal = nt.nodes.new('ShaderNodeNormalMap')
    nt.links.new(tex['normal'].outputs[0], normal.inputs['Color'])
    nt.links.new(normal.outputs[0], bs.inputs['Normal'])
    return m


def fine_details(maps, out):
    """Ordered service covers, vents and flush fasteners in PBR, not geometry.

    The hull's existing fittings and silhouettes stay exactly as authored.
    At 1024 texels per unit even a 2 cm slot has twenty texture samples.
    """
    from PIL import Image, ImageDraw, ImageFont
    result = {}
    for zone, source in maps.items():
        height = Image.new('F', (RES, RES), 0)
        hd = ImageDraw.Draw(height)
        marking = Image.new('L', (RES, RES), 0)
        md = ImageDraw.Draw(marking)
        if zone in ('hgrey', 'hpanel'):
            # A recessed maintenance cover with screws and an adjacent vent.
            hd.rectangle((180, 250, 700, 810), outline=-.003, width=5)
            hd.line((690, 290, 690, 760), fill=.002, width=8)
            for x in (208, 672):
                for y in (280, 780):
                    hd.ellipse((x-9, y-9, x+9, y+9), fill=-.002)
                    hd.line((x-5, y, x+5, y), fill=-.004, width=3)
            for y in range(1100, 1390, 37):
                hd.rounded_rectangle((190, y, 650, y+17), radius=7, fill=-.004)
            font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 30)
            md.text((210, 835), 'EVA  /  04', font=font, fill=95)
            md.text((210, 1420), 'RETURN', font=font, fill=75)
            for x,y in ((80,80),(1900,80),(80,1900),(1900,1900)):
                md.line((x-20,y,x+20,y),fill=90,width=4)
                md.line((x,y-20,x,y+20),fill=90,width=4)
        else:
            # Machined trim: sparse shallow handling scratches, never grain.
            for x,y in ((150,300),(730,1200),(1450,720)):
                hd.line((x,y,x+150,y+4), fill=-.0004, width=2)
        h = np.asarray(height, dtype=np.float32)
        gy, gx = np.gradient(h, TILE_WORLD / RES)
        mark = np.asarray(marking, dtype=np.float32) / 255
        detailed = {}
        for channel, im in source.items():
            pixels = np.empty(RES*RES*4, np.float32)
            im.pixels.foreach_get(pixels)
            pixels = pixels.reshape(RES, RES, 4)
            # Blender image rows begin at the bottom; Pillow rows at the top.
            if channel == 'normal':
                v = pixels[...,:3] * 2 - 1
                v[...,0] -= gx[::-1]
                v[...,1] += gy[::-1]
                v /= np.maximum(np.linalg.norm(v,axis=2,keepdims=True),1e-6)
                pixels[...,:3] = v * .5 + .5
            elif channel == 'albedo':
                recess = (h[::-1] < -.001).astype(np.float32) * .23
                pixels[...,:3] *= 1 - recess[...,None]
                pixels[...,:3] = pixels[...,:3]*(1-mark[::-1,...,None]) + np.array(H.CAP_LIN)*mark[::-1,...,None]
            else:
                pixels[...,1] = np.maximum(pixels[...,1], .52 + (h[::-1] < 0)*.1)
            final = PS.new_image('T2_detail_'+zone+'_'+channel, RES, channel == 'albedo')
            final.pixels.foreach_set(pixels.ravel())
            PS.save(final, str(out), final.name)
            detailed[channel] = final
        result[zone] = detailed
    return result


def uv_and_masks(objs, uniform_scale, out):
    """Box UVs in world units, plus masks from the evaluated station itself.

    Face-local coordinates keep a hatch, pipe and hull at the same density.
    Dominant-axis projection has a measured worst case of sqrt(1/sqrt(3)).
    Cavity rays sample the real station; curvature reads its bevel normals.
    """
    deps = bpy.context.evaluated_depsgraph_get()
    vertices, faces = [], []
    for ob in objs:
        ev = ob.evaluated_get(deps)
        me = ev.to_mesh()
        off = len(vertices)
        vertices.extend(ob.matrix_world @ v.co for v in me.vertices)
        faces.extend(tuple(off + k for k in p.vertices) for p in me.polygons)
        ev.to_mesh_clear()
    tree = BVHTree.FromPolygons(vertices, faces)
    density = []
    for ob in objs:
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        # Apply only existing bevels, exactly as PR 700's export does.
        bpy.ops.object.convert(target='MESH')
        me = ob.data
        me.uv_layers.new(name='T2_world_tile')
        me.color_attributes.new(name='T2_geometry_wear', type='FLOAT_COLOR', domain='CORNER')
        # Adding an attribute can invalidate earlier RNA handles (Blender 4.5).
        uv = me.uv_layers['T2_world_tile']
        ca = me.color_attributes['T2_geometry_wear']
        me.color_attributes.active_color = ca
        colours = np.ones((len(me.loops), 4), dtype=np.float32)
        uvs = np.zeros((len(me.loops), 2), dtype=np.float32)
        for p in me.polygons:
            n = p.normal
            axis = max(range(3), key=lambda k: abs(n[k]))
            axes = ((1, 2), (2, 0), (0, 1))[axis]
            centre = ob.matrix_world @ p.center
            normal = (ob.matrix_world.to_3x3() @ n).normalized()
            hits = 0
            tangent = normal.cross(Vector((0, 0, 1)))
            if tangent.length < .1: tangent = normal.cross(Vector((0, 1, 0)))
            tangent.normalize()
            bitangent = normal.cross(tangent)
            for direction in (normal, (normal + tangent * .7).normalized(),
                              (normal - tangent * .7).normalized(),
                              (normal + bitangent * .7).normalized()):
                if tree.ray_cast(centre + normal * .012, direction, .65)[0] is not None:
                    hits += 1
            # Darken cavities and the damaged/stub side. No rust on Hegemony.
            abandoned = max(0, min(1, (-centre.y - 4) / 20))
            cavity = 1 - hits * .11
            for li in p.loop_indices:
                co = me.vertices[me.loops[li].vertex_index].co * uniform_scale
                uvs[li] = [co[axes[0]] / TILE_WORLD,
                           co[axes[1]] / TILE_WORLD * (1 if n[axis] > 0 else -1)]
                # Bevel faces expose lighter worn edges in the same palette.
                edge = 1 - max(abs(n.x), abs(n.y), abs(n.z))
                wear = min(1, cavity * (1 - .27 * abandoned) + edge * .22)
                colours[li, :3] = wear
        uv.data.foreach_set('uv', uvs.ravel())
        ca.data.foreach_set('color', colours.ravel())
        actual_uv = np.empty_like(uvs)
        me.uv_layers['T2_world_tile'].data.foreach_get('uv', actual_uv.ravel())
        if not np.allclose(actual_uv, uvs): raise RuntimeError('UV write did not survive attribute creation')
        me.calc_loop_triangles()
        area, texels, minimum = 0, 0, float('inf')
        for t in me.loop_triangles:
            a, b, c = [me.vertices[i].co * uniform_scale for i in t.vertices]
            ar = (b-a).cross(c-a).length / 2
            q = [Vector(uvs[i]) for i in t.loops]
            ua = abs((q[1]-q[0]).cross(q[2]-q[0])) / 2
            if ar > 1e-10:
                minimum = min(minimum, math.sqrt(ua * RES**2 / ar))
                area += ar
                texels += ua * RES**2
        density.append(dict(object=ob.name, zone=ob['zone'], area=area,
                            texels_per_unit=math.sqrt(texels/max(area, 1e-12)), minimum=minimum))
        print('T2 SURFACE', ob.name, flush=True)
    write(out / 'station_density.json', dict(resolution=RES, tile_world=TILE_WORLD,
          method='actual exported per-triangle UV area / world surface area', surfaces=density))


def cruiser_density(project):
    """Measure the installed comparison cruiser, using its real world fit."""
    path = project / 'assets/ships/C15s_23/C15s_23.glb'
    old = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    imported = [o for o in bpy.data.objects if o not in old]
    meshes = [o for o in imported if o.type == 'MESH']
    bb = review.bounds(meshes)
    source = (project / 'render/hull_table.gd').read_text()
    import re
    length = float(re.search(r'"C15s_23":\s*([\d.]+)', source).group(1))
    ship_k = float(re.search(r'const SHIP_K :=\s*([\d.]+)', source).group(1))
    fit = length * ship_k / max(bb['size'])
    area, texels, max_density = 0, 0, 0
    for ob in meshes:
        me = ob.data
        if not me.uv_layers: continue
        me.calc_loop_triangles()
        for t in me.loop_triangles:
            mat = me.materials[t.material_index]
            images = [n.image for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image]
            resolution = max((max(i.size) for i in images), default=0)
            if not resolution: continue
            a,b,c = [(ob.matrix_world @ me.vertices[i].co) * fit for i in t.vertices]
            ar = (b-a).cross(c-a).length / 2
            q = [me.uv_layers.active.data[i].uv for i in t.loops]
            ua = abs((q[1]-q[0]).cross(q[2]-q[0])) / 2
            if ar > 1e-9:
                area += ar
                texels += ua * resolution**2
                max_density = max(max_density, math.sqrt(ua * resolution**2 / ar))
    for ob in imported: bpy.data.objects.remove(ob, do_unlink=True)
    return dict(code='C15s_23', length_world=length*ship_k,
                texels_per_unit=math.sqrt(texels/area), max_triangle_texels_per_unit=max_density,
                source_sha256=hashlib.sha256(path.read_bytes()).hexdigest())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--reuse-tiles', action='store_true')
    a = ap.parse_args(sys.argv[sys.argv.index('--')+1:])
    out, project = Path(a.out), Path(a.project)
    out.mkdir(parents=True, exist_ok=True)
    textures = out / 'textures'
    textures.mkdir(exist_ok=True)
    PS.gpu(16)
    print('T2 BAKE DEVICE', bpy.context.scene.cycles.device, flush=True)
    cruiser = cruiser_density(project)
    if a.reuse_tiles:
        maps = {zone: {channel: bpy.data.images.load(str(textures/('T2_'+zone+'_'+channel+'.png')))
                      for channel in ('albedo','orm','normal')} for zone in set(ZONE.values())}
        for source in maps.values():
            source['orm'].colorspace_settings.name = 'Non-Color'
            source['normal'].colorspace_settings.name = 'Non-Color'
    else:
        maps = tile_maps(textures, cruiser['length_world'])
    maps = fine_details(maps, textures)
    licences = json.loads((out/'licences.json').read_text())
    known = {r['file'] for r in licences['textures']}
    for image in textures.glob('T2_*.png'):
        if image.name not in known:
            licences['textures'].append(dict(file=image.name, licence='CC0',
                source='own work: Hegemony procedural stack and station service-detail drawing',
                used='repeating PBR paint tile; no downloaded image or projected concept'))
    write(out/'licences.json', licences)
    root, move, objs, rows, details = review.build()
    bpy.context.view_layer.update()
    initial = review.bounds(objs)
    uniform_scale = contract()['range'][0] / max(initial['size'])
    root.scale = (uniform_scale,) * 3
    joints = dict(review.D.JOINTS, core=[z*uniform_scale for z in review.D.JOINTS['core']])
    root['joints_json'] = json.dumps(joints)
    root['status'] = 'production paint; issue 975'
    root['paint_stack'] = 'hegemony'
    root['tile_world_units'] = TILE_WORLD
    bpy.context.view_layer.update()
    before = signature(objs)
    uv_and_masks(objs, uniform_scale, out)
    after = signature(objs)
    if before != after: raise RuntimeError('Paint changed PR 700 geometry')
    materials = {zone: finish_material(zone, m) for zone, m in maps.items()}
    window_light = H.glow_material('hwin')
    window_light.name = 'T2_window_lights'
    window_faces = 0
    for ob in objs:
        zone = ob['zone']
        if zone in ZONE:
            ob.data.materials.clear()
            ob.data.materials.append(materials[ZONE[zone]])
            if zone == 'glazing' and ob['module'].startswith('core_'):
                deck = int(ob['module'].split('_')[1])-1
                clusters = [c for c in review.D.LIGHT_CLUSTERS if c['kind'] == 'core' and c['deck'] == deck]
                if clusters:
                    ob.data.materials.append(window_light)
                    radii = [math.hypot(v.co.x,v.co.y) for v in ob.data.vertices]
                    glass_mid_radius = (min(radii)+max(radii))*.5
                    for polygon in ob.data.polygons:
                        angle = math.atan2(polygon.center.y,polygon.center.x)
                        facing = polygon.normal.x*math.cos(angle)+polygon.normal.y*math.sin(angle)
                        cell = int((angle % math.tau)/math.tau*80)
                        near = any(abs(math.atan2(math.sin(angle-math.radians(c['angle'])),
                                  math.cos(angle-math.radians(c['angle'])))) < math.radians(12) for c in clusters)
                        # The accepted two-sided glass shell keeps its original
                        # winding. Pick the actual outer face by its radius.
                        if near and abs(facing) > .6 and math.hypot(polygon.center.x,polygon.center.y) > glass_mid_radius and cell % 2 == 0:
                            polygon.material_index = 1
                            window_faces += 1
        elif zone in ('blue', 'viewport'):
            bs = ob.data.materials[0].node_tree.nodes.get('Principled BSDF')
            rgb = H.window_rgb()
            bs.inputs['Emission Color'].default_value = (*(v*.60/max(rgb) for v in rgb), 1)
            bs.inputs['Emission Strength'].default_value = 1
    write(out/'shape_preservation.json', dict(pass_unchanged=before == after, objects=after,
          triangles=sum(v['triangles'] for v in after.values()),
          inside_triangles=sum(v['triangles'] for v in after.values() if v['inside']),
          source='unchanged review.build(), design.py and parts.py from PR 700'))
    write(out/'cruiser_density.json', cruiser)
    write(out/'production_manifest.json', dict(code='station_T2', stage='paint proof',
          bounds=review.bounds(objs), uniform_scale=uniform_scale, modules=rows,
          details=details, joints=joints,
          drums=review.D.DRUMS, light_clusters=review.D.LIGHT_CLUSTERS,
          lit_window_faces=window_faces,
          paint_stack='tools/blender/kits/hegemony/stack.py',
          maps=dict(resolution=RES, tile_world=TILE_WORLD, texels_per_unit=RES/TILE_WORLD),
          source_hashes={p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                         for p in [HERE/'production.py', HERE/'design.py', HERE/'parts.py', HERE/'review.py',
                                   HERE.parent/'hegemony/stack.py', HERE.parent/'shared/paint_stack.py']}))
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'station_T2_painted.blend'))
    review.export(root, move, objs, out)
    (out/'station_T2.glb').write_bytes((out/'station_T2_review.glb').read_bytes())
    print('T2 PRODUCTION COMPLETE', flush=True)


if __name__ == '__main__': main()
