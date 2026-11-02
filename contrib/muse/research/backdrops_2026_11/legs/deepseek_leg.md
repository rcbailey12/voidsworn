Voidsworn visual scale, planets, stations and debris

1. Reference study

Homeworld 3. Blackbird's own Steam post says maps span about 100 km and are filled with megalithic structures that ships fly in and around, and it names planets in low orbit as one of the lighting environments. The same post stresses physically based rendering, so ships react to the scene's light instead of being flatly lit against a painted backdrop. The planet or moon is part of the scene's lighting story, not a separate wallpaper layer. The post also says the team studied Hollywood space visuals for hull paneling and small surface detail. See the developer post: https://store.steampowered.com/news/posts/?feed=steam_community_announcements&enddate=1688140850#2. Impression: Homeworld 3 sells scale by letting the player fly around big objects, not by making the backdrop object huge. The megaliths are in play and have readable surfaces at close camera range; the backdrop planet stays a mood element.

Battlefleet Gothic: Armada. The game is a 2D plane with naval-style capital ships, and its backgrounds are static matte paintings of planets, rings, nebulae and distant stars. Reviews describe the backgrounds as static and separate from the combat plane: the fights are "practically two-dimensional," and the background includes "colorful planets and nebulae" but does not become a playable object. See the review lines at https://www.api.landauinteractive.com and the 2D-plane description at https://www.pcgamesn.com/battlefleet-gothic-armada. Impression: this is the cleanest reference for the owner's complaint. The background planet is painted at a controlled angular size and can never be confused with a nearby asteroid, because the background has no 3D scale relationship with the ships at all. The cost is that the backdrop cannot be flown around.

Sins of a Solar Empire II. Ironclad and Stardock built one continuous zoom: tactical engagements at close range, then a pull-back to a strategic map where planets, moons and asteroids orbit their parent. The store page describes "instantly zoom in" and "instantly zoom back out," with every asteroid, moon and planet orbiting in a slowly changing strategic landscape. See https://www.sinsofasolarempire2.com. The art pipeline journal is a high-low bake workflow with quad topology and holding edges, aimed at crisp ship silhouettes. See https://stardock.atlassian.net/wiki/pages/viewpage.action?pageId=2161999924. Sins II also updates planet textures and clouds in patches, so planet art is treated as a live system rather than a one-off bake. See https://forums.sinsofasolarempire.com. Impression: Sins II accepts unrealistic planet-to-ship scale but keeps the planet's role consistent. The planet is a map object with a gravity well and a readable orbit, not a decorative mountain. The ruler is gameplay scale, not physical scale.

Nebulous: Fleet Command. This is a contrast case. Its store page describes 3D movement, realistic radar and sensor occlusion, and asteroids and gas clouds used as sensor cover rather than decoration. See https://store.steampowered.com/app/887570/NEBULOUS_Fleet_Command/. Impression: Nebulous keeps the backdrop sparse and makes the few large objects tactical. That is useful for Voidsworn because it shows that a tactical camera does not need a busy sky. A quiet backdrop makes the in-play rocks and ships easier to read.

The shared lesson is that scale is a relationship, not a number. Homeworld 3 keeps the big object in play and lights it. Battlefleet Gothic keeps the big object in a painted backdrop and never lets it compete. Sins II makes the planet a map object and accepts a gameplay ruler. Voidsworn currently mixes all three: a 3D backdrop planet, 3D backdrop rocks, and an in-play planet, with no single ruler. That is why a mountain can beat a planet.

2. Scale plan in game units

The rule is simple: the backdrop planet is the ruler for the sky, and the hex is the ruler for the board. Nothing in the backdrop may subtend more than one quarter of the backdrop planet's angular diameter. Nothing on the board may exceed the hex's inner radius without being an intentional hero object.

Backdrop planet angular diameter D_p rolls between 0.22 and 0.36 rad (godot/world/world.gd:321). Use the minimum, 0.22 rad, for the safety check. Maximum backdrop rock angular width = 0.25 × 0.22 = 0.055 rad. For a rock at distance d, maximum length = tan(0.055) × d, or about 0.055 × d. Because every rock mesh is 2.0 long before scaling (godot/world/rocks/rocks.json), the maximum scale is about 0.0275 × d.

Ships: Squadron 2.6 to Super-dreadnought 49.6 (godot/render/hull_table.gd:26). Fixed. Do not change.

Hex: 20 across corners, 17.32 across flats, inner radius 8.66 (godot/world/world.gd:675). Fixed. Board ruler.

Blocker hero rock: 13 to 15 long, half-length under 8.66 (godot/world/world.gd:670). Keep 13 to 15. Rule: long axis ≤ 0.75 × 20, half-length ≤ inner radius 8.66.

Blocker satellites: 2 to 4.4 long. Keep. Rule: each satellite ≤ 0.5 × hero length.

Debris, plain path: 0.7 to 3.9 long (godot/world/world.gd:698). Keep. Rule: no piece over 4.0.

Debris, living path: rocks and wreckage 2.6 to 7.6 long (godot/world/world_living.gd:545). Cap wreckage at 7.0. Rule: no debris piece over 0.81 × inner radius.

Edge scatter: up to 33 long (godot/world/world.gd:768). Clamp by distance. At 600 out, max 33. At 900, max 49.5. If closer than 600, shrink below 33.

Deep field: up to 128 long at 130 to 780 below. Clamp hard. At 130, max 7.2. At 780, max 43. Current 128 fails at every distance.

Belt stream: up to 75 long. Clamp by distance. At 1200, max 66. At 2000, max 110. Current 75 only passes if the belt sits beyond about 1364 units.

Mountains: up to 630 long at 900 to 2300 out. Clamp hard. At 900, max 49.5. At 2300, max 126.5. Current 630 is 5 to 12.7 times too wide.

Backdrop planet: angular diameter 0.22 to 0.36 rad, true diameter 726 to 1180. Keep the rolled range. Never let it fall below 0.22 rad. It is the ruler.

Backdrop moons: angular diameter 0.024 to 0.09 rad. Cap at 0.35 × D_p. With D_p minimum 0.22, max moon diameter is 0.077 rad. Current max 0.09 must shrink slightly.

Planet in play area: radius 50, diameter 100, cap 22.5 high (godot/render/board.gd:805). Change to radius 35, diameter 70, cap about 12 high. Rule: visible diameter ≤ 3.5 hex widths, cap height ≤ 0.36 × battleship length.

Station: 46 long for 5+ hexes, 22 + 4 per hex otherwise (godot/render/board.gd:716). Major station 55 long, outpost 28 long. Rule: major station ≤ 1.27 × dreadnought 43.2, outpost ≤ 0.83 × battleship 33.6.

Dead star: core radius 15, diameter 30 (godot/world/world.gd). Keep 15. Background only. Rule: no backdrop rock near it may exceed 0.055 rad.

The owner's photo becomes impossible by this margin. Today a 630-long mountain at 900 subtends about 0.61 rad of width, while the planet's diameter is 0.22 to 0.36 rad. The mountain can read 1.7 to 2.8 times wider than the planet. Under the new clamp the largest mountain at 900 is 49.5 long, subtending 0.055 rad, which is 0.25 times the smallest planet diameter. That is at least a 4:1 planet-to-rock width margin, and an 11:1 reduction in the worst mountain's angular width. No backdrop rock can read bigger than the planet because the clamp is checked against D_p at runtime, not authored by eye.

Two secondary rules keep the plan honest. First, the existing angle check that keeps mountains and deep-field rocks off the planet's disc stays (godot/world/world.gd:751), and the new angular clamp runs after it. Second, every backdrop layer must log its actual placement distance and its clamped scale at generation time, so a future distance change cannot silently break the ruler.

3. Planets: improve the procedural bake or switch to textures

The comparison. Free-licence textures are available. Solar System Scope publishes equirectangular planet maps under CC BY 4.0, based on NASA imagery, with Earth day, night, cloud, normal and specular maps, plus Jupiter, Saturn, Mars, Venus, Mercury, Uranus, Neptune, Moon and fictional dwarf planets. Licence line: "Solar System Scope textures, CC BY 4.0, https://www.solarsystemscope.com/textures/, https://creativecommons.org/licenses/by/4.0/." NASA 3D Resources is public domain and includes planetary textures and models: https://nasa3d.arc.nasa.gov/. Switching would give real surface detail at 2K to 8K, and it would remove most of the 6 to 9 second bake cost because the textures are pre-baked.

But Voidsworn needs eight fictional looks: gas giant, ice giant, terran, volcanic, barren, ice world, with palettes, rings and moon counts set per look (godot/world/world_sky.gd:44). Solar System Scope gives real planets, not those eight looks. A volcanic world would have to reuse Mars or Venus with a tint, and an ice world would reuse Europa or Pluto with a tint. The campaign map also reuses the same planet system (godot/render/board.gd:805), so a texture switch lands in two places and needs two material paths. Attribution also has to ship with the game.

Pick: improve the procedural generator. It already supports all eight looks, it is shared with the campaign map, it has no per-texture licence burden, and the white blotches are diagnosable code faults rather than a fundamental limit. The bake cost is acceptable if the fix adds only a few noise octaves. A CC0 high-frequency noise tile can be baked in Blender and multiplied into the cloud and surface detail, which gets most of the texture route's detail without giving up the fictional palette system.

White blotch diagnosis, ranked.

Double sRGB decode, the main cause. Albedo is stored as pow(albedo, 1/2.2) into an 8-bit image (godot/world/world_planet.gd:161), and the texture is declared source_color in the sphere shader. Godot decodes source_color from sRGB again on sampling. The stored values are already gamma-encoded, so the second decode lifts midtones and clips near-white values. Clouds and ice caps turn into flat white patches with lost detail. Fix: store linear albedo without the pow, or remove source_color and sample as linear. This is the first thing to change because it affects every look.

Cloud shader is too white, too broad and too low-frequency. Terran clouds use smoothstep(0.48, 0.72, fbm at low frequency) × 0.95 (godot/world/world_planet.gd:129) and mix toward vec3(0.92, 0.94, 0.97). Low-frequency fbm produces blobs, not wisps, and 0.95 coverage leaves little ground showing. Fix: add two higher-frequency octaves, raise the smoothstep lower bound to about 0.55, reduce coverage to about 0.75, and mix toward 0.82 to 0.88 instead of near-white. This is the literal white blotch on terran worlds.

Ice caps pinch at the poles. Ice albedo mixes to vec3(0.85, 0.88, 0.92) where latitude passes smoothstep(0.88, 0.94) (godot/world/world_planet.gd:123). An equirectangular bake pinches all longitudes together at the poles, so the cap becomes a bright white blob with radial stretching. Fix: fade the cap before the pole, add noise to the latitude threshold, and lower the cap albedo to about 0.78 to 0.84.

Gas giant storm cores are near-white. The five storms mix the small ones toward vec3(0.97) (godot/world/world_planet.gd:93). That is brighter than most cloud decks and reads as a white spot. Fix: tint small storm cores to 0.86 to 0.90 and add a darker rim.

Ice world base is pale and low-contrast. The base albedo is already (0.82, 0.86, 0.9) with white fracture lines. Fix: lower the base to 0.68 to 0.74 and raise fracture contrast, so the white lines read as structure instead of a blotch.

Detail budget is thin where it matters. The visible hemisphere of the 2048-wide bake is 1024 pixels across, and the sphere has 128 radial segments. The planet can fill an upper corner at 1440p or 4K. White areas have no high-frequency texture to break them up, so they read as blobs even after colour fixes. Fix: add a tiling high-frequency cloud and surface noise, and consider a 4096-wide planet bake only for the largest looks, not every moon.

Dither is minor. The ±0.5/255 dither (godot/world/world_planet.gd:165) can add noise but is not the cause of large white patches. Keep it or reduce it after the sRGB fix.

4. Stations and debris

Station. The current station is O1_37, an AI-generated objective mesh scaled by size (godot/assets/ships/a4_props.gd:34), and the ship queue marks the station as Priority 1 and "not started" for the hand-built kit pass (docs/ship_pipeline/SHIP_QUEUE.md:23). The fix is a kitbash from the game's own ship parts, using the Pyre-Barge kit (tools/blender/hs/c19_kit.py) as the worked example. This keeps the station in the same visual language as the ships and avoids a new AI blob.

The layout should be structural, not organic: a central spine 55 units long for a major station, three radial arms 20 to 30 units long, docking rings at the arm ends, exposed trusses between rings, and a dense greeble band along the spine. Reuse carrier hull sections for the spine, dreadnought truss segments for the arms, frigate engine bells as manoeuvring thrusters, and turret hardpoints from the ship library. Guns must face forward or be mounted in turrets that can traverse; no gun barrel points backward along the spine. No keel, jackstaff, bollard, crow's nest, yardarm or mast ladder. Parts must share the same panel scale and greeble density, so the station reads as one built object, not a pile.

Debris. The living path already builds wreckage from procedural shards: hull fragment, broken frame, truss and hull section, about 2 units across before scaling, scaled 1.3 to 3.8 (godot/world/world_living.gd:545). That is a good start, but the pieces are generic. Replace the generic shard with six kitbash wreck variants derived from frigate and destroyer hull sections: a torn hull plate with visible deck layers, a broken keel-less frame, a bent truss, an engine bell with a torn mount, a bulkhead with a hatch, and a half-melted armour slab. Each should be 3 to 7 units long, with jagged cut edges made procedurally in Blender. Cap the long axis at 7.0, keep 2 to 3 large pieces and 10 to 15 small pieces per debris hex, and reduce the tumble rate for large pieces to about 0.06 to 0.20 rad/s so they read as mass, not confetti.

Free models are a fallback, not the first choice. The Quaternius space station kit is CC0 and has 92 ready-to-use objects (https://gdevelop.io), but its clean, stylised look will not match Voidsworn's hull language. Blender procedural is the right tool for the jagged wreck edges, while kitbash from the game's own ship parts is the right tool for the station and the wreck hull sections.

5. Build order, Blender jobs and owner questions

Codex tasks.

Backdrop angular clamp. Change godot/world/world.gd:768 (fields()) and add a helper near the angle check at godot/world/world.gd:751. Test: log every backdrop layer's maximum angular width and assert it is at most 0.25 × planet_angular_diameter. Owner sees no background rock wider than a quarter of the planet.

Planet and moon ruler. Change godot/world/world.gd:321, :334 and :344. Test: assert planet_angular_diameter >= 0.22 and moon_angular_diameter <= 0.35 × planet_angular_diameter. Owner sees moons clearly smaller than the planet and no moon competing with it.

Planet bake white fix. Change godot/world/world_planet.gd:161, :129, :123 and :93. Test: capture a 1440p planet screenshot and check that no more than 2 percent of planet pixels are clipped white; inspect cloud edges for wisps rather than blobs. Owner sees surface detail in clouds and ice caps, with no white patches.

Play-area planet scale. Change godot/render/board.gd:805. Test: assert visible diameter is 70 units and cap height is about 12 units. Owner sees a planet dome 3.5 hexes wide, not a giant ball next to its footprint.

Station kitbash. Change godot/render/board.gd:716, :738 and :776, and build the kit in tools/blender/hs/c19_kit.py style. Test: station length 55 for a major cluster, no backward gun barrel, no naval part names in the kit. Owner sees a trussed, lit station with readable arms instead of a blob.

Debris kitbash. Change godot/world/world_living.gd:545 onward. Test: assert no wreck piece exceeds 7.0 long, six distinct variants spawn, and large pieces tumble at 0.20 rad/s or less. Owner sees recognizable hull wreckage instead of generic shards.

High-frequency planet detail tile. Optional but recommended. Bake a 2K seamless fbm cloud and surface detail tile in Blender, licence CC0, and multiply it into the cloud and albedo functions in godot/world/world_planet.gd. Test: compare variance in a clear-sky region before and after; the tile should add fine structure without adding white coverage. Owner sees texture inside clouds and on barren ground.

Blender jobs on the owner's PC.

Station kit: three variants, high-low bake to 2K normal, AO and roughness, export GLB. Estimated 2 to 4 hours.

Wreckage kit: six variants, 1K normal and AO bake, export GLB. Estimated 1 to 2 hours.

Planet detail tile: 2K seamless fbm cloud and surface mask, export PNG, CC0. Estimated 20 minutes.

Owner questions.

Planet route. A. Improve the procedural bake, keep eight fictional looks, accept about 7 to 10 seconds bake. Pick: A. B. Switch to Solar System Scope CC BY textures, lose some fictional variety. C. Hybrid: procedural base plus real textures for terran and gas giants.

Play-area planet size. A. Keep 100 diameter, 22.5 cap. B. Reduce to 70 diameter, 12 cap. Pick: B. C. Remove in-play planets entirely.

Backdrop rock rule. A. Cap backdrop rocks at 0.25 of planet diameter. Pick: A. B. Cap at 0.5. C. Remove mountains and deep-field rocks completely.

Station size. A. Keep 46. B. Major 55, outpost 28. Pick: B. C. Major 70, outpost 35.

Debris style. A. Kitbash recognizable ship wreckage. Pick: A. B. More rock debris. C. Leave the current procedural shards.
