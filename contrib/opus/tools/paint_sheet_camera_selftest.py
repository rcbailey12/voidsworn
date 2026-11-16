"""Issue 844: run the real beauty camera functions with small Blender API doubles, no render or GPU."""
import ast
import itertools
import json
import math
import os
from pathlib import Path
from types import SimpleNamespace as NS

ROOT = Path(os.environ.get('VS_ROOT', Path(__file__).resolve().parents[3]))
SOURCE = ROOT / 'tools/blender/build_sheets/paint_sheet.py'


class Vector(tuple):
    def __new__(cls, values):
        return super().__new__(cls, values)

    x, y, z = (property(lambda self, i=i: self[i]) for i in range(3))

    def __add__(self, other):
        return Vector(a + b for a, b in zip(self, other))

    def __sub__(self, other):
        return Vector(a - b for a, b in zip(self, other))

    def __mul__(self, number):
        return Vector(a * number for a in self)

    def __neg__(self):
        return self * -1

    def dot(self, other):
        return sum(a * b for a, b in zip(self, other))

    def cross(self, other):
        a, b, c = self; x, y, z = other
        return Vector((b * z - c * y, c * x - a * z, a * y - b * x))

    def normalized(self):
        return self * (1 / math.sqrt(self.dot(self)))


class Transform:
    def __matmul__(self, point):
        # Translation, rotation and nonuniform scale must all affect the bounds.
        return Vector((point.z * .8 + .12, point.x * 1.1 - .07, point.y * .6 + .03))


BOUNDS = list(itertools.product((-.5, .5), (-.2, .2), (-.15, .15)))
evaluated = NS(matrix_world=Transform(), bound_box=BOUNDS)
mesh = NS(type='MESH', hide_render=False, evaluated_get=lambda dg: evaluated)
# Hidden meshes and non-mesh objects do not supply bounds and must be ignored.
sc = NS(objects=[mesh, NS(type='MESH', hide_render=True), NS(type='LIGHT', hide_render=False)],
        render=NS(), collection=NS(objects=NS(link=lambda obj: None)))
bpy = NS(context=NS(evaluated_depsgraph_get=lambda: None), data=NS(
    cameras=NS(new=lambda name: NS()), objects=NS(new=lambda name, data: NS(data=data))))
tree = ast.parse(SOURCE.read_text(encoding='utf-8'), filename=str(SOURCE))
functions = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in ('scene_clip', 'look_cam')]
env = dict(math=math, Vector=Vector, Matrix=lambda rows: rows, bpy=bpy, sc=sc)
exec(compile(ast.Module(body=functions, type_ignores=[]), str(SOURCE), 'exec'), env)


def camera(fc, scale):
    env['S'] = scale
    return env['look_cam'](fc['az'], fc['el'], fc['dist'], fc['mm'], tuple(fc['res']), fc['target'],
                           fc.get('roll', 0), (-fc.get('sx', 0), -fc.get('sy', 0)))


def depths(obj):
    rows = obj.matrix_world
    loc = Vector(row[3] for row in rows[:3])
    forward = Vector(-row[2] for row in rows[:3])
    return [(evaluated.matrix_world @ Vector(p) - loc).dot(forward) for p in evaluated.bound_box]


def encloses(obj):
    ds = depths(obj)
    assert 0 < obj.data.clip_start < min(ds), (obj.data.clip_start, min(ds))
    assert obj.data.clip_end > max(ds), (obj.data.clip_end, max(ds))


count = 0
ships = ROOT / 'tools/blender/build_sheets/ships'
for path in sorted(ships.glob('*_camera.json')):
    code = path.name.removesuffix('_camera.json')
    sheet = ast.parse((ships / (code + '.py')).read_text(encoding='utf-8'))
    length = next(ast.literal_eval(n.value) for n in sheet.body if isinstance(n, ast.Assign)
                  and any(isinstance(t, ast.Name) and t.id == 'LENGTH' for t in n.targets))
    fc = json.loads(path.read_text(encoding='utf-8'))
    obj = camera(fc, 1 / length)
    encloses(obj)
    assert obj.data.lens == fc['mm'] and obj.data.sensor_fit == 'HORIZONTAL'
    assert (obj.data.shift_x, obj.data.shift_y) == (-fc.get('sx', 0), -fc.get('sy', 0))
    assert (sc.render.resolution_x, sc.render.resolution_y) == tuple(fc['res'])
    # Changing only the model bounds may change only the clip planes, never the fitted camera or lens.
    evaluated.bound_box = [tuple(v * 1.3 for v in p) for p in BOUNDS]
    larger = camera(fc, 1 / length)
    encloses(larger)
    assert larger.matrix_world == obj.matrix_world and larger.data.lens == obj.data.lens
    evaluated.bound_box = BOUNDS
    count += 1
    print('PASS ' + code + ': full bounds visible, fitted framing preserved')

# Distances alone cannot set the planes: an off-centre, deep model needs its actual scene bounds.
fc = dict(az=0, el=0, dist=25, mm=50, target=[10, 0, 0], res=[1280, 720])
evaluated.bound_box = list(itertools.product((-3, 3), (-2, 2), (-50, 20)))
obj = camera(fc, 1)
encloses(obj)
assert obj.data.clip_end > 2 * fc['dist']
print('PASS off-centre deep model: planes follow scene bounds')

# A surface crossing the camera retains a positive near plane; flat bounds still have padding.
fc.update(dist=.001, target=[.12, -.07, .03])
evaluated.bound_box = BOUNDS
obj = camera(fc, 1)
assert 0 < obj.data.clip_start < obj.data.clip_end
evaluated.bound_box = [(0, 0, 0)] * 8
encloses(camera(fc, 1))
print('PASS near-camera and flat bounds: valid clip planes')
print('PASS paint sheet camera: ' + str(count) + ' saved cameras and clip edge cases')
