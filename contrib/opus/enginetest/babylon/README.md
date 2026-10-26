# A2 engine test: the Babylon.js half

Built to `../SPEC.md`. One page (`index.html`, Babylon.js 9.30.0 plus the glTF loader; `--bjs 8.20.0` runs the first release used) and one runner (`run.py`, Python Playwright). Nothing comes from the game's effect, material or shader code (fx3d.js, vfx3d.js, wfx3d.js, gfx3d.js, ships3d.js): the effects are new for this test.

## Running it on the PC

Needs: the seven ship files in `enginetest\assets\` (see SPEC.md), Python with Playwright (the runner's `python_path.txt` Python already has it), internet the first time (run.py saves Babylon into `babylon\vendor\` so later loads, and the load time, never touch the CDN).

From `Downloads\voidsworn_test\enginetest\babylon`:

```
"%PYEXE%" run.py --res 3840x2160 --out ..\results\babylon_webgl2_3840x2160.json --shots ..\results\shots_babylon_3840x2160
"%PYEXE%" run.py --res 2560x1440 --out ..\results\babylon_webgl2_2560x1440.json --shots ..\results\shots_babylon_2560x1440
"%PYEXE%" run.py --stress --res 3840x2160 --out ..\results\babylon_webgl2_stress_3840x2160.json
"%PYEXE%" run.py --stress --res 2560x1440 --out ..\results\babylon_webgl2_stress_2560x1440.json
```

Ceiling and max runs (SPEC.md "Trimmed scope": main, stress 24, 40 ships and max, each at 1440p and 4K):

```
"%PYEXE%" run.py --ships 40 --res 3840x2160 --out ..\results\babylon_webgl2_ships40_3840x2160.json
"%PYEXE%" run.py --ships 40 --res 2560x1440 --out ..\results\babylon_webgl2_ships40_2560x1440.json
"%PYEXE%" run.py --max --res 3840x2160 --out ..\results\babylon_webgl2_max_3840x2160.json --shots ..\results\shots_babylon_max_3840x2160
"%PYEXE%" run.py --max --res 2560x1440 --out ..\results\babylon_webgl2_max_2560x1440.json --shots ..\results\shots_babylon_max_2560x1440
```

WebGPU and the old release, for comparison (any mode):

```
"%PYEXE%" run.py --webgpu --res 3840x2160 --out ..\results\babylon_webgpu_3840x2160.json
"%PYEXE%" run.py --bjs 8.20.0 --stress --res 3840x2160 --out ..\results\babylon820_webgl2_stress_3840x2160.json
```

Add `--vsync` to any run for a capped number: the uncapping flags are left off, and the JSON gets `vsync`, `refresh_hz` (read from the median frame gap, snapped to a common rate) and `dropped_frames` / `dropped_pct` against it. Headless Chromium paces vsync at its own 60 Hz; add `--headed` to pace to the real monitor.

`--stress` is SPEC.md's stress run: the six flagships plus 18 clones at 0.6 scale in rows z = +60, 0, -60 (x = -60 to +60, factions in the main order), every ship on the full loop with a breach, 0.17 s stagger in layout order (flagships first, then the rows from +z to -z, left to right), destruction every 4 s from t = 4, orbit radius 190 and height 85. The JSON says `"mode": "stress"` (the normal run says `"mode": "main"`). The clones share the flagships' geometry and materials.

Each run: about 10 s to load, 3 s warm-up, 20 s measured, then the five stills (`battle_05.png`, `battle_12.png`, `battle_126.png`, `close_20.png` for the barge, `breach_30.png` for the Hegemony breach). Nothing to click; the browser is headless.

Options: `--seconds 20`, `--warmup 3`, `--msaa 4`, `--headed` (show the window), `--angle d3d11` (default on Windows), `--debug-shots` (extra views: top-down to check the bows, a Hegemony close-up for the key light, a lance, a hull hit, the destruction at 12.9 s, the wreck at 15 s, engine trails, and a tight breach close-up), `--extra shadows=0` or `--extra hide=ribbons,sprites,smoke,streaks,rings,shards` (diagnostics). `--soft` is the software renderer for the cloud sandbox only; its numbers mean nothing.

Browser flags (real GPU): `--use-angle=d3d11 --enable-gpu-rasterization --ignore-gpu-blocklist --disable-gpu-vsync --disable-frame-rate-limit`. The runner's `sitecustomize.py` shim normally replaces Playwright's launch flags (and would drop the two vsync flags); run.py detects the shim and calls the original launch.

## What the result JSON holds

The SPEC.md format: engine `babylon`, renderer `webgl2`, width, height, seconds, frames, avg_ms, p99_ms (mean of the worst 1% of frames), max_ms, fps_avg, load_s, `gpu_mem_mb: null`. The notes field carries:
- the GL renderer string (so a silent fall back to software would show);
- the median frame time, and the GPU's own time per frame from a timer query when Chromium offers one;
- the nvidia-smi total memory before launch and at peak (WebGL has no memory counter of its own);
- a warning if the median frame time sits on a display refresh rate (vsync still on);
- how long the browser launch took (load_s itself starts at navigation);
- the JS work per frame (time inside the update and render calls) at its worst 1% and maximum, and the 8 worst frames as scene time: frame ms / JS work ms.

Each run also writes `<out>_trace.json` with a per-second trace of the counted 20 s (frames, avg, worst 1%, max, frames over 16.7 ms, max JS work) and the 15 worst frames. A long frame with small JS work was spent waiting in Chromium's frame pipeline (GPU process, compositor, presentation), not in this page's code.

Hitch forensics: the trace also lists every shader compile (`shader_compiles`) and every JS heap drop of 0.5 MB or more (`heap_drops`, which means a garbage collection) during the bench, with times. A spike next to one of those belongs to the page or to Babylon. A spike with neither, and with small JS work, is Chromium's frame pipeline.

How it measures:
- Frame time is the gap between two requestAnimationFrame callbacks. The warm-up holds the camera at the orbit start with the effects running; the counted 20 s is the orbit itself. A gap counts only if it starts after the warm-up.
- Before the warm-up (and after load_s is taken) the page steps through the moments that bring in a new shader variant (each loop phase, a drift fade half way, which turns the hull materials transparent, the destruction break, the chunk fade out and the fade in), waits for every shader to compile, then waits for the GPU to finish. So no shader compiles on first use during the measured 20 s. The chunk edge and fire batches stay active all the time (switched off by uniforms), so they compile up front too. The per-frame update allocates nothing.
- load_s runs from navigation start to the first presented frame with all six ships, the sky, shaders and shadows ready.

## Babylon 9.30 (moved from 8.20 so both engines run their latest stable release)

- **Default release:** 9.30.0 (babylonjs, babylonjs-loaders and babylonjs-gui 9.30.0, `@babylonjs/havok` 1.3.14), vendored under `vendor/bjs-9.30.0/` and `vendor/havok-1.3.14/`. run.py fetches them on the first run.
- **The old release still runs:** `--bjs 8.20.0` uses `vendor/bjs-8.20.0/` and Havok 1.3.10 for comparison. Main and stress modes run the same code on both and look the same (checked side by side in software).
- **New 9.x features used in max mode:** clustered lighting for the event lights.
- **9.x features not used:**
  - volumetric lighting exists only as a frame graph task, lit by one directional light through its shadow map. Moving the whole scene to the frame graph is outside the time box, and it would not be lit by the explosions, so the dust haze stays a hand-written post-process;
  - node particles: the effects are already static GPU particle data driven by one clock, so they would add nothing here.
- **`--webgpu`:** Babylon's WebGPU engine, reported as renderer `webgpu`. Babylon turns the page's GLSL into WGSL at run time, loading its glslang and twgsl helpers from cdn.babylonjs.com (the PC has internet). Stills in this mode come from a screenshot of the canvas element. Not tested here: the sandbox has no WebGPU and cannot reach that CDN.

## Ceiling and max modes: what each feature took in Babylon

- **Max-detail ships (`assets/hi/`):** in max and board modes run.py passes `hi=1` when all seven files are there (`--hi on` / `--hi off` to force it). The page then loads the ships from `assets/hi/` with the files' own PBR materials (base colour, ORM, normal with the files' tangents, emissive), not the faction-colour material of the hull2glb files. Emissive maps get a strength of 4 so windows and running lights reach the bloom threshold; a file that carries KHR_materials_emissive_strength keeps its own value. The detail-normal layer tiles 40 times over the hi files' single UV atlas, and the clustered lights sit on top. load_s includes decoding the 8K JPEG and PNG textures. WebGL keeps them uncompressed (RGBA8 with mips, about 358 MB per 8K texture, so about 10 GB for the 28 ship textures), unlike Godot's import, which compresses to GPU formats. The notes give the page's texture estimate and run.py's nvidia-smi peak.
- **40 ships (`--ships 40`):** the stress layout plus more rows of copies every 30 units in z, alternating sides (+90, -90, +120), with a partial last row (34 copies). The orbit radius is 150 + 40 per extra row pair (243, height 0.45 of the radius). The stagger is 0.17 s per ship, wrapped inside the 4 s loop, so every ship fires from the start.
- **Max mode (`--max`, mode `max`):** the six flagships in the main layout with every rich effect and the detail features below. The stills are written as `max_<name>.png`, plus one `hero_<code>.png` close-up per flagship at t = 3.0. Every still is taken from the main camera poses so it lines up with today's stills.
- **Dynamic lights, 40+ at once:** on Babylon 9.30 this uses the native `ClusteredLightContainer` (screen tiles plus depth slices, WebGL2 and WebGPU). Every material sees the container as one light, so there is no per-mesh limit to work around. Each frame the 64 brightest event lights (muzzle flashes, impacts, the lance emitter and its impact, hits, breach fire, pops, engines, burning chunks) are placed in its 64 point lights, and each lights every hull in range. On 8.20 (no container) the fallback below is used, which was hand-written on top of Babylon's lights. Babylon's standard PBR material takes a fixed number of lights per mesh (4 by default; the shader is compiled for that count). Raising it to 12 is built in. Each ship then gets a pool of 8 point lights. Every frame, JS gathers every event light (muzzle flashes, impacts, the lance emitter and its impact, hits, breach fire, pops, engines, burning chunks). It puts into each ship's pool the 8 that light that hull most (intensity times range falloff, from any ship, so a neighbour's impact lights this hull too). The notes report how many distinct event lights were lit at once (average and maximum).
- **Soft particles:** built-in depth pass (`enableDepthRenderer`, hulls, chunks, plates and rocks only) plus about 5 hand-written lines in the sprite shader. Sprites fade over 1.5 units where they meet a hull.
- **Volumetric smoke:** hand-written; Babylon has no built-in volume. The smoke rings start as a torus and swell into a soft, noise-broken puff as they drift and fade. Raymarched density fields (24 steps, 3D value-noise fbm, one shadow tap toward the key light) draw inside proxy boxes: one for the destruction fireball and smoke, one breach vent per ship, one box per ship for its four broadside smoke rings. Each stops at the hull depth, so hulls cut into the smoke. They replace the sprite versions in this mode.
- **Deep breaches:** hand-written parallax occlusion mapping in the decal shader. The cavity is a height field with steep jagged walls, a rough floor and broken frames, marched 28 steps along the view ray in tangent space (a cotangent frame from screen derivatives). It is lit by embers that deepen toward the floor.
- **SSAO:** built in (`SSAO2RenderingPipeline`, geometry buffer forced so the custom effect shaders stay out of it).
- **Reflections:** built in (`SSRRenderingPipeline`, same geometry buffer).
- **GI:** Babylon has no real-time GI. Image-based lighting from the sky stands in: `EquiRectangularCubeTexture` from the sky image, mipmapped, as the scene environment, used for reflections only. Its irradiance is zeroed because the neutral 0.25-of-key ambient already lights the diffuse; with both on, rocks and hulls looked washed out and soft.
- **Micro-detail normals:** built in (PBR `detailMap`). A procedural 256 px tile of panel seams and grain is made at load and tiled 6 times over the hull's box-projected UVs.
- **Contact shadows:** not built in. A small hand-written post-process marches 14 steps toward the key light over the hull depth pass and darkens creases. It darkens all light at those pixels, not only the key light.
- **TAA:** built in (`TAARenderingPipeline`, 8 samples). Its history reprojection needs Babylon's prepass renderer, which the custom effect shaders do not write, so it runs without reprojection: it accumulates while the camera holds still (the stills render 16 frames at the same time) and switches itself off while the camera moves (the benchmark orbit). MSAA is off in max mode.
- **Environment (SPEC.md "Environment"):** in max mode the page looks for `assets/env/`. If `sky_deadstar_8k.png` is there it is the sky and the IBL source. If `asteroids.json` is there, each rock mesh it names (`env/rocks/<mesh>.glb`) is drawn once with thin instances, tumbling about its own axis. Keys read per rock (the asset helper's format, with a few aliases): `mesh` (or `file`); `position`; `rotation` (a quaternion x, y, z, w, or Euler radians); `scale`; `spin_axis` and `spin_rate` (or `axis` and `spin`). Rocks of 15 units and up cast shadows. The dust haze is a hand-written post-process: a thin depth-based haze plus analytic in-scattering from the destruction flash and the 7 brightest event lights (engines included). With no `env/`, the starfield, no rocks and no haze.

## Push round, trimmed: physics, presentation, the game slice

- **Physics (max and board modes):** the Havok plugin (`@babylonjs/havok` 1.3.14 with Babylon 9.30, or 1.3.10 with `--bjs 8.20.0`, vendored as `HavokPhysics_umd.js` plus `.wasm`). The setup is hand-written:
  - each hull is an animated convex hull (from a thinned copy of its vertices) that follows the drift;
  - rocks are static spheres;
  - the destruction's 4 chunks are dynamic convex hulls (mass 300) pushed apart at the break, spinning;
  - debris comes from three pools of instanced chips (164 bodies) that bounce off hulls, rocks and each other and drift until they are reused. Chips come from the destruction (40), hull hits on Chorus and Deathless (8 each) and every breach (one every 0.7 s).
  - There is no gravity. The world steps at a fixed 1/60 s on the scene clock, so a still replays it from t = 0 and always comes out the same.
  - The JSON gets `physics_step_avg_ms` and `physics_step_max_ms` (the step time inside each frame) and the notes give the body count. In this mode the GPU debris shards for those sources and the analytic chunk smoke trails are switched off.
- **Presentation (max mode):**
  - depth of field on the close-ups and heroes, built in (DefaultRenderingPipeline, focused on the look-at point, f/2, 80 mm). It is switched on once at load and left neutral (f/32, far focus) for the battle camera, because switching it on and off between stills rebuilt the post chain and broke the frame. Its blur passes therefore also run, and count, in the max-mode benchmark;
  - screen shake scaled by weapon weight (broadside 0.25 per gun, lance 0.5, hit 0.6, destruction 2.5) and by distance. It is a deterministic function of t, so the stills shake the same each time;
  - colour grading with built-in curves (cool shadows, warm highlights).
  - Dropped per the trimmed scope: kill-cam, motion blur, lens effects, light shafts.
- **Game slice (`--board`, mode `board`):** max mode seen from a tactical camera pitched 55 degrees, over a hex board of flat-topped hexes 20 units corner to corner, 20 by 14, at y = -6. One shader draws it: anti-aliased grid lines (screen-space derivatives, so 1 to 2 px at any resolution) and the movement range (3 hexes) of the selected ship, which follows it as it drifts. Also:
  - hover outline: built-in `renderOutline`, picked under the mouse;
  - selection ring on click: the page counts rendered frames from the click to the first frame that drew the ring, plus one animation frame to reach the screen. run.py hovers and clicks the Corsair and writes `click_to_visible_frames` and `click_to_visible_ms`;
  - labels with hull and shield bars: Babylon GUI (`babylon.gui.min.js`, vendored) with an ideal height of 1440. It scales with the render height (25 px names at 1440p, 38 px at 4K, nameplate size) and renders at the real canvas size, so it stays sharp.
  - `--ui html` swaps the labels for HTML over the canvas, positioned each frame from the projected ship centres. Babylon GUI redraws and re-uploads its full-screen texture (about 33 MB at 4K) every frame while the labels follow the drifting ships. That is the main suspect for the board's 54 to 64 ms worst frames, and the HTML run tells the two apart. Stills in that mode are page screenshots.
  - Stills: `board_03.png` and `board_126.png`, with the Hegemony selected and the Corsair hovered.
- **Standalone:** none; Babylon stays a browser page (trimmed scope).

PC lines for the board slice:

```
"%PYEXE%" run.py --board --res 3840x2160 --out ..\results\babylon_webgl2_board_3840x2160.json --shots ..\results\shots_babylon_board_3840x2160
"%PYEXE%" run.py --board --res 2560x1440 --out ..\results\babylon_webgl2_board_2560x1440.json --shots ..\results\shots_babylon_board_2560x1440
```

## Choices made where SPEC.md leaves room (the Godot half should match these)

- **Handedness.** The scene is right-handed (`scene.useRightHandedSystem`), the same as glTF and Godot, so every coordinate in SPEC.md means the same thing in both engines and the glTF files load with no flip.
- **Fixed clock.** One clock t drives everything, t = 0 at scene start, nothing from before it (the persistent engines and breaches are already running at t = 0). Ship i's 4 s loop starts at 0.5 i. Stills: battle camera at orbit time t = 5.0, 12.0 and 12.6 with the effects at the same t; barge close-up at t = 2.0; Hegemony breach close-up at t = 3.0. In the benchmark the camera holds at the orbit start for the 3 s warm-up while t runs, then orbits.
- **Drift.** x offset = ((3 t + 20) mod 40) - 20: the layout position is the middle of the 40 unit loop and t = 0 is the layout. Wraps fall at t = 6.67, 20, 33.3; the ships fade out over the second before and in over the second after (`mesh.visibility`, so they turn see-through for that moment). Every effect rides with its ship; particles keep the ship's velocity after they leave it.
- **Sky mapping.** Godot's panorama convention: u = atan2(x, -z) / 2 pi (wrapped to 0..1), v = acos(y) / pi, v = 0 is the top row of the PNG. Decoded from sRGB, no mipmaps, tone mapped with the frame.
- **Ambient.** A flat neutral term, 0.25 x key, times albedo times the AO map (like Godot's colour ambient). No reflections of the sky.
- **Lights.** Key intensity 3.2 (Hegemony hull measures about 224/255 at the 95th percentile, 233 max, in a close view). Full specular on both lights; Godot's `light_specular` defaults to 0.5, so set it to 1.0 there to match.
- **Shadows.** 4 cascades of 2048 x 2048 (the same texel budget as Godot's default 4096 atlas split four ways), max distance 320, PCF.
- **Anti-aliasing.** MSAA 4x. Godot's default is off; set `msaa_3d = 4x` there.
- **Bloom.** Threshold 0.8, weight 0.35. Babylon's blur kernel is in pixels, so it scales with the height (64 at 1440p, 96 at 2160p) to keep the glow the same size at both resolutions.
- **Ship anchors** (found from the mesh, not hand placed). Bow = the mean of the vertices in the front 2% of the length. Nozzles = k-means on the aft 5% of the vertices (2 for slim hulls, 3 for wide ones). Guns, breach and the starboard hit point are ray casts onto the hull: guns at 0.28, 0.1, -0.08, -0.26 of the length along the upper port flank; breach at -0.17 of the length, upper port flank; hit at midship, starboard.
- **Engines.** Core sprite per nozzle, a flickering plume ribbon 1.5 ship widths long, a 60 unit trail ribbon that wavers, cools from the engine colour to blue-grey and thins out in density. I read "thinning" as density: the trail widens slightly as it diffuses. Corsair: coughing plume and core, a dirtier trail, soot puffs.
- **Broadside.** Four guns 80 ms apart, bow to stern. Each gun has a flash, a fireball core, a flame tongue, a smoke ring that drifts and lingers 2 s, smoke puffs, and a tracer at 160 per second to a point 70 off the port side. The impact has a flash, sparks, 6 tumbling debris shards and smoke.
- **Lance.** Charge flare 0.25 s before; a 0.7 s beam with a white core, faction glow and a shimmer along it; an emitter flare; an impact flare with a 44 spark fountain and smoke.
- **Hit at 2.4 s.** A shell tracer arrives from far starboard (fired 0.5 s before). Shielded ships: an ellipsoid shield with three ripple rings running out from the hit, a bright core, a rim, and a mask keeping it to the struck side, 0.6 s. Corsair's shield flickers and is patchy. Chorus and Deathless: a flash, a core, 22 sparks, 12 hot debris shards, flame and smoke.
- **Breach.** A projected decal (Babylon's `CreateDecal`) with a jagged torn hole and parallax embers inside (the dark recess), a white-hot jagged edge, a charred ring with glowing cracks, and soot. Nine bent torn plates stick out around the rim with hot roots. Then a venting gas jet that wavers and puffs, tumbling debris shards, licking flames, spark showers every 2.3 s and a secondary pop every 3.7 s.
- **Destruction.** Every 12 s from t = 12. The 0.6 scale Hegemony copy is the Hegemony's own mesh cut by 3 slanted planes into 4 chunks. Squibs pop on the hull from 12.05, then at 12.4 the hull breaks: a flash, two shockwave rings, a fireball core, 18 rolling flame sprites, 12 dark smoke clouds, 110 embers and 60 debris shards. The chunks tumble apart, with glowing break edges (the shared edges of the cut) and fire and squibs along them. Each chunk leaves a smoke trail. The aft-middle chunk is the slow burning wreck. The chunks fade out from 9 to 10 s after the event, and the whole ship fades back in over the last 2 s before the next one.
- **Light on the hulls.** Each ship has one point light (its own hull only) that follows its strongest effect: muzzle flashes, lance charge and fire, the hit, otherwise the flickering breach and its pops. The destruction has one point light for the flash and fireball, lighting every hull in range. All are point lights with a linear range falloff, no shadows.
- **Effect engine.** Every particle's start time, period and motion is fixed data on the GPU, and one clock drives the shaders, so the stills are exact and repeatable. Per frame the CPU only moves the ships, the shields, the 4 chunks and the 7 lights. Draw calls for all particles: 6 batches (smoke, rings, glow sprites, streaks, ribbons, debris shards), plus 4 shields, 6 decals, 6 plate sets and 4 chunks with their edges and fires.
- **The unpainted barge exports** (sandbox only) have no material, and glTF's default (metal 1, rough 1) renders black with no environment map. Those files alone get metal 0, rough 0.75. The painted PC files keep their own materials.

## Authoring throughput (one ship from Blender into Babylon)

Steps:
1. In Blender: File, Export, glTF 2.0 (.glb), with the defaults (+Y up, apply modifiers). About 1 minute. The barge's painted files already come out of `project_paint.py` this way.
2. Copy the .glb next to the page. Seconds.
3. Load it: one `SceneLoader.LoadAssetContainerAsync` call, then centre and scale it, register it with the shadow generator and set the ambient colour on its materials. About 25 lines, written once for all six ships.
4. Check the orientation by eye. The barge was built with its bow at -x, so it needs a 180 degree turn about y. Add the turn and reload.

There is no import step: the browser reads the .glb as it is, and a re-export shows up on the next page reload (about 5 to 10 s). Rough time for a new ship: 5 to 10 minutes the first time, about 1 minute per later re-export.

The same job in the real game is longer, because the game does not load glTF. Hulls go through its own JSON plus WebP format (or `.vsm` for the barge) via `pixal_to_game.py` and `vsm_pack.mjs`. This test uses the standard loader so that both engines read the same files.
