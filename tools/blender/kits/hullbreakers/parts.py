# Ashfall Hullbreakers part shapes (issue 532 round 3; Ryan, Nov 11 21:24 CST, R217: "the engines look like big tubes, the
# weapons look so simple and just tubes"; RULEBOOK 5.15, ships.md 2c).
# Every part is modelled as the thing it is, at the build sheet already, and the real build uses the same builders:
#   engine_bell   a bell with a throat, an inner cone, cooling rings, gimbal struts, a banded housing and a mount collar
#   gun           a turret ring (or a flank sponson plate and ball), a faceted housing, a mantlet on trunnions, breeches,
#                 barrels with recoil sleeves, muzzle brakes and dark bores
#   launch_tube   a tube with depth, a thick (optionally hooded) lip, a dark bore and clamp bands; optional grille
#   rocket_rack   a framed box of cells, each a short tube with a rocket nose set back in it, on a trunnion yoke and ring
# Pure geometry: mathutils only, no bpy, scale free (sizes are parameters), so the build-sheet kit (world units) and the
# recipe kit (normalised units) both call it. Each builder returns a Part: a list of components (name, role, material,
# verts, faces) in a local frame, plus fit data (pivots, exits, cones) for the fit check (tools/blender/build_sheets/clash.py).
# Local frame of every part: +X forward (the aim, or the engine's thrust direction), +Y left, +Z up (the mount normal).
# Roles: 'mount' parts may sit into the hull (rings, collars, plates, saddles); every other role must stay clear of it.
# Materials are names; the caller maps them: steel, dark, soot, iron, rust, glow, ember, brass, warhead, dish.
import math
from mathutils import Vector, Matrix


class Part:
    def __init__(self, kind):
        self.kind = kind
        self.comps = []   # dict(name, role, mat, verts, faces)
        self.fit = {}     # local-frame fit data, transformed by place()

    def add(self, name, role, mat, vf):
        v, f = vf
        self.comps.append(dict(name=name, role=role, mat=mat, verts=[Vector(p) for p in v], faces=f))

    def extend(self, other, prefix=''):
        for c in other.comps:
            c = dict(c); c['name'] = prefix + c['name']; self.comps.append(c)

    def transform(self, M):
        R = M.to_3x3()
        for c in self.comps:
            c['verts'] = [M @ v for v in c['verts']]
        def tr(val):
            if isinstance(val, dict):
                return {k: tr(x) for k, x in val.items()}
            if isinstance(val, list):
                return [tr(x) for x in val]
            if isinstance(val, tuple) and len(val) == 2 and val[0] in ('p', 'd'):
                return ('p', M @ Vector(val[1])) if val[0] == 'p' else ('d', (R @ Vector(val[1])).normalized())
            return val
        self.fit = tr(self.fit)
        return self


def P(v):
    """a point in the fit data (moved by place)"""
    return ('p', Vector(v))


def D(v):
    """a direction in the fit data (turned by place)"""
    return ('d', Vector(v))


def frame(origin, fwd, up):
    """matrix taking the local frame (+X fwd, +Z up) to the world"""
    f = Vector(fwd).normalized(); u = Vector(up)
    u = (u - f * u.dot(f)).normalized() if (u - f * u.dot(f)).length > 1e-6 else f.orthogonal().normalized()
    l = u.cross(f).normalized()
    M = Matrix(((f.x, l.x, u.x, 0), (f.y, l.y, u.y, 0), (f.z, l.z, u.z, 0), (0, 0, 0, 1)))
    M.translation = Vector(origin)
    return M


# ---------------------------------------------------------------------------------------------------- primitives
def revolve(profile, n=24, closed=False, cap0=False, cap1=False, phase=0.0, axis='X'):
    """surface of revolution about the local X axis. profile: [(x, r)]; closed joins the last ring to the first (a solid
    with an inner and an outer wall); cap0 / cap1 close the first / last ring with a fan."""
    V, F = [], []
    for (x, r) in profile:
        for i in range(n):
            a = 2 * math.pi * i / n + phase
            V.append((x, r * math.cos(a), r * math.sin(a)))
    k = len(profile)
    for j in range(k - 1 + (1 if closed else 0)):
        j2 = (j + 1) % k
        for i in range(n):
            a, b = j * n + i, j * n + (i + 1) % n
            c, d = j2 * n + (i + 1) % n, j2 * n + i
            F.append((a, b, c, d))
    if cap0:
        c0 = len(V); V.append((profile[0][0], 0, 0))
        for i in range(n):
            F.append((c0, (i + 1) % n, i))
    if cap1:
        c1 = len(V); V.append((profile[-1][0], 0, 0)); o = (k - 1) * n
        for i in range(n):
            F.append((c1, o + i, o + (i + 1) % n))
    if axis == 'Z':
        V = [(-z, y, x) for (x, y, z) in V]  # local X -> +Z (a vertical revolve)
    return V, F


def prism(sections):
    """a closed loft through cross-sections [(x, [(y, z), ...])], all with the same point count, capped at both ends"""
    V, F = [], []
    n = len(sections[0][1])
    for x, ring in sections:
        for (y, z) in ring:
            V.append((x, y, z))
    for j in range(len(sections) - 1):
        for i in range(n):
            a, b = j * n + i, j * n + (i + 1) % n
            F.append((a, b, b + n, a + n))
    F.append(tuple(range(n))[::-1]); o = (len(sections) - 1) * n; F.append(tuple(range(o, o + n)))
    return V, F


def octa(hw, hh, ch, yo=0.0, zo=0.0):
    ch = min(ch, hw * 0.95, hh * 0.95)
    return [(yo + hw, zo + hh - ch), (yo + hw - ch, zo + hh), (yo - hw + ch, zo + hh), (yo - hw, zo + hh - ch),
            (yo - hw, zo - hh + ch), (yo - hw + ch, zo - hh), (yo + hw - ch, zo - hh), (yo + hw, zo - hh + ch)]


def block(x0, x1, hw, hh, ch=0.0, yo=0.0, zo=0.0, taper=1.0, ztaper=1.0):
    """an octagonal-section block from x0 to x1; the x1 end shrinks by taper (width) and ztaper (height)"""
    return prism([(x0, octa(hw, hh, ch, yo, zo)), (x1, octa(hw * taper, hh * ztaper, ch * min(taper, ztaper), yo, zo))])


def moved(vf, M):
    v, f = vf
    return [tuple(M @ Vector(p)) for p in v], f


def ring_band(x, r, w, t, n=24):
    """a raised band around a cylinder of radius r at station x: width w, standing t proud"""
    return revolve([(x - w / 2, r - 0.01), (x - w / 2, r + t), (x + w / 2, r + t), (x + w / 2, r - 0.01)], n, closed=True)


# ---------------------------------------------------------------------------------------------------- engine
def engine_bell(r_exit, body_len, bell_len=None, body_r=None, throat=0.55, rings=3, struts=4, nose='dome', seg=28):
    """an engine pod: exhaust leaves along -X. Origin at the centre of the bell's exit plane.
    body: a banded housing forward of the throat, a domed or flat nose, a mount collar at the front of the housing;
    throat: the narrow neck between housing and bell; bell: a flared shell with a lip, an inner wall that glows ember toward
    the throat, an inner cone (the plug) pointing aft, cooling rings on the outside, gimbal struts from housing to bell."""
    p = Part('engine')
    bl = bell_len or r_exit * 1.25
    br = body_r or r_exit * 0.92
    rt = r_exit * throat
    t = max(0.02, r_exit * 0.05)          # bell wall
    xt = bl                               # throat station (forward of the exit plane)
    # bell shell: outer from the throat aft to the exit, lip, inner back to the throat (one closed revolve)
    k = 7
    outer = [(xt - (xt * i / k), rt + (r_exit - rt) * (i / k) ** 1.6) for i in range(k + 1)]
    inner = [(x, max(rt - t, r - t)) for (x, r) in reversed(outer)]
    lip = [(-t * 0.6, r_exit + t * 0.9), (-t * 0.6, r_exit - t * 0.4)]
    prof = outer + lip + inner[1:]
    p.add('bell', 'body', 'steel', revolve(prof, seg, closed=True))
    # ember lining just inside the inner wall, brightest at the throat
    lin = [(x, max(0.01, r - t * 1.3)) for (x, r) in reversed(outer)][: k - 1]
    p.add('lining', 'body', 'ember', revolve(lin, seg))
    p.add('throat_glow', 'body', 'glow', revolve([(xt - t * 2, 0.001), (xt - t * 2, rt - t * 1.2)], seg))
    # the inner cone (plug), from the throat aft to 55 percent of the bell
    p.add('cone', 'body', 'dark', revolve([(xt - t, rt * 0.62), (xt * 0.45, rt * 0.34), (xt * 0.32, 0.001)], 16))
    # cooling rings on the bell
    for i in range(rings):
        f = (i + 1) / (rings + 1)
        x = xt * (1 - f); r = rt + (r_exit - rt) * f ** 1.6
        p.add('cool%d' % i, 'body', 'iron', ring_band(x, r + t * 0.3, max(0.04, r_exit * 0.08), max(0.03, r_exit * 0.07), seg))
    # throat neck and the housing
    neck = [(xt - t, rt + t * 0.5), (xt + r_exit * 0.12, rt + t * 0.5), (xt + r_exit * 0.28, br * 0.86), (xt + r_exit * 0.34, br)]
    xf = xt + body_len
    house = neck + [(xf - br * 0.25, br), (xf - br * 0.12, br * 0.93)]
    if nose == 'dome':
        house += [(xf - br * 0.02, br * 0.72), (xf + br * 0.08, br * 0.42), (xf + br * 0.12, 0.001)]
    else:
        house += [(xf, br * 0.9), (xf, 0.001)]
    p.add('housing', 'mount', 'soot', revolve(house, seg, cap0=True))
    # housing bands and the mount collar (a heavier band at the front)
    nb = max(1, int(body_len / (br * 0.9)))
    for i in range(nb):
        x = xt + r_exit * 0.34 + (body_len - r_exit * 0.34 - br * 0.3) * (i + 0.5) / nb
        p.add('band%d' % i, 'mount', 'iron', ring_band(x, br, max(0.05, br * 0.12), max(0.03, br * 0.06), seg))
    p.add('collar', 'mount', 'iron', ring_band(xf - br * 0.35, br, max(0.08, br * 0.22), max(0.05, br * 0.1), seg))
    # gimbal struts from the housing to the bell's second ring
    for i in range(struts):
        a = 2 * math.pi * (i + 0.5) / struts
        c, s = math.cos(a), math.sin(a)
        f = 2 / (rings + 1); x1 = xt * (1 - f); r1 = rt + (r_exit - rt) * f ** 1.6 + t
        a0 = Vector((xt + r_exit * 0.45, br * 0.97 * c, br * 0.97 * s)); a1 = Vector((x1, r1 * c, r1 * s))
        p.add('strut%d' % i, 'body', 'steel', rod(a0, a1, max(0.025, r_exit * 0.05), 8))
    p.fit = dict(exit=P((0, 0, 0)), axis=D((-1, 0, 0)), radius=r_exit + t, front=P((xf, 0, 0)), body_r=br)
    return p


def rod(a, b, r, n=8, r1=None):
    a, b = Vector(a), Vector(b); d = b - a; L = d.length
    M = frame(a, d, d.orthogonal())
    return moved(revolve([(0, r), (L, r if r1 is None else r1)], n, cap0=True, cap1=True), M)


# ---------------------------------------------------------------------------------------------------- guns
def barrel(L, cal, brake=True, sleeve=0.32, seg=14):
    """one barrel along +X from x=0 (the breech face of the mantlet): a recoil sleeve, a taper, a muzzle brake, a dark bore"""
    p = Part('barrel')
    xs = L * sleeve
    prof = [(0, cal * 1.55), (xs, cal * 1.55), (xs + cal * 0.4, cal * 1.05), (L * 0.93, cal * 0.92)]
    if brake:
        # brake: a squared block wider than the barrel, then the muzzle face ring around the bore
        prof += [(L * 0.93, cal * 0.92), (L * 0.93, cal * 1.45), (L, cal * 1.45), (L, cal * 0.62)]
    else:
        prof += [(L, cal * 1.15), (L, cal * 0.62)]
    prof += [(L - cal * 1.6, cal * 0.62)]
    p.add('tube', 'body', 'steel', revolve(prof, seg, cap0=True, cap1=False, phase=math.pi / seg))
    p.add('bore', 'body', 'dark', revolve([(L - cal * 1.6, 0.001), (L - cal * 1.6, cal * 0.63)], seg))
    if brake:
        # brake vents: two dark slots on each side of the brake block
        for s in (1, -1):
            for j in range(2):
                x0 = L * 0.93 + (L * 0.07) * (0.18 + j * 0.45); x1 = x0 + L * 0.07 * 0.28
                p.add('vent%d%d' % (j, s > 0), 'body', 'dark', block(x0, x1, cal * 0.12, cal * 0.5, 0, yo=s * cal * 1.4))
    # clamp ring at the end of the sleeve
    p.add('clamp', 'body', 'iron', ring_band(xs - cal * 0.4, cal * 1.55, cal * 0.5, cal * 0.18, seg))
    return p


def gun(barrels=2, cal=0.12, blen=2.0, size=1.0, mount='turret', pitch=0.0, variant=0, seg=20):
    """a gun mount. Origin on the hull surface at the mount centre; local +Z the mount normal; local +X the rest aim
    projected into the mount plane; the barrels then elevate by pitch about the trunnions.
    mount 'turret': a turret ring with a bolt ring, a faceted housing with a sloped glacis and a rear bustle, a mantlet on
    trunnions, a breech block behind each barrel inside a breech housing that shows through the bustle sides.
    mount 'casemate': a flank sponson: an armoured octagonal plate on the hull, a box housing standing out from it with a
    sloped face, a ball mantlet in the face, the breeches inside, barrels out of the ball.
    variant: salvage detail differs between matched pairs (a patch plate, a missing bolt ring segment, a borrowed hood)."""
    s = size
    p = Part('gun')
    W = 0.62 * s * (1 + 0.28 * (barrels - 1))   # housing width
    Lh = 0.95 * s                               # housing length
    H = 0.5 * s                                  # housing height
    if mount == 'turret':
        rr = max(W, Lh) * 0.62
        p.add('ring', 'mount', 'iron', revolve([(-0.25 * s, rr * 1.04), (0.1 * s, rr * 1.04), (0.1 * s, rr * 0.9), (0.16 * s, rr * 0.86),
                                               (0.16 * s, 0.001)], seg, cap0=True, axis='Z'))
        p.add('boltring', 'mount', 'steel', revolve([(0.0, rr * 1.04), (0.0, rr * 1.12), (0.07 * s, rr * 1.12), (0.07 * s, rr * 1.04)],
                                                    seg, closed=True, axis='Z'))
        z0 = 0.16 * s
        zc = z0 + H / 2
        # housing: octagonal sections, glacis forward, a bustle aft
        secs = [(-Lh * 0.62, octa(W * 0.42, H * 0.42, H * 0.14, 0, zc - H * 0.06)),
                (-Lh * 0.45, octa(W * 0.48, H * 0.5, H * 0.16, 0, zc)),
                (Lh * 0.18, octa(W * 0.5, H * 0.5, H * 0.18, 0, zc)),
                (Lh * 0.42, octa(W * 0.44, H * 0.3, H * 0.12, 0, zc - H * 0.2))]
        p.add('housing', 'body', 'soot', prism(secs))
        # roof hatch and a vision block, salvage plate on one variant
        p.add('hatch', 'body', 'iron', moved(revolve([(0, W * 0.16), (0.05 * s, W * 0.16), (0.05 * s, 0.001)], 12, axis='Z'),
                                              Matrix.Translation((-Lh * 0.2, W * 0.18, zc + H * 0.5))))
        p.add('vision', 'body', 'dark', block(Lh * 0.05, Lh * 0.2, W * 0.12, H * 0.06, 0, yo=-W * 0.2, zo=zc + H * 0.5))
        if variant % 2:
            p.add('patch', 'body', 'rust', block(-Lh * 0.4, -Lh * 0.05, 0.02 * s, H * 0.3, 0, yo=W * 0.5, zo=zc + H * 0.05))
        mx = Lh * 0.42; mz = zc - H * 0.06
        mantlet_r = H * 0.42
        trunnion = Vector((mx - mantlet_r * 0.3, 0, mz))
    else:
        # casemate: plate on the hull (local z = out of the flank), housing standing out, the ball in its face
        pw = W * 1.25; ph = H * 1.5
        p.add('plate', 'mount', 'iron', moved(block(-0.25 * s, 0.1 * s, ph * 0.5, pw * 0.5, ph * 0.18),
                                              Matrix.Rotation(-math.pi / 2, 4, 'Y')))
        # the box housing: from the plate out 0.55 s, its outer face sloped back
        z0 = 0.1 * s; zo = z0 + 0.55 * s
        hs = [(-Lh * 0.5, [(W * 0.48, z0), (W * 0.48, zo - 0.08 * s), (W * 0.36, zo), (-W * 0.36, zo), (-W * 0.48, zo - 0.08 * s), (-W * 0.48, z0)]),
              (Lh * 0.32, [(W * 0.48, z0), (W * 0.48, zo - 0.08 * s), (W * 0.36, zo), (-W * 0.36, zo), (-W * 0.48, zo - 0.08 * s), (-W * 0.48, z0)]),
              (Lh * 0.5, [(W * 0.4, z0), (W * 0.4, zo - 0.16 * s), (W * 0.3, zo - 0.1 * s), (-W * 0.3, zo - 0.1 * s), (-W * 0.4, zo - 0.16 * s), (-W * 0.4, z0)])]
        # in a casemate, local +Y is along the hull (up or down the flank); the housing is wide along Y
        p.add('housing', 'body', 'soot', prism(hs))
        if variant % 2:
            p.add('patch', 'body', 'rust', block(-Lh * 0.45, -Lh * 0.1, W * 0.3, 0.015 * s, 0, zo=zo + 0.01 * s))
        mx = Lh * 0.5; mz = (z0 + zo) / 2
        mantlet_r = 0.24 * s * (1 + 0.12 * (barrels - 1))
        trunnion = Vector((mx - mantlet_r * 0.4, 0, mz))
    # the mantlet: a ball (casemate) or a curved shield on the trunnions (turret), turning with the elevation
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    if mount == 'turret':
        mw = W * 0.82
        shield = revolve([(-mw / 2, mantlet_r * 0.95), (-mw / 2 + 0.03 * s, mantlet_r), (mw / 2 - 0.03 * s, mantlet_r),
                          (mw / 2, mantlet_r * 0.95)], 18, cap0=True, cap1=True)
        shield = ([(y, x, z) for (x, y, z) in shield[0]], shield[1])   # axis along local Y (the trunnion axis)
        p.add('mantlet', 'body', 'iron', moved(shield, E))
        for sgn in (1, -1):
            p.add('trunnion%d' % (sgn > 0), 'body', 'steel', moved(rod((0, sgn * mw / 2, 0), (0, sgn * (mw / 2 + 0.06 * s), 0), mantlet_r * 0.45, 12), E))
    else:
        ball = []
        k = 7
        for i in range(k + 1):
            a = -math.pi / 2 + math.pi * i / k
            ball.append((mantlet_r * math.sin(a), max(0.001, mantlet_r * math.cos(a))))
        p.add('mantlet', 'body', 'iron', moved(revolve(ball, 18), E))
        p.add('collar', 'body', 'steel', moved(ring_band(-mantlet_r * 0.35, mantlet_r * 0.9, mantlet_r * 0.35, mantlet_r * 0.18, 18), E))
    # breeches (inside the housing, the back blocks show at the bustle) and barrels from the mantlet face
    muzzles = []
    for i in range(barrels):
        off = (i - (barrels - 1) / 2) * cal * 3.6
        bx0 = mantlet_r * 0.55
        p.add('breech%d' % i, 'body', 'steel', moved(block(-mantlet_r * 1.6, -mantlet_r * 0.2, cal * 1.9, cal * 1.7, cal * 0.5, yo=off), E))
        b = barrel(blen, cal, brake=True)
        for c in b.comps:
            p.add('b%d_%s' % (i, c['name']), c['role'], c['mat'], moved((c['verts'], c['faces']), E @ Matrix.Translation((bx0, off, 0))))
        muzzles.append(P(E @ Vector((bx0 + blen, off, 0))))
    pivot = Vector((0, 0, trunnion.z))
    p.fit = dict(pivot=P(pivot), trunnion=P(trunnion), muzzles=muzzles, reach=bx0 + blen + trunnion.x,
                 aim=D(E.to_3x3() @ Vector((1, 0, 0))), up=D((0, 0, 1)), mount=mount, radius=max(W, Lh) * 0.6)
    return p


# ---------------------------------------------------------------------------------------------------- tubes and racks
def launch_tube(r, depth, lip=0.18, hood=0.0, bands=2, grille=False, seg=24, wall=0.14):
    """a launch tube or scoop with real depth. Origin at the centre of the mouth; the tube runs back along -X to the bore floor.
    lip: a thick rolled rim (fraction of r); hood: the upper lip reaches forward further than the lower one (fraction of r),
    a cowl; grille: bars across the mouth set back a little (scoop drums). The bore is dark and deep, never a disc."""
    p = Part('tube')
    t = r * wall
    ro = r + t
    prof = [(-depth, ro), (-r * 0.25, ro), (-r * 0.12, ro + r * lip * 0.6), (0.0, ro + r * lip * 0.55), (r * 0.02, ro), (r * 0.02, r),
            (-depth * 0.92, r)]
    V, F = revolve(prof, seg, cap0=True)
    if hood:
        # pull the mouth forward on the upper half: the cowl
        V = [(x + (hood * r * max(0.0, z / ro) if x > -r * 0.3 else 0.0), y, z) for (x, y, z) in V]
    p.add('tube', 'mount', 'soot', (V, F))
    p.add('bore', 'body', 'dark', revolve([(-depth * 0.92, 0.001), (-depth * 0.92, r * 1.001), (-depth * 0.35, r * 1.001)], seg))
    for i in range(bands):
        x = -depth * (0.35 + 0.45 * i / max(1, bands - 1)) if bands > 1 else -depth * 0.5
        p.add('band%d' % i, 'mount', 'iron', ring_band(x, ro, r * 0.22, r * 0.08, seg))
    if grille:
        n = 5
        for i in range(n):
            y = -r + 2 * r * (i + 0.5) / n
            h = math.sqrt(max(0.0, r * r - y * y))
            p.add('bar%d' % i, 'body', 'steel', block(-r * 0.3, -r * 0.2, r * 0.05, h, 0, yo=y))
        p.add('hub', 'body', 'steel', revolve([(-r * 0.32, r * 0.22), (-r * 0.18, r * 0.22), (-r * 0.18, 0.001)], 12))
    p.fit = dict(mouth=P((0, 0, 0)), axis=D((1, 0, 0)), radius=r)
    return p


def rocket_rack(rows, cols, cell=0.4, depth=1.8, yoke=True, variant=0, seg=12):
    """a box of launch cells: a welded frame with cell dividers, each cell a short tube with a rocket nose set back in its
    mouth, side cheeks on a trunnion yoke, a slewing ring underneath. Origin: the slewing ring centre on the deck; the cell
    faces point +X. Racks are big and mismatched (factions.md): variant changes the frame plates and the nose colour."""
    p = Part('rack')
    W = cols * cell + cell * 0.35; H = rows * cell + cell * 0.35
    zb = 0.35 * cell + (0.25 * cell if yoke else 0)          # box underside
    zc = zb + H / 2
    # the box, slightly tapered to the back
    p.add('box', 'body', 'soot', prism([(-depth, octa(W * 0.47, H * 0.47, cell * 0.12, 0, zc)),
                                        (-cell * 0.2, octa(W * 0.5, H * 0.5, cell * 0.1, 0, zc))]))
    # front frame: outer bars and dividers, standing proud of the cell faces
    fx0, fx1 = -cell * 0.2, cell * 0.08
    bar = cell * 0.09
    p.add('frame_t', 'body', 'iron', block(fx0, fx1, W / 2, bar, 0, zo=zc + H / 2 - bar))
    p.add('frame_b', 'body', 'iron', block(fx0, fx1, W / 2, bar, 0, zo=zc - H / 2 + bar))
    p.add('frame_l', 'body', 'iron', block(fx0, fx1, bar, H / 2, 0, yo=W / 2 - bar, zo=zc))
    p.add('frame_r', 'body', 'iron', block(fx0, fx1, bar, H / 2, 0, yo=-W / 2 + bar, zo=zc))
    for c in range(1, cols):
        y = -cols * cell / 2 + c * cell
        p.add('div_v%d' % c, 'body', 'steel', block(fx0, fx1 - 0.02 * cell, bar * 0.45, H / 2 - bar, 0, yo=y, zo=zc))
    for r_ in range(1, rows):
        z = zc - rows * cell / 2 + r_ * cell
        p.add('div_h%d' % r_, 'body', 'steel', block(fx0, fx1 - 0.02 * cell, W / 2 - bar, bar * 0.45, 0, zo=z))
    exits = []
    nose_mat = 'warhead' if variant % 2 == 0 else 'brass'
    for r_ in range(rows):
        for c in range(cols):
            y = -cols * cell / 2 + (c + 0.5) * cell
            z = zc - rows * cell / 2 + (r_ + 0.5) * cell
            M = Matrix.Translation((0, y, z))
            rt = cell * 0.36
            # cell tube: lip ring and a dark bore going back, a rocket nose set back inside
            p.add('cell%d%d' % (r_, c), 'body', 'steel', moved(revolve([(-cell * 0.25, rt * 1.18), (0.0, rt * 1.18), (0.0, rt), (-depth * 0.6, rt)],
                                                                         seg), M))
            p.add('bore%d%d' % (r_, c), 'body', 'dark', moved(revolve([(-depth * 0.6, 0.001), (-depth * 0.6, rt), (-cell * 0.35, rt * 1.002)], seg), M))
            p.add('nose%d%d' % (r_, c), 'body', nose_mat, moved(revolve([(-cell * 0.55, rt * 0.82), (-cell * 0.42, rt * 0.8), (-cell * 0.2, rt * 0.45),
                                                                        (-cell * 0.12, 0.001)], seg, cap0=True), M))
            exits.append(dict(pos=P((cell * 0.08, y, z)), axis=D((1, 0, 0)), radius=rt))
    # side cheeks with lightening holes (dark discs), the trunnion yoke and the slewing ring
    for sgn in (1, -1):
        p.add('cheek%d' % (sgn > 0), 'body', 'iron', block(-depth * 0.85, -cell * 0.3, cell * 0.06, H * 0.42, cell * 0.08, yo=sgn * (W / 2 + cell * 0.06), zo=zc))
        p.add('hole%d' % (sgn > 0), 'body', 'dark', moved(revolve([(0, 0.001), (0, cell * 0.28)], 12),
                                                         Matrix.Translation((-depth * 0.5, sgn * (W / 2 + cell * 0.125), zc)) @ Matrix.Rotation(sgn * math.pi / 2, 4, 'Z')))
    if yoke:
        rr = min(W, depth) * 0.42
        p.add('yoke', 'mount', 'steel', block(-depth * 0.75, -depth * 0.2, W * 0.35, (zb + 0.05 * cell) / 2, cell * 0.08, zo=(zb + 0.05 * cell) / 2 - 0.02 * cell))
        p.add('ring', 'mount', 'iron', moved(revolve([(-0.2 * cell, rr), (0.25 * cell, rr), (0.25 * cell, 0.001)], 20, axis='Z', cap0=True),
                                             Matrix.Translation((-depth * 0.48, 0, 0))))
    if variant % 2:
        p.add('salvage', 'body', 'rust', block(-depth * 0.7, -depth * 0.3, W * 0.3, 0.03 * cell, 0, zo=zc + H / 2 + 0.02 * cell))
    p.fit = dict(exits=exits, box=dict(x=(-depth, cell * 0.08), w=W, z=(zb, zb + H)))
    return p


# ---------------------------------------------------------------------------------------------------- R218: every other part type
# Ryan, Nov 11 21:34 CST (R218): "Engines and guns are the reference but we want to carry that through to the whole model."
# Each type below carries the sub-parts that make it read as that thing (ships.md 2c, RULEBOOK 5.16). SUBPARTS names them so a
# sheet can tick each inventory line: present, shaped (built by its kit type), detailed (every sub-part modelled).
SUBPARTS = {
    'engine': ['housing', 'collar', 'band', 'bell', 'lining', 'throat_glow', 'cone', 'cool', 'strut'],
    'gun': ['ring|plate', 'housing', 'mantlet', 'breech', 'tube', 'clamp', 'bore', 'vent'],
    'tube': ['tube', 'bore', 'band'],
    'rack': ['box', 'frame', 'div', 'cell', 'nose', 'bore', 'cheek', 'yoke', 'ring'],
    'dish': ['bowl', 'rib', 'feed', 'strut', 'yoke', 'post', 'base'],
    'claw': ['hinge', 'arm', 'joint', 'ram', 'finger'],
    'chain': ['link', 'lug'],
    'hatch': ['rim', 'door', 'seam', 'hinge'],
    'hatchbox': ['frame', 'lid', 'rib'],
    'vent': ['frame', 'slat'],
    'lamp': ['housing', 'hood', 'lens'],
    'thruster': ['block', 'nozzle'],
    'antenna': ['base', 'mast', 'whip', 'pod'],
    'pipe': ['run', 'flange'],
    'bay': ['rim', 'leaf', 'seam', 'hinge'],
    'slit': ['frame', 'glass'],
    'plate': ['slab', 'step', 'bevel', 'rivet'],
    'patch': ['slab', 'lift', 'rivet'],
    'hull': ['bevel', 'step', 'overhang'],
    'tier': ['face', 'roof', 'opening'],
    'rib': ['rib'],
    'pylon': ['web', 'plate'],
}


def detail_ok(kind, names):
    """True when every sub-part of a kit type is among the component names (prefix match; 'a|b' means either)"""
    need = SUBPARTS.get(kind, [])
    return all(any(any(n.split('_')[-1].startswith(alt) or n.startswith(alt) for n in names) for alt in req.split('|')) for req in need)


def dish(r, depth=None, ribs=6, post=0.9, seg=24):
    """a listening dish: a base plate, a post, a yoke, a shallow bowl with a rolled rim and radial ribs behind it, a feed horn
    on three struts. Origin at the base on the deck; the bowl faces +X (tilted by the caller)."""
    p = Part('dish')
    d = depth or r * 0.32
    h = r * post
    p.add('base', 'mount', 'iron', block(-r * 0.32, r * 0.32, r * 0.3, r * 0.05, r * 0.06, zo=r * 0.05))
    p.add('post', 'body', 'steel', rod((0, 0, 0.0), (0, 0, h), r * 0.09, 10))
    c = Vector((r * 0.05, 0, h))
    p.add('yoke', 'body', 'steel', block(-r * 0.12, r * 0.1, r * 0.22, r * 0.08, r * 0.03, zo=h))
    # bowl: a paraboloid shell with thickness and a rolled rim
    k = 8
    outer = [(c.x + d * (i / k) ** 2 * 0 + d * (1 - (1 - i / k) ** 2) * 0, 0) for i in range(1)]
    prof = []
    for i in range(k + 1):
        rr = r * i / k
        prof.append((c.x + 0.12 * r + d * (rr / r) ** 2, max(0.001, rr)))
    rim = [(prof[-1][0] + r * 0.03, r * 1.03), (prof[-1][0] - r * 0.02, r * 1.04)]
    back = [(x - r * 0.04, rr) for (x, rr) in reversed(prof)]
    V, F = revolve(prof + rim + back, seg)
    V = [(x, y, z + h) for (x, y, z) in V]
    p.add('bowl', 'body', 'dish', (V, F))
    for i in range(ribs):
        a = 2 * math.pi * i / ribs
        e = Vector((0, math.cos(a), math.sin(a)))
        p.add('rib%d' % i, 'body', 'steel', rod(Vector((c.x + 0.08 * r, 0, h)), Vector((c.x + 0.08 * r + d * 0.9, 0, h)) + e * r * 0.95, r * 0.025, 6))
    tip = Vector((c.x + 0.12 * r + r * 0.75, 0, h))
    p.add('feed', 'body', 'steel', rod(tip - Vector((r * 0.12, 0, 0)), tip, r * 0.07, 10, r1=r * 0.1))
    for i in range(3):
        a = 2 * math.pi * i / 3 + 0.5
        e = Vector((0, math.cos(a), math.sin(a)))
        p.add('strut%d' % i, 'body', 'steel', rod(Vector((c.x + 0.12 * r + d * 0.7, 0, h)) + e * r * 0.82, tip - Vector((r * 0.1, 0, 0)), r * 0.018, 5))
    p.fit = dict(face=P((c.x + 0.12 * r + d, 0, h)), axis=D((1, 0, 0)), radius=r)
    return p


def claw(hinge_r, segs, w=0.45, fingers=3, ram=True):
    """a boarding claw or grapple. segs: points (local) from the hinge (origin) out to the wrist; the last segment ends in a
    hand of hooked fingers. Sub-parts: hinge drum with end caps, armoured arm segments (tapered, bevelled), joint drums, a
    piston ram along the first segment, hooked fingers (two or three blades curling inward)."""
    p = Part('claw')
    p.add('hinge', 'mount', 'iron', moved(revolve([(-w * 0.65, hinge_r * 0.9), (-w * 0.6, hinge_r), (w * 0.6, hinge_r), (w * 0.65, hinge_r * 0.9),
                                                   (w * 0.65, 0.001)], 16, cap0=True), Matrix.Rotation(math.pi / 2, 4, 'Z')))
    prev = Vector((0, 0, 0)); pts = [Vector(q) for q in segs]
    th = w * 0.36
    for i, q in enumerate(pts):
        d = q - prev; L = d.length
        if L < 1e-6:
            continue
        k0 = 1.0 - 0.35 * i / len(pts); k1 = 1.0 - 0.35 * (i + 1) / len(pts)
        M = frame(prev, d, (0, 1, 0) if abs(d.normalized().y) < 0.9 else (1, 0, 0))
        # arm segment: an octagonal box tapering along its length (local frame: X along the arm, Z = across, Y = sideways)
        p.add('arm%d' % i, 'body', 'steel', moved(prism([(0.0, octa(w * 0.5 * k0, th * k0, th * 0.35)), (L, octa(w * 0.5 * k1, th * k1, th * 0.3))]), M))
        p.add('armplate%d' % i, 'body', 'soot', moved(block(L * 0.15, L * 0.8, w * 0.52 * k1, th * 0.5, th * 0.15, zo=th * k0 * 0.55), M))
        if i < len(pts) - 1:
            p.add('joint%d' % i, 'body', 'iron', moved(revolve([(-w * 0.55, th * 1.1 * k1), (w * 0.55, th * 1.1 * k1)], 14, cap0=True, cap1=True),
                                                       Matrix.Translation(q) @ Matrix.Rotation(math.pi / 2, 4, 'Z')))
        if i == 0 and ram:
            a0 = M @ Vector((L * 0.1, 0, th * 1.6)); a1 = M @ Vector((L * 0.8, 0, th * 1.2))
            p.add('ram_cyl', 'body', 'iron', rod(a0, a0.lerp(a1, 0.55), th * 0.32, 10))
            p.add('ram_rod', 'body', 'steel', rod(a0.lerp(a1, 0.5), a1, th * 0.18, 8))
        prev = q
    # the hand: fingers from the wrist, each two blades bending inward to a hook
    d = (pts[-1] - (pts[-2] if len(pts) > 1 else Vector((0, 0, 0)))).normalized()
    side = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
    out = d.cross(side).normalized()
    for f in range(fingers):
        sp = (f - (fingers - 1) / 2) * w * 0.38
        a = pts[-1] + side * sp
        b = a + d * w * 0.9 + out * w * 0.35
        c = b + d * w * 0.45 - out * w * 0.45
        for j, (u0, u1, t0, t1) in enumerate(((a, b, 0.16, 0.12), (b, c, 0.12, 0.02))):
            M = frame(u0, u1 - u0, side)
            L = (u1 - u0).length
            p.add('finger%d%d' % (f, j), 'body', 'steel', moved(prism([(0.0, octa(w * t0, w * 0.1, w * 0.03)), (L, octa(max(0.005, w * t1), w * 0.06, 0.0))]), M))
    p.fit = dict(tip=P(pts[-1] + d * w * 1.2))
    return p


def chain(pts, link=0.32, r=0.05):
    """a chain of real links between lugs (taut: nothing hangs in space). Links alternate 90 degrees."""
    p = Part('chain')
    pts = [Vector(q) for q in pts]
    k = 0
    for a, b in zip(pts, pts[1:]):
        d = b - a; L = d.length; n = max(1, int(L / (link * 0.78)))
        for i in range(n):
            c = a + d * ((i + 0.5) / n)
            up = d.orthogonal() if k % 2 == 0 else d.cross(d.orthogonal())
            M = frame(c, d, up)
            # an oval link: a closed ring of 8 rods around a stadium
            ring = []
            for j in range(10):
                t = 2 * math.pi * j / 10
                ring.append(Vector((math.cos(t) * link * 0.5, 0, math.sin(t) * link * 0.28)))
            V, F = [], []
            for j in range(10):
                vv, ff = rod(ring[j], ring[(j + 1) % 10], r, 5)
                o = len(V); V += vv; F += [tuple(x + o for x in f) for f in ff]
            p.add('link%d' % k, 'mount', 'iron', moved((V, F), M)); k += 1
    for j, q in enumerate((pts[0], pts[-1])):
        p.add('lug%d' % j, 'mount', 'steel', block(q.x - 0.18, q.x + 0.18, 0.16, 0.16, 0.05, yo=q.y, zo=q.z))
    return p


def hatch(w, h, round_=False, wheel=True):
    """a hatch on a surface (local +Z out of the surface): a raised rim, a door set a little proud with a seam around it,
    two hinge knuckles, a hand wheel on round hatches."""
    p = Part('hatch')
    if round_:
        r = w / 2
        p.add('rim', 'mount', 'iron', revolve([(-0.03, r * 1.18), (0.06, r * 1.18), (0.06, r * 1.02), (-0.03, r * 1.02)], 20, closed=True, axis='Z'))
        p.add('seam', 'body', 'dark', revolve([(0.0, r * 1.02), (0.0, r * 0.98)], 20, axis='Z'))
        p.add('door', 'body', 'steel', revolve([(-0.02, r * 0.96), (0.04, r * 0.96), (0.06, r * 0.8), (0.06, 0.001)], 20, axis='Z'))
        if wheel:
            p.add('wheel', 'body', 'iron', moved(revolve([(0.0, r * 0.42), (0.02, r * 0.42), (0.02, r * 0.34), (0.0, r * 0.34)], 14, closed=True), Matrix.Translation((0, 0, 0.1)) @ Matrix.Rotation(-math.pi / 2, 4, 'Y')))
        hx = r
    else:
        p.add('rim', 'mount', 'iron', prism([(-0.03, octa(w / 2 + 0.06, h / 2 + 0.06, 0.05)), (0.05, octa(w / 2 + 0.06, h / 2 + 0.06, 0.05))]) if False else
              block(-0.03, 0.05, w / 2 + 0.07, h / 2 + 0.07, 0.06))
        p.add('seam', 'body', 'dark', block(0.05, 0.055, w / 2 + 0.01, h / 2 + 0.01, 0.04))
        p.add('door', 'body', 'steel', block(0.05, 0.1, w / 2 - 0.02, h / 2 - 0.02, 0.05, taper=0.96, ztaper=0.96))
        hx = w / 2
        # local X is out of the surface for blocks: rotate so the block axis is +Z
        for c in p.comps:
            c['verts'] = [Vector((-v.z, v.y, v.x)) for v in c['verts']]
    for s in (1, -1):
        p.add('hinge%d' % (s > 0), 'body', 'iron', rod((-hx * 0.9, s * hx * 0.45, 0.06), (-hx * 0.9, s * hx * 0.15, 0.06), 0.05, 8))
    return p


def hatchbox(w, l, h, fins=0):
    """a raised framed box on the deck: a frame block, an inset lid, side ribs; fins adds slanted armour blades on top
    (A16's armoured vent housing). Origin on the deck; +X forward."""
    p = Part('hatchbox')
    p.add('frame', 'mount', 'soot', block(-l / 2, l / 2, w / 2, h / 2, h * 0.25, zo=h / 2 - 0.05, taper=0.92, ztaper=0.9))
    p.add('lid', 'body', 'iron', block(-l * 0.38, l * 0.32, w * 0.36, 0.04, 0.03, zo=h * 0.95))
    p.add('lidseam', 'body', 'dark', block(-l * 0.4, l * 0.34, w * 0.38, 0.02, 0.02, zo=h * 0.92))
    for i in range(3):
        x = -l * 0.35 + l * 0.35 * i
        for s in (1, -1):
            p.add('rib%d%d' % (i, s > 0), 'body', 'steel', block(x - 0.04, x + 0.04, 0.035, h * 0.4, 0.0, yo=s * (w / 2 + 0.01), zo=h * 0.45))
    for i in range(fins):
        y = (i - (fins - 1) / 2) * w * 0.42
        p.add('fin%d' % i, 'body', 'soot', prism([(-l * 0.35, [(y + 0.08, h), (y - 0.08, h), (y - 0.08, h + 0.05), (y + 0.08, h + 0.05)]),
                                                  (l * 0.4, [(y + 0.08, h), (y - 0.08, h), (y - 0.08, h + h * 1.2), (y + 0.08, h + h * 1.2)])]))
    return p


def vent(w, h, slats=5, depth=0.12):
    """a louvre panel on a surface (local +Z out): a frame, slanted slats, a dark recess behind them"""
    p = Part('vent')
    fr = 0.06
    p.add('back', 'mount', 'dark', block(-0.03, 0.01, w / 2, h / 2, 0))
    for (yo, zo, hw, hh) in ((0, h / 2 - fr / 2, w / 2, fr / 2), (0, -h / 2 + fr / 2, w / 2, fr / 2), (w / 2 - fr / 2, 0, fr / 2, h / 2), (-w / 2 + fr / 2, 0, fr / 2, h / 2)):
        p.add('frame', 'mount', 'iron', block(-0.02, depth, hw, hh, 0, yo=yo, zo=zo))
    for i in range(slats):
        z = -h / 2 + fr + (h - 2 * fr) * (i + 0.5) / slats
        p.add('slat%d' % i, 'body', 'steel', prism([(depth * 0.2, [(w / 2 - fr, z - 0.02), (-w / 2 + fr, z - 0.02), (-w / 2 + fr, z + 0.02), (w / 2 - fr, z + 0.02)]),
                                                    (depth * 0.8, [(w / 2 - fr, z + (h - 2 * fr) / slats * 0.35 - 0.02), (-w / 2 + fr, z + (h - 2 * fr) / slats * 0.35 - 0.02),
                                                                   (-w / 2 + fr, z + (h - 2 * fr) / slats * 0.35 + 0.02), (w / 2 - fr, z + (h - 2 * fr) / slats * 0.35 + 0.02)])]))
    for c in p.comps:
        c['verts'] = [Vector((-v.z, v.y, v.x)) for v in c['verts']]
    return p


def lamp(r=0.09, hood=True):
    """a running light (local +Z out of the hull): a squat housing, a hood over the top, a red lens"""
    p = Part('lamp')
    p.add('housing', 'mount', 'iron', revolve([(-0.02, r * 1.5), (r * 0.7, r * 1.5), (r * 0.7, r * 1.1)], 10, axis='Z'))
    p.add('lens', 'body', 'light', revolve([(r * 0.68, r * 1.1), (r * 1.1, r * 0.7), (r * 1.25, 0.001)], 10, axis='Z'))
    if hood:
        p.add('hood', 'body', 'steel', block(r * 0.6, r * 1.5, r * 1.6, 0.012, 0.0, zo=r * 1.55))
        p.comps[-1]['verts'] = [Vector((v.x - r * 0.9, v.y, v.z)) for v in p.comps[-1]['verts']]
    return p


def thruster(r=0.35, nozzles=4):
    """an attitude thruster quad (local +Z out of the hull): a bevelled block, four small bells splayed out"""
    p = Part('thruster')
    p.add('block', 'mount', 'iron', block(-0.25 * r, 0.6 * r, r, r, r * 0.3))
    for c in p.comps:
        c['verts'] = [Vector((-v.z, v.y, v.x + 0.0)) for v in c['verts']]
    for i in range(nozzles):
        a = 2 * math.pi * (i + 0.5) / nozzles
        e = Vector((math.cos(a), math.sin(a), 0))
        o = e * r * 0.5 + Vector((0, 0, r * 0.6))
        d = (e * 0.5 + Vector((0, 0, 1))).normalized()
        M = frame(o, d, Vector((0, 0, 1)).cross(e) if abs(d.z) < 0.99 else Vector((1, 0, 0)))
        p.add('nozzle%d' % i, 'body', 'steel', moved(revolve([(0, r * 0.16), (r * 0.12, r * 0.14), (r * 0.42, r * 0.3), (r * 0.42, r * 0.24), (r * 0.15, r * 0.1)], 10), M))
    p.fit = dict(out=D((0, 0, 1)))
    return p


def antenna(h, whips=3, pod=True):
    """an antenna array (never a crossbar mast, R185): a base block, a short mast, whips of uneven height, a sensor pod"""
    p = Part('antenna')
    p.add('base', 'mount', 'iron', block(-0.25, 0.25, 0.22, 0.12, 0.05, zo=0.08))
    p.add('mast', 'body', 'steel', rod((0, 0, 0.15), (0, 0, h * 0.45), 0.07, 8))
    for i in range(whips):
        a = 2 * math.pi * i / whips
        o = Vector((math.cos(a) * 0.12, math.sin(a) * 0.12, h * 0.4))
        p.add('whip%d' % i, 'body', 'steel', rod(o, o + Vector((0, 0, h * (0.45 + 0.25 * ((i * 7) % 3) / 2))), 0.025, 6, r1=0.012))
    if pod:
        p.add('pod', 'body', 'iron', moved(revolve([(-0.18, 0.001), (-0.14, 0.11), (0.14, 0.11), (0.18, 0.001)], 10), Matrix.Translation((0.0, 0, h * 0.42))))
    return p


def pipe(pts, r=0.07, flanges=True):
    """a pipe run along the hull: segments, flange rings at each joint and every metre, brackets down to the hull"""
    p = Part('pipe')
    pts = [Vector(q) for q in pts]
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        p.add('run%d' % i, 'mount', 'steel', rod(a, b, r, 10))
        if flanges:
            n = max(1, int((b - a).length / 1.0))
            for j in range(n + 1):
                c = a.lerp(b, j / n); d = b - a
                p.add('flange%d_%d' % (i, j), 'mount', 'iron', rod(c - d.normalized() * 0.03, c + d.normalized() * 0.03, r * 1.5, 10))
    return p


def bay(w, l, leaves=2):
    """a ventral launch bay door (local +Z out of the hull): a raised rim, door leaves with a centre seam, hinge knuckles"""
    p = Part('bay')
    p.add('rim', 'mount', 'iron', block(-0.04, 0.08, l / 2 + 0.12, w / 2 + 0.12, 0.08))
    for i in range(leaves):
        y0 = -w / 2 + w * i / leaves + 0.03; y1 = -w / 2 + w * (i + 1) / leaves - 0.03
        p.add('leaf%d' % i, 'body', 'steel', block(0.08, 0.12, l / 2 - 0.04, (y1 - y0) / 2, 0.03, yo=(y0 + y1) / 2))
    p.add('seam', 'body', 'dark', block(0.08, 0.1, l / 2 - 0.04, 0.03, 0.0))
    for c in p.comps:
        c['verts'] = [Vector((v.y, v.z, v.x)) for v in c['verts']]
    for i in range(3):
        x = -l / 2 + l * (i + 0.5) / 3
        for s in (1, -1):
            p.add('hinge%d%d' % (i, s > 0), 'body', 'iron', rod((x - 0.2, s * w / 2, 0.12), (x + 0.2, s * w / 2, 0.12), 0.06, 8))
    # rotate so +Z is out: the block axis (X) became Z above
    return p


def slit(w, h, depth=0.08):
    """a window or vision slit in a tier face (local +Z out): a frame proud of the face and dark glass set back"""
    p = Part('slit')
    p.add('frame', 'mount', 'iron', block(-0.02, depth, w / 2 + 0.05, h / 2 + 0.05, 0.03))
    p.add('glass', 'body', 'dark', block(depth * 0.4, depth + 0.004, w / 2, h / 2, 0.0))
    for c in p.comps:
        c['verts'] = [Vector((-v.z, v.y, v.x)) for v in c['verts']]
    return p


def plate_slab(bot, nrm, t, bevel=0.25, rivets=True, lift=0.0, rr=0.035):
    """one armour plate on a hull face: bot = the four corners on the surface (world), nrm = outward normal. A slab of
    thickness t with a bevelled top edge (bevel as a fraction of t), rivets at the corners; lift raises one corner (a
    torn patch). Returns (verts, faces) lists for the slab and the rivets."""
    bot = [Vector(q) for q in bot]; nrm = Vector(nrm)
    mid = sum(bot, Vector()) / 4
    top = []
    for i, q in enumerate(bot):
        sh = (mid - q).normalized() * min(t * bevel, (mid - q).length * 0.3)
        top.append(q + nrm * (t + (lift if i == 2 else 0.0)) + sh)
    base = [q - nrm * 0.02 for q in bot]
    V = [tuple(q) for q in base + top]
    F = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    RV, RF = [], []
    if rivets:
        for i, q in enumerate(top):
            c = q + (mid + nrm * t - q) * 0.16
            vv, ff = rod(c - nrm * 0.01, c + nrm * rr * 0.8, rr, 6)
            o = len(RV); RV += vv; RF += [tuple(x + o for x in f) for f in ff]
    return (V, F), (RV, RF)
