"""R103: three broad coat values, dark cavities and thin geometric edge wear."""
import bpy
import round5_material as previous

# Linear values. Bands describe real parts, never a noise threshold.
PALETTE = [(.0018,.0020,.0023),(.0080,.0090,.0105),(.30,.024,.013),
           (.026,.029,.032),(.0080,.0090,.0105)] + [(.0080,.0090,.0105)]*8
node=previous.node
mathnode=previous.mathnode
mix=previous.mix
unique_uv=previous.unique_uv


def make_material(pc,band,variation=0):
    mat=bpy.data.materials.new('round6_simple_'+str(band));mat.use_nodes=True
    nt=mat.node_tree;nt.nodes.clear()
    output=node(nt,'ShaderNodeOutputMaterial')
    bs=node(nt,'ShaderNodeBsdfPrincipled');nt.links.new(bs.outputs[0],output.inputs[0])
    geo=node(nt,'ShaderNodeNewGeometry')
    ao=node(nt,'ShaderNodeAmbientOcclusion',samples=12,inside=False,only_local=True)
    ao.inputs['Distance'].default_value=.009
    cavity=mathnode(nt,'ADD',mathnode(nt,'MULTIPLY',ao.outputs['AO'],.85),.15)
    base=node(nt,'ShaderNodeRGB')
    tint=PALETTE[band] if band<len(PALETTE) else PALETTE[1]
    base.outputs[0].default_value=(*tint,1)
    dirty=node(nt,'ShaderNodeMixRGB',blend_type='MULTIPLY');dirty.inputs[0].default_value=1
    nt.links.new(base.outputs[0],dirty.inputs[1]);nt.links.new(cavity,dirty.inputs[2])
    # Bevel-normal difference confines rust to a narrow real edge. No
    # pointiness interpolation, rust speckle, photo grain or broad scorch.
    bevel=node(nt,'ShaderNodeBevel',samples=3);bevel.inputs['Radius'].default_value=.00016
    dot=node(nt,'ShaderNodeVectorMath',operation='DOT_PRODUCT')
    nt.links.new(geo.outputs['Normal'],dot.inputs[0]);nt.links.new(bevel.outputs['Normal'],dot.inputs[1])
    edge=mathnode(nt,'MULTIPLY',mathnode(nt,'SUBTRACT',1,dot.outputs['Value']),18)
    edge=mathnode(nt,'MINIMUM',mathnode(nt,'MAXIMUM',edge,0),.45)
    colour=mix(nt,dirty.outputs[0],(.065,.023,.014,1),edge)
    if band in [8,12]:colour=dirty.outputs[0]
    nt.links.new(colour,bs.inputs['Base Color'])
    rough=mathnode(nt,'ADD',mathnode(nt,'MULTIPLY',ao.outputs['AO'],-.09),.84)
    metal=mathnode(nt,'ADD',mathnode(nt,'MULTIPLY',edge,.55),.10)
    nt.links.new(rough,bs.inputs['Roughness']);nt.links.new(metal,bs.inputs['Metallic'])
    emission=node(nt,'ShaderNodeRGB')
    emission.outputs[0].default_value=(.35,.001,0,1) if band==8 else ((1.5,.06,.006,1) if band==12 else (0,0,0,1))
    nt.links.new(emission.outputs[0],bs.inputs['Emission Color']);bs.inputs['Emission Strength'].default_value=2.2
    combine=node(nt,'ShaderNodeCombineColor',mode='RGB')
    nt.links.new(ao.outputs['AO'],combine.inputs[0]);nt.links.new(rough,combine.inputs[1]);nt.links.new(metal,combine.inputs[2])
    mat['round4_band']=band
    return mat,dict(base=colour,orm=combine.outputs[0],emission=emission.outputs[0]),[]


def bake(obj,pc,folder,lib,res=4096,donor_normal=None,keep_uv=False):
    result=previous.bake(obj,pc,folder,lib,res=res,donor_normal=None,keep_uv=keep_uv)
    result.update(version=18701,method='Three coat values on geometric masses and parts; local AO; thin bevel edge rust; no photo or noise',
                  photo=None,donor_normal=False)
    obj.data.materials[0].name='round6_simple_baked_PBR'
    # Soot has a weak dielectric reflection. The old default kept a bright
    # grey reflection over even near-black albedo under the fixed G4 sky.
    bs=next(n for n in obj.data.materials[0].node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Specular IOR Level'].default_value=.12
    result['coat_specular_ior_level']=.12
    result['coat_linear']={str(i):PALETTE[i] for i in [0,1,3]}
    return result
