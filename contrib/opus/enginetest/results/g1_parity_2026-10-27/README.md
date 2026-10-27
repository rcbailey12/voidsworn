# G1 parity, Oct 27 2026

The Godot 4.7.2 rules port (`godot/rules/`) checked against the pinned JS oracle (`godot/rules/test/oracle/`). The PC logs are copied unchanged from `Downloads\voidsworn_test\queue_b\logs\`; only the line endings were changed.

## Cloud record at 61c57fa (oracle: battle.js and core.js at d8b47c6, data.js at 6b1571e)

| Check | Result |
|---|---|
| PRNG: 10,000 draws from each of seeds 1001, 7 and 4242424242 | 3 of 3 PASS |
| Maths: 316,090 inputs, including 26,030 sin and cos results above 2^19 pi | PASS, 0 differences |
| Seeded battles s1 to s43 (state hash and PRNG after every action) | 43 of 43 PASS |
| Threat overlay for s4, s19 and s23 | 3 of 3 PASS |
| Threads and the hard stop | PASS |
| 200-battle random sweep, seed 4 (35 Nemesis fights carrying the R42 and R49 fields, all six factions) | 200 of 200 identical, 33,500 records, 0 differ, 0 errors; endings: 130 wins, 59 losses, 11 with no result |

Notes:
- s32 and the thread test were killed by a SIGTERM from outside the run on the first full pass. Other streams run Godot in the same container. Both passed when run again on their own.
- The cloud think times on that pass were taken under load (several streams sharing 2 CPUs), so they are not a measure. The PC numbers below are the ones that count.

## PC lane B at 61c57fa (the record for stream B steps 4 and 5)

### g1_lb_parity_61c57fa (about 7.5 min)

| Check | Result |
|---|---|
| PRNG, 3 seeds | 3 of 3 PASS |
| Maths, 316,090 inputs (including big-argument sin and cos) | PASS |
| Seeded battles s1 to s43 | 43 of 43 PASS |
| Threat overlay for s4, s19 and s23 | 3 of 3 PASS |
| Threads and the hard stop | PASS (s4: 59 reads during enemy steps, s23: 96) |
| G3 campaign parity | 30 of 30 runs PASS |

Enemy think time per activation (report only; the bar is about 0.5 s). Every battle is inside the bar:

| Battle | Node avg / worst | Godot avg / worst | Godot worst round total |
|---|---|---|---|
| s4 (10 v 10) | 0.033 / 0.049 s | 0.118 / 0.310 s | 1.478 s |
| s5 (10 v 10) | 0.029 / 0.056 s | 0.087 / 0.261 s | 1.198 s |
| s23 (carrier-heavy 10 v 10) | 0.031 / 0.068 s | 0.075 / 0.406 s | 1.496 s |

### g1_lb_sweep_61c57fa

200-battle sweep, seed 4: 200 of 200 identical, 33,500 records, 0 differ; endings: 130 wins, 59 losses, 11 with no result. It took 13 min 21 s. These are the same battles and the same record count as the cloud run of seed 4.

## Later cloud checks (data.js only changes after 61c57fa)

- At 02f23da (stream B step 6, the arc hulls as sidegrades): s44 to s46 PASS. A 200-battle sweep, seed 5: 200 of 200 identical, 36,163 records.
- At 48638ef (s47, the compact field): full parity, 47 of 47 battles, maths, PRNG, threat maps and threads all PASS. Cloud worst think: s4 0.260 s, s5 0.290 s, s23 0.419 s. A 200-battle sweep, seed 6: 200 of 200, 37,913 records. A 300-battle sweep, seed 7: 300 of 300, 54,785 records.

## PC lane B at 2b91ea4 (oracle c7b1a78), run Oct 26 evening, filed here

### g1_lb_parity_1027e

| Check | Result |
|---|---|
| PRNG, 3 seeds | 3 of 3 PASS |
| Maths, 283,730 inputs | PASS |
| Seeded battles s1 to s34 | 34 of 34 PASS |
| Threat overlay for s4, s19 and s23 | 3 of 3 PASS |
| Threads and the hard stop | PASS (s4: 59 reads during enemy steps, s23: 95) |
| G3 campaign parity | 30 of 30 runs PASS |

Enemy think time per activation (report only; the bar is about 0.5 s):

| Battle | Node avg / worst | Godot avg / worst | Godot worst round total |
|---|---|---|---|
| s4 (10 v 10) | 0.034 / 0.067 s | 0.145 / **0.585 s** (round 2) | 2.309 s |
| s5 (10 v 10) | 0.032 / 0.070 s | 0.101 / 0.297 s | 1.341 s |
| s23 (carrier-heavy 10 v 10) | 0.030 / 0.066 s | 0.093 / 0.399 s | 1.618 s |

s4 missed the bar on this run. On 1027b it was 0.279 s. Node's own worst also rose by about half (0.046 to 0.067 s), which points to a busy PC more than to a change in the port.

### g1_lb_sweep_1027f

200-battle sweep, seed 3: 200 of 200 identical, 36,606 records, 0 differ; endings: 128 wins, 54 losses, 18 with no result. It took 17 min 28 s.

## Running sweep record

Seeds 1, 2, 3 and 4 on the PC, seed 4 again and seeds 5, 6 and 7 in the cloud: 1,500 different random battles, 273,265 records, 0 differences.
