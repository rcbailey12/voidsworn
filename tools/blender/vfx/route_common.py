"""Shared Blender setup for the issue 353 explosion route bakes (bake_route_a.py, bake_route_b.py).

Same camera, cell layout and lighting as bake_death.py and bake_weapons.py (16 frames, orthographic top view of a 4 unit
gas domain, violet ambient, one key light), so the packed atlases drop into the game's flipbook shader. Not run by itself.
"""
import math, time
import bpy
from mathutils import Vector

FRAMES = 32          # simulated frames (30 per second); every second frame is rendered, 16 cells
DOMAIN = 4.0


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.frame_start = 1; sc.frame_end = FRAMES; sc.render.fps = 30; sc.gravity = (0, 0, 0)
    return sc


def domain(name, resolution, cache, dissolve, noise=False, vorticity=.3):
    bpy.ops.mesh.primitive_cube_add(size=DOMAIN, location=(0, 0, 0)); dom = bpy.context.object; dom.name = name
    mod = dom.modifiers.new('Mantaflow', 'FLUID'); mod.fluid_type = 'DOMAIN'; ds = mod.domain_settings
    ds.domain_type = 'GAS'; ds.resolution_max = resolution; ds.use_adaptive_domain = False
    ds.alpha = 0; ds.beta = 0; ds.vorticity = vorticity; ds.gravity = (0, 0, 0)   # space: no buoyancy, no gravity
    ds.use_dissolve_smoke = True; ds.dissolve_speed = dissolve; ds.use_dissolve_smoke_log = True
    for side in ['front', 'back', 'right', 'left', 'top', 'bottom']:
        setattr(ds, 'use_collision_border_' + side, False)
    ds.use_noise = noise
    if noise:
        ds.noise_scale = 2; ds.noise_strength = 1.4; ds.noise_pos_scale = 2.0; ds.noise_time_anim = .2
    ds.cache_type = 'ALL'; ds.cache_directory = str(cache); ds.cache_frame_end = FRAMES
    return dom, ds


def flow(obj, kind, density, speed, coord=(0, 0, 0), on=2, temperature=0.0, fuel=0.0):
    fm = obj.modifiers.new('gas source', 'FLUID'); fm.fluid_type = 'FLOW'; fs = fm.flow_settings
    fs.flow_type = kind; fs.flow_behavior = 'INFLOW'; fs.density = density; fs.temperature = temperature
    if kind in ('FIRE', 'BOTH'):
        fs.fuel_amount = fuel
    fs.surface_distance = 1.5
    fs.use_initial_velocity = True; fs.velocity_normal = speed; fs.velocity_coord = coord
    fs.use_inflow = True; fs.keyframe_insert('use_inflow', frame=1); fs.keyframe_insert('use_inflow', frame=on)
    fs.use_inflow = False; fs.keyframe_insert('use_inflow', frame=on + 1)
    return fs


def bake(dom):
    """Bakes the whole cache (base and, if on, the noise detail). Returns wall-clock seconds."""
    bpy.context.view_layer.objects.active = dom; bpy.ops.object.select_all(action='DESELECT'); dom.select_set(True)
    t = time.time(); bpy.ops.fluid.bake_all(); return time.time() - t


def render_setup(sc, tile, cpu=False, samples=16):
    sc.render.engine = 'CYCLES'; sc.cycles.samples = samples; sc.cycles.use_denoising = not cpu
    names = ['CPU']
    if not cpu:
        prefs = bpy.context.preferences.addons['cycles'].preferences; prefs.compute_device_type = 'OPTIX'; prefs.get_devices()
        devices = [d for d in prefs.devices if d.type == 'OPTIX']
        if not devices:
            raise RuntimeError('GPU required for channel rendering (pass --cpu for a sandbox smoke test)')
        for dev in prefs.devices:
            dev.use = dev.type == 'OPTIX'
        sc.cycles.device = 'GPU'; names = [d.name for d in devices]
    sc.render.resolution_x = tile; sc.render.resolution_y = tile; sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGBA'; sc.render.image_settings.color_depth = '8'
    sc.view_settings.view_transform = 'Standard'; sc.view_settings.look = 'None'
    camd = bpy.data.cameras.new('orthographic'); camd.type = 'ORTHO'; camd.ortho_scale = DOMAIN
    cam = bpy.data.objects.new('camera', camd); sc.collection.objects.link(cam); cam.location = (0, 0, 8); sc.camera = cam
    return names


def world(sc, lit):
    w = bpy.data.worlds.new('ambient'); w.use_nodes = True; bg = w.node_tree.nodes['Background']
    if lit:
        bg.inputs[0].default_value = (.10, .075, .15, 1); bg.inputs[1].default_value = .35
    else:
        bg.inputs[0].default_value = (0, 0, 0, 1); bg.inputs[1].default_value = 0
    sc.world = w


def key_light(sc):
    ld = bpy.data.lights.new('baked key', 'AREA'); ld.energy = 650; ld.size = 4
    light = bpy.data.objects.new('key', ld); sc.collection.objects.link(light); light.location = (-3, 2, 5)
    light.rotation_euler = (Vector((0, 0, 0)) - light.location).to_track_quat('-Z', 'Y').to_euler()
    return light


def smoke_material(dom, colour=(.30, .28, .34), density=4.0):
    """Lit smoke only: absorbs and scatters, no emission."""
    mat = bpy.data.materials.new('route smoke'); mat.use_nodes = True; nt = mat.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); vol = nt.nodes.new('ShaderNodeVolumePrincipled')
    att = nt.nodes.new('ShaderNodeAttribute'); att.attribute_name = 'density'
    mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; mul.inputs[1].default_value = density
    nt.links.new(att.outputs['Fac'], mul.inputs[0]); nt.links.new(mul.outputs[0], vol.inputs['Density'])
    vol.inputs['Color'].default_value = (*colour, 1); vol.inputs['Emission Strength'].default_value = 0
    nt.links.new(vol.outputs[0], out.inputs['Volume'])
    dom.data.materials.clear(); dom.data.materials.append(mat)
    return mat


def fire_material(dom, density=4.0, strength=1.6):
    """Fire only: the flame field glows through a colour ramp (deep red to white); the smoke still absorbs, so fire
    behind thick smoke is hidden as it would be. Rendered on black with no lights."""
    mat = bpy.data.materials.new('route fire'); mat.use_nodes = True; nt = mat.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); vol = nt.nodes.new('ShaderNodeVolumePrincipled')
    den = nt.nodes.new('ShaderNodeAttribute'); den.attribute_name = 'density'
    fl = nt.nodes.new('ShaderNodeAttribute'); fl.attribute_name = 'flame'
    mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; mul.inputs[1].default_value = density
    nt.links.new(den.outputs['Fac'], mul.inputs[0]); nt.links.new(mul.outputs[0], vol.inputs['Density'])
    vol.inputs['Color'].default_value = (0, 0, 0, 1)
    ramp = nt.nodes.new('ShaderNodeValToRGB'); el = ramp.color_ramp.elements
    el[0].position = 0.0; el[0].color = (.45, .05, .01, 1); el[1].position = 1.0; el[1].color = (1, .97, .9, 1)
    e = el.new(.35); e.color = (1, .32, .04, 1); e = el.new(.7); e.color = (1, .78, .30, 1)
    nt.links.new(fl.outputs['Fac'], ramp.inputs['Fac']); nt.links.new(ramp.outputs['Color'], vol.inputs['Emission Color'])
    # Only the hottest part glows hard (flame squared), so the fire is a core inside the gas, not the whole ball.
    sq = nt.nodes.new('ShaderNodeMath'); sq.operation = 'POWER'; sq.inputs[1].default_value = 2.0
    nt.links.new(fl.outputs['Fac'], sq.inputs[0])
    em = nt.nodes.new('ShaderNodeMath'); em.operation = 'MULTIPLY'; em.inputs[1].default_value = strength
    nt.links.new(sq.outputs[0], em.inputs[0]); nt.links.new(em.outputs[0], vol.inputs['Emission Strength'])
    nt.links.new(vol.outputs[0], out.inputs['Volume'])
    dom.data.materials.clear(); dom.data.materials.append(mat)
    return mat


def render_frames(sc, folder, prefix, transparent):
    """16 cells: simulated frames 2, 4, ... 32. Returns wall-clock seconds."""
    sc.render.film_transparent = transparent
    t = time.time()
    for i in range(16):
        sc.frame_set(2 + i * 2); sc.render.filepath = str(folder / ('%s_%02d.png' % (prefix, i)))
        bpy.ops.render.render(write_still=True)
    return time.time() - t
