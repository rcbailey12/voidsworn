# Enemy think time on the PC

Issue #1017. The worst Godot activation fell from **1.472 s to 0.399 s**,
inside the 0.5 s bar in all three A3 timing battles.

| A3 battle | Ship activations | Node average / worst | Godot before average / worst | Godot after average / worst |
| --- | ---: | ---: | ---: | ---: |
| s4 | 29 | 0.057 / 0.149 s | 0.413 / 1.472 s | 0.138 / 0.399 s |
| s5 | 59 | 0.041 / 0.118 s | 0.251 / 0.772 s | 0.121 / 0.342 s |
| s23 | 50 | 0.035 / 0.067 s | 0.211 / 0.981 s | 0.092 / 0.256 s |

Measured on the PC with Node 22.11.0 and headless Godot 4.7.2. The baseline
was commit `1b5861b5`. Each scenario ran in its own process using
`golden.js scenario` and `parity_main.gd -- scenario`. The same Node
records were used for the before and after runs of the
[A3 report](../../../godot/rules/test/node/timing.js). Godot still averaged
2.4 to 2.9 times Node's time. A3 subtracts snapshot time and excludes startup.
Node measures `aiUnit`. Godot measures the enemy API step, which can also
advance the round and plan squadron moves.

## Where the time went

CPU measurements from an instrumented copy of the baseline, rounded to the
nearest millisecond. The profile and the A3 table are separate runs.

| Battle, round, ship | Largest costs in the profile |
| --- | --- |
| s4, round 2, x028 | 836 ms scoring incoming fire and 105 ms scoring outgoing fire across 708 states. Reach took 58 ms and the distance field took 8 ms. |
| s5, round 2, x030 | 633 ms scoring incoming fire and 111 ms scoring outgoing fire across 373 states. Reach took 49 ms and other scoring took 93 ms. |
| s23, round 2, x029 | 525 ms planning 13 squadron moves during the round transition. The ship's own planning spent 219 ms on reach and 204 ms on incoming fire. |

The candidate loop repeatedly checked the same guns at the same hex.
Incoming aim and damage estimates now share results across equivalent
positions. Outgoing scoring prepares its in-range targets and sight lines
once per hex, then checks each candidate's facing. The search uses integer
coordinate keys and only builds paths for candidates it queues. Squadron
planning can skip a costlier route to a previously scored hex when the
available shots give the same score at every facing.

## Verification

The three A3 battles matched Node at every recorded action, activation and
round, including the state hash and PRNG state. The 1,244 Godot records were
also byte-identical before and after. The four-worker parity rerun measured
worst steps of 0.340 s in s4, 0.349 s in s5 and 0.350 s in s23.

Full Godot rules parity passed across all 281 battles, the three threat
maps and the thread and hard-stop checks. The saved results had zero changes.
The Godot-only safety check matched all six selected battles with caches
on and off, and passed its 15 ruled-number checks.

The standing suite recorded 64 passes and two known baseline results. Its
Windows runner self-test hit the 600 s limit in the suite and on an isolated
retry. Run directly, the self-test passed all 118 checks in 665.69 s.
