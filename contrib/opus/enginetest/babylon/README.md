# A2 engine test: the Babylon.js half

Built to `../SPEC.md`. One page (`index.html`, Babylon.js 8.20.0 plus the glTF loader) and one runner (`run.py`, Python Playwright). Nothing comes from the game's effect, material or shader code (fx3d.js, vfx3d.js, wfx3d.js, gfx3d.js, ships3d.js): the effects are new for this test.

## Running it on the PC

Needs: the seven ship files in `enginetest\assets\` (see SPEC.md), Python with Playwright (the runner's `python_path.txt` Python already has it), internet the first time (run.py saves Babylon into `babylon\vendor\` so later loads, and the load time, never touch the CDN).

From `Downloads\voidsworn_test\enginetest\babylon`:

```
"%PYEXE%" run.py --res 3840x2160 --out ..\results\babylon_webgl2_3840x2160.json --shots ..\results\shots_babylon_3840x2160
"%PYEXE%" run.py --res 2560x1440 --out ..\results\babylon_webgl2_2560x1440.json --shots ..\results\shots_babylon_2560x1440
```

Each run: about 10 s to load, 3 s warm-up, 20 s measured, then the three stills (`battle_05.png`, `battle_12.png`, `close_13.png`). Nothing to click; the browser is headless.

Options: `--seconds 20`, `--warmup 3`, `--msaa 4`, `--headed` (show the window), `--angle d3d11` (default on Windows), `--debug-shots` (four extra views: top-down to check the bows, a Hegemony close-up for the key light, an explosion close-up, a hull hit close-up), `--extra shadows=0` (diagnostics). `--soft` is the software renderer for the cloud sandbox only; its numbers mean nothing.

Browser flags (real GPU): `--use-angle=d3d11 --enable-gpu-rasterization --ignore-gpu-blocklist --disable-gpu-vsync --disable-frame-rate-limit`. The runner's `sitecustomize.py` shim normally replaces Playwright's launch flags (and would drop the two vsync flags); run.py detects the shim and calls the original launch.

## What the result JSON holds

The SPEC.md format: engine `babylon`, renderer `webgl2`, width, height, seconds, frames, avg_ms, p99_ms (mean of the worst 1% of frames), max_ms, fps_avg, load_s, `gpu_mem_mb: null`. The notes field carries:
- the GL renderer string (so a silent fall back to software would show);
- the median frame time, and the GPU's own time per frame from a timer query when Chromium offers one;
- the nvidia-smi total memory before launch and at peak (WebGL has no memory counter of its own);
- a warning if the median frame time sits on a display refresh rate (vsync still on);
- how long the browser launch took (load_s itself starts at navigation).

How it measures:
- Frame time is the gap between two requestAnimationFrame callbacks. The warm-up holds the camera at the orbit start with the effects running; the counted 20 s is the orbit itself.
- load_s runs from navigation start to the first presented frame with all six ships, the sky, shaders and shadows ready.

## Choices made where SPEC.md leaves room (the Godot half should match these)

- **Handedness.** The scene is right-handed (`scene.useRightHandedSystem`), the same as glTF and Godot, so every coordinate in SPEC.md means the same thing in both engines and the glTF files load with no flip.
- **Fixed clock.** One clock t drives everything. The loop starts at t = 0, with nothing from before it. Stills: battle camera at orbit time t = 5.0 and 12.0 with the effects at the same t; close-up with the effects at t = 1.3 (on that clock the barge is 0.7 s into its slot, so the close-up shows its shield flash. The Hegemony explosion starts at 1.5 and the barge's at 1.8.)
- **Sky mapping.** Godot's panorama convention: u = atan2(x, -z) / 2 pi (wrapped to 0..1), v = acos(y) / pi, v = 0 is the top row of the PNG. Decoded from sRGB, no mipmaps, tone mapped with the frame.
- **Ambient.** A flat neutral term, 0.25 x key, times albedo times the AO map (like Godot's colour ambient). No reflections of the sky.
- **Lights.** Key intensity 3.2 (Hegemony hull measures about 224/255 at the 95th percentile, 233 max, in a close view). Full specular on both lights; Godot's `light_specular` defaults to 0.5, so set it to 1.0 there to match.
- **Shadows.** 4 cascades of 2048 x 2048 (the same texel budget as Godot's default 4096 atlas split four ways), max distance 320, PCF.
- **Anti-aliasing.** MSAA 4x. Godot's default is off; set `msaa_3d = 4x` there.
- **Bloom.** Threshold 0.8, weight 0.35. Babylon's blur kernel is in pixels, so it scales with the height (64 at 1440p, 96 at 2160p) to keep the glow the same size at both resolutions.
- **Ship anchors.** Bow = the front tip (mean of the vertices in the front 2% of the length). Bolt target = bow + 60 ahead + 10 to starboard. Shield and hull hits on the port side (+z); the hull hit point is a ray cast onto the hull at midship. Explosion 12 units to starboard of the ship's centre line.
- **Effects.** Three bolts 0.12 s apart, each 6 long, travelling 120 per second with a 0.1 s muzzle flash. Shield: ellipsoid 1.12 to 1.3 x the ship's half sizes, with a hit glow, a ring running out, a rim, and a mask that keeps it to the struck side. Hull hit: 18 orange sparks and 3 small flame puffs. Explosion: a core, 7 rolling flame sprites, 30 sparks and 6 smoke puffs (1.5 s).
- **Effect engine.** Every particle's start time and motion is fixed data on the GPU, and one clock drives the shaders. So the stills are exact and repeatable, and the effects cost almost no CPU each frame. Draw calls: 3 for all particles, plus 4 shields.
- **The unpainted barge exports** (sandbox only) have no material, and glTF's default (metal 1, rough 1) renders black with no environment map. Those files alone get metal 0, rough 0.75. The painted PC files keep their own materials.

## Authoring throughput (one ship from Blender into Babylon)

Steps:
1. In Blender: File, Export, glTF 2.0 (.glb), with the defaults (+Y up, apply modifiers). About 1 minute. The barge's painted files already come out of `project_paint.py` this way.
2. Copy the .glb next to the page. Seconds.
3. Load it: one `SceneLoader.LoadAssetContainerAsync` call, then centre and scale it, register it with the shadow generator and set the ambient colour on its materials. About 25 lines, written once for all six ships.
4. Check the orientation by eye. The barge was built with its bow at -x, so it needs a 180 degree turn about y. Add the turn and reload.

There is no import step: the browser reads the .glb as it is, and a re-export shows up on the next page reload (about 5 to 10 s). Rough time for a new ship: 5 to 10 minutes the first time, about 1 minute per later re-export.

The same job in the real game is longer, because the game does not load glTF. Hulls go through its own JSON plus WebP format (or `.vsm` for the barge) via `pixal_to_game.py` and `vsm_pack.mjs`. This test uses the standard loader so that both engines read the same files.
