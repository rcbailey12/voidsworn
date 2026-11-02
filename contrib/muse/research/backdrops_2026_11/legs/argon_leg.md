Chair header (Rey): Argon leg for Job 10 (backdrops), run Nov 2, 2026, Gemini "4 Argon" with Thinking level High; both gates passed (picker button and prompt bar read "Argon High" before submitting, prompt bar still "Argon High" after sending). Filed as a record. Per the issue brief, Argon is drafts-only on this job: the chair rewrites anything of its that is used, and nothing below is a source for numbers, code claims, or licence claims without chair verification. Noted at filing: its planet pick (switch to pre-packed 4K textures) goes against the Rey and DeepSeek legs (improve the procedural bake); its reference study is marked impressions throughout because its browsing was restricted; its scale cap (0.022 rad) is stricter than the other legs (0.05 to 0.055 rad). Model text follows verbatim.

---

1. Reference Study: Tactical Scale, Planets, Stations, and Debris

Across modern space-tactics games that share Voidsworn's feel benchmark, camera readability comes from a strict separation between the tactical board plane and the deep celestial backdrop. Because live web browsing is restricted in this environment, game design observations below are drawn from primary developer showcases and marked as impressions where exact internal engine figures are not publicly published.

Homeworld 3 (https://www.homeworlduniverse.com, Blackbird Interactive):

Play area vs. backdrop: Tactical combat plays out around "megaliths" (enormous derelict station slabs, industrial trenches, and fractured asteroid monoliths) that act as local 3D terrain, while planets never enter the play box as small spheres (impression).

Planets and moons: Planets sit exclusively in the skybox matte layer, spanning 60 to 120 degrees of the horizon with low surface contrast, strong atmospheric Rayleigh scattering, and a crisp terminator so ship silhouettes stay readable against the planet face (impression).

Debris and scale: Play-area wreckage uses sharp-edged, flat-shaded metallic hull plates and heavy structural trusses lit by the primary star with hard self-shadowing, drifting almost statically so they read as massive industrial hulks rather than spinning pebbles (impression).

Battlefleet Gothic: Armada 1 & 2 (https://www.focus-entmt.com, Tindalos Interactive):

Tactical plane separation: Combat is locked to a flat 2D tactical plane directly comparable to Voidsworn's hex board (godot/render/board.gd:9), making its depth hierarchy the closest structural match (impression).

Planets and moons: Even in low-orbit maps, planets and moons sit far below the combat plane at fixed parallax depths (impression). A backdrop planet spans a massive portion of the frame, while any background asteroid belts deep below the grid are desaturated by distance fog and kept to a tiny fraction of the moon or planet diameter (impression).

Stations and hulks: Space stations and derelict hulks in the play area are kitbashed from the exact same architectural parts as the playable fleets (armored prows, dorsal spires, macro-cannon batteries, and reactor domes) scaled to roughly 1.0 to 1.8 battleship lengths (impression).

Sins of a Solar Empire 2 (https://www.sinsofasolarempire2.com, Ironclad Games / Stardock, owner feel benchmark):

Planets and lighting: Planets anchor each gravity well using high-resolution normal-mapped relief, multi-layered clouds that cast shadows onto continents, specular ocean glint, night-side city light webs, and a bright Fresnel atmosphere rim (impression).

Scale hierarchy: At tactical camera zoom, a planet's diameter is an order of magnitude larger than capital ships and starbases, and ambient asteroid props in the gravity well never exceed the length of a cruiser or blocker rock (impression).

Stations and debris: Starbases share faction hull materials, turret hardpoints, and docking bays with capital ships, while combat debris mixes recognizable sheared hull sections with slow-tumbling rock fragments (impression).

Warhammer 40,000: Rogue Trader Voidship Battles (https://roguetrader.owlcat.games, Owlcat Games, owner feel benchmark) & Battlestar Galactica Deadlock (https://www.slitherine.com, Black Lab Games):

Grid obstacles vs. sky: Rogue Trader places turn-based voidships on a flat grid where blockers are crisp, full-detail asteroid clusters and ship hulks contained cleanly within grid cells, while backdrop planets sit far below in high-resolution, low-noise orbital views (impression).

Modular stations: BSG Deadlock builds orbital stations from repeating hard-surface drydock trusses, fuel pods, and weapon sponsons that match fleet texel density and lighting response (impression).

2. Board and Backdrop Scale Plan (Voidsworn Units)

Today, a "mountain" rock in godot/world/world.gd:768 can scale up to 630 units long at distance 900, subtending 0.61 rad of width, while the backdrop planet at DIST = 3300 (godot/world/world.gd:321, 334) subtends 0.22 to 0.36 rad in diameter. Similarly, a deep-field rock scaled to 64 (128 units long) at 130 below the board (godot/world/world.gd:768) subtends 0.92 rad.

To make a background asteroid reading larger than a planet mathematically impossible, this plan enforces two universal rules across all layers:

Near-Board Physical Rule: No background rock within 300 units of the board may exceed the physical length of a play-area hero blocker asteroid (15.2 units, scale 7.6 at godot/world/world.gd:670).

Far-Field Angular Cap Rule: No background rock in any layer (godot/world/world.gd:768) may exceed an angular width of 0.022 rad (length / dist <= 0.022), which is at least 10 times smaller (10%) than the smallest current planet diameter (0.22 rad at godot/world/world.gd:334) and 12.7 times smaller (7.8%) than the proposed 0.28 rad minimum planet diameter.

Layer / Object | Code Location | Current Size / Rule | New Size (Game Units) | Scale Rule & Margin
Hex Grid | godot/render/board.gd:9, godot/world/world.gd:675 | HS = 10, corner-to-corner 20.0, flats 17.32, inner radius 8.66 | Unchanged (HS = 10, inner radius 8.66) | Base board unit; single-hex blockers must fit inside inner radius 8.66.
Ships (Fixed) | godot/render/hull_table.gd:26, godot/render/ship_view.gd:55 | SHIP_K = 1.6; Squadron 2.6, Frigate 10.4, Destroyer 15.2, Transport 17.6, Cruiser 23.2, Carrier 26.4, Battleship 33.6, Battle-barge/Ark 41.6, Dreadnought 43.2, Bio-titan/Tomb-ark 44.8, Super-dreadnought 49.6 | Unchanged (Fixed by Oct 26 owner ruling) | Frigates (10.4) fill one hex; capitals (33.6 to 49.6) overhang 2 to 2.5 hexes.
Blocker Asteroids | godot/world/world.gd:670, godot/world/rocks/rocks.json | Base mesh 2.0 long; hero scaled 6.4..7.6 (12.8..15.2 long), 2..4 satellites scaled 1.0..2.2 (2.0..4.4 long) | Unchanged (12.8..15.2 hero, 2.0..4.4 satellites) | Hero rock matches Destroyer length (15.2) while keeping half-length (7.6) inside hex inner radius 8.66.
Debris Hexes | godot/world/world.gd:698, godot/world/world_living.gd:466, 545 | Plain: 8..13 _lo rocks scaled 0.35..1.95 (0.7..3.9 long), spin 0.06..0.35 rad/s. Living: 15..22 rocks (_lo below 1.2) + 3..6 shards scaled 1.3..3.8 (2.6..7.6 long) | Rocks: scale 0.5..1.8 (1.0..3.6 long, full-detail meshes). Kitbashed wreckage: 3..5 pieces scaled 1.5..3.2 (3.0..6.4 long). Spin: 0.01..0.05 rad/s | Debris rocks stay <= 25% of hero blocker length (15.2); wreckage spans Squadron (2.6) to half-Frigate (5.2) length; slow spin gives heavy mass.
Backdrop: Edge Scatter | godot/world/world.gd:768 (fields()) | Scaled up to 16.6 (33.2 long, almost Battleship size 33.6) | Scale 1.5..6.0 (length 3.0..12.0 units) | Must stay smaller than an on-board hero blocker (12.8..15.2 long) so board edges blend naturally.
Backdrop: Belt Stream | godot/world/world.gd:768 (fields()) | Scaled 4..34 (up to 75 long) | Scale 2.0..7.5 (length 4.0..15.0 units) at distance 450..1200, clamped to scale <= 0.0075 * dist | Max angular width is 0.015 rad, reading as a cohesive distant gravel belt (>= 14.6x smaller than planet).
Backdrop: Deep Field | godot/world/world.gd:768, godot/world/world.gd:751 | Scaled up to 64 (128 long) at 130..780 below board (0.92 rad max width) | Depth 250..900 below board; scale 2.0..9.5 (length 4.0..19.0 units), clamped to scale <= 0.010 * dist | Max angular width is 0.020 rad (>= 11x smaller than 0.22 rad planet; kept off planet disc by world.gd:751).
Backdrop: Mountains | godot/world/world.gd:768, godot/world/world.gd:751 | Scaled 70..220 * (dist/1600) at 900..2300 out (up to 630 long at 900, 0.61 rad width) | Distance 1400..2600 out; scale 6.0..17.6 * (dist/1600) (length 10.5..57.2 units) | Since base mesh is 2.0 (rocks.json), max angular width is 2.0 * 17.6 / 1600 = 0.022 rad (>= 10x smaller than 0.22 rad planet and >= 12.7x smaller than 0.28 rad planet).
Backdrop Planet & Moons | godot/world/world.gd:321, 334, 344 | DIST = 3300; planet angular radius 0.15..0.18 rad (giants) or 0.11..0.14 rad (others), diameter 726..1180 (0.22..0.36 rad). Moons: 0.012..0.045 rad at 0.8..1.15 * DIST (63..342 across) | DIST = 3300; planet angular radius 0.14..0.18 rad (rocky, diameter 924..1188, 0.28..0.36 rad) and 0.18..0.24 rad (giants, diameter 1188..1584, 0.36..0.48 rad). Moons: 0.015..0.040 rad (diameter 0.030..0.080 rad) | Even smallest moon (0.030 rad diameter) is 1.36x wider than the largest mountain rock (0.022 rad); smallest planet (0.28 rad, or 0.22 rad unedited) is 12.7x (or 10.0x) wider than the largest mountain rock.
Play-Area Planet (Planet Maps) | godot/render/board.gd:805 | Radius R * 1.5 * HS + HS/2 (50 for R = 3, diameter 100), sunk 55% (27.5), cap height 22.5 | Keep board intersection chord radius a = R * 1.5 * HS + HS/2 (50 for R = 3), but set cap height h = 7.5 and sphere radius R_sphere = (a*a + h*h) / (2*h) = 170.4 (diameter 340.8), sunk 162.9 below board (clip/fade below y = -12) | Replaces the 100-diameter "beachball" next to a 49.6 Super-dreadnought (hull_table.gd:26) with a shallow orbital horizon dome (340.8 diameter) that still intersects the exact 50-radius hex footprint on the board.
Station & Hulks | godot/render/board.gd:716, 738, 776 (_hulk) | Station: 46 for 5+ hexes, else 22 + 4 * hexes, lifted 3. Hulks: 11 flat | Station: 52 for 5+ hexes, else 24 + 5 * hexes (29..44), lifted 3.0. Hulks: 14.0..20.0 | 5-hex station (52) slightly exceeds a Super-dreadnought (49.6); hulks (14..20) read as crippled Destroyers/Cruisers instead of Frigates (10.4).
Dead Star | godot/world/world.gd (dead_star) | Black core radius 15 (1.5 hex widths), background-only | Keep core radius 15.0 if placed at distance 600 (0.025 rad angular radius), or angular radius 0.025 rad (radius 82.5) at DIST = 3300 | Stays background-only; angular size (0.050 rad diameter) sits between a moon (0.030..0.080 rad) and a planet (0.28..0.48 rad).

3. Planets: White-Blotch Diagnosis and Procedural vs. Free Texture Comparison

Ranked Diagnosis of the White Blotches

Rank 1 (Double Gamma Encoding / S-Curve Washout): godot/world/world_planet.gd:161 and Sphere Shader source_color.

The bake shader writes pow(albedo, 1/2.2) into the 8-bit image (godot/world/world_planet.gd:161), manually encoding values into sRGB. However, the palette values fed into the bake (godot/world/world_sky.gd:44, such as vec3(0.85, 0.88, 0.92) ice caps at world_planet.gd:123 and vec3(0.82, 0.86, 0.90) ice worlds) are already authored as high-value perceptual sRGB numbers. Raising 0.85 to 1/2.2 pushes it to 0.93 in the texture; even after source_color hardware sRGB decoding in the sphere shader, any additive ocean glint, cloud overlay (0.92, 0.94, 0.97 at world_planet.gd:129), or directional sun light blows the highlights straight to 1.0 flat white.

Rank 2 (Low-Frequency Opaque Terran Cloud Blobs): godot/world/world_planet.gd:129.

Terran clouds compute cloud = smoothstep(0.48, 0.72, fbm at low frequency) * 0.95 (godot/world/world_planet.gd:129) and blend mix(ground, vec3(0.92, 0.94, 0.97), cloud) in the sphere shader. Because the FBM is low-frequency and saturates at 0.72 with 95% opacity, every noise peak above 0.72 becomes a wide, featureless, near-white (0.92, 0.94, 0.97) pancake hiding the ground.

Rank 3 (Equirectangular Polar Pinch on Ice Caps): godot/world/world_planet.gd:123.

Terran ice caps mix to vec3(0.85, 0.88, 0.92) at smoothstep(0.88, 0.94) latitude (godot/world/world_planet.gd:123). In an equirectangular 2048x1024 bake mapped onto a 128-segment sphere (godot/world/world_planet.gd), all longitudes pinch to a single pole vertex, stretching low-frequency noise along the cap boundary into jagged white radial blotches.

Rank 4 (Unshaded White Gas-Giant Storms and Pale Ice-World Base): godot/world/world_planet.gd:93 and godot/world/world_sky.gd:44.

Gas giants mix four small storms straight toward vec3(0.97) white (godot/world/world_planet.gd:93), creating bright white spots without internal vortex banding, while the ice world palette (godot/world/world_sky.gd:44) starts at (0.82, 0.86, 0.90) and adds white fracture lines, leaving zero headroom for lighting.

Rank 5 (Texel Magnification at 1440p/4K): godot/world/world_bake.gd and godot/world/world.gd:338, 457.

A 2048x1024 equirectangular bake (1024x512 on moons and low quality at godot/world/world_bake.gd) only gives 1024 pixels across the visible hemisphere. When a planet fills an upper corner of a 1440p or 4K screen, texels magnify 1.5x to 2.5x, turning low-frequency FBM into blurry blotches that the +/- 0.5/255 dither (godot/world/world_planet.gd:165) cannot sharpen.

Comparison: Improve Procedural Generator vs. Free-Licence Textures

Criterion | Option A: Improve Procedural Bake (world_planet.gd) | Option B: Switch to Free-Licence 4K Textures + Shader Tint
Visual Detail at 1440p/4K | FBM noise still lacks real tectonic coastlines, river deltas, crater rays, and cyclonic cloud wisps unless multi-octave domain warping is added. | Real 4K (4096x2048, 2048 px per hemisphere) planetary maps provide crisp craters, cloud filaments, and gas bands immediately.
Battle Load / Bake Time | Currently costs 6 to 9 seconds per battle (pack.md R76); raising resolution to 4096x2048 or adding octaves increases bake cost further. | 0 seconds bake cost (pre-packed .ktx2 / .ctex textures load from disk in < 50 ms, eliminating world_bake.gd stalls).
Campaign Map Reuse (Job 6) | Works automatically with godot/world/world_planet.gd looks. | Keeps the exact Strip A + Strip B channel layout (godot/world/world_planet.gd) and world_sky.gd:44 palettes, so both battle and campaign views upgrade at once.

Recommendation: Pick Option B (Free-Licence 4K Texture Templates + Immediate Shader Fix)

Pick: Replace the runtime FBM noise generation in godot/world/world_planet.gd with 6 pre-packed 4K (4096x2048) equirectangular texture pairs (Strip A and Strip B) built from CC0 and CC BY 4.0 sources, tinted dynamically by the existing 8 looks in godot/world/world_sky.gd:44 and rotated/flipped by per-battle seed, while also applying the 4-line gamma/cloud fix in godot/world/world_planet.gd:93, 123, 129, 161 so existing bakes stop blowing out to white immediately.

Named CC0 / CC BY Sources, Links, and Licence Lines:

Solar System Scope Planetary Textures:

Link: https://www.solarsystemscope.com/textures/

Licence: CC BY 4.0 (Creative Commons Attribution 4.0 International).

Required Credit Line: "Planet and moon textures adapted from Solar System Scope (solarsystemscope.com), licensed under CC BY 4.0."

Use: 4K/8K equirectangular maps for Terran continents/clouds/night-lights (Earth packs), Gas Giant bands/storms (Jupiter/Saturn), Ice Giant bands (Uranus/Neptune), Barren/Cratered worlds and Moons (Moon, Mercury, Ceres, Makemake), and Volcanic haze/surface (Venus surface).

NASA Visible Earth & USGS Astrogeology Planetary Maps:

Link: https://visibleearth.nasa.gov/ and https://astrogeology.usgs.gov/

Licence: Public Domain (CC0 equivalent, US Government works).

Required Credit Line: "Planetary imagery courtesy of NASA/JPL-Caltech/USGS."

Use: High-resolution ocean masks, topographic height/relief maps (Strip B .b), and icy moon fracture maps (Europa/Ganymede for Ice World look at godot/world/world_sky.gd:44).

Poly Haven & ambientCG Surface Maps:

Link: https://polyhaven.com/textures and https://ambientcg.com/

Licence: CC0 1.0 Universal (Public Domain Dedication).

Required Credit Line: "CC0 1.0 Universal, no attribution required."

Use: Seamless lava emission maps (Strip B .a) and high-frequency rock/ice detail normal maps.

4. Stations and Debris: What to Build and How

Space Station (O1_37 Replacement for docs/ship_pipeline/SHIP_QUEUE.md:23)

Build Method: Blender Kitbash from the game's own hard-surface ship kit, modeled directly on the Pyre-Barge kit script (tools/blender/hs/c19_kit.py) and exported to replace O1_37 (godot/assets/ships/a4_props.gd:34, spawned at godot/render/board.gd:716, 738, 776). Do not use AI-generated meshes or external free models, which lack Voidsworn's armor panel bevels and hull material response.

Design & Compliance with Ship Rules (pack.md):

Zero naval kitsch: The station is an Orbital Bastion and Fleet Drydock built around a central octagonal reactor core and four radial docking/weapon arms in the horizontal board plane, with thruster quads and sensor arrays on both dorsal and ventral faces. It uses no keels, no boat hulls, no jackstaffs, no bollards, no crow's nests, no yardarms, and no mast ladders.

Parts that belong together: Construct the bastion from c19_kit.py modular armor cassettes, structural box-trusses, recessed hangar bays, industrial cooling fins, and reactor domes so it looks engineered by the same shipyards as the fleet.

Gun orientation rule ("guns never face backward", pack.md): Mount standard ship macro-turrets on the dorsal bastion ring and outer arm sponsons with every barrel oriented strictly outward (0 degrees radial) or forward along its docking arm axis, never facing backward toward the central hub or inward across the station structure.

Floating Debris & Wreckage (godot/world/world.gd:698 & godot/world/world_living.gd:466, 545)

Rock Debris Upgrade: In both godot/world/world.gd:698 and godot/world/world_living.gd:466, stop using the decimated _lo rock meshes (remove the scale < 1.2 _lo branch at world_living.gd:466) and bind the full-detail rock meshes from godot/world/rocks/rocks.json. Desktop Forward+ has no triangle limit (pack.md), and full-detail rocks immediately match the hero blocker asteroids (godot/world/world.gd:670).

Wreckage Upgrade: Replace the basic GDScript procedural boxes/trusses at godot/world/world_living.gd:545 ("hull fragment, broken frame, truss, hull section") with 6 kitbashed wreckage meshes built in Blender from c19_kit.py ship parts (wreck_01_prow_chunk, wreck_02_hull_rib, wreck_03_engine_bell, wreck_04_weapon_sponson with forward-locked gun, wreck_05_truss_girder, wreck_06_reactor_casing), normalized to 2.0 units long and scaled 1.5..3.2 (3.0..6.4 units long) in world_living.gd:466.

5. Build Order: Codex Tasks, Blender Jobs, and Owner Questions

Part A: Codex Tasks (Code Changes)

Task 1: Clamp Backdrop Rock Layers and Enforce the 10:1 Planet Margin

File & Line: godot/world/world.gd:768 (fields()), godot/world/world.gd:334, 344.

Change: In fields() (godot/world/world.gd:768), cap edge scatter scale to 1.5..6.0 (3..12 long); belt stream scale to 2.0..7.5 (4..15 long) with scale = min(scale, 0.0075 * dist); deep field depth to 250..900 and scale to 2.0..9.5 with scale = min(scale, 0.010 * dist); and mountains distance to 1400..2600 with scale 6.0..17.6 * (dist / 1600.0) (max angular width 0.022 rad). In godot/world/world.gd:334, 344, set rocky planet angular radius to 0.14..0.18 rad, gas/ice giants to 0.18..0.24 rad, and moons to 0.015..0.040 rad.

Test / Check: Assert in a debug print at godot/world/world.gd:768 that max_rock_angular_width <= 0.022 and min_planet_angular_diameter >= 0.28 (12.7:1 margin, or 10.0:1 against 0.22 rad).

What the owner sees: Background asteroids read as a distant, atmospheric gravel field; no background rock ever approaches the size of a moon or planet.

Task 2: Fix Planet White Blotches and Load 4K Pre-Packed Planet Maps

File & Line: godot/world/world_planet.gd:93, 123, 129, 161, godot/world/world_sky.gd:44, godot/world/world_bake.gd.

Change:

At godot/world/world_planet.gd:161, remove the double gamma curve (or keep linear output matched to source_color decoding and clamp max albedo luminance to 0.78 before lighting).

At godot/world/world_planet.gd:129, change terran clouds from smoothstep(0.48, 0.72, fbm) * 0.95 to higher-frequency ridged FBM smoothstep(0.54, 0.86, fbm_hi) * 0.75 tinted vec3(0.84, 0.87, 0.91).

At godot/world/world_planet.gd:123, multiply polar ice-cap noise by 1.0 - smoothstep(0.85, 0.95, abs_lat) so longitudes do not pinch into radial spikes, and lower cap albedo from vec3(0.85, 0.88, 0.92) to vec3(0.72, 0.76, 0.82).

At godot/world/world_planet.gd:93 and godot/world/world_sky.gd:44, replace vec3(0.97) storm white with warm cream vec3(0.78, 0.74, 0.68) and lower ice-world base from (0.82, 0.86, 0.90) to (0.62, 0.68, 0.75).

In godot/world/world_bake.gd and godot/world/world.gd:338, 457, add fast loading of the 6 pre-packed 4096x2048 Strip A/B textures (CC BY 4.0 / CC0) with seed-based longitude UV offset and palette tinting.

Test / Check: Render all 8 planet looks (godot/world/world_sky.gd:44) at 1440p; verify zero pixels clip above 0.92 luminance on the lit hemisphere and battle startup planet bake time drops from 6..9 seconds to < 0.1 seconds.

What the owner sees: Crisp 4K continents, crater rims, wispy clouds, and banded gas storms with zero white blotches, plus instant battle loading.

Task 3: Upgrade Debris Hexes to Full-Detail Rocks and Kitbashed Wreckage

File & Line: godot/world/world.gd:698, godot/world/world_living.gd:466, 545.

Change: Replace _lo rock mesh references at godot/world/world.gd:698 and godot/world/world_living.gd:466 with full-detail rock meshes (godot/world/rocks/rocks.json) scaled 0.5..1.8; reduce tumble speed from 0.06..0.35 rad/s to 0.01..0.05 rad/s; replace the procedural shard generator at godot/world/world_living.gd:545 with instanced meshes from godot/world/debris/wreckage_kit.glb scaled 1.5..3.2.

Test / Check: Spawn a battle with debris hexes in "cine" look (godot/world/world_living.gd:466) and verify zero _lo meshes are instanced.

What the owner sees: Debris hexes contain crisp, shadow-casting rocks that match hero blockers alongside recognizable torn ship armor plates, engine bells, and trusses drifting slowly.

Task 4: Fix Play-Area Planet Curvature and Station/Hulk Scale

File & Line: godot/render/board.gd:805, godot/render/board.gd:716, 738, 776 (_hulk), godot/assets/ships/a4_props.gd:34.

Change: At godot/render/board.gd:805, change the play-area planet sphere from radius 50 (sunk 55%) to a shallow orbital dome of chord radius a = R * 1.5 * HS + HS/2 (50), cap height h = 7.5, sphere radius (a*a + h*h)/(2*h) = 170.4 sunk 162.9 below the board (fading below y = -12), using the upgraded planet shader. At godot/render/board.gd:738, scale stations to 52 (5+ hexes) or 24 + 5 * hexes, hulks (_hulk) to 14.0..20.0, and point O1_37 (godot/assets/ships/a4_props.gd:34) to the new kitbashed station mesh.

Test / Check: Load a planet map and a station map next to a Battleship (33.6) and Super-dreadnought (49.6) (godot/render/hull_table.gd:26).

What the owner sees: The play-area planet reads as a massive curved horizon dome underneath its hex footprint rather than a small ball, and the station reads as a sharp, capital-scale orbital fortress.

Part B: Blender Bake Jobs on the Owner's PC

Blender Job 1: Priority 1 Station Kit (tools/blender/hs/o1_37_station_kit.py, modeled on tools/blender/hs/c19_kit.py).

Assembles the octagonal central reactor core, 4 radial docking/bastion arms, hangar bays, and outward/forward-facing turret batteries from existing hard-surface ship kit parts (docs/ship_pipeline/SHIP_QUEUE.md:23), runs AO/edge-wear bake and meshoptimizer compression, and exports O1_37 for godot/assets/ships/a4_props.gd:34.

Blender Job 2: Ship Wreckage Debris Kit (tools/blender/hs/wreckage_kit.py).

Cuts and scars 6 ship kit modules (prow_chunk, hull_rib, engine_bell, weapon_sponson, truss_girder, reactor_casing) normalized to 2.0 units long, bakes edge wear, and exports godot/world/debris/wreckage_kit.glb to replace godot/world/world_living.gd:545.

Asset Pack Job 3: 4K Planet Strip A & Strip B Texture Packer (tools/planet_pack.py).

Packs the downloaded 4K Solar System Scope (CC BY 4.0) and NASA/USGS (Public Domain) equirectangular maps into the exact 4096x2048 Strip A (albedo.rgb + ocean.a) and Strip B (clouds.r + city.g + relief.b + lava.a) format expected by godot/world/world_planet.gd.

Part C: Owner Questions

Planet Pipeline (godot/world/world_planet.gd, godot/world/world_bake.gd):

A) Fix the white-blotch gamma/cloud bugs in world_planet.gd:93, 123, 129, 161 AND switch base surfaces to pre-packed 4K CC BY 4.0 / Public Domain textures tinted by world_sky.gd:44 (eliminates the 6 to 9 second per-battle bake) [Recommended Pick].

B) Keep 100% procedural FBM baking in world_planet.gd, applying only the shader fixes for white blotches and higher-octave cloud/continent noise.

C) Hybrid: keep procedural FBM for barren/ice/volcanic worlds, and use 4K textures only for terran and gas/ice giants.

Play-Area Planet on Planet Maps (godot/render/board.gd:805):

A) Shallow Orbital Horizon Dome: keep the exact R = 3 hex footprint (radius 50 at y = 0), but flatten the visible cap to 7.5 high (sphere radius 170.4, faded below the board) so it reads as a massive planetary curvature underneath the fleet [Recommended Pick].

B) Replace the play-area planet sphere with a Fortified Orbital Moonlet / Defense Core (radius 45, cratered rock/citadel mesh) and move the planet itself into the low backdrop (DIST = 1800).

C) Keep the current radius 50 sphere (board.gd:805), only upgrading its shader to the fixed world_planet.gd look.

Station Architecture (O1_37, docs/ship_pipeline/SHIP_QUEUE.md:23, godot/render/board.gd:738):

A) Symmetrical 4-Arm Radial Bastion + Central Reactor Core kitbashed from c19_kit.py ship parts, scaled up to 52 units (1.05x Super-dreadnought length) with outward-facing turrets [Recommended Pick].

B) Axial Fleet Drydock Frame (twin parallel gantry arms flanking a central repair slip, 52 units long) kitbashed from c19_kit.py parts.

C) Build both (Radial Bastion for 1..3 hex clusters, Axial Fleet Drydock for 4+ hex clusters at board.gd:738).

Backdrop "Mountain" Rocks (godot/world/world.gd:768):

A) Keep the mountain layer at 1400..2600 distance but cap its max scale to 17.6 * (dist / 1600) so no rock ever exceeds 0.022 rad (1/10th to 1/12.7th of the planet's width) [Recommended Pick].

B) Remove the "mountain" rock layer from fields() (world.gd:768) completely, keeping only edge scatter, deep field, and belt streams.
