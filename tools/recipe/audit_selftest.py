# Ship recipe, stage 4: prove the audit fails when it should (Muse condition 2 on PR 341, R158). Three broken copies of the opened
# build, in memory only (the blend on disk is never written): a gun turned into the ship against its mount normal, the build's own
# break lines removed, the mount normals removed. audit.py must refuse all three.
# usage: blender -b CELL.blend -P audit_selftest.py -- OUT_DIR      (exit 0: all three refused; 1: one got through)
import os, sys, json, runpy
import bpy
HERE = os.path.dirname(os.path.abspath(__file__)); AUDIT = os.path.join(HERE, 'audit.py')
out = sys.argv[sys.argv.index('--') + 1]; os.makedirs(out, exist_ok=True); blend = bpy.data.filepath; ok = True
for case in ('into_ship', 'no_break_lines', 'no_normals'):
    bpy.ops.wm.open_mainfile(filepath=blend); sc = bpy.context.scene; g = json.loads(sc.get('r209_guns', '[]'))
    if case == 'into_ship' and g and len(g[0]) > 2 and g[0][2]:
        g[0][1] = [-v for v in g[0][2]]; sc['r209_guns'] = json.dumps(g)          # aimed straight back into its own mount
    elif case == 'no_break_lines' and 'r209_t_lines' in sc: del sc['r209_t_lines']
    elif case == 'no_normals': sc['r209_guns'] = json.dumps([x[:2] for x in g])
    sys.argv = ['blender', '--', os.path.join(out, f'audit_{case}.json')]
    try: runpy.run_path(AUDIT, run_name='__main__'); code = 0
    except SystemExit as e: code = e.code or 0
    good = code != 0; ok &= good
    print(('ok  ' if good else 'BAD ') + f' {case}: the audit ' + ('failed as it must' if good else 'PASSED a broken build'), flush=True)
print('PASS the audit fails when it should' if ok else 'FAIL the audit let a broken build through', flush=True)
sys.exit(0 if ok else 1)
