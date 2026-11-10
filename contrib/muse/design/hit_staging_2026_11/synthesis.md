# Hit and death staging table (issue #352, chaired synthesis)

Delivered by Rey (chair). Legs: Rey blind (written first), DeepSeek (writer), Qwen (writer), Flash (ideation), Grok (ideation, see the legs section). Argon blocked since 2026-11-05. Grounding: FINDINGS R88, R90, R157, R158, R160; audit pass 2 findings 1, 2, 4, 9 with Board verdicts; audit pass 1 holes P1, P2; godot/fx/API.md line 116; fx_death.gd, fx_ship.gd, fx_weapons.gd, fx.gd read at main 0a9cd07; capture sheets fx_01, fx_08, fx_18, fx_19, fx_20, ships_04.

## How sizes are measured

- Screen 1920 x 1080, battle camera at its default distance r = 170 (godot/render/camera_rig.gd:9). Near the centre of the view, 1 world unit is about 6 px (from finding 4: a frigate is 60 to 80 px, a cruiser 150 to 180 px). The conversion is a centre-screen average and varies about 15 percent by ship class and screen position.
- Size means the peak visible diameter of the effect in that beat: the widest extent of any luminous or opaque element, rings and ripples counted at their outer edge, debris excluded, and light cast on other hulls not counted (it is specified separately below).
- The table is written for a cruiser target (about 165 px on screen). Hit rows scale by target: x0.8 against a frigate, x1.2 against a capital.
- Floors: no hit flash under 34 px at 1080p (the lightest floor the code already has, HIT_PX in fx_weapons.gd:67). A death's core flash is at least twice the dying ship's on-screen length.
- Times are seconds from the start of the event. The death rows keep the API.md line 116 skeleton: power-down 0.3 s, split at 1.38 effect seconds, core flash 0.28 s after the split, secondaries staggered 0.7 to 3.5 s after the split.

## The table

| Event | Flash: px / s | Body: px / s | Aftermath: px / s | Flash step |
|---|---|---|---|---|
| Las hit | 40 / 0.10 | 30 / 0.35 | 24 / 1.5 | first step |
| Macro hit | 56 / 0.12 | 48 / 0.50 | 36 / 2.5 | x1.40 |
| Lance hit | 78 / 0.14 per pulse | 64 / sustain + 0.30 | 48 / 3.0 | x1.39 |
| Torpedo on a shield | 110 / 0.16 | 156 / 1.10 (the ripple) | 90 / 1.2 | x1.41 |
| Torpedo on a hull | 154 / 0.16 | 140 / 0.90 | 110 / 4.0 | x1.40 |
| Frigate death | 216 / 0.18 | 180 / 1.10 | 130 / 6.0 | x1.40 |
| Cruiser death | 302 / 0.20 | 260 / 3.50 | 240 / 10.0 | x1.40 |
| Capital death | 423 / 0.22 | 380 / 4.50 | 320 / 14.0 | x1.40 |

What each beat is:

- Flash: the white core at peak, reached inside the first two frames, then decaying for the rest of the stated life. Torpedo rows and all deaths also cast light on nearby hulls during this beat (owner ruling, 2026-11-10, question 5: the heavy rows only, not lance or las).
- Body: las and macro are a hot spark and a short gas puff. The lance body is the contact burn for as long as the beam dwells, plus a 0.30 s tail after it lifts. The shield body is the ripple disc expanding across the dome (156 px is the code's current 26 units at 6 px per unit, and its 1.10 s matches the code's shield life). The torpedo-on-hull body is gas, debris and the hot core inside the flame cap. Death bodies are the break-up itself: spin and pop for a frigate; power-down, tear, split, core flash and secondaries for cruiser and capital.
- Aftermath: the glowing wound, cut line or shield scar cooling, and for deaths the coals and drifting halves. On the two big deaths only the first part is active (about 5 s on a cruiser, about 8 s on a capital: gas, embers, debris motion); the rest of the stated time is the passive coals shader, which R90 prices as cheap. This split form is the owner's ruling, 2026-11-10 (question 4).
- Secondary explosions on cruiser and capital deaths: each at least 75 px, five per half, staggered 0.7 to 3.5 s after the split per API.md line 116, each one a separate flame element under the cap below. The 75 px floor is the owner's ruling, 2026-11-10 (question 6), splitting the chair's 60 and DeepSeek's 90. Today's floor is 24 px (fx_death.gd:1421), which reads as a blink.

Ladder placement note: the shield row sits below the hull row on the flash column and above it on the body column. A shield flash is a surface strobe spread thin; the hull flash is a concentrated breach. The shield's spectacle is its ripple, which is the largest body of any weapon hit. Qwen's leg dissents and puts the shield flash above the hull flash; the chair holds that the flash ladder stays honest about concentration, and the ripple carries the shield row's size in its own column. This is question 3, still open with the owner at this revision; the table as printed follows the chair's placement.

## Flame cap

No single flame or hot-core element lives longer than 0.70 s anywhere in the table, and no hot core stays at full heat longer than 0.25 s. Owner ruling, 2026-11-10 (question 1): 0.70 s, splitting the chair's 0.60 and DeepSeek's 0.80. It sits inside R88 (flash and snuff out), R158 (not a second of rolling fire) and R90 (the death budget lives in the first 2 s; the long tail is a cooling shader, not flame). Glowing wounds, coals, venting gas and drifting smoke are not flame and are not bound by the cap. Leg positions going into the ruling: Qwen 0.45 s, Flash 0.60 s, DeepSeek 0.80 s.

## Reduce-flashing variant (per row)

Same sizes as the table. The flash beat's peak drops to the code's soft-lift level (power 1.25, fx.gd:346 and fx_weapons.gd:410) and its life stretches into a smooth rise and fall: las 0.40 s, macro 0.42 s, lance 0.45 s per pulse, torpedo on shield 0.50 s, torpedo on hull 0.50 s, frigate death 0.55 s, cruiser death 0.60 s, capital death 0.65 s. Body and aftermath beats do not change; they are not strobing hazards, and the code's limiter only governs flashes. No row shrinks.

## What in API.md line 116 does not read on screen today

1. The power-down beat. Running lights and engine glow dying over 0.3 s is not readable in fx_18 or fx_20; there is no visible shutdown phase before the event starts.
2. The jets on the future split. The death bake is smoke only (finding 1), so nothing hot starts along the split line.
3. The thermal tear. No glowing tear grows before the split; fx_18 sits unchanged for cells, then the puff arrives.
4. The core flash as specified. The code floor is 70 px (fx_death.gd:1327) against 302 and 423 px in this table, what appears is a pale puff with almost no light (Board verdict on finding 2), and it sits off the hull at 0.42 x 0.85 of the ship's length (fx_death.gd:179 and :1045, finding 9), not at the visible lip of the torn face.
5. The contained 0.42 s volume. When the flash budget allows it, what appears is the 64-cell smoke puff filling about a fifth of its cell (finding 1, Board re-measured at about 52 of 256 px on the impact cell and 92 of 512 on the capital flash cell).
6. Light on nearby hulls. No flash in the captures lights the ships around it; finding 2's flash beat includes hull light and no leg found it in the code or the sheets.
7. The secondaries. At a 24 px floor (fx_death.gd:1421) they are blinks; fx_20 shows none.
8. The coals. Wrecks go dark instead of cooling through a visible gradient, and record_spawn is never called from fx_death.gd, so the stray-puff check has never covered deaths (R160(e)).

What does read today: the split itself, the halves staying visible, and drifting debris.

Two numbers in the evidence flagged as imprecise, not wrong: finding 2 calls a torpedo hit "a tan cloud for about a quarter of a second"; in code the flash lives 0.32 s and the gas 0.42 s (0.74 s alive in total), and the quarter second is the visible peak in the capture. And the HIT_PX floors (34, 46, 56 px) are larger than the world-space flash quads for light weapons (1.4 to 1.8 units is 8 to 11 px), so for las and macro the floor is the size today and the world-space parameter does nothing at the battle camera; that is why this table is written in on-screen pixels.

## References (links only; one line on what to take from each)

- Las hit: https://bzotto.medium.com/star-wars-one-weird-trick-for-space-explosions-765b40943d10 - the single-frame white strobe; the flash is the hit and the body is secondary.
- Macro hit: https://www.youtube.com/watch?v=_c9W-icdTmg - The Expanse, Rocinante attack run; kinetic hits read as a punch with ejecta and a brief hot spot, no fireball.
- Lance hit: https://www.youtube.com/watch?v=6A9IZHWz45Q - Star Trek Generations, Enterprise-D vs Bird of Prey; a sustained beam contact stays bright and vents material while it dwells.
- Torpedo on a shield: https://www.youtube.com/watch?v=6A9IZHWz45Q - same fight; the shield hit is a surface event and the ripple out-sizes the contact core.
- Torpedo on a hull: https://www.youtube.com/watch?v=_c9W-icdTmg - The Expanse, Rocinante attack run; a hull event with debris spray and a scar that stays.
- Frigate death: https://www.youtube.com/watch?v=_c9W-icdTmg - same run; a small ship badly hit sheds pieces and vents in a visible stream before going dark.
- Cruiser death: https://www.polygon.com/battlestar-galactica-season-3-exodus-20th-anniversary/ - the Pegasus death in BSG "Exodus Part 2" (a capital in its own fiction; the staging transfers); a big ship dies in acts, with secondaries along the hull before the break.
- Capital death: https://www.polygon.com/battlestar-galactica-season-3-exodus-20th-anniversary/ - same sequence; lights die, vents open, the ship breaks in two, halves drift with trailing gas over many seconds.

Further links suggested by the DeepSeek, Qwen and Flash legs were self-marked unverified or were search pages; they are recorded in the leg files and are not carried here as references.

## Legs and what the chair took

- Rey (blind, written before any other leg was read): the ladder shape, the constant 1.4x step, the shield placement, the API skeleton for death bodies, the 14 s capital tail. Its flash lives (0.12 to 0.25 s) were shortened toward the other legs' convergence.
- DeepSeek (writer): complete and internally consistent; its ladder (46 to 380 px) corroborates the big scale. Adopted: the measure refinement (rings by outer diameter, wounds by longest glowing extent) and the argument that the 24 px secondary floor cannot read. Not adopted: its compressed times, which drop the API death skeleton it elsewhere says matches, and its 0.80 s flame cap. Its API gap list paraphrased the contract with invented phrases; the substance was re-derived from the sources for the list above.
- Qwen (writer): the tightest argued leg and the most conservative; its ladder (12 to 240 px) sits at or below today's floors and its death bodies drop the API skeleton, so its sizes and death times are not adopted. Adopted: the outer-edge ring measure, the HIT_PX floor observation, the active-versus-passive split in the capital aftermath, hull light scoped to torpedoes and deaths, reduce-flashing scoped to the flash beat, and the torpedo quarter-second flag.
- Flash (ideation): adopted its flash-life critique (a 0.24 to 0.32 s flash is a glowing orb, not a strobe; the torpedo flash living 76 percent as long as its own gas plume is the beige ball stated precisely) and its half-sine reduce-flashing envelope. Its near-code sizes are not adopted. Three of its code claims go beyond the pack evidence and are treated as inference, not fact (recorded in its leg file).
- Grok (ideation): did not land. Its sign-in waited on a Google phone approval that had not completed when this was delivered, so the seat is recorded empty rather than filled by a substitute, per the model gates. If it lands later it will be added as a follow-up.

## Questions for the owner: rulings recorded 2026-11-10

1. Flame cap. RULED: 0.70 s (owner split the chair's 0.60 and DeepSeek's 0.80; Qwen held 0.45).
2. Ladder scale. RULED: the 1.4x ladder in this table, capital flash 423 px, over the compressed near-code scale (Flash and Qwen: capital flash 185 to 240 px).
3. Shield placement. OPEN. (a) Shield flash smaller than hull flash, ripple bigger [CHAIR PICK, the placement printed in the table]. (b) Shield flash bigger than hull flash (Qwen).
4. Capital aftermath. RULED: 14.0 s total with about 8 s active and the rest the passive coals shader (the chair pick; over 10.0 s flat matching the API coal wording, and 8.0 s flat, Qwen's active window only).
5. Hull light. RULED: torpedo rows and all deaths light nearby hulls (the chair pick; over lance and everything above, and every event).
6. Secondary explosion floor. RULED: 75 px (owner split the chair's 60 and DeepSeek's 90; Flash held 42 to 48).

## Not checked

- Nothing here was measured in a running build; sizes are staged targets derived from the capture sheets and the code's current numbers, not timings from play.
- Qwen's cite of bake_death.py line 26 for the smoke-only bake was not independently re-read by the chair; finding 1 establishes the smoke-only substance.
- No cost pass: what the 423 px flash, hull lights and bigger secondaries do to the frame gate (R116) is the Board's measurement to make when this is built.
