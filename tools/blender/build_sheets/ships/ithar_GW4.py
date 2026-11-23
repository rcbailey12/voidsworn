"""ithar_GW4: the Heliograph Prism, the Glasswright bomber wing craft (data.js bomber: cls 'Squadron', bombs T; hp 28, sp 5).

Issue 1373 (R362, R370). Built to Ryan's Nov 16 pick W4b (contrib/muse/design/glasswright_family_2026_11/bomber.md): two plump
lobes fused side by side, the same size and shape, fully closed (no holes, bays or portholes); stained panes in amber, violet
and green between silver veins; the seam between the lobes glowing seafoam; two star torpedoes carried visibly at the front
underside with their star heads forward and glowing amber; a soft bloom at the stern where the lobes taper together.
R254 and R259 (craft must not read as jets or carry slung stores; Nov 14 and 15) and W4b's slung torpedoes (Nov 16) are reconciled by nesting each torpedo in the
belly seam between the lobes: carried in sight, never hanging below the hull's lowest line. W4b's prism gun is left out: the
data.js bomber has bombs only, and a gun with no data.js slot fails the weapon match. The Nov 20 Needle bomber (ithar_GB1) was
built without the W4b pick; this sheet replaces it on the shared Glasswright kit (via ithar_GF1's machinery). Size 1.6, +X bow.
  blender -b -P tools/blender/build_sheets/build.py -- ithar_GW4 OUT render
"""
import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location('ithar_GF1_for_GW4', Path(__file__).with_name('ithar_GF1.py'))
F = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(F)

CODE = 'ithar_GW4'
NAME = 'The Heliograph Prism, the Glasswright bomber wing craft (Ryan\'s W4b pick)'
FACTION = F.FACTION
CLASS = F.CLASS
LENGTH = 1.6   # a plain number: stage 6 reads it without running the sheet (ship.py sheet_length)
GAME = "data.js bomber (cls 'Squadron'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = 'contrib/muse/design/glasswright_family_2026_11/img/bomber_heliograph_w4b.webp'
CONCEPT_SHEET = BEAUTY
SHEET = dict(F.SHEET, version=1, round='first sheet (Ryan\'s Nov 16 W4b pick)', date='2026-11-20',
             blend_where='built in the issue 1373 cloud thread (Blender 4.5 bpy wheel, Cycles CPU); `build.py ithar_GW4 <out> render` rebuilds it from this file',
             before='W4b concept', before_note='The Heliograph Prism as Ryan picked it on Nov 16, built from the Glasswright kit.')
CAMERA = F.CAMERA
U = F.U
TAU = F.TAU

F.CODE = CODE
F.X0, F.X1 = U(-0.42), U(0.40)       # the twin lobes; the torpedo heads run on to the bow line
R_LOBE, C_LOBE = 1.0, 0.80           # each lobe's section radius and its centre's offset from the axis (shares of HW)
F.HW, F.HH = 0.38 * LENGTH, 0.32 * LENGTH   # plump: each lobe about 1.6 times as long as it is round (W4b)


def env(t):
    """plump lobes: full through the middle, rounding to the bow, tapering together at the stern"""
    e = math.sin(math.pi * min(1.0, max(0.0, t)) ** 1.05) ** (0.38 if t > 0.5 else 0.5)
    return max(e, 0.10 if t < 0.5 else 0.0)


def core(x, a, inset=0.0):
    """the fused twin lobes: in section two circles side by side, a groove top and bottom where they meet. a: 0 port beam"""
    t = (x - F.X0) / (F.X1 - F.X0)
    if t < 0.0 or t > 1.0:
        return (min(F.X1, max(F.X0, x)), 0.0, 0.0)
    e = env(t)
    c, R = C_LOBE * e ** 0.5, R_LOBE * e          # the lobe centres stay apart toward the ends, so each lobe rounds off to its own nose
    ca, sa = math.cos(a), math.sin(a)
    d = c * abs(ca) + math.sqrt(max(0.0, R * R - (c * sa) ** 2))
    k = d / (C_LOBE + R_LOBE)                 # 1 at the beam's widest
    w = max(0.0, F.HW * k - inset)
    h = max(0.0, F.HH * k / 0.95 - inset)
    return (x, w * ca, h * sa)


F.core = core


def belly_z(x, y):
    """the underside of the lobes at beam offset y (world units): where a torpedo can nest in the belly seam"""
    t = (x - F.X0) / (F.X1 - F.X0)
    e = env(t)
    cy = F.HW * C_LOBE / (C_LOBE + R_LOBE) * e ** 0.5
    ry = F.HW * R_LOBE / (C_LOBE + R_LOBE) * e
    rz = F.HH * R_LOBE / (C_LOBE + R_LOBE) / 0.95 * e
    q = min(1.0, ((y - cy) / ry) ** 2)
    return -rz * math.sqrt(1.0 - q)


def lowest_z(x):
    """the lobes' lowest line at station x"""
    t = (x - F.X0) / (F.X1 - F.X0)
    return belly_z(x, F.HW * C_LOBE / (C_LOBE + R_LOBE) * env(t) ** 0.5)
F.NRIB = 10
F.HALF = 0.22    # R431 (Ryan Nov 23, I8_37 look everywhere): broad pearl bands, the stained panes show in the seams between them
F.TWIST = lambda x: -0.4                   # straight meridian veins bow to stern; -0.4 sets them at 0, 36, 72.. degrees so the grooves (90, 270) stay open
# F.MOSAIC_WEIGHTS: the kit's four-colour weights (issue 1415, Ryan Nov 21 1:45 PM CT: less red and amber, more blue, green and
# purple); the Nov 20 three-colour override would have dropped blue from the marble.
F.MOSAIC_KW = dict(streak=True)   # Ryan, Nov 20 7:07 PM CT: "random lights rather than integrated"; evenly lit panes with a thin dark rim (kit, issue 1415)
_gaps0 = F.gaps


def gaps(x, a, ribs):
    """long panes along the flow (issue 1415's streak style): each bay runs a little longer bow to stern than the kit's, so
    a pane between two veins reads as one long streak of stained glass"""
    r = _gaps0(x, a, ribs)
    return (r[0], r[1] * 0.8) + tuple(r[2:])


F.gaps = gaps
F.MOSAIC_GRID = (160, 240)   # ten gaps of four thin streaks each round the twin lobes (kit MIX 'streaks', Ryan Nov 20 7:48 PM CT)
F.CORE_NOTE = 'two plump lobes fused side by side, the same size and shape, fully closed; a groove top and bottom where they meet (W4b)'
F.STONES = [(0.0, 'c')]
F.STONE_RING = (0.0, 0.0)
F.STONE_X = -0.42 - 0.004
F.STONE_R = 0.016
F.ROOMS = [('pilot', 'crew', 0.12, 0.26, 0.04, 0.04, 0.05, 'the pilot between the lobes at the front'),
           ('light_core', 'core', -0.15, 0.08, 0.05, 0.05, 0.05, 'the light core that lights the seam'),
           ('drive_well', 'engroom', -0.40, -0.25, 0.03, 0.03, 0.03, 'the light well behind the stern bloom')]
F.BREAK_X = -0.2
F.CORE_PT = 0.0
TORP_X0, TORP_X1 = 0.06, 0.50          # the torpedoes' tail and star-head stations (shares of LENGTH)


def build(K):
    from mathutils import Vector
    F.body(K)
    P = F.gw_kit('parts')
    # ---------------- the seam: a seafoam glow along the groove where the lobes meet, top and bottom ----------------
    for side, nm in ((1, 'top'), (-1, 'belly')):
        pts = [core(F.X0 + (F.X1 - F.X0) * i / 40, side * math.pi / 2, inset=U(0.004)) for i in range(4, 37)]
        K._obj('%s_seam_%s' % (CODE, nm), *F.tube_mesh(pts, [U(0.012)] * len(pts), 8), 'gw_gem_green', smooth=True, grp='hull')
    # ---------------- two star torpedoes nested in the belly seam, star heads forward (bombs T, 2 shots) ----------------
    apertures = []
    for side, sn in ((1, 'p'), (-1, 's')):
        fid = 'BT' + sn
        r = U(0.040)
        y = side * U(0.07)
        zc = lowest_z(U(0.2)) + r                     # sunk into the V of the belly seam: its underside on the lobes' lowest line, never below
        body_pts = [(U(TORP_X0) + (U(TORP_X1 - 0.03) - U(TORP_X0)) * i / 10, y, zc) for i in range(11)]
        K._obj(fid + '_casing', *F.tube_mesh(body_pts, [r * min(1.0, 0.45 + 0.55 * i / 3) for i in range(11)], 10), 'gw_pearl', smooth=True, grp=fid)
        K._obj(fid + '_cradle', *F.ellipsoid((U(0.22), y, zc + U(0.006)), (U(0.17), r * 1.2, r * 1.05), 16, 8), 'gw_silver', smooth=True, grp=fid)
        head = Vector((U(TORP_X1 - 0.03), y, zc))
        K._obj(fid + '_star', *F.ellipsoid(tuple(head), (U(0.035), r * 1.1, r * 1.1), 12, 6), 'gw_gem_amber', smooth=True, grp=fid)
        for j in range(6):
            an = j * TAU / 6
            d = Vector((0.55, math.cos(an), math.sin(an))).normalized()
            tip = head + d * U(0.05)
            K._obj('%s_spike%d' % (fid, j), *F.tube_mesh([tuple(head), tuple(tip)], [U(0.009), U(0.0015)], 5), 'gw_gem_amber', smooth=True, grp=fid)
        K._obj(fid + '_point', *P.cut_lens(tuple(head + Vector((U(0.032), 0, 0))), (1, 0, 0), r * 0.55, r * 0.5, 8), 'gw_gem_amber', grp=fid)
        for o in K.coll.objects:
            if o.get('grp') == fid:
                o['part_kind'] = 'launcher'; o['machine'] = 1
                o['grp'] = 'BT'
        apertures.append(dict(pos=tuple(head + Vector((U(0.03), 0, 0))), dir=(1.0, 0.0, 0.0), r=r, length=LENGTH * 0.8, cone=4.0, what='star torpedo head'))
    cv = sum((Vector(a_['pos']) for a_ in apertures), Vector()) / 2
    lane = dict(apex=tuple(cv), dir=(1, 0, 0), u=(0, 1, 0), w=(0, 0, 1), hu=U(0.07), hw=U(0.04), half=4.0, length=LENGTH * 0.8, what='firing lane')
    K.fitdata.append(dict(id='BT', kind='launcher', slot='T', lanes=[lane], apertures=apertures))
    K.features.append(dict(id='BT', kind='launcher', what='two star torpedoes nested in the belly seam, star heads forward', count=2, pos=tuple(cv),
                           aim=(0.0, 0.0), slot='T', weapon='bombs', src='picture', inv=['star_torpedoes'],
                           note='the bomb payload (data.js bombs T, 2 shots): W4b\'s two star torpedoes, both every volley; the craft turns onto its target'))
    K.built.append(dict(id='BT', kind='launcher', type='bomb_tube', inv=['star_torpedoes'], shaped=True, detailed=True, subs=['pearl casing', 'silver cradle', 'amber star head']))
    K.colour('seafoam glow along the seam between the lobes; amber star heads', U(0.45), U(-0.47), 'W4b')
    K.change('Built to Ryan\'s W4b pick: two plump lobes fused side by side, fully closed, a seafoam seam, two star torpedoes with amber star heads forward',
             'Ryan, Nov 16 2026: W4b (bomber.md); the Nov 20 Needle bomber missed that pick (dropped-work audit)')
    K.change('The torpedoes sit nested in the belly seam between the lobes, not slung below the hull', 'R254, R259: nothing slung under a hull; W4b: carried visibly, never a bay')
    K.change('No prism gun', 'the data.js bomber carries bombs only; a gun with no data.js slot fails the weapon match (R241)')
    K.change('The concept\'s clear glass reads as opaque pearl over the lit mosaic', 'R337: the Glasswright kit look is opaque reflective pearl and glowing mosaic, nothing see-through')
