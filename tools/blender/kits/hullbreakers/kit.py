# The Ashfall Hullbreakers parts kit (issue 209 round 6; Ryan, Nov 9 14:52 CST, R151).
# Shape language: scavenged and rebuilt. Heavy, squat, over-armoured guns made from salvage: octagonal armour plates bolted on in
# frames, quilted (padded and strapped) mantlet sleeves, copper barrels with fat recoil sleeves, missile drums wrapped in strapping
# with faded ochre bands, welded pipe cradles, patch plates and weld beads everywhere. Matched pairs keep the same placement and size;
# their detail does not match (different patches, welds, a borrowed part here and there), because nothing on a Hullbreaker ship
# came out of one factory. Some parts are borrowed from other factions and welded on (variant 'borrowed': a clean faceted
# Hegemony-style turret on a crude adapter ring).
# Every part is crisp hard-surface geometry (flat facets, small bevels, no noise or displacement), seated on the real hull through
# the shared sockets (kits/shared/plumbing.py), aimed by the owner's rules (forward or out, never backward, never into the ship).
# Sizes come from the concept, measured through its fitted camera (docs/shots/ship_pipeline/route209/round6/README.md).
import os, sys, math, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.normpath(os.path.join(HERE, '..', 'shared')))
import plumbing as PB
import bpy, bmesh
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import box, cyl, loft

FACTION = 'hullbreakers'

# ---------------------------------------------------------------------------------------------------------------- primitives of this kit
def _basis(n, up=(0, 0, 1)):
    """outward normal n; u along the surface (horizontal), v up the surface"""
    n = Vector(n).normalized(); u = Vector(up).cross(n)
    if u.length < 1e-4: u = Vector((1, 0, 0)).cross(n)
    u.normalize(); v = n.cross(u).normalized(); return n, u, v

def _poly_prism(name, c, n, outline, d0, d1, bevel=.0012):
    """a flat prism: outline points (a, b) in the (u, v) plane, from depth d0 to d1 along n"""
    n, u, v = _basis(n); c = Vector(c); bm = bmesh.new()
    rings = [[bm.verts.new(c + u * a + v * b + n * d) for a, b in outline] for d in (d0, d1)]
    k = len(outline); bm.faces.new(rings[0][::-1]); bm.faces.new(rings[1])
    for i in range(k): bm.faces.new((rings[0][i], rings[0][(i + 1) % k], rings[1][(i + 1) % k], rings[1][i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return hs_lib._obj(name, bm, bevel)

def _octagon(w, h, ch):
    return [(-w / 2 + ch, h / 2), (w / 2 - ch, h / 2), (w / 2, h / 2 - ch), (w / 2, -h / 2 + ch), (w / 2 - ch, -h / 2), (-w / 2 + ch, -h / 2),
            (-w / 2, -h / 2 + ch), (-w / 2, h / 2 - ch)]

def _ring_prism(name, c, n, outer, inner, d0, d1, bevel=.0008):
    """a flat frame between two outlines with the same point count"""
    n, u, v = _basis(n); c = Vector(c); bm = bmesh.new(); k = len(outer)
    O = [[bm.verts.new(c + u * a + v * b + n * d) for a, b in outer] for d in (d0, d1)]
    I = [[bm.verts.new(c + u * a + v * b + n * d) for a, b in inner] for d in (d0, d1)]
    for i in range(k):
        j = (i + 1) % k
        bm.faces.new((O[1][i], O[1][j], I[1][j], I[1][i])); bm.faces.new((O[0][j], O[0][i], I[0][i], I[0][j]))
        bm.faces.new((O[0][i], O[0][j], O[1][j], O[1][i])); bm.faces.new((I[0][j], I[0][i], I[1][i], I[1][j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return hs_lib._obj(name, bm, bevel)

def sphere(name, c, r, seg=20, squash=1.0):
    bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=max(6, seg // 2), radius=r)
    for vv in bm.verts: vv.co.z *= squash
    bmesh.ops.translate(bm, verts=bm.verts, vec=Vector(c)); return hs_lib._obj(name, bm, 0)

def tube(name, a, b, r, seg=8):
    a, b = Vector(a), Vector(b); d = b - a
    if d.length < 1e-5: return None
    return cyl(name, (a + b) / 2, r, d.length, axis='X', seg=seg, rot=PB.frame(d), bevel=0)

def weld(name, pts, r=.0016, rnd=None):
    """a salvage weld bead along a polyline: squashed beads every 1.5 r, a little irregular"""
    rnd = rnd or random.Random(len(name)); k = 0
    for a, b in zip(pts, pts[1:]):
        a, b = Vector(a), Vector(b); n = max(1, int((b - a).length / (r * 1.5)))
        for i in range(n):
            p = a.lerp(b, (i + .5) / n); rr = r * rnd.uniform(.8, 1.15)
            cyl(f'{name}{k}', p, rr, rr * 1.1, axis='X', seg=6, rot=PB.frame(b - a), bevel=0); k += 1

def patch(name, c, n, w, h, th=.0018, ang=0.0, rivets=True, rnd=None):
    """a salvage patch plate, a little crooked, riveted at the corners"""
    n_, u, v = _basis(n); R = Matrix.Rotation(ang, 3, n_); u, v = R @ u, R @ v; c = Vector(c)
    bm = bmesh.new(); pts = [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]
    rings = [[bm.verts.new(c + u * a + v * b + n_ * d) for a, b in pts] for d in (-.0005, th)]
    bm.faces.new(rings[0][::-1]); bm.faces.new(rings[1])
    for i in range(4): bm.faces.new((rings[0][i], rings[0][(i + 1) % 4], rings[1][(i + 1) % 4], rings[1][i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); hs_lib._obj(name, bm, .0005)
    if rivets:
        e = min(w, h) * .18
        for k, (a, b) in enumerate(((-1, -1), (1, -1), (1, 1), (-1, 1))):
            p = c + u * (a * (w / 2 - e)) + v * (b * (h / 2 - e)) + n_ * th
            cyl(f'{name}rv{k}', p, .0011, .0012, axis='X', seg=6, rot=PB.frame(n_), bevel=0)

def quilted(name, base, aim, L, r0, r1, rings=5, straps=12, seg=28):
    """the concept's padded mantlet sleeve: a tapered sleeve from r0 to r1 along aim, strapped with rings and lengthwise straps"""
    R = PB.frame(aim); a = Vector(aim).normalized(); base = Vector(base)
    cyl(name, base + a * L / 2, r0, L, axis='X', seg=seg, r2=r1, rot=R, bevel=.0008)
    for k in range(rings):
        f = (k + .5) / rings; rr = r0 + (r1 - r0) * f
        cyl(f'{name}rg{k}', base + a * L * f, rr * 1.035, .0016, axis='X', seg=seg, rot=R, bevel=0)
    for k in range(straps):
        t = 2 * math.pi * k / straps; off = R @ Vector((0, math.cos(t), math.sin(t)))
        tube(f'{name}st{k}', base + a * .001 + off * r0 * 1.02, base + a * (L - .001) + off * r1 * 1.02, .0011, seg=5)

# ---------------------------------------------------------------------------------------------------------------- weapons
def casemate(s, seat, rnd):
    """bow casemate: an octagonal armour housing bolted onto the flank (framed, recessed field, corner braces, patch plates), a dark
    collar disc with a bolt ring, a copper ball and mantlet ring, the quilted sleeve, a front cap and twin long copper barrels with
    recoil sleeves and muzzle rings. s.pos: the hull surface point at the plate centre; s.size: plate width; s.aim: barrel aim;
    extra proud: the housing's stand-off from the hull."""
    W = s.size; Hh = W * s.extra.get('h', .97); ch = W * .23; n = s.normal; c = s.pos
    nn, u, v = _basis(n)
    dp = s.extra.get('proud', .010) - .010      # round 7: how far the housing stands off the hull (0.010 on a curved flank; less on a slab side)
    i0 = PB.mark()
    _poly_prism(f'{s.name}house', c, n, _octagon(W, Hh, ch), -s.extra.get('bury', .035), .010 + dp)   # buried in the hull behind
    _ring_prism(f'{s.name}frame', c, n, _octagon(W, Hh, ch), _octagon(W * .84, Hh * .84, ch * .8), .010 + dp, .0155 + dp)
    for k, (a, b) in enumerate(((-1, -1), (1, -1), (1, 1), (-1, 1))):       # corner braces from the frame toward the collar
        p0 = c + u * (a * W * .36) + v * (b * Hh * .36) + nn * (.011 + dp); p1 = c + u * (a * W * .24) + v * (b * Hh * .24) + nn * (.017 + dp)
        tube(f'{s.name}brace{k}', p0, p1, .0014, seg=6)
        cyl(f'{s.name}bfoot{k}', p0, .0026, .003, axis='X', seg=8, rot=PB.frame(nn), bevel=0)
    for k in range(10):                                                        # frame bolts
        t = 2 * math.pi * (k + .5) / 10; p = c + u * (math.cos(t) * W * .46) + v * (math.sin(t) * Hh * .46) + nn * (.0158 + dp)
        cyl(f'{s.name}fb{k}', p, .0016, .0015, axis='X', seg=6, rot=PB.frame(nn), bevel=0)
    # salvage: one or two crooked patch plates on the field, a weld bead along the housing's top edge (different per casemate)
    for k in range(1 + s.variant % 2):
        a, b = rnd.uniform(-.28, .28) * W, rnd.choice((-1, 1)) * rnd.uniform(.25, .32) * Hh
        patch(f'{s.name}patch{k}', c + u * a + v * b + nn * (.010 + dp), nn, W * rnd.uniform(.16, .24), Hh * rnd.uniform(.10, .15), ang=rnd.uniform(-.12, .12))
    top = [c + u * (x * W) + v * (Hh / 2 + .0008) + nn * (.002 + dp) for x in (-.26, -.05, .12, .26)]
    weld(f'{s.name}weldtop', top[:2 + s.variant % 3], rnd=rnd)
    PB.tag(i0, 'part', 'casemate_plate')
    i1 = PB.mark()
    cyl(f'{s.name}collar', c + nn * (.019 + dp), W * .31, .006, axis='X', seg=40, rot=PB.frame(nn), bevel=.0008)
    for k in range(14):
        t = 2 * math.pi * k / 14; p = c + u * (math.cos(t) * W * .28) + v * (math.sin(t) * W * .28) + nn * (.0225 + dp)
        cyl(f'{s.name}cb{k}', p, .0013, .0016, axis='X', seg=6, rot=PB.frame(nn), bevel=0)
    PB.tag(i1, 'part', 'gun_dark')
    i2 = PB.mark(); a = s.aim; base = c + nn * (.021 + dp)
    sphere(f'{s.name}ball', base + a * .002, W * .235, seg=24, squash=1.0)
    cyl(f'{s.name}mant', base + a * (W * .17), W * .245, W * .10, axis='X', seg=32, rot=PB.frame(a), bevel=.0008)
    PB.tag(i2, 'part', 'copper_dark')
    i3 = PB.mark(); L = W * .46; sb = base + a * (W * .21)
    quilted(f'{s.name}slv', sb, a, L, W * .25, W * .195, rings=5, straps=14)
    cyl(f'{s.name}cap', sb + a * (L + .002), W * .175, .004, axis='X', seg=28, rot=PB.frame(a), bevel=.0006)
    PB.tag(i3, 'part', 'gun')
    i4 = PB.mark(); R = PB.frame(a); side = (R @ Vector((0, 1, 0))).normalized()
    for k in (-1, 1):
        b0 = sb + a * (L + .004) + side * (k * W * .085) + Vector((0, 0, -W * .01))
        Lb = W * s.extra.get('barrel', .55)
        cyl(f'{s.name}rec{k}', b0 + a * (Lb * .17), W * .062, Lb * .34, axis='X', seg=20, rot=R, bevel=.0006)      # recoil sleeve
        cyl(f'{s.name}rec{k}c', b0 + a * (Lb * .34), W * .068, Lb * .035, axis='X', seg=20, rot=R, bevel=0)       # its clamp ring
        cyl(f'{s.name}brl{k}', b0 + a * (Lb * .55), W * .043, Lb * .9, axis='X', seg=20, rot=R, bevel=.0004)
        cyl(f'{s.name}mz{k}', b0 + a * (Lb * .98), W * .056, Lb * .07, axis='X', seg=20, rot=R, bevel=.0004)       # muzzle ring
        PB.register_gun(f'{s.name}brl{k}', a, nn, tip=b0 + a * (Lb * 1.016), socket=s.name, radius=W * .043)
    PB.tag(i4, 'part', 'copper')
    i5 = PB.mark()
    for k in (-1, 1):
        b0 = sb + a * (L + .004) + side * (k * W * .085) + Vector((0, 0, -W * .01)); Lb = W * s.extra.get('barrel', .55)
        cyl(f'{s.name}bore{k}', b0 + a * (Lb * 1.016), W * .03, .0012, axis='X', seg=12, rot=R, bevel=0)
    PB.tag(i5, 'dark')

def bow_battery(s, seat, rnd):
    """the twin bow guns on the raised forward deck: heavy breech blocks under a slatted armour hood, fat recoil sleeves, long
    barrels with ribbed muzzle shrouds and a glowing bore (the concept's orange muzzles), welded braces to the deck.
    extra hooded: 1 when the hull has its own hood over the breeches (round 7): only the barrels, shrouds, bores and braces are built"""
    c = s.pos; a = s.aim; R = PB.frame(a); gap = s.extra.get('gap', .030); Lb = s.extra.get('barrel', .090); r = s.size
    hooded = bool(s.extra.get('hooded'))
    i0 = PB.mark()
    for k in (-1, 1):
        y = k * gap; b0 = c + Vector((0, y, 0))
        if not hooded:
            box(f'{s.name}breech{k}', b0 + Vector((-.012, 0, -.002)), (.036, r * 3.0, r * 2.6), bevel=.0012)
            cyl(f'{s.name}rec{k}', b0 + a * .014, r * 1.45, .030, axis='X', seg=24, rot=R, bevel=.0008)
            for j in range(3): cyl(f'{s.name}recr{k}{j}', b0 + a * (.004 + j * .010), r * 1.55, .0018, axis='X', seg=24, rot=R, bevel=0)
        else:      # a collar where the barrel leaves the hood's front face
            cyl(f'{s.name}collar{k}', b0 + a * .031, r * 1.5, .005, axis='X', seg=24, rot=R, bevel=.0006)
        cyl(f'{s.name}brl{k}', b0 + a * (.029 + Lb / 2), r, Lb, axis='X', seg=24, rot=R, bevel=.0005)
        cyl(f'{s.name}shr{k}', b0 + a * (.029 + Lb - .010), r * 1.32, .020, axis='X', seg=24, rot=R, bevel=.0006)
        for j in range(3): cyl(f'{s.name}shrr{k}{j}', b0 + a * (.029 + Lb - .017 + j * .007), r * 1.40, .0015, axis='X', seg=24, rot=R, bevel=0)
        PB.register_gun(f'{s.name}brl{k}', a, (0, 0, 1), tip=b0 + a * (.029 + Lb + .0005), socket=s.name, radius=r)
        fa, fx = (.066, .082) if hooded else (.060, .052)                      # welded brace from the barrel down to the deck
        z0 = (seat.top(b0.x + fx, y) if hooded else seat.top(b0.x + .045, y, .02)) or (b0.z - .02)
        tube(f'{s.name}brace{k}', b0 + a * fa + Vector((0, 0, -r)), Vector((b0.x + fx, y, z0)), .0016, seg=6)
    PB.tag(i0, 'part', 'copper')
    i1 = PB.mark()   # the slatted armour hood over the breeches (the concept's louvred raised-deck front)
    if not hooded:
        hw = gap + r * 2.4; zt = c.z + r * s.extra.get('hood', 1.9)
        box(f'{s.name}hood', (c.x - .020, c.y, zt), (.050, 2 * hw, .005), rot=(0, math.radians(-8), 0), bevel=.0008)
        for j in range(5):
            box(f'{s.name}slat{j}', (c.x - .040 + j * .010, c.y, zt + .0035), (.006, 2 * hw - .004, .0018), rot=(0, math.radians(-8), 0), bevel=0)
        for k in (-1, 1): box(f'{s.name}cheek{k}', (c.x - .016, k * hw, c.z + r * .5), (.040, .004, r * 3.0), bevel=.0006)
        weld(f'{s.name}weld', [(c.x - .020, -hw + .006, zt + .0020), (c.x - .020, hw - .006, zt + .0020)], rnd=rnd)
    PB.tag(i1, 'part', 'hood')
    i2 = PB.mark()
    for k in (-1, 1):
        b0 = c + Vector((0, k * gap, 0)); cyl(f'{s.name}glow{k}', b0 + a * (.029 + Lb + .0005), r * .62, .0016, axis='X', seg=16, rot=R, bevel=0)
    PB.tag(i2, 'glow')

def drum(name, c, r, L, aim=(1, 0, 0), variant=0, rnd=None):
    """a missile drum: strapped and quilted body, two faded ochre bands, a framed front with a recessed launch mouth, a tapered tail.
    variant 1: one band slipped and a patch strap; variant 2: shorter, a conical nose ring (salvaged from another drum type)"""
    rnd = rnd or random.Random(len(name)); a = Vector(aim).normalized(); R = PB.frame(a); c = Vector(c)
    if variant == 2: L *= .88
    i0 = PB.mark()
    cyl(name, c, r, L, axis='X', seg=28, rot=R, bevel=.0012)
    for k in range(6):
        f = -.42 + k * .168; cyl(f'{name}rib{k}', c + a * (L * f), r * 1.025, .0014, axis='X', seg=28, rot=R, bevel=0)
    for k in range(12):
        t = 2 * math.pi * (k + .5) / 12; off = R @ Vector((0, math.cos(t), math.sin(t)))
        tube(f'{name}st{k}', c + a * (-L * .47) + off * r * 1.01, c + a * (L * .47) + off * r * 1.01, .0010, seg=5)
    cyl(f'{name}rim', c + a * (L / 2 - .002), r * 1.06, .006, axis='X', seg=28, rot=R, bevel=.0006)
    cyl(f'{name}tail', c - a * (L / 2 + .004), r * .92, .008, axis='X', seg=24, r2=r * .62, rot=R, bevel=.0006)
    cyl(f'{name}tailc', c - a * (L / 2 + .009), r * .45, .004, axis='X', seg=16, rot=R, bevel=0)
    if variant == 2: cyl(f'{name}nring', c + a * (L / 2 + .002), r * .98, .006, axis='X', seg=28, r2=r * .80, rot=R, bevel=.0005)
    if variant == 1:
        t = rnd.uniform(0, math.pi); patch(f'{name}patch', c + R @ Vector((L * .05, math.cos(t) * r, math.sin(t) * r)), R @ Vector((0, math.cos(t), math.sin(t))), .014, .010)
    PB.tag(i0, 'part', 'drum')
    i1 = PB.mark()
    for k, f in enumerate((-.26, .30 if variant != 1 else .22)):
        cyl(f'{name}band{k}', c + a * (L * f), r * 1.045, L * .055, axis='X', seg=28, rot=R, bevel=0)   # round 7: thinner, as the concept's
    PB.tag(i1, 'trim', 'band')
    i2 = PB.mark()
    front = c + a * (L / 2 + (.0045 if variant == 2 else .0012))
    cyl(f'{name}face', front, r * .84, .0016, axis='X', seg=28, rot=R, bevel=0)
    PB.tag(i2, 'dark')
    i3 = PB.mark()
    cyl(f'{name}mouthr', front + a * .0012, r * .52, .0022, axis='X', seg=24, rot=R, bevel=0)
    PB.tag(i3, 'part', 'gun')
    i4 = PB.mark(); cyl(f'{name}mouth', front + a * .0026, r * .40, .0012, axis='X', seg=20, rot=R, bevel=0); PB.tag(i4, 'dark')
    return front + a * .0032      # the launch mouth (a muzzle point for the game export)

def drum_rack(s, seat, rnd):
    """drums in a welded pipe cradle: s.extra n (drums), pitch (along y), stagger (x step per drum, outward), r, L, lift (cradle height
    above the deck). Drums aim forward. The cradle stands on the real deck under each foot (legs cut to length)."""
    e = s.extra; n = e.get('n', 2); pitch = e.get('pitch', .046); st = e.get('stagger', 0.0); r = e.get('r', .02); L = e.get('L', .095)
    lift = e.get('lift', .004); c = s.pos; sy = 1 if s.side >= 0 else -1
    ys = [c.y + sy * (k - (n - 1) / 2) * pitch for k in range(n)] if e.get('centred', True) else [c.y + sy * k * pitch for k in range(n)]
    xs = [c.x - k * st for k in range(n)]
    zdeck = max(seat.top(x, y, L, r * 2) or c.z for x, y in zip(xs, ys))
    zc = e['zc'] if 'zc' in e else zdeck + lift + r * .95                   # 'zc': the drums' axis height, when the concept sets it
    i0 = PB.mark()
    for x, y, k in zip(xs, ys, range(n)):
        mouth = drum(f'{s.name}d{k}', (x, y, zc), r, L, (1, 0, 0), variant=(s.variant + k) % 3 if e.get('mixed', True) else 0, rnd=rnd)
        PB.register_gun(f'{s.name}d{k}', (1, 0, 0), (0, 0, 1), tip=mouth, socket=s.name, radius=r * .40)
    i1 = PB.mark()
    y0, y1 = min(ys) - r * 1.15, max(ys) + r * 1.15; xm = sum(xs) / n
    for f in (-.30, .26):                                                       # cross beams and saddles
        xb = xm + f * L
        box(f'{s.name}beam{f}', (xb, (y0 + y1) / 2, zc - r * .78), (.008, y1 - y0, .006), bevel=.0008)
        for x, y, k in zip(xs, ys, range(n)):
            box(f'{s.name}sad{f}{k}', (xb, y, zc - r * .62), (.009, r * 1.3, .006), bevel=.0008)      # round 7: on the beam, also in a staggered rack
        for yy in (y0, y1, (y0 + y1) / 2):                                      # legs cut to the deck under each foot
            zf = seat.top(xb, yy) or zdeck
            if zc - r * .78 - zf > .002: box(f'{s.name}leg{f}{yy:.3f}', (xb, yy, (zc - r * .78 + zf) / 2), (.006, .006, zc - r * .78 - zf + .002), bevel=.0006)
    zr = zc + r * .15                                                            # the low welded pipe cradle round the drums
    xa, xb2 = xm - L * .44, xm + L * .40
    for yy in (y0 - .003, y1 + .003):
        tube(f'{s.name}rail{yy:.3f}', (xa, yy, zr), (xb2, yy, zr), .0019)
        for xx in (xa, xb2, xm): tube(f'{s.name}post{yy:.3f}{xx:.3f}', (xx, yy, zc - r * .80), (xx, yy, zr), .0017)
    tube(f'{s.name}railb', (xa, y0 - .003, zr), (xa, y1 + .003, zr), .0019)
    weld(f'{s.name}weld', [(xm - L * .30 + .004, y0, zc - r * .78 + .0028), (xm - L * .30 + .004, (y0 + y1) / 2, zc - r * .78 + .0028)], rnd=rnd)
    PB.tag(i1, 'part', 'rack')

def turret(s, seat, rnd):
    """a top turret. variant 0 (Hullbreaker junk): a squat welded drum with a sloped front plate, a patch, one heavy barrel.
    variant 1 ('borrowed'): a clean faceted dome turret from another navy, welded onto a crude adapter ring, a long thin barrel."""
    c = s.pos; R0 = s.size; a = s.aim; z0 = seat.top(c.x, c.y, R0 * 2, R0 * 2) or c.z
    flat = Vector((a.x, a.y, 0)).normalized(); yaw = math.atan2(flat.y, flat.x); RZ = Matrix.Rotation(yaw, 3, 'Z')
    elev = math.radians(s.extra.get('elev', 12)); ad = (RZ @ Vector((math.cos(elev), 0, math.sin(elev)))).normalized()
    i0 = PB.mark()
    cyl(f'{s.name}ring', (c.x, c.y, z0 + .003), R0 * 1.15, .006, seg=10 if s.variant == 1 else 24, bevel=.0008)   # adapter / race ring
    weld(f'{s.name}weld', [(c.x + R0 * 1.15 * math.cos(t), c.y + R0 * 1.15 * math.sin(t), z0 + .0008) for t in [k * .5 for k in range(7)]], rnd=rnd)
    PB.tag(i0, 'part', 'turret_ring')
    i1 = PB.mark(); zb = z0 + .006
    if s.variant == 1:     # borrowed: a clean faceted dome
        cyl(f'{s.name}body', (c.x, c.y, zb + R0 * .35), R0, R0 * .7, seg=8, r2=R0 * .78, bevel=.0010)
        cyl(f'{s.name}dome', (c.x, c.y, zb + R0 * .85), R0 * .78, R0 * .3, seg=8, r2=R0 * .45, bevel=.0008)
        pivot = Vector((c.x, c.y, zb + R0 * .45)) + flat * R0 * .7; Lb = R0 * 3.2 * s.extra.get('blen', 1.0); rb = R0 * .14
        PB.tag(i1, 'part', 'borrowed')
    else:                  # Hullbreaker: squat drum, sloped glacis plate, a patch
        cyl(f'{s.name}body', (c.x, c.y, zb + R0 * .4), R0, R0 * .8, seg=20, bevel=.0010)
        pf = Vector((c.x, c.y, zb + R0 * .45)) + flat * R0 * .9
        box(f'{s.name}plate', pf, (R0 * .5, R0 * 1.5, R0 * .9), rot=(0, math.radians(-25), yaw), bevel=.0008)
        side = RZ @ Vector((0, 1, 0)); patch(f'{s.name}patch', Vector((c.x, c.y, zb + R0 * .4)) + side * R0, side, R0 * .6, R0 * .45)
        pivot = pf + flat * R0 * .2; Lb = R0 * 2.5 * s.extra.get('blen', 1.0); rb = R0 * .2
        PB.tag(i1, 'part', 'gun')
    i2 = PB.mark(); R = PB.frame(ad)
    cyl(f'{s.name}rec', pivot + ad * Lb * .12, rb * 1.6, Lb * .24, axis='X', seg=16, rot=R, bevel=.0004)
    cyl(f'{s.name}brl', pivot + ad * Lb * .55, rb, Lb * .9, axis='X', seg=16, rot=R, bevel=.0004)
    cyl(f'{s.name}mz', pivot + ad * Lb * .98, rb * 1.3, Lb * .07, axis='X', seg=16, rot=R, bevel=0)
    PB.register_gun(f'{s.name}brl', ad, (0, 0, 1), tip=pivot + ad * Lb * 1.015, socket=s.name, radius=rb)
    PB.tag(i2, 'part', 'copper' if s.variant == 0 else 'gun')

def marking(s, seat, rnd):
    """painted markings as thin decal plates seated on the hull (the bake paints them into the parts atlas): extra 'mark' is
    frame (a stencilled rectangle outline), tag (a filled yellow tag), disc (a white ring on a deck), lamps (a row of amber lamps)"""
    e = s.extra; mk = e.get('mark', 'frame'); c = s.pos; n = s.normal; w, h = e.get('w', .03), e.get('h', .02); th = .0007
    nn, u, v = _basis(n) if abs(n.z) < .7 else (n, Vector((1, 0, 0)), Vector((0, 1, 0)) if n.z > 0 else Vector((0, -1, 0)))
    i0 = PB.mark()
    if mk == 'frame':
        b = e.get('line', .0022)
        for k, (a, bb, ww, hh) in enumerate(((0, h / 2, w, b), (0, -h / 2, w, b), (w / 2, 0, b, h), (-w / 2, 0, b, h))):
            patch(f'{s.name}f{k}', c + u * a + v * bb, nn, ww, hh, th=th, rivets=False)
        PB.tag(i0, 'decal', e.get('kind', 'white'))
    elif mk == 'tag':
        patch(f'{s.name}t', c, nn, w, h, th=th, rivets=False); PB.tag(i0, 'decal', e.get('kind', 'yellow'))
    elif mk == 'disc':
        cyl(f'{s.name}d', c + nn * th / 2, w / 2, th, axis='X', seg=32, rot=PB.frame(nn), bevel=0)
        PB.tag(i0, 'decal', e.get('kind', 'white'))
        i1 = PB.mark(); cyl(f'{s.name}di', c + nn * th, w * .36, th, axis='X', seg=32, rot=PB.frame(nn), bevel=0); PB.tag(i1, 'part', 'rust_plain')
    elif mk == 'lamps':
        k_ = e.get('n', 6); step = e.get('step', .012)
        for k in range(k_):
            p = c + u * ((k - (k_ - 1) / 2) * step)
            cyl(f'{s.name}h{k}', p + nn * .0012, .0030, .0024, axis='X', seg=12, rot=PB.frame(nn), bevel=0)
        PB.tag(i0, 'part', 'gun_dark')
        i1 = PB.mark()
        for k in range(k_):
            p = c + u * ((k - (k_ - 1) / 2) * step)
            cyl(f'{s.name}l{k}', p + nn * .0026, .0019, .0008, axis='X', seg=12, rot=PB.frame(nn), bevel=0)
        PB.tag(i1, 'glow')

PARTS = dict(casemate=casemate, bow_battery=bow_battery, drum_rack=drum_rack, turret=turret, marking=marking)

def build(sockets, seat, seed=209):
    """build every socket's part with this kit. Returns the gun audit (names aimed badly; must be empty)."""
    rnd = random.Random(seed)
    for s in sockets:
        PARTS[s.part](s, seat, random.Random(f"{seed}:{s.name}"))
    return PB.audit_guns()
