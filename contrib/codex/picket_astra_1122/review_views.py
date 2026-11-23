"""Render five CPU Cycles views of the recipe blend. Run with Blender -b BLEND -P this_file -- OUTPUT."""
import math
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
from picture_provenance import stamp_file
sys.path.insert(0, str(ROOT / 'tools/blender/kits/shared'))
from paint_colors import battle_lift

output = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
output.mkdir(parents=True, exist_ok=True)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'AgX'
scene.render.film_transparent = False
world = bpy.data.worlds.new('Review studio')
scene.world = world
world.use_nodes = True
nodes, links = world.node_tree.nodes, world.node_tree.links
ambient = nodes['Background']
ambient.inputs[0].default_value = (.43,.45,.5,1)
backdrop = nodes.new('ShaderNodeBackground')
backdrop.inputs[0].default_value = (.018,.026,.039,1)
mix = nodes.new('ShaderNodeMixShader')
links.new(nodes.new('ShaderNodeLightPath').outputs['Is Camera Ray'],mix.inputs[0])
links.new(ambient.outputs[0],mix.inputs[1])
links.new(backdrop.outputs[0],mix.inputs[2])
links.new(mix.outputs[0],nodes['World Output'].inputs[0])


def sunlight(name, ray, power, colour):
    light = bpy.data.lights.new(name,'SUN')
    light.energy, light.angle, light.color = power*math.pi,math.radians(1.5),colour
    obj = bpy.data.objects.new(name,light)
    scene.collection.objects.link(obj)
    obj.rotation_euler = Vector(ray).to_track_quat('-Z','Y').to_euler()


# Same Blender-space key, fill and linear albedo adjustment as paint_sheet.py.
sunlight('Key',(-.45,.55,-.70),2.0,(1,.96,.90))
sunlight('Fill',(.6,-.75,-.2),.5,(.55,.65,.85))
lift = battle_lift('hegemony')
for mat in bpy.data.materials:
    if not mat.get('p3_textured') or not mat.use_nodes:
        continue
    tree = mat.node_tree
    base = tree.nodes['Principled BSDF'].inputs['Base Color']
    source = base.links[0].from_socket
    scale = tree.nodes.new('ShaderNodeVectorMath')
    scale.operation = 'SCALE'
    scale.inputs['Scale'].default_value = lift
    tree.links.new(source,scale.inputs[0])
    tree.links.new(scale.outputs['Vector'],base)
camera = bpy.data.cameras.new('Review lens')
camera.clip_end = 100
cam = bpy.data.objects.new('Review camera',camera)
scene.collection.objects.link(cam)
scene.camera = cam


def view(label, direction, width, battle=False, fitted=None):
    origin = Vector((0,0,0))
    class_length = scene['r209_length_world']
    distance = 170/(class_length * 1.6) if battle else 2.0
    if fitted:
        distance = fitted['dist']/class_length
    cam.location = origin + Vector(direction).normalized()*distance
    cam.rotation_euler = (origin-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.resolution_x, scene.render.resolution_y = 1152,648
    scene.view_settings.exposure = 0.0 if battle else .8
    camera.type = 'ORTHO'
    camera.ortho_scale = width
    scene.render.use_border = battle
    scene.render.use_crop_to_border = battle
    if fitted:
        cam.rotation_euler.rotate_axis('Z',math.radians(fitted['roll']))
        camera.type = 'PERSP'
        camera.sensor_fit = 'HORIZONTAL'
        camera.lens = fitted['mm'] * 1.22
    if battle:
        camera.type = 'PERSP'
        camera.sensor_fit = 'VERTICAL'
        camera.lens = camera.sensor_height / (2*math.tan(math.radians(45)/2))
        scene.render.resolution_x, scene.render.resolution_y = 1920,1080
        scene.render.border_min_x = scene.render.border_min_y = .25
        scene.render.border_max_x = scene.render.border_max_y = .75
    path = output / ('hegemony_H7A_'+label+'.png')
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    stamp_file(path, 'paint proof', repo=ROOT, new_render=True)


fitted = json.loads(Path(__file__).with_name('hegemony_H7A_camera.json').read_text())
az, el = (math.radians(fitted[k]) for k in ('az','el'))
view('three_quarter', (math.cos(az)*math.cos(el),math.sin(az)*math.cos(el),math.sin(el)),
     1.05, fitted=fitted)
view('side', (0,1,0),1.14)
view('top', (0,.0001,1),1.14)
view('underside', (.25,.52,-1),1.22)
view('battle_170', (0,math.sin(.98),math.cos(.98)),1,battle=True)
