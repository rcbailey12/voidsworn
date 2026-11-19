"""Compare the normal bake and height fallback with the original on a fixture.

Blender background only. Writes to TEMP, never installs or edits ship assets.
Usage: blender -b -P normal_bake_diagnostic.py -- REPO TEMP_OUTPUT
"""
import ast
import json
import subprocess
import sys
import time
from pathlib import Path
from types import SimpleNamespace

import bpy
import numpy as np

repo, output = map(Path, sys.argv[sys.argv.index('--') + 1:])
output.mkdir(parents=True, exist_ok=True)
candidate = repo / 'tools/blender/kits/shared/paint_stack.py'
baseline = subprocess.check_output(['git', '-C', str(repo), 'show',
                                  '0e9c791d:tools/blender/kits/shared/paint_stack.py'], text=True)


def function(source, label):
    module = ast.parse(source)
    fn = next(n for n in module.body if isinstance(n, ast.FunctionDef) and n.name == 'bake')
    namespace = {'bpy': bpy, 'time': time, 'INFO': {}, 'np': np}
    exec(compile(ast.Module(body=[fn], type_ignores=[]), label, 'exec'), namespace)
    return namespace['bake']


old, new = function(baseline, 'main bake'), function(candidate.read_text(), str(candidate))
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
    image = bpy.data.images.new(name, fixture_resolution, fixture_resolution, alpha=False, float_buffer=True)
    image.colorspace_settings.name = 'Non-Color'
    for slot in obj.material_slots:
        slot.material.node_tree.nodes.active.image = image
    fn(obj, 'NORMAL', 4)
    assert all(slot.material.node_tree.nodes.active.image == image for slot in obj.material_slots)
    assert bpy.data.images.get('ps_height_inactive') is None
    assert bpy.data.images.get('ps_patchwork_height') is None
    pixels = np.empty(fixture_resolution * fixture_resolution * 4, dtype=np.float32)
    image.pixels.foreach_get(pixels)
    image.filepath_raw = str(output / (name + '.png'))
    image.file_format = 'PNG'
    image.save()
    return pixels


rows = []
fixture_resolution = 128
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

# Force the height route with harmless reroutes in a labelled height term.
# SVM optimizes these away, providing a valid procedural control.
fixture_resolution = 1024
bump.inputs['Distance'].default_value = .0008
tex.label = 'NORMAL_PATCHWORK_HEIGHT'
wire = bump.outputs['Normal']
for _ in range(810):
    reroute = nt.nodes.new('NodeReroute')
    nt.links.new(wire, reroute.inputs[0]); wire = reroute.outputs[0]
nt.links.new(wire, bs.inputs['Normal'])
before = state()
settings = (scene.cycles.device, scene.cycles.shading_system, scene.render.bake.use_clear)
# A large graph without the trophy opt-in must still use the original path.
reference = bake_pixels(old, 'reference_large_unopted')
candidate = bake_pixels(new, 'candidate_large_unopted')
delta = float(np.max(np.abs(reference - candidate)))
assert delta < 1e-6 and state() == before, delta
assert not new.__globals__['INFO'].get('normal_height_maps')
rows.append(dict(unopted_large_graph=True, max_delta=delta, graph_restored=True))
material['ps_height_bake'] = True
reference = bake_pixels(old, 'reference_height')
candidate = bake_pixels(new, 'candidate_height')
delta = float(np.max(np.abs(reference - candidate)))
# Height sampling must stay within half a shipped 8-bit normal step on
# this smooth input at the faction's real bump distance.
assert delta < .5 / 255 and np.isfinite(candidate).all(), delta
assert state() == before, dict(added=list(set(state()[1]) - set(before[1])), removed=list(set(before[1]) - set(state()[1])))
assert (scene.cycles.device, scene.cycles.shading_system, scene.render.bake.use_clear) == settings
rows.append(dict(forced_height=True, max_delta=delta, graph_restored=True, settings_restored=True))

# Put a flat material beside the height material on the same UV atlas.
# The final normal pass must preserve both at the shared face boundary.
small = bpy.data.materials.new('small_normal_fixture'); small.use_nodes = True
small.node_tree.nodes.active = small.node_tree.nodes.new('ShaderNodeTexImage')
obj.data.materials.append(small)
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.subdivide(number_cuts=1); bpy.ops.object.mode_set(mode='OBJECT')
for face in obj.data.polygons:
    face.material_index = 1 if face.center.x > 0 else 0
before = state()
reference = bake_pixels(old, 'reference_mixed')
candidate = bake_pixels(new, 'candidate_mixed')
delta = float(np.max(np.abs(reference - candidate)))
assert delta < .5 / 255 and np.isfinite(candidate).all(), delta
assert state() == before
assert (scene.cycles.device, scene.cycles.shading_system, scene.render.bake.use_clear) == settings
rows.append(dict(mixed_materials=True, max_delta=delta, graph_restored=True, settings_restored=True))

# Raise at the operator boundary, after temporary links have been connected.
# A missing image only prints an Info message in Blender 4.5, so it cannot
# exercise the exception path.
def refused_bake(**kwargs):
    raise RuntimeError('diagnostic bake failure')


new.__globals__['bpy'] = SimpleNamespace(context=bpy.context, data=bpy.data, ops=SimpleNamespace(
    object=SimpleNamespace(select_all=bpy.ops.object.select_all, bake=refused_bake)))
before = state()
try:
    new(obj, 'NORMAL', 4)
except RuntimeError:
    pass
else:
    raise AssertionError('The injected operator error was swallowed')
assert state() == before, 'The shader graph was not restored after failure'
assert (scene.cycles.device, scene.cycles.shading_system, scene.render.bake.use_clear) == settings
report = dict(ok=True, cases=rows, error_graph_restored=True, no_ship_assets_changed=True)
(output / 'diagnostic.json').write_text(json.dumps(report, indent=2))
print('PASS normal bake diagnostic ' + json.dumps(report))
