"""Verify the bake-off deliverables against the captured models and inputs."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    p = argparse.ArgumentParser()
    p.add_argument('work', type=Path)
    a = p.parse_args()
    work = a.work
    cfg = json.loads((work / 'config.json').read_text())
    gpu = json.loads((work / 'gpu.json').read_text())
    assert '5080' in gpu['adapter'] and gpu['renderer'] == 'forward_plus'
    assert gpu['resolution'] == [1920, 1080] and len(gpu['rows']) == 7
    assert gpu['vsync'] == 'disabled'
    expected = {(c, r) for c in cfg['ships'] for r in (['today', 'B', 'A'] if c == 'C19_51' else ['today', 'B'])}
    assert {(r['code'], r['route']) for r in gpu['rows']} == expected
    for code, route in sorted(expected):
        row = next(r for r in gpu['rows'] if (r['code'], r['route']) == (code, route))
        assert row['geometry']['triangles'] > 5000
        for test in ['single', 'fleet']:
            assert row[test]['frames'] == 360 and row[test]['warmup'] == 100
            assert row[test]['gpu_median_ms'] > 0 and row[test]['draw_calls'] > 0
        for kind in ['battle', 'close', 'top', 'side', 'below']:
            path = work / 'shots' / f'{code}_{route}_{kind}.png'
            im = Image.open(path).convert('RGB')
            assert im.size == (1920, 1080)
            if route != 'today':
                before = Image.open(work / 'shots' / f'{code}_today_{kind}.png').convert('RGB')
                delta = ImageChops.difference(im, before).crop((500, 200, 1420, 900))
                # A cruiser occupies few pixels at battle distance. Count
                # changed pixels instead of diluting its change over the sky.
                assert sum(delta.convert('L').histogram()[4:]) > 100, f'Unchanged or missing capture {path}'
        if route != 'today':
            folder = work / code / route
            info = json.loads((folder / 'build.json').read_text())
            assert info['reimport'] == 'PASS' and info['triangles'] == info['reimport_triangles'] == row['geometry']['triangles']
            assert sha(folder / f'route{route}.glb') == info['sha256']
            if route == 'B':
                assert info['gpu'] == 'OPTIX' and info['quads'] < 22000
                assert info['source_surface_coverage'] > .90
                assert info['occupied_texels'] > 500000, 'UV atlas coverage is too low'
                assert sha(info['source']) == info['source_sha256']
                if code == 'B16_23':
                    assert Image.open(folder / 'orm.png').getchannel('B').getextrema() == (0, 0), 'Organic surface contains metal'
            else:
                assert info['floating'] == [] and info['backward_guns'] == 0 and info['trim_sheet_bands'] == 8
    # Verify that the live packed ships and textures have not been replaced.
    for code, info in cfg['today'].items():
        packed = Path(info['packed_scene'])
        assert sha(packed) == info['sha256']
        source_dir = packed.parents[2] / 'assets/ships' / code
        for name, digest in info['maps'].items():
            assert sha(source_dir / name) == digest
    log = (work / 'gpu.log').read_text(errors='replace')
    assert '[surface75] GPU PASS' in log
    assert not any(x in log for x in ['SCRIPT ERROR', 'Assertion failed', 'Could not load'])
    result = dict(result='PASS', prototype_exports=4, render_variants=7, screenshots=35,
                  benchmark_cases=15, source_game_unchanged=True, adapter=gpu['adapter'],
                  verifier_sha256=sha(__file__))
    (work / 'verification.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
