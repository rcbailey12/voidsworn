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
