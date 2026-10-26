# godot/main: the game as one program (G2)

`main.tscn` is the project's main scene. It owns the title screen, the settings, the quick battle and the hand-off between the campaign (G3, `godot/campaign/`) and the battle scene (G2, `godot/scenes/battle/`). This file is the contract with the campaign. A change to it lands here in the same commit.

## The campaign

G3's `res://campaign/campaign.gd` is a Node:
- Main adds it as a child and calls `start(main, opts)`. `opts` can hold `continue`, `screen` (`"legacy"` or `"help"`), and `bot` with `seed`.
- It draws its own screens (`godot/ui/campaign/`).
- For every fight it calls `await main.start_battle(run, cfg, {"bot": ...})` and reads the finished rules state from `result.api`.
- It emits `run_over(summary)` when the player is back at the title, or when a bot run ends. Main frees it and shows the title.
- `static has_save()` decides whether the title shows Continue run.

See `godot/campaign/README.md` ("The game shell hand-off") for the campaign side.

## Battles: `start_battle`

```gdscript
var result: Dictionary = await main.start_battle(run, cfg)            # a player battle
var result: Dictionary = await main.start_battle(run, cfg, {"bot": true})   # both sides on AI (bot runs)
```

- `run`: the campaign run dictionary, as rules/API.md `new_battle` takes it (admiral, fac, sector, fleet of ships, relics, boons, flagUid ...).
- `cfg`: the battle config (kind, fac, col, seed, obj, shape, map, dep, arch, mod; enemies optional once G1 generates fleets).
- While the battle plays, main hides the campaign's visible children and shows them again afterwards.
- With `bot`, the battle also returns at once when it ends (no end card).
- In a campaign battle, the top bar offers Retreat (except against a sector flagship), and the menu has no Quit to title.
- Without `bot`, the battle ends on its Victory or Defeat card. The player presses Continue, then the result comes back.

`result` holds:

| Field | Meaning |
|---|---|
| `result` | `"win"`, `"loss"`, `"retreat"`, `"quit"` (quick battles only: Quit to title), or `"softlock"` (bot runs only: nothing happened for 60 s) |
| `rounds` | rounds played |
| `killed`, `lost` | enemy ships destroyed, player ships lost |
| `errors` | Array of strings: rules functions not ported yet, softlocks |
| `secs` | how long the battle took |
| `view` | the final `api.view()` |
| `api` | the battle's rules API object (`godot/rules/battle_api.gd`), still holding the final rules state `api.R.B` |

Use `api` to run the campaign's after-battle rules exactly as campaign_run.js does from `B` (hull damage, ships lost, captures, salvage, XP). Read it straight away: main frees the battle scene right after `start_battle` returns, but `api` stays valid as long as you hold it.

## Settings

Main keeps the settings in `user://settings.json` and passes them to every battle:
- `volume` (0..1) and `sound`;
- `speed` (1 normal, 0.45 fast);
- `ai` (`veteran` or `standard`);
- `reduce_flashing` and `shake` (passed on to G4 fx);
- `tips`, `fullscreen` and `quality`.

The campaign reads them from `main.settings`. A campaign screen changes one with `main.settings[key] = value`, then `main.save_settings()`.

## Headless test: whole runs with both sides on AI

```
godot --headless --path godot -- --bot-runs 50 --fast 40 --report report.json
```

- With the campaign in the build, each run is a full campaign run. Without it, each run is one sector 1 battle.
- The exit code is 0 when every run had 0 errors and 0 softlocks.
- PC job: `tools/pc/jobs/g2_checks.bat`.
