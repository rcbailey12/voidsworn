# Job 10 synthesis: backdrops, planets, stations, debris and scale

Chair synthesis of four blind legs (DeepSeek, Qwen, Argon, blind Rey), all run from the same evidence pack built from main on Nov 2, 2026. The complaint under study is FINDINGS R76: planets look awful next to the ships, the station reads as a blob, debris looks basic next to the improved asteroids, and a background asteroid can read bigger than the planet. Verdict: GO. Every part of the complaint has a code level cause and a bounded fix, and none of the fixes touch owner ruled ship framing.

Restoration note (issue 53): the version of this synthesis merged in PR #52 was truncated inside section 2, losing sections 3 to 6. This file is the complete text: sections 3 to 6 were rebuilt from the four filed legs and the chair settlements recorded in sections 2 and 7, and the Owner rulings section was added. Nothing in sections 1, 2, 7, or 8 changed.

## 1. Reference study (merged, chair wording)

The legs converge on one lesson from four directions: at a tactics camera, angular size is the only honest unit, and each view needs exactly one dominant body.

- Homeworld 3 (Blackbird): the biggest objects moved out of the skybox into the play area as real terrain. Co-founder Rob Cunningham told PC Gamer the megaliths began as things "painted into the sky" in Homeworld 1, sketched at a scale small ships could thread and big ships could not, and are now terrain that blocks fire and hides fleets (https://www.pcgamer.com/homeworld-3-is-blackbirds-ambitious-vision-for-a-cinematic-sci-fi-rts-that-was-utterly-impossible-to-make-20-years-ago/). Scale reads from occlusion and shared light, not raw size.
- Battlefleet Gothic: Armada (Tindalos): the cautionary case. Backdrops were praised while scale still felt wrong, because planet sized background structures dwarf the playable stations and commanded ships stop feeling huge (player discussion at https://steamcommunity.com/app/573100/discussions/0/1778261771154189912/; a review making the camera point is quoted in the Rey leg). This is the R76 photo in another game: if the backdrop holds the biggest silhouette, the fleet shrinks.
- Sins of a Solar Empire 2 (Ironclad, Stardock; the named presentation benchmark): the planet is the play area, not the backdrop. Battles happen in its gravity well, structures ring it, and Stardock's dev journal stresses planets as active map objects that orbit and change the lanes between them, with starbases riding along (https://forums.stardock.net/517899/sins-ii-dev-journal-8-an-rts-with-a-changing-map/page/1). One dominant body per view, nothing behind it competing.
- Stellaris (Paradox), for the station: Dev Diary 256, Making a Station, names the owner complaint exactly. Early shapes risked becoming "a big blob of parts," so the design got a long axis and a strong silhouette; the artist blocked it out with real ships in its slots, exported it in game early, and checked scale before detailing (https://devtrackers.gg/stellaris/p/5bdbe0ff-stellaris-dev-diary-256-making-a-station). A blobby station is a silhouette problem, fixed at blockout, not a texture problem.
- Nebulous: Fleet Command (chair note from the DeepSeek leg): a sparse backdrop with few, large, tactical objects. A quiet sky makes in play rocks and ships easier to read. Voidsworn does not need a busier sky; it needs a ruled one.

## 2. Scale plan (settled)

Ships and hexes are owner ruled and fixed: SHIP_K = 1.6 times class length (godot/render/hull_table.gd:26, applied godot/render/ship_view.gd:55); on board lengths run from Squadron 2.6 to Super dreadnought 49.6, with Frigate 10.4, Battleship 33.6 and Dreadnought 43.2. Hex corner radius HS = 10 (godot/render/board.gd:9), 20 across corners, inner radius 8.66 (godot/world/world.gd:675).

**The cap rule (chair pick): no single backdrop rock may subtend more than 0.05 rad of angular width.** The clamp is applied at spawn as max length = 0.05 times distance, inside fields() at godot/world/world.gd:768, after the existing check that keeps mountains and the deep field off the planet disc (godot/world/world.gd:751).

Why this number, against the three alternatives. DeepSeek's 0.055 rad is the same rule dressed as 0.25 times the smallest planet diameter (0.22 rad, godot/world/world.gd:334); the chair adopts its runtime check idea but keeps Rey's flat 0.05, because a flat constant is one number a future edit cannot silently break, and the margin difference (4.4x against 4.0x) is inside rounding. Qwen's 0.10 rad leaves the planet only 2.2 times wider than the biggest rock; that is the same order of read that produced the complaint, and a 2.2x margin disappears the moment a rock sits near the planet in frame. Argon's 0.022 rad (10x) overshoots: at that cap the belt and deep field shrink toward gravel, the horizon loses the mass the cinematic benchmark needs, and the sky reads empty rather than ruled. Strictness should buy a guarantee, not sterility. At 0.05 rad the guarantee is mathematical and the richness survives, because density and range span are uncapped: a mountain range may still span up to 0.15 rad in total as overlapping individually capped rocks.

Per layer numbers (proposed unless marked keep):

| Layer | Number | Rule |
|---|---|---|
| Blocker asteroids | Keep: hero rock 13 to 15 long, 2 to 4 satellites 2.0 to 4.4 (godot/world/world.gd:670) | Hero half length under hex inner radius 8.66. The detail benchmark the owner likes. |
| Debris on hexes | Keep sizes: plain 0.7 to 3.9 (godot/world/world.gd:698), living 2.6 to 7.6 (godot/world/world_living.gd:466, :545) | No piece over half the hex flat width (8.66). Largest piece today is 7.6, so the cap already holds; write it down. Mix changes are in section 4. |
| Edge scatter | Max length 20, and clamped by the 0.05 rad rule at spawn distance. Today up to about 33 long (godot/world/world.gd:768) | May beat a blocker in world units, never in angle. |
| Belt stream | Max length 30, minimum distance 600. Today up to about 75 long | Density sells a stream, not individual size. At 600 out, 30 long is exactly 0.05 rad. |
| Deep field | Move out to 800 to 1500, max length 40. Today up to about 128 long at 130 to 780 below the board | Distance first, then the clamp. Near and huge is the current fault. |
| Mountains | Max length = 0.05 times distance: 45 at 900 out, 115 at 2300 out. Today one can reach about 630 long at 900 away | Ranges may span 0.15 rad total as overlapping capped rocks, keeping horizon mass. |
| Backdrop planet | Keep: distance 3300 (godot/world/world.gd:321), angular radius 0.11 to 0.18 rad by kind (:334, :344), diameter 726 to 1180, angular diameter 0.22 to 0.36 rad | Largest single silhouette in any view. Not enlarged (Argon proposed growing it; rejected, it changes owner ruled framing to fix a rock problem). |
| Moons | Roll angular radius 0.03 to 0.04 rad (diameter 0.06 to 0.08). Today 0.012 to 0.045 rad | Trim the top, raise the floor, so the ladder never overlaps: rock 0.05 max, moon 0.06 min, planet 0.22 min. |
| Planet in the play area | Keep radius 50 and the hex footprint; sink the centre to 39 below the board so the visible cap is about 11 high and the chord about 63 across. Today centre sunk 55 percent of radius, cap 22.5 high (godot/render/board.gd:805) | See settlement below. |
| Station | Keep shipped sizing: 46 long for a cluster of 5 or more hexes, else 22 plus 4 per hex, lifted 3 (godot/render/board.gd:716, :738, :776) | Bigger than a Battleship (33.6), smaller than a Super dreadnought (49.6), never wider than its cluster. Mesh rebuilt, section 4. |
| Dead star | Keep: core radius 15, about 1.5 hex widths | Background only, no gravity mechanics, per ruling. Outside the angular ladder; check by screenshot. |

**The margin.** Today a 630 long mountain at 900 away subtends about 0.61 rad against a planet diameter of 0.22 to 0.36 rad: the rock can read about twice the planet's width. Under this plan the largest single rock is 0.05 rad and the smallest planet is 0.22 rad across, so the planet is at least 4.4 times wider than any single rock, worst pairing included, and no rock can beat a moon either (0.05 under 0.06). The R76 photo is arithmetically impossible, not just unlikely.

Play area planet, settled. Rey sinks the current sphere (cap about 11 high); DeepSeek shrinks the sphere to 70 diameter and a 12 high cap; Argon keeps the 50 radius chord and flattens to a 7.5 high cap on a 170.4 radius horizon dome; Qwen keeps it unchanged.
The chair settles on the sink: it changes one number (the centre depth at board.gd:805), keeps the radius 50 sphere and the hex footprint the map logic already uses, and lands the same read as the shrink (cap about 11 high) without touching planet radius, which other map code may lean on. The dome is new geometry bought to get a flatter cap the sink already gives. No change leaves a 22.5 high dome in the corner of the board, which is the complaint.

## 3. Planets (settled: improve the procedural bake)

**Route: improve the procedural bake, 3 legs to 1.** The game needs eight fictional looks (the palette table at godot/world/world_sky.gd:44), and photo textures cannot supply them: the free sources carry real bodies only, so a terran, a lava world, and an ice world would need three different real planets with no matching channel set across ocean, cloud, night lights, relief, and lava. The campaign map reuses this same planet system (Job 6), so one procedural fix upgrades both screens; a texture switch would have to be made twice. Argon's dissent (switch to pre-packed 4K textures, mainly to kill the 6 to 9 second bake) is carried as owner question 1. Bake cost is a separate Codex batch's problem per the brief; this job notes it and does not redesign the baker.

Licence lines for the record, if the texture route is ever taken: Solar System Scope textures are CC BY 4.0, credit line "Textures: Solar System Scope (https://www.solarsystemscope.com/textures/), CC BY 4.0"; NASA and USGS imagery is public domain, courtesy line "Imagery: NASA / USGS" (not legally required, customary). Poly Haven and ambientCG assets are CC0. None of these ship under the settled route.

**The white blotches: one ranked diagnosis, unanimous across all four legs.** The planet bakes read washed out and blotchy white, worst on terran clouds and ice. Ranked by contribution, with the fix for each:

1. **Double gamma at the store, godot/world/world_planet.gd:161.** Albedo is stored as pow(albedo, 1/2.2) and the sphere shader samples it as source_color, so the image is brightened twice; mid tones lift toward white and every pale recipe below clips early. This is the multiplier on all the others. Fix, one line, two candidate forms: drop the :161 encode, or drop source_color in the shader. Which form matches the shader's actual sampling must be settled by reading the shader (see Not checked); the test is the clipped white pixel count in task 3.
2. **Terran clouds, world_planet.gd:129.** The cloud mix runs toward (0.92, 0.94, 0.97) at 0.95 coverage, so a near white target colour covers almost the whole disc. Fix: smoothstep lower bound up to about 0.55, coverage down to about 0.75, mix target down to the 0.82 to 0.88 range, so oceans and land read through broken cloud.
3. **Ice cap pole pinch, world_planet.gd:123.** Caps mix to (0.85, 0.88, 0.92) and pinch at the poles of the 2048x1024 bake, making two bright blobs that read as damage. Fix: cap the ice albedo at 0.78 to 0.84 and soften the pinch falloff.
4. **Gas giant small storms, world_planet.gd:93.** Storm spots mix toward 0.97 white, the brightest value in the bake. Fix: tint down to 0.86 to 0.90 with a darker rim so a storm reads as a feature, not a hole.
5. **Pale ice world base, godot/world/world_sky.gd:44.** The ice look starts pale before any recipe runs. Fix: base down to the 0.68 to 0.74 range.
6. **Detail budget, amplifier only.** A 2048x1024 bake shows a 1024 px hemisphere at battle camera; at that budget the flat areas above have no texture detail to break them up. This is why the blotches read flat rather than noisy. It is an amplifier, not a cause: fixing 1 to 5 comes first, resolution is owner question 4.

Explicitly excluded: the dither at world_planet.gd:165 (plus or minus 0.5/255) is three orders of magnitude too small to make a visible blotch; all four legs rule it out.

## 4. Stations and debris (settled)

**Station: Blender kitbash from the game's own ship parts, on the Pyre-Barge pattern** (the worked kit example at tools/blender/hs/c19_kit.py). Unanimous across the legs, and the Stellaris diary in section 1 says why: the current mesh (O1_37, AI generated, godot/assets/ships/a4_props.gd:34) is a blob because it has no long axis and no silhouette, and that is fixed at blockout with real ships beside it, not with texture. Design: a spine with radial arms and berths sized off the ships that dock there, hand built bolt-ons in matched symmetric pairs, nothing aimed backward, per the ship rules. Size stays at the shipped formula (46 long for a cluster of 5 or more hexes, else 22 plus 4 per hex): bigger than a Battleship at 33.6, smaller than a Super dreadnought at 49.6, never wider than its cluster. DeepSeek's 55 and Argon's 52 both outsize a Super dreadnought and were rejected on that line. Variants are a scope call, carried as owner question 3: the chair pick is two variants from one kit (fleet station and refinery, swap parts on the same spine), modelled together in Blender job A below.

**Debris: keep the counts, raise the detail where the eye lands.** Living counts are unchanged (15 to 22 rocks plus 3 to 5 wreck pieces per hex; the plain path keeps 8 to 13). The three largest pieces per hex get full detail meshes; the _lo set stays for the small tail, which is where the poly saving actually is. Wreckage becomes a six piece ship derived set: the four existing procedural types rebuilt in Blender (hull fragment, broken frame, truss, hull section) plus an engine bell and a weapon sponson, so a wreck reads as a dead ship, not a grey rock. Long axis stays capped at 7.6 (under half the hex flat width, section 2). Tumble is capped at 0.10 rad/s, slower for larger pieces; Argon's near static 0.01 to 0.05 was rejected as making the field feel frozen.

## 5. Sequencing and cost notes

Order matters in one place: the scale clamp (task 1) and the bake fixes (tasks 3 and 4) are independent and can run in parallel, but the screenshot tests in tasks 3 and 4 should be judged after task 1 lands, because a capped sky changes what a planet screenshot is competing with. The play area sink (task 6) is one number and can land any time. The station work is the long pole: Blender job A (kit) must be approved by Ryan from its turntable render before task 8 swaps the blockout in, and task 9 (detail) follows the swap. Bake time is owned by the separate Codex batch working on the 6 to 9 second bake; nothing in tasks 3 and 4 is expected to make the bake slower except the optional 4096 step in owner question 4, which is why that step is optional and last.

## 6. Build order (Codex tasks)

1. **Angular clamp.** godot/world/world.gd:768 (fields), helper near :751: clamp every backdrop rock's length at spawn to 0.05 times its distance, with the runtime form of the check against the rolled planet diameter (smallest 0.22 rad). Test: a spawn audit over seeded battles reporting the maximum angular width per layer; none above 0.05 rad. Ryan sees: no background rock ever reads bigger than the planet again, ranges still mass on the horizon.
2. **Planet and moon ruler.** godot/world/world.gd:321, :334, :344: moons roll angular radius 0.03 to 0.04 rad (floor raised, top trimmed); backdrop planet unchanged. Test: screenshot ladder check, rock under moon under planet in the same frame. Ryan sees: a size ladder that never overlaps.
3. **Bake white fix, gamma.** godot/world/world_planet.gd:161 and the sphere shader: apply the one line form that matches the shader's sampling (drop the encode, or drop source_color). Test: no more than 2 percent clipped white pixels in a 1440p terran bake, before and after recorded. Ryan sees: planets stop washing out.
4. **Bake white fix, recipes.** godot/world/world_planet.gd:129 (clouds), :123 (ice caps), :93 (storms), and godot/world/world_sky.gd:44 (ice base), to the section 3 numbers. Optional, only if the bakes still read flat: a self authored high frequency detail tile from Blender, tiled into the bake, no licence attaches. Test: one bake per look, eight total, judged at battle camera. Ryan sees: broken cloud over visible oceans, ice that reads as ice, storms as features.
5. **Backdrop layer moves.** godot/world/world.gd:768: deep field moved out to 800 to 1500 with max length 40; belt max length 30 at minimum distance 600; edge scatter max length 20. Test: the R76 composition recreated (planet high, belt rock low in frame) as a screenshot pair, before and after. Ryan sees: a ruled sky with the fleet back on top of the size order.

6. **Play area planet sink.** godot/render/board.gd:805: centre from 27.5 to 39 below the board. Test: planet map screenshot with a Battleship beside the cap; cap height measures about 11 and the chord about 63. Ryan sees: a horizon that fits its footprint instead of a dome swallowing the corner.
7. **Debris detail pass.** godot/world/world_living.gd:466 and godot/world/world.gd:698: full detail rocks for the three largest pieces per hex, wreck set swapped in, tumble capped at 0.10 rad/s scaled by size. Test: debris hex close ups before and after on both paths, plus the no _lo mesh in the top three assertion. Ryan sees: blocker quality debris with recognisable wreckage, drifting slowly.
8. **Station blockout in game.** godot/render/board.gd:716, :738, :776 and godot/assets/ships/a4_props.gd:34: swap the blockout in for O1_37 at the shipped sizing. Test: screenshots with a Battleship (33.6) and a Frigate (10.4) alongside at both cluster sizes; no backward facing gun in the kit. Ryan sees: a long structured silhouette with berths his ships fit, not a blob.
9. **Station detail pass.** Finish the kit (panel, greeble, lights) at both sizes. Test: station maps at battle camera, all facings. Ryan sees: a finished station that belongs with his fleet.

Optional, only if task 3 and 4 screenshots still read soft: **backdrop planet bake at 4096x2048** (world_bake.gd), accepting the longer bake on the backdrop planet only; moons stay 1024x512. Owner question 4 covers this.

**Blender jobs for Ryan's PC.**

- Job A, station kit: a new script beside tools/blender/hs/c19_kit.py on the Pyre-Barge pattern, building the station of section 4 with a turntable render for Ryan's approval before the detail pass. Variant ready by construction (refinery swap parts modelled, exported only if question 3 goes that way).
- Job B, wreckage kit: six ship derived pieces (hull fragment, broken frame, truss, hull section rebuilt; engine bell and weapon sponson new) at about 2 units base size, matching the builder at godot/world/world_living.gd:545.
- No Blender job for planets: that work is GPU bake and shader code (tasks 2 to 4).

## 7. Leg screening and settlements

Planet route: settled procedural, 3 legs to 1 (section 3). Argon is drafts only on this job per the brief; its texture pick also fails the pack fit test on its own terms (real bodies only, no matching channel set), so it is carried as owner question 1 rather than adopted. Its gamma and cloud fixes agree with the other legs and are adopted through them.

Scale cap: settled at a flat 0.05 rad (section 2), against Qwen 0.10 (too loose) and Argon 0.022 (sterile). DeepSeek's runtime check against the rolled planet diameter is adopted as the test form of the same rule.

White blotch diagnosis: unanimous across all four legs, including the ranking and the exclusion of the :165 dither. Presented once in section 3.

Play area planet: settled as the sink (section 2). DeepSeek's shrink and Argon's dome both change more than the read requires; Qwen's no change leaves the complaint standing.

Station: unanimous on the Blender kitbash from the game's own ship parts on the Pyre-Barge pattern. Sizes settled at the shipped 46 formula against DeepSeek 55 and Argon 52, both of which outsize a Super dreadnought. Variants carried to owner question 3 as a genuine scope call.

Debris: settled in section 4. Rey's top three full detail rule over Argon's all full detail (same read, bounded cost); DeepSeek's six variant wreck set adopted in merged form; tumble settled at Rey's 0.10 rad/s cap against Argon's near static 0.01 to 0.05.

Qwen error, flagged: its scale table (leg section 2) lists the Frigate drawn at 16.6 and the Dreadnought at 69.1. Both contradict the pack's measured on board lengths, Frigate 10.4 and Dreadnought 43.2, which already include SHIP_K = 1.6 (godot/render/hull_table.gd:26). The leg appears to have applied the 1.6 factor a second time. Its other numbers track the pack, and neither wrong figure appears anywhere in this synthesis.

Argon notes: its reference study is impressions throughout by its own marking (browsing restricted) and was used only where another leg or the pack backs it. Its proposals to enlarge the backdrop planet (angular diameter up to 0.48 rad) and to resize hulks to 14 to 20 long are dropped: the first rewrites owner ruled framing to fix a rock problem, the second is outside the pack's scope and unbacked by it. Its near board physical rule (no rock within 300 units longer than a hero blocker) is not adopted; the angular cap already governs those distances more simply.

DeepSeek notes: its numbers track the pack throughout. One reference link it cites for Battlefleet Gothic (an api.landauinteractive.com address) does not resolve to an identifiable source from the chair side, so the synthesis relies on the Rey leg's sources for that game instead. Its high frequency detail tile idea is adopted as an optional part of build task 4 (self authored in Blender, so no licence attaches).

Rey leg notes: adopted as the spine for the cap, the play area sink and the debris mix. Its moon floor raise (0.03 rad) is adopted in section 2.

## 8. Owner questions (chair pick marked)

1. **Planet route.** A) Improve the procedural bake: the section 3 fix list, eight fictional looks kept, campaign map upgraded by the same change. (CHAIR PICK) B) Switch to pre-packed 4K free licence textures (Solar System Scope CC BY 4.0, NASA public domain): real bodies only, recognisable Earth, Mars and Jupiter cycling through battles, masks hand derived per texture, and the 6 to 9 second bake goes away. C) Hybrid: procedural for most looks, textures only for terran and the giants.
2. **Rock cap strictness.** A) 0.05 rad: the planet is always at least 4.4 times wider than any single rock, ranges may still span 0.15 rad. (CHAIR PICK) B) 0.08 rad: at least 2.75 times wider, slightly heavier horizon rocks. C) 0.022 rad (the Argon line): at least 10 times wider, emptiest sky.
3. **Station variants.** A) Two variants from one kit, fleet station and refinery, modelled together. (CHAIR PICK) B) One station, higher finish. C) One per faction, six total, as a later job.
4. **Planet detail step.** A) Stay at 2048x1024, fix gamma and recipes first, raise resolution only if screenshots still fail. (CHAIR PICK) B) 4096x2048 for the backdrop planet now, longer bakes. C) Stay at 2048x1024 no matter what the screenshots say.

## Owner rulings (Ryan, Nov 2, 2026, recorded as FINDINGS R79)

1. Planet route: A. Planets stay procedural and get the bake fixes in section 3; no photo textures.
2. Cap strictness: A. No single backdrop rock wider than 0.05 rad; the planet is always at least 4.4 times wider than any single rock.
3. Station variants: A. Two station kinds (fleet station and refinery) from one Blender kit built from the game's own ship parts.
4. Planet detail: B, against the chair pick. The backdrop planet bake goes to 4096x2048 now; moons stay 1024x512. This promotes the optional step after task 9 from conditional to scheduled: it lands with tasks 3 and 4, accepting the longer bake on the backdrop planet only.

## Not checked

- No leg or the chair opened the Godot project or ran a bake; every code claim rests on the pack's measured file:line inventory, not on a fresh read of world.gd, world_planet.gd or board.gd in this run.
- The gamma settlement (drop the :161 encode, or drop source_color) is a diagnosis with two candidate one line fixes; which one matches the sphere shader's actual sampling was not verified against the shader file, which is not in the pack.
- Solar System Scope's CC BY 4.0 status rests on the site and a third party licence audit quoted by the legs; if owner question 1 goes to B or C, the licence should be re-read on the site before any texture ships.
- Bake time effects of the section 3 fixes are argued, not measured; the separate Codex batch on bake cost owns that number.
- The station blockout proportions (spine, arms, berths) are a design proposal; no silhouette test against real ship models has been run yet.
