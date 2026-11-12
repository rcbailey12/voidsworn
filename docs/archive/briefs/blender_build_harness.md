ARCHIVED Nov 11 2026: replaced by docs/playbooks/ships.md (section 0 binds) and docs/ship_pipeline/RECIPE.md. Kept for history; do not follow (habit 4's no downloaded textures is overruled by RULEBOOK 5.13, CC0 assets allowed; its caps section is dead, R111).

# Blender build jobs: the harness every builder follows (from #206 and #214, Nov 8 2026)

Whoever builds a hull, part or station in Blender (Codex, the workhorse, Opus) works this way. Source notes: issue #206 (the Kamome harness example Ryan reviewed Nov 6) and issue #214 (the Kensei 15-step Blender plus Tripo guide, Nov 6). Both are closed into this file.

## The four habits

1. **Design doc first.** Step one of a build job is a short per-asset design doc in the job's output folder: overall size, a measured parts list (start, end, height, width per part), build order, materials. Build to it; do not improvise geometry stage by stage.
2. **Fixed-camera compare loop.** After each stage, render from the same cameras as the reference sheet (for ships: the battle camera and the nine-cell sweep views of the existing review sheets) and compare before Ryan sees anything. Treat the model's own visual check as a hint, never proof: in the Kamome run an AI inspector passed a prop clipping through a windowsill. Scripted checks below catch what eyes miss.
3. **Scripted overlap audit as the standing final check.** Every build ends with a script that prints, for every part, its gap or intersection with the hull and its neighbours (target 0 gap, no intersections), parts crossing authored break lines (the #200 clearance clauses), and a triangle, draw call and surface report. Keep the audit in the build script so it runs every time.
4. **Procedural materials, no external assets.** No downloaded 3D models or texture images, even CC0 (licence risk, and it stops the agent fetching assets on its own). Procedural nodes with pattern scales in real units, driven by masks baked from the ship's own geometry (R96). Generated images only for text or pictorial details.

## Generators (from #214)

- What generators drop (thin wires, text and logos, fine greebles) is built in code or by hand: antennas, markings, small detail.
- A reference view in the wrong slot doubles features; references stay orthographic and measurable.
- Hunyuan3D 2.0 runs locally in 16 GB VRAM (the 5080 fits; a portable Windows build exists). It is the second free local generator if #209's Arm B wants one beside TRELLIS.2. Its licence excludes the EU, UK and South Korea (fine for Ryan, US).
- Tripo stays as #193 has it: local routes first, Tripo evaluated by Opus only if they leave the question open (R110). If it runs, price the API for our workload (texture off, per part) from a real logged charge, not from third-party per-model figures.

## What does not transfer

The examples' budgets and character rigging steps. Our only binding performance law is the #207 scene gate in ms (R116); triangles, draw calls and surfaces are reported, never capped (R111, R113, R121).
