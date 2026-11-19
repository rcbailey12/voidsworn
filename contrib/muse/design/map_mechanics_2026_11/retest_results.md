# Retest results: two-pass per controller, paired falloff (Nov 17, 2026, late)

Run in answer to Artoo's review of the map and mechanics package (GO WITH CONDITIONS). Method upgrades over the original matrix: two-pass split by controller (bot seat only, veteran seat only, both), paired seeds throughout, and per-side outcome metrics (net and multi displacement per side, survivors, hull remaining, kills, hull damage dealt, mean firing range and close-range shot share per side). Kills include launched craft; survivors, hull and damage are capital hulls only. Harness: the frozen mechanics copy plus patch_retest.py. Zero timeouts in 288 battles.

## 1. Two-pass per controller (96 battles, mirror Hegemony, 34x24, 24 paired seeds)

Base reproduces the matrix: player-seat wins 5/24 (21%), blended net displacement about 3.09 (matrix 3.08).

- Bot seat only (tpP): that seat's net displacement 3.30 to 3.95 (+20%; paired per-seed delta median +0.68); the other seat unchanged (2.87). But the bot seat's wins fall 5/24 to 2/24 (paired flips +0/-3), its hull damage dealt falls 461 to 379 (medians), and enemy hull remaining rises 209 to 292. It moves more and fights worse.
- Veteran seat only (tpE): the veteran's net displacement 2.88 to 3.55 (+23%), multi displacement 3.62 to 4.67. The veteran pays the same tax: its damage dealt falls 598 to 570, the player keeps more hull (0 to 27.5 median) and wins rise to 13/24 (paired flips +9/-1 for the player).
- Both seats: both move more (3.88 and 3.62) and player wins fall to 2/24; the bot seat pays more than the veteran does.

Verdict: two-pass reliably buys displacement for whichever controller runs it, and reliably costs that controller damage and wins at the tested 10% combined-score budget. Artoo's patch reading explains why: the budget caps the drop in the combined score, so the max-displacement pick can spend offense and exposure freely inside it (the bot seat's mean firing range drifts 3.64 to 3.74). As implemented, two-pass fails the no-damage acceptance criterion from the synthesis. It is a movement lever with a real price, not a free win. Untested variants that could change the price: a tighter budget (3-5%), or a budget on offense alone with displacement as the tiebreak. Neither was run.

## 2. Paired falloff (192 battles, Hegemony vs Corsair at 16 CP each, both seatings, 48 paired seeds per config)

- Wins: Hegemony takes 66/96 under the shipped accuracy falloff and 63/96 under the damage band. Per seating: as player 31/48 to 30/48; as enemy 35/48 to 33/48. Paired flips are nearly symmetric (the band gains Hegemony 16 wins and loses 19 across both seatings). No reliable win effect; the first test's 33-to-29 drift was inside noise, as flagged at the time.
- Mechanism (the closing faction's own numbers, accuracy to band): Corsair close-range shot share 0.83 to 0.82 (Hegemony-player seating) and 0.73 to 0.76 (Corsair-player seating); Corsair mean firing range 2.50 to 2.49 and 2.98 to 2.74; Corsair hull damage dealt 467 to 463 and 439 to 417. The closing side does not deal more damage under the band in either seating; where it closes slightly more, it deals less.
- Why the mechanic barely engages: both fleets fight at mean range 2.5 to 3.0, at or inside most weapons' optimal range, where the two falloff forms are identical by construction. The band only differs past optimal, and this matchup rarely fights there.

Verdict: the damage-band falloff is not supported as a closing-faction lever at this tuning and matchup. Downgrade from promising to unsupported. A version that bites inside the ranges fleets actually use (taper starting around range 3) would be a different mechanic and a new test, not a continuation of this one.

## What this changes in the package's conclusions

- Two-pass: from "PASS, the clear winner" to "real movement gain at a measured combat price; adoption needs a budget redesign and a retest, or a deliberate decision that the feel is worth the price in bot hands (human players may spend the budget differently, which the sim cannot show)."
- Damage-band falloff: from "promising, direction matches intent" to "no reliable effect at double the sample with mechanism metrics; drop or redesign."
- Multiplicative scoring remains the only tested change that moved coverage and clustering without a measured combat tax, and it has not yet had its own per-controller or paired scrutiny.
