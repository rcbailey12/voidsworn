"""Pure geometry checks shared by the Blender runner and ordinary Python tests."""
import math


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def axis(value):
    axes = {"+X": (1, 0, 0), "-X": (-1, 0, 0), "+Y": (0, 1, 0),
            "-Y": (0, -1, 0), "+Z": (0, 0, 1), "-Z": (0, 0, -1)}
    if value not in axes:
        raise ValueError("Use an explicit signed axis: +X, -X, +Y, -Y, +Z or -Z")
    return axes[value]


def frame(forward, up):
    f, u = axis(forward), axis(up)
    if dot(f, u):
        raise ValueError("Forward and up must be perpendicular")
    side = (u[1] * f[2] - u[2] * f[1], u[2] * f[0] - u[0] * f[2], u[0] * f[1] - u[1] * f[0])
    return f, u, side


def direction_status(vector, forward):
    if len(vector) != 3 or not all(math.isfinite(v) for v in vector):
        return "INVALID"
    length = math.sqrt(dot(vector, vector))
    if length <= 1e-12:
        return "INVALID"
    return "BACKWARD" if dot(vector, forward) / length < -0.05 else "FORWARD_OR_SIDE"


def mirror_error(a, b, side, center):
    rel = tuple(x - c for x, c in zip(a, center))
    depth = dot(rel, side)
    expected = tuple(a[i] - 2 * depth * side[i] for i in range(3))
    return math.dist(expected, b)
