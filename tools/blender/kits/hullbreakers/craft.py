# Ashfall Hullbreaker squadron craft parts (issue 793: the bomber, corsair_KB1CC; R253: each faction its own fighter and bomber).
# The faction sheet (docs/playbooks/factions.md, Ashfall Hullbreakers): a lopsided brick of rust and stolen plate that runs dark;
# bolted, patched; nothing hangs off; mismatched bells with a red-orange glow, one often larger than the rest. Ryan (R254, R259):
# no canopy, no swept aero wings, no tail fins, nothing hung under a hull; drives are nozzle clusters inside armoured blocks; the
# bomber stays a space bomber, never a boat, barge, platform or ground vehicle.
# Why a module of its own: the Hullbreaker kit's parts.py is hashed into the A16 fixture (tools/recipe/sheet_fixture_hash.py), so a
# craft part added there would mark the fixture stale. The craft ship file calls install(HP) on the kit module it was given; it
# adds the craft parts beside the kit's own and changes nothing the kit already builds (engine_bell and rocket_rack keep their
# own behaviour unless called with the craft's own switches: craft=True, variant='bomb').
# A craft is about a sixteenth of the Pyre-Barge's length, so every size below comes from the arguments (no fixed world sizes);
# bold and simple, since fine greeble reads as a shrunken capital ship.
# Local frame of every part: +X forward (the aim, or the drive's thrust direction), +Y left, +Z up (the mount normal).
import math
import os
import sys
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'shared')))
from geom import Part, P, D, revolve, block, moved  # noqa: E402

SUBPARTS = {
    'bomb_tube': ['collar', 'housing', 'bore', 'warhead', 'band', 'bolt'],
    'machbay': ['frame', 'back', 'pipe', 'hoist', 'door', 'hinge'],
    'slit': ['frame', 'glass'],
}
WEAPONS = {
    'bombs': dict(
        name='Bomb payload', rules='data.js bombs: 2 shots, 9 damage, range 1 (k sq), pierce 0.6, crit 10, x0.2 against squadrons',
        lore='Lore 4: the Hullbreakers strip every wreck and run dark; their bombers carry salvaged ordnance in welded tubes. Battle look: bombs.',
        design=('Two bomb tubes, one in each front corner pod of the wide glacis, the widest-separated pair in the field: a heavy dark '
                'armoured collar round each mouth with welded bolt heads, a dark bore with the next salvaged bomb\'s nose seated deep '
                'inside, the tube\'s eight-sided armoured drum running back into the flank with two riveted bands and a welded patch. '
                'Fixed forward: the bomber turns onto its target on a strafing run. Ordnance is internal, never hung under the hull.')),
}


def _stud(c, nrm, r):
    """one welded bolt head: a low four-sided dome at c on a face with normal nrm"""
    c = Vector(c); n = Vector(nrm).normalized()
    u = n.orthogonal().normalized() * r; w = n.cross(u).normalized() * r
    V = [c - u, c - w, c + u, c + w, c + n * r * 0.8]
    return [tuple(v) for v in V], [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (3, 2, 1, 0)]


def _join(parts):
    V, F = [], []
    for v, f in parts:
        o = len(V); V.extend(v); F.extend(tuple(x + o for x in q) for q in f)
    return V, F


def _box(x0, x1, y0, y1, z0, z1, ch=0.0):
    return block(x0, x1, (y1 - y0) / 2, (z1 - z0) / 2, ch, yo=(y1 + y0) / 2, zo=(z1 + z0) / 2)


def bomb_mouth(r, depth, seed=0):
    """one bomb tube in its corner pod (data.js bombs). Origin at the centre of the collar's front face, +X the firing direction.
    r: the mouth's radius; depth: how far the pod's drum runs back into the flank. Every piece is mount: the pod is part of the
    craft's front corner and the bore runs back into it."""
    p = Part('launcher')
    p.type = 'bomb_tube'
    n = 16
    ph = math.pi / 8
    # the heavy dark collar round the mouth: a thick stepped ring standing proud of the drum, its lip chamfered
    p.add('collar', 'mount', 'soot2', revolve([(-r * 0.55, r * 1.0), (-r * 0.55, r * 1.52), (-r * 0.12, r * 1.52), (0.0, r * 1.38), (0.0, r * 1.0)], n,
                                              closed=True, phase=math.pi / n))
    p.add('collarstep', 'mount', 'soot2', revolve([(-r * 0.75, r * 1.42), (-r * 0.75, r * 1.58), (-r * 0.55, r * 1.58), (-r * 0.55, r * 1.42)], 8,
                                                  closed=True, phase=ph))
    p.add('bolt', 'mount', 'iron', _join([_stud((-r * 0.05, r * 1.25 * math.cos(2 * math.pi * (i + 0.3) / 7), r * 1.25 * math.sin(2 * math.pi * (i + 0.3) / 7)),
                                               (1, 0, 0), r * 0.07) for i in range(7)]))
    # the drum: eight-sided armoured plate running back, two riveted bands, a welded patch on its top
    p.add('housing', 'mount', 'rust', revolve([(-r * 0.7, r * 1.45), (-depth, r * 1.45), (-depth, 0.0001)], 8, cap0=False, phase=ph))
    for k, f in enumerate((0.38, 0.72)):
        x = -r * 0.7 - (depth - r * 0.7) * f
        p.add('band%d' % k, 'mount', 'iron', revolve([(x + r * 0.12, r * 1.43), (x + r * 0.12, r * 1.53), (x - r * 0.12, r * 1.53), (x - r * 0.12, r * 1.43)], 8,
                                                     closed=True, phase=ph))
        p.add('bandbolt%d' % k, 'mount', 'iron', _join([_stud((x, r * 1.53 * math.cos(ph + math.pi * j / 4), r * 1.53 * math.sin(ph + math.pi * j / 4)),
                                                              (0, math.cos(ph + math.pi * j / 4), math.sin(ph + math.pi * j / 4)), r * 0.06) for j in range(8)]))
    a = math.pi / 2 + (0.4 if seed % 2 else -0.4)
    c_, s_ = math.cos(a), math.sin(a)
    p.add('patch', 'mount', 'blood' if seed % 2 else 'pale', moved(_box(-depth * 0.62, -depth * 0.3, -r * 0.42, r * 0.42, 0, r * 0.08),
                                                                   Matrix.Translation((0, c_ * r * 1.42, s_ * r * 1.42)) @ Matrix.Rotation(a - math.pi / 2, 4, 'X')))
    # the bore: a dark lined tube, the next bomb's nose seated deep inside (salvaged ordnance, brass-banded)
    p.add('bore', 'mount', 'soot2', revolve([(0.0, r * 1.0), (-depth * 0.72, r * 1.0)], n))
    p.add('boreback', 'mount', 'dark', revolve([(-depth * 0.72, r * 1.01), (-depth * 0.72, 0.0001)], n))
    p.add('warhead', 'mount', 'warhead', revolve([(-depth * 0.7, r * 0.84), (-depth * 0.5, r * 0.82), (-depth * 0.36, r * 0.48), (-depth * 0.32, 0.0001)], n))
    p.add('warheadband', 'mount', 'brass', revolve([(-depth * 0.56, r * 0.83), (-depth * 0.56, r * 0.9), (-depth * 0.5, r * 0.9), (-depth * 0.5, r * 0.83)], n, closed=True))
    p.fit = dict(exits=[dict(pos=P((0.0, 0.0, 0.0)), axis=D((1, 0, 0)), radius=r)])
    return p


def craft_drive(r, body_len, bell_len=None, seed=0):
    """a craft's drive (the owner's rule for craft: nozzle clusters inside armoured blocks): a salvaged bell with a red-orange glow.
    Origin at the centre of the bell's exit plane, exhaust along -X. bell: a flared shell with a thick lip; lining: ember inside;
    throat_glow and the plug cone deep in it (the plug glows, R228's lesson: never black); cool: one cooling ring; housing: a short
    drum running forward into the stern (the mount) with a collar and a band; strut: gimbal struts from the drum to the bell."""
    p = Part('engine')
    bl = bell_len or r * 1.15
    t = r * 0.11
    rt = r * 0.55
    k = 6
    outer = [(bl - bl * i / k, rt + (r - rt) * (i / k) ** 1.5) for i in range(k + 1)]
    lip = [(-t * 0.5, r + t * 1.0), (-t * 0.5, r - t * 0.5)]
    inner = [(x, max(rt * 0.8, rr - t * 1.3)) for (x, rr) in reversed(outer)]
    seg = 18
    p.add('bell', 'body', 'steel', revolve(outer + lip + inner[1:], seg, closed=True, phase=math.pi / seg))
    p.add('lining', 'body', 'ember', revolve([(x - r * 0.01, max(rt * 0.78, rr - t * 1.35)) for (x, rr) in outer[::-1][:-1]], seg, phase=math.pi / seg))
    p.add('throat_glow', 'body', 'glow', revolve([(bl * 0.92, rt * 0.8), (bl * 0.98, 0.0001)], seg, cap0=False))
    p.add('cone', 'body', 'glow', revolve([(bl * 0.9, rt * 0.6), (bl * 0.55, rt * 0.4), (bl * 0.22, 0.0001)], seg, cap0=True))
    xr = bl * 0.5; rr_ = rt + (r - rt) * (1 - xr / bl) ** 1.5
    p.add('cool0', 'body', 'iron', revolve([(xr + t * 0.7, rr_ - t * 0.1), (xr + t * 0.7, rr_ + t * 0.8), (xr - t * 0.7, rr_ + t * 0.8), (xr - t * 0.7, rr_ - t * 0.1)],
                                           seg, closed=True, phase=math.pi / seg))
    br = r * 0.82
    p.add('housing', 'mount', 'soot', revolve([(bl - t, rt + t), (bl + r * 0.25, br), (bl + body_len, br), (bl + body_len, 0.0001)], 10, cap0=True, phase=math.pi / 10))
    p.add('collar', 'mount', 'iron', revolve([(bl + r * 0.3, br * 0.98), (bl + r * 0.3, br * 1.12), (bl + r * 0.55, br * 1.12), (bl + r * 0.55, br * 0.98)],
                                             10, closed=True, phase=math.pi / 10))
    p.add('band', 'mount', 'iron', revolve([(bl + body_len * 0.7, br * 0.98), (bl + body_len * 0.7, br * 1.08), (bl + body_len * 0.82, br * 1.08),
                                            (bl + body_len * 0.82, br * 0.98)], 10, closed=True, phase=math.pi / 10))
    for i in range(3):
        a = 2 * math.pi * (i + 0.25 + 0.1 * seed) / 3
        c, s = math.cos(a), math.sin(a)
        a0 = Vector((bl + r * 0.35, br * 0.95 * c, br * 0.95 * s)); a1 = Vector((bl * 0.55, (rr_ + t) * c, (rr_ + t) * s))
        d_ = a1 - a0; L = d_.length
        M = Matrix.Translation(a0) @ d_.to_track_quat('X', 'Z').to_matrix().to_4x4()
        p.add('strut%d' % i, 'mount', 'steel', moved(revolve([(0, r * 0.06), (L, r * 0.06)], 6, cap0=True, cap1=True), M))
    p.fit = dict(exit=P((0, 0, 0)), axis=D((-1, 0, 0)), radius=r + t, front=P((bl + body_len, 0, 0)), body_r=br)
    return p


def machbay(w, h, depth, door=0.45, seed=0):
    """a flank machinery bay (KB1C-C's recessed side bays): the bomb hoist that walks the next bomb from the magazine into its tube,
    behind an armoured door. Local +Z out of the hull wall, +X along the craft. A heavy frame stands proud of the wall round a dark
    back plate; pipes and the hoist block sit inside it; the door, in a second tone, covers the fore part of the bay on hinges."""
    p = Part('machbay')
    p.type = 'machbay'
    fr = min(w, h) * 0.12
    hw, hh = w / 2, h / 2
    for (x0, x1, y0, y1) in ((-hw, hw, hh - fr, hh), (-hw, hw, -hh, -hh + fr), (hw - fr, hw, -hh, hh), (-hw, -hw + fr, -hh, hh)):
        p.add('frame', 'mount', 'iron', _box(x0, x1, y0, y1, -depth * 0.3, depth))
    p.add('back', 'mount', 'dark', _box(-hw + fr, hw - fr, -hh + fr, hh - fr, -depth * 0.3, depth * 0.1))
    for k, y in enumerate((-hh * 0.45, hh * 0.15)):
        p.add('pipe%d' % k, 'mount', 'steel', moved(revolve([(-hw + fr, fr * 0.32), (hw - fr, fr * 0.32)], 6, cap0=True, cap1=True), Matrix.Translation((0, y, depth * 0.35))))
    p.add('hoist', 'mount', 'soot2', _box(-hw * 0.15, hw * 0.35, -hh * 0.6, hh * 0.6, 0.0, depth * 0.75, ch=fr * 0.2))
    p.add('hoistarm', 'mount', 'steel', _box(hw * 0.35, hw * 0.75, -hh * 0.1, hh * 0.25, depth * 0.2, depth * 0.6))
    xd = hw - fr - (w - 2 * fr) * door
    p.add('door', 'mount', 'pale' if seed % 2 else 'rust', _box(xd, hw - fr * 0.4, -hh + fr * 0.4, hh - fr * 0.4, depth, depth * 1.45, ch=fr * 0.15))
    for k in range(2):
        y = -hh * 0.4 + hh * 0.8 * k
        p.add('doorrib%d' % k, 'mount', 'soot2', _box(xd + fr * 0.3, hw - fr * 0.7, y - fr * 0.18, y + fr * 0.18, depth * 1.45, depth * 1.7))
    for y in (-hh * 0.6, hh * 0.6):
        p.add('hinge', 'mount', 'iron', moved(revolve([(-hh * 0.12, fr * 0.3), (hh * 0.12, fr * 0.3)], 6, cap0=True, cap1=True),
                                               Matrix.Translation((xd, y, depth * 1.2)) @ Matrix.Rotation(math.pi / 2, 4, 'Z')))
    return p


def slit(w, h, depth, fr):
    """the crew's vision slit (local +Z out of the face): a welded iron frame round a dark recessed pane (the craft runs dark)"""
    p = Part('slit')
    for (y0, y1, x0, x1) in ((-w / 2 - fr, w / 2 + fr, h / 2, h / 2 + fr), (-w / 2 - fr, w / 2 + fr, -h / 2 - fr, -h / 2), (w / 2, w / 2 + fr, -h / 2, h / 2),
                             (-w / 2 - fr, -w / 2, -h / 2, h / 2)):
        p.add('frame', 'mount', 'iron', _box(x0, x1, y0, y1, -depth * 0.3, depth))
    p.add('glass', 'mount', 'dark', _box(-h / 2, h / 2, -w / 2, w / 2, -depth * 0.3, depth * 0.2))
    return p


def install(HP):
    """add the craft parts to the Hullbreaker kit module HP (this build only): rocket_rack(..., variant='bomb') builds a bomb tube,
    engine_bell(..., craft=True) a craft drive; everything else the kit builds is unchanged"""
    base_rack, base_bell = HP.rocket_rack, HP.engine_bell

    def rocket_rack(rows, cols, cell=0.4, depth=1.8, yoke=True, variant=0, seg=12):
        if isinstance(variant, str) and variant.startswith('bomb'):
            return bomb_mouth(cell * 0.3, depth, seed=int(variant[4:] or 0))
        return base_rack(rows, cols, cell, depth, yoke=yoke, variant=variant, seg=seg)

    def engine_bell(r_exit, body_len, bell_len=None, body_r=None, throat=0.55, rings=3, struts=4, nose='dome', seg=28, craft=False, craft_len=None, seed=0):
        if craft:
            return craft_drive(r_exit, body_len, bell_len=craft_len, seed=seed)
        return base_bell(r_exit, body_len, bell_len=bell_len, body_r=body_r, throat=throat, rings=rings, struts=struts, nose=nose, seg=seg)
    HP.rocket_rack = rocket_rack
    HP.engine_bell = engine_bell
    for k, v in SUBPARTS.items():
        HP.SUBPARTS.setdefault(k, v)
    if 'launcher' not in HP.MACHINES:
        HP.MACHINES = tuple(HP.MACHINES) + ('launcher',)   # the bomb tube rides whole with one piece (R226)
    W = dict(getattr(HP, 'WEAPONS', {}) or {})
    W.update(WEAPONS)
    HP.WEAPONS = W
    return HP
