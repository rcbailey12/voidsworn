"""The Chorus grown body (issue 1291): lumpy fused swellings, deep folds and sac bulges grown into the hull's own skin, so the
body reads as one mass of flesh (the C13 concept, chorus_C13_spitter_v7.jpg), never balls stuck on a smooth hull.

field(...) returns fn(x, t) -> a radial push (sheet units) for the kit's wob hook (K.wob_fn): x the station, t the section
angle (0 the port beam, pi/2 the top, pi the starboard beam, 3 pi/2 the belly). Any Chorus sheet can use it; the swellings,
folds and their sizes are the sheet's own (the seed and the counts), the shapes are the family's."""
import math
import random

TAU = 2 * math.pi


def _wrap(d):
    return (d + math.pi) % TAU - math.pi


def field(seed, x_bow, x_aft, swell=22, folds=16, wrinkles=40, keep=(), height=(0.18, 0.42), size=(0.5, 1.0), depth=0.13, sweeps=0, shell=None):
    """the swell field. swell: fused swellings (gaussian lumps, overlapping in clusters); folds: deep creases running round the
    body between them, each a groove with a rolled lip on its aft side (skin bunched against the fold); wrinkles: shallow short
    creases over the swellings' flanks. keep: (x, t, r) spots left calm (a gland's knoll, a vent) where nothing swells or folds.
    sweeps: long folds swept back along the body from the nose (the concept's skin pulled aft over the shoulders).
    shell: (x_bow, x_aft, lo), where an armour shell lies over the back (section angles lo to pi - lo): the folds fade out
    under it, so the plates ride over the swellings without the skin's creases breaking through them.
    height and size: the swellings' push and their length (sheet units); depth: a deep fold's depth."""
    rng = random.Random(seed)

    def calm(x, t):
        k = 1.0
        for (xk, tk, rk) in keep:
            d2 = ((x - xk) / rk) ** 2 + (_wrap(t - tk) / (rk * 0.9)) ** 2
            k *= 1.0 - math.exp(-d2 * 1.5)
        return k
    L = x_bow - x_aft
    S = []
    # clusters: a few big swellings with smaller ones fused onto their shoulders (the concept's lumpy mass)
    while len(S) < swell:
        x0 = x_aft + L * rng.uniform(0.08, 0.9); t0 = rng.uniform(-0.9, math.pi + 0.9)
        sx = rng.uniform(*size); h = rng.uniform(*height)
        S.append((x0, t0, sx, sx * rng.uniform(0.55, 0.85), h))
        for _ in range(rng.randint(1, 3)):
            if len(S) >= swell:
                break
            a = rng.uniform(0, TAU); d = sx * rng.uniform(0.7, 1.1)
            S.append((x0 + d * math.cos(a), t0 + d * 0.8 * math.sin(a), sx * rng.uniform(0.45, 0.7), sx * rng.uniform(0.3, 0.5), h * rng.uniform(0.5, 0.85)))
    # the belly's sag: a broad low swell under each flank, the flesh hanging (the concept's underside)
    for t0 in (-0.75, math.pi + 0.75):
        S.append((x_aft + L * 0.5, t0, L * 0.32, 0.55, height[1] * 0.6))
    F = []
    for i in range(folds):
        # a fold runs round the body (along t), wandering fore and aft, deepest in its middle
        t0 = rng.uniform(-1.2, math.pi + 0.4); span = rng.uniform(0.7, 1.6)
        xa = x_aft + L * rng.uniform(0.1, 0.92); xb = xa + rng.uniform(-0.45, 0.45)
        F.append((t0, t0 + span, xa, xb, rng.uniform(-0.18, 0.18), rng.uniform(0.07, 0.11), depth * rng.uniform(0.6, 1.1)))
    W = []
    for i in range(wrinkles):
        t0 = rng.uniform(-1.2, math.pi + 1.2); span = rng.uniform(0.25, 0.6)
        xa = x_aft + L * rng.uniform(0.05, 0.95); xb = xa + rng.uniform(-0.2, 0.2)
        W.append((t0, t0 + span, xa, xb, rng.uniform(-0.06, 0.06), rng.uniform(0.045, 0.06), depth * rng.uniform(0.2, 0.35)))

    G = []
    for i in range(sweeps):
        # a sweep runs aft along the body, drifting round it, deepest in its middle; its width is in section angle
        xa = x_bow - L * rng.uniform(0.05, 0.6); ln = rng.uniform(1.2, 2.8)
        t0 = rng.uniform(-1.0, math.pi + 1.0)
        G.append((xa, xa - ln, t0, rng.uniform(-0.5, 0.5), rng.uniform(0.05, 0.08), depth * rng.uniform(0.7, 1.2)))

    def sweep(x, t, g):
        xa, xb, t0, drift, w, d = g
        u = (xa - x) / (xa - xb)
        if not (0.0 < u < 1.0):
            return 0.0
        tc = t0 + drift * u + 0.12 * math.sin(3.0 * u + t0)
        env = math.sin(math.pi * u) ** 0.6
        dt = _wrap(t - tc)
        if abs(dt) > 6 * w:
            return 0.0
        return env * (-d * math.exp(-(dt / w) ** 2) + 0.5 * d * math.exp(-((dt - 1.7 * w) / (1.3 * w)) ** 2)
                      + 0.3 * d * math.exp(-((dt + 1.6 * w) / (1.2 * w)) ** 2))

    def crease(x, t, f):
        t0, t1, xa, xb, bow, w, d = f
        u = _wrap(t - t0) / (t1 - t0) if t1 > t0 else -1
        if not (0.0 < u < 1.0):
            return 0.0
        xc = xa + (xb - xa) * u + bow * math.sin(math.pi * u)
        env = math.sin(math.pi * u) ** 0.7
        dx = x - xc
        if abs(dx) > 6 * w:
            return 0.0
        # the groove, and the skin bunched into a rolled lip on its aft side and a lower one fore
        return env * (-d * math.exp(-(dx / w) ** 2) + 0.5 * d * math.exp(-((dx + 1.7 * w) / (1.3 * w)) ** 2)
                      + 0.25 * d * math.exp(-((dx - 1.6 * w) / (1.2 * w)) ** 2))

    def covered(x, t):
        if not shell:
            return 0.0
        xb, xa, lo = shell
        tt = _wrap(t - math.pi / 2)   # 0 on the spine
        half = math.pi / 2 - lo
        k_t = min(1.0, max(0.0, (half + 0.15 - abs(tt)) / 0.3))
        k_x = min(1.0, max(0.0, (xb + 0.2 - x) / 0.4), max(0.0, (x - xa + 0.2) / 0.4))
        return k_t * min(1.0, k_x)

    def fn(x, t):
        v = 0.0
        c_ = 1.0 - covered(x, t)
        for (x0, t0, sx, st, h) in S:
            dx = (x - x0) / sx
            if abs(dx) > 3.2:
                continue
            dt = _wrap(t - t0) / st
            if abs(dt) > 3.2:
                continue
            v += h * math.exp(-dx * dx - dt * dt)
        if c_ > 0.0:
            fv = 0.0
            for f in F:
                fv += crease(x, t, f)
            for f in W:
                fv += crease(x, t, f)
            for g in G:
                fv += sweep(x, t, g)
            v += c_ * fv
        # taper to nothing at the very bow and stern, where the gland and the vents sit
        tip = min(1.0, (x_bow - x) / 0.5, (x - x_aft) / 0.4)
        return v * max(0.0, tip) * calm(x, t)
    fn.swellings = S; fn.folds = F
    return fn
