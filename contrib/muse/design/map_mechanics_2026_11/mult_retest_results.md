# Retest: multiplicative scoring per controller (Nov 17, 2026, late)

Same retest discipline as the two-pass and falloff retests: per-controller split (bot seat only, veteran seat only, both), 24 paired seeds (1000-1023), mirror Hegemony, 34x24 belt rout, 1.25 whole numbers, per-side outcome metrics. Harness: the retest copy plus a two-line gate split (multP in the harness bot, multE in the veteran AI). 96 battles, zero timeouts.

## Replication check

The both-seats config reproduces the original matrix row almost exactly: coverage 0.17 (matrix 0.17), shot cluster 0.22 (0.22), rounds 11.0 (11.0), blended net displacement about 3.34 (3.34). The matrix result was real, not a sampling artefact. Base also reproduces (coverage 0.15, cluster 0.33, player wins 5/24).

## Per-controller results (medians; paired deltas vs base)

- Bot seat only (multP): coverage 0.16 (paired +0.010), cluster 0.25 (paired -0.066). The bot pays for it: wins 5/24 to 2/24 (flips +0/-3), its hull damage dealt falls (paired median -60), enemy hull remaining rises 209 to 321, and its mean firing range stretches 3.64 to 4.41. The response-curve scoring makes the simple bot pick safer, longer-range positions: shots spread because it fights from farther off, and it hits less hard.
- Veteran seat only (multE): coverage 0.16 (paired +0.013), cluster 0.27 (paired -0.043), rounds stretch 9.5 to 11.0. The veteran pays too: player wins rise to 13/24 (flips +9/-1), the player deals more damage (paired median +79.5), veteran survivors fall (alive 2.5 to 1.0) and veteran hull remaining falls 209 to 73. Longer, more spread battles that the veteran loses more often.
- Both seats (multBoth): coverage 0.17 (paired +0.019, the largest gain), cluster 0.22 (paired -0.088, the largest drop), rounds 11.0. Wins unchanged at 5/24 with symmetric paired flips (+4/-4). The per-seat taxes mostly cancel: paired damage deltas shrink to -10.5 (bot seat) and 0 (veteran seat) at the median. What remains as a real cost is pacing and per-round lethality: battles run about 1.5 rounds longer with slightly less total damage, so noticeably less damage per round. Bearing diversity is flat (2.36 vs 2.38): the spread is spatial, not geometric.

## Verdict

Multiplicative scoring survives the retest, with the same shape as the other two mechanics once they were measured per controller: the effect is real, each seat produces part of it, and a seat running it alone fights worse against a linear-scoring opponent. The difference from two-pass is what happens when both sides run it: two-pass stayed net-negative for the player seat (2/24), while multiplicative's taxes wash out in outcomes and its spread gains persist.

Adoption caveat the sim cannot settle: in the shipped game only the AI scores this way; the player seat here is a bot standing in for a human. The AI-only column (multE) is the closest picture of shipping it as-is, and there the AI takes more damage and loses more. Whether that trade (more spread, longer battles, softer AI) is good for the game is a design call about difficulty and feel, not a measurement. A human player's response to a more spread AI is also unmeasured.
