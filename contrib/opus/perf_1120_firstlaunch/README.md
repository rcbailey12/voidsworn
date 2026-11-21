# Issue 1439: first-launch cost and graphics memory per stage (measurement, before any fix)

Evidence asked for by Astra items 3 and 6 (contrib/openai/astra_council_1120/report.md). Numbers land here after the PC run.

**How it is measured** (OPUS1439_MEASURE3.bat, GPU solo, on one pinned commit):
- `godot/bench/perf_1439.gd`, added by main for `--perf-1439 <folder>`, samples every frame: frame time, the five
  pipeline compile counters, Godot's video, texture and buffer memory, objects, labelled by stage (title, map, loadN,
  battleN_open for the first 10 s of play, battleN). It also logs the first drawn title frame and the moment each
  battle's cover lifts.
- cold_1 and cold_2: the release export of the pinned commit, each in a fresh throwaway profile (Godot's shader cache
  and the driver's cache start empty), with the fresh profile's own settings (fullscreen, Max), driven through title,
  map, Battle 1 and Battle 2 with the player path recorder's moves. Route seed 10 stops after Battle 2 on a missing
  route 2-2 (a known council finding); the summary says where it stopped.
- battle24: scenario s25 from the checkout (test scenarios are not exported), 24 ships that play themselves to the end.
- `gpu_mem_sampler.ps1` reads Windows' dedicated and shared GPU memory for the game process once a second;
  `summarize.ps1` writes one table per run (summary.txt).

Not covered: the next sector (the route ends in Sector I), other GPUs, and a warm second launch with the same profile.
