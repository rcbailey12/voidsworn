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


def body_keepouts(K, sec_at, skip=(), keep=(), reach=0.3, bury=0.06, cell=(0.1, 0.06), margin=0):
    """the hull cells the shell must leave open: every outside mesh that is not hull skin (grp 'hull'), plus hull objects whose
    name starts with one of `keep` (grown-in features that stay bare, e.g. a face or a blade row), minus names starting with `skip`. Only the foot of a fitting counts, the part between `bury` under the skin and `reach` over it (a spine tip far
    out, or a root deep in the body, opens no hole). Returns blocked(x, th, side) with th in the port convention of K.hpt
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
            for a in range(-margin, margin + 1):
                for b in range(-margin, margin + 1):
                    occ[side].add((ix + a, it + b))
                    # a fitting on the belly or the back sits on both flanks' bands
                    if abs(th) > 1.35:
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


def _armour_scute(section, root, length, angles, t, side, point=0.22, bulge=0.35, wave=0.0, phase=0.0, nu=7, nv=10):
    """One armour scute (R341): a broad keratin plate lying aft, its root low on the skin and its free lip standing proud with a
    shadow gap under it, so the scute behind slides under it as a pangolin's do. The lip comes to a blunt point aft (`point`
    of its length), the face is crowned across, and the slab has real thickness at the lip. Returns (vertices, faces, growth)."""
    lo, hi = angles
    mid, half = 0.5 * (lo + hi), 0.5 * (hi - lo)
    row = nv + 1
    vertices, growth = [], []
    for under in (False, True):
        for i in range(nu + 1):
            a = i / nu
            for j in range(row):
                e = 2.0 * j / nv - 1.0
                reach = length * (1.0 - point * e * e)
                x = root - a * reach
                angle = mid + e * half * (1.0 - 0.10 * a) + 0.03 * wave * math.sin(phase + math.pi * a)
                gap = 0.004 + 0.45 * t * a ** 1.6
                thick = t * (0.55 - 0.12 * a) * (1.0 - 0.55 * e ** 4)
                h = gap if under else gap + thick * (1.0 + bulge * (1.0 - e * e))
                point_, _ = section(x, angle if side > 0 else math.pi - angle, out=h)
                vertices.append(point_)
                growth.append(a)
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
    return vertices, faces, growth


def armour_shell(section, blocked, x_bow, x_aft, seed, rows=6, scute=0.8, belly=-1.52, back=1.40, thick=0.1, lap=0.3, over=1.35):
    """Yield (side name, mesh, tones, growth) for the two flanks' shells: `rows` bands between the belly angle and the back
    angle (K.hpt's port convention), scutes about `scute` long, each band lapping `lap` of the band below it and offset half a
    scute from it. A scute any part of which would cover a blocked cell is left out, so a fitting stands in an open socket."""
    rng = random.Random(seed)
    span = (back - belly) / rows
    for side, name in ((1, 'port'), (-1, 'starboard')):
        mesh, tones, growth = ([], []), [], []
        placed = left = 0
        for r in range(rows):
            lo = belly + r * span - (lap * span if r else 0.0)
            hi = belly + (r + 1) * span
            x = x_bow - (0.5 * scute if r % 2 else 0.0) - rng.uniform(0.0, 0.15) * scute
            while x > x_aft:
                step = scute * rng.uniform(0.82, 1.18)
                todo = [(x, lo, hi, step, 0)]
                while todo:
                    x0, lo0, hi0, st, depth = todo.pop()
                    length = over * st
                    free = not any(blocked(x0 - fa * length, lo0 + fb * (hi0 - lo0), side)
                                   for fa in (0.05, 0.35, 0.65, 0.95) for fb in (0.08, 0.5, 0.92))
                    if not free:
                        if depth < 1:
                            # crowded here: try two smaller scutes a band-half each, so the shell
                            # closes round a fitting instead of leaving a whole scute's gap
                            mid = 0.5 * (lo0 + hi0) + 0.1 * (hi0 - lo0) * rng.uniform(-1, 1)
                            for a_lo, a_hi in ((lo0, mid + 0.12 * (hi0 - lo0)), (mid, hi0)):
                                todo.append((x0, a_lo, a_hi, st * 0.55, depth + 1))
                                todo.append((x0 - 0.5 * st, a_lo, a_hi, st * 0.55, depth + 1))
                        else:
                            left += 1
                        continue
                    placed += 1
                    vertices, faces, progress = _armour_scute(
                        section, x0, length, (lo0, hi0), thick * rng.uniform(0.85, 1.15) * (1.0 if depth == 0 else 0.8), side,
                        point=rng.uniform(0.28, 0.42), wave=rng.uniform(-1, 1), phase=rng.uniform(0, math.tau))
                    _append(mesh, vertices, faces)
                    tones.extend([rng.uniform(0.1, 0.9)] * len(vertices))
                    growth.extend(progress)
                x -= step
        print('[armour] %s: %d scutes, %d left open round fittings' % (name, placed, left), flush=True)
        yield name, mesh, tones, growth


def armour(K, kit_module, x_bow, x_aft, seed, drape=(), skip=(), keep=(), note='', inv='hide', **kw):
    """the whole-body shell on a Chorus sheet: keep-outs from the sheet's own fittings, both flanks' scutes as hull detail
    (structure: they tear with the hull, R226), the growth and tone attributes the paint stack reads. Returns the shell objects."""
    register(kit_module)
    blocked = body_keepouts(K, kit_module.sec_at, skip=skip, keep=keep)
    made = []
    for side, mesh, tones, growth in armour_shell(draped(K, drape) if drape else K.hpt, blocked, x_bow, x_aft, seed, **kw):
        shell = K.hull_detail('armour_' + side, mesh, 'carapace', inv=inv, kind='chitin', subs=['plate', 'rim', 'growth'])
        if shell is None:
            continue
        K.mass('Armour shell (' + side + ')', shell, 'brown keratin scutes',
               note=note or 'Banded overlapping scutes over the whole body, lips aft; fittings stand in open sockets (R341).')
        for nm, values in (('scute_tone', tones), ('scute_progress', growth)):
            attr = shell.data.attributes.new(nm, 'FLOAT', 'POINT')
            attr.data.foreach_set('value', values)
        made.append(shell)
    return made
