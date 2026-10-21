# Step 1 of concept registration (Blender): silhouettes of a Pixal3D mesh over a grid of rig cameras (fov 20, z up, az 0 = the run's
# first view). Writes out_dir/sil_<az>_<el>.png at 384 px plus a 1024 px one later on request. Step 2: fitcam_fit.py (any python with PIL).
# usage: blender -b -P fitcam_render.py -- mesh.glb out_dir az0 el0 [span] [step] [res]
import sys, os, math, bpy, mathutils
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
src, outd, az0, el0 = argv[0], argv[1], float(argv[2]), float(argv[3]); span = float(argv[4]) if len(argv) > 4 else 30; step = float(argv[5]) if len(argv) > 5 else 3; R = int(argv[6]) if len(argv) > 6 else 384
os.makedirs(outd, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'; sc.display.shading.light = 'FLAT'; sc.display.shading.color_type = 'SINGLE'; sc.display.shading.single_color = (1, 1, 1)
sc.world = bpy.data.worlds.new('w'); sc.world.color = (0, 0, 0); sc.render.resolution_x = sc.render.resolution_y = R
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.angle = math.radians(20); cam.data.sensor_fit = 'HORIZONTAL'
D = 1.1 * 0.5 / math.tan(math.radians(10)); n = int(round(span / step))
for i in range(-n, n + 1):
    for j in range(-int(round(18 / step)), int(round(18 / step)) + 1):
        az, el = az0 + i * step, el0 + j * step
        a, e = math.radians(az), math.radians(el); back = mathutils.Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
        cam.location = back * D; cam.rotation_euler = (-back).to_track_quat('-Z', 'Y').to_euler()
        sc.render.filepath = os.path.join(outd, f'sil_{az:.1f}_{el:.1f}.png'); bpy.ops.render.render(write_still=True)
print('SILS DONE')
