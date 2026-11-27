"""Save the packed paint proof and five CPU Cycles views. Blender -b S9A.blend -P this_file -- OUT."""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
from picture_provenance import stamp_file
sys.path.insert(0, str(ROOT / 'tools/blender/kits/shared'))
from paint_colors import battle_lift

OUT = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
OUT.mkdir(parents=True, exist_ok=True)
scene = bpy.context.scene
code = scene['r209_sheet']
camera_path = ROOT / 'tools/blender/build_sheets/ships' / (code + '_camera.json')
beauty = json.loads(camera_path.read_text())

# Count the real painted meshes before adding lights. Each flak pivot draws
# its own material surfaces even when both turrets share the parts atlas.
groups = {}
depsgraph = bpy.context.evaluated_depsgraph_get()
for obj in scene.objects:
    if obj.type != 'MESH':
        continue
    key = 'interior' if obj.get('role') == 'interior' else 'fixed_exterior'
    if obj.parent and obj.parent.get('turret'):
        key = obj.parent.name
    row = groups.setdefault(key, {'triangles': 0, 'materials': set()})
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    mesh.calc_loop_triangles()
    row['triangles'] += len(mesh.loop_triangles)
    for index in {poly.material_index for poly in mesh.polygons}:
        row['materials'].add(mesh.materials[index].name)
    evaluated.to_mesh_clear()
for row in groups.values():
    row['materials'] = sorted(row['materials'])
(OUT / 'painted_mesh_budget.json').write_text(json.dumps(groups, indent=2) + '\n')
# The stack packs the baked atlases. Save the clean model before adding the
# review rig or applying the battle viewer's lighting adjustment.
bpy.ops.wm.save_as_mainfile(filepath=str(OUT.parent / 'S9A_painted.blend'), compress=True, copy=True)

scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'AgX'
scene.render.film_transparent = False

world = bpy.data.worlds.new('Iron review studio')
scene.world = world
world.use_nodes = True
nodes, links = world.node_tree.nodes, world.node_tree.links
ambient = nodes['Background']
ambient.inputs[0].default_value = (.43, .45, .50, 1)
backdrop = nodes.new('ShaderNodeBackground')
backdrop.inputs[0].default_value = (.018, .026, .039, 1)
mix = nodes.new('ShaderNodeMixShader')
links.new(nodes.new('ShaderNodeLightPath').outputs['Is Camera Ray'], mix.inputs[0])
links.new(ambient.outputs[0], mix.inputs[1])
links.new(backdrop.outputs[0], mix.inputs[2])
links.new(mix.outputs[0], nodes['World Output'].inputs[0])

# Lighting and game albedo compensation follow the Picket blind-pair proof rig.
for name, ray, power, colour in [('Key', (-.45,.55,-.70), 2, (1,.96,.90)),
                                  ('Fill', (.6,-.75,-.2), .5, (.55,.65,.85))]:
    light = bpy.data.lights.new(name, 'SUN')
    light.energy, light.angle, light.color = power*math.pi, math.radians(1.5), colour
    obj = bpy.data.objects.new(name, light)
    scene.collection.objects.link(obj)
    obj.rotation_euler = Vector(ray).to_track_quat('-Z','Y').to_euler()

for mat in bpy.data.materials:
    if not mat.get('p3_textured') or not mat.use_nodes or mat.get('authored_look'):
        continue
    tree = mat.node_tree
    base = tree.nodes['Principled BSDF'].inputs['Base Color']
    source = base.links[0].from_socket
    scale = tree.nodes.new('ShaderNodeVectorMath')
    scale.operation = 'SCALE'
    scale.inputs['Scale'].default_value = battle_lift('voidsworn')
    tree.links.new(source, scale.inputs[0])
    tree.links.new(scale.outputs['Vector'], base)

lens = bpy.data.cameras.new('Proof lens')
cam = bpy.data.objects.new('Proof camera', lens)
scene.collection.objects.link(cam)
scene.camera = cam
lens.clip_start = .01


def render(label, direction, width, fitted=False, battle=False):
    length = scene['r209_length_world']
    origin = Vector(beauty['target']) / length if fitted else Vector((0,0,.024))
    distance = beauty['dist']/length if fitted else 2.0
    if battle:
        origin = Vector((0,0,0))
        distance = 170/(1.6*length)
    cam.location = origin + Vector(direction).normalized()*distance
    cam.rotation_euler = (origin-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.resolution_x, scene.render.resolution_y = 1280,720
    scene.view_settings.exposure = 0 if battle else .8
    lens.type = 'ORTHO'
    lens.ortho_scale = width
    scene.render.use_border = scene.render.use_crop_to_border = battle
    if fitted:
        cam.rotation_euler.rotate_axis('Z',math.radians(beauty['roll']))
        # Keep the bow clear of the provenance strip in the landscape proof.
        lens.type, lens.sensor_fit, lens.lens = 'PERSP','HORIZONTAL',beauty['mm']*.75
    if battle:
        lens.type, lens.sensor_fit = 'PERSP','VERTICAL'
        lens.lens = lens.sensor_height / (2*math.tan(math.radians(45)/2))
        scene.render.resolution_x, scene.render.resolution_y = 1920,1080
        scene.render.border_min_x = scene.render.border_min_y = .25
        scene.render.border_max_x = scene.render.border_max_y = .75
    path = OUT / (code + '_' + label + '.png')
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    with Image.open(path) as source:
        labeled = source.convert('RGB')
    draw = ImageDraw.Draw(labeled)
    try:
        font = ImageFont.truetype('segoeui.ttf', 22)
    except OSError:
        font = ImageFont.load_default()
    title = label.replace('_',' ').title()
    draw.text((23,18), f'ASTRA  /  S9A Warden  /  {title}', fill='#e6e2dc', font=font)
    labeled.save(path)
    stamp_file(path, 'paint proof', repo=ROOT, new_render=True)


az, el = [math.radians(beauty[k]) for k in ('az','el')]
render('three_quarter', (math.cos(az)*math.cos(el),math.sin(az)*math.cos(el),math.sin(el)), 1, fitted=True)
render('side', (0,1,0), 1.14)
render('top', (0,.0001,1), 1.14)
render('underside', (.23,.45,-1), 1.15)
render('battle_170', (0,math.sin(.98),math.cos(.98)), 1, battle=True)
