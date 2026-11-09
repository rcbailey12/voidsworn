# Admiral tree effects: questions for Ryan (issue #305)

Five picks before the build starts. My pick is listed first in each. Plan: contrib/opus/plans/tree_effects_plan.md.

Today no tree skill does anything in a battle. Of the 216 skill texts, 145 can be built on the battle as it is, 22 more after a one-line wording fix, 10 need a brand new mechanic, and 39 describe something the game already does, so picking them would change nothing even once built.

## 1. The 49 skills that need a new mechanic or do nothing today

- **A (my pick). Rewrite them first, then build everything.** Muse rewrites the 39 do-nothing skills and turns the 10 big ones into simpler versions (for example "every ship fires at one target and its shields stop only the first hit" instead of a true combined strike). You get all 216 picks working, each one changing a fight. Cost: one Muse job and one read of the changed texts by you before the factions are built. Low risk.
- **B. Rewrite the do-nothing ones, but build the four "combined strike" capstones for real.** Those capstones (Vex, Saro, Kassar, Tamsa) land as one huge hit with one big number on screen, which should feel great. Adds one Opus thread and one or two review rounds. Medium risk: it changes how hits add up, so parity needs care.
- **C. Build all 10 big mechanics as written.** Includes stepping in during the enemy's move (Vell, Vesh, Reyes), formations and ship roles. Adds about two Opus threads, extra battle screen work in Godot, and three to five review rounds. Highest risk; the interrupt touches the turn flow.
- **D. Ship the 145 that work as written now and grey out the rest as "coming later".** Fastest to play, but some admirals would have half their tree locked.

## 2. Testing trees with the playtest switch

Today the playtest switch unlocks every admiral and hull, but not tree levels. You would need about 75 XP on an admiral for the first skill and 230 for a capstone.

- **A (my pick). The playtest switch also opens every tree skill and capstone.** You can try any build on any admiral from the first run. Turning the switch off brings back your earned levels and picks. Small job, folds into the pilot.
- **B. Keep earning them.** Truer to the final game, but you would grind before seeing a single skill.
- **C. A separate "Tree test" switch.** Same as A but you can test trees without also unlocking every admiral and hull. One extra setting on the menu.

## 3. Grax and boarding

Boarding is in the game (the Board order; Hullbreakers are the best boarders). The finished texts turned Grax's boarding skills into rams by mistake. Two of them cannot work as rams at all.

- **A (my pick). Move three skills to boarding, keep one ram.** Ram First, Ram Rush and Run of the Warlord become boarding skills (for example "a ship that ends its burn next to an enemy may board it even after firing"). The Maw Opens stays a ram (+30%). Grax plays as the warlord who crashes in and climbs aboard. No extra cost.
- **B. All four on boarding.** Grax becomes a pure boarding admiral. No extra cost.
- **C. Keep all four as rams.** Muse rewrites the two that cannot work as rams. Grax never touches boarding.

## 4. How visible a skill is in battle

- **A (my pick). Callout, log line and recap.** When a skill fires, its name and effect float over the ship in the faction colour ("Hard Light: section held"), a line goes in the battle log, and the after-battle screen lists each skill and how often it fired. Same look as boons today. Part of the pilot.
- **B. A, plus a small icon on each ship card when a skill is armed** (for example the ship that will get the next free shot). Clearer, more screen clutter, one more UI job and a screenshot round.
- **C. Log line and recap only.** Quiet battle screen, but easy to miss that a pick did anything.

## 5. Dace Vorn's Command name

His eight tree texts call his Command "Interdiction strike". The game shows "Reload and strike", but the Hegemony has no torpedoes, so "Reload" promises nothing.

- **A (my pick). Rename it Interdiction strike in the game.** Matches his tree and the design docs. One text change.
- **B. Keep "Reload and strike"** and Muse rewrites his eight texts to match.

## Ryan's answers (Nov 9 2026 07:08 CST, FINDINGS R145)

"Agree with picks on 3": all five are A. 1: Muse rewrites the 49 x and c texts onto existing effects, nothing is left as text. 2: the playtest switch opens every tree skill. 3: Grax, three skills back to boarding, one stays a ram. 4: callout over the ship, a log line and a count on the recap. 5: Vorn's Command becomes Interdiction strike.
