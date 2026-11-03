Gate 1 (selector Qwen3.8-Max before sending) and Gate 2 (header Qwen3.8-Max after generation) both passed.

Qwen leg report, Issue #86. Model: Qwen3.8. Scope: 15 merged PRs of Nov 2, 2026, main at 80307a2. Weight on PR #63 and PR #83. Evidence base: synthesis.md (chair review) and pack.md (shared pack). I did not run the repo, the browser suites, or Godot. Every claim below is drawn from the chair's cited observations or reasoned from them, and is marked accordingly.
Verdicts, one per PR
PR #10 (Command wording): CLEAN. Text-only change. Chair confirmed the new wording in godot/rules/rules.gd cmdDesc and both regenerated tables (OBSERVED by string search). No type or state risk.
PR #14 (price tests): CLEAN. Test values match data.js at HEAD. The note about the r1 FS-2 check computing through FAC_PRICE and shipyard rounding rather than comparing table entries directly is acceptable: the pin at 590 vs 415 still holds (OBSERVED per chair).
PR #32 (playtest batch 1): FINDINGS carried forward. The chair's inferred item on godot/world/blocker_visuals.gd:105 (look_at_from_position with local coordinates in a global-space call) stands. I cannot settle it without the engine. The batch 1 docs staleness was superseded by PR #85 and fixed on branch. Verdict: CLEAN conditional on the Opus in-engine check (INFERRED).
PR #35 (playtest batch 2): CLEAN, one note. The torpedo flight clamp (0.85 to 1.25 s in godot/fx/fx_weapons.gd torp_strike) is a pacing change presented as a clarity fix. No state or save risk. Removed peak-acceleration fields (gl_apk, gl_ypk, gl_fpk, gl_spk) confirmed absent by grep (OBSERVED).
PR #36 (onboarding tests): CLEAN. Tests evaluate the real TIPS table. Stricter than what they replaced. b1_tests passes, 39 ok (OBSERVED).
PR #38 (effect caps): CLEAN. Cap clamp landed in core.js:189 (sumFx), godot/rules/rules.gd:301, and godot/campaign/campaign.gd:486 (OBSERVED). Clamping after summing is correct for the penalty-offsets-bonus semantics. FX_CAPS added to campaign REQUIRED_TABLES. No save-path risk: FX_CAPS is a table constant, not a per-save field.
PR #39 (b4 flake fix): CLEAN. Root cause identified and fixed by seeding (rndSeed(37)) and pinning N.weak. Test-only scope (OBSERVED).
PR #46 (Nemesis clash tests): CLEAN. Tests only, no shipped code in the diff (OBSERVED). 12,330 browser cases pass. Godot fixture replay exists at godot/campaign/test/nemesis_clash_test.gd but was not re-run here.
PR #47 (export smoke guard): CLEAN. _exit_tree in godot/render/ship_view.gd detaches render instances only under headless/dummy renderer and returns early otherwise. meshes is the view's own array (OBSERVED). No save or state risk.
PR #63 (lineage slice): CLEAN with notes. See detailed analysis below.
PR #64 (free exit tests): CLEAN. Tests only. Browser suite drives the real event picker and ACT handlers at 0 and 120 credits for every fight event and faction (OBSERVED).
PR #68 (playtest batch 3): CLEAN, one note. Damage staging matches FINDINGS R80. Removed TRAIL_LEN, TRAIL_RELAX, and trail "dirty" flag confirmed absent by grep (OBSERVED). The unused NEB_SHEET shader string in godot/ui/campaign/map3d_shaders.gd is harmless dead code.
PR #69 (fx guards): CLEAN. Systematic typeof guards on every fx and animation entry point in battle.js. No remaining unguarded calls outside try blocks and definitions (OBSERVED by grep). Both oracle copies updated.
PR #83 (shadow XP and heir naming): FINDINGS, one bug fixed on branch. See detailed analysis below.
PR #85 (deaths): FINDINGS, docs only, fixed on branch. Code matches the issue. Four stale passages in godot/fx/API.md corrected.
Detailed analysis: PR #63 (lineage) and PR #83 (shadow XP)
PR #63, browser vs Godot port comparison
The chair read both implementations side by side (this is one of the two PRs where Codex was cut off). From the synthesis:
lineageBuild validation. Both ports validate stored picks the same way: sequential per branch, tier exists, choice is 0 or 1, capped by level (OBSERVED per chair read).
Respec pricing. Matches across ports (OBSERVED).
Between-runs gating. Matches across ports (OBSERVED).
Save round-trip. lineage_tests passes, including save round-trip and the check that other factions stay at level 4 (OBSERVED, suite run by chair).
Trunk display thresholds. Uses MASTERY_XP thresholds, which equal LINEAGE_XP for levels 1 to 4 (0, 6, 16, 30, 50 in data.js:583 and the LINEAGE_XP table). No visible mismatch (OBSERVED).
Save and migration path for lineage. PR #63 added lineage to both defaultMeta and saneMeta. The chair explicitly notes this set the precedent (OBSERVED). The lineage field therefore passes saneSave validation and would be caught by type checking if malformed.
Residual concern. Codex was cut off before its own validation on this PR. The chair compensated with a full side-by-side read. I find no divergence claim that contradicts the chair's read, but the absence of Codex's own pass means this PR had one fewer independent check than the others. This is a process note, not a code finding.
PR #83, browser vs Godot port comparison
Overflow pool redistribution. Terminates in both ports: each pass either spends the pool or caps at least one benched line (OBSERVED per chair read).
Heir naming gate. Browser: gated to the debrief state via heirDebrief in campaign_meta.js. Godot: gated by page kind and RUN null check in godot/campaign/campaign.gd ACT_nameHeir (OBSERVED).
Duplicate endRun guard. Duplicate calls can no longer pay twice, in both ports (OBSERVED).
Importer fixtures. contrib/muse/tools/importer_fixtures updated in step (OBSERVED). The chair flags this as correct and easy to miss. I concur: if the fixtures had not been updated, future imports could produce metas with the old shape.
Save and migration path for heirs and shadowPool. This is where the bug lived. defaultMeta in core.js:50 gained heirs and shadowPool. saneMeta did not learn them. The failure case, reproduced by the chair in Node against shipped code: a meta with heirs as a string and shadowPool as a number passes saneSave, is not repaired by migrateMeta, and shadow XP silently stops persisting (the pool write in awardLineageXP no-ops on a number, heir naming no-ops on a string) (OBSERVED, reproduced).
Chair's saneMeta fix: completeness check
The fix adds heirs and shadowPool to the saneMeta key lists in:
core.js:102 (OBSERVED)
Both oracle copies of core.js, re-copied and byte-identical (OBSERVED)
godot/campaign/campaign.gd:354 (OBSERVED)
Regression assertions added to contrib/opus/tools/shadow_xp_tests.js; suite passes with the fix and the malformed meta is now rejected (OBSERVED).
Is the fix complete across ports? The browser port (core.js:102) and the Godot campaign port (campaign.gd:354) are both covered. The oracle copies are byte-identical to the source. I find no third port or third copy mentioned in the pack or synthesis that would need the same treatment. Verdict: the fix is complete across the ports that exist (INFERRED from the chair's enumeration; I cannot independently confirm there is no fourth copy).
Does any other defaultMeta container miss the same treatment? I walked the 15 PRs for any other addition to defaultMeta:
PR #63 added lineage to defaultMeta and saneMeta together (correct, OBSERVED).
PR #83 added heirs and shadowPool to defaultMeta but missed saneMeta (the bug, now fixed).
PR #38 added FX_CAPS to campaign REQUIRED_TABLES, which is a table constant, not a per-save meta field. Not affected.
No other PR in the batch adds a field to defaultMeta.
I find no other defaultMeta container that misses the saneMeta treatment in this batch (INFERRED from the PR list and the chair's per-PR reads). However, I cannot rule out a pre-existing gap from a PR merged before Nov 2 that is outside this review's scope.
Does migrateMeta need updating? The chair's reproduction shows migrateMeta does not repair a malformed heirs or shadowPool. The fix is in saneMeta (rejection), not migrateMeta (repair). This means a save that already shipped with the wrong types will be rejected by saneMeta going forward, but will not be silently repaired. If the intent is to repair rather than reject, migrateMeta would need a migration step. The chair does not flag this, and the regression test confirms rejection, so I treat rejection as the intended behavior (INFERRED). If a player save is already corrupted, they lose the shadow XP data rather than getting it repaired. This is a design question for Opus, not a code bug.
Findings
Finding 1 (PR #83, fixed on branch). saneMeta gap for heirs and shadowPool.
defaultMeta at core.js:50 gained heirs and shadowPool, but saneMeta did not include them in its key lists. A meta with heirs as a string and shadowPool as a number passed saneSave and was not repaired by migrateMeta, causing shadow XP to silently stop persisting. Fix applied at core.js:102, both oracle copies, and godot/campaign/campaign.gd:354. Regression test in shadow_xp_tests.js. (OBSERVED, reproduced by chair.)
Finding 2 (PR #85, fixed on branch). Stale destruction docs in godot/fx/API.md.
Four passages did not match the code: line 118 claimed a deterministic fifth of blast deaths become whole hulks (code says ordinary blast kills always split), line 360 described the old Chorus deflate death (code now does rupture), and the batch 1 check description still said "organic collapse." All four corrected on branch. (OBSERVED.)
Finding 3 (PR #32, open for Opus). look_at_from_position with local coordinates.
godot/world/blocker_visuals.gd:105 calls mi.look_at_from_position(mi.position, b, ...) with local coordinates, but look_at_from_position operates in global space. If build() runs after the blocker node is in the tree, outline segments land near the world origin instead of on their hex. If build() runs before tree entry, the call is harmless. Failure case: a set-piece map (planet or station footprint) whose rim segments appear at the wrong place. Needs one in-engine screenshot of a station map to settle. (INFERRED, no Godot binary in this environment.)
Finding 4 (PR #83, design question). migrateMeta does not repair malformed heirs or shadowPool.
The saneMeta fix rejects a malformed meta. But if a player save was written during the window when the bug was live (between the PR #83 merge and this fix), the save contains the wrong types. saneMeta will now reject it. migrateMeta does not repair it. The player loses shadow XP state silently (the save is rejected, presumably falling back to defaults). If the intent is graceful repair, migrateMeta needs a step that coerces heirs to its expected container type and shadowPool to its expected container type. (INFERRED from the chair's reproduction: "is not repaired by migrateMeta.")
Finding 5 (PR #63, process note). Codex was cut off before its own validation.
The chair compensated with a full side-by-side read and lineage_tests passes. But this PR had one fewer independent automated validation pass than the others. No code bug found, but the coverage gap is worth recording. (OBSERVED per pack.md.)
Finding 6 (PR #35, pacing note). Torpedo flight time clamp is a design change in a fix PR.
godot/fx/fx_weapons.gd torp_strike now clamps torpedo flight time to 0.85 to 1.25 s. A point-blank torpedo flies longer than its distance implies. The chair accepts it as pacing. I note it here because it changes game feel without a design-doc update, and future balance passes may not expect the clamp. (OBSERVED per chair read.)
Not checked
Godot runtime behavior of any .gd change. No Godot binary available in this environment. All Godot-side claims are INFERRED from code reads and the PR bodies' PC check results.
Godot fixture replays for effect caps, Nemesis clash, free exits, lineage, and shadow XP exist as .gd files but were not re-run. They passed on the PC at merge time per the PR bodies.
Visual results of PRs #32, #35, #68, and #85 beyond their own check files.
PC-only checks (Godot parity, campaign parity) were not re-run.
The DeepSeek and Argon legs have not run. This report does not incorporate their findings.
PRs merged Nov 2 that are not code PRs in the issue list (docs and design merges such as #73, #74, #84) are out of scope.
I did not independently verify any file:line citation. All line numbers are taken from the chair's synthesis. I have no repo checkout and no browser.
Whether any pre-Nov-2 PR left a defaultMeta field out of saneMeta. That is outside this review's scope.
The blocker_visuals.gd item (Finding 3) requires an in-engine check that I cannot perform.
