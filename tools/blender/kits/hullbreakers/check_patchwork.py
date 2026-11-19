"""Build the real sheet, check mesh integrity, report its plate sizes and relief.

Blender -b -P check_patchwork.py -- REPORT.json A18|A19|A20|KB1CC
Distribution numbers are for review, not arbitrary visual pass bars.
"""
import importlib.util
import json
import math
import runpy
from pathlib import Path
import sys
import bpy
import numpy as np

REPO = Path(__file__).resolve().parents[4]
runpy.run_path(str(Path(__file__).with_name('check_stack.py')))
sys.path.insert(0, str(REPO / 'tools/blender/build_sheets'))
import variants
import clash
import weapon_match

out, code = sys.argv[sys.argv.index('--') + 1:]
sp = importlib.util.spec_from_file_location('ship', REPO / f'tools/blender/build_sheets/ships/corsair_{code}.py')
ship = importlib.util.module_from_spec(sp); sp.loader.exec_module(ship)
bpy.ops.wm.read_factory_settings(use_empty=True)
K = variants.build(ship)
fit = clash.run(K, str(Path(out).parent), ship.CODE, ship.LENGTH)
match, problems = weapon_match.run(K, K.game_ship)
assert not problems, problems
assert not any(fit['counts'].values()), fit['clashes']
rows = K.patchwork_report
areas = [a for row in rows for a in row['areas']]
angles = [a for row in rows for a in row['angles']]
assert areas and all(a > 0 for a in areas)
assert sum(r['welded_edges'] for r in rows) > 0
assert sum(r['stacked'] for r in rows) > 0
triangles = 0
for obj in K.coll.objects:
    if obj.type != 'MESH':
        continue
    mesh = obj.data
    assert all(math.isfinite(c) for v in mesh.vertices for c in v.co), obj.name
    assert all(len(set(p.vertices)) >= 3 for p in mesh.polygons), obj.name
    mesh.calc_loop_triangles(); triangles += len(mesh.loop_triangles)
report = dict(ship=code, plates=len(areas), welded_edges=sum(r['welded_edges'] for r in rows),
              stacked=sum(r['stacked'] for r in rows), triangles=triangles,
              fit=fit['counts'], weapon_match=match['result'],
              area_percentiles_world_squared=list(np.percentile(areas, [10, 50, 90])),
              angle_percentiles_degrees=list(np.percentile(angles, [10, 50, 90])),
              size_note='Measured, for review; no visual cap. Material weights remain in the sheet.')
Path(out).write_text(json.dumps(report, indent=2))
print('PASS patchwork geometry', json.dumps(report), flush=True)
