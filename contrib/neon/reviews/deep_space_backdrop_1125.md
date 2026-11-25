# Deep-Space Backdrop and Starfield Review (main, Nov 25 2026)

- **Issue:** #2155 (run 1)
- **Reviewer:** Neon (Gemini 4 Neon)
- **Commit reviewed:** `3629e7331` (`main`, delivered on `neon/issue-2155`)
- **Scope:** Read-only code and existing-picture audit of the deep-space sky, starfield, sky bake, and Dead Star backdrop on `main` (`godot/world/world_sky.gd`, `godot/world/world.gd`, `godot/world/world_bake.gd`, `godot/world/world_shaders.gd`, `godot/fx/faction_looks.json`, plus supporting board/camera/planet/asteroid/nebula interfaces and committed / relay pictures). No GPU capture was run.

---

## Plain Verdict for Ryan

**No, the star cut never went in.** The space background on `main` is still the Nov 1 first-pass sky sitting behind Nov 23 to 25 ships, planets, asteroids, comets, stations, and storm lightning. Right now it puts **~10,000 to 13,500 bright white dots** into every 45-degree battle frame (25x to 35x over your locked R421 target of ~400), washes the play area in bright faction-colored fog (including **purple skies in half of all non-Eclipse battles** and **mustard soup** against the Chorus), bakes gradients in 8-bit so dark skies show contour bands, and puts big blurry white headlight blobs directly behind ships and storms.

**My pick and why:** Build **World Sky V2 (#1766) and 16-bit Sky Bake (#1502) together in one coordinated PR**, but **update the #1766 brief first** on four things that changed or turned out wrong on live `main`:
1. **Pull regional sky nebula way down and push it away from the board center.** Newer Ship Exteriors V2 (`#1786`), dark ice comets with faint tails (`#1782`), Band-2 planets (`#1776`), baked cyan lightning (`#1986`), and rose on-board nebula gas (`#1268` / `#2050`) all need calm near-black space (`0.00` to `0.015` linear) behind the board. Keeping bright orange, blue, or mustard sky gas behind the board makes on-board rose nebula and blue storms clash with the sky.
2. **Fix the purple-sky generator in `world_sky.gd:188-191`, not just Eclipse in `faction_looks.json:114`.** `world_sky.gd:191` swaps blue faction skies into purple `c2` for Sunward Crusade, Meridian Directorate, and Glasswrights across `world`, `deep`, and `nebula` regions, and line 188 blends Corsair into purple `c2` everywhere.
3. **Do not waste a round on `world_shaders.gd:103` (`front_only`).** Zero callers on `main` ever set `front_only`. The `deadstar_3_low` equator cut comes from `disc` / `core` / `LENS` depth interaction and placing the radius-15 sphere at `y = -10`.
4. **Bake the sky at `2048x1024` in linear 16-bit half-float (`RGBAH`, no mipmaps on `neb_tex`) instead of `4096x2048` 8-bit `RGBA8` with mipmaps.** Because sharp stars are drawn per pixel, `2048x1024` `RGBAH` kills `#1502` 8-bit banding while cutting cold sky bake work ~4x and VRAM from 42.7 MiB to 16.0 MiB (21.3 MiB if mips are kept for rock haze).

---

## Findings Table (Most Important First, Max 10)

| # | Finding | OBSERVED/INFERRED | file:line | Exact quote | Why it matters | Your fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | Starfield snow is still live (~10,000 to 13,500 stars per 45-deg view, 25x to 35x over R421's 400 target) and `star_floor = 0.15` lets stars punch through dark dust. | OBSERVED (code + `AC1361_comets_wide.jpg`, `storm1360_wide.png`); exact view count INFERRED from direct frustum lattice simulation of `star_layer` | `godot/world/world_sky.gd:497`, `godot/world/world_sky.gd:470`, `godot/world/world.gd:518` | `star_layer(d, 120.0, 0.955, 1.0, bd * 0.03)` / `* gain * (0.15 + 2.6 * m);` / `m.set_shader_parameter("star_floor", float(sf) if sf != "" else 0.15)` | Directly violates RULEBOOK 10.11 (R421: ~400 stars, `star_floor = 0.0`). Even dimmest `m = 0` Layer-3 stars emit `0.0525` linear (~25% sRGB), turning space into white static behind ships, comet tails, and hex lines; at `S = 650`, `3 * sig` exceeds the 2x2x2 cell box. | Cut to 2 sparse layers (~400 stars per 45-deg view, concentrated on `bd`), drop the `0.15` floor for a steep `pow(m, 4.5)` curve, tighten `sig` with a 1080p shimmer floor, and set default `star_floor = 0.0`. | high |
| 2 | Purple sky nebula is manufactured across 5 of 6 factions (15 of 30 faction-region pairs), not just Eclipse, violating RULEBOOK 10.9. | OBSERVED (code + `world_planet_before_after.jpg` Hegemony purple sky, `map_09_backdrops_sheet_a.jpg`); hue table INFERRED by evaluating lines 187-191 | `godot/world/world_sky.gd:191`, `godot/world/world_sky.gd:188`, `godot/fx/faction_looks.json:114` | `c2 = c2.lerp(Vector3(c1.z, c1.x * 0.8, c1.y) * 0.6, 0.55)` / `"nebula": [[0.1, 0.04, 0.16], [0.34, 0.14, 0.52], [1.0, 0.84, 0.55]],` | Swizzling `(b, r*0.8, g)` turns blue `c1` (Sunward, Directorate, Glasswrights) into magenta-purple `c2` (hue 284 to 309 deg), Corsair's red lerped with blue gives hue 276 deg, Eclipse `c1` is purple everywhere, `world_sky.gd:361` boosts saturation 1.45x, and `world.gd:1341-1342` copies `c1`/`c2` onto mid-ground wisps. | Replace Eclipse `nebula` in `faction_looks.json:114` with dark charcoal-slate/warm-ember, replace the RGB swizzle at `world_sky.gd:188-191` with a non-purple shadow hue (cool slate-teal or warm umber), and drop saturation push from `1.45` to `<= 1.15`. | high |
| 3 | Bright regional sky gas (`neb = 1.0`, `cover = 0.72`) aims its brightest core straight behind the board while `cine` has `underlay = 0.0`, clashing with V2 ships, comets, and terrain clouds. | OBSERVED (code + `gas2035_nebula_c170_calm.png`, `storm1360_wide.png`, `AC1361_comets_wide.jpg`) | `godot/world/world_sky.gd:33`, `godot/world/world_sky.gd:210`, `godot/world/board_look.gd:73` | `"nebula": {"neb": 1.0, "cover": 0.72, "dust": 0.6, "band": 0.4,` / `Vector3(rng.randf_range(-0.35, 0.35), -0.42, -0.85).normalized(),` / `return {"plate": false, "underlay": 0.0, "fills": false, "grid": "holo",` | The default camera looks down 34 deg along `(0, -0.557, -0.83)`, directly into `feature` `(±0.35, -0.42, -0.85)`. With no dark underlay in `cine`, bright orange/blue sky gas sits behind the hex grid, clashes with on-board rose nebula (`world_living.gd:138`) and steel-blue storms, and washes out dark Ship V2 shadow sides (`ambient = 0.095`) and faint comet tails (`gain = 0.22`). | Cut `REGION` `neb` by ~45 to 60% and `cover` to `0.20..0.42`, bias `feature` toward the upper horizon/corners instead of board center, and add a subtle non-colored sky dimming band directly behind the play area if needed. | high |
| 4 | Chorus mustard-yellow soup and `STOP_MOOD` boosts (`boss` 1.6x, `rival` 1.7x tint) breach Band 1/2 luminance budgets and leak purple or mustard into any sector. | OBSERVED (code + `map_10_backdrops_sheet_b.jpg` `nebula_crystal_belt_1_default`); bloom threshold crossing INFERRED (`0.50 * 1.6 = 0.80`) | `godot/fx/faction_looks.json:74`, `godot/world/world_sky.gd:78`, `godot/world/world_sky.gd:489` | `"nebula": [[0.14, 0.16, 0.06], [0.55, 0.38, 0.12], [0.8, 0.9, 0.35]],` / `"boss": {"neb": 1.6, "cover": 1.25, "c3": 1.3, "frame": 1.5},` / `g = mix(g, mood_tint * dot(g, vec3(0.3, 0.59, 0.11)) * 1.7, mood_mix);` | Chorus `[0.55, 0.38, 0.12]` in `nebula` (`neb = 1.0`) floods 70% of the screen in mustard yellow. On `boss` stops `mood_gain = 1.6` can push sky gas past `glow_hdr_threshold = 0.8` (`look.gd:364`). On `rival` stops `mood_tint * lum * 1.7` brightens the sky and injects Eclipse purple or Chorus mustard into clean sectors. | Re-palette Chorus `nebula` to dark olive-slate / muted ochre dust, cap `STOP_MOOD` `boss` `neb` at `1.15..1.25` (with darker base gas), and normalize `rival` tint to preserve luminance (`1.0` instead of `1.7`). | high |
| 5 | Issue 1766's Dead Star equator seam fix targets dead code (`front_only` is never set on `main`); the real `deadstar_3_low` hard cut comes from `disc`/`core`/`LENS` depth interaction. | OBSERVED (code grep across `godot/` + `map_09_backdrops_sheet_a.jpg` `deadstar_3_low`, `deadstar_low_and_close.jpg`) | `godot/world/world_shaders.gd:70`, `godot/world/world_shaders.gd:103`, `godot/world/world.gd:249` | `uniform float front_only = 0.0;` / `if (length(toFrag) > length(toHole)) { discard; }` / `dead_star(hw.call(int(ds["q"]), int(ds["r"])) + Vector3(0, -10, 0), 1.0)` | Zero files in `godot/` set `front_only > 0.5`, so implementing 1766 item 3 as written will change zero pixels. At low camera (`b = 1.32`, 14.4 deg down vs `disc_tilt = -25` deg), the opaque `disc` (`r_in = 18`) and `core` (`Rsh = 15`, spanning `y = -25..+5`) clip the depth-tested `LENS` quad (`world_shaders.gd:179`) at `z = hole_z`, creating a sharp cut across the shadow sphere. | Remove dead `front_only` code, verify `deadstar_3_low` on current `main`, and soften the grazing intersection between `core`, opaque `disc`, `DISC_HAZE`, and `LENS` (using `depth_test_disabled` + smooth `front` depth transition on `LENS`, or feathering `DISC` inner alpha at grazing view angle). | high |
| 6 | Sky bake quantizes dark gradients to 8-bit `R8G8B8A8_UNORM` PNGs (`#1502`), and 2.1x to 4.2x magnification plus embedded `lamp` baking turns RPDF dither back into contour rings. | OBSERVED (code + issue #1502 DEBAND_B receipt); magnification and step percentages INFERRED from `fov = 45` and `4096x2048` | `godot/world/world_bake.gd:733`, `godot/world/world_sky.gd:366`, `godot/world/world_sky.gd:488` | `format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM` / `g += (h3(vec3(px * 1.37, seed + 7.0)) - 0.5) / 255.0;` / `vec3 g = pow(t.rgb, vec3(2.2)) * neb_gain * mood_gain;` | At 45-deg vertical FOV, `4096x2048` shows only 512 vertical texels (magnified 2.11x at 1080p, 4.22x at 4K). In Band 1 (`0.002..0.015` linear), 1/255 gamma-2.2 steps are 6% to 15% relative luminance jumps. Bilinear filtering averages out texel-level RPDF dither while preserving bands, and `lamp` glows (`world_sky.gd:344-348`) bake smooth radial gradients right into 8-bit. | Switch sky compute bake to `DATA_FORMAT_R16G16B16A16_SFLOAT` (`rgba16f` / `Image.FORMAT_RGBAH`) in linear light (drop `pow(1/2.2)` and `pow(2.2)`), save cached sky as `.exr` or raw float16 binary, and keep TPDF dither only on the `gl_compatibility` fallback. | high |
| 7 | Cold sky bake runs 48 ray-march steps over 8.39M pixels across 64 `rd.sync()` stalls on a throwaway Vulkan device, then builds unused 4K mipmaps (+10.7 MiB VRAM). | OBSERVED (code + `world_sky.gd:100` "3.7 to 6.1 s" and `pc-out-opus1777ft4k` 2.1 to 14.2 s worker bake logs); VRAM sizes INFERRED from dimensions | `godot/world/world.gd:563`, `godot/world/world_bake.gd:748`, `godot/world/world_bake.gd:446`, `godot/world/world_sky.gd:418` | `"steps": 48 if quality == "max" else (40 if quality == "high" else 26),` / `for y in range(0, size.y, 32):` / `if img != null and not img.has_mipmaps(): img.generate_mipmaps()` / `uniform sampler2D neb_tex : filter_linear, repeat_enable;` | `4096x2048` `RGBA8` + mips uses 42.7 MiB VRAM + 42.7 MiB RAM, yet `SKY` uses `filter_linear` (no mips; only `world_rocks.gd:327` reads mip 4 for far rock haze). Moving blindly to `4096x2048` `RGBAH` + mips would jump to 85.3 MiB VRAM + 85.3 MiB RAM. Meanwhile 64 strip submits stall CPU-GPU sync 64 times per bake. | Bake the smooth gas/band sky at `2048x1024` `RGBAH` (16.0 MiB base, 21.3 MiB with mips, 4x fewer pixels -> ~4x faster cold bake) with 4 to 8 strips (128 to 256 px tall) and `32` ray-march steps (`max`), or keep `4096x2048` `RGBAH` only if mips are skipped (`64 MiB`) and a tiny 256x128 mip supplies `world_rocks.gd`. | high |
| 8 | Embedded `lamp[k]` halos and `far_galaxies` draw blurry white headlight orbs right behind ships and storms, and `dust()` adds 1,300 to 2,600 extra floating specks. | OBSERVED (code + `AC1361_comets_wide.jpg`, `storm1360_wide.png`) | `godot/world/world_sky.gd:503`, `godot/world/world_sky.gd:312`, `godot/world/world.gd:1596` | `exp(-a * a / 0.00006) * 0.25 + 0.0006 / (0.0004 + a * a) * 0.08);` / `c += vec3(0.95, 0.88, 0.8) * (exp(-r * r * 30.0) * 1.4` / `var n := {"belt": 2600, "graveyard": 2000, "storm": 1600}.get(mk, 1300)` | Visible in `AC1361_comets_wide.jpg` (two bright round orbs mid-right) and `storm1360_wide.png` (two white oval blobs behind the blue storm). Once 96% of star static is removed, these soft low-contrast blobs read as distracting artifacts; `lamp` placement (`world_sky.gd:531`) clusters all of them right around `feature` behind the board. | Tighten `lamp[k]` halos to crisp rare hero-star glints (cut broad `0.0004` glow tail 5x and scatter off board center), soften/shrink `far_galaxies` to subtle background landmarks (`<= 0.03` linear), and trim `dust()` speck brightness/count so they do not re-create star snow. | high |
| 9 | Issue 1766's proposed `galaxy_band()` multiplier (`0.14` to `0.22`) would blow past Cohesion Band 2 (`0.25` linear ceiling). | OBSERVED (code + plan); peak linear output INFERRED from `world_sky.gd:290-294` (`lum` max `2.22`) | `godot/world/world_sky.gd:294`, `contrib/opus/plans/world_consistency_v2.md:95`, `contrib/opus/plans/global_cohesion_standard.md:36` | `return col * lum * band * 0.06;` / ``Raise `galaxy_band()` luminance from `* 0.06` to a balanced cinematic range (~`0.14` to `0.22` `` | At `band = 1.0`, `lum` reaches `2.22` at the galactic center (`world_sky.gd:290`), so `* 0.06` is already `0.133` linear. Multiplying by `0.14..0.22` pushes the band to `0.31..0.49` linear, brighter than Planets V2 (`0.03..0.25`) and lit hulls, competing with hex lines. Meanwhile `rift` (`line 292`) stops at `0.15` minimum instead of carving true black lanes. | Hold `galaxy_band()` scale near `0.08..0.10` (clamped `<= 0.18` linear), sharpen internal contrast by letting `rift` cut down to `0.0` (`clamp(rift, 0.0, 1.0)`), and rely on darker voids (`0.00..0.015`) to make the Milky Way pop. | high |
| 10 | Live `SKY` shader loops 24 3D-grid cells per pixel at 4K and lacks the Cohesion Standard's automated sky-palette and star-budget anti-drift gate. | OBSERVED (code); ALU savings INFERRED from reducing 3x8 to 2x8 cells and raising skip threshold | `godot/world/world_sky.gd:462`, `godot/world/world_sky.gd:497`, `godot/world/test/planet_v2_check.gd:342` | `for (int i = 0; i < 8; i++) {` / `for table in [SKY.PLANETS, SKY.PLANETS_ALT]:` | At 4K (8.29M pixels), `SKY` evaluates 24 `sh33` hashes per uncovered sky pixel plus `acos(dot)` on every star hit. Meanwhile `global_cohesion_standard.md:120` Law 5 Gate 4 ("Zero-Purple & Starfield Budget Gate") was only built for planets (`planet_v2_check.gd:342`), leaving `world_sky.gd` and `faction_looks.json` `nebula` unguarded. | Collapse `star_layer` from 3 layers (24 cells) to 2 sparse layers (16 cells: rare hero stars + galactic-band pinpoints), use `length(sp - d)` instead of `acos(dot)` for star distance (cheaper and full float32 precision), and add `sky_v2_check.gd` asserting zero purple across all 30 faction-region pairs, `star_floor == 0.0`, and Band-1/2 sky budgets. | high |

---

## Detailed Assessment Against the Four Review Axes

### 1. Is the #1766 Brief (`world_consistency_v2.md` Section 3) Still Right After Recent World & Ship Upgrades?

**Mostly right in direction (Grounded Cinematic Space, ~400 stars, `star_floor = 0.0`, 16-bit bake), but four parts need updating because the rest of the game moved on:**

1. **Nebula & Storm Work (`#1268`, `#1986` merged, `#2050` in flight):** On-board calm nebula is now locked to **hydrogen rose** (`world_living.gd:138-141`), ion storms are **steel-blue/cyan** with bright Blender-baked lightning (`ion_storm.gd:82-90`, `world_living.gd:328-360`), and `#2050` adds multi-layer soft gas depth. Look at `gas2035_nebula_c170_calm.png` and `storm1360_wide.png` (`voidsworn-relay`, captured Nov 25): the bright orange/rust sky nebula behind the board fights the rose nebula and cyan storm for hue and value. **The sky nebula must step back into deep dark-space framing** (lower `neb`, lower `cover`, pushed toward the upper horizon/edges rather than centered behind the hex grid at `world_sky.gd:210`).
2. **Asteroids & Comets V2 (`#1782`, merged):** Crystal spikes are gone (`RULEBOOK 10.11`). The `"crystal"` biome (`nebula_crystal_belt`) is now **dark dusty ice comets with faint additive anti-sun gas tails** (`world.gd:1170-1275`, `world_rocks.gd:265-275`). In `AC1361_comets_wide.jpg`, the pale blue-grey nebula haze (`neb = 1.0`) and star static wash out the delicate comet tails. Darker void + sparse crisp stars will immediately make the comets and pale frosted `ice` belts read twice as cleanly.
3. **Planets V2 (`#1776`, merged) & Ship Exteriors V2 (`#1786`, merged) & Stations/Hulks (`#1772`, `#1998`, merged):**
   - `PLANETS[2]` is already re-paletted off purple (`world_sky.gd:47`, guarded by `planet_v2_check.gd:342`).
   - All backdrop planets and moons are calibrated to **Band 2 (`0.03` to `0.25` linear)** with deep night terminators. Darkening the sky into Band 1 (`0.00` to `0.015`) lets those planet terminators, atmosphere rims, and night city lights sit naturally in space instead of looking like dark discs pasted over bright orange/blue walls.
   - Ship Exteriors V2 lowered flat ambient from `0.25` to `0.095` (`look.gd:116`) and `rim_spec` from `8.0` to `3.0`, giving ships deeper shadow sides and HDR emissive focal points. Calm dark space behind the board is now essential for silhouette separation, especially for dark Eclipse, Sunward, and Chorus hulls and dark R425 derelicts.
4. **Two #1766 specifics are outdated or wrong on `main`:**
   - **Dead Star seam (`world_shaders.gd:103`):** `front_only` is dead code with zero callers. Do not ship a "fix" to lines 99-104; diagnose the actual `disc` / `core` / `LENS` grazing intersection at `world.gd:766-858` and `world_shaders.gd:177-292`.
   - **`galaxy_band()` multiplier (`world_consistency_v2.md:95`):** Do not jump `* 0.06` to `0.14..0.22` blindly; keep peak galactic core under `~0.18` linear and get drama from deeper dark rifts (`rift` down to `0.0`) against near-black void.
   - **Extra purple root cause:** Fixing only `faction_looks.json:114` leaves purple skies in 12 non-Eclipse faction-region combinations via `world_sky.gd:188-191`.

### 2. RULEBOOK 10.9, 10.11, and Global Cohesion Standard (`global_cohesion_standard.md`)

| Standard / Rule | Requirement | Status on `main` (`3629e7331`) |
|---|---|---|
| **RULEBOOK 10.11 / R421 (Star count)** | ~400 pinpoint stars per 45-deg view (~96% cut), galactic clustering, steep magnitude curve | **FAIL.** ~9,986 stars off-band to ~13,500+ across band per 45-deg 16:9 frame (`world_sky.gd:497`), flat `0.15` brightness floor (`line 470`). |
| **RULEBOOK 10.11 (`star_floor`)** | Default `star_floor = 0.0` (keep `VS_STAR_FLOOR` override) so dust lanes black out stars | **FAIL.** Default is `0.15` in both `world.gd:518` and `world_sky.gd:427`. |
| **RULEBOOK 10.9 (No purple / no mustard)** | Zero indigo-to-purple sky/nebula, zero mustard fog | **FAIL.** Eclipse `faction_looks.json:114` is `[0.34, 0.14, 0.52]`; Chorus `faction_looks.json:74` is mustard `[0.55, 0.38, 0.12]`; `world_sky.gd:188-191` creates purple `c2` for Sunward, Directorate, Glasswrights, and Hullbreakers; `BAKE_BODY` default `c1` (`world_sky.gd:235`) is purple `(0.5, 0.2, 0.4)`. (Note: `PLANETS[2]` IS fixed.) |
| **Cohesion Law 1 (Band 1 value budget)** | Majority of sky in `0.00` to `0.015` linear near-black; landmarks in Band 2 (`0.03` to `0.25`) | **FAIL.** `REGION["nebula"]` (`neb = 1.0, cover = 0.72`), `world_sky.gd:361` (`1.45x` sat), `STOP_MOOD["boss"]` (`1.6x`), and `rival` (`* 1.7`) push large swaths of background sky into `0.15` to `0.80+` linear. |
| **Cohesion Law 5 Gate 4 (Anti-drift gate)** | Headless CI check blocking purple sky palettes, `star_floor != 0.0`, and star-snow regressions | **PARTIAL / MISSING FOR SKY.** `planet_v2_check.gd:342-355` checks planets and moons only; zero tests check `world_sky.gd` `REGION`/`setting`/`star_layer` or `faction_looks.json` `nebula`. |

### 3. Readability at Battle Camera Height (`r = 170`, `b = 0.98`, `fov = 45`)

- **No dark underlay in default `cine` play:** `board_look.gd:73` sets `"underlay": 0.0` (`max_4k_cost_check.gd:54` hides `_under_mi` completely until the player hits `Z` for tactical grid at `underlay = 0.45`). Everything drawn by the sky sits raw behind every ship, hex line, and weapon arc.
- **Hex grid & tactical overlays:** `line_style.gd:28` draws `grid_holo` at `Color(0.55, 0.85, 1.0, 0.2)` (additive, core only) and `board_look.gd:73` sets `hazard_edge = 0.25`. Against `nebula` blue/orange washes (`map_05_nebula_storm_default_camera.jpg`, `storm1360_wide.png`) and 10,000 bright dots, faint cyan grid edges and pale bone enemy arcs (`arc_enemy` alpha `0.42`) lose contrast.
- **Dark hulls and beams:** Under Ship Exteriors V2 (`look.gd:116`, `ambient = 0.095`), Eclipse, Sunward, Chorus, and R425 burnt hulks rely on silhouette contrast and subtle rim lighting (`rim_spec = 3.0`) to pop at `c170`. Putting bright orange/blue nebula and blurry white `lamp[k]` halos right behind the board (`world_sky.gd:210, 531`) destroys that figure-ground separation.
- **4K scaling note:** PR `#1968` (`6de14acb8`) fixed `world_sky.gd:414` to use fixed angular size `ANGULAR_PIXEL_1080` so stars do not shrink at 4K. When #1766 narrows `sig` (`px * (0.42 + 0.55 * m)`), verify at **1080p** during slow camera orbit that faint stars do not sub-pixel twinkle/alias (`sig` should not drop below `~0.50 * px` at 1080p unless temporally steady).

### 4. Cost: Bake Time, Texture Size & Format (`#1502`), and Frame Time

- **Current sky texture & VRAM:** `world.gd:556` bakes `4096x2048` (`max`/`high`) or `2048x1024` (`low`) in `DATA_FORMAT_R8G8B8A8_UNORM` (`world_bake.gd:733`), saves as 8-bit PNG (`world_bake.gd:462`), and builds full mipmaps on CPU (`world_bake.gd:446`) = **42.7 MiB VRAM + 42.7 MiB RAM** (32.0 MiB base + 10.7 MiB mips), even though `SKY` (`world_sky.gd:418`) uses `filter_linear` (no mips) to avoid the equirectangular longitude wrap seam (`0266424b6`).
- **Why `#1502` 8-bit banding persists even with `use_debanding = true` (`project.godot:46`):**
  1. `4096x2048` covers 180 deg vertically, so a 45-deg battle camera magnifies each baked texel **2.11x at 1080p** and **4.22x at 4K**.
  2. `world_sky.gd:365-366` stores gamma-2.2 encoded RGB in 8-bit with ±0.5/255 RPDF noise; bilinear filtering blurs away the texel-level dither while preserving the 6% to 15% linear steps in Band 1 dark space (`0.002..0.015`).
  3. `world_sky.gd:342-349` bakes smooth radial `lamp[k]` light falloffs directly into that 8-bit texture, creating concentric rings around embedded stars, and `world_sky.gd:488` scales decoded 8-bit values up to `1.6x` on boss stops.
- **Smart 16-bit `#1502` sizing (better look AND lower cost):**
  - `4096x2048` `RGBAH` (16-bit half-float) with mips would cost **85.3 MiB VRAM + 85.3 MiB RAM** (double current cost and heavier disk cache pressure against `CACHE_CAP_BYTES = 500 MB`, `world_bake.gd:16`).
  - **`2048x1024` `RGBAH` (linear 16-bit half-float)** costs only **16.0 MiB base (21.3 MiB with mips)**, cuts VRAM/RAM **in half** vs current 8-bit 4K, eliminates all `#1502` bake banding completely, and reduces bake pixel count **4x**! Because all crisp stars are drawn per screen pixel and the baked layer holds only smooth volumetric gas and the galactic band (`fbm3n` / `ridge3`), `2048x1024` in linear `RGBAH` is visually clean (validate on a `2048` vs `4096` `RGBAH` comparison sheet before locking).
- **Bake time:** `world_sky.gd:100` cites **3.7 to 6.1 s** per cold 4K sky rebake on RTX 5080 (and `pc-out-opus1777ft4k` logged `2,141 ms` to `14,242 ms` queued worker wall times for `4096x2048` bakes). Reducing `4096x2048` x 48 steps x 64 `rd.sync()` stalls to `2048x1024` (or keeping 4K with fewer strips) x 32 steps x 8 strips + lower `cover` early-out cuts cold sky bake time by **~4x to 6x** (`INFERRED` ~0.6 to 1.2 s on RTX 5080). Note: `world_sky.gd:100` stop-mood reuse and `world.gd:541` `PROCESS_MODE_INCREMENTAL` for `RADIANCE_SIZE_256` are already solid and should be kept.
- **Per-frame GPU time:** In `docs/shots/f4/2514693/bench.json` (1080p Max, RTX 5080), `deep_storm` and `nebula_storm` averaged `3.19` to `3.21 ms` total frame time. At 4K (4x pixels), cutting `star_layer` from 3 dense layers (24 cell checks + ~10,000 hits/view) to 2 sparse layers (16 cell checks + ~400 hits/view) and replacing `acos(dot)` with `length(sp - d)` frees real fragment shader budget at 4K with zero visual loss.

---

## Top 5 Ranked Upgrades (What Ryan Will See)

1. **Upgrade 1: Grounded Cinematic Starfield + Opaque Dust Rifts (`#1766` core)**
   - *Changes:* Cut `star_layer` to ~400 crisp pinpoint stars per 45-deg view (2 layers, rare temperature-tinted hero stars + galactic-band micro-pinpoints, steep `pow(m, 4.5)` magnitude curve, `sig` floor safe at 1080p), set default `star_floor = 0.0`, and sharpen `galaxy_band()` dark rifts (`rift` down to `0.0`) while capping core brightness inside Band 2 (`<= 0.18` linear).
   - *What Ryan will see:* The white-static "snowstorm" disappears overnight. Battles happen in calm, deep black space crossed by a crisp, realistic Milky Way dust lane with rare gleaming stars. Ships, weapon beams, comet tails, and cyan hex lines pop immediately.
2. **Upgrade 2: Deep-Space Nebula Restraint + Full Non-Purple / Non-Mustard Palette Purge**
   - *Changes:* Cut `REGION` `neb` and `cover` so 65%+ of every battle frame stays Band 1 near-black (`0.00` to `0.015`), move `feature` off the board center toward the upper horizon/corners, remove the purple-generating RGB swizzle at `world_sky.gd:188-191`, fix Eclipse (`faction_looks.json:114`) and Chorus mustard (`faction_looks.json:74`), drop `1.45x` saturation boost (`world_sky.gd:361`), and tame `STOP_MOOD` (`boss` <= 1.25x, `rival` luminance-neutral).
   - *What Ryan will see:* No more mustard-yellow soup in comet belts, no more surprise purple skies in Hegemony/Sunward/Eclipse fights, and no more loud orange/blue sky walls fighting the rose on-board nebula or blue ion storms. Every sector feels dark, vast, and distinct without cluttering the board.
3. **Upgrade 3: Linear 16-bit Half-Float Sky Bake (`#1502`) at Faster / Leaner Cost**
   - *Changes:* Switch sky bake output from 8-bit `R8G8B8A8_UNORM` PNG to linear 16-bit `R16G16B16A16_SFLOAT` (`FORMAT_RGBAH`, cached as `.exr` or float16 binary), test `2048x1024` `RGBAH` (half VRAM, 4x faster bake) vs `4096x2048` `RGBAH` on a contrast-stretched sheet, and reduce `world_bake.gd:748` from 64 tiny strips to 8 strips.
   - *What Ryan will see:* Zero concentric rings or wavy contour lines across dark space, galactic dust gradients, or sun glows even in dim deep-space sectors, plus noticeably faster cold sector loads.
4. **Upgrade 4: Kill Blurry `lamp` / `far_galaxies` Headlights and Trim `dust()` Static**
   - *Changes:* Replace the wide fuzzy `lamp[k]` circular halos (`world_sky.gd:503`) with subtle rare bright star glints moved off board center, scale down `far_galaxies` (`world_sky.gd:312`) into delicate distant smudges, and dial back `world.gd:1596` `dust()` density/brightness.
   - *What Ryan will see:* Those glaring blurry white blobs sitting behind storms and comets (like in `storm1360_wide.png` and `AC1361_comets_wide.jpg`) vanish, leaving only crisp astronomical pinpoints and real 3D props.
5. **Upgrade 5: True Dead Star Grazing-Angle Fix + Automated `sky_v2_check.gd` Anti-Drift Gate**
   - *Changes:* Delete dead `front_only` (`world_shaders.gd:70, 99-104`), fix the real `disc`/`core`/`LENS` depth seam on `deadstar_3_low`, and add a headless `godot/world/test/sky_v2_check.gd` asserting zero purple across all 30 faction-region combinations, `star_floor == 0.0`, Band-1/2 sky limits, and star thresholds (Cohesion Law 5 Gate 4).
   - *What Ryan will see:* The Dead Star black hole wraps cleanly without a horizontal slice even when tilting the camera low, and future changes can never silently sneak purple skies or star snow back into the game.

---

## One Recommended Next Step

Update Issue `#1766` (and coordinate `#1502` into the same branch) with the four corrections above (calm Band-1 sky framing away from board center, `world_sky.gd:188-191` purple-swizzle fix, real `disc`/`core`/`LENS` Dead Star grazing fix instead of dead `front_only`, and linear `RGBAH` sky bake at `2048x1024` vs `4096x2048`), add `sky_v2_check.gd`, and once CI + `independent-audit` are green (RULEBOOK 3.12, 3.13), run one before/after PC sheet across `frontier_belt`, `nebula_crystal_belt`, `nebula_storm`, `world_planet`, `deep_storm`, and `deadstar_3_low` (plus x12 contrast banding proof for `#1502`) for Ryan's sign-off.

---

## Files Read (Protocol Receipts at Commit `3629e7331`)

| File | Total lines | Ranges read | First 40 chars of last line |
|---|---:|---|---|
| `godot/world/world_sky.gd` | 547 | 1-547 (full) | `\treturn out` |
| `godot/world/world.gd` | 1633 | 1-800, 801-1600, 1601-1633 (full) | `\tif _living != null: _living.use_ship_de` |
| `godot/world/world_bake.gd` | 831 | 1-800, 801-831 (full) | `\treturn true` |
| `godot/world/world_shaders.gd` | 365 | 1-365 (full) | `"""` |
| `godot/fx/faction_looks.json` | 118 | 1-118 (full) | `}` |
| `godot/world/board_look.gd` | 74 | 1-74 (full) | `\treturn {"plate": true, "underlay": 1.0,` |
| `godot/render/look.gd` | 503 | 1-503 (full) | `\treturn m` |
| `godot/render/line_style.gd` | 211 | 1-211 (full) | `\t\tst.add_vertex(v[0])` |
| `godot/render/camera_rig.gd` | 354 | 1-354 (full) | `\treturn p` |
| `godot/world/world_rocks.gd` | 610 | 1-610 (full) | `\t\t\t(entry["decal"] as Decal).transform =` |
| `godot/world/world_planet.gd` | 1031 | 1-800 (bytes 0-46080), 739-1031 (full) | `"""` |
| `godot/world/ion_storm.gd` | 130 | 1-130 (full) | `"""` |
| `godot/world/world_living.gd` | 1707 | 1-800, 1528-1544 (`_well`) | `\t\tif c != null: m.set_shader_parameter(p` |
| `godot/scenes/battle/battle.gd` | 8176 | 310-460, 870-960 | not read to EOF (targeted sky/world slices only) |
| `godot/render/board.gd` | 1485 | 1-90, 230-420, 500-600 | not read to EOF (targeted grid/fill slices only) |
| `godot/project.godot` | 80 | 1-80 (full) | `}` |
| `godot/world/test/planet_v2_check.gd` | 504 | 1-504 (full) | `\tquit(0 if failures == 0 else 1)` |
| `godot/world/test/stop_sky_check.gd` | 128 | 1-128 (full) | `\tquit(1 if fails > 0 else 0)` |
| `godot/world/test/max_4k_cost_check.gd` | 72 | 1-72 (full) | `\tquit(1 if failures else 0)` |
| `godot/world/test/bake_cache_cap_check.gd` | 121 | 1-121 (full) | `\tquit(1 if failures else 0)` |
| `godot/world/test/backdrop_clip_check.gd` | 149 | 1-149 (full) | `\tquit(1 if failures else 0)` |
| `godot/world/world_shots.gd` | 507 | 1-507 (full) | `\tprint("[world_shots] ", p)` |
| `godot/world/sky_sheet_shots.gd` | 192 | 1-192 (full) | `\tquit(0)` |
| `docs/RULEBOOK.md` | 737 | 1-737 (full, two byte slices) | `draws meshes at full detail. Set: Ryan, ` |
| `docs/REVIEW_PROTOCOL.md` | 35 | 1-35 (full) | `- Claude checks every claim against the ` |
| `contrib/opus/plans/world_consistency_v2.md` | 171 | 1-171 (full) | ``5. **Palette rule trap:** Grep `world_sk`` |
| `contrib/opus/plans/global_cohesion_standard.md` | 186 | 1-186 (full) | `` (empty trailing line) |

Existing pictures visually inspected:
- `docs/shots/audit_2026_11/map_01_battle_scene_20_ships_wide.jpg`
- `docs/shots/audit_2026_11/map_05_nebula_storm_default_camera.jpg`
- `docs/shots/audit_2026_11/map_09_backdrops_sheet_a.jpg`
- `docs/shots/audit_2026_11/map_10_backdrops_sheet_b.jpg`
- `docs/shots/1361/AC1361_comets_wide.jpg`
- `docs/shots/issue-1765/PV2_backdrop_1.jpg` and `PV2_backdrop_2.jpg`
- `docs/shots/terrain_fx_2/deadstar.jpg`
- `docs/shots/f4/2514693/deadstar_low_and_close.jpg`, `nebula_crystal_belt_before_after.jpg`, `deep_storm_before_after.jpg`, `world_planet_before_after.jpg`
- `rcbailey12/voidsworn-relay` (`pc-out-neon2035gas3`: `out_20261124_222947_30/out_new/gas2035_nebula_c170_calm.png`)
- `rcbailey12/voidsworn-relay` (`pc-out-opus1360storm2`: `out_20261124_202241_9547/out_new/after_c170/still_200_wide.png`)

---

## Not checked:

- Live GPU execution, fresh screenshots, or solo RTX 5080 1080p/4K frame-time measurements (read-only audit per brief; no Godot or GPU capture run).
- Contrast-stretched x12 PNG banding pairs from `#1460` / `#1502` (`DEBAND_runB_png_compare.png` lived in Board local `/mnt/project-files/board/1460/` and older `board/pc-out-1460*` branches not fetched in this worktree).
- Live `deadstar_3_low` capture on commit `3629e7331` itself (inspected `map_09_backdrops_sheet_a.jpg` from `70e87f234`, `deadstar_low_and_close.jpg` from `2514693`, and `terrain_fx_2/deadstar.jpg` from `7d4db9de7`, plus `world.gd` and `world_shaders.gd` code on `3629e7331`).
- `gl_compatibility` raster fallback (`world_bake.gd:777-825`) runtime visuals or 3D LUT color grading (`godot/assets/luts/*.png`, currently opt-in behind `VS_BATTLE_LUT=1`).
- Campaign sector map sky (`godot/ui/campaign/map3d*.gd`), title screen backdrop (`godot/main/title.gd`), and full bodies of `battle.gd` (lines outside 310-460 and 870-960) and `board.gd` (lines outside 1-90, 230-420, 500-600).
