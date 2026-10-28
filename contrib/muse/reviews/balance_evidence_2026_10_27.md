# Balance evidence pack, Oct 27 program item 7

Chair-produced evidence pack (Rey). All runs executed in the Oct 27 program working clone at HEAD 68b42ce406286eb95ea7df6aaf3f683c1231b51d, the same pin as the wave 2 audit packs. Harness: node sim3d.js in the fresh clone, modes runsim, bossmatrix and matrix. Raw outputs are held in the program working folder (runsim_7101.txt through runsim_7108.txt, bossmatrix_s42.txt, matrix_s42.txt).

Purpose: settle three numbers the rollout audit could not verify from its pack. (1) The step 9 headline win rate of about 20 percent, which was measured on its own tuning seeds. (2) The G-13 admiral band claim of 53 to 85 percent. (3) The G-13 post-tuning faction spread claim of 9 points or less, where the only matrix in the rollout pack read 17.

## Harness verification

The VM reproduces the PC lane exactly. SEED=5, ADMS=grax, bossmatrix 4 at HEAD returns "85% r8.3", identical to the figure recorded in port_notes step 10 for the same configuration. The numbers below are therefore comparable to the numbers in Opus's own notes.

## Finding 1: the 20 percent win rate is a tuning-seed number; out of sample it reads about 17 percent

runsim 100 per seed. Reach columns are runs reaching sector 2, runs reaching sector 3, and runs won.

Tuning seeds (the seeds step 9 tuned on; both reproduce step 9's after-figures exactly):
- 7101: sector 2: 71, sector 3: 37, won 20.
- 7102: sector 2: 73, sector 3: 32, won 19.

Fresh seeds (never used for tuning):
- 7103: sector 2: 69, sector 3: 36, won 21. (Sector 2 battles won 83 percent, sector 2 boss 80 percent, sector 3 boss 88 percent.)
- 7104: sector 2: 57, sector 3: 28, won 11.
- 7105: sector 2: 68, sector 3: 30, won 18.
- 7106: sector 2: 65, sector 3: 36, won 20.
- 7107: sector 2: 73, sector 3: 31, won 13.
- 7108: sector 2: 70, sector 3: 36, won 17.

Pooled fresh seeds: 100 wins in 600 runs, 16.7 percent. Pooled all eight seeds: 139 in 800, 17.4 percent. Seed variance is wide (11 to 21 across the fresh set), so any single-seed headline overstates precision. Verdict: the tuning did not collapse out of sample, but the honest headline is about 17 percent, not about 20. OBSERVED.

## Finding 2: the admiral band claim holds

bossmatrix, SEED=42, 8 battles per admiral, player win rate against each admiral's boss fleet:

vex 68, malek 60, ashgrove 68, thale 80, kassar 83, vorn 80, reyes 85, maren 73, grax 75, sable 68, mott 65, vesh 70, matriarch 57, razormaw 78, mending 68, voice 85, aelith 75, vaelen 70, thorne 70, mirelle 70, nekhet 85, sekhmar 55, anuket 78, khepra 68.

Band: 55 (sekhmar) to 85 (reyes, voice, nekhet). The G-13 claimed band is 53 to 85. The measured band sits inside the claim. CONFIRMED.

By boss faction (player win rate against that faction's bosses): hegemony 56 (hardest), ithar 62, chorus 63, voidsworn 81, deathless 83, corsair 87 (easiest). Carrier fleets 72 percent, gun fleets 72 percent. OBSERVED. Note for the admirals audit: reyes (85) and voice (85) sit at the top of this band and sekhmar (55) at the bottom, which the admirals synthesis uses when screening the external legs' cost-band power calls.

## Finding 3: the faction spread claim does not hold; two matrix reads now show 17 and 23

matrix, SEED=42, 16 battles per pairing, bot vs bot. Rows are the player faction, columns the enemy faction (voidsworn, hegemony, corsair, chorus, ithar, deathless), values are player win percent.

- voidsworn: 94, 100, 100, 94, 100, 88. Average 96.
- hegemony: 94, 69, 100, 94, 100, 75. Average 89.
- corsair: 88, 69, 94, 88, 75, 88. Average 83.
- chorus: 75, 75, 100, 88, 94, 88. Average 86.
- ithar: 94, 69, 100, 81, 50, 44. Average 73.
- deathless: 88, 100, 94, 63, 100, 81. Average 88.

Faction average spread: 96 minus 73 = 23 points. The G-13 claim is a post-tuning spread of 9 points or less. This read does not support the claim, and it is the second matrix to say so (the rollout audit pack's matrix read 17). Verdict: the 9-point spread claim is NOT EVIDENCED and is contradicted by both available post-tuning matrices. OBSERVED.

Ithar is the outlier at the bottom (average 73). Its weak cells are deathless (44) and hegemony (69), while it beats corsair (100) and voidsworn (94) outright, so this reads as matchup-specific weakness rather than a uniformly weak kit. Voidsworn tops the table (96) with no losing cell. Sample caveat: 16 battles per cell is small (a single cell carries roughly plus or minus 12 points of noise), but the faction averages rest on 96 battles each, and the 23-point gap between top and bottom is well outside that noise. Bot-vs-bot play is not human play; the claim being tested was itself a bot-matrix claim, so the comparison is like for like.

## What this pack does not cover

Human playtesting (Ryan's return playthrough remains the sign-off), the Godot build's balance (these runs are the browser data layer at the pin, which the shared data file carries into Godot), and per-admiral campaign performance beyond the bossmatrix configuration above. The runsim harness plays a simplified economy; the economy evidence pack (item 8) covers what that simplification means, and the win rates here are comparable to step 9 precisely because step 9 used the same harness.

## Bottom line for Opus

Three claims checked against fresh measurement: the admiral band (53 to 85 claimed) is confirmed at 55 to 85; the win-rate headline (about 20 percent) is a tuning-seed figure and reads about 17 percent pooled out of sample; the faction spread (9 points or less claimed) is contradicted by both available matrices, 17 in the rollout pack and 23 here, with Ithar the low outlier on matchup-specific losses. No human-direction question arises from this pack; spread remediation, if any, is a tuning call in Opus's lane.
