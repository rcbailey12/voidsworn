# Voidsworn explosion flipbooks: Mantaflow fire+smoke sims rendered as tintable channel frames.
# usage: blender -b --factory-startup -P fxsim.py -- <out_dir> <variant> [res] [frames]
#   writes <out_dir>/<variant>/flame_####.png (fire emission, greyscale) and smoke_####.png (smoke density, greyscale), camera looks straight down the sim.
# variants: fireball (big round burst), burst (fast small blast), plasma (wobbly bulging blob, little smoke), smoke (slow lingering puff), debris (sparky blast with streaks)
import sys, os, math
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
OUT, VAR = argv[0], argv[1]; RES = int(argv[2]) if len(argv) > 2 else 128; FR = int(argv[3]) if len(argv) > 3 else 48
import bpy
V = {
 'fireball': dict(fuel=1.6, temp=2.2, smoke=1.0, vort=.25, burn=.9, flame_v=1.2, size=.35, vel=10.0, dissolve=24, noise=.5),
 'burst':    dict(fuel=1.0, temp=2.6, smoke=.6, vort=.35, burn=1.6, flame_v=1.6, size=.22, vel=18.0, dissolve=14, noise=.7),
 'plasma':   dict(fuel=1.4, temp=1.6, smoke=.15, vort=.6, burn=.5, flame_v=.8, size=.3, vel=5.0, dissolve=30, noise=1.0),
 'smoke':    dict(fuel=.3, temp=.6, smoke=1.6, vort=.2, burn=.3, flame_v=.4, size=.3, vel=4.0, dissolve=60, noise=.4),
 'debris':   dict(fuel=1.2, temp=2.4, smoke=.8, vort=.4, burn=1.2, flame_v=1.4, size=.2, vel=22.0, dissolve=18, noise=.8),
}[VAR]
bpy.ops.wm.read_factory_settings(use_empty=True); sc = bpy.context.scene
sc.frame_start, sc.frame_end = 1, FR
# domain: cube 4 units, open boundaries, no gravity (space)
bpy.ops.mesh.primitive_cube_add(size=4); dom = bpy.context.active_object; dom.name = 'domain'
m = dom.modifiers.new('fluid', 'FLUID'); m.fluid_type = 'DOMAIN'; d = m.domain_settings
d.domain_type = 'GAS'; d.resolution_max = RES; d.use_adaptive_domain = False
for side in ('use_collision_border_front', 'use_collision_border_back', 'use_collision_border_right', 'use_collision_border_left', 'use_collision_border_top', 'use_collision_border_bottom'): setattr(d, side, False)
d.gravity = (0, 0, 0); d.use_dissolve_smoke = True; d.dissolve_speed = V['dissolve']; d.vorticity = V['vort']
d.burning_rate = V['burn']; d.flame_vorticity = V['flame_v']; d.flame_max_temp = V['temp'] * 1.5; d.use_noise = True; d.noise_scale = 2; d.noise_strength = V['noise']
d.cache_type = 'ALL'; d.cache_directory = os.path.join(OUT, VAR, 'cache'); d.cache_frame_end = FR
# emitter: sphere that emits fire+smoke for a few frames with an outward kick
bpy.ops.mesh.primitive_uv_sphere_add(radius=V['size'], segments=24, ring_count=12); fl = bpy.context.active_object; fl.name = 'flow'
f = fl.modifiers.new('fluid', 'FLUID'); f.fluid_type = 'FLOW'; s = f.flow_settings
s.flow_type = 'BOTH'; s.flow_behavior = 'INFLOW'; s.fuel_amount = V['fuel']; s.temperature = V['temp']; s.density = V['smoke']
s.use_initial_velocity = True; s.velocity_normal = V['vel']; s.surface_distance = .3; s.subframes = 2
# emit only for the first frames
s.use_inflow = True; s.keyframe_insert('use_inflow', frame=1); s.keyframe_insert('use_inflow', frame=4)
s.use_inflow = False; s.keyframe_insert('use_inflow', frame=5)
bpy.context.view_layer.objects.active = dom; bpy.ops.object.select_all(action='DESELECT'); dom.select_set(True)
print('[fx] baking', VAR, RES, FR, flush=True)
bpy.ops.fluid.bake_all()
print('[fx] baked', flush=True)
fl.hide_render = True
# render setup: orthographic top camera, black world, Cycles GPU
cam_d = bpy.data.cameras.new('cam'); cam_d.type = 'ORTHO'; cam_d.ortho_scale = 3.2; cam = bpy.data.objects.new('cam', cam_d); sc.collection.objects.link(cam)
cam.location = (0, 0, 10); cam.rotation_euler = (0, 0, 0); sc.camera = cam
sc.world = bpy.data.worlds.new('w'); sc.world.use_nodes = True; sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0
sc.render.engine = 'CYCLES'; sc.cycles.samples = 24; sc.render.resolution_x = sc.render.resolution_y = int(os.environ.get('FX_PX', '256')); sc.render.film_transparent = False
sc.view_settings.view_transform = 'Standard'; sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'BW'
try:
    pr = bpy.context.preferences.addons['cycles'].preferences
    for t in ('OPTIX', 'CUDA'):
        pr.compute_device_type = t; pr.get_devices()
        if any(x.type == t for x in pr.devices):
            for x in pr.devices: x.use = x.type == t
            sc.cycles.device = 'GPU'; break
except Exception: pass
mat = bpy.data.materials.new('vol'); mat.use_nodes = True; nt = mat.node_tree; nt.nodes.clear()
outn = nt.nodes.new('ShaderNodeOutputMaterial'); emi = nt.nodes.new('ShaderNodeEmission'); att = nt.nodes.new('ShaderNodeAttribute')
mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; vol = nt.nodes.new('ShaderNodeVolumePrincipled')
nt.links.new(att.outputs['Fac'], mul.inputs[0]); nt.links.new(mul.outputs[0], emi.inputs['Strength']); nt.links.new(emi.outputs[0], outn.inputs['Volume'])
dom.data.materials.clear(); dom.data.materials.append(mat)
for chan, attr, gain in (('flame', 'flame', 6.0), ('smoke', 'density', 3.0)):
    att.attribute_name = attr; mul.inputs[1].default_value = gain
    os.makedirs(os.path.join(OUT, VAR), exist_ok=True)
    for fr in range(1, FR + 1):
        sc.frame_set(fr); sc.render.filepath = os.path.join(OUT, VAR, '%s_%04d.png' % (chan, fr)); bpy.ops.render.render(write_still=True)
    print('[fx] rendered', chan, flush=True)
print('[fx] DONE', VAR, flush=True)
