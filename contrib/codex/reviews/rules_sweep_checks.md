# Rules sweep: code and checks, issue 496

The main risks are exact presentation tests, the browser visual drift ceiling, and comments that turn tuning into a prohibition. Preserve save integrity, rules parity, comfort and measured frame cost. Reword the look tests when the Board picks a new look. Do not change game balance to satisfy an old presentation test.

Reviewed checkout: `4d13a0cb29cc7cfe62eabecae7d05a18b3e493b7`, branch `codex/issue-496`, Nov 11 2026. Read the full [issue 492 plan](https://github.com/rcbailey12/voidsworn/issues/492), FINDINGS through R192, both code audits, and the entry/review instructions. This task is a read-only register: only this report and its JSON companion are delivered. No commit or push.

The JSON has **3,363 source records**: 2,420 check/assertion/guard/registration records, 876 code-comment records, and 67 sampled document claims across 20 documents. **20 sampled claims are stale or contradicted**; one debrief target is explicitly prospective. These are source sites, including loops and registrations, not a count of independent bugs or executed tests.

Standing checks ran once, with `node contrib/opus/tools/run_all_checks.js --json`: **exit 0, 41 PASS, 2 KNOWN, no FAIL and no SKIP rows**. KNOWN: seven listed findings (KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5), and twelve visual constant differences. The findings output also skips 31 triaged opinion/stale cases internally. Local Node is v24.14.0; CI pins Node 22. The temporary JSON and log are kept outside the checkout. The runner briefly writes checks_report.json; that generated file was moved to TEMP after the run.

Evidence terms: OBSERVED means the source expression/quote or run result was inspected. INFERRED means the claimed conflict or future failure follows from that expression; a proposed patch was not built. `still_true` distinguishes observed source presence from a current ruling. `protects` is a purpose classification, not approval to remove a check. `value.predicate` keeps the actual expression, including symbolic bounds; its enclosing fixture supplies dynamic values. Decoded legacy JS records carry the physical source line plus `decoded_line`. Adjacent comment values are labelled as adjacent, not falsely attributed as owner-selected numbers.

## The twenty that matter most

The task explicitly asks for twenty, overriding the generic review protocol maximum of ten. Quotes below are exact, short source excerpts; future-breakage conclusions are inferred.

| # | Finding | Evidence | Exact quote | Why it matters / recommended treatment | Confidence |
|---|---|---|---|---|---|
| 1 | The flash size rule measures height, not combined bright area. | OBSERVED source; INFERRED impact, `godot/fx/fx.gd:25` | `const FLASH_SCREEN := 0.06` | C1: keep comfort; review the counting model. The audit's replacement is a proposal, not a safety certification. | high |
| 2 | Death tests also demand counted flashes at particular beats. | OBSERVED source; INFERRED impact, `godot/fx/test/destruction_staging_check.gd:81` | `chain_n == 0 if calm` | C1/C5: an area-based counter can correctly count fewer chain flashes and still fail this assertion. Test event staging separately from counted safety events. | high |
| 3 | Hit and muzzle sizes are deliberately below the counter cutoff. | OBSERVED source; INFERRED impact, `godot/fx/fx_weapons.gd:67` | `const HIT_PX := [0.0, 34.0, 46.0, 56.0]` | C3: tuning values, not owner ceilings. No standing test was found demanding these exact hit sizes. | high |
| 4 | Hull lighting is tuned to dodge the same counter. | OBSERVED source; INFERRED impact, `godot/fx/fx_weapons.gd:69` | `const HULL_LIGHT := 7.9` | C1/C3/C7: increasing it invokes a different runtime safety path; no test fixes light range at 30. | high |
| 5 | The separate pace script fixes the speed spread. | OBSERVED source; INFERRED impact, `tools/pacecheck_godot.sh:30` | `500 <= per <= 950` | M3/M5/M12: slower heavy-hull tuning may fail this manual check. It is not in CI. R131 retains the cap/sequential policy; R189 clarifies the purpose. | high |
| 6 | A capital death must return exactly 2.67 s. | OBSERVED source; INFERRED impact, `godot/fx/test/death_leap_check.gd:39` | `2.67` | C5: changing death length trips this. Jitter inside the existing window need not. Tie waits to the death timeline. | high |
| 7 | Large death piece counts are fixed. | OBSERVED source; INFERRED impact, `godot/fx/test/destruction_staging_check.gd:103` | `"a cruiser parts in two, a capital in three"` | R186: preserve opaque interiors and cleanup; exact 2/3 counts should not prevent missing bites and uneven wreckage. | high |
| 8 | One cap-geometry test fixes the recessed area formula. | OBSERVED source; INFERRED impact, `godot/fx/test/destruction_steps_check.gd:62` | `7.0 * 0.982 * 0.982` | R186: a new ragged cap can fail the old area fixture; open-edge and finite-vertex checks remain valuable. | high |
| 9 | Damage throat size is tested as a look constant. | OBSERVED source; INFERRED impact, `godot/fx/test/damage_surface_check.gd:67` | `s.hull.L * 0.032` | Keep surface seating and rule-state correspondence; do not mistake the precise radius for save or crash protection. | high |
| 10 | Adding audio content fails an exact cue-table count. | OBSERVED source; INFERRED impact, `godot/audio/test/audio_check.gd:72` | `s.cues.size() == 67` | C4/C8: reuse of existing hit/variant cues passes; new ids require this count to change deliberately. | high |
| 11 | Big-death sounds have once-only expectations. | OBSERVED source; INFERRED impact, `godot/audio/test/audio_check.gd:140` | `heard.count(n) == 1` | C8: multiple secondary blasts using the same tested cue can fail; varying existing once-only layers need not. | high |
| 12 | Audio voice caps are a different protection from cue count. | OBSERVED source; INFERRED impact, `godot/audio/test/salvo_check.gd:23` | `s.active.size() <= s.max_voices` | C4/C8: retain bounded voices, actual starts and cancellation. More per-shot requests do not inherently fail this. | high |
| 13 | Music has a hard 150 MB test. | OBSERVED source; INFERRED impact, `godot/music/test/music_check.gd:50` | `total < 150 * 1048576` | Not the measured scene gate. Record the content/storage reason before treating it as a lasting budget. | high |
| 14 | The shared text floor is 12 while the orders rail enforces 17. | OBSERVED source; INFERRED impact, `contrib/opus/tools/ui_spec_tests.js:21` | `MIN_TEXT === 12` | Not a direct logical contradiction: 12 is global minimum, 17 a stricter rail rule. Raising the global minimum needs an intentional test edit. | high |
| 15 | UI tests lock detailed layout and palette syntax. | OBSERVED source; INFERRED impact, `contrib/opus/tools/ui_spec_tests.js:93` | `const COL_W := 540` | They also lock 40 px padding, 43% veil, 56 px action, font families, ember hexes and tier factors. Preserve focus/legibility, update picked look intentionally. | high |
| 16 | Visual oracle drift is already at its ceiling. | OBSERVED source; INFERRED impact, `contrib/opus/tools/checks_baseline.json:6` | `"driftDifferedCeiling": 12` | The guard compares FAC3D, AI_HULLS, CLS_LEN, FINISH, nebula, rocks and planets. One more unmatched value can block a valid Godot look; this is not rules parity. | high |
| 17 | The old auto-facing opinion check is not a current blocker. | OBSERVED source; INFERRED impact, `contrib/opus/tools/checks_baseline.json:207` | `"UI-8"` | M10: UI-8 is triaged opinion and skipped. Do not repair the frozen browser UI just to make that skipped proposal pass. | high |
| 18 | Backdrop scale asserts still enforce numbers Ryan retired. | OBSERVED source; INFERRED impact, `godot/world/world.gd:848` | `"Backdrop rock exceeds 0.05 rad"` | R191 replaces hard 0.05 rad / 4.4 ratios with apparent scale. Assertions change when the environment is next worked on. | high |
| 19 | Recipe export still requires exactly six breach anchors. | OBSERVED source; INFERRED impact, `tools/recipe/check_export.py:137` | `count['breach'] != 6` | R164 item 4 says no fixed count. Keep on-hull, outward-normal, clear-space and real weapon-arc checks independently. | high |
| 20 | Tests can pass while default-mode documentation is false. | OBSERVED source; INFERRED impact, `godot/render/ship_view.gd:1134` | `rotation.x = glide_bank` | FX API says ShipView never writes roll; main README says no banking. Twenty sampled false/stale claims are listed below. R73 slowmo exists only as a helper/test call, not a live death beat. | high |

## What each audit fix would trip

C1..C10 mean the numbered sections in cinematic_audit_code.md; M1..M10 mean the numbered sections in movement_audit_code.md. These are their first ten numbered findings, not a new ranking. A conditional blocker means a particular implementation would fail; it does not claim every version of the fix fails.

| Finding | Existing check affected | Verdict for the proposed fix |
|---|---|---|
| C1 flash area/counting | destruction_staging_check.gd exact/minimum flash counts; fx_smoke.gd, death_leap_check.gd rolling maximum | Count-dependent staging assertions need changing; <=3 rolling maximum and zero calm counted flashes must still pass. Retain comfort checks. |
| C2 death camera hold | No exact 1.6 s camera-release assertion found; bot_battle timeout only indirectly | No direct blocker. Default cut-ins already conflict with R123 prose; Board must settle that policy. Longer accumulated presentation has a conditional 300 s driver / 360 s CI risk. |
| C3 shooter-weight hit size | No exact HIT_PX/MUZ_PX guard; shared flash tests and optional spawn checks | No direct numeric blocker. Larger close-up flashes must still meet the comfort contracts. Palette/table edits can additionally affect visual drift. |
| C4 per-shot and weapon-specific sound | audio_check.gd 67 cues; salvo_check.gd starts/caps/cancellation | Existing cue dispatch and per-shot calls need no count change. Adding cue ids trips 67. Keep starts/caps, defer relation and stop_all tests. |
| C5 irregular intervals and secondaries | destruction_staging_check.gd chain/core counts and windows; death_leap_check.gd 2.67 and release spacing; fx_death_spawn_tests.js source shape | Conditional: times crossing observed test windows, changed death duration, or refactored flipbook call spelling fail. Jitter that preserves those contracts may pass. Rolling comfort maximum remains. |
| C6 stronger shake/punch | No exact trauma-square, distance-divider, .06 amplitude or 6% punch assertion found | No direct blocker. Preserve shake_scale, reduce-flashing adjustment and reduce-motion behavior. Measured scene cost stays protected. |
| C7 variable light range/warm tails | No exact 30-unit light-range assertion found; global flash counter and scene measurement | No direct range blocker. A larger light peak can spend the flash budget; wider lights need frame-cost measurement. Visual drift only if compared palette fields change. |
| C8 varied death sound and tails | audio_check.gd once-only death cues, 67 ids, synthetic slowmo-release wait | Existing clip variants and duration fields need not fail. Repeating tested cues or adding ids does. Preserve actual split alignment, hulk silence policy and reduced-flashing sting suppression unless deliberately re-ruled. |
| C9 connect slow motion | destruction_staging_check.gd helper <0.8 real s and hurry reset; audio_check.gd synthetic beat wait | Merely calling the existing helper should pass. Lengthening its beat beyond the helper bound fails. No current integration test requires production to call it. |
| C10 misses pass then fade | No miss-shape or exact fade-time assertion found; fx_smoke.gd impact count and lifetime/crash protection | No direct blocker for presentation-only fly-past/fade. Preserve one impact result per shot and eventual cleanup; do not introduce damage for a miss. |
| M1 engine follows acceleration | tools/pacecheck_godot.sh only if timing changes; exhaust persistence tests | No direct thrust-curve assertion. Existing emitted-position and expiration tests should pass; pure engine phase changes are not timed by parity. |
| M2 smooth slides/back-offs | No heading-blend or 0.45 drift-bias assertion found | No direct blocker. R189 explicitly permits smooth heading-held slides; no new owner ruling is needed merely to remove the old literal prohibition. |
| M3 class-rate turn windows | Manual pacecheck 500..950 ms/hex, <=7.05 s, no overlap, normal enemy speed | Timing changes may trip the manual script; first preserve the chosen 7 s cap and sequential moves. CI contains no default-glide angular-rate test. |
| M4 braking/side/settle jets | No default-glide jet phase assertion found; FX spawn and lifetime protection | No direct blocker. R189 allows physically sensible braking/turn/slide jets. Keep attachment and bounded emitter lifetimes. |
| M5 heavier upper classes | Manual pacecheck fixed cruise interval and move cap | A widened slow-heavy profile can fail the 950 ms ceiling. R131 numbers were unmeasured tuning. The proposed fix keeps the 7 s cap; do not remove it accidentally. |
| M6 distinct pulled playback | Rules parity if the event/results change; no pull-presentation assertion found | Holding heading while ending at the same rules hex is a look change and should pass parity. Do not change the pulled event or gravity result. |
| M7 avoid friends / hull-scaled clearance | Rules queries and same state/RNG protection; no 9/-7.5 clearance assertion found | No direct blocker for playback-only altitude/phase treatment. Keep final rules hex and query purity. Changing reach occupancy rules would require both twins. |
| M8 remove aircraft bank | No four-degree bank test found; squadron_check tests craft weave separately | No direct hull-bank blocker. Do not remove strike-craft weave accidentally. The two audits disagree; R189 purpose and the Board reading favor space motion. |
| M9 improve routes | Rules parity, event path records, Grax allScars tree coverage, if rule search changes | Changing only one twin fails parity. Updating both may change allScars outcomes, so this is not guaranteed to preserve play. The LOOK option that preserves rule path/events should pass. |
| M10 improve suggested facing | UI-8 findings proposal exists but is skipped as opinion; no live _best_facing fixture found | No present automatic blocker to the default-facing presentation helper. Same explicit commands keep same results. It is still a player-default policy change for the Board/Ryan to pick. |

## Rulings and comments

- R131 replaces the movement clauses of R50/R55/R76 as a build reference; R50 hit reactions remain separate. R189 rejects literal bans on braking puffs and smooth slides. The continuous-flight header, old segments description, ENGINE_IDLE comment and fixed timing values must be read in that order, not treated as fresh owner prohibitions.
- R183 withdrew the Board's largest-forward-gun gate. No automatic assertion of that withdrawn gate was found in the scanned checks. Do not use the absence of a test as evidence that the old written gate is current.
- R164 says authored damage anchors have no fixed count; recipe check_export.py still fails counts other than six. R121 removes assumed geometry caps; old station scripts are historical paths, and any live count/triangle limit must earn a measured reason.
- R191 is already in this checkout and matters to this leg: retire lime as screens are rebuilt, shield colour picked later, and rock scale limits reworded to purpose. Existing source is transitional, not evidence that these older calls remain binding.
- R187/R188 protect comfort and frame rate and ask for a list before builds. The two audits' suggested replacement numbers are not owner rulings. This register changes none of them.

The JSON separates comments from assertions: a comment is not an automatic failure. It retains cited ids, surrounding literal assignments and a status note. A bare number with no owner words is marked tuning/unknown, never silently promoted to a mandate. R1/R2/R3 and D-series names sometimes denote local audit items; the cross-reference below identifies matching registry rows but does not assume all same-looking ids have the same origin.

## Documents checked against code

Three or four concrete claims were checked per API/README/spec, with five for the broad FX API. The table records all sampled stale/false claims; the JSON also contains the true claims and the prospective debrief target. A dated description or a wanted column is not automatically called a shipped defect. Current contract claims and superseded build directions are identified separately in the notes. Other dated briefs were scanned for cited rules, not certified as current specifications.

| Document:line | Stale/false claim | Code evidence and correction |
|---|---|---|
| `contrib/opus/briefs/movement_spec.md:11` | Default cinematic braking lights retro jets. | `godot/render/ship_view.gd:1141`: Only the segments path calls _retro_puffs; default glide emits turn couples. R189 permits the proposed fix. |
| `contrib/opus/briefs/movement_spec.md:14` | Default glide has a segment settle of 14%. | `godot/render/ship_view.gd:570`: SETTLE_T belongs to segments; play_glide does not use the segment settle. |
| `godot/fx/API.md:135` | Cruiser/flagship deaths trigger the R73 slow-motion beat in play. | `godot/fx/fx.gd:586`: Definition and direct test exist; no production call. The eligibility data is real, the integration claim is false. |
| `godot/fx/API.md:150` | ShipView never writes root roll/pitch. | `godot/render/ship_view.gd:1134`: Default glide writes roll every frame, alongside the reaction layer. |
| `godot/fx/API.md:116` | Every cruiser-or-bigger death uses two halves at 1.38 s. | `godot/fx/fx_death.gd:51`: Capital has its own row and three pieces; cruiser uses 1.38. |
| `godot/fx/API.md:311` | Faction accent and shield_edge fields are still null. | `godot/fx/faction_looks.json:77`: Several faction accents and two shield edges are populated. |
| `godot/fx/API.md:311` | All effect colours come solely from faction JSON. | `godot/fx/fx_weapons.gd:47`: Plasma has an explicit uniform colour; core lights also use fixed colours. |
| `godot/main/README.md:95` | Cinematic default is segmented rest-to-rest movement. | `godot/scenes/battle/battle.gd:1524`: Segments survives as a debug option. R131 replaced the serial movement clauses. |
| `godot/main/README.md:95` | Default cinematic ships do not bank. | `godot/render/ship_view.gd:1134`: A default glide banks up to four degrees. |
| `godot/main/README.md:98` | Cinematic moves keep the old B2 total duration. | `godot/scenes/battle/battle.gd:1524`: The glide computes its own mass/ramp/spin duration, capped at MOVE_CAP; B2 is debug segments. |
| `godot/main/README.md:122` | Current G2 and campaign headers share Michroma. | `godot/ui/battle/hud.gd:61`: HUD uses Chakra/Azeret; orders sheet uses Big Shoulders/Barlow. These are historical font descriptions. |
| `godot/campaign/README.md:51` | Map stops still use the old concentric ANG0/R_OUT/R_IN layout. | `godot/ui/campaign/map3d.gd:143`: Sector approach layout now computes a different path; named constants no longer exist. |
| `godot/campaign/README.md:55` | Every fight uses the old danger-band hologram. | `godot/ui/campaign/map3d.gd:399`: Fights now use seeded enemy ship groups, numbers/words/crest; old hologram helper absent. |
| `godot/campaign/README.md:60` | Campaign current headers are Michroma and Oxanium. | `godot/ui/campaign/campaign_ui.gd:115`: Campaign theme/rail replaced the old font implementation. |
| `godot/story/README.md:125` | Story arc integration hooks still need building. | `godot/campaign/campaign.gd:2637`: Hook is implemented and guarded by arcs_on=false; disabled content is different from missing integration. |
| `godot/bench/README.md:71` | Look bench preserves live death slow motion. | `godot/bench/look_bench.gd:569`: Setting an effect clock does not invoke death_slowmo; bench also never calls it. No existing death still proves that beat. |
| `contrib/opus/briefs/ui_spec.md:29` | Capital deaths never take the player camera. | `godot/scenes/battle/battle.gd:1969`: Default cine=key selects a kill cut-in; bot and screenshot paths suppress it. This is a live policy/code conflict. |
| `contrib/opus/briefs/ui_style.md:4` | Older lime style clauses are current everywhere. | `contrib/opus/FINDINGS.md:218`: R191 retires lime as each screen is rebuilt. Do not apply the old lime clauses to the next battle screen. |
| `contrib/opus/briefs/campaign_map_briefing.md:27` | Initial Briefing column is 480 px with a filled panel. | `godot/ui/campaign/campaign_ui.gd:606`: Orders-sheet build replaced initial Briefing column; retain as design history. |
| `godot/portraits/README.md:16` | Portrait README seven-painting list describes the current collection. | `godot/portraits/index.json:103`: The dated Oct 26 list is history: index.json now contains 13 painted-admiral entries, including Sable, Mott, Vesh, Thorne, Mirelle and Vaelen beyond that list. Keep as history rather than a current availability contract. |

## What really ran

| Standing row | Result | Detail |
|---|---|---|
| b1_tests | PASS | PASS: exit 0 |
| b3_tests | PASS | PASS: exit 0 |
| b4_tests | PASS | PASS: exit 0 |
| backlog_tests | PASS | PASS: exit 0 |
| campaign_start_test | PASS | PASS: exit 0 |
| capstone_mastery_tests | PASS | PASS: capstone mastery opens at 320, 440 and 600 XP only after the level 8 evolution, and shows its effect. |
| checks_truth_tests | PASS | PASS: the checks runner result words behave as issue 358 requires |
| core_sync_tests | PASS | PASS: core sync tiers at 4/12/25, rare/epic and duo gains, resumed picks, full sync, gifts and all debrief endings. |
| doc_check_tests | PASS | PASS: 48 paths named in the entry documents exist, 39 READMEs state no stale scenario count (godot/rules/test/scenarios.json holds 271) or latest record, and the two stale entry-document claims stay gone |
| effect_caps_tests | PASS | PASS: 227 sum fixtures, 4 derive fixtures, all effect kinds covered and single effects unchanged. |
| free_exit_tests | PASS | PASS: 32 free exits across moon, tomb, haven, every eligible faction, zero and 120 credits, return to map and save. |
| fx_death_spawn_tests | PASS | PASS: the death spawn behaviour check passed on the real hull |
| heat_tests | PASS | PASS: Heat opens after the first loss and pays 2 XP per point to the flown line and 1 to the shadow pool. |
| inheritance_tests | PASS | PASS: paid inheritance matches win, loss and abandon profiles, affordability, tree progress and capped shadow XP. |
| ion_tests | PASS | PASS: exit 0 |
| lineage_tests | PASS | PASS: every faction's XP, tiers, locks, capstones, saves and per-line resets. |
| nemesis_121_tests | PASS | PASS: exit 0 |
| nemesis_122_tests | PASS | PASS: exit 0 |
| nemesis_395_tests | PASS | PASS: exit 0 |
| nemesis_clash_tests | PASS | PASS: 12482 Nemesis adaptation cases, all six factions, scored and fallback choices, caps and forced exhaustion, 30 commander pairs (#121). |
| nemesis_teach_tests | PASS | PASS: exit 0 |
| r1_tests | PASS | PASS: exit 0 |
| shadow_xp_tests | PASS | PASS: quarter and heir half rates, both debriefs, saves, faction scope and lossless capped XP. |
| squadron_auto_tests | PASS | PASS: automatic opening flight, shared AI, Classic rounds, replacements, reserves, cooldown, blocked hexes, dead carriers and optional orders. |
| story_beat3_tests | PASS | PASS: authored beat 3 screens, all five reward keys, exact damage, round 1 sync, free core offers, reloads, all battle kinds and win/loss/retreat expiry. |
| ui_spec_tests | PASS | PASS: exit 0 |
| progression_telemetry_test | PASS | PASS: simulated batch medians per line, old saves, #122 rates read, and the Godot twin. |
| tree_effects_test | PASS | PASS: 215 tree fixtures fired their pick; 7 waiting rows are inert; 3 corrected Hullbreakers rows behave as their text says |
| tree_handoff_test | PASS | PASS: real campaign picks reach the battle for all six factions (four skills each): |
| tree_table_walk_test | PASS | PASS: 281 effect rows reach B.tree through lineagePick, newRun and startBattle; 7 dated waiting rows make no promise; 288 rows walked |
| oracle_copy_test | PASS | PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files |
| nem_assign_enum | PASS | PASS: all issue 120 enumeration checks |
| nem_direct_reads_report | PASS | PASS: report only, 189 direct save reads outside godot/campaign (main 9, render 9, scenes 47, story 41, tools 3, ui 78, world 2) |
| naming_lint_game.test | PASS | PASS: exit 0 |
| naming_lint_game | PASS | PASS: naming lint within the baseline |
| checks | PASS | PASS: within the pack baseline |
| fleet_invariants | PASS | PASS: exit 0 |
| save_fuzz | PASS | PASS: exit 0 |
| softlock_sweep | PASS | PASS: exit 0 |
| table_xref | PASS | PASS: exit 0 |
| findings_tests | KNOWN | KNOWN: 7 listed failure(s): KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5 |
| oracle_drift_guard | KNOWN | KNOWN: 12 constant difference(s) within the baseline |
| fixture_check | PASS | PASS fixture corrupt2 pair |

CI registration has 68 GDScript test files: 40 headless and 28 GPU. Several headless rows run in separately named parity/Nemesis steps. The CI list enforces one registration per file and valid five-field rows, then fails nonzero exits, SCRIPT ERROR, individual timeouts and exhaustion of the 780 s list budget. GPU rows are not run by that headless loop. Rules and campaign parity compare generated current JS against Godot; they are not permanently frozen golden screenshots.

## Recommended next step

When the Board chooses the audit fixes, include a check-change list in each build brief. Change exact look expectations alongside that implementation, while retaining independent safety, final-state, resource-cleanup and rules-parity checks. Start with flash-count-dependent death assertions, the six-anchor export failure and the visual drift ceiling.

## Not checked

No game, test or old document was edited. No proposed fix was implemented or mutation-tested. The full Godot/headless/GPU packs, bot battles and manual pace/scene benches were not rerun: this read-only task required one standing run, and no runtime change was made. No new screenshots, sheets or recordings were needed or produced. Runtime comfort compliance, actual visible turn rates and frame cost require the capture/measurement legs; this report does not certify them. A source scan cannot prove an absence of every dynamically computed restriction. Documentary sampling is explicitly bounded above; unsampled historical prose is not claimed verified.

The source basis is raw bytes from the requested local checkout, pinned above, rather than GitHub's folding page. The generic review protocol's remote-raw-view recipe was adapted to this local job; no remote latest-main content was mixed with local line numbers. Exact source quotes and file endings were re-opened during report validation.

<details><summary>Source-read ledger: complete file lengths, last-line prefixes and full-file ingestion ranges</summary>

This is the complete text-scan corpus, including fixture generators and historical tools. File length/ending evidence is mechanical; it is not a claim that every function was executed. Ranges cover complete files; files over 1,500 lines or 60 KB are split into 500-line ranges for this ledger. Ending prefixes are JSON-escaped so invisible characters and house-rule punctuation remain reviewable without introducing them into this report.

| File | Lines | Ranges | First 40 characters of last line (JSON string) |
|---|---:|---|---|
| `.github/workflows/checks.yml` | 184 | 1-184 | `"          exit $code"` |
| `contrib/muse/tools/checkpack/RUN_CHECKS.bat` | 1 | 1-1 | `"QGVjaG8gb2ZmCmNkIC9kICV+ZHAwCnRpdGxlIFZv"` |
| `contrib/muse/tools/checkpack/checks.js` | 1 | 1-1 | `"Ly8gVm9pZHN3b3JuIG1lY2hhbmljYWwgY2hlY2tz"` |
| `contrib/muse/tools/codex/codex_entries.json` | 1721 | 1-500, 501-1000, 1001-1500, 1501-1721 | `"]"` |
| `contrib/muse/tools/cutover_gate/README.md` | 114 | 1-114 | `"The gate never modifies the repo it chec"` |
| `contrib/muse/tools/cutover_gate/baseline.json` | 276 | 1-276 | `"}"` |
| `contrib/muse/tools/cutover_gate/fixture_check.js` | 88 | 1-88 | `"process.exit(passed === total ? 0 : 1);"` |
| `contrib/muse/tools/cutover_gate/gate.js` | 539 | 1-539 | `"main();"` |
| `contrib/muse/tools/cutover_gate/gate_report.json` | 387 | 1-387 | `"}"` |
| `contrib/muse/tools/cutover_gate/gate_report.md` | 77 | 1-77 | `"Verdict key: PASS = clean and unchanged."` |
| `contrib/muse/tools/cutover_gate/run_gate.bat` | 76 | 1-76 | `"exit /b %GATE_EXIT%"` |
| `contrib/muse/tools/cutover_gate/scratch/telemetry_reference/audit.js` | 65 | 1-65 | `"module.exports = { oldJoinAudit, newJoin"` |
| `contrib/muse/tools/cutover_gate/scratch/telemetry_reference/dataset.js` | 132 | 1-132 | `"module.exports = { buildDataset, ADAPTAT"` |
| `contrib/muse/tools/cutover_gate/scratch/telemetry_reference/logger.js` | 84 | 1-84 | `"module.exports = { createLogger, SCHEMA_"` |
| `contrib/muse/tools/cutover_gate/scratch/telemetry_reference/run_demo.js` | 78 | 1-78 | `"main();"` |
| `contrib/muse/tools/event_expansion/new_events_data.js` | 178 | 1-178 | `"];"` |
| `contrib/muse/tools/findings_tests/README.md` | 407 | 1-407 | `"- BF-7 and BF-8 entered the ledger as Ar"` |
| `contrib/muse/tools/findings_tests/battle_probe.js` | 77 | 1-77 | `"module.exports = { installBattleProbe, s"` |
| `contrib/muse/tools/findings_tests/campaign_loader.js` | 128 | 1-128 | `"module.exports = { loadCampaign, loadGam"` |
| `contrib/muse/tools/findings_tests/findings_tests.js` | 1160 | 1-500, 501-1000, 1001-1160 | `"})();"` |
| `contrib/muse/tools/findings_tests/ui_loader.js` | 89 | 1-89 | `"module.exports = { loadUI };"` |
| `contrib/muse/tools/harness/README.md` | 84 | 1-84 | `"  ordering probe; the per-fleet cap chec"` |
| `contrib/muse/tools/harness/fleet_invariants.js` | 102 | 1-102 | `"process.exit(failures.length ? 1 : 0);"` |
| `contrib/muse/tools/harness/fleet_scaling.js` | 108 | 1-108 | `"process.exit(failures.length ? 1 : 0);"` |
| `contrib/muse/tools/harness/game_loader.js` | 96 | 1-96 | `"module.exports = { loadGame, EXPORTS };"` |
| `contrib/muse/tools/harness/save_fuzz.js` | 120 | 1-120 | `"process.exit(failures.length ? 1 : 0);"` |
| `contrib/muse/tools/harness/softlock_sweep.js` | 128 | 1-128 | `"process.exit(failures.length ? 1 : 0);"` |
| `contrib/muse/tools/harness/validators/README.md` | 73 | 1-73 | `"where the old label names a visual style"` |
| `contrib/muse/tools/harness/validators/naming_allowlist.json` | 1 | 1-1 | `"{\"docs/archive\":[\"Deathless (faction lab"` |
| `contrib/muse/tools/harness/validators/naming_lint.js` | 104 | 1-104 | `"process.exit(hard ? 1 : 0);"` |
| `contrib/muse/tools/harness/validators/table_xref.js` | 155 | 1-155 | `"process.exit(failures.length ? 1 : 0);"` |
| `contrib/muse/tools/importer_fixtures/README.md` | 520 | 1-520 | `"otherwise."` |
| `contrib/muse/tools/importer_fixtures/absent_store.json` | 33 | 1-33 | `"}"` |
| `contrib/muse/tools/importer_fixtures/corrupt2_input.json` | 11 | 1-11 | `"}"` |
| `contrib/muse/tools/importer_fixtures/corrupt2_output.json` | 35 | 1-35 | `"}"` |
| `contrib/muse/tools/importer_fixtures/corrupt_input.json` | 482 | 1-482 | `"}"` |
| `contrib/muse/tools/importer_fixtures/corrupt_output.json` | 497 | 1-497 | `"}"` |
| `contrib/muse/tools/importer_fixtures/early_run.json` | 995 | 1-995 | `"}"` |
| `contrib/muse/tools/importer_fixtures/fleet_edges.json` | 1489 | 1-1489 | `"}"` |
| `contrib/muse/tools/importer_fixtures/fresh.json` | 60 | 1-60 | `"}"` |
| `contrib/muse/tools/importer_fixtures/generate_fixtures.js` | 1239 | 1-1239 | `"verify();"` |
| `contrib/muse/tools/importer_fixtures/half_meta.json` | 74 | 1-74 | `"}"` |
| `contrib/muse/tools/importer_fixtures/half_run.json` | 874 | 1-874 | `"}"` |
| `contrib/muse/tools/importer_fixtures/longlived_meta.json` | 239 | 1-239 | `"}"` |
| `contrib/muse/tools/importer_fixtures/meta_junk.json` | 108 | 1-108 | `"}"` |
| `contrib/muse/tools/importer_fixtures/midrun.json` | 1261 | 1-1261 | `"}"` |
| `contrib/muse/tools/importer_fixtures/nemesis_late.json` | 1232 | 1-1232 | `"}"` |
| `contrib/muse/tools/importer_fixtures/partial_grant.json` | 1216 | 1-1216 | `"}"` |
| `contrib/muse/tools/importer_fixtures/repaired_input.json` | 519 | 1-519 | `"}"` |
| `contrib/muse/tools/importer_fixtures/repaired_output.json` | 576 | 1-576 | `"}"` |
| `contrib/muse/tools/importer_fixtures/reward_mod.json` | 911 | 1-911 | `"}"` |
| `contrib/muse/tools/importer_fixtures/reward_prize.json` | 1067 | 1-1067 | `"}"` |
| `contrib/muse/tools/importer_fixtures/reward_promo.json` | 1067 | 1-1067 | `"}"` |
| `contrib/muse/tools/importer_fixtures/reward_salvage.json` | 1251 | 1-1251 | `"}"` |
| `contrib/muse/tools/importer_fixtures/sector3_run.json` | 1256 | 1-1256 | `"}"` |
| `contrib/muse/tools/importer_fixtures/settled_run.json` | 568 | 1-568 | `"}"` |
| `contrib/muse/tools/importer_fixtures/unlocked.json` | 136 | 1-136 | `"}"` |
| `contrib/muse/tools/importer_reference/README.md` | 279 | 1-279 | `"   or passes through this intermediate s"` |
| `contrib/muse/tools/importer_reference/converter.js` | 646 | 1-646 | `"module.exports = { convert, loadGameCore"` |
| `contrib/muse/tools/importer_reference/run_tests.js` | 306 | 1-306 | `"process.exit(passed === results.length ?"` |
| `contrib/muse/tools/montecarlo/aggregate.js` | 106 | 1-106 | `"console.log(JSON.stringify({ totalRuns: "` |
| `contrib/muse/tools/montecarlo/aggregate.json` | 1530 | 1-500, 501-1000, 1001-1500, 1501-1530 | `"}"` |
| `contrib/muse/tools/montecarlo/aggregate_profiles.js` | 113 | 1-113 | `"console.log(JSON.stringify({ totalRuns: "` |
| `contrib/muse/tools/montecarlo/boongrid.js` | 53 | 1-53 | `"console.log(which, 'cells', cells.length"` |
| `contrib/muse/tools/montecarlo/bot.js` | 47 | 1-47 | `"}"` |
| `contrib/muse/tools/montecarlo/driver.js` | 223 | 1-223 | `"var MC={runOne:mcRunOne,sampleBoons:mcSa"` |
| `contrib/muse/tools/montecarlo/gen_tables.js` | 68 | 1-68 | `"console.log('\\nTimeouts:', a.timeouts, '"` |
| `contrib/muse/tools/montecarlo/grid_shards.sh` | 20 | 1-20 | `"fi"` |
| `contrib/muse/tools/montecarlo/loader.js` | 124 | 1-124 | `"module.exports = { loadGame };"` |
| `contrib/muse/tools/montecarlo/loader_main.js` | 97 | 1-97 | `"module.exports = { loadGame };"` |
| `contrib/muse/tools/montecarlo/policies.js` | 171 | 1-171 | `"};"` |
| `contrib/muse/tools/montecarlo/profiles_aggregate.json` | 4013 | 1-500, 501-1000, 1001-1500, 1501-2000, 2001-2500, 2501-3000, 3001-3500, 3501-4000, 4001-4013 | `"}"` |
| `contrib/muse/tools/montecarlo/run_queue1.sh` | 17 | 1-17 | `"echo \"QUEUE1 DONE $(date +%H:%M:%S)\""` |
| `contrib/muse/tools/montecarlo/run_queue2.sh` | 17 | 1-17 | `"echo \"QUEUE2 DONE $(date +%H:%M:%S)\""` |
| `contrib/muse/tools/montecarlo/shard.js` | 49 | 1-49 | `"main().catch(e => { console.error(e); pr"` |
| `contrib/muse/tools/oracle_drift/DRIFT_REPORT_2026_10_30.md` | 127 | 1-127 | `"picture."` |
| `contrib/muse/tools/oracle_drift/README.md` | 118 | 1-118 | `"  carries the interpretation; this tool "` |
| `contrib/muse/tools/oracle_drift/oracle_drift_guard.js` | 828 | 1-828 | `"main();"` |
| `contrib/muse/tools/port_export/abilities.json` | 69 | 1-69 | `"}"` |
| `contrib/muse/tools/port_export/admirals.json` | 501 | 1-501 | `"}"` |
| `contrib/muse/tools/port_export/arc_name.json` | 7 | 1-7 | `"}"` |
| `contrib/muse/tools/port_export/arc_variant.json` | 8 | 1-8 | `"}"` |
| `contrib/muse/tools/port_export/archetypes.json` | 35 | 1-35 | `"}"` |
| `contrib/muse/tools/port_export/aspects.json` | 55 | 1-55 | `"}"` |
| `contrib/muse/tools/port_export/boon_need.json` | 22 | 1-22 | `"}"` |
| `contrib/muse/tools/port_export/boons.json` | 314 | 1-314 | `"}"` |
| `contrib/muse/tools/port_export/boons_evaluated.json` | 2204 | 1-500, 501-1000, 1001-1500, 1501-2000, 2001-2204 | `"}"` |
| `contrib/muse/tools/port_export/cap_first.json` | 30 | 1-30 | `"]"` |
| `contrib/muse/tools/port_export/cap_last.json` | 30 | 1-30 | `"]"` |
| `contrib/muse/tools/port_export/captains.json` | 266 | 1-266 | `"}"` |
| `contrib/muse/tools/port_export/cls_name.json` | 6 | 1-6 | `"}"` |
| `contrib/muse/tools/port_export/event_fallback.json` | 1 | 1-1 | `"\"quiet\""` |
| `contrib/muse/tools/port_export/events.json` | 1247 | 1-1247 | `"]"` |
| `contrib/muse/tools/port_export/fac_gates.json` | 12 | 1-12 | `"}"` |
| `contrib/muse/tools/port_export/fac_price.json` | 29 | 1-29 | `"}"` |
| `contrib/muse/tools/port_export/fac_verbs.json` | 62 | 1-62 | `"}"` |
| `contrib/muse/tools/port_export/fac_wnames.json` | 45 | 1-45 | `"}"` |
| `contrib/muse/tools/port_export/fac_wpool.json` | 45 | 1-45 | `"}"` |
| `contrib/muse/tools/port_export/fac_wtrait.json` | 35 | 1-35 | `"}"` |
| `contrib/muse/tools/port_export/factions.json` | 97 | 1-97 | `"}"` |
| `contrib/muse/tools/port_export/favour_tiers.json` | 21 | 1-21 | `"]"` |
| `contrib/muse/tools/port_export/fit_slots.json` | 5 | 1-5 | `"}"` |
| `contrib/muse/tools/port_export/heat.json` | 37 | 1-37 | `"}"` |
| `contrib/muse/tools/port_export/hull_variants.json` | 370 | 1-370 | `"}"` |
| `contrib/muse/tools/port_export/hulls.json` | 1567 | 1-500, 501-1000, 1001-1500, 1501-1567 | `"}"` |
| `contrib/muse/tools/port_export/kind_name.json` | 9 | 1-9 | `"}"` |
| `contrib/muse/tools/port_export/legacy.json` | 78 | 1-78 | `"}"` |
| `contrib/muse/tools/port_export/manifest.json` | 433 | 1-433 | `"}"` |
| `contrib/muse/tools/port_export/mastery_perks.json` | 19 | 1-19 | `"]"` |
| `contrib/muse/tools/port_export/mastery_xp.json` | 7 | 1-7 | `"]"` |
| `contrib/muse/tools/port_export/mod_names.json` | 77 | 1-77 | `"}"` |
| `contrib/muse/tools/port_export/mod_need.json` | 9 | 1-9 | `"}"` |
| `contrib/muse/tools/port_export/modules.json` | 110 | 1-110 | `"}"` |
| `contrib/muse/tools/port_export/more_ship_names.json` | 62 | 1-62 | `"}"` |
| `contrib/muse/tools/port_export/move_rules.json` | 33 | 1-33 | `"}"` |
| `contrib/muse/tools/port_export/nem_adapt.json` | 27 | 1-27 | `"}"` |
| `contrib/muse/tools/port_export/nem_adapt_fac.json` | 74 | 1-74 | `"}"` |
| `contrib/muse/tools/port_export/nem_beat_word.json` | 9 | 1-9 | `"}"` |
| `contrib/muse/tools/port_export/nem_clock.json` | 1 | 1-1 | `"4"` |
| `contrib/muse/tools/port_export/nem_fac.json` | 508 | 1-508 | `"}"` |
| `contrib/muse/tools/port_export/nem_lines.json` | 19 | 1-19 | `"}"` |
| `contrib/muse/tools/port_export/nem_persona.json` | 62 | 1-62 | `"}"` |
| `contrib/muse/tools/port_export/nem_traits.json` | 58 | 1-58 | `"}"` |
| `contrib/muse/tools/port_export/nem_weak.json` | 30 | 1-30 | `"}"` |
| `contrib/muse/tools/port_export/node_mods.json` | 12 | 1-12 | `"}"` |
| `contrib/muse/tools/port_export/orders.json` | 6 | 1-6 | `"}"` |
| `contrib/muse/tools/port_export/patrons.json` | 50 | 1-50 | `"}"` |
| `contrib/muse/tools/port_export/perks.json` | 101 | 1-101 | `"}"` |
| `contrib/muse/tools/port_export/rank_xp.json` | 7 | 1-7 | `"]"` |
| `contrib/muse/tools/port_export/ranks.json` | 7 | 1-7 | `"]"` |
| `contrib/muse/tools/port_export/rarity.json` | 22 | 1-22 | `"]"` |
| `contrib/muse/tools/port_export/relic_names.json` | 62 | 1-62 | `"}"` |
| `contrib/muse/tools/port_export/relics.json` | 86 | 1-86 | `"}"` |
| `contrib/muse/tools/port_export/run_word.json` | 8 | 1-8 | `"}"` |
| `contrib/muse/tools/port_export/sector_conds.json` | 32 | 1-32 | `"}"` |
| `contrib/muse/tools/port_export/sector_pool.json` | 16 | 1-16 | `"]"` |
| `contrib/muse/tools/port_export/ship_names.json` | 30 | 1-30 | `"]"` |
| `contrib/muse/tools/port_export/tools/export_data.js` | 107 | 1-107 | `"for (const f of fnPaths) console.log('  "` |
| `contrib/muse/tools/port_export/tools/validate_export.js` | 181 | 1-181 | `"for (const f of findings) console.log('["` |
| `contrib/muse/tools/port_export/validation.json` | 274 | 1-274 | `"}"` |
| `contrib/muse/tools/port_export/validation_report.md` | 55 | 1-55 | `"godot/rules/data/tables.json and godot/c"` |
| `contrib/muse/tools/port_export/w.json` | 303 | 1-303 | `"}"` |
| `contrib/muse/tools/port_export/wing_perks.json` | 26 | 1-26 | `"}"` |
| `contrib/muse/tools/port_export/wing_stances.json` | 14 | 1-14 | `"}"` |
| `contrib/muse/tools/port_export/wing_xp.json` | 5 | 1-5 | `"]"` |
| `contrib/muse/tools/port_export/wtraits.json` | 42 | 1-42 | `"}"` |
| `contrib/muse/tools/port_export/wtraits_source.json` | 52 | 1-52 | `"}"` |
| `contrib/muse/tools/telemetry_reference/README.md` | 69 | 1-69 | `"that it should."` |
| `contrib/muse/tools/telemetry_reference/audit.js` | 65 | 1-65 | `"module.exports = { oldJoinAudit, newJoin"` |
| `contrib/muse/tools/telemetry_reference/dataset.js` | 132 | 1-132 | `"module.exports = { buildDataset, ADAPTAT"` |
| `contrib/muse/tools/telemetry_reference/logger.js` | 84 | 1-84 | `"module.exports = { createLogger, SCHEMA_"` |
| `contrib/muse/tools/telemetry_reference/run_demo.js` | 78 | 1-78 | `"main();"` |
| `contrib/opus/FINDINGS.md` | 364 | 1-364 | `"\| X17 \| Muse follow-up pass over unasses"` |
| `contrib/opus/briefs/blender_build_harness.md` | 21 | 1-21 | `"The examples' budgets and character rigg"` |
| `contrib/opus/briefs/campaign_map_briefing.md` | 102 | 1-102 | `"- What Ryan will see: the Briefing layou"` |
| `contrib/opus/briefs/campaign_rail_orders_sheet.md` | 114 | 1-114 | `"  and anything the Board should rule on."` |
| `contrib/opus/briefs/codex_fb1_playtest_fixes.md` | 30 | 1-30 | `"Tests: parse-check every changed .gd; ru"` |
| `contrib/opus/briefs/codex_fb2_movement_torpedo_tiles.md` | 22 | 1-22 | `"Tests: parse-check changed .gd; rules pa"` |
| `contrib/opus/briefs/codex_fb3_playtest_fixes.md` | 23 | 1-23 | `"Tests: parse-check changed .gd; rules pa"` |
| `contrib/opus/briefs/debrief_spec.md` | 99 | 1-99 | `"- The first-loss kicker and sub for the "` |
| `contrib/opus/briefs/feel_pass_2026-11-01.md` | 99 | 1-99 | `"Use a new tag every time (codex_run.bat "` |
| `contrib/opus/briefs/lore_rollout_2026-10-27.md` | 62 | 1-62 | `"L's map first (B and the Godot mirrors w"` |
| `contrib/opus/briefs/movement_spec.md` | 47 | 1-47 | `"One capture round in #233: the same thre"` |
| `contrib/opus/briefs/muse_2026-10-25_engine_and_b2.md` | 43 | 1-43 | `"- No game code edits, no new design docs"` |
| `contrib/opus/briefs/muse_2026-10-25b_while_opus_paused.md` | 21 | 1-21 | `"Deliverable: `contrib/muse/reviews/findi"` |
| `contrib/opus/briefs/muse_2026-10-25c_engine_proof_audit.md` | 34 | 1-34 | `"Deliverable: `contrib/muse/reviews/engin"` |
| `contrib/opus/briefs/muse_2026-10-26_travel_sprint.md` | 27 | 1-27 | `"Order if time runs short: A, C, F, E, B,"` |
| `contrib/opus/briefs/muse_2026-10-26b_story_review.md` | 9 | 1-9 | `"Deliverable: `contrib/muse/reviews/story"` |
| `contrib/opus/briefs/muse_2026-10-26c_sprint_audits.md` | 28 | 1-28 | `"Order if usage runs short: 3, 1, 2, 5, 6"` |
| `contrib/opus/briefs/muse_2026-10-27_lore_review.md` | 89 | 1-89 | `"- a top summary of five bullets at most,"` |
| `contrib/opus/briefs/muse_2026-10-27b_full_audit.md` | 54 | 1-54 | `"File whatever finishes first; Audit A an"` |
| `contrib/opus/briefs/muse_2026-10-27c_rollout_audit.md` | 51 | 1-51 | `"- Questions for Ryan at the end, multipl"` |
| `contrib/opus/briefs/muse_2026-11-01_destruction_research.md` | 12 | 1-12 | `"Cite primary sources (developer talks, d"` |
| `contrib/opus/briefs/muse_2026-11-01_faction_packages.md` | 24 | 1-24 | `"Do the six feel distinct in look, play a"` |
| `contrib/opus/briefs/muse_2026-11-01b_four_jobs.md` | 22 | 1-22 | `"When each job is done, list the files an"` |
| `contrib/opus/briefs/muse_2026-11-02_three_jobs.md` | 32 | 1-32 | `"Job 2's faction packages are long. Ryan "` |
| `contrib/opus/briefs/muse_2026-11-02b_backdrops.md` | 12 | 1-12 | `"5. A build order sized as Codex tasks (f"` |
| `contrib/opus/briefs/muse_standing_rule.md` | 28 | 1-28 | `"Time estimates (Ryan, Nov 4 10:40 CST, F"` |
| `contrib/opus/briefs/progression_next_2026-11-01.md` | 20 | 1-20 | `"So the progression phase includes, per f"` |
| `contrib/opus/briefs/takeover_2026-10-27.md` | 25 | 1-25 | `"Commit, then end your turn with a short "` |
| `contrib/opus/briefs/ui_spec.md` | 269 | 1-269 | `"- Scene (.tscn) files were not scanned f"` |
| `contrib/opus/briefs/ui_spec_constants.md` | 302 | 1-302 | `"- 9, godot/ui/campaign/campaign_ui.gd:65"` |
| `contrib/opus/briefs/ui_style.md` | 245 | 1-245 | `"- Every sentence and figure on the rail "` |
| `contrib/opus/reviews/cinematic_audit_code.md` | 357 | 1-357 | `"- Frame cost of wider lights (finding 7)"` |
| `contrib/opus/reviews/movement_audit_code.md` | 392 | 1-392 | `"- Brisk mode and strike craft were read "` |
| `contrib/opus/tools/RUN_ALL_CHECKS.bat` | 8 | 1-8 | `"exit /b %CHECK_EXIT%"` |
| `contrib/opus/tools/b1_tests.js` | 245 | 1-245 | `"if (require.main === module) (async () ="` |
| `contrib/opus/tools/b3_tests.js` | 123 | 1-123 | `"  console.log('\\nB3 tests: ' + pass + ' "` |
| `contrib/opus/tools/b4_tests.js` | 168 | 1-168 | `"  console.log('\\nB4 tests: ' + pass + ' "` |
| `contrib/opus/tools/backlog_tests.js` | 82 | 1-82 | `"  console.log('\\nBacklog tests: ' + pass"` |
| `contrib/opus/tools/campaign_start_test.js` | 61 | 1-61 | `"console.log(out.join('\\n')); console.log"` |
| `contrib/opus/tools/capstone_mastery_tests.js` | 72 | 1-72 | `"console.log('PASS: capstone mastery open"` |
| `contrib/opus/tools/checkpack/RUN_CHECKS.bat` | 16 | 1-16 | `"pause"` |
| `contrib/opus/tools/checkpack/checks.js` | 198 | 1-198 | `"                  : 'No hard failures. W"` |
| `contrib/opus/tools/checks_baseline.json` | 221 | 1-221 | `"}"` |
| `contrib/opus/tools/checks_truth_tests.js` | 118 | 1-118 | `"process.exit(fail ? 1 : 0);"` |
| `contrib/opus/tools/core_sync_tests.js` | 59 | 1-59 | `"console.log('PASS: core sync tiers at 4/"` |
| `contrib/opus/tools/coverage_index.js` | 115 | 1-115 | `"  first40Uncited: uncited.slice(0, 40) }"` |
| `contrib/opus/tools/doc_check_tests.js` | 167 | 1-167 | `"  + ') or latest record, and the two sta"` |
| `contrib/opus/tools/effect_caps_tests.js` | 61 | 1-61 | `"console.log('PASS: ' + sums.length + ' s"` |
| `contrib/opus/tools/free_exit_tests.js` | 94 | 1-94 | `"  ', every eligible faction, zero and 12"` |
| `contrib/opus/tools/fx_death_spawn_tests.js` | 71 | 1-71 | `"console.log('PASS: the death spawn behav"` |
| `contrib/opus/tools/heat_tests.js` | 66 | 1-66 | `"console.log('PASS: Heat opens after the "` |
| `contrib/opus/tools/inheritance_tests.js` | 66 | 1-66 | `"console.log('PASS: paid inheritance matc"` |
| `contrib/opus/tools/ion_tests.js` | 45 | 1-45 | `"})();"` |
| `contrib/opus/tools/lineage_tests.js` | 101 | 1-101 | `"console.log('PASS: every faction\\'s XP, "` |
| `contrib/opus/tools/mega_report.py` | 62 | 1-62 | `"print('campaign', len(camp), 'fm', bool("` |
| `contrib/opus/tools/naming_lint_allow.json` | 30 | 1-30 | `"}"` |
| `contrib/opus/tools/naming_lint_game.js` | 185 | 1-185 | `"if (require.main === module) main(proces"` |
| `contrib/opus/tools/naming_lint_game.test.js` | 40 | 1-40 | `"}"` |
| `contrib/opus/tools/nem_direct_reads_report.js` | 34 | 1-34 | `"console.log('PASS: report only, ' + tota"` |
| `contrib/opus/tools/nemesis_121_tests.js` | 211 | 1-211 | `"})();"` |
| `contrib/opus/tools/nemesis_122_tests.js` | 160 | 1-160 | `"})();"` |
| `contrib/opus/tools/nemesis_395_tests.js` | 141 | 1-141 | `"})();"` |
| `contrib/opus/tools/nemesis_clash_tests.js` | 116 | 1-116 | `"console.log('PASS: ' + fixtures.length +"` |
| `contrib/opus/tools/nemesis_teach_tests.js` | 107 | 1-107 | `"})();"` |
| `contrib/opus/tools/oracle_copy_test.js` | 51 | 1-51 | `"console.log('PASS: no oracle folders exi"` |
| `contrib/opus/tools/pc_simjob.py` | 30 | 1-30 | `"print(open(f'{out}/sb_{tag}.bat').read()"` |
| `contrib/opus/tools/playlog_report.js` | 201 | 1-201 | `"}"` |
| `contrib/opus/tools/playlog_report.test.js` | 76 | 1-76 | `"}"` |
| `contrib/opus/tools/progression_telemetry_test.js` | 90 | 1-90 | `"console.log('PASS: simulated batch media"` |
| `contrib/opus/tools/r1_tests.js` | 176 | 1-176 | `"  console.log('\\nR1 tests: ' + pass + ' "` |
| `contrib/opus/tools/run_all_checks.js` | 249 | 1-249 | `"module.exports = { classifyFindings, cla"` |
| `contrib/opus/tools/run_montecarlo.js` | 134 | 1-134 | `"main().catch(e => { console.error(ascii("` |
| `contrib/opus/tools/sb_report.py` | 51 | 1-51 | `"main()"` |
| `contrib/opus/tools/scene_gate_report.py` | 190 | 1-190 | `"    main()"` |
| `contrib/opus/tools/scene_gate_sheet.py` | 144 | 1-144 | `"    main()"` |
| `contrib/opus/tools/shadow_xp_tests.js` | 67 | 1-67 | `"console.log('PASS: quarter and heir half"` |
| `contrib/opus/tools/squadron_auto_tests.js` | 63 | 1-63 | `"main().catch(e => { console.error(e); pr"` |
| `contrib/opus/tools/stall220_report.py` | 112 | 1-112 | `"    main()"` |
| `contrib/opus/tools/story_beat3_tests.js` | 139 | 1-139 | `"console.log('PASS: authored beat 3 scree"` |
| `contrib/opus/tools/tree_effects_test.js` | 319 | 1-319 | `"console.log('PASS: ' + Object.keys(WANT)"` |
| `contrib/opus/tools/tree_handoff_test.js` | 72 | 1-72 | `"for (const line of out.lines) console.lo"` |
| `contrib/opus/tools/tree_table_walk_test.js` | 110 | 1-110 | `"if (require.main === module) run();"` |
| `contrib/opus/tools/ui_constants_diff.js` | 221 | 1-221 | `"}"` |
| `contrib/opus/tools/ui_spec_tests.js` | 185 | 1-185 | `"process.exitCode = fail ? 1 : 0;"` |
| `godot/assets/ships/README.md` | 125 | 1-125 | `"- Nothing here depends on the old `hulls"` |
| `godot/assets/ships/a4_props.gd` | 64 | 1-64 | `"\treturn n"` |
| `godot/assets/ships/manifest.json` | 1725 | 1-500, 501-1000, 1001-1500, 1501-1725 | `"}"` |
| `godot/assets/ships/test/a4_shots.gd` | 384 | 1-384 | `"\t\t\tmi.set_surface_override_material(s, b"` |
| `godot/audio/README.md` | 100 | 1-100 | `"functional verification; listening and a"` |
| `godot/audio/SFX_CREDITS.md` | 101 | 1-101 | `"\| uiRound \| Kenney Impact Sounds; Kenney"` |
| `godot/audio/build/render_ambient_bed.py` | 82 | 1-82 | `"print(\"wrote\", out, os.path.getsize(out)"` |
| `godot/audio/build/render_synth.js` | 60 | 1-60 | `"})();"` |
| `godot/audio/clips/index.json` | 316 | 1-316 | `"}"` |
| `godot/audio/cues.json` | 1997 | 1-500, 501-1000, 1001-1500, 1501-1997 | `"}"` |
| `godot/audio/death_audio.gd` | 67 | 1-67 | `"\t\tsfx.death_beat(false)"` |
| `godot/audio/sfx.gd` | 450 | 1-450 | `"\tcreate_tween().tween_property(_amb, \"vo"` |
| `godot/audio/test/audio_check.gd` | 181 | 1-181 | `"\tquit(0 if fails.is_empty() else 1)"` |
| `godot/audio/test/salvo_check.gd` | 86 | 1-86 | `"\tquit(0 if fails.is_empty() else 1)"` |
| `godot/audio/test/smoke_lifetime_check.gd` | 56 | 1-56 | `"\tquit(0 if errors == 0 else 1)"` |
| `godot/bench/README.md` | 83 | 1-83 | `"- The late-shader counter of issue 376 d"` |
| `godot/bench/look_bench.gd` | 615 | 1-615 | `"\treturn true"` |
| `godot/bench/look_moments.json` | 1965 | 1-500, 501-1000, 1001-1500, 1501-1965 | `"}"` |
| `godot/bench/rebake_measure.gd` | 112 | 1-112 | `"\tquit()"` |
| `godot/bench/scene_gate.gd` | 935 | 1-935 | `"\t\t\t\"volumetric_fog\": b.env.volumetric_fo"` |
| `godot/campaign/README.md` | 85 | 1-85 | `"What the harness leaves out, on both sid"` |
| `godot/campaign/campaign.gd` | 3364 | 1-500, 501-1000, 1001-1500, 1501-2000, 2001-2500, 2501-3000, 3001-3364 | `"\t\t\"events\": tel_log.slice(max(0, tel_log"` |
| `godot/campaign/campaign_view.gd` | 410 | 1-410 | `"\treturn \"\""` |
| `godot/campaign/data/campaign_tables.json` | 1 | 1-1 | `"{\"sha256\":\"8c026a3fd5fdcf470c4e389e9b940"` |
| `godot/campaign/test/README.md` | 40 | 1-40 | `"- **Real battles**: both sides use the s"` |
| `godot/campaign/test/RECORD.md` | 121 | 1-121 | `"The screens live in `godot/ui/campaign/`"` |
| `godot/campaign/test/arc_hook_test.gd` | 94 | 1-94 | `"\tquit(1 if fails > 0 else 0)"` |
| `godot/campaign/test/capstone_mastery_shots.gd` | 76 | 1-76 | `"\tPG.finish(0)"` |
| `godot/campaign/test/capstone_mastery_test.gd` | 77 | 1-77 | `"\tquit(0 if failures == 0 else 1)"` |
| `godot/campaign/test/core_sync_test.gd` | 63 | 1-63 | `"\tquit(0 if failures == 0 else 1)"` |
| `godot/campaign/test/debrief_mock_shots.gd` | 232 | 1-232 | `"\treturn cc"` |
| `godot/campaign/test/free_exit_test.gd` | 55 | 1-55 | `"\tquit()"` |
| `godot/campaign/test/heat_test.gd` | 78 | 1-78 | `"\tquit(0 if failures == 0 else 1)"` |
| `godot/campaign/test/heat_ui_shots.gd` | 69 | 1-69 | `"\tPG.finish(0)"` |
| `godot/campaign/test/inheritance_test.gd` | 38 | 1-38 | `"\tquit(0 if failures == 0 else 1)"` |
| `godot/campaign/test/lineage_test.gd` | 92 | 1-92 | `"\tquit(0 if failures == 0 else 1)"` |
| `godot/campaign/test/map_approach_shots.gd` | 114 | 1-114 | `"func _initialize(): root.add_child.call_"` |
| `godot/campaign/test/map_readonly_test.gd` | 280 | 1-280 | `"\tquit(0 if fails == 0 else 1)"` |
| `godot/campaign/test/map_region_shots.gd` | 123 | 1-123 | `"func _initialize(): root.add_child.call_"` |
| `godot/campaign/test/map_travel_test.gd` | 205 | 1-205 | `"\tquit(0 if failures == 0 else 1)"` |
| `godot/campaign/test/nem_panel_shots.gd` | 105 | 1-105 | `"\tPG.finish(0)"` |
| `godot/campaign/test/nem_read_test.gd` | 91 | 1-91 | `"\tquit(0 if fails == 0 else 1)"` |
| `godot/campaign/test/nem_scenarios.gd` | 218 | 1-218 | `"\trec(\"ah3\", C.nemClockAdd(1)); rec(\"ah4\""` |
| `godot/campaign/test/nemesis_clash_test.gd` | 35 | 1-35 | `"\tquit()"` |
| `godot/campaign/test/nemesis_teach_shots.gd` | 90 | 1-90 | `"\tPG.finish(0)"` |
| `godot/campaign/test/nemesis_teach_test.gd` | 45 | 1-45 | `"\tquit(0 if failures == 0 else 1)"` |
| `godot/campaign/test/node/compare_campaign.js` | 34 | 1-34 | `"console.log('PASS: ' + ga.length + ' ste"` |
| `godot/campaign/test/node/coverage.js` | 15 | 1-15 | `"console.log(Object.keys(acts).sort().map"` |
| `godot/campaign/test/node/cross_twin_handoff_test.js` | 83 | 1-83 | `"process.exitCode = main();"` |
| `godot/campaign/test/node/env.js` | 51 | 1-51 | `"module.exports = { load, ORACLE, FILES }"` |
| `godot/campaign/test/node/export_campaign.js` | 48 | 1-48 | `"console.log('  code fields left out (car"` |
| `godot/campaign/test/node/golden_campaign.js` | 125 | 1-125 | `"if (n < 0) process.exit(1);"` |
| `godot/campaign/test/node/nem_assign_enum.js` | 78 | 1-78 | `"process.exit(fails ? 1 : 0);"` |
| `godot/campaign/test/node/nem_scenarios.js` | 171 | 1-171 | `"console.log(__OUT.length + ' records');"` |
| `godot/campaign/test/onboarding_test.gd` | 175 | 1-175 | `"\tquit(0 if fails == 0 else 1)"` |
| `godot/campaign/test/onboarding_visual.gd` | 69 | 1-69 | `"\tquit(0 if checks == 0 and errors.n == 0"` |
| `godot/campaign/test/parity_campaign.gd` | 148 | 1-148 | `"\tlines.append(JSON.stringify({\"i\": 4001,"` |
| `godot/campaign/test/playtest_switch_test.gd` | 21 | 1-21 | `"\tquit(0 if bad.is_empty() else 1)"` |
| `godot/campaign/test/r1_ui_shots.gd` | 60 | 1-60 | `"\tPG.finish(0)"` |
| `godot/campaign/test/run_nem_scenarios.sh` | 16 | 1-16 | `"grep -E \"^Map read-only: PASS\" out/map_r"` |
| `godot/campaign/test/run_parity_campaign.sh` | 23 | 1-23 | `"if [ $F -eq 0 ]; then echo \"PASS: the Go"` |
| `godot/campaign/test/save_test.gd` | 25 | 1-25 | `"\tquit(1 if fails > 0 else 0)"` |
| `godot/campaign/test/shadow_xp_test.gd` | 48 | 1-48 | `"\tquit(0 if failures == 0 else 1)"` |
| `godot/campaign/test/story_beat3_test.gd` | 186 | 1-186 | `"\tquit(0 if fails == 0 else 1)"` |
| `godot/campaign/test/tree_handoff_test.gd` | 102 | 1-102 | `"\tquit(0 if failures == 0 else 1)"` |
| `godot/fx/API.md` | 373 | 1-373 | `"- `fx/test/check_destruction.bat` now in"` |
| `godot/fx/atlases/death/bake_manifest.json` | 81 | 1-81 | `"}"` |
| `godot/fx/atlases/rebake/route_manifest.json` | 364 | 1-364 | `"}"` |
| `godot/fx/atlases/weapons/bake_manifest.json` | 54 | 1-54 | `"}"` |
| `godot/fx/faction_look.gd` | 69 | 1-69 | `"\t_cache = {}"` |
| `godot/fx/faction_looks.json` | 94 | 1-94 | `"}"` |
| `godot/fx/fx.gd` | 1136 | 1-1136 | `"\ttmp.queue_free()"` |
| `godot/fx/fx_breach.gd` | 1860 | 1-500, 501-1000, 1001-1500, 1501-1860 | `"\t\t_tube(pt, points, e.R * 0.06, e.R * 0."` |
| `godot/fx/fx_death.gd` | 1914 | 1-500, 501-1000, 1001-1500, 1501-1914 | `"\t\t\tl[\"base\"] = 0.7 * gate"` |
| `godot/fx/fx_hull.gd` | 576 | 1-576 | `"\treturn Vector3(r * cos(an), r * sin(an)"` |
| `godot/fx/fx_pool.gd` | 255 | 1-255 | `"\treturn [v, n, idx]"` |
| `godot/fx/fx_shaders.gd` | 1936 | 1-500, 501-1000, 1001-1500, 1501-1936 | `"\"\"\""` |
| `godot/fx/fx_ship.gd` | 1332 | 1-1332 | `"\t\t_dmg_request(fx)"` |
| `godot/fx/fx_weapons.gd` | 1349 | 1-500, 501-1000, 1001-1349 | `"\t\t\t(m as ShaderMaterial).set_shader_para"` |
| `godot/fx/gallery/README.md` | 118 | 1-118 | `"Pipeline compiles during the measured fi"` |
| `godot/fx/gallery/gallery.gd` | 717 | 1-717 | `"\treturn RenderingServer.frame_post_draw"` |
| `godot/fx/gallery/pc/g4_gallery.bat` | 102 | 1-102 | `"exit /b 0"` |
| `godot/fx/gallery/tonemap_check.py` | 136 | 1-136 | `"            np.mean([x[3] for x in hu]),"` |
| `godot/fx/test/DAMAGE_SURFACE.md` | 36 | 1-36 | `"table, and counts include equivalent spo"` |
| `godot/fx/test/check_damage_surface.bat` | 49 | 1-49 | `"exit /b 1"` |
| `godot/fx/test/check_destruction.bat` | 49 | 1-49 | `"exit /b 1"` |
| `godot/fx/test/check_squadrons.bat` | 40 | 1-40 | `"exit /b 1"` |
| `godot/fx/test/damage_surface_check.gd` | 134 | 1-134 | `"\tquit(1 if failures else 0)"` |
| `godot/fx/test/damage_surface_probe.gd` | 183 | 1-183 | `"\tFileAccess.open(out.path_join(\"fleet.js"` |
| `godot/fx/test/damage_surface_sheets.py` | 51 | 1-51 | `"sheet.save(output / f\"{label}_details_re"` |
| `godot/fx/test/death_leap_check.gd` | 81 | 1-81 | `"\tquit(1 if failures else 0)"` |
| `godot/fx/test/death_leap_probe.gd` | 169 | 1-169 | `"\treturn {\"frames\": samples.size(), \"mean"` |
| `godot/fx/test/death_plane_check.gd` | 96 | 1-96 | `"\tquit(1 if failures else 0)"` |
| `godot/fx/test/death_spawn_check.gd` | 198 | 1-198 | `"\treturn best"` |
| `godot/fx/test/death_vent_strip_probe.gd` | 188 | 1-188 | `"\treturn c"` |
| `godot/fx/test/destruction_fleet_probe.gd` | 89 | 1-89 | `"\tPG.finish(0)"` |
| `godot/fx/test/destruction_staging_check.gd` | 180 | 1-180 | `"\tquit(1 if failures > 0 else 0)"` |
| `godot/fx/test/destruction_steps_check.gd` | 198 | 1-198 | `"\t\t\tedges[key] = int(edges.get(key, 0)) +"` |
| `godot/fx/test/fx_breach_probe.gd` | 107 | 1-107 | `"\tPG.finish(0)"` |
| `godot/fx/test/fx_cost_probe.gd` | 86 | 1-86 | `"\tPG.finish(0)"` |
| `godot/fx/test/fx_inside_probe.gd` | 263 | 1-263 | `"\tfx.camera = cam"` |
| `godot/fx/test/fx_marks_probe.gd` | 216 | 1-216 | `"\tPG.finish(0)"` |
| `godot/fx/test/fx_nozzle_probe.gd` | 87 | 1-87 | `"\tPG.finish(0)"` |
| `godot/fx/test/fx_probe.gd` | 81 | 1-81 | `"\tPG.finish(0)"` |
| `godot/fx/test/fx_proj_probe.gd` | 68 | 1-68 | `"\tPG.finish(0)"` |
| `godot/fx/test/fx_range_probe.gd` | 356 | 1-356 | `"\tprint(\"[range] wrote %s\" % path)"` |
| `godot/fx/test/fx_react_probe.gd` | 133 | 1-133 | `"\tPG.finish(0)"` |
| `godot/fx/test/fx_smoke.gd` | 159 | 1-159 | `"\tquit(1 if errors > 0 else 0)"` |
| `godot/fx/test/playtest_batch1_check.gd` | 176 | 1-176 | `"\tcamera.position = organic.to_world(Vect"` |
| `godot/fx/test/playtest_batch3_check.gd` | 92 | 1-92 | `"\tquit(1 if failures else 0)"` |
| `godot/fx/test/ship_fire_probe.gd` | 175 | 1-175 | `"\tframe_i += 1"` |
| `godot/fx/test/squadron_check.gd` | 120 | 1-120 | `"\tquit(0 if failures == 0 else 1)"` |
| `godot/fx/test/squadron_probe.gd` | 167 | 1-167 | `"\tawait process_frame"` |
| `godot/fx/test/squadron_sheets.py` | 53 | 1-53 | `"    main()"` |
| `godot/fx/test/vent_clip.py` | 172 | 1-172 | `"    main()"` |
| `godot/fx/test/vent_look_probe.gd` | 337 | 1-337 | `"\tcam.snap()"` |
| `godot/main/FEATURES.md` | 101 | 1-101 | `"\| Engine cues on moves \| done \|"` |
| `godot/main/README.md` | 137 | 1-137 | `"- The new game name (Embers of the Hollo"` |
| `godot/main/campaign_fallback_ui.gd` | 134 | 1-134 | `"\treturn l"` |
| `godot/main/campaign_host.gd` | 369 | 1-369 | `"\trun_over.emit({\"result\": \"win\" if won e"` |
| `godot/main/load_screen.gd` | 58 | 1-58 | `"\t\tlast = now"` |
| `godot/main/main.gd` | 513 | 1-513 | `"\treturn out"` |
| `godot/main/test_loading.gd` | 106 | 1-106 | `"\tprint(\"BAKE %s pixel error: max=%f mean"` |
| `godot/main/title.gd` | 562 | 1-562 | `"\t_reveal_tw.tween_property(_shade, \"colo"` |
| `godot/music/CREDITS.md` | 322 | 1-322 | `"The Deathless mix is CC0 and so are all "` |
| `godot/music/README.md` | 63 | 1-63 | `"A battle starts the calm layer and the i"` |
| `godot/music/music.json` | 556 | 1-556 | `"}"` |
| `godot/music/music_player.gd` | 365 | 1-365 | `"\t\t\"bed_db\": _bed.volume_db, \"single\": _s"` |
| `godot/music/test/music_check.gd` | 102 | 1-102 | `"\tquit(0 if fails.is_empty() else 1)"` |
| `godot/portraits/README.md` | 84 | 1-84 | `"- **Jobs on lane A:** `r8a`, `r8b` (fres"` |
| `godot/portraits/crests/index.json` | 122 | 1-122 | `"}"` |
| `godot/portraits/index.json` | 1279 | 1-1279 | `"}"` |
| `godot/portraits/nemesis/scars/scars.json` | 62 | 1-62 | `"}"` |
| `godot/portraits/portraits.gd` | 160 | 1-160 | `"\t_idx.clear()"` |
| `godot/portraits/test/portraits_check.gd` | 46 | 1-46 | `"\tquit(0 if fails.is_empty() else 1)"` |
| `godot/render/backdrop.gd` | 65 | 1-65 | `"\t_update()"` |
| `godot/render/board.gd` | 897 | 1-897 | `"\t\tBV.outline(blocker_highlights, hex_wor"` |
| `godot/render/build_assets.gd` | 487 | 1-487 | `"\t\t\t\treturn"` |
| `godot/render/camera_rig.gd` | 194 | 1-194 | `"\tlook_at_from_position(p, tg, up)"` |
| `godot/render/hull_table.gd` | 56 | 1-56 | `"\treturn Color(hex).srgb_to_linear()"` |
| `godot/render/look.gd` | 109 | 1-109 | `"\treturn m"` |
| `godot/render/placeholder_guard.gd` | 41 | 1-41 | `"\t\t(loop as SceneTree).quit(exit_code)"` |
| `godot/render/ship_view.gd` | 1295 | 1-1295 | `"\t\tring.rotation.y = -rotation.y"` |
| `godot/render/squadron_craft.gd` | 206 | 1-206 | `"\t_orb(Vector3(0.12, 0.11, 0), Vector3(0."` |
| `godot/render/squadron_wing.gd` | 103 | 1-103 | `"\tmesh.surface_end()"` |
| `godot/rules/API.md` | 190 | 1-190 | `"- **Maths:** sin, cos, atan2, exp, hypot"` |
| `godot/rules/battle_api.gd` | 943 | 1-943 | `"\treturn why"` |
| `godot/rules/data/tables.json` | 1 | 1-1 | `"{\"sha256\":\"65cf8f270c49a3e65357f20d7303f"` |
| `godot/rules/jsm.gd` | 654 | 1-654 | `"\treturn s if i < 0 else s.substr(0, i) +"` |
| `godot/rules/rules.gd` | 6422 | 1-500, 501-1000, 1001-1500, 1501-2000, 2001-2500, 2501-3000, 3001-3500, 3501-4000, 4001-4500, 4501-5000, 5001-5500, 5501-6000, 6001-6422 | `"\tB[\"aiActive\"] = null; u[\"activated\"] = "` |
| `godot/rules/test/README.md` | 101 | 1-101 | `"  - `tr` is taken by `Object.tr`."` |
| `godot/rules/test/api_smoke.gd` | 34 | 1-34 | `"\tquit(0 if api.R.not_ported == \"\" else 3"` |
| `godot/rules/test/effect_caps_test.gd` | 31 | 1-31 | `"\tquit(1 if bad > 0 else 0)"` |
| `godot/rules/test/node/campaign_hooks.js` | 3 | 1-3 | `"function nemAdaptName(a,fac){ const T=NE"` |
| `godot/rules/test/node/compare.js` | 43 | 1-43 | `"console.log('PASS');"` |
| `godot/rules/test/node/export_data.js` | 56 | 1-56 | `"console.log('exported', Object.keys(out)"` |
| `godot/rules/test/node/fnames.js` | 6 | 1-6 | `"  deathless:['Long Noon','The Unbroken',"` |
| `godot/rules/test/node/golden.js` | 257 | 1-257 | `"})().catch(e => { console.error(e); proc"` |
| `godot/rules/test/node/summary.js` | 16 | 1-16 | `"console.log('  ' + Object.entries(seen)."` |
| `godot/rules/test/node/sweep_check.js` | 15 | 1-15 | `"console.log(bad ? 'FAIL' : 'PASS'); proc"` |
| `godot/rules/test/node/sweep_gen.js` | 47 | 1-47 | `"fs.writeFileSync(out, JSON.stringify(res"` |
| `godot/rules/test/node/timing.js` | 13 | 1-13 | `"console.log(`    Godot/Node: ${(G.avg / "` |
| `godot/rules/test/parity_main.gd` | 206 | 1-206 | `"\treturn 0"` |
| `godot/rules/test/run_parity.sh` | 18 | 1-18 | `"if [ $F -eq 0 ]; then echo \"PASS: the Go"` |
| `godot/rules/test/run_sweep.sh` | 11 | 1-11 | `"node node/sweep_check.js out/sweep.json "` |
| `godot/rules/test/scenarios.json` | 8682 | 1-500, 501-1000, 1001-1500, 1501-2000, 2001-2500, 2501-3000, 3001-3500, 3501-4000, 4001-4500, 4501-5000, 5001-5500, 5501-6000, 6001-6500, 6501-7000, 7001-7500, 7501-8000, 8001-8500, 8501-8682 | `"}"` |
| `godot/rules/test/thread_test.gd` | 92 | 1-92 | `"\tquit(0 if bad == 0 else 1)"` |
| `godot/scenes/battle/battle.gd` | 5120 | 1-500, 501-1000, 1001-1500, 1501-2000, 2001-2500, 2501-3000, 3001-3500, 3501-4000, 4001-4500, 4501-5000, 5001-5120 | `"\tget_tree().quit(code)"` |
| `godot/scenes/battle/f1_trace.gd` | 434 | 1-434 | `"\tPG.finish(1 if fails > 0 else 0)"` |
| `godot/scenes/battle/fx_stub.gd` | 165 | 1-165 | `"\titems.clear()"` |
| `godot/scenes/battle/lineup.gd` | 136 | 1-136 | `"\tPG.finish(0)"` |
| `godot/scenes/battle/play_log.gd` | 87 | 1-87 | `"\treturn {\"v\": 1, \"result\": result, \"roun"` |
| `godot/scenes/battle/test/wing_cancel_test.gd` | 103 | 1-103 | `"\tquit(1 if fails > 0 else 0)"` |
| `godot/scenes/campaign/campaign_scene.gd` | 406 | 1-406 | `""` |
| `godot/scenes/campaign/map3d_probe.gd` | 39 | 1-39 | `"\tPG.finish(0)"` |
| `godot/scenes/campaign/stops_probe.gd` | 54 | 1-54 | `"\tget_viewport().get_texture().get_image("` |
| `godot/story/README.md` | 136 | 1-136 | `"`story_test.gd`: data complete (24 admir"` |
| `godot/story/arc.gd` | 171 | 1-171 | `"\treturn segments(A.get(\"win\" if won else"` |
| `godot/story/battle_voice.gd` | 204 | 1-204 | `"\treturn \"%s: \\\"%s\\\"\" % [admiral_name(), "` |
| `godot/story/career.gd` | 450 | 1-450 | `"\treturn row"` |
| `godot/story/data/arcs.json` | 129 | 1-129 | `"}"` |
| `godot/story/data/medals.json` | 17 | 1-17 | `"}"` |
| `godot/story/data/rival_lines.json` | 493 | 1-493 | `"}"` |
| `godot/story/data/titles.json` | 31 | 1-31 | `"}"` |
| `godot/story/data/voices.json` | 416 | 1-416 | `"}"` |
| `godot/story/outlines.md` | 345 | 1-345 | `"Checked by `godot/story/test/check_outli"` |
| `godot/story/outlines_variants.md` | 257 | 1-257 | `"Incident 8's \"that captain\" effects need"` |
| `godot/story/review_incorporation.md` | 110 | 1-110 | `"godot/story/outlines.md (REVISED round 3"` |
| `godot/story/rival.gd` | 174 | 1-174 | `"\treturn line(\"hail\", nem, seed, ctx)"` |
| `godot/story/story.gd` | 370 | 1-370 | `"\treturn s"` |
| `godot/story/test/career_shots.gd` | 85 | 1-85 | `"\t\tpass"` |
| `godot/story/test/check_outlines.py` | 65 | 1-65 | `"sys.exit(1 if bad else 0)"` |
| `godot/story/test/check_personas.py` | 24 | 1-24 | `"sys.exit(1 if bad else 0)"` |
| `godot/story/test/fixture_arc.json` | 36 | 1-36 | `"}"` |
| `godot/story/test/story_test.gd` | 459 | 1-459 | `"\tok(battles_seen > 0 and recorded_runs ="` |
| `godot/story/tokens.gd` | 98 | 1-98 | `"\treturn t"` |
| `godot/story/unlocks.md` | 32 | 1-32 | `"The cosmetic rewards need nothing from s"` |
| `godot/tools/ci/bot_battle.gd` | 182 | 1-182 | `"\tquit(0)"` |
| `godot/tools/ci/load_all.gd` | 52 | 1-52 | `"\t\t\tout.append(dir.path_join(f))"` |
| `godot/tools/ci/run_checks.sh` | 77 | 1-77 | `"if [ $F -eq 0 ]; then echo \"PASS: every "` |
| `godot/ui/battle/brand.gd` | 81 | 1-81 | `"\treturn false"` |
| `godot/ui/battle/hud.gd` | 2746 | 1-500, 501-1000, 1001-1500, 1501-2000, 2001-2500, 2501-2746 | `"\t_refresh_unacted()"` |
| `godot/ui/battle/ui_shots.gd` | 336 | 1-336 | `"\tb._quit_report()"` |
| `godot/ui/campaign/campaign_tips.gd` | 120 | 1-120 | `"\tif is_off(): _dismiss(\"off\", false)"` |
| `godot/ui/campaign/campaign_ui.gd` | 1804 | 1-500, 501-1000, 1001-1500, 1501-1804 | `"\t\t\t\tC.act(on[n][0], on[n][1]); get_viewp"` |
| `godot/ui/campaign/choice_button.gd` | 40 | 1-40 | `"\t\taccept_event(); pressed.emit()"` |
| `godot/ui/campaign/crest.gd` | 101 | 1-101 | `"\treturn pts"` |
| `godot/ui/campaign/map3d.gd` | 1275 | 1-500, 501-1000, 1001-1275 | `"\t\t_wake_mesh.surface_end()"` |
| `godot/ui/campaign/map3d_props.gd` | 311 | 1-311 | `"\t\tcaster(mm)"` |
| `godot/ui/campaign/map3d_shaders.gd` | 859 | 1-859 | `"\"\"\""` |
| `godot/ui/campaign/map3d_system.gd` | 409 | 1-409 | `"\tm.extra_cull_margin = h; parent.add_chi"` |
| `godot/ui/campaign/map_intel.gd` | 163 | 1-163 | `"\treturn {\"avg\": avg, \"low\": low, \"hurt\":"` |
| `godot/ui/campaign/rail_orders_shots.gd` | 132 | 1-132 | `"func _initialize(): root.add_child.call_"` |
| `godot/ui/career/career_screen.gd` | 407 | 1-407 | `"\t\t_close()"` |
| `godot/ui/career/crest.gd` | 100 | 1-100 | `"\tdraw_string(f, c + Vector2(-ts.x * 0.5,"` |
| `godot/ui/career/rename_dialog.gd` | 135 | 1-135 | `"\t\t_close()"` |
| `godot/ui/theme/glass_shell.gd` | 782 | 1-782 | `"\treturn c"` |
| `godot/ui/ui_scale.gd` | 40 | 1-40 | `"\tplayer = clampf(float(v), PLAYER_MIN, P"` |
| `godot/world/blocker_visuals.gd` | 189 | 1-189 | `"\tnode.global_position = centre + Vector3"` |
| `godot/world/board_look.gd` | 69 | 1-69 | `"\treturn {\"plate\": true, \"underlay\": 1.0,"` |
| `godot/world/hull_debris.gd` | 51 | 1-51 | `"\treturn out"` |
| `godot/world/rocks/rocks.json` | 235 | 1-235 | `"}"` |
| `godot/world/test_blockers.gd` | 87 | 1-87 | `"\tquit(1 if failures else 0)"` |
| `godot/world/test_world.gd` | 45 | 1-45 | `"\tquit(errs)"` |
| `godot/world/tools/bake_preview.gd` | 62 | 1-62 | `"\tquit(0)"` |
| `godot/world/tools/board_sheet.py` | 118 | 1-118 | `"    main()"` |
| `godot/world/tools/rockgen.py` | 393 | 1-393 | `"    main()"` |
| `godot/world/world.gd` | 1304 | 1-1304 | `"\tif _living != null: _living.use_ship_de"` |
| `godot/world/world_bake.gd` | 283 | 1-283 | `"\treturn true"` |
| `godot/world/world_living.gd` | 884 | 1-884 | `"\t\t_chunk_task = -1"` |
| `godot/world/world_planet.gd` | 351 | 1-351 | `"\"\"\""` |
| `godot/world/world_rocks.gd` | 462 | 1-462 | `"\t\treturn n"` |
| `godot/world/world_shaders.gd` | 459 | 1-459 | `"\"\"\""` |
| `godot/world/world_shots.gd` | 323 | 1-323 | `"\tprint(\"[world_shots] \", p)"` |
| `godot/world/world_sky.gd` | 385 | 1-385 | `"\treturn out"` |
| `godot/world/wreckage/kit.json` | 35 | 1-35 | `"}"` |
| `tools/blender/README.md` | 6 | 1-6 | `"- fxsim.py: Mantaflow explosion sims ren"` |
| `tools/blender/a1/barge_shapes.py` | 203 | 1-203 | `"    print(clay.render_views(pre, views=("` |
| `tools/blender/a1/barge_v15.py` | 242 | 1-242 | `"    if '--export' in a: export(shells, k"` |
| `tools/blender/a1/clay.py` | 71 | 1-71 | `"    print(render_views(a[0], views=('q',"` |
| `tools/blender/a1/render_v15.py` | 31 | 1-31 | `"print(outs)"` |
| `tools/blender/a1/sheet.py` | 41 | 1-41 | `"print('ok')"` |
| `tools/blender/a2detail/a2_barge.py` | 164 | 1-164 | `"    main()"` |
| `tools/blender/a2detail/a2_ship.py` | 257 | 1-257 | `"    main()"` |
| `tools/blender/a2detail/bakemat.py` | 207 | 1-207 | `"    return m, dict(albedo=albedo, orm=or"` |
| `tools/blender/a2detail/blmesh.py` | 113 | 1-113 | `"    a = image_to_numpy(im)[..., :3].copy"` |
| `tools/blender/a2detail/checks.py` | 110 | 1-110 | `"    return outs"` |
| `tools/blender/a2detail/checks_glb.py` | 28 | 1-28 | `"except ImportError: print('[checks] rend"` |
| `tools/blender/a2detail/checks_sheet.py` | 38 | 1-38 | `"          f'C19_51 Pyre-Barge v15, {res}"` |
| `tools/blender/a2detail/dress.py` | 559 | 1-559 | `"    return n"` |
| `tools/blender/a2detail/hullio.py` | 206 | 1-206 | `"    return dict(tris=len(I) // 3, verts="` |
| `tools/blender/a2detail/pack_glb.py` | 45 | 1-45 | `"        for p in a: pack(p)"` |
| `tools/blender/a2detail/reimport.py` | 17 | 1-17 | `"    print('[reimport]', os.path.basename"` |
| `tools/blender/a2detail/spires.py` | 104 | 1-104 | `"    return symmetrize(out, .0045)"` |
| `tools/blender/a4/K1_DECISIONS.md` | 143 | 1-143 | `"`godot/assets/ships/README.md`."` |
| `tools/blender/a4/README.md` | 124 | 1-124 | `"- The game's hull JSON (unchanged): x bo"` |
| `tools/blender/a4/a4_ship.py` | 425 | 1-425 | `"    main()"` |
| `tools/blender/a4/bakemat4.py` | 367 | 1-367 | `"    return m, dict(albedo=albedo, orm=or"` |
| `tools/blender/a4/barge4.py` | 183 | 1-183 | `"    main()"` |
| `tools/blender/a4/chain.py` | 38 | 1-38 | `"    main()"` |
| `tools/blender/a4/compose.py` | 89 | 1-89 | `"    return idx[keep]"` |
| `tools/blender/a4/concept.py` | 487 | 1-487 | `"    if '--apply' in a: apply(a[0], op, r"` |
| `tools/blender/a4/cuts.py` | 103 | 1-103 | `"    return idx[~cut_all], rims, rep"` |
| `tools/blender/a4/cview.py` | 77 | 1-77 | `"W.save(out, quality=88); print('sheet', "` |
| `tools/blender/a4/damage.py` | 472 | 1-472 | `"            'edge': mk('damage_edge', ed"` |
| `tools/blender/a4/dmgview.py` | 88 | 1-88 | `"    else: main()"` |
| `tools/blender/a4/dress4.py` | 244 | 1-244 | `"    return made"` |
| `tools/blender/a4/faired.py` | 122 | 1-122 | `"        i = int(np.argmin(abs(xs - x)));"` |
| `tools/blender/a4/frame.py` | 70 | 1-70 | `"    return h"` |
| `tools/blender/a4/gio.py` | 171 | 1-171 | `"    return dict(tris=tris, ext=[round(fl"` |
| `tools/blender/a4/godot_check.gd` | 36 | 1-36 | `"\t\t_walk(c, d + 1)"` |
| `tools/blender/a4/ingame_sheet.py` | 153 | 1-153 | `"        sheet(bdir, adir, fac, title, co"` |
| `tools/blender/a4/ithar.py` | 69 | 1-69 | `"    return nm, mm"` |
| `tools/blender/a4/kit.py` | 737 | 1-737 | `"    return made"` |
| `tools/blender/a4/lineup.py` | 165 | 1-165 | `"    else: main()"` |
| `tools/blender/a4/livery.py` | 87 | 1-87 | `"    return out.reshape(res, res, 3), mas"` |
| `tools/blender/a4/look.py` | 178 | 1-178 | `"    else: main()"` |
| `tools/blender/a4/manifest.py` | 62 | 1-62 | `"    main(*sys.argv[1:4])"` |
| `tools/blender/a4/pack.py` | 198 | 1-198 | `"        pack(a[0], a[a.index('--hi') + 1"` |
| `tools/blender/a4/probe.py` | 48 | 1-48 | `"        print(f'{c:+7.3f} ' + ' '.join('"` |
| `tools/blender/a4/reshape.py` | 111 | 1-111 | `"    n = acc[w]; L = np.linalg.norm(n, ax"` |
| `tools/blender/a4/sheet.py` | 10 | 1-10 | `"        checks_sheet.make(sys.argv[1], c"` |
| `tools/blender/a4/ships.py` | 611 | 1-611 | `"    kit=[], notes='pass 1: stands uprigh"` |
| `tools/blender/a4/stage.py` | 63 | 1-63 | `"    main()"` |
| `tools/blender/a4/wreck.py` | 104 | 1-104 | `"    return out"` |
| `tools/blender/bake_all.py` | 22 | 1-22 | `"LOG.write('BAKE ALL DONE\\n')"` |
| `tools/blender/fitcam_fit.py` | 29 | 1-29 | `"r = {'az': az, 'el': el, 'iou': float(v)"` |
| `tools/blender/fitcam_render.py` | 19 | 1-19 | `"print('SILS DONE')"` |
| `tools/blender/fix_hull.py` | 44 | 1-44 | `"json.dump(j,open(f,'w')); print(f,'tris'"` |
| `tools/blender/fxsim.py` | 64 | 1-64 | `"print('[fx] DONE', VAR, flush=True)"` |
| `tools/blender/hs/STATION_KIT.md` | 56 | 1-56 | `"Relay and transport work in the structur"` |
| `tools/blender/hs/c19_hs.py` | 67 | 1-67 | `"bpy.ops.wm.save_as_mainfile(filepath=out"` |
| `tools/blender/hs/c19_kit.py` | 555 | 1-555 | `"    bpy.ops.export_scene.gltf(filepath=p"` |
| `tools/blender/hs/cleanup.py` | 27 | 1-27 | `"bpy.ops.wm.save_as_mainfile(filepath=out"` |
| `tools/blender/hs/detail_lib.py` | 309 | 1-309 | `"    bm.to_mesh(me); bm.free(); me.update"` |
| `tools/blender/hs/export_json.py` | 28 | 1-28 | `"if glb: bpy.ops.export_scene.gltf(filepa"` |
| `tools/blender/hs/hs_lib.py` | 80 | 1-80 | `"    return o"` |
| `tools/blender/hs/json2obj.py` | 9 | 1-9 | `"print(len(P), len(I))"` |
| `tools/blender/hs/o1_hs.py` | 34 | 1-34 | `"print('faces', len(o.data.polygons)); bp"` |
| `tools/blender/hs/panel_flatten.py` | 58 | 1-58 | `"bpy.ops.export_scene.gltf(filepath=dst, "` |
| `tools/blender/hs/planesnap.py` | 72 | 1-72 | `"bpy.ops.wm.save_as_mainfile(filepath=out"` |
| `tools/blender/hs/render.py` | 28 | 1-28 | `"print('faces', sum(len(o.data.polygons) "` |
| `tools/blender/hs/station_check.gd` | 333 | 1-333 | `"\tquit(0)"` |
| `tools/blender/hs/station_kit.py` | 963 | 1-963 | `"        main()"` |
| `tools/blender/hs/station_paint_review.bat` | 49 | 1-49 | `"exit /b 1"` |
| `tools/blender/hs/station_paint_sheets.py` | 202 | 1-202 | `"    main()"` |
| `tools/blender/hs/station_preview.gd` | 157 | 1-157 | `"\tkey.directional_shadow_max_distance = 6"` |
| `tools/blender/hs/station_readable_paint.py` | 84 | 1-84 | `"    return base, orm.outputs[0], emissio"` |
| `tools/blender/hs/station_sheets.py` | 162 | 1-162 | `"    main()"` |
| `tools/blender/hs/to_game.py` | 28 | 1-28 | `"subprocess.run([sys.executable, __import"` |
| `tools/blender/hs/wavy_report.py` | 101 | 1-101 | `"print('wrote', pre + '_wavy.txt')"` |
| `tools/blender/hull_repair/README.md` | 27 | 1-27 | `"The outcome and remaining visual work be"` |
| `tools/blender/hull_repair/ROUND4.md` | 23 | 1-23 | `"The actual-game phase copies this checko"` |
| `tools/blender/hull_repair/ROUND5.md` | 17 | 1-17 | `"The verifier compares triangle-coordinat"` |
| `tools/blender/hull_repair/ROUND6.md` | 19 | 1-19 | `"Each nine-cell sheet also has a neutral "` |
| `tools/blender/hull_repair/RUN_C19_REPAIR.bat` | 15 | 1-15 | `"pause"` |
| `tools/blender/hull_repair/RUN_PYRE_ROUND4.bat` | 8 | 1-8 | `"if \"%~1\"==\"\" pause"` |
| `tools/blender/hull_repair/RUN_PYRE_ROUND5.bat` | 7 | 1-7 | `"if \"%~1\"==\"\" pause"` |
| `tools/blender/hull_repair/RUN_PYRE_ROUND6.bat` | 7 | 1-7 | `"if \"%~1\"==\"\" pause"` |
| `tools/blender/hull_repair/ai_parts.py` | 132 | 1-132 | `"    generate(args.work.resolve(), args.p"` |
| `tools/blender/hull_repair/assembly.gd` | 25 | 1-25 | `"\tcache.clear()"` |
| `tools/blender/hull_repair/build.py` | 513 | 1-513 | `"    main()"` |
| `tools/blender/hull_repair/checks.py` | 90 | 1-90 | `"if __name__=='__main__':main()"` |
| `tools/blender/hull_repair/pack_parts.py` | 157 | 1-157 | `"if __name__=='__main__':main()"` |
| `tools/blender/hull_repair/probe.gd` | 127 | 1-127 | `"\tquit(0)"` |
| `tools/blender/hull_repair/round4_build.py` | 221 | 1-221 | `"if __name__=='__main__':main()"` |
| `tools/blender/hull_repair/round4_hand.py` | 310 | 1-310 | `"        hero_objects=len(heroes),detail_"` |
| `tools/blender/hull_repair/round4_material.py` | 170 | 1-170 | `"        maps={p.name:lib.sha(p) for p in"` |
| `tools/blender/hull_repair/round4_probe.gd` | 152 | 1-152 | `"\tfor row in original:row[0].set_surface_"` |
| `tools/blender/hull_repair/round4_raw.py` | 72 | 1-72 | `"    assert a.work.resolve().is_relative_"` |
| `tools/blender/hull_repair/round4_reference.py` | 222 | 1-222 | `"    main(a.work.resolve(),a.phase)"` |
| `tools/blender/hull_repair/round4_run.py` | 406 | 1-406 | `"if __name__=='__main__':main()"` |
| `tools/blender/hull_repair/round5_bench.gd` | 34 | 1-34 | `"\tfile.close();print(\"[round5] PAIRED GPU"` |
| `tools/blender/hull_repair/round5_build.py` | 72 | 1-72 | `"if __name__=='__main__':main()"` |
| `tools/blender/hull_repair/round5_material.py` | 189 | 1-189 | `"        maps={p.name:lib.sha(p) for p in"` |
| `tools/blender/hull_repair/round5_probe.gd` | 49 | 1-49 | `"\tawait settle(4)"` |
| `tools/blender/hull_repair/round5_run.py` | 112 | 1-112 | `"if __name__=='__main__':main()"` |
| `tools/blender/hull_repair/round5_sheets.py` | 376 | 1-376 | `"    print('[round5] SHEETS PASS',out,flu"` |
| `tools/blender/hull_repair/round6_build.py` | 158 | 1-158 | `"if __name__=='__main__':main()"` |
| `tools/blender/hull_repair/round6_game.gd` | 20 | 1-20 | `"\tfile.close()"` |
| `tools/blender/hull_repair/round6_material.py` | 61 | 1-61 | `"    return result"` |
| `tools/blender/hull_repair/round6_probe.gd` | 103 | 1-103 | `"\tawait settle(6)"` |
| `tools/blender/hull_repair/round6_run.py` | 119 | 1-119 | `"if __name__=='__main__':main()"` |
| `tools/blender/hull_repair/round6_sheets.py` | 271 | 1-271 | `"    print('[round6] SHEETS PASS',out,flu"` |
| `tools/blender/hull_repair/run.py` | 313 | 1-313 | `"if __name__=='__main__':main()"` |
| `tools/blender/hullbake.py` | 195 | 1-195 | `"log('done verts', len(P), '->', len(P2),"` |
| `tools/blender/kits/README.md` | 39 | 1-39 | `"weapons and returns any gun aimed agains"` |
| `tools/blender/kits/hullbreakers/README.md` | 22 | 1-22 | `"salvage detail (patches, welds, drum typ"` |
| `tools/blender/kits/hullbreakers/kit.py` | 320 | 1-320 | `"    return PB.audit_guns()"` |
| `tools/blender/kits/hullbreakers/paint.py` | 261 | 1-261 | `"    return mats"` |
| `tools/blender/kits/shared/plumbing.py` | 201 | 1-201 | `"                guns_with_normals=sum(1 "` |
| `tools/blender/lod_make.py` | 14 | 1-14 | `"    print('LOD', n, 'from', f0, '->', le"` |
| `tools/blender/mv_prep.py` | 40 | 1-40 | `"sheet.resize((S, S)).save(os.path.join(o"` |
| `tools/blender/paint_level.py` | 27 | 1-27 | `"    print(level(sys.argv[1], sys.argv[2]"` |
| `tools/blender/pixal_to_game.py` | 128 | 1-128 | `"print(code, 'verts', n, 'tris', len(I), "` |
| `tools/blender/project_paint.py` | 200 | 1-200 | `"    bpy.ops.export_scene.gltf(filepath=o"` |
| `tools/blender/r209/README.md` | 88 | 1-88 | `"\| `pc/r6_*.bat` to `pc/r6f_*.bat` \| the "` |
| `tools/blender/r209/armA.py` | 148 | 1-148 | `"    build(a[0])"` |
| `tools/blender/r209/armA2.py` | 258 | 1-258 | `"    build(a[0], int(a[1]) if len(a) > 1 "` |
| `tools/blender/r209/armA3.py` | 347 | 1-347 | `"    print('[209]', json.dumps(meta), flu"` |
| `tools/blender/r209/armA4.py` | 350 | 1-350 | `"    print('[209]', json.dumps(meta), flu"` |
| `tools/blender/r209/armA5.py` | 437 | 1-437 | `"    print('[209]', json.dumps(meta), flu"` |
| `tools/blender/r209/armA6.py` | 112 | 1-112 | `"    print('[209]', json.dumps(meta)[:300"` |
| `tools/blender/r209/armA7.py` | 198 | 1-198 | `"    print('[209]', json.dumps(meta)[:300"` |
| `tools/blender/r209/armA8.py` | 177 | 1-177 | `"    print('[209]', json.dumps(meta)[:300"` |
| `tools/blender/r209/armB.py` | 156 | 1-156 | `"    build(a[0], a[1], a[2], a[3])"` |
| `tools/blender/r209/armB2.py` | 80 | 1-80 | `"    build(a[0], a[1], a[2], a[3])"` |
| `tools/blender/r209/armB_fix.json` | 46 | 1-46 | `"}"` |
| `tools/blender/r209/b0trace.py` | 92 | 1-92 | `"    elif sys.argv[1] == 'fit': fit(*sys."` |
| `tools/blender/r209/bakeAb.py` | 87 | 1-87 | `"    A2.build(OUT, 2, cell='Ab', hull_det"` |
| `tools/blender/r209/bakeAb3.py` | 199 | 1-199 | `"    main()"` |
| `tools/blender/r209/bakeAb4.py` | 207 | 1-207 | `"    main()"` |
| `tools/blender/r209/bakeAb5.py` | 200 | 1-200 | `"    main()"` |
| `tools/blender/r209/bakeAb6.py` | 222 | 1-222 | `"    main()"` |
| `tools/blender/r209/close5.py` | 46 | 1-46 | `"print('[209] CLOSE DONE', CELL, flush=Tr"` |
| `tools/blender/r209/close6.py` | 55 | 1-55 | `"print('[209] CLOSE DONE', CELL, flush=Tr"` |
| `tools/blender/r209/common.py` | 251 | 1-251 | `"    return o"` |
| `tools/blender/r209/deck_line.py` | 36 | 1-36 | `"json.dump(res, open(os.path.join(out, 'd"` |
| `tools/blender/r209/export3.py` | 78 | 1-78 | `"print('[209] export', OUT, json.dumps(in"` |
| `tools/blender/r209/export_glb.py` | 57 | 1-57 | `"print('[209] export', OUT, 'triangles', "` |
| `tools/blender/r209/fire_clip.py` | 82 | 1-82 | `"    print('[clip] strip', os.path.join(d"` |
| `tools/blender/r209/fit8.py` | 228 | 1-228 | `"    OT.run(CONCEPT, CAM, os.path.join(ou"` |
| `tools/blender/r209/fit8_bow.json` | 388 | 1-388 | `"}"` |
| `tools/blender/r209/fit8_bow_try1.json` | 418 | 1-418 | `"}"` |
| `tools/blender/r209/flat_views.py` | 41 | 1-41 | `"    sc.render.filepath=f'{OUT}_{n}.png';"` |
| `tools/blender/r209/godot/bench209.gd` | 257 | 1-257 | `"\tquit(0)"` |
| `tools/blender/r209/godot/bench209r3.gd` | 356 | 1-356 | `"\tquit(0)"` |
| `tools/blender/r209/massing_sheet.py` | 82 | 1-82 | `"stack(parts, OUT)"` |
| `tools/blender/r209/outline_battle.py` | 60 | 1-60 | `"    run(a[0], ref, [c for x in a[1:] if "` |
| `tools/blender/r209/outline_thirds.py` | 87 | 1-87 | `"    run(sys.argv[1], sys.argv[2], sys.ar"` |
| `tools/blender/r209/paint3.py` | 202 | 1-202 | `"    return m"` |
| `tools/blender/r209/pc/r2_queue.bat` | 9 | 1-9 | `"echo launched 209 r2"` |
| `tools/blender/r209/pc/r2_run.bat` | 39 | 1-39 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r3_queue.bat` | 9 | 1-9 | `"echo launched 209 r3"` |
| `tools/blender/r209/pc/r3_run.bat` | 34 | 1-34 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r3b_queue.bat` | 9 | 1-9 | `"echo launched 209 r3b"` |
| `tools/blender/r209/pc/r3b_run.bat` | 32 | 1-32 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r3c_queue.bat` | 9 | 1-9 | `"echo launched 209 r3c"` |
| `tools/blender/r209/pc/r3c_run.bat` | 32 | 1-32 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r4_queue.bat` | 9 | 1-9 | `"echo launched 209 r4"` |
| `tools/blender/r209/pc/r4_r3concept.bat` | 10 | 1-10 | `"echo done > \"%O%\\out4b\\r3\\done.txt\""` |
| `tools/blender/r209/pc/r4_run.bat` | 35 | 1-35 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r4b_queue.bat` | 9 | 1-9 | `"echo launched 209 r4b"` |
| `tools/blender/r209/pc/r4b_run.bat` | 31 | 1-31 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r5_queue.bat` | 9 | 1-9 | `"echo launched 209 r5"` |
| `tools/blender/r209/pc/r5_run.bat` | 38 | 1-38 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r5b_queue.bat` | 9 | 1-9 | `"echo launched 209 r5b"` |
| `tools/blender/r209/pc/r5b_run.bat` | 40 | 1-40 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r6_queue.bat` | 9 | 1-9 | `"echo launched 209 r6"` |
| `tools/blender/r209/pc/r6_run.bat` | 51 | 1-51 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r6b_queue.bat` | 9 | 1-9 | `"echo launched 209 r6b"` |
| `tools/blender/r209/pc/r6b_run.bat` | 52 | 1-52 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r6c_queue.bat` | 9 | 1-9 | `"echo launched 209 r6c"` |
| `tools/blender/r209/pc/r6c_run.bat` | 52 | 1-52 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r6d_queue.bat` | 9 | 1-9 | `"echo launched 209 r6d"` |
| `tools/blender/r209/pc/r6d_run.bat` | 52 | 1-52 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r6e_queue.bat` | 9 | 1-9 | `"echo launched 209 r6e"` |
| `tools/blender/r209/pc/r6e_run.bat` | 52 | 1-52 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r6f_queue.bat` | 9 | 1-9 | `"echo launched 209 r6f"` |
| `tools/blender/r209/pc/r6f_run.bat` | 52 | 1-52 | `"echo done > \"%OUT%\\done.txt\""` |
| `tools/blender/r209/pc/r7_queue.bat` | 11 | 1-11 | `"echo launched 209 r7 (it waits for opus2"` |
| `tools/blender/r209/pc/r7_run.bat` | 93 | 1-93 | `"echo done > \"%OUT%\\done7.txt\""` |
| `tools/blender/r209/pc/r7b_queue.bat` | 10 | 1-10 | `"echo launched 209 r7b"` |
| `tools/blender/r209/pc/r7b_run.bat` | 59 | 1-59 | `"echo done > \"%OUT%\\done7b.txt\""` |
| `tools/blender/r209/pc/r7c_queue.bat` | 10 | 1-10 | `"echo launched 209 r7c"` |
| `tools/blender/r209/pc/r7c_run.bat` | 28 | 1-28 | `"echo done > \"%OUT%\\done7c.txt\""` |
| `tools/blender/r209/pc/r8_queue.bat` | 10 | 1-10 | `"echo launched 209 r8"` |
| `tools/blender/r209/pc/r8_run.bat` | 87 | 1-87 | `"echo done > \"%OUT%\\done8.txt\""` |
| `tools/blender/r209/pc/r8b_queue.bat` | 10 | 1-10 | `"echo launched 209 r8b"` |
| `tools/blender/r209/pc/r8b_run.bat` | 87 | 1-87 | `"echo done > \"%OUT%\\done8b.txt\""` |
| `tools/blender/r209/pc/r8c_recheck.bat` | 23 | 1-23 | `"type \"%O%\\out8b\\recheck341\\result.txt\""` |
| `tools/blender/r209/preview6.py` | 54 | 1-54 | `"print('[prev] done', round(time.time() -"` |
| `tools/blender/r209/preview7.py` | 96 | 1-96 | `"print('[prev] done', round(time.time() -"` |
| `tools/blender/r209/render.py` | 128 | 1-128 | `"print('[209] RENDER DONE', CELL, flush=T"` |
| `tools/blender/r209/report3.py` | 35 | 1-35 | `"                  build_s=m.get('build_s"` |
| `tools/blender/r209/report_table.py` | 14 | 1-14 | `"          f\"{len(au.get('problems', []))"` |
| `tools/blender/r209/sheets.py` | 90 | 1-90 | `"stack(parts, 'break.jpg')"` |
| `tools/blender/r209/sheets2.py` | 134 | 1-134 | `"    if GOD: lod_sheet([c for c in ('A2',"` |
| `tools/blender/r209/sheets3.py` | 180 | 1-180 | `"    if MAPS: maps_sheet('Ab3' if 'Ab3' i"` |
| `tools/blender/r209/sheets4.py` | 186 | 1-186 | `"    if MAPS: maps_sheet('Ab4' if 'Ab4' i"` |
| `tools/blender/r209/sheets5.py` | 202 | 1-202 | `"    if CLOSE: close_sheet()"` |
| `tools/blender/r209/sheets6.py` | 99 | 1-99 | `"json.dump({k: dict(concept=[round(x) for"` |
| `tools/blender/r209/sheets7.py` | 100 | 1-100 | `"stack(sp, 'silhouette.jpg')"` |
| `tools/blender/r209/sheets7pc.py` | 173 | 1-173 | `"stack(fr, 'fire.jpg')"` |
| `tools/blender/r209/sheets8.py` | 221 | 1-221 | `"stack(fr, 'fire.jpg')"` |
| `tools/blender/r209/sil_dump.py` | 46 | 1-46 | `"print('[sil] dumped', OUT, T.shape, 'obj"` |
| `tools/blender/r209/silhouette4.py` | 135 | 1-135 | `"    elif sys.argv[1] == 'score': score(s"` |
| `tools/blender/r209/silsheet4.py` | 70 | 1-70 | `"out.save(OUT, quality=88); print('sheet'"` |
| `tools/blender/r209/tune4.py` | 67 | 1-67 | `"json.dump(res, open(OUT, 'w'), indent=1)"` |
| `tools/blender/r209/tune5.py` | 137 | 1-137 | `"json.dump(res, open(OUT, 'w'), indent=1)"` |
| `tools/blender/r209/tune5_P.json` | 1098 | 1-1098 | `"}"` |
| `tools/blender/render_multi.py` | 49 | 1-49 | `"    sc.render.filepath = f'{pre}{k}.png'"` |
| `tools/blender/rockgen.py` | 75 | 1-75 | `"        t = to_json(ob, os.path.join(OUT"` |
| `tools/blender/rocks_bake.py` | 13 | 1-13 | `"LOG.write('ROCKS DONE\\n')"` |
| `tools/blender/surface_bakeoff/README.md` | 17 | 1-17 | `"The temporary solver scale handles Blend"` |
| `tools/blender/surface_bakeoff/ROUND2.md` | 19 | 1-19 | `"`round2_run.py` verifies exports by reim"` |
| `tools/blender/surface_bakeoff/RUN_SURFACE_BAKEOFF.bat` | 15 | 1-15 | `"pause"` |
| `tools/blender/surface_bakeoff/RUN_SURFACE_ROUND2.bat` | 15 | 1-15 | `"pause"` |
| `tools/blender/surface_bakeoff/build.py` | 625 | 1-625 | `"    main()"` |
| `tools/blender/surface_bakeoff/probe.gd` | 290 | 1-290 | `"\tquit(0)"` |
| `tools/blender/surface_bakeoff/round2_build.py` | 610 | 1-610 | `"if __name__=='__main__':main()"` |
| `tools/blender/surface_bakeoff/round2_game.gd` | 99 | 1-99 | `"\tquit(0)"` |
| `tools/blender/surface_bakeoff/round2_probe.gd` | 86 | 1-86 | `"\tquit(0)"` |
| `tools/blender/surface_bakeoff/round2_run.py` | 234 | 1-234 | `"if __name__=='__main__':main()"` |
| `tools/blender/surface_bakeoff/run.py` | 185 | 1-185 | `"    main()"` |
| `tools/blender/surface_bakeoff/verify.py` | 74 | 1-74 | `"    main()"` |
| `tools/blender/trellis_bake.py` | 126 | 1-126 | `"log('done verts', len(P), 'tris', len(I)"` |
| `tools/blender/trellis_fleet_bake.sh` | 14 | 1-14 | `"done"` |
| `tools/blender/uvprep.py` | 23 | 1-23 | `"    print(code, res, 'charts', at.chart_"` |
| `tools/blender/vfx/README.md` | 19 | 1-19 | `"The existing weapon-only volume helper m"` |
| `tools/blender/vfx/bake_death.bat` | 10 | 1-10 | `"exit /b %ERRORLEVEL%"` |
| `tools/blender/vfx/bake_death.py` | 57 | 1-57 | `"(out/'bake.json').write_text(json.dumps("` |
| `tools/blender/vfx/bake_route_a.bat` | 15 | 1-15 | `"exit /b %ERRORLEVEL%"` |
| `tools/blender/vfx/bake_route_a.py` | 56 | 1-56 | `"    (out / 'bake.json').write_text(json."` |
| `tools/blender/vfx/bake_route_b.bat` | 15 | 1-15 | `"exit /b %ERRORLEVEL%"` |
| `tools/blender/vfx/bake_route_b.py` | 53 | 1-53 | `"        (out / 'bake.json').write_text(j"` |
| `tools/blender/vfx/bake_weapons.bat` | 10 | 1-10 | `"exit /b %ERRORLEVEL%"` |
| `tools/blender/vfx/bake_weapons.py` | 77 | 1-77 | `"(out/'bake.json').write_text(json.dumps("` |
| `tools/blender/vfx/check_death.bat` | 21 | 1-21 | `"exit /b 1"` |
| `tools/blender/vfx/evidence.py` | 43 | 1-43 | `"(out/'index.html').write_text(html,encod"` |
| `tools/blender/vfx/grammar.md` | 22 | 1-22 | `"Mantaflow is an offline artistic gas mod"` |
| `tools/blender/vfx/grammar_sheet.py` | 52 | 1-52 | `"im.save(out/'death_grammar.png')"` |
| `tools/blender/vfx/pack_death.py` | 69 | 1-69 | `"print(json.dumps(metadata,indent=2))"` |
| `tools/blender/vfx/pack_routes.py` | 223 | 1-223 | `"print('PACK_DONE', a.route, flush=True)"` |
| `tools/blender/vfx/pack_weapons.py` | 71 | 1-71 | `"print(json.dumps(metadata,indent=2))"` |
| `tools/blender/vfx/rebake.bat` | 11 | 1-11 | `"exit /b %ERRORLEVEL%"` |
| `tools/blender/vfx/rebake_evidence.py` | 83 | 1-83 | `"print(json.dumps({k: {q: v for q, v in d"` |
| `tools/blender/vfx/route_common.py` | 198 | 1-198 | `"    return time.time() - t"` |
| `tools/blender/wreck_kit.py` | 292 | 1-292 | `"    stream.write(\"\\n\")"` |
| `tools/build_clips.py` | 69 | 1-69 | `"open('sfx_data.js','w').write(js); print"` |
| `tools/music/audition_2026_11/LISTEN_SHEET.md` | 99 | 1-99 | `"played a battle or two."` |
| `tools/music/catalogue.json` | 38 | 1-38 | `"}"` |
| `tools/music/process.py` | 212 | 1-212 | `"    elif a[0] == 'loopfind': print(loopf"` |
| `tools/music/seamcheck.py` | 32 | 1-32 | `"            print('%-28s jump %5.2f  ste"` |
| `tools/music/selection.json` | 530 | 1-530 | `"}"` |
| `tools/onboarding_cards.json` | 77 | 1-77 | `"]"` |
| `tools/pacecheck_godot.sh` | 45 | 1-45 | `"if [ $F -eq 0 ]; then echo \"PASS: every "` |
| `tools/pc/audio_checks.bat` | 39 | 1-39 | `"exit /b 0"` |
| `tools/pc/autostart_off.bat` | 9 | 1-9 | `"pause"` |
| `tools/pc/autostart_on.bat` | 16 | 1-16 | `"pause"` |
| `tools/pc/bake_all.bat` | 4 | 1-4 | `"echo done > \"%USERPROFILE%\\Downloads\\voi"` |
| `tools/pc/bake_uv.bat` | 22 | 1-22 | `"echo done > %T%\\bakeuv_done.txt"` |
| `tools/pc/codex_board.bat` | 10 | 1-10 | `"goto loop"` |
| `tools/pc/codex_issue.bat` | 76 | 1-76 | `"exit /b 9"` |
| `tools/pc/codex_run.bat` | 31 | 1-31 | `"exit /b %RC%"` |
| `tools/pc/comfy_custom/voidsworn_pixal_views.py` | 35 | 1-35 | `"NODE_DISPLAY_NAME_MAPPINGS = {'Voidsworn"` |
| `tools/pc/comfy_run.py` | 179 | 1-179 | `"        import traceback; log('FAILED', "` |
| `tools/pc/errprobe.py` | 22 | 1-22 | `"    print('\\n'.join(errs[:40])); b.close"` |
| `tools/pc/fx_run.bat` | 19 | 1-19 | `"echo FX DONE %date% %time% >> %T%\\fx_log"` |
| `tools/pc/get_ship_files.bat` | 94 | 1-94 | `"exit /b 0"` |
| `tools/pc/hy_bakeoff.py` | 27 | 1-27 | `"log('HY BAKEOFF DONE')"` |
| `tools/pc/jobs/a2_detail.bat` | 60 | 1-60 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/a3_godot_fx.bat` | 37 | 1-37 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/a4_barge.bat` | 19 | 1-19 | `"exit /b"` |
| `tools/pc/jobs/a4_damage.bat` | 27 | 1-27 | `"exit /b"` |
| `tools/pc/jobs/a4_lineup.bat` | 11 | 1-11 | `"exit /b"` |
| `tools/pc/jobs/a4_looks.bat` | 15 | 1-15 | `"exit /b"` |
| `tools/pc/jobs/a4_regen.bat` | 14 | 1-14 | `"exit /b"` |
| `tools/pc/jobs/a4_repaint.bat` | 28 | 1-28 | `"exit /b"` |
| `tools/pc/jobs/a4_ship.bat` | 42 | 1-42 | `"exit /b"` |
| `tools/pc/jobs/bench207_scene_gate.bat` | 60 | 1-60 | `"exit /b 0"` |
| `tools/pc/jobs/bench207_scene_gate_repeat.bat` | 27 | 1-27 | `"exit /b 0"` |
| `tools/pc/jobs/bench207_scene_gate_res.bat` | 28 | 1-28 | `"exit /b 0"` |
| `tools/pc/jobs/c19_10_kitdark_probe3.bat` | 29 | 1-29 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_11_normals_probe.bat` | 21 | 1-21 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_12_hull_face_probe.bat` | 29 | 1-29 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_13_faceout.bat` | 28 | 1-28 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_14_plating_finish.bat` | 67 | 1-67 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_14b.bat` | 67 | 1-67 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_14c.bat` | 70 | 1-70 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_14d_shots.bat` | 34 | 1-34 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_14e_probe.bat` | 30 | 1-30 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_14f_probe.bat` | 29 | 1-29 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_14g.bat` | 30 | 1-30 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_1_views.bat` | 6 | 1-6 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_1b_views_front_back.bat` | 8 | 1-8 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_2_mesh_fit_paint.bat` | 32 | 1-32 | `"goto :eof"` |
| `tools/pc/jobs/c19_3_lod.bat` | 33 | 1-33 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_4_kit_to_game.bat` | 49 | 1-49 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_5_flatten_panels.bat` | 39 | 1-39 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_6_shell_to_game.bat` | 55 | 1-55 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_7_infill.bat` | 37 | 1-37 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_7_repack_only.bat` | 37 | 1-37 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_8_kitdark_probe.bat` | 30 | 1-30 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_9_kitdark_probe2.bat` | 27 | 1-27 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_v15c.bat` | 62 | 1-62 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/c19_v15d.bat` | 77 | 1-77 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/explosion_routes.bat` | 146 | 1-146 | `"exit /b 0"` |
| `tools/pc/jobs/explosion_routes_sheet.py` | 148 | 1-148 | `"    main()"` |
| `tools/pc/jobs/fx_inside_capture.bat` | 42 | 1-42 | `"exit /b 2"` |
| `tools/pc/jobs/g2_battle_shots.bat` | 24 | 1-24 | `"exit /b 0"` |
| `tools/pc/jobs/g2_checks.bat` | 15 | 1-15 | `"exit /b 0"` |
| `tools/pc/jobs/g2_export.bat` | 51 | 1-51 | `"exit /b 1"` |
| `tools/pc/jobs/godot_gpu_checks.bat` | 94 | 1-94 | `"goto :eof"` |
| `tools/pc/jobs/look_bench.bat` | 170 | 1-170 | `"exit /b 0"` |
| `tools/pc/jobs/look_bench_sheets.py` | 298 | 1-298 | `"    sys.exit(main())"` |
| `tools/pc/jobs/nem122_checks.bat` | 33 | 1-33 | `"exit /b 0"` |
| `tools/pc/jobs/stall220.bat` | 39 | 1-39 | `"exit /b 0"` |
| `tools/pc/jobs/stall220_stills.bat` | 30 | 1-30 | `"exit /b 0"` |
| `tools/pc/jobs/station_blockout.bat` | 26 | 1-26 | `"exit /b %RC%"` |
| `tools/pc/jobs/tex_download.bat` | 6 | 1-6 | `"cd /d \"%~dp0\""` |
| `tools/pc/jobs/ui231_shots.bat` | 36 | 1-36 | `"exit /b 0"` |
| `tools/pc/jobs/ui271_build_shots.bat` | 50 | 1-50 | `"exit /b 0"` |
| `tools/pc/jobs/ui344_briefing_shots.bat` | 75 | 1-75 | `"exit /b 0"` |
| `tools/pc/jobs/ui344_rollout_shots.bat` | 63 | 1-63 | `"exit /b 0"` |
| `tools/pc/jobs/v13k_winding_audit.bat` | 29 | 1-29 | `"cd /d \"%~dp0\""` |
| `tools/pc/parity.bat` | 90 | 1-90 | `"if exist \"%~dp0parity_campaign.bat\" ( ca"` |
| `tools/pc/parity_campaign.bat` | 59 | 1-59 | `"exit /b"` |
| `tools/pc/parity_sweep.bat` | 50 | 1-50 | `"exit /b"` |
| `tools/pc/pcsync.sh` | 8 | 1-8 | `"ls $DST \| wc -l"` |
| `tools/pc/play.bat` | 10 | 1-10 | `"start \"\" msedge --new-window \"http://127"` |
| `tools/pc/play_godot.bat` | 45 | 1-45 | `"exit /b 0"` |
| `tools/pc/play_godot_safe.bat` | 3 | 1-3 | `"call \"%~dp0play_godot.bat\" --rendering-m"` |
| `tools/pc/rocks_bake.bat` | 12 | 1-12 | `"echo done > %T%\\rocks_done.txt"` |
| `tools/pc/run_smoke.bat` | 23 | 1-23 | `"echo DONE > smoke_done.txt"` |
| `tools/pc/setup.bat` | 24 | 1-24 | `"echo SETUP DONE > setup_done.txt"` |
| `tools/pc/sfx_dl.bat` | 27 | 1-27 | `"echo done > \"%USERPROFILE%\\Downloads\\voi"` |
| `tools/pc/sitecustomize.py` | 45 | 1-45 | `"except Exception as e: print('shim: goto"` |
| `tools/pc/tmo.bat` | 8 | 1-8 | `"exit /b %ERRORLEVEL%"` |
| `tools/pc/trellis_bakeoff.py` | 64 | 1-64 | `"log('TRELLIS BAKEOFF DONE')"` |
| `tools/pc/trellis_fleet.py` | 72 | 1-72 | `"log('TRELLIS BAKEOFF DONE')"` |
| `tools/pc/voidsworn_prompts11.json` | 76 | 1-76 | `"}"` |
| `tools/pc/vs_art_o.py` | 60 | 1-60 | `"log(P['done'])"` |
| `tools/pc/vs_mesh12.py` | 38 | 1-38 | `"log('PICKS9 DONE')"` |
| `tools/pc/watcher.bat` | 38 | 1-38 | `"goto loop"` |
| `tools/pc/watcher_b.bat` | 31 | 1-31 | `"goto loop"` |
| `tools/pc/work/README.md` | 34 | 1-34 | `"Windows path end to end."` |
| `tools/pc/work/mock_llm.js` | 64 | 1-64 | `"server.listen(port, '127.0.0.1');"` |
| `tools/pc/work/opencode.json` | 11 | 1-11 | `"}"` |
| `tools/pc/work/opencode_mock.json` | 15 | 1-15 | `"}"` |
| `tools/pc/work_issue.bat` | 148 | 1-148 | `"exit /b 6"` |
| `tools/pc/work_pro_120.bat` | 43 | 1-43 | `"exit /b 0"` |
| `tools/pc/work_setup.bat` | 124 | 1-124 | `"exit /b 0"` |
| `tools/pc/work_trial.bat` | 45 | 1-45 | `"exit /b 0"` |
| `tools/portraits/batches/b1a.json` | 52 | 1-52 | `"}"` |
| `tools/portraits/batches/b1b.json` | 79 | 1-79 | `"}"` |
| `tools/portraits/batches/b1c.json` | 123 | 1-123 | `"}"` |
| `tools/portraits/batches/b1q.json` | 96 | 1-96 | `"}"` |
| `tools/portraits/batches/b2.json` | 75 | 1-75 | `"}"` |
| `tools/portraits/batches/c64.json` | 182 | 1-182 | `"}"` |
| `tools/portraits/batches/c64b.json` | 182 | 1-182 | `"}"` |
| `tools/portraits/batches/c64c.json` | 182 | 1-182 | `"}"` |
| `tools/portraits/batches/e64a.json` | 202 | 1-202 | `"}"` |
| `tools/portraits/batches/e64b.json` | 216 | 1-216 | `"}"` |
| `tools/portraits/batches/e64c.json` | 146 | 1-146 | `"}"` |
| `tools/portraits/batches/e64d.json` | 34 | 1-34 | `"}"` |
| `tools/portraits/batches/e64e.json` | 34 | 1-34 | `"}"` |
| `tools/portraits/batches/f64.json` | 69 | 1-69 | `"}"` |
| `tools/portraits/batches/f64b.json` | 195 | 1-195 | `"}"` |
| `tools/portraits/batches/k64.json` | 188 | 1-188 | `"}"` |
| `tools/portraits/batches/k64b.json` | 120 | 1-120 | `"}"` |
| `tools/portraits/batches/k64c.json` | 237 | 1-237 | `"}"` |
| `tools/portraits/batches/k64d.json` | 281 | 1-281 | `"}"` |
| `tools/portraits/batches/n1a.json` | 204 | 1-204 | `"}"` |
| `tools/portraits/batches/n1b.json` | 204 | 1-204 | `"}"` |
| `tools/portraits/batches/n1fix.json` | 41 | 1-41 | `"}"` |
| `tools/portraits/batches/n1s_a.json` | 195 | 1-195 | `"}"` |
| `tools/portraits/batches/n1s_b.json` | 195 | 1-195 | `"}"` |
| `tools/portraits/batches/n1s_c.json` | 90 | 1-90 | `"}"` |
| `tools/portraits/batches/n1s_c2.json` | 90 | 1-90 | `"}"` |
| `tools/portraits/batches/n2.json` | 204 | 1-204 | `"}"` |
| `tools/portraits/batches/n3.json` | 66 | 1-66 | `"}"` |
| `tools/portraits/batches/p64ga.json` | 406 | 1-406 | `"}"` |
| `tools/portraits/batches/p64gn.json` | 606 | 1-500, 501-606 | `"}"` |
| `tools/portraits/batches/p64ha.json` | 230 | 1-230 | `"}"` |
| `tools/portraits/batches/p64hn.json` | 342 | 1-342 | `"}"` |
| `tools/portraits/batches/r8a.json` | 162 | 1-162 | `"}"` |
| `tools/portraits/batches/r8b.json` | 104 | 1-104 | `"}"` |
| `tools/portraits/batches/r8c.json` | 28 | 1-28 | `"}"` |
| `tools/portraits/batches/r8e.json` | 202 | 1-202 | `"}"` |
| `tools/portraits/batches/r8f.json` | 111 | 1-111 | `"}"` |
| `tools/portraits/batches/r8s_a.json` | 174 | 1-174 | `"}"` |
| `tools/portraits/batches/r8s_b.json` | 216 | 1-216 | `"}"` |
| `tools/portraits/batches/r8s_c.json` | 258 | 1-258 | `"}"` |
| `tools/portraits/batches/s64g.json` | 174 | 1-174 | `"}"` |
| `tools/portraits/batches/s64h.json` | 258 | 1-258 | `"}"` |
| `tools/portraits/batches/s68a.json` | 272 | 1-272 | `"}"` |
| `tools/portraits/batches/s68b.json` | 258 | 1-258 | `"}"` |
| `tools/portraits/batches/s68c.json` | 216 | 1-216 | `"}"` |
| `tools/portraits/batches/s68g.json` | 160 | 1-160 | `"}"` |
| `tools/portraits/batches/s68h.json` | 230 | 1-230 | `"}"` |
| `tools/portraits/batches/s68i.json` | 146 | 1-146 | `"}"` |
| `tools/portraits/batches/s68j.json` | 27 | 1-27 | `"}"` |
| `tools/portraits/batches/v64g.json` | 446 | 1-446 | `"}"` |
| `tools/portraits/batches/v64g2.json` | 438 | 1-438 | `"}"` |
| `tools/portraits/batches/v64g3.json` | 90 | 1-90 | `"}"` |
| `tools/portraits/batches/v64h.json` | 446 | 1-446 | `"}"` |
| `tools/portraits/batches/v64h2.json` | 446 | 1-446 | `"}"` |
| `tools/portraits/batches/v64h3.json` | 336 | 1-336 | `"}"` |
| `tools/portraits/batches/v64h4.json` | 146 | 1-146 | `"}"` |
| `tools/portraits/batches/v64h5.json` | 132 | 1-132 | `"}"` |
| `tools/portraits/batches/v64h6.json` | 62 | 1-62 | `"}"` |
| `tools/portraits/concept_sheets.py` | 73 | 1-73 | `"        for sp in SPECIES: sheet(src, ou"` |
| `tools/portraits/crests.py` | 264 | 1-264 | `"    except ImportError as e: print('no s"` |
| `tools/portraits/make_batches.py` | 813 | 1-500, 501-813 | `"        print(k, len(items), 'items', su"` |
| `tools/portraits/make_edits.py` | 423 | 1-423 | `"    json.dump({'out': 's68', 'budget_s':"` |
| `tools/portraits/nemesis_crop.py` | 53 | 1-53 | `"    json.dump(A, open(os.path.join(out, "` |
| `tools/portraits/nemesis_fx.py` | 140 | 1-140 | `"    print('frames and scars written to',"` |
| `tools/portraits/nemesis_publish.py` | 87 | 1-87 | `"    main(sys.argv[1], sys.argv[2])"` |
| `tools/portraits/p64_publish.py` | 94 | 1-94 | `"    elif a[0] == 'crops': crops(a[1], a["` |
| `tools/portraits/phone_sheets.py` | 63 | 1-63 | `"    admirals(out); nemesis(out)"` |
| `tools/portraits/picks_b1b2.json` | 16 | 1-16 | `"}"` |
| `tools/portraits/plates.py` | 22 | 1-22 | `"    for f in GLOW: plate(f).save(os.path"` |
| `tools/portraits/portrait_edit.py` | 41 | 1-41 | `"    main(sys.argv[1])"` |
| `tools/portraits/portrait_run.py` | 162 | 1-162 | `"    elif a[0] == 'gen': gen(a[1])"` |
| `tools/portraits/portrait_specs.py` | 179 | 1-179 | `"    return EDIT.format(what=what, settin"` |
| `tools/portraits/post.py` | 112 | 1-112 | `"    elif a[0] == 'phone': cmd_phone_shee"` |
| `tools/portraits/r8_prep.py` | 61 | 1-61 | `"    main(sys.argv[1], sys.argv[2])"` |
| `tools/portraits/r8_publish.py` | 36 | 1-36 | `"    main(sys.argv[1])"` |
| `tools/portraits/v64_publish.py` | 194 | 1-194 | `"    elif a[0] == 'sheet': sheet(a[1], a["` |
| `tools/recipe/1_concept_in.bat` | 21 | 1-21 | `"exit /b 1"` |
| `tools/recipe/2_shape_ref.bat` | 20 | 1-20 | `"exit /b 1"` |
| `tools/recipe/3_trace_hull.bat` | 38 | 1-38 | `"exit /b 1"` |
| `tools/recipe/4_parts_kit.bat` | 36 | 1-36 | `"exit /b 1"` |
| `tools/recipe/5_paint_bake.bat` | 21 | 1-21 | `"exit /b 1"` |
| `tools/recipe/6_lod.bat` | 20 | 1-20 | `"exit /b 1"` |
| `tools/recipe/7_export.bat` | 50 | 1-50 | `"exit /b 1"` |
| `tools/recipe/audit.py` | 43 | 1-43 | `"sys.exit(0 if au['result'] == 'PASS' els"` |
| `tools/recipe/audit_selftest.py` | 37 | 1-37 | `"sys.exit(0 if ok else 1)"` |
| `tools/recipe/check_export.py` | 161 | 1-161 | `"    main()"` |
| `tools/recipe/check_export_selftest.py` | 69 | 1-69 | `"sys.exit(1 if bad else 0)"` |
| `tools/recipe/env.bat` | 35 | 1-35 | `"if \"%BAKE%\"==\"\" set BAKE=bakeAb6.py"` |
| `tools/recipe/export7.py` | 247 | 1-247 | `"print('[export7] written', OUT, flush=Tr"` |
| `tools/recipe/gamedata.py` | 20 | 1-20 | `"    print(weapons(sys.argv[1]))"` |
| `tools/recipe/ship.py` | 25 | 1-25 | `"    Image.open(os.path.join(REPO, json.l"` |
| `tools/recipe/ships/C15s_23.json` | 301 | 1-301 | `"}"` |
| `tools/recipe/ships/_template.json` | 19 | 1-19 | `"}"` |
| `tools/shots/ui344_briefing_sheet.py` | 80 | 1-80 | `"    sys.exit(main())"` |
| `tools/shots/ui344_contact_sheet.py` | 99 | 1-99 | `"    sys.exit(main())"` |
| `tools/test_onboarding.js` | 104 | 1-104 | `"fs.writeFileSync(path.join(out, 'PASS.tx"` |
| `tools/test_onboarding_gate.js` | 61 | 1-61 | `"`);"` |

</details>

<details><summary>Cited-id cross-reference to FINDINGS history</summary>

| Id | Registry source | Opening words / status text |
|---|---|---|
| D1 | `contrib/opus/FINDINGS.md:319` | Barge v14 files in the repo (READING_PLAN.md:9; pipeline README:58, :64) WRONG at d5d0227 No .vsm or _kit.json was in git. |
| D2 | `contrib/opus/FINDINGS.md:320` | Barge "done end to end" (pipeline README:6) or "awaiting verdict" (SHIP_QUEUE.md:17) STALE v14 verdict "it's pretty close" (NEXT.md:56): clean blocky |
| D3 | `contrib/opus/FINDINGS.md:321` | Kit script builds space-only parts WRONG c19_kit.py:173 mast with yards, :160 funnels, :38 keel line, :403 keel plate. AUDIT_SYNTHESIS.md:208-218 prescribes |
| D22 | `contrib/opus/FINDINGS.md:340` | Sonniss clips in a public repo (field guide line 350: files may not be handed to others; sfx_data.js carries them |
| R1 | `contrib/opus/FINDINGS.md:26` | Battle size grows over a run: about 10, 14, then 20 ships on board. 20 is a guide, not a |
| R2 | `contrib/opus/FINDINGS.md:27` | The dead-star gravity-well board stays. The Dead Star painting is its backdrop and a finale backdrop. |
| R3 | `contrib/opus/FINDINGS.md:28` | Shields keep their faction colours. The cyan-only shield rule is retired for 3D shields. Interface shield bars stay cyan. |
| R4 | `contrib/opus/FINDINGS.md:29` | Capture: boarded enemies switch sides in battle. After a win each prize gets add, strip or ransom. A full fleet |
| R7 | `contrib/opus/FINDINGS.md:32` | One enemy commander per run is both the Nemesis and the story rival. |
| R8 | `contrib/opus/FINDINGS.md:33` | The barge gets the Corsair rust-and-bone palette. Naval reads are removed from the whole hull shape, not just the parts; |
| R11 | `contrib/opus/FINDINGS.md:36` | Plan approved (contrib/opus/go-forward-plan.md). The old two-helper limit is retired. |
| R12 | `contrib/opus/FINDINGS.md:37` | Barge shape (A1 step 1, Oct 24 late): option C, the double-sided hulk (diamond bow, matching blocks top and bottom, |
| R14 | `contrib/opus/FINDINGS.md:39` | Barge paint approved (A1 step 3, Oct 25): bolted stolen panels in rust, Hegemony grey, bare steel and bone; "Yes, |
| R23 | `contrib/opus/FINDINGS.md:48` | Oct 25, B2 calls: (1) no enemy squadrons yet; Ryan judges big-fleet tempo in play first (turns already under 15 |
| R24 | `contrib/opus/FINDINGS.md:49` | Oct 25: (1) Dead Star: the gravity-well board stays as it plays today; the painting is its backdrop (re-confirms R2; |
| R28 | `contrib/opus/FINDINGS.md:53` | Oct 25 night, A3 engine call. Blind read finished (A = Babylon, B = Godot): Godot better lighting and ship |
| R31 | `contrib/opus/FINDINGS.md:56` | Oct 26, A3 proof part 1 (effects parity) built and run on Ryan's PC (6890db6). Babylon's effect system ported into |
| R33 | `contrib/opus/FINDINGS.md:58` | Oct 26, Godot move scope (Ryan): first playable Godot build is one full battle; today's browser version frozen (only fixes |
| R36 | `contrib/opus/FINDINGS.md:61` | Oct 26, Ryan on the Godot campaign map screenshot: "fine right now but I do want to add it to |
| R37 | `contrib/opus/FINDINGS.md:62` | Oct 26, Ryan: "For muse picks, agreed on all counts" (contrib/muse/reviews/sprint_decision_packs.md): story and career start small (admiral lines in the |
| R38 | `contrib/opus/FINDINGS.md:63` | Oct 26, Ryan on the 3D map first pass: "better but it's still pretty basic with icons and imagery. We |
| R39 | `contrib/opus/FINDINGS.md:64` | Oct 26, Ryan on the breach shots: "the breach effects still need work. Right now it's just an orange shape |
| R40 | `contrib/opus/FINDINGS.md:65` | Oct 26, Ryan: music from free licensed tracks first (royalty-free or CC0, fitting the R37 direction); admiral portrait drafts made |
| R41 | `contrib/opus/FINDINGS.md:66` | Oct 26, Ryan on the story arcs: read the full text first (published at https://claude.ai/artifact/CjXGraJBfX9aYrs3xKDKxb); finishing an arc gives BOTH |
| R42 | `contrib/opus/FINDINGS.md:67` | Oct 26, Ryan: story text "pretty good"; wants independent review against other games' stories before building (two blind Claude reviewers, |
| R43 | `contrib/opus/FINDINGS.md:68` | Oct 26, Ryan on A4's real-hull breach sheet: "that looks way better. We should take a similar approach for other |
| R45 | `contrib/opus/FINDINGS.md:70` | Oct 26, Ryan commissioned incorporation of the four-way blind story review (contrib/muse/reviews/story_review_synthesis.md, GO WITH CONDITIONS, 10 fixes): outlines approved in |
| R49 | `contrib/opus/FINDINGS.md:74` | Oct 26, Ryan on the verifier's design questions: Deathless Nemesis comeback only in sector 3 (withdraws like the others before); |
| R50 | `contrib/opus/FINDINGS.md:75` | Oct 26, Ryan from prior battles: (1) "The reaction of ships getting hit is kind of a simple cartoonish push |
| R51 | `contrib/opus/FINDINGS.md:76` | Oct 26, Ryan on the round-2 campaign map shots: "It's definitely closer but I'd like to upgrade the visuals a |
| R55 | `contrib/opus/FINDINGS.md:82` | Oct 27, Ryan on stream B pass 3 and the G2 thruster movement (680324c): agrees with the B fixes and |
| R59 | `contrib/opus/FINDINGS.md:86` | Oct 27 15:28 PT, Ryan: **"Lore approved. Good to go. Let's ensure that it carries through everything the helpers are |
| R62 | `contrib/opus/FINDINGS.md:89` | Oct 28, Ryan's progression and loop rulings recorded by Muse (progression_synthesis_2026_10_28.md:22,44,48; rewards_synthesis_2026_10_28.md:36,40; loop_synthesis_2026_10_28.md:44; validation_synthesis_2026_10_28.md:51,55; variety_synthesis_2026_10_28.md:55; hud_synthesis_2026_10_27.md:40; events_synthesis_2026_10_27.md:44): a high run-loss |
| R63 | `contrib/opus/FINDINGS.md:90` | Oct 29, Ryan's battle-layer and economy rulings recorded by Muse (fights_synthesis_2026_10_28.md:47; nemesis_synthesis_2026_10_28.md:47-48; roster_synthesis_2026_10_28.md:51; battlefield_synthesis_2026_10_28.md:50; skill_tree_proposal_final_2026_10_28.md:85; factionshape_synthesis_2026_10_29.md:45,49; battleui_activation_models_2026_10_29.md:37; economy_synthesis_2026_10_29.md:39,43), spot-checked by |
| R64 | `contrib/opus/FINDINGS.md:92` | Nov 1 01:20 CDT, Ryan's rulings after his first Godot playtest (contrib/opus/briefs/feel_pass_2026-11-01.md): battle feel before more playtest data; movement about |
| R68 | `contrib/opus/FINDINGS.md:96` | Nov 1 07:37 CDT, Ryan: "We should have portraits on different backgrounds, different poses, etc so the admirals and nemesis |
| R69 | `contrib/opus/FINDINGS.md:97` | Nov 1 11:54 CDT, Ryan on fresh-save unlocks in Godot (6 of 24 admirals free, carriers and battleships locked, about |
| R73 | `contrib/opus/FINDINGS.md:101` | Nov 1 20:54 CDT, Ryan on the destruction plan (contrib/muse/research/destruction_2026_11/synthesis.md): a brief slow-motion beat on kills only for big ships |
| R75 | `contrib/opus/FINDINGS.md:103` | Nov 2 08:21 CDT, Ryan on agent coordination: "Use both your picks." The job board is GitHub issues with owner |
| R76 | `contrib/opus/FINDINGS.md:104` | Nov 2 10:17 CST, Ryan's playtest (9 battles, exe b50c932) and his calls (Opus picks accepted): movement glides on smooth |
| R79 | `contrib/opus/FINDINGS.md:107` | Nov 2 14:35 CST, Ryan on the Muse job 10 backdrop questions (contrib/muse/research/backdrops_2026_11/synthesis.md section 8): planets stay procedural and get |
| R80 | `contrib/opus/FINDINGS.md:108` | Nov 2, Ryan's rulings on the damage research (contrib/muse/research/damage_surface_2026_11/synthesis.md, Owner rulings): open breaks only at stage 4 (20 percent section |
| R82 | `contrib/opus/FINDINGS.md:110` | Nov 3 07:56 CST, Ryan: "Agree with picks." Terrain fx (contrib/muse/research/terrain_fx_2026_11/synthesis.md section 9): Q1 fixed violet nebula family, faction tint |
| R85 | `contrib/opus/FINDINGS.md:113` | Nov 3 13:58 CST, Ryan: "agree with picks" on the Nemesis assignment design (contrib/muse/design/nemesis_assignment_2026_11/synthesis.md section 8): Q1 a hunter drawn |
| R88 | `contrib/opus/FINDINGS.md:116` | Nov 3 16:31 CST, Ryan after playtest g2_pt_c7b4808: planets better but terrain planets need much higher quality; campaign map movement |
| R91 | `contrib/opus/FINDINGS.md:119` | Nov 3 20:31 CST, Ryan agreed with the Opus pick on the #61 station blockouts (PR #142): keep the 46-unit |
| R94 | `contrib/opus/FINDINGS.md:122` | Nov 4 02:49 CST, Ryan on the #61 station blockouts (PR #151, board\issue-61\shots\r91 fleet_review.jpg, refinery_review.jpg): approved the height and silhouette |
| R96 | `contrib/opus/FINDINGS.md:124` | Nov 4 02:49 CST, Ryan adopted all five chair picks of the ship look round 3 research (#147, PR #154, |
| R98 | `contrib/opus/FINDINGS.md:126` | Nov 4 08:49 CST, Ryan after his playtest ("the broken open pieces are visibly empty"; "should the empty ship/death/destruction issue |
| R99 | `contrib/opus/FINDINGS.md:127` | Nov 4 10:40 CST, Ryan on the breakable-ships research (#171, PR #174, contrib/muse/research/breakable_ships_2026_11/synthesis.md section 8). Q1 ADOPTED: thick where it |
| R100 | `contrib/opus/FINDINGS.md:128` | Nov 4 12:55 CST, Ryan adopted all five chair picks of the station detail brief (#172, PR #178, contrib/muse/research/station_detail_2026_11/synthesis.md section |
| R101 | `contrib/opus/FINDINGS.md:129` | Nov 4 12:55 CST, Ryan adopted the Nemesis writing as is (#173, PR #181, contrib/muse/design/nemesis_writing_2026_11/synthesis.md and text_table.md): all five chair |
| R103 | `contrib/opus/FINDINGS.md:131` | Nov 4 18:20 CST, Ryan on the Pyre-Barge round 5 sheets (#163, PR #186 merged as tools and report only): |
| R105 | `contrib/opus/FINDINGS.md:133` | Nov 4 21:40 CST, Ryan adopted all five picks of the readable-paint standard (#188, PR #191, contrib/muse/research/readable_paint_2026_11/synthesis.md section 6): readability |
| R111 | `contrib/opus/FINDINGS.md:139` | Nov 6 2026, Ryan, the R96 ceiling replacement (#207 section 2, from the ceiling pressure test): measurement floor is the |
| R113 | `contrib/opus/FINDINGS.md:141` | Nov 7 2026 18:40 CST, Ryan: drop both remaining triangle caps in the #200 standard. D20's station triangle figures (about |
| R116 | `contrib/opus/FINDINGS.md:144` | Nov 7 2026 21:56 CST, Ryan, the scene gate (R111, R115): **12.5 ms, 75% of the 16.7 ms frame**, read |
| R118 | `contrib/opus/FINDINGS.md:146` | Nov 7 2026, #220 effects spawn stalls (Opus, project thread on the PC; PR #223, docs/shots/ship_pipeline/bench207/stalls/README.md). Per-frame trace of the |
| R124 | `contrib/opus/FINDINGS.md:152` | Nov 8 2026, board (Opus), #213 environment audit (Ryan, Nov 6): run the loom turntable, judged on looming, clutter and |
| R131 | `contrib/opus/FINDINGS.md:159` | Nov 8 2026, board (Opus), #228 movement spec (contrib/opus/briefs/movement_spec.md, PR #251): one build reference replaces R50, R55 and R76's movement |
| R135 | `contrib/opus/FINDINGS.md:163` | Nov 8 2026 16:30 CST, board (Opus) with Ryan. The first two spin-off threads (#231 at 13:45, #121 at 14:24 |
| R136 | `contrib/opus/FINDINGS.md:164` | Nov 8 2026, #231 consolidated UI specification (Opus worker thread; contrib/opus/briefs/ui_spec.md, debrief_spec.md and the generated two-build table ui_spec_constants.md; PR from |
| R137 | `contrib/opus/FINDINGS.md:165` | Nov 8 2026 16:53 CST, Ryan on the #231 debrief sheet: "Yes" to the debrief spec's layout as #92's target |
| R140 | `contrib/opus/FINDINGS.md:167` | Nov 8 2026 20:30 CST, Ryan on #209 round 1 (PR #287, sheets in docs/shots/ship_pipeline/route209/): A (hand build) and B3 |
| R145 | `contrib/opus/FINDINGS.md:172` | Ryan, Nov 9 2026 07:08 CST Ruled Four picks. (1) Ship #209: "Hy3 and ab3" both go forward to round |
| R147 | `contrib/opus/FINDINGS.md:174` | Ryan, Nov 9 2026 09:47 CST, on #209 round 4 (PR #316) Ruled "agreed on that approach and what's wrong. |
| R148 | `contrib/opus/FINDINGS.md:175` | Ryan, Nov 9 2026 10:41 CST, on the #271 build captures (PR #314) Ruled Agrees with the two board fixes |
| R149 | `contrib/opus/FINDINGS.md:176` | Ryan, Nov 9 2026 12:00 CST, on docs/shots/ui_redesign/identity/identity_sheet.jpg (PR #314) Ruled "yeah i like lime tactical, run it." The battle |
| R150 | `contrib/opus/FINDINGS.md:177` | Ryan, Nov 9 2026 13:27 CST, on #209 round 5 (PR #325) and #281 run 5 (PR #327) Ruled Ships: |
| R151 | `contrib/opus/FINDINGS.md:178` | Ryan, Nov 9 2026 14:52 CST, on the three ship questions Ruled (1) Order: recipe first ("1a"): turn rounds 1 |
| R155 | `contrib/opus/FINDINGS.md:182` | Board (Fable 5.2), Nov 9 2026 23:32 UTC, outside audit pass 1 (PR #334, merged; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md, pinned to da01a7a) Verdicts |
| R156 | `contrib/opus/FINDINGS.md:183` | Ryan, Nov 9 2026 18:16 CST, on #209 round 6 (PR #336) and the Board's takes Ruled "I agree with |
| R158 | `contrib/opus/FINDINGS.md:185` | Ryan, Nov 9 2026 19:18 CST, on the Board's three audit questions Ruled "Agree on those questions outside of waiting |
| R160 | `contrib/opus/FINDINGS.md:187` | Board (Fable 5.2), Nov 10 2026 04:50 UTC: Muse's hole-poking of both audits (PR #345, merged; contrib/muse/reviews/audit_pass1_holes_2026_11.md), the tree hand-off |
| R164 | `contrib/opus/FINDINGS.md:191` | Ryan, Nov 10 2026 07:38 and 07:58 CST (owner rulings), with the Board's corrections Owner rulings (1) Seats until ChatGPT |
| R165 | `contrib/opus/FINDINGS.md:192` | Ryan, Nov 10 2026 08:29 CST (owner pick: the campaign map) Owner ruling Shown the three options of R164, he |
| R170 | `contrib/opus/FINDINGS.md:197` | Ryan, Nov 10 2026 19:02 and 19:11 CST (program decisions 1 and 3; Codex) Owner rulings (1) Codex: 'Yes, run |
| R174 | `contrib/opus/FINDINGS.md:201` | Ryan, Nov 10 2026 21:15 to 21:25 CST (his review of campaign map round 3, PR 432) Owner rulings Round |
| R176 | `contrib/opus/FINDINGS.md:203` | Ryan, Nov 10 2026 21:39 CST (his picks on the rail options and the Sunward sheets) Owner rulings (1) The |
| R187 | `contrib/opus/FINDINGS.md:214` | Ryan, Nov 11 2026 09:16 CST, and his four picks Owner ruling: the cinematic audit His words: "Can we do |
| R191 | `contrib/opus/FINDINGS.md:218` | Ryan, Nov 11 2026, about 10:40 CST: the first batch of old calls from the rules sweep (issue 492), four |
| X20 | `contrib/opus/FINDINGS.md:240` | Oct 26, Muse travel-sprint reviews A to D (contrib/muse/reviews/sprint_*.md, Argon, DeepSeek, Qwen) routed. G1: hash gaps verified (rules.gd CUT, SOLID, |

</details>
