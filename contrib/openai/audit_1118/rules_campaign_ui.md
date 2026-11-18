# Code audit C: rules, campaign and screens

Main reviewed: `dfbb5ef6f3cd4922e2eb97a283357118582de513`. The resumed checkout's seven scoped folders match that tree. I kept the earlier probe and extended it. I ranked lost runs and wrong battle results first, then lost rewards, misleading screens and sound.

## Top ten

1. Closing the game in a story-boosted fight can skip the fight or leave no way forward.
2. A failed breakthrough can end the whole run even though a ship already jumped clear.
3. The game can ignore a good backup or offer Continue when there is no run to continue.
4. Standard difficulty changes how enemies act but still builds the Veteran fleet; the map also uses Veteran.
5. A save made between paying a boss reward and leaving the sector can strand the run at the boss.
6. The Hegemony Nemesis can miss the round-three reinforcements the game promises.
7. Returning to a saved run after confirming a captured ship can skip wreck salvage and the next prize.
8. Using doctrine from the shipyard fleet screen can throw you out of the yard before you finish shopping.
9. A failed Career save can leave the previous good backup exposed to the next write.
10. A victory or defeat fanfare can outlive the screen that started it. The overlap is clear in code; how often it is heard is unverified.

## Confirmed findings

| # | What goes wrong | Evidence and how to show it | Fix and size |
|---|---|---|---|
| 1 | **The story boost consumes the pre-fight checkpoint.** The saved fleet is now at an unfinished fight and the one-use effect is gone. Continue shows only routes out of that fight; if it was the sector boss, there are no routes. | **OBSERVED, high.** `godot/campaign/campaign.gd:3281`: `RUN["storyNext"] = null; saveRun()`. `ACT_enterNode` sets `pos` and `curNode` first (1719); `saveRun` clones them (1280-1282). `ACT_continueRun` only opens map or rewards (1414-1417); `availableNodes` follows outgoing edges (1283-1292). Probe below reopens an actual Sector III fight checkpoint and finds the node unfinished but unreachable. `campaign3d.js:75-77` has the same premature save. `godot/campaign/test/story_beat3_test.gd:83-101` checks effect retention before entry and removal after entry, but never tries to reach the real entered node after reload. | Keep the playable pre-fight checkpoint until the outcome is written, or save an explicit retry for the current node and its modifiers. Repair old saves that point at an unfinished fight; distinguish a battle retry from an already-paid reward. **2 agent runs.** |
| 2 | **A ship already through the exit does not prevent campaign defeat.** With three ships, send one through, then lose the other two. That leaves a valid survivor and a forced withdrawal in the rules, but Godot pays a run loss and removes Continue. | **OBSERVED, high.** `godot/campaign/campaign.gd:3339`: `not jt(u.get("dead")) and not jt(u.get("isSq"))`. `godot/rules/rules.gd:3769-3771` sets `exited`, `dead` and `fled` together; `survivorsP` at 3733-3737 counts exited ships. The browser consumes that count at `campaign3d.js:89`. The probe gets `withdraw=true` and one survivor before `finish_battle`, then gets `page=end`. Godot's battle end card also falls back to Defeat for every raw loss (`godot/scenes/battle/battle.gd:2289-2323`); Story uses the raw `over` value (`godot/story/story.gd:101-104`). Battle parity stops at the rules result; stub campaign parity never builds this end state. | Resolve the withdrawal against the shared survivor predicate and pass one settled outcome to campaign, HUD and Career. Keep this probe as a cross-boundary check, including what the end card calls it. **1 agent run.** |
| 3 | **Backup recovery and Continue disagree with what is on disk.** A missing or zero-byte primary ignores a sound backup. Separately, a valid profile-only primary after a completed run still makes the real title show Continue; that click is dispatched even when there is no saved run. | **OBSERVED, high.** `godot/campaign/campaign.gd:448`: `if s != "" and not saneSave(o):`. `persist_load` uses an empty string for missing files (463-466). `godot/main/campaign_host.gd:104-105` only tests file existence; `godot/main/title.gd:129-131` offers Continue based on that answer. The host dispatches it at `godot/main/campaign_host.gd:74-76`, then `ACT_continueRun` calls `mapScreen` with a null run, which indexes `RUN["map"]` at `godot/campaign/campaign.gd:1695`. The probe makes a real save string, passes it as the backup, and sees renown reset to zero. `godot/campaign/test/save_test.gd:20-23` covers a nonempty malformed primary only. | Resolve the viable save once for both the title and the host, including backup-only and profile-only states. Keep the existing save format and fall through safely if no playable run is left. **1 agent run.** |
| 4 | **Standard difficulty still generates a Veteran campaign fleet.** The fleet size budget has already been spent when the battle scene applies the difficulty. The briefing, map and route estimates also start with an unwired Veteran setting. | **OBSERVED, high.** `godot/rules/rules.gd:1385`: `if AI_LEVEL == "standard": budget *= RAMP.std`. The default is Veteran (35), and fleet generation happens in `startBattle` (1221). The live host calls `new_battle` first (`godot/main/campaign_host.gd:127-133`), then the scene is configured and begins (`godot/main/main.gd:204-214,375-390`); only there is the selected level applied (`godot/scenes/battle/battle.gd:515-516`). `godot/ui/campaign/campaign_ui.gd:59,742-752` and `godot/ui/campaign/map3d.gd:164` feed the estimates from the UI default. Compare this with `battle.js:170`, where the active browser setting is read during fleet generation. Godot scenario fixtures can set AI before setup (`godot/rules/battle_api.gd:106`), so they do not cover the host order. | Give battle setup and map intel the same current difficulty, before any fleet roll. Cover the real Standard and Veteran launch paths at the same seed and assert the map estimate receives the selected level. **1 agent run.** |
| 5 | **There is a bad save between a boss payout and sector advancement.** The previous map is still current, but the boss is done and the reward is gone. If the second write is never reached or fails, reload cannot complete the boss again or use its nonexistent outgoing route. This is a write interruption case, not the normal uninterrupted boss path. | **OBSERVED, high.** `godot/campaign/campaign.gd:3181-3182`: `RUN["reward"] = null` then `completeNode()`. `completeNode` saves immediately (1684-1687), before the next map or final result is written (3183-3192). `genSector` puts the boss in the last column (947-956); `ACT_continueRun` only resumes a non-null reward (1414-1417). Exact path: finish the final reward click, load the first persisted snapshot rather than the later one, and inspect `pos`, `reward` and `availableNodes()`. `campaign_run.js:726-733` writes the same intermediate snapshot. Parity reloads between actions, not between these writes. | Commit the full next-sector or end state once, or retain a pending transition in every intermediate save. Recognize the old terminal boss snapshot on Continue and finish the transition without another payout. **2 agent runs.** |
| 6 | **The real Hegemony Nemesis encounter does not force reinforcements.** An otherwise valid meeting can have no event, an unrelated one, or reinforcements on another round. The briefing still warns about round three. | **OBSERVED, high.** `godot/rules/battle_api.gd:188`: `R.B["event"] = R.rollBattleEvent(cfg, force)`. The live path from `godot/campaign/campaign.gd:1723-1726,3304-3309` sends war context only. The guaranteed event is in the stub-only branch (3283-3290); the warning is at 2233. The real event fires from `godot/rules/rules.gd:561-581`; the browser sets the forced round at `campaign3d.js:76`. Probe uses external setup and sees a null event. The rules golden uses a separate setup expression for war and `event_force` (`godot/rules/test/node/golden.js:168`), and does not model the campaign's Nemesis precedence. | Resolve the documented Nemesis override in the real event setup before the war roll, retaining normal teaching and boss exclusions where applicable. Check both neutral and war sectors on the same campaign path, preserving draw order. **1 agent run.** |
| 7 | **The save records the prize as paid but leaves the stage at prize.** When entering salvage after confirming a prize, reopening can silently drop the salvage and the pending boon or refit. You do not get the prize twice; the later choices are skipped. | **OBSERVED, high.** `godot/campaign/campaign.gd:3015`: `R["prizes"] = []; R["prizeSel"] = null; saveRun()`. `ACT_prizeStep` changes stage afterward (2975-2983); `ACT_salvageStep` does not save (3019-3028). `resumeReward` only dispatches the prize stage if there are prizes, then falls through to promotions (3170-3178). The probe observes salvage before reload, no modal afterward. `campaign_run.js:653-659,721-725` has the same sequence, so matching snapshots in parity do not establish correctness. | Save the paid prize and next stage together. Route old `prize` saves with an empty prize list to their remaining wrecks or ordinary reward. **1 agent run.** |
| 8 | **Using doctrine from a yard's fleet view discards the return to the yard.** The purchase is made but neither the yard nor its Leave action remains reachable. The shop node stays unfinished while the map offers only its successors. | **OBSERVED, high.** `godot/ui/campaign/fleet_manifest.gd:288`: `C.act("factionVerb", "")`. In campaign, `yardFleet` opens the fleet with a shipyard return (`godot/campaign/campaign.gd:1371-1374`), but `ACT_factionVerb` always opens the map (2622-2625); the same view's normal Done would use `backShipyard` (`godot/ui/campaign/fleet_manifest.gd:290-291`). The probe takes that route after a real Sector II yard arrival and sees `page=map`. The browser's doctrine action was on the map, so stub parity does not exercise this Godot screen route. | Keep the spent doctrine on the caller's fleet screen with the same return route, or explicitly return to its yard. Check both the yard and map entrances with the same purchase. **1 agent run.** |
| 9 | **Career can overwrite the last good copy with a damaged primary.** A failed write can leave the primary truncated. The loader can fall back once, but a later save unconditionally backs up the damaged file before trying the primary write, exposing both copies to a second failed write. | **OBSERVED, high for the write path.** `godot/story/career.gd:186`: `var f := FileAccess.open(save_path, FileAccess.WRITE)`. `load_profile` tries both copies (155-166); `save_profile` copies the primary without validation (184-185), truncates it and ignores the write result (186-188). Exact path: interrupt a save after the open, restart from the good backup, then interrupt the next write after the copy. `record_battle` and `record_run_end` both use this writer (318,449), so the Career history, medals and titles are affected. | Write through a checked temporary file and rotate only a validated primary. Keep the same schema and test recovery after two interrupted writes in an isolated folder. **1 agent run.** |

## Suspected finding

**10. An old fanfare can play over the start of a new scene (INFERRED, medium).**
`godot/music/music_player.gd:311`: `_sting.play()`. The persistent player starts a battle sting from
`godot/scenes/battle/battle.gd:2292-2297`. `play_battle` (214-241), `play_title` via `_play_single` (174-203), and
`stop` (318-321) never stop or fade `_sting`; `_process` only fades or stops the other players (326-351). Thus the old
track can run under new music until natural completion. A slow transition can mask the overlap, and a sting can reasonably
carry into the reward screen. The useful check is a fast exit to title or a fast start of a different battle during a long
fanfare. If audible, give stings an explicit hand-off on title or new battle while allowing the reward screen to keep its
outro. **1 agent run.**

## Frame-cost suspects

- **unmeasured guess:** `godot/ui/campaign/map3d.gd:881-885,1280-1298` rebuilds the wake surfaces while the wake is live and schedules an overlay redraw every visible map frame. Check the cost on a jump and immediately after arrival.
- **unmeasured guess:** `godot/rules/battle_api.gd:215-231,602-650` copies the battle's UI view and separately computes threat by ship, reachable state and hex. The threat pass is cached by version; measure cache misses on a large fleet before changing anything.
- **unmeasured guess:** `godot/portraits/portraits.gd:125-177` holds a full composed texture for each scar ordering until the static cache is cleared. Measure memory across multiple campaigns before deciding whether to limit that cache.

## Reproduction and impact sweep

Run from the repo root with the Godot 4.7.2 console executable (shown as `godot`):

```sh
godot --headless --path godot --script ../contrib/openai/audit_1118/tests/rules_campaign_ui/handoff_regressions.gd
```

```text
FAIL: unfinished story fight remains playable with its reward after reload (page=map, node_done=false, node_reachable=false)
FAIL: failed breakthrough returns the ship that already jumped clear (page=end)
FAIL: Hegemony Nemesis always calls enemy reinforcements in round 3 (event=<null>)
FAIL: an empty or missing primary save recovers the backup run and profile (renown=0)
FAIL: reopening during salvage resumes salvage after the paid prize (modal=none)
FAIL: using doctrine from the yard fleet keeps a way back to the yard (page=map)
```

The probe exits 1 on main, as intended; it uses the real tables, rules and campaign save encoder in memory. The prize
and breakthrough probes set up the tactical outcome directly and then use the real result and reward handlers. The other
single checks were:

- `godot --headless --path godot --script res://campaign/test/core_eat_test.gd`: `core eat: PASS`.
- `godot --headless --path godot --script res://campaign/test/heat_test.gd`: `PASS: Heat opens after the first loss and pays 2 XP per point to the flown line and 1 to the shadow pool.` This includes a pre-Heat-gate profile loaded from save text.
- `node contrib/opus/tools/free_exit_tests.js <temp fixture>`: `PASS: 32 free exits across moon, tomb, haven, every eligible faction, zero and 120 credits, return to map and save.`
- `godot --headless --path godot --script res://campaign/test/free_exit_test.gd -- <temp fixture>`: `PASS: 32 free exits match the live browser at entry, result and sector map.` The first invocation lacked the fixture argument and exited 1 with `Expected the browser fixture JSON path`; the fixture-backed run passed.
- Scoped byte, JSON, fixture and file-header check: `PASS: 1183 tracked files accounted for; no parse or header failures.`
- Scoped catalog reference check: `PASS: 524 audio, music and portrait catalog references; all referenced files exist`.

Impact sweep:

- **Callers:** Searched repo-wide for the save, setup, outcome, reward, doctrine and music entry points; the live callers and the distinct stub and scenario paths are cited above. Only the audit probe changed.
- **Saves:** Checked the existing format through real in-memory save text and Continue, including backup-only and post-prize states. The existing pre-Heat-gate fixture still loads and unlocks Heat. The audit adds no save field and never opens a player's profile.
- **Twins:** Compared the live campaign hand-offs with `core.js`, `battle.js`, `campaign_run.js` and `campaign3d.js`. Some checkpoint bugs are shared, while withdrawal, live AI setup and Hegemony scheduling diverge. No rule or table edits or exports.
- **UI:** Traced the actual title, map and intel, reward modals, fleet and yard return, result HUD and Career readers. No game screen changed.
- **CI:** `.github/workflows/checks.yml` runs standing checks, rules and campaign parity, the Godot-only rules safety net, and Godot game checks from `godot/tools/ci/godot_checks.txt`. The intentionally red audit probe is manual under this issue's deliverable-only scope; it is not on the standing or Godot check list.

**Recommended next step:** File the story checkpoint and battle withdrawal fixes first. Require each fix to pass through the real campaign hand-off; matching just the browser rules snapshot did not catch either failure.

## Scope ledger

The ledger uses local raw checkout files from the pinned main tree. Plain-text rows are `file lines "first 40 characters of last line"` under the directory heading. `\t` and `\uXXXX` escape characters. The last newline does not count as another line. The inventory includes 210 text files (57,313 lines), 292 packed reference fixtures (375,594 decoded lines), and 681 binary assets. It separates file-read coverage from the runtime paths actually exercised.

Large-file scan ranges (inclusive; generated data and records were scanned in full by the inventory check):

- `godot/rules/rules.gd`: 1-459 (table, JS and ship helpers), 460-1098 (board), 1099-1553 (setup), 1554-2397 (movement, faction and round flow), 2398-3928 (combat and objectives), 3929-4819 (orders and tree helpers), 4820-6185 (tree dispatch and abilities), 6186-6839 (AI).
- `godot/campaign/campaign.gd`: 1-467 (state and saves), 468-1214 (fleet, map and progression), 1215-1682 (run and dispatcher), 1683-1992 (map, fleet and yards), 1993-2570 (Nemesis), 2571-2880 (actions and story), 2881-3198 (rewards), 3199-3530 (battle hand-off and stub).
- `godot/ui/campaign/campaign_ui.gd`: 1-469 (widgets and rendering), 470-741 (title, setup and map helpers), 742-1230 (map and intel), 1231-1600 (fleet, yard and progression), 1601-2021 (debrief, modals and input).
- `godot/ui/campaign/map3d.gd`: 1-205 (setup and loads), 206-674 (sector geometry and token), 675-930 (refresh and camera), 931-1298 (overlay and input).
- `godot/audio/cues.json`: 1-2143; `godot/rules/test/scenarios.json`: 1-9091; `godot/rules/test/saved/results.json`: 1-2036. Both compact exported tables are complete on line 1.

### Text files

```text
[godot/audio]
README.md 100 "functional verification; listening and a"
SFX_CREDITS.md 101 "| uiRound | Kenney Impact Sounds; Kenney"
cues.json 2143 "}"
death_audio.gd 104 "\t\tsfx.death_beat(false)"
sfx.gd 565 "\tcreate_tween().tween_property(_amb, \"vo"
[godot/audio/build]
bake_sound_weight.gd 122 "\tawait create_timer(0.2).timeout"
render_ambient_bed.py 82 "print(\"wrote\", out, os.path.getsize(out)"
render_synth.js 60 "})();"
[godot/audio/clips]
index.json 316 "}"
[godot/audio/test]
audio_check.gd 236 "\tquit(0 if fails.is_empty() else 1)"
salvo_check.gd 88 "\tquit(0 if fails.is_empty() else 1)"
smoke_lifetime_check.gd 58 "\tquit(0 if errors == 0 else 1)"
sound_weight_check.gd 208 "\t\t_ok(false, shot + \" charge and shot bo"
[godot/campaign]
.gitignore 1 "*.uid"
README.md 85 "What the harness leaves out, on both sid"
campaign.gd 3530 "\t\t\"events\": tel_log.slice(max(0, tel_log"
campaign_view.gd 410 "\treturn \"\""
[godot/campaign/data]
campaign_tables.json 1 "{\"sha256\":\"e782ca30a4c9489c3a4acf96f8ee6"
[godot/campaign/test]
.gitignore 3 "parity_campaign_log.txt"
README.md 40 "- **Real battles**: both sides use the s"
RECORD.md 121 "The screens live in `godot/ui/campaign/`"
arc_hook_test.gd 94 "\tquit(1 if fails > 0 else 0)"
boon_fleet_test.gd 248 "\tquit(1 if fails > 0 else 0)"
capstone_mastery_shots.gd 76 "\tPG.finish(0)"
capstone_mastery_test.gd 77 "\tquit(0 if failures == 0 else 1)"
cinder_prizes_test.gd 141 "\tquit(1 if fails > 0 else 0)"
core_eat_test.gd 114 "\tquit(0 if fails == 0 else 1)"
core_sync_test.gd 63 "\tquit(0 if failures == 0 else 1)"
debrief_mock_shots.gd 232 "\treturn cc"
free_exit_test.gd 55 "\tquit()"
heat_test.gd 78 "\tquit(0 if failures == 0 else 1)"
heat_ui_shots.gd 69 "\tPG.finish(0)"
inheritance_test.gd 38 "\tquit(0 if failures == 0 else 1)"
lineage_test.gd 92 "\tquit(0 if failures == 0 else 1)"
map_approach_shots.gd 114 "func _initialize(): root.add_child.call_"
map_load_cancel_test.gd 93 "\t\tprinterr(\"FAIL: \", message)"
map_readonly_test.gd 280 "\tquit(0 if fails == 0 else 1)"
map_region_shots.gd 123 "func _initialize(): root.add_child.call_"
map_travel_test.gd 205 "\tquit(0 if failures == 0 else 1)"
nem_panel_shots.gd 105 "\tPG.finish(0)"
nem_read_test.gd 91 "\tquit(0 if fails == 0 else 1)"
nem_scenarios.gd 218 "\trec(\"ah3\", C.nemClockAdd(1)); rec(\"ah4\""
nemesis_clash_test.gd 35 "\tquit()"
nemesis_teach_shots.gd 90 "\tPG.finish(0)"
nemesis_teach_test.gd 45 "\tquit(0 if failures == 0 else 1)"
onboarding_test.gd 175 "\tquit(0 if fails == 0 else 1)"
onboarding_visual.gd 69 "\tquit(0 if checks == 0 and errors.n == 0"
parity_campaign.gd 148 "\tlines.append(JSON.stringify({\"i\": 4001,"
playtest_switch_test.gd 21 "\tquit(0 if bad.is_empty() else 1)"
r1_ui_shots.gd 60 "\tPG.finish(0)"
run_nem_scenarios.sh 16 "grep -E \"^Map read-only: PASS\" out/map_r"
run_parity_campaign.sh 29 "if [ $F -eq 0 ]; then echo \"PASS: the Go"
save_test.gd 25 "\tquit(1 if fails > 0 else 0)"
shadow_xp_test.gd 48 "\tquit(0 if failures == 0 else 1)"
story_beat3_test.gd 203 "\tquit(0 if fails == 0 else 1)"
tree_handoff_test.gd 102 "\tquit(0 if failures == 0 else 1)"
[godot/campaign/test/node]
compare_campaign.js 34 "console.log('PASS: ' + ga.length + ' ste"
coverage.js 15 "console.log(Object.keys(acts).sort().map"
cross_twin_handoff_test.js 83 "process.exitCode = main();"
env.js 51 "module.exports = { load, ORACLE, FILES }"
export_campaign.js 48 "console.log('  code fields left out (car"
golden_campaign.js 125 "if (n < 0) process.exit(1);"
nem_assign_enum.js 79 "process.exit(fails ? 1 : 0);"
nem_scenarios.js 171 "console.log(__OUT.length + ' records');"
[godot/music]
CREDITS.md 322 "The Deathless mix is CC0 and so are all "
README.md 63 "A battle starts the calm layer and the i"
music.json 556 "}"
music_player.gd 365 "\t\t\"bed_db\": _bed.volume_db, \"single\": _s"
[godot/music/test]
music_check.gd 104 "\tquit(0 if fails.is_empty() else 1)"
[godot/portraits]
README.md 95 "- **Jobs on lane A:** `r8a`, `r8b` (fres"
index.json 1279 "}"
portraits.gd 356 "\t_rfac.clear()"
[godot/portraits/crests]
aelith.svg 32 "</svg>"
anuket.svg 29 "</svg>"
ashgrove.svg 32 "</svg>"
faction_chorus.svg 16 "</svg>"
faction_corsair.svg 30 "</svg>"
faction_deathless.svg 8 "</svg>"
faction_hegemony.svg 16 "</svg>"
faction_ithar.svg 15 "</svg>"
faction_voidsworn.svg 16 "</svg>"
grax.svg 29 "</svg>"
index.json 122 "}"
kassar.svg 31 "</svg>"
khepra.svg 29 "</svg>"
malek.svg 29 "</svg>"
maren.svg 28 "</svg>"
matriarch.svg 32 "</svg>"
mending.svg 32 "</svg>"
mirelle.svg 29 "</svg>"
mott.svg 32 "</svg>"
nekhet.svg 32 "</svg>"
razormaw.svg 29 "</svg>"
reyes.svg 31 "</svg>"
sable.svg 29 "</svg>"
sekhmar.svg 32 "</svg>"
thale.svg 29 "</svg>"
thorne.svg 29 "</svg>"
vaelen.svg 32 "</svg>"
vesh.svg 32 "</svg>"
vex.svg 32 "</svg>"
voice.svg 32 "</svg>"
vorn.svg 28 "</svg>"
[godot/portraits/nemesis/scars]
scars.json 62 "}"
[godot/portraits/test]
campaign_face_check.gd 108 "\treturn n"
portraits_check.gd 108 "\treturn n"
[godot/rules]
API.md 193 "- **Maths:** sin, cos, atan2, exp, hypot"
battle_api.gd 1001 "\treturn why"
jsm.gd 654 "\treturn s if i < 0 else s.substr(0, i) +"
rules.gd 6839 "\tB[\"aiActive\"] = null; u[\"activated\"] = "
[godot/rules/data]
tables.json 1 "{\"sha256\":\"1dc071ae97d18988acb09f165a488"
[godot/rules/test]
.gitignore 3 "parity_log.txt"
README.md 132 "  - `tr` is taken by `Object.tr`."
api_smoke.gd 34 "\tquit(0 if api.R.not_ported == \"\" else 3"
effect_caps_test.gd 31 "\tquit(1 if bad > 0 else 0)"
parity_main.gd 208 "\treturn 0"
run_parity.sh 4 "exec node \"$(dirname \"$0\")/node/run_pari"
run_sweep.sh 11 "node node/sweep_check.js out/sweep.json "
scenarios.json 9091 "}"
shield_pool_test.gd 52 "\tquit(1 if bad > 0 else 0)"
thread_test.gd 92 "\tquit(0 if bad == 0 else 1)"
tree_prompt_test.gd 66 "\tquit(0 if fails == 0 else 1)"
[godot/rules/test/node]
campaign_hooks.js 3 "function nemAdaptName(a,fac){ const T=NE"
compare.js 43 "console.log('PASS');"
export_data.js 56 "console.log('exported', Object.keys(out)"
fnames.js 6 "  deathless:['Long Noon','The Unbroken',"
golden.js 262 "})().catch(e => { console.error(e); proc"
run_parity.js 193 "if (require.main === module) run().then("
summary.js 16 "console.log('  ' + Object.entries(seen)."
sweep_check.js 15 "console.log(bad ? 'FAIL' : 'PASS'); proc"
sweep_gen.js 47 "fs.writeFileSync(out, JSON.stringify(res"
timing.js 15 "if (G.n) console.log(`    Godot peaked a"
[godot/rules/test/safety]
README.md 220 "time here from that run, including setup"
ruled_numbers_test.gd 48 "\tquit(1 if bad else 0)"
run_cache_check.js 182 "main().catch(e => { console.error('FAIL:"
run_cache_check.sh 6 "exec node \"$HERE/run_cache_check.js\" \"$@"
[godot/rules/test/saved]
README.md 128 "This upload is for access to the files; "
changes.txt 394 "FAIL: saved Godot results; 284 battles c"
check.js 78 "})().catch(e => { console.error('FAIL: s"
pilot.js 163 "main().catch(e => { console.error('FAIL:"
records.js 144 "module.exports = { HOME, SCENARIOS, FILE"
results.json 2036 "}"
self_test.js 121 "console.log(`PASS: saved results self-te"
update.js 45 "}"
[godot/story]
.gitignore 1 "*.uid"
README.md 136 "`story_test.gd`: data complete (24 admir"
arc.gd 171 "\treturn segments(A.get(\"win\" if won else"
battle_voice.gd 204 "\treturn \"%s: \\\"%s\\\"\" % [admiral_name(), "
career.gd 450 "\treturn row"
outlines.md 345 "Checked by `godot/story/test/check_outli"
outlines_variants.md 257 "Incident 8's \"that captain\" effects need"
review_incorporation.md 110 "godot/story/outlines.md (REVISED round 3"
rival.gd 175 "\treturn line(\"hail\", nem, seed, ctx)"
story.gd 370 "\treturn s"
tokens.gd 98 "\treturn t"
unlocks.md 32 "The cosmetic rewards need nothing from s"
[godot/story/data]
arcs.json 129 "}"
medals.json 17 "}"
rival_lines.json 493 "}"
titles.json 31 "}"
voices.json 416 "}"
[godot/story/test]
career_shots.gd 85 "\t\tpass"
check_outlines.py 65 "sys.exit(1 if bad else 0)"
check_personas.py 24 "sys.exit(1 if bad else 0)"
fixture_arc.json 36 "}"
story_test.gd 459 "\tok(battles_seen > 0 and recorded_runs ="
[godot/ui/battle]
brand.gd 91 "\treturn false"
hud.gd 1393 "\tledger.mark()"
keel_shots.gd 189 "\tGuard.finish(1)"
ledger.gd 952 "\t\t\t\tact.emit(h.act, h.arg)"
ui_shots.gd 327 "\tb._quit_report()"
[godot/ui/battle/fonts]
OFL_Barlow.txt 93 "OTHER DEALINGS IN THE FONT SOFTWARE."
[godot/ui/battle/icons]
keel_icons.gd 79 "\t\t_: return \"command\""
make_silhouettes.gd 168 "\t\t\tdraw_string(GS.sheet_body(), cell + V"
[godot/ui/battle/test]
battle_log_cap_test.gd 67 "\tquit(1 if fails > 0 else 0)"
ledger_readability_test.gd 467 "\treturn e"
[godot/ui/campaign]
.gitignore 1 "*.uid"
campaign_tips.gd 160 "\tif is_off(): _dismiss(\"off\", false)"
campaign_ui.gd 2021 "\t\t\t\tC.act(on[n][0], on[n][1]); get_viewp"
choice_button.gd 40 "\t\taccept_event(); pressed.emit()"
crest.gd 101 "\treturn pts"
debrief_ledger.gd 344 "\treturn false"
fleet_manifest.gd 301 "\treturn false"
fleet_portrait.gd 33 "\treturn {\"code\": code, \"installed\": true"
ledger_ship.gd 34 "\t# A still camera; the installed model r"
map3d.gd 1298 "\t\t_wake_mesh.surface_end()"
map3d_props.gd 311 "\t\tcaster(mm)"
map3d_shaders.gd 859 "\"\"\""
map3d_system.gd 415 "\tm.extra_cull_margin = h; parent.add_chi"
map_intel.gd 163 "\treturn {\"avg\": avg, \"low\": low, \"hurt\":"
rail_orders_shots.gd 132 "func _initialize(): root.add_child.call_"
[godot/ui/campaign/fonts]
OFL_Michroma.txt 93 "OTHER DEALINGS IN THE FONT SOFTWARE."
OFL_Oxanium.txt 93 "OTHER DEALINGS IN THE FONT SOFTWARE."
[godot/ui/campaign/test]
debrief_ledger_test.gd 224 "\tquit(0 if failures == 0 else 1)"
fleet_manifest_test.gd 202 "\tui.queue_free(); await frames(); preloa"
hull_text_test.gd 18 "\tquit(0 if fails == 0 else 1)"
map_key_halo_test.gd 110 "\tquit(0 if fails == 0 else 1)"
[godot/ui/career]
.gitignore 1 "*.uid"
career_screen.gd 554 "\t\t\tset_tab(TABS[key - KEY_1][0])"
crest.gd 100 "\tdraw_string(f, c + Vector2(-ts.x * 0.5,"
rename_dialog.gd 135 "\t\t_close()"
[godot/ui/career/test]
career_honours_test.gd 214 "\tquit(1 if fails else 0)"
career_readability_test.gd 123 "\tquit(1 if fails > 0 else 0)"
[godot/ui]
text_floor_shots.gd 414 "\treturn best"
ui_scale.gd 40 "\tplayer = clampf(float(v), PLAYER_MIN, P"
[godot/ui/theme/fonts]
OFL_AzeretMono.txt 94 "OTHER DEALINGS IN THE FONT SOFTWARE."
OFL_Barlow.txt 93 "OTHER DEALINGS IN THE FONT SOFTWARE."
OFL_BigShouldersDisplay.txt 93 "OTHER DEALINGS IN THE FONT SOFTWARE."
OFL_ChakraPetch.txt 93 "OTHER DEALINGS IN THE FONT SOFTWARE."
[godot/ui/theme]
glass_shell.gd 819 "\treturn c"
```

### Packed reference files

Each entry is `basename:decoded lines` in `godot/rules/test/saved/records/`, with the suffix given on its own line.
Every file was decompressed and every JSON/JSONL record parsed; the battles themselves were not replayed here.

```text
txt.br
math:316090 math_verdict:1 prng_1001:10000 prng_4242424242:10000 prng_7:10000
jsonl.br
s1:161 s10:243 s11:143 s12:99 s13:162
s14:135 s15:182 s16:242 s17:119 s18:266
s19:172 s2:192 s20:131 s21:206 s22:144
s23:690 s24:526 s25:321 s26:167 s27:232
s28:277 s29:180 s3:168 s30:322 s31:230
s32:79 s33:135 s34:168 s35:305 s36:201
s37:272 s38:369 s39:517 s4:263 s40:270
s41:229 s42:150 s43:174 s44:185 s45:145
s46:197 s47:89 s48:118 s49:62 s5:389
s50:88 s51:124 s52:164 s53:110 s54:56
s55:176 s56:153 s57:141 s6:247 s7:432
s8:123 s9:325 s983_station_defend:136 s983_station_plain:113 s983_teaching_station_defend:125
t529_may_debt_no:42 t529_may_grow_no:99 t529_nostop:104 t529_roles_change:92 t529_roles_mend:82
t529_roles_screen:79 t529_roles_strike:78 t529_scent:53 t529_spawned:72 t7a_accountsplits:96
t7a_debtdue:51 t7a_facetlit:24 t7a_fleetelsewhere:63 t7a_flightcast:92 t7a_flightpaths:87
t7a_forgeahead:99 t7a_grandledger:56 t7a_lastaccount:44 t7a_ledgerarcs:40 t7a_lensrotates:23
t7a_lighttogether:31 t7a_mirroraside:66 t7a_onelens:36 t7a_prismsface:37 t7a_rearreckoning:72
t7a_replay:105 t7a_salvoend:84 t7a_screensshift:48 t7a_splitthree:53 t7a_starlings:96
t7a_sunlens:37 t7a_torpfirst:70 t7a_wallearly:41 t7a_wallmoves:41 t7a_weakside:36
t7b_ch_broodsplits:64 t7b_ch_growth:107 t7b_ch_nine:59 t7b_ch_spat:83 t7b_ch_teeth:97
t7b_ch_tideearly:117 t7b_ecl_archive:96 t7b_ecl_formation_a:99 t7b_ecl_formation_b:77 t7b_ecl_formation_c:101
t7b_ecl_formation_d:70 t7b_ecl_iterfire:112 t7b_ecl_shadow:76 t7b_ecl_targetarchived:36 t7b_ecl_triage:95
t7b_ecl_wall:113 t_acidbeforeaim:58 t_acidseams:46 t_angles:76 t_breathbite:130
t_broodreserve:43 t_burnflaw:34 t_burnstays:87 t_castcorrected:32 t_casttwice:93
t_choosebrood:53 t_debthunts:55 t_debtsreserve:40 t_deployread:21 t_ecl_arcswarm:180
t_ecl_copiedbehind:56 t_ecl_copiescontribute:73 t_ecl_copyfires:55 t_ecl_coronashadow:58 t_ecl_earliercopy:84
t_ecl_everyframe:95 t_ecl_flagshipindex:57 t_ecl_framezero:114 t_ecl_iterationkill:56 t_ecl_iterationswap:50
t_ecl_layersshift:75 t_ecl_longcopy:67 t_ecl_nolayer:110 t_ecl_noonchoice:89 t_ecl_noonrepeat:65
t_ecl_onesuncopy:60 t_ecl_outshadow:86 t_ecl_platesshadow:93 t_ecl_restoredbeyond:109 t_ecl_restoredfleet:112
t_ecl_restoreninth:93 t_ecl_silentarchive:79 t_ecl_stillness:131 t_ecl_tenthframe:110 t_ecl_tenthousand:163
t_ecl_twicerestored:115 t_ecl_uncopiedtarget:58 t_ecl_unseenarchive:60 t_escortname:37 t_everygun:73
t_everythroat:52 t_falsehulls:62 t_firstlight:55 t_firstthroat:66 t_firstwave:45
t_flagshipLedger:33 t_flagshiplens:36 t_flakskip:106 t_flawforever:49 t_fleshknit:54
t_frenzyfeeds:122 t_generation:29 t_glasscorrected:68 t_growhurts:105 t_hardlight:70
t_hb_allscars:61 t_hb_burncarry:46 t_hb_cutfeeds:117 t_hb_cutturn:60 t_hb_darkknives:93
t_hb_darktorps:69 t_hb_doublebolted:104 t_hb_everyknife:50 t_hb_firstscar:47 t_hb_hulkmore:31
t_hb_knifeback:50 t_hb_loosepack:31 t_hb_mawopens:63 t_hb_nothingbroken:113 t_hb_packbites:141
t_hb_packcloses:48 t_hb_patchedwing:57 t_hb_patchguns:121 t_hb_preyscent:52 t_hb_privatewing:58
t_hb_railboarding:54 t_hb_retasked:86 t_hb_runbigger:51 t_hb_rushrail:80 t_hb_scrapfront:147
t_hb_screaming:113 t_hb_secondknife:82 t_hb_smilecut:42 t_hb_swarmscrap:48 t_hb_trophystandard:35
t_hb_warlordrun:63 t_hb_weldedfight:126 t_hb_weldedwhole:145 t_hb_weldmatters:158 t_hb_wholeyard:69
t_hb_wreckline:28 t_heg_beacon:61 t_heg_bell:105 t_heg_colddrill:54 t_heg_columnendures:115
t_heg_columnstraight:102 t_heg_crossfire:56 t_heg_cruisers:80 t_heg_drill:78 t_heg_escorts:91
t_heg_filedarmor:139 t_heg_filedbefore:112 t_heg_filedtriplicate:63 t_heg_flagshipstandard:135 t_heg_formation:76
t_heg_fullgroup:129 t_heg_irontempo:166 t_heg_launchorder:55 t_heg_livingrelay:58 t_heg_oneorder:66
t_heg_onetarget:46 t_heg_onevoice:66 t_heg_overflow:112 t_heg_permanentfile:92 t_heg_rehearsed:79
t_heg_rollingfire:74 t_heg_rotation:102 t_heg_secondvolley:133 t_heg_secondwave:89 t_heg_sevenbreach:113
t_heg_sharedsolution:62 t_heg_standardcovers:153 t_heg_standinggroup:87 t_heg_stdforward:48 t_heg_strikebook:66
t_heg_totalinterdiction:131 t_heg_widenet:43 t_heldaccount:74 t_holdcounted:40 t_inheritedaim:82
t_irontestament:45 t_lensaloft:56 t_longfocus:36 t_longlight:38 t_manymouths:73
t_mirrorturns:38 t_mouthdeep:88 t_namedledger:58 t_namedprey:64 t_oathstillness:42
t_oathwings:132 t_preyeverymouth:101 t_preyname:68 t_razorprey:96 t_rechargelit:24
t_recordedangle:55 t_refraction:55 t_refuseholes:101 t_rollwings:87 t_rundown:77
t_salvotwohands:70 t_secondthroat:115 t_skinthick:65 t_sporetide:54 t_standardreroll:66
t_sworndeploy:33 t_throatdeep:32 t_throatred:68 t_throatspits:150 t_tideend:43
t_tornback:125 t_twoimages:54 t_twosalvos:66 t_unpaid:133 t_volleygrows:90
t_wallanswers:84 t_wardglass:54 t_wingreserve:58 t_wingsdebt:80
json.br
threat_s19:1 threat_s23:1 threat_s4:1
```

### Binary files

Binary file line counts are N/A. Every tracked binary was read and had its format header checked. For the two audio directories,
append `.ogg` to bare names and expand `name[0-2]` as `name_0.ogg`, `name_1.ogg`, `name_2.ogg`. For the Nemesis pool,
combine `nem_<faction>_<n>` for each `n` from 1 to 6 with each listed suffix, then append `.webp`.

```text
[godot/audio/clips] 180
ambient_0 arc_0 bassDrop_0 boomBig[0-2] boomCrunch[0-2] boomLow[0-1] boomSmall[0-3] choirBell[0-2]
cough[0-2] crackGlass[0-2] crackSettle[0-2] darkLance[0-2] deathRun[0-2] debris[0-1] enemyTurn_0 engineLoop[0-2]
grappleWet[0-2] gunFlak[0-2] gunGlob[0-3] gunSpine[0-1] gunTracer[0-1] heavyPlate[0-2] hitGlass[0-3] hitWet[0-3]
hullHitBig[0-1] hullHit[0-5] hullTick[0-3] impactChord_0 ionCharge_0 ionField[0-2] ionZap[0-2] lanceLR[0-2]
lasSear[0-2] laserLR[0-2] laserLarge[0-4] laserSmall[0-4] launch_0 needleTick[0-2] patterHull[0-3] patterShield[0-2]
plasmaHit[0-3] plasmaShot[0-2] puff[0-2] railHit[0-3] railStrike[0-3] reward_0 salvoBoom[0-3] scrape_0
shellBang[0-2] shieldBig_0 shieldHit[0-4] shieldShatter[0-2] shieldShimmer[0-2] starShimmer[0-2] torpLaunch[0-1] torpRocket[0-3]
torpSac[0-3] uiClick_0 uiConfirm_0 uiDeny_0 uiPanel_0 uiRound[0-2] uiSelect_0 victory_0
whoosh_0 wreckSettle[0-2] yourTurn_0
[godot/audio/synth] 137
ambient_bed.ogg bass_drop_0 boom_l[0-1] boom_m[0-1] boom_s[0-2] charge_0 cough[0-2] engine[0-1]
gun_flak[0-3] gun_glob[0-2] gun_las[0-3] gun_needle[0-3] gun_plasma[0-2] gun_rail[0-2] gun_shell[0-3] gun_spine[0-2]
gun_sq[0-2] gun_tracer[0-2] hit[0-3] hit_glass[0-2] hit_heavy[0-2] hit_ion[0-2] hit_las[0-2] hit_plasma[0-2]
hit_rail[0-2] hit_wet[0-2] lance[0-1] lance_choir[0-1] lance_dark[0-1] lance_ion[0-1] launch[0-2] patter_hull[0-2]
patter_shield[0-2] phase[0-1] pop[0-2] puff[0-1] salvo_tail[0-1] shield[0-2] shield_break[0-1] sting_loss_0
sting_win_0 torp[0-2] torp_heavy[0-2] torp_rocket[0-2] torp_sac[0-2] torp_star[0-2] ui_alert_0 ui_boss_0
ui_cancel_0 ui_click[0-3] ui_confirm_0 ui_enemy_0 ui_panel_0 ui_reward_0 ui_round_0 ui_select_0
ui_your_0 wreck_0
[godot/music/tracks] 24
boss_final.ogg calm_darktimes.ogg calm_tactical.ogg fac_chorus.ogg fac_corsair.ogg fac_deathless.ogg fac_hegemony.ogg fac_ithar.ogg
fac_voidsworn.ogg hot_heat.ogg hot_pursuit.ogg hot_qazi.ogg hot_theme_a.ogg map_drone.ogg map_echo.ogg map_outer.ogg
map_sector.ogg map_signal.ogg map_transmission.ogg sting_champion.ogg sting_fanfare.ogg sting_lose.ogg sting_victory.ogg title_war.ogg
[godot/portraits/alts] 49
aelith_alt1.webp aelith_alt2.webp aelith_alt3.webp aelith_pre68.webp aelith_r7.webp aelith_r8alt1.webp grax_alt1.webp grax_alt2.webp
grax_alt3.webp grax_p64alt1.webp grax_pre68.webp grax_r7.webp grax_r8.webp grax_r8alt1.webp kassar_alt1.webp kassar_alt2.webp
kassar_alt3.webp kassar_pre68.webp kassar_r7.webp kassar_r8alt1.webp matriarch_alt1.webp matriarch_alt2.webp matriarch_pre68.webp matriarch_r7.webp
matriarch_r8alt1.webp mending_alt1.webp mending_alt2.webp mending_alt3.webp mending_pre68.webp mending_r7.webp mending_r8alt1.webp mott_p64alt1.webp
mott_pre68.webp nekhet_alt1.webp nekhet_alt2.webp nekhet_alt3.webp nekhet_pre68.webp nekhet_r7.webp nekhet_r8alt1.webp sable_p64alt1.webp
sable_pre68.webp vesh_p64alt1.webp vesh_pre68.webp vex_alt1.webp vex_alt2.webp vex_alt3.webp vex_pre68.webp vex_r7.webp
vex_r8alt1.webp
[godot/portraits/nemesis] 6
frame_chorus.png frame_corsair.png frame_deathless.png frame_hegemony.png frame_ithar.png frame_voidsworn.png
[godot/portraits/nemesis/pool] 204
chorus: (none) _burn _burn_patch _carapace _carapace_patch
corsair: (none) _burn _burn_patch _cyber _cyber_patch _eye _eye_patch
deathless: (none) _burn _burn_patch _machine _machine_patch
hegemony: (none) _burn _burn_patch _cyber _cyber_patch _eye _eye_patch
ithar: (none) _burn _burn_patch _porcelain _porcelain_patch
voidsworn: (none) _burn _burn_patch _eye _eye_patch
[godot/portraits/nemesis/scars] 6
scar_burn.png scar_carapace.png scar_cyber.png scar_eye.png scar_machine.png scar_porcelain.png
[godot/portraits/painted] 13
aelith.webp grax.webp kassar.webp matriarch.webp mending.webp mirelle.webp mott.webp nekhet.webp
sable.webp thorne.webp vaelen.webp vesh.webp vex.webp
[godot/portraits/sheets] 13
chorus_portraits.webp corsair_portraits.webp crests_all.webp deathless_portraits.webp hegemony_portraits.webp ithar_portraits.webp nemesis_chorus.webp nemesis_corsair.webp
nemesis_deathless.webp nemesis_hegemony.webp nemesis_ithar.webp nemesis_voidsworn.webp voidsworn_portraits.webp
[godot/ui/battle/fonts] 3
BarlowSemiCondensed-Medium.ttf BarlowSemiCondensed-Regular.ttf BarlowSemiCondensed-SemiBold.ttf
[godot/ui/battle/icons/ships] 36
B16_23.png B19_11.png B20_11.png B21_11.png B22_11.png B23_51.png C13s_23.png C14s_23.png
C15s_23.png C16s_23.png C19_51.png D20_23.png D21_23.png D22_23.png D9_23.png H10_23.png
H4_11.png H7_23.png H8_23.png H9_23.png I11_37.png I14_23.png I15_11.png I16_11.png
I8_37.png O1_37.png O2_37.png O3_11.png S1_51.png S2_23.png V14_23.png V15_37.png
V16_37.png V17_37.png V18_51.png V1b_r_23.png
[godot/ui/campaign/fonts] 2
Michroma-Regular.ttf Oxanium-Variable.ttf
[godot/ui/theme/fonts] 8
AzeretMono-VF.ttf Barlow-Medium.ttf Barlow-Regular.ttf BigShouldersDisplay-VF.ttf ChakraPetch-Bold.ttf ChakraPetch-Medium.ttf ChakraPetch-Regular.ttf ChakraPetch-SemiBold.ttf
```

**Not checked:** Full standing checks and parity, windowed play, screenshot scripts, live listening, installed hulls (including replaced A4 hulls), replay of packed battles, historical disk saves and frame timing. The brief leaves the full runs to the runner and reserves the PC for issue 1070; no picture was needed for this code-only audit. The source outside the seven scoped folders was read only where a caller, CI job or oracle comparison required it.
