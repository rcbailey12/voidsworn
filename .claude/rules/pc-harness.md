---
paths:
  - "tools/pc/**"
  - "docs/playbooks/pc.md"
  - "contrib/opus/tools/{pc_*,gpu_slots*,runner_*}.js"
---

Read the [PC playbook](../../docs/playbooks/pc.md) before changing or running the queue, watchdog, or job wrappers. RULEBOOK sections 3.2 to 3.4 and 3.12 cover shared PC and GPU limits.

## 3.5 to 3.7. PC harness

3.5 **Every PC queue job is wrapped in the tmo.bat watchdog, ends with exit /b, and carries no |, &, < or > in its
arguments.** Agent runs stop after STALL_MIN minutes without progress (default 30), or at a hard ceiling (default six
hours; CODEX_CAP and WORK_CAP override the ceiling in seconds). Progress is a changed file write time in the run repo,
a new commit, or new bytes in log.txt (also stderr for workhorse runs). Git housekeeping does not count. A stall or ceiling
stop writes its reason, changed files and last log lines to the out folder's resume.txt and the -partial commit message;
the next run reads that note. timeouts.log records STALLED after N min or CEILING. Short queue commands and runner checks
keep their explicit time limits. Why: hung Godot windows blocked the queue for about three hours (G-3), but the old two-hour
agent cap killed jobs that were still working (367 and 371). Ryan, Nov 15: "do we need to get rid of that random 2 hour rule
if it's timing out actual work?" He took up a stall check, a high backstop and a saved resume note (issue 818). Set: Board
(G-3), Ryan (issue 818). Ids: G-3, feel-06, skill-pb-05.

PC jobs never use Ryan's real game profile. The watchdog gives each Godot start a fresh profile so captures cannot overwrite his settings (issue 1228, Nov 19).

PC jobs run one tools copy and report honestly (issue 1194, Board, Nov 20). `lane_tools_refresh.ps1 -Build tools_live`
installs main's tools as a verified, never-edited version under `Downloads\voidsworn_test\tools_live\` with its own
hashes, named by `tools_live\current.txt`; every `tmo.bat` outside it hands its step to that copy, so an old `build\tools`
or branch checkout never runs its own watchdog or slot reader (self-tests set `TMO_OWN_COPY=1`). The main watcher refreshes
tools_live and `build\tools` between jobs. Old lane backups and old tools_live versions rotate instead of stopping the
refresh: a backup goes only when every file in it is kept in a newer copy or a saved main snapshot, a version only when it
was replaced over a day ago and no running process names it (the refresh's own rebuildable copies, 3.3). Job bats run
their steps through `tools/pc/job_wrap.bat`: a GPU label on every claim, the tool preflight before any clone or GPU claim
(exit 2 on a missing tool), the strict watchdog hash check, a stop on a failed step unless it is marked optional, non-empty
declared outputs, and `done PASS` or `done FAILED: <steps>` then `all done`, with a non-zero exit after any failure. Helper
(Opus) proof bats start from `tools/pc/jobs/opus_job_template.bat` and call `opus_job_head.bat` from tools_live: exact
commit pins in a fresh checkout per attempt, the safe ships copy with a tracked-file check, the throwaway profile and
Ryan's options hashed before and after; the Board checks only that a bat calls the head (docs/playbooks/pc.md, issue
1303, Board Nov 20: seven bats sent back on Nov 19 and 20 for the same four mistakes). The
watchers log each job's exit code and move a failed job to `queue\failed` (`queue_b\failed`). `PC_DOCTOR.bat` is a
read-only look at the GPU claims (owner, child, age, health), damaged slot files, stuck Godot or Blender processes and
failed jobs. Why: a stale Nov 18 `build\tools` copy ran the hung 1078 probe, jobs wrote "all done" after failed steps,
the watcher filed every job as done, and a missing ffmpeg or Pillow showed only after an hour on the GPU (Neon's PC
pipeline audit, checked by the Board, Nov 19).

3.6 **The Board may double-click .bat files on the PC itself by computer use, a few clicks at a time, releasing the lock at
once, never while Ryan is playing; it never drives the PC by remote clicks to unstick a job.** Why: "can't you use computer
use for all of this?" (R126); holding the lock hides his windows; Task Manager ignores remote clicks. Set: Ryan (R126); Board
(the limits). Ids: R126a, R126b, loop-16, skill-pb-06.

3.7 **Clone on the PC with `git -c core.autocrlf=false`.** Why: CRLF breaks the campaign table export. Set: Board. Id: loop-14.
