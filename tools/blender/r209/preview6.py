# Issue 209 round 6: a quick sandbox preview (CPU Cycles, no bake): build a cell, paint it with the procedural materials directly
# (no texture bake), render the concept camera and weapon close-ups. For iterating geometry and paint before the PC run.
# usage: python3.11 preview6.py OUT_DIR MODULE [res=512] [samples=16] [views=concept,cas,bow,drums,aft] [clay=0|1]
import os, sys, math, json, importlib, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import bpy
from mathutils import Vector, Matrix
a = sys.argv[1:]; OUT, MOD = a[0], a[1]
kw = dict(x.split('=', 1) for x in a[2:] if '=' in x)
RES = int(kw.get('res', 512)); SAMP = int(kw.get('samples', 16)); VIEWS = kw.get('views', 'concept').split(','); CLAY = kw.get('clay', '0') == '1'
os.makedirs(OUT, exist_ok=True); t0 = time.time()
M = importlib.import_module(MOD)
S, Pl, hard, gen, notes, prox = M.build_geometry()
import common as C
P = importlib.import_module(kw.get('paint', 'paint3'))
P.assign(S + Pl + hard, S + Pl)
if kw.get('albedo') == '1':      # debug: show the baked albedo as emission (no lighting)
    import paint3 as P3
    for m in bpy.data.materials:
        if m.name.startswith('p3_') and m.node_tree and any(n.label == 'ALBEDO' for n in m.node_tree.nodes): P3._emit_switch(m, 'ALBEDO')
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = SAMP; sc.cycles.use_denoising = True
sc.view_settings.view_transform = 'AgX'; sc.view_settings.exposure = 1.6
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; bg = w.node_tree.nodes['Background']
bg.inputs['Color'].default_value = (.035, .037, .042, 1)
LIGHTS = {'studio': ((('key', (50, 0, 140), 4.0, 2), ('fill', (115, 0, -40), 1.0, 8), ('rim', (60, 0, -95), 2.2, 3)), 1.6),
          'concept': ((('key', (28, 0, 165), 4.2, 3), ('fill', (100, 0, 60), .7, 10), ('rim', (65, 0, -95), 1.0, 3)), .75)}
rig, expo = LIGHTS[kw.get('light', 'studio')]; sc.view_settings.exposure = expo
for nm, rot, e, ang in rig:
    L = bpy.data.lights.new(nm, 'SUN'); L.energy = e; L.angle = math.radians(ang); o = bpy.data.objects.new(nm, L); sc.collection.objects.link(o)
    o.rotation_euler = [math.radians(v) for v in rot]
if CLAY:
    C.mats(); bpy.context.view_layer.material_override = bpy.data.materials.get('clay')
CAMJ = os.path.join(HERE, '..', '..', '..', 'docs', 'shots', 'ship_pipeline', 'route209', 'round4', 'concept_camera.json')
def cam(name, loc, look, lens=50, res=(RES, RES)):
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    o.location = loc; o.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler(); c.lens = lens; c.clip_start = .005
    sc.camera = o; sc.render.resolution_x, sc.render.resolution_y = res; return o
def concept():
    p = json.load(open(CAMJ))['camera']; az, el = math.radians(p['az']), math.radians(p['el'])
    t = Vector((0, 0, -.01)); d = Vector((math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)))
    o = cam('concept', t + d * p['dist'], t, lens=p['focal'] / 1024 * 36)
    o.rotation_euler = (o.rotation_euler.to_matrix() @ Matrix.Rotation(math.radians(p['roll']), 3, 'Z')).to_euler()
    o.data.sensor_fit = 'HORIZONTAL'; o.data.sensor_width = 36; o.data.shift_x = -(p['cx'] - 512) / 1024; o.data.shift_y = (p['cy'] - 512) / 1024
    return o
# close-ups at the concept's viewing direction (front-port, above), aimed at each weapon group
p = json.load(open(CAMJ))['camera']; az, el = math.radians(p['az']), math.radians(p['el'])
D = Vector((math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)))
CLOSE = dict(cas=((.29, .17, -.05), .55), bow=((.36, 0, .07), .45), drums=((.12, .05, .10), .6), aft=((-.30, 0, .10), .6))
for v in VIEWS:
    if v == 'concept': concept()
    else:
        tgt, dist = CLOSE[v]; cam(v, Vector(tgt) + D * dist, tgt, lens=50)
    sc.render.filepath = os.path.join(OUT, f'{MOD}_{v}{"_clay" if CLAY else ""}.png'); bpy.ops.render.render(write_still=True)
print('[prev] done', round(time.time() - t0, 1), flush=True)
