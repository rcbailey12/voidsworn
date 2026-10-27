# G1 parity, Oct 27 2026

The Godot 4.7.2 rules port (`godot/rules/`) checked against the pinned JS oracle (`godot/rules/test/oracle/`). The PC logs are copied unchanged from `Downloads\voidsworn_test\queue_b\logs\`; only the line endings were changed.

## Headline: bdb1a9d, PC lane B and cloud (Oct 27)

**Commit:** bdb1a9d. **Oracle:** `godot/rules/test/oracle/` battle.js, core.js and data.js are all byte-identical to the game's files at cb55ec9 (stream B steps 0 to 7b), which are also the files at the root of bdb1a9d. **Tables:** sha256 bd6677a8f04c003b, 131 exported, 90 read by the port.

| Check | PC lane B (`g1_lb_parity_bdb1a9d`, `g1_lb_sweep_bdb1a9d`) | Cloud |
|---|---|---|
| PRNG, 10,000 draws from each of 3 seeds | 3 of 3 PASS | 3 of 3 PASS |
| Maths, 316,090 inputs (26,030 of them big-argument sin and cos) | PASS, 0 differences | PASS, 0 differences |
| Golden battles s1 to s48, state hash and PRNG after every action (includes s44 to s48) | 48 of 48 PASS | 48 of 48 PASS |
| Threat overlay for s4, s19 and s23 | 3 of 3 PASS | 3 of 3 PASS |
| Threads and the hard stop | PASS | PASS |
| 200-battle random sweep, seed 9 | 200 of 200 identical, 38,235 records, 0 differ (17 min 55 s) | 200 of 200 identical, 38,235 records, 0 differ |
| G3 campaign parity (G3's own check, against G3's pinned JS at d8b47c6) | 30 of 30 PASS | not run |

PC enemy think time per activation (report only; the bar is about 0.5 s). All three are inside the bar: s4 0.108 s average / 0.301 s worst, s5 0.106 / 0.262 s, s23 0.099 / 0.469 s.

**What this does not cover (JS-only by design):**
- The battle tooltip and legend helpers: `factionTraitLines`, `cantFireReason`, `cmdNext`, `ramFrom` and `terrainPresent`, with their tables `TERRAIN_INFO`, `FAC_RULES`, `CMD_HOLD` and `WING_PERKS`. G2's battle scene writes its own text.
- The encounter rolls in battle.js: `pickRegion`, `regionMap`, `fitEncounter`, `rollEncounter` and `bossEncounter`, with `DEEP_MAPS`, `ENC_POOL`, `ENC_SPECIAL`, `FAC_REGION` and `REGIONS`. G3 ports these in `godot/campaign/campaign.gd` and checks them in its own campaign parity.
- `export_data.js` only checks that the tables the port reads exist. The 41 tables nothing in `godot/rules/` reads are listed in `godot/rules/test/README.md` (What it checks, item 1).
- G3's campaign check compares against G3's own pinned copy (d8b47c6). Campaign data changed after that (stream B steps 5 to 7b: admiral start fleets and bonuses, arc variant rows, Chorus regrowth), so it says nothing yet about the current data.

## PC lane B at f7789b1 (oracle cb55ec9), Oct 27

`g1_lb_parity_f7789b1`: 48 of 48 battles, PRNG, maths (316,090), threat maps, threads and hard stop all PASS; G3 campaign 30 of 30. Worst think: s4 0.313 s, s5 0.259 s, s23 0.403 s. `g1_lb_sweep_f7789b1`, seed 8: 200 of 200 identical, 35,596 records, 0 differ (the cloud run of seed 8 at f7789b1 gives the same 35,596 records). bdb1a9d differs from f7789b1 only in where the squadron leash constant is read from (same value).

# Earlier runs (each names its commit)

## Cloud at 61c57fa (oracle: battle.js and core.js at d8b47c6, data.js at 6b1571e)

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

## Sweep record (unique battles only)

Each seed makes a different set of 200 battles (300 for seed 7). A seed run twice (once on the PC and once in the cloud, at the same commit) is the same battles, so it is counted once.

| Seed | Commit (oracle) | Where | Battles | Records | Differences |
|---|---|---|---|---|---|
| 1 | lane A run 1027a, oracle c7b1a78 (the source commit was not recorded) | PC | 200 | 36,604 | 0 |
| 2 | 2d54b56 (oracle c7b1a78) | PC | 200 | 37,694 | 0 |
| 3 | 2b91ea4 (oracle c7b1a78) | PC | 200 | 36,606 | 0 |
| 4 | 61c57fa (oracle d8b47c6 and 6b1571e) | PC and cloud (same battles) | 200 | 33,500 | 0 |
| 5 | 02f23da (oracle 59f13a5) | cloud | 200 | 36,163 | 0 |
| 6 | 48638ef (oracle 59f13a5) | cloud | 200 | 37,913 | 0 |
| 7 | 48638ef (oracle 59f13a5) | cloud | 300 | 54,785 | 0 |
| 8 | f7789b1 (oracle cb55ec9) | PC and cloud (same battles) | 200 | 35,596 | 0 |
| 9 | bdb1a9d (oracle cb55ec9) | PC and cloud (same battles) | 200 | 38,235 | 0 |

Total: 1,900 unique battles, 347,096 records, 0 differences. Only seeds 8 and 9 ran against the current rules (cb55ec9): 400 battles, 73,831 records. The earlier seeds ran against older oracles, as named.
