# Outside check: PR #248, commit b45b9731 (issue #256, R132)

Reviewer: Rey (chair). Legs: blind Rey (written first, from the pack only), DeepSeek (DeepThink on, Search off, gate verified at send), Qwen (Qwen3.8-Max, selector verified before sending and header verified after; one response returned). Argon seat empty (blocked since Nov 5). Date: Nov 8, 2026.
Scope: the Opus-written commit b45b9731 only, per the board comment on #256 (Nov 8, 2026): four Godot UI readers switched from RUN.nem to C.nemActive(), and the 120-2 quick gate wired into contrib/opus/tools/run_all_checks.js. The rest of PR #248 is DeepSeek's and board-reviewed; anything tripped over in it is flagged, not reviewed.

## Verdict: GO. No BLOCKING findings.

The four switched readers are safe drop-ins, the quick gate is wired and asserts what R-Q1 asks, and the one reader the commit missed (NOTE 1) is safe on the current code for reasons the chair verified directly in campaign.gd. Ten NOTEs follow; none blocks the merge of PR #248.

## How the check was done

- The diff of b45b9731 was read in full (4 files).
- Reader census: all 23 files under godot/ui/ and godot/story/ (.gd and .js) fetched at the PR branch head (work/issue-120-deepseek) and at main, grepped for RUN.nem, nemActive, .nem, plus the spelled-out forms C.RUN.get("nem") and C.RUN["nem"]. On the branch, code reads of RUN.nem in the scanned set: zero (one comment remains, godot/story/rival.gd:6). nemActive call sites on the branch: exactly the four the commit switched.
- The chair additionally read godot/campaign/campaign.gd at the branch head (nemActive, nemMigrate, the sector modal call site), which the pack did not include, to settle the one question all three legs left open.

## The alias question, settled by the chair (OBSERVED)

RUN.nem is a maintained alias of the active commander, not a leftover field:

- New run: campaign.gd:1118 sets RUN["nem"] to the first assignment slot's entry.
- nemActive() (campaign.gd:1894) runs the migration, resolves the current sector's slot, creates the registry entry lazily if missing (:1901), and re-points the alias at :1902 (RUN["nem"] = reg[fac]) before returning it.
- Migration (campaign.gd:1857) carries a legacy save's single RUN.nem into the registry at the current sector slot and nulls the alias (:1871); the next nemActive() call re-points it. A migrated save is therefore safe at every reader that resolves through nemActive() or reads the alias after any resolve.
- The sector modal has exactly one call site, campaign.gd:2751, and its payload evaluates nemActive() while building the adapt field, before the modal renders.

## Findings

BLOCKING: none.

1. NOTE, godot/ui/campaign/campaign_ui.gd:1255 and :1256 (with :1238 and :1257). The commit missed a fifth reader of the run's nem entry, spelled through a local alias: _modal sets var R = C.RUN at :1238, and the sector branch reads R.get("nem") (:1255) and R["nem"]["fac"] (:1256), pairing that faction with C.nemFull() at :1257. It is safe today: the only call site refreshes the alias immediately before rendering (campaign.gd:2751 and :1902, above), and nemFull() resolves through nemActive() (campaign.gd:1934), so name and faction come from the same entry. It is fragile by convention: a future sector modal caller that does not evaluate nemActive() while building its payload would print the new commander's name with the previous sector's faction. Cheap hardening, if the board wants it: read C.nemActive() at :1255 and :1256 instead of the alias. Correction to the sweep's own evidence: the pack (section 5.3) stated R is not C.RUN. That was wrong; R is assigned C.RUN at :1238 (chair-verified in the branch-head source). The blind Rey leg caught the reader from the source; the DeepSeek and Qwen legs trusted the pack line and under-called it. The pack error is the chair's.

2. NOTE, godot/story/story.gd:141, :261, :295. These read the alias through the run parameter (run.get("nem")) and are unswitched. Their safety is exactly the alias invariant in Finding 1: safe for a migrated save by construction, safe for a registry run as long as nemActive() has resolved since the last sector change. Standing contract for future work: RUN.nem cannot be removed or allowed to go stale without switching these readers and the _modal reader in the same change. All three legs concur.

3. NOTE, godot/campaign/test/node/nem_assign_enum.js:50 to :53 and :54. The standing gate asserts the four 120-2 exact constraints only (assignment length and foes membership, no own-faction hunter, no H2=H1, no H3=H2). The statistical checks (120-1 marginals, 120-3 SP1 return and distinct-hunter split) sit behind --full at :54 onward and run only in the recorded 120,000-start verification. That matches the R-Q1 design as the board stated it, but a future change to the draw's weights or pool would pass the PR gate silently. All three legs concur.

4. NOTE, contrib/opus/tools/run_all_checks.js:36, with :17 and :21 (chair-verified). Under --fast, the runner marks any check with a timeout over 120 seconds as SKIP, and the enum row was added with the default 300 second timeout. A --fast invocation therefore reports the R-Q1 gate as SKIP, and SKIP does not fail the run. If any gating path ever runs --fast, the gate is not in force. Whether CI or the board uses --fast was not established.

5. NOTE, godot/campaign/test/node/nem_assign_enum.js:32, :36, :50 (chair-verified). Two distinct failures increment one counter: a malformed assignment (:32) and a hunter missing from RUN.foes (:36) both increment badLen, reported under the single label "120-2 assignment length" at :50. The check is correct; the label would mislead a future debugger on the second failure.

6. NOTE, godot/campaign/test/node/nem_assign_enum.js:13. The gate exercises the JS oracle's draw only. The Godot twin's draw and registry in campaign.gd ride on the parity and scenario checks quoted in the PR body, not on this gate, so a Godot-only draw regression would not trip run_all_checks.js.

7. NOTE, contrib/opus/tools/run_all_checks.js (whole file, chair-verified by grep at branch head). The scenario twins (nem_scenarios.js and nem_scenarios.gd, which cover migration, lazy creation and SP1 return per the PR body) are not a row in this runner. Where they are invoked from was not established by this check. If they are not standing elsewhere, the board may want them wired in; the migration path is the one behaviour this PR's design leans on hardest.

8. NOTE, godot/campaign/campaign.gd:1901, with godot/ui/campaign/campaign_ui.gd:716 and :781. nemActive() creates the current sector's registry entry lazily on first resolve, so two render paths (_nem_panel and nem_portrait) can now mutate run state while drawing, where the reads they replaced were pure. This is the stated B4 design, and the parity results in the PR body cover seeded campaign runs. Whether creation draws on the run's RNG stream, and whether a render-first resolve could order differently from the JS twin, was not established.

9. NOTE, PR #248 body (Skipped section). No screenshots were supplied for the four switched UI paths. R129 asks for shots after the sweep on UI-touching changes. The PR body skips them as a data-shape change; the four sites do render (nemesis panel, portrait, map card, threat line), so a single shot of the nemesis panel on a migrated save would close the loop.

10. NOTE, godot/story/rival.gd:6. The comment still describes the dictionary as the campaign's RUN.nem. Under the alias design the name is defensible, but the canonical access is now nemActive(). Cosmetic.

## Per-reader dispositions (summary)

- campaign_ui.gd:716 (_nem_panel): safe drop-in; jt guard at :717 preserved.
- campaign_ui.gd:781 (nem_portrait): safe drop-in; the C and C.RUN null guard is preserved verbatim; portrait cache re-keys on the resolved entry's faction.
- map3d.gd:877 (_card_bb): safe drop-in; gated by nemNodeIs at :875; the new call also removes the old subscript's hard error on a missing key.
- map_intel.gd:63 (_nem_threat): safe drop-in; reached only through danger() at :55, gated at :33.
- Remaining .nem hits in the scanned set are context, battle or info dictionaries (arc.gd, battle_voice.gd, tokens.gd), a context write (rival.gd:92), test fixtures (story_test.gd), downstream consumers of the switched readers, or the alias readers covered in Findings 1 and 2. None bypasses the nemActive() and alias path.

## Not checked

- The JS-side readers (campaign_run.js, core.js, campaign3d.js): outside the board's stated scope for this commit, and part of the board-reviewed DeepSeek half of the PR.
- Whether CI ran the standing checks on the PR branch, and which rows executed; the PR body's recorded output was taken as the record.
- newNemesis internals (persona and portrait draws, RNG stream use), beyond the lazy-creation note in Finding 8.
- The scenario twin files themselves, and the oracle copies under godot/campaign/test/oracle/.
- The rest of PR #248 beyond what the sweep touched.
