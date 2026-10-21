# Bake-off entry D: Warlord's Pyre-Barge (C19_51) rebuilt as a scripted hard-surface model from Ryan's concept art.
import sys, math, bpy
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__))); from hs_lib import *
from mathutils import Matrix, Vector
out = sys.argv[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
def sec(x, w, t, b):
    H = [(0, t + .012), (w * .82, t), (w, t - .035), (w, b + .08), (w * .62, b)]
    return (x, H + [(0, b - .005)] + [(-y, z) for (y, z) in reversed(H[1:])])
# hull: long armoured wedge, sharp prow (+X), flat deck, chamfered gunwales
loft('hull', [sec(-1.0, .23, .02, -.2), sec(-.82, .27, .03, -.25), sec(-.2, .285, .03, -.28), sec(.35, .265, .02, -.27), sec(.68, .19, 0, -.22), sec(.9, .08, -.02, -.15), sec(1.0, .012, -.03, -.09)], bevel=.008)
# keel: a darker stepped band under the hull
loft('keel', [sec(-.86, .16, -.2, -.31), sec(-.2, .19, -.22, -.34), sec(.45, .15, -.2, -.31), sec(.7, .08, -.17, -.25)], bevel=.006)
T = .03
# superstructure: a leaning armoured pyramid with a second tier and the bridge
frustum('tower', (-.1, 0, T), (.45, .245), (.31, .15), .27, shear=(-.05, 0), bevel=.01)
frustum('tier2', (-.16, 0, T + .27), (.25, .14), (.19, .105), .1, shear=(-.02, 0), bevel=.008)
box('bridge', (-.09, 0, T + .4), (.17, .19, .055), bevel=.006); box('bridgeWin', (-.002, 0, T + .405), (.012, .17, .016), bevel=.002)
for s in (1, -1):  # stepped armour slabs on both flanks of the tower
    for k in range(3):
        box(f'slab{s}{k}', (-.12 + k * .03, s * (.205 - k * .035), T + .06 + k * .075), (.5 - k * .09, .03, .075), rot=(s * -.34, 0, 0), bevel=.005)
    box(f'casemate{s}', (.16, s * .29, T - .08), (.34, .07, .15), bevel=.008); box(f'casemate2{s}', (.16, s * .33, T - .1), (.26, .03, .08), bevel=.004)
    vents(f'vent{s}', (.16, s * .366, T - .1), 8, .004, .05, .03)
    for k in range(5): box(f'port{s}{k}', (-.62 + k * .09, s * .272, T - .07), (.05, .012, .02), bevel=.002)  # hull hatches
    box(f'lgunh{s}', (-.48, s * .27, T + .03), (.1, .07, .07), bevel=.004); barrel(f'lgun{s}', (-.48, s * .27, T + .06), (.75, s * .05, .66), .36, .011)
# engines: a deep block with six thrusters and armoured cowls
box('engblock', (-.86, 0, -.08), (.28, .46, .24), bevel=.01)
for y in (-.12, .12):
    for z in (-.14, -.02):
        cyl(f'noz{y}{z}', (-1.04, y, z), .062, .1, axis='X', r2=.05, seg=24); cyl(f'nozb{y}{z}', (-1.09, y, z), .05, .01, axis='X', seg=24, bevel=0)
for s in (1, -1): box(f'cowl{s}', (-.9, s * .24, -.08), (.34, .05, .28), bevel=.008)
# rocket pod and twin tanks on the upper tower, a lattice mast
tubes('pod', (-.33, 0, T + .45), 4, 2, .022, .24, .05, Matrix.Rotation(-.12, 3, 'Y')); box('podframe', (-.33, 0, T + .43), (.2, .26, .04), bevel=.004)
for s in (1, -1): tank(f'tank{s}', (-.02, s * .085, T + .43), .033, .13)
cyl('mast', (.05, 0, T + .58), .011, .36, seg=12)
for k, (zz, w) in enumerate(((.5, .12), (.6, .09), (.68, .06))): box(f'yard{k}', (.05, 0, T + zz), (.01, w, .01), bevel=.001)
cyl('mast2', (.0, .03, T + .52), .007, .2, seg=10); cyl('mast3', (.09, -.03, T + .5), .006, .16, seg=10)
# fore deck: twin turret, drums, a prow mast, deck clutter
cyl('turret', (.46, 0, T + .025), .075, .05, seg=32); box('turreth', (.48, 0, T + .07), (.12, .1, .05), bevel=.006)
for s in (1, -1): barrel(f'tgun{s}', (.53, s * .026, T + .075), (1, 0, .06), .26, .011)
for k, y in enumerate((-.13, -.09, .11)): cyl(f'drum{k}', (.27, y, T + .022), .022, .07, axis='Y', seg=16)
cyl('prowmast', (.8, 0, T + .05), .009, .13, seg=10); cyl('prowtip', (.8, 0, T + .125), .016, .025, r2=.002, seg=10)
greebles('gf', ((.6, .86), (-.12, .12)), 22, lambda x, y: T - .02 * max(0, x - .6) / .3, 1)
greebles('gr', ((-.95, -.62), (-.2, .2)), 26, .04, 2)
greebles('gt', ((-.2, .02), (-.1, .1)), 12, T + .425, 3, size=(.01, .03))
# v2 detail: armour plate seams on the hull sides and deck, a recessed stripe band, ledges and a name plate on the tower
for s in (1, -1):
    for k in range(9):
        x0 = -.78 + k * .17
        if -.2 < x0 < .1: continue
        box(f'hplate{s}{k}', (x0, s * .287, -.05), (.15, .01, .1), bevel=.002)
    box(f'band{s}', (-.1, s * .286, -.17), (1.3, .008, .035), bevel=.002)
    for k in range(4): box(f'ledge{s}{k}', (-.12 - k * .012, s * (.232 - k * .028), T + .04 + k * .06), (.55 - k * .07, .02, .008), rot=(s * -.34, 0, 0), bevel=.001)
box('nameplate', (.21, 0, T + .1), (.012, .2, .09), rot=(0, -.45, 0), bevel=.003)
for k in range(6): box(f'deckplate{k}', (.4 + k * .075, 0, T + .004), (.065, .3 - k * .035, .006), bevel=.001)
for k in range(4): box(f'hatch{k}', (.62 + (k % 2) * .08, (k // 2 - .5) * .12, T + .006), (.04, .03, .008), bevel=.001)
vents('tvent', (-.38, 0, T + .3), 7, .12, .012, .025)
o = finish('C19_hs'); print('faces', len(o.data.polygons))
bpy.ops.wm.save_as_mainfile(filepath=out)
