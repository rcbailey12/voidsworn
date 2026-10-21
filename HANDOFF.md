# Voidsworn: handoff (Oct 21, 2026)

## What and where
- Babylon.js 8.20 single-HTML hex fleet tactics roguelite. Ryan plays on a Pixel 10 XL and a PC (RTX 5080).
- Live game (one link only): https://claude.ai/artifact/QZ7pVvYuupUHFZkFGwxsaH (publish `voidsworn-3d.html` from `python3 build.py publish`; hull sidecars `hulls/`, `hulls_hi/` are uploaded as artifact files and kept on republish).
- Repo: github.com/rcbailey12/voidsworn (private). `master` is pushed to `main`. Workstream branches (both pushed to GitHub): `v53-I` (effects, merged and published as v53.6), `v53-E` (rock library + Ithar sail glass, 5cca697 (carbon lightened for phone, re-check on Pixel), master v53.6 merged in, sandbox-verified only). `v53-C` and `v53-G` are merged.
- Plan and queue: `NEXT.md`. History: `PROGRESS.md`. Code audit and asset grades: `AUDIT_v53H.md`. Reference checklists: `docs/skills/`.
- Master review doc (Claude Docs): https://claude.ai/code/artifact/aef64607-980c-49ce-977b-ff7b8a32868a

## Current state
- Live: **v53.5** (Oct 21, artifact Version 62): concept meshes for the carrier (V18_51), Corsair boss (C19_51), squadron craft (S1_51, S2_23, B23_51), station (O1_37), transport (O2_37) and beacon (O3_11); baked normal + AO/curvature maps on all 36 hulls (desktop `hulls_hi/`, phone `hulls/`); leftover-code cleanup; asteroid rebuild; perf work. Hull sidecars are uploaded artifact files (about 110 MB, published in 3 batches because one publish caps at 64 MB). `rocks/index.json` ships as a `{}` placeholder.
- Known issues: a small orange glow floats above some hulls (cathedral, h_vanguard, i_song); the Ithar sail is a flat grey sheet; Deathless lines are heavy; a few red/green bake errors in the normal maps; desktop CPU frame time went up (10 to 15 ms) while the phone got faster.
- Live since Version 63: **v53.6** effects pass (blue plasma bolt, thicker lasers, rail with green wake + accelerator rings, visible tracers, flat shock rings, game-feel tiers, reduce flash/shake toggles), merged to master.
- `v53-E`: 32-rock library (carbon, stone, crystal, ice) baked, being wired; Ithar sail material.
- Explosion sims (Mantaflow, `tools/blender/fxsim.py`) run on the PC but look blobby at 64 res; not usable yet.

## Decisions (Ryan decided)
- Full per-ship detail bake; desktop loads the sharp set, phone a lighter set. GPU jobs may run on the PC any time it is on. Blender installed (portable 4.5.14).
- After ships: effects, doubled down. Plasma must feel nothing like lasers; everything visceral and punchy.
- Blender for asteroids, wrecks/breakup pieces, nebula renders, explosion footage; live shaders for black-hole lensing, beams, shields, hex grid, engines.
- Concept picks round 11: V18_51, C19_51, S1_51, S2_23, B23_51, O1_37, O2_37, O3_11 (O3_51 meshed broken). When several options are good Ryan leans to `_51`.
- Recorded sound packs OK (Kenney CC0, Sonniss GDC 2026, royalty free).
- Engine: stay on Babylon; revisit Godot after v55 (parking lot in NEXT.md).
- Earlier: GitHub repo, doctrine pilot Ithar + Chorus, Hades-style legendaries, mid-battle reload replays the same fight, no content freezes, big swings, drops as they land.
- Process: ask 3-5 non-technical scope questions before anything big; run at most two subagents at once (four or five hit the usage limit twice).

## Suggested, not confirmed
- Adaptive music generated on the PC with an open music model (Ryan to pick a style).
- Rendering a CC0 VDB explosion set instead of raw sims.
- Sector 1 balance pass (Ryan won 4/4 in 3 rounds with 0 losses on v53.2).

## Open questions for Ryan
- Music style for the adaptive score.
- Whether he wants a Pixel check of v53.4 sound and status bars.

## Ryan's Pixel feedback on v53.5 (Oct 21, screenshots in `docs/feedback/2026-10-21/`)
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
1. Ryan's Pixel feedback above. Ask him 3-5 scope questions first (his saved preference), mainly about how far to push close-up detail. Fix the station first: it's a bug, not a quality question. Pass: Pixel close-ups of the station, the flagship and a hegemony hull look intact and crisp, and battle load has no visible hitch.
2. Get Ryan's Pixel verdict on v53.6 effects (live, artifact Version 63). Plasma, laser, rail and tracer were approved on PC fxshot round 3; open items are plasma sprite counts (about 440-600 alive per volley on desktop) and swapping in Blender-rendered flipbooks via `fxBookLoad(url, cols, rows)`.
3. Check `v53-E` on the PC, then merge and publish it as v53.7.
   - What it adds: the 32-rock library (desktop `rocks_hi/`, phone `rocks/`). It fails soft to procedural rocks until `index.json` lists the sets.
   - The Ithar sail is now jade glass.
   - PC checks:
     - `worldshot MODE=rocks` over several runs so carbon, stone, crystal and ice all come up, at desktop and 412x915;
     - `MODE=ithar` for the sail;
     - normal direction: if highlights come from the wrong side, flip `invertNormalMapX`/`Y` in `rockLibMat`;
     - whether the procedural-to-sculpted swap pops at battle start; if so, preload the rock set on the title screen.
   - Upload `rocks/` (9.8 MB) and `rocks_hi/` (27.6 MB) as artifact files, with each folder's `index.json` last.
   - Then hunt the floating orange glow (closeshot `PROBE=1 EXP=1`), the brown patches on the Ithar frigate's baked maps, and the desktop CPU regression.

## Gotchas
- PC test runner: `Downloads\voidsworn_test` with `watcher.bat` running. Commit files with device_commit_files, then commit `run.request` **in a separate, later call** (parallel write+commit raced twice and shipped stale files). `build\job.bat` runs once instead of the smoke test; a job must `cd` back to `build` or it re-runs. Scripts are in `tools/pc/`.
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
