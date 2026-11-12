# Destruction probe extension and ram Monte Carlo (issue 234, S-B and S-C)

Seat: DeepSeek workhorse. Branch: work/issue-234-deepseek. Date: Nov 12 2026. Checkout: main at 8502d6d.
Report only: no game code, rules, save or UI file changed. The one-time probe and plot scripts live under this folder.

Source briefs: the destruction audit record (`contrib/muse/reviews/destruction_audit_2026_11/`), the G3 campaign harness
(`contrib/muse/tools/montecarlo/`), and issue 212 S-B and S-C. The gate is R116: 12.5 ms, 75 percent of a 16.7 ms frame.

## Answer first

- S-B, wreck cap (DS1, DS2): the visual wreck list is capped at 24. A 20-ship board wiped completely leaves 20 wrecks, 4
  under the cap. A 30-death stress hit 24, kept the newest 24 and evicted the oldest. Set-piece wrecks do NOT share the
  list: they are terrain hulks built by `godot/world/blocker_visuals.gd` and never enter `fx.dstate["wrecks"]`. The rules
  hulk list is separate and uncapped, so the DS1/DS2 mismatch remains: after 24 visual wrecks an old visual wreck can
  disappear while its rules hulk stays as an invisible blocker.
- S-B, physics step (DS4): at the shipped 360-body cap the step is 0.400 ms median, 3.20 percent of the R116 gate. At the
  doubled count of 720 bodies it is 0.785 ms, 6.28 percent. At damp 0.3 the same counts read 0.463 ms and 0.927 ms. Physics
  step is not the binder at either count. The 360 cap cannot be justified by physics step cost from this probe.
- S-B, collider cost (DS15): a convex hull collider adds 0.124 ms at 360 bodies and 0.361 ms at 720 bodies per frame. The
  one-time collider build is the larger number: 1.42 ms per piece from a 900-point hull to at most 50 points, on the cut's
  worker thread. The accuracy side of DS15 is not measured here.
- S-C, ram damage (PF4): no matchup one-shots a full-health ship. The 40 percent cap holds in every cell of the 110,592-cell
  matrix. Against a target already at 40 percent hull, a ram kills same or lighter classes often (about 27 to 30 percent)
  and heavier classes rarely (0 to 4 percent). PF4 KEEP.
- S-C, recoil (PF5): recoil is real but rarely fatal: 24.6 percent of the attacker's hull on average and a 6.6 percent
  attacker death rate in 2,665 landed rams. Frigates pay 42.8 percent recoil and die 13.9 percent of the time. The ithar
  sliver (30 hull) can die to recoil even at full hull in the worst matchup (32 recoil). PF5 KEEP.
- S-C, appetite (PF6): the AI takes 59.7 percent of ram opportunities, 0.81 rams per battle. Ram factions pass 82 to 84
  percent of their opportunities at the 30 percent band; other factions pass 31 to 34 percent at the 45 percent band. Only
  13.5 percent of ram decisions are kill decisions. The damage rule is finisher-shaped, but the AI usage is opener-shaped.
  PF6 RE-DERIVE.

## S-B wreck count against the 24 cap (DS1, DS2)

Code facts, read at this checkout:

- `godot/fx/fx_death.gd:2418 _cap_wrecks` keeps `fx.dstate["wrecks"]` at 24 by popping the oldest.
- `_break_up` (`fx_death.gd:2214`) and `_hulk` (`fx_death.gd:2047`) append one visual wreck per death.
- The rules hulk is `B.terrain[...] = "hulk"` (`battle.js:1237`, twin `godot/rules/rules.gd:3574`) and blocks movement and
  line of fire. It is not the visual wreck list.
- Set-piece wrecks are terrain cells and world visuals: `godot/world/blocker_visuals.gd:29` builds a `hulk` visual from
  `hulk_fallback` (`:147`). Nothing on that path appends to `fx.dstate["wrecks"]`.

Probe: `destruction_wreck_probe.gd` staged 30 deaths on mixed cruisers, battleships and frigates. The wrecks kept after
each death were:

```
1, 2, 3, 4, 5, 6, 7, 7, 9, 10, 10, 12, 13, 13, 15, 16, 16, 18, 19, 19, 21, 22, 22, 24, 24, 24, 24, 24, 24, 24
```

The plateaus at 7, 10, 13, 16, 19 and 22 are deaths whose cuts had not all produced a wreck in the same beat; the final
list has 24 entries, ids 6 to 29, and the six oldest ids are gone. The JSON is `wrecks.json`; the plot is
`plots/wreck_cap.png`.

Worst-case arithmetic. The battle-size ramp (B2, `battle.js:144`) targets about 10, 14 and 20 enemy ships on board with a
4 to 7 ship player fleet (wings not counted). A one-side wipe is at most 20, 4 under the cap. The all-sides extreme is 27
wrecks, which hits 24 and recycles 3. A reanimated or otherwise twice-killed ship can also add a second wreck in a smaller
battle; the cap then recycles the oldest. The cap is a visual recycling rule, not a hard battle-size limit.

DS1/DS2 read: set-piece wrecks do not share the list. The visual list and the rules hulk list are independent, so the
visual cap does not free a blocking hex. That is the DS2 mismatch the audit named, unchanged by this probe. The DS1/DS2
rulings ride S-A's owner review per the brief.

## S-B physics step across the body matrix (DS4)

Method: `destruction_cost_probe.gd`, headless, Jolt, `--fixed-fps 60`. Bodies use the game's wreck settings: gravity off,
altitude locked, layers 1 and 2, bounce 0.4 and friction 0.4, damping REPLACE. Colliders are the game's `safe_convex`
collider from a 900-point hull, at most 50 points. A run warms up for 60 physics frames and measures 300 frames. The time
is the wall time between physics frame signals at a fixed 60 Hz step; the empty-scene baseline is 0.004 ms. Counts are 50
to 500 plus 360 (shipped cap) and 720 (doubled, uncapped). Full data is `physics.json`; the plot is
`plots/physics_step_vs_bodies.png`.

| bodies | damp | median ms | p95 ms | median % of 12.5 ms | p95 % of 12.5 ms |
|---:|---:|---:|---:|---:|---:|
| 50 | 0.0 | 0.150 | 0.189 | 1.20 | 1.51 |
| 100 | 0.0 | 0.197 | 0.231 | 1.58 | 1.85 |
| 150 | 0.0 | 0.237 | 0.286 | 1.90 | 2.29 |
| 200 | 0.0 | 0.266 | 0.336 | 2.13 | 2.69 |
| 250 | 0.0 | 0.313 | 0.395 | 2.50 | 3.16 |
| 300 | 0.0 | 0.350 | 0.447 | 2.80 | 3.58 |
| 350 | 0.0 | 0.395 | 0.517 | 3.16 | 4.14 |
| 360 | 0.0 | 0.400 | 0.525 | 3.20 | 4.20 |
| 400 | 0.0 | 0.450 | 0.575 | 3.60 | 4.60 |
| 450 | 0.0 | 0.497 | 0.648 | 3.98 | 5.18 |
| 500 | 0.0 | 0.545 | 0.696 | 4.36 | 5.57 |
| 720 | 0.0 | 0.785 | 0.992 | 6.28 | 7.94 |
| 50 | 0.3 | 0.159 | 0.191 | 1.27 | 1.53 |
| 100 | 0.3 | 0.210 | 0.243 | 1.68 | 1.94 |
| 150 | 0.3 | 0.254 | 0.291 | 2.03 | 2.33 |
| 200 | 0.3 | 0.300 | 0.347 | 2.40 | 2.78 |
| 250 | 0.3 | 0.347 | 0.411 | 2.78 | 3.29 |
| 300 | 0.3 | 0.402 | 0.469 | 3.22 | 3.75 |
| 350 | 0.3 | 0.459 | 0.554 | 3.67 | 4.43 |
| 360 | 0.3 | 0.463 | 0.566 | 3.70 | 4.53 |
| 400 | 0.3 | 0.524 | 0.608 | 4.19 | 4.86 |
| 450 | 0.3 | 0.576 | 0.660 | 4.61 | 5.28 |
| 500 | 0.3 | 0.631 | 0.736 | 5.05 | 5.89 |
| 720 | 0.3 | 0.927 | 1.049 | 7.42 | 8.39 |

DS4 read: at 360 the step spends 3.2 percent of the R116 gate; even the doubled, uncapped 720 bodies spends 6.3 percent
damp 0.0 and 7.4 percent damp 0.3. The worst p95 in the matrix is 1.049 ms, 8.39 percent of the gate. The step curve says
the 360-body cap is not load-bearing for physics cost. If a binder exists at 360, it is elsewhere: rendering, material
updates, draw calls or the death preparation work, none of which this probe measures. This curve should feed issue 207's
scene family as the physics half it does not currently separate. DS4 re-derives the cap's rationale: keep the cap if
another system needs it, but not for physics step.

## S-B collider cost against body count (DS15)

| bodies | damp | convex median ms | no-collider median ms | delta ms | delta per body |
|---:|---:|---:|---:|---:|---:|
| 50 | 0.0 | 0.150 | 0.135 | 0.015 | 0.30 us |
| 100 | 0.0 | 0.197 | 0.156 | 0.041 | 0.41 us |
| 200 | 0.0 | 0.266 | 0.212 | 0.054 | 0.27 us |
| 300 | 0.0 | 0.350 | 0.253 | 0.097 | 0.32 us |
| 360 | 0.0 | 0.400 | 0.276 | 0.124 | 0.34 us |
| 400 | 0.0 | 0.450 | 0.294 | 0.156 | 0.39 us |
| 500 | 0.0 | 0.545 | 0.333 | 0.212 | 0.42 us |
| 720 | 0.0 | 0.785 | 0.424 | 0.361 | 0.50 us |
| 360 | 0.3 | 0.463 | 0.279 | 0.184 | 0.51 us |
| 720 | 0.3 | 0.927 | 0.404 | 0.523 | 0.73 us |

At 360 a box collider reads 0.305 ms against 0.400 ms for the 50-point convex hull, so the convex hull adds about 0.095 ms
per 360 bodies. The one-time build cost is 1.42 ms per piece (900 points to at most 50 extreme points), and it runs on the
cut worker thread. Per frame the colliders are cheap: 0.34 us per body at 360. DS15's accuracy side, the roughly 7.2-degree
sample spacing on a long hull, is not measured here; it needs a close-range piece capture or a geometry comparison. The
cost side says collider shape is not the reason to keep the 360 cap.

## S-C ram Monte Carlo (PF4, PF5, PF6)

Method: `ram_montecarlo.js` loads the shipped game through the G3 campaign harness (Muse's unmodified baseline driver,
veteran AI, baseline policy) and instruments the existing `tacticRam` and `ramUnit` bindings in memory. No game file is
changed. 300 runs were played, 50 per faction, seeds 234000 to 234049: 3,294 battles and 14,538 rounds. A second identical
batch differed by 2 battles out of 3,294 and 2 opportunities out of 4,456, so treat the counts as plus or minus a few.

The same script also builds an exhaustive `ramEstimate` matrix over all 48 non-squadron hulls: 110,592 cells covering run-up
1, 2 and 3 or more, the four shield quadrants, shields on and off, and the target at 100 and 40 percent hull. Baseline hulls,
no boons, no tree skills. Full data is `ram_outcomes.json`; plots are `plots/ram_damage_by_class.png`,
`plots/ram_recoil_by_class.png` and `plots/ram_appetite.png`.

### PF4 ram outcomes by matchup

No cell one-shots a full-health ship: every damage value is capped at 40 percent of the target's full hull, and the matrix's
kill rate at full health is 0 in every class matchup. At 40 percent target hull the kill rate depends on the class pair.
Selected rows from the class matrix (damage as percent of target max hull; kill rate at 40 percent target hull):

| attacker -> target | mean damage | kill at 40 percent |
|---|---:|---:|
| Frigate -> Frigate | 40 | 27.3 |
| Frigate -> Cruiser | 25 | 3.7 |
| Frigate -> Battleship | 12 | 0.0 |
| Destroyer -> Destroyer | 38 | 29.9 |
| Destroyer -> Cruiser | 29 | 8.9 |
| Cruiser -> Frigate | 40 | 27.8 |
| Cruiser -> Cruiser | 33 | 17.7 |
| Cruiser -> Battleship | 17 | 0.0 |
| Battleship -> Frigate | 40 | 27.8 |
| Battleship -> Battleship | 20 | 0.0 |
| Dreadnought -> Cruiser | 39 | 43.5 |
| Bio-titan -> Cruiser | 40 | 44.9 |

The 40 percent cap is the binding rule on every healthy target. Ramming a healthy ship is a heavy hit, not a kill. Ramming
a damaged same or lighter class is a finisher. PF4 KEEP: the arithmetic matches the stated intent ("rams hit hard but
cannot one-shot a healthy ship").

### PF5 recoil outcomes

Observed in the 2,665 landed campaign rams: mean recoil 14.8 hull, 24.6 percent of the attacker's max hull; 6.6 percent of
rammers died later in the same action. By attacker class:

| attacker class | landed rams | mean recoil, percent of own hull | attacker death rate |
|---|---:|---:|---:|
| Frigate | 771 | 42.8 | 13.9 |
| Destroyer | 1,064 | 23.5 | 5.1 |
| Cruiser | 627 | 9.8 | 1.6 |
| Carrier | 84 | 9.5 | 3.6 |
| Battleship | 53 | 7.6 | 1.9 |

The recoil formula uses 0.35 for RAM_FAC factions (voidsworn, corsair, chorus) and 0.5 for the others, a 30 percent
asymmetry at the same size and armor. The matrix shows the same shape: a Frigate attacker pays about 61 percent of its own
hull against a super-dreadnought or ark, while a Cruiser attacker pays about 25 percent. The worst cell is the ithar
sliver (i_wisp, 30 hull, no armor) ramming a cruiser at run-up 3: 32 recoil, 107 percent of its own hull, so the lightest
frigate can die to recoil even at full health. That is the intended risk, not a broken constant: the RAM_FAC factions pay
30 percent less, and the heavier classes pay single-digit percentages. In the observed campaign rams the risk is
concentrated in frigates (13.9 percent death) and is 1.6 percent for cruisers. PF5 KEEP.

### PF6 ram appetite counts

| faction | opportunities | threshold passes | pass rate | landed |
|---|---:|---:|---:|---:|
| chorus | 747 | 629 | 84.2% | 629 |
| corsair | 745 | 620 | 83.2% | 620 |
| voidsworn | 889 | 729 | 82.0% | 729 |
| hegemony | 678 | 232 | 34.2% | 232 |
| deathless | 671 | 225 | 33.5% | 225 |
| ithar | 734 | 230 | 31.3% | 230 |
| total | 4,464 | 2,665 | 59.7% | 2,665 |

The three RAM_FAC factions use the 30 percent band and pass 82 to 84 percent of their opportunities. The other three use the
45 percent band and pass 31 to 34 percent. The threshold bands split as: kill 361 (13.5 percent), ram faction 30 percent
1,794 (67.3 percent), other 45 percent 510 (19.1 percent). By side, 1,318 enemy rams and 1,347 player rams landed. That is
0.81 rams per battle and 0.183 per round. PF6 RE-DERIVE: the thresholds are set from counts now, and the 30 percent band is
the reason ram factions ram almost every time the geometry allows.

### Finisher or opener

The damage rule is a finisher: the 40 percent cap means no full-health one-shot, and a ram kills only a target that is
already damaged (or a lighter class at 40 percent hull). The AI's use of it is not a finisher. Only 13.5 percent of ram
decisions are made because the estimate kills; 67.3 percent are made because the estimate reaches 30 percent of the
target's current hull. The average target is at 77.1 percent hull when the ram lands, the average hit is 39.2 percent of
the target's max hull, and only 12.2 percent of landed rams kill. In plain words, ramming as shipped is a heavy attrition
opener in AI hands and a finisher only against damaged targets. PF4 and PF5 (damage and recoil constants) keep the stated
intent and stay KEEP. PF6 (the appetite thresholds) contradicts the finisher usage and is the item to re-derive. If the
owner wants rams to read as finishers, tighten the 30 and 45 percent bands toward the kill condition; the 30 percent band
is the one that opens fights.

## What this report changes and what it does not

No game code, rules table, save field or UI value changed. The new files are the report, its JSON, its plots and the
one-time probe scripts. The probe scripts are not added to `contrib/opus/tools/run_all_checks.js` and are not CI tests:
the physics and wreck probes need Godot, and the ram Monte Carlo plays 300 campaigns. They are reproducible by hand from
this folder (see below). GitHub runs the existing standing checks, rules parity and campaign parity, exactly as before.

## Reach checks

- Callers: no function, constant or save field was changed. Searched the whole repo for the names used by the probes:
  `ramEstimate` (battle.js:1145, called by `ramUnit`, `tacticRam`, `ramSetup` and sim3d), `tacticRam` (battle.js:1204,
  bot.js:24, sim3d.js:102, godot/rules/test/node/golden.js:116), `ramUnit` (battle.js:1149, ui3d.js:525, sim3d.js:272
  and 333), `_cap_wrecks` (fx_death.gd:2418, called at 2048 and 2215), `fx.dstate["wrecks"]` (fx_death.gd and fx.gd).
  The G3 instrumentation reassigns `tacticRam` and `ramUnit` inside the harness copy in memory only.
- Saves: no profile or run save field added or changed. The G3 harness starts from `defaultMeta()` and `newRun()`; the
  standing checks `save_fuzz`, `free_exit_tests`, `shadow_xp_tests` and `progression_telemetry_test` passed, including
  their old-save cases. A pre-change profile or run save loads as before because the save schema and save code are
  untouched.
- Twins: no root JS rules and no Godot rules changed, so no table re-export was needed. `oracle_copy_test` passed (both
  committed tables equal a fresh export from the root game files). Rules parity passed; campaign parity passed 30 of 30
  with the cross-twin save hand-off.
- UI: no UI value changed. No screen reads a new value. The campaign map, intel, panels and HUD are untouched.
- CI: no new test file was added to `contrib/opus/tools/run_all_checks.js`. The new scripts are one-time probes and plot
  builders under `docs/shots/destruction_probe_2026_11/tools/`. GitHub runs the existing standing checks, rules parity
  and campaign parity (the three jobs in `.github/workflows/checks.yml`).

## Checks run

Standing checks, `node contrib/opus/tools/run_all_checks.js`:

```
PASS: exit 0 (all rows; oracle_copy_test PASS)
KNOWN: 7 listed failure(s): KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5
KNOWN: 12 constant difference(s) within the baseline
```

Relevant PASS rows from the same run:

```
oracle_copy_test | PASS | 0.22 | PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files
save_fuzz | PASS | 0.10 | PASS: exit 0
free_exit_tests | PASS | 0.17 | PASS: 32 free exits across moon, tomb, haven, every eligible faction, zero and 120 credits, return to map and save.
shadow_xp_tests | PASS | 0.09 | PASS: quarter and heir half rates, both debriefs, saves, faction scope and lossless capped XP.
progression_telemetry_test | PASS | 0.12 | PASS: simulated batch medians per line, old saves, #122 rates read, and the Godot twin.
```

Parity, `cmd.exe //c "tools\\pc\\parity.bat nopause"`:

```
PASS: the Godot port matches the game's rules exactly.
PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.
```

Physics probe, `destruction_cost_probe.gd` (headless, `--fixed-fps 60`): exit 0, 50 rows written.

Wreck probe, `destruction_wreck_probe.gd` (windowed, `--fixed-fps 60`): exit 0.

```
WRECKPROBE deaths=30 cap=24 max=24 final=24
```

Ram Monte Carlo, `ram_montecarlo.js --runs 50 --seed 234000`:

```
RAM_MC runs=300 battles=3294 rounds=14538 opportunities=4464 pass=2665 landed=2665 failed=0 matrix_cells=110592
RAM_MC by_fac_opp={"corsair":745,"hegemony":678,"voidsworn":889,"deathless":671,"chorus":747,"ithar":734} by_fac_pass={"corsair":620,"hegemony":232,"voidsworn":729,"deathless":225,"chorus":629,"ithar":230}
RAM_MC actual_rams=469 wrote ...ram_outcomes.json
```

The 469 is the number of distinct matchup rows in `actual_rams.by_matchup`; the underlying landed ram count is 2,665.

## What was skipped and why

- DS15 accuracy (the 50-direction sampling error on long hulls): needs a close-range death capture or a geometry test,
  not a cost probe. The cost side is reported.
- Renderer, material, draw-call and death-preparation cost at 360 and 720 bodies: not measured. The R116 gate is a frame
  gate and this probe isolates the physics step; the report states only the physics share.
- GPU timing and the 4K half of R116: not measured; this is a CPU physics probe.
- The controlled bodies are convex wreck pieces with the game's collider and body settings, not live battle meshes. The
  probe deliberately reuses a 16-shape pool for the step sweep; the one-time per-piece build is measured separately.
- Headless was not used for the wreck probe: `fx.warmup` awaits `RenderingServer.frame_post_draw`, so the probe ran with a
  window. The physics probe runs headless.

## Files

```
README.md
physics.json
wrecks.json
ram_outcomes.json
ram_matrix_extremes.json
plots/physics_step_vs_bodies.png / .svg
plots/collider_cost_vs_bodies.png / .svg
plots/wreck_cap.png / .svg
plots/ram_damage_by_class.png / .svg
plots/ram_recoil_by_class.png / .svg
plots/ram_appetite.png / .svg
tools/destruction_cost_probe.gd
tools/destruction_wreck_probe.gd
tools/ram_montecarlo.js
tools/make_plots.py
tools/make_plots.js
```

The six PNGs are also copied into the run's `out/shots` folder for the reviewer.

## How to rerun

The two GDScript probes preload `res://` game scripts, so copy them into `godot/fx/test/` first (they are kept under
`tools/` so the report does not add a test file to the game). If the checkout has no imported textures yet, run the
Godot `--import` once before the wreck probe; it may touch `.import` files, so revert those if the tree must stay clean.
Run the physics probe headless and the wreck probe with a window:

```
set PHYSPROBE_JSON=%TEMP%\physics.json
Godot_v4.7.2-stable_win64_console.exe --headless --path godot --fixed-fps 60 --script res://fx/test/destruction_cost_probe.gd

set WRECKPROBE_JSON=%TEMP%\wrecks.json
Godot_v4.7.2-stable_win64_console.exe --path godot --fixed-fps 60 --script res://fx/test/destruction_wreck_probe.gd
```

The ram Monte Carlo and the plots run from this folder:

```
node tools/ram_montecarlo.js --runs 50 --seed 234000 --out ram_outcomes.json
node tools/ram_montecarlo.js --matrix-only > ram_matrix_extremes.json
python tools/make_plots.py
```

`tools/make_plots.py` writes the PNGs (with text); `tools/make_plots.js` writes the vector SVGs. The PNGs here are the
ones to read if the SVG viewer has no Consolas font.
