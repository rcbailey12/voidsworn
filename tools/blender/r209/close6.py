# Issue 209 round 6: weapon close-ups at the concept's own camera, so a crop of the concept and the same crop of each cell line up
# pixel for pixel (same angle, same zoom). The concept camera is rendered 4x larger (4096 px) with a render border round each weapon
# region; the sheet crops the concept at the same pixels and scales it 4x.
# Regions in concept pixels (1024 px image): cas (the bow casemates), bow (the twin bow guns), drums (the drum racks round the
# tower), aft (the aft drums and turrets). Paint under the studio rig and the concept rig, and clay.
# usage: blender -b CELL.blend -P close6.py -- OUT_DIR CELL [samples]
import os, sys, math, json
import bpy
from mathutils import Vector, Matrix
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
a = sys.argv[sys.argv.index('--') + 1:]; OUT, CELL = a[0], a[1]; SAMPLES = int(a[2]) if len(a) > 2 else 64
os.makedirs(OUT, exist_ok=True)
REGIONS = dict(cas=(170, 470, 510, 700), bow=(130, 380, 410, 530), drums=(330, 250, 730, 460), aft=(680, 200, 1010, 430))
SCALE = 4
CAMJ = os.path.join(HERE, '..', '..', '..', 'docs', 'shots', 'ship_pipeline', 'route209', 'round4', 'concept_camera.json')
sc = bpy.context.scene; sc.render.engine = 'CYCLES'
prefs = bpy.context.preferences.addons['cycles'].preferences
for t in ('OPTIX', 'CUDA'):
    try:
        prefs.compute_device_type = t; prefs.get_devices()
        if not [d for d in prefs.devices if d.type == t]: continue
        for d in prefs.devices: d.use = True
        sc.cycles.device = 'GPU'; break
    except Exception: pass
sc.cycles.samples = SAMPLES; sc.cycles.use_denoising = True; sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = 'None'
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs['Color'].default_value = (.035, .037, .042, 1)
RIGS = {'studio': ((('key', (50, 0, 140), 4.0, 2), ('fill', (115, 0, -40), 1.0, 8), ('rim', (60, 0, -95), 2.2, 3)), 1.6),
        'concept': ((('key', (28, 0, 165), 4.2, 3), ('fill', (100, 0, 60), .7, 10), ('rim', (65, 0, -95), 1.0, 3)), .75)}
lights = []
def rig(name):
    for o in lights: bpy.data.objects.remove(o)
    lights.clear(); r, e = RIGS[name]; sc.view_settings.exposure = e
    for nm, rot, en, ang in r:
        L = bpy.data.lights.new(nm, 'SUN'); L.energy = en; L.angle = math.radians(ang); o = bpy.data.objects.new(nm, L); sc.collection.objects.link(o)
        o.rotation_euler = [math.radians(v) for v in rot]; lights.append(o)
p = json.load(open(CAMJ))['camera']; az, el = math.radians(p['az']), math.radians(p['el'])
t = Vector((0, 0, -.01)); d = Vector((math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)))
c = bpy.data.cameras.new('concept'); o = bpy.data.objects.new('concept', c); sc.collection.objects.link(o); sc.camera = o
o.location = t + d * p['dist']; o.rotation_euler = (t - o.location).to_track_quat('-Z', 'Y').to_euler(); c.lens = p['focal'] / 1024 * 36
o.rotation_euler = (o.rotation_euler.to_matrix() @ Matrix.Rotation(math.radians(p['roll']), 3, 'Z')).to_euler()
c.sensor_fit = 'HORIZONTAL'; c.sensor_width = 36; c.shift_x = -(p['cx'] - 512) / 1024; c.shift_y = (p['cy'] - 512) / 1024; c.clip_start = .01
sc.render.resolution_x = sc.render.resolution_y = 1024 * SCALE; sc.render.resolution_percentage = 100
sc.render.use_border = True; sc.render.use_crop_to_border = True
import common as C
C.mats()
for nm, (x0, y0, x1, y1) in REGIONS.items():
    sc.render.border_min_x, sc.render.border_max_x = x0 / 1024, x1 / 1024
    sc.render.border_min_y, sc.render.border_max_y = 1 - y1 / 1024, 1 - y0 / 1024
    for look in ('studio', 'concept', 'clay'):
        rig('studio' if look == 'clay' else look)
        bpy.context.view_layer.material_override = bpy.data.materials.get('clay') if look == 'clay' else None
        sc.render.filepath = os.path.join(OUT, f'{CELL}_{nm}_{look}.png'); bpy.ops.render.render(write_still=True)
        print('[209] close', CELL, nm, look, flush=True)
bpy.context.view_layer.material_override = None
print('[209] CLOSE DONE', CELL, flush=True)
