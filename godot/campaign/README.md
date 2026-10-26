# Campaign (G3)

The rules of a whole run in Godot: the sector map, shipyards, drydocks, events, rewards and the prize screen (add, strip or ransom), capture, retreat, saves, meta progression (renown, hull variants, admiral mastery, patron favour, Heat) and the run's end. It is a GDScript port of the browser game's `core.js` (run parts), `campaign_run.js`, `campaign_meta.js` and `campaign3d.js`, with the same names, order and maths.

## Files

- `campaign.gd`: the rules and the screen flow, one object.
- `data/campaign_tables.json`: every table the campaign reads, exported from the pinned JS files (`test/node/export_campaign.js`). Nothing is copied by hand. Boon effects and texts, which are code in `data.js`, are evaluated once per rarity.
- `test/`: the campaign parity test (below).

## How the screens work

Every place the JS game calls `show(html)` or `modal(html)`, the port sets:

- `page = {kind, data, acts}` (the full screen), or
- `modal_d = {kind, data, acts}` (a dialog on top; `null` when none).

`acts` lists the screen's buttons in the same order as the browser: `[act, arg, enabled]`. One call makes a click: `campaign.act("enterNode", "2-1")`. Nothing else changes campaign state, so a person, a test or the full-run bot all play the campaign the same way. The signal `changed` fires whenever the page or the modal changes; `toasts` holds short messages for the UI to show and clear.

Screen kinds: `title`, `admiral`, `aspect`, `map`, `fleet`, `shipyard`, `battle`, `legacy`, `help`, `end` (pages) and `intro`, `abandon`, `sell`, `drydock`, `event`, `event_result`, `victory`, `prize`, `salvage`, `mod`, `boon`, `relic`, `promote`, `retreat`, `sector` (modals).

## Battles

A fight node shows the `battle` page. Its buttons are `battle:win`, `battle:partial`, `battle:loss` and, except against a sector flagship, `c3retreat`.

- **Stub mode** (`battle_mode = "stub"`, the default): those buttons resolve the fight with the stub battle (`stub_start`, `stub_resolve`), which the JS harness copies line for line.
- **External mode** (`battle_mode = "external"`): set `battle_setup = func(run, cfg) -> Dictionary` to build the real battle (G1's rules: `startBattle(cfg)` reseeds the shared PRNG from `cfg.seed`, exactly as the game does) and return its `B`. The campaign then rolls the mid-battle event into `B.event` (as the game does after setup), shows the `battle` page and emits `battle_requested` with the config in `pending_battle`. The battle scene plays the fight and calls `campaign.finish_battle(result)` with `"win"`, `"loss"` or `"retreat"` (`can_retreat()` says whether the retreat button is allowed). The campaign reads the units of `B` (the JS field names: `ship`, `hp`, `maxHp`, `dead`, `dealt`, `kills`, `captured`, `killCause`, `killedBy`, `weapons`, `t`) for losses, experience, prizes and wrecks.

## The game shell hand-off

G2's `godot/main/campaign_host.gd` hosts the campaign (contract: `godot/main/README.md`). It creates `campaign.gd` (a RefCounted), sets `battle_mode = "external"` and `battle_setup`, draws the screens with `godot/ui/campaign/campaign_ui.gd`, and plays each battle when `battle_requested` fires.

- `battle_setup(run, cfg) -> B`: the campaign passes `cfg.campaign = true` (the rules roll the mid-battle event right after setup, as campaign3d.js does) and, in sectors at war, `cfg.event_war = true`. Stream B (B4) adds `cfg.nemesis` (the Nemesis fight: name, faction, weaknesses, adaptations, scars) and `cfg.verb` (a next-battle faction action); the rules apply both (`applyNemesis`, `applyVerb`).
- After the fight the host calls `finish_battle("win" | "loss" | "retreat", B)`; the campaign reads the units of `B` for losses, experience, prizes and wrecks, plus (B4) `B.usage` and unit `ev` (what the Nemesis learns), the unit with `nemFlag` (did his flagship die) and wing kills through `parent` (wing veterancy).

## Stream B campaign changes (port_notes.md steps 1 to 3, oracle c7b1a78)

Events with blue options (`needMet`, `needText`, `eventFlags`, no event repeats, 'quiet' once all are seen) and the new outcome kinds; the Nemesis (`newNemesis`, clock, `nemNodeIs` marks his fight on the map, `nemAfterBattle`, `nemLearn`, `nemAdapt` at each new sector); faction actions on the map (`factionVerb`); wing veterancy; legendary boons; boon reroll and decline; class refit tracks at shipyards (`buyTrack`); Corsair prize money; faction gates on prizes and towing. New buttons: `factionVerb`, `boonReroll` (arg `patron:minRarity`), `boonDecline`, `buyTrack` (arg the class name).
- `can_retreat()` says whether the battle may offer Retreat (never against a sector flagship).

## Saves

A fresh Godot save (browser saves are not carried over, R33): `user://voidsworn_campaign.json` plus a backup one save behind (`.bak`). It holds the profile (`meta`), the saved run and a slim run log. Every non-integer number is written as its exact IEEE hex, because Godot's JSON reader can land one unit in the last place off. A damaged save falls back to the backup; the half that is sound is kept. Set `persist_on = true` and call `persist_load()` at start (the parity harness keeps saves in memory).

## Parity test

- **PC:** double-click `tools\pc\parity_campaign.bat` (also run at the end of `parity.bat`). It plays 30 seeded runs.
- **Linux or the cloud:** `GODOT=/path/to/godot sh godot/campaign/test/run_parity_campaign.sh [first] [last]`.

Node runs the pinned JS files (`test/oracle/`, unchanged) and plays whole runs, title to end screen, with a scripted player that clicks the buttons a player sees (read from the game's own HTML). Godot plays the same runs through `act()`. After every click both write the buttons on screen, the PRNG state and the campaign state in canonical form (run, map, profile, screen transients, the saved copy). `compare_campaign.js` names the first step and field that differ. There is no tolerance: numbers compare as exact doubles. The scripted player also reloads the page now and then (save, load, continue), which tests the save format and the reward-resume path.

What the harness leaves out, on both sides: the decorative title and map showcase battles (in the browser they draw from the rules PRNG, see the G3 report), telemetry, and the browser's back-fill of old run logs.
