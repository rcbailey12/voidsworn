# Levels of detail from a full-detail textured GLB, keeping its UVs (and so its painted textures): weld on import, collapse-decimate.
# usage: blender -b -P lod_make.py -- in.glb out_prefix TRIS[,TRIS...]   -> out_prefix_<tris>.glb (geometry + the same material)
import sys, bpy
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
src, pre, counts = argv[0], argv[1], [int(x) for x in argv[2].split(',')]
for n in counts:
    bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src, merge_vertices=True)
    o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]; bpy.context.view_layer.objects.active = o; o.select_set(True)
    f0 = len(o.data.polygons)
    if n < f0:
        d = o.modifiers.new('dc', 'DECIMATE'); d.ratio = n / f0; d.use_collapse_triangulate = True; bpy.ops.object.modifier_apply(modifier='dc')
    bpy.ops.object.shade_smooth()
    bpy.ops.export_scene.gltf(filepath=f'{pre}_{n}.glb', export_format='GLB', use_selection=True, export_image_format='JPEG', export_jpeg_quality=95)
    print('LOD', n, 'from', f0, '->', len(o.data.polygons))
