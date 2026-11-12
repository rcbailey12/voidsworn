# Issue 559: list what each visible material in a .blend is made of (read-only; saves nothing).
# usage: blender -b CELL.blend -P blendmat559.py -- OUT.json
import bpy, sys, json
out = sys.argv[sys.argv.index('--') + 1:][0]
sc = bpy.context.scene
use = {}
for o in sc.objects:
    if o.type != 'MESH' or o.hide_render: continue
    role = o.get('role', '')
    for s in o.material_slots:
        if s.material is None: continue
        u = use.setdefault(s.material.name, {'objects': 0, 'roles': {}, 'tris': 0})
        u['objects'] += 1; u['roles'][role] = u['roles'].get(role, 0) + 1
mats = {}
for name, u in use.items():
    m = bpy.data.materials[name]; d = dict(u); d['nodes'] = {}; d['images'] = []
    if m.use_nodes:
        for n in m.node_tree.nodes:
            d['nodes'][n.bl_idname] = d['nodes'].get(n.bl_idname, 0) + 1
            if n.bl_idname == 'ShaderNodeTexImage' and n.image:
                d['images'].append([n.image.name, list(n.image.size), n.image.colorspace_settings.name, [l.to_socket.name for l in n.outputs['Color'].links]])
        bsdf = next((n for n in m.node_tree.nodes if n.bl_idname == 'ShaderNodeBsdfPrincipled'), None)
        if bsdf:
            d['bsdf_linked'] = [i.name for i in bsdf.inputs if i.is_linked]
            for nm in ('Emission Strength', 'Metallic', 'Roughness'):
                if nm in bsdf.inputs and not bsdf.inputs[nm].is_linked: d[nm] = bsdf.inputs[nm].default_value
    mats[name] = d
json.dump({'materials': mats, 'interior_objects': sum(1 for o in sc.objects if o.get('role') == 'interior'),
           'hidden_render_meshes': sum(1 for o in sc.objects if o.type == 'MESH' and o.hide_render)}, open(out, 'w'), indent=1)
print('[559m] wrote', out, len(mats), flush=True)
