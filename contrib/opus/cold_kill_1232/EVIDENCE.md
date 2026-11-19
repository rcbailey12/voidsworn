# Issue 1232: the first capital kill of a session (evidence)

Fix commit, second pass after the Board read (cap and free cores) (branch opus/issue-1232, base main 280bb3a9). Stage: code, headless checks only; the PC timing run
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

## PC timing run (to come)

OPUS1232_RUN.bat: before (main 280bb3a9) and after (cb721036), three fresh sessions each, each with its own empty
profile (empty shader cache): arrival (warm-up at load, A16 arrives and dies 6 frames later) and cold (nothing warmed).
Reads: worst kill frame, pipelines compiled at arrival and at the kill, late hull shaders, outcome and pieces.
