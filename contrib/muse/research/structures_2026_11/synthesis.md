# Structures look research: chair synthesis (issue #102)

Chair: Rey. Inputs: DeepSeek leg and Qwen leg (both writers, filed under legs/), Argon review leg (reviews and ideas only, R81), the evidence pack's verified grounding from current main, FINDINGS R79 (two station kinds from one Blender kit), the Job 10 backdrops synthesis (kitbash approach, spine with radial arms and berths, and the shipped size formula are settled there and are not reopened here), the issue #51 damage language as ruled in R80, and the R82 Q3 export rule.

## Verdict: GO

The look spec below is ready for Codex to build issue #61 from. One kit makes the fleet station and the refinery. The relay beacon and the intercept transports are separate, smaller readability problems and are specced separately. Five owner questions sit at the end with chair picks; everything else is settled here.

## 1. Headline

A station is terrain that happens to be owned. Long axis first, berths that visibly fit our ships, negative space that reads from the battle camera, batteries that are visible because they are rules truth, and damage that degrades from the working face inward. Faction identity lives in paint and lit accents, never in silhouette, so one kit serves every map. The current station fails on all of this: one AI mesh (O1_37) at a fixed length, Hegemony paint on every map, and a flat grey clay fallback in the Godot board. This spec replaces it.

## 2. Shared rules for every structure kind

Camera budget (both legs converge; numbers INFERRED from the pack's camera anchors, about 170 units, 15.4 px per unit at 4K):

- Silhouette features must be 2 units or larger (about 31 px at 4K) to read as shape.
- Features of 1 to 2 units are secondary read: panel breaks, mount rings, lit strips.
- Below 1 unit is texture only. Below 0.5 units is wasted geometry; do not model it.
- Gaps and openings under 4 units read as noise, not negative space. Berth mouths and arm gaps must clear 4 units, and a berth opening must clear 6 units to read as a berth.

Kit logic (R79, settled): one Blender kit script beside the Pyre-Barge kit pattern (tools/blender/hs/c19_kit.py), named parts, matched symmetric pairs, bolt-ons snapped to the hull surface on visible mounts, nothing aimed backward. Static parts merge into the hull mesh at export; rotating turrets export separately (R82 Q3).

Faction dressing (both legs converge): structure geometry is faction-neutral. Identity goes on as panel bands, battery cowlings, dock lips, hazard striping and lit accents over the neutral structure, following the EVE personalization pattern of coatings on standard hulls. The station must stop wearing Hegemony paint on every map; it takes the paint of the faction whose country the map is in (FAC_MAP, battle.js:59: Hegemony and Crusade home country today). Owner question Q4 confirms the coverage level.

Damage language (R80 applied to structures): four stages driven by the structure's own track (the defend station's integrity; plain station terrain degrades by hits taken). Stage 1 scorch and scoring, stage 2 deeper scorch and small marks, stage 3 a deep fissure crater with the hull still sealed, stage 4 the first and only open break. Persistent fire and smoke stay inside the Job 1 flash budget (never more than 3 counted flashes per rolling second); damage fires are not counted flashes. Repair is not specced for structures; nothing in the rules repairs a station.

## 3. Fleet station (defend objective and station terrain)

Grounding: 'obj|station' is O1_37 (ships3d.js:712), drawn at fixed length 46 in the browser (ships3d.js:925-927) and by cluster size in the Godot board (board.gd:716: 46.0 for a cluster of 5 or more hexes, else 22.0 + 4.0 per hex, lifted 3). The rules make it armed terrain: it blocks movement and line of fire (battle.js:6, battle.js:11), enemies within 2 hexes at round start knock out 1 integrity each, the hold lasts until round 6 ends (battle.js:63), and stationFire hits the 2 nearest enemy capitals within 5 hexes for 12 damage, pierce 0.2.

Silhouette rules:

- Long spine first: the 46-unit length is the read. Blunt ends, no tapered bow; this is a building, not a ship.
- One axial battleship cradle parallel to the spine, about 34 to 36 units long, open on the working face. The scale math forces this: a 33.6-unit Battleship cannot berth radially on a 46-unit station without the station growing wider than its hex cluster. Owner question Q1 confirms.
- Radial arms in matched pairs carry frigate berths at their tips (berth opening 12 to 14 units, sized to the 10.4-unit Frigate) and secondary docking. Arm gaps clear 4 units.
- A working face and a service face: berths, batteries and lit docking guides on the working face; radiators, tanks and cable runs on the service face. The silhouette differs by side on purpose; the matched-pairs rule binds the bolt-ons, not the whole-station composition.
- At least three clear silhouette breaks along the length (cradle mouth, arm roots, end caps) so the eye does not slide off a smooth 46-unit bar.

Scale: 46 units long at full cluster size, between the Battleship (33.6) and the Super dreadnought (49.6). Never wider than its cluster. The Godot size formula does not change.

Batteries (rules truth, so they must be visible): four twin battery mounts, two dorsal and two ventral, at one-quarter and three-quarters along the spine, on barbette rings with visible traverse arcs. Four mounts give believable arcs for a weapon that fires on the 2 nearest targets; more would promise a fortress the rules do not deliver. Whether the turrets move is owner question Q5; the mounts export separately either way (R82 Q3).

Damage: R80 stages mapped onto the integrity track. Batteries degrade before the spine breaks: scorch, droop and frozen traverse at stages 2 to 3, never removed at stages 1 to 2. The stage 4 first open break lands at a radial-arm and spine junction, not mid-spine, so the station reads as crippled, not cut in half. Destruction is a station-specific hulk built from the same model by the Stellaris diary method: parts moved, bent or cut, colour darkened, roughness changed, emissive removed, one arm drifting. The hulk stays on the hex as terrain dressing (hulk terrain already exists, battle.js:11).

Derelict dressing: the derelict station is this same kit at full damage dressing (hulk state, no emissive, cold radiators), not a fifth structure kind. The pack settles this; it is in the build order, not the owner questions.

## 4. Refinery (second variant from the same kit, R79)

Same spine, same length, same size formula, same kit script with a module swap. What changes:

- The working face goes dense and closed: processing volumes where the fleet station has open berth concavities. One battleship cradle is deleted; frigate berths shrink to service docks.
- Skyline: one tall element only, a cracking tower or drum cluster 12 to 16 units, so the refinery reads taller and busier against the fleet station's low cross, while the dominant gesture stays horizontal length, not a vertical tower.
- Process read: intake, processing, output laid along the spine in that order, with drum gaps of 4 or more units and pipe bridges between them. (The legs framed this as an EVE material-flow pattern; the chair carries it as a design inference, not a verified quote. See the screening notes.)
- Radiators and tank farms carry the visual heat: radiator glow and hazard striping are the refinery's accent zones.

Armament: none visible. The refinery never fires in the rules; only the defend station has stationFire. Modelling turrets on it would promise fire that never comes, the same defect the fleet-station battery count is calibrated to avoid. This is the chair's call against the DeepSeek leg's two-turret pick; owner question Q2 puts it to Ryan.

Damage: R80 stages, with the refinery's stage 4 break at a tank or drum mount. Destruction is two large pieces plus a kit-part debris field, venting and process fire inside the flash budget, and no ammunition-style secondary explosions: the refinery stores feedstock, not shells (Qwen's point, adopted). Its hulk state doubles as boneyard dressing.

## 5. Relay beacon (hold objective)

Grounding: 'obj|beacon' is O3_11 (ships3d.js:712); beaconMesh clones it at height H with the base on the board in station material (ships3d.js:919-920). The hold objective scores for a ship next to the relay with no enemy there at the start of 3 rounds (battle.js:67), and setup clears blocking terrain within 1 hex, so the beacon always stands in open space and must fill it as a landmark.

Spec: a mast, not a station. Plinth 5 to 6 units across, a single mast, crossarms, and a distinctive top ring 6 units in diameter that no ship silhouette shares. Total height 14 units (chair pick; owner question Q3). At 4K that is about 216 px of vertical read over the ships contesting the hex. One emissive colour, one silhouette; panel lines and greebles are wasted at this size.

Damage and state: the beacon has no integrity track and no destruction state in the rules, and the spec invents none. State is read through light instead: a slow amber-white strobe while contested, and the top light takes the holding faction's colour on a score. That needs a small emissive hook in code, which is Opus's call to schedule; the geometry does not change. A dark, pitted derelict beacon is allowed as biome dressing only, clearly non-functional.

Build: a standalone small prop, but its sensor mast, dish and cable-drum parts come from the same part families as the Route C machine kit, so the board's hardware speaks one language.

## 6. Intercept transports (objective movers)

Grounding: 'obj|transport' is O2_37 (ships3d.js:712); transports are units that move and die like units (battle.js:65, u.transport); the current material is pale grey with hazard-yellow collars (ships3d.js:912-913).

Spec (shorter treatment, per the pack): a boxy cargo spine under 10 units, cargo pods hung on visible mounts with gaps of 1 unit or more between pods, and the hazard-yellow collar kept at about 1.5 units wide (about 23 px at 4K) as the instant civilian read. No weapons, ever, and no military silhouette breaks: the transport must read as prey, not as a small warship. It takes damage and dies like a unit under the normal ship rules; at its stage 4 break the pods spill as a small debris scatter. Measure the shipped O2_37 mesh against this spec at build time rather than remodelling blind.

## 7. What is shared with the Route C machine kit

Shared: hull plate and panel stock, sensor masts and dishes, cable drums, radiator fins, mount rings and barbette bases, the greeble kit, and the trim and decal language settled in issue #112 (one shared detail language across hulls and structures). Station-specific, not shared: the spine segments, the axial cradle, berth arms, processing drums and tanks, and the beacon top ring. Kenney and KayKit free kits are shape reference only; geometry comes from the game's own part families (R79). That was the pack position and is confirmed here, not an owner question.

## 8. Build order for issue #61 (Codex)

1. Kit script scaffold: tools/blender/hs station kit beside c19_kit.py, named parts, symmetric pairs, surface-snapped mounts. Static parts merge at export; battery turrets export as separate nodes.
2. Proxy blockout first: spine, axial cradle and arm layout blocked out with real ship meshes docked (Battleship in the cradle, Frigate at an arm berth), exported into Godot early to judge scale in game, per the Stellaris diary method. Do not detail before the blockout reads.
3. Fleet station variant: spine, cradle, arms, four twin battery mounts, service-face dressing, lit docking guides.
4. Refinery variant: module swap on the same spine (processing volumes, one tall element, drums and pipe bridges, radiator and tank dressing). No weapon mounts.
5. Damage states: stage 1 to 4 material and geometry states for both variants, battery degradation, stage 4 breaks at the specced points, and both destruction hulks from the same models. Derelict dressing is the fleet station hulk state with emissive removed.
6. Faction paint pass: neutral structure plus panel bands, cowlings, dock lips and lit accents per map faction; kill the every-map Hegemony paint default and the flat grey fallback (a4_props.gd:34-43, board.gd station path).
7. Relay beacon prop: mast, crossarms, top ring, strobe and holder-colour emissive states (geometry here; the code hook is Opus's to schedule).
8. Transport check: measure O2_37 against section 6; adjust pods and collar only if it fails the read.
9. Turntable renders of both station variants for Ryan first (issue #61's done-when gate), then both in game at shipped sizes with a Battleship and a Frigate alongside, screenshots at battle distance and close zoom at 4K.

## 9. Screening notes

DeepSeek leg: used as the primary writer. Its sourced core (Stellaris Dev Diary 256 station method, Sins II starbase material, Homeworld 3 megalith negative space, EVE structure personalization) converges with the pack seeds. Two limits, one of them flagged by the Argon review and verified by the chair: its bracket numbers are orphaned search-result indices with no reference list in the filed text, so claims resting only on a bracket number are carried at the strength of the pack seeds, not as independently verified citations; and its EVE "amphitheater" and "front-in/back-out material flow" phrasing cannot be verified as a quote, so section 4 carries the process-flow layout as a design inference. Its refinery turret pick is not adopted (section 4).

Qwen leg: used with cuts. Cut: the four pylon legs and anti-grav glow proposed to justify the board's 3-unit lift (the station is in space, the lift is a readability offset, and ships float the same way; landing struts are planetary vocabulary). Folded: its damage stages beyond stage 4 are folded into the stage 4 break plus hulk treatment, since R80 fixes four stages. Not carried as owner questions, because the pack or the code already settles them: refinery blocking rules (station terrain blocks uniformly, battle.js:6 and battle.js:11), the derelict as a damage-dressing variant (the pack position), and Kenney/KayKit as reference only (R79). Carried: its no-weapons refinery position (adopted), its beacon emitter colour idea (merged into section 5's light-state read), and its turret-tracking proposal (owner question Q5). Its non-Stellaris source titles are largely unverified by its own Not Checked admission; principles are carried only where DeepSeek's sourced version or the pack supports them.

Argon review: screened out almost in full; see the chair header on the filed leg. Its cut list argues against claims that do not exist in either filed leg (verified by direct text search: no Deep Rock Galactic, no Stellaris Colossus, no Sins Phase Gate or Titan claims, no invented author names, no ratio rule, no Warframe in either leg or in the pack), and its section 4 ideas answer those same phantom claims. Two narrow credits stand and are used above: the orphaned DeepSeek citation indices, and the EVE amphitheater phrasing flag.

## 10. Owner questions (chair picks marked)

Q1. Battleship berth geometry on the fleet station.
A) Axial cradle parallel to the spine, about 34 to 36 units. CHAIR PICK.
B) Radial arm with an oversized tip berth.
C) External clamp on the working face.
Why: a 33.6-unit Battleship cannot berth radially on a 46-unit station without exceeding the cluster width. Axial is the only option that keeps the settled size formula.

Q2. Refinery armament.
A) Two light defensive turrets (the DeepSeek leg's pick).
B) No turrets at all; the refinery reads purely industrial. CHAIR PICK.
Why: only the defend station fires in the rules (stationFire, battle.js). Turrets on the refinery would promise fire that never comes.

Q3. Relay beacon height.
A) 14 units, with a 6-unit top ring. CHAIR PICK.
B) 12 units, roughly Frigate height (the Qwen leg's pick).
C) 18 units.
Why: 14 reads over the ships contesting the hex at 4K without competing with the station's tall elements; 12 can hide behind a hull, 18 starts to read as a second station.

Q4. Faction paint coverage on stations.
A) Panel bands, battery cowlings, dock lips and lit accents over neutral structure. CHAIR PICK.
B) Full hull tint in the map faction's colours.
C) Per-faction geometry kits.
Why: the EVE coating pattern keeps one silhouette and one kit (R79) while ending the every-map Hegemony default. Full tint kills the neutral structural read; geometry kits double the kit.

Q5. Station battery turret behaviour.
A) Turrets rotate to face the last-fired target, then hold. CHAIR PICK.
B) Turrets track the nearest enemy in real time (the Qwen leg's pick).
C) Turrets stay static.
Why: stationFire fires once a round on the 2 nearest capitals. Facing the last target sells the shot; constant tracking would spin against a target set that changes every round. Turrets export separately under any answer (R82 Q3).

## Not checked

- No Blender work was run for this research; triangle counts, export behaviour and the R82 Q3 merge feasibility on station parts are for the #61 build to prove.
- The chair did not re-open every leg source URL. DeepSeek citations were checked against the pack seeds and its own text; Qwen's non-Stellaris citations remain unverified, as its leg admits.
- No 4K screenshot test exists yet; every camera number here is arithmetic from the pack's anchors (camera about 170 units, 15.4 px per unit at 4K), labelled INFERRED where the legs introduced it. The #61 turntable and in-game screenshots are the real test.
- The beacon light-state read needs a code hook (emissive swap on contest and score) that no current code provides; scheduling it is Opus's call.
- BFG Armada 2 station sourcing stayed thin in both legs (fandom-level); no spec point rests on BFG alone.
