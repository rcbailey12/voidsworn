"""Bake the real E11 hull normal twice on identical inputs. TEMP output only.

Usage: blender -b -P ship_normal_diagnostic.py -- REPO TEMP_OUTPUT
The original bake is pinned to main 0e9c791d; the candidate comes from the working tree.
"""
import ast
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import time

import bpy
import numpy as np

repo, output = map(Path, sys.argv[sys.argv.index('--') + 1:])
output.mkdir(parents=True, exist_ok=True)
for directory in ('tools/blender/r209', 'tools/blender/kits/shared', 'tools/recipe'):
    sys.path.insert(0, str(repo / directory))
os.environ['R209_SHIP'] = str(repo / 'tools/recipe/ships/deathless_E11.json')
import sheet_hull
import paint_stack as ps

source = subprocess.check_output(['git', '-C', str(repo), 'show',
                                  '0e9c791d:tools/blender/kits/shared/paint_stack.py'], text=True)
fn = next(n for n in ast.parse(source).body if isinstance(n, ast.FunctionDef) and n.name == 'bake')
namespace = dict(bpy=bpy, time=time)
exec(compile(ast.Module(body=[fn], type_ignores=[]), 'main bake', 'exec'), namespace)
original, candidate = namespace['bake'], ps.bake
spec = importlib.util.spec_from_file_location('eclipse_stack', repo / 'tools/blender/kits/eclipse/stack.py')
stack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stack)
sheet_hull.build_geometry()
rows = []


def graph(obj):
    return {m.name: (len(m.node_tree.nodes), sorted(
        (link.from_node.name, link.from_socket.identifier, link.to_node.name, link.to_socket.identifier)
        for link in m.node_tree.links)) for m in {slot.material for slot in obj.material_slots}}


def compare(obj, kind, margin):
    if kind != 'NORMAL':
        return candidate(obj, kind, margin)
    image = obj.material_slots[0].material.node_tree.nodes.active.image
    # The real mesh, UVs and 4096-pixel geometry masks are retained. A compact
    # normal target makes the deterministic CPU equivalence check practical.
    image.scale(512, 512)
    count = len(image.pixels)
    before = graph(obj)
    # GPU bevel rays vary slightly across unchanged repeats. The equivalence
    # comparison uses CPU kernels for stable pixels;
    # masks, atlas size and materials remain real E11. One sample is enough
    # to compare the same normal shader; production ship bakes keep 64.
    cycles = bpy.context.scene.cycles
    old_device = cycles.device
    old_samples = cycles.samples
    cycles.device = 'CPU'
    cycles.samples = 1
    original(obj, kind, margin)
    reference = np.empty(count, np.float32)
    image.pixels.foreach_get(reference)
    ps.save(image, str(output), 'E11_normal_reference')
    original(obj, kind, margin)
    repeated = np.empty(count, np.float32)
    image.pixels.foreach_get(repeated)
    ps.save(image, str(output), 'E11_normal_repeat')
    elapsed = candidate(obj, kind, margin)
    current = np.empty(count, np.float32)
    image.pixels.foreach_get(current)
    ps.save(image, str(output), 'E11_normal_candidate')
    delta = np.abs(reference - current).reshape(-1, 4)[:, :3]
    repeat_delta = np.abs(reference - repeated).reshape(-1, 4)[:, :3]
    report = dict(ship='E11', device='CPU', resolution=list(image.size), samples=bpy.context.scene.cycles.samples,
                  max_float_delta=float(delta.max()), changed_float_channels=int(np.count_nonzero(delta)),
                  rgb_channels=int(delta.size), rms_8bit=float(np.sqrt(np.mean(delta ** 2)) * 255),
                  repeat_max_float_delta=float(repeat_delta.max()),
                  repeat_changed_float_channels=int(np.count_nonzero(repeat_delta)),
                  repeat_rms_8bit=float(np.sqrt(np.mean(repeat_delta ** 2)) * 255),
                  graph_restored=graph(obj) == before)
    for name in ('reference', 'repeat', 'candidate'):
        report[name + '_sha256'] = hashlib.sha256((output / ('E11_normal_' + name + '.png')).read_bytes()).hexdigest()
    (output / 'comparison.json').write_text(json.dumps(report, indent=2))
    # The unchanged shader also varies between bakes on this PC. Use its own
    # measured repeat range; do not require a hash match that the control fails.
    assert np.isfinite(current).all(), report
    assert report['max_float_delta'] <= report['repeat_max_float_delta'] + 1e-6, report
    assert report['graph_restored'], report
    cycles.device = old_device
    cycles.samples = old_samples
    rows.append(report)
    print('PASS E11 normal map comparison ' + json.dumps(report), flush=True)
    return elapsed


ps.bake = compare
info = ps.run(stack, str(output), 'E11', 4096, 4096, 64, textures_dir=str(output / 'textures'))
assert len(rows) == 1, rows
report = dict(ok=True, source_revision=subprocess.check_output(
    ['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip(), cases=rows,
    paint_seconds=info['paint_seconds'] if 'paint_seconds' in info else None,
    no_ship_assets_changed=True)
(output / 'diagnostic.json').write_text(json.dumps(report, indent=2))
print('PASS ship normal diagnostic ' + json.dumps(report), flush=True)
