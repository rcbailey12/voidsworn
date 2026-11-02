Voidsworn Research Leg Report: Job 10, Backdrops, Planets, Stations, Debris and Scale

1. Reference Study

Homeworld 3 (Blackbird Interactive, Gearbox, May 2024). Planets and megastructures sit outside the play volume and serve as visual anchors and occlusion terrain. The tactical camera frames squadrons against these bodies; planets never enter the formation layer. In developer diaries posted to the Blackbird Interactive YouTube channel and Steam community updates, the team described a "scale hierarchy" where backdrop geometry is lit with a single key light and receives no shadow-casting from ships, keeping the read clean at distance. Moons are small accent discs near the parent planet. Stations are playable structures in the battle volume, built from modular hull sections. Debris fields are sparse, large fragments, not gravel. The overall rule: nothing in the backdrop is allowed to compete for attention with the fleet. Steam page: https://store.steampowered.com/app/1339880/Homeworld_3/. Developer diary series on the Blackbird YouTube channel. The specific "scale hierarchy" phrasing is my impression from watching the diaries; the exact wording may differ.

Battlefleet Gothic: Armada 2 (Tindalos Interactive, Focus Entertainment, 2019). The camera sits close to the ships. Planets are full backdrop spheres with simple atmosphere shaders, placed well outside the battle box. Stations are in-play objectives built from repeated hull modules. Debris is limited to a few large wreck pieces for performance. The key lesson: stations read as architecture because they are assembled from recognisable ship modules (engines, weapon bays, habitation rings), not from a single sculpted blob. Steam page: https://store.steampowered.com/app/573100/Battlefleet_Gothic_Armada_2/.

Sins of a Solar Empire 2 (Ironclad Games, October 2024). The named feel benchmark in contrib/opus/FINDINGS.md. Planets are strategic nodes rendered as lit spheres with atmosphere rims. The camera zooms from system view to fleet engagement. At tactical zoom, planets fill a corner of the screen but never overlap the ship layer. Moons are small, 10 to 20 percent the parent diameter. Stations and orbital structures sit on the planet surface or in close orbit. Debris after battles is sparse large chunks. Ironclad's Steam community posts and the game's built-in screenshot mode show this layering. Steam page: https://store.steampowered.com/app/1575940/Sins_of_a_Solar_Empire_2/.

Warhammer 40,000: Rogue Trader (Owlcat Games, December 2023). The second named benchmark. Voidship battles show a handful of large ships against a nebula and distant planet backdrop. Ships are the only detailed models; the planet is a soft gradient sphere. The lesson: at tactical camera, the planet is mood, not geometry. Steam page: https://store.steampowered.com/app/1582800/Warhammer_40000_Rogue_Trader/. Voidship battle presentation is my impression from gameplay footage.

Endless Space 2 (Amplitude Studios, 2017). Added here for backdrop planet handling. Planets are pre-rendered or simply shaded spheres at system view. At battle view (auto-resolve is default, but the cinematic replay shows ships), the planet is a soft-lit disc with an atmosphere rim, never more than 30 percent of the frame width. Stations are modular. The lesson: a strong atmosphere rim and terminator do more for planet readability than surface detail. Steam page: https://store.steampowered.com/app/392110/Endless_Space_2/. This framing is an impression from replaying the game.

Synthesis. Every reference keeps backdrop planets well outside the play area, caps their angular size to roughly a quarter to a third of the frame, lights them with one key light plus atmosphere rim, and builds stations from modular ship-like parts. Debris is large and sparse, not fine gravel. No reference lets a backdrop rock read bigger than the planet.

2. Scale Plan

All numbers in game units (1 unit = 1 world unit). Ship sizes and hex size are owner-ruled and fixed.

Layer | Current | Proposed | Rule
Ships | SHIP_K = 1.6 (hull_table.gd:26, ship_view.gd:55). Frigate drawn 16.6, Dreadnought 69.1. | No change. | Owner-ruled Oct 26.
Hex | HS = 10, 20 across corners (board.gd:9, world.gd:675). | No change. | Reference unit.
Blocker asteroids | Hero rock 13 to 15 long, satellites 2 to 4.4 (world.gd:670). | No change. | Already liked by owner.
Debris | Rocks 0.7 to 3.9 (world.gd:698). Wreckage 2.6 to 7.6 (world_living.gd:466, 545). | No size change. Improve variety (Section 4). | Sub-hex scale, reads as fragments.
Edge scatter | Up to 33 long (world.gd:768). | Keep 33 max. | At board edge, does not overlap planet disc.
Deep field | Up to 128 long at 130 to 780 below board (world.gd:768). | Cap at 50 long. | Angular cap rule below.
Belt stream | Up to about 75 long (world.gd:768). | Cap at 40 long. | Angular cap rule below.
Mountains | Up to 630 long at 900 out (world.gd:768). | Cap at 90 long at 900, 230 at 2300. Scale cap 45 near, 115 far. | Angular cap rule below.
Backdrop planet | DIST 3300, angular diameter 0.22 to 0.36 rad (world.gd:321, 334). | No change. | Reference ceiling.
Moons | Angular radius 0.012 to 0.045 at 0.8 to 1.15 DIST (world.gd:344). | No change. | Well under planet.
Planet in play | Radius 50, diameter 100, cap 22.5 high (board.gd:805). | No change. | In-play object, different shader.
Station | 22 to 46 long (board.gd:716, 738). | Keep size. Replace mesh (Section 4). | In-play object.
Dead star | Core radius 15 (world.gd, dead_star). | No change. | Background accent.

The angular cap rule. No backdrop rock (mountain, deep field, belt) shall subtend more than 0.10 rad of angular width as seen from the board centre. The planet's smallest angular diameter is 0.22 rad (2 x 0.11, world.gd:334). Therefore the planet is always at least 2.2 times the angular width of any backdrop rock.

Margin against the owner's photo. Today a 630-long mountain at 900 subtends about 0.61 rad while the planet subtends 0.22 to 0.36 rad. The mountain reads 1.7 to 2.8 times the planet. Under the cap, the largest mountain at 900 is 90 long, subtending 0.10 rad. The planet at its smallest (0.22 rad) is 2.2 times wider. The owner's photograph becomes impossible by a factor of at least 2.2. At the planet's largest (0.36 rad), the margin grows to 3.6 times.

The existing angle check at world.gd:751 keeps mountains off the planet disc. The new cap complements it by controlling relative size when they sit side by side.

3. Planets

White blotch diagnosis, ranked

Possible sRGB double-encode. Albedo is stored as pow(albedo, 1/2.2) into an 8-bit image (world_planet.gd:161). The texture is declared source_color in the sphere shader, so Godot decodes sRGB to linear on sampling. If the bake shader's output is already in sRGB display space (as the artistic colour picks suggest), the manual pow(1/2.2) is a second encode. The source_color decode removes one layer, leaving the image one gamma step too bright. Every colour shifts toward white. This is the most likely systemic cause. Hang on world_planet.gd:161 and the source_color declaration in the sphere shader.

Terran cloud coverage and colour. Clouds mix to vec3(0.92, 0.94, 0.97) with smoothstep(0.48, 0.72) coverage (world_planet.gd:129). At 1024 px across the visible hemisphere, these near-white bands dominate the disc and read as blotches. Hang on world_planet.gd:129.

Ice cap pole pinch. Ice mixes to vec3(0.85, 0.88, 0.92) above smoothstep(0.88, 0.94) latitude (world_planet.gd:123). In an equirectangular bake, all longitudes collapse at the pole row, concentrating white into a few texture rows that smear when sampled near the pole. Hang on world_planet.gd:123.

Gas giant white storms. Small storms mix toward vec3(0.97) (world_planet.gd:93). Five storms, several near-white, on a banded surface at low resolution. Hang on world_planet.gd:93.

Ice world base palette. Base albedo is already pale at (0.82, 0.86, 0.9) with white fracture lines. Inherent to the look, but compounds with issues 1 and 5. Hang on the ice world palette in world_sky.gd:44.

Detail budget. 2048x1024 bake, visible hemisphere 1024 px across. At 4K the planet can fill 800 to 1200 px of screen width. The texture is stretched, making every bright region blob. Not a bug per se, but amplifies all the above.

Pick: improve the procedural bake

I recommend fixing the bake rather than switching to free textures.

Reasons. The planet system serves two places at once: the battle backdrop and the campaign sector map (Job 6 set map stops to use world_planet.gd looks). A free-texture swap would need reworking both integration points and the sphere shader's ocean mask, cloud, city-light and lava channels. Sourcing CC0 or CC BY equirectangular textures for eight planet kinds (gas giant, ice giant, terran, volcanic, barren, ice world, plus variants, world_sky.gd:44) with enough variety to avoid repetition across a campaign is a large curation job. The sRGB fix (cause 1) is a one-line change that should remove the worst of the white washing. Reducing cloud opacity and coverage (cause 2) and adding a pole-cap fade (cause 3) are small shader edits.

The bake cost of 6 to 9 seconds per battle is noted. The fix does not change bake resolution or add passes, so cost stays flat. The separate Codex batch on bake cost can pursue caching or resolution options independently.

Free-texture option noted for completeness: Solar System Scope (CC BY 4.0, https://www.solarsystemscope.com/textures/) and NASA/JPL public-domain imagery are the main CC0/CC BY sources. They cover real planets, not the eight stylised kinds the game needs. Licensing lines would need to be added per texture. I do not recommend this path.

4. Stations and Debris

Station

The current mesh is O1_37, an AI-generated objective mesh (a4_props.gd:34). It reads as a blob. In the ship queue (docs/ship_pipeline/SHIP_QUEUE.md:23) the station is Priority 1 and "not started" for the hand-built kit pass. The worked example of that pass is the Pyre-Barge kit (tools/blender/hs/c19_kit.py).

Pick: kitbash from the game's own ship parts, following the c19_kit.py pattern. Build the station in Blender from existing hull sections, engine housings, weapon mounts, antenna masts and cargo pod primitives. Rules from the pack: space ships not naval ships, so no keels, jackstaffs, bollards, crow's nests, yardarms or mast ladders. Parts must belong together visually. Guns never face backward. The station should read as a cluster of connected modules: a central spine, two to four habitation or cargo rings, docking arms, and a defence battery facing forward. Target 46 long for a 5-plus hex cluster (board.gd:716), 22 to 42 for smaller clusters (board.gd:738). Lift 3 above the board (board.gd:776).

Do not use a free CC0 station model. The station must match the game's ship visual language, and no free model will match the existing hull kit without heavy rework.

Debris

The living/cine debris path (world_living.gd:466, 545) already places 15 to 22 rocks plus 3 to 5 procedural wreckage shards (hull fragment, broken frame, truss, hull section) per hex. The owner calls it "very basic" next to the improved asteroids.

Pick: extend the procedural wreckage set. Add three to four new shard types in Blender using the ship hull kit primitives: a torn engine bell, a bent sensor dish, a shattered cargo container, a crumpled armour plate. Keep them around 2 units across before the existing 1.3 to 3.8 scale (world_living.gd:545 onward), so they land in the 2.6 to 7.6 range. The rocks themselves are fine at low detail; the gap is in wreckage variety.

5. Build Order

Codex tasks

Task 1: Fix sRGB encode on planet bake.
File: world_planet.gd:161. Remove or guard the pow(albedo, 1/2.2) so the 8-bit image stores linear values, or remove the source_color flag on the sphere shader's planet texture, whichever matches Godot's Forward+ expectation. Test: bake a terran and a gas giant, screenshot at battle camera, compare to current. Owner sees: planet colours are richer, white blotches reduced across all kinds.

Task 2: Reduce terran cloud coverage and opacity.
File: world_planet.gd:129. Widen the smoothstep to (0.55, 0.80) and lower the mix alpha from 0.95 to 0.70. Test: bake 10 terran seeds, count cloud-covered pixels, target under 35 percent of disc. Owner sees: more surface visible, clouds read as weather not white paint.

Task 3: Fade ice caps at poles.
File: world_planet.gd:123. Add a smoothstep fade over the top 3 texture rows to break the solid white pole band. Test: bake a terran, inspect pole region in the equirectangular image. Owner sees: no solid white cap smearing.

Task 4: Cap mountain and deep-field angular size.
File: world.gd:768 fields(). Clamp mountain scale so length at any distance does not exceed 0.10 rad x distance. Clamp deep-field scale to 25 (50 long) and belt to 20 (40 long). Test: script 20 random battles, screenshot each, measure largest backdrop rock angle vs planet angle. Owner sees: no backdrop rock ever reads bigger than the planet. The photo in R76 is impossible.

Task 5: Station kitbash.
File: new tools/blender/hs/c20_station_kit.py modelled on c19_kit.py. Replace O1_37 reference at a4_props.gd:34 with the new kit mesh. Test: place a 5-hex station cluster, screenshot from battle camera and from edge indicator. Owner sees: a modular structure with recognisable parts, not a blob.

Task 6: Add wreckage shard variants.
File: world_living.gd:545 onward. Register 3 to 4 new shard meshes. Test: generate 5 debris hexes, screenshot each. Owner sees: more varied wreckage, less repetition.

Blender bake jobs on the owner's PC

Station kit: model in Blender using hull kit primitives, bake AO and normal maps at 2048x2048. Estimated 10 to 15 minutes on the owner's GPU.

Four new wreckage shards: model, bake AO at 1024x1024. About 5 minutes total.

These follow the existing pipeline pattern in tools/blender/hs/.

Owner questions

Q1. Planet fix path.
(a) Improve the procedural bake: fix sRGB, tune clouds, fade poles. [MY PICK]
(b) Switch to free CC0/CC BY textures from Solar System Scope and NASA.
(c) Hybrid: keep procedural base, overlay free textures for detail.

Q2. Station build method.
(a) Kitbash from the game's ship parts, following the Pyre-Barge pattern. [MY PICK]
(b) Blender procedural generation with random modules.
(c) Free CC0 model from an online library.

Q3. Backdrop angular cap.
(a) 0.10 rad: planet always at least 2.2 times any backdrop rock. [MY PICK]
(b) 0.15 rad: planet always at least 1.5 times.
(c) 0.05 rad: planet always at least 4.4 times.

Q4. Debris priority.
(a) Add wreckage variety first (new shard types). [MY PICK]
(b) Upgrade rock meshes to higher detail.
(c) Both at once.

Q5. Planet texture resolution.
(a) Keep 2048x1024, fix the colour and cloud issues first, revisit resolution later. [MY PICK]
(b) Raise to 4096x2048 now for more detail.
(c) Drop to 1024x512 to cut the 6 to 9 second bake cost.
