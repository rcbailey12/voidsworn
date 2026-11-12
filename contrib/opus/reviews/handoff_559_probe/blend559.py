# Issue 559 (read-only trace): the ship as Blender has it, at the game's battle camera angle (rig a -90 deg, b 0.98 rad from
# straight up, vertical fov 45), radius 170 and 60 game units, under the game's key, fill and ambient (look.gd numbers;
# Godot light energy times pi is the same irradiance as a Blender sun strength), AgX. Opens files read-only; saves nothing.
# usage: blender -b [file.blend] -P blend559.py -- OUT TAG L_GAME [glb=PATH]
import bpy, sys, os, math
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:]
OUT, TAG, LG = a[0], a[1], float(a[2])
GLB = next((x.split('=', 1)[1] for x in a if x.startswith('glb=')), None)
os.makedirs(OUT, exist_ok=True)
sc = bpy.context.scene
if GLB:
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=GLB)
for o in list(sc.objects):
    if o.type in ('LIGHT', 'CAMERA'):
        o.hide_render = True
meshes = [o for o in sc.objects if o.type == 'MESH' and not o.hide_render and o.visible_get()]
lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
for o in meshes:
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
ctr = (lo + hi) / 2; length = hi.x - lo.x
k = length / LG            # Blender units per game unit
print('[559b] meshes', len(meshes), 'bbox', tuple(lo), tuple(hi), 'length', length, 'k', k, flush=True)
tris = 0
dg = bpy.context.evaluated_depsgraph_get()
for o in meshes:
    me = o.evaluated_get(dg).to_mesh(); me.calc_loop_triangles(); tris += len(me.loop_triangles); o.evaluated_get(dg).to_mesh_clear()
print('[559b] triangles', tris, flush=True)
# render
sc.render.engine = 'CYCLES'; cy = sc.cycles
prefs = bpy.context.preferences.addons['cycles'].preferences
for t in ('OPTIX', 'CUDA'):
    try:
        prefs.compute_device_type = t; prefs.get_devices()
        for d in prefs.devices: d.use = True
        cy.device = 'GPU'; break
    except Exception: pass
cy.samples = 128; cy.use_denoising = True
sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = 'None'; sc.view_settings.exposure = 0.0
sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 1920, 1080, 100
sc.render.film_transparent = False
w = bpy.data.worlds.new('w559'); sc.world = w; w.use_nodes = True
nt = w.node_tree; nt.nodes.clear()
outn = nt.nodes.new('ShaderNodeOutputWorld'); mix = nt.nodes.new('ShaderNodeMixShader'); lp = nt.nodes.new('ShaderNodeLightPath')
amb = nt.nodes.new('ShaderNodeBackground'); bg = nt.nodes.new('ShaderNodeBackground')
amb.inputs['Color'].default_value = (0.86, 0.9, 1.0, 1); amb.inputs['Strength'].default_value = 0.5
bg.inputs['Color'].default_value = (0.01, 0.012, 0.02, 1); bg.inputs['Strength'].default_value = 1.0
nt.links.new(lp.outputs['Is Camera Ray'], mix.inputs[0]); nt.links.new(amb.outputs[0], mix.inputs[1]); nt.links.new(bg.outputs[0], mix.inputs[2])
nt.links.new(mix.outputs[0], outn.inputs[0])
def g2b(v):  # Godot (glTF) frame to Blender: x, -z, y
    return Vector((v[0], -v[2], v[1]))
suns = []
for nm, d, col, e in (('key', (-0.45, -0.70, -0.55), (1.0, 0.96, 0.90), 2.0), ('fill', (0.6, -0.2, 0.75), (0.55, 0.65, 0.85), 0.5)):
    L = bpy.data.lights.new(nm + '559', 'SUN'); L.energy = e * math.pi; L.color = col; L.angle = math.radians(0.5)
    o = bpy.data.objects.new(nm + '559', L); sc.collection.objects.link(o)
    o.rotation_euler = g2b(Vector(d)).normalized().to_track_quat('-Z', 'Y').to_euler(); suns.append((L, e * math.pi))
cam = bpy.data.cameras.new('c559'); co = bpy.data.objects.new('c559', cam); sc.collection.objects.link(co); sc.camera = co
cam.sensor_fit = 'VERTICAL'; cam.angle_y = math.radians(45.0); cam.clip_start = 0.001 * k * 10; cam.clip_end = 5000 * k
b = 0.98
dirv = g2b(Vector((0.0, math.cos(b), math.sin(b))))
def shot(r, name):
    co.location = ctr + dirv * (r * k)
    co.rotation_euler = (ctr - co.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = os.path.join(OUT, f'{TAG}_{name}.png'); bpy.ops.render.render(write_still=True); print('[559b] shot', name, flush=True)
shot(170.0, 'b170'); shot(60.0, 'b60')
for L, e in suns: L.energy = 0.0
amb.inputs['Strength'].default_value = 0.0
shot(170.0, 'blights170'); shot(60.0, 'blights60')
print('[559b] done', flush=True)
