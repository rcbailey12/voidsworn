# Campaign parity test (G3)

Node runs the pinned JS game files (`oracle/`, unchanged) and Godot runs `campaign.gd`; both play the same seeded runs with the same scripted player and write one record per click. `node/compare_campaign.js` stops at the first step and field that differ. There is no tolerance: numbers compare as exact doubles in canonical form (keys sorted, null and undefined left out, integers plain, other numbers as IEEE hex).

- PC: `tools\pc\parity_campaign.bat` (30 runs). Linux: `GODOT=... sh godot/campaign/test/run_parity_campaign.sh [first] [last]`.
- Files: `node/env.js` (loads the oracle headless), `node/golden_campaign.js` (the JS side), `parity_campaign.gd` (the Godot side), `node/compare_campaign.js`, `node/export_campaign.js` (the tables), `node/coverage.js` (what the runs exercised).

## Other campaign checks

- `run_nem_scenarios.sh`: the Nemesis scenarios (Deathless comeback, Corsair loot and towed ship, Ithar honed, Chorus feeding and gloat, beat-teaching, weaknesses found in battle, pronouns, every faction's warning line) in the JS game and in Godot, compared record by record.
- `arc_hook_test.gd`: the story arc hook (off, on with no arc file, on with a test card).
- `save_test.gd`: atomic saves, the backup, a damaged save loading the backup.

## When a record is written

- Once at the start (the title screen), then after every click the scripted player makes, and after every simulated page reload.
- The record is written after the click's whole effect, including every screen it opens.

## What every record holds

| Field | What it is |
|---|---|
| `act`, `arg` | the click (or `reload`, `start`, `end`) |
| `acts` | every button on the screen now, in order, with enabled or disabled: on the JS side read from the HTML the game produced |
| `rng` | the state of the game's PRNG (mulberry32, `RNG_S`), the only random stream the campaign rules use |
| `run` | the whole run object except its map (fleet, ships, captains, credits, relics, boons, reward chain, stats, reserve, ...) |
| `map` | the sector map (nodes with their encounter, seed, reward, shipyard stock; edges; condition; region; biome) |
| `meta` | the profile (renown, unlocks, mastery, favour, variants, stats, options) except the telemetry log |
| `saved` | the saved copy of the run (which also checks when saves happen) |
| `t` | everything else that can change what happens next: the JS `window._*` transients (reward config, patron reward, relic choice, wrecks, boon and refit offers, aspect offer), the open event (id and the options shown, which depend on the faction's wording), the shipyard node, the picked admiral and faction, the run options (alternate fleet, alternate Command, Heat), the progression tab, the ship id counter (`UID`), whether the run has ended, and the battle in progress (seed, round, result, partial, campaign and finished flags, the mid-battle event, and every unit's id, side, hull, hp, dead, captured, fled, kills, damage, kill cause and killer) |

Each part is stored in full when it changes and as a 16-hex SHA-256 every step.

## What is left out, on purpose

- **Telemetry** (`META.tel`): it only fed the browser's back-fill of old run logs, which a Godot profile never runs (`backfilled` and `wonFix41` are set on both sides).
- **The page and toast text**: wording is checked by eye; the buttons are compared.
- **The function to call after a promotion** (`window._promoteAfter`): its effect shows in the next screen's buttons.
- **Presentation**: the decorative title and map showcase battles (in the browser they reseed the rules PRNG; both sides leave them out, see the G3 report), the 3D map, toasts, sounds.
- **Real battles**: both sides use the same stub battle (`stub_start`, `stub_resolve` in `campaign.gd`, copied line for line in `golden_campaign.js`). The battle rules have their own parity test (`godot/rules/test/`).
