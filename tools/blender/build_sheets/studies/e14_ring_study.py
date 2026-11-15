# E14 flare ring orientation study (issue 739; R233: the flare carries one closed ring and must not read from above as a
# small zenith, E12). Plain primitives, no design detail: a 9.5 spar and a closed ring of twelve plates 5.4 across, in three
# orientations, rendered from straight above and at the battle camera's pitch (0.98 rad, about 56 degrees down) from the bow
# quarter, the beam and the stern quarter. The concept's three views disagree on the ring's plane, so the build picks the one
# that reads as one closed ring from above and at the battle camera.
#   python e14_ring_study.py OUT_DIR      (the bpy module, or blender -b -P e14_ring_study.py -- OUT_DIR)
import sys, os, math
import bpy
from mathutils import Vector, Matrix

OUT = (sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:])[0]
os.makedirs(OUT, exist_ok=True)
OPTIONS = [('A_flat', 'ring flat in plan', 0.0), ('B_upright', 'ring upright, facing forward', 90.0), ('C_leaning', 'ring leaning back 40 degrees', 50.0)]
VIEWS = [('top', None), ('bow_quarter', 35.0), ('beam', 90.0), ('stern_quarter', 145.0)]


def box_mesh(name, verts, faces, col):
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    m = bpy.data.materials.new(name); m.diffuse_color = col; ob.data.materials.append(m)
    return ob


def ring_plates(tilt, xc=2.0, R=2.7, w=0.9, d=0.35, n=12, gap=4.0):
    """twelve plates on a closed ring; tilt 0 lies flat (normal +Z), 90 stands upright (normal +X)"""
    M = Matrix.Translation((xc, 0, 0)) @ Matrix.Rotation(math.radians(tilt), 4, 'Y')
    for k in range(n):
        a0 = math.radians(360.0 * k / n + gap / 2); a1 = math.radians(360.0 * (k + 1) / n - gap / 2)
        V = []
        for a in (a0, a1):
            for r in (R - w, R):
                for z in (-d / 2, d / 2):
                    V.append(tuple(M @ Vector((r * math.cos(a), r * math.sin(a), z))))
        F = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
        box_mesh('plate%d' % k, V, F, (0.32, 0.22, 0.45, 1))
    # the closed hoop under the plates
    V, F = [], []
    m = 48
    for i in range(m):
        a = 2 * math.pi * i / m
        for r, z in ((R - w - 0.05, -0.08), (R - w + 0.1, -0.08), (R - w + 0.1, 0.08), (R - w - 0.05, 0.08)):
            V.append(tuple(M @ Vector((r * math.cos(a), r * math.sin(a), z))))
    for i in range(m):
        j = (i + 1) % m
        for q in range(4):
            F.append((i * 4 + q, i * 4 + (q + 1) % 4, j * 4 + (q + 1) % 4, j * 4 + q))
    box_mesh('hoop', V, F, (0.15, 0.85, 0.4, 1))


def spar():
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.35, depth=9.5, location=(0, 0, 0), rotation=(0, math.pi / 2, 0))
    o = bpy.context.object; m = bpy.data.materials.new('spar'); m.diffuse_color = (0.25, 0.2, 0.32, 1); o.data.materials.append(m)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.55, location=(2.0, 0, 0))
    o = bpy.context.object; m = bpy.data.materials.new('core'); m.diffuse_color = (0.3, 1.0, 0.45, 1); o.data.materials.append(m)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.7, minor_radius=0.08, location=(-4.75, 0, 0), rotation=(0, math.pi / 2, 0))
    o = bpy.context.object; m = bpy.data.materials.new('eng'); m.diffuse_color = (0.85, 0.85, 1.0, 1); o.data.materials.append(m)


def camera(name, view):
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); bpy.context.scene.collection.objects.link(o)
    if view is None:
        c.type = 'ORTHO'; c.ortho_scale = 11.0
        o.matrix_world = Matrix.Translation((0, 0, 50)) @ Matrix.Rotation(math.radians(90), 4, 'Z')
    else:
        pitch = 0.98; dist = 26.0; b = math.radians(view)
        d = Vector((math.cos(pitch) * math.cos(b), math.cos(pitch) * math.sin(b), math.sin(pitch)))
        o.location = d * dist
        o.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
        c.lens = 36 / (2 * math.tan(math.radians(45) / 2)) * 1.0; c.sensor_width = 36
    return o


sc = bpy.context.scene
sc.render.engine = 'BLENDER_WORKBENCH'
sc.display.shading.light = 'STUDIO'; sc.display.shading.color_type = 'MATERIAL'
sc.render.resolution_x = sc.render.resolution_y = 300
sc.render.film_transparent = False
for key, label, tilt in OPTIONS:
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    spar(); ring_plates(tilt)
    for vn, v in VIEWS:
        cam = camera('cam_' + vn, v); sc.camera = cam
        sc.render.filepath = os.path.join(OUT, '%s_%s.png' % (key, vn))
        bpy.ops.render.render(write_still=True)

# one named picture, 1280 by 720 at most: a row per orientation, a column per view
from PIL import Image, ImageDraw, ImageFont
try:
    fnt = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 18); big = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 24)
except OSError:
    fnt = big = ImageFont.load_default()
W, H = 1280, 720; cell = 196
im = Image.new('RGB', (W, H), (40, 40, 42)); d = ImageDraw.Draw(im)
d.text((16, 10), 'deathless_E14 flare | ring orientation study (R233: one closed ring, never a small zenith from above)', fill=(240, 230, 210), font=big)
for j, (vn, v) in enumerate(VIEWS):
    d.text((300 + j * (cell + 40), 48), 'from above' if v is None else 'battle camera, %s' % vn.replace('_', ' '), fill=(200, 196, 186), font=fnt)
for i, (key, label, tilt) in enumerate(OPTIONS):
    y = 76 + i * (cell + 18)
    d.text((16, y + cell // 2 - 10), '%s: %s' % (key[0], label), fill=(240, 180, 90), font=fnt)
    for j, (vn, v) in enumerate(VIEWS):
        t = Image.open(os.path.join(OUT, '%s_%s.png' % (key, vn))).convert('RGB').resize((cell, cell))
        im.paste(t, (300 + j * (cell + 40), y))
im.save(os.path.join(OUT, 'deathless_E14_ring_study.jpg'), quality=90)
print('WROTE', os.path.join(OUT, 'deathless_E14_ring_study.jpg'))
