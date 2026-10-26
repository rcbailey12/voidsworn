# Damage marks review, DeepSeek leg (brief muse_2026-10-26c, Job 3)

Model: DeepSeek web chat, DeepThink ON and Search ON (verified by toggling), fresh chat "Hull damage marks review", Oct 26, 2026. Both pack files attached (leg prompt and evidence pack). Generation consulted 143 web pages per the chat footer. Filed verbatim below; the model's citations appear as bracket numbers whose reference list was not included in the return, so those claims are leg-stated, not chair-verified.

---

Research findings

Homeworld 3 is the closest direct model for what Voidsworn is trying to do. Blackbird Interactive built a system called Splat Damage. The official developer blog says the team needed four distinct damage types, Kinetic, High Explosive, Energy, and Ion, each with its own visual treatment. It also says Splat Damage does not slap impact stickers on a ship. It creates dynamic impact points that alter the surface geometry and properties of the hull in the exact area hit by a specific weapon type. The same material says damage transitions from surface scars to hull breaches, with secondary hot spots and burn marks, and that the marks persist so a ship's combat history is readable at a glance. For larger ships, Blackbird uses damage sockets around the hull to spawn smoke, fire, hull breach FX, and sparks in staged damage states, light, heavy, critical, and near-destruction. Smoke gets thicker and darker as damage rises. A later patch specifically improved the readability of the Dynamic Splat Damage system, which is a useful admission that readability at fleet scale needs tuning, not just asset creation. [1] [5]

Sins of a Solar Empire 2 is the presentation benchmark in the brief, but its hull damage readability is weak. Player threads repeatedly complain that hull hits leave almost nothing on the ship, that ships look brand new until they explode, and that the game attaches particle effects to damaged ships rather than updating the hull surface. One thread asks for visible surface damage that accumulates after shields go down. Another calls the system a rehash of attaching a particle effect as the ship gets damaged, and asks for textures that update as health drops. The game does have a Crippled state for capital ships and titans, but that is a rule state and a UI/health-bar state, not a hull mark. The lesson for Voidsworn is negative but useful: shield flicker, hit sparks, and smoke alone do not make a damaged fleet readable at tactical distance. [15] [111] [113]

Battlefleet Gothic: Armada 2 communicates damage through critical hits, disabled subsystems, fires, turret loss, and morale effects. Critical damage can cripple ships by disabling essential parts, and fires cause hull damage over time. Emergency repairs put out fires and repair destroyed turrets. What I could not find is a primary source documenting a hull decal or persistent surface-mark system. The visual language appears to lean on fire, smoke, turret destruction, and subsystem states rather than authored impact marks. I am marking the hull-mark specifics UNSURE, but the fire and subsystem-loss language is a useful high-salience cue for Voidsworn.

Starsector uses a documented decal sheet. The game overlays a 256 by 256 pixel sheet containing six 48 by 48 pixel damage tiles. When a ship takes sufficient damage, a random tile is chosen, given a random orientation, and overlaid on the ship sprite. Tiles can overlap, and the bottom-most tile on the sheet draws on top. At fleet zoom those small tiles read as scattered dark speckle rather than as individual weapon signatures. Starsector also has a separate damage glow sheet and community smoke plugins, which shows the same two-channel approach: a surface decal layer plus a glow or smoke layer. The decal sheet is cheap and readable, but it is not designed to distinguish nine weapon types. It is a grime and damage layer, not a weapon-signature layer. [30]

BattleTech and MechWarrior read damage by location primarily through the paper doll or armor diagram, not through the hull itself. The MechWarrior manual describes a color graduation: grey for pristine armor, yellow for damaged armor with internals exposed, then orange and red as the section degrades. The armor outline is separate from the internal-structure fill, so the player reads two layers of damage from the HUD diagram. This is excellent for location damage, but it confirms the brief's concern: the hull itself is not carrying the main readability load. For Voidsworn, the BattleTech lesson is that section state must be readable somewhere, and if the hull marks are weak, the UI has to carry too much. [92]

Children of a Dead Earth simulates damage physically, including individual shells and shrapnel, but I did not find a documented system of persistent hull marks or decals. The damage model is described as physics-driven, with projectiles and armour interacting realistically, but the visual communication appears to rely on system failures and simulation outcomes rather than authored surface marks. I am marking its hull-mark readability UNSURE.

Freespace 2 is a useful older reference for beam and burn decals. Community documentation describes damage decals as simple black burn marks on the ship surface. Beam weapons leave a glowing decal that later blackens. A burn map can fade over time, and the original decal feature was limited and later deprecated in some builds. The important pattern is a fresh glowing line that cools into a black scar. That is directly applicable to lance and ion marks. [54]

War on the Sea gives a very direct readability lesson from its developer. The developer says the game shows damage as a texture over the damaged region of a ship rather than as small shell-hole decals, because decals are only clearly visible up close. The developer also says the region texture allows scorching based on fires, which is a stronger visual cue at distance. This is a strong argument for a two-tier system in Voidsworn: region-level damage texture and silhouette change at fleet distance, fine decals at close zoom. [124]

Per-mark reference entries

1. Lance: burn-through

Fleet distance. A straight, narrow line crossing the hull, one or two pixels wide at tactical zoom. Fresh colour is white-blue with a thin orange edge. It should read as a cut, not as a crater. If it crosses the hull edge, it should break the silhouette slightly so the line is visible even against a dark hull.

Evolution. Fresh: bright white-blue core, sparks and vapour jetting from the cut, thin smoke. Cooling: core fades to orange, edges darken, smoke thins. Scarred: black charred groove, faint ember or no glow, exposed inner structure as a thin bright line.

Strongest source or example. Homeworld 3 treats Energy and Ion as separate damage types with distinct visual treatments, and its Splat Damage system creates directional surface scars rather than generic stickers. Freespace 2 beam decals follow the same fresh glow to black scar pattern. Judgement on the exact line width and colour for Voidsworn. [1]

2. Plasma: splash craters

Fleet distance. A cluster of overlapping circular craters, roughly 20 to 30 percent of the hull width. Fresh impact is bright orange-white at the centres with dark rims and a splash of ejecta. It should read as a molten splash, not a single clean hole.

Evolution. Fresh: molten centres, ejecta sparks, fast-rising smoke. Cooling: centres darken to brown and black, rims cool to dark grey, residual glow in the deepest pits. Scarred: dark glassy crater field with cracked edges, no glow.

Strongest source or example. Homeworld 3 explicitly uses High Explosive as one of its four damage types and its official material describes unique impact craters for different weapon types. Battlefleet Gothic fires and critical damage provide a high-salience secondary cue for the cooling stage. Judgement on crater count and spread for Voidsworn. [1]

3. Gauss: punctures

Fleet distance. A small, sharp dark dot with a bright rim, or a short stitching line of dots. Each puncture is tiny relative to the hull, so at fleet distance one hit reads as a single hole, and multiple hits read as a line or cluster. Do not give gauss a long persistent glow.

Evolution. Fresh: bright white rim, brief sparks, no fire. Cooling: rim darkens, hole becomes black. Scarred: clean black hole with a ring of cracked metal.

Strongest source or example. Homeworld 3 uses Kinetic as a distinct damage type, and its Splat Damage system alters the hull surface at the impact point rather than adding a generic scorch. Starsector's small decal tiles show how tiny marks become speckle at distance, which is the risk gauss marks must avoid. Judgement on the clean-hole shape for Voidsworn. [1] [30]

4. Torpedo: blast craters

Fleet distance. A large irregular crater, roughly 30 to 40 percent of the hull width, with torn petal edges. Fresh impact is a bright orange-white flash with a rolling smoke plume and debris. This is a silhouette-changing mark and should be one of the strongest far-distance cues on a badly damaged ship.

Evolution. Fresh: flash, large smoke plume, flying debris. Cooling: crater darkens, embers glow inside, smoke becomes thin and dark. Scarred: black crater with exposed decks and torn metal, no glow.

Strongest source or example. Homeworld 3 High Explosive damage and its transition from surface scars to hull breaches is the closest model for a crater that changes the hull surface and eventually the silhouette. Battlefleet Gothic's fires and critical damage support the idea that a torpedo hit should also create a secondary fire or smoke cue. Judgement on crater scale for Voidsworn. [1]

5. Flak: pockmarks

Fleet distance. Many small, shallow dents, dark grey or brown, with no glow. At tactical distance they merge into a speckled patch rather than reading as individual marks. Flak should look like abrasive damage, not like a hit from a main gun.

Evolution. Fresh: brief spark and dust puff, no persistent glow. Cooling: dents darken. Scarred: a field of small pits, maybe shiny bare metal at the centres.

Strongest source or example. Starsector's damage decal sheet is a good example of small marks that read as speckle at distance, and its random tile overlay is a warning about how quickly small marks become noise. Homeworld 3 Kinetic damage supports the idea of a non-glowing, physical impact mark. Judgement on density and colour for Voidsworn. [1] [30]

6. Bio: acid pitting

Fleet distance. Irregular blotches with a sickly green-yellow edge, not circular. They should look wet or corroded, not like gunfire. At fleet distance a bio mark should read as a discoloured patch that spreads along panel lines and eats into the hull, not as a crater.

Evolution. Fresh: bright green-yellow bubbling edge, thin vapour, maybe droplets. Cooling: colour dulls to olive, edges darken. Scarred: pitted, pockmarked corrosion with exposed structure and dried residue.

Strongest source or example. I did not find a primary source that documents an acid-pitting hull mark in the reference games. This entry is judgement based on the visual language of corrosion and the brief's requirement that bio weapons feel different from plasma and gauss. UNSURE. The closest structural analogue is Homeworld 3's principle that each damage type gets its own visual treatment, but the specific acid colour and spreading behaviour are my design judgement. [1]

7. Ion: burns

Fleet distance. Branching blue-white electrical scorch marks, like lightning or coral, with a dark charred centre. Ion should be a line-and-branch mark, not a crater. At fleet distance the player should see a brief blue-white flash, then a dark branching scar.

Evolution. Fresh: bright blue-white arcs, flickering, ozone sparks. Cooling: arcs stop, glow fades to blue embers, char darkens. Scarred: black branching lines with occasional blue flicker.

Strongest source or example. Homeworld 3 treats Ion as its own damage type, separate from Energy and Kinetic, which supports giving ion a distinct branching electrical language. Freespace 2 beam decals show the fresh-glow-to-black-scar pattern that ion should follow. Judgement on the branching shape for Voidsworn. [1]

8. Ram: crumple

Fleet distance. A large-scale deformation of the hull silhouette, crushed panels, a bent or torn edge, or a visible bite taken out of the outline. This is the strongest far-distance cue because it changes the shape of the ship, not just its surface colour. There should be no persistent glow after the impact, only sparks and debris in the fresh stage.

Evolution. Fresh: sparks, debris, sudden silhouette change, maybe a flash at the contact point. Cooling: exposed metal darkens, smoke from torn compartments. Scarred: permanent crumpled geometry, torn plating, no glow.

Strongest source or example. Homeworld 3's Splat Damage is the closest technical reference because it directly alters surface geometry at the impact point rather than adding a flat decal. Real-world collision damage supports the crumpled-panel language, but the exact deformation budget is judgement. UNSURE on how much geometry deformation Godot can afford with 20 ships on screen. [1]

9. Boarding: breaches

Fleet distance. A ragged dark opening in the hull, roughly door-sized or larger, with torn edges and a faint warm interior light or intermittent spark. At fleet distance a boarding breach should read as a black hole with a small light inside, not as a crater. It should be distinguishable from a torpedo crater by its torn, inward-folding edges and the presence of a pod or tendril silhouette.

Evolution. Fresh: sparks, flashing lights, maybe a boarding pod embedded in the breach. Cooling: opening darkens, sparks become intermittent. Scarred: blackened breach, patched edges, occasional spark or interior glow.

Strongest source or example. Homeworld 3 uses hull breach FX as part of its damage stages, and Battlefleet Gothic uses boarding actions and critical damage as part of its combat language. The specific visual of a torn boarding breach is judgement. UNSURE whether a dark breach will read at fleet distance against a dark hull without a small light or silhouette cue. [1]

10. Battery: generic lighter mark

Fleet distance. A small, shallow scorch or dent, dark grey-brown, low contrast, with no strong glow and only a brief spark. Battery fire is the most common weapon kind in Voidsworn, so this mark must be the lightest in the hierarchy. Individually it should be almost invisible at fleet distance. Collectively, many battery marks should accumulate into general hull grime, not into a field of competing craters.

Evolution. Fresh: small spark, dust puff, dark smudge. Cooling: smudge fades. Scarred: faint dark speck or shallow dent, contributing to a dirty, worn hull.

Strongest source or example. Starsector's small decal tiles are the closest example of a low-salience generic damage mark that overlays the hull without trying to be a weapon signature. Homeworld 3's Kinetic damage provides the non-glowing physical-impact language. The low-contrast battery mark is judgement based on the brief's statement that batteries are the most common weapons in the game. [1] [30]

Readability rules

Silhouette beats surface. If a mark does not change the outline, it is a secondary cue. Budget at least one silhouette-changing mark per badly damaged ship: ram crumple, large torpedo crater, or boarding breach. At fleet distance the eye reads shape before it reads texture. This is judgement, supported by the War on the Sea developer's statement that small decals are only visible up close and that region-level damage texture is a stronger cue. [124]

Set a mark budget per hull. Cap high-salience marks at roughly four to six per ship. Cap total individual decals at roughly twelve to twenty. Beyond that, merge damage into a grime texture or shader mask rather than stacking more small decals. These numbers are judgement, not sourced. The principle is supported by Starsector's overlapping decal tiles, which show how random small marks become noise when they pile up. [30]

Use a two-tier damage system. Tier one is the fleet-distance layer: silhouette change, large colour patches, fresh glows, smoke and fire. Tier two is the close-zoom layer: punctures, pitting, cracks, exposed internals, weeping fluid. The fleet layer must work at 20 ships. The close layer is for inspection and should be culled or faded at distance. War on the Sea's developer explicitly chose region-level texture over small decals because decals fail at distance. [124]

Build a contrast hierarchy. One fresh bright mark per ship at a time. Once it cools, it should drop in contrast so the next fresh hit reads. Do not let every mark glow at once. If everything glows, nothing reads. This is judgement, supported by Homeworld 3's staged damage states, where smoke gets thicker and darker and fire and sparks are added only as severity rises. [5]

Make accumulation change the hull, not just add objects. Fresh marks glow, cooling marks desaturate, scarred marks darken. Many small marks should merge into a grime layer, not remain individual distinct decals. Homeworld 3's Splat Damage transitions from surface scars to hull breaches and secondary hot spots, which is the right model: the hull itself should look progressively damaged, not just decorated with stickers. [1]

Use narrow colour families per weapon. Lance and ion: blue-white to black. Plasma and torpedo: orange-white to dark brown. Gauss and flak: grey to black. Bio: green-yellow to olive. Ram: bare metal to dark. Boarding: black with a warm interior light. This lets the player identify weapon type by colour at a glance, which is exactly what Homeworld 3 is doing with its four distinct damage types. Judgement on the specific hues for Voidsworn. [1]

Use smoke and fire as a severity channel, not the only channel. Homeworld 3 layers smoke, fire, hull breach FX, and sparks on top of the surface damage. Sins of a Solar Empire 2 shows the failure mode: particle effects alone can leave hulls looking pristine at fleet distance. Smoke and fire are excellent for severity and motion, but they must be paired with hull marks and silhouette change. [5] [111]

Place marks deliberately. Random decal placement creates clutter. Use authored damage sockets, decal projectors, or placement rules tied to panel lines, hardpoints, and silhouette edges. Starsector's random tile overlay is cheap and works for grime, but it cannot carry nine weapon signatures. For signature marks, deliberate placement is necessary. [30]

Cull at distance. At tactical zoom, hide the smallest marks: flak pockmarks, gauss punctures, battery scorches. Merge them into a texture. Show only large marks, fresh glows, and smoke or fire. At close zoom, reveal the small marks. This is the two-tier rule applied to individual decals.

Test with 20 damaged ships at fleet camera distance. The readability test is not one hero ship. It is a full fleet, all damaged, at the tactical camera. If the fleet reads as a uniform dirty mass, the mark budget is too high or the contrast hierarchy is too flat. This is judgement, but it follows directly from the brief's stated problem.

Failure modes to avoid. Decal soup, where too many small marks compete and nothing stands out. Glow inflation, where every hit glows and the player cannot see the fresh or severe hits. Same-shape language, where every mark is a circular crater and the player cannot tell lance from plasma from gauss. Distance blindness, where marks only read at close zoom and the fleet looks pristine at tactical distance, which is the Sins of a Solar Empire 2 problem. Texture noise, where damage reads as dirt rather than as a hit. Silhouette destruction, where too much deformation makes the ship class unreadable. Performance collapse, where too many decals or expensive shaders break the 20-ship frame budget. [111]

Ranked recommendations

1. Make silhouette-changing marks the top priority. Ram crumple, large torpedo craters, and boarding breaches should be authored first, because they read at fleet distance when surface decals do not. Supported by War on the Sea's distance lesson and Homeworld 3's geometry-altering Splat Damage. [1] [124]

2. Enforce a strict mark budget and merge excess damage into a grime texture. Without a budget, 20 damaged ships become decal soup. The budget is judgement, but the risk is demonstrated by Starsector's overlapping decal tiles and Sins 2's particle-only damage. [30] [111]

3. Build a two-tier system: fleet-distance damage texture and silhouette layer, plus close-zoom decals. This is the single most important architectural decision for readability at 20 ships. It directly follows the War on the Sea developer's choice of region texture over small decals. [124]

4. Give each weapon family a distinct shape and colour language. Lance and ion as lines and branches, plasma and torpedo as crater clusters, gauss and flak as punctures and pocks, bio as corrosion, boarding as a torn breach. Homeworld 3's four distinct damage types show the value of this discipline. [1]

5. Make fresh marks glow briefly and cool to dark scars. This gives the player a timeline of the battle and prevents every mark from competing at once. Supported by Freespace 2's glowing-then-blackened beam decals and Homeworld 3's staged damage states. [5]

6. Use smoke, fire, and sparks as a severity channel, but never as the only channel. They are high-salience motion cues, especially at fleet distance. Sins 2 shows what happens when they are the only channel. [111]

7. Keep battery marks light and low-contrast. Batteries are the most common weapon, so their marks must accumulate into grime, not into signature craters. This is judgement based on the brief's weapon table.

8. Place signature marks deliberately, not randomly. Random decals are fine for grime but not for weapon identification. Use damage sockets or placement rules tied to hull geometry.

9. Cull small marks at fleet distance and reveal them at close zoom. This preserves readability without losing detail for inspection.

10. Playtest with 20 damaged ships at the actual tactical camera distance, not one ship in isolation. The readability problem is a fleet problem, not a single-ship art problem.

UNSURE list

Bio acid pitting visual language. I found no primary source documenting acid-pitting hull marks in the reference games. The green-yellow colour, spreading behaviour, and weeping detail are my judgement. UNSURE.

Ram crumple geometry budget in Godot. Homeworld 3 alters surface geometry, but I do not know how much deformation Voidsworn can afford with 20 ships on screen. This needs a technical performance test. UNSURE.

Boarding breach readability at fleet distance. A dark breach may disappear against a dark hull. It may need a small interior light, a blinking spark, or a silhouette cue to read at tactical zoom. UNSURE.

Battlefleet Gothic: Armada 2 hull decal specifics. I found critical damage, fires, turret loss, and subsystem states, but no primary source documenting persistent hull decals. My claims about BFGA2 are limited to those systems. UNSURE on its hull-mark technique.

Children of a Dead Earth visual hull marks. The physics damage model is documented, but I did not verify a persistent decal or surface-mark system. UNSURE.

Nexus: The Jupiter Incident damage marks. I did not find primary documentation of its hull damage visuals. UNSURE.

Exact mark budget numbers. The four-to-six high-salience marks and twelve-to-twenty total decals are judgement, not sourced. They need playtesting at the target camera distance and fleet size. UNSURE.

Godot decal projector performance with many marks on 20 ships. I do not have a verified performance figure for the target platform. This needs a prototype test before the mark budget is locked. UNSURE.

Sins of a Solar Empire 2 hull damage system specifics. Player complaints strongly suggest weak hull marks, but I did not find a developer statement describing the exact system. The negative lesson is well supported by player reports, but the technical details are UNSURE.
