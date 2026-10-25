# A2 engine test: the Babylon.js half

Built to `../SPEC.md`. One page (`index.html`, Babylon.js 8.20.0 plus the glTF loader) and one runner (`run.py`, Python Playwright). Nothing comes from the game's effect, material or shader code (fx3d.js, vfx3d.js, wfx3d.js, gfx3d.js, ships3d.js): the effects are new for this test.

## Running it on the PC

Needs: the seven ship files in `enginetest\assets\` (see SPEC.md), Python with Playwright (the runner's `python_path.txt` Python already has it), internet the first time (run.py saves Babylon into `babylon\vendor\` so later loads, and the load time, never touch the CDN).

From `Downloads\voidsworn_test\enginetest\babylon`:

```
"%PYEXE%" run.py --res 3840x2160 --out ..\results\babylon_webgl2_3840x2160.json --shots ..\results\shots_babylon_3840x2160
"%PYEXE%" run.py --res 2560x1440 --out ..\results\babylon_webgl2_2560x1440.json --shots ..\results\shots_babylon_2560x1440
"%PYEXE%" run.py --stress --res 3840x2160 --out ..\results\babylon_webgl2_stress_3840x2160.json
"%PYEXE%" run.py --stress --res 2560x1440 --out ..\results\babylon_webgl2_stress_2560x1440.json
```

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

How it measures:
- Frame time is the gap between two requestAnimationFrame callbacks. The warm-up holds the camera at the orbit start with the effects running; the counted 20 s is the orbit itself. A gap counts only if it starts after the warm-up.
- Before the warm-up (and after load_s is taken) the page steps through the moments that bring in a new shader variant (each loop phase, a drift fade half way, which turns the hull materials transparent, the destruction break, the chunk fade out and the fade in), waits for every shader to compile, then waits for the GPU to finish. So no shader compiles on first use during the measured 20 s. The chunk edge and fire batches stay active all the time (switched off by uniforms), so they compile up front too. The per-frame update allocates nothing.
- load_s runs from navigation start to the first presented frame with all six ships, the sky, shaders and shadows ready.

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
