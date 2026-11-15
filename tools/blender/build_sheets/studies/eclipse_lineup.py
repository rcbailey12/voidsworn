# The Eclipse fleet line-up (issue 739): the four Eclipse sheet ships (E11 The Unsetting, E12 zenith, E14 flare, E13 mote) from
# straight above at ONE scale, each built from its own build sheet (tools/blender/build_sheets/ships/<code>.py) at its class length
# (godot/render/hull_table.gd CLS_LEN, docs/playbooks/scale.md), bow up, with a scale bar and one board hex drawn at the same scale
# (a hex is 20 units across its corners on the board, where ships are drawn at their length x SHIP_K 1.6, so 12.5 ship units).
# One named picture, 1280 by 720.
#   python eclipse_lineup.py OUT_DIR      (the bpy module; or blender -b -P eclipse_lineup.py -- OUT_DIR)
import os, sys, math, importlib.util
import bpy
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__)); SHEETS = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, SHEETS)
import kit  # noqa: E402

OUT = (sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:])[0]
os.makedirs(OUT, exist_ok=True)
SHIPS = [('deathless_E11', 'E11 The Unsetting', 'flagship, Tomb-ark'), ('deathless_E12', 'E12 zenith', 'cruiser, Cruiser'),
         ('deathless_E14', 'E14 flare', 'destroyer, Destroyer'), ('deathless_E13', 'E13 mote', 'frigate, Frigate')]
PX = 20.0            # pixels per world unit, the one scale
HEX_UNITS = 20.0 / 1.6


def render_top(code):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sp = importlib.util.spec_from_file_location(code, os.path.join(SHEETS, 'ships', code + '.py'))
    d = importlib.util.module_from_spec(sp); sp.loader.exec_module(d)
    kit.use_kit(getattr(d, 'KIT', 'hullbreakers'))
    K = kit.Kit(code, d.LENGTH); d.build(K); K.finish()
    for o in K.cin.objects:
        o.hide_render = True
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    lo = Vector((1e9, 1e9, 1e9)); hi = -lo
    for o in K.coll.objects:
        if o.type != 'MESH':
            continue
        e = o.evaluated_get(dg)
        for v in e.data.vertices:
            w = o.matrix_world @ v.co; lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
    sc = bpy.context.scene
    w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.2, 0.2, 0.2, 1); w.node_tree.nodes['Background'].inputs[1].default_value = 0.7
    l = bpy.data.lights.new('key', 'SUN'); l.energy = 4.0; lo_ = bpy.data.objects.new('key', l); sc.collection.objects.link(lo_)
    lo_.rotation_euler = Vector((0.5, 0.5, 0.7)).to_track_quat('Z', 'Y').to_euler()
    pad = 0.3
    Lx, Ly = hi.x - lo.x + 2 * pad, hi.y - lo.y + 2 * pad
    c = bpy.data.cameras.new('top'); c.type = 'ORTHO'; c.ortho_scale = max(Lx, Ly)
    co = bpy.data.objects.new('top', c); sc.collection.objects.link(co)
    cx, cy = (lo.x + hi.x) / 2, (lo.y + hi.y) / 2
    # bow up the page, port on the left (as the sheets' top view)
    co.matrix_world = Matrix(((0, 1, 0, cx), (-1, 0, 0, cy), (0, 0, 1, hi.z + 50), (0, 0, 0, 1)))
    sc.camera = co
    sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = int(os.environ.get('SHEET_SAMPLES', 16)); sc.cycles.use_denoising = True
    sc.render.film_transparent = True; sc.view_settings.view_transform = 'Standard'
    sc.render.resolution_x = int(round(Ly * PX)); sc.render.resolution_y = int(round(Lx * PX)); sc.render.resolution_percentage = 100
    sc.render.filepath = os.path.join(OUT, code + '_lineup_top.png')
    bpy.ops.render.render(write_still=True)
    return d.LENGTH, hi.x - lo.x, hi.y - lo.y


rows = [(code, name, cls) + render_top(code) for code, name, cls in SHIPS]

from PIL import Image, ImageDraw, ImageFont


def font(n):
    for p in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf'):
        try:
            return ImageFont.truetype(p, n)
        except OSError:
            pass
    return ImageFont.load_default()


W, H = 1280, 720
im = Image.new('RGB', (W, H), (36, 36, 38)); dr = ImageDraw.Draw(im)
dr.text((16, 10), 'Eclipse fleet line-up, from above, one scale (%d px per world unit), bow up' % PX, fill=(240, 230, 210), font=font(24))
dr.text((16, 42), 'lengths from godot/render/hull_table.gd CLS_LEN (docs/playbooks/scale.md); the board draws each x 1.6', fill=(170, 168, 160), font=font(16))
x = 40; base = 712
for code, name, cls, L, mlen, beam in rows:
    t = Image.open(os.path.join(OUT, code + '_lineup_top.png')).convert('RGBA')
    y = base - t.height
    im.paste(t, (x, y), t)
    dr.text((x, y - 50), name, fill=(240, 180, 90), font=font(19))
    dr.text((x, y - 26), '%s, %.1f long, %.1f across' % (cls.split(', ')[0], L, beam), fill=(205, 200, 190), font=font(15))
    x += t.width + 50
# one board hex at the same scale, and a 5 unit scale bar
hx, hy, r = W - 170, 300, HEX_UNITS / 2 * PX
dr.polygon([(hx + r * math.cos(math.radians(60 * k)), hy + r * math.sin(math.radians(60 * k))) for k in range(6)], outline=(120, 160, 200), width=2)
dr.text((hx - r, hy + r + 8), 'one board hex at this scale', fill=(150, 180, 210), font=font(15))
dr.rectangle((W - 260, base - 10, W - 260 + 5 * PX, base), outline=(232, 228, 218), width=1)
dr.text((W - 260, base - 32), '5 units', fill=(232, 228, 218), font=font(15))
im.save(os.path.join(OUT, 'eclipse_lineup.jpg'), quality=90)
print('WROTE', os.path.join(OUT, 'eclipse_lineup.jpg'))
