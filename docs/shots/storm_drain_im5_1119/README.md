# F12 ion storm drain and F13 IM5 stern

## F12 · Ion storm drain

[Camera 170 comparison sheet](../issue-1148-codex/F12_storm_drain_c170.jpg) · [Before and after clip](F12_storm_drain.mp4)

Seed 4103 has 31 storm hexes and 28 nebula hexes. In all four replays, the 19-hex cloud takes the Resolve of the Reach (V16_37) from 40 to 30 shields. Its hull stays at 135. The sheet shows a quiet tick and a tick during an incoming Glasswrights prism volley in Standard and Reduced Flashing. The shield numbers come from the rules fixture. The crops retain the original camera 170 pixels from the 1920 by 1080 Forward+ render.

The flare uses the existing positioned Ion storm event. The gas lights near the affected ship for 0.45 seconds through the existing flash budget and comfort curve. Reduced Flashing keeps the softer rise and 0.22 peak on that curve.

The cyan glow sits under the ship and is strongest in Standard. In Reduced Flashing it rises more gently and is subtler during the volley. The final native storm look bench matched 35 fleet stills pixel for pixel. The still of the repaired IM5 differed by 0.79 levels on average, within the 2.0-level tolerance.

## F13 · Iron Mandate IM5 (H4_11)

[Camera 170 and stern comparison sheet](../issue-1148-codex/F13_IM5_stern_before_after.jpg) · [Stern comparison clip](F13_IM5_stern.mp4)

Two zero-area faces on the flat stern cap sent its generated inner shell through the plating. The cap now triangulates along the existing rim. The comparison marks the two spots where the liner slivers were visible above the nozzles.

The repair follows the [IM5 build sheet](../../ship_pipeline/build_sheets/hegemony_IM5/README.md), [parts manifest](../../ship_pipeline/build_sheets/hegemony_IM5/manifest.json) and the [recipe settings](../../../tools/recipe/ships/hegemony_IM5.json). The change is in the [build sheet source](../../../tools/blender/build_sheets/ships/hegemony_IM5.py). The existing Hegemony paint stack baked both atlases at 4096 with 64 OPTIX samples. The production export uses 2048 maps.

The intact outside-triangle count fell from 14 to 0 in the existing wreck check. The same check found zero split machines and zero new protrusions after break-up. The export silhouette overlaps the old export by 99.99% at the approved three-quarter camera and 100% in top and stern views. All eight fit counters are zero and all five weapon slots pass.

The export has 105,500 main mesh triangles and 8,436 turret triangles at class length 31. Stage 7 checks cover the GLB, hard points, six nozzle openings and authored interior. The checker rejected all 35 planted faults in its self-test. The stage 6 and 7 helpers ran directly, following the [issue 970 route](../../ship_pipeline/build_sheets/hegemony_IM5/ion_install_README.md). The full batch launchers require historical shape-reference records outside this checkout.

The stage 6 LOD export and two-repeat solo studio bench passed. The second repeat for 20 full-detail ships measured a 1.390 ms frame median at 1080p and a 2.847 ms GPU median with 3D at 4K.

The isolated game read back all 38 hard-point and turret nodes, and its installed GLB also returned zero intact protrusions. Only then was the checked export installed into the shared playable build. The shared cache was rebuilt and read back the same 38 nodes. The shared GLB SHA256 matches the checked export. The install kept the previous files in the shared build's `.stage7-replaced-b59w46e7/previous` folder.

## Run 2 · Multiple ships in one cloud

Each drained ship has its own position and 0.45-second fade in the storm cards and Max fog. Cues can overlap, with the shared flash counter still deciding which use the softer curve. Where the glows overlap, the stronger one sets the local brightness. If all eight slots in a cloud are busy, later cues wait for a slot and then play in full.

The headless test plays a turn with two ships four hexes apart in one cloud. It checks both materials through the full cue in Standard and Reduced Flashing, with same-frame and staggered playback. The pictures and clips above show run 1.

## Run 1 verification

Standing checks passed with 74 passes and two recorded baselines.

Godot loaded 239 scripts and 16 scenes with zero failures. All 84 game checks passed after rerunning five cases with their Windows test profiles and fixture inputs in place. The seed 360 campaign bot battle, storm lightning check and A16 fixture freshness check passed.

The scratch IM5 stern recorder reported renderer shutdown errors after saving the frames. Both sheets passed provenance verification, and both clips decoded to the end and stayed below 8 MB.
