# Leg: Qwen (Qwen3.8-Max, standing gate), issue 2063

Gate record: New Chat on chat.qwen.ai, already signed in. Model selector showed Qwen3.8-Max before the brief was pasted or sent, and the chat header still showed Qwen3.8-Max after generation. Brief pasted as plain text, no file attached. Single response (not comparison mode). Chat: "Godot Space Tactics Merge Review", https://chat.qwen.ai/c/70fc38eb-8572-4c78-99b6-1bb135819fae

Response verbatim:

Design-Council Review: Combined PR Analysis for Embers of the Hollow Sun
Reviewer: Leg 3 (effects and sprite-kind integrity)
Evidence date: 25 November 2026, main at 3629e733
Q1. Findings (at most 10, most important first)
Finding 1. Sprite kind 8 is claimed by three PRs with three different meanings.
File/line: godot/fx/fx.gd:813 (PR 2049); godot/fx/fx_ship.gd:2623 (main, kept by 2049 at :2523); godot/fx/fx_ship.gd:2571 (PR 2007); godot/fx/fx.gd:760 (PR 2021).
Quote: const SPARK_KIND := 8 (2049, fx.gd:813).
Mark: OBSERVED. PR 2049 makes kind 8 a spark routed through flight_streak. Main (and 2049's branch) uses kind 8 as the Eclipse dark-smoke sprite. PR 2007 adds a second kind-8 emitter for deathless smoke tinted by damage_glow. PR 2021 lists kind 8 in its SMOKY dictionary for status-tick processing. After merge, one kind number drives a spark, two smoke emitters, and a smoke-status flag simultaneously.
Fix: Reassign SPARK_KIND to an unused number (kind 29 is taken by 2021; audit 9 through 28) before any of these four PRs merge.
Finding 2. Sprite kind 7 is simultaneously Hegemony fire, a shared spark, and smoke.
File/line: godot/fx/fx.gd:822 (PR 2049); godot/fx/fx_ship.gd (PR 2007, kind 7 for Hegemony fire and non-organic vents); godot/fx/fx.gd:760 (PR 2021, SMOKY set).
Quote: if kind in [1, 7, SPARK_KIND]: (2049, fx.gd:822).
Mark: OBSERVED. PR 2007 gives kind 7 to Directorate fire and vent sprites. PR 2049 reroutes kind 7 into the shared spark path, so Hegemony fire would render as a spark tinted by damage_glow instead of a fire effect. PR 2021 classifies kind 7 as smoke for its persistent-acid status work. Three systems disagree on what kind 7 is.
Fix: Give Hegemony fire and vents a dedicated kind outside the spark-reroute list and outside SMOKY, or explicitly exclude kind 7 from the spark reroute in 2049.
Finding 3. Eclipse acid colour is written twice with different values and no textual conflict.
File/line: godot/fx/fx_ship.gd:1908 (PR 2021) and godot/fx/fx_ship.gd:1886 (PR 2049 branch, carrying main's line).
Quote: "deathless": return fac["damage_glow"] (2021, fx_ship.gd:1908).
Mark: OBSERVED. PR 2021 replaces the hardcoded green Color(0.5, 0.9, 0.2) with the faction's violet damage_glow. PR 2049's branch still carries the old green at line 1886. The evidence states the two edits do not textually conflict, so git will keep both lines. After merge, two code paths can return different acid colours for Eclipse.
Fix: After merging 2049, rebase 2021 so the green line is removed, and add a grep-level CI guard that no Eclipse colour literal falls outside the violet palette.
Finding 4. faction_looks.json is edited by both PR 2007 and PR 2049, and they conflict.
File/line: godot/fx/faction_looks.json (PR 2007 and PR 2049).
Quote: "PR 2007 retunes in faction_looks.json (PR 2049 also edits that file)."
Mark: OBSERVED. PR 2007 retunes damage_glow for the Directorate. PR 2049 edits the same file for the shared spark's faction palette. The pairwise merge test reports a conflict in faction_looks.json. Whoever resolves this conflict must reconcile the damage_glow values, because both the spark tint (2049) and the Hegemony spark rule depend on that field.
Fix: Resolve the conflict by taking 2007's retuned damage_glow values and confirming 2049's spark palette test still passes against them before merging the second PR.
Finding 5. PR 2021 fails nearly every Godot check on its own head.
File/line: PR head 207f5d71; check definitions in godot/tools/ci/godot_checks.txt (not enough info in the pack to name the exact failing test files or line numbers).
Quote: "Nearly every Godot check fails on its own head."
Mark: OBSERVED. The pack does not say whether these failures are caused by 2021's own code or by a stale base. Either way, merging a PR whose head cannot pass the game checks risks introducing regressions that the other three PRs' passing checks will mask.
Fix: Require 2021 to pass all four Godot game checks on a rebased head before it enters the merge sequence.
Finding 6. PR 2007 fails the standing checks at its current head.
File/line: PR head 16bc0005; standing-check definition not pinpointed in the pack (not enough info for exact file and line of the failing rule).
Quote: "Standing checks (rules, text, saves)" fails
Mark: OBSERVED. The four Godot game checks pass, but the standing checks covering rules, text, and saves do not. The earlier death-plane test failure is resolved at this head, so the remaining failure is in a different area. Merging with a standing-check failure risks breaking save compatibility or rule text that the other three PRs assume is stable.
Fix: Identify and fix the standing-check failure (likely a rule-text or save-schema mismatch from the faction colour rework) before merging.
Finding 7. Three of four capture launchers pin AFTER to a branch ref, not a full SHA.
File/line: PR 2007 capture.bat, AFTER line; PR 2049 capture.bat, AFTER line; PR 2055 capture_2042_before_after.bat, AFTER and BEFORE lines.
Quote: set "LB_AFTER=origin/codex/issue-1991" (2007 capture.bat).
Mark: OBSERVED. The stated rule is that AFTER must pin to a full commit SHA. PR 2007 uses a branch ref. PR 2049 uses "origin/codex/issue-2018". PR 2055 uses "origin/neon/issue-2042" for AFTER and "origin/main" for BEFORE. Only PR 2021 validates AFTER as exactly 40 hex characters. Branch refs move, so the captured "after" images are not reproducible.
Fix: Replace every branch ref in BEFORE and AFTER with the full 40-character SHA of the merge-commit or review head.
Finding 8. PR 2021 passes a res:// Godot path to a Windows file-existence check.
File/line: PR 2021 wave2b_run4.bat, LB_MOMENTS assignment.
Quote: LB_MOMENTS=res://bench/look_moments_1693_run4.json
Mark: OBSERVED. The capture rule requires Windows paths for file checks. PR 2007's check mode runs if not exist "%LB_MOMENTS%" exit /b 2, and a res:// path will never exist on the Windows filesystem, so the check will always exit with code 2. PR 2055 explicitly documents this hazard and passes a real Windows path, but 2021 does not.
Fix: Change LB_MOMENTS in wave2b_run4.bat to a Windows-native path (e.g. %~dp0..\..\bench\look_moments_1693_run4.json).
Finding 9. Kind 20 (Chorus hatch and vent sprites) is classified as smoke by PR 2021.
File/line: godot/fx/fx.gd:760 (PR 2021, SMOKY dictionary); godot/fx/fx_ship.gd (PR 2007, kind 20 assignment).
Quote: "20: true" within the SMOKY set (2021, fx.gd:760).
Mark: INFERRED. The reasoning: PR 2007 assigns kind 20 to Chorus hatch and vent sprites, which are meant to be organic effects. PR 2021 places kind 20 in SMOKY, so its persistent-acid and bio-contact status work will treat Chorus vent puffs as smoke. If SMOKY classification triggers soot-like persistence or particle behaviour, Chorus vents could acquire a non-organic, smoke-like look, edging toward the "no metal sparks" and "organic effects only" rule. The pack does not show exactly what SMOKY classification does at runtime, so the visual consequence is not confirmed.
Fix: Confirm what SMOKY membership does in 2021's status system. If it adds persistence or soot visuals, exclude kind 20 or give Chorus vents a kind outside SMOKY.
Finding 10. fx_shaders.gd is edited by all four PRs, with PR 2055 rewriting 215 lines.
File/line: godot/fx/fx_shaders.gd (2007, 2049, 2021, 2055; 2055 is +215 -20).
Quote: "2055 is +215 -20" (net diff summary for fx_shaders.gd).
Mark: INFERRED. The reasoning: four concurrent edits to one shader file, one of which rewrites over 200 lines, create a high risk that the merge resolution silently drops a uniform, a vary, or a render-mode flag that another PR depends on. The pairwise merge tests confirm 2007 x 2021 conflict in this file. The pack does not show the shader contents, so I cannot confirm which specific uniforms or passes collide, but the surface area is large.
Fix: Merge 2055 first (largest delta), then rebase the other three onto it. Run a shader-compilation check after each subsequent merge.
Q2. Faction rules that break only in combination
Eclipse: "violet, no green or orange."
No single PR introduces green. Main already has the green acid line, and 2049 inherits it without changing it. PR 2021 replaces it with violet. But because 2049 and 2021 edit different lines (1886 vs 1908) and do not textually conflict, the combined tree can carry both the old green assignment and the new violet assignment. A code path that hits the 2049-branch line will render green acid for Eclipse. This violation exists only when both PRs are in the tree.
Chorus: "organic effects, no metal sparks."
No single PR gives Chorus metal sparks. But the combined kind-8 and kind-7 rerouting in 2049 changes how the sprite system processes kinds. If any Chorus effect currently uses kind 7 or 8 (not enough info in the pack to confirm), the spark reroute would turn it into a metallic-looking streak. Additionally, kind 20 Chorus sprites being classified as SMOKY by 2021 (Finding 9) could add non-organic persistence. The pack does not confirm a visible violation, so this is flagged as a risk, not a confirmed break.
Directorate (Hegemony): "sparks follow damage_glow."
Individually, 2007 assigns kind 7 to Hegemony fire and retunes damage_glow; 2049 reroutes kind 7 into the spark path tinted by damage_glow. Neither alone breaks the rule. Combined, Hegemony fire becomes a spark whose tint depends on the damage_glow value in faction_looks.json. Because 2007 and 2049 conflict in that file (Finding 4), a bad conflict resolution could pair 2007's kind-7 fire assignment with 2049's pre-retune damage_glow, making Hegemony sparks the wrong colour. The break depends on the merge resolution, so it is a combination-only risk.
Glasswrights: "no orange fire, no soot, no white cold gas."
Not enough info. The pack does not show any Glasswrights-specific kind assignment or colour edit in any of the four PRs. I cannot confirm or deny a combined violation.
Shield blocks stay quiet; one shield pool per ship.
PR 2049 adds a test asserting quiet shield blocks. The evidence states the shield_hit call sites in the shared fx_weapons.gd hunks are unchanged by 2007 and 2049. However, 2049 and 2021 conflict in fx_weapons.gd. Not enough info to confirm whether 2021's side of that conflict touches shield_hit paths. Flagged as unresolved.
Q3. Safe merge order and re-checks
Order: 2055, then 2049, then 2007, then 2021.
Step 1: Merge PR 2055 (RCS cone jets, engine plumes, trails) at d987c053.
Why first: all checks pass; it has the largest single-file delta (+215 -20 in fx_shaders.gd), so landing it first means every later PR rebases onto the new shader base rather than the other way around. Its conflicts with 2007 (look_bench.gd, fx_ship.gd) and with 2049 (render/bench files, disjoint fx regions) are the easiest to resolve when 2055 is already in main.
Re-check after merge: run all four Godot game checks; compile every shader in fx_shaders.gd; run look_bench.gd and confirm the bench output matches the 2055 capture.
Step 2: Merge PR 2049 (shared spark effect) at 838263ae, rebased onto new main.
Why second: all checks pass; it defines the spark-kind routing (SPARK_KIND, the reroute list at fx.gd:822) that 2007 and 2021 must respect. Its fx edits with 2055 are in disjoint regions, so the rebase should be clean. The faction_looks.json edit lands here, setting the palette baseline.
Re-check after merge: run all four Godot game checks; run death_variety_1586_check.gd; run the 2049 capture launcher (after pinning AFTER to a full SHA); confirm the quiet-shield-block test passes; grep for any kind-8 or kind-7 sprite emitters that now unintentionally enter the flight_streak path.
Step 3: Merge PR 2007 (faction colour leaks, wreck cap) at 16bc0005, rebased onto new main.
Why third: it has the heaviest pairwise conflict with 2049 (8 files), so 2049 must already be in main to resolve those conflicts with full context. The standing-check failure must be fixed before or during this merge. The kind-7 and kind-8 assignments in this PR must be renumbered to avoid the collisions identified in Findings 1 and 2.
Re-check after merge: run all four Godot game checks AND the standing checks (rules, text, saves); verify faction_looks.json damage_glow values are the 2007-retuned ones; confirm no Eclipse asset renders green or orange; run the 2007 capture launcher (after pinning AFTER to a full SHA); re-run the 2049 spark-palette test against the retuned damage_glow.
Step 4: Merge PR 2021 (persistent acid, bio contact) at 207f5d71, rebased onto new main.
Why last: nearly every Godot check fails on its current head, so it needs the most repair before it is mergeable. Its bio-contact glob reserves kind 29 (tested clear of the thrust sprite), which is safe relative to the kinds used by the other three PRs. Its SMOKY dictionary and acid-colour edit must be verified against the settled kind assignments from steps 1 through 3. The res:// path in wave2b_run4.bat must be fixed.
Re-check after merge: run all four Godot game checks; confirm the Eclipse acid test asserts violet, not green; confirm BIO_CONTACT_GLOB kind 29 does not collide with any kind assigned by 2007, 2049, or 2055; verify SMOKY membership for kinds 7, 8, 20 does not misclassify sparks or Chorus organics; run wave2b_run4.bat with a valid Windows LB_MOMENTS path and a full-SHA AFTER pin.
Not checked:
The pack does not include the contents of fx_shaders.gd, so I cannot confirm which specific uniforms, varyings, or render passes collide across the four PRs' shader edits.
The pack does not show the runtime behaviour of the SMOKY dictionary in PR 2021, so I cannot confirm whether SMOKY membership changes visual output or only status-tick logic.
The pack does not identify which specific Godot game checks fail for PR 2021, nor whether the failures are caused by 2021's own code or by a stale merge base.
The pack does not identify which standing check (rules, text, or saves) fails for PR 2007.
The pack does not confirm whether any Glasswrights-specific sprite or colour is touched by any of the four PRs.
The pack does not show whether the 2049 x 2021 conflict in fx_weapons.gd touches shield_hit call sites.
The pack does not include save-file schema information, so save compatibility across the combined changes is not verified.
The pack does not cover performance or frame-budget impact of the combined shader and particle load.
The pack does not confirm whether the earlier death-plane test failure in PR 2007's history was fully resolved or merely masked at head 16bc0005.
The pack does not show the content of the Godot game checks themselves (godot/tools/ci/godot_checks.txt), so I cannot verify whether the checks cover kind-collision scenarios.
Single strongest objection to the chair's likely synthesis
The chair will almost certainly frame the kind-8 and kind-7 collisions as "merge conflicts to resolve" and recommend a merge order with conflict-resolution instructions. That framing is wrong. These are not textual conflicts where you pick one side or the other. Three PRs assign three different semantic roles to the same integer, and the sprite system dispatches on that integer at runtime. No merge-resolution strategy, no matter how careful, can make kind 8 be a spark, a smoke sprite, and a smoke-status flag at the same time. The chair's synthesis will produce a tree that compiles, passes the four Godot game checks (because the checks do not test kind-collision semantics), and then renders Eclipse dark smoke as a violet spark and Hegemony fire as a damage_glow streak in actual gameplay. The fix is not a merge-order change or a conflict-resolution note. It is a design-level renumbering of sprite kinds, done once, before any of these four PRs merge. If the chair's synthesis skips that renumbering step, the combined build will ship with silently wrong faction visuals that no automated check in the current suite will catch.
