"""T2 sheet materials. Production mask/trim bake is deliberately not claimed.

Colours are a Hegemony station palette, not the Hullbreaker or Eclipse stack.
The sheet uses bevel geometry and an AO shader to expose the proposed finish.
The production paint bake must follow sheet approval through recipe stage 5.
"""
import bpy

ZONES = {'plate':(.30,.33,.35), 'plate2':(.40,.43,.44), 'trim':(.085,.14,.19),
         'edge':(.22,.25,.27), 'liner':(.018,.024,.030), 'deck':(.10,.12,.13),
         'frame':(.19,.22,.24), 'rack':(.045,.065,.085), 'recess':(.009,.015,.019),
         'blue':(.18,.52,1.0), 'battery':(.28,.105,.025), 'frost':(.40,.45,.47)}


def materials():
    mats={}
    for zone,rgb in ZONES.items():
        m=bpy.data.materials.new('T2_'+zone); m.use_nodes=True
        m.diffuse_color=(*rgb,1); m['rim_soft']=True
        nodes=m.node_tree.nodes; links=m.node_tree.links
        bs=nodes.get('Principled BSDF')
        bs.inputs['Base Color'].default_value=(*rgb,1)
        bs.inputs['Metallic'].default_value=.45
        bs.inputs['Roughness'].default_value=.72
        if zone in ('blue','battery'):
            bs.inputs['Emission Color'].default_value=(*rgb,1)
            bs.inputs['Emission Strength'].default_value=1.4 if zone=='blue' else .45
            bs.inputs['Metallic'].default_value=.0
        elif zone not in ('liner','recess'):
            ao=nodes.new('ShaderNodeAmbientOcclusion'); ao.inputs['Distance'].default_value=.65
            ao.inputs['Color'].default_value=(*rgb,1)
            links.new(ao.outputs['Color'],bs.inputs['Base Color'])
        mats[zone]=m
    return mats
