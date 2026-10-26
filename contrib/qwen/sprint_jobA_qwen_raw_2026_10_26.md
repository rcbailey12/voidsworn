Blind Review: GDScript Rules Port, Travel Sprint, Oct 26 2026

Preamble and scope limits

I cannot fetch live files from raw.githubusercontent.com or the GitHub blob pages. Every observation below is drawn from the evidence pack itself: the commit descriptions, the README paraphrase, the API.md summary, the trap list, and the scenario descriptions the pack provides. Where the pack gives me a specific file, line range, or byte count, I cite it. Where I must reason from those descriptions rather than read the code, I mark the claim INFERRED. Where the pack does not give me enough to decide, I mark it UNSURE. I have not read, quoted, or built on any other model's review. I have not reviewed godot/campaign/ (its parity harness has not landed) or godot/fx/ (it did not list on main at check time).

1. Ranked findings, most dangerous first

F1. Per-action hash completeness is asserted but not itemised in the evidence I can read (Trap A)
Status: INFERRED, partially UNSURE.
Commit 9273632e says records carry "the full state (exact doubles), PRNG state, round and record index." The trap list in section 3A demands, at minimum: RNG state as an exact 32-bit value; every unit field (template, q, r, facing, exact HP unrounded, dead, section HP, shield, statuses, weapons fired, cooldowns); turn number and activation index; pending event queue; board shape and full terrain state; well state; combat log entries or their hash; the seed.
The commit message's phrase "full state" is not the same as an itemised field list. I cannot read godot/rules/test/parity_main.gd or node/golden.js to confirm whether "full state" includes the pending event queue, the well state, combat log entries, and the seed. If any of those are serialised on the Node side but skipped in the Godot canonical writer (or vice versa), parity passes while behaviour diverges silently.
Why dangerous: A hash that omits the pending event queue, for example, would let a tick-death ordering error cancel within a turn and still match. A hash that omits well state would let a gravity-well divergence pass in any future scenario that adds one.
What would close it: Read the canonical-state serialiser in both node/golden.js and godot/rules/test/parity_main.gd. Diff the field lists. Confirm every field in the 3A checklist appears in both. Confirm the SHA-256 is computed over the identical byte sequence on both sides.

F2. README describes record granularity that the latest commit has superseded (Trap A, staleness)
Status: OBSERVED from the pack's own flag, INFERRED in consequence.
The pack itself flags this: "the README describes records 'after every activation', while commit 9273632e says records are now taken after every action (hooks, abilities, orders, ticks, activations, rounds)." The README at godot/rules/test/README.md still says "after every activation." If a future reviewer or contributor reads the README and believes the harness checks only at activation boundaries, they will underestimate the coverage and miss that the harness is now finer-grained. Worse, if the README is the only documentation a new scenario author reads, they may not know which hooks produce records and may write a scenario that accidentally skips a hook.
Why dangerous: Stale documentation causes false confidence. A contributor may add a scenario and believe it is checked at activation granularity when it is actually checked at action granularity, or vice versa, and misdiagnose a failure.
What would close it: Update godot/rules/test/README.md to match commit 9273632e. List every record point explicitly: move burn, weapon volley, death, ram, boarding, nova, every ability, every order, every turn-start tick, every activation, every round.

F3. Sort stability depends on a single choke point (JSM.ssort) and four known JS sorts lack full tiebreaks (Trap B)
Status: INFERRED, with specific UNSURE items.
The pack states that "every sort in the rules is a stable merge sort with the JS comparator (JSM.ssort, matching JS's stable Array.prototype.sort)." The trap list names four JS sorts that need care: the target sort near battle.js line 864, the activation order near line 1073 (no tiebreak for equal speed and squadron status), and two partial-tiebreak sorts near lines 569 and 1052.
I cannot grep rules.gd (117,728 bytes) or battle_api.gd (11,947 bytes) for bare .sort() or .sort_custom() calls. If even one call site uses Godot's builtin Array.sort() or Array.sort_custom(), the sort is not stable, and ties will reorder non-deterministically across runs or across Godot versions. The activation-order sort at JS line 1073 is especially dangerous: two units with equal speed and equal squadron status have no tiebreak, so insertion order is the only guarantee. If the GDScript port builds the activation list in a different order than JS (for example, by iterating a Dictionary, which in GDScript has no guaranteed order), the tiebreak silently changes.
Why dangerous: A single bare sort_custom on a gameplay path would pass all five current scenarios if no tie occurs in s1 through s5, then break on a seed sweep or a new scenario.
What would close it: Grep rules.gd and battle_api.gd for .sort( and .sort_custom(. Confirm zero hits outside jsm.gd's own ssort implementation. Then, for each of the four named JS sorts, confirm the GDScript port feeds the list in the same insertion order and uses JSM.ssort.

F4. GDScript integer division truncates; JS / on numbers does not (Trap D)
Status: INFERRED, UNSURE on specific call sites.
In GDScript, 7 / 2 is 3 (integer truncation). In JS, 7 / 2 is 3.5. The pack warns: "Every division in the port must be checked for intended float division." rules.gd is 117,728 bytes. I cannot read it. Any division that the JS oracle performs as float division but the GDScript port performs as integer division will silently truncate. This is especially dangerous for damage calculations, speed calculations, and any formula that divides and then rounds.
Similarly, GDScript's % operator does not work on floats; the port must use fmod(). And GDScript's builtin round() rounds halves away from zero, while JS Math.round() rounds toward positive infinity. The pack says the port must use the V8 round from jsm.gd everywhere. If any call site uses GDScript's builtin round() instead of JSM.round() (or whatever the ported helper is named), a value of exactly x.5 will round differently.
Why dangerous: These are silent, per-value errors. They will not crash. They will produce a wrong number that feeds into the hash, and if both sides make the same mistake (unlikely, since one is JS and one is GDScript), parity passes. More likely, one side rounds and the other does not, and parity fails on a scenario that happens to hit that value. But if no current scenario hits it, the error is latent.
What would close it: Grep rules.gd for every / operator, every % operator, and every round( call. For each, confirm the intended semantics match JS. Confirm no GDScript builtin round() is called on a gameplay path.

F5. str() on floats in the canonical state writer could produce different strings than JS (Trap D)
Status: INFERRED, UNSURE on implementation.
The pack warns: "str(10.0) is '10.0' in GDScript. Any canonical state string built with str() on floats can differ from JS." In JS, String(10.0) is "10". In GDScript, str(10.0) is "10.0". If the canonical writer on either side uses its language's default float-to-string conversion, the SHA-256 inputs differ even when the numeric values are identical.
The README says "Non-integer numbers are written as exact IEEE hex" for the data export. But the canonical state writer for parity records is a different code path. I cannot confirm whether parity_main.gd and golden.js both serialise floats as IEEE hex, or whether one uses str() and the other uses String().
Why dangerous: If the serialisation differs, every record hashes differently and parity fails immediately, which is at least loud. But if both sides use a custom writer that mostly agrees except on edge cases (negative zero, subnormals, very large exponents), the failure is intermittent and seed-dependent.
What would close it: Read the canonical serialiser in both golden.js and parity_main.gd. Confirm both use the same float-to-bytes representation (ideally IEEE 754 hex, matching the data export convention). Confirm no str() or String() is used on a float in the serialisation path.

F6. tr name collision and builtin math function shadowing (Trap D)
Status: INFERRED, UNSURE on whether the collision exists.
The pack warns: "tr is taken by Object.tr. Any ported helper named tr collides." And: "Bare atan() inside a script calls Godot's builtin C atan, not the script's own static function." If any function in rules.gd or jsm.gd is named tr, it silently calls Object.tr() (translation lookup) instead of the intended helper. If any call site writes atan(x) without qualifying it as JSM.atan(x), it calls the C library's atan, not the ported V8-compatible version.
I cannot grep the 117,728-byte rules.gd for these patterns. The fdlibm port in jsm.gd (15,176 bytes) presumably defines sin, cos, atan2, exp, hypot, and round. If rules.gd calls sin(x) without the JSM. prefix, it gets Godot's builtin C sin, not the fdlibm port. The pack says this was checked for the proof slice (243,721 inputs against Node), but the full port is larger.
Why dangerous: A last-bit sin difference can change terrain noise. A last-bit atan2 difference can flip a .5 facing boundary. These are exactly the silent-divergence errors the fdlibm port exists to prevent.
What would close it: Grep rules.gd and battle_api.gd for unqualified calls to sin(, cos(, atan2(, exp(, hypot(, round(, atan(, and tr(. Confirm every call is qualified with the JSM or equivalent namespace. Confirm no function in the port is named tr.

F7. NOT PORTED guards may not cover every unported branch (Trap G)
Status: INFERRED, UNSURE on specific guard placement.
The README says: "anything a battle reaches that the port does not carry stops the run with 'NOT PORTED: <rule>', so a gap cannot pass silently." The trap list adds: "A guard that never fires because the branch that would reach it is itself unported (or pruned) is a finding."
I cannot enumerate the NOT PORTED guards in rules.gd without reading the file. The specific risk is: if a branch is unported and the code that would enter that branch is also unported, the guard inside the branch is dead code. For example, if the gravity-well fight type is not ported, and the code path that checks if (fight_type == "gravity_well") is also not ported, then a NOT PORTED guard inside the gravity-well handler will never fire. The absence of the guard is invisible because the scenario that would reach it does not exist.
The same applies to convoy fights, breakthrough fights, and any fight type not in s1 through s5.
Why dangerous: The guard system gives false confidence. A reviewer sees "NOT PORTED guards exist" and assumes any unported path will be caught. But if the entry point to that path is also unported, the guard is unreachable.
What would close it: Enumerate every NOT PORTED guard in rules.gd. For each, trace the call graph backward to the entry point. Confirm the entry point is itself ported and reachable. Flag any guard whose only caller is also unported.

F8. Async-to-sync ordering for tick deaths and mid-await events (Trap H)
Status: INFERRED, UNSURE on specific await points.
The README says: "Async functions run synchronously. Tick deaths: deaths queued by turn ticks have their tail deferred to the point where the game awaits them." The trap list says to check "every await point in the JS for an ordering the sync port could change (especially deaths queued by turn ticks, round-start deaths, and any event emitted mid-await)."
In JS, await yields to the event loop. If two deaths are queued by a turn tick, and the JS code awaits between processing them, other events (animations, AI decisions) can interleave. In the GDScript sync port, there is no event loop. The two deaths process back-to-back with nothing in between. If the JS code's observable state depends on that interleaving (for example, if a death triggers a callback that modifies the queue before the second death is processed), the sync port produces a different state.
I cannot read battle.js or core.js to enumerate await points. The oracle copies are in godot/rules/test/oracle/ but I cannot access them.
Why dangerous: The divergence is timing-dependent and may not appear in any current scenario. It would appear when a specific interleaving of deaths and events occurs, which is seed-dependent.
What would close it: Enumerate every await in battle.js and core.js. For each, determine whether any state mutation can occur between the await and the next line. If so, confirm the GDScript port replicates that mutation order.

F9. Data export completeness and runtime-computed tables (Trap I)
Status: INFERRED, partially UNSURE.
The pack says: "node/export_data.js writes every data table from data.js, core.js and battle.js to tables.json." The Godot loader recomputes SHA-256 and refuses to run on mismatch. This is good. But the trap list asks: "Check for tables the export could miss (added tables, tables built at runtime, values computed at load time rather than stored)."
If any table in the JS is built by a loop at load time (for example, a lookup table computed from other tables), the export script must replicate that computation. If the export script only dumps static literals, the computed table is missing from tables.json, and the Godot side either crashes or uses a default.
The file sizes are: tables.json is 70,289 bytes, data.js is part of the oracle pin at b71c8d7. I cannot compare the table count in tables.json against the table count in the JS files.
Why dangerous: A missing table would likely cause a crash, which is loud. But a table that is present but has a runtime-computed column missing would silently use a default value, and parity would pass if no scenario reads that column.
What would close it: Diff the set of table names in tables.json against the set of exported names in export_data.js. Confirm every table in data.js, core.js, and battle.js appears. For each table, confirm the export includes all columns, including any computed at load time.

F10. Enemy fleet generation is not ported and not tested (Trap A, section 4)
Status: OBSERVED from API.md, INFERRED in consequence.
API.md states: "Fleet: without cfg.enemies, the enemy fleet is generated exactly as the game does (G1 work in progress; today pass enemies)." Every scenario s1 through s5 passes enemies explicitly. The fleet generation code path is therefore untested by design. When it lands, it will introduce new PRNG draws, new id assignments, and new sort orders, none of which are covered by any golden scenario.
Why dangerous: Fleet generation is the first code a battle runs. If its PRNG draw order differs between JS and GDScript, every subsequent state diverges. This is not a bug in the current port; it is a known gap that will need its own golden scenarios when it lands.
What would close it: When fleet generation is ported, add at least one golden scenario that does NOT pass enemies, and let both sides generate the fleet. Hash after generation, before the first activation.

F11. Port size against the 1.5x threshold
Status: UNSURE.
The pack says the full port was estimated at "about 2,500 to 3,000 more lines" beyond the proof slice's 2,600 lines, giving a total estimate of roughly 5,100 to 5,600 lines. The adopted bar (X19) sets a threshold of 1.5x the estimate. rules.gd is 117,728 bytes. I cannot convert bytes to line count without reading the file. GDScript lines average perhaps 40 to 60 bytes, giving a rough range of 1,960 to 2,940 lines, but this is very rough. The proof slice was 2,600 lines for 59% of battle.js and 23% of core.js. The full port covers 100% of both, plus the data layer.
If the estimate is 5,600 lines and the threshold is 1.5x, the limit is 8,400 lines. If rules.gd is within that range, the threshold is met. But I cannot confirm the line count.
What would close it: Count the lines in rules.gd. Compare against 1.5 times the port plan estimate. The estimate itself may not be on main; if so, mark this UNSURE permanently until the estimate is published.

F12. Dictionary identity comparison in GDScript (Trap D)
Status: INFERRED, UNSURE on specific call sites.
The pack warns: "== on dictionaries compares contents in GDScript; use is_same for identity." In JS, === on objects checks identity. If the JS oracle uses unit === target to check whether two references point to the same unit, the GDScript port must use is_same(unit, target), not unit == target. The latter compares all fields, so two distinct units with identical stats would be "equal" in GDScript but not in JS.
I cannot grep rules.gd for == on unit references. This is a latent bug that would only fire when two units have identical field values, which is unlikely in current scenarios but possible in a 200-seed sweep.
What would close it: Grep rules.gd for == where both operands are unit dictionaries. Replace with is_same() where identity is intended.

F13. JSON integer recovery (Trap D)
Status: INFERRED, UNSURE on implementation.
The pack warns: "JSON numbers all load as floats in Godot. Integer fields from tables.json must be recovered as ints where the JS treats them as ints, or compared as exact doubles consistently."
If tables.json has "count": 3 and Godot loads it as 3.0 (a float), then any GDScript code that does integer arithmetic on it (for example, using it as an array index or a loop bound) may behave differently. GDScript's for i in range(3.0) works, but 3.0 / 2 is 1.5, while the JS code might expect integer division.
The README says non-integer numbers are written as IEEE hex, implying integers are written as plain numbers. But the Godot JSON parser still loads them as floats.
What would close it: Confirm the Godot loader casts integer fields to int after JSON parse. Alternatively, confirm all arithmetic on those fields uses float semantics consistently on both sides.

2. Ranked list of missing golden scenarios

M1. Gravity well (dead star) fight
None of s1 through s5 is a gravity well fight. The trap list names "pulled events, tidal ticks, well state" as untested paths. The well state is also in the required hash state (Trap A), so the hash code for well state is untested. This is the most dangerous gap because it is an entire fight type with its own mechanics, and the adopted bar (X19) requires all 8 fight types.

M2. Convoy fight
Not described in s1 through s5. Convoy fights have fled events (escorts fleeing, a convoy getting through). These are distinct code paths in battle.js. Without a golden scenario, any port error in the convoy logic is invisible.

M3. Breakthrough fight
Not described in s1 through s5. Breakthrough fights have a breakthrough event. Same reasoning as M2.

M4. Boarding outcomes: capture, overrun, raid
The pack lists three boarding outcomes. s1 through s5 descriptions do not mention boarding. If no scenario exercises boarding, the entire boarding code path is untested. Capture (ship changes side) is especially dangerous because it mutates unit ownership, which affects id assignment, targeting, and the hash.

M5. All 8 fight types
The adopted bar requires all 8 fight types. The pack does not name all 8 explicitly. From the JS game, the typical set would include: standard engagement, station defence, convoy, breakthrough, gravity well, ambush, patrol, and possibly a flagship hunt or sector boss. I cannot confirm the exact 8 without reading battle.js. Mark the exact list UNSURE. s1 is a station engagement. s2 is a flagship with escorts. s3 is a Corsair fight in an asteroid belt. s4 and s5 are 10v10 sector 3 battles. That covers perhaps 3 or 4 of 8 types. The remaining 4 or 5 are missing.

M6. All 12 abilities and all 6 Commands
The pack lists: evasive, reload, focus, phase, frenzy, overburn, regrow, reclaim, ionpulse, blink, surge, launch, nova (13 items listed, though the pack says 12 abilities; nova may be separate). Commands: barrage, hunt, iron, restore, surge, scramble. Plus command_warning announcements. I cannot confirm which of these are exercised in s1 through s5 without reading scenarios.json. Mark UNSURE. Any ability or command not exercised by a golden scenario is a code path that could diverge silently.

M7. Section-down effects
Prow down (forward guns silenced), mid down (broadsides and shield generator), eng down (engines crippled). These are state-dependent modifiers. If no scenario reduces a section to zero HP and then continues the fight, the section-down code path is untested.

M8. All 8 death causes and wreck-as-blocking-terrain
The pack lists: cut, big, flay, melt, dark, tidal, blast (7 named; the 8th may be ram or nova). The wreck-as-blocking-terrain path means a dead ship becomes an obstacle. If no scenario produces a wreck and then has another unit interact with it, this path is untested.

M9. Turn-start ticks: fire, acid, tidal, storm
Ion storm (shields only) is specifically named. If no scenario starts a turn with a unit on fire, in acid, in a tidal zone, or in an ion storm, those tick paths are untested.

M10. Ram runs
The pack names "ram event with path, dmg, recoil, soak, section." s1 through s5 descriptions do not mention ramming. If no scenario includes a ram, the entire ram code path is untested.

M11. Terrain generation beyond s3's asteroid belt
s3 uses an asteroid belt on a square arena. Other board shapes and terrain types the generator can produce are untested. Terrain generation uses the PRNG, so a different terrain type means different PRNG draws, which means a different state sequence.

M12. Station guns firing in s1
s1 is "a sector 1 engagement at a station." The pack asks to "check whether station guns fire." If the scenario's enemy list does not include the station's guns, or if the guns are present but never activate, the station-gun code path is untested even though the scenario is at a station. Mark UNSURE without reading scenarios.json.

M13. 200-seed sweep on the full port
The adopted bar requires a 200-seed sweep. The proof history mentions a 60-seed cloud sweep on the proof slice. The full port has not been sweep-tested at 200 seeds per the evidence in this pack. Mark UNSURE; the sweep may have run but the pack does not confirm it.

M14. Enemy fleet generation scenario
As noted in F10, every scenario passes enemies. When fleet generation lands, at least one scenario must omit cfg.enemies and let both sides generate the fleet.

3. Not checked
The following items I could not verify because I cannot read the repo files directly.
1. Exact field list in the canonical state serialiser (node/golden.js and godot/rules/test/parity_main.gd). I cannot confirm whether the hash includes pending event queue, well state, combat log, and seed. UNSURE.
2. Bare sort() or sort_custom() calls in rules.gd or battle_api.gd. I cannot grep the files. UNSURE.
3. Every division, modulo, and round() call in rules.gd. I cannot audit 117,728 bytes of GDScript for GDScript-vs-JS semantic mismatches. UNSURE.
4. The canonical float serialisation format in both golden.js and parity_main.gd. UNSURE.
5. Qualification of math calls (sin, cos, atan2, exp, hypot, round, atan) in rules.gd. I cannot confirm every call goes through JSM. UNSURE.
6. NOT PORTED guard enumeration and reachability. I cannot list the guards or trace their call graphs. UNSURE.
7. Await points in battle.js and core.js and their sync-port equivalents. I cannot read the oracle files. UNSURE.
8. tables.json completeness against the JS source tables. I cannot diff the export. UNSURE.
9. Line count of rules.gd for the 1.5x port-size threshold. UNSURE.
10. The exact 8 fight types from battle.js. UNSURE.
11. Which abilities, commands, death causes, and tick types are exercised by s1 through s5. I cannot read scenarios.json. UNSURE.
12. godot/fx/API.md. The pack says it did not list on main at check time. Not checked.
13. godot/campaign/. Parity harness has not landed. Not checked, per instructions.
14. The fdlibm constants in jsm.gd. The pack says 13 were off and one parsed as 0, and that exact constants must be IEEE words. I cannot confirm the fix is in place. UNSURE.
15. Whether the JS oracle's Date.now() pin is the only time source. I cannot grep the oracle files for Date, performance.now, or any other clock. UNSURE.
16. Whether the tr name collision exists anywhere in the port. UNSURE.
17. Whether any Dictionary identity check uses == instead of is_same(). UNSURE.
18. Whether integer fields from tables.json are cast to int after JSON parse. UNSURE.

Closing note
The five golden scenarios (s1 through s5) cover a station engagement, a flagship escort fight, an asteroid-belt skirmish, and two 10v10 sector-3 battles. This is a solid foundation for the core combat loop. The most dangerous gaps are: (a) the hash field list is not itemised in any evidence I can read, so I cannot confirm it covers all state the trap list demands; (b) at least four of the eight fight types have no golden scenario; (c) boarding, ramming, section-down effects, and several death causes appear untested; (d) the GDScript semantic traps (integer division, round, str on floats, dictionary identity) are high-probability bug sites in a 117,728-byte file that I cannot grep. The NOT PORTED guard system is a strong design choice, but its value depends on every guard being reachable, and I cannot verify reachability without reading the code. The README staleness on record granularity is a small fix but should be done before the next contributor reads it.

END OF REVIEW.
