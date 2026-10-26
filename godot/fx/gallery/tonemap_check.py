# Tonemapper colour-faithfulness check for look.gd (G4). Replicates Godot 4.7.2's ACES and AgX exactly (tonemap.glsl and
# environment_storage.cpp at the 4.7.2-stable tag) and the Khronos PBR Neutral curve, then scores how faithfully each
# keeps Voidsworn's colours: the six faction colours as effects (emissive, 1x to 16x) and the six hull albedos under the
# key light. Score = hue drift in OKLab (degrees) and chroma kept, at the brightness each colour is actually used at.
# usage: python3 tonemap_check.py   (prints a table; no files written)
import numpy as np

M709_2020_INSET = np.array([[0.544814746488245, 0.140416948464053, 0.0888104196149096],
                            [0.373787398372697, 0.754137554567394, 0.178871756420858],
                            [0.0813978551390581, 0.105445496968552, 0.732317823964232]]).T
M_OUTSET = np.array([[1.96488741169489, -0.299313364904742, -0.164352742528393],
                     [-0.855988495690215, 1.32639796461980, -0.238183969428088],
                     [-0.108898916004672, -0.0270845997150571, 1.40253671195648]]).T


def glsl_mat(rows):
    # GLSL mat3(vec3 a, vec3 b, vec3 c) takes columns; `color * M` (row vector) uses them as rows of M^T
    return np.array(rows, float)


def aces(c, white=8.0):
    eb = 1.8
    A, B, C, D, E = 0.0245786, 0.000090537, 0.983729, 0.432951, 0.238081
    rrt = glsl_mat([[0.59719 * eb, 0.35458 * eb, 0.04823 * eb], [0.07600 * eb, 0.90834 * eb, 0.01566 * eb], [0.02840 * eb, 0.13383 * eb, 0.83777 * eb]])
    odt = glsl_mat([[1.60475, -0.53108, -0.07367], [-0.10208, 1.10813, -0.00605], [-0.00327, -0.07276, 1.07602]])
    x = c @ rrt.T  # color *= M in GLSL: row vector times matrix, columns as given = rrt rows dot
    x = (x * (x + A) - B) / (x * (C * x + D) + E)
    x = x @ odt.T
    w = white * eb
    wt = (w * (w + A) - B) / (w * (C * w + D) + E)
    return x / wt


def agx(c, white=12.0, contrast=1.25, out_max=1.0):
    cross = 0.18
    sh_max = out_max - cross
    white = max(2.0, white) * out_max
    toe_a = ((1.0 / cross) - 1.0) * cross ** contrast
    den = cross ** contrast + toe_a
    slope = (contrast * cross ** (contrast - 1.0) * toe_a) / (den * den)
    w = (white - cross) ** 2 / sh_max * slope
    x = c @ M709_2020_INSET.T
    x = np.maximum(x, 0.0)
    s = x - cross
    ss = slope * s
    s = ss * (1.0 + s / w) / (1.0 + ss / sh_max) + cross
    t = x ** contrast
    t = t / (t + toe_a)
    x = np.where(x < cross, t, s)
    x = np.minimum(out_max, x)
    return x @ M_OUTSET.T


def neutral(c):
    start, desat = 0.8 - 0.04, 0.15
    c = c.copy()
    x = c.min(axis=-1, keepdims=True)
    off = np.where(x < 0.08, x - 6.25 * x * x, 0.04)
    c = c - off
    peak = c.max(axis=-1, keepdims=True)
    d = 1.0 - start
    newp = 1.0 - d * d / (peak + d - start)
    comp = c * newp / np.maximum(peak, 1e-6)
    g = 1.0 - 1.0 / (desat * (peak - newp) + 1.0)
    comp = comp * (1 - g) + newp * g
    return np.where(peak < start, c, comp)


def oklab(rgb):
    rgb = np.clip(rgb, 0, None)
    M1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929], [0.2119034982, 0.6806995451, 0.1073969566], [0.0883024619, 0.2817188376, 0.6299787005]])
    M2 = np.array([[0.2104542553, 0.7936177850, -0.0040720468], [1.9779984951, -2.4285922050, 0.4505937099], [0.0259040371, 0.7827717662, -0.8086757660]])
    lms = rgb @ M1.T
    return np.cbrt(lms) @ M2.T


def hue_chroma(rgb):
    L = oklab(rgb)
    return np.degrees(np.arctan2(L[..., 2], L[..., 1])), np.hypot(L[..., 1], L[..., 2]), L[..., 0]


FAC = {  # weapon, shield, engine (linear, ships3d.js FAC3D)
    "voidsworn": [(1.0, 0.45, 0.15), (1.0, 0.46, 0.16), (1.0, 0.50, 0.16)],
    "hegemony": [(0.55, 0.82, 1.0), (0.38, 0.68, 1.0), (0.45, 0.72, 1.0)],
    "corsair": [(0.95, 0.22, 0.10), (0.85, 0.16, 0.10), (1.0, 0.38, 0.16)],
    "chorus": [(0.85, 0.90, 0.30), None, (0.80, 0.90, 0.28)],
    "ithar": [(0.75, 1.0, 0.88), (0.72, 1.0, 0.86), (0.62, 1.0, 0.84)],
    "deathless": [(0.20, 1.0, 0.38), None, (0.15, 1.0, 0.35)],
}
HULL = dict(voidsworn='#4a4440', hegemony='#c4ccd5', corsair='#6a2c22', chorus='#57364c', ithar='#e4ebe7', deathless='#2c3431')


def lin(h):
    v = np.array([int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)])
    return np.where(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055) ** 2.4)


def score(fn, name, gain):
    # effects: the shaders' typical intensities (glow edges 1 to 3, cores and flashes 6 to 16) times fx_gain for that curve
    rows = []
    for f, cols in FAC.items():
        for c in cols:
            if c is None:
                continue
            c = np.array(c)
            h0, c0, _ = hue_chroma(c / c.max())
            for I in (0.5, 1.0, 2.0, 4.0):
                out = fn(c * I * gain)
                h1, c1, l1 = hue_chroma(np.clip(out, 0, 1))
                dh = abs((h1 - h0 + 180) % 360 - 180)
                rows.append((f, "fx", I, dh, c1 / max(c0, 1e-6), l1))
        # hulls under the key (energy 2, a lit face about cos 0.7) plus ambient 0.5
        a = lin(HULL[f])
        for E in (0.6, 1.4, 2.2):
            out = fn(a * E)
            h0, c0, _ = hue_chroma(a)
            h1, c1, l1 = hue_chroma(np.clip(out, 0, 1))
            dh = abs((h1 - h0 + 180) % 360 - 180) if c0 > 0.01 else 0.0
            rows.append((f, "hull", E, dh, c1 / max(c0, 1e-6) if c0 > 0.01 else 1.0, l1))
    return rows


if __name__ == "__main__":
    curves = [("ACES w8", lambda c: aces(c, 8.0), 0.5556), ("AgX w12 c1.25", lambda c: agx(c, 12.0, 1.25), 0.75),
              ("AgX w16 c1.25", lambda c: agx(c, 16.0, 1.25), 0.75), ("PBR Neutral", neutral, 0.5)]
    print("curve            | fx hue drift (deg) mean / worst | fx chroma kept | hull hue drift mean / worst | hull chroma kept | dark hulls L (chorus, deathless)")
    for name, fn, g in curves:
        r = score(fn, name, g)
        fx = [x for x in r if x[1] == "fx" and x[2] <= 2.0]
        hu = [x for x in r if x[1] == "hull"]
        dk = [x[5] for x in r if x[1] == "hull" and x[0] in ("chorus", "deathless") and x[2] == 1.4]
        worst_fx = max(fx, key=lambda x: x[3])
        worst_h = max(hu, key=lambda x: x[3])
        print("%-16s | %5.1f / %5.1f (%s %.1fx) | %4.2f | %5.1f / %5.1f (%s) | %4.2f | %.2f, %.2f" % (
            name, np.mean([x[3] for x in fx]), worst_fx[3], worst_fx[0], worst_fx[2], np.mean([x[4] for x in fx]),
            np.mean([x[3] for x in hu]), worst_h[3], worst_h[0], np.mean([x[4] for x in hu]), dk[0], dk[1]))
