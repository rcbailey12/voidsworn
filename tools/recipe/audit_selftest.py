# Ship recipe, stage 4: prove the audit fails when it should (Muse condition 2 on PR 341, R158; condition 1 on PR 341's check).
# Six broken copies of the opened build, in memory only (the blend on disk is never written): a gun turned into the ship against
# its mount normal, the build's own transverse break lines removed, the transverse lines emptied, a malformed longitudinal seam,
# every mount normal removed, and one gun's mount normal removed. audit.py must refuse all six. A case whose break cannot be made
# on this build (for example no gun carries a normal to turn against) counts as a self-test failure, never as a pass.
# One more copy proves the longitudinal seam is optional (issue 592): with r209_l_line removed, the audit must not name the
# break lines among its failures (it may still fail for something else the build really has).
# usage: blender -b CELL.blend -P audit_selftest.py -- OUT_DIR      (exit 0: all behave; 1: one got through or could not be made)
import os, sys, json, runpy
import bpy
HERE = os.path.dirname(os.path.abspath(__file__)); AUDIT = os.path.join(HERE, 'audit.py')
out = sys.argv[sys.argv.index('--') + 1]; os.makedirs(out, exist_ok=True); blend = bpy.data.filepath; ok = True
WHY = dict(into_ship='aims into the ship', no_break_lines='no break lines of its own', empty_break_lines='break lines are empty',
           no_normals='carry no mount normal', one_normal_missing='1 of ', bad_longitudinal='longitudinal seam', no_longitudinal=None)
for case in ('into_ship', 'no_break_lines', 'empty_break_lines', 'bad_longitudinal', 'no_normals', 'one_normal_missing', 'no_longitudinal'):
    bpy.ops.wm.open_mainfile(filepath=blend); sc = bpy.context.scene; g = json.loads(sc.get('r209_guns', '[]')); made = True
    if case == 'into_ship':
        k = next((i for i, x in enumerate(g) if len(x) > 2 and x[2]), None); made = k is not None
        if made: g[k][1] = [-v for v in g[k][2]]; sc['r209_guns'] = json.dumps(g)      # aimed straight back into its own mount
    elif case == 'no_break_lines':
        made = 'r209_t_lines' in sc
        if made: del sc['r209_t_lines']
    elif case == 'empty_break_lines': sc['r209_t_lines'] = []
    elif case == 'bad_longitudinal': sc['r209_l_line'] = [0.0, 0.2, -0.2]                    # x0 above x1: not a seam
    elif case == 'no_longitudinal':
        if 'r209_l_line' in sc: del sc['r209_l_line']
    elif case == 'no_normals': sc['r209_guns'] = json.dumps([x[:2] for x in g])
    elif case == 'one_normal_missing':
        made = len(g) > 1 and all(len(x) > 2 and x[2] for x in g)
        if made: g[-1] = g[-1][:2]; sc['r209_guns'] = json.dumps(g)                  # the last gun loses its normal, the rest keep theirs
    if not made:
        ok = False; print(f'BAD  {case}: this break could not be made on this build, so the case proves nothing', flush=True); continue
    sys.argv = ['blender', '--', os.path.join(out, f'audit_{case}.json')]
    try: runpy.run_path(AUDIT, run_name='__main__'); code = 0
    except SystemExit as e: code = e.code or 0
    au = json.load(open(os.path.join(out, f'audit_{case}.json'))); said = json.dumps(au.get('failures', []) + au.get('problems', []))
    if WHY[case] is None:       # the optional longitudinal seam: its absence is never a failure of its own
        good = 'break line' not in json.dumps(au.get('failures', [])); ok &= good
        print(('ok  ' if good else 'BAD ') + f' {case}: ' + ('a build with no longitudinal seam is audited on its transverse seams' if good
              else 'the audit refused a build only for having no longitudinal seam'), flush=True); continue
    why = WHY[case] in said                                     # refused for the reason the case broke, not for another one
    good = code != 0 and why; ok &= good
    print(('ok  ' if good else 'BAD ') + f' {case}: the audit ' + ('failed as it must' if good else 'PASSED a broken build' if code == 0
          else f'failed, but not for the broken {case} (no "{WHY[case]}" in its reasons)'), flush=True)
print('PASS the audit fails when it should' if ok else 'FAIL the audit let a broken build through (or a case could not be made)', flush=True)
sys.exit(0 if ok else 1)
