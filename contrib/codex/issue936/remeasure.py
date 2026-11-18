"""Refresh only the descriptive geometry measurements, without rendering."""
import hashlib
import json
import math
from pathlib import Path
import sys
import bpy
import numpy as np

REPO=Path(__file__).resolve().parents[3];PC=REPO.parents[1]
PROOF=PC/'board_b/issue-936/shots'
source=Path(__file__).with_name('capture.py').read_text()
body=source[source.index('areas = [];'):source.index("print('PASS issue936 captures'")]
for code in ('A16','A17','A18','A19','A20'):
    for when in ('after','before'):
        out=PROOF/code/when
        if code=='A16' and when=='before':
            old=json.loads((out/'painted_mesh_measure.json').read_text())
            new=json.loads((PROOF/code/'after/painted_mesh_measure.json').read_text())
            assert old['geometry_sha256']==new['geometry_sha256']
            for key in ('plate_components','plate_area_world2_p10_p50_p90','plate_edge_angle_degrees_p10_p50_p90','method'):
                old[key]=new[key]
            old['plate_measure_note']='Same geometry fingerprint as the final painted output; its plate metrics apply to the preserved before capture too. Original engine-seed evidence retained.'
            (out/'painted_mesh_measure.json').write_text(json.dumps(old,indent=2))
            continue
        path=PC/f'recipe/corsair_{code}/{code}.blend'
        if when=='before':path=Path(str(path)+'1')
        bpy.ops.wm.open_mainfile(filepath=str(path))
        scope={'sc':bpy.context.scene,'S':float(bpy.context.scene['r209_scale'])}
        exec(compile(body,str(Path(__file__).with_name('capture.py')),'exec'),globals())
        print(code,when,measurement['plate_components'],measurement['plate_area_world2_p10_p50_p90'],flush=True)
