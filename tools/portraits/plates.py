# Dark faction background plates (1024 px PNG) for the qref portrait mode: Qwen-Image-Edit paints the admiral onto
# the plate, so every portrait of a faction shares the same dark field and the same glow from the left.
# Run: python3 tools/portraits/plates.py <out_dir>   (then copy to Downloads\voidsworn_test\comfy_io\PORTRAITS\ on the PC)
import os, sys
import numpy as np
from PIL import Image, ImageFilter
GLOW = {'chorus': (214, 210, 74), 'voidsworn': (255, 122, 42), 'hegemony': (95, 160, 255), 'corsair': (224, 64, 44), 'ithar': (159, 255, 210), 'deathless': (61, 255, 106)}
FIELD = {'chorus': (40, 22, 36), 'voidsworn': (34, 28, 24), 'hegemony': (22, 30, 42), 'corsair': (36, 18, 14), 'ithar': (20, 32, 32), 'deathless': (14, 20, 17)}

def plate(fac, n=1024, seed=7):
    rng = np.random.default_rng(seed); y, x = np.mgrid[0:n, 0:n] / n
    base = np.array(FIELD[fac], float) / 255; glow = np.array(GLOW[fac], float) / 255
    vig = np.clip(1.2 - 1.3 * np.hypot(x - 0.5, y - 0.48), 0, 1)[..., None]
    light = np.exp(-((x - 0.02) ** 2 / 0.09 + (y - 0.42) ** 2 / 0.18))[..., None]   # soft glow from the left edge
    noise = rng.normal(0, 1, (n // 8, n // 8, 3)); noise = np.array(Image.fromarray(((noise * 0.5 + 0.5).clip(0, 1) * 255).astype(np.uint8)).resize((n, n), Image.BICUBIC)) / 255 - 0.5
    img = base * (0.35 + 0.65 * vig) + glow * light * 0.28 + noise * 0.05
    im = Image.fromarray((img.clip(0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))
    return im

if __name__ == '__main__':
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    for f in GLOW: plate(f).save(os.path.join(out, 'plate_%s.png' % f)); print('plate', f)
