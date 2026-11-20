# Issue 1237: three capitals dying at once

`capture.gd` times three A16 (C19_51) killed on one frame at the battle camera (1920x1080, Forward+, 60 fps fixed),
on main (before) and on opus/issue-1237 (after). `OPUS1237_TIMING.bat` runs it on the PC through tools/pc/tmo.bat with
the GPU solo (R293) and a throwaway profile (issue 1228): the prepared run three times per ref, the cold run once.

Two runs, kept apart as Artoo asked on the issue:
- **prepared**: warm-up at load, every cut job and its pieces built, then the kill. This measures the pool and sleep fix.
- **cold**: a fresh process, nothing prepared. A stress case only; first-use slicing belongs to issue 1232, and the run
  records whether a cut job existed before the kill and how many hull pieces each ship really spawned.

Done when (issue body): prepared p99 frame time inside the 12.5 ms gate, Jolt's active body count at 0 within 8 s of the
kill, and no leak lines at quit. Each run writes `<mode>.json` (per-frame wall, GPU and render CPU times, active bodies,
awake plates, effect clock) and one `CAPTURE1237` summary line that the .bat copies into status.txt.
