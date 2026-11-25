# Issue 889: stamp every newly rendered picture at its save step.
import sys
from pathlib import Path as _PicturePath
sys.dont_write_bytecode = True
sys.path.insert(0, str(next(p for p in _PicturePath(__file__).resolve().parents if (p / 'tools/picture_provenance.py').is_file()) / 'tools'))
from picture_provenance import stamp_file as _stamp_picture, Review

# Interior cutaway review (issue 1743, R416 Layer 3; RULEBOOK 5.4): the ship's insides as Ryan will judge them, from any blend of
# the recipe (the stage 4 build, or the stage 5 painted blend with the interior trim maps on). Three section views, each a clip
# plane through the ship, so the rooms, girders, frames and trim read in place:
#   section   the side, cut at the centreline (the near half removed)
#   plan      from above, cut at mid height
#   close     a three-quarter view from port and above, cut by a plane through the ship's middle, zoomed on the midships third
# The light comes in through the cut (the hull and room shells cast no shadow; the modeled pieces do). Writes
# <code>_cut_section.png, <code>_cut_plan.png, <code>_cut_close.png and <code>_cutaway.jpg (the three on one sheet, 1280 wide,
# no taller than 720, the code name, stage and revision on it; RULEBOOK 1.2).
# usage (Blender or the bpy module):  python cutaway.py BLEND OUT_DIR "<title>" [stage=cloud direction check] [samples=24] [res=1]
import os, math
import bpy
from mathutils import Vector, Matrix

args = [a for a in sys.argv[1:] if '=' not in a]
opts = dict(a.split('=', 1) for a in sys.argv[1:] if '=' in a)
BLEND, OUT, TITLE = args[-3:]
STAGE = opts.get('stage', 'cloud direction check')
SAMPLES = int(opts.get('samples', 24)); RES = float(opts.get('res', 1))
VIEWS = opts.get('views', 'section,plan,close').split(',')      # cutaway_lineup.py asks for section,close and no sheet
SHEET = opts.get('sheet', '1') == '1'
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BLEND)
sc = bpy.context.scene
for o in list(sc.objects):
    if o.type in ('CAMERA', 'LIGHT'):
        bpy.data.objects.remove(o, do_unlink=True)
meshes = [o for o in sc.objects if o.type == 'MESH' and not o.hide_render and not o.get('proxy')]
inside = [o for o in sc.objects if o.type == 'MESH' and (o.get('role') == 'interior' or o.get('inside'))]
for o in inside:
    o.hide_render = False
outside = [o for o in meshes if o not in inside]
# the hull's thickness as the game has it: stage 7 turns each hull's 'skin' (solidify) modifier on, its inner shell in the dark
# liner (tools/recipe/export7.py prep(), <CODE>_inside_skin); the stage 5 blend keeps it off, so without this a cutaway would
# show the outside paint on the inner face of the hull, which no game ship shows
LINER = bpy.data.materials.new('cut_liner'); LINER.use_nodes = True
_lb = LINER.node_tree.nodes['Principled BSDF']; _lb.inputs['Base Color'].default_value = (.035, .028, .022, 1); _lb.inputs['Roughness'].default_value = .85
for o in outside:
    sk = o.modifiers.get('skin')
    if sk is None or o.get('role') == 'interior':
        continue
    sk.show_viewport = True; sk.show_render = True
    if LINER.name not in o.data.materials: o.data.materials.append(LINER)
    li = list(o.data.materials).index(LINER)
    sk.material_offset = li; sk.material_offset_rim = 0 if o.get('open_cut') else li
P = [o.matrix_world @ Vector(c) for o in outside for c in o.bound_box]
LO = Vector((min(p.x for p in P), min(p.y for p in P), min(p.z for p in P))); HI = Vector((max(p.x for p in P), max(p.y for p in P), max(p.z for p in P)))
C = (LO + HI) / 2; D = HI - LO; L = D.x
code = os.path.splitext(os.path.basename(BLEND))[0]

w = bpy.data.worlds.new('cut'); sc.world = w; w.use_nodes = True
w.node_tree.nodes['Background'].inputs['Color'].default_value = (0.05, 0.055, 0.065, 1); w.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.6


def sun(name, toward, strength):
    d = bpy.data.lights.new(name, 'SUN'); d.energy = strength; d.angle = math.radians(8)
    o = bpy.data.objects.new(name, d); sc.collection.objects.link(o)
    o.rotation_euler = Vector(toward).normalized().to_track_quat('-Z', 'Y').to_euler()


sun('key', (0.3, -1.0, -0.45), 3.0); sun('top', (-0.2, -0.3, -1.0), 1.4); sun('fill', (-0.5, -0.6, 0.3), 0.6)
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = SAMPLES; sc.cycles.use_denoising = True
sc.cycles.transparent_max_bounces = 256      # a ray crosses many cut-away layers on its way in; fewer turns them black
sc.render.film_transparent = False; sc.view_settings.view_transform = 'Standard'
sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGB'; sc.render.resolution_percentage = 100


# the section: every surface past the cut plane turns fully transparent in its own shader (a true planar section at any view
# angle, the cut-open rooms then lit like the rest; a camera clip could only cut square to the view)
CUT = bpy.data.node_groups.new('cut_plane', 'ShaderNodeTree')
CUT.interface.new_socket('Fac', in_out='OUTPUT', socket_type='NodeSocketFloat')
_g = CUT.nodes; _geo = _g.new('ShaderNodeNewGeometry'); _dot = _g.new('ShaderNodeVectorMath'); _dot.operation = 'DOT_PRODUCT'
_sub = _g.new('ShaderNodeMath'); _sub.operation = 'SUBTRACT'; _gt = _g.new('ShaderNodeMath'); _gt.operation = 'GREATER_THAN'
_gt.inputs[1].default_value = 0.0; _out = _g.new('NodeGroupOutput')
CUT.links.new(_geo.outputs['Position'], _dot.inputs[0]); CUT.links.new(_dot.outputs['Value'], _sub.inputs[0])
CUT.links.new(_sub.outputs[0], _gt.inputs[0]); CUT.links.new(_gt.outputs[0], _out.inputs[0])


def cut(normal, point):
    """cut away everything on the normal's side of the plane through point"""
    n = Vector(normal).normalized(); _dot.inputs[1].default_value = n; _sub.inputs[1].default_value = n.dot(Vector(point))


for m in {s.material for o in meshes for s in o.material_slots if s.material}:
    m.use_nodes = True; nt = m.node_tree
    outn = next((n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output), None) or next((n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL'), None)
    if outn is None or not outn.inputs['Surface'].links:
        continue
    src = outn.inputs['Surface'].links[0].from_socket
    mix = nt.nodes.new('ShaderNodeMixShader'); tr = nt.nodes.new('ShaderNodeBsdfTransparent'); grp = nt.nodes.new('ShaderNodeGroup'); grp.node_tree = CUT
    nt.links.new(grp.outputs[0], mix.inputs[0]); nt.links.new(src, mix.inputs[1]); nt.links.new(tr.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], outn.inputs['Surface'])
# the light comes in through the cut: the cut-open hull, the plates and the room shells cast no shadow on the insides (the build
# sheet's cutaway does the same); the modeled pieces inside keep theirs, so racks, girders and frames read in relief
for o in meshes:
    o.visible_shadow = bool(o.get('dress_of'))


def camera(name, d, ortho, res, target, up=(0, 0, 1), dist=None, lens=None):
    """a camera looking along d at target: orthographic (ortho scale) or perspective (lens, at dist)"""
    c = bpy.data.cameras.new(name)
    o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    d = Vector(d).normalized(); far = dist or 4 * L
    loc = Vector(target) - d * far
    z = -d; x = Vector(up).cross(z).normalized(); y = z.cross(x)
    o.matrix_world = Matrix(((x.x, y.x, z.x, loc.x), (x.y, y.y, z.y, loc.y), (x.z, y.z, z.z, loc.z), (0, 0, 0, 1)))
    if lens:
        c.type = 'PERSP'; c.lens = lens; c.sensor_width = 36
    else:
        c.type = 'ORTHO'; c.ortho_scale = ortho
    c.clip_start = 0.001 * L; c.clip_end = 12 * L
    sc.camera = o; sc.render.resolution_x, sc.render.resolution_y = int(res[0] * RES), int(res[1] * RES)
    return o


def shot(path):
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True); _stamp_picture(path, STAGE, new_render=True)
    return path


views = []
if 'section' in VIEWS:
    cut((0, 1, 0), C)
    camera('section', (0, -1, 0), 1.06 * L, (1600, max(240, int(1600 * D.z / L * 1.25))), C)
    views.append(shot(os.path.join(OUT, code + '_cut_section.png')))
if 'plan' in VIEWS:
    cut((0, 0, 1), C + Vector((0, 0, 0.08 * D.z)))
    camera('plan', (0, 0, -1), 1.06 * L, (1600, max(240, int(1600 * D.y / L * 1.15))), C, up=(0, 1, 0))
    views.append(shot(os.path.join(OUT, code + '_cut_plan.png')))
if 'close' in VIEWS:
    cut((0, 1, 0), C)
    tgt = C + Vector((0.02 * L, -0.06 * D.y, -0.02 * D.z))
    camera('close', (-0.45, -0.8, -0.4), None, (1280, 800), tgt, dist=0.24 * L, lens=30)
    views.append(shot(os.path.join(OUT, code + '_cut_close.png')))
if not SHEET:
    sys.exit(0)

# the three on one sheet: 1280 wide, at most 720 tall
from PIL import Image, ImageDraw, ImageFont
R = Review(STAGE)
ims = [R.open(v) for v in views]
W = 1280; top = 40
f = None
for p in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf'):
    if os.path.exists(p):
        f = ImageFont.truetype(p, 18); g = ImageFont.truetype(p, 14); break
sec = ims[0].resize((W // 2, int(ims[0].height * (W // 2) / ims[0].width)))
pla = ims[1].resize((W // 2, int(ims[1].height * (W // 2) / ims[1].width)))
H = min(720, top + 24 + sec.height + 24 + pla.height + 30)
clo = ims[2].resize((W // 2, int(ims[2].height * (W // 2) / ims[2].width)))
if clo.height > H - top - 30:
    k = (H - top - 30) / clo.height; clo = clo.resize((int(clo.width * k), int(clo.height * k)))
sheet = Image.new('RGB', (W, H), (14, 15, 18)); dr = ImageDraw.Draw(sheet)
dr.text((12, 10), '%s  %s' % (code, TITLE), fill=(230, 230, 232), font=f)
y = top
dr.text((12, y), 'centreline section, near half cut away', fill=(165, 170, 178), font=g); y += 20
sheet.paste(sec, (0, y)); y += sec.height + 4
dr.text((12, y), 'plan section at mid height', fill=(165, 170, 178), font=g); y += 20
sheet.paste(pla, (0, min(y, H - pla.height - 26)))
dr.text((W // 2 + 12, top), 'close cutaway, midships, three-quarter from port', fill=(165, 170, 178), font=g)
sheet.paste(clo, (W // 2, top + 20))
R.save(sheet, os.path.join(OUT, code + '_cutaway.jpg'), quality=92)
print('[cutaway] wrote', os.path.join(OUT, code + '_cutaway.jpg'))
