# R1: the rules fix batch (feel pass, Nov 1 2026)

Stream R1 of the feel pass. Rules only, so there are no screenshots here: what Ryan will notice is in the list below. The technical record (every function, every random draw that moved) is `contrib/opus/compute/port_notes.md`, step 13.

Commits on main: 53531b2 (browser rules and tests), c4c1431 (Godot port and the re-pin of both oracles), e3bff1e (Hullbreaker blurb), 222b492 (notes). Both oracles are pinned to e3bff1e.

## What changes in the game
- **The first sector never opens on the dead star.** It stays a set piece for sectors 2 and 3.
- **Protocol offers (boons):** one pool across your cores, the offering core three times as likely, every pick at that core's sync level, no useless or duplicate filler. When a core runs out you get a shorter offer plus 60 credits (once per reward). A duo and the core's legendary now compete for the special slot instead of the legendary always winning it. Reroll is greyed out when it could not change anything, so it never charges for nothing.
- **Nemesis:** losing a meeting still teaches you one weakness (or confirms the one you uncovered in the fight). He never adapts straight against a weakness you already know (no shields once you know he is weak to ion, no point defense once you know torpedoes work). An old save keeps everything he had built up.
- **Shipwright event:** the free repair goes to the next most damaged ship, as the text says.
- **Every map** has its elite before the rest stop.
- **Refits** only fit where they do something (no lance crystal on a ship without lances).
- **Events:** the raider den can be passed by for free. Faction "free order" rewards only unlock on the choice that earned them (selling the defector back no longer counts as being briefed). The Glasswrights can meet the Glasswright wanderer, so its special option finally appears.
- **Enemy veterans** brace when they are taking heavy fire and have nothing worth shooting, even when they had to move first.
- **Eclipse null sentries** are no longer a copy of ordinary flak: two heavier shots that reach one hex further.
- **Salvage (relics):** never offered when it could not do anything for your fleet (the coils with no abilities, the logbook when every captain is at top rank, the chalked roll for a single ship).
- **Text:** five ship variants now say which gun or ability they give up; the "Short supplies" Heat rule is now "Thin repair crews" and says it only halves free repairs; the decommission button shows the real payout; admiral mastery counts each battle once; the browser battle hint no longer says "nothing left to do" while a ship can still move or brace; the Hullbreaker blurb follows the void-hunter ruling (no fur, plainly alien).
- **Progression:** locked admirals have an unlock button and the Progression screen has a Legacy tab again (carriers, battleships, war chests and the rest). The rules side is in the Godot build; the buttons on the Godot screens still need the campaign UI owner (see below).
- **Crusade Nemesis** never gets the implant scar.

## Checks
- New test file `contrib/opus/tools/r1_tests.js`: 25 checks, all pass; all 25 fail on the code before this batch.
- Check pack 0 FAIL; unit tests b1 39, b3 17, b4 29, backlog 11, campaign start 6, all ok. Muse's findings suite 8 to 28 passing (EVT-1 and AI-1 are fixed but their tests assume a different shape; see the report). Softlock sweep, fleet invariants and save fuzz: 0 failures.
- Rules parity, Ryan's PC (lane B, 222b492): 48 of 48 battles, maths, random numbers, threat maps, threads: PASS. Worst enemy think 0.456 s (bar 0.5 s). Sweep seed 13: 200 of 200 identical (36,628 records). Cloud: 48 of 48.
- Campaign parity: 30 of 30 on the PC and in the cloud; Nemesis scenarios 78 of 78 records identical (14 new); save and story hook tests pass.

## Balance (bot sims, Ryan's PC, same seeds before and after)
| Mode | Before | After | Note |
|---|---|---|---|
| runsim 80 x 4 seeds (7105 to 7108), full-run wins | 18.4% (59 of 320) | 15.0% (48 of 320) | noise about 2 points; more runs reach sector 2 (62% to 68%) and 3 (31% to 34%), fewer win there |
| same, sector 3 flagship fights won | 83% of 71 | 73% of 66 | about 1.7 noise widths |
| fmatrix 48 per cell, seed 6201, all cells | 60.2% | 59.0% | without the veteran brace fix: 61.3% |
| fmatrix, Sunward Crusade row | 55.5% | 47.5% | the veteran brace fix accounts for it (55.8% without it) |
| bossmatrix 16, sector 1, admiral band | 55 to 90% | 56 to 84% | inside the 50 to 90% bar |
| fuzz 500 | 0 exceptions | 0 exceptions | |
Read: the veteran brace fix makes veteran enemies a little tougher, most of all against the Crusade fleet in the skirmish matrix. No tuning was done (Ryan's call, after he plays).

## Vetoable calls (technical, mine)
- Short offer: 60 credits on top of the one or two protocols shown, once per reward (the literal reading of "a short offer pays 60 credits"; Codex's patch only paid an empty offer).
- Null sentries: 2 shots of 4, range 3 (was a flak copy, 3 of 3, range 2).
- "Thin repair crews" as the new Heat name.
- Eclipse battleship price key 1.6 (the cruiser is 1.55).
- The loss debrief line: "Your analysts piece together the engagement. Weakness found: ...".
- The Glasswrights may now meet the seer (rather than removing its Glasswright option).
- No new golden battles (the count stays 48); the sweep covers the new shape rule.
