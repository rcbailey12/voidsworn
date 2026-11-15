# Issue 368: step 1 preparation, waiting for a GPU window

Refs #368. This is not a finished route comparison or a request to approve a look.
The resumed CPU run on Nov 15 found the Board's go file explicitly revoked: its first line starts with
"GPU not cleared." CODEX_TASK.md requires a first line starting with "GPU cleared" at run start before any GPU job.
No captures, frame timings, GPU timings, recommendation or picked route are claimed.
Step 2 remains behind Ryan's route pick after the measured sheet.

## Files and defaults

- `godot/world/world_living.gd`: two opt-in candidates. `VS_NEBULA_ROUTE=fog` adds one baked-noise FogVolume per
  connected patch at max quality, a reduced card layer, and two fog-active storm lights. High and low use cards.
  `VS_NEBULA_ROUTE=cards` increases card coverage and density using the existing world-space noise shader.
  Both expand the footprint past the marked hex and stretch the height bands. With the variable unset, today's route stays.
- `godot/world/nebula_noise_bake.gd`, `nebula_noise_data.gd`, `nebula_noise.res`: deterministic, CPU-backed 128-cubed R8
  volume. The fog route uploads the saved slices once per living-terrain instance. No downloads or paid assets.
- `godot/render/camera_rig.gd`: candidate near planes of 15, 5 and 1 at zoom bands 100+, 45+ and below 45.
- `godot/render/backdrop.gd`, `godot/scenes/battle/battle.gd`: candidate fog setup and max-tier 128 by 128 froxel grid.
  The live battle uses world.gd rather than backdrop.gd, so battle.gd explicitly enables candidate fog.
- `godot/world/nebula_bench.gd`, `nebula_bench.tscn`: adapter over the existing gate's timing, effects and placeholder guard.
  Uses the real battle scenario and terrain generator. Headless mode refuses timing runs.

The fog length in the gate grows to camera radius plus 200, at least 250. The engagement camera can exceed 250 units:
timing a volume outside the fog integration range would give misleadingly cheap results.

## First CPU run checks

- Godot 4.7.2 headless CPU bake, repeated: byte-identical SHA256
  `92c69b3254aa015cd577bced12f694bfa764e4b8d3d5e2b2a332628f11dc5691`.
  The saved resource is 1,644,091 bytes; its 128 R8 slices contain 2,097,152 bytes.
- Headless dry runs of both generated maps at seed 4207: pass. Nebula case: six nebula hexes in three patches
  (1, 4, 1), no storm hexes. Storm case: 23 storm hexes in three patches (13, 5, 5), plus four nebula hexes.
- Each dry run constructs the real gas builder for today, fog and cards at max, high and low. Fog volumes occur only
  for fog/max, one per patch, at height 38.5. The mask at 11 units from an isolated hex center has alpha 0 today
  and 0.27792 for both candidates, proving an edge beyond the hex's 8.6603-unit inradius.
  Storm max: today 121 cards, A 52 cards plus three volumes, B 282 cards. These are counts, not performance evidence.
- Headless timing without `--dry-run` refuses with exit 2, rather than writing dummy GPU numbers.
- Node 22 standing suite: fails only `doc_check_tests`, which names missing `docs/playbooks/scale.md` and
  `godot/render/test/scale_check.gd`. These are the pending issue 710 deliverables already referenced by HANDOFF.
  Findings and oracle drift checks report their known baselines; the remaining standing checks pass.
- Godot prints a Windows root-certificate-store warning in this sandbox. The successful headless checks exit 0.

Scratch logs remain in `%TEMP%/voidsworn_368_*`. CPU result JSON copies are in the issue's shared shots folder.

## Resumed CPU run, Nov 15

- Built on the merged partial branch. No default route or candidate appearance was changed.
- Replaced the bench's existence-only GPU go check with a first-line prefix check. A headless runtime check exercised
  eight cases: cleared, revoked, clearance on a later line, leading whitespace, empty contents, empty path, missing path,
  and the Board's actual revoked file. All eight passed without starting a renderer.
- Repeated both headless map dry runs: exit 0. All three routes at all three quality tiers retain the first run's
  geometry results and noise SHA256. Frame and GPU medians remain null, never substituted with CPU timings.
- Headless timing without `--dry-run`: expected refusal, exit 2.
- `scale_check.gd`: exit 0, 53 rows with six KNOWN rows, including this job's two undersized terrain rows.
- `node contrib/opus/tools/run_all_checks.js`: exit 0. Findings retain seven listed failures and the drift guard retains
  12 listed constant differences; every other row passes, including the formerly failing document check.
  The sandbox initially blocked Node's path lookup; the authorized retry outside the sandbox completed the suite.
- `git diff --check` and an em-dash scan of changed files: pass.

This run's scratch logs and CPU JSON remain in `%TEMP%/voidsworn_368_resume_*`. No screenshots, sheets or recordings
were made because the GPU window was explicitly revoked at run start.

## Next GPU window

The Board supplies a go file whose first line starts with "GPU cleared", verifies the PC is free and runs one GPU job
at a time through the queue/watchdog. Read that line before launching Godot. File existence alone is not clearance.
The bench also rejects an empty, missing, unreadable or revoked file before building the battle or capturing it.
Do not treat the older `paused_for_ryan.txt` or an idle utilization reading as authorization.
Built `godot/gen` and `godot/assets/ships` exist in this checkout, but their current source/stamps have not been verified
for this GPU run. Verify them before the first capture; stop on any placeholder.

For each route (unset/today, fog, cards) and each `--map-case nebula|storm`, run twice and keep the second:

```
Godot --path godot --rendering-method forward_plus --resolution 1920x1080 res://world/nebula_bench.tscn -- --go-file PATH --out DIR --sessions 3 --warmup 120 --frames 720 --modes base,res_2160
```

`DIR` belongs under `C:/Users/rcbai/Downloads/voidsworn_test/board/issue-368/shots/`.
Use distinct warm and kept directories. The original gate retains its 20-ship mixed-faction fleet; the scope questions
were unanswered, so current lighting and the gate's existing fleet were retained for comparable measurements.
Compare base frame median at 1080p and res_2160 GPU median at 4K, each against 12.5 ms. Include deltas against today.
The capture mode (`--captures`) prepares views at 170, 60, 26 and top-down, with one example of each class present in
the gate fleet. This path has only been parsed, not GPU-run or visually reviewed.

Still required before a pick: GPU shader compilation and visual checks, measured results, a bench sheet no taller than
720 px, true-pixel 4K hull readability evidence, all-class scale evidence, top-down board and campaign sector-map views.
The current capture adapter does not yet cover every class or the campaign map. Nebula-case density must also be judged
at the GPU window; the generator yielded only six nebula hexes. Neither candidate has been polished.
Pure fog can affect opaque hulls: cards' depth exclusion alone does not prove that A meets the crisp-hull rule.

## Scale acceptance after issue 710

Issue 710 has landed. Use the single scale table in `docs/playbooks/scale.md` and its live check
`godot/render/test/scale_check.gd`; the provisional duplicate table from the first run is retired.
The headless scale check passes with six KNOWN rows. Nebula and storm are still two of those rows: the current default
cloud span is 46.0 world units against a target of 74.4 to 297.6. An overall PASS with those KNOWN rows does not complete
this job's scale requirement. The picked route must meet the target and retire its KNOWN entries at build time.

The cloud must read far larger than a capital, with each hex sampling part of it. The prototype geometry and small
nebula fixture do not yet prove that requirement. Asteroid terrain is left to issue 369's in-game coverage; verify that
coverage before calling R247 complete. No game rules, saves, oracle copies or ship assets were changed.

## R129 impact review

- Callers: world.gd still builds living terrain through the same API; board-look fading updates both candidate gas layers.
  The mask's original two return values remain in place; its third CPU image is used by the dry run.
- Saves and twins: no serialized state or rule changes. No JS or table edits, so no oracle copies or exports to refresh.
- UI: no new player setting. Candidates require an explicit environment variable; existing quality choices remain.
- Checks on a later push: standing checks, no-em-dash scan, Godot rules parity and Godot game checks from checks.yml.
  This bench is outside test folders and is a manual GPU measurement, not a registered automatic check.
  The new baked volume and its bake script are in scope. No workflow, hull, gen or UID files are part of this delivery.
