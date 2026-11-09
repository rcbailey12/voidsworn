# Issue 209 round 1: the same cameras, lights and exposure for every cell.
# usage: blender -b CELL.blend -P render.py -- OUT_DIR CELL [--preview]
# Views (bow on the left in all of them, like the concept; round 4 adds 'concept', the concept's own fitted camera):
#   hero   concept angle (front-port, above), paint and clay        side/top/below  orthographic, paint and clay (cut in thirds for the 9 cells)
#   battle the battle camera's height angle at about 180 px of ship length (1080p), paint      break  the four break pieces pulled apart
import os, sys, math, json
import bpy, bmesh
from mathutils import Vector, Matrix
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
a = sys.argv[sys.argv.index('--') + 1:]
OUT, CELL = a[0], a[1]; PREVIEW = '--preview' in a
ONLY = next((x.split('=', 1)[1].split(',') for x in a if x.startswith('--views=')), None)
os.makedirs(OUT, exist_ok=True)
sc = bpy.context.scene

def setup():
    sc.render.engine = 'CYCLES'; cy = sc.cycles
    if not PREVIEW:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        for t in ('OPTIX', 'CUDA'):
            try:
                prefs.compute_device_type = t; prefs.get_devices()
                for d in prefs.devices: d.use = True
                cy.device = 'GPU'; break
            except Exception: pass
    cy.samples = 24 if PREVIEW else 96; cy.use_denoising = True
    sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = 'None'; sc.view_settings.exposure = 1.6
    w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; bg = w.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = (.035, .037, .042, 1); bg.inputs['Strength'].default_value = 1.0
    for nm, rot, e, ang in (('key', (50, 0, 140), 4.0, 2), ('fill', (115, 0, -40), 1.0, 8), ('rim', (60, 0, -95), 2.2, 3)):
        L = bpy.data.lights.new(nm, 'SUN'); L.energy = e; L.angle = math.radians(ang); o = bpy.data.objects.new(nm, L); sc.collection.objects.link(o)
        o.rotation_euler = [math.radians(v) for v in rot]
    sc.render.film_transparent = False

def cam(name, loc, look, ortho=None, lens=50, res=(1600, 900)):
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    o.location = loc; d = Vector(look) - Vector(loc); o.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    if ortho: c.type = 'ORTHO'; c.ortho_scale = ortho
    else: c.lens = lens
    c.clip_start = .01; c.clip_end = 50
    sc.camera = o; sc.render.resolution_x, sc.render.resolution_y = res; sc.render.resolution_percentage = 50 if PREVIEW else 100
    return o

def shot(name):
    sc.render.filepath = os.path.join(OUT, f'{CELL}_{name}.png'); bpy.ops.render.render(write_still=True); print('[209] shot', name, flush=True)

def clay(on):
    vl = bpy.context.view_layer; vl.material_override = bpy.data.materials.get('clay') if on else None

def ups(v, up):  # camera with an explicit up vector (top and below views keep the bow on the left)
    pass

setup()
target = Vector((0, 0, -.01))
views = [('hero', dict(loc=(1.22, 1.62, .80), look=target, lens=50, res=(1600, 900))),
         ('side', dict(loc=(0, 3, -.01), look=(0, 0, -.01), ortho=1.2, res=(2400, 1200))),
         ('top', dict(loc=(0, 0, 3), look=(0, 0, 0), ortho=1.2, res=(2400, 1200))),
         ('below', dict(loc=(0, 0, -3), look=(0, 0, 0), ortho=1.2, res=(2400, 1200)))]
# round 4: the concept's own camera (fitted to the concept image by silhouette4.py; 1024 px square like the concept), so the render
# lies pixel for pixel over the concept
CAMJ = next((x.split('=', 1)[1] for x in a if x.startswith('--cam=')),
            os.path.join(HERE, '..', '..', '..', 'docs', 'shots', 'ship_pipeline', 'route209', 'round4', 'concept_camera.json'))
def concept_cam(name='concept'):
    p = json.load(open(CAMJ))['camera']; az, el = math.radians(p['az']), math.radians(p['el'])
    t = Vector(p.get('target', (0, 0, -.01))); d = Vector((math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)))
    o = cam(name, t + d * p['dist'], t, lens=p['focal'] / 1024 * 36, res=(1024, 1024))
    o.rotation_euler = (o.rotation_euler.to_matrix() @ Matrix.Rotation(math.radians(p['roll']), 3, 'Z')).to_euler()
    o.data.sensor_fit = 'HORIZONTAL'; o.data.sensor_width = 36
    o.data.shift_x = -(p['cx'] - 512) / 1024; o.data.shift_y = (p['cy'] - 512) / 1024
    return o
if os.path.exists(CAMJ): views = [('concept', None)] + views
for nm, kw in views:
    if ONLY and nm not in ONLY: continue
    o = concept_cam() if nm == 'concept' else cam(nm, **kw)
    if nm == 'top': o.rotation_euler = (0, 0, math.radians(180))       # looking down, bow (+x) on the left
    if nm == 'below': o.rotation_euler = (math.radians(180), 0, 0)    # looking up, bow on the left
    for cl in (False, True):
        clay(cl); shot(nm + ('_clay' if cl else ''))
clay(False)
# battle: height angle 55 degrees, from front-port; ortho so the ship is about 180 px long in a 1080p frame (crop 400x260 rendered direct)
el, az = math.radians(55), math.radians(150)
d = Vector((math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)))
if not ONLY or 'battle' in ONLY:
    o = cam('battle', target + d * 6, target, ortho=400 / 180, res=(400, 260)); sc.render.resolution_percentage = 100
    shot('battle')
if ONLY and 'break' not in ONLY:
    print('[209] RENDER DONE', CELL, flush=True); sys.exit(0)

# break view: join everything, cut along the break lines and pull the four pieces apart
import common as C
for ob in [ob for ob in sc.objects if ob.type == 'MESH']:
    bpy.context.view_layer.objects.active = ob
    for m in list(ob.modifiers):
        try: bpy.ops.object.modifier_apply(modifier=m.name)
        except Exception: ob.modifiers.remove(m)
meshes = [ob for ob in sc.objects if ob.type == 'MESH' and not ob.hide_render]
bpy.ops.object.select_all(action='DESELECT')
for ob in meshes: ob.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True); bpy.ops.object.join()
whole = bpy.context.view_layer.objects.active
TL = list(sc['r209_t_lines']) if 'r209_t_lines' in sc else C.T_LINES; LL = list(sc['r209_l_line']) if 'r209_l_line' in sc else C.L_LINE
T1, T2 = max(TL), min(TL); zL = LL[0]
pieces = [('bow', [((T1, 0, 0), (1, 0, 0))], (.16, 0, 0)), ('aft', [((T2, 0, 0), (-1, 0, 0))], (-.16, 0, 0)),
          ('midup', [((T1, 0, 0), (-1, 0, 0)), ((T2, 0, 0), (1, 0, 0)), ((0, 0, zL), (0, 0, 1))], (0, 0, .06)),
          ('midlo', [((T1, 0, 0), (-1, 0, 0)), ((T2, 0, 0), (1, 0, 0)), ((0, 0, zL), (0, 0, -1))], (0, 0, -.06))]
for nm, planes, off in pieces:
    bm = bmesh.new(); bm.from_mesh(whole.data)
    for co, no in planes:
        g = bm.verts[:] + bm.edges[:] + bm.faces[:]
        bmesh.ops.bisect_plane(bm, geom=g, plane_co=co, plane_no=no, clear_inner=True)
    bmesh.ops.translate(bm, verts=bm.verts, vec=off)
    me = bpy.data.meshes.new(nm); bm.to_mesh(me); bm.free()
    for m in whole.data.materials: me.materials.append(m)
    ob = bpy.data.objects.new(nm, me); sc.collection.objects.link(ob)
whole.hide_render = True
o = cam('brk', (1.10, 1.95, .80), target, lens=45, res=(1600, 900)); shot('break')      # from the bow quarter: the aft faces of each cut
o = cam('brk2', (-1.10, 1.95, .80), target, lens=45, res=(1600, 900)); shot('break2')   # from the stern quarter: the forward faces
print('[209] RENDER DONE', CELL, flush=True)
