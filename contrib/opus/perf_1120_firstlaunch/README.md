# Issue 1439: first-launch cost and graphics memory per stage (measurement, before any fix)

Evidence asked for by Astra items 3 and 6 (contrib/openai/astra_council_1120/report.md). Run 1 numbers below (MEASURE3, Nov 20 PC time, relay board/pc-out-1439b b8773fcd). The 24-ship kill stage reruns as MEASURE4.

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

## Run 1 results (RTX 5080, fresh profile: fullscreen 2560x1440, Max)

Ryan's screen is 2560x1440, so the fresh profile ran there, not at 4K. The ship line's Blender export and checks ran on
the CPU during cold_1 and cold_2, so their stall lengths may read a little high.

| | cold_1 | cold_2 |
|---|---:|---:|
| First drawn title, from engine start | 3.4 s | 2.9 s |
| First drawn title, from the bat's launch | 4.8 s | 5.9 s |
| Battle 1 playable (cover lifted), from engine start | 53.3 s | 51.2 s |

| Stage (cold_1) | Worst frame | Frames over 100 ms | Pipeline compiles | Godot VRAM peak | Windows dedicated peak |
|---|---:|---:|---:|---:|---:|
| title (13 s) | 6,251 ms | 5 | 320 | 1.7 GB | 1.8 GB |
| map (310 s) | 3,029 ms | 10 | 1,499 | 3.2 GB | 3.3 GB |
| load 1 | 1,946 ms | 13 | 350 | 3.0 GB | 3.1 GB |
| battle 1, first 10 s | 82 ms | 0 | 22 | 2.9 GB | 3.1 GB |
| battle 1 | 56 ms | 0 | 12 | 3.2 GB | 3.3 GB |
| load 2 | 2,028 ms | 7 | 379 | 3.1 GB | 3.3 GB |
| battle 2, first 10 s | 262 ms | 1 | 20 | 3.0 GB | 3.3 GB |
| battle 2 | 35 ms | 0 | 11 | 3.2 GB | 3.3 GB |

cold_2 matches cold_1 within a few percent (title worst 5,687 ms, map 2,869 ms, same compile counts), so the driver
cache was empty in both, as intended. Windows shared GPU memory stayed near 0.4 GB throughout.

battle24 (s25, run from the checkout): load 31.4 s with a worst frame of 6,153 ms and 505 compiles, then play at a 71 ms
worst frame with 0 compiles and 2.3 GB VRAM (2.5 GB Windows dedicated). It never ended in 955 s: s25 plays itself only
with --bot, which MEASURE3 did not pass. MEASURE4 reruns it with --bot for the kill stage.

**What is worth a fix (first read):**
1. **The title is where first launch hurts.** One stall of 5.7 to 6.3 s with 300+ pipeline compiles while the title is
   already on screen. That is the title showcase build plus its shader compiles (issue 1434 covers the build).
2. **The campaign map compiles 1,499 pipelines and stalls up to 3 s**, more than either battle. No issue covers it yet:
   the map's shaders are a new target.
3. **Battle loads are 8 to 9 s with about 350 compiles each, and Battle 2 compiles as many as Battle 1.** That fits
   Astra's point that world shaders are rebuilt each battle (shared sky Shader test in this issue's brief).
4. **Play itself is clean:** 12 to 22 compiles after the cover lifts, worst frames 35 to 82 ms. One 262 ms frame at the
   start of Battle 2 (its reinforcement arriving) is the only play hitch.
5. **Memory is not a problem on this card:** 3.3 GB peak dedicated of 16 GB. The map holds 3.2 GB and that does not drop
   in battle, which fits W1 (the hidden map stays alive, issue 1437). On an 8 GB card at 4K it is still an estimate.
