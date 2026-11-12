# Eclipse (`deathless`) part shapes (issue 532, the E11 and E12 build sheets; RULEBOOK 4.5: every faction its own kit, only
# invisible plumbing shared, from tools/blender/kits/shared/geom.py).
# The faction sheet (docs/playbooks/factions.md, Eclipse): "a black shade with a thin ring of green-white fire at its edge";
# sunshades and heat shields, broad layered plates; the green is a thin cold line along the rim of every shade plate and the
# trapped light core seen through gaps; engines are no flaming bells but an eclipse ring of pale light; never bone, ribs,
# skulls, green pooled in hollows, or flame. Ryan's part rules (R217, R218) hold for every type: an engine reads as an
# engine, a gun has a base, a mount and a muzzle that say how it fires (R221), every part carries the ship's detail level.
#   engine_bell  the eclipse engine: a faceted ribbed drum on a mount collar, radial vanes, a short bell with a thick lip,
#                a thin corona ring of pale green-white light just inside the lip around a black shade disc (no flame)
#   gun          (R221) built from the weapon it carries, never a breech-and-barrel cannon; every turret stands behind its
#                own small shade (curved plates, a corona line on the rim) and fires through the gap in it:
#                (R221 pass 2, "super blocky": the hull's language, curved, layered, banded, never boxes or square frames)
#                nullcannon (gauss): slim round rail pairs with banded collars past a thin arched crescent shade of seamed,
#                bevelled plates, crescent capacitor fins, an oval shell; shredder (flak): a fan of five thin needle rails
#                from a layered crescent shade; spire (gsentry): a tall slim banded spire, needles through a crescent fin
#   spinal       the corona arc (doom): an arc emitter: breech collars, a capacitor column (segments, stacked disc banks,
#                feed conduits), a black shade disc in a corona ring with a small lens, a crown of six electrode horns
#   core_cage    the trapped light core: a bright sphere in gimbal rings and meridian bars between two hub collars
#   strut        a built truss: two rails, a zigzag web and end lugs (R207: real structural connections)
#   corewin      a hexagonal armoured port onto the core's light: a rim, set-back glass that glows, grille bars
#   hatch, hatchbox, vent, lamp, thruster, plate_slab: the Eclipse versions (octagonal hatches, shade-generator housings,
#                heat slot panels, corona strip lights, slot thrusters, chamfered machine-cut plates with flush fasteners)
# Local frame of every part: +X forward (the aim, or the engine's thrust direction), +Y left, +Z up (the mount normal).
# Roles: 'mount' parts may sit into the hull; every other role must stay clear of it; 'turn' (turret guns, R219) turns.
# Materials (mapped by tools/blender/build_sheets/kit.py MATS): shade, shade2, mauve, violet, gunv, dark, corona, ecore,
# lens, steel.
import math
import os
import sys
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'shared')))
from geom import Part, P, D, frame, revolve, prism, octa, block, moved, ring_band, rod  # noqa: E402,F401
import geom  # noqa: E402

# R226 (Board, Nov 12, from R186 'blown apart, never sliced'): the part kinds that are machines. A machine never
# crosses a seam (a cut gun reads as sliced): it rides whole with one piece. Every other kind is structure (plates,
# ribs, rails, hatches, vents, lamps, pipes, openings such as the launch bay) and may tear across a seam. The sheet kit
# stamps each part's objects with part_kind and machine from here; the stage 4 audit reads them (tools/recipe/audit.py).
MACHINES = ('gun', 'spinal', 'engine', 'thruster')

SUBPARTS = {
    'engine': ['housing', 'collar', 'rib', 'vane', 'bell', 'corona', 'shade'],
    # the weapons (R221: each from what it is; WEAPONS below)
    'nullcannon': ['ring|plate', 'housing', 'capacitor', 'yoke', 'shade', 'layer', 'corona', 'rail', 'collar', 'muzzle'],
    'shredder': ['ring|plate', 'housing', 'capacitor', 'shade', 'layer', 'corona', 'needle', 'collar'],
    'spire': ['ring|plate', 'spire', 'band', 'sight', 'head', 'shade', 'corona', 'needle', 'collar'],
    'corona_arc': ['breech', 'segment', 'capacitor', 'conduit', 'emitter', 'shade', 'corona', 'lens', 'horn'],
    'core': ['hub', 'sphere', 'gimbal', 'bar'],
    'strut': ['rail', 'web', 'lug'],
    'corewin': ['rim', 'glass', 'bar'],
    'hatch': ['rim', 'door', 'seam', 'hinge'],
    'hatchbox': ['frame', 'lid', 'rib'],
    'vent': ['frame', 'slat'],
    'lamp': ['housing', 'lens'],
    'thruster': ['block', 'nozzle'],
    'plate': ['slab', 'step', 'bevel', 'fastener'],
    'shade': ['band', 'layer', 'corona', 'plate'],
    'arc': ['channel', 'corona', 'frame', 'machinery', 'plate'],
    'hull': ['bevel', 'step', 'overhang'],
    'tier': ['face', 'roof', 'opening'],
    'belt': ['band', 'plate'],
    'feather': ['blade', 'step'],
    'rib': ['rib'],
    'pylon': ['web', 'plate'],
}


def detail_ok(kind, names):
    return geom.detail_ok(SUBPARTS, kind, names)


def _zrev(profile, n, phase=0.0, **kw):
    """a revolve about the local Z axis (a vertical solid of revolution): profile [(z, r)]"""
    return revolve(profile, n, axis='Z', phase=phase, **kw)


# ---------------------------------------------------------------------------------------------------- plate courses
PANEL = (0.2, 0.4)   # world units across and along: the small end of the hull's plate sizes (the sheets' PL run 0.2 to 0.32 by 0.45 to 0.75)


def panels(p, tag, role, mats, x0, x1, r, n, phase, skip=(), th=0.022, size=PANEL, seed=0):
    """issue 618 (R224, measured): plate courses on the flat faces of an n-sided revolve (radius r to its corners, phase as
    revolve's) from x0 to x1, at the hull's own plate size in world units, so a big part carries the hull's detail density as
    a small one does: each plate a thin chamfered slab with a gap round it, its thickness varied plate to plate. skip: face
    indices to leave bare (a conduit runs there). One comp per material."""
    ap = r * math.cos(math.pi / n); fw = 2 * r * math.sin(math.pi / n)
    across = max(1, int(round(fw / size[0]))); along = max(1, int(round((x1 - x0) / size[1])))
    g = min(0.025, fw / across * 0.12, (x1 - x0) / along * 0.12)
    acc = {m: ([], []) for m in mats}
    for k in range(n):
        if k in skip: continue
        a = 2 * math.pi * (k + 0.5) / n + phase
        nv = Vector((0, math.cos(a), math.sin(a))); tv = Vector((0, -math.sin(a), math.cos(a)))
        for i in range(along):
            xa = x0 + (x1 - x0) * i / along + g; xb = x0 + (x1 - x0) * (i + 1) / along - g
            for j in range(across):
                ta = -fw / 2 + fw * j / across + g; tb = -fw / 2 + fw * (j + 1) / across - g
                h = th * (0.7 + 0.6 * (((k * 7 + i * 13 + j * 5 + seed) * 2654435761) % 1000) / 1000.0)
                e = min(h * 0.8, (xb - xa) * 0.2, (tb - ta) * 0.2)
                base = [(xa, ta), (xb, ta), (xb, tb), (xa, tb)]
                top = [(xa + e, ta + e), (xb - e, ta + e), (xb - e, tb - e), (xa + e, tb - e)]
                V = [Vector((x, 0, 0)) + nv * (ap - 0.004) + tv * t for x, t in base] + [Vector((x, 0, 0)) + nv * (ap + h) + tv * t for x, t in top]
                F = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
                m = mats[(i + j + k + seed) % len(mats)]
                VV, FF = acc[m]; o = len(VV); VV.extend(tuple(v) for v in V); FF.extend(tuple(q + o for q in f) for f in F)
    for m, (VV, FF) in acc.items():
        if FF: p.add('%s_plate_%s' % (tag, m), role, m, (VV, FF))


# ---------------------------------------------------------------------------------------------------- engine
def engine_bell(r_exit, body_len, bell_len=None, body_r=None, throat=0.6, rings=3, struts=6, nose='flat', seg=24):
    """the eclipse engine; exhaust leaves along -X; origin at the centre of the bell's exit plane.
    housing: a faceted (octagonal) drum forward of the bell with raised ribs; a heavier mount collar at its front;
    bell: short and wide, a thick rolled lip; inside the lip a thin corona ring of pale light around a black shade disc set a
    little back, so the mouth reads as an eclipse (a dark disc with a ring of light), never a flame; radial vanes tie the
    housing to the bell."""
    p = Part('engine')
    bl = bell_len or r_exit * 0.8
    br = body_r or r_exit * 0.95
    t = max(0.03, r_exit * 0.08)
    rt = r_exit * throat
    xt = bl
    k = 6
    outer = [(xt - xt * i / k, rt + (r_exit - rt) * (i / k) ** 1.3) for i in range(k + 1)]
    lip = [(-t * 0.5, r_exit + t * 1.1), (-t * 0.5, r_exit - t * 0.6)]
    inner = [(x, max(rt * 0.8, r - t * 1.4)) for (x, r) in reversed(outer)]
    p.add('bell', 'body', 'gunv', revolve(outer + lip + inner[1:], seg, closed=True, phase=math.pi / seg))
    # the corona: a thin bright ring just inside the lip, and the black shade disc set back inside it
    # issue 618 (R224): stiffener rings round the bell's back, as many as its size carries (the bell itself is a smooth surface)
    for i in range(max(1, int(round(bl / 0.22)))):
        u = (i + 0.6) / (max(1, int(round(bl / 0.22))) + 0.4); x = xt * (1 - u); rr = rt + (r_exit - rt) * (1 - x / xt) ** 1.3
        p.add('bellring%d' % i, 'body', 'gunv', revolve([(x + 0.03, rr - 0.005), (x + 0.03, rr + t * 0.7), (x - 0.03, rr + t * 0.7), (x - 0.03, rr - 0.005)],
                                                        seg, closed=True, phase=math.pi / seg))
    p.add('corona', 'body', 'corona', revolve([(-t * 0.2, r_exit - t * 0.65), (t * 0.4, r_exit - t * 0.65), (t * 0.4, r_exit - t * 1.25),
                                               (-t * 0.2, r_exit - t * 1.25)], seg, closed=True))
    p.add('shade', 'body', 'dark', revolve([(xt * 0.35, 0.001), (xt * 0.35, r_exit * 0.86), (xt * 0.55, r_exit * 0.8), (xt * 0.9, rt * 0.7)],
                                           seg, cap1=False))
    # housing: an octagonal drum (phase so a flat sits on top), stepped down into the throat
    xf = xt + body_len
    house = [(xt - t, rt * 1.05), (xt + r_exit * 0.15, br * 0.82), (xt + r_exit * 0.25, br), (xf - br * 0.2, br), (xf - br * 0.05, br * 0.88)]
    house += [(xf, br * 0.7), (xf, 0.001)] if nose == 'flat' else [(xf + br * 0.15, br * 0.45), (xf + br * 0.2, 0.001)]
    p.add('housing', 'mount', 'shade', revolve(house, 8, cap0=True, phase=math.pi / 8))
    nb = max(2, int(body_len / (br * 0.55)))
    for i in range(nb):
        x = xt + r_exit * 0.3 + (body_len - r_exit * 0.3 - br * 0.35) * (i + 0.5) / nb
        p.add('rib%d' % i, 'mount', 'gunv', revolve([(x - br * 0.05, br * 0.99), (x - br * 0.05, br * 1.05), (x + br * 0.05, br * 1.05), (x + br * 0.05, br * 0.99)],
                                                    8, closed=True, phase=math.pi / 8))
    panels(p, 'housing', 'mount', ('shade2', 'violet', 'shade'), xt + r_exit * 0.28, xf - br * 0.47, br, 8, math.pi / 8)   # issue 618, R224
    p.add('collar', 'mount', 'mauve', revolve([(xf - br * 0.45, br * 0.98), (xf - br * 0.45, br * 1.12), (xf - br * 0.22, br * 1.12),
                                               (xf - br * 0.22, br * 0.98)], 8, closed=True, phase=math.pi / 8))
    for i in range(struts):
        a = 2 * math.pi * (i + 0.5) / struts
        c, s = math.cos(a), math.sin(a)
        # a vane: a thin plate from the housing's aft edge out onto the bell's back
        x0, x1 = xt + r_exit * 0.3, xt * 0.35
        r0, r1 = br * 0.97, rt + (r_exit - rt) * 0.65 ** 1.3 + t
        V = [(x0, r0 * c - 0.02 * s, r0 * s + 0.02 * c), (x0, r0 * c + 0.02 * s, r0 * s - 0.02 * c),
             (x1, r1 * c + 0.02 * s, r1 * s - 0.02 * c), (x1, r1 * c - 0.02 * s, r1 * s + 0.02 * c)]
        V += [(x0, (r0 + t * 1.6) * c - 0.02 * s, (r0 + t * 1.6) * s + 0.02 * c), (x0, (r0 + t * 1.6) * c + 0.02 * s, (r0 + t * 1.6) * s - 0.02 * c),
              (x1, (r1 + t) * c + 0.02 * s, (r1 + t) * s - 0.02 * c), (x1, (r1 + t) * c - 0.02 * s, (r1 + t) * s + 0.02 * c)]
        F = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
        p.add('vane%d' % i, 'mount', 'gunv', (V, F))
    p.fit = dict(exit=P((0, 0, 0)), axis=D((-1, 0, 0)), radius=r_exit + t * 1.1, front=P((xf, 0, 0)), body_r=br)
    return p


# ---------------------------------------------------------------------------------------------------- guns
# R221 (Ryan, Nov 12: "their turrets look the same as hullbreakers. We should have those be more unique per factions and fit
# the actual weapons they use per lore Bible and faction rules"). Every Eclipse weapon is built from what it is (data.js W,
# FAC_WNAMES.deathless, the lore bible 7.5 and 7.10, factions.md Eclipse "guns sit behind the shade's rim, firing through gaps
# between plates", the battle effect in godot/fx/fx_weapons.gd). None is a breech-and-barrel cannon: no round barrel, no
# breech block, no muzzle brake, no bore. Each turret stands behind its own small shade (a curved shield plate with a corona
# line on its rim), and the weapon fires through the gap in it. The design line per weapon is in WEAPONS below and in
# tools/blender/kits/eclipse/README.md.
WEAPONS = {
    'gauss': dict(
        name='Null cannon', rules='data.js gauss: 3 shots, 6 damage, range 5; ignores half of armour (WTRAITS gauss)',
        lore='Lore 7.5: "Null weapons ignore half of armour". Battle effect: capacitor coils light breech to muzzle in steps, a near '
             'invisible slug, a hard white flash and a pale shock ring, a punch-through with an exit spray.',
        design=('A magnetic rail gun, not a barrel: each gun is a pair of slim round rails (the slug rides between them) banded '
               'with round accelerator collars that step down toward the muzzle (the coils the effect lights in steps), reaching'
               ' well past the shade and ending in a thin shock ring, no bore. They fire through the slot of a thin crescent '
               "shade in the hull's language: an arch of three bevelled plates with narrow seams, a second layer stepped in on "
               "its face, plate courses at the hull's scale, horns swept back and down, a corona line on the crest. Low layered "
               'crescent capacitor fins sit behind it on a small oval shell. Twin: two rail pairs.')),
    'flak': dict(
        name='Null shredder', rules='data.js flak: 3 shots, 3 damage, range 2; point defence (vs squadrons x3)',
        lore='The Eclipse flak (FAC_WNAMES deathless flak). Battle effect (gflak): instant thin streaks to a spread of airbursts.',
        design=('A fan of five thin round needle rails, each with two banded collars, splayed side to side so the slugs spread '
               'into a screen, out of the slot of a small layered crescent shade on a low oval shell; two crescent capacitor '
               'fins behind; it elevates high (to 60) for craft.')),
    'gsentry': dict(
        name='Null spire', rules='data.js gsentry: 2 shots, 4 damage, range 3; point defence (vs squadrons x3)',
        lore='Null sentries / Null spire (FAC_WNAMES deathless gsentry, lore 7.10): the zenith\'s picket against craft. Battle '
             'effect (gflak): instant thin streaks.',
        design=('A sentry post, not a gun box: a tall slim round spire with banded collars and green sight slits down its face, '
               'turning; at its head a small oval pod with two thin round needle rails through a layered crescent fin; it stands'
               ' high to see craft over the hull.')),
    'doom': dict(
        name='Corona arc', rules='data.js doom: lance, 1 shot, 40 damage, range 5, every other turn (cd 2)',
        lore='Lore 7.5: "the Corona arc lands one heavy blow every other turn". Battle effect: little crawling arcs gather on the '
             'emitter, then a re-striking arc of lightning. Crest (7.8): an eclipsed sun, a black disc with a thin ring.',
        design='An arc emitter, not a barrel: the shaft is a capacitor column (stacked disc banks between the segments, feed '
               'conduits along it) that stores the charge for one blow every other turn; the mouth is the faction crest, a black '
               'shade disc in a thin corona ring, with a crown of six electrode horns curving forward round it where the arcs '
               'crawl before the strike.'),
}


def _ringloft(rings, cap=True):
    """a closed loft through 3D cross-section rings (lists of points, all the same count), capped at both ends"""
    V, F = [], []
    n = len(rings[0])
    for r in rings:
        V += [tuple(q) for q in r]
    for j in range(len(rings) - 1):
        for i in range(n):
            a, b = j * n + i, j * n + (i + 1) % n
            F.append((a, b, b + n, a + n))
    if cap:
        F.append(tuple(range(n))[::-1]); o = (len(rings) - 1) * n; F.append(tuple(range(o, o + n)))
    return V, F


def _shade(R, half, z0, z1, t, lean=0.0, cx=0.0, droop=0.3, n=28, bevel=0.6, span=None):
    """a turret's own sunshade, in the hull's language (the crescent's layered, bevelled plates): a thin plate curved round a
    vertical axis at x = cx (concave aft), spanning -half..half degrees from +X, from z0 up to z1 (lower toward the horns by
    droop), the top leaning back by lean; its top edge bevelled to a knife rim (bevel: the share of t the chamfer takes).
    Returns (plate, rim line) as (verts, faces): the rim line is the thin corona strip along the crest."""
    rings, rim = [], []
    a0, a1 = span or (-half, half)   # span: one plate of a segmented shade (degrees), the droop still measured on the whole
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        c, s = math.cos(a), math.sin(a)
        f = abs(a) / math.radians(half)
        zt = z0 + (z1 - z0) * (1 - droop * f * f)
        rt = R - lean * (zt - z0)
        tk = t * (1 - 0.45 * f)            # thinner toward the horns, as the crescent

        def pt(r, z):
            return (cx + r * c, r * s, z)
        ch = tk * 2.2 * bevel
        rings.append([pt(R, z0), pt(R + tk, z0), pt(rt + tk - lean * 0, zt - ch), pt(rt + tk * 0.35, zt), pt(rt, zt - ch * 0.3)])
        rim.append([pt(rt + tk * 0.05, zt - tk * 0.15), pt(rt + tk * 0.75, zt - tk * 0.15), pt(rt + tk * 0.75, zt + tk * 0.3), pt(rt + tk * 0.05, zt + tk * 0.3)])
    return _ringloft(rings), _ringloft(rim)


def _ovaldome(rx, ry, z0, h, xo=0.0, n=24, k=5, flat=0.35):
    """a rounded oval shell (the hull's oval section, in miniature): base rx by ry at z0, rising h, flattened on top"""
    rings = []
    for j in range(k + 1):
        u = j / k
        sc = max(0.25, math.cos(u * math.pi / 2) ** flat)
        z = z0 + h * u ** 0.8
        rings.append([(xo + rx * sc * math.cos(2 * math.pi * i / n), ry * sc * math.sin(2 * math.pi * i / n), z) for i in range(n)])
    return _ringloft(rings)


def _collar(x, r_in, r_out, w, n=16):
    """a banded collar round the X axis at station x (the hull's band collar in miniature): a round band with a raised lip"""
    return revolve([(x - w / 2, r_in), (x - w / 2, r_out * 0.92), (x - w * 0.2, r_out), (x + w * 0.2, r_out), (x + w / 2, r_out * 0.92), (x + w / 2, r_in)],
                   n, closed=True)


def _turntable(p, s, rr, z_top, sides=24):
    """the fixed foot every Eclipse turret turns on: a thin round plate with a bevelled edge and a low bearing ring"""
    p.add('plate', 'mount', 'shade', _zrev([(-0.1 * s, rr * 1.05), (0.0, rr * 1.05), (0.025 * s, rr * 0.95), (0.025 * s, 0.001)],
                                          sides, cap0=True))
    p.add('ring', 'mount', 'gunv', _zrev([(0.02 * s, rr * 0.78), (z_top, rr * 0.74), (z_top, 0.001)], sides))


def _crescent_stack(p, name, E, R, cx, z0, z1, t, half, k, step, mats=('violet', 'mauve')):
    """capacitor banks as layered crescent fins behind the shade, stepping down and in (the crescent's layers repeated)"""
    for j in range(k):
        f = 1 - 0.16 * (j + 1)
        pl, _ = _shade(R * f, half * (0.92 - 0.06 * j), z0 * f, z1 * f, t * 0.8, lean=0.1, cx=cx - step * (j + 1), droop=0.45, n=20)
        p.add('%s%d' % (name, j), 'body', mats[j % 2], moved(pl, E))


def _null_cannon(p, barrels, cal, blen, s, pitch, variant):
    """the null cannon (data.js gauss): two round rail pairs banded with stepped collars, reaching well past a tall, thin,
    layered crescent shade (corona on its rim); layered crescent capacitor banks behind; a small oval shell under it"""
    rr = 0.36 * s
    _turntable(p, s, rr, 0.06 * s)
    z0 = 0.06 * s
    p.add('housing', 'body', 'mauve', _ovaldome(0.34 * s, 0.26 * s, z0, 0.13 * s, xo=-0.08 * s))
    zh = z0 + 0.12 * s
    zc = zh + 0.3 * s
    trunnion = Vector((0.05 * s, 0, zc))
    for sgn in (1, -1):
        p.add('yoke%d' % (sgn > 0), 'body', 'gunv', rod((0.0, sgn * 0.17 * s, zh - 0.02 * s), (0.05 * s, sgn * 0.17 * s, zc), 0.028 * s, 8))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    R = 0.46 * s; cx = -0.4 * s; slot = cal * 1.2
    lo, _rl = _shade(R, 68, -0.2 * s, -slot, 0.03 * s, lean=-0.25, cx=cx, droop=0.2)
    p.add('shade0', 'body', 'violet', moved(lo, E))
    # the upper shade: three plates with narrow seams (the E12 ring's broken plates, the crescent's plate courses), an arch
    # high at the centre and swept down to thin horns; the corona line runs along the whole crest
    for j, (a0, a1) in enumerate(((-74.0, -27.0), (-25.0, 25.0), (27.0, 74.0))):
        up, _ = _shade(R, 74, slot, 0.48 * s, 0.03 * s, lean=0.22, cx=cx, droop=0.75, n=12, span=(a0, a1))
        p.add('shade%d' % (j + 1), 'body', 'mauve' if j != 1 else 'violet', moved(up, E))
    _, rim = _shade(R, 74, slot, 0.48 * s, 0.03 * s, lean=0.22, cx=cx, droop=0.75)
    p.add('corona', 'body', 'corona', moved(rim, E))
    # the second layer, stepped in from the rim on the shade's front face (as the crescent's upper layer), and two thin plate
    # courses across the front at the hull's plate scale
    ly, _ = _shade(R + 0.03 * s, 52, slot + 0.02 * s, 0.32 * s, 0.022 * s, lean=0.22, cx=cx, droop=0.6)
    p.add('layer0', 'body', 'violet', moved(ly, E))
    for j, za in enumerate((0.15 * s, 0.25 * s)):
        rb, _ = _shade(R + 0.032 * s + 0.022 * s - 0.22 * (za - slot), 58 - 10 * j, za, za + 0.025 * s, 0.012 * s, cx=cx, droop=0.0, n=20, bevel=0.2)
        p.add('layer%d' % (j + 1), 'body', 'gunv', moved(rb, E))
    # capacitor banks: low layered crescent fins behind the slot
    _crescent_stack(p, 'capacitor', E, R * 0.8, cx, -0.14 * s, 0.14 * s, 0.026 * s, 60, 3, 0.06 * s)
    xf = cx + R + 0.04 * s
    gap = cal * 3.6
    L = blen * 1.3
    muzzles = []
    for i in range(barrels):
        off = (i - (barrels - 1) / 2) * gap
        xe = xf + L
        T = E @ Matrix.Translation((0, off, 0))
        for sz in (1, -1):
            p.add('rail%d%d' % (i, sz > 0), 'body', 'gunv', moved(rod((-0.15 * s, 0, sz * cal * 0.42), (xe, 0, sz * cal * 0.42), cal * 0.24, 8, cal * 0.2), T))
        for j, (t_, k_) in enumerate(((0.08, 1.25), (0.3, 1.12), (0.52, 1.0), (0.74, 0.9))):
            p.add('collar%d%d' % (i, j), 'body', 'violet' if j % 2 else 'gunv', moved(_collar(xf + L * t_, cal * 0.5, cal * (0.62 + 0.26 * k_), cal * 0.45), T))
        p.add('muzzle%d' % i, 'body', 'steel', moved(_collar(xe - cal * 0.25, cal * 0.5, cal * 1.05, cal * 0.14), T))
        muzzles.append(P(E @ Vector((xe, off, 0))))
    return trunnion, muzzles, xf + L, max(rr * 1.05, 0.5 * s)


def _shredder(p, barrels, cal, blen, s, pitch, variant):
    """the null shredder (data.js flak): a fan of five thin round needle rails out of the slot of a layered crescent shade on a
    small oval shell; crescent capacitor fins behind"""
    rr = 0.32 * s
    _turntable(p, s, rr, 0.06 * s)
    z0 = 0.06 * s
    p.add('housing', 'body', 'mauve', _ovaldome(0.28 * s, 0.24 * s, z0, 0.14 * s, xo=-0.06 * s))
    zc = z0 + 0.24 * s
    trunnion = Vector((0.03 * s, 0, zc))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    R = 0.36 * s; cx = -0.2 * s; slot = cal * 0.9
    lo, _ = _shade(R, 76, -0.16 * s, -slot, 0.026 * s, lean=-0.2, cx=cx, droop=0.2)
    up, rim = _shade(R, 80, slot, 0.42 * s, 0.028 * s, lean=0.3, cx=cx, droop=0.55)
    p.add('shade0', 'body', 'violet', moved(lo, E)); p.add('shade1', 'body', 'mauve', moved(up, E)); p.add('corona', 'body', 'corona', moved(rim, E))
    ly, _ = _shade(R + 0.026 * s, 55, slot + 0.02 * s, 0.28 * s, 0.018 * s, lean=0.3, cx=cx, droop=0.4)
    p.add('layer0', 'body', 'violet', moved(ly, E))
    _crescent_stack(p, 'capacitor', E, R * 0.8, cx, -0.1 * s, 0.1 * s, 0.022 * s, 60, 2, 0.05 * s)
    xf = cx + R + 0.03 * s
    n = max(barrels, 5)
    L = blen * 1.25
    muzzles = []
    for i in range(n):
        a = math.radians((i - (n - 1) / 2) * 8.0)
        Ry = Matrix.Rotation(a, 4, 'Z')
        root = Vector((xf - 0.14 * s, (i - (n - 1) / 2) * cal * 0.9, 0))
        tip = root + Ry.to_3x3() @ Vector((L, 0, 0))
        p.add('needle%d' % i, 'body', 'gunv', moved(rod(root, tip, cal * 0.3, 8, cal * 0.2), E))
        for j, t_ in enumerate((0.45, 0.85)):
            fr = root + Ry.to_3x3() @ Vector((L * t_, 0, 0))
            p.add('collar%d%d' % (i, j), 'body', 'steel' if j else 'violet', moved(moved(_collar(0, cal * 0.25, cal * 0.5, cal * 0.4, 12), Matrix.Translation(fr) @ Ry), E))
        muzzles.append(P(E @ tip))
    return trunnion, muzzles, xf - 0.14 * s + L, rr * 1.05


def _spire(p, barrels, cal, blen, s, pitch, variant):
    """the null spire (data.js gsentry): a tall slim round spire with banded collars and green sight slits, turning; at its
    head a small oval pod with two thin round needle rails through a layered crescent fin"""
    rr = 0.3 * s
    _turntable(p, s, rr, 0.06 * s)
    z0 = 0.06 * s; zt = z0 + 0.95 * s
    p.add('spire', 'body', 'mauve', _zrev([(z0, rr * 0.7), (z0 + 0.1 * s, rr * 0.7), (z0 + 0.18 * s, rr * 0.48), (zt - 0.08 * s, rr * 0.26), (zt, rr * 0.22), (zt, 0.001)], 16))
    for k in range(3):
        z = z0 + 0.3 * s + 0.2 * s * k
        rk = rr * (0.48 - 0.22 * (z - z0 - 0.18 * s) / (zt - z0 - 0.18 * s)) + 0.012 * s
        p.add('band%d' % k, 'body', 'gunv', _zrev([(z - 0.02 * s, rk * 0.95), (z - 0.01 * s, rk), (z + 0.03 * s, rk), (z + 0.04 * s, rk * 0.95), (z + 0.04 * s, 0.001)], 16))
        p.add('sight%d' % k, 'body', 'corona', block(rk - 0.012 * s, rk + 0.008 * s, 0.022 * s, 0.045 * s, 0, zo=z + 0.1 * s))
    zc = zt + 0.07 * s
    p.add('head', 'body', 'violet', _ovaldome(0.15 * s, 0.1 * s, zt - 0.02 * s, 0.14 * s, xo=-0.05 * s, n=20))
    trunnion = Vector((0.0, 0, zc))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    R = 0.2 * s; cx = -0.1 * s
    fin, rim = _shade(R, 70, -0.12 * s, 0.24 * s, 0.022 * s, lean=0.35, cx=cx, droop=0.55)
    p.add('shade', 'body', 'violet', moved(fin, E)); p.add('corona', 'body', 'corona', moved(rim, E))
    xf = cx + R + 0.025 * s
    L = blen * 1.2
    muzzles = []
    for i in range(max(barrels, 2)):
        off = (i - 0.5) * cal * 2.4
        root = Vector((-0.05 * s, off, 0)); tip = Vector((xf + L, off, 0))
        p.add('needle%d' % i, 'body', 'gunv', moved(rod(root, tip, cal * 0.32, 8, cal * 0.22), E))
        p.add('collar%d' % i, 'body', 'steel', moved(_collar(xf + L * 0.7, cal * 0.25, cal * 0.55, cal * 0.4, 12), E @ Matrix.Translation((0, off, 0))))
        muzzles.append(P(E @ tip))
    return trunnion, muzzles, xf + L, rr * 1.05


GUN_BUILDERS = {'gauss': ('nullcannon', _null_cannon), 'flak': ('shredder', _shredder), 'gsentry': ('spire', _spire)}


def gun(barrels=2, cal=0.12, blen=2.0, size=1.0, mount='turret', pitch=0.0, variant=0, seg=6, weapon='gauss'):
    """an Eclipse weapon mount, built from the weapon it carries (data.js id: gauss, flak, gsentry; WEAPONS says how each
    works). Origin on the hull surface at the mount centre, local +Z the mount normal, +X the rest aim; the firing group
    elevates by pitch about the trunnion. Fixed pieces (the hex foot) are 'mount'; everything that turns is 'turn' (R219)."""
    assert mount == 'turret', 'Eclipse guns are turrets (the corona arc is the spinal mount)'
    typ, fn = GUN_BUILDERS[weapon]
    p = Part('gun')
    p.type = typ
    trunnion, muzzles, reach, radius = fn(p, barrels, cal, blen, size, pitch, variant)
    for c in p.comps:
        if c['role'] == 'body':
            c['role'] = 'turn'
    E = Matrix.Rotation(-math.radians(pitch), 3, 'Y')
    p.fit = dict(pivot=P((0, 0, trunnion.z)), trunnion=P(trunnion), muzzles=muzzles, reach=reach + trunnion.x,
                 aim=D(E @ Vector((1, 0, 0))), up=D((0, 0, 1)), mount=mount, radius=radius)
    return p


# ---------------------------------------------------------------------------------------------------- the corona arc projector
def spinal(length, r=0.55, collar_r=None, collar_len=None, block_len=None, block_r=None, seg=8):
    """the corona arc (data.js doom, slot F; the Tomb-ark's spinal shell), an arc emitter, not a barrel. Origin at the root on
    the hull's front face, +X forward. Stepped octagonal breech collars at the root (the mount: they sink into the hull); the
    shaft a capacitor column: octagonal segments with stacked disc banks between them and four feed conduits along them; the
    emitter head: a short octagonal throat, a black shade disc in a thin corona ring (the crest, an eclipsed sun), a small
    lens at its centre, and a crown of six electrode horns curving forward round the disc where the arcs gather."""
    p = Part('spinal')
    p.type = 'corona_arc'
    cr = collar_r or r * 1.6
    cl = collar_len or length * 0.4
    bl = block_len or length * 0.22
    brr = block_r or r * 1.3
    ph = math.pi / seg
    xs = [-0.6, cl * 0.3, cl * 0.62, cl]
    rs = [cr, cr * 0.9, cr * 0.8]
    for i in range(3):
        a, b = xs[i], xs[i + 1]
        p.add('breech%d' % i, 'mount', 'mauve' if i % 2 == 0 else 'violet',
              revolve([(a, rs[i] * 0.7), (a, rs[i]), (b - 0.08, rs[i]), (b - 0.02, rs[i] * 0.93), (b - 0.02, rs[i] * 0.7)], seg, closed=True, phase=ph))
        p.add('breechgap%d' % i, 'mount', 'dark', revolve([(b - 0.03, rs[i] * 0.72), (b + 0.03, rs[i] * 0.72)], seg, cap0=True, cap1=True, phase=ph))
        panels(p, 'breech%d' % i, 'mount', ('mauve', 'violet', 'shade2'), a + 0.06, b - 0.1, rs[i], seg, ph, seed=3 + i)   # issue 618, R224
    x0, x1 = cl, length - bl
    n = 3
    for i in range(n):
        a = x0 + (x1 - x0) * i / n; b = x0 + (x1 - x0) * (i + 1) / n
        ri = r * (1.0 - 0.04 * i)
        p.add('segment%d' % i, 'body', 'violet' if i % 2 else 'mauve', revolve([(a, ri), (b, ri)], seg, cap0=True, cap1=True, phase=ph))
        # issue 618 (R224): plate courses on the column's faces at the hull's plate size, clear of the disc banks and the
        # four feed conduits (they run on faces 0, 2, 4, 6 of an 8-sided column)
        panels(p, 'segment%d' % i, 'body', ('violet', 'mauve', 'shade2'), a + 0.1 + min(0.07, (b - a) * 0.05) * 4, b - 0.04, ri, seg, ph,
               skip=tuple(range(0, seg, 2)) if seg == 8 else (), seed=i)
        # a capacitor bank: three thin discs stacked across the joint, the middle one widest (it stores the blow)
        dw = min(0.07, (b - a) * 0.05)
        for k, (dx, rk) in enumerate(((-dw * 2.4, 1.18), (0.0, 1.3), (dw * 2.4, 1.18))):
            p.add('capacitor%d_%d' % (i, k), 'body', 'gunv' if k != 1 else 'steel',
                  revolve([(a + 0.1 + dx - dw / 2, ri * 0.98), (a + 0.1 + dx - dw / 2, ri * rk), (a + 0.1 + dx + dw / 2, ri * rk), (a + 0.1 + dx + dw / 2, ri * 0.98)],
                          seg, closed=True, phase=ph))
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        c, s_ = math.cos(a), math.sin(a)
        p.add('conduit%d' % k, 'body', 'gunv', rod((x0 + 0.15, r * 1.0 * c, r * 1.0 * s_), (x1 - 0.05, r * 0.92 * c, r * 0.92 * s_), r * 0.08, 6))
    # the emitter head: an octagonal throat flaring to a dish rim; the black shade disc set back in it; the corona ring
    p.add('emitter', 'body', 'mauve', revolve([(x1, r * 0.95), (x1 + bl * 0.15, brr), (length - bl * 0.1, brr), (length, brr * 1.08), (length, brr * 0.9),
                                               (length - bl * 0.25, brr * 0.82)], seg, closed=True, phase=ph))
    p.add('emitterband', 'body', 'violet', revolve([(x1 + bl * 0.35, brr * 0.99), (x1 + bl * 0.35, brr * 1.06), (x1 + bl * 0.5, brr * 1.06),
                                                   (x1 + bl * 0.5, brr * 0.99)], seg, closed=True, phase=ph))
    panels(p, 'emitter', 'body', ('violet', 'mauve'), x1 + bl * 0.53, length - bl * 0.14, brr, seg, ph, seed=9)   # issue 618, R224
    p.add('shade', 'body', 'dark', revolve([(length - bl * 0.25, brr * 0.82), (length - bl * 0.3, brr * 0.5), (length - bl * 0.32, 0.001)], 24))
    p.add('corona', 'body', 'corona', revolve([(length - bl * 0.03, brr * 0.84), (length - bl * 0.03, brr * 0.9), (length + bl * 0.015, brr * 0.9),
                                               (length + bl * 0.015, brr * 0.84)], 24, closed=True))
    p.add('lens', 'body', 'lens', revolve([(length - bl * 0.33, brr * 0.12), (length - bl * 0.28, brr * 0.1), (length - bl * 0.24, 0.001)], 16, cap0=True))
    # the crown: six electrode horns from the rim, curving forward and in toward the axis ahead of the disc
    hl = brr * 1.15
    for k in range(6):
        a = 2 * math.pi * (k + 0.5) / 6
        c, s_ = math.cos(a), math.sin(a)
        pts = []
        for j in range(5):
            t = j / 4
            rad = brr * (1.0 - 0.55 * t ** 1.6)
            pts.append(Vector((length - bl * 0.05 + hl * math.sin(t * math.pi / 2), rad * c, rad * s_)))
        for j, (u, v) in enumerate(zip(pts, pts[1:])):
            rw = brr * 0.11 * (1 - 0.17 * j)
            p.add('horn%d_%d' % (k, j), 'body', 'gunv' if j < 3 else 'steel', rod(u, v, rw, 6, rw * 0.82))
    # the muzzle (the hard point the game fires from) is the lens at the crest's centre, where the arc leaves: it sits on the
    # emitter's own mesh (issue 618: the horns' meeting point ahead of it is open space, half a crest radius off the mesh, which
    # the export check refuses); reach still runs to the horn tips, so the fit check's lane and arcs see the whole crown
    tip = length - bl * 0.24
    p.fit = dict(muzzles=[P((tip, 0, 0))], pivot=P((length - 0.05, 0, 0)), trunnion=P((length - 0.05, 0, 0)), reach=hl + 0.05,
                 aim=D((1, 0, 0)), up=D((0, 0, 1)), mount='spinal', radius=brr * 1.08, bore=brr * 0.82)
    return p


# ---------------------------------------------------------------------------------------------------- the core
def _uv_sphere(r, nu=16, nv=10):
    V = [(0, 0, -r)]
    for j in range(1, nv):
        ph = -math.pi / 2 + math.pi * j / nv
        for i in range(nu):
            th = 2 * math.pi * i / nu
            V.append((r * math.cos(ph) * math.cos(th), r * math.cos(ph) * math.sin(th), r * math.sin(ph)))
    V.append((0, 0, r))
    F = []
    for i in range(nu):
        F.append((0, 1 + (i + 1) % nu, 1 + i))
    for j in range(nv - 2):
        for i in range(nu):
            a = 1 + j * nu + i; b = 1 + j * nu + (i + 1) % nu
            F.append((a, b, b + nu, a + nu))
    top = len(V) - 1; o = 1 + (nv - 2) * nu
    for i in range(nu):
        F.append((top, o + i, o + (i + 1) % nu))
    return V, F


def _torus(R, rs, axis, n=32, m=6):
    """a ring of square-ish section (m sides) radius R about the given local axis ('X' or 'Z')"""
    V, F = [], []
    for i in range(n):
        a = 2 * math.pi * i / n
        for j in range(m):
            b = 2 * math.pi * j / m + math.pi / m
            rr = R + rs * math.cos(b); h = rs * math.sin(b)
            if axis == 'X':
                V.append((h, rr * math.cos(a), rr * math.sin(a)))
            else:
                V.append((rr * math.cos(a), rr * math.sin(a), h))
    for i in range(n):
        for j in range(m):
            a = i * m + j; b = i * m + (j + 1) % m; c = ((i + 1) % n) * m + (j + 1) % m; d = ((i + 1) % n) * m + j
            F.append((a, b, c, d))
    return V, F


def core_cage(r, hub_r=None, seg=24):
    """the trapped light core: a bright sphere (the Eclipse's last light) caged by two gimbal rings (one about the spine,
    one round the equator), four meridian bars and two hub collars where the spine enters. Origin at the centre, +X along
    the spine. The hubs are the mount (they seat on the spine ends)."""
    p = Part('core')
    hr = hub_r or r * 0.42
    p.add('sphere', 'body', 'ecore', _uv_sphere(r * 0.74, 20, 12))
    for sgn in (1, -1):
        prof = [(sgn * r * 0.55, hr * 1.25), (sgn * r * 1.12, hr * 1.25), (sgn * r * 1.12, hr * 0.8), (sgn * r * 0.55, hr * 0.8)]
        p.add('hub%d' % (sgn > 0), 'mount', 'mauve', revolve(prof if sgn > 0 else prof[::-1], 8, closed=True, phase=math.pi / 8))
    p.add('gimbal0', 'body', 'gunv', _torus(r * 0.96, r * 0.07, 'X', 36, 6))
    p.add('gimbal1', 'body', 'gunv', _torus(r * 0.9, r * 0.06, 'Z', 36, 6))
    for k in range(4):
        a = k * math.pi / 2
        pts = []
        for i in range(9):
            t = -math.pi / 2 + math.pi * i / 8
            x = r * 0.86 * math.sin(t); rr = r * 0.86 * math.cos(t)
            rr = max(rr, hr * 1.1)
            pts.append(Vector((x * 1.08, rr * math.cos(a), rr * math.sin(a))))
        for j, (u, v) in enumerate(zip(pts, pts[1:])):
            p.add('bar%d_%d' % (k, j), 'body', 'steel', rod(u, v, r * 0.045, 6))
    p.fit = dict(centre=P((0, 0, 0)), radius=r)
    return p


# ---------------------------------------------------------------------------------------------------- struts
def strut(a, b, w=0.22, r=0.035, up=(0, 0, 1)):
    """a built truss between two points (world or local): two rails a width w apart, a zigzag web, end lugs. All mount
    (it is structure joining two hull masses)."""
    p = Part('strut')
    a, b = Vector(a), Vector(b)
    d = (b - a); L = d.length; d.normalize()
    u = Vector(up); u = (u - d * u.dot(d)); u = u.normalized() if u.length > 1e-6 else d.orthogonal().normalized()
    rails = [(a + u * w / 2, b + u * w / 2), (a - u * w / 2, b - u * w / 2)]
    for i, (q0, q1) in enumerate(rails):
        p.add('rail%d' % i, 'mount', 'gunv', rod(q0 + d * 0.05, q1 - d * 0.05, r, 6))
    n = max(2, int(L / (w * 1.2)))
    for i in range(n):
        t0 = 0.06 + 0.88 * i / n; t1 = 0.06 + 0.88 * (i + 1) / n
        s0 = 1 if i % 2 == 0 else -1
        q0 = a + d * (L * t0) + u * (s0 * w / 2); q1 = a + d * (L * t1) - u * (s0 * w / 2)
        p.add('web%d' % i, 'mount', 'steel', rod(q0, q1, r * 0.6, 5))
    side = d.cross(u).normalized()
    for j, q in enumerate((a, b)):
        M = frame(q, d, u)
        p.add('lug%d' % j, 'mount', 'mauve', moved(block(-0.12 if j else -0.05, 0.05 if j else 0.12, w * 0.9, w * 0.5, w * 0.12), M))
    p.fit = dict(a=P(a), b=P(b))
    return p


# ---------------------------------------------------------------------------------------------------- surface parts
def corewin(r, depth=0.12, bars=3):
    """a hexagonal armoured port onto the core's light: a raised hex rim, glowing glass set back, bars across it.
    Origin on the surface, local +Z out."""
    p = Part('corewin')
    p.add('rim', 'mount', 'gunv', _zrev([(-0.04, r * 1.25), (depth, r * 1.25), (depth, r * 1.0), (-0.04, r * 1.0)], 6, closed=True))
    p.add('glass', 'body', 'ecore', _zrev([(depth * 0.3, r * 1.0), (depth * 0.3, 0.001)], 6))
    for i in range(bars):
        y = (i - (bars - 1) / 2) * r * 0.55
        p.add('bar%d' % i, 'body', 'steel', block(-r * 0.95, r * 0.95, 0.025, 0.025, 0, yo=y, zo=depth * 0.75))
    return p


def hatch(w, h, round_=False, wheel=False):
    """an octagonal hatch (local +Z out): a raised rim, a door set proud with a seam, two hinge knuckles"""
    p = Part('hatch')
    r = w / 2
    p.add('rim', 'mount', 'gunv', _zrev([(-0.03, r * 1.2), (0.06, r * 1.2), (0.06, r * 1.02), (-0.03, r * 1.02)], 8, closed=True, phase=math.pi / 8))
    p.add('seam', 'body', 'dark', _zrev([(0.0, r * 1.02), (0.0, r * 0.97)], 8, phase=math.pi / 8))
    p.add('door', 'body', 'violet', _zrev([(0.01, r * 0.96), (0.05, r * 0.96), (0.07, r * 0.8), (0.07, 0.001)], 8, phase=math.pi / 8))
    p.add('doorplate', 'body', 'mauve', block(-r * 0.5, r * 0.5, r * 0.12, r * 0.6, 0.0, zo=0.0))
    p.comps[-1]['verts'] = [Vector((v.x, v.y, 0.075 + 0.02 * (v.z > 0))) for v in p.comps[-1]['verts']]
    for s in (1, -1):
        p.add('hinge%d' % (s > 0), 'body', 'gunv', rod((-r * 0.9, s * r * 0.45, 0.06), (-r * 0.9, s * r * 0.15, 0.06), 0.04, 6))
    return p


def hatchbox(w, l, h, fins=0):
    """a shade-generator housing on the deck: a chamfered frame block, an inset lid under a smaller stacked plate, side
    ribs. Origin on the deck, +X forward."""
    p = Part('hatchbox')
    p.add('frame', 'mount', 'mauve', block(-l / 2, l / 2, w / 2, h / 2, h * 0.35, zo=h / 2 - 0.05, taper=0.88, ztaper=0.85))
    p.add('lid', 'body', 'violet', block(-l * 0.36, l * 0.3, w * 0.36, 0.035, 0.03, zo=h * 0.93))
    p.add('lid2', 'body', 'mauve', block(-l * 0.26, l * 0.18, w * 0.24, 0.03, 0.02, zo=h * 0.99))
    p.add('lidseam', 'body', 'dark', block(-l * 0.38, l * 0.32, w * 0.38, 0.015, 0.02, zo=h * 0.9))
    for i in range(3):
        x = -l * 0.32 + l * 0.32 * i
        for s in (1, -1):
            p.add('rib%d%d' % (i, s > 0), 'body', 'gunv', block(x - 0.035, x + 0.035, 0.03, h * 0.32, 0.0, yo=s * (w / 2 + 0.0), zo=h * 0.48))
    return p


def vent(w, h, slats=5, depth=0.1):
    """a heat slot panel (local +Z out): a frame and slanted slats over a dark recess"""
    p = Part('vent')
    fr = 0.05
    p.add('back', 'mount', 'dark', block(-0.03, 0.01, w / 2, h / 2, 0))
    for (yo, zo, hw, hh) in ((0, h / 2 - fr / 2, w / 2, fr / 2), (0, -h / 2 + fr / 2, w / 2, fr / 2), (w / 2 - fr / 2, 0, fr / 2, h / 2), (-w / 2 + fr / 2, 0, fr / 2, h / 2)):
        p.add('frame', 'mount', 'gunv', block(-0.02, depth, hw, hh, 0, yo=yo, zo=zo))
    for i in range(slats):
        z = -h / 2 + fr + (h - 2 * fr) * (i + 0.5) / slats
        dz = (h - 2 * fr) / slats * 0.3
        p.add('slat%d' % i, 'body', 'violet', prism([(depth * 0.2, [(w / 2 - fr, z - 0.015), (-w / 2 + fr, z - 0.015), (-w / 2 + fr, z + 0.015), (w / 2 - fr, z + 0.015)]),
                                                     (depth * 0.8, [(w / 2 - fr, z + dz - 0.015), (-w / 2 + fr, z + dz - 0.015), (-w / 2 + fr, z + dz + 0.015), (w / 2 - fr, z + dz + 0.015)])]))
    for c in p.comps:
        c['verts'] = [Vector((-v.z, v.y, v.x)) for v in c['verts']]
    return p


def lamp(r=0.08, hood=True):
    """a corona strip light (local +Z out): a low housing with a thin bar lens of green-white light"""
    p = Part('lamp')
    p.add('housing', 'mount', 'gunv', block(-r * 2.2, r * 2.2, r * 0.9, r * 0.35, r * 0.15, zo=r * 0.2))
    p.comps[-1]['verts'] = [Vector((v.x, v.y, v.z)) for v in p.comps[-1]['verts']]
    p.add('lens', 'body', 'corona', block(-r * 1.8, r * 1.8, r * 0.3, r * 0.12, 0.0, zo=r * 0.62))
    return p


def thruster(r=0.3, nozzles=3):
    """an attitude thruster (local +Z out): a chamfered block with a row of slot nozzles"""
    p = Part('thruster')
    p.add('block', 'mount', 'gunv', block(-r, r, r * 0.6, r * 0.35, r * 0.15, zo=r * 0.2))
    for i in range(nozzles):
        y = (i - (nozzles - 1) / 2) * r * 0.55
        p.add('nozzle%d' % i, 'body', 'dark', block(-r * 0.18, r * 0.18, r * 0.2, r * 0.08, 0.0, yo=y, zo=r * 0.58))
    for c in p.comps:
        c['verts'] = [Vector((v.y, v.x, v.z)) for v in c['verts']]
    p.fit = dict(out=D((0, 0, 1)))
    return p


def plate_slab(bot, nrm, t, bevel=0.35, rivets=True, lift=0.0, rr=0.03):
    """one Eclipse armour plate on a hull face: bot = four corners on the surface (world), nrm = outward normal. A
    machine-cut slab of thickness t with a deep chamfer on its top edges (bevel, a fraction of t) and two flush square
    fasteners on its long axis (not rivets: the Starwrights' plate is cut and clamped). lift tilts one corner up (a plate
    lifting away, used sparingly). Returns (verts, faces) for the slab and the fasteners."""
    bot = [Vector(q) for q in bot]; nrm = Vector(nrm)
    mid = sum(bot, Vector()) / 4
    top = []
    for i, q in enumerate(bot):
        sh = (mid - q).normalized() * min(t * (1 + bevel * 2), (mid - q).length * 0.35)
        top.append(q + nrm * (t + (lift if i == 2 else 0.0)) + sh)
    base = [q - nrm * 0.02 for q in bot]
    V = [tuple(q) for q in base + top]
    F = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    RV, RF = [], []
    if rivets:
        e0 = (top[1] - top[0]); e1 = (top[3] - top[0])
        ax = e0 if e0.length > e1.length else e1
        c0 = mid + nrm * t
        for sgn in (1, -1):
            c = c0 + ax * 0.3 * sgn
            u = ax.normalized() * rr; w = nrm.cross(u).normalized() * rr
            q = [c - u - w, c + u - w, c + u + w, c - u + w]
            o = len(RV)
            RV += [tuple(x) for x in q] + [tuple(x + nrm * rr * 0.5) for x in q]
            RF += [tuple(o + i for i in f) for f in F]
    return (V, F), (RV, RF)
