# Argon blind leg: battlefield and terrain audit (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (Gemini Argon High; chat https://gemini.google.com/app/33fa9117858113c2). Em dashes and en dashes normalized to hyphens per house rule; inline citation chips omitted as UI markers. Evidence pack: the Oct 28 battle program battlefield pack (code slices pinned to main 264f441d). Method notes and screening live outside this file.

1. Proof of Reading

Sections read:

EVIDENCE PACK title line (EVIDENCE PACK: battlefield and terrain audit (code slices from the shipped browser build, main 264f441d; the Godot port mirrors this design)).

THE COMMISSIONER'S QUESTION.

CHAIR CENSUS (verified from the code in this pack).

WHAT TO JUDGE.

Code slice 1: === battle.js 1-70: board, terrain table, regions, biomes, encounters, arenas === (battle.js header).

Code slice 2: === battle.js 160-330: terrain and arena generation, deployment === (terrain/arena generation and deployment).

Overall Verdict: FIELDS VARY ON PAPER - Although the generator combines 12 shapes, 5 map kinds, 5 biomes, 3 arenas, and 3 deployment modes, post-generation spawn bulldozing (clearSpawns), boss rock thinning, strict encounter-to-arena gating, and redundant terrain effects collapse most fights back onto open, center-cleared strips.

2. Findings

[BLOCKER] clearSpawns() bulldozes sightlines across the center, erasing lanes, ring, belt, and graveyard obstacles.

READ: clearSpawns() deletes 'rock' and 'hulk' within radius 2 of player ships (1 for enemies) and along hexLine(u,tgt) up to L = 6 hexes toward the enemy centroid ("clear rocks and wrecks around each ship and along a lane toward the enemy").

READ: For the first 3 steps along each player ship's line toward tgt, near(line[i], 1) clears a 3-hex-wide path; lanes places its 'rock' barrier along midR (r = 11) from c = 7 to c = 22 with gaps g1 (c = 10..12) and g2 (c = 16..18).

INFERRED: In standard strip line deployment (L0 = 1, R0 = 29), player ships at c = 5..7 clear rocks out to c = 13 while enemy ships at c = 22..24 clear down to c = 18. Along midR = 11, player clearance (c = 7..12), g1 (10..12), g2 (16..18), and enemy clearance (c = 18..22) leave at most 3 hexes (c = 13..15) of the lanes barrier intact. In ambush (c = 8..12) or approachDeploy() (R = ext * .68 ~ 7.5 hexes from center), 6-hex clearance corridors punch straight through board center, gutting ring, dense, archipelago, and belt.

[BLOCKER] lanes builds its rock barrier parallel to the fleet advance axis instead of across it.

READ: lanes is listed in AXIS_SHAPES (restricting it to strip, as "only the strip has a fixed left-to-right axis") and places rocks at offToAx(c,midR) and offToAx(c,midR-1) across for(let c=7;c<=BW-8;c++).

INFERRED: On a strip arena, fleets deploy on the left (c = 5..7) and right (c = 22..24) and advance horizontally (increasing/decreasing c). Placing a wall along constant row midR = 11 runs parallel to the line of advance rather than dividing the fleets, and the gaps g1/g2 allow vertical movement across midR rather than creating left-to-right attack lanes (unlike rift, which cuts vertically along r at mid - 1).

[BLOCKER] edgeHex() hardcodes left/right reinforcement edges, spawning units in the enemy's rear on rotated arenas and too far back on strip.

READ: BEVENTS promises reinforcements "on their side of the field" / "on your side of the field" at round r:ri(3,4), and edgeHex(side) hardcodes c=side==='player'?bb.c0+1:bb.c1-1 with u.facing=side==='player'?0:3.

READ: approachDeploy() places the player at pt(th+Math.PI) and the enemy around pt(th), where th is rnd()*Math.PI*2 on round arenas and flips sign via (rnd()<.5?1:-1) on square arenas.

INFERRED: Whenever Math.cos(th) < 0 (50% of round and square fights), the player starts on the right (c1) and the enemy on the left (c0), so edgeHex() drops round 3-4 reinforcements directly behind the opposing fleet facing into its rear. On strip, spawning at c = 2 or c = 27 on round 3 or 4 puts a single cheapHull 13-15 hexes from board center in a battle that lasts only "4 to 8 rounds" (assuming standard capital ship speeds of 2-4 hexes per round, INFERRED).

[FIX] deploy()'s single-centroid scorer collapses two-sided ambush spawns onto one edge, and the half-board fallback erases deployment modes.

READ: ambush states "Two enemy groups close in from both sides" and defines one disconnected enemy zone: h.c>=R0-14-CX&&h.c<=R0-6&&(h.r<=T0+2||h.r>=T1-3).

READ: deploy() computes a single average centre across cand and scores hexes via sc=Math.min(dmin,2)*100-hdist(h,centre)*4+rnd(), falling back to h.c<BW/2-1 h.c or>=BW/2+1 when cand.length<caps.length+1.

INFERRED: Unlike approachDeploy()'s pincer (which splits Ec by i%2 into two separate deploy() calls), deploy() pools top (r <= 5) and bottom (r >= 16) hexes. Whenever asymmetric edge noise (nz(c,0) vs nz(c,2)) or terrain leaves more free hexes on one edge, centre.r shifts toward that edge, giving every hex on that side a smaller hdist(h,centre) so the entire enemy fleet spawns on one side as long as dmin >= 2 holds. When narrow shapes (corridor, hourglass, compact) shrink cand below caps.length+1, the fallback dumps ships around the centroid of the entire half-board, erasing flank and ambush.

[FIX] flank deployment shifts both fleets to opposite corners facing head-on, and approachDeploy() overwrites deployMode.

READ: B.deployMode is a single battle-wide string; when mode==='flank', player uses h.c>=L0+3&&h.c<=L0+9&&h.r>=T1-7 (facing=5) and enemy uses h.c>=R0-10&&h.c<=R0-4&&h.r<=T0+6 (facing=2). In deploy(), if(zoneFn) zone=zoneFn;.

INFERRED: Because both sides enter flank simultaneously, player shifts to bottom-left facing up-right (5) and enemy shifts to top-right facing down-left (2). Facings 5 and 2 are 180 degrees opposite across a ~17-hex diagonal; neither fleet is flanked, making flank geometrically a line deployment rotated 60 degrees. Furthermore, whenever approachDeploy() runs (square and round arenas), passing zoneAt(...) as zoneFn completely overwrites B.deployMode.

[FIX] TERRAIN_INFO and terrainPresent() omit deadstar gravity wells, SOLID set pieces, and rift chasms from the legend while duplicating terrain tints.

READ: terrainPresent() checks only Object.values(B.terrain||{}) against TERRAIN_INFO ("tints, tooltips and the legend all read from it"), where rock/hulk both use col:'#bda088' and station/planet both use col:'#9a948a'.

READ: deadstar enforces WELL_RIM=3 (-7 HP), WELL_PULL=5 (1-hex drag), and WELL_ASSIST=6 (+1 MP) via B.well, while its core, rift chasms, and SOLID obstacles (asteroid, station, moon, hulk, comet) are stored in CUT/SOLID/TERRAIN_META, not B.terrain.

INFERRED: A player relying on the terrain legend and board tints cannot see the Hollow Sun's three hazard radii (d <= 3, 5, 6), SOLID blockers, or rift chasms in terrainPresent(), and cannot visually separate rock from hulk or station from planet by color tint during the opening camera zoom.

[FIX] Boss rock thinning (45% deletion) Swiss-cheeses ring, one of only three boss shapes.

READ: bossEncounter() restricts boss shapes to ['ring','open','hourglass'], and startBattle runs if(cfg.kind==='boss') for(const k of Object.keys(T)) if(T[k]==='rock'&&rnd()<.45) delete T[k]; ("flagship duels need firing lanes, not a maze").

READ: ring builds its central obstacle out of 'rock' in T (if(d<=1||(d===2&&rnd()<.55)) force(h,'rock')) rather than SOLID.

INFERRED: Deleting 45% of 'rock' hexes in boss fights destroys nearly half of ring's central 7-to-13-hex plug, punching random line-of-fire and movement holes straight through the middle of the ring.

[FIX] rift rolls bridge rows across the full 22-row canvas before strip margins (mT:3, mB:3) and ragged edges cut the top and bottom 4-5 rows.

READ: rift is in AXIS_SHAPES (forcing strip with mT:3, mB:3 and eT = 1..2 ragged rows) but rolls n = 2 or 3 bridge centers using const r=ri(2,BH-3); (r in 2..19).

INFERRED: Because strip cuts r < 3 and r >= 19 plus up to 2 ragged rows (r = 3, 4 and r = 17, 18), any bridge rolled at r = 2..4 or r = 17..19 has its 3-row span (Math.abs(x-r)<=1) partially or wholly erased by the map border, leaving fleets with a single far-edge crossing or forcing terrainConnected(T) retries.

[FIX] planet on strip arenas is mostly clipped off-board by arena margins, and station can overwrite rift bridges or merge into ring.

READ: planet places its center at top?-5:BH+4 (-5 or 26) with R=8, and station picks okSite by checking onBoard and !(VOID.holes||[]).some(...) before ring and lanes apply force(h,'rock').

INFERRED: From r = -5 or r = 26, a radius-8 circle only reaches r ~ 3 or r ~ 18 - rows already cut by strip (mT:3, mB:3) and ragged edges (eT = 1..2) - so planet on strip reduces to just 3 small rock blobs (ri(2,4)) and 1 nebula blob (ri(4,7)). Meanwhile, because VOID.holes excludes rift and ring, station can place a 7-hex 'station' obstacle right on top of a 3-row rift bridge near mid (blocking the crossing) or at mid inside ring.

[NOTE] compact is unreachable for any fleet above 2 ships, and 'archipelago' is double-weighted in rout.shapes.

READ: 'compact' appears in zero ENCOUNTERS[enc].shapes lists and only triggers via if(shape==='open'&&B0small(cfg)&&['rout','hunt','ambush'].includes(enc)) shape='compact';, where B0small checks RUN.fleet.filter(x=>x.hp>0).length<=2. ENCOUNTERS.rout.shapes lists 'archipelago' twice ("...'hourglass','archipelago','archipelago','colossus']").

INFERRED: Once a player owns 3 or more surviving ships, compact is dead code for the rest of the run, reducing the active shape pool from 12 to 11.

3. Explicit Checks

1. VARIETY

Axes that produce real differences in how a battle is flown:

Encounter objective (enc) + Arena (ARENA.kind / B.approach) does the most work. Moving from strip left-to-right line battles to round/square arenas with pincer (split enemy groups at th +/- .95) or cross (th +/- PI/2) approaches genuinely changes fleet facing, firing arcs, and target prioritization, while objectives like defend, intercept, break, and hold create spatial anchors. However, square and round are gated behind axisFree (only rout, hold, and flagship, excluding bosses, compact, and ambush deployments, and purging all 5 AXIS_SHAPES).

Hard-cut/hazard shapes (deadstar and rift) create real spatial problems: deadstar introduces a 6-hex-radius gravity zone (+1 MP at d <= 6, 1-hex pull at d <= 5, -7 HP at d <= 3) around a central SOLID core, and rift severs movement across the board except at 2-3 narrow bridges while leaving line of fire open across the empty CUT chasm.

Axes that collapse into near-duplicates or cosmetics:

Shapes (open, dense, archipelago, shoals, ring, colossus, hourglass, lanes, corridor, compact): After clearSpawns() carves 6-hex player and 4-hex enemy sightline lanes toward the opposing centroid, 'rock'-based shapes (lanes, ring, dense, archipelago) lose their central blocking structure. colossus (d <= 2..3 SOLID hole near center) is just deadstar without the gravity well. shoals (up to 3 SOLID holes of R = 1..2) and archipelago (up to 6 'rock' clusters of d <= 1) both scatter small impassable islands across the middle. hourglass cuts at most w = 4 rows at c = 15 (leaving 8 rows vertically on strip), which is barely narrower than corridor (10 rows).

Base map kinds (belt, station, planet, storm, graveyard): Every map kind sprinkles 2-3 small rock blobs (ri(2,4)) and 1-2 nebula blobs (ri(4,9)). planet is mostly cut off-board on strip arenas; graveyard's 7 single-hex 'hulk' tiles are subject to clearSpawns() deletion just like 'rock'. Only storm (4 large ion storm blobs of ri(8,14) steps) and belt (when not deleted by clearSpawns() or replaced on lanes/ring) noticeably alter pathing.

Biome (ROCK_KINDS, REGION_BIOME) does the least work: it sets shader colors, specularity, emissivity, and model indices (stone, ice, iron, carbon, crystal; planet 0..7; station ring/rig/spire) with zero mechanical reference anywhere in battle.js.

2. TERRAIN AS TACTICS

Blocking group - rock, hulk, station, planet (4 of the 7 types):

READ: All four belong to BLOCKING={rock:1,hulk:1,planet:1,station:1} with identical mechanical text ("Blocks movement and line of fire.").

INFERRED: Four separate entries in TERRAIN_INFO are one mechanic wearing four skins (plus a fifth skin for SOLID set pieces). At fleet scale (up to ~20 ships), line-of-fire blocking only creates real routing and peeking decisions when obstacles form multi-hex contiguous barriers (station at d <= 1 = 7 hexes, SOLID holes in deadstar/colossus/shoals = 7-25 hexes, or intact belt ridges). Single-hex 'hulk' tiles in graveyard (spaced hdist >= 3) and ri(2,4)-step 'rock' blobs (often 2-3 unique hexes after random-walk overlap and clearSpawns()) cannot screen a 6-10 ship formation and are ignored or stepped around.

Cover group - neb (-15 hit) and debris (-10 hit):

READ: neb makes ships inside "15 points harder to hit" and placed in contiguous blobs of ri(4,9) steps (up to ri(6,11) via sector conditions); debris makes ships "10 points harder to hit" and is mostly sprinkled on single hexes via probability rolls (12%-42% around rocks, wrecks, rings, or rifts) or small ri(4,7) blobs in dense.

INFERRED: neb creates a straightforward, positive positioning decision - park ranged ships inside a 5-8 hex nebula patch for free -15 evasion with no movement or aim penalty. debris is redundant and largely ignorable at fleet scale: -10 is strictly inferior to neb's -15 with the exact same rule, and 1-hex specks scattered at 12%-30% density around obstacles cannot hold a fleet formation or justify breaking formation to chase a 10-point modifier.

Hazard - storm (-10 shield/facing/turn and -10 aim):

READ: storm strips "10 shield on every facing each turn" and makes ships "aim 10 points worse", placed in 4 large blobs of ri(8,14) steps on storm maps (plus 3 blobs of ri(6,11) from storm sector conditions).

INFERRED: Assuming ships have 4 or 6 shield facings (INFERRED from "every facing" on a hex grid), losing 10 shield per facing strips 40-60 total shield capacity per turn on top of -10 aim, with zero defensive benefit (unlike neb). Because storm is purely punitive, it is not a tactical tradeoff zone a player chooses to enter; it functions strictly as soft area denial that ships route around.

3. FIT

Canvas (30 x 22 = 660 hexes) vs. Arenas and Fleet Scale (~20 ships, 4-8 rounds, ENC_ROUNDS = 6):

Where the canvas helps: On square (22 x 22 before ragged edges) and round (R = 11, ~350 hexes) arenas paired with approachDeploy(), placing fleets at R = ext * (.68 or .74) (~7.5-8 hexes from center) creates an immediate ~15-hex engagement diameter with flanks open in all 360 degrees, fitting ~20 ships comfortably while letting battles resolve within 4-8 rounds.

Where the canvas hurts:

Dead rear columns on strip: On strip (c = 1..28, r = 3..18), line deployment places player ships at c = 5..7 and enemy ships at c = 22..24. The outer 8 columns (c = 1..4 and c = 25..28, ~29% of the strip's width) sit behind the starting lines as dead space that only serves to strands round 3-4 edgeHex reinforcements 13-15 hexes from the fight.

Unreachable compact: compact trims the board to c = 6..23, r = 5..16 (an 18 x 12 box well-suited to fast brawls), but B0small locks it behind RUN.fleet.filter(x=>x.hp>0).length<=2, so normal fleets never see it.

Multi-obstacle crowding vs. empty center: When a 10-ship side deploys into a 3-column-wide line zone (c = 5..7, |r - 11| <= 5, 33 hexes before terrain) with dmin >= 2 spacing (sc = Math.min(dmin,2)*100...), a 33-hex box can only hold ~8-10 ships at dmin >= 2 before either forcing ships to pack adjacent (dmin = 1) or triggering the < caps.length+1 half-board fallback if terrain blocks a few hexes.

4. DEPLOYMENT

Do line, flank, and ambush create three different opening problems?

No - at most two on strip, and none on square/round (where approachDeploy() overrides them):

line vs. flank is the same geometry rotated 60 degrees: Because B.deployMode applies to both sides at once, flank puts the player in the bottom-left (c = 4..10, r = 12..18, facing 5) and the enemy in the top-right (c = 19..25, r = 3..9, facing 2). Both fleets start ~17 hexes apart facing directly at each other across the diagonal; neither fleet has an angular advantage or split formation.

ambush is partially broken on strip: The player starts pushed forward (c = 8..12, |r - 11| <= 3) while the enemy zone spans c = 13..23 at r <= 5 and r >= 16. When both strips happen to receive ships, it creates a real pocket problem, but because deploy() uses a single centroid centre across both strips, any asymmetry in top vs. bottom free hexes pulls the entire enemy fleet onto one side. (By contrast, approachDeploy()'s cross and pincer modes on square/round arenas genuinely create 90 degree and two-group flanking openings.)

What the fallback zone rule does to unusual shapes:

When cand.length < caps.length + 1, deploy() replaces the deployment zone with half (c < 14 for player, c >= 16 for enemy) and scores hexes by -hdist(h, centre)*4 around the half-board centroid (c ~ 7.5, r ~ 11 and c ~ 22, r ~ 11). On shapes that cut top/bottom or side rows (corridor, hourglass, compact), this silently erases flank and ambush and reverts the opening to a central line blob.

5. READABILITY

What the field must communicate during the opening wide-to-player camera zoom:

Impassable movement blockers vs. passable hexes (CUT voids vs. SOLID / BLOCKING hexes) so the player can see lanes and bridges (rift) immediately.

Line-of-fire blockers vs. open firing arcs across empty voids.

Positive cover (neb -15, debris -10) vs. negative hazards (storm shield drain/aim penalty, deadstar gravity well pull/damage/assist rings).

Objective anchors (e.g., the friendly station in defend, relay in hold, exit hexes in break/intercept).

Does the terrain system support it? No, in three specific ways:

Legend omissions (terrainPresent()): Because terrainPresent() only scans B.terrain, the Hollow Sun gravity well (B.well with radii 3, 5, and 6), SOLID set pieces (VOID.holes), and rift chasms never appear in the legend.

Identical color tints in TERRAIN_INFO and biome recoloring: rock and hulk share #bda088; station and planet share #9a948a; and ROCK_KINDS recolors asteroids from dark grey (carbon: [.36,.34,.33]) to bright cyan-white (ice: [.78,.92,1.18], crystal: [.82,1,.95]), competing visually with special terrain across sectors.

Low-impact visual clutter: Scattering isolated 1-hex debris specks (12%-30% around obstacles) adds visual noise across the board for a marginal -10 hit modifier that does not merit fleet-level maneuvering.

4. Not Checked

Because this pack provides only battle.js lines 1-70 and 160-330 plus the census, the following cannot be verified from the evidence pack:

Rendering and UI code: How the 3D/2D renderer draws CUT vs. SOLID vs. B.terrain, whether B.well draws visible rings on the board, and the exact duration/easing of the Oct 28 opening camera zoom.

Line-of-sight and movement solver (blocks(), onBoard(), terrainConnected()): Exact implementation of blocks() and whether line-of-fire checks test SOLID and BLOCKING[T[k]] identically while ignoring CUT (rift) hexes.

Ship stats and weapon ranges (HULLS, mkWeapon): Exact movement speeds (mp), weapon ranges, and base hit chances needed to quantify how many turns it takes to cross 15 hexes or how much -10/-15 hit shifts expected DPS.

AI pathing around terrain (beyond aiWellScore): Whether the enemy AI actively seeks neb cover or avoids storm hexes the way it scores B.well (-45 at WELL_RIM, -6 at WELL_PULL).

5. Questions for the Designer

Should lanes divide the left-to-right path between fleets (vertical barrier like rift), or divide the board into top and bottom corridors (horizontal spine along midR)?

Stakes: Right now lanes places a horizontal wall along midR = 11 that runs parallel to a strip battle's advance and gets almost completely erased by clearSpawns() along r = 11.

Is flank deployment supposed to pit a flanking attacker against a standard line defender, or move both fleets to opposite corners?

Stakes: Setting a single shared B.deployMode = 'flank' moves both fleets to opposite corners with opposite facings (5 vs. 2), which plays as a diagonal head-on line fight rather than a flank attack.

Should clearSpawns() only clear a 1-2 hex radius around spawned ships instead of bulldozing 4-to-6-hex corridors toward the enemy centroid?

Stakes: The 6-hex forward bulldozer deletes the very central rocks (ring, lanes, archipelago, belt) and wrecks (graveyard) that the map and shape generators just placed to create tactical decisions.
