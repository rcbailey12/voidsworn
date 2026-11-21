# Hegemony Navy (`hegemony`) part shapes (issue 759, the Dominion dreadnought build sheet hegemony_H10; RULEBOOK 4.5: every
# faction its own kit, only the invisible plumbing in tools/blender/kits/shared/geom.py is shared).
# The faction sheet (docs/playbooks/factions.md, Hegemony Navy): "a pale wedge with a line of blue light"; machined, modular,
# horizontal; flush panels, straight seams, repeated modules; the same parts repeated at different sizes across the fleet;
# guns in low armoured mounts sunk into the shoulder armour, short thick barrels, never tall round turrets with long thin
# barrels (R185 (4): "The hegemony guns look weird and almost cartoonish"); the ion weapon a recessed emitter trench in a blunt
# bow face, never prongs (R183 (1)); engines a flat row of rectangular blue-white nozzles; never rust, asymmetry, ornament or
# warm light. Paint direction (contrib/muse/design/paint_direction_2026_11/hegemony.md, approved Nov 14): the even grid, two
# module sizes, the module band as structure, flush fasteners (no rivet lines). Lore (lore bible 3): the Registry's fleet,
# "rows of identical turrets", plasma weapons (light blue), ion tech reverse-engineered from the captured core Vyre, drone
# escorts, retro thrusters that make backing off cheap.
#   gun          (R221) built from the weapon it carries (data.js W, FAC_WNAMES.hegemony, godot/fx/fx_weapons.gd looks):
#                plasma lance turret (hturbo, the Heavy plasma lance, look 'plasma': slow fat bolts with a corona): a low
#                  wide armoured mount sunk in a shoulder pit: a flush ring, a faceted casemate housing with a sloped glacis,
#                  armoured cheeks and a capacitor bustle, two short thick containment barrels (accelerator coil rings,
#                  a vented muzzle shroud, a blue-lit bore)
#                picket laser turret (flak, Picket lasers, point defence): a small low eight-sided turret with a sensor eye
#                  and two short emitter tubes with lens tips, elevating high for craft
#   spinal       the ion cannon (ion, look 'ion'): an emitter trench recessed in the blunt bow face (R183 (1)): lined walls of
#                  stacked coil plates, an emitter block at the back with a blue lens, never a barrel or prongs
#   engine_bell  a rectangular nozzle (factions.md: a flat row of rectangular blue-white nozzles): a panelled housing sunk in
#                the engine block, a thick lip, inner walls tapering to a blue throat, guide vanes deep in the throat
#   antenna      the one low sensor fin (factions.md: one low sensor fin, not a tower): a swept armoured fin with sensor
#                windows and a lens strip; a machine (R226) and a sensor for the R240 test (clash.py SENSOR_KINDS)
#   bay          flush armoured drone doors (R232: a seam line only on the intact ship, opening in the break state)
#   latch        a module latch row: the four clamp heads that lock two hull modules together at a module band
#   hatch, hatchbox, vent, slit, thruster, module_panels: the Hegemony versions (flush rectangular hatches, a module housing,
#                louvres over a dark recess, blue-white window slits, rectangular retro and attitude nozzles, flush panels in an
#                even grid of two module sizes)
# Local frame of every part: +X forward (the aim, or the engine's thrust direction), +Y left, +Z up (the mount normal).
# Roles: 'mount' parts may sit into the hull; every other role must stay clear of it; 'turn' (turret guns, R219) turns.
# Materials: the Hegemony rows are this kit's own (MATS below; the ship file merges them into the sheet kit's table before it
# builds, so the shared tools/blender/build_sheets/kit.py is untouched), plus the shared dark.
import math
import os
import sys
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'shared')))
from geom import Part, P, D, frame, revolve, prism, octa, block, moved, ring_band, rod  # noqa: E402,F401
import geom  # noqa: E402

# R226: the part kinds that are machines (a machine never crosses a seam; it rides whole with one piece). The sensor fin is a
# machine (pack.md section 6: "turrets, launchers and the sensor fin are machines and ride whole with their module").
MACHINES = ('gun', 'engine', 'thruster', 'antenna', 'spinal',
            'capbank', 'exchanger')   # issue 768: the Iron Mandate's canyon machinery rides whole with its module too

# The Hegemony colour zones (factions.md: pale grey, steel-blue trim, implant-blue light strips; paint direction hegemony.md
# section 2, the H10 samples: body #48505e over #141c2a, recessed #212b3b, trim #626d7d, implant blue #57b6e5 to #bdf1fd),
# in the sheet kit's format (rgb linear, emission strength). Schematic; the Hegemony paint stack finishes them later.
MATS = {
    'hgrey': ((0.085, 0.095, 0.118), 0),     # hull body modules (the big module plates)
    'hgrey2': ((0.036, 0.044, 0.060), 0),    # recessed fields, module bands' seams, pits and frames
    'hpanel': ((0.105, 0.118, 0.142), 0),    # the small module plates (the second module size)
    'htrim': ((0.125, 0.150, 0.195), 0),     # steel-blue trim: module bands, rails' edges, housings' rims
    'hmetal': ((0.17, 0.18, 0.20), 0),       # machined metal: barrels, coils, latch heads, vanes
    'hblue': ((0.30, 0.68, 1.0), 2.2),       # implant-blue light strips (the blue line; never warm light)
    'hlens': ((0.45, 0.80, 1.0), 2.6),       # weapon lenses and bores (plasma and ion: light blue)
    'hnozzle': ((0.62, 0.86, 1.0), 6.0),     # nozzle throat glow, blue-white
    'hlining': ((0.18, 0.40, 0.85), 1.2),    # nozzle inner walls, a dimmer blue so the dark lip reads
    'hwin': ((0.72, 0.88, 1.0), 1.4),        # blue-white windows
    # insides (cutaway only; factions.md "Inside: white corridors, blue emergency light, racks of identical equipment")
    'hcorr': ((0.70, 0.73, 0.76), 0),        # white corridors and crew decks
    'hrack': ((0.30, 0.38, 0.48), 0),        # racks of identical equipment
    'hemerg': ((0.15, 0.40, 0.95), 0.6),     # blue emergency light strips
}
METALLIC = ('hmetal', 'htrim')

SUBPARTS = {
    'engine': ['housing', 'lip', 'lining', 'throat', 'vane', 'band'],
    'gun': ['ring', 'housing', 'mantlet', 'barrel', 'coil', 'muzzle', 'bore'],
    'ion_trench': ['liner', 'coil', 'emitter', 'lens'],
    'antenna': ['root', 'fin', 'window', 'lens'],
    'bay': ['frame', 'door', 'seam'],
    'latch': ['base', 'clamp'],
    'hatch': ['rim', 'door', 'seam', 'grip'],
    'hatchbox': ['frame', 'lid', 'seam'],
    'vent': ['frame', 'slat'],
    'slit': ['frame', 'glass'],
    'thruster': ['block', 'nozzle'],
    'plate': ['panel', 'seam', 'module'],
    'hull': ['facet', 'step', 'chamfer'],
    'band': ['band', 'seam', 'strip'],
    'tier': ['face', 'roof', 'opening'],
    'rail': ['facet', 'step', 'strip'],
    'rib': ['rib'],
    # issue 768 (hegemony_IM5, the Iron Mandate): the canyon machinery
    'pipe': ['trunk', 'collar', 'flange', 'saddle'],
    'capbank': ['base', 'cell', 'cap', 'bus', 'strip'],
    'exchanger': ['base', 'housing', 'fin', 'frame', 'port'],
    # issue 1413 (hegemony_O2, the Convoy transport): a cargo module locked in the cargo well
    'container': ['frame', 'lid', 'seam', 'rib', 'clamp'],
    # issue 1413 (hegemony_O3, the Relay beacon): the oversized recessed relay lens
    'relay_lens': ['face', 'ring', 'lens', 'glow'],
    'bomb_tube': ['housing', 'frame', 'collar', 'bore', 'ring', 'back', 'warhead'],
}


def detail_ok(kind, names):
    return geom.detail_ok(SUBPARTS, kind, names)


def _zrev(profile, n, phase=0.0, **kw):
    """a revolve about the local Z axis (a vertical solid of revolution): profile [(z, r)]"""
    return revolve(profile, n, axis='Z', phase=phase, **kw)


def _join(parts):
    V, F = [], []
    for v, f in parts:
        o = len(V); V.extend(v); F.extend(tuple(x + o for x in q) for q in f)
    return V, F


def _zblock(x0, x1, y0, y1, z0, z1, ch=0.0):
    """an axis box (x0..x1, y0..y1, z0..z1) with its top edges chamfered by ch"""
    hw = (y1 - y0) / 2; yo = (y1 + y0) / 2; hh = (z1 - z0) / 2; zo = (z1 + z0) / 2
    return block(x0, x1, hw, hh, ch, yo=yo, zo=zo)


def _poly_prism(pts, z0, z1, inset=0.0):
    """a vertical prism over a plan polygon pts [(x, y)] from z0 to z1; the top face shrunk by inset (a chamfer)"""
    n = len(pts)
    cx = sum(p[0] for p in pts) / n; cy = sum(p[1] for p in pts) / n
    top = []
    for (x, y) in pts:
        d = math.hypot(x - cx, y - cy) or 1.0
        k = max(0.0, 1 - inset / d)
        top.append((cx + (x - cx) * k, cy + (y - cy) * k))
    V = [(x, y, z0) for (x, y) in pts] + [(x, y, z1) for (x, y) in top]
    F = [tuple(range(n))[::-1], tuple(range(n, 2 * n))] + [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
    return V, F


# ---------------------------------------------------------------------------------------------------- the even panel grid
def panel_slab(bot, nrm, t, bevel=0.5, gap=0.0, sink=0.02):
    """one flush Hegemony panel on a hull face: bot = four corners on the surface (world), nrm = outward normal. A thin slab of
    thickness t with a machined chamfer on its top edges (bevel, a share of t); no rivets (paint direction: flush fasteners).
    sink: how far its base sits into the hull (issue 793: a craft passes a smaller one)."""
    bot = [Vector(q) for q in bot]; nrm = Vector(nrm); k = len(bot)
    mid = sum(bot, Vector()) / k
    top = []
    for q in bot:
        sh = (mid - q).normalized() * min(t * bevel * 2, (mid - q).length * 0.25)
        top.append(q + nrm * t + sh)
    base = [q - nrm * sink for q in bot]
    V = [tuple(q) for q in base + top]
    F = [tuple(range(k))[::-1], tuple(range(k, 2 * k))] + [(i, (i + 1) % k, k + (i + 1) % k, k + i) for i in range(k)]
    return V, F


def module_panels(rings, faces, pv=0.62, t_big=0.034, t_small=0.022, mats=('hgrey', 'hpanel'), keep=None, small=None, closed=True, gap=0.03, unit=1.0):
    """Hegemony plating over the quad strips of a loft whose rings sit at an even pitch along X (the caller lays the rings at
    the module grid's pitch in world units, so seams line up across the whole hull: R243, "rigid and clean"). Every face strip
    between two rings is divided across into round(width / pv) panels, each a flush slab with a machined chamfer and a seam gap
    round it. small(i, b, nb) says which cells carry the second module size (four small panels, a step thinner); the default
    is an even rhythm, symmetric across each face so port and starboard match. keep(p, r) True where a mount claims the surface.
    unit (issue 793, a squadron craft): scales the smallest face that takes panels and the panels' sink into the hull, so a craft
    a twentieth of a capital ship's length gets the same grid; 1.0 keeps every capital sheet as it was.
    Returns ({mat: (V, F)}, panels laid)."""
    n = len(rings[0])
    acc = {m: ([], []) for m in mats}
    laid = 0
    cen = [sum((Vector(q) for q in r), Vector()) / n for r in rings]
    if small is None:
        def small(i, b, nb):
            return i % 3 == 1 and min(b, nb - 1 - b) % 2 == 0

    def put(mk, bot, nrm, t):
        V, F = panel_slab(bot, nrm, t, sink=0.02 * unit)
        bv, bf = acc[mk]; o = len(bv); bv.extend(V); bf.extend(tuple(x + o for x in f) for f in F)

    for i in range(len(rings) - 1):
        for j in faces:
            if not closed and j >= n - 1:
                continue
            A, B = Vector(rings[i][j]), Vector(rings[i][(j + 1) % n])
            Dq, C = Vector(rings[i + 1][j]), Vector(rings[i + 1][(j + 1) % n])
            flen = ((Dq - A).length + (C - B).length) / 2; fw = ((B - A).length + (C - Dq).length) / 2
            if flen < 0.2 * unit or fw < 0.16 * unit:
                continue
            nrm = (B - A).cross(Dq - A)
            if nrm.length < 1e-7:
                nrm = (C - B).cross(Dq - B)
            if nrm.length < 1e-7:
                continue
            nrm.normalize()
            if nrm.dot((A + C) / 2 - (cen[i] + cen[i + 1]) / 2) < 0:
                nrm = -nrm

            def Pq(u, v):
                return A.lerp(Dq, u).lerp(B.lerp(C, u), v)
            nb = max(1, int(round(fw / pv)))
            gu, gv = gap / flen, gap / fw
            for b in range(nb):
                v0, v1 = b / nb + gv, (b + 1) / nb - gv
                pc = Pq(0.5, (v0 + v1) / 2); hd = 0.5 * (flen + (v1 - v0) * fw)
                if keep and keep(pc, hd * 0.6):
                    continue
                if small(i, b, nb):
                    um = 0.5; vm = (v0 + v1) / 2
                    for (ua, ub) in ((gu, um - gu * 0.5), (um + gu * 0.5, 1 - gu)):
                        for (va, vb) in ((v0, vm - gv * 0.5), (vm + gv * 0.5, v1)):
                            put(mats[1], [Pq(ua, va), Pq(ub, va), Pq(ub, vb), Pq(ua, vb)], nrm, t_small); laid += 1
                else:
                    put(mats[0], [Pq(gu, v0), Pq(1 - gu, v0), Pq(1 - gu, v1), Pq(gu, v1)], nrm, t_big); laid += 1
    return acc, laid


# ---------------------------------------------------------------------------------------------------- engine
ENGINE_WHAT = 'engine, rectangular nozzle %.1f across'


def engine_bell(r_exit, body_len, bell_len=None, body_r=None, throat=0.55, rings=3, nose='flat', w=None, h=None, seg=None, craft=False, cells=3):
    """the Hegemony engine (factions.md: a flat row of rectangular blue-white nozzles); exhaust leaves along -X; origin at the
    centre of the nozzle's exit plane. w, h: the mouth's width and height (local Y and Z). The mouth is a rounded rectangle
    (its corners eased so the exit rim reads all round, the export's open-bell test, check_export.py) with a thick machined
    lip; inner walls taper in to a recessed throat plate glowing blue-white, three guide vanes deep in the throat; behind it a
    panelled housing sunk in the engine block (the mount) with two trim bands. fit radius: the rim's mean radius.
    craft=True (issue 793): a squadron craft's drive instead, craft_drive below (the sheet kit's K.engine passes it through kw)."""
    if craft:
        return craft_drive(w or 2 * r_exit, h or r_exit, body_len, depth=bell_len, cells=cells)
    p = Part('engine')
    w = w or 2 * r_exit * 0.85; h = h or 2 * r_exit * 1.15
    depth = bell_len or max(w, h) * 0.75

    def rrect(hw, hh, rc, k=8):
        """a rounded rectangle (y, z) loop, corners of radius rc, k points a corner, starting at +Y +Z"""
        corners = []
        for cy, cz, a0 in ((hw - rc, hh - rc, 0.0), (-hw + rc, hh - rc, 90.0), (-hw + rc, -hh + rc, 180.0), (hw - rc, -hh + rc, 270.0)):
            corners.append([(cy + rc * math.cos(math.radians(a0 + 90.0 * i / (k - 1))), cz + rc * math.sin(math.radians(a0 + 90.0 * i / (k - 1)))) for i in range(k)])
        pts = []
        for c, arc in enumerate(corners):
            pts.extend(arc)
            a, b = arc[-1], corners[(c + 1) % 4][0]
            for j in range(1, 4):   # points along each straight edge, so the rim reads all round (the export's open-bell test)
                pts.append((a[0] + (b[0] - a[0]) * j / 4, a[1] + (b[1] - a[1]) * j / 4))
        return pts

    def loop_prism(secs):
        """a loft through rounded-rectangle loops [(x, [(y, z)])], open at both ends"""
        V, F = [], []
        m = len(secs[0][1])
        for x, lp in secs:
            V.extend((x, y, z) for (y, z) in lp)
        for j in range(len(secs) - 1):
            for i in range(m):
                a, b = j * m + i, j * m + (i + 1) % m
                F.append((a, b, b + m, a + m))
        return V, F
    hw, hh = w / 2, h / 2
    rc = min(hw, hh) * 0.42
    t = max(0.06, min(hw, hh) * 0.16)
    # the lip: a thick machined frame round the mouth, from the exit plane forward
    outer = rrect(hw + t, hh + t, rc + t); inner = rrect(hw, hh, rc)
    V1, F1 = loop_prism([(-0.02, outer), (t * 1.6, outer)])
    V2, F2 = loop_prism([(-0.02, inner), (t * 1.6, inner)])
    m = len(outer)
    V = V1 + V2; F = F1 + [tuple(x + len(V1) for x in f[::-1]) for f in F2]
    for i in range(m):   # the front face of the lip, outer loop to inner loop
        F.append((i + len(V1), (i + 1) % m + len(V1), (i + 1) % m, i))
    p.add('lip', 'body', 'htrim', (V, F))
    # the inner walls: tapering in from the mouth to the throat (the lining glows a dim blue so the dark lip reads)
    xt = depth
    tw = rrect(hw * throat + 0.02, hh * throat + 0.02, rc * throat)
    p.add('lining', 'body', 'hlining', loop_prism([(0.0, rrect(hw * 0.995, hh * 0.995, rc)), (xt, tw)]))
    # the throat plate, recessed at the back, and the guide vanes just ahead of it (all upstream of the exit plane)
    tp = rrect(hw * throat, hh * throat, rc * throat)
    V = [(xt + 0.01, y, z) for (y, z) in tp] + [(xt + 0.01, 0.0, 0.0)]
    F = [(len(tp), (i + 1) % len(tp), i) for i in range(len(tp))]
    p.add('throat', 'body', 'hnozzle', (V, F))
    for k in range(3):
        z = (k - 1) * hh * throat * 0.55
        p.add('vane%d' % k, 'body', 'hmetal', _zblock(xt * 0.62, xt * 0.97, -hw * throat * 0.98, hw * throat * 0.98, z - 0.018, z + 0.018))
    # the housing: the nozzle pod. A sleeve of four armoured walls round the lining from the lip back to the throat, a solid
    # block behind the throat that seats on the rail's end (the mount), two trim rings round it, machined side panels (R224)
    bh, bz = hw + t * 1.25, hh + t * 1.25
    x0s = t * 1.5
    for (y0, y1, z0, z1) in ((-bh, bh, hh + t * 0.2, bz), (-bh, bh, -bz, -hh - t * 0.2), (hw + t * 0.2, bh, -bz, bz), (-bh, -hw - t * 0.2, -bz, bz)):
        p.add('housing', 'mount', 'hgrey2', _zblock(x0s, xt + 0.02, y0, y1, z0, z1))
    p.add('housingback', 'mount', 'hgrey2', _zblock(xt + 0.02, body_len, -bh, bh, -bz, bz, ch=t * 0.5))
    # the trim bands are rings round the sleeve, open in the middle (R262, issue 780: as solid blocks their aft face closed the
    # nozzle mouth just inside the lip, so the throat and the vanes were never seen): each band is four bars round the walls,
    # their inner edge on the walls' inner face, so the mouth, the lining and the throat stay open
    ow, oz = bh + 0.035, bz + 0.035; iw, iz = hw + t * 0.2, hh + t * 0.2
    for k, xb in enumerate((x0s + 0.06, max(x0s + 0.3, body_len - 0.35))):
        p.add('band%d' % k, 'mount', 'htrim', _zblock(xb, xb + 0.12, -ow, ow, iz, oz, ch=0.03))
        p.add('band%d' % k, 'mount', 'htrim', _zblock(xb, xb + 0.12, -ow, ow, -oz, -iz))
        p.add('band%d' % k, 'mount', 'htrim', _zblock(xb, xb + 0.12, iw, ow, -iz, iz))
        p.add('band%d' % k, 'mount', 'htrim', _zblock(xb, xb + 0.12, -ow, -iw, -iz, iz))
    for s in (1, -1):   # machined side panels: the module grid carried onto the part (R224)
        for k in range(3):
            zc = (k - 1) * bz * 0.62
            xa_ = x0s + 0.26
            p.add('housingpanel%d%d' % (k, s > 0), 'mount', 'hpanel', _zblock(xa_, xa_ + min(0.5, body_len * 0.4), bh - 0.01 if s > 0 else -bh - 0.02,
                                                                              bh + 0.02 if s > 0 else -bh + 0.01, zc - bz * 0.26, zc + bz * 0.26, ch=0.01))
        p.add('housingtop%d' % (s > 0), 'mount', 'hpanel', _zblock(x0s + 0.26, x0s + 0.26 + min(0.5, body_len * 0.4), -bh * 0.8, bh * 0.8,
                                                                    s * bz - 0.01 if s > 0 else -bz - 0.02, bz + 0.02 if s > 0 else -bz + 0.01, ch=0.01))
    p.fit = dict(exit=P((0, 0, 0)), axis=D((-1, 0, 0)), radius=0.55 * (hw + hh), front=P((t * 1.2 + body_len, 0, 0)),
                 body_r=max(bh, bz), w=w, h=h)
    return p


# ---------------------------------------------------------------------------------------------------- guns
# R221 (Ryan, Nov 12: weapons "more unique per factions and fit the actual weapons they use per lore Bible and faction rules").
# Every Hegemony weapon is built from what it is: data.js W and FAC_WNAMES.hegemony (laser, turbo and hturbo carry the plasma
# trait, FAC_WTRAIT), the battle look in godot/fx/fx_weapons.gd (hturbo 'plasma': slow fat churning bolts with a corona; ion
# 'ion': a beam with crawling arcs; flak: Hegemony picket lasers), the lore bible 3.8 (Heavy plasma lance, light blue; Ion
# cannon; Picket lasers) and the faction sheet (low armoured mounts sunk into the shoulder armour, short thick barrels, R185 (4);
# the ion weapon a recessed emitter trench in a blunt bow face, R183 (1)).
WEAPONS = {
    'hturbo': dict(
        name='Heavy plasma lance', rules='data.js hturbo: 3 shots, 9 damage, range 6 (k battery); FAC_WTRAIT plasma',
        lore='Lore 3.8: the Heavy plasma lance (light blue). Battle look: plasma (slow fat churning bolts with a corona, splashing slag).',
        design=('A low wide armoured mount sunk in a shoulder pit (never a tall round turret with long thin barrels, R185 (4)): '
                'a flush ring, a faceted housing with a sloped glacis and armoured cheeks, a capacitor bustle with a blue charge '
                'strip, and two short thick containment barrels: a heavy breech sleeve, accelerator coil rings along the barrel '
                '(the plasma is held and pushed by fields), a vented muzzle shroud and a blue-lit bore.')),
    'ion': dict(
        name='Ion cannon', rules='data.js ion: 1 shot, 12 damage, range 6 (k lance), ion 2.7 (strips shields)',
        lore='Lore 3.1 and 1.4: ion tech reverse-engineered from the captured core Vyre; ion cannons strip shields. Battle look: ion (a beam with crawling arcs, a blue static wash).',
        design=('An emitter trench recessed in the blunt bow face (R183 (1): never a barrel or prongs on the nose): armoured '
                'walls lined with stacked field coil plates, an emitter block at the back of the trench with a blue lens where '
                'the beam forms, feed conduits along its floor.')),
    'turbo': dict(
        name='Plasma lance', rules='data.js turbo: 2 shots, 9 damage, range 5 (k battery); FAC_WTRAIT plasma',
        lore='Lore 3.8: the Plasma lance. Battle look: plasma (slow fat bolts with a corona), as the heavy lance.',
        design=('The heavy lance\'s mount at a smaller size (factions.md: the same parts repeated at different sizes): a low wide '
                'faceted housing with a sloped glacis, armoured cheeks, a capacitor bustle with a blue charge strip, two short thick '
                'containment barrels with coil rings, vented shrouds and blue-lit bores. Issue 768 (hegemony_IM5): on the midships '
                'bridge, turning all round (slot T).')),
    'flak': dict(
        name='Picket lasers', rules='data.js flak: 3 shots, 3 damage, range 2, point defence (vs squadrons x3)',
        lore='Lore 3.8: Picket lasers. Battle look: flak (airbursts in the Hegemony style).',
        design=('A small low eight-sided turret on a flush ring, a sensor eye in its face, two short emitter tubes with lens '
                'tips and cooling collars, elevating high (to 60) for craft. Twin: two emitters.')),
}


def _coil_barrel(p, tag, x0, L, cal, E, seg=12, coils=4):
    """one Hegemony containment barrel along +X from x0 under the frame E: a heavy breech sleeve, a thick barrel with accelerator
    coil rings, a vented muzzle shroud (eight-sided), a dark bore with a blue-lit lens deep in it. Returns the muzzle point."""
    xb = x0 + L * 0.3
    p.add('%sbreech' % tag, 'body', 'hgrey2', moved(revolve([(x0, cal * 1.7), (xb, cal * 1.7), (xb + cal * 0.4, cal * 1.25), (xb + cal * 0.4, 0.001)],
                                                           8, cap0=True, phase=math.pi / 8), E))
    xe = x0 + L
    xs = xe - cal * 2.2
    p.add('%sbarrel' % tag, 'body', 'hmetal', moved(revolve([(xb, cal * 1.08), (xs, cal * 1.0)], seg, phase=math.pi / seg), E))
    for i in range(coils):
        x = xb + cal * 0.7 + (xs - xb - cal * 1.3) * i / max(1, coils - 1)
        p.add('%scoil%d' % (tag, i), 'body', 'htrim', moved(ring_band(x, cal * 1.04, cal * 0.42, cal * 0.3, seg), E))
        p.add('%scoilglow%d' % (tag, i), 'body', 'hlens', moved(ring_band(x + cal * 0.3, cal * 1.03, cal * 0.08, cal * 0.12, seg), E))
    # the muzzle shroud: eight-sided, vented (four dark slots), its mouth a squared ring
    p.add('%smuzzle' % tag, 'body', 'hgrey2', moved(revolve([(xs, cal * 1.32), (xe - cal * 0.15, cal * 1.32), (xe, cal * 1.2), (xe, cal * 0.66),
                                                            (xs + cal * 0.4, cal * 0.66)], 8, closed=True, phase=math.pi / 8), E))
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        c, s_ = math.cos(a), math.sin(a)
        p.add('%svent%d' % (tag, k), 'body', 'dark', moved(block(xs + cal * 0.6, xe - cal * 0.6, cal * 0.12, cal * 0.06, 0,
                                                                 yo=c * cal * 1.3, zo=s_ * cal * 1.3), E))
    p.add('%sbore' % tag, 'body', 'dark', moved(revolve([(xs + cal * 0.42, 0.001), (xs + cal * 0.42, cal * 0.67)], 12), E))
    p.add('%slens' % tag, 'body', 'hlens', moved(revolve([(xs + cal * 0.5, cal * 0.5), (xs + cal * 0.56, 0.001)], 12, cap0=True), E))
    return Vector((xe, 0, 0))


def _lance_turret(p, barrels, cal, blen, s, pitch, variant):
    """the heavy plasma lance (data.js hturbo): a low wide armoured mount sunk in a shoulder pit. Local +Z up, +X the rest aim."""
    rr = 0.74 * s
    p.add('ring', 'mount', 'hgrey2', _zrev([(-0.3 * s, rr * 1.04), (0.06 * s, rr * 1.04), (0.06 * s, rr * 0.94), (0.08 * s, rr * 0.9),
                                           (0.08 * s, 0.001)], 16, cap0=True, phase=math.pi / 16))
    p.add('ringband', 'mount', 'htrim', _zrev([(-0.02 * s, rr * 1.03), (-0.02 * s, rr * 1.08), (0.05 * s, rr * 1.08), (0.05 * s, rr * 1.03)], 16, closed=True,
                                             phase=math.pi / 16))
    z0 = 0.08 * s
    # the housing: a faceted casemate in plan (eight sides, longer than wide), the glacis sloping up from the front, a flat roof
    L, W, H = 0.72 * s, 0.62 * s, 0.34 * s
    plan = [(L, W * 0.55), (L * 0.55, W), (-L * 0.6, W), (-L, W * 0.7), (-L, -W * 0.7), (-L * 0.6, -W), (L * 0.55, -W), (L, -W * 0.55)]
    V, F = _poly_prism(plan, z0, z0 + H, inset=0.0)
    # slope the glacis: the front top vertices pulled back and down
    V = [((x - 0.3 * s if (x > L * 0.5 and z > z0 + H * 0.5) else x), y, z) for (x, y, z) in V]
    p.add('housing', 'body', 'hgrey', (V, F))
    p.add('housingseam', 'body', 'hgrey2', _poly_prism([(x * 1.012, y * 1.012) for (x, y) in plan], z0 + H * 0.36, z0 + H * 0.42))
    # the armoured cheeks: a thicker plate on each side, chamfered, its top edge a step below the roof
    for sg in (1, -1):
        p.add('cheek%d' % (sg > 0), 'body', 'hpanel', _zblock(-L * 0.62, L * 0.5, sg * W * 0.86 if sg > 0 else -W * 1.08, W * 1.08 if sg > 0 else -W * 0.86,
                                                             z0 + 0.03 * s, z0 + H * 0.8, ch=0.02 * s))
    # the roof: a raised machined plate with a seam round it and a sight block
    p.add('roof', 'body', 'hpanel', _poly_prism([(x * 0.62 - 0.08 * s, y * 0.7) for (x, y) in plan], z0 + H - 0.005, z0 + H + 0.035 * s, inset=0.02 * s))
    p.add('sight', 'body', 'hgrey2', _zblock(-L * 0.55, -L * 0.25, W * 0.35, W * 0.62, z0 + H, z0 + H + 0.1 * s, ch=0.02 * s))
    p.add('sightlens', 'body', 'hlens', _zblock(-L * 0.25, -L * 0.24, W * 0.4, W * 0.57, z0 + H + 0.03 * s, z0 + H + 0.08 * s))
    # the capacitor bustle: stacked plates behind the housing with a blue charge strip between them
    for k in range(3):
        x = -L - 0.06 * s - k * 0.09 * s
        p.add('bustle%d' % k, 'body', 'hgrey2', _zblock(x - 0.06 * s, x, -W * 0.62, W * 0.62, z0 + 0.04 * s, z0 + H * 0.78, ch=0.015 * s))
    p.add('bustlecap', 'body', 'hgrey', _zblock(-L - 0.33 * s, -L - 0.26 * s, -W * 0.66, W * 0.66, z0 + 0.04 * s, z0 + H * 0.82, ch=0.02 * s))
    p.add('bustleglow', 'body', 'hblue', _zblock(-L - 0.27 * s, -L - 0.02 * s, -W * 0.55, W * 0.55, z0 + H * 0.5, z0 + H * 0.56))
    # the mantlet: a deep armoured block set in the glacis slot, carrying the barrels; it elevates about the trunnion
    trunnion = Vector((L * 0.5, 0, z0 + H * 0.48))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    gap = cal * 3.5
    mw = gap / 2 + cal * 1.9
    p.add('mantlet', 'body', 'hgrey2', moved(block(-0.18 * s, 0.14 * s, mw, H * 0.3, 0.03 * s), E))
    p.add('mantletface', 'body', 'htrim', moved(block(0.12 * s, 0.16 * s, mw * 0.92, H * 0.24, 0.02 * s), E))
    muzzles = []
    for i in range(barrels):
        off = (i - (barrels - 1) / 2) * gap
        T = E @ Matrix.Translation((0, off, 0))
        mz = _coil_barrel(p, 'b%d_' % i, 0.1 * s, blen, cal, T)
        muzzles.append(P(T @ mz))
    reach = trunnion.x + 0.1 * s + blen
    return trunnion, muzzles, reach, max(rr * 1.08, math.hypot(L + 0.33 * s, W)), E


def _picket(p, barrels, cal, blen, s, pitch, variant):
    """the picket lasers (data.js flak): a small low eight-sided turret, a sensor eye, two short emitter tubes"""
    rr = 0.42 * s
    p.add('ring', 'mount', 'hgrey2', _zrev([(-0.22 * s, rr * 1.06), (0.07 * s, rr * 1.06), (0.07 * s, rr * 0.95), (0.09 * s, rr * 0.9),
                                           (0.09 * s, 0.001)], 16, cap0=True, phase=math.pi / 16))
    p.add('ringband', 'mount', 'htrim', _zrev([(-0.01 * s, rr * 1.05), (-0.01 * s, rr * 1.1), (0.05 * s, rr * 1.1), (0.05 * s, rr * 1.05)], 16, closed=True))
    z0 = 0.09 * s
    R = rr * 0.92
    p.add('housing', 'body', 'hgrey', _zrev([(z0, R), (z0 + 0.16 * s, R), (z0 + 0.24 * s, R * 0.78), (z0 + 0.24 * s, 0.001)], 8, phase=math.pi / 8))
    p.add('housingseam', 'body', 'hgrey2', _zrev([(z0 + 0.07 * s, R * 0.995), (z0 + 0.07 * s, R * 1.03), (z0 + 0.1 * s, R * 1.03), (z0 + 0.1 * s, R * 0.995)],
                                                 8, closed=True, phase=math.pi / 8))
    p.add('roofplate', 'body', 'hpanel', _zrev([(z0 + 0.235 * s, R * 0.55), (z0 + 0.27 * s, R * 0.5), (z0 + 0.27 * s, 0.001)], 8, phase=math.pi / 8))
    zc = z0 + 0.13 * s
    trunnion = Vector((R * 0.55, 0, zc))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    gap = cal * 3.0
    p.add('mantlet', 'body', 'hgrey2', moved(block(-0.1 * s, 0.1 * s, gap / 2 + cal * 1.4, 0.07 * s, 0.02 * s), E))
    p.add('eye', 'body', 'hlens', moved(block(0.1 * s, 0.11 * s, cal * 0.8, cal * 0.8, 0, zo=0.05 * s), E))
    muzzles = []
    for i in range(barrels):
        off = (i - (barrels - 1) / 2) * gap
        T = E @ Matrix.Translation((0, off, 0))
        x0 = 0.08 * s; xe = x0 + blen
        p.add('b%d_barrel' % i, 'body', 'hmetal', moved(revolve([(x0, cal * 1.0), (xe - cal * 0.8, cal * 0.9)], 10), T))
        p.add('b%d_coil' % i, 'body', 'htrim', moved(ring_band(x0 + blen * 0.35, cal * 0.98, cal * 0.5, cal * 0.25, 10), T))
        p.add('b%d_muzzle' % i, 'body', 'hgrey2', moved(revolve([(xe - cal * 0.8, cal * 1.25), (xe, cal * 1.25), (xe, cal * 0.55), (xe - cal * 0.5, cal * 0.55)],
                                                                10, closed=True), T))
        p.add('b%d_bore' % i, 'body', 'dark', moved(revolve([(xe - cal * 0.5, 0.001), (xe - cal * 0.5, cal * 0.56)], 10), T))
        p.add('b%d_lens' % i, 'body', 'hlens', moved(revolve([(xe - cal * 0.45, cal * 0.45), (xe - cal * 0.42, 0.001)], 10, cap0=True), T))
        muzzles.append(P(T @ Vector((xe, 0, 0))))
    return trunnion, muzzles, trunnion.x + 0.08 * s + blen, rr * 1.1, E


# issue 768: the Plasma lance (data.js turbo, 2 shots) is the same lance turret at a smaller size (factions.md: the same parts
# repeated at different sizes across the fleet)
GUN_BUILDERS = {'hturbo': _lance_turret, 'turbo': _lance_turret, 'flak': _picket}


def gun(barrels=1, cal=0.12, blen=1.6, size=1.0, mount='turret', pitch=0.0, variant=0, seg=12, weapon='hturbo'):
    """a Hegemony weapon mount, built from the weapon it carries (data.js id hturbo or flak; the ion cannon is the bow trench,
    spinal() below). Origin on the hull surface at the mount centre, local +Z the mount normal, +X the rest aim. Fixed pieces are
    'mount'; a turret's turning pieces are 'turn' (R219)."""
    fn = GUN_BUILDERS[weapon]
    assert mount == 'turret', 'the Hegemony plasma lance and picket lasers are turrets (the ion cannon is the bow trench)'
    p = Part('gun')
    trunnion, muzzles, reach, radius, E = fn(p, barrels, cal, blen, size, pitch, variant)
    for c in p.comps:
        if c['role'] == 'body':
            c['role'] = 'turn'
    p.fit = dict(pivot=P((0, 0, trunnion.z)), trunnion=P(trunnion), muzzles=muzzles, reach=reach,
                 aim=D(E.to_3x3() @ Vector((1, 0, 0))), up=D((0, 0, 1)), mount=mount, radius=radius)
    return p


def spinal(length, r=0.5, w=1.3, h=0.7, coils=6, **kw):
    """the ion cannon's emitter trench (data.js ion, slot F): origin at the trench's back wall on the axis, +X forward out of the
    bow face; length is the trench's depth to the bow face. w, h: the trench mouth (local Y and Z). The walls are lined (the
    liners are mounts: they sit against the hull's trench walls), stacked field coil plates stand on the walls, the emitter block
    sits on the back wall with a blue lens on its face where the beam forms (the muzzle: on the emitter's own mesh, E11's export
    lesson), two feed conduits run along the floor. The fit pivot and the firing lane start at the mouth, so the arc rays leave
    the trench clear of the bow face."""
    p = Part('spinal')
    p.type = 'ion_trench'
    hw, hh = w / 2, h / 2
    lt = 0.05
    # wall liners (top, bottom, port, starboard), flush with the hull's trench walls
    p.add('liner_top', 'mount', 'hgrey2', _zblock(0.0, length, -hw, hw, hh - lt, hh + 0.01))
    p.add('liner_bottom', 'mount', 'hgrey2', _zblock(0.0, length, -hw, hw, -hh - 0.01, -hh + lt))
    for sg in (1, -1):
        p.add('liner_side%d' % (sg > 0), 'mount', 'hgrey2', _zblock(0.0, length, sg * (hw - lt) if sg > 0 else -hw - 0.01, hw + 0.01 if sg > 0 else -(hw - lt),
                                                                    -hh, hh))
    # field coil plates: thin frames standing proud of the walls round the trench at an even pitch (the field that shapes the beam)
    for k in range(coils):
        x = length * (0.28 + 0.62 * k / max(1, coils - 1))
        ct = 0.05
        p.add('coil%d_t' % k, 'body', 'htrim', _zblock(x - 0.03, x + 0.03, -hw + lt, hw - lt, hh - lt - ct, hh - lt))
        p.add('coil%d_b' % k, 'body', 'htrim', _zblock(x - 0.03, x + 0.03, -hw + lt, hw - lt, -hh + lt, -hh + lt + ct))
        for sg in (1, -1):
            y0, y1 = (hw - lt - ct, hw - lt) if sg > 0 else (-hw + lt, -hw + lt + ct)
            p.add('coil%d_s%d' % (k, sg > 0), 'body', 'htrim', _zblock(x - 0.03, x + 0.03, y0, y1, -hh + lt, hh - lt))
        p.add('coilglow%d' % k, 'body', 'hlens', _zblock(x + 0.03, x + 0.045, -hw + lt + 0.01, hw - lt - 0.01, hh - lt - 0.025, hh - lt - 0.012))
    # the emitter block on the back wall: a stepped machined block, a blue lens on its face, a seam ring round the lens
    ex = length * 0.24
    p.add('emitter', 'mount', 'hmetal', _zblock(-0.02, ex, -hw * 0.62, hw * 0.62, -hh * 0.62, hh * 0.62, ch=0.04))
    p.add('emitterstep', 'body', 'hgrey2', _zblock(ex - 0.01, ex + 0.05, -hw * 0.46, hw * 0.46, -hh * 0.46, hh * 0.46, ch=0.02))
    p.add('lens', 'body', 'hlens', moved(revolve([(ex + 0.05, min(hw, hh) * 0.36), (ex + 0.08, min(hw, hh) * 0.3), (ex + 0.1, 0.001)], 16, cap0=True),
                                        Matrix.Identity(4)))
    for sg in (1, -1):
        p.add('conduit%d' % (sg > 0), 'mount', 'hmetal', rod((ex, sg * hw * 0.7, -hh + lt + 0.04), (length * 0.94, sg * hw * 0.7, -hh + lt + 0.04), 0.035, 6))
    mz = (ex + 0.1, 0, 0)
    p.fit = dict(muzzles=[P(mz)], pivot=P((length + 0.05, 0, 0)), trunnion=P((length + 0.05, 0, 0)), reach=0.1, aim=D((1, 0, 0)), up=D((0, 0, 1)),
                 mount='spinal', radius=max(hw, hh), bore=min(hw, hh) * 0.36, lane_from=P((length + 0.05, 0, 0)))
    return p


# ---------------------------------------------------------------------------------------------------- the sensor fin
def antenna(h, whips=0, L=2.4, t=0.34):
    """the one low sensor fin (factions.md: "One low sensor fin, not a tower"): origin on the deck at the fin's middle, +X
    forward, +Z up. A swept armoured fin, low and long (h tall, L long at the root, t thick), its leading edge raked back, a
    root plinth (the mount), a recessed sensor window strip along each face, a lens strip on the leading edge, a seam band."""
    p = Part('antenna')
    p.add('root', 'mount', 'hgrey2', _zblock(-L * 0.58, L * 0.55, -t * 0.85, t * 0.85, -0.2, 0.08, ch=0.04))
    # the fin: a tapered prism in side view (leading edge raked, trailing edge near upright), its top narrower
    top_len = L * 0.42
    sec = [(L * 0.5, 0.06), (-L * 0.5, 0.06), (-L * 0.42, h), (-L * 0.42 + top_len, h)]
    V, F = [], []
    for (x, z) in sec:
        k = 1.0 - 0.45 * (z / h)
        V += [(x, t / 2 * k, z), (x, -t / 2 * k, z)]
    F = [(0, 2, 4, 6), (7, 5, 3, 1), (0, 1, 3, 2), (2, 3, 5, 4), (4, 5, 7, 6), (6, 7, 1, 0)]
    p.add('fin', 'body', 'hgrey', (V, F))
    for sg in (1, -1):
        p.add('window%d' % (sg > 0), 'body', 'hwin', _zblock(-L * 0.3, L * 0.1, sg * t * 0.38 if sg > 0 else -t * 0.43, t * 0.43 if sg > 0 else -t * 0.38,
                                                            h * 0.42, h * 0.56))
        p.add('finpanel%d' % (sg > 0), 'body', 'hpanel', _zblock(-L * 0.38, L * 0.2, sg * t * 0.4 if sg > 0 else -t * 0.46, t * 0.46 if sg > 0 else -t * 0.4,
                                                                h * 0.12, h * 0.34))
    p.add('band', 'body', 'htrim', _zblock(-L * 0.47, L * 0.47, -t * 0.47, t * 0.47, h * 0.66, h * 0.71))
    p.add('lens', 'body', 'hlens', _zblock(-L * 0.36, -L * 0.36 + top_len * 0.85, -t * 0.12, t * 0.12, h - 0.005, h + 0.02))
    p.fit = dict(top=P((0, 0, h)))
    return p


# ---------------------------------------------------------------------------------------------------- small parts
def bay(w, l):
    """flush armoured drone doors (R232, pack.md question 2: flush armoured doors on the Dominion, a seam line only on the intact
    ship, opening in the break state): local +Z out of the hull, +X along the doors. A machined frame flush with the deck, two
    door leaves meeting on a centre seam, the hinge lines dark, a row of guide lamps (blue) along each side."""
    p = Part('bay')
    fr = 0.08
    p.add('frame', 'mount', 'htrim', _zblock(-l / 2 - fr, l / 2 + fr, -w / 2 - fr, w / 2 + fr, -0.05, 0.02))
    for sg in (1, -1):
        p.add('door%d' % (sg > 0), 'body', 'hgrey', _zblock(-l / 2, l / 2, 0.012 if sg > 0 else -w / 2, w / 2 if sg > 0 else -0.012, 0.02, 0.05, ch=0.012))
        for k in range(4):
            x = -l / 2 + l * (k + 0.5) / 4
            p.add('doorrib%d%d' % (k, sg > 0), 'body', 'hpanel', _zblock(x - 0.05, x + 0.05, sg * w * 0.08 if sg > 0 else -w * 0.44, w * 0.44 if sg > 0 else -w * 0.08,
                                                                        0.05, 0.065))
        for k in range(5):
            x = -l / 2 + l * (k + 0.5) / 5
            p.add('lamp%d%d' % (k, sg > 0), 'body', 'hblue', _zblock(x - 0.04, x + 0.04, sg * (w / 2 + fr * 0.3) - 0.025, sg * (w / 2 + fr * 0.3) + 0.025, 0.02, 0.035))
    p.add('seam', 'body', 'dark', _zblock(-l / 2, l / 2, -0.012, 0.012, 0.02, 0.03))
    return p


def latch(n=4, pitch=0.24, w=0.16):
    """a module latch row: the clamp heads that lock two hull modules together across a module band (H10's rows of four
    rounded blocks): local +Z out of the hull, +X across the band. A low base plate, n machined clamp heads at an even pitch."""
    p = Part('latch')
    span = (n - 1) * pitch
    p.add('base', 'mount', 'hgrey2', _zblock(-w * 0.9, w * 0.9, -span / 2 - w * 0.8, span / 2 + w * 0.8, -0.04, 0.025, ch=0.012))
    for k in range(n):
        y = -span / 2 + pitch * k
        p.add('clamp%d' % k, 'body', 'hmetal', _zblock(-w * 0.55, w * 0.55, y - w * 0.4, y + w * 0.4, 0.02, 0.085, ch=0.025))
    return p


def hatch(w, h, round_=False, wheel=False):
    """a flush rectangular armoured hatch (local +Z out): a machined rim, a door flush within it with a seam, a recessed grip"""
    p = Part('hatch')
    hw, hh = w / 2, (h or w) / 2
    p.add('rim', 'mount', 'htrim', _zblock(-hh - 0.05, hh + 0.05, -hw - 0.05, hw + 0.05, -0.04, 0.02, ch=0.01))
    p.add('seam', 'body', 'dark', _zblock(-hh, hh, -hw, hw, 0.015, 0.022))
    p.add('door', 'body', 'hgrey', _zblock(-hh + 0.012, hh - 0.012, -hw + 0.012, hw - 0.012, 0.02, 0.04, ch=0.01))
    p.add('grip', 'body', 'hgrey2', _zblock(-hh * 0.15, hh * 0.15, -hw * 0.55, hw * 0.55, 0.04, 0.052))
    return p


def hatchbox(w, l, h, fins=0):
    """a module housing on the deck (a lift head or an equipment housing): a chamfered frame block, an inset lid with a seam"""
    p = Part('hatchbox')
    p.add('frame', 'mount', 'hgrey2', block(-l / 2, l / 2, w / 2, h / 2, h * 0.25, zo=h / 2 - 0.05, taper=0.94, ztaper=0.96))
    p.add('lid', 'body', 'hpanel', block(-l * 0.4, l * 0.36, w * 0.38, 0.03, 0.02, zo=h * 0.93))
    p.add('seam', 'body', 'dark', block(-l * 0.42, l * 0.38, w * 0.4, 0.012, 0.0, zo=h * 0.9))
    p.add('lidstrip', 'body', 'hblue', block(l * 0.37, l * 0.39, w * 0.3, 0.012, 0.0, zo=h * 0.92))
    return p


def container(l, w, h, ribs=3):
    """a cargo module (issue 1413, the Convoy transport: designs.md "FOUR identical container modules ... plain slab sides,
    mooring clamps"): origin at the middle of its floor, +X along the ship (l), +Y across (w), +Z up (h). A plain chamfered slab
    box sitting in the cargo well (the mount), an inset lid with a seam round it, flat stiffener ribs up the fore and aft faces,
    corner castings, and mooring clamps at the foot of each face that lock it to the well floor."""
    p = Part('container')
    p.add('frame', 'mount', 'hgrey', _zblock(-l / 2, l / 2, -w / 2, w / 2, 0.0, h, ch=0.04))
    p.add('seam', 'body', 'dark', _zblock(-l / 2 + 0.045, l / 2 - 0.045, -w / 2 + 0.045, w / 2 - 0.045, h - 0.01, h + 0.006))
    p.add('lid', 'body', 'hpanel', _zblock(-l / 2 + 0.06, l / 2 - 0.06, -w / 2 + 0.06, w / 2 - 0.06, h - 0.01, h + 0.016, ch=0.008))
    for k in range(ribs):
        y = -w / 2 + w * (k + 1) / (ribs + 1)
        for sx in (1, -1):
            x0, x1 = (l / 2 - 0.01, l / 2 + 0.022) if sx > 0 else (-l / 2 - 0.022, -l / 2 + 0.01)
            p.add('rib%d%s' % (k, 'f' if sx > 0 else 'a'), 'body', 'hgrey2', _zblock(x0, x1, y - 0.03, y + 0.03, 0.07, h - 0.07))
    for sy in (1, -1):
        for sx in (1, -1):
            cx, cy = sx * (l / 2 - 0.035), sy * (w / 2 - 0.035)
            p.add('clampc%s%s' % ('f' if sx > 0 else 'a', 'p' if sy > 0 else 's'), 'body', 'htrim', _zblock(cx - 0.05, cx + 0.05, cy - 0.05, cy + 0.05, h - 0.02, h + 0.03))
            x0, x1 = (l / 2, l / 2 + 0.07) if sx > 0 else (-l / 2 - 0.07, -l / 2)
            yc = sy * (w / 2 - 0.22)
            p.add('clamp%s%s' % ('f' if sx > 0 else 'a', 'p' if sy > 0 else 's'), 'body', 'hmetal', _zblock(x0, x1, yc - 0.08, yc + 0.08, 0.0, 0.16, ch=0.02))
    return p


def relay_lens(half, r, depth, steps=5, ch=0.2, n=32):
    """the Relay beacon's lens (issue 1413; designs.md: ONE oversized recessed blue lens in the module's forward face, stepped
    machined rings, NO muzzle lip, no capacitor trench, a thin blue ring at its base): origin at the middle of the face's back,
    local +Z out of the face (a surface part, like the vent). A square face block (half-width `half`, its corners chamfered by ch) `depth` deep with a round mouth of
    radius r; inside it machined rings step down toward a glowing blue lens at the back; a thin blue ring round the mouth; four
    bolt bosses in the face's corners."""
    p = Part('relay_lens')
    angs = [2 * math.pi * i / n + math.pi / n for i in range(n)]

    def sq(a):
        c, s_ = math.cos(a), math.sin(a)
        t = min(half / max(abs(c), 1e-9), half / max(abs(s_), 1e-9), (2 * half - ch) / max(abs(c) + abs(s_), 1e-9))
        return (t * c, t * s_)
    outer = [sq(a) for a in angs]
    inner = [(r * math.cos(a), r * math.sin(a)) for a in angs]
    x0, x1 = 0.0, depth
    V = [(x0, y, z) for (y, z) in outer] + [(x1, y, z) for (y, z) in outer] + [(x0, y, z) for (y, z) in inner] + [(x1, y, z) for (y, z) in inner]
    F = []
    for i in range(n):
        j = (i + 1) % n
        F.append((i, j, n + j, n + i)); F.append((2 * n + j, 2 * n + i, 3 * n + i, 3 * n + j))
        F.append((j, i, 2 * n + i, 2 * n + j)); F.append((n + i, n + j, 3 * n + j, 3 * n + i))
    p.add('face', 'mount', 'hgrey', (V, F))
    # the stepped machined rings, each a little smaller and deeper, down to the lens
    prof = []
    for k in range(steps):
        rr = r * (1.0 - 0.1 * k)
        xa = x1 - depth * 0.65 * k / steps
        xb = x1 - depth * 0.65 * (k + 1) / steps
        prof += [(xa, rr), (xb + 0.02, rr), (xb + 0.02, rr * 0.93)]
    rlast = prof[-1][1]
    p.add('ring', 'mount', 'hmetal', revolve([(x1, r * 1.001)] + prof + [(prof[-1][0] - 0.03, rlast), (prof[-1][0] - 0.03, rlast + 0.06), (x1 - 0.002, r + 0.06)],
                                               n, closed=True, phase=math.pi / n))
    xl = prof[-1][0] - 0.01
    # the lens: a deep blue dish (the dimmer lining blue, so the rings read) round a small bright core
    p.add('lens', 'body', 'hlining', revolve([(xl, rlast * 0.98), (xl + rlast * 0.08, rlast * 0.7), (xl + rlast * 0.1, rlast * 0.36), (xl + rlast * 0.1, 0.001)],
                                             n, cap0=True, phase=math.pi / n))
    p.add('lens_core', 'body', 'hblue', revolve([(xl + rlast * 0.09, rlast * 0.34), (xl + rlast * 0.2, rlast * 0.26), (xl + rlast * 0.27, 0.001)], n, cap0=True, phase=math.pi / n))
    p.add('glow', 'body', 'hblue', ring_band(x1 - 0.03, r * 0.985, 0.03, r * 0.025, n))
    for (yy, zz) in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        c = (half - ch * 0.9) * 0.92
        p.add('face_boss%d%d' % (yy > 0, zz > 0), 'mount', 'dark', moved(revolve([(x1 - 0.01, 0.1), (x1 + 0.03, 0.1), (x1 + 0.04, 0.07), (x1 + 0.04, 0.001)], 12),
                                                                         Matrix.Translation((0, yy * c, zz * c))))
    p.transform(Matrix.Rotation(-math.pi / 2, 4, 'Y'))   # built along +X, turned so the face looks along local +Z
    p.fit = dict(exits=[], radius=r)
    return p


def vent(w, h, slats=5, depth=0.08):
    """a heat louvre (local +Z out): a machined frame and straight slats over a dark recess (never warm light)"""
    p = Part('vent')
    fr = 0.05
    p.add('back', 'mount', 'dark', block(-0.03, 0.01, w / 2, h / 2, 0))
    for (yo, zo, hw, hh) in ((0, h / 2 - fr / 2, w / 2, fr / 2), (0, -h / 2 + fr / 2, w / 2, fr / 2), (w / 2 - fr / 2, 0, fr / 2, h / 2), (-w / 2 + fr / 2, 0, fr / 2, h / 2)):
        p.add('frame', 'mount', 'htrim', block(-0.02, depth, hw, hh, 0, yo=yo, zo=zo))
    for i in range(slats):
        z = -h / 2 + fr + (h - 2 * fr) * (i + 0.5) / slats
        p.add('slat%d' % i, 'body', 'hgrey', block(depth * 0.15, depth * 0.85, w / 2 - fr, 0.014, 0, zo=z))
    for c in p.comps:
        c['verts'] = [Vector((-v.z, v.y, v.x)) for v in c['verts']]
    return p


def lamp(r=0.08, hood=True):
    """a small blue strip lamp (local +Z out); the Hegemony has no separate running lights (paint direction 5: the strips are
    the running lights), so sheets use strips; kept for the sheet kit's lamp helper"""
    p = Part('lamp')
    p.add('housing', 'mount', 'hgrey2', block(-r * 1.6, r * 1.6, r * 0.8, r * 0.3, r * 0.1, zo=r * 0.15))
    p.add('lens', 'body', 'hblue', block(-r * 1.3, r * 1.3, r * 0.5, r * 0.08, 0, zo=r * 0.45))
    return p


def slit(w, h, depth=0.06, fr=0.035, back=0.02, pane=0.006):
    """a blue-white window slit (local +Z out; lore 3.3: blue-white windows): a machined frame round a recessed pane. fr, the
    frame's width, back and pane its setbacks (issue 793: a craft passes smaller ones; the defaults keep every capital sheet as it was)"""
    p = Part('slit')
    for (yo, zo, hw, hh) in ((0, h / 2 + fr / 2, w / 2 + fr, fr / 2), (0, -h / 2 - fr / 2, w / 2 + fr, fr / 2), (w / 2 + fr / 2, 0, fr / 2, h / 2), (-w / 2 - fr / 2, 0, fr / 2, h / 2)):
        p.add('frame', 'mount', 'htrim', block(-back, depth, hw, hh, 0, yo=yo, zo=zo))
    p.add('glass', 'body', 'hwin', block(pane, depth * 0.3, w / 2, h / 2, 0))
    for c in p.comps:
        c['verts'] = [Vector((-v.z, v.y, v.x)) for v in c['verts']]
    return p


def thruster(r=0.3, nozzles=2):
    """an attitude or retro thruster (local +Z out; lore 3.4: retro thrusters make backing off cheap): a machined block with
    rectangular nozzle throats that have depth (R244: an opening is never a flat disc), a lip and a dark bore with a blue glow"""
    p = Part('thruster')
    p.add('block', 'mount', 'hgrey2', block(-r, r, r * 0.75, r * 0.3, r * 0.1, zo=r * 0.15))
    for i in range(nozzles):
        y = (i - (nozzles - 1) / 2) * r * 0.78
        q = Matrix.Translation((0, y, 0))
        # the nozzle: a squared lip standing on the block, a dark bore inside it, a dim blue throat at the bottom
        for (yo, xo, hy, hx) in ((r * 0.28, 0, r * 0.05, r * 0.42), (-r * 0.28, 0, r * 0.05, r * 0.42), (0, r * 0.37, r * 0.33, r * 0.05), (0, -r * 0.37, r * 0.33, r * 0.05)):
            p.add('nozzle%d' % i, 'body', 'hmetal', moved(_zblock(xo - hx, xo + hx, yo - hy, yo + hy, r * 0.42, r * 0.6), q))
        p.add('nozzlebore%d' % i, 'body', 'dark', moved(_zblock(-r * 0.32, r * 0.32, -r * 0.23, r * 0.23, r * 0.43, r * 0.44), q))
        p.add('nozzleglow%d' % i, 'body', 'hlining', moved(_zblock(-r * 0.2, r * 0.2, -r * 0.12, r * 0.12, r * 0.44, r * 0.445), q))
    for c in p.comps:
        c['verts'] = [Vector((v.y, v.x, v.z)) for v in c['verts']]
    p.fit = dict(out=D((0, 0, 1)))
    return p


# ---------------------------------------------------------------------------------------------------- canyon machinery
# Issue 768 (hegemony_IM5, the Iron Mandate): the armoured canyon down the spine carries the ship's heavy plant in the open,
# shielded by the canyon walls: power trunks from the reactor to the ion cannon and the drives, the ion cannon's capacitor
# banks, the reactor's heat exchangers. Every piece has a job (R221); the banks and exchangers are machines (MACHINES) and sit
# whole inside one module; the trunks are structure and stop at a flanged coupling short of every module band.
def pipe(pts, r=0.16, pitch=0.6):
    """an armoured power trunk along the world points pts (the sheet kit emits it with no transform): an eight-sided trunk,
    trim collars at an even pitch, a flange at each end, saddles under it every ~1.2 down to the floor it lies on (the mount)"""
    p = Part('pipe')
    pts = [Vector(q) for q in pts]
    for k, (a, b) in enumerate(zip(pts, pts[1:])):
        d = b - a; L = d.length
        if L < 1e-4:
            continue
        up = Vector((0, 0, 1)) if abs(d.normalized().z) < 0.9 else Vector((1, 0, 0))
        M = frame(a, d, up)
        p.add('trunk%d' % k, 'body', 'hgrey2', moved(revolve([(0, r), (L, r)], 8, cap0=True, cap1=True, phase=math.pi / 8), M))
        n = max(1, int(L / pitch))
        for i in range(n):
            x = L * (i + 0.5) / n
            p.add('collar%d_%d' % (k, i), 'body', 'htrim', moved(ring_band(x, r, 0.08, 0.035, 8), M))
        ns = max(1, int(round(L / 1.2)))
        for i in range(ns):
            x = L * (i + 0.5) / ns
            p.add('saddle%d_%d' % (k, i), 'mount', 'hgrey2', moved(block(x - 0.07, x + 0.07, r * 0.9, r * 0.55 + 0.09, 0.02, zo=-r * 0.55 - 0.07), M))
    for k, (q, d) in enumerate(((pts[0], pts[1] - pts[0]), (pts[-1], pts[-2] - pts[-1]))):
        M = frame(q, d, Vector((0, 0, 1)))
        p.add('flange%d' % k, 'body', 'hmetal', moved(revolve([(0.0, r * 1.45), (0.07, r * 1.45), (0.07, r * 0.4), (0.0, r * 0.4)], 8, closed=True, phase=math.pi / 8), M))
        p.add('flangecap%d' % k, 'body', 'hgrey2', moved(revolve([(-0.06, r * 1.2), (0.0, r * 1.2)], 8, cap0=True, phase=math.pi / 8), M))
    return p


def capbank(n=4, l=2.0, w=1.2, h=0.55):
    """a capacitor bank (the ion cannon's charge banks): local +Z up, +X along the bank. A machined plinth (the mount), n
    identical cells in a row (factions.md Inside: racks of identical equipment), each with a trim cap and a blue charge strip, a
    bus bar along the caps, terminal blocks at both ends"""
    p = Part('capbank')
    p.add('base', 'mount', 'hgrey2', _zblock(-l / 2, l / 2, -w / 2, w / 2, -0.04, 0.08, ch=0.03))
    pitch = (l - 0.24) / n
    for k in range(n):
        x0 = -l / 2 + 0.12 + pitch * k + 0.03; x1 = x0 + pitch - 0.06
        p.add('cell%d' % k, 'body', 'hgrey', _zblock(x0, x1, -w * 0.42, w * 0.42, 0.08, h - 0.06, ch=0.04))
        p.add('cap%d' % k, 'body', 'htrim', _zblock(x0 + 0.04, x1 - 0.04, -w * 0.36, w * 0.36, h - 0.07, h - 0.02, ch=0.015))
        for sg in (1, -1):
            yy = sg * w * 0.42
            p.add('strip%d%d' % (k, sg > 0), 'body', 'hblue', _zblock(x0 + 0.06, x1 - 0.06, yy - 0.012, yy + 0.012, h * 0.55, h * 0.62))
            p.add('cellrib%d%d' % (k, sg > 0), 'body', 'hpanel', _zblock(x0 + 0.05, x1 - 0.05, yy - 0.02 if sg > 0 else yy - 0.004, yy + 0.004 if sg > 0 else yy + 0.02, 0.14, h * 0.45))
    for sg in (1, -1):
        p.add('bus%d' % (sg > 0), 'body', 'hmetal', rod((-l / 2 + 0.1, sg * w * 0.18, h - 0.005), (l / 2 - 0.1, sg * w * 0.18, h - 0.005), 0.035, 6))
        p.add('terminal%d' % (sg > 0), 'body', 'hmetal', _zblock(sg * (l / 2 - 0.1) - 0.06, sg * (l / 2 - 0.1) + 0.06, -w * 0.3, w * 0.3, 0.08, h + 0.02, ch=0.02))
    return p


def exchanger(l=1.4, w=1.2, h=0.6, fins=9):
    """a heat exchanger (the reactor's coolant plant, in the canyon so its heat leaves the hull): local +Z up, +X along it. A
    plinth (the mount), a chamfered housing, a stack of cooling fin plates across its top in a trim frame, an inlet and an outlet
    port at its ends"""
    p = Part('exchanger')
    p.add('base', 'mount', 'hgrey2', _zblock(-l / 2, l / 2, -w / 2, w / 2, -0.04, 0.08, ch=0.03))
    p.add('housing', 'body', 'hgrey', _zblock(-l * 0.46, l * 0.46, -w * 0.44, w * 0.44, 0.08, h * 0.55, ch=0.05))
    for sg in (1, -1):
        p.add('frame%d' % (sg > 0), 'body', 'htrim', _zblock(-l * 0.44, l * 0.44, sg * w * 0.36 - 0.03, sg * w * 0.36 + 0.03, h * 0.55, h))
        p.add('frameend%d' % (sg > 0), 'body', 'htrim', _zblock(sg * l * 0.42 - 0.03, sg * l * 0.42 + 0.03, -w * 0.36, w * 0.36, h * 0.55, h))
    for k in range(fins):
        x = -l * 0.38 + l * 0.76 * k / max(1, fins - 1)
        p.add('fin%d' % k, 'body', 'hmetal', _zblock(x - 0.012, x + 0.012, -w * 0.33, w * 0.33, h * 0.55, h - 0.03))
    p.add('finglow', 'body', 'dark', _zblock(-l * 0.4, l * 0.4, -w * 0.33, w * 0.33, h * 0.55, h * 0.57))
    for sg in (1, -1):
        x = sg * l * 0.46
        p.add('port%d' % (sg > 0), 'body', 'hmetal', moved(revolve([(0.0, 0.11), (0.12, 0.11), (0.12, 0.14), (0.17, 0.14)], 8, cap1=True),
                                                            Matrix.Translation((x, 0, h * 0.32)) @ (Matrix.Identity(4) if sg > 0 else Matrix.Rotation(math.pi, 4, 'Z'))))
    return p


# ---------------------------------------------------------------------------------------------------- squadron craft
# Issue 793 (R253, R259): the Hegemony fighter, hegemony_HF1D (data.js fighter: guns T). A craft is about a twentieth of the
# Iron Mandate's length, so every size below comes from its arguments (no fixed world sizes), and it stays bold and simple:
# fine greeble reads as a shrunken capital ship. Ryan (R254): no canopy, no swept aero wings, no tail fins, nothing hung under
# a hull; drives are nozzle clusters inside armoured blocks.
WEAPONS['guns'] = dict(
    name='Interceptor guns', rules='data.js guns: 3 shots, 4 damage, range 1 (k sq), x2.2 against squadrons, x0.5 against capitals',
    lore='Lore 3.8: Hegemony weapons are plasma in light blue, machined and modular. The fighter wing\'s only weapon. Battle look: guns.',
    design=('The gun cassette (HF1D): three short containment barrels grouped tight in one machined box, so the three muzzles read '
            'as one cassette, not three guns; coil rings, light-blue lenses deep in the bores. The cassette sits in a low flat '
            'housing on a flush ring sunk in a framed recess at the prow (the concept\'s framed recess), so it turns all round '
            '(arc T) and at rest faces forward out of its frame.'))


def _cassette(p, barrels, cal, blen, s, pitch, variant):
    """the interceptor gun cassette (data.js guns): s the flush ring's radius, cal a barrel's radius, blen the barrels' reach from
    the trunnion. Local +Z out of the deck, +X the rest aim. The framed recess is fixed (mount); the housing, the mantlet and the
    cassette turn (R219)."""
    ph = math.pi / 16
    p.add('ring', 'mount', 'hgrey2', _zrev([(-0.6 * s, s), (0.06 * s, s), (0.06 * s, s * 0.92), (0.09 * s, s * 0.88), (0.09 * s, 0.001)], 16, cap0=True, phase=ph))
    # the framed recess: a squared machined frame round the ring, flush with the deck (four bars and their inner liners)
    fo, fi = 1.36 * s, 1.1 * s
    for (x0, x1, y0, y1) in ((fi, fo, -fo, fo), (-fo, -fi, -fo, fo), (-fi, fi, fi, fo), (-fi, fi, -fo, -fi)):
        p.add('wellframe', 'mount', 'htrim', _zblock(x0, x1, y0, y1, -0.35 * s, 0.1 * s, ch=0.04 * s))
    p.add('wellfloor', 'mount', 'hgrey2', _zblock(-fi, fi, -fi, fi, -0.4 * s, 0.02 * s))
    z0 = 0.09 * s
    d = cal * 2.5
    offs = [(0.0, d * 0.58), (-d * 0.5, -d * 0.29), (d * 0.5, -d * 0.29)][:max(1, barrels)]
    cw, ch_ = d * 0.5 + cal * 1.6, d * 0.58 + cal * 1.6
    # the trunnion stands high enough that the cassette box clears the ring when it elevates, and the housing wraps the mantlet
    tz = max(z0 + 0.15 * s, z0 + ch_ * 1.25)
    L, W, H = 0.86 * s, 0.74 * s, max(0.3 * s, tz + ch_ * 0.55 - z0)
    # the housing: a low flat eight-sided box, a sloped glacis at its front, a seam band, a roof plate, a blue strip aft
    plan = [(L, W * 0.6), (L * 0.6, W), (-L * 0.7, W), (-L, W * 0.7), (-L, -W * 0.7), (-L * 0.7, -W), (L * 0.6, -W), (L, -W * 0.6)]
    V, F = _poly_prism(plan, z0, z0 + H)
    V = [((x - 0.3 * s if (x > L * 0.5 and z > z0 + H * 0.5) else x), y, z) for (x, y, z) in V]
    p.add('housing', 'body', 'hgrey', (V, F))
    p.add('housingseam', 'body', 'hgrey2', _poly_prism([(x * 1.015, y * 1.015) for (x, y) in plan], z0 + H * 0.38, z0 + H * 0.5))
    p.add('roof', 'body', 'hpanel', _poly_prism([(x * 0.6 - 0.1 * s, y * 0.68) for (x, y) in plan], z0 + H - 0.003 * s, z0 + H + 0.05 * s, inset=0.03 * s))
    p.add('housingstrip', 'body', 'hblue', _zblock(-L * 1.003, -L * 0.6, -W * 0.5, W * 0.5, z0 + H * 0.62, z0 + H * 0.74))
    trunnion = Vector((L * 0.45, 0, tz))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    # the mantlet and the cassette box round all three barrels (one machined block, a trim face frame at its mouth)
    p.add('mantlet', 'body', 'hgrey2', moved(block(-0.3 * s, 0.12 * s, cw * 1.12, ch_ * 1.05, cal * 0.6, zo=d * 0.05), E))
    xb = blen * 0.62
    p.add('cassette', 'body', 'hgrey', moved(block(0.1 * s, xb, cw, ch_, cal * 0.7, zo=d * 0.05), E))
    p.add('cassetteframe', 'body', 'htrim', moved(block(xb - cal * 0.9, xb, cw * 1.08, ch_ * 1.08, cal * 0.7, zo=d * 0.05), E))
    for k in range(2):
        x = 0.1 * s + (xb - 0.1 * s) * (0.3 + 0.35 * k)
        p.add('cassettecoil%d' % k, 'body', 'htrim', moved(block(x - cal * 0.45, x + cal * 0.45, cw * 1.06, ch_ * 1.06, cal * 0.7, zo=d * 0.05), E))
    muzzles = []
    for i, (oy, oz) in enumerate(offs):
        T = E @ Matrix.Translation((0, oy, oz + d * 0.05))
        xe = blen
        p.add('b%d_barrel' % i, 'body', 'hmetal', moved(revolve([(xb - cal, cal), (xe - cal * 1.2, cal * 0.95)], 10, phase=math.pi / 10), T))
        xc = (xb + xe) / 2 - cal * 0.6   # a coil ring sized to the barrel (the shared ring_band sinks a fixed 0.01, too deep on a craft)
        p.add('b%d_coil' % i, 'body', 'htrim', moved(revolve([(xc - cal * 0.3, cal * 0.92), (xc - cal * 0.3, cal * 1.25), (xc + cal * 0.3, cal * 1.25),
                                                              (xc + cal * 0.3, cal * 0.92)], 10, closed=True), T))
        p.add('b%d_muzzle' % i, 'body', 'hgrey2', moved(revolve([(xe - cal * 1.2, cal * 1.25), (xe, cal * 1.25), (xe, cal * 0.6), (xe - cal * 0.8, cal * 0.6)],
                                                                8, closed=True, phase=math.pi / 8), T))
        p.add('b%d_bore' % i, 'body', 'dark', moved(revolve([(xe - cal * 0.8, 0.0001), (xe - cal * 0.8, cal * 0.61)], 10), T))
        p.add('b%d_lens' % i, 'body', 'hlens', moved(revolve([(xe - cal * 0.75, cal * 0.45), (xe - cal * 0.7, 0.0001)], 10, cap0=True), T))
        muzzles.append(P(T @ Vector((xe, 0, 0))))
    return trunnion, muzzles, trunnion.x + blen, fo * 1.42, E


GUN_BUILDERS['guns'] = _cassette


def rocket_rack(rows, cols, cell, depth, variant=0):
    """the Navy bomb cassette (data.js bombs; issue 1373, the Navy bomber HB1). The sheet kit's K.launcher asks every faction
    kit for rocket_rack(rows, cols, cell, depth); the Navy answer is a machined module of bomb tubes set into the bow: a pale grey
    block with a steel-blue trim frame round its face, round bores with machined collars and an implant-blue ring deep inside,
    the next bomb seated in each bore. Local +X the firing direction, +Z up, origin at the centre of the front face; cell the
    tube pitch, depth how far the bores run back. Every piece is mount: the cassette is part of the hull (factions.md: modules,
    rectangular, machined)."""
    p = Part('launcher')
    p.type = 'bomb_tube'
    r = cell * 0.3
    hw, hh = cols * cell / 2, rows * cell / 2
    ch = cell * 0.1
    n = 16
    ctr = [((i - (cols - 1) / 2) * cell, (j - (rows - 1) / 2) * cell) for j in range(rows) for i in range(cols)]
    p.add('housing', 'mount', 'hgrey', block(-depth * 1.1, -r * 0.12, hw, hh, ch))
    p.add('frame', 'mount', 'htrim', block(-r * 0.25, r * 0.08, hw * 1.04, hh * 1.06, ch))
    for k_, (cy, cz) in enumerate(ctr):
        T = Matrix.Translation((0, cy, cz))
        p.add('collar%d' % k_, 'mount', 'hmetal', moved(revolve([(-r * 0.3, r * 1.0), (-r * 0.3, r * 1.28), (r * 0.18, r * 1.28), (r * 0.24, r * 1.18),
                                                               (r * 0.24, r * 1.0)], 12, closed=True, phase=math.pi / 12), T))
        p.add('bore%d' % k_, 'mount', 'hgrey2', moved(revolve([(r * 0.2, r * 1.0), (-depth, r * 1.0)], n), T))
        p.add('ring%d' % k_, 'mount', 'hblue', moved(ring_band(-depth * 0.35, r * 0.98, r * 0.12, r * 0.04, n), T))
        p.add('back%d' % k_, 'mount', 'dark', moved(revolve([(-depth * 0.99, r * 1.0), (-depth * 0.99, 0.0001)], n), T))
        p.add('warhead%d' % k_, 'mount', 'hmetal', moved(revolve([(-depth * 0.97, r * 0.82), (-depth * 0.7, r * 0.8), (-depth * 0.55, r * 0.42),
                                                                 (-depth * 0.5, 0.0001)], n), T))
    p.fit = dict(exits=[dict(pos=P((r * 0.24, cy, cz)), axis=D((1, 0, 0)), radius=r) for (cy, cz) in ctr], radius=max(hw, hh) * 1.1)
    return p


def craft_drive(w, h, body_len, depth=None, cells=3):
    """a craft's drive (factions.md: a flat row of rectangular blue-white nozzles; the owner's rule for craft: nozzle clusters inside
    armoured blocks): one wide rectangular mouth w by h split by upright guide vanes into a row of cells, a thick machined lip,
    inner walls tapering to a recessed blue-white throat plate, the walls a dimmer blue so the dark lip reads, a sleeve of
    armoured walls (the mount) with a trim band, a back block seated in the stern. Origin at the centre of the exit plane,
    exhaust along -X. Every size from w and h."""
    p = Part('engine')
    hw, hh = w / 2, h / 2
    t = min(hw, hh) * 0.28
    dp = depth or h * 1.6
    rc = hh * 0.3
    k = 4

    def rrect(a, b, r):
        pts = []
        for cy, cz, a0 in ((a - r, b - r, 0.0), (-a + r, b - r, 90.0), (-a + r, -b + r, 180.0), (a - r, -b + r, 270.0)):
            pts += [(cy + r * math.cos(math.radians(a0 + 90.0 * i / (k - 1))), cz + r * math.sin(math.radians(a0 + 90.0 * i / (k - 1)))) for i in range(k)]
        return pts

    def loop_prism(secs, cap_last=False):
        V, F = [], []
        m = len(secs[0][1])
        for x, lp in secs:
            V.extend((x, y, z) for (y, z) in lp)
        for j in range(len(secs) - 1):
            for i in range(m):
                a, b = j * m + i, j * m + (i + 1) % m
                F.append((a, b, b + m, a + m))
        if cap_last:
            F.append(tuple(range((len(secs) - 1) * m, len(secs) * m)))
        return V, F
    outer = rrect(hw + t, hh + t, rc + t); inner = rrect(hw, hh, rc)
    m = len(outer)
    V1, F1 = loop_prism([(-t * 0.3, outer), (t * 1.4, outer)])
    V2, F2 = loop_prism([(-t * 0.3, inner), (t * 1.4, inner)])
    V = V1 + V2; F = F1 + [tuple(x + len(V1) for x in f[::-1]) for f in F2]
    for i in range(m):
        F.append((i + len(V1), (i + 1) % m + len(V1), (i + 1) % m, i))
    p.add('lip', 'body', 'htrim', (V, F))
    th = 0.62
    p.add('lining', 'body', 'hlining', loop_prism([(0.0, rrect(hw * 0.995, hh * 0.995, rc)), (dp, rrect(hw * 0.9, hh * th, rc * th))]))
    tp = rrect(hw * 0.9, hh * th, rc * th)
    p.add('throat', 'body', 'hnozzle', ([(dp + t * 0.05, y, z) for (y, z) in tp] + [(dp + t * 0.05, 0.0, 0.0)],
                                       [(len(tp), (i + 1) % len(tp), i) for i in range(len(tp))]))
    for c in range(1, cells):
        y = -hw + w * c / cells
        p.add('vane%d' % c, 'body', 'hmetal', _zblock(t * 0.3, dp * 0.98, y - t * 0.22, y + t * 0.22, -hh * 0.98, hh * 0.98))
    # the sleeve and back block: armoured walls round the lining to the throat, a block behind it seated in the stern
    bh, bz = hw + t * 1.3, hh + t * 1.3
    xs = t * 1.3
    for (y0, y1, z0, z1) in ((-bh, bh, hh + t * 0.2, bz), (-bh, bh, -bz, -hh - t * 0.2), (hw + t * 0.2, bh, -bz, bz), (-bh, -hw - t * 0.2, -bz, bz)):
        p.add('housing', 'mount', 'hgrey2', _zblock(xs, dp + t * 0.2, y0, y1, z0, z1))
    p.add('housingback', 'mount', 'hgrey2', _zblock(dp + t * 0.2, body_len, -bh, bh, -bz, bz, ch=t * 0.4))
    ow, oz = bh + t * 0.35, bz + t * 0.35
    xb = xs + t * 0.4
    for (y0, y1, z0, z1) in ((-ow, ow, bz - t * 0.1, oz), (-ow, ow, -oz, -bz + t * 0.1), (bh - t * 0.1, ow, -bz, bz), (-ow, -bh + t * 0.1, -bz, bz)):
        p.add('band', 'mount', 'htrim', _zblock(xb, xb + t * 1.1, y0, y1, z0, z1))
    p.fit = dict(exit=P((0, 0, 0)), axis=D((-1, 0, 0)), radius=0.55 * (hw + hh), front=P((body_len, 0, 0)), body_r=max(bh, bz), w=w, h=h)
    return p
