# Issue 209 round 7: Ab7 = Ab6 with one bounded bow pass (Ryan, Nov 9 18:16 CST, R156: "The front is still very much off from the
# concept but the rest looks pretty good"). Read off the concept first (docs/shots/ship_pipeline/route209/round7/README.md, step 3);
# what its bow has that Ab6's did not:
#   1. a long flat bow deck with a sharp deck edge: the deck runs out to the full width of the hull at about z 0 and wraps round the
#      nose. Ab6's deck sat lower (z -0.015) and narrower (0.083 of 0.123), with a wide sloped shoulder down to the side;
#   2. slab sides: one tall near-vertical side from the deck edge down to about z -0.10 (the casemate plates lie flat on it), then
#      the tuck to the belly. Ab6's vertical side was 0.034 tall, so the bow read as a tube and the casemates stood proud as boxes;
#   3. a raked, overhanging prow: the slab side wraps the nose and overhangs a lower hull that falls away aft under it;
#   4. the bow gun hood: a wedge that rises aft from a thin louvred front lip, narrower than the hull so the deck runs past it on
#      both sides, with the two bow guns coming out from under the lip. Ab6 had a full-width box there with the guns lying on top.
# Everything aft of the bow break line (x 0.178) is Ab6's, untouched: same knots, blocks, plates and parts.
# Only the bow knots, the hood, the bow plates and a few bow deck fittings are new; the weapons still come from the Hullbreaker kit
# at the sockets in tools/recipe/ships/C15s_23.json.
# usage: imported by bakeAb6.py (R209_HULL=armA7), preview7.py, sil_dump.py; standalone: blender -b -P armA7.py -- OUT_DIR [Ab7]
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import armA6 as A6          # puts the kit folders on the path
import common as C
import bpy, bmesh
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import loft, box, cyl
import armA5 as A5
import armA3 as A3
from armA3 import tag, plate_crossing, armour
import plumbing as PB
import kit as HB

BREAK = A5.BREAK; GUNS = A5.GUNS; HERO_SLOTS = (); P = A5.P; knot = A5.knot
SHIP = A6.SHIP

# ------------------------------------------------------------------------------------------------ 1 to 3: the bow knots
# Same columns as armA5.HK: x, deck z (zt), deck-edge half-width (Wd), side half-width (Ws), top and bottom of the slab side
# (zs1, zs2), tuck point (Wt, zt2), belly corner (Wb, zb). The plan (Ws) and the belly are round 5's tuned numbers; the deck is
# raised toward the concept's level and taken out to the side (Wd = Ws - 0.003: a sharp edge), the slab side runs from just under
# the deck to z -0.108, and at the nose the lower hull is cut back a little more under the slab (the overhang).
# Where the concept disagrees with itself: its near (port) deck edge reads z 0.0 at x 0.39, its far outline wants the deck at about
# z -0.03 there. The deck sits between the two (z -0.010) and keeps round 5's fall toward the nose, which the outline needs.
BOW = [
    (0.210, -0.004, 0.120, 0.123, -0.009, -0.108, 0.085, -0.142, 0.040, -0.179),
    (0.300, -0.006, 0.120, 0.123, -0.011, -0.108, 0.087, -0.142, 0.041, -0.180),
    (0.380, -0.010, 0.122, 0.125, -0.015, -0.108, 0.082, -0.148, 0.038, -0.184),
    (0.420, -0.018, 0.106, 0.109, -0.023, -0.107, 0.078, -0.146, 0.040, -0.180),
    (0.450, -0.027, 0.088, 0.091, -0.032, -0.104, 0.072, -0.138, 0.042, -0.164),
    (0.480, -0.035, 0.068, 0.071, -0.040, -0.100, 0.051, -0.130, 0.030, -0.148),
    (0.497, -0.040, 0.038, 0.041, -0.045, -0.096, 0.025, -0.114, 0.014, -0.126),
]
BOW_X0 = .205     # knots forward of this are replaced

def set_bow():
    """swap the bow knots into armA5's table (knot(), section(), stations() and every seat read it)"""
    A5.HK[:] = [k for k in A5.HK if k[0] < BOW_X0] + [tuple(k) for k in BOW]

# ------------------------------------------------------------------------------------------------ 4: the bow gun hood
# The hood: a wedge on the bow deck. Flat top aft (it carries the forward drum pair), then the top slopes down and the plan narrows
# to a thin front lip; the guns come out of the front face under the lip. Numbers read off the concept through its camera.
HOOD = dict(x_back=.212, x_flat=.310, x_face=.368, x_lip=.400,     # aft end, where the slope starts, the front face, the lip's front edge
            w_back=(.078, .070), w_face=(.052, .046), w_lip=.038,  # half-widths (bottom, top)
            z_top=.046, z_face=.0335, z_lip=(.0245, .0290),        # top of the flat part, top at the front face, the lip (under, top)
            slats=6)

def hood_w(x):
    """the hood's bottom half-width at x (the deck beside it is clear outboard of this)"""
    h = HOOD
    if x <= h['x_flat']: return h['w_back'][0]
    t = min(1, (x - h['x_flat']) / (h['x_face'] - h['x_flat'])); return h['w_back'][0] + (h['w_face'][0] - h['w_back'][0]) * t

def hood_objs():
    h = HOOD; zb = lambda x: A5.deck_z(x) - .006; H = []
    o = loft('glacis', [A3.rtrap(h['x_face'], h['w_face'][0], h['w_face'][1], zb(h['x_face']), h['z_face'], .003, .002),
                        A3.rtrap(h['x_flat'], h['w_back'][0], h['w_back'][1], zb(h['x_flat']), h['z_top'], .003, .002),
                        A3.rtrap(h['x_back'], h['w_back'][0], h['w_back'][1], zb(h['x_back']), h['z_top'], .003, .002)], bevel=.002)
    H.append(A5.hull_obj(o, 'glacis'))
    zl0, zl1 = h['z_lip']; zf = h['z_face']
    o = loft('hoodlip', [A3.rtrap(h['x_lip'], h['w_lip'], h['w_lip'], zl0, zl1, .0012, .0008),
                         A3.rtrap(h['x_face'] - .004, h['w_face'][1], h['w_face'][1], zf - .0075, zf + .0004, .0012, .0008)], bevel=.0008)
    H.append(A5.hull_obj(o, 'glacis'))
    return H

def deck_lip():
    """the sharp deck edge: a thin deck plate over the bow deck that overhangs the slab side by 0.003 all the way round the nose"""
    secs = []
    for x in [x for x in A5.stations() if x >= .214]:
        k = knot(x); w = max(k['Ws'], k['Wd']) + .003; zt = k['zt']
        secs.append((x, [(w, zt + .0014), (w, zt - .0032), (-w, zt - .0032), (-w, zt + .0014)]))
    o = loft('decklip', secs, bevel=.0008); return A5.hull_obj(o, 'core')

def structure7():
    """armA5.structure5 with the new bow: the core hull lofts through the swapped knots, the hood replaces the raised-deck box"""
    set_bow()
    S = [o for o in A5.structure5() if o.name != 'glacis']
    for o in list(bpy.data.objects):
        if o.name == 'glacis' and o not in S: bpy.data.objects.remove(o, do_unlink=True)
    new = hood_objs() + [deck_lip()]
    for o in new:
        bpy.context.view_layer.objects.active = o; o.select_set(True)
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
        o.select_set(False)
    return S + new

# ------------------------------------------------------------------------------------------------ bow plates
BOW_PLATES = ('plU', 'plS', 'plT', 'pld', 'plg')     # armA5.plates5's bow plates (shoulder, slab, tuck, deck strips, raised deck top)

def plates7(S):
    """armA5.plates5 aft of the bow break line; the bow re-plated for the slab side: two belts on the side (a narrow strake under
    the deck edge, the main belt below it), the tuck, the deck strips beside the hood, the foredeck and the hood top"""
    Pl = []
    for o in A5.plates5(S):
        if o.name.startswith(BOW_PLATES): bpy.data.objects.remove(o, do_unlink=True)
        else: Pl.append(o)
    by = {}
    for o in S: by.setdefault(o['kind'], []).append(o)
    B = {k: C.bvh(v) for k, v in by.items()}; lo, hi = .0025, .0045; kb = knot(.30); h = HOOD
    zA = (-.030, kb['zs1'] - .004)                     # the strake under the deck edge
    zB = (kb['zs2'] + .004, -.036)                     # the main belt
    zT = (kb['zt2'] + .008, kb['zs2'] - .005)          # the upper tuck
    for s in (1, -1):
        t = 'p' if s > 0 else 's'
        for k, (x0, x1) in enumerate(((.216, .300), (.292, .384), (.376, .436))):
            Pl.append(armour(f'plU{t}{k}', B['core'], 'side', (x0, x1), zA, s, off=hi if k % 2 else lo))
        for k, (x0, x1) in enumerate(((.216, .290), (.282, .372), (.364, .430))):
            Pl.append(armour(f'plS{t}{k}', B['core'], 'side', (x0, x1), zB, s, off=lo if k % 2 else hi))
        for k, (x0, x1) in enumerate(((.216, .304), (.296, .380))):
            Pl.append(armour(f'plT{t}{k}', B['core'], 'side', (x0, x1), zT, s, off=hi if k % 2 else lo))
        # deck strips beside the hood (clear of its widest point), and the foredeck ahead of the lip
        Pl.append(armour(f'pld{t}0', B['core'], 'top', (.216, .296), tuple(sorted((s * (h['w_back'][0] + .007), s * .113))), s, off=hi))
        Pl.append(armour(f'pld{t}1', B['core'], 'top', (.304, .372), tuple(sorted((s * (h['w_back'][0] + .007), s * .113))), s, off=lo))
        Pl.append(armour(f'pld{t}2', B['core'], 'top', (.408, .448), tuple(sorted((s * .005, s * .078))), s, off=hi))
        # hood top (flat part), split down the centreline
        Pl.append(armour(f'plg{t}', B['glacis'], 'top', (.220, .294), tuple(sorted((s * .004, s * (h['w_back'][1] - .010)))), s, off=lo))
    return Pl

# ------------------------------------------------------------------------------------------------ bow fittings
def bow_fittings(seat):
    """the hood's louvres (dark slats on the lip and the front of the slope), a dark double hatch on each hood cheek, two flat
    deck hatches and a low grab bar over the forward hatch (an EVA handhold, as the concept's bow deck has; not a naval railing)"""
    h = HOOD; Pp = hs_lib.PARTS
    slope = math.atan2(h['z_face'] - h['z_lip'][1], h['x_lip'] - h['x_face'])          # the lip's top falls toward the front
    n0 = len(Pp)
    for k in range(h['slats']):
        f = (k + .5) / h['slats']; x = h['x_face'] - .006 + f * (h['x_lip'] - h['x_face'] + .004)
        z = seat.top(x, 0) or h['z_lip'][1]; w = h['w_lip'] + (h['w_face'][1] - h['w_lip']) * (1 - f)
        box(f'hslat{k}', (x, 0, z + .0009), (.0030, 2 * w - .006, .0016), rot=(0, slope, 0), bevel=0)
    tag('part', n0, 'gun_dark')
    ang = math.atan2(h['w_back'][0] - h['w_face'][0], h['x_face'] - h['x_flat'])        # the cheek's plan angle
    for s in (1, -1):
        for j, x in enumerate((.322, .344)):
            y, nrm = seat.flank(x, .017, s)
            if y is None: continue
            n0 = len(Pp); box(f'hhatch{s}{j}', (x, s * (y + .0008), .017), (.019, .0026, .017), rot=(0, 0, -s * ang), bevel=.0006); tag('part', n0, 'gun_dark')
            n0 = len(Pp); box(f'hhatchi{s}{j}', (x, s * (y + .0020), .017), (.013, .0012, .011), rot=(0, 0, -s * ang), bevel=0); tag('dark', n0)
    def fall(x, y):      # the deck's fall toward the nose at (x, y), as a rotation about the y axis for a fitting lying on it
        a, b = seat.top(x - .008, y), seat.top(x + .008, y)
        return math.atan2(a - b, .016) if a is not None and b is not None else 0.0
    n0 = len(Pp)
    for (x, y, L, W) in ((.432, .052, .026, .018), (.300, .102, .022, .016)):
        for s in (1, -1):
            z = seat.top(x, s * y)
            if z is not None: box(f'dhatch{s}{x}', (x, s * y, z + .0008), (L, W, .0022), rot=(0, fall(x, s * y), 0), bevel=.0006)
    tag('part', n0, 'hood')
    xh, yh = .458, 0.0; z = seat.top(xh, yh)
    if z is not None:
        n0 = len(Pp); box('fhatch', (xh, yh, z + .0008), (.022, .026, .0022), rot=(0, fall(xh, yh), 0), bevel=.0006); tag('part', n0, 'gun_dark')
        n0 = len(Pp); zb = z + .011
        for sy in (1, -1):
            HB.tube(f'grab{sy}', (xh - .016, sy * .020, seat.top(xh - .016, sy * .020) or z), (xh - .016, sy * .020, zb), .0016, seg=6)
        HB.tube('grabbar', (xh - .016, -.020, zb), (xh - .016, .020, zb), .0016, seg=6)
        tag('part', n0, 'rack')

# ------------------------------------------------------------------------------------------------ build
def build_geometry(hero=(), G=None):
    """structure, plates, Ab6's other parts, the bow fittings, then the weapons from the Hullbreaker kit at the ship's sockets"""
    bpy.ops.wm.read_factory_settings(use_empty=True); hs_lib.PARTS.clear(); GUNS.clear(); PB.clear_registry(); C.set_break(**BREAK)
    S = structure7(); Pl = plates7(S); seat = A3.Seat(S + Pl); notes = []
    A6.other_parts(seat); bow_fittings(PB.Seat(S + Pl))
    ship = json.load(open(SHIP)); socks = PB.resolve(PB.sockets_from(ship), PB.Seat(S + Pl))
    bad = HB.build(socks, PB.Seat(S + Pl))
    for n, a, nn in PB.GUNS: GUNS.append((n, a))
    bpy.context.scene['r209_hp'] = json.dumps(PB.hardpoint_data(socks))      # muzzles and engine exits for the game export
    notes.append(dict(kit=HB.FACTION, bow='round 7 bow pass (armA7)', guns_badly_aimed=bad,
                      sockets=[dict(name=s.name, part=s.part, pos=[round(v, 4) for v in s.pos], aim=[round(v, 3) for v in s.aim],
                                    normal=[round(v, 3) for v in s.normal], side=s.side) for s in socks]))
    for o in hs_lib.PARTS:
        if 'role' not in o: o['role'] = 'part'
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    return S, Pl, list(hs_lib.PARTS), [], notes, []

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    out = a[0]; cell = a[1] if len(a) > 1 else 'Ab7'; t0 = time.time()
    S, Pl, hard, gen, notes, prox = build_geometry()
    rep = C.report(S + Pl + hard)
    bpy.context.scene['r209_guns'] = json.dumps([(n, list(a)) for n, a in GUNS])   # the audit (tools/recipe/audit.py) reads the aims
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f'{cell}.blend'))
    meta = dict(cell=cell, plates=len(Pl), plate_crossing=plate_crossing(Pl), seconds=round(time.time() - t0, 1), notes=notes, **rep)
    json.dump(meta, open(os.path.join(out, f'{cell}_build.json'), 'w'), indent=1)
    print('[209]', json.dumps(meta)[:3000], flush=True)
