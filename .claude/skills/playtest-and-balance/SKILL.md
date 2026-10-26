---
name: playtest-and-balance
description: Use after any Voidsworn rules, balance, pacing or content change (battle.js, core.js, data.js, campaign files, sim3d.js). Runs the check pack, the unit checks and the sims, compares against the balance baseline, and reports only the deltas with the mode that produced them. Also covers running heavy jobs on Ryan's PC.
---

# Playtest and balance

## Fast checks (cloud, every change)
1. `node contrib/opus/tools/checkpack/checks.js` (or `RUN_CHECKS.bat` on the PC): must stay 0 FAIL.
2. `node contrib/opus/tools/b1_tests.js`: all ok (save repair, reward chain, capture, retreat and more).
3. `python3 build.py test` builds; `grep -c` for em dashes is 0 in what you wrote.

## Sims (`node sim3d.js <mode>`)
- `campaign`: win rate, rounds, hull left, ships lost and waits per sector and kind. Use the `real` timing model for waits (FINDINGS S8); `PACE_OLD=1` re-measures the old pace.
- `bossmatrix N` (sector 1 unless `BS=2` or `BS=3`), `archmatrix`, `fmatrix`, `matrix`, `shipcount`, `fuzz N` (crash test; must show 0 exceptions).
- Long runs crawl in the cloud when helpers share the machine: run `fuzz 2000` and big matrices on the PC (below).
- Baseline: `contrib/opus/compute/balance_reference.md` and its CSVs (rebuild CSVs with `python3 contrib/opus/tools/mega_report.py`).

## Report
Only deltas against the baseline, in a table: cell, before, after, the mode and sample size. Flag exit criteria: no admiral below 50% or above 90% against a sector 1 flagship; waits under 15 s per round (target 12); no crashes. Update FINDINGS rows (evidence, status) and the plan's phase status. Rules and outcomes must not change when only presentation time changes.

## Playtest
Ryan's own run is the exit for B1 and B2. Give him a short list of what to feel for, and record what he says in FINDINGS.

## PC runner (heavy jobs)
- **Job queue (Oct 26, preferred):** drop a uniquely named job file into `Downloads\voidsworn_test\queue\` (for example `g1_parity_0426.bat`). The watcher runs queued jobs one at a time, oldest first, from `build\`; output lands in `queue\logs\<name>.log` and the file moves to `queue\done\`. Jobs must end with `exit /b` (never plain `exit`) and must not touch `build\job.bat`. Copy any files the job needs first, from a fresh staging folder. Several helpers can queue jobs safely; never edit a job after it is queued.
- **Lane B (Oct 26):** a second watcher ("VS job queue B", `watcher_b.bat`) runs `queue_b\*.bat` from its own folder `build_b\`, in parallel with lane A. Use lane B ONLY for CPU-only work that does not touch `build\` or the GPU: downloads, parity checks, headless bot runs, sims. Lane B jobs must unpack their own copy of what they need into `build_b\` (never run from or write into `build\`), use `..\node\node.exe` and `..\godot_path.txt`, and call `tools\pc\tmo.bat` (present in `build_b\tools\pc\`). Logs in `queue_b\logs\`. Lane A (`queue\`) stays for GPU and anything that needs `build\` (renders, shots, Blender, ComfyUI, exports). Lane B starts after the current lane A job (it was launched through run.request); autostart only starts lane A.
- **Watchdog (Oct 26, required):** wrap every program launch in a queue job as `call tools\pc\tmo.bat <seconds> <exe> [args ...]` from build\ (kills the process tree on overrun, exit 124, logged to queue\logs\timeouts.log). A hung Godot without it blocked the queue for hours on Oct 26. Never drive the PC by computer control to unstick jobs: Task Manager runs elevated and ignores remote clicks, and opening a portable Godot exe starts a new instance.
- The running watcher is `watcher_q.bat` (window title "VS job queue"); `watcher.bat` is the same script and is what autostart launches. Never edit a watcher script while it runs (cmd reads it line by line).
- `Downloads\voidsworn_test` with `watcher.bat` running (if it is not, start it with computer control: Explorer, Downloads, voidsworn_test, double-click watcher.bat).
- Copy changed game files into `voidsworn_test\build\` with device_commit_files. Write the job as `build\job.bat` (CRLF, written by Python; it runs once from `build\`, logs to `..\smoke_log.txt`; `PYEXE` comes from python_path.txt; node is `voidsworn_test\node\node.exe`).
- Never write job.bat while a run is going. Stage every file from a fresh staging folder (re-using a staged path can commit a stale copy), stage `build\job.bat` back and compare byte for byte, then send `run.request` in a separate, later call.
- Read results by staging `smoke_log.txt` and the output files back.
