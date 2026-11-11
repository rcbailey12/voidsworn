# Rules sweep, leg B: playbooks, briefs, plans and agent files (issue 494)

Read-only sweep for the rulebook (issue 492, FINDINGS R190). Every rule found is one entry in register_docs.json, in the fields issue 492 defines (plus `proposed` for every REWORD). Read on main at c04d439, checked against FINDINGS R170 to R190. Verdicts are drafts for the Board. No source quoted here contained an em dash, so nothing had to be replaced.

## The documents

| Document | Verdict | What is stale, or what replaced it |
|---|---|---|
| AGENTS.md | PARTLY STALE | Seat table still says Fable Board and "Codex when un-parked" (R170, R180); "Ship models (the current big job)" sends builders to the October browser pipeline and Pyre-Barge; auditors are sent to AUDIT_BRIEF.md (October). Owner rulings, job board, folder rules and preferences are live. |
| CLAUDE.md | PARTLY STALE | "The approved build plan is go-forward-plan.md": replaced by docs/playbooks/PROGRAM.md (R167). |
| HANDOFF.md | LIVE | Section 0 is current to R185. It holds the only up-to-date seat list (R180). |
| docs/playbooks/PROGRAM.md | PARTLY STALE | Who-does-what table and pacing are Fable-era (R180); line 41 keeps the battle HUD as Lime Tactical, contradicting its own decision 4 (line 162); promises a space.md that does not exist. |
| docs/playbooks/screens.md | PARTLY STALE | Section 2 is the Briefing look of R165: lime accent, sage text, filled lime button, 12 px floor, small caps heads, backings off the map. The orders sheet (R176, R177) replaced all of it. Section 8 "the HUD keeps its slabs" is overtaken. |
| docs/playbooks/effects.md | PARTLY STALE | Sizes pinned to the staging table "within 15 percent", and those sizes were tuned under the flash counter R187 found 13 times too strict; no mention of R186 or the cinematic audit. |
| docs/playbooks/deaths_and_hits.md | PARTLY STALE | "Two capped halves" and three neat pieces are the tidy wreck R186 rejected; hit sizes follow the target, not the gun; cut-ins still fire against its own "camera never taken" line. |
| docs/playbooks/ships.md | LIVE | Small conflicts: three-view sheet vs the gate's top and side sheet; the 90 percent outline gate; breach anchors "by class" while the check enforces six. |
| docs/playbooks/concepts_round2.md | PARTLY STALE | Gate lines 1 to 12 are live (R183 withdrawal of "the forward gun is the largest object on the bow" is written in; gate 11 has the R185 naval pass). Stale: "Flak is one small cluster" beside the R176 two-to-four turrets in the same line; the round 2 grammars and proportions (crystal Glasswrights, prong Hegemony, "the ring never lies flat") were overtaken by R180 to R185 and should be archived. |
| docs/playbooks/factions.md | PARTLY STALE | The flagship table and the method are current. The per-faction sheets above it still describe the old looks: Sunward spires and a bow gun pair, Hegemony prongs and turret rows, Hullbreaker chains, Eclipse shade facing forward; Chorus glow is bile yellow-green in the sheet and amber in the table. |
| docs/playbooks/sound.md | LIVE | First cut. "Short and dry" is the Board's reading, not Ryan's words. |
| docs/REVIEW_PROTOCOL.md | LIVE | |
| docs/ship_pipeline/README.md | HISTORY | The October browser pipeline (Qwen views, Pixal3D, projection, .vsm, phone LOD). Replaced by RECIPE.md and ships.md. |
| docs/ship_pipeline/BLOB_SWEEP.md | PARTLY STALE | "Not shown to Ryan until it passes" was turned into a viewing instrument by R121; the rebuild list is for AI meshes the recipe no longer ships; phone shots. The placement and naval rules are live but stated better elsewhere. |
| docs/ship_pipeline/SHIP_QUEUE.md | HISTORY | The 36 old concepts are history (R169); "Ithar have sails" contradicts the Glasswright Never list. |
| docs/ship_pipeline/AUDIT_BRIEF.md | HISTORY | Oct 21 to 22 Pyre-Barge brief. Keep its "don't get stuck ... not constrained" quote for the rulebook preamble. |
| docs/ship_pipeline/AUDIT_SYNTHESIS.md | HISTORY | Says "the owner's rule allows stern guns aft" and lists jackstaffs, bollards, yards, crow rail and funnels as fixes to make. Dangerous if followed. |
| docs/ship_pipeline/TEXTURE_PASS.md | HISTORY | Browser texture pass; Pixel phone questions. |
| docs/ship_pipeline/GRAPHICS_REVIEW.md | HISTORY | Babylon fixes. |
| docs/ship_pipeline/RECIPE.md | LIVE | Breach contract "exactly six" contradicts the class table (R164); outline gate 0.90 as a hard exit. |
| contrib/opus/go-forward-plan.md | HISTORY | Replaced by PROGRAM.md (R167): Babylon, commit to main, 12 s round target, phone, helper rules. Its Oct 24 owner rulings (battle size, shields, capture) are carried in AGENTS.md. |
| briefs: movement_spec.md | PARTLY STALE | The glide model is written as the R76 prohibitions R189 says were misread; it describes braking and side jets the default game does not fire; the bank is now to be removed. R189 says rewrite it. |
| briefs: campaign_rail_orders_sheet.md | LIVE | The interface look. |
| briefs: ui_style.md | PARTLY STALE | Sections 1 to 8 are Lime Tactical (R149), which the orders sheet replaces screen by screen; only the "Orders sheet" section at the end is the live look. |
| briefs: ui_spec.md | PARTLY STALE | Scale law, focus ring, settings, debrief order live; the gold palette, fonts and 12 px floor are superseded; the flash cap line is the R187 problem. |
| briefs: ui_spec_constants.md | LIVE | Generated table. |
| briefs: debrief_spec.md | LIVE | Content and order; its look must follow the orders sheet. |
| briefs: campaign_map_briefing.md | HISTORY | Replaced by the rail brief (R176, R177) and map rounds 3 to 4c (R170 far stops 85 percent, R174 rings off). |
| briefs: blender_build_harness.md | LIVE | "No downloaded textures, even CC0" conflicts with TEXTURE_PASS.md and the plan. |
| briefs: codex_fb1, fb2, fb3, feel_pass_2026-11-01 | HISTORY | Finished jobs. fb2 is where "no side-to-side shuffle" and "thruster puffs only while turning" were written for a builder (R189). feel_pass still says commit to main and never use computer control. |
| briefs: lore_rollout_2026-10-27 | HISTORY | Done; its Eclipse white-gold repaint is overruled by R169 (green stays). Ids-never-change carries on in AGENTS.md. |
| briefs: muse_standing_rule.md | PARTLY STALE | Still names Argon as a working leg (blocked since Nov 5); "FINDINGS overrides every doc" should become the rulebook. |
| briefs: the 17 dated Muse briefs (Oct 25 to Nov 2), takeover_2026-10-27, progression_next_2026-11-01 | HISTORY | Finished jobs; house rules say commit to main and use Argon. |
| contrib/opus/LOOP.md (standing sections) | PARTLY STALE | How a run works and Known traps are live. Lock is for the deleted hourly task; "Seats right now (Nov 7)", Queue (Nov 8), Holds and Waiting on Ryan are history. |
| docs/feedback/ | HISTORY | Six October screenshots, no rule text. |
| .claude/skills/playtest-and-balance | PARTLY STALE | "waits under 15 s per round (target 12)" retired by R64; job.bat lines superseded by the queue. |
| .claude/skills/screenshot-verdict | LIVE | |
| .claude/skills/ship-kit | PARTLY STALE | Whole procedure is the browser Pyre-Barge chain; should point at tools/recipe. |
| contrib/README.md | PARTLY STALE | "Good first tasks" build on c19_kit.py and the old ship queue. |

## Counts

313 entries.

| Area | Entries |
|---|---|
| agents and process | 71 |
| ships and concepts | 59 |
| battle look | 44 |
| ship build pipeline | 42 |
| screens and UI | 38 |
| PC and tools | 20 |
| movement | 13 |
| rules of play | 9 |
| battle sound | 8 |
| lore and names | 5 |
| map | 3 |
| campaign | 1 |

| Verdict | Entries |
|---|---|
| KEEP | 165 |
| RETIRE | 59 |
| REWORD TO ITS PURPOSE | 45 |
| KEEP AND ADD THE REASON | 41 |
| ASK RYAN | 3 |

Said by: Board 195, Ryan 105, agent 12, unknown 1. Most rules in these files are the Board's own; most of the stale ones are too, so the Board can fix them without asking.

## The twenty most restrictive for the least reason (ranked)

1. **plan-08 / uispec-04, the flash cap.** "At most 3 flashes a second" became a counter that treats anything 6 percent of screen height as a flash, about 13 times stricter in area than the WCAG rule it cites (R187), and every effect was sized under it. ASK RYAN.
2. **movespec-01, the glide model.** "Thruster puffs only where the hull turns; no side-to-side shuffle" is the R76 misreading R189 corrects. It removed braking burns and slides.
3. **effects-02 and deaths-12, the staging table pixels.** Every hit and death is one exact pixel size by kind and by target, never by gun; numbers nobody chose by eye, set under item 1.
4. **effects-07, "within 15 percent and two frames".** The check locks every effect to the table. Its only reason is the table.
5. **deaths-05, "two capped halves".** The tidy wreck rule that made deaths look sliced (R186).
6. **screens-01 to 03, the lime system.** The playbook still tells the next screen to use the lime accent, filled lime button, sage text and 12 px small caps that Ryan called AI-made (R174, R176).
7. **recipe-06, exactly six breach anchors.** The check fails any hull with more or fewer, while the playbooks say the count follows class and faction (R164).
8. **ships-05 / recipe-03, the 90 percent outline gate.** A hard exit on a number nobody chose by eye; R156 already put the look ahead of it.
9. **blob-01, "not shown to Ryan until it passes".** A pass bar R121 removed.
10. **concepts-14, fixed proportions per class.** Board-guessed ratios (Hegemony 4.5 : 1 : 0.5) that Ryan had to correct ("too fragile and slender").
11. **concepts-02 and concepts-03, "exactly its mounts" and "flak is one small cluster".** Read literally they forbid the barrel rows and four flak turrets Ryan picked (R176, R180).
12. **loop-11, fire caps 4, 8, 12 pinned in a check** when the research asked for 1, 2, 3 and nobody ruled.
13. **movespec-04, the 4 degree bank.** An aircraft tell kept as a "cinematic accent" (R188).
14. **sound-02, "short and dry".** The Board's reading of "Clean and tactical"; may cut deaths short, which the cinematic audit already flagged.
15. **concepts-08, engines fill a quarter to a half of the stern face; nothing else glows like an engine.** A proportion with no reason, and the second clause can be read against R189's jets.
16. **concepts-09, one continuous spine; break lines at the two or three narrowest places.** No reason; strains Chorus and the Eclipse ring.
17. **factions-03, one main colour and one accent light.** Fights the Hullbreaker trophy colours and the Glasswright fringe.
18. **harness-03, no downloaded textures even CC0.** Blocks free real-photo materials other docs recommend.
19. **plan-07, no board pixel brighter than 40 percent of mid grey.** A research number never checked against Ryan's eye.
20. **screens-04, 8 px grid and column padding 40.** Copied from one mockup generator.

## Contradictions and duplicates (both sources each)

- Accent colour: docs/playbooks/screens.md:16 and ui_style.md:23 (lime) vs campaign_rail_orders_sheet.md:34, ui_style.md:221 and PROGRAM.md:162 (ember, every screen follows); ui_spec.md:106 still says gold.
- Battle HUD: PROGRAM.md:41 and screens.md:91 (keeps Lime Tactical slabs) vs PROGRAM.md:162 and HANDOFF.md:25 (battle screen is next in the orders sheet look).
- Text floor: ui_spec.md:83 and screens.md:21 (12 px) vs campaign_rail_orders_sheet.md:94 (17 px for anything read).
- Rail veil: campaign_rail_orders_sheet.md:51 (92 percent) vs ui_style.md:237 (96 and 94 percent after the readability pass).
- Far stops: campaign_map_briefing.md:62 (70 percent size, half brightness) vs R170 (85 and 75 percent).
- Movement: movement_spec.md:7 and codex_fb2:7 (puffs only on turns, no shuffle) vs R189 (jets on braking, turns and slides; a smooth slide is right). movement_spec.md:11 (retro jets while braking) vs the default glide, which fires none.
- Bank: movement_spec.md:13 (up to 4 degrees) vs the movement audit (remove) and the cinematic audit (10 to 12).
- Round time: playtest-and-balance SKILL.md:20 and go-forward-plan.md:370 (12 s target, 15 s limit) vs feel_pass:23 and R64 (retired).
- Breach anchors: factions.md:30 and ships.md:50 (by class and faction) vs RECIPE.md:86 and tools/recipe/check_export.py:137 (exactly six).
- Concept sheets: ships.md:21 (three views: side, top, front) vs concepts_round2.md:107 (top and side design sheet, then a beauty view).
- Flak: concepts_round2.md:44 (one small cluster) vs concepts_round2.md:47 (two to four turrets in pairs), same gate line.
- Eclipse ring: concepts_round2.md:216 (E1: "never lies flat") and factions.md:139 (shade faces forward) vs concepts_round2.md:74 and R183 (ring laid flat, identity from above).
- Hegemony bow: factions.md:72 (ion prongs, turret rows) vs concepts_round2.md:55 (no prongs, recessed trench) and R185 (low sunk guns).
- Hullbreaker chains: factions.md:90 (chains between sections) vs concepts_round2.md:96 and R185 (nothing hangs off).
- Chorus glow: factions.md:160 (bile yellow-green) vs factions.md:183 (amber).
- Sunward look: factions.md:49 (spire row, bow gun pair) vs factions.md:178 (S8: forked prow, recessed lance, rear radiator bank).
- Eclipse colour: lore_rollout_2026-10-27.md:105 (white-gold corona, violet-white glow) vs factions.md:129 and R169 (green corona line).
- Backward guns: AUDIT_SYNTHESIS.md:33 ("owner's rule allows stern guns aft") vs AGENTS.md:69 and every later doc (never backward).
- Naval parts: AUDIT_SYNTHESIS.md:83 (add jackstaff, bollards, yards, crow rail, funnels) vs AGENTS.md:72 and gate line 11.
- Glasswright sails: SHIP_QUEUE.md:70 ("Ithar have sails") vs factions.md:123 (never sails).
- Blob sweep: BLOB_SWEEP.md:3, AGENTS.md:97 and ship-kit SKILL.md:20 (a pass, clean or rebuild) vs ships.md:52 and R121 (a viewing instrument, no pass bar).
- Floating parts: ship-kit SKILL.md:19 (1.5 mm) vs RECIPE.md:59 (0.002 of length).
- Assets: blender_build_harness.md:10 (no downloaded textures, even CC0) vs TEXTURE_PASS.md:14 and go-forward-plan section 3 (ambientCG, Poly Haven CC0).
- Concept tool: AGENTS.md:49 (Rey's image models, local ComfyUI) vs factions.md:193 and R173 (Codex's image tool for finals; no ComfyUI while Ryan uses the GPU).
- Computer control: feel_pass:86 and playtest-and-balance SKILL.md:28 (never) vs R126 and LOOP.md:225 (click tier allowed; never for unsticking jobs).
- Push to main: go-forward-plan.md:548, feel_pass:72, takeover:11 and the Muse house rules (commit to main) vs AGENTS.md:16 and R75 (branches and PRs only).
- Argon: muse_standing_rule.md:10 and 21 (Argon reviews and drafts) vs AGENTS.md:1 (blocked since Nov 5).
- Seats: three tables disagree: AGENTS.md:40 (Fable Board), LOOP.md:17 (Nov 7, Codex down), HANDOFF.md:16 (R180, the current one); PROGRAM.md:58 is a fourth.
- Thread count: PROGRAM.md:148 (Board plus two Fable helpers) vs go-forward-plan.md:503 (two-helper rule retired) vs the project instructions (2 or 3 threads at once).
- Flame cap: effects.md:13 and deaths_and_hits.md:22 state it the same way (duplicate, both need the R88 reason added).
- Space not naval is stated nine times with different lists (AGENTS.md:72 and 95, BLOB_SWEEP.md:40, ship-kit SKILL.md:10, factions.md:19, ships.md:58, concepts_round2.md:83, go-forward plan item 9, lore review brief:28). Gate line 11 is the full one; the rest should point to it.
- Never backward guns is stated in nine places (see agents-17 note).

Rules whose only reason is another rule: effects-07 (the table), recipe-03 and ships-05 (the gate is its own reason), deaths-02 (repeats effects-03), concepts-07 (repeats agents-17), skill-sk-02 (repeats AGENTS.md).

Rules the playbooks repeat from an older brief (fix one, the other stays wrong): screens.md section 2 from campaign_map_briefing.md; deaths_and_hits.md hit ladder and effects.md sizes from the hit staging table; movement_spec.md from codex_fb2; factions.md faction sheets from the round 1 directions and the lore bible; ship-kit skill and AGENTS.md "Ship models" from the October pipeline README.

## ASK RYAN

1. **The flash cap (plan-08, uispec-04).** His standing pick (R187): "Keep comfort, loosen rest", with the Board's note that relaxing FLASH_CAP is his call with the facts. The rule as stated: at most 3 flashes a second, and the code counts any flash over 6 percent of screen height. Proposed: "At most three large flashes a second, where large means flashes that together cover more than the WCAG 2.3.1 area at the player's screen (about a 234 px disc at 1080); reduce flashing goes further. Prove any change with the salvo test."
2. **Lime Tactical (uistyle-01).** His words when he picked it (R149): "yeah i like lime tactical, run it". Later: "R2, let's just do a readability pass on it as well. But I like the direction" and "Map first, then all". Proposed: "Retire Lime Tactical: each screen moves to the orders sheet look when it is next built, the battle screen next." Likely a one-line yes, but it is his pick being retired.

Not put to him because R189 already gives his purpose: the movement wording (movespec-01). The Board can rewrite it without asking.

## Could not determine

- Where "no hot core at full heat longer than 0.25 s" was ruled: the staging synthesis gives Ryan's 0.70 s split but no quote for 0.25 s.
- Whether the "Playtest: everything unlocked" switch (progression-01) is still on.
- The frame gate numbers PROGRAM.md says live in a space playbook: no such file exists.
- Line numbers for the go-forward plan and briefs are from main at c04d439; LOOP.md changes daily, so its line numbers will drift.
