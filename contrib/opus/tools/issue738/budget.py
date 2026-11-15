# usage: python budget.py BUILD.blend (with the bpy module)
# budget of a built sheet scene: triangles outside and inside, materials (surfaces once joined per material), objects
import sys, json, bpy
bpy.ops.wm.open_mainfile(filepath=sys.argv[1])
out = dict(tris_outside=0, tris_inside=0, mats_outside=set(), mats_inside=set(), objects_outside=0, objects_inside=0)
dg = bpy.context.evaluated_depsgraph_get()
for o in bpy.context.scene.objects:
    if o.type != 'MESH':
        continue
    e = o.evaluated_get(dg); me = e.to_mesh(); me.calc_loop_triangles(); n = len(me.loop_triangles); e.to_mesh_clear()
    k = 'inside' if o.get('role') == 'interior' else 'outside'
    out['tris_' + k] += n; out['objects_' + k] += 1
    for m in o.data.materials:
        if m: out['mats_' + k].add(m.name)
out['mats_outside'] = sorted(out['mats_outside']); out['mats_inside'] = sorted(out['mats_inside'])
print(json.dumps(out))
