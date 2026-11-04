"""Mantaflow gas cache and Cycles GPU channel renders for issue 137.

blender -b -t 8 -P bake_death.py -- OUT [--resolution 64] [--tile 512]
Simulation is CPU Mantaflow; the transparent volume renders require an RTX GPU.
Temporary caches stay in OUT, not the repository. Pack with pack_death.py.
"""
import argparse, json, math, pathlib, sys, time
import bpy
from mathutils import Vector

p = argparse.ArgumentParser(); p.add_argument('out'); p.add_argument('--resolution', type=int, default=64); p.add_argument('--tile',type=int,default=512)
a = p.parse_args(sys.argv[sys.argv.index('--')+1:]); out = pathlib.Path(a.out); out.mkdir(parents=True,exist_ok=True)
start = time.time(); records = []
for kind in ['flash','vent','cool']:
    bpy.ops.wm.read_factory_settings(use_empty=True); sc=bpy.context.scene
    sc.frame_start=1; sc.frame_end=32; sc.render.fps=30; sc.gravity=(0,0,0)
    bpy.ops.mesh.primitive_cube_add(size=4, location=(0,0,0)); dom=bpy.context.object; dom.name='gas_'+kind
    mod=dom.modifiers.new('Mantaflow','FLUID'); mod.fluid_type='DOMAIN'; ds=mod.domain_settings
    ds.domain_type='GAS'; ds.resolution_max=a.resolution; ds.use_adaptive_domain=False
    ds.alpha=0; ds.beta=0; ds.vorticity=.28; ds.gravity=(0,0,0); ds.use_noise=False
    ds.use_dissolve_smoke=True; ds.dissolve_speed=12 if kind=='flash' else 26; ds.use_dissolve_smoke_log=True
    for side in ['front','back','right','left','top','bottom']: setattr(ds,'use_collision_border_'+side,False)
    folder=out/kind; folder.mkdir(exist_ok=True); ds.cache_type='ALL'; ds.cache_directory=str(folder/'cache'); ds.cache_frame_end=32
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=.27 if kind=='flash' else .21,location=(0,-.9 if kind=='vent' else 0,0))
    src=bpy.context.object; fm=src.modifiers.new('gas source','FLUID'); fm.fluid_type='FLOW'; fs=fm.flow_settings
    fs.flow_type='SMOKE'; fs.flow_behavior='INFLOW'; fs.density=1.5; fs.temperature=0; fs.surface_distance=1.5
    fs.use_initial_velocity=True; fs.velocity_normal=2.5 if kind=='flash' else .65; fs.velocity_coord=(0,3.0 if kind=='vent' else .25,0)
    fs.use_inflow=True; fs.keyframe_insert('use_inflow',frame=1); fs.keyframe_insert('use_inflow',frame=4 if kind=='vent' else 2)
    fs.use_inflow=False; fs.keyframe_insert('use_inflow',frame=5 if kind=='vent' else 3)
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
    nt.links.new(density.outputs['Fac'],mul.inputs[0]); nt.links.new(mul.outputs[0],vol.inputs['Density']); vol.inputs['Color'].default_value=(.65,.60,.74,1)
    vol.inputs['Emission Color'].default_value=(.55,.68,.9,1) if kind=='flash' else (.13,.10,.2,1)
    em=nt.nodes.new('ShaderNodeMath'); em.operation='MULTIPLY'; em.inputs[1].default_value=2.2 if kind=='flash' else .12
    nt.links.new(density.outputs['Fac'],em.inputs[0]); nt.links.new(em.outputs[0],vol.inputs['Emission Strength']); nt.links.new(vol.outputs[0],output.inputs['Volume'])
    dom.data.materials.clear(); dom.data.materials.append(mat)
    for i in range(16):
        fr=1+i*2; sc.frame_set(fr); sc.render.filepath=str(folder/('lit_%02d.png'%i)); bpy.ops.render.render(write_still=True)
    records.append(dict(kind=kind,resolution=a.resolution,frames=16,simulation_frames=32,buoyancy=0,gravity=[0,0,0],device=[d.name for d in devices]))
    print('BAKE_DONE',kind,flush=True)
(out/'bake.json').write_text(json.dumps(dict(records=records,seconds=time.time()-start),indent=2))
