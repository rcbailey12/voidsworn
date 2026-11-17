"""Issue 921 run 2 CPU evidence, without painting or installing.

blender -b -t 6 --python-exit-code 1 -P <this file> -- chorus_C10 before|run1|after OUT [view]
The main and run 1 designs are pinned below. After reads the working C10 design.
Views: concept, maw_close, flesh_close, cam170. Compose with review_publish.py.
"""
import sys
sys.dont_write_bytecode = True
import hashlib
from datetime import datetime, timezone
import json
import math
from pathlib import Path
import subprocess
import types

import bpy
from mathutils import Matrix, Vector

ROOT = next(p for p in Path(__file__).resolve().parents if (p / 'tools/picture_provenance.py').is_file())
SHEETS = ROOT / 'tools/blender/build_sheets'
sys.path[:0] = [str(SHEETS), str(ROOT / 'tools')]
import clash
import kit
import variants
import weapon_match
from picture_provenance import save_picture
from PIL import Image

args = sys.argv[sys.argv.index('--') + 1:]
code, state, out = args[:3]
only = args[3] if len(args) > 3 else None
out = Path(out) / code / state
out.mkdir(parents=True, exist_ok=True)
source = 'tools/blender/build_sheets/ships/' + code + '.py'
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip()
baseline = ('8e9def50232a3ba0b5a1cb1a771a49595926bec8' if state == 'run1'
            else '51ec81bb2746576a5ebabd0aed7f813da109005b')
baseline = subprocess.check_output(['git', 'rev-parse', baseline], cwd=ROOT).decode().strip()
data = (subprocess.check_output(['git', 'show', baseline + ':' + source], cwd=ROOT)
        if state != 'after' else (ROOT / source).read_bytes())
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


# Measure each real maw with axial rays through a 2-unit central circle.
from mathutils.bvhtree import BVHTree
maw_read = {}
for fid in ('M1', 'M2'):
    V, F = [], []
    for ob in K.coll.objects:
        if ob.type != 'MESH' or ob.get('grp') != fid:
            continue
        mesh = ob.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
        off = len(V)
        V.extend(ob.matrix_world @ v.co for v in mesh.vertices)
        F.extend(tuple(off + i for i in p.vertices) for p in mesh.polygons)
    tree = BVHTree.FromPolygons(V, F)
    front = max(v.x for v in V)
    feature = next(f for f in K.features if f['id'] == fid)
    y, z = feature['pos'][1:]
    setback = []
    for iy in range(-20, 21):
        for iz in range(-20, 21):
            if iy * iy + iz * iz > 400:
                continue
            hit, normal, index, distance = tree.ray_cast(Vector((front + 1, y + iy / 20, z + iz / 20)), Vector((-1, 0, 0)), 6)
            if hit is not None:
                setback.append(front - hit.x)
    maw_read[fid] = dict(sample_circle_diameter=2.0, rays=len(setback),
                         median_first_surface_depth=round(sorted(setback)[len(setback)//2], 3),
                         fraction_reaching_0_5_depth=round(sum(d > .5 for d in setback) / len(setback), 4))
fit = clash.run(K, str(out), code, design.LENGTH)
match, errors = weapon_match.run(K, K.game_ship)
(out / 'weapon_match.json').write_text(json.dumps(match, indent=2) + '\n')
checks = dict(source_revision=baseline if state != 'after' else head, state=state, source_sha256=hashlib.sha256(data).hexdigest(),
              outside=geometry(K.coll.objects), inside=geometry(K.cin.objects), fit=fit['counts'],
              tested=fit['tested'], weapon_match=match['result'], features=K.features, changes=K.changes)
(out / 'checks.json').write_text(json.dumps(checks, indent=2) + '\n')
if errors or any(fit['counts'].values()):
    raise RuntimeError('weapon or fit check failed: ' + str(errors) + str(fit['counts']))

for ob in K.cin.objects:
    ob.hide_render = True
sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.cycles.samples = 16
sc.cycles.use_denoising = True
sc.render.threads_mode = 'FIXED'
sc.render.threads = 6
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
for name, toward, rgb, energy in [('key', (-.5, -.5, -.707), (1, 1, 1), 4 / math.pi),
                                   ('fill', (.66, .66, .35), (1, 1, 1), .8 / math.pi)]:
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
             maw_close=dict(az=15, el=10, dist=19, mm=57, target=(12, 0, -.15), res=(1280, 720)),
             flesh_close=dict(az=54, el=25, dist=22, mm=50, target=(4.5, 0, .2), res=(1280, 720)),
             cam170=dict(az=30, el=90 - math.degrees(.98), dist=170 / 1.6,
                         mm=36 / (2 * math.tan(math.radians(45) / 2) * 1920 / 1080), res=(1280, 720)))
for name, settings in views.items():
    if only and name != only:
        continue
    sc.camera = camera(settings)
    size = settings['res']
    if name == 'concept':
        size = (1080, 720)
    sc.render.resolution_x, sc.render.resolution_y = size
    sc.render.resolution_percentage = 100
    dest = out / (name + '.png')
    sc.render.filepath = str(dest)
    bpy.ops.render.render(write_still=True)
    with Image.open(dest) as original:
        pixels = original.copy()
    sources = None
    if state != 'after':
        src = dict(source_commit=baseline, source_dirty=False, source_diff_sha256='', stage='sheet built')
        sources = [dict(src, picture_name=dest.name, date=datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
                        image_sha256=hashlib.sha256(dest.read_bytes()).hexdigest(), sources=[src])]
    save_picture(pixels, dest, 'sheet built', sources=sources)
    print('921 rendered', code, state, name, flush=True)
checks['cameras'] = views
checks['maw_read'] = maw_read
checks['inside_rows'] = K.inside
checks['preserved_objects'] = {ob.name: geometry([ob]) for ob in K.coll.objects if ob.type == 'MESH' and ob.name not in ('M1_body_flesh','M2_body_flesh','M1_body_flesh2','M2_body_flesh2')}
checks['lip_objects'] = {ob.name: geometry([ob]) for ob in K.coll.objects if ob.name in ('M1_body_flesh','M2_body_flesh','M1_body_flesh2','M2_body_flesh2')}
checks['tendril'] = geometry([o for o in K.coll.objects if o.get('grp') == 'T1'])
checks['unmodified_outline_parts'] = geometry([o for o in K.coll.objects if o.get('grp') not in ('hull', 'M1', 'M2')])
(out / 'checks.json').write_text(json.dumps(checks, indent=2) + '\n')

