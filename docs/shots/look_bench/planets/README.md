# Issue 369: R01 rocky planet review packet

R01's three 8K maps now ship in 39.68 MB total, with every file below 8 MB.
The compressed candidate, scanned rocks, GPU captures and checks are ready for
review. Live board integration and larger asteroid sizing remain unapplied
patches because their targets are outside CODEX_TASK.md's allowed write list.
Ryan's first-planet approval and the outside check on issue 256 are still owed.

## Files and method

- `godot/world/world_planet.gd`: the retained R01 surface, air glow, moving cloud
  shell and matching ground shadows, including the previous pole/filter fixes.
- `godot/world/world_bake.gd`: worker loading and assembly of WebP payloads inside
  Godot Resources. Resources survive export without texture import changing the
  packed channels. Float mipmaps preserve filtered height values.
- `godot/world/rocks/r01/`: 48 resources, three descriptors and the bake manifest.
  All maps remain 8192 by 4096. Resources total 39,680,106 bytes;
  the largest is 2,104,667 bytes.
- `godot/world/world_rocks.gd`, `rocks/scan_*` and `scans.json`: the resumed eight
  scanned CC0 rock pairs and five biome tints. Dust retains generated geometry.
- `LICENCE_369.md` and `SOURCES_369.json`: per-file credits and original dates.
  All 34 cached source files match the download receipts. No new downloads.
- `tools/pc/jobs/planet369_*`: reproducible download, remix, WebP encoding,
  resource packing, checks, captures, scale proposal and comparison jobs.
- `docs/shots/look_bench/planets/`: fresh camera, planet, map, rock and scale
  evidence, including the packing comparison at camera 26.

The sources are LROC WAC colour and LRO LOLA elevation, mixed and independently
warped in sphere space, then recoloured. Per-file source pages and dates remain
in the licence ledger. [Source comparison](R01_sources.jpg).

## What compression loses

Colour uses WebP quality 90. Height is rounded from 16 to 11 bits, with at most
16/65535 error in decoded height. Roughness and clouds are rounded to six bits,
with at most 2/255 error. Their WebP encoding preserves those rounded values.
No spatial samples are removed. Raw colour channel errors and both source and
decoded pixel hashes are in [R01_storage.json](R01_storage.json). A large low-byte
height difference can be a carry; decoded height is the relevant error.

[Prior lossless versus compressed R01 at camera 26](R01_pack_compare_c26.jpg)
shows matching centre crops at actual pixels. The final launcher rerun reproduced
all three captured decoded pixel hashes exactly. Original full PNGs stay in TEMP.

## Pictures

The PC packet is `C:/Users/rcbai/Downloads/voidsworn_test/board/issue-369/shots/`.
Each before/after mode ran twice; run 2 is retained for review. Cameras 170, 60
and 26 use 1280 by 720 crops at actual pixels from a 1920 by 1080 viewport.
The planet and top-down images show the reduced full frame. Every image is named;
no close view uses a radius below 26.

- [Battle camera 170](R01_compare_c170.jpg), [camera 60](R01_compare_c60.jpg),
  [camera 26](R01_compare_c26.jpg).
- [Planet](R01_after_planet.jpg), [top-down board](R01_after_board_top.jpg).
- `after/run2/R01_planet.png` and `R01_cloud_motion.png` are four seconds apart.
  `R01_shadows_on.png` and `R01_shadows_off.png` hide the cloud shell and hold its
  field to expose the ground-shadow effect. The pair was inspected, with pixel
  differences recorded in `R01_visual_checks.json`.
- Eight `R01_scan_*` images show each full scan beside its reduced mesh; five
  `R01_biome_*` images show the tints. [One scan example](R01_scan_03.jpg).
- `R01_scale_*` images show every real combat hull class and spawned wings at
  cameras 170 and 60. [Frigate example](R01_scale_Frigate_c170.jpg): 10.4 units
  beside a proposed 37.91-unit rock. These larger sizes are a proposal, not the
  live field size. Raw class/rock/tint pictures are in `showcase/` in the PC packet.
- `R01_sector_before_*` and `R01_sector_after_*` show the real campaign map and
  sector II. R01 has not been rolled out to campaign planet types.

## Measurements

Offline CPU remix: 26.315 s; WebP encoding:
65.261 s; resource packing: 1.637 s.
These are actual final PC launcher runs. R01 needs no runtime geology bake.

| Median of three #207 sessions | Before | Scanned rocks |
|---|---:|---:|
| 1080p frame median, ms | 3.663 | 3.625 |
| 4K GPU median, ms | 5.650 | 5.576 |
| 4K GPU session range, ms | 5.631 to 5.728 | 5.563 to 5.635 |

Both pass R116's 12.5 ms gate. The 4K render uses a 1920 by 1080 window at 2x
3D resolution. Small differences are not a speedup claim. Both modes recorded
one existing `exterior_alpha` late-shader marker per session; details remain in
`R01_before_gate.json` and `R01_after_gate.json`.

The separate planet scene loads 20 ship hulls plus four squadron entities.
At 4K its opening GPU median is 3.589 ms; the planet-focused
median is 4.493 ms versus 5.559 ms before.
Process-cold decode, float mips, upload and first draw take
1,672 ms. Resident card memory is
7,715 of 16,303 MiB, including desktop/driver use. Runtime map memory remains
about 853 MiB; disk compression does not reduce that cost. The planet-focused
frame reports 7,686,271 primitives and
1,158 draw calls. The scan library totals
513,970 full-mesh and 20,089 reduced-mesh triangles. These are reports, not caps.

## Checks and remaining work

- Required `node contrib/opus/tools/run_all_checks.js`: 56 PASS, two KNOWN, zero
  failures. The sandbox Node access error was cleared by running with normal
  Windows access; the completed check run exited 0.
- `planet369_remix.bat --only planet`, `planet369_pack.bat`,
  `planet369_check.bat`, `planet369_bench.bat` and `planet369_sheets.bat`: real
  PC runs passed. The data check verifies all 48 hashes and sizes, all three
  assembled 8K pixel hashes, scan loads/LODs, unit radii, procedural dust, mip
  heights, cloud coverage and shared shadow data. Final mip error is below one
  16-bit step. Placeholder guards passed every GPU run.
- A real isolated Godot PCK export using these resources and the production
  loader reproduced all three decoded 8K pixel hashes.
- `scale_check.gd`: PASS with its six existing KNOWN rows. The asteroid row
  remains KNOWN because the live size edits are outside scope.
- `git diff --check` and both production patches' `git apply --check`: PASS.

Skipped applying `planet369_board.patch`: its target is `godot/render/board.gd`.
Skipped applying `planet369_scale.patch`: its targets are `world.gd`, the scale
playbook and the scale check. CODEX_TASK.md explicitly limits edits to its Deliver
to list and excludes these targets. The live board planet therefore remains
procedural, and live scanned rocks retain the existing scale range. The probe
installs R01 for review. Both ready patches are retained in `tools/pc/jobs/`.
Gas and ice giant code is unchanged. No other planet type was made before Ryan's
first-planet review. Outside review on issue 256 remains required before merge.

R129: world, blocker and living-terrain callers retain the rock API and unit
radius. The new image path is only used by R01. Saves, faction ids, rules, both
exported tables and UI flows are unchanged; no oracle refresh is needed. GitHub
still runs standing checks, changed-text checks, rules/campaign parity and the
Godot game checks. No workflow files were edited. Import-generated metadata was
restored; no tracked changes remain outside scope.

Refs #369. Refs #256. No commit or push was made.

Board, Nov 16: the 51 captured PNGs in this folder were stored as JPEG quality 90 (same pixel size) to keep the repo small
(44 MB to 11 MB); the capture scripts still write PNG, so convert after a rerun.
