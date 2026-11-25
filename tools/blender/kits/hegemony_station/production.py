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
import production_finish as finish
from scale import contract
import paint_stack as PS

spec = importlib.util.spec_from_file_location('hegemony_paint', HERE.parent / 'hegemony/stack.py')
H = importlib.util.module_from_spec(spec)
spec.loader.exec_module(H)

RES = 2048
TILE_WORLD = 2.0
ZONE = dict(plate='hgrey', plate2='hpanel', trim='htrim', edge='hmetal',
            frame='hmetal', deck='dark', liner='dark', rack='dark',
            recess='dark', frost='hpanel')


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
        key = '|'.join((ob['module'],ob['zone'],str(bool(ob['inside']))))
        result[key] = dict(vertices=len(vv), triangles=len(tt), inside=bool(ob['inside']),
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
        mat = PS.zone_material(H, zone, 'P', masks, tiles, [], None, ())
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
        # Calm ordered sheets on every zone, including former black deck and
        # liner materials. These coordinates are physical, module-aligned UVs.
        for x in (0,1024,2047):
            hd.line((x,0,x,2047),fill=-.006,width=17)
        for y in (0,512,1024,1536,2047):
            hd.line((0,y,2047,y),fill=-.006,width=17)
        if zone in ('hgrey', 'hpanel'):
            # A recessed maintenance cover with screws and an adjacent vent.
            hd.rectangle((180, 250, 700, 810), outline=-.006, width=14)
            hd.line((690, 290, 690, 760), fill=.002, width=8)
            for x in (208, 672):
                for y in (280, 780):
                    hd.ellipse((x-13, y-13, x+13, y+13), fill=-.004)
                    hd.line((x-8, y, x+8, y), fill=-.007, width=5)
            for y in range(1100, 1390, 37):
                hd.rounded_rectangle((190, y, 650, y+21), radius=7, fill=-.007)
            font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 30)
            md.text((210, 835), 'EVA  /  04', font=font, fill=95)
            md.text((210, 1420), 'RETURN', font=font, fill=75)
            for x,y in ((80,80),(1900,80),(80,1900),(1900,1900)):
                md.line((x-20,y,x+20,y),fill=90,width=4)
                md.line((x,y-20,x,y+20),fill=90,width=4)
        else:
            # Structural bands, deck plates, cable trunks and bare fittings
            # have joints, access slots and flush bolts too, never flat grey.
            hd.rectangle((175,150,840,440),outline=-.005,width=13)
            for x in (200,810):
                for y in (180,410):
                    hd.ellipse((x-12,y-12,x+12,y+12),fill=-.006)
            for y in range(1140,1360,44):
                hd.rounded_rectangle((1220,y,1830,y+21),radius=6,fill=-.007)
            for x,y in ((150,300),(730,1200),(1450,720)):
                hd.line((x,y,x+150,y+4), fill=-.0004, width=2)
        h = np.asarray(height, dtype=np.float32)
        gy, gx = np.gradient(h, TILE_WORLD / RES)
        mark = np.asarray(marking, dtype=np.float32) / 255
        # Fine residue runs down the metal, with broad world-space soot added
        # from the real geometry below. This is sparse streaking, not grain.
        yy, xx = np.mgrid[0:RES, 0:RES].astype(np.float32) / RES
        # Residue originates at the service cover corners, vent ends and
        # seams, then trails down the module. No independent plate noise.
        streak = np.zeros_like(xx)
        for sx,sy in ((.09,.39),(.34,.39),(.60,.67),(.89,.67),(.50,.25)):
            trail = np.exp(-((xx-sx)/.012)**2)*np.maximum(0,yy-sy)*np.exp(-np.maximum(0,yy-sy)*4)
            streak += trail*2.4
        # Fine geometry survives the camera only if the seam's dirt shoulder
        # spans real pixels too. A 17-texel seam is .017 world units; its soft
        # grime shoulder is .05 units. They follow the same ordered joints.
        from PIL import ImageFilter
        cavity_image = Image.fromarray(((h < -.001)*255).astype(np.uint8))
        residue = np.asarray(cavity_image.filter(ImageFilter.GaussianBlur(24)),dtype=np.float32)[::-1]/255
        # A shallow brushed-metal direction and rubbed service-cover margin,
        # shared by the entire module. No randomly coloured plate or grain.
        brush = .012*np.sin(xx*math.tau*220+.25*np.sin(yy*math.tau))
        handling = Image.new('L',(RES,RES),0)
        handling_draw = ImageDraw.Draw(handling)
        for x,y in ((700,500),(840,280),(1180,1340)):
            handling_draw.line((x-50,y-10,x+70,y+18),fill=110,width=5)
            handling_draw.line((x-35,y+10,x+45,y+34),fill=70,width=4)
        scuffs = np.asarray(handling.filter(ImageFilter.GaussianBlur(1)),dtype=np.float32)[::-1]/255
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
                recess = (h[::-1] < -.001).astype(np.float32) * .42
                pixels[...,:3] *= ((1-recess)*(1-residue*.48)*(1-streak)+brush)[...,None]
                wear = np.clip(np.hypot(gx,gy)[::-1]*.08,0,.10)+scuffs*.30
                pixels[...,:3] = pixels[...,:3]*(1-wear[...,None])+np.array(H.BARE)*wear[...,None]
                pixels[...,:3] = pixels[...,:3]*(1-mark[::-1,...,None]) + np.array(H.CAP_LIN)*mark[::-1,...,None]
            else:
                base_roughness = pixels[...,1]-(.14 if zone == 'dark' else 0)
                pixels[...,0] *= 1-residue*.45
                pixels[...,1] = np.clip(base_roughness+residue*.28+streak*.30-scuffs*.25,.52,.92)
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
    module_ids = {name:i+1 for i,name in enumerate(sorted({o['module'] for o in objs}))}
    for ob in objs:
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        # Apply only existing bevels, exactly as PR 700's export does.
        bpy.ops.object.convert(target='MESH')
        me = ob.data
        me.uv_layers.new(name='T2_world_tile')
        me.color_attributes.new(name='T2_geometry_wear', type='FLOAT_COLOR', domain='CORNER')
        ids = me.attributes.new(name='_T2_MODULE',type='FLOAT',domain='POINT')
        ids.data.foreach_set('value',np.full(len(me.vertices),module_ids[ob['module']],np.float32))
        # Adding an attribute can invalidate earlier RNA handles (Blender 4.5).
        uv = me.uv_layers['T2_world_tile']
        ca = me.color_attributes['T2_geometry_wear']
        me.color_attributes.active_color = ca
        colours = np.ones((len(me.loops), 4), dtype=np.float32)
        uvs = np.zeros((len(me.loops), 2), dtype=np.float32)
        roots, tones = finish.island_tones(me, ob['module'], ob['zone'])
        module = ob['module']
        radial_origin = None
        if module.startswith('core_') or module == 'observation_window':
            radial_origin = Vector((0,0,0))
        elif module.startswith('tower_'):
            tower = review.D.TOWERS[int(module[-1])-1]
            radial_origin = Vector((tower['x'],tower['y'],0))
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
            cavity = 1 - hits * .11
            tone = tones[roots[p.vertices[0]]]
            for li in p.loop_indices:
                co = me.vertices[me.loops[li].vertex_index].co * uniform_scale
                uvs[li] = [co[axes[0]] / TILE_WORLD,
                           co[axes[1]] / TILE_WORLD * (1 if n[axis] > 0 else -1)]
                if radial_origin is not None and abs(n.z)<.65:
                    local = me.vertices[me.loops[li].vertex_index].co-radial_origin
                    mid = p.center-radial_origin
                    angle = math.atan2(mid.y,mid.x)
                    delta = math.atan2(math.sin(math.atan2(local.y,local.x)-angle),
                                       math.cos(math.atan2(local.y,local.x)-angle))
                    radius = math.hypot(mid.x,mid.y)
                    uvs[li] = ((angle+delta)*radius*uniform_scale/TILE_WORLD,co.z/TILE_WORLD)
                if ob['zone'] in ('blue','battery'):
                    # Each face gets a complete bezel and recessed lens.
                    points = [me.vertices[i].co for i in p.vertices]
                    for uvaxis,axis0 in enumerate(axes):
                        low = min(v[axis0] for v in points)
                        span = max(v[axis0] for v in points)-low
                        uvs[li,uvaxis] = (me.vertices[me.loops[li].vertex_index].co[axis0]-low)/max(span,1e-8)
                # Bevel faces expose lighter worn edges in the same palette.
                edge = 1 - max(abs(n.x), abs(n.y), abs(n.z))
                world = ob.matrix_world @ me.vertices[me.loops[li].vertex_index].co
                if ob['zone'] in ZONE:
                    colours[li, :3] = finish.weather(world, n, cavity, edge, tone)
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
          module_ids=module_ids,
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
    paint_direction = finish.configure(H)
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
    glass = finish.glass_materials(H, PS, textures, RES, TILE_WORLD)
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
    bpy.context.view_layer.update()
    original = signature(objs)
    original_bounds = review.bounds(objs)
    # Rebuild only with the explicit loose-piece repairs enabled. The original
    # review route remains available, and every other source mesh must match.
    root, move, objs, rows, details = review.build(repair_loose=True)
    root.scale = (uniform_scale,) * 3
    joints = dict(review.D.JOINTS, core=[z*uniform_scale for z in review.D.JOINTS['core']])
    root['joints_json'] = json.dumps(joints)
    root['status'] = 'production paint; issue 975'
    root['paint_stack'] = 'hegemony'
    root['tile_world_units'] = TILE_WORLD
    bpy.context.view_layer.update()
    before = signature(objs)
    changed = [key for key in before if before[key] != original.get(key)]
    allowed = {f'core_{i:02d}|{zone}|False' for i in (3,5,7,8,9) for zone in ('edge','frame')}
    allowed |= {f'habitat_{i//2+1}_slot_{i:02d}|{zone}|False' for i in range(11) for zone in ('edge','frame')}
    allowed |= {'tower_1|'+zone+'|False' for zone in ('edge','plate2','frame')}
    allowed |= {'folded_plate|edge|False','folded_plate|frame|False','spoke_3|frame|False'}
    assert set(changed) <= allowed, 'geometry outside loose-piece repairs: '+str(set(changed)-allowed)
    assert set(original) <= set(before), 'removed a source module or zone'
    assert np.allclose(original_bounds['min'],review.bounds(objs)['min'],atol=.0001), (original_bounds,review.bounds(objs))
    assert np.allclose(original_bounds['max'],review.bounds(objs)['max'],atol=.0001), (original_bounds,review.bounds(objs))
    uv_and_masks(objs, uniform_scale, out)
    after = signature(objs)
    if before != after: raise RuntimeError('Paint changed PR 700 geometry')
    materials = {zone: finish_material(zone, m) for zone, m in maps.items()}
    window_counts = []
    for ob in objs:
        zone = ob['zone']
        if zone in ZONE:
            ob.data.materials.clear()
            ob.data.materials.append(materials[ZONE[zone]])
        elif zone in ('glazing', 'viewport'):
            window_counts.append(dict(module=ob['module'], zone=zone,
                                      **finish.assign_glazing(ob, glass)))
        elif zone == 'blue':
            ob.data.materials.clear()
            ob.data.materials.append(glass[2])
        elif zone == 'battery':
            ob.data.materials.clear()
            ob.data.materials.append(glass[3])
        else: raise RuntimeError('unpainted station zone: '+zone)
    write(out/'shape_preservation.json', dict(pass_unchanged=before == after, objects=after,
          baseline_objects=original,changed_objects=changed,allowed_changed_objects=sorted(allowed),
          unchanged_objects=len(before)-len(changed),bounds_unchanged=True,
          baseline_triangles=sum(v['triangles'] for v in original.values()),
          triangles=sum(v['triangles'] for v in after.values()),
          inside_triangles=sum(v['triangles'] for v in after.values() if v['inside']),
          baseline_inside_triangles=sum(v['triangles'] for v in original.values() if v['inside']),
          source='review.build() against review.build(repair_loose=True); paint changes no geometry'))
    write(out/'cruiser_density.json', cruiser)
    write(out/'production_manifest.json', dict(code='station_T2', stage='paint proof',
          bounds=review.bounds(objs), uniform_scale=uniform_scale, modules=rows,
          details=details, joints=joints,
          drums=review.D.DRUMS, towers=review.D.TOWERS,light_clusters=review.D.LIGHT_CLUSTERS,
          module_families={r['id']:finish.module_family(r['id']) for r in rows},
          lit_window_faces=sum(r['lit_faces'] for r in window_counts),
          windows=window_counts, paint_direction=paint_direction,
          paint_stack='tools/blender/kits/hegemony/stack.py',
          maps=dict(resolution=RES, tile_world=TILE_WORLD, texels_per_unit=RES/TILE_WORLD),
          source_hashes={p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                         for p in [HERE/'production.py', HERE/'production_finish.py', HERE/'design.py', HERE/'parts.py', HERE/'review.py',
                                   HERE.parent/'hegemony/stack.py', HERE.parent/'shared/paint_stack.py']}))
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'station_T2_painted.blend'))
    # Blender's material-inferred export can insert a white COLOR_0 and put
    # the real wear in COLOR_1. glTF/Godot multiply COLOR_0 only. Name it.
    review.export(root, move, objs, out, vertex_colour='T2_geometry_wear')
    (out/'station_T2.glb').write_bytes((out/'station_T2_review.glb').read_bytes())
    print('T2 PRODUCTION COMPLETE', flush=True)


if __name__ == '__main__': main()
