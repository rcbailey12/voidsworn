# IM5 engine check: issue 967

The painted IM5 export passes, and its export self-test passes all 33 cases, including
radius and half-radius position faults on all six open bells. Installing it remains a
separate GPU-lane step. No paint, geometry or installed assets changed here.

## Cause and fix

The old rim-plane tolerance was 0.012 of the whole ship's length. IM5's bell radius is
0.022475961 in the export frame, so the planted half-radius move is only 0.011237980.
That move stayed within the 0.011999999 plane tolerance: the original rim still covered
12 sectors, and the throat and clear-exhaust tests still passed. The unchanged checker
at base commit `38865952` accepts that moved point on every IM5 bell. This is unrelated to paint.

`check_export.py` now limits the rim-plane distance to the smaller of the existing
mesh tolerance and one quarter of that bell's radius: 0.005618990 on IM5. All six real
mouths retain 12 rim sectors; every moved point has zero. This only narrows the accepted
rim vertices. Radius bands, sector count, throat, exhaust and mesh-distance limits stay
the same, so this change cannot turn an old bell failure into a pass.

`check_export_selftest.py` refreshes its bell list with the current checker and plants
both existing faults on every eligible bell, retaining the original first-bell case
names. The position fault still moves half a radius; it now uses the same scene frame
as the checker, including parent transforms. The working instructions are updated in
[RECIPE.md](../../RECIPE.md).

## PC checks, November 17, 2026

All runs used scratch copies in TEMP. [Measured results and GLB hashes](engine_check_results.json)
identify the actual sources. Painted exports use the normal checks; the existing
unbaked Chorus exports use `unbaked=1`.

| Ship | Full export self-test | Cases | Bell fault cases |
|---|---|---:|---:|
| IM5 | PASS | 33 | 12 |
| H10 | PASS | 29 | 8 |
| Hullbreakers A16 | PASS | 26 | 6 |
| Hullbreakers A17 | PASS | 24 | 4 |
| Hullbreakers A18 | PASS | 24 | 4 |
| Hullbreakers A19 | PASS | 22 | 2 |
| Hullbreakers A20 | PASS | 20 | 0 |
| Eclipse E11 | PASS | 21 | 0 |
| Eclipse E12 | PASS | 21 | 0 |
| Eclipse E13 | PASS | 23 | 2 |
| Eclipse E14 | PASS | 21 | 2 |
| Chorus C10 | PASS | 20 | 0 |
| Chorus C11 | PASS | 18 | 0 |
| Sunward S8, legacy installed copy | BLOCKED by existing baseline | incomplete | 0 |

Total: 13 passing suites, 302 cases, 40 bell faults refused for the required reason.
Zero bell cases means no engine required the checker's off-mesh open-bell exception;
the other cases still ran. No existing fault was removed or made smaller.

Sunward's available `V1b_r_23` is the legacy A4 export, not the new S8 sheet export.
Both the original and changed checker refuse it: the original reports 48 problems,
including no authored interior/seams contract and missing weapon sockets. The full
self-test therefore fails its good-copy case and later stops at the absent socket.
The [S8 paint note](../voidsworn_S8/paint/README.md) still awaits its PC recipe run.
Direct `open_bell` checks on the legacy copy accept all three real bells and refuse
all three doubled-radius and all three half-radius position faults. This is partial
Sunward evidence, not a passing full export self-test. The requested all-ship full-suite
condition remains open until a valid S8 recipe export is available.

Additional checks passed: the tolerance regression at scales 0.001, 1 and 1000, and
half-radius displacement under rotated/scaled parents for both TRS and matrix nodes.
A stale empty bell record was also refreshed to all six IM5 bells.
Standing checks exited 0, including the 93-check Windows runner test and 44-check
stage-failure test. Only the recorded seven findings and twelve oracle differences
remain as baseline exceptions; no check was skipped.

Re-run with `python tools/recipe/check_export_selftest.py SHIP_JSON EXPORT_DIR`, adding
`unbaked=1` only for an unbaked export; standing checks use
`node contrib/opus/tools/run_all_checks.js`. No GPU, Blender or install was run.
