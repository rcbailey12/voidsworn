"""Issue 353: pack the route A or route B renders into the game's flipbook atlases, in both fire amounts.

python pack_routes.py BAKE_OUT DEST --route a|b [--fire fire|firelo|firehi]

DEST/<amount>/ is laid out like godot/fx/atlases/ (death/small|cruiser|capital/flash_*.png, weapons/impact/impact_*.png),
so the bench switch VS_FX_ATLAS=DEST/<amount> swaps just those two kinds. Amounts (R88, R158: flash and snuff out):
  flash  the bright flash only: fire in the first cell, a trace in the second, then smoke and debris that thin.
  core   the flash plus a short hot core that cools over four cells and is gone from cell 5 of 16 (5/15 of the
         effect's life: 0.14 s for the torpedo hit's 0.42 s impact gas, 0.07 s for the 0.20 s ship-death flash).
Route B also writes core_s1/ and core_s2/ (seeds 1 and 2) and authors its hot core, colour ramp and sparks here.

Channels match pack_death.py so the game's shader reads them: colour (RGB, straight alpha), motion (RG forward, BA
backward, +/- .125 per frame, Horn-Schunck on the alpha), thickness (R optical depth, G lit, B heat 0 smoke to 1 fire,
A alpha). The colour is not cut to six levels (today's grade) and the gas is framed to fill about four fifths of the cell.
Writes DEST/route_manifest.json (fill, sizes, bake seconds) and DEST/preview_<kind>_<amount>.png strips.
"""
import argparse, json, math, pathlib, random
import numpy as np
from PIL import Image, ImageFilter

p = argparse.ArgumentParser(); p.add_argument('src'); p.add_argument('dst'); p.add_argument('--route', required=True, choices=['a', 'b'])
p.add_argument('--fire', default='fire')   # route A: which fire render to pack (fire, or firelo / firehi: half / double strength)
a = p.parse_args(); src = pathlib.Path(a.src); dst = pathlib.Path(a.dst); dst.mkdir(parents=True, exist_ok=True)
FILL = .80
AMOUNTS = {'flash': [1.0, .3] + [0.0] * 14, 'core': [1.0, .8, .55, .3, .12] + [0.0] * 11}
BANDS = {'impact': [('weapons/impact', 1024)], 'flash': [('death/small', 1024), ('death/cruiser', 1536), ('death/capital', 2048)]}
RAMP = [(0.0, (.45, .05, .01)), (.35, (1, .32, .04)), (.7, (1, .78, .30)), (1.0, (1, .97, .9))]   # as route_common.fire_material


def blur(x):
    return (x + np.roll(x, 1, 0) + np.roll(x, -1, 0) + np.roll(x, 1, 1) + np.roll(x, -1, 1)) / 5
def warp(x, u, v):
    yy, xx = np.indices(x.shape); xx = np.clip(xx + u, 0, x.shape[1] - 1.001); yy = np.clip(yy + v, 0, x.shape[0] - 1.001)
    xi = xx.astype(int); yi = yy.astype(int); xf = xx - xi; yf = yy - yi
    return (x[yi, xi] * (1 - xf) + x[yi, xi + 1] * xf) * (1 - yf) + (x[yi + 1, xi] * (1 - xf) + x[yi + 1, xi + 1] * xf) * yf
def flow(aa, bb):
    # Coarse-to-fine Horn-Schunck, as pack_death.py.
    u = v = None
    for n in [24, 48, 96, 192]:
        x = np.array(Image.fromarray(aa).resize((n, n), Image.Resampling.BILINEAR), dtype=np.float32) / 255
        y = np.array(Image.fromarray(bb).resize((n, n), Image.Resampling.BILINEAR), dtype=np.float32) / 255
        if u is None: u = np.zeros_like(x); v = np.zeros_like(x)
        else:
            u = np.array(Image.fromarray(u).resize((n, n), Image.Resampling.BILINEAR)) * 2
            v = np.array(Image.fromarray(v).resize((n, n), Image.Resampling.BILINEAR)) * 2
        for _ in range(3):
            yw = warp(y, u, v); gy, gx = np.gradient((x + yw) * .5); dt = yw - x; du = np.zeros_like(x); dv = np.zeros_like(x)
            for __ in range(28):
                ub = blur(du); vb = blur(dv); q = (gx * ub + gy * vb + dt) / (.008 + gx * gx + gy * gy); du = ub - gx * q; dv = vb - gy * q
            u += du; v += dv
    return np.stack([u / n, v / n], axis=-1)


def ramp(t):
    t = np.clip(t, 0, 1); out = np.zeros(t.shape + (3,), np.float32)
    for (p0, c0), (p1, c1) in zip(RAMP, RAMP[1:]):
        m = (t >= p0) & (t <= p1); f = ((t - p0) / (p1 - p0))[m][:, None]
        out[m] = np.array(c0) * (1 - f) + np.array(c1) * f
    return out


def load(path, mode):
    return np.array(Image.open(path).convert(mode), dtype=np.float32) / 255


def frame_box(masks, tile):
    """A square crop centred on the source so the largest frame spans FILL of the cell."""
    c = (tile - 1) / 2; yy, xx = np.indices((tile, tile)); d = np.maximum(abs(xx - c), abs(yy - c))
    r = max([d[m].max() for m in masks if m.any()] + [8])
    side = int(min(tile, max(32, math.ceil(2 * (r + 1) / FILL))))
    lo = int(round(c - side / 2 + .5)); return lo, side


def crop(img, lo, side, tile):
    arr = img[lo:lo + side, lo:lo + side]
    if side == tile: return arr
    chans = [np.array(Image.fromarray(arr[..., k]).resize((tile, tile), Image.Resampling.BICUBIC)) for k in range(arr.shape[-1])]
    return np.clip(np.stack(chans, -1), 0, None)


def value_noise(rnd, tile, cells):
    g = np.array([[rnd.random() for _ in range(cells)] for _ in range(cells)], np.float32)
    return np.array(Image.fromarray(g).resize((tile, tile), Image.Resampling.BICUBIC))


def authored(kind, seed, tile, w):
    """Route B: the hot core (seeded, lumpy, through the fire ramp) and the sparks (small hot points on curved, slowing
    paths with short trails). Returns 16 RGB arrays (0..1+) in cell space; w is the fire amount per cell (core only)."""
    rnd = random.Random(35300 + seed * 11 + (0 if kind == 'impact' else 500))
    big = kind == 'flash'; c = (tile - 1) / 2; yy, xx = np.indices((tile, tile)); ux = (xx - c) / (tile / 2); uy = (yy - c) / (tile / 2)
    r = np.hypot(ux, uy); th = np.arctan2(uy, ux)
    lump = 1 + sum(rnd.uniform(.015, .045) * np.cos(k * th + rnd.uniform(0, math.tau)) for k in range(3, 10))
    grain = .75 + .5 * value_noise(rnd, tile, 12)
    sparks = [dict(t=rnd.uniform(0, math.tau), s=rnd.uniform(.55, 1.0), om=rnd.uniform(-1.2, 1.2), k=rnd.uniform(1.8, 3.2),
                   life=rnd.uniform(.3, .55)) for _ in range(16 if big else 10)]
    rad = max(.6, tile / 420)
    out = []
    for i in range(16):
        T = i / 15; img = np.zeros((tile, tile, 3), np.float32)
        if w[i] > 0:
            rc = (.27 if big else .22) * (1.0 + .3 * (1 - math.exp(-i / 2.0)))   # the flash is big at once, then the core spreads as it cools
            heat = w[i] * np.exp(-((r / lump) / rc) ** 2 * 1.6) * grain
            img += ramp(heat) * np.clip(heat * 1.4, 0, 1)[..., None]
        for sp in sparks:
            for j in range(5):
                t = T - j * .02
                if t < 0 or t > sp['life']: continue
                b = (1 - t / sp['life']) * (1 - j / 5)
                d = .85 * sp['s'] * (1 - math.exp(-sp['k'] * t)) / (1 - math.exp(-sp['k']))
                ang = sp['t'] + sp['om'] * t; px = c + math.cos(ang) * d * tile / 2; py = c + math.sin(ang) * d * tile / 2
                x0, x1 = int(max(0, px - 3 * rad)), int(min(tile, px + 3 * rad + 1)); y0, y1 = int(max(0, py - 3 * rad)), int(min(tile, py + 3 * rad + 1))
                if x0 >= x1 or y0 >= y1: continue
                g = np.exp(-(((xx[y0:y1, x0:x1] - px) ** 2 + (yy[y0:y1, x0:x1] - py) ** 2) / (2 * rad * rad)))
                col = np.array([1, .85 - .4 * t, .55 - .45 * t], np.float32)
                img[y0:y1, x0:x1] += g[..., None] * col * b * .55
        out.append(img)
    return out


def compose(smoke, fire):
    """Fire over lit smoke. Returns straight RGB, alpha and heat (the fire's share of the pixel)."""
    s_rgb, a_s = smoke[..., :3], smoke[..., 3]
    fl = np.clip(fire.max(-1), 0, 1); fa = np.clip((fl - .06) * 1.4, 0, 1)
    f_norm = np.clip(fire / np.maximum(fire.max(-1, keepdims=True), 1e-4), 0, 1)
    alpha = a_s + fa * (1 - a_s)
    pm = f_norm * fa[..., None] + s_rgb * (a_s * (1 - fa))[..., None]
    rgb = pm / np.maximum(alpha, 1e-3)[..., None]
    heat = np.clip(fa / np.maximum(alpha, 1e-3), 0, 1) * (alpha > 1e-3)
    return np.clip(rgb, 0, 1), alpha, heat


def write_set(kind, cells, folder_root):
    """cells: 16 (rgb, alpha, heat). Writes the three atlases for every band of this kind. Returns sizes in bytes."""
    tile = cells[0][1].shape[0]; atl = [np.zeros((tile * 4, tile * 4, 4), np.uint8) for _ in range(3)]
    alphas = [np.uint8(np.clip(al, 0, 1) * 255) for _, al, _ in cells]
    fw = [flow(alphas[i], alphas[min(i + 1, 15)]) for i in range(16)]; bw = [flow(alphas[i], alphas[max(i - 1, 0)]) for i in range(16)]
    for i, (rgb, al, heat) in enumerate(cells):
        y, x = (i // 4) * tile, (i % 4) * tile
        atl[0][y:y + tile, x:x + tile] = np.uint8(np.clip(np.dstack([rgb, al]), 0, 1) * 255)
        mo = [np.array(Image.fromarray(m[..., k]).resize((tile, tile))) for m in (fw[i], bw[i]) for k in (0, 1)]
        atl[1][y:y + tile, x:x + tile] = np.uint8(np.clip(np.stack(mo, -1) / .25 + .5, 0, 1) * 255)
        tau = -np.log(np.maximum(1 - al, .005)) / 5.3
        atl[2][y:y + tile, x:x + tile] = np.uint8(np.clip(np.stack([tau, rgb.mean(-1), heat, al], -1), 0, 1) * 255)
    sizes = {}
    for rel, pixels in BANDS[kind]:
        folder = folder_root / rel; folder.mkdir(parents=True, exist_ok=True); total = 0
        for arr, suffix in zip(atl, ['color', 'flow', 'thickness']):
            target = folder / (kind + '_' + suffix + '.png')
            Image.fromarray(arr).resize((pixels, pixels), Image.Resampling.BILINEAR).save(target, optimize=True); total += target.stat().st_size
        sizes[rel] = total
    return sizes


def fill_of(cells):
    """Widest frame of alpha over 25 of 255, in pixels of a 256 pixel cell (the Board's measure: today 52 and 45)."""
    best = 0
    for _, al, _ in cells:
        m = np.array(Image.fromarray(np.uint8(np.clip(al, 0, 1) * 255)).resize((256, 256), Image.Resampling.BILINEAR)) > 25
        if m.any():
            ys, xs = np.nonzero(m); best = max(best, xs.max() - xs.min() + 1, ys.max() - ys.min() + 1)
    return int(best)


def preview(cells, path):
    pick = [0, 1, 2, 3, 4, 6, 8, 11]; t = 192; sheet = Image.new('RGB', (t * len(pick), t), (12, 12, 20))
    for k, i in enumerate(pick):
        rgb, al, heat = cells[i]; col = np.clip(rgb * (1 + heat[..., None] * 2.5), 0, 1)
        bg = np.array([.05, .05, .08], np.float32); img = col * al[..., None] + bg * (1 - al[..., None])
        sheet.paste(Image.fromarray(np.uint8(img * 255)).resize((t, t), Image.Resampling.BILINEAR), (k * t, 0))
    sheet.save(path)


bake = json.loads((src / 'bake.json').read_text()); manifest = dict(route=a.route, fire_pass=a.fire if a.route == 'a' else 'authored', bake=bake, sets={})
for kind in ['impact', 'flash']:
    runs = [(None, src / kind)] if a.route == 'a' else sorted((int(d.name[1:]), d) for d in (src / kind).glob('s*') if d.is_dir())
    for seed, folder in runs:
        smoke = [load(folder / ('smoke_%02d.png' % i), 'RGBA') for i in range(16)]
        tile = smoke[0].shape[0]
        smoke = [np.dstack([np.array(Image.fromarray(np.uint8(s[..., :3] * 255)).filter(ImageFilter.GaussianBlur(1.0)), np.float32) / 255,
                            np.array(Image.fromarray(np.uint8(s[..., 3] * 255)).filter(ImageFilter.GaussianBlur(1.0)), np.float32) / 255]) for s in smoke]
        fire = [load(folder / ('%s_%02d.png' % (a.fire, i)), 'RGB') for i in range(16)] if a.route == 'a' else None
        masks = [s[..., 3] > .1 for s in smoke] + ([f.max(-1) > .1 for f in fire] if fire else [])
        lo, side = frame_box(masks, tile)
        smoke = [crop(s, lo, side, tile) for s in smoke]
        if fire: fire = [crop(f, lo, side, tile) for f in fire]
        for amount, w in AMOUNTS.items():
            if seed not in (None, 0) and amount != 'core': continue
            if a.route == 'a':
                fires = [f * w[i] for i, f in enumerate(fire)]
                smokes = smoke
            else:
                fires = authored(kind, seed, tile, w)
                warm = [np.array([1.0 + .25 * w[i], 1.0 + .05 * w[i], 1.0 - .1 * w[i]], np.float32) for i in range(16)]   # a little warm light from the core, no tan
                smokes = [np.dstack([np.clip(s[..., :3] * warm[i], 0, 1), s[..., 3:]]) for i, s in enumerate(smoke)]
            cells = [compose(smokes[i], fires[i]) for i in range(16)]
            name = amount if seed in (None, 0) else '%s_s%d' % (amount, seed)
            sizes = write_set(kind, cells, dst / name)
            preview(cells, dst / ('preview_%s_%s.png' % (kind, name)))
            manifest['sets']['%s/%s' % (name, kind)] = dict(fill_of_256=fill_of(cells), crop_side=side, tile=tile, bytes=sizes,
                                                           fire_cells=[round(x, 2) for x in w])
            print('PACKED', a.route, name, kind, manifest['sets']['%s/%s' % (name, kind)]['fill_of_256'], sizes, flush=True)
(dst / 'route_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print('PACK_DONE', a.route, flush=True)
