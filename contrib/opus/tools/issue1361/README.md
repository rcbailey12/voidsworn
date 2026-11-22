# Issue 1361 cloud rock bench

`rock_bench.gd` renders one rock group per kind (stone, iron, carbon, ice, crystal) at camera 26 or SHOT_D.
Copy it into `godot/world/` and run it in a cloud thread in Forward+ through lavapipe:

    VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json SHOT_SHADOW=1 SHOT_D=26 xvfb-run -a -s "-screen 0 1280x720x24" \
      godot --rendering-driver vulkan --resolution 1280x720 --path godot --script res://world/rock_bench.gd -- after OUT

The "before" row loads `res://world/_before_rocks_tmp.gd`: main's world_rocks.gd with LIB_DIR pointed at a folder of
main's rock files. Bench lights, not the game's look.gd: direction only. Do not judge rock shaders in the GL
Compatibility renderer: a SPECULAR that varies by kind or by fragment renders the rock near black there (found here).
