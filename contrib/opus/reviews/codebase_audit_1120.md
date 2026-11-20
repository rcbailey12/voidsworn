# Codebase audit, Nov 20 2026 (issue 1333)

Read-only audit by an Opus worker of rules parity, saves, battle state and campaign flow. No game code changed. Every finding
below was confirmed by a headless run; the repro scripts are in `contrib/opus/reviews/codebase_audit_1120/`. Base: main at
0ac29b17.

## Answer first

Three confirmed bugs, one of them worth fixing soon:

| # | Severity | What the player sees | Issue |
|---|---|---|---|
| F2 | High | On Standard, every campaign fight is rolled on the Veteran fleet budget (a 22% bigger budget for generated fleets in Sectors 1 and 2, so more or heavier ships). The map's danger bands also read as Veteran. | #1336 |
| F1 | Low to medium | A Chorus run that ate a patron's core can still get a protocol offer from that patron (a weaker offer); the two rules twins disagree. | #1337 |
| F3 | Low | A Sector III fight resumed from a save gets the one-battle story buff (for example +25% flagship damage) a second time. | #1338 |

Everything else I checked held up: battle parity, save round trips under heavy reload stress, bot campaigns with no soft-locks.

## F2 (high): Standard players fight Veteran-sized fleets

- Where: `godot/main/campaign_host.gd:133-138` (`_setup_battle` makes a new `battle_api`, calls `load_rules` and
  `new_battle`, never sets the AI level). `godot/rules/battle_api.gd:191-202` (`new_battle` calls `R.startBattle`, which rolls
  the enemy fleet in `genEnemyFleet`, reading `R.AI_LEVEL`, still the default "veteran"). The level is only set later, in
  `godot/scenes/battle/battle.gd:507-508` (`_api_set_ai(ai_level)`), after the fleet already exists. The settings default is
  Standard (`godot/main/main.gd:21`, `"ai": "standard"`).
- Effect: fleets get `RAMP.vet` 1.1 instead of `RAMP.std` 0.9 (battle.js:160-172), a 22% bigger budget for generated fleets in Sectors 1 and 2 (more or heavier ships: seed 11 has 4 ships both ways, 5 CP against 4);
  Sector III gets 1.1 x 1.25 instead of 0.9 x 1.4 (+9%). The AI then plays at Standard with a Veteran fleet.
- Map side: `godot/ui/campaign/campaign_ui.gd:57` `ai_level := "veteran"` is never set from the settings (the only writer is
  `map3d.gd:167`, which copies it), so the map's danger bands always read Veteran. Also `map_intel.gd:50-53` never applies
  `RAMP.vet` (added by issue 1160), so a real Veteran player's bands read 10% low.
- Repro: `godot --headless --path godot --script <abs path>/repro_ai_level_fleet.gd`. Drives the campaign exactly as the host
  does. Result: 8 of 8 first battles rolled at Veteran. Example: "seed 11: host path rolls at AI_LEVEL=veteran: b_drone x3,
  b_spitter (5 CP) | Standard set first: b_drone x4 (4 CP)". Exit 1 = bug.
- History: first reported as audit C finding 4 (contrib/openai/audit_1118/rules_campaign_ui.md), left report-only and never
  ticketed. Still live on main.
- Fix idea: pass the settings' AI level into `_setup_battle` and set `R.AI_LEVEL` (or a real `set_ai_level`) before
  `new_battle`; feed the same level to `campaign_ui.ai_level`; add `RAMP.vet` to map_intel. Balance note: every Standard
  balance read taken from the Godot game since issue 1160 was really a Veteran-budget read.

## F1 (low to medium): eaten core's patron still offers protocols (Chorus)

- Where: browser `campaign_run.js:769` (`boonStep` moves the offer off `RUN.eatenCore`) and `campaign_run.js:596` (the
  beat-3 story core reward does the same). Godot `godot/campaign/campaign.gd:3396-3399` (`boonStep`) and `:3043-3047`
  (`applyBeat3Outcome` core reward) have no such redirect. Both browser lines landed Nov 17; the port never followed.
- Trigger 1: a Chorus run that ate a core, and a reward whose patron comes from `rewardFlow`'s fallback `pick(RUN.patrons)`
  (`campaign.gd:3219-3220`, eaten core included), for example a Nemesis meeting at a column 4 shipyard.
- Trigger 2: the Chorus ate the "hunger" core, then takes story choice 0 at beat 3 (the core reward is the hunger patron).
- Repro: `node contrib/opus/reviews/codebase_audit_1120/repro_eaten_core_boon.js` gives "offer patron = star"; the Godot twin
  `repro_eaten_core_boon.gd` gives "offer patron = iron". Campaign parity also catches it: extra seed 120 (step 200, boonReroll
  patron star vs iron) at the normal reload rate, and seed 91 (step 254, reward patron rook vs hunger) under the reload stress.
- Effect: the offer is headed by the patron the player gave up, and the twins disagree, so campaign parity on more seeds fails.
- Why the standing check misses it: seeds 1 to 24 never hit it.

## F3 (low): resumed Sector III fight re-grants the spent story buff

- Where: `godot/campaign/campaign.gd:3058-3065` (`_restore_legacy_story_modifier`), called from `_resume_node` at
  `:1876` (battle nodes) and `:1890` (event fights). It rebuilds `RUN.storyNext` from the beat-3 choice flag whenever
  `storyNext` is empty in Sector III. It cannot tell "erased by an old checkpoint" from "already spent by battleScreen", so a
  spent buff comes back. The browser has no such restore (campaign3d.js:73-75 only spends it).
- Realistic path: the Nemesis-cleared column 4 event stop saves right before its fight; quit mid-fight and Continue. Old saves
  that resume at a battle node do the same.
- Repro: `godot --headless --path godot --script <abs path>/repro_story_buff_resume.gd`. Result: "resumed fight at 1-3:
  storyMods = { "power": true }" after the buff was already spent. Exit 1 = bug.
- Fix idea: mark the buff as spent in the run (for example `storyNextSpent`), or only restore when a save version older than
  the checkpoint change is loaded.

## What I ran (all green apart from the three bugs)

- Battle rules parity: `godot/rules/test/run_parity.sh`, all 284 scenarios PASS.
- 400-battle sweep, seed 913 (`run_sweep.sh 400 913`): PASS, 400 of 400 battles identical at every record (77,153 records).
- Campaign parity, extra seeds 25 to 200 at the normal reload rate: only seed 120 differs (F1).
- Save and reload stress: `reload_stress/run.sh` (copies of the campaign parity pair with the reload rate raised to 30% per
  click). Seeds 1 to 120, 9,620 reloads, every run reached its end: only seed 91 differs (F1). The save encoder, float
  round trips, missing keys and mid-reward reloads held up.
- 12 extra seeded bot battles (`bot_battle.gd`, seeds 3 to 777): all PASS.
- Two full bot campaigns (`--bot-runs 2 --seed 4242`): no soft-locks. The only errors were cloud-only (unimported fx
  textures) and `ledger.gd:926` Rect2 negative-size errors from the headless window size, not filed.

## Looked at, not filed

- Battle API player commands that parity never drives (ram, board, ability, order, rotate, command, answer, change_role,
  wing_order, stance): thin wrappers over ported rules functions, no difference found by reading; worth a parity scenario
  set some day, not a bug.
- Chorus text: the Scrap rig and ledger lines say "credits" where Chorus earns biomass. Taste, not a bug.
- Quitting mid-battle returns to the map at the earlier node: the same in both twins, by design.
- Known items not refiled: Artoo's issue 906 list, Neon's Nov 19 health audit (node_added leaks, static caches, timer
  lambdas), audit C findings already fixed by issue 1125.
