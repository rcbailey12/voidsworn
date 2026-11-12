# Clean-up of old instructions (issue 492)

Ryan, Nov 11 2026, 21:00 CST: "Yes, now" (FINDINGS R216) to a clean-up of old instructions and context, so no agent reads stale
guidance again. One pull request, branch opus/issue-492-cleanup. Nothing was deleted: every stale file or part of a file was
moved into docs/archive/ with a one-line ARCHIVED header ("replaced by ...; kept for history; do not follow"). Work list:
contrib/opus/reviews/rulebook_board_notes.md ("Archive list" and "Also outstanding").

## What moved where

| Before | After | Replaced by |
|---|---|---|
| contrib/opus/go-forward-plan.md | docs/archive/go-forward-plan.md | docs/playbooks/PROGRAM.md and docs/RULEBOOK.md; its section 1 (Ryan's Oct 24 calls) is named in the header and lives on in FINDINGS R1 to R10 |
| contrib/opus/briefs/feel_pass_2026-11-01.md | docs/archive/briefs/ | contrib/opus/briefs/movement_spec.md, RULEBOOK 7 |
| contrib/opus/briefs/codex_fb1, fb2, fb3 briefs | docs/archive/briefs/ | applied; RULEBOOK 6.8 and section 7 |
| contrib/opus/briefs/campaign_map_briefing.md | docs/archive/briefs/ | contrib/opus/briefs/campaign_rail_orders_sheet.md, docs/playbooks/screens.md |
| contrib/opus/briefs/ui_spec_constants.md (a generated snapshot) | docs/archive/briefs/ | nothing; `node contrib/opus/tools/ui_constants_diff.js` writes a fresh one on demand |
| contrib/opus/briefs/blender_build_harness.md | docs/archive/briefs/ | docs/playbooks/ships.md, docs/ship_pipeline/RECIPE.md (its one unique lesson, "a model's own visual check is a hint, never proof", is now a trap line in ships.md) |
| ui_style.md sections 1 to 8 (Glass Shell and Lime Tactical) | docs/archive/briefs/ui_style_lime_tactical.md (section numbers unchanged, so code comments that cite "ui_style.md 3" still find their text) | the "Orders sheet" section, which stays in ui_style.md, and screens.md section 2 |
| concepts_round2.md, "How round 2 is drawn" and the six design sheets | docs/archive/playbooks/concepts_round2_grammars.md | factions.md (the current picks); the gate stays in the playbook |
| factions.md, "Round 1 directions" | docs/archive/playbooks/factions_round1_directions.md | factions.md "The concept redo"; the pictures stay where they were |
| AGENTS.md, the long version (seat table, ship sections, PC notes, lore, time estimates) | docs/archive/AGENTS_2026-11-11.md, word for word | the slim AGENTS.md and the rulebook |
| .claude/skills/ship-kit/SKILL.md, the Pyre-Barge chain | docs/archive/skills/ship-kit_SKILL_2026-11-11.md | a new short ship-kit skill that points at RULEBOOK 4 and 5, ships.md section 0 and tools/recipe |
| FINDINGS F, S, B, D, K and X letter tables | the same place, under a new heading "Closed era (Oct 24 to Nov 7 2026)" | the rulebook |

Kept, not archived (as the notes asked): contrib/opus/briefs/debrief_spec.md, docs/ship_pipeline/README.md and BLOB_SWEEP.md.
tools/blender/hs/c19_kit.py and tools/blender/a1/barge_v15.py stay where they are (job files call them); each got a two-line
history comment at the top.

## What AGENTS.md lost, and where each part now lives

| Removed from AGENTS.md | Now |
|---|---|
| "Start with HANDOFF and FINDINGS (fixed Nov 7, R110; reviewed in #216)" | Read first: the rulebook (it wins), then HANDOFF section 0 and LOOP.md, then the playbook; FINDINGS is history |
| Auditing: REVIEW_PROTOCOL "then AUDIT_BRIEF.md" | one line: REVIEW_PROTOCOL (RULEBOOK 2.11) and the issue's own brief; AUDIT_BRIEF.md is marked as history |
| Codex watcher paragraph (codex_board.bat queues every new codex issue) | one line: the Board launches Codex through the queue (LOOP.md "The seats", R170) and codex issues carry `blocked`; cloud rule is RULEBOOK 2.7 |
| Seat map with "Fable 5.2" in its header, Kimi "50x the price" | RULEBOOK 2.6; live seats in LOOP.md "The seats" |
| Blind Rey leg rule | kept as the Models line format; the rule is RULEBOOK 2.8 |
| Questions for Ryan in chat | owner preferences list; RULEBOOK 1.6 |
| "Ship models (the current big job)": README, BLOB_SWEEP, SHIP_QUEUE, barge_v15 worked example | archived; the start is docs/playbooks/ships.md section 0 (in the ship-kit skill) |
| Placement, no backward guns, space not naval | RULEBOOK 4.1, 4.2, 4.3 |
| Free tools, no triangle limits, glb not .vsm | RULEBOOK 3.8, 3.9, 5.12 |
| Owner rulings of Oct 24: PC-only, shield colours | RULEBOOK 3.1, 6.11 |
| Battles grow toward about 20 ships; capture is add, strip or ransom | rules of play, kept in FINDINGS R1 and R4; now named as examples in the rulebook's preamble |
| The dead-star board stays | RULEBOOK 10.10 (R216, merged with PR 554) |
| Lore approved, ids never change, the id to name list | RULEBOOK 11.1; the id to name list stays in AGENTS.md's first paragraph as a fact |
| Ryan's PC first: RTX 5080, 32 GB, "400+ GB free", paths, ComfyUI | RULEBOOK 3.2; "400+ GB free" dropped (the disk filled on Nov 11); new rule in RULEBOOK 3.3: keep each job's PC folder lean, the Board lists folder sizes at each disk check; the Blender path is in RECIPE.md, ComfyUI in the pipeline README |
| Breakable by design | RULEBOOK 5.4 and 5.5; the "older hulls use the game-side interior fallback (issue 167)" fact added to 5.4 |
| Blob sweep and its rebuild list, one level of detail | RULEBOOK 5.9 and 5.6; the list stays in BLOB_SWEEP.md section 2 |
| KEEP-box hand paint, pipeline gotchas (ships3d.js, closeshot) | browser-era history; in the archived AGENTS.md and the pipeline README |
| Heavy work paragraph | RULEBOOK 3.2; one line in the owner preferences |
| Time estimates (R99) | RULEBOOK 1.1; one line in the owner preferences |

AGENTS.md keeps: what the game is; read the rulebook first; the job board mechanics (labels, branch shapes, auto pull request,
checks, the fixed block with the four ship-build lines, a ruling lands with its document, no closing words); outside agents in
contrib/<agent>/; the owner preferences. CLAUDE.md is a short pointer in step with it.

## Browser-era material, now labelled

- docs/ship_pipeline/README.md: a status block at the top; steps 5 to 10 and the gotchas say "browser-era history, not the Godot
  product" (projection, phone LOD, vsm_pack, .vsm, ships3d.js, closeshot).
- docs/ship_pipeline/BLOB_SWEEP.md: a status block; the clean or rebuild verdict is retired (R121); projection paint and phone
  shots are labelled.
- History header (browser-era, do not follow): TEXTURE_PASS.md, GRAPHICS_REVIEW.md, AUDIT_BRIEF.md, AUDIT_SYNTHESIS.md (it lists
  naval parts as fixes), SHIP_QUEUE.md.
- contrib/opus/briefs/ui_spec.md: a status line (scale law, focus ring, settings, faction colour rule and debrief order are
  live; the palettes and the 12 px floor are superseded by RULEBOOK 9.1 and 9.4).

## Other stale lines fixed on the way

- docs/playbooks/ships.md: the outline overlap is reported, not a gate (RULEBOOK 5.8; stage 3 still exits below 0.90 until the
  workhorse fix); the seat line said "Codex runs the recipe", now an Opus worker (R205).
- docs/playbooks/concepts_round2.md gate line 9: "fixed proportions" became a starting point (RULEBOOK 4.8).
- contrib/opus/briefs/muse_standing_rule.md: the rulebook overrides other docs (was FINDINGS); Argon is off.
- .claude/skills/playtest-and-balance: the retired 15 s per round wait target (R64).
- contrib/README.md: the "good first tasks" built on c19_kit.py and SHIP_QUEUE are replaced.

## References fixed

Every full path to a moved file was rewritten across the repo, live documents to the replacement and history documents
(old reviews, research legs, the sweep registers, FINDINGS rows) to the archive path: 30 files in the first pass, then
ui_spec.md, screens.md, campaign_ui.gd, glass_shell.gd and ui_spec_tests.js (comments only), FINDINGS, and the skill path in
the sweep register and two research legs. `node contrib/opus/tools/doc_check_tests.js` and the standing checks pass.

## What I was unsure of, or left alone

- Files in open pull requests: screens.md, glass_shell.gd and ui_spec_tests.js (all in PR 544) got one path fix each in lines
  544 does not change (a trial merge with every open branch is clean). contrib/codex/reviews/rules_sweep_checks.md and .json
  (in PR 543) still name the old brief paths: they are history, left for 543.
- contrib/opus/LOOP.md is the Board's own file on main, so I did not edit it. Its "Seats right now (Nov 7)" section (Fable
  Board, Codex down, the old codex_board.ps1 watcher) is stale beside "The seats", and a few LATEST lines name old brief
  paths: the Board may want to fold or mark it.
- ui_style.md keeps a short table of the Lime-era theme names still in glass_shell.gd, because ui_spec_tests.js reads it and
  the unrebuilt screens still use them. When the last screen moves to the orders sheet, that table and its test can go.
- Old file:line citations into archived files are off by two lines (the header line and a blank line).
- Not on the list and left: AUDIT_v53H.md at the repo root (an old browser audit, unmarked); PROGRAM.md's Fable-era seat
  notes (rules_sweep register says PARTLY STALE); lore bible Eclipse colour note and the space playbook (still outstanding in
  the board notes).
- Whether the old board watcher (codex_board.bat) still runs on the PC is not known from the repo; AGENTS.md keeps the safe
  rule that codex issues carry `blocked`.
