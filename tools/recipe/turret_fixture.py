# Issue 560: the turret test ship. A small Hullbreaker test hull (not production art) carrying the recipe kit's own turret parts
# (tools/blender/kits/hullbreakers/kit.py turret(), the same function the C15s_23 cruiser was built with), fixed casemate
# barrels and a bow tube, exported through the real stage 7 script (export7.py, unbaked=1: geometry and hard points, no maps).
# The two turrets are marked by the two routes a kit can use (tools/blender/kits/shared/turrets.py):
#   turA   marked in the blend while it is built, the build-sheet way (an empty turA_turret with its own arc, -120 to +120:
#          a kit's own narrower arc, so the game check can prove a target astern clamps to the arc edge);
#   turB   left unmarked, so stage 7 marks it from the kit's TURRET_TURN list (the route the already-built C15s_23 takes);
#          a block (a sensor mast) stands on the deck beside it to port, so the game check can prove a turret never trains
#          its barrel into its own ship.
# The written folder is the game check's fixture: godot/render/test/fixtures/T560_fx/ (godot/render/test/turret_check.gd).
#   blender -b -P tools/recipe/turret_fixture.py -- OUT_DIR [exporter=PATH]     (or python with the bpy module, same arguments)
#   exporter=PATH runs another copy of export7.py on the same scene (the proof that the export before issue 560 merged the turrets
#   and the check refuses it: git show <commit>:tools/recipe/export7.py into a file, then pass it here)
import os, sys, json, math, random, runpy
import bpy
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
for p in ('tools/blender/kits/shared', 'tools/blender/kits/hullbreakers', 'tools/blender/hs'):
    sys.path.insert(0, os.path.join(REPO, p))
import plumbing as PB, hs_lib, kit as HB, turrets as TUR

ARGS = sys.argv[sys.argv.index('--') + 1:]
OUT = ARGS[0]; EXPORTER = dict(a.split('=', 1) for a in ARGS[1:] if '=' in a).get('exporter', os.path.join(HERE, 'export7.py'))
SHIPJ = os.path.join(HERE, 'ships', '_turret_fixture.json')
ship = json.load(open(SHIPJ))

# a clean scene
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene
hs_lib.PARTS.clear(); PB.clear_registry()

# the hull: a lofted octagonal section, bow at +X, deck at z 0.03, length 1 (ship units)
def sec(x, hw, zb, zt, ch=.025):
    return (x, [(-hw + ch, zb), (hw - ch, zb), (hw, zb + ch), (hw, zt - ch), (hw - ch, zt), (-hw + ch, zt), (-hw, zt - ch), (-hw, zb + ch)])
hull = hs_lib.loft('hull', [sec(-.5, .075, -.055, .028), sec(-.2, .09, -.06, .03), sec(.2, .09, -.06, .03), sec(.42, .06, -.045, .024, .02),
                            sec(.5, .025, -.02, .012, .008)], bevel=0)
hull['role'] = 'hull'
# authored insides (stage 7 requires them, issue 557): a deck box inside the hull
inside = hs_lib.box('room_deck', (0, 0, -.02), (.7, .1, .05), bevel=0); inside['role'] = 'interior'
sc['r209_t_lines'] = [-.15, .18]

seat = PB.Seat([hull])
sockets = PB.resolve(PB.sockets_from(SHIPJ), seat)
by = {s.name: s for s in sockets}

# fixed guns: one casemate barrel a side (slot 0 port, slot 1 starboard) and a bow tube (slot 2): never turrets
for s in sockets:
    if s.part == 'turret': continue
    i0 = PB.mark()
    if s.part == 'casemate':
        base = s.pos + s.normal * .004
        hs_lib.cyl(f'{s.name}box', base, .012, .012, axis='X', seg=8, rot=PB.frame(s.normal), bevel=0)
        tip = base + s.aim * .05
        hs_lib.cyl(f'{s.name}brl', (base + tip) / 2, .0035, .05, axis='X', seg=10, rot=PB.frame(s.aim), bevel=0)
        PB.register_gun(f'{s.name}brl', s.aim, s.normal, tip=tip, socket=s.name, radius=.0035)
    else:   # bow tube
        tip = s.pos + Vector((.004, 0, 0))
        hs_lib.cyl(f'{s.name}tube', s.pos - Vector((.01, 0, 0)), .008, .028, axis='X', seg=12, bevel=0)
        PB.register_gun(f'{s.name}tube', (1, 0, 0), (1, 0, 0), tip=tip, socket=s.name, radius=.008)
    PB.tag(i0, 'part', 'gun')

# the turrets: the recipe kit's own turret part, at the ship json's sockets
for name in ('turA', 'turB'):
    HB.turret(by[name], seat, random.Random(f'560:{name}'))

# turA is marked the build-sheet way, here in the blend, with a narrower arc of its own
ring = sc.objects['turAring']
w = [ring.matrix_world @ Vector(b) for b in ring.bound_box]
top = Vector(((min(v.x for v in w) + max(v.x for v in w)) / 2, (min(v.y for v in w) + max(v.y for v in w)) / 2, max(v.z for v in w)))
piv = bpy.data.objects.new('turA_turret', None); sc.collection.objects.link(piv)
piv.matrix_world = TUR._frame(top, (1, 0, 0), (0, 0, 1))
for k, v in dict(turret=1, slot=3, weapon='flak', arc_lo=-120.0, arc_hi=120.0, rest_yaw=0.0, rest_pitch=14.0, socket='turA').items(): piv[k] = v
bpy.context.view_layer.update()
for o in [o for o in sc.objects if o.type == 'MESH' and o.name.startswith('turA') and not o.name.startswith(('turAring', 'turAweld'))]:
    mw = o.matrix_world.copy(); o.parent = piv; o.matrix_parent_inverse = piv.matrix_world.inverted(); o.matrix_world = mw

# the sensor mast beside turB, to port: turB cannot train its barrel through it
zt = seat.top(by['turB'].pos.x, .045) or .03
mast = hs_lib.box('mast', (by['turB'].pos.x + .002, .045, zt + .02), (.016, .014, .04), bevel=0); mast['role'] = 'part'; mast['kind'] = 'gun_dark'

# an engine
hs_lib.cyl('eng0', (-.505, 0, -.01), .03, .02, axis='X', seg=16, bevel=0)['role'] = 'part'
PB.register_engine('eng0', (-.515, 0, -.01), (-1, 0, 0), .03)
sc['r209_hp'] = json.dumps(PB.hardpoint_data(sockets))
bpy.context.view_layer.update()

# stage 7, the real script
os.makedirs(OUT, exist_ok=True)
sys.argv = [sys.argv[0], '--', SHIPJ, OUT, 'unbaked=1']
try:
    runpy.run_path(EXPORTER, run_name='__main__', init_globals=dict(__file__=os.path.join(HERE, 'export7.py')))
except SystemExit as e:
    if e.code not in (None, 0): raise
print('[turret_fixture] written', OUT)
