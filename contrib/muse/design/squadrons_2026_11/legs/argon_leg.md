CHAIR HEADER (Rey): Argon leg for issue #70, run Nov 2, 2026, about 7:50 to 7:57 PM CST (runtime measured). Model gates verified by the browser run: picker showed 4 Argon selected and the prompt bar read "Argon High" before submitting; the prompt bar still read "Argon High" after sending. No AI Ultra upgrade accepted, no model switch. Per the issue block, Argon is drafts only; the chair synthesis rewrites anything it uses. Screening notes: its claim that rules overrides can spawn generic fighter hulls for Chorus carriers is treated as a hypothesis (the grounded pack found Chorus wings resolve to the spore kind in data); its root-cause fix (keying craft meshes by faction and role) is adopted on its own merits. Its per-game comparator text is heavily marked IMPRESSION by the leg itself and is weighted accordingly.

---

1. Comparator breakdown
Homeworld 2 (Relic Entertainment, 2003)

Representation: Per the Homeworld 2 manual and the game's .squadron and .ship tuning scripts, strike craft are built, selected, and commanded as single squadron units composed of multiple independent 3D craft meshes (for example, 5 craft for Hiigaran Interceptors and Bombers, and 7 craft for Vaygr Assault Craft and Lance Fighters).

Movement: Per the manual, squadrons launch sequentially from internal carrier or mothership bays, assemble into parade or combat formations (Delta, Broad, X, Claw, Sphere), and break formation when engaging. In combat, interceptors execute high-speed strafing passes with 3D turn reversals while bombers fly coordinated dive passes over capital hulls [IMPRESSION]. Squadrons persist on the map until destroyed, and can be ordered to dock with a carrier bay to repair and replace lost craft for free (documented in the manual).

Loss read: Each craft in the squadron tracks its own hit points in the engine; as the squadron takes fire, individual craft explode and vanish one by one, shrinking the visible formation until docked for reinforcement (documented in the manual).

Tactical distance read: At zoomed-out tactical sensor levels, individual 3D craft hulls become tiny specks; persistent ribbon engine contrails (fx_weapons.gd:624 in Voidsworn already cites this concept) and a single shared tactical selection bracket carry the unit's position, heading, and speed [IMPRESSION].

Homeworld 3 (Blackbird Interactive, 2024)

Representation: Per Blackbird Interactive's pre-release developer updates on strike craft and formations, squadrons remain consolidated tactical units represented by 5 to 8 individual craft meshes sharing one overhead unit badge and health bar.

Movement: Craft launch from carrier hangar slots, lock into geometric formation shapes during transit, and peel off individually into ballistic attack passes that skim capital hull surfaces and megalith terrain (documented in BBI strike craft dev blogs). Surviving squadrons persist and dock to replenish lost members [IMPRESSION].

Loss read: The shared squadron health bar depletes as individual craft take fatal hits and detonate out of the formation [IMPRESSION].

Tactical distance read: At normal battle camera distances, BBI relies on bright engine flare sprites, thick engine contrail ribbons, and a consolidated unit icon tethered to the formation centroid so the player tracks the maneuver group rather than individual hulls [IMPRESSION].

Battlefleet Gothic: Armada 1 and 2 (Tindalos Interactive, 2016 and 2019)

Representation: Per the official game guides and in-game hangar tooltips, strike craft (Fury Interceptors, Starhawk Bombers, Assault Boats) are treated as expendable ordnance waves launched from carrier bays using finite hangar charges and cooldown timers. On screen, each wave is drawn as a tight flock of 6 to 10 miniature craft meshes under a single floating banner badge [IMPRESSION].

Movement: Waves launch straight out of the carrier hull and move across the 2D battle plane as a unified cluster [IMPRESSION]. Fighters set to escort/CAP orbit friendly capital ships in a continuous defensive ring; bombers and assault boats fly straight through the target's point-defense turret envelope (battle.js:774 mirrors this flak gauntlet) to dump ordnance in a single run before vanishing or returning to bay [IMPRESSION]. When fighter waves intercept enemy bombers, both flocks merge into a circling dogfight loop until one wave is wiped out [IMPRESSION].

Loss read: Point-defense turret tracers and fighter interceptions shoot down individual miniature meshes out of the flock while the wave's durability bar ticks down under its banner [IMPRESSION].

Tactical distance read: Colored tactical banners, pulsing ordnance wave icons, bright engine dots, and dense point-defense tracer streams carry the entire read from full fleet altitude [IMPRESSION].

Sins of a Solar Empire 2 (Ironclad Games, 2024)

Representation: Per Ironclad Games and Stardock developer journals and game documentation, carrier capitals and cruisers host a set capacity of squadrons, each represented by a squadron token on the HUD and 4 to 8 individual simulated strike craft meshes in 3D space (varying by faction and fighter vs bomber role) [IMPRESSION].

Movement: Squadrons launch from carrier bay hardpoints, fly a continuous idle orbit around their host carrier when on station, and streak across the gravity well to execute looping strafe or torpedo passes against assigned targets [IMPRESSION]. Opposing fighter squadrons break formation into turning tail-chases when dogfighting. Squadrons persist indefinitely without fuel timers [IMPRESSION].

Loss read: Individual craft meshes are destroyed during combat passes, and the host carrier automatically rebuilds missing craft in the background on a cooldown timer, launching replacements that fly out to rejoin the surviving formation [IMPRESSION].

Tactical distance read: Team-colored engine contrails, consolidated squadron icons, and the sweeping geometry of the formation's turn arc carry the read when zoomed out to the gravity-well view [IMPRESSION].

Transferable lessons for Voidsworn

Break the rigid block during combat passes (Homeworld 2 and 3): A formation should hold recognizable geometry in transit, but craft meshes must physically peel off with staggered timing during attack runs and dogfights so the wing never reads as a single rigid block (ship_view.gd:116 to 122).

Map stances to physical station behavior (Battlefleet Gothic: Armada 1 and 2): Orbiting friendly hulls when set to screen and flying physical attack passes through flak (battle.js:774) when set to strike or hunt turns rules stances (battle.js:622 to 630) into instant visual telemetry.

Vary craft count by faction and thin the flock with HP loss (Homeworld 2 and Sins of a Solar Empire 2): Letting Chorus swarm at 6 craft while Hegemony flies a disciplined 4-craft flight, and popping individual wingmen as the wing's HP pool drops, fixes both faction identity and the static full-strength illusion.

Never let an idle wing park stationary (Sins of a Solar Empire 2): Continuous hex patrol orbits and desynchronized per-craft weave keep wings alive between turns while capital ships hold station.

2. Per-faction craft spec
Fixing the wrong-craft root cause

Today, hull_table.gd:15 resolves strike craft meshes strictly by rules hull ID (craft|fighter = "S1_51", craft|bomber = "S2_23", craft|spore = "B23_51"), data.js:113 omits an sq key for Sunward Crusade, and wingKind (battle.js:1170, godot/rules/rules.gd:3271) or adaptation wings (battle.js:361) can spawn generic 'fighter' or 'bomber' hulls for a carrier. That is why Chorus ships can display metal fighters (S1_51) under rules overrides (FINDINGS R80). hull_table.gd must resolve craft meshes via a two-key lookup of (carrier_faction, wing_role) with both a fighter and a bomber/heavy variant defined per faction so no faction ever falls back to a shared generic mesh.

Scale against capital hulls

Today every squadron craft draws at L = 3.84 world units (ship_view.gd:72, hull_table.gd:26 to 28), which equals 29.6 px at 1080p and 59.1 px at 4K (7.7 px/unit and 15.4 px/unit), or 37% of a Frigate's 10.4-unit length. To create clear role separation at battle zoom without dropping below the 10 px readability floor at 1080p, split fighter and bomber scales: standard fighters shrink slightly to 3.20 world units (24.6 px at 1080p, 49.3 px at 4K, 31% of a Frigate) for agile proportions, while bombers grow slightly to 4.20 world units (32.3 px at 1080p, 64.7 px at 4K, 40% of a Frigate) for heavy ordnance presence, with organic swarm tuning for Chorus below.

Faction | Fighter Craft (fighter role) | Bomber Craft (bomber / spore role) | Length (World Units) | Length (1080p / 4K px) | Craft per Wing (Full HP)
Sunward Crusade | Censer Interceptor | Pyre-Lance Torpedo Boat | 3.20 / 4.20 | 24.6 / 49.3 px ; 32.3 / 64.7 px | 4
Hegemony Navy | Grid-7 Interceptor Drone | Grid-12 Strike Drone | 3.20 / 4.20 | 24.6 / 49.3 px ; 32.3 / 64.7 px | 4
Ashfall Hullbreakers | Shrike Gun-Cutter | Gaff-Skiff Breacher | 3.50 / 4.30 | 27.0 / 53.9 px ; 33.1 / 66.2 px | 5
The Chorus | Chitin-Mite Hunter | Bile-Cyst Spore | 3.00 / 3.50 | 23.1 / 46.2 px ; 27.0 / 53.9 px | 5
The Glasswrights | Starling Shard | Heliograph Prism | 3.30 / 4.00 | 25.4 / 50.8 px ; 30.8 / 61.6 px | 5
Eclipse (Data-fenced) | Oculus Automaton | Corona Singularity Node | 3.30 / 4.00 | 25.4 / 50.8 px ; 30.8 / 61.6 px | 4

[Chair note: the table above shows Chorus at 5 craft per wing as returned; the leg text in sections 2 and 3 consistently uses 6 for Chorus. Recorded as an internal inconsistency in the leg.]

1. Sunward Crusade

What launches: Censer Interceptor (fighter) and Pyre-Lance Torpedo Boat (bomber). Heavy black-iron strike craft inscribed with chalked pilot oaths and tall radiator fins (lore_bible_r8.md line 161; also add explicit sq: 'fighter' to data.js:113).

Silhouette: The Censer is a narrow forward-tapering iron dart with clipped delta winglets and a prominent dorsal radiator spire behind the cockpit. The Pyre-Lance has a broad blunt prow, twin underslung torpedo cradles, and a split vee-tail radiator assembly.

Size against hulls: Shrink fighters from 3.84 to 3.20 world units (24.6 px at 1080p, 49.3 px at 4K); grow bombers to 4.20 world units (32.3 px at 1080p, 64.7 px at 4K).

Colours and finish: Matte hammered black-iron hull (#4a4440), warm copper-rust trim (#c8501f), bold frost-white (#f0f4f8) chalked oath stripes across the nose and dorsal spine, and ember-orange armored viewport slits (#ff7a2a).

Engine look: Single deep-bell thruster nozzle on fighters and twin bells on bombers burning ember-orange (#ff7a2a), glowing dimly like banked furnace coals at rest (R55) and flaring bright orange-white with soot-edged exhaust ribbons on thrust.

2. Hegemony Navy

What launches: Grid-7 Interceptor Drone (fighter) and Grid-12 Strike Drone (bomber). Standardized unmanned registry craft and fighter screens built for fleet order (lore_bible_r8.md lines 24, 216, 226).

Silhouette: The Grid-7 is a crisp, cockpit-less diamond wedge with forward-swept twin sensor prongs and razor-straight wing edges. The Grid-12 is a wide flying-wing bomber with an internal ventral payload notch and twin canted tail fins.

Size against hulls: Shrink fighters to 3.20 world units (24.6 px at 1080p, 49.3 px at 4K); grow bombers to 4.20 world units (32.3 px at 1080p, 64.7 px at 4K).

Colours and finish: Clean satin pale-grey plating (#c4ccd5), crisp steel-blue wing chevrons (#3a78d0), and implant-blue navigation strobes (#5fa0ff) that pulse in locked fleet-wide synchronization across every craft in the wing.

Engine look: Wide horizontal slot thrusters emitting cool implant-blue (#5fa0ff), maintaining a uniform dim calibration bar at rest (R55) and drawing a clean, geometric blue light ribbon in motion.

3. Ashfall Hullbreakers

What launches: Gaff-Skiff Breacher (bomber, primary per data.js:118) and Shrike Gun-Cutter (fighter, used when rules or adaptation spawn a fighter wing). Bolted-together scrap raiders and pack-hunting ordnance skiffs (lore_bible_r8.md).

Silhouette: The Gaff-Skiff is a bulky, asymmetric twin-boom breacher with an offset cockpit cage, jagged prow harpoon prongs, and external bomb racks slung beneath a shorter port stub-wing. The Shrike Gun-Cutter is a stubby, twin-engine rotary-gun sled with notched salvage plates.

Size against hulls: Shrink the Shrike fighter slightly to 3.50 world units (27.0 px at 1080p, 53.9 px at 4K); grow the primary Gaff-Skiff bomber to 4.30 world units (33.1 px at 1080p, 66.2 px at 4K) so its heavy scrap silhouette reads clearly.

Colours and finish: Charred rust-brown base hull (#6a2c22), mismatched blood-rust salvage panels (#b8402a), weathered bare-metal weld seams, and harsh red-orange hazard lights (#e0402c).

Engine look: Oversized, mismatched cylindrical thruster cans glowing furnace red-orange (#e0402c), flickering unevenly around a dim idle glow at rest (R55) and belching jagged orange-red exhaust trails when accelerating.

4. The Chorus

What launches: Bile-Cyst Spore (spore/bomber, primary per data.js:120) and Chitin-Mite Hunter (fighter, replacing the erroneous metal S1_51 fighter mesh whenever a Chorus ship spawns a fighter wing per R80). Living void-organisms budded from carrier brood-sacs (lore_bible_r8.md lines 339, 349).

Silhouette: The Bile-Cyst is a teardrop-shaped bio-form with a ribbed head shield, a swollen translucent rear abdomen sac, and four trailing whip-tendrils. The Chitin-Mite is a sleeker, crescent-headed predatory organism with Scythe-like fore-carapaces and a segmented whip tail.

Size against hulls: Shrink individual creatures from 3.84 to 3.00 world units (23.1 px at 1080p, 46.2 px at 4K) for Chitin-Mites and 3.50 world units (27.0 px at 1080p, 53.9 px at 4K) for Bile-Cysts, offset by increasing the swarm count to 6 organisms per wing.

Colours and finish: Following the lore bible override (lore_bible_r8.md line 339) over stale purple data: wet dark olive-brown flesh (#3b4228), ochre chitin carapace plates (#a4913a), and glowing bile yellow-green internal sacs and pore lines (#d6d24a).

Engine look: No metal nozzles; the translucent rear abdomen sac and bio-vent pulse with a dim bile yellow-green bioluminescence (#d6d24a) at rest (R55) and leave a wispy yellow-green spore trail when swimming through space.

5. The Glasswrights

What launches: Starling Shard (fighter, per lore_bible_r8.md line 416) and Heliograph Prism (bomber). Faceted crystal motes and silver-vaned vessels carrying bound starlight (lore_bible_r8.md line 405).

Silhouette: The Starling Shard is a slender three-vaned crystal needle flanked by two detached silver arc-vanes that float beside the prism body. The Heliograph Prism is a broader, open-centered diamond crystal frame suspended around a blazing spherical core of stored light.

Size against hulls: Shrink the Starling Shard to 3.30 world units (25.4 px at 1080p, 50.8 px at 4K); grow the Heliograph Prism to 4.00 world units (30.8 px at 1080p, 61.6 px at 4K).

Colours and finish: High-gloss clear silver-white crystal facets (#eef3f1), warm electrum-silver trim (#d7c88a), and refracted seafoam-cyan internal light (#9fffd2) shining through the crystal core.

Engine look: No mechanical exhaust; the rear crystal vertex focuses a crisp point of seafoam-cyan light (#9fffd2) that glows softly at rest (R55) and draws a razor-sharp prismatic light ribbon during flight.

6. Eclipse (Fenced as data-dependent)

Rules dependency note: Eclipse currently sets sq: null (data.js:128) and has no carrier hull in its roster. These craft specs are fenced for future use if Eclipse receives a carrier hull, activates the Drone bay refit (lore_bible_r8.md line 512), or spawns adaptation wings (battle.js:361).

What launches: Oculus Automaton (fighter/drone role, lore_bible_r8.md line 469) and Corona Singularity Node (bomber role). Uploaded-mind machine vessels and geometric construct drones.

Silhouette: The Oculus Automaton is a flat, non-aerodynamic dark obelisk split down its centerline by a vertical glowing slot and flanked by two detached chevron plates. The Corona Node is an interlocking octagonal ring housing a suspended white-gold aperture sphere.

Size against hulls: Shrink the Oculus Automaton to 3.30 world units (25.4 px at 1080p, 50.8 px at 4K); grow the Corona Node to 4.00 world units (30.8 px at 1080p, 61.6 px at 4K).

Colours and finish: Following the lore bible override (lore_bible_r8.md line 469) over stale green data: deep violet-black machine plates (#1a1423), pale burnished gold trim (#e6c875), and piercing white-gold corona light (#fff4cc).

Engine look: A suspended white-gold corona ring (#fff4cc) inside the rear aperture that shimmers dimly at rest (R55) and leaves a crisp gold-white wake in transit.

3. Formation and movement behaviour
Unified kinematic controller

Replace the static four-mesh offset setup in ship_view.gd:116 to 122 and 1280 to 1292 with a single parameterized SquadronFormationController on the squadron ship_view unit. Each craft i in 0 .. N_max - 1 has a local home slot S_i, a phase offset phi_i = i * 1.37 radians, and a state blend between four kinematic modes: On-Station Patrol, Spline Transit, Attack Run, and Furball Dogfight.

Craft count and HP-linked attrition

Although a wing is one rules unit with a single HP pool (battle.js), keeping all craft visible at 1 HP makes wings look immortal and static. Link visible craft count to hp_ratio = hp / max_hp across four thresholds:

100% to 76% HP: Full N_max craft visible (4 for Crusade, Hegemony, Eclipse; 5 for Hullbreakers, Glasswrights; 6 for Chorus).

75% to 51% HP: N_max - 1 craft visible; R80 Stage 0 surface scorches appear on surviving craft.

50% to 26% HP: max(2, N_max - 2) craft visible; the ruled R80 smoke ribbon ignites on the lead craft and one wingman.

25% to 1% HP: 2 craft minimum visible (so a wing always reads as a formation rather than a lone micro-hull), both trailing R80 smoke ribbons.

Loss transition: Whenever damage crosses a threshold downward during flak (battle.js:774) or dogfights, the outermost surviving wingman plays a 0.35 s spiral roll and a miniature pop-flash (2.5 units diameter) before hiding its mesh.

Formation geometry, spacing, and faction variation

All formations fit inside a 12.0 x 12.0 world unit footprint (one hex, corner radius 10). Local home slots (forward_x, height_y, lateral_z) in world units and continuous weave parameters per faction are:

Hegemony (Locked Wedge, 4 craft): Slots (0, 0, 0), (-4.0, +0.4, +3.8), (-4.0, -0.4, -3.8), (-7.6, +0.8, 0). Weave amplitude 0.15 units at 0.5 Hz; all 4 craft bank at the exact same angle in unison.

Sunward Crusade (Lance Chevron, 4 craft): Slots (0, 0, 0), (-4.4, +0.8, +4.4), (-4.4, -0.8, -4.4), (-8.8, 0, 0). Weave amplitude 0.45 units at 0.65 Hz with independent roll micro-corrections (+-6 deg).

Glasswrights (Starling Diamond, 5 craft): Slots (0, 0, 0), (-3.8, +1.2, +4.6), (-3.8, -1.2, -4.6), (-7.6, -0.8, +2.3), (-7.6, +0.8, -2.3). Harmonic figure-eight weave (0.95 units lateral, 0.70 units vertical at 0.85 Hz) so craft smoothly trade height like flocking starlings (lore_bible_r8.md line 416).

Hullbreakers (Raider Pack, 5 craft): Asymmetric slots (0, +0.3, -0.6), (-3.2, -0.9, +4.8), (-4.6, +1.1, -4.2), (-7.1, +0.5, +2.8), (-8.4, -1.0, -2.1). Aggressive erratic weave (1.35 units amplitude at 1.15 Hz, +-14 deg roll jitter) so craft jostle like pack hunters.

Chorus (Brood Swarm, 6 craft): 3D cluster at (+1.5, +0.4, 0), (-1.8, +1.6, +3.9), (-2.2, -1.4, -3.7), (-5.1, -0.8, +4.8), (-5.6, +1.5, -4.4), (-8.2, +0.2, +0.5). 3D Lissajous swimming motion (1.60 units amplitude at 1.30 Hz) plus a +-8 deg pitch undulation so organisms swim rather than fly.

Eclipse (Geometric Lattice, 4 craft): Planar diamond at (+4.2, 0, 0), (0, +1.8, +4.5), (0, -1.8, -4.5), (-4.2, 0, 0). Zero organic weave; craft make crisp, quantized attitude adjustments.

On-station behaviour (eliminating the frozen diamond)

Instead of holding fixed coordinates where only the lead craft bobs (ship_view.gd:1280 to 1282), every stationary wing flies a continuous On-Station Patrol inside its hex, keyed off carrier wing stance (battle.js:622 to 630):

Screen stance: The formation centroid orbits the hex center in a 3.2-unit radius circle at 3.6 world units/s (one full orbit every 5.6 seconds), banking inward at 18 deg with engines glowing dimly (R55).

Strike or Hunt stance: The formation centroid flies a 4.2 x 2.0 unit figure-eight racetrack inside its hex (period 4.8 seconds) aligned toward the nearest enemy ship, keeping every craft moving at 3.2 to 4.0 world units/s.

Launch, transit, attack run, and dogfighting

Launch (0.95 seconds, replacing sprite streaks at fx_weapons.gd:969 to 983): At battle start, spare replacement (data.js:136), or Admiral scramble (battle.js:1080), craft meshes spawn at the carrier's hangar offset at 0.25x scale and launch in staggered 0.10 s intervals. Craft scale to 1.0x over 0.20 s, bank 35 deg outward, and fly a curved Bezier path into the target hex at 2.2x parent capital ship transit speed, settling into patrol with an eased braking phase over the final 0.25 s (R55).

Hex transit (1.75x capital ship flight speed): During the swarm phase (battle.js:1064, 1157), the wing traverses its hex spline at 1.75x capital ship speed with an eased braking phase over the final 25% of the distance (R55). Each wingman applies spline yaw and up to 45 deg turn-bank roll with a 0.06 s * i delay behind the lead craft, replacing rigid speed-lag (ship_view.gd:1286 to 1292) with a fluid whip-turn.

Attack run (1.40 seconds, flown by craft meshes, replacing parked _strafe at fx_weapons.gd:609 to 640):

Flak Approach (0.00 to 0.45 s): Craft ignite full engine trails, break formation with 0.07 s stagger, and dive from their hex to the target hull's edge at 2.5x ship speed, jinking laterally (+-1.2 units) through point-defense flak bursts (battle.js:774). Any threshold craft loss pops during this phase.

Ordnance Pass (0.45 to 0.90 s): Fighters skim 2.8 units above the target deck at 50 deg bank firing rapid tracer bursts; bombers fly a level run 3.5 units overhead releasing visible bomb salvos; Chorus Bile-Cysts dive to 1.8 units height and convulse to eject glowing spore-sacs onto the hull (fx_weapons.gd:609 to 640 sprites now spawn from the moving craft).

Breakaway & Eased Return (0.90 to 1.40 s): Craft execute a 65 deg banking peel-off turn, arc back to their hex, and ease smoothly back into their patrol orbit (R55).

Admiral Scramble Commands (battle.js:1080, data.js:207 to 229): When Ashgrove, Reyes, Old Mott, Matriarch, or Tamsa triggers a scramble, the extra wing launches on a fast 0.75 s curve and all active friendly wings pulse their engine flares to 1.6x brightness and trail width while executing their +50% damage attack runs.

Dogfighting (1.25 seconds when wing attacks wing): Both wings surge to the shared hex boundary and merge into a 7.0-unit radius 3D Furball. Each craft follows an offset figure-eight chase loop at 2.4x ship speed (55 to 70 deg roll angles), trading short tracer bursts before peeling back to its home hex.

Death and replacement (data.js:136): Wings never dock to rearm. When wing HP hits zero, surviving craft break outward and detonate in staggered 0.10 s fireballs (or bile-bursts for Chorus); when a carrier replaces a lost wing from its spare pool (data.js:136), the new wing flies the 0.95 s mesh launch from the carrier.

4. Readability at the battle camera

At the standard battle camera (170 world units out), resolution scale is 7.7 px per unit at 1080p and 15.4 px per unit at 4K (the owner's play resolution), with a hard 10 px (1.30 world units) floor for readable features at 1080p.

What reads at full board view (170 units out)

Formation shape and motion signature (92 x 92 px at 1080p, 185 x 185 px at 4K): A 12 x 12 unit wing formation is the primary board-level icon. Before noticing individual hulls, the player reads Hegemony's rigid 4-ship wedge, Hullbreakers' loose 5-ship pack, Glasswrights' weaving 5-ship starling diamond, and Chorus's 6-organism swimming swarm.

Outer hull silhouette (23 to 33 px long at 1080p, 46 to 66 px at 4K): At 3.00 to 4.30 world units, overall planform (iron dart, flying wing, asymmetric twin-boom skiff, teardrop spore, crystal shard) and broad two-tone color blocks (>= 1.5 units / 11.5 px at 1080p) read cleanly.

Engine glow points and contrail ribbons: Per R55, dim engine glows at rest (0.5-unit bloomed cores = 4 px at 1080p, 8 px at 4K) mark every craft's tail. In patrol and attack runs, 0.45-unit wide (3.5 px at 1080p, 7.0 px at 4K) vertex-faded ribbons stretching 5.0 to 9.0 units (38 to 69 px at 1080p) behind each craft make speed, heading, and turn arcs readable across the whole board (fx_weapons.gd:624).

Stance posture: A circular hex orbit (screen) versus an enemy-pointed figure-eight (strike/hunt) communicates carrier stance (battle.js:622 to 630) at a glance.

What only reads on zoom (< 80 world units camera distance)

Features smaller than 1.30 world units (< 10 px at 1080p): Crusade chalk oath lettering and dorsal radiator vanes, Hullbreaker weld plates and underslung bombs, Chorus chitin rib segments and trailing tendrils, Glasswright floating silver tip-rings, and R80 Stage 0 surface scorch decals.

Minimum motion floor to never read as static

Below 1.0 world unit/s (7.7 px/s at 1080p), slow drift aliases against the pixel grid and looks frozen. Every on-station wing must maintain at least 3.0 world units/s (23 px/s at 1080p, 46 px/s at 4K) of patrol velocity plus at least 0.40 units of desynchronized per-craft weave (except Hegemony, whose synchronized bank and 3.6 units/s patrol orbit carry its mechanical motion).

Damage read within R80 (fresh vs mauled at board distance)

Respecting FINDINGS R80 (Stage 0 damage surfaces plus a smoke ribbon below half total HP, and no extra per-craft damage states), a player tells a mauled wing (<= 50% HP) from a fresh one at board distance in under half a second via two combined cues:

Thinned formation count: A wing below 50% HP has dropped from 4-6 craft down to 2-4 craft, leaving visible gaps in the formation silhouette.

The R80 Smoke Ribbon: Below 50% HP, the lead craft and one wingman trail a high-contrast dark charcoal ribbon (0.85 world units wide = 6.5 px at 1080p, 13.1 px at 4K; 7.5 units long = 58 px at 1080p) laced with faction-colored ember sparks (or dark olive spore-ichor mist for Chorus) that cuts across the bright engine trails. On zoom, the Stage 0 scorch and pitting surface shader is visible on the surviving hulls.

5. Frame budget at 20 ships plus wings
Worst-case board arithmetic

Per R1, battles reach 20 capital ships plus wings, and the pack sets a worst case of 14 wings active on the board at once. With 4-to-6 craft per wing, a mixed board averages 70 craft meshes, and an all-Chorus 14-wing board peaks at 84 craft meshes (14 x 6, compared to 56 at today's fixed 4). Budget all caps against 84 active craft meshes alongside 20 capital ships so the game holds the 40 fps floor at 4K on an RTX 5080 required by the damage spec.

Geometry, batching, and animation caps

Mesh triangle budget: Cap LOD0 strike craft meshes at 350 triangles per craft (84 craft x 350 = 29,400 triangles board-wide, less than a single capital ship hull) and LOD1 meshes at 120 triangles per craft.

Draw call cap via instancing: Today ship_view.gd:116 to 122 spawns four separate MeshInstance3D nodes per wing (56 to 84 draw calls at 14 wings). Replace the child meshes in each wing with a single MultiMeshInstance3D per wing (4 to 6 instances sharing one material, with per-instance custom data carrying engine glow intensity and R80 Stage 0 damage float) plus one batched ribbon mesh for engine trails and one for R80 smoke ribbons. This caps all 14 wings at 14 hull draw calls + 14 engine trail draw calls + up to 14 smoke ribbon draw calls = 42 draw calls maximum.

CPU animation cost drivers:

Zero Skeleton3D rigs, zero Node3D physics bodies, and zero per-craft raycasts.

Update all 4 to 6 instance transforms per wing inside a single flat loop in ship_view.gd (<= 84 Transform3D math evaluations per frame across the entire board).

Drive Chorus body undulation and Glasswright floating rings inside the vertex shader via TIME and INSTANCE_ID at zero CPU cost.

Sprite and particle traffic caps:

Physical mesh launches and attack runs eliminate the 6 launch sprites per wing (fx_weapons.gd:969 to 983) and the 3 fake craft-pass streaks (fx_weapons.gd:609 to 640).

Cap active combat particles during an all-wing Admiral Scramble (battle.js:1080) at 12 ordnance sprites per attacking wing and a hard pool of 160 active squadron particles board-wide (tracers, flak puffs, bomb flashes, spore bursts).

Degradation hierarchy (Distance, Low settings, Safe Mode)

At camera distance (> 130 world units out): Swap craft to LOD1 (<= 120 tris), disable R80 Stage 0 surface scorch texture sampling (unreadable below 10 px), and halve engine/smoke ribbon segments from 12 quads to 6 quads.

At Low graphics settings: Cap maximum visible craft at 4 per wing across all factions (56 craft max), step off-turn patrol orbit math to 30 Hz, and reduce trail lengths by 40%.

In Safe Mode: Freeze intra-wing sine weave and continuous hex patrol orbits (wings hold static formation offsets at rest and only animate during hex transit and attack runs), merge per-craft engine trails into a single wing-centroid ribbon, and render the R80 < 50% HP smoke indicator as one flat scrolling quad per mauled wing.

What must be measured before sign-off

Profile CPU script time (ship_view.gd + fx_weapons.gd) and 4K GPU frame time in Godot on an RTX 5080 in a torture test scene: 20 damaged capital ships + 14 Chorus 6-craft wings (84 craft), all below 50% HP with R80 smoke ribbons active, executing a simultaneous Admiral Scramble attack run through flak.

6. Owner questions

Visible craft count and HP attrition

A (Recommended): Faction-varied craft count (4 for Crusade/Hegemony/Eclipse, 5 for Hullbreakers/Glasswrights, 6 for Chorus) that drops wingmen at 75%, 50%, and 25% HP down to a 2-craft floor.

B: Keep a fixed 4 craft per wing for all factions, but drop to 3 craft at 66% HP and 2 craft at 33% HP.

C: Keep a fixed 4 craft per wing that never lose members until 0 HP, relying solely on the R80 < 50% HP smoke ribbon for damage read.

Stakes: Option A gives Chorus and Hullbreakers immediate swarm/pack silhouettes at board zoom and makes damage readable before half HP, at the cost of raising the 14-wing ceiling from 56 to 84 instanced meshes.

Craft size against capital hulls

A (Recommended): Split scale by role: fighters shrink slightly to 3.00 to 3.50 units (23 to 27 px at 1080p) and bombers grow to 4.00 to 4.30 units (31 to 33 px at 1080p).

B: Keep today's uniform 3.84 world units (30 px at 1080p, 59 px at 4K) across all fighters, bombers, and spores (ship_view.gd:72).

C: Shrink all craft to 2.40 world units (18.5 px at 1080p, 23% of a Frigate) for stricter capital ship scale.

Stakes: Option A makes fighters and bombers distinguishable by size at board zoom while keeping both well above the 10 px readability floor, whereas Option C risks losing hull silhouettes at 1080p.

Per-faction mesh matrix coverage

A (Recommended): Build both a Fighter mesh and a Bomber/Spore mesh for all 5 active launching factions (10 meshes total) and key hull_table.gd by (faction, role).

B: Build only the primary role meshes each faction launches in standard fleet lists (Crusade/Hegemony/Glasswright fighters + bombers, Hullbreaker bomber only, Chorus spore only = 8 meshes) and force rules overrides like adaptation (battle.js:361) to use the faction's primary mesh.

Stakes: Option A permanently prevents the R80 wrong-craft bug under any future doctrine or adaptation rule, while Option B saves 2 meshes by clamping Chorus and Hullbreakers to one visual craft type each.

Eclipse squadron craft scope

A (Recommended): Spec the design now (Section 2), but defer modeling the 2 Eclipse drone meshes until an Eclipse carrier or Drone bay refit (lore_bible_r8.md line 512) is added to data.js.

B: Model and wire the 2 Eclipse drone meshes in Issue 67 now so they are ready for adaptation wings (battle.js:361) or future Drone bay rules.

Stakes: Option A focuses Issue 67 modeling budget on the five factions that actually launch wings today (data.js:116 to 128), while Option B front-loads 2 meshes for future rules work.

Attack run animation pacing during the swarm phase

A (Recommended): Staggered overlapping mesh attack runs (1.40 s per wing, launched with a 0.20 s stagger between wings in the swarm phase so 10 wings resolve in ~3.2 s total).

B: Strictly sequential mesh attack runs (1.40 s each, one wing after another).

Stakes: Option A keeps late-run carrier battles brisk (~3.2 s per swarm phase) and creates a thrilling mass-strike spectacle, whereas sequential runs would stretch a 14-wing swarm phase to nearly 20 seconds.
