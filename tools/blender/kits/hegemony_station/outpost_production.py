"""Issue 1791: paint and export station_outpost with station_T2's own production route.

The outpost (outpost.py) is painted by the same functions as T2 (production.py): the Hegemony stack configured to T2's
accepted direction (production_finish.configure), the same five tile families at the same 2 world-unit repeat, the same
service-detail drawing, glass and emergency-marker materials, cavity and edge wear from the real geometry, and the same
named COLOR_0 wear export. Kit units map to world units by T2's own factor (99.2 / T2's 51.69 kit span), so the outpost's
drums, airlocks and pipes are T2's size and the game fits it into its hexes (a4_props.station).

blender -b --python-exit-code 1 -P outpost_production.py -- --out DIR --project GODOT_DIR --t2-glb STATION_T2_GLB
(or the pip bpy wheel: python outpost_production.py -- ...). Writes DIR/station_outpost.glb and its reports.

--t2-glb takes the painted tiles straight from the installed station_T2.glb (Ryan, Nov 24: "paint with T2's tiles"): the same
pixels, so the outpost cannot drift from T2's accepted paint. Without it the tiles are baked again through production.py
(--reuse-tiles reads an earlier bake from DIR/textures); that bake now goes through the newer shared paint stack and is not
the accepted T2 look, so the PC job always passes --t2-glb.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path
import sys
import types

import bpy

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import production as P          # T2's paint route: tiles, details, masks, materials (imports review, finish, PS, H)
import outpost

# T2's kit-to-world factor: production.py scales T2's 51.69 kit-unit span to the scale table's 99.2 (scale.md, the big
# station row). The outpost keeps it, so a drum or airlock is the same world size on both stations.
T2_KIT_SPAN = 51.69
OUT_NAME = 'station_outpost'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--reuse-tiles', action='store_true')
    ap.add_argument('--t2-glb')
    a = ap.parse_args(sys.argv[sys.argv.index('--') + 1:])
    out, project = Path(a.out), Path(a.project)
    out.mkdir(parents=True, exist_ok=True)
    textures = out / 'textures'
    textures.mkdir(exist_ok=True)
    P.PS.gpu(16)
    print('OUTPOST BAKE DEVICE', bpy.context.scene.cycles.device, flush=True)
    paint_direction = P.finish.configure(P.H)
    if a.t2_glb:
        maps = t2_tiles(Path(a.t2_glb), textures)
    elif a.reuse_tiles:
        maps = {zone: {channel: bpy.data.images.load(str(textures / ('T2_' + zone + '_' + channel + '.png')))
                       for channel in ('albedo', 'orm', 'normal')} for zone in set(P.ZONE.values())}
        for source in maps.values():
            source['orm'].colorspace_settings.name = 'Non-Color'
            source['normal'].colorspace_settings.name = 'Non-Color'
        maps = P.fine_details(maps, textures)
    else:
        maps = P.fine_details(P.tile_maps(textures, P.cruiser_density(project)['length_world']), textures)
    glass = P.finish.glass_materials(P.H, P.PS, textures, P.RES, P.TILE_WORLD)
    root, move, objs, rows, details = outpost.build()
    root.name = OUT_NAME
    uniform_scale = P.contract()['range'][0] / T2_KIT_SPAN
    root.scale = (uniform_scale,) * 3
    root['status'] = 'production paint; issue 1791 (T2 route)'
    root['paint_stack'] = 'hegemony'
    root['tile_world_units'] = P.TILE_WORLD
    bpy.context.view_layer.update()
    # uv_and_masks wraps tower faces round their own axis, read from the design's tower list: the outpost's one tower
    t = outpost.TOWER
    import math
    tower_xy = dict(x=t['dist'] * math.cos(math.radians(t['angle'])), y=t['dist'] * math.sin(math.radians(t['angle'])))
    saved_design = P.review.D
    P.review.D = types.SimpleNamespace(TOWERS=[tower_xy])
    try:
        P.uv_and_masks(objs, uniform_scale, out)
    finally:
        P.review.D = saved_design
    materials = {zone: P.finish_material(zone, m) for zone, m in maps.items()}
    window_counts = []
    for ob in objs:
        zone = ob['zone']
        if zone in P.ZONE:
            ob.data.materials.clear()
            ob.data.materials.append(materials[P.ZONE[zone]])
        elif zone in ('glazing', 'viewport'):
            window_counts.append(dict(module=ob['module'], zone=zone, **P.finish.assign_glazing(ob, glass)))
        elif zone == 'blue':
            ob.data.materials.clear()
            ob.data.materials.append(glass[2])
        elif zone == 'battery':
            ob.data.materials.clear()
            ob.data.materials.append(glass[3])
        else:
            raise RuntimeError('unpainted outpost zone: ' + zone)
    after = P.signature(objs)
    P.write(out / 'outpost_manifest.json', dict(
        code=OUT_NAME, stage='paint proof', route='station_T2 production functions (production.py)',
        tiles=dict(source=str(a.t2_glb), sha256=hashlib.sha256(Path(a.t2_glb).read_bytes()).hexdigest()) if a.t2_glb
        else 'baked again (not the accepted T2 tiles)',
        bounds=P.review.bounds(objs), uniform_scale=uniform_scale, modules=rows, details=details,
        triangles=sum(v['triangles'] for v in after.values()),
        inside_triangles=sum(v['triangles'] for v in after.values() if v['inside']),
        lit_window_faces=sum(r['lit_faces'] for r in window_counts), paint_direction=paint_direction,
        maps=dict(resolution=P.RES, tile_world=P.TILE_WORLD),
        source_hashes={p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                       for p in [HERE / 'outpost.py', HERE / 'outpost_production.py', HERE / 'production.py',
                                 HERE / 'production_finish.py', HERE / 'parts.py', HERE.parent / 'hegemony/stack.py']}))
    bpy.ops.wm.save_as_mainfile(filepath=str(out / 'station_outpost_painted.blend'))
    export(root, move, objs, out)
    print('OUTPOST PRODUCTION COMPLETE', flush=True)


def t2_tiles(glb, textures):
    """The painted tiles of each zone, read from T2's own material (T2_painted_<zone>) in its installed GLB."""
    data = glb.read_bytes()
    if data[:4] != b'glTF':
        raise RuntimeError('not a GLB: ' + str(glb))
    size, kind = struct.unpack_from('<II', data, 12)
    gltf = json.loads(data[20:20 + size])
    blob_at = 20 + size + 8
    by_name = {m.get('name'): m for m in gltf['materials']}

    def image(info, name, colour):
        img = gltf['images'][gltf['textures'][info['index']]['source']]
        view = gltf['bufferViews'][img['bufferView']]
        start = blob_at + view.get('byteOffset', 0)
        ext = '.png' if img.get('mimeType', 'image/png') == 'image/png' else '.jpg'
        path = textures / (name + ext)
        path.write_bytes(data[start:start + view['byteLength']])
        im = bpy.data.images.load(str(path))
        im.name = name
        if not colour:
            im.colorspace_settings.name = 'Non-Color'
        return im

    maps = {}
    for zone in sorted(set(P.ZONE.values())):
        m = by_name.get('T2_painted_' + zone)
        if m is None or 'normalTexture' not in m or 'baseColorTexture' not in m.get('pbrMetallicRoughness', {}) \
                or 'metallicRoughnessTexture' not in m['pbrMetallicRoughness']:
            raise RuntimeError('station_T2.glb has no painted tiles for zone ' + zone)
        pbr = m['pbrMetallicRoughness']
        # glTF metallicRoughness keeps roughness in G and metal in B, as T2's ORM tiles do
        maps[zone] = dict(albedo=image(pbr['baseColorTexture'], 'T2_tile_' + zone + '_albedo', True),
                          orm=image(pbr['metallicRoughnessTexture'], 'T2_tile_' + zone + '_orm', False),
                          normal=image(m['normalTexture'], 'T2_tile_' + zone + '_normal', False))
        print('OUTPOST TILE FROM T2', zone, flush=True)
    return maps


def export(root, move, objs, out):
    """As review.export: per-module meshes joined into one static mesh, wear named as COLOR_0. Nothing moves."""
    copies = []
    for ob in objs:
        cp = ob.copy(); cp.data = ob.data.copy(); bpy.context.collection.objects.link(cp)
        copies.append(cp)
    bpy.ops.object.select_all(action='DESELECT')
    for o in copies:
        o.select_set(True)
    bpy.context.view_layer.objects.active = copies[0]
    bpy.ops.object.convert(target='MESH')
    bpy.ops.object.join()
    copies[0].name = 'outpost_structure'
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    copies[0].select_set(True)
    for ob in bpy.context.scene.objects:
        if ob.name.startswith('tower_axis_'):
            ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out / (OUT_NAME + '.glb')), export_format='GLB', use_selection=True,
                              export_extras=True, export_yup=True, export_animations=False,
                              export_materials='EXPORT', export_vertex_color='NAME',
                              export_vertex_color_name='T2_geometry_wear', export_all_vertex_colors=False,
                              export_attributes=True)


if __name__ == '__main__':
    main()
