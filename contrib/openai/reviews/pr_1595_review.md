# PR 1595 review: shield drops, damage timing and wings lost

## Ranked findings

Reviewed PR head `469d072ec3c7`, against merge base `1a000813476a` (`origin/main` at `d16c734b6d58`). Verdict: hold for fixes. Line references are to the raw Git blobs at the PR head.

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Fix | Confidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | One collapse sends two shield breaks | OBSERVED | `godot/rules/rules.gd:3248,6586` | `shieldDrained(t, shM)`; `shieldDrained(x, shN, quad)` | A legal nova that breaks still-shielded midships sent two `shield_down` events for the same ship. Playback handles each separately. Spread Pattern, Corona splash and station fire use the same two paths. | Make one per-hit path own the break, or guard each post-hit call against a break already emitted for that unit during `applyHit`. Test a collapse caused by the section, with shields remaining after the direct spend. | High |
| 2 | Generator collapse misses its volley impact | OBSERVED | `godot/rules/rules.gd:3240`; `godot/scenes/battle/battle.gd:1291` | `"t": "section_down"`; `["hit", "system", "shield_down", "burning"]` | In a two-hit rules volley the scene grouped only the first hit. The break and the second hit fell into standalone playback after the volley call instead of playing on their shot impacts. | Carry the break on the actual hit or give it a shot index and keep it attached through section and log events. Check a multi-hit batch that breaks the generator before the last shot. | High |
| 3 | Illegal nova aim still consumes the ability | OBSERVED | `battle.js:2116`; `godot/rules/rules.gd:6506` | `onBoard(arg.hex.q,arg.hex.r)`; `onBoard(c.q, c.r)` | Both probes accepted an adjacent hex behind the ship, counted one use and spent the undo. The legal aim is the prow arc at range 3 to 9. UI and AI normally supply legal aim, so seeded parity misses this. | Match against `novaTargets(u)` in both twins before spending anything. Test off-arc, out-of-range, fractional and malformed inputs, and a legal shot. | High |
| 4 | Scene test starts two battles on one instance | OBSERVED | `godot/scenes/battle/test/battle_feedback_1481_check.gd:68-69`; `godot/scenes/battle/battle.gd:242-243` | `root.add_child(b)`; `await b._begin(api)`; `start_default()` | Adding the node starts the default battle before the test starts its own. Both initializations appeared in the local log. That test can report green while exercising concurrent setup. | Set `b.external = true` before entering the tree, as the campaign does, then feed the test's single API into `_begin`. | High |

Recommended next step: fix the break producers and timing together, then align nova validation with the shared target list and rerun the impact tests, both parities and CI.

## `battle.js`

**OBSERVED - defect.** At line 2116, `onBoard(arg.hex.q,arg.hex.r)` admits positions outside the nova targeting list, including fractional positions. Reject any target not in `novaTargets(u)` before side effects. The storm clamp and the ram spend match Godot's state math for valid play; line 906 still duplicates the spend and should call the new helper so the two JS paths stay together.

## `contrib/opus/tools/rules_1481_tests.js`

**OBSERVED - defect.** Line 64 exercises `await E('useAbility')(u, null)` only for nova, so it passes while an illegal on-board target can still spend the shot. Add positive legal aim and rejected off-arc, fractional and malformed aim cases, with usage, undo and cooldown assertions, in both test files.

## `contrib/opus/tools/run_all_checks.js`

**OBSERVED - sound.** The standing list registers `rules_1481_tests` at line 149 alongside the other Node checks.

## `godot/rules/rules.gd`

**OBSERVED - defects.** `applyHit` can already emit a drop via `damageSection` before its caller invokes `shieldDrained` with the old positive pool. Nova, station batteries, Spread Pattern and Corona splash all have this double-emission path. Use one per-hit break source or deduplicate against a mark taken before each `applyHit`. Nova validation at line 6506 should also use `novaTargets(u)` before any side effects. For ram, the event stores a shield snapshot before section damage and then sends the break itself if soak depleted the pool; mid-section damage after a partial soak is a separate route to a break. The three quiet-hit sites use the existing hit event shape and suppress the normal number.

## `godot/rules/test/rules_1481_test.gd`

**OBSERVED - defect.** Line 111 calls nova after setting `t["shp"] = 2` (line 109); it never forces the still-shielded target's mid section to fail. Add a nova or secondary-hit case with shields surviving the direct spend and a 1 HP mid section; require exactly one drop. The bad-nova case at line 182 checks only `R.useAbility(u, null)`; mirror the rejected-aim cases from the browser test.

## `godot/rules/test/saved/changes.txt`

**OBSERVED - sound.** The 31 listed state deltas match the decompressed old and new archives. Each first changed row adds a ram to the log and removes a `route` bit on a target with a zero pool in both versions. Later state differences range from 1 to 204 rows; no record count, action label, PRNG sequence or final result changed in these 31. This is a before/after report, so its `FAIL` labels are expected; the refreshed manifest passed the fresh run. The pilot does not compare battle presentation events.

## `godot/rules/test/saved/records/s12.jsonl.br`

**OBSERVED - sound.** JSONL row 45, x08 `route[0]` 1 to 0; 1 later row changed, 176 rows, `end win`.

## `godot/rules/test/saved/records/s17.jsonl.br`

**OBSERVED - sound.** JSONL row 74, x08 `route[0]` 1 to 0; 11 later rows changed, 98 rows, `end loss`.

## `godot/rules/test/saved/records/s18.jsonl.br`

**OBSERVED - sound.** JSONL row 57, x010 `route[0]` 1 to 0; 4 later rows changed, 274 rows, `end loss`.

## `godot/rules/test/saved/records/s21.jsonl.br`

**OBSERVED - sound.** JSONL row 77, x012 `route[0]` 1 to 0; 7 later rows changed, 183 rows, `end win`.

## `godot/rules/test/saved/records/s23.jsonl.br`

**OBSERVED - sound.** JSONL row 623, x025 `route[3]` 1 to 0; 20 later rows changed, 656 rows, `end loss`.

## `godot/rules/test/saved/records/s25.jsonl.br`

**OBSERVED - sound.** JSONL row 230, x09 `route[1]` 1 to 0; 22 later rows changed, 334 rows, `end loss`.

## `godot/rules/test/saved/records/s30.jsonl.br`

**OBSERVED - sound.** JSONL row 107, x010 `route[0]` 1 to 0; 204 later rows changed, 311 rows, `end win`.

## `godot/rules/test/saved/records/s36.jsonl.br`

**OBSERVED - sound.** JSONL row 157, x020 `route[0]` 1 to 0; 23 later rows changed, 206 rows, `end win`.

## `godot/rules/test/saved/records/s37.jsonl.br`

**OBSERVED - sound.** JSONL row 180, x09 `route[0]` 1 to 0; 116 later rows changed, 296 rows, `end win`.

## `godot/rules/test/saved/records/s49.jsonl.br`

**OBSERVED - sound.** JSONL row 27, x05 `route[0]` 1 to 0; 165 later rows changed, 197 rows, `end none`.

## `godot/rules/test/saved/records/s983_station_plain.jsonl.br`

**OBSERVED - sound.** JSONL row 13, x09 `route[0]` 1 to 0; 18 later rows changed, 87 rows, `end win`.

## `godot/rules/test/saved/records/t529_roles_change.jsonl.br`

**OBSERVED - sound.** JSONL row 28, x08 `route[0]` 1 to 0; 61 later rows changed, 89 rows, `end none`.

## `godot/rules/test/saved/records/t529_scent.jsonl.br`

**OBSERVED - sound.** JSONL row 40, x08 `route[0]` 1 to 0; 7 later rows changed, 53 rows, `end win`.

## `godot/rules/test/saved/records/t7a_grandledger.jsonl.br`

**OBSERVED - sound.** JSONL row 25, x06 `route[0]` 1 to 0; 6 later rows changed, 57 rows, `end win`.

## `godot/rules/test/saved/records/t7a_screensshift.jsonl.br`

**OBSERVED - sound.** JSONL row 33, x05 `route[0]` 1 to 0; 9 later rows changed, 47 rows, `end win`.

## `godot/rules/test/saved/records/t7b_ecl_archive.jsonl.br`

**OBSERVED - sound.** JSONL row 37, x09 `route[0]` 1 to 0; 4 later rows changed, 107 rows, `end none`.

## `godot/rules/test/saved/records/t7b_ecl_formation_b.jsonl.br`

**OBSERVED - sound.** JSONL row 58, x011 `route[0]` 1 to 0; 30 later rows changed, 88 rows, `end win`.

## `godot/rules/test/saved/records/t_debthunts.jsonl.br`

**OBSERVED - sound.** JSONL row 42, x03 `route[0]` 1 to 0; 5 later rows changed, 53 rows, `end win`.

## `godot/rules/test/saved/records/t_ecl_uncopiedtarget.jsonl.br`

**OBSERVED - sound.** JSONL row 53, x09 `route[0]` 1 to 0; 16 later rows changed, 69 rows, `end win`.

## `godot/rules/test/saved/records/t_flagshipLedger.jsonl.br`

**OBSERVED - sound.** JSONL row 24, x05 `route[0]` 1 to 0; 2 later rows changed, 34 rows, `end win`.

## `godot/rules/test/saved/records/t_hb_knifeback.jsonl.br`

**OBSERVED - sound.** JSONL row 25, x07 `route[0]` 1 to 0; 15 later rows changed, 40 rows, `end win`.

## `godot/rules/test/saved/records/t_hb_mawopens.jsonl.br`

**OBSERVED - sound.** JSONL row 25, x07 `route[0]` 1 to 0; 29 later rows changed, 54 rows, `end win`.

## `godot/rules/test/saved/records/t_hb_preyscent.jsonl.br`

**OBSERVED - sound.** JSONL row 44, x08 `route[0]` 1 to 0; 11 later rows changed, 55 rows, `end win`.

## `godot/rules/test/saved/records/t_hb_runbigger.jsonl.br`

**OBSERVED - sound.** JSONL row 25, x07 `route[0]` 1 to 0; 9 later rows changed, 34 rows, `end win`.

## `godot/rules/test/saved/records/t_hb_rushrail.jsonl.br`

**OBSERVED - sound.** JSONL row 27, x08 `route[0]` 1 to 0; 53 later rows changed, 80 rows, `end win`.

## `godot/rules/test/saved/records/t_hb_smilecut.jsonl.br`

**OBSERVED - sound.** JSONL row 27, x07 `route[0]` 1 to 0; 10 later rows changed, 37 rows, `end win`.

## `godot/rules/test/saved/records/t_hb_trophystandard.jsonl.br`

**OBSERVED - sound.** JSONL row 15, x03 `route[0]` 1 to 0; 11 later rows changed, 35 rows, `end win`.

## `godot/rules/test/saved/records/t_holdcounted.jsonl.br`

**OBSERVED - sound.** JSONL row 24, x05 `route[0]` 1 to 0; 2 later rows changed, 40 rows, `end win`.

## `godot/rules/test/saved/records/t_oathstillness.jsonl.br`

**OBSERVED - sound.** JSONL row 33, x05 `route[0]` 1 to 0; 8 later rows changed, 41 rows, `end win`.

## `godot/rules/test/saved/records/t_oathwings.jsonl.br`

**OBSERVED - sound.** JSONL row 56, x03 `route[0]` 1 to 0; 5 later rows changed, 72 rows, `end win`.

## `godot/rules/test/saved/records/t_throatspits.jsonl.br`

**OBSERVED - sound.** JSONL row 136, x03 `route[3]` 1 to 0; 5 later rows changed, 141 rows, `end loss`.

## `godot/rules/test/saved/results.json`

**OBSERVED - sound.** Only the 31 matching battle hashes changed. Verified old and new Brotli data against manifest lengths and hashes, parsed each row, verified state hashes, and confirmed unchanged scenario hashes and auxiliary records. The live saved-results check passed all 288.

## `godot/scenes/battle/battle.gd`

**OBSERVED - defect.** At line 1291, `["hit", "system", "shield_down", "burning"]` ends the volley group at `section_down`. The probe fed events from `landVolley` into `_play_batch` and saw the break and next hit take the standalone path. Carry the break on the actual hit or explicitly associate it with its shot slot across section and log events. Standalone pool clearing, quiet-hit number suppression, and the end tally itself are sound.

## `godot/scenes/battle/test/battle_feedback_1481_check.gd`

**OBSERVED - defect.** Lines 68-69 start the default battle and the probe battle on the same instance (finding 4). Line 81 calls `await b._play_event({"t": "shield_down", "unit": t, "quad": 0})` directly, bypassing real volley grouping. Set external mode before adding the node, then drive a real multi-hit rules volley through the batch player and check the hit and break arrive together, once.

## `godot/tools/ci/godot_checks.txt`

**OBSERVED - sound.** Both Godot tests have executable `headless` entries at lines 72 and 82.

## Impact sweep

- Callers: searched the PR tree for both clamp/spend helpers, Godot break and hit producers/consumers, blink and nova callers, forecasts, `end_tally`, and the returned counts. The previews still quote damage absorbed by the ram rather than pool points lost to routing. The end result counts feed the banner and bot summary; campaign settlement has its own ship-only tally.
- Saves: no new persisted fields. `ram.sh` and `hit.float` are presentation events, outside the round snapshot. Same-build cold round restore passed for battle, elite, ambush and event. I then wrote a real profile and round 2 save on `1a000813476a` and loaded it on PR 1595. The old fingerprint correctly sent Continue to the map; the old run could enter battle again at round 1. Campaign parity also passed the cross-twin saved-run hand-off.
- Twins: valid blink, ram routing and storm clamp agree. Flare assigns zero and ion pulse floors in both. Nova and blink use the same target lists in UI/AI; the illegal nova case is shared too. The browser only mirrors the shield state, while Godot owns the new playback events. Both table exports matched; no repo files were regenerated by this review.
- UI: checked battle plates, ram forecast, shield break playback, target overlays, end banner, report toast, campaign wrap-up and debrief/career count sources. Map and intel have no reader for the transient `ram.sh`, `hit.float` or banner tally. Findings 1 and 2 affect what the battle player sees and hears.
- CI: PR head was green for Standing checks, Godot rules and campaign parity, Godot-only rules safety, Godot game checks, A16 death seam, and All checks. CI runs the JS test through `run_all_checks.js` and both Godot tests through `godot_checks.txt`. The docs-only review itself gets the standing checks.

## Checks run on the PR head

Compared `origin/main...pr1595`; `git diff --check` exited 0. I tested the pinned PR tree in temp with isolated Godot profiles. The following are local result lines:

```text
Issue 1481 rules tests (battle.js): 5 ok, 0 FAIL
Issue 1481 rules tests (rules.gd): 15 ok, 0 FAIL
battle_feedback_1481_check: PASS (0 failures)
PASS  other rules: Continue opens the map checkpoint, the stop can be entered again (page map)
PASS  failed write: Continue opens the map checkpoint, nothing settled (page map)
PASS  old main writes a real profile and round 2 save
PASS  PR receives a real round save with the old rules fingerprint
PASS  PR Continue loads old profile and returns to its playable map checkpoint
PASS  the old run enters battle again at round 1
PASS: saved Godot results; 288 battles checked, 0 changed, 0 other files changed, 0 failures; 21.322 s
PASS: the Godot port matches the game's rules exactly.
PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.
PASS: 31 saved changes checked against both manifests, every first change removes a route bit
PASS: all 41 changed files have ASCII per-file verdicts
PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files
FAIL: one nova mid-section collapse, 2 shield_down events: [{ "t": "shield_down", "unit": "x03", "quad": 0 }, { "t": "shield_down", "unit": "x03", "quad": 1 }]
FAIL: off-arc nova accepted=true, counted=1, undo spent=true
FAIL: browser off-arc nova accepted=true, counted=1, undo spent=true
FAIL: mid-section volley grouped=["hit"], standalone=["section_down", "shield_down", "float", "log", "hit", "float", "float", "float", "log"]
```

The first scratch nova probe lacked a sector in its setup and timed out; the corrected probe produced the two Godot FAIL lines. The initial headless import call timed out. After it built the imports needed by the probe, the scene check ran to completion. Its own assertions passed, with placeholder hulls, a headless layout error and resource cleanup diagnostics in the local log; this is not an installed-game visual pass. The full standing and Godot game packs were checked on GitHub rather than repeated locally.

## Raw file evidence

The comparison and line counts use raw Git blobs rather than the rendered GitHub diff. Last-line prefixes below are JSON strings so leading tabs and embedded quotes are visible. For each archive above, its line count is the decompressed row count; the matching last-line prefixes are below. The archive review parsed every decompressed line and checked both old and new hashes.

| Text file | Lines | Final line, first 40 characters |
| --- | ---: | --- |
| `battle.js` | 2390 | `"}"` |
| `contrib/opus/tools/rules_1481_tests.js` | 75 | `"})();"` |
| `contrib/opus/tools/run_all_checks.js` | 301 | `"module.exports = { classifyFindings, cla"` |
| `godot/rules/rules.gd` | 7286 | `"\tB[\"aiActive\"] = null; u[\"activated\"] = "` |
| `godot/rules/test/rules_1481_test.gd` | 184 | `"\treturn [not ok and counted == 0 and evs"` |
| `godot/rules/test/saved/changes.txt` | 130 | `"FAIL: saved Godot results; 288 battles c"` |
| `godot/rules/test/saved/results.json` | 2064 | `"}"` |
| `godot/scenes/battle/battle.gd` | 6339 | `"\tget_tree().quit(code)"` |
| `godot/scenes/battle/test/battle_feedback_1481_check.gd` | 103 | `"\tquit(1 if failures > 0 else 0)"` |
| `godot/tools/ci/godot_checks.txt` | 211 | `"headless\|main/test/player_path_map_ready"` |

Large source review ranges (PR line numbers, changed hunks and call-site context):

- `battle.js`: 101-123, 444-455, 895-909, 1147, 1214-1234, 2107-2157, 2289-2302, 2377-2378, and EOF.
- `godot/rules/rules.gd`: 38-50, 460-479, 1708-1727, 2636-2647, 3085-3259, 3477-3517, 3688-3739, 3760-3841, 4031-4044, 4124-4136, 6462-6524, 6549-6594, 7046-7111, 7261-7271, and EOF.
- `godot/scenes/battle/battle.gd`: 225-249, 1225-1405, 1474-1516, 1559-1569, 2090-2160, 2288-2305, 2335-2505, 2637-2684, 3354-3400, 4579-4586, 5790-5820, and EOF.
- `godot/rules/test/saved/results.json`: parsed lines 1-2064 as JSON, compared changed hashes and checked the matching archive set.

Final decompressed row prefixes, in the same order as the per-file verdicts:

```text
s12                    {"actor":"end win","hash":"d79f6483abe20
s17                    {"actor":"end loss","hash":"a3ac6189ba4a
s18                    {"actor":"end loss","hash":"93d12bda38ce
s21                    {"actor":"end win","hash":"e17deb2ff067f
s23                    {"actor":"end loss","hash":"82cc37a56278
s25                    {"actor":"end loss","hash":"d72526544e99
s30                    {"actor":"end win","hash":"0bc7c028cf55c
s36                    {"actor":"end win","hash":"06a9dd470136e
s37                    {"actor":"end win","hash":"f8f336bbdd060
s49                    {"actor":"end none","hash":"9b65654e0b6b
s983_station_plain     {"actor":"end win","hash":"85ed44c981adc
t529_roles_change      {"actor":"end none","hash":"9e61d4b72e45
t529_scent             {"actor":"end win","hash":"08eb460d867ba
t7a_grandledger        {"actor":"end win","hash":"b0a151afc638f
t7a_screensshift       {"actor":"end win","hash":"a5ac3dfea2224
t7b_ecl_archive        {"actor":"end none","hash":"aa6bfb3a4f05
t7b_ecl_formation_b    {"actor":"end win","hash":"679503ad9d41c
t_debthunts            {"actor":"end win","hash":"62ded0866fd68
t_ecl_uncopiedtarget   {"actor":"end win","hash":"ea2cd1745979a
t_flagshipLedger       {"actor":"end win","hash":"480e32a5a6eb7
t_hb_knifeback         {"actor":"end win","hash":"5256445fe1bb0
t_hb_mawopens          {"actor":"end win","hash":"f6ac3cfdc5d80
t_hb_preyscent         {"actor":"end win","hash":"0512efb364295
t_hb_runbigger         {"actor":"end win","hash":"52ad61e3be8f4
t_hb_rushrail          {"actor":"end win","hash":"2c984843d0c2b
t_hb_smilecut          {"actor":"end win","hash":"73c5ad02e99f1
t_hb_trophystandard    {"actor":"end win","hash":"b73c0583f36e0
t_holdcounted          {"actor":"end win","hash":"767e1dd4c7ded
t_oathstillness        {"actor":"end win","hash":"02cc9bc3e3143
t_oathwings            {"actor":"end win","hash":"39384f1900543
t_throatspits          {"actor":"end loss","hash":"c41762ea6ff5
```

## Not checked

No GPU capture, installed ship models, or human playthrough. No real player save or profile was opened. The 31 saved records cover rules state and RNG; the targeted event probes cover the findings above, not every presentation event in all 288 battles. The gameplay review is limited to PR hunks and their callers.
