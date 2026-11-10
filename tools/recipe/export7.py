# Ship recipe, stage 7: the game export, automated (issue 209 round 7; FINDINGS R155, R156: the recipe writes the hard points as a
# required output, and the effects are built to that contract).
# From a ship's baked blend (stage 5) and its ship json, with no hand steps, this writes the game's ship folder
# (godot/assets/ships/README.md, tools/blender/a4/K1_DECISIONS.md):
#   <CODE>.glb             one ship node <CODE> (one mesh; surfaces <CODE>_hull, <CODE>_parts, <CODE>_glow) with an empty child node per
#                          hard point; the maps are outside the glb, by relative URI, as the A4 ships have them
#   <CODE>_base.jpg, <CODE>_orm.jpg, <CODE>_normal.jpg          the hull atlas (albedo sRGB; R occlusion, G roughness, B metal; normal)
#   <CODE>_parts_base.jpg, <CODE>_parts_orm.jpg                 the parts atlas
#   <CODE>_export.json     what was written: every hard point, the weapon slots, triangles, every file with its size and sha256
# Hard points (frame: +X bow, +Y up, -Z port, as every game ship):
#   hp_w<slot>_<weapon>_<arc>_<n>   one per weapon muzzle of every socket that has a "slot" in the ship json (the barrel tips and
#                                   launch mouths the kit registered while building): node -Z along the barrel, +Y away from the hull
#   hp_eng_<n>                      one per engine exit: -Z out of the bell (aft), extras.radius the bell radius
#   hp_breach_<n>                   breach anchors on open hull, clear of parts: two per section (prow, mid, eng), port and starboard;
#                                   +Y is the outward surface normal
#   hp_core                         the hull's centre of mass
# The weapon kind and arc of each slot are read from the game's own data.js (the ship json names the ship: "game_ship"), so the
# names can never drift from the rules. tools/recipe/check_export.py then reads the written glb back and fails the export when a
# weapon slot has no hard point or a hard point is off the mesh.
# usage: blender -b CELL.blend -P export7.py -- SHIP_JSON OUT_DIR [maps=2048] [unbaked=1]
#   unbaked=1 is for testing the geometry and hard points on a build that has not been baked (no maps are written and the
#   export json says so; check_export.py fails such a folder unless it is told the same).
import os, sys, json, math, struct, hashlib, shutil, time
import bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
a = sys.argv[sys.argv.index('--') + 1:]
SHIPJ, OUT = a[0], a[1]; kw = dict(x.split('=', 1) for x in a[2:] if '=' in x)
MAPS = int(kw.get('maps', 2048)); UNBAKED = kw.get('unbaked') == '1'
ship = json.load(open(SHIPJ)); CODE = ship.get('game_code') or ship['ship']; GAME = ship.get('game_ship')
ARC_DEG = {'F': 30, 'T': 135, 'P': 60, 'S': 60}       # as tools/blender/a4/ships.py: half-angle of the firing arc from the rest direction
MOUNT_SIZE = dict(casemate='M', drum_rack='M', turret='S', bow_battery='M')   # a socket's "mount" key overrides
BREACH_SECTIONS = (('prow', .215, .47), ('mid', -.10, .16), ('eng', -.44, -.14))   # x ranges; two anchors each (port, starboard)
BREACH_CLEAR = .030                                  # an anchor keeps this far from every part

def status(text):      # the stage file reads this (a Blender exit code is not something to lean on)
    os.makedirs(OUT, exist_ok=True); open(os.path.join(OUT, 'export_status.txt'), 'w').write(text + '\n')

def die(msg):
    print('[export7] FAILED:', msg, flush=True); status('FAILED: ' + msg); sys.exit(2)

if not GAME: die('the ship json has no "game_ship" (the ship id in data.js)')
sys.path.insert(0, HERE)
import gamedata
try: WEAPONS = gamedata.weapons(GAME)      # [(kind, arc), ...] in slot order, from the game's data.js
except ValueError as e: die(str(e))
sc = bpy.context.scene
if 'r209_hp' not in sc: die('this blend has no hard point data (scene r209_hp): rebuild it with the current hull module')
HP = json.loads(sc['r209_hp'])
os.makedirs(OUT, exist_ok=True); t0 = time.time(); status('RUNNING')

# ---------------------------------------------------------------------------------------------------------------- the ship mesh
src = [o for o in sc.objects if o.type == 'MESH' and not o.hide_render and o.get('role') != 'interior' and not o.get('proxy')]
hull_src = [o for o in src if o.get('role') == 'hull']; part_src = [o for o in src if o.get('role') != 'hull']
if not hull_src: die('no hull in this blend')

def world_bvh(objs):
    bm = bmesh.new(); dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        oe = o.evaluated_get(dg); me = oe.to_mesh(); t = bmesh.new(); t.from_mesh(me); t.transform(o.matrix_world)
        tm = bpy.data.meshes.new('_t'); t.to_mesh(tm); t.free(); bm.from_mesh(tm); bpy.data.meshes.remove(tm); oe.to_mesh_clear()
    T = BVHTree.FromBMesh(bm); return T, bm

for o in hull_src:      # the game's ship has no inner skin (that is for the break pieces)
    sk = o.modifiers.get('skin')
    if sk: sk.show_viewport = False; sk.show_render = False
HT, hbm = world_bvh(hull_src); PT, pbm = world_bvh(part_src) if part_src else (None, None)

def core_point(bm):
    """centre of mass of the hull blocks (signed-volume weighted), on the centreline"""
    bmesh.ops.triangulate(bm, faces=bm.faces); c = Vector(); vol = 0.0
    for f in bm.faces:
        p, q, r = (v.co for v in f.verts); v6 = p.dot(q.cross(r)); vol += v6; c += (p + q + r) * (v6 / 4)
    if abs(vol) < 1e-9: die('the hull has no volume')
    c /= vol; return Vector((c.x, 0.0, c.z))

def breach_anchors():
    """open hull, clear of parts: per section and side, the side-hull point (ray in from the side) nearest the middle of the
    section's side among those at least BREACH_CLEAR from every part"""
    out = []
    for sec, x0, x1 in BREACH_SECTIONS:
        for s in (1, -1):
            best = None; xm = (x0 + x1) / 2
            for x in np.linspace(x0, x1, 21):
                for z in np.linspace(-.115, .020, 13):
                    loc, nrm, _, _ = HT.ray_cast(Vector((x, s * .6, z)), Vector((0, -s, 0)), 1.2)
                    if loc is None or nrm.y * s < .55: continue             # a side face, facing out
                    d = PT.find_nearest(loc)[3] if PT else 9.0
                    if d is None: d = 9.0
                    if d < BREACH_CLEAR: continue
                    off = (x - xm) ** 2 + 4 * (z + .050) ** 2
                    if best is None or off < best[0]: best = (off, loc.copy(), nrm.copy(), d)
            if best is None: die(f'no open hull for a breach anchor in the {sec} section, side {s}')
            out.append(dict(section=sec, side=s, p=best[1], n=best[2].normalized(), clear=round(best[3], 4)))
    return out

CORE = core_point(hbm); BREACH = breach_anchors(); hbm.free()
if pbm: pbm.free()

keep = []
for o in src:
    c = o.copy(); c.data = o.data.copy(); sc.collection.objects.link(c); bpy.context.view_layer.objects.active = c
    for md in list(c.modifiers):
        if md.name == 'skin': c.modifiers.remove(md); continue
        try: bpy.ops.object.modifier_apply(modifier=md.name)
        except Exception: c.modifiers.remove(md)
    if UNBAKED:      # test only: one plain material per role, so the glb splits hull from parts as a baked one does (the check measures
        c.data.materials.clear()       # the breach anchors' clearance from the parts surfaces)
        nm = CODE + ('_hull' if o.get('role') == 'hull' else '_parts'); c.data.materials.append(bpy.data.materials.get(nm) or bpy.data.materials.new(nm))
        for f in c.data.polygons: f.material_index = 0
    keep.append(c)
bpy.ops.object.select_all(action='DESELECT')
for c in keep: c.select_set(True)
bpy.context.view_layer.objects.active = keep[0]; bpy.ops.object.join(); J = bpy.context.view_layer.objects.active
J.name = CODE; J.data.name = CODE; bpy.ops.object.material_slot_remove_unused()
for k in list(J.keys()): del J[k]
J.data.calc_loop_triangles(); TRIS = len(J.data.loop_triangles)

# ---------------------------------------------------------------------------------------------------------------- materials and maps
def occlusion_group():
    ng = bpy.data.node_groups.get('glTF Material Output')
    if ng is None:
        ng = bpy.data.node_groups.new('glTF Material Output', 'ShaderNodeTree')
        ng.interface.new_socket('Occlusion', in_out='INPUT', socket_type='NodeSocketFloat')
    return ng

maps = {}
if UNBAKED:      # test only: the plain role materials set before the join (<CODE>_hull, <CODE>_parts) so the glb still loads; no maps
    for s in J.material_slots: s.material.use_nodes = True
else:
    tex = [s.material for s in J.material_slots if s.material and s.material.get('p3_textured')]
    hullm = next((m for m in tex if any(n.type == 'NORMAL_MAP' for n in m.node_tree.nodes)), None)
    partm = next((m for m in tex if m is not hullm), None)
    if hullm is None or partm is None: die('this blend is not baked (no hull and parts atlas materials): run stage 5 first, or pass unbaked=1 for a geometry test')
    for m, pre in ((hullm, CODE), (partm, CODE + '_parts')):
        m.name = pre if pre != CODE else CODE + '_hull'; nt = m.node_tree
        sep = next(n for n in nt.nodes if n.type == 'SEPARATE_COLOR')
        if not any(n.type == 'GROUP' for n in nt.nodes):
            g = nt.nodes.new('ShaderNodeGroup'); g.node_tree = occlusion_group(); nt.links.new(sep.outputs[0], g.inputs['Occlusion'])
        bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
        role = {'base': bs.inputs['Base Color'].links[0].from_node.image, 'orm': sep.inputs[0].links[0].from_node.image}
        nm = next((n for n in nt.nodes if n.type == 'NORMAL_MAP'), None)
        if nm is not None: role['normal'] = nm.inputs['Color'].links[0].from_node.image
        for r, im in role.items():
            if max(im.size) > MAPS: im.scale(MAPS, MAPS)
            maps[f'{pre}_{r}'] = im.name
    glow = next((s.material for s in J.material_slots if s.material and s.material.name.startswith('p3_glow')), None)
    if glow: glow.name = CODE + '_glow'

# ---------------------------------------------------------------------------------------------------------------- hard points
def empty(name, p, fwd, up, extras):
    """an empty whose glTF node has -Z along fwd and +Y along up. The exporter turns Blender's axes (x, y, z) into glTF's
    (x, z, -y) for positions and rotations alike, so in Blender the empty's +Y is fwd and its +Z is up."""
    f = Vector(fwd).normalized(); u = Vector(up).normalized()
    if abs(u.dot(f)) > .85: u = Vector((0, 0, 1))      # a gun aimed straight out of its mount: 'away from the hull' is the barrel itself, so up is up
    u = (u - f * u.dot(f))
    if u.length < 1e-4: u = Vector((0, 0, 1)) - f * f.z
    if u.length < 1e-4: u = Vector((0, 1, 0))
    u.normalize(); x = f.cross(u).normalized()
    o = bpy.data.objects.new(name, None); sc.collection.objects.link(o); o.empty_display_size = .01
    R = Matrix((x, f, u)).transposed().to_4x4(); R.translation = Vector(p); o.matrix_world = R; o.parent = J; o.matrix_parent_inverse = Matrix.Identity(4)
    o.matrix_world = R
    for k, v in extras.items(): o[k] = v
    return o

HPS = []; cnt = {}; by_slot = {}
part_of = {e['name']: e for e in ship['parts']}
for m in HP['muzzles']:
    if m.get('slot') is None: continue
    slot = int(m['slot'])
    if slot >= len(WEAPONS): die(f'socket {m["socket"]} names weapon slot {slot}, but {GAME} has {len(WEAPONS)} weapons in data.js')
    wk, arc = WEAPONS[slot]; key = f'hp_w{slot}_{wk}_{arc}'; k = cnt.get(key, 0); cnt[key] = k + 1
    e = part_of.get(m['socket']) or part_of.get(m['socket'][:-2], {})
    ex = dict(kind='gun', size=e.get('mount') or MOUNT_SIZE.get(m.get('part'), 'M'), arc=arc, arc_deg=ARC_DEG[arc], slot=slot, weapon=wk,
              radius=float(m.get('radius') or 0), socket=m['socket'])
    HPS.append(dict(name=f'{key}_{k}', p=m['tip'], fwd=m['aim'], up=m['normal'], extras=ex)); by_slot.setdefault(slot, []).append(f'{key}_{k}')
for k, e in enumerate(sorted(HP['engines'], key=lambda e: (-e['radius'], -e['pos'][1]))):
    HPS.append(dict(name=f'hp_eng_{k}', p=e['pos'], fwd=e['dir'], up=(0, 0, 1), extras=dict(kind='engine', radius=float(e['radius']), engine=e['name'])))
for k, b in enumerate(BREACH):
    f = Vector((1, 0, 0)) if abs(b['n'].x) < .9 else Vector((0, 0, 1))
    HPS.append(dict(name=f'hp_breach_{k}', p=list(b['p']), fwd=list(f), up=list(b['n']),
                    extras=dict(kind='breach', radius=0.0, section=b['section'], side='P' if b['side'] > 0 else 'S', clear=b['clear'])))
HPS.append(dict(name='hp_core', p=list(CORE), fwd=(0, 1, 0), up=(0, 0, 1), extras=dict(kind='core')))   # identity in the game frame
for h in HPS: empty(h['name'], h['p'], h['fwd'], h['up'], h['extras'])
missing = [f'slot {i} ({wk} {arc})' for i, (wk, arc) in enumerate(WEAPONS) if i not in by_slot]
J['length_world'] = float(ship.get('length_world', 0) or 0); J['recipe_cell'] = ship.get('cell', ''); J['faction'] = ship.get('faction', '')

# ---------------------------------------------------------------------------------------------------------------- write
tmp = os.path.join(OUT, '_gltf_source'); os.makedirs(tmp, exist_ok=True)      # the exporter's own files; kept (nothing is deleted)
bpy.ops.object.select_all(action='DESELECT'); J.select_set(True)
for c in J.children: c.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(tmp, CODE + '.gltf'), export_format='GLTF_SEPARATE', use_selection=True, export_apply=True,
                          export_yup=True, export_extras=True, export_image_format='NONE' if UNBAKED else 'JPEG', export_jpeg_quality=92, export_image_quality=92,
                          export_tangents=False, export_cameras=False, export_lights=False, export_animations=False)
g = json.load(open(os.path.join(tmp, CODE + '.gltf')))
binname = g['buffers'][0]['uri']; blob = open(os.path.join(tmp, binname), 'rb').read()
files = {}
# the maps stay outside the glb, named by the format's rule from the job each one does in its material (not from whatever name
# the exporter gave the file)
role = {}
def use(mat, slot, tex):
    if tex is None: return
    i = g['textures'][tex['index']]['source']; pre = CODE if mat['name'] == CODE + '_hull' else mat['name']; nm = f'{pre}_{slot}'
    if role.get(i, nm) != nm: die(f'one image does two jobs ({role[i]} and {nm}): the ORM map must hold occlusion, roughness and metal together')
    role[i] = nm
for mat in g.get('materials', []):
    if mat.get('name') not in (CODE + '_hull', CODE + '_parts'): continue
    pbr = mat.get('pbrMetallicRoughness', {})
    use(mat, 'base', pbr.get('baseColorTexture')); use(mat, 'orm', pbr.get('metallicRoughnessTexture')); use(mat, 'orm', mat.get('occlusionTexture'))
    use(mat, 'normal', mat.get('normalTexture'))
for i, im in enumerate(g.get('images', [])):
    if i not in role: die(f'the exporter wrote an image no ship material uses: {im.get("uri")}')
    new = role[i] + '.jpg'; shutil.copyfile(os.path.join(tmp, im['uri']), os.path.join(OUT, new)); im['uri'] = new; im['name'] = role[i]
if not UNBAKED:
    need = {CODE + '_base', CODE + '_orm', CODE + '_normal', CODE + '_parts_base', CODE + '_parts_orm'}
    if set(role.values()) != need: die(f'the map set is not the format\'s: wrote {sorted(role.values())}, need {sorted(need)}')
del g['buffers'][0]['uri']; g['buffers'][0]['byteLength'] = len(blob)
g.setdefault('asset', {}).setdefault('extras', {}).update(recipe='tools/recipe/7_export.bat', ship=ship['ship'], cell=ship.get('cell'), game_ship=GAME,
                                                         unbaked=UNBAKED)
js = json.dumps(g, separators=(',', ':')).encode('utf-8'); js += b' ' * (-len(js) % 4); blob += b'\0' * (-len(blob) % 4)
with open(os.path.join(OUT, CODE + '.glb'), 'wb') as f:      # glb: header, the JSON chunk, the binary chunk (images by URI)
    f.write(struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(js) + 8 + len(blob)))
    f.write(struct.pack('<I4s', len(js), b'JSON')); f.write(js); f.write(struct.pack('<I4s', len(blob), b'BIN\0')); f.write(blob)
for fn in sorted(os.listdir(OUT)):
    p = os.path.join(OUT, fn)
    if os.path.isfile(p) and fn.startswith(CODE) and not fn.endswith(('_export.json', '_check.json')):
        files[fn] = dict(bytes=os.path.getsize(p), sha256=hashlib.sha256(open(p, 'rb').read()).hexdigest())
kinds = {}
for h in HPS: kinds[h['extras']['kind']] = kinds.get(h['extras']['kind'], 0) + 1
rep = dict(ship=ship['ship'], code=CODE, cell=ship.get('cell'), game_ship=GAME, faction=ship.get('faction'), unbaked=UNBAKED, maps=0 if UNBAKED else MAPS,
           triangles=TRIS, surfaces=len([s for s in J.material_slots if s.material]),
           weapons=[dict(slot=i, weapon=wk, arc=arc, hard_points=by_slot.get(i, [])) for i, (wk, arc) in enumerate(WEAPONS)],
           slots_without_hard_points=missing, hardpoints=kinds,
           hard_points=[dict(name=h['name'], p=[round(float(v), 5) for v in h['p']], fwd=[round(float(v), 4) for v in h['fwd']],
                             up=[round(float(v), 4) for v in h['up']], frame='ship (x bow, y port, z up)', **h['extras']) for h in HPS],
           files=files, seconds=round(time.time() - t0, 1),
           not_written=['<CODE>_wreck.glb (the death pieces)', '<CODE>_damage.glb and the skin_<n> hull patches (breach damage)',
                        '<CODE>_emissive.jpg (the glow is its own surface with an emissive factor, no map)'])
json.dump(rep, open(os.path.join(OUT, CODE + '_export.json'), 'w'), indent=1)
print('[export7]', CODE, 'triangles', TRIS, 'hard points', json.dumps(kinds), 'files', sorted(files), flush=True)
if missing:
    die('no hard point for ' + ', '.join(missing))
status('WRITTEN ' + CODE + ('  (unbaked test: no maps)' if UNBAKED else ''))
print('[export7] written', OUT, flush=True)
