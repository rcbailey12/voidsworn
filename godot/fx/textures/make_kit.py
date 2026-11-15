"""Bake the issue-367 masks with Python and Pillow, both free tools.

No downloaded images. Run: python godot/fx/textures/make_kit.py
The random seed, cooling particles and integration steps are fixed.
R/G/B carry head, cooling tail and soft glow, respectively.
"""
from pathlib import Path
import math
import random
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent


def tail():
    rng = random.Random(367)
    size = (256, 96)
    head = Image.new('L', size)
    trail = Image.new('L', size)
    glow = Image.new('L', size)
    h, t, g = ImageDraw.Draw(head), ImageDraw.Draw(trail), ImageDraw.Draw(glow)
    # Integrate small hot particles backwards from the moving head. Drag
    # narrows the history; transverse turbulence breaks up the cooling edge.
    for i in range(1600):
        x, y = 220.0, 48.0
        vx, vy = -rng.uniform(70, 210), rng.gauss(0, 9)
        age = rng.uniform(0, 0.95)
        for _ in range(int(age * 90)):
            x += vx / 90
            y += vy / 90
            vx *= 0.996
            vy += math.sin(x * 0.12 + i) * 0.15
        radius = 0.7 + 2.8 * (1 - age)
        t.ellipse((x-radius, y-radius, x+radius, y+radius), fill=int(190 * (1-age)**1.5))
    h.ellipse((206, 37, 234, 59), fill=255)
    g.ellipse((192, 27, 244, 69), fill=220)
    head = head.filter(ImageFilter.GaussianBlur(2.0))
    trail = trail.filter(ImageFilter.GaussianBlur(1.2))
    glow = glow.filter(ImageFilter.GaussianBlur(9.0))
    Image.merge('RGB', (head, trail, glow)).save(ROOT / 'hot_tail.png')


def beam():
    rng = random.Random(248)
    im = Image.new('RGB', (256, 64))
    # Periodic along the strip, tapered across it. Core and sheath scroll
    # at different rates in the shader, so the mask never freezes as a bar.
    for y in range(64):
        side = (y + 0.5) / 32 - 1
        for x in range(256):
            u = 2 * math.pi * x / 256
            flow = 0.7 + 0.15 * math.sin(u * 7 + side * 4) + 0.1 * math.cos(u * 13 - side * 6)
            core = math.exp(-side * side * 16) * (0.78 + 0.22 * math.sin(u * 3)**2)
            sheath = math.exp(-side * side * 2.5) * flow
            im.putpixel((x, y), tuple(int(255 * max(0, min(1, v))) for v in
                (core, sheath, sheath * (0.78 + rng.random() * 0.22))))
    im.save(ROOT / 'beam_flow.png')


def flake():
    im = Image.new('RGB', (64, 64))
    d = ImageDraw.Draw(im)
    d.polygon([(17, 12), (43, 16), (51, 40), (29, 49), (12, 34)], fill=(80, 130, 190))
    d.polygon([(17, 12), (43, 16), (29, 30), (12, 34)], fill=(225, 240, 255))
    d.polygon([(43, 16), (51, 40), (29, 30)], fill=(140, 185, 240))
    d.line([(17, 12), (43, 16), (51, 40)], fill=(255, 255, 255), width=2)
    im.save(ROOT / 'lit_flake.png')


if __name__ == '__main__':
    tail()
    beam()
    flake()
