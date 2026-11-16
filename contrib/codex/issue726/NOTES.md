# Issue 726 paint run

The PC run reached A20 stage 5 before installation. Cycles reported `out of SVM stack space` for ps_soot2_H, ps_blood_H,
ps_soot_H, ps_iron_H and ps_rust_H during the normal bake. Blender still exited zero. The baseline ships are unchanged.

`proposed/` contains whole-file copies of a proposed shared bake fix and its recipe note. The live shared code and recipe
are restored. The proposal compiles only the existing normal input for a normal bake, then restores the original shader
links. It changes no faction palette or geometry. Automatic approval review rejected restarting the full paint and install
run with this broader shared change. Do not apply or install it without approval.

`normal_bake_diagnostic.py` compares the original and proposed bake on a small temporary fixture, including graph restoration
after an injected operator error. It writes only to TEMP and never installs ships.
