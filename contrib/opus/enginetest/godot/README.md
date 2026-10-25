# A2 engine test: the Godot half

The scene from `../SPEC.md`, built in Godot 4.7.2 (GDScript only, no C#): six faction flagships drifting in formation, the shared starfield, key and fill lights, ACES, glow and shadows, and the cinematic effect set (R16). Nothing from the game's Babylon effects is reused.

## Files

- `project.godot`, `main.tscn`: the project. No editor or import step is needed; Godot makes a `.godot` cache folder on the first run (ignored by git).
- `main.gd`: loads the ships at runtime, finds where the effects sit on each hull, sets up the sky, lights and cameras, and runs the benchmark and stills modes.
- `fx.gd`: every effect (engines, broadside, beam, incoming shell and hit, hull breach, the destruction event) and the ship drift.

## What it reads

- Ships from `../assets/` (the enginetest folder's `assets`): `V1b_r_23.glb`, `H4_11.glb`, `C19_51_shell.glb` plus `C19_51_kit.glb`, `B16_23.glb`, `I8_37.glb`, `D22_23.glb`. On the PC these sit in `Downloads\voidsworn_test\enginetest\assets\` (the barge as the painted pair, copied under those two names).
- The sky from `../starfield_4k.png` (it also looks in `../assets/`).
- `--assets dir` points somewhere else if needed.

## Running it

Godot on the PC: `Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe`. Run from `Downloads\voidsworn_test\enginetest` (so the project is `godot` and the ships are `assets`). Relative paths after `--` (for `--bench`, `--shots`, `--assets`) are taken relative to the `godot` folder, so `../results/x.json` lands in `enginetest\results`.

User options go after the lone `--`:

| Option | What it does |
|---|---|
| `--bench out.json` | 3 s uncounted warm-up, then the 20 s battle orbit with every effect running, then writes the JSON and quits. |
| `--stress` | The stress run from SPEC.md: 24 ships (the six flagships plus 18 copies at 0.6 scale in rows z = +60, 0, -60 at x = -60 to +60, factions in order), every loop staggered 0.17 s, the destruction event every 4 s (breaks at 4.4, 8.4, ... s), orbit radius 190 and height 85. The JSON gets `"mode": "stress"`. The copies share the flagships' meshes, so nothing is loaded twice. |
| `--seconds 20` | Length of the measured run (the orbit is stretched to fit it). |
| `--res 3840x2160` | The render size. Always give it: Godot keeps its own `--resolution` to itself and only sizes the window with it, and Windows may shrink a 4K window to fit the screen. The scene renders into an off-screen target of exactly this size and the window shows it scaled. |
| `--shots dir` | Writes the five stills on a fixed clock, then quits. Give the engine `--fixed-fps 60` too; if it is missing, the script starts itself again with it and waits. |
| `--key 2.4` | Key light energy (fill and ambient are each 25% of it). |
| none | Free viewing: 1 battle orbit, 2 barge close-up, 3 breach close-up, Esc quits. |

### The four PC benchmark runs

Do one throwaway run first after copying the project: the first run compiles and caches shaders, which inflates `load_s` and the first frames.

```
set G=%USERPROFILE%\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe
cd /d %USERPROFILE%\Downloads\voidsworn_test\enginetest

%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --disable-vsync -- --bench ../results/godot_forward_plus_3840x2160.json --seconds 20 --res 3840x2160
%G% --path godot --rendering-method forward_plus --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_forward_plus_2560x1440.json --seconds 20 --res 2560x1440
%G% --path godot --rendering-method gl_compatibility --resolution 3840x2160 --disable-vsync -- --bench ../results/godot_compat_3840x2160.json --seconds 20 --res 3840x2160
%G% --path godot --rendering-method gl_compatibility --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_compat_2560x1440.json --seconds 20 --res 2560x1440
```

### The four PC stress runs

```
%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --disable-vsync -- --bench ../results/godot_forward_plus_3840x2160_stress.json --seconds 20 --res 3840x2160 --stress
%G% --path godot --rendering-method forward_plus --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_forward_plus_2560x1440_stress.json --seconds 20 --res 2560x1440 --stress
%G% --path godot --rendering-method gl_compatibility --resolution 3840x2160 --disable-vsync -- --bench ../results/godot_compat_3840x2160_stress.json --seconds 20 --res 3840x2160 --stress
%G% --path godot --rendering-method gl_compatibility --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_compat_2560x1440_stress.json --seconds 20 --res 2560x1440 --stress
```

### Stills (for the blind pick)

```
%G% --path godot --rendering-method forward_plus --resolution 3840x2160 --fixed-fps 60 -- --shots ../shots/godot_forward_plus --res 3840x2160
%G% --path godot --rendering-method gl_compatibility --resolution 3840x2160 --fixed-fps 60 -- --shots ../shots/godot_compat --res 3840x2160
```

Files: `t02.0_barge_closeup.png`, `t03.0_breach_closeup.png`, `t05.0_battle.png`, `t12.0_battle.png`, `t12.6_destruction.png`. `--fixed-fps 60` makes every frame exactly 1/60 s, for the script's clock, the shaders' `TIME` and the particles alike, and the particle systems use fixed seeds in this mode, so the stills land on the same simulated moment every run whatever the frame rate.

## The JSON

As the spec has it: `engine`, `renderer` (from `RenderingServer.get_current_rendering_method()`), `width`, `height` (the render size), `seconds`, `frames`, `avg_ms`, `p99_ms` (mean of the worst 1% of frame times), `max_ms`, `fps_avg`, `load_s`, `gpu_mem_mb`, `notes`.

- Frame times are the wall-clock gaps between frames (`Time.get_ticks_usec()`), which with vsync off is the real frame time.
- `load_s` runs from engine start (Godot's clock starts at engine init, a few milliseconds after the process starts) to the end of the first frame drawn with all six ships, the sky and the effects in the scene.
- `gpu_mem_mb` is `Performance.RENDER_VIDEO_MEM_USED` at the end of the run (the notes also give the peak). The PC job also samples nvidia-smi.
- `notes` adds the adapter and driver, the engine's own GPU and CPU render time per frame for the 3D view, the window size, the vsync state and anything that fell back.

## How the scene maps to the spec

- **Ships:** each glb is loaded with `GLTFDocument` at runtime (no import step), scaled uniformly so its length along x is 24, its bounding box centred on its slot. The barge is the shell and kit loaded into one node, then turned 180 degrees about y so its bow points +x. Rows: z = +30 (Voidsworn, Hegemony, Corsair) and z = -30 (Chorus, Ithar, Deathless) at x = -45, 0, +45.
- **Drift:** every ship moves along +x at 3 units per second within 20 units either side of its layout position (offset 0 at t = 0), jumping from +20 back to -20 at t = 6.67, 20, 33.3 s, with a 2 s fade around each jump (1 s out, 1 s in, Godot's per-instance `transparency`). Particles emitted from a ship keep the ship's velocity (`inherit_velocity_ratio` 1.0); the ship's continuous emitters pause while it is faded out so the jump does not fling them.
- **Where effects sit:** from each hull's own vertices: engine nozzles in the rearmost slice (two if the stern is wide), the beam emitter at the bow, four broadside guns at the outermost port point near x = -6, -2, 2, 6, the breach at the outermost upper port point a little forward of midships, the hull-hit point on the starboard side.
- **Sky:** `starfield_4k.png` as a panorama sky (u = atan2(x, -z) / 2 pi, v = acos(y) / pi, the same mapping as the Babylon half).
- **Lights:** key directional light along (-0.45, -0.70, -0.55), colour (1.0, 0.96, 0.90), energy 2.4 (tune by eye on the close-ups so the Hegemony hull reads near-white without clipping); fill along (0.6, -0.2, 0.75), colour (0.55, 0.65, 0.85), 25% of the key; ambient a neutral flat colour at 25% of the key. `light_specular` is 1.0 on both (Godot's default is 0.5) to match Babylon. The sky gives specular reflections.
- **Post:** ACES, exposure 1.0, white point 8.0 (Godot's default of 1.0 clips everything above 1.0; 8.0 is close to the plain ACES fit), glow on (threshold 0.8, intensity 0.8, screen blend).
- **Shadows:** the key light only, 4 cascades (PSSM) out to 300 units in a 4096 atlas (2048 per cascade).
- **Anti-aliasing:** MSAA 4x on the 3D view, as on the Babylon side.
- **Cameras:** vertical field of view 40 degrees. Battle orbit radius 150, height 70, azimuth 200 to 320 degrees (from +x toward +z) over 20 s, looking at (0, -5, 0). Barge close-up at (20, 14, 58) looking at (45, 0, 30). Breach close-up at (12, 10, 52) looking at (0, 2, 30).

## The effects (fx.gd)

Per ship, a 4 s loop, staggered 0.5 s in layout order:

1. **Engines, always on:** per nozzle a hot core sprite (white centre, faction edge), a flickering plume ribbon with scrolling noise about 1.5 ship-widths long, and a 60-unit trail ribbon that thins, cools from the faction colour to dull red, fades and wavers. Corsair: the engines sputter and cut out at random, and a soot emitter coughs dark smoke harder when they do.
2. **Broadside at 0.0 s:** four port guns ripple 80 ms apart. Each: a muzzle flash, a flame tongue, a lit smoke ring that grows, drifts and fades over 2.2 s plus a few lit smoke puffs, a hot tracer at 160 units per second toward a point 70 units off the port side, and at impact a flash, sparks and hot plate debris. A flash light on the hull at the firing gun.
3. **Beam at 1.5 s:** a 0.25 s charge-up flare at the bow, then 0.7 s of a white-hot core ribbon inside a wider faction-coloured glow, both with scrolling noise and flicker, an impact flare and a spark fountain 80 units ahead, and lights at both ends.
4. **Incoming shell at 2.4 s:** a hot shell streak arrives from the starboard side. Shielded ships: a partial ellipsoid bubble ripples out from the impact point in the faction shield colour with a bright impact core, fading over 0.6 s (Corsair's flickers and breaks into patches). Chorus and Deathless: a flash, sparks, hot debris and a fire puff on the hull. A light flash at the impact.
5. **Hull breach, persistent:** on the upper port flank, a hole about 2.4 units across (1/10 of the ship): a projected scorch decal (black jagged hole, scorched ring, glowing torn edge and short hot cracks, a bowl-shaped normal map so the hole reads as a recess), eleven torn plates peeled outward around the rim and glowing hot at their torn ends, a pale venting jet that puffs, small plates tumbling out, licking fire, a spark shower every 2.3 s and a secondary pop every 3.7 s on fixed timers (staggered 0.5 s per ship like the loop, so the Hegemony is between pops at t = 3.0), and a flickering fire light on the hull. The torn plates are each snapped onto the hull vertex nearest their place on the rim.
6. **Destruction event every 12 s, scene-wide:** a copy of the Hegemony hull at 0.6 scale at (0, 25, 0). Squibs pop on the hull from 11.8 s, the flash builds from 11.9 s (so the 12.0 still catches it starting) to its peak at the break at 12.4 s (a big sprite plus a strong light that lights the hulls below), then a horizontal shockwave ring, a fireball, dark smoke, embers and hot debris. The hull is cut at load time into four chunks of its own mesh (three tilted planes); each chunk tumbles away with fire, smoke and squibs along its break, and the biggest drifts slowly as a burning wreck. The chunks fade at about 21.8 s and the whole ship fades back in from 22.4 s, 2 s before the next break at 24.4 s.

Fixed-lifetime pieces (flashes, ribbons, rings, the shield, the shockwave, chunk motion) are driven straight from the clock. Flame, sparks, smoke and debris are `GPUParticles3D`, restarted when the clock crosses their start time; the breach, engine soot, beam fountain and chunk fires are continuous emitters.

## Spec points I had to read one way

- **Drift loop:** offset 0 at t = 0 so the layout is as specified at the start, then -20 to +20; the 2 s fade is 1 s out and 1 s in.
- **Gun and breach placement** come from each hull's vertices (above), not from hand-placed points; the guns fire straight out to port (slightly up), the breach faces the hull normal there.
- **Geometry left as the spec has it, even where it looks odd:** the 80-unit beam passes through the ship ahead in the same row, and row 2's broadside aim point (70 units off port) lands just behind row 1. Shell impacts burst where the shell stops.
- **Destruction timing:** the break (flash peak, chunks flying apart) at 12.4 s, the flash building from 11.9 s so t = 12.0 catches it starting, as the Babylon half does.
- **Shader safety:** every effect shader guards against NaN (no `pow` of a possibly negative base, safe normalise, final colour clamped to 0 to 512), the lesson from the Babylon half on Ryan's GPU, where NaN pixels spread into black squares through bloom. Software rendering does not show these, so watch for them in the PC stills.
- **Lights:** each ship has five effect lights (the firing gun, beam emitter, beam impact, shell hit, breach fire) and the destruction event one big light: 31 omni lights in all, none casting shadows. The Babylon half uses one effect light per ship that follows its brightest effect, because Babylon materials take 4 lights; Godot's Forward+ is clustered and has no such limit, so this is an engine difference, not a build choice. Compatibility handles them too but pays for each light per object it touches; its on-screen light limit is raised from 32 to 160 in `project.godot` so the stress run's 121 lights all draw (8 per object stays the default).

## Authoring throughput: one ship from Blender into Godot

Steps for this test, once the loader existed:

1. Blender: File, Export, glTF 2.0 (.glb), default +Y up. Same file Babylon gets.
2. Copy the .glb into `enginetest\assets`.
3. Add one line for it to the `SHIPS` table in `main.gd` (file name, slot, faction colours). If its bow is at -x, set `rot_y` to 180.
4. Run. No import step, no editor. The effect anchor points (nozzles, guns, breach) are found from the hull automatically.

Rough time: about 2 minutes per ship. Writing the loader the first time took about an hour, most of it finding three gaps in Godot's runtime glTF loading that the loader now fixes for every ship:

- Godot's standard material samples the normal map on the first UV set only and ignores glTF's `texCoord`. The hull files keep their normal and AO maps on the second set (`TEXCOORD_1`), so the loader swaps the two UV sets for such materials and rebuilds tangents on the new first set (about 130 to 230 ms per hull on the sandbox CPU). Without this the normal maps land on the wrong UVs.
- Runtime-loaded textures come without mipmaps; the loader makes them.
- Vertex colours (`COLOR_0`) are not applied to the base colour; the loader turns them on, as glTF requires. (A primitive with no material at all, like the unpainted barge exports used for testing in the sandbox, gets Godot's default material: rough, non-metal. glTF's default would be fully metal.)

The usual Godot route is different: put the .glb inside the project and let the editor import it (seconds per ship). The import compresses textures for the GPU, makes mipmaps, LODs and shadow meshes, and lets you override materials; the UV-set issue would still need a material override or a custom shader there. This test skips the editor so the PC needs no import step and Godot gets the same files Babylon does.
