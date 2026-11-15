# Issue 369: R01 first rocky planet

R01 is the first rocky review candidate, continued from the merged partial run.
It has real terrain, an air shell, moving clouds with shadows and eight scanned
rock pairs. No other planet type was made. Gas and ice giants are unchanged.
Ryan's acceptance and the outside check on issue 256 are still owed.

## Files and method

- `godot/world/world_planet.gd`: R01 surface, atmosphere and cloud materials.
- `godot/world/world_bake.gd`: worker loading, tile assembly, shared mipmaps and
  texture uploads. Packed height channels use float mipmaps. Byte mipmaps rounded
  the high height byte first and produced false radial ridges near the pole.
  Angular sampling and a latitude clamp also prevent opposite-pole wrapping.
- `godot/world/world_rocks.gd` and `rocks/scan_*`: the first run's eight CC0 scan
  pairs, five biome materials and the procedural geometry kept for dust.
- `godot/world/rocks/r01/`: three complete 8192 by 4096 maps, each in sixteen
  compressed Godot Image resources. The largest file is 7,488,035 bytes. Nothing
  was lost in resolution, channel precision or pixels. Full PNG hashes also match
  the first run. The loader joins tiles before mip generation. The roughness map
  is a review output; the runtime shares colour and packed data between materials.
- `LICENCE_369.md`, `SOURCES_369.json`, `scans.json`, `r01/bake.json`: credits,
  source terms, dates, hashes and methods. All 34 cached inputs match the original
  receipts. No sources were downloaded again during this continuation.
- `tools/pc/jobs/planet369_*`: download, remix, pack, check, capture, scale and
  comparison jobs. User entry points are double-click `.bat` files.

Two public-domain instrument datasets, LROC WAC and LRO LOLA, are mixed, warped
in sphere space and recoloured into fictional mineral terrain. See
[R01_sources.jpg](R01_sources.jpg). Per-file source pages and dates read at download
time remain in the licence ledger. Current NASA and Poly Haven terms were also
checked during this continuation.

## Evidence

All screenshots, sheets and measurements are saved under:

`C:/Users/rcbai/Downloads/voidsworn_test/board/issue-369/shots/`

Keep `before/run2` and `after/run2`; run 1 pays shader warm-up. Cameras 170, 60
and 26 keep 1280 by 720 true pixel crops from an actual 1920 by 1080 viewport.
`home_c170` is the opening view; `c170` pans onto the planet at the same battle
angle and radius. Nearer checks target the cap height to stay outside the sphere.
The planet and top-down views are reduced full frames. No radius is below 26.

- `R01_compare_c170.jpg`, `R01_compare_c60.jpg`, `R01_compare_c26.jpg`: paired
  centre crops at 1:1 pixels. Individual full crops are retained in this folder.
- `after/run2/R01_planet.png` and `R01_cloud_motion.png`: the same view four seconds
  apart. `R01_shadows_on.png` and `R01_shadows_off.png` hide the cloud shell and
  hold the field so its effect on terrain can be compared directly.
- `R01_visual_checks.json`: pixel differences below the captions.
- `showcase/R01_scan_00.png` through `R01_scan_07.png`: every scan beside its
  reduced mesh. `R01_biome_*`: all five tints. Every picture has its code name.
- `showcase/R01_scale_*`: eleven real combat classes at cameras 170 and 60 beside
  scan_04 at a proposed 20x scale. The rock is 37.91 units long; the frigate is
  10.4. Units come from the real scenario constructor; only presentation positions
  change. This is a proposal, not a claim that the production size changed.
- `before/sector` and `after/sector`: real campaign mapshots, including sector II.
  This first-planet job does not roll R01 out onto the sector map.
- `before/gate/scene_gate.json`, `after/gate/scene_gate.json`: three #207 sessions
  each at 1080p and a 3840 by 2160 3D render size, with real fleets and effects.

## Measurements

CPU remix: 25.990 s. Lossless packing and readback: 6.129 s, actual PC runs.
R01 is authored offline; no runtime geology bake is needed.

| Median of three #207 sessions | Before | Scanned rocks |
|---|---:|---:|
| 1080p frame median, ms | 3.801 | 3.779 |
| 4K GPU median, ms | 5.611 | 5.541 |
| 4K GPU range, ms | 5.528 to 5.663 | 5.483 to 5.583 |

Both pass the R116 12.5 ms gate. The small difference is not a speedup claim.
The R01 surface has separate 4K readings with 20 hulls and four squadron entities
loaded: `before/run2/R01_metrics.json` and `after/run2/R01_metrics.json`. They also
measure a pan onto the planet, its process-cold map load through the first drawn
frame, texture memory and a resident `nvidia-smi` reading.


| Separate planet scene at 4K, run 2 | Before | R01 |
|---|---:|---:|
| Opening-view GPU median, ms | 3.518 | 3.452 |
| Planet-focused GPU median, ms | 5.455 | 4.473 |
| Planet-focused frame median, ms | 5.777 | 4.741 |
| Resident card memory, MiB | 6145 | 6999 |
| Card total memory, MiB | 16303 | 16303 |

R01 process-cold decode, float mip generation, upload and first draw took 1,611 ms.
These are process-cold readings with OS/driver caches left alone. Float filtering
spends about 853 MiB in the two shared 8K GPU maps; the roughness review map is not
uploaded. The card reading includes desktop and driver use. The original #207
storm scene does not install R01, so its completed gate is unchanged by the later
pole-filter correction. The final surface captures were repeated after it.

The scan library has 513,970 full-mesh triangles and 20,089 reduced-mesh triangles.
At the planet-focused R01 frame the renderer reported 7,580,724 primitives and
1,153 draw calls. Per-session visible/shadow counts and per-hull surface counts
remain in the scene-gate JSON. These are measurements, not triangle/draw limits.
Cloud motion changed 108,699 pixels below the caption; the isolated shadow pair
changed 46,620 pixels. The comparison inputs and channel maxima are retained in
R01_visual_checks.json. The pictures, rather than these counts alone, are the proof.

## Checks and remaining scope

- Required standing checks: 50 PASS, two KNOWN baseline rows, zero failures.
- `planet369_check.bat`: all 48 file sizes/hashes, all three full 8K pixel hashes,
  actual GLB loads and reductions, unit radii, procedural dust, clouds, shared
  shadow map and material installation pass. Float mip heights agree with the
  source averages within one 16-bit step; measured maximum error 0.000000088.
- All 34 source hashes and the first run's three full PNG hashes match.
- Godot 4.7.2 parses the capture scripts. Placeholder guards accept the PC hulls.
- `scale_check.gd`: PASS with six existing KNOWN rows. The asteroid row remains
  KNOWN because the live size change is outside the permitted write list.
- Both production patches pass `git apply --check`.

The live board planet is made in `godot/render/board.gd`, outside the task's write
list. `tools/pc/jobs/planet369_board.patch` is the ready hook for its first rocky
look. `planet369_scale.patch` changes the live rock range to 12x through 20x and
updates its scale table and check. Its files are also outside that list. Scope
approval was requested and has not arrived. Neither patch is applied. The probe
installs R01 for review; live board integration and the live asteroid scale remain
open. Ryan must approve the first planet before any further types are made.

The first real capture run exposed and corrected the inherited screenshot-tour
trigger, viewport setup and campaign scene path. Only corrected captures are kept
as review evidence. Failed-tour scratch was moved intact to TEMP. Nothing was
deleted. Import-generated edits outside this job are restored before delivery.

R129 impact sweep: world.gd, blocker_visuals.gd and world_living.gd keep the rock API
and normalized scale. Other image callers keep default loading. Saves, faction
ids, rules, both exported tables and UI flows are unchanged; no oracle refresh
is needed. Existing GitHub standing, text, parity and Godot jobs remain in place.
The task-specific data check stays an explicit PC job outside the Godot test folder.

Refs #369. No commit or push was made.
