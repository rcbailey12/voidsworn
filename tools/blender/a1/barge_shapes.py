# A1 step 1: Pyre-Barge (C19_51) silhouette options, clay only. No naval read anywhere (owner, Oct 24):
# no V keel or keel plate, no raked stem, no deck sheer, no crossbar mast, no smokestack funnels, no single "waterline" band.
# Frame matches c19_kit.py: x aft (bow at -x), y to port, z up, ship length about 1.0.
# Keeps the concept's identity masses: red sloped superstructure, bridge tier, rocket rack, side armour blocks, forward and side guns.
# usage: python3 barge_shapes.py OPTION out_prefix     (OPTION = A, B or C; needs the bpy module, or run inside Blender with -P)
import sys, os, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'hs'))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import loft, frustum, box, cyl, barrel, vents, greebles

# Measured v14 shell stations (c19_kit.py ST, aft of the bow seam): x, top z, top half-width, deck z, superstructure foot half-width, deck/chine half-width
ST = [(-.240, -.074, .080, -.085, .095, .122), (-.220, -.030, .040, -.085, .110, .150), (-.180, .016, .045, -.085, .135, .155),
      (-.140, .037, .046, -.085, .145, .162), (-.110, .056, .050, -.085, .150, .165), (-.060, .056, .050, -.085, .150, .165),
      (.000, .056, .052, -.085, .155, .165), (.060, .056, .052, -.080, .155, .165), (.080, .033, .065, -.076, .155, .165),
      (.110, .030, .076, -.075, .152, .160), (.165, .030, .076, -.075, .152, .160), (.190, .052, .066, -.075, .152, .160),
      (.280, .056, .064, -.075, .152, .160), (.300, .048, .052, -.078, .150, .158), (.345, -.064, .128, -.066, .134, .145),
      (.400, -.066, .110, -.068, .116, .122), (.460, -.064, .094, -.066, .097, .100), (.492, -.066, .080, -.068, .082, .084)]

def mirror(half, ztop, zbot):
    """half: (y, z) points down the port side, top to bottom. Returns a closed loop with a fixed point count."""
    return [(0, ztop)] + half + [(0, zbot)] + [(-y, z) for y, z in reversed(half)]

def lerp(a, b, t): return a + (b - a) * t

def bridge_and_rack(x_off=0.0, y_off=0.0, z_off=0.0):
    """The concept's two signature top masses, as clean clay blocks: the armoured bridge tier and the 2x7 rocket rack."""
    x0, x1, zb, zt = -.088 + x_off, .059 + x_off, .056 + z_off, .102 + z_off
    box('plinth', ((x0 + x1) / 2, y_off, zb + .002), (x1 - x0 + .028, .170, .014), bevel=.002)
    frustum('tier', ((x0 + x1) / 2, y_off, zb), ((x1 - x0) / 2, .056), ((x1 - x0) / 2 - .010, .050), zt - zb, shear=(.010, 0), bevel=.003)
    box('roof', ((x0 + x1) / 2 + .010, y_off, zt + .002), (x1 - x0 - .018, .098, .004), bevel=.001)
    box('windows', (x0 + .012, y_off, zb + .030), (.007, .090, .008), bevel=.001)  # sits in the sloped tier front (it floated in front of it)
    for s in (1, -1): cyl(f'drum{s}', (x0 + .010, y_off + s * .066, zb + .016), .012, .040, axis='X', seg=20)
    rx = .217 + x_off
    for row, z in enumerate((.113, .091)):
        for k in range(7): cyl(f'tube{row}{k}', (rx + (k - 3) * .0202, y_off, z + z_off), .0090, .085, axis='Y', seg=16, bevel=.0008)
    box('rackframe', (rx, y_off, .102 + z_off), (.150, .07, .006), bevel=.0015)
    for xe in (-.073, .073): box(f'rackcheek{xe}', (rx + xe, y_off, .102 + z_off), (.006, .088, .04), bevel=.0015)
    cyl('rackcolumn', (.202 + x_off, y_off, .066 + z_off), .028, .062, seg=28, bevel=.002)

def antenna_array(x, y, z0, h=.16, flip=False, seed=1):
    """Replaces the crossbar mast: a squat sensor tower (square, no yards) carrying dishes, a sensor head and whip rods of uneven height."""
    s = -1 if flip else 1
    box('ant_base', (x, y, z0 + s * .008), (.040, .040, .016), bevel=.002)
    box('ant_tower', (x, y, z0 + s * (.016 + h * .30)), (.016, .016, h * .60), bevel=.001)
    box('ant_head', (x, y, z0 + s * (.016 + h * .62)), (.030, .026, .022), bevel=.002)
    for k, (dx, dy, dz, r) in enumerate(((.000, .030, .45, .020), (.000, -.026, .30, .016))):
        R = Matrix.Rotation(math.radians(-60 if dy > 0 else 60), 3, 'X')
        cyl(f'dish{k}', (x + dx, y + dy, z0 + s * (.016 + h * dz)), r, .006, seg=24, r2=r * .35, rot=R, bevel=.001)
        box(f'dishstrut{k}', (x + dx, y + dy * .55, z0 + s * (.016 + h * dz)), (.004, abs(dy) * .9, .004), bevel=0)
    for k, (dx, dy, hh) in enumerate(((.010, .008, 1.0), (-.010, -.006, .78), (.006, -.012, .62), (-.008, .012, .50))):
        cyl(f'whip{k}', (x + dx, y + dy, z0 + s * (.016 + h * .62 + h * hh * .25)), .0018, h * hh * .5, seg=8, bevel=0)

def radiator_pair(x, y, z0, flip=False, splay=28, n=2, L=.075, H=.060):
    """Replaces the funnels: thin ribbed heat-radiator panels standing out from a root spine, splayed in a V."""
    s = -1 if flip else 1
    box('rad_spine', (x, y, z0 + s * .006), (L + .010, .014, .012), bevel=.001)
    for side in (1, -1):
        for k in range(n):
            R = Matrix.Rotation(math.radians(side * splay), 3, 'X')
            c = Vector((x + (k - (n - 1) / 2) * (L / n), y, z0)) + R @ Vector((0, 0, s * (H / 2 + .010))) + Vector((0, side * .010, 0))
            o = box(f'rad{side}{k}', c, (L / n - .004, .0035, H), rot=(math.radians(side * splay), 0, 0), bevel=.0008)
            for r_ in range(5):  # cooling ribs across the panel
                cr = Vector((x + (k - (n - 1) / 2) * (L / n), y, z0)) + R @ Vector((0, 0, s * (.016 + r_ * H / 5))) + Vector((0, side * .010, 0)) + R @ Vector((0, side * .003, 0))
                box(f'radrib{side}{k}{r_}', cr, (L / n - .006, .003, .0025), rot=(math.radians(side * splay), 0, 0), bevel=0)

def engine_bell(c, r, L, axis_dir=Vector((1, 0, 0))):
    d = axis_dir.normalized(); R = d.to_track_quat('X', 'Z').to_matrix()
    cyl('bellcollar', Vector(c), r * .75, L * .35, axis='X', seg=28, rot=R, bevel=.002)
    cyl('bell', Vector(c) + d * L * .55, r * .80, L * .75, axis='X', seg=32, r2=r, rot=R, bevel=.001)

def side_guns(pairs, outboard=.45, up=.35, L=.075, r=.0034):
    """Long guns on ball mounts, aimed forward-and-out (never back): pairs = [(x, y, z), ...] on the port side, mirrored."""
    for i, (x, y, z) in enumerate(pairs):
        for s in (1, -1):
            a = Vector((x, s * y, z)); d = Vector((-1, s * outboard, up)).normalized()
            cyl(f'gunplate{i}{s}', a - Vector((0, s * .004, 0)), .016, .004, axis='Y', seg=20, bevel=.0008)
            cyl(f'gunball{i}{s}', a, .0085, .010, seg=16, bevel=.002); barrel(f'gun{i}{s}', a, d, L, r)

def bow_guns(x, ys, z, L=.06):
    for i, y in enumerate(ys):
        a = Vector((x, y, z)); box(f'bowmount{i}', a + Vector((.006, 0, 0)), (.014, .018, .018), bevel=.002)
        barrel(f'bowgun{i}', a, Vector((-1, 0, 0)), L, .0045)

# ---------------- Option A: armoured slab ----------------
# Closest to v14. The superstructure, bridge, rack and side blocks stay where they are. The hull below the deck becomes a flat
# armoured belly with angled chines (no V keel), the deck runs flat to the bow (no sheer), and the bow is a blunt armoured
# wedge that tapers top and bottom to a flat nose plate (no raked stem). Mast and funnels become an antenna array and radiators.
def option_A():
    ZB = -.192  # flat belly
    secs = []
    for x, zt, wt, zf, wf, wc in ST:
        wb = wc * .72; wt = min(wt, wf - .002)
        half = [(wt, zt), (wf, zf + .001), (wc, zf), (wc, zf - .040), (wb + .030, ZB + .030), (wb, ZB)]
        secs.append((x, mirror(half, zt + .002, ZB)))
    bow = []
    for t in (0, .25, .5, .75, 1.0):  # stations from the superstructure front (-.24) to the nose plate (-.475)
        x = lerp(-.262, -.470, t); zt = -.082; wc = lerp(.120, .078, t); zb = lerp(ZB, -.168, t); wt = wc * .62
        half = [(wt, zt), (wc - .004, zt - .002), (wc, zt - .006), (wc, max(zt - .040, zb + .012)), (wc * .72 + .012, zb + .012), (wc * .72, zb)]
        bow.append((x, mirror(half, zt + .002, zb)))
    loft('hull', list(reversed(bow)) + secs, bevel=.002)
    box('noseplate', (-.474, 0, -.124), (.010, .150, .086), bevel=.003)
    box('glacis', (-.300, 0, -.068), (.090, .200, .030), rot=(0, .30, 0), bevel=.003)  # forward armour slab: the superstructure front reaches toward the nose
    bow_guns(-.480, (.040, -.040), -.110)
    for x0, x1, z0, z1 in ((-.235, -.120, -.150, -.070), (-.045, .085, -.180, -.090), (.135, .265, -.180, -.090)):  # side armour blocks
        for s in (1, -1): box(f'sideblock{x0}{s}', ((x0 + x1) / 2, s * .190, (z0 + z1) / 2), (x1 - x0, .050, z1 - z0), bevel=.003)
    bridge_and_rack()
    antenna_array(.032, 0, .104, h=.15)
    radiator_pair(.083, 0, .056, splay=32)
    side_guns([(-.050, .150, .010), (.245, .150, .010)])
    for k, x in enumerate((-.10, -.02, .06, .14, .22)):  # bolted belly slabs
        box(f'bellyslab{k}', (x, 0, ZB - .006), (.060, .14 - .02 * (k % 2), .010), bevel=.002)
    for k, y in enumerate((-.030, 0, .030)): cyl(f'ventral{k}', (.000, y, ZB - .020), .010, .026, seg=20, r2=.014, bevel=.001)  # ventral thruster pods
    box('engineblock', (.470, 0, -.110), (.060, .150, .090), bevel=.004)
    for k, (y, z, r) in enumerate(((.045, -.090, .028), (-.045, -.090, .028), (0, -.135, .024))): engine_bell((.505, y, z), r, .050)

# ---------------- Option B: salvage spine ----------------
# A Corsair build around a stolen spine. The red superstructure sits on an armoured octagonal spine; under it hang a stolen cargo
# section (port) and an oversized donor engine on a pylon (starboard). The bow is a blunt hammerhead block bolted on slightly off
# centre. Big radiator wings fan out aft. Deliberately asymmetric (art direction: "No Corsair hull is symmetrical").
def option_B():
    def oct_sec(x, w, h, zc):
        c = .38
        half = [(w * (1 - c), zc + h), (w, zc + h * (1 - c)), (w, zc - h * (1 - c)), (w * (1 - c), zc - h)]
        return (x, mirror(half, zc + h, zc - h))
    loft('spine', [oct_sec(x, w, h, -.095) for x, w, h in ((-.40, .085, .050), (-.20, .105, .060), (.20, .105, .060), (.42, .090, .055))], bevel=.003)
    sup = []
    for x, zt, wt, wb in ((-.20, -.030, .050, .100), (-.15, .040, .050, .135), (.10, .050, .060, .140), (.29, .050, .060, .135), (.33, -.010, .070, .115)):
        half = [(wt, zt), (wb, -.045), (wb, -.050)]; sup.append((x, mirror(half, zt + .002, -.050)))
    loft('superstructure', sup, bevel=.003)
    box('hammer', (-.430, .018, -.090), (.090, .300, .110), bevel=.006)  # stolen bow block, off centre
    for s, y in ((1, .150), (-1, -.112)): box(f'hammercheek{s}', (-.440, y + .018, -.090), (.070, .030, .130), rot=(0, 0, s * .12), bevel=.003)
    bow_guns(-.478, (.075, .030, -.020, -.065), -.090)
    for k in range(3): box(f'hamplate{k}', (-.420 + k * .025, .018 + (k - 1) * .04, -.032), (.028, .09, .010), rot=(0, 0, (k - 1) * .2), bevel=.002)
    loft('cargo', [(x, mirror([(.075, -.170), (.080, -.200), (.075, -.255)], -.165, -.260)) for x in (-.22, -.18, .10, .16)], bevel=.004)
    o = bpy.data.objects['cargo']; o.location.y = .070
    for x in (-.15, .05): box(f'cargopylon{x}', (x, .065, -.155), (.020, .030, .030), bevel=.002)
    for k in range(4): box(f'cargoband{k}', (-.18 + k * .09, .070, -.212), (.010, .165, .098), bevel=.001)
    cyl('donorpod', (.200, -.205, -.110), .055, .330, axis='X', seg=32, bevel=.004)
    box('donorpylon', (.180, -.135, -.105), (.120, .080, .030), bevel=.003)
    engine_bell((.375, -.205, -.110), .070, .070)
    cyl('donorintake', (.030, -.205, -.110), .045, .020, axis='X', seg=32, bevel=.002)
    engine_bell((.445, 0, -.095), .060, .070)  # main engine, centred
    engine_bell((.440, .065, -.060), .026, .040)  # small stolen thruster, port only
    for s, ang in ((1, 55), (-1, 68)):  # radiator wings: different splay port and starboard
        R = Matrix.Rotation(math.radians(s * ang), 3, 'X')
        for k in range(3):
            c = Vector((.215 + k * .062, 0, -.045)) + R @ Vector((0, 0, .175))
            box(f'wing{s}{k}', c, (.056, .004, .300), rot=(math.radians(s * ang), 0, 0), bevel=.001)
        box(f'wingroot{s}', (.277, s * .040, -.045), (.200, .030, .020), bevel=.002)
    bridge_and_rack(x_off=-.060, z_off=-.050)
    antenna_array(-.030, 0, .054, h=.14)
    for x0, x1 in ((-.13, -.03), (.02, .12)): box(f'sideblock{x0}', ((x0 + x1) / 2, .155, -.075), (x1 - x0, .040, .070), bevel=.003)  # port side armour, two blocks
    box('sideblockS', (-.05, -.150, -.070), (.130, .035, .060), rot=(0, .08, 0), bevel=.003)  # one mismatched block starboard
    side_guns([(-.100, .145, -.020)])
    greebles('spinejunk', ((-.35, .35), (-.08, .08)), 26, lambda x, y: -.160 if abs(y) < .07 else -.6, 7)

# ---------------- Option C: double-sided hulk ----------------
# Nothing reads "above the water". The hull is a flattened hexagon that is as deep below its midline as above, the bow is a
# diamond wedge pointing from the middle, and the superstructure on top is answered by an armoured ordnance block and a second
# antenna array underneath. The side armour blocks become engine nacelles at mid height. Radiator fins stand up and hang down aft.
def option_C():
    ZC = -.070
    def hexs(x, w, h, top_w=.50):
        half = [(w * top_w, ZC + h), (w, ZC), (w * top_w, ZC - h)]; return (x, mirror(half, ZC + h, ZC - h))
    stations = [(-.490, .006, .006), (-.380, .085, .040), (-.250, .140, .068), (-.100, .165, .080), (.200, .165, .080), (.380, .140, .070), (.470, .110, .060)]
    loft('hull', [hexs(*s) for s in stations], bevel=.003)
    sup = []
    for x, zt, wt, wb in ((-.200, ZC + .085, .050, .100), (-.130, .040, .050, .120), (.120, .046, .055, .125), (.300, .046, .055, .115), (.340, ZC + .085, .060, .090)):
        sup.append((x, mirror([(wt, zt), (wb, ZC + .078), (wb, ZC + .070)], zt + .002, ZC + .070)))
    loft('superstructure', sup, bevel=.003)
    bridge_and_rack(z_off=-.012)
    antenna_array(.032, 0, .092, h=.14)
    keel = []  # ventral ordnance block: the superstructure's answer underneath, shorter and blunter
    for x, zb, wb_, wt_ in ((-.120, ZC - .140, .045, .095), (-.070, ZC - .155, .055, .110), (.180, ZC - .155, .055, .110), (.250, ZC - .130, .050, .090)):
        keel.append((x, mirror([(wt_, ZC - .070), (wt_, ZC - .078), (wb_, zb)], ZC - .070, zb)))
    loft('ventral', keel, bevel=.003)
    for k in range(5): box(f'bayslat{k}', (-.050 + k * .045, 0, ZC - .158), (.030, .080, .006), bevel=.001)
    antenna_array(.215, 0, ZC - .132, h=.10, flip=True)
    for s in (1, -1):  # side nacelles in place of the side armour blocks
        box(f'pylon{s}', (.090, s * .175, ZC), (.140, .040, .022), bevel=.002)
        cyl(f'nacelle{s}', (.110, s * .215, ZC), .040, .300, axis='X', seg=28, bevel=.004)
        engine_bell((.270, s * .215, ZC), .045, .055)
        box(f'nacelleplate{s}', (.020, s * .215, ZC + .036), (.100, .040, .010), bevel=.002)
    radiator_pair(.390, 0, ZC + .060, splay=12, n=2, L=.080, H=.075)
    radiator_pair(.390, 0, ZC - .060, flip=True, splay=12, n=2, L=.080, H=.060)
    engine_bell((.480, 0, ZC + .022), .032, .050); engine_bell((.480, 0, ZC - .030), .032, .050)
    bow_guns(-.380, (.050, -.050), ZC, L=.055)
    side_guns([(-.140, .120, ZC + .045), (.235, .120, ZC + .048)], up=.25)
    box('donorplate', (-.180, .085, ZC + .045), (.090, .010, .050), rot=(.5, 0, .05), bevel=.002)  # one stolen plate, port bow (Corsair patchwork)

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    opt, pre = a[0].upper(), a[1]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    import clay; clay.setup_scene()
    {'A': option_A, 'B': option_B, 'C': option_C}[opt]()
    ship = hs_lib.finish('barge_' + opt)
    bpy.ops.wm.save_as_mainfile(filepath=pre + '.blend')
    print('tris', sum(len(p.vertices) - 2 for p in ship.data.polygons))
    print(clay.render_views(pre, views=('q', 'side', 'front', 'below', 'top')))
