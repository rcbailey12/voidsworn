# A4 hull reshaping (Oct 27, Opus relaying the owner's Oct 24 ruling: space-not-naval covers the whole hull shape, bow profile, keel line
# and deck line). Some AI hulls carry a ship's side profile: a deck that rises toward the bow (sheer), a stem raked forward over a belly
# that sweeps up to it (forefoot). flat_bow() turns the forward part of the hull into a chisel wedge in side view: the belly runs flat to
# the tip, the top slopes down to a low blunt edge. The top view (the wedge silhouette) is untouched: only z moves.
# Works on the raw arrays (Blender working frame: x bow, y port, z up) after the cuts, before refining. No Blender needed.
import numpy as np
import hullio


def envelope(pos, idx, nb=200):
    """lowest and highest z per x bin over the kept triangles (smoothed), and the bin edges"""
    P = pos[np.unique(idx.ravel())]; x0, x1 = P[:, 0].min(), P[:, 0].max(); edges = np.linspace(x0, x1, nb + 1)
    b = np.clip(np.searchsorted(edges, P[:, 0]) - 1, 0, nb - 1)
    lo = np.full(nb, np.nan); hi = np.full(nb, np.nan)
    for k in range(nb):
        z = P[b == k, 2]
        if len(z): lo[k], hi[k] = z.min(), z.max()
    for a in (lo, hi):  # fill empty bins, then a light smooth
        ok = ~np.isnan(a); a[~ok] = np.interp(np.nonzero(~ok)[0], np.nonzero(ok)[0], a[ok])
        a[:] = np.convolve(np.pad(a, 2, mode='edge'), np.ones(5) / 5, mode='valid')
    return (edges[:-1] + edges[1:]) / 2, lo, hi


def flat_bow(pos, idx, x0, tip=.30, power=1.0, top=None):
    """in place on pos. x0: where the reshaping starts (aft of it nothing moves). tip: the tip's height as a share of the hull's depth at x0
    (0.3: a low blunt edge). power: the top line's curve (1 straight, under 1 a fuller shoulder). top: optional z cap for the envelope's top
    at x0 (when a part aft of x0 would otherwise set it). Returns the number of vertices moved."""
    xc, lo, hi = envelope(pos, idx)
    zlo = lambda x: np.interp(x, xc, lo); zhi = lambda x: np.interp(x, xc, hi)
    xmax = pos[np.unique(idx.ravel()), 0].max()
    zb0 = float(zlo(x0)); zt0 = float(zhi(x0)) if top is None else min(float(zhi(x0)), top)
    zt_tip = zb0 + (zt0 - zb0) * tip
    m = pos[:, 0] > x0
    x = pos[m, 0]; z = pos[m, 2]; s = np.clip((x - x0) / max(xmax - x0, 1e-6), 0, 1)
    a, b = zlo(x), zhi(x)
    t = np.clip((z - a) / np.maximum(b - a, 1e-6), 0, 1.0)
    zt = zt0 + (zt_tip - zt0) * s ** power
    pos[m, 2] = zb0 + t * (zt - zb0)
    return int(m.sum())


def vertex_normals(pos, idx):
    """area-weighted vertex normals, shared across UV-seam duplicates (welded by position)"""
    w = hullio.weld_ids(pos); a, b, c = pos[idx[:, 0]], pos[idx[:, 1]], pos[idx[:, 2]]; fn = np.cross(b - a, c - a)
    acc = np.zeros((w.max() + 1, 3))
    for k in range(3): np.add.at(acc, w[idx[:, k]], fn)
    n = acc[w]; L = np.linalg.norm(n, axis=1, keepdims=True); return n / np.maximum(L, 1e-12)
