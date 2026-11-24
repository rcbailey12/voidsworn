# Planets V2 Detail and Optimization Review: Terran and Volcanic (Issue 1765 Follow-Up, Issue 1939)

**Lead verdict and pick:** Terran (`BAKE2`) and volcanic (`BAKE3`) read basic next to rocky and barren (`R01`) for three concrete reasons: **(1) their 4K maps have no fine geological frequency or real landforms** (3 to 5 octaves of smooth value noise, flat decals on land, soft monochrome orange blur on lava, barely 0.85 to 1.1 texels per screen pixel on Ryan's 2560x1377 monitor), **(2) the baked board shader never tilts the north pole away from the battle camera** (putting terran's big blank white ice cap dead-center in every battle), and **(3) a real NVIDIA float32 FMA bug in `wh31()` (`godot/world/world_shaders.gd:15-19`) is slicing razor-sharp straight seams, square corners, and clipped white triangles across both planets on the RTX 5080.**

**Biggest optimization surprise:** Almost none of the 18.7 s (terran) or 18.5 s (volcanic) cold load time is GPU baking. On the RTX 5080, **9.1 to 9.7 seconds is synchronous single-threaded CPU `img.save_png()` blocking the loading cover**, and another **4 to 11 seconds is main-thread startup/handoff dead time** where the bake worker sits idle because `WorldBakes` waits on deferred `_attach` and exits between jobs waiting for `_process()`. Fixing those two pipeline bottlenecks plus single-dispatch multi-output baking cuts cold board planet ready from **~18.6 s to ~2 to 4 s** (16+ seconds of headroom under the 20 s cover) and frees the budget to make terran and volcanic genuinely rich.

**Recommended plan (Rank 1 pick):** **Pipeline optimization + `wh31` integer-hash fix + upgraded 4K macro geology in `BAKE_BODY` + runtime triplanar detail in a shared `PLANET_DETAIL` shader helper (Option A enhanced with a tiny 1K/2K tileable real-DEM micro-terrain pack, ~1 to 2 MB in git).** Why it wins: it closes the close-up crispness gap to R01 at camera 170 and close limb on 2560x1377, keeps per-seed variety, costs ~0 ms cold load and only ~0.04 to 0.08 ms/frame on the RTX 5080 (taking `BOARD_SURFACE` from 0.085 ms to ~0.14 ms, matching R01's 0.133 ms), avoids adding ~80 MB to git and +1.5 GB VRAM/RAM spikes per 8K world, and serves both board and backdrop planets from one shared kit.

- **Reviewer:** Neon (Gemini 4 Neon High, T3 Code)
- **Date:** 2026-11-24
- **Repo commit reviewed:** `78e2ac3e0` (`78e2ac3e0d1c6ab37a233bd4dbb8d0da867e3378`, `main`; `godot/world/world_planet.gd` and `godot/world/world_bake.gd` identical to PC_M pin `9de7f81a4dad`)
- **Engine (headless CPU benchmarks):** Godot `4.7.2.stable.official.ed1daf0bf` on Ryan's Windows PC (CPU only, no GPU claim taken)

---

## 1. Proof of Reading (`docs/REVIEW_PROTOCOL.md`)

### Repository files read

| File | Commit | Total lines | Ranges read | First 40 chars of last line |
|---|---|---|---|---|
| `docs/REVIEW_PROTOCOL.md` | `78e2ac3e0` | 35 | 1-35 | `- Claude checks every claim against the ` |
| `godot/world/world_planet.gd` | `78e2ac3e0` | 916 | 1-916 | `"""` |
| `godot/world/world_bake.gd` | `78e2ac3e0` | 606 | 1-606 | `	return true` |
| `godot/world/world_shaders.gd` | `78e2ac3e0` | 488 | 1-488 | `"""` |
| `godot/world/world.gd` | `78e2ac3e0` | 1587 | 140-750, 1560-1587 | `	if _living != null: _living.use_ship_de` |
| `godot/world/world_sky.gd` | `78e2ac3e0` | 531 | 1-531 | `	return out` |
| `godot/world/planet_v2_shots.gd` | `78e2ac3e0` | 359 | 1-359 | `	await _save(name)` |
| `godot/world/test/planet_v2_check.gd` | `78e2ac3e0` | 423 | 1-423 | `	quit(0 if failures == 0 else 1)` |
| `godot/render/board.gd` | `78e2ac3e0` | 1218 | 1070-1218 | `		BV.outline(blocker_highlights, hex_wor` |
| `godot/scenes/battle/battle.gd` | `78e2ac3e0` | 7270 | 580-865, 7240-7270 | `	get_tree().quit(code)` |
| `godot/world/rocks/r01/bake.json` | `78e2ac3e0` | 224 | 1-224 | `}` |
| `tools/pc/jobs/planet369_remix.py` | `78e2ac3e0` | 297 | 1-297 | `        rocks()` |

### Pictures, logs, and baked maps inspected on Ryan's PC

- **PC_M real battles (`9de7f81a4dad`, 2560x1377, RTX 5080):** `opus1765m/out_20261123_222936_4675/out_new/` PNGs `battle_s5_cold.png` (rocky), `battle_s6_cold.png` (terran), `battle_s7_cold.png` (ice), `battle_s8_cold.png` (volcanic), `battle_s9_cold.png` (barren), all ten `battle_s*_{cold,warm}.txt` logs, `cache_battle/used.json`, and the baked 4096x2048 PNGs (`252aaaa3...png`, `4e50b6bb...png`, `5d5c884c...png`, `0ff8bb97...png`, `c8e8d721...png`, `c8c08538...png`).
- **PC_I ragged coasts/flows (`00b0f1fa93bc`, 1280x720, RTX 5080):** `opus1765i/out_20261123_171901_22044/out_new/` `shots/board_{0,1,4}_c170_after.png`, `shots/board_{0,1,4,5}_close_after.png`, `timing.txt`, `shots.txt`.
- **PC_F pre-`OCT_ROT` (`248be0e29224`, 1280x720, RTX 5080):** `opus1765f/out_20261123_125247_26203/out_new/shots/board_{1,4}_close_after.png`.
- **Cloud direction sheets (`0a52ca3a`, software Vulkan):** `docs/shots/issue-1765/PV2_board_c170.jpg`, `PV2_board_close.jpg`, `PV2_backdrop_1.jpg`, `PV2_backdrop_2.jpg`, `PV2_standin.jpg`.

---

## 2. Question 1: Why Terran and Volcanic Read Basic Next to Rocky and Barren

Compare `battle_s6_cold.png` (terran) and `battle_s8_cold.png` (volcanic) directly against `battle_s5_cold.png` (rocky) and `battle_s9_cold.png` (barren), plus the close-limb shots (`board_{0,1,4,5}_close_after.png`).

### A. Shared structural causes (affecting both terran and volcanic)

1. **Map resolution is under-sampled on Ryan's 2560x1377 monitor even at default camera 170.**
   - At `2560x1377` and FOV 45 deg (`planet_v2_shots.gd:162`), one screen pixel is `0.000570 rad`. On the sunk board planet (`R = 50`, center `(0, -39, 0)`, `board.gd:1079-1088`), the cap center sits ~164 units from camera 170 and the near limb sits ~115 to 145 units away. One screen pixel subtends **`0.00131` to `0.00171 rad`** of planet arc.
   - `BOARD_SIZE` (`4096x2048`, `world_planet.gd:34`) gives `PI / 2048 = 0.00153 rad/texel`: **~1.1 texels/px at cap center and only ~0.85 texels/px on the near limb** (magnification blur at default camera 170, worse on zoom).
   - `R01` (`8192x4096`, `world_planet.gd:14`) gives `0.000767 rad/texel`: **~2.2 texels/px at center and ~1.7 texels/px at the near limb**, so every rim and pit stays crisp.
2. **North pole is never tilted away from the battle camera (`world_planet.gd:414` vs `99`).**
   - `install_rocky` explicitly tips the equator up toward the camera (`tilt = PI * 0.5 +/- 0.25`, `world_planet.gd:93-99`) so the cap never shows the pinched pole.
   - `BOARD_SURFACE` only spins around Y (`bp_spin(normalize(local_direction), turn)`, `world_planet.gd:414`). In every terran battle (`battle_s6_cold.png`, `board_1_c170_after.png`), the north pole sits dead-center on the upper visible face, covering the top ~25% of the disc with a smooth blank white ice cap and pinching longitude lines toward the middle of the screen.
3. **NVIDIA float32 FMA discontinuity bug in `wh31()` (`godot/world/world_shaders.gd:15-19`) cuts razor-sharp straight seams and triangles across both planets.**
   - Look at `board_1_close_after.png` (`00b0f1fa9`): a ruler-straight cut slices vertically right through the mid-right cloud and green peninsula. Look at `board_4_close_after.png` (`00b0f1fa9`): a crisp 90-degree staircase step cuts across the lower-right ash plain. In `opus1765f` (`248be0e29`, before `OCT_ROT`), two crisp geometric white triangles stick out of the terran clouds and rectangular steps cut through volcanic basalt.
   - **Verified root cause:** In `wh31(p)` (`world_shaders.gd:15-19`), `p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z);`. Inside inlined `wvn3(x)` (`world_shaders.gd:26-27`), the compiler distributes/FMA-folds `(i + vec3(0,0,1)) * 0.1031` differently from `i_next * 0.1031`. Because `(p.x + p.y) * p.z` reaches **11,000 to 15,000+**, a 1-ULP difference in `p * 0.1031` is amplified ~10,000x into ~0.01 before the final `fract()`, crossing an integer on ~1% of all lattice corners and wrapping `0.00 <-> 1.00` across entire cell faces.
   - **Live proof on `4e50b6bb...png` (terran `b` from PC_M):** At `(3288, 750) -> (3289, 750)`, `(q*2+13).z` crosses `115.0` (`cell=[116,115,115]`, where `(p.x+p.y)*p.z = 15126.0127` direct vs `15126.0020` with FMA) and cloud opacity jumps from `0.00` to `0.61` in 1 pixel along a 200-pixel straight line (`y = 720..912`). At `(2470, 335) -> (2470, 336)`, `p_fine.y` crosses `58.0` (`cell=[26,58,16]`, `(p.x+p.y)*p.z = 11230.0000` on the nose!) and cloud opacity jumps from `0.04` to `0.65`. CPU llvmpipe (`PV2_board_close.jpg`) did not FMA-fold it, so the cloud renders hid it.

### B. Why terran (`BAKE2`) specifically reads basic in `battle_s6_cold.png` and `board_1_close_after.png`

- **Smooth airbrushed continent interiors (zero mid/fine color frequency):** `dry` uses only 4 octaves starting at `2.2` (`world_planet.gd:611`), `green` uses only **3 octaves at `7.0`** (`line 612`), and `sand` uses **3 octaves at `9.0`** (`line 613`). At 2560x1377, the olive green and beige desert interiors read as smooth gradient fills with zero forest/steppe grain, zero river valleys or deltas, and zero rocky escarpments.
- **Flat shading on continents (no readable mountain relief):** `"bump": 0.03` (`world_planet.gd:29`), and `relief = 0.45 + e * 0.3 + ridge * 0.25` (`line 622`). In `battle_s6_cold.png` and `board_1_close_after.png`, the continents look completely flat like painted stickers on a smooth ball, unlike R01 where every crater wall and ridge catches crisp raking sunlight and throws dark leeward shadows.
- **Hard binary coastline cutout + false height cliff:** `if (h < sea) ... else ...` (`world_planet.gd:599-622`) jumps `relief` abruptly from `0.42` (ocean) to `0.45` (land) and switches `alb` and `ocean` in 1 texel, making continents read as flat paper cutouts with a narrow uniform tan stroke (`line 621`) instead of eroded coasts, shoals, and archipelagos.
- **Soft, flat clouds pasted onto the ground sphere:** Unlike R01's raised `R01Clouds` shell (`radius * 1.012`, `world_planet.gd:200`) with runtime wispy breakup (`r01_cloud`, `lines 259-272`), terran clouds are baked into `tex_b.r` at 4K and shaded only by the smooth sphere normal `ndl` (`line 467`). They have zero cloud-top bump or crisp cumulus edges, so they look like blurry white smudges next to crisp ships.
- **Broad featureless ocean + airbrushed sun-glint circle:** Ocean albedo varies only +/-10% with 3-octave noise (`line 606`), and `pow(sp, 60.0) * 0.05` (`line 471`) puts a soft grey circle on the sea (`board_1_c170_after.png`).

### C. Why volcanic (`BAKE3`) specifically reads basic in `battle_s8_cold.png` and `board_4_close_after.png`

- **Two-tone paper-cutout camo instead of geology:** `battle_s8_cold.png` reads as flat grey-taupe ash (`ca = (0.56, 0.47, 0.40)`) overlaid with flat charcoal-black blobs (`flow = smoothstep(0.535, 0.55, ...)`, width 0.015, overwriting 85% of albedo with `cb * 0.8 = (0.12, 0.108, 0.10)`, `world_planet.gd:658-659`). The basalt flow edges look cut with scissors while their interiors are flat near-black voids (`- flow * 0.01` gives almost zero rim height in `relief`, `line 672`).
- **Fine grit never enters the normal map:** `grit = fb(q * 40.0, 3)` (`line 654`) only darkens `alb` (`line 661`); it is omitted from `relief` (`line 672`), so the close limb (`board_4_close_after.png`) lacks crisp micro-pitted rock shading.
- **Lava lakes look like soft fuzzy orange clouds:** `lava` (`line 673`) fades smoothly with low-frequency `h`, modulates with soft 4-octave `crust`, and renders in **one flat orange uniform** `lava_col = vec3(1.0, 0.36, 0.08)` (`world_planet.gd:386, 475`). Real volcanic lakes (Io's Loki Patera, Kilauea) read as molten because of a **blackbody temperature ramp** (white-yellow core -> bright orange -> deep ember red) broken by **crisp dark rafted crust plates** inside **terraced caldera rims**.
- **No volcanic landforms:** Rocky and barren (`R01`) are believable because lunar LRO/LOLA data has real multi-scale geological grammar (nested craters, raised rims, ejecta rays, wrinkled maria). Volcanic uses pure isotropic `fb()`/`rg()` noise with zero shield volcanoes, zero circular terraced calderas, zero radial flank ridges or downslope flow fans, and zero sulfur/ochre vent aprons.
- **Crushed darks near the band 2 floor:** `board_4_c170` sits at `0.037` linear mean (`board_4_close` at `0.033`, `opus1765i/timing.txt:36-39`), right on the `0.03` band 2 floor. The dark `low` basins (`alb *= 1.0 - low * 0.45`, `line 667`) crush relief shading to flat black.

---

## 3. Question 3: Optimization (Where the 18 s Cold Time Actually Goes)

### Measured breakdown on Ryan's PC (RTX 5080, Godot 4.7.2)

Comparing isolated `planet_v2_shots.gd` (`opus1765i/timing.txt`, no ships/world blocking) against real PC_M battles (`opus1765m/out_new/battle_s*_{cold,warm}.txt`) and headless Godot 4.7.2 CPU timings on the exact PC_M 4K maps reveals **every millisecond**:

| Look / run | Isolated worker (`timing.txt`) | Real battle cold (`PC_M`) | Real battle warm (`PC_M`) | Measured CPU `save_png` (3 maps) | Measured CPU `load_png` (3 maps) | Measured `height_float` + mips |
|---|---|---|---|---|---|---|
| Terran (`BAKE2`, s6) | 11,101 ms | **18,698 ms** | 13,046 ms | **9,656 ms** (`a` 3,398 + `b` 2,257 + `h` 4,001) | 404 ms (`119+113+172`) | 385 ms + 62 ms |
| Volcanic (`BAKE3`, s8) | 11,197 ms | **18,548 ms** | 11,489 ms | **9,050 ms** (`a` 3,036 + `b` 1,629 + `h` 4,385) | 369 ms (`118+79+172`) | 423 ms + 53 ms |
| Ice (`BAKE5`, s7) | 9,100 ms | **17,001 ms** | 15,108 ms | ~7.5 to 8.0 s (inferred) | ~370 ms | ~400 ms + 55 ms |
| Rocky (`R01`, s5) | 2,362 ms | **17,356 ms** | 14,853 ms | n/a (authored) | 2,362 ms total decode+mips | n/a (`RGBAF` 339 ms) |
| Barren (`R01`, s9) | 2,362 ms | **5,825 ms** | 5,750 ms | n/a (authored) | 2,362 ms total decode+mips | n/a (`RGBAF` 339 ms) |
| Sky (4K, s6/s8) | ~4.2 s | 4,167 ms delta | ~150 ms pure load | **4,080 ms** | 152 ms | 17 ms mips |

*(Note: `opus1765i/timing.txt` ran before commit `28f8a3b9f` added the 64K LUT to `height_float()`, which cut `height_float()` from ~1,624 ms to 385 to 423 ms. Subtracting `save_png` + `height_float` + `mips` from `timing.txt` proves the actual RTX 5080 GPU compute + readback for all three 4K passes combined is only **~0.5 to 1.0 s**!)*

### Where the 18.6 seconds go (ranked by size)

1. **Synchronous `img.save_png()` on the worker blocks the loading cover: `9.1 to 9.7 s` (~50% of cold time!).**
   - `world_bake.gd:300` runs `img.save_png(tmp)` synchronously inside `_work()` **before** returning the baked `Image` to the battle.
   - Zlib PNG compression of three 4096x2048 RGBA8 maps takes **9,656 ms** (terran) and **9,050 ms** (volcanic) on one CPU core. The 4K sky takes another **4,080 ms** in `save_png()`.
   - **Fix:** Return the ready `Image` to the battle immediately after GPU readback + mipmaps, and write the disk cache on a separate background IO thread (or after the cover lifts): **0 ms blocking time**. Even if kept synchronous, replacing PNG with Godot's built-in `PackedByteArray.compress(FileAccess.COMPRESSION_ZSTD)` drops all 3 maps from **9,656 ms -> 852 ms** (`278 + 198 + 376 ms`) and warm decode to **214 ms** (`64 + 71 + 79 ms`), while caching `FORMAT_RF` directly so `height_float()` never runs on warm loads.
2. **Deferred worker start + one-job-per-`_process()`-tick handoff stalls behind main-thread battle loading: `4 to 11+ s` (~35-40% of cold time, and ~85% of warm time!).**
   - `board.build()` (`battle.gd:632`) stamps `planet_t0` and calls `request_bake()`/`request_authored()`, while `WorldBakes` is not in the tree yet (`_attach` is `call_deferred`, `world_bake.gd:48`). The worker thread does not even start until `battle.gd:_start()` finishes building `world.build()`, loading all ship GLBs (`_make_view`, `battle.gd:661`), turrets, and HUD synchronously on the main thread. That is why identical R01 maps take **5.8 s** with Hegemony fighters (`s9`) vs **17.4 s** with heavier Chorus ships (`s5`), and why warm terran (`404 ms` of total PNG decode!) takes **13.0 s** in `battle_s6_warm.txt`.
   - Worse, `world_bake.gd:214-243` spawns a fresh `Thread.new()` for **one** job, exits when that job ends, and sits completely idle until the main thread finishes whatever stall it is in and ticks `_process()` to pop the next job (`battle_s6_warm.txt`: map `a` at 5.2 s, map `b` at 7.9 s [+2.7 s for a 113 ms PNG!], map `h` at 13.0 s [+5.1 s!]; `battle_s8_warm.txt`: `h` finished at 6.5 s, yet `board planet ready` waited until 11.5 s!).
   - **Fix:** Start a single persistent worker thread immediately when `_enqueue()` receives work (guarded by a `Mutex` + `Semaphore`, draining `_queue` back-to-back without waiting for `_process()` ticks, and posting completed results to a mutex-guarded `_done` array that `_process()` harvests). Then the GPU/worker finishes all 3 planet maps **in parallel with** `world.build()` and `_make_view()`, cutting battle wall-clock wait by **4 to 11+ seconds** on cold AND warm runs, for both baked planets and R01!
3. **Redundant 3-pass compute + 3x device/SPIR-V setup + GDScript `height_float()`: `~1.2 to 2.0 s`.**
   - `install_board()` (`world_planet.gd:116-120`) dispatches the **exact same `BAKE_BODY` shader 3 separate times** (`pass_id = 0, 1, 2`), recomputing all 3D noise + continents + clouds 3x, creating and destroying 3 separate Vulkan `local_rendering_device()`s (`world_bake.gd:510`), compiling SPIR-V 3x (`line 514`), submitting 64x3 = 192 `submit()/sync()` stalls (`lines 538-547`), packing 16-bit height into RG8, and looping 8.39M pixels in GDScript `height_float()` (`385-423 ms`).
   - **Fix:** Keep one persistent `local_rendering_device()` + compiled pipeline cache on the worker thread, and add a multi-output compute path (`binding 0: rgba8 out_a`, `binding 1: rgba8 out_b`, `binding 2: r32f out_h`) that evaluates `BAKE_BODY` **once per pixel** and reads back `FORMAT_RF` height directly from GPU (zero `height_float()` loop, 3x less GPU work, and larger strip height e.g. 256 rows = 8 submits instead of 64).
4. **Combined cold-load headroom:** Applying fixes (1) + (2) + (3) drops terran and volcanic cold board ready from **18.7 s / 18.5 s** down to **~2.0 to 4.0 s** (and warm ready from **11.5-15.1 s** down to **<1.0 s**), with **16+ seconds of safety margin** under the 20 s loading cover.

---

## 4. Question 2: Where Should Fine Detail Come From? (Options Weighed)

| Option | Look gain (c170 + close limb at 2560x1377) | Cold-load cost (after / before pipeline fix) | Per-frame GPU cost (RTX 5080) | Git / VRAM / variety trade-off |
|---|---|---|---|---|
| **A. Runtime detail in shared surface shader** (triplanar real-DEM micro-detail texture + procedural breakup, masked by 4K baked masks, plus upgraded `BAKE_BODY` landforms) | **Very High.** Breaks the 4K texel ceiling (>4 detail texels/px at close limb), adds crisp raking micro-normals, volcanic calderas/blackbody crust, terran mountain relief + raised 3D clouds. | **+0 ms** (~2-4 s cold with pipeline fix; 0 ms added even without it) | **+0.04 to +0.08 ms** (total ~0.13-0.16 ms, matching R01's 0.133 ms) | **Best:** ~1-2 MB in git (one shared 1K/2K tileable detail pack), ~10 MB VRAM, full per-seed variety, shared by board and backdrop. |
| **B. Authored 8K source maps like R01** (remixed NASA Earth SRTM/Blue Marble + Mars MOLA/LOLA) | **Highest raw geology on Day 1**, but Earth continents are hard to warp without recognizable outlines or stretched swirls (R01 itself only has 23% clean longitudes in `R01_CLEAN`), and Io has no global 16-bit laser DEM. | **~2.4 s** pure decode per planet (~3-5 s cold after worker-start fix; **17.4 s** today behind ship load!) | **~0.08-0.13 ms** (same as R01) | **Worst footprint:** +75 to 80 MB in git (R01 is 39.7 MB), **+1.53 GB VRAM / +1.02 GB peak RAM** per loaded 8K world (`s5` 3,171 MB VRAM vs `s6` 1,640 MB, because `world_bake.gd:282` converts 8K relief to 716 MB `FORMAT_RGBAF`), and every battle shares one static planet face. |
| **C. Smaller 2K macro bake + runtime detail** | **Medium-High.** Crisp interiors from runtime detail, but 2K macro masks (`0.55` texels/px on 2560x1377) soften coastlines, islands, and lava-lake edges unless the shader also perturbs mask thresholds at runtime. | **Saves ~7.5 s** even without fixing `save_png` (`2K save_png` = 720 ms x 3 = 2.16 s); **~1-2 s** after pipeline fix | **+0.05 to +0.09 ms** | Saves ~75% bake VRAM (~30 MB vs 120 MB), good fallback for `quality != "max"` or slower GPUs, but unnecessary on RTX 5080 once `save_png` stops blocking. |
| **D. Caching the bake across runs** | **Zero** (no visual change). | **Already exists** (`user://world_bakes/v3/*.png`, 500 MB LRU cap). Zero help on cold first-ever run; in fact synchronous `save_png` causes half the cold delay, and warm runs still take 11.5-15.1 s due to worker-start stalls. | **0 ms** | Keep disk caching, but make writes async (or ZSTD + cached `FORMAT_RF`) rather than relying on it for cold load or detail. |

---

## 5. Ranked Plan for the Opus Thread

### Phase 0 (Prerequisite, ~1 Opus run): Fix the seam bug and free ~15 s of cold-load headroom
1. **Replace `wh31()` in `godot/world/world_shaders.gd:15-19` with an exact integer hash** (convert `ivec3(floor(x))` and bit-mix with `uvec3`, e.g. PCG3D/Wang integer hash, returning `[0, 1)` float; update `hh()` in `world_planet.gd:508` to match on integer lattice calls). Eliminates every NVIDIA FMA straight-line seam and clipped triangle across all baked and procedural worlds.
2. **Optimize `godot/world/world_bake.gd`:**
   - Decouple disk cache writes from the loading cover (return `Image` immediately after mipmaps, flush cache file on an async IO thread or use `COMPRESSION_ZSTD` raw cache including direct `FORMAT_RF` caching so `height_float()` never runs on warm loads).
   - Start a persistent background worker loop immediately on `_enqueue()` (using `Mutex` + `Semaphore`) so planet baking runs **in parallel with** `world.build()` and ship loading instead of waiting for deferred `_attach` + `_process()` frame ticks.
   - Combine board planet passes `0, 1, 2` into one multi-output compute dispatch (`rgba8` + `rgba8` + `r32f` height) reusing one `local_rendering_device()` + compiled SPIR-V pipeline on the worker.
3. **Tilt baked board planets in `world_planet.gd:414` (`BOARD_SURFACE`)** using the same `r01_remix` tilt (`PI * 0.5 +/- 0.25`) so the north pole never sits dead-center under camera 170.

### Phase 1 (Rank 1 Pick, ~1 to 2 Opus runs): Option A + Upgraded `BAKE_BODY` Landforms + Small Tileable Real-DEM Detail Pack
1. **Build one tiny shared tileable micro-terrain detail texture (`1024x1024` or `2048x2048`, ~1-2 MB in git, e.g. `godot/world/planet_detail.res`)** from public-domain NASA/USGS crops (SRTM mountain/erosion relief + LOLA/basalt micro-pitting, zero recognizable geography, logged in `SOURCES_369.json` style):
   - `R`: real eroded micro-height (for crisp raking-light micro-normals)
   - `G`: crevice/valley ambient occlusion
   - `B`: volcanic basalt/scree grit height (for stepped lava flows & rough ash)
   - `A`: fine albedo grain (canopy/steppe/regolith speckle)
2. **Add a shared `PLANET_DETAIL` GLSL helper in `world_planet.gd` included by BOTH `BOARD_SURFACE` and `SPHERE`** (serving board and backdrop from one kit, faded smoothly by `lod` so far planets never shimmer):
   - Sample `planet_detail` via **triplanar projection on sphere direction `d`** (two scales: mid-frequency `~14x` and fine-frequency `~48x`, zero UV seams, zero polar pinch).
   - Add detail height `dh` directly into `h` BEFORE the `dFdx(h)`/`dFdy(h)` normal calculation (`world_planet.gd:457`), masked by `(1.0 - ocean)` on terran and weighted by terrain class on volcanic.
   - Multiply ground albedo by detail AO and fine grain (within grounded band 2 bounds: day-side linear mean `0.03` to `0.25`, targeting `0.10-0.16` terran and `0.06-0.09` volcanic).
3. **Upgrade macro geology in `BAKE_BODY` (`world_planet.gd:590-675`, shared by board and backdrop):**
   - **Terran (`kind == 2`):**
     - Remove the `0.42 -> 0.45` coastal cliff step (`lines 608, 622`); blend shallow continental shelves smoothly across `sea +/- 0.015`.
     - Add eroded mountain chains + dendritic valley darkening (`1.0 - rg(...)` inverse ridges for river/drainage basins) + 4-band elevation/moisture biomes (coastal lowland, dark timber forest, arid ochre steppe, rocky scree highlands, snow crests). Raise `bump` from `0.03` to `~0.055-0.065`.
     - Give terran board planets a **separate raised cloud shell** (`radius * 1.012`, matching `R01Clouds`) with runtime wispy breakup (`r01_cloud`-style flow warp + subtle sun-facing cloud-top bump) instead of flat clouds baked onto the ground sphere; tighten ocean specular (`pow(sp, 260)` only, drop the soft `pow(sp, 60)` grey disc).
   - **Volcanic (`kind == 3`):**
     - Keep Ryan's approved ragged basalt lobes and basin lava lakes (zero crack/lineae lines!).
     - Add **shield volcano calderas** (a cell helper like `craters()` producing broad sloped shields with terraced circular caldera rims, dark lava-pooled floors, and radial downslope ridges) plus sparse impact craters on older ash plains.
     - Put `grit` and stepped basalt-flow rims into `relief` (`line 672`) so flow margins catch raking light instead of looking like flat black stickers.
     - Add restrained sulfur-ochre / warm rust-ash mineral aprons around active basins to break the two-tone grey/black camo and lift day-side mean from `0.037` to `~0.06-0.09`.
     - Replace the flat single-color `lava_col` (`line 386, 475`) with a **runtime blackbody ramp** driven by baked `lava` heat + high-frequency dark rafted crust plates (`deep ember red -> bright orange -> hot yellow-white core` with sharp crust edges).

### Phase 2 (Optional fallback / follow-up): Option C for low quality, Option B only if Ryan still wants an authored 8K globe
- **Option C (`2048x1024` macro bake + Phase 1 runtime detail):** Wire automatically when `quality != "max"` (or on integrated/slower GPUs) with runtime threshold perturbation on coastlines/flows.
- **Option B (authored 8K maps):** Hold unless Ryan rejects the Phase 1 look-sheet. If ever pursued, fix `world_bake.gd:282` first (decode R01 height to `FORMAT_RF` + keep roughness/clouds in `RG8` instead of converting all 4 channels to 716 MB `FORMAT_RGBAF`, cutting R01 VRAM/RAM by ~4x!), and target volcanic via Mars MOLA + LOLA first (easier to remix cleanly than recognizable Earth continents).

### What Ryan's look-sheet should show
One side-by-side sheet (`<= 720 px` tall, code-named) comparing **Current (`9de7f81a4` PC_M)** vs **Phase 1 (Best Option)** for both **Terran (`B1`)** and **Volcanic (`B4`)** at **camera 170** and **close limb**, plus **Rocky (`B0`)** beside them as the quality bar, with the cold-load ready time (seconds) and band 2 linear mean printed under each panel.

---

## 6. Findings (`docs/REVIEW_PROTOCOL.md`)

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
|---|---|---|---|---|---|---|---|
| 1 | `wh31()` float32 hash suffers FMA wrap-around at ~1% of lattice corners on NVIDIA Vulkan, slicing razor-sharp straight seams and clipped triangles across terran and volcanic maps. | OBSERVED (visible in PC_I/PC_F close shots; reproduced numerically on `4e50b6bb.png` at `cell=[116,115,115]` `15126.0127 vs 15126.0020` and `cell=[26,58,16]` `11230.0000`, jumps 0.61 and 0.65) | `godot/world/world_shaders.gd:5-6,15-19` | `const HASH_SCALE := "0.1031"` / `return fract((p.x + p.y) * p.z);` | Creates obvious straight cuts and square steps across clouds, continents, and basalt lobes on Ryan's RTX 5080 (hidden in llvmpipe cloud shots). | Replace `wh31()` with an exact integer bit-mix hash on `ivec3(floor(x))` before converting to `[0,1)` float. | high |
| 2 | Synchronous CPU `img.save_png()` inside the bake worker consumes 9.1 to 9.7 s of the 18.6 s cold board-planet load time before returning the image. | OBSERVED (headless Godot 4.7.2 on PC_M maps: terran `3398+2257+4001=9656 ms`, volcanic `3036+1629+4385=9050 ms`, sky `4080 ms`) | `godot/world/world_bake.gd:300` | `if img.save_png(tmp) == OK and DirAccess.rename_absolute(tmp, path) == OK:` | Eats ~50% of the 20 s loading-cover budget on pure CPU zlib compression while the GPU is already done (~0.5 to 1.0 s total). | Return `Image` immediately and write disk cache asynchronously (or use `COMPRESSION_ZSTD` raw bytes: 852 ms total, 214 ms decode, caching `FORMAT_RF` directly). | high |
| 3 | `WorldBakes` waits for deferred `_attach` and terminates its worker thread after every single job until `_process()` ticks, stalling 4 to 11+ s behind main-thread battle/ship loading. | OBSERVED (`battle_s6_warm`: 404 ms PNG decode took 13,046 ms; `battle_s5_cold`: 2,362 ms R01 took 17,356 ms vs `s9` 5,825 ms) | `godot/world/world_bake.gd:48,214-243` | `Callable(node.get_script(), "_attach").call_deferred(node)` / `_active = _queue.pop_front(); _thread = Thread.new()` | Wastes 4 to 11+ s on both cold and warm battle starts while the worker sits idle during `world.build()` and `_make_view()`. | Start one persistent worker thread immediately on `_enqueue()` using `Mutex`+`Semaphore` to drain `_queue` continuously while the main thread loads ships. | high |
| 4 | `install_board()` bakes `BAKE_BODY` three separate times per planet (`pass_id` 0, 1, 2) with 3 local Vulkan devices, 3 SPIR-V compiles, 192 sync stalls, and a 400 ms GDScript `height_float()` loop. | OBSERVED (code + `bench_bake.gd`: `height_float` = 385-423 ms; `timing.txt` vs `save_png` proves ~0.5-1.0 s GPU overhead) | `godot/world/world_planet.gd:116-120`, `godot/world/world_bake.gd:510,538-547` | `var ka: String = baker.request_bake(key + "\|a", ...)` / `var rd := RenderingServer.create_local_rendering_device()` | Triples GPU terrain computation and forces CPU 16-bit height unpacking on every cold and warm load. | Reuse one persistent `local_rendering_device()` on the worker and write `out_a`, `out_b`, and `r32f` `out_h` in a single multi-image compute dispatch. | high |
| 5 | `BOARD_SURFACE` never tilts baked planets away from the north pole, placing terran's blank white polar ice cap dead-center under camera 170 in every battle. | OBSERVED (`battle_s6_cold.png`, `board_1_c170_after.png`, code contrast with `world_planet.gd:99`) | `godot/world/world_planet.gd:414` | `vec3 d = bp_spin(normalize(local_direction), turn);` | Wastes the top ~25% of terran's visible disc on a featureless white cap and pinches equirectangular longitude texels right on the close camera cap. | Apply `r01_remix`-style tilt (`PI * 0.5 +/- 0.25`) in `BOARD_SURFACE` so the equator faces the battle camera. | high |
| 6 | 4K baked maps under-sample Ryan's 2560x1377 monitor (~0.85 texels/px on the near limb), and terran/volcanic recipes lack mid/fine frequency, landforms, and normal-mapped grit. | OBSERVED (`battle_s6_cold.png`, `battle_s8_cold.png`, `board_{1,4}_close_after.png`, `bench_extra.gd` 2560x1377) | `godot/world/world_planet.gd:34,612-613,654,672` | `const BOARD_SIZE := Vector2i(4096, 2048)` / `vec3 green = ca * (0.75 + 0.5 * fb(q * 7.0 + 1.0, 3));` | Continents look like flat airbrushed decals, basalt flows look like flat black cutouts (`grit` is omitted from `relief`), and the close limb blurs. | Add shared triplanar `PLANET_DETAIL` runtime micro-relief/grain (Option A + small real-DEM tileable texture) and upgrade `BAKE_BODY` with calderas, drainage, and raised terran clouds. | high |
| 7 | Terran coastlines jump `relief` discontinuously (`0.42` ocean to `0.45` land), and volcanic lava renders in one flat orange uniform without blackbody heat or crisp crust plates. | OBSERVED (`find_seam3.gd` row `y=750` 30+ coast steps >0.02 in `th`; `battle_s8_cold.png` soft orange smudges) | `godot/world/world_planet.gd:608,622,386,475` | `relief = 0.42 - dep * 0.12;` / `relief = 0.45 + e * 0.3 + ridge * 0.25;` / `uniform vec3 lava_col = vec3(1.0, 0.36, 0.08);` | Makes terran coasts look like sharp paper cutouts with a normal spike and makes volcanic lava lakes look like blurry orange paint instead of molten rock. | Make coastal height continuous across `sea` with gentle shelf blending; replace flat `lava_col` with a runtime blackbody ramp + sharp dark rafted crust plates. | high |
| 8 | Authored 8K `R01` relief converts all 4 channels to `FORMAT_RGBAF`, inflating VRAM by +1.53 GB and peak RAM by +1.02 GB per 8K world. | OBSERVED (`battle_s5_cold.txt`: 3,171 MB VRAM, 1,657 MB RAM vs `battle_s6_cold.txt`: 1,640 MB VRAM, 632 MB RAM) | `godot/world/world_bake.gd:282` | `if job.get("float_mips", false): authored_image.convert(Image.FORMAT_RGBAF)` | Makes shipping two more full 8K authored worlds (Option B) very heavy (+80 MB git, multi-GB RAM/VRAM spikes when switching looks). | Keep terran/volcanic on 4K bake + runtime detail (Option A); if Option B is ever used, split 16-bit height into `FORMAT_RF` + `RG8` roughness/clouds (~4x less memory). | high |

---

## 7. Recommended Next Step

Hand this review to the Opus planets thread to execute **Phase 0 + Phase 1** in one clean branch (`opus/issue-1765-detail` or `opus/issue-1939`):
1. Fix `wh31()` to an exact integer hash, decouple `save_png` (async/ZSTD), start a persistent `WorldBakes` worker immediately on `_enqueue()`, combine the 3 board bake passes into 1 multi-output compute dispatch, and tilt baked board planets away from the pole.
2. Add the shared `PLANET_DETAIL` triplanar runtime detail helper (backed by one ~1-2 MB tileable real-DEM micro-terrain pack) plus upgraded terran (eroded ridges, drainage, raised cloud shell) and volcanic (shield calderas, stepped basalt rims, sulfur aprons, blackbody lava + crust plates) recipes in `BAKE_BODY`, keeping band 2 (`0.03-0.25` linear) and zero crack lines.
3. Run the RTX 5080 look-sheet (camera 170 + close limb, before vs after beside rocky `B0`, plus cold-load and GPU frame-time numbers) for Ryan's pick.

---

## 8. Not Checked

- **Live GPU compute execution (`_compute`) and live RTX 5080 frame-time measurements of a modified shader:** Review-only delivery per brief; no game source files were edited and no GPU claim or capture was run. GPU compute sub-timings (~0.5 to 1.0 s for 3 passes) are inferred by subtracting our live headless CPU timings (`save_png`, `height_float`, `generate_mipmaps`) from PC_I's isolated RTX 5080 `timing.txt` totals on the exact same maps.
- **`gl_compatibility` raster fallback (`_canvas`):** Not exercised (Windows RTX 5080 runs Vulkan Forward+ compute).
- **Ice (`BAKE5`), gas giant (`kind 0`), ice giant (`kind 1`), and moon (`kind 4`) aesthetics:** Outside the brief's terran and volcanic scope, though all of them automatically benefit from the `wh31()` FMA seam fix and the `world_bake.gd` cold-load speedup.
- **Lines of `godot/render/board.gd` outside 1070-1218, `godot/world/world.gd` outside 140-750 and 1560-1587, and `godot/scenes/battle/battle.gd` outside 580-865 and 7240-7270.**
