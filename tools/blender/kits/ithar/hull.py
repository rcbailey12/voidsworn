"""The Glasswright (ithar) hull builders, shared by every fleet hull (issue 1415, R333: one kit, so every Glasswright gets the
same look and a fix lands on all of them).

CD5 (tools/blender/build_sheets/ships/ithar_CD5.py, r5c) is the reference of record and keeps its own copy of these steps, so
its accepted model and hash do not move. The four fleet hulls (Sliver, Lancet, Prism, Aperture; Ryan's Nov 16 picks in
contrib/muse/design/glasswright_family_2026_11/) build through this file:

  RibbonField     long pearl ribbons evenly round a body, twisting and swaying so the gaps between them are leaf windows,
                  and the gap a core point sits in (for the mosaic colours)
  mosaic_core     the opaque glowing mosaic core (the main colour of the ship), with optional seafoam stored light
  lay_ribbons     the pearl ribbons (real thickness, no solidify) and their silver edge lines
  turret_optic    a grown turning optic: a small pearl seat sunk in the ribbons and a cut stone (arc T)
  bow_optic       the ringed optic a lance or the shards come out of (three stepped pearl rings, silver lines, stored light)
  lance           the prism lance: a white core with a rainbow fringe out of a bow optic, fixed forward (pulsar F)
  shard_cluster   three short drawn needles gathered at the bow (shard F, the Prism shards)
  star_torpedo    a star torpedo: glowing capsule in a pointed pearl sheath with swept fins, on a keel cradle (startorp F)
  stern_drive     a grown stern optic: deep lens, white bloom, rose-cut face; no flame
  lens_bay        a hangar lens grown into a flank with parked Starlings on a glowing floor (data.js hangar)
  launch_tunnel   a ringed launch tunnel at the forward end of a bay, a Starling nosing out
  insides         decks, annealed frames and braided light cores, cut at every break; layered glass and light
  review/layout   the review renders and the build sheet pictures, manifest and feature table, from the ship module's records

The look (R337, Ryan Nov 19 2026): opaque reflective pearl ribbons with silver edges over glowing amber, violet and green mosaic
panels. Nothing is see-through on an intact hull.
"""
import hashlib
import json
import math
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[4]
SHEETS = ROOT / 'tools/blender/build_sheets'
TAU = 2 * math.pi

# Inside zones, seen only in the break-up (rgb, emission, roughness, transmission, metallic). Transmission is forced to 0.
ZONES = {
    'gw_in_frame': ((0.16, 0.24, 0.28), 0, 0.28, 0.0, 0.42),
    'gw_in_amber': ((0.95, 0.16, 0.006), 2.5, 0.13, 0.0, 0.0),
    'gw_in_violet': ((0.20, 0.002, 0.68), 2.8, 0.13, 0.0, 0.0),
    'gw_in_green': ((0.08, 0.43, 0.004), 2.3, 0.13, 0.0, 0.0),
    'gw_in_light': ((0.35, 1.0, 0.64), 3.0, 0.12, 0.0, 0.0),     # stored light, data glow #9fffd2
}
SEAFOAM = (0.35, 1.0, 0.64)


def gw_kit(name):
    """load a Glasswright kit module by path under its own name (another kit's parts.py may already be imported as `parts`)"""
    import importlib.util
    key = 'ithar_' + name
    if key not in sys.modules:
        spec = importlib.util.spec_from_file_location(key, ROOT / 'tools/blender/kits/ithar' / (name + '.py'))
        mod = importlib.util.module_from_spec(spec); sys.modules[key] = mod; spec.loader.exec_module(mod)
    return sys.modules[key]


# ------------------------------------------------------------------------------------------------------------ mesh helpers
def grid_surface(fn, nu, nv, u0, u1, v0=0.0, v1=TAU, wrap=True):
    verts = [fn(u0 + (u1 - u0) * i / nu, v0 + (v1 - v0) * j / nv)
             for i in range(nu + 1) for j in range(nv if wrap else nv + 1)]
    row = nv if wrap else nv + 1
    faces = [(i * row + j, i * row + (j + 1) % row, (i + 1) * row + (j + 1) % row, (i + 1) * row + j)
             for i in range(nu) for j in range(nv if wrap else nv)]
    return verts, faces


def ellipsoid(c, r, n=40, rings=20):
    return grid_surface(lambda u, v: (c[0] + r[0] * math.cos(u), c[1] + r[1] * math.sin(u) * math.cos(v),
                                     c[2] + r[2] * math.sin(u) * math.sin(v)), rings, n, 0.001, math.pi - 0.001)


def tube_mesh(points, radii, n=10):
    from mathutils import Vector
    vv, ff = [], []
    points = [Vector(p) for p in points]
    for i, p in enumerate(points):
        d = (points[min(i + 1, len(points) - 1)] - points[max(0, i - 1)]).normalized()
        q = d.cross(Vector((0, 0, 1))).normalized()
        if q.length < 0.1:
            q = d.cross(Vector((0, 1, 0))).normalized()
        w = d.cross(q).normalized()
        for j in range(n):
            a = j * TAU / n
            vv.append(tuple(p + radii[i] * (q * math.cos(a) + w * math.sin(a))))
    for i in range(len(points) - 1):
        for j in range(n):
            a, b = i * n + j, i * n + (j + 1) % n
            ff.append((a, b, b + n, a + n))
    ff += [tuple(range(n))[::-1], tuple(range((len(points) - 1) * n, len(points) * n))]
    return vv, ff


def thick_shell(ob, t, centre):
    """give an open surface real thickness t without a solidify modifier (CD5 r5c: a solidify is the contract's 'skin' and the
    export lines its back with a dark inside material that tears from its piece at every break). Back layer along the vertex
    normals (inward, or split either side when `centre`), walls on the open edges; point attributes copied to the back."""
    import bpy
    me = ob.data
    n = len(me.vertices)
    co = [v.co.copy() for v in me.vertices]
    nr = [me.vertex_normals[i].vector.copy() for i in range(n)]
    a, b = (0.5 * t, -0.5 * t) if centre else (0.0, -t)
    verts = [c + q * a for c, q in zip(co, nr)] + [c + q * b for c, q in zip(co, nr)]
    faces = [tuple(p.vertices) for p in me.polygons]
    faces += [tuple(v + n for v in reversed(f)) for f in faces]
    count = {}
    for f in me.polygons:
        vs = list(f.vertices)
        for i in range(len(vs)):
            e = tuple(sorted((vs[i], vs[(i + 1) % len(vs)])))
            count[e] = count.get(e, 0) + 1
    for f in me.polygons:
        vs = list(f.vertices)
        for i in range(len(vs)):
            u, w = vs[i], vs[(i + 1) % len(vs)]
            if count[tuple(sorted((u, w)))] == 1:
                faces.append((w, u, u + n, w + n))
    attrs = {}
    for at in me.attributes:
        if at.domain == 'POINT' and not at.name.startswith('.') and at.name != 'position':
            if at.data_type == 'FLOAT':
                vals = [0.0] * n; at.data.foreach_get('value', vals); attrs[at.name] = ('FLOAT', vals)
            elif at.data_type == 'FLOAT_COLOR':
                vals = [0.0] * (4 * n); at.data.foreach_get('color', vals); attrs[at.name] = ('FLOAT_COLOR', vals)
    mats = list(me.materials)
    new = bpy.data.meshes.new(me.name + '_thick')
    new.from_pydata([tuple(v) for v in verts], [], faces)
    for m in mats:
        new.materials.append(m)
    for name, (kind, vals) in attrs.items():
        if kind == 'FLOAT':
            new.attributes.new(name, 'FLOAT', 'POINT')
        else:
            new.color_attributes.new(name, 'FLOAT_COLOR', 'POINT')
    for name, (kind, vals) in attrs.items():   # fetch after creating all (adding one moves the others' storage)
        new.attributes[name].data.foreach_set('value' if kind == 'FLOAT' else 'color', vals + vals)
    for p in new.polygons:
        p.use_smooth = True
    ob.data = new
    new.update()


def smooth_group(K, fid):
    for o in K.coll.objects:
        if o.get('grp') == fid:
            for f in o.data.polygons:
                f.use_smooth = True


def own_part(kind='gun'):
    from kit import HP
    p = HP.Part(kind)
    p.type = 'gun'
    return p


def material_setup(code, length=26.0):
    """inside zones plus the shared Glasswright paint stack for every outside surface. The review mosaic keeps the bake's
    cell count per ship length (stack.cells_per_length(): craft of length 1.6 or less take the craft count, issue 1373), so the
    review shows the cells the game will show."""
    import kit
    stack = gw_kit('stack')
    for name, (rgb, em, rough, _trans, metal) in ZONES.items():
        kit.MATS[name] = (rgb, em)
        m = kit.mat(name)
        bs = m.node_tree.nodes.get('Principled BSDF')
        bs.inputs['Roughness'].default_value = rough
        bs.inputs['Metallic'].default_value = metal
        bs.inputs['Transmission Weight'].default_value = 0.0   # R337: nothing see-through, inside or out
    made = stack.setup(kit)
    k = 26.0 / length
    if 0 < length <= 1.6 + 1e-6:   # strike craft: the bake's bigger craft cells (stack.cells_per_length)
        k *= stack.CRAFT_CELLS_PER_LENGTH / stack.CELLS_PER_LENGTH
    for node in made['gw_mosaic'].node_tree.nodes:
        if node.type == 'TEX_VORONOI':
            node.inputs['Scale'].default_value *= k
    kit.KIT_NAME = '%s on the shared Glasswright kit (tools/blender/kits/ithar)' % code


# ------------------------------------------------------------------------------------------------------------ the ribbon field
class RibbonField:
    """n long ribbons spaced evenly round a body. Each follows base_k + twist(x); neighbours sway in opposite senses, so they
    meet and part and the gaps between them become leaf-shaped windows of mosaic (CD5 r5). gather(x, a) may draw every ribbon
    toward the bow optic."""

    def __init__(self, n, twist, sway=0.22, leaf_f=0.8, start=0.2, gather=None):
        self.n, self.twist, self.sway, self.leaf_f, self.start = n, twist, sway, leaf_f, start
        self.gather = gather or (lambda x, a: a)

    def base(self, k):
        return self.start + k * TAU / self.n

    def centre(self, k):
        b = self.base(k)
        return lambda x: self.gather(x, b + self.twist(x) + self.sway * math.sin(self.leaf_f * x + k * math.pi))

    def gap_of(self, x, a):
        """(gap, leaf coordinate along it, across 0..1): whole numbers along fall where two neighbours pinch together"""
        step = TAU / self.n
        u = ((a - self.start - self.twist(x)) % TAU) / step
        g = int(math.floor(u))
        f = u - g
        along = (self.leaf_f * x + g * math.pi - math.pi / 2) / math.pi + 0.45 * (f - 0.5)
        return g, along, f


def bow_gather(x0, x1, targets, strength=0.85):
    """ribbons forward of x0 draw toward the nearest target angle, fully by x1 (flames gathering to a point)"""
    def g(x, a):
        s = min(1.0, max(0.0, (x - x0) / (x1 - x0))) ** 1.6
        s = s * s * (3 - 2 * s)
        if s <= 0:
            return a
        best = min(targets, key=lambda t: abs(math.atan2(math.sin(t - a), math.cos(t - a))))
        d = math.atan2(math.sin(best - a), math.cos(best - a))
        return a + d * s * strength
    return g


def mosaic_core(K, name, skin, x0, x1, gap_of, nu=200, nv=128, thick=0.04, seed=0, light=None, v0=0.0, v1=TAU, wrap=True,
                grp=None, even=0.0, streak=False):
    """the opaque glowing mosaic core. light(x, a) -> 0..1 blends the panel to seafoam stored light (a cleft, a bay floor).
    even (0..1) evens each panel's glow toward a steady middle tone, so a pane-heavy hull (the Prism) reads as rows of lit
    panes rather than lit spots; 0 is the CD5 panel (hot middle, dark border). streak=True is parts.mosaic_tint's streak style
    for wide bodies whose whole bays show (the Prism, the W4b bomber)."""
    gw, stack = gw_kit('parts'), gw_kit('stack')
    vf = grid_surface(skin, nu, nv, x0, x1, v0, v1, wrap)
    hull = K._obj(name, *vf, 'gw_mosaic', smooth=True, grp=grp)
    hull.data.color_attributes.new('gw_tint', 'FLOAT_COLOR', 'POINT')
    hull.data.attributes.new('gw_glow', 'FLOAT', 'POINT')
    tint, glow = hull.data.attributes['gw_tint'], hull.data.attributes['gw_glow']   # fetch both after creating both
    row = nv if wrap else nv + 1
    for i in range(len(tint.data)):
        ix, ia = divmod(i, row)
        x = x0 + (x1 - x0) * ix / nu
        a = v0 + (v1 - v0) * ia / nv
        if even > 0:
            name_, g = gw.mosaic_tint(x, a, gap_of, stack.PALETTE, stack.WEIGHTS, seed=seed, tones=None, streak=streak)
            g = g + (0.55 + 0.45 * g - g) * even
            deep, hot = stack.TONES[name_]
            rgb = [d + (h - d) * g ** 1.5 for d, h in zip(deep, hot)]
        else:
            rgb, g = gw.mosaic_tint(x, a, gap_of, stack.PALETTE, stack.WEIGHTS, seed=seed, tones=stack.TONES, streak=streak)
        if light:
            w = max(0.0, min(1.0, light(x, a)))
            if w > 0:
                rgb = [c + (s * (0.80 + 0.20 * g) - c) * w for c, s in zip(rgb, SEAFOAM)]
                g = g + (1.0 - g) * w
        tint.data[i].color = tuple(rgb) + (1,)
        glow.data[i].value = g
    thick_shell(hull, thick, centre=False)
    return hull


def lay_ribbons(K, ribbons, skin, thick, silver_r, nu=160, nv=8, grp=None):
    """pearl ribbons with real thickness and a silver line along each edge"""
    obs = []
    for r in ribbons:
        vv, ff, attrs = r.mesh(skin, nu, nv)
        ob = K._obj(r.name, vv, ff, 'gw_pearl', smooth=True, grp=grp)
        for an in attrs:
            ob.data.attributes.new(an, 'FLOAT', 'POINT')
        for an, vals in attrs.items():
            ob.data.attributes[an].data.foreach_set('value', vals)
        thick_shell(ob, thick, centre=True)
        ob['zone'] = 'pearl ribbon'
        obs.append(ob)
        for side in (-1, 1):
            pts = r.edge(skin, side, nu)
            radii = [silver_r * (0.35 + 0.65 * math.sin(math.pi * i / nu) ** 0.4) for i in range(nu + 1)]
            K._obj(r.name + ('_silver_p' if side > 0 else '_silver_s'), *tube_mesh(pts, radii, 6), 'gw_silver', smooth=True,
                   grp=grp)
    return obs


def optic_clamp(optics, flat=0.02):
    """ribbons lie flat under each grown optic (optics: [(x, y, radius)]) so its turning lens stays clear"""
    def clamp(x, p, lift):
        for ox, oy, r in optics:
            d = ((x - ox) / r) ** 2 + ((p[1] - oy) / r) ** 2
            if d < 1 and p[2] > 0:
                lift = min(lift, flat + lift * d * d)
        return lift
    return clamp


# ------------------------------------------------------------------------------------------------------------ weapons
def turret_optic(K, fid, pos, weapon, colour, s=1.0, slot='T', note=''):
    """a grown turning optic (CD5 r5): a small flat pearl seat sunk in the ribbons and a cut stone on it, 360 degrees"""
    p = own_part()
    # The seat's top sits 0.08 under the pivot, clear of the barrel (as CD5, issue 1282): at -0.20 it met the barrel and the
    # game's clearance test locked GA1's O1 at rest (PC run, pin-1415b, Nov 20).
    p.add('integral_root', 'mount', 'gw_pearl', ellipsoid((0, 0, -0.28 * s), (0.42 * s, 0.42 * s, 0.20 * s), 48, 16))
    # round 2 (Ryan Nov 21): a lens you can see, as the picks' domes: a tall cut dome, a stored-light halo and a silver ring
    gv, gf = gw_kit('parts').cut_lens((0, 0, -0.02 * s), (0, 0, 1), 0.34 * s, 0.24 * s, 12)
    p.add('lens', 'turn', 'gw_gem_' + colour, (gv, gf))
    p.add('stored_light', 'turn', 'gw_gem_' + colour, ellipsoid((0, 0, -0.03 * s), (0.28 * s, 0.28 * s, 0.06 * s), 32, 12))
    halo = [(0.47 * s * math.cos(a), 0.47 * s * math.sin(a), -0.11 * s) for a in [TAU * i / 48 for i in range(49)]]
    p.add('halo', 'mount', 'gw_light', tube_mesh(halo, [0.05 * s] * 49, 10))
    p.add('halo_silver', 'mount', 'gw_silver', tube_mesh([(q[0] * 1.13, q[1] * 1.13, q[2] - 0.01 * s) for q in halo], [0.022 * s] * 49, 6))
    p.fit = dict(pivot=('p', (0, 0, 0)), reach=0.26 * s, radius=0.28 * s, muzzles=[('p', (0.26 * s, 0, 0))], aim=('d', (1, 0, 0)))
    K.gun(fid, pos, 0, cal=0.09 * s, blen=0.26 * s, slot=slot, weapon=weapon, part=p, inv=['optics'],
          band=(0, 5, 10, 15, 20, 30), note=note or 'Grown %s optic; the cut stone turns on a seat sunk in the ribbons, 360 degrees.' % colour)
    K.features[-1]['what'] = '%s grown optic / %s' % (colour, weapon)
    K.built[-1].update(detailed=True, subs=['grown root', 'cut dome', 'stored light', 'halo ring'])
    smooth_group(K, fid)


def bow_optic(p, R, x0=0.0, name='bow_optic'):
    """a grown ringed optic the lance or the shards come out of (the picks' bow rings): three stepped pearl rings, a silver
    line on each, and a disc of stored light inside them, facing forward from x0"""
    p.add(name + '_light', 'mount', 'gw_light', ellipsoid((x0, 0, 0), (0.14 * R, 0.92 * R, 0.92 * R), 40, 14))
    for k, (dx, rr, tr) in enumerate(((0.00, 1.00, 0.15), (0.12, 0.78, 0.12), (0.22, 0.58, 0.10))):
        ring = [(x0 + dx * R, rr * R * math.cos(a), rr * R * math.sin(a)) for a in [TAU * i / 48 for i in range(49)]]
        p.add('%s_ring%d' % (name, k), 'mount', 'gw_pearl', tube_mesh(ring, [tr * R] * 49, 12))
        p.add('%s_ring%d_silver' % (name, k), 'mount', 'gw_silver',
              tube_mesh([(q[0] + tr * R * 0.9, q[1], q[2]) for q in ring], [0.025 * R] * 49, 6))


def lance(K, fid, root, length, r0, weapon='pulsar', drop=0.0, spread=0.0, note='', what='drawn-glass forward Prism lance',
          collar=0.0):
    """the prism lance (faction sheet: the hull's stored light let out through the bow optic, a white core with a rainbow
    fringe). Round 2 (Ryan Nov 21, "what happened to the weapons"): a ringed bow optic, a short pearl sheath, then a white beam
    core wound with three thin amber, green and violet strands (the fringe), ending in a long faceted crystal point.
    spread: its sideways reach at the tip. collar: the bow optic's radius (0 picks one from r0)."""
    p = own_part()
    gw = gw_kit('parts')
    R = collar or 1.15 * r0
    bow_optic(p, R)
    pts, radii = [], []
    for i in range(101):
        t = i / 100
        pts.append((0.10 * R + length * t, spread * t, -drop * t + 0.18 * r0 * math.sin(math.pi * t)))
        radii.append(0.62 * r0 * (1 - 0.82 * t) ** 1.2)
    k_sheath = 34
    p.add('sheath', 'mount', 'gw_lance', tube_mesh(pts[:k_sheath + 1], [r * 1.18 for r in radii[:k_sheath + 1]], 24))
    lip = [(pts[k_sheath][0], pts[k_sheath][1] + radii[k_sheath] * 1.2 * math.cos(a), pts[k_sheath][2] + radii[k_sheath] * 1.2 * math.sin(a))
           for a in [TAU * i / 32 for i in range(33)]]
    p.add('sheath_lip', 'mount', 'gw_silver', tube_mesh(lip, [0.05 * r0] * 33, 6))
    p.add('beam_core', 'mount', 'gw_beam', tube_mesh(pts, radii, 20))
    for k, gem in enumerate(('gw_gem_amber', 'gw_gem_green', 'gw_gem_violet')):
        a0 = k * TAU / 3
        line = [(q[0], q[1] + r * 1.05 * math.cos(a0 + 5.5 * i / 100), q[2] + r * 1.05 * math.sin(a0 + 5.5 * i / 100))
                for i, (q, r) in enumerate(zip(pts, radii))][k_sheath - 4:]
        p.add('fringe_%d' % k, 'mount', gem, tube_mesh(line, [0.07 * r0] * len(line), 8))
    tip = pts[-1]
    cone = 0.30 * length
    tv, tf = gw.cut_lens((tip[0] - 0.02 * length, tip[1], tip[2]), (1, 0, 0), radii[-1] * 1.6, cone * 0.35, 6)
    p.add('crystal_point', 'mount', 'gw_beam', (tv, tf))
    end = (tip[0] - 0.02 * length + cone * 0.35, tip[1], tip[2])
    tr = 0.05 * r0
    p.add('aperture', 'mount', 'gw_tip', ellipsoid((end[0] - tr * 0.6, end[1], end[2]), (tr, tr * 1.1, tr * 1.1), 24, 10))
    p.fit = dict(pivot=('p', end), reach=0.06, radius=r0 * 1.03, muzzles=[('p', end)], aim=('d', (1, 0, 0)))
    K.gun(fid, root, 0, cal=0.06, blen=length, fixed=True, slot='F', weapon=weapon, part=p, inv=['forward_lances'],
          band=(0, 5, 10), note=note or 'Stored light let out through a ringed bow optic: white core, rainbow fringe; fixed forward, F arc +/-60.')
    K.features[-1]['what'] = what
    K.built[-1].update(detailed=True, subs=['ringed bow optic', 'pearl sheath', 'white beam core', 'rainbow fringe', 'crystal point'])
    smooth_group(K, fid)


def shard_cluster(K, fid, root, length, r0, n=3, spread=0.16, note=''):
    """the Prism shards (data.js shard F, three shots): n short drawn needles gathered at the bow on the centreline, each
    with its own glowing tip. One mount, n muzzles, every needle fires every volley."""
    p = own_part()
    tips = []
    for k in range(n):
        a = math.pi / 2 + k * TAU / n
        oy, oz = spread * math.cos(a), spread * math.sin(a)
        pts, radii = [], []
        for i in range(41):
            t = i / 40
            pts.append((length * t, oy * (0.35 + 0.65 * t), oz * (0.35 + 0.65 * t)))
            radii.append(r0 * (1 - t) ** 1.3 + 0.012 * r0 / 0.2)
        p.add('needle%d' % k, 'mount', 'gw_lance', tube_mesh(pts, radii, 16))
        line = [(q[0], q[1], q[2] + r * 0.9) for q, r in zip(pts, radii)]
        p.add('needle%d_vein' % k, 'mount', 'gw_silver', tube_mesh(line, [0.012 * r0 / 0.2] * len(line), 5))
        tip = pts[-1]
        tr = 0.03 * r0 / 0.2
        p.add('needle%d_tip' % k, 'mount', 'gw_tip', ellipsoid((tip[0] - tr * 0.5, tip[1], tip[2]), (tr, tr, tr), 16, 8))
        tips.append(tip)
    bow_optic(p, spread * 1.6 + r0 * 1.2, x0=-0.02 * length)
    # the gathered root: a pearl collar the needles grow from, sunk into the bow
    p.add('root', 'mount', 'gw_pearl', ellipsoid((0.02 * length, 0, 0), (0.18 * length, spread * 0.9 + r0, spread * 0.9 + r0), 32, 12))
    tc = tuple(sum(t[i] for t in tips) / len(tips) for i in range(3))
    p.fit = dict(pivot=('p', tc), reach=0.06, radius=spread + r0, muzzles=[('p', t) for t in tips], aim=('d', (1, 0, 0)))
    K.gun(fid, root, 0, cal=0.05, blen=length, fixed=True, slot='F', weapon='shard', part=p, inv=['bow_shards'], band=(0, 5, 10),
          note=note or 'The Prism shards: three drawn needles grown from the bow optic on the centreline; fixed forward, F arc.')
    K.features[-1]['what'] = 'three drawn-glass shard needles at the bow / shard'
    K.built[-1].update(detailed=True, subs=['grown collar', 'three needles', 'silver veins', 'glowing tips'])
    smooth_group(K, fid)


def _band(rad, x0, x1, a_of, hw, lift=1.05, depth=0.06, nu=40, nv=5):
    """a closed pearl band lying on a round body: rad(x) the body radius, a_of(x) the band's centre angle, hw its half
    width in radians; outer face at lift*rad, inner face depth*rad below it, side walls closed"""
    vv, ff = [], []
    for layer, k in ((0, lift), (1, lift - depth)):
        for i in range(nu + 1):
            x = x0 + (x1 - x0) * i / nu
            t = i / nu
            w = hw * max(0.15, math.sin(math.pi * (0.04 + 0.92 * t))) ** 0.5
            for j in range(nv + 1):
                a = a_of(x) + w * (-1 + 2 * j / nv)
                r = rad(x) * k
                vv.append((x, r * math.cos(a), r * math.sin(a)))
    row = nv + 1
    off = (nu + 1) * row
    for i in range(nu):
        for j in range(nv):
            a_, b_ = i * row + j, i * row + j + 1
            ff.append((a_, b_, b_ + row, a_ + row))
            ff.append((off + a_ + row, off + b_ + row, off + b_, off + a_))
    for i in range(nu):
        for j in (0, nv):
            a_, b_ = i * row + j, (i + 1) * row + j
            ff.append((a_, off + a_, off + b_, b_) if j == 0 else (b_, off + b_, off + a_, a_))
    for i in (0, nu):
        for j in range(nv):
            a_, b_ = i * row + j, i * row + j + 1
            ff.append((a_, b_, off + b_, off + a_) if i == 0 else (off + a_, off + b_, b_, a_))
    return vv, ff


def _band_w(rad, x0, x1, a_of, hw_of, lift=1.05, depth=0.06, nu=40, nv=5):
    """_band with its half width given per station: hw_of(t), t from 0 at x0 to 1 at x1"""
    vv, ff = [], []
    for layer, k in ((0, lift), (1, lift - depth)):
        for i in range(nu + 1):
            x = x0 + (x1 - x0) * i / nu
            w = hw_of(i / nu)
            for j in range(nv + 1):
                a = a_of(x) + w * (-1 + 2 * j / nv)
                r = rad(x) * k
                vv.append((x, r * math.cos(a), r * math.sin(a)))
    row = nv + 1
    off = (nu + 1) * row
    for i in range(nu):
        for j in range(nv):
            a_, b_ = i * row + j, i * row + j + 1
            ff.append((a_, b_, b_ + row, a_ + row))
            ff.append((off + a_ + row, off + b_ + row, off + b_, off + a_))
    for i in range(nu):
        for j in (0, nv):
            a_, b_ = i * row + j, (i + 1) * row + j
            ff.append((a_, off + a_, off + b_, b_) if j == 0 else (b_, off + b_, off + a_, a_))
    for i in (0, nu):
        for j in range(nv):
            a_, b_ = i * row + j, i * row + j + 1
            ff.append((a_, b_, off + b_, off + a_) if i == 0 else (off + a_, off + b_, b_, a_))
    return vv, ff


def _swept_fin(x0, x1, r_root, span, sweep, a, th, n=16):
    """a thin swept leaf fin standing off a round body at angle a: root chord x0..x1 at radius r_root(x), the outer edge
    reaching span out and swept sweep back (towards -x) at the tip; th its half thickness at the root"""
    ca, sa = math.cos(a), math.sin(a)
    na, nb = -sa, ca
    vv, ff = [], []
    for i in range(n + 1):
        t = i / n
        x = x0 + (x1 - x0) * t
        prof = math.sin(math.pi * t) ** 0.7 * (1.0 - 0.45 * t)
        reach = span * prof
        rr0 = r_root(x) * 0.92
        xo = x - sweep * prof * (1.0 - t * 0.3)
        for (px, rr, tt) in ((x, rr0, th), (xo, rr0 + reach, th * 0.25)):
            for sg in (1, -1):
                vv.append((px, rr * ca + sg * tt * na, rr * sa + sg * tt * nb))
    for i in range(n):
        b = i * 4
        ff += [(b, b + 4, b + 6, b + 2), (b + 1, b + 3, b + 7, b + 5), (b + 2, b + 6, b + 7, b + 3), (b, b + 1, b + 5, b + 4)]
    ff += [(0, 2, 3, 1), (4 * n, 4 * n + 1, 4 * n + 3, 4 * n + 2)]
    edge = []
    for i in range(n + 1):
        t = i / n
        x = x0 + (x1 - x0) * t
        prof = math.sin(math.pi * t) ** 0.7 * (1.0 - 0.45 * t)
        rr = r_root(x) * 0.92 + span * prof
        xo = x - sweep * prof * (1.0 - t * 0.3)
        edge.append((xo, rr * ca, rr * sa))
    return (vv, ff), edge


def star_torpedo(K, fid, pos, length, r0, cradle_up, note=''):
    """a star torpedo carried on the keel in a grown pearl cradle (startorp F). The cradle's two arms rise into the hull
    (cradle_up: how far above the torpedo axis the hull's underside sits), so it reads carried, not docked.

    Round 3 (Ryan Nov 21, "the torpedo underneath looks very simple and plain"), after the Lancet pick (I11_37): a bright
    stored-light capsule held in a pointed pearl sheath. The sheath opens in a long window down each flank so the capsule
    glows through (opaque, nothing see-through, R337); silver filigree runs along the sheath lips; a glowing needle tip at
    the nose; two swept canards forward, three big swept leaf fins aft (two flat, one under the keel, none upward into
    the hull), and a rose-cut drive lens with a white bloom at the tail."""
    p = own_part()
    gw = gw_kit('parts')
    L = length

    def rad(x):  # pointed at both ends, fuller forward of the middle (a seed pod)
        t = x / L + 0.5
        if t <= 0.0 or t >= 1.0:
            return r0 * 0.02
        return r0 * max(0.02, math.sin(math.pi * t ** 0.85)) ** 0.62

    # the capsule: stored light, with three silver bands so it reads as a made thing
    cx, cl = 0.02 * L, 0.36 * L
    p.add('star_capsule', 'mount', 'gw_light', ellipsoid((cx, 0, 0), (cl, r0 * 0.70, r0 * 0.70), 32, 14))
    for k, xr in enumerate((-0.22, 0.02, 0.24)):
        xx = cx + xr * L
        rr = r0 * 0.70 * max(0.05, 1 - ((xx - cx) / cl) ** 2) ** 0.5 * 1.04
        ring = [(xx, rr * math.cos(a), rr * math.sin(a)) for a in [TAU * i / 32 for i in range(33)]]
        p.add('star_capsule_band%d' % k, 'mount', 'gw_silver', tube_mesh(ring, [r0 * 0.035] * 33, 6))
    # the sheath: two pearl shells meeting fore and aft, a long window down each flank between them
    xa, xb = -0.50 * L, 0.50 * L
    def window(t):
        lo, hi = 0.20, 0.80
        if t <= lo or t >= hi:
            return 0.0
        return 0.95 * math.sin(math.pi * (t - lo) / (hi - lo)) ** 0.55
    for nm, ac in (('top', math.pi / 2), ('keel', -math.pi / 2)):
        p.add('star_sheath_%s' % nm, 'mount', 'gw_pearl',
              _band_w(rad, xa + 0.01 * L, xb - 0.01 * L, lambda x, ac=ac: ac, lambda t: math.pi / 2 + 0.02 - window(t),
                      1.0, 0.10, nu=64, nv=12))
    # silver filigree along each window lip, and a fine vine line down the sheath crown
    for side in (1, -1):
        for lip in (1, -1):
            line = []
            for i in range(49):
                t = 0.16 + 0.68 * i / 48
                x = xa + (xb - xa) * t
                a = (0.0 if side > 0 else math.pi) + lip * (window(t) + 0.02) * (1 if side > 0 else -1)
                line.append((x, rad(x) * 1.01 * math.cos(a), rad(x) * 1.01 * math.sin(a)))
            p.add('star_lip_%s%s' % ('p' if side > 0 else 's', 'u' if lip > 0 else 'd'), 'mount', 'gw_silver',
                  tube_mesh(line, [r0 * 0.028] * 49, 5))
    for nm, ac in (('top', math.pi / 2), ('keel', -math.pi / 2)):
        vine = []
        for i in range(61):
            t = 0.06 + 0.88 * i / 60
            x = xa + (xb - xa) * t
            a = ac + 0.35 * math.sin(TAU * 2.0 * t)
            vine.append((x, rad(x) * 1.012 * math.cos(a), rad(x) * 1.012 * math.sin(a)))
        p.add('star_vine_%s' % nm, 'mount', 'gw_silver', tube_mesh(vine, [r0 * 0.02] * 61, 5))
    # the nose: a glowing needle out of a pearl collar
    xn = 0.44 * L
    ring = [(xn, rad(xn) * 1.06 * math.cos(a), rad(xn) * 1.06 * math.sin(a)) for a in [TAU * i / 32 for i in range(33)]]
    p.add('star_nose_collar', 'mount', 'gw_silver', tube_mesh(ring, [r0 * 0.04] * 33, 6))
    needle = [(xn - 0.06 * L + 0.22 * L * i / 16, 0, 0) for i in range(17)]
    p.add('star_needle', 'mount', 'gw_light', tube_mesh(needle, [r0 * 0.20 * (1 - i / 16) ** 1.3 + r0 * 0.01 for i in range(17)], 12))
    # two swept canards forward, three big swept leaf fins aft (flat pair and one under the keel; nothing rises into the hull)
    for k, a in enumerate((0.0, math.pi)):
        fin, edge = _swept_fin(0.12 * L, 0.30 * L, rad, r0 * 0.75, 0.14 * L, a, r0 * 0.06)
        p.add('star_canard%d' % k, 'mount', 'gw_pearl', fin)
        p.add('star_canard%d_silver' % k, 'mount', 'gw_silver', tube_mesh(edge, [r0 * 0.022] * len(edge), 5))
    for k, a in enumerate((0.0, math.pi, -math.pi / 2)):
        fin, edge = _swept_fin(-0.34 * L, -0.02 * L, rad, r0 * (1.35 if k < 2 else 1.0), 0.26 * L, a, r0 * 0.08)
        p.add('star_fin%d' % k, 'mount', 'gw_pearl', fin)
        p.add('star_fin%d_silver' % k, 'mount', 'gw_silver', tube_mesh(edge, [r0 * 0.028] * len(edge), 6))
    # the tail drive: a rose-cut lens over a white bloom
    xe = -0.47 * L
    p.add('star_tail_bloom', 'mount', 'gw_beam', ellipsoid((xe, 0, 0), (0.03 * L, r0 * 0.30, r0 * 0.30), 18, 8))
    tv, tf = gw.cut_lens((xe - 0.01 * L, 0, 0), (-1, 0, 0), r0 * 0.34, r0 * 0.20, 8)
    p.add('star_tail_lens', 'mount', 'gw_drive_cut', (tv, tf))
    # the cradle: two hoops and four arms grown from the hull's belly
    for xs in (-0.28, 0.22):
        for side in (-1, 1):
            # the arms start above the flat fins and canards (round 3), so the cradle never touches them
            arm = [(xs * L + 0.04 * L * math.sin(math.pi * i / 12), side * r0 * (1.06 - 0.56 * i / 12),
                    r0 * 0.45 + (cradle_up - r0 * 0.45) * (i / 12) ** 0.8) for i in range(13)]
            p.add('cradle_%s_%d' % ('aft' if xs < 0 else 'fwd', side), 'mount', 'gw_pearl', tube_mesh(arm, [r0 * 0.20 * (1.0 - 0.3 * i / 12) for i in range(13)], 10))
        hoop = [(xs * L, r0 * 1.16 * math.cos(a), r0 * 1.16 * math.sin(a)) for a in [math.pi * (0.12 + 0.76 * i / 24) for i in range(25)]]
        p.add('cradle_hoop_%s' % ('aft' if xs < 0 else 'fwd'), 'mount', 'gw_pearl', tube_mesh(hoop, [r0 * 0.15] * 25, 10))
        p.add('cradle_hoop_%s_silver' % ('aft' if xs < 0 else 'fwd'), 'mount', 'gw_silver',
              tube_mesh([(q[0] + r0 * 0.15, q[1], q[2]) for q in hoop], [r0 * 0.03] * 25, 6))
    nose = (0.61 * L, 0, 0)
    p.fit = dict(pivot=('p', nose), reach=0.05, radius=r0 * 1.2, muzzles=[('p', nose)], aim=('d', (1, 0, 0)))
    K.gun(fid, pos, 0, cal=0.08, blen=L, fixed=True, slot='F', weapon='startorp', part=p, inv=['star_torpedo'], band=(0, 5),
          note=note or 'One star torpedo on the keel in a grown pearl cradle; fixed forward, F arc.')
    K.features[-1]['what'] = 'star torpedo carried in a grown keel cradle / startorp'
    K.built[-1].update(detailed=True, subs=['stored-light capsule with silver bands', 'pointed pearl sheath with a window down each flank',
                                            'silver filigree on the lips and crown', 'glowing needle nose in a silver collar',
                                            'two swept canards', 'three swept leaf fins', 'rose-cut tail drive', 'two cradle hoops and four arms'])
    smooth_group(K, fid)


# ------------------------------------------------------------------------------------------------------------ drive and bays
def stern_drive(K, fid, c, R, attach=None):
    """a grown stern optic at centre c (x is the grown body's middle), radius R: deep lens, white bloom and a rose-cut face
    over it, silver flow lines; propulsion only, no flame. Records the engine (exit at the cut face's apex)."""
    gw = gw_kit('parts')
    x, y, z = c
    face_x = x - 0.64 * R / 0.74 * 0.74
    ex = face_x - 0.38 * R
    ob = K._obj(fid + '_grown_stern', *ellipsoid((x, y, z), (0.85 * R, 0.93 * R, 0.98 * R), 64, 32), 'gw_pearl', smooth=True,
                grp=fid, role='mount')
    ob['part_kind'] = 'engine'; ob['machine'] = 1
    K._obj(fid + '_deep_lens', *ellipsoid((face_x - 0.07 * R, y, z), (0.13 * R / 0.74, 0.86 * R, 0.88 * R), 64, 32), 'gw_drive',
           smooth=True, grp=fid, role='mount')
    K._obj(fid + '_white_bloom', *ellipsoid((face_x - 0.08 * R, y, z), (0.18 * R / 0.74, 0.44 * R, 0.46 * R), 64, 32),
           'gw_drive_core', smooth=True, grp=fid, role='mount')
    K._obj(fid + '_cut_face', *gw.cut_lens((face_x, y, z), (-1, 0, 0), 0.80 * R, 0.38 * R, 10, 0.80 * R, 0.82 * R),
           'gw_drive_cut', grp=fid, role='mount')
    for j in range(11):
        a = j * TAU / 11
        pts = [(x + 0.855 * R * math.cos(u), y + 0.935 * R * math.sin(u) * math.cos(a), z + 0.985 * R * math.sin(u) * math.sin(a))
               for u in [0.07 + i * 3.0 / 32 for i in range(33)]]
        K._obj(fid + '_silver_flow_%02d' % j, *tube_mesh(pts, [0.014 * R / 0.74] * len(pts), 7), 'gw_silver', smooth=True,
               grp=fid, role='mount')
    if attach is not None:
        K._obj(fid + '_internal_feed', *tube_mesh([(x, y, z), attach], [0.07 * R / 0.74] * 2, 12), 'gw_pearl', smooth=True,
               grp=fid, role='mount')
    smooth_group(K, fid)
    K.features.append(dict(id=fid, kind='engine', what='grown stern drive optic, white bloom', count=1, pos=(ex, y, z),
                           exit=(ex, y, z), radius=0.86 * R, aim=(180, 0), src='picture',
                           note='Drive lens only; no flame, exhaust mesh or weapon.', inv=['stern_drive']))
    K.fitdata.append(dict(id=fid, kind='engine', cones=[dict(apex=(ex, y, z), dir=(-1, 0, 0), r0=0.86 * R, half=10,
                                                             length=max(2.0, K.length * 0.2))]))
    K.built.append(dict(id=fid, kind='engine', inv=['stern_drive'], shaped=True, detailed=True,
                        subs=['grown root', 'recessed lens', 'stored light', 'bloom']))


def lens_bay(K, fid, rim, floor, side, craft=3, s=1.0, hangar_index=0, launch=None):
    """a hangar lens grown into a flank (data.js hangar). The ship dents its own mosaic core into a shallow oval well whose
    floor carries seafoam stored light (so the well is opaque, never a view into the ship); this adds the pearl lip round the
    rim (rim: points on the skin, closed loop), its silver line, and `craft` parked Starlings on the floor.
    floor(u, w) -> the floor point at -1..1 along and across the well (for parking the craft)."""
    n = len(rim)
    K._obj(fid + '_lip', *tube_mesh(rim + [rim[0]], [0.10 * s] * (n + 1), 12), 'gw_pearl', smooth=True, grp=fid, role='mount')
    K._obj(fid + '_lip_silver', *tube_mesh([(p[0], p[1] + side * 0.085 * s, p[2]) for p in rim + [rim[0]]], [0.026 * s] * (n + 1), 6),
           'gw_silver', smooth=True, grp=fid, role='mount')
    for k in range(craft):
        u = -0.55 + 1.1 * k / max(1, craft - 1)
        w = 0.32 if k % 2 else -0.32
        c = floor(u, w)
        cl = 0.55 * s
        dart = grid_surface(lambda t, v: (c[0] + cl * (t - 0.5), c[1] + side * (0.05 * s + 0.10 * s * math.sin(math.pi * t) * max(0, math.sin(v))),
                                          c[2] + 0.28 * cl * math.sin(math.pi * t) ** 0.7 * (1 - 0.5 * t) * math.cos(v)), 12, 16, 0.0, 1.0)
        K._obj('%s_starling_%d' % (fid, k), *dart, 'gw_pearl', smooth=True, grp=fid, role='mount')
        gv, gf = gw_kit('parts').cut_lens((c[0] + 0.08 * cl, c[1] + side * 0.12 * s, c[2]), (0, side, 0), 0.07 * cl, 0.035 * cl, 6)
        K._obj('%s_starling_%d_eye' % (fid, k), gv, gf, 'gw_gem_amber', grp=fid, role='mount')
    mid = floor(0, 0)
    K.features.append(dict(id=fid, kind='bay', what='hangar lens grown into the %s flank, Starlings parked on stored light' %
                           ('port' if side > 0 else 'starboard'), count=1, pos=tuple(mid), src='picture',
                           note='data.js hangar: squadrons launch out of the flank lens', inv=['hangar_lenses']))
    K.built.append(dict(id=fid, kind='bay', inv=['hangar_lenses'], shaped=True, detailed=True,
                        subs=['pearl lip', 'silver line', 'stored light floor', '%d parked Starlings' % craft]))
    K.point('bay', 'hp_bay_%d' % hangar_index, tuple(launch or (mid[0], mid[1] + side * 0.06 * s, mid[2])),
            side='port' if side > 0 else 'stbd', note='flank hangar lens: Starlings launch outward', dir=(0.5, side * 0.87, 0))


def launch_tunnel(K, fid, c, R, facing=-1, s=1.0):
    """a round launch tunnel mouth (the carrier pick's ringed tube openings): three stepped pearl rings with silver lines, a
    deep stored-light throat and a Starling nosing out. c is the mouth centre; the tunnel runs along x, its mouth facing
    `facing` (-1 aft, +1 forward). Opaque: the throat is a lit floor, never a view into the ship."""
    x, y, z = c
    for k, (dx, rr, tr) in enumerate(((0.0, 1.0, 0.16), (-0.18, 0.80, 0.13), (-0.34, 0.62, 0.10))):
        ring = [(x - facing * dx * R, y + rr * R * math.cos(a), z + rr * R * math.sin(a)) for a in [TAU * i / 48 for i in range(49)]]
        K._obj('%s_ring%d' % (fid, k), *tube_mesh(ring, [tr * R] * 49, 12), 'gw_pearl', smooth=True, grp=fid, role='mount')
        K._obj('%s_ring%d_silver' % (fid, k), *tube_mesh([(q[0] + facing * tr * R * 0.9, q[1], q[2]) for q in ring], [0.03 * R] * 49, 6),
               'gw_silver', smooth=True, grp=fid, role='mount')
    K._obj(fid + '_throat', *ellipsoid((x - facing * 0.55 * R, y, z), (0.22 * R, 0.62 * R, 0.62 * R), 32, 12), 'gw_light',
           smooth=True, grp=fid, role='mount')
    cl = 0.50 * s
    cx = x - facing * 0.25 * R
    dart = grid_surface(lambda t, v: (cx + facing * cl * (t - 0.5), y + 0.10 * s * math.sin(math.pi * t) * math.cos(v) * 2.2,
                                      z + 0.08 * s * math.sin(math.pi * t) ** 0.7 * math.sin(v)), 12, 16, 0.0, 1.0)
    K._obj(fid + '_starling', *dart, 'gw_pearl', smooth=True, grp=fid, role='mount')
    K.built.append(dict(id=fid, kind='part', inv=['hangar_lenses'], shaped=True, detailed=True,
                        subs=['three stepped rings', 'silver lines', 'stored-light throat', 'a Starling nosing out']))


# ------------------------------------------------------------------------------------------------------------ insides
def insides(K, half_w, half_h, x0, x1, breaks, breach_x, decks=(-0.3, 0.2), frames=8, cores=True, s=1.0, y0=0.0, tag=''):
    """layered glass and light through the whole hull (R209): shaped decks (one span per compartment, a gap at every break),
    open annealed frames (off every break and breach bite), three braided light cores. half_w(x), half_h(x) are the core's
    half beam and half height at x; y0 offsets a twin hull."""
    GAP = 0.04 * K.length
    edges = [x0] + [v for b in breaks for v in (b - GAP, b + GAP)] + [x1]
    spans = [(edges[i], edges[i + 1]) for i in range(0, len(edges), 2)]
    for zf in decks:
        for si, (a, b) in enumerate(spans):
            n = max(4, int(40 * (b - a) / K.length))
            vv, ff = grid_surface(lambda x, t, zf=zf: (x, y0 + max(0.02, half_w(x) * math.sqrt(max(0.0, 1 - zf * zf)) - 0.06 * s) * t * 0.85,
                                                     zf * half_h(x)), n, 10, a, b, -1.0, 1.0, False)
            ob = K._obj('in%s_deck_%+.1f_%d' % (tag, zf, si), vv, ff, 'gw_in_frame', inside=True)
            ob.modifiers.new('shell', 'SOLIDIFY').thickness = 0.015 * K.length
        K.inside.append(dict(kind='deck', name='%sdeck at %.0f%% height' % (tag and tag + ' ', 50 + 50 * zf), z=zf, x=(edges[0], edges[-1]),
                             note='layered glass deck follows the leaf, one span per compartment'))
    clear_b, clear_r = 0.1 * K.length, 0.14 * K.length
    for i in range(frames):
        x = x0 + (x1 - x0) * (i + 0.5) / frames
        for _ in range(4):
            near = [b for b in breaks if abs(x - b) < clear_b] + [b for b in breach_x if abs(x - b) < clear_r]
            if not near:
                break
            lim = clear_b if near[0] in breaks else clear_r
            x = near[0] + (lim + 0.01) * (1 if x >= near[0] else -1)
        if not (x0 < x < x1) or any(abs(x - b) < clear_b for b in breaks) or any(abs(x - b) < clear_r for b in breach_x):
            continue
        pts = [(x, y0 + 0.8 * half_w(x) * math.cos(a), 0.8 * half_h(x) * math.sin(a)) for a in [TAU * j / 48 for j in range(49)]]
        K._obj('in%s_frame_%02d' % (tag, i), *tube_mesh(pts, [0.012 * K.length] * len(pts), 8), 'gw_in_frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name='%sannealed frame %02d' % (tag and tag + ' ', i), x=x, note='open structural glass frame'))
    if cores:
        for k, col in enumerate(('amber', 'violet', 'green')):
            for si, (a, b) in enumerate(spans):
                n = max(4, int(50 * (b - a) / K.length))
                pts = [(a + (b - a) * i / n, 0, 0) for i in range(n + 1)]
                pts = [(p[0], y0 + 0.30 * half_w(p[0]) * math.cos(p[0] * 2.2 / K.length * 6 + k * 2.1),
                        0.30 * half_h(p[0]) * math.sin(p[0] * 2.2 / K.length * 6 + k * 2.1)) for p in pts]
                K._obj('in%s_light_core_%s_%d' % (tag, col, si), *tube_mesh(pts, [0.012 * K.length] * len(pts), 10), 'gw_in_' + col,
                       inside=True, smooth=True)
        K.inside.append(dict(kind='space', name='%scontinuous light core' % (tag and tag + ' '), x=(x0, x1), y=(y0 - 0.3, y0 + 0.3),
                             z=(-0.3, 0.3), mat='layered glass and light', note='three braided waveguides of amber, violet and green light'))
    return spans


def ragged_break(K, name, x, width, note, jitter=None):
    j = jitter if jitter is not None else 0.02 * K.length
    path = [(x + dx * j / 0.13, y * width / 6) for dx, y in ((0, -6), (0.13, -3), (-0.12, -1.4), (0.09, 0), (-0.14, 1.3), (0.12, 3), (0, 6))]
    K.break_line(name, x, note, path=path)


# ------------------------------------------------------------------------------------------------------------ review renders
def mosaic_share(objs, res=160):
    """R431 (Ryan Nov 23 2026): the share of the visible outside that is bare stained glass (gw_mosaic), by rays from the top,
    the side and the battle camera's tilt (34 degrees up), over the hull's bounding box. Every Glasswright hull reads as I8_37:
    a pearl shell with the coloured glass only in the seams and openings, so this stays at or under stack.MOSAIC_MAX."""
    import bpy
    from mathutils import Vector
    objs = [o for o in objs if o.type == 'MESH']
    names = {o.name for o in objs}
    lo = Vector([min((o.matrix_world @ Vector(c))[i] for o in objs for c in o.bound_box) for i in range(3)])
    hi = Vector([max((o.matrix_world @ Vector(c))[i] for o in objs for c in o.bound_box) for i in range(3)])
    ctr, size = (lo + hi) / 2, max(hi - lo)
    dg = bpy.context.evaluated_depsgraph_get()
    sc = bpy.context.scene
    out = {}
    for name, az, el in (('top', 270, 90), ('side', 270, 0), ('battle', 250, 34)):
        a, e = math.radians(az), math.radians(el)
        d = Vector((math.cos(e) * math.cos(a), math.cos(e) * math.sin(a), math.sin(e)))
        u = Vector((0, 0, 1)).cross(d) if abs(d.z) < 0.99 else Vector((1, 0, 0))
        u.normalize(); v = d.cross(u); v.normalize()
        hits = glass = 0
        for i in range(res):
            for j in range(res // 2):
                p = ctr + d * size * 2 + u * size * 0.6 * (2 * i / res - 1) + v * size * 0.3 * (4 * j / res - 1)
                ok, _, _, idx, ob, _ = sc.ray_cast(dg, p, -d)
                if not ok or ob.name not in names:
                    continue
                hits += 1
                mats = ob.data.materials
                ev = ob.evaluated_get(dg).data
                mi = ev.polygons[idx].material_index if 0 <= idx < len(ev.polygons) else 0
                if mi < len(mats) and mats[mi] and mats[mi].name == 'gw_mosaic':
                    glass += 1
        if hits < res * res // 20:   # the hull must fill a fair part of the frame; a near-empty view is a broken measure, not a pass
            raise ValueError('mosaic_share: only %d of %d rays hit the hull from the %s view' % (hits, res * res // 2, name))
        out[name] = round(glass / hits, 3)
    return out


def mosaic_gate(K, code):
    """R431: measure the bare-glass share and stop the build above stack.MOSAIC_MAX (the review and the recipe's stage 4 build,
    tools/blender/r209/sheet_hull.py, both call this, so no Glasswright hull exports over it)"""
    share = mosaic_share(list(K.coll.objects))
    cap = gw_kit('stack').MOSAIC_MAX
    print('MOSAIC SHARE', code, share, 'max', cap)
    if max(share['top'], share['battle']) > cap:
        raise ValueError('R431: %s shows %s bare stained glass from above or the battle camera (max %.2f); widen the pearl '
                         'so the glass shows only in the seams (kit README)' % (code, share, cap))
    return share


def review(mod, out):
    import bpy
    from mathutils import Vector
    sys.path[:0] = [str(SHEETS), str(ROOT / 'tools/recipe')]
    import variants, weapon_match, clash, contract
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    game = next((a.split('=')[1] for a in sys.argv if a.startswith('--variant=')), None)
    K = variants.build(mod, game)
    bpy.context.view_layer.update()
    gs = K.game_ship or mod.GAME_SHIP
    match, probs = weapon_match.run(K, gs)
    (out / 'weapon_match.json').write_text(json.dumps(match, indent=2))
    if probs:
        raise ValueError(probs)
    fit = clash.run(K, str(out), mod.CODE, mod.LENGTH)
    (out / 'fit.json').write_text(json.dumps(fit, indent=2))
    if any(fit['counts'].values()):
        raise ValueError('Fit failed: ' + str(fit['counts']))
    share = mosaic_gate(K, mod.CODE)   # R431: pearl shell, glass only in the seams
    dg = bpy.context.evaluated_depsgraph_get()

    def cost(coll):
        tris, surfaces, mats = 0, 0, set()
        for o in coll.objects:
            if o.type != 'MESH':
                continue
            ev = o.evaluated_get(dg); me = ev.to_mesh(); me.calc_loop_triangles()
            tris += len(me.loop_triangles)
            used = {p.material_index for p in me.polygons}
            surfaces += len(used)
            mats.update(o.data.materials[i].name for i in used if i < len(o.data.materials))
            ev.to_mesh_clear()
        return dict(triangles=tris, unjoined_surfaces=surfaces, material_surfaces=len(mats), materials=sorted(mats))
    budget = dict(outside=cost(K.coll), inside=cost(K.cin),
                  note='unjoined material surfaces are draw submissions; joined-by-material is an estimate only; no game frame measurement')
    lo, hi = contract._bbox([o for o in K.coll.objects if o.type == 'MESH'])
    groups = {fid: [o.name for o in K.coll.objects if o.type == 'MESH' and o.get('grp') == fid]
              for fid in [f['id'] for f in K.features]}
    if not all(groups.values()):
        raise ValueError('A recorded part has no actual meshes: %s' % [k for k, v in groups.items() if not v])
    model = dict(code=mod.CODE, name=mod.NAME, game_ship=gs, cls=mod.CLASS, length=mod.LENGTH, camera=mod.CAMERA,
                 features=K.features, masses=K.masses, inside=K.inside, points=K.points, changes=K.changes, budget=budget,
                 mesh_groups=groups, mosaic_share=share, dimensions=[float(hi[i] - lo[i]) for i in range(3)],
                 design_sha256=hashlib.sha256(Path(mod.__file__).read_bytes()).hexdigest(),
                 kit_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    (out / 'model.json').write_text(json.dumps(model, indent=2))
    recipe = dict(sheet=mod.CODE, game_ship=gs, faction='ithar', cls=mod.CLASS, length_world=mod.LENGTH, bake='none')
    (out / 'ship.json').write_text(json.dumps(recipe, indent=2))
    for o in K.cin.objects:
        o.hide_render = True
    bpy.ops.wm.save_as_mainfile(filepath=str(out / (mod.CODE + '_blockout.blend')))
    record = contract.to_recipe(K, recipe)
    (out / 'contract.json').write_text(json.dumps(record, indent=2))
    bpy.ops.wm.save_as_mainfile(filepath=str(out / (mod.CODE + '_contract.blend')))
    bpy.ops.wm.open_mainfile(filepath=str(out / (mod.CODE + '_blockout.blend')))
    sc = bpy.context.scene
    if '--checks-only' in sys.argv:
        return
    L = mod.LENGTH
    sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'
    sc.cycles.samples = next((int(a.split('=')[1]) for a in sys.argv if a.startswith('--samples=')), 32)
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 8; sc.cycles.transmission_bounces = 6
    sc.render.resolution_x = 1280; sc.render.resolution_y = 640; sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = 'PNG'; sc.render.film_transparent = False
    sc.view_settings.view_transform = 'AgX'
    sc.view_settings.look = 'AgX - Medium High Contrast'
    sc.use_nodes = True
    nodes = sc.node_tree.nodes; nodes.clear()
    layer = nodes.new('CompositorNodeRLayers')
    glow = nodes.new('CompositorNodeGlare'); glow.glare_type = 'FOG_GLOW'
    glow.quality = 'HIGH'; glow.threshold = 1.5; glow.size = 7; glow.mix = -0.85
    composite = nodes.new('CompositorNodeComposite')
    sc.node_tree.links.new(layer.outputs['Image'], glow.inputs['Image'])
    sc.node_tree.links.new(glow.outputs['Image'], composite.inputs['Image'])
    world = bpy.data.worlds.new('Glasswright dark studio'); sc.world = world; world.use_nodes = True
    world.node_tree.nodes['Background'].inputs[0].default_value = (0.007, 0.010, 0.016, 1)
    world.node_tree.nodes['Background'].inputs[1].default_value = 0.24
    wn, wl = world.node_tree.nodes, world.node_tree.links
    room = wn.new('ShaderNodeBackground'); room.inputs[0].default_value = (0.32, 0.28, 0.27, 1); room.inputs[1].default_value = 1.0
    path = wn.new('ShaderNodeLightPath'); mixw = wn.new('ShaderNodeMixShader')
    wl.new(path.outputs['Is Camera Ray'], mixw.inputs[0]); wl.new(room.outputs[0], mixw.inputs[1])
    wl.new(wn['Background'].outputs[0], mixw.inputs[2]); wl.new(mixw.outputs[0], wn['World Output'].inputs['Surface'])
    k = L / 26.0

    def area(name, pos, energy, size, colour):
        ld = bpy.data.lights.new(name, 'AREA'); ld.energy = energy * k * k; ld.shape = 'RECTANGLE'
        ld.size = size * k; ld.size_y = size * k * 0.14; ld.color = colour
        ob = bpy.data.objects.new(name, ld); sc.collection.objects.link(ob); ob.location = Vector(pos) * k
        ob.rotation_euler = (-ob.location).to_track_quat('-Z', 'Y').to_euler()
    area('long pearl reflection', (0, -8, 13), 1400, 22, (1.0, 0.92, 0.85))
    area('warm inner light reflection', (3, 7, 9), 2000, 18, (1.0, 0.65, 0.31))
    area('stern edge reflection', (-10, 2, 4), 1800, 12, (0.85, 0.85, 1.0))
    cd = bpy.data.cameras.new('review camera'); cam = bpy.data.objects.new('review camera', cd)
    sc.collection.objects.link(cam); sc.camera = cam
    view = L * 1.12

    def render(name, az, el, scale, roll=0, target=(0, 0, 0), perspective=False, distance=None):
        selected = next((a.split('=')[1].split(',') for a in sys.argv if a.startswith('--views=')), None)
        if selected and name not in selected:
            return
        az, el = math.radians(az), math.radians(el)
        d = distance or (170 if perspective else 6 * L)
        cam.location = Vector(target) + Vector((math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el))) * d
        cam.rotation_euler = (Vector(target) - cam.location).to_track_quat('-Z', 'Y').to_euler()
        cam.rotation_euler.rotate_axis('Z', math.radians(roll))
        cd.type = 'PERSP' if perspective else 'ORTHO'; cd.ortho_scale = scale
        cd.sensor_fit = 'VERTICAL' if perspective else 'HORIZONTAL'; cd.sensor_height = 24
        cd.lens = 24 / (2 * math.tan(math.radians(45) / 2))
        cd.clip_end = 1000
        sc.render.filepath = str(out / (name + '.png'))
        bpy.ops.render.render(write_still=True)
        if name == 'concept_camera':
            bpy.ops.wm.save_as_mainfile(filepath=str(out / (mod.CODE + '_review.blend')))
    c = mod.CAMERA
    render('concept_camera', c['az'], c['el'], c['scale'] * k, c.get('roll', 0))
    cl = getattr(mod, 'CLOSE', dict(daz=15, del_=6, scale=0.42, target=(-0.2, 0, 0.03)))
    render('close', c['az'] + cl['daz'], c['el'] + cl['del_'], cl['scale'] * L, c.get('roll', 0), target=tuple(v * L for v in cl['target']))
    render('top', 270, 90, view)
    render('side', 270, 0, view)
    render('underside', 270, -90, view)
    render('bow', 0, 0, view)
    render('stern', 180, 0, view)
    ship_k = 1.6   # SHIP_K: the drawn size on the board
    for ob in bpy.data.collections[mod.CODE].objects:
        if ob.parent is None:
            ob.scale *= ship_k; ob.location *= ship_k
    sc.render.resolution_x = 1920; sc.render.resolution_y = 1080
    render('camera170', 270, 90 - math.degrees(0.98), view, perspective=True)
    sc.render.resolution_x = 1280; sc.render.resolution_y = 640
    for ob in bpy.data.collections[mod.CODE].objects:
        if ob.parent is None:
            ob.scale /= ship_k; ob.location /= ship_k
    for ob in bpy.data.collections[mod.CODE + '_inside'].objects:
        ob.hide_render = False
    for ob in bpy.data.collections[mod.CODE].objects:
        ob.hide_render = True
    render('inside', 248, 35, view)


# ------------------------------------------------------------------------------------------------------------ sheet layout
def _fonts():
    from PIL import ImageFont
    for path in ('C:/Windows/Fonts/segoeui.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'):
        if Path(path).exists():
            return (ImageFont.truetype(path, 19), ImageFont.truetype(path, 15), ImageFont.truetype(path, 27))
    f = ImageFont.load_default()
    return f, f, f


def layout(mod, src, dest):
    from PIL import Image, ImageDraw, ImageOps
    sys.path.insert(0, str(ROOT / 'tools'))
    from picture_provenance import save_picture
    dest.mkdir(parents=True, exist_ok=True)
    model = json.loads((src / 'model.json').read_text())
    rev = model['design_sha256'][:12]
    font, small, title = _fonts()
    bg, ink = '#09111c', '#dce7ec'
    L = mod.LENGTH
    view = L * 1.12
    tag = '%s r%d' % (mod.SHORT, mod.SHEET['version'])

    def canvas(label):
        im = Image.new('RGB', (1280, 720), bg)
        d = ImageDraw.Draw(im)
        d.text((24, 14), '%s / %s' % (tag, label), fill=ink, font=title)
        d.text((24, 51), 'Issue 1415 | %s | %s | design %s | SHEET BUILT (Blender review, not in game)' % (mod.NAME, mod.PICK, rev),
               fill='#a9bdc9', font=small)
        return im

    def put(im, path, box):
        pic = Image.open(path).convert('RGB')
        pic = ImageOps.contain(pic, (box[2] - box[0], box[3] - box[1]), Image.Resampling.LANCZOS)
        im.paste(pic, (box[0] + (box[2] - box[0] - pic.width) // 2, box[1] + (box[3] - box[1] - pic.height) // 2))

    def save(im, name):
        save_picture(im, dest / name, 'sheet built', quality=94)
    Image.open(ROOT / mod.BEAUTY).convert('RGB').save(dest / 'concept.jpg', quality=92)   # the recipe's stage 1 input
    im = canvas('Ryan\'s Nov 16 pick beside the build')
    put(im, ROOT / mod.BEAUTY, (12, 92, 630, 566))
    put(im, src / 'concept_camera.png', (638, 92, 1268, 566))
    d = ImageDraw.Draw(im)
    d.text((24, 82), 'RYAN\'S PICK (%s), a see-through sketch' % mod.PICK, fill=ink, font=font)
    d.text((650, 82), 'BUILD, R337 finish: opaque pearl over glowing mosaic', fill=ink, font=font)
    for i, line in enumerate(mod.COMPARE_NOTE):
        d.text((24, 578 + 28 * i), line, fill=ink, font=font if i == 0 else small)
    save(im, 'compare.jpg')
    im = canvas('close / pearl ribbons, silver lines, glowing panels')
    put(im, src / 'close.png', (0, 76, 1280, 610))
    save(im, 'close.jpg')
    for name, caption, text in (('side', 'side', 'True side view. ' + mod.SIDE_NOTE),
                                ('camera170', 'battle camera / drawn size %.1f' % (L * 1.6),
                                 'Blender stand-in for the battle camera: radius 170, field 45, tilt 0.98, drawn size %.1f. Not the game.' % (L * 1.6)),
                                ('inside', 'inside / layered glass and light', mod.INSIDE_NOTE)):
        im = canvas(caption)
        if name == 'camera170':
            raw = Image.open(src / 'camera170.png').convert('RGB')
            w, h = raw.size
            crop = raw.crop((w // 2 - 640, h // 2 - 250, w // 2 + 640, h // 2 + 250))
            im.paste(crop, (0, 76))
            # an inset at 4x so the ship can be read; the main frame stays 1:1
            z = raw.crop((w // 2 - 110, h // 2 - 55, w // 2 + 110, h // 2 + 55)).resize((440, 220), Image.Resampling.LANCZOS)
            im.paste(z, (820, 96))
            d = ImageDraw.Draw(im)
            d.rectangle((820, 96, 1260, 316), outline='#a9bdc9', width=2)
            d.text((830, 322), 'inset: the same frame at 4x', fill=ink, font=small)
        else:
            put(im, src / (name + '.png'), (0, 76, 1280, 590))
        ImageDraw.Draw(im).text((24, 598), text, fill=ink, font=small)
        save(im, name + '.jpg')
    im = canvas('true views / one model, one scale')
    d = ImageDraw.Draw(im)
    for name, label, x, y in (('top', 'TOP', 30, 112), ('side', 'SIDE', 660, 112), ('underside', 'UNDERSIDE', 30, 300),
                              ('bow', 'BOW', 660, 300), ('stern', 'STERN', 660, 488)):
        raw = Image.open(src / (name + '.png')).resize((550, 275), Image.Resampling.LANCZOS)
        im.paste(raw.crop((0, 52, 550, 222)), (x, y))
        d.text((x, y - 25), label, fill=ink, font=font)
    unit = max(1, round(L / 6.5))
    d.line((48, 548, 48 + round(unit * 550 / view), 548), fill=ink, width=3)
    d.text((48, 566), '%d world unit%s / %.2f px per unit in every view' % (unit, '' if unit == 1 else 's', 550 / view), fill=ink, font=small)
    d.text((48, 598), '%s %.1f long / drawn %.1f on the board' % (mod.CLASS, L, L * 1.6), fill=ink, font=font)
    save(im, 'sheet.jpg')
    fit = json.loads((src / 'fit.json').read_text())
    im = canvas('fit / firing arcs and drive clearance')
    put(im, src / 'top.png', (0, 76, 1280, 500))
    d = ImageDraw.Draw(im)
    d.text((24, 507), 'Fit counts: ' + str(fit['counts']), fill=ink, font=font)
    d.text((24, 539), 'Grown roots touch the skin; turning stones clear it through a full turn; forward weapons +/-60 degrees.', fill=ink, font=font)
    d.text((24, 570), 'Drive lens clearance: aft cones, 10-degree half angle. Sampled arcs are in fit.json.', fill=ink, font=font)
    save(im, 'fit_view.jpg')
    for name in ('weapon_match.json', 'fit.json', 'contract.json', 'model.json'):
        (dest / name).write_bytes((src / name).read_bytes())
    station = lambda x: (L / 2 - x) / L * 100
    fractures = [r for r in model['inside'] if r['kind'] == 'break']
    tr = sorted((r for r in fractures if r.get('orient') != 'long'), key=lambda r: -r['x'])
    edges = [L / 2] + [r['x'] for r in tr] + [-L / 2]
    names = ['bow piece'] + ['midships piece %d' % i for i in range(1, len(tr))] + ['stern piece']
    pieces = [dict(name=nm, stations='%.3f to %.3f percent' % (station(a), station(b)),
                   bounded_by=[r['name'] for r in tr if r['x'] in (a, b)], full_interior=True)
              for nm, a, b in zip(names, edges, edges[1:])]
    design = 'tools/blender/build_sheets/ships/%s.py' % mod.CODE
    manifest = dict(code=mod.CODE, sheet_version=mod.SHEET['version'], design=design, design_sha256=model['design_sha256'],
                    kit='tools/blender/kits/ithar/hull.py', game_ship=model['game_ship'], cls=mod.CLASS, length_world=L,
                    routes_note='Every visible part is hand-built in the sheet on the shared Glasswright kit (tools/blender/kits/ithar).',
                    parts=[dict(id=f['id'], kind=f['kind'], what=f['what'], route='hand-built', count=f['count'], source=f['src'],
                                inventory=f.get('inv', []), weapon=f.get('weapon'), arc=f.get('slot')) for f in model['features']],
                    masses=[dict(name=m['name'], route='hand-built') for m in model['masses']],
                    break_pieces=pieces,
                    whole_optics=[dict(name=f['id'] + ' whole part', part=f['id'], objects=model['mesh_groups'][f['id']], full_interior=True,
                                       attachment='separate whole group, grown into its parent skin') for f in model['features']],
                    hull_fractures=fractures, insides=mod.INSIDE_NOTE, budget=model['budget'], stage='sheet built',
                    paint_stack='tools/blender/kits/ithar/stack.py')
    for part in manifest['parts']:
        if part['kind'] == 'gun':
            part['turret'] = part['arc'] == 'T'
            if part['turret']:
                part.update(pivot_object=part['id'] + '_turret', arc_lo=-180.0, arc_hi=180.0)
    (dest / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    hash_ok = hashlib.sha256(Path(mod.__file__).read_bytes()).hexdigest() == model['design_sha256']
    assert hash_ok, 'Model is stale: rebuild after editing the design'
    lines = ['# %s feature table' % mod.SHORT, '', 'Revision r%d. Generated from the same Blender model as the pictures. Counts outrank pictures.' % mod.SHEET['version'], '',
             '## Feature table', '', '| ID | Fitting | Count | Weapon arc | Route |', '|---|---|---:|---|---|']
    for f in model['features']:
        lines.append('| %s | %s | %s | %s | hand-built |' % (f['id'], f['what'], f['count'],
                                                            (f.get('weapon') or f['kind']) + ' ' + (f.get('slot') or ('aft' if f['kind'] == 'engine' else 'flank'))))
    lines += ['', '## Size', '', '%s LENGTH %.1f; drawn %.1f with SHIP_K 1.6. Measured mesh length / beam / height: ' % (mod.CLASS, L, L * 1.6) +
              ' / '.join('%.3f' % n for n in model['dimensions']) + '.', '', '## Major masses', '', '| Mass | Route |', '|---|---|']
    for m in manifest['masses']:
        lines.append('| %s | %s |' % (m['name'], m['route']))
    nb = len([p for p in model['points'] if p['kind'] == 'breach'])
    lines += ['', '## INSIDE', '', mod.INSIDE_NOTE,
              '%d breach anchor%s (class base minus the Glasswright one), one core, two RCS and two boarding origins.' % (nb, '' if nb == 1 else 's'), '',
              '| Break line | Station % | What it opens |', '|---|---|---|']
    for r in fractures:
        lines.append('| %s | %.3f | %s |' % (r['name'], station(r['x']), r['note']))
    lines += ['', 'Whole parts are listed separately in manifest.json whole_optics.',
              'break_pieces names the hull compartments made by these paths, each with its share of the full interior.', '',
              '## Changed from the picture', '']
    for what, why in model['changes']:
        lines += ['- ' + what + '. ' + why]
    (dest / 'feature_table.md').write_text('\n'.join(lines) + '\n')
    b = model['budget']
    readme = ['# %s: %s' % (mod.SHORT, mod.NAME), '',
              'Issue 1415 (R368). Stage: **sheet built** (Blender review renders, not in the game), revision **r%d**, design %s.' % (mod.SHEET['version'], rev),
              'Built from Ryan\'s Nov 16 pick %s (contrib/muse/design/glasswright_family_2026_11/, PR 942) in the R337 finish on the' % mod.PICK,
              'shared Glasswright kit: opaque pearl ribbons with silver edges over glowing amber, violet and green mosaic; nothing see-through.', '',
              '![%s beside the pick](compare.jpg)' % mod.SHORT, '',
              'Review: [close](close.jpg), [side](side.jpg), [battle camera stand-in](camera170.jpg), [true views](sheet.jpg),',
              '[inside](inside.jpg), [fit](fit_view.jpg). [Feature table](feature_table.md), [manifest](manifest.json).', '',
              'Design: [%s.py](../../../../tools/blender/build_sheets/ships/%s.py) on [hull.py](../../../../tools/blender/kits/ithar/hull.py).' % (mod.CODE, mod.CODE),
              'Recipe ship file: tools/recipe/ships/%s.json (game code %s).' % (mod.CODE, json.loads((ROOT / ('tools/recipe/ships/%s.json' % mod.CODE)).read_text())['game_code']), '',
              'Budget (Blender, before the recipe): outside %d triangles, inside %d; %d material surfaces outside.' %
              (b['outside']['triangles'], b['inside']['triangles'], b['outside']['material_surfaces']),
              'Weapon match and fit: PASS (weapon_match.json, fit.json). Contract: contract.json.', '',
              '## Changed from the picture', '']
    readme += ['- ' + what + '. ' + why for what, why in model['changes']]
    (dest / 'README.md').write_text('\n'.join(readme) + '\n')


def main(mod):
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    if args[0] == 'layout':
        layout(mod, Path(args[1]), Path(args[2]))
    else:
        review(mod, Path(args[1]))
