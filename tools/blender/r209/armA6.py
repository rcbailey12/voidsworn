# Issue 209 round 6: Ab5's hull (armA5: traced from B0, tuned to the concept outline) with its weapons rebuilt by the Hullbreaker
# parts kit (tools/blender/kits/hullbreakers/kit.py) at the concept's sizes and places (Ryan, Nov 9 14:52 CST, R151: "weapons and
# paint first. Let's ensure it actually looks good"; R150: "there are still some gaps in the detail or approach with the weapons").
# Weapon placement is data, not code: tools/recipe/ships/C15s_23.json (measured off the concept through its fitted camera). Every
# other part (tower, aft mast, engines, cargo blocks, ventral pylons, small detail) is armA5's, unchanged.
# usage: imported by bakeAb6.py, preview6.py, sil_dump.py; standalone: blender -b -P armA6.py -- OUT_DIR [Ab6]
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
KITS = os.path.normpath(os.path.join(HERE, '..', 'kits'))
for p in (os.path.join(KITS, 'shared'), os.path.join(KITS, 'hullbreakers')):
    if p not in sys.path: sys.path.insert(0, p)
import common as C
import bpy, bmesh
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import loft, box, cyl
import armA5 as A5
import armA3 as A3
from armA3 import tag, plate_crossing
import plumbing as PB
import kit as HB

BREAK = A5.BREAK
GUNS = A5.GUNS
HERO_SLOTS = ()
P = A5.P; knot = A5.knot; plates5 = A5.plates5; structure5 = A5.structure5
SHIP = os.environ.get('R209_SHIP', os.path.normpath(os.path.join(HERE, '..', '..', 'recipe', 'ships', 'C15s_23.json')))

def other_parts(seat):
    """armA5.parts5 without its weapons (bow guns, casemates, drums, drum racks): tower, aft mast, engines, cargo, pylons, detail"""
    Pp = hs_lib.PARTS; p = P
    TOWER, MAST = A5.TOWER, A5.MAST
    tx, z2 = TOWER['x'], p['t2_z']; dt = max(.040, TOWER['drum_top'] - z2)
    n0 = len(Pp); cyl('tower', (tx, 0, z2 + dt / 2 - .002), .036, dt + .004, seg=40, bevel=.003); tag('part', n0, 'tower')
    n0 = len(Pp); cyl('towerband', (tx, 0, z2 + dt * .62), .0375, .006, seg=40, bevel=0); tag('trim', n0, 'band')
    n0 = len(Pp); cyl('bridge', (tx, 0, z2 + dt + .003), .042, .006, seg=40, bevel=.0015); tag('part', n0, 'bridge')
    n0 = len(Pp)
    for k in range(10):
        t = k * math.pi / 5; cyl(f'brail{k}', (tx + .040 * math.cos(t), .040 * math.sin(t), z2 + dt + .011), .0012, .010, seg=6, bevel=0)
    for k in range(4):
        t = k * math.pi / 2 + .3; box(f'bwin{k}', (tx + .0365 * math.cos(t), .0365 * math.sin(t), z2 + dt * .8), (.008, .008, .006), rot=(0, 0, t), bevel=.0005)
    tag('dark', n0)
    A5.antenna_tower(tx, z2 + dt + .006, TOWER['truss_top'], TOWER['w0'], TOWER['w1'])
    A5.aft_mast(MAST['x'], seat.top(MAST['x'], 0), MAST['top'], MAST['dx'], MAST['dy'])
    xs = p['st_x'][1]
    for nm, (y, z, r) in (('main', (0, -.004, .026)), ('portb', (.044, -.004, .016)), ('stbdb', (-.044, -.004, .016))):
        n0 = len(Pp); A5.B_engine((xs + .002, y, z), r, .036 if r > .02 else .026); tag('part', n0, 'engine')
        n0 = len(Pp); cyl(f'glow{nm}', (xs - .036 if r > .02 else xs - .027, y, z), r * .9, .002, axis='X', seg=32, bevel=0); tag('glow', n0)
    (xa, xb), (za, zb_), wo = p['cg_x'], p['cg_z'], p['cg_out']
    for s in (1, -1):
        n0 = len(Pp); wi = .090
        loft(f'cargo{s}', [A5.rbox(xa, wi, wo - .008, za + .010, zb_ - .006, s), A5.rbox(xa - .008, wi, wo, za, zb_, s),
                           A5.rbox(xb + .008, wi, wo, za, zb_, s), A5.rbox(xb, wi, wo - .008, za + .010, zb_ - .006, s)], bevel=.002)
        for xx in (xa - .024, xb + .024): box(f'cargoarm{s}{xx}', (xx, s * (wi + .004), zb_ + .004), (.016, .012, .010), bevel=.001)
        hz = zb_ - za - .008; cz = (za + zb_) / 2
        for k in range(7): box(f'cargorib{s}{k}', (xa - .012 - k * .012, s * (wo + .001), cz), (.005, .004, hz), bevel=0)
        for k in range(5): box(f'cargorib2{s}{k}', (xb + .060 - k * .010, s * (wo + .001), cz), (.004, .004, hz), bevel=0)
        box(f'cargohatch{s}', ((xa + xb) / 2 - .004, s * (wo + .001), cz + .003), (.020, .003, hz * .66), bevel=.0006)
        tag('part', n0, 'cargo')
    for s in (1, -1):
        n0 = len(Pp); R = Matrix.Rotation(math.radians(s * -8), 3, 'X'); zr = knot(.35 + p['fin_dx'])['zb'] + .004
        bm = bmesh.new(); fx, fz = p['fin_dx'], p['fin_dz']; ff = p['fin_fwd']; fr = p['fin_root']
        prof = [(.420 + fx - fr, zr), (.288 + fx - fr * .5, zr), (.304 + fx + ff * .5, -.238 - fz), (.416 + fx + ff, -.244 - fz)]
        vs = [[bm.verts.new(Vector((x, s * .026, zr)) + R @ Vector((0, k * .0045, z - zr))) for x, z in prof] for k in (-1, 1)]
        bm.faces.new(vs[0][::-1]); bm.faces.new(vs[1])
        for i in range(4): bm.faces.new((vs[0][i], vs[0][(i + 1) % 4], vs[1][(i + 1) % 4], vs[1][i]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces); hs_lib._obj(f'vfin{s}', bm, .0015)
        tip = Vector((.366 + fx, s * .026, zr)) + R @ Vector((0, 0, -.248 - fz - zr))
        cyl(f'vpod{s}', tip + Vector((ff * .7, 0, 0)), .010, .110 + ff * .6, axis='X', seg=24, r2=.007, bevel=.001)
        tag('part', n0, 'fin')
    for s in (1, -1):
        n0 = len(Pp); xv = -.300; zt = knot(xv)['zb']
        cyl(f'vthr{s}', (xv, s * .050, zt - .012), .011, .046, axis='X', seg=24, bevel=.002)
        box(f'vthrpylon{s}', (xv, s * .050, zt - .003), (.030, .008, .008), bevel=.001); tag('part', n0, 'engine')
    import detail_lib as D
    n0 = len(Pp)
    for s_ in (1, -1):
        hs_lib.vents(f'spvent{s_}', (.120, s_ * (seat.flank(.120, .004, s_) + .001), .004), 6, .003, .010, .008)
        for xx in (-.020, -.070): box(f'mhatch{s_}{xx}', (xx, s_ * (seat.flank(xx, -.074, s_) + .0005), -.074), (.026, .002, .030), bevel=.0006)
        zt = seat.top(.440, s_ * .044)
        box(f'dvent{s_}', (.440, s_ * .044, zt + .003), (.024, .016, .006), bevel=.0008)
        zt = seat.top(-.320, s_ * .036)
    for yy in (-.058, .058): D.tube(f'aftpipe{yy}', Vector((-.140, yy, P['ab_z'] - .012)), Vector((-.410, yy, P['ab_z'] - .012)), .0032)
    tag('part', n0, 'detail')

def build_geometry(hero=(), G=None):
    """structure, plates, armA5's other parts, then the weapons from the Hullbreaker kit at the placement file's sockets"""
    bpy.ops.wm.read_factory_settings(use_empty=True); hs_lib.PARTS.clear(); GUNS.clear(); PB.GUNS.clear(); C.set_break(**BREAK)
    S = structure5(); Pl = plates5(S); seat = A3.Seat(S + Pl); notes = []
    other_parts(seat)
    ship = json.load(open(SHIP)); socks = PB.resolve(PB.sockets_from(ship), PB.Seat(S + Pl))
    bad = HB.build(socks, PB.Seat(S + Pl))
    for n, a, nn in PB.GUNS: GUNS.append((n, a))
    notes.append(dict(kit=HB.FACTION, sockets=[dict(name=s.name, part=s.part, pos=[round(v, 4) for v in s.pos], aim=[round(v, 3) for v in s.aim]) for s in socks],
                      guns_badly_aimed=bad))
    for o in hs_lib.PARTS:
        if 'role' not in o: o['role'] = 'part'
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    return S, Pl, list(hs_lib.PARTS), [], notes, []

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    out = a[0]; cell = a[1] if len(a) > 1 else 'Ab6'; t0 = time.time()
    S, Pl, hard, gen, notes, prox = build_geometry()
    rep = C.report(S + Pl + hard)
    bpy.context.scene['r209_guns'] = json.dumps([(n, list(a)) for n, a in GUNS])   # the audit (tools/recipe/audit.py) reads the aims
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f'{cell}.blend'))
    meta = dict(cell=cell, plates=len(Pl), plate_crossing=plate_crossing(Pl), seconds=round(time.time() - t0, 1), notes=notes, **rep)
    print('[209]', json.dumps(meta)[:3000], flush=True)
