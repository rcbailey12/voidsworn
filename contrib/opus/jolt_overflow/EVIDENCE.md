# Issue 1279: Jolt job overflow on a capital's arrival

## The cause

Jolt runs its physics step as small jobs on Godot's shared worker lanes, and keeps every job in a fixed table (2048
slots) until a lane has run it. When every high-priority lane is held by long work, the step itself still finishes (the
main thread runs the jobs), but the table is not emptied, so after about a second it is full. Then Jolt logs "Jolt Physics
job system exceeded the maximum number of jobs" and the physics step waits on the main thread until a lane frees up.
On the PC, `tools/pc/run_timeout.ps1` stops Godot at that line, which is what ended 1232 RUN4's before s2 row.

Jolt makes these jobs only while some body moves. Measured headless here (Godot 4.7.2, 4 lanes, every lane held 2 s by
high-priority work, `body_kinds_probe.gd`, log `body_kinds_probe_log.txt`):

| bodies in the space | warning | physics frames in 6 s |
|---|---|---|
| none, static, still kinematic, frozen, asleep | no | 358 to 362 |
| moving kinematic (`AnimatableBody3D`, as the hull colliders) | **yes** | 215 (stalled) |
| a moving rigid body (earlier probe) | **yes** | 148 in 9 s |

In the game, every live ship gets a moving kinematic hull collider (`DEATH.add_collider`), and the fx warm-up left three
debris bodies drifting far below the board for the whole battle. So Jolt stepped from load to the end of every battle,
and any second of long high-priority work could fill its table:

- shader and pipeline compiles on a capital's arrival (the engine's own high-priority work; RUN4's before rows compile
  90 pipelines on arrival, the fix rows 132);
- since PR 1240, a death cut's side-by-side lanes: each cut took every lane but two, high priority, and two cuts at once
  (an arrival's precut beside another) took them all. The cut's own waiting task holds a third.

So the count was not too many bodies or too many jobs per step: it was jobs never being freed while the lanes were busy.

## The fix (`godot/fx/fx.gd`, `godot/fx/fx_death.gd`)

1. The battle's physics space steps only while a loose body is awake: a debris plate or a wreck piece that is not frozen
   and not asleep. Spawning debris, building wreck pieces and releasing a section wake it at once (`fx.wake_physics()`);
   a check four times a second puts it back to sleep. With it asleep Jolt makes no jobs at all, whatever holds the lanes.
   The hull colliders only matter to loose bodies, so nothing changes while one is awake. After warm-up, its three debris
   bodies (2000 units below the board, never seen) are stopped so they sleep until a death reuses them.
2. A death cut runs side by side one at a time, and leaves two lanes free beyond every lane low-priority work can hold
   (`DEATH.cut_lanes`). On 4 lanes that is 1 lane; on a 24 lane PC, 15 (a capital has fewer surfaces than that).

After main's issue 1237 (PR 1255, merged first), every debris plate is stopped and asleep by DEBRIS_REST_S (5.5 s), so
the space also sleeps a few seconds after an ordinary death, not only before the first one. The only cover gap left is
those seconds while debris or a wreck section still moves.

One visible difference, small: while the space sleeps, a ship's hull passing a resting plate no longer knocks it awake. A
moving wreck section is itself a loose awake body, so it keeps the space awake and still knocks plates (checked).

## Checks

- New headless check `godot/fx/test/jolt_jobs_check.gd` (in `godot/tools/ci/godot_checks.txt`): moving hull colliders
  alone leave the space asleep; 2 s of every lane held raises no warning; debris wakes it; settled debris sleeps it again;
  a moving wreck section keeps it awake and knocks a resting plate; the lane budget. `headless_check_with_control.txt` is the same check with `JOLT_JOBS_CONTROL=1`: the same 2 s starve with
  the space awake (the old behaviour) raises the warning on this machine.
- Run here, Godot 4.7.2 headless, all exit 0, no SCRIPT ERROR, no Jolt warning: load_all (263 scripts, 0 failed),
  jolt_jobs_check, cold_kill_check, death_leap_check, death_plane_check, multi_kill_pace_check, death_story_check,
  destruction_staging_check, fx_smoke, kill_slowmo_check.
- PC: `OPUS1279_RUN2.bat` (start with `q_opus1279_run2.bat`; run 1's bat had duplicate labels, Artoo on PR 1302, and is removed) runs the 1232 arrival bench five times on main 7ff4320f and five
  times on the fix, each in an empty profile, plus jolt_jobs_check on the PC's lane count. Not run yet.
- `before_main_d2717a32_s2_log_arrival.txt`: RUN4's original overflow log, from relay branch board/pc-out-1119y.
