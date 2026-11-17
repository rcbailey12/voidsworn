# KB1CC run 3, R304, issue 903

Run 3 extends the two Run 2 bomb mouths into continuous hollow barrels.
Each runs .54 LENGTH (0.864 sheet units) from mouth x +.430 to breech x -.110,
with four riveted straps and curved armour wrapping its rear hull entrance.
The inside shows covered lifting cradles connecting both breeches to the
existing magazine rows. The original dark collars, bores, red liners and
bomb noses keep their Run 2 positions and sizes.

- [Concept, Run 2 and Run 3 at paint_full](KB1CC_R304_compare.jpg)
- [Run 3 at paint_full](KB1CC_R304_paint_full.jpg)
- [Tube close-up](KB1CC_R304_tube.jpg)
- [Top view of both long barrels](KB1CC_R304_top.jpg)
- [Inside: barrels and magazine feeds](KB1CC_R304_inside.jpg)
- [Run 2 and Run 3 at camera 170](KB1CC_R304_cam170.jpg)
- [Bays and engines](KB1CC_R304_details.jpg)
- [Taper and ramp then plateau](KB1CC_R304_profile.jpg)
- [Measurements and check results](checks.json)

The shoulder skins and the bays' outer walls have seats around the new barrels
and straps. Bay locations, pipes and hoists stay in place. Run 2's rust-red paint
inputs, existing faction stack, seven engines, rails, bow taper and plateau stay.
Only the tube magazine feeds are added inside. The weapon remains bombs T,
two matching fixed mounts with one muzzle each. No extra weapons or pale or
purple square zones are added.

Method: [KB1CC design](../../../../../tools/blender/build_sheets/ships/corsair_KB1CC.py),
[inventory](../../../../../tools/blender/build_sheets/ships/corsair_KB1CC_inv.py),
[build sheet](../../../../ship_pipeline/build_sheets/corsair_KB1CC/README.md),
[manifest](../../../../ship_pipeline/build_sheets/corsair_KB1CC/manifest.json),
the existing sheet contract and unchanged Hullbreaker craft paint stack.
Budget counts and the requested checks come from the rebuilt model and paint.

Double-click [reproduce.bat](reproduce.bat) on Ryan's PC. The script rebuilds the
sheet, checks its fit and contract, bakes 2048 maps, captures the saved paint_full
camera and camera 170, and publishes labelled pictures no taller than 720 px.
Scratch stays in `%TEMP%\voidsworn903_r304`. Review copies are also saved in
`C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-903\shots`.
The watchdog, weighted GPU claims and `gpu_go.txt` remain in use.

Run 2 references are preserved as `KB1CC_R299_*`, from PR 909 head `39ac3609`.
The old camera 170 reference crop is recovered at its original pixel size from
the saved Run 2 sheet, without resizing. `KB1CC_R294_*` are older Run 1 references.
All current Run 3 pictures use `KB1CC_R304_*` names, their build revision and
stage labels, and picture-provenance sidecars.

Stage: sheet built and paint proof. No game export or installation is part of
this job; squadron craft still use their separate procedural game renderer.
No visual acceptance or frame-time result is claimed.
