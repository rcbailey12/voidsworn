"""Issue 1360 (Ryan's pick B, Nov 20 2026): animated storm lightning bolts baked in Blender into flipbooks.

blender -b -t 8 -P bake_storm_bolts.py -- OUT [--tile 512] [--samples 32] [--variants a,b,c] [--pack GODOT_DIR] [--pack-only] [--cpu]

Three bolt variants, each a 16-frame strike over BOLT_LIFE seconds (world_living.gd), rendered with Cycles on the GPU
the same way the explosion flipbooks were (issues 353, 365, 426): one fixed orthographic camera, one tile per frame, then
packed into a 4x4 atlas per variant. The bolt is drawn as emissive ribbons (a soft hot channel) with an additive
transparent shader, so forks and the main channel sum where they cross instead of hiding each other.

  a  STB-A "Forked": a bright main channel with three or four wide forks; leader, return stroke, one re-strike.
  b  STB-B "Branched": a slower leader that lights a tree of fine branches, one long stroke and a slow cool-down.
  c  STB-C "Twin strike": a fast, sparse channel that strikes three times, shifting a little between strikes.

Render channels (linear EXR, black background): red is the main channel, green the forks. The bake carries only shape
and brightness; the game colours it with the one line style's storm roles (render/line_style.gd bolt_core,
bolt_skirt, bolt_corona), so PR 1299's cyan-white colour stays in one place.

Pack (numpy, CPU only; runs in the same Blender): each atlas cell is 256 px, RGBA8, no colour space:
  R main channel core, G fork core, B near glow (Gaussian, sigma 7 px), A far glow (sigma 16 px). Glows are normalised so
  a full-brightness main channel reads 1.0 at its centre. Lossless import, mipmaps on, no alpha repair (alpha is data).
The main channel runs from tile row 0.10 to row 0.90 down the centre column (BOLT_TOP, BOLT_BOTTOM below), which the game
maps onto the bolt's start and end points. Nothing is deleted; frames and bake.json stay in OUT.
"""
import argparse, json, math, pathlib, random, struct, sys, time, zlib
import numpy as np

FRAMES = 16
GRID = 4
CELL = 256
BOLT_TOP = 0.40      # tile units, y up, tile spans -0.5..0.5; the game's BOLT_FILL is BOLT_TOP * 2 = 0.80
BOLT_BOTTOM = -0.40
SIGMA_NEAR = 7.0
SIGMA_FAR = 16.0
MAIN_HALF_W = 0.010
FORK_HALF_W = (0.0062, 0.0040)

# Per frame: (main brightness, fork brightness, leader reveal 0..1, shifted channel). Reveal 1 means the whole path.
VARIANTS = {
    'a': dict(code='STB-A', name='Forked', seed=1360, forks=4, fork_len=(0.20, 0.34), fork_angle=(0.55, 0.95),
              subforks=0.35, rough=0.22, schedule=[
                  (0.22, 0.18, 0.45, 0), (0.28, 0.22, 0.85, 0), (1.00, 0.85, 1, 0), (0.80, 0.55, 1, 0),
                  (0.60, 0.30, 1, 0), (0.42, 0.12, 1, 0), (0.30, 0.00, 1, 0), (0.95, 0.20, 1, 0),
                  (0.65, 0.05, 1, 0), (0.45, 0.00, 1, 0), (0.32, 0.00, 1, 0), (0.22, 0.00, 1, 0),
                  (0.15, 0.00, 1, 0), (0.09, 0.00, 1, 0), (0.05, 0.00, 1, 0), (0.00, 0.00, 1, 0)]),
    'b': dict(code='STB-B', name='Branched', seed=4410, forks=7, fork_len=(0.14, 0.30), fork_angle=(0.45, 1.05),
              subforks=0.75, rough=0.25, schedule=[
                  (0.18, 0.20, 0.30, 0), (0.22, 0.24, 0.60, 0), (0.28, 0.30, 0.92, 0), (1.00, 1.00, 1, 0),
                  (0.75, 0.68, 1, 0), (0.55, 0.42, 1, 0), (0.40, 0.24, 1, 0), (0.30, 0.13, 1, 0),
                  (0.22, 0.07, 1, 0), (0.16, 0.03, 1, 0), (0.11, 0.00, 1, 0), (0.08, 0.00, 1, 0),
                  (0.05, 0.00, 1, 0), (0.03, 0.00, 1, 0), (0.015, 0.00, 1, 0), (0.00, 0.00, 1, 0)]),
    'c': dict(code='STB-C', name='Twin strike', seed=7731, forks=2, fork_len=(0.16, 0.26), fork_angle=(0.50, 0.85),
              subforks=0.0, rough=0.20, schedule=[
                  (0.30, 0.20, 1, 0), (1.00, 0.70, 1, 0), (0.55, 0.30, 1, 0), (0.28, 0.08, 1, 0),
                  (0.12, 0.00, 1, 0), (1.00, 0.40, 1, 1), (0.60, 0.15, 1, 1), (0.34, 0.00, 1, 1),
                  (0.18, 0.00, 1, 1), (0.85, 0.00, 1, 0), (0.52, 0.00, 1, 0), (0.30, 0.00, 1, 0),
                  (0.17, 0.00, 1, 0), (0.09, 0.00, 1, 0), (0.04, 0.00, 1, 0), (0.00, 0.00, 1, 0)]),
}


def jag(p0, p1, depth, rough, rng):
    """Midpoint displacement: each split moves the midpoint sideways by a Gaussian share of its segment length."""
    pts = [p0, p1]
    for _ in range(depth):
        out = [pts[0]]
        for a, b in zip(pts, pts[1:]):
            dx, dy = b[0] - a[0], b[1] - a[1]
            ln = math.hypot(dx, dy)
            k = rng.gauss(0.0, rough) * ln
            out.append(((a[0] + b[0]) * 0.5 - dy / max(ln, 1e-9) * k, (a[1] + b[1]) * 0.5 + dx / max(ln, 1e-9) * k))
            out.append(b)
        pts = out
    return pts


def arc(pts):
    s = [0.0]
    for a, b in zip(pts, pts[1:]):
        s.append(s[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
    return s


def clip_inside(pts, lim=0.47):
    for i, p in enumerate(pts):
        if abs(p[0]) > lim or abs(p[1]) > lim:
            return pts[:max(i, 2)]
    return pts


def build_bolt(cfg):
    rng = random.Random(cfg['seed'])
    main = jag((0.0, BOLT_TOP), (0.0, BOLT_BOTTOM), 6, cfg['rough'], rng)
    main = [(max(-0.30, min(0.30, x)), y) for x, y in main]
    main_s = arc(main)
    total = main_s[-1]
    # the channel the second strike of STB-C follows: the same path, shifted a little
    shift = [(x + rng.gauss(0.0, 0.006) + 0.012 * math.sin(i * 0.37), y) for i, (x, y) in enumerate(main)]
    paths = [dict(pts=main, t=[s / total for s in main_s], level=0, alt=shift)]
    sides = [1 if k % 2 == 0 else -1 for k in range(cfg['forks'])]
    rng.shuffle(sides)
    for k in range(cfg['forks']):
        frac = 0.12 + 0.63 * (k + rng.random() * 0.8) / cfg['forks']
        i = min(len(main) - 2, int(frac * (len(main) - 1)))
        tx, ty = main[i + 1][0] - main[i - 1][0], main[i + 1][1] - main[i - 1][1]
        ang = math.atan2(ty, tx) + sides[k] * rng.uniform(*cfg['fork_angle'])
        ln = rng.uniform(*cfg['fork_len']) * (1.0 - 0.45 * frac)
        end = (main[i][0] + math.cos(ang) * ln, main[i][1] + math.sin(ang) * ln)
        fork = clip_inside(jag(main[i], end, 5, cfg['rough'] * 1.1, rng))
        fs = arc(fork)
        t0 = paths[0]['t'][i]
        paths.append(dict(pts=fork, t=[t0 + s / total for s in fs], level=1))
        if rng.random() < cfg['subforks'] and len(fork) > 8:
            j = rng.randint(len(fork) // 4, len(fork) // 2)
            a2 = ang + rng.choice([-1, 1]) * rng.uniform(0.4, 0.8)
            l2 = ln * rng.uniform(0.35, 0.55)
            sub = clip_inside(jag(fork[j], (fork[j][0] + math.cos(a2) * l2, fork[j][1] + math.sin(a2) * l2), 4, cfg['rough'] * 1.2, rng))
            ss = arc(sub)
            paths.append(dict(pts=sub, t=[paths[-1]['t'][j] + s / total for s in ss], level=2))
    # bead noise along each path: the channel breaks up unevenly as it cools
    for p in paths:
        phase = rng.random() * 10.0
        p['bead'] = [0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase + i * 0.55) * math.sin(phase * 1.7 + i * 0.23)) for i in range(len(p['pts']))]
    return paths


def frame_strokes(paths, row, peak_main):
    """Ribbon specs for one frame: list of (points, half widths, colours, depth)."""
    bm, bf, reveal, shifted = row
    leader = reveal < 1.0 or (bm < 0.35 and peak_main == 0)
    out = []
    for p in paths:
        b = bm if p['level'] == 0 else bf
        if b <= 0.0:
            continue
        pts = p['alt'] if shifted and p['level'] == 0 else p['pts']
        keep = [i for i, t in enumerate(p['t']) if t <= reveal + 1e-6]
        if len(keep) < 2:
            continue
        n = len(pts)
        cool = 1.0 - b   # how far through its cooling the channel is
        widths, cols = [], []
        for i in keep:
            u = i / (n - 1)
            if p['level'] == 0:
                end = min(i, n - 1 - i)
                w = MAIN_HALF_W * (0.12 if end == 0 else (0.55 if end == 1 else 1.0))
            else:
                w = FORK_HALF_W[p['level'] - 1] * (1.0 - 0.7 * u)
            v = b * (1.0 - cool * (1.0 - p['bead'][i]))
            if p['level'] > 0:
                v *= 1.0 - u * cool * 0.8   # fork tips go out first
            if leader:
                v *= 0.55 + 0.45 * max(0.0, 1.0 - (reveal - p['t'][i]) / 0.15)   # the leader's head is its brightest part
            widths.append(w)
            cols.append((v, 0.0) if p['level'] == 0 else (0.0, v))
        out.append(([pts[i] for i in keep], widths, cols, 0.02 - 0.01 * p['level']))
    return out


# ---------------------------------------------------------------- Blender side

def render(out, variants, tile, samples, cpu=False):
    import bpy
    records = []
    for key in variants:
        cfg = VARIANTS[key]
        paths = build_bolt(cfg)
        bpy.ops.wm.read_factory_settings(use_empty=True)
        sc = bpy.context.scene
        sc.render.engine = 'CYCLES'; sc.cycles.samples = samples; sc.cycles.use_denoising = False
        sc.cycles.transparent_max_bounces = 64; sc.cycles.max_bounces = 0
        devices = []
        if cpu:
            sc.cycles.device = 'CPU'   # drafts only (cloud Blender, or a quick look); production bakes use the GPU
        else:
            prefs = bpy.context.preferences.addons['cycles'].preferences; prefs.compute_device_type = 'OPTIX'; prefs.get_devices()
            devices = [d for d in prefs.devices if d.type == 'OPTIX']
            if not devices:
                raise RuntimeError('GPU required for the bolt renders (OPTIX); --cpu makes a draft')
            for dev in prefs.devices:
                dev.use = dev.type == 'OPTIX'
            sc.cycles.device = 'GPU'
            print('CYCLES_GPU', [(d.name, d.type) for d in devices], flush=True)
        sc.render.resolution_x = tile; sc.render.resolution_y = tile; sc.render.resolution_percentage = 100
        sc.render.film_transparent = False
        sc.render.image_settings.file_format = 'OPEN_EXR'; sc.render.image_settings.color_mode = 'RGBA'
        sc.render.image_settings.color_depth = '32'
        sc.world = bpy.data.worlds.new('black'); sc.world.use_nodes = True
        sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.0
        camd = bpy.data.cameras.new('ortho'); camd.type = 'ORTHO'; camd.ortho_scale = 1.0
        cam = bpy.data.objects.new('camera', camd); sc.collection.objects.link(cam); cam.location = (0, 0, 5); sc.camera = cam
        mat = bpy.data.materials.new('hot channel'); mat.use_nodes = True; nt = mat.node_tree; nt.nodes.clear()
        # The heat rides in a UV map (u main, v fork) into two emission strengths: a colour attribute read through the
        # Attribute or Color Attribute node rendered black in this Blender (4.5.14, Cycles CPU and GPU).
        o = nt.nodes.new('ShaderNodeOutputMaterial'); add = nt.nodes.new('ShaderNodeAddShader')
        add2 = nt.nodes.new('ShaderNodeAddShader'); tr = nt.nodes.new('ShaderNodeBsdfTransparent')
        uvn = nt.nodes.new('ShaderNodeUVMap'); uvn.uv_map = 'heat'; sep = nt.nodes.new('ShaderNodeSeparateXYZ')
        nt.links.new(uvn.outputs[0], sep.inputs[0])
        e_main = nt.nodes.new('ShaderNodeEmission'); e_main.inputs['Color'].default_value = (1.0, 0.0, 0.0, 1.0)
        e_fork = nt.nodes.new('ShaderNodeEmission'); e_fork.inputs['Color'].default_value = (0.0, 1.0, 0.0, 1.0)
        nt.links.new(sep.outputs[0], e_main.inputs['Strength']); nt.links.new(sep.outputs[1], e_fork.inputs['Strength'])
        nt.links.new(e_main.outputs[0], add2.inputs[0]); nt.links.new(e_fork.outputs[0], add2.inputs[1])
        nt.links.new(tr.outputs[0], add.inputs[0]); nt.links.new(add2.outputs[0], add.inputs[1])
        nt.links.new(add.outputs[0], o.inputs['Surface'])
        folder = out / key; folder.mkdir(parents=True, exist_ok=True)
        peak = 0
        for f, row in enumerate(cfg['schedule']):
            for ob in [ob for ob in sc.objects if ob.type == 'MESH']:
                bpy.data.objects.remove(ob, do_unlink=True)
            verts, faces, cols = [], [], []
            for pts, widths, colours, z in frame_strokes(paths, row, peak):
                base = len(verts)
                for i, p in enumerate(pts):
                    a = pts[max(i - 1, 0)]; b = pts[min(i + 1, len(pts) - 1)]
                    tx, ty = b[0] - a[0], b[1] - a[1]; ln = math.hypot(tx, ty) or 1.0
                    nx, ny = -ty / ln, tx / ln
                    w = widths[i]
                    r, g = colours[i]
                    # soft profile across the channel: dark rim, hot middle
                    for off, k in ((-1.0, 0.0), (-0.4, 1.0), (0.4, 1.0), (1.0, 0.0)):
                        verts.append((p[0] + nx * w * off, p[1] + ny * w * off, z))
                        cols.append((r * k, g * k, 0.0, 1.0))
                for i in range(len(pts) - 1):
                    for c in range(3):
                        q = base + i * 4 + c
                        faces.append((q, q + 1, q + 5, q + 4))
            if row[0] >= 0.99:
                peak = 1
            me = bpy.data.meshes.new('bolt'); me.from_pydata(verts, [], faces); me.update()
            uv = me.uv_layers.new(name='heat')
            for loop in me.loops:
                c = cols[loop.vertex_index]
                uv.data[loop.index].uv = (c[0], c[1])
            me.materials.append(mat)
            ob = bpy.data.objects.new('bolt', me); sc.collection.objects.link(ob)
            sc.render.filepath = str(folder / ('frame_%02d.exr' % f))
            bpy.ops.render.render(write_still=True)
        records.append(dict(variant=key, code=cfg['code'], name=cfg['name'], seed=cfg['seed'], frames=FRAMES, tile=tile,
                            samples=samples, paths=len(paths), device=[d.name for d in devices] or ['CPU']))
        print('BAKE_DONE', key, cfg['code'], flush=True)
    return records


def read_exr(path):
    import bpy
    img = bpy.data.images.load(str(path))
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    a = np.empty(w * h * 4, np.float32); img.pixels.foreach_get(a)
    bpy.data.images.remove(img)
    return a.reshape(h, w, 4)[::-1]


def blur(x, sigma):
    pad = int(sigma * 4)
    p = np.pad(x, pad)
    n = p.shape[0]
    f = np.fft.fftfreq(n)
    g = np.exp(-2.0 * (math.pi * sigma * f) ** 2)
    k = np.outer(g, g)
    return np.real(np.fft.ifft2(np.fft.fft2(p) * k))[pad:-pad, pad:-pad]


def line_peak(sigma):
    """The blurred peak of one full-brightness main channel, drawn with the bake's own profile at CELL size."""
    x = (np.arange(CELL) + 0.5) / CELL - 0.5
    d = np.abs(x) / MAIN_HALF_W
    prof = np.where(d < 0.4, 1.0, np.clip((1.0 - d) / 0.6, 0.0, 1.0))
    return float(blur(np.tile(prof, (CELL, 1)), sigma)[CELL // 2].max())


def write_png(path, rgba):
    h, w, _ = rgba.shape
    raw = b''.join(b'\x00' + rgba[y].tobytes() for y in range(h))
    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
                     + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"
path="res://.godot/imported/{name}-{md5}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="{res}"
dest_files=["res://.godot/imported/{name}-{md5}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=false
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""


def pack(src, dst, variants):
    import hashlib
    dst.mkdir(parents=True, exist_ok=True)
    near_ref, far_ref = line_peak(SIGMA_NEAR), line_peak(SIGMA_FAR)
    manifest = dict(issue=1360, frames=FRAMES, grid=GRID, cell=CELL, bolt_top=BOLT_TOP, bolt_bottom=BOLT_BOTTOM,
                    channels='R main core, G fork core, B near glow (sigma %g px), A far glow (sigma %g px)' % (SIGMA_NEAR, SIGMA_FAR),
                    variants={})
    for key in variants:
        cfg = VARIANTS[key]
        atlas = np.zeros((CELL * GRID, CELL * GRID, 4), np.float32)
        curve = []
        for f in range(FRAMES):
            img = read_exr(src / key / ('frame_%02d.exr' % f))
            t = img.shape[0] // CELL
            core = img[:, :, :2].reshape(CELL, t, CELL, t, 2).mean(axis=(1, 3))
            core = np.clip(core, 0.0, 1.0)
            both = np.clip(core[:, :, 0] + 0.85 * core[:, :, 1], 0.0, 1.0)
            near = np.clip(blur(both, SIGMA_NEAR) / near_ref, 0.0, 1.0)
            far = np.clip(blur(both, SIGMA_FAR) / far_ref, 0.0, 1.0)
            cell = np.dstack([core[:, :, 0], core[:, :, 1], near, far])
            y, x = (f // GRID) * CELL, (f % GRID) * CELL
            atlas[y:y + CELL, x:x + CELL] = cell
            curve.append(round(float(cfg['schedule'][f][0]), 3))
        name = 'bolt_%s.png' % key
        write_png(dst / name, np.uint8(np.round(np.clip(atlas, 0.0, 1.0) * 255)))
        res = 'res://fx/atlases/storm/' + name
        (dst / (name + '.import')).write_bytes(IMPORT.format(name=name, md5=hashlib.md5(res.encode()).hexdigest(), res=res).encode())
        manifest['variants'][key] = dict(code=cfg['code'], name=cfg['name'], seed=cfg['seed'], file=name, main_brightness=curve,
                                         nonempty_frames=int(sum(1 for r in cfg['schedule'] if r[0] > 0 or r[1] > 0)))
        print('PACKED', key, name, flush=True)
    bake = src / 'bake.json'
    if bake.exists():
        manifest['source'] = json.loads(bake.read_text())
    # LF line endings on Windows too, the same as git stores them
    (dst / 'bake_manifest.json').write_bytes((json.dumps(manifest, indent=2) + '\n').encode())


def main():
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    p = argparse.ArgumentParser()
    p.add_argument('out'); p.add_argument('--tile', type=int, default=512); p.add_argument('--samples', type=int, default=32)
    p.add_argument('--variants', default='a,b,c'); p.add_argument('--pack', default=''); p.add_argument('--pack-only', action='store_true')
    p.add_argument('--cpu', action='store_true')
    a = p.parse_args(argv)
    out = pathlib.Path(a.out); out.mkdir(parents=True, exist_ok=True)
    variants = [v for v in a.variants.split(',') if v]
    if not a.pack_only:
        start = time.time()
        records = render(out, variants, a.tile, a.samples, a.cpu)
        (out / 'bake.json').write_text(json.dumps(dict(records=records, seconds=round(time.time() - start, 1)), indent=2))
    if a.pack:
        pack(out, pathlib.Path(a.pack), variants)


if __name__ == '__main__':
    main()
