# Clay render of a mesh for the shape bake-off: same light, camera and grey material for every entry.
# usage: python3 render.py in.(glb|obj) out.png [az_deg] [el_deg]
import sys, math, bpy, mathutils
src, out = sys.argv[1], sys.argv[2]; az = float(sys.argv[3]) if len(sys.argv) > 3 else 35; el = float(sys.argv[4]) if len(sys.argv) > 4 else 28
bpy.ops.wm.read_factory_settings(use_empty=True)
if src.endswith('.glb'): bpy.ops.import_scene.gltf(filepath=src)
elif src.endswith('.obj'): bpy.ops.wm.obj_import(filepath=src)
else: bpy.ops.wm.open_mainfile(filepath=src)
ms = [o for o in bpy.context.scene.objects if o.type == 'MESH']
mn = mathutils.Vector((1e9,)*3); mx = mathutils.Vector((-1e9,)*3)
for o in ms:
    for c in o.bound_box:
        w = o.matrix_world @ mathutils.Vector(c); mn = mathutils.Vector(map(min, mn, w)); mx = mathutils.Vector(map(max, mx, w))
ctr = (mn + mx) / 2; R = (mx - mn).length / 2
mat = bpy.data.materials.new('clay'); mat.use_nodes = True; b = mat.node_tree.nodes['Principled BSDF']; b.inputs['Base Color'].default_value = (.42, .42, .44, 1); b.inputs['Roughness'].default_value = .55; b.inputs['Metallic'].default_value = .2
for o in ms:
    o.data.materials.clear(); o.data.materials.append(mat)
    for p in o.data.polygons: p.use_smooth = True
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 24; sc.cycles.use_denoising = True; sc.render.resolution_x = 900; sc.render.resolution_y = 600
sc.world = bpy.data.worlds.new('w'); sc.world.use_nodes = True; sc.world.node_tree.nodes['Background'].inputs[0].default_value = (.06, .065, .08, 1); sc.world.node_tree.nodes['Background'].inputs[1].default_value = .6
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 50
a, e = math.radians(az), math.radians(el); d = R * float(__import__('os').environ.get('DIST','3.1'))
cam.location = ctr + mathutils.Vector((math.cos(a) * math.cos(e), -math.sin(a) * math.cos(e), math.sin(e))) * d
cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler()
for (en, rot) in ((4.0, (math.radians(50), 0, math.radians(30))), (1.2, (math.radians(70), 0, math.radians(200)))):
    l = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); l.data.energy = en; l.rotation_euler = rot; sc.collection.objects.link(l)
sc.render.filepath = out; bpy.ops.render.render(write_still=True)
print('faces', sum(len(o.data.polygons) for o in ms), 'size', [round(x, 3) for x in (mx - mn)])
