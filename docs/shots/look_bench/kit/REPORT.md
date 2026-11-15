# Weapon kit, issue 367

Refs #367. Not ready for final approval. This continuation preserves the
resumed kit and its earlier evidence. At this run's start on Nov 15, the
required GPU go file began `GPU not cleared`. Per CODEX_TASK.md, this run
did CPU work only. Final-source captures, current gate costs, Ryan's faction
picks and visual approval, and outside review on issue 256 remain pending.
No commit or push was made.

## Changes already on the resumed branch

- `godot/fx/fx_shaders.gd`: textured compact heads and capped curved tails;
  filled lit prism/shield chips; separate ribbon core and sheath flow, forks,
  per-kind motion and fades; resolved curved engine history.
- `godot/fx/fx_weapons.gd`: smaller shell head/trail; a two-frame travelling
  gauss tracer and short distortion wake in both gauss paths; beam endpoint
  flares and cooling glow; readable rocket/torpedo motors with a rise and fade.
- `godot/fx/fx.gd`: bind the shared imported mask textures for every material,
  including attached batches.
- `godot/fx/textures/`: three original masks, their complete Python/Pillow
  source and provenance. No downloaded sprites or licence packs.
- `godot/fx/API.md`: the kit contract, pixel convention, callers and capture
  method. The rules oracle, saves, UI and faction ids are unchanged.
- This folder: capture, pixel measurement, gate and sheet tools.

This continuation changes only this report and `make_sheets.py`. The sheet
tool now rejects after-capture source hashes that differ from the current FX.
An explicit `--provisional` flag permits historical comparisons, labels all
their pictures `OLDER CANDIDATE`, and writes `sheet_provenance.json`. No new
runtime visual changes were made without the required GPU window.

## Evidence

CPU processing recovered two earlier complete sets of 138 strips each,
covering 46 rows at cameras 170, 60 and 26. The before set's three FX hashes
match `origin/main`. The after set's three FX hashes differ from the resumed
final files, so these are historical candidate pictures, not final proof.
The separate six-strip craft set has no process completion record and was
not substituted into these comparisons.

The 46 comparison sheets, 46 camera-26 sheets and nine ribbon timelines are
saved in the required folder, with source metadata, hashes and frame choices:

[Evidence manifest](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/resume_cpu_20261115/evidence_sha256.json),
[source provenance](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/resume_cpu_20261115/sheet_provenance.json),
[Doom](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/resume_cpu_20261115/doom.png),
[shell](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/resume_cpu_20261115/macro.png),
[plume](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/resume_cpu_20261115/ribbon_0.png),
[rockets](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/resume_cpu_20261115/rockets.png).

All 101 PNGs decode and fit within 1280 by 716 pixels. Camera 170 is first
and retains source pixels. Ribbon camera 60 retains a native detail crop;
other camera-60 views and all camera-26 build views are reduced full views.
The four linked example sheets were opened and inspected: ships are real
hulls, the older Doom candidate has forks and coloured glow, and the shell
has a compact head. This sampling is not an all-frame no-hairline verdict.

The old before capture completed 138 strips with no reported bench warnings,
then stalled during native teardown and was stopped (exit -1). Its later PD
recapture is recorded separately in `historical_before_bench.json`. The old
after capture exited 0 with 138 strips, no bench warnings, and one late
`exterior_alpha` shader. These limitations remain attached to the evidence.
Raw strips stay in their original TEMP folders; only the review sheets and
metadata were copied, avoiding another 461 MB copy. No new capture ran.

Historical R116 results, median of three session medians:

| Measurement | Before | Older candidate after | Binding gate |
|---|---|---|---|
| 1080p frame median | 2.590 ms | 2.665 ms | 12.5 ms |
| 4K GPU median | 5.142 ms | 5.146 ms | 12.5 ms |

The raw records are [before](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/resume_cpu_20261115/historical_gate_before.json)
and [older candidate after](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots/resume_cpu_20261115/historical_gate_after.json).
They have no FX source fingerprint and report one late shader per session.
They are context only, not acceptance of the final kit's cost or warm-up.

## Faction shapes for Ryan's pick

These are candidates shown by the kit, not recorded owner approvals. Existing
faction colours remain in faction_looks.json, including Eclipse violet-white.

| Faction id | Display name | Proposed shape language | Sheet | Pick |
|---|---|---|---|---|
| voidsworn | Sunward Crusade | Compact hot shells, broad sustained lance, clean hot throat | macro, lance | Pending |
| corsair | Ashfall Hullbreakers | Uneven pellet spray, rocket clusters, broken sputtering exhaust | scatter, rockets, ribbon_3 | Pending |
| ithar | the Glasswrights | Filled faceted chips, narrow needles and spectral travelling packets | prism, needle, pulsar | Pending |
| deathless | Eclipse | Angular forked arcs, compact two-frame gauss tracer and cooling violet sheath | doom, gauss | Pending |
| chorus | the Chorus | Wet luminous globs, curved drips, wriggling tissue and spores | bioplasma, tendril, spores | Pending |
| hegemony | Hegemony Navy | Blue churning plasma heads, crawling ion filaments, short precise picket darts | plasma, ion, pflak | Pending |

## Checks and limits

Current-run CPU checks:

- `node contrib/opus/tools/run_all_checks.js`: exit 0; 50 PASS, 2 KNOWN,
  zero FAIL or SKIP rows.
  The first sandbox attempt stopped at Node's EPERM path lookup; the retry
  outside the sandbox runs the same command. Log:
  `%TEMP%/voidsworn-367-resume-standing.txt`.
- Godot 4.7.2 `--headless --path godot --script res://tools/ci/load_all.gd`:
  exit 0, 187 scripts, 11 scenes, zero failed. It logs the PC root-certificate
  warning. Log: `%TEMP%/voidsworn-367-resume-load.txt`.
- Headless `destruction_steps_check`, `death_plane_check`,
  `destruction_staging_check`, `fx_smoke`, `flash_area_check`,
  `hit_recipe_check`, and `playtest_batch1_check`: all exit 0. These runs also
  log missing imported kit PNG resources in this fresh checkout. Their exit
  codes cover CPU assertions only, not texture loading or rendered appearance.
  Logs: `%TEMP%/voidsworn-367-cpu-ed57df593e594151a729b423e33875a0/`.
- All three mask outputs reproduced byte for byte from `make_kit.py` in TEMP.
- Sheet source guard: correctly refused the older after set with exit 2;
  explicit provisional export exited 0. All 101 output PNGs decode, with
  their size limit and hashes verified.
- `git diff --check`: pass. Changed text is ASCII.

Skipped: new GPU captures and raster measurements, imported-texture rendering,
the GPU/real-hull portion of `check_destruction.bat`, and final R116 runs,
because the task explicitly stops GPU work when its go file is not cleared.
No final-source two-frame or pixel-width claim is made from older TEMP rasters.
API.md section 17 states the implementation's geometry caps: sparks 16 actual
render-target pixels, shells 22, gauss 26; ribbon core/sheath targets are there
too. Measure those again against the final source in the next GPU window.
The one scale table remains docs/playbooks/scale.md.

R129 sweep: every `stk`, `rib` and kind-16 sprite caller shares the new drawing
code. Both gauss emitters use the shared wake; beam endpoint additions cover lance,
ion, pulsar, Doom, needle and tendril. All eight original shared-helper rows
are in the capture adapter. No saves, UI path or rules twin changed, so there are no oracle
copies or tables to refresh. GitHub still runs standing checks, changed-text
checks, rules parity and Godot game checks. No remote check was dispatched.

Next run: require the GPU go file, copy and verify PC hulls before import,
capture the final source twice and keep the second set at all three cameras,
inspect every family and all nine ribbon kinds, rerun raster caps and the
two-frame gauss proof, and measure the scene gate with source hashes. Then
obtain the outside check and Ryan's faction picks and final visual approval.
