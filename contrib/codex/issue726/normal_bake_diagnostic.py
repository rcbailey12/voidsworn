"""Compare the proposed normal-only bake with the original on a small fixture.

Blender background only. Writes to TEMP, never installs or edits ship assets.
Usage: blender -b -P normal_bake_diagnostic.py -- REPO TEMP_OUTPUT
"""
import ast
import json
import os
import sys
import time
from pathlib import Path
from types import SimpleNamespace

import bpy
import numpy as np

repo, output = map(Path, sys.argv[sys.argv.index('--') + 1:])
output.mkdir(parents=True, exist_ok=True)
original = repo / 'tools/blender/kits/shared/paint_stack.py'
proposal = repo / 'contrib/codex/issue726/proposed/tools/blender/kits/shared/paint_stack.py'


def function(path):
    module = ast.parse(path.read_text())
    fn = next(n for n in module.body if isinstance(n, ast.FunctionDef) and n.name == 'bake')
    namespace = {'bpy': bpy, 'time': time}
    exec(compile(ast.Module(body=[fn], type_ignores=[]), str(path), 'exec'), namespace)
    return namespace['bake']


old, new = function(original), function(proposal)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 1
scene.cycles.device = 'CPU'
bpy.ops.mesh.primitive_plane_add()
obj = bpy.context.object
material = bpy.data.materials.new('normal_fixture')
material.use_nodes = True
obj.data.materials.append(material)
nt = material.node_tree
bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
tex = nt.nodes.new('ShaderNodeTexNoise')
tex.inputs['Scale'].default_value = 7
bump = nt.nodes.new('ShaderNodeBump')
bump.inputs['Distance'].default_value = .08
nt.links.new(tex.outputs['Fac'], bump.inputs['Height'])
nt.links.new(tex.outputs['Color'], bs.inputs['Base Color'])
nt.links.new(tex.outputs['Fac'], bs.inputs['Roughness'])
nt.links.new(tex.outputs['Fac'], bs.inputs['Metallic'])
target = nt.nodes.new('ShaderNodeTexImage')
nt.nodes.active = target


def state():
    return (len(nt.nodes), sorted((l.from_node.name, l.from_socket.name, l.to_node.name, l.to_socket.name) for l in nt.links))


def bake_pixels(fn, name):
    image = bpy.data.images.new(name, 128, 128, alpha=False, float_buffer=True)
    image.colorspace_settings.name = 'Non-Color'
    target.image = image
    fn(obj, 'NORMAL', 4)
    pixels = np.empty(128 * 128 * 4, dtype=np.float32)
    image.pixels.foreach_get(pixels)
    image.filepath_raw = str(output / (name + '.png'))
    image.file_format = 'PNG'
    image.save()
    return pixels


rows = []
for linked in (False, True):
    for link in list(bs.inputs['Normal'].links):
        nt.links.remove(link)
    if linked:
        nt.links.new(bump.outputs['Normal'], bs.inputs['Normal'])
    before = state()
    reference = bake_pixels(old, 'reference_' + str(linked))
    candidate = bake_pixels(new, 'candidate_' + str(linked))
    delta = float(np.max(np.abs(reference - candidate)))
    assert np.isfinite(candidate).all() and delta < 1e-6, delta
    assert state() == before, 'The candidate left a changed shader graph'
    rows.append(dict(linked_normal=linked, max_delta=delta, graph_restored=True))

# Raise at the operator boundary, after temporary links have been connected.
# A missing image only prints an Info message in Blender 4.5, so it cannot
# exercise the exception path.
def refused_bake(**kwargs):
    raise RuntimeError('diagnostic bake failure')


new.__globals__['bpy'] = SimpleNamespace(context=bpy.context, ops=SimpleNamespace(
    object=SimpleNamespace(select_all=bpy.ops.object.select_all, bake=refused_bake)))
before = state()
try:
    new(obj, 'NORMAL', 4)
except RuntimeError:
    pass
else:
    raise AssertionError('The injected operator error was swallowed')
assert state() == before, 'The shader graph was not restored after failure'
report = dict(ok=True, cases=rows, error_graph_restored=True, no_ship_assets_changed=True)
(output / 'diagnostic.json').write_text(json.dumps(report, indent=2))
print('PASS normal bake diagnostic ' + json.dumps(report))
