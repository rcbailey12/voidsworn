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
- Battles: real battles decide every fight, with the game's own AI on both sides (api.ai_activate is sim3d's player bot).
- Choices: `--bot-policy smart` (the default) spends like a sensible player. At a yard it repairs, buys the dearest hull that fits, upgrades, then fits modules. On the map it heads for a yard when the fleet is under 4 ships or holds 300+ credits. It tows salvage and keeps prizes when there is room. `--bot-policy random` uses the G3 parity weights instead, which rarely buy hulls.
- Summary per run: `result` (win, loss, unfinished or crashed), `sector`, `battles`, `clicks`, `errors`, `game_s`, plus:
  - `log`: one line per battle (sector, kind, faction, objective, result, rounds, ships left on each side, the fleet going in), to compare with `node sim3d.js campaign`;
  - `pressed` and `offered`: button counts.
  - each battle line's `pace`: the enemy's share of each round in game seconds (`enemy_s_mean`, `enemy_s_max`, `rounds`, `movement`). Measure it at real speed (`--fast 1` with Godot's `--fixed-fps 60`): at `--fast 40` every frame is 40 game frames long and the numbers are noise.
- `--run-timeout S` (default 600 real seconds): a run that overruns prints `[botrun] HANG {...}` with where it stood (page, battle phase, round, flags, idle time), writes the report and quits with exit code 2.

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
- `movement` (`cinematic`, the default, or `brisk`): how ships move (R50, below);
- `taa`: Temporal AA on Max and High (off by default).

The campaign reads them from `main.settings`. A campaign screen changes one with `main.settings[key] = value`, then `main.save_settings()`.

## Headless test: whole runs with both sides on AI

```
godot --headless --path godot -- --bot-runs 50 --fast 40 --report report.json
```

- With the campaign in the build, each run is a full campaign run. Without it, each run is one sector 1 battle.
- The exit code is 0 when every run had 0 errors and 0 softlocks.
- PC job: `tools/pc/jobs/g2_checks.bat`.

## Ship movement (R50)

`ship_view.gd` moves a ship along the rules' path in one of two ways:
- **Cinematic** (default): the main engine builds speed and brakes over a time scaled by mass (frigate 0 to capital 1), the hull swings round on a critically damped spring and banks into the turn (bank and pitch sit on the hull child, never the root, which G4's hit reactions own), a big hull's turn blends into its burn, the ship slides past its hex and settles back, the engines flare through G4's `set_engine` and RCS puffs fire on turns and stops.
- **Brisk**: the earlier motion (eased burn, eased facing).

Pace: the burn takes the same time in both modes; only the burn holds up the battle (`burning()`), and the settle plays on while the next ship acts. `busy()` stays true through the settle and the yaw swing: it tells G4's hit reaction that G2 is steering the ship, so fx adds its yaw kick and drift only once the ship is at rest. Rules outcomes are the same in both modes (checked on the same seed).

## Test and capture switches (after `--`)

| Switch | What it does |
|---|---|
| `--movement cinematic\|brisk` | overrides the setting for this launch |
| `--move-frames <dir>` | the player's biggest and smallest ship each make a long burn with a turn from a fixed camera; a JPG per rendered frame (with Godot's `--fixed-fps 30`) through the settle, a folder per ship |
| `--sheet-check` | builds the ship sheet for every ship on the board and prints `[sheet] N ships` |
| `--title-shot <png>` | the title with its decorative battle faded in, saved, then quit |
| `--window WxH` | an exact window size for capture jobs (the project starts maximised) |
| `--no-showcase` | no decorative battle behind the title |

Every battle result (and each bot-run battle line) carries `pace`: the enemy's share of each round in game seconds (`enemy_s_mean`, `enemy_s_max`). Measure it at real speed (`--fast 1` with Godot's `--fixed-fps 60`).

## Vetoable calls (G2, Oct 27)

Technical calls made without Ryan; any of them can be reversed.
- Movement defaults to Cinematic; the burn takes the same time as Brisk, and only the settle (about 0.5 to 1 s) overlaps the next ship.
- The slide past the hex is about 5% of a hull's length (never under a tenth of a hex); heavy hulls bank up to about 9 degrees, frigates about 15.
- RCS puffs are drawn by the scene in G4's puff colour (G4 has no public puff call).
- Enemy volleys hold the battle for the browser's own volley length at the B2 pace, while G4's longer effects play on over the next volley; your own first volley at normal speed plays in full; a killing volley waits for its impacts; deaths hold half their length at most on the enemy's turn (big hulls 0.8 s at least).
- The title shows a decorative battle on open maps (no belts), Max and High graphics only; the browser's map showcase is not carried over (G3's 3D map replaces it).
- The concept-art hulls toggle is not carried over (Godot has the game hulls only). Temporal AA is a setting, off by default.
- The ship sheet leaves out the enemy reach line (it needs a threat pass per hover; R shows the threat map).
- The ambient bed plays at the browser's levels: room tone 0.032 over the synth bed.
