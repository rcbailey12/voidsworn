legs/deepseek.md -- Voidsworn objective structures look spec

Gate: DeepSeek leg, DeepThink ON, Search ON. Inputs: PACK.md plus cited web sources. All inferred extensions are marked INFERRED.

1. Headline

The station is not a ship with a different outline. It is a piece of terrain that happens to be owned: long axis first, berths that visibly fit our ships, negative space that reads from the battle camera, batteries that are visible because they are rules truth, and damage that degrades from the working face inward. One Blender kit produces the fleet station and the refinery; the relay beacon and the intercept transport are small, separate readability problems, not station variants. Faction identity lives in paint and lit accents, never in silhouette. The #61 build order should block out with ship proxies first, export to game at once, and only then detail.

2. What the shipped references actually do

Stellaris -- Salvagers station: The art team rejected early shapes that became "a big blob of parts" and gave the station a long axis and a strong shape; they blocked out the model with existing ship types in the station's "back-slots" and exported it to the game early to check scale; the destroyed version reuses the same model, with parts moved, bent and cut, base colour darkened, roughness changed and emissive lights removed. [164] What this leg takes from it: Long axis, ship-proxy blockout, early in-game scale export, and a destroyed variant that is a modified build of the same asset rather than a separate wreck model.

Sins of a Solar Empire II -- Argonev starbase: The Argonev began as a civilian orbital city and was converted to war; the base configuration carries 48 autocannon emplacements plus 16 point-defence emplacements, with optional heavy beams, missile arrays, hangars, construction bays and docking booms that visibly change the model; the Safety Override causes a catastrophic reactor explosion. The later ship-series article notes the model's improved greebling and texture use and non-monochrome windows/lighting. [10] [59] What this leg takes from it: Visible battery mounts, module-driven silhouette change, greeble density as a readability tool, and a destruction event that is a designed reactor/industrial catastrophe rather than a generic pop.

Sins of a Solar Empire II -- Ruins of War: Every capital ship, titan and starbase gets its own unique wreckage, and starbases leave "appropriately massive wreckage". [97] What this leg takes from it: Destruction must leave a station-specific hulk that still reads as the station kind, not a scaled-up ship wreck.

Homeworld 3 -- megaliths: Megaliths are 3D terrain: walls, giant flat surfaces with holes, gaps small ships can get through but big ships cannot, and trench runs that allow ambush and cover. They were "blocked out and designed" as massive objects intended to bring scale and awe to the battlefield. [1] [3] [57] What this leg takes from it: Negative space, holes and trenches are not decoration; they are the station's tactical read. Silhouette must have gaps and depth, not a closed hull.

EVE Online -- Upwell engineering complexes / citadels: The XL structures were consciously designed to act as a backdrop to the fighting around them, with large flat sloping surfaces "a bit like an amphitheater"; the designs use negative space, trenches and dark shadow pockets; the complexes are self-contained manufacturing lines, not sparse rib-like shipyards, with a front-in/back-out material flow and visible cranes/processing equipment. [24] What this leg takes from it: The refinery is a flow-through industrial building, not a decorated box. The station's large flat surfaces and dark berth mouths are what make it read at distance.

EVE Online -- structure personalization: Corporations apply nanocoating designs to standard Upwell structure hulls to display identity; the structure class and silhouette stay the same while paint and lit accents carry ownership. [165] What this leg takes from it: Faction dressing must be a paint/emissive layer over a neutral structure, not faction-specific geometry.

Battlefleet Gothic: Armada 2 -- stations: Space stations are "huge contraptions fitted with numerous deadly weapons for all ranges", supported by defence platforms whose generators replenish the station's shields; the game lists separate Imperium Facility Station and Outpost Station artworks, implying station roles read differently even within one faction. [17] [114] What this leg takes from it: A station is an armed objective with subordinate mounts; battery visibility and role differentiation matter more than hull greebles.

3. Non-negotiables from the pack

These are pack facts, not inferences:

Scale anchors: Frigate 10.4, Battleship 33.6, Super dreadnought 49.6. Station 46 long for a cluster of 5+ hexes, else 22 + 4 per hex, lifted 3. The station sits between Battleship and Super dreadnought and is never wider than its cluster.

Rules truth: station terrain blocks movement and line of fire; the defend station has an integrity track and working batteries (stationFire fires on the 2 nearest enemy caps within 5 hexes, 12 damage, pierce 0.2, logged as "Station batteries hit …"). Battery mounts are therefore rules truth, not decoration.

Two kinds, one kit: fleet station and refinery from one Blender kit built from the game's own ship parts (FINDINGS R79). The look spec must serve exactly that kit decision.

Ship damage language: staged surface damage, scorch progression, stage 4 the first open break, repair leaves patch plus scars, faction wound variants including Eclipse wound_kind 3, persistent damage fire spends zero counted flashes, and never more than 3 counted flashes per second.

Export rule: static kit parts merged into the hull mesh at export; rotating turrets separate (R82 Q3, subject to feasibility).

House rules: space structures, never naval; no keels, raked bows, masts in the ship sense, funnels; bolt-ons snapped to surfaces on visible mounts, in matched symmetric pairs, never aimed backward.

Route C: the station kit must answer from the c19_kit.py pattern and the #76 synthesis, not invent a second kit system.

4. Camera budget at 4K

The pack gives the battle camera at about 170 units distance, 7.7 px per unit at 1080p and 15.4 px per unit at 4K. Derived from those numbers (INFERRED):

Station, big cluster -- 46 units -- ~708 px -- 18.4% of a 3840-wide frame; unmistakable
Battleship -- 33.6 units -- ~517 px -- large ship, clearly subordinate to station
Frigate -- 10.4 units -- ~160 px -- small but readable
2 units -- 2 units -- ~31 px -- minimum feature that reads as shape
1 unit -- 1 unit -- ~15 px -- reads as line/texture, not shape
0.5 unit -- 0.5 units -- ~8 px -- wasted geometry

Rule: model silhouette at >= 2 units; use 1-2-unit features for secondary read (pipe runs, railings, battery barrels); anything below 1 unit is texture, not mesh. A berth opening smaller than 6 units will not read as a berth at 4K. A gap between arms smaller than 4 units will read as surface noise, not negative space.

5. Shared kit logic -- one kit, two station kinds

5.1 What is shared with the Route C machine kit

The station must not introduce a second visual language. Use the Route C machine-kit part families as the vocabulary, and add only station-scale parts.

Chamfered armour plate -- shared -- spine cladding, arm caps, battery cowlings
Exposed frame rib -- shared -- spine/arm structure at breaks, berth frames
Docking collar / clamp -- shared -- berth mouths, transport collar, refinery loading arm
Radiator fin -- shared -- station heat rejection, refinery cooling
Sensor mast / dish -- shared -- beacon mast, station sensor cluster
Turret ring / barbette -- shared -- battery mounts
Cargo pod / container -- shared -- transport cargo, refinery storage
Station-only -- none -- spine segment, radial arm root/mid/tip, battleship berth cradle, refinery drum, beacon top ring, beacon plinth

c19_kit.py pattern: named parts, matched symmetric pairs, surface-snapped mounts. Use the same naming and mirror tools. Static parts merge at export; turret assemblies stay separate. The station's kitbash character comes from arranging ship-scale parts on a station-scale spine, not from inventing station-only greebles.

5.2 The two station kinds from one kit

Both kinds share the spine, radial-arm roots, berth cradles, radiator fins and battery rings. The refinery swaps the arm tips and the working face: tanks, drums, pipe runs and loading arms instead of frigate berths and battery blisters. This is a part-swap and silhouette change, not a second kit.

6. Per-kind look spec

6.1 Fleet station (defend objective and station terrain)

Silhouette rules -- Must do:

Long spine first. The primary mass is a horizontal spine along X, 46 units at the big-cluster size. The spine must be legible as one continuous structural member, not a chain of boxes. Stellaris's long-axis rule is the direct precedent: the station must not become "a big blob of parts". [164]

Axial battleship cradle. A Battleship is 33.6 units long on a 46-unit station. A battleship berth cannot be a radial arm without making the station wider than its cluster. Put the battleship cradle parallel to the spine, recessed into one face, with the berth mouth open along the spine. This is the single most important silhouette decision. INFERRED from the pack's scale anchors and the "never wider than its cluster" rule.

Radial arms in matched pairs. Two or four radial arms, mirrored across the spine, carrying frigate berths and service gantries at their tips. Arms must be shorter than the spine and must not extend the total width beyond the cluster. Frigate berths are ~10.4 units long, so an arm tip berth of 12-14 units reads.

Negative space. At least one clear gap between the spine and each radial arm, and between the two radial arms on the same side. Homeworld 3's megaliths work because they are walls with holes and trenches, not solid lumps. EVE's XL structures use negative space and shadow pockets for the same reason. [3] [24]

Visible battery mounts. At least four visible twin mounts: two dorsal, two ventral, on the spine at roughly 1/4 and 3/4 length. The rules fire on the 2 nearest targets, so four mounts give arcs without implying a fortress. Each mount must have a visible barbette ring and clear traverse arcs; no guns buried inside the hull.

Working face. One long face carries the berths, docking lips, crane rails and lit interior edges. The opposite face carries radiators, tanks and service trunks. This gives the station a "front" without giving it a ship's bow.

Blunt ends. Both spine ends are blunt, open structural frames. No raked bow, no tapered stern, no engine cluster at one end.

Must never do:

Never a closed ovoid or cube with surface greebles only.
Never a ship silhouette: no bow, no stern engine block, no dorsal superstructure concentrated at one end.
Never wider than the cluster.
Never a radial arm long enough to make the station read as a "star" rather than a station.
Never battery mounts that are invisible from the battle camera. If the player cannot see the guns that are shooting, the rules and the model disagree.
Never backward-aimed parts; no exhaust nozzles pointed at the station's own berths.

Scale against ship classes

At 46 units, the station is 1.37x a Battleship and 0.93x a Super dreadnought. The silhouette should make the Battleship look like it belongs in the cradle: the cradle length should be ~34-36 units, leaving ~10-12 units of spine for the bow/stern service sections. A Frigate at 10.4 units should fit an arm-tip berth with visible clearance. If the blockout does not show that relationship with proxy ships, the scale is wrong.

What reads at 4K / what is wasted

Reads: spine length, cradle mouth, arm span, negative-space gaps, battery barbettes, lit berth interiors, radiator fins, the difference between the working face and the service face.
Reads as texture: pipe runs, railings, panel seams, small crane rails, docking clamps.
Wasted: individual rivets, panel lines below 0.5 units, tiny windows used as the only scale cue, greebles packed into gaps smaller than 2 units. At 15.4 px/unit, a 0.5-unit rivet is ~8 px; it is noise.

Damage and destruction

Use the settled ship damage language, not a new system.

Stage 1: Scorch on battery cowlings and berth lips; paint discoloration; no structural change.
Stage 2: One battery mount scorched; barrel droop or traverse frozen; berth lights flicker; small venting jet at a service trunk.
Stage 3: Scorch spreads across the spine; one radial-arm tip blackened; a frigate berth goes dark; persistent damage fire at <=3 counted flashes/sec.
Stage 4: First open break at a radial-arm/spine junction; berth cradle buckled; one battery mount broken open with internal glow; the station's silhouette now has a visible missing piece.
Repair: Patch plates over the break, scorch scars left around the patch, paint mismatch at the repair boundary. Faction wound variant changes scorch colour/pattern, including Eclipse wound_kind 3.
Destruction: If the integrity track reaches zero, the station becomes a hulk: spine broken in one place, one arm drifting on a tether or free, batteries dead and dark, no counted flashes above 3/sec. Use the same model with bent/cut parts and emissive removed, following the Stellaris destroyed-version method. Sins' unique starbase wreckage is the precedent for a station-specific hulk rather than a generic explosion. [97] [164]

Rules consistency: battery mounts degrade before the spine breaks. The player must be able to read "the guns are dying" before "the station is dying". Do not remove a mount at stage 1-2; scorch it and keep the geometry. At stage 4, the first open break should be at a non-critical arm junction, not the main spine, so the station still reads as a station.

Faction dressing

Paintable: armour panel bands, battery cowlings, dock-lip stripes, arm-tip caps, a faction emblem plate on the spine's working face.
Neutral: spine forging, structural trusses, berth frames, radiator fins, greeble, hazard markings, docking collars, pipe runs, crane rails.
Rule: the station today wears Hegemony paint on every map. Replace that with a paint layer selected by owner faction over a neutral structural primer. EVE's structure personalization uses exactly this model: standard structure hull plus corporation nanocoating, silhouette unchanged. The Voidsworn variant must use the Voidsworn ship palette from the ship pipeline; do not invent a new palette in this research. [165]
Hazard markings stay yellow/black regardless of faction. They are safety markings, not faction identity.
Lit accents (berth interior, battery status lights, beacon top) may change colour by faction; the structural geometry must not.

How it is built

Kit parts: spine segments (2 lengths), radial arm root/mid/tip, battleship cradle (port/starboard halves, mirrored), frigate berth ring, docking collar, battery barbette + twin turret, radiator fin, sensor mast, crane rail, service trunk, arm-tip cap.
Assembly: spine first; cradle second; radial arms in mirrored pairs; battery mounts on the spine; radiators opposite the working face; greeble only on surfaces the camera sees.
Export: static parts merged into the hull mesh; turret assemblies separate; named collision meshes for the berth cradle and spine; LODs at 46, 22 and 14 units.
Do not build a unique greeble set for the station. Use the Route C machine-kit greebles and ship-part vocabulary.

6.2 Refinery (second variant from the same kit)

Silhouette rules -- Must do:

Same spine, different skyline. The refinery uses the same spine and arm roots as the fleet station, but the radial arms carry tank clusters, processing drums and pipe bridges instead of frigate berths and batteries. The fleet station is low and cross-shaped; the refinery is tall and comb-like. The two must be distinguishable at a glance in the same faction paint.

A clear process flow. Intake at one end, processing in the middle, output/loading at the other. EVE's engineering complexes were designed as self-contained manufacturing lines with material coming in the front and finished products stored/transported at the back; the station should read the same way. [24]

Visible processing face. One long face carries the drums, stacks, pipe runs, heat exchangers and loading arms. The opposite face carries radiators and service access. The processing face should be denser and taller than the fleet station's working face.

Negative space between stacks. Gaps of at least 4 units between drums; pipe bridges spanning the gaps. Without gaps, the refinery becomes a solid wall and loses the EVE/Homeworld negative-space read.

At least one tall vertical element. A cracking tower or drum cluster 12-16 units tall gives the refinery a different silhouette from the fleet station's horizontal cross. This is the main "at a glance" difference.

Two light defensive turrets maximum. The refinery is infrastructure, not the defend objective's fortress. Two visible turret mounts on the spine are enough to read as owned and armed; more would confuse it with the fleet station's battery suite. INFERRED from the pack's two-kinds-one-kit ruling and the rules truth that only the defend station's batteries are specified.

Must never do:

Never a copy of the fleet station with tanks glued on. If the skyline is the same, the variant has failed.
Never a solid wall of drums with no gaps.
Never a refinery that reads as a ship: no bow, no stern engine cluster.
Never exceed the fleet station's width; height may exceed it, width may not.

Scale

Same 46 / 22 + 4 per hex rule. The refinery may be taller than the fleet station (12-16 units above the spine) but not wider. At 4K, a 14-unit tower is ~216 px, clearly taller than a Frigate (160 px) and about 42% of a Battleship's length. That is enough to change the silhouette without competing with the station's overall length.

What reads at 4K / what is wasted

Reads: tower height, drum cluster silhouette, pipe bridges, loading arms, the difference between intake and output ends, radiator fins.
Reads as texture: pipe runs, valve clusters, ladders, small tanks, hazard bands.
Wasted: individual pipe elbows below 0.5 units, tiny gauges, internal detail behind opaque drum walls.

Damage and destruction

Stage 1: scorch on a drum or pipe bridge; paint discoloration; small steam/vapour vent.
Stage 2: one drum scorched and dented; a pipe run ruptured with a venting jet; loading arm stuck.
Stage 3: fire at a stack or drum base (<=3 counted flashes/sec); scorch across the processing face; one drum goes dark.
Stage 4: first open break at a drum support frame or pipe bridge; tank rupture with a sustained jet; the processing face now has a visible missing drum and a bent frame.
Repair: patch plates on drums and pipe runs; scorch scars; mismatched paint at patches.
Destruction: the refinery should not produce a single symmetric explosion. It should break into two large pieces plus a field of kit-part debris: a burning tank farm at one end, a drifting spine section at the other, and a cloud of cargo pods/pipe segments. Sins' unique starbase wreckage supports station-specific debris; Stellaris's destroyed version supports reusing the same model with parts moved/bent/cut and emissive removed. Keep counted flashes <=3/sec even during the break; use sustained fire and venting rather than flash spam. [97] [164]

Faction dressing

Same rule as the fleet station: tank bands, drum caps, loading-arm stripes and faction emblem plate are paintable; pressure vessels, structural frames, pipes, hazard bands, radiators stay neutral. The refinery is where faction paint is most tempting to over-apply; resist it. A Voidsworn refinery should read as a Voidsworn-owned industrial site, not a Voidsworn-painted oil drum.

How it is built

Shared with fleet station: spine, arm roots, radiator fins, docking collars, battery rings, service trunks.
Refinery-only parts: processing drum (2 sizes), storage tank (2 sizes), pipe bridge, loading arm, heat exchanger, flare/vent stack.
Assembly: spine first; processing face built as a sub-assembly and snapped onto the spine; drums and tanks in matched pairs where possible; pipe bridges last.
Export: static parts merged; loading arms and turret assemblies separate if they animate; LODs at 46, 22 and 14.

6.3 Relay beacon (hold objective)

Silhouette rules -- Must do:

A mast, not a station. The beacon is a vertical object with a base, a mast, crossarms and a distinctive top. It must read as a deliberate marker, not a piece of debris or a ship antenna.

Strong vertical line. The mast should be visible as a continuous vertical element from the battle camera. At 4K, a 14-unit beacon is ~216 px tall, about 1.35x a Frigate, so it reads over ships without competing with the station.

Distinctive top. A ring, dish or lattice cage at the top, at least 5 units across, so the beacon has a recognizable "head" rather than a plain pole.

Grounded base. A plinth 5-6 units across and 1.5-2 units tall, with visible feet or anchors. The beacon must look placed on the board, not floating.

Two or three crossarms at different heights, in matched pairs, carrying antenna elements or lights. This gives the silhouette a ladder-like rhythm and helps it read at distance.

Bright faction light at the top. The beacon's function is to be seen; the top light is its readability anchor.

Must never do:

Never a ship's communications mast on a hull; the beacon needs its own base and structure.
Never a thin pole with no top feature; at 4K a 0.5-unit pole is ~8 px and disappears.
Never a solid tower that reads as a small station; the negative space between the mast and crossarms is what makes it a beacon.
Never backward-aimed antenna elements; matched pairs only.

Scale

INFERRED proposal: height 14 units (base 1.5 + mast 12.5), top ring 6 units diameter, base plinth 5x5. This is 1.35x a Frigate and 30% of a Battleship's length. The pack does not fix the beacon height; 14 is a recommendation for the owner questions.

What reads at 4K / what is wasted

Reads: overall height, top ring silhouette, crossarm spacing, faction light, base plinth.
Reads as texture: cable runs, small antenna elements, warning bands on the mast.
Wasted: tiny dishes below 1 unit, individual cables, bolt heads.

Damage and destruction

The beacon is a hold objective, not an integrity-track structure. The rules specify contest and scoring, not destruction. Therefore:

No destruction state. The beacon must not be destroyable in the normal hold objective. If a future variant makes it destructible, use the ship damage language, but the default is contest state only.
Contest state: the top light shifts from the owner's faction colour to warning amber/white strobe; the crossarm lights pulse; the mast itself is unchanged. The player reads "this objective is being contested" from light and motion, not from structural damage.
Capture state: the top light and plinth band change to the capturing faction's colour. No geometry change.
If the beacon is destroyed by a scripted event: break the mast at one crossarm, leave the base standing, and let the top ring fall or drift. No counted flashes above 3/sec.

Faction dressing

Paintable: plinth band, top ring, crossarm end caps, faction light.
Neutral: mast structure, cables, base feet, hazard bands.
The beacon is small; faction identity should be carried by light colour first and paint second.

How it is built

Kit parts: base plinth, mast segments (2 lengths), crossarm root/tip, top ring, dish, antenna element, cable drum, light housing.
Shared with Route C: sensor masts, dishes, antenna elements, cable drums.
Assembly: base -> mast -> crossarms in matched pairs -> top ring -> light.
Export: one static mesh plus a separate emissive light mesh for the top; no turrets.

6.4 Intercept transports (objective movers)

Silhouette rules -- Must do:

Read as a non-combat mover in one glance. Boxy cargo spine, visible container stacks or cargo pods, a small bridge, engine bells at the rear. No turrets, no missile pods, no warship antennas.

Pale grey with hazard-yellow collars, as the current shipped look already does. The pale value separates it from warships; the hazard collar says "civilian/industrial".

Cargo pods as the main silhouette feature. Two or three pods stacked along the spine, with visible gaps of at least 1 unit. At 4K, a 1.5-unit hazard collar is ~23 px, clearly readable as a yellow band.

A distinct rear engine block and a small forward bridge. This gives the transport direction without making it a warship.

Blinking navigation lights in a slow, non-combat rhythm. This is a readability cue, not a weapon.

Must never do:

Never mount a turret or missile launcher, even a small one.
Never use the warship hull silhouette with cargo boxes added.
Never use faction camouflage that hides the hazard collar; the collar must stay hazard yellow.

Scale

Transports are unit-scale movers, not structures. They should be smaller than a Frigate or roughly Frigate-sized; the pack does not fix their length. Keep the cargo spine shorter than 10 units so they read as auxiliaries, not combatants. At 4K, a 10-unit transport is ~154 px, comparable to a Frigate; a 6-unit transport is ~92 px, clearly smaller.

What reads at 4K / what is wasted

Reads: overall boxy silhouette, hazard collar, cargo pod separations, engine block, blinking nav lights.
Reads as texture: container ribs, small hatches, cable runs.
Wasted: interior cargo detail, tiny labels, sub-unit greebles.

Damage and destruction

Transports die like units, so use the ship damage language, with cargo-specific secondary effects:

Stage 1-3: scorch on cargo pods, paint discoloration, one pod dented, engine trail flickering.
Stage 4: first open break at a cargo pod or engine mount; cargo containers spill and drift; venting gas.
Destruction: break into 2-3 pieces; cargo pods scatter; no counted flashes above 3/sec. The wreck should read as "a transport died", not "a warship exploded".
Repair: patch plates on pods and engine block; scorch scars.

Faction dressing

Minimal. The transport is a civilian/auxiliary unit; faction identity should be a small pennant or nav-light colour, not a full hull paint. The hazard collar stays yellow. If the transport is owned by a faction, a faction stripe on the engine block is enough.

How it is built

From the ship kit, not the station kit. Cargo pods, docking collars, engine block and bridge come from the Route C machine kit / ship kit.
Station kit does not need transport parts beyond the shared cargo pod and docking collar families.
Export: standard ship export; no special station rules.

7. Shared with the Route C machine kit -- summary

The station kit is a superset of the Route C machine kit at the part-family level:

Shared: armour plates, frame ribs, docking collars, radiator fins, sensor masts, turret rings, cargo pods, pipe runs, cable drums.
Station-only: spine segment, radial arm, battleship berth cradle, refinery drum/tank, beacon top ring/plinth.
Rule: no station-only greeble style. The station's detail comes from arrangement, scale and negative space, not from a new bag of tiny parts. This is the direct answer to the pack's Route C requirement.

8. Build order for #61 (Codex)

Step 1: Freeze the scale and camera table: 46 / 22+4n, Frigate 10.4, Battleship 33.6, Super dreadnought 49.6, 15.4 px/unit at 4K. Acceptance check: Table is in the Blender scene as a text block and in the build notes.
Step 2: Blockout the fleet station with ship proxies: a Battleship in the axial cradle, a Frigate at an arm-tip berth. Acceptance check: Proxy ships fit with visible clearance; station is not wider than the cluster; export to Godot immediately for a scale screenshot. Stellaris's early scale export is the model. [164]
Step 3: Build the spine and axial battleship cradle first. Acceptance check: Spine reads as one member; cradle mouth is open and visible; no bow/stern taper.
Step 4: Add radial arms in matched pairs and frigate berth rings. Acceptance check: Arms are mirrored; gaps between arms are >=4 units at 4K; width <= cluster.
Step 5: Add four visible battery mounts (2 dorsal, 2 ventral) with barbette rings and clear arcs. Acceptance check: Mounts are visible from the battle camera; no guns buried in the hull; turret assemblies are separate objects.
Step 6: Add radiators, sensor mast, docking lips, crane rails and service trunks. Acceptance check: Working face and service face read differently; no backward-aimed parts.
Step 7: Build the refinery variant by swapping arm tips and the processing face: drums, tanks, pipe bridges, loading arms. Acceptance check: Refinery has a different skyline (tall/comb-like) from the fleet station (low/cross-shaped); same spine and arm roots.
Step 8: Build the relay beacon from mast parts: plinth, mast, crossarms, top ring, light. Acceptance check: Beacon reads as a vertical marker at 4K; height 14 units (provisional); top ring >=5 units.
Step 9: Build damage stages 1-4 and the hulk for both station kinds. Acceptance check: Stage 4 has a visible open break; hulk uses the same model with bent/cut parts and emissive removed; no counted flashes >3/sec.
Step 10: Author faction paint layers (Hegemony, Voidsworn) over neutral structure. Acceptance check: Silhouette unchanged between factions; hazard markings stay yellow/black; lit accents change colour only.
Step 11: Export: merge static kit parts, keep turrets separate, name collision meshes, build LODs at 46/22/14. Acceptance check: Draw-call and triangle budget checked in Godot; turrets rotate independently; collision matches the spine and cradle.
Step 12: Turntable render both stations for Ryan first, with Battleship and Frigate alongside. Acceptance check: Ryan can see berths, batteries, negative space and the refinery's different skyline before in-game integration.
Step 13: Integrate both stations in game at shipped sizes; place a Battleship and a Frigate alongside on a station map. Acceptance check: Ryan sees "long structured stations with berths, not a blob"; 4K screenshot checked against the camera budget.
Step 14: Integrate the beacon and transport variants. Acceptance check: Beacon reads over a Frigate at 4K; transport reads as non-combat at a glance.

9. Owner questions (max five, chair picks marked)

Q1. Battleship berth geometry: axial cradle or radial arm?
A) Axial cradle parallel to the spine. ← chair pick
B) Radial arm with an oversized tip berth.
C) External clamp on the spine's working face.
Reason for pick: a 33.6-unit Battleship cannot fit radially on a 46-unit station without making the station wider than its cluster. Axial is the only option that preserves the scale rule and the "never wider than cluster" constraint.

Q2. Fleet station battery suite: how many visible mounts?
A) Four twin mounts (2 dorsal, 2 ventral). ← chair pick
B) Six or more mounts.
C) Two mounts only.
Reason for pick: the rules fire on the 2 nearest targets; four mounts give believable arcs without implying a fortress the rules do not support. More mounts would be decoration that misrepresents the station's firepower.

Q3. Refinery armament: how much?
A) Two light defensive turrets. ← chair pick
B) No turrets; purely industrial.
C) The same battery suite as the fleet station.
Reason for pick: two turrets read as owned infrastructure and justify the refinery being a station-terrain object, without confusing it with the defend objective's fortress role.

Q4. Relay beacon height: 10, 14 or 18 units?
A) 14 units. ← chair pick
B) 10 units.
C) 18 units.
Reason for pick: 14 units is ~1.35x a Frigate at 4K, readable over ships and clearly not a station. 10 is too close to a Frigate; 18 starts to compete with the station's vertical elements.

Q5. Faction paint coverage on stations: full hull tint or panel bands?
A) Panel bands, battery cowlings, dock lips and lit accents over neutral structure. ← chair pick
B) Full hull tint in faction colours.
C) Faction geometry kits (different armour parts per faction).
Reason for pick: EVE personalizes standard structure hulls with nanocoatings, keeping the silhouette intact; this is the cheapest and most readable way to support Hegemony and Voidsworn without doubling the kit. Full hull tint destroys the neutral structural read; faction geometry violates the one-kit ruling. [165]

10. Not checked

No direct shipped-game source for a relay beacon mast at this scale. The beacon spec is inferred from the pack's beaconMesh (O3_11, height H, base on board) and from sensor-mast part language. The 14-unit height is a proposal, not a sourced figure.

No direct source for Voidsworn faction colours. The pack names Hegemony paint and Crusade/Voidsworn country but does not give a Voidsworn palette. The build must use the ship pipeline's existing Voidsworn palette; this leg does not invent one.

No direct source for integrity-driven battery loss on a station. The staged battery degradation is inferred from the pack's rules truth (integrity track, working batteries) and the settled ship damage language. It needs a playtest read.

No performance measurement for the kit. Triangle counts, draw calls, LOD transition distances and merged-mesh cost are Codex's profiling work in #61, not measured here.

No Blender inspection of c19_kit.py. The kit pattern is cited at the level the pack states: named parts, symmetric pairs, surface-snapped mounts. Detailed part lists are Codex's build work.

No 4K screenshot test. The px/unit table is derived from the pack's camera numbers (170 units, 7.7 px/unit at 1080p, 15.4 at 4K), not measured in the engine. The first in-game export should confirm it.

Battlefleet Gothic station detail is thin. The fandom page gives gameplay description (huge contraptions, numerous weapons, defence platforms with shield generators) and the gallery lists Facility/Outpost station art, but no art breakdown or design talk was found. The station-as-armed-objective read is sourced; the internal art process is not.

No direct shipped-game "refinery station" variant. EVE engineering complexes and Sins construction bays are the closest analogues; the refinery look is an inference from those industrial-flow sources, not a copy of a named refinery station.

Stellaris asymmetry note: the Stellaris dev diary says the Salvagers station was deliberately not very symmetrical. This leg keeps the house rule of matched symmetric bolt-ons, and allows asymmetry only at the whole-station composition level (e.g. refinery intake at one end). That tension is deliberate, not an oversight. [164]

DeepSeek chat retained for verification: https://chat.deepseek.com/a/chat/s/02beefe0-ffed-4b04-97e8-9d38bde87769
