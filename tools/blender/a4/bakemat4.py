# A4 copy of tools/blender/a2detail/bakemat.py (A2 max-detail bake material), extended for A4: Corsair (rust-and-bone patchwork, the
# barge's approved palette, R14), and the stern hull glow switched off when the ship has modelled engines (the bells carry their glow).
# A2 max-detail ships: the bake material. One node tree per ship whose outputs are baked to the new UV0 atlas:
#   albedo   faction base colour (today's game look), plate-to-plate tone, edge wear and crevice grime from the hulls_hi AO/curvature
#            map (hull) or Cycles AO and bevel (hand-built parts), undersides a touch darker, faction markings
#   orm      R occlusion, G roughness, B metal (glTF convention)
#   normal   the hulls_hi normal map (hull) plus fine procedural relief: panel seams per faction, grit (tangent space, baked)
#   emissive windows in short runs (faction window colour), running-light lenses and glowing parts, engine glow at the stern
# Node names and sockets used here exist in Blender 4.5 and 5.x (ShaderNodeMix, Separate/CombineColor, Voronoi F1/F2).
import math, os
import bpy

PAINT = os.environ.get('A4_PAINT', 'v2')  # paint v2 (Nov 1, feel pass), see PLATE below; A4_PAINT=v1 bakes the Oct 31 look

FAC = {  # from ships3d.js FAC3D (hull, dark, trim as sRGB hex; win and eng as linear). met/rgh: the painted-hull finish (the game's paint
    # mode runs metal about .08 to .36, roughness .5 to .6; the old flat-colour table had Hegemony at .40 metal, which reads as wet chrome
    # once the albedo carries the paint), so a painted hull is paint, with worn edges going to bare metal
    # Oct 27, lore approved (R59, contrib/opus/briefs/lore_rollout_2026-10-27.md): Sunward Crusade black iron, frost-white markings, ember
    'voidsworn': dict(hull='#2b2d31', dark='#111214', trim='#dfe6ec', win=(1, .42, .12), eng=(1, .50, .16), met=.40, rgh=.50),
    'hegemony': dict(hull='#c4ccd5', dark='#5a6573', trim='#3a78d0', win=(.78, .9, 1), eng=(.45, .72, 1), met=.14, rgh=.50),
    'chorus': dict(hull='#3b3a22', dark='#17160c', trim='#b5852f', win=(.78, .92, .22), eng=(.75, .90, .25), met=.02, rgh=.40),  # dark olive flesh, ochre chitin, bile glow
    'ithar': dict(hull='#9fb5c8', dark='#5e7082', trim='#d4d8de', win=(.85, .90, 1.0), eng=(.80, .86, 1.0), met=.55, rgh=.10),  # Glasswrights: crystal, silver, stored light
    'deathless': dict(hull='#1e1726', dark='#0d0a12', trim='#e9d9a6', win=(.85, .75, 1.0), eng=(1.0, .86, .58), met=.42, rgh=.42),  # Eclipse: violet-black, white-gold corona, violet-white glow
    'corsair': dict(hull='#5c2a1c', dark='#28140f', trim='#a3542c', win=(1, .4, .2), eng=(1, .38, .16), met=.30, rgh=.62),
}
if PAINT == 'v2':  # Nov 1 (vetoable): Hegemony a step darker so the plating reads (still pale grey, lore r8; the concept art is slate),
    # Crusade black iron a touch lighter (concept gunmetal) so panel lines and bevels show at battle distance
    FAC['hegemony']['hull'] = '#a3adb9'; FAC['voidsworn']['hull'] = '#33363b'
# Corsair hull tone cells: rust shades only. The stolen grey, steel and bone panels are real 3D plates (dress4.py); painted patch cells
# in those colours were tried on the barge and dropped because they read as warship dazzle camouflage, a naval tell (R14).
CORSAIR_PATCH = [((.100, .034, .014), .55), ((.16, .055, .022), .22), ((.060, .022, .010), .18), ((.12, .05, .03), .05)]


# Paint v2 (Nov 1 2026, feel pass; Ryan after his first Godot playtest: "painting and ship visuals looked incomplete"). The in-game check
# (docs/shots/a4/<sha>/README.md) showed the maps load, but the paint itself read as clay: Hegemony nearly white with no plating, Crusade
# black with blotchy white frost, Eclipse waxy with white scribbles from the AI curvature map. v2 paints the plating into the colour, the
# way the concept art shows it: dark panel lines at two sizes, a light bevel catch inside each big plate's edge, accent plates in a second
# tone, hatches and vent grilles on some plates, and grain from real photographed metal (CC0, ambientCG, already on the PC in
# Downloads\voidsworn_test\textures: TEXTURE_PASS.md) projected at one world scale for every ship. Edge wear and grime follow the real
# geometry (Cycles bevel and AO) more than the AI's blobby curvature map. A4_PAINT=v1 bakes the old look.
TEXROOT = os.environ.get('A4_TEXLIB') or os.path.join(os.path.expanduser('~'), 'Downloads', 'voidsworn_test', 'textures')
PLATE = {  # accent plates are a value step, never a strong hue (a first try with steel-blue plates read as dazzle camouflage, a naval tell)
    # ink: panel-line darkness (big plates, small plates; 1 = none); acc: accent plate colour and share; hi: bevel catch;
    # vent, hatch: share of big plates with a grille or an inset hatch; grain: photo set and strength; tile: world units per photo tile
    'hegemony': dict(ink=(.52, .74), acc='#8e9aab', acc_p=.18, hi=.30, vent=.07, hatch=.12, grain='Metal038', grain_k=.40, tile=5.0),
    'voidsworn': dict(ink=(.50, .72), acc='#4a4f57', acc_p=.24, hi=.60, vent=.09, hatch=.10, grain='Metal046B', grain_k=.65, tile=5.0),
    'deathless': dict(ink=(.55, .78), acc='#352a44', acc_p=.22, hi=.45, vent=.0, hatch=.10, grain='Metal027', grain_k=.55, tile=6.0),
    'corsair': dict(ink=(.62, .82), acc=None, acc_p=0, hi=.25, vent=.06, hatch=.06, grain='MetalPlates013', grain_k=.50, tile=4.0),
}
_GRAIN = {}


def grain_image(sid, kind):
    """a photo map from the CC0 library on the PC (None in the cloud, where the bake falls back to the procedural grain only), plus its
    mean (linear) so the grain only modulates the paint"""
    key = (sid, kind)
    if key in _GRAIN: return _GRAIN[key]
    p = os.path.join(TEXROOT, sid, f'{sid}_2K-JPG_{kind}.jpg'); r = (None, 1.0)
    if os.path.exists(p):
        im = bpy.data.images.load(p, check_existing=True)
        im.colorspace_settings.name = 'sRGB' if kind == 'Color' else 'Non-Color'
        try:
            import numpy as np
            px = np.empty(im.size[0] * im.size[1] * im.channels, np.float32); im.pixels.foreach_get(px)
            px = px.reshape(-1, im.channels)[::37, :3]
            if kind == 'Color': px = np.where(px <= .04045, px / 12.92, ((px + .055) / 1.055) ** 2.4); m = float((px * (.2126, .7152, .0722)).sum(1).mean())
            else: m = float(px[:, 0].mean())
        except Exception: m = .5 if kind != 'Color' else .2
        r = (im, max(m, 1e-3))
    _GRAIN[key] = r
    return r


def lin(h):
    c = [int(h[i:i + 2], 16) / 255. for i in (1, 3, 5)]
    return tuple(x / 12.92 if x <= .04045 else ((x + .055) / 1.055) ** 2.4 for x in c)


class G:
    """small node-graph helper"""
    def __init__(self, T): self.T = T; self.L = T.links
    def n(self, kind, **kw):
        x = self.T.nodes.new(kind)
        for k, v in kw.items(): setattr(x, k, v)
        return x
    def link(self, a, b): self.L.new(a, b)
    def _in(self, sock, v):
        if isinstance(v, (int, float)): sock.default_value = v
        elif isinstance(v, tuple): sock.default_value = v if len(v) == len(sock.default_value) else (*v, 1)
        else: self.link(v, sock)
    def math(self, op, a, b=0.0, clamp=False):
        x = self.n('ShaderNodeMath', operation=op); x.use_clamp = clamp; self._in(x.inputs[0], a); self._in(x.inputs[1], b); return x.outputs[0]
    def add(self, a, b): return self.math('ADD', a, b)
    def mul(self, a, b): return self.math('MULTIPLY', a, b)
    def rng(self, v, a, b, c, d, clamp=True):
        x = self.n('ShaderNodeMapRange'); x.clamp = clamp; self._in(x.inputs['Value'], v)
        for s, val in zip(('From Min', 'From Max', 'To Min', 'To Max'), (a, b, c, d)): x.inputs[s].default_value = val
        return x.outputs[0]
    def smooth(self, v, a, b):
        x = self.n('ShaderNodeMapRange', interpolation_type='SMOOTHSTEP'); self._in(x.inputs['Value'], v)
        x.inputs['From Min'].default_value = a; x.inputs['From Max'].default_value = b; return x.outputs[0]
    def vmath(self, op, a, b=None, s=None):
        x = self.n('ShaderNodeVectorMath', operation=op); self._in(x.inputs[0], a)
        if b is not None: self._in(x.inputs[1], b)
        if s is not None: self._in(x.inputs[3], s)
        return x.outputs['Value'] if op in ('DOT_PRODUCT', 'LENGTH', 'DISTANCE') else x.outputs['Vector']
    def mix(self, fac, a, b, mode='MIX'):
        x = self.n('ShaderNodeMix', data_type='RGBA', blend_type=mode); self._in(x.inputs['Factor'], fac)
        self._in(x.inputs[6], a); self._in(x.inputs[7], b); return x.outputs[2]
    def vmix(self, fac, a, b):
        x = self.n('ShaderNodeMix', data_type='VECTOR'); self._in(x.inputs['Factor'], fac); self._in(x.inputs[4], a); self._in(x.inputs[5], b); return x.outputs[1]
    def noise(self, vec, scale, detail=4, rough=.55):
        x = self.n('ShaderNodeTexNoise'); x.inputs['Scale'].default_value = scale; x.inputs['Detail'].default_value = detail; x.inputs['Roughness'].default_value = rough
        self.link(vec, x.inputs['Vector']); return x.outputs['Fac']
    def voro(self, vec, scale, feature='F1', metric='EUCLIDEAN', out='Distance'):
        x = self.n('ShaderNodeTexVoronoi', feature=feature, distance=metric); x.inputs['Scale'].default_value = scale; self.link(vec, x.inputs['Vector'])
        return x.outputs[out]
    def white(self, vec):
        x = self.n('ShaderNodeTexWhiteNoise', noise_dimensions='3D'); self.link(vec, x.inputs['Vector']); return x.outputs['Value']
    def sep(self, v):
        x = self.n('ShaderNodeSeparateXYZ'); self.link(v, x.inputs[0]); return x.outputs
    def comb(self, a, b, c):
        x = self.n('ShaderNodeCombineXYZ'); self._in(x.inputs[0], a); self._in(x.inputs[1], b); self._in(x.inputs[2], c); return x.outputs[0]
    def attr(self, name):
        x = self.n('ShaderNodeAttribute', attribute_name=name); return x


def plates(g, obj, scale, stretch):
    """big plates (Chebychev Voronoi): returns (edge distance f2-f1, cell random colour socket)"""
    v = g.vmath('MULTIPLY', obj, stretch)
    a = g.n('ShaderNodeTexVoronoi', feature='F1', distance='CHEBYCHEV'); a.inputs['Scale'].default_value = scale; g.link(v, a.inputs['Vector'])
    b = g.n('ShaderNodeTexVoronoi', feature='F2', distance='CHEBYCHEV'); b.inputs['Scale'].default_value = scale; g.link(v, b.inputs['Vector'])
    return g.math('SUBTRACT', b.outputs['Distance'], a.outputs['Distance']), a.outputs['Color']


def box_tex(g, img, vec, blend=.25):
    t = g.n('ShaderNodeTexImage', projection='BOX', interpolation='Linear', extension='REPEAT'); t.image = img; t.projection_blend = blend
    g.link(vec, t.inputs['Vector']); return t.outputs['Color']


def seams(g, obj, scale, stretch, metric, width):
    """panel seams: the gap between the nearest and second-nearest Voronoi cells (Chebychev gives rectangular plates). 1 on the plate, 0 in
    the seam."""
    v = g.vmath('MULTIPLY', obj, stretch)
    f1 = g.voro(v, scale, 'F1', metric); f2 = g.voro(v, scale, 'F2', metric)
    return g.smooth(g.math('SUBTRACT', f2, f1), 0.0, width)


LOOK = {  # how weathered each faction is (art direction: Hegemony parade finish, Voidsworn soot and worn black steel, Ithar clean pearl)
    'voidsworn': dict(rnoise=.06, grit=.10, wear_met=.30), 'hegemony': dict(rnoise=.025, grit=.05, wear_met=.12),
    'chorus': dict(rnoise=.05, grit=.08, wear_met=0), 'ithar': dict(rnoise=.02, grit=.03, wear_met=.10, ao_floor=.6), 'deathless': dict(rnoise=.05, grit=.08, wear_met=.25),
    'corsair': dict(rnoise=.08, grit=.13, wear_met=.35)}  # Ithar's sail is a thin double sheet: its baked AO came out dark everywhere, hence the floor


def build(o, fac, nmap, mmap, info):
    """o: the joined ship object (attributes hull, emit, rgh, met; colour attribute Col; UV maps atlas and UV0). nmap/mmap: hulls_hi
    image paths. info: dict(lo, hi (Blender-frame bounds), up (ring/up axis), needle (Ithar: radius of the needle hull around x), mirror)
    Returns (material, dict of output sockets: albedo, orm, emit, normal)."""
    F = FAC[fac]; m = bpy.data.materials.new('a2bake'); m.use_nodes = True; T = m.node_tree; T.nodes.clear(); g = G(T)
    out = g.n('ShaderNodeOutputMaterial'); em = g.n('ShaderNodeEmission'); g.link(em.outputs[0], out.inputs[0])
    tc = g.n('ShaderNodeTexCoord'); obj = tc.outputs['Object']; geo = g.n('ShaderNodeNewGeometry'); gn = geo.outputs['Normal']
    uva = g.n('ShaderNodeUVMap', uv_map='atlas')
    tn = g.n('ShaderNodeTexImage'); tn.image = bpy.data.images.load(nmap, check_existing=True); tn.image.colorspace_settings.name = 'Non-Color'; g.link(uva.outputs[0], tn.inputs[0])
    tm = g.n('ShaderNodeTexImage'); tm.image = bpy.data.images.load(mmap, check_existing=True); tm.image.colorspace_settings.name = 'Non-Color'; g.link(uva.outputs[0], tm.inputs[0])
    sm = g.n('ShaderNodeSeparateColor'); g.link(tm.outputs[0], sm.inputs[0])
    hull = g.attr('hull').outputs['Fac']; part = g.math('SUBTRACT', 1.0, hull)
    col = g.attr('Col').outputs['Color']; emit = g.attr('emit').outputs['Fac']; prg = g.attr('rgh').outputs['Fac']; pmt = g.attr('met').outputs['Fac']
    X, Y, Z = g.sep(obj); NX, NY, NZ = g.sep(gn)
    V2 = PAINT == 'v2' and fac in PLATE
    if V2:  # paint v2: the plate layout shared by the colour and the normal (so the painted lines sit in the seams)
        PL = PLATE[fac]; sc1 = {'hegemony': 24, 'voidsworn': 20, 'corsair': 17, 'deathless': 18}[fac]
        e1, c1 = plates(g, obj, sc1, (1.0, 2.2, 2.2) if fac != 'deathless' else (1.0, 1.0, 2.5)); e2, _ = plates(g, obj, 60, (1.0, 1.8, 1.8))
        R1 = g.sep(c1)  # per big plate, random 0..1: x accent, y vent, z hatch
        s1v = g.smooth(e1, 0.0, .025); s2v = g.smooth(e2, 0.0, .03)
        pk = g.add(hull, g.mul(part, .6))  # hand-built parts carry the plating a little softer (they read as plain blocks otherwise)
        if PL['acc']: col = g.mix(g.mul(g.math('LESS_THAN', R1[0], PL['acc_p']), hull), col, lin(PL['acc']))
        hatch = g.mul(g.mul(g.smooth(e1, .125, .135), g.math('SUBTRACT', 1.0, g.smooth(e1, .15, .16))), g.mul(g.math('LESS_THAN', R1[2], PL['hatch']), pk))
        slot = g.math('SUBTRACT', 1.0, g.smooth(g.math('ABSOLUTE', g.math('SUBTRACT', g.math('FRACT', g.mul(X, 170.0)), .5)), .18, .27))
        vent = g.mul(g.mul(slot, g.smooth(e1, .16, .18)), g.mul(g.math('LESS_THAN', R1[1], PL['vent']), pk))
        gimg, gmean = grain_image(PL['grain'], 'Color'); gv = g.vmath('MULTIPLY', obj, (info.get('L', 20.0) / PL['tile'],) * 3)
        grain = None
        if gimg is not None:
            bw = g.n('ShaderNodeRGBToBW'); g.link(box_tex(g, gimg, gv), bw.inputs[0])
            grain = g.add(1.0, g.mul(g.math('SUBTRACT', g.math('MINIMUM', g.math('MAXIMUM', g.math('DIVIDE', bw.outputs[0], gmean), .35), 1.9), 1.0), PL['grain_k']))
    # occlusion: hull = baked AO from the full-detail mesh; everything also gets Cycles AO (parts sitting on the hull, plates on plates)
    ao_node = g.n('ShaderNodeAmbientOcclusion'); ao_node.inputs['Distance'].default_value = .012; ao_node.samples = 16
    # Oct 31 (Ryan: 'a weird wavy effect'): where reshape.flat_bow moved the hull, the AI's baked AO, curvature and normal maps no longer
    # match the surface (ghost ripples painted onto a faired bow). 'fresh' fades those maps out there; the bow keeps the procedural seams
    fx0 = info.get('fresh_x0')
    fresh = g.mul(hull, g.smooth(X, fx0, fx0 + .05)) if fx0 is not None else 0.0
    keep = g.math('SUBTRACT', 1.0, fresh)
    ao_h = g.add(g.mul(hull, g.add(g.mul(g.rng(sm.outputs[0], 0, 1, LOOK[fac].get('ao_floor', 0.0), 1), keep), fresh)), part)  # 1 on parts
    ao = g.mul(ao_h, g.rng(ao_node.outputs['AO'], 0, 1, .35, 1.0))
    # curvature: hull from the map (G - .5); parts from the bevel normal (worn plate edges)
    bv = g.n('ShaderNodeBevel'); bv.inputs['Radius'].default_value = .0006; bv.samples = 8
    edge_p = g.rng(g.vmath('DOT_PRODUCT', bv.outputs[0], gn), .99, .80, 0, .2)
    curv = g.add(g.mul(g.mul(hull, keep), g.math('SUBTRACT', sm.outputs[1], .5)), g.mul(part, edge_p))
    if V2:  # the AI curvature map is blobby (wear came out as smears and scribbles): real geometry edges lead, the map helps at half weight
        curv = g.add(g.mul(g.mul(g.mul(hull, keep), g.math('SUBTRACT', sm.outputs[1], .5)), .5), edge_p)
    wear = g.mul(g.smooth(curv, .03, .18), g.rng(g.noise(obj, 60, 3), .35, .65, .2, 1.0))
    cavity = g.smooth(g.mul(curv, -1.0), .02, .15)
    # ---------------- albedo ----------------
    under = g.rng(NZ, -.9, .2, .86, 1.0)
    tone_scale = {'hegemony': 30, 'voidsworn': 26, 'deathless': 22, 'ithar': 18, 'chorus': 10, 'corsair': 17}[fac]
    cell = g.n('ShaderNodeTexVoronoi', feature='F1', distance='CHEBYCHEV'); cell.inputs['Scale'].default_value = tone_scale
    g.link(g.vmath('MULTIPLY', obj, (1.0, 1.6, 1.6)), cell.inputs['Vector'])
    ct = g.n('ShaderNodeSeparateColor'); g.link(cell.outputs['Color'], ct.inputs[0])
    tv = {'hegemony': (.93, 1.06), 'voidsworn': (.82, 1.14), 'deathless': (.84, 1.12), 'ithar': (.95, 1.04), 'chorus': (.80, 1.15), 'corsair': (.80, 1.18)}[fac]
    tone = g.add(g.mul(hull, g.rng(ct.outputs[0], 0, 1, *tv)), part)  # parts carry their own tone already
    big = g.rng(g.noise(obj, 5, 5, .6), .35, .65, .90, 1.06)
    if fac == 'corsair':  # the hull's own plate cells each take a salvage colour (stable: picked from the cell's random value)
        acc = CORSAIR_PATCH[0][1]; pc = col  # the first share keeps the hull's own rust
        for c_, w_ in CORSAIR_PATCH[1:]:
            sel = g.mul(hull, g.mul(g.math('GREATER_THAN', ct.outputs[1], acc), g.math('LESS_THAN', ct.outputs[1], acc + w_)))
            pc = g.mix(sel, pc, c_); acc += w_
        col = pc
    base = g.mix(1.0, col, g.comb(tone, tone, tone), 'MULTIPLY')
    base = g.mix(1.0, base, g.comb(big, big, big), 'MULTIPLY')
    base = g.mix(1.0, base, g.comb(under, under, under), 'MULTIPLY')
    dark = lin(F['dark']); trim = lin(F['trim']); hc = lin(F['hull'])
    if fac == 'chorus':
        mott = g.noise(obj, 14, 6, .62); vein = g.math('LESS_THAN', g.math('ABSOLUTE', g.math('SUBTRACT', g.noise(obj, 7, 3, .5), .5)), .018)
        base = g.mix(g.rng(mott, .3, .7, 0, .35), base, (min(1, hc[0] * 1.8), hc[1] * 1.3, min(1, hc[2] * 1.6)))  # paler, pinker flesh patches
        base = g.mix(g.mul(vein, .55), base, tuple(c * .35 for c in dark))                          # dark vein lines
        base = g.mix(g.mul(cavity, .8), base, (.035, .04, .012))                                    # dark olive-brown in the folds
        base = g.mix(g.mul(g.smooth(curv, .08, .25), .12), base, tuple(min(1, c * 1.2) for c in lin(F['trim'])))  # a little bile-yellow on the sharpest ridges
    else:
        worn = {'voidsworn': (.30, .31, .33), 'hegemony': (.80, .82, .84), 'deathless': (.26, .22, .32), 'ithar': (.95, .97, 1.0), 'corsair': (.20, .19, .18)}[fac]  # Crusade: bare iron, no rust
        wk = {'voidsworn': .8, 'hegemony': .25, 'deathless': .6, 'ithar': .2, 'corsair': .9}[fac]
        if V2 and fac == 'deathless': wk = .25; worn = (.12, .10, .16)  # the light-violet wear read as white scribbles in game (Nov 1)
        base = g.mix(g.mul(wear, wk), base, worn)                                                   # worn edges
        base = g.mix(g.mul(cavity, {'voidsworn': .7, 'hegemony': .4, 'deathless': .6, 'ithar': .3, 'corsair': .8}[fac]), base, tuple(c * .4 for c in dark))  # grime in the crevices
        st = g.vmath('MULTIPLY', obj, (40, 40, 3)); streak = g.rng(g.noise(st, 1, 5), .45, .75, 0, 1)
        if fac in ('voidsworn', 'deathless', 'corsair'): base = g.mix(g.mul(streak, .35), base, tuple(c * .5 for c in dark))  # soot run-off
        if fac == 'corsair':  # rust blooms over everything, parts included (nothing on a Corsair ship looks new)
            rb = g.smooth(g.noise(obj, 22, 6, .6), .58, .72); base = g.mix(g.mul(rb, .55), base, (.13, .045, .016))
    if V2:
        i1, i2 = PL['ink']
        base = g.mix(g.mul(g.math('SUBTRACT', 1.0, s1v), pk), base, (i1, i1, i1), 'MULTIPLY')                 # big panel lines
        base = g.mix(g.mul(g.math('SUBTRACT', 1.0, s2v), g.mul(pk, .8)), base, (i2, i2, i2), 'MULTIPLY')      # small panel lines
        band = g.mul(g.smooth(e1, .025, .06), g.math('SUBTRACT', 1.0, g.smooth(e1, .06, .12)))
        base = g.mix(g.mul(band, g.mul(pk, PL['hi'])), base, (1.8, 1.8, 1.8), 'MULTIPLY')                    # bevel catch inside each plate edge
        base = g.mix(g.mul(hatch, .8), base, (i1, i1, i1), 'MULTIPLY')                                       # inset hatches
        base = g.mix(g.mul(vent, .85), base, (.25, .25, .25), 'MULTIPLY')                                    # vent grilles
        if grain is not None: base = g.mix(1.0, base, g.comb(grain, grain, grain), 'MULTIPLY')             # photographed metal grain
        st2 = g.vmath('MULTIPLY', obj, (30, 55, 4)); smear = g.rng(g.noise(st2, 1.3, 5), .5, .78, 0, 1)      # grime run-off along the hull
        base = g.mix(g.mul(g.mul(smear, hull), {'hegemony': .14, 'voidsworn': .25, 'deathless': .2, 'corsair': .3}[fac]), base, tuple(c * .45 for c in dark))
    gm = g.rng(ao, .35, 1.0, .40 if V2 else .55, 1.0); base = g.mix(1.0, base, g.comb(gm, gm, gm), 'MULTIPLY')
    if fac == 'hegemony':  # faction markings: paired bow chevrons. Oct 27: the thin blue line along each flank is gone (with the row of lit
        # windows under it, it read as a ship's waterline stripe, a naval tell); the steel blue stays on the chevrons and the parts' trim
        zc = (info['lo'][2] + info['hi'][2]) / 2; h = info['hi'][2] - info['lo'][2]
        side = g.smooth(g.math('ABSOLUTE', NY), .55, .8)
        chev = g.math('LESS_THAN', g.math('ABSOLUTE', g.math('SUBTRACT', g.math('FRACT', g.mul(g.add(X, g.mul(g.math('ABSOLUTE', Z), .6)), 28)), .5)), .12)
        chev = g.mul(g.mul(chev, g.math('GREATER_THAN', X, info['hi'][0] - .16)), g.mul(side, g.math('LESS_THAN', g.math('ABSOLUTE', g.math('SUBTRACT', Z, zc - h * .02)), h * .05)))
        base = g.mix(g.mul(hull, chev), base, trim)
    if fac == 'ithar':  # gold filigree inlay painted into the pearl, and fine radial lines on the sail
        fil = g.math('LESS_THAN', g.math('ABSOLUTE', g.math('SUBTRACT', g.noise(g.vmath('MULTIPLY', obj, (1, 3, 3)), 9, 2, .4), .5)), .008)
        base = g.mix(g.mul(fil, g.mul(hull, .85)), base, trim)
        ang = g.math('ARCTAN2', Z, g.math('SUBTRACT', X, 0.0)); rad_l = g.math('LESS_THAN', g.math('ABSOLUTE', g.math('SUBTRACT', g.math('FRACT', g.mul(ang, 22)), .5)), .04)
        sail = g.smooth(g.math('SQRT', g.add(g.mul(Y, Y), g.mul(Z, Z))), info['needle'], info['needle'] * 1.6)
        base = g.mix(g.mul(g.mul(rad_l, sail), .5), base, (.86, .88, .92))
        base = g.mix(g.mul(sail, .45), base, (.62, .74, .90))  # Oct 31: the vane is ice-blue crystal (it read as white porcelain)
    if fac == 'voidsworn':  # frost-white markings (lore r8): paired bow chevrons and a frost dusting on worn upward edges
        side_v = g.smooth(g.math('ABSOLUTE', NY), .55, .8); zc_v = (info['lo'][2] + info['hi'][2]) / 2; h_v = info['hi'][2] - info['lo'][2]
        # Oct 31: bigger and bolder (at lineup distance the first pass did not show at all)
        chev_v = g.math('LESS_THAN', g.math('ABSOLUTE', g.math('SUBTRACT', g.math('FRACT', g.mul(g.add(X, g.mul(g.math('ABSOLUTE', Z), .6)), 14)), .5)), .15)
        chev_v = g.mul(g.mul(chev_v, g.math('GREATER_THAN', X, info['hi'][0] - .22)), g.mul(side_v, g.math('LESS_THAN', g.math('ABSOLUTE', g.math('SUBTRACT', Z, zc_v)), h_v * .15)))
        base = g.mix(g.mul(hull, chev_v), base, trim)
        base = g.mix(g.mul(g.mul(wear, g.smooth(NZ, .3, .9)), .30 if V2 else .70), base, (.80, .85, .90))  # v2: frost was blotchy white smears
    if fac == 'ithar':  # Glasswrights: faceted rainbow edges (hue running with position), the rest clear pale crystal
        ph = g.mul(g.add(g.add(X, g.mul(Y, 1.7)), g.mul(Z, 2.3)), 21.0)
        rb = g.comb(g.add(.5, g.mul(g.math('SINE', ph), .5)), g.add(.5, g.mul(g.math('SINE', g.add(ph, 2.09)), .5)), g.add(.5, g.mul(g.math('SINE', g.add(ph, 4.19)), .5)))
        edge_i = g.mul(hull, g.smooth(curv, .03, .16))
        # Oct 31: facets. Each Voronoi cell is one crystal face: its own brightness and a faint hue of its own, and a small height step
        # (used in the normal below) so the faces catch the light separately
        fc = g.sep(g.voro(g.vmath('MULTIPLY', obj, (1.0, 2.2, 2.2)), 26, out='Color'))[0]
        fv = g.rng(fc, 0, 1, .74, 1.20); base = g.mix(hull, base, g.comb(fv, fv, fv), 'MULTIPLY')
        phf = g.mul(fc, 19.0)
        rbf = g.comb(g.add(.5, g.mul(g.math('SINE', phf), .5)), g.add(.5, g.mul(g.math('SINE', g.add(phf, 2.09)), .5)), g.add(.5, g.mul(g.math('SINE', g.add(phf, 4.19)), .5)))
        base = g.mix(g.mul(hull, .16), base, rbf)
        base = g.mix(g.mul(edge_i, .65), base, rb)
    albedo = base
    # ---------------- roughness / metal / occlusion ----------------
    rg = g.add(g.mul(hull, F['rgh']), g.mul(part, prg))
    LK = LOOK[fac]; rg = g.add(rg, g.rng(g.noise(obj, 40, 4), 0, 1, -LK['rnoise'], LK['rnoise']))
    rg = g.add(rg, g.mul(cavity, .18)); rg = g.math('SUBTRACT', rg, g.mul(wear, .18 if fac != 'chorus' else 0))
    if V2:
        rimg, rmean = grain_image(PL['grain'], 'Roughness')
        if rimg is not None: rg = g.add(rg, g.mul(g.math('SUBTRACT', g.sep(box_tex(g, rimg, gv))[0], rmean), .45))
        rg = g.add(rg, g.mul(vent, .15))
    mt = g.add(g.mul(hull, F['met']), g.mul(part, pmt))
    mt = g.add(mt, g.mul(wear, LK['wear_met']))
    orm = g.comb(g.rng(ao, 0, 1, 0, 1), g.rng(rg, 0, 1, .06, 1), g.rng(mt, 0, 1, 0, 1))
    # ---------------- emissive ----------------
    up = info.get('up', (0, 0, 1)); upd = g.math('ABSOLUTE', g.vmath('DOT_PRODUCT', gn, up))
    open_ = g.mul(g.mul(hull, g.smooth(sm.outputs[0], .55, .7)), g.math('LESS_THAN', g.math('ABSOLUTE', g.math('SUBTRACT', sm.outputs[1], .5)), .05))
    if fac != 'chorus':
        if fac == 'deathless':  # around the ring: along = angle x radius
            u = g.mul(g.math('ARCTAN2', Y, X), .45); v = Z; ku, kv, wu, wv, runlen, thr, rows = 160, 70, (.42, .58), (.12, .88), 4, .45, .55
        elif fac == 'voidsworn': u, v = X, Z; ku, kv, wu, wv, runlen, thr, rows = 180, 95, (.08, .92), (.30, .70), 7, .25, .60  # long ember strips
        elif fac == 'corsair': u, v = X, Z; ku, kv, wu, wv, runlen, thr, rows = 150, 90, (.20, .80), (.30, .70), 3, .55, .74  # few, scattered, dirty
        elif fac == 'hegemony': u, v = X, Z; ku, kv, wu, wv, runlen, thr, rows = 210, 110, (.25, .75), (.30, .70), 6, .35, .62
        else: u, v = X, Z; ku, kv, wu, wv, runlen, thr, rows = 170, 120, (.30, .70), (.30, .70), 4, .55, .70
        U = g.mul(u, ku); Vv = g.mul(v, kv); cu = g.math('FLOOR', U); cv = g.math('FLOOR', Vv)
        fu = g.math('FRACT', U); fv = g.math('FRACT', Vv)
        rect = g.mul(g.mul(g.math('GREATER_THAN', fu, wu[0]), g.math('LESS_THAN', fu, wu[1])), g.mul(g.math('GREATER_THAN', fv, wv[0]), g.math('LESS_THAN', fv, wv[1])))
        deck = g.math('GREATER_THAN', g.white(g.comb(0.0, cv, 3.3)), rows)
        run = g.math('GREATER_THAN', g.white(g.comb(g.math('FLOOR', g.math('DIVIDE', cu, runlen)), cv, 7.1)), .55)
        lit = g.math('GREATER_THAN', g.white(g.comb(cu, cv, 1.7)), thr)
        side = g.math('LESS_THAN', upd, .35)
        win = g.mul(g.mul(g.mul(rect, deck), g.mul(run, lit)), g.mul(side, open_))
        if fac == 'ithar': win = g.mul(win, g.math('LESS_THAN', g.math('SQRT', g.add(g.mul(Y, Y), g.mul(Z, Z))), info['needle']))
        if fac in ('hegemony', 'voidsworn'):  # Oct 27: windows only in small clusters, never a long row along the flank (Hegemony: a waterline
            # read; Voidsworn, Muse audit: V1b's regular rows read as the banned porthole row at lineup distance)
            clus = g.math('LESS_THAN', g.voro(g.vmath('MULTIPLY', obj, (1.0, 1.0, 1.6)), 7.0), .16)
            win = g.mul(win, clus)
        e_col = g.mix(win, (0, 0, 0), F['win'])
    else:
        e_col = (0, 0, 0)
    if info.get('engine', True):
        aft = g.mul(g.smooth(g.mul(NX, -1.0), .5, .8), g.math('LESS_THAN', X, info['lo'][0] + .08 * (info['hi'][0] - info['lo'][0])))
        eng = g.mul(g.mul(aft, hull), g.rng(sm.outputs[0], .8, .45, 0, 1))
        e_col = g.mix(eng, e_col, F['eng'])
    if fac == 'ithar':  # stored light: the rainbow edges glow softly, the crystal body holds a faint pale light
        e_col = g.mix(g.mul(edge_i, .60), e_col, rb); e_col = g.mix(g.mul(hull, .16), e_col, (.80, .86, 1.0))
        e_col = g.mix(g.mul(g.mul(rad_l, sail), .55), e_col, (.75, .85, 1.0))  # Oct 31: light runs out along the vane ribs
    if fac == 'deathless':  # Oct 31: violet-white inner glow seeping from the seams between the shield plates
        if V2:  # v2: the glow runs in the big plate seams (clean lines), not in the AI's cavity map (it came out as scribbles)
            # Nov 1 seam-glow check (in game, paint v2): at .16 (times the game's emissive strength 4) every plate edge came out as a bright
            # violet-white line, the hull read as cracked crazy paving; .05 is a faint glow in the seams that blooms only up close
            e_col = g.mix(g.mul(g.mul(hull, g.math('SUBTRACT', 1.0, s1v)), .05), e_col, (.70, .55, 1.0))
        else:
            e_col = g.mix(g.mul(g.mul(hull, g.smooth(cavity, .70, .98)), .12), e_col, (.70, .55, 1.0))  # Nov 1: .40 streaked the whole hull; only the deepest seams now
    e_col = g.mix(emit, e_col, col)  # lenses, glowing sacs and veins carry their own colour
    # ---------------- normal ----------------
    nm = g.n('ShaderNodeNormalMap', uv_map='atlas'); g.link(tn.outputs[0], nm.inputs['Color'])
    # guard (Oct 26, H4's belly): where the hulls_hi normal map tips the surface past about 60 degrees (the AI bake of deep rib channels),
    # the baked hull shades black in patches; fade those texels back toward the true surface normal
    tame = g.smooth(g.vmath('DOT_PRODUCT', nm.outputs[0], gn), .30, .62)
    nmap_t = g.vmath('NORMALIZE', g.vmix(tame, gn, nm.outputs[0]))
    nbase = g.vmix(g.mul(hull, keep), gn, nmap_t)
    if V2:
        ht = g.add(g.mul(s1v, .7), g.mul(s2v, .3)) if fac != 'deathless' else s1v
    elif fac in ('voidsworn', 'hegemony', 'corsair'):
        s1 = seams(g, obj, {'hegemony': 24, 'voidsworn': 20, 'corsair': 17}[fac], (1.0, 2.2, 2.2), 'CHEBYCHEV', .025)
        s2 = seams(g, obj, 60, (1.0, 1.8, 1.8), 'CHEBYCHEV', .03)
        ht = g.add(g.mul(s1, .7), g.mul(s2, .3))
    elif fac == 'deathless':
        s1 = seams(g, obj, 18, (1.0, 1.0, 2.5), 'CHEBYCHEV', .03); ht = s1
    elif fac == 'ithar':
        ht = g.add(g.add(g.mul(seams(g, obj, 9, (1.0, 2.0, 2.0), 'EUCLIDEAN', .02), .45), g.mul(fc, .35)), .25)  # facet steps
    else:  # chorus: wrinkles and pores
        wr = g.noise(g.vmath('MULTIPLY', obj, (1, 1, 2.5)), 55, 6, .6); po = g.smooth(g.voro(obj, 140), 0.0, .25)
        ht = g.add(g.mul(wr, .7), g.mul(po, .3))
    if fac in ('voidsworn', 'hegemony', 'corsair', 'deathless'):  # Oct 26: hand-built parts take the panel seams too (they read as plain blocks
        ht = g.add(g.mul(ht, hull), g.mul(g.add(g.mul(ht, .6), .4), part))  # beside the AI hull otherwise), a little softer than the hull's
    else:
        ht = g.mul(ht, hull)
    ht = g.add(ht, g.mul(g.noise(obj, 600, 2), LK['grit']))  # fine grit everywhere
    if V2:
        ht = g.math('SUBTRACT', ht, g.add(g.mul(hatch, .5), g.mul(vent, .6)))  # hatches and grilles sit in
        dimg, dmean = grain_image(PL['grain'], 'Displacement')
        if dimg is not None: ht = g.add(ht, g.mul(g.math('SUBTRACT', g.sep(box_tex(g, dimg, gv))[0], dmean), .25))
    bmp = g.n('ShaderNodeBump'); bmp.inputs['Strength'].default_value = .8 if fac != 'ithar' else .4; bmp.inputs['Distance'].default_value = .0012
    g.link(ht, bmp.inputs['Height']); g.link(nbase, bmp.inputs['Normal'])
    pb = g.n('ShaderNodeBsdfPrincipled'); g.link(bmp.outputs['Normal'], pb.inputs['Normal'])
    return m, dict(albedo=albedo, orm=orm, emit=e_col, normal=pb.outputs[0], em=em, out=out, g=g)
