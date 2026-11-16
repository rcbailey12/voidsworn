"""Bake a smoke-free charge discharge, 16 frames in a 4 by 4 mask atlas.

Run with the PC's ComfyUI Python. Pillow is the only dependency. The paths
are charge branches with tapered, cooling cores, not a gas simulation.
Red is the hot filament; green is its soft electric corona. No painted fill.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

CELL = 256
FRAMES = 16
SEED = 372


def bake(destination):
    rng = random.Random(SEED)
    paths = []
    for branch in range(7):
        angle = branch * math.tau / 7 + rng.uniform(-0.23, 0.23)
        points = [(128, 128)]
        for step in range(1, 12):
            radius = step * rng.uniform(7.0, 9.0)
            side = rng.uniform(-9, 9) * math.sin(step / 12 * math.pi)
            points.append((128 + math.cos(angle) * radius - math.sin(angle) * side,
                           128 + math.sin(angle) * radius + math.cos(angle) * side))
        paths.append(points)
        fork = points[5:8]
        tip = fork[-1]
        for step in range(1, 5):
            fork.append((tip[0] + math.cos(angle + 0.8) * step * 6 + rng.uniform(-3, 3),
                         tip[1] + math.sin(angle + 0.8) * step * 6 + rng.uniform(-3, 3)))
        paths.append(fork)
    atlas = Image.new("RGB", (CELL * 4, CELL * 4))
    for frame in range(FRAMES):
        t = frame / (FRAMES - 1)
        filament = Image.new("L", (CELL, CELL))
        draw = ImageDraw.Draw(filament)
        for index, points in enumerate(paths):
            reach = min(len(points), max(2, int(len(points) * (0.3 + t * 3))))
            intensity = int(255 * (1 - t) ** 1.5 * (0.65 + 0.35 * math.sin(index * 2.4 + t * 5) ** 2))
            draw.line(points[:reach], fill=intensity, width=2 if index % 2 == 0 else 1)
        filament = filament.filter(ImageFilter.GaussianBlur(0.55))
        corona = ImageChops.lighter(filament.filter(ImageFilter.GaussianBlur(2.0)),
                                   filament.filter(ImageFilter.GaussianBlur(5.0)))
        atlas.paste(Image.merge("RGB", (filament, corona, Image.new("L", filament.size))),
                    ((frame % 4) * CELL, (frame // 4) * CELL))
    destination.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(destination)
    print(f"SHIELD_CRACKLE seed={SEED} frames={FRAMES} cell={CELL} output={destination}")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=Path(__file__).resolve().parents[3] /
                        "godot/fx/textures/shield_crackle.png")
    bake(parser.parse_args().out)
