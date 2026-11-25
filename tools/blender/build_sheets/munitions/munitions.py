# Issue 1379 run 2 (R362, docs/playbooks/ships.md section 9): torpedoes and rockets are built from the faction part kits and take
# the hull finish. This file builds every munition body from the kits' own parts (tools/blender/kits/<faction>/parts.py), with the
# kits' material rows, at game size: the code casing it replaces (godot/fx/fx_weapons.gd _casing) is 2.3 long (x -1.15 to 1.15),
# radius 0.29, +X the nose, +Y left, +Z up. The game scales it like the old casing (k x unit, rockets x 0.55).
# Who fires what (data.js): Sunward torp (harrow), Hullbreaker torp and htorp (their rockets trait: four small rockets a volley).
# The Glasswright star torpedo is a glowing effect and stays one (ships.md section 9). No other faction fires torpedoes.
# Run: V/bin/python tools/blender/build_sheets/munitions/munitions.py [out dir] [export|flat|review]   (bpy 4.5 wheel, cloud or PC)
# With no arguments it writes the picked bodies to godot/fx/munition_bodies/<faction>_<look>.glb, which the game loads.
import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..'))
KITS = os.path.join(REPO, 'tools', 'blender', 'kits')
sys.path.insert(0, os.path.join(KITS, 'shared'))
import bpy  # noqa: E402,F401  (the bpy wheel provides mathutils)
from mathutils import Vector, Matrix  # noqa: E402
from geom import Part, revolve, block, moved, ring_band  # noqa: E402

L = 2.3          # the old casing's length
X0, X1 = -1.15, 1.15


def kit(name, fn='parts.py'):
    sp = importlib.util.spec_from_file_location('mun_%s_%s' % (name, fn[:-3]), os.path.join(KITS, name, fn))
    m = importlib.util.module_from_spec(sp); sp.loader.exec_module(m)
    return m


VS = kit('voidsworn')
HB = kit('hullbreakers')
HBC = kit('hullbreakers', 'craft.py')
CH = kit('chorus')

# the sheet kit's shared rows (tools/blender/build_sheets/kit.py MATS) the munitions use, plus each kit's own rows
BASE_MATS = {
    'soot': ((0.055, 0.050, 0.048), 0), 'rust': ((0.22, 0.09, 0.055), 0), 'iron': ((0.10, 0.10, 0.105), 0),
    'steel': ((0.20, 0.20, 0.21), 0), 'dark': ((0.012, 0.011, 0.011), 0), 'glow': ((1.0, 0.25, 0.08), 8),
    'ember': ((0.9, 0.22, 0.06), 1.6), 'warhead': ((0.42, 0.12, 0.06), 0), 'brass': ((0.42, 0.30, 0.12), 0),
    'blood': ((0.33, 0.05, 0.05), 0),
}
MATS = dict(BASE_MATS)
MATS.update(VS.MATS)
MATS['oath'] = ((0.62, 0.65, 0.68), 0)   # the frost-white oath band as paint (Sunward markings), not a light
METAL = ('steel', 'iron', 'brass', 'sworn')
# the Chorus rows the bone bolt uses (the sheet kit's rows, tools/blender/build_sheets/kit.py MATS); the stack names the zones
MATS.update({
    'scar': ((0.17, 0.125, 0.07), 0), 'chitin': ((0.25, 0.15, 0.045), 0), 'bone': ((0.55, 0.45, 0.27), 0),
    'tissue': ((0.13, 0.075, 0.035), 0), 'pore': ((0.012, 0.010, 0.005), 0), 'pit': ((0.010, 0.007, 0.004), 0),
    'veilroot': ((0.45, 0.68, 0.06), 1.0), 'carapace': ((0.17, 0.122, 0.074), 0), 'flesh': ((0.068, 0.056, 0.029), 0), 'maw': ((0.022, 0.014, 0.008), 0),
})


def _move(p, M):
    for c in p.comps:
        c['verts'] = [M @ v for v in c['verts']]
    return p


def _on_surface(p, tag, part, x, a, rad, mats=None):
    """place a kit part built local +Z out (vent, slit, lamp, hatch) on the body's surface at station x, angle a round the X
    axis (0 = +Y, pi/2 = +Z), radius rad"""
    nv = Vector((0, math.cos(a), math.sin(a)))
    M = Matrix.Translation(Vector((x, 0, 0)) + nv * rad) @ Matrix(((1, 0, 0), (0, -nv.z, nv.y), (0, nv.y, nv.z))).to_4x4()
    for c in part.comps:
        p.add('%s_%s' % (tag, c['name']), 'body', (mats or {}).get(c['mat'], c['mat']), ([M @ Vector(q) for q in c['verts']], c['faces']))


def _scaled(part, k):
    for c in part.comps:
        c['verts'] = [Vector(q) * k for q in c['verts']]
    return part


def _fin(x0, x1, a, r0, h, t, sweep=0.6):
    """a flat stabiliser blade standing out of the body at angle a: root x0..x1 at radius r0, height h, the tip swept back"""
    nv = Vector((0, math.cos(a), math.sin(a))); tv = Vector((0, -math.sin(a), math.cos(a)))
    L = x1 - x0
    q = [Vector((x0, 0, 0)) + nv * r0, Vector((x1, 0, 0)) + nv * r0, Vector((x1 - L * sweep, 0, 0)) + nv * (r0 + h), Vector((x0 - L * 0.15, 0, 0)) + nv * (r0 + h * 0.9)]
    V = [v + tv * t for v in q] + [v - tv * t for v in q]
    F = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    return [tuple(v) for v in V], F


def _flip_x(vf):
    """a revolve profile built along -X for the stern"""
    V, F = vf
    return [(-x, y, z) for (x, y, z) in V], [tuple(reversed(f)) for f in F]


# ------------------------------------------------------------------------------------------------- Sunward torpedo (harrow)
# factions.md: black iron, forged plate with rivet lines, frost-white markings, ember; never rust, never blue light.
def sunward_torpedo(variant='A'):
    p = Part('munition')
    n, ph = 8, math.pi / 8
    r = 0.27
    if variant == 'A':
        # VT-A the forged round: an eight-sided forged body, the bomber's bomb nose scaled up (a blunt dark ogive with a worked
        # band, the SB4 cassette's seated warhead), a frost-white oath band, rivet rings, the craft drive in its armoured cowl
        xb0, xb1 = -0.78, 0.55
        p.add('body', 'body', 'siron', revolve([(xb0, r * 0.9), (xb0 + 0.06, r), (xb1, r), (xb1 + 0.05, r * 0.94)], n, phase=ph))
        VS.panels(p, 'body', 'body', ['siron', 'siron2'], xb0 + 0.08, xb1 - 0.04, r, n, ph, th=0.016, size=(0.09, 0.17), seed=3)
        p.add('nose', 'body', 'siron2', revolve([(xb1 + 0.04, r * 0.95), (0.80, r * 0.92), (1.0, r * 0.62), (1.12, r * 0.22), (1.15, 0.0001)], 16, phase=ph / 2))
        p.add('noseband', 'body', 'sworn', ring_band(0.70, r * 0.93, 0.07, 0.022, 16))
        p.add('collar', 'body', 'sworn', revolve([(xb1 - 0.02, r * 0.98), (xb1 - 0.02, r * 1.09), (xb1 + 0.07, r * 1.09), (xb1 + 0.07, r * 0.96)], n, closed=True, phase=ph))
        p.add('oath', 'body', 'oath', ring_band(0.30, r * 1.04, 0.12, 0.012, n))
        for x in (xb1 + 0.025, -0.05, xb0 + 0.05):
            p.add('rivets%.2f' % x, 'body', 'sworn', VS._x_studs(x, r * 1.02, 8, 0.016, phase=ph))
        # two heat louvres a side: the motor's heat shed through ember-lit slats (the kit's vent), on the flank flats
        for k in (2, 6):
            a = 2 * math.pi * (k + 0.5) / n + ph
            nv = Vector((0, math.cos(a), math.sin(a)))
            v = VS.vent(0.16, 0.09, slats=4, depth=0.02, fr=0.018)
            M = Matrix.Translation(Vector((-0.45, 0, 0)) + nv * (r * math.cos(math.pi / n) + 0.004)) @ Matrix(((1, 0, 0), (0, -nv.z, nv.y), (0, nv.y, nv.z))).to_4x4()
            for c in v.comps:
                p.add('vent%d_%s' % (k, c['name']), 'body', c['mat'], ([M @ Vector(q) for q in c['verts']], c['faces']))
        # more detail (Ryan, Nov 20: "are we going to paint it and add more detail after?"): a riveted worked-iron spine strap
        # along the top and the belly flats, a louvre on the top flat forward of the drive, studs round the nose collar
        ap = r * math.cos(math.pi / n)
        for sgn in (1, -1):
            p.add('spine%d' % (sgn > 0), 'body', 'sworn', block(xb0 + 0.04, xb1 - 0.03, 0.028, 0.009, 0.004, zo=sgn * (ap + 0.009)))
            st = [VS._stud((x, 0, sgn * (ap + 0.018)), (0, 0, sgn), 0.012) for x in [xb0 + 0.10 + i * 0.16 for i in range(8)]]
            p.add('spinestuds%d' % (sgn > 0), 'body', 'sworn', VS._join(st))
        v = VS.vent(0.10, 0.20, slats=5, depth=0.02, fr=0.016)
        Mt = Matrix.Translation((-0.62, 0.12, ap + 0.004))
        for c in v.comps:
            p.add('vent_top_%s' % c['name'], 'body', c['mat'], ([Mt @ Vector(q) for q in c['verts']], c['faces']))
        p.add('nosestuds', 'body', 'sworn', VS._x_studs(xb1 + 0.035, r * 1.09, 12, 0.014, phase=0.1))
        # fine detail to the ships' density (Ryan, Nov 20, after the PC run: "a bit more fine detail to match the ships"):
        # seam rings worked into the warhead, a frost-white tip band, four forged stabiliser blades at the stern with worked
        # edges, a conduit with clamps down each flank, ember sight slits and frost running points forward, a second oath band
        p.add('noseseam1', 'body', 'sworn', ring_band(0.88, r * 0.84, 0.025, 0.012, 16))
        p.add('noseseam2', 'body', 'sworn', ring_band(1.00, r * 0.63, 0.022, 0.010, 16))
        p.add('nosefrost', 'body', 'oath', ring_band(0.62, r * 0.955, 0.035, 0.008, 16))
        p.add('oath2', 'body', 'oath', ring_band(-0.66, r * 1.03, 0.035, 0.008, n))
        for k in range(4):
            a = 2 * math.pi * k / 4 + math.pi / 4 + ph
            p.add('fin%d' % k, 'body', 'siron2', _fin(-0.86, -0.56, a, r * 0.95, 0.15, 0.012))
            p.add('finedge%d' % k, 'body', 'sworn', _fin(-0.88, -0.84, a, r * 0.95 + 0.15 * 0.9, 0.025, 0.016, sweep=0))
        for sgn in (1, -1):
            a = math.pi / 2 - sgn * math.pi / 2      # the two side flats (+Y, -Y)
            nv = Vector((0, math.cos(a), math.sin(a)))
            c0, c1 = Vector((-0.30, 0, 0)) + nv * (ap + 0.02), Vector((0.42, 0, 0)) + nv * (ap + 0.02)
            p.add('conduit%d' % (sgn > 0), 'body', 'sworn', HB.rod(c0, c1, 0.012, 6))
            cl = [HB.rod(c0.lerp(c1, t) - Vector((0.012, 0, 0)), c0.lerp(c1, t) + Vector((0.012, 0, 0)), 0.02, 6) for t in (0.0, 0.33, 0.66, 1.0)]
            p.add('clamps%d' % (sgn > 0), 'body', 'siron2', VS._join(cl))
            _on_surface(p, 'lamp%d' % (sgn > 0), _scaled(VS.lamp(0.05), 0.5), 0.48, a + sgn * 0.6, ap + 0.002)
        for a in (math.pi / 4 + ph, 3 * math.pi / 4 + ph):
            _on_surface(p, 'slit%.1f' % a, VS.slit(0.06, 0.016, depth=0.012, fr=0.008), 0.30, a, r * math.cos(math.pi / n) + 0.002)
        d = VS.craft_drive(0.17, 0.32, cowl_r=0.25)
        _move(d, Matrix.Translation((X0 + 0.03, 0, 0)))
        p.extend(d, 'drive_')
    else:
        # VT-B the oath lance: slimmer and longer in the iron, a stepped two-course body (the warhead course forward of a
        # forged step), a worked-iron ram tip, two frost-white bands, the same craft drive
        r = 0.24
        p.add('aft', 'body', 'siron', revolve([(-0.80, r * 0.92), (-0.74, r), (0.05, r), (0.08, r * 0.92)], n, phase=ph))
        VS.panels(p, 'aft', 'body', ['siron', 'siron2'], -0.72, 0.02, r, n, ph, th=0.015, size=(0.14, 0.26), seed=5)
        r2 = r * 1.12
        p.add('step', 'body', 'sworn', revolve([(0.05, r * 0.9), (0.10, r2), (0.16, r2), (0.16, r * 0.9)], n, closed=True, phase=ph))
        p.add('fore', 'body', 'siron2', revolve([(0.15, r2 * 0.96), (0.62, r2 * 0.96), (0.95, r2 * 0.55), (1.08, r2 * 0.2)], n, phase=ph))
        VS.panels(p, 'fore', 'body', ['siron2', 'siron'], 0.18, 0.60, r2 * 0.96, n, ph, th=0.014, size=(0.15, 0.22), seed=8, rivets=False)
        p.add('tip', 'body', 'sworn', revolve([(1.06, r2 * 0.24), (1.15, 0.0001)], n, cap0=True, phase=ph))
        p.add('oath1', 'body', 'oath', ring_band(-0.20, r * 1.03, 0.07, 0.01, n))
        p.add('oath2', 'body', 'oath', ring_band(-0.34, r * 1.03, 0.04, 0.01, n))
        for x in (0.13, -0.60):
            p.add('rivets%.2f' % x, 'body', 'sworn', VS._x_studs(x, (r2 if x > 0 else r) * 1.01, 8, 0.015, phase=ph))
        d = VS.craft_drive(0.16, 0.30, cowl_r=0.23)
        _move(d, Matrix.Translation((X0 + 0.03, 0, 0)))
        p.extend(d, 'drive_')
    return p


# ------------------------------------------------------------------------------------------------- Hullbreaker rocket
# factions.md: a lopsided brick of rust and stolen plate; bolted, patched; salvaged noses (the rocket rack's own nose rows).
def hullbreaker_rocket(variant='A'):
    p = Part('munition')
    r = 0.25
    seg = 12
    if variant == 'A':
        # KR-A the welded round: the rack's rocket nose (red-brown warhead) on a soot tube, two iron clamp bands with bolts,
        # one big pale salvaged patch welded on the flank, the craft drive's salvaged bell on a short drum
        p.add('tube', 'body', 'soot', revolve([(-0.62, r * 0.9), (-0.58, r), (0.42, r), (0.46, r * 0.95)], seg, phase=math.pi / seg))
        p.add('nose', 'body', 'warhead', revolve([(0.44, r * 0.96), (0.70, r * 0.93), (0.98, r * 0.55), (1.12, r * 0.15), (1.15, 0.0001)], seg, cap0=False))
        for x in (0.36, -0.40):
            p.add('band%.2f' % x, 'body', 'iron', ring_band(x, r * 1.01, 0.08, 0.03, seg))
            st = []
            for i in range(4):
                a = 2 * math.pi * (i + 0.5) / 4
                st.append(HB.rod((x, r * 1.03 * math.cos(a), r * 1.03 * math.sin(a)), (x, r * 1.09 * math.cos(a), r * 1.09 * math.sin(a)), 0.02, 6))
            p.add('bolts%.2f' % x, 'body', 'steel', VS._join(st))
        # the patch: one salvaged plate over the starboard flank (the faction's big trophy patch, R252), rivets on its long edge
        bot = []
        for (x, a) in ((-0.28, -1.35), (0.22, -1.35), (0.22, -0.35), (-0.28, -0.35)):
            bot.append((x, r * 1.005 * math.cos(a), r * 1.005 * math.sin(a)))
        (V_, F_), (RV, RF) = HB.plate_slab(bot, (0, math.cos(-0.85), math.sin(-0.85)), 0.018, rr=0.016)
        p.add('patch', 'body', 'iron', (V_, F_))
        if RV:
            p.add('patchrivets', 'body', 'steel', (RV, RF))
        d = HBC.craft_drive(0.19, 0.36)
        _move(d, Matrix.Translation((X0 + 0.02, 0, 0)))
        p.extend(d, 'drive_')
        # the lopsided booster: none on A (one round tube)
    else:
        # KR-B the strapped pair: a main tube with a smaller booster strapped to one flank (bigger on one side than the other),
        # a brass salvaged nose, straps with bolts, two mismatched bells (one larger, factions.md)
        p.add('tube', 'body', 'soot', revolve([(-0.60, r * 0.9), (-0.56, r), (0.40, r), (0.44, r * 0.95)], seg, phase=math.pi / seg))
        p.add('nose', 'body', 'brass', revolve([(0.42, r * 0.96), (0.66, r * 0.93), (0.96, r * 0.5), (1.12, r * 0.12), (1.15, 0.0001)], seg))
        rb = r * 0.55
        yb = -(r + rb * 0.85)   # strapped to the starboard flank
        B = Matrix.Translation((0, yb, -0.03))
        p.add('booster', 'body', 'rust', moved(revolve([(-0.45, rb * 0.9), (-0.42, rb), (0.25, rb), (0.40, rb * 0.5), (0.46, 0.0001)], 10), B))
        for x in (0.18, -0.30):
            p.add('strap%.2f' % x, 'body', 'iron', revolve([(x - 0.04, r * 1.0), (x - 0.04, r * 1.06), (x + 0.04, r * 1.06), (x + 0.04, r * 1.0)], seg, closed=True))
            p.add('strapb%.2f' % x, 'body', 'iron', moved(revolve([(x - 0.04, rb * 1.0), (x - 0.04, rb * 1.1), (x + 0.04, rb * 1.1), (x + 0.04, rb * 1.0)], 10, closed=True), B))
            p.add('web%.2f' % x, 'body', 'iron', block(x - 0.035, x + 0.035, (-yb - r) * 0.5 + 0.02, rb * 0.35, 0, yo=yb + rb * 0.5, zo=-0.015))
        # more detail (Ryan, Nov 20): a weld bead where the salvaged nose meets the tube, a clamp band behind it, bolt heads on
        # the straps, and a salvaged plate welded over the top of the main tube
        p.add('weld', 'body', 'steel', revolve([(0.42, r * 0.98), (0.43, r * 1.035), (0.45, r * 1.035), (0.46, r * 0.95)], seg, closed=True))
        p.add('clamp', 'body', 'iron', ring_band(0.30, r * 1.0, 0.05, 0.025, seg))
        bl = []
        for x in (0.18, -0.30):
            for a in (0.6, 1.6, 2.6):
                bl.append(HB.rod((x, r * 1.05 * math.cos(a), r * 1.05 * math.sin(a)), (x, r * 1.11 * math.cos(a), r * 1.11 * math.sin(a)), 0.018, 6))
        p.add('strapbolts', 'body', 'steel', VS._join(bl))
        bot = [(x, r * 1.005 * math.cos(a), r * 1.005 * math.sin(a)) for (x, a) in ((-0.48, 1.2), (-0.05, 1.2), (-0.05, 2.1), (-0.48, 2.1))]
        (V_, F_), (RV, RF) = HB.plate_slab(bot, (0, math.cos(1.65), math.sin(1.65)), 0.016, rr=0.014)
        p.add('patch', 'body', 'iron', (V_, F_))
        if RV:
            p.add('patchrivets', 'body', 'steel', (RV, RF))
        # fine detail to the ships' density (Ryan, Nov 20, after the PC run): a feed pipe with collars along the top of the tube,
        # three mismatched welded fins (one cut from other plate), a long weld seam with a rivet line along the belly, a bolted
        # access plate, a small vent and two bands on the booster, a scorched bracket where the booster meets the tube
        pa, pb = Vector((-0.50, r * 1.08 * math.cos(2.55), r * 1.08 * math.sin(2.55))), Vector((0.36, r * 1.08 * math.cos(2.55), r * 1.08 * math.sin(2.55)))
        p.add('pipe', 'body', 'steel', HB.rod(pa, pb, 0.018, 8))
        p.add('pipecollars', 'body', 'iron', VS._join([HB.rod(pa.lerp(pb, t) - Vector((0.012, 0, 0)), pa.lerp(pb, t) + Vector((0.012, 0, 0)), 0.028, 8) for t in (0.05, 0.4, 0.75, 0.97)]))
        for k, (a, h, mat) in enumerate(((1.1, 0.16, 'iron'), (2.9, 0.12, 'rust'), (3.9, 0.14, 'steel'))):
            p.add('fin%d' % k, 'body', mat, _fin(-0.58, -0.30, a, r * 0.95, h, 0.011, sweep=0.4 + 0.1 * k))
        bolts = [HB.rod((x, r * 1.0 * math.cos(a), r * 1.0 * math.sin(a)), (x, r * 1.05 * math.cos(a), r * 1.05 * math.sin(a)), 0.012, 6)
                 for a in (1.1, 2.9, 3.9) for x in (-0.54, -0.44, -0.34)]
        p.add('finbolts', 'body', 'steel', VS._join(bolts))
        p.add('seam', 'body', 'steel', HB.rod((-0.54, r * 1.0 * math.cos(3.4), r * 1.0 * math.sin(3.4)), (0.38, r * 1.0 * math.cos(3.4), r * 1.0 * math.sin(3.4)), 0.009, 5))
        rv = [VS._stud((x, r * 1.01 * math.cos(3.25), r * 1.01 * math.sin(3.25)), (0, math.cos(3.25), math.sin(3.25)), 0.011) for x in [-0.5 + 0.09 * i for i in range(10)]]
        p.add('seamrivets', 'body', 'steel', VS._join(rv))
        acc = [(x, r * 1.004 * math.cos(a), r * 1.004 * math.sin(a)) for (x, a) in ((0.02, 0.35), (0.28, 0.35), (0.28, 0.95), (0.02, 0.95))]
        (V_, F_), (RV, RF) = HB.plate_slab(acc, (0, math.cos(0.65), math.sin(0.65)), 0.012, rr=0.011)
        p.add('access', 'body', 'steel', (V_, F_))
        if RV:
            p.add('accessrivets', 'body', 'iron', (RV, RF))
        for x in (0.05, -0.38):
            p.add('bband%.2f' % x, 'body', 'iron', moved(ring_band(x, rb * 1.0, 0.035, 0.015, 10), B))
        bv = _scaled(HB.vent(0.40, 0.22, slats=3, depth=0.05), 0.3)
        _on_surface(p, 'boostvent', bv, -0.16, -math.pi / 2, rb * 0.98)
        for c in p.comps:
            if c['name'].startswith('boostvent_'):
                c['verts'] = [Vector((v.x, v.y + yb, v.z - 0.03)) for v in c['verts']]
        p.add('bracket', 'body', 'rust', block(-0.12, 0.02, 0.03, 0.03, 0.01, yo=-(r + 0.01), zo=-0.02))
        d = HBC.craft_drive(0.19, 0.36)
        _move(d, Matrix.Translation((X0 + 0.04, 0, 0)))
        p.extend(d, 'drive_')
        d2 = HBC.craft_drive(0.10, 0.10, seed=1)
        _move(d2, Matrix.Translation((-0.47 - 0.15, yb, -0.03)))
        p.extend(d2, 'boost_')
    return p


# ------------------------------------------------------------------------------------------------- Chorus bone bolt (tendril)
# Issue 1877 (Ryan, Nov 24 2026: "Yes bone bolts but we should make sure we actually build those not with code and improve
# the quality"): the Chorus close-in weapon (data.js tendril, range 1, acid) is one heavy bone bolt grown in a gland and
# snapped out. factions.md, The Chorus: grown, not built; bone to horn chitin, olive-brown tissue, bile light from inside only;
# never metal, eyes or a flat lime surface. Every shape comes from the Chorus kit (tools/blender/kits/chorus/parts.py: blob,
# tube, welt, pore, spine_blade, chitin) and the hull's zones (bone, chitin, tissue, scar; veilroot the restrained bile glow),
# so the Chorus paint stack bakes it like a hull. Frame as the casing: +X the point, x -1.15 to 1.15.
#   head   a twisted, ridged pale bone spike (seven growth ridges, a worn point): the part that reads at camera 170
#   barbs  four swept-back bone barbs at the shoulder (the bolt holds once it is in)
#   knuckle  a lumpy bone knuckle with growth rings where the head grows out of the shaft
#   shaft  six splints of dark horn (the hulls' armour finish, carapace) round a bile core: the acid shows only in the cracks
#   sinew  three wet tissue wraps binding the splints
#   tail   three raked bone vanes and a rough butt knob (it flies point first, never tumbling)
def _loft(secs, n, cap0=True, cap1=True):
    """sections [(x, [r per angle], twist)] along +X; a closed ring of n points each"""
    V, F = [], []
    for x, rs, tw in secs:
        for k in range(n):
            a = 2 * math.pi * k / n + tw
            V.append((x, rs[k] * math.cos(a), rs[k] * math.sin(a)))
    m = len(secs)
    for j in range(m - 1):
        for k in range(n):
            a, b = j * n + k, j * n + (k + 1) % n
            F.append((a, a + n, b + n, b))
    if cap0:
        F.append(tuple(range(n)))
    if cap1:
        F.append(tuple(range((m - 1) * n, m * n))[::-1])
    return V, F


def _bare(part):
    """a kit blade without its tissue collar (the collar is for a hull; on a bolt it reads as a flat disc)"""
    part.comps = [c for c in part.comps if c['name'] != 'collar']
    return part


def chorus_bolt(variant='A'):
    import random
    rnd = random.Random(1877)
    p = Part('munition')
    # head: seven ridges, the valleys a third deeper, a quarter turn of twist to the point, a little lumpy
    n, ridges = 28, 7
    xh0, xh1 = 0.30, 1.15
    secs = []
    for j in range(15):
        s = j / 14
        x = xh0 + (xh1 - xh0) * s
        R = 0.20 * (1 - s) ** 0.85 + 0.004
        rs = []
        for k in range(n):
            a = 2 * math.pi * k / n
            ridge = 0.5 + 0.5 * math.cos(ridges * a)
            rs.append(R * (0.70 + 0.30 * ridge ** 1.6) * (1 + 0.05 * math.sin(3 * a + 7 * s + 1.3)))
        secs.append((x, rs, 0.9 * s))
    p.add('head', 'body', 'bone', _loft(secs, n, cap0=True, cap1=True))
    # barbs: four swept-back blades at the shoulder, raked aft, set between the head ridges
    for k in range(4):
        a = 2 * math.pi * k / 4 + math.pi / 4
        b = _bare(CH.spine_blade(0.13, 0.15, t=0.045, rake=60.0, teeth=2, growth=2, seed=10 + k))
        # spine_blade grows out of +Z and rakes toward -X: on the shoulder it sweeps aft like a fish-hook barb
        _on_surface(p, 'barb%d' % k, b, 0.42, a, 0.135)
    # knuckle: the lumpy bone where the head grows out of the shaft, with two growth rolls
    p.add('knuckle', 'body', 'bone', CH.blob(0.13, 0.215, 0.215, centre=(0.25, 0, 0), nu=22, nv=12, seed=4, amp=0.12))
    for x, r in ((0.17, 0.19), (0.33, 0.18)):
        pts = [Vector((x, r * math.cos(2 * math.pi * k / 24), r * math.sin(2 * math.pi * k / 24))) for k in range(25)]
        p.add('roll%.2f' % x, 'body', 'scar', CH.tube(pts, [0.022] * 25, n=6, cap0=False, cap1=False))
    # shaft: the bile core, and six splints round it with cracks between (the acid shows only in the cracks)
    xs0, xs1 = -0.80, 0.20
    core = []
    for j in range(9):
        s = j / 8
        core.append((xs0 + (xs1 - xs0) * s, [0.09] * 12, 0.0))
    p.add('core', 'body', 'veilroot', _loft(core, 12))
    nsp = 6
    for i in range(nsp):
        a0 = 2 * math.pi * i / nsp + 0.085 + rnd.uniform(-0.03, 0.03)
        a1 = 2 * math.pi * (i + 1) / nsp - 0.085 + rnd.uniform(-0.03, 0.03)
        m = 6
        rows = []
        off = rnd.uniform(-0.014, 0.014)
        for j in range(12):
            s = j / 11
            x = xs0 + (xs1 - xs0) * s
            ro = 0.152 + off + 0.026 * math.sin(math.pi * s) + 0.011 * math.sin(13 * s + 2.1 * i) + 0.006 * math.sin(29 * s + i)
            # a crack wanders: the splint's edges shift a little along the shaft
            w = 0.02 * math.sin(6 * s + i * 1.7)
            ring = []
            for q in range(m):
                a = a0 + w + (a1 - a0 - 2 * w * 0) * q / (m - 1)
                bulge = 1 + 0.06 * math.sin(math.pi * q / (m - 1))
                ring.append(Vector((x, ro * bulge * math.cos(a), ro * bulge * math.sin(a))))
            rows.append(ring)
        V, F = [], []
        for ring in rows:
            for v in ring:
                V.append(tuple(v))
            for v in ring:
                d = Vector((0, v.y, v.z)).normalized()
                V.append(tuple(v - d * 0.045))
        for j in range(len(rows) - 1):
            o0, o1 = j * 2 * m, (j + 1) * 2 * m
            for q in range(m - 1):
                F.append((o0 + q, o0 + q + 1, o1 + q + 1, o1 + q))                  # outer face
                F.append((o0 + m + q + 1, o0 + m + q, o1 + m + q, o1 + m + q + 1))  # inner face
            F.append((o0, o1, o1 + m, o0 + m))                                       # crack walls
            F.append((o0 + m - 1, o0 + 2 * m - 1, o1 + 2 * m - 1, o1 + m - 1))
        last = (len(rows) - 1) * 2 * m
        F.append(tuple([q for q in range(m)] + [m + q for q in reversed(range(m))]))
        F.append(tuple([last + m + q for q in range(m)] + [last + q for q in reversed(range(m))]))
        p.add('splint%d' % i, 'body', 'carapace', (V, F))
    # sinew: three tissue wraps binding the splints, slightly spiralled
    for x in (-0.68, -0.38, -0.08):
        pts = [Vector((x + 0.05 * k / 24, 0.178 * math.cos(2 * math.pi * k / 24), 0.178 * math.sin(2 * math.pi * k / 24))) for k in range(25)]
        p.add('sinew%.2f' % x, 'body', 'tissue', CH.tube(pts, [0.026 + 0.006 * math.sin(k) for k in range(25)], n=6, cap0=False, cap1=False))
    # acid pores on the shaft between the wraps (the bile weeps out as it flies)
    for i, (x, a) in enumerate(((-0.52, 0.5), (-0.24, 2.6), (-0.52, 4.3), (0.06, 1.6))):
        nv = Vector((0, math.cos(a), math.sin(a)))
        c = Vector((x, 0, 0)) + nv * 0.175
        p.add('pore%d' % i, 'body', 'scar', CH.pore(c, nv, 0.03, n=14))
    # tail: the shaft narrows into a rough knuckled butt, like the end of a long bone, with three short hooked spurs (no fins:
    # it is grown, not a rocket)
    tl = []
    for j in range(7):
        s_ = j / 6
        x = xs0 + 0.02 - 0.30 * s_
        R = 0.15 * (1 - 0.35 * s_)
        tl.append((x, [R * (1 + 0.10 * math.sin(3 * k * 2 * math.pi / 18 + 2 * s_)) for k in range(18)], 0.3 * s_))
    p.add('neck', 'body', 'carapace', _loft(tl, 18))
    p.add('butt', 'body', 'bone', CH.blob(0.13, 0.15, 0.13, centre=(-1.04, 0.01, 0), nu=20, nv=10, seed=9, amp=0.2))
    p.add('butttip', 'body', 'chitin', CH.blob(0.06, 0.08, 0.07, centre=(-1.13, 0, 0.02), nu=14, nv=8, seed=3, amp=0.25))
    for k in range(3):
        a = 2 * math.pi * k / 3 + math.pi / 6
        _on_surface(p, 'spur%d' % k, _bare(CH.spine_blade(0.08, 0.10, t=0.035, rake=55.0, teeth=0, growth=1, seed=20 + k)), -0.96, a, 0.12)
    return p

MUNITIONS = {
    'voidsworn_torp': ('voidsworn', 'torp', sunward_torpedo),
    'corsair_rockets': ('corsair', 'rockets', hullbreaker_rocket),
    'chorus_bolt': ('chorus', 'bolt', chorus_bolt),
}
# the variant the game uses (options sheet /mnt/project-files/board/torpedo_rework/tp_body_*_r1.jpg; the Board's pick
# VT-A and KR-B until Ryan picks)
PICK = {'voidsworn_torp': 'A', 'corsair_rockets': 'B', 'chorus_bolt': 'A'}
OUT_GAME = os.path.join(REPO, 'godot', 'fx', 'munition_bodies')



def old_casing():
    """the code casing being replaced (fx_weapons.gd _casing, torpedo colours), for the before picture"""
    p = Part('old')
    prof = [[-1.15, 0.12], [-1.02, 0.24], [-0.75, 0.29], [0.38, 0.29], [0.70, 0.21], [1.12, 0.025], [1.15, 0.0]]
    p.add('body', 'body', 'old_body', revolve([tuple(q) for q in prof], 8))
    p.add('band', 'body', 'old_band', revolve([(-0.75, 0.292), (0.38, 0.292)], 8))
    fins = []
    for i in range(4):
        rad = Vector((0, math.cos(i * math.pi / 2), math.sin(i * math.pi / 2)))
        a, b, c = Vector((-0.95, 0, 0)) + rad * 0.23, Vector((-0.90, 0, 0)) + rad * 0.63, Vector((-0.20, 0, 0)) + rad * 0.23
        fins.append(([tuple(a), tuple(b), tuple(c)], [(0, 1, 2)]))
    p.add('fins', 'body', 'old_fin', VS._join(fins))
    return p


MATS['old_body'] = ((0.14, 0.13, 0.12), 0)
MATS['old_band'] = ((0.34, 0.29, 0.21), 0)
MATS['old_fin'] = ((0.40, 0.36, 0.29), 0)


# ------------------------------------------------------------------------------------------------- Blender side
def _mat(bpy, name):
    m = bpy.data.materials.get(name)
    if m:
        return m
    rgb, em = MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*rgb, 1)
    b.inputs['Roughness'].default_value = 0.62
    b.inputs['Metallic'].default_value = 0.35 if name in METAL else 0.12
    if em:
        b.inputs['Emission Color'].default_value = (*rgb, 1)
        b.inputs['Emission Strength'].default_value = em
    return m


def _job(cname):
    """the paint stack's job for a piece: the body is hull (one atlas), the drive and the fittings are parts"""
    for pre, kind in (('drive_', 'engine'), ('boost_', 'engine'), ('vent', 'vent'), ('barb', 'spine'), ('spur', 'spine')):
        if cname.startswith(pre):
            return 'part', kind, pre.rstrip('_')
    return 'hull', '', 'body'


def to_blender(bpy, part, name, at=(0, 0, 0)):
    """one object per (job, material), parented to an empty named after the munition; role, part_kind and grp as the build
    sheets stamp them (tools/blender/build_sheets/kit.py), so the faction paint stack paints it as it paints a ship"""
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    root.location = at
    by = {}
    for c in part.comps:
        role, kind, grp = _job(c['name'])
        V, F = by.setdefault((role, kind, grp, c['mat']), ([], []))
        o = len(V); V.extend(tuple(v) for v in c['verts']); F.extend(tuple(i + o for i in f) for f in c['faces'])
    for (role, kind, grp, m), (V, F) in by.items():
        nm = '%s_%s_%s' % (name, grp, m)
        me = bpy.data.meshes.new(nm); me.from_pydata(V, [], F); me.validate(); me.update()
        for poly in me.polygons:
            poly.use_smooth = name in SMOOTH     # grown parts are smooth shaded, as the Chorus kit's (parts.SMOOTH)
        ob = bpy.data.objects.new(nm, me); ob.data.materials.append(_mat(bpy, m))
        ob['role'] = role; ob['grp'] = grp
        if kind:
            ob['part_kind'] = kind
        bpy.context.scene.collection.objects.link(ob); ob.parent = root
    return root


STACKS = {'voidsworn': 'voidsworn', 'corsair': 'hullbreakers', 'chorus': 'chorus'}
# Ryan, Nov 20 (PC run 1379c): the Sunward torpedo read near black in game ("Brighten"). A torpedo is a few pixels on the board,
# so the black-iron hull finish is lifted on its baked albedo (the ships keep theirs). 1.0 = the ship finish as baked.
LIFT = {'voidsworn': 2.3, 'corsair': 1.15, 'chorus': 1.0}
KEEP = ('oath',)      # painted marks the stack has no zone for: kept as their own flat material (the frost-white oath band)
SMOOTH = ('chorus_bolt',)
RES = {'chorus_bolt': 1024}   # the bolt is seen close at camera 26 (Ryan: "improve the quality"); the rest keep 512


def lift(bpy, cell, k):
    """brighten the baked albedo atlases of one munition by k (alpha kept), in place, so the glb export carries it"""
    if abs(k - 1.0) < 1e-6:
        return
    import numpy as np
    for im in bpy.data.images:
        if im.name.startswith(cell) and 'albedo' in im.name:
            a = np.empty(len(im.pixels), np.float32); im.pixels.foreach_get(a)
            a = a.reshape(-1, 4); a[:, :3] = np.clip(a[:, :3] * k, 0, 1)
            im.pixels.foreach_set(a.ravel()); im.update()
            if im.filepath_raw:
                im.save()
            im.pack()          # the stack packs its atlases; the glb export writes the packed copy, so pack the lifted pixels
            print('[munitions] lifted', im.name, k)


def paint(bpy, root, fac, cell, out, res=512, samples=8):
    """the faction's paint stack (tools/blender/kits/<kit>/stack.py through kits/shared/paint_stack.py), as a ship's stage 5:
    masks from the munition's own geometry, the faction's procedural layers, trim sheet and decals, baked to small atlases"""
    kitn = STACKS[fac]
    sys.path.insert(0, os.path.join(REPO, 'tools', 'blender', 'r209'))
    S = kit(kitn, 'stack.py')
    size = L
    if hasattr(S, 'CRAFT_SIZE'):
        # the Hullbreaker stack's craft sizes (patches, rivets, scuffs): a munition is craft-sized on the board. The stack
        # reads the length again from the scene during the bake, so the scene carries the craft length too.
        size = min(L, S.CRAFT_SIZE['max_length'])
    bpy.context.scene['r209_length_world'] = size
    if hasattr(S, 'configure_size'):
        S.configure_size(size)
    S.RUNNING_LIGHTS = None   # a munition carries no running lights
    os.makedirs(out, exist_ok=True)
    import paint_stack as PS
    kept = [o for o in root.children if o.data.materials and o.data.materials[0].name in KEEP]
    for o in kept:
        bpy.context.scene.collection.objects.unlink(o)
    info = PS.run(S, out, cell, res, res, samples)
    lift(bpy, cell, LIFT.get(fac, 1.0))
    for o in kept:
        bpy.context.scene.collection.objects.link(o)
    return info


def main():
    import bpy
    out = sys.argv[1] if len(sys.argv) > 1 else OUT_GAME
    mode = sys.argv[2] if len(sys.argv) > 2 else 'export'
    os.makedirs(out, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    if mode == 'review':
        rows = [('old', old_casing(), 'before: code casing')]
        for v in ('A', 'B'):
            rows.append(('VT-%s' % v, sunward_torpedo(v), 'Sunward VT-%s' % v))
        for v in ('A', 'B'):
            rows.append(('KR-%s' % v, hullbreaker_rocket(v), 'Hullbreaker KR-%s' % v))
        for i, (nm, pt, _) in enumerate(rows):
            to_blender(bpy, pt, nm, at=(0, 0, 0))
        import json
        json.dump([[nm, lab] for nm, _, lab in rows], open(os.path.join(out, 'rows.json'), 'w'))
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, 'munitions_review.blend'))
    else:
        for code, (fac, lk, fn) in MUNITIONS.items():
            bpy.ops.wm.read_factory_settings(use_empty=True)
            v = PICK[code]
            root = to_blender(bpy, fn(v), code)
            if mode != 'flat':
                paint(bpy, root, fac, code, os.path.join(out, '_paint', code), res=RES.get(code, 512))
            bpy.ops.object.select_all(action='DESELECT')
            for o in [root] + list(root.children):
                o.select_set(True)
            bpy.ops.export_scene.gltf(filepath=os.path.join(out, code + '.glb'), use_selection=True, export_format='GLB',
                                      export_apply=True, export_yup=True, export_extras=True,
                                      export_image_format='JPEG', export_jpeg_quality=88)
            print('[munitions] wrote', code, v)


if __name__ == '__main__':
    main()
