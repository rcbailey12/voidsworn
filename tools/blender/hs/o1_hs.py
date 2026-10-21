# Bake-off entry D: the defend-objective station (O1_37) as a scripted hard-surface model from the concept: stepped disc, hangars, docked spire.
import sys, math, bpy
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__))); from hs_lib import *
from mathutils import Matrix, Vector
out = sys.argv[1]; bpy.ops.wm.read_factory_settings(use_empty=True)
def polar(r, a, z): return (r * math.cos(a), r * math.sin(a), z)
cyl('base', (0, 0, -.04), 1.0, .08, seg=96, r2=.97, bevel=.008); cyl('under', (0, 0, -.11), .85, .07, seg=64, r2=.6, bevel=.006)
cyl('ring2', (0, 0, .03), .8, .06, seg=96, bevel=.006); cyl('ring3', (0, 0, .085), .56, .05, seg=96, bevel=.006)
cyl('well', (0, 0, .11), .4, .012, seg=72, bevel=.002)
for k in range(16):  # radial deck plates and the notched rim
    a = k * math.pi / 8 + math.pi / 16
    box(f'rad{k}', polar(.68, a, .07), (.2, .07, .022), rot=(0, 0, a), bevel=.003)
    box(f'rim{k}', polar(.985, a, -.005), (.06, .11, .05), rot=(0, 0, a), bevel=.004)
    box(f'light{k}', polar(.805, a + .1, .03), (.012, .09, .012), rot=(0, 0, a), bevel=.001)
for k in range(4):  # hangars on the four quarters, each with a dark bay
    a = k * math.pi / 2; c = polar(.88, a, .06)
    box(f'hang{k}', c, (.2, .24, .16), rot=(0, 0, a), bevel=.008); box(f'bay{k}', polar(.985, a, .05), (.02, .15, .09), rot=(0, 0, a), bevel=.002)
    box(f'hangroof{k}', polar(.86, a, .145), (.13, .18, .025), rot=(0, 0, a), bevel=.004)
    for s in (-1, 1): box(f'pyl{k}{s}', polar(.62, a + s * .2, .12), (.1, .05, .06), rot=(0, 0, a), bevel=.004)
for a in (math.pi * .75, -math.pi * .75):  # twin gun platforms
    c = Vector(polar(.86, a, .07)); box(f'gp{a}', c, (.16, .16, .1), rot=(0, 0, a), bevel=.006); cyl(f'gt{a}', c + Vector((0, 0, .07)), .05, .04, seg=24)
    d = Vector((math.cos(a + math.pi), math.sin(a + math.pi), .25)).normalized()
    for s in (-1, 1): barrel(f'gb{a}{s}', c + Vector((0, 0, .09)) + Vector((-math.sin(a), math.cos(a), 0)) * s * .02, -d, .22, .009)
for a in (math.pi * .25, -math.pi * .25): box(f'glow{a}', polar(.97, a, 0), (.08, .2, .05), rot=(0, 0, a), bevel=.004)
# the docked spearhead ship in the middle
def sec(x, w, h): return (x, [(0, h), (w, h * .35), (w * .6, 0), (0, -.01), (-w * .6, 0), (-w, h * .35)])
loft('spire', [sec(-.3, .07, .12), sec(-.1, .11, .16), sec(.15, .07, .12), sec(.32, .01, .05)], bevel=.004)
for k in range(5): box(f'spfin{k}', (-.22 + k * .1, 0, .12 + .16 - abs(k - 2) * .015), (.06, .012, .03), bevel=.001)
for s in (1, -1): box(f'clamp{s}', (0, s * .19, .14), (.14, .05, .05), bevel=.004)
greebles('g1', ((-.75, .75), (-.75, .75)), 90, lambda x, y: (.06 if .58 < math.hypot(x, y) < .8 else .11 if .42 < math.hypot(x, y) < .56 else -1), 7, size=(.015, .04))
o = finish('O1_hs')
import bmesh  # drop greebles that fell off the decks (z<0 marks a miss)
bm = bmesh.new(); bm.from_mesh(o.data); bm.to_mesh(o.data); bm.free()
print('faces', len(o.data.polygons)); bpy.ops.wm.save_as_mainfile(filepath=out)
