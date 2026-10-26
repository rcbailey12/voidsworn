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

## Stream B R42 Nemesis v2, R41 arc variants and step 4 (port_notes.md "R42 Nemesis v2" and "Step 4", oracle d8b47c6)

A new identity every run from the faction's own pools (`nemName`, `nemGender`, title, persona, two strength traits, a stored portrait id `nem_<faction>_<1..6>`), faction behaviour (`nemBeh`: clock pace, raid or tithe strikes on the map, flee, revive, feed, fast adaptation, reinforcements, duel, challenge), each logged in `RUN.nem.signatures` (`nemSignature`), scars with their cause (`scarKinds`) and an epithet each (`nemScar`), faction-named adaptations plus a faction special (`nemAdaptName`, `nemAdaptDesc`, `nemAdaptWhy`), what beat him last (`nemBeatOf`, `last_beat`), the Chorus feeding on your losses (`nemFeedLosses`), and the R41 arc hull unlock when he dies for good in sector III (`arcComplete`; arc variants cannot be bought). `cfg.nemesis` now also carries persona, traits, fed, riches, last_beat, g and met for the rules. Step 4 (R49): the weakness pool drops a weakness that cancels a drawn strength; a raid's credits go to `loot` and a towed ship to `held`, both returned when he dies; `gloat` after he beats you, `honed` for the Ithar who flees; the Deathless comeback only in sector III; the arc hull unlocks on any sector III win that does not bring him back; `nemBeatTeach` makes his next adaptation counter what beat him; `nemFoundMerge(B.nemFound)` keeps weaknesses found in battle; his fight uses his faction's fleet archetype; `nemSay` swaps pronouns for a she or an it; `nemWarnLine` says what the next win will do. `cfg.nemesis` also carries gloat, honed and beaten. Battle signatures: the browser's `nemSig` calls the campaign directly; in external battles the campaign records `B.nemSigs` kinds at `finish_battle`, before its own. `test/nem_scenarios.gd` against `test/node/nem_scenarios.js` (`run_nem_scenarios.sh`): the step 4 golden scenarios on the campaign side, identical record by record.

The war-room Nemesis card shows all of it in words (persona, strengths with their effect, his faction's behaviour line, the clock with half steps and its pace, fed, riches, the Deathless comeback, weaknesses and adaptations with their effects, what he remembers), and his face from the stored portrait id with one overlay per scar. The map's danger estimate counts his scars, adaptations, strengths, fed and riches, and the hover card lists what moved the number.

## The story layer (godot/story/README.md)

- Screens: the admiral page, the sector I intro and sector change dialogs and the end page draw `story.campaign_line()`; the admiral card and the war-room panel show `story.titled_name()`; the fleet screen has "Rename flagship" (`story.open_rename()`); Progression has a "Career" tab button (`story.open_career()`); the admiral card shows the face from `godot/portraits/` (painting or crest). All guarded: without `godot/story/` or `godot/portraits/` nothing shows.
- Story arcs, behind a flag: `campaign.arcs_on` (default **false** until Ryan approves the arc text). When on, closing the sector I intro or a sector change dialog opens `arc_source(sector)` (the UI wires `story.arc_beat`) as an event card. Its choice runs the normal `eventFlags` and `applyOutcome`, completes no map node, adds the card's outcome line, saves, and calls `arc_chose_cb(card, key)` (`story.arc_chose`). At the end of a run that played beat 3, `arc_end_cb(won)` (`story.arc_end`). With the flag off, or on with no arc file for the faction, a run is identical step by step: `test/arc_hook_test.gd` checks both, plus the card flow with a test card.

## Rules access and tables

- The campaign reaches the battle rules only through `res://rules/battle_api.gd` (its `JSM`, the shared JS maths and PRNG, and a table-free rules object for the weapon trait effects). No copy of rules code is kept here.
- `load_tables` refuses to start when a table in `REQUIRED_TABLES` is missing, and `test/node/export_campaign.js` fails (exit 1, nothing written) when the oracle lacks any table the campaign scripts read.

## Saves

A fresh Godot save (browser saves are not carried over, R33): `user://voidsworn_campaign.json` plus a backup one save behind (`.bak`). Both are written atomically: whole to a `.tmp` file, flushed and size-checked, then renamed over the old file, so a crash mid-write leaves the old save or the new one, never half a file (`test/save_test.gd`). It holds the profile (`meta`), the saved run and a slim run log. Every non-integer number is written as its exact IEEE hex, because Godot's JSON reader can land one unit in the last place off. A damaged save falls back to the backup; the half that is sound is kept. Set `persist_on = true` and call `persist_load()` at start (the parity harness keeps saves in memory).

## Parity test

- **PC:** double-click `tools\pc\parity_campaign.bat` (also run at the end of `parity.bat`). It plays 30 seeded runs.
- **Linux or the cloud:** `GODOT=/path/to/godot sh godot/campaign/test/run_parity_campaign.sh [first] [last]`.

Node runs the pinned JS files (`test/oracle/`, unchanged) and plays whole runs, title to end screen, with a scripted player that clicks the buttons a player sees (read from the game's own HTML). Godot plays the same runs through `act()`. After every click both write the buttons on screen, the PRNG state and the campaign state in canonical form (run, map, profile, screen transients, the saved copy). `compare_campaign.js` names the first step and field that differ. There is no tolerance: numbers compare as exact doubles. The scripted player also reloads the page now and then (save, load, continue), which tests the save format and the reward-resume path.

What the harness leaves out, on both sides: the decorative title and map showcase battles (in the browser they draw from the rules PRNG, see the G3 report), telemetry, and the browser's back-fill of old run logs.
