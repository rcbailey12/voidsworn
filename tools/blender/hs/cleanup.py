# Bake-off entry B: clean up the current Hunyuan mesh in Blender. Planar dissolve flattens the lumpy panels into flat faces,
# then hard edges are split where faces meet at more than ANG degrees (weighted normals), which is what reads as "machined".
# usage: python3 cleanup.py in.glb out.blend [angle_deg] [target_tris]
import sys, math, bpy, bmesh
src, out = sys.argv[1], sys.argv[2]; ANG = float(sys.argv[3]) if len(sys.argv) > 3 else 6; TGT = int(sys.argv[4]) if len(sys.argv) > 4 else 60000
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
ms = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in bpy.context.scene.objects: o.select_set(o.type == 'MESH')
bpy.context.view_layer.objects.active = ms[0]
if len(ms) > 1: bpy.ops.object.join()
o = bpy.context.view_layer.objects.active; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
f0 = len(o.data.polygons)
# 1. light smoothing removes the voxel ripple without rounding the big forms
m = o.modifiers.new('sm', 'SMOOTH'); m.factor = .5; m.iterations = 2; bpy.ops.object.modifier_apply(modifier='sm')
# 2. planar dissolve: near-coplanar triangles merge into flat panels
m = o.modifiers.new('dp', 'DECIMATE'); m.decimate_type = 'DISSOLVE'; m.angle_limit = math.radians(ANG); m.use_dissolve_boundaries = False; bpy.ops.object.modifier_apply(modifier='dp')
m = o.modifiers.new('tr', 'TRIANGULATE'); bpy.ops.object.modifier_apply(modifier='tr')
f1 = len(o.data.polygons)
if f1 > TGT: m = o.modifiers.new('dc', 'DECIMATE'); m.ratio = TGT / f1; bpy.ops.object.modifier_apply(modifier='dc')
# 3. hard edges at sharp creases, weighted normals so flat panels shade flat
bpy.ops.object.shade_auto_smooth(angle=math.radians(32))
for md in list(o.modifiers):
    try: bpy.ops.object.modifier_apply(modifier=md.name)
    except Exception: pass
wn = o.modifiers.new('wn', 'WEIGHTED_NORMAL'); wn.keep_sharp = True; bpy.ops.object.modifier_apply(modifier='wn')
print('faces', f0, '->', f1, '->', len(o.data.polygons))
bpy.ops.wm.save_as_mainfile(filepath=out)
