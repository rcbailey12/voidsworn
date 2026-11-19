Run 2 report for issue 1144: shield routing only on landed hits.

**Changed files**
- `godot/rules/rules.gd`: `previewVolley` now carries the shield pool as a branch tree. Each shot has a hit branch that removes a real pool amount and a miss branch that leaves the pool alone, with the same coverage, route boost and route loss as combat. `_estimate_gun` returns the next branch set so guns and delayed torpedoes share one pool. `applyHit`, `_spend_shield` and combat are unchanged.
- `godot/scenes/battle/test/volley_preview_test.gd`: adds Artoo's low-odds case (four 30 percent shots, each strong enough to fill the facing, 60 point pool, 25 percent coverage) with 1024 seeded volleys, beside the existing 85 percent cases.
- `godot/tools/ci/godot_checks.txt`: updates the test's reason line. No new file, so no new CI line is needed.
- `contrib/openai/truth_pass_1119/README.md`: adds the run 2 section with before and after numbers.

**Before and after on the worked case**
- Run 1 code: `FAIL: low odds, pool 60, coverage 25%: preview (23.0, 77.0), actual mean (19.25195, 80.46973), tolerance (1.865916, 8.194656) (shield/hull)`
- Fixed code: `PASS: target preview matches seeded 1-, 2- and 3-gun volleys (bare, shielded and planned) and low-odds routing`

**Checks run**
- Target test, fixed tree: PASS line above.
- Target test, run 1 `rules.gd`: FAIL line above (shield preview 23, seeded mean 19.25).
- Rules parity: `PASS: the Godot port matches the game's rules exactly.`
- Campaign parity: `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`
- Standing checks: 73 PASS, 2 KNOWN, 1 FAIL. The FAIL was `runner_selftest`: `FAIL runner687: AssertionError [ERR_ASSERTION]: mock agent never reached its checkout`. It is unrelated to this change and passed twice on its own: `PASS: runner_selftest (79.28 s) | PASS runner687+722+860+985: 134 checks, Windows entry points, local Git and stub agents only.`
- Godot game checks: `PASS: every listed headless Godot check passed.` (`Ran 86 headless Godot checks in 598 s`, including `volley_preview_test: PASS (51 s)` and `onboarding_test: PASS (2 s)`). On this Windows PC I set a local `APPDATA` sandbox and a local 1800 s budget because `run_checks.sh` sets only `XDG_DATA_HOME`; the GitHub Linux job keeps its 780 s budget and its own sandbox.

**Impact review**
- Callers: only `battle.gd` calls `previewVolley` (target card and single-gun tip paths); both read the returned `shield` and `hull` unchanged. `_estimate_gun` has no callers outside `previewVolley`.
- Saves: no player profile or run save field was added or changed, so old saves load as before; the save checks in the standing and Godot suites pass.
- Twins: the preview is Godot HUD only and the root JS game has no copy of it, so `battle.js`, `core.js`, `data.js` and both tables are untouched. `oracle_copy_test` and rules parity pass.
- UI: target card, hull ghost, hover, armed gun and planned-hex paths all go through the same preview and still round to whole points; no UI file needed a change.
- CI: the extended test is already listed in `godot/tools/ci/godot_checks.txt`, so GitHub runs it in the headless Godot game job. The run 1 onboarding workflow patch stays as text in the README; run 2 needs no workflow change.

**Skipped**
- No new screenshots or look bench: the change only corrects the shield number on the target card, and the look bench does not draw the HUD. The run 1 volley shot still shows the card.
- Did not touch `campaign_run.js` or `data.js`; parity does not need a root JS change.

No commit and no push were made.