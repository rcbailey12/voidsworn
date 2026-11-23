# World & Backdrop Consistency V2 (Tracker #1764)

**Owner rulings captured (Ryan, Nov 22 2026):**
- **Planets (#1765, coordinated with #1463):** Option A (wire 8K `R01` board planet, upgrade all 5 foreground board planet types, and lift the 4 weak backdrop planet archetypes plus moons to match the A-tier ringed gas giants).
- **Asteroids & Crystals (#1361):** Option A (fix all 3 shader/shape bugs breaking the 5 biomes, retire/replace weak `scan_06` and flat boomerang `scan_07`, and replace the 216-tri flat cyan `crystal_00..02.glb` spikes with faceted Blender multi-crystal clusters).
- **Sky, Starfield & Dead Star (#1766, coordinated with #1502 and #1328):** Option A (**Grounded Cinematic Space**, The Expanse / Homeworld balance: cut star count by ~85% so deep near-black space replaces uniform starfield snow, concentrate faint stars along a tilted Milky Way band carved by opaque dark dust rifts at `star_floor = 0.0`, kill `nebula_crystal_belt` mustard fog and Eclipse purple nebula per RULEBOOK 10.9, and soften the Dead Star grazing-angle equator disc seam).
- **Stations, Hulks & Wreckage (#1767, coordinated with #1362 and R416 #1741/#1743):** Option A (retire chalky `O1_37` onto `station_T2` across cluster sizes and teaching battles, add `rig`/`ring`/`spire` biome station hooks, add Chorus and Glasswright hulls to `_hulk()`, and align `#1362` debris hex scraps to R416 lit authored interior cut-faces).

**Binding rules respected:** RULEBOOK 3.12 (no GPU capture before green checks and review), 3.13 (`independent-audit` before merge), 10.1 (cinematic scene, not a board game), 10.2 (rock scale discipline), 10.3 (planets from real data, remixed past recognition), 10.4 (hulls stay crisp inside gas), 10.5 (ship-derived wreckage), 10.7 (`station_T2` detail bar), 10.9 (hydrogen rose nebula, zero indigo-to-purple gradients), 12.1 (update look-pinning checks in the same PR), and R416 (cohesive faction materials across damage, interiors, and wreckage).

---

## 0. Why This Pass Matters

An independent visual, shader, and binary mesh audit across all battle boards, planets, asteroids, crystal clusters, skies, nebulas, storms, the Dead Star, stations, wreckage, and the campaign map on `origin/main` found that the game already contains A-tier centerpieces (`PLANETS[0]` and `PLANETS[7]` ringed gas giants, the `max`-quality Dead Star, `station_T2`, `scan_00..05` photogrammetry boulders, and 39.7 MB of 8K NASA `R01` rocky maps) sitting immediately beside D-tier outliers and silent wiring bugs:

1. **Foreground board planet** fills half the screen as a blurry clay sphere because `R01` is never called and `board.gd` still uses the tiny campaign-map icon shader.
2. **All 5 asteroid biomes** look nearly identical dull grey/tan rock because a crushed `COLOR_0.b` vertex channel on the scans disables iron metal, ice frost, and crystal veins, a blanket warm-tan tint overwrites iron and carbon, and `names_for()` ignores biome shapes.
3. **The background sky** generates ~85,000 stars (~6,800 to 11,600 bright 2px dots inside a single 45-degree battle camera frame), turning deep space into uniform white TV static that is 30x to 50x denser than real space and fights tactical ship/arc readability.
4. **Stations, hulks, backdrop planets, and skies** suffer sharp quality drops between biomes (`O1_37` vs `station_T2`, purple gas giant `PLANETS[2]`, soupy Terran/Ice worlds, mustard fog, Eclipse purple nebula, missing Chorus/Glasswright hulks, and a hard horizontal seam across the Dead Star at low camera angles).

Fixing these together brings every region, biome, and battle board up to one consistent cinematic quality bar.

---

## 1. Planets V2 (#1765, coordinated with #1463)

### 1.1 Foreground Board Planet (`godot/render/board.gd:28-34, 1064-1126`)
- **Current defect:**
  - `_planet()` still instantiates `res://ui/campaign/map3d_shaders.gd` (`MS.PLANET`, lines 179 to 238), which has **zero normal map, zero bump mapping, zero crater rim relief, and no cloud layer for rocky worlds** (just 6-octave flat value noise).
  - `godot/world/rocks/r01/` contains 39.7 MB of authored 8K NASA LROC WAC + LRO LOLA maps (`8192x4096` albedo, 11-bit height relief, roughness, drifting cloud layer with drop shadows), yet `PL.install_rocky()` in `godot/world/world_planet.gd:23-65` has **zero callers** anywhere in `godot/` (`tools/pc/jobs/planet369_board.patch` was never merged).
  - Even `planet369_board.patch` only hooks `look[0] == 0`, leaving the other 4 foreground `PLANET_LOOKS` (`kind` 1 terran, 3 ice, 4 lava, 5 barren) on the blurry campaign-icon shader.
- **Required fix:**
  1. Wire `PL.install_rocky()` into `board.gd:_planet()` for rocky and barren foreground board planets (with seeded rotation and mineral province tint remixing per RULEBOOK 10.3 so no two worlds repeat visibly).
  2. Refine `R01`'s `ROCKY_CLOUDS` layer (`world_planet.gd`) so wide camera views show finer wispy cyclonic cloud bands instead of broad soft diagonal streaks.
  3. Move all 5 foreground `PLANET_LOOKS` (`rocky`, `terran`, `ice`, `volcanic/lava`, `barren`) off `map3d_shaders.gd` onto `world_planet.gd`'s high-relief pipeline (using 4K/8K baked or remixed `R01` relief + normal perturbation + crisp limb atmosphere + cloud shadows where atmospheric). Never expose longitude UV seams (`atan` wrap discontinuity) or pole pinching.

### 1.2 Backdrop Planets & Moons (`godot/world/world_sky.gd:43-68`, `godot/world/world_planet.gd:227-326`, `godot/world/world_bake.gd:11`)
Use `PLANETS[0]` (amber ringed gas giant) and `PLANETS[7]` (teal ringed gas giant) as the A-tier visual benchmark and lift the 4 weak planet archetypes plus moons to match:

| Planet Index / Kind | Current Defect | Target Upgrade |
| :--- | :--- | :--- |
| `PLANETS[2]` (`kind == 0`, purple gas giant) | Cartoon purple-lavender stripes clashing with grounded sci-fi palette and RULEBOOK 10.9 | Re-palette to grounded dusty bronze/slate-ochre or dark storm-teal/cream (zero indigo-to-purple); check `PLANETS_ALT[2]` for clean non-purple contrast too |
| `PLANETS[3]` (`kind == 2`, Terran) | Near-black ocean blobs (`0.008, 0.03, 0.07`), blurry low-frequency continents, flat soupy clouds (`world_planet.gd:257-287`) | Add shallow continental-shelf bathymetry transitions, crisper mountain-ridge high-frequency relief, stronger normal shading along terminator, wispy multi-scale cyclonic clouds casting subtle ground shadows, and crisp ocean sun glint |
| `PLANETS[6]` (`kind == 5`, Ice world) | Smooth dull grey billiard ball (`world_planet.gd:305-316`), weak fracture contrast and flat lighting | Build high-contrast Europa/Enceladus-style tectonic ice crust: bright glacial plains cut by deep mineral-rust/cobalt lineae fractures, crisp normal bump along ridges, and clear icy specular glint along the lit limb |
| `PLANETS[5]` (`kind == 4`, Barren) & Moons (`MOON_SIZE = 1024x512`) | Flat low-contrast procedural grey craters (`world_planet.gd:299-304`); all moons share one 1024x512 uniform grey bake | Drive barren worlds and moons from remixed/rotated real relief data (`R01` height/roughness channel slices per RULEBOOK 10.3) or higher-contrast 2K/4K crisp crater relief with sharp terminator shadowing and per-moon mineral tinting (rust regolith, pale ice moon, dark basalt moon) |

---

## 2. Asteroids & Crystal Clusters V2 (#1361)

### 2.1 Binary Mesh & Vertex-Color Proof (`godot/world/rocks/*.glb`)
Direct binary `.glb` inspection of all 33 rock files revealed the exact causes behind the visual breakdown:

| Group | Files | Triangles | `COLOR_0.b` (`facet`) Mean / Range | Visual Issue |
| :--- | :--- | :--- | :--- | :--- |
| High-detail scans | `scan_00` to `scan_05` | 59,066 to 109,114 | **Mean 0.09 to 0.23, range 0.16 to 0.27** | Great silhouettes, but crushed `vC.b` disables metal, ice, and crystal shader branches |
| Weak scans | `scan_06`, `scan_07` | 14,844 / 12,416 | **Flat 0.70 / 0.49, range 0.04 to 0.05** | 6x to 9x lower detail; `scan_07` (`ext: [0.97, 0.43, 1.90]`) is a flat boomerang pancake |
| Procedural fallbacks | `frag`, `rubble`, `binary`, `slab`, `shard` | 20,480 | Mean 0.50 to 0.81, range 1.00 | Puffy smooth "baked potato" silhouettes when scans are disabled |
| Crystal clusters | `crystal_00` to `crystal_02` | **216 to 240** (no `_lo` LOD) | N/A | Flat low-poly cyan plastic spikes glued onto 90K-tri boulders |

### 2.2 Required Fixes (Folded into #1361)
1. **Fix `facet` (`COLOR_0.b`) on photogrammetry scans (`world_rocks.gd:188-223`):**
   - Either re-bake normalized convex ridge/edge curvature (`0.0..1.0` full dynamic range per scan) into `COLOR_0.b` on `scan_00..05` (preferred, deterministic and zero shader cost) OR normalize `vC.b` per mesh / combine with world-space triplanar ridge noise inside `ROCK_SHADER` so `fr` spans `0.0..1.0` cleanly on every scanned asteroid.
2. **Fix biome color and material separation (`world_rocks.gd:196-238`):**
   - Remove the blanket warm-tan tint `if (kind != 3 && kind != 4) { a *= vec3(1.12, 1.0, 0.84); }` at line 227 from `iron` (`kind == 1`) and `carbon` (`kind == 2`).
   - Lock unmistakable silhouettes and PBR separation across all 5 biomes at both camera-170 and close-up (`c26`):
     - **`stone` (`kind == 0`):** Warm ochre/sandstone silicate rock with dark dust pockets, crisp fissures, and rock-to-rock tone jitter.
     - **`iron` (`kind == 1`):** Cool dark gunmetal/slag exterior with bright metallic nickel-iron specular facets (`METALLIC` 0.65 to 0.90 on fresh fractured ridges) catching the system sun cleanly.
     - **`carbon` (`kind == 2`):** Deep charcoal/basalt carbonaceous rock (very low albedo, matte `ROUGHNESS` 0.92+, dusty dark pockets, subtle ash-grey ridge highlights; never tan).
     - **`ice` (`kind == 3`):** Dark comet-crust hollows contrasted with crisp pale frost/glacial shelves (`ROUGHNESS` 0.35 to 0.45 on clean exposed ice, subtle cool cyan subsurface/rim bounce, never plastic).
     - **`crystal` (`kind == 4`):** Dark slate/obsidian host rock laced with crisp glowing mineral crystal veins seated inside fractured crevices (`smoothstep` calibrated to actual scan `fr` distribution so veins read cleanly without covering the whole rock).
   - Keep per-instance rock-to-rock tone/hue variance and normal-bias crevice shadow-acne fix already scoped on `#1361`.
3. **Restore biome silhouette variety (`world_rocks.gd:424-426`):**
   - Do not let `names_for(kind)` return the exact same flat pool for every biome. Pair curated scan subsets, non-uniform rock-axis aspect bounds (within natural limits), and biome-specific angular shard/slab detail so an ice field feels sharper and an iron field feels heavier/blockier than a plain stone belt, without reverting to smooth procedural blobs.
4. **Retire/replace `scan_07` and weak `scan_06`:**
   - Remove flat boomerang `scan_07` from the active belt pool immediately; replace `scan_06` and `scan_07` with high-detail CC0 photogrammetry scans (50K+ tris full / clean `_lo` LOD) matching `scan_00..05` or restrict the active scan pool to the 6 crisp scans (`scan_00..05`) until replacements are packed.
5. **Replace 216-tri plastic crystal clusters (`crystal_00..02.glb`):**
   - Build 3 to 4 proper faceted multi-crystal Blender clusters (`crystal_00..03.glb` + `_lo` LODs, ~1.5K to 4K tris each): clustered hexagonal quartz/beryl crystal prisms of varied height and angle bursting out of a rough mineral host collar that blends cleanly into the host boulder, with sharp beveled edges, internal depth shading, Fresnel specular glints, and restrained core luminescence (matching grounded sci-fi aesthetics, zero Roblox/plastic flat cyan).

---

## 3. Grounded Cinematic Space Sky, Starfield & Dead Star V2 (#1766, coordinated with #1502 and #1328)

### 3.1 Starfield Snow Overhaul (`godot/world/world_sky.gd:440-480`, `godot/world/world.gd:470`)
- **Current math on `origin/main`:**
  - `world_sky.gd:479` evaluates three 3D-grid `star_layer()` calls (`scale = 120, 300, 650`; thresholds `0.955, 0.985, 0.994`), producing **~85,000 stars across the celestial sphere (~6,800 to 11,600 dots inside one 45-degree battle camera view)**.
  - Even the dimmest stars receive a `0.15` floor (`world_sky.gd:452`) and wide radius `px * (0.65 + 0.9 * m)` (`world_sky.gd:451`), and `star_floor = 0.15` (`world.gd:470`) lets stars punch straight through opaque dust lanes.
  - Result: wall-to-wall white static behind ships, hex outlines, and firing arcs.
- **Target aesthetic: Grounded Cinematic Space (The Expanse / Homeworld balance):**
  1. **Cut star density by ~85%:** Target **~250 to 500 visible pinpoint stars inside a 45-degree battle frame** (with wide, quiet pools of true near-black deep space so lit ships, planets, moons, and glowing weapon trails own the frame cleanly).
  2. **Natural galactic clustering instead of isotropic static:** Keep off-plane deep space sparse (only rare crisp hero stars and very faint distant pinpoints), and concentrate faint micro-star density cleanly along the tilted galactic band (`bd`).
  3. **True magnitude hierarchy & crisp pinpoint size:** Replace the flat `(0.15 + 2.6 * m)` floor with a steep power-law magnitude curve (`pow(m, 4.0)` to `pow(m, 5.0)`) and tighten `sig` (`px * (0.42 + 0.55 * m)` clamped cleanly against aliasing) so faint stars are delicate sub-pixel/1px pinpoints and only a sparse handful of hero stars gleam brighter with subtle realistic stellar temperature tint (blue-white O/B, crisp white A/F, warm gold G/K, rare ember M).
  4. **Opaque dark dust lanes (`star_floor = 0.0`):** Lower the default `star_floor` in `world.gd:470` and `world_sky.gd:409` from `0.15` to `0.0` (retaining `VS_STAR_FLOOR` env override for tuning sheets) so dense dark molecular dust rifts carve dramatic black silhouettes cleanly out of both the Milky Way band and background stars.
  5. **Lift galactic band & cosmic landmarks (`world_sky.gd:276-293`):** Raise `galaxy_band()` luminance from `* 0.06` to a balanced cinematic range (~`0.14` to `0.22`, tuned on real PC captures) with sharper dark-rift contrast and restrained regional nebula filaments, so real astronomical structure gives the sky depth without washing out hulls or hex lines.

### 3.2 Sky Palette Compliance (`world_sky.gd`, `godot/fx/faction_looks.json:102`)
- **`nebula_crystal_belt` mustard fog:** Adjust the region/faction gas mixing in `world_sky.gd` so crystal-belt sectors shift away from soupy yellow-mustard Perlin haze into deep dark-slate cosmic dust with subtle cold mineral cyan/amber highlights.
- **Eclipse purple nebula (`godot/fx/faction_looks.json:102`):** Replace `"nebula"` purple tint `[0.34, 0.14, 0.52]` with a RULEBOOK 10.9-compliant non-purple palette (dark ash-obsidian / ember-crimson or cold dark slate-steel, matching Eclipse's ruthless aesthetic without indigo-to-purple gradients).

### 3.3 Dead Star Low-Camera Equator Seam (`godot/world/world_shaders.gd:92-97`)
- **Current defect:** When `front_only > 0.5`, line 96 runs a hard binary cut `if (length(toFrag) > length(toHole)) { discard; }`. At grazing/low camera angles (`deadstar_3_low`), this draws a razor-sharp horizontal edge slicing straight across the black-hole sphere.
- **Required fix:** Replace the hard `discard` with a smooth depth/radial horizon transition (feathering `ALPHA` / intensity smoothly across the sphere limb radius and ensuring the inner disc edge blends naturally behind the gravitational shadow boundary), verified on both default and low (`deadstar_3_low`) camera captures.

### 3.4 Coordination with `#1502` and `#1328`
- **#1502 (16-bit sky bake):** Moving `world_bake.gd:380,408` off 8-bit `R8G8B8A8_UNORM` (`FORMAT_RGBA8`) to 16-bit half-float (`DATA_FORMAT_R16G16B16A16_SFLOAT` / `FORMAT_RGBAH`, with Compatibility fallback dither) is essential once deep dark voids and subtle galactic dust rifts replace star noise; coordinate branch order so `#1502` and `#1766` do not fight over `world_sky.gd` and `world_bake.gd`.
- **#1328 (Soft volumetric on-board clouds):** Keep on-board nebula and ion storm clouds aligned with RULEBOOK 10.9 (hydrogen rose calm nebula vs cyan/amber ion storms) and eliminate flat spiderweb lace decals (`N368`) and hard hex-footprint cutoffs as part of `#1328` / `#1360`.

---

## 4. Stations, Faction Hulks & Graveyard Wreckage V2 (#1767, coordinated with #1362 and R416)

### 4.1 Retire Old Chalky `O1_37` onto `station_T2` (`godot/assets/ships/a4_props.gd:67-106`, `godot/render/board.gd:946-980`, `godot/world/blocker_visuals.gd:70`)
- **Current defect:** `A4P.station()` restricts the detailed `station_T2.scn` strictly to `size == LARGE_STATION_SIZE` (`46.0`). All smaller clusters (`size == 34.0`), teaching battles, and blocker station props (`size == 14.0`) fall back to the bright chalk-white blocky `O1_37`. Meanwhile, `REGION_BIOME` in `godot/rules/data/tables.json` declares three distinct station classes (`rig`, `ring`, `spire`) that `board.gd:_station()` ignores.
- **Required fix:**
  1. Allow `A4P.station(size, clearance, station_kind := "")` to instantiate `station_T2.scn` cleanly scaled by `size / LARGE_STATION_SIZE` across all cluster sizes and teaching battles (preserving hex clearance and attitude fit), keeping `O1_37` solely as an offline fallback when `station_T2.scn` is absent.
  2. Update `godot/assets/ships/test/station_size_check.gd` in the same PR (per RULEBOOK 12.1) to assert clean `station_T2` scaling across both large and small clusters.
  3. Pass the biome's `station` kind (`rig`, `ring`, `spire`) from `tables.json` into `_station()` / `A4P.station()` as a clean variant hook (with subtle per-biome debris/beacon lighting accents now, ready for dedicated `rig` / `spire` Blender kits later without re-plumbing `board.gd`).

### 4.2 Add Missing Chorus and Glasswright Hulks (`godot/render/board.gd:920-929`)
- **Current defect:** `_hulk()` hardcodes only four hulls (`["H8_23", "V15_37", "C14s_23", "D20_23"]`), covering Meridian Directorate, Sunward Crusade, Ashfall Hullbreakers, and Eclipse only. Zero Chorus or Glasswright hulks ever spawn anywhere in the game.
- **Required fix:**
  1. Expand `_hulk()`'s pool to cover all 6 factions using verified installed medium/cruiser hulls from `godot/assets/ships/manifest.json`:
     - Meridian Directorate: `H8_23`
     - Sunward Crusade: `V15_37`
     - Ashfall Hullbreakers: `C14s_23`
     - Eclipse: `D20_23`
     - **The Chorus:** `B20_11` (spitter destroyer), `B21_11` (bladeback cruiser)
     - **The Glasswrights:** `I11_37` (lancet destroyer), `I15_11` (prism cruiser)
  2. Weight hulk selection toward the sector's faction and active battle factions (e.g., 70% battle/sector factions, 30% ambient frontier derelicts) so graveyards tell a coherent local story.
  3. Ensure `A4P.hulk(code)` applies faction-appropriate R416 derelict finishes (never covering Glasswright crystal or Chorus organic chitin in uniform matte charcoal soot).

### 4.3 Graveyard Debris Hexes (`#1362`, aligned with R416 `#1741` / `#1743`)
- Current `wreck_kit.py` props (`godot/world/wreckage/*.glb`, 4K to 7K tris) read as uniform flat-grey blocky trusses and cones beside detailed faction ships and photogrammetry rocks.
- When `#1362` unblocks and rebuilds debris hex scraps from the shared faction ship part kits, every scrap piece must share the **R416** faction exterior finish and Layer 1/3 interior cut-face look (`#1741`, `#1743`) so pre-placed graveyard wreckage is visually indistinguishable from combat-destroyed hulls.

---

## 5. Campaign Map (Low-Priority Polish)

`docs/shots/audit_2026_11/map_12_campaign_map.jpg` already reads strongly (striking central Hollow Sun, clean orbital rings, crisp fleet and shipyard miniatures). As an optional polish follow-up after the battle-board tracks land, widen stop-planet palette and ring variation in `godot/ui/campaign/map3d_shaders.gd` so adjacent campaign stops do not repeat identical blue striped gas spheres.

---

## 6. Execution Sequence, Verification Gates & Audit Traps

### Recommended Execution Order
1. **Wave W1 (Parallel, zero file overlap):**
   - **#1765 (Planets V2, coordinated with #1463):** `board.gd:_planet()`, `world_planet.gd`, `world_sky.gd` (`PLANETS` tables), `world_bake.gd` (moons).
   - **#1361 (Asteroids & Crystals V2):** `world_rocks.gd`, `godot/world/rocks/` scans + new Blender `crystal_00..03.glb`.
   - **#1767 (Stations & Hulks V2):** `a4_props.gd`, `board.gd:_station()/_hulk()`, `blocker_visuals.gd`, `station_size_check.gd`.
2. **Wave W2 (Coordinated on `world_sky.gd` / `world_bake.gd`):**
   - **#1766 (Grounded Cinematic Space Sky & Starfield + Dead Star seam)** sequenced cleanly with **#1502 (16-bit sky bake)** so the new dark voids, dust rifts, and galactic band render with zero 8-bit contour rings, plus **#1328 / #1360** for volumetric on-board clouds and storm bolts.
3. **Wave W3 (Post-R416 Interior Kit):**
   - **#1362 (Graveyard debris scraps from faction ship kits)** unblocked alongside `#1741` / `#1743` so wreckage and combat damage share one unified interior/exterior pipeline.

### Visual & Technical Acceptance Gates (Every Track)
- **Green CI + `independent-audit` FIRST (RULEBOOK 3.12, 3.13):** No PC GPU capture runs until Godot checks pass and an independent pre-merge audit checks every trap below.
- **Before/After PC Captures (no taller than 720 px per stamped sheet, real installed hulls):**
  - **#1765:** All 5 foreground board planet archetypes (`c170` + close-up) plus all 8 backdrop planets + moons side-by-side.
  - **#1361:** All 5 asteroid biomes (`stone`, `iron`, `carbon`, `ice`, `crystal`) on real installed scans (`c170` + `c26`), plus close-up of new faceted crystal clusters.
  - **#1766:** Full 1080p battle views (`frontier`, `nebula_crystal_belt`, `deep_storm`, `boneyard`, `deadstar` default + `deadstar_3_low`) comparing old starfield snow vs Grounded Cinematic Space, plus contrast-stretched banding verification with `#1502`.
  - **#1767:** Small cluster + teaching station + large cluster (`station_T2` vs old `O1_37`) and graveyard views showing all 6 faction hulks including Chorus and Glasswright hulls.
- **Zero Frame-Time Regression:** Solo GPU benchmark confirms no regressions on RTX 5080 (especially watching `8192x4096` `R01` sampling, starfield shader loops, and multi-crystal triangle budgets).

### Specific Silent-Regression Traps to Audit Before Merge
1. **Unwired asset trap:** Confirm `PL.install_rocky()` and any new planet/crystal/station asset is actually instantiated by live `battle.gd` / `board.gd` / `world.gd` code paths, not only by a look-bench script.
2. **Vertex-channel mismatch trap:** Verify `COLOR_0.r/g/b/a` ranges on every exported `.glb` rock scan directly against `ROCK_SHADER` thresholds (never assume Blender/scan exports match procedural generator ranges).
3. **Starfield aliasing/shimmer trap:** Verify narrowed pinpoint `sig` does not sparkle/flicker aggressively during slow camera pan or orbit on 1080p and 4K displays (clamp minimum pixel radius cleanly).
4. **Hulk chirality & material trap:** Verify Chorus (`B20_11`, `B21_11`) and Glasswright (`I11_37`, `I15_11`) hulks keep true `+Z` chirality (no negative Z mirroring) and never receive matte charcoal metal soot.
5. **Palette rule trap:** Grep `world_sky.gd` and `faction_looks.json` to ensure zero indigo-to-purple nebula/planet leaks remain (RULEBOOK 10.9).
