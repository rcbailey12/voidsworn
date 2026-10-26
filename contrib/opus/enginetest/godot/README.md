# A2 engine test: the Godot half

The scene from `../SPEC.md`, built in Godot 4.7.2 (GDScript only, no C#): six faction flagships drifting in formation, the shared starfield, key and fill lights, ACES, glow and shadows, and the cinematic effect set (R16), plus the crowd runs, the max mode with physics, the game slice and a standalone build (SPEC.md "Trimmed scope"). Nothing from the game's Babylon effects is reused.

## Files

- `project.godot`, `main.tscn`: the project. No editor or import step is needed; Godot makes a `.godot` cache folder on the first run (ignored by git). Jolt is the physics engine, gravity is 0.
- `main.gd`: loads the ships at runtime, finds where the effects sit on each hull, sets up the sky, lights and cameras, the scene options, the shader warm-up, and the benchmark and stills modes.
- `fx.gd`: every effect (engines, broadside, beam, incoming shell and hit, hull breach, the destruction event), the ship drift, the rich-mode extras and the shake.
- `physics.gd`: Jolt rigid bodies for debris and destruction chunks (max mode).
- `board.gd`: the game slice (`--board`).
- `env.gd`: the asteroid field, big rocks and dust haze (max and board modes).
- `export_presets.cfg`, `pc/export_windows.ps1`: the standalone Windows build.

## What it reads

- Ships from `../assets/` (the enginetest folder's `assets`): `V1b_r_23.glb`, `H4_11.glb`, `C19_51_shell.glb` plus `C19_51_kit.glb`, `B16_23.glb`, `I8_37.glb`, `D22_23.glb`. On the PC these sit in `Downloads\voidsworn_test\enginetest\assets\` (the barge as the painted pair, copied under those two names).
- The sky from `../starfield_4k.png`; in max and board modes `../assets/env/sky_deadstar_8k.png` when it exists.
- In max and board modes, `../assets/env/asteroids.json` and `env/rocks/*.glb` (seed 7 placements shared with Babylon): 200 field rocks instanced in one MultiMesh per rock mesh and 6 big rocks, each tumbling about its own axis, with sphere colliders so the debris bounces off them; a faint dust haze in Godot's volumetric fog (density 0.0001, about 3% across the battle, cool grey, forward scattering, barely touching the sky so the background stays dark; plain distance fog in Compatibility). Missing files: no rocks, no haze.
- `--assets dir` points somewhere else if needed.

## Running it

Godot on the PC: `Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe`. Run from `Downloads\voidsworn_test\enginetest` (so the project is `godot` and the ships are `assets`). Relative paths after `--` (for `--bench`, `--shots`, `--assets`) are taken relative to the `godot` folder, so `../results/x.json` lands in `enginetest\results`.

User options go after the lone `--`:

| Option | What it does |
|---|---|
| `--bench out.json` | Load, shader warm-up, 3 s uncounted warm-up, then the 20 s battle orbit with every effect running; writes the JSON and `out_trace.json`, then quits. |
| `--shots dir` | Writes the stills for the chosen scene on a fixed clock, then quits. Give the engine `--fixed-fps 60` too; if it is missing, the script starts itself again with it and waits. |
| `--res 3840x2160` | The render size. Always give it: Godot keeps its own `--resolution` to itself and only sizes the window with it, and Windows may shrink a 4K window to fit the screen. The scene renders into an off-screen target of exactly this size and the window shows it scaled. |
| `--seconds 20` | Length of the measured run (the orbit is stretched to fit it). |
| `--stress` | 24 ships: the six flagships plus 18 copies at 0.6 scale in rows z = +60, 0, -60 at x = -60 to +60 (factions in order), loops staggered 0.17 s (flagships first, then the rows from +z to -z, left to right), the destruction every 4 s (breaks at 4.4, 8.4, ... s), orbit radius 190, height 85. JSON `"mode": "stress"`. |
| `--ships 40` | 40 ships: the stress layout plus rows of six every 30 units beyond it, alternating sides (+90, -90, then the first four places of +120); orbit radius 150 + 40 per extra row pair (250), height 0.45 of it. JSON `"mode": "ships40"`. |
| `--max` | The six-ship scene at its best: rich effects (below), SSAO, SSIL, SSR, SDFGI, TAA (bench only), a tiling detail normal layer on the hulls, soft (PCSS) key shadows in an 8192 atlas, Jolt rigid-body debris and chunks, a mild depth of field on the hero stills, weight-scaled shake on the battle camera, and colour grading. Stills are `max_<name>.png` plus one hero close-up per ship (`hero_<code>.png`). JSON `"mode": "max"`. |
| `--rich` | The rich effects alone (no lighting extras, no physics): a light per gun and per impact, volumetric fog for the breach gas, smoke rings and fireball, soft particles, parallax breach holes. |
| `--physics` | The Jolt debris and chunks alone. |
| `--board` | The game slice: top-down camera at 55 degrees over a 20 by 14 board of flat-topped hexes 20 units across (game scale, `--hex 20` changes it) in the plane y = -6, a movement-range highlight (3 hexes) on the selected ship, a gold rim outline on the ship under the pointer, a selection ring on click, name labels with hull and shield bars (native Control UI drawn inside the render target, sized from the render height, so sharp at 4K and 1440p), with the ships, effects, debris physics and the environment running. Scripted pointer in bench and stills: hover over the Hegemony from 0.5 s, click the barge at 2.0 s. Stills `board_t03.0.png`, `board_t12.6.png`; the JSON adds `click_to_ring_frames`. |
| `--vsync` | Capped run: vsync on (leave out `--disable-vsync`); the JSON adds `vsync`, `refresh_hz` and `dropped_frames`. |
| `--key 2.0` | Key light energy (fill and ambient are each 25% of it). |
| none | Free viewing: 1 battle orbit, 2 barge close-up, 3 breach close-up, Esc quits. |

### PC runs

```
set G=%USERPROFILE%\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe
cd /d %USERPROFILE%\Downloads\voidsworn_test\enginetest

rem main, stress, 40 ships, max; each at 4K and 1440p, each renderer (gl_compatibility: same lines with --rendering-method gl_compatibility)
%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --disable-vsync -- --bench ../results/godot_fp_2160_main.json --seconds 20 --res 3840x2160
%G% --path godot --rendering-method forward_plus --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_fp_1440_main.json --seconds 20 --res 2560x1440
%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --disable-vsync -- --bench ../results/godot_fp_2160_stress.json --seconds 20 --res 3840x2160 --stress
%G% --path godot --rendering-method forward_plus --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_fp_1440_stress.json --seconds 20 --res 2560x1440 --stress
%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --disable-vsync -- --bench ../results/godot_fp_2160_ships40.json --seconds 20 --res 3840x2160 --ships 40
%G% --path godot --rendering-method forward_plus --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_fp_1440_ships40.json --seconds 20 --res 2560x1440 --ships 40
%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --disable-vsync -- --bench ../results/godot_fp_2160_max.json --seconds 20 --res 3840x2160 --max
%G% --path godot --rendering-method forward_plus --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_fp_1440_max.json --seconds 20 --res 2560x1440 --max

rem capped (vsync on) run, to match Babylon's --vsync
%G% --path godot --rendering-method forward_plus --resolution 2560x1440 -- --bench ../results/godot_fp_1440_main_vsync.json --seconds 20 --res 2560x1440 --vsync

rem board slice (bench and stills)
%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --disable-vsync -- --bench ../results/godot_fp_2160_board.json --seconds 20 --res 3840x2160 --board
%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --fixed-fps 60 -- --shots ../shots/godot_fp_board --res 3840x2160 --board

rem stills (main, then max)
%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --fixed-fps 60 -- --shots ../shots/godot_fp --res 3840x2160
%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --fixed-fps 60 -- --shots ../shots/godot_fp_max --res 3840x2160 --max
```

Main stills: `t02.0_barge_closeup.png`, `t03.0_breach_closeup.png`, `t05.0_battle.png`, `t12.0_battle.png`, `t12.6_destruction.png`. `--fixed-fps 60` makes every frame exactly 1/60 s for the script's clock, the shaders' clock and the particles alike, and the particle systems use fixed seeds in this mode, so the stills land on the same simulated moment every run whatever the frame rate. Several stills at one moment (the hero shots at t = 3.0) hold the clock with `Engine.time_scale = 0` while the camera moves.

## The JSON and the trace

As the spec has it: `engine`, `renderer` (from `RenderingServer.get_current_rendering_method()`), `mode`, `ships`, `width`, `height` (the render size), `seconds`, `frames`, `avg_ms`, `p99_ms` (mean of the worst 1% of frame times), `max_ms`, `fps_avg`, `load_s`, `gpu_mem_mb`, `notes`; plus where they apply `lights_active_avg` and `lights_active_max`, `physics_ms_avg`, `physics_ms_p99` and `bodies_max`, the vsync fields, and `click_to_ring_frames` (board).

- Frame times are the wall-clock gaps between frames (`Time.get_ticks_usec()`), which with vsync off is the real frame time.
- `load_s` runs from engine start (Godot's clock starts at engine init, a few milliseconds after the process starts) to the end of the first frame drawn with all six ships and the sky.
- The max mode's long load (38 s on the PC with the 8K hi ships) is the runtime path: GLTFDocument decodes every embedded JPEG and PNG on one CPU thread, the loader builds mipmaps on the CPU, and the textures go to the GPU uncompressed (an 8K RGB map with mipmaps is 255 MB). A normal Godot project imports the ships in the editor instead: the textures are stored VRAM-compressed (S3TC/BPTC) with their mipmaps, so a load is a file read and a direct upload, with no decode and 4 to 6 times fewer bytes. Measured in the sandbox on one 8K hull map: runtime path 766 ms (JPEG decode 634, mipmaps 132), imported CompressedTexture2D load 30 ms (45 MB file instead of 255 MB in memory). So I would expect the imported project to load the hi ships in a few seconds instead of 38, roughly 10 times faster or better; the console log prints parse, fixes and scene times per file to show where the 38 s goes.
- `gpu_mem_mb` is `Performance.RENDER_VIDEO_MEM_USED` at the end of the run (the notes also give the peak). The PC job also samples nvidia-smi.
- `notes` gives the effect script's cost per frame, the engine's own GPU and render-CPU time per frame for the 3D view, the warm-up time, the adapter and driver, and anything that fell back.
- `<out>_trace.json`: per second of the counted run, frames, average, worst 1%, max, frames over 16.7 ms and the most the effect script took in a frame; and the 15 worst frames with their scene time.

## How the effects run (why the script is cheap)

One global shader parameter, `scene_t`, carries the clock.
- Every glow sprite and ribbon of one kind (engine cores, plumes, trails, muzzle flashes, flame tongues, tracers, impact flashes, beam charge, core, glow and end flare, the incoming shell, hit cores, breach pops), for all ships, is one MultiMesh, so one draw: 14 draws for all effect sprites and ribbons whatever the ship count. Each instance's data (start point, direction, widths, colours, start time) rides in its instance transform, colour and custom data, and the shader computes its position, drift, size and brightness from `scene_t`.
- The shields compute their ripple from `scene_t` too (one per shielded ship, shown only during its 0.6 s).
- Particles are `GPUParticles3D` (simulated on the GPU). The breach gas, fire and tumbling debris of every ship are three shared systems emitting from all the breaches at once (emission points); each ship's four guns share one smoke-ring, one impact-spark and one impact-debris system (emission points again).
- Per frame the script only moves the ship roots and the shared emitters, shows a shield while it can be seen, restarts one-shot particle systems when their start time passes, hides each one-shot system again once its burst is over (so idle systems drop out of the render server's particle updates and instance updates instead of idling there for 1.2 lifetimes), and sets the lights that are on.
- Scenes with no physics turn the physics server off.

The JSON notes give the effect script's time and a frame breakdown of CPU wall time per frame, measured with timestamps around each phase of Godot's main loop (a probe node first and last in the process order, and the render server's frame_pre_draw and frame_post_draw signals): physics steps, node processing (every _process and particle node), tree flush and render sync, the render server's draw split into scene update, 3D view render CPU and the rest (waiting on the GPU frame, particle updates, 2D, present), and the time between frames; then draw calls, objects and the node count, next to the engine's own GPU and render-CPU time for the 3D view. (Godot's TIME_PROCESS monitor is not used: it is the peak over the last second of process plus draw, not an average.)

### Shader warm-up

After `load_s` is taken and before the warm-up seconds, every effect group is shown, every particle system fired, and the hulls and chunks drawn half transparent (the drift fade and the chunk fade states), at several clock times; then the script keeps drawing until Godot's pipeline-compile counters stop moving. So no shader or pipeline compiles during the measured window. Godot's shader and pipeline caches are on (the defaults) and keep the work for the next run.

## How the scene maps to the spec

- **Ships:** each glb is loaded with `GLTFDocument` at runtime (no import step), scaled uniformly so its length along x is 24, its bounding box centred on its slot. The barge is the shell and kit loaded into one node, then turned 180 degrees about y so its bow points +x. Rows: z = +30 (Voidsworn, Hegemony, Corsair) and z = -30 (Chorus, Ithar, Deathless) at x = -45, 0, +45.
- **Drift:** every ship moves along +x at 3 units per second within 20 units either side of its layout position (offset 0 at t = 0), jumping from +20 back to -20 at t = 6.67, 20, 33.3 s, with a 2 s fade around each jump (1 s out, 1 s in, Godot's per-instance `transparency`). Particles emitted from a ship keep the ship's velocity (`inherit_velocity_ratio` 1.0); the ship's continuous emitters pause while it is faded out so the jump does not fling them.
- **Where effects sit:** from each hull's own vertices: engine nozzles in the rearmost slice (two if the stern is wide), the beam emitter at the bow, four broadside guns at the outermost port point near x = -6, -2, 2, 6, the breach on the upper port flank of the main hull a little forward of midships, the hull-hit point on the starboard side.
- **Sky:** the starfield as a panorama sky (u = atan2(x, -z) / 2 pi, v = acos(y) / pi, the same mapping as the Babylon half), in a two-line sky shader that caps each texel just under the glow threshold, so the stars are not bloomed into larger, brighter dots than the PNG has.
- **Lights:** key directional light along (-0.45, -0.70, -0.55), colour (1.0, 0.96, 0.90), energy 2.0 (on the Forward+ breach close-up the Hegemony hull averages 155 of 255 with nothing clipped); fill along (0.6, -0.2, 0.75), colour (0.55, 0.65, 0.85), 25% of the key; ambient a neutral flat colour at 25% of the key, multiplied by each hull's AO map (glTF occlusion) as on the Babylon side. `light_specular` 1.0 on both (Godot's default is 0.5). The sky gives specular reflections.
- **Post:** ACES, exposure 1.0, white point 8.0 (Godot's default of 1.0 clips everything above 1.0; 8.0 is close to the plain ACES fit), glow on (threshold 0.8, intensity 0.8, screen blend).
- **Shadows:** the key light only, 4 cascades (PSSM) out to 300 units in a 4096 atlas (2048 per cascade); 8192 in max mode.
- **Anti-aliasing:** MSAA 4x on the 3D view, as on the Babylon side (plus TAA in max mode).
- **Cameras:** vertical field of view 40 degrees. Battle orbit radius 150, height 70, azimuth 200 to 320 degrees (from +x toward +z) over 20 s, looking at (0, -5, 0). Barge close-up at (20, 14, 58) looking at (45, 0, 30). Breach close-up at (12, 10, 52) looking at (0, 2, 30). Hero close-ups (max): (ship x - 8, 6, ship z + 20) for row 1, z - 20 for row 2, looking at the ship (drift included).

## The effects (fx.gd)

Per ship, a 4 s loop, staggered 0.5 s in layout order:

1. **Engines, always on:** per nozzle a hot core sprite (white centre, faction edge), a flickering plume ribbon with scrolling noise about 1.5 ship-widths long, and a 60-unit trail ribbon that thins, cools from the faction colour to dull red, fades and wavers. Corsair: the engines sputter and cut out (in the shaders), and a soot emitter coughs dark smoke harder when they do.
2. **Broadside at 0.0 s:** four port guns ripple 80 ms apart. Each: a muzzle flash, a flame tongue, a smoke ring (puffs born on a ring that expands and drifts out, lit by the key, 2.2 s), a hot tracer at 160 units per second toward a point 70 units off the port side, and at impact a flash, sparks and hot plate debris. A flash light on the hull at the firing gun.
3. **Beam at 1.5 s:** a 0.25 s charge-up flare at the bow, then 0.7 s of a white-hot core ribbon inside a wider faction-coloured glow, both with scrolling noise and flicker, an impact flare and a spark fountain 80 units ahead, and lights at both ends.
4. **Incoming shell at 2.4 s:** a hot shell streak arrives from the starboard side. Shielded ships: on the bubble near the hit, two thin ripple rings run out from the impact point and fade within a few units (distances measured in world units on the bubble), with a small soft glow and a dim flash in the faction shield colour, mostly transparent, fading over 0.6 s (Corsair's flickers and breaks into patches). Chorus and Deathless: a flash, sparks, hot debris and a fire puff on the hull. A light flash at the impact.
5. **Hull breach, persistent:** on the upper port flank of the main hull (found as the port-facing surface at the hull's widest point there, so never on the superstructure), a hole about 2.4 units across (1/10 of the ship): a projected scorch decal (black jagged hole, scorched ring, glowing torn edge and short hot cracks, a bowl-shaped normal map), eleven torn plates peeled outward around the rim (each snapped onto the hull vertex nearest its place, merged into one mesh), glowing hot at their torn ends, a pale venting jet that puffs, small plates tumbling out, licking fire, a spark shower every 2.3 s and a secondary pop every 3.7 s on fixed timers (per-ship offsets: pops from 0.6 + 0.55 i as in the Babylon half, so the Hegemony pops at 1.15 and 4.85; sparks from 1.5 + 0.37 i, Babylon's spacing 1.2 s later, so the Hegemony's showers fall at 1.87 and 4.17 instead of 2.97, so the 3.0 still shows the open hole), and a flickering fire light on the hull.
6. **Destruction event every 12 s, scene-wide:** a copy of the Hegemony hull at 0.6 scale at (0, 25, 0). Squibs pop on the hull from 11.8 s, the flash builds from 11.9 s (so the 12.0 still catches it starting) to its peak at the break at 12.4 s (a big sprite plus a strong light that lights the hulls below), then a horizontal shockwave ring, a fireball, dark smoke, embers and hot debris. The hull is cut at load time into four chunks of its own mesh (three tilted planes); each chunk tumbles away with fire, smoke and squibs along its break, and the biggest drifts slowly as a burning wreck. The chunks fade at about 21.8 s and the whole ship fades back in from 22.4 s, 2 s before the next break.

### Rich and max extras, and what each needed

| Feature | Mode | How (built-in, hand-written) |
|---|---|---|
| A light per muzzle flash and per impact, fire lights on the chunks and the fireball | rich, max | built-in OmniLight3D, energies set by the script while on; Forward+ is clustered, so no per-material limit. 40 to 55 lit at once in the 24-ship rich run (the JSON reports it). |
| Volumetric gas: breach vents, the four smoke rings of each broadside, the fireball | rich, max (Forward+) | built-in volumetric fog and FogVolume, shaped by hand-written fog shaders (the rings are torus distance fields computed from the clock). Not in Compatibility. |
| Soft particles | rich, max (Forward+) | hand-written: the flame, smoke and glow shaders read the depth texture and fade near hulls |
| Breach holes with depth | rich, max | hand-written parallax occlusion mapping on a disc on the hull (a jagged crater ray-marched in tangent space, its floor glowing) |
| SSAO, SSIL, SSR, SDFGI | max (Forward+) | built-in Environment settings. SDFGI adds little in empty space (nothing but the dark sky to bounce). |
| TAA | max (Forward+) | built-in (on top of MSAA 4x), in the bench runs only: the stills change camera on held frames, where TAA history ghosts and softens, so they use MSAA 4x alone |
| Detail normals | max | built-in StandardMaterial3D detail layer, triplanar, with a generated NoiseTexture2D normal map. Triplanar works from the mesh's own positions (30 tiles across a ship), not its UVs, so the hi files' single UV atlas does not matter (Babylon retiles the atlas UVs 40 times instead). |
| Emissive strength on the hi ships | max | GLTFDocument gives emission_energy_multiplier from KHR_materials_emissive_strength, else 1.0. The hi files carry none, so their emissive maps get 4, as in the Babylon max mode, and the windows and running lights reach the glow threshold. |
| Contact shadows | max | Godot has no screen-space contact shadows; soft PCSS key shadows (light angular distance) in an 8192 atlas instead |
| Rigid-body debris and chunks | max, board | built-in Jolt: irregular debris shards (random convex polygons, extruded thin, with matching convex colliders) and the four chunks (convex hulls of their own vertices) are RigidBody3D; each ship has a convex collider on an AnimatableBody3D riding with it, the asteroids sphere colliders; zero gravity; the blast pushes the chunks apart. The shards are dark hull metal with a few soft glowing specks (3D noise in the piece's own space, so nothing traces its outline) that cool within a second or two (a per-body spawn time in an instance uniform). |
| Depth of field on the hero shots | max (Forward+) | built-in CameraAttributesPractical, mild and on the six hero stills only: the whole ship sharp, far blur from 40 units behind the focus, small amount. No depth of field on the close-ups or the battle views. |
| Weight-scaled shake | max | hand-written: every big event (broadside, beam, hit, pop, destruction) adds a decaying impulse scaled by weight and distance |
| Colour grading | max (Forward+) | built-in Environment adjustments (contrast, saturation, a cool-shadow warm-highlight curve) |

## Spec points I had to read one way

- **Drift loop:** offset 0 at t = 0 so the layout is as specified at the start, then -20 to +20; the 2 s fade is 1 s out and 1 s in.
- **Gun and breach placement** come from each hull's vertices (above), not from hand-placed points; the guns fire straight out to port (slightly up), the breach faces the hull normal there.
- **Geometry left as the spec has it, even where it looks odd:** the 80-unit beam passes through the ship ahead in the same row, and row 2's broadside aim point (70 units off port) lands just behind row 1.
- **Destruction timing:** the break (flash peak, chunks flying apart) at 12.4 s, the flash building from 11.9 s so t = 12.0 catches it starting, as the Babylon half does.
- **40 ships:** 40 is not a multiple of six rows, so the last row holds four.
- **Shader safety:** every effect shader guards against NaN (no `pow` of a possibly negative base, safe normalise, final colour clamped to 0 to 512), the lesson from the Babylon half on Ryan's GPU.
- **Lights:** in the main scene each ship has its gun, beam emitter, beam impact, hit and breach-fire lights, and the destruction one big light. The Babylon half uses one effect light per ship that follows its brightest effect, because Babylon materials take 4 lights; Godot's Forward+ is clustered and has no such limit, so this is an engine difference, not a build choice. Compatibility pays for each light per object it touches; its on-screen light limit is raised to 256 in `project.godot` (8 per object stays the default).

## Standalone build

`pc/export_windows.ps1` downloads the official 4.7.2 export templates once (`Godot_v4.7.2-stable_export_templates.tpz` from https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/, about 1.3 GB), installs them in `%APPDATA%\Godot\export_templates\4.7.2.stable\`, exports the "Windows Desktop" preset to `enginetest\build\VoidswornEngineTest.exe` (one file with the game packed in, plus `VoidswornEngineTest.console.exe`, a small wrapper that shows its console output), writes the sizes to `build\export_log.txt`, then runs it twice with a 5 s bench (cold and warm; `load_s` in `results\godot_exe_cold.json` and `godot_exe_warm.json`). The exe reads the ships from `..\assets` next to its folder, as the project does. In the sandbox the export of this project came out at 109 MB (the exe) plus 0.2 MB (the wrapper); the exe takes the same options as the project runs, after `--`.

```
powershell -ExecutionPolicy Bypass -File %USERPROFILE%\Downloads\voidsworn_test\enginetest\godot\pc\export_windows.ps1
build\VoidswornEngineTest.console.exe --rendering-method forward_plus --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_exe_1440_main.json --seconds 20 --res 2560x1440
```

## Authoring throughput: one ship from Blender into Godot

Steps for this test, once the loader existed:

1. Blender: File, Export, glTF 2.0 (.glb), default +Y up. Same file Babylon gets.
2. Copy the .glb into `enginetest\assets`.
3. Add one line for it to the `SHIPS` table in `main.gd` (file name, slot, faction colours). If its bow is at -x, set `rot_y` to 180.
4. Run. No import step, no editor. The effect anchor points (nozzles, guns, breach) are found from the hull automatically.

Rough time: about 2 minutes per ship. Writing the loader the first time took under an hour. Godot's runtime glTF loading needed two fixes, applied to every ship:

- Runtime-loaded textures come without mipmaps; the loader makes them.
- Vertex colours (`COLOR_0`) are not applied to the base colour; the loader turns them on, as glTF requires. (A primitive with no material at all, like the unpainted barge exports used for testing in the sandbox, gets metal 0 and rough 0.75, as the Babylon half does.)

Godot 4.7 itself handles maps on the second UV set (`TEXCOORD_1`, which the hull files use for their normal and AO maps): it moves them to the first set. An earlier version of this loader swapped the sets again on top of that, which put the AO on the wrong UVs (the blotchy hulls in the first PC stills); that swap is gone.

The usual Godot route is different: put the .glb inside the project and let the editor import it (seconds per ship). The import compresses textures for the GPU, makes mipmaps, LODs and shadow meshes, and lets you override materials. This test skips the editor so the PC needs no import step and Godot gets the same files Babylon does.
