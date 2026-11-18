"""R306 to R308: colour reset, preserved trophies, translated/scaled engines.

Blender -b -P contrib/codex/issue936/check_stack.py. No GPU bake is needed.
"""
import importlib.util
import math
from pathlib import Path
import sys
from types import SimpleNamespace
import bpy
import numpy as np

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO / 'tools/blender/kits/shared'))
import paint_stack as P
sp = importlib.util.spec_from_file_location('hullbreaker', REPO / 'tools/blender/kits/hullbreakers/stack.py')
S = importlib.util.module_from_spec(sp); sp.loader.exec_module(S)

for code in ('A16', 'A17', 'A18', 'A19', 'A20', 'A16'):
    bpy.context.scene['r209_sheet'] = 'corsair_' + code
    S.configure_size(26 if code == 'A16' else 9.5)
    assert S.TROPHY['cell'] == (.130, .085, .060)
    assert S.TROPHY['families'][0] == (.65, S.pair('trophy_grey'))
    assert S.ZONES['pale'] == S._SHIP_ZONES['pale']
    assert S.ZONES['rust']['hi'] == S.lin(S.CONCEPT_REGISTERS[code]['rust'][1])
    assert abs(sum(f[0] for f in S.PATCH_FAMILIES[:2]) - .85) < 1e-9
    assert S.LAYERS == S._SHIP_LAYERS
S.configure_size(1.6)
assert S.CRAFT_ACTIVE and S.TROPHY['cell'] == tuple(v * 1.5 for v in S._SHIP_TROPHY['cell'])
assert S.BARE == S.lin((100, 91, 82)), 'R292 craft chips must not wash the red plates grey'
S.configure_size(26)
assert S.LAYERS == S._SHIP_LAYERS

# Observe the real vertex-writing path before its UV packing and bake. Three
# identical throats differ only in radius and world translation. The old path
# gave different seeds and world-space hot spots, so this catches both faults.
bpy.ops.wm.read_factory_settings(use_empty=True)
glow = bpy.data.materials.new('glow')
objects = []
for j, radius in enumerate((.1, .2, .4)):
    vertices = [(0, 0, 0)] + [(0, radius * math.cos(i * math.tau / 32),
                               radius * math.sin(i * math.tau / 32)) for i in range(32)]
    faces = [(0, i + 1, (i + 1) % 32 + 1) for i in range(32)]
    mesh = bpy.data.meshes.new('disc'); mesh.from_pydata(vertices, [], faces)
    obj = bpy.data.objects.new('engine' + str(j), mesh); bpy.context.collection.objects.link(obj)
    obj.location = (j * .3, j * .8, j * .15); obj['grp'] = obj.name
    obj['part_kind'] = 'engine'; mesh.materials.append(glow); objects.append(obj)
bpy.context.view_layer.update()
class StopBeforeBake(Exception):
    pass
def stop(*args):
    raise StopBeforeBake()
P.unwrap = stop
try:
    P.bake_engine_glow(S, objects, '', 'test', 64, 1)
except StopBeforeBake:
    pass
for attr in ('ps_glow', 'ps_glow_pos'):
    expected = np.array([d.color[:] for d in objects[0].data.color_attributes[attr].data])
    for obj in objects[1:]:
        actual = np.array([d.color[:] for d in obj.data.color_attributes[attr].data])
        # Angle wraps at one turn; 0 and 1 represent the same location.
        if attr == 'ps_glow':
            delta = (actual[:, 3] - expected[:, 3] + .5) % 1 - .5
            assert np.allclose(delta, 0, atol=2e-6), (obj.name, 'angle', delta)
            assert np.allclose(actual[:, :3], expected[:, :3], atol=2e-6), (obj.name, attr)
        else:
            assert np.allclose(actual, expected, atol=2e-6), (obj.name, attr, np.abs(actual - expected).max())
nt = bpy.data.materials.new('glow_test'); nt.use_nodes = True
nodes = nt.node_tree
tc = P.node(nodes, 'ShaderNodeTexCoord')
values = [P.node(nodes, 'ShaderNodeValue').outputs[0] for _ in range(4)]
for socket, value in zip(values, (.4, .7, 1.0, .2)):
    socket.default_value = value
P._throat_glow(nodes, S.ENGINE_GLOW, *values, tc,
               lambda vec, *args: P.node(nodes, 'ShaderNodeTexNoise').outputs['Fac'])
assert any(getattr(n, 'attribute_name', '') == 'ps_glow_pos' for n in nodes.nodes)
print('PASS R306/R307: concept registers, red majority, reset, trophy size and grey metal')
print('PASS R308: translated and scaled throats share seed, normalized pattern and strength')
