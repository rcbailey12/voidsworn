# Brighten a TRELLIS paint map toward the concept art: TRELLIS de-lights the image and comes out about 2.5x too dark.
# One gain in linear light (keeps the hues), chosen so the mean painted texel lands at K x the concept's mean; soft roll-off near white.
# usage: python3 paint_level.py CODE_a.webp concept_cut.png [K=0.8]
import sys, numpy as np
from PIL import Image
def level(albedo_path, concept_path, K=.8):
    a = np.array(Image.open(albedo_path).convert('RGB')).astype(np.float64) / 255; m = a.sum(2) > 6 / 255
    c = np.array(Image.open(concept_path).convert('RGBA')).astype(np.float64); cm = c[..., 3] > 200; target = c[cm][:, :3].mean() / 255 * K
    lin = a ** 2.2; lo, hi = .5, 8.
    for _ in range(40):  # bisect the gain on the mean sRGB value of painted texels
        g = (lo + hi) / 2; o = np.where(lin * g < .6, lin * g, .6 + (1 - .6) * (1 - np.exp(-(lin * g - .6) / .4)))
        (lo, hi) = (g, hi) if (o[m] ** (1 / 2.2)).mean() < target else (lo, g)
    out = np.clip(o ** (1 / 2.2), 0, 1); Image.fromarray((out * 255 + .5).astype(np.uint8)).save(albedo_path, quality=90, method=6)
    return g, a[m].mean(), out[m].mean(), target
def _curve(lin, g): return np.where(lin * g < .6, lin * g, .6 + (1 - .6) * (1 - np.exp(-(lin * g - .6) / .4)))
def solve(arrays, concept_path, K=.8):
    """one gain for several paint maps together (audits, Oct 22: hull and kit were levelled separately and drifted apart).
    arrays: sRGB float images in 0..1. Returns the gain; the bounds are wide so a clamp shows up instead of hiding."""
    c = np.array(Image.open(concept_path).convert('RGBA')).astype(np.float64); target = c[c[..., 3] > 200][:, :3].mean() / 255 * K
    px = np.concatenate([a[a.sum(2) > 6 / 255] for a in arrays]); lin = px ** 2.2; lo, hi = .05, 20.
    for _ in range(50):
        g = (lo + hi) / 2; (lo, hi) = (g, hi) if (_curve(lin, g) ** (1 / 2.2)).mean() < target else (lo, g)
    return g
def apply(a, g):  # sRGB float image -> levelled sRGB float image
    return np.clip(_curve(a ** 2.2, g) ** (1 / 2.2), 0, 1)
if __name__ == '__main__':
    print(level(sys.argv[1], sys.argv[2], float(sys.argv[3]) if len(sys.argv) > 3 else .8))
