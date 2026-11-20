"""Grown shell and bone for rounded Chorus sheets, in the build sheet's frame."""

import math
import random

from mathutils import Vector


MATERIALS = {
    'carapace': ((0.100, 0.068, 0.038), 0),
    'carapace_joint': ((0.041, 0.026, 0.012), 0),
}


def _append(mesh, vertices, faces):
    offset = len(mesh[0])
    mesh[0].extend(vertices)
    mesh[1].extend(tuple(offset + i for i in face) for face in faces)


def _scute(section, root, length, angles, sweep, scallops, phase, relief, recesses, side, bounds):
    """One closed scute. The buried root rises gently to a thick, free trailing lip."""
    lo, hi = angles
    width = 18
    row = width + 1
    # The two closely spaced stations at the trailing edge round the lip.
    face_stations = ((0.0, -0.065), (0.22, 0.009), (0.49, 0.052),
                     (0.73, 0.106), (0.94, 0.164), (0.985, 0.181), (1.0, 0.167))
    vertices, faces, growth = [], [], []
    for lower in (False, True):
        for along, rise in face_stations:
            for j in range(row):
                across = j / width
                edge = 2.0 * across - 1.0
                scallop = math.sin(math.tau * scallops * across + phase)
                taper = 0.12 * (1.0 - along) ** 2 + 0.055 * along ** 4
                angle = lo + (hi - lo) * (taper + across * (1.0 - 2.0 * taper))
                x = root - along * length + sweep * edge * (0.22 + 0.78 * along)
                x += (0.26 * edge ** 2 + 0.13 * scallop) * along ** 3
                x = min(bounds[0], max(bounds[1], x))
                # Clear fittings by drawing in the nearer margin of this plate.
                inset = max((margin * math.exp(-((x - centre) / radius) ** 4)
                             for centre, radius, margin in recesses), key=abs, default=0.0)
                angle += inset * (1.0 - across if inset > 0.0 else across)
                angle += 0.035 * math.sin(phase + math.pi * along)
                height = rise * relief - 0.11 * edge ** 6
                if lower:
                    height -= 0.035 + 0.058 * along
                point, _ = section(x, angle if side > 0 else math.pi - angle, out=height)
                vertices.append(point)
                growth.append(along)
    half = row * len(face_stations)
    for i in range(len(face_stations) - 1):
        for j in range(width):
            v = i * row + j
            top = (v, v + 1, v + row + 1, v + row)
            faces.append(top)
            faces.append(tuple(v + half for v in reversed(top)))
    rim = (list(range(row)) + list(range(2 * row - 1, half, row)) +
           list(range(half - 2, half - row - 1, -1)) +
           list(range(half - 2 * row, 0, -row)))
    for a, b in zip(rim, rim[1:] + rim[:1]):
        faces.append((b, a, a + half, b + half))
    if side > 0:
        faces = [face[::-1] for face in faces]
    return vertices, faces, growth


def overlapping_plates(section, coverage, plate_count_range, seed):
    """Yield shell meshes for each flank.

    Coverage gives (bow x, aft x, low angle, high angle, socket recesses) for
    each band. Recesses give (x, radius, angle inset). A positive inset draws
    in the low edge; a negative inset draws in the high edge. The count range
    applies to each band, and the band's span sets the size of its scutes.
    """
    rng = random.Random(seed)
    for side, name in ((1, 'port'), (-1, 'starboard')):
        mesh, tones, growth = ([], []), [], []
        for bow, aft, lo, hi, recesses in coverage:
            count = rng.randint(*plate_count_range)
            span = bow - aft
            weights = [rng.uniform(0.73, 1.27) for _ in range(count)]
            lengths = [span * w / sum(weights) for w in weights]
            root = bow
            for step in lengths:
                length = 1.24 * step
                sweep = rng.uniform(-0.61, 0.61) * min(1.0, step / 1.8)
                angular_shift = rng.uniform(-0.075, 0.075)
                vertices, faces, progress = _scute(
                    section, root, length, (lo + angular_shift, hi + angular_shift),
                    sweep, rng.uniform(1.4, 2.65), rng.uniform(0, math.tau),
                    rng.uniform(0.94, 1.16), recesses, side, (bow + 0.30, aft - 0.40),
                )
                _append(mesh, vertices, faces)
                tones.extend([rng.uniform(0.1, 0.9)] * len(vertices))
                growth.extend(progress)
                root -= step
        yield name, mesh, tones, growth


def _spine(root, normal, height, sweep, width, lean):
    """A tapered bone blade with a forward keel and a backswept tip."""
    aft = Vector((-1.0, 0.0, 0.0))
    across = normal.cross(aft).normalized()
    vertices, faces = [], []
    rings = ((0.0, 1.0), (0.15, 0.93), (0.36, 0.71),
             (0.60, 0.49), (0.81, 0.27), (0.94, 0.095))
    sides = 8
    for t, size in rings:
        centre = root + normal * (height * t) + aft * (sweep * t ** 1.55)
        centre += across * (lean * t ** 1.5)
        for i in range(sides):
            a = math.tau * i / sides
            vertices.append(centre + aft * (math.cos(a) * width * size * 1.25)
                            + across * (math.sin(a) * width * size * 0.76))
    faces.append(tuple(reversed(range(sides))))
    tip = len(vertices)
    vertices.append(root + normal * height + aft * sweep + across * lean)
    for row in range(len(rings)):
        for i in range(sides):
            a, b = row * sides + i, row * sides + (i + 1) % sides
            faces.append((a, b, b + sides, a + sides) if row < len(rings) - 1 else (a, b, tip))
    return vertices, faces


def _socket(section, x, angle, radius):
    """A wet lip seated in the hull, raised just around the spine's root."""
    vertices, faces = [], []
    sides = 14
    for scale, rise in ((1.29, -0.035), (1.11, 0.097), (0.82, 0.135), (0.58, 0.015)):
        for i in range(sides):
            a = math.tau * i / sides
            ripple = 1.0 + 0.07 * math.sin(3 * a)
            dx = 1.35 * radius * math.cos(a) * scale * ripple
            da = 0.48 * radius * math.sin(a) * scale * ripple
            vertices.append(section(x + dx, angle + da, out=rise)[0])
    for row in range(3):
        for i in range(sides):
            a, b = row * sides + i, row * sides + (i + 1) % sides
            faces.append((b, a, a + sides, b + sides))
    return vertices, faces


def dorsal_spines(section, coverage, count_range, seed):
    """Build a row of bone blades and sockets. Coverage is (bow x, aft x, height range)."""
    bow, aft, heights = coverage
    rng = random.Random(seed)
    count = rng.randint(*count_range)
    bone, sockets = ([], []), ([], [])
    pitch = (bow - aft) / count
    for i in range(count):
        x = bow - pitch * (i + rng.uniform(0.28, 0.73))
        angle = math.pi / 2 + rng.uniform(-0.082, 0.082)
        root, normal = section(x, angle, out=-0.06)
        height = rng.uniform(*heights) * (1.0 - 0.23 * i / count)
        width = pitch * rng.uniform(0.19, 0.26)
        _append(bone, *_spine(root, normal, height, height * rng.uniform(0.64, 0.91),
                             width, rng.uniform(-0.18, 0.18)))
        _append(sockets, *_socket(section, x, angle, width))
    return bone, sockets


# ---------------- the armour shell over the whole body (Ryan, R341, Nov 19 2026) ----------------
# "the armor should be comprehensive and across the entire body, minus things like the spine, maw, 'engines', weapons, etc. it
# should be almost like an armadillo, pangolin, etc. not exactly the same, still alien, but think about it as a warship."
# One builder for every Chorus sheet (R333): scutes in bands from the belly to the back on both flanks, each band offset half a
# scute from the next (a pangolin's brick lay), every scute's free lip lying aft over the root of the one behind it. Nothing is
# listed by hand: the keep-outs are read from the sheet's own fittings (every part that is not hull skin), so the guns, maws,
# glands, vents, siphons, sacs and the spine row stand in open sockets of wet hide.

def register(kit_module):
    """the shell's materials in the sheet kit (call before building anything that uses them)"""
    kit_module.MATS.update(MATERIALS)


def body_keepouts(K, sec_at, skip=(), keep=(), reach=0.18, bury=0.06, cell=(0.1, 0.06), margin=0, wide=('Q', 'E')):
    """the hull cells the shell must leave open: every outside mesh that is not hull skin (grp 'hull'), plus hull objects whose
    name starts with one of `keep` (grown-in features that stay bare, e.g. a face or a blade row), minus names starting with `skip`. Only the foot of a fitting counts, the part between `bury` under the skin and `reach` over it (a spine tip far
    out, or a root deep in the body, opens no hole). Siphons and vents (names starting with `wide`) keep a wider socket, clear of
    their jets. Returns blocked(x, th, side) with th in the port convention of K.hpt
    (0 beam, pi/2 top) and side +1 port, -1 starboard."""
    dx, dt = cell
    occ = {1: set(), -1: set()}
    for ob in K.coll.objects:
        if ob.type != 'MESH' or ob.get('inside'):
            continue
        nm = ob.name
        if any(nm.startswith(s) for s in skip):
            continue
        if ob.get('grp') == 'hull' and not any(nm.startswith(k) for k in keep):
            continue
        M = ob.matrix_world
        vs = ob.data.vertices
        step = max(1, len(vs) // 700)
        mg = margin + 3 if any(nm.startswith(w) and nm[1:2].isdigit() for w in wide) else margin
        for i in range(0, len(vs), step):
            v = M @ vs[i].co
            s = sec_at(K.hull_sections, v.x)
            zc = (s[3] + s[4]) / 2
            side = 1 if v.y >= 0 else -1
            th = math.atan2(v.z - zc, abs(v.y))
            hp, _ = K.hpt(v.x, th if side > 0 else math.pi - th)
            rh = math.hypot(hp.y, hp.z - zc)
            rv = math.hypot(v.y, v.z - zc)
            if rv - rh > reach or rv - rh < -bury:
                continue   # a spine tip far out, or a root buried deep in the body, does not open the shell
            ix, it = int(math.floor(v.x / dx)), int(math.floor(th / dt))
            for a in range(-mg, mg + 1):
                for b in range(-mg, mg + 1):
                    occ[side].add((ix + a, it + b))
                    # a fitting on the belly or the back sits on both flanks' bands
                    if abs(th) > 1.5:
                        occ[-side].add((ix + a, it + b))

    def blocked(x, th, side):
        return (int(math.floor(x / dx)), int(math.floor(th / dt))) in occ[side]
    return blocked


def draped(K, names):
    """K.hpt laid over the lumps grown into the hull (hull objects whose name starts with one of `names`, e.g. the knolls): a
    point on the outermost of the hull skin and the lumps, so the shell rides over a knoll like a pangolin's back over its
    shoulders. Same call as K.hpt: (x, th, out) -> (point, normal)."""
    from mathutils.bvhtree import BVHTree
    V, F = [], []
    for ob in K.coll.objects:
        if ob.type == 'MESH' and not ob.get('inside') and any(ob.name.startswith(n) for n in names):
            M = ob.matrix_world
            o = len(V)
            V.extend(M @ v.co for v in ob.data.vertices)
            F.extend(tuple(o + i for i in poly.vertices) for poly in ob.data.polygons)
    tree = BVHTree.FromPolygons(V, F) if F else None

    def at(x, th, out=0.0):
        p0, n0 = K.hpt(x, th)
        if tree is not None:
            hit, nrm, _, dist = tree.ray_cast(p0 + n0 * 1.5, -n0, 1.5)
            if hit is not None and dist < 1.5:
                # the lump's own normal, leaned back toward the hull's so a scute does not stand on edge at a knoll's foot
                nrm = (nrm if nrm.dot(n0) > 0 else -nrm)
                nrm = (nrm + n0 * 0.6).normalized()
                return hit + nrm * out, nrm
        return p0 + n0 * out, n0
    return at


def _armour_scute(section, root, length, angles, t, side, point=0.5, sharp=1.0, keels=1, bulge=0.08, wave=0.0, phase=0.0,
                  nu=8, nv=16):
    """One armour scute (R341): a thick keratin plate lying aft, its root low on the skin and its free lip standing proud with a
    deep shadow gap under it, so the scute behind slides under it as a pangolin's do. The trailing edge comes to a point
    (`point` of the length; `sharp` 1 is a straight-sided V, 2.5 a squared chisel with a short point), the lip is the thickest
    part, and a keel runs root to lip: one roof-like ridge splitting the face into a lit and a shaded plane, or two raised keels
    (Neon's review, Nov 19: crisp planes, not a pillow). Returns (vertices, faces, growth, ridge): growth 0 at the root to 1 at
    the lip, ridge 1 on a keel's crest to 0 in the grooves (the paint's pale worn horn)."""
    lo, hi = angles
    mid, half = 0.5 * (lo + hi), 0.5 * (hi - lo)
    row = nv + 1
    vertices, growth, ridge = [], [], []
    for under in (False, True):
        for i in range(nu + 1):
            a = i / nu
            for j in range(row):
                e = 2.0 * j / nv - 1.0
                reach = length * (1.0 - point * abs(e) ** sharp)
                x = root - a * reach
                angle = mid + e * half * (1.0 - 0.12 * a) + 0.03 * wave * math.sin(phase + math.pi * a)
                gap = 0.004 + 0.62 * t * a ** 1.5
                thick = t * (0.38 + 0.7 * a ** 2.5) * (1.0 - 0.5 * e ** 4)
                if keels == 1:
                    rk = (1.0 - abs(e)) ** 1.5
                else:
                    rk = max(math.exp(-((e - c) / 0.17) ** 2) for c in (-0.38, 0.38))
                keel = rk * t * 0.6 * (0.25 + 0.75 * a)
                h = gap if under else gap + thick * (1.0 + bulge * (1.0 - e * e)) + keel
                point_, _ = section(x, angle if side > 0 else math.pi - angle, out=h)
                vertices.append(point_)
                growth.append(a)
                ridge.append(rk)
    faces = []
    sheet = row * (nu + 1)
    for i in range(nu):
        for j in range(nv):
            v = i * row + j
            top = (v, v + 1, v + row + 1, v + row)
            faces.append(top)
            faces.append(tuple(q + sheet for q in reversed(top)))
    rim = (list(range(row)) + list(range(2 * row - 1, sheet, row)) +
           list(range(sheet - 2, sheet - row - 1, -1)) + list(range(sheet - 2 * row, 0, -row)))
    for a_, b_ in zip(rim, rim[1:] + rim[:1]):
        faces.append((b_, a_, a_ + sheet, b_ + sheet))
    if side > 0:
        faces = [f[::-1] for f in faces]
    return vertices, faces, growth, ridge


def armour_shell(section, blocked, x_bow, x_aft, seed, rows=5, scute=0.8, belly=-1.56, back=1.57, thick=0.1, lap=0.3, over=1.35):
    """Yield (side name, mesh, attributes) for the two flanks' shells: `rows` bands between the belly angle and the back angle
    (K.hpt's port convention), scutes about `scute` long, each band lapping `lap` of the band below it and offset half a scute
    from it. Where a scute would cover a fitting it is trimmed, never replaced by a patch of small scutes (Neon, Nov 19): first
    shortened, then cut back from the side that meets the fitting, so the shell's edge pulls back round the socket."""
    rng = random.Random(seed)
    span = (back - belly) / rows

    def free(x0, lo0, hi0, length, side):
        return not any(blocked(x0 - fa * length, lo0 + fb * (hi0 - lo0), side)
                       for fa in (0.05, 0.35, 0.7) for fb in (0.15, 0.5, 0.85))   # the lip may tuck against a foot
    for side, name in ((1, 'port'), (-1, 'starboard')):
        mesh, attrs = ([], []), dict(scute_tone=[], scute_progress=[], scute_ridge=[])
        placed = trimmed = left = 0
        for r in range(rows):
            lo = belly + r * span - (lap * span if r else 0.0)
            hi = belly + (r + 1) * span
            x = x_bow - (0.5 * scute if r % 2 else 0.0) - rng.uniform(0.0, 0.15) * scute
            while x > x_aft:
                step = scute * rng.uniform(0.85, 1.15)
                w = hi - lo
                fits = []
                for k in (1.0, 0.72, 0.5):                                  # shortened
                    if free(x, lo, hi, over * step * k, side):
                        fits = [(lo, hi, k)]
                        break
                if not fits:                                                # cut back from the fitting's side
                    for k, f_ in ((0.85, 0.6), (0.6, 0.6), (0.5, 0.45)):
                        fits = [(a_, b_, k) for a_, b_ in ((lo, lo + f_ * w), (hi - f_ * w, hi))
                                if free(x, a_, b_, over * step * k, side)]
                        if fits:
                            break
                if not fits:
                    left += 1
                for lo0, hi0, k in fits:
                    placed += 1
                    trimmed += k < 1.0 or hi0 - lo0 < w
                    vertices, faces, progress, ridge = _armour_scute(
                        section, x, over * step * k, (lo0, hi0), thick * rng.uniform(0.9, 1.1), side,
                        point=rng.uniform(0.4, 0.55), sharp=rng.choice((1.0, 1.0, 1.0, 2.5)), keels=rng.choice((1, 1, 1, 2)),
                        wave=rng.uniform(-1, 1), phase=rng.uniform(0, math.tau))
                    _append(mesh, vertices, faces)
                    attrs['scute_tone'].extend([rng.uniform(0.1, 0.9)] * len(vertices))
                    attrs['scute_progress'].extend(progress)
                    attrs['scute_ridge'].extend(ridge)
                x -= step
        print('[armour] %s: %d scutes (%d trimmed), %d left open round fittings' % (name, placed, trimmed, left), flush=True)
        yield name, mesh, attrs


def armour(K, kit_module, x_bow, x_aft, seed, drape=(), skip=(), keep=(), note='', inv='hide', **kw):
    """the whole-body shell on a Chorus sheet: keep-outs from the sheet's own fittings, both flanks' scutes as hull detail
    (structure: they tear with the hull, R226), the growth and tone attributes the paint stack reads. Returns the shell objects."""
    register(kit_module)
    # a fitting counts as far out as the scutes stand (gap, lip and keel: about twice their thickness)
    blocked = body_keepouts(K, kit_module.sec_at, skip=skip, keep=keep, reach=max(0.18, 2.2 * kw.get('thick', 0.1)))
    made = []
    for side, mesh, attrs in armour_shell(draped(K, drape) if drape else K.hpt, blocked, x_bow, x_aft, seed, **kw):
        shell = K.hull_detail('armour_' + side, mesh, 'carapace', inv=inv, kind='chitin', subs=['plate', 'rim', 'growth'])
        if shell is None:
            continue
        K.mass('Armour shell (' + side + ')', shell, 'brown keratin scutes',
               note=note or 'Banded overlapping scutes over the whole body, lips aft; fittings stand in open sockets (R341).')
        _attributes(shell, attrs)
        made.append(shell)
    return made


def _dome_section(tree, centre, axis, radius):
    """a dome's surface in the scute builder's terms: x is minus the polar angle from the crown (so a scute's lip points down
    the dome toward its foot) and the angle is the azimuth round the axis. Rays come in from outside onto the dome's mesh."""
    n = axis.normalized()
    u = n.orthogonal().normalized()
    v = n.cross(u)

    def at(x, az, out=0.0):
        ph = max(0.0, -x)
        d = u * (math.sin(ph) * math.cos(az)) + v * (math.sin(ph) * math.sin(az)) + n * math.cos(ph)
        far = 2.6 * radius
        hit, nrm, _, dist = tree.ray_cast(centre + d * far, -d, far)
        if hit is None:
            hit, nrm = centre + d * radius, d
        nrm = nrm if nrm.dot(d) > 0 else -nrm
        nrm = (nrm + d * 0.5).normalized()
        return hit + nrm * out, nrm
    return at


def dome_caps(K, kit_module, domes, seed, name='armour_caps', note='', inv='hide', flat=False):
    """R341 (the Board, Nov 19): small scutes capping the top of each grown dome the shell leaves open (sacs, knolls), lips down
    the dome, so the armour wraps them; never on a gland, maw or vent. domes = [(prefixes, centre, axis, radius, reach)], with
    the hull objects or fittings whose names start with `prefixes` as the dome's surface and `reach` the polar angle (radians
    from the crown) the cap comes down to; an optional sixth value starts the cap that far from the crown, so a gland's knoll is
    armoured round its slopes with its vent and spines open. flat (issue 1291 round G, Ryan: "caps, but flatter"): two rings of
    fewer, wider, thin plates lying close on the dome instead of three rings of keeled scutes, so a cap reads as a shell, not a
    pinecone. One hull-detail object for the ship; returns it."""
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    register(kit_module)
    rng = random.Random(seed)
    mesh, attrs = ([], []), dict(scute_tone=[], scute_progress=[], scute_ridge=[])
    for dome in domes:
        prefixes, centre, axis, radius, reach = dome[:5]
        start = dome[5] if len(dome) > 5 else 0.0
        V, F = [], []
        for ob in K.coll.objects:
            if ob.type == 'MESH' and not ob.get('inside') and any(ob.name.startswith(p) for p in prefixes):
                M = ob.matrix_world
                o = len(V)
                V.extend(M @ w.co for w in ob.data.vertices)
                F.extend(tuple(o + i for i in poly.vertices) for poly in ob.data.polygons)
        if not F:
            continue
        sec = _dome_section(BVHTree.FromPolygons(V, F), Vector(centre), Vector(axis), radius)
        t = (0.032 if flat else 0.075) * radius   # thinner and calmer than the body's scutes: a cap, never a rosette
        k = 0
        ph = start
        rings = ((5, 8) if flat else (4, 8, 12)) if not start else ((7, 10) if flat else (10, 13, 16))
        step = (reach - start) / len(rings)
        for n_ in rings:
            off = rng.uniform(0, math.tau)
            w = math.tau / n_
            for i in range(n_):
                lo = off + i * w - 0.24 * w
                hi = off + (i + 1) * w + 0.24 * w
                vertices, faces, progress, ridge = _armour_scute(
                    sec, -ph, step * (1.25 if flat else 1.45), (lo, hi), t * rng.uniform(0.9, 1.1), 1,
                    point=rng.uniform(0.06, 0.12) if flat else rng.uniform(0.12, 0.22),
                    sharp=1.6 if flat else 2.5, keels=1, bulge=0.03 if flat else 0.12)
                _append(mesh, vertices, faces)
                attrs['scute_tone'].extend([rng.uniform(0.1, 0.9)] * len(vertices))
                attrs['scute_progress'].extend(progress)
                attrs['scute_ridge'].extend(ridge)
                k += 1
            ph += step
    if not mesh[1]:
        return None
    caps = K.hull_detail(name, mesh, 'carapace', inv=inv, kind='chitin', subs=['plate', 'rim', 'growth'])
    K.mass('Armour caps', caps, 'brown keratin scutes', note=note or 'small scutes capping the sacs and knolls, lips down (R341)')
    _attributes(caps, attrs)
    return caps


def _attributes(ob, attrs):
    """the per-point values the Chorus paint stack reads on a shell (tone, growth root to lip, keel crest)"""
    for nm, values in attrs.items():
        attr = ob.data.attributes.new(nm, 'FLOAT', 'POINT')
        attr.data.foreach_set('value', values)


# ------------------------------------------------------------------ issue 1291: grown chitin (the spitter's rebuild)
def _band(section, root, length, lo, hi, t, rng, nu=12, nv=None, sink=0.012):
    """One armadillo band (issue 1291): a curved chitin plate grown out of the flesh, lying aft, from section angle lo to hi
    (K.hpt's port convention; a band may run across the back from flank to flank). The root sinks into the skin (it grows out
    of it), the face carries transverse growth ridges and the lip rolls over thick; both ends thin out into the flesh (fused,
    never a cut tile). Returns (vertices, faces, growth, ridge) as _armour_scute does."""
    nv = nv or max(8, int((hi - lo) / 0.05))
    row = nv + 1
    r1, r2 = rng.uniform(0.2, 0.42), rng.uniform(0.48, 0.74)
    # round D: each band's ridges its own strength, so the shell is not a stack of identical rings
    k1, k2, k3 = rng.uniform(0.2, 0.75), rng.uniform(0.25, 0.9), rng.uniform(0.5, 1.0)
    ph = rng.uniform(0, math.tau); wav = rng.uniform(0.6, 1.2)
    vertices, growth, ridge = [], [], []
    for under in (False, True):
        for i in range(nu + 1):
            a = i / nu
            for j in range(row):
                e = j / nv
                ang = lo + (hi - lo) * e
                end = min(1.0, e / 0.12, (1 - e) / 0.12)            # the ends fuse into the flesh
                lip = length * (1.0 + 0.06 * math.sin(ph + 4 * e) + 0.03 * math.sin(2 * ph + 11 * e))   # an uneven grown edge
                x = root - a * lip * (0.75 + 0.25 * end)
                rk = (k1 * math.exp(-((a - r1) / 0.06) ** 2) + k2 * math.exp(-((a - r2) / 0.07) ** 2)
                      + k3 * math.exp(-((a - 0.94) / 0.07) ** 2))
                rk *= 1.0 + 0.25 * math.sin(ph + wav * 14 * e)
                # round D (issue 1291): the band lies nearly flush on the hide, its lip only a little proud
                gap = 0.002 + 0.28 * t * a ** 1.6
                thick = t * (0.24 + 0.4 * a ** 2) * end ** 0.7
                h = gap * end - sink * (1 - a) ** 3 if under else gap * end - sink * (1 - a) ** 3 + thick * (1 + 0.35 * rk)
                p_, _ = section(x, ang, out=h)
                vertices.append(p_)
                growth.append(a)
                ridge.append(min(1.0, rk))
    faces = []
    sheet = row * (nu + 1)
    for i in range(nu):
        for j in range(nv):
            v = i * row + j
            top = (v, v + 1, v + row + 1, v + row)
            faces.append(top)
            faces.append(tuple(q + sheet for q in reversed(top)))
    rim = (list(range(row)) + list(range(2 * row - 1, sheet, row)) +
           list(range(sheet - 2, sheet - row - 1, -1)) + list(range(sheet - 2 * row, 0, -row)))
    for a_, b_ in zip(rim, rim[1:] + rim[:1]):
        faces.append((b_, a_, a_ + sheet, b_ + sheet))
    return vertices, [f[::-1] for f in faces], growth, ridge


def _skirt(section, pts_xt, w, h, rng, creases=True):
    """the hide gathered against a plate's edge (issue 1291): a soft roll of skin along the edge (x, t points) and short crease
    welts running off it into the flesh. Returns (vertices, faces) in the welt kit's shape."""
    from chorus import parts
    V, F = [], []

    def add(vf):
        o = len(V); V.extend(vf[0]); F.extend(tuple(q + o for q in f) for f in vf[1])
    P = [section(x, t_, out=0.0) for x, t_ in pts_xt]
    if len(P) >= 2:
        add(parts.welt([p for p, _ in P], [n for _, n in P], w, h, n=5))
    if creases:
        for k in range(1, len(pts_xt) - 1, 2):
            x, t_ = pts_xt[k]
            ln = rng.uniform(0.1, 0.22); dt = rng.uniform(-0.05, 0.05)
            q = [section(x + ln * f, t_ + dt * f, out=0.0) for f in (0.1, 0.5, 1.0)]
            add(parts.welt([p for p, _ in q], [n for _, n in q], [w * 0.5, w * 0.4, w * 0.15], [h * 0.6, h * 0.45, h * 0.1], n=4))
    return V, F


# issue 1291 (Ryan, Nov 20 4:18 PM CT: "run it down low too. we should cover the chorus ships in armor almost everywhere"):
# the armadillo bands wrap the body down to the keel by default; KEEL is how close to the keel line a band end may come
WRAP = -1.5
KEEL = -math.pi / 2 + 0.02


def armadillo(K, kit_module, x_bow, x_aft, seed, lo=None, band=0.42, lap=1.4, thick=0.07, skip=(), keep=(), note='', inv='hide',
              close_gaps=True, fill=True):
    """issue 1291 (Ryan, Nov 20: "mix of b and c"; round F: "armor more across the entire ship body"): an armadillo-like shell
    wrapping the body (lo=-1.2 runs each band from belly edge to belly edge; the default wraps to the keel), bands of grown chitin
    running across the back from flank (section angle lo) to flank (pi - lo), each lying aft over the next; a band is broken
    round a fitting and both broken ends thin into the flesh; hide rolls and creases gather along the shell's lower edges.
    close_gaps (issue 1291): when a long step would outrun a short band and leave a bare strip across the back, the next band
    starts under this one's lip instead (no extra draw from rng, so only those steps change). False keeps the old steps: C13
    as accepted and published (round G, PR 1308) has one such step and keeps it until Ryan asks for a rebuild.
    lo=None (the default, Ryan Nov 20: "cover the chorus ships in armor almost everywhere") is WRAP: each band runs down both
    flanks to the keel, where the two ends meet; a band never crosses the keel. fill (default on): where a fitting cuts a band,
    a half band still grows ahead of it or behind it, so the shell hugs the fittings instead of leaving a band-long gap.
    Returns the shell object and the skirt object."""
    register(kit_module)
    rng = random.Random(seed)
    lo = WRAP if lo is None else lo
    blocked = body_keepouts(K, kit_module.sec_at, skip=skip, keep=keep, reach=max(0.18, 3 * thick))
    mesh, attrs = ([], []), dict(scute_tone=[], scute_progress=[], scute_ridge=[])
    skirt = ([], [])
    x = x_bow; nb = 0; runs_n = 0; clamped = 0
    while x - band > x_aft:
        L_ = band * lap
        # round D: uneven bands, wider and narrower, their lower edges ragged
        L_ = band * lap * rng.uniform(0.75, 1.25)
        lo_ = lo + rng.uniform(-0.16, 0.16); hi_ = math.pi - lo + rng.uniform(-0.16, 0.16)
        lo_ = max(lo_, KEEL); hi_ = min(hi_, math.pi - KEEL)   # the two ends meet at the keel, never cross it
        n = 80
        cols = []
        for j in range(n + 1):
            th = lo_ + (hi_ - lo_) * j / n
            side = 1 if th < math.pi / 2 else -1
            thp = th if side > 0 else math.pi - th
            cols.append((thp, side))

        def runs_of(ok):
            out = []; j = 0
            while j <= n:
                if ok[j]:
                    k = j
                    while k + 1 <= n and ok[k + 1]:
                        k += 1
                    a_ = lo_ + (hi_ - lo_) * j / n; b_ = lo_ + (hi_ - lo_) * k / n
                    if b_ - a_ > 0.22:
                        out.append((a_, b_, j, k))
                    j = k + 1
                else:
                    j += 1
            return out

        def clear(fs):
            return [not any(blocked(x - f * L_, thp, side) for f in fs) for (thp, side) in cols]
        full = clear((0.0, 0.3, 0.6, 0.9))
        pieces = [(x, L_, a_, b_) for (a_, b_, _, _) in runs_of(full)]
        if fill:
            # Ryan (Nov 20, "cover the chorus ships in armor almost everywhere"): where a fitting cuts a band, a half band still
            # grows on the clear side of it (its front half ahead of the fitting, or its back half behind it), so a big
            # fitting leaves a hole the size of itself, not a whole band's length either side
            covered = list(full)
            for fs, root in (((0.0, 0.15, 0.3, 0.42), x), ((0.55, 0.7, 0.85, 0.97), x - 0.55 * L_)):
                ok = clear(fs)
                ok = [o and not c for o, c in zip(ok, covered)]
                for (a_, b_, j0, k0) in runs_of(ok):
                    pieces.append((root, L_ * 0.45, a_, b_))
                    for q in range(j0, k0 + 1):
                        covered[q] = True
        for xr, Lr, a_, b_ in pieces:
            vv, ff, gg, rr = _band(K.hpt, xr, Lr, a_, b_, thick * rng.uniform(0.9, 1.1), rng)
            _append(mesh, vv, ff)
            attrs['scute_tone'].extend([rng.uniform(0.2, 0.8)] * len(vv))
            attrs['scute_progress'].extend(gg)
            attrs['scute_ridge'].extend(rr)
            runs_n += 1
            # the hide gathered at the band's ends (its lower edge on each flank, or where it breaks round a fitting)
            for tt in (a_, b_):
                pts = [(xr - Lr * f, tt + (0.02 if tt == a_ else -0.02)) for f in (0.0, 0.2, 0.4, 0.6, 0.8, 1.0)]
                _append(skirt, *_skirt(K.hpt, pts, 0.14, 0.014, rng))
        step = band * rng.uniform(0.65, 1.35)
        if close_gaps and step > L_:
            # issue 1291: a long step after a short band would leave a bare strip across the back; the next band starts under
            # this one's lip instead. Only the steps that would open a gap change (no extra draw from rng), so a sheet whose
            # bands never hit the case builds the same bytes as before
            step = L_ * 0.92; clamped += 1
        x -= step; nb += 1
    # the first band's root: the hide it grows out of, rolled against it
    print('[armadillo] %d bands, %d runs, %d steps clamped' % (nb, runs_n, clamped), flush=True)
    shell = K.hull_detail('armour_shell', mesh, 'carapace', inv=inv, kind='chitin', subs=['plate', 'rim', 'growth'])
    if shell is not None:
        K.mass('Armour shell', shell, 'grown chitin bands', note=note or 'armadillo bands of grown chitin over the back, lips aft (issue 1291)')
        _attributes(shell, attrs)
    sk = K.hull_detail('armour_skirt', skirt, 'flesh2') if skirt[1] else None
    return shell, sk


def fused_patches(K, kit_module, spots, seed, thick=0.05, inv='hide', name='armour_patches'):
    """issue 1291 (Ryan's "b"): chitin grown into the flesh on the lower flanks: small clusters of overlapping ridged plates,
    their roots sunk in the hide, the hide rolled round each cluster. spots = [(x, t, size, count)] in K.hpt's terms (t in
    the port convention, any side). Returns the plates object and the hide object."""
    register(kit_module)
    rng = random.Random(seed)
    mesh, attrs = ([], []), dict(scute_tone=[], scute_progress=[], scute_ridge=[])
    hide = ([], [])
    for (x0, t0, sz, cnt) in spots:
        for k in range(cnt):
            xr = x0 + sz * rng.uniform(-0.5, 0.6) - k * sz * 0.25
            tc = t0 + rng.uniform(-0.5, 0.5) * sz
            half = sz * rng.uniform(0.25, 0.42)
            vv, ff, gg, rr = _band(K.hpt, xr, sz * rng.uniform(0.45, 0.7), tc - half, tc + half, thick * rng.uniform(0.8, 1.2), rng,
                                   nu=8, nv=10, sink=0.02)
            _append(mesh, vv, ff)
            attrs['scute_tone'].extend([rng.uniform(0.2, 0.8)] * len(vv))
            attrs['scute_progress'].extend(gg)
            attrs['scute_ridge'].extend(rr)
        # the hide rolled round the cluster's fore edge (where the plates grow out of it)
        pts = [(x0 + sz * 0.62 + 0.04 * math.sin(a * 3), t0 + sz * 0.75 * math.sin(a)) for a in [(-1.3 + 2.6 * i / 8) for i in range(9)]]
        _append(hide, *_skirt(K.hpt, pts, 0.12, 0.012, rng))
    ob = K.hull_detail(name, mesh, 'carapace', inv=inv, kind='chitin', subs=['plate', 'rim', 'growth'])
    if ob is not None:
        K.mass('Grown chitin patches', ob, 'grown chitin', note='chitin grown into the flank flesh in small fused clusters (issue 1291)')
        _attributes(ob, attrs)
    hd = K.hull_detail(name + '_hide', hide, 'flesh2') if hide[1] else None
    return ob, hd
