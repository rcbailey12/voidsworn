"""Refs #2003. Compare fresh CPU coupon tiles to the installed T2 GLB.

blender -b -t 4 --factory-startup --python-exit-code 1 -P tile_maps_test.py -- --project INSTALLED_GODOT_DIR
The tiles are written under TEMP (or --scratch TEMP_DIR) for inspection.
"""
import argparse
from pathlib import Path
import sys
from tempfile import gettempdir
from uuid import uuid4

import bpy
from PIL import Image, ImageStat

sys.path.insert(0, str(Path(__file__).resolve().parent))
import production as P
from outpost_production import t2_tiles

MAX_RGB_DRIFT = 0.02
ZONES = ('hgrey', 'hpanel', 'dark', 'hmetal', 'htrim')


def mean_rgb(path):
    with Image.open(path) as image:
        if image.size != (P.RES, P.RES):
            raise AssertionError(f'{path.name}: expected {P.RES}x{P.RES}, got {image.size}')
        return ImageStat.Stat(image.convert('RGB')).mean


def compare(project, scratch):
    baked, installed = scratch / 'baked', scratch / 'installed'
    baked.mkdir()
    installed.mkdir()
    glb = project / 'assets/ships/station_T2/station_T2.glb'
    accepted = t2_tiles(glb, installed)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 16
    print(f'T2 BAKE DEVICE {scene.cycles.device}, scratch {scratch}', flush=True)
    P.finish.configure(P.H)
    actual = P.tile_maps(baked, P.cruiser_density(project)['length_world'])
    failures = []
    for zone in ZONES:
        raw = mean_rgb(baked / f'T2_{zone}_albedo.png')
        expected = mean_rgb(Path(accepted[zone]['albedo'].filepath_raw))
        fresh = mean_rgb(Path(actual[zone]['albedo'].filepath_raw))
        drift = max(abs(a - b) / b for a, b in zip(fresh, expected))
        print(f'{zone}: installed {expected}, baked {fresh}, max RGB drift {drift:.3%}', flush=True)
        if min(raw) <= 10:
            failures.append(f'{zone}: near-black raw coupon {raw}')
        if drift > MAX_RGB_DRIFT:
            failures.append(f'{zone}: finished tile drift {drift:.3%} exceeds {MAX_RGB_DRIFT:.0%}')
    if failures:
        raise AssertionError('\n'.join(failures))
    print('T2 TILE COLOUR PASS', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--scratch', type=Path, default=Path(gettempdir()))
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    scratch = args.scratch / f't2-tiles-{uuid4().hex}'
    scratch.mkdir()
    compare(args.project, scratch)


if __name__ == '__main__':
    main()
