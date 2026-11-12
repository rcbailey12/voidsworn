# Shared geometry plumbing for the build-sheet part kits (issue 532, Eclipse sheets). Invisible plumbing only (R151, RULEBOOK
# 4.5): a part container, local frames and mesh primitives (revolve, prism, octagonal block, ring band, rod). No part shapes,
# no proportions, no paint: every faction kit (tools/blender/kits/<faction>/parts.py) draws its own parts with these.
# The same functions as the first kit (tools/blender/kits/hullbreakers/parts.py, which keeps its own copy so nothing it
# builds changes). Pure geometry: mathutils only, no bpy.
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


def rod(a, b, r, n=8, r1=None):
    a, b = Vector(a), Vector(b); d = b - a; L = d.length
    M = frame(a, d, d.orthogonal())
    return moved(revolve([(0, r), (L, r if r1 is None else r1)], n, cap0=True, cap1=True), M)




def detail_ok(subparts, kind, names):
    """True when every sub-part of a kit type is among the component names (prefix match; 'a|b' means either)"""
    need = subparts.get(kind, [])
    return all(any(any(n.split('_')[-1].startswith(alt) or n.startswith(alt) for n in names) for alt in req.split('|')) for req in need)
