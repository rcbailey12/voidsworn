"""Issue 870 CPU sheet evidence. No paint bake or game install.

blender -b -P tools/blender/build_sheets/studies/ion870.py -- CODE before|after OUT
Before reads the design from the pinned main baseline; after builds the working design.
Run both states for both ships, then compose with ion870_compose.py.
"""
import sys
sys.dont_write_bytecode = True
import hashlib
from datetime import datetime, timezone
import importlib.util
import json
import math
from pathlib import Path
import subprocess
import types

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[4]
SHEETS = ROOT / 'tools/blender/build_sheets'
sys.path[:0] = [str(SHEETS), str(ROOT / 'tools')]
import clash
import kit
import variants
import weapon_match
from picture_provenance import save_picture
from PIL import Image

code, state, out = sys.argv[sys.argv.index('--') + 1:]
out = Path(out) / code / state
out.mkdir(parents=True, exist_ok=True)
source = 'tools/blender/build_sheets/ships/' + code + '.py'
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip()
baseline = '67ac3ab86616e39cfc598b5fa9714cb46307e117'
data = (subprocess.check_output(['git', 'show', baseline + ':' + source], cwd=ROOT)
        if state == 'before' else (ROOT / source).read_bytes())
design = types.ModuleType(code)
exec(compile(data, str(ROOT / source), 'exec'), design.__dict__)
bpy.ops.wm.read_factory_settings(use_empty=True)
K = variants.build(design)
bpy.context.view_layer.update()


def geometry(objects):
    rows, count = [], 0
    deps = bpy.context.evaluated_depsgraph_get()
    for ob in sorted(objects, key=lambda o: o.name):
        if ob.type != 'MESH':
            continue
        obj = ob.evaluated_get(deps)
        mesh = obj.to_mesh()
        mesh.calc_loop_triangles()
        count += len(mesh.loop_triangles)
        rows.append((ob.name, [tuple(round(c, 6) for c in ob.matrix_world @ v.co) for v in mesh.vertices],
                     [tuple(p.vertices) for p in mesh.polygons]))
        obj.to_mesh_clear()
    return dict(triangles=count, objects=len(rows), sha256=hashlib.sha256(json.dumps(rows).encode()).hexdigest())


fit = clash.run(K, str(out), code, design.LENGTH)
match, errors = weapon_match.run(K, K.game_ship)
(out / 'weapon_match.json').write_text(json.dumps(match, indent=2) + '\n')
checks = dict(source_revision=baseline if state == 'before' else head, state=state, source_sha256=hashlib.sha256(data).hexdigest(),
              outside=geometry(K.coll.objects), inside=geometry(K.cin.objects), fit=fit['counts'],
              tested=fit['tested'], weapon_match=match['result'], features=K.features, changes=K.changes)
(out / 'checks.json').write_text(json.dumps(checks, indent=2) + '\n')
if errors or any(fit['counts'].values()):
    raise RuntimeError('weapon or fit check failed: ' + str(errors) + str(fit['counts']))

# Both states use the same game light and Hegemony stack lights. The after gun's
# source-authored I1 light materials are preserved, with no capture-only boost.
sp = importlib.util.spec_from_file_location('heg_stack', ROOT / 'tools/blender/kits/hegemony/stack.py')
stack = importlib.util.module_from_spec(sp)
sp.loader.exec_module(stack)
for ob in K.coll.objects:
    if ob.type != 'MESH' or not ob.data.materials:
        continue
    zone = ob.data.materials[0].name
    if zone in stack.GLOW:
        ob.data.materials[0] = stack.glow_material(zone)
for ob in K.cin.objects:
    ob.hide_render = True
sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.cycles.samples = 24
sc.cycles.use_denoising = True
sc.render.threads_mode = 'FIXED'
sc.render.threads = 10
sc.view_settings.view_transform = 'Standard'
sc.use_nodes = True
tree = sc.node_tree
tree.nodes.clear()
layers = tree.nodes.new('CompositorNodeRLayers')
glare = tree.nodes.new('CompositorNodeGlare')
glare.glare_type = 'FOG_GLOW'
glare.quality = 'HIGH'
glare.threshold = 1.2
glare.size = 7
output = tree.nodes.new('CompositorNodeComposite')
tree.links.new(layers.outputs['Image'], glare.inputs['Image'])
tree.links.new(glare.outputs['Image'], output.inputs['Image'])
sc.render.image_settings.file_format = 'PNG'
sc.render.film_transparent = False
world = bpy.data.worlds.new('game')
sc.world = world
world.use_nodes = True
nt = world.node_tree
bg = nt.nodes['Background']
bg.inputs[0].default_value = (.43, .45, .5, 1)
bg.inputs[1].default_value = .5
path = nt.nodes.new('ShaderNodeLightPath')
back = nt.nodes.new('ShaderNodeBackground')
back.inputs[0].default_value = (.012, .017, .026, 1)
mix = nt.nodes.new('ShaderNodeMixShader')
nt.links.new(path.outputs['Is Camera Ray'], mix.inputs[0])
nt.links.new(bg.outputs[0], mix.inputs[1])
nt.links.new(back.outputs[0], mix.inputs[2])
nt.links.new(mix.outputs[0], nt.nodes['World Output'].inputs[0])
for name, toward, rgb, energy in [('key', (-.45, .55, -.70), (1, .96, .90), 2),
                                   ('fill', (.6, -.75, -.2), (.55, .65, .85), .5)]:
    light = bpy.data.lights.new(name, 'SUN')
    light.energy = energy * math.pi
    light.color = rgb
    light.angle = math.radians(1.5)
    ob = bpy.data.objects.new(name, light)
    sc.collection.objects.link(ob)
    ob.rotation_euler = Vector(toward).to_track_quat('-Z', 'Y').to_euler()


def camera(c):
    a, e, roll = [math.radians(c.get(k, 0)) for k in ('az', 'el', 'roll')]
    d = Vector((math.cos(e) * math.cos(a), math.cos(e) * math.sin(a), math.sin(e)))
    loc = Vector(c.get('target', (0, 0, 0))) + d * c['dist']
    r = (-d).cross(Vector((0, 0, 1))).normalized()
    u = r.cross(-d).normalized()
    r, u = r * math.cos(roll) + u * math.sin(roll), u * math.cos(roll) - r * math.sin(roll)
    b = r.cross(u)
    data = bpy.data.cameras.new('review')
    ob = bpy.data.objects.new('review', data)
    sc.collection.objects.link(ob)
    ob.matrix_world = Matrix(((r.x, u.x, b.x, loc.x), (r.y, u.y, b.y, loc.y),
                             (r.z, u.z, b.z, loc.z), (0, 0, 0, 1)))
    data.lens = c['mm']
    data.sensor_width = 36
    data.sensor_fit = 'HORIZONTAL'
    data.shift_x, data.shift_y = -c.get('sx', 0), -c.get('sy', 0)
    data.clip_start = .05
    data.clip_end = 500
    return ob


fc = json.loads((SHEETS / 'ships' / (code + '_camera.json')).read_text())
views = dict(concept=fc,
             close=dict(az=9, el=8, dist=7, mm=48, target=(design.XB + .8, 0, -.1), res=(1100, 620)),
             cam170=dict(az=30, el=90 - math.degrees(.98), dist=170 / 1.6,
                         mm=36 / (2 * math.tan(math.radians(45) / 2) * 1920 / 1080), res=(1920, 1080)),
             beam170=dict(az=90, el=90 - math.degrees(.98), dist=170 / 1.6,
                          mm=36 / (2 * math.tan(math.radians(45) / 2) * 1920 / 1080), res=(1920, 1080)))
for name, settings in views.items():
    sc.camera = camera(settings)
    size = settings['res']
    if name == 'concept':
        size = (1200, round(size[1] * 1200 / size[0]))
    sc.render.resolution_x, sc.render.resolution_y = size
    sc.render.resolution_percentage = 100
    dest = out / (name + '.png')
    sc.render.filepath = str(dest)
    bpy.ops.render.render(write_still=True)
    with Image.open(dest) as original:
        pixels = original.copy()
    sources = None
    if state == 'before':
        src = dict(source_commit=baseline, source_dirty=False, source_diff_sha256='', stage='sheet built')
        sources = [dict(src, picture_name=dest.name, date=datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
                        image_sha256=hashlib.sha256(dest.read_bytes()).hexdigest(), sources=[src])]
    save_picture(pixels, dest, 'sheet built', sources=sources)
    print('870 rendered', code, state, name, flush=True)
checks['cameras'] = views
(out / 'checks.json').write_text(json.dumps(checks, indent=2) + '\n')
