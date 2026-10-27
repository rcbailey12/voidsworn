# Godot rules parity (G1; started as the A3 gate, FINDINGS R28 and R29)

The battle rules in `godot/rules/` are a GDScript port of the game's `battle.js` (Godot 4.7.2). This folder is their parity test: it runs the port headless, with no scene and no rendering, against the JS game. The game side uses the rules through `godot/rules/battle_api.gd` (see `godot/rules/API.md`).

## Running it

- **On the PC:** double-click `tools\pc\parity.bat`. It works in two places:
  - in `Downloads\voidsworn_test\build\`, with the game files beside it and the repo's `godot\` folder copied to `build\godot\`;
  - in a repo checkout.

  It prints PASS or FAIL. On a FAIL it also gives the first turn and field that differ.
- **In the cloud or on Linux:** `GODOT=/path/to/godot sh godot/rules/test/run_parity.sh [scenario ...]`.
- **API smoke test:** `godot --headless --path godot --script res://rules/test/api_smoke.gd -- s1` plays a battle through `battle_api.gd` and prints the event counts.

## What it checks

1. **Data.** `node/export_data.js` writes every data table from `data.js`, `core.js` and `battle.js` to `godot/rules/data/tables.json`. Nothing is copied by hand.
   - It fails (exit 1, nothing written) when a table the port reads is missing: it scans `godot/rules/*.gd` for `TB.NAME`, `TB["NAME"]` and `TB.get("NAME")` and checks each was exported (a table renamed, removed or turned into a function in the JS). The list goes into the file, and the Godot loader refuses a file that lacks one.
   - Non-integer numbers are written as exact IEEE hex.
   - The Godot loader recomputes a SHA-256 of the tables and refuses to run if it differs.
2. **Random numbers.** The game's PRNG (mulberry32), ported exactly. The check compares the first 10,000 draws from seeds 1001, 7 and 4242424242.
3. **Math.** V8 computes `sin`, `cos`, `atan2` and `exp` with fdlibm and `hypot` with its own scaled sum. These are ported line for line in `rules/jsm.gd`, along with V8's `Math.round` and V8 12.4's `Math.pow` (the enemy fleet budget and the heavy-fleet weights use it). The check covers 316,090 inputs against Node, including the edge branches (Oct 26): atan2 of infinities, exp near overflow and underflow and exp(1) (V8 returns E there; the port was one bit off before), pow with exponents above 2^31 and subnormal results, and (Oct 27) 26,030 sin and cos results above 2^19 pi, up to the largest double (V8's `__kernel_rem_pio2` big-argument reduction, the last branch that was NOT PORTED). Every fdlibm branch is now ported; `_np` in `jsm.gd` stays as the hard stop for any future gap.
4. **Battles.** `scenarios.json` holds the seeded fights, one or more per feature (each has a `note` saying what it covers):
   - **s1 to s5:** engagements, the Hegemony flagship, a Corsair belt fight, two 10-against-10 battles (also timing).
   - **s6 to s10:** carriers and squadrons (Scramble, launches, the flak gauntlet), a generated carrier fleet with carrier adaptation, all 36 boons, relics, aspects and heat, campaign events (reinforcements both ways, solar flare), the Standard AI, the heavy and swarm archetypes.
   - **s11 to s20:** every fight type: defend, hunt, intercept, breakthrough, relay (Standard and veteran AI), ambush, decapitation, the dead-star gravity well, and a sector 1 opener on a compact field.
   - **s21, s22:** Classic mode (whole turns, `aiTurn`).
   - **s23:** carrier-heavy 10 against 10, the think-time worst case.
   - **s24 to s31:** B-20 coverage and stream B steps 1 to 3 (sync fire, prism charge, the legion, the Nemesis, travelling torpedoes).
   - **s32 to s34 (Oct 26, X20 verifier):** a tidal death on the dead-star rim, a rift board (chasm and bridges), a shoals board (holes in the field).
   - **s35 to s40 (Oct 27, stream B step 4, R42 and R49):** one Nemesis fight per faction: Corsair riches and withdrawal, the Ithar duel fleet honed, the Voidsworn challenge that moves to your biggest ship, the Hegemony artillery line with campaign reinforcements, the Deathless legion that never routs, the fed Chorus. Between them they reach every battle signature (challenge, duel, line, flee_battle, reinforce) and every weakness found in battle (flank, brawl, ion, torp, slow, anchor, board).
   - **s41 (Oct 27):** config type safety on the dead-star board: `alt` arrives as a Dictionary (the game reads `cfg.alt!==false`, so it means alternating). Before the fix in 2b91ea4 this stopped `new_battle` in GDScript.

   Node runs the game's own `data.js`, `core.js` and `battle.js` unchanged (`node/golden.js`, from the pinned copy in `oracle/`). It writes a record at every one of these points, the same on both sides:
   - `start` (after setup), `move` (each burn, at the point the game draws it), `rotate`, `fire` (each weapon's volley, and each torpedo impact), `death`, `ram`, `board` (before the boarding rolls), `nova`, `blink`;
   - `ability`, `order`, `command <side>` and `wing order` after each of those actions;
   - `tick <side>` after each side's turn-start ticks, `end turn` (Classic mode), `end activation`, `activation` (after each enemy activation), `round` (after the round start and swarm phases), and `end <result>`.

   Each record holds the whole battle state in canonical form (B, every unit, and the rules state kept outside B: the board cut-outs, the hexes that block sight, the id counter), including the battle log, a SHA-256 of that state, and the PRNG state. Godot writes the same record, and `node/compare.js` stops at the first turn and field that differ.
   - Integers must match exactly.
   - Every other number is compared as its exact 64-bit double. There is no tolerance anywhere.
   - The player's side is played by a bot through the same API calls the scene uses: `bot: "full"` is the sim's `botUnit` (Command, abilities, rams, boarding, brace, objective pull, plus one turn in place when nothing bears); otherwise a simpler move-and-shoot bot.

   **The sweep** (`run_sweep.sh [count] [seed]`, on the PC `tools\pc\parity_sweep.bat`): `node/sweep_gen.js` writes N random battles with every scenario field varied (fight type, shape, map, deployment, kind, sector, column, both factions, the admiral and so the Command, the player fleet, generated enemy fleets, boons, relics, aspect, heat, veteran captains, AI level, Classic mode, campaign events, the Nemesis with his R42 and R49 fields (persona, traits, faction special, honed, riches, fed, memory lines), bot). Both sides play them all in one process each (`batch` mode) and `node/sweep_check.js` compares every battle record by record. The G1 exit bar is 200 battles, 0 differences, 0 errors.

4c. **Threads and the hard stop.** `thread_test.gd` plays s4 and s23 on one thread and again with every enemy `step()` on a worker while the main thread reads (`view`, `ui_info`, `threat_map`, `compute_reach`, `preview_fire`); both must end identical. It also checks that a NOT PORTED rule and a bad battle config halt the battle and block commands.

5. **Timing (report only).** Enemy think time per activation in the scenarios marked `timing` (s4, s5, s23): the AI's `aiUnit` only, with no snapshots and no startup. It reports the average, the worst, and the total per round, for Node and for Godot. The game bar is a worst enemy think under about 0.5 s on the PC.

## Files

- `../jsm.gd`: JavaScript number semantics:
  - 32-bit ops and the PRNG;
  - V8 rounding;
  - fdlibm and V8 `hypot`;
  - a stable sort;
  - the canonical state writer.
- `../rules.gd`: the ported rules, in the same order and with the same names as the JS. Units stay dictionaries with the JS field names.
  - **Async functions** run synchronously.
  - **Tick deaths:** deaths queued by turn ticks have their tail deferred to the point where the game awaits them.
  - **Unported rules:** anything a battle reaches that the port does not carry stops the run with `NOT PORTED: <rule>`, so a gap cannot pass silently.
- `parity_main.gd`: the Godot harness. It mirrors `node/golden.js`: the same bot for the player's side, the same activation order and the same records.
- `node/summary.js`: lists in plain words what a scenario exercised.

## Traps found while porting (keep these in mind for the full port)

- **Long decimal literals.** Godot parses them up to one unit in the last place off. 13 fdlibm constants were off, and one parsed as 0. Write exact constants as IEEE words.
- **Built-in name clash.** Inside a script, a bare `atan()` calls Godot's built-in C atan, not the script's own static function. Name ported helpers so they cannot clash with built-ins.
- **C library math is not V8's.** On 200,000 inputs, glibc differs from V8 on 21% of `atan2`, 34% of `hypot` and 3% of `sin` results. That is why fdlibm is ported.
- **GDScript versus JS semantics:**
  - `int / int` truncates.
  - `%` is not allowed on floats; use `fmod`.
  - `round()` rounds halves away from zero (JS rounds toward plus infinity).
  - `==` on dictionaries compares contents; use `is_same` for identity.
  - `sort_custom` is not stable.
  - `str(10.0)` is `"10.0"`.
  - JSON numbers all load as floats.
  - `tr` is taken by `Object.tr`.
