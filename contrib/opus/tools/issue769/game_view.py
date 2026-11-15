# Issue 769 helper (sandbox only, not a standing check): renders build sheet ships together at their game size, through the
# game's battle camera, for the read test and the pictures. Runs with the bpy module:
#   python game_view.py OUT.png SCENE [W H]
# Environment: GV_FULL=1 renders the whole 1920 x 1080 frame (default: its middle third); GV_SAMPLES; GV_DIST, GV_EL, GV_AZ,
# GV_TARGET, GV_FOV move the camera off the battle camera; GV_ORTHO=<board units across> makes it orthographic (the scale picture,
# where every ship's length on the picture is to scale).
# SCENE is a JSON list of placements: [code, x, y, heading_deg, count, scale], where code is a build sheet (tools/blender/
# build_sheets/ships/<code>.py), x and y are board units (+x to the right of the screen, +y away from the camera), heading is the
# bow's bearing (0 = to the screen's right, 90 = away), count the craft in the wing (1 for a ship), scale the factor from the
# sheet's length to the board length (a craft: 3.84 / 1.6 = 2.4, godot/render/ship_view.gd; a ship: SHIP_K 1.6).
# A wing of four uses the game's own formation offsets (godot/render/squadron_wing.gd setup: rests). The camera is the game's
# battle camera (godot/render/camera_rig.gd: vertical fov 45, range 170, b 0.98 rad from straight up, so 33.9 degrees above the
# board); the key light is look.gd's KEY_DIR, a fifth of it as fill. Unpainted blockout colours on the game's near-black sky.
import sys, os, json, math, importlib.util
import bpy
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..'))
SHEETS = os.path.join(REPO, 'tools', 'blender', 'build_sheets')
sys.path.insert(0, SHEETS)
import kit  # noqa: E402

out = sys.argv[1]
scene = json.loads(sys.argv[2])
W, H = (int(sys.argv[3]), int(sys.argv[4])) if len(sys.argv) > 4 else (1920, 1080)
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
built = {}


def build(code):
    if code in built:
        return built[code]
    sp = importlib.util.spec_from_file_location(code, os.path.join(SHEETS, 'ships', code + '.py'))
    d = importlib.util.module_from_spec(sp); sp.loader.exec_module(d)
    kit.use_kit(getattr(d, 'KIT', 'hullbreakers'))
    K = kit.Kit(code, d.LENGTH); d.build(K); K.finish()
    for o in K.cin.objects:
        o.hide_render = True
    bpy.context.view_layer.layer_collection.children[K.coll.name].exclude = True
    bpy.context.view_layer.layer_collection.children[K.cin.name].exclude = True
    built[code] = K.coll
    return K.coll


# the game's wing formation (squadron_wing.gd): offsets in craft lengths, Godot frame (x bow, y up, z side)
def rests(count):
    out_ = [Vector((0, 0, 0))]
    for i in range(1, count):
        k = 1 + (i - 1) // 2
        out_.append(Vector((-0.95 * k, 0.12 if i % 2 else -0.09, (0.95 if i % 2 else -1.02) * k)))
    return out_


for code, x, y, hd, count, scale in scene:
    coll = build(code)
    for off in rests(int(count)):
        e = bpy.data.objects.new('%s_inst' % code, None)
        e.instance_type = 'COLLECTION'; e.instance_collection = coll
        sc.collection.objects.link(e)
        L_board = 1.6 * scale   # the craft's board length (its sheet is 1.6 long)
        # Godot (x bow, y up, z side) to Blender (x bow, y = -z, z = y), then turned to the heading
        o = Vector((off.x, -off.z, off.y)) * L_board
        R = Matrix.Rotation(math.radians(hd), 4, 'Z')
        e.matrix_world = Matrix.Translation(Vector((x, y, 0)) + (R @ o)) @ R @ Matrix.Scale(scale, 4)

world = bpy.data.worlds.new('w'); sc.world = world; world.use_nodes = True
world.node_tree.nodes['Background'].inputs[0].default_value = (0.012, 0.012, 0.016, 1)
world.node_tree.nodes['Background'].inputs[1].default_value = 1.0


def sun(name, frm, e):
    l = bpy.data.lights.new(name, 'SUN'); l.energy = e; l.angle = math.radians(3)
    ob = bpy.data.objects.new(name, l); sc.collection.objects.link(ob)
    ob.rotation_euler = Vector(frm).normalized().to_track_quat('Z', 'Y').to_euler()


# look.gd KEY_DIR (-0.45, -0.70, -0.55) is the light's travel in Godot; in Blender (x, -z, y) it comes from (0.45, -0.55, 0.70)
sun('key', (0.45, -0.55, 0.70), 4.0)
sun('fill', (-0.45, 0.55, 0.3), 0.8)
cam = bpy.data.cameras.new('battle'); cam.sensor_fit = 'VERTICAL'; cam.angle_y = math.radians(float(os.environ.get('GV_FOV', 45.0))); cam.clip_end = 2000
co = bpy.data.objects.new('battle', cam); sc.collection.objects.link(co)
# GV_DIST, GV_EL, GV_AZ (degrees round from the screen's bottom), GV_TARGET (x,y): a closer studio view for the scale picture;
# unset, the battle camera
el = math.radians(float(os.environ.get('GV_EL', 90 - math.degrees(0.98))))
dist = float(os.environ.get('GV_DIST', 170.0)); az = math.radians(float(os.environ.get('GV_AZ', 0.0)))
tgt = Vector([float(v) for v in os.environ.get('GV_TARGET', '0,0').split(',')] + [0.0])
co.location = tgt + Vector((dist * math.cos(el) * math.sin(az), -dist * math.cos(el) * math.cos(az), dist * math.sin(el)))
co.rotation_euler = (tgt - co.location).to_track_quat('-Z', 'Y').to_euler()
if os.environ.get('GV_ORTHO'):
    cam.type = 'ORTHO'; cam.ortho_scale = float(os.environ['GV_ORTHO']); cam.sensor_fit = 'HORIZONTAL'   # board units across the frame
sc.camera = co
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = int(os.environ.get('GV_SAMPLES', 24)); sc.cycles.use_denoising = False
sc.render.resolution_x, sc.render.resolution_y = W, H
sc.render.film_transparent = False
sc.view_settings.view_transform = 'Standard'
# the middle third of the screen (640 x 360 of 1920 x 1080), as paint_sheet.py's cam170 does: the ships at their real pixel size
if os.environ.get('GV_FULL') != '1':
    sc.render.use_border = True; sc.render.use_crop_to_border = True
    sc.render.border_min_x, sc.render.border_max_x, sc.render.border_min_y, sc.render.border_max_y = 1 / 3, 2 / 3, 1 / 3, 2 / 3
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
print('wrote', out)
