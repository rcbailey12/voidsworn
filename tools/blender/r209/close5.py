# Issue 209 round 5: close-ups of one casemate and one drum rack, for judging waviness (Ryan, R147: "even some of the parts look
# wavy or oversharpened"). Same lights and exposure as render.py; orthographic, the part centred, paint then clay.
# usage: blender -b CELL.blend -P close5.py -- OUT_DIR CELL CASEMATE_OBJ RACK_OBJ
#   Hy4: hcasemate_0p hdrums_sp   (the generated parts)      Ab5: cplate01 srack1frame   (the hand rebuilds)
import os, sys, math
import bpy
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:]
OUT, CELL, CAS, RACK = a[:4]; os.makedirs(OUT, exist_ok=True)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; cy = sc.cycles
prefs = bpy.context.preferences.addons['cycles'].preferences
for t in ('OPTIX', 'CUDA'):
    try:
        prefs.compute_device_type = t; prefs.get_devices()
        for d in prefs.devices: d.use = True
        cy.device = 'GPU'; break
    except Exception: pass
cy.samples = 128; cy.use_denoising = True
sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = 'None'; sc.view_settings.exposure = 1.6
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; bg = w.node_tree.nodes['Background']
bg.inputs['Color'].default_value = (.035, .037, .042, 1); bg.inputs['Strength'].default_value = 1.0
for nm, rot, e, ang in (('key', (50, 0, 140), 4.0, 2), ('fill', (115, 0, -40), 1.0, 8), ('rim', (60, 0, -95), 2.2, 3)):
    L = bpy.data.lights.new(nm, 'SUN'); L.energy = e; L.angle = math.radians(ang); o = bpy.data.objects.new(nm, L); sc.collection.objects.link(o)
    o.rotation_euler = [math.radians(v) for v in rot]

def centre(name):
    o = bpy.data.objects[name]; w = [o.matrix_world @ Vector(b) for b in o.bound_box]
    return Vector([(max(v[i] for v in w) + min(v[i] for v in w)) / 2 for i in range(3)])

def shoot(tag, target, d, scale):
    c = bpy.data.cameras.new(tag); o = bpy.data.objects.new(tag, c); sc.collection.objects.link(o)
    d = Vector(d).normalized(); o.location = target + d * 2.0; o.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    c.type = 'ORTHO'; c.ortho_scale = scale; c.clip_start = .01; c.clip_end = 10
    sc.camera = o; sc.render.resolution_x = sc.render.resolution_y = 1024; sc.render.resolution_percentage = 100
    for clay in (False, True):
        bpy.context.view_layer.material_override = bpy.data.materials.get('clay') if clay else None
        sc.render.filepath = os.path.join(OUT, f'{CELL}_{tag}{"_clay" if clay else ""}.png'); bpy.ops.render.render(write_still=True)
    bpy.context.view_layer.material_override = None

cas = centre(CAS); cas.y = max(cas.y, 0)
shoot('cas', cas + Vector((0, .010, 0)), (.45, 1.0, .30), .15)
shoot('casfront', cas + Vector((0, .010, 0)), (1.0, .35, .18), .15)
rk = centre(RACK)
shoot('rack', rk + Vector((0, 0, .010)), (.55, .70, .75), .13)
print('[209] CLOSE DONE', CELL, flush=True)
