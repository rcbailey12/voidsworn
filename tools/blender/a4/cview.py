# A4 concept paint check (cloud or PC): render a packed ship (the npz from a4_ship.py) with a given albedo from the concept's registered
# camera and two more angles, next to the concept. Cycles CPU, small, for judging the paint, not the final look (that is the in-game shot).
#   python3 cview.py SHIP.npz ALBEDO.png [ALBEDO2.png ...] --reg CONCEPT.json --concept CONCEPT.webp --out SHEET.jpg [--normal N.png --orm O.png]
import sys, os, json, math
import numpy as np
import bpy
from PIL import Image, ImageDraw

a = sys.argv[1:]
npz, albs = a[0], []
i = 1
while i < len(a) and not a[i].startswith('--'): albs.append(a[i]); i += 1
opt = lambda k, d=None: a[a.index(k) + 1] if k in a else d
reg = json.load(open(opt('--reg')))['reg']; out = opt('--out'); cpt = opt('--concept'); RES = int(opt('--px', '520'))
labels = (opt('--labels') or ','.join(os.path.basename(x) for x in albs)).split(',')

bpy.ops.wm.read_factory_settings(use_empty=True)
m = np.load(npz); pos, idx, uv, nor = m['pos'], m['idx'].astype(np.int64), m['uv'], m['nor']
# glTF frame (+X bow, +Y up, +Z starboard) to Blender (x, -z, y)
P = np.stack([pos[:, 0], -pos[:, 2], pos[:, 1]], 1)
me = bpy.data.meshes.new('ship'); me.vertices.add(len(P)); me.vertices.foreach_set('co', P.ravel())
me.loops.add(idx.size); me.loops.foreach_set('vertex_index', idx.ravel())
me.polygons.add(len(idx)); me.polygons.foreach_set('loop_start', np.arange(0, idx.size, 3)); me.polygons.foreach_set('loop_total', np.full(len(idx), 3))
me.update(); me.validate()
ul = me.uv_layers.new(name='UVMap'); U = uv[idx.ravel()].copy(); U[:, 1] = 1 - U[:, 1]; ul.data.foreach_set('uv', U.ravel())
N = np.stack([nor[:, 0], -nor[:, 2], nor[:, 1]], 1); N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9)
try: me.normals_split_custom_set_from_vertices(N)
except Exception: pass
me.polygons.foreach_set('use_smooth', np.ones(len(idx), bool))
ob = bpy.data.objects.new('ship', me); sc = bpy.context.scene; sc.collection.objects.link(ob)
mat = bpy.data.materials.new('m'); mat.use_nodes = True; nt = mat.node_tree; bs = nt.nodes['Principled BSDF']; me.materials.append(mat)
tex = nt.nodes.new('ShaderNodeTexImage'); nt.links.new(tex.outputs[0], bs.inputs['Base Color'])
if opt('--orm'):
    to = nt.nodes.new('ShaderNodeTexImage'); to.image = bpy.data.images.load(opt('--orm')); to.image.colorspace_settings.name = 'Non-Color'
    sp = nt.nodes.new('ShaderNodeSeparateColor'); nt.links.new(to.outputs[0], sp.inputs[0]); nt.links.new(sp.outputs[1], bs.inputs['Roughness']); nt.links.new(sp.outputs[2], bs.inputs['Metallic'])
else: bs.inputs['Roughness'].default_value = .5; bs.inputs['Metallic'].default_value = .2
if opt('--normal'):
    tn = nt.nodes.new('ShaderNodeTexImage'); tn.image = bpy.data.images.load(opt('--normal')); tn.image.colorspace_settings.name = 'Non-Color'
    nm = nt.nodes.new('ShaderNodeNormalMap'); nt.links.new(tn.outputs[0], nm.inputs['Color']); nt.links.new(nm.outputs[0], bs.inputs['Normal'])
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (.05, .055, .065, 1); w.node_tree.nodes['Background'].inputs[1].default_value = 1.0
def sun(energy, rot):
    l = bpy.data.lights.new('s', 'SUN'); l.energy = energy; o = bpy.data.objects.new('s', l); o.rotation_euler = rot; sc.collection.objects.link(o)
sun(3.2, (math.radians(40), 0, math.radians(35))); sun(.8, (math.radians(-120), 0, math.radians(-150)))
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam
sc.render.engine = 'CYCLES'; sc.cycles.samples = 24; sc.cycles.device = 'CPU'; sc.render.resolution_x = sc.render.resolution_y = RES
sc.view_settings.view_transform = 'AgX' if 'AgX' in [x.identifier for x in sc.view_settings.bl_rna.properties['view_transform'].enum_items] else 'Filmic'
sc.render.film_transparent = False
try: sc.cycles.use_denoising = True
except Exception: pass

def place(az, el, fov):
    a_, e_ = math.radians(az), math.radians(el)
    back = np.array([math.cos(e_) * math.cos(a_), math.sin(e_), math.cos(e_) * math.sin(a_)])  # glTF frame
    D = 1.1 * .5 / math.tan(math.radians(fov) / 2)
    p = back * D; cam.location = (p[0], -p[2], p[1]); cam.data.angle = math.radians(fov)
    import mathutils
    d = mathutils.Vector((-p[0], p[2], -p[1])); cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()

views = [(reg['az'], reg['el'], reg['fov'], 'concept view'), (reg['az'] + 180 - 2 * (reg['az'] % 180) if False else (360 - reg['az']) % 360, reg['el'], reg['fov'], 'other side'),
         (reg['az'] + 35, -25, reg['fov'], 'from below')]
views = views[:int(opt('--nviews', '3'))]
tiles = []
for ap in albs:
    tex.image = bpy.data.images.load(ap, check_existing=True)
    row = []
    for az, el, fov, nm_ in views:
        place(az, el, fov); fp = f'/tmp/_cview_{len(tiles)}_{len(row)}.png'; sc.render.filepath = fp; bpy.ops.render.render(write_still=True)
        row.append(Image.open(fp).convert('RGB'))
    tiles.append(row)
cimg = Image.open(cpt).convert('RGBA'); bg = Image.new('RGBA', cimg.size, (13, 14, 17, 255)); bg.alpha_composite(cimg); cimg = bg.convert('RGB').resize((RES, RES))
W = Image.new('RGB', (RES * (len(views) + 1), (RES + 26) * len(tiles)), (20, 20, 24)); d = ImageDraw.Draw(W)
for r, row in enumerate(tiles):
    y = r * (RES + 26)
    W.paste(cimg, (0, y + 26)); d.text((6, y + 6), 'concept', fill=(255, 255, 255))
    for c, im in enumerate(row):
        W.paste(im, (RES * (c + 1), y + 26)); d.text((RES * (c + 1) + 6, y + 6), f'{labels[r]}: {views[c][3]}', fill=(255, 255, 255))
W.save(out, quality=88); print('sheet', out)
