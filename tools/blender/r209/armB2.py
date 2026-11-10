# Issue 209 round 2, Arm B cells on the corrected structure.
#   B0r2  the whole-hull generation again, yaw fixed (round 1's B0 sat about 20 degrees off the ship axis), round 2 break lines.
#         The control image and the bake source for the Ab cell.
#   B3r2  generated parts on the corrected hand-built core, one rung up: armA2's structure and hull detail (the same plating as A2,
#         so the only difference from A2 is how the parts were made), TRELLIS.2 parts at double round 1's triangle budget.
# Thin parts (sensor array, radiators) and the command tower stay hand-built, as in round 1 (generators drop thin parts, #214).
# usage: python armB2.py -- CELL GEN3D_DIR B0_GLB OUT_DIR
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import common as C
import bpy
from mathutils import Vector
import hs_lib
from hs_lib import box, cyl
import armB as AB
import armA2 as A2

YAW_B0 = 22.0       # measured in round 2: the yaw that makes B0's mid-hull slab widths narrowest (PCA of the hull band gives 20)
PART_K = 2          # round 2 rung: double round 1's per-part triangle budget

def b3_parts(G, notes, made, hull):
    P = lambda nm: os.path.join(G, f'p_{nm}.glb'); T = C.bvh(hull)
    def flank(x, z):
        h = T.ray_cast(Vector((x, .6, z)), Vector((0, -1, 0)), .6); return h[0].y if h[0] is not None else A2.at(x)[3]
    for i, x in enumerate((.368, .248)):
        for s in (1, -1):
            wc = flank(x, -.046)
            o = AB.gen(P('casemate'), f'casemate_{i}{"p" if s > 0 else "s"}', 15000 * PART_K, (x - .040, wc - .004, -.086), (x + .040, wc + .060, -.006), 'part', notes)
            if s < 0: AB.mirror_y(o)
            made.append(o)
    # drum racks at A2's drum stations: deckhouse tier front, each sponson top, each aft module, aft deck
    for nm, (x, y, L, W, H) in (('drums_f', (.146, 0, .046, .100, .034)), ('drums_sp', (.092, .139, .085, .066, .030)), ('drums_ss', (.092, -.139, .085, .066, .030)),
                                ('drums_mp', (-.050, .134, .080, .050, .036)), ('drums_ms', (-.050, -.134, .080, .050, .036)), ('drums_a', (-.290, 0, .070, .125, .034))):
        zt = A2.top_z(x, y)
        made.append(AB.gen(P('drumrack'), nm, 20000 * PART_K, (x - L / 2, y - W / 2, zt - .003), (x + L / 2, y + W / 2, zt + H), 'part', notes))
    made.append(AB.gen(P('bowguns'), 'bowguns', 12000 * PART_K, (.336, -.050, .052), (.452, .050, .088), 'part', notes))
    for s in (1, -1):
        o = AB.gen(P('cargo'), f'cargo_{"p" if s > 0 else "s"}', 20000 * PART_K, (-.300, .100, -.108), (-.146, .160, -.010), 'part', notes)
        if s < 0: AB.mirror_y(o)
        made.append(o)
    made.append(AB.gen(P('sternblock'), 'sternblock', 25000 * PART_K, (-.548, -.092, -.058), (-.480, .092, .066), 'part', notes))

def b3_thin():
    import barge_shapes as B
    cyl('tower', (.058, 0, .094 + .030), .034, .060, seg=32, bevel=.003)
    box('bridge', (.068, 0, .094 + .068), (.058, .070, .022), bevel=.003)
    B.antenna_array(.058, 0, .094 + .079, h=.080)
    B.radiator_pair(-.426, 0, .094, n=2, L=.070, H=.046)

def build(cell, G, b0, out):
    t0 = time.time(); bpy.ops.wm.read_factory_settings(use_empty=True); hs_lib.PARTS.clear(); notes = []; made = []
    C.set_break(**A2.BREAK)
    if cell == 'B0r2':
        o = C.import_glb(b0, 'b0_whole'); n0, n1 = AB.decimate(o, AB.DENSITY); C.ai_align(o, YAW_B0); o['role'] = 'ai'; hull = [o]
        notes.append(dict(part='whole hull', source=os.path.basename(b0), tris_raw=n0, tris=n1, yaw=YAW_B0))
    elif cell == 'B3r2':
        hull = A2.structure(); b3_thin(); b3_parts(G, notes, made, hull)
    for o in hs_lib.PARTS:
        if 'role' not in o: o['role'] = 'part'
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    parts = [o for o in made + hs_lib.PARTS if o.get('role') != 'glow']
    au = C.audit(hull, parts, [])
    if cell == 'B3r2':  # the same hull detail as A2 (round 2 rung), seated around the generated parts
        n0 = len(hs_lib.PARTS); A2.detail(hull, parts, 2)
        for o in hs_lib.PARTS[n0:]:
            o['role'] = 'part'
            for m in list(o.modifiers):
                bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    brk, fit_notes = C.breakable(hull)
    allobj = hull + made + list(hs_lib.PARTS) + brk
    C.paint(allobj, hull)
    rep = C.report(allobj)
    meta = dict(cell=cell, build_seconds=round(time.time() - t0, 1), audit=au, break_fit=fit_notes, break_lines=A2.BREAK, generations=notes, **rep)
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f'{cell}.blend'))
    json.dump(meta, open(os.path.join(out, f'{cell}.json'), 'w'), indent=1); print('[209]', cell, json.dumps(meta)[:1500], flush=True)

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:]
    build(a[0], a[1], a[2], a[3])
