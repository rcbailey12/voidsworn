# LOAD38 Board handoff

- Job `codex2085load38` (Refs #2085)
- Launcher `contrib/codex/issue-2085/CODEX2085_LOAD38.bat`
- Windows checkout SHA-256 `50EEF7C2D913FDC5A89CFB2E452418956B46BB17ECAE8081A908CEAC27337F07`. The raw Git file uses LF and hashes to `546A63271D5F20738A72057A23FE6AE888AA7E2E425DB75C68A83E419DE81DFD`.
- Candidate pin pending. Pass the runner's full, pushed `codex/issue-2085` commit as argument 1 after checks and review. The current checkout head `16422705af286bd66c2246e96f33ad641113b2f0` does not contain these uncommitted changes.
- Trace pins are built in. Main is `d96e3298fa564f5d7d683589205a439743f756a8`, PR 2053 alone is `b58fccee658347b4cec38fa6879e2dce77c912b5`, and COMBINED1 is `e1d7e568e52d3935ea3485bf26e1b82788136f7e`.

## What changed

- `fx_hull.gd`, `fx_ship.gd`, `fx.gd`, `static_caches.gd`, and `battle.gd` now reuse seed-free hull analysis across screens. The sliced load sets the altitude band before priming, so registration uses the same pose and key. The BVH, turret reach and fallback core and nozzle geometry are shared. Samples, live node and paint bindings, and effect state stay per ship. Quit clears the bounded cache.
- `stage_in.gd` and `world_living.gd` warm debris a material and vertex layout at a time with color and shadows in a private viewport. The main camera and light masks stay unchanged. Forward+ checks the drawing camera's layer mask for directional shadow casters too, so a shadow proxy excluded by that camera would not do the work. [Godot 4.7.2 renderer source](https://github.com/godotengine/godot/blob/ed1daf0bf/servers/rendering/renderer_scene_cull.cpp#L2958-L2968)
- `quick_watch.gd` runs the original quick battle check and publishes its last frame, battle phase, effect clock, shot number and draw marker once per second from a separate thread. The launcher records all three historical runs with `--verbose`, grades the candidate's cold and warm title under 500 ms, keeps the LOAD37 close and exit grades, and requires a candidate PASS and `09_end.png` with its sidecar.

## Evidence and limits

- COMBINED1 stopped logging after shot 08 in the windowed run. Both COMBINED1 and the working tree reached a round 6 win and exited cleanly headless with the same built hulls and seed. Headless skips image readback and the windowed renderer. The windowed hang cause is unresolved.
- A headless probe using built hulls from COMBINED1 and the new analyser reused the same BVH after recreating each of four ships. The repeat solve took 57 ms on C14s_23 and 43 ms on C16s_23, down from first solves of 307 ms and 289 ms after priming. These are analysis times, not title frame times.
- The headless cache probe passed new-root reuse, mesh and pose misses, different seeded samples, per-instance bindings, cache clearing, and separation of the warm viewport. Showcase, bake close, FX clock, broadside mounts, authored interiors, FX exit release, turret, and the GPU static ownership checks passed.
- A stubbed launcher run took all four pins, used solo mode for capture and timing, and failed the candidate when `09_end.png` was missing even though the game log said PASS. It did not start Godot.
- The local standing check run was not green. It reported failures in `godot_shard_tests`, `pc_jobs_1194_tests`, `picture_provenance_tests`, and `ship_job_tests` before the handoff. The sweep was still running its remaining fixtures.
- No GPU run was queued. The Board still needs the solo windowed runs to diagnose the hang and verify both title limits and the close grades. The candidate end-screen picture and provenance are expected under the job attempt's `out_new/quick_shots/`.
