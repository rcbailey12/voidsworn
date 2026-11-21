"""ithar_GV2: the Starling Shard, the Glasswright fighter wing craft (data.js fighter: cls 'Squadron', guns T; hp 20, sp 7).

Issue 1373 (R362, R370). Built to Ryan's Nov 16 pick V2d ("perfect"; contrib/muse/design/glasswright_family_2026_11/fighter.md):
two broad ribbons twisted tightly round a small double-lobed dart, the stained-glass skin unbroken from nose to stern, one
small warm pearl of light at the waist where the ribbons cross, a tiny cut lens at the nose for the shard gun, and a short
streamer of rigid glass at the stern. The Nov 20 Needle (ithar_GF1) was built without that pick; this sheet replaces it and
reuses its machinery (the shared Glasswright kit: pearl ribbons, silver edges, the glowing mosaic, cut stones). The kit look is
opaque pearl and lit mosaic (R337), so the concept's clear glass reads as pearl here. R254/R259 (no canopy, nothing jet-like) and
V2d's stained-glass canopy are reconciled by building no canopy at all: the pilot sits sealed inside the fore lobe under the
unbroken ribbon skin, so nothing reads as a cockpit bubble. Size 1.6 (scale.md Squadron row), +X bow.
  blender -b -P tools/blender/build_sheets/build.py -- ithar_GV2 OUT render
"""
import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location('ithar_GF1_for_GV2', Path(__file__).with_name('ithar_GF1.py'))
F = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(F)

CODE = 'ithar_GV2'
NAME = 'The Starling Shard, the Glasswright fighter wing craft (Ryan\'s V2d pick)'
FACTION = F.FACTION
CLASS = F.CLASS
LENGTH = 1.6   # a plain number: stage 6 reads it without running the sheet (ship.py sheet_length)
GAME = F.GAME
BEAUTY = 'contrib/muse/design/glasswright_family_2026_11/img/fighter_starling_v2d.webp'
CONCEPT_SHEET = BEAUTY
SHEET = dict(F.SHEET, version=1, round='first sheet (Ryan\'s Nov 16 V2d pick)', date='2026-11-20',
             blend_where='built in the issue 1373 cloud thread (Blender 4.5 bpy wheel, Cycles CPU); `build.py ithar_GV2 <out> render` rebuilds it from this file',
             before='V2d concept', before_note='The Starling Shard as Ryan picked it on Nov 16, built from the Glasswright kit.')
CAMERA = F.CAMERA
U = F.U
TAU = F.TAU

# ---------------- the double-lobed dart: a small rear lobe, a pinched waist, the big fore lobe, a needle nose ----------------
F.CODE = CODE
F.X0, F.X1 = U(-0.31), U(0.43)        # the body; the stern streamers run on to -0.5, the nose needle to +0.5
F.HW, F.HH = 0.150 * LENGTH, 0.130 * LENGTH
REAR, FORE = (0.24, 0.12, 0.58), (0.64, 0.17, 1.0)   # (centre, width, height) of the two lobes along the body (0 stern, 1 bow)
WAIST_T = 0.43


def env(t):
    e = REAR[2] * math.exp(-((t - REAR[0]) / REAR[1]) ** 2) + FORE[2] * math.exp(-((t - FORE[0]) / FORE[1]) ** 2)
    if t < 0.12:
        e = max(e, 0.16 * (1 - t / 0.12) + e * t / 0.12)   # a small round stern cap for the drive stone
    return min(1.0, e)


def core(x, a, inset=0.0):
    """the dart: two lobes on one axis. a: 0 port beam, pi/2 top"""
    t = (x - F.X0) / (F.X1 - F.X0)
    if t < 0.0 or t > 1.0:
        return (min(F.X1, max(F.X0, x)), 0.0, 0.0)
    e = env(t)
    w = max(0.0, F.HW * e - inset)
    h = max(0.0, F.HH * e - inset)
    return (x, w * math.cos(a), h * math.sin(a))


F.core = core
F.NRIB = 4
F.HALF = 0.42
F.TWIST = lambda x: 2.6 * (x - F.X0) / LENGTH * TAU / 2.0   # two ribbons wound tightly, about one and a half turns nose to stern
F.MOSAIC_GRID = (110, 64)    # four gaps of four thin streaks each (kit MIX 'streaks', Ryan Nov 20 7:48 PM CT)
F.CORE_NOTE = 'a small double-lobed dart: a rear lobe, a pinched waist, a big fore lobe and a needle nose (V2d)'
F.STONES = [(0.0, 'c')]
F.STONE_RING = (0.0, 0.0)
F.STONE_X = -0.31 - 0.004
F.STONE_R = 0.012
F.ROOMS = [('pilot', 'crew', 0.12, 0.26, 0.03, 0.03, 0.04, 'the pilot in the fore lobe, the canopy section fused shut (V2d)'),
           ('light_core', 'core', -0.06, 0.02, 0.015, 0.015, 0.015, 'the warm pearl of light at the waist where the ribbons cross'),
           ('drive_well', 'engroom', -0.26, -0.16, 0.025, 0.02, 0.02, 'the light well behind the stern stone')]
F.BREAK_X = -0.05
F.CORE_PT = 0.10
F.CREST = 0.022   # clear of the ribbons' lift on the crown
F.GX = U(0.20)   # the shard lens on the crown of the fore lobe, where it sees all round (the arc check); V2d's nose point is the needle


def build(K):
    from mathutils import Vector
    F.body(K)
    F.gun_optic(K)
    # ---------------- the needle nose: a fine pearl spike from the fore lobe's point ----------------
    n0, n1 = F.X1 - U(0.03), U(0.5)
    pts = [(n0 + (n1 - n0) * i / 8, 0.0, 0.0) for i in range(9)]
    K._obj(CODE + '_nose_needle', *F.tube_mesh(pts, [U(0.006) * (1 - 0.85 * i / 8) for i in range(9)], 8), 'gw_pearl', smooth=True, grp='hull')
    # ---------------- the warm pearl of light at the waist, where the ribbons cross ----------------
    xw = F.X0 + (F.X1 - F.X0) * WAIST_T
    zw = core(xw, math.pi / 2)[2]
    K._obj(CODE + '_waist_pearl', *F.ellipsoid((xw, 0.0, zw), (U(0.012), U(0.012), U(0.010)), 16, 8), 'gw_gem_amber', smooth=True, grp='hull')
    # ---------------- the stern streamer: three fine rods of rigid glass trailing from the stern lobe ----------------
    for k, (ang, spread) in enumerate(((0.4, 0.035), (2.5, 0.045), (4.6, 0.03))):
        x_start = F.X0 + U(0.05)
        r0 = core(x_start, ang)
        pts = []
        for i in range(13):
            s = i / 12
            x = x_start + (U(-0.5) - x_start) * s
            rad = max(U(0.022), math.hypot(r0[1], r0[2]) * 0.8) + U(spread) * s ** 1.4
            wob = 0.25 * math.sin(math.pi * s * 1.5 + k)
            pts.append((x, rad * math.cos(ang + wob), rad * math.sin(ang + wob)))
        K._obj('%s_streamer_%d' % (CODE, k), *F.tube_mesh(pts, [U(0.004) * (1 - 0.7 * i / 12) for i in range(13)], 6), 'gw_pearl', smooth=True, grp='hull')
    K.colour('a warm amber pearl of light at the waist; pearl nose needle and stern streamers', U(0.5), U(-0.5), 'V2d')
    K.change('Built to Ryan\'s V2d pick: four ribbons (two pairs) wound tightly round a double-lobed dart, a warm pearl of light at the waist, a lens at the nose, a glass streamer at the stern',
             'Ryan, Nov 16 2026: V2d "perfect" (fighter.md); the Nov 20 Needle missed that pick (dropped-work audit)')
    K.change('The concept\'s clear glass reads as opaque pearl over the lit mosaic', 'R337: the Glasswright kit look is opaque reflective pearl and glowing mosaic, nothing see-through')
