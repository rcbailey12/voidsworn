# Issue 209 round 3: export a cell with its hand-made LOD chain to one glb for Godot. Four mesh nodes, CELL_lod0 to CELL_lod3, sharing
# the cell's two texture atlases (hull: albedo, ORM, detail normal; parts: albedo, ORM), so a lower LOD costs no extra texture memory.
# The chain is authored by rule from the full ship (so every LOD keeps the same UVs and paint):
#   lod0  everything: hull with its skin, every part, the break structure inside (as rounds 1 and 2 measured)
#   lod1  no interior (bulkheads, decks, ribs) and no hull skin (both are only seen once the ship breaks), parts under 0.012 of the
#         ship's length dropped (bolts, lugs, slats, small accents); generated hero parts kept whole (reducing them threw spikes)
#   lod2  parts under 0.028 dropped, parts over 300 triangles reduced to half, hull to half; in the hybrid the generated hero parts
#         give way to the hand-built parts of the same slots (baked into the same atlas; generated meshes barely reduce, their UV
#         islands are tiny)
#   lod3  parts under 0.05 dropped, the rest to 30 percent, hull to 20 percent (silhouette and paint only)
# usage: blender -b CELL.blend -P export3.py -- OUT.glb
import sys, os, json, bpy
OUT = sys.argv[sys.argv.index('--') + 1]
CELL = os.path.basename(OUT)[:-4]
RULES = [dict(drop=0, interior=True, skin=True, gen=1, part=1, big=1e9, hull=1),
         dict(drop=.012, interior=False, skin=False, gen=1, part=1, big=1e9, hull=1),
         dict(drop=.028, interior=False, skin=False, gen=0, part=.50, big=300, hull=.50),
         dict(drop=.050, interior=False, skin=False, gen=0, part=.30, big=150, hull=.20)]

def occlusion_group():
    ng = bpy.data.node_groups.get('glTF Material Output')
    if ng is None:
        ng = bpy.data.node_groups.new('glTF Material Output', 'ShaderNodeTree')
        ng.interface.new_socket('Occlusion', in_out='INPUT', socket_type='NodeSocketFloat')
    return ng

def add_occlusion(m):
    """the ORM map's red channel (ambient occlusion from the ship's own geometry) into the glTF occlusion slot"""
    nt = m.node_tree; sep = next((n for n in nt.nodes if n.type == 'SEPCOLOR'), None)
    if sep is None or any(n.type == 'GROUP' for n in nt.nodes): return
    g = nt.nodes.new('ShaderNodeGroup'); g.node_tree = occlusion_group(); nt.links.new(sep.outputs[0], g.inputs['Occlusion'])

def tris(o):
    o.data.calc_loop_triangles(); return len(o.data.loop_triangles)

def decimate(o, ratio):
    if ratio >= 1: return
    m = o.modifiers.new('lod', 'DECIMATE'); m.ratio = ratio; m.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = o; bpy.ops.object.modifier_apply(modifier='lod')

sc = bpy.context.scene
src = [o for o in sc.objects if o.type == 'MESH' and (not o.hide_render or o.get('proxy'))]
for m in bpy.data.materials:
    if m.get('p3_textured'): add_occlusion(m)
made = []; info = {}
for k, R in enumerate(RULES):
    keep = []
    for o in src:
        role = o.get('role', 'part'); kind = str(o.get('kind', '')); size = float(o.get('size', 1.0))
        if role == 'interior' and not R['interior']: continue
        if role != 'hull' and size < R['drop']: continue
        if o.get('proxy') and k < 2: continue           # the hybrid: generated hero parts up close (lod0, lod1) ...
        if kind.startswith('gen_') and k >= 2: continue  # ... and the hand-built parts in the same slots further out
        c = o.copy(); c.data = o.data.copy(); sc.collection.objects.link(c)
        if role == 'hull' and not R['skin'] and c.modifiers.get('skin'): c.modifiers.remove(c.modifiers['skin'])
        bpy.context.view_layer.objects.active = c
        for md in list(c.modifiers):
            try: bpy.ops.object.modifier_apply(modifier=md.name)
            except Exception: c.modifiers.remove(md)
        t0 = tris(c)
        if role == 'hull': decimate(c, R['hull'])
        elif kind.startswith('gen_'): decimate(c, R['gen'])
        elif tris(c) > R['big']: decimate(c, R['part'])
        keep.append(c)
        if os.environ.get('LODDBG') and t0 > 2000: print('[lod]', k, o.name, t0, tris(c))
    bpy.ops.object.select_all(action='DESELECT')
    for c in keep: c.select_set(True)
    bpy.context.view_layer.objects.active = keep[0]; bpy.ops.object.join(); j = bpy.context.view_layer.objects.active
    j.name = f'{CELL}_lod{k}'; j.data.name = j.name
    bpy.ops.object.material_slot_remove_unused()
    info[f'lod{k}'] = dict(triangles=tris(j), objects=len(keep), materials=len([s for s in j.material_slots if s.material]))
    made.append(j)
bpy.ops.object.select_all(action='DESELECT')
for j in made: j.select_set(True)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_apply=True, export_yup=True)
json.dump(info, open(OUT[:-4] + '_lods.json', 'w'), indent=1)
print('[209] export', OUT, json.dumps(info), flush=True)
