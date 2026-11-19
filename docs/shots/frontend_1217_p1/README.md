# Issue 1217 phase 1: the orders kit, front-end sounds, Esc and scale

Stage: built and checked in the cloud (not installed on the PC yet, not accepted by Ryan). Each picture is before (main
977b7af5) and after (this branch), rendered through the real main scene with no showcase battle.

![F1_settings Larger](F1_settings_larger_before_after.png)

![F1_settings Normal](F1_settings_normal_before_after.png)

![F1_setup Larger](F1_setup_larger_before_after.png)

![F1_title Normal](F1_title_normal_before_after.png)

Retake: `xvfb-run -a godot --rendering-driver opengl3 --path godot --resolution 1920x1080 --script
res://ui/test/front_end_shots.gd -- <out dir> [tag]` (on the PC, drop xvfb-run and the driver flag).
