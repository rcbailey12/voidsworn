Revised Job A review: rules port parity

Correction accepted. My earlier read of rules.gd stopped at 417 lines and I treated that as the whole file. The pack says the file is 117,728 bytes, and your browser read confirms the complete battle layer is present. F1 is withdrawn. I cannot independently re-fetch the full file with my tools in this session, so for the functions you listed I treat existence as confirmed by you and mark line-level claims about them UNSURE. I keep the findings that rest on files and lines I did read, and I work trap items D, F, G, and H against the confirmed function list, marking what I could not see.

The most important retained finding is still the hash gap: the canonical record does not carry CUT, SOLID, deferred, or UID. That is independent of the truncation and is the highest live risk.

## 1. Ranked findings, most dangerous first

### F1. OBSERVED. CUT and SOLID are module state that the hash does not carry.

rules.gd:27-28 declares CUT and SOLID at module level. rules.gd:351 sets both inside genTerrain. rules.gd:238 reads CUT in onBoard. SOLID is the hole set that blocks sight and is read by sightBlocked and los. Neither variable is inside B. parity_main.gd:30-37 hashes B with SKIP_B = {units, log, cfg, prog} and each unit with SKIP_U = {t, ship}. CUT and SOLID are not in B, so they are not in the canonical text on either side. A port bug in cut-hex or hole detection would change onBoard, sightBlocked, and los without changing the hash, and parity would pass while movement and line of sight differed. The check that closes it is to add CUT and SOLID to B or to the canonical writer, hash them as sorted arrays, and add a scenario with holes that asserts sightBlocked and los results.

### F2. OBSERVED. deferred and UID are module state that the hash does not carry.

rules.gd:29 declares deferred and UID at module level. deferred holds the pending killUnit tails that flush_deferred runs. UID is the ship id counter. Neither is in B, and neither is in parity_main.gd:30-38. deferred controls the order in which death tails run at the next flush. UID controls every new ship id. A port bug that reorders deferred tails or skips a UID increment would not be caught. The check that closes it is to hash deferred as an ordered list of queued unit ids and UID as a number in the hash, and to add a scenario where a turn-start tick queues a death and the tail runs.

### F3. INFERRED. NOT PORTED guard coverage cannot be verified from the files I read, and the guard pattern has a structural risk.

rules.gd:68-69 defines np() which sets the NOT PORTED marker. The confirmed function list includes many functions that likely contain np() guards or call functions that do: genEnemyFleet, makeWing, deployWings, sqRole, sqWants, sqPlan, sqAct, swarmPhase, squadronsOf, bossCmdTick, bossCmdFire, cmdTier, cmdRec, cmdPow, cmdActive, cmdTaken, runCommand, tacticRam, tacticBoard, escortsBreak, objectiveTick, checkEndRules, setupObjective, objAfterMove. The trap is a guard placed on a path that is itself only reachable through another unported branch. The check that closes it is to grep rules.gd for every np() call, list the branch condition that reaches it, and test that forces each branch. Mark each guard as firing or not firing.

### F4. INFERRED. Trap D semantics are not verified across the full port.

GDScript int division, % on floats, builtin round, == on dictionaries, and str() on floats are all live risks in the battle layer. The parts I did read are handled: jt at rules.gd:70 avoids the Object.tr collision, is_same is used for unit identity in battle_api.gd:88, battle_api.gd:92, battle_api.gd:128, and battle_api.gd:161, and jsm.gd:39-41 implements V8 round. But the confirmed battle functions contain many arithmetic paths where the trap applies. Likely hot spots: hitChance, motionHit, expectedVs, applyHit, damageSection, repairSection, systemDamage, ramEstimate, ramInfo, boardOdds, captureChance, cmdPow, dmgMult, guardMul, ionOf, pathField, fieldDist, aiArcSoon, aiObjScore, aiObjUrgency, sqValue, sqObjNear. In those, an int / int truncation or a builtin round() would change the result by a small amount and could still pass a hash if the hash omits the affected field. The check that closes it is to grep rules.gd for /, %, round(, == on dictionaries, and str( on floats, with each hit classified as intended or a bug. Also check that every integer field loaded from tables.json is recovered as int where the JS treats it as an integer, and compared as an exact double where the JS treats it as a number.

### F5. INFERRED. Trap F math usage is not verified across the full port.

jsm.gd is correct, but whether every gameplay path calls JSM.sin, JSM.cos, JSM.atan2, JSM.exp, JSM.hypot, and JSM.jsround is UNSURE. jsm.gd:41-61 writes the fdlibm constants as IEEE words. jsm.gd:114-126 names the atan helper _atan and explains that a bare atan() would call Godot's builtin. jsm.gd:220-228 is a stable merge sort. That part is in good shape. The risk is in the battle layer: motionHit, hitChance, ramInfo, ramEstimate, pathField, fieldDist, aiArcSoon, sightBlocked, los, and genTerrain are the likely call sites for trig, hypot, and rounding. A last-bit atan2 difference can flip a facing boundary, and a last-bit sin difference can change terrain noise. I did not read those lines. The check that closes it is a grep of rules.gd for sin(, cos(, atan2(, exp(, hypot(, and round( and a confirmation that every hit is a JSM. call and not a builtin.

### F6. INFERRED. Trap H async-to-sync ordering is only partly covered by the hash.

flush_deferred and queueDeath are in the confirmed function list, and deferred is not hashed (F2). The JS await points that queue death tails are the risk. A sync port that runs a tail early or late changes event order. If deferred is not in the hash, a reordering that does not change the final state can pass. The check that closes it is to hash deferred and to add a scenario where a turn-start tick queues a death, the death tail emits an event, and the event order is asserted.

### F7. OBSERVED. The Node harness does hook abilities, orders, ticks, and commands.

The earlier note that these were commented out was wrong. golden.js:37-43 wraps useAbility, giveOrder, startSideTurn, and useCommand with hook(...) calls. The block is active. useAbility calls hook('ability',u), giveOrder calls hook('order',u), startSideTurn calls hook('tick '+side,null), and useCommand calls hook('command '+side,null). The Godot side calls hook from battle_api.gd and from rules.gd, and parity_main.gd:122 records every hook. Both sides record after these actions on the code that is on main. This is not a finding against the code; it corrects the earlier note.

### F8. OBSERVED. SKIP_U and SKIP_B match between the Node and Godot harnesses.

golden.js:133 has SKIP_U={t:1,ship:1} and SKIP_B={units:1,log:1,cfg:1,prog:1}. parity_main.gd:30-31 has the same sets. This part of the hash is aligned. The remaining gaps are F1 and F2, which are state outside B.

### F9. OBSERVED, with a completeness caveat. Every sort I could read goes through JSM.ssort, and no bare sort or sort_custom appeared in the parts of rules.gd and battle_api.gd I read.

rules.gd:262 uses JSM.ssort(l, _cmpCheap). rules.gd:392 and rules.gd:395 use JSM.ssort for the station site search. battle_api.gd:169 uses JSM.ssort(pe, func(a,b): return b["speed"] - a["speed"]). jsm.gd:220-228 is a stable merge sort. The JS activation sort at golden.js:66 (pe.sort((a,b)=>b.speed-a.speed)) is matched by battle_api.gd:169. The four named JS sorts at "battle.js about 864, 1073, 569, 1052" cannot be matched because battle.js on main is 401 lines and the oracle copy is 402 lines. The sorts I could find in battle.js are at lines 43, 228, 232, 308, and 361. The port equivalents for those are in functions you listed. The check that closes it is to grep rules.gd and battle_api.gd for .sort( and .sort_custom( with no hits, and a line-by-line comparison of every sort in battle.js to a JSM.ssort call in the port.

### F10. OBSERVED. The jt helper avoids the Object.tr collision, and is_same is used for unit identity in the API.

rules.gd:70 defines jt for JS truthiness and explains the name collision. battle_api.gd:88, battle_api.gd:92, battle_api.gd:128, and battle_api.gd:161 use is_same for unit identity. This part of trap D is handled in the code I read. The battle layer is UNSURE.

### F11. OBSERVED. The canonical writer does not use str() on floats.

jsm.gd:236-237 formats integers as integers and every other number as "d:" + hex64(f). parity_main.gd uses JSM.canon at lines 36-37. This avoids the str(10.0) == "10.0" problem. Any other canonical string built outside canon is UNSURE.

### F12. OBSERVED. scenarios.json covers only obj: "rout" and a narrow set of maps and shapes.

s1 is rout, open/open, sector 1 (scenarios.json:3-8). s2 is rout, open/station, boss (scenarios.json:9-15). s3 is rout, open/belt, sector 1 (scenarios.json:16-21). s4 is rout, open/station, sector 3, 10v10 (scenarios.json:22-29). s5 is rout, 10v10 sector 3 (scenarios.json:30-33). There is no deadstar shape, no convoy, no breakthrough, no boarding, no station-gun assertion, no ability-complete test, and no command-complete test. This is the coverage gap.

### F13. UNSURE. Trap I data export completeness cannot be verified from the files in the pack.

rules.gd:41-44 checks a SHA-256 and refuses to run on a mismatch, and _dec() at rules.gd:63-66 decodes #d: hex words back to doubles. Whether every table that data.js, core.js, and battle.js build at runtime is present in tables.json is UNSURE. The export script and the full tables file were not in the set I read.

### F14. UNSURE. Port size against the 1.5x threshold cannot be assessed.

The pack says the full port was estimated at 2,500-3,000 more lines and the audit bar is 1.5x. rules.gd is 117,728 bytes and now confirmed to hold the full battle layer. Without a line count and the port plan estimate on main, the threshold cannot be checked.

## 2. Ranked list of missing golden scenarios

1. Gravity well (dead star). Covers pulled, tick with kind: "tidal", WELL_RIM, WELL_PULL, WELL_ASSIST, WELL_DMG, and the deadstar shape cut. scenarios.json has no deadstar shape and no dead-star map. This matters because the well state is the most branch-heavy terrain path.

2. Boarding outcomes. Covers result: "capture", result: "overrun", and result: "raid". No scenario calls board or tacticBoard. The capture path changes a ship's side, which is a large state change that the hash must catch.

3. Convoy and breakthrough. Covers fled for escorts, breakthrough, and convoy getting through. scenarios.json has obj: "rout" only. A breakthrough fight exercises obj.type: "break" and the fled event, neither of which is exercised.

4. All eight fight types. The JS SHAPES table at battle.js:20-23 lists twelve shapes. The audit bar says eight fight types including the gravity well. scenarios.json exercises open and belt maps but only rout objective. The missing types include deadstar, convoy, breakthrough, and the objective types hold, break, defend, intercept, hunt.

5. Station guns. s1 and s2 are at a station map, but there is no scenario that asserts station guns fire (hit with unit: null). This matters because the hit event's unit can be null for station guns (API.md event table), and the port must carry that path.

6. All twelve abilities and all six commands. The pack lists evasive, reload, focus, phase, frenzy, overburn, regrow, reclaim, ionpulse, blink, surge, launch, nova and barrage, hunt, iron, restore, surge, scramble. scenarios.json does not name any ability or command. The bot in golden.js uses useAbility and useCommand, but only when the scenario's ship has ab and the bot chooses it. A dedicated scenario per ability and per command is needed to make the ability and command events and their state changes reachable.

7. Section-down effects. Covers section_down for prow (forward guns silenced), mid (broadsides and shield generator), and eng (engines crippled). No scenario forces a section to zero.

8. All death causes and wreck terrain. The pack lists cut, big, flay, melt, dark, tidal, blast, plus the wreck event. s1 to s5 are rout fights and will produce some deaths, but there is no assertion that every cause is hit and no scenario that asserts a wreck becomes blocking terrain.

9. Turn-start ticks beyond fire. Covers tick with kind: "acid", kind: "tidal", and kind: "storm" (ion storm, shields only). s1 to s5 may produce fire ticks, but acid, tidal, and storm are not described.

10. Ram runs. Covers the ram event with path, dmg, recoil, soak, section. s3's note says "ramming AI", but the scenario is rout and there is no assertion that a ram event is produced. A dedicated ram scenario is needed.

11. Terrain generation beyond belt, station, planet, storm, and graveyard. rules.gd:366 lists belt, station, planet, storm, graveyard. The shapes include hourglass, rift, shoals, colossus, archipelago, corridor, compact. s1 to s5 cover open and belt only. A scenario per shape is needed to exercise the cut and hole code paths, and to exercise CUT and SOLID after they are hashed.

12. Enemy fleet generation. API.md says enemy fleet generation is not ported and every scenario passes enemies. There is no scenario that omits cfg.enemies and asserts the generated fleet matches JS. This is a known gap, but it is still a missing scenario.

13. The 200-seed sweep on the full port. The pack says the proof slice ran 60 seeds, but the adopted bar is 200 seeds on the full port. run_parity.sh and the scenario harness support a seed override (parity_main.gd:121), so the sweep is possible, but there is no evidence in the pack that it has run on the full port.

14. A scenario that exercises CUT and SOLID directly. Even after F1 is fixed, a scenario with a shape that produces holes (for example rift or shoals) and a line-of-sight assertion is needed to prove the hole set is correct.

15. A scenario that forces a deferred death tail. After F2 is fixed, a scenario where a turn-start tick queues a death and the tail runs at the next await point is needed to prove the deferred queue order is correct.

## 3. Not checked

- I did not read the full rules.gd. My tool truncated the file at 417 lines. The confirmed function list tells me the battle layer exists. I could not verify divisions, % / fmod, round, == vs is_same, str() on floats, JSON int recovery, tr / jt, bare atan, long decimal literals, or JSM math usage inside those functions. Every claim about those functions is INFERRED or UNSURE.
- I could not enumerate the NOT PORTED guards. np() is at rules.gd:68-69, but the call sites in the battle layer were not read. Trap G is UNSURE beyond the structural risk noted in F3.
- I could not match the four named JS sorts at "battle.js about 864, 1073, 569, 1052" because battle.js on main is 401 lines and the oracle copy is 402 lines. The sorts I could find are at lines 43, 228, 232, 308, and 361.
- I could not read godot/fx/API.md because godot/fx/ is not on main. The commit f45852c8 is in the log but the directory does not list. That document is UNSURE.
- I could not verify tables.json against a full export of data.js, core.js, and battle.js because the export script and the full tables file were not in the set I read. Whether every table that battle.js builds at runtime is present is UNSURE.
- I could not verify the 200-seed sweep, the 60-seed sweep, or the timing numbers on the full port.
- I did not review godot/campaign/ because the pack says its parity harness has not landed.
- I could not independently confirm the existence or line numbers of the functions you listed. I take your browser read as confirming existence and mark line-level claims UNSURE.

## 4. Claims tied to files and lines I read

- rules.gd:27-29 declares CUT, SOLID, UID, and deferred at module level. rules.gd:351 sets CUT and SOLID. rules.gd:238 reads CUT in onBoard.
- rules.gd:68-69 defines np() for the NOT PORTED marker. rules.gd:70 defines jt.
- rules.gd:262, rules.gd:392, and rules.gd:395 call JSM.ssort. battle_api.gd:169 calls JSM.ssort.
- rules.gd:366 lists terrain types belt, station, planet, storm, graveyard.
- rules.gd:41-44 checks a SHA-256 of tables.json. rules.gd:63-66 decodes #d: hex words.
- parity_main.gd:30-37 hashes B with SKIP_B = {units, log, cfg, prog} and units with SKIP_U = {t, ship}. CUT, SOLID, deferred, and UID are not included. parity_main.gd:122 records every hook.
- golden.js:37-43 is active code that wraps useAbility, giveOrder, startSideTurn, and useCommand with hook(...). golden.js:133 has SKIP_U={t:1,ship:1} and SKIP_B={units:1,log:1,cfg:1,prog:1}.
- jsm.gd:39-41 implements V8 round. jsm.gd:41-61 uses IEEE words for fdlibm constants. jsm.gd:114-126 names the atan helper _atan. jsm.gd:220-228 is a stable merge sort. jsm.gd:236-237 formats canonical numbers without str() on floats.
- battle_api.gd:88, battle_api.gd:92, battle_api.gd:128, and battle_api.gd:161 use is_same for unit identity.
- scenarios.json:3-33 shows every scenario has obj: "rout", with shape: "open" and maps open, station, and belt.
- battle.js:20-23 lists twelve shapes. battle.js on main is 401 lines; the sorts I could find are at lines 43, 228, 232, 308, and 361.

With F1 withdrawn, the review now rests on the two hash gaps (F1 and F2) as the top live risks, with CUT, SOLID, deferred, and UID to be added to the canonical record on both sides and a scenario that forces a deferred death tail to be added. The remaining work is to enumerate the np() guards, bare math calls, and division and rounding sites in the battle layer, which I could not complete with the truncated read.
