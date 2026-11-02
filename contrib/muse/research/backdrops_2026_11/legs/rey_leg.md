# Job 10: Backdrops, planets, stations, debris and scale

Blind Rey leg. Game claims come only from the pack, cited file:line. Outside claims carry links; unverified points are impressions.

## 1. Reference study

**Homeworld 3 (Blackbird Interactive).** Its biggest objects moved out of the skybox into the play area. Co-founder Rob Cunningham told PC Gamer the megaliths began as things "painted into the sky" in Homeworld 1, sketched "Death Star sized" with gaps small ships could use and big ships could not, and are now real terrain that blocks fire and hides fleets (https://www.pcgamer.com/homeworld-3-is-blackbirds-ambitious-vision-for-a-cinematic-sci-fi-rts-that-was-utterly-impossible-to-make-20-years-ago/). Lesson: scale reads from occlusion and shared light, not raw size.

**Battlefleet Gothic: Armada (Tindalos).** The cautionary case, and the closest cousin: slow capitals, asteroid fields and debris on a flat plane. One review praised the backdrops, then said scale still does not feel right, because the camera can neither get close enough to feel ship mass nor far enough for a tactical view (https://www.chalgyr.com/2016/05/battlefleet-gothic-armada-pc-review.html?m=0). Players said the same about the sequel: planet sized background structures dwarf the playable stations, so commanded ships stop feeling huge (https://steamcommunity.com/app/573100/discussions/0/1778261771154189912/?l=dutch&ctp=1). That thread is player impression, not developer fact. Lesson: this is the owner photo in another game. If the backdrop holds the biggest silhouette, the fleet shrinks.

**Sins of a Solar Empire 2 (Ironclad, Stardock).** Sins inverts the problem: the planet is the play area, not the backdrop. Battles happen in its gravity well, structures ring it, fleets fight in its foreground, so it is always the largest thing in the well. Stardock's dev journal stresses that its planets are active map objects that orbit and change the lanes between them, with starbases riding along (https://forums.stardock.net/517899/sins-ii-dev-journal-8-an-rts-with-a-changing-map/page/1), Lesson: one dominant body per view, nothing behind it competing.

**Stellaris (Paradox), for stations.** Dev Diary 256, Making a Station, names the owner complaint exactly: early shapes risked becoming "a big blob of parts," so the design got a long axis and a strong silhouette (https://devtrackers.gg/stellaris/p/5bdbe0ff-stellaris-dev-diary-256-making-a-station). Its 3D artist blocked it out with real ships in its slots, exported it in game early, and checked scale before detailing. Lesson: a blobby station is a silhouette problem, fixed at blockout. Not a texture problem.

**EVE: Valkyrie (CCP).** Rebuilding EVE ships for close up VR, CCP's team named the core problem: with planets and stations that large nearby, players cannot tell a small near object from a large distant one (https://www.pcgamesn.com/eve-valkyrie/making-it-in-unreal-how-ccp-rebuilt-the-eve-universe-in-close-up-for-valkyrie). Impression: EVE survives planet sized backdrops because its camera is glued to one ship. A tactics camera compares everything on screen, so angular size is the only honest unit. Section 2 is built on that.

## 2. Scale plan

Units are world units. Hex corner radius HS = 10 (godot/render/board.gd:9), 20 across corners, 17.32 across flats, inner radius 8.66 (godot/world/world.gd:675). Governing rule behind the board: **no single backdrop rock may subtend more than 0.05 rad of width, or exceed one quarter of the planet's angular diameter.** Code clamps size by distance at spawn (max length = 0.05 times distance).

| Layer | Number (proposed where marked) | Rule |
|---|---|---|
| Ships | Fixed. On board 2.6 (Squadron) to 49.6 (Super dreadnought); Battleship 33.6, Dreadnought 43.2. SHIP_K = 1.6 times class length (godot/render/hull_table.gd:26, godot/render/ship_view.gd:55) | Owner ruled. Not changed. All layers size against these. |
| Hex | HS = 10, 20 across corners (godot/render/board.gd:9) | The board ruler. A frigate at 10.4 fills most of a hex; capitals overhang 2 to 2.5 hexes. |
| Blocker asteroids | Keep. Hero rock 13 to 15 long, plus 2 to 4 satellites at 2.0 to 4.4 long (godot/world/world.gd:670) | Hero half length stays under inner radius 8.66. The look the owner likes; the detail benchmark. |
| Debris on hexes | Keep sizes, change mix (section 4). Plain pieces 0.7 to 3.9 long (godot/world/world.gd:698); living shards 2.6 to 7.6 long (godot/world/world_living.gd:466, godot/world/world_living.gd:545) | No piece over half the hex flat width (8.66). Largest shard is 7.6, so the cap already holds; write it down. |
| Edge scatter | Proposed: max length 20, also clamped by the 0.05 rad rule at spawn distance | They may beat a blocker in world units, never in angle. |
| Belt stream | Proposed: max length 30, minimum distance 600, so max angle 0.05 rad. Today it runs to about 75 long (godot/world/world.gd:768) | Density sells a stream, not individual size. |
| Deep field | Proposed: move to 800 to 1500 out, max length 40, max angle 0.05 rad. Today pieces reach about 128 long at 130 to 780 below the board (godot/world/world.gd:768) | Distance first, then the clamp. Near and huge is the current fault. |
| Mountains | Proposed: max length = 0.05 times distance, so 45 at 900 out, 115 at 2300 out. Today one can reach about 630 long at 900 away (godot/world/world.gd:768) | A range may span 0.15 rad total as overlapping capped rocks, keeping horizon mass. |
| Backdrop planet | Keep. Distance 3300 (godot/world/world.gd:321), angular radius 0.11 to 0.18 rad by kind (godot/world/world.gd:334, godot/world/world.gd:344), diameter 726 to 1180, angular diameter 0.22 to 0.36 rad | Largest single silhouette in any view. Nothing behind the board within a factor of 4 of it. |
| Moons | Proposed: angular radius 0.03 to 0.04 rad, diameter 0.06 to 0.08 rad. Today radius is 0.012 to 0.045 rad, 63 to 342 across | Trim the top, raise the floor, so the ladder never overlaps: rock, moon, planet. |
| Planet in the play area | Proposed: keep radius 50, sink the centre so the visible cap is 11 high instead of 22.5; chord about 63 across. Today radius = R x 1.5 x HS + HS/2, R = 3, centre sunk 55 percent, cap 22.5 high (godot/render/board.gd:805) | Visible width near its hex footprint (3 hex widths, 60), not 100 across. Curvature stays, dominance goes. |
| Station | Keep size, rebuild mesh (section 4). 46 long for a cluster of 5 or more hexes, else 22 plus 4 per hex, lifted 3 (godot/render/board.gd:716) | Bigger than a Battleship (33.6), no bigger than its cluster is wide. Shape, not size, is its problem. |
| Dead star | Keep. Core radius 15, diameter 30, about 1.5 hex widths | Background only, no gravity mechanics, per ruling. Outside the angular ladder; check by screenshot. |

**Why the owner photo becomes impossible.** Today a 630 long mountain at 900 away subtends about 0.61 rad against a planet diameter of 0.22 to 0.36 rad: the rock can read about twice the planet's width. Under this plan the largest rock is 0.05 rad and the smallest planet 0.22 rad across, so the planet is at least 4.4 times wider than any single rock, worst pairing included. That 4.4 times margin is the guarantee. The ladder is gap free (rock 0.05, moon 0.06, planet 0.22), so a rock cannot beat a moon either.

## 3. Planets

**Pick: improve the procedural bake. Do not switch to free licence textures as the primary source.**

The free sources are legal and still fail the fit test. Solar System Scope offers sharp equirectangular textures based on NASA data, with gaps filled by fictional terrain and colours slightly saturated (https://www.solarsystemscope.com/textures/). A licence audit quoting the site records them as CC BY 4.0, credit "Textures by Solar System Scope, CC BY 4.0", licence at https://creativecommons.org/licenses/by/4.0/ (https://github.com/hotragn/hotearth/blob/HEAD/docs/PLANETS_DATA_SOURCES.md). NASA Visible Earth imagery is public domain, since NASA policy states its material is not copyright protected unless noted (https://en.wikiversity.org/wiki/File:Equirectangular-projection.jpg). But both depict real bodies, so battles would cycle a recognisable Earth, Mars and Jupiter, while this game needs eight fictional looks set per look (godot/world/world_sky.gd:44), rolled by seed. Its sphere shader also needs more than albedo: the bake packs an ocean mask, clouds, city lights, relief and lava glow (godot/world/world_planet.gd, godot/world/world.gd:338). A photo supplies none of those, so masks would be hand derived per texture, and the campaign map reuses this system, doubling the work.

**White blotch diagnosis, ranked.**

1. **Double gamma lift (most likely, systemic).** Albedo is stored as pow(albedo, 1/2.2) into an 8 bit image (godot/world/world_planet.gd:161), and the texture is declared source_color in the sphere shader, which in Godot means it is decoded from sRGB again on sampling. Pale areas brighten twice, contrast dies, near whites clip into featureless blotches. It touches every kind, matching blotches across kinds. Fix first.
2. **Terran cloud recipe.** Clouds are smoothstep(0.48, 0.72) of low frequency fbm, times 0.95 (godot/world/world_planet.gd:129), mixed toward vec3(0.92, 0.94, 0.97): high coverage, near white, low detail by construction. After cause 1, these clip hardest.
3. **Ice cap pinch.** Albedo mixes to vec3(0.85, 0.88, 0.92) past latitude smoothstep(0.88, 0.94) (godot/world/world_planet.gd:123). In an equirectangular bake all longitudes converge at the poles, so the band smears into a round white cap, not a broken ice edge.
4. **Gas giant small storms.** Small storms mix toward vec3(0.97) white (godot/world/world_planet.gd:93). Lifted by cause 1, their rims vanish and they read as pasted white spots. The rust red great storm does not suffer this: a useful control case.
5. **Detail budget (contributing, not a cause).** The visible hemisphere of a 2048 wide bake is 1024 px across, the planet can fill an upper corner of a 1440p or 4K view, and the sphere has 128 radial segments, so soft features upscale into blobs, magnifying causes 1 to 4. The dither of plus or minus 0.5/255 (godot/world/world_planet.gd:165) is ruled out: far too small.

**Improvement job, in order.** Encode albedo once. Rework clouds: raise the coverage threshold, lower mix strength, add a second higher frequency fbm octave. Break the cap edge with the same fbm. Give small storms a darker rim. Only if screenshots still read soft, raise the backdrop planet bake to 4096x2048, accepting more bake time there; bakes are cached per session by kind, seed and size, CACHE_MAX 6 (godot/world/world_bake.gd). Judge each step on the same seeded screenshots.

## 4. Stations and debris

**Station: kitbash from the game's own ship parts in Blender, following the Pyre Barge kit method.** The current mesh is O1_37, an AI generated objective mesh (godot/render/board.gd:738, godot/assets/ships/a4_props.gd:34). The station is Priority 1, "not started," in the kit queue (docs/ship_pipeline/SHIP_QUEUE.md:23), whose worked example is the Pyre Barge kit (tools/blender/hs/c19_kit.py). Build it the Stellaris way: blockout, in game check, detail last. A central hub, one long docking spine (the axis that kills the blob read), two or three arms ending in ship sized berths, a ring segment, a sensor cluster at one pole. Reuse hull panels, turret bases, engine bells and trusses from the ship kit, one material set. Ship rules bind: a space station, not a naval ship (no keel, jackstaff, bollards, crow's nest, yardarms or mast ladders); parts that belong together; guns keep their facing, firing outward, never backward. Park a Battleship (33.6) and Frigate (10.4) beside the blockout before detailing. Two variants from one kit (fleet, refinery) cost little. Free models rejected: none licence clean matches this style.

**Debris: upgrade the living look, no new system.** The default "cine" look already builds 15 to 22 rocks per hex plus 3 to 5, sometimes 6, wreckage shards (hull fragment, broken frame, truss, hull section) at 2.6 to 7.6 long, plus dust (godot/world/world_living.gd:466, godot/world/world_living.gd:545). It reads basic because low detail "_lo" meshes are used whenever scale is under 1.2, which is most pieces, while blockers get full detail meshes, and because the plain path tumbles pieces at 0.06 to 0.35 rad/s (godot/world/world.gd:698), fast enough to read as toys. Fixes: full detail rocks for the three largest pieces per hex, "_lo" only for the small tail; rebuild the four shard types in Blender from real ship hull sections, with bent frames and a turret or engine part attached, so wreckage reads as dead ships; cap tumble at 0.10 rad/s, slower for larger pieces. Hulks already use real ship hulls (godot/render/board.gd, _hulk) and prove this reads well: debris should look like a hulk that came apart.

## 5. Build order

One change, one check, one visible result each.

1. **Angular cap.** godot/world/world.gd:768 (fields()): clamp every backdrop rock to max length = 0.05 times spawn distance, move the deep field to 800 to 1500 out, keep the disc check at godot/world/world.gd:751. Test: assert across 20 seeds, no rock over 0.05 rad. Owner sees: the planet is the biggest thing in the sky, every screenshot.
2. **Moon ladder trim.** godot/world/world.gd:321, godot/world/world.gd:344: roll moon radius at 0.03 to 0.04 rad. Test: seeded screenshots, moons against the planet disc. Owner sees: moons smaller than the planet, larger than any rock.
3. **Planet gamma fix.** godot/world/world_planet.gd:161: encode albedo once, matched to sampling. Test: same seed terran, gas giant and ice world before and after, plus a mid grey patch that must hold its value. Owner sees: darker oceans, real contrast, whites with detail.
4. **Cloud, cap and storm rework.** godot/world/world_planet.gd:129 (threshold, strength, second fbm octave), godot/world/world_planet.gd:123 (broken cap edge), godot/world/world_planet.gd:93 (storm rims). Test: seeded close ups at battle camera. Owner sees: edged clouds, broken ice shores, rimmed storms.
5. **In play planet sink.** godot/render/board.gd:805: sink the centre until the cap is 11 high. Test: planet map screenshot, Battleship beside the cap. Owner sees: a horizon fitting its footprint, not a dome swallowing the corner.
6. **Debris detail pass.** godot/world/world_living.gd:466: full detail rocks for the three largest pieces per hex, capped tumble; same cap at godot/world/world.gd:698. Test: debris hex close up, before and after. Owner sees: blocker quality debris, drifting slowly.
7. **Station blockout in game.** godot/render/board.gd:716: swap the blockout in for O1_37 at existing sizing. Test: screenshot, Battleship and Frigate alongside. Owner sees: a long structured silhouette, not a blob.
8. **Station detail and variant.** Finish the kit pass, add the refinery variant. Test: both variants in game, all facings. Owner sees: two stations that belong with his ships.

**Blender bake jobs for the owner's PC.** Job A: station kit build, a new script beside tools/blender/hs/c19_kit.py, exporting both variants with a turntable render for approval first. Job B: debris shard set, four ship derived pieces at about 2 units base size, matching the builder at godot/world/world_living.gd:545. Job C: none for planets; that work is GPU bake and shader code (tasks 3 and 4).

**Owner questions (pick marked).**

1. Rock cap: A) 0.05 rad, planet at least 4.4 times wider than any rock (PICK). B) 0.08 rad, at least 2.75 times wider. C) Cap clusters only, hero rocks to 0.12 rad.
2. In play planet: A) Sink the current sphere, cap 11 high, chord about 63 across (PICK). B) Shrink the sphere to radius 35. C) Keep the dome.
3. Planet detail: A) Stay at 2048x1024, fix gamma and recipes first, raise resolution only if screenshots still fail (PICK). B) 4096x2048 for the backdrop planet now, longer bakes. C) Stay at 2048x1024 no matter what.
4. Station variants: A) Two from one kit, fleet and refinery (PICK). B) One station, higher finish. C) One per faction, six total, as a later job.
5. Mountain ranges: A) Ranges from capped rocks, total span up to 0.15 rad (PICK). B) Single capped rocks only. C) Remove mountains entirely.
