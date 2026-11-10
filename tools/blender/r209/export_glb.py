# Issue 209 round 2: export a cell to one glb for the Godot cost runs (LOD addendum). Every mesh is joined into one object
# with its modifiers applied (the hull skin included), so the draw calls are the surfaces: one per material. The round 6 paint is a
# Blender procedural with no game export yet, so each band becomes a flat game material (light enough to judge LOD pops by eye);
# the bake cell (Ab) keeps its baked normal map and AO (glTF occlusion), so its texture cost is in the reading.
# usage: blender -b CELL.blend -P export_glb.py -- OUT.glb
import sys, os, bpy
OUT = sys.argv[sys.argv.index('--') + 1]
FLAT = {0: (.10, .10, .11), 1: (.20, .21, .23), 2: (.45, .07, .035), 3: (.32, .33, .35)}

def gltf_output_group():
    ng = bpy.data.node_groups.get('glTF Material Output')
    if ng is None:
        ng = bpy.data.node_groups.new('glTF Material Output', 'ShaderNodeTree')
        ng.interface.new_socket('Occlusion', in_out='INPUT', socket_type='NodeSocketFloat')
    return ng

def game_mat(src):
    nm = src.name if src else 'none'; band = int(src.get('round4_band', -1)) if src else -1
    m = bpy.data.materials.new('g_' + nm); m.use_nodes = True; nt = m.node_tree; bs = nt.nodes['Principled BSDF']
    bs.inputs['Roughness'].default_value = .7; bs.inputs['Metallic'].default_value = .15
    if 'interior' in nm: col = (.03, .025, .022)
    elif band == 12: col = (.05, .02, .01); bs.inputs['Emission Color'].default_value = (1.5, .06, .006, 1); bs.inputs['Emission Strength'].default_value = 2.2
    else: col = FLAT.get(band, (.2, .2, .2))
    bs.inputs['Base Color'].default_value = (*col, 1)
    if nm.endswith('_Ab'):  # the baked maps of the bake cell
        uv = nt.nodes.new('ShaderNodeUVMap')
        tn = nt.nodes.new('ShaderNodeTexImage'); tn.image = bpy.data.images['Ab_normal']; tn.image.colorspace_settings.name = 'Non-Color'
        nmap = nt.nodes.new('ShaderNodeNormalMap'); nt.links.new(uv.outputs[0], tn.inputs[0]); nt.links.new(tn.outputs[0], nmap.inputs['Color'])
        nt.links.new(nmap.outputs[0], bs.inputs['Normal'])
        ta = nt.nodes.new('ShaderNodeTexImage'); ta.image = bpy.data.images['Ab_ao']; ta.image.colorspace_settings.name = 'Non-Color'
        nt.links.new(uv.outputs[0], ta.inputs[0]); sep = nt.nodes.new('ShaderNodeSeparateColor'); nt.links.new(ta.outputs[0], sep.inputs[0])
        g = nt.nodes.new('ShaderNodeGroup'); g.node_tree = gltf_output_group(); nt.links.new(sep.outputs[0], g.inputs['Occlusion'])
    return m

sc = bpy.context.scene
meshes = [o for o in sc.objects if o.type == 'MESH' and not o.hide_render]
for o in meshes:
    bpy.context.view_layer.objects.active = o
    for md in list(o.modifiers):
        try: bpy.ops.object.modifier_apply(modifier=md.name)
        except Exception: o.modifiers.remove(md)
cache = {}
for o in meshes:
    for i, s in enumerate(o.material_slots):
        k = s.material.name if s.material else 'none'
        if k not in cache: cache[k] = game_mat(s.material)
        s.material = cache[k]
bpy.ops.object.select_all(action='DESELECT')
for o in meshes: o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]; bpy.ops.object.join()
o = bpy.context.view_layer.objects.active; o.name = os.path.basename(OUT)[:-4]
# merge slots that point at the same game material, so surfaces = distinct materials
bpy.ops.object.material_slot_remove_unused()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_apply=True, export_yup=True)
me = o.data; me.calc_loop_triangles()
print('[209] export', OUT, 'triangles', len(me.loop_triangles), 'materials', len([s for s in o.material_slots if s.material]), flush=True)
