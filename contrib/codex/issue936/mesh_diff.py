"""Explain any before/after geometry fingerprint difference without rendering."""
import hashlib
import json
from pathlib import Path
import sys
import bpy
import numpy as np

old_path,new_path,out=sys.argv[sys.argv.index('--')+1:]
def read(path):
    bpy.ops.wm.open_mainfile(filepath=path)
    rows={}
    for ob in bpy.context.scene.objects:
        if ob.type!='MESH': continue
        me=ob.data;me.calc_loop_triangles()
        points=np.asarray([tuple(ob.matrix_world@v.co) for v in me.vertices])
        faces=[tuple(f.vertices) for f in me.polygons]
        rows[ob.name]=dict(points=points,faces=faces,triangles=len(me.loop_triangles))
    return rows
old=read(old_path);new=read(new_path)
result=dict(old_only=sorted(set(old)-set(new)),new_only=sorted(set(new)-set(old)),changed=[])
for name in sorted(set(old)&set(new)):
    a,b=old[name],new[name]
    if a['points'].shape!=b['points'].shape or a['faces']!=b['faces']:
        result['changed'].append(dict(name=name,old_vertices=len(a['points']),new_vertices=len(b['points']),
                                      old_triangles=a['triangles'],new_triangles=b['triangles'],topology=True))
    elif not np.array_equal(a['points'],b['points']):
        result['changed'].append(dict(name=name,max_position_delta=float(np.abs(a['points']-b['points']).max()),topology=False))
Path(out).write_text(json.dumps(result,indent=2))
print(json.dumps(result),flush=True)
