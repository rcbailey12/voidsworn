# Squadron design spec (board issue 70)

Chair synthesis of four legs (Rey blind leg, DeepSeek, Qwen, Argon as screened drafts), grounded in the evidence pack at repo main 7677728. This is the spec Codex builds issue 67 from. FINDINGS rulings override every other doc; where this spec touches a ruling it says so.

## Verdict

GO WITH CONDITIONS.

The one condition: Owner Question 1 (visible craft count tracking wing HP) needs the owner's ruling before the count piece builds, because it extends the R80 squadron damage ruling. Everything else in this spec is buildable now.

## 1. Why this spec exists: the current state

The owner complaint (FINDINGS R80, Ryan, Nov 2, 2026, RULED): squadrons need their own detailing pass. They look static, some factions show the wrong craft (regular fighters from Chorus ships is his example), and they need more detail and more views.

The grounded facts behind the complaint (pack, file:line):

- There are exactly three squadron hulls in the game (data.js:70 to 72): fighter, bomber, and the Chorus spore, which is a bomber underneath (sq:'bomber'). All three are shared.
- The craft mesh comes from a three-entry table with no per-faction entry (godot/render/hull_table.gd:15): craft|fighter = "S1_51", craft|bomber = "S2_23", craft|spore = "B23_51". Five launching factions share three meshes; per-faction difference is at most finish and glow on a shared mesh.
- The Sunward Crusade roster entry has no sq key at all (data.js:113) and falls through to the default. FACTIONS sq values sit at data.js:116 to 128: Hegemony 'fighter', Hullbreakers 'bomber', Chorus 'spore', Glasswrights 'fighter', Eclipse null.
- Wing kind is decided per wing at launch by wingKind (battle.js:1170, mirrored at godot/rules/rules.gd:3271): for a faction whose set is 'fighter', player-side wings alternate fighter and bomber by launch index when the enemy has any air, and are all bombers when the enemy has none. So fighter and bomber wings alternate per launch for Crusade, Hegemony, and Glasswright carriers. This matters for section 3: both roles are on screen for those factions, so both roles need a faction mesh and a readable role difference.
- A wing is drawn as one lead craft mesh plus three rigid duplicates at fixed offsets (godot/render/ship_view.gd:116 to 122). The duplicates never bob, bank, weave, or separate; their only motion is a uniform speed lag (ship_view.gd:1286 to 1292). Only the lead gets the idle bob (ship_view.gd:1280 to 1282).
- Launch is not flown by the meshes: six engine-coloured sprites streak from carrier to hex (godot/fx/fx_weapons.gd:969 to 983). The attack run is not flown either: _strafe draws sprite streaks per craft pass (fx_weapons.gd:609 to 640), and the comment at fx_weapons.gd:624 admits the vapour trail exists "so a wing reads as moving lights at battle zoom". The formation stays parked while the lights attack.
- Wing HP is invisible on the model. Craft are never lost individually. A wing at 2 HP looks identical to a fresh wing.
- A wing is a single rules unit with one HP pool (battle.js:1064, 1157). Wings are autonomous in their own swarm phase, leashed to a living carrier at SQ_LEASH 8 hexes (battle.js:1128), with a carrier wing stance of strike, screen, or hunt (battle.js:622 to 630). Wings attacking capital ships run the flak gauntlet first (battle.js:774). Wings never return to rearm; they fight until destroyed and are replaced from spares, one spare per hangar slot (data.js:136).
- Craft draw today at L = 3.84 world units (ship_view.gd:72, hull_table.gd:26 to 28), about 30 px at 1080p and 59 px at 4K at the battle camera (about 170 units out, 7.7 px per unit at 1080p, 15.4 at 4K). A frigate draws at 10.4 units, so one craft is about 37 percent of a frigate's length. Formation footprint is about 13 by 12 units, roughly one hex (hex corner radius 10).
- Enemy wings exist now (enemy wing stances at battle.js:381, adaptation wings at battle.js:361); the old R23 note (no enemy squadrons) is stale. This spec covers both sides.
- R55: engines glow dimly at rest. Every engine look below keeps that.
- R80 damage ruling for squadrons: stage 0 damage surfaces plus a smoke ribbon below half total HP, and no per-craft damage states beyond that. Section 7 builds exactly that as the baseline.

## 2. Comparator summary

What the four reference games do with strike craft, as the legs sourced it. Where a leg marked a claim as impression or secondary, that is noted; the design lessons do not depend on the impression-grade details.

### Homeworld 2 (Relic, 2003)

Representation: strike craft are individual craft grouped into squadrons at build time, with squadron size fixed per hull. DeepSeek gives 3 for scouts, 5 for interceptors, 6 for bombers, 7 for assault craft; the Argon leg gives 5 for Hiigaran interceptors and bombers and 7 for Vaygr assault craft and lance fighters, sourced to the manual and the game's squadron and ship tuning scripts. Qwen gives roughly five to seven, sourced to the manual and developer commentary.

Movement: squadrons launch sequentially from carrier or mothership bays, assemble into named parade and combat formations (Delta, Broad, X, Claw, Sphere per the Argon leg, manual-sourced), break formation to engage with strafing passes and 3D turn reversals, and dock to rearm and repair. Docked squadrons replace lost craft free of charge.

Loss read: each craft tracks its own hit points; individual craft explode and vanish one by one, and the squadron visibly thins until it docks for reinforcement.

Tactical distance read: engine trails and the shape of the formation carry the read; at sensor zoom the craft are specks and the trails plus a shared selection bracket carry position, heading, and speed.

### Homeworld 3 (Blackbird Interactive, 2024)

Representation: individual craft in squadrons of about 5 to 8, sharing one unit badge and health bar (BBI pre-release developer updates, per the Argon leg; Qwen marks its count range as impression from launch-window coverage).

Movement: craft launch from hangar slots, hold geometric formation in transit, and peel off individually into attack passes that skim capital hull surfaces. Formations reflow spacing around obstacles and execute barrel rolls and high-G turns (DeepSeek). Formations were explicitly improved after demo feedback, and the non-linear inverse perspective scaling was fixed so fighters stay visible and selectable zoomed out (DeepSeek).

Loss read: individual craft are lost from the squadron; the shared health bar depletes as craft detonate out of the formation.

Tactical distance read: formation behaviour and strafing arcs first, engine flare sprites and contrail ribbons second, with a unit icon tethered to the formation centroid. The Rey leg also notes the Splat Damage material from Blackbird's Unreal Fest 2023 talk: the capital ships carry the visible record of the fight.

### Battlefleet Gothic: Armada 1 and 2 (Tindalos, 2016 and 2019)

Representation: squadrons are ordnance waves, not persistent individual ships. A launch bay puts a squadron token or tight flock (6 to 10 miniature craft meshes under one banner badge, Argon leg, marked impression) onto the plane on finite hangar charges and cooldowns. The BFG tabletop rules describe squadrons as attack waves resolved against turret defence, and the digital games mirror that (Qwen, codex and tutorial text).

Movement: waves fly straight out across the 2D plane as a unified cluster. Fighters set to escort orbit friendly capital ships in a continuous defensive ring; bombers and assault boats fly one attack run through the target's point-defence envelope and dump ordnance. In Armada 2, fighters and bombers restore their charge only if they return intact (DeepSeek). When fighter waves intercept bombers, both flocks merge into a circling dogfight loop (Argon leg, impression).

Loss read: turret fire is the counter; a failed turret roll can remove the whole wave, fighters are removed before other ordnance in a mixed wave (DeepSeek), and point-defence tracers pick individual meshes out of the flock while the wave's durability bar ticks down (Argon leg, impression).

Tactical distance read: the token or banner itself, its course, coloured wave icons, engine dots, and the tracer streams meeting it. Individual craft are not the unit of readability.

### Sins of a Solar Empire 2 (Ironclad, 2024)

Representation: strike craft are hosted per carrier as squadrons of per-craft models. A TEC hangar hosts two squadrons of six fighters or four bombers (DeepSeek). The Argon leg gives 4 to 8 individual simulated craft per squadron varying by faction and role, from Ironclad and Stardock developer journals (marked impression in places).

Movement: craft orbit their host carrier when on station, peel off to strike targets anywhere in the gravity well, and return. Dogfighting opposing squadrons break into turning tail-chases. Squadrons persist without fuel timers.

Loss read: losses are per craft, and the host carrier rebuilds missing craft for free over time, launching replacements that fly out to rejoin the formation.

Tactical distance read: the moving cloud of small craft, their engine lights, team-coloured contrails, squadron icons, and the sweeping geometry of the turn arc. Per-craft detail matters only on zoom. Most weapons cannot target the craft, so the read is the swarm's motion, not craft under fire.

### Transferable lessons (all four legs agree)

1. The formation, not the single craft, is the unit of readability at board distance. Formation shape, motion, engine lights, and trails carry the read; panel detail is a zoom reward.
2. A rigid block always reads as static. Every comparator gives craft independent motion: reflow, peel-off, weave, or orbit. Voidsworn's rigid duplicates are the outlier.
3. An on-station holding pattern is what keeps wings alive on screen between orders. Sins 2's orbit is the strongest version; no comparator parks a wing.
4. The attack run is a single staged, committed event: approach through the flak, a firing pass, and an exit. BFG makes the flak and the run one readable event.
5. The launch and the replacement must be visible flights, not pop-ins (Homeworld docking cycle, Sins 2 rebuild launches, BFG waves returning). Voidsworn's rules version of this is the spare launch (data.js:136).
6. Voidsworn's specific problem has no direct comparator answer: its wing is one rules unit with one HP pool, so the spec borrows motion and readability without borrowing per-craft loss simulation. The one place that borrowing is proposed, visible count thinning, is Owner Question 1 (section 7), not settled spec.

## 3. Craft identity: the mesh matrix (the root fix)

Problem: hull_table resolves craft meshes by rules hull ID only (hull_table.gd:15), so every faction falls back to one of three shared meshes. That is the mechanical root of the wrong-craft complaint.

Settled fix:

- hull_table resolves craft meshes by a two-key lookup: (carrier faction, wing role). Wing role is fighter or bomber (the Chorus spore role maps to its bomber-role mesh).
- Build BOTH a fighter-role and a bomber-role mesh for all five launching factions: 10 meshes. No faction ever falls back to a shared generic mesh, under any doctrine, adaptation, or Command spawn path.
- Data flag for Opus and Codex (separate from the mesh work): the Sunward Crusade roster entry has no sq key (data.js:113, verified in the pack) and falls through to the default. The entry needs an explicit sq: 'fighter' so the faction's launch behaviour is stated, not inherited.

Craft names (one naming set per faction, used across this spec):

| Faction | Fighter role | Bomber / spore role | Craft per wing | Fighter length | Bomber length |
|---|---|---|---|---|---|
| Sunward Crusade | Ember Dart | Pyre-Lance | 4 | 3.2 | 4.2 |
| Hegemony Navy | Grid-7 Interceptor Drone | Grid-12 Strike Drone | 4 | 3.2 | 4.2 |
| Ashfall Hullbreakers | Shrike Gun-Cutter | Gaff-Skiff Breacher | 5 | 3.5 | 4.3 |
| The Chorus | Chitin-Mite Hunter | Bile-Cyst Spore | 6 | 3.0 | 3.5 |
| The Glasswrights | Starling Shard | Heliograph Prism | 5 | 3.2 | 4.2 |
| Eclipse (fenced, section 4.6) | Oculus Automaton | Corona Singularity Node | 4 | 3.3 | 4.0 |

Lengths in world units. Pixel equivalents at the battle camera (7.7 px per unit at 1080p, 15.4 at 4K): fighter 3.2 = 24.6 px / 49.3 px; bomber 4.2 = 32.3 / 64.7; Hullbreaker 3.5 / 4.3 = 27.0 / 33.1 at 1080p, 53.9 / 66.2 at 4K; Chorus 3.0 / 3.5 = 23.1 / 27.0 at 1080p, 46.2 / 53.9 at 4K; Eclipse 3.3 / 4.0 = 25.4 / 30.8 at 1080p, 50.8 / 61.6 at 4K.

Size rationale (chair): the size split is by role, not uniform. Because wingKind alternates fighter and bomber wings per launch for three of the five launching factions, a player sees both roles from the same carrier in the same battle; making bombers visibly larger than fighters is a real readability gain, and every size in the table stays well above the 10 px readability floor at 1080p. Chorus creatures are smaller per organism because the count goes up to 6; the swarm mass carries the read.

Worst case arithmetic: 14 wings on the board (pack working worst case) at the counts above peaks at 84 craft meshes (an all-Chorus board), against 56 at today's fixed four. Section 8 budgets against 84.

## 4. Per-faction craft detail

Colours are the shipped data palettes (data.js FACTIONS) unless the lore bible overrides, which it does for Chorus flesh and Eclipse. Bible references are to lore_bible_r8.md.

### 4.1 Sunward Crusade: Ember Dart (fighter), Pyre-Lance (bomber)

What launches: crewed black-iron strike craft, chalked pilot oaths, tall radiator fins (bible line 161).

Silhouette: the Ember Dart is a narrow forward-tapering iron dart with clipped delta winglets and a prominent dorsal radiator spire behind the cockpit. DeepSeek's Ember Dart description (single tall radiator spire, two swept fins, frost-white oath marking on the spine) and the Argon leg's Censer Interceptor converge on the same shape; the Dart name carries. The Pyre-Lance is the heavy role: broad blunt prow, twin underslung torpedo cradles, split vee-tail radiator assembly.

Colours and finish: matte hammered black iron, hull #4a4440, trim #c8501f, frost-white #f0f4f8 chalked oath stripes across nose and dorsal spine, ember-orange #ff7a2a viewport slits.

Engine: single deep-bell nozzle on the Dart, twin bells on the Pyre-Lance, ember-orange, glowing dim like banked coals at rest (R55), flaring orange-white with soot-edged exhaust ribbons on thrust.

Flight character: Lance Chevron formation (section 5), moderate weave, banks as a disciplined unit with small independent roll corrections.

### 4.2 Hegemony Navy: Grid-7 Interceptor Drone (fighter), Grid-12 Strike Drone (bomber)

What launches: standardized unmanned registry craft; the bible calls them small drone escorts and fighter screens (bible lines 24, 216, 226). The Argon Grid naming is adopted over Qwen's Registry Drone name for consistency with the two-role matrix.

Silhouette: the Grid-7 is a crisp, cockpit-less diamond wedge with forward-swept twin sensor prongs and razor-straight edges. The Grid-12 is a wide flying-wing bomber with an internal ventral payload notch and twin canted tail fins. Identical geometry across the wing is the point: Hegemony craft look interchangeable.

Colours and finish: clean satin pale grey #c4ccd5, steel-blue #3a78d0 wing chevrons, implant-blue #5fa0ff navigation strobes pulsing in locked synchronization across every craft in the wing. The synced pulse is the faction read at board distance.

Engine: wide horizontal slot thrusters, cool implant-blue, a uniform dim calibration bar at rest (R55), drawing a clean geometric blue ribbon in motion.

Flight character: Locked Wedge, tightest spacing, weave nearly zero, all craft bank at the exact same angle in unison (section 5). Hegemony is the one faction whose motion is synchronized, by design.

### 4.3 Ashfall Hullbreakers: Shrike Gun-Cutter (fighter), Gaff-Skiff Breacher (bomber)

What launches: bolted-together scrap raiders and pack-hunting ordnance skiffs. The bomber is the faction's primary wing kind in data (sq 'bomber'); the fighter covers rules and adaptation spawns.

Silhouette: the Gaff-Skiff is a bulky asymmetric twin-boom breacher with an offset cockpit cage, jagged prow harpoon prongs, and external bomb racks under a shorter port stub-wing. The Shrike is a stubby twin-engine rotary-gun sled with notched salvage plates. Nothing about either silhouette is symmetrical or parade-clean; DeepSeek's Scrap Hound (asymmetric welded plates, exposed engine block, trophy scraps lashed on) is the same read in one hull.

Colours and finish: charred rust-brown #6a2c22 base, mismatched blood-rust #b8402a salvage panels, weathered bare-metal weld seams, harsh red-orange #e0402c hazard lights.

Engine: oversized mismatched thruster cans, furnace red-orange, flickering unevenly around a dim idle at rest (R55), belching jagged exhaust trails on acceleration.

Flight character: Raider Pack, asymmetric slots, the largest and most erratic weave in the table (section 5). Craft jostle like pack hunters; spacing variance is a feature.

### 4.4 The Chorus: Chitin-Mite Hunter (fighter), Bile-Cyst Spore (spore role)

What launches: living void-organisms budded from carrier brood-sacs, never built (bible lines 339, 349). The spore hull already exists in data (data.js:72); it gets its own mesh here, and the fighter role gets the Chitin-Mite so no Chorus wing can ever draw a metal fighter mesh again.

Silhouette: the Bile-Cyst is a teardrop bio-form with a ribbed head shield, a swollen translucent rear abdomen sac, and four trailing whip-tendrils. The Chitin-Mite is sleeker: crescent head, scythe-like fore-carapaces, segmented whip tail. Rounded and organic against every other faction's angles; no hard edges, no wings (DeepSeek's Brood Spore description agrees).

Colours and finish: the bible palette governs over the data palette where they differ (pack): wet dark olive-brown flesh #3b4228 (bible line 339 flesh tones; the data base #57364c is superseded for the flesh read), ochre chitin #a4913a, bile yellow-green #d6d24a glow in internal sacs and pore lines.

Engine: none. The translucent rear abdomen sac and bio-vents pulse with dim bile yellow-green bioluminescence at rest (R55) and leave a wispy yellow-green spore trail in motion. Propulsion reads as swimming, not thrust (section 5 weave).

Flight character: Brood Swarm, a 3D cluster with continuous Lissajous swimming motion and pitch undulation; organisms drift individually even in transit. Six per wing, the largest count, at the smallest sizes: mass and motion carry the read.

### 4.5 The Glasswrights: Starling Shard (fighter), Heliograph Prism (bomber)

What launches: faceted crystal motes and silver-vaned vessels carrying bound starlight (bible line 405); the wings are called starling wings in the bible (line 416), and the Starling name is convergent across DeepSeek, Qwen, and Argon.

Silhouette: the Starling Shard is a slender three-vaned crystal needle flanked by two detached silver arc-vanes floating beside the prism body. The Heliograph Prism is a broader open-centred diamond crystal frame suspended around a blazing spherical core of stored light.

Colours and finish: high-gloss clear silver-white crystal #eef3f1, warm electrum-silver trim #d7c88a, refracted seafoam-cyan #9fffd2 internal light shining through the core.

Engine: no exhaust. The rear crystal vertex focuses a crisp point of seafoam-cyan light, soft at rest (R55), drawing a razor-sharp prismatic ribbon in flight. The internal stored light must be visible at board distance as a moving point of light; it is the faction tell.

Flight character: Starling Diamond with a harmonic figure-eight weave, craft smoothly trading height like flocking starlings (section 5). The widest graceful weave of the metal-adjacent factions.

### 4.6 Eclipse: Oculus Automaton (fighter), Corona Singularity Node (bomber) - FENCED

Eclipse fields no wings today: sq null (data.js:128), no carrier hull and no hangar anywhere in its roster. The full craft spec is written here so the design is complete; modelling is fenced (Owner Question 4) until an Eclipse carrier or the Drone bay refit (bible line 512) ships in data. The fiction anchor is the bible's tiny repair drones attending Eclipse works (bible line 469): these are machine drones, repair and escort in fiction first.

Silhouette: the Oculus Automaton is a flat, non-aerodynamic dark obelisk split down its centreline by a vertical glowing slot, flanked by two detached chevron plates. DeepSeek's Corona Drone (angular machine body, ring of corona light, single eye) and Qwen's Warden Drone (angular body, corona ring at the sensor head) converge on the same machine read. The Corona Node is an interlocking octagonal ring housing a suspended white-gold aperture sphere.

Colours and finish: the bible palette, not the stale data green (pack flags the data palette as stale; the damage research flagged the same): deep violet-black plates #1a1423, pale burnished gold trim #e6c875, piercing white-gold corona light #fff4cc.

Engine: a suspended white-gold corona ring inside the rear aperture, shimmering dim at rest (R55), leaving a crisp gold-white wake in transit. Steady and cold: no flicker, no flare variation.

Flight character: Geometric Lattice, planar diamond, zero organic weave; craft make crisp quantized attitude adjustments (section 5).

## 5. Formation geometry and weave

One system: a single parameterized formation controller on the squadron unit replaces the rigid four-mesh offset block (ship_view.gd:116 to 122). Each craft has a home slot, a phase offset (i times 1.37 radians in the Argon leg's controller sketch), and a blend between four kinematic modes: on-station patrol, spline transit, attack run, and dogfight (section 6). All formations fit inside a 12.0 by 12.0 unit footprint, one hex.

Home slots (forward x, height y, lateral z, world units) and weave parameters per faction, from the Argon leg's table, which is the only leg that specified slots numerically for all six factions:

- Hegemony, Locked Wedge, 4 craft: slots (0, 0, 0), (-4.0, +0.4, +3.8), (-4.0, -0.4, -3.8), (-7.6, +0.8, 0). Weave amplitude 0.15 units at 0.5 Hz. All craft bank at the exact same angle in unison. The synchronized exception: Hegemony's mechanical motion is carried by the synced bank and the patrol, not by per-craft weave.
- Sunward Crusade, Lance Chevron, 4 craft: slots (0, 0, 0), (-4.4, +0.8, +4.4), (-4.4, -0.8, -4.4), (-8.8, 0, 0). Weave amplitude 0.45 units at 0.65 Hz with independent roll micro-corrections of plus or minus 6 degrees.
- Glasswrights, Starling Diamond, 5 craft: slots (0, 0, 0), (-3.8, +1.2, +4.6), (-3.8, -1.2, -4.6), (-7.6, -0.8, +2.3), (-7.6, +0.8, -2.3). Harmonic figure-eight weave, 0.95 units lateral and 0.70 units vertical at 0.85 Hz.
- Hullbreakers, Raider Pack, 5 craft: asymmetric slots (0, +0.3, -0.6), (-3.2, -0.9, +4.8), (-4.6, +1.1, -4.2), (-7.1, +0.5, +2.8), (-8.4, -1.0, -2.1). Erratic weave 1.35 units amplitude at 1.15 Hz, plus or minus 14 degrees roll jitter.
- Chorus, Brood Swarm, 6 craft: 3D cluster at (+1.5, +0.4, 0), (-1.8, +1.6, +3.9), (-2.2, -1.4, -3.7), (-5.1, -0.8, +4.8), (-5.6, +1.5, -4.4), (-8.2, +0.2, +0.5). Lissajous swimming motion 1.60 units amplitude at 1.30 Hz plus plus or minus 8 degrees pitch undulation.
- Eclipse, Geometric Lattice, 4 craft (fenced): planar diamond at (+4.2, 0, 0), (0, +1.8, +4.5), (0, -1.8, -4.5), (-4.2, 0, 0). Zero weave; quantized attitude steps.

Weave is desynchronized per craft everywhere except Hegemony. The minimum weave amplitude outside Hegemony is 0.40 units (Argon leg's motion floor, section 7).

Formation notes from the other legs that the controller must honour: offsets are per-wing random seeds within the faction's allowed spread for Hullbreakers and Chorus, so no two packs or swarms are identical (Qwen); Chorus offsets drift continuously even in transit (DeepSeek); footprint stays at or under one hex so the formation reads as one unit without blurring into a blob (DeepSeek).

## 6. Movement behaviour

All four legs agree on the headline: launch and the attack run are flown by the meshes. The sprite-only launch streaks (fx_weapons.gd:969 to 983) and the sprite-only strafe (fx_weapons.gd:609 to 640) are retired as the primary read; the strafe's per-weapon payload sprites (tracers, bombs, spore sacs) survive, but they spawn from the moving craft.

### 6.1 On-station patrol (the core anti-static fix)

A wing on station never holds fixed coordinates. It flies a continuous patrol INSIDE its own hex, keyed off the carrier's wing stance (battle.js:622 to 630), so stance becomes visual telemetry:

- Screen stance: the formation centroid orbits the hex centre on a 3.2-unit radius circle at 3.6 units per second (one orbit every 5.6 seconds), banking inward at 18 degrees, engines dim (R55). A screen wing reads as a defensive ring over its hex.
- Strike or hunt stance: the centroid flies a 4.2 by 2.0 unit figure-eight racetrack inside the hex, period 4.8 seconds, aligned toward the nearest enemy ship, holding 3.2 to 4.0 units per second. A strike wing reads as wound up and pointed.

Motion floor: every on-station wing keeps at least 3.0 units per second of patrol velocity (23 px per second at 1080p, 46 at 4K). Below about 1.0 unit per second, drift aliases against the pixel grid and reads as frozen (Argon leg); the floor sits well above that. The Rey leg's wider circuit (a flat oval 8 by 5 units, one lap in about 9 seconds, about 1.6 units per second) is not adopted: it fails this motion floor and drifts outside the hex footprint. Patrol is the wing's idle state, not an embellishment: if a wing is not patrolling, transiting, or attacking, it reads as parked.

Stance nuance (Rey leg, adopted as variation within the hex): a screen wing biases its circuit toward the side of the hex facing the nearest threat; a hunt wing biases its figure-eight toward the hunted ship. The circuit stays inside the hex either way.

### 6.2 Launch

Trigger points: battle start, spare replacement (data.js:136), and scramble Commands (battle.js:1080).

- Craft meshes spawn at the carrier's hangar offset at 0.25 scale and launch in staggered 0.10 second intervals per craft.
- Each craft scales to full over 0.20 seconds, banks about 35 degrees outward, and flies a curved Bezier path into the wing's hex at 2.2 times parent capital ship transit speed.
- Total launch event: 0.95 to 1.4 seconds depending on wing count and distance, ending with an eased braking phase over the final 0.25 seconds as the craft settle into the patrol (R55 eased braking).
- Engine glow ramps from the R55 dim idle to full over the first 0.3 to 0.6 seconds.
- Chorus launch is a budding in fiction and should read that way: organisms swell out from the brood-sac rather than streaking (Rey leg). The stagger and timing numbers are the same; the spawn scale-in does the visual work.

### 6.3 Hex transit

- During the swarm phase (battle.js:1064, 1157) the wing traverses its hex spline at 1.75 times capital ship flight speed, with eased braking over the final 25 percent of the distance (R55).
- Wingmen are independent transforms following formation targets, not rigid offsets: each wingman applies the spline's yaw with a delay of 0.06 seconds times its craft index behind the lead, and banks up to 45 degrees in turns. This whip-turn replaces the rigid speed lag (ship_view.gd:1286 to 1292).
- The whole formation banks as a body; per-faction character lives in the weave and slot tables (section 5), with Hegemony banking in exact unison and Hullbreakers lagging and jittering the most.

### 6.4 Attack run

Total 1.40 seconds, flown by the meshes, in three phases:

- Flak approach, 0.00 to 0.45 s: craft ignite full engine trails, break formation with a 0.07 second stagger, and dive from their hex to the target hull's edge at 2.5 times ship speed, jinking laterally plus or minus 1.2 units through the point-defence flak bursts. The flak gauntlet (battle.js:774) and the run are one staged event: turret fire meets the craft during this phase. This is where a gated threshold loss would pop, if Owner Question 1 adopts thinning.
- Ordnance pass, 0.45 to 0.90 s: role-specific delivery. Fighters skim 2.8 units above the target deck at 50 degrees bank firing tracer bursts. Bombers fly a level run 3.5 units overhead releasing visible bomb salvos. Chorus Bile-Cysts dive to 1.8 units and convulse to eject glowing spore sacs onto the hull. Weapon sprites spawn from the moving craft positions (fx_weapons.gd:609 to 640 payloads, re-anchored).
- Breakaway, 0.90 to 1.40 s: craft execute a 65 degree banking peel-off turn, arc back to their hex, and ease back into the patrol orbit.

DeepSeek's two-pair structure (the wing breaks into two pairs for the pass) is adopted as the default pass geometry where the count allows it; the Rey leg's two-element split around the target hex is the same idea at element scale. Chorus swarms and 4-craft wings split by halves.

Swarm phase pacing across wings is Owner Question 5; the per-run numbers above do not depend on its answer.

### 6.5 Dogfight

When a wing attacks a wing, or opposing wings meet at a shared hex: both wings surge to the shared hex boundary and merge into a 7.0-unit radius 3D furball for 1.25 seconds. Each craft follows an offset figure-eight chase loop at 2.4 times ship speed with 55 to 70 degree roll angles, trading short tracer bursts, before both wings peel back to their home hexes and resume patrol. This is presentation only: the rules still resolve the wing as one unit in the swarm phase, and no per-craft targeting is simulated (all legs agree). Qwen's close-orbit version (half orbit radius, 1.5 times orbit speed, sine weave) is the fallback shape if the furball's transform cost measures high; it is also the first degradation step in section 8.

### 6.6 Scramble Commands

The five wing Commands (Ashgrove, Reyes, Old Mott, Matriarch, Tamsa; data.js:207 to 229) share one rules shape: extra wing out, then all wings strike again at plus 50 percent damage (battle.js:1080). Presentation:

- The extra wing launches on a fast 0.75 second curve (the section 6.2 launch, compressed).
- All active friendly wings pulse their engine flares to 1.6 times brightness and trail width while executing their plus 50 percent attack runs.
- Qwen's proposed camera shake and carrier flash on the Command are NOT adopted (section 9, camera).

### 6.7 Death and replacement

Wings never dock to rearm (data.js:136). When wing HP reaches zero, the surviving craft break outward and detonate in staggered 0.10 second fireballs, or bile-bursts for Chorus, sized under the capital-ship kill flash rules (no explosion bigger than a small capital kill). When a carrier replaces a lost wing from its spare pool, the new wing flies the section 6.2 mesh launch from the carrier: a replacement is a visible launch, never a pop-in token (all legs agree, BFG and Sins 2 lessons).

## 7. Damage read and the count question

### 7.1 Buildable baseline (R80 as ruled)

This is settled spec, buildable now, and matches the owner's actual ruling for squadrons:

- Stage 0 damage surfaces on the craft meshes: scorch and pitting, visible on zoom, carried as a per-instance damage value on the wing's MultiMesh (section 8).
- A smoke ribbon below half total wing HP: a high-contrast dark charcoal ribbon, 0.85 units wide (6.5 px at 1080p, 13.1 px at 4K) and 7.5 units long (58 px at 1080p), trailed by the lead craft, laced with faction-coloured ember sparks, or dark olive spore-ichor mist for Chorus. At board distance the ribbon is the primary mauled-wing tell; on zoom the stage 0 surfaces confirm it.
- Fixed visible craft count. A fresh wing and a mauled wing show the same number of craft; the read is surfaces plus ribbon, with the health bar as the exact read.
- No per-craft damage states beyond the above. No formation thinning, no missing craft, no ghost craft in the baseline.

### 7.2 The gated proposal: count thinning (NOT settled spec)

The Rey leg and the Argon leg both propose linking visible craft count to the wing's HP ratio, with faction-varied full counts:

- 100 to 76 percent HP: full count (4 Crusade, Hegemony, Eclipse; 5 Hullbreakers, Glasswrights; 6 Chorus).
- 75 to 51 percent: full count minus 1; stage 0 scorches appear on survivors.
- 50 to 26 percent: max(2, full count minus 2); the R80 smoke ribbon ignites on the lead and one wingman.
- 25 to 1 percent: 2 craft floor, both trailing smoke ribbons, so a wing always reads as a formation and never as a lone micro-hull.
- Loss transition: when damage crosses a threshold downward during the flak approach or a dogfight, the outermost surviving wingman plays a 0.35 second spiral roll and a miniature pop flash (2.5 units diameter) before its mesh hides.

This is carried as Owner Question 1 and is NOT part of the buildable baseline, for one reason: it extends R80. Ryan ruled stage 0 surfaces plus the smoke ribbon for squadrons; he has not ruled on craft disappearing. The chair does not extend an owner ruling by synthesis.

The objection, stated fairly (DeepSeek and Qwen, against): the rules treat the wing as one HP pool and never lose individual craft (battle.js:1064, 1157); R80 as ruled forbids per-craft damage states beyond surfaces and the ribbon; dropping a craft implies an individual loss the simulation did not happen, risks a false read (a player could mistake a thinned wing for a wing that lost craft to a mechanic that does not exist), and the smoke ribbon plus surfaces already give a ruled damage read. DeepSeek adds formation tightening at low HP as a non-count alternative; Qwen adds a dimmed ghost-craft compromise. Both are recorded in section 11.

The chair pick on Q1 is to adopt thinning, for the record: the owner's complaint is that wings look static and unchanged; a wing at 1 HP showing a full pristine formation is the sharpest version of that complaint, and the comparators that feel alive (Homeworld 2 and 3, Sins 2) all thin visibly. But it is the owner's call, because it is his ruling that changes.

## 8. Frame budget at 20 ships plus wings

Caps, not millisecond promises. No leg measured real frame cost in the Godot build, and this section does not pretend otherwise (section 12).

Worst case (pack, R1): 20 capital ships plus 14 wings. At the section 3 counts, the craft ceiling is 84 meshes (all-Chorus board); a mixed board averages about 70.

Caps:

- Instancing: one MultiMeshInstance3D per wing (all craft of the wing as instances of the faction-role mesh, one material, per-instance custom data carrying engine glow intensity and the stage 0 damage value), plus one batched ribbon mesh per wing for engine trails and one for the smoke ribbon. Ceiling: 14 hull draw calls plus 14 trail ribbons plus up to 14 smoke ribbons = 42 draw calls for all squadrons, against 56 to 84 separate MeshInstance3D nodes today.
- Geometry: LOD0 cap 350 triangles per craft (84 craft = 29,400 triangles board-wide, less than a single capital ship hull); LOD1 cap 120 triangles per craft.
- Animation: zero skeletons, zero physics bodies, zero per-craft raycasts. All craft transforms update in one flat loop (at most 84 transform evaluations per frame board-wide). Chorus body undulation and Glasswright floating vanes run in the vertex shader off TIME and instance ID at zero CPU cost.
- Particles: the mesh-flown launch and attack run eliminate the 6 launch sprites per wing and the sprite strafe streaks. Squadron particle pool cap: 160 active board-wide (tracers, flak puffs, bomb flashes, spore bursts), including scramble peaks at 12 ordnance sprites per attacking wing. Qwen's roughly 500 concurrent sprite ceiling and DeepSeek's 256 sprite pool are NOT adopted: they budget for the sprite traffic this spec removes.

Degradation order (what goes first, in order):

1. Dogfight weave: furball loops degrade to simple head-on passes (DeepSeek), then to Qwen's close-orbit shape.
2. Per-craft trails: per-craft ribbons collapse to one ribbon per wing.
3. Per-craft banking: banking and offset drift freeze; the formation still moves as a group.
4. Distance LOD past 130 units camera distance: LOD1 meshes, stage 0 scorch sampling off (unreadable under 10 px), ribbon segments halved from 12 quads to 6.
5. Low settings: visible craft capped at 4 per wing (56 craft max), patrol math stepped at 30 Hz, trail lengths reduced 40 percent. Note: if Owner Question 1 adopts thinning, the low-settings cap interacts with the count table and Codex should treat the cap as a ceiling on whichever count is lower.
6. Safe mode (the floor): trails merge to one wing-centroid ribbon, the smoke read renders as one flat scrolling quad per mauled wing, and the patrol freezes (wings hold formation offsets at rest and animate only in transit and attack). Safe mode is the ONLY state where a wing may sit still; DeepSeek's safe-mode fallback to today's rigid block plus sprite streaks is not adopted, because it reinstates the exact presentation this spec exists to replace.

Measurement gate (pass criterion, build task 5): the 40 fps floor from the issue 51 damage spec, measured on an RTX 5080 at 4K in a torture scene: 20 damaged capital ships plus 14 Chorus 6-craft wings (84 craft), all below half HP with smoke ribbons active, executing a simultaneous scramble attack run through flak. Profile CPU script time in the ship view and weapons fx, and GPU frame time. The counts and caps above are final only when that scene holds the floor; if it fails, degradation steps engage in the order above before any count is cut globally (the Rey leg's position, adopted: cut craft count last among the visual systems, and never cut the patrol).

## 9. Readability at the battle camera

Camera settled by the chair: no camera moves for attack runs. Qwen raised a soft zoom or cinematic cut as an owner question; the chair closes it instead. The board is turn-based, wings attack in groups during the swarm phase, and a camera nudge per run would fight the board view across many simultaneous attacks. R73 reserves the slow-motion beat for big ship and flagship kills; squadron runs do not take camera time. Qwen's own pick was also no camera change.

What reads at full board view (170 units out):

- Formation shape and motion signature: the 12 by 12 unit formation is about 92 by 92 px at 1080p and 185 by 185 at 4K. Hegemony's rigid wedge, Hullbreakers' loose pack, Glasswrights' weaving diamond, and Chorus's swimming swarm are distinct icons before any hull is resolved.
- Stance posture: circular orbit (screen) versus enemy-pointed figure-eight (strike, hunt) reads carrier stance at a glance.
- Silhouette and colour blocks: craft at 3.0 to 4.3 units are 23 to 33 px long at 1080p (46 to 66 at 4K); broad two-tone blocks of 1.5 units or more (11.5 px at 1080p) read cleanly. Fighter versus bomber reads by size (section 3).
- Engine glow points and contrail ribbons: dim 0.5-unit glow cores at rest (4 px at 1080p, 8 px at 4K, R55), and in motion 0.45-unit wide vertex-faded ribbons 5.0 to 9.0 units long (38 to 69 px at 1080p) carrying speed, heading, and turn arcs. Faction identity at distance is glow colour and behaviour: synced blue pulse, bile pulse, flickering red, pale stored light.
- The smoke ribbon below half HP (section 7.1).

What only reads on zoom (under 80 units out): everything under the 10 px floor at 1080p (about 1.3 units): chalk oath lettering, radiator vanes, weld plates and underslung bombs, chitin rib segments and tendrils, floating silver vanes, stage 0 scorch decals. These are the "more detail and more views" the owner asked for; they reward zoom without carrying the board read.

The anti-static test: at any given second, a wing is patrolling (section 6.1), transiting with per-craft lag and bank (6.3), attacking (6.4), dogfighting (6.5), launching (6.2), or dying (6.7). There is no idle state left in the system outside safe mode.

## 10. Build order (Codex tasks against issue 67)

1. Mesh matrix and lookup. Build the 10 faction-role meshes (section 3 table, section 4 detail, triangle caps in section 8). Change hull_table to the two-key (carrier faction, wing role) lookup with no generic fallback. Flag, do not silently fix: the Crusade sq data gap (data.js:113) goes to Opus as a data note alongside this task.
2. Formation controller and stance patrol. The parameterized controller (section 5 slots and weave), MultiMesh per wing, and the stance-keyed in-hex patrol with the 3.0 units per second motion floor (section 6.1). This task alone removes the frozen diamond.
3. Mesh-flown events. Launch (6.2), transit whip-turn (6.3), attack run (6.4), dogfight furball (6.5), scramble presentation (6.6), death and spare replacement (6.7). Retire the sprite launch streaks and the sprite strafe as primary reads; re-anchor the weapon payload sprites to craft positions.
4. Damage read. R80 stage 0 surfaces and the smoke ribbon (section 7.1): build now. The count-thinning piece (section 7.2) is GATED on Owner Question 1: build it only if the owner adopts thinning, and in the thresholds given there.
5. Budget, LOD, safe mode, measurement. Distance LOD past 130 units, low-settings caps, safe mode floor (section 8), and the torture-scene measurement against the 40 fps floor on the RTX 5080 at 4K. Sign-off requires the measurement, not the caps on paper.

Eclipse modelling is not in any task above: it is fenced behind Owner Question 4's answer plus a data change (a carrier hull or the Drone bay refit) that is outside issue 67.

## 11. Owner questions

Exactly five. Chair pick marked on each.

### Q1. Visible craft count tracking wing HP

- A (CHAIR PICK): Adopt thinning. Faction-varied counts (4 / 4 / 5 / 6 / 5) drop at 75, 50, and 25 percent HP down to a 2-craft floor, losses shown as a spiral and pop during flak or dogfight (section 7.2).
- B: Keep the R80 baseline exactly as ruled: fixed count, damage read from stage 0 surfaces and the smoke ribbon only (section 7.1).
- C: Fixed 4 craft for all factions, thinning at 66 and 33 percent to 3 and 2 craft (Argon leg's option B).

Stakes: A is the strongest answer to "wings look unchanged" and matches how Homeworld and Sins reads work, but it extends your R80 ruling and implies per-craft losses the one-pool rules do not simulate (the DeepSeek and Qwen objection). B builds nothing extra and stays inside what you already ruled.

### Q2. Craft size: role split

- A (CHAIR PICK): Adopt the split: fighters 3.2, bombers 4.2, Hullbreaker 3.5 / 4.3, Chorus 3.0 / 3.5 (section 3).
- B: Keep today's uniform 3.84 units for all craft (DeepSeek and Qwen position, with minor faction exceptions in DeepSeek).
- C: Shrink everything to 2.6 to 3.0 units (Rey leg position: fighter 2.6, bomber 3.0, spore 2.8).

Stakes: A makes fighter and bomber wings distinguishable by size at board distance, which matters because three factions alternate the two roles per launch. C makes craft truer scale against frigates but pushes silhouettes toward the readability floor at 1080p.

### Q3. Mesh matrix coverage: 10 meshes or 8

- A (CHAIR PICK): Build both roles for all five launching factions (10 meshes), keyed by (faction, role), no generic fallback ever.
- B: Build only the primary role each faction launches in standard lists (8 meshes: Crusade, Hegemony, Glasswright both roles; Hullbreaker bomber only; Chorus spore only) and clamp rules overrides such as adaptation wings (battle.js:361) to the faction's primary mesh.

Stakes: A permanently closes the wrong-craft bug class under any future doctrine or adaptation rule. B saves two meshes and accepts that a Chorus fighter-role wing and a Hullbreaker fighter-role wing would draw their faction's primary mesh instead of a role mesh.

### Q4. Eclipse craft: spec now, model later

- A (CHAIR PICK): Keep the full Eclipse spec in this document (section 4.6) and model the two drone meshes only when an Eclipse carrier or the Drone bay refit ships in data.
- B: Leave Eclipse out of the spec entirely and revisit with a balance pass (Qwen position).
- C: Model and wire the two Eclipse meshes in issue 67 now, ready for adaptation wings or future drone bay rules.

Stakes: A keeps the design complete at zero build cost today. B risks the faction's squadron absence becoming an oversight instead of a decision. C spends modelling budget on craft no ship can launch.

### Q5. Swarm phase pacing: staggered or sequential

- A (CHAIR PICK): Staggered overlapping attack runs: 1.40 seconds per wing, wings launch their runs 0.20 seconds apart, so 10 wings resolve in about 3.2 seconds of swarm phase.
- B: Strictly sequential runs: 1.40 seconds each, one wing after another.

Stakes: A keeps late carrier battles brisk and gives a mass-strike spectacle. B is easier to follow wing by wing but stretches a 14-wing swarm phase to nearly 20 seconds of animation.

## 12. Dissents and rejected positions

Recorded so the screening is auditable. The legs are filed in full under legs/.

- Count tracking (the big split): Rey leg and Argon leg for thinning; DeepSeek and Qwen against. Chair: baseline stays at the R80 ruling, thinning goes to the owner as Q1 with the chair pick stated and the objection stated fairly (section 7).
- Size: DeepSeek keeps craft near 3.84 (Hegemony 3.5, Glasswright 3.1, Hullbreaker grown to 4.2, Eclipse 2.8); Qwen keeps the uniform 3.84 for all factions; the Rey leg shrinks everything (2.6 to 3.0). Chair adopts the Argon leg's role split as Q2's pick, moderated to the section 3 numbers.
- On-station geometry: Qwen's carrier orbit (loose orbit at 3 to 5 hex radius around the carrier, 14 second period) is rejected. Wings hold hexes under the leash rules (SQ_LEASH 8, battle.js:1128) and stance is a property of the wing's hex behaviour; a multi-hex carrier orbit would move the wing off its rules position visually. The patrol belongs inside the hex (DeepSeek's hex-centre orbit and the Argon leg's stance-keyed in-hex patterns converge there). Qwen's per-faction on-station variety (locked ring, wide sweep, cloud, figure-eight, racetrack) is absorbed into the weave and patrol parameters rather than separate orbit centres.
- Rey leg patrol circuit (oval 8 by 5 units, about 9 second lap, about 1.6 units per second) rejected on the motion floor and the one-hex footprint (section 6.1). Its stance-bias nuance is adopted.
- Attack run totals: DeepSeek 2.0 seconds and Qwen 3.5 seconds are not adopted; the Argon leg's 1.40 second run is, because swarm phase pacing (Q5) needs runs short enough to overlap. DeepSeek's contribution to the run is the two-pair pass structure and the flak-as-part-of-the-run staging, both adopted.
- Transit speed: DeepSeek's 1.4 times ship spline speed and Qwen's same-duration-as-ships are not adopted; the Argon leg's 1.75 times is, with its per-craft delay (0.06 s times index) matching the Rey leg's lag figure independently.
- Launch duration: Qwen's 2.5 second launch is not adopted; it is too long for spare replacements mid-battle. The adopted launch (0.95 to 1.4 s total) follows the Argon leg's 0.95 s structure with count-dependent stretch.
- Particle ceilings: Qwen's roughly 500 concurrent sprites and DeepSeek's 256 sprite pool are rejected as budgets for traffic this spec deletes (section 8). The 160 active squadron particle cap stands.
- Safe mode: DeepSeek's fallback to today's rigid block and sprite streaks is rejected (section 8). A fallback that restores the complained-about presentation is not a floor, it is a regression.
- Eclipse: Qwen's leave-it-out-entirely pick is recorded as the dissent on Q4. The spec keeps Eclipse written and fenced, following the Job 8 precedent of designing ahead of the data.
- Camera: Qwen raised attack-run camera moves as a question and picked no change; the chair settles it in section 9 rather than spending an owner question. Qwen's scramble camera shake and carrier flash are not adopted for the same reason.
- Argon leg screening notes: its comparator text is heavily self-marked as impression and is weighted accordingly in section 2. Its claim that rules overrides can spawn generic fighter hulls for Chorus carriers is treated as a hypothesis (the pack grounds Chorus wings resolving to the spore kind in data); the two-key lookup fix is adopted on its own merits regardless. Its summary table lists Chorus at 5 craft per wing while its sections 2 and 3 use 6; the chair adopts 6, consistent with its own text and with the swarm read.
- Hegemony naming: Qwen's Registry Drone and DeepSeek's Registry Lance are not used; the Argon Grid-7 / Grid-12 names carry, so each faction has one name per role across the matrix.
- Formation tightening at low HP (DeepSeek) and ghost craft (Qwen option c on its Q1): not adopted in the baseline or in Q1's options; if the owner rejects thinning at Q1 and still wants a secondary damage tell beyond the ribbon, formation tightening is the first fallback to raise with Opus.

## 13. Not checked

- No leg opened the Godot project or ran the build. All code citations are from the pack's grounding at main 7677728; render-side line numbers (ship_view.gd, hull_table.gd, fx_weapons.gd) were not re-verified against a live checkout during synthesis.
- No frame cost was measured. Section 8 is caps and a measurement gate, not a performance result; the torture scene has not been run.
- Comparator claims rest on the legs' sourcing: manual and developer material as cited per game in section 2, with impression-grade items marked. No primary source was re-fetched during synthesis.
- The Crusade sq data gap (data.js:113) is verified in the pack as a missing key; what the code's default fall-through resolves to in every spawn path (including adaptation wings, battle.js:361) was not traced.
- Triangle counts for existing capital ship hulls (used in section 8 only as a scale comparison, "less than a single capital ship hull", from the Argon leg) were not verified against the ship meshes.
- The interaction between the low-settings 4-craft cap and an adopted Q1 thinning table is flagged in section 8 but not specified further; it needs one line from Codex at build time.
- Eclipse drone fiction (repair drones, bible line 469; Drone bay refit, line 512) is cited from the pack's bible extracts; the full bible passages were not re-read during synthesis.
