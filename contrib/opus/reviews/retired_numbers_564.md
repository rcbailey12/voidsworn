# Issue 564: checks that still enforced retired numbers

Branch work/issue-564-deepseek. One change per item. Nothing on screen changes; the work removes look numbers from checks
that had outlived their rule.

## 1. Recipe stages 3 and 4 report the outline overlap (RULEBOOK 5.8)

- `tools/recipe/ship.py`: the `gate` helper now prints `REPORT <cell> outline overlap <n> percent, outline_gate <g> is
  context only (not a pass bar)` and exits 0 whenever the score file can be read. A missing or unreadable score still
  exits non-zero.
- `tools/recipe/standing.py`: `check_outline` still fails loudly when an overlap or any inner edge distance is missing,
  but a low overlap is now a `REPORT` line beside the old gate and per-third floor. Its selftest fixture was moved below
  the old gate on purpose; the broken copy now removes an inner edge distance.
- `tools/recipe/3_trace_hull.bat` and `tools/recipe/4_parts_kit.bat`: comments and end messages say reported, not a gate.
  Every other failure in both stages is unchanged: missing shape reference, trace, tune, build, audit, audit selftest,
  per-third data and second camera still stop the stage.
- `docs/playbooks/ships.md` and `docs/ship_pipeline/RECIPE.md`: removed the stale "stages still exit below 0.90" notes and
  the old gate wording, so the working documents now match RULEBOOK 5.8 (RULEBOOK 0.2).

Rule now followed: RULEBOOK 5.8, the outline overlap against the concept is reported, never a pass bar.

## 2. Destruction checks protect caps, cleanup and no straight cut (R186, R215)

- `godot/fx/test/destruction_staging_check.gd`: removed the fixed `death_cut_count == 2 or 1` assertion and the
  `nodes == count + 1` assertion. The test now checks that every main piece from the fracture plan has an opaque cap
  (not hollow), that every parted piece has its cut event, that `clear_wreck` releases every piece, and keeps the existing
  `_check_blown_apart` checks for the bite and no straight full-width cut.
- `godot/fx/test/destruction_steps_check.gd`: removed the exact `7.0 * 0.982 * 0.982` cap area pin. The cap must now
  cover 90 to 105 percent of the concave outline's own area, so a changed cap look cannot fail while a hollow piece still
  does. The open-edge, finite-vertex and cap-material checks are unchanged.

Rule now followed: RULEBOOK 5.5 and 6.5 with R186 and R215, wrecks are blown apart and back their broken faces; there is
no fixed piece count. RULEBOOK 12.1, a check that pinned a look number no longer pins it.

## 3. Death wait reads the ship's own timeline (RULEBOOK 12.1)

- `godot/fx/test/death_leap_check.gd`: the typed 2.67 s wait is gone. The test calls `fx.death("T", "blast")` and compares
  the returned duration to the ship's `death_timeline` from `fx_death.gd` (`tl.end`), and checks the death outlasts its
  break (`dur > tl.cut`). A later change to the capital timeline moves the test with it.

## 4. Audio cues counted by family (RULEBOOK 8.4)

- `godot/audio/test/audio_check.gd`: removed `s.cues.size() == 67`. A `CUE_FAMILIES` floor table now covers 14 families
  (guns, weapon tails, lances, torpedoes, hits, shields, patterns, explosions, ship, ui, stings, fleet, death, orders).
  Every listed take must be present, every cue must belong to a family, and removing a take from a family fails. Adding a
  take or a variant to a family passes without moving a total. Added a check through the real `_pick` round robin that a
  cue never plays the same take twice in a row (RULEBOOK 8.4).
- The once-only big-death cues (`boom_l`, `bass_drop`, `wreck`) are kept: the death playbook keeps one core beat per
  capital death, so those assertions still protect the single split, core flash and wreck tail. Only the exact table
  total was retired.

## 5. Glide bank roll: report only (RULEBOOK 7.5)

No code change. `godot/render/ship_view.gd` sets `glide_bank = 0.0` on every default `play_glide` step (line 1221), when a
glide finishes (1203), and on `snap_to` (1279). The old debug segments mode `play_moves` never writes it either, so it
stays 0. `godot/fx/fx_ship.gd:639` reads it and writes `root.rotation.x = flight_bank + hit reaction`; with the bank at 0
there is no roll into turns in any mode. The only other `rotation.x` writes in `ship_view.gd` are the wreck pose
`hull.rotation.x = 0.08` in `die()` and `hull.rotation = Vector3.ZERO` in `revive()`; neither is a turn. No non-default
mode still rolls.

## Checks run

- `python tools/recipe/standing.py selftest`
  - `PASS the standing gate passes good output and fails each broken copy`
  - The good fixture now reports bow 80, midship 80, stern 70, whole 78 against the old 90 gate and still passes.
- `python tools/recipe/ship.py C15s_23 gate <50 percent fixture>`
  - `REPORT Ab8 outline overlap 50.0 percent, outline_gate 90 is context only (not a pass bar)` and exit 0.
- `python tools/recipe/contract_tables_selftest.py`
  - `PASS the hard point contract tables and standing gate behave` (it runs the same standing selftest).
- Godot 4.7.2 headless, after one `--import`:
  - `DESTRUCTION_STEPS failures=0`
  - `DEATH_LEAP failures=0`
  - `DESTRUCTION_STAGING failures=0`
  - `AUDIO CHECK PASS`
  - `movement flight: PASS` (run to confirm no roll in the default mode)
- `node contrib/opus/tools/run_all_checks.js`
  - All rows PASS except the two baseline rows: `KNOWN: 7 listed failure(s)` and
    `KNOWN: 12 constant difference(s) within the baseline`; exit 0.
  - `doc_check_tests` rerun after the document edits: `PASS: 49 paths named in the entry documents exist ...`
- `cmd.exe //c "tools\\pc\\parity.bat nopause"`
  - `PASS: the Godot port matches the game's rules exactly.`
  - `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`

## Review sweep (the five checks)

- Callers: `ship.py ... gate` is called only by stages 3 and 4. `standing.py outline` is called by stages 3 and 4 and by
  `standing.py all` in stage 7; all now report the overlap and still fail on missing data. No other caller of the changed
  constants or test helpers. `death_cut_count` is still read by `fx_death.gd` itself; only the tests stopped asserting it.
- Saves: no player profile or run save field was changed. The save and campaign suites in the standing checks and the 30
  seeded campaign parity runs pass, including the cross-twin save hand-off.
- Twins: no change to `battle.js`, `data.js` or `core.js`, so no table re-export was needed. `oracle_copy_test`, rules
  parity and campaign parity all pass.
- UI: no displayed value changed. Campaign, intel, panels and HUD read none of these check constants.
- CI: no new test file, so `run_all_checks.js` is unchanged. The four modified Godot tests already have their lines in
  `godot/tools/ci/godot_checks.txt` (`audio/test/audio_check.gd`, `fx/test/death_leap_check.gd`,
  `fx/test/destruction_staging_check.gd`, `fx/test/destruction_steps_check.gd`), so the Godot game checks run them. The
  push also runs the standing checks, rules parity, campaign parity, tree hand-off and Nemesis scenarios.

## Left alone, and notes

- `contrib/opus/tools/ui_spec_tests.js` MIN_TEXT stays 12 (PR 544 owns it).
- `contrib/opus/tools/checks_baseline.json` is untouched. Its `driftDifferedCeiling` is 12.
- No files in open pull requests 524, 536, 543, 544 or 547 were touched. The other open PRs 562, 570 and 571 were also
  avoided.
- No screenshots: the job's own done-when says nothing changes on screen, and no picture is linked here. The out/shots
  folder is created empty for the runner.
- Godot prints a pre-existing `get_meta` error about `death_timeline` from `godot/fx/fx.gd:1087` during death setup on
  these tests. It is not caused by this change (that file is untouched) and the tests exit 0.
