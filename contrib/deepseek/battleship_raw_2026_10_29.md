# Eclipse battleship entry review, DeepSeek leg (wave 5, Oct 29, 2026)

Filed verbatim from the DeepSeek run of Oct 29, 2026 (DeepThink and Search verified ON). Arrows and multiplication signs in the original are normalized to ASCII in this copy; wording is otherwise unchanged. Method notes and the chair screening live in the screening note, not in this file.

1. Verdict: ENTRY SOUND

2. Price arithmetic: CP 6 base = round((60*6+10)/5)*5 = round(370/5)*5 = 74*5 = 370. With deathless.Battleship:1.6, final = round(370*1.6/5)*5 = round(592/5)*5 = round(118.4)*5 = 118*5 = 590. This matches the entry's claimed 590 and lands above 390.

3. Ladder consistency:

- HP: 56 -> 110 -> 145 -> 250 -> boss 480. The zenith-to-meridian jump is larger than prior roster steps, but it remains below the boss and is consistent with the entry's "durability is what an Eclipse price buys" rationale.
- Armor: .2 -> .25 -> .3 -> .35 -> boss .35. Continues the +.05 step and reaches boss parity; no break.
- Speed: 4 -> 3 -> 2 -> 2 -> boss 1. The new hull plateaus at the zenith's speed rather than descending further; not a strict ladder step, but the entry explicitly justifies it.
- Turns: 2 -> 2 -> 1 -> 1 -> boss 1. Consistent.
- Evasion: 14 -> 6 -> 0 -> 0 -> boss 0. Consistent plateau.
- Regen: 3 -> 3 -> 4 -> 6 -> boss 8. Sits between zenith and boss; no existing roster hull is made strictly pointless.
- Weapons: mote 1, flare 2, zenith 4, meridian 5, boss 4 in the excerpts. The meridian has one more mount than the boss, which is worth noting, but the boss retains CP 12, HP 480, regen 8, and nova, so it is not strictly pointless.
- Size: .5 -> .62 -> .82 -> .98 -> boss 1.3. Reasonable increasing progression below the boss.

4. Rulings check:

- R1: CONFIRM - CP 6, above the CP 4 zenith in HP/armor/regen/weapons, and price 590 > 390.
- R2: CONFIRM - ab:'phase'; no reclaim.
- R3: CONFIRM - no carrier/launch/hangar field is added; nothing gives launch capability.
- R4: CONFIRM - price is fixed through base formula + faction multiplier + rounding, not a hardcoded cost, and lands above 390.

5. Integration claims:

- Roster edit required for pricing: CONFIRMED by the derivation loop, which iterates F.roster and sets cost/slots only for roster hulls.
- Roster edit required for "sold and fielded": NOT SETTLED by the excerpts. The excerpts show the pricing/slots derivation loop, but do not show shipyard stocking or genEnemyFleet.
- No CLS_NAME entry needed: NOT SETTLED by the excerpts. The CLS_NAME table is not included, so this claim cannot be verified from the provided files.

6. Naming: d_meridian fits the existing d_ deathless ids, and Eclipse meridian fits the existing "Eclipse + lowercase solar noun" pattern (mote, flare, zenith). No collision is visible in the excerpts.

7. Findings:

- [NOTE] READ - Price derivation is correct: 370 base, x1.6 = 592, rounded to 590, above 390.
- [NOTE] READ - Armor .35, regen 6, and size .98 fit between the zenith and boss in the excerpted Eclipse ladder.
- [NOTE] READ - The meridian's five mounts exceed the boss's four in the excerpts; not a blocker, but the only ladder anomaly worth playtest attention.
- [NOTE] READ - Speed 2 and evasion 0 plateau at zenith values rather than descending further; consistent with the entry's rationale but not a strict step.
- [NOTE] READ - Adding d_meridian to FACTIONS.deathless.roster is necessary for the excerpted derivation loop to price and slot it.
- [NOTE] INFERRED - "Sold and fielded" via roster cannot be verified from the excerpts, which do not show shipyard stocking or enemy-fleet generation.
- [NOTE] INFERRED - "No CLS_NAME entry needed" cannot be verified from the excerpts, which do not include CLS_NAME.

8. Not checked: I did not run the game, harness, or validation script; the entry's validation note was not independently reproduced. I did not inspect full data.js, core.js, or battle.js, nor CLS_NAME, shipyard stocking, genEnemyFleet, derive() caps, name pools, or cross-faction rows not present in the excerpts. I did not evaluate other factions or broader balance beyond the stated rulings and excerpted Eclipse ladder.
