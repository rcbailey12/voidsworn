# Codex review of PR 1643

**Review against** `origin/main` at `85d380a52e20d08bb15af46f021e278ab48baf1c`, using the three-dot merge base `adda5beed634890679252aa90972f96a5b1763bb` and PR head `999da9df610a2a52ad1d9d106289d5bac16cd100`. The pinned local diff and GitHub agree on all nine changed files.

**Hold PR 1643 for the plan and turn fixes.** The ordinary move and volleys share one playback batch, but a stale target can commit a move without the intended volley and Q/E can execute a free turn before the player commits.

| # | Finding | Evidence | File and line | Exact quote | Why it matters | Fix | Confidence |
|---:|---|---|---|---|---|---|---|
| 1 | Replacing Burn and fire leaves a false confirmation target | OBSERVED | `godot/scenes/battle/battle.gd:4202`, `:4184` | `atk = null` / `if target == u["id"] or _aimed(str(u["id"])):` | Click an out-of-range enemy to stage Burn and fire, then click a reachable hex from which that enemy can be hit. The blue-hex branch drops `atk` but leaves `target` when `aims` is empty (`:4290`). The next enemy click commits a move with zero picks instead of adding the first pick. | Clear the old focus when replacing an attack plan. Confirm an enemy click only if it is a live attack-move target or an actual entry in `aims`. Preserve the previous attack plan in the Backspace snapshot. | High |
| 2 | Q/E spends an earned free turn before commit | OBSERVED | `godot/scenes/battle/battle.gd:3916` | `if _cmd(func(): return api.rotate(rid, d)):` | With a tree free turn and the pointer off other reachable hexes, the free-turn branch skips staging and runs a rules command. It consumes the token and can clear shots already planned from the ship's original facing. Backspace then uses the rules undo path, where available. | Stage the free pivot as a UI step, revalidate aims from its facing, and call `api.rotate` inside the same commit batch before firing. Retain R397's zero-movement and post-fire behavior. | High |
| 3 | Committing a turn in place invokes move rules | OBSERVED | `godot/scenes/battle/battle.gd:4372` | `if not api.move(id, st):` | An ordinary planned pivot now enters `moveUnit` rather than `rotateUnit`. That increments `B["usage"]["moves"]` and runs move-only hooks and objective checks (`godot/rules/rules.gd:1913`, `:1922`, `:1932`), unlike base Godot and browser Q/E (`ui3d.js:513`). The outcome can differ even though both engines' rules files are unchanged. | Commit pure rotations with the existing rotate rules and include their events in the same batch as planned fire. Use `api.move` for paths that actually travel. Check the pure-pivot result against the browser rotation. | High |
| 4 | Ghost rings can light targets that have no selectable gun | OBSERVED | `godot/scenes/battle/battle.gd:3254` | `if w["ready"] and w["kind"] != "flak" and api.in_reach(sel, int(w["i"]), e["id"], pst):` | The ring fallback uses every ready gun. `_firing_set` honors the armed slot and guns already assigned to other picks. An unpicked enemy can be lit when clicking it cannot add any gun to the plan. | Use the same selectable set for plain-plan rings, the card and click handling. Keep a separate lock ring for already aimed enemies and apply the attack plan's own set in Burn and fire. | High |
| 5 | Clicking a turn-in-place ghost cancels it | OBSERVED | `godot/scenes/battle/battle.gd:4162` | `_cancel("click")` | An in-place ghost shares the actor's hex. The friendly-unit branch handles that click before the planned-hex confirm at `:4196`, despite the on-screen instructions. | Handle a click on the exact planned hex before the same-ship cancel branch. Keep the normal cancel behavior when the clicked ship is away from the ghost. | High |
| 6 | The flanking forecast names the current shield side | OBSERVED | `godot/scenes/battle/battle.gd:4759`, `:4794` | `quad = int(tg.get("quad", quad))` / `From current position (move not taken yet).` | `_attack_tip` reads the quadrant and rear flag from the current position before merging the ghost's volley preview. A flanking plan can list ghost-based damage beside the old shield side and rear-arc bonus, and label all of it as current-position odds. | Take the shield side, rear flag and geometry from the same ghost source as the volley, and label the tooltip with that source. | High |
| 7 | Campaign Help still sends players to the wrong keys | OBSERVED | `godot/ui/campaign/campaign_ui.gd:1955` | `Enter end turn` | Enter commits the plan, Space ends the ship, and clicking an enemy aims a volley. The same Help row still lists A for firing arcs while the scene uses V (`godot/scenes/battle/battle.gd:3835`). | Bring the Help keys and firing text into line with the battle controls. | High |
| 8 | The new check requires early free-turn mutation | OBSERVED | `godot/scenes/battle/test/plan_commit_check.gd:138` | `with a free turn earned, Q/E turn through the rules at once and spend no movement` | The check passes only if the free turn bypasses the plan, so the test misses finding 2 by design. Target picks also bypass `_on_click` (`:168`, `:205`). | Assert that Q/E and Backspace preserve the rules and token until commit. Exercise first and second target clicks on the board, including replacement of a Burn and fire plan. | High |
| 9 | The picture probe can label a turn and undo that did not happen | INFERRED | `godot/tools/probes/plan_commit_1589_shots.gd:188` | `if b.plan != keep:` | If the ghost cannot change facing, the probe skips Backspace but captures both the turn and undo frames with success labels. Output existence alone can still make the probe pass. | Require a different facing after E and restoration after Backspace. Fail that capture when either condition is false. | High |

## `contrib/opus/FINDINGS.md`

**OBSERVED: Sound as a ruling record.** R403 at line 431 records Ryan's words and picks and names both landing documents. The statement that the implementation is UI only still depends on resolving finding 3.

## `docs/RULEBOOK.md`

**OBSERVED: Defect (findings 2 and 3).** Line 863 says `Nothing reaches the rules until the commit`; line 868 says `UI only: no rule changes`. Free turns execute on Q/E, and ordinary planned pivots commit as rules moves. Keep those turns in the plan and preserve rotation semantics at commit.

## `docs/playbooks/screens.md`

**OBSERVED: Defect (findings 3 and 5).** Line 108 describes a `second click on the planned hex or a picked enemy` as a commit, and describes `api.move` as the route before fire. Handle the ghost's own hex as a confirm, and document and use the rules' rotate path for a pure turn.

## `godot/scenes/battle/battle.gd`

**OBSERVED: Defects (findings 1 to 6).** The main move-plus-fire path enqueues a single ordered batch. The regressions concern stale focus after replacing a Burn and fire plan, Q/E applying a tree free turn early, pure turns using the move rules, ghost rings bypassing the selectable weapon set, clicking an in-place ghost cancelling it, and the flanking tooltip mixing the current and planned positions.

## `godot/scenes/battle/test/plan_commit_check.gd`

**OBSERVED: Defect (finding 8).** Line 138 expects that `Q/E turn through the rules at once and spend no movement`. This locks in the premature rules change from finding 2. Assert no rule changes after Q/E and Backspace, then assert the free turn is consumed at commit. Route the target selections through the board click handler to cover finding 1.

## `godot/tools/ci/godot_checks.txt`

**OBSERVED: Sound.** Line 86 registers the new scene test once as a standalone `headless` check, consistent with Rulebook 12.3. Its path resolves at the reviewed commit.

## `godot/tools/probes/plan_commit_1589_shots.gd`

**INFERRED: Defect (finding 9).** At line 188, `if b.plan != keep:` allows the advertised turn and undo pictures to be taken even if the ghost never turned. Require a changed facing and verify that Backspace restores it before saving the strip.

## `godot/ui/battle/hud.gd`

**OBSERVED: Defect (finding 5).** Line 481 promises `Click the hex or a target again`. Clicking the actor on an in-place ghost's hex cancels the plan. Make that click confirm so the help holds for both kinds of ghost plan.

## `godot/ui/campaign/campaign_ui.gd`

**OBSERVED: Defect (finding 7).** Line 1955 says `Enter end turn`. The scene commits a pending plan with Enter and ends the ship with Space. The same Help section still says `Click a target to fire all bearing weapons` at line 1948. Update the Help section to teach aiming, committing and ending the ship.

## Evidence from the requested battle paths

- **OBSERVED, ordinary plan and undo.** The PR headless plan check passed all 21 assertions. The first move click, both target picks, Backspace, and Esc leave the rules view unchanged in that fixture. The commit produces one batch with movement first and fire for both picks. The same test also reproduced the free-turn exception in finding 2.
- **OBSERVED, input regressions.** Headless scene probes reproduced findings 1, 3, 4, 5 and 6. After replacing Burn and fire, the first click on the old target committed the move with zero fire events. An ordinary committed pivot incremented the move counter from 0 to 1. A ghost ring was lit with no gun eligible for the current armed slot. Clicking the ghost on its own hex cleared it without applying the turn. For a planned flanking shot, the tooltip named the prow shield even though the ghost was lined up on the port shield.
- **OBSERVED, Save and Quit mid-plan.** The checked-in save handoff test and a scratch extension passed. The extension opened a real move plan before Save and Quit, compared the live rules view and saved round bytes, then continued from the saved payload in a fresh battle scene with no pending plan. That matches the round-start checkpoint contract in Rulebook 9.18.
- **OBSERVED, Glasswright slip.** In a deterministic battle scene with the selected unit set to the Glasswright faction, committing a shot left movement available. A side-slip click staged the move without spending that allowance. Enter landed the ship on the planned hex and spent the allowance.
- **OBSERVED, enemy activation.** A headless call through the scene's enemy worker received a single batch for an activation with movement and fire by the same enemy. The unchanged playback loop passes that batch through one `_play_batch` call and looks ahead from movement to fire within it.
- **OBSERVED, rules copies.** The PR changes no browser or Godot rules files. The #1560 checks passed in both copies (28 Godot and 23 browser assertions). The rules calls for a committed pivot still differ at the UI boundary, as shown in finding 3.
- **OBSERVED, standing checks.** `git diff --check origin/main...999da9df` passed. The Node 22 standing suite on the review checkout, run with the normal Windows PATH and `--jobs 4`, returned 98 PASS, 2 KNOWN, and 8 FAIL. The failed rows were `auto_pr_body_tests`, `godot_shard_tests`, `picture_provenance_tests`, `pysite_1535_tests`, `runner_cleanup_tests`, `runner_selftest`, `g2_export_selftest`, and `stage5_fail_selftest`. This was a check of the review checkout, separate from the headless tests on the PR head.

## Source inspection

Each file was opened as a raw blob at the pinned PR head. These are the lines reviewed in detail, including the changed areas and the end of each file.

- `contrib/opus/FINDINGS.md`: 582 lines. Last line starts with `| X17 | Muse follow-up pass over unasses`. Reviewed 428-434, 582.
- `docs/RULEBOOK.md`: 992 lines. Last line starts with `draws meshes at full detail. Set: Ryan, `. Reviewed 15-105, 180-282, 728-764, 856-875, 965-992.
- `docs/playbooks/screens.md`: 291 lines. Last line starts with `well-specified follow-ups (a string, a t`. Reviewed 94-115, 291.
- `godot/scenes/battle/battle.gd`: 6740 lines. Last line starts with `	get_tree().quit(code)`. Reviewed 9-15, 190-207, 552-566, 940-1018, 1265-1369, 2880-3045, 3154-3389, 3578-3588, 3732-3937, 3940-3951, 3996-4054, 4100-4484, 4739-4803, 4931-4952, 5084-5102, 5240-5421, 5858-5865, 5989-6009, 6108-6139, 6740.
- `godot/scenes/battle/test/plan_commit_check.gd`: 235 lines. Last line starts with `	quit(0 if fails == 0 else 1)`. Reviewed 1-235.
- `godot/tools/ci/godot_checks.txt`: 233 lines. Last line starts with `headless|main/test/player_path_map_ready`. Reviewed 78-89, 233.
- `godot/tools/probes/plan_commit_1589_shots.gd`: 242 lines. Last line starts with `	quit(0 if failed == "" else 1)`. Reviewed 1-242.
- `godot/ui/battle/hud.gd`: 1519 lines. Last line starts with `	ledger.mark()`. Reviewed 478-483, 1519.
- `godot/ui/campaign/campaign_ui.gd`: 2598 lines. Last line starts with `				Kit.play(Kit.press_cue(cue_role(str(`. Reviewed 1943-1961, 2598.

**Recommended next step.** Fix the target and turn paths before merging, and rerun the scene check through board clicks with an earned free turn and a replaced Burn and fire plan.

**Not checked.** The visual appearance at camera 170, GPU capture output and provenance files. This lane used headless Godot with fallback hulls for logic checks. No visual acceptance result is claimed.

## Run 2 (5b928b4a)

Reviewed PR head `5b928b4acfbb2933dc729673c60d8c2ab910b3b6` against `origin/main` at `bc06e33e51f5643aded26b01b493f4c4155c00ac`, using merge base `766bb2d1565bc0eb9c3fbc0b295f4346afde764b`. The nine-file diff is from the pinned local commit.

**Hold PR 1643.** The normal free turn waits for commit. With Burn and fire staged, E still spends that turn immediately and clears the draft. A separate fixture also exposed a two-step pivot that stops before its planned volley.

| # | Run 1 finding | Verdict | Evidence at `5b928b4a` |
|---:|---|---|---|
| 1 | Stale target after replacing Burn and fire | **Fixed / OBSERVED** | `godot/scenes/battle/battle.gd:4231` to `:4234` clears `target = ""` on replacement, after taking the Backspace snapshot. Line 4213 confirms only for `(atk != null and target == u["id"]) or _aimed(str(u["id"]))`. |
| 2 | Q/E spends an earned free turn before commit | **Partly fixed / OBSERVED** | `godot/scenes/battle/battle.gd:3883` to `:3897` stages an ordinary in-place turn, and `:3944` copies the unit. With Burn and fire open, `:3883` excludes the plan and `:3916` can still execute `if _cmd(func(): return api.rotate(rid, d)):`. See the blocking finding below. |
| 3 | A pure turn goes through move rules | **Fixed / OBSERVED** | `godot/scenes/battle/battle.gd:4394` to `:4396` clears the move state for a rotation plan. Line 4421 commits it with `if not api.rotate(id, signi(rot)):`. |
| 4 | Plain-plan rings advertise unavailable guns | **Fixed / OBSERVED** | `godot/scenes/battle/battle.gd:3199` uses `not _firing_set(e["id"]).is_empty()`; `:3251` to `:3252` skips the orange fallback when a plain plan exists. The picked-target locks still come from `aims` at `:3267`. |
| 5 | Clicking an in-place ghost cancels it | **Fixed / OBSERVED** | `godot/scenes/battle/battle.gd:4188` to `:4189` checks the ghost at the ship's hex and calls `_confirm()` before the cancel branch. |
| 6 | Flanking forecast uses the current shield side | **Fixed / OBSERVED** | `godot/scenes/battle/battle.gd:4840` to `:4842` passes `api.R.stateView(ru, plan)` to the shield-side and rear calculations. Line 4851 identifies the ghost as the source. |
| 7 | Campaign Help teaches the old controls | **Partly fixed / OBSERVED** | `godot/ui/campaign/campaign_ui.gd:1948` teaches aiming and committing, and `:1955` says `Space ends the ship` and `V firing arcs`. Line 1946 still describes the initial Burn and fire click as firing on arrival and leaves out the commit. Add the second click or Enter to that instruction. |
| 8 | Scene check expects the wrong free-turn behavior and bypasses clicks | **Partly fixed / OBSERVED** | `godot/scenes/battle/test/plan_commit_check.gd:147` to `:157` checks the staged turn and commit; `:187` calls `_click_unit(e)`. The fixture excludes the original stale target with `e not in picks` at `:225`, then clicks a different target at `:234`. Add the same-target case and an E press with Burn and fire open. |
| 9 | Probe can label an unchanged ghost as turned and undone | **Fixed / OBSERVED** | `godot/tools/probes/plan_commit_1589_shots.gd:185` to `:186` fails when E leaves the facing unchanged; `:190` to `:192` requires Backspace to restore it before grabbing the undo frame. |

### Remaining and new findings

| Severity | Finding | Evidence | File and line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| Blocking | E still spends the free turn while Burn and fire is staged | OBSERVED | `godot/scenes/battle/battle.gd:3883`, `:3916`, `:1014` | `if _cmd(func(): return api.rotate(rid, d)):` | A live Burn and fire draft uses `atk` with `plan == null`. When the pointer is over the target or outside the reach area, E falls through to the old command. In the headless scene the facing changed from 0 to 1, the free-turn token from 1 to 0, and movement stayed at 5. One rotation batch queued and the attack draft cleared without a commit. This violates Rulebook 9.17a at `docs/RULEBOOK.md:882` and `:885`. | Keep Q/E in the UI while the attack draft is open. Turn its ghost if the draft supports that, or leave it in place and tell the player how to replace it. Remove the immediate rotate and move fallbacks from Q/E. Cover the live attack draft in the headless scene check. | High |
| Medium | A two-step pivot can stop at the middle heading and lose its volley | OBSERVED | `godot/scenes/battle/battle.gd:4420` to `:4425`, `godot/rules/battle_api.gd:320` to `:327` and `:479` | `if not api.rotate(id, signi(rot)):` / `moved_ok[0] = any` | A headless fixture with a Chorus hull, zero movement, an earned free turn and an unused free pivot staged a 120-degree turn and aimed from its final heading. The first rotation found no shot at the middle heading, so the API ended the activation there. The commit applied 60 degrees, left the pivot unused and fired no shot. The fixture supplied the free turn directly. Campaign availability of that combination was unverified. | Defer the done check until the last planned rotation and volley have resolved, or reject the draft if the current API cannot commit both rotations. Report a partial turn explicitly if an intervening rule effect stops it. | High in the fixture |
| Low | Burn and fire Help still omits the commit | OBSERVED | `godot/ui/campaign/campaign_ui.gd:1946` | `and open fire on arrival.` | This sentence gives one click for the whole action. The first click previews the burn, and the player still has to commit. | Name the second click or Enter before stating when the guns fire. | High |

### Changed-file verdicts

| File | Verdict |
|---|---|
| `contrib/opus/FINDINGS.md` | **Sound / OBSERVED.** R403 at line 431 records Ryan's pick and names both landing documents. |
| `docs/RULEBOOK.md` | **Defect / OBSERVED.** Line 882 says `Nothing reaches the rules until the commit`. Line 885 puts the free-turn spend there too. The Burn and fire path still violates that contract. Fix the input path and keep the rule. |
| `docs/playbooks/screens.md` | **Defect / OBSERVED.** Line 105 says `a free turn is spent at the commit`. The Burn and fire path spends it early. Fix the input path so the playbook holds for both ghosts. |
| `godot/scenes/battle/battle.gd` | **Defect / OBSERVED.** The premature rotation at line 3916 is blocking. The rotate loop at line 4421 also allows the observed partial turn. |
| `godot/scenes/battle/test/plan_commit_check.gd` | **Defect / OBSERVED.** The free-turn fixture sets `b.hover = Vector2i(99999, 99999)` at line 144 before E with no attack draft. Add the staged attack case. In the stale-target fixture, assert that clicking the original Burn and fire enemy aims without committing. |
| `godot/tools/ci/godot_checks.txt` | **Sound / OBSERVED.** Line 86 registers the scene check once as a standalone headless row. |
| `godot/tools/probes/plan_commit_1589_shots.gd` | **Sound / OBSERVED.** Lines 185 to 192 guard the two facing captures. |
| `godot/ui/battle/hud.gd` | **Sound / OBSERVED.** The controls at line 481 describe the intended draft and confirmation. Clicking the ship's own ghost now confirms it. |
| `godot/ui/campaign/campaign_ui.gd` | **Defect / OBSERVED.** Line 1946 still omits the Burn and fire commit. |

### Checks

- The checked-in headless scene check passed all 27 assertions on `5b928b4a`. That includes staging and undoing a free turn, spending it without movement on the ship-hex commit, and batching the move before both planned volleys.
- A scratch headless extension verified that replacing Burn and fire with a reachable hex lets the original enemy be aimed on the next click. Two Backspaces restored the attack draft. Its commit-only assertion then failed with the attack draft open, reproducing the blocking finding.
- A second scratch headless fixture failed both assertions for the complete two-step turn and the final shot. The report describes the fixture state and the observed outcome above.
- `git diff --check origin/main...5b928b4a` passed. The requested fetch could not write `.git/FETCH_HEAD` in this checkout. The exact PR commit was already present locally and was used for the diff and the temporary headless project.

- The standing suite ran on the review checkout with Node 22 and `--jobs 4` after retrying with symlink preservation flags for a Windows path-permission error. It reported 97 PASS, 2 KNOWN and 9 FAIL. Failed rows were `auto_pr_body_tests`, `godot_shard_tests`, `picture_provenance_tests`, `pysite_1535_tests`, `runner_cleanup_tests`, `runner_stall_tests`, `runner_selftest`, `g2_export_selftest`, `stage5_fail_selftest`. This suite ran on the review checkout. The scene and scratch checks ran on the PR commit.

### Source inspection

Opened raw blobs at the pinned head. Line counts and the start of each final line follow. For the large scripts, the cited ranges cover the affected handlers and supporting paths.

- `contrib/opus/FINDINGS.md` has 586 lines and ends with `| X17 | Muse follow-up pass over unasses`. Read 428-434, 586.
- `docs/RULEBOOK.md` has 1012 lines and ends with `draws meshes at full detail. Set: Ryan, `. Read 875-895, 1012.
- `docs/playbooks/screens.md` has 294 lines and ends with `well-specified follow-ups (a string, a t`. Read 95-116, 294.
- `godot/scenes/battle/battle.gd` has 6798 lines and ends with `	get_tree().quit(code)`. Read 994-1018, 2918-3041, 3166-3270, 3765-3958, 4056-4448, 4789-4863, 5302-5342, 6048-6052, 6798.
- `godot/scenes/battle/test/plan_commit_check.gd` has 269 lines and ends with `	quit(0 if fails == 0 else 1)`. Read 1-269.
- `godot/tools/ci/godot_checks.txt` has 233 lines and ends with `headless|main/test/player_path_map_ready`. Read 83-89, 233.
- `godot/tools/probes/plan_commit_1589_shots.gd` has 245 lines and ends with `	quit(0 if failed == "" else 1)`. Read 180-196, 245.
- `godot/ui/battle/hud.gd` has 1519 lines and ends with `	ledger.mark()`. Read 478-483, 1519.
- `godot/ui/campaign/campaign_ui.gd` has 2598 lines and ends with `				Kit.play(Kit.press_cue(cue_role(str(`. Read 1941-1957, 2598.

**Recommended next step.** Keep PR 1643 on hold until the Burn and fire Q/E path stays in the draft. Rerun the scene check with that input path and the two-step turn fixture.

**Not checked.** Rendered capture quality and provenance, GPU playback, campaign acquisition of the combined free turn and free pivot, and full rules parity. Headless checks used fallback assets.
