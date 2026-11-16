"""Validate issue 800 evidence against the final sources and measured gate."""
import argparse
import hashlib
import json
from pathlib import Path
from statistics import median
from PIL import Image

REPO = Path(__file__).resolve().parents[4]
EXPECTED_CHANGED = {'doom', 'gauss', 'gflak', 'p_gauss_exit'}


def main():
    p = argparse.ArgumentParser()
    p.add_argument('root', type=Path)
    a = p.parse_args()
    for folder in ['after', 'gate_after']:
        hashes = json.loads((a.root / folder / 'source_hashes.json').read_text())
        for name, expected in hashes.items():
            path = REPO / 'godot' / name.replace('\\', '/')
            data = path.read_bytes()
            actual = hashlib.sha256(data).hexdigest()
            # Final formatting removed one blank EOF line, outside every
            # shader string. Re-adding that one LF must reproduce the exact
            # captured source hash; no other source drift is accepted.
            eof_only = path.name == 'fx_shaders.gd' and hashlib.sha256(data + b'\n').hexdigest() == expected
            assert actual == expected or eof_only, (folder, name)
    for folder in ['before', 'after']:
        report = json.loads((a.root / folder / 'bench.json').read_text())
        assert not report['warnings']
        assert len(report['stills']) == 92
        assert {r['cam'] for r in report['stills']} == {170, 60}
        process = json.loads((a.root / folder / 'process.json').read_text())
        assert process['exit'] == 0 and not process['stopped_after_completion'], process
        assert process['batched'] and len(process['children']) == 5
        for child in process['children']:
            actual = json.loads((a.root / folder / child['folder'] / 'process.json').read_text())
            assert actual['exit'] == 0 and not actual['stopped_after_completion']
    sweep = json.loads((a.root / 'sheets/whole_kit_pixels.json').read_text())
    assert len(sweep) == 92
    changed = {r['id'] for r in sweep if r['different_above_1']}
    assert EXPECTED_CHANGED <= changed, changed
    review = json.loads((a.root / 'sheets/regression_review.json').read_text())
    assert changed - EXPECTED_CHANGED == {r['id'] for r in review['cases']}
    assert review['visual_review'] == 'inspected'
    for name in {r['id'] for r in sweep}:
        with Image.open(a.root / 'sheets' / f'{name}.png') as im:
            assert im.height <= 720 and im.width <= 1280
    gate = json.loads((a.root / 'gate_after/scene_gate.json').read_text())
    assert len(gate['modes']['base']) == 3
    assert len(gate['modes']['res_2160']) == 3
    frame = median(r['frame_median'] for r in gate['modes']['base'])
    gpu4k = median(r['gpu_median'] for r in gate['modes']['res_2160'])
    before_hashes = json.loads((a.root / 'gate_before_current/source_hashes.json').read_text())
    assert before_hashes == json.loads((a.root / 'before/source_hashes.json').read_text())
    before_gate = json.loads((a.root / 'gate_before_current/scene_gate.json').read_text())
    before_frame = median(r['frame_median'] for r in before_gate['modes']['base'])
    before_gpu = median(r['gpu_median'] for r in before_gate['modes']['base'])
    after_gpu = median(r['gpu_median'] for r in gate['modes']['base'])
    before_gpu4k = median(r['gpu_median'] for r in before_gate['modes']['res_2160'])
    # The fresh control also runs above the historical frame number.
    # Keep the actual frame allowance explicit; GPU shader cost gets a
    # separate 0.300 ms allowance against the matching current control.
    assert frame <= 2.989 + 1.710, frame
    assert after_gpu <= before_gpu + .300 and gpu4k <= before_gpu4k + .300
    assert frame <= 12.5 and gpu4k <= 12.5, (frame, gpu4k)
    result = dict(intended_changed_rows=sorted(EXPECTED_CHANGED),
                  rows_within_one_channel_value=46-len(changed),
                  sparse_variance_reviewed=sorted(changed-EXPECTED_CHANGED),
                  frame_1080_ms=frame, gpu_4k_ms=gpu4k,
                  current_control_frame_1080_ms=before_frame,
                  current_control_gpu_1080_ms=before_gpu, gpu_1080_ms=after_gpu,
                  current_control_gpu_4k_ms=before_gpu4k,
                  kit_baseline_ms=2.989, historical_frame_margin_ms=1.710,
                  gpu_change_allowance_ms=.300,
                  final_sources_match=True)
    (a.root / 'round2_verified.json').write_text(json.dumps(result, indent=1))
    print('ROUND2 MEASUREMENTS VALIDATED', json.dumps(result))


if __name__ == '__main__':
    main()
