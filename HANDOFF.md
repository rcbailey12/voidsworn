# Voidsworn: handoff (Oct 21, 2026, evening)

## What and where
- Babylon.js 8.20 single-HTML hex fleet tactics roguelite. Ryan plays on a Pixel 10 XL and a PC (RTX 5080).
- Live game (one link only): https://claude.ai/artifact/QZ7pVvYuupUHFZkFGwxsaH (publish `voidsworn-3d.html` from `python3 build.py publish`; hull sidecars `hulls/`, `hulls_hi/` are uploaded as artifact files and kept on republish).
- Repo: github.com/rcbailey12/voidsworn (private). `master` is pushed to `main`. Workstream branches (both pushed to GitHub): `v53-I` (effects, merged and published as v53.6), `v53-E` (rock library + Ithar sail glass, 5cca697 (carbon lightened for phone, re-check on Pixel), master v53.6 merged in, sandbox-verified only). `v53-C` and `v53-G` are merged.
- Plan and queue: `NEXT.md`. History: `PROGRESS.md`. Code audit and asset grades: `AUDIT_v53H.md`. Reference checklists: `docs/skills/`.
- Master review doc (Claude Docs): https://claude.ai/code/artifact/aef64607-980c-49ce-977b-ff7b8a32868a

## Current state
- Live: **v53.7** (artifact Version 64): concept station on every station map (the "broken station" was the old procedural spire), camera floor (biggest ship about half the screen), board overlays fade when close.
- Live since Version 65: **v53.8**: sculpted rock library (v53-E merged), "Entering battle" cover that holds until ships, this battle's hull maps, rocks and ship shaders are ready (4 s cap), map-screen prefetch, the 12 biggest hulls load the desktop mesh on phones, footprint-faded close-up plating. rocks/ and rocks_hi/ are uploaded artifact files. hulls/ is unchanged from v53.7. (Publishing warns the page references an undeclared `downloads` capability: the ?prof=1 CSV export, old debug code, left as is.)
- Ryan's verdict on v53.7 (Pixel and desktop screenshots, Oct 21): "everything still feels pretty low poly". Cause: the Hunyuan shapes themselves. Shape bake-off running (NEXT.md "Ship shapes"): A Hunyuan 512/640 and B Blender clean-up show no gain; D Blender hard-surface rebuild (tools/blender/hs/) is crisp in-game on first pass and is my pick; C TRELLIS.2 downloading to Downloads\trellis2 (approved by Ryan, 736 MB zip, then its own installer).
- **Ship shapes, new pipeline (Oct 21 evening):** the Pyre-Barge (C19_51) is done to kit v6 and is the worked example. Everything is
  written up for any agent in `docs/ship_pipeline/` (README = pipeline, BLOB_SWEEP = what "done" means, SHIP_QUEUE = all 36 hulls,
  concepts/ = every concept painting, c19_example/ = views and renders) plus `AGENTS.md` and `contrib/` (contained folders for outside
  agents such as Argon). Not published yet. Ryan's notes on it: bow, rocket rack and side guns fixed; the blob sweep rule came from his
  "ensure we catch all of those for all other ships".
- Known: box/T-shape wreck debris looks crude; the bright gold ring on Ryan's Pixel close-up (PC shots show it faded, re-check on v53.8).

## Decisions (Ryan decided)
- Full per-ship detail bake; desktop loads the sharp set, phone a lighter set. GPU jobs may run on the PC any time it is on. Blender installed (portable 4.5.14).
- After ships: effects, doubled down. Plasma must feel nothing like lasers; everything visceral and punchy.
- Blender for asteroids, wrecks/breakup pieces, nebula renders, explosion footage; live shaders for black-hole lensing, beams, shields, hex grid, engines.
- Concept picks round 11: V18_51, C19_51, S1_51, S2_23, B23_51, O1_37, O2_37, O3_11 (O3_51 meshed broken). When several options are good Ryan leans to `_51`.
- Recorded sound packs OK (Kenney CC0, Sonniss GDC 2026, royalty free).
- Engine: stay on Babylon; revisit Godot after v55 (parking lot in NEXT.md).
- Earlier: GitHub repo, doctrine pilot Ithar + Chorus, Hades-style legendaries, mid-battle reload replays the same fight, no content freezes, big swings, drops as they land.
- Process: ask 3-5 non-technical scope questions before anything big; run at most two subagents at once (four or five hit the usage limit twice).
- Oct 21: close-ups: surface first, then rebuild the worst shapes; camera stops a bit further out; load: a short loading moment is fine, no hitch once the battle shows; ship the bug fix first. Then (after "still low poly"): bake-off first, try TRELLIS.2, ship v53.8 while the shapes are worked on.

## Suggested, not confirmed
- Adaptive music generated on the PC with an open music model (Ryan to pick a style).
- Rendering a CC0 VDB explosion set instead of raw sims.
- Sector 1 balance pass (Ryan won 4/4 in 3 rounds with 0 losses on v53.2).

## Open questions for Ryan
- Music style for the adaptive score.
- Whether he wants a Pixel check of v53.4 sound and status bars.

## Ryan's Pixel feedback on v53.5 (Oct 21, screenshots in `docs/feedback/2026-10-21/`): addressed in v53.7 and v53.8, shapes moved to the bake-off
- **Station looks broken** (`pixel_station_broken.png`, objective station `obj|station` → O1_37). It shows a spire with loose slabs, red spikes and orange lights floating around it. Suspects: procedural station parts and lights that `applyAIHull` never disposes (it only removes meshes named `hull_*` or `*emblem`), points that `seatOnHull` failed to seat, or a bad mesh/alignment. Check with a PC closeshot of `obj|station`, `obj|transport` and `obj|beacon`.
- **Ships still don't look detailed when zoomed in** (`pixel_flagship_closeup.png`, `pixel_hull_melted.png`). The Hunyuan meshes read soft and "melted" at full zoom, and the phone loads the half-res maps. Options to put to Ryan:
  - give capitals sharper maps on the phone;
  - add a tiling detail normal (panel lines, greebles) in the hull shader;
  - remesh and sharpen in Blender;
  - regenerate at a higher Hunyuan octree resolution;
  - limit how far the camera can zoom in.
  Also at close zoom the hex highlight bands and the selection ring blow up and cover the view (yellow/green bands in the flagship shot), so overlays should fade when the camera is very close.
- **Lag on loading into a battle**: hull JSON + webp map fetch/decode, plus the effect atlas build (v53-I moves it to idle slices on the title screen). Measure with perfprobe. Ideas: prefetch the next battle's hulls on the map screen, compressed GPU textures (KTX2), decode off the main thread.

## Next 3 tasks
1. Audits are in (Codex, Rey, Gemini). Claude's verified synthesis and picks: docs/ship_pipeline/AUDIT_SYNTHESIS.md. Gemini's drop-in code
   is NOT merged (built on false premises). Owner to answer the scope questions from Oct 22 before the next build.
2. C19 verified fixes (list in AUDIT_SYNTHESIS.md), joint paint gain + no kit self-light, then the shared HullFx detail on hull and kit.
3. Loader bundle/fallback fixes, then a real-GPU (not SwiftShader) stress test on the PC and the Pixel before ship 2.

## Gotchas
- PC test runner: `Downloads\voidsworn_test` with `watcher.bat` running. Never write job.bat while a run is going (run_smoke deletes job.bat after it finishes). Hunyuan: C:\AI\HY3D2\Hunyuan3D2_WinPortable (python_standalone, cwd Hunyuan3D-2.1). PS 5.1 Invoke-WebRequest is slow for big files: set $ProgressPreference='SilentlyContinue'. Sandbox has Blender as a Python module (pip bpy 5.1.2) for scripted modelling and clay renders. Commit files with device_commit_files, then commit `run.request` **in a separate, later call** (parallel write+commit raced twice and shipped stale files). `build\job.bat` runs once instead of the smoke test; a job must `cd` back to `build` or it re-runs. Scripts are in `tools/pc/`.
- closeshot's local server needs a big backlog (request_queue_size 256): with the default 5, desktop runs dropped hull/kit files (ERR_CONNECTION_REFUSED) and shots silently lacked the kit.
- Full smoke on the PC takes about 4 min (25+ in the sandbox). Smoke does not catch invisible hulls: always add PC closeshot + console capture (`errprobe.py`).
- Transfers are capped at about 25 MB per file and 100 MB per call: split zips. Artifact publishes cap at 64 MB: split sidecar uploads across publishes (files left out are kept).
- `pcsync.sh <worktree>` stages sources for the PC; it now includes perf3d.js, wfx3d.js and fxshot.py.
- xatlas crashes inside Blender on Windows: prepare UVs in the sandbox (`tools/blender/uvprep.py`), then bake with `hullbake.py` (aligns automatically; ops `keep_main`, `tall`).
- download.blender.org blocks scripted downloads; the Berkeley mirror works.
- WebFetch needs URLs that came from a search or the user; Reddit is blocked in both browsers.
- Git commits: `-c user.name="Ryan Bailey" -c user.email="rcbailey12@gmail.com"`, with the Co-Authored-By and Claude-Session lines.

Starter line:
```
Read HANDOFF.md, NEXT.md and PROGRESS.md in github.com/rcbailey12/voidsworn, then pick up task 1 (Ryan's Pixel feedback on v53.5: broken station, close-up detail, battle load lag; screenshots in docs/feedback/2026-10-21). Ask your scope questions first, and keep the PC test runner flow.
```
