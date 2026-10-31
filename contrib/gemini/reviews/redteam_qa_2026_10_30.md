# Red team audit, qa persona: Argon leg

Chair header: Argon (Gemini, Argon High) leg for the Oct 30, 2026 red team audit, run from the qa evidence pack and the persona leg prompt. Text below is the model report verbatim, with em dashes normalized to ASCII where they appeared.

1. [OBSERVED / INFERRED] Save Audit Finding 1 proved false: loadLocal() fails to write .repaired on parse or sanity failure, and saveLocal() overwrites .bak with malformed saves

Prior Verdict Under Attack: Save Audit Finding 1 claims "common failure modes (corrupt write, malformed half) degrade instead of bricking" and that voidsworn.v1.repaired "receives a raw copy of any save that needed repairs or failed to load". OVERTURNED.

What Breaks or Underperforms: Unparseable or half-malformed saves fail to write the .repaired recovery key, a malformed save that still parses as JSON overwrites the last good .bak on the next local write, and cloud sync clobbers valid cloud data when only one half of the cloud envelope is malformed.

Evidence:

OBSERVED: In core.js, loadLocal() swallows JSON syntax errors with "try{ if(s) o=JSON.parse(s); }catch(e){ o=null; }" and nulls invalid halves with "if(!saneRun(o.run)) o.run=null; if(o.meta!=null&&!saneMeta(o.meta)) o.meta=null;" before entering the inner try block.

OBSERVED: Inside that inner try block, STORE_KEY+'.repaired' is written only when "if(SAVED_RUN&&SAVED_RUN._repairs&&s)" holds or if an exception is thrown inside migrateMeta or migrateRun.

INFERRED: When JSON.parse(s) fails (o=null), the if(o&&typeof o==='object') guard skips the inner block without throwing, so .repaired is never written. Likewise, when o.run fails saneRun(o.run) and .bak cannot recover it, o.run becomes null prior to migrateRun, so SAVED_RUN evaluates to null without throwing and .repaired is never written.

OBSERVED: In saveLocal(), the backup rotation checks only "try{ JSON.parse(prev); localStorage.setItem(STORE_KEY+'.bak',prev); }" and never calls saneSave.

INFERRED: If voidsworn.v1 holds a save that parses as valid JSON but fails saneSave ("fleet not an array, broken meta"), the very next saveLocal() call overwrites the valid .bak with the malformed payload. Furthermore, in Persist.connect(), "if(!saneSave(d)){ console.warn('Cloud save malformed; keeping this device\'s save'); if(META.updated) this.push(); return; }" overwrites the entire cloud save when either half fails validation, rather than salvaging the valid half as loadLocal() attempts to do.

What It Costs the Game: Players who hit a corrupt write or malformed RUN object lose both their active run and their .bak safety net without generating the .repaired diagnostic backup, and a malformed cloud run wipes a valid cloud meta on connect.

2. [OBSERVED / INFERRED] Save Audit Finding 10 and Claims Register proved incomplete: Godot cutover lacks a browser-to-desktop transport and imports unlockAll profile corruption

Prior Verdict Under Attack: Save Audit Finding 10 claims "An importer is nevertheless cheap, because the Godot port mirrors the browser layer field for field" and the claims register treats "saves BLOCKER without the importer (fixtures now built and filed)" as resolved by schema fixtures. OVERTURNED (while confirming Save Audit Finding 6 and Finding 9).

What Breaks or Underperforms: A native Godot desktop build cannot read browser-origin localStorage without an export or cloud bridge, and any direct import of browser META carries a permanently unlocked profile into the Godot release.

Evidence:

OBSERVED: The Godot campaign loader reads only "user://voidsworn_campaign.json" and its .bak, and "no GDScript in the tree references the browser key voidsworn.v1".

OBSERVED: At the same time, "The browser build offers no export path either", because its Copy report feature emits only a diagnostic summary rather than an importable save.

INFERRED: Matching dictionary keys in godot/campaign/campaign.gd do not solve how a desktop binary reading OS filesystem paths (user://) accesses browser localStorage (voidsworn.v1) or window.claude cloud storage when the frozen browser build cannot export its save envelope.

OBSERVED: At browser boot, "if META.opts.unlockAll is anything other than false", main3d.js grants every Legacy key and admiral, so "any save written by the current browser build carries a fully unlocked META".

INFERRED: If an importer copies browser META into Godot without stripping unbought unlocks, every migrated player bypasses generational progression permanently.

What It Costs the Game: Either every existing player loses 100% of their progression and active runs at the Godot cutover, or migrated saves arrive corrupted with all doctrines and admirals unlocked for free.

3. [OBSERVED / INFERRED] Findings-to-Tests completeness claim overturned: 65% of tracked defects, all campaign/save runtime logic, and the entire Godot port have zero automated test coverage

Prior Verdict Under Attack: findings_tests/README.md claims "Every BLOCKER and FIX-level finding from the audit programs" is mapped to a working regression test or an explicit non-testable row, with "48 tests, 8 PASS / 40 FAIL". OVERTURNED.

What Breaks or Underperforms: The automated regression suite tests only static JS data and generator slices, leaving 41 testable runtime defects unwritten, omitting the Oct 29 save and persistence audit from its scope, and executing zero tests against the Godot port.

Evidence:

OBSERVED: Across the 125 ledger rows, only "44 of 125 findings (35%) have a working regression test today", while "41 are testable with named infrastructure and 40 are not honestly automatable".

OBSERVED: Those 41 testable defects remain unasserted because building them requires "usually a loader extension for the campaign files, which game_loader.js does not load" or a sim3d battle probe.

OBSERVED: The Scope list in findings_tests/README.md omits saves_persistence_audit_2026_10_29.md (which contains 1 [BLOCKER] and 4 [FIX] defects), and Wave 3 notes "nothing here runs the Godot build".

INFERRED: Because the browser build is "frozen to break fixes only since Oct 26, 2026" and active fixes target the godot/ tree, a Node harness that reads only root JS files cannot verify whether any of the 40 failing tests or 41 unwritten runtime checks are actually fixed in GDScript.

What It Costs the Game: Release readiness has no automated gate for 65% of known browser defects and 0% automated regression verification on the target Godot executable.

4. [OBSERVED / INFERRED] Regression test EVT-5 proved defective: asserts "haven only" and masks 6 of the 7 event free-exit guarantee failures

Prior Verdict Under Attack: findings_tests/README.md claims "failures are correct regression tests against unfixed defects" and "When a fix lands, the matching test should flip to PASS without edits". OVERTURNED for EVT-5 (while confirming the event_guarantee_eval_2026_10_29.md verdict of 26 PASS / 7 FAIL).

What Breaks or Underperforms: Test EVT-5 checks only the 3 fight-option events instead of the 33-event drawable pool, so fixing haven alone turns the regression test green while 6 other events continue to violate the settled free-exit ruling.

Evidence:

OBSERVED: The event guarantee evaluation tested all 33 drawable events and found "Events checked: 33. PASS: 26. FAIL: 7.". Alongside haven, it flagged "the other six FAIL events: storm, reactor, squall, mutiny, scout, saboteur", plus a permanently unreachable option in seer ("Answer her tone in glass") that requires ithar inside an event that "is barred for ithar".

OBSERVED: In the findings_tests.js run table, row EVT-5 fails with the note "haven only".

INFERRED: Because EVT-5 asserts only the strict fight-option subset (moon, tomb, haven), adding a leave option to haven will cause EVT-5 to pass while storm, reactor, squall, mutiny, scout, and saboteur still force hull damage, credit/experience penalties, or Nemesis clock advances (nemClock +1 and nemClock +2) on players who lack gated requirements.

What It Costs the Game: A false-green test result on EVT-5 lets 6 rule-violating events slip into the Godot cutover, trapping under-resourced fleets in mandatory damage or Nemesis ambushes.

5. [OBSERVED / INFERRED] Silent ID repair in core.js and campaign_run.js destroys space ships, captains, refits, and banked combat rewards when data IDs change

Prior Verdict Confirmed: Confirms Save Audit Finding 5 ([FIX]) and Finding 8 ([FIX]) using the ID-repair and reward-resume traces in core.js and campaign_run.js.

What Breaks or Underperforms: Whenever a hull, module, perk, or reward stage ID is renamed or filtered out, repairRunIds and resumeReward silently strip player space ships, captains, fitted modules, and unclaimed post-combat rewards without compensation.

Evidence:

OBSERVED: At load, keep() filters fleet space ships, modules, perks, relics, and boons against live tables, so "a renamed hull id therefore deletes that ship, its captain, its perks and its fitted refits". On Continue, "the _repairs fields are then deleted and the repaired run re-saved".

OBSERVED: In rewardFlow, the node is marked complete immediately ("completeNode inside the same call"), while in resumeReward, "repair forces an unrecognised stage to promo" and "a damaged or id-shifted reward can silently skip unclaimed prize, salvage or pick stages".

INFERRED: Remediating the 40 failing tests in findings_tests.js requires touching broken hull, weapon, and module definitions (such as ROS-2, ROS-3, ROS-5, MOD-2, and WPN-5), which will trigger silent deletions of ships, modules, and pending rewards in any active run loaded across that change.

What It Costs the Game: Data-table fixes silently amputate ships from a player's fleet or forfeit already-won combat rewards after the node is banked.

6. [OBSERVED / INFERRED] Live mobile detection fires on desktop PCs to disable accessibility protection, while saveOpts() fails to sync settings to cloud

Prior Verdict Confirmed: Confirms Drift Audit Finding 2 ("The retired mobile layer is live, and it can fire on real PCs") and Save Audit Finding 2 ([FIX]).

What Breaks or Underperforms: Desktop PCs with coarse pointers (touch-screen monitors or laptops) in small windows trigger the retired mobile code path at boot, forcing reduced-flash accessibility off and lowering graphics quality, while manual setting fixes never sync to the cloud mirror.

Evidence:

OBSERVED: The mobile detection flag "derives from pointer type and window size, so a coarse-pointer PC in a small window qualifies". At boot, that branch "forces reduced-flash off when no explicit setting exists and forces quality to medium".

OBSERVED: When a player changes settings in the UI, "saveOpts() merges into META.opts and calls Persist.saveLocal() only", whereas "Persist.save() is the only writer that stamps META.updated or runAt and pushes to the cloud".

INFERRED: A desktop player on a touch-enabled laptop has their reduced-flash accessibility default overridden at boot, and if they change their settings without playing a battle node, those preferences never receive a timestamp or cloud push.

What It Costs the Game: Creates a live accessibility hazard for photosensitive players on touch-capable PCs and breaks cross-device settings persistence.

7. [OBSERVED / INFERRED] Save Audit Finding 7 proved unsafe: replay-based mid-battle persistence enables infinite combat mulligans and drops cloud abandon telemetry

Prior Verdict Under Attack: Save Audit Finding 7 grades mid-battle persistence as a benign [NOTE], claiming "Mid-battle state is never saved; battle integrity is replay based, not resume based." and "What makes that safe is the per-node seed". OVERTURNED.

What Breaks or Underperforms: Because battle state B is never saved and hull damage is committed only when finishBattle runs, reloading the page mid-battle resets any losing fight to turn 1 without penalty, and the pagehide handler writes abandon telemetry only locally without stamping or syncing to the cloud.

Evidence:

OBSERVED: During combat, "Hull damage from an unfinished battle is not applied, because ship hp is written back only in finishBattle".

OBSERVED: Leaving a fight mid-battle fires pagehide, which "only logs a battle_abandon telemetry event and calls Persist.saveLocal()".

INFERRED: Seeding pre-battle setup does not preserve battle integrity: in a game where "about 80 percent of runs are lost by design", a player can reload the browser on any fatal turn before finishBattle executes to erase space ship losses and replay the battle with full knowledge of enemy placements and AI rolls. Furthermore, because pagehide calls Persist.saveLocal() rather than Persist.save(), META.updated is never stamped and battle_abandon events are lost on cloud reconciliation.

What It Costs the Game: Undercuts the core attrition loop via zero-cost turn resets and blinds cloud telemetry to mid-battle quit rates.

8. [OBSERVED / INFERRED] 40 failing regression tests and Open Check 3 expose silent weapon deletions on hull variants, no-op module fitting, backward gun arcs, and broken combat rules

Prior Verdict Confirmed: Confirms the findings_tests.js failure ledger ("48 tests: 8 pass, 40 fail"), Open Check 1 (NOMIDFIRE brace bypass), and Open Check 3 (campaign_run.js:128 module install guard).

What Breaks or Underperforms: Ship variants silently delete weapons or corrupt mounts, weapon-kind modules can be fitted to incompatible space ships where they do nothing, data tables define illegal backward-facing gun arcs, and combat gates fail across factions, bosses, and point-defense adaptations.

Evidence:

OBSERVED: Three ship variants silently drop weapons (ROS-2: "d_harvester_t, i_song_w, plus b_razor_s", where "b_razor_s drops bioplasma undisclosed"), two break mounts (ROS-3: "h_vanguard_g, c_hulk_g"), ascendant crawls at "ascendant speed 1" (ROS-1), and WPN-5 fails with "Rear arc defined; startorp evMult present", violating the rule that guns never face backward.

OBSERVED: Combat and faction gates fail in KIT-1 ("FAC_GATES has no chorus entry"), KIT-2 ("ionpulse dead against chorus and deathless"), PP-2 ("pure-hive fleet armed no point-defense adaptation"), FGT-1 ("flagship rolled in 91 of 400 boss encounters"), and Open Check 1 ("the brace bypass at battle.js:1385-1387 stands as a pure code defect").

OBSERVED: In campaign_run.js:128, the module install guard "keys on ability alone, no weapon-kind check exists anywhere", so six weapon-kind modules can be "fitted to a hull with no matching weapon kind and silently does nothing".

INFERRED: Because the Godot port uses the browser data tables and battle logic as its parity oracle, every one of these 40 failing data and combat defects is actively being cloned into the Godot tree.

What It Costs the Game: Players spend scarce credits and refit capacity on non-functional modules and downgraded hull variants while encountering broken faction gates, dead ion weapons, and unintended flagship spawns in 22.75% of boss fights.

9. [OBSERVED / INFERRED] Sector generator pass-ordering bug breaks the column-4 elite guarantee in 1.87% of maps, and the proposed single-line fix remains exposed to downstream overwrites

Prior Verdict Confirmed and Refined: Confirms Wave 3 Deep QA Section 1 (W3-1) while identifying an execution-order hazard in the chair's proposed fix shape.

What Breaks or Underperforms: Whenever column 4 rolls only rest nodes ([drydock, drydock]), genSector fails to place the guaranteed pre-rest elite node in 84 of 4,500 maps (1.87%).

Evidence:

OBSERVED: Wave 3 found "Sector maps 84 failures, all one kind: \"column 4 offers no elite\" (1.87% of maps)." and test W3-1 confirmed "elite guarantee broke on 25 of 900 maps in the compact sweep".

OBSERVED: Tracing seed 151, sector 1 showed that "the elite guarantee at core.js:268 looks for a battle or event node to convert" and does nothing on [drydock, drydock], after which the budgets loop promotes one node to battle and "the lone-node field conversion at core.js:277 (its target column can be 4)" converts the other into field.

INFERRED: The chair's suggested fix at core.js:268 ("when no battle or event node exists in the column, convert a rest node") still executes before the budgets loop and the core.js:277 field conversion ("its target column can be 4"), so fixing core.js:268 without guarding core.js:277 from targeting an elite node risks re-breaking the guarantee when column 4 is targeted downstream.

What It Costs the Game: Nearly 1 in 50 sectors breaks a core map-structure guarantee and deprives the player of an elite encounter before the rest stop.

10. [OBSERVED / INFERRED] Reward pipeline bugs completely kill duo boons (0 of 300) and corrupt tier-3 favour backfill (63% Common), exposing blind spots in Wave 3's simulation sweeps

Prior Verdict Under Attack: Attacks the sufficiency of Wave 3 Deep QA's reassurance ("1. Softlock and guarantee sweep: no softlocks" and 60-run Monte Carlo) while confirming findings_tests.js failures RWD-2, RWD-3, RWD-4, RWD-8, BN-1, BN-2, and BN-5.

What Breaks or Underperforms: Duo boons never survive offer generation, tier-3 favour backfill overwhelmingly rolls Common instead of high-rarity rewards, ram boons collide in a single key pool, and Epic boons outscale Legendary boons, yet none of these progression-breaking defects are flagged by softlock_sweep.js or sim3d.

Evidence:

OBSERVED: findings_tests.js proves "duo survived 0 of 300 offers" (RWD-4), "378 of 600 backfill picks rolled Common at favour tier 3" (RWD-8), L_storm is "ungated" (RWD-3), "three ram boons, one key pool" (BN-1), and "legendary 40 flat vs epic 40 plus burning" (BN-2).

OBSERVED: Meanwhile, Wave 3 admits "The sweep checks map structure and battle setup legality only", its 216-battle matrix admits "roster-depth extremes (all-swarm, all-capital) were not run as separate probes", and its campaign simulation ran only "60 bot runs" (yielding just 12 Sector 3 elite and 13 Sector 3 boss fights).

INFERRED: Because Wave 3's tools test only map graph reachability, initial battle placement, and a 60-run bot sample, 100% feature failures in the reward layer (RWD-4) and late-run rarity inversion (RWD-8, BN-2) pass the simulation sweeps completely undetected.

What It Costs the Game: Players investing in generational favour and boon synergies hit dead 0% duo rates and broken tier-3 Common backfills, while the QA simulation suite provides false confidence on late-sector and campaign-reward stability.

Verdict

RELEASE BLOCKED (40 failing regression tests, 41 unwritten runtime tests, broken save recovery in core.js, and an unbridged Godot save cutover); the single most important attack is overturning Save Audit Finding 1 and Finding 10 by proving from core.js:104-132 that loadLocal() never writes voidsworn.v1.repaired on JSON parse or saneRun/saneMeta failure, saveLocal() overwrites .bak with malformed saves because it checks only JSON.parse(prev) instead of saneSave, and the Godot desktop port cannot import browser localStorage saves because the frozen browser build has no export path and poisons every META profile with unlockAll.

Not checked

Godot runtime execution and parity goldens: The pack contains no GDScript source slices or Godot test output, so whether godot/campaign/campaign.gd or godot/scenes/battle/battle.gd introduces new state-corruption bugs, saves on battle exit, or matches browser rules parity could not be verified.

Live cloud conflict resolution: Persist.connect() is truncated at line 132 in the pack's core.js slice, so timestamp reconciliation logic after line 132 (updated vs runAt) and live multi-device race conditions could not be inspected.

Mid-battle AI softlocks on extreme fleets and phased activation UI: Roster extremes (all-swarm, all-capital) and UI modal states during the ruled phased activation flow were not exercised in the pack's evidence.

Unbounded save growth and secondary .repaired overwrites: Long-run localStorage quota exhaustion from RUN.map, fleet, and fallen growth, as well as the write-once lock on voidsworn.v1.repaired across multiple repair sessions, were not measured in the pack.
