# Issue 982 validation

The only changed game file is `godot/world/world_living.gd`. No commits or pushes
were made in the job checkout. Rules, `battle.js`, workflows, ship source, the
accepted `ion_storm.gd` shader and baked nebula noise are unchanged.

## Checks

- `node contrib/opus/tools/run_all_checks.js`: 62 PASS, 2 KNOWN, 1 FAIL across
  65 rows. [Every result and duration](standing_results.json) comes from the real
  final table. The command exits 1 because of the existing station capture issue.
- The FAIL is `picture_provenance_tests`: the unchanged
  [station capture](../../../tools/blender/kits/hegemony_station/capture.gd)
  saves at lines 169 and 203 bypass the shared provenance writer. Its diff against
  HEAD is empty. Both saves need the shared stamped writer; no workflow edit is
  needed. This file is outside issue 982 and was left unchanged.
- KNOWN: seven listed findings and twelve listed oracle constant differences,
  within their existing baselines.
- `world/storm_lightning_check.gd`, headless: PASS. Ten bolts, 32 forks, 16,128
  actual branch vertices, five overlapping strike samples, taper and faster
  branch fade retained.
- `world/nebula_bench.tscn --dry-run`, storm and nebula, headless: PASS. Both gas
  routes and Max/High/Low geometry pass, including footprints, volume count,
  38.5-unit fog height and the unchanged 2,097,152-byte noise resource.
- `render/test/scale_check.gd`, headless: PASS. Zero failures across 54 objects
  outside four existing KNOWN rows.
- Six review sheets: PASS, each 1280x720 with code name, installed-in-game stage,
  verified input revisions and image checksum. [Picture checks](picture_checks.json).
  Max before/after sheets retain both source records; quality sheets share one
  source revision. [Image differences](image_difference.json) exclude the stamp
  area. Whole-scene pixel identity is not claimed: idle indicators and distant
  spinning geometry differ between launches.
- `git diff --check`: PASS. Delivery files contain no em dashes.

## Timing evidence and confirmation

[The tables and pass results](frame_times.md) are generated from measured JSON,
using the median of three session medians. All timing launches use the existing
solo GPU watchdog and respect the gaming pause. A game briefly opened before the
initial after gate; the watchdog waited for it to close before launching.

The [established scene-gate protocol](../ship_pipeline/bench207/README.md) reads
the median across sessions. An initial report assertion imposed a stricter limit
on every session; that extra requirement was corrected. The initial batch's
aggregate already passes the binding gate.

The initial after gate had one 1080p session at 12.936 ms frame median while its
GPU median stayed at 2.673 ms. The three-session frame median was 8.645 ms and the
4K GPU median was 5.899 ms. The full initial output is preserved as
[initial warm](after_gate_initial_warm.json) and
[initial retained](after_gate_initial_keep.json), including that exception.

A follow-up process inspection found concurrent headless rules-parity jobs from
other lanes (issues 990 and 983). CPU contention is an inference, not an isolated
cause measurement. Other jobs were left running. The gate was repeated with the
same production source, arguments, warm-up, frames and three sessions, after this
job's standing suite had finished, with two launches and the second retained.
The final report uses that confirmation batch and preserves both attempts.
The confirmation passes both binding medians; every retained confirmation
session is also below 12.5 ms in its applicable frame or GPU measure.

The max storm render and layout were not changed between timing, pictures,
checks or confirmation. All changes after the production edit are evidence and
reporting work. Scratch logs, imports and failed setup probes stay in TEMP and
are not treated as timing evidence.
