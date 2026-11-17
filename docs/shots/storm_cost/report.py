"""Rebuild the measured tables from retained GPU output, never typed timings."""
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from statistics import median

root = Path(__file__).resolve().parent
def read(name):
    return json.loads((root / name).read_text())
def storm(tag, tier, resolution):
    return [r for r in read(f'{tag}_storm.json') if r['pass'] == 2 and r['tier'] == tier and r['resolution'] == resolution]

if '--profile' in sys.argv:
    rows = [r for r in read('before_diagnostic.json') if r['pass'] == 2]
    lines = ['# Issue 982: attribution before production edits', '',
             f'Recorded {datetime.now(timezone.utc).isoformat()}. world_living.gd SHA256: `{rows[0]["living_sha256"]}`.', '',
             'Solo RTX 5080, seed 4103, 31 storm and 28 nebula hexes, PR 976 c170 view, live time, 4K. One diagnostic session, two passes per ablation; retain pass 2 after 180 warm frames, at least 720 measured frames and 8 seconds. These are independent full-scene removals; their differences are not additive.', '',
             '| Tier | Variant | GPU median ms | Change from full ms |', '|---|---|---:|---:|']
    for row in rows:
        full = next(r['gpu_ms']['median'] for r in rows if r['tier'] == row['tier'] and r['variant'] == 'full')
        lines.append(f"| {row['tier']} | {row['variant']} | {row['gpu_ms']['median']:.3f} | {row['gpu_ms']['median']-full:+.3f} |")
    lines += ['', 'Actual live tree, before ablations:', '', *[f"- {r['tier']}: {json.dumps(r['lights'], sort_keys=True)}" for r in rows if r['variant'] == 'full'], '',
              'cards_off hides only the gas MultiMeshes; storm_cards_off and nebula_cards_off isolate each gas family. fog_off hides only FogVolumes, retaining the tiny background haze. fog_64 changes the fog grid from 128x128 to 64x128. lights_off hides the four direct bolt lights and their fog injection while retaining bolt meshes and shader-driven cloud flashes.', '',
              'Source cause to test: both card shaders evaluate multiple five-octave world-space noise fields before computing their thin height-layer support. Cards expand to three times their original width, shading large masked or empty regions repeatedly. Low has more cards than Max because it replaces fog with three puffs per hex. The fix will reject provably empty support before noise and reduce the dim low-tier bottom puffs. The Max fog grid, volumes and bolt lights will stay as measured.', '']
    (root / 'profile_before.md').write_text('\n'.join(lines))
    print('\n'.join(lines))
    raise SystemExit(0)

lines = ['# Issue 982: before and after frame times', '',
         'RTX 5080, Godot 4.7.2 Forward+, vsync off, solo watchdog claims. Three sessions per source. Storm rows use the real seed-4103 terrain generator with its nebula condition: 31 storm and 28 nebula hexes, c170 beta 0.98, idle battle, HUD hidden. Each session warms 180 frames before each of two passes, measures at least 720 frames and 8 seconds, and retains pass 2. 4K draws 3840x2160 through 2x 3D scaling in a 1920x1080 viewport. Time and weather stay live.', '',
         '| Storm tier | Resolution | Before GPU median ms | After GPU median ms | After frame median ms | After GPU session medians ms |',
         '|---|---|---:|---:|---:|---|']
checks = {}
for tier in ['max', 'low']:
    for resolution in ['1080p', '4K']:
        before = storm('before', tier, resolution)
        after = storm('after', tier, resolution)
        assert len(before) == len(after) == 3
        values = [r['gpu_ms']['median'] for r in after]
        lines.append(f"| {tier} | {resolution} | {median(r['gpu_ms']['median'] for r in before):.3f} | {median(values):.3f} | {median(r['frame_ms']['median'] for r in after):.3f} | {', '.join(f'{v:.3f}' for v in values)} |")
checks['storm_max_4K_under_12_5_each_session'] = all(r['gpu_ms']['median'] < 12.5 for r in storm('after', 'max', '4K'))
for resolution in ['1080p', '4K']:
    checks[f'low_cheaper_{resolution}_each_session'] = all(lo['gpu_ms']['median'] < hi['gpu_ms']['median'] for lo, hi in zip(storm('after', 'low', resolution), storm('after', 'max', resolution)))
lines += ['', 'All table values are medians of three session medians. Raw JSON retains both storm passes, p95, maxima, render CPU time, live tree counts, source SHA256 and adapter identity.', '',
          '## Scene 207', '',
          'Unmodified production gate, 20 ships across six factions, real volleys and HUD, max quality and MSAA 4x. Each batch has two launches, each with three sessions and alternating mode order; retain the second launch. Each mode settles 2.5 seconds, warms 180 frames and measures 720. The 1080p gate uses frame median; the 4K gate uses GPU median, taking the median across sessions. The after values below are the confirmation batch run after the standing suite ended. The initial after batch and its CPU timing exception are preserved in validation.md.', '',
          '| Mode | Before frame median ms | After frame median ms | Before GPU median ms | After GPU median ms | After binding session medians ms |',
          '|---|---:|---:|---:|---:|---|']
for mode in ['base', 'res_2160']:
    before = read('before_gate_keep.json')['modes'][mode]
    after = read('after_gate_keep.json')['modes'][mode]
    key = 'frame_median' if mode == 'base' else 'gpu_median'
    values = [r[key] for r in after]
    lines.append(f"| {mode} | {median(r['frame_median'] for r in before):.3f} | {median(r['frame_median'] for r in after):.3f} | {median(r['gpu_median'] for r in before):.3f} | {median(r['gpu_median'] for r in after):.3f} | {', '.join(f'{v:.3f}' for v in values)} |")
    checks[f'gate_{mode}_median_of_sessions_under_12_5'] = median(values) < 12.5
lines += ['', '## Evidence', '',
          '[Before attribution](profile_before.md), [before storm](before_storm.json), [after storm](after_storm.json), [before gate](before_gate_keep.json), [after gate](after_gate_keep.json), [checks and timing exception](validation.md). The discarded gate launches are kept as before_gate_warm.json and after_gate_warm.json. GPU state snapshots are before_gpu.csv, after_gpu.csv and after_gate_repeat_gpu.csv.', '',
          'The approved PR 717 storm shader is unchanged in ion_storm.gd. The max route retains the same card transforms, density, fog, noise, colors, heights, bolt geometry, timing and four lights, including two fog injectors. Early support rejection avoids noise only where the original density was zero. It hoists the accepted shader declarations, keeping layer dimensions and falloffs in one place. Low drops the dim bottom puffs first, keeping the middle cores, upper puffs, broad veils and color ramps. The live low tree falls from 196 gas cards to 137; max stays at 137.', '',
          'Fixed-pose native 4K captures use presentation time 0.08, with calm and peak-strike pairs. Comparison sheets are 1280x720, with matching native-pixel detail crops, code names and revision/stage provenance. Whole-scene pixel equality is not claimed: distant rock spin and small idle effects can differ between launches.', '']
for radius in [170, 60]:
    for state in ['calm', 'bolt']:
        name = f'STORM982_c{radius}_{state}.jpg'
        lines.append(f'![{name}](../issue-982-codex/{name})')
for radius in [170, 60]:
    name = f'STORM982_c{radius}_quality.jpg'
    lines.append(f'![{name}](../issue-982-codex/{name})')
lines += ['', 'Reproduce on the PC with the installed gen cache and matching ship textures, after a successful headless import: run `docs/shots/storm_cost/run.bat before` on the original source and `run.bat after` on the changed source. The batch uses tmo.bat and solo GPU claims for every invocation, respects gpu_go.txt, stops on command failure and keeps logs in TEMP. measure.gd is derived from the PR 976 capture adapter. compose.py preserves input provenance and builds the sheets; report.py rebuilds these tables from raw results. [Approved-source hashes](approved_source.json) verify the baseline gas and lightning against PR 717 commit ee2e21d9.', '']
lines += ['', 'Checks derived from the retained data:', '']
lines += [f"- {'PASS' if value else 'FAIL'}: {name}" for name, value in checks.items()]
(root / 'frame_times.md').write_text('\n'.join(lines) + '\n')
(root / 'summary.json').write_text(json.dumps(checks, indent=2) + '\n')
print(json.dumps(checks, indent=2))
if not all(checks.values()):
    raise SystemExit(1)
