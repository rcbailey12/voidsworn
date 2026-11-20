# Issue 1289: the hitch when a ship arrives mid-battle

## What the hitch was

Issue 1232's PC run 4 (contrib/opus/cold_kill_1232/EVIDENCE.md) timed A16 (C19_51, a capital) arriving after the battle's
load in an empty profile: one frame of 845 to 998 ms, all on the main thread (GPU under 8 ms in that frame), on both the
fix and main. That bench left the arrival's own build (ShipView.setup and fx.add_ship) outside the timed frame, and in the
game it is inside it: the battle builds an arriving ship in the frame it appears (battle._play_batch, _make_view).

Only one thing brings a ship mid-battle: the rules' reinforcement event (rules.gd eventTick; R42's Nemesis reinforcement
is the same event). It is rolled when the battle starts and always brings its faction's cheapest hull (cheapHull: a
frigate, never a capital). So the battle knows at its start exactly which hull will arrive.

What an arriving ship paid for, in its frame:

| part | cost | who pays it |
|---|---|---|
| the fitted shield skin posed for the ship (copy, offset, upload, hit collider: about 58,000 vertices) | 133 to 175 ms in this container, every arrival, cached skin or not | every ship that arrives; ships at the load pay it under the cover |
| the shield skin bake, when the disk cache does not have the hull yet | seconds of CPU (R303 bake) | the first arrival of a hull per profile |
| the model and paint loaded for the first time | 1 to 2 ms here (placeholder hull); on the PC, the trace says | the first ship of a hull per session |
| the renderer's first draw of the new hull's materials (pipelines) | 132 pipelines in run 4's arrival frame | the first ship of a hull per session |
| its hull analysis | 4 to 5 ms here | every ship |

(Container numbers: Godot 4.7.2 headless, 4 cores, the capture's dry run on a placeholder hull. The PC run below names the
rest on the real hulls.)

## The fix (shared kits, every battle and every faction)

1. **The arrival is built at the load.** `battle_api.arrival_previews()` names the reinforcement's hull (read only: no dice,
   no ids, the battle plays the same; checked by rules/test/arrival_preview_test.gd for an enemy and an ally reinforcement
   and a battle without one). `render/arrival_warm.gd` builds that hull exactly as an arriving ship is built, before the
   battle's warm-up, so the loading cover pays its load, shield bake, cut and first draw with every other ship. Then it
   leaves the effects and stays hidden in the scene until the battle ends, so its model and paint stay loaded
   (render/test/arrival_warm_check.gd).
2. **A shield pose is built once per hull per battle.** `fx_ship._posed_skin` keeps each posed skin and its hit collider in
   `fx.shield_poses` (freed with the battle's effects); a later ship of the same hull shares them. In the dry run a second
   arrival of the same hull went from 164 ms to 9 ms, and an arrival after the kit's load 14 ms.
3. **Named parts.** fx.add_ship's parts (hull analysis, damage root, engines, shield, collider) are in fx.prof as `add:*`,
   so any later arrival cost names itself.

## The fully cold case: out of scope

The cold rows (1077 and 1232: nothing warmed at all, then a capital killed 6 frames after it appears) stay as they are.
Reason: no battle in the game runs cold. Every battle with a window runs battle._warmup under the loading cover
(prepare_battle_hulls, then fx.warmup), and now also builds its one possible arrival there. The cold path exists only in a
bench process that skips the warm-up. The one game path near it is a warm-up that runs past its 20 s cap: the battle then
starts while the warm-up finishes behind it, and the arrival's hull was still built first (the kit runs before the cap's
clock starts).

## PC proof: run 5 PASSED (Nov 20, 02:22 PC time)

contrib/opus/arrival_hitch_1289/OPUS1289_RUN5.bat on Ryan's PC (RTX 5080, solo GPU, frames paced to 60 a second, every row
a fresh process in an empty throwaway profile, Ryan's real options unchanged). AFTER 63222da0 (the fix), BEFORE ab6b3258
(main). ACCEPT 6 of 6; 28 of 28 rows collected. Full table: run5_summary.txt in this folder.

Worst frame in ms (sessions 1 and 2):

| case | before (main) | after (the fix) |
|---|---|---|
| A16 arrives mid-battle (as the game now does it: built at the load) | 5,518 and 6,192 (no warm-up existed) | **35 and 36** |
| Warden (the real reinforcement frigate) arrives (built at the load) | 1,142 and 1,231 | **24 and 24** |
| A16's second arrival in one process (shared analysis and shield) | 1,308 and 1,445 | 36 and 38 |
| first A16 kill after a normal load | 16 and 24 | **13 and 16** |
| A16 arrival with no load-time build (bench control) | 5,518 and 6,192 | 5,355 and 7,820 |
| fully cold (out of scope) | 4,370 and 4,488 | 4,278 and 4,810 |

Every kill broke into pieces (A16 4, warden 2) on both commits. Where the 5.4 s went without the fix (A16, after s2):
shield skin bake and hull analysis 4.1 s (fx.add_ship), model load 0.4 s, first draw 0.9 s (126 pipelines). With the load-time
build and the shared analysis the arrival frame is view 2 ms, fx.add_ship 32 to 34 ms, render 2 ms, no pipelines.
