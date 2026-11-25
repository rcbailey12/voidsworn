"""Issue 1777 (Ship Exteriors V2, Law 6): the six faction micro-detail maps under godot/assets/ships/detail/.

Every map is made from seeded, periodic noise, so it tiles with no seam and the same seed always writes the same file.
Two files per faction (ids never change, display names do):
  <faction>_n.png      tangent-space normal map, OpenGL convention (green up), the micro relief
  <faction>_grain.png  RGBA grain for Godot's detail albedo (multiply): RGB is the colour grain (near white, never
                       brighter than the hull), A is how strongly the layer applies (render/look.gd reads it as the share)

Run: python3 contrib/opus/tools/issue1777/make_detail_maps.py [out_dir]   (numpy and Pillow only)
"""
import sys
import os
import numpy as np
from PIL import Image

N = 512
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "godot", "assets", "ships", "detail")


def band_noise(rng, lo, hi, aniso=(1.0, 1.0)):
    """Periodic noise keeping spatial frequencies between lo and hi cycles per tile (aniso stretches x or y)."""
    w = rng.standard_normal((N, N))
    f = np.fft.fftfreq(N) * N
    fx, fy = np.meshgrid(f * aniso[0], f * aniso[1])
    r = np.sqrt(fx * fx + fy * fy)
    filt = np.exp(-((np.log(np.maximum(r, 1e-6)) - np.log(np.sqrt(lo * hi))) ** 2) / (2 * (np.log(hi / lo) / 2.5) ** 2))
    filt[0, 0] = 0.0
    out = np.real(np.fft.ifft2(np.fft.fft2(w) * filt))
    out -= out.mean()
    return out / (out.std() + 1e-9)


def voronoi(rng, cells):
    """Periodic jittered-grid Voronoi: (F1 distance, F2 - F1 edge distance, cell id), distances in cell units."""
    pts = rng.random((cells, cells, 2))
    ids = rng.random((cells, cells))
    ys, xs = np.mgrid[0:N, 0:N] / N * cells
    cx, cy = np.floor(xs).astype(int), np.floor(ys).astype(int)
    d1 = np.full((N, N), 9.0)
    d2 = np.full((N, N), 9.0)
    idm = np.zeros((N, N))
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            gx, gy = cx + ox, cy + oy
            p = pts[gy % cells, gx % cells]
            px, py = gx + p[..., 0], gy + p[..., 1]
            d = np.sqrt((xs - px) ** 2 + (ys - py) ** 2)
            closer = d < d1
            d2 = np.where(closer, d1, np.minimum(d2, d))
            idm = np.where(closer, ids[gy % cells, gx % cells], idm)
            d1 = np.where(closer, d, d1)
    return d1, d2 - d1, idm


def dots(rng, count, radius_px, depth=1.0):
    """Periodic round pits (negative height) of a given radius at random places."""
    h = np.zeros((N, N))
    ys, xs = np.mgrid[0:N, 0:N]
    for _ in range(count):
        x0, y0 = rng.random(2) * N
        r = radius_px * (0.6 + 0.8 * rng.random())
        dx = (xs - x0 + N / 2) % N - N / 2
        dy = (ys - y0 + N / 2) % N - N / 2
        h -= depth * np.clip(1.0 - (dx * dx + dy * dy) / (r * r), 0.0, 1.0) ** 1.5
    return h


def lines(spacing_px, width_px, angle_deg, offset=0.0):
    """Periodic straight grooves; the angle is snapped so the pattern tiles (integer steps across the tile)."""
    a = np.deg2rad(angle_deg)
    kx, ky = round(np.cos(a) * N / spacing_px), round(np.sin(a) * N / spacing_px)
    ys, xs = np.mgrid[0:N, 0:N] / N
    ph = (xs * kx + ys * ky + offset) % 1.0
    d = np.minimum(ph, 1.0 - ph) * spacing_px
    return np.clip(1.0 - d / width_px, 0.0, 1.0)


def normal_png(h, strength):
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * strength
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * strength
    n = np.dstack([-gx, gy, np.ones_like(h)])   # OpenGL: +Y is up the image
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return Image.fromarray(np.uint8(np.clip((n * 0.5 + 0.5) * 255.0 + 0.5, 0, 255)), "RGB")


def grain_png(g, tint, lo, alpha):
    """g ~ zero mean; colour = tint * (lo .. 1), white at the bright end so the multiply only darkens."""
    g = (g - g.min()) / (g.max() - g.min() + 1e-9)
    v = lo + (1.0 - lo) * g
    rgb = np.dstack([v * tint[0], v * tint[1], v * tint[2]])
    a = np.full((N, N, 1), alpha)
    return Image.fromarray(np.uint8(np.clip(np.concatenate([rgb, a], 2) * 255.0 + 0.5, 0, 255)), "RGBA")


def sunward(rng):
    # rolled and forged dark cast iron: fine grain, a few furnace pits, faint weld seams pitted along their run
    grain = band_noise(rng, 60, 200) * 0.5 + band_noise(rng, 20, 60) * 0.3
    seam = (lines(256, 1.6, 0) + lines(256, 1.6, 90, 0.37)) * 0.5
    pits = dots(rng, 220, 2.2) + dots(rng, 900, 1.0, 0.5) * np.clip(seam * 3, 0, 1)
    h = grain * 0.35 + pits * 2.0 + seam * 1.2
    mott = band_noise(rng, 2, 6) * 0.7 + band_noise(rng, 8, 20) * 0.3   # carbon mottling, colour only
    return h, 3.0, mott + grain * 0.25, (1.0, 0.97, 0.93), 0.72, 0.42


def hegemony(rng):
    # brushed aerospace alloy along one axis, crisp fastener rows on the panel rhythm
    brush = band_noise(rng, 30, 220, aniso=(16.0, 1.0))
    ys, xs = np.mgrid[0:N, 0:N]
    pitch = 64
    dx = (xs % pitch) - pitch / 2
    dy = (ys % 128) - 6
    r2 = dx * dx + dy * dy
    fast = np.clip(1.0 - np.abs(np.sqrt(r2) - 3.0) / 1.2, 0, 1) - 0.6 * np.clip(1.0 - r2 / 4.0, 0, 1)
    h = brush * 0.18 + fast * 1.0
    return h, 3.2, brush * 0.6 + band_noise(rng, 3, 8) * 0.4, (0.98, 0.99, 1.0), 0.82, 0.34


def corsair(rng):
    # hammered, pitted salvage iron: shallow hammer dimples, deep rust pits, crusty oxide breakup
    d1, _, _ = voronoi(rng, 14)
    dimple = -(1.0 - np.clip(d1, 0, 1) ** 2)
    crust = band_noise(rng, 40, 160)
    pits = dots(rng, 500, 2.0) + dots(rng, 80, 4.5, 0.6)
    h = dimple * 0.7 + crust * 0.2 + pits * 1.3
    rust = np.clip(band_noise(rng, 2, 7) - 0.3, 0, None) * 1.2 + crust * 0.35
    return h, 3.4, -rust, (1.0, 0.94, 0.88), 0.66, 0.46


def chorus(rng):
    # keratin and chitin: long warped striations, wet pores, slow dermal wrinkles (no metal look)
    warp = band_noise(rng, 2, 6) * 18.0
    ys, xs = np.mgrid[0:N, 0:N]
    stri = np.sin((ys + warp) / N * 2 * np.pi * 48) * 0.5 + band_noise(rng, 40, 200, aniso=(12.0, 1.0)) * 0.35
    wrinkle = np.abs(band_noise(rng, 5, 14, aniso=(3.0, 1.0)))
    pores = dots(rng, 700, 1.6, 0.9)
    h = stri * 0.45 - wrinkle * 0.8 + pores * 1.2
    return h, 2.8, stri * 0.3 - wrinkle * 0.6 + band_noise(rng, 3, 9) * 0.4, (1.0, 0.95, 0.97), 0.8, 0.38


def ithar(rng):
    # annealed crystal: tiny flat micro-facets (each cell its own tilt), fine etched edge grain; no grime
    cells = 22
    d1, edge, idm = voronoi(rng, cells)
    ys, xs = np.mgrid[0:N, 0:N] / N * cells
    ang = idm * 2 * np.pi
    facet = (np.cos(ang) * xs + np.sin(ang) * ys) * 0.35
    facet = facet - np.floor(facet)   # keeps each facet a flat tilt; edges between them read as fine ridges
    ridge = np.clip(1.0 - edge / 0.06, 0, 1)
    h = facet * 0.25 + ridge * 0.5 + band_noise(rng, 120, 250) * 0.04
    return h, 2.2, -ridge * 0.4 + band_noise(rng, 4, 10) * 0.1, (0.99, 1.0, 1.0), 0.93, 0.22


def deathless(rng):
    # obsidian slate: smooth, with hairline fractures and a sparse geometric vein lattice
    _, edge, _ = voronoi(rng, 9)
    crack = np.clip(1.0 - edge / 0.025, 0, 1) * np.clip(band_noise(rng, 2, 5) + 0.4, 0, 1)
    vein = lines(170, 1.2, 0) + lines(170, 1.2, 60) * 0.7 + lines(256, 1.0, 120, 0.21) * 0.6
    h = -crack * 1.1 - vein * 0.6 + band_noise(rng, 60, 220) * 0.05
    return h, 3.0, -crack * 0.8 - vein * 0.4 + band_noise(rng, 2, 6) * 0.2, (0.98, 0.97, 1.0), 0.8, 0.36


FACTIONS = {"voidsworn": sunward, "hegemony": hegemony, "corsair": corsair, "chorus": chorus, "ithar": ithar, "deathless": deathless}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for i, (fac, fn) in enumerate(FACTIONS.items()):
        rng = np.random.default_rng(1777 + i)
        h, strength, g, tint, lo, alpha = fn(rng)
        normal_png(h, strength).save(os.path.join(OUT, fac + "_n.png"), optimize=True)
        grain_png(g, tint, lo, alpha).save(os.path.join(OUT, fac + "_grain.png"), optimize=True)
        print(fac, "ok")
