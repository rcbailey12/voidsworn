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


def flat_bow(pos, idx, x0, tip=.30, power=1.0, top=None, fair=0, cut=None, beam=None):
    """in place on pos. x0: where the reshaping starts (aft of it nothing moves). tip: the tip's height as a share of the hull's depth at x0.
    power: the top line's curve (1 straight; 2.5 keeps the deck nearly level and chamfers it down only near the front: pass 5, Ryan saw
    the straight slope as a drooping, knife-down prow). top: optional z cap for the envelope's top at x0. fair: Taubin passes over the
    bow. cut: x where the point is cut off square (an armoured prow face goes there). beam (Oct 31, Ryan: V1b's bow is blunt from the side
    but still pointed from the top): the hull's half-width may taper only down to beam x its half-width at x0 by the cut, so the top view
    ends in a blunt prow face too. Returns the number of vertices moved."""
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
    if beam is not None:  # widen the taper: each slice's half-width is held at least at a straight taper from w(x0) to beam * w(x0)
        xe = cut if cut is not None else xmax; xw, wy = half_width(pos, idx); w0 = float(np.interp(x0, xw, wy))
        sw = np.clip((x - x0) / max(xe - x0, 1e-6), 0, 1); wmin = w0 * (1 - (1 - beam) * sw)
        wx = np.maximum(np.interp(x, xw, wy), 1e-4); k = np.maximum(wmin / wx, 1.0)
        k = 1 + (k - 1) * np.clip((x - x0) / .04, 0, 1)  # eased in over the first .04 so the flank does not kink
        pos[m, 1] = pos[m, 1] * k
    if fair: fair_region(pos, idx, x0, fair)
    if cut is not None:  # pass 5 (Ryan: 'a weird downward slope on hegemony prows'): the point is cut off square; kit.prow_face caps it
        pos[pos[:, 0] > cut, 0] = cut
    return int(m.sum())


def half_width(pos, idx, nb=200):
    """largest |y| per x bin (smoothed, empty bins filled), and the bin centres"""
    P = pos[np.unique(idx.ravel())]; x0, x1 = P[:, 0].min(), P[:, 0].max(); edges = np.linspace(x0, x1, nb + 1)
    b = np.clip(np.searchsorted(edges, P[:, 0]) - 1, 0, nb - 1); w = np.full(nb, np.nan)
    for k in range(nb):
        y = np.abs(P[b == k, 1])
        if len(y): w[k] = np.percentile(y, 98)  # not the very widest vertex: a stray sponson tip would set the whole slice
    ok = ~np.isnan(w); w[~ok] = np.interp(np.nonzero(~ok)[0], np.nonzero(ok)[0], w[ok])
    w = np.convolve(np.pad(w, 3, mode='edge'), np.ones(7) / 7, mode='valid')
    return (edges[:-1] + edges[1:]) / 2, w


def straighten(pos, idx, iters=8, sigma=.004, align=4, x_lo=-1.0, x_hi=1.0):
    """Oct 31 (Ryan, pass 5 sheets: 'a weird wavy effect'): the AI hulls' long bulges and ridges wobble along their length (soft, melted
    lines; flat_bow squashes them into bands at the bow). This evens the wobble out ALONG the ship only: Taubin smoothing of y and z where
    each edge counts by how closely it runs fore and aft (cos^align) and by how small the step across it is (exp(-(d/sigma)^2)), so
    lengthwise lines straighten while real steps (plate edges, the fronts of blocks) and the cross-section stay. x never moves."""
    w = hullio.weld_ids(pos); W = w.max() + 1
    P = np.zeros((W, 3)); np.add.at(P, w, pos); cnt = np.bincount(w, minlength=W)[:, None]; P /= np.maximum(cnt, 1)
    e = np.concatenate([w[idx[:, [0, 1]]], w[idx[:, [1, 2]]], w[idx[:, [2, 0]]]]); e = e[e[:, 0] != e[:, 1]]
    e = np.unique(np.concatenate([e, e[:, ::-1]]), axis=0)
    d = P[e[:, 1]] - P[e[:, 0]]; L = np.linalg.norm(d, axis=1) + 1e-12
    wt = (np.abs(d[:, 0]) / L) ** align * np.exp(-(np.linalg.norm(d[:, 1:], axis=1) / sigma) ** 2)
    inside = ((P[:, 0] > x_lo) & (P[:, 0] < x_hi)).astype(float)[:, None]
    ws = np.bincount(e[:, 0], weights=wt, minlength=W)[:, None]
    P0 = P.copy()
    for _ in range(iters):
        for lam in (.5, -.53):
            acc = np.zeros((W, 3)); np.add.at(acc, e[:, 0], P[e[:, 1]] * wt[:, None])
            avg = np.where(ws > 1e-9, acc / np.maximum(ws, 1e-12), P)
            dd = (avg - P) * lam * inside; dd[:, 0] = 0; P += dd
    moved = np.linalg.norm(P - P0, axis=1)
    pos[:] = P[w]
    return float(np.percentile(moved, 99)), float(moved.max())


def fair_region(pos, idx, x0, iters, ramp=.06):
    """hand-fairing stand-in (Opus, Oct 27: V1b's reshaped bow had a wavy underside): Taubin smoothing (no shrink) of y and z over the
    welded mesh forward of x0, fading in over `ramp`, so the AI surface's waves even out into a faired loft while the outline and the flat
    belly stay"""
    w = hullio.weld_ids(pos); W = w.max() + 1
    P = np.zeros((W, 3)); np.add.at(P, w, pos); cnt = np.bincount(w, minlength=W)[:, None]; P /= np.maximum(cnt, 1)
    e = np.concatenate([w[idx[:, [0, 1]]], w[idx[:, [1, 2]]], w[idx[:, [2, 0]]]]); e = e[e[:, 0] != e[:, 1]]; e = np.unique(np.concatenate([e, e[:, ::-1]]), axis=0)  # both directions, each edge once
    wt = np.clip((P[:, 0] - x0) / ramp, 0, 1)[:, None]
    deg = np.bincount(e[:, 0], minlength=W)[:, None]
    for _ in range(iters):
        for lam in (.5, -.53):
            acc = np.zeros((W, 3)); np.add.at(acc, e[:, 0], P[e[:, 1]]); avg = acc / np.maximum(deg, 1)
            d = (avg - P) * lam * wt; d[:, 0] = 0; P += d
    pos[:] = P[w]


def vertex_normals(pos, idx):
    """area-weighted vertex normals, shared across UV-seam duplicates (welded by position)"""
    w = hullio.weld_ids(pos); a, b, c = pos[idx[:, 0]], pos[idx[:, 1]], pos[idx[:, 2]]; fn = np.cross(b - a, c - a)
    acc = np.zeros((w.max() + 1, 3))
    for k in range(3): np.add.at(acc, w[idx[:, k]], fn)
    n = acc[w]; L = np.linalg.norm(n, axis=1, keepdims=True); return n / np.maximum(L, 1e-12)
