# Qwen blind leg: battlefield and terrain audit (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (Qwen3.8-Max, both model gates passed; Access Verification slider cleared in one round). Em dashes and en dashes normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://chat.qwen.ai/c/bc405242-44be-4365-ab06-09ff83b9bd5b. Evidence pack: the Oct 28 battle program battlefield pack (code slices pinned to main 264f441d). Method notes and screening live outside this file.

# BATTLEFIELD AND TERRAIN AUDIT - VOIDSWORN

## 1. Proof of Reading

Sections read in full:

- EVIDENCE PACK title line ("battlefield and terrain audit, code slices from the shipped browser build, main 264f441d")
- THE COMMISSIONER'S QUESTION
- CHAIR CENSUS (all seven bullet points)
- WHAT TO JUDGE (all five numbered questions)
- Code slice 1: battle.js 1-70 - board constants (BW=30, BH=22), TERRAIN_INFO, SHAPES, REGIONS, ROCK_KINDS, REGION_BIOME, ENCOUNTERS, ENC_ARENA, ENC_POOL, bossEncounter, rollEncounter
- Code slice 2: battle.js 160-330 - genTerrain, deploy, ARENAS, approachDeploy, gravity-well system (wellTick, aiWellScore), clearSpawns, startBattle

Overall verdict: FIELDS VARY. The shape axis rewrites board topology, the arena axis rewrites approach geometry, and the map axis rewrites terrain composition; together they produce battlefields that demand different routing, firing, and positioning. The variation is real, though unevenly distributed across axes, and several downstream systems (spawn-clearing, boss terrain stripping, fallback deployment) erode the variety the generator builds.

## 2. Findings

### Finding 1 - [FIX] The canvas is oversized for the fleet count and battle length, diluting the "cinematic fleet battle" feel.

INFERRED. The canvas is "30 by 22 hex grid" (READ). The strip arena yields roughly 28 x 16 ~ 448 playable hexes; the round arena ~ 380; the square ~ 484. The commissioner states fleets of "up to about 20 ships total" and battles of "4 to 8 rounds" (READ, chair census). At 20 ships on 448 hexes, occupancy is roughly one ship per 22 hexes. A fleet battle should feel dense and contested; at this density the field reads as a sparse skirmish with large dead zones in the middle. Ships moving 3-4 hexes per turn need 7-9 turns to cross the strip's width, which already exceeds the upper bound of measured battle length. The generator mitigates this with the compact shape ("small fleets fight in close quarters," READ) and with terrain filling space, but the base canvas still sets a scale that works against the stated feel. The board helps when terrain is dense (belt, graveyard, dense shape) and hurts when it is open (open shape on a storm or planet map with few blocking features).

### Finding 2 - [FIX] clearSpawns carves corridors through terrain-heavy shapes, undoing their design intent near the deployment zones.

READ / INFERRED. The code states: "no fleet starts boxed in: clear rocks and wrecks around each ship and along a lane toward the enemy" (READ). Player ships clear a radius-2 bubble; a line is then traced toward the enemy centroid and rocks are removed along it for up to 6 hexes at radius 1 (READ). On shapes whose identity is blocking terrain near the centre - lanes ("force(offToAx(c,midR),'rock')" along two rock walls with two gaps), dense (four rock blobs plus three debris blobs), archipelago (up to six rock islands with neighbours), corridor (top and bottom rows cut) - the spawn-clearing can remove the very features that define the shape's tactical problem. INFERRED: on a lanes board, clearing a corridor from each deployment zone toward the enemy centre is likely to breach one or both rock walls, collapsing the two-gap routing decision into a more open engagement. The function is a necessary safety valve, but its radius is not shape-aware.

### Finding 3 - [FIX] The deployment fallback rule ("a board shape left the usual zone too small") overrides shape-specific deployment with a generic half-board zone.

READ. The code: "if a board shape left the usual zone too small," the zone falls back to "half-board zones" split at BW/2 (READ). The line-deployment zone is columns L0+4 to L0+6, rows within +/-5 of mid - roughly 3 x 11 = 33 hexes. On a corridor (rows 3 to BH-4 only, so 16 rows), compact (columns 4+CX to BW-5-CX, rows 2 to BH-3), or rift (a jagged chasm removes two columns of hexes through the middle), the zone can easily drop below the ship count + 1 threshold. INFERRED: when the fallback triggers, the player deploys across an entire half of the board, and the shape's spatial constraint - the narrow corridor, the tight close-quarters box, the rift's chokepoint - no longer governs the opening. The shape still affects mid-battle routing, but the first-turn positioning problem, which is where deployment mode should matter most, becomes generic.

### Finding 4 - [FIX] Boss fights strip nearly half the blocking terrain, making the climactic battle the least topologically interesting.

READ. "if(cfg.kind==='boss') for(const k of Object.keys(T)) if(T[k]==='rock'&&rnd()<.45) delete T[k]; // flagship duels need firing lanes, not a maze" (READ). The comment reveals the intent: the designer wants the boss fight to be about the flagship, not about navigating rocks. But removing 45 % of rocks on a dense, archipelago, or lanes board fundamentally changes the shape's character. INFERRED: a dense boss fight with half its rocks gone plays closer to open with scattered debris. The boss encounter pool is already narrow - bossEncounter picks from ['rout','rout','ambush','flagship'] and shapes from ['ring','open','hourglass'] (READ) - so the boss layer already has less shape variety. Stripping terrain on top of that makes the climax the most homogeneous battle type in the game, which is the opposite of what a cinematic peak should deliver.

### Finding 5 - [FIX] Non-strip arenas silently replace axis-dependent shapes, shrinking the effective shape pool.

READ. AXIS_SHAPES=['corridor','lanes','hourglass','rift','compact']. If the arena is square or round and the rolled shape is in AXIS_SHAPES, the code replaces it: "shape=pick(['open','dense','deadstar','shoals','archipelago','colossus','ring'])" (READ). Additionally, only rout, hold, and flagship encounters are eligible for non-strip arenas (axisFree check, READ), and boss fights and ambush deployments are excluded. INFERRED: for ambush, defend, hunt, intercept, and break encounters, the arena is always strip, so five of the twelve shapes are never filtered. But for rout, hold, and flagship - the three encounters that can use square and round arenas - five shapes (corridor, lanes, hourglass, rift, compact) are silently replaced if the arena rolls non-strip. The ENC_ARENA weights give rout a 65 % chance of a non-strip arena, hold a 60 % chance, and flagship a 55 % chance. So for these three encounters, roughly half the shape pool is being rerolled behind the scenes. The player never sees the filter; they just notice that certain shapes never appear with certain encounters.

### Finding 6 - [NOTE] Biome is purely cosmetic and does not interact with any mechanical system.

READ. ROCK_KINDS defines five rock types (stone, ice, iron, carbon, crystal) with colour values, specular values, and emissive values (READ). REGION_BIOME maps each region to a subset of rock kinds, planet visual indices, and station visual variants (READ). rollBiome picks one rock kind, one planet variant, one station variant (READ). None of these values are read by any movement, combat, or terrain-effect system in the provided code. INFERRED: an ice-asteroid belt and a carbon-asteroid belt are tactically identical; the difference is colour and specular highlight. Biome is the axis doing the least work: it recolors the same mechanical field. This is not a defect - cosmetic variety is legitimate - but the commissioner's question asks which axes are "cosmetic recolors of the same field," and biome is the clear answer.

### Finding 7 - [NOTE] Soft-cover terrain (nebula +15, debris +10) is marginal at fleet scale and may not drive routing decisions.

READ / INFERRED. Nebula makes ships "15 points harder to hit"; debris makes them "10 points harder to hit" (READ). The code does not provide the base to-hit formula or typical weapon accuracy values in this pack, so I cannot compute the percentage reduction. INFERRED: if base to-hit is in the 60-80 range (typical for hex tactics), a 15-point reduction is meaningful (roughly 20-25 % relative) but a 10-point reduction is marginal (roughly 12-16 %). Neither modifier is large enough to justify routing a fleet through a nebula cloud instead of around it, unless the alternative is significantly longer. Debris at +10 is especially weak: it is a minor speed bump, not a decision. Compare to ion storm, which deals 10 shield damage per facing per turn (up to 60 shield per turn for a fully surrounded ship) and worsens aim by 10 - storm is a genuine hazard zone that demands routing around it. The soft-cover types are present on the board but are unlikely to be the reason a player chooses one route over another.

### Finding 8 - [NOTE] The deadstar gravity well is the most mechanically rich terrain feature and the only one with three distinct interaction zones.

READ. The well has four radii: WELL_RIM=3 (tidal damage: 7 HP per turn), WELL_PULL=5 (gravitational drag: pulls ship one hex toward the sun), WELL_ASSIST=6 (slingshot: +1 movement point) (READ). The wellTick function applies all three effects in sequence, and aiWellScore penalises AI positioning near the rim (-45) and pull zone (-6) (READ). INFERRED: this is the only terrain that creates a genuine risk-reward gradient. A player can use the assist ring for extra movement, must avoid the pull ring or exploit it for repositioning, and must never end a turn on the rim. The deadstar shape also cuts a hole in the board centre and surrounds it with a debris ring, so the well interacts with the shape's topology. This is the terrain system working at its best.

### Finding 9 - [NOTE] The sector-condition terrain injection adds a global modifier but cannot interact with shape features.

READ. "the sector condition injects its own terrain blobs into every battlefield in the sector (never in the deployment columns)" (READ, chair census). The code places 3-4 blobs of the condition's terrain type in columns 8 to BW-9 (READ). INFERRED: these blobs are placed by blob(), which does a random walk from a random start point. They do not check for or interact with shape features (rift chasms, deadstar holes, archipelago islands). A storm-condition blob could land partially inside a rift's cut region (the hexes are simply not placed because put checks onBoard), or overlap with a deadstar's debris ring. The effect is additive but not compositional: the condition adds noise on top of the shape rather than interacting with it. This is a missed opportunity but not a bug.

### Finding 10 - [NOTE] The terrain legend exists in code but the pack does not show how or when it is surfaced to the player.

READ. TERRAIN_INFO contains display names, colours, and effect descriptions for all seven terrain types (READ). The chair census notes "terrain legend exists in code" (READ). INFERRED: the legend data is there, but the pack contains no UI code showing when the legend is displayed, whether it is always visible, whether it appears during the opening zoom, or whether the player must open a menu to read it. For readability (Question 5), the legend's availability during the opening camera move is critical, and this pack cannot answer that.

## 3. Explicit Checks

### VARIETY

Axes that produce real tactical differences:

| Axis | What changes mechanically | Verdict |
|---|---|---|
| Shape (12) | Board topology: holes, walls, chasms, islands, central obstacles. Corridor restricts vertical movement; rift splits the field with bridges; lanes forces two-gap routing; archipelago creates island-hopping; colossus splits the field around a central wreck; deadstar creates a gravity well and central void; hourglass pinches the middle. | Real. This is the axis doing the most work. |
| Arena (3) | Approach geometry. Strip is left-to-right; square and round allow diagonal, cross, and pincer approaches via approachDeploy. Non-strip arenas rotate the deployment axis by an arbitrary angle th. | Real. Changes the first-turn problem fundamentally. |
| Map kind (5) | Terrain composition. Belt: a diagonal asteroid band with gaps. Station: a central station with debris ring. Planet: a large circle blocking one edge. Storm: four ion-storm blobs. Graveyard: scattered hulks with debris. | Real. Each map creates a different terrain density and distribution. |
| Encounter type (8) | Objective changes what matters on the field. Defend centres on a station; intercept targets moving transports; break requires reaching the far edge; hold requires controlling a relay point. | Real. The same board plays differently under different objectives. |
| Deployment mode (3) | Starting positions and facing. | Real but undermined (see Finding 3). |
| Sector condition | Adds 3-4 extra terrain blobs of a fixed type. | Mild. Additive, not compositional. |
| Biome (5 rock kinds x planet/station variants) | Colour, specular, emissive values only. | Cosmetic. No mechanical effect. |

Most work: Shape. It rewrites the board's topology and creates the routing, firing-lane, and area-control problems that define a battle.

Least work: Biome. It is a pure recolor. An ice-asteroid dense field and a crystal-asteroid dense field are the same battle with different tints.

Combinatorial estimate (INFERRED): 12 shapes x 3 arenas x 5 maps x 8 encounters x 3 deployment modes = 4,320 nominal combinations before filtering. After filtering (deadstar map restrictions, axis-shape replacement on non-strip arenas, encounter-specific shape lists, boss shape restrictions), the effective pool is smaller but still in the high hundreds. Two randomly drawn battlefields will almost certainly differ in shape, map, and encounter. The variety is real.

### TERRAIN AS TACTICS

Taken type by type:

1. Asteroids (rock): Block movement and line of fire (READ). On a 30x22 board with ~20 ships, a rock cluster of 3-5 hexes forces a detour of 2-4 hexes, which is one full turn of movement. With multiple clusters (belt band, dense blobs, archipelago islands, lanes walls), rocks create genuine routing decisions. Line-of-fire blocking is real at this fleet size: a ship behind a rock cannot be shot, and a ship in front of one cannot shoot through it. Creates decisions.
2. Wrecks (hulk): Mechanically identical to rocks (READ). Differ only in placement logic (graveyard maps scatter them as individual hexes with adjacent debris, rather than as blobs). Creates decisions, same as rocks.
3. Stations: Mechanically identical to rocks (READ). In defend encounters, the station is the objective and has its own batteries. In other encounters, it is just another blocking hex. Creates decisions in defend; otherwise same as rocks.
4. Planets: Mechanically identical to rocks (READ). Placed as a large circle at one board edge (radius 8 hexes, READ). The planet's size makes it a major terrain feature: it blocks a large swath of one edge, forcing the battle toward the centre and the opposite edge. The code also clears rocks near the planet's rim so asteroids don't visually overlap it (READ). Creates decisions through sheer size.
5. Nebula: Ships inside are "15 points harder to hit" (READ). No movement or firing penalty. INFERRED: a competent player will park a damaged ship in a nebula to reduce incoming fire, but will not route a fleet through a nebula cloud to gain 15 points of evasion. The modifier is a small tactical bonus, not a routing driver. Marginal.
6. Debris: Ships inside are "10 points harder to hit" (READ). INFERRED: at 10 points, this is unlikely to influence any decision a competent player makes. Debris serves as a visual indicator of a contested or damaged area and as a minor stat modifier. It is the weakest terrain type. Ignorable at fleet scale.
7. Ion storm: Ships inside "lose 10 shield on every facing each turn and aim 10 points worse" (READ). A ship with all six facings exposed loses 60 shield per turn. Even a ship with three facings in the storm loses 30. This is a severe, recurring penalty that compounds over the 4-8 round battle length. Storms also worsen aim, so a ship in a storm is both losing defence and losing offence. Creates strong decisions. Storms are the only terrain that punishes occupation rather than just blocking movement. A player must route around a storm or accept significant attrition.

Summary: Blocking terrain (rock, hulk, station, planet) is the real tactical system. It creates routes, firing lanes, and shelter. Ion storm is the strongest soft terrain and creates genuine avoidance decisions. Nebula is a minor bonus. Debris is noise. At fleet scale (~20 ships), blocking terrain matters because ships must physically route around it; soft cover matters less because the modifiers are small relative to the cost of a detour.

Line-of-fire blocking: With ~20 ships and hex-based firing arcs, a single blocking hex can shield one or two ships. A cluster of 3-5 hexes can shield a small group. On boards with multiple clusters (belt, dense, archipelago, lanes), line-of-fire blocking is a real and recurring consideration. On open boards with sparse debris, it is negligible. The system works when the board has enough blocking terrain; it does not work on open void.

### FIT

Board size vs. fleet size: 448 hexes (strip) for 20 ships is roughly 22 hexes per ship. INFERRED: in a hex tactics game, a ship occupies 1 hex and needs 1-2 hexes of clearance for manoeuvring. Twenty ships need roughly 60-80 hexes of "active space." The remaining 370+ hexes are terrain, empty space, and buffer. This means the field is under-occupied. Battles will have a long approach phase (turns 1-2), a combat phase (turns 3-6), and potentially unresolved positioning at the end. For 4-round battles (the measured low end), the board is too large: ships may not close to effective range before the battle ends. The compact shape exists to address this for small fleets (READ: "small fleets fight in close quarters"), but it triggers only when B0small(cfg) is true (fleet has <= 2 surviving ships) and only for rout, hunt, and ambush encounters. A 10-ship fleet on an open void still gets the full 448-hex strip.

Where the board helps: Terrain-heavy maps (belt, graveyard) and shapes (dense, archipelago, lanes) fill the space with features, reducing the effective open area and creating structure. The deadstar's gravity well and the planet's large circle create natural focal points that draw the battle inward.

Where the board hurts: Open shape on a storm or planet map with sparse blocking terrain. The field is mostly empty, ships spread out, and the battle becomes a long-range exchange with little routing. The arena cuts (strip margins of 3 top/bottom, 1 left/right) are shallow and do not significantly reduce the play area.

Arena fit: The round arena (R=11, ~ 380 hexes) is the best fit for 20-ship battles because it reduces the maximum distance between any two points and forces a more compact engagement. The square arena (~ 484 hexes) is the largest and the least fitting. INFERRED: the ENC_ARENA weights favour round and square over strip for hold (60 % round) and flagship (35 % round), which is a good instinct.

### DEPLOYMENT

Line: Player deploys in columns L0+4 to L0+6, rows +/-5 of mid, facing right (facing 0). Enemy deploys in columns R0-7 to R0-5, rows +/-5 of mid, facing left (facing 3). This is a symmetric, head-on opening. The problem is straightforward: advance, find firing lanes, engage. Functional but undramatic.

Flank: Player deploys in columns L0+3 to L0+9, bottom 7 rows, facing 5 (lower-right). Enemy deploys in columns R0-10 to R0-4, top 7 rows, facing 2 (upper-left). The fleets start at diagonal corners. Creates a different problem: the approach is oblique, and ships must angle their movement to close distance. Facing is pre-set, so the first turn is about repositioning, not firing.

Ambush: Player deploys in a small central-left zone (columns L0+5+CX to L0+9+CX, rows +/-3 of mid), facing right. Enemy deploys in two zones: top edge (rows <= T0+2) and bottom edge (rows >= T1-3), spanning columns R0-14-CX to R0-6. Creates a pincer problem: the player is centred and must deal with threats from two directions. This is the most tactically distinct deployment.

Are they meaningfully different? Yes, in design intent. Line is symmetric, flank is oblique, ambush is a pincer. INFERRED: the difference is real but modest. All three place the player on the left side of the board (or centre-left for ambush). The enemy is always on the right. The approachDeploy function for non-strip arenas introduces more radical variation (arbitrary angles, pincer and cross approaches), but this only applies to rout, hold, and flagship encounters on square or round arenas.

Fallback zone rule: "if a board shape left the usual zone too small," the zone becomes the entire half of the board (READ). INFERRED: this is a necessary safety net, but it undermines shapes that deliberately constrain deployment space. On a corridor (only 16 rows of the 22 are playable), the line-deployment zone of 3 columns x 11 rows = 33 hexes might be reduced to 3 x 8 = 24 hexes by the corridor's top and bottom cuts. If the fleet has 12+ ships, the fallback triggers and the player deploys across 200+ hexes instead of 24. The corridor's spatial constraint is negated at the moment it should matter most.

### READABILITY

The ruled opening camera: "battles open with the camera zoomed out showing the whole battlefield and the enemy fleet, then zoom in on the player's fleet" (READ, chair census).

What the field must communicate in the zoom window (INFERRED):

1. Board shape and topology (where are the holes, walls, chasms, islands?)
2. Terrain types and their locations (which hexes are blocking, which are soft cover, which are hazardous?)
3. Set pieces (giant asteroid, wreck, moon, comet, deadstar, planet)
4. Deployment zones (where can I place my ships?)
5. Objective markers (relay point, transport path, station, escape hexes)
6. Enemy fleet composition and position

Does the terrain system support this? Partially. The terrain legend exists in code (TERRAIN_INFO with names, colours, and effect descriptions, READ). The seven terrain types have distinct colours (READ: rock #bda088, station #9a948a, nebula #b07cff, debris #d4bf86, storm #ffe866). INFERRED: the colour palette is reasonably distinct, though rock and station share the same colour (#bda088 and #9a948a are close), and planet also uses #9a948a. A player zooming out over a 30x22 hex field with up to seven terrain types, set pieces, and 20 ships must parse a great deal of information in the zoom duration. The pack does not specify the zoom duration, so I cannot judge whether the time is sufficient. INFERRED: at typical zoom durations of 2-4 seconds, reading a complex field with a legend is tight. The player will likely get a gestalt impression ("lots of rocks in the middle," "storm on the left") rather than a precise tactical read.

The biome adds visual variety but may hurt readability (INFERRED): carbon-black asteroids (col [0.36, 0.34, 0.33]) against a dark space background will be harder to see than stone asteroids (col [1, 1, 1]). Crystal shards have emissive glow. These visual differences do not affect mechanics but do affect how quickly the player can identify blocking terrain during the zoom.

## 4. Not Checked

This pack does not let me judge:

1. Base to-hit and damage formulas. Without the combat resolution code, I cannot compute whether nebula (+15) and debris (+10) are meaningful percentage modifiers. My assessment that they are marginal is INFERRED from typical hex-tactics ranges, not from the code.
2. Ship movement ranges. The pack references u.mp and gravity-assist (+1 mp), but does not provide base movement values. My crossing-time estimates (7-9 turns to cross the strip) are INFERRED.
3. Camera zoom duration and implementation. The ruling says the camera zooms out then in, but the pack contains no camera code. I cannot judge whether the zoom window is long enough to read the field.
4. The UI rendering of the terrain legend. TERRAIN_INFO is defined, but the pack does not show when or how the legend is displayed to the player.
5. The Godot port. The pack states "the Godot port mirrors this design" but provides no Godot code. I have judged the browser build only.
6. The sector-condition system in full. The pack shows the condition's terrain injection but not the condition generation, frequency, or types beyond the terr field.
7. Player fleet sizes in practice. The commissioner says "up to about 20 ships total," but the pack does not show the fleet-building or roster-selection code. The B0small check (<= 2 surviving ships) suggests small fleets are possible but does not show the typical range.
8. The terrainConnected function. The generation loop retries up to 6 times if the terrain is not connected, but the connectivity check itself is not in the pack. I cannot judge what "connected" means or how often the fallback to open shape triggers.

## 5. Questions for the Designer

1. **What is the base to-hit value, and is a 10-point debris modifier intended to be a meaningful decision or a rounding error?** If debris is meant to be ignorable, it could be removed from the tactical layer and kept as a visual effect; if it is meant to matter, the number needs to be at least doubled. The stakes: a terrain type that does not influence decisions is dead weight in the legend and a source of player confusion.
2. **Should clearSpawns be shape-aware, preserving the defining features of lanes, corridors, and archipelagos near deployment zones?** The current implementation clears a corridor from each ship toward the enemy centroid, which can breach the rock walls and island chains that give those shapes their identity. The stakes: if the player's first turn always starts in cleared space, the shape's opening tactical problem is solved before the player makes a decision.
3. **Is the 30x22 canvas a legacy constraint or a deliberate scale choice?** The v47 comment calls it "a bigger canvas," implying it grew from a smaller size. If the canvas were 24x18 or 22x16, the same shapes and terrain would produce denser, more cinematic engagements for 10-20 ship fleets without any other changes. The stakes: board size is the single most expensive lever to change after content is built, and getting it wrong locks in a sparse feel for every encounter.
