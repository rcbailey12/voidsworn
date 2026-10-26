# A4 kit: the hand-built parts that replace what the AI mangles (guns, launchers, engines, bridges, antennas, radiators, tanks, bays) and
# the hard points the effects helper attaches to. Blender working frame (frame.py): x bow, y port, z up, ship length 1.0.
# Rules built in (CLAUDE.md): every part is seated on the real hull surface on a visible mount (a plinth that reaches below the lowest
# point of the hull under its footprint, so it never floats and never shows a light gap), guns aim forward or out to the side (the
# builder refuses anything else), pairs mirror exactly (Corsair excepted, by choice of the ship file), and no naval parts exist here at
# all: no masts with yards, funnels, keels, rails, ladders, anchors or porthole rows.
import math, random
import numpy as np
import bpy, bmesh
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
import hs_lib, detail_lib, dress

# K1 decision 1: mount ring radius in world units by mount size; divided by the class length (ships3d.js CLS_LEN) to get ship units
MOUNT_R = dict(S=.16, M=.26, L=.40, XL=.55)
CLS_LEN = {'Squadron': 1.6, 'Transport': 11, 'Frigate': 6.5, 'Destroyer': 9.5, 'Cruiser': 14.5, 'Carrier': 16.5, 'Battleship': 21, 'Dreadnought': 27,
           'Super-dreadnought': 31, 'Battle-barge': 26, 'Bio-titan': 28, 'Ark': 26, 'Tomb-ark': 28, 'station': 30, 'transport': 11, 'beacon': 6}
BAND = {'Frigate': 'S', 'Squadron': 'S', 'beacon': 'S', 'Destroyer': 'M', 'Cruiser': 'M', 'transport': 'M', 'Battleship': 'L', 'Carrier': 'L',
        'Battle-barge': 'L', 'Dreadnought': 'XL', 'Super-dreadnought': 'XL', 'Ark': 'XL', 'Bio-titan': 'XL', 'Tomb-ark': 'XL', 'station': 'XL'}

HP = []      # hard points: dict(name, kind, p, fwd, up, size, arc, slot, wkind, radius)
GUNS = []    # (part name, direction, arc) for the no-backward-guns audit
CTX = dict(T=None, L=1.0, fac='voidsworn', pal=None, rng=random.Random(1))


def srgb(h): return dress.srgb(h)
def mul(c, k): return tuple(min(1., x * k) for x in c)


def palette(fac):
    """part colours (linear) per faction, from FAC3D (ships3d.js) like bakemat: base hull, dark, trim, gun metal, lens (win), engine (eng)"""
    F = {'voidsworn': ('#4a4440', '#1c1918', '#9c3a1c', (1, .42, .12), (1, .50, .16)), 'hegemony': ('#c4ccd5', '#5a6573', '#3a78d0', (.78, .9, 1), (.45, .72, 1)),
         'corsair': ('#6a2c22', '#28140f', '#a3542c', (1, .4, .2), (1, .38, .16)), 'chorus': ('#57364c', '#211419', '#a4913a', (.85, .92, .25), (.80, .90, .28)),
         'ithar': ('#e4ebe7', '#6c8179', '#d7c88a', (.6, 1, .82), (.62, 1, .84)), 'deathless': ('#2c3431', '#121715', '#1fbf4a', (.15, 1, .35), (.15, 1, .35))}[fac]
    base, dark, trim = srgb(F[0]), srgb(F[1]), srgb(F[2])
    gun = {'voidsworn': (.045, .042, .040), 'hegemony': (.30, .33, .37), 'corsair': (.07, .07, .075), 'chorus': mul(dark, 1.4), 'ithar': (.62, .66, .64), 'deathless': (.05, .06, .055)}[fac]
    finish = {'voidsworn': (.55, .36), 'hegemony': (.46, .16), 'corsair': (.62, .35), 'chorus': (.4, .02), 'ithar': (.34, .12), 'deathless': (.55, .4)}[fac]
    return dict(base=base, dark=dark, trim=trim, gun=gun, lens=tuple(F[3]), eng=tuple(F[4]), rgh=finish[0], met=finish[1])


def setup(hull_objs, cls, fac, seed=1):
    HP.clear(); GUNS.clear(); CTX['L'] = CLS_LEN.get(cls, 10.); CTX['fac'] = fac; CTX['pal'] = palette(fac); CTX['rng'] = random.Random(seed)
    CTX['targets'] = list(hull_objs); rebuild_bvh()


def rebuild_bvh(extra=()):
    CTX['T'] = detail_lib.bvh_of(list(CTX['targets']) + list(extra))


def add_target(o):
    CTX['targets'].append(o)


def R(size):
    return MOUNT_R[size] / CTX['L']


# --------------------------------------------------------------------------------------------------------------------------------------
# placement on the hull
SIDE_RAY = {'top': ((0, 0, 1), (0, 0, -1)), 'below': ((0, 0, -1), (0, 0, 1)), 'port': ((0, 1, 0), (0, -1, 0)), 'stbd': ((0, -1, 0), (0, 1, 0)),
            'bow': ((1, 0, 0), (-1, 0, 0)), 'stern': ((-1, 0, 0), (1, 0, 0))}
MIRROR_SIDE = {'port': 'stbd', 'stbd': 'port', 'top': 'top', 'below': 'below', 'bow': 'bow', 'stern': 'stern'}


def hit(x, y, z, side):
    """first hull hit casting inward from outside on that side; the free coordinate (the one along the ray) is ignored"""
    o_dir, d = SIDE_RAY[side]; o = Vector((x, y, z)); od = Vector(o_dir)
    for i in range(3):
        if od[i] != 0: o[i] = od[i] * 2.0
    h = CTX['T'].ray_cast(o, Vector(d), 4.0)
    if h[0] is None: return None, None
    n = Vector(h[1]).normalized()
    if n.dot(Vector(d)) > .2: print(f'[kit] warning: ray at ({x:.3f}, {y:.3f}, {z:.3f}) from {side} met an inside face (a hole in the hull?)')
    n = n if n.dot(Vector(d)) < 0 else -n
    return Vector(h[0]), n


def seat(p, n, r, ring=12):
    """the hull's height range (along n) under a footprint of radius r around p: (lo, hi), or None where the footprint runs off the hull"""
    t, b, n = detail_lib.frame(n); ds = []; miss = 0
    for k in range(ring + 1):
        a = k * 2 * math.pi / ring; off = (t * math.cos(a) + b * math.sin(a)) * (r if k < ring else 0)
        h = CTX['T'].ray_cast(p + off + n * .08, -n, .2)
        if h[0] is None: miss += 1; continue
        ds.append((Vector(h[0]) - p).dot(n))
    if miss > ring // 4 or not ds: return None
    return min(ds), max(ds)


def lframe(n, aim):
    """t along the aim (projected onto the surface), b = n x t, n out of the hull"""
    n = n.normalized(); t = Vector(aim) - n * Vector(aim).dot(n)
    if t.length < 1e-4: t = Vector((1, 0, 0)) - n * n.x
    if t.length < 1e-4: t = Vector((0, 0, 1)) - n * n.z
    t.normalize(); return t, n.cross(t), n


def M3(t, b, n): return Matrix((t, b, n)).transposed()


def ocyl(name, c, r, h, Mx, seg=20, r2=None, bevel=.0004):
    """cylinder along the local n axis of the frame matrix Mx (columns t, b, n)"""
    return hs_lib.cyl(name, tuple(c), r, h, axis='Z', seg=seg, r2=r2, bevel=bevel, rot=Mx)


def obox(name, c, t, b, n, size, bevel=.0005, rot=0.):
    return detail_lib.obox(name, c, t, b, n, size, bevel=bevel, rot=rot)


def ofrustum(name, c, t, b, n, bot, top, h, shear=(0, 0), bevel=.0005, sides=4):
    """box (or prism with `sides`) with a smaller top, base centred at c in the local frame"""
    bm = bmesh.new(); V = []
    if sides == 4:
        for (hx, hy), z, s in ((bot, 0, (0, 0)), (top, h, shear)):
            for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)): V.append(bm.verts.new((sx * hx + s[0], sy * hy + s[1], z)))
        for f in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)): bm.faces.new([V[i] for i in f])
    else:
        for (hx, hy), z, s in ((bot, 0, (0, 0)), (top, h, shear)):
            for k in range(sides):
                a = k * 2 * math.pi / sides + math.pi / sides; V.append(bm.verts.new((hx * math.cos(a) + s[0], hy * math.sin(a) + s[1], z)))
        bm.faces.new(list(reversed(V[:sides]))); bm.faces.new(V[sides:])
        for k in range(sides): bm.faces.new((V[k], V[(k + 1) % sides], V[sides + (k + 1) % sides], V[sides + k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.transform(bm, matrix=M3(t, b, n).to_4x4(), verts=bm.verts); bmesh.ops.translate(bm, verts=bm.verts, vec=c)
    return hs_lib._obj(name, bm, bevel, seg=1)


SALVAGE_PART = [(.10, .034, .014), (.16, .055, .022), (.20, .21, .22), (.19, .18, .17), (.13, .135, .145), (.30, .08, .025)]


def scol(default):
    """Corsair parts take a salvage colour (rust, stolen grey, bare steel, bone-ish) instead of one clean red; others keep the default"""
    return CTX['rng'].choice(SALVAGE_PART) if CTX['fac'] == 'corsair' else default


def tag(col, emit=0., rgh=None, met=None):
    P = CTX['pal']; dress.tag(col, emit=emit, rgh=P['rgh'] if rgh is None else rgh, met=P['met'] if met is None else met)


def plinth(name, p, n, t, b, r, extra, shape='round', ratio=1.0, col=None):
    """the visible mount: from below the hull's lowest point under the footprint up to `extra` above its highest. Returns the top height
    (along n, from p) or None if the footprint runs off the hull."""
    s = seat(p, n, r * 1.05)
    if s is None: return None
    lo, hi = s; h = (hi - lo) + extra + .0008; c = p + n * (lo - .0008)
    if shape == 'round': ocyl(name, c + n * h / 2, r, h, M3(t, b, n), seg=24, bevel=.0004)
    elif shape == 'hex': ofrustum(name, c, t, b, n, (r, r), (r * .92, r * .92), h, sides=6, bevel=.0003)
    else: ofrustum(name, c, t, b, n, (r, r * ratio), (r * .94, r * ratio * .94), h, bevel=.0004)
    tag(col or scol(mul(CTX['pal']['base'], 1.15) if CTX['fac'] in ('voidsworn', 'deathless') else mul(CTX['pal']['base'], .9)))
    if shape == 'round' and (hi + extra) - lo > r * .5:  # a tall barbette gets a collar under the turret and a band where it leaves the hull
        Mx = M3(t, b, n); top_ = c + n * h
        ocyl(name + 'cl', top_ - n * r * .09, r * 1.08, r * .14, Mx, seg=24, bevel=.0003)
        ocyl(name + 'bd', p + n * (hi + .0008), r * 1.05, r * .08, Mx, seg=24, bevel=.0002)
        tag(mul(CTX['pal']['dark'], 1.8), rgh=.5, met=.6)
    return hi + extra


def _gun_dir(aim, n, elev=.03):
    d = Vector(aim).normalized(); d = (d + n * elev).normalized()
    if d.x < -.05: raise ValueError(f'backward gun refused: aim {tuple(round(v, 2) for v in d)}')
    return d


def add_hp(name, kind, p, fwd, up, **kw):
    HP.append(dict(name=name, kind=kind, p=Vector(p), fwd=Vector(fwd).normalized(), up=Vector(up).normalized(), **kw))


def barrel_set(name, base, d, b_axis, n, count, spacing, L, r, col):
    """parallel barrels from base along d, side by side along b_axis; returns the muzzle centre"""
    Rq = d.to_track_quat('Z', 'Y').to_matrix(); tips = []
    for k in range(count):
        o = base + b_axis * (k - (count - 1) / 2) * spacing
        hs_lib.cyl(f'{name}b{k}', tuple(o + d * L / 2), r, L, axis='Z', seg=12, bevel=0, rot=Rq)
        hs_lib.cyl(f'{name}m{k}', tuple(o + d * (L - r * 1.6)), r * 1.45, r * 3.2, axis='Z', seg=12, bevel=.0002, rot=Rq)  # muzzle collar
        hs_lib.cyl(f'{name}j{k}', tuple(o + d * r * 2), r * 1.6, r * 4, axis='Z', seg=12, bevel=.0002, rot=Rq)  # jacket at the root
        tips.append(o + d * L)
    tag(col, rgh=.42, met=.75)
    return sum(tips, Vector()) / len(tips)


# --------------------------------------------------------------------------------------------------------------------------------------
# guns
def turret(name, p, n, aim, size, barrels=2, slot=None, wkind='turret', arc='T', style=None, bl=1.0, lift=0.0, scale=1.0):
    """a turret on a barbette: plinth ring, housing, barrels. Rests aimed along aim (forward for T and F, out-and-forward for P and S)."""
    P = CTX['pal']; fac = style or CTX['fac']; r = R(size) * scale; t, b, n = lframe(n, aim)
    top = plinth(name + 'p', p, n, t, b, r * 1.12, r * .22 + lift, shape='hex' if fac == 'deathless' else 'round')
    if top is None: return None
    c = p + n * top; base, dark, gun = P['base'], P['dark'], P['gun']
    if fac == 'hegemony':  # low sleek wedge, long thin barrels
        ofrustum(name + 'h', c - t * r * .15, t, b, n, (r * 1.05, r * .82), (r * .55, r * .62), r * .52, shear=(-r * .2, 0)); tag(mul(base, .95))
        obox(name + 'v', c + t * r * .05 + n * r * .40, t, b, n, (r * .5, r * .9, r * .06), bevel=.0002); tag(P['trim'])
        mz = r * .30; bln, brad, sp = r * 2.6 * bl, r * .085, r * .32
    elif fac == 'corsair':  # crude box with a bolted plate, a little off square
        rot = CTX['rng'].uniform(-.08, .08); Rr = Matrix.Rotation(rot, 3, n); tr, br = Rr @ t, Rr @ b
        ofrustum(name + 'h', c - tr * r * .1, tr, br, n, (r * .95, r * .78), (r * .70, r * .66), r * .62, shear=(r * .12, 0)); tag(CTX['rng'].choice((mul(base, 1.1), (.13, .135, .145), (.17, .165, .16))))
        for sd in (1, -1):  # bolted side plates, one a size off (salvage)
            obox(name + f'sp{sd}', c + br * sd * r * .80 + n * r * .30 - tr * r * .1, tr, br, n, (r * (1.3 if sd > 0 else 1.1), r * .07, r * .5), bevel=.0002)
        tag((.20, .17, .14))
        obox(name + 'q', c + n * r * .63 - tr * r * .35, tr, br, n, (r * .55, r * .6, r * .06), bevel=.0002, rot=.2); tag((.10, .034, .014))
        dress.blister(name + 'k', c + n * r * .62 - tr * r * .55 + br * r * .3, n, r * .2, r * .2, r * .12, seg=10, vseg=5); tag((.07, .07, .075), rgh=.5, met=.6)
        mz = r * .30; bln, brad, sp = r * 2.1 * bl, r * .13, r * .42
    elif fac == 'deathless':  # carved hexagonal head with a green slit
        ofrustum(name + 'h', c, t, b, n, (r * .95, r * .95), (r * .62, r * .62), r * .62, sides=6); tag(mul(base, 1.2))
        obox(name + 's', c + t * r * .55 + n * r * .32, t, b, n, (r * .25, r * .9, r * .06), bevel=0); tag(P['lens'], emit=1.0, rgh=.2, met=0)
        mz = r * .30; bln, brad, sp = r * 2.2 * bl, r * .11, r * .36
    elif fac == 'ithar':  # smooth pearl pod with a gold ring, needle emitters
        bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=10, radius=1.0)
        for v in bm.verts: v.co = Vector((v.co.x * r * 1.15, v.co.y * r * .85, max(v.co.z, -.1) * r * .55))
        bmesh.ops.transform(bm, matrix=M3(t, b, n).to_4x4(), verts=bm.verts); bmesh.ops.translate(bm, verts=bm.verts, vec=c); hs_lib._obj(name + 'h', bm, 0); tag(base, rgh=.3, met=.1)
        dress.torus(name + 'g', c + n * .0004, n, r * .98, r * .06, seg=20, ring=6); tag(P['trim'], rgh=.32, met=.6)
        mz = r * .25; bln, brad, sp = r * 2.4 * bl, r * .06, r * .34
    else:  # voidsworn: heavy armoured block with a mantlet and buttresses
        ofrustum(name + 'h', c - t * r * .12, t, b, n, (r * 1.0, r * .88), (r * .78, r * .70), r * .58, shear=(-r * .08, 0)); tag(mul(base, 1.05))
        obox(name + 'mt', c + t * r * .78 + n * r * .30, t, b, n, (r * .22, r * 1.15, r * .44), bevel=.0003); tag(mul(dark, 1.8))
        for s in (1, -1): obox(name + f'bt{s}', c - t * r * .55 + b * s * r * .82 + n * r * .18, t, b, n, (r * .6, r * .16, r * .32), bevel=.0002)
        tag(mul(base, .85))
        mz = r * .30; bln, brad, sp = r * 2.3 * bl, r * .12, r * .40
    d = _gun_dir(aim, n); base_pt = c + n * mz + t * r * .7
    muzzle = barrel_set(name, base_pt, d, b, n, barrels, sp, bln, brad, gun)
    GUNS.append((name, d, arc)); add_hp(name, 'gun', muzzle, d, n, size=size, arc=arc, slot=slot, wkind=wkind, radius=r)
    return muzzle


def casemate(name, p, n, aim, size, barrels=1, slot=None, wkind='battery', arc='P'):
    """broadside gun in an armoured box let into the flank (P or S batteries); barrels out and a little forward"""
    P = CTX['pal']; fac = CTX['fac']; r = R(size); t, b, n = lframe(n, Vector((1, 0, 0)))
    top = plinth(name + 'p', p, n, t, b, r * 1.25, r * .35, shape='box', ratio=.8, col=mul(P['base'], .9 if fac != 'corsair' else 1.2))
    if top is None: return None
    c = p + n * top
    obox(name + 'h', c + n * r * .18, t, b, n, (r * 1.7, r * 1.3, r * .36), bevel=.0004); tag(mul(P['dark'], 1.7))
    d = _gun_dir(aim, n, elev=0); base_pt = c + n * r * .30
    sp_axis = (t - d * t.dot(d)); sp_axis = sp_axis.normalized() if sp_axis.length > 1e-4 else b
    muzzle = barrel_set(name, base_pt, d, sp_axis, n, barrels, r * .45, r * 1.9, r * .12, P['gun'])
    GUNS.append((name, d, arc)); add_hp(name, 'gun', muzzle, d, n, size=size, arc=arc, slot=slot, wkind=wkind, radius=r)
    return muzzle


def spinal(name, p, n, size, slot=None, wkind='lance', arc='F', tubes=0, length=4.0):
    """a forward weapon housing along the centreline (lance, ion, doom, gauss) or a torpedo launcher (tubes = 2 or 4)"""
    P = CTX['pal']; fac = CTX['fac']; r = R(size); t, b, n = lframe(n, Vector((1, 0, 0)))
    top = plinth(name + 'p', p, n, t, b, r * 1.1, r * .2, shape='box', ratio=.75)
    if top is None: return None
    c = p + n * top
    if tubes:
        obox(name + 'h', c + n * r * .45, t, b, n, (r * 2.4, r * 1.6, r * .9), bevel=.0006); tag(scol(mul(P['base'], 1.0)))
        rows = 2 if tubes >= 4 else 1; cols = 2
        for i in range(cols):
            for j in range(rows):
                o = c + n * r * (.45 + (j - (rows - 1) / 2) * .42) + b * (i - .5) * r * .7 + t * r * 1.2
                ocyl(name + f't{i}{j}', o, r * .17, r * .04, M3(b, n, t), seg=14, bevel=0)
        tag((.01, .01, .012), rgh=.9, met=.2)
        muzzle = c + n * r * .45 + t * r * 1.22; d = Vector((1, 0, 0))
    else:
        ofrustum(name + 'h', c - t * r * length * .5, t, b, n, (r * length * .5, r * .7), (r * length * .45, r * .5), r * .7, shear=(r * .2, 0)); tag(mul(P['base'], 1.05))
        for k in range(3): obox(name + f'r{k}', c + n * r * .72 - t * r * (length * .3 - k * r * 0 - k * length * .22), t, b, n, (r * .18, r * .8, r * .1), bevel=.0002)
        tag(P['trim'] if fac in ('hegemony', 'ithar') else mul(P['dark'], 1.8))
        d = Vector((1, 0, 0)); Rq = d.to_track_quat('Z', 'Y').to_matrix()
        hs_lib.cyl(name + 'e', tuple(c + n * r * .38 + t * r * .9), r * .2, r * 1.6, axis='Z', seg=16, bevel=.0002, rot=Rq); tag(P['gun'], rgh=.4, met=.8)
        hs_lib.cyl(name + 'l', tuple(c + n * r * .38 + t * r * 1.72), r * .14, r * .05, axis='Z', seg=16, bevel=0, rot=Rq); tag(P['lens'], emit=1.0, rgh=.2, met=0)
        muzzle = c + n * r * .38 + t * r * 1.75
    GUNS.append((name, d, arc)); add_hp(name, 'gun', muzzle, d, n, size=size, arc=arc, slot=slot, wkind=wkind, radius=r)
    return muzzle


def launcher(name, p, n, aim, size, cols=3, rows=2, slot=None, wkind='torp', arc='T'):
    """missile or rocket box on a pivot plinth, tubes facing aim (forward or out)"""
    P = CTX['pal']; r = R(size); t, b, n = lframe(n, aim)
    top = plinth(name + 'p', p, n, t, b, r * .8, r * .25)
    if top is None: return None
    c = p + n * top; d = _gun_dir(aim, n, elev=.05)
    obox(name + 'h', c + n * r * .55, t, b, n, (r * 1.8, r * (cols * .42 + .2), r * (rows * .42 + .15)), bevel=.0005); tag(scol(mul(P['base'], 1.1)))
    for i in range(cols):
        for j in range(rows):
            o = c + n * r * (.55 + (j - (rows - 1) / 2) * .42) + b * (i - (cols - 1) / 2) * r * .42 + t * r * .91
            ocyl(name + f't{i}{j}', o, r * .15, r * .03, M3(b, n, t), seg=12, bevel=0)
    tag((.012, .012, .014), rgh=.9, met=.2)
    muzzle = c + n * r * .55 + t * r * .92
    GUNS.append((name, d, arc)); add_hp(name, 'gun', muzzle, d, n, size=size, arc=arc, slot=slot, wkind=wkind, radius=r)
    return muzzle


def emitter(name, p, n, size, slot=None, wkind='bio', arc='F', aim=(1, 0, 0), scale=1.0):
    """Chorus: no bolted guns. A grown weapon: a ringed muscular sphincter with a glowing throat (bioplasma, spores, tendrils)"""
    P = CTX['pal']; r = R(size) * scale; t, b, n = lframe(n, aim); s = seat(p, n, r)
    if s is None: return None
    c = p + n * (s[1] - .0004)
    dress.blister(name + 'b', c - n * r * .2, n, r * 1.1, r * .95, r * .55, seg=16, vseg=8); tag(mul(P['base'], 1.15), rgh=.42, met=.02)
    dress.torus(name + 'r', c + n * r * .28, n, r * .55, r * .18, seg=16, ring=8); tag(mul(P['base'], .8), rgh=.45, met=.02)
    dress.blister(name + 'g', c + n * r * .18, n, r * .42, r * .42, r * .16, seg=12, vseg=6); tag(P['lens'], emit=1.0, rgh=.2, met=0)
    d = (Vector(aim).normalized() * .6 + n * .4).normalized()
    if d.x < -.05: d = n
    GUNS.append((name, d, arc)); add_hp(name, 'gun', c + n * r * .35, d, n, size=size, arc=arc, slot=slot, wkind=wkind, radius=r)
    return c


# --------------------------------------------------------------------------------------------------------------------------------------
# engines and the rest
def engine(name, p, r, L=None, axis=Vector((-1, 0, 0)), style=None, n_hint=None):
    """main engine bell: collar sunk into the hull at p, bell flaring aft along axis, glowing throat. hp_eng at the exit."""
    P = CTX['pal']; fac = style or CTX['fac']; d = axis.normalized(); L = L or r * 1.3
    up = Vector((0, 0, 1)); up = (up - d * up.dot(d)).normalized(); side = d.cross(up); Mx = M3(side, up, d)
    col = P['gun'] if fac != 'ithar' else mul(P['base'], .9)
    ocyl(name + 'c', p + d * L * .12, r * .82, L * .5, Mx, seg=28, bevel=.0004); tag(mul(P['dark'], 1.7))  # collar, half inside the hull
    ocyl(name + 'b', p + d * L * .62, r * .80, L * .76, Mx, seg=32, r2=r, bevel=.0003); tag(col, rgh=.45, met=.8)  # bell
    for k in range(3): ocyl(name + f'r{k}', p + d * L * (.35 + k * .22), r * (.84 + k * .05), L * .05, Mx, seg=32, bevel=0)
    tag(mul(P['dark'], 2.2), rgh=.5, met=.7)
    ocyl(name + 'g', p + d * (L - .0006), r * .88, .0016, Mx, seg=28, bevel=0); tag(P['eng'], emit=1.0, rgh=.2, met=0)  # glowing throat across the bell mouth
    exitp = p + d * L
    add_hp(f'eng{len([h for h in HP if h["kind"] == "engine"])}', 'engine', exitp, d, up, radius=r, size='-', arc='-', slot=None, wkind='engine')
    return exitp


def engine_at(name, p, n, r, L=None, axis=(-1, 0, 0), sink=.004):
    """engine placed by a ray from the stern (kit.place): the collar starts a little inside the surface it hit"""
    d = Vector(axis).normalized()
    return engine(name, p - d * sink, r, L, axis=d)


def orifice(name, p, n, r, axis=(-1, 0, 0)):
    """Chorus propulsion: a muscular ring vent grown from the body with a glowing throat (no metal bells on a living ship). hp_eng at the
    throat, pointing out along the vent (aft by default)"""
    P = CTX['pal']; d = Vector(axis).normalized()
    dress.blister(name + 'b', p - n * r * .25, n, r * 1.25, r * 1.25, r * .7, seg=18, vseg=8); tag(mul(P['base'], 1.1), rgh=.42, met=.02)
    dress.torus(name + 'r', p + n * r * .35, n, r * .62, r * .2, seg=18, ring=8); tag(mul(P['base'], .75), rgh=.45, met=.02)
    dress.blister(name + 'g', p + n * r * .3, n, r * .48, r * .48, r * .12, seg=14, vseg=6); tag(P['eng'], emit=1.0, rgh=.2, met=0)
    up = Vector((0, 0, 1)); up = (up - d * up.dot(d)).normalized() if abs(d.z) < .9 else Vector((1, 0, 0))
    add_hp(f'eng{len([h for h in HP if h["kind"] == "engine"])}', 'engine', p + n * r * .4, d, up, radius=r * .55, size='-', arc='-', slot=None, wkind='engine')
    return p


def _grow(p, n, length, bend, rng, steps=10, droop=Vector((0, 0, 0))):
    """points of a gently curving growth from p along n (organic parts): bends one way, a little droop"""
    side = n.cross(Vector((0, 0, 1)) if abs(n.z) < .9 else Vector((1, 0, 0))).normalized(); a = rng.uniform(0, 2 * math.pi)
    sv = (side * math.cos(a) + n.cross(side) * math.sin(a)).normalized(); pts = []; d = n.copy(); q = p.copy()
    for k in range(steps + 1):
        pts.append((q.copy(), sv)); d = (d + sv * bend / steps + droop / steps).normalized(); q = q + d * length / steps
    return pts


def brood(name, p, n, r, launch=None):
    """Chorus carrier bay: a swollen brood sac with a glowing birth slit; hp_bay at the slit"""
    P = CTX['pal']; t, b, n = lframe(n, Vector((1, 0, 0)) if abs(n.x) < .9 else Vector((0, 0, 1)))
    dress.blister(name + 's', p - n * r * .3, n, r * 1.5, r * 1.1, r * .9, seg=18, vseg=8); tag(mul(P['base'], 1.2), rgh=.4, met=.02)
    obox(name + 'l', p + n * r * .55, t, b, n, (r * 1.6, r * .22, r * .3), bevel=.0003); tag(P['lens'], emit=1.0, rgh=.2, met=0)
    d = Vector(launch).normalized() if launch else (n + Vector((.5, 0, 0))).normalized()
    add_hp(f'bay{len([h for h in HP if h["kind"] == "bay"])}', 'bay', p + n * r * .65, d, n, size='-', arc='-', slot=None, wkind='bay', radius=r)
    return p


def tendril(name, p, n, length, r, bend=.9):
    """Chorus: a crisp grown tendril (the AI melts them into lumpy worms): a tapered curving tube rooted a little into the body"""
    P = CTX['pal']; rng = CTX['rng']; pts = _grow(p - n * r, n, length, bend, rng)
    if dress.tube_path(name, pts, r, r * .18, 0, seg=10): tag(mul(P['base'], rng.uniform(.9, 1.25)), rgh=.42, met=.02)
    dress.torus(name + 'b', p - n * r * .2, n, r * 1.3, r * .45, seg=12, ring=6); tag(mul(P['base'], .8), rgh=.45, met=.02)
    return p


def horn(name, p, n, length, r, bend=.25):
    """Chorus and Deathless: a crisp bone spike (stalactites, crown spikes), tapered to a point, rooted in a fleshy collar"""
    P = CTX['pal']; rng = CTX['rng']; pts = _grow(p - n * r * 1.2, n, length, bend, rng, steps=8)
    bone = (.55, .48, .36) if CTX['fac'] == 'chorus' else mul(P['trim'], 1.0)
    if dress.tube_path(name, pts, r, r * .05, 0, seg=10): tag(bone, rgh=.55, met=.03)
    dress.blister(name + 'c', p - n * r * .3, n, r * 1.6, r * 1.6, r * .7, seg=12, vseg=6); tag(mul(P['base'], .85), rgh=.45, met=.02)
    return p


def thruster_pod(name, p, n, r):
    """small manoeuvring thruster on the hull (bellies, flanks): a block with a short nozzle pointing aft"""
    P = CTX['pal']; t, b, n = lframe(n, Vector((1, 0, 0)))
    top = plinth(name + 'p', p, n, t, b, r * 1.1, r * .3, shape='box', ratio=.8)
    if top is None: return None
    c = p + n * (top - r * .1); obox(name + 'h', c + n * r * .35, t, b, n, (r * 2.2, r * 1.5, r * .8), bevel=.0004); tag(mul(P['base'], .95))
    Mx = M3(b, n, -t); ocyl(name + 'z', c + n * r * .35 - t * r * 1.25, r * .45, r * .5, Mx, seg=16, r2=r * .6, bevel=0); tag(P['gun'], rgh=.45, met=.8)
    return c


def radiators(name, p, n, length, height, n_fins=2, splay=18):
    """heat radiator fins (what replaces funnels and crossbar masts): a root spine and thin ribbed panels in a shallow V"""
    P = CTX['pal']; t, b, n = lframe(n, Vector((1, 0, 0)))
    top = plinth(name + 'p', p, n, t, b, max(height * .12, .004), height * .04, shape='box', ratio=.6)
    if top is None: return None
    c = p + n * top; obox(name + 's', c + n * height * .04, t, b, n, (length, height * .16, height * .08), bevel=.0003); tag(mul(P['dark'], 1.8))
    for side in (1, -1):
        Rr = Matrix.Rotation(math.radians(side * splay), 3, t)
        nn = Rr @ n; bb = Rr @ b
        for k in range(n_fins):
            cc = c + t * (k - (n_fins - 1) / 2) * (length / n_fins) + nn * (height * .55) + b * side * height * .05
            obox(name + f'f{side}{k}', cc, t, bb, nn, (length / n_fins * .92, height * .03, height), bevel=.0002)
            for j in range(5): obox(name + f'q{side}{k}{j}', cc + nn * height * (-.4 + j * .2) + bb * side * height * .02, t, bb, nn, (length / n_fins * .86, height * .03, height * .03), bevel=0)
    tag((.17, .165, .16) if CTX['fac'] == 'corsair' else mul(P['dark'], 2.4), rgh=.4, met=.6)
    return c


def antenna(name, p, n, h, dishes=2):
    """sensor array: squat square tower (no yards, no crossbars), sensor head, dishes and whip antennas of uneven height"""
    P = CTX['pal']; t, b, n = lframe(n, Vector((1, 0, 0))); w = h * .2
    top = plinth(name + 'p', p, n, t, b, w * 1.2, h * .05, shape='box', ratio=1.0)
    if top is None: return None
    c = p + n * top; obox(name + 't', c + n * h * .30, t, b, n, (w * .55, w * .55, h * .6), bevel=.0002); tag(mul(P['dark'], 1.8))
    obox(name + 'h', c + n * h * .62, t, b, n, (w * 1.1, w * .9, h * .14), bevel=.0003); tag(mul(P['base'], 1.1))
    for k in range(dishes):
        s = 1 if k % 2 == 0 else -1; z = h * (.42 - k * .12); rr = w * (.75 - k * .12)
        Rr = Matrix.Rotation(math.radians(s * 60), 3, t) @ M3(t, b, n)
        hs_lib.cyl(name + f'd{k}', tuple(c + n * z + b * s * w * 1.1), rr, rr * .25, axis='Z', seg=20, r2=rr * .4, bevel=.0002, rot=Rr)
        obox(name + f'ds{k}', c + n * z + b * s * w * .55, t, b, n, (w * .12, w * .9, w * .12), bevel=0)
    tag(mul(P['base'], 1.2))
    for k, (dt, db, hh) in enumerate(((.25, .2, 1.0), (-.25, -.15, .75), (.1, -.3, .55))):
        ocyl(name + f'w{k}', c + n * (h * .69 + h * hh * .2) + t * w * dt + b * w * db, max(w * .045, .0006), h * hh * .4, M3(t, b, n), seg=6, bevel=0)
    tag(P['gun'], rgh=.4, met=.7)
    ocyl(name + 'bc', c + n * (h * .69 + h * .4) + t * w * .25 + b * w * .2, max(w * .08, .0009), w * .1, M3(t, b, n), seg=8, bevel=0); tag(P['lens'], emit=1.0, rgh=.2, met=0)
    return c


def sensor_dome(name, p, n, r):
    P = CTX['pal']; t, b, n = lframe(n, Vector((1, 0, 0)))
    top = plinth(name + 'p', p, n, t, b, r * 1.15, r * .12)
    if top is None: return None
    c = p + n * top; dress.blister(name + 'd', c, n, r, r, r * .8, seg=18, vseg=8); tag(mul(P['base'], 1.15), rgh=.25, met=.2)
    return c


def bridge(name, p, n, length, width, height, tiers=2):
    """command tower: stacked tiers with a forward visor slit (one continuous lit band, not rows of portholes) and a roof sensor"""
    P = CTX['pal']; fac = CTX['fac']; t, b, n = lframe(n, Vector((1, 0, 0)))
    top = plinth(name + 'p', p, n, t, b, max(length, width) * .5, height * .05, shape='box', ratio=width / max(length, 1e-6))
    if top is None: return None
    c = p + n * top; z = 0; L, W = length, width
    for k in range(tiers):
        h = height / tiers; sh = (L * .12, 0)
        ofrustum(name + f'k{k}', c + n * z, t, b, n, (L / 2, W / 2), (L / 2 * .82, W / 2 * .86), h, shear=sh); tag(mul(P['base'], 1.0 + .06 * k))
        obox(name + f'v{k}', c + n * (z + h * .62) + t * (L / 2 * .9 + sh[0] * .55), t, b, n, (L * .04, W * .8, h * .14), bevel=0); tag(P['lens'], emit=1.0, rgh=.2, met=0)
        z += h; L *= .72; W *= .78
    obox(name + 'r', c + n * (z + height * .03), t, b, n, (L * .9, W * .9, height * .06), bevel=.0003); tag(mul(P['dark'], 1.8))
    sensor_dome(name + 's', c + n * (z + height * .06), n, min(L, W) * .28)
    return c + n * z


def tank(name, p, n, r, length, straps=3):
    """strapped fuel drum lying fore and aft on two saddles (Corsair junk, tankers)"""
    P = CTX['pal']; t, b, n = lframe(n, Vector((1, 0, 0)))
    sad = []
    for s in (-.3, .3):
        q = p + t * length * s; top = plinth(name + f's{s}', q, n, t, b, r * .7, r * .35, shape='box', ratio=1.3)
        if top is None: return None
        sad.append(top)
    c = p + n * (max(sad) + r * .9); Mx = M3(b, n, t)
    ocyl(name + 'd', c, r, length, Mx, seg=24, bevel=.0005); tag(CTX['rng'].choice(((.13, .135, .145), (.17, .165, .16), (.50, .45, .35), mul(P['base'], 1.2))))
    for k in range(straps): ocyl(name + f'k{k}', c + t * length * (k - (straps - 1) / 2) / (straps + .5), r * 1.04, length * .04, Mx, seg=24, bevel=0)
    tag((.10, .034, .014))
    return c


def bay(name, p, n, width, height, launch=None):
    """hangar mouth: armoured frame, dark recess, a lit threshold strip. hp_bay at its centre, launch direction outward (or given)"""
    P = CTX['pal']; t, b, n = lframe(n, Vector((1, 0, 0)) if abs(n.x) < .9 else Vector((0, 0, 1)))
    top = plinth(name + 'p', p, n, t, b, max(width, height) * .62, .0015, shape='box', ratio=height / max(width, 1e-6))
    if top is None: return None
    c = p + n * top
    obox(name + 'k', c, t, b, n, (width, height, .0012), bevel=0); tag((.012, .012, .014), rgh=.9, met=.1)
    for s in (1, -1):
        obox(name + f'fa{s}', c + t * s * width * .53, t, b, n, (width * .08, height * 1.1, .0035), bevel=.0003)
        obox(name + f'fb{s}', c + b * s * height * .53, t, b, n, (width * 1.1, height * .08, .0035), bevel=.0003)
    tag(mul(P['base'], .9))
    obox(name + 'l', c - b * height * .40 + n * .0008, t, b, n, (width * .9, height * .04, .0006), bevel=0); tag(P['lens'], emit=1.0, rgh=.2, met=0)
    d = Vector(launch).normalized() if launch else (n + Vector((.6, 0, 0))).normalized()
    add_hp(f'bay{len([h for h in HP if h["kind"] == "bay"])}', 'bay', c + n * .002, d, n, size='-', arc='-', slot=None, wkind='bay', radius=max(width, height) / 2)
    return c


def cover(name, lo, hi, pad=.0025, raise_=.0015, col=None):
    """deck block over a cut hole (rim bounds lo/hi from the cut): from below the rim's lowest point to just above its highest, so it
    sits on the hull and hides the hole; its top becomes a seat for the rebuilt part"""
    lo = Vector(lo) - Vector((pad, pad, pad * 2)); hi = Vector(hi) + Vector((pad, pad, raise_))
    c = (lo + hi) / 2; s = hi - lo
    o = hs_lib.box(name, tuple(c), tuple(s), bevel=.0008); tag(col or mul(CTX['pal']['base'], .95))
    return o


def sail(name, root, u, v, a0, a1, R, ribs=9, billow=.06, th=.0016, hub=None, rim_glow=1.0):
    """Ithar fan sail (the faction's signature; the AI meshes it as a thick lumpy volume, R27): a thin membrane spread between gold ribs
    that radiate from a hub on the hull, a lit jade rim. u, v span the sail's plane (unit, perpendicular); the fan opens from angle a0 to a1
    (radians, measured from u toward v), radius R. The membrane billows a little along the plane's normal. Built as real thin geometry so
    it reads crisp from any side; the hub is a ring plinth on the hull."""
    P = CTX['pal']; u = Vector(u).normalized(); v = Vector(v).normalized(); w = u.cross(v).normalized(); root = Vector(root)
    nr, na = 7, max(8, ribs * 3)
    bm = bmesh.new(); grid = []
    for i in range(nr + 1):
        r = .06 + .94 * i / nr; row = []
        for j in range(na + 1):
            t = j / na; a = a0 + (a1 - a0) * t
            rad = R * r * (1 - .10 * math.sin(math.pi * t) ** 6)  # the rim scallops in a little between the outer ribs
            bil = billow * R * math.sin(math.pi * r) * math.sin(math.pi * t)
            row.append(bm.verts.new(root + (u * math.cos(a) + v * math.sin(a)) * rad + w * bil))
        grid.append(row)
    for i in range(nr):
        for j in range(na): bm.faces.new((grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = hs_lib._obj(name + 'm', bm, 0)
    sm = o.modifiers.new('sd', 'SOLIDIFY'); sm.thickness = th; sm.offset = 0; sm.use_rim = True
    tag(mul(P['base'], 1.02), emit=.06, rgh=.35, met=.05)  # pearl membrane, a breath of glow so it reads against space
    for k in range(ribs):
        t = k / (ribs - 1); a = a0 + (a1 - a0) * t; pts = []
        for i in range(nr + 1):
            r = .02 + .98 * i / nr; rad = R * r * (1 - .10 * math.sin(math.pi * t) ** 6); bil = billow * R * math.sin(math.pi * r) * math.sin(math.pi * t)
            q = root + (u * math.cos(a) + v * math.sin(a)) * rad + w * bil; pts.append((q, w))
        dress.tube_path(name + f'r{k}', pts, max(th * 1.6, .0016) * (1.8 if k in (0, ribs - 1) else 1.0), th * .9, 0, seg=6)
    tag(P['trim'], rgh=.32, met=.6)
    rim = [(grid[nr][j].co.copy(), w) for j in range(na + 1)]
    dress.tube_path(name + 'e', rim, th * .9, th * .9, 0, seg=6); tag(P['lens'], emit=rim_glow, rgh=.2, met=0)
    if hub is not None:
        hp, hn = hub; dress.torus(name + 'h', hp, hn, R * .07, R * .02, seg=16, ring=6); tag(P['trim'], rgh=.32, met=.6)
    return o


# --------------------------------------------------------------------------------------------------------------------------------------
def mirror_spec(x, y, z, side):
    return x, -y, z, MIRROR_SIDE[side]


def place(fn, name, x, y, z, side, *a, pair=False, aim=None, **kw):
    """cast onto the hull at (x, y, z) from `side`, then build fn there; pair=True also builds the mirror (y -> -y, port <-> stbd) with
    the aim mirrored too. Returns the list of results (None where the footprint missed)."""
    out = []; specs = [(x, y, z, side, aim, '')]
    if pair: mx, my, mz, ms = mirror_spec(x, y, z, side); specs.append((mx, my, mz, ms, None if aim is None else (aim[0], -aim[1], aim[2]), 'm'))
    for (xx, yy, zz, sd, am, suf) in specs:
        p, n = hit(xx, yy, zz, sd)
        if p is None: out.append(None); continue
        k2 = dict(kw)
        if k2.pop('align', 'axis') == 'axis': n = -Vector(SIDE_RAY[sd][1])  # stand square to the placement side; the plinth takes up the surface
        if suf and k2.get('arc') in ('P', 'S'): k2['arc'] = {'P': 'S', 'S': 'P'}[k2['arc']]  # the mirror of a port battery is a starboard one
        if suf and 'slot_m' in k2: k2['slot'] = k2['slot_m']
        k2.pop('slot_m', None)
        if suf and 'aim' in k2 and k2['aim'] is not None: k2['aim'] = (k2['aim'][0], -k2['aim'][1], k2['aim'][2])
        if am is None: out.append(fn(name + suf, p, n, *a, **k2))
        else: out.append(fn(name + suf, p, n, am, *a, **k2))
    return out


def breach_anchors(Hd, count, min_sep=None, seed=3):
    """breach anchor candidates spread over open hull (not under parts): farthest-point sampling over the hull samples with good AO and
    flat curvature, on the flanks and top"""
    rng = np.random.default_rng(seed); ok = np.nonzero((Hd.ao > .55) & (np.abs(Hd.cv) < .08) & (Hd.sn[:, 2] > -.4))[0]
    if len(ok) < count: ok = np.arange(len(Hd.sp))
    pick = [int(rng.choice(ok))]; d = np.linalg.norm(Hd.sp[ok] - Hd.sp[pick[0]], axis=1)
    PT = detail_lib.bvh_of(hs_lib.PARTS) if hs_lib.PARTS else None
    while len(pick) < count * 3 and len(pick) < len(ok):
        i = int(ok[int(np.argmax(d))]); pick.append(i); d = np.minimum(d, np.linalg.norm(Hd.sp[ok] - Hd.sp[i], axis=1))
    made = 0
    for i in pick:
        p = Vector(Hd.sp[i].tolist()); n = Vector(Hd.sn[i].tolist())
        if PT is not None and PT.find_nearest(p, .012)[0] is not None: continue  # under or next to a part
        add_hp(f'breach{made}', 'breach', p, Vector((1, 0, 0)) - n * n.x if abs(n.x) < .95 else Vector((0, 0, 1)), n, size='-', arc='-', slot=None, wkind='breach', radius=0)
        made += 1
        if made >= count: break
    return made
