# Rulebook notes for the Board (issue 492, Part B)

What docs/RULEBOOK.md was built from, what it left out, and what is still to do. Sources: the two registers in
contrib/opus/reviews/rules_sweep/ (827 entries), contrib/muse/reviews/rules_sweep_2026_11.md,
contrib/codex/reviews/rules_sweep_checks.md, FINDINGS through R215. `said_by` was re-checked at the FINDINGS row for every
rule kept: rows written as "board (Opus), ... (Ryan, Nov 6)" (R122, R123, R125) are the Board's audit calls, not Ryan's words.

## Reworded or retired by the Board (Board or agent rules)

- AGENTS.md seat table naming Fable for the Board and Codex for Blender: replaced by RULEBOOK 2.6 (R180, R205, R206; PR 549 fixes
  the table).
- Kimi "slower and 50x the price": reworded to "off and never fairly tested" (R164).
- REVIEW_PROTOCOL "at most 10 findings": reworded to ranked, count set by the job (Muse sweep item 18).
- Gate line 3's stern fraction and gate line 9's fixed proportions: reworded to starting points (R183 overrode 4.5 : 1).
- "Up to three tries each" for concept pictures: retired; image rounds now follow R192, R204, R206.
- Outline overlap 90 percent as a pass bar (R147, ships.md stage 3, RECIPE.md): reworded to reported, not a bar (R207, R213).
- BLOB_SWEEP.md "clean or rebuild" per cell: retired (R121 already said so).
- "Short and dry" sound: reworded to weapons dry, big moments with weight (R193).
- "At least four takes": reworded to never the same take twice running, four as a start.
- The 12 px text floor (ui_spec.md, ui_spec_tests.js): retired for one floor of 17 px.
- The 4 degree bank into turns, the 7 s move cap and the other R131 numbers: tuning values (R189); the bank retired (no roll).
- R123 "the camera is never taken for a capital death" and ui_spec's dropped capital cut-in: retired (R193).
- Death playbook "two capped halves", Hegemony "parts cleanly": reworded to blown apart (R186).
- Brightness scan "no pixel brighter than 40 percent of mid grey" (go-forward plan, agent): a tuning value, not a gate.
- R30 "0.5 s enemy think bar": retired as a bar (Ryan accepted longer enemy turns, R64); keep reporting worst case.
- G-1 ship draw scale 1.6x: a tuning value (R157 found ships 60 to 200 px at camera 170).
- Codex "the tool for finals" (factions.md): retired (R197 (3), R205).
- "Two or three authored break lines" (AGENTS.md) and R99 Q2: retired by the class table and R215.
- Feel pass and fb1 to fb3 brief rules (pace targets, holes as the main damage read): history; fb3's "normal hits do not cut
  holes" is carried as the purpose of batch item 2.

## Rules with no reason that nobody could supply (left out of the rulebook)

Ryan's (in the batch for him): the dead-star board, Argon blocked, the repo public, R80's two clauses, R62c zoomed-out start,
R23 one prize screen. Others, for the Board to give a reason or drop:
- F19 tonemapper AgX only (Board, Oct 25).
- R82c tactical hex tint reduced, faint tint kept; dead star well at subtle brightness (Ryan's pick, no reason).
- R79d planet texture 4096 by 2048, moons 1024 by 512 (a size, not a rule).
- R84 and R100a station structure picks (cradle, unarmed refinery, beacon sizes; additions only): superseded in practice by the
  T2 concept (R206); fold into the station build sheet or archive.
- R74c Nemesis clock as a ring round the sun, bypassed branches dim: check whether the Briefing map still has these.
- R125b campaign map faction colour "under a written rule with station muting": the written rule is not found.
- R80d squadrons get stage 0 surfaces and a smoke ribbon below half HP (no reason).
- R78b trophy plates on the flagship only, one hero trophy per portrait (no reason).
- R9b three height bands on the backlog: a backlog item, not a rule; file as an issue or drop.
- R105a two value-step tiers between plates (Ryan's pick of the paint research; reason in the synthesis not checked).
- uistyle-07 the finishing action fixed bottom right (the orders sheet moved it to the sheet).
- music_check.gd's 150 MB music cap (no storage reason recorded).

## Checks and code that still enforce retired numbers (from Codex's sweep; each a small workhorse job)

- tools/recipe stage 3 and 4 exit non-zero below 0.90 outline overlap: make it a reported number (RULEBOOK 5.8).
- contrib/opus/tools/ui_spec_tests.js MIN_TEXT 12: raise to 17 when the battle screen (PR 544) lands (RULEBOOK 9.4).
- godot/fx/test/destruction_staging_check.gd "a cruiser parts in two, a capital in three" and destruction_steps_check.gd's
  flat cap area: check opaque insides and cleanup, not piece counts (R186).
- godot/fx/test/death_leap_check.gd fixed 2.67 s capital wait: tie it to the death timeline.
- godot/audio/test/audio_check.gd cue count 67 and once-only big-death cues: count by family, not total (sound weight, 507).
- contrib/opus/tools/checks_baseline.json driftDifferedCeiling 12: the browser drift guard is at its ceiling; a Godot look change
  can trip it.
- godot/render/ship_view.gd still writes rotation.x from glide_bank in one mode: confirm none in the default mode (RULEBOOK 7.5).
- Already fixed: check_export.py's fixed six breach anchors (issue 363, PR 530); world.gd rock asserts now report (PR 527).

## Also outstanding from Part A

- Done (PR 552, then the clean-up PR): AGENTS.md is slimmed; its seat table, ship sections and PC notes are in the rulebook
  and the old text is archived at docs/archive/AGENTS_2026-11-11.md.
- Done: CLAUDE.md no longer names the go-forward plan (archived at docs/archive/go-forward-plan.md).
- FINDINGS.md needs a header line: the rulebook is the live source; new rulings record the problem Ryan was reacting to (R189)
  and land with their document edit (R214). Board commits it to main.
- The lore bible's Eclipse ship colour line needs a note pointing at R169b (green rim) and R201 (purple plates).
- No playbook for space and the board yet (PROGRAM.md track 3).

## Should move to docs/archive/, and what replaced each

Done Nov 11 by the clean-up pull request (branch opus/issue-492-cleanup): where each item went is in
contrib/opus/reviews/cleanup_492.md. The paths in the table are the old ones.

| Document | Replaced by |
|---|---|
| contrib/opus/go-forward-plan.md | docs/playbooks/PROGRAM.md and this rulebook (keep its section 1, Ryan's Oct 24 calls, quoted in the archive note) |
| contrib/opus/briefs/feel_pass_2026-11-01.md | contrib/opus/briefs/movement_spec.md; RULEBOOK 7 |
| contrib/opus/briefs/codex_fb1_playtest_fixes.md, codex_fb2_movement_torpedo_tiles.md, codex_fb3_playtest_fixes.md | applied; fb3's damage read is RULEBOOK 6.8 and batch item 2 |
| contrib/opus/briefs/campaign_map_briefing.md | contrib/opus/briefs/campaign_rail_orders_sheet.md and docs/playbooks/screens.md |
| contrib/opus/briefs/ui_style.md (Glass Shell and lime sections) | docs/playbooks/screens.md section 2 (the orders sheet) |
| contrib/opus/briefs/ui_spec_constants.md | generated snapshot; nothing (regenerate if needed) |
| contrib/opus/briefs/blender_build_harness.md | docs/playbooks/ships.md and docs/ship_pipeline/RECIPE.md (its caps section is dead, R111) |
| docs/playbooks/concepts_round2.md, the round 2 grammars and variations (from "How round 2 is drawn" down) | docs/playbooks/factions.md (current picks); the gate stays in the playbook |
| docs/playbooks/factions.md "Round 1 directions" | history of R172; keep the pictures' folder as is |
| tools/blender/hs/c19_kit.py references and AGENTS.md "Ship models" | docs/playbooks/ships.md, tools/recipe |
| The F, S, B, D, K, X and G letter tables in FINDINGS | a closed-era section heading inside FINDINGS (it stays as history) |

Keep, do not archive: contrib/opus/briefs/debrief_spec.md (the only statement of the debrief's content, issue 92); docs/ship_pipeline/README.md
and BLOB_SWEEP.md (mark their phone and .vsm steps as browser-era history instead).
