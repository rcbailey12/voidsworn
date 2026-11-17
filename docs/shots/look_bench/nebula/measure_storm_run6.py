"""Measure the run 6 captures and retained scene gate sessions. No image edits."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import statistics
import subprocess
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
from picture_provenance import Review


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', required=True, type=Path)
    args = parser.parse_args()
    deliver = Path(__file__).parent
    normal = json.loads((args.source / 'after_keep/lightning_metadata.json').read_text())
    reduced = json.loads((args.source / 'reduced_keep/lightning_metadata.json').read_text())
    old = subprocess.check_output(['git', '-C', str(ROOT), 'show', '5ca3dc45:godot/world/world_living.gd']).decode().replace('\r\n', '\n')
    new = (ROOT / 'godot/world/world_living.gd').read_text()
    preservation = {}
    for key in ['GAS_SHADER', 'FOG_SHADER']:
        pattern = 'const ' + key + ' := """(.*?)"""'
        preservation[key] = re.search(pattern, old, re.S).group(1) == re.search(pattern, new, re.S).group(1)
    for name in ['_gas', '_fog_patch', '_mask']:
        pattern = r'func ' + name + r'\(.*?(?=\nfunc |\nstatic func |\Z)'
        preservation[name] = re.search(pattern, old, re.S).group() == re.search(pattern, new, re.S).group()
    assert all(preservation.values()), 'Accepted nebula source changed'
    source_hashes = {name: hashlib.sha256((ROOT / 'godot/world' / file).read_bytes()).hexdigest()
                     for name, file in [('world_sha256', 'world_living.gd'), ('ion_sha256', 'ion_storm.gd')]}
    assert all(normal[k] == reduced[k] == v for k, v in source_hashes.items()), 'Capture source differs from final source'
    assert normal['terrain_sha256'] == reduced['terrain_sha256']
    assert normal['glow_enabled'] and reduced['reduced']
    normal_peak = max(b['radiance'] or 0 for row in normal['samples'] for b in row['bolts'])
    reduced_peak = max(b['radiance'] or 0 for row in reduced['samples'] for b in row['bolts'])
    assert 0 < reduced_peak <= 0.22 < normal_peak
    assert [b['pos'] for b in normal['samples'][0]['bolts']] == [b['pos'] for b in reduced['samples'][0]['bolts']]
    assert all(2 <= n <= 4 for n in normal['burst_sizes'])
    forks = [b['forks'] for b in normal['samples'][0]['bolts']]
    assert all(2 <= n <= 4 for n in forks)
    active_counts = [sum((b['radiance'] or 0) > 0.04 for b in row['bolts']) for row in normal['samples']]
    assert sum(n >= 2 for n in active_counts) >= 4
    assert any((b['radiance'] or 0) > 0.04 and (b['branch_radiance'] or 0) == 0 for row in normal['samples'] for b in row['bolts'])
    review = Review('installed in game')
    rows = []
    poses = {r['file']: r for r in json.loads((args.source / 'after_keep/capture_poses.json').read_text())}
    for kind in ['neb', 'storm']:
        for radius in [170, 60]:
            stem = args.source / 'after_keep' / f'{kind}_c{radius}_peak_4k'
            gas = np.asarray(review.open(str(stem) + '.png').convert('RGB')).astype(float)
            clear = np.asarray(review.open(str(stem) + '_clear.png').convert('RGB')).astype(float)
            assert gas.shape == clear.shape == (2160, 3840, 3), 'Native 4K images required'
            pose, clear_pose = [poses[f'{kind}_c{radius}_peak_4k{suffix}.png'] for suffix in ['', '_clear']]
            assert pose['radius'] == clear_pose['radius'] == radius and pose['target'] == clear_pose['target']
            assert pose['viewport'] == clear_pose['viewport'] == [3840, 2160] and clear_pose['gas_nodes_hidden'] > 0
            mask_image = review.open(str(stem) + '_mask.png').convert('L')
            mask = np.asarray(mask_image.filter(ImageFilter.MinFilter(5))) > 250
            a, b = gas[mask] @ [0.2126, 0.7152, 0.0722], clear[mask] @ [0.2126, 0.7152, 0.0722]
            row = {'kind': kind, 'camera': radius, 'hull_pixels': int(mask.sum()),
                   'contrast_retained': float(a.std() / b.std()), 'mean_luma_delta_255': float((a-b).mean()),
                   'p95_rgb_difference_255': float(np.percentile(np.abs(gas[mask]-clear[mask]), 95))}
            if kind == 'storm':
                mask_1080 = np.asarray(mask_image.resize((1920, 1080), Image.Resampling.NEAREST).filter(ImageFilter.MinFilter(5))) > 250
                calm = np.asarray(review.open(args.source / 'after_keep' / f'storm_c{radius}_strike_00.png').convert('RGB')).astype(float)
                peak = np.asarray(review.open(args.source / 'after_keep' / f'storm_c{radius}_peak.png').convert('RGB')).astype(float)
                delta = (peak - calm)[mask_1080] @ [0.2126, 0.7152, 0.0722]
                row['strike_hull_mean_luma_lift_255'] = float(delta.mean())
                row['strike_hull_p95_abs_luma_delta_255'] = float(np.percentile(np.abs(delta), 95))
                change = (peak - calm) @ [0.2126, 0.7152, 0.0722]
                row['scene_pixels_lifted_over_40_luma'] = int((change > 40).sum())
                core = (peak.min(axis=2) > 210) & ((peak.max(axis=2) - peak.min(axis=2)) < 35) & (change > 30)
                core_image = Image.fromarray(core.astype('uint8') * 255)
                halo = (np.asarray(core_image.filter(ImageFilter.MaxFilter(17))) > 0) & (np.asarray(core_image.filter(ImageFilter.MaxFilter(3))) == 0) & (change > 8)
                row['halo_pixels_cyan'] = int((halo & (peak[:,:,2] > peak[:,:,0]+4) & (peak[:,:,1] > peak[:,:,0]+3)).sum())
                row['halo_pixels_violet'] = int((halo & (peak[:,:,2] > peak[:,:,1]+4) & (peak[:,:,0] > peak[:,:,1]+3)).sum())
                row['halo_pixels_total'] = int(halo.sum())
                print('HALO_DIAGNOSTIC', row)
                assert row['halo_pixels_cyan'] > 0 and row['halo_pixels_violet'] > 0, 'Color halo missing from rendered pixels'
            rows.append(row)
    report = {'sources': source_hashes, 'nebula_components_identical_to_run5': preservation,
              'noise_sha256': hashlib.sha256((ROOT / 'godot/world/nebula_noise.res').read_bytes()).hexdigest(),
              'patch_strike_counts': normal['burst_sizes'], 'fork_counts': forks, 'active_strip_strikes': active_counts,
              'normal_peak_uniform': normal_peak, 'reduced_peak_uniform': reduced_peak,
              'same_strike_positions_in_reduced_mode': True, 'glow_intensity': normal['glow_intensity'],
              'readability': rows, 'gate': [], 'fallback_captures': []}
    for tier in ['high', 'low']:
        path = args.source / f'{tier}_keep/lightning_metadata.json'
        if not path.exists(): continue
        data = json.loads(path.read_text())
        assert data['tier'] == tier and data['glow_enabled']
        assert all(data[k] == v for k, v in source_hashes.items())
        report['fallback_captures'].append({'tier': tier, 'source_hashes_match': True, 'glow_enabled': True,
                                           'metadata_path': str(path)})
    for kind in ['nebula', 'storm']:
        path = args.source / f'gate_{kind}_keep/scene_gate.json'
        if not path.exists(): continue
        data = json.loads(path.read_text())
        assert data['adapter_sha256'] == hashlib.sha256((ROOT / 'godot/world/nebula_bench.gd').read_bytes()).hexdigest()
        assert data['probe_sha256'] == hashlib.sha256((ROOT / 'godot/bench/scene_gate.gd').read_bytes()).hexdigest()
        assert data['sessions'] == 3 and data['warmup_frames'] == 120 and data['measured_frames'] == 720
        assert data['renderer'] == 'forward_plus'
        assert all(r['scaling_3d'] == 2 and r['viewport'] == [1920, 1080] for r in data['modes']['res_2160'])
        summary = {'map': kind}
        for mode, key in [('base', 'frame_median'), ('res_2160', 'gpu_median')]:
            readings = [row[key] for row in data['modes'][mode]]
            assert len(readings) == 3 and all(value <= 12.5 for value in readings), 'Scene gate failed'
            summary[mode] = {'median_ms': statistics.median(readings), 'sessions_ms': readings}
        report['gate'].append({'map': kind, 'path': str(path), 'summary': summary, 'report': data})
    (deliver / 'run6_measurements.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'gate'}, indent=2))


if __name__ == '__main__':
    main()
