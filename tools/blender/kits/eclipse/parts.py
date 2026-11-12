# Eclipse (`deathless`) part shapes (issue 532, the E11 and E12 build sheets; RULEBOOK 4.5: every faction its own kit, only
# invisible plumbing shared, from tools/blender/kits/shared/geom.py).
# The faction sheet (docs/playbooks/factions.md, Eclipse): "a black shade with a thin ring of green-white fire at its edge";
# sunshades and heat shields, broad layered plates; the green is a thin cold line along the rim of every shade plate and the
# trapped light core seen through gaps; engines are no flaming bells but an eclipse ring of pale light; never bone, ribs,
# skulls, green pooled in hollows, or flame. Ryan's part rules (R217, R218) hold for every type: an engine reads as an
# engine, a gun has a base, a mantlet, a breech and a muzzle, every part carries the ship's detail level.
#   engine_bell  the eclipse engine: a faceted ribbed drum on a mount collar, radial vanes, a short bell with a thick lip,
#                a thin corona ring of pale green-white light just inside the lip around a black shade disc (no flame)
#   gun          the null cannon turret: a two-step hexagonal plinth (fixed), a low faceted housing under two stacked shade
#                plates (the cowl), a slotted mantlet on trunnions, breech blocks, slim barrels wound with accelerator coils
#                and a ringed muzzle; four or more barrels make a clustered flak head (the null shredder) in a shroud
#   spinal       the corona arc projector: stepped octagonal breech collars, octagonal shaft segments with bands and four
#                rails, an octagonal muzzle block, a dark bore ring and a recessed green emitter lens
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

SUBPARTS = {
    'engine': ['housing', 'collar', 'rib', 'vane', 'bell', 'corona', 'shade'],
    'gun': ['ring|plate', 'housing', 'cowl', 'mantlet', 'breech', 'tube', 'coil', 'muzzle', 'bore'],
    'spinal': ['breech', 'segment', 'band', 'rail', 'block', 'bore', 'lens'],
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
def _barrel(L, cal, coils=3, seg=12):
    """a null cannon barrel along +X from x = 0: a thick root sleeve, a slim tube wound with accelerator coils, a ringed
    muzzle collar and a dark bore"""
    p = Part('barrel')
    xs = L * 0.22
    prof = [(0, cal * 1.45), (xs, cal * 1.45), (xs + cal * 0.5, cal * 0.95), (L * 0.94, cal * 0.88), (L * 0.94, cal * 0.62), (L * 0.9, cal * 0.62)]
    p.add('tube', 'body', 'gunv', revolve(prof, seg, cap0=True, phase=math.pi / seg))
    p.add('muzzle', 'body', 'steel', revolve([(L * 0.9, cal * 1.0), (L * 0.9, cal * 1.32), (L, cal * 1.32), (L, cal * 0.68), (L * 0.95, cal * 0.68),
                                              (L * 0.95, cal * 1.0)], seg, closed=True, phase=math.pi / seg))
    p.add('bore', 'body', 'dark', revolve([(L * 0.9, 0.001), (L * 0.9, cal * 0.66), (L + 0.002, cal * 0.66)], seg))
    for i in range(coils):
        x = xs + (L * 0.86 - xs) * (i + 0.6) / (coils + 0.4)
        p.add('coil%d' % i, 'body', 'mauve', ring_band(x, cal * 0.9, cal * 0.9, cal * 0.32, seg))
    return p


def gun(barrels=2, cal=0.12, blen=2.0, size=1.0, mount='turret', pitch=0.0, variant=0, seg=6):
    """an Eclipse gun mount. Origin on the hull surface at the mount centre, local +Z the mount normal, +X the rest aim; the
    barrels elevate by pitch about the trunnions.
    turret: a two-step hexagonal plinth (fixed: 'ring' and 'plate'), a low faceted housing narrowing to a wedge front, two
    stacked shade plates over its roof (the cowl, Eclipse's layered plates), a slotted mantlet, breeches, coiled barrels.
    barrels >= 4: the null shredder, a cluster of short barrels round one axis inside a shroud ring.
    casemate: a flank mount, a hexagonal plate on the hull, a faceted box housing, a slotted mantlet."""
    s = size
    p = Part('gun')
    cluster = barrels >= 4
    W = 0.66 * s * (1 + 0.22 * (min(barrels, 3) - 1)) if not cluster else 0.8 * s
    Lh = 1.0 * s
    H = 0.42 * s
    if mount == 'turret':
        rr = max(W, Lh) * 0.6
        p.add('plate', 'mount', 'shade', _zrev([(-0.3 * s, rr * 1.32), (0.0, rr * 1.32), (0.0, rr * 1.22), (0.06 * s, rr * 1.18), (0.06 * s, 0.001)],
                                              6, phase=math.pi / 6, cap0=True))
        p.add('ring', 'mount', 'gunv', _zrev([(0.05 * s, rr * 1.02), (0.15 * s, rr * 1.02), (0.15 * s, rr * 0.9), (0.18 * s, rr * 0.86), (0.18 * s, 0.001)],
                                             6, phase=math.pi / 6))
        z0 = 0.18 * s
        zc = z0 + H / 2
        secs = [(-Lh * 0.55, octa(W * 0.42, H * 0.42, H * 0.3, 0, zc - H * 0.06)),
                (-Lh * 0.4, octa(W * 0.5, H * 0.5, H * 0.32, 0, zc)),
                (Lh * 0.1, octa(W * 0.5, H * 0.5, H * 0.32, 0, zc)),
                (Lh * 0.42, octa(W * 0.3, H * 0.34, H * 0.2, 0, zc - H * 0.12))]
        p.add('housing', 'body', 'mauve', prism(secs))
        # two stacked shade plates over the roof, the upper one smaller and set back (layered, as the hull's shades)
        p.add('cowl0', 'body', 'violet', block(-Lh * 0.52, Lh * 0.18, W * 0.54, 0.035 * s, 0.02 * s, zo=zc + H * 0.5 + 0.03 * s, taper=0.82))
        p.add('cowl1', 'body', 'mauve', block(-Lh * 0.42, Lh * 0.02, W * 0.4, 0.03 * s, 0.02 * s, zo=zc + H * 0.5 + 0.09 * s, taper=0.85))
        p.add('sensor', 'body', 'dark', block(Lh * 0.0, Lh * 0.12, W * 0.08, 0.03 * s, 0, yo=W * 0.3, zo=zc + H * 0.42))
        if variant % 2:
            p.add('sensor2', 'body', 'dark', block(Lh * 0.0, Lh * 0.12, W * 0.08, 0.03 * s, 0, yo=-W * 0.3, zo=zc + H * 0.42))
        mx = Lh * 0.4
        mantlet_r = H * 0.4
        trunnion = Vector((mx - mantlet_r * 0.4, 0, zc - H * 0.08))
    else:
        pw = Lh * 1.2; ph = W * 1.2
        p.add('plate', 'mount', 'shade', moved(block(-0.25 * s, 0.06 * s, pw * 0.5, ph * 0.5, ph * 0.3),
                                               Matrix.Rotation(-math.pi / 2, 4, 'Y') @ Matrix.Rotation(math.pi / 2, 4, 'X')))
        z0 = 0.06 * s; zo = z0 + 0.55 * s
        p.add('housing', 'body', 'mauve', prism([(-Lh * 0.5, octa(W * 0.5, (zo - z0) / 2, 0.12 * s, 0, (z0 + zo) / 2)),
                                                 (Lh * 0.5, octa(W * 0.42, (zo - z0) / 2 * 0.9, 0.12 * s, 0, (z0 + zo) / 2))]))
        p.add('cowl0', 'body', 'violet', block(-Lh * 0.5, Lh * 0.4, W * 0.55, 0.03 * s, 0.02 * s, zo=zo + 0.03 * s))
        mantlet_r = 0.24 * s
        trunnion = Vector((0, 0, zo - mantlet_r * 0.6))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    mw = W * 0.78
    # the mantlet: a squared slab on the trunnions with a dark slot per barrel
    p.add('mantlet', 'body', 'gunv', moved(block(-mantlet_r * 0.5, mantlet_r * 0.45, mw / 2, mantlet_r, mantlet_r * 0.35), E))
    for sgn in (1, -1):
        p.add('trunnion%d' % (sgn > 0), 'body', 'steel', moved(rod((0, sgn * mw / 2, 0), (0, sgn * (mw / 2 + 0.06 * s), 0), mantlet_r * 0.4, 8), E))
    muzzles = []
    bx0 = mantlet_r * 0.4
    if cluster:
        rcl = cal * 2.3
        for i in range(barrels):
            a = 2 * math.pi * i / barrels
            off = Vector((0, rcl * math.cos(a), rcl * math.sin(a)))
            b = _barrel(blen, cal, coils=1, seg=8)
            for c in b.comps:
                p.add('b%d_%s' % (i, c['name']), c['role'], c['mat'], moved((c['verts'], c['faces']), E @ Matrix.Translation(Vector((bx0, 0, 0)) + off)))
            muzzles.append(P(E @ (Vector((bx0 + blen, 0, 0)) + off)))
        p.add('breech0', 'body', 'gunv', moved(block(-mantlet_r * 1.4, -mantlet_r * 0.3, rcl * 1.3, rcl * 1.3, rcl * 0.5), E))
        for j, x in enumerate((blen * 0.3, blen * 0.75)):
            p.add('shroud%d' % j, 'body', 'mauve', moved(ring_band(bx0 + x, rcl + cal * 1.1, cal * 1.6, cal * 0.45, 12), E))
    else:
        for i in range(barrels):
            off = (i - (barrels - 1) / 2) * cal * 3.8
            p.add('slot%d' % i, 'body', 'dark', moved(block(mantlet_r * 0.44, mantlet_r * 0.47, cal * 1.7, cal * 1.7, 0, yo=off), E))
            p.add('breech%d' % i, 'body', 'gunv', moved(block(-mantlet_r * 1.7, -mantlet_r * 0.4, cal * 1.8, cal * 1.6, cal * 0.6, yo=off), E))
            b = _barrel(blen, cal)
            for c in b.comps:
                p.add('b%d_%s' % (i, c['name']), c['role'], c['mat'], moved((c['verts'], c['faces']), E @ Matrix.Translation((bx0, off, 0))))
            muzzles.append(P(E @ Vector((bx0 + blen, off, 0))))
    if mount == 'turret':
        for c in p.comps:
            if c['role'] == 'body':
                c['role'] = 'turn'
    pivot = Vector((0, 0, trunnion.z))
    p.fit = dict(pivot=P(pivot), trunnion=P(trunnion), muzzles=muzzles, reach=bx0 + blen + trunnion.x,
                 aim=D(E.to_3x3() @ Vector((1, 0, 0))), up=D((0, 0, 1)), mount=mount, radius=max(W, Lh) * 0.62)
    return p


# ---------------------------------------------------------------------------------------------------- the corona arc projector
def spinal(length, r=0.55, collar_r=None, collar_len=None, block_len=None, block_r=None, seg=8):
    """the corona arc projector (data.js doom, slot F; the Tomb-ark's spinal shell). Origin at the root on the hull's front
    face, +X forward to the emitter. Stepped octagonal breech collars at the root (the mount: they sink into the hull),
    octagonal shaft segments with raised bands between them and four rails along them, an octagonal muzzle block, a dark
    bore ring and a recessed green emitter lens."""
    p = Part('spinal')
    cr = collar_r or r * 1.6
    cl = collar_len or length * 0.4
    bl = block_len or length * 0.22
    brr = block_r or r * 1.3
    ph = math.pi / seg
    # collars: three steps, each a short octagonal drum with a dark gap behind it
    xs = [-0.6, cl * 0.3, cl * 0.62, cl]
    rs = [cr, cr * 0.9, cr * 0.8]
    for i in range(3):
        a, b = xs[i], xs[i + 1]
        p.add('breech%d' % i, 'mount', 'mauve' if i % 2 == 0 else 'violet',
              revolve([(a, rs[i] * 0.7), (a, rs[i]), (b - 0.08, rs[i]), (b - 0.02, rs[i] * 0.93), (b - 0.02, rs[i] * 0.7)], seg, closed=True, phase=ph))
        p.add('breechgap%d' % i, 'mount', 'dark', revolve([(b - 0.03, rs[i] * 0.72), (b + 0.03, rs[i] * 0.72)], seg, cap0=True, cap1=True, phase=ph))
    # the shaft: three segments, each a touch narrower, with bands between
    x0, x1 = cl, length - bl
    n = 3
    for i in range(n):
        a = x0 + (x1 - x0) * i / n; b = x0 + (x1 - x0) * (i + 1) / n
        ri = r * (1.0 - 0.04 * i)
        p.add('segment%d' % i, 'body', 'violet' if i % 2 else 'mauve', revolve([(a, ri), (b, ri)], seg, cap0=True, cap1=True, phase=ph))
        p.add('band%d' % i, 'body', 'gunv', revolve([(a - 0.06, ri * 0.98), (a - 0.06, ri * 1.14), (a + 0.12, ri * 1.14), (a + 0.12, ri * 0.98)],
                                                     seg, closed=True, phase=ph))
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        c, s_ = math.cos(a), math.sin(a)
        p.add('rail%d' % k, 'body', 'gunv', rod((x0 + 0.15, r * 1.0 * c, r * 1.0 * s_), (x1 - 0.1, r * 0.92 * c, r * 0.92 * s_), r * 0.09, 6))
    # the muzzle block: an octagonal block with a chamfered face and a dark bore ring round the lens
    p.add('block', 'body', 'mauve', revolve([(x1, r * 0.95), (x1 + 0.08, brr), (length - 0.12, brr), (length, brr * 0.86), (length, brr * 0.62),
                                             (length - 0.05, brr * 0.62)], seg, closed=True, phase=ph))
    p.add('blockcap', 'body', 'violet', revolve([(x1 + bl * 0.35, brr * 0.99), (x1 + bl * 0.35, brr * 1.06), (x1 + bl * 0.5, brr * 1.06),
                                                (x1 + bl * 0.5, brr * 0.99)], seg, closed=True, phase=ph))
    p.add('bore', 'body', 'dark', revolve([(length - 0.05, brr * 0.62), (length - 0.3, brr * 0.5), (length - 0.3, 0.001)], 16))
    p.add('lens', 'body', 'lens', revolve([(length - 0.28, brr * 0.34), (length - 0.2, brr * 0.3), (length - 0.16, 0.001)], 16, cap0=True))
    p.fit = dict(muzzles=[P((length, 0, 0))], pivot=P((length - 0.05, 0, 0)), trunnion=P((length - 0.05, 0, 0)), reach=0.3,
                 aim=D((1, 0, 0)), up=D((0, 0, 1)), mount='spinal', radius=brr)
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
