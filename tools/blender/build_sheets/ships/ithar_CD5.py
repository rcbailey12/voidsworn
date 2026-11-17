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
SHEET = dict(version=2, round='R298 / CD5 r2', date='2026-11-17', stage='sheet built')
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
}


def width(x):
    return (0.08 + 3.75 * max(0.0, math.sin(math.pi * (x + 12.75) / 23.0)) ** 0.68
            + 2.65 * math.exp(-((x + 12.6) / 2.5) ** 2))


def flow_phase(x):
    return 0.12 * x + 0.42 * math.sin(x * 0.23)


def skin(x, a, inset=0.0):
    """Mirrored flow, not polygon panels. The lens saddles are part of this surface."""
    w = max(0.035, width(x) - inset)
    env = max(0.0, math.sin(math.pi * (x + 12.75) / 23.0)) ** 0.45
    folded = math.atan2(math.sin(a), abs(math.cos(a)))
    # Broad poured ridges wrap a full oval body. No fluted slab or isolated peaks.
    ridge = 4 * (folded - flow_phase(x))
    flow = 1.0 + 0.16 * math.cos(ridge) + 0.030 * math.cos(2 * ridge)
    y = w * math.cos(a) * flow
    h = 0.30 + 2.15 * env + 0.85 * math.exp(-((x + 12.4) / 2.2) ** 2)
    z = (h - inset) * math.sin(a) * flow
    # Gentle broad swells in the skin support round lenses, rather than tent peaks.
    if math.sin(a) > 0:
        bump = sum(math.exp(-((x - ox) / 1.65) ** 2 - (y / 1.30) ** 2)
                   for ox, _, _, _ in OPTICS)
        z += 0.24 * bump * math.sin(a) ** 4
    return (x, y, z)


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
    import kit
    # The approval contains small refracted lights inside each coloured pane.
    # These are geometry/material zones, with no painted or projected concept art.
    for colour in ('amber', 'violet', 'green'):
        rgb, em, rough, trans, metal = ZONES['cd5_' + colour]
        ZONES['cd5_' + colour + '_deep'] = (tuple(c * 0.25 for c in rgb), em * 0.25, rough, trans, metal)
        ZONES['cd5_' + colour + '_hot'] = (tuple(min(1, c * 1.2 + 0.09) for c in rgb), em * 1.9, rough, trans, metal)
    for name, (rgb, em, rough, trans, metal) in ZONES.items():
        kit.MATS[name] = (rgb, em)
        m = kit.mat(name)
        bs = m.node_tree.nodes.get('Principled BSDF')
        bs.inputs['Roughness'].default_value = rough
        bs.inputs['Metallic'].default_value = metal
        bs.inputs['Transmission Weight'].default_value = trans
        bs.inputs['IOR'].default_value = 1.47
        bs.inputs['Coat Weight'].default_value = 0.45
        bs.inputs['Coat Roughness'].default_value = 0.12
        if name.startswith('cd5_pane_'):
            # Continuous light pools, made from the pane's own parametric coordinates.
            att = m.node_tree.nodes.new('ShaderNodeAttribute'); att.attribute_name = 'pane_light'
            ramp = m.node_tree.nodes.new('ShaderNodeValToRGB')
            ramp.color_ramp.elements[0].color = tuple(c * 0.12 for c in rgb) + (1,)
            ramp.color_ramp.elements[1].color = rgb + (1,)
            ramp.color_ramp.interpolation = 'EASE'
            m.node_tree.links.new(att.outputs['Fac'], ramp.inputs['Fac'])
            m.node_tree.links.new(ramp.outputs['Color'], bs.inputs['Base Color'])
            m.node_tree.links.new(ramp.outputs['Color'], bs.inputs['Emission Color'])
        if name == 'cd5_drive':
            # White stored light catches the curved optic at grazing angles too,
            # so the aft cluster keeps its soft bloom at the overhead battle camera.
            facing = m.node_tree.nodes.new('ShaderNodeLayerWeight')
            ramp = m.node_tree.nodes.new('ShaderNodeValToRGB')
            ramp.color_ramp.elements[0].color = rgb + (1,)
            ramp.color_ramp.elements[1].color = (0.88, 0.84, 1.0, 1)
            m.node_tree.links.new(facing.outputs['Fresnel'], ramp.inputs['Fac'])
            m.node_tree.links.new(ramp.outputs['Color'], bs.inputs['Base Color'])
            m.node_tree.links.new(ramp.outputs['Color'], bs.inputs['Emission Color'])
    # Pearly streams fade continuously into clear glass. Face-by-face zoning made
    # jagged stair steps in run 1 and is unsuitable for seamless blown glass.
    m = kit.mat('cd5_body_clear'); nodes = m.node_tree.nodes; links = m.node_tree.links
    clear = nodes.get('Principled BSDF')
    pearl = nodes.new('ShaderNodeBsdfPrincipled')
    for inp in clear.inputs:
        if hasattr(inp, 'default_value') and inp.name in pearl.inputs:
            pearl.inputs[inp.name].default_value = inp.default_value
    pearl.inputs['Base Color'].default_value = (0.72, 0.77, 0.83, 1)
    pearl.inputs['Transmission Weight'].default_value = 0.56
    pearl.inputs['Metallic'].default_value = 0.28
    pearl.inputs['Roughness'].default_value = 0.14
    att = nodes.new('ShaderNodeAttribute'); att.attribute_name = 'pearl_flow'
    mix = nodes.new('ShaderNodeMixShader')
    links.new(att.outputs['Fac'], mix.inputs[0])
    links.new(clear.outputs[0], mix.inputs[1]); links.new(pearl.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], nodes.get('Material Output').inputs['Surface'])
    kit.KIT_NAME = 'ithar_CD5 hand-built (no faction kit yet)'


def own_part():
    # Part is a data container, not a borrowed shape.
    from kit import HP
    p = HP.Part('gun')
    p.type = 'gun'
    return p


def optical_gun(K, x, fid, weapon, colour):
    """The hidden rotating element fits within a continuous grown glass saddle."""
    p = own_part()
    p.add('integral_root', 'mount', 'cd5_body_clear', ellipsoid((0, 0, -0.30), (1.08, 1.08, 0.48), 64, 28))
    # A round internal lens turns inside the continuous clear glass envelope.
    p.add('lens', 'turn', 'cd5_body_clear', ellipsoid((0, 0, 0), (0.60, 0.60, 0.16), 64, 28))
    p.add('stored_light', 'turn', 'cd5_' + colour, ellipsoid((0, 0, 0), (0.52, 0.52, 0.14), 64, 28))
    # The exit is on the forward face, not a disconnected hard point or a flat disc.
    p.fit = dict(pivot=('p', (0, 0, 0)), reach=0.60, radius=0.60,
                 muzzles=[('p', (0.60, 0, 0))], aim=('d', (1, 0, 0)))
    crest = max(skin(x + 0.62 * i / 8, math.pi / 2 + 0.35 * j / 8)[2]
                for i in range(-8, 9) for j in range(-8, 9))
    K.gun(fid, (x, 0, crest + 0.30), 0, cal=0.09, blen=0.60, slot='T', weapon=weapon,
          part=p, inv=['secondary_optics'], band=(0, 5, 10, 15, 20, 30),
          note='Grown %s optic; inner lens rotates under unbroken clear skin, 360 degrees; %s slot.' % (colour, weapon))
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
    p.add('drawn_waveguide', 'mount', 'cd5_clear', tube_mesh(pts, radii, 32))
    for k in range(5):
        a = k * 2 * math.pi / 5
        line = [(q[0], q[1] + r * math.cos(a + 1.7 * i / 100),
                 q[2] + r * math.sin(a + 1.7 * i / 100)) for i, (q, r) in enumerate(zip(pts, radii))]
        p.add('flowing_vein%d' % k, 'mount', 'cd5_silver', tube_mesh(line, [0.016] * len(line), 6))
    for k, col in enumerate(('amber', 'violet', 'green')):
        line = [(q[0], q[1] + radii[i] * 0.32 * math.cos(k * 2.1), q[2]) for i, q in enumerate(pts)]
        p.add('inner_pane%d' % k, 'mount', 'cd5_' + col,
              tube_mesh(line, [max(0.008, r * 0.26) for r in radii], 10))
    p.add('aperture', 'mount', 'cd5_white', ellipsoid((9.975, side * 0.8, -0.22), (0.025, 0.027, 0.027), 24, 10))
    p.fit = dict(pivot=('p', (10, side * 0.8, -0.22)), reach=0.06, radius=0.64,
                 muzzles=[('p', (10, side * 0.8, -0.22))], aim=('d', (1, 0, 0)))
    K.gun(fid, (3, side * 2.05, 0.92), 0, cal=0.06, blen=10, fixed=True,
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
    vf = grid_surface(skin, 184, 96, -12.75, 10.25)
    hull = K._obj(CODE + '_flowing_skin', *vf, 'cd5_body_clear', smooth=True)
    pearl = hull.data.attributes.new('pearl_flow', 'FLOAT', 'POINT')
    for i, value in enumerate(pearl.data):
        ix, ia = divmod(i, 96)
        x = -12.75 + 23.0 * ix / 184
        a = ia * 2 * math.pi / 96
        a = math.atan2(math.sin(a), abs(math.cos(a)))
        value.value = max(0, min(1, (math.cos(4 * (a - flow_phase(x))) - 0.10) / 0.60))
    md = hull.modifiers.new('shell', 'SOLIDIFY')
    md.thickness = 0.065
    md.offset = -1
    K.mass('Single flowing leaf', hull, 'clear and milky blown glass',
           note='One continuous ridged skin, shaped lens roots and a worked belly; silver follows the flow, no panels.')
    K.mark('flowing_hull', 'hull', ['bevel', 'step', 'overhang'])
    # Broad, smooth internal panes, shaped as flowing pools rather than full-length bars.
    # A single calm material per pane removes the random triangle glints of run 1.
    for side in (-1, 1):
        for row in range(4):
            for bay, (xc, span) in enumerate(((-9.6, 3.0), (-3.1, 3.4), (4.45, 4.05))):
                a0 = -math.pi / 2 + (row + 0.5) * math.pi / 4
                def pane(t, v, xc=xc, span=span, a0=a0, side=side):
                    x = xc + span * (2 * t - 1)
                    # Monotone angular warp stays in this side of the skin. Separate
                    # bays never overlap, avoiding coplanar coloured glass and moire.
                    a = math.atan(math.tan(a0 + v * 0.34 * math.sin(math.pi * t) ** 0.65)
                                  + 0.85 * math.sin(x * 0.22))
                    p = skin(x, a, inset=0.16)
                    return (p[0], side * p[1], p[2])
                vv, ff = grid_surface(pane, 72, 18, 0.002, 0.998, -1, 1, False)
                colour = ('green', 'amber', 'violet')[(row + bay) % 3]
                ob = K._obj('inner_colour_pane_%s_%s_%s' % (side, row, bay), vv, ff,
                            'cd5_pane_' + colour, smooth=True)
                light = ob.data.attributes.new('pane_light', 'FLOAT', 'POINT')
                for i, value in enumerate(light.data):
                    t = 0.002 + 0.996 * (i // 19) / 72
                    v = -1 + 2 * (i % 19) / 18
                    value.value = (0.35 + 0.65 * math.sin(math.pi * t)) * (0.40 + 0.60 * math.cos(v * math.pi / 2))
                ob['zone'] = 'smooth inner colour pane'
                # Veins divide the flowing panes beneath the skin, never armour seams.
                for edge in (-1, 1):
                    pts = [pane(0.002 + 0.996 * i / 100, edge) for i in range(101)]
                    K._obj('pane_vein_%s_%s_%s_%s' % (side, row, bay, edge),
                           *tube_mesh(pts, [0.024] * len(pts), 7), 'cd5_silver', smooth=True)
    # Broad helical ridges are already part of the skin; these thin veins trace their crests.
    for side in (-1, 1):
        for k in range(4):
            pts = []
            for i in range(185):
                x = -12.65 + 22.8 * i / 184
                a = -math.pi / 2 + k * math.pi / 2 + flow_phase(x)
                p = skin(x, a, inset=-0.012)
                pts.append((p[0], side * p[1], p[2]))
            K._obj('silver_flow_%s_%02d' % (side, k),
                   *tube_mesh(pts, [0.034] * len(pts), 9), 'cd5_silver', smooth=True)
    lance(K, 1, 'L1')
    lance(K, -1, 'L2')
    for x, fid, wk, col in OPTICS:
        optical_gun(K, x, fid, wk, col)
    # The three stern lenses are propulsion, never extra weapons. Optical depth, no flame.
    for k, y in enumerate((-1.90, 0.0, 1.90)):
        fid = 'E%d' % (k + 1)
        ob = K._obj(fid + '_grown_stern', *ellipsoid((-12.05, y, -0.02), (0.85, 0.93, 0.98), 64, 32),
                    'cd5_body_clear', smooth=True, grp=fid, role='mount')
        ob['part_kind'] = 'engine'; ob['machine'] = 1
        K._obj(fid + '_deep_lens', *ellipsoid((-12.67, y, -0.02), (0.32, 0.86, 0.88), 64, 32),
               'cd5_drive', smooth=True, grp=fid, role='mount')
        K._obj(fid + '_white_bloom', *ellipsoid((-12.81, y, -0.02), (0.18, 0.44, 0.46), 64, 32),
               'cd5_drive_core', smooth=True, grp=fid, role='mount')
        for j in range(11):
            a = j * 2 * math.pi / 11
            pts = [(-12.05 + 0.855 * math.cos(u), y + 0.935 * math.sin(u) * math.cos(a),
                    -0.02 + 0.985 * math.sin(u) * math.sin(a))
                   for u in [0.07 + i * 3.0 / 32 for i in range(33)]]
            K._obj(fid + '_silver_flow_%02d' % j, *tube_mesh(pts, [0.014] * len(pts), 7),
                   'cd5_silver', smooth=True, grp=fid, role='mount')
        if k == 1:
            # The middle drive is enclosed by the broad stern. Its internal feed
            # joins the skin, rather than relying on a floating enclosed sphere.
            K._obj(fid + '_internal_feed',
                   *tube_mesh([(-12.05, 0, 0), skin(-12.05, math.pi / 2)], [0.07, 0.07], 12),
                   'cd5_clear', smooth=True, grp=fid, role='mount')
        for o in K.coll.objects:
            if o.get('grp') == fid:
                o['part_kind'] = 'engine'; o['machine'] = 1
        K.features.append(dict(id=fid, kind='engine', what='grown stern drive optic, white bloom', count=1,
                               pos=(-13, y, -0.02), exit=(-13, y, -0.02), radius=0.86,
                               aim=(180, 0), src='picture', note='Drive lens only; no flame, exhaust mesh or weapon.', inv=['stern_cluster']))
        K.fitdata.append(dict(id=fid, kind='engine', cones=[dict(apex=(-13, y, -0.02), dir=(-1, 0, 0), r0=0.86, half=10, length=5)]))
        K.built.append(dict(id=fid, kind='engine', inv=['stern_cluster'], shaped=True, detailed=True,
                            subs=['grown root', 'recessed lens', 'stored light', 'bloom']))
    # Full internal construction follows the leaf, not rectangular room boxes.
    for z, name in ((-0.55, 'lower'), (0.20, 'upper')):
        vv, ff = grid_surface(lambda x, t: (x, (width(x) - 0.40) * t, z),
                             80, 14, -11.8, 8.6, -0.73, 0.73, False)
        ob = K._obj('in_deck_' + name, vv, ff, 'cd5_frame', inside=True)
        mod = ob.modifiers.new('shell', 'SOLIDIFY'); mod.thickness = 0.06
        K.inside.append(dict(kind='deck', name=name, z=z, x=(-11.8, 8.6), note='layered glass deck follows the leaf'))
    for i in range(15):
        x = -11.6 + 1.35 * i
        pts = [skin(x, a * 2 * math.pi / 64, inset=0.23) for a in range(65)]
        K._obj('in_frame_%02d' % i, *tube_mesh(pts, [0.065] * len(pts), 8), 'cd5_frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name='annealed frame %02d' % i, x=x, note='open structural glass frame'))
    for k, col in enumerate(('amber', 'violet', 'green')):
        pts = [(-11.8 + 21.0 * i / 100, 0.42 * math.cos(i * 0.07 + k * 2.1),
                -0.10 + 0.30 * math.sin(i * 0.07 + k * 2.1)) for i in range(101)]
        K._obj('in_light_core_' + col, *tube_mesh(pts, [0.14] * len(pts), 12), 'cd5_' + col, inside=True, smooth=True)
    for x, fid, _, col in OPTICS:
        K._obj('in_reservoir_' + fid, *ellipsoid((x, 0, 0.55), (0.9, 0.75, 0.50)),
               'cd5_' + col, inside=True, smooth=True)
        K.inside.append(dict(kind='space', name=fid + ' light reservoir', x=(x - 0.9, x + 0.9),
                             y=(-0.75, 0.75), z=(0.05, 1.05), mat='cd5_' + col, note='optic power and steering chamber'))
    K.inside.append(dict(kind='space', name='continuous light core and stern drive chamber', x=(-12, 9),
                         y=(-0.8, 0.8), z=(-0.6, 0.9), mat='layered glass and light', note='three braided waveguides throughout the hull'))
    K.armour('annealed outer glass', 0.065, 'actual shell thickness; layered blown glass, no armour plates')
    # Jagged transverse tears bracket each secondary bay. Forward lances stay whole
    # on the bow piece. The three stern drives each retain their own machine group.
    for i, x in enumerate((-10.95, -7.45, -4.55, -1.45, 1.45)):
        path = [(x + dx, y) for dx, y in ((0, -6), (0.13, -3), (-0.12, -1.4),
                                         (0.09, 0), (-0.14, 1.3), (0.12, 3), (0, 6))]
        K.break_line('B%d' % (i + 1), x, 'ragged shatter path at the lens bay; whole optics, never a straight saw cut', path=path)
    # Fore optic peels away above the forward waveguides, without cutting either lance.
    K.break_line('O3-peel', 6.0, 'whole fore optic above the flowing skin; one compartment',
                 path=[(4.6, 1.66), (7.4, 1.66)], kind='long')
    K.point('core', 'hp_core', (-0.4, 0, 0.10))
    for i, (x, side, sec) in enumerate(((-8.8, 1, 'eng'), (-8.8, -1, 'eng'),
                                       (-3.1, 1, 'mid'), (-3.1, -1, 'mid'), (4, 1, 'prow'),
                                       (4, -1, 'prow'), (8, 1, 'prow'))):
        K.point('breach', 'hp_breach_%d' % i, skin(x, 0.25 if side > 0 else math.pi - 0.25),
                side='port' if side > 0 else 'stbd', section=sec)
    for i, (x, a) in enumerate(((-9, 0), (6, math.pi))):
        K.point('rcs', 'hp_rcs_%d' % i, skin(x, a))
        K.point('board', 'hp_board_%d' % i, skin(x, a))
    K.colour('clear and milky blown glass, silver veins', 10.25, -13, 'continuous hull, underside and drawn forward lances')
    K.colour('amber, violet, green inner panes', 10.0, -12.6, 'beneath the clear skin; emissive stored light')
    K.colour('soft white bloom', -12.7, -13, 'three stern drive optics, no flame')
    K.fix('Run 1 secondary roots read as tent peaks',
          'Broad 0.24-high skin swells carry 1.20-wide round lens caps; their moving glass clears the highest local ridge and vein.')
    K.fix('Run 1 stern drive optics read as small dots',
          'Doubled lens radius to 0.86, widened the grown stern and placed three complete drives 1.90 apart.')
    K.fix('Enlarged stern shoulders crossed the old B1 shatter path',
          'Moved B1 forward to x=-10.95 so all three drive optics remain whole, without an audit exemption.')
    K.change('Three round secondary optics at x=-6, 0, +6 on the centreline, set into gentle glass swells',
             'R298: even, balanced spacing and all-direction arcs; amber = pulsar T, violet = turret T, green = flak T. The stern cluster is propulsion.')
    K.change('Two separate long drawn-glass lances, one per forward pulsar slot',
             'Keep Ryan\'s loved long forward lances; the model uses the game\'s two F slots and visible optical exits.')
    K.change('Deep rounded leaf with broad twisting ridges, smooth internal panes and full glass insides',
             'The single three-quarter concept cannot settle the underside or depths; faction symmetry and R215 supply them.')
    K.change('Breaks bracket the lens bays; O3 is an upper peel clear of both lances',
             'Glasswrights shatter; each large optic remains a whole part. The forward lances cannot be cut by a new transverse seam.')
    K.open_item('Schematic physical glass and colour-zone materials only. No Glasswright paint stack exists; no other faction stack applied.')
    K.open_item('Sheet built, not installed in Godot. Board comparison and Ryan visual acceptance remain separate from technical checks.')


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
    sc.use_nodes = True
    nodes = sc.node_tree.nodes; nodes.clear()
    layer = nodes.new('CompositorNodeRLayers')
    glow = nodes.new('CompositorNodeGlare'); glow.glare_type = 'FOG_GLOW'
    glow.quality = 'HIGH'; glow.threshold = 1.5; glow.size = 7; glow.mix = -0.85
    composite = nodes.new('CompositorNodeComposite')
    sc.node_tree.links.new(layer.outputs['Image'], glow.inputs['Image'])
    sc.node_tree.links.new(glow.outputs['Image'], composite.inputs['Image'])
    world = bpy.data.worlds.new('CD5 dark studio'); sc.world = world; world.use_nodes = True
    world.node_tree.nodes['Background'].inputs[0].default_value = (0.025, 0.035, 0.055, 1)
    world.node_tree.nodes['Background'].inputs[1].default_value = 0.36
    def area(name, pos, energy, size, colour):
        ld = bpy.data.lights.new(name, 'AREA'); ld.energy = energy; ld.shape = 'RECTANGLE'
        ld.size = size; ld.size_y = size * 0.14; ld.color = colour
        ob = bpy.data.objects.new(name, ld); sc.collection.objects.link(ob); ob.location = pos
        ob.rotation_euler = (-ob.location).to_track_quat('-Z', 'Y').to_euler()
    area('long pearl reflection', (0, -8, 13), 1600, 22, (0.78, 0.85, 1.0))
    area('warm inner light reflection', (3, 7, 9), 1500, 18, (1.0, 0.74, 0.47))
    area('stern edge reflection', (-10, 2, 4), 1500, 12, (0.60, 0.73, 1.0))
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
        d.text((24, 51), 'R298 | r2 | design ' + rev + ' | SHEET BUILT | glass colour zones, no faction paint stack', fill='#a9bdc9', font=small)
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
    d.text((24, 575), 'R2: deeper twisted glass, round inset optics, broad smooth inner panes, three large stern lenses.', fill=ink, font=font)
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
    d.text((24, 575), 'Centreline x = -6, 0, +6. Same 6-unit spacing; round internal lenses turn inside continuous clear glass.', fill=ink, font=font)
    d.text((24, 603), 'Stern (left): three drive optics. Bow (right): L1 and L2, one per forward pulsar slot.', fill=ink, font=small)
    save(im, 'top.jpg')
    for name, caption in (('side', 'side / rounded body and low lens swells'),
                          ('camera170', 'camera 170 / true Ark size 41.6'), ('inside', 'inside / full-length glass construction')):
        im = canvas(caption)
        if name == 'camera170':
            im.paste(Image.open(src / 'camera170.png').crop((320, 252, 1600, 828)), (0, 76))
        else:
            put(im, src / (name + '.png'), (0, 76, 1280, 653))
        d = ImageDraw.Draw(im)
        text = ('Blender proxy: radius 170, vertical FOV 45, beta 0.98, size 41.6; 1920x1080 crop at 1:1; no game install.' if name == 'camera170'
                else 'Rounded middle, twisting ridges and round lit lens caps. Both run 1 forward lances preserved.' if name == 'side'
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
    lines = ['# CD5 feature table', '', 'Revision r2. Generated from the same Blender model as the pictures. Counts outrank pictures.', '',
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
              'Seven breach anchors (Ark base 8 minus Glasswright 1), one core, two RCS and two boarding origins.', '',
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
