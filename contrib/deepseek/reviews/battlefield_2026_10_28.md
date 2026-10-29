# DeepSeek blind leg: battlefield and terrain audit (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (DeepSeek, DeepThink ON + Search ON, verified by toggling). Em dashes and en dashes normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://chat.deepseek.com/a/chat/s/d0c45f85-316e-4440-bdff-8771bef4b069. Evidence pack: the Oct 28 battle program battlefield pack (code slices pinned to main 264f441d). Method notes and screening live outside this file.

## 1. Proof of reading

Read: EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE; battle.js header slice (board constants, TERRAIN_INFO, REGIONS, biomes, ENCOUNTERS, arenas); terrain/arena generation and deployment slice.

Overall verdict: FIELDS VARY ON PAPER. The generator has many axes, but actual battle decisions are narrowed by pre-cleared blocking terrain, limited arena/shape combinations, forced deployment modes, and mostly cosmetic biome variation.

## 2. Findings

### [BLOCKER] Blocking terrain is deliberately cleared out of spawns and approach lanes.

Claims: READ - clearSpawns() says "clear rocks and wrecks around each ship and along a lane toward the enemy" and clears player?6:4 hexes along the line to the enemy. INFERRED - with fleets of about 20 ships and 4-8 rounds, many LOS/movement blocks are removed before play, so line-of-fire blocking is not a reliable opening system; it is an exception, not the board's logic.

### [BLOCKER] The canvas is large for the stated fleet size and battle length.

Claims: READ - const BW=30, BH=22; strip margins leave roughly a 28x16 field; square is 22x22; round uses R:11. INFERRED - 10 ships per side spread over these fields, in 4-8 rounds, will often leave large unused areas. The board is cinematic in scale but tactically sparse; many hexes are irrelevant to the fight.

### [FIX] Arena variation is much narrower than the census implies.

Claims: READ - axisFree=['rout','hold','flagship']; most other encounters fall back to 'strip'. Non-strip arenas replace axis shapes: if(ak!=='strip'&&AXIS_SHAPES.includes(shape)) shape=pick([...]). INFERRED - square/round fields are mostly limited to a few objectives and cannot use corridor/lanes/hourglass/rift/compact, so arena variety is real but gated and less common than "12 board shapes" suggests.

### [FIX] Deployment modes are not three general opening problems, and the fallback undermines shape constraints.

Claims: READ - B.deployMode=enc==='ambush'?'ambush':['defend','hunt','intercept','break'].includes(enc)?'line':(cfg.dep||'line'); fallback triggers on if(cand.length<caps.length+1) and uses half-board zones. INFERRED - ambush is forced by encounter, several objectives force line, and the fallback can replace an unusual shape's intended zone with a generic half-board. That makes shape-driven deployment constraints disappear exactly when they should matter most.

### [FIX] Terrain readability fails at the color layer.

Claims: READ - rock and hulk both use col:'#bda088'; station and planet both use col:'#9a948a'. INFERRED - in the ruled wide opening shot, the player cannot distinguish asteroid from wreck or station from planet by color. The legend exists, but the field itself does not communicate the blocking type quickly enough for a cinematic wide-to-zoom opening.

### [FIX] Most of the seven terrain types are passive modifiers, not route decisions.

Claims: READ - blockers "Blocks movement and line of fire"; nebula is 15 harder to hit; debris 10 harder; storm strips 10 shield per facing and worsens aim by 10. INFERRED - only blocking terrain and the deadstar gravity well reliably create decisions. Nebula/debris are optional cover blobs a competent player can ignore unless an objective forces entry; storm is area denial but random and avoidable. At fleet scale, most terrain is noise or a modest to-hit modifier.

### [NOTE] Biome and rock-kind variation is cosmetic.

Claims: READ - ROCK_KINDS vary col, spec, and em; REGION_BIOME selects rock/planet/station visual variants. INFERRED - these do not change movement, LOS, cover, damage, or deployment. The "biome" axis changes how the same field looks, not how it must be flown.

### [NOTE] The deadstar gravity well is the strongest real terrain system, but it is gated away from most battles.

Claims: READ - WELL_RIM=3, WELL_PULL=5, WELL_ASSIST=6, WELL_DMG=7; fitEncounter removes deadstar from non-deep maps. INFERRED - the well creates genuine risk/reward movement, but only on deep maps and only when the shape survives encounter fitting. Most fights never see the one terrain feature with strong tactical identity.

### [NOTE] Sector-condition terrain adds random blobs rather than strategic terrain.

Claims: READ - sector condition injects n=...3...4 blobs into every battlefield, never in deployment columns. INFERRED - this increases density/noise but does not guarantee a meaningful route, firing lane, or objective interaction. It is variety by random placement, not by design pressure.

## 3. Explicit checks

### VARIETY

Real differences: board shape cuts and set pieces (rift, deadstar, colossus, corridor, compact), map kind terrain generators, and arena/approach for the few axisFree encounters. Cosmetic differences: biome rock kind, planet index, station variant, and most color changes. The axis doing the most work is shape cut/set-piece placement, because it can split routes or create a center obstacle. The axis doing the least work is biome/rock kind, which is visual only.

### TERRAIN AS TACTICS

- Rock/hulk/station/planet: real blockers, but sparse in many maps and explicitly cleared near spawns/lanes. Planet is a large edge obstacle; station can matter in station maps/defend. Otherwise blocking is situational.
- Nebula: 15-point to-hit penalty is meaningful if a fight happens inside it, but it is a random blob and optional cover.
- Debris: 10-point penalty is weaker and easier to ignore.
- Ion storm: 10 shield per facing per turn plus 10 aim penalty is the best area-denial terrain, but random placement and avoidability reduce it to a local tax.
- Deadstar well: real tactical terrain with pull, damage, and movement assist, but gated.

The numbers say most terrain is either binary blocking or a modest modifier; without base hit/shield/movement values in the pack, I cannot quantify 10/15 points, but the structure is clear: blockers and the well create decisions; nebula/debris usually do not.

### FIT

INFERRED assumption: movement and weapon ranges are not so large that a 30x22 canvas is crossed in one round; the pack does not give those numbers. Under that assumption, the canvas is too big for 20 ships and 4-8 rounds. Strip and square fields leave broad empty flanks; line deployment puts each side in a narrow 3-column band, increasing travel time. The canvas helps cinematic framing and non-strip approaches, but hurts tactical density: terrain and enemies are spread thin, and many ships can avoid the board's features entirely.

### DEPLOYMENT

Line is opposite 3-column bands; flank puts player low and enemy high with different facings; ambush puts the player in a narrow central-left zone and the enemy in right-side top/bottom bands. They are geometrically different, but not three general problems because encounters force line/ambush and the campaign layer sets enemy line/flank frequency. The fallback half-board rule is the bigger issue: when a shape leaves the intended zone too small, deployment ignores the shape's constraint and uses a generic half-board. That directly undermines unusual shapes.

### READABILITY

The wide opening shot must communicate board outline, blocking set pieces, terrain type, deployment, enemy fleet, and objective markers. The terrain table exists, but duplicate colors for rock/hulk and station/planet mean the field itself does not communicate blocker type. At wide zoom, 15/10-point modifiers and LOS blocking are not legible without icons/tooltips. The camera move supports gross shape and enemy fleet reading; it does not support reading the terrain system's tactical meaning in that window.

## 4. Not checked

- Actual UI legend rendering, icons, tooltips, and camera timing/easing.
- Base hit chances, shield values, movement points, and weapon ranges, so the real weight of 10/15-point modifiers cannot be quantified.
- AI pathing and terrain use beyond the deadstar aiWellScore.
- Exact rendering of CUT, SOLID, and enclosed holes.
- The campaign-layer enemy deployment ratio; it is stated in the census but not shown in this code slice.
- Actual fleet compositions and battle-length distribution.
- Sector-condition definitions and how often they produce meaningful terrain.
- Performance and pathfinding cost on the 30x22 canvas.

## 5. Questions for the designer

1. Is clearSpawns() intended to guarantee clean opening lanes, or is it a safety fix that accidentally removes the terrain game? Stakes: determines whether blocking terrain is supposed to matter at all in the first round.
2. How long is the wide opening shot, and what terrain information must be legible without a tooltip? Stakes: the duplicate blocker colors may make the ruled camera move fail readability even if the legend exists.
3. Should biome/rock kind ever affect mechanics, or is it purely visual? Stakes: if purely visual, the "variety" claim should be scoped to shape/map terrain, not biome.
