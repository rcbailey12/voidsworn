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
  lance           a drawn-glass waveguide fixed forward (pulsar F)
  shard_cluster   three short drawn needles gathered at the bow (shard F, the Prism shards)
  star_torpedo    a star torpedo carried on the keel in a grown glass cradle (startorp F)
  stern_drive     a grown stern optic: deep lens, white bloom, rose-cut face; no flame
  lens_bay        a hangar lens grown into a flank with parked Starlings on a glowing floor (data.js hangar)
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
    cell count per ship length (stack.CELLS_PER_LENGTH), so the review shows the cells the game will show."""
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
                grp=None, even=0.0):
    """the opaque glowing mosaic core. light(x, a) -> 0..1 blends the panel to seafoam stored light (a cleft, a bay floor).
    even (0..1) evens each panel's glow toward a steady middle tone, so a pane-heavy hull (the Prism) reads as rows of lit
    panes rather than lit spots; 0 is the CD5 panel (hot middle, dark border)."""
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
            name_, g = gw.mosaic_tint(x, a, gap_of, stack.PALETTE, stack.WEIGHTS, seed=seed, tones=None)
            g = g + (0.55 + 0.45 * g - g) * even
            deep, hot = stack.TONES[name_]
            rgb = [d + (h - d) * g ** 1.5 for d, h in zip(deep, hot)]
        else:
            rgb, g = gw.mosaic_tint(x, a, gap_of, stack.PALETTE, stack.WEIGHTS, seed=seed, tones=stack.TONES)
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
    p.add('integral_root', 'mount', 'gw_pearl', ellipsoid((0, 0, -0.20 * s), (0.42 * s, 0.42 * s, 0.20 * s), 48, 16))
    gv, gf = gw_kit('parts').cut_lens((0, 0, -0.02 * s), (0, 0, 1), 0.26 * s, 0.12 * s, 10)
    p.add('lens', 'turn', 'gw_gem_' + colour, (gv, gf))
    p.add('stored_light', 'turn', 'gw_gem_' + colour, ellipsoid((0, 0, -0.03 * s), (0.20 * s, 0.20 * s, 0.05 * s), 32, 12))
    p.fit = dict(pivot=('p', (0, 0, 0)), reach=0.26 * s, radius=0.28 * s, muzzles=[('p', (0.26 * s, 0, 0))], aim=('d', (1, 0, 0)))
    K.gun(fid, pos, 0, cal=0.09 * s, blen=0.26 * s, slot=slot, weapon=weapon, part=p, inv=['optics'],
          band=(0, 5, 10, 15, 20, 30), note=note or 'Grown %s optic; the cut stone turns on a seat sunk in the ribbons, 360 degrees.' % colour)
    K.features[-1]['what'] = '%s grown optic / %s' % (colour, weapon)
    K.built[-1].update(detailed=True, subs=['grown root', 'cut stone', 'stored light'])
    smooth_group(K, fid)


def lance(K, fid, root, length, r0, weapon='pulsar', drop=0.0, spread=0.0, note='', what='drawn-glass forward Prism lance',
          collar=0.0):
    """a drawn-glass waveguide fixed forward from `root`; tapers to a glowing tip. spread: its sideways reach at the tip.
    collar: the radius of a grown bow optic round the lance root (a ring of stored light in a pearl lip), 0 for none."""
    p = own_part()
    if collar:
        p.add('bow_optic', 'mount', 'gw_light', ellipsoid((0.0, 0, 0), (0.18 * collar, collar, collar), 40, 16))
        ring = [(0.10 * collar, collar * 1.02 * math.cos(a), collar * 1.02 * math.sin(a)) for a in [TAU * i / 48 for i in range(49)]]
        p.add('bow_optic_lip', 'mount', 'gw_pearl', tube_mesh(ring, [0.16 * collar] * 49, 12))
        p.add('bow_optic_silver', 'mount', 'gw_silver', tube_mesh([(q[0] + 0.15 * collar, q[1], q[2]) for q in ring], [0.035 * collar] * 49, 6))
    pts, radii = [], []
    for i in range(101):
        t = i / 100
        pts.append((length * t, spread * t, -drop * t + 0.25 * r0 * math.sin(math.pi * t)))
        radii.append(r0 * (1 - t) ** 1.55 + 0.018 * r0 / 0.62)
    p.add('drawn_waveguide', 'mount', 'gw_lance', tube_mesh(pts, radii, 24))
    for k in range(5):
        a = k * TAU / 5
        line = [(q[0], q[1] + r * math.cos(a + 1.7 * i / 100), q[2] + r * math.sin(a + 1.7 * i / 100))
                for i, (q, r) in enumerate(zip(pts, radii))]
        p.add('flowing_vein%d' % k, 'mount', 'gw_silver', tube_mesh(line, [0.016 * r0 / 0.62] * len(line), 6))
    tip = pts[-1]
    tr = 0.04 * r0 / 0.62
    p.add('aperture', 'mount', 'gw_tip', ellipsoid((tip[0] - tr * 0.6, tip[1], tip[2]), (tr, tr * 1.1, tr * 1.1), 24, 10))
    p.fit = dict(pivot=('p', tip), reach=0.06, radius=r0 * 1.03, muzzles=[('p', tip)], aim=('d', (1, 0, 0)))
    K.gun(fid, root, 0, cal=0.06, blen=length, fixed=True, slot='F', weapon=weapon, part=p, inv=['forward_lances'],
          band=(0, 5, 10), note=note or 'Drawn-glass waveguide, not a metal barrel; fixed forward, F arc +/-60.')
    K.features[-1]['what'] = what
    K.built[-1].update(detailed=True, subs=['drawn glass', 'silver veins', 'glowing tip'])
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
    # the gathered root: a pearl collar the needles grow from, sunk into the bow
    p.add('root', 'mount', 'gw_pearl', ellipsoid((0.02 * length, 0, 0), (0.18 * length, spread * 0.9 + r0, spread * 0.9 + r0), 32, 12))
    tc = tuple(sum(t[i] for t in tips) / len(tips) for i in range(3))
    p.fit = dict(pivot=('p', tc), reach=0.06, radius=spread + r0, muzzles=[('p', t) for t in tips], aim=('d', (1, 0, 0)))
    K.gun(fid, root, 0, cal=0.05, blen=length, fixed=True, slot='F', weapon='shard', part=p, inv=['bow_shards'], band=(0, 5, 10),
          note=note or 'The Prism shards: three drawn needles grown from the bow optic on the centreline; fixed forward, F arc.')
    K.features[-1]['what'] = 'three drawn-glass shard needles at the bow / shard'
    K.built[-1].update(detailed=True, subs=['grown collar', 'three needles', 'silver veins', 'glowing tips'])
    smooth_group(K, fid)


def star_torpedo(K, fid, pos, length, r0, cradle_up, note=''):
    """a star torpedo carried on the keel in a grown pearl cradle (startorp F). The cradle's two arms rise into the hull
    (cradle_up: how far above the torpedo axis the hull's underside sits), so it reads carried, not docked."""
    p = own_part()
    body = [(length * (i / 40 - 0.5), 0, 0) for i in range(41)]
    radii = [r0 * max(0.05, math.sin(math.pi * (0.04 + 0.92 * i / 40))) ** 0.55 for i in range(41)]
    p.add('star_body', 'mount', 'gw_light', tube_mesh(body, radii, 20))
    p.add('star_core', 'mount', 'gw_drive_core', ellipsoid((0.05 * length, 0, 0), (0.30 * length, r0 * 0.55, r0 * 0.55), 24, 10))
    gv, gf = gw_kit('parts').cut_lens((0.5 * length, 0, 0), (1, 0, 0), r0 * 0.55, r0 * 0.45, 8)
    p.add('star_nose', 'mount', 'gw_gem_violet', (gv, gf))
    for k in range(6):
        a = k * TAU / 6
        line = [(q[0], r * 1.02 * math.cos(a + 0.6 * i / 40), r * 1.02 * math.sin(a + 0.6 * i / 40)) for i, (q, r) in enumerate(zip(body, radii))]
        p.add('star_vein%d' % k, 'mount', 'gw_silver', tube_mesh(line, [0.010 * r0 / 0.25] * len(line), 5))
    for xs in (-0.28, 0.22):
        for side in (-1, 1):
            arm = [(xs * length + 0.04 * length * math.sin(math.pi * i / 12), side * r0 * (1.05 - 0.55 * i / 12),
                    r0 * 0.2 + (cradle_up - r0 * 0.2) * (i / 12) ** 0.8) for i in range(13)]
            p.add('cradle_%s_%d' % ('aft' if xs < 0 else 'fwd', side), 'mount', 'gw_pearl', tube_mesh(arm, [r0 * 0.20 * (1.0 - 0.3 * i / 12) for i in range(13)], 10))
        hoop = [(xs * length, r0 * 1.08 * math.cos(a), r0 * 1.08 * math.sin(a)) for a in [math.pi * (-0.15 + 1.3 * i / 24) for i in range(25)]]
        p.add('cradle_hoop_%s' % ('aft' if xs < 0 else 'fwd'), 'mount', 'gw_pearl', tube_mesh(hoop, [r0 * 0.15] * 25, 10))
    nose = (0.5 * length + r0 * 0.45, 0, 0)
    p.fit = dict(pivot=('p', nose), reach=0.05, radius=r0 * 1.2, muzzles=[('p', nose)], aim=('d', (1, 0, 0)))
    K.gun(fid, pos, 0, cal=0.08, blen=length, fixed=True, slot='F', weapon='startorp', part=p, inv=['star_torpedo'], band=(0, 5),
          note=note or 'One star torpedo on the keel in a grown pearl cradle; fixed forward, F arc.')
    K.features[-1]['what'] = 'star torpedo carried in a grown keel cradle / startorp'
    K.built[-1].update(detailed=True, subs=['star body', 'stored light', 'cut nose', 'two cradle hoops and four arms'])
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
                 mesh_groups=groups, dimensions=[float(hi[i] - lo[i]) for i in range(3)],
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
