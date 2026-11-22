# Issue 1765: Planets V2 direction sheets

Stage: cloud direction check (software Vulkan renderer in a cloud container), not PC, not installed in game, not
accepted. Ryan's done-when still needs the PC captures after green checks and the Board's independent audit
(RULEBOOK 3.12, 3.13).

| Sheet | What it shows |
| --- | --- |
| PV2_board_c170.jpg | The five board planet looks (B0 rocky, B1 terran, B3 ice, B4 volcanic, B5 barren) at camera 170, before (main) and after |
| PV2_board_close.jpg | The same five, close over the lit limb |
| PV2_backdrop_1.jpg, PV2_backdrop_2.jpg | The eight backdrop planets (world_sky.gd PLANETS 0 to 7), before and after |
| PV2_moons.jpg | The four new moon minerals; before, every moon was one of two looks (rock or ice) |

Made with `godot/world/planet_v2_shots.gd` (the same script draws the old board path on a checkout without
`install_board`), then cropped and labelled. PC capture (Board queues it):

```
godot --path godot --resolution 1280x720 --script res://world/planet_v2_shots.gd -- --out <folder> --tag after
```
