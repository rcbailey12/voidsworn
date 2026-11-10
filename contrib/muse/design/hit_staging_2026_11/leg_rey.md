# Blind Rey leg, issue #352 (written before any other leg, 2026-11-10)

Grounded at main 0a9cd07d3e708f7e0ae725c0ff32c16865d8cfa4 (the issue was filed against 34565f3; sizes re-checked at the current head, no fx constant cited below changed between the two in a way that moves a number here). Method: code constants from godot/fx/fx_weapons.gd, fx_death.gd, fx.gd; the Board's own atlas measurements in pass 2 finding 1; the audit captures fx_01, fx_08, fx_18, fx_19, fx_20, ships_04 (fx_08 and fx_18 re-read by this leg directly).

## Measuring stick

- Screen 1920x1080, battle camera (camera_rig.gd r = 170). On-screen ship lengths at that camera (pass 2 finding 4, ships_04): frigate 60 to 80 px, cruiser 150 to 180 px, most ships 60 to 200 px.
- World lengths (fx_death.gd:141): small under 18 units, cruiser 18 to 30, capital 30 and up. A cruiser of about 24 units reading about 150 px gives roughly 6 px per world unit near the centre of the battle view. DERIVED and approximate: ships off centre read smaller. Every pixel figure below for a proposed size is a target to be set in the effect, not a conversion; the conversion is used only to describe today's state.
- The visible-gas problem: the baked impact picture fills about 55 of its 256 px cell and the capital death flash about 91 of 512 (Board-measured, finding 1). So a flipbook quad's visible core is roughly a fifth of the quad's width today. Today's on-screen sizes below are stated as quad size, with the visible core about a fifth of it until the rebake (pass 3 job P1) fills the cell.

## Today, per event (code, cruiser-class target, k = 1)

- Las hit (generic light hull hit, fx_weapons.gd:925): flash quad 1.4 units (about 8 px at 6 px per unit), held up only by its pixel floor HIT_PX 34; life 0.24 s. Gas burst 0.34 s. Afterglow 0.42 s. Hull light 0.22 s. Visible core today: single digits of px plus the floor.
- Macro hit (generic, w 2 to 3): flash quad 1.6 to 1.8 units, floor 46 to 56 px, life 0.32 s. Gas 0.34 s. Afterglow 0.50 s.
- Lance hit (beam burn, fx_weapons.gd:1002): contact flashes of 5.0 units (about 30 px, floor 34) every 0.22 s of sustain, life 0.25 s each; a vent along the burn for sustain + 0.25 s; afterglow placed mid-burn. No single ignition beat: the first step is the same size as every later step.
- Torpedo on a shield (fx_weapons.gd:988, :960): flash quad 9.0 units (about 54 px), floor 64 px, life 0.30 s; shield ripple spread 26 units, shield response life 1.1 s; ring to 12 units over 0.8 s; vent 0.45 s. Hit pause 3 frames, shake 0.35.
- Torpedo on a hull (_big_hit, fx_weapons.gd:1055): flash quad 12 units (about 72 px), floor 60 px, life 0.32 s; gas 0.42 s; a cool lift of the same 12 units at +0.20 s for 0.8 s; ring to 12 units; afterglow; hull light 0.35 s; shake 0.4, hit pause 4 frames. On fx_08 (battle view) the whole event reads as a tan puff in about 3 of 13 frames and the hull is unchanged after.
- Frigate death (small band): 0.72 s spin, a 0.22 s counted pop, pixel floors smoke 44, ribbon 28, core 60 (API.md section 5). On fx_19 (battle view) it is almost invisible.
- Cruiser death: API.md:116's paragraph is the contract (see the gap list). On fx_18 the split reads; almost nothing else in the paragraph does.
- Capital death: core flash pixel floor 70 (fx_death.gd:1327, _core_flash with px 70.0); secondary flashes floor 24 (:1421). The death flash atlas's gas fills 91 of 512 px of cell.

## Proposed staging table (targets: peak visible diameter in px at 1080p, battle camera, cruiser-class target; times in seconds)

Flash diameter ladder, one ratio all the way up: each step 1.4x the step before (plus or minus 0.05).

| Event | Flash px | Flash s | Body px | Body s | Aftermath | Aftermath s |
|---|---|---|---|---|---|---|
| Las hit | 40 | 0.12 | 30 (gas + sparks) | 0.35 | wound glow cools | 1.5 |
| Macro hit | 56 | 0.14 | 48 | 0.50 | wound glow cools | 2.5 |
| Lance hit | 78 (ignition) | 0.16 | 64 (burn patch + vent) | sustain + 0.30 | cut glow cools | 3.0 |
| Torpedo on shield | 110 | 0.16 | 150 (ripple disc on the bubble) | 0.80 | shield scar fades | 1.2 |
| Torpedo on hull | 154 | 0.18 | 140 (gas + ring + debris) | 0.90 | wound glow 4.0, smoke drift | 4.0 |
| Frigate death | 216 | 0.20 | 180 (break-up spread) | 1.10 | coals cool, wreck stays | 6.0 |
| Cruiser death | 302 | 0.22 | 260 | 3.50 | coals cool, wreck stays | 10.0 |
| Capital death | 423 | 0.25 | 380 | 4.50 | coals cool, wreck stays | 14.0 |

Ratios, flash column: 56/40 = 1.40; 78/56 = 1.39; 110/78 = 1.41; 154/110 = 1.40; 216/154 = 1.40; 302/216 = 1.40; 423/302 = 1.40.

Rules that travel with the table:
- Flash peak: full brightness inside the first 2 frames (0.033 s at 60 fps) on every row; the flash seconds above are the whole bright-core life, decay included.
- Death rows are also stated against the dying ship's own screen length: frigate death flash about 3.0x its length (216 px against 60 to 80), cruiser about 1.9x (302 against 150 to 180), capital about 2.0x (423 against a 200+ px flagship). If a death flash would fall under 2x the ship's length at a wider camera, the length multiple wins.
- Target scaling for hits: frigate target x0.8, capital target x1.2, floor of 28 px visible on any hit flash so a las hit on a frigate still reads.
- Death body beats keep the API skeleton: cruiser split at 1.38 s with secondaries staggered 0.7 to 3.5 s after the split; capital split later, 1.6 s, secondaries to 4.5 s. Frigate keeps its 0.72 s spin before the burst.
- Longest flame: no single flame element lives longer than 0.6 s anywhere in the table. The hot core inside any flash is 0.25 s at most. Edge fires and jets on a breaking hull are separate elements of 0.6 s or less, staggered; they may chain across the body beat but no one flame persists. Glowing wounds and coals are cooling metal, not flame, and run on the aftermath column. (Inside R88 and R158: flash and snuff out.)
- Reduce flashing, per row: same diameters, no shrinking. The peak is capped to the soft-lift level the code already substitutes (fx.gd:346 and fx_weapons.gd:410: burst power 1.25 in place of 3.6 to 5.2, sprite intensity min(i, 3) x 0.4), and the flash stretches instead of peaking: las 0.40 s, macro 0.42, lance 0.45, torpedo shield 0.48, torpedo hull 0.50, frigate death 0.55, cruiser death 0.60, capital death 0.65, rising as a slower glow to the same size. Body and aftermath unchanged (they are already slow).

## What API.md:116 promises that does not read on screen today (cruiser band and up; evidence fx_18, fx_20, finding 2)

1. "Running-light emission and engine glow die over 0.3 s": no readable power-down beat. On fx_18 the ship sits unchanged for about 2 s of frames before anything happens.
2. "Narrow fire/gas jets start on the future split": one small orange flicker at the stern (fx_18, third cell) is the only trace; nothing reads as jets on the split line.
3. "One thermal tear grows": no glowing tear is visible before the hull parts.
4. "One counted core flash follows 0.28 s later... 0.16 s flash at the visible lip of a torn face": what appears is a pale lavender puff beside the hull (fx_18), not a bright flash at a torn face. Finding 9 adds that death gas sits 0.36 ship lengths off the hull (fx_death.gd:179, :1045, the 0.42 x 0.85 offset), and R160(e): the stray-puff guard never covered deaths because record_spawn is never called from fx_death.
5. Light on the hulls: the paragraph's flashes and volumes never change the light on the dying ship or its neighbours in any capture.
6. "Five small secondary explosions each [half], staggered from 0.7 to 3.5 s": not visible in fx_18 or the fx_20 flagship reel; the halves simply drift apart.
7. "Slow coals cool over about ten seconds": the wreck pieces in the last frames are dark; no cooling glow.
What does read: the split itself, the halves staying visible, and debris. The staging above is sized so items 2, 3, 4 and 6 become the body beat rather than decoration.

## References (seed list; legs to extend)

- Las hit: "Why Star Wars Explosions Flash White" (bzotto.medium.com/star-wars-one-weird-trick-for-space-explosions-765b40943d10). Take: the one-frame white strobe that sells a small hit; our flash peak inside 2 frames is the same discipline at 60 fps.
- Torpedo on shield: Star Trek Generations, Enterprise-D vs Bird of Prey (youtube.com/watch?v=6A9IZHWz45Q). Take: the shield answers as a surface event bigger than the flash itself; the ripple disc out-sizes the core.
- Torpedo on hull: The Expanse, Rocinante attack run (youtube.com/watch?v=_c9W-icdTmg). Take: a torpedo hit is a hull event, not a cloud: flash, debris thrown off the surface, and a mark that stays.
- Capital death: Pegasus's death, Battlestar Galactica "Exodus Part 2", stills and breakdown (polygon.com/battlestar-galactica-season-3-exodus-20th-anniversary). Take: a capital death is staged in acts (fires, break-up, secondary kills) over many seconds, and the ship stays the biggest thing on screen throughout.

## Questions for Ryan (chair will carry these to the synthesis)

1. Longest flame: (A) 0.4 s, strictest reading of R88; (B) 0.6 s [pick]; (C) 0.8 s.
2. Ladder steepness: (A) constant 1.4x per step [pick]; (B) 1.25x, deaths less dominant; (C) 1.55x, deaths tower over hits.
3. Torpedo on shield vs on hull: (A) shield flash smaller, ripple disc bigger [pick]; (B) same size both; (C) shield event bigger overall.
4. Capital death body: (A) 4.5 s [pick]; (B) 3.5 s, the API skeleton as written; (C) 6 s, full ceremony.
5. Capital coals: (A) 14 s (R90's cooling tail) [pick]; (B) 10 s (API today); (C) until the battle ends.
