# Eclipse battleship: finished data entry (wave 5, slate item 2)

Chair note (Oct 29, 2026): reviewed by DeepSeek and Qwen legs, both ENTRY SOUND with no BLOCKER or FIX (filed under contrib/deepseek/reviews/ and contrib/qwen/reviews/). One naming note from the Qwen leg, carried here rather than applied silently: the existing line-hull ids (scythe, jackal, harvester) are dark nouns while the solar register lives in the display names; d_meridian puts a solar term in the id. If Opus wants the split preserved, d_wraith is the chair's suggested id for the same hull; the display name "Eclipse meridian" stands either way. The hull has no references yet, so the id choice is free now and load-bearing later.

Proposal for Opus to verify and land. Three edits, all in data.js: one HULLS row, one
FAC_PRICE key, one FACTIONS roster id. No other file changes. Every line below is
paste-ready and was validated end to end through the game's own machinery (see the
validation note at the end).

Rulings honored: battle-layer Q7 (the Eclipse ladder gains a battleship-class hull;
Eclipse ships are stronger but more expensive across stats, price and CP), battle-layer
Q10 (reclaim stays the zenith's signature; this hull does not use it), and the faction
shape pricing fix (a real Battleship price for Eclipse, above the cruiser's 390, not
the 370 fallback).

## 1. HULLS entry (data.js, Eclipse block, after d_harvester, before d_boss)

```js
  d_meridian:{n:'Eclipse meridian',cls:'Battleship',fac:'deathless',size:.98,cp:6,hp:250,sh:0,rg:0,ar:.35,sp:2,tn:1,ev:0,w:[['gauss','T'],['gauss','T'],['doom','F'],['gsentry','T'],['flak','T']],ab:'phase',regen:6,reanimate:true},
```

cost and slots are deliberately absent, matching every other non-player-faction hull:
the roster loop (data.js:545-546) derives cost from CP and slots from the CP band.
With the FAC_PRICE key below, the derived price lands at 590 and slots at 3.

## 2. FAC_PRICE addition (data.js:539, inside the deathless table)

The deathless segment of the FAC_PRICE line becomes:

```js
deathless:{Frigate:1.45,Destroyer:1.5,Cruiser:1.55,Battleship:1.6}
```

The only change is the added `,Battleship:1.6`. The CP base price for a cp6 hull is
round((60*6+10)/5)*5 = 370; the multiplier takes it to 592, which the game's rounding
lands on 590.

## 3. Roster line (data.js, FACTIONS.deathless) and CLS_NAME

```js
    roster:['d_scythe','d_jackal','d_harvester','d_meridian'],boss:'d_boss',sq:null},
```

The roster line is required, not decorative: the price and slots derivation loop only
visits roster hulls, shipyards stock from the roster, equivHull maps through it, and
genEnemyFleet builds enemy fleets from it. Without it the hull exists but is never
priced, sold or fielded.

No CLS_NAME entry is needed. CLS_NAME only remaps four boss class keys (Battle-barge,
Bio-titan, Ark, Tomb-ark); clsName('Battleship') returns 'Battleship' unchanged, the
same as the existing cathedral and h_dominion rows. No name-pool line is needed either:
individual ship names for Eclipse fleets come from the existing deathless pool at
data.js:531, which already fits the register.

## 4. Rationale, stat by stat

The Eclipse ladder today: d_scythe 'Eclipse mote' (Frigate, cp1, hp56, ar .2, regen 3),
d_jackal 'Eclipse flare' (Destroyer, cp2, hp110, ar .25, regen 3), d_harvester 'Eclipse
zenith' (Cruiser, cp4, hp145, ar .3, regen 4, ab reclaim), d_boss 'The Unsetting'
(Tomb-ark, cp12, hp480, ar .35, regen 8). Cross-faction battleship references: cathedral
(Sunward Crusade, cp5, hp220, ar .3) and h_dominion 'Dominion dreadnought' (Hegemony,
cls Battleship, cp6, hp230, ar .25).

- Name and id: 'Eclipse meridian', id d_meridian. Line hulls are Eclipse plus a solar
  noun of rising scale: mote, flare, zenith. The meridian is the sun's great noon
  circle, one step grander than the zenith point, and the word collides with nothing:
  not an Eclipse rank (Shade, Gloam, Umbra, Midnight, Nadir), not a weapon word
  (Corona belongs to the arc). The display name uses Eclipse only; deathless appears
  solely as the fac data id, as on every other row.
- cls 'Battleship', cp 6: the Q7 step above the cp4 zenith, at the same CP as the
  Dominion, the game's other line battleship.
- hp 250: up 72 percent on the zenith's 145 for 50 percent more CP, and above the
  Dominion's 230 at equal CP, because durability is what an Eclipse price buys (the
  faction has no shields at all). It stays well below the cp8 Ascendant (370) and the
  boss (480), so the ladder's top end is untouched.
- sh 0, rg 0: faction invariant. Every Eclipse hull carries sh:0; the faction's
  defence is armor, hull regen and reanimate, never shields. rg is shield regen and
  stays 0 with it.
- ar .35: the armor ladder climbs .2 / .25 / .3 by class, so .35 continues the same
  +.05 step. It equals The Unsetting's armor and stays under the .6 cap in derive().
- sp 2, tn 1, ev 0: identical to the zenith and to both other line battleships
  (cathedral and the Dominion are both sp2 tn1 ev0). The Eclipse speed ladder descends
  4 / 3 / 2 down the classes; the battleship holds at 2 instead of dropping to the
  boss's 1.
- size .98: matches the Dominion exactly; the zenith is .82, the boss 1.3.
- Weapons: the zenith's package (two Null cannons on turrets, a Corona arc forward,
  a Null spire) plus The Unsetting's Null shredder turret, five mounts in all. Every
  arc is T or F; nothing faces backward. The second point-defense system is the
  point: a speed 2, evasion 0 hull cannot dodge wings, so it carries both of the
  faction's PD weapons. Capital damage stays one clean step above the zenith rather
  than doubling up on Corona arcs, which no hull in the game mounts twice.
- ab 'phase' (Fold skip): the Eclipse faction ability, the one the rename map ties to
  the fold drive; the mote and the flare already carry it. reclaim is not used (Q10:
  it stays the zenith's alone). surge was rejected because it restores shield facings
  on a faction with no shields; nova stays boss and unique tier only.
- regen 6, reanimate true: the regen ladder runs 3 / 3 / 4 by class with the boss at 8,
  so 6 is the battleship step (2.4 percent of max hull per round, before admiral or
  boon effects). reanimate is carried by every Eclipse line hull and by no boss.
- Price 590 (FAC_PRICE Battleship 1.6): the deathless multiplier ladder rises +.05
  per class (Frigate 1.45, Destroyer 1.5, Cruiser 1.55), so Battleship 1.6 continues
  the pattern and keeps Eclipse the highest-priced faction at every class, which is
  the B3 design note in data.js's own comment ("Deathless pay most for few, durable
  hulls"). Without the key, the cp6 fallback price is 370, below the zenith cruiser's
  390: the inversion Q7's pricing fix exists to close. At 590 the battleship costs
  200 more than the cruiser for 2 more CP, the steepest per-CP price in the game,
  which is the faction shape ruling working as intended.

One honest observation for the coder, not a defect: on the game's own fleetPower
metric a lone meridian reads 6.00 against the Dominion's 6.45 (zenith 4.00). The
premium buys the Eclipse durability profile (armor .35, regen 6, reanimate) rather
than raw power, which is the faction's shape; if playtesting wants the price to buy
power instead, the lever is a sixth mount, not a price cut.

## 5. Validation note

Method: a scratch copy of the rules files was built in
~/workspace/voidsworn-wave5/battleship_scratch/ (data.js with exactly the three edits
above applied by anchored string replacement, each anchor matched exactly once;
core.js and battle.js copied verbatim). The scratch copy was loaded through the wave 1
harness loader (~/workspace/voidsworn-harness/game_loader.js) and exercised with the
game's own functions via ~/workspace/voidsworn-wave5/validate_battleship.js. No game
file was edited.

Results, all from the validation run:

- The data.js roster derivation loop priced the hull with no hand-tuning: cost0 370
  (the CP base), final cost 590, slots 3. No other Eclipse price moved: mote 100,
  flare 195, zenith 390 as today.
- derive() on a stock mk1 meridian: maxHp 250, shMax 0, armor .35, speed 2, turns 1,
  ev 0, hangar 0, hullRegen 6. Weapons resolve with Eclipse display names: Null cannon,
  Null cannon, Corona arc, Null spire, Null shredder.
- fleetPower for a one-ship fleet: meridian 6.00, zenith 4.00, Dominion 6.45.
- genEnemyFleet fielded it without help: d_meridian appeared in 193 of 300 seeded
  sector 3 elite Eclipse fleets.
- The full script (load, derivation, newShip, derive, fleetPower, 300 enemy fleet
  generations) completed with nothing thrown.

Known non-issue: d_boss shows cost undefined in the scratch load, exactly as in the
live load, because boss hulls sit outside the roster derivation loop. This entry does
not touch that path.
