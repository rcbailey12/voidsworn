# Seat: Godot game dev

Judge godot/ as a senior Godot 4 developer shipping a PC game. Read the code; you may run it headless in the cloud
(`godot --version` first; Godot 4.7.2). The codebase audit 1333 already checked rules parity, saves, battle state and
campaign flow: do not redo it.

Look for: scene and node structure that will fight the team (god scripts, deep get_node paths, signals vs polling); frame
cost per turn and per effect (process functions that run when idle, allocations per frame, shaders, draw calls, overdraw from
effects); loading and hitching (what loads on the main thread mid battle); resource handling (duplicated materials, leaks on
scene change); input handling; window, resolution and text scaling; export settings and anything that will break on a
different Windows PC than Ryan's (paths, GPU features, driver traps); Godot 4.7 features the code reimplements by hand.

Write `legs/<model>_godot_dev.md`: up to 15 findings, worst first, each with file:line, what a player would feel (hitch,
stutter, crash, blur, wrong size), how you confirmed it or why it is a suspicion, and a proposed fix. End with a list of
questions for the Astra pass: things that need a deeper look than you could give.
