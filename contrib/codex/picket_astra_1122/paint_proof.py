"""CPU Cycles proof of the Navy stack, using bake_sheet.py's normal Blender arguments."""
import os
from pathlib import Path
import runpy
import sys

recipe = Path(os.environ['R209_SHIP']).resolve().parents[2] / 'blender/r209'
sys.path.insert(0, str(recipe))
import cycles_devices


def use_cpu(scene):
    scene.cycles.device = 'CPU'
    return 'CPU'


cycles_devices.configure_cycles_device = use_cpu
runpy.run_path(str(recipe / 'bake_sheet.py'), run_name='__main__')
