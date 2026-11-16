# Issue 756 sandbox driver (not a standing check): runs a recipe script with the bpy module (pip bpy 5.3), as
# "blender -b [BLEND] -P SCRIPT -- ARGS" does, with the paint stack's device set to CPU (the sandbox has no GPU).
# usage: python run_cpu.py SCRIPT [BLEND] -- ARGS        (R209_SHIP set as env.bat sets it)
import os, sys, runpy
repo = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
sys.path[:0] = [os.path.join(repo, 'tools/blender/kits/shared'), os.path.join(repo, 'tools/blender/r209')]
import bpy
a = sys.argv[1:]; i = a.index('--'); head, rest = a[:i], a[i + 1:]
script = head[0]
if len(head) > 1: bpy.ops.wm.open_mainfile(filepath=head[1])
try:
    import paint_stack

    def cpu(samples):
        sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = samples; sc.cycles.device = 'CPU'; return 'CPU'
    paint_stack.gpu = cpu
except Exception as e:
    print('no paint_stack', e)
sys.argv = [script, '--'] + rest
runpy.run_path(script, run_name='__main__')
