"""Grown shell and bone for rounded Chorus sheets, in the build sheet's frame."""

import math
import random

from mathutils import Vector


MATERIALS = {
    'carapace': ((0.129, 0.102, 0.037), 0),
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
