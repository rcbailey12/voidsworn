# Eclipse battleship entry review, Qwen leg (wave 5, Oct 29, 2026)

Filed verbatim from the Qwen3.8-Max run of Oct 29, 2026 (both model gates passed; chat ac5bd58a-263c-428a-8f8d-cb41b4e3df92, "Battleship Entry Review"). En dashes, arrows, and multiplication signs in the original are normalized to ASCII in this copy; wording is otherwise unchanged. Method notes and the chair screening live in the screening note, not in this file.

ENTRY SOUND

## Price arithmetic

Recomputed from the excerpts' derivation loop (data.js:545-546):

1. Base CP formula: `Math.round((60x6+10)/5)x5 = Math.round(370/5)x5 = 74x5 = 370`.
2. Faction-class multiplier: the entry adds `Battleship:1.6` to the deathless FAC_PRICE table. `370 x 1.6 = 592`.
3. Rounding to nearest 5: `Math.round(592/5)x5 = Math.round(118.4)x5 = 118x5 = 590`.

My figure 590 matches the entry's claimed price. 590 > 390. ✓

Slots: `cp=6 -> cp<=2?1 : cp<=4?2 : 3` -> 3. Matches the entry's claim. ✓

No hardcoded `cost` or `slots` field appears in the HULLS line; both are left to the loop. ✓

## Ladder consistency

| Stat | mote (cp1) | flare (cp2) | zenith (cp4) | meridian (cp6) | boss (cp12) | Verdict |
|---|---|---|---|---|---|---|
| hp | 56 | 110 | 145 | 250 | 480 | Steps +54/+35/+105/+230 - proportional to CP gaps. OK |
| armor | .20 | .25 | .30 | .35 | .35 | +.05 per class maintained; equals boss (see NOTE 1) |
| speed | 4 | 3 | 2 | 2 | 1 | Holds at 2; boss drops to 1. OK |
| turns | 2 | 2 | 1 | 1 | 1 | Consistent. OK |
| evasion | 14 | 6 | 0 | 0 | 0 | Consistent. OK |
| regen | 3 | 3 | 4 | 6 | 8 | +2 step; sits cleanly between 4 and 8. OK |
| size | .50 | .62 | .82 | .98 | 1.30 | +.16 step, in line. OK |
| weapons | 1 | 2 | 4 | 5 | 4 | Meridian exceeds boss mount count (see NOTE 2) |

No existing hull is rendered strictly pointless: the zenith retains its unique `reclaim` ability, lower CP cost (4 vs 6), and lower credit cost (390 vs 590), keeping it relevant in CP-budgeted fleets. The mote and flare occupy their own CP tiers. The boss remains dominant in hp (480 vs 250), regen (8 vs 6), and CP weight (12 vs 6).

## Rulings check

- R1 - CP 6 battleship, stronger and more expensive: Confirmed. `cp:6`; hp, armor, regen, weapons, and price (590 > 390) all exceed the zenith. READ.
- R2 - No `ab:'reclaim'`: Confirmed. Entry uses `ab:'phase'`. Reclaim remains on d_harvester only. READ.
- R3 - No carrier / no launch capability: Confirmed. `cls` is `'Battleship'`, no hangar field, no carrier-class key, no launch-related data. READ.
- R4 - Price fixed through derivation, not hardcoded: Confirmed. No `cost` key in the HULLS line; the 370 -> x1.6 -> 590 path runs through the roster loop's own formula. The FAC_PRICE `Battleship:1.6` key continues the faction's +.05-per-class multiplier ladder (1.45 / 1.5 / 1.55 / 1.6). READ.

## Integration claims

- Roster-line edit required for pricing, selling, and fielding: Confirmed by the excerpts. The derivation loop iterates `for(const id of F.roster)` (data.js:544); a hull absent from the roster array is never visited, so `h.cost` stays `null` and the hull is never priced or stocked. The entry's addition of `'d_meridian'` to the roster array is necessary. READ.
- No CLS_NAME entry needed: Cannot be settled from the excerpts. The excerpts contain no CLS_NAME table or `clsName()` function. The entry's claim that CLS_NAME remaps only four boss-class keys and that `clsName('Battleship')` passes through unchanged is plausible but unverifiable here. READ (absence noted).

## Naming

Display name "Eclipse meridian" follows the line-hull pattern *Eclipse + solar noun of rising scale* (mote -> flare -> zenith -> meridian). The meridian (the sun's great noon circle) is a fitting step above the zenith point. No collision with Eclipse ranks, weapon names, or the boss title. ✓

ID `d_meridian` follows the `d_` prefix. However, the three existing line-hull IDs (*scythe, jackal, harvester*) are dark/reaping nouns deliberately distinct from the solar display names. *Meridian* is itself a solar/astronomical term, collapsing the ID/display-name distinction the other rows maintain. This is a stylistic deviation, not a data error. (See NOTE 3.)

## Findings

1. **[NOTE] Armor equals the boss.** Meridian ar .35 matches The Unsetting's .35. The +.05-per-class step is internally consistent, but armor ceases to differentiate the top two hulls. The boss remains superior via hp (480 vs 250), regen (8 vs 6), and CP weight, so the ladder is not broken. READ.
2. **[NOTE] Five weapon mounts vs the boss's four.** The meridian carries the zenith's four mounts plus a Null shredder turret, exceeding the boss's mount count. The boss is flagged `boss:true` and sits outside normal ladder constraints, and the entry justifies the extra mount as PD coverage for a speed-2, evasion-0 hull. Not a ladder break, but worth a designer's eye. READ.
3. **[NOTE] ID breaks the dark-noun pattern.** Existing line-hull IDs (scythe, jackal, harvester) are reaping/dark nouns paired with solar display names. `d_meridian` reuses a solar term for the ID. Functionally harmless; cosmetically off-pattern. INFERRED.
4. **[NOTE] CLS_NAME claim unverifiable.** The excerpts do not include the CLS_NAME table or the `clsName()` helper. The entry's assertion that no CLS_NAME edit is needed cannot be confirmed or refuted from the provided material. READ.
5. **[NOTE] Fleet-power ratio acknowledged.** The entry transparently flags that a lone meridian reads 6.00 fleetPower vs the Dominion's 6.45 at equal CP, attributing the gap to the Eclipse durability profile. This is an observation, not a defect. READ.

No [BLOCKER] or [FIX] items identified.

## Not checked

- CLS_NAME table contents and `clsName()` behaviour - not present in the excerpts.
- `derive()` internals beyond the fields the excerpts expose (e.g. the .6 armor cap the entry cites, admiral/boon modifiers on regen).
- `equivHull`, shipyard stocking, and `genEnemyFleet` logic - referenced by the entry but not included in the excerpts; their behaviour is taken on the entry's validation-note description.
- Cross-faction balance beyond the two reference battleships (cathedral, h_dominion) the entry cites; per instructions, other factions are out of scope.
- Playtest feel - whether 590 credits for 250 hp / .35 armor / regen 6 is the right power-per-credit trade at the table.
- The validation scratch environment described in section 5 of the entry; the report reviews the data entry and the excerpts only.
