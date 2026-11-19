# AI fixes, paired battles

Every setup stayed within 5 points of the baseline player win rate, and every median stayed unchanged. With all three fixes, player wins rose 4 points on Normal and 0.5 points on Veteran.

| Difficulty | Setup | Player wins | Median rounds | AI torpedo shots per battle | AI wings alive after 2 rounds | AI capital losses | Battles past round 12 |
|---|---|---:|---:|---:|---:|---:|---:|
| Normal | Baseline | 57.5% | 8 | 1.500 | 47.8% (175/366) | 50.3% | 4 |
| Normal | Ready weapons only | 59.0% | 8 | 1.495 | 47.7% (175/367) | 50.9% | 4 |
| Normal | Self-preservation only | 57.5% | 8 | 1.500 | 47.8% (175/366) | 50.3% | 4 |
| Normal | Launch after moving only | 60.5% | 8 | 1.545 | 47.1% (172/365) | 50.6% | 7 |
| Normal | All three | 61.5% | 8 | 1.565 | 47.2% (175/371) | 50.6% | 6 |
| Veteran | Baseline | 59.5% | 7 | 1.570 | 49.0% (173/353) | 49.1% | 2 |
| Veteran | Ready weapons only | 58.5% | 7 | 1.595 | 49.3% (173/351) | 48.8% | 2 |
| Veteran | Self-preservation only | 59.5% | 7 | 1.575 | 49.0% (173/353) | 49.1% | 3 |
| Veteran | Launch after moving only | 61.0% | 7 | 1.645 | 48.9% (174/356) | 50.6% | 2 |
| Veteran | All three | 60.0% | 7 | 1.670 | 47.6% (168/353) | 49.7% | 1 |

The ready-weapons change on its own produced one fewer torpedo shot across 200 Normal battles and five more across 200 Veteran battles. The longest battle with self-preservation alone stayed at 16 rounds on Normal and 14 on Veteran. Launch sequencing alone reached 22 rounds on Normal in one seed. The longest with all three was 15 on Normal and 13 on Veteran. Every fight resolved inside the 30-round sim limit.

With launch sequencing alone, launches into 5 or more expected damage fell from 56.3% to 40.8% on Normal and from 41.1% to 26.7% on Veteran. Two-round wing survival was flat to slightly lower, and self-preservation alone left capital and frigate loss rates unchanged.

The headless `sim3d.js` player bot ran the alternating battle loop for 200 battles per row, 2,000 total. Every row used seeds 1062001 through 1062200 and the same five sector 2 rout matchups, rotating once per seed. Baseline was `ba113cf0`, and each standalone run applied only the named change. The player fleets were Sunward against the Glasswrights (open belt, line), Sunward against Sunward (open storm, flank), Hegemony against the Hullbreakers (belt ring, line), the Hullbreakers against the Chorus (open storm, line), and Eclipse against Hegemony (belt lanes, ambush). All used the strip arena.

Wing survival counts AI replacements from their launch through the end of the second following round, or through battle end if sooner. Capital losses count destroyed or captured AI hulls of 4 CP or more, divided by the number fielded.
