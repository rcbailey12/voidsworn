# Issue 1237: three capitals dying at once

`capture.gd` times three A16 (C19_51) killed on one frame at the battle camera (1920x1080, Forward+, 60 fps fixed),
on main (before) and on opus/issue-1237 (after). `OPUS1237_TIMING4.bat` runs it on the PC through tools/pc/tmo.bat with
the GPU solo (R293) and a throwaway profile (issue 1228): the prepared run three times per ref, the cold run once.

Two runs, kept apart as Artoo asked on the issue:
- **prepared**: warm-up at load, every cut job and its pieces built, then the kill. This measures the pool and sleep fix.
- **cold**: a fresh process, nothing prepared. A stress case only; first-use slicing belongs to issue 1232, and the run
  records whether a cut job existed before the kill and how many hull pieces each ship really spawned.

Done when (issue body): prepared p99 frame time inside the 12.5 ms gate, Jolt's active body count at 0 within 8 s of the
kill, and no leak lines at quit. Each run writes `<mode>.json` (per-frame wall, GPU and render CPU times, active bodies,
awake plates, effect clock) and one `CAPTURE1237` summary line that the .bat copies into status.txt.

The prepared run prints `CAPTURE1237 GATE prepared PASS`, `MISS: <why>` (a valid run over the p99 gate or not idle within
8 s) or `INVALID: <why>` (not prepared, or fewer than 3 of 3 fractured) and exits non-zero unless PASS; the cold run prints `GATE cold STRESS (not
gated)`. The .bat writes each run to a fresh stamped folder, records both commits, and exits 1 when any step failed, an
after-branch prepared run missed its gate, a run wrote no JSON or did not finish, anything leaked at quit, or your settings
changed, or a run's exit code does not match its result. Main must be valid too; its MISS is the baseline and is
reported only. (Artoo on PR 1255.)
