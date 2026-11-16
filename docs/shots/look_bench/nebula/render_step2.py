"""Build R270 route A evidence from real captures. Keep source pixels in shared shots.

python render_step2.py --source PATH_TO_SHARED_SHOTS
The first timing invocation is discarded; only step2_*_keep enters the report.
"""
import argparse
import hashlib
import json
import statistics
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
BG = '#10141c'
INK = '#e5e9f0'


def text(sheet, xy, value, size=18):
    ImageDraw.Draw(sheet).text(xy, value, fill=INK,
                               font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size))


def fit(sheet, path, box):
    pic = Image.open(path).convert('RGB')
    pic.thumbnail(box[2:], Image.Resampling.LANCZOS)
    sheet.paste(pic, (box[0] + (box[2] - pic.width) // 2,
                     box[1] + (box[3] - pic.height) // 2))


def save(sheet, name, source):
    assert sheet.height <= 720
    for root in (HERE, source):
        sheet.save(root / name, quality=92)


def capture(source, case, tier='max'):
    return source / f'step2_{case}_{tier}_keep_captures'


def contrast(source):
    rows = []
    for case in ('nebula', 'storm'):
        folder = capture(source, case)
        poses = {r['file']: r for r in json.loads((folder / 'capture_poses.json').read_text())}
        for cam in (170, 60, 26):
            stem = f'{case}_fog_c{cam}_4k'
            names = [stem + '.png', stem + '_clear.png', stem + '_mask.png']
            a, b = (poses[n] for n in names[:2])
            assert a['target'] == b['target'] and b['gas_nodes_hidden'] > 0
            assert a['viewport'] == b['viewport'] == [3840, 2160]
            assert all(abs(v - wanted) < .05 for v, wanted in zip(a['subject_screen'], (1920, 1080)))
            gas, clear = [np.asarray(Image.open(folder / n).convert('RGB'), dtype=float) / 255 for n in names[:2]]
            raw_mask = Image.open(folder / names[2]).convert('L').point(lambda v: 255 if v > 240 else 0)
            mask = np.asarray(raw_mask.filter(ImageFilter.MinFilter(3))) > 0
            assert int(mask.sum()) > 500
            lum = np.array([.2126, .7152, .0722])
            x, y = (pic @ lum for pic in (gas, clear))
            span = lambda z: float(np.percentile(z[mask], 95) - np.percentile(z[mask], 5))
            # Adjacent hull pixels measure preserved plating edges, excluding the silhouette.
            edge_mask = mask[:, 1:] & mask[:, :-1]
            edge = lambda z: float(np.mean(np.abs(np.diff(z, axis=1))[edge_mask]))
            row = {'map': case, 'camera': cam, 'hull_pixels': int(mask.sum()),
                   'srgb_luma_contrast_ratio': span(x) / span(y),
                   'srgb_edge_contrast_ratio': edge(x) / edge(y),
                   'mean_abs_rgb_delta_255': float(np.abs(gas - clear)[mask].mean() * 255),
                   'mean_rgb_delta_255': ((gas - clear)[mask].mean(axis=0) * 255).tolist(),
                   'files': {n: hashlib.sha256((folder / n).read_bytes()).hexdigest() for n in names}}
            rows.append(row)
    return rows


def timings(source):
    rows = []
    for case in ('nebula', 'storm'):
        for tier in ('max', 'high', 'low'):
            path = source / f'step2_{case}_{tier}_keep' / 'scene_gate.json'
            raw = json.loads(path.read_text())
            base, four = (raw['modes'][m] for m in ('base', 'res_2160'))
            assert len(base) == len(four) == 3
            assert raw['warmup_frames'] == 120 and raw['measured_frames'] == 720
            assert raw['renderer'] == 'forward_plus' and raw['route'] == 'fog'
            assert raw['terrain_tier'] == tier
            assert all(r['terrain_rendering']['fog_enabled'] == (tier == 'max') for r in base + four)
            assert all((r['terrain_rendering']['volumes'] > 0) == (tier == 'max') for r in base + four)
            assert all(r['scaling_3d'] == 2 and r['gpu_median'] > 0 for r in four)
            rows.append({'map': case, 'tier': tier, 'frame_1080p_ms': statistics.median(r['frame_median'] for r in base),
                         'gpu_4k_ms': statistics.median(r['gpu_median'] for r in four),
                         'frame_sessions': [r['frame_median'] for r in base],
                         'gpu_sessions': [r['gpu_median'] for r in four],
                         'draw_calls': statistics.median(r['dc_vis_median'] for r in base),
                         'visible_primitives': statistics.median(r['prim_vis_median'] for r in base),
                         'vram_mb': statistics.median(r['vram_mb'] for r in four),
                         'camera': base[0]['camera'], 'patches': base[0]['patches'],
                         'adapter': raw['adapter'], 'source': str(path),
                         'terrain_rendering': base[0]['terrain_rendering'],
                         'source_sha256': raw['source_sha256'],
                         'adapter_sha256': raw['adapter_sha256'], 'gate_sha256': raw['probe_sha256']})
    for row in rows:
        row['gate_pass'] = row['frame_1080p_ms'] <= 12.5 and row['gpu_4k_ms'] <= 12.5
    return rows


def sheets(source, rows):
    for case in ('nebula', 'storm'):
        folder = capture(source, case)
        for cam in (170, 60, 26):
            sheet = Image.new('RGB', (1280, 720), BG)
            text(sheet, (16, 10), f'N368A | {case.upper()} | CAMERA {cam} | R270 FOG', 24)
            text(sheet, (16, 50), 'STEP 1 TODAY')
            text(sheet, (650, 50), 'STEP 2 DEFAULT MAX')
            fit(sheet, source / f'{case}_today_captures' / f'{case}_today_c{cam}.png', (0, 80, 634, 357))
            fit(sheet, folder / f'{case}_fog_c{cam}.png', (646, 80, 634, 357))
            text(sheet, (16, 445), 'Native 4K hull pixels: gas on / same pose with gas hidden', 19)
            for idx, suffix in enumerate(('', '_clear')):
                im = Image.open(folder / f'{case}_fog_c{cam}_4k{suffix}.png').convert('RGB')
                # Native pixels, with no enlargement, sharpening or colour adjustment.
                sheet.paste(im.crop((1632, 982, 2208, 1178)), (18 + idx * 640, 480))
                text(sheet, (18 + idx * 640, 678), 'INSIDE GAS' if idx == 0 else 'GAS HIDDEN', 17)
            save(sheet, f'N368A_{case}_c{cam}.jpg', source)
        sheet = Image.new('RGB', (1280, 720), BG)
        text(sheet, (16, 10), f'N368A | {case.upper()} | QUALITY TIERS | CAMERA 170', 24)
        for idx, tier in enumerate(('max', 'high', 'low')):
            x = idx * 426
            text(sheet, (x + 12, 55), tier.upper() + (' | VOLUME' if tier == 'max' else ' | CARDS'))
            fit(sheet, capture(source, case, tier) / f'{case}_fog_c170.png', (x, 90, 422, 300))
            im = Image.open(capture(source, case, tier) / f'{case}_fog_c170.png')
            sheet.paste(im.crop((750, 440, 1170, 690)), (x, 410))
            row = next(r for r in rows if r['map'] == case and r['tier'] == tier)
            text(sheet, (x + 12, 675), f'4K GPU {row["gpu_4k_ms"]:.3f} ms / 12.5', 19)
        save(sheet, f'N368A_{case}_tiers.jpg', source)
    sheet = Image.new('RGB', (1280, 720), BG)
    text(sheet, (16, 10), 'N368A | STORM LIGHT SCATTER | SAME GAS, RIBBONS HIDDEN', 23)
    for idx, state in enumerate(('off', 'on')):
        text(sheet, (16 + 640 * idx, 55), 'VOLUME LIGHT ' + state.upper())
        fit(sheet, capture(source, 'storm') / f'storm_fog_c60_light_{state}.png', (640 * idx, 90, 638, 500))
    text(sheet, (16, 650), 'Actual fog light injection, fixed clock and pose. Temporal reprojection off.', 20)
    save(sheet, 'N368A_storm_light.jpg', source)
    sheet = Image.new('RGB', (1280, 720), BG)
    text(sheet, (16, 10), 'N368A | TOP-DOWN BOARD | NEBULA / ION STORM', 24)
    for idx, case in enumerate(('nebula', 'storm')):
        fit(sheet, capture(source, case) / f'{case}_fog_top.png', (640 * idx, 55, 638, 600))
    save(sheet, 'N368A_topdown.jpg', source)
    metadata = json.loads((capture(source, 'nebula') / 'scale_metadata.json').read_text())
    for ship in metadata['ships']:
        cls = ship['class'].lower().replace(' ', '_')
        for cam in (170, 60):
            sheet = Image.new('RGB', (1280, 720), BG)
            text(sheet, (16, 8), f'N368A | {ship["code"]} | {ship["class"].upper()} | C{cam} | {ship["length"]:.2f} UNITS', 22)
            for idx, case in enumerate(('nebula', 'storm')):
                x = idx * 640
                text(sheet, (x + 12, 45), case.upper(), 18)
                path = capture(source, case) / f'scale_{case}_fog_{cls}_c{cam}.png'
                fit(sheet, path, (x, 75, 638, 359))
                sheet.paste(Image.open(path).crop((648, 432, 1272, 648)), (x + 8, 448))
            text(sheet, (16, 680), 'Full view above. Native 1080p crop below. Hex corner diameter 20. Presentation placement only.', 17)
            save(sheet, f'N368A_scale_{cls}_c{cam}.jpg', source)


def light_difference(source):
    folder = capture(source, 'storm')
    off, on = [np.asarray(Image.open(folder / f'storm_fog_c60_light_{state}.png').convert('RGB'), dtype=float)
               for state in ('off', 'on')]
    difference = np.max(np.abs(on - off), axis=2)
    return {'ribbons_hidden_in_both': True, 'pixels_changed_by_more_than_2': int((difference > 2).sum()),
            'max_channel_delta_255': float(difference.max()), 'mean_abs_rgb_delta_255': float(np.abs(on - off).mean())}


def report(source, data):
    baseline = {r['map']: r for r in json.loads((HERE / 'measurements.json').read_text()) if r['route'] == 'today'}
    lines = [
        '# Issue 368: route A built, awaiting Ryan\'s look approval', '',
        'Refs #368. Continued the merged partial after Ryan picked A, fog (R270). Max now uses baked-noise FogVolumes with reduced edge cards. High and low use cards. The 83-unit soft footprint and 38.5-unit height pass the shared scale check; the default gas rows have left KNOWN. No route B work was done in this round.', '',
        'Start with [nebula at camera 170](N368A_nebula_c170.jpg) and [storm at camera 170](N368A_storm_c170.jpg). Each sheet puts step 1\'s Today beside the built route, with native 4K gas-on and gas-hidden hull crops below. The other views are [nebula 60](N368A_nebula_c60.jpg), [nebula 26](N368A_nebula_c26.jpg), [storm 60](N368A_storm_c60.jpg), [storm 26](N368A_storm_c26.jpg), [top-down](N368A_topdown.jpg), and the unchanged [campaign sector context](N368_campaign.jpg). All new sheets are 1280 by 720.', '',
        'The shared evidence root is `' + str(source).replace('\\', '/') + '/`. Every N368A sheet and this report are copied there for the Board. Native captures and poses are in `step2_<map>_<tier>_keep_captures`; raw timing sessions are in `step2_<map>_<tier>_keep/scene_gate.json`. The first invocation for each map and tier is discarded in the matching `warm` folder.', '',
        'GPU: Ryan\'s RTX 5080, Godot 4.7.2 Forward+, vsync off. Each kept row is the median of three session medians, 120 warmup frames and 720 measured frames per mode. Session 2 reverses the mode order. The engagement camera is the real scene gate camera, not the presentation camera. 4K is the gate\'s `res_2160` mode, 3D at 3840 by 2160 in a 1080p window. Stills use a native 3840 by 2160 window. GPU jobs ran one at a time after checking the Board go file.', '',
        '| Map | Tier | 1080p frame ms | 4K GPU ms | Gate 12.5 ms |',
        '|---|---|---:|---:|---|',
    ]
    for row in data['timings']:
        lines.append(f'| {row["map"]} | {row["tier"]} | {row["frame_1080p_ms"]:.3f} | {row["gpu_4k_ms"]:.3f} | {"PASS" if row["gate_pass"] else "OVER"} |')
    lines += ['', 'Max-tier deltas against the saved step 1 Today reference (historical, not a paired cost isolation on this revision):']
    for row in data['timings']:
        if row['tier'] == 'max':
            old = baseline[row['map']]
            lines.append(f'- {row["map"]}: 1080p frame {row["frame_1080p_ms"] - old["frame_1080p_ms"]:+.3f} ms; 4K GPU {row["gpu_4k_ms"] - old["gpu_4k_ms"]:+.3f} ms.')
    lines += [
        '', 'The [measurement file](step2_measurements.json) retains every session, actual fog/card counts, draw calls, visible primitives, VRAM, camera, adapter and source hashes. Draw calls and triangles are reported, not capped. The real generated multi-patch fixtures and fleet are unchanged: nebula seed 4207 has six nebula hexes in three patches; storm has 23 storm hexes in three patches and four nebula hexes. The gate uses live volleys. Before/after views can differ in incidental debris placement because each route consumes the living-terrain RNG differently. The gas/clear hull pair instead uses one fixed scene. The raw logs retain the existing late `exterior_alpha` compile notice (issue 376); this report measures the frame and GPU medians, not a claim that compilation stalls are gone.', '',
        'R82 hull check: hull materials skip volumetric fog, including shared damage shaders, and foreground cards reject opaque hull pixels. Paired stills hold pose, direct lights and debris fixed while hiding only gas. A separate render of the real hull triangles supplies the pixel mask; the measurement erodes its silhouette by one pixel. sRGB luma contrast is the hull\'s 95th minus 5th percentile; edge contrast is the mean adjacent-pixel sRGB luma difference inside that mask. Ratios compare inside gas with the same hull outside gas. No enlargement, sharpening or recolouring enters the measurement.', '',
        '| Map | Camera | sRGB luma contrast retained | Edge contrast retained | Mean RGB difference / 255 |',
        '|---|---:|---:|---:|---:|',
    ]
    for row in data['hull_contrast']:
        lines.append(f'| {row["map"]} | {row["camera"]} | {row["srgb_luma_contrast_ratio"] * 100:.2f}% | {row["srgb_edge_contrast_ratio"] * 100:.2f}% | {row["mean_abs_rgb_delta_255"]:.3f} |')
    light = data['storm_light']
    lines += [
        '', 'The cruiser no longer has the prototype\'s violet wash. Faction ramp-end tint remains clamped to 0.25. Some background glow still reaches hull pixels through postprocessing; the measured differences above expose that remaining contribution.', '',
        f'The [storm-light pair](N368A_storm_light.jpg) hides ribbons and suppresses card flashes in both frames, with identical direct light. Only fog scattering toggles: {light["pixels_changed_by_more_than_2"]:,} pixels change by more than 2/255, with a peak channel difference of {light["max_channel_delta_255"]:.0f}/255. Two bolt lights can enter max-tier fog. The 128-cubed froxel grid has temporal reprojection off so short flashes leave no history trail.', '',
        '[Nebula tier sheet](N368A_nebula_tiers.jpg) and [storm tier sheet](N368A_storm_tiers.jpg) show the fallbacks. The JSON asserts that actual max scenes contain volumes with fog enabled, and high/low scenes contain no volumes with fog disabled. The camera near plane uses 15, 5 and 1 unit zoom bands; fog length follows the camera to keep distant clouds in range.', '',
        'Class scale, with the asset code printed on each sheet:', '',
        '| Class | Camera 170 | Camera 60 |', '|---|---|---|',
    ]
    metadata = json.loads((capture(source, 'nebula') / 'scale_metadata.json').read_text())
    for ship in metadata['ships']:
        cls = ship['class'].lower().replace(' ', '_')
        lines.append(f'| {ship["class"]} ({ship["code"]}) | [170](N368A_scale_{cls}_c170.jpg) | [60](N368A_scale_{cls}_c60.jpg) |')
    lines += [
        '', 'These use real scenario-generated units, with presentation placement only. Transport is the built O2_37 objective prop at the hull table length. The existing N368_context class sheets below retain the unchanged asteroid, debris and wreck sizes; fresh context captures are also retained in the new max capture folders. Station and asteroid scale work stays with issues 373 and 369.', '',
        'PC assets: copied gen, built ship files and the existing import cache from `C:/Users/rcbai/Downloads/voidsworn_test/build/godot` before import; all 252 manifest files match. Captures stop on placeholder hulls. No ship assets, gen files, UID files or rewritten import metadata are delivered. The existing 128-cubed R8 noise bake is unchanged, SHA256 `92c69b3254aa015cd577bced12f694bfa764e4b8d3d5e2b2a332628f11dc5691`; its source is `godot/world/nebula_noise_bake.gd`.', '',
        'Checks: required Node standing suite exits 0 (51 PASS, two KNOWN baseline rows: seven findings and 12 oracle differences). Scale check exits 0 (53 objects, four unrelated KNOWN rows). Both headless map dry runs exit 0 and prove the 83-unit footprint, 38.5-unit height and max/high/low route split. All retained GPU invocations exit 0 without shader errors or placeholders. Evidence logs and the CPU dry-run JSON are in the shared folder. Import completed; its sandbox-only certificate/settings-write notices did not prevent import or the later elevated GPU runs.', '',
        'R129: world build callers and rules APIs are unchanged. No saves, JS rules, oracle copies or exported tables changed, so no oracle refresh was needed. Existing Graphics choices remain, with fog at max and cards at high/low. GitHub runs standing checks, the em-dash scan, rules parity and Godot game checks; the manual GPU bench is outside test folders.', '',
        'Reproduction for workers: run `res://world/nebula_bench.tscn` with Forward+, `--go-file <PC gpu_go.txt> --map-case nebula --terrain-tier max --sessions 3 --warmup 120 --frames 720 --modes base,res_2160 --out <folder>`, then repeat for storm and the other tiers. Leave VS_NEBULA_ROUTE unset for the shipped default. Discard the first invocation and keep the second. For stills run `res://world/nebula_capture.tscn` with `--captures --four-k --scale-captures`; use `--captures` alone for high/low. Compose with `python docs/shots/look_bench/nebula/render_step2.py --source <shared shots root>`. The go file must start with `GPU cleared`; headless timing is refused.', '',
        'Stopped for Ryan\'s final look approval. The outside check on issue 256 is still required before merge. No hand-play recording or route B rebuild was made; acceptance here uses the requested still sheets and live scene-gate timings. No commit or push was made by the agent.', '',
        '---', '', '## Historical step 1 evidence', '',
        'The following comparison records the prior route pick. Its default/status statements and route B commands apply to that earlier revision only; the live route is A as documented above.', '',
    ]
    old = (HERE / 'README.md').read_text()
    old = '# Issue 368: route comparison' + old.split('# Issue 368: route comparison', 1)[1]
    result = '\n'.join(lines) + old
    for root in (HERE, source):
        (root / 'README.md').write_text(result, newline='\n')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    args = parser.parse_args()
    data = {'timings': timings(args.source), 'hull_contrast': contrast(args.source),
            'storm_light': light_difference(args.source)}
    sheets(args.source, data['timings'])
    for root in (HERE, args.source):
        (root / 'step2_measurements.json').write_text(json.dumps(data, indent=2) + '\n')
    report(args.source, data)
    print(json.dumps(data, indent=2))


if __name__ == '__main__':
    main()
