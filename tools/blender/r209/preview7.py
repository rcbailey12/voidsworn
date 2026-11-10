# Issue 209 round 7: the sandbox preview (CPU Cycles, no bake). Builds a cell, paints it with the procedural materials directly and
# renders the views the round 7 sheets need. The PC run (bakeAb6.py, render.py) is the full-quality version of the same pictures.
# usage: python3.11 preview7.py OUT_DIR MODULE [name=TAG] [res=1024] [samples=16] [views=concept,side,top,...] [clay=0|1]
#                               [light=studio|concept] [paint=paint] [crop=x0,y0,x1,y1] [save=1]
#   views: concept (the concept's own fitted camera), side, top, below, front (orthographic, bow on the left), battle,
#          cas, bow, drums, aft, hull (close-ups along the concept's viewing direction)
#   crop:  for the concept view only: render just this box of the 1024 px concept frame, at res px per full frame (a close crop
#          at the concept camera without paying for the whole frame)
#   save:  also save OUT_DIR/TAG.blend
# The ship json comes from R209_SHIP, the tune from R209_TUNE_JSON, as in the recipe.
import os, sys, math, json, importlib, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import bpy
from mathutils import Vector, Matrix
a = sys.argv[1:]; OUT, MOD = a[0], a[1]
kw = dict(x.split('=', 1) for x in a[2:] if '=' in x)
RES = int(kw.get('res', 1024)); SAMP = int(kw.get('samples', 16)); VIEWS = kw.get('views', 'concept').split(','); CLAY = kw.get('clay', '0') == '1'
TAG = kw.get('name', MOD); LIGHT = kw.get('light', 'studio')
os.makedirs(OUT, exist_ok=True); t0 = time.time()
M = importlib.import_module(MOD)
S, Pl, hard, gen, notes, prox = M.build_geometry()
import common as C
P = importlib.import_module(kw.get('paint', 'paint'))
P.assign(S + Pl + hard, S + Pl)
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = SAMP; sc.cycles.use_denoising = True
sc.view_settings.view_transform = 'AgX'
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; bg = w.node_tree.nodes['Background']
bg.inputs['Color'].default_value = (.035, .037, .042, 1)
# the same two rigs as render.py: the studio rig of every round, and the concept painting's own light (round 6)
LIGHTS = {'studio': ((('key', (50, 0, 140), 4.0, 2), ('fill', (115, 0, -40), 1.0, 8), ('rim', (60, 0, -95), 2.2, 3)), 1.6),
          'concept': ((('key', (28, 0, 165), 4.2, 3), ('fill', (100, 0, 60), .7, 10), ('rim', (65, 0, -95), 1.0, 3)), .75)}
rig, expo = LIGHTS[LIGHT]; sc.view_settings.exposure = expo
for nm, rot, e, ang in rig:
    L = bpy.data.lights.new(nm, 'SUN'); L.energy = e; L.angle = math.radians(ang); o = bpy.data.objects.new(nm, L); sc.collection.objects.link(o)
    o.rotation_euler = [math.radians(v) for v in rot]
if CLAY:
    C.mats(); bpy.context.view_layer.material_override = bpy.data.materials.get('clay')
CAMJ = os.path.join(HERE, '..', '..', '..', 'docs', 'shots', 'ship_pipeline', 'route209', 'round4', 'concept_camera.json')
T0 = Vector((0, 0, -.01))

def cam(name, loc, look, lens=50, res=(RES, RES), ortho=None, up=None):
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    o.location = loc; d = Vector(look) - Vector(loc); o.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    if up is not None:      # explicit up vector (top and below keep the bow on the left)
        f = d.normalized(); r = f.cross(Vector(up)).normalized(); u = r.cross(f)
        o.rotation_euler = Matrix((r, u, -f)).transposed().to_euler()
    if ortho: c.type = 'ORTHO'; c.ortho_scale = ortho
    else: c.lens = lens
    c.clip_start = .005; c.clip_end = 50
    sc.camera = o; sc.render.resolution_x, sc.render.resolution_y = res; sc.render.use_border = False; return o

def concept():
    p = json.load(open(CAMJ))['camera']; az, el = math.radians(p['az']), math.radians(p['el'])
    d = Vector((math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)))
    o = cam('concept', T0 + d * p['dist'], T0, lens=p['focal'] / 1024 * 36)
    o.rotation_euler = (o.rotation_euler.to_matrix() @ Matrix.Rotation(math.radians(p['roll']), 3, 'Z')).to_euler()
    o.data.sensor_fit = 'HORIZONTAL'; o.data.sensor_width = 36; o.data.shift_x = -(p['cx'] - 512) / 1024; o.data.shift_y = (p['cy'] - 512) / 1024
    if 'crop' in kw:
        x0, y0, x1, y1 = [float(v) / 1024 for v in kw['crop'].split(',')]
        sc.render.use_border = True; sc.render.use_crop_to_border = True
        sc.render.border_min_x, sc.render.border_max_x = x0, x1; sc.render.border_min_y, sc.render.border_max_y = 1 - y1, 1 - y0
    return o

p = json.load(open(CAMJ))['camera']; az, el = math.radians(p['az']), math.radians(p['el'])
D = Vector((math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)))
CLOSE = dict(cas=((.29, .17, -.05), .55), bow=((.36, 0, .07), .45), drums=((.12, .05, .10), .6), aft=((-.30, 0, .10), .6), hull=((.33, .13, -.04), .42))
WIDE = (int(RES * 16 / 9), RES)
for v in VIEWS:
    if v == 'concept': concept()
    elif v == 'side': cam(v, T0 + Vector((0, 3, 0)), T0, ortho=1.2, res=WIDE)          # port side, bow on the left
    elif v == 'top': cam(v, T0 + Vector((0, 0, 3)), T0, ortho=1.2, res=WIDE, up=(0, -1, 0))
    elif v == 'below': cam(v, T0 + Vector((0, 0, -3)), T0, ortho=1.2, res=WIDE, up=(0, 1, 0))
    elif v == 'front': cam(v, T0 + Vector((3, 0, 0)), T0, ortho=.62, res=(RES, RES))
    elif v == 'bowside': cam(v, Vector((.34, 3, -.04)), Vector((.34, 0, -.04)), ortho=.42, res=WIDE)   # the bow third from the side
    elif v == 'battle':     # as render.py: height angle 55 degrees, orthographic, the ship about 180 px long
        e2 = math.radians(55); a2 = math.radians(150)
        d2 = Vector((math.cos(e2) * math.cos(a2), math.cos(e2) * math.sin(a2), math.sin(e2)))
        cam(v, T0 + d2 * 6, T0, ortho=400 / 180, res=(400, 260))
    else:
        tgt, dist = CLOSE[v]; cam(v, Vector(tgt) + D * dist, tgt, lens=50)
    sfx = ('_clay' if CLAY else '') + ('_cl' if LIGHT == 'concept' else '') + ('_crop' if (v == 'concept' and 'crop' in kw) else '')
    sc.render.filepath = os.path.join(OUT, f'{TAG}_{v}{sfx}.png'); bpy.ops.render.render(write_still=True)
    print('[prev] shot', v, round(time.time() - t0, 1), flush=True)
if kw.get('save') == '1': bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, f'{TAG}.blend'))
print('[prev] done', round(time.time() - t0, 1), flush=True)
