# Voidsworn: handoff (Oct 21, 2026)

## What and where
- Babylon.js 8.20 single-HTML hex fleet tactics roguelite. Ryan plays on a Pixel 10 XL and a PC (RTX 5080).
- Live game (one link only): https://claude.ai/artifact/QZ7pVvYuupUHFZkFGwxsaH (publish `voidsworn-3d.html` from `python3 build.py publish`; hull sidecars `hulls/`, `hulls_hi/` are uploaded as artifact files and kept on republish).
- Repo: github.com/rcbailey12/voidsworn (private). `master` is pushed to `main`. Workstream branches: `v53-C` (perf), `v53-E` (asteroids/Ithar), `v53-G` (ship close-ups).
- Plan and queue: `NEXT.md`. History: `PROGRESS.md`. Code audit and asset grades: `AUDIT_v53H.md`. Reference checklists: `docs/skills/`.
- Master review doc (Claude Docs): https://claude.ai/code/artifact/aef64607-980c-49ce-977b-ff7b8a32868a

## Current state
- Live: **v53.4** (board readability, correctness, smarter AI with enemy intent, status bars inside each ship's own hex, sound rebuild with Kenney CC0 + Sonniss GDC 2026 clips).
- `main` (unpublished): adds concept meshes for the Voidsworn carrier (V18_51), Corsair boss (C19_51), squadron craft (S1_51, S2_23, B23_51), station (O1_37), transport (O2_37), beacon (O3_11); leftover-code cleanup; asteroid rebuild; Ithar fly bow-first; close-up fixes.
- **Blocker:** on the real GPU every concept hull renders **pitch black** (HULLFX_AI shader path now applied after 40befb1), and a stray orange orb sits beside some ships. Smoke passes. Do not publish until PC close-ups look right.
- Baked but not yet wired: per-hull normal + AO/curvature maps for all 36 hulls (desktop 2K/1K/512, phone half) and a 32-rock asteroid library (carbon, stone, crystal, ice). Files: Ryan's PC `Downloads\voidsworn_test\bake`, `bake_lo`, `rocks\rocks_bake`, `rocks_bake_lo` (also uncommitted in the old session's worktrees, which won't survive). Re-zip from the PC if needed.
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

## Next 3 tasks
1. Fix black concept hulls + stray orb (ships3d `applyAIHull`, gfx3d `HullFxPlugin` AI path). Pass: PC closeshot of reliquary, c_boss, h_boss, b_razor, i_song, d_boss shows lit, detailed hulls, no orb, no console errors; full smoke passes. Then publish v53.5.
2. Wire the baked hull maps (JSON `u` UVs, `_n.webp` tangent normal OpenGL, `_m.webp` R=AO G=curvature) and the rock library. Pass: PC close-ups at ship-fills-frame zoom show panel detail with no seams; asteroids show cracks/strata; draws stay under ~500 desktop.
3. Effects pass (start after perf `v53-C` merges): per-weapon identity, game-feel tiers (trauma shake, real-time hit-stop, 5-8 stacked responses on big hits), reduce shake/flash toggles, explosions. Pass: Ryan says plasma vs laser vs rail feel distinct and punchy on the Pixel.

## Gotchas
- PC test runner: `Downloads\voidsworn_test` with `watcher.bat` running. Commit files with device_commit_files, then commit `run.request` **in a separate, later call** (parallel write+commit raced twice and shipped stale files). `build\job.bat` runs once instead of the smoke test; a job must `cd` back to `build` or it re-runs. Scripts are in `tools/pc/`.
- Full smoke on the PC takes about 4 min (25+ in the sandbox). Smoke does not catch invisible hulls: always add PC closeshot + console capture (`errprobe.py`).
- Transfers are capped at 30 MB per file: split zips.
- xatlas crashes inside Blender on Windows: prepare UVs in the sandbox (`tools/blender/uvprep.py`), then bake with `hullbake.py` (aligns automatically; ops `keep_main`, `tall`).
- download.blender.org blocks scripted downloads; the Berkeley mirror works.
- WebFetch needs URLs that came from a search or the user; Reddit is blocked in both browsers.
- Git commits: `-c user.name="Ryan Bailey" -c user.email="rcbailey12@gmail.com"`, with the Co-Authored-By and Claude-Session lines.

Starter line:
```
Read HANDOFF.md, NEXT.md and PROGRESS.md in github.com/rcbailey12/voidsworn, then pick up task 1 (black concept hulls on the PC) and keep the PC test runner flow.
```
