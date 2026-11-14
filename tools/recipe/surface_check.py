# Every surface seen from outside carries the paint stack (issue 601; Ryan, Nov 12 2026 16:32 CST on the first painted A16:
# "a white square near the back and another white square underneath on the bottom ... Do a full thorough pass"). Runs inside
# Blender on a painted stage 5 blend. It renders the six standard views (top, below, port, starboard, bow, stern) with every
# object drawn flat in the colour of its class, and counts the pixels where the nearest surface is:
#   room     an authored inside with its sheet room colour (an inside seen from outside must read as the dark liner, R99 Q1)
#   bare     a surface with no stack material (a sheet placeholder colour)
# against the allowed classes: stack (the hull and parts atlases), glow (engine throat and lining, running lamps), liner (an
# inside in the stack's dark liner). Zero room and zero bare pixels pass. Writes JOB/surface_check.json and one class picture.
# usage: blender -b CELL.blend -P surface_check.py -- OUT_DIR [res=640]
import os, sys, json, math
import bpy
import numpy as np
from mathutils import Vector, Matrix

a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
OUT = a[0]; kw = dict(x.split('=', 1) for x in a[1:] if '=' in x); RES = int(kw.get('res', 640))
os.makedirs(OUT, exist_ok=True)
sc = bpy.context.scene
CLS = dict(stack=(0, 1, 0), glow=(0, 0, 1), liner=(.5, .5, .5), room=(1, 0, 0), bare=(1, 0, 1))
GLOW = ('p3_glow', 'p3_ember', 'p3_light', 'p3_lamp')


def cls_of(o):
    names = [s.material.name if s.material else '' for s in o.material_slots] or ['']
    if o.get('role') == 'interior':
        return 'liner' if all(bpy.data.materials.get(n) is not None and bpy.data.materials[n].get('ps_inside') for n in names if n) and any(names) else 'room'
    worst = 'stack'
    for n in names:
        m = bpy.data.materials.get(n)
        if m is not None and m.get('p3_textured'): continue
        if n.startswith(GLOW): worst = 'glow' if worst == 'stack' else worst; continue
        return 'bare'
    return worst


counts_obj = {}; bad_objs = []
for o in sc.objects:
    if o.type != 'MESH' or o.hide_render: continue
    k = cls_of(o); counts_obj.setdefault(k, []).append(o.name)
    if k in ('room', 'bare'): bad_objs.append(o)
    o['ps_cls'] = CLS[k]
NB = max(1, len(bad_objs))
for i, o in enumerate(bad_objs):      # each offending object its own green level, so the report names what shows
    r, g, b = CLS[cls_of(o)]; o['ps_cls'] = (r, .05 + .9 * i / NB, b)
m = bpy.data.materials.new('ps_class'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
out = nt.nodes.new('ShaderNodeOutputMaterial'); em = nt.nodes.new('ShaderNodeEmission'); at = nt.nodes.new('ShaderNodeAttribute')
at.attribute_type = 'OBJECT'; at.attribute_name = 'ps_cls'
nt.links.new(at.outputs['Vector'], em.inputs['Color']); nt.links.new(em.outputs[0], out.inputs[0])
bpy.context.view_layer.material_override = m
sc.render.engine = 'CYCLES'; sc.cycles.samples = 1; sc.cycles.use_denoising = False; sc.render.filter_size = .01
sc.cycles.max_bounces = 0
sc.view_settings.view_transform = 'Standard'; sc.view_settings.look = 'None'; sc.view_settings.exposure = 0
w = bpy.data.worlds.new('black'); w.use_nodes = True; w.node_tree.nodes['Background'].inputs['Color'].default_value = (0, 0, 0, 1); sc.world = w
sc.render.resolution_x, sc.render.resolution_y = RES, RES // 2; sc.render.resolution_percentage = 100
sc.render.image_settings.file_format = 'PNG'


def cam(loc, look, up):
    c = bpy.data.cameras.new('chk'); o = bpy.data.objects.new('chk', c); sc.collection.objects.link(o)
    f = (Vector(look) - Vector(loc)).normalized(); r = f.cross(Vector(up)).normalized(); u = r.cross(f); b = -f
    o.matrix_world = Matrix(((r.x, u.x, b.x, loc[0]), (r.y, u.y, b.y, loc[1]), (r.z, u.z, b.z, loc[2]), (0, 0, 0, 1)))
    c.type = 'ORTHO'; c.ortho_scale = 1.12; c.clip_start = .001; c.clip_end = 20
    return o


VIEWS = dict(top=((0, 0, 3), (0, -1, 0)), below=((0, 0, -3), (0, 1, 0)), port=((0, 3, 0), (0, 0, 1)), starboard=((0, -3, 0), (0, 0, 1)),
             bow=((3, 0, 0), (0, 0, 1)), stern=((-3, 0, 0), (0, 0, 1)))
res = {}; tot = dict(room=0, bare=0); seen = {}
keys = list(CLS); C = np.array([CLS[k] for k in keys], np.float32)
for v, (loc, up) in VIEWS.items():
    sc.camera = cam(loc, (0, 0, 0), up); p = os.path.join(OUT, f'surface_{v}.png'); sc.render.filepath = p
    bpy.ops.render.render(write_still=True)
    im = bpy.data.images.load(p); px = np.empty(im.size[0] * im.size[1] * 4, np.float32); im.pixels.foreach_get(px); px = px.reshape(-1, 4)[:, :3]
    lit = px.sum(1) > .15; P = px[lit]
    room = (P[:, 0] > .9) & (P[:, 2] < .1); bare = (P[:, 0] > .9) & (P[:, 2] > .9)
    rest = ~(room | bare); d = ((P[rest][:, None] - C[None]) ** 2).sum(2); near = d.argmin(1)
    n = {k: int((near == i).sum()) for i, k in enumerate(keys) if k not in ('room', 'bare')}
    n['room'] = int(room.sum()); n['bare'] = int(bare.sum())
    for q in np.round((P[room | bare][:, 1] - .05) / .9 * NB).astype(int):
        if 0 <= q < NB: seen[bad_objs[q].name] = seen.get(bad_objs[q].name, 0) + 1
    res[v] = n; tot['room'] += n['room']; tot['bare'] += n['bare']
ok = tot['room'] == 0 and tot['bare'] == 0
rep = dict(ok=ok, totals=tot, views=res, seen_from_outside=dict(sorted(seen.items(), key=lambda kv: -kv[1])), objects={k: len(v) for k, v in counts_obj.items()}, res=RES)
json.dump(rep, open(os.path.join(OUT, 'surface_check.json'), 'w'), indent=1)
print(('PASS' if ok else 'FAIL') + f' surface check: {tot["room"]} pixels of inside room colours and {tot["bare"]} of surfaces with no stack material seen from outside (six views at {RES})')
for nme, c in sorted(seen.items(), key=lambda kv: -kv[1])[:40]: print(f'  seen from outside: {nme} {c} px')
