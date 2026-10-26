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
   - Non-integer numbers are written as exact IEEE hex.
   - The Godot loader recomputes a SHA-256 of the tables and refuses to run if it differs.
2. **Random numbers.** The game's PRNG (mulberry32), ported exactly. The check compares the first 10,000 draws from seeds 1001, 7 and 4242424242.
3. **Math.** V8 computes `sin`, `cos`, `atan2` and `exp` with fdlibm and `hypot` with its own scaled sum. These are ported line for line in `rules/jsm.gd`, along with V8's `Math.round` and V8 12.4's `Math.pow` (the enemy fleet budget and the heavy-fleet weights use it). The check covers 283,730 inputs against Node.
4. **Battles.** `scenarios.json` holds the seeded fights:
   - **s1:** a sector 1 engagement at a station.
   - **s2:** the sector 1 Hegemony flagship and two escorts.
   - **s3:** a Corsair fight in an asteroid belt on a square arena.
   - **s4 and s5:** two 10-against-10 battles at sector 3 size (Hegemony; Corsair), which also serve as the timing test.

   Node runs the game's own `data.js`, `core.js` and `battle.js` unchanged (`node/golden.js`). After every activation it writes the whole battle state in canonical form, a SHA-256 of that state, and the PRNG state. Godot writes the same record, and `node/compare.js` stops at the first turn and field that differ.
   - Integers must match exactly.
   - Every other number is compared as its exact 64-bit double. There is no tolerance anywhere.

5. **Timing (report only).** Enemy think time per activation in s4 and s5: the AI's `aiUnit` only, with no snapshots and no startup. It reports the average, the worst, and the total per round, for Node and for Godot. The game bar is a worst enemy think under about 0.5 s on the PC.

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
