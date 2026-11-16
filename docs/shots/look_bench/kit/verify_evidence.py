"""Check delivered kit evidence, its coverage and its source before review."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
from PIL import Image

REPO = Path(__file__).resolve().parents[4]


def read(path):
    return json.loads(path.read_text())


def main():
    p = argparse.ArgumentParser()
    p.add_argument('shots', type=Path)
    args = p.parse_args()
    shots = args.shots.resolve()
    after = shots / 'after'
    source = read(after / 'source_hashes.json')
    for name, expected in source.items():
        actual = hashlib.sha256((REPO / 'godot' / name).read_bytes()).hexdigest()
        assert actual == expected, f'Stale capture: {name}'
    rows = read(after / 'moments.json')['rows']
    expected = {(r['id'], cam) for r in rows for cam in [170, 60, 26]}
    for version in ['before', 'after']:
        folder = shots / version
        bench = read(folder / 'bench.json')
        assert not bench['warnings'], bench['warnings']
        assert {(r['id'], r['cam']) for r in bench['stills']} == expected
        for row in bench['stills']:
            for key in ['file', 'native_file']:
                if key in row:
                    with Image.open(folder / row[key]) as im:
                        assert im.size == (640 * len(row['cells']), 360)
                        im.verify()
    sheets = read(shots / 'sheets' / 'sheet_frames.json')
    assert {r['id'] for r in sheets} == {r['id'] for r in rows}
    for path in (shots / 'sheets').glob('*.png'):
        with Image.open(path) as im:
            assert im.width <= 1280 and im.height <= 720, path
            im.verify()
    costs = {}
    for version in ['before', 'after']:
        folder = shots / ('gate_' + version)
        gate = read(folder / 'scene_gate.json')
        assert read(folder / 'source_hashes.json') == read(shots / version / 'source_hashes.json')
        costs[version] = {
            'frame_1080_ms': statistics.median(r['frame_median'] for r in gate['modes']['base']),
            'gpu_4k_ms': statistics.median(r['gpu_median'] for r in gate['modes']['res_2160']),
            'sessions': len(gate['modes']['base']),
        }
    summary = dict(rows=len(rows), stills_per_version=len(expected), costs=costs,
                   after_source_sha256=source,
                   approval='Ryan faction picks and visual approval pending')
    (shots / 'evidence_summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps(summary, indent=2))
    assert max(costs['after']['frame_1080_ms'], costs['after']['gpu_4k_ms']) < 12.5
    print('EVIDENCE PASS: current source, all rows at all cameras, readable sheets, scene gate')


if __name__ == '__main__':
    main()
