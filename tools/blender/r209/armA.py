# Issue 209 round 1, Arm A rung 1: the C15s Hullbreaker cruiser hand-built in Blender at a modest detail level, using the AI mesh and
# the Qwen reference views only as massing underlay (the station table below was measured off the TRELLIS.2 whole-hull mesh, see
# docs/shots/ship_pipeline/route209/design_c15s.md). Breakable by design through common.breakable(). Space, not naval: no keel, no
# chin fin, no lattice masts (sensor array and radiators instead), guns forward or out, matched pairs.
# usage: blender -b -P armA.py -- OUT_DIR      (or the bpy module: python armA.py -- OUT_DIR)
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import common as C
import bpy
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import loft, frustum, box, cyl

# stations: x, deck half-width, deck z, flank half-width, chine z, belly half-width, belly z (bow is +x)
ST = [(.500, .030, .020, .040, -.030, .025, -.070), (.470, .072, .036, .090, -.022, .062, -.092), (.420, .105, .044, .126, -.020, .092, -.106),
      (.330, .125, .052, .148, -.020, .110, -.115), (.200, .135, .056, .156, -.020, .118, -.120), (.100, .138, .058, .156, -.020, .118, -.120),
      (.040, .138, .066, .154, -.020, .116, -.122), (.000, .136, .074, .150, -.020, .114, -.122), (-.120, .128, .078, .142, -.020, .108, -.120),
      (-.220, .122, .078, .136, -.018, .102, -.116), (-.340, .116, .076, .130, -.015, .098, -.110), (-.460, .110, .072, .124, -.012, .094, -.104),
      (-.500, .104, .066, .118, -.012, .090, -.098)]

def sec(s):
    x, wd, zt, wc, zc, wb, zb = s
    half = [(wd, zt), (wc, zt - .016), (wc, zc), (wb, zb)]
    return (x, [(0, zt)] + half + [(0, zb)] + [(-y, z) for y, z in reversed(half)])

def at(x):
    """interpolated station at x"""
    for a, b in zip(ST, ST[1:]):
        if b[0] <= x <= a[0]:
            t = (x - b[0]) / (a[0] - b[0]); return tuple(b[i] + (a[i] - b[i]) * t for i in range(7))
    return ST[0] if x > ST[0][0] else ST[-1]

GUNS = []
def gun(name, base, d, L, r):
    d = Vector(d).normalized(); GUNS.append((name, d)); hs_lib.barrel(name, base, d, L, r)

def tagged(r, since):
    for o in hs_lib.PARTS[since:]: o['role'] = r

def shells():
    """one continuous hull loft, like a generated hull: the break pieces are made by the shared break structure, not by the loft"""
    o = loft('hull', [sec(s) for s in reversed(ST)], bevel=0); hs_lib.PARTS.remove(o)
    bpy.context.view_layer.objects.active = o; o.select_set(True)
    m = o.modifiers.new('bv', 'BEVEL'); m.width = .003; m.segments = 2; m.limit_method = 'ANGLE'; m.angle_limit = math.radians(25)
    bpy.ops.object.modifier_apply(modifier='bv')
    sd = o.modifiers.new('sd', 'SUBSURF'); sd.subdivision_type = 'SIMPLE'; sd.levels = sd.render_levels = 2; bpy.ops.object.modifier_apply(modifier='sd')
    o.select_set(False); o['role'] = 'hull'; return [o]

def drum(nm, x, y, z, r, L):
    n0 = len(hs_lib.PARTS)
    cyl(nm, (x, y, z), r, L, axis='X', seg=28, bevel=.0015)
    for k, xx in enumerate((x - L * .3, x + L * .3)): cyl(f'{nm}band{k}', (xx, y, z), r * 1.04, L * .06, axis='X', seg=28, bevel=0)
    tagged('trim', n0 + 1)
    n1 = len(hs_lib.PARTS); cyl(f'{nm}bore', (x + L / 2 + .0005, y, z), r * .72, .002, axis='X', seg=24, bevel=0); tagged('dark', n1)
    for k, xx in enumerate((x - L * .3, x + L * .3)):  # cradle saddles down to the deck
        zt = at(xx)[2]; box(f'{nm}saddle{k}', (xx, y, (z - r * .6 + zt) / 2), (L * .10, r * 1.6, z - r * .6 - zt + .006), bevel=.001)

def parts():
    P = hs_lib.PARTS
    # forward glacis: a raised armoured block on the bow deck carrying the twin bow guns
    n0 = len(P); frustum('glacis', (.300, 0, at(.30)[2] - .004), (.095, .080), (.070, .062), .036, shear=(-.012, 0), bevel=.003)
    box('glacislip', (.300, 0, at(.30)[2] + .033), (.150, .128, .004), bevel=.001); tagged('trim', n0 + 1)
    for s in (1, -1):
        box(f'bowmount{s}', (.375, s * .032, at(.375)[2] + .040), (.026, .024, .020), bevel=.002)
        gun(f'bowgun{s}', (.385, s * .032, at(.375)[2] + .042), (1, 0, 0), .075, .0062)
    # casemates: two octagonal armour plates a side with a ball mount and twin barrels aimed forward and out
    for i, x in enumerate((.300, .175)):
        for s in (1, -1):
            wc = at(x)[3]; y = s * (wc + .003); z = .004
            n0 = len(P); cyl(f'cplate{i}{s}', (x, y, z), .040, .008, axis='Y', seg=8, bevel=.0015); tagged('trim', n0)
            cyl(f'cring{i}{s}', (x, y + s * .006, z), .026, .006, axis='Y', seg=24, bevel=.001)
            cyl(f'cball{i}{s}', (x, y + s * .014, z), .019, .016, axis='Y', seg=24, bevel=.004)
            d = Vector((.55, s * .83, .05))
            for k in (-1, 1): gun(f'cgun{i}{s}{k}', Vector((x, y + s * .016, z + k * .0075)), d, .062, .0048)
    # command tower with the sensor array that replaces the concept's lattice mast
    zt = at(.02)[2]; cyl('tower', (.020, 0, zt + .034), .046, .072, seg=32, bevel=.003)
    n0 = len(P); cyl('towerband', (.020, 0, zt + .060), .0475, .008, seg=32, bevel=0); tagged('trim', n0)
    box('bridge', (.032, 0, zt + .082), (.070, .074, .026), bevel=.003)
    n0 = len(P); box('bridgeglass', (.068, 0, zt + .085), (.004, .060, .008), bevel=.0005); tagged('dark', n0)
    import barge_shapes as B
    B.antenna_array(.020, 0, zt + .095, h=.085)
    # missile drums lying along the deck, launch ends forward: a pair ahead of the tower, a rack of three behind it, a pair aft
    for s in (1, -1): drum(f'fdrum{s}', .145, s * .046, at(.145)[2] + .024, .018, .064)
    for k, y in enumerate((-.052, 0, .052)): drum(f'mdrum{k}', -.085, y, at(-.085)[2] + .026, .021, .090)
    for s in (1, -1): drum(f'adrum{s}', -.300, s * .042, at(-.30)[2] + .022, .016, .060)
    # aft deck: radiators in place of the aft lattice mast, an intake grille, and the dark belly block under the mid hull
    B.radiator_pair(-.420, 0, at(-.42)[2], n=2, L=.070, H=.048)
    box('grille', (-.165, 0, at(-.19)[2] + .002), (.070, .090, .008), bevel=.001)
    n0 = len(P); [box(f'grilleslat{k}', (-.195 + k * .010, 0, at(-.19)[2] + .0065), (.004, .086, .003), bevel=0) for k in range(7)]; tagged('dark', n0)
    box('bellyblock', (-.060, 0, at(-.06)[6] - .014), (.270, .150, .036), bevel=.004)
    # armoured cargo containers on both flanks of the mid hull (the concept shows one side; a matched pair here)
    for s in (1, -1):
        wc = at(-.11)[3]; y = s * (wc + .028)
        box(f'cargo{s}', (-.115, y, -.060), (.172, .056, .066), bevel=.003)
        for k in range(7): box(f'cargorib{s}{k}', (-.190 + k * .025, y + s * .029, -.060), (.006, .004, .062), bevel=0)
        for xx in (-.170, -.060): box(f'cargoarm{s}{xx}', (xx, s * (wc + .001), -.055), (.020, .010, .030), bevel=.001)
    # stern: one big engine bell and two smaller ones, glow discs at the mouths, ventral thruster pods
    for nm, (y, z, r) in (('main', (0, -.025, .046)), ('portb', (.062, .022, .028)), ('stbdb', (-.062, .022, .028))):
        B.engine_bell((-.492, y, z), r, .050, axis_dir=Vector((-1, 0, 0)))
        n0 = len(P); cyl(f'glow{nm}', (-.530, y, z), r * .9, .002, axis='X', seg=28, bevel=0); tagged('glow', n0)
    for s in (1, -1):
        cyl(f'vthr{s}', (-.380, s * .055, at(-.38)[6] - .010), .016, .070, axis='X', seg=20, bevel=.002)
        box(f'vthrpylon{s}', (-.380, s * .055, at(-.38)[6] - .002), (.040, .010, .012), bevel=.001)
    # ventral sensor blister under the bow (replaces the concept's chin fin, which reads as a boat keel)
    box('vsensor', (.300, 0, at(.30)[6] - .010), (.110, .060, .022), bevel=.004)
    cyl('vdish', (.300, 0, at(.30)[6] - .024), .020, .006, seg=24, r2=.008, bevel=.001)

def modest_detail(S, hard):
    """rung 1 detail: fewer, bigger salvage plates (the round 5 lesson: busy small plating reads as clutter), a few vents and pipe runs"""
    import detail_lib as D, random
    Sf = D.Surface(S, hard); r = random.Random(209); base = lambda p: (.1, .04, .02); tag = lambda rgb: None
    big = [(.6, (.06, .10), (.035, .060)), (.4, (.035, .06), (.025, .040))]
    for s_ in (1, -1):
        D.scatter_plates(Sf, tag, lambda r_: Vector((r_.uniform(-.46, .44), s_ * .6, r_.uniform(-.015, .06))), Vector((0, -s_, 0)), lambda n: abs(n.y) > .5,
                         base, r, True, 16, big, th=.0026, kinds=(('rect', .45), ('chamfer', .35), ('slant', .20)), name=f'fl{s_}_')
    D.scatter_plates(Sf, tag, lambda r_: Vector((r_.uniform(-.46, .44), r_.uniform(-.12, .12), .5)), Vector((0, 0, -1)), lambda n: n.z > .6,
                     base, r, True, 18, big, th=.0026, kinds=(('rect', .4), ('chamfer', .35), ('trap', .25)), name='top')
    D.scatter_plates(Sf, tag, lambda r_: Vector((r_.uniform(-.46, .44), r_.uniform(-.10, .10), -.6)), Vector((0, 0, 1)), lambda n: n.z < -.6,
                     base, r, True, 10, big, th=.0030, kinds=(('rect', .5), ('chamfer', .5)), name='belly')
    for s_ in (1, -1):
        D.accents(Sf, tag, lambda r_: Vector((r_.uniform(-.44, .40), s_ * .6, r_.uniform(-.01, .05))), Vector((0, -s_, 0)), lambda n: abs(n.y) > .6, r, 8, name=f'acc{s_}_')

def build(out):
    t0 = time.time(); bpy.ops.wm.read_factory_settings(use_empty=True); hs_lib.PARTS.clear()
    S = shells(); parts()
    hard = [o for o in hs_lib.PARTS]
    for o in hard:
        if 'role' not in o: o['role'] = 'part'
    import detail_lib
    n0 = len(hs_lib.PARTS)
    modest_detail(S, [o for o in hard if not o.name.startswith('glow')])
    for o in hs_lib.PARTS[n0:]: o['role'] = 'part'
    for o in hs_lib.PARTS:  # apply bevels so the counts and the audit see the real geometry
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    allparts = list(hs_lib.PARTS)
    au = C.audit(S, [o for o in hard if not o.name.startswith('glow')], GUNS)
    made, notes = C.breakable(S)
    C.paint(S + allparts + made, S)
    rep = C.report(S + allparts + made)
    meta = dict(cell='A', route='hand build on AI massing underlay', build_seconds=round(time.time() - t0, 1), audit=au, break_fit=notes,
                hand_parts=len(hard), detail_parts=len(allparts) - len(hard), **rep)
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, 'A.blend'))
    json.dump(meta, open(os.path.join(out, 'A.json'), 'w'), indent=1); print('[209] A', json.dumps(meta)[:1500])

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    build(a[0])
