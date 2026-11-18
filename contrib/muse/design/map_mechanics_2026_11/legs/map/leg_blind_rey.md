# Whole-map design round, blind Rey leg (written before any council leg or probe result)

## Diagnosis: three causes stack

1. Objective monoculture in practice. The game has 8 encounters (rout, ambush, defend, hunt, intercept, break, hold, flagship), but the campaign's first column is always rout and sector flagships roll only rout or ambush (battle.js rollEncounter, BOSS_ENC). The other six exist as garnish. A player mostly plays one battle: two fleets walk at each other until one breaks.
2. Convergent tactical logic. The bot scores movement by offense against the enemy mass, threat, and an objective term (botObj). Even when an objective exists, the fleets converge on the same ground because the objective is a single point and both sides want it. One point of value makes one blob of ships.
3. The map away from the fight has no persistent value. Terrain is cover on the way in, not territory. Nothing accrues for holding ground, nothing is lost by abandoning an edge, reserves exist in the code (treeOff, a reserve held off the field) but are a tree feature, not a battle system. So the outer map is scenery the fleets cross once.

The sweeps sharpen this: on the 38x26, neither doubled speed nor +50 percent range produced earlier contact or shorter battles, because the only thing either fleet wants is the other fleet. Deployment distance looked like the master lever only because it sets how long the walk is. The walk itself is the problem.

## The design principle

A map matters when value is distributed in space and time: more than one place worth being, worth being at different moments, so a fleet has to split, choose, or race. Speed matters when arrival order at distributed value decides outcomes. Range matters when holding distance is a defensible choice, not just a slower walk-in.

## Proposals, smallest first

1. Roll the existing encounters for real. Column 0 and bosses should draw from the full pool with weights, not rout by default. This is a data change, not a system, and it is the cheapest large win: six finished objectives are already built, described, and shaped (each encounter even carries its own shape list and arena weights in ENC_ARENA).
2. Split the point of value. Where an objective is a place (hold the relay, defend the station), field two sites at separated locations, either of which scores, or which score in sequence. One site makes a blob; two sites make a front. The relay objective already wants a ship beside it with no enemy there at the start of 3 rounds; a second relay turns that into a genuine allocation problem.
3. Make deployment a decision. Offer the player a deployment band choice (forward, standard, deep) and a lateral offset, with the enemy's choice hidden until reveal. Forward buys first contact and objective position at the price of being caught deployed; deep buys reaction room. This converts deployment distance from a fixed pacing constant into a priced choice, which is what Ryan actually objected to it being.
4. Reserves with a clock. Generalize the treeOff reserve: a player may hold ships off the field and commit them from a board edge on a round they choose; faster ships may enter from a wider set of edges or a round earlier. Speed then buys strategic timing, not just hexes per round, and edges of the map become live territory.
5. Ground that pays rent. A small number of terrain features (the station's battery already fires in defend) should give an ongoing effect to whoever holds their hexes: a sensor shoal that extends sight or targeting, a wreck field that repairs or rearms slowly. Holding must beat passing through, or nobody holds.
6. A standoff dividend for range. Facings and per-side shield coverage already reward maneuver. Add the missing half: a ship that fires at long band without having moved this round keeps its facing bonus or gains a small accuracy step, so a long-range hull has a reason to hold distance and a fast hull has a reason to close it. Range becomes a position to defend, speed the tool that attacks it.

## Refusals

- Bigger maps as a fix: disproven by the 1004 study; area without distributed value is dead space at any size.
- Global speed or range buffs as pacing fixes: measured weak (864 + 1,296 battles); they change the walk, not the reasons.
- Random battle events as a substitute for structure: the game has events; they spice a battle, they do not give its map a geography of value.
- Any proposal that needs the bot rewritten before it can be tested: the round's probes run on the shipped bot, and a design that only works under a smarter AI is a promise, not a design.

## What the probes should show if this diagnosis is right

Baseline rout battles on the big board should touch a small share of hexes (the smoke run showed 14 percent). Non-rout objectives should raise coverage only modestly under the current bot, because botObj pulls toward one site; if an objective like break or intercept (which force a crossing) shows much higher coverage, that is evidence that forced traversal, not scoring, is what spreads a battle today, and split-site objectives are the fix that generalizes it.
