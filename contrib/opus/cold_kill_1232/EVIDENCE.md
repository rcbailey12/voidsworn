# Issue 1232: the first capital kill of a session (evidence)

Fix branch merged with main at d2717a32 (includes the fitted shield pass, PR 1241). PC run 2 pins the exact revisions in OPUS1232_RUN2.bat.
(OPUS1232_RUN.bat in this folder) is queued through the Board.

## What the first death built

From the 1077 PC rerun at 1236bbc3 (contrib/opus/flagship_death_1077/EVIDENCE.md on PR 1231) and the headless runs here:

| what | cost | who pays it |
|---|---|---|
| A16's break-up cut (worker) | 5.4 s on the PC, 2.6 to 3.8 s headless here | a capital killed less than that after its cut started pops with no pieces at 2.67 s |
| first draw of the death shaders | the 3.1 to 6.9 s CPU-side frame in 1077's cold rows (GPU under 2 ms) | only a process that never ran the battle warm-up (1077's cold bench); the same first kill after the warm-up worst frame 6 to 13 ms (1077 timing rows, first=true) |
| the death's main-thread gather of the hull arrays | 130 to 175 ms in the kill frame (1077 cold kill_call_ms) | a ship killed before its cut started |
| the tear overlay on the hull's own vertex format | not warmed (only on a box) | the first death per hull format (Neon death audit F8.1) |

A battle warms and cuts every ship under the loading cover (fx.prepare_battle_hulls, fx.warmup), so a player meets the
cold path when a ship arrives after the load (a reinforcement) and dies soon after: its cut waited 0.4 + 0.25 per ship
in the battle before it started, and its hull's death overlays were never drawn.

## The fix (shared death kit, every ship)

1. fx_death._cut: each surface and each piece's seal on its own worker, merged in surface order. Same pieces, checked by
   hash in fx/test/cold_kill_check.gd: one thread 3844 ms, side by side 1826 ms on this 4-core container.
2. fx_death._break_up_when_ready: with no earlier cut, the hull holds its tell until its own cut is done, for at most 5 s
   of real time from the death (Board on PR 1240: the kill camera and the turn wait for the core flash, so the cap bounds
   them; a capital's death is 2.67 s, so a late cut adds at most about 2.3 s). Past the cap, the old no-pieces pop.
   The side by side cut uses all cores but two, leaving the main and render threads theirs (Board on PR 1240).
3. fx.add_ship after the load: the cut starts 0.1 s after arrival (staggered only behind other waiting cuts), and
   fx.warm_arrival draws the new hull once, a thousandth of its size, with the tear overlay and its cuttable surfaces.
4. fx.warmup: the real tear (and the strain tear when on) on every hull's own format; the unused VOL, CHUNK, CRACKS and
   HULLIN shaders and fx_death._cracks deleted (F8.1). fx_breach.apply no longer builds two empty batches (F8.2).
   F8.4 waits for 1077, as the audit says.

## Headless checks (Godot 4.7.2.stable.official.ed1daf0bf, this container)

- fx/test/cold_kill_check.gd (new): same pieces (one thread 4040 ms, side by side on 2 of 4 cores 2196 ms); A16 arriving
  and killed 6 frames later (frames paced to 60 a second): kill frame 17.9 ms, fractured, 4 pieces, hidden at 2.07 s; a
  stuck cut held the death 5.07 s against the 5 s cap, then popped.
- fx/test/kill_slowmo_check.gd: a cut that lands 0.5 s past the deadline now keeps its pieces (new case); a stuck worker
  still pops after the real-time wait.
- Every fx/test headless line in godot_checks.txt passed (23 of 23), load_all 247 scripts 0 failed, death_seam_check 0
  failures (cut 1.9 s against 2.4 to 2.8 s before).

## PC timing run 4 (RTX 5080, solo GPU, Nov 20 01:50 UTC; files in the project folder pc/1232/out_1119y/1232_run4)

AFTER 98d470c4 (the fix merged with main), BEFORE d2717a32 (that main). Each row is a fresh process with an empty
throwaway profile (empty shader and shield caches); Ryan's real options were unchanged. Frames paced to 60 a second.

| row | outcome | pieces | kill frame (ms) | worst frame after the kill (ms) | pipelines built at the kill | late hull shaders | worst frame on arrival (ms) |
|---|---|---|---|---|---|---|---|
| after arrival s1 | fractured | 4 + 11 frags | 49.3 | 10.1 | 1 | 0 | 986 |
| after arrival s2 | fractured | 4 + 11 frags | 38.8 | 10.1 | 1 | 0 | 978 |
| after arrival s3 | fractured | 4 + 11 frags | 38.6 | 10.2 | 1 | 0 | 998 |
| before arrival s1 | no pieces (pop at 2.68 s) | 0 | 282.6 | 7.7 | 24 | 2 | 858 |
| before arrival s2 | Godot stopped: "FATAL Jolt Physics job system exceeded" at 22 s (exit 124) | - | - | - | - | - | - |
| before arrival s3 | no pieces (pop at 2.68 s) | 0 | 262.9 | 7.8 | 24 | 2 | 845 |
| after cold s1 to s3 | fractured | 4 + 11 frags | 135 to 142 | 4997 to 5120 | 97 | 7 | 236 to 254 |
| before cold s1 to s3 | fractured | 4 + 11 frags | 136 to 139 | 4934 to 5089 | 97 | 7 | 242 to 257 |

Read: the battle-like case (a ship arriving after the load and dying 6 frames later) now always breaks into pieces, its kill
frame fell from 263 to 283 ms to 39 to 49 ms, and the kill builds 1 pipeline instead of 24. About 130 ms moved to the
arrival frame (132 pipelines built there against 90): the arrival frame is about 1 s on both commits in an empty profile
(first sight of the hull, its shield skin and its materials), which is a separate cost from this issue. The cold rows
(never warmed at all, a bench-only path: every battle warms under the loading cover) are unchanged, as expected.
On the PC the cut is 3157 ms one thread, 1534 ms side by side, same pieces (cold_kill_check); a stuck cut held 5.07 s.
