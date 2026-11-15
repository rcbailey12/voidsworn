# The export's open-bell test (tools/recipe/check_export.py open_bell) on a build sheet's engines, before any export (issue 759: the
# Hegemony nozzles are rectangular, and the test was written for round bells). Builds the sheet, gathers every outside vertex, and
# tests each engine's exit centre and recorded radius at the export's tolerance (0.012 of the model's length).
# usage: python bell_check.py hegemony_H10   (with the bpy module; exit 1 when an engine fails)
import sys, os, importlib.util
import numpy as np
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'tools/blender/build_sheets')); sys.path.insert(0, os.path.join(REPO, 'tools/recipe'))
import bpy, kit
from check_export import open_bell
CODE = sys.argv[1] if len(sys.argv) > 1 else 'hegemony_H10'
bpy.ops.wm.read_factory_settings(use_empty=True)
sp = importlib.util.spec_from_file_location(CODE, os.path.join(REPO, 'tools/blender/build_sheets/ships', CODE + '.py'))
d = importlib.util.module_from_spec(sp); sp.loader.exec_module(d)
kit.use_kit(d.KIT); K = kit.Kit(d.CODE, d.LENGTH); d.build(K); K.finish(); bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get(); V = []
for o in K.coll.objects:
    if o.type != 'MESH':
        continue
    e = o.evaluated_get(dg); me = e.to_mesh(); V += [tuple(o.matrix_world @ v.co) for v in me.vertices]; e.to_mesh_clear()
V = np.array(V); L = V[:, 0].max() - V[:, 0].min(); tol = 0.012 * L
bad = 0
for f in K.features:
    if f['kind'] == 'engine':
        r = open_bell(np.array(f['exit']), np.array([-1.0, 0, 0]), f['radius'], V, tol)
        bad += not r['ok']
        print(f['id'], 'PASS' if r['ok'] else 'FAIL', r)
print('engines failing the open-bell test', bad)
sys.exit(1 if bad else 0)
