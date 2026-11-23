# Global Visual & Sensory Cohesion Standard (Master Tracker #1774)

**Owner directive (Ryan, Nov 22 2026):**
> "make sure we're not just doing individual patches but taking a more global approach? And then include everything we've discussed"

This document establishes **one unified visual, material, world, and audio contract** across the entire game so subsystems stop drifting in silos. Every ship exterior, ship interior, weapon effect, combat wound, destruction sequence, graveyard hulk, debris hex, station, planet, asteroid, crystal cluster, space sky, and audio cue derives from the same grounded sci-fi hierarchy and is protected by automated anti-drift gates.

**Companion specs unified under this standard:**
- **R416 Cohesive Ship-to-Destruction Pipeline:** `contrib/opus/plans/cohesive_damage_v2.md` (`#1741` Wounds V2 Layers 1+2, `#1743` / PR `#1763` Interior Kit V2 Layer 3, `#1692` weapon marks, `#1422` / `#1681` / `#1684` active rebakes).
- **R419 World & Backdrop Consistency V2:** `contrib/opus/plans/world_consistency_v2.md` (`#1764` tracker, `#1765` / `#1463` Planets V2, `#1361` Asteroids & Crystals V2, `#1766` / `#1502` / `#1328` Grounded Cinematic Space Sky & Dead Star Seam, `#1767` / `#1362` Stations, Hulks & R416 Wreckage).
- **Cohesive Dark Sci-Fi Audio V2:** `contrib/opus/plans/cohesive_audio_v2.md` (`#1752`, PR `#1753`, Ryan picks locked `1=A, 2=A, 3=A`, 72 items / 138 files, Wave A first after `main` merge confirmation).

---

## 1. Why Silo Patches Kept Breaking Cohesion

Independent audits across the entire game exposed **one repeating structural failure** across every visual and audio pipeline:

1. **No shared value / luminance budget:** Grounded dark-space hulls sit at `0.04` to `0.15` linear albedo, yet Directorate interiors jumped to matte pale clay (`0.175` linear, `metal 0.2`, `var 0.05`, 2.5x to 6x brighter than every other metal faction), old `O1_37` stations stayed chalk-white, and `world_sky.gd` painted ~85,000 bright 2px stars (~6,800 to 11,600 per frame) behind the fleet.
2. **Schematic blockout colors leaked into final renders:** `tools/blender/build_sheets/kit.py` lines 54 to 105 carry early CAD/diagram room colors (`engroom` orange, `magazine` red, `hangar` blue, `crew` green, `bridge` yellow, Eclipse `archive` teal-green, Chorus `vat` neon lime emitting `2.0`, `gland` acid yellow-green emitting `0.6`, `brood` bright yellow). PR `#1763` raised `INSIDE_TINT` from `0.18` to `0.55` and passed Chorus schematic colors and full-surface emissions straight into final V2 materials, turning Chorus organs into neon green/yellow lightbulbs, binding bone hoops (`bonefr`) to wet glowing flesh trim, leaking teal-green `archive` tint into Eclipse, and tinting metal rooms like a color-coded cutaway diagram.
3. **Unenforced hue / palette rules:** RULEBOOK 10.9 banned indigo-to-purple gradients on battle nebulas, yet `PLANETS[2]` stayed a cartoon purple gas giant, Eclipse kept purple `[0.34, 0.14, 0.52]` in `godot/fx/faction_looks.json:102`, `nebula_crystal_belt` turned yellow-mustard soup, and Chorus interiors turned neon lime.
4. **Asset fidelity mismatches & silent wiring gaps:** 39.7 MB of 8K NASA `R01` rocky planet maps sat completely unwired in git while `board.gd` rendered a blurry campaign-icon sphere; crushed `COLOR_0.b` (`facet`) channels on `scan_00..05` plus a blanket warm-tan tint collapsed all 5 asteroid biomes to identical tan stone; 216-tri flat cyan crystal spikes sat on 90K-tri boulders; `station_T2` was gated strictly to `size == 46.0` leaving chalky `O1_37` on smaller clusters; `board.gd:_hulk()` skipped Chorus and Glasswrights completely; and old `wreck_kit.py` trusses clashed against detailed hulls.
5. **Isolated review views:** Interiors were tuned in Blender without `#1741`'s dynamic breach cavity lights (`s._hole_lights`), skies were tuned without judging full-frame 1080p ship readability, and Gate 1 audio prompts were written without checking Godot's per-muzzle trigger loop.

**Rule going forward:** No subsystem is tuned or patched in isolation. Every change must satisfy the five global laws below and pass the automated anti-drift gates in Section 6.

---

## 2. Law 1: Global Value & Luminance Hierarchy

Every visual element in a battle frame belongs to one strict luminance band so silhouettes, depth, and tactical clarity never fight each other:

| Band | Target Linear Albedo / Luminance | Role & Hard Rules |
| :--- | :--- | :--- |
| **1. Deep Space Void** | 0.00 to 0.015 (near-black) | Majority of the sky frame (`#1766`, RULEBOOK 10.11). Calm dark negative space so ships, hex lines, and weapon fire read effortlessly. |
| **2. Cosmic Landmarks & Backdrop Planets** | 0.03 to 0.25 (terminator shadow near 0) | Milky Way band carved by opaque dust rifts (`star_floor = 0.0`), restrained non-purple/non-mustard regional nebula, 16-bit band-free bake (`#1502`), realistic planets and moons matching A-tier ringed gas giants (`#1765`). |
| **3. Lit Outer Hulls, Stations & Asteroids** | 0.04 to 0.30 linear base (15 to 55% shaded lit faces) | Physically grounded PBR armor, `station_T2` across all sizes (`#1767`), distinct 5-biome asteroids and faceted multi-crystal clusters (`#1361`), 6-faction hulks & ship-kit debris (`#1767`, `#1362`); hulks at 0.04 to 0.045, except Chorus hulks at about 0.025 (R423, Ryan Nov 23). |
| **4. Shadowed Ship Interiors & Wreckage Cavities** | **Strictly darker than lit outer armor: 0.03 to 0.10 linear mean max** (bone/glass structural trim exempted up to 0.18 matte/refractive) | Broken-open compartments sit in deep vacuum shadow, NEVER stark matte chalk-white (`0.175`) and NEVER rainbow diagram colors. Mood and readability come from modeled ribs/machinery, crisp normal/AO relief, thin recessed accent light strips, and `#1741` Layer 1 dynamic breach cavity lights. |
| **5. Emissives, Weapons, Cores & Breach Arcs** | Reserved HDR top band (localized only) | Muzzle flashes, beams, projectiles, reactor cores, engine throats, shield flares, and tiny recessed interior light strips or gland pores. **Never** full-surface glowing organs (`vat 2.0`), full-wall neon, or wall-to-wall starfield static. |

---

## 3. Law 2: Global Fix for Modeled Ship Interiors (PR #1763 / #1743 + #1741)

Instead of patching individual faction colors after each cutaway review, PR `#1763` (`#1743`) must enforce one global material architecture across **all 6 factions**:

1. **Decouple `inside_material()` from `kit.py` schematic blockout colors completely:**
   - `kit.py` lines 54 to 105 (`engroom`, `magazine`, `machinery`, `hangar`, `crew`, `bridge`, `archive`, `organ`, `gut`, `gland`, `brood`, `vat`, `ganglion`, `septum`, `bonefr`) are **semantic role tags ONLY**.
   - `inside_material(room, trim=True)` in EVERY faction `stack.py` MUST ignore `kit.py`'s schematic `Base Color` and non-core `Emission Strength`. Instead, map each room/part role through that faction's **authored interior role table** (`wall`, `deck`, `frame`, `machinery`, `core`, `organ`, `bone`, `gland`, `glass_strut`).
   - Room differentiation comes from **modeled architecture** (`interior_kit.py`), **roughness/metal/panel variation**, **subtle micro-tint (`<= 15%` shift within the faction's own grounded palette)**, and **localized accent lights**, NEVER from orange/red/blue/green/yellow CAD color-coding.
2. **Strict Structural-vs-Surface Separation:**
   - Structural frames (`bonefr`, `frame`, `truss`, `bulkhead`, `deck`) MUST take structural finishes (dry weathered bone on Chorus, dark brushed alloy on metal factions, faceted clear/tinted struts on Glasswrights). Never apply wet glowing flesh trim to Chorus bone hoops/struts.
3. **Coordinated Six-Faction Interior Calibration (Jointly with `#1741` Layer 1 Breach Lights):**
   - **Sunward Crusade (`voidsworn`):** Dark forged-iron bulkheads (`~0.045 to 0.065` linear, `metal 0.35..0.5`), subtle ash/carbon panel contrast, restrained warm ember recessed strips (`strength <= 1.5`), hot reactor core slits only.
   - **Meridian Directorate (`hegemony`):** **Cool brushed clinical steel-slate (`~0.075 to 0.095` linear, `metal 0.45`, `var 0.10`, low grime `0.10`)**: noticeably cleaner, cooler, and slightly lighter than Sunward/Hullbreakers without ever looking like stark chalky white clay (`0.175` matte is retired). Crisp cold-blue emergency strips carry the sterile Directorate identity.
   - **Ashfall Hullbreakers (`corsair`):** Dark oil-stained scavenged steel (`~0.045 to 0.065` linear, mismatched plates, rust/soot pockets unique to Hullbreakers), sparse dim red-orange cage lamps (`strength <= 1.1`).
   - **The Chorus (`chorus`):** Deep wet dark crimson-umber / bruised mahogany organic cavity tissue (`~0.035 to 0.075` linear, wet roughness `0.24..0.46`, zero metal, zero magenta, **zero bright yellow `flesh_tone`/`brood` and zero neon lime `vat`/`gland` full-surface glow**). `bonefr` hoops and cross-struts use **dry weathered muted ochre-ivory bone** (`~0.14 to 0.18` linear, roughness `0.60..0.72`, zero glow). Any bioluminescent bile accent stays strictly tiny, deep, and muted (dim olive-amber capillary pores inside gland/vat recesses only, `strength <= 0.25`, `share <= 0.08`).
   - **The Glasswrights (`ithar`):** Deep translucent-reading annealed seafoam/smoky-amber faceted crystal bulkheads (`~0.05 to 0.10` linear, low roughness `0.08..0.28`, zero metal, zero soot, zero grime), subtle seafoam edge-refraction highlights (`strength <= 0.6`), luminous crystal prism core nodes only.
   - **Eclipse (`deathless`):** Deep obsidian-violet monolithic vaults (`~0.025 to 0.045` linear, satin dark alloy/obsidian `rough 0.28..0.55`, **zero green from `archive` or `ecore`**, zero rust), hairline violet-white power bus rails (`faction_looks.json` `death.fire`, `strength <= 1.6`).
4. **Merge Order Guard (Artoo finding on PR `#1763`):** Resolve and land `#1724`'s `export7.py` map-size reporting fix cleanly before merging `#1763`, so reference rebakes report true pixel dimensions.

---

## 4. Law 3: Single Six-Faction Identity Matrix (All 7 Pipelines Locked Together)

Every faction must read as **one cohesive species/culture** across all 7 pipelines (zero cross-contamination):

| Faction | Exterior & Interior (R416 `#1743`) | Weapons & Firing FX (`#1692`, `#1741`) | Combat Wounds & Cavity Lights (`#1741`) | Capability Loss & Destruction (`#1741`) | Graveyard Hulks & Debris (`#1767`, `#1362`) | Sci-Fi Audio V2 (`#1752` / PR `#1753`, Picks `A/A/A`) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Sunward Crusade (`voidsworn`)** | Forged dark iron + brass; ember-lit iron decks | Heavy forged-iron kinetic/propellant shell cannons, lances, torpedoes | Bent steel ribs, burning amber slag, soot & spark plumes | Jammed slot casemates/turrets, failing ember drive nozzles, ember core split | `V15_37` hulks + iron-kit burnt debris with R416 interior cuts | **1=A:** Forged-iron propellant shell crack + low thump; weathered low brass & cellos |
| **Meridian Directorate (`hegemony`)** | Slate-navy alloy; cool brushed steel-slate interiors + blue strips | Tight regulated plasma cannons, flak, turbo batteries | Clean sheared alloy, blue-white plasma arc burn, zero orange soot | Jammed precision turrets, vented blue thruster plumes, clean snapped hull segments | `H8_23` hulks + clean-sheared Directorate kit debris | Tight capacitor-bank plasma thump + clean cutoff; taut cold strings & pulse |
| **Ashfall Hullbreakers (`corsair`)** | Welded scrap steel; dark soot/rust scavenged interiors + red lamps | Rattling autocannons, junk guns, brutal salvos | Torn jagged scrap plates, dark oil smoke, glowing rust/char | Spluttering rough drive bells, jammed scrap mounts, violent shrapnel breakup | `C14s_23` hulks + jagged scorched scrap-kit debris | Heavy rattling mechanical cannon & industrial junk bark; gritty bowed metal & scrap percussion |
| **The Chorus (`chorus`)** | Pale horn/chitin over wet umber hide; deep wet crimson-umber organs + dry ochre bone ribs | Pressurized bio-acid sacs (`sporeb`), spine volleys, organic lances | Torn dark wet tissue, snapped bone ribs, dim oozing olive-amber ichor (zero soot, zero magenta) | Ruptured brood/spine glands, failing organic thruster vents, visceral split | **`B20_11`, `B21_11` hulks** (`#1767`) + non-soot bio/chitin R416 debris | Wet pressurized bio-thump & viscous sac burst (zero balloon/metal); low contrabassoon & bone harmonics |
| **The Glasswrights (`ithar`)** | Annealed seafoam/amber glass + lattice; clean faceted glass interiors | Harmonic shard volleys, needle beams, focused prism lenses | Crisp fractured crystal planes, escaping seafoam light, zero soot/fire/smoke | Shattered lens emitters, dimmed resonant drive lattice, crystalline shatter | **`I11_37`, `I15_11` hulks** (`#1767`) + clean fractured crystal debris | Crisp harmonic glass crack & resonant crystalline beam; glass harmonica & ethereal strings |
| **Eclipse (`deathless`)** | Obsidian-violet monoliths; dark obsidian vaults + violet-white bus rails (zero green) | Heavy magnetic null cannons, Corona arc (`doom`), sentry arrays | Fractured obsidian plates, sharp violet-white electrical arcs (zero fire/soot/green) | Deadened null emitters, collapsing violet field vents, silent brittle shard breakup | `D20_23` hulks + obsidian-truss R416 debris (zero purple sky wash) | **2=A:** Heavy magnetic slam + cold hollow void decay; glacial sub-brass & obsidian chimes |

---

## 5. Law 4: World, Planets, Asteroids, Sky & Audio Integration

All world and audio tracks operate under the exact same cohesion rules (full line-level specs in `contrib/opus/plans/world_consistency_v2.md` and `contrib/opus/plans/cohesive_audio_v2.md`):

1. **Planets V2 (`#1765`, coordinated with `#1463`):**
   - Wire the unwired 39.7 MB 8K NASA `R01` rocky maps into `board.gd:_planet()` AND upgrade all 5 foreground `PLANET_LOOKS` off `map3d_shaders.gd`.
   - Re-palette cartoon purple `PLANETS[2]` (RULEBOOK 10.9), sharpen Terran (`PLANETS[3]`), Ice (`PLANETS[6]`), Barren (`PLANETS[5]` using remixed `R01` relief per RULEBOOK 10.3), and moons to match A-tier ringed gas giants (`PLANETS[0]`, `PLANETS[7]`).
2. **Asteroids & Crystals V2 (`#1361`):**
   - Fix crushed `COLOR_0.b` (`facet`) on `scan_00..05` so iron metal, ice frost, and crystal veins work on photogrammetry rocks.
   - Remove the blanket warm-tan tint (`world_rocks.gd:227`) from iron and carbon; restore biome shape variety in `names_for()`; retire flat boomerang `scan_07` and weak `scan_06`; replace 216-tri flat cyan `crystal_00..02.glb` spikes with faceted Blender multi-crystal clusters + `_lo` LODs.
3. **Grounded Cinematic Space Sky & Dead Star (`#1766`, coordinated with `#1502` and `#1328`, RULEBOOK 10.11):**
   - Cut starfield density by ~85% (~6,800 to 11,600 static dots/frame -> ~250 to 500 crisp pinpoint stars/frame clustered along a richer tilted Milky Way band), drop `star_floor` to `0.0` so dark molecular dust lanes carve real black voids, bake skies in 16-bit half-float (`#1502`), remove `nebula_crystal_belt` mustard fog and Eclipse purple nebula (`faction_looks.json:102`), soften the Dead Star grazing equator seam (`world_shaders.gd:96`), and finish soft volumetric on-board clouds (`#1328` / `#1360`).
4. **Stations, Hulks & Graveyard Wreckage (`#1767`, coordinated with `#1362`):**
   - Retire chalky `O1_37` onto cleanly scaled `station_T2` across all cluster sizes and teaching battles; wire `rig`/`ring`/`spire` biome hooks; expand `board.gd:_hulk()` to all 6 factions (adding Chorus `B20_11`/`B21_11` and Glasswright `I11_37`/`I15_11`); align `#1362` graveyard debris scraps with R416 lit interior cut-faces.
5. **Cohesive Dark Sci-Fi Audio V2 (`#1752`, PR `#1753`):**
   - Wait for PR `#1753` (72 items / 138 files, merge conflict resolved cleanly on `opus/issue-1752`) to merge and verify `main` holds the 72-item manifest before any spend.
   - Ryan's three picks are locked (`1=A` Sunward shell guns, `2=A` Eclipse heavy magnetic slam + cold hollow decay, `3=A` Gate 1 `reward_preview` wording on 16 whole bars).
   - Run Wave A (14 diagnostic items, `--max-credits 1200`) and ear-check on the corrected `listen_page.js` before Wave B (~4,300 real credits total).

---

## 6. Law 5: Automated Anti-Drift CI Gates (Stopping Regressions Forever)

No visual rule stays intact if it relies on human memory alone. Add these automated checks directly into the existing pipelines:

### 6.1 Blender Export & Material Gates (`tools/recipe/check_export.py` + `cutaway.py`)
1. **No Schematic Blockout Color Leak:** Fail export or test if any V2 interior material inherits unmapped `kit.py` schematic room hues/emissions (e.g., `vat 2.0`, `gland 0.6`, `archive` green on Eclipse, red `magazine`, blue `hangar`).
2. **Interior Albedo Ceiling Gate:** Compute mean linear base albedo of every non-bone, non-glass interior material; fail if `> 0.11` linear (automatically blocks chalky white `0.175` clay corridors from ever slipping back in).
3. **Interior Non-Core Emission Gate:** Fail if any non-core interior surface (outside `core` / `ecore` reactor slits) has full-surface constant emission `> 0.0` or area-weighted trim emission `> 0.25` (automatically blocks glowing neon-green Chorus organs).
4. **Faction Palette & Role Guard:**
   - Assert Chorus `bonefr` never binds to `style='flesh'` or any glowing vein emission.
   - Assert Chorus has zero metal (`metallic == 0.0`) and zero magenta/neon-lime saturation spikes.
   - Assert Glasswrights have zero soot/wear/metal.
   - Assert Eclipse has zero green (`g > r * 1.15 and g > b * 1.15` banned on both albedo and emission).
5. **Lossless Normal & ORM Map Gate (`#1778`):** Fail any ship export carrying lossy `.jpg` normal or ORM maps (lossless `.png` / BC5 only; fixes JPEG 8x8 plastic-smudge normals like `C19_51_normal.jpg` and `D21_23_normal.jpg`).
6. **Unified 6-Faction Lineup Review Sheet (`cutaway.py`):** Render one side-by-side 6-faction strip at identical exposure (showing exterior hull + cut-open interior for Sunward, Directorate, Hullbreakers, Chorus, Glasswrights, Eclipse together) AND require calibration against `#1741` Layer 1 breach cavity lights before locking final lift values.

### 6.2 Godot Headless World, Exterior & Palette Parity Gates (`godot/world/test/`, `godot/render/`)
1. **Unwired-Asset Gate:** Assert `board.gd` wires high-relief planet shaders across all 5 `PLANET_LOOKS` (no silent fallback to `map3d_shaders.gd`), `a4_props.gd` uses `station_T2` across small and large clusters when installed, and `board.gd:_hulk()` covers all 6 factions.
2. **Ship Exterior Lighting & Micro-Detail Gate (`#1777`):** Assert Space PBR reflection IBL and per-faction `ao_light_affect` are enabled by default in play (not hidden behind an off-by-default env flag), `key.shadow_normal_bias <= 0.5`, and all 6 faction micro-detail normal/roughness maps resolve cleanly in `look.gd`.
3. **Rock Scan Channel Gate:** Inspect every rock `.glb` in `godot/world/rocks/scans.json` and assert `COLOR_0.b` spans usable dynamic range (`>= 0.45`) and minimum triangle quality (preventing flat/low-poly outlier regressions like `scan_07` and crushed `COLOR_0.b`).
4. **Zero-Purple & Starfield Budget Gate:** Assert zero indigo-to-purple entries in `world_sky.gd` (`PLANETS`, `PLANETS_ALT`) and `godot/fx/faction_looks.json` (`nebula`), and assert default `star_floor == 0.0` and grounded starfield thresholds in `world_sky.gd`.

### 6.3 Audio Pack & Engine Gate (`contrib/opus/tools/sound/`, `#1752`)
- Keep automated `elevenlabs_gen_selftest.js` + manifest lint checking: one shot per wired SFX clip, zero naval/ocean/pink-elephant words, zero em dashes, exact `today` baseline mapping against `godot/audio/cues.json`, and `FAC_WNAMES` roster coverage.
- Gate 3 Godot wiring (`#1752`) uses Godot 4.7's native `AudioStreamSynchronized` / `AudioStreamInteractive` for beat-synced, bar-locked 4-stem adaptive battle music plus a dynamic `AudioEffectLowPassFilter` on `battle_sfx` during slow-motion death beats, tactical pause, and extreme zoom-out.

---

## 7. Law 6: AAA Ship Exterior Lighting, Per-Faction Micro-Detail, PBR & Godot 4.7 Engine Standard (#1777, #1778, #1779, #1780)

Visual and code audits of live in-game ship renders (`S9`, `S10`, `S8`, `H10`, `A16`, `C11`, `C14`, `E12`) vs accepted concepts proved that even newly built hulls read slightly clay-ish or miniature-like due to global Godot lighting defaults and mid-roughness/mid-metallic PBR values (`metal = 0.48`, `VS_FLEET_LIGHTING` off by default, `ao_light_affect = 0.0`, `shadow_normal_bias = 2.0`, `LookRim spec = 8.0`, zero tiling micro-detail normal/roughness layer, zero advanced PBR channels, hardcoded `600.0` shadow cascades, `COMPRESS_S3TC` normal compression bug in `build_assets.gd:159`, missing scale cues, and lossy `.jpg` normals on legacy hulls).

### 7.1 Global Godot Ship Look, Advanced PBR Channels & Micro-Detail Layer (#1777, Lifts All 45 Ships Instantly)
1. **Default-On Multi-Lobe Space PBR Reflection IBL & `ao_light_affect`:** Graduate `#1679` ON by default in `godot/render/look.gd` and `godot/world/world.gd` with warm sun specular + cool nebula/planet bounce lobes + deep dark-space troughs, plus per-faction `ao_light_affect` so baked AO darkens sunlit seams and recesses.
2. **Crisp Contact Shadows & Zoom-Tracked Cascades (`look.gd:167`, `battle.gd:350,360`):** Reduce `key.shadow_normal_bias` from `2.0` down to a calibrated crisp contact-shadow range (`~0.15 to 0.35`), replace hardcoded `directional_shadow_max_distance = 600.0` with zoom-tracked `clampf(cam_r * 1.8, 120.0, 420.0)` and tighter near-split ratios (~3x sharper hull shadows for free), lower flat diffuse `ambient_light_energy` (`0.50` -> `~0.16 to 0.22`), and tame `LookRim` `spec: 8.0` plastic glare streaks across beveled decks.
3. **True BC5 / RGTC Ship Normal Compression (`godot/render/build_assets.gd:158-159`):** Fix the silent normal-map compression mismatch where line 156 asks for BC5/RGTC while line 159 passes `Image.COMPRESS_S3TC` (BC3 5-6-5 swizzled); switch to true `Image.COMPRESS_RGTC` (dual-8-bit normal precision) for cleaner specular highlights at identical VRAM size.
4. **Alive HDR Ship Emissives:** Push hot ship focal accents (Sunward ember spires, engine bells, core slits, Directorate bays, Eclipse corona rims) cleanly above bloom threshold (`0.8`) so vents glow warmly rather than reading as flat orange/blue paint stickers.
5. **Per-Faction Native Godot 4.7 PBR Channels (`BaseMaterial3D`) & Tiling Micro-Detail Maps (`godot/assets/ships/detail/`):** Inject six dedicated tileable micro-detail normal/roughness maps (mip-faded to prevent camera-170 shimmer) paired with native Godot 4.7 physical surface channels tailored per faction:

| Faction | Godot Native PBR + Tiling Micro-Detail (#1777) | Blender Exterior PBR Separation & Scale Cues (#1778) |
| :--- | :--- | :--- |
| **Sunward Crusade (`voidsworn`)** | `anisotropy_enabled` rolled forged-iron highlight + rolled cast-iron micro-grain, weld seam pitting & carbon mottling | Raw forged dark iron (`metal 0.80..0.92`, varied `rough 0.25..0.50`) vs deep matte furnace soot crevices (`metal 0.0`, `rough 0.88`), brass fittings (`metal 0.92`), recessed hot ember spires + micro-porthole strips and stenciled markings |
| **Meridian Directorate (`hegemony`)** | `anisotropy_enabled` brushed titanium highlight + tight directional brushed aerospace alloy & micro-machined fastener grit | Satin coated clinical navy-slate (`metal 0.10..0.20`, `rough 0.36..0.52`) contrasting sharply with bare chipped/machined titanium edge wear (`metal 0.90`, `rough 0.20`), deep recessed armor seams, crisp fleet stripes & viewport rows |
| **Ashfall Hullbreakers (`corsair`)** | Coarse hammered/pitted salvage iron + rough oxidized rust crust & oil-streak micro-roughness breakup | Dark oil-streaked raw salvage iron base (`metal 0.72..0.88`) with localized weathered rust-red plates and matte rust crusts (`metal 0.0`, `rough 0.85..0.95`; pull back from uniform bright red plastic on `A16`), vent grates, weld scars & stencils |
| **The Chorus (`chorus`)** | `subsurf_scatter_enabled` + `backlight_enabled` (translucent warm rim glow through thin chitin/membranes/veils) + wet `clearcoat_enabled` + keratin striations & wet organic micro-pores (zero metal) | High-relief multi-scale keratin/scute grooves, porous bone ridges, wet mucosa crevice sheen (`rough 0.16..0.28`) vs dry chalky horn lips (`rough 0.58..0.74`, `metal 0.0`), eliminating smooth wax/play-doh close-ups (`C11`, `C14`) |
| **The Glasswrights (`ithar`)** | `refraction_enabled` + crystal `clearcoat_enabled` (bending background starlight and weapon beams through glass) + fine annealed crystal micro-facets & optical edge grain (zero metal, zero grime) | Deep refractive/reflective smoked seafoam & amber annealed glass (dark glassy internal depth + sharp Fresnel grazing mirror reflections + fine etched prism rings, replacing blinding white origami A4 hulls via `#1682` / `#1146`) |
| **Eclipse (`deathless`)** | Subtle obsidian `clearcoat_enabled` + smooth-yet-etched obsidian-slate micro-fracture grain & hairline geometric veining | Deep satin obsidian-violet composite plates (`metal 0.15..0.35`, `rough 0.22..0.42`) contrasted with mirror-dark metallic bus channels (`metal 0.88`), fine monolith geometric seams, and crisp all-violet corona rims (`#1422`) |

### 7.2 Blender Exterior PBR, Scale-Cue & Lossless-Normal Pipeline (#1778)
- Pair directly with `#1680` (4K capital map sizing) and PR `#1763` (`#1743` Interior Kit V2) so every active and upcoming rebake (`#1681`, `#1682`, `#1684`, `#1422`, `#1412`, `#1291`, `#1153`, `#1155`) automatically exits the `metal = 0.48` clay dead zone, gains faction-matched massive-scale cues, and exports strictly lossless `.png` / BC5 normal and ORM maps.

### 7.3 Godot 4.7 Cinematic Post-FX & Lens Look (#1779)
1. **Per-Region Battle Color-Grading 3D LUT (`env.adjustment_enabled`, `adjustment_color_correction`):** Bring subtle filmic 3D LUT grading (currently only on campaign map `map3d.gd:136`) into battles so ships, FX, planets, and sky share one cohesive cinematic tone curve without tinting UI.
2. **Kill-Cam & Close-Up `CameraAttributesPractical`:** Keep Depth-of-Field strictly OFF during tactical play (`c170`); smoothly engage subtle far-background bokeh during close-up kill-cams, flagship podium previews, and close hull inspection.
3. **Selective RTX 5080 `Max` SSR & `CompositorEffect` Benchmark:** Benchmark half-res `env.ssr_enabled` on crystal, obsidian, and wet hulls under live weapon fire, and prototype a lightweight Godot 4.7 RD `CompositorEffect` for subtle capital-death shockwave distortion and Dead Star gravitational lensing polish.
4. **Forward+ Clustered `Decal`s:** Use hardware-accelerated Forward+ `Decal`s for non-cutout scorch and plasma burn marks on `station_T2` and asteroids (keeping Compatibility safe-mode fallback intact).

### 7.4 Godot 4.7 Performance, VRAM & Stutter Optimization (#1780)
1. **Eliminate 48 Runtime `Shader.new()` Compiles Across 17 Live Scripts:** Move hot inline string shaders (`world.gd`, `world_planet.gd`, `world_rocks.gd`, `world_living.gd`, `board.gd`, `fx_death.gd`, `fx_hull.gd`, `battle.gd`, `line_style.gd`, `squadron_wing.gd`, `squadron_craft.gd`, `map3d.gd`) to preloaded `.gdshader` files (or cached static `Shader` singletons) so Godot 4.7's Vulkan binary PSO disk cache eliminates first-battle load stalls and mid-battle first-death stutters (`#1439`, `#1542`).
2. **BC7 World VRAM Compression (`godot/world/world_bake.gd:45-48`):** GPU-compress baked sky/planet color maps and `R01` albedo maps to BC7 (`COMPRESS_BPTC`), cutting world VRAM by 60 to 75 percent (from >1 GB raw RGBA8) while keeping height/relief and 16-bit `#1502` sky gradients high-precision (`RGBAH` / BC6H).
3. **AMD FSR 2.2 (`Viewport.SCALING_3D_MODE_FSR2`) vs 4x MSAA (`battle.gd:393-399`):** Add FSR 2.2 (Native AA at `1.0` scale and 4K Quality at `0.75..0.85`) benchmarked side-by-side against 4x MSAA to kill metallic specular and thin-line shimmer while freeing major 4K GPU headroom.
4. **Empty Volumetric Fog Gate & Prop Distance Culling (`world_living.gd:55`, `world_rocks.gd`, `backdrop.gd`):** Enable `env.volumetric_fog_enabled` ONLY on boards containing actual `FogVolume` terrain (avoiding wasted `128x128` froxel raymarches on clear space maps); tune `visibility_range` fade and `Viewport.mesh_lod_threshold` on dense asteroid fields.

---

## 8. Global Execution Sequence (Zero Overlap, Maximum Cohesion)

1. **Gate 0 (Immediate Merges & Guardrails):**
   - `main` now holds PR `#1775` (R420 / `RULEBOOK 3.14`) and PR `#1753` (verified 72-item / 138-file Audio V2 manifest, ready for Audio Wave A `--max-credits 1200`).
   - Land `#1724`'s `export7.py` map-size fix, then apply Law 2 + Section 6.1 automated gates to **PR `#1763`** (`#1743` Interior Kit V2) and verify on one unified 6-faction lineup cutaway sheet before merging.
2. **Wave A (Parallel, Zero File Overlap):**
   - **`#1777` (Godot AAA Ship Exteriors: Space PBR IBL, crisp zoom-tracked shadows, BC5 normal fix, native per-faction PBR channels, 6-faction micro-detail normal/roughness maps, HDR emissive bloom):** lifts all 45 installed ships immediately.
   - **`#1741` (Wounds V2 Layers 1+2, `VS_WOUNDS_V2=1`):** calibrated jointly with `#1777`'s lighting and PR `#1763`'s moody interior values (`<= 0.10` linear walls) so breach-mouth cavity lights look dramatic, never washed out.
   - **`#1765` (Planets V2, coordinated with `#1463`)**
   - **`#1361` (Asteroids & Crystals V2)**
   - **`#1767` (Stations & 6-Faction Hulks V2)**
3. **Wave B (Coordinated Sky, Blender PBR, Performance & Audio Follow-Up):**
   - **`#1780` (Godot 4.7 Performance, VRAM & Stutter Optimization: `.gdshader` PSO cache, BC7 world VRAM, FSR 2.2 vs MSAA benchmark, empty volumetric fog gate):** frees GPU headroom and kills shader stutters before heavy post-FX.
   - **`#1778` (Blender Faction-by-Faction Exterior PBR, Scale Cues & Lossless Normal/ORM Gate):** lands right before active rebakes (`#1681`, `#1682`, `#1684`, `#1422`, `#1412`, `#1291`) so every rebake ships at full AAA fidelity.
   - **`#1766` (Grounded Cinematic Space Sky & Dead Star Seam)** sequenced cleanly with **`#1502` (16-bit sky bake)** and **`#1328` / `#1360`** (volumetric clouds & storm bolts).
   - **Audio Wave B** (after Ryan ear-checks Wave A listening page) -> **Gate 3** using native `AudioStreamSynchronized` / `AudioStreamInteractive` + dynamic `AudioEffectLowPassFilter`.
4. **Wave C (Cinematic Post-FX & Unified Final Polish):**
   - **`#1779` (Godot 4.7 Cinematic Post-FX: per-region battle 3D LUT, kill-cam `CameraAttributesPractical` DoF, selective SSR & `CompositorEffect` benchmark, Forward+ `Decal`s):** final visual glue over finished lighting, skies, and hulls.
   - **`#1362` (Graveyard debris scraps from faction ship kits)** aligned with R416 (`#1741` + `#1743`) and `#1778` PBR standards so combat wreckage and terrain graveyards share one visual language.
   - Full `independent-audit` (RULEBOOK 3.13) + solo RTX 5080 frame-time/VRAM check + full 6-faction / multi-biome PC capture pass for Ryan's final visual sign-off.


