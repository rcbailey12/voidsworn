"""Geometry-driven Hullbreaker PBR, baked once into unique UVs.

Photo microstructure is CC0 ambientCG from the already installed library.
No generated reference, AI texture, light render or projected paint is sampled.
"""
import math
from pathlib import Path
import time

import bpy
import numpy as np

PALETTE = [(.006,.0055,.005),(.004,.0045,.005),(.28,.044,.024),
           (.018,.020,.021),(.030,.025,.020),(.023,.048,.074),
           (.32,.29,.20),(.020,.04,.026),(.42,.016,.005),
           (.23,.21,.16),(.025,.053,.085),(.025,.052,.030),(.7,.015,.005)]


def node(nt, kind, **values):
    n=nt.nodes.new(kind)
    for k,v in values.items():setattr(n,k,v)
    return n


def mathnode(nt, op, a, b):
    n=node(nt,'ShaderNodeMath',operation=op)
    for i,value in enumerate([a,b]):
        if isinstance(value,(float,int)):n.inputs[i].default_value=value
        else:nt.links.new(value,n.inputs[i])
    return n.outputs[0]


def mix(nt, a, b, factor):
    n=node(nt,'ShaderNodeMixRGB',blend_type='MIX')
    for socket,value in zip(n.inputs,[factor,a,b]):
        if hasattr(value,'node'):nt.links.new(value,socket)
        else:socket.default_value=value
    return n.outputs[0]


def make_material(pc, band, variation=0):
    mat=bpy.data.materials.new('round5_smart_'+str(band)+'_'+str(variation));mat.use_nodes=True
    nt=mat.node_tree;nt.nodes.clear()
    output=node(nt,'ShaderNodeOutputMaterial')
    bs=node(nt,'ShaderNodeBsdfPrincipled');nt.links.new(bs.outputs[0],output.inputs[0])
    pos=node(nt,'ShaderNodeNewGeometry')
    scale=node(nt,'ShaderNodeVectorMath',operation='SCALE');scale.inputs[3].default_value=2.2
    nt.links.new(pos.outputs['Position'],scale.inputs[0])
    noise=node(nt,'ShaderNodeTexNoise');noise.inputs['Scale'].default_value=85
    noise.inputs['Detail'].default_value=4;noise.inputs['Roughness'].default_value=.72
    nt.links.new(pos.outputs['Position'],noise.inputs['Vector'])
    fine=node(nt,'ShaderNodeTexNoise');fine.inputs['Scale'].default_value=1100
    fine.inputs['Detail'].default_value=2;nt.links.new(pos.outputs['Position'],fine.inputs['Vector'])
    texture_root=pc/'textures/PaintedMetal004'
    image_paths=[]
    photos={}
    for name,suffix in [('rough','Roughness'),('grain','Displacement'),('tone','Color')]:
        path=texture_root/('PaintedMetal004_2K-JPG_'+suffix+'.jpg');assert path.exists()
        tex=node(nt,'ShaderNodeTexImage',projection='BOX',projection_blend=.25)
        tex.image=bpy.data.images.load(str(path),check_existing=True)
        tex.image.colorspace_settings.name='sRGB' if name=='tone' else 'Non-Color'
        nt.links.new(scale.outputs[0],tex.inputs[0]);photos[name]=tex.outputs['Color'];image_paths.append(str(path))
    grey=node(nt,'ShaderNodeRGBToBW');nt.links.new(photos['tone'],grey.inputs[0])
    modulation=mathnode(nt,'ADD',mathnode(nt,'MULTIPLY',grey.outputs[0],1.4),.38)
    ao=node(nt,'ShaderNodeAmbientOcclusion',samples=12,inside=False,only_local=True)
    ao.inputs['Distance'].default_value=.009
    cavity=mathnode(nt,'ADD',mathnode(nt,'MULTIPLY',ao.outputs['AO'],.72),.28)
    tint=np.array(PALETTE[band])*(.70+variation*.14)
    base=node(nt,'ShaderNodeRGB');base.outputs[0].default_value=(*tint,1)
    multiply=node(nt,'ShaderNodeMixRGB',blend_type='MULTIPLY');multiply.inputs[0].default_value=1
    nt.links.new(base.outputs[0],multiply.inputs[1]);nt.links.new(modulation,multiply.inputs[2])
    dirty=node(nt,'ShaderNodeMixRGB',blend_type='MULTIPLY');dirty.inputs[0].default_value=1
    nt.links.new(multiply.outputs[0],dirty.inputs[1]);nt.links.new(cavity,dirty.inputs[2])
    # Convex curvature admits thin chips; AO puts dark grime in real recesses.
    ramp=node(nt,'ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position=.545;ramp.color_ramp.elements[1].position=.65
    nt.links.new(pos.outputs['Pointiness'],ramp.inputs[0])
    # Pointiness alone interpolates across a four-corner flat panel. Bound it
    # with a real short-radius bevel-normal change so whole faces cannot chip.
    bevel=node(nt,'ShaderNodeBevel',samples=3);bevel.inputs['Radius'].default_value=.00065
    dot=node(nt,'ShaderNodeVectorMath',operation='DOT_PRODUCT')
    nt.links.new(pos.outputs['Normal'],dot.inputs[0]);nt.links.new(bevel.outputs['Normal'],dot.inputs[1])
    edge=mathnode(nt,'MULTIPLY',mathnode(nt,'SUBTRACT',1,dot.outputs['Value']),96)
    edge=mathnode(nt,'MINIMUM',mathnode(nt,'MAXIMUM',edge,0),1)
    curve=mathnode(nt,'ADD',mathnode(nt,'MULTIPLY',ramp.outputs[0],.7),.3)
    wear=mathnode(nt,'MULTIPLY',mathnode(nt,'MULTIPLY',edge,curve),mathnode(nt,'GREATER_THAN',noise.outputs['Fac'],.52))
    # Rust is an irregular mask within each plate, never a whole-plate band.
    rust=node(nt,'ShaderNodeValToRGB')
    rust.color_ramp.elements[0].position=.58
    rust.color_ramp.elements[1].position=.605
    nt.links.new(noise.outputs['Fac'],rust.inputs[0])
    rustmask=mathnode(nt,'MAXIMUM',rust.outputs['Color'],mathnode(nt,'MULTIPLY',edge,.50))
    rustmask=mathnode(nt,'MULTIPLY',rustmask,.72 if band in [0,1,3,4] else .18)
    base_socket=mix(nt,dirty.outputs[0],(.09,.022,.015,1),rustmask)
    base_socket=mix(nt,base_socket,(.24,.255,.26,1),mathnode(nt,'MULTIPLY',wear,.70))
    # A separate broad field leaves readable soot and scorch at close zoom.
    broad=node(nt,'ShaderNodeTexNoise');broad.inputs['Scale'].default_value=24
    broad.inputs['Detail'].default_value=3
    nt.links.new(pos.outputs['Position'],broad.inputs['Vector'])
    scorch=mathnode(nt,'MULTIPLY',mathnode(nt,'GREATER_THAN',broad.outputs['Fac'],.61),.72)
    base_socket=mix(nt,base_socket,(.0015,.0015,.0015,1),scorch)
    # Natural scratches must survive the UV bake. The former 28 repeats per
    # hull put the photo grain below a texel and averaged it into flat colour.
    scratches=node(nt,'ShaderNodeValToRGB')
    scratches.color_ramp.elements[0].position=.29
    scratches.color_ramp.elements[1].position=.49
    nt.links.new(grey.outputs[0],scratches.inputs[0])
    scuff=mathnode(nt,'MULTIPLY',scratches.outputs['Color'],.36)
    if band not in [8,12]:base_socket=mix(nt,base_socket,(.12,.125,.12,1),scuff)
    if band==6:
        wave=node(nt,'ShaderNodeTexWave',bands_direction='DIAGONAL')
        wave.inputs['Scale'].default_value=8;wave.inputs['Distortion'].default_value=1.2
        nt.links.new(scale.outputs[0],wave.inputs['Vector'])
        base_socket=mix(nt,base_socket,(.023,.025,.023,1),mathnode(nt,'GREATER_THAN',wave.outputs['Color'],.5))
    rough=mathnode(nt,'ADD',mathnode(nt,'MULTIPLY',photos['rough'],.27),.61)
    metal=mix(nt,(.07,.07,.07,1),(.76,.76,.76,1),wear)
    nt.links.new(base_socket,bs.inputs['Base Color']);nt.links.new(rough,bs.inputs['Roughness'])
    nt.links.new(metal,bs.inputs['Metallic'])
    bump=node(nt,'ShaderNodeBump');bump.inputs['Strength'].default_value=.45
    bump.inputs['Distance'].default_value=.00065;nt.links.new(photos['grain'],bump.inputs['Height'])
    micro=node(nt,'ShaderNodeBump');micro.inputs['Strength'].default_value=.25
    micro.inputs['Distance'].default_value=.00008;nt.links.new(fine.outputs['Fac'],micro.inputs['Height'])
    nt.links.new(bump.outputs[0],micro.inputs['Normal']);nt.links.new(micro.outputs[0],bs.inputs['Normal'])
    emission=node(nt,'ShaderNodeRGB')
    emission.outputs[0].default_value=(.35,.001,0,1) if band==8 else ((1.5,.06,.006,1) if band==12 else (0,0,0,1))
    nt.links.new(emission.outputs[0],bs.inputs['Emission Color']);bs.inputs['Emission Strength'].default_value=2.2
    combine=node(nt,'ShaderNodeCombineColor',mode='RGB')
    nt.links.new(ao.outputs['AO'],combine.inputs[0]);nt.links.new(rough,combine.inputs[1]);nt.links.new(metal,combine.inputs[2])
    mat['round4_band']=band
    return mat,dict(base=base_socket,orm=combine.outputs[0],emission=emission.outputs[0]),image_paths


def unique_uv(obj,lib):
    lib.active(obj)
    while obj.data.uv_layers:obj.data.uv_layers.remove(obj.data.uv_layers[0])
    obj.data.uv_layers.new(name='surface')
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.00015,area_weight=.35)
    bpy.ops.object.mode_set(mode='OBJECT')


def bake(obj,pc,folder,lib,res=4096,donor_normal=None,keep_uv=False):
    start=time.perf_counter();lib.gpu()
    if not keep_uv:unique_uv(obj,lib)
    sc=bpy.context.scene;sc.cycles.samples=16;sc.render.bake.margin=12
    sc.render.bake.use_selected_to_active=False
    materials=list(obj.data.materials)
    maps={};outputs=[];paths=set()
    for mat in materials:
        # Reconstruct shader links from known named outputs in the prepared material.
        nt=mat.node_tree;bs=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED')
        output=next(n for n in nt.nodes if n.type=='OUTPUT_MATERIAL')
        orm=next(n for n in nt.nodes if n.type=='COMBINE_COLOR')
        outputs.append((mat,output,bs,{'base':bs.inputs['Base Color'].links[0].from_socket,
            'orm':orm.outputs[0],'emission':bs.inputs['Emission Color'].links[0].from_socket}))
    for kind in ['base','orm','emission','normal']:
        image=bpy.data.images.new('bake_'+kind,width=res,height=res,alpha=True,float_buffer=False)
        image.colorspace_settings.name='Non-Color' if kind in ['orm','normal'] else 'sRGB'
        for mat,output,bs,sockets in outputs:
            nt=mat.node_tree;tex=node(nt,'ShaderNodeTexImage');tex.image=image;nt.nodes.active=tex
            if kind=='normal':nt.links.new(bs.outputs[0],output.inputs[0])
            else:
                emit=node(nt,'ShaderNodeEmission');nt.links.new(sockets[kind],emit.inputs[0]);nt.links.new(emit.outputs[0],output.inputs[0])
        lib.active(obj)
        bpy.ops.object.bake(type='NORMAL' if kind=='normal' else 'EMIT',normal_space='TANGENT')
        image.filepath_raw=str(folder/(kind+'.png'));image.file_format='PNG';image.save()
        maps[kind]=image
        print('[round4] baked',kind,flush=True)
    # A separately filtered donor bake can be combined with local micro-normal.
    if donor_normal is not None:
        raw=np.empty(res*res*4,np.float32);maps['normal'].pixels.foreach_get(raw)
        local=raw.reshape(res,res,4)[:,:,:3]*2-1
        donor=donor_normal
        combined=np.stack([local[:,:,0]+donor[:,:,0],local[:,:,1]+donor[:,:,1],local[:,:,2]*donor[:,:,2]],2)
        combined/=np.maximum(np.linalg.norm(combined,axis=2,keepdims=True),1e-8)
        maps['normal']=lib.save_image(folder/'normal.png',combined*.5+.5)
    mat=lib.material(folder);mat.name='round5_baked_Hullbreaker_PBR'
    nt=mat.node_tree
    group=bpy.data.node_groups.get('glTF Material Output')
    if group is None:
        group=bpy.data.node_groups.new('glTF Material Output','ShaderNodeTree')
        group.interface.new_socket(name='Occlusion',in_out='INPUT',socket_type='NodeSocketFloat')
    gn=node(nt,'ShaderNodeGroup');gn.node_tree=group
    sep=next(n for n in nt.nodes if n.type=='SEPARATE_COLOR');nt.links.new(sep.outputs['Red'],gn.inputs['Occlusion'])
    obj.data.materials.clear();obj.data.materials.append(mat)
    return dict(version=16303,resolution=res,seconds=time.perf_counter()-start,
        method='unique UV bake of geometry Pointiness wear, short-distance AO grime, position noise scorch, CC0 photo microstructure',
        photo='ambientCG PaintedMetal004, installed CC0 set',projected_paint=False,
        maps={p.name:lib.sha(p) for p in folder.glob('*.png')})
