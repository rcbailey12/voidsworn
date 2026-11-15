# E14 flare ring study at the battle camera (issue 782; R256: the ring stands upright as in the concept). The first sheet's
# study (issue 739) rendered plain primitives three ways and laid the ring flat; Ryan withdrew that (R256). This one renders
# the BUILT blockout (build.py's deathless_E14_blockout.blend) at the game's battle camera: 34 degrees above the board
# (godot/render/camera_rig.gd home_b 0.98 rad from straight up, range 170, fov 45 vertical), from the bow quarter, the beam and
# the stern quarter, each twice: enlarged, and at the size the game draws it (the ship drawn SHIP_K 1.6 times its 9.5 units,
# 1920 by 1080, about 12.3 px per model unit), the crop shown 1:1 and twice up with no smoothing. It writes on the picture the
# ring's band width and height in game pixels, measured by projecting the ring's own rim through the game-size camera.
# From the beam the upright ring is exactly edge-on at any camera height, so its depth along the ship is the whole band.
#   python e14_ring_study.py BLOCKOUT.blend OUT_DIR [samples]      (the bpy module)
import sys, os, math, json
import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
BLEND, OUT = args[0], args[1]
SAMPLES = int(args[2]) if len(args) > 2 else 16
os.makedirs(OUT, exist_ok=True)
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'ships'))
import deathless_E14 as E  # noqa: E402

bpy.ops.wm.open_mainfile(filepath=BLEND)
sc = bpy.context.scene
EL = math.degrees(math.pi / 2 - 0.98)          # 33.9: camera_rig.gd b = 0.98 rad from straight up
SHIP_K, RANGE, FOV = 1.6, 170.0, 45.0
GAME_H = 1080
PX_UNIT = GAME_H / (2 * RANGE * math.tan(math.radians(FOV / 2))) * SHIP_K   # game pixels per model unit at the battle range
VIEWS = [('bow quarter', 35.0), ('beam', 90.0), ('stern quarter', 145.0)]
TGT = Vector((0.0, 0.0, 0.0))
for o in sc.objects:
    if o.type == 'LIGHT':
        o.hide_render = True


def sun(name, toward, strength, angle=4.0):
    l = bpy.data.lights.new(name, 'SUN'); l.energy = strength; l.angle = math.radians(angle)
    o = bpy.data.objects.new(name, l); sc.collection.objects.link(o)
    o.rotation_euler = Vector(toward).normalized().to_track_quat('Z', 'Y').to_euler()
    return o


def camera(name, heading, game_size, res):
    """heading: the camera's bearing from the bow, + to port; el 34 above the board. game_size: the game's lens and range."""
    a, e = math.radians(heading), math.radians(EL)
    d = Vector((math.cos(e) * math.cos(a), math.cos(e) * math.sin(a), math.sin(e)))
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    dist = RANGE / SHIP_K if game_size else 60.0
    o.location = TGT + d * dist
    o.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    c.sensor_fit = 'VERTICAL'
    if game_size:
        c.angle_y = 2 * math.atan(math.tan(math.radians(FOV / 2)) * res[1] / GAME_H)   # the middle of a 1080-high screen, unscaled
    else:
        c.angle_y = 2 * math.atan(6.4 / dist)
    c.clip_start, c.clip_end = 0.1, dist * 3
    return o


def light_for(heading):
    """a key from above and to the camera's left, a soft fill from the other side: the ring lit the same way at every heading"""
    for o in [o for o in sc.objects if o.name.startswith('study_')]:
        bpy.data.objects.remove(o)
    a = math.radians(heading + 50.0)
    sun('study_key', (math.cos(a) * 0.6, math.sin(a) * 0.6, 0.8), 4.0)
    a = math.radians(heading - 120.0)
    sun('study_fill', (math.cos(a) * 0.8, math.sin(a) * 0.8, 0.3), 0.8, angle=20)


def project(cam, pts, res):
    out = []
    for p in pts:
        v = world_to_camera_view(sc, cam, Vector(p))
        out.append((v.x * res[0], (1 - v.y) * res[1]))
    return out


sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = SAMPLES; sc.cycles.use_denoising = True
sc.render.film_transparent = False
sc.world.node_tree.nodes['Background'].inputs[0].default_value = (0.012, 0.012, 0.018, 1)
sc.render.resolution_percentage = 100
GRES, BRES = (220, 160), (400, 300)
rows = []
# the ring's rim: the outer rim's back and front edges at the top plate, and the whole outer circle front and back
rim_back, rim_front = E.XR - E.D / 2, E.XR + E.D / 2 + E.LIP
circle = [E.rp(x, E.R_OUT, t) for x in (rim_back, rim_front) for t in range(0, 360, 5)]
for name, hd in VIEWS:
    light_for(hd)
    rec = dict(view=name, heading=hd)
    for tag, gs, res in (('big', False, BRES), ('game', True, GRES)):
        cam = camera('study_%s_%s' % (tag, name.replace(' ', '_')), hd, gs, res)
        sc.camera = cam
        sc.render.resolution_x, sc.render.resolution_y = res
        sc.render.filepath = os.path.join(OUT, 'study_%s_%d.png' % (tag, int(hd)))
        bpy.ops.render.render(write_still=True)
        if gs:
            pc = project(cam, circle, res)
            xs = [p[0] for p in pc]; ys = [p[1] for p in pc]
            top = project(cam, [E.rp(rim_back, E.R_OUT, 90.0), E.rp(rim_front, E.R_OUT, 90.0)], res)
            rec['band_px'] = round(math.dist(top[0], top[1]), 1)          # the rim's depth at the top plate, on screen
            rec['ring_w_px'] = round(max(xs) - min(xs), 1); rec['ring_h_px'] = round(max(ys) - min(ys), 1)
            rec['ring_c_px'] = project(cam, [(E.XR, 0.0, 0.0)], res)[0]                 # the ring's centre on screen, for the crop
    rows.append(rec)
json.dump(dict(px_per_unit=round(PX_UNIT, 2), elevation=round(EL, 1), views=rows), open(os.path.join(OUT, 'ring_study.json'), 'w'), indent=1)

# one named picture, 1280 by 720: a column per view; the enlarged render above, the game-size crop 1:1 and twice up below
from PIL import Image, ImageDraw, ImageFont
def F(n):
    for f_ in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf'):
        if os.path.exists(f_):
            return ImageFont.truetype(f_, n)
    return ImageFont.load_default()
W, H = 1280, 720
im = Image.new('RGB', (W, H), (40, 40, 42)); d = ImageDraw.Draw(im)
d.text((16, 10), 'deathless_E14 flare | the upright ring at the battle camera (34 degrees above the board, R256)', fill=(240, 230, 210), font=F(22))
d.text((16, 40), 'the built blockout; below each: the game\'s size at range 170 (%.1f px per unit), 1:1 and twice up' % PX_UNIT, fill=(186, 190, 198), font=F(15))
for j, rec in enumerate(rows):
    x0 = 16 + j * 422
    d.text((x0, 70), 'battle camera, %s' % rec['view'], fill=(240, 180, 90), font=F(17))
    big = Image.open(os.path.join(OUT, 'study_big_%d.png' % int(rec['heading']))).convert('RGB')
    im.paste(big, (x0, 96))
    g = Image.open(os.path.join(OUT, 'study_game_%d.png' % int(rec['heading']))).convert('RGB')
    im.paste(g, (x0, 404))
    cx_, cy_ = [int(round(v)) for v in rec['ring_c_px']]
    cx_ = max(45, min(GRES[0] - 45, cx_)); cy_ = max(35, min(GRES[1] - 35, cy_))
    im.paste(g.crop((cx_ - 45, cy_ - 35, cx_ + 45, cy_ + 35)).resize((180, 140), Image.NEAREST), (x0 + 226, 414))
    d.text((x0, 566), '1:1, the game\'s size', fill=(186, 190, 198), font=F(13)); d.text((x0 + 226, 566), 'the ring\'s centre, twice up', fill=(186, 190, 198), font=F(13))
    if rec['view'] == 'beam':
        line = 'edge-on: a band %.0f px wide and %.0f px tall' % (rec['band_px'], rec['ring_h_px'])
    else:
        line = 'the ring %.0f px across, %.0f px tall; rim %.0f px deep' % (rec['ring_w_px'], rec['ring_h_px'], rec['band_px'])
    d.text((x0, 582), line, fill=(236, 236, 240), font=F(15))
d.text((16, 640), 'Ring 6.0 across, %.1f deep at its rim (%.1f at its inner edge); twelve plates, corona lines on the rim edges and down each plate.' % (E.D + E.LIP, E.D),
       fill=(236, 236, 240), font=F(15))
d.text((16, 664), 'The null lance\'s muzzle is the bright aperture at the ring\'s centre. Measured by projecting the ring\'s rim through the game-size camera.',
       fill=(186, 190, 198), font=F(15))
im.save(os.path.join(OUT, 'deathless_E14_ring_study.jpg'), quality=90)
print('WROTE', os.path.join(OUT, 'deathless_E14_ring_study.jpg'), json.dumps(rows))
