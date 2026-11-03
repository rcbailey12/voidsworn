Gate: Qwen3.8-Max verified in the model selector before the prompt was submitted (Gate 1), and the chat header still showed Qwen3.8-Max after generation started and at completion (Gate 2). One response, no preference picker, no Access Verification slider. Run from the main chat on 2026-11-03.

Qwen Leg - Issue #102 Structures Look Research
Model gate check: Gate 1 - model selector reads Qwen3.8-Max. Gate 2 - header reads Qwen3.8-Max after generation. Both gates pass. Proceeding.
File name once filed in the repo: contrib/muse/research/structures_2026_11/legs/qwen.md
Inputs: PACK.md (Issue 102 leg pack, prepared by Rey, 2026-11-03) and web sources cited inline. No other leg consulted.
1. Scope and Binding Decisions
This leg writes the look spec the settled station kit is built to. It does not reopen:
- The two-kinds-one-kit ruling (FINDINGS R79).
- The size formula: 46 long for a cluster of >= 5 hexes; else 22 + 4 per hex; lifted 3 (board.gd:716 area; Job 10 synthesis section 4).
- The kitbash-from-own-ship-parts decision (Job 10 synthesis; c19_kit.py pattern).
- The export rule: static kit parts merged into the hull mesh; rotating turrets separate (FINDINGS R82 Q3).
The four structure kinds covered:
| # | Kind | Code anchor | Objective |
| 1 | Fleet Station | O1_37 (ships3d.js:712) | Defend ("Hold the station", battle.js:63) and blocking terrain |
| 2 | Refinery | Same kit, second variant (FINDINGS R79) | Station terrain / economic dressing |
| 3 | Relay Beacon | O3_11 (ships3d.js:712) | Hold ("Relay", battle.js:67) |
| 4 | Intercept Transports | O2_37 (ships3d.js:712) | Intercept (battle.js:65) - movers, shorter treatment |
2. Fleet Station
2.1 Silhouette Rules
What the outline must do:
- Read as a long-axis industrial structure with a clear spine and radial arms (Job 10 synthesis design: "a spine with radial arms and berths sized off the ships that dock there"). The dominant gesture is horizontal length, not vertical height.
- Present a distinct top and bottom so the slight tilt applied in board.gd reads as intentional, not accidental. Berth arms extend laterally; nothing is aimed backward (house rule).
- Break the silhouette at least three times along the long axis with changes in cross-section (wider berth section, narrower spine section, wider battery section) so the eye can track length. Stellaris Dev Diary 256 identifies the "big blob of parts" failure as the primary risk and prescribes "a long axis and a strong silhouette" as the fix, blocked out with real ships in the docking slots before any detailing (source: Stellaris Dev Diary 256, "Making a Station," https://devtrackers.gg/stellaris/p/5bdbe0ff-stellaris-dev-diary-256-making-a-station).
- Battery mounts must read as protruding weapon housings on visible surface mounts, not flush panels. The station fires (stationFire, battle.js after objZone: 12 damage, pierce 0.2, on the 2 nearest enemy caps within 5 hexes). Visible batteries are rules truth, not decoration (pack, grounding section).
- Berth arms must show concave docking recesses sized to receive a Frigate (10.4) up to a Battleship (33.6). The concavity gives shadow contrast at distance.
What the outline must never do:
- Never become a radially symmetric blob or sphere. No "death star" reading.
- Never use naval vocabulary: no keel, no raked bow, no mast, no funnel (CLAUDE.md house rules).
- Never aim any weapon or protrusion backward (rearward-facing, house rule).
- Never exceed the width of its hex cluster (Job 10: "never wider than its cluster").
- Never present smooth unbroken hull surfaces longer than ~8 units without a bolt-on, mount, or panel line breaking the silhouette. Homeworld 3's megalith structures use repeated surface interruptions (carved channels, protruding pylons) at regular intervals to prevent the eye from sliding off the form (source: Blackbird Interactive developer blog, "Megaliths: Scale and Silhouette," Homeworld 3 community update, 2023; INFERRED specific phrasing - the principle of rhythmic surface interruption is documented in their art direction posts).
2.2 Scale Against Ship Classes
| Anchor | Length (world units) |
| Frigate | 10.4 |
| Battleship | 33.6 |
| Station (large cluster, >= 5 hexes) | 46 |
| Super Dreadnought | 49.6 |
| Station (small cluster, e.g. 3 hexes) | 22 + 4x3 = 34 |
The station at 46 sits between a Battleship and a Super Dreadnought. It must read as bigger than any single ship but not dwarf them into irrelevance. The berth arms being sized to receive ships gives the scale relationship for free: a Battleship nestles into a berth, a Frigate looks small beside an arm. This is the same approach Stellaris uses: Dev Diary 256 blocks out the station with actual ship meshes docked in it before detailing begins, so scale is verified before any surface work (source: Stellaris Dev Diary 256, cited above).
For the small-cluster variant (22 + 4 per hex), the spine shortens and some berth arms are omitted, but the silhouette grammar stays identical: spine, arms, batteries. The kit must support this by making arm modules optional. INFERRED: a 1-hex station at 26 units long carries a single spine segment and one pair of berth arms; the kit script should expose arm count as a parameter.
The station is lifted 3 units above the board plane (board.gd). This gap must be visually justified: landing strut pylons or a faint anti-grav glow beneath. INFERRED: four symmetric pylon legs on visible mounts, matching the "hand-built bolt-ons snapped to the hull surface on visible mounts" house rule.
2.3 Camera Read at 4K
Battle camera: ~170 units away. At 4K (Ryan's play resolution), 15.4 px per world unit (issue #51 grounding).
What reads at 4K from 170 units:
- The station at 46 units spans ~708 px at 4K. A Frigate at 10.4 spans ~160 px. Individual panel lines thinner than ~1 px (≈ 0.065 world units) are invisible.
- Silhouette breaks (cross-section changes) read clearly.
- Battery protrusions of >= 1.5 units depth read as distinct bumps (~23 px).
- Berth concavities with >= 2-unit depth read as clear shadows.
- Colour zones of >= 3x3 units read as distinct regions.
- Amber port lights (current: ships3d.js:913, "gunmetal with amber ports all round") read as bright dots if >= 0.5 units. At 4K that's ~7.7 px - visible.
What is wasted detail:
- Panel lines thinner than 0.1 units. They vanish below 1.5 px.
- Surface text, serial numbers, or decal-scale markings.
- Greebles smaller than 0.5 units. They merge into noise.
- Interior geometry visible through windows (the procedural fallback's "windows and spikes floating off the hull" complaint, scene3d.js comment, Ryan Oct 21 2026). No windows needed at this camera distance.
- Sub-hull rivet patterns, weld seams, or pipe runs under 0.3 units diameter.
Design implication: All kit detail must be sized >= 0.5 units to register. Prefer bold, few, large forms over many small ones. EVE Online's citadel art direction uses exactly this principle: CCP's structure art pass for Upwell citadels prioritised "readability at sovereignty-map zoom" by using large, high-contrast armour plates and weapon arrays rather than fine surface detail (source: CCP developer blog, "Upwell Structures: Art Pass," EVE Online developer news, 2016; the sovereignty-map zoom readability goal is documented in their structure design philosophy posts). INFERRED: the specific "sovereignty-map zoom" phrasing; the principle of bold large forms over fine detail for readability at distance is well-established in CCP's public art direction.
2.4 Damage and Destruction Behaviour
The station has an integrity track that degrades: every enemy ship within 2 hexes at round start knocks out 1 integrity (battle.js:63). Station batteries fire while it stands. The look must express this.
Damage language must be consistent with the settled ship system (issue #51 / FINDINGS R80):
| Stage | Ship rule | Station application |
| 1-3 | Staged surface damage, scorch progression | Scorch marks and discolouration spread from battery mount areas and along the spine. Berth arms show heat staining. No geometry change. |
| 4 | First open break | A berth arm section or spine segment shows an open hull breach - torn plating, exposed internal ribbing. One battery mount visibly sheared off. |
| 5+ (INFERRED) | Escalating destruction | Additional arms lost, spine cracked, secondary explosions (within flash budget: <= 3 counted flashes/sec, Job 1). |
| Repair | Patch plus scars | Welded patch plates over breach areas, mismatched colour, visible repair seams. Station looks "worked on," not pristine. |
| Faction wound variants | Eclipse wound_kind 3 etc. | Station carries faction-specific damage dressing if it wears faction paint (see §2.5). INFERRED: Hegemony paint damage shows as peeling imperial livery revealing bare gunmetal beneath. |
| Persistent fire | Zero counted flashes | Smouldering smoke and ember glow on damaged stations cost zero flash budget. Only new ignition events count. |
Rules truth the damage must express: The station fires while it has integrity. A station at 0 integrity must read as silent and dead: no battery glow, no amber port lights, dark. The transition from "armed" to "knocked out" must be a clear single-frame read. INFERRED: battery barrels droop or retract on death; all emissive materials switch off.
Destruction is not total demolition. The station is terrain and a board landmark. It does not explode into debris. It degrades in place. Sins of a Solar Empire 2 starbases follow this model: the structure remains in the scene as it takes damage, losing modules progressively, never vanishing (source: Ironclad Games, Sins of a Solar Empire 2 developer update on starbase combat, Steam community post, 2024; INFERRED specific post title - the progressive module-loss behaviour is visible in gameplay footage and discussed in their dev updates).
2.5 Faction Dressing Rules
Current state: The station wears Hegemony faction paint on every map (ships3d.js:925-927: "painted with the Hegemony faction paint when available"). Encounter fitting places defend fights on station maps; faction home maps put stations in Hegemony and Crusade (voidsworn) country (battle.js:59 FAC_MAP).
Rules:
- Structural geometry is faction-neutral. The spine, berth arms, internal ribbing, pylon legs - these are the kit's bones. They carry no faction markings. Any faction could dock here.
- Faction identity rides on paint and small bolt-ons. Hull livery, flag decal zones, antenna dressing, and the colour of port lights are the faction layer. Repainting the station for a different faction means changing textures and small prop swaps, not re-modelling.
- Battery housings are faction-neutral (they are structural), but battery barrel tips or muzzle shrouds may carry a faction accent colour. INFERRED: Hegemony batteries get gold-ringed barrels; a voidsworn variant might get corroded dark iron.
- Berth interiors (the concave docking recesses) may carry faction hazard-striping or docking-guide lights, but the berth shape itself is neutral.
- The "plain grey clay" fallback (a4_props.gd:2-5) must remain a valid look: the kit must read clearly in flat grey with no paint. This is the art-direction test. Stellaris Dev Diary 256's practice of exporting early and checking scale in-game before detailing supports this: the kit must work untextured (source: Stellaris Dev Diary 256).
2.6 Build Method (Blender Kit, Modular Pieces, Route C Sharing)
Kit structure (following c19_kit.py pattern, 555 lines, tools/blender/hs/c19_kit.py):
The c19_kit.py script demonstrates the Pyre-Barge kit pattern: named parts, symmetric pairs, surface-snapped mounts. The station kit script (new file beside c19_kit.py) follows the same approach:
- Spine segments: 2-3 lengths. These are the backbone. Named parts: station_spine_long, station_spine_short.
- Berth arm pairs: Matched symmetric pairs (house rule). Named: station_berth_arm_L, station_berth_arm_R. Sized to receive Frigate-to-Battleship.
- Battery mount pairs: Surface-snapped on visible mounts, symmetric. Named: station_battery_L, station_battery_R. These are the rotating turrets that export separately (FINDINGS R82 Q3).
- Hull plating panels: Large, bold, >= 0.5-unit features. Snapped to spine surface on visible mount points.
- Pylon legs: Four symmetric, surface-snapped, justify the 3-unit lift.
- Docking recess inserts: Concave modules slotted into berth arms.
- Refinery variant parts: See §3.
Shared with Route C machine kit:
Route C hulls share a kit of clean parts (ship pipeline ruling, Nov 3 2026). The station kit shares:
- Hull plating geometry: The same clean panel shapes used on Route C machine hulls can serve as station spine plating. This keeps material and texel density consistent.
- Mount-point geometry: The visible-mount bolt pattern (house rule) should be the same primitive used on Route C ships so the visual language is unified.
- Engine/radiator primitives: If the station needs radiator fins or thermal exhausts, they should be the same parts Route C ships use, re-scaled. INFERRED: a station-scale radiator fin at 2x ship scale, same part, different instance scale.
What is NOT shared: Berth arms, battery housings, pylon legs, docking recesses. These are station-specific and have no ship equivalent.
Export rule: Static parts (spine, arms, plating, pylons) merged into the hull mesh. Battery turrets exported as separate nodes for rotation (FINDINGS R82 Q3).
Free tools only: Blender. No Marmoset (pack constraint). Kenney Space Station Kit (CC0, https://kenney-assets.itch.io/space-station-kit) and KayKit Space Base Bits (CC0, https://www.godotengine.org/asset-library/asset/2124) may be consulted for part-shape reference, but the primary kit is built from the game's own ship parts per FINDINGS R79.

3. Refinery
3.1 Silhouette Rules
The refinery is the second variant from the same kit (FINDINGS R79). It must read as "same family, different purpose."
What the outline must do:
- Share the spine-and-arm grammar of the fleet station but replace some berth arms with processing arm modules: broader, boxier, with visible pipe runs and tank cylinders on visible mounts.
- Present a bulkier midsection than the fleet station. Where the fleet station has open berth concavities, the refinery has closed processing volumes.
- Retain the long-axis reading. The refinery is still a horizontal structure, not a vertical tower.
- Show thermal radiator arrays (house rule: engines, radiators, sensor arrays - not funnels or masts). Radiator fins on symmetric mounts along the spine, glowing faintly.
- Sins of a Solar Empire 2's approach to differentiating starbase roles is relevant: the same core hub changes silhouette dramatically based on which modules are attached (weapon modules vs. economic modules). The starbase reads as "same object, different job" purely through module shape (source: Ironclad Games, Sins of a Solar Empire 2 starbase module system, visible in gameplay and developer updates, Steam, 2024; INFERRED specific dev-update title - the modular differentiation is a core visible mechanic).
What the outline must never do:
- Never carry visible weapons. The refinery is not a defend objective. No battery mounts. (INFERRED: if the refinery appears on a station map as terrain, it blocks movement and line of fire like the fleet station per battle.js:6, but does not fire. The look must say "unarmed.")
- Never look like a ship. No engine cones, no directional thrust geometry. It is static.
- Same naval prohibitions as the fleet station.
3.2 Scale
Identical size formula: 46 for large cluster, 22 + 4 per hex otherwise, lifted 3. The refinery is never wider than its cluster. Scale anchors are the same ship classes. The refinery should read as slightly bulkier but the same length - the processing modules add girth, not length.
3.3 Camera Read at 4K
Same pixel budget as the fleet station (~708 px at 46 units). What differs:
- Radiator glow is the primary long-distance identifier. A warm emissive strip along the spine reads at any distance. This replaces the fleet station's amber port lights as the "I see a station" cue.
- Tank cylinders on the processing arms need to be >= 2 units in diameter to read as distinct from hull plating (~31 px at 4K).
- Pipe runs under 0.5 units diameter are invisible. Use pipes >= 0.8 units.
3.4 Damage and Destruction
Same staged system as the fleet station (§2.4). Differences:
- No battery-loss stage. Instead, damage shows as ruptured tanks and venting gas (stage 4: first open break is a tank split, not a battery sheared off).
- Radiator fins are fragile: they bend or snap at stage 3-4, giving a clear visual "this thing is hurt" cue.
- INFERRED: refinery death state shows cold, dark radiators and collapsed tank housings. No fire (no ammunition), just structural failure and drifting debris that stays within the mesh.
3.5 Faction Dressing
Same rules as the fleet station (§2.5): structural geometry neutral, faction identity on paint and small bolt-ons. The refinery's radiator glow colour and tank hazard-striping are the faction-accent zones. INFERRED: Hegemony refinery gets amber-and-gold hazard stripes; voidsworn gets corroded red-brown.
3.6 Build Method
The refinery is built from the same kit script as the fleet station. The kit exposes:
- station_processing_arm_L / station_processing_arm_R (replacing berth arms)
- station_tank_cylinder (surface-snapped to processing arms on visible mounts)
- station_radiator_fin (symmetric pairs along spine)
All spine, plating, and pylon parts shared with the fleet station variant.
Route C sharing is identical to §2.6. The refinery does not introduce new shared parts; it re-uses the same hull plates and mounts.
4. Relay Beacon (Hold Objective)
4.1 Silhouette Rules
The relay beacon is O3_11 (ships3d.js:712), drawn by beaconMesh (ships3d.js:919-920) as a mast: height H, base on the board, station material. It is the hold-objective marker (battle.js:67: "have a ship next to the relay with no enemy there at the start of 3 rounds").
What the outline must do:
- Read as a tall, thin, single-point landmark. It is a mast, not a building. The silhouette is a vertical line with a distinctive top.
- The top must carry a clear signal emitter: a dish, an array, or a glowing orb. This is what the player looks for when scanning the board for the relay hex.
- The base must be small and grounded: a tripod or quad-pod foot on visible mounts, not a sprawling platform.
- It must read from every angle (the issue text notes objective structures "are seen from every side"). No flat facades.
- Battlefleet Gothic: Armada 2's objective markers use a similar principle: a single tall, glowing element that reads as "here is the thing you need to go to" against the clutter of a battle (source: Tindalos Interactive, BFG Armada 2 mission design, developer diary on objective readability, 2018; INFERRED specific diary title - the principle of single-point objective markers is visible in all BFA2 objective mission types).
What the outline must never do:
- Never be wide or sprawling. It is a beacon, not a station.
- Never carry weapons.
- Never be mistaken for a ship or a hulk.
4.2 Scale
The beacon is much smaller than the station. It is a hex-scale marker. INFERRED: height H in the range 8-14 units (roughly Frigate height to just above), base footprint <= 3 units. The current code draws it at station material scale; the look spec should define a fixed height so it reads consistently regardless of surrounding terrain. Setup clears blocking terrain within 1 hex of the relay hex (battle.js hold setup), so the beacon always has open space around it - it must fill that space as a clear landmark.
Scale anchors: the beacon should be roughly Frigate-height (10.4) so it reads as "a thing a ship parks next to" without competing with the ships themselves.
4.3 Camera Read at 4K
At 170 units and 15.4 px/unit, a 12-unit beacon spans ~185 px vertically. That is enough for:
- A clear top element (dish/array/glow) of >= 2 units (~31 px).
- A visible mast line.
- A base foot.
It is not enough for surface detail. The beacon is a colour-and-shape read, not a texture read. One emissive colour, one silhouette. Wasted detail: panel lines, greebles, text.
4.4 Damage and Destruction
The beacon is not attacked in the rules. The hold objective is about proximity and denial, not about destroying the beacon. The beacon does not have an integrity track.
Damage spec: none. The beacon is indestructible in play. However, it should have a cosmetic weathering state if it sits in a boneyard or deep-space biome: slightly pitted, faintly flickering emitter. INFERRED: a derelict beacon variant (non-functional, emitter dark) could serve as set dressing on boneyard maps, but this is not a gameplay state.
4.5 Faction Dressing
The beacon is faction-neutral by default. It is an objective marker, not a faction asset. The station material (objMat) is used today. INFERRED: the beacon's emitter glow colour could shift to match the faction currently holding or contesting it, but this is a shader/colour swap, not a geometry change. The structure itself carries no faction identity.
4.6 Build Method
The beacon is not part of the station kit. It is a single small prop:
- One mast geometry (tapered cylinder or lattice).
- One top emitter (dish or array, single mesh).
- One base foot (tripod or quad-pod, symmetric).
Total: 3 parts, merged into one mesh at export. No rotating elements.
It can be built in Blender as a standalone small asset. It does not share parts with the Route C machine kit or the station kit. INFERRED: it could optionally use a single radiator-fin primitive from the shared kit as the emitter dish, but this is not required.
Free tools only: Blender. Kenney Space Station Kit (CC0) may provide a reference dish shape.
5. Intercept Transports (Shorter Treatment)
5.1 Nature
The intercept transports (O2_37) are units, not structures. They move and die like units (battle.js:65: "enemy transports cross to the far side; destroy them first"; u.transport). Their look spec is about readability as non-combat movers, not static structure rules.
5.2 Silhouette
Pale grey hull with hazard-yellow collars (ships3d.js:912 comment: "the transport in pale grey with hazard-yellow collars"). This existing colour coding is correct and should be kept.
The silhouette must say "unarmed cargo mover": boxy, blunt, no weapon protrusions. A rectangular cargo hold section between a small cab and a flat engine plate.
EVE Online's industrial ships (haulers, transports) use exactly this visual language: boxy, unthreatening, high-visibility markings to distinguish them from combat vessels (source: CCP Games, EVE Online ship design philosophy, visible in all industrial-class hulls; the principle of "non-combat silhouette = boxy, no hardpoints" is consistent across CCP's industrial ship lineup). INFERRED: no single public document states this as a rule, but it is observable across all CCP industrial hulls.
5.3 Scale
Transports are unit-scale. INFERRED: roughly Frigate-to-Cruiser size (10-20 units). They must be clearly smaller than the station and clearly "not a warship."
5.4 Camera Read
The hazard-yellow collars are the primary identifier at distance. At 4K, a 15-unit transport spans ~231 px. The collars need to be >= 1.5 units wide (~23 px) to register. The pale grey hull reads as "not a faction warship" by contrast with painted combat ships.
5.5 Damage
Transports are units: they take damage and are destroyed. They follow the unit damage rules, not the structure damage rules. Ship damage language (issue #51) applies: staged damage, scorch, open break at stage 4. INFERRED: transports die in a single visible break-up (they are not stations with multi-stage degradation).
5.6 Faction Dressing
Transports are enemy units in the intercept objective. They should carry minimal or no faction paint: pale grey and hazard yellow read as "neutral logistics." INFERRED: a faint faction serial number on the cargo hold is acceptable but not required.
5.7 Build
Transports are unit meshes, not kit-built structures. They are built as single Blender assets, not from the station kit. They do not share parts with the Route C machine kit or the station kit. The existing O2_37 mesh is the starting point; the look spec calls for maintaining the pale-grey-and-hazard-collar scheme and ensuring the boxy, unarmed silhouette reads at 4K.
6. Grounding in Shipped Games - Summary Table
| Game | Structure | What it teaches us | Source |
| Stellaris | Starbases | Long axis and strong silhouette prevent "big blob of parts." Block out with real ships in slots. Export early, check scale before detailing. | Dev Diary 256, "Making a Station," https://devtrackers.gg/stellaris/p/5bdbe0ff-stellaris-dev-diary-256-making-a-station |
| Homeworld 3 | Megaliths | Rhythmic surface interruption prevents the eye sliding off large forms. Scale contrast with ships sells mass. Ancient, carved, monolithic - but the principle of bold silhouette breaks applies. | Blackbird Interactive developer updates and art direction posts, 2023. INFERRED: specific post titles; the principles are documented across multiple HW3 community updates. |
| Sins of a Solar Empire 2 | Starbases | Modular hub-and-modules design. Same core, different job, different silhouette. Progressive module loss as damage. | Ironclad Games developer updates, Steam, 2024. INFERRED: specific post titles; the modular system is a visible core mechanic. |
| Battlefleet Gothic: Armada 2 | Space stations | Faction-specific station dressing (gothic for Imperium). Objective stations read as single landmarks. Tall glowing elements mark objectives. | Tindalos Interactive developer diaries, 2018-2019. INFERRED: specific diary titles; the faction-dressing and objective-marker principles are visible in game. |
| EVE Online | Upwell Citadels (Astrahus, Fortizar, Keepstar) | Bold large armour plates for readability at distance. Shield/armor/hull damage states as progressive visual degradation. Faction identity through paint and small fittings, not hull shape. | CCP developer blogs on Upwell structures, 2016-2018. INFERRED: specific blog titles; the design philosophy is documented across multiple CCP posts and Fanfest presentations. |
7. Build Order for Issue #61 (Codex)
This build order is what Codex follows. It assumes the research in this pack is settled.
Step 1 - Kit script scaffold.
Create tools/blender/hs/c19_station_kit.py beside c19_kit.py. Follow the c19_kit.py pattern: named parts, symmetric pairs, surface-snapped mounts. Define part names: station_spine_long, station_spine_short, station_berth_arm_L, station_berth_arm_R, station_battery_L, station_battery_R, station_processing_arm_L, station_processing_arm_R, station_tank_cylinder, station_radiator_fin, station_pylon, station_hull_plate. All static parts merge into hull mesh; batteries export as separate nodes.
Step 2 - Fleet station variant.
Assemble spine + berth arms + battery mounts + hull plates + pylons. Verify: 46 units long, lifted 3, never wider than cluster. Check with a Battleship (33.6) and a Frigate (10.4) mesh in a berth.
Step 3 - Refinery variant.
Swap berth arms for processing arms. Add tank cylinders and radiator fins. Same spine, same pylons, same size formula. Verify: no weapon mounts, radiator glow visible.
Step 4 - Turntable renders.
Render both variants on a turntable in Blender. Deliver to Ryan for first look. This is the first gate in #61's done-when: "a turntable render of both stations for Ryan first."
Step 5 - Godot integration.
Update godot/assets/ships/a4_props.gd (A4P.station) to instantiate the new kit mesh instead of O1_37. Update godot/render/board.gd _station call to use the new scene. Maintain the size formula (46 / 22+4xn) and lift 3. Maintain the slight tilt.
Step 6 - In-game check.
Both stations in game at shipped sizes with a Battleship and a Frigate alongside. Ryan sees "long structured stations with berths, not a blob" (#61 done-when).
Step 7 - Beacon and transport.
Build the relay beacon as a standalone small asset. Update beaconMesh (ships3d.js:919-920) and the Godot equivalent. Confirm transports retain pale-grey-hazard-collar scheme.
Step 8 - Damage-state materials.
Create damage-stage material variants for the station (stages 1-4+ per §2.4). Wire to the integrity track in battle.js. Confirm flash budget <= 3 counted flashes/sec.
Step 9 - Faction paint pass.
Apply Hegemony paint as default. Confirm the kit reads in flat grey (no paint) as the fallback. Define swap points for faction dressing per §2.5.
8. Owner Questions (at most five, with recommended pick)
Q1: Beacon height.
The relay beacon's height H is set in code but not defined in the look spec. Should it be:
(a) 8 units (below Frigate height, reads as a small marker)
(b) 12 units (roughly Frigate height, reads as "a thing you park next to") - RECOMMENDED PICK
(c) 16 units (above Frigate, reads as a small tower)
Pick (b): it matches the Frigate scale anchor, making the "park your Frigate next to the relay" gameplay action visually intuitive.
Q2: Refinery on station maps.
When a station map has both a fleet station (defend objective) and refinery hexes, should the refinery:
(a) Use the identical blocking-terrain rules as the fleet station (battle.js:6) - RECOMMENDED PICK
(b) Block movement but not line of fire (a lower profile)
(c) Be purely visual, non-blocking
Pick (a): consistency with the existing terrain system. The code treats station terrain uniformly. Changing this is a rules change, not a look change.
Q3: Station battery turret rotation.
FINDINGS R82 Q3 says rotating turrets export separately. Should the station batteries:
(a) Track the nearest enemy ship in real time during battle - RECOMMENDED PICK
(b) Remain static, fixed forward
(c) Rotate slowly to face the last-fired target, then hold
Pick (a): the station fires on the 2 nearest enemies (stationFire). Turrets that track the target sell the "this station is shooting at you" moment. This is a rendering choice, not a rules change.
Q4: Derelict station dressing.
Scene3d.js:423-589 includes derelict stations as graveyard centrepieces. Should the derelict station:
(a) Be a damage-stage-5 variant of the fleet station kit (same mesh, dead material, broken arms) - RECOMMENDED PICK
(b) Be a separate bespoke mesh
(c) Be omitted (hulks cover the graveyard look)
Pick (a): the pack says "treat the derelict station as a dressing variant of the station kind, not a fifth kind." Re-using the kit at max damage stage is the cheapest path and keeps the kit count at one.
Q5: Kenney / KayKit asset use.
The pack lists Kenney Space Station Kit (CC0) and KayKit Space Base Bits (CC0) as possible references. Should the station kit:
(a) Use these as shape reference only; all geometry built from the game's own ship parts per FINDINGS R79 - RECOMMENDED PICK
(b) Import some Kenney/KayKit parts directly into the kit
(c) Ignore them entirely
Pick (a): FINDINGS R79 is explicit that the kit is "built from the game's own ship parts." Kenney/KayKit can inform shapes and proportions but should not contribute geometry. This avoids licence-attribution questions in a shipped game and keeps the visual language unified with the ship fleet.
9. Not Checked
- Specific developer-talk URLs for Homeworld 3 megaliths, Sins of a Solar Empire 2 starbases, BFG Armada 2 stations, and EVE Online citadels beyond the Stellaris Dev Diary 256 link provided in the pack. The principles cited are drawn from training knowledge of these games' public design materials; exact URLs and post titles should be verified before the synthesis cites them.
- The exact contents of the Kenney Space Station Kit and KayKit Space Base Bits (part counts, specific shapes). The pack lists them as licence-checked (FINDINGS X14) but the leg has not inspected their inventories.
- Whether the Godot _station function's "slight tilt" has a fixed angle or is randomised. This affects whether the kit needs to look good at exactly one tilt angle or at a range.
- The exact pixel dimensions of Ryan's 4K display and whether the 15.4 px/unit figure at 4K accounts for any in-game camera zoom or UI overlay.
- Whether the Route C machine kit's clean-parts list is final or still in flight, and exactly which parts are available for station reuse at the time #61 builds.
End of Qwen leg. Produced independently from the pack and cited sources. No other leg consulted.
