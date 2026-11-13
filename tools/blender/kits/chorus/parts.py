# The Chorus (`chorus`) part shapes (issue 623, the C10 and C11 build sheets; RULEBOOK 4.5: every faction its own kit, only
# invisible plumbing shared, from tools/blender/kits/shared/geom.py).
# The faction sheet (docs/playbooks/factions.md, The Chorus) and the lore (contrib/opus/compute/lore_bible_r8.md 5.3, 5.5):
# grown, not built: ridges, pores, veins, glowing sacs, tendrils, brood sacs and regrowing scar tissue; no panels, no pipes, no
# metal, no eyes, no face, no legs, no grub segments; dark olive flesh, ochre bone and chitin, bile yellow-green light from
# inside. "Guns sit in throats, spines and sacs: a weapon is an organ." Engines: "no nozzles. Pulsing vents or trailing
# membranes with a yellow-green glow." No shields; they win by regrowth and mass.
# Ryan's part rules hold for every type (R217, R218, R221, R224): every part reads as what it is, carries the hull's detail
# density (pores, creases, growth lines, rings and folds stand in for the plate steps and rivets of a built ship), and has a job.
#   throat       (bioplasma, the Spine volley, slot F; fixed) a bile spitter: a muscular root grown out of the head, rolled
#                fold lips (folded, C10) or a flared rim (flared, C11), an inner sphincter, a ring of chitin spines (the
#                spines it spits), a dark bore and a glowing bile gland at its back
#   gun          tendril (Boarding tendrils, slot T): a crown of hooked tendrils from a sphincter on a muscle mound (turns),
#                or a mane rooted along a crest (fixed); spores (Spore cloud, slot T): a hanging spore gland: a neck collar,
#                a veined sac, a forward spout ending in a rosette of pores (turns)
#   engine_bell  the pulse vent: a muscular cone grown into the hull, radial folds, a sphincter mouth, a dark throat with
#                bile glow deep in it, and trailing membrane veils (membrane) or glowing filaments (filament); no nozzle
#   thruster     a siphon: a puckered jet pore on a muscle collar (attitude)
#   sac          a bile or regrowth sac: a socket of wrinkled tissue, the sac, creases, surface veins, glow windows
#   brood_sac    the hangar: a brood sac with a birth slit between lip rolls (spore swarms are born from it)
#   spine_blade  a bone blade: transition tissue collar, a raked blade with growth lines and a serrated edge
#   chitin       an ochre chitin scute: a domed plate, a raised rim, growth lines
#   plate_slab   (the hull's surface layer, called by the sheet kit) a callus pad of hide with sense pores, never a panel
#   hull detail  welt (ridges, fold rolls), vein, pore, scar (patch and knit): (verts, faces) the ship lays on its own hull
# Local frame of every part: +X forward (the aim, or the vent's thrust direction), +Y left, +Z up (the mount normal).
# Roles: 'mount' may sit into the hull (roots, collars, sockets, grown-in folds); every other role must stay clear of it;
# 'turn' turns with a turret (R219).
# Materials (mapped by tools/blender/build_sheets/kit.py MATS): flesh, flesh2, hide, scar, chitin, bone, bile, bilewet, maw,
# membrane, pore, tissue.
import math
import os
import sys
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'shared')))
from geom import Part, P, D, frame, revolve, prism, moved, rod  # noqa: E402,F401
import geom  # noqa: E402

# R226: the part kinds that are machines (never across a seam). Organs that fire or drive are machines; sacs, blades, scutes,
# veins and the hide are structure and tear.
MACHINES = ('gun', 'spinal', 'engine', 'thruster')
SMOOTH = True   # grown parts are smooth shaded (the sheet kit reads it)

SUBPARTS = {
    'throat': ['root', 'fold|lip', 'sphincter', 'tooth', 'bore', 'gland'],
    'tendril': ['root', 'sphincter', 'stalk', 'ring', 'barb', 'pore'],
    'mane': ['root', 'crest', 'stalk', 'ring', 'barb'],
    'spore': ['root', 'sac', 'vein', 'spout', 'pore'],
    'engine': ['root', 'fold', 'sphincter', 'throat', 'glow', 'membrane|filament'],
    'thruster': ['collar', 'lip', 'bore'],
    'sac': ['root', 'sac', 'crease', 'vein', 'glow'],
    'brood': ['root', 'sac', 'crease', 'slit', 'lip', 'vein'],
    'spine': ['collar', 'blade', 'growth', 'edge'],
    'chitin': ['plate', 'rim', 'growth'],
    'plate': ['pad', 'pore'],
    'hull': ['ridge', 'fold', 'pore'],
    'welt': ['welt'],
    'vein': ['vein', 'branch'],
    'pore': ['rim', 'pit'],
    'scar': ['patch', 'knit'],
    'wound': ['channel', 'lip', 'tissue'],
}

WEAPONS = {
    'bioplasma': dict(
        name='Spine volley', rules='data.js bioplasma (Bile spray): 2 shots, 10 damage, range 4; Chorus trait spines (strips armour)',
        lore='Lore 5.5: "spines that strip armour"; 5.10 weapons: Spine volley, Bile spray. Battle effect (fx_weapons.gd, spine): '
             'wobbling globs that splash and corrode.',
        design='A throat, not a barrel: a muscular root grown out of the head, the mouth closed by rolled fold lips (C10) or a '
               'flared rim (C11), an inner sphincter that squeezes the shot, a ring of chitin spines round the bore (the spines '
               'it spits inside each glob of bile), a dark bore and a glowing bile gland at its back. Fixed forward: the head '
               'turns, not the throat.'),
    'tendril': dict(
        name='Boarding tendrils', rules='data.js tendril: 2 shots, 11 damage, range 1, pierce 0.5; Chorus trait acid (hull hits '
                                        'leave acid through shields and armour)',
        lore='Lore 5.5: "boarding tendrils, acid that eats through shields and armour". Battle effect (tendril): an organic lash.',
        design='Hooked tendrils, each a tapering muscle with raised grip rings, a chitin barb at its tip and acid pores behind '
               'the barb, rooted in a sphincter on a muscle mound: a crown that leans toward its prey (C10, turns) or a mane '
               'along a crest of the back (C11, fixed; a mane reaches every way at once).'),
    'spores': dict(
        name='Spore cloud', rules='data.js spores (Spore drifts): 3 shots, 4 damage, range 2; flak (x3 against squadrons)',
        lore='Lore 5.10: Spore cloud. Battle effect (spores): soft airbursts of spores.',
        design='A spore gland, not a flak gun: a sac hanging from a neck collar under the belly, veined, its spout curling '
               'forward to a rosette of pores that puff the cloud; it swings on its neck to face the craft.'),
}


def detail_ok(kind, names):
    return geom.detail_ok(SUBPARTS, kind, names)


# ------------------------------------------------------------------------------------------------ geometry helpers
def _noise(seed):
    """a smooth deterministic lump field on the unit sphere: sum of a few sine waves"""
    import random
    r = random.Random(seed)
    waves = [(Vector((r.uniform(-1, 1), r.uniform(-1, 1), r.uniform(-1, 1))).normalized() * r.uniform(2.0, 5.5), r.uniform(0, 6.28),
              r.uniform(0.3, 1.0)) for _ in range(6)]
    tot = sum(w[2] for w in waves)

    def f(v):
        return sum(a * math.sin(k.dot(v) + ph) for k, ph, a in waves) / tot
    return f


def blob(rx, ry, rz, centre=(0, 0, 0), nu=24, nv=14, seed=0, amp=0.06, squash=None):
    """a lumpy ellipsoid (uv sphere displaced by a smooth noise along its normal). squash(z) -> radius scale by height"""
    nf = _noise(seed)
    V = [(centre[0], centre[1], centre[2] - rz)]
    for j in range(1, nv):
        th = math.pi * j / nv - math.pi / 2
        for i in range(nu):
            ph = 2 * math.pi * i / nu
            u = Vector((math.cos(th) * math.cos(ph), math.cos(th) * math.sin(ph), math.sin(th)))
            k = 1 + amp * nf(u)
            s = squash(u.z) if squash else 1.0
            V.append((centre[0] + rx * u.x * k * s, centre[1] + ry * u.y * k * s, centre[2] + rz * u.z * k))
    V.append((centre[0], centre[1], centre[2] + rz))
    F = [(0, 1 + (i + 1) % nu, 1 + i) for i in range(nu)]
    for j in range(nv - 2):
        for i in range(nu):
            a = 1 + j * nu + i; b = 1 + j * nu + (i + 1) % nu
            F.append((a, b, b + nu, a + nu))
    top = len(V) - 1; o = 1 + (nv - 2) * nu
    F += [(o + i, o + (i + 1) % nu, top) for i in range(nu)]
    return V, F


def _frames(pts):
    """parallel-transport frames along a polyline: (tangent, normal, binormal) per point"""
    pts = [Vector(p) for p in pts]
    T = []
    for i in range(len(pts)):
        d = pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]
        T.append(d.normalized() if d.length > 1e-9 else Vector((1, 0, 0)))
    N = [T[0].orthogonal().normalized()]
    for i in range(1, len(pts)):
        n = N[-1] - T[i] * N[-1].dot(T[i])
        N.append(n.normalized() if n.length > 1e-9 else T[i].orthogonal().normalized())
    B = [t.cross(n) for t, n in zip(T, N)]
    return pts, T, N, B


def tube(pts, radii, n=8, cap0=True, cap1=True, flat=1.0, up=None):
    """a tube swept along pts with a radius per point; flat < 1 squashes the section along the binormal (a welt)"""
    pts, T, N, B = _frames(pts)
    if up is not None:
        # a fixed up for welts lying on a surface: N points away from the surface
        N = []; B = []
        for i, t in enumerate(T):
            u = Vector(up[i] if isinstance(up, list) else up)
            n = (u - t * u.dot(t)); n = n.normalized() if n.length > 1e-9 else t.orthogonal()
            N.append(n); B.append(t.cross(n))
    V, F = [], []
    for p, nn, bb, r in zip(pts, N, B, radii):
        for k in range(n):
            a = 2 * math.pi * k / n
            V.append(tuple(p + (nn * math.cos(a) + bb * math.sin(a) * flat) * r))
    m = len(pts)
    for j in range(m - 1):
        for k in range(n):
            a, b = j * n + k, j * n + (k + 1) % n
            F.append((a, b, b + n, a + n))
    if cap0:
        F.append(tuple(range(n))[::-1])
    if cap1:
        F.append(tuple(range((m - 1) * n, m * n)))
    return V, F


def welt(pts, normals, w, h, n=6):
    """a raised rounded welt lying on a surface: pts on the surface, normals outward; w wide, h proud (a half tube sunk a little);
    w and h may be lists (one per point) for a fold that swells and fades"""
    pts, T, _, _ = _frames(pts)
    V, F = [], []
    ws = w if isinstance(w, (list, tuple)) else [w] * len(pts)
    hs = h if isinstance(h, (list, tuple)) else [h] * len(pts)
    for p, t, nr, w, h in zip(pts, T, normals, ws, hs):
        nr = Vector(nr); nr = (nr - t * nr.dot(t)).normalized()
        s = t.cross(nr).normalized()
        for k in range(n + 1):
            a = math.pi * k / n
            V.append(tuple(p - nr * h * 0.3 + s * math.cos(a) * w / 2 + nr * math.sin(a) * h * 1.3))
        V.append(tuple(p - nr * h * 0.5))
    m = len(pts); q = n + 2
    for j in range(m - 1):
        for k in range(q):
            a, b = j * q + k, j * q + (k + 1) % q
            F.append((a, b, b + q, a + q))
    F.append(tuple(range(q))[::-1]); F.append(tuple(range((m - 1) * q, m * q)))
    return V, F


def pore(c, nrm, r, depth=None, n=7):
    """a sense or acid pore on a surface: a raised rim ring round a sunk pit"""
    c = Vector(c); nrm = Vector(nrm).normalized(); u = nrm.orthogonal().normalized(); w = nrm.cross(u)
    d = depth or r * 0.9
    V = []
    for rr, hh in ((r * 1.6, -0.01), (r * 1.15, r * 0.45), (r * 0.75, r * 0.2), (r * 0.5, -d)):
        for k in range(n):
            a = 2 * math.pi * k / n
            V.append(tuple(c + (u * math.cos(a) + w * math.sin(a)) * rr + nrm * hh))
    V.append(tuple(c - nrm * d * 1.1))
    F = []
    for j in range(3):
        for k in range(n):
            a, b = j * n + k, j * n + (k + 1) % n
            F.append((a, b, b + n, a + n))
    F += [(3 * n + k, 3 * n + (k + 1) % n, 4 * n) for k in range(n)]
    return V, F


def scar(c, nrm, r, seed=0, knits=3):
    """regrowing scar tissue: an irregular raised patch (patch) crossed by knit ridges (knit: the new flesh pulling a wound shut).
    Returns two (verts, faces): patch, knits"""
    import random
    rnd = random.Random(seed)
    c = Vector(c); nrm = Vector(nrm).normalized(); u = nrm.orthogonal().normalized(); w = nrm.cross(u)
    ang = rnd.uniform(0, math.pi); u, w = u * math.cos(ang) + w * math.sin(ang), w * math.cos(ang) - u * math.sin(ang)
    n = 14; ring = []
    for k in range(n):
        a = 2 * math.pi * k / n
        rr = r * (0.75 + 0.35 * rnd.random()) * (1.0 if k % 2 else 0.88)
        ring.append((math.cos(a) * rr * 1.5, math.sin(a) * rr))
    V = [tuple(c - nrm * 0.03 + u * x + w * y) for x, y in ring]
    V += [tuple(c + nrm * r * 0.08 + u * x * 0.8 + w * y * 0.8) for x, y in ring]
    V += [tuple(c + nrm * r * 0.13 + u * x * 0.45 + w * y * 0.45) for x, y in ring]
    V.append(tuple(c + nrm * r * 0.15))
    F = []
    for j in range(2):
        for k in range(n):
            a, b = j * n + k, j * n + (k + 1) % n
            F.append((a, b, b + n, a + n))
    F += [(2 * n + k, 2 * n + (k + 1) % n, 3 * n) for k in range(n)]
    F.append(tuple(range(n))[::-1])
    KV, KF = [], []
    for i in range(knits):
        t = (i + 1) / (knits + 1) * 2 - 1
        a = c + u * t * r * 1.2 + nrm * r * 0.12
        pts = [a - w * r * 0.85, a - w * r * 0.3 + nrm * 0.02, a + w * r * 0.3 + nrm * 0.02, a + w * r * 0.85]
        vv, ff = welt(pts, [nrm] * 4, r * 0.09, r * 0.06, n=4)
        o = len(KV); KV += vv; KF += [tuple(x + o for x in f) for f in ff]
    return (V, F), (KV, KF)


def _add_tube_rings(p, name, pts, radii, every, w, k=1.25, mat='flesh2', role='body', n=8):
    """raised grip rings round a tendril or stalk every `every` points"""
    pts_, T, N, B = _frames(pts)
    for i in range(every, len(pts_) - 1, every):
        r = radii[i] * k
        a = pts_[i] - T[i] * w / 2; b = pts_[i] + T[i] * w / 2
        p.add('%s_%d' % (name, i), role, mat, tube([a, pts_[i], b], [radii[i] * 0.95, r, radii[i] * 0.95], n=n))


# ------------------------------------------------------------------------------------------------ the hull's surface layer
def plate_slab(bot, nrm, t, bevel=0.35, rivets=True, lift=0.0, rr=0.03):
    """one callus pad of hide (the sheet kit's plate layer, Chorus version): never a panel. bot = four corners on the surface,
    nrm = outward normal. The pad is an irregular oval inside the four corners, domed t proud, its edge sunk a little into the
    hide; 'rivets' become one to three sense pores on the pad (the Chorus tastes the dark; it has no eyes). Returns
    (verts, faces) for the pad and the pores."""
    bot = [Vector(q) for q in bot]; nrm = Vector(nrm).normalized()
    mid = sum(bot, Vector()) / 4
    eu = (bot[1] - bot[0] + bot[2] - bot[3]) / 2; ev = (bot[3] - bot[0] + bot[2] - bot[1]) / 2
    seed = int(abs(mid.x * 7919 + mid.y * 104729 + mid.z * 1299709)) % 100000
    import random
    rnd = random.Random(seed)
    n = 8
    V = []
    jit = [0.82 + 0.18 * rnd.random() for _ in range(n)]
    # each pad shifted, sized and turned at random inside its patch, so the hide never shows rows
    mid = mid + eu * rnd.uniform(-0.18, 0.18) + ev * rnd.uniform(-0.18, 0.18)
    ang_ = rnd.uniform(0, math.pi); sc_ = rnd.uniform(0.6, 1.1)
    eu, ev = (eu * math.cos(ang_) + ev * math.sin(ang_)) * sc_, (ev * math.cos(ang_) - eu * math.sin(ang_)) * sc_
    for lay, (sc, hh) in enumerate(((0.5, -0.03), (0.44, t * 0.7), (0.26, t * (1.1 + lift)))):
        for k in range(n):
            a = 2 * math.pi * k / n
            q = mid + eu * (math.cos(a) * sc * jit[k]) + ev * (math.sin(a) * sc * jit[k]) + nrm * hh
            V.append(tuple(q))
    V.append(tuple(mid + nrm * t * (1.2 + lift)))
    F = []
    for j in range(2):
        for k in range(n):
            a, b = j * n + k, j * n + (k + 1) % n
            F.append((a, b, b + n, a + n))
    F += [(2 * n + k, 2 * n + (k + 1) % n, 3 * n) for k in range(n)]
    F.append(tuple(range(n))[::-1])
    RV, RF = [], []
    if rivets:
        npores = int(rnd.random() * 2.4)
        for i in range(npores):
            a = rnd.uniform(0, 6.28); s = rnd.uniform(0.0, 0.22)
            c = mid + eu * math.cos(a) * s + ev * math.sin(a) * s + nrm * t * 0.95
            vv, ff = pore(c, nrm, max(0.018, rr * rnd.uniform(0.7, 1.3)), n=5)
            o = len(RV); RV += vv; RF += [tuple(x + o for x in f) for f in ff]
    return (V, F), (RV, RF)


# ------------------------------------------------------------------------------------------------ the throat (bioplasma)
def spinal(length, r=0.55, style='folded', lip_r=None, rolls=3, teeth=9, seed=0, seg=20, side=1, gland_at=0.72, **kw):
    """the bile spitter (data.js bioplasma, slot F): a throat along +X. Origin at its root on the head (the root and the bore
    run back from there into the hull: mount); the mouth's front at x = length. r: the opening's radius.
    folded (C10): heavy rolled fold lips stacked round the mouth and fold wrinkles running back over the root;
    flared (C11): one wide flared rim rolled outward, the throat wall wrinkled behind it.
    Inside: a sphincter ring, a ring of chitin spines leaning in and forward (the spines it spits), a dark bore, and at the
    back of the bore the bile gland glowing yellow-green."""
    p = Part('spinal')
    p.type = 'throat'
    L = length
    lr = lip_r or r * 1.55
    nf = _noise(seed)
    # root: a muscular collar from the hull face to the mouth, swelling behind the lip
    # the root: a muscle collar ringed with wrinkle ridges (mostly inside the head)
    prof = [(-0.3, lr * 0.82)]
    for j in range(9):
        x_ = -0.3 + (L * 0.8 + 0.3) * (j + 0.5) / 9
        prof += [(x_ - 0.05, lr * 0.86), (x_, lr * 0.92), (x_ + 0.05, lr * 0.86)]
    prof += [(L * 0.8, lr * 0.8), (L * 0.95, r * 1.12), (L * 0.95, r * 0.98), (L * 0.6, r * 0.92), (-0.3, r * 0.9)]
    V, F = revolve(prof, 32, closed=True)
    V = [(x, y * (1 + 0.05 * nf(Vector((x, y, z)).normalized())), z * (1 + 0.05 * nf(Vector((x, z, y)).normalized()))) for (x, y, z) in V]
    p.add('root', 'mount', 'flesh', (V, F))
    if style == 'folded':
        # the rolled fold lips: full rolls stacked round the mouth, each larger and further back, lumpy and twisting, so the
        # mouth sits deep in coiled flesh (the picture's folded mouth); the outer ones grow into the head (mount)
        for i in range(rolls):
            R = r * (1.18 + 0.44 * i); rs = r * (0.36 + 0.08 * i); x0 = L * (1.0 - 0.16 * i)   # each roll further back: a domed lobe
            m = 84
            pts = []; rad = []
            for k in range(m):
                a = 2 * math.pi * k / m + 0.3 * i
                # folded flesh, not a tube: the roll's reach, set-back and thickness all wander round the mouth
                rr = rs * (0.7 + 0.35 * (1 + math.sin(3 * a + 2 * i)) + 0.35 * nf(Vector((math.cos(a * 2 + i), math.sin(a * 3), 0.3 * i))))
                Ra = R * (1 + 0.12 * math.sin(2 * a + 1.3 * i) + 0.07 * math.sin(5 * a + i))
                pts.append(Vector((x0 + r * (0.25 * math.sin(3 * a + 0.7 * i) + 0.1 * math.sin(7 * a) - 0.3) - (0.12 * r if math.sin(a) < -0.3 else 0.0) * i,
                                   Ra * math.cos(a), Ra * math.sin(a) * (1.08 if math.sin(a) > 0 else 0.95))))
                rad.append(rr)
            pts.append(pts[0]); rad.append(rad[0])
            p.add('fold%d' % i, 'body' if i == 0 else 'mount', 'flesh' if i % 2 == 0 else 'flesh2', tube(pts, rad, n=10, cap0=False, cap1=False))
            # sense pores along the roll's outer face
            PV, PF = [], []
            for k in range(1, m, 2):
                q = pts[k]; out = (q - Vector((q.x, 0, 0))).normalized()
                for off in (0.0, 0.9):
                    nn = (out * math.cos(off) + Vector((1, 0, 0)) * math.sin(off)).normalized()
                    vv, ff = pore(q + nn * rad[k] * 0.98, nn, rs * 0.07, n=5)
                    o = len(PV); PV += vv; PF += [tuple(x + o for x in f) for f in ff]
            p.add('foldp%d' % i, 'body' if i == 0 else 'mount', 'pore', (PV, PF))
            # creases across each roll (the coil's wrinkles)
            for k in range(0, m, 3):
                q = pts[k]; ax = (pts[k + 1] - pts[k]).normalized(); out = (q - Vector((q.x, 0, 0))).normalized()
                c = q + out * rad[k] * 0.55 + Vector((rad[k] * 0.6, 0, 0))
                p.add('foldc%d_%d' % (i, k), 'body' if i == 0 else 'mount', 'flesh2', tube([c - ax * rad[k] * 0.1 - out * rad[k] * 0.4, c, c + ax * rad[k] * 0.1 + out * rad[k] * 0.35],
                                                                                         [rs * 0.12, rs * 0.16, rs * 0.1], n=5))
        p.add('lip0', 'body', 'tissue', tube([Vector((L * 1.0 + 0.02, r * 1.0 * math.cos(2 * math.pi * k / 30), r * 1.0 * math.sin(2 * math.pi * k / 30)))
                                              for k in range(31)], [r * 0.1] * 31, n=6, cap0=False, cap1=False))
    elif style == 'flush':
        # a fleshy rimmed hole flush in the face (C11, round 3): one thick lumpy lip round the opening, a few uneven creases
        # across it, the throat going straight back from it; no collar standing out, no ribs, no disc
        m = 72; pts = []; rad = []
        for k in range(m):
            a = 2 * math.pi * k / m
            Ra = r * (1.12 + 0.06 * math.sin(3 * a + seed) + 0.04 * math.sin(7 * a))
            pts.append(Vector((L * 1.0 - r * 0.12 + r * 0.05 * math.sin(2 * a + seed), Ra * math.cos(a), Ra * math.sin(a) * (0.97 if math.sin(a) > 0 else 1.04))))
            rad.append(r * (0.3 + 0.08 * math.sin(4 * a + seed) + 0.06 * nf(Vector((math.cos(a), math.sin(a), 0.4)))))
        pts.append(pts[0]); rad.append(rad[0])
        p.add('lip0', 'mount', 'flesh', tube(pts, rad, n=10, cap0=False, cap1=False))
        import random
        rp = random.Random(seed + 31)
        # pores and small wrinkles over the lip, at the hide's grain (never radial ribs)
        PV, PF = [], []
        for k in range(170):
            kk = rp.randrange(m); q = pts[kk]; rr_ = rad[kk]
            out = (q - Vector((q.x, 0, 0))).normalized(); ang = rp.uniform(-1.2, 1.6)
            nn = (out * math.cos(ang) + Vector((1, 0, 0)) * math.sin(ang)).normalized()
            vv, ff = pore(q + nn * rr_ * 0.98, nn, r * rp.uniform(0.02, 0.035), n=5)
            o = len(PV); PV += vv; PF += [tuple(x + o for x in f) for f in ff]
        p.add('lipp', 'mount', 'pore', (PV, PF))
        for k in range(16):
            a = rp.uniform(0, 2 * math.pi); ln = rp.uniform(0.35, 0.8)
            c0 = pts[int(a / (2 * math.pi) * m) % m]; out = (c0 - Vector((c0.x, 0, 0))).normalized()
            q = [c0 + out * r * 0.05 + Vector((r * 0.3, 0, 0)), c0 + out * r * 0.28 + Vector((r * 0.12, 0, 0)), c0 + out * r * (0.28 + ln * 0.4) - Vector((r * 0.05, 0, 0))]
            p.add('fold%d' % k, 'mount', 'flesh2', tube(q, [r * 0.05, r * 0.06, r * 0.03], n=5, flat=0.6))
        p.add('lipt', 'mount', 'tissue', tube([Vector((L * 1.0 - r * 0.12, r * 0.86 * math.cos(2 * math.pi * k / 40), r * 0.86 * math.sin(2 * math.pi * k / 40)))
                                                for k in range(41)], [r * 0.07] * 41, n=6, cap0=False, cap1=False))
    else:
        # flared rim: a thick lip rolled outward, with radial creases on its face
        # a rolled lip: the throat wall curls out and back over itself in a fat round roll
        cx_, cr_ = L * 0.95, (lr - r) * 0.5; rc_ = (lr + r) * 0.5
        rim = [(L * 0.6, r * 1.0)] + [(cx_ + cr_ * math.sin(math.pi * k / 10), rc_ - cr_ * math.cos(math.pi * k / 10)) for k in range(11)] + \
              [(cx_ - cr_ * 0.6, lr * 0.98), (L * 0.6, lr * 0.9)]
        V, F = revolve(rim, 64, closed=True)
        # the rim is the head's own flesh rolled outward: it grows out of the head (mount), the hull may wrap round it
        # a lip of flesh, not a ring: lumpy, a little oval, drooping at the bottom
        V = [(x + 0.06 * nf(Vector((x, y, z)).normalized()), y * (1.0 + 0.07 * nf(Vector((y, z, x)).normalized())) * 1.04,
              z * (1.0 + 0.07 * nf(Vector((z, x, y)).normalized())) * (0.96 if z > 0 else 1.06)) for (x, y, z) in V]
        p.add('lip0', 'mount', 'flesh', (V, F))
        # pores over the rim's face and its outer wall
        import random
        rp = random.Random(seed + 17); PV, PF = [], []
        for k in range(140):
            # fine radial wrinkles over the roll, from the throat's edge round to the outer wall (the picture's lip)
            a = 2 * math.pi * k / 140 + rp.uniform(-0.015, 0.015)
            pts = []; nrm_ = []
            for j in range(7):
                ph = math.pi * (0.1 + 0.8 * j / 6)
                x_ = cx_ + cr_ * math.sin(ph); rr_ = rc_ - cr_ * math.cos(ph)
                ndir = Vector((math.sin(ph - math.pi / 2) * -1, -math.cos(ph - math.pi / 2), 0))
                pts.append(Vector((x_, rr_ * math.cos(a), rr_ * math.sin(a))))
                nrm_.append(Vector((math.cos(ph - math.pi / 2) * 0 + (x_ - cx_), (rr_ - rc_) * math.cos(a), (rr_ - rc_) * math.sin(a))).normalized())
            PV_, PF_ = welt(pts, nrm_, r * 0.035, r * 0.02, n=3)
            o = len(PV); PV += PV_; PF += [tuple(x + o for x in f) for f in PF_]
        for k in range(50):
            a = rp.uniform(0, 2 * math.pi); xx = rp.uniform(L * 0.62, L * 0.86)
            c = Vector((xx, lr * 0.97 * math.cos(a), lr * 0.97 * math.sin(a))); nn = Vector((0, math.cos(a), math.sin(a)))
            vv, ff = pore(c, nn, r * rp.uniform(0.025, 0.045), n=5)
            o = len(PV); PV += vv; PF += [tuple(x + o for x in f) for f in ff]
        p.add('lipp', 'mount', 'flesh2', (PV, PF))
        # the throat's lining lit by the gland (the picture's warm glow on the inner wall)
        for k in range(10):
            a = 2 * math.pi * (k + 0.25) / 10
            pts = [Vector((L * 1.03 + 0.01 * j, (r * 1.18 + (lr - r * 1.18) * j / 4) * math.cos(a), (r * 1.18 + (lr - r * 1.18) * j / 4) * math.sin(a)))
                   for j in range(5)]
            p.add('fold%d' % k, 'mount', 'flesh2', tube(pts, [r * 0.05] * 5, n=5, flat=0.7))
        for k in range(12):
            a = 2 * math.pi * (k + 0.5) / 12
            pts = [Vector((L * (0.82 - 0.16 * j), lr * (1.0 - 0.02 * j) * math.cos(a + 0.04 * j), lr * (1.0 - 0.02 * j) * math.sin(a + 0.04 * j))) for j in range(5)]
            p.add('foldw%d' % k, 'mount', 'flesh2', tube(pts, [r * 0.1 * (1 - 0.12 * j) for j in range(5)], n=6, flat=0.6))
    # the sphincter: a muscle ring a little way inside the mouth, with radial wrinkles
    xs = L * (0.9 if style == 'folded' else 0.84)
    srole = 'body' if style == 'folded' else 'mount'   # a flared throat's sphincter sits in the head's flesh
    p.add('sphincter', srole, 'tissue', revolve([(xs - 0.08, r * 0.98), (xs - 0.03, r * 0.84), (xs + 0.04, r * 0.82), (xs + 0.08, r * 0.98)], seg, closed=True))
    for k in range(12):
        a = 2 * math.pi * k / 12
        p.add('sphincterw%d' % k, srole, 'tissue', tube([Vector((xs, r * 0.83 * math.cos(a), r * 0.83 * math.sin(a))),
                                                          Vector((xs - 0.05, r * 0.95 * math.cos(a), r * 0.95 * math.sin(a)))], [r * 0.045, r * 0.03], n=5))
    # the spines: a ring of chitin teeth leaning in and forward from the throat wall
    tz = 0.0 if style == 'folded' else -0.2   # a flared throat keeps its spines deeper, out of the lip
    for k in range(teeth):
        a = 2 * math.pi * (k + 0.5) / teeth
        c, s = math.cos(a), math.sin(a)
        b0 = Vector((L * (0.8 + tz), r * 0.92 * c, r * 0.92 * s)); b1 = Vector((L * (0.86 + tz), r * 0.72 * c, r * 0.72 * s)); b2 = Vector((L * (0.93 + tz), r * 0.55 * c, r * 0.55 * s))
        p.add('tooth%d' % k, 'body' if style == 'folded' else 'mount', 'chitin', tube([b0, b1, b2], [r * 0.07, r * 0.04, r * 0.005], n=5))
    # the bore and the gland: the gland sits deep in the throat; its light falls on the bore's wet wall, brightest at the
    # back and fading to dark tissue at the lip (the glow is down inside, never a disc at the mouth; R228 item 5 in spirit)
    ga = gland_at; gr = 0.62
    xg = L * ga
    p.add('bore', 'mount', 'maw', revolve([(xg + r * 0.05, r * 0.7), (xg - r * 0.3, r * 0.6), (0.0, r * 0.5)], seg, cap1=True))
    xl = L * 0.9; bands = (('gland', 0.0, 0.3), ('bilewet', 0.3, 0.62), ('tissue', 0.62, 1.0))
    for mat_, f0, f1 in bands:
        a0 = xg + (xl - xg) * f0; a1 = xg + (xl - xg) * f1
        rad0 = r * (0.7 + 0.25 * f0); rad1 = r * (0.7 + 0.25 * f1)
        p.add('bore%s' % mat_, 'mount', mat_, revolve([(a0, rad0), ((a0 + a1) / 2, (rad0 + rad1) / 2 * 0.985), (a1, rad1)], seg))
    # wet wall wrinkles along the bore, catching the light
    for k in range(16):
        a = 2 * math.pi * (k + 0.5) / 16
        pts = [Vector((xg + (xl - xg) * j / 7, r * (0.69 + 0.25 * j / 7) * math.cos(a + 0.03 * j), r * (0.69 + 0.25 * j / 7) * math.sin(a + 0.03 * j))) for j in range(8)]
        p.add('borew%d' % k, 'mount', 'bilewet' if k % 3 == 0 else 'tissue', tube(pts, [r * 0.045] * 8, n=5, flat=0.6))
    p.add('gland', 'mount', 'bile', blob(r * 0.22, r * gr, r * gr, centre=(xg, 0, 0), nu=20, nv=12, seed=seed + 3, amp=0.1))
    if side < 0:
        # the starboard throat is the port one mirrored: its outer fold rolls lie over the top and the outer (starboard) side
        for c in p.comps:
            c['verts'] = [Vector((v.x, -v.y, v.z)) for v in c['verts']]
    p.fit = dict(muzzles=[P((L * 1.02, 0, 0))], pivot=P((L * 1.02, 0, 0)), trunnion=P((L * 1.02, 0, 0)), reach=0.3, aim=D((1, 0, 0)),
                 up=D((0, 0, 1)), mount='spinal', radius=r * 1.15)   # the shot leaves the bore: its lane is the bore's width
    return p


# ------------------------------------------------------------------------------------------------ tendrils and spore glands
def _tendril(p, name, root, d0, length, r0, seed, curl=1.0, role='turn', rings=True, n=7, k=18, sweep=None):
    """one hooked tendril from root along d0 (a unit direction), curling at its end; adds stalk, rings, barb and acid pores.
    sweep: an extra direction the tendril bends toward along its length (a mane streaming aft). Returns the tip."""
    import random
    rnd = random.Random(seed)
    d = Vector(d0).normalized()
    side = d.cross(Vector((0, 0, 1)))
    side = side.normalized() if side.length > 1e-6 else Vector((0, 1, 0))
    bend = d.cross(side).normalized()   # toward which the tip curls
    if rnd.random() < 0.5:
        bend = -bend
    pts = []; rad = []
    pos = Vector(root); h = length / k
    ax = side   # a positive turn about `side` curls the tendril up and over, never down into the hull
    for i in range(k + 1):
        t = i / k
        pts.append(pos.copy()); rad.append(r0 * (1 - 0.85 * t ** 1.3) + 0.004)
        ang = curl * 2.4 * t ** 2.2 + 0.1 * math.sin(t * 7 + seed)
        dd = Matrix.Rotation(ang, 3, ax) @ Vector(d0).normalized()
        if sweep:
            # a mane streams: it bends aft along its length and waves side to side
            dd = (dd + Vector(sweep) * t * 1.2 + side * 0.35 * t * math.sin(t * 9 + seed)).normalized()
        pos = pos + dd * h
    p.add('stalk%s' % name, role, 'flesh' if seed % 3 else 'flesh2', tube(pts, rad, n=n, cap0=False))
    if rings:
        _add_tube_rings(p, 'ring%s' % name, pts, rad, 2, r0 * 0.3, k=1.18, mat='flesh2', role=role, n=n)
    # the barb: a hooked chitin claw at the tip
    pts2, T, N, B = _frames(pts)
    tip = pts2[-1]; tt = T[-1]; bn = N[-1]
    hook = [tip - tt * r0 * 0.5, tip + tt * r0 * 1.2, tip + tt * r0 * 2.2 + bn * r0 * 1.0, tip + tt * r0 * 2.4 + bn * r0 * 2.0]
    p.add('barb%s' % name, role, 'chitin', tube(hook, [r0 * 0.32, r0 * 0.28, r0 * 0.16, 0.003], n=5))
    # acid pores just behind the barb
    for j, ii in enumerate((k - 2, k - 4)):
        q = pts2[ii]; nn = N[ii] if j == 0 else B[ii]
        p.add('pore%s%d' % (name, j), role, 'bilewet', pore(q + nn * rad[ii] * 0.85, nn, rad[ii] * 0.42, n=6))
    return tip


def gun(barrels=2, cal=0.12, blen=2.0, size=1.0, mount='turret', pitch=0.0, variant=0, seg=6, weapon='tendril', count=14,
        spread=1.0, seed=0, mane_len=0.0, mane_drop=0.0):
    """a Chorus weapon organ, built from what it is (WEAPONS). Origin on the hull at the mount centre, +Z the mount normal,
    +X the rest aim. tendril: a crown of `count` hooked tendrils `blen` long from a sphincter on a muscle mound (turns);
    with mane_len > 0 a mane: the tendrils rooted along a crest mane_len long (fixed, mount 'spinal' in the fit check).
    spores: a spore gland hanging from its neck (the belly), its spout curling forward to a rosette of pores (turns)."""
    p = Part('gun')
    s = size
    if weapon == 'tendril' and mane_len <= 0:
        p.type = 'tendril'
        R = 0.42 * s
        p.add('root', 'mount', 'flesh', blob(R * 1.9, R * 1.9, R * 0.7, centre=(0, 0, -0.05), nu=28, nv=12, seed=seed, amp=0.08))
        for k in range(12):
            a = 2 * math.pi * k / 12
            pts = [Vector((R * 0.7 * math.cos(a), R * 0.7 * math.sin(a), R * 0.55)), Vector((R * 1.3 * math.cos(a), R * 1.3 * math.sin(a), R * 0.42)),
                   Vector((R * 1.8 * math.cos(a), R * 1.8 * math.sin(a), R * 0.12))]
            p.add('rootw%d' % k, 'mount', 'flesh2', tube(pts, [R * 0.09, R * 0.1, R * 0.06], n=5, flat=0.6))
        zt = R * 0.62
        p.add('sphincter', 'turn', 'tissue', revolve([(zt - 0.02, R * 0.95), (zt + 0.1 * s, R * 0.92), (zt + 0.16 * s, R * 0.7), (zt + 0.1 * s, R * 0.5), (zt, R * 0.5)],
                                                     24, closed=True, axis='Z'))
        tips = []
        import random
        rnd = random.Random(seed + 11)
        for i in range(count):
            a = 2 * math.pi * (i + 0.5 * (i % 2)) / count
            ring = 0.62 if i % 2 else 0.32
            root = Vector((R * ring * math.cos(a), R * ring * math.sin(a), zt + 0.05 * s))
            el = math.radians(rnd.uniform(58, 78) if i % 2 == 0 else rnd.uniform(46, 64))
            d0 = Vector((math.cos(a) * math.cos(el) * spread, math.sin(a) * math.cos(el) * spread, math.sin(el)))
            Ln = blen * rnd.uniform(0.7, 1.05)
            # the tips curl outward and over (the picture's crown), the roots rise steeply so no curl comes back to the hide
            tips.append(_tendril(p, 't%02d' % i, root, d0, Ln, cal * rnd.uniform(0.85, 1.15), seed * 100 + i, curl=-rnd.uniform(0.45, 0.75)))
        pivot = Vector((0, 0, zt + 0.1 * s))
        reach = max((t - pivot).length for t in tips)
        p.fit = dict(pivot=P(pivot), trunnion=P(pivot), muzzles=[P(t) for t in tips[::max(1, len(tips) // barrels)][:max(1, barrels)]],
                     reach=reach, aim=D((1, 0, 0)), up=D((0, 0, 1)), mount=mount, radius=R * 1.9)
        return p
    if weapon == 'tendril':
        # the mane (C11): a crest of muscle along the back, the tendrils rooted in rows along it, streaming up and aft
        p.type = 'mane'
        Lm = mane_len; W = 0.32 * s
        sec = []
        for i in range(17):
            t = i / 16; x = -Lm * t
            k_ = math.sin(math.pi * (0.06 + 0.88 * t)) ** 0.6
            sec.append((x, [(W * k_ * math.cos(a) * (1 + 0.08 * math.sin(i * 1.7 + j)), (W * 0.85 * k_) * max(0.0, math.sin(a)) ** 0.8 - 0.25 * s - mane_drop * t)
                            for j, a in enumerate([math.pi * j / 15 for j in range(16)])]))
        V, F = prism([(x, [(y, z) for (y, z) in ring]) for x, ring in sec])
        p.add('root', 'mount', 'flesh', (V, F))
        p.add('crest', 'mount', 'tissue', welt([Vector((-Lm * t, 0, W * 0.85 * math.sin(math.pi * (0.06 + 0.88 * t)) ** 0.6 - 0.25 * s - mane_drop * t)) for t in [j / 16 for j in range(17)]],
                                                [Vector((0, 0, 1))] * 17, W * 0.55, 0.06 * s))
        import random
        rnd = random.Random(seed + 7)
        tips = []
        for i in range(count):
            t = (i + 0.5) / count
            x = -Lm * (0.05 + 0.9 * t)
            sg = 1 if i % 2 else -1
            y = sg * W * rnd.uniform(0.1, 0.55)
            z = max(W * 0.85 * math.sin(math.pi * (0.06 + 0.88 * (0.05 + 0.9 * t))) ** 0.6 - 0.25 * s, 0.06) + 0.02 - mane_drop * (0.05 + 0.9 * t) - abs(y) * 0.3
            el = math.radians(rnd.uniform(30, 52))
            az = math.radians(180 + sg * rnd.uniform(12, 62))
            d0 = Vector((math.cos(az) * math.cos(el) * 0.75, math.sin(az) * math.cos(el) * 1.2, math.sin(el)))
            tips.append(_tendril(p, 'm%02d' % i, Vector((x, y, z)), d0, blen * rnd.uniform(0.75, 1.1), cal * rnd.uniform(0.8, 1.15), seed * 100 + i,
                                 curl=rnd.uniform(-0.25, 0.35), role='body', n=6, k=18, sweep=(-0.6, sg * 0.2, -0.15)))
        pivot = Vector((-Lm * 0.5, 0, W * 0.85 - 0.25 * s - mane_drop * 0.5 + 0.8 * s))
        for c in p.comps:
            if c['role'] == 'turn':
                c['role'] = 'body'
        p.fit = dict(pivot=P(pivot), trunnion=P(pivot), muzzles=[P(t) for t in sorted(tips, key=lambda v: -v.z)[:max(1, barrels)]],
                     reach=max((t - pivot).length for t in tips), aim=D((1, 0, 0)), up=D((0, 0, 1)), mount='spinal', radius=W * 1.5)
        return p
    # ---- spores: the spore gland
    p.type = 'spore'
    R = 0.45 * s
    p.add('root', 'mount', 'flesh', blob(R * 0.85, R * 0.85, R * 0.55, centre=(0, 0, 0.0), nu=20, nv=10, seed=seed, amp=0.1))
    neck = [Vector((0, 0, 0.2 * s)), Vector((0.02 * s, 0, R * 0.6)), Vector((0.05 * s, 0, R * 1.0))]
    p.add('rootn', 'turn', 'flesh2', tube(neck, [R * 0.55, R * 0.45, R * 0.5], n=12))
    cz = R * 1.0 + R * 0.95
    p.add('sac', 'turn', 'flesh', blob(R * 1.05, R * 1.0, R * 1.1, centre=(0.05 * s, 0, cz), nu=24, nv=14, seed=seed + 1, amp=0.07))
    import random
    rnd = random.Random(seed + 5)
    for k in range(5):
        a = 2 * math.pi * (k + rnd.random() * 0.3) / 5
        pts = []
        for j in range(7):
            th = -0.9 + 1.9 * j / 6
            rr = R * 1.06
            pts.append(Vector((0.05 * s + rr * math.cos(th) * math.cos(a + 0.12 * math.sin(j)), rr * math.cos(th) * math.sin(a + 0.12 * math.sin(j)),
                               cz + R * 1.12 * math.sin(th))))
        p.add('vein%d' % k, 'turn', 'bilewet', tube(pts, [R * 0.045] * 7, n=5, flat=0.7))
    # the spout: from the sac's far side curling forward, a rosette of pores at its mouth
    sp = [Vector((0.05 * s + R * 0.35, 0, cz + R * 0.85)), Vector((0.05 * s + R * 0.85, 0, cz + R * 1.15)), Vector((0.05 * s + R * 1.3, 0, cz + R * 1.2)),
          Vector((0.05 * s + R * 1.65, 0, cz + R * 1.05))]
    p.add('spout', 'turn', 'flesh2', tube(sp, [R * 0.34, R * 0.3, R * 0.27, R * 0.3], n=12, cap1=False))
    mz = sp[-1]
    p.add('spoutlip', 'turn', 'tissue', moved(revolve([(-0.02, R * 0.22), (0.03, R * 0.34), (0.06, R * 0.3), (0.02, R * 0.18)], 14, closed=True),
                                              frame(mz, (sp[-1] - sp[-2]).normalized(), (0, 0, 1))))
    dirv = (sp[-1] - sp[-2]).normalized()
    u = dirv.orthogonal().normalized(); w = dirv.cross(u)
    muzzles = []
    for k in range(6):
        a = 2 * math.pi * k / 6
        c = mz + dirv * 0.03 + (u * math.cos(a) + w * math.sin(a)) * R * 0.17
        p.add('pore%d' % k, 'turn', 'bilewet', pore(c, dirv, R * 0.06, n=6))
        muzzles.append(c)
    p.add('pore6', 'turn', 'bile', pore(mz + dirv * 0.04, dirv, R * 0.08, n=6))
    pivot = Vector((0, 0, cz))
    p.fit = dict(pivot=P(pivot), trunnion=P(pivot), muzzles=[P(m) for m in muzzles[:max(1, barrels)]], reach=(mz - pivot).length + 0.1,
                 aim=D((1, 0, 0)), up=D((0, 0, 1)), mount=mount, radius=R * 1.15)
    return p


# ------------------------------------------------------------------------------------------------ the pulse vent (engine)
def engine_bell(r_exit, body_len, bell_len=None, body_r=None, throat=0.6, rings=3, nose='flat', seg=24, trail='membrane',
                trails=3, trail_len=None, out_dir=None, seed=0):
    """the pulse vent (no nozzle): exhaust leaves along -X; origin at the centre of the vent's mouth.
    root: a muscular cone running forward body_len into the hull (mount); fold: radial folds round the mouth; sphincter: the
    muscle ring that squeezes each pulse; throat: the dark funnel; glow: bile light deep in it. trail: 'membrane' veils (C10)
    or 'filament' strands with glowing nodes (C11), rooted on the rim and splayed away from the ship's axis (out_dir, a
    direction in the local Y-Z plane) so they never hang in a neighbour's jet."""
    p = Part('engine')
    br = body_r or r_exit * 1.35
    nf = _noise(seed)
    prof = [(-0.04, r_exit * 1.02), (r_exit * 0.25, r_exit * 1.28), (r_exit * 0.9, br), (body_len * 0.6, br * 1.05), (body_len, br * 0.9),
            (body_len + br * 0.25, 0.001)]
    V, F = revolve(prof, seg, cap0=False)
    V = [(x, y * (1 + 0.06 * nf(Vector((x, y, z)).normalized())), z * (1 + 0.06 * nf(Vector((z, x, y)).normalized()))) for (x, y, z) in V]
    p.add('root', 'mount', 'flesh', (V, F))
    for k in range(rings * 4):
        a = 2 * math.pi * k / (rings * 4)
        pts = [Vector((-0.02, r_exit * 1.05 * math.cos(a), r_exit * 1.05 * math.sin(a))), Vector((r_exit * 0.35, r_exit * 1.32 * math.cos(a + 0.05), r_exit * 1.32 * math.sin(a + 0.05))),
               Vector((r_exit * 0.95, br * 1.02 * math.cos(a + 0.1), br * 1.02 * math.sin(a + 0.1)))]
        p.add('fold%d' % k, 'mount', 'flesh2', tube(pts, [r_exit * 0.09, r_exit * 0.11, r_exit * 0.05], n=5, flat=0.6))
    p.add('sphincter', 'body', 'tissue', revolve([(0.04, r_exit * 1.04), (-0.05, r_exit * 0.98), (-0.06, r_exit * 0.8), (0.03, r_exit * 0.72), (0.08, r_exit * 0.9)],
                                                 seg, closed=True))
    p.add('throat', 'body', 'maw', revolve([(0.04, r_exit * 0.74), (r_exit * 0.5, r_exit * 0.55), (r_exit * 1.0, r_exit * 0.3)], seg, cap1=True))
    p.add('glow', 'body', 'bile', blob(r_exit * 0.28, r_exit * 0.42, r_exit * 0.42, centre=(r_exit * 0.8, 0, 0), nu=12, nv=8, seed=seed + 1, amp=0.1))
    tl = trail_len or r_exit * 6
    od = Vector(out_dir or (0, 0, 1)); od.x = 0.0
    od = od.normalized() if od.length > 1e-6 else Vector((0, 0, 1))
    import random
    rnd = random.Random(seed + 9)
    for i in range(trails):
        a0 = math.atan2(od.z, od.y) + (i - (trails - 1) / 2) * 0.75
        rv = Vector((0, math.cos(a0), math.sin(a0)))
        sp = math.radians(22 + 6 * rnd.random())
        if trail == 'membrane':
            # a veil: a thin, wavy, tapering strip from the rim, splaying out at 22 to 28 degrees from the axis
            m = 20; V, F = [], []
            wv = rv.cross(Vector((1, 0, 0))).normalized()
            for j in range(m + 1):
                t = j / m
                c = rv * r_exit * 0.95 + Vector((-tl * t, 0, 0)) + rv * tl * t * math.tan(sp) + wv * 0.1 * tl * math.sin(t * 5 + i) * t + rv * 0.06 * tl * math.sin(t * 7 + 2 * i) * t
                w = r_exit * 2.2 * (0.55 + 0.45 * math.sin(math.pi * (0.15 + 0.85 * t))) * (1 - 0.6 * t) * (1 + 0.15 * math.sin(t * 9 + i))
                th = 0.012 + 0.02 * (1 - t)
                for q in (c - wv * w / 2, c + wv * w / 2, c + wv * w / 2 + rv * th, c - wv * w / 2 + rv * th):
                    V.append(tuple(q))
            for j in range(m):
                for k in range(4):
                    a, b = j * 4 + k, j * 4 + (k + 1) % 4
                    F.append((a, b, b + 4, a + 4))
            F.append((3, 2, 1, 0)); o = m * 4; F.append((o, o + 1, o + 2, o + 3))
            p.add('membrane%d' % i, 'body', 'membrane', (V, F))
            # a vein of light along the veil's middle
            for q_, f_ in enumerate((0.2, 0.5, 0.8)):
                pts = [Vector(V[j * 4]).lerp(Vector(V[j * 4 + 1]), f_) + rv * 0.02 for j in range(m + 1)]
                p.add('membranev%d_%d' % (i, q_), 'body', 'bilewet' if q_ == 1 else 'membrane', tube(pts, [r_exit * (0.05 if q_ == 1 else 0.03) * (1 - 0.6 * j / m) for j in range(m + 1)], n=4))
        else:
            for f in range(3):
                b0 = rv * r_exit * 0.95 + rv.cross(Vector((1, 0, 0))).normalized() * (f - 1) * r_exit * 0.28
                pts = []
                for j in range(13):
                    t = j / 12
                    pts.append(b0 + Vector((-tl * t * (0.85 + 0.1 * f), 0, 0)) + rv * tl * t * math.tan(sp + 0.05 * f) + Vector((0, 0, 0.05 * tl * math.sin(t * 6 + f + i) * t)))
                p.add('filament%d_%d' % (i, f), 'body', 'membrane', tube(pts, [r_exit * 0.07 * (1 - 0.8 * j / 12) + 0.004 for j in range(13)], n=5, cap0=False))
                for j in (3, 7):
                    p.add('filamentn%d_%d_%d' % (i, f, j), 'body', 'bile', blob(r_exit * 0.12, r_exit * 0.12, r_exit * 0.12, centre=tuple(pts[j]), nu=8, nv=5, seed=j))
    p.fit = dict(exit=P((0, 0, 0)), axis=D((-1, 0, 0)), radius=r_exit * 1.05, front=P((body_len, 0, 0)), body_r=br)
    return p


def thruster(r=0.3, nozzles=3):
    """a siphon (local +Z out): a muscle collar, a puckered lip and a dark bore; it squirts to turn the body"""
    p = Part('thruster')
    p.add('collar', 'mount', 'flesh', blob(r * 1.2, r * 1.0, r * 0.45, centre=(0, 0, 0.0), nu=18, nv=8, seed=int(r * 100), amp=0.08))
    p.add('lip', 'body', 'tissue', revolve([(r * 0.38, r * 0.55), (r * 0.55, r * 0.5), (r * 0.6, r * 0.32), (r * 0.5, r * 0.22), (r * 0.36, r * 0.3)], 14, closed=True, axis='Z'))
    for k in range(8):
        a = 2 * math.pi * k / 8
        p.add('lipw%d' % k, 'body', 'flesh2', tube([Vector((r * 0.3 * math.cos(a), r * 0.3 * math.sin(a), r * 0.6)), Vector((r * 0.62 * math.cos(a), r * 0.62 * math.sin(a), r * 0.45))],
                                                   [r * 0.05, r * 0.04], n=5))
    p.add('bore', 'mount', 'maw', revolve([(r * 0.56, r * 0.25), (r * 0.2, r * 0.15), (0.0, 0.001)], 14, axis='Z'))
    p.fit = dict(out=D((0, 0, 1)))
    return p


# ------------------------------------------------------------------------------------------------ sacs, blades, scutes
def sac(r, h=None, seed=0, glow=3, creases=2, veins=5, kind='sac', slit=0.0, rim=1.0, pores=None, hang=1.0):
    """a sac grown out of the hull (local +Z out of the hull): root, a socket of wrinkled tissue (mount); sac, the bulge (mount:
    it grows into the hull); crease, creases across it; vein, veins over it; glow, windows where the bile shows through.
    kind 'brood' adds the birth slit (slit: its length as a share of the sac) between two lip rolls (lip): a launch opening for
    the spore swarms. Fit: the slit's aperture along +Z."""
    p = Part(kind)
    h = h or r * 1.1
    cz = h - r * 1.0
    # hang > 1: a pendulous lobe, swelling away from the body and narrowing to a soft neck where it grows out
    p.add('sac', 'mount', 'flesh', blob(r, r * 0.96, r * 1.0, centre=(0, 0, cz), nu=40, nv=24, seed=seed, amp=0.06,
                                         squash=(lambda uz: 1.0 if uz >= 0 else max(0.5, 1.0 - (hang - 1.0) * 1.1 * uz * uz)) if hang > 1 else None))
    # the root: a broad swelling where the sac grows out of the body, so it reads as a bulge of the flank, not a ball stuck on
    p.add('rootf', 'mount', 'flesh', blob(r * (0.85 if hang > 1 else 1.1), r * (0.8 if hang > 1 else 1.05), r * (0.55 if hang > 1 else 0.3), centre=(0, 0, 0.0), nu=28, nv=10, seed=seed + 7, amp=0.08))
    # the socket: wrinkle rolls round the base, where the sac meets the hull (z about 0)
    for k in range(3):
        zz = 0.02 + r * 0.07 * (2 - k)
        R = (max(0.05, r * r - (cz - zz) ** 2) ** 0.5 + r * 0.06 * (k + 1)) * rim
        if hang > 1:
            uz_ = max(-1.0, min(0.0, (zz - cz) / r)); R *= max(0.5, 1.0 - (hang - 1.0) * 1.1 * uz_ * uz_)
        m = 36
        pts = [Vector((R * math.cos(2 * math.pi * j / m), R * math.sin(2 * math.pi * j / m), zz + 0.03 * math.sin(j * 1.7 + k))) for j in range(m + 1)]
        p.add('root%d' % k, 'mount', 'flesh2' if k % 2 else 'flesh', tube(pts, [r * (0.09 - 0.015 * k)] * (m + 1), n=6, cap0=False, cap1=False))
    import random
    rnd = random.Random(seed + 3)
    thb = math.asin(max(-1.0, min(1.0, -cz / r))) + 0.14   # the lowest latitude on the sac that is clear of the hull
    if hang > 1:
        thb += 0.55   # a hanging sac leans into the body near its neck: keep the surface detail to its free lobe
    # creases: shallow grooves read as a pair of welts with a dark line between (the concept's "smile" creases)
    for i in range(creases):
        th0 = max(thb + 0.1, rnd.uniform(-0.5, 0.1) + i * 0.35); a0 = rnd.uniform(-0.6, 0.6) + (math.pi if i % 2 else 0)
        pts = []; nrm = []
        for j in range(9):
            a = a0 + (j - 4) * 0.16
            th = th0 + 0.12 * math.sin(j * 0.7)
            u = Vector((math.cos(th) * math.cos(a), math.cos(th) * math.sin(a), math.sin(th)))
            pts.append(Vector((r * u.x, r * 0.96 * u.y, cz + r * u.z)) + u * 0.01); nrm.append(u)
        p.add('crease%d' % i, 'body', 'flesh2', welt(pts, nrm, r * 0.06, r * 0.035, n=4))
        p.add('creasel%d' % i, 'body', 'maw', welt([q - nn * r * 0.005 for q, nn in zip(pts, nrm)], nrm, r * 0.02, r * 0.02, n=3))
    for i in range(veins):
        a0 = 2 * math.pi * i / veins + rnd.uniform(-0.3, 0.3)
        pts = []; nrm = []
        for j in range(8):
            th = max(thb, -0.35) + (1.1 - max(0.0, thb + 0.35)) * j / 7
            a = a0 + 0.25 * math.sin(j * 0.9 + i)
            u = Vector((math.cos(th) * math.cos(a), math.cos(th) * math.sin(a), math.sin(th)))
            pts.append(Vector((r * u.x, r * 0.96 * u.y, cz + r * u.z))); nrm.append(u)
        p.add('vein%d' % i, 'body', 'flesh2' if i % 2 else 'bilewet', welt(pts, nrm, r * 0.045, r * 0.03, n=4))
    for i in range(glow):
        a = 2 * math.pi * (i + 0.3) / max(1, glow); th = max(thb + 0.05, rnd.uniform(-0.2, 0.6))
        u = Vector((math.cos(th) * math.cos(a), math.cos(th) * math.sin(a), math.sin(th)))
        c = Vector((r * u.x, r * 0.96 * u.y, cz + r * u.z))
        p.add('glow%d' % i, 'body', 'bile', moved(blob(r * 0.13, r * 0.09, r * 0.035, nu=10, nv=5, seed=i), frame(c, u.orthogonal(), u)))
    # pores over the sac's skin (it breathes the swarm's air), at the hull's grain
    npo = pores if pores is not None else int(18 * r * r * 4)
    V, F = [], []
    for i in range(npo):
        a = rnd.uniform(0, 2 * math.pi); th = rnd.uniform(thb + 0.05, 1.35)
        u = Vector((math.cos(th) * math.cos(a), math.cos(th) * math.sin(a), math.sin(th)))
        c = Vector((r * u.x, r * 0.96 * u.y, cz + r * u.z))
        vv, ff = pore(c, u, r * rnd.uniform(0.025, 0.045), n=6)
        o = len(V); V += vv; F += [tuple(q + o for q in f) for f in ff]
    p.add('pore', 'body', 'pore', (V, F))
    if kind == 'brood':
        # the birth slit along the sac's crown, between two lip rolls
        sl = r * slit
        for sg in (1, -1):
            pts = []; nrm = []
            for j in range(9):
                t = (j - 4) / 4
                u = Vector((t * sl / r, sg * 0.1 * (1 - t * t) + sg * 0.05, 1.0)).normalized()
                pts.append(Vector((r * u.x, r * 0.96 * u.y, cz + r * u.z))); nrm.append(u)
            p.add('lip%d' % (sg > 0), 'body', 'tissue', welt(pts, nrm, r * 0.13, r * 0.08, n=5))
        pts = [Vector(((j - 4) / 4 * sl, 0, cz + r * 1.0 + 0.02)) for j in range(9)]
        p.add('slit', 'body', 'maw', welt(pts, [Vector((0, 0, 1))] * 9, r * 0.09, r * 0.03, n=4))
        p.add('slitg', 'body', 'bile', welt([q + Vector((0, 0, 0.01)) for q in pts[2:7]], [Vector((0, 0, 1))] * 5, r * 0.03, r * 0.03, n=3))
        p.fit = dict(exit=P((0, 0, cz + r * 1.05)), axis=D((0, 0, 1)), radius=r)
    else:
        p.fit = dict(top=P((0, 0, cz + r)), radius=r)
    return p


def spine_blade(h, w, t=None, rake=25.0, teeth=5, growth=4, seed=0):
    """a bone blade (local +Z out of the hull, +X forward; it rakes aft): collar, the transition tissue it grows out of (mount);
    blade, a thin curved shard; growth, raised growth lines along its faces; edge, a serrated cutting edge on its front."""
    import random
    rnd = random.Random(seed)
    t = t or w * 0.22
    p = Part('spine')
    p.add('collar', 'mount', 'tissue', blob(w * 0.75, t * 2.6, h * 0.16, centre=(0, 0, 0.0), nu=18, nv=8, seed=seed, amp=0.15))
    rk = math.radians(rake)
    k = 8
    secs = []
    for j in range(k + 1):
        s = j / k
        z = h * s
        xc = -math.tan(rk) * z - 0.08 * h * s * s
        ww = w * (1 - 0.82 * s ** 1.2) + 0.01
        tt = t * (1 - 0.8 * s) + 0.004
        secs.append((xc, z, ww, tt))
    V, F = [], []
    for xc, z, ww, tt in secs:
        for (dx, dy) in ((ww / 2, 0), (0.15 * ww, tt / 2), (-ww / 2, tt * 0.3), (-ww / 2, -tt * 0.3), (0.15 * ww, -tt / 2)):
            V.append((xc + dx, dy, z))
    n = 5
    for j in range(k):
        for q in range(n):
            a, b = j * n + q, j * n + (q + 1) % n
            F.append((a, b, b + n, a + n))
    F.append(tuple(range(n))[::-1]); F.append(tuple(range(k * n, (k + 1) * n)))
    p.add('blade', 'body', 'bone', (V, F))
    for g in range(growth):
        s = (g + 1) / (growth + 1) * 0.85
        j = s * k; j0 = int(j); f = j - j0
        a = secs[j0]; b = secs[min(j0 + 1, k)]
        xc = a[0] + (b[0] - a[0]) * f; z = a[1] + (b[1] - a[1]) * f; ww = a[2] + (b[2] - a[2]) * f; tt = a[3] + (b[3] - a[3]) * f
        for sg in (1, -1):
            pts = [Vector((xc + ww * (0.42 - 0.84 * q / 4), sg * tt * (0.48 - 0.1 * abs(q - 2) / 2), z - 0.02 * h * math.sin(q))) for q in range(5)]
            p.add('growth%d%d' % (g, sg > 0), 'body', 'chitin', tube(pts, [h * 0.012] * 5, n=4))
    for q in range(teeth):
        s = (q + 0.6) / (teeth + 0.4) * 0.9
        j = s * k; j0 = int(j); f = j - j0
        a = secs[j0]; b = secs[min(j0 + 1, k)]
        xc = a[0] + (b[0] - a[0]) * f; z = a[1] + (b[1] - a[1]) * f; ww = a[2] + (b[2] - a[2]) * f
        base = Vector((xc + ww / 2 - 0.01, 0, z))
        p.add('edge%d' % q, 'body', 'bone', tube([base - Vector((0, 0, h * 0.03)), base + Vector((ww * 0.18, 0, h * 0.04)), base + Vector((ww * 0.28, 0, h * 0.1))],
                                                 [t * 0.4, t * 0.25, 0.003], n=4))
    p.fit = dict(top=P((secs[-1][0], 0, h)), radius=w)
    return p


def chitin(w, l, t=0.06, growth=3, seed=0):
    """an ochre chitin scute (local +Z out, +X along its length): plate, a domed overlapping plate; rim, its raised edge;
    growth, concentric growth lines"""
    p = Part('chitin')
    n = 16
    def ring(sc, hh):
        return [(l / 2 * sc * math.cos(2 * math.pi * k / n) * (1.1 if math.cos(2 * math.pi * k / n) > 0 else 0.9), w / 2 * sc * math.sin(2 * math.pi * k / n), hh)
                for k in range(n)]
    lay = [ring(1.0, -0.03), ring(0.97, t * 0.6), ring(0.8, t * 1.0), ring(0.5, t * 1.35), ring(0.2, t * 1.5)]
    V = [v for r_ in lay for v in r_] + [(0, 0, t * 1.55)]
    F = []
    for j in range(len(lay) - 1):
        for k in range(n):
            a, b = j * n + k, j * n + (k + 1) % n
            F.append((a, b, b + n, a + n))
    c = len(V) - 1; o = (len(lay) - 1) * n
    F += [(o + k, o + (k + 1) % n, c) for k in range(n)]
    F.append(tuple(range(n))[::-1])
    p.add('plate', 'mount', 'chitin', (V, F))
    rimpts = [Vector(v) + Vector((0, 0, 0.005)) for v in ring(0.92, t * 0.85)]
    p.add('rim', 'body', 'bone', tube(rimpts + [rimpts[0]], [t * 0.28] * (n + 1), n=5, cap0=False, cap1=False))
    for g in range(growth):
        sc = 0.72 - 0.18 * g; hh = t * (1.08 + 0.12 * g)
        pts = [Vector(v) for v in ring(sc, hh)]
        p.add('growth%d' % g, 'body', 'chitin', tube(pts + [pts[0]], [t * 0.12] * (n + 1), n=4, cap0=False, cap1=False))
    p.fit = dict(top=P((0, 0, t * 1.5)), radius=max(w, l) / 2)
    return p


ENGINE_WHAT = 'pulse vent, mouth %.1f across'


def gun_what(part, kind):
    """the feature table's words for a weapon organ"""
    t = getattr(part, 'type', '')
    n = sum(1 for c in part.comps if c['name'].startswith('stalk'))
    return {'tendril': 'crown of %d hooked tendrils (turns)' % n, 'mane': 'mane of %d hooked tendrils (fixed)' % n,
            'spore': 'spore gland, pore rosette (swings on its neck)'}.get(t, kind)


def bone_crest(length, h, w=None, knuckles=3, seed=0, jagged=0.0):
    """a knuckled bone crest (local +Z out of the hull, +X along the crest): collar, the raw tissue it grows from (mount);
    blade, a thick bony ridge whose top rises and falls in knuckles; edge, the knuckle knobs on the ridge; growth, growth
    ridges across its flanks. Uneven by design: no two crests alike (the bladeback's back, issue 623)."""
    import random
    rnd = random.Random(seed)
    w = w or h * 0.55
    p = Part('spine')
    p.add('collar', 'mount', 'tissue', blob(length * 0.58, w * 0.95, h * 0.18, centre=(0, 0, 0.0), nu=24, nv=8, seed=seed, amp=0.18))
    k = 18
    peaks = sorted(rnd.uniform(-0.38, 0.38) for _ in range(knuckles))
    hts = [rnd.uniform(0.6, 1.0) for _ in range(knuckles)]

    jag = [rnd.uniform(-1, 1) for _ in range(k + 1)]

    def top(t):
        # the ridge line: knuckle humps over a base, broken by jagged notches, falling to the ends
        x = (t - 0.5)
        v = 0.5 + sum(0.5 * hk * math.exp(-((x - pk) / 0.13) ** 2) for pk, hk in zip(peaks, hts))
        j = jag[min(k, int(t * k + 0.5))] * jagged
        return h * max(0.12, min(1.05, v + j)) * math.sin(math.pi * t) ** 0.4
    secs = []
    for j in range(k + 1):
        t = j / k
        x = -length / 2 + length * t
        zt = top(t) + 0.02
        ww = w * (0.55 + 0.45 * math.sin(math.pi * t) ** 0.6)
        ring = []
        for q in range(10):
            a = math.pi * q / 9
            # a thick base narrowing to a rounded bony ridge
            yy = ww / 2 * math.cos(a) * (1 - 0.65 * math.sin(a) ** 2)
            zz = zt * math.sin(a) ** 0.8 - 0.06
            ring.append((yy, zz))
        secs.append((x, ring))
    V, F = prism(secs)
    V = [(x, y * (1 + 0.12 * math.sin(7 * x + seed)), z) for (x, y, z) in V]
    p.add('blade', 'body', 'bone', (V, F))
    for i, (pk, hk) in enumerate(zip(peaks, hts)):
        t = pk + 0.5; x = -length / 2 + length * t
        p.add('edge%d' % i, 'body', 'bone', blob(w * 0.22, w * 0.2, h * 0.12, centre=(x, 0, top(t) - h * 0.02), nu=12, nv=8, seed=seed + i, amp=0.2))
    for g in range(int(length / 0.12)):
        t = (g + 0.5) * 0.12 / length
        x = -length / 2 + length * t; zt = top(t)
        if zt < h * 0.15:
            continue
        ww = w * (0.55 + 0.45 * math.sin(math.pi * t) ** 0.6)
        for sg in (1, -1):
            pts = [Vector((x, sg * ww / 2 * math.cos(a) * (1 - 0.65 * math.sin(a) ** 2) * 1.02, zt * math.sin(a) ** 0.8 - 0.06)) for a in (0.15, 0.6, 1.1)]
            p.add('growth%d%d' % (g, sg > 0), 'body', 'chitin', tube(pts, [h * 0.018] * 3, n=4))
    p.fit = dict(top=P((0, 0, h)), radius=length / 2)
    return p
