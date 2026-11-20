"""ithar_GF1: the Needle, the Glasswright fighter wing craft (data.js fighter: cls 'Squadron', guns T; hp 18, sp 6).

Issue 1373 (R362: anything solid near a ship is built from the ship part kits and takes the hull finish). Ryan picked GF1 from
three kit-built options on Nov 20 2026 (decision card, 18:38 UTC; the sheet: /mnt/project-files/board/1373/
GW_craft_options_r1.jpg, the concept of record docs/ship_pipeline/build_sheets/ithar_GF1/concept.jpg).
Built on the shared Glasswright kit (tools/blender/kits/ithar: pearl ribbons, silver edges, the glowing mosaic core, cut
stones), so every change to that kit (PR 1283's warmer look and after) reaches this craft too (R333).
Ryan's craft rules that bind (R254, R259): space craft, not aircraft: no canopy, no swept aero wings, no tail fins, nothing
hung under the hull. Glasswrights are a small elite fleet (Ryan, Nov 20): sleek, never a swarm.
Size: docs/playbooks/scale.md, Squadron row (binding): CLS_LEN['Squadron'] 1.6 long, drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84.
+X bow, +Y port, +Z up. Bow point x = +0.8, the stern stones x = -0.8.
  blender -b -P tools/blender/build_sheets/build.py -- ithar_GF1 OUT render
"""
import importlib.util
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
CODE = 'ithar_GF1'
NAME = 'The Needle, the Glasswright fighter wing craft'
FACTION = 'The Glasswrights (ithar)'
CLASS = 'Squadron'
LENGTH = 1.6
GAME = "data.js fighter (cls 'Squadron', the Glasswright wing: ithar sq 'fighter'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = 'docs/ship_pipeline/build_sheets/ithar_GF1/concept.jpg'
CONCEPT_SHEET = BEAUTY
SHEET = dict(version=1, round='first sheet (Ryan\'s GF1 pick)', date='2026-11-20', blend='opus1373', px_per_unit=900, view_pad=0.12,
             label_scale=1.5, bar_units=0.5, stage='blockout + paint preview',
             blend_where='built in the issue 1373 cloud thread (Blender 4.5 bpy wheel, Cycles CPU); `build.py ithar_GF1 <out> render` rebuilds it from this file',
             before='The GF1 option', before_note='The option Ryan picked (gw_craft_options.py GF1), made a full sheet: thick ribbons, the gun optic, the stern stones, an inside.',
             during='The table above is every finding, in the order the check made them.')
CAMERA = dict(az=220.0, el=28.0, roll=0.0, scale=2.0)


def U(v):
    """a share of the craft's length in world units"""
    return v * LENGTH


def gw_kit(name):
    """load a Glasswright kit module under its own name (another kit's parts.py may already be imported as `parts`)"""
    key = 'ithar_' + name
    if key not in sys.modules:
        spec = importlib.util.spec_from_file_location(key, ROOT / 'tools/blender/kits/ithar' / (name + '.py'))
        mod = importlib.util.module_from_spec(spec); sys.modules[key] = mod; spec.loader.exec_module(mod)
    return sys.modules[key]


TAU = 2 * math.pi
X0, X1 = -0.5 * LENGTH + 0.03 * LENGTH, 0.5 * LENGTH   # the core; the stern stones stand on its blunt face out to -0.8
HW, HH = 0.095 * LENGTH, 0.070 * LENGTH   # the core's half-beam and half-height at its widest (about 5 to 1)
BOW_EXP = 0.75   # how fast the core swells from its bow point (t=1 is the bow, X1); lower is a blunter, rounder bow (the bomber sets it)
MOSAIC_WEIGHTS = None           # the mosaic's amber, violet, green shares; None: the kit's (the bomber sets its own)


def core(x, a, inset=0.0):
    """the spindle core: a point at the bow, a blunt face at the stern for the stones. a: 0 port beam, pi/2 top"""
    t = (x - X0) / (X1 - X0)
    if t < 0.0 or t > 1.0:
        return (min(X1, max(X0, x)), 0.0, 0.0)
    env = math.sin(math.pi * t ** 0.9) ** (BOW_EXP if t > 0.5 else 0.45)
    env = max(env, 0.10 if t < 0.5 else 0.0)
    w = max(0.0, HW * (1 + 0.15 * math.sin(math.pi * t)) * env - inset)
    h = max(0.0, HH * env - inset)
    return (x, w * math.cos(a), h * math.sin(a))


NRIB = 6
TWIST = lambda x: 0.9 * (x - X0) / LENGTH + 0.25 * math.sin(3.0 * x / LENGTH)
CORE_NOTE = 'a slim spindle about 5 to 1, a point at the bow, a blunt stern face for the stones'
HALF = 0.29       # a ribbon's half width at its widest, radians of the section (six ribbons cover a little over half)
RIB_T = U(0.006)  # ribbon thickness


def ribbons():
    P = gw_kit('parts')
    out = []
    for k in range(NRIB):
        prof = P.leaf(0.7, 0.55, 0.4, 0.05)
        out.append(P.Ribbon(X0 + U(0.02), X1, (lambda x, k=k: 0.4 + k * TAU / NRIB + TWIST(x)), (lambda t, f=prof: HALF * f(t)),
                            (lambda t, v: U(0.006) + U(0.004) * (1 - abs(v)) * math.sin(math.pi * t)), 'ribbon_%d' % k))
    return out


def gaps(x, a, ribs):
    """which ribbon gap a core point sits in, its leaf coordinate along the gap and its place across it (0..1)"""
    cs = sorted(((r.centre(x) % TAU), i) for i, r in enumerate(ribs))
    a0 = a % TAU
    for i in range(len(cs)):
        c0 = cs[i][0]
        c1 = cs[(i + 1) % len(cs)][0] + (TAU if i == len(cs) - 1 else 0)
        aa = a0 if a0 >= c0 else a0 + TAU
        if c0 <= aa <= c1:
            return cs[i][1], 4.0 * (x / LENGTH + 0.5) + 0.3 * cs[i][1], (aa - c0) / max(1e-6, c1 - c0)
    return 0, 0.0, 0.5


def grid(fn, nu, nv, u0, u1):
    verts = [fn(u0 + (u1 - u0) * i / nu, TAU * j / nv) for i in range(nu + 1) for j in range(nv)]
    faces = [(i * nv + j, i * nv + (j + 1) % nv, (i + 1) * nv + (j + 1) % nv, (i + 1) * nv + j) for i in range(nu) for j in range(nv)]
    return verts, faces


def thick_ribbon(r, nu=72, nv=6):
    """a ribbon with real thickness: its top layer, an under layer RIB_T below along the core's normal, and walls round the rim"""
    P = gw_kit('parts')
    top, bot, along, across = [], [], [], []
    for i in range(nu + 1):
        t = i / nu
        for j in range(nv + 1):
            v = -1 + 2 * j / nv
            x = r.x0 + (r.x1 - r.x0) * t
            a = r.centre(x) + v * r.half(t)
            h = r.lift(t, v)
            top.append(P.outward(core, x, a, h)); bot.append(P.outward(core, x, a, max(0.0, h - RIB_T)))
            along.append(t); across.append(v)
    row = nv + 1; n = len(top)
    faces = [(i * row + j, i * row + j + 1, (i + 1) * row + j + 1, (i + 1) * row + j) for i in range(nu) for j in range(nv)]
    faces += [tuple(q + n for q in reversed(f)) for f in faces[:nu * nv]]
    rim = list(range(row)) + [i * row + nv for i in range(1, nu + 1)] + [nu * row + j for j in range(nv - 1, -1, -1)] + [i * row for i in range(nu - 1, 0, -1)]
    for a_, b_ in zip(rim, rim[1:] + rim[:1]):
        faces.append((b_, a_, a_ + n, b_ + n))
    return top + bot, faces, along + along, across + across


def tube_mesh(points, radii, n=6):
    from mathutils import Vector
    vv, ff = [], []
    pts = [Vector(p) for p in points]
    for i, p in enumerate(pts):
        d = pts[min(i + 1, len(pts) - 1)] - pts[max(0, i - 1)]
        d = d.normalized() if d.length > 1e-9 else Vector((1, 0, 0))
        q = d.cross(Vector((0, 0, 1)))
        q = q.normalized() if q.length > 0.1 else d.cross(Vector((0, 1, 0))).normalized()
        w = d.cross(q).normalized()
        for j in range(n):
            an = j * TAU / n
            vv.append(tuple(p + radii[i] * (q * math.cos(an) + w * math.sin(an))))
    for i in range(len(pts) - 1):
        for j in range(n):
            a_, b_ = i * n + j, i * n + (j + 1) % n
            ff.append((a_, b_, b_ + n, a_ + n))
    return vv, ff


def ellipsoid(c, r, n=16, rings=8):
    verts, faces = [], []
    for i in range(rings + 1):
        u = 0.001 + (math.pi - 0.002) * i / rings
        for j in range(n):
            v = TAU * j / n
            verts.append((c[0] + r[0] * math.cos(u), c[1] + r[1] * math.sin(u) * math.cos(v), c[2] + r[2] * math.sin(u) * math.sin(v)))
    for i in range(rings):
        for j in range(n):
            faces.append((i * n + j, i * n + (j + 1) % n, (i + 1) * n + (j + 1) % n, (i + 1) * n + j))
    return verts, faces


def own_part(kind):
    from kit import HP
    p = HP.Part(kind)
    p.type = kind
    return p


GX = U(0.075)     # the gun optic's station on the spine
STONES = [(0.5, 'p'), (2.6, 'u'), (4.7, 's')]   # the three stern stones round the stern face (section angle, name)


def build(K):
    """the fighter: the shared body plus the interceptor optic"""
    body(K)
    gun_optic(K)
    K.change('One turning cut optic stands for the interceptor guns (three pulses per volley), not three barrels',
             'the Glasswrights fight with light from cut stones (the Ark\'s optics, CD5), never metal barrels')


def body(K):
    """the Needle family's body (ithar_GB1, the bomber, builds the same with its own proportions): the mosaic core, the
    ribbons, the stern stones, the colour zones, the small inside and the records"""
    import kit
    stack = gw_kit('stack')
    stack.setup(kit)
    P = gw_kit('parts')
    ribs = ribbons()

    # ---------------- the core: the glowing stained-glass mosaic seen between the ribbons ----------------
    nu, nv = 64, 40
    vf = grid(core, nu, nv, X0, X1)
    hull = K._obj(CODE + '_mosaic_core', *vf, 'gw_mosaic', smooth=True)
    # the core's glass wall: a thin inward shell (stage 4's sheet contract reads the hull thickness from a shell modifier)
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = U(0.004); md.offset = -1; md.use_rim = True
    hull.data.color_attributes.new('gw_tint', 'FLOAT_COLOR', 'POINT')
    hull.data.attributes.new('gw_glow', 'FLOAT', 'POINT')
    tint, glow = hull.data.attributes['gw_tint'], hull.data.attributes['gw_glow']   # fetch both after creating both
    for i in range(len(tint.data)):
        ix, iv = divmod(i, nv)
        x = X0 + (X1 - X0) * ix / nu; a = TAU * iv / nv
        rgb, g = P.mosaic_tint(x, a, lambda x_, a_: gaps(x_, a_, ribs), stack.PALETTE, MOSAIC_WEIGHTS or stack.WEIGHTS, seed=6, tones=stack.TONES)
        tint.data[i].color = (rgb[0], rgb[1], rgb[2], 1.0)
        glow.data[i].value = g
    K.hull_sections = [(x, core(x, 0.0)[1], core(x, 0.0)[1], core(x, -math.pi / 2)[2], core(x, math.pi / 2)[2], 0.0, 0.0)
                       for x in [X1 - (X1 - X0) * i / 24 for i in range(25)]]
    K.mass('Mosaic core', hull, 'opaque glowing stained-glass mosaic', note=CORE_NOTE)
    K.mark('flowing_hull', 'hull', ['bevel', 'step', 'overhang'])

    # ---------------- six pearl ribbons twisting together to one point at the bow ----------------
    for r in ribs:
        vv, ff, al, ac = thick_ribbon(r)
        ob = K._obj(CODE + '_' + r.name, vv, ff, 'gw_pearl', smooth=True, grp='hull')
        ob.data.attributes.new('gw_along', 'FLOAT', 'POINT'); ob.data.attributes.new('gw_across', 'FLOAT', 'POINT')
        A, C = ob.data.attributes['gw_along'], ob.data.attributes['gw_across']
        for i in range(len(al)):
            A.data[i].value = al[i]; C.data[i].value = ac[i]
        for side in (-1, 1):
            e = r.edge(core, side, 72, U(0.0015))
            K._obj('%s_%s_silver_%s' % (CODE, r.name, 'p' if side > 0 else 's'), *tube_mesh(e, [U(0.0016)] * len(e), 5), 'gw_silver', smooth=True, grp='hull')
    K.mass('Pearl ribbons', ob, 'pearl ribbons with silver edges', note='six ribbons wrap the core stern to bow and twist together to one point, like a drawn flame')

    # ---------------- the drive: three cut violet stones round the blunt stern face (no flame, no nozzle) ----------------
    for ang, sn in STONES:
        fid = 'E' + sn
        y, z = U(0.022) * math.cos(ang), U(0.018) * math.sin(ang)
        ex = -0.5 * LENGTH + U(0.006)
        R = U(0.013)
        K._obj(fid + '_seat', *ellipsoid((ex + U(0.012), y, z), (U(0.014), R * 1.15, R * 1.15), 16, 8), 'gw_pearl', smooth=True, grp=fid)
        K._obj(fid + '_stone', *P.cut_lens((ex, y, z), (-1, 0, 0), R, R * 0.45, 10), 'gw_drive', grp=fid)
        K._obj(fid + '_core', *P.cut_lens((ex - U(0.001), y, z), (-1, 0, 0), R * 0.45, R * 0.6, 8), 'gw_drive_core', grp=fid)
        for o in K.coll.objects:
            if o.get('grp') == fid:
                o['part_kind'] = 'engine'; o['machine'] = 1
        K.features.append(dict(id=fid, kind='engine', what='cut violet drive stone, %.3f across' % (2 * R), count=1, pos=(ex, y, z), aim=(180, 0),
                               src='picture', note='a drive stone: light, never a flame or a nozzle', exit=(ex, y, z), radius=R, inv=['stern_stones']))
        K.fitdata.append(dict(id=fid, kind='engine', cones=[dict(apex=(ex, y, z), dir=(-1, 0, 0), r0=R, half=10, length=U(0.25))]))
        K.built.append(dict(id=fid, kind='engine', inv=['stern_stones'], shaped=True, detailed=True, subs=['pearl seat', 'cut stone', 'bright core']))

    # ---------------- colour zones ----------------
    K.colour('pearl ribbons, silver edges (the Glasswright kit)', X1, X0, 'the six ribbons')
    K.colour('amber, violet and green stained-glass mosaic, lit from behind', X1, X0, 'the core between the ribbons')
    K.colour('amber gun optic; violet drive stones', GX + U(0.02), X0, 'the spine optic, the stern face')

    # ---------------- INSIDE: kept small; the build contract needs one, the game never breaks a craft ----------------
    K.room('pilot', 'crew', U(0.08), U(0.16), -U(0.02), U(0.02), -U(0.012), U(0.022), note='the pilot\'s cell under the gun optic')
    K.room('light_core', 'core', U(-0.22), U(0.05), -U(0.03), U(0.03), -U(0.02), U(0.02), note='the stored light the mosaic glows with')
    K.room('drive_well', 'engroom', U(-0.40), U(-0.26), -U(0.025), U(0.025), -U(0.02), U(0.02), note='the light well that feeds the three stones')
    K.inside.append(dict(kind='note', name='insides', note='A craft: the game shows its death as a spark (godot/fx/fx_death.gd _wing_death); nothing breaks open. These few rooms are here because the build contract needs an inside.'))
    K.armour('annealed outer glass', U(0.004), 'pearl ribbons over the mosaic; no plates')
    K.break_line('B-1', U(-0.3), 'the craft shatters aft of the light core (records only: the game never breaks a craft)',
                 path=[(U(-0.3), U(0.3)), (U(-0.29), U(0.05)), (U(-0.31), 0.0), (U(-0.3), U(-0.05)), (U(-0.3), U(-0.3))])
    K.point('core', 'hp_core', (U(-0.05), 0.0, 0.0))

    K.change('Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as every craft; length to beam about 5 to 1',
             'docs/playbooks/scale.md, Squadron rows, binding; Glasswrights are a small elite fleet, so the craft is slim and sleek (Ryan, Nov 20)')
    K.change('Three cut violet drive stones on the blunt stern face, no flame or nozzle', 'the CD5 concept\'s stern stones in small')
    K.open_item('Colours and the ribbons\' sheen come from the shared Glasswright kit (tools/blender/kits/ithar/stack.py); PR 1283\'s warmer look reaches this craft when it merges')


def gun_optic(K):
    P = gw_kit('parts')
    # ---------------- the gun: one amber cut optic on the spine (data.js guns T, 3 shots; Interceptor guns) ----------------
    p = own_part('gun')
    p.add('integral_root', 'mount', 'gw_pearl', ellipsoid((0, 0, -U(0.004)), (U(0.026), U(0.022), U(0.008)), 16, 6))
    gv, gf = P.cut_lens((0, 0, 0.0), (0, 0, 1), U(0.016), U(0.010), 10)
    p.add('lens', 'turn', 'gw_gem_amber', (gv, gf))
    p.fit = dict(pivot=('p', (0, 0, 0)), reach=U(0.016), radius=U(0.018), muzzles=[('p', (U(0.016), 0, U(0.004)))], aim=('d', (1, 0, 0)))
    crest = core(GX, math.pi / 2)[2] + U(0.010)
    K.gun('G1', (GX, 0.0, crest), 0.0, cal=U(0.004), blen=U(0.016), barrels=3, slot='T', weapon='guns', part=p, inv=['gun_optic'],
          band=(0, 10, 20, 30), note='the interceptor guns (data.js guns T, 3 shots): one amber cut optic set in the ribbons on the spine; its stone turns, three pulses per volley')
    K.features[-1]['what'] = 'amber cut optic, interceptor guns'
    K.built[-1].update(detailed=True, subs=['pearl seat', 'cut stone'])
