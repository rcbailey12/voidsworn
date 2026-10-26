# godot/main: the game as one program (G2)

`main.tscn` is the project's main scene. It owns the title screen, the settings, the quick battle and the hand-off between the campaign (G3, `godot/campaign/`) and the battle scene (G2, `godot/scenes/battle/`). This file is the contract with the campaign. A change to it lands here in the same commit.

## The campaign

G3's `res://campaign/campaign.gd` holds the rules of a run and its screens as data. `campaign_host.gd` runs it inside the game:
- It loads the tables and the save, then sets `battle_mode = "external"` and `battle_setup`.
- `battle_setup(run, cfg)` builds the real battle through the rules API and returns its `B`.
- On `battle_requested`, it plays that battle in the battle scene (`main.play_api(api, opts)`), then calls `campaign.finish_battle("win" | "loss" | "retreat", api.R.B)`.
- When the campaign shows the title page again, the host hands back to main's title screen.

### Drawing the screens: G3's UI

When `res://ui/campaign/campaign_ui.gd` exists, the host uses it:

```gdscript
# res://ui/campaign/campaign_ui.gd (G3)
extends CanvasLayer
func bind(campaign) -> void    # draw campaign.page and campaign.modal_d now and on campaign.changed;
                               # a click calls campaign.act(act, arg); show and clear campaign.toasts
```

- The host hides the UI (`visible = false`) while a battle plays.
- If that file is ever missing, `campaign_fallback_ui.gd` draws each screen as its title, its facts and one button per act.
- The host sets `hide_on_battle = true` on G3's UI when the UI has that property.

### Bot runs

`--bot-runs N` plays whole runs headless, title to end screen:
- Each choice uses the weights of the G3 parity bot. The stub battle buttons are left out: real battles decide every fight, with both sides on AI.
- Summary per run: `result` (win, loss, unfinished or crashed), `sector`, `battles`, `clicks`, `errors`, `game_s`.

## Battles: `start_battle` and `play_api`

`play_api(api, opts)` plays a battle the campaign host already set up. `start_battle(run, cfg, opts)` sets one up and plays it, for anything else that needs a battle.

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
