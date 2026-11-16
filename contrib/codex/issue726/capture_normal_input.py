"""Capture the real A20 procedural normal graph in TEMP, without installing.

Skip paint-only bakes; reuse the last run's geometry masks. This is a compiler
diagnostic input, never a painted deliverable.
"""
import importlib.util
import os
from pathlib import Path
import sys

import bpy
import numpy as np

repo, output, job = map(Path, sys.argv[sys.argv.index('--') + 1:])
output.mkdir(parents=True, exist_ok=True)
for directory in ('tools/blender/r209', 'tools/blender/kits/shared', 'tools/recipe'):
    sys.path.insert(0, str(repo / directory))
os.environ['R209_SHIP'] = str(repo / 'tools/recipe/ships/corsair_A20.json')
import sheet_hull
import paint_stack as ps

spec = importlib.util.spec_from_file_location('hullbreaker_stack', repo / 'tools/blender/kits/hullbreakers/stack.py')
stack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stack)
sheet_hull.build_geometry()


def capture(obj, kind, margin):
    image = obj.material_slots[0].material.node_tree.nodes.active.image
    if kind == 'NORMAL':
        bpy.ops.wm.save_as_mainfile(filepath=str(output / 'A20_normal_input.blend'))
        print('CAPTURED A20 normal input', flush=True)
        raise SystemExit(0)
    if image.name.endswith('_masks'):
        group = 'hull' if '_H_' in image.name else 'parts'
        source = bpy.data.images.load(str(job / ('A20_' + group + '_masks.png')))
        pixels = np.empty(len(source.pixels), np.float32)
        source.pixels.foreach_get(pixels)
        image.pixels.foreach_set(pixels)
    return 0.0


ps.bake = capture
ps.run(stack, str(output), 'A20', 4096, 4096, 1)
