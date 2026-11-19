"""Compare painted meshes with fresh builds of the approved, unchanged sheets.

Blender -b -P check_geometry.py -- REPORT.json. No rendering or baking.
"""
import json
from pathlib import Path
import sys
import bpy
import numpy as np

REPO=Path(__file__).resolve().parents[3]
PC=REPO.parents[1]
sys.path.insert(0,str(REPO/'tools/blender/r209'))
import sheet_hull as SH

def snapshot():
    rows={}
    for ob in bpy.context.scene.objects:
        if ob.type!='MESH': continue
        rows[ob.name]=(np.asarray([tuple(ob.matrix_world@v.co) for v in ob.data.vertices]),
                       [tuple(f.vertices) for f in ob.data.polygons])
    return rows

args=sys.argv[sys.argv.index('--')+1:]
report={}
for code in args[1:] or ('A16','A17','A18','A19','A20'):
    bpy.ops.wm.open_mainfile(filepath=str(PC/f'recipe/corsair_{code}/{code}.blend'))
    painted=snapshot()
    SH.SHIP=str(REPO/f'tools/recipe/ships/corsair_{code}.json')
    SH.build_geometry()
    approved=snapshot(); problems=[]; maximum=0.0
    for name,(points,faces) in approved.items():
        if name not in painted:
            problems.append(name+': absent'); continue
        other,other_faces=painted[name]
        if points.shape!=other.shape or faces!=other_faces:
            problems.append(name+': topology differs'); continue
        delta=float(np.abs(points-other).max()) if len(points) else 0.0
        maximum=max(maximum,delta)
        if delta>1e-7:
            problems.append(name+': positions differ by '+str(delta))
    report[code]=dict(ok=not problems,problems=problems,approved_meshes=len(approved),
                      maximum_position_delta=maximum,
                      tolerance='1e-7 normalized ship length, for float32 transform serialization only',
                      paint_generated_meshes=sorted(set(painted)-set(approved)))
    print(code,'PASS approved sheet geometry' if not problems else 'FAIL',problems,flush=True)
out=Path(args[0]);out.write_text(json.dumps(report,indent=2)+'\n')
assert all(row['ok'] for row in report.values()),report
