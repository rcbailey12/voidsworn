# Issue 209 round 8: Ab8 = Ab7 with the bow third's hull sections FITTED to the concept outline (Board brief, Nov 10; Ryan, R156: "The
# front is still very much off from the concept"). Round 7 added detail to the bow and its outline got worse (bow third 91.0 to 90.3).
# This round changes the shape only, by fitting, not by adding parts.
#
# The concept's bow, read before fitting (docs/shots/ship_pipeline/route209/round8/README.md, step 1):
#   1. plan: a broad rounded D. The deck keeps nearly its full width well forward (to about x 0.45), then rounds to a blunt stem;
#   2. side: the bow deck runs level from the forecastle and then falls in one long straight slope to the stem, so the prow is long
#      and low; the slab side stays vertical round the nose (no raked stem), shallowest at the stem;
#   3. the step up: the hood (the forecastle) stands well above the falling deck. Its front face is a tall, near-vertical step at
#      about x 0.39 with the twin bow guns coming out of it, and its top rises aft to the flat drum deck;
#   4. under the slab, a chamfered tuck to a flat armoured belly; the ventral fins sit under the bow a little deeper than Ab7's.
#
# The numbers come from tools/blender/r209/fit8.py (coordinate descent on the concept outline at the concept camera, with the bow's
# inner edges in the score) over smooth curves: deck height, a superellipse plan, slab bottom, tuck and belly, hood face, lip and top.
# Ranges keep the design: flat deck with a sharp edge, slab side at least to z -0.102 (it carries the casemates), a flat belly at
# least 0.45 of the tuck width, no keel. The result is fixed in fit8_bow.json (the fit's own output, copied).
# The weapons still come from the Hullbreaker kit at tools/recipe/ships/C15s_23.json (bow guns moved to the new hood face there).
# usage: imported by bakeAb6.py (R209_HULL=armA8), preview7.py, sil_dump.py; standalone: blender -b -P armA8.py -- OUT_DIR [Ab8]
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import armA7 as A7
import armA6 as A6
import armA5 as A5
import armA3 as A3
import common as C
import bpy
import hs_lib
from hs_lib import box
from armA3 import tag, plate_crossing, armour
import plumbing as PB
import kit as HB

FIT = json.load(open(os.environ.get('R209_FIT8') or os.path.join(HERE, 'fit8_bow.json')))     # R209_FIT8: another fit8.json, for a trial build
BREAK = A7.BREAK; GUNS = A7.GUNS; HERO_SLOTS = (); P = A5.P; knot = A5.knot; SHIP = A7.SHIP

# the fitted bow knots and hood go into armA7's tables, so armA7's structure, hood and deck lip build the new shape
A7.BOW[:] = [tuple(k) for k in FIT['bow']]
A7.HOOD.clear(); A7.HOOD.update({k: (tuple(v) if isinstance(v, list) else v) for k, v in FIT['hood'].items()})
P['fin_dx'] += FIT['params']['fin_dx']; P['fin_dz'] += FIT['params']['fin_dz']     # the fit's moves on top of round 5's tuned fins


SIDE_PLATES = os.environ.get('R209_BOWPLATES', 'UST')     # which bow side belts are built: U strake, S main belt, T tuck


def plates8(S):
    """armA5.plates5 aft of the bow break line; the bow plated for the fitted shape. The deck falls toward the stem, so each belt
    segment takes its z range from the hull at its own forward end (a belt never rides above the deck edge or below the slab)"""
    Pl = []
    for o in A5.plates5(S):
        if o.name.startswith(A7.BOW_PLATES): bpy.data.objects.remove(o, do_unlink=True)
        else: Pl.append(o)
    by = {}
    for o in S: by.setdefault(o['kind'], []).append(o)
    B = {k: C.bvh(v) for k, v in by.items()}; lo, hi = .0025, .0045; h = A7.HOOD
    for s in (1, -1):
        t = 'p' if s > 0 else 's'
        # the strake under the deck edge and the main belt: z from the hull at the segment's forward end
        for k, (x0, x1) in enumerate(((.216, .300), (.292, .372), (.364, .428))):
            kk = knot(x1); top = kk['zs1'] - .004
            if 'U' in SIDE_PLATES: Pl.append(armour(f'plU{t}{k}', B['core'], 'side', (x0, x1), (top - .024, top), s, off=hi if k % 2 else lo))
            if 'S' in SIDE_PLATES: Pl.append(armour(f'plS{t}{k}', B['core'], 'side', (x0, x1), (kk['zs2'] + .004, top - .028 if 'U' in SIDE_PLATES else top), s, off=lo if k % 2 else hi))
        # the nose: one plate wrapping the slab forward of the belts
        kk = knot(.470)
        if 'S' in SIDE_PLATES: Pl.append(armour(f'plS{t}3', B['core'], 'side', (.420, .470), (kk['zs2'] + .004, kk['zs1'] - .006), s, off=hi))
        # the upper tuck
        kb = knot(.30)
        for k, (x0, x1) in enumerate(((.216, .304), (.296, .380))):
            if 'T' in SIDE_PLATES: Pl.append(armour(f'plT{t}{k}', B['core'], 'side', (x0, x1), (kb['zt2'] + .010, kb['zs2'] - .006), s, off=hi if k % 2 else lo))
        # deck strips beside the hood (clear of it), and the falling foredeck ahead of the hood face
        wd = knot(.30)['Wd'] - .008
        Pl.append(armour(f'pld{t}0', B['core'], 'top', (.216, .296), tuple(sorted((s * (h['w_back'][0] + .007), s * wd))), s, off=hi))
        Pl.append(armour(f'pld{t}1', B['core'], 'top', (.304, .372), tuple(sorted((s * (h['w_back'][0] + .004), s * wd))), s, off=lo))
        Pl.append(armour(f'pld{t}2', B['core'], 'top', (.404, .452), tuple(sorted((s * .005, s * .070))), s, off=hi))
        Pl.append(armour(f'plg{t}', B['glacis'], 'top', (.220, .294), tuple(sorted((s * .004, s * (h['w_back'][1] - .010)))), s, off=lo))
    return Pl


def bow_fittings8(seat):
    """armA7's bow fittings with the deck hatch beside the hood brought inboard of the narrower deck edge"""
    h = A7.HOOD; Pp = hs_lib.PARTS
    slope = math.atan2(h['z_face'] - h['z_lip'][1], h['x_lip'] - h['x_face'])
    n0 = len(Pp)
    for k in range(h['slats']):
        f = (k + .5) / h['slats']; x = h['x_face'] - .006 + f * (h['x_lip'] - h['x_face'] + .004)
        z = seat.top(x, 0) or h['z_lip'][1]; w = h['w_lip'] + (h['w_face'][1] - h['w_lip']) * (1 - f)
        box(f'hslat{k}', (x, 0, z + .0009), (.0030, 2 * w - .006, .0016), rot=(0, slope, 0), bevel=0)
    tag('part', n0, 'gun_dark')
    ang = math.atan2(h['w_back'][0] - h['w_face'][0], h['x_face'] - h['x_flat'])
    for s in (1, -1):
        for j, x in enumerate((.334, .356)):
            y, nrm = seat.flank(x, .017, s)
            if y is None: continue
            n0 = len(Pp); box(f'hhatch{s}{j}', (x, s * (y + .0008), .017), (.019, .0026, .017), rot=(0, 0, -s * ang), bevel=.0006); tag('part', n0, 'gun_dark')
            n0 = len(Pp); box(f'hhatchi{s}{j}', (x, s * (y + .0020), .017), (.013, .0012, .011), rot=(0, 0, -s * ang), bevel=0); tag('dark', n0)
    def fall(x, y):
        a, b = seat.top(x - .008, y), seat.top(x + .008, y)
        return math.atan2(a - b, .016) if a is not None and b is not None else 0.0
    n0 = len(Pp)
    for (x, y, L, W) in ((.428, .048, .024, .018), (.300, .090, .022, .014)):
        for s in (1, -1):
            z = seat.top(x, s * y)
            if z is not None: box(f'dhatch{s}{x}', (x, s * y, z + .0008), (L, W, .0022), rot=(0, fall(x, s * y), 0), bevel=.0006)
    tag('part', n0, 'hood')
    xh, yh = .462, 0.0; z = seat.top(xh, yh)
    if z is not None:
        n0 = len(Pp); box('fhatch', (xh, yh, z + .0008), (.020, .024, .0022), rot=(0, fall(xh, yh), 0), bevel=.0006); tag('part', n0, 'gun_dark')
        n0 = len(Pp); zb = z + .011; xg = xh - .016
        for sy in (1, -1):
            zg = seat.top(xg, sy * .020) or z
            HB.tube(f'grab{sy}', (xg, sy * .020, zg), (xg, sy * .020, zg + .011), .0016, seg=6)
        zg = (seat.top(xg, .020) or z) + .011
        HB.tube('grabbar', (xg, -.020, zg), (xg, .020, zg), .0016, seg=6)
        tag('part', n0, 'rack')


def build_geometry(hero=(), G=None):
    """armA7.build_geometry on the fitted bow"""
    bpy.ops.wm.read_factory_settings(use_empty=True); hs_lib.PARTS.clear(); GUNS.clear(); PB.clear_registry(); C.set_break(**BREAK)
    S = A7.structure7(); Pl = plates8(S); seat = A3.Seat(S + Pl); notes = []
    A6.other_parts(seat); bow_fittings8(PB.Seat(S + Pl))
    ship = json.load(open(SHIP)); socks = PB.resolve(PB.sockets_from(ship), PB.Seat(S + Pl))
    bad = HB.build(socks, PB.Seat(S + Pl))
    for n, a, nn in PB.GUNS: GUNS.append((n, a, nn))
    bpy.context.scene['r209_hp'] = json.dumps(PB.hardpoint_data(socks))
    notes.append(dict(kit=HB.FACTION, bow='round 8 fitted bow (armA8, fit8.py)', guns_badly_aimed=bad,
                      sockets=[dict(name=s.name, part=s.part, pos=[round(v, 4) for v in s.pos], aim=[round(v, 3) for v in s.aim],
                                    normal=[round(v, 3) for v in s.normal], side=s.side) for s in socks]))
    for o in hs_lib.PARTS:
        if 'role' not in o: o['role'] = 'part'
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    return S, Pl, list(hs_lib.PARTS), [], notes, []


if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    out = a[0]; cell = a[1] if len(a) > 1 else 'Ab8'; t0 = time.time()
    S, Pl, hard, gen, notes, prox = build_geometry()
    rep = C.report(S + Pl + hard)
    bpy.context.scene['r209_guns'] = json.dumps([(g[0], list(g[1]), list(g[2]) if len(g) > 2 and g[2] is not None else None) for g in GUNS])
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f'{cell}.blend'))
    meta = dict(cell=cell, plates=len(Pl), plate_crossing=plate_crossing(Pl), seconds=round(time.time() - t0, 1), notes=notes, **rep)
    json.dump(meta, open(os.path.join(out, f'{cell}_build.json'), 'w'), indent=1)
    print('[209]', json.dumps(meta)[:3000], flush=True)
