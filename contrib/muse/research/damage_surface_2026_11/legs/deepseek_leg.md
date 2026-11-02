DeepThink: verified ON (pale blue). Search: verified ON (pale blue).

1. Per-game breakdown

Battlefleet Gothic: Armada 1 and 2. Light hits read mainly as shield flares and small hull scorches; the hull itself stays largely intact. Heavy hits produce critical damage that disables specific parts, and critical damage can trigger fires that cause hull damage over time; every 100 hull points lost also removes a defence turret, so functional loss is a visible damage state. A crippled ship is one with engines or weapons disabled and fires still burning; the silhouette changes through lost turrets and drifting fire, not through a large cut in the hull [IMPRESSION]. The mix is mostly decals and particles plus hardpoint removal; mesh change is concentrated in lost turrets and engines, not general hull geometry. At the tactical camera, fires and missing turrets carry the read; small scorch decals only show on zoom. Budget is kept by tying effects to hardpoints and by capping fires, with no per-hit hull mesh rebuild. Transferable lesson: functional loss and fire read farther than small surface marks.

Homeworld 2 and 3. Homeworld 2 uses scripted 3D effects and texture overlays; the TriDamage parameter in the ship config raises or lowers damage-texture frequency, and heavy battles can cost framerate. Homeworld 3's Splat Damage is the important change: instead of slapping impact stickers on the hull, it creates dynamic impact points that alter surface geometry and properties in the exact area hit by a specific weapon type, with a per-ship dynamic damage texture that transitions from surface scars to hull breaches, hot spots, and burn marks. Light hits are weapon-specific surface scars; heavy hits deform the hull and add burn marks; crippled sections move toward breach states, with persistent scars that carry between missions. The mix is mesh deformation plus dynamic texture, not decals. At distance, Splat Damage is prioritized on larger units and capital ships because the system is resource-intensive; fighters and corvettes use simpler damage modeling. Budget is class-scaled: detailed damage only where it reads. Transferable lessons: surface deformation and weapon-specific impact points read as real damage; persistent scars tell a ship's history; detail must be rationed by ship class.

Sins of a Solar Empire II. Combat is shields, armour, hull points, durability, armour strength, and hull regeneration; capital ships, titans, and starbases enter a Crippled Hull state instead of dying at zero hull. Visually, damage is still driven mainly by shield effects and particles; players on the official news page ask for dynamic damage models and textures that update as the ship loses health, which is a fair signal that the shipped surface-damage layer is thin. At distance, the health bar and shield flare carry the read; hull surface detail is minimal. Budget is kept by simple, pooled effects across large fleets rather than per-ship deformation. Transferable lesson: a crippled state gives a clear "still fighting" band that a surface-damage system can sit on top of.

Star Wars: Empire at War. Damage is hardpoint-based: each hardpoint carries Damage_Decal, Damage_Particles, and fire bones, so a destroyed subsystem shows a decal, particles, and fire at that location. Light hits mark the hardpoint; heavy hits destroy it; a crippled ship has lost weapons, engines, or shield generators, and the silhouette changes through missing hardpoint geometry. The mix is decals, particles, and hardpoint mesh removal; there is no general hull cut. At distance, hardpoint loss and fires read; the decals themselves are close-up detail. Budget is per-hardpoint and cheap. Transferable lesson: tying decals to functional damage makes surface marks feel consequential rather than decorative.

Nebulous: Fleet Command. Armor health is stored as a texture mask layered across the hull and takes localized damage only where it is hit; both penetrating and non-penetrating attacks degrade the mask. Light hits leave local armor degradation; heavy hits penetrate and damage components; a crippled ship has destroyed components and stripped armor. The mix is a texture mask plus component damage, with relatively little particle work. At tactical distance, the armor mask is a subtle read; the game expects closer inspection. Budget is strong because the mask is a texture operation, not per-hit mesh work. Transferable lesson: a localized texture mask gives cheap, spatial damage memory that scales to many ships.

Star Citizen (additional entry). The damage system uses four values at the impact point: temperature, burn, thickness, and deformation. Those values make the hull glow with heat, burn and bubble paint, peel paint to expose metal, dent and deform the surface, and cut holes that expose internal wiring and mechanics; internals are modeled under most of the hull, not only in special locations. Light hits are paint and heat; heavy hits deform and peel; crippled sections expose internals. The mix is procedural mesh deformation plus decals and particles. It is a close-up game, so surface detail is the point; the same density would be too fine at a tactical camera. Budget is high per ship, suited to a few ships rather than 20. Transferable lesson: the break reads because internals exist and are exposed; a hole without internals is exactly the cardboard cut-out the owner rejected.

Transferable lessons for Voidsworn.

Homeworld 3: weapon-specific surface deformation and persistent scars read as real damage, but the system must be rationed to capital ships because it is expensive.

Nebulous: a localized texture mask is a cheap way to give every ship spatial damage memory across a large fleet.

Star Citizen: expose real internals at the break; an empty cavity behind a cut hole reads as a shell.

Battlefleet Gothic: functional loss and fire carry at distance better than small hull decals.

Sins of a Solar Empire II: a crippled state is a readable band; surface damage should support it, not replace it.

2. Staged damage spec

The stage ladder stays: stage 0 above f 0.8; stage 1 at f 0.8; stage 2 at f 0.6; stage 3 at f 0.4; stage 4 at f 0.2 or broken. The change is that stages 1 through 3 are surface damage only. The open break is stage 4.

Stage 1 (f <= 0.8). One spreading scorch overlay at the section anchor, radius L x 0.10, plus one smaller burn mark at radius L x 0.05 elsewhere in the section. No dent, no crater, no hole. Scorch heat 0.15, as today. On a Frigate (L 10.4) the main scorch is 1.04 world units: 8 px at 1080p and 16 px at 4K. On a Battleship (L 33.6) it is 3.36 units: 26 px at 1080p and 52 px at 4K. Stage 1 is the first readable stage on a battleship; on a frigate the 8 px scorch is below the 10 px readability line and only begins to read at stage 2.

Stage 2 (f <= 0.6). The scorch grows to radius L x 0.16. Add a shallow dent at the anchor, radius L x 0.08, depth 15 percent of radius, plus a hot torn-plate rim around the scorch (emissive, not a counted flash). Add two smaller burns. Frigate scorch is 1.66 units, 13 px at 1080p and 26 px at 4K; Battleship scorch is 5.38 units, 41 px at 1080p and 83 px at 4K. The dent is 0.83 units on a Frigate (6 px at 1080p) and 2.69 units on a Battleship (21 px at 1080p). This is the first stage that reads on every hull class at the full-board camera.

Stage 3 (f <= 0.4). Still surface only. Scorch reaches radius L x 0.22. Add one crater kind (melted bowl, no hole) at radius L x 0.06, with a bright molten lip. Add two or three burns. Add persistent fire and smoke from the section: two fire emitters and one smoke trail emitter per damaged section. No hole. Frigate scorch is 2.29 units, 18 px at 1080p and 35 px at 4K; Battleship scorch is 7.39 units, 57 px at 1080p and 114 px at 4K. The crater is 0.62 units on a Frigate (5 px at 1080p) and 2.02 units on a Battleship (16 px at 1080p); the crater itself is marginal on a frigate, but the fire and smoke carry the section.

Stage 4 (f <= 0.2 or broken). The open break. One real hole at radius L x 0.07, with torn plate edges that overlap the opening, a short recessed throat, and fire inside the throat. Add a second hole at radius L x 0.045 for weight 2 and up. Add three fire emitters and one smoke trail per broken section. Frigate hole is 0.73 units, 5.6 px at 1080p and 11 px at 4K; Battleship hole is 2.35 units, 18 px at 1080p and 36 px at 4K. The hole reads by contrast and by the fire inside, not by raw diameter.

The open break and the cardboard problem. The stage 3 and stage 4 holes the owner rejected were cut-outs with flat lines inside: the cavity existed, but it had no readable internal structure, so it read as a hole in a shell. The new stage 4 break differs in four ways. First, the throat is short but modeled, with two or three cross-members or pipe stubs visible inside, so the eye catches depth. Second, a fire emitter sits inside the throat, not only around the rim, so the interior glows and flickers. Third, the torn plate rim is irregular and overlaps the opening in several places; it is not a clean outline. Fourth, the rim has a hot emissive edge that spills light onto the surrounding scorch. The Job 1 interior darkness rule still applies, but the break must not be a flat black disc; it needs ember noise and at least one internal silhouette.

Per-weapon marks. Scorch, burn, ion surface pattern, and hatch breach stay surface at stages 1 through 3; the hatch can show a blown decal, but no hole. Dent and ram crumple are surface mesh deformation at stages 2 and 3. Crater and plasma/blast marks are surface bowls at stage 3; they do not cut through. Slot (lance burn-through) is a deep molten channel at stage 3, but it only cuts at stage 4 if it falls inside the break footprint. Cluster and flak pits stay surface at stage 3; individual pits may tear through only at stage 4. Gauss punctures stay surface dimples at stage 3 and become through-holes only at stage 4. Hole kind is stage 4 only.

Counts and frame budget. Per section: stage 1 has 2 marks; stage 2 has 4; stage 3 has 4 (scorch, crater, two burns); stage 4 adds the break plus two burns, but the surface marks from stage 3 remain. The existing SEC_MARK_CAP 4 and MARK_CAP 12 per ship are kept. Emitters: stage 3 uses 2 fire plus 1 smoke per damaged section; stage 4 uses 3 fire plus 1 smoke. Worst case at 20 ships is 180 fire emitters and 60 smoke emitters, all pooled sprites with roughly 20 particles each, or about 3,600 particles. Mesh rebuilds happen only on stage transitions, on the worker thread, with one interior mesh and one overlay mesh per ship. Counted flashes remain at zero for damage; hot rims and embers are emissive, not counted. Safe mode draws flat scorch quads, no dents or craters, no hole geometry, and one fire sprite and one smoke sprite per damaged section.

Repair and squadrons. When a section repairs and its stage falls, fires and smoke stop immediately, scorch fades over two to three seconds, and dents and craters remain as permanent scars. This preserves the cumulative scar record from Job 1 step 7 without keeping the gameplay state. Squadrons stay at stage 0. A squadron is L 2.6, about 20 px at 1080p for the whole craft; any section mark would be under 5 px. Instead, show a single hull-state tint and a spark trail at low hull, which reads without spending the stage ladder.

3. Faction variants

Chorus (organic). Surface stages are wounds, not plate damage. Stage 1 is a discolored, weeping welt with pulsing inflammation and a faint yellow-green glow. Stage 2 is a torn wound with exposed sinew and a brighter glow at the edges. Stage 3 is a deep suppurating wound with exposed internal tissue, drifting spores, and a smoke-like haze. Stage 4 is a mouth-like rupture with soft sphincter edges, a glowing yellow-green interior, and spore puffs; it is not a metal hole. Regrowth reverses the visuals: as the stage falls, the wound closes from the edges, the glow fades, and the flesh knits, using the existing organic path and wound_kind 1. Fires become spore emitters, not flames.

Glasswrights (crystal, id ithar). Scorch is replaced by crazing and cracks. Stage 1 is a web of fine cracks that catch light. Stage 2 adds missing crystal flakes and a pale blue-white glow along fracture planes. Stage 3 is a deep fracture with prismatic light leaking from inside and silver support struts visible. Stage 4 is a jagged crystalline break with sharp shards around the opening and a bright prismatic core inside, not a dark throat. Use wound_kind 2. Smoke is replaced by a fine glittering dust.

Eclipse (machine, id deathless). Surface stages add darkened panels, scorched metal, severed conduits with violet arcs, coolant venting as white mist, and violet ember sparks. Stage 3 exposes machinery and flickering violet conduits. Stage 4 is a torn armor break with arcing cables, internal violet fire, and a coolant jet. Add wound_kind 3 for deathless so the machine path is not forced through the standard metal shader; the existing violet glow and ember trail already fit.

Sunward Crusade (voidsworn). Black iron with ember-orange damage glow. Scorch is soot black with hot orange rivets; fires are deep orange and smoke is thin and dark. The staged shape is unchanged.

Hegemony. Pale grey and steel blue. Scorch is grey soot; hot rims are blue-white; shield flicker precedes hull damage. Fires are small and clean-burning, with pale smoke. The staged shape is unchanged.

Ashfall Hullbreakers (corsair). Rust red with heavy soot. Scorch is thick black soot; fires are deep orange; smoke is dense and black. The existing engine soot extra fits. The staged shape is unchanged.

4. Build order against issue 49

Task 0: measurement only. Build a stage-by-stage capture sheet at battle-camera distance at 1080p and 4K on real hulls of Sunward Crusade, Hegemony, and one Chorus ship, using the current build. Measure frame cost with 20 ships on board, with fx.prof open, and record mark counts and emitter counts. Files: godot/fx/fx_ship.gd, godot/fx/fx_breach.gd, godot/fx/fx_pool.gd, godot/fx/fx.gd. Proof: capture sheet and a frame log. Ryan sees the baseline and the exact cardboard read he reported.

Task 1: remove cut holes from stages 1 through 3. In fx_ship.gd, _plan() around line 839, replace the stage 3 hole entry with a crater or slot surface mark and keep the stage 4 hole. Add the short modeled throat, internal cross-members, internal fire emitter, and irregular torn rim at stage 4. Files: godot/fx/fx_ship.gd (_plan(), _build_breach()), godot/fx/fx_breach.gd (hole and crater styles). Proof: captures of stage 3 and stage 4 on Sunward and Hegemony. Ryan sees no open hole at 20 to 40 percent section hull, and a stage 4 break that is not an empty shell.

Task 2: surface stage ladder. Add the stage 1 and stage 2 scorch and dent sizes, the stage 2 hot rim, and the stage 3 persistent fire and smoke. Modify _plan(), _set_burning(), and the style tables. Files: godot/fx/fx_ship.gd, godot/fx/fx_breach.gd, godot/fx/faction_looks.json. Proof: full stage capture sheet on Sunward and Hegemony. Ryan sees readable surface damage from stage 2 at the battle camera.

Task 3: per-weapon surface marks. Change the mark kinds so slot, crater, cluster, gauss, plasma, blast, ram, hatch, and ion stay surface at stages 1 through 3 and only cut at stage 4. Files: godot/fx/fx_breach.gd (kinds and styles), fx_ship.gd (_plan()). Proof: fire each weapon at a section and capture the before and after. Ryan sees lance burn-through as a molten channel, plasma as a crater, gauss as punctures, and no holes before stage 4.

Task 4: faction variants. Add wound_kind 3 for Eclipse in fx_breach.gd around the existing wound_kind parameter at lines 1641 and 1653. Tune the Chorus organic stage sizes and the Glasswright crack and prismatic behavior. Files: godot/fx/fx_breach.gd, godot/fx/fx_ship.gd (_build_organic_section), godot/fx/faction_looks.json, godot/render/hull_table.gd (FINISH). Proof: captures of Chorus, Glasswrights, and Eclipse at each stage. Ryan sees three distinct damage languages.

Task 5: budget and safe mode. Pool the new emitters, verify MARK_CAP 12 and SEC_MARK_CAP 4, add safe-mode simplified marks, and run a 20-ship frame check. Files: godot/fx/fx_pool.gd, godot/fx/fx_breach.gd, godot/fx/fx_ship.gd, play_godot_safe.bat. Proof: 20-ship frame log at 1080p and 4K, plus a safe-mode capture. Ryan sees 40+ fps and a safe-mode fallback that still reads.

The breach code decision. Keep the existing breach code as the heavy stage only. The machinery is sound: worker-thread mesh rebuilds, mark styles, one interior mesh and one overlay mesh per ship, and a cap of 12 marks. What failed was using cut holes at stage 3. Retire cut-hole usage before stage 4, keep the breach code for the stage 4 break, and extend it with the internal fire and torn rim described above. Retiring it entirely would throw away the only system that can produce a real open break and would force a new mesh path for a stage that appears rarely.

5. Owner questions

1. When should surface damage first become readable at the full-board camera?
A) Stage 1 on every hull class.
B) Stage 1 on capital ships, stage 2 on frigates. [PICK]
C) Stage 2 on every hull class.
Stakes: earlier readability versus visual clutter on small hulls.

2. Where should the first real open break sit?
A) Stage 4 only, at 20 percent section hull or broken. [PICK]
B) Late stage 3 for capital ships only.
C) Death only.
Stakes: the cardboard risk versus the drama of seeing a section fail before death.

3. Should repaired sections keep visible scars?
A) Keep dents, craters, and faded scorch as permanent scars. [PICK]
B) Fade all damage when repaired.
C) Keep only a slight scorch tint.
Stakes: a ship's history versus a clean look after repair.

4. What should squadrons show when damaged?
A) Keep stage 0, no damage visuals.
B) A single hull-state tint and a low-hull spark trail. [PICK]
C) The full stage ladder.
Stakes: readability at 20 px per craft versus cost and clutter.

5. Should Eclipse get a dedicated machine damage variant?
A) Yes, add a deathless wound variant with arcs, coolant, and violet internals. [PICK]
B) Reuse the standard metal path with violet glow.
C) No variant.
Stakes: faction identity versus scope.
