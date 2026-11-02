# First-run teaching cards

Implemented CODEX_TASK.md items 1-8 and 10 in this folder. No commit. Item 9
was skipped as Ryan ruled. All approved card bodies are kept verbatim in
tools/onboarding_cards.json, the browser TIPS table, and the Godot card tables.

## Changes by build-list item

| Item | Change | Main locations |
| --- | --- | --- |
| 1 | Reordered and timed battle cards; corrected Brace; retired start and turns without resetting saved history. | godot/scenes/battle/battle.gd:57, :1134, :2959, :4071; ui3d.js:642; godot/ui/campaign/campaign_tips.gd:22 |
| 2 | Added reinforce_warn, using the real scheduled event one round before arrival and the run's arrival history. | godot/scenes/battle/battle.gd:4086; godot/rules/battle_api.gd:578 |
| 3 | Action cards retire on completed rules events or completed turn handling, even if never shown. Dismissal alone leaves them eligible next battle. | godot/scenes/battle/battle.gd:4037, :4057, :2658, :2698, :2933 |
| 4 | One shown card per activation, one pending condition, no queue of later conditions. Returning to an earlier selection cannot show a second card in that activation. | godot/scenes/battle/battle.gd:4071 |
| 5 | Small campaign helper reads and merges battle_opts.json and uses the existing HUD card. Speed and other saved fields survive. | godot/ui/campaign/campaign_tips.gd:22, :51, :60 |
| 6 | Map, reward, shipyard, drydock, field-repair stop, summary and admiral-screen hooks. See the c_tree limitation below. | godot/ui/campaign/campaign_ui.gd:281 |
| 7 | First enemy Hegemony, second Hullbreakers; first field open with one connected edge feature; no first-fight event; guaranteed second-fight enemy arrival. Updated map preview, both ports, both relevant oracles and campaign tables. | campaign3d.js:47; core.js:273, :322; battle.js:26, :209; godot/campaign/campaign.gd:775, :942, :2487; godot/rules/rules.gd:482, :681 |
| 8 | Teaching tips switch in battle options and the map fleet column; title setting reads the same flag; each card has Turn off all tips. Existing capture overrides still win. | godot/scenes/battle/battle.gd:3418, :4118; godot/ui/campaign/campaign_ui.gd:658; godot/main/title.gd:292, :427; godot/main/main.gd:215; godot/ui/battle/hud.gd:1178 |
| 9 | Not implemented, per R74. | No idle timer or re-arm was added. |
| 10 | Battle shows, dismissals and action retirements in the F1 log; campaign shows and dismissals in existing telemetry. Reporter counts both and still accepts older logs. | godot/scenes/battle/play_log.gd:25, :82; godot/ui/campaign/campaign_tips.gd:94; contrib/opus/tools/playlog_report.js:53, :92 |

## Final card schedule

This is the approved list order. Campaign cards appear at their screens, so the
first map and clock cards are read before the first battle. Every card is once
per profile after retirement. An uncompleted action card can return in a later
battle. Eligible cards respect the activation and screen spacing rules.

| # | ID and title | First eligible moment |
| --- | --- | --- |
| 1 | select: Moving and facing | First battle hand-over, before moving. Returns on later hand-overs until the movement, facing or Brace action is completed. |
| 2 | target: Firing | An enemy enters any available player ship's firing set. |
| 3 | fired: Taking turns | First resolved player shot, including a torpedo launch. |
| 4 | move: Shields and hull | First completed enemy activation. |
| 5 | threat: Threat map | Round 2 begins. |
| 6 | reinforce_warn: More ships are coming | One round before the first scheduled reinforcement, starting in battle 2. |
| 7 | close: Close action | Selected ship can ram or board, starting in battle 2. |
| 8 | resolve: Admiral's Command | Command ready, starting in battle 3. |
| 9 | objective: Objectives | Non-rout objective, starting in battle 3. |
| 10 | c_map: The sector map | First map opening without another campaign dialog over it. |
| 11 | c_clock: The Nemesis clock | c_map dismissed on that map, or the next eligible map opening. |
| 12 | c_reward: Rewards | First victory/reward dialog. |
| 13 | c_shipyard: Repair and refit | First shipyard, drydock or field-repair stop. |
| 14 | c_loss: The next run | First run summary. |
| 15 | c_tree: Your admiral's skill tree | Admiral setup with spendable XP. Currently dormant; see below. |

## Tests

- Rules parity PASS: 50 scenarios, including new s49 and s50, with every action,
  activation, round, state hash and PRNG state compared.
- Standing PRNG, 316,090 math inputs, three threat maps and both thread tests PASS.
- Campaign parity PASS: all 30 seeded runs, every click and PRNG state identical.
- Focused onboarding checks PASS, including reload checkpoint preservation,
  battle counting across bosses and sectors, action retirement, spacing, shared
  preferences and logging.
- Every changed or added .gd parsed headless. JS syntax and reporter tests PASS.
- All 135 non-TIPS campaign tables are unchanged, including budget, hull and
  weapon values. Existing NaN guards remain; invalid saved speed falls back safely.
- Additional 50-seed first-field check: a connected edge feature remains in every
  tested opening. The existing spawn-safety clearing can trim its three cells.
- All 15 actual HUD card widgets rendered on the RTX 5080 at 1920x1080; no clipped
  text or buttons. The real map column's switch was also captured.

The project oracle is Node 22.11.0 and Godot 4.7.2. System Node 24 uses different
Math.pow results and is not a compatible oracle runtime. The supplied batch
runner chooses the bundled Node 22. Godot emitted the environment's root
certificate-store notice; there were no unexpected script errors in final checks.

Full proof summary: tests.txt. Generated detailed logs and states stay in the
ignored .onboarding_checks folder. Godot APPDATA was redirected there; the real
player profile was not used.

Double-click RUN_ONBOARDING_CHECKS.bat for the full checks, or
RUN_ONBOARDING_SHOTS.bat for card captures. Both operate in this checkout.

## Screenshots and verdict

- shots/before_after.png compares the old and new select card with the actual HUD.
- shots/all_cards.png shows the complete approved copy and off links.
- shots/campaign_map_toggle_1080.png shows the real map fleet column and switch.

Pick: keep this layout. All copy and both buttons fit. The card uses the existing
HUD design. These are card-widget and campaign-column captures from this small
checkout, which omits the full battle art bundle; they are not full battle shots.
The skill-tree card is force-rendered only in the isolated visual check.

## Technical calls, open to veto

- Keep all shipped IDs. start and turns are recorded retired, and never displayed.
- Completed move or facing change or Brace retires select; a resolved shot retires
  target; End ship, Next ship or automatic activation completion retires fired;
  a resolved ram or boarding attempt retires close. Previews and rejected commands
  never count.
- Preserve an existing run's teaching count using its prior won-battle count as a
  starting point. New runs count distinct fights, including bosses and later
  sectors. Retries keep their identity. Persist only this new history into the
  existing saved checkpoint, without advancing the saved position into a fight.
- c_tree is wired to an admiralXPToSpend capability. This checkout has automatic
  mastery but no spendable admiral XP or skill-tree implementation. Showing the
  approved card for mastery would teach an unavailable action. The card remains
  dormant until that prerequisite exists; no progression gameplay was added.

No other requested item remains undone. No executable was exported and nothing
was committed.
