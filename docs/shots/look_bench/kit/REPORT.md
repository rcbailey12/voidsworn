# Weapon kit, issue 367

Refs #367. The proposed kit and its measured before/after evidence are ready
for review. Ryan's faction picks and final visual approval are pending, as is
the outside check on issue 256. No commit or push was made.

## Changes

- `godot/fx/fx_shaders.gd`: authored compact heads and capped curved tails;
  filled lit prism/shield chips; separate ribbon core and sheath flow,
  branching Doom, per-kind motion and fades; resolved engine/craft history.
- `godot/fx/fx_weapons.gd`: smaller shell heads and trails; a two-frame gauss
  tracer and brief distortion wake in both gauss paths; beam endpoint flares
  and cooling glow; rocket/torpedo motor rise and fade; real PD interception
  routing; capped trails on attack craft and live wings.
- `godot/fx/fx.gd`: shared imported mask bindings and craft-trail warm-up.
- `godot/fx/textures/`: three original masks, their complete free
  Python/Pillow source, and provenance. All three reproduce byte for byte.
  No downloaded sprite pack or new third-party licence is involved.
- `godot/fx/API.md`: pixel convention, caps, callers and capture method.
- This folder: capture, merge, raster, cost, sheet and evidence tools. This
  continuation completed proof of the resumed kit, expanded raster coverage
  to all nine ribbons, finished the mixed audit trace and corrected an empty
  Eclipse shield fixture to the missing Hullbreaker shield style. The adapter
  now refuses a shield-break fixture with no live shield.

## Evidence and method

Final evidence root:
`C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/review_20261115`.
Use its `sheets/` and `sheet_frames.json` index. Earlier preview folders are
not the final selection. There are 46 comparison sheets at cameras 170/60,
46 separate camera-26 build sheets, 25 weapon sequence sheets, nine ribbon
fade sheets and 12 review pages. Every sheet is at most 1280 by 720.
Camera 170 is kept at source pixel size; nine ribbon kinds also have native
camera-60 detail crops. Other camera-60 views and camera-26 build views are
clearly labelled as full views reduced three times.

Start with [Doom](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/review_20261115/sheets/doom.png),
[gauss](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/review_20261115/sheets/gauss.png),
[shell sequence](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/review_20261115/sheets/macro_sequence.png),
[filled flakes](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/review_20261115/sheets/flakes_hegemony.png)
and [Hullbreaker shield](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/review_20261115/sheets/flakes_corsair.png).
The complete `before/` and `after/` strips contain all 138 rows per version,
including muzzle, flight, contact and cooling samples. All eight original
shared-helper regressions, three PD groups, bay launch, travelling torpedoes,
moving engine history and all four actual shield styles are included.

The GPU go file began with `GPU cleared` at this run's start. PC hulls were
copied without deletion from `build/godot`; all 252 ship-file hashes match
the tracked manifest. Both bench reports have zero capture warnings and no placeholder
hulls. The fresh camera-170 warm pass and kept three-camera after pass exit 0.
The Hullbreaker replacement was also warmed and captured a second time on
both versions, without changing FX source.

The original before strips come from the earlier kept run. Their three FX
files exactly match pre-kit parent `a5295973e6ced2e3d2bf85a2155d138bc64c77a0`.
That earlier process was stopped after a native shutdown stall following
`LOOK_BENCH_DONE`; all 138 stills completed without pre-completion render
errors. The final after capture exits normally. The new cost pair uses the
current game on both sides with only those three FX files substituted.
Source hashes and fixture replacement history are delivered with the data.
`verify_evidence.py` passes against the final source, coverage and images.
The accepted look-bench baseline was not changed.

## Trace and pixel measurements

[TRACE.md](TRACE.md) lists every named audit feature and its emitter. The
remaining sh_06 ambiguity is now observed in a source-checked replay of the
original audit gallery: 48 long green streaks come from Chorus spore flak,
`_flak:803 -> _impact_sparks:530 -> stk(kind 1)`. Sunward shield sparks and
torpedo sparks also overlap that shot. Hegemony's break supplies rings and
cross glints. The replay, live call stacks and summary are in `forensic/`.
This old free-camera replay is attribution evidence, not a kit look bench.

The stated caps are absolute render-target head-to-tail geometry lengths,
independent of the optional `min_px` setting and of resolution:

| Kind | Cap | Actual lit horizontal span in the no-bloom probe |
|---|---:|---:|
| Spark, bio/metal drip and flame tongue | 16 px | Spark: 12 to 13 px |
| Shell/tracer | 22 px | 17 px |
| Gauss/gauss flak | 26 px | 17 to 21 px |
| Las/prism dart | 32 px | Covered by family captures and shared cap code |

The raster probe passes at cameras 170, 60 and 26, at 1080p and 4K, including
sparks with `min_px = 0`. Max and low quality gauss are luminous at ages 0 and
1/60 s and dark at 2/60 and 3/60 s. Its tracer lasts `(2 - 0.001) / 60` s;
max quality adds a separate 0.10 s heat shimmer. The slight epsilon prevents
a third sample from float rounding. The whole-shot luminous wake is gone.
See `raster/gauss_two_frames_1080.png` and `gauss_two_frames_2160.png`.

API section 17 states separate analytic core/sheath width profiles for every
ribbon. Actual combined red/green channel half-peak widths below are measured
in the 1080p raster without bloom. These channel measurements include both
profiles and tone mapping; they are not isolated core/sheath widths.

| Ribbon | Camera 170, R/G px | Camera 60, R/G px |
|---|---:|---:|
| Plume 0 | 5 / 6 | 10 / 13 |
| Idle 1 | 5 / 5 | 11 / 13 |
| Lance 2 | 8 / 10 | 16 / 22 |
| Sputter 3 | 5 / 6 | 10 / 13 |
| Ion 5 | 8 / 10 | 16 / 22 |
| Doom 6 | 7 / 17 | 7 / 16 |
| Pulsar 7 | 4 / 6 | 8 / 13 |
| Needle 8 | 6 / 8 | 16 / 22 |
| Tendril 9 | 7 / 10 | 16 / 21 |

Raw results for both resolutions and all three cameras are in
`raster/cap_measurements.json`. Geometry caps precede bloom and do not bound
a glow's threshold-dependent lit extent. The one world-scale source remains
`docs/playbooks/scale.md`; the kit adds no competing scale table.

## R116 cost

Unchanged #207 scene gate, RTX 5080, Forward+, 360 measured frames per mode,
three kept sessions per version after a separate warm run. Values below are
the median of the three session medians.

| Binding measurement | Before | After | Change | Limit |
|---|---:|---:|---:|---:|
| 1080p frame median | 2.738 ms | 2.989 ms | +0.251 ms | 12.5 ms |
| 4K GPU median | 5.152 ms | 5.142 ms | -0.010 ms | 12.5 ms |

The GPU difference is inside session variation. Both versions report one
late `exterior_alpha` shader; this does not claim zero late compilation.
Full counts, timings, settings and source hashes are in `gate_before/` and
`gate_after/`. Final summaries are in `evidence_summary.json` and
`checks_summary.json` at the evidence root.

## Faction shapes for Ryan's pick

These are candidates shown by the kit, not owner approvals. Existing faction
colours remain in faction_looks.json, including Eclipse violet-white. Each
listed code has its own comparison sheet under `sheets/`.

| Faction id | Display name | Proposed shape language | Sheet codes | Pick |
|---|---|---|---|---|
| voidsworn | Sunward Crusade | Compact hot shells, broad sustained lance, clean hot throat | macro, lance, ribbon_0 | Pending |
| corsair | Ashfall Hullbreakers | Uneven pellet spray, rocket clusters, broken sputtering exhaust | scatter, rockets, ribbon_3 | Pending |
| ithar | the Glasswrights | Filled facets, narrow needles and spectral travelling packets | prism, needle, pulsar | Pending |
| deathless | Eclipse | Angular forked arcs, compact two-frame gauss tracer and cooling violet sheath | doom, gauss | Pending |
| chorus | the Chorus | Wet luminous globs, curved drips, wriggling tissue and spores | bioplasma, tendril, spores | Pending |
| hegemony | Hegemony Navy | Blue churning plasma, crawling ion filaments, precise picket darts | plasma, ion, pflak | Pending |

## Checks and remaining review

- `node contrib/opus/tools/run_all_checks.js`: exit 0, 50 PASS, 2 KNOWN,
  no FAIL. The known rows are findings_tests and oracle_drift_guard.
- Headless load: 187 scripts, 11 scenes, zero failed. Nine focused checks
  pass without resource errors: load-all, destruction geometry, death plane,
  destruction staging, effects smoke, flash area, hit recipes, playtest batch
  1 and the scale table.
- Full `godot/fx/test/check_destruction.bat`: exit 0, including GPU box and
  20-ship fleet probes. The real-hull spawn guard records 33 of 33 pictures,
  zero stray, zero errors. Blocker checks cover 120 battles and 3068 hexes,
  zero failures. Stand-in fleet probe: 1.803 ms average, 5.499 ms p99.
- Real public PD option: before exits 1 with `INTERCEPT_CHECK failures=12`;
  intercepted bodies remain alive (Sunward 1, Hullbreakers 4, Glasswright 1).
  After exits 0 with failures=0 and all six bodies freed. Ordinary misses
  and rolled hits remain flying. The fixture calls the real volley/update
  path and inspects the bodies themselves.
- Raster proof, final evidence/source checks and mask reproduction pass.
  All four active shield styles are captured. Review pages were inspected
  at camera-170 source pixel size. The new comparison selectors show the
  gauss tracer and PD bursts rather than earlier charging/flight frames.
- First checks started during import hit temporary or unimported files.
  They were rerun after import and pass. Godot still reports the PC's
  root-certificate-store warning. Generated tracked import churn was restored.

R129 sweep: every `stk`, `rib`, kind-16 sprite and craft-trail caller is
covered, including both gauss emitters and the eight original helper rows.
No save, UI, faction id or rules twin changed; no oracle copy or table export
needed refresh. GitHub still runs standing, changed-text, rules parity and
Godot game checks. No remote workflow was dispatched.

Still required: Ryan's faction picks and visual approval, then the outside
check on issue 256. These were not claimed or substituted with test passes.
No accepted baseline, tracked ship asset, uid file or workflow was edited.
The copied ship and gen cache files remain ignored.
