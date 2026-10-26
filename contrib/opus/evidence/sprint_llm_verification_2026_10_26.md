# Independent check of the Oct 26 travel sprint syntheses (Muse chair, DeepSeek, Qwen, Argon legs)

Checked Oct 26 2026 against main at fa93e1f (code unchanged since bfe36e6), plus git history. Owner request (R45): verify every outside-model finding, question the ones that do not hold.

How to read this:
- The Job A and Job C legs worked from an evidence pack cut at commit 9273632 (06:52; rules.gd 117,728 bytes, godot/ holding only rules/). The syntheses were filed later (Job A be60fd7 07:51, Job B b5702a8 08:02, Job C ef7de9c 08:05, Job D 2e7c9c1 08:28, story b8793f3 13:24). Several items were already fixed on main before their synthesis was filed; those are marked TRUE BUT FIXED with the commit.
- DeepSeek's rules.gd, jsm.gd, battle_api.gd, parity_main.gd and golden.js line numbers match no committed version of those files (checked 727edd6, 9273632 and HEAD, with and without blank lines). The code facts behind them are mostly right; the line numbers should not be reused.
- The story reviewers read godot/story/outlines.md before f51fcf8 ("old" below, f51fcf8^). "New" is the current file.
- Coverage numbers come from running node/golden.js on all 31 scenarios at HEAD (Node side only; there is no Godot binary in the cloud sandbox). Output stayed in scratch, nothing committed.
- Verdicts: TRUE, TRUE BUT FIXED in commit, FALSE, PARTLY, UNVERIFIABLE.

## 1. contrib/muse/reviews/sprint_rules_port_review.md (Job A)

| # | Claim (short) | Verdict | Evidence | Next |
|---|---|---|---|---|
| A1 | CUT and SOLID are module level, outside B, hashed nowhere (rules.gd:27-28, set at :351, read at :238) | TRUE BUT FIXED in e83bae2 | Pack: rules.gd:25-26 (9273632), onBoard at 319, genTerrain at 432, so the cited lines are wrong. Now hashed in a "g" block on both sides: parity_main.gd:59-64, golden.js:145. Side note: the stated consequence is too strong. A CUT or SOLID difference that changes any move or shot changes unit q, r or hp, which were always hashed; only a difference with no effect on play went unseen. | None. |
| A2 | deferred and UID are hashed nowhere (rules.gd:29) | PARTLY | UID: fixed in e83bae2 (gl.uid). deferred: still not hashed, and it should not be: it holds Callables (rules.gd:32, :2541) that flush_deferred runs right after the tick (rules.gd:1404-1406, :1930, :1936). JS has no matching value to hash (promise continuations). The order of death tails shows in the battle log, which has been in the hash since 467ac6f. Pack lines: UID 28, deferred 30, not 29. | Close. FINDINGS X20 already says the same. |
| A3 | s1-s5 are all rout on open, station or belt, Hegemony and Corsair only | TRUE BUT FIXED in 265d46d and 467ac6f | 265d46d added s6-s10 (all five enemy factions, generated fleets). 467ac6f (07:41, ten minutes before the synthesis) added s11-s23: defend, hunt, intercept, break, hold, ambush, flagship, the dead star (s19). Now 31 scenarios. | None. |
| A4 | Enemy fleet generation unported; API.md says pass enemies | TRUE BUT FIXED in 265d46d | Pack API.md:24 "G1 work in progress; today pass enemies". Now ported (API.md:24 genEnemyFleet); s7, s9, s10, s20, s24, s25 omit enemies. | None. |
| A5 | np() at rules.gd:68-69; guards that never fire | PARTLY | np() is at rules.gd:78 (pack), :94 now. 47 np( mentions at the pack; now only 2 call sites: rules.gd:145 (unknown weapon trait) and :332 (unknown boon), both data-error guards. | Optional: one tiny test per guard. |
| A6 | Test README says "after every activation"; harness records per action | TRUE BUT FIXED in 467ac6f and e83bae2 | Pack README:28 said after every activation. 467ac6f: "After every action". e83bae2: itemised list of record points (README:29-34). | None. |
| A7 | Handled in what DeepSeek read: jt at rules.gd:70, is_same at battle_api.gd:88/92/128/161, V8 round at jsm.gd:39-41, fdlibm words 41-61, _atan 114-126, merge sort 220-228, canon numbers 236-237 | PARTLY | Every fact holds; every line number is wrong. Pack: jt rules.gd:81; is_same battle_api.gd:69, 96, 187; jsround jsm.gd:63; IEEE-word constants from jsm.gd:70; atan wraps _atan at 182-183; ssort (stable bottom-up merge) at 277; num() ints or "d:"+hex at 311. | Do not reuse the line numbers. |
| A8 | Trap D and trap F greps still open (bare sin/cos/atan2/exp/hypot/round, .sort, comparator truncation) | PARTLY | Grep of current rules.gd: no bare sin, cos, atan2, exp, hypot, round or pow outside JSM; no .sort( or .sort_custom( in rules.gd or battle_api.gd; the % hits seen are on int values (rules.gd:655, 1451, 1529, 2288). Comparator truncation cannot happen: ssort tests float(cmp.call(...)) < 0.0. Not done: a classified pass over every / and the 13 str( calls. | Low priority; 31 scenarios and the 283,730-input math check pass. |
| A9 | Sorts DeepSeek read go through JSM.ssort (rules.gd:262, :392, :395; battle_api.gd:169) | PARTLY | True, lines wrong (pack rules.gd:365, 589, 598; battle_api.gd:204). | None. |
| A10 | Battle log is in SKIP_B on both sides, so not hashed (golden.js:133, parity_main.gd:30-31) | TRUE BUT FIXED in 467ac6f | Pack golden.js:70 had log in SKIP_B. 467ac6f removed it on both sides ("the battle log is in the hash", golden.js:133 now, parity_main.gd:53). Fixed before the synthesis was filed. | None. |
| A11 | golden.js wraps useAbility, giveOrder, startSideTurn and useCommand | PARTLY | At the pack only three were wrapped (golden.js:32-34 at 9273632). useCommand was added in 265d46d. All four now (golden.js:32-35). | None. |
| A12 | tables.json SHA-256 checked at load, _dec rebuilds "#d:" doubles (rules.gd:41-44, 63-66) | TRUE | Pack rules.gd:50-51 and 64-75 (lines off). | None. |
| A13 | SHA only proves the file matches itself; export may silently drop functions, Infinity, NaN, undefined or lazily built tables | PARTLY | export_data.js finds top-level ALL-CAPS const/let by regex plus a hand list of 18 mid-line names, and drops functions, Sets and Maps with only a printed "skipped" list. Infinity and NaN are not dropped (written as hex doubles). load_tables reads each table by name (rules.gd:52-60 at pack), so a missing named table fails at load. | Still open, small: make the export exit non-zero when a table the port reads is missing. |
| A14 | Shapes "listed at rules.gd:366": hourglass, rift, shoals, colossus, archipelago, corridor, compact, belt, station, planet, storm, graveyard | FALSE | SHAPES (battle.js:18) has 12: open, corridor, lanes, ring, dense, compact, deadstar, rift, shoals, hourglass, archipelago, colossus. belt, station, planet, storm and graveyard are maps, not shapes. Scenarios cover shapes open, corridor, ring, dense, deadstar; none covers lanes, compact, rift, shoals, hourglass, archipelago, colossus (only the random sweep does). | Optional per-shape scenarios, or rely on the sweep. |
| A15 | Abilities: the pack said 12 but listed 13 | TRUE | data.js ABILITIES has 13: evasive, reload, focus, launch, surge, nova, ionpulse, overburn, frenzy, regrow, blink, phase, reclaim. Matches API.md. | None. |
| A16 | Death causes: 7 named, no 8th adopted | TRUE | 7: killCauseOf (battle.js:909-914) gives flay, melt, cut, big, dark, blast; tidal at battle.js:282; melt and dark at 381-382. | None. |
| A17 | 8 fight types | TRUE | The scenario obj values (rout, defend, hunt, intercept, break, hold, flagship, ambush) are all in golden scenarios since 467ac6f. setupObjective is at battle.js:940-951. | None. |
| A18 | Pack sort lines (569, 864, 1052, 1073) do not match battle.js (401 lines) or the oracle (402 lines); DeepSeek found sorts at 43, 228, 232, 308, 361 | FALSE | battle.js was 1,155 lines at the pack (9273632) and in the pinned oracle (e7893f0). Lines 569, 864, 1052 and 1073 each hold a .sort( there; DeepSeek's lines 43, 228, 232, 308 and 361 hold none. The pack was right and DeepSeek's view was wrong. | Drop this discrepancy. |
| A19 | Port size vs the 1.5x threshold cannot be assessed | TRUE (now resolved) | rules.gd 3,724 lines, battle_api.gd 630, jsm.gd 473: 4,827 total. R29 estimate: about 2,600 done plus 2,500 to 3,000 more, so 5,100 to 5,600. Under 1.0x. | Close: within estimate. |
| A20 | godot/fx/API.md is on main at 13,540 bytes | TRUE | Added in f45852c (06:59) at 13,540 bytes; 14,134 at synthesis time; 20,987 now. | None. |
| A21 | Proof slice ran 60 seeds; no 200-seed sweep on the full port has been shown | TRUE (still open) | R29: 60 of 60. Sweep tools landed in 467ac6f (run_sweep.sh, sweep_gen.js, sweep_check.js, tools/pc/parity_sweep.bat), but no sweep output is filed anywhere in the repo. FINDINGS X20: "queued on the PC". | Run it on the PC and file the result. This is the G1 exit bar. |
| A22 | Seed override exists (parity_main.gd:121) | PARTLY | Exists; line 110 at the pack, 167 now. | None. |
| A23 | Ranked list of 16 missing scenarios | TRUE BUT MOSTLY FIXED in 265d46d, 467ac6f, e83bae2 | Node golden run of all 31: boarding in 11 scenarios (19 board records, 7 captures), 37 rams, station batteries firing in s11, Commands in 25, nova 10, blink 8, the dead-star slingshot and rim in s19. Still thin: SOLID is non-null only in s19; no scenario produces a tidal death; no rift or shoals board (item 14); no scenario forces each section down or each ability on purpose (items 9-10 come only from the bot). | Optional: one forced tidal death and one rift or shoals board. The 200 sweep covers the rest. |

## 2. contrib/muse/reviews/sprint_b3_b4_review.md (Job B)

| # | Claim (short) | Verdict | Evidence | Next |
|---|---|---|---|---|
| B1 | Trigger beae728b, Oct 26 06:58 CDT, battle.js +2 -1, sim3d.js +28 -14 | TRUE | git show --stat beae728b: 30 insertions, 15 deletions across the two files. | None. |
| B2 | roundStart starts the enemy tick before the player tick is awaited, unlike ui3d.js nextRound, which awaits the player tick first and returns if the battle ended (top code defect) | FALSE | At beae728b, ui3d.js:592 nextRound is `const d1=startSideTurn('player'), d2=B.over?null:startSideTurn('enemy'); if(d1) await d1; if(d2) await d2;`, the same as sim3d.js:6 roundStart. Today the game calls roundStartBoth (battle.js:839), same order. The sim matches the game. | None. FINDINGS X20 already rejected it; keep it rejected. |
| B3 | Nothing sets B.fstat, so the FID definer counters are always 0 | TRUE BUT FIXED in df18598 and c7b1a78 | True at beae728b (0 matches in data.js, core.js, battle.js). df18598 (07:21, before the synthesis) added fstat writes; c7b1a78 added more. battle.js now writes charge, feed, revive, shots, syncShots, torpLaunch, torpHit, torpDodge, torpGone, braces. The pass 1 FID table shows non-zero values. The old 'sync' key had no writer; the current fidReport list dropped it. | None. |
| B4 | Balance numbers stale after B-19; no post-B-19 sims or FID output filed | TRUE BUT FIXED in 24d12ad | contrib/opus/compute/streamb/pass1_report.md: "Before = main at beae728", fmatrix 96, bossmatrix 96, FID table. | None. |
| B5 | Only band numbers on record are 57-89% at 96 runs (FINDINGS S6); 89 is 1 under 90 | TRUE | FINDINGS.md:130. | Still open: the band on HEAD needs pass 2 (c7b1a78 says the torpedo admirals fell out of band in pass 1 and were tuned). |
| B6 | Old battle.js:720 hid the stall check after //; new :721 runs it | TRUE | beae728b diff. | None. |
| B7 | "No change in the sim" for B-18 is inferred, not proven | TRUE BUT FIXED in c7b1a78 | contrib/opus/tools/b3_tests.js:108-109 adds the B-18 stall check ("16 ok" in the commit). | None. |
| B8 | Argon: the restored check may fire before Deathless reanimation (battle.js:702) or before death queues finish | FALSE | killUnit handles last stand, revive and reanimate first and returns early (battle.js:709-712 at beae728b). The restored check comes after the explosion (:721) and fires only when the battle epoch changed (liveFrom, battle.js:831), not on B.over. battle.js:702 at beae728b is inside killCauseOf; the "702" came from the older plan text. | Close the check. |
| B9 | Carriers decided: F22 DECIDED; Ashgrove is a Voidsworn carrier admiral starting with a reliquary | TRUE | FINDINGS.md:112; data.js:204 (start reliquary, harrow, warden), :64 (reliquary, voidsworn carrier), :531 (25% premium). | None. |
| B10 | One FID line with per-faction entries (sim3d.js:412) | TRUE | sim3d.js:412 at beae728b. | None. |
| B11 | B-19 touches sim, match, fuzz, bossCheck, bossMatrix, archMatrix, fMatrix, rsFight, chainSim | TRUE | All in the diff, plus campaignSim. | None. |
| B12 | FID wrappers are harness only and delegate to the originals | TRUE | applyHit, fireWeapon and startSideTurn wrappers in the beae728b diff only count. | None. |
| B13 | Plan B3 item 1 is carriers, item 5 is Deathless attrition; B4 order 2 then 3 then 4 | TRUE | go-forward-plan.md:388-396, 410-418. | None. |
| B14 | b2/ committed Oct 25 4:57 PM; trigger Oct 26 6:58 AM | TRUE | 3e5091c 16:57; beae728b 06:58. | None. |

## 3. contrib/muse/reviews/sprint_godot_shipping_review.md (Job C)

| # | Claim (short) | Verdict | Evidence | Next |
|---|---|---|---|---|
| C1 | godot/ holds only .gitignore, project.godot and rules/; main/, campaign/ and scenes/battle/ do not exist | PARTLY | True of the pack (9273632). Already false when filed (08:05): main/, scenes/, campaign/, fx/, render/, ui/, world/, audio/ were on main from 680c6ea (07:12). | The Part 3 re-check is due now, not "when main lands". |
| C2 | No [autoload] section | TRUE | Then and now. | None. |
| C3 | No [rendering] section (chair-confirmed) | PARTLY | True at 727edd6/9273632. On main at filing time (97bca4c) [rendering] existed, still without driver.windows. Now driver.windows="vulkan" and fallback_to_d3d12=true (1fbb4e6). | None. |
| C4 | 17 warnings silenced, integer_division=0 at line 20 | TRUE BUT FIXED in dd58851 | Pack project.godot:9-25, line 20 exact. dd58851 sets the six named warnings to 1. Rules files carry @warning_ignore_start for all 17 (rules.gd:11, jsm.gd:13, battle_api.gd:6). | None. |
| C5 | rules.gd is 117,728 bytes | TRUE | At 9273632. Now 193,468 bytes, 3,724 lines. | None. |
| C6 | Scenes reach rules only through battle_api.gd; recommend a lint so only battle_api.gd references rules.gd or jsm.gd | TRUE when written; now FALSE | scenes/battle/battle.gd:19 preloads rules.gd and keeps api.R ("read only", :54); main/campaign_host.gd:127-163 reads api.R.B; story/battle_voice.gd reads api.R; campaign.gd:16 and scenes/campaign/*.gd preload jsm.gd. | Open: either accept read-only R access as a recorded exception or add the lint. |
| C7 | view() could hand out live rules dictionaries | TRUE (risk), handled | battle_api.gd:86-101 builds new dicts per unit and duplicates sh, sec, map, obj, terrain. arena is a string. | None. |
| C8 | GodotSteam announced dropping MIT in 4.20 | TRUE | godotsteam.com/blog/category/licenses/ and the 2026-05-29 "dejavu for you" post: "In the upcoming GodotSteam 4.20 (hey-o), we will be dropping the MIT for another custom license similar to GodotSteamKit's." | None. |
| C9 | Shipped GDExtension is still MIT; Asset Library shows 4.23.2 with SDK 1.65 | TRUE | Asset Library edit pages (asset/edit/21728, /23695): current Version 4.23.2, License MIT, Steamworks SDK 1.65. The synthesis says the Asset Library gave no licence field; these pages do show one, which adds a source. The mirror license.md and the Codeberg pages could not be fetched here. | Keep the build-time glance at the bundled licence file. |
| C10 | GodotSteamKit is a separate paid closed product, not MIT | UNVERIFIABLE | The blog only says the new licence is "similar to GodotSteamKit's". Kit terms not fetched. | Irrelevant unless the Kit is adopted. |
| C11 | Upstream No LLM Policy | UNVERIFIABLE | Codeberg not reachable from this session. | Follow it anyway. |
| C12 | Steamworks SDK terms (partner account, may ship steam_api64.dll, may not ship headers) | UNVERIFIABLE | Not read (the synthesis says the same). | Read before the Steam build. |
| C13 | 8K RGBA8: 256 MiB, about 341 with mips; BPTC about 64 and 85 | TRUE | 8192 x 8192 x 4 = 268,435,456 bytes; x4/3 for mips; BC7 is 1 byte per pixel. | None. |
| C14 | High Quality uses BPTC (BC7 SDR, BC6H HDR); normal maps go RGTC | TRUE | ResourceImporterTexture class doc text. Done in 1e8fc9d: importer_defaults high_quality true, mode 2, normal_map 0 (Detect); build_assets.gd BC7 and BC5. | None. |
| C15 | High Quality only in Forward+ and Mobile, off in Compatibility | UNVERIFIABLE | Not in the doc text that could be read. | Check if the Compatibility path matters. |
| C16 | Shader baker since 4.5; bakes only for the configured driver | TRUE | pipeline_compilations doc: "Since Godot 4.5", and it "will only export shaders that match the rendering/rendering_device/driver project setting". Done: export_presets.cfg:28 with vulkan. | None. |
| C17 | Pipeline monitors Canvas, Mesh, Surface, Draw, Specialization; build a warmup | TRUE | Same doc. Warmup built: fx/API.md:25, scenes/battle/battle.gd:455 and :485 (d1b05eb). | None. |
| C18 | With no driver.windows set, Godot 4.6+/4.7 defaults to d3d12 on Windows | FALSE | The Godot commit that made d3d12 the default keeps vulkan as the setting's technical default; only projects created in 4.6 or later get d3d12 written into project.godot ("Projects created before Godot 4.6 keep vulkan for compatibility reasons"; 4.6 dev 5 notes: "only impact new projects"). A hand-written project.godot without the line runs Vulkan. Moot: 1fbb4e6 sets vulkan. FINDINGS X20 repeats the wrong premise. | None; the setting is right either way. |
| C19 | Ship a launch option forcing --rendering-method gl_compatibility | TRUE | Done: tools/pc/play_godot_safe.bat (1e8fc9d). | None. |
| C20 | Issues #122828 (4.7.2 Compatibility, NVIDIA 0x141) and #120409 (4.7 Forward+ crash on old Maxwell/Kepler) | UNVERIFIABLE | github.com not reachable; no copy found by search. | Low impact (target is RTX 5080, Vulkan). |
| C21 | Warning levels: 0 Ignore, 1 Warn, 2 Error | TRUE | Matches Godot and dd58851's =1. | None. |
| C22 | Steam Overlay may not hook under Vulkan from the editor | UNVERIFIABLE | Not checked. | Check at Steam integration. |

## 4. contrib/muse/reviews/sprint_decision_packs.md (Job D, factual claims only)

| # | Claim (short) | Verdict | Evidence | Next |
|---|---|---|---|---|
| D1 | Plan B5 is Option A first, then B | TRUE | go-forward-plan.md B5 section. | None. |
| D2 | Ryan approves the six faction outlines before B ships | TRUE | Plan B5 exit; godot/story/outlines.md has six arcs. | None. |
| D3 | Option C touches the save layer; effort (days, a week, weeks) is inferred | TRUE | career_story.md:34, 44, 52-54, all marked INFERRED. | None. |
| D4 | The Hall of the Fallen exists | TRUE | campaign_meta.js:120 'fallen' tab. | None. |
| D5 | Regrowth tide: every ship regrows 25% and rebuilds destroyed sections | TRUE | data.js:224 "regrows 25% of its hull and heals damaged sections, even destroyed ones". | None. |
| D6 | Matriarch's Command is Spawning surge (brood swarms) | TRUE | data.js:222. | None. |
| D7 | Voice v4 is final | TRUE | contrib/opus/evidence/syntheses_part2_and_drafts.md:51, 55. | None. |
| D8 | "15 unmade portraits": count not confirmed, legs split on whether it includes the Chorus trio | TRUE (count holds) | 24 admirals (data.js:201, 4 per faction; godot/portraits/README.md "all 24 admirals"); 9 painted in contrib/muse/design/IMAGE_MANIFEST.md:40-48, including Matriarch, Voice and Mending. 24 minus 9 = 15, so 15 does not include the Chorus trio. | Settled. |
| D9 | Poster cap means 6 paintings (fresh Mending plus 5 posters) | TRUE | 5 non-Chorus factions. | None. |
| D10 | Music album and track links | UNVERIFIABLE | Out of scope (not repo, data or licence facts). | None. |

## 5. contrib/muse/reviews/story_review_synthesis.md (facts section and claims about outlines.md and code)

The synthesis was filed (b8793f3, 13:24) after the outlines were revised (f51fcf8, 13:12), but its facts describe the old text as current. R45 notes this.

| # | Claim (short) | Verdict | Evidence | Next |
|---|---|---|---|---|
| S1 | 12 Beat 1 flags appear once each; six read in Beat 2 (vesper_hand, hg_offbook, cs_rigged, ch_silence, it_song, dd_patient), six never read (vesper_sold, hg_orders, cs_party, ch_ate, it_mercy, dd_vengeance) | TRUE BUT FIXED in f51fcf8 | Old: flags at lines 25-26, 55-56, 85-86, 115-116, 145-146, 175-176; Beat 2 brackets at 30, 60, 94, 120, 150, 180 cover exactly those six. New: every Beat 1 choice gets a Beat 2 bracket (new 45, 90, 135, 180, 225, 270). | None. |
| S2 | Beat 3 rewards: three identical repair 20 vs experience 20 (Voidsworn, Hegemony reversed, Deathless); Chorus regrow vs weakness; Ithar experience vs weakness; Corsair experience vs credits | TRUE BUT FIXED in f51fcf8 | Old lines 40-41, 70-71, 100-101, 130-131, 160-161, 190-191, exact. New Beat 3s are costed story choices plus a blue (new 60-64, 105-109, 150-154, 195-199, 240-244, 283-287). | None. |
| S3 | Chorus header says "short lines" (line 109) but body sentences are long | TRUE BUT FIXED in f51fcf8 | Old line 109. New header: "sentences under eight words" (new 165); bodies rewritten. | None. |
| S4 | Deathless crest "crowned eye over a closed tomb door" (line 169); sample rival "Dynast Setekh the Patient" (line 53); fix 3: rename Setekh | PARTLY | Old lines 169 and 53 exact. The outlines now use tokens, no sample names; crest is "a sealed vault door" (new 255). But "Setekh" is still in the enemy captain name pool, data.js:520 (CAPTAINS deathless names, with ranks Dynast, Cryptlord, Overlord and "of the Ninth Tomb"), and in godot/story/test/story_test.gd:242-249 and career_shots.gd:42. | Open: rename it in data.js CAPTAINS (with the R44 rename map) and in the two test files. |
| S5 | Two sample rivals are women while the text hardcodes "his" ("learns his scent", "He offers to return it") | TRUE BUT FIXED in f51fcf8 | Old 113, 116, 173, 180. New pronoun tokens; tokens.gd:28-41 gives he, she or it. | None. |
| S6 | Rival deeds assume a humanoid in three scenes (auction front row, crown worn, altar message); "the Chorus text says the swarm does not answer in words" | PARTLY | Three scenes true (old 23, 90, 180). The "does not answer in words" line (old 128) is about the player's own Chorus swarm, and the old rival table gives a Chorus rival spoken lines (old 206), so it is weak support. New: a deed slot by faction and personality with "It" deeds for the Chorus (new 296-307); the auction rival now waits off the rock (new 135). | None. |
| S7 | No Beat 2 choice has a named flag | TRUE BUT FIXED in f51fcf8 (one gap) | Old: none. New: every Beat 2 option has a flag except Chorus "Dive and eat" (new 182). | Add a flag to Chorus "Dive and eat". |
| S8 | Hegemony Beat 2 is the consensus best beat (all four) | TRUE | DeepSeek raw:61, Argon:85, Qwen raw:69, Rey:61. | None. |
| S9 | Chorus Beat 1 and Deathless Beat 2 are each strongest for three of four | TRUE | Chorus B1: DeepSeek:77, Qwen:79, Rey:77 (Argon picked B2). Deathless B2: Argon:117, Qwen:89, Rey:93 (DeepSeek picked B1). | None. |
| S10 | Voidsworn, Corsair and Ithar picks scatter across beats 1 to 3 | PARTLY | Voidsworn scatters (B1, B2, B3, B2). Corsair splits B1/B2 only. Ithar is three of four for Beat 2, "The Glass Choir" (DeepSeek:85, Argon:109, Rey:85; Qwen B3): as strong a consensus as S9. | Treat Ithar Beat 2 as a consensus strong beat. |
| S11 | DeepSeek calls Beat 3 the weakest in all six | TRUE | DeepSeek raw:55, 63, 71, 79, 87, 95, 105. | None. |
| S12 | The rival's hail, last words and gloat are fixed per faction | TRUE BUT FIXED in f51fcf8 | Old table 201-208. New Table B: remembers, mercy, ruthless (new 309-320) plus rival_lines.json pools. | See note N1 below. |
| S13 | Beat 2 blues stack the standard rewards without their costs | TRUE BUT FIXED in f51fcf8 | Old 34, 64, 94, 124, 154, 184. New blues carry costs (new 51, 96, 141, 186-188, 231, 276). | None. |
| S14 | 40k density: Deathless (tomb, crown, warden, long sleep) and Crusade (heresy, confessors, litanists, shrine-moon) | PARTLY FIXED in f51fcf8 | Word counts old to new: tomb 11 to 1, crown 12 to 4, dynast 10 to 1, heresy 1 to 0, shrine 1 to 0, Warlord 2 to 0. Crusade not thinned: confess 5 to 4, litanist 3 to 5. Ithar "elders" 3 to 5. | Crusade pass still open if Ryan wants it. |
| S15 | Open: can a Chorus admiral roll as the Nemesis? | Answered: yes | campaign_run.js:246 picks from RUN_FACTIONS minus the player's faction (core.js:241 includes chorus); NEM_FAC has a chorus entry (data.js:457 onward). Fix 7 was required; f51fcf8 did it. | None. |
| S16 | Open: does anything follow Beat 3 in a run? | Answered: yes | Beat 3 shows when sector III begins (godot/story/README.md:125). The sector III map (battle, elite, event, shipyard, drydock, boss nodes) and the Nemesis node (campaign_run.js:264) follow, so old Corsair credits were not dead weight. New Corsair Beat 3 spends credits at once anyway (new 152). | None. |
| S17 | Fix 9: the Chronicle should record the run's flags | TRUE BUT FIXED (partly) | New cross-run callbacks (new 322-327); career code records the arc's choices (career_shots.gd:42 record_arc_end with choices per beat). | None. |

N1, found while checking S12 and fix 7 (not a claim in the syntheses, but it breaks what f51fcf8 promises). The story layer reads the Nemesis's "personality" (godot/story/rival.gd:89, :129). Stream B stores it as "persona" (campaign_run.js:248), and story.gd:140/:260 and battle_voice.gd:34 pass run.nem through unchanged. So in the live game the personality never reaches the deed or the hail pick: the deed falls back to a hash of the name (rival.gd:90-93), and personality lines never show. The ids do not line up either. Stream B rolls cunning, greedy, proud, cruel, patient, methodical, ravenous, zealous (NEM_FAC personas). Outlines Table A and rival_lines.json use proud, cruel, cunning, zealous, cold, mocking. So cold and mocking never roll, and greedy, patient, methodical and ravenous have no deed column.

## Claims that are FALSE

1. A14: the shape list "at rules.gd:366" mixes maps (belt, station, planet, storm, graveyard) into shapes and leaves out lanes, ring and dense.
2. A18: the "battle.js is 401 lines, the pack's sort lines are wrong" discrepancy. battle.js was 1,155 lines and the pack's lines were right; DeepSeek's were wrong.
3. B2: the roundStart "top code defect". The sim's order matches the game's nextRound exactly.
4. B8: the B-18 vs reanimation ordering worry. Reanimation runs first and returns early, and the check only fires on a changed battle epoch.
5. C18: "no driver.windows means d3d12 on 4.6+". The technical default is still vulkan; only new projects get d3d12 written. Moot, since vulkan is now set.
6. C6 is now false (it was true when written): scenes and the story layer read rules.gd state directly.

## Still open and important

1. A21: no 200-battle parity sweep result is filed. This is the G1 exit bar; the tools exist and the sweep is queued on the PC.
2. B5: the admiral 50-90% band on current code is unmeasured until stream B pass 2 is filed.
3. N1: the Nemesis personality never reaches the story layer ("persona" vs "personality"), and the two personality id lists do not match.
4. S4: "Setekh" is still a Deathless captain name in data.js:520 (CAPTAINS) and in two story test files; the R45 rename only touched the outlines.
5. C6: the rules boundary (only battle_api.gd touches rules.gd and jsm.gd) is not followed by battle.gd, campaign_host.gd, battle_voice.gd or the campaign scripts. Decide: accepted exception or lint.
6. Smaller: A13 tables export has no fail-hard; A23 has no golden scenario with a tidal death or a rift or shoals board; S7 Chorus "Dive and eat" has no flag; S14 Crusade vocabulary not thinned.
