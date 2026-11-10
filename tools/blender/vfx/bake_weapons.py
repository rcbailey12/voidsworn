"""Mantaflow gas cache and Cycles GPU channel renders for issue 281 weapon vent gas.

blender -b -t 8 -P bake_weapons.py -- OUT [--resolution 64] [--tile 512]

Two flipbooks, baked the same way as the issue 137 ship deaths so the muzzle and impact vent gas
reads at the same quality bar instead of the old pale puff:

  muzzle  a fast forward jet of hot gas with a bright core that cools and thins (Cone B shape).
  impact  a tight burst along the surface normal: a bright core, short smoke, no wide ball.

Simulation is CPU Mantaflow; the transparent volume renders require an RTX GPU. Temporary caches stay
in OUT. Pack with pack_weapons.py. The runtime shades these through the death flipbook shader, so the
channel names (color, flow, thickness) and cell layout stay identical to bake_death.py.
"""
import argparse, json, math, pathlib, sys, time
import bpy
from mathutils import Vector

p = argparse.ArgumentParser(); p.add_argument('out'); p.add_argument('--resolution', type=int, default=64); p.add_argument('--tile',type=int,default=512)
a = p.parse_args(sys.argv[sys.argv.index('--')+1:]); out = pathlib.Path(a.out); out.mkdir(parents=True,exist_ok=True)
start = time.time(); records = []

# Each kind: name, sphere radius, initial velocity speed, velocity direction, sphere offset, dissolve
# speed, inflow on/off frames, emission strength, emission colour. All buoyancy/gravity disabled
# (space). The ortho camera looks down -Z, so the jet and burst travel in the XY plane (mostly +Y):
# a directional cone in the render maps to the muzzle axis once the runtime billboards it.
KINDS = {
    'muzzle': dict(radius=.18, speed=5.0, coord=(0, 4.0, 0), offset=(0, -.55, 0), dissolve=20, on=(1, 3), off=4,
                   emission=1.7, ecol=(1.0, .52, .14, 1)),
    'impact': dict(radius=.30, speed=2.4, coord=(0, 1.6, 0), offset=(0, 0, 0), dissolve=18, on=(1, 2), off=3,
                   emission=1.4, ecol=(.95, .55, .18, 1)),
}

for kind, cfg in KINDS.items():
    bpy.ops.wm.read_factory_settings(use_empty=True); sc=bpy.context.scene
    sc.frame_start=1; sc.frame_end=32; sc.render.fps=30; sc.gravity=(0,0,0)
    bpy.ops.mesh.primitive_cube_add(size=4, location=(0,0,0)); dom=bpy.context.object; dom.name='gas_'+kind
    mod=dom.modifiers.new('Mantaflow','FLUID'); mod.fluid_type='DOMAIN'; ds=mod.domain_settings
    ds.domain_type='GAS'; ds.resolution_max=a.resolution; ds.use_adaptive_domain=False
    ds.alpha=0; ds.beta=0; ds.vorticity=.28; ds.gravity=(0,0,0); ds.use_noise=False
    ds.use_dissolve_smoke=True; ds.dissolve_speed=cfg['dissolve']; ds.use_dissolve_smoke_log=True
    for side in ['front','back','right','left','top','bottom']: setattr(ds,'use_collision_border_'+side,False)
    folder=out/kind; folder.mkdir(exist_ok=True); ds.cache_type='ALL'; ds.cache_directory=str(folder/'cache'); ds.cache_frame_end=32
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=cfg['radius'],location=cfg['offset'])
    src=bpy.context.object; fm=src.modifiers.new('gas source','FLUID'); fm.fluid_type='FLOW'; fs=fm.flow_settings
    fs.flow_type='SMOKE'; fs.flow_behavior='INFLOW'; fs.density=1.6; fs.temperature=0; fs.surface_distance=1.5
    fs.use_initial_velocity=True; fs.velocity_normal=cfg['speed']; fs.velocity_coord=cfg['coord']
    fs.use_inflow=True; fs.keyframe_insert('use_inflow',frame=1); fs.keyframe_insert('use_inflow',frame=cfg['on'][1])
    fs.use_inflow=False; fs.keyframe_insert('use_inflow',frame=cfg['off'])
    bpy.context.view_layer.objects.active=dom; bpy.ops.object.select_all(action='DESELECT'); dom.select_set(True)
    print('MANTAFLOW_BAKE',kind,flush=True); bpy.ops.fluid.bake_all(); src.hide_render=True
    sc.render.engine='CYCLES'; sc.cycles.samples=16; sc.cycles.use_denoising=True
    prefs=bpy.context.preferences.addons['cycles'].preferences; prefs.compute_device_type='OPTIX'; prefs.get_devices()
    devices=[d for d in prefs.devices if d.type=='OPTIX']
    if not devices: raise RuntimeError('GPU required for channel rendering')
    for dev in prefs.devices: dev.use=dev.type=='OPTIX'
    sc.cycles.device='GPU'; print('CYCLES_GPU',[(d.name,d.type) for d in devices],flush=True)
    sc.render.resolution_x=a.tile; sc.render.resolution_y=a.tile; sc.render.resolution_percentage=100
    sc.render.film_transparent=True; sc.render.image_settings.file_format='PNG'; sc.render.image_settings.color_mode='RGBA'; sc.render.image_settings.color_depth='8'
    sc.view_settings.view_transform='Standard'; sc.view_settings.look='None'
    sc.world=bpy.data.worlds.new('violet ambient'); sc.world.use_nodes=True; sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.10,.075,.15,1); sc.world.node_tree.nodes['Background'].inputs[1].default_value=.35
    camd=bpy.data.cameras.new('orthographic'); camd.type='ORTHO'; camd.ortho_scale=4.0
    cam=bpy.data.objects.new('camera',camd); sc.collection.objects.link(cam); cam.location=(0,0,8); sc.camera=cam
    ld=bpy.data.lights.new('baked key','AREA'); ld.energy=650; ld.size=4; light=bpy.data.objects.new('key',ld); sc.collection.objects.link(light); light.location=(-3,2,5); light.rotation_euler=(Vector((0,0,0))-light.location).to_track_quat('-Z','Y').to_euler()
    mat=bpy.data.materials.new('density thickness and lit gas'); mat.use_nodes=True; nt=mat.node_tree; nt.nodes.clear()
    output=nt.nodes.new('ShaderNodeOutputMaterial'); vol=nt.nodes.new('ShaderNodeVolumePrincipled'); density=nt.nodes.new('ShaderNodeAttribute'); density.attribute_name='density'
    mul=nt.nodes.new('ShaderNodeMath'); mul.operation='MULTIPLY'; mul.inputs[1].default_value=3.0
    nt.links.new(density.outputs['Fac'],mul.inputs[0]); nt.links.new(mul.outputs[0],vol.inputs['Density']); vol.inputs['Color'].default_value=(.60,.56,.70,1)
    vol.inputs['Emission Color'].default_value=cfg['ecol']
    em=nt.nodes.new('ShaderNodeMath'); em.operation='MULTIPLY'; em.inputs[1].default_value=cfg['emission']
    nt.links.new(density.outputs['Fac'],em.inputs[0]); nt.links.new(em.outputs[0],vol.inputs['Emission Strength']); nt.links.new(vol.outputs[0],output.inputs['Volume'])
    dom.data.materials.clear(); dom.data.materials.append(mat)
    for i in range(16):
        fr=1+i*2; sc.frame_set(fr); sc.render.filepath=str(folder/('lit_%02d.png'%i)); bpy.ops.render.render(write_still=True)
    records.append(dict(kind=kind,resolution=a.resolution,frames=16,simulation_frames=32,buoyancy=0,gravity=[0,0,0],device=[d.name for d in devices]))
    print('BAKE_DONE',kind,flush=True)
(out/'bake.json').write_text(json.dumps(dict(records=records,seconds=time.time()-start),indent=2))
