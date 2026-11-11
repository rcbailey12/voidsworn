# Briefing campaign map: second capture

Refs #344. Refs #418.

The Briefing layout now runs over the real 3D sector map. Its flat left column holds the numbered routes, one lime Jump
button, the short Nemesis block and the fleet. The map keeps its models, curved routes, starfield and Hollow Sun. Far stops
are smaller and darker, with their words on hover. The selected objective is readable without a sentence ending in dots,
and the red nebula at the right edge is quieter.

## Changes in this finishing pass

- `godot/ui/campaign/campaign_ui.gd`: reserve three 20 px lines for the selected objective instead of two; show the objective
  without ellipsis. If an objective needs more space, keep whole sentences that fit. In the current content only Hold the
  station needs this: its first two sentences fit, and the sentence about its batteries stays in the full hover text.
  The full objective, archetype, modifier, board and strength estimate remain in that tooltip. The column's height budget
  includes the extra 20 px, so the fleet can still tighten or scroll.
- `godot/ui/campaign/map3d.gd`: set the map sky material's `neb_gain` to `BACKDROP_K` (0.5). This halves the baked gas again,
  in addition to the existing 0.5 background energy. Stars retain the existing half-strength setting. This changes the
  campaign map's material instance; battle skies, stop lighting, route materials and the Hollow Sun are unaffected.
- `docs/shots/ui_redesign/briefing/`: 16 Briefing JPEGs at quality 90, 18 extra rollout JPEGs at quality 90, the three reached
  lists, and one before-and-after sheet. Each Briefing image is exactly 1920x1080 or 2560x1440.
- This report. No other source repairs were made in this pass. The larger Briefing build, theme, view readers, test and
  capture modes were already on the helper branch.

## Pictures and provenance

[Before and after](../../../docs/shots/ui_redesign/briefing/before_after.jpg) places
`docs/shots/ui_redesign/rollout1/1080/01_map.jpg` beside the final three-route map at native 1080 size. Its captions disclose
that the before is the opening map and the after is one jump later in the same seeded run.

The PC copies for the Board are under `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-418\shots`:

- [Before-and-after sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-418/shots/before_after.jpg)
- [1080 three-route map](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-418/shots/1080/02_map_three_routes.jpg)
- [1440 three-route map](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-418/shots/1440/02_map_three_routes.jpg)

Both resolution folders contain these same eight views:

| File stem | What it proves |
|---|---|
| `01_map_jump0` | Opening map and first objective |
| `02_map_three_routes` | Three choices, full Relay objective, quieter right edge |
| `02b_route_two_picked` | Second row, marker and Jump button agree; Breakthrough objective fits |
| `03_far_stop_hover` | Far stop's one hover card |
| `03b_nemesis_stop_hover` | Nemesis diamond and meeting sentence |
| `04_dossier` | Full Nemesis information in the slide-over |
| `05_map_key` | Legend, sector information, run information and controls in the slide-over |
| `06_damaged_fleet` | Hurt hull bars, warning and four-ship fleet |

[1080 reached list](../../../docs/shots/ui_redesign/briefing/reached_1080.txt),
[1440 reached list](../../../docs/shots/ui_redesign/briefing/reached_1440.txt), and
[extra rollout reached list](../../../docs/shots/ui_redesign/briefing/reached_rollout1080.txt) all say `not reached: none`.
All 16 Briefing images and the assembled sheet were inspected. The opening, three-route, alternate pick, hover, Dossier,
Map key and damaged-fleet layouts fit at both resolutions.

I ran the Godot steps directly on this checkout, rather than invoking the job's clone/fetch steps, which would discard the
uncommitted repairs. The job file was not changed. The GPU was idle on two checks at least a minute apart, and no fx353
queue job was running. The PC-built `assets/ships` and `gen` folders and import cache were copied from `audit2/repo/godot`.
The final modes were:

```
Godot_v4.7.2-stable_win64_console.exe --path godot --rendering-method forward_plus --windowed --resolution 1920x1080 res://scenes/campaign/campaign.tscn -- briefing <shots>/1080 --no-tips --win 1920x1080
Godot_v4.7.2-stable_win64_console.exe --path godot --rendering-method forward_plus --windowed --resolution 2560x1440 res://scenes/campaign/campaign.tscn -- briefing <shots>/1440 --no-tips --win 2560x1440
Godot_v4.7.2-stable_win64_console.exe --path godot --rendering-method forward_plus --windowed --resolution 1920x1080 res://scenes/campaign/campaign.tscn -- rollout <shots>/rollout1080 --no-tips --win 1920x1080
```

The modes use seed 344 and the campaign's own start, aspect, route, reward and sector actions. Battles in these screen
captures use the existing campaign capture driver's result actions; these are screen captures, not a real battle playtest.
The extra run reached intro, fleet, retreat, victory, salvage, promotion, event, event result, prizes, elite map, boons,
relics, shipyard, flagship map, sector transition and the sector II map.

The checkout starts at helper head `f9f1b3d9` with `origin/main` at `c83737da` merged cleanly using `--no-commit --no-ff`.
No commit or push was made. The runner must commit this final tree; there is intentionally no new capture commit to cite.
The final captures were rerun after the last source edit. Their source SHA-256 values are:

```
campaign_ui.gd b4a1a95509aaf72b558213a409a14a7f91f0b3f954e636c9f13f75b55c1b00e4
map3d.gd       198008bff76d83db944d06e5a156ab4e2abbb92876e3980c0117f168c8a1cc65
```

## Where the old screen's information lives

| Old item | Current home |
|---|---|
| Hostile-presence top card | Sector holder sentence under the title; full holder description in Map key, This sector |
| Sector-condition top card | Header sentence and full wording in Map key, This sector |
| Rival-raiders top card | Map key, This sector; each affected route/card identifies its enemy |
| Cores-in-range top card | Map key, This sector, with the current lore terminology |
| Legend row | Map key, On the map, Stops and Danger against your fleet now |
| Bottom help line | Map key, Controls |
| Map detail and Tips switches | Map key, Settings, in its scroll area |
| Bottom-left fight card | Route rows: name, kind, enemy, danger, reward and destinations; selected objective underneath |
| Long objective, archetype description, modifier, board and strength explanation | Selected objective's hover tooltip; row hover also expands shortened reward/destination lines |
| Far-stop danger tags and name strips | Far-stop hover or keyboard-focus card, with pips and a danger word |
| Faction-coloured names in body text | Plain sage names; the words and faction identity remain |
| Long Nemesis block | Portrait, name, persona and hunt clock in the column; Dossier carries strengths, personality, comeback, weaknesses, adaptations, earlier hunters and meeting rule |
| Old right-panel purse | Credits and command points at the bottom right of the map |
| Old right-panel fleet | Bottom of the briefing column, with short hull bars and numbers |
| Fleet management and refits | Fleet and refits button opens the existing page, including promotions and the hold |
| Faction action and cost | One line below the fleet; full description and used state in Map key, Your run |
| Admiral, aspect, protocols, relics and hold count | Map key, Your run; fleet/refit operations stay on their existing page |
| Run fight count | Map key, Your run, alongside sector and admiral |
| Old route planner and repair warning | Far-stop tip's safest/richest ways on, plus the damaged-fleet warning in the column |

## Muse's three conditions

1. **The view only reads.** The helper's `campaign_view.gd` starts from `C.nemRead()`, then supplies the commander to the
   campaign's existing readers. It guards the absent-commander case instead of falling through to `nemActive()`.
   `map_readonly_test.gd` executes the real views, every route pick, every stop hover, Dossier and Map key. It compares the
   run, saved run, profile, registry, UID and random stream before/after, including a deliberately missing commander.
   Calling `nemActive()` afterward creates that record, proving the test would catch the former render-side write.
   Result: `Map read-only: PASS (24 checks)`. It is listed in `godot_checks.txt` and invoked by `run_nem_scenarios.sh`.
2. **The three bare map detail lines.** The old shape/modifier and reward lines under models are gone from the map overlay;
   those facts now live in the route details or hover card. The IN FLIGHT line remains, drawn with `GS.halo_text`.
   Current-stop and next-jump names also use that halo. The owner-approved map-only exception is recorded in
   `ui_style.md` section 3; other screens keep backed text.
3. **The colour table.** `ui_style.md` section 5 documents BLUE and SHADE. DANGER, STOP and ROUTE are explicitly retired:
   danger uses pips plus words, stops use models, and routes use lime or pale lines. COLUMN, HAIR, ROW_LIT, ROW_HOVER, HALO,
   PALE and PALE_CUT are also documented. No missing constant rows were left for another pass.

## Checks and impact sweep

| Check | Result |
|---|---|
| Baseline `node contrib/opus/tools/run_all_checks.js`, before the repairs | Exit 0; existing KNOWN rows retained |
| Final standing checks with the PC's Node 22.11.0 | Exit 0; 40 PASS, 2 KNOWN, 0 FAIL, 0 SKIP |
| `ui_spec_tests.js` after the final objective edit | `106 checks, 106 pass, 0 fail` |
| Campaign parity, seeds 1 through 30 | All 30 match the root JS oracle after every click; fresh table checksum matches |
| Nemesis scenarios and readers | 219 scenario records identical; `Nemesis read: PASS` |
| Map read-only behavior | `Map read-only: PASS (24 checks)` |
| Map travel regression | `PASS: map reachability, lane states, curves, flight at 30/60/144 fps, arrival and skips` |
| Load every Godot script and scene | `load all: 150 scripts, 11 scenes, 0 failed` |
| Objective layout probe, temporary script outside the repo | PASS: 1,012 stops from 30 real seeded maps, at 1080 and 1440; maximum three complete lines, full objective retained in hover text |
| Rules parity with Node 22 | All 271 battle scenarios match, action by action; three 10,000-draw PRNG streams match; all 316,090 math values match; threat maps s4, s19 and s23 match |
| Worker-thread parity and hard stop | PASS; s4: 958 events identical, s23: 1,998 events identical; hard-stop check PASS |
| GPU capture modes | All three exit 0, no script errors; 8 + 8 Briefing pictures and 18 rollout pages; no missing views |
| Diff whitespace and em-dash scan | Clean |

The two KNOWN standing rows are the unchanged baseline: 16 listed findings failures and 12 constant differences. They are
not reported as passes. The initial rules math attempt used the shell's Node 24.14.0 and found 4,048 pow differences.
The project pins Node 22's V8 12.4 math; using the installed Node 22.11.0 produced
`math 316090 values, differences from Node: none`. No math, rules or test baseline was changed.

On Windows I invoked the Node and Godot commands from `run_parity_campaign.sh`, `run_nem_scenarios.sh` and
`rules/test/run_parity.sh` through temporary Python drivers. The full battle comparison used four independent headless
processes, one output file per scenario. Campaign tables were freshly exported to temp and their checksum compared with
the committed table. All golden records and comparison logs stayed in temp. The UI structure check and standing suite
were invoked directly, not inferred from source inspection.
The full parity driver ended with `PARITY SUMMARY: 0 failures; all 271 battle scenarios; 3 threat maps; threads; final map checks`
and `Failures: []`. The read-only, travel and script-load checks were repeated at its end against the final files and passed.

- **Callers in this pass:** `_map()` builds `_briefing_column()`; the column and `pick_route()` call `_show_pick()`.
  The latter is shared by row clicks/focus, number keys, map hover/click and the capture driver. `_detail_text()` is still
  the full hover source. `_load_sector()` is the only caller of the changed `_build()`; `sync()` reaches it on sector or
  quality changes. Each rebuild sets the same map-only nebula gain before the baked texture arrives.
- **Saves and old profiles:** no save keys, formats or persistence calls changed. The repair changes labels and a material
  instance only. The inherited optional commander parameters in `nemBeh`, `nemNodeIs` and `nemPanelData` let the view read
  without creation; callers that omit them retain the existing resolution path. `nemWarnLine` uses the supplied commander.
  Read-only behavior and campaign parity cover the affected records and saved copies. Capture persistence stays off.
- **JS and Godot twins:** the JS oracle and both data tables are unchanged in this finishing pass. The inherited Godot
  reader API has extra optional parameters for the UI; its default action paths retain the browser's behavior. The
  campaign and Nemesis comparisons above check that distinction. There are no new rules or save-format requirements.
- **UI paths:** opening map, first pick, second pick, far hover, Nemesis hover, both overlays, damaged fleet, fleet/refits,
  shipyard, every reached between-battle page and sector change were exercised by the existing modes/tests. Selection
  callbacks and keyboard bindings were read in the source; no claim of a manual keyboard playtest is made. The backdrop
  behind other campaign pages shares the repaired map material. The battle world creates its own sky material.
- **Test registration:** no new test script was added under `godot/**/test/`. The inherited read-only test already has its
  CI list entry. The temporary objective probe ran from the temp folder and is not part of the delivery.

## Differences from option C

The mockup uses glyphs, straight sketch routes and an outlined black-hole symbol. The build deliberately retains the real
models, curved flight paths, accretion disc, nebula and stars, as Ryan requested. Seed 344 supplies actual enemy archetypes,
rewards, hull values, credits and a fractional hunt clock rather than the mockup's sample values. Its real sector has seven
jumps; the mockup's eight is not forced onto the game.

The full sector-condition wording wraps to three header lines. The selected objective gets up to three lines between the
route list and Jump, so the button and Nemesis block sit lower than the sketch. Those are the brief's retained facts and
the Board's explicit clipping repair. The fleet remains at the foot of the column. Far-stop cards include route and reward
information beyond the sketch's minimal example so the old planner's facts remain available.

## Limits and cleanup

No manual gameplay session, packaged playtest build, movie, new design or full unrelated GPU test pack was requested or run.
The existing deterministic screen drivers provide the captures. Local non-elevated Godot checks printed sandbox log-file
and certificate-store warnings; the authorized capture/parity runs used the PC normally. Import re-saves of tracked
`.import` files were restored, and newly generated untracked import sidecars were removed inside this checkout only.
Nothing outside the checkout was deleted. Logs and temporary drivers remain in the temp folder, not the repo.
