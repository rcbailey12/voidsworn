# Shared interior trim maps (issue 1743, R416 Layer 3; RULEBOOK 5.4). Shared plumbing only, no look of its own: every colour,
# panel size, strip, vein and facet setting comes from the faction's stack (INSIDE_TRIM in tools/blender/kits/<faction>/stack.py,
# RULEBOOK 4.5). Paint (stage 5) calls trim_material() from each faction's inside_material() when the ship's insides carry the
# Interior Kit V2 UVs (tools/blender/build_sheets/interior_kit.py).
#
# One tiling set per faction, made here from numbers (nothing painted by hand, nothing projected, seeded so every bake makes the
# same pixels): albedo (sRGB), ORM (occlusion, roughness, metal; linear) and a detail normal (OpenGL, linear), plus an emission
# map where the faction lights its insides (corridor strips, ember conduits, blue emergency lines, violet-white bus rails, bile in
# the veins). The albedo is a DETAIL map whose every channel averages 0.5; each room's material scales it by the room's own
# colour (baseColorFactor = 2 x the room's albedo), so one set of maps serves every room of the ship and a broken ship's spaces
# are still not all one colour. The images are packed into the blend, so stage 7 finds them; export7 writes them once per ship
# (shared by every interior material, tools/recipe/export7.py "authored trim maps may be shared").
# Styles: 'panels' (metal factions: a panel grid with seams, bolts, grilles, conduits and light strips; rust only where the stack
# asks, so soot and rust stay on the Hullbreakers), 'flesh' (the Chorus: cells, raised veins, pores; wet, no metal), 'glass'
# (the Glasswrights: annealed facets and fine lines; no metal, no soot).
import hashlib, json, math
import numpy as np

SIZE = 1024


def _noise(n, sigma, rng):
    """tileable smooth noise in 0..1 (white noise low-passed in the frequency domain)"""
    f = np.fft.fft2(rng.standard_normal((n, n)))
    k = np.fft.fftfreq(n)[:, None] ** 2 + np.fft.fftfreq(n)[None, :] ** 2
    a = np.real(np.fft.ifft2(f * np.exp(-k * (2 * math.pi * sigma) ** 2 / 2)))
    return (a - a.min()) / (a.max() - a.min() + 1e-9)


def _blur(a, sigma):
    k = np.fft.fftfreq(a.shape[0])[:, None] ** 2 + np.fft.fftfreq(a.shape[1])[None, :] ** 2
    return np.real(np.fft.ifft2(np.fft.fft2(a) * np.exp(-k * (2 * math.pi * sigma) ** 2 / 2)))


def _normal(h, strength):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * strength
    n = np.stack([-dx, -dy, np.ones_like(h)], -1)
    return n / np.linalg.norm(n, axis=-1, keepdims=True)


def _panels(n, spec, rng):
    """the metal styles: height, a per-pixel panel value (0..1), a light-strip mask and a rust mask"""
    G = int(spec.get('panel', 8)); cs = n / G
    Y, X = np.mgrid[0:n, 0:n].astype(float)
    ci, cj = np.minimum((X // cs).astype(int), G - 1), np.minimum((Y // cs).astype(int), G - 1); fx, fy = X - ci * cs, Y - cj * cs
    split = rng.integers(0, 3, (G, G)) if spec.get('split', 0.5) > 0 else np.zeros((G, G), int)
    split = np.where(rng.random((G, G)) < spec.get('split', 0.5), split, 0)
    sp = split[cj, ci]
    w = np.where(sp == 1, cs / 2, cs).astype(float); hgt = np.where(sp == 2, cs / 2, cs).astype(float)
    lx = np.where(sp == 1, fx % (cs / 2), fx); ly = np.where(sp == 2, fy % (cs / 2), fy)
    sub = np.where(sp == 1, fx // (cs / 2), np.where(sp == 2, fy // (cs / 2), 0)).astype(int).clip(0, 1)
    pid = (cj * G + ci) * 2 + sub
    pr = rng.random(G * G * 2)[pid]                                         # one value per panel
    edge = np.minimum(np.minimum(lx, w - 1 - lx), np.minimum(ly, hgt - 1 - ly))
    sw = max(2.0, cs * 0.025)
    h = np.clip(edge / sw, 0, 1) ** 0.7 * (0.75 + 0.25 * pr)               # seams: grooves at every panel edge
    # bolts in the panel corners
    b = cs * 0.07; br = max(1.6, cs * 0.018)
    for cx in (b, None):
        for cy in (b, None):
            px = lx - (b if cx else w - 1 - b); py = ly - (b if cy else hgt - 1 - b)
            d = np.sqrt(px ** 2 + py ** 2)
            h = h + np.clip(1 - d / br, 0, 1) ** 0.5 * 0.35 * (edge > sw)
    # grilles: some panels carry slats
    g = (rng.random(G * G * 2)[pid] < spec.get('grille', 0.2)) & (edge > cs * 0.12)
    period = max(4.0, cs * 0.06)
    h = h - g * 0.35 * (np.sin(2 * math.pi * ly / period) > 0.2)
    # conduits: a few full-width pipes along panel rows
    strip = np.zeros((n, n))
    rows = spec.get('conduit_rows', 2)
    for k in range(rows):
        yc = (k + 0.5) * n / rows + cs * 0.5; r = cs * 0.09
        d = np.abs(((Y - yc + n / 2) % n) - n / 2)
        h = np.where(d < r, np.maximum(h, 0.6 + 0.6 * np.sqrt(np.clip(1 - (d / r) ** 2, 0, 1))), h)
    # light strips: thin recessed lines along every few panel rows
    st = spec.get('strip')
    if st:
        every = int(st.get('every', 4)); thick = max(2.0, cs * 0.03)
        for k in range(0, G, every):
            yc = k * cs + cs * 0.5
            d = np.abs(((Y - yc + n / 2) % n) - n / 2)
            on = d < thick
            h = np.where(on, 0.55, h); strip = np.maximum(strip, on * np.clip(1 - d / thick, 0, 1) ** 0.5)
    rust = np.zeros((n, n))
    if spec.get('rust', 0) > 0:
        rn = _noise(n, n * 0.05, rng) * 0.7 + _noise(n, n * 0.012, rng) * 0.3
        rust = np.clip((rn - (1 - spec['rust'])) / 0.12, 0, 1)
    return h, pr, strip, rust


def _cells(n, count, rng, warp=None):
    """tileable Worley distances (F1, F2) and the nearest cell's id; warp: (dx, dy) pixel offsets bending the cells (flesh)"""
    pts = rng.random((count, 2)) * n
    Y, X = np.mgrid[0:n, 0:n].astype(np.float32)
    if warp is not None:
        X = (X + warp[0]) % n; Y = (Y + warp[1]) % n
    F1 = np.full((n, n), 1e9, np.float32); F2 = np.full((n, n), 1e9, np.float32); idn = np.zeros((n, n), np.int32)
    for i, (px, py) in enumerate(pts):
        dx = np.abs(X - px); dx = np.minimum(dx, n - dx); dy = np.abs(Y - py); dy = np.minimum(dy, n - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < F1
        F2 = np.where(closer, F1, np.minimum(F2, d)); idn = np.where(closer, i, idn); F1 = np.where(closer, d, F1)
    return F1, F2, idn


def maps(spec, n=SIZE):
    """the faction's set: dict(base (n, n, 3) sRGB 0..1, orm (n, n, 3) linear, normal (n, n, 3) encoded, emission (n, n, 3) sRGB
    or None). Row 0 is the bottom of the image (Blender's pixel order)."""
    rng = np.random.default_rng(int(spec.get('seed', 1743)))
    style = spec.get('style', 'panels')
    tint = np.array(spec.get('tones', ((1.0, 1.0, 1.0),)), float)          # detail tones (relative), averaged to 0.5 below
    em = None
    if style == 'panels':
        h, pr, strip, rust = _panels(n, spec, rng)
        grime = _noise(n, n * 0.02, rng)
        cav = np.clip(_blur(h, 3.0) - h, 0, None) + np.clip(_blur(h, 10.0) - h, 0, None) * 0.5
        ao = np.clip(1 - 3.0 * cav, 0.25, 1)
        tone = tint[np.minimum((pr * len(tint)).astype(int), len(tint) - 1)]
        var = spec.get('var', 0.12)
        alb = tone * (1 + var * (pr[..., None] - 0.5) * 2) * (0.75 + 0.25 * ao[..., None]) * (1 - spec.get('grime', 0.2) * grime[..., None])
        if spec.get('rust', 0) > 0:
            alb = alb * (1 - rust[..., None]) + np.array(spec.get('rust_tone', (1.6, 0.75, 0.45)))[None, None] * rust[..., None] * 0.6
        rlo, rhi = spec.get('rough', (0.45, 0.8))
        rough = rlo + (rhi - rlo) * (0.6 * pr + 0.4 * grime) + 0.15 * rust
        metal = np.full((n, n), spec.get('metal', 0.6)) * (1 - 0.8 * rust)
        if spec.get('strip'):
            s = spec['strip']; em = np.array(s['rgb'], float)[None, None] * strip[..., None]
            alb = alb * (1 - strip[..., None]) + strip[..., None] * 0.9
        nrm = _normal(h, spec.get('relief', 6.0))
    elif style == 'flesh':
        wa = spec.get('warp', 0.04) * n
        warp = ((_noise(n, n * 0.03, rng) - 0.5) * 2 * wa, (_noise(n, n * 0.03, rng) - 0.5) * 2 * wa)
        F1, F2, idn = _cells(n, int(spec.get('cells', 90)), rng, warp)         # bent cells: tissue, never tiles
        border = np.clip(1 - (F2 - F1) / spec.get('vein_w', 6.0), 0, 1)            # veins on the cell borders
        dome = np.clip(1 - F1 / (F1.max() * 0.8), 0, 1) ** 0.6 * 0.6 + 0.4 * _noise(n, n * 0.008, rng)
        pr = rng.random(int(spec.get('cells', 90)))[idn]
        fine = _noise(n, 3.0, rng)
        h = 0.55 * dome + 0.5 * border ** 1.5 + 0.08 * fine
        pores = (fine > 0.82) & (border < 0.2)
        h = np.where(pores, h - 0.25, h)
        cav = np.clip(_blur(h, 4.0) - h, 0, None)
        ao = np.clip(1 - 3.0 * cav, 0.3, 1)
        flesh = np.array(spec.get('flesh_tone', (1.0, 0.95, 0.7)), float); vein = np.array(spec.get('vein_tone', (0.7, 0.18, 0.12)), float)
        alb = flesh[None, None] * (0.8 + 0.4 * pr[..., None]) * (1 - border[..., None] ** 2) + vein[None, None] * border[..., None] ** 2
        alb = alb * (0.7 + 0.3 * ao[..., None]) * np.where(pores, 0.35, 1.0)[..., None]
        rlo, rhi = spec.get('rough', (0.28, 0.5))
        rough = rlo + (rhi - rlo) * (1 - dome) + 0.1 * pores
        metal = np.zeros((n, n))
        if spec.get('glow'):
            g = spec['glow']; mask = (border > 0.85) & (_noise(n, n * 0.04, rng) > 1 - g.get('share', 0.25))
            em = np.array(g['rgb'], float)[None, None] * mask[..., None] * border[..., None]
        nrm = _normal(h, spec.get('relief', 5.0))
    else:                                                                     # glass
        F1, F2, idn = _cells(n, int(spec.get('cells', 60)), rng)
        k = int(spec.get('cells', 60))
        tilt = rng.normal(0, spec.get('facet', 0.18), (k, 2))[idn]
        line = np.clip(1 - (F2 - F1) / spec.get('line_w', 2.5), 0, 1)
        nrm = np.stack([tilt[..., 0], tilt[..., 1], np.ones((n, n))], -1)
        nrm = nrm / np.linalg.norm(nrm, axis=-1, keepdims=True)
        pr = rng.random(k)[idn]
        alb = np.ones((n, n, 3)) * (0.85 + 0.3 * pr[..., None]) * (1 - 0.35 * line[..., None])
        ao = np.clip(1 - 0.25 * line, 0, 1)
        rlo, rhi = spec.get('rough', (0.08, 0.3))
        rough = rlo + (rhi - rlo) * (0.5 * pr + 0.5 * line)
        metal = np.zeros((n, n))
        if spec.get('glow'):
            g = spec['glow']; em = np.array(g['rgb'], float)[None, None] * (line[..., None] ** 2) * g.get('share', 0.4)
    alb = np.clip(alb, 0, None); alb = alb / (alb.reshape(-1, 3).mean(0) + 1e-6) * 0.5     # the detail averages 0.5 per channel
    alb = np.clip(alb, 0, 1)
    srgb = lambda c: np.where(c <= 0.0031308, 12.92 * c, 1.055 * np.clip(c, 0, None) ** (1 / 2.4) - 0.055)
    out = dict(base=srgb(alb), orm=np.stack([ao, np.clip(rough, 0.04, 1), np.clip(metal, 0, 1)], -1),
               normal=nrm * 0.5 + 0.5, emission=None if em is None else srgb(np.clip(em, 0, 1)))
    return out


def _key(fac, spec):
    return hashlib.sha1(json.dumps([fac, spec], sort_keys=True, default=str).encode()).hexdigest()[:8]


_CACHE = {}


def images(fac, spec, n=SIZE):
    """the faction's packed Blender images (made once per blend: a second call returns the same images)"""
    import bpy
    key = _key(fac, spec)
    pre = 'trim_%s_%s' % (fac, key)
    if bpy.data.images.get(pre + '_base') is not None:
        return {k: bpy.data.images.get('%s_%s' % (pre, k)) for k in ('base', 'orm', 'normal', 'emission')}
    m = maps(spec, n); out = {}
    for k, a in m.items():
        if a is None:
            out[k] = None; continue
        im = bpy.data.images.new('%s_%s' % (pre, k), n, n, alpha=False)
        im.colorspace_settings.name = 'sRGB' if k in ('base', 'emission') else 'Non-Color'
        px = np.concatenate([a.astype(np.float32), np.ones((n, n, 1), np.float32)], -1)
        im.pixels.foreach_set(px.ravel()); im.update()
        im.file_format = 'PNG'; im.pack()
        im['interior_trim'] = fac
        out[k] = im
    return out


def trim_material(name, fac, spec, albedo, emission=None, strip_strength=None):
    """one interior material: the faction's trim maps, scaled by the room's albedo (linear rgb, each at most 0.5), with its own
    constant emission (the core: rgb, strength) or else the faction's strip emission map"""
    import bpy
    ims = images(fac, spec)
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; N = nt.nodes; Lk = nt.links
    b = N['Principled BSDF']
    tb = N.new('ShaderNodeTexImage'); tb.image = ims['base']
    mix = N.new('ShaderNodeMix'); mix.data_type = 'RGBA'; mix.blend_type = 'MULTIPLY'; mix.inputs['Factor'].default_value = 1.0
    mix.inputs['B'].default_value = (*[min(1.0, 2.0 * c) for c in albedo], 1)
    Lk.new(tb.outputs['Color'], mix.inputs['A']); Lk.new(mix.outputs['Result'], b.inputs['Base Color'])
    to = N.new('ShaderNodeTexImage'); to.image = ims['orm']
    sep = N.new('ShaderNodeSeparateColor')
    Lk.new(to.outputs['Color'], sep.inputs['Color']); Lk.new(sep.outputs['Green'], b.inputs['Roughness']); Lk.new(sep.outputs['Blue'], b.inputs['Metallic'])
    # occlusion: the glTF exporter reads the red channel from its own output group
    grp = bpy.data.node_groups.get('glTF Material Output') or bpy.data.node_groups.new('glTF Material Output', 'ShaderNodeTree')
    if not grp.interface.items_tree:
        grp.interface.new_socket('Occlusion', in_out='INPUT', socket_type='NodeSocketFloat')
    g = N.new('ShaderNodeGroup'); g.node_tree = grp
    Lk.new(sep.outputs['Red'], g.inputs['Occlusion'])
    tn = N.new('ShaderNodeTexImage'); tn.image = ims['normal']
    nm = N.new('ShaderNodeNormalMap')
    Lk.new(tn.outputs['Color'], nm.inputs['Color']); Lk.new(nm.outputs['Normal'], b.inputs['Normal'])
    if emission is not None:
        b.inputs['Emission Color'].default_value = (*emission[0], 1); b.inputs['Emission Strength'].default_value = emission[1]
    elif ims['emission'] is not None:
        te = N.new('ShaderNodeTexImage'); te.image = ims['emission']
        Lk.new(te.outputs['Color'], b.inputs['Emission Color']); b.inputs['Emission Strength'].default_value = strip_strength or spec.get('strip', spec.get('glow', {})).get('strength', 1.0)
    m['ps_inside'] = 1; m['interior_trim'] = fac
    return m


def upgrade(flat, fac, spec, lift, base=None, flat_base=None):
    """the V2 material for a faction's flat inside material (the legacy one its inside_material() just made): the same room
    colour, lifted by the stack's INSIDE_LIFT (each channel at most 0.5), and its own light (the core) kept; the flat one is removed.
    base: the stack's own interior colour for the trim (the Directorate's white corridors), carrying the room's tint over
    flat_base (the liner colour the flat one was made from) instead of the lift"""
    import bpy
    b = flat.node_tree.nodes['Principled BSDF']
    col = tuple(b.inputs['Base Color'].default_value)[:3]
    if base is not None:
        col = tuple(base[i] * col[i] / max(flat_base[i], 1e-6) for i in range(3)); lift = 1.0
    em = b.inputs['Emission Strength'].default_value
    emission = (tuple(b.inputs['Emission Color'].default_value)[:3], em) if em > 0 else None
    name = flat.name; bpy.data.materials.remove(flat)
    return trim_material(name, fac, spec, tuple(min(0.5, c * lift) for c in col), emission=emission)
