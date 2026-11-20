# Eclipse loose ends: plan (issue 1419)

Opus worker thread, Nov 20 2026. Refs #1419. A plan, not a build.

## Ryan's answers (Nov 20 2026, 22:17 UTC, project chat)

The coordinator asked: "2. Eclipse battleship: it was ruled in long ago but never started. Do you still want it? My pick is
yes, after the current ships land. 3. Eclipse colors: the rim is written as green and the weapons as violet, from picks on
different days. My pick is all violet, to match the deaths and the color file." Ryan: "yes on 2 and 3, agree with you".

So: (a) Eclipse is all violet, no green on the hulls. This replaces his Nov 10 green corona line and the green in R237 and
R243 for colour only; everything else in those rulings (light not paint, thin uneven line, even panels) stands. (b) The
Eclipse battleship (R63, d_totality) is still wanted, after the current old-ship replacements land (R328, R368).

The Board records both in FINDINGS. The playbook lines are in this PR (factions.md Eclipse, ships.md "The Eclipse paint").

## Where things stand

- Effects are already violet: godot/fx/faction_looks.json `deathless` (engines, bolts, damage glow, deaths since PR 1400).
- The only green left in that file is `weapon_core`, the Doom gun's core (R263). "All violet" was asked about the rim, so it
  is kept and flagged below, not changed.
- The four installed Eclipse hulls (E11 D22_23, E12 D21_23, E13 D9_23, E14 D20_23) were baked with a green corona and green
  core by tools/blender/kits/eclipse/stack.py. They show green in game until rebaked.
- The three variants d_scythe_s (E13), d_jackal_h (E14), d_harvester_t (E12) have their parts and recipe JSONs
  (issue 812: tools/recipe/ships/deathless_E13_sentinel.json, deathless_E14_guard.json, deathless_E12_turreted.json), proved
  as unbaked geometry only. Nothing is baked or installed: in game they fall back to their base hull, so the extra spire or
  turret fires from bare hull (docs/shots/swap_eclipse_1118/README.md).
- d_totality has a full Muse design (contrib/muse/design/eclipse_battleship_2026_11/synthesis.md) and no data entry,
  concept picture or sheet.

## Job A: Eclipse violet repaint plus the three variants (issue 1422)

One job because every step is a stage 5 rebake with the same stack; doing the variants on the old green stack would mean
baking them twice.

1. Cloud, Opus: change the corona and core light in tools/blender/kits/eclipse/stack.py to violet-white (white-gold on the
   brightest arcs, deeper violet where dim, core violet-white with a white-hot centre), colours taken from faction_looks.json
   `deathless` (weapon, damage_glow, accent), not new numbers. Fix the stack's green comments and its concept-sampling green
   test. One kit change reaches every Eclipse ship (R333). Proof picture in cloud Blender (cloud-blender route): E12 before
   and after at camera 170 and close, labelled "stack proof, not in game".
2. Ryan looks at that one picture (taste call: how bright the violet rim reads on violet-black plates).
3. PC, Board queues: ship_job.bat runs for E11, E12, E13, E14 (rebake stage 5 to 7) and the three variant recipe JSONs
   (stages 1 to 7, the variant self-test and variant_ship_check.gd with VARIANT_EXPORTS). One labelled picture per ship.
4. Ryan says yes to the pictures, then the Board queues publish_ship.bat for all seven codes (D22_23, D21_23, D9_23, D20_23,
   d_scythe_s, d_jackal_h, d_harvester_t).

Cost: 1 to 2 Opus cloud runs, 1 Ryan look, 2 PC ship runs (seven ships), 1 publish run, about 2 review rounds.
Order: the repaint is small and the installed green now contradicts Ryan's ruling, so it can take a free PC slot ahead of
the R328 queue; the Board decides.

## Job B: the Eclipse battleship d_totality (issue 1423, blocked until the current ships land)

1. Rules, Opus: add d_totality to both rule copies (data.js and the Godot rules data) from the synthesis: Battleship,
   size 1.0, CP 6, hull 260, armour .35, speed 2, two Null cannons, two Corona arcs, a Null spire, Repair swarm, regen 5.
   Check the FS-2 price ladder (data.js:1041 still has deathless Battleship 1.6 below Cruiser 1.65; the synthesis raises it
   to 1.7). Parity goldens and the playtest-and-balance sims; report deltas. Decide where it appears (shipyard unlock
   u_battleship, enemy fleets).
2. Concept, Muse: three views from the synthesis prompts, all violet (the synthesis already says no green). Ryan picks.
   Check contrib/muse/design for any earlier pick first.
3. Sheet, Opus: build sheet E15 on the Eclipse kit and the new violet stack (R205), rounds judged at camera 170 beside the
   picked concept.
4. PC: ship_job run, Ryan's yes, publish.

Cost: 1 Opus rules run plus 1 review round, 1 Muse concept run plus Ryan's pick, 2 to 4 Opus sheet rounds, 1 to 2 PC runs.

## Flags (not acted on)

- Doom gun core green (faction_looks.json weapon_core, R263): the last green on Eclipse. Kept because Ryan's "all violet"
  answered a rim question. Worth one line to Ryan when Job A's picture goes to him.
- d_scythe_s is still a strict upgrade (data.js:1077: adds a Null spire, takes nothing away), against R63 "every hull variant
  carries a real trade" (Qwen roster review F-5, Oct 28). A rules fix for the Board's balance queue, separate from the build.
- The browser data.js FAC3D line for deathless (hull #1d2220, trim #1fbf4a, glow #3dff6a) is still green. Browser look
  only; the browser copy changes for rules, so it is left alone.
