# Performance and Snappiness Review (main, Nov 24 2026)

- **Reviewer:** Neon (Gemini 4 Neon High, T3 Code, R428)
- **Commit audited:** `7c542ab89` (`main`)
- **Scope:** Full read-only audit of loading times, stutters in play, input and UI snappiness, bugs and dead code, and memory/VRAM across `godot/` (excluding open work already in flight, assessed separately below).
- **Method:** Direct source code and asset inspection on `main`. Every code path and file size is `OBSERVED`; every timing estimate (ms, seconds) and VRAM/RAM calculation derived from code and formats is marked `INFERRED`.

---

## Top 10 (Sorted by How Much the Player Feels It)

1. **R01 planet relief texture allocates 682.7 MiB RAM + 682.7 MiB VRAM and is double-sampled per pixel** (`INFERRED` ~500 MiB VRAM/RAM saved, ~3-4x faster CPU mipmap build, half relief texture bandwidth in planet battles) - [Finding 1](#1-r01-8k-planet-relief-allocates-6827-mib-ram--6827-mib-vram-and-double-samples-per-pixel)
2. **Upfront death-cut precompute blocks battle load for every ship and serializes all 8 workers on one Mutex** (`INFERRED` 2-8+ s added to battle load on PC) - [Finding 2](#2-upfront-death-cut-precompute-blocks-battle-load-and-serializes-all-8-workers-on-one-mutex)
3. **Baked planets run 3 separate RenderingDevices, 64 `rd.sync()` stalls per pass, and an 8.4M-pixel GDScript loop on every load** (`INFERRED` ~1.6 s on warm loads and ~4-8 s on cold planet bakes) - [Finding 3](#3-baked-planets-spin-up-3-renderingdevices-64-rdsync-stalls-per-pass-and-an-84m-pixel-gdscript-loop-on-every-load)
4. **Campaign sector map freezes synchronously: 25-40 full 3D ships, 6x 20K-tri GDScript icospheres (5 discarded), and 18 shadow cubemap passes** (`INFERRED` 0.8-2.5 s map-open freeze + heavy High-quality GPU shadow cost) - [Finding 4](#4-campaign-sector-map-synchronous-load-freeze-and-18-shadow-cubemap-passes)
5. **Dead `fx/atlases/rebake/` flipbooks waste ~55 MB on disk and synchronously load into VRAM on every battle warmup** (`INFERRED` ~55 MB dead `.pck` weight, up to 72 MB if `s1`/`s2` dropped, + 100-350 ms battle warmup hitch + ~100+ MiB VRAM) - [Finding 5](#5-dead-fxatlasesrebake-flipbooks-waste-55-mb-on-disk-and-load-into-vram-on-every-battle-warmup)
6. **Artificial fixed waits add 0.6-2.5 s of dead hold on loads, auto-end ship handoff, battle end screen, and title reveal** (`OBSERVED` 500 ms+12 frames on loads, 800 ms auto-end lock, 2.45 s to end-card focus, 500 ms title showcase wait) - [Finding 6](#6-artificial-fixed-waits-add-06-25-s-of-dead-hold-across-loads-turn-handoff-and-menus)
7. **First ship death rebuilds all terrain edge meshes synchronously on the kill frame, and first styled/Eclipse deaths hit un-warmed materials and unpooled GPUParticles3D** (`INFERRED` 15-80 ms hitch on first kill and first Eclipse/faction death) - [Finding 9](#9-first-death-rebuilds-all-terrain-edges-synchronously-and-hits-un-warmed-eclipse-and-styled-tear-materials)
8. **Synchronous full-catalog SFX loading and `.import` parsing repeats from scratch on every battle start** (`INFERRED` 150-500 ms per battle start) - [Finding 8](#8-synchronous-full-catalog-sfx-loading-and-import-parsing-repeats-on-every-battle-start)
9. **Hovering across battle hexes runs `board.refresh()` twice, rebuilds firing-arc meshes/materials, and Battle HUD calls `reset_size()` every frame and redraws the ledger on every mouse pixel** (`INFERRED` 2-12 ms hover/UI micro-stutters on mouse sweep) - [Findings 12](#12-hovering-battle-hexes-runs-boardrefresh-twice-rebuilds-firing-fans-and-updates-tooltips-every-pixel) and [14](#14-battle-hud-calls-reset_size-every-frame-redraws-ledger-every-mouse-pixel-and-rebuilds-pause-menu-on-open)
10. **Mid-battle background debris cut stalls a live gameplay frame via synchronous `surface_get_arrays()` + MultiMesh install, and ghost move previews clone the whole 3D ship tree on every plan** (`INFERRED` 10-40 ms mid-battle hitch when debris cut finishes; 5-25 ms hitch when planning moves) - [Findings 10](#10-mid-battle-background-debris-cut-stalls-a-live-frame-on-install) and [11](#11-ghost-preview-duplicates-the-whole-3d-ship-tree-on-every-plan-and-play_glide-runs-241-curve-scans)

---

## Open Work: Agree / Disagree

None of the items below are reported as missing. Here is where the code on `main` agrees or disagrees with their approach:

- **PR 1445 (battle load and title backdrop: ships built a few per frame, threaded hull loading, `Sfx.silent`, `stop_build()`, sky radiance incremental):** **Agree strongly** with slicing ship construction across frames, moving hull resource loads to worker threads, and switching sky radiance to `PROCESS_MODE_INCREMENTAL` (LOAD34b). **Gap to watch:** PR 1445 does not eliminate upfront `DEATH.precompute()` serialization on `_lanes_lock` (Finding 2), synchronous SFX catalog reload on every battle (Finding 8), or `load_screen.settle()`'s mandatory 500 ms + 12-frame floor (Finding 6).
- **PR 1776 (Planets V2, already merged on `main`):** **Agree** with replacing 8-bit mip averaging on baked height maps with single-channel `FORMAT_RF` (`world_bake.gd:199`) and moving away from expensive procedural per-pixel terrain shaders. **Disagree on two implementation choices that landed in `main`:** (1) R01's `relief` stayed 4-channel `FORMAT_RGBAF` (682.7 MiB RAM + 682.7 MiB VRAM, Finding 1) instead of splitting height into `FORMAT_RF` + a lower-res RG8 roughness/cloud texture; (2) baked planets still spin up 3 local `RenderingDevice`s with 64 `rd.sync()` stalls each and decode 8.4M pixels in GDScript on every load (Finding 3).
- **Issue 1519 / PR 1950 (battle to title: draw title first, free battle in slices behind it):** **Agree** with freeing the battle in slices behind the title and skipping combat-only preparation on the title showcase. **Small note:** Because `main.gd:350` still waits 0.5 s before starting the showcase and `title.gd:698` fades it in over 2.5 s, cutting the fade/wait after sliced freeing lands will make returning to title feel noticeably faster.
- **Issue 1518 (close during load, folded into PR 1445):** **Agree.** Adding cancellation gates (`stop_build()`) and avoiding blocking worker joins on quit is the right design. Make sure the world bake worker (`world_bake.gd:223-258`) and death cut `WorkerThreadPool` group tasks (`fx_death.gd:1793,1814`) also check an abort flag inside loops so closing mid-bake or mid-cut does not wait seconds for a single ship or 4K pass to finish.
- **PR 1852 / Issue 1843 (round 2 150-190 ms pipeline compile hitch on firing-arc outline material):** **Agree** with warming the firing-arc outline shader/material variant before gameplay. **Watch out:** `_fans()` (`battle.gd:3364-3399`) still tears down and rebuilds `SurfaceTool` meshes and `StandardMaterial3D` instances on every hovered hex or weapon-ready state change (Finding 12). Caching/reusing the fan material and mesh per ship avoids repeating setup work even after the pipeline is warm.
- **Issue 1645 (round 4 Hullbreaker ~100 ms hitch):** **Agree** it needs targeted profiling on the PC, and code reading on `main` points to four concrete Hullbreaker (`corsair`) round-4 candidates to instrument first:
  1. `fx_death.gd:3214-3233` (`_patch_tear()`): spawns physical Jolt `RigidBody3D` debris plates during the death tell, waking Jolt physics and creating new `RigidBody3D`/`CollisionShape3D` nodes when the debris pool runs short.
  2. `fx_death_beats.gd:435-499` (`_tether()`): mutates Jolt `RigidBody3D` velocities across 9 beats plus cook-offs.
  3. `fx_ship.gd:1786-1800` (`_build_engines()` at line 1792): engine damage tier transitions rebuild engine batches and allocate 9 soot cough emitters per nozzle for Hullbreakers (`engine_extra == "soot"`).
  4. `fx_ship.gd:2068-2113` (`flush_damage()`): triggers `BREACH.apply()` + `_cut_refresh()`, swapping hull meshes and queueing a fresh death cut after hull damage crosses a threshold (typical around round 3-4).
- **Issue 1780 / PR 1960 (caching 48 `Shader.new()` calls, BC7 world VRAM compression, FSR 2.2 AA option, empty volumetric fog gate, asteroid distance fade/LOD):** **Agree strongly** with moving all 48 `Shader.new()` sites (including `map3d*`, `blocker_visuals`, `fx_hull`, `world_*`, `board`, `squadron_*`) to `.gdshader` files, gating empty `FogVolume`s, adding FSR 2.2 AA options, and adding asteroid distance fade/LOD. **Disagree on two VRAM/load choices in PR 1960:**
  1. PR 1960 encodes R01's static 8K color map to BC7 at runtime on the player's CPU (taking **15.7 seconds** on the single serial world-bake worker on cold install). Because R01 is a static authored asset, pre-compressing it to BC7 at build/import time avoids a 15.7 s cold-install stall completely.
  2. PR 1960 compressed R01 `colour` (128 MiB -> 42.7 MiB base) while leaving R01 `relief` at 4-channel `FORMAT_RGBAF` (**682.7 MiB** RAM + **682.7 MiB** VRAM, ~12x larger than the compressed color map). Splitting R01 relief (Finding 1) delivers 5x more VRAM savings than compressing `colour`.
- **Issue 1438 / PR 1963 (smaller download: source ship GLBs excluded from export, merged on `main`):** **Agree** with excluding `assets/ships/*.glb`. **Gap:** `export_presets.cfg:11` still bundles ~74+ MB of unused assets, dead `s1`/`s2` flipbooks, unreferenced portraits, dev benches, and legacy rockgen GLBs (Findings 5 and 27).

---

## All Findings (Sorted by Player-Felt Impact)

### 1. R01 8K planet relief allocates 682.7 MiB RAM + 682.7 MiB VRAM and double-samples per pixel
- **Category:** Memory & VRAM / Loading / GPU
- **Evidence:** `OBSERVED` (code and dimensions); size and cost `INFERRED`
- **Location:** `godot/world/world_bake.gd:290` (`_work`), `godot/world/world_planet.gd:166` (`install_rocky`), `godot/world/world_planet.gd:300,306` (`ROCKY_SURFACE`)
- **Quotes:**
  - `world_bake.gd:290-291`: `if job.get("float_mips", false): authored_image.convert(Image.FORMAT_RGBAF)` / `authored_image.generate_mipmaps()`
  - `world_planet.gd:166`: `var kd: String = baker.request_authored(R01_DIR + "relief.json", R01_SIZE, true, urgent)`
  - `world_planet.gd:300,306`: `vec4 data = r01_sample(surface_data, d, lod);` / `float h = r01_height(d, surface_data, lod);` (`r01_height` calls `r01_sample(surface_data, ...)` a second time at the exact same `d, lod`)
- **Player-visible cost:** `INFERRED`: Converting an 8192x4096 RGBA8 image to `FORMAT_RGBAF` (16 bytes/pixel) with full mipmaps (`4/3` multiplier) allocates **682.7 MiB** in CPU RAM (kept in `world_bake` cache) plus **682.7 MiB** in GPU VRAM (~1.36 GiB total for one texture; adding 8K `colour` brings one planet to ~853 MiB VRAM before PR 1960, or ~740 MiB VRAM even after PR 1960). CPU `generate_mipmaps()` on 512 MiB of `RGBAF` floats also adds `INFERRED` ~1.5-3.5 s on the bake worker thread. In the fragment shader, `r01_height(d, surface_data, lod)` re-computes `atan`/`acos`/`exp2` and re-samples the 683 MiB texture at the exact same coordinate already loaded into `data`, wasting GPU memory bandwidth on every planet pixel.
- **Fix:** Split R01 relief into a 1-channel `FORMAT_RF` height map (matching `world_bake.gd:199`, 170.7 MiB with mips, zero height precision loss) and a separate 2K or 4K RG8/BC7 roughness+cloud map (~10-42 MiB), saving **~500 MiB VRAM + ~500 MiB RAM** and cutting mipmap build time ~3-4x. In `ROCKY_SURFACE`, decode `h` directly from `data.r`/`data.g` instead of calling `r01_height(d, surface_data, lod)` again.
- **Confidence:** `high`

---

### 2. Upfront death-cut precompute blocks battle load and serializes all 8 workers on one Mutex
- **Category:** Loading / Stutters
- **Evidence:** `OBSERVED` (code); time `INFERRED` (anchored by code comment noting 5.4 s for A16 alone on PC)
- **Location:** `godot/fx/fx.gd:1528-1581` (`prepare_battle_hulls`), `godot/fx/fx_death.gd:1758-1816` (`_cut`)
- **Quotes:**
  - `fx.gd:1562-1565`: `while started < jobs.size() and live.size() < LOAD_CUT_LIMIT:` / `live.append({"ship": j["ship"], "task": WorkerThreadPool.add_task(...)})`
  - `fx_death.gd:1792-1796`: `_lanes_lock.lock()` / `var gid := WorkerThreadPool.add_group_task(func(i: int) -> void: _cut_surface(...))` / `WorkerThreadPool.wait_for_group_task_completion(gid)` / `_lanes_lock.unlock()`
  - `fx_death.gd:1813-1816`: `_lanes_lock.lock()` / `var sid := WorkerThreadPool.add_group_task(func(i: int) -> void: _seal_piece(pieces[i]), ...)` / `WorkerThreadPool.wait_for_group_task_completion(sid)` / `_lanes_lock.unlock()`
- **Player-visible cost:** `INFERRED`: `battle.gd:870` awaits `gfx.prepare_battle_hulls()` under the loading screen cover for EVERY ship on the board (including duplicate classes and player ships that may never die). Each cut runs GDScript triangle splitting (up to 200k verts/surface), boundary welding, ear-clipping caps, and mesh uploads. Comment at `fx_death.gd:1780` states A16 alone took 5.4 s on PC. Although `prepare_battle_hulls()` tries to run `LOAD_CUT_LIMIT = 8` ships in parallel, `_lanes_lock` serializes `_cut_surface` and `_seal_piece` so only one ship executes at a time, adding `INFERRED` **2-8+ s** to battle load on medium/large fleets.
- **Fix:** (1) Share authored-seam cut geometry across ships of the same hull class (or pre-bake seam-cut meshes into `gen/` at build time). (2) Defer runtime death cuts out of the loading cover: start them at low priority (1-2 worker lanes) once the battle is live, prioritizing damaged ships first (or on first hull hit, well before a ship dies). (3) Remove or narrow `_lanes_lock` (use a semaphore or lower per-ship lane budget instead of serializing all ships).
- **Confidence:** `high`

---

### 3. Baked planets spin up 3 RenderingDevices, 64 `rd.sync()` stalls per pass, and an 8.4M-pixel GDScript loop on every load
- **Category:** Loading / CPU
- **Evidence:** `OBSERVED` (code); warm time `OBSERVED` in code comment (1.6 s), cold time `INFERRED`
- **Location:** `godot/world/world_planet.gd:116-123` (`_build_baked`), `godot/world/world_bake.gd:249-251` (`_process`), `godot/world/world_bake.gd:299-337` (`_work`, `height_float`), `godot/world/world_bake.gd:515-559` (`_compute`)
- **Quotes:**
  - `world_planet.gd:117-119`: `var k0 := BAKE.request_bake(..., {"pass_id": 0}, sz, 1, false, true)` / `k1 ... {"pass_id": 1}` / `k2 ... {"pass_id": 2}, sz, 1, true, true`
  - `world_bake.gd:312`: `if img != null and job.get("half_mips", false): img = height_float(img)`
  - `world_bake.gd:318-319`: `Neon (PR 1776 review, item 6): this runs on the worker for every cold and warm load of a baked look, about 1.6 s per 4K map on the PC.`
  - `world_bake.gd:518,546-555`: `var rd := RenderingServer.create_local_rendering_device()` / `for y in range(0, size.y, 32):` (`size.y = 2048` -> 64 tiles) `rd.submit()` / `rd.sync()`
- **Player-visible cost:** `INFERRED`: Every terran/ice/volcanic planet queues 3 serial 4096x2048 jobs on the single `_thread` worker (`world_bake.gd:249`). On a cold bake, each pass creates and destroys a new local Vulkan `RenderingDevice`, compiles SPIR-V from GLSL source, executes **64 synchronous CPU-GPU `rd.sync()` stalls** (192 stalls total), and CPU-encodes a 4K PNG. On **every** load (even warm disk-cache hits), `pass_id = 2` runs `height_float()` in GDScript over 8,388,608 pixels (`~1.6 s` on PC per comment) plus CPU `generate_mipmaps()`. Cold planet battle loads lose `INFERRED` **4-8 s**; warm loads still lose **~1.6-2.2 s** waiting on the serial bake worker.
- **Fix:** (1) Cache the decoded `FORMAT_RF` binary bytes (`.rf.bin` or `.exr`) alongside/instead of the PNG so warm loads read directly into `Image.create_from_data()` in ~15 ms instead of running `height_float()` in GDScript. (2) Keep one persistent local `RenderingDevice` and cached SPIR-V shader per pass on the worker, and dispatch fewer larger tiles (e.g., 4-8 tiles or 1 dispatch) instead of 64 `rd.sync()` stalls. (3) Combine passes 0, 1, and 2 into one multi-output compute shader so shared FBM noise is evaluated once instead of 3 times.
- **Confidence:** `high`

---

### 4. Campaign sector map synchronous load freeze and 18 shadow cubemap passes
- **Category:** Loading / Stutters / GPU
- **Evidence:** `OBSERVED` (code); timing `INFERRED`
- **Location:** `godot/ui/campaign/map3d.gd:159,207,331,469-476` (`_apply_quality`, `_load_sector`, `_map_ship_rim`), `godot/ui/campaign/map3d_props.gd:228-263` (`rock_meshes`), `godot/ui/campaign/map3d_system.gd:292-293` (`build`)
- **Quotes:**
  - `map3d.gd:207`: `_build(sig)` (synchronous build of all stops, up to 25-40 full 3D `ShipView` hulls + `_map_ship_rim` surface material duplicates + up to 14 boneyard dead hulls in one frame)
  - `map3d.gd:475`: `var material = source.duplicate(); material.rim_enabled = true; material.rim = maxf(material.rim, 0.28); material.rim_tint = 0.15`
  - `map3d_props.gd:228-262`: `static func rock_meshes(hi: bool) -> Array:` (builds 6 subdivision-5 icospheres = 20,480 tris each in pure GDScript with 3 `FastNoiseLite` + 20-33 crater `acos`/`exp` calls per vertex; `hollow_asteroid` only uses index `[2]`, discarding the other 5!)
  - `map3d.gd:159,331` + `map3d_system.gd:292-293`: `vp.positional_shadow_atlas_size = 4096 if hi else 0` / `l.shadow_enabled = sun.shadow_enabled and float(sys.approach["infall"]) > 0.0` / `l.omni_shadow_mode = OmniLight3D.SHADOW_CUBE`
- **Player-visible cost:** `INFERRED`: Opening a sector map stalls the main thread for **0.8-2.5 s** on a single frame (especially in `frontier` where `rock_meshes(true)` runs ~1.5M+ GDScript trig/noise iterations to build 6 high-poly meshes when only 1 is used, plus synchronous ship instantiation and per-surface `source.duplicate()` across every map stop). Once open on High quality, up to 3 `OmniLight3D`s (`sun` + 2 tier copies at `map3d.gd:329-333`) cast `SHADOW_CUBE` (6 faces each = up to **18 scene shadow passes per frame**) into a 4096x4096 atlas inside a 4x MSAA SubViewport, costing `INFERRED` **3-8 ms/frame** on GPU.
- **Fix:** (1) In `map3d_props.gd`, build only the 1 asteroid mesh needed for `hollow_asteroid()` (or pre-bake it as a `.res` mesh) and cut subdivision from 5 (20,480 tris) to 3-4 (1,280-5,120 tris). (2) Slice `_build(sig)` stop ship instantiation across frames behind the loading cover, and share rim-modified materials by `(source_rid)` instead of calling `source.duplicate()` per ship surface. (3) On the campaign map lights, disable shadows on the 2 extra tier `OmniLight3D`s (only the main sun needs shadows) and switch `SHADOW_CUBE` to `SHADOW_DUAL_PARABOLOID` (2 passes instead of 6) or a directional key light.
- **Confidence:** `high`

---

### 5. Dead `fx/atlases/rebake/` flipbooks waste ~55 MB on disk and load into VRAM on every battle warmup
- **Category:** Memory & VRAM / Loading / Dead Code
- **Evidence:** `OBSERVED` (disk inventory: 69 PNGs = 101.56 MB; caller scan); load/VRAM size `INFERRED`
- **Location:** `godot/fx/fx.gd:2165-2175` (`warmup`), `godot/fx/fx_death.gd:266,382`, `godot/fx/fx_weapons.gd:2479,2508`
- **Quotes:**
  - `fx.gd:2171-2174`: `for variant in 3:` / `var tex: Texture2D = DEATH.route_texture(rel, variant)`
  - `fx_weapons.gd:2512`: `Both pictures use the lopsided baked seed (s0) turned at random: the round seeds (s1, s2) drew` (rejected as too even/weird; `hull_impact_material` and `fx_death.gd:382` hardcode `seed_index = 0`)
- **Player-visible cost:** `OBSERVED` on disk: `godot/fx/atlases/rebake/` totals **101.56 MB** (69 PNGs up to 3072x3072). `s1/death/*` (27.16 MB), `s2/death/*` (25.88 MB), `s1/weapons/macro/*` + `s2/weapons/macro/*` (~1.3 MB), and 6 preview strip PNGs (`*_s0/s1/s2.png`, 0.62 MB) = **~55 MB** have zero gameplay callers (if `_blast_inner` and `_smoke_clump` also switch to `s0` with random rotation/aspect, **72.21 MB** of `s1/` + `s2/` can be deleted). Yet `fx.gd:2171` loops `for variant in 3:` and synchronously loads all 63 textures into VRAM during every battle warmup, adding `INFERRED` **~100+ MiB VRAM** (BC7 + mipmaps for 3K atlases) and **100-350 ms** to every battle load.
- **Fix:** Remove the unused `s1/` and `s2/` atlases and preview strips from `godot/fx/atlases/rebake/` (saving ~55-72 MB of `.pck` download and disk size), and change `fx.gd:2171` to warm only the variants actually referenced in gameplay (`variant = 0`).
- **Confidence:** `high`

---

### 6. Artificial fixed waits add 0.6-2.5 s of dead hold across loads, turn handoff, and menus
- **Category:** Input & UI / Loading
- **Evidence:** `OBSERVED` (exact timer values in code)
- **Location:** `godot/main/load_screen.gd:48` (`settle`), `godot/scenes/battle/battle.gd:592-593,861-890,3152-3158,5028`, `godot/ui/battle/hud.gd:1259`, `godot/main/main.gd:350`, `godot/main/title.gd:698`
- **Quotes:**
  - `load_screen.gd:48`: `while (quiet < 12 or Time.get_ticks_msec() - since < 500) and Time.get_ticks_msec() - start < 12000:`
  - `battle.gd:5028`: `await get_tree().create_timer(0.8).timeout` (in `_auto_end()`, while `ending = true` blocks all input)
  - `battle.gd:3152,3158`: `await wait(500.0)` / `await get_tree().create_timer(1.2).timeout` (followed by `hud.gd:1259` `create_timer(0.75)` before focusing Continue)
  - `main.gd:350` + `title.gd:698`: `get_tree().create_timer(0.5).timeout.connect(_start_showcase)` / `_reveal_tw.tween_property(_bg, "modulate:a", 0.0, 2.5)`
- **Player-visible cost:** `OBSERVED`:
  - Every battle load and sector map load (`map3d.gd:212`) waits **>= 500 ms + 12 quiet frames** inside `load_screen.settle()` plus 10 explicit `await get_tree().process_frame`s in `battle.gd:592-889` (`~650-750 ms` of pure idle waiting even when 0 pipelines are compiling).
  - When a ship finishes its last action, `_auto_end()` locks out player input for **800 ms** before activating the next ship.
  - At battle victory/defeat, the player waits **500 ms + 1200 ms = 1.7 s** for the end card and another **750 ms** (**2.45 s total**) before Enter/Space triggers Continue.
  - App launch waits **500 ms** before starting the title showcase and **2.5 s** to fade it in.
- **Fix:** Reduce `load_screen.settle()` to `quiet < 3` and `>= 80 ms` once pipeline count stops rising (keep the 12 s cap); collapse the 10 extra `process_frame` waits in `battle.gd` to 2-3. Cut `_auto_end()` hold from 800 ms to 200-250 ms (and allow clicking another ship immediately to cancel the wait). Shorten battle-end card delay to 300 ms + 500 ms and focus Continue immediately when the card appears (with a 150 ms accidental-press guard instead of 750 ms). Start the title showcase on the next frame (`call_deferred`) and shorten the reveal tween to 0.8-1.0 s.
- **Confidence:** `high`

---

### 7. Volley, ability, order, and cut-in flows stack blocking `await wait(...)` timers during combat
- **Category:** Input & UI
- **Evidence:** `OBSERVED` (code timers and `PACE` values)
- **Location:** `godot/scenes/battle/battle.gd:1551-1784` (`_play_events`), `godot/scenes/battle/battle.gd:2578-2583` (`_play_volley`), `godot/rules/data/tables.json:219` (`PACE`)
- **Quotes:**
  - `battle.gd:2578-2580`: `await wait(80.0)` / `if cined and not _stale(gen):` / `await wait(900.0, _routine_shot_cut != "")`
  - `battle.gd:1551-1784`: stacked `await wait(...)` holds of `200-600 ms` across abilities, orders, boarding, and `PACE.banner (380 ms) + 140 ms` banner gaps.
- **Player-visible cost:** `OBSERVED`: Every volley adds 80 ms of dead tail (980 ms if a shot cut-in fired, even when the projectiles have already landed), and multi-event enemy turns stack 200-600 ms pauses between abilities, orders, ticks, and banners (`INFERRED` **1.5-4.0 s** of extra idle pacing per round on top of animation time, feeling sluggish to experienced players).
- **Fix:** Allow click/Space to immediately release post-volley and cut-in holds (and drop the 80 ms tail when the last projectile has already impacted). Add a "Fast Combat" / "Snappy Pacing" toggle (or scale `wait()` multiplier down on `PACE` holds when Fast mode is on) without breaking animation order.
- **Confidence:** `high`

---

### 8. Synchronous full-catalog SFX loading and `.import` parsing repeats on every battle start
- **Category:** Loading / Stutters
- **Evidence:** `OBSERVED` (code); timing `INFERRED`
- **Location:** `godot/scenes/battle/battle.gd:253` (`_ready`), `godot/audio/sfx.gd:58-111` (`_ready`)
- **Quotes:**
  - `battle.gd:253`: `sfx = Sfx.new()`
  - `sfx.gd:61-62,73`: `cues = JSON.parse_string(FileAccess.get_file_as_string("res://audio/cues.json"))` / `var idx = JSON.parse_string(FileAccess.get_file_as_string("res://audio/clips/index.json"))` (followed by per-clip `HUDRes.imported_ok()` file reads and `load()` into instance dicts)
- **Player-visible cost:** `INFERRED`: Every time a battle loads, `Sfx.new()` re-reads and re-parses `cues.json`, `clips/index.json`, opens every `.import` sidecar file from disk, and synchronously `load()`s the entire audio clip catalog into instance dictionaries that are thrown away when the battle ends. Costs `INFERRED` **150-500 ms** on the main thread on every battle start (and slows the title showcase whenever `Sfx` runs without `silent`).
- **Fix:** Cache parsed `cues`, `clips/index`, and loaded `AudioStream` resources in `static var` dictionaries on `Sfx` (or an autoload) so the catalog loads once per app session (and optionally streams in on a background thread at app boot). Skip runtime `.import` text parsing in exported builds (`ResourceLoader.exists()` is sufficient).
- **Confidence:** `high`

---

### 9. First death rebuilds all terrain edges synchronously and hits un-warmed Eclipse and styled tear materials
- **Category:** Stutters
- **Evidence:** `OBSERVED` (code); hitch size `INFERRED`
- **Location:** `godot/scenes/battle/battle.gd:1771` (`_play_events`), `godot/render/board.gd:1142-1170` (`add_wreck`, `_rebuild_edges`), `godot/fx/fx.gd:1388-1406` (`_eclipse_flash`), `godot/fx/fx_death.gd:429-477` (`tear_particles`)
- **Quotes:**
  - `board.gd:1159-1169`: `if fresh:` / `_rebuild_edges()` -> `for n in [edges, gas_edges, hazard_edges, solid_edges, cover_edges, hover_edges]: ... n.queue_free()` / `_terrain_edges()`
  - `fx.gd:1396-1399`: `var m := StandardMaterial3D.new()` / `m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA` / `m.no_depth_test = true` (created on first Eclipse capital death, never warmed)
  - `fx_death.gd:429-477`: `tear_particles()` allocates `death_spark_mesh_styled` / `death_cone_mesh_styled` (`StandardMaterial3D.new()`) on the first real styled faction death because `fx.warmup()` passes `src = null`, AND spawns 2 brand-new `GPUParticles3D` nodes + `queue_free()` per tear/vent.
- **Player-visible cost:** `INFERRED`: **15-80 ms** frame hitch right on the kill beat: (a) every ship that leaves a wreck destroys and rebuilds all 6 terrain-edge mesh layers across the entire hex board (`_terrain_edges()` BFS + geometry build) on the kill frame; (b) the first Eclipse capital kill compiles a brand-new `StandardMaterial3D` (`TRANSPARENCY_ALPHA` + `no_depth_test` + unshaded) pipeline live; (c) the first real faction ship death compiles the styled tear spark/cone pipelines and instantiates unpooled `GPUParticles3D` nodes mid-death.
- **Fix:** (1) For `add_wreck()`, append/patch only the 6 edges of the single newly-wrecked hex (or update a cached edge MultiMesh) instead of destroying and rebuilding all terrain edges for the whole board. (2) Warm the Eclipse death flash material and styled tear spark/cone materials during `fx.warmup()` (pass a dummy styled spec in warmup). (3) Pool the tear `GPUParticles3D` emitters in `fx_pool.gd` instead of `new()` + `queue_free()` per tear.
- **Confidence:** `high`

---

### 10. Mid-battle background debris cut stalls a live frame on install
- **Category:** Stutters
- **Evidence:** `OBSERVED` (code); hitch size `INFERRED`
- **Location:** `godot/world/world_living.gd:1401-1463` (`_install_chunks`)
- **Quotes:**
  - `world_living.gd:1401-1409`: `func _install_chunks(chunks: Array) -> void:` (called from `_process` once the background debris-cut thread finishes, after the loading cover has already dropped, then runs `surface_get_arrays()`, builds `ArrayMesh`es and `MultiMeshInstance3D`s synchronously in one frame)
- **Player-visible cost:** `INFERRED`: **10-40 ms** sudden single-frame hitch several seconds into a battle (often during round 1-2 camera panning or first ship selection) when the background debris job completes and installs all cut asteroid/wreck chunks in a single `_process` tick.
- **Fix:** Slice `_install_chunks()` to upload at most 1-2 chunk meshes/MultiMeshes per frame, and construct the `ArrayMesh` vertex buffers (`PackedVector3Array` / `Array`) on the worker thread so the main thread only calls `add_surface_from_arrays()` + `MultiMesh` assignment.
- **Confidence:** `high`

---

### 11. Ghost preview duplicates the whole 3D ship tree on every plan, and `play_glide()` runs 241 curve scans
- **Category:** Stutters / Input & UI
- **Evidence:** `OBSERVED` (code); hitch size `INFERRED`
- **Location:** `godot/scenes/battle/battle.gd:3734-3787` (`_ghost_show`), `godot/render/ship_view.gd:1190-1195` (`play_glide`)
- **Quotes:**
  - `battle.gd:3734-3740`: `func _ghost_show(id: String) -> void:` / `var gh := sv.hull.duplicate(0)` (clones entire 3D ship hierarchy including lights, particles, turrets, then walks and `queue_free()`s non-meshes + creates new `TorusMesh` and materials; destroyed on cancel/confirm)
  - `ship_view.gd:1190-1195`: `for i in 241:` (evaluates path curves and binary searches ~12x per sample = ~3,000+ GDScript evaluations synchronously at the moment a move begins)
- **Player-visible cost:** `INFERRED`: **5-25 ms** micro-hitch every time the player clicks a destination hex to preview a move (especially on high-detail capital ships with dozens of child nodes/meshes), followed by another **3-10 ms** spike when confirming the move as `play_glide()` scans 241 samples synchronously on the main thread.
- **Fix:** Cache one stripped mesh-only ghost `Node3D` per ship (or per hull class) on first use and toggle `.visible` + transform instead of calling `sv.hull.duplicate(0)` and `queue_free()` on every move preview. In `play_glide()`, sample 32-48 points (sufficient for smooth peak velocity scaling) or compute analytically from segment arc lengths.
- **Confidence:** `high`

---

### 12. Hovering battle hexes runs `board.refresh()` twice, rebuilds firing fans, and updates tooltips every pixel
- **Category:** Input & UI / Stutters
- **Evidence:** `OBSERVED` (code); hitch size `INFERRED`
- **Location:** `godot/scenes/battle/battle.gd:3364-3399` (`_fans`), `godot/scenes/battle/battle.gd:4596-4618` (`_on_pointer`), `godot/render/board.gd:398-452` (`refresh`)
- **Quotes:**
  - `battle.gd:4603-4616`: `board.set_hover(h.x, h.y)` -> `_overlay()` -> `board.set_overlay(...)` (calls `board.refresh()` TWICE per hex crossing, rewriting 200+ MultiMesh instances with `"%d,%d"` keys twice) and `hud.show_tip(_tip(), p)` unconditionally on every mouse-motion pixel
  - `battle.gd:3364-3376`: `_fans()` destroys `fan_root` and rebuilds `SurfaceTool` firing-arc geometry + `StandardMaterial3D` whenever ship/host/weapons key changes
- **Player-visible cost:** `INFERRED`: **2-10 ms** frame spikes while sweeping the cursor across hexes during player turns, making hex targeting and movement preview feel less crisp than 60/120 fps.
- **Fix:** Coalesce `board.set_hover()` + `board.set_overlay()` into a dirty flag flushed once at the end of `_on_pointer()` (or `_process`), cutting MultiMesh updates in half. Cache `_tip()` string per hovered hex/unit and only reposition the tooltip on sub-hex pixel motion (never re-evaluate `_tip()` or `reset_size()` when the hex has not changed). Pool/reuse firing-arc materials and hide/transform cached fan meshes per ship rather than regenerating `SurfaceTool` geometry on every hover.
- **Confidence:** `high`

---

### 13. Legacy debris rocks are hidden via per-fragment `discard` instead of `visible = false`
- **Category:** Stutters / GPU
- **Evidence:** `OBSERVED` (code); GPU cost `INFERRED`
- **Location:** `godot/world/world.gd:259`, `godot/world/world_rocks.gd:192`, `godot/world/world_living.gd:1012-1019`
- **Quotes:**
  - `world_rocks.gd:192`: `if (legacy_debris && living_terrain) { discard; }`
  - `world.gd:259` + `world_living.gd:1014-1019`: `debris_field(p, rock_kind)` still builds the legacy debris MultiMeshInstance3D scatter on every battle, and `world_living._debris()` only flips its shader flag (`_sync_legacy_debris()`) instead of hiding the node with `visible = false`
- **Player-visible cost:** `INFERRED`: **0.5-2.5 ms/frame** wasted GPU vertex shading, rasterization, and broken early-Z culling on every single battle frame in Living/Cine mode (the default), because hundreds of legacy debris rock instances are still submitted to the GPU and rasterized only to be discarded per pixel.
- **Fix:** Set `mmi.visible = false` (or skip building the legacy debris `MultiMeshInstance3D`s entirely) when `living_terrain` is enabled, removing the `discard;` branch from the rock fragment shader so hardware early-Z stays active for all remaining rocks.
- **Confidence:** `high`

---

### 14. Battle HUD calls `reset_size()` every frame, redraws ledger every mouse pixel, and rebuilds pause menu on open
- **Category:** Input & UI / Stutters / Dead Code
- **Evidence:** `OBSERVED` (code); hitch size `INFERRED`
- **Location:** `godot/ui/battle/ledger.gd:1028-1035` (`_gui_input`), `godot/ui/battle/hud.gd:924,1008,1268,1447,1466-1495` (`set_plate`, `show_menu`, `_process`, `_layout`, `declutter_plates`)
- **Quotes:**
  - `ledger.gd:1028-1035`: `if e is InputEventMouseMotion:` -> calls `hover_tip.emit(...)` and `queue_redraw()` on every pixel of mouse movement over the HUD even when `_hover` is unchanged
  - `hud.gd:1447,1473-1495`: `_process()` calls `_layout()` every frame, which calls `legend.reset_size()` unconditionally every frame, plus `aichip`/`banner_lbl` `reset_size()` and `font_semi.get_string_size()` for `toast_lbl` every frame while shown
  - `hud.gd:924,1008`: `bars_c.visible = false` (permanent), yet `set_plate()` allocates a 5-element array for `bars_c` on every ship every frame
  - `hud.gd:1268`: `func show_menu(...)` destroys and rebuilds the entire 20+ button battle menu on every Esc/menu click
- **Player-visible cost:** `INFERRED`: **1-5 ms/frame** CPU UI layout/text-shaping overhead while moving the mouse over the HUD or during combat, plus a **5-15 ms** micro-hitch when opening the Esc menu.
- **Fix:** (1) In `ledger._gui_input()`, track `prev_hover` and only emit `hover_tip` and call `queue_redraw()` when the hovered slot changes. (2) Dirty-flag `_layout()` so `reset_size()` only runs when text or viewport size changes. (3) Delete the dead `bars_c` per-frame allocation in `set_plate()`. (4) Guard `declutter_plates()` so sorting/overlap checks only run when camera pose or unit positions changed. (5) Build the pause menu once and toggle `.visible` + update dynamic labels/states on open.
- **Confidence:** `high`

---

### 15. Campaign map redraws 2D overlay and `Curve3D`s every frame, and keeps static 3D portraits rendering every frame
- **Category:** Stutters / GPU
- **Evidence:** `OBSERVED` (code); frame cost `INFERRED`
- **Location:** `godot/ui/campaign/map3d.gd:877-940,984-1090` (`_live_frame`, `_draw_overlay`), `godot/ui/campaign/ledger_ship.gd:19-20`, `godot/ui/campaign/flagship_podium.gd:45-46`
- **Quotes:**
  - `map3d.gd:913-923,938-939,984`: `_live_frame()` calls `overlay.queue_redraw()` and `_update_card()` every frame, and walks `o.get_children()` plus `o.get_node_or_null("spin")` / `"spin2"` for every stop every frame; `_draw_overlay()` constructs new `Curve3D`s with 25 `sample_baked()` points per route + 16-candidate label collision loop every frame
  - `ledger_ship.gd:20`: `vp.transparent_bg = true; vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE` (a completely stationary 640x300 3D ship camera)
  - `flagship_podium.gd:45-46`: `_vp.msaa_3d = Viewport.MSAA_4X` / `_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE` (even when `still == true` / Reduce Motion)
- **Player-visible cost:** `INFERRED`: **2-6 ms/frame** wasted CPU+GPU work on the campaign map and fleet/shipyard screens (especially when multiple `ledger_ship` SubViewports are visible at once, each re-rendering a 3D scene every frame for a static image).
- **Fix:** Set `ledger_ship.gd` SubViewport to `SubViewport.UPDATE_ONCE` (and set `flagship_podium.gd` to `UPDATE_ONCE` when `still == true`). On `map3d.gd`, cache route `Curve3D` samples when the sector builds, cache `spin`/`spin2` node references in stop structs instead of `get_node_or_null()` every frame, and only call `overlay.queue_redraw()` / `card.reset_size()` when camera, hover, or selection changes.
- **Confidence:** `high`

---

### 16. First-time campaign map open runs a 6,591-iteration 3D color grid search per swatch in GDScript
- **Category:** Loading
- **Evidence:** `OBSERVED` (code); timing `INFERRED`
- **Location:** `godot/ui/campaign/map3d.gd:568-590` (`for_screen`)
- **Quotes:**
  - `map3d.gd:576-583`: `for stage in 3:` / `var n = 12` / `for i in n + 1:` / `for j in n + 1:` / `for l in n + 1:` / `var d = _shown(x, ex, wh, co, sa).distance_squared_to(target)`
- **Player-visible cost:** `INFERRED`: Each unique color passed to `for_screen()` runs `3 * 13^3 = 6,591` GDScript calls to `_shown()` (with `pow()`/`srgb` conversions). Across ~10-20 unique sector/faction/route colors on first map open, that is 65,000-130,000 GDScript loop iterations (**80-250 ms** on the main thread).
- **Fix:** Replace the 3D brute-force grid search with a direct analytical inverse of the ACES/Reinhard tonemap + contrast/saturation curve (or a 1D binary search per channel after inverting saturation, ~20 iterations instead of 6,591), cutting cost by >100x.
- **Confidence:** `high`

---

### 17. Cold shield skin bake runs 3D voxel raycasting + BFS + marching tetrahedra in GDScript
- **Category:** Loading / Stutters
- **Evidence:** `OBSERVED` (code); timing `INFERRED`
- **Location:** `godot/fx/fx_ship.gd:747-755,813-916` (`_ensure_shield_skin`, `_bake_shield_skin`)
- **Quotes:**
  - `fx_ship.gd:751`: `arrays = _bake_shield_skin(box, faces)` (3D grid voxelization + raycast + BFS + marching tetrahedra in GDScript; cached to `user://shield_skins/` afterward)
- **Player-visible cost:** `INFERRED`: On a fresh install (or after a hull mesh update), the first battle containing each shielded hull class incurs **100-400 ms per unique hull** to bake the shield skin mesh in GDScript (either blocking load when `defer_initial_cuts == false` or consuming worker threads during battle 1).
- **Fix:** Pre-bake shield skins into `res://gen/shield_skins/` as part of the ship build/export pipeline (just like `gen/ships/`), keeping runtime `_bake_shield_skin()` only as a fallback for dev hulls.
- **Confidence:** `high`

---

### 18. Synchronous double-flush atomic save reads, parses, and validates the old save from disk on every round start and shipyard click
- **Category:** Stutters / Loading
- **Evidence:** `OBSERVED` (code); hitch size `INFERRED`
- **Location:** `godot/campaign/campaign.gd:450-474` (`persist_save`, `_write_atomic`), `godot/campaign/campaign.gd:1996-2007` (`save_battle_round`)
- **Quotes:**
  - `campaign.gd:459-463`: `var prev = FileAccess.get_file_as_string(save_path)` / `if prev != data and saneSave(_dec(_json_quiet(prev))):` / `if not _write_atomic(save_path + ".bak", prev):` / `if not _write_atomic(save_path, data):`
  - `campaign.gd:469`: `f.store_string(text); f.flush()` (twice per save, each followed by `DirAccess.rename_absolute`)
- **Player-visible cost:** `INFERRED`: **5-25 ms** synchronous main-thread hitch on every battle round start (`save_battle_round`) and every shipyard buy/sell/repair/refit click (`saveRun`), worse on Windows when Defender scans newly created `.tmp` files before rename. Reading the existing file back from disk, parsing the entire JSON (up to 600 `tel_log` entries + full battle snapshot), recursively decoding `_dec()`, and running `saneSave()` repeats work already known in memory.
- **Fix:** Cache the last known-good serialized save string in memory (populated on `persist_load()` and updated after each successful write) to avoid re-reading/re-parsing/re-validating `save_path` on every save. Offload the `.bak` + primary atomic disk writes to a single serial background save queue (flushed synchronously only on app quit) so rapid shipyard clicks coalesce without blocking the UI thread.
- **Confidence:** `high`

---

### 19. Battle load runs ~80K-130K GDScript math iterations for nebula/storm masks and calls `mesh.get_faces()` just to check `>= 3`
- **Category:** Loading
- **Evidence:** `OBSERVED` (code); timing `INFERRED`
- **Location:** `godot/world/world_living.gd:643-717` (`_mask`), `godot/world/world_living.gd:1345` (`_cut_mesh_check`)
- **Quotes:**
  - `world_living.gd:643-717`: `_mask()` loops pixel-by-pixel in GDScript (~13,000 `exp`/`sqrt`/`smoothstep` iterations per nebula or ion storm hex on the main thread during battle load)
  - `world_living.gd:1345`: calls `mesh.get_faces()` (which allocates and copies the entire mesh's triangle vertex array on CPU) solely to check `>= 3`
- **Player-visible cost:** `INFERRED`: **60-200 ms** added to battle load on nebula/storm maps from CPU GDScript pixel loops, plus **5-20 ms** of unnecessary CPU array copies in `get_faces()` during debris setup.
- **Fix:** Move `_mask()` generation to a tiny shader / `SubViewport` pass or a `WorkerThreadPool` task (or pre-bake 3-4 reusable mask textures). Replace `mesh.get_faces().size() >= 3` with `mesh.get_surface_count() > 0` and `mesh.surface_get_array_len(0) >= 3` (O(1), zero allocation).
- **Confidence:** `high`

---

### 20. Per-frame `load()`, OS env reads, 200-hex camera loops, and unconditional camera/shader updates when idle
- **Category:** Stutters
- **Evidence:** `OBSERVED` (code); frame cost `INFERRED`
- **Location:** `godot/render/camera_rig.gd:240,262-302` (`keyboard_pan`, `_process`, `_apply`), `godot/scenes/battle/battle.gd:6492-6517` (`_board_far`, `_process`)
- **Quotes:**
  - `camera_rig.gd:240`: `if load("res://ui/theme/modal_focus.gd").any_open():` (called every frame in `_process`)
  - `camera_rig.gd:269-274`: `_apply()` runs every frame unconditionally (updating 3 global shader params, `look_at_from_position`, `pose_applied.emit()`, plus calling `OS.get_environment("VS_NEBULA_ROUTE")` twice per frame)
  - `battle.gd:6516-6517`: `if key_light != null and board != null and LOOK.ship_look_v2_enabled():` (calls `OS.get_environment("VS_SHIP_LOOK_V2")` every frame) / `key_light.directional_shadow_max_distance = LOOK.shadow_reach(float(cam.r), _board_far(cam.t))` (loops all 200+ `_board_cells_xz` every frame)
- **Player-visible cost:** `INFERRED`: **0.3-1.0 ms/frame** constant background CPU overhead and scene/shader dirtying even when the player is just reading the board with a stationary camera.
- **Fix:** Preload `ModalFocus` as a `const` in `camera_rig.gd`. Cache `VS_NEBULA_ROUTE` and `VS_SHIP_LOOK_V2` in `static var`s at startup instead of calling `OS.get_environment()` every frame. Skip `_apply()` and `pose_applied.emit()` when camera `(a, b, r, t)` deltas are below epsilon (`1e-5`). In `battle.gd`, cache the 6 board convex-hull corners (the farthest hex is always one of the outer vertices, not all 200+ interior hexes) and only recompute `directional_shadow_max_distance` when `cam.r` or `cam.t` changes.
- **Confidence:** `high`

---

### 21. Idle turrets, parked engines, nebula wakes, ion flashes, SFX bus volumes, and death audio run unconditional per-frame work
- **Category:** Stutters
- **Evidence:** `OBSERVED` (code); frame cost `INFERRED`
- **Location:** `godot/fx/fx_hull.gd:1769-1793` (`turret_step`), `godot/fx/fx_ship.gd:495,520-527` (`step`), `godot/world/world_living.gd:949-969` (`step`), `godot/world/nebula_wake.gd:300-337`, `godot/audio/sfx.gd:426-435`, `godot/audio/death_audio.gd:60`
- **Quotes:**
  - `fx_hull.gd:1769-1793`: `turret_step()` computes `Basis` and assigns `Node3D.transform` every frame for every turret on every ship even when idle at rest (unlike `door_step()` right below it)
  - `fx_ship.gd:495,520-527`: calls `_hide_placeholder_engines()` and updates engine shader uniforms every frame even for parked, undamaged ships
  - `world_living.gd:949-969` + `nebula_wake.gd:300-337`: sorts wake arrays with a lambda, allocates Dicts/144-float buffers, and uploads uniforms to every nebula card & FogVolume every frame even with 0 active wakes; calls `_set_flashes()` every frame even with 0 active flashes
  - `death_audio.gd:60`: `sfx.death_beat(float(fx.get("_death_slow_left")) > 0.0)` every frame even when no death is running (and `sfx._process` calls `AudioServer.get_bus_index()` + `set_bus_volume_db()` every frame even when ducking is idle)
- **Player-visible cost:** `INFERRED`: **0.5-2.0 ms/frame** steady CPU + GC churn during every battle frame, scaling linearly with ship count, turret count, and nebula card count.
- **Fix:** Early-out `turret_step()` when current yaw/pitch matches target (like `door_step`). Run `_hide_placeholder_engines()` once at ship attach, not every frame, and dirty-flag engine shader uniform writes. Short-circuit `nebula_wake` and `_set_flashes()` when active counts are 0 (uploading a zero count once on transition to empty). Cache `AudioServer` bus indices once in `sfx._buses()` and only update volumes or call `death_beat()` when state/ducking changes.
- **Confidence:** `high`

---

### 22. Unpooled transient VFX and audio nodes churn the scene tree during combat
- **Category:** Stutters
- **Evidence:** `OBSERVED` (code); frame cost `INFERRED`
- **Location:** `godot/render/ship_view.gd:1672` (`_rcs_puff`), `godot/audio/sfx.gd:212-270` (`play`), `godot/fx/fx_ship.gd:544-590` (`_update_trails`)
- **Quotes:**
  - `ship_view.gd:1672`: creates a new `Sprite3D.new()` + `add_child()` + `queue_free()` for every maneuvering thruster puff
  - `sfx.gd`: spawns a new `AudioStreamPlayer`/`AudioStreamPlayer3D` + `Tween`s + `queue_free()` for every sound layer played
  - `fx_ship.gd:544-590`: rebuilds each engine trail `ArrayMesh` via `clear_surfaces(); add_surface_from_arrays()` on every 0.05 s sample while moving (and calls `xf()` with `affine_inverse()` every frame)
- **Player-visible cost:** `INFERRED`: **1-4 ms** micro-stutters during heavy multi-ship volleys, squadron swarms, and simultaneous ship movements from scene-tree insertion/removal, Tween allocations, and GPU buffer reallocations.
- **Fix:** Pool `Sprite3D` RCS puffs (or render them via a small shared `MultiMeshInstance3D`), maintain a fixed ring pool of `AudioStreamPlayer` and `AudioStreamPlayer3D` nodes in `Sfx`, and update engine trail vertices in-place via `surface_update_vertex_region()` (or a pre-allocated vertex buffer) instead of `clear_surfaces()` + `add_surface_from_arrays()`.
- **Confidence:** `high`

---

### 23. Ship look init loads grain textures twice and synchronously decompresses all 6 faction textures on CPU
- **Category:** Loading
- **Evidence:** `OBSERVED` (code); timing `INFERRED`
- **Location:** `godot/render/look.gd:197-208` (`_detail_of`, `_alpha_of`)
- **Quotes:**
  - `look.gd:197`: `_detail[faction] = [load(g), load(n), _alpha_of(load(g))] if ResourceLoader.exists(g) and ResourceLoader.exists(n) else []`
  - `look.gd:202-208`: `_alpha_of()` calls `t.get_image()` + `img.decompress()` on the main thread just to read pixel `(0, 0).a`
- **Player-visible cost:** `INFERRED`: **20-80 ms** wasted on first battle/title load calling `load(g)` twice, downloading/copying compressed VRAM textures back to CPU, and software-decompressing all 6 faction grain maps just to read a single static alpha byte.
- **Fix:** Store the 6 faction grain alpha constants directly in a `const` dictionary (validated by a standing/asset test if needed) and reuse the single `load(g)` result, removing `get_image()` and `decompress()` from runtime entirely.
- **Confidence:** `high`

---

### 24. Redundant `manifest.json` parses and unused legacy `gen/rocks/*.res` loads
- **Category:** Loading / Memory & VRAM
- **Evidence:** `OBSERVED` (code); cost `INFERRED`
- **Location:** `godot/render/board.gd:835,850` (`_rock_lib`, `_terrain`), `godot/render/ship_view.gd:43`, `godot/assets/ships/a4_props.gd:53` (and `main.gd`, `title.gd`, `backdrop.gd`, `squadron_wing.gd`)
- **Quotes:**
  - `board.gd:835`: `var man = JSON.parse_string(FileAccess.get_file_as_string("res://gen/manifest.json")) if FileAccess.file_exists("res://gen/manifest.json") else null`
  - `board.gd:850`: `rock_meshes = _rock_lib()` (runs unconditionally in `_terrain()`, loading all `gen/rocks/*.res` meshes even when `props_world == true` and the world renders its own rocks)
- **Player-visible cost:** `INFERRED`: **15-50 ms** and **5-15 MiB** unnecessary mesh loads on every battle load, plus repeated disk reads and JSON parses of `gen/manifest.json` across 6+ scripts.
- **Fix:** Share `ShipView.manifest()` (cached once in a static dict) across all callers instead of re-reading `res://gen/manifest.json` from disk. In `board._terrain()`, skip `_rock_lib()` when `props_world == true` (lazy-load only if legacy board rocks are actually spawned).
- **Confidence:** `high`

---

### 25. Portrait overlay restoration and Nemesis framing run pixel-by-pixel GDScript loops and sync Lanczos resize on main thread
- **Category:** Stutters / Loading
- **Evidence:** `OBSERVED` (code); cost `INFERRED`
- **Location:** `godot/portraits/portraits.gd:222-340` (`_restore_overlay`, `_ring_pass`, `nemesis`)
- **Quotes:**
  - `portraits.gd:222-239`: `_restore_overlay()` creates a 768x768 `Image` and runs `_ring_pass`, `_plates_pass`, `_visor_pass` doing per-pixel GDScript math + `get_pixel`/`set_pixel` on the main thread; `nemesis()` synchronously calls `decompress()` + `Image.INTERPOLATE_LANCZOS` resize on the main thread
- **Player-visible cost:** `INFERRED`: **30-120 ms** UI hitch when first opening a restored admiral portrait or a Nemesis portrait in campaign/career screens.
- **Fix:** Draw the restoration ring/plates/visor via a lightweight `CanvasItem` shader or `Control._draw()` (0 ms CPU pixel loop, resolution-independent) instead of baking 768x768 images in GDScript. For Nemesis framing, crop via `AtlasTexture` or shader UV transform instead of CPU `decompress()` + Lanczos resize.
- **Confidence:** `high`

---

### 26. Title drawers, campaign pages, and career tabs destroy and rebuild entire Control trees on every open/click
- **Category:** Input & UI
- **Evidence:** `OBSERVED` (code); hitch size `INFERRED`
- **Location:** `godot/main/title.gd:345-484` (`_settings`, `_credits`), `godot/ui/campaign/campaign_ui.gd:456-457` (`_render`), `godot/ui/career/career_screen.gd:235-253` (`render`)
- **Quotes:**
  - `title.gd:345-347`: `func _settings() -> void:` / `if settings_panel != null:` / `settings_panel.queue_free()` (and `_credits()` re-reads `music.json` from disk and rebuilds on every open)
  - `campaign_ui.gd:456-457` & `career_screen.gd:235-245`: `c.queue_free()` removes all children and rebuilds full Control trees on every click/tab switch
- **Player-visible cost:** `INFERRED`: **5-20 ms** UI click latency and brief frame drop when toggling Settings/Credits, switching Career tabs, or clicking shipyard/fleet actions in Campaign.
- **Fix:** Keep Settings, Credits, and Career tab subtrees alive after first build (toggle `.visible` and refresh only changed values/labels). In `campaign_ui.gd`, update existing widgets in place when staying on the same screen kind (e.g., shipyard buy/repair) instead of tearing down and reconstructing the whole page tree.
- **Confidence:** `med`

---

### 27. Unused assets, dev benches, and unreferenced scripts are bundled in the export `.pck` (~19+ MB beyond dead flipbooks)
- **Category:** Bugs & Dead Code / Memory & VRAM
- **Evidence:** `OBSERVED` (disk audit and codebase reference scan)
- **Location:** `godot/export_presets.cfg:11`, `godot/world/test_blockers.gd:1`
- **Quotes:**
  - `export_presets.cfg:11`: `exclude_filter="*/test/*, rules/test/*, campaign/test/*, fx/test/*, music/test/*, story/test/*, portraits/test/*, audio/build/*, assets/ships/*.glb"`
- **Player-visible cost:** `OBSERVED`: The export filter omits several dev/unused directories, shipping **~19+ MB** of dead weight in `Voidsworn.pck` (on top of the ~55-72 MB dead `fx/atlases/rebake/` flipbooks in Finding 5):
  - `godot/portraits/alts/` (**5.36 MB**) and `godot/portraits/sheets/` (**3.94 MB**): zero runtime references in `godot/`.
  - `godot/world/rocks/` (**~10+ MB** of legacy rockgen GLBs, unused unless `VS_PLANET_REMIX=0`).
  - Dev-only directories still exported: `godot/bench/`, `godot/fx/gallery/`, `godot/world/tools/`, `godot/tools/`.
  - `godot/world/test_blockers.gd` (4.6 KB): unreferenced runtime script sitting outside `test/`.
  - Note on texture compression: 28 `.png.import` files use `compress/mode=0` (lossless), mostly `fx/atlases/death/*` flow/thickness maps (~2.95 MB). Keep flow/LUT textures lossless so vector/lookup precision is preserved; do not blindly force BC7 on those.
- **Fix:** Add `portraits/alts/*, portraits/sheets/*, bench/*, fx/gallery/*, world/tools/*, tools/*, world/test_blockers.gd` (and `world/rocks/*` once legacy remix fallback is retired) to `exclude_filter` in `export_presets.cfg`, and delete or move `world/test_blockers.gd` into `world/test/`.
- **Confidence:** `high`

---

### 28. Unshared per-ship `TorusMesh` + materials and unbounded OGG music cache grow memory across battles
- **Category:** Memory & VRAM
- **Evidence:** `OBSERVED` (code); memory size `INFERRED`
- **Location:** `godot/render/ship_view.gd:331-397` (`_ring`, `_marker`), `godot/music/music_player.gd:32,135` (`_streams`)
- **Quotes:**
  - `ship_view.gd:334-345`: `var tm := TorusMesh.new()` (`rings = 64`, `ring_segments = 6`, 768 tris) + `var m := StandardMaterial3D.new()` allocated per ship for selection ring, marker, and wreck overlays
  - `music_player.gd:32,135`: `var _streams := {}` / `_streams[id] = s` (unbounded session cache holding every played OGG stream in memory; catalog is ~32 MB on disk)
- **Player-visible cost:** `INFERRED`: Minor steady memory growth (~32+ MiB RAM for decoded/buffered music tracks over a long campaign run, plus extra GPU mesh/material objects per ship in large battles).
- **Fix:** Share one `static var` unit `TorusMesh` (scaled per ship radius) and shared materials per color state in `ShipView`. Cap `MusicPlayer._streams` to the active/recent 4-6 tracks (evicting LRU tracks not currently playing).
- **Confidence:** `high`

---

### 29. Unconditional `print()` console logging on every ship load and removal
- **Category:** Bugs & Dead Code / Stutters
- **Evidence:** `OBSERVED` (code)
- **Location:** `godot/fx/fx_hull.gd:1490`, `godot/fx/fx.gd:1708`
- **Quotes:**
  - `fx_hull.gd:1490`: `print("[turret] %s (%s) on %s: arc %.0f to %.0f, trains %s%s" % ...)`
  - `fx.gd:1708`: `print("[attach] battle %s %s: skipped %d; %s" % ...)`
- **Player-visible cost:** `INFERRED`: **<1-3 ms** per ship load/removal, plus noisy stdout flushing in Windows release builds and log bloat during long campaigns or headless tests.
- **Fix:** Gate diagnostic prints behind `OS.is_debug_build()` or an explicit env flag (e.g. `VS_TRACE_FX=1`), keeping release stdout quiet.
- **Confidence:** `high`

---

## Not checked:
- Live GPU/CPU profiling, frame-time percentiles, and Vulkan peak VRAM numbers on Ryan's RTX 5080 (this was a read-only source and asset audit; no Godot binary or GPU capture was run).
- Full 7,932-line body of `godot/rules/rules.gd` beyond targeted hot-path scans (`battle_api.gd` and `threat_preview.gd` were read, so deep AI minimax/scoring loops inside `rules.gd` were not line-audited).
- `godot/ui/campaign/campaign_ui.gd` lines 651-2826 (first 650 lines were audited; deeper individual modal/shop sub-builders may have additional rebuild-on-click sites).
- Per-instruction GPU ALU cost of custom GLSL/gdshader code in `godot/fx/fx_shaders.gd` (beyond the R01 double-sample and legacy debris `discard` findings).
- `godot/ui/theme/glass_shell.gd` and `godot/ui/theme/orders_kit.gd` styling helper internals.
- Offline Blender/Node asset build scripts under `tools/` (not shipped to the player runtime).

---

## Recommended Next Step

Queue three high-impact follow-up issues right after PR 1445 and PR 1960 merge:
1. **R01 relief split + baked-planet binary RF cache & single-RD pass** (Findings 1 and 3: ~500 MiB VRAM/RAM saved + ~1.6 s off warm baked-planet loads + ~4-8 s off cold bakes).
2. **Deferred/shared death cuts + `_lanes_lock` fix + dead `s1`/`s2` flipbook & `.pck` cleanup** (Findings 2, 5, and 27: 2-8+ s off battle load + ~74-91 MB smaller export `.pck`).
3. **Snappiness sweep: trim artificial waits (`load_screen.settle`, `_auto_end`, battle end card), cache `Sfx` across battles, fix hover double-refresh + HUD per-frame `reset_size()`, and slice campaign `map3d` load + fix `rock_meshes(true)`** (Findings 4, 6, 8, 12, and 14).
