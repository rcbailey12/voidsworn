# Issue 756 rivet pitch A/B (sunward.md 4: the builder tests .013 against .011 at camera 170). Runs bake_sheet.py with the
# Sunward stack's rivet_pitch replaced for this run only (the stack file is not changed).
# usage: R209_SHIP=... python run_cpu.py rivet_ab.py -- PITCH OUT_DIR none none CELL RES SAMPLES
import os, sys, runpy
pitch = float(sys.argv[sys.argv.index('--') + 1]); del sys.argv[sys.argv.index('--') + 1]
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
import importlib.util
_orig = importlib.util.module_from_spec


def patched(spec):
    m = _orig(spec)
    if spec.name == 'stack_voidsworn':
        ex = spec.loader.exec_module
        def run(mod):
            ex(mod); mod.LAYERS['rivet_pitch'] = pitch; print('[756] rivet_pitch', pitch, flush=True)
        spec.loader.exec_module = run
    return m


importlib.util.module_from_spec = patched
runpy.run_path(os.path.join(REPO, 'tools', 'blender', 'r209', 'bake_sheet.py'), run_name='__main__')
