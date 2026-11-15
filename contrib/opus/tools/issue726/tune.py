# Issue 726 tuning driver (sandbox only, not a standing check, never for the pictures in the PR): run_cpu.py's job, plus two
# shortcuts for quick looks at the trophy layer while tuning:
#   SKIP_NORMAL=1        the hull's detail normal bake is skipped (a flat normal map; it is most of the bake time on CPU)
#   TROPHY='{"..": ..}'  JSON merged into the stack's TROPHY before the materials are built (for example a debug colour:
#                        {"families": [[1.0, [[0, 1, 0], [0, 1, 0]]]]} paints every trophy plate green)
# usage: python tune.py SCRIPT [BLEND] -- ARGS        (R209_SHIP set as env.bat sets it)
import os, sys, json, runpy
repo = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
sys.path[:0] = [os.path.join(repo, 'tools/blender/kits/shared'), os.path.join(repo, 'tools/blender/r209')]
import bpy
import paint_stack
a = sys.argv[1:]; i = a.index('--'); head, rest = a[:i], a[i + 1:]


def cpu(samples):
    sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = samples; sc.cycles.device = 'CPU'; return 'CPU'


paint_stack.gpu = cpu
_bake, _use = paint_stack.bake, paint_stack.use


def bake(obj, kind, margin):
    if kind == 'NORMAL' and os.environ.get('SKIP_NORMAL') == '1': return 0.0
    return _bake(obj, kind, margin)


def use(S):
    over = json.loads(os.environ.get('TROPHY', '{}') or '{}')
    if over and hasattr(S, 'TROPHY'):
        if 'families' in over: over['families'] = [(f[0], (tuple(f[1][0]), tuple(f[1][1]))) for f in over['families']]
        S.TROPHY.update(over); print('[726] TROPHY', S.TROPHY, flush=True)
    return _use(S)


paint_stack.bake, paint_stack.use = bake, use
sys.argv = [head[0], '--'] + rest
runpy.run_path(head[0], run_name='__main__')
