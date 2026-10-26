# G1 parity on Ryan's PC, Oct 26 2026

Godot 4.7.2 rules port (`godot/rules/`) against the pinned JS oracle (`godot/rules/test/oracle/`, battle.js, core.js, data.js at c7b1a78). Logs copied unchanged from `Downloads\voidsworn_test\queue*\logs\` (line endings only).

## g1_lb_parity_1027d (lane B, source 2d54b56, oracle c7b1a78), the G1 exit record

| Check | Result |
|---|---|
| PRNG, 10,000 draws from seeds 1001, 7, 4242424242 | 3 of 3 PASS |
| Maths (sin, cos, atan2, exp, hypot, round, pow), 283,730 inputs | PASS, 0 differences |
| Seeded battles s1 to s31, state hash and PRNG after every action | 31 of 31 PASS |
| Threat overlay (ui3d.js computeThreat) s4, s19, s23 | 3 of 3 PASS |
| 200-battle random sweep (seed 2) | 200 of 200 identical, 37,694 records, 0 differ, 0 errors; endings win 119, loss 65, none 16; 17 min 27 s |
| G3 campaign parity | did not run: the job copied parity.bat to build_b\ but not parity_campaign.bat (fixed in parity.bat: it now finds parity_campaign.bat in tools\pc\ too). G3's own lane B job g3_parity_4f71164 covers it. |

Enemy think per activation (report only, bar about 0.5 s):

| Battle | Node avg / worst | Godot avg / worst | Godot worst round total |
|---|---|---|---|
| s4 (10 v 10) | 0.029 / 0.046 s | 0.111 / 0.312 s | 1.618 s |
| s5 (10 v 10) | 0.030 / 0.055 s | 0.098 / 0.302 s | 1.204 s |
| s23 (carrier-heavy 10 v 10) | 0.033 / 0.084 s | 0.117 / **0.537 s** (round 1) | 1.695 s |

s23 misses the 0.5 s bar on this run (0.456 s in 1027b): G1 task 3 targets about 0.3 s.

## g1_parity_1027a (lane A, oracle c7b1a78, 25 scenarios at that time)

25 of 25 battles, PRNG, maths PASS; campaign 30 of 30 PASS; sweep seed 1: 200 of 200 identical, 36,604 records, 0 differ (win 124, loss 57, none 19), 14 min 46 s. The timing step failed on a path quoting bug (fixed in 2d9a70c).

## g1_timing_1027b

s4, s5, s23 PASS; Godot worst think 0.279, 0.291, 0.456 s.

## Combined sweep record

400 random battles over two seeds, 74,298 records, 0 differences, 0 errors.
