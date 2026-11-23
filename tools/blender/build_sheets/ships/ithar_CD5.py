"""CD5, The Unfinished. Issue 912, Ryan's R298 reference.

All visible shapes are authored here. The sheet kit supplies records and scene plumbing
only; no Hullbreaker geometry or paint is used. CPU review and layout are reproducible:
  blender -b -t 8 --python-exit-code 1 -P THIS_FILE -- review TEMP_OUT
  python THIS_FILE layout TEMP_OUT docs/ship_pipeline/build_sheets/ithar_CD5
The normal build.py and recipe contract also load build(K).
"""
import hashlib
import json
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[4]
SHEETS = ROOT / 'tools/blender/build_sheets'
CODE = 'ithar_CD5'
NAME = 'The Unfinished / Glasswright flagship CD5'
FACTION = 'The Glasswrights (ithar)'
CLASS = 'Ark'
LENGTH = 26.0
GAME = "data.js i_boss (Ark); CLS_LEN Ark = 26, SHIP_K 1.6 = 41.6 on the board"
BEAUTY = 'docs/ship_pipeline/build_sheets/ithar_CD5/concept.jpg'
SHEET = dict(version=5, round='R337 / CD5 r5', date='2026-11-19', stage='blockout + paint preview')
# One camera for the reference comparison, with the stern near and the bow receding right.
CAMERA = dict(az=240.0, el=29.0, roll=-10.0, scale=30.6)
OPTICS = [(-6.0, 'O1', 'pulsar', 'amber'), (0.0, 'O2', 'turret', 'violet'),
          (6.0, 'O3', 'flak', 'green')]
ZONES = {
    'cd5_clear': ((0.82, 0.88, 0.91), 0, 0.09, 1.0, 0.0),
    'cd5_pearl': ((0.51, 0.59, 0.66), 0, 0.16, 0.42, 0.36),
    'cd5_silver': ((0.73, 0.76, 0.79), 0, 0.20, 0.0, 0.88),
    'cd5_amber': ((0.95, 0.16, 0.006), 2.5, 0.13, 0.18, 0.0),
    'cd5_violet': ((0.20, 0.002, 0.68), 2.8, 0.13, 0.18, 0.0),
    'cd5_green': ((0.08, 0.43, 0.004), 2.3, 0.13, 0.18, 0.0),
    'cd5_white': ((0.76, 0.84, 1.0), 3.2, 0.14, 0.25, 0.10),
    'cd5_frame': ((0.16, 0.24, 0.28), 0, 0.28, 0.28, 0.42),
    # Separate body zones leave both run 1 lances and their materials unchanged.
    'cd5_body_clear': ((0.86, 0.91, 0.96), 0, 0.065, 1.0, 0.0),
    'cd5_body_pearl': ((0.72, 0.77, 0.83), 0, 0.14, 0.65, 0.20),
    'cd5_pane_amber': ((0.95, 0.19, 0.009), 0.80, 0.17, 0.30, 0.12),
    'cd5_pane_violet': ((0.19, 0.008, 0.63), 0.85, 0.16, 0.30, 0.10),
    'cd5_pane_green': ((0.055, 0.38, 0.012), 0.65, 0.16, 0.30, 0.10),
    'cd5_drive': ((0.43, 0.24, 0.86), 2.2, 0.10, 0.35, 0.0),
    'cd5_drive_core': ((0.84, 0.83, 1.0), 4.5, 0.12, 0.10, 0.0),
    # Run 3 body zones are separate so every run 2 optical material stays intact.
    'cd5_strand_glass': ((0.85, 0.88, 0.91), 0, 0.095, 0.90, 0.0),
    'cd5_sliver_amber': ((1.0, 0.22, 0.006), 8.5, 0.13, 0.12, 0.0),
    'cd5_sliver_violet': ((0.34, 0.012, 0.80), 6.0, 0.13, 0.12, 0.0),
    'cd5_sliver_green': ((0.20, 0.55, 0.008), 4.5, 0.13, 0.12, 0.0),
}


def width(x):
    return (0.08 + 3.75 * max(0.0, math.sin(math.pi * (x + 12.75) / 23.0)) ** 0.68
            + 2.65 * math.exp(-((x + 12.6) / 2.5) ** 2))


def flow_phase(x):
    return 0.12 * x + 0.42 * math.sin(x * 0.23)


# Round 5 (outside read, Nov 19): the concept is a slender spindle, about 4 to 1; round 4 was about 2.6 to 1. Every section
# of the run 2 oval is scaled by SLIM, so the optics, lances and drives keep following the skin they sit on.
SLIM = 0.70


def run2_skin(x, a, inset=0.0):
    """Frozen run 2 attachment surface for the eight preserved optical groups (round 5: slimmed by SLIM, no optic swells)."""
    w = max(0.035, width(x) - inset)
    env = max(0.0, math.sin(math.pi * (x + 12.75) / 23.0)) ** 0.45
    folded = math.atan2(math.sin(a), abs(math.cos(a)))
    # Broad poured ridges wrap a full oval body. No fluted slab or isolated peaks.
    ridge = 4 * (folded - flow_phase(x))
    flow = 1.0 + 0.16 * math.cos(ridge) + 0.030 * math.cos(2 * ridge)
    y = w * math.cos(a) * flow
    h = 0.30 + 2.15 * env + 0.85 * math.exp(-((x + 12.4) / 2.2) ** 2)
    z = (h - inset) * math.sin(a) * flow
    # Round 5: no optic swells; the optics are small glints set flush in the ribbons (the domes are not in the concept).
    return (x, y * SLIM, z * SLIM)


# R337 (issue 1183): the hull restarts from the approved concept. The core is run 2's frozen oval (it already carries the
# three optic swells and the stern shoulders, so every optic, lance and drive keeps its exact attachment). Over it lie the
# Glasswright kit's pearl ribbons; the core itself is the opaque glowing mosaic seen in the gaps. Nothing is see-through.
NOSE_X, NOSE_END = 7.0, 12.4


def skin(x, a, inset=0.0):
    """Board round 4: forward of x=7 the run 2 nose is stretched into a long point that runs out between the lances
    (the optics, all at x <= 6, keep their exact skin)"""
    if x > NOSE_X:
        c = (NOSE_END - 10.25) / (NOSE_END - NOSE_X) ** 2
        q = x - c * (x - NOSE_X) ** 2
        p = run2_skin(q, a, inset)
        return (x, p[1], p[2])
    return run2_skin(x, a, inset)


def gw_kit(name):
    """load a Glasswright kit module under its own name (another kit's parts.py may already be imported as `parts`)"""
    import importlib.util
    key = 'ithar_' + name
    if key not in sys.modules:
        spec = importlib.util.spec_from_file_location(key, ROOT / 'tools/blender/kits/ithar' / (name + '.py'))
        mod = importlib.util.module_from_spec(spec); sys.modules[key] = mod; spec.loader.exec_module(mod)
    return sys.modules[key]


RIB_A = 12           # full-length ribbons, stern lenses to bow, twisting together (round 5: more and finer, was 7)
TWIST_A = lambda x: 0.07 * x + 0.30 * math.sin(0.21 * x)
# Upper leaves: shorter, wider ribbons that cross the long ones with a counter twist and curl up along the spine.
# (x0, x1, base angle, width): laid by hand so they overlap like the concept's leaves, not as a regular pattern.
LEAVES = [(-11.6, 1.8, 1.30, 0.17), (-8.4, 9.4, 2.25, 0.16), (-5.2, 9.6, 0.70, 0.16), (-9.0, 5.0, 3.40, 0.15),
          (-10.4, 6.6, 1.75, 0.13), (-3.6, 10.2, 1.05, 0.12), (-7.0, 7.8, 4.55, 0.13), (-11.0, 3.0, 5.40, 0.12)]
TWIST_B = lambda x: 0.05 * x + 0.22 * math.sin(0.24 * x + 1.1)  # same sweep as the long ribbons: openings run with the flow


SWAY, LEAF_F = 0.22, 0.80


# Toward the bow every ribbon gathers into one of the two lance roots, like flames drawing to a point (Board, round 2).
BOW_ANGLE = 0.62


def bow_gather(x, a):
    s = min(1.0, max(0.0, (x - 0.5) / 9.0)) ** 1.6
    s = s * s * (3 - 2 * s)
    target = BOW_ANGLE if math.cos(a) >= 0 else math.pi - BOW_ANGLE
    d = math.atan2(math.sin(target - a), math.cos(target - a))
    return a + d * s * 0.85


def gap_of(x, a):
    """which long-ribbon gap a core point sits in, and its leaf coordinate along the gap: whole numbers fall where the two
    swaying neighbours pinch together, so each leaf window between two pinches is one panel"""
    step = 2 * math.pi / RIB_A
    u = ((a - 0.2 - TWIST_A(x)) % (2 * math.pi)) / step
    g = int(math.floor(u))
    # Board round 4: each opening breaks into smaller leaves of mixed colour: two side by side across the opening, offset
    # half a leaf along it, and three leaves where round 3 had one.
    # Round 5: with twelve finer ribbons each opening is one leaf across, lit from behind: `across` (0 and 1 under the two
    # ribbons, 0.5 in the middle) lets the glow fall off to the edges. Bay ends are slanted, not square.
    f = u - g
    along = (LEAF_F * x + g * math.pi - math.pi / 2) / math.pi + 0.45 * (f - 0.5)
    return g, along, f


def optic_clamp(x, p, lift):
    """ribbons lie flat under each grown optic so its turning lens stays clear"""
    for ox, _, _, _ in OPTICS:
        d = ((x - ox) / 1.30) ** 2 + (p[1] / 1.20) ** 2
        if d < 1 and p[2] > 0:
            lift = min(lift, 0.02 + 1.0 * d * d)  # smooth: reaches the tallest crest curl at the edge of the clamp
    return lift


BODY_NU, BODY_NV = 240, 144


def grid_surface(fn, nu, nv, u0, u1, v0=0.0, v1=2 * math.pi, wrap=True):
    verts = [fn(u0 + (u1 - u0) * i / nu, v0 + (v1 - v0) * j / nv)
             for i in range(nu + 1) for j in range(nv if wrap else nv + 1)]
    row = nv if wrap else nv + 1
    faces = [(i * row + j, i * row + (j + 1) % row,
              (i + 1) * row + (j + 1) % row, (i + 1) * row + j)
             for i in range(nu) for j in range(nv)]
    return verts, faces


def ellipsoid(c, r, n=40, rings=20):
    return grid_surface(lambda u, v: (c[0] + r[0] * math.cos(u),
                                     c[1] + r[1] * math.sin(u) * math.cos(v),
                                     c[2] + r[2] * math.sin(u) * math.sin(v)),
                        rings, n, 0.001, math.pi - 0.001)


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
            a = j * 2 * math.pi / n
            vv.append(tuple(p + radii[i] * (q * math.cos(a) + w * math.sin(a))))
    for i in range(len(points) - 1):
        for j in range(n):
            a, b = i * n + j, i * n + (j + 1) % n
            ff.append((a, b, b + n, a + n))
    ff += [tuple(range(n))[::-1], tuple(range((len(points) - 1) * n, len(points) * n))]
    return vv, ff


def material_setup():
    """Inside zones (seen only in the break-up) plus the shared Glasswright paint stack for every outside surface."""
    import kit
    stack = gw_kit('stack')
    for name, (rgb, em, rough, trans, metal) in ZONES.items():
        kit.MATS[name] = (rgb, em)
        m = kit.mat(name)
        bs = m.node_tree.nodes.get('Principled BSDF')
        bs.inputs['Roughness'].default_value = rough
        bs.inputs['Metallic'].default_value = metal
        bs.inputs['Transmission Weight'].default_value = 0.0  # R337: nothing see-through, inside or out
    stack.setup(kit)
    kit.KIT_NAME = 'ithar_CD5 on the shared Glasswright kit (tools/blender/kits/ithar)'


def thick_shell(ob, t, centre):
    """give an open surface real thickness t without a solidify modifier (r5c): a back layer along the vertex normals
    (inward, or split either side when `centre`) and walls on the open edges. Point attributes are copied to the back
    layer. A vertex with no normal (a pinched ribbon tip) stays put, so no spikes."""
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
            e = (vs[i], vs[(i + 1) % len(vs)])
            count[tuple(sorted(e))] = count.get(tuple(sorted(e)), 0) + 1
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
        at = new.attributes[name]
        at.data.foreach_set('value' if kind == 'FLOAT' else 'color', vals + vals)
    for p in new.polygons:
        p.use_smooth = True
    ob.data = new
    new.update()


def own_part():
    # Part is a data container, not a borrowed shape.
    from kit import HP
    p = HP.Part('gun')
    p.type = 'gun'
    return p


def optical_gun(K, x, fid, weapon, colour):
    """The hidden rotating element fits within a continuous grown glass saddle."""
    p = own_part()
    # Round 5 (outside read): no pastel domes, they are not in the concept. A small flat pearl seat sunk in the ribbons
    # and a small cut stone on it: a glint among the mosaic, not the first thing the eye goes to.
    # Issue 1282 (Fable on PR 1184): the seat's top sits 0.08 under the pivot, clear of the barrel's lower edge (calibre 0.09),
    # so the game's clearance test lets the optic train; at -0.20 its top met the barrel and all three stayed locked at rest.
    p.add('integral_root', 'mount', 'gw_pearl', ellipsoid((0, 0, -0.28), (0.42, 0.42, 0.20), 48, 16))
    gv, gf = gw_kit('parts').cut_lens((0, 0, -0.02), (0, 0, 1), 0.26, 0.12, 10)
    p.add('lens', 'turn', 'gw_gem_' + colour, (gv, gf))
    p.add('stored_light', 'turn', 'cd5_' + colour, ellipsoid((0, 0, -0.03), (0.20, 0.20, 0.05), 32, 12))
    # The exit is on the forward face, not a disconnected hard point or a flat disc.
    p.fit = dict(pivot=('p', (0, 0, 0)), reach=0.26, radius=0.28,
                 muzzles=[('p', (0.26, 0, 0))], aim=('d', (1, 0, 0)))
    crest = max(run2_skin(x + 0.30 * i / 8, math.pi / 2 + 0.20 * j / 8)[2]
                for i in range(-8, 9) for j in range(-8, 9))
    K.gun(fid, (x, 0, crest + 0.28), 0, cal=0.09, blen=0.26, slot='T', weapon=weapon,
          part=p, inv=['secondary_optics'], band=(0, 5, 10, 15, 20, 30),
          note='%s cut-stone optic on a flush pearl seat; turns 360 degrees; %s slot.' % (colour.capitalize(), weapon))
    K.features[-1]['what'] = '%s grown optic / %s' % (colour, weapon)
    K.built[-1].update(detailed=True, subs=['grown root', 'lens', 'light reservoir', 'forward optical exit'])
    for o in K.coll.objects:
        if o.get('grp') == fid:
            for f in o.data.polygons:
                f.use_smooth = True


def lance(K, side, fid):
    p = own_part()
    # The pulled glass root follows the flowing skin. The outer contour ends at x=13.
    pts, radii = [], []
    for i in range(101):
        t = i / 100
        pts.append((10 * t, side * (0.30 * math.sin(math.pi * t) + 0.80 * t),
                    0.20 * math.sin(math.pi * t) - 0.22 * t))
        radii.append(0.62 * (1 - t) ** 1.55 + 0.018)
    p.add('drawn_waveguide', 'mount', 'gw_lance', tube_mesh(pts, radii, 32))
    for k in range(5):
        a = k * 2 * math.pi / 5
        line = [(q[0], q[1] + r * math.cos(a + 1.7 * i / 100),
                 q[2] + r * math.sin(a + 1.7 * i / 100)) for i, (q, r) in enumerate(zip(pts, radii))]
        p.add('flowing_vein%d' % k, 'mount', 'gw_silver', tube_mesh(line, [0.016] * len(line), 6))
    for k, col in enumerate(('amber', 'violet', 'green')):
        line = [(q[0], q[1] + radii[i] * 0.32 * math.cos(k * 2.1), q[2]) for i, q in enumerate(pts)]
        p.add('inner_pane%d' % k, 'mount', 'cd5_' + col,
              tube_mesh(line, [max(0.008, r * 0.26) for r in radii], 10))
    p.add('aperture', 'mount', 'gw_tip', ellipsoid((9.975, side * 0.8, -0.22), (0.025, 0.027, 0.027), 24, 10))
    p.fit = dict(pivot=('p', (10, side * 0.8, -0.22)), reach=0.06, radius=0.64,
                 muzzles=[('p', (10, side * 0.8, -0.22))], aim=('d', (1, 0, 0)))
    K.gun(fid, (3, side * 1.50, 0.66), 0, cal=0.06, blen=10, fixed=True,  # round 5: on the slimmer hull (SLIM)
          slot='F', weapon='pulsar', part=p, inv=['forward_lances'], band=(0, 5, 10),
          note='One of Ryan\'s two long forward lances. Pulled-glass waveguide, not a metal barrel; F arc +/-60.')
    K.features[-1]['what'] = 'long pulled-glass forward Prism lance'
    K.built[-1].update(detailed=True, subs=['drawn glass', 'silver veins', 'inner colour panes', 'optical exit'])
    for o in K.coll.objects:
        if o.get('grp') == fid:
            for f in o.data.polygons:
                f.use_smooth = True


def build(K):
    import kit
    material_setup()
    gw, stack = gw_kit('parts'), gw_kit('stack')
    # The opaque core: the glowing mosaic seen between the ribbons. Each gap between two long ribbons is cut into
    # leaf-length panels of one colour each (amber most, then violet, then green: the concept's shares).
    vf = grid_surface(skin, BODY_NU, BODY_NV, -12.75, NOSE_END)
    hull = K._obj(CODE + '_mosaic_core', *vf, 'gw_mosaic', smooth=True)
    hull.data.color_attributes.new('gw_tint', 'FLOAT_COLOR', 'POINT')
    hull.data.attributes.new('gw_glow', 'FLOAT', 'POINT')
    # Fetch both after creating both: adding an attribute moves the others' storage.
    tint, glow = hull.data.attributes['gw_tint'], hull.data.attributes['gw_glow']
    for i in range(len(tint.data)):
        ix, ia = divmod(i, BODY_NV)
        x = -12.75 + (NOSE_END + 12.75) * ix / BODY_NU
        a = ia * 2 * math.pi / BODY_NV
        rgb, g = gw.mosaic_tint(x, a, gap_of, stack.PALETTE, stack.WEIGHTS, seed=0, tones=stack.TONES)  # seed 0: amber 57, violet 26, green 16 on top (the concept's shares)
        tint.data[i].color = tuple(rgb) + (1,)
        glow.data[i].value = g
    # r5c (death seam check, r5b): the core's thickness is real geometry, not a 'skin' modifier. The export lines a skin
    # modifier's back with a dark inside material; under the ribbons that lining tore apart from its own piece at every
    # break and breach (about 3,000 of the 3,500 triangles outside their piece). The core's inner face is mosaic too.
    thick_shell(hull, 0.065, centre=False)
    K.mass('Mosaic core', hull, 'opaque glowing stained-glass mosaic',
           note='Run 2 oval core, unchanged optic roots; leaf panels of amber, violet and green cells; never see-through.')
    K.mark('flowing_hull', 'hull', ['bevel', 'step', 'overhang'])
    ribbons = []
    step = 2 * math.pi / RIB_A
    for k in range(RIB_A):
        base = 0.2 + k * step
        ribbons.append(gw.Ribbon(
            # the long ribbons run on past the body's nose and close into one long point between the lances
            -12.45 + 0.18 * math.sin(2.3 * k), 12.2 - 0.30 * (k % 3),
            # Neighbours sway in opposite senses, so they meet and part: the gaps between them become leaf-shaped windows.
            lambda x, base=base, k=k: bow_gather(x, base + TWIST_A(x) + SWAY * math.sin(LEAF_F * x + k * math.pi)),
            lambda t, k=k: (0.135 + 0.025 * math.sin(1.7 * k)) * gw.leaf(0.55, 0.40, 0.40 + 0.05 * math.sin(k), tip=0.0)(t),
            lambda t, v: 0.05 + 0.14 * (1 - v * v) ** 0.5 * (0.5 + 0.5 * math.sin(math.pi * t) ** 0.5),  # a rounded, pillowed fold, not a flat strap
            name='long_ribbon_%d' % k, clamp=optic_clamp))
    for k, (x0, x1, base, wd) in enumerate(LEAVES):
        top = max(0.0, math.sin(base)) ** 2
        ribbons.append(gw.Ribbon(
            x0, x1, lambda x, base=base: bow_gather(x, base + TWIST_B(x)),
            lambda t, wd=wd: wd * gw.leaf(0.7, 0.0, 0.38)(t),
            # Upper leaves curl their trailing edge up off the hull, like the concept's crests along the spine.
            lambda t, v, top=top: 0.22 + 0.14 * (1 - v * v) ** 0.5 + 0.75 * top * ((v + 1) / 2) ** 2 * math.sin(math.pi * t) ** 1.5,
            name='leaf_ribbon_%d' % k, clamp=optic_clamp))
    for r in ribbons:
        vv, ff, attrs = r.mesh(skin, 180, 8)
        ob = K._obj(r.name, vv, ff, 'gw_pearl', smooth=True)
        for an in attrs:
            ob.data.attributes.new(an, 'FLOAT', 'POINT')
        for an, vals in attrs.items():
            ob.data.attributes[an].data.foreach_set('value', vals)
        # r5c: the ribbon's thickness is real geometry, not a solidify modifier. A modifier would be the contract's 'skin',
        # and the export lines a skin's back with an inside material: a ribbon's underside is outside plating over the
        # mosaic, not an inside lining (death seam check, r5b).
        thick_shell(ob, 0.035, centre=True)
        ob['zone'] = 'pearl ribbon'
        for side in (-1, 1):
            pts = r.edge(skin, side, 180)
            radii = [0.024 * (0.35 + 0.65 * math.sin(math.pi * i / 180) ** 0.4) for i in range(181)]
            K._obj(r.name + ('_silver_p' if side > 0 else '_silver_s'), *tube_mesh(pts, radii, 6), 'gw_silver', smooth=True)
    lance(K, 1, 'L1')
    lance(K, -1, 'L2')
    for x, fid, wk, col in OPTICS:
        optical_gun(K, x, fid, wk, col)
    # The three stern lenses are propulsion, never extra weapons. Optical depth, no flame.
    # Round 5: the slimmer stern carries three slightly smaller cut lenses, closer together (SLIM).
    SR = 0.74
    EX = -12.60 - 0.38 * SR   # the cut face's apex: the drive's exit point (Artoo, r5 readback)
    for k, y in enumerate((-1.42, 0.0, 1.42)):
        fid = 'E%d' % (k + 1)
        ob = K._obj(fid + '_grown_stern', *ellipsoid((-12.05, y, -0.02), (0.85 * SR, 0.93 * SR, 0.98 * SR), 64, 32),
                    'gw_pearl', smooth=True, grp=fid, role='mount')
        ob['part_kind'] = 'engine'; ob['machine'] = 1
        K._obj(fid + '_deep_lens', *ellipsoid((-12.67, y, -0.02), (0.13, 0.86 * SR, 0.88 * SR), 64, 32),
               'gw_drive', smooth=True, grp=fid, role='mount')
        K._obj(fid + '_white_bloom', *ellipsoid((-12.68, y, -0.02), (0.18, 0.44 * SR, 0.46 * SR), 64, 32),
               'gw_drive_core', smooth=True, grp=fid, role='mount')
        # R337: the concept's stern lenses are cut stones. A rose-cut face, flat facets, sits over the deep lens.
        K._obj(fid + '_cut_face', *gw.cut_lens((-12.60, y, -0.02), (-1, 0, 0), 0.80 * SR, 0.38 * SR, 10, 0.80 * SR, 0.82 * SR),
               'gw_drive_cut', grp=fid, role='mount')
        for j in range(11):
            a = j * 2 * math.pi / 11
            pts = [(-12.05 + 0.855 * SR * math.cos(u), y + 0.935 * SR * math.sin(u) * math.cos(a),
                    -0.02 + 0.985 * SR * math.sin(u) * math.sin(a))
                   for u in [0.07 + i * 3.0 / 32 for i in range(33)]]
            K._obj(fid + '_silver_flow_%02d' % j, *tube_mesh(pts, [0.014] * len(pts), 7),
                   'gw_silver', smooth=True, grp=fid, role='mount')
        if k == 1:
            # The middle drive is enclosed by the broad stern. Its internal feed
            # joins the skin, rather than relying on a floating enclosed sphere.
            K._obj(fid + '_internal_feed',
                   *tube_mesh([(-12.05, 0, 0), run2_skin(-12.05, math.pi / 2)], [0.07, 0.07], 12),
                   'gw_pearl', smooth=True, grp=fid, role='mount')
        for o in K.coll.objects:
            if o.get('grp') == fid:
                o['part_kind'] = 'engine'; o['machine'] = 1
        K.features.append(dict(id=fid, kind='engine', what='grown stern drive optic, white bloom', count=1,
                               pos=(EX, y, -0.02), exit=(EX, y, -0.02), radius=0.86 * SR,
                               aim=(180, 0), src='picture', note='Drive lens only; no flame, exhaust mesh or weapon.', inv=['stern_cluster']))
        K.fitdata.append(dict(id=fid, kind='engine', cones=[dict(apex=(EX, y, -0.02), dir=(-1, 0, 0), r0=0.86 * SR, half=10, length=5)]))
        K.built.append(dict(id=fid, kind='engine', inv=['stern_cluster'], shaped=True, detailed=True,
                            subs=['grown root', 'recessed lens', 'stored light', 'bloom']))
    # Full internal construction follows the leaf, not rectangular room boxes.
    # r5c (death seam check, PC run r5b): an inside object goes whole to the piece its middle lies in, so a deck or light
    # core running across a break stuck out of its own piece. Each is cut into one span per compartment, with a gap at
    # every break (its jagged path wanders 0.14 either side), and no frame stands on a break.
    BREAKS = (-10.95, -7.45, -4.55, -1.45, 1.45)
    BREACH_X = (-8.8, -3.1, 4.0, 8.0)     # the breach anchors below: a bite opens the hull there
    GAP = 0.22
    edges = [-11.3] + [v for b in BREAKS for v in (b - GAP, b + GAP)] + [6.6]   # clear of the thin stern and nose tips
    spans = [(edges[i], edges[i + 1]) for i in range(0, len(edges), 2)]
    for z, name in ((-0.55, 'lower'), (0.20, 'upper')):
        for si, (x0, x1) in enumerate(spans):
            n = max(4, int(80 * (x1 - x0) / 20.4))
            vv, ff = grid_surface(lambda x, t, z=z * SLIM: (x, (width(x) * SLIM - 0.40) * t, z),
                                 n, 14, x0, x1, -0.55, 0.55, False)
            ob = K._obj('in_deck_%s_%d' % (name, si), vv, ff, 'cd5_frame', inside=True)
            mod = ob.modifiers.new('shell', 'SOLIDIFY'); mod.thickness = 0.06
        K.inside.append(dict(kind='deck', name=name, z=z, x=(edges[0], edges[-1]), note='layered glass deck follows the leaf, one span per compartment'))
    for i in range(15):
        x = -11.6 + 1.35 * i
        # off every break (its jagged path) and out from under every breach bite (death seam check, r5b)
        for _ in range(4):
            near = [b for b in BREAKS if abs(x - b) < 0.65] + [b for b in BREACH_X if abs(x - b) < 0.9]
            if not near:
                break
            x = near[0] + (0.65 if near[0] in BREAKS else 0.9) * (1 if x >= near[0] else -1) + (0.01 if x >= near[0] else -0.01)
        if x > 6.6 or any(abs(x - b) < 0.65 for b in BREAKS) or any(abs(x - b) < 0.9 for b in BREACH_X):
            continue    # the nose is too thin for a frame, or no clear room between a break and a breach
        pts = [skin(x, a * 2 * math.pi / 64, inset=1.0) for a in range(65)]
        K._obj('in_frame_%02d' % i, *tube_mesh(pts, [0.065] * len(pts), 8), 'cd5_frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name='annealed frame %02d' % i, x=x, note='open structural glass frame'))
    for k, col in enumerate(('amber', 'violet', 'green')):
        line = lambda x: (x, 0.30 * math.cos((x + 11.8) / 0.21 * 0.07 + k * 2.1),
                          -0.07 + 0.21 * math.sin((x + 11.8) / 0.21 * 0.07 + k * 2.1))
        for si, (x0, x1) in enumerate(spans):
            x1 = min(x1, 9.2)
            n = max(4, int(100 * (x1 - x0) / 21.0))
            pts = [line(x0 + (x1 - x0) * i / n) for i in range(n + 1)]
            K._obj('in_light_core_%s_%d' % (col, si), *tube_mesh(pts, [0.10] * len(pts), 12), 'cd5_' + col, inside=True, smooth=True)
    for x, fid, _, col in OPTICS:
        K._obj('in_reservoir_' + fid, *ellipsoid((x, 0, 0.40), (0.65, 0.52, 0.35)),
               'cd5_' + col, inside=True, smooth=True)
        K.inside.append(dict(kind='space', name=fid + ' light reservoir', x=(x - 0.9, x + 0.9),
                             y=(-0.75, 0.75), z=(0.05, 1.05), mat='cd5_' + col, note='optic power and steering chamber'))
    # the rooms (Ryan, Nov 23: real rooms like every other faction, kits/ithar/rooms.py): crew halls and stored-light machinery
    # beside the light cores between the decks, the crystal heart and its racks under the lower deck; the light reservoirs keep
    # the space over the upper deck
    env = lambda x: max(0.0, math.sin(math.pi * (x + 12.75) / 23.0)) ** 0.45
    gw_kit('rooms').rooms(K, lambda x: 0.75 * SLIM * width(x), lambda x: 0.75 * SLIM * (0.30 + 2.15 * env(x)), -11.3, 6.6,
                          BREAKS, BREACH_X, y0=0.0, gap=GAP, deck_z=(-0.55 * SLIM, 0.20 * SLIM), bands=('mid', 'low'))
    K.inside.append(dict(kind='space', name='continuous light core and stern drive chamber', x=(-12, 9),
                         y=(-0.8, 0.8), z=(-0.6, 0.9), mat='layered glass and light', note='three braided waveguides throughout the hull'))
    K.armour('annealed outer glass', 0.065, 'actual shell thickness; layered blown glass, no armour plates')
    # Jagged transverse tears bracket each secondary bay. Forward lances stay whole
    # on the bow piece. The three stern drives each retain their own machine group.
    for i, x in enumerate((-10.95, -7.45, -4.55, -1.45, 1.45)):
        path = [(x + dx, y) for dx, y in ((0, -6), (0.13, -3), (-0.12, -1.4),
                                         (0.09, 0), (-0.14, 1.3), (0.12, 3), (0, 6))]
        K.break_line('B%d' % (i + 1), x, 'ragged shatter path at the lens bay; whole optics, never a straight saw cut', path=path)
    # r5c: no O3 peel. On the slimmer hull a level plane clear of O3 and both lances lies at the hull top, and the game's
    # peel takes the whole compartment above it, so it opened the bow piece (death seam check, r5b: insides outside their
    # piece). O3 stays whole in the bow piece; the playbook allows as many peels as the faction needs, including none.
    K.point('core', 'hp_core', (-0.4, 0, 0.10))
    for i, (x, side, sec) in enumerate(((-8.8, 1, 'eng'), (-8.8, -1, 'eng'),
                                       (-3.1, 1, 'mid'), (-3.1, -1, 'mid'), (4, 1, 'prow'),
                                       (4, -1, 'prow'), (8, 1, 'prow'))):
        K.point('breach', 'hp_breach_%d' % i, skin(x, 0.25 if side > 0 else math.pi - 0.25),
                side='port' if side > 0 else 'stbd', section=sec)
    # Issue 1282 (Fable on PR 1184): one RCS point per side at each end, so the game's braking, side and turning jets each
    # find an authored point on their own side and end (two points left half the requests on the surface ray).
    for i, (x, a) in enumerate(((-9, 0), (-9, math.pi), (6, 0), (6, math.pi))):
        K.point('rcs', 'hp_rcs_%d' % i, skin(x, a))
    for i, (x, a) in enumerate(((-9, 0), (6, math.pi))):
        K.point('board', 'hp_board_%d' % i, skin(x, a))
    K.colour('opaque champagne pearl ribbons, silver lines', 10.25, -13, 'ribbons over the core and the drawn forward lances')
    K.colour('amber, violet, green stained-glass mosaic', 10.0, -12.6, 'the opaque core seen between the ribbons, lit from behind')
    K.colour('violet cut stones', -12.7, -13, 'three stern drive optics, no flame')
    K.fix('Run 1 secondary roots read as tent peaks; round 4 domes were not in the concept',
          'Round 5: a small flat pearl seat and a cut stone set flush in the ribbons; the seat sits under the barrel so the optic trains (issue 1282).')
    K.fix('Run 1 stern drive optics read as small dots',
          'Doubled lens radius to 0.86, widened the grown stern and placed three complete drives 1.90 apart.')
    K.fix('Enlarged stern shoulders crossed the old B1 shatter path',
          'Moved B1 forward to x=-10.95 so all three drive optics remain whole, without an audit exemption.')
    K.change('Three small cut-stone optics at x=-6, 0, +6 on the centreline, set flush in the ribbons',
             'R298: even, balanced spacing and all-direction arcs; amber = pulsar T, violet = turret T, green = flak T. The stern cluster is propulsion.')
    K.change('Two separate long drawn-glass lances, one per forward pulsar slot',
             'Keep Ryan\'s loved long forward lances; the model uses the game\'s two F slots and visible optical exits.')
    K.change('Twelve fine pearl ribbons over an opaque mosaic core, a slender spindle about 4 to 1 (round 5)',
             'R337: restart from the approved concept; each ribbon a bundle of strands with silver lines; the mosaic glows from behind.')
    K.change('Breaks bracket the lens bays; no upper peel (r5c: on the slim hull a peel opened the bow piece)',
             'Glasswrights shatter; each large optic remains a whole part. The forward lances cannot be cut by a new transverse seam.')
    K.open_item('Paint: the shared Glasswright stack (tools/blender/kits/ithar/stack.py), baked with EMISSIVE_ATLAS for the mosaic glow.')
    K.open_item('Built and checked in Windows job clones only (issue 1183 r5c, accepted Nov 20; issue 1282 W2). The shared game build keeps the old hull until issue 1311 publishes it.')


def review(out):
    import bpy
    from mathutils import Vector
    sys.path[:0] = [str(SHEETS), str(ROOT / 'tools/recipe')]
    import kit, variants, weapon_match, clash, contract
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    K = variants.build(sys.modules[__name__])
    bpy.context.view_layer.update()
    match, probs = weapon_match.run(K, 'i_boss')
    (out / 'weapon_match.json').write_text(json.dumps(match, indent=2))
    if probs:
        raise ValueError(probs)
    fit = clash.run(K, str(out), CODE, LENGTH)
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
    budget = dict(outside=cost(K.coll), inside=cost(K.cin), note='unjoined material surfaces are draw submissions; joined-by-material is an estimate only; no game frame measurement')
    lo, hi = contract._bbox([o for o in K.coll.objects if o.type == 'MESH'])
    groups = {fid: [o.name for o in K.coll.objects if o.type == 'MESH' and o.get('grp') == fid]
              for fid in [f['id'] for f in K.features]}
    if not all(groups.values()):
        raise ValueError('A recorded part has no actual meshes')
    model = dict(code=CODE, name=NAME, game_ship='i_boss', cls=CLASS, length=LENGTH, camera=CAMERA,
                 features=K.features, masses=K.masses, inside=K.inside, points=K.points, changes=K.changes, budget=budget,
                 mesh_groups=groups, dimensions=[float(hi[i] - lo[i]) for i in range(3)],
                 design_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    (out / 'model.json').write_text(json.dumps(model, indent=2))
    recipe = dict(sheet=CODE, game_ship='i_boss', faction='ithar', cls=CLASS, length_world=LENGTH, bake='none')
    (out / 'ship.json').write_text(json.dumps(recipe, indent=2))
    # Contract mutates units. Use a fresh scene, preserving the review scene on disk.
    sc = bpy.context.scene
    for o in K.cin.objects:
        o.hide_render = True
    bpy.ops.wm.save_as_mainfile(filepath=str(out / (CODE + '_blockout.blend')))
    record = contract.to_recipe(K, recipe)
    (out / 'contract.json').write_text(json.dumps(record, indent=2))
    bpy.ops.wm.save_as_mainfile(filepath=str(out / (CODE + '_contract.blend')))
    bpy.ops.wm.open_mainfile(filepath=str(out / (CODE + '_blockout.blend')))
    sc = bpy.context.scene
    if '--checks-only' in sys.argv:
        return
    sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'
    sc.cycles.samples = next((int(a.split('=')[1]) for a in sys.argv if a.startswith('--samples=')), 48)
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 10; sc.cycles.transmission_bounces = 8
    sc.render.threads_mode = 'FIXED'; sc.render.threads = 8
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
    world = bpy.data.worlds.new('CD5 dark studio'); sc.world = world; world.use_nodes = True
    world.node_tree.nodes['Background'].inputs[0].default_value = (0.007, 0.010, 0.016, 1)
    world.node_tree.nodes['Background'].inputs[1].default_value = 0.24
    # r4: the pearl mirrors a soft warm room; the camera still sees the dark studio behind the ship.
    wn, wl = world.node_tree.nodes, world.node_tree.links
    room = wn.new('ShaderNodeBackground'); room.inputs[0].default_value = (0.32, 0.28, 0.27, 1); room.inputs[1].default_value = 1.0
    path = wn.new('ShaderNodeLightPath'); mixw = wn.new('ShaderNodeMixShader')
    wl.new(path.outputs['Is Camera Ray'], mixw.inputs[0]); wl.new(room.outputs[0], mixw.inputs[1])
    wl.new(wn['Background'].outputs[0], mixw.inputs[2]); wl.new(mixw.outputs[0], wn['World Output'].inputs['Surface'])
    def area(name, pos, energy, size, colour):
        ld = bpy.data.lights.new(name, 'AREA'); ld.energy = energy; ld.shape = 'RECTANGLE'
        ld.size = size; ld.size_y = size * 0.14; ld.color = colour
        ob = bpy.data.objects.new(name, ld); sc.collection.objects.link(ob); ob.location = pos
        ob.rotation_euler = (-ob.location).to_track_quat('-Z', 'Y').to_euler()
    area('long pearl reflection', (0, -8, 13), 1400, 22, (1.0, 0.92, 0.85))
    area('warm inner light reflection', (3, 7, 9), 2000, 18, (1.0, 0.65, 0.31))
    area('stern edge reflection', (-10, 2, 4), 1800, 12, (0.85, 0.85, 1.0))
    cd = bpy.data.cameras.new('CD5 review camera'); cam = bpy.data.objects.new('CD5 review camera', cd)
    sc.collection.objects.link(cam); sc.camera = cam
    def render(name, az, el, scale, roll=0, target=(0, 0, 0), perspective=False):
        selected = next((a.split('=')[1].split(',') for a in sys.argv if a.startswith('--views=')), None)
        if selected and name not in selected:
            return
        az, el = math.radians(az), math.radians(el)
        distance = 170 if perspective else 60
        cam.location = Vector(target) + Vector((math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el))) * distance
        cam.rotation_euler = (Vector(target) - cam.location).to_track_quat('-Z', 'Y').to_euler()
        cam.rotation_euler.rotate_axis('Z', math.radians(roll))
        cd.type = 'PERSP' if perspective else 'ORTHO'; cd.ortho_scale = scale
        cd.sensor_fit = 'VERTICAL' if perspective else 'HORIZONTAL'; cd.sensor_height = 24
        cd.lens = 24 / (2 * math.tan(math.radians(45) / 2))
        sc.render.filepath = str(out / (name + '.png'))
        bpy.ops.render.render(write_still=True)
        if name == 'concept_camera':
            bpy.ops.wm.save_as_mainfile(filepath=str(out / (CODE + '_review.blend')))
    c = CAMERA
    render('concept_camera', c['az'], c['el'], c['scale'], c['roll'])
    render('close', c['az'] + 15, c['el'] + 6, 10.5, c['roll'], target=(-6.5, 0, 0.8))  # r4: close look at ribbons and mosaic
    render('top', 270, 90, 29)
    render('side', 270, 0, 29)
    render('underside', 270, -90, 29)
    render('bow', 0, 0, 29)
    render('stern', 180, 0, 29)
    # Same model at true game size (41.6); camera 170, 50 degree horizontal field.
    # Apply SHIP_K to the ship and its pivot origins, leaving the camera at 170.
    for ob in bpy.data.collections[CODE].objects:
        if ob.parent is None:
            ob.scale *= 1.6; ob.location *= 1.6
    sc.render.resolution_x = 1920; sc.render.resolution_y = 1080
    render('camera170', 270, 90 - math.degrees(0.98), 29, perspective=True)
    sc.render.resolution_x = 1280; sc.render.resolution_y = 640
    for ob in bpy.data.collections[CODE].objects:
        if ob.parent is None:
            ob.scale /= 1.6; ob.location /= 1.6
    # Cutaway: all real insides with the outer skin hidden.
    for ob in bpy.data.collections[CODE + '_inside'].objects:
        ob.hide_render = False
    for ob in bpy.data.collections[CODE].objects:
        ob.hide_render = True
    render('inside', 248, 35, 29)


def layout(src, dest):
    from PIL import Image, ImageDraw, ImageFont, ImageOps
    sys.path.insert(0, str(ROOT / 'tools'))
    from picture_provenance import save_picture
    dest.mkdir(parents=True, exist_ok=True)
    model = json.loads((src / 'model.json').read_text())
    rev = model['design_sha256'][:12]
    fontpath = 'C:/Windows/Fonts/segoeui.ttf'
    font = ImageFont.truetype(fontpath, 19)
    small = ImageFont.truetype(fontpath, 15)
    title = ImageFont.truetype(fontpath, 27)
    bg, ink = '#09111c', '#dce7ec'
    def canvas(label):
        im = Image.new('RGB', (1280, 720), bg)
        d = ImageDraw.Draw(im)
        d.text((24, 14), 'ITHAR CD5 / ' + label, fill=ink, font=title)
        d.text((24, 51), 'R298 | r3 | design ' + rev + ' | SHEET BUILT | glass colour zones, no faction paint stack', fill='#a9bdc9', font=small)
        return im
    def put(im, path, box):
        pic = Image.open(path).convert('RGB')
        pic = ImageOps.contain(pic, (box[2] - box[0], box[3] - box[1]), Image.Resampling.LANCZOS)
        im.paste(pic, (box[0] + (box[2] - box[0] - pic.width) // 2, box[1] + (box[3] - box[1] - pic.height) // 2))
    def save(im, name):
        save_picture(im, dest / name, 'sheet built', quality=94)
    im = canvas('approved concept beside Blender')
    put(im, ROOT / BEAUTY, (12, 92, 630, 566))
    camera_image = Image.open(src / 'concept_camera.png').convert('RGB').crop((120, 10, 1180, 620))
    camera_image = ImageOps.contain(camera_image, (630, 474), Image.Resampling.LANCZOS)
    im.paste(camera_image, (638, 92 + (474 - camera_image.height) // 2))
    d = ImageDraw.Draw(im)
    d.text((24, 82), 'APPROVED CONCEPT / whole image', fill=ink, font=font)
    d.text((650, 82), 'BLENDER / same direction', fill=ink, font=font)
    d.text((24, 575), 'R5: fine champagne pearl ribbons with silver lines over a glowing amber, violet and green mosaic core.', fill=ink, font=font)
    d.text((24, 603), 'Changed: amber / violet / green optics at even 6-unit intervals on the centreline, grown into the skin.', fill=ink, font=small)
    save(im, 'compare.jpg')
    im = canvas('top / balanced secondary optics')
    im.paste(Image.open(src / 'top.png').crop((0, 31, 1280, 609)), (0, 76))
    d = ImageDraw.Draw(im)
    for x, fid, wk, col in OPTICS:
        px = 640 + x / 29 * 1280
        d.line((px, 200, px, 505), fill='#8395a2', width=1)
        d.text((px - 65, 160), fid + ' / ' + col, fill=ink, font=font)
        d.text((px - 65, 520), wk + ' / 360 deg', fill=ink, font=small)
    d.text((24, 575), 'Centreline x = -6, 0, +6. Same 6-unit spacing; small cut-stone optics turn all round, set flush in the ribbons.', fill=ink, font=font)
    d.text((24, 603), 'Stern (left): three drive optics. Bow (right): L1 and L2, one per forward pulsar slot.', fill=ink, font=small)
    save(im, 'top.jpg')
    for name, caption in (('side', 'side / slender spindle, flush optics'),
                          ('camera170', 'camera 170 / true Ark size 41.6'), ('inside', 'inside / decks, frames and light cores, one span per compartment')):
        im = canvas(caption)
        if name == 'camera170':
            im.paste(Image.open(src / 'camera170.png').crop((320, 252, 1600, 828)), (0, 76))
        else:
            put(im, src / (name + '.png'), (0, 76, 1280, 653))
        d = ImageDraw.Draw(im)
        text = ('Blender proxy: radius 170, vertical FOV 45, beta 0.98, size 41.6; 1920x1080 crop at 1:1; no game install.' if name == 'camera170'
                else 'Deep rounded middle, six twisting strands and narrow groove lights. All run 2 optical groups preserved.' if name == 'side'
                else 'Two shaped decks, 15 annealed frames, three braided light cores and three optical reservoirs. Outer skin hidden.')
        d.text((24, 598), text, fill=ink, font=small)
        save(im, name + '.jpg')
    # All five views share 29 units across 550 pixels. Full beam and height fit.
    im = canvas('true views / one model, one scale')
    d = ImageDraw.Draw(im)
    for name, label, x, y in (('top', 'TOP', 30, 112), ('side', 'SIDE', 660, 112),
                               ('underside', 'UNDERSIDE', 30, 300), ('bow', 'BOW', 660, 300),
                               ('stern', 'STERN', 660, 488)):
        raw = Image.open(src / (name + '.png')).resize((550, 275), Image.Resampling.LANCZOS)
        im.paste(raw.crop((0, 52, 550, 222)), (x, y))
        d.text((x, y - 25), label, fill=ink, font=font)
    d.line((48, 548, 48 + round(5 * 550 / 29), 548), fill=ink, width=3)
    d.text((48, 566), '5 world units / 18.97 px per unit in every view', fill=ink, font=small)
    d.text((48, 598), 'Ark 26.0 long / drawn 41.6 on the board', fill=ink, font=font)
    save(im, 'sheet.jpg')
    # Fit display carries the actual sampled arcs, and the notes do not imply full sphere coverage.
    fit = json.loads((src / 'fit.json').read_text())
    im = canvas('fit / firing arcs and drive clearance')
    im.paste(Image.open(src / 'top.png').crop((0, 108, 1280, 532)), (0, 76))
    d = ImageDraw.Draw(im)
    for x, fid, _, col in OPTICS:
        px = 640 + x / 29 * 1280
        d.ellipse((px - 55, 234, px + 55, 344), outline='#96cfc2', width=2)
        d.text((px - 28, 353), fid + ' 360', fill=ink, font=small)
    d.text((24, 507), 'Fit counts: ' + str(fit['counts']), fill=ink, font=font)
    d.text((24, 539), 'Sampled at 5-degree bearings. Grown roots touch the skin; moving lenses clear it through a full turn.', fill=ink, font=font)
    d.text((24, 570), 'Forward slots: +/-60 degrees. Drive lens clearance: aft cones, 5 units, 10-degree half angle.', fill=ink, font=font)
    d.text((24, 604), 'Clear firing elevation per bearing and the full turning sweep are recorded in fit.json.', fill=ink, font=small)
    save(im, 'fit_view.jpg')
    for name in ('weapon_match.json', 'fit.json', 'contract.json', 'model.json'):
        (dest / name).write_bytes((src / name).read_bytes())
    # Same station convention and piece names as layout.py and manifest_schema.md.
    # Both output tables and the manifest read these actual authored break paths.
    station = lambda x: (LENGTH / 2 - x) / LENGTH * 100
    fractures = [r for r in model['inside'] if r['kind'] == 'break']
    tr = sorted((r for r in fractures if r.get('orient') != 'long'), key=lambda r: -r['x'])
    lg = [r for r in fractures if r.get('orient') == 'long']
    edges = [LENGTH / 2] + [r['x'] for r in tr] + [-LENGTH / 2]
    names = ['bow piece'] + ['midships piece %d' % i for i in range(1, len(tr))] + ['stern piece']
    pieces = []
    for name, a, b in zip(names, edges, edges[1:]):
        bounds = [r['name'] for r in tr if r['x'] in (a, b)]
        split = [r['name'] for r in lg if min(p[0] for p in r['path']) < a and max(p[0] for p in r['path']) > b]
        for half in (('upper', 'lower') if split else (None,)):
            pieces.append(dict(name=name + (', %s half' % half if half else ''),
                               stations='%.3f to %.3f percent' % (station(a), station(b)),
                               bounded_by=bounds + split, full_interior=True))
    manifest = dict(code=CODE, sheet_version=SHEET['version'], design='tools/blender/build_sheets/ships/ithar_CD5.py',
                    design_sha256=model['design_sha256'], game_ship='i_boss', cls=CLASS, length_world=LENGTH,
                    routes_note='Every visible part is hand-built here. CPU Blender; no faction kit or paint stack exists.',
                    parts=[dict(id=f['id'], kind=f['kind'], what=f['what'], route='hand-built',
                                count=f['count'], source=f['src'], inventory=f.get('inv', []),
                                weapon=f.get('weapon'), arc=f.get('slot')) for f in model['features']],
                    turret_marking='O1/O2/O3_turret empties retain turning lenses, slot and arc_lo/arc_hi; L1/L2 are fixed.',
                    masses=[dict(name=m['name'], route='hand-built') for m in model['masses']],
                    break_pieces=pieces,
                    whole_optics=[dict(name=f['id'] + ' whole optic', part=f['id'],
                                       objects=model['mesh_groups'][f['id']], full_interior=True,
                                       attachment='separate whole machine group, grown into its parent bay') for f in model['features']],
                    hull_fractures=fractures,
                    insides='Two shaped decks, 15 glass frames, braided full-length light core and three reservoirs',
                    budget=model['budget'], stage='sheet built', paint_stack=None)
    for part in manifest['parts']:
        if part['kind'] == 'gun':
            part['turret'] = part['arc'] == 'T'
            if part['turret']:
                part.update(pivot_object=part['id'] + '_turret', arc_lo=-180.0, arc_hi=180.0)
    assert {p['id'] for p in manifest['parts']} == set(model['mesh_groups'])
    assert all(p['route'] == 'hand-built' for p in manifest['parts'])
    assert len([p for p in model['points'] if p['kind'] == 'breach']) == 7
    (dest / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    hash_ok = hashlib.sha256(Path(__file__).read_bytes()).hexdigest() == model['design_sha256']
    assert hash_ok, 'Model is stale: rebuild after editing the design'
    (dest / 'manifest_check.json').write_text(json.dumps(dict(result='PASS', check='CD5 model consistency only; standing build_manifest_tests.js is separate', parts=len(manifest['parts']),
        weapon_mounts=5, drive_optics=3, breach_anchors=7, all_routes_hand_built=True,
        design_hash_matches=hash_ok), indent=2))
    lines = ['# CD5 feature table', '', 'Revision r3. Generated from the same Blender model as the pictures. Counts outrank pictures.', '',
             '## Feature table', '',
             '| ID | Fitting | Count | Weapon arc | Route |', '|---|---|---:|---|---|']
    for f in model['features']:
        lines.append('| %s | %s | %s | %s | hand-built |' %
                     (f['id'], f['what'], f['count'], f.get('weapon', 'drive') + ' ' + f.get('slot', 'aft')))
    lines += ['', '## Size', '', 'Ark LENGTH 26.0; drawn 41.6 with SHIP_K 1.6. Measured mesh length / beam / height: ' +
              ' / '.join('%.3f' % n for n in model['dimensions']) + '.', '',
              '## Major masses', '', '| Mass | Route |', '|---|---|']
    for m in manifest['masses']:
        lines.append('| %s | %s |' % (m['name'], m['route']))
    lines += ['', '## INSIDE', '', 'Two shaped glass decks, 15 open annealed frames, three full-length braided light cores and three optical reservoirs.',
              'Seven breach anchors (Ark base 8 minus Glasswright 1), one core, four RCS (one per side at each end) and two boarding origins.', '',
              '| Break line | Station % | What it opens |', '|---|---|---|']
    for r in fractures:
        if r.get('orient') == 'long':
            xs = [p[0] for p in r['path']]
            pos = '%.3f to %.3f (along)' % (station(max(xs)), station(min(xs)))
        else:
            pos = '%.3f' % station(r['x'])
        lines.append('| %s | %s | %s |' % (r['name'], pos, r['note']))
    lines += ['', 'Whole optical machine groups are listed separately in manifest.json whole_optics.',
              'break_pieces names the hull compartments made by these paths, each with its share of the full interior.', '',
              '## Changed from the picture', '']
    for what, why in model['changes']:
        lines += ['- ' + what + '. ' + why]
    (dest / 'feature_table.md').write_text('\n'.join(lines) + '\n')
    # Run the real shared validator after writing, so regeneration cannot quietly
    # replace its schema with a private model check as it did in run 1.
    import shutil
    import subprocess
    node = shutil.which('node')
    if not node:
        node = str(ROOT.parents[1] / 'node/node.exe')
    command = [node, 'contrib/opus/tools/build_manifest_tests.js']
    checked = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    record = dict(check='standing build_manifest_tests.js, all sheets and planted faults',
                  command='node contrib/opus/tools/build_manifest_tests.js',
                  exit_code=checked.returncode, result='PASS' if checked.returncode == 0 else 'FAIL',
                  design_sha256=model['design_sha256'], output=checked.stdout + checked.stderr)
    (dest / 'build_manifest_check.json').write_text(json.dumps(record, indent=2))
    if checked.returncode:
        raise ValueError(record['output'])


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    if args[0] == 'layout':
        layout(Path(args[1]), Path(args[2]))
    else:
        review(Path(args[1]))
