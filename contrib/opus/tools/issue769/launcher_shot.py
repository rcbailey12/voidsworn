# Issue 769 helper (sandbox only): the weapon close-up for a sheet whose weapon is a launcher (build.py's weapon_shots renders
# guns only): the part alone, 35 degrees to port of its aim and 22 up, as weapon_shots does, written weapon_<data.js id>.png.
# usage: python launcher_shot.py CODE FID OUT_DIR   (bpy module)
import sys, os, math, importlib.util
import bpy
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
SHEETS = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..', 'tools', 'blender', 'build_sheets'))
sys.path.insert(0, SHEETS)
import kit  # noqa: E402
code, fid, out = sys.argv[1:4]
sp = importlib.util.spec_from_file_location(code, os.path.join(SHEETS, 'ships', code + '.py'))
d = importlib.util.module_from_spec(sp); sp.loader.exec_module(d)
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
kit.use_kit(getattr(d, 'KIT', 'hullbreakers'))
K = kit.Kit(code, d.LENGTH); d.build(K); K.finish()
f = next(x for x in K.features if x['id'] == fid)
obs = [o for o in K.coll.objects if o.type == 'MESH' and o.get('grp') == fid]
for o in list(K.coll.objects) + list(K.cin.objects):
    o.hide_render = o not in obs
W = [o.matrix_world @ v.co for o in obs for v in o.data.vertices]
lo = Vector([min(v[i] for v in W) for i in range(3)]); hi = Vector([max(v[i] for v in W) for i in range(3)])
tgt = (lo + hi) / 2; size = (hi - lo).length
a, e = math.radians(35), math.radians(22)
dv = Vector((math.cos(e) * math.cos(a), math.cos(e) * math.sin(a), math.sin(e)))
cam = bpy.data.cameras.new('c'); cam.lens = 50; cam.sensor_width = 36
co = bpy.data.objects.new('c', cam); sc.collection.objects.link(co)
co.location = tgt + dv * size * 1.75; co.rotation_euler = (-dv).to_track_quat('-Z', 'Y').to_euler(); sc.camera = co
for nm, frm, en in (('key', (0.5, 0.5, 0.7), 4.0), ('fill', (-0.66, -0.66, -0.35), 0.8)):
    l = bpy.data.lights.new(nm, 'SUN'); l.energy = en; ob = bpy.data.objects.new(nm, l); sc.collection.objects.link(ob)
    ob.rotation_euler = Vector(frm).normalized().to_track_quat('Z', 'Y').to_euler()
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True
w.node_tree.nodes['Background'].inputs[0].default_value = (0.2, 0.2, 0.2, 1); w.node_tree.nodes['Background'].inputs[1].default_value = 0.7
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 24; sc.render.film_transparent = True
sc.view_settings.view_transform = 'Standard'; sc.render.resolution_x, sc.render.resolution_y = 800, 560
sc.render.filepath = os.path.join(out, 'weapon_%s.png' % f['weapon'])
bpy.ops.render.render(write_still=True)
print('wrote', sc.render.filepath)
