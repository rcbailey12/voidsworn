# Voidsworn: handoff (Oct 21, 2026)

## What and where
- Babylon.js 8.20 single-HTML hex fleet tactics roguelite. Ryan plays on a Pixel 10 XL and a PC (RTX 5080).
- Live game (one link only): https://claude.ai/artifact/QZ7pVvYuupUHFZkFGwxsaH (publish `voidsworn-3d.html` from `python3 build.py publish`; hull sidecars `hulls/`, `hulls_hi/` are uploaded as artifact files and kept on republish).
- Repo: github.com/rcbailey12/voidsworn (private). `master` is pushed to `main`. Workstream branches: `v53-I` (effects, master merged in, under PC review), `v53-E` (rock library + Ithar sail). `v53-C` and `v53-G` are merged.
- Plan and queue: `NEXT.md`. History: `PROGRESS.md`. Code audit and asset grades: `AUDIT_v53H.md`. Reference checklists: `docs/skills/`.
- Master review doc (Claude Docs): https://claude.ai/code/artifact/aef64607-980c-49ce-977b-ff7b8a32868a

## Current state
- Live: **v53.5** (Oct 21, artifact Version 62): concept meshes for the carrier (V18_51), Corsair boss (C19_51), squadron craft (S1_51, S2_23, B23_51), station (O1_37), transport (O2_37) and beacon (O3_11); baked normal + AO/curvature maps on all 36 hulls (desktop `hulls_hi/`, phone `hulls/`); leftover-code cleanup; asteroid rebuild; perf work. Hull sidecars are uploaded artifact files (about 110 MB, published in 3 batches because one publish caps at 64 MB). `rocks/index.json` ships as a `{}` placeholder.
- Known issues: a small orange glow floats above some hulls (cathedral, h_vanguard, i_song); the Ithar sail is a flat grey sheet; Deathless lines are heavy; a few red/green bake errors in the normal maps; desktop CPU frame time went up (10 to 15 ms) while the phone got faster.
- `v53-I` effects pass (blue-white plasma bolt, thicker lasers, rail with green wake + accelerator rings, visible tracers, flat shock rings, game-feel tiers, reduce flash/shake toggles) is merged with master and under PC fxshot review.
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

## Next 3 tasks
1. Finish `v53-I` effects: review PC fxshot sheets (`python3 build.py && python3 fxshot.py`, board + close views), fix what reads wrong, full smoke, merge, publish v53.6. Pass: Ryan says plasma vs laser vs rail vs tracer feel distinct and punchy on the Pixel.
2. Merge `v53-E` (rock library + Ithar sail). Pass: PC worldshot/closeshot show cracked, strata'd rocks and a glassy sail; draws stay under ~500 desktop; upload `rocks/` + `rocks_hi/` as artifact files.
3. Hunt the floating orange glow (closeshot `PROBE=1 EXP=1`), then the desktop CPU regression.

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
Read HANDOFF.md, NEXT.md and PROGRESS.md in github.com/rcbailey12/voidsworn, then pick up task 1 (finish the v53-I effects pass from the PC fxshot review) and keep the PC test runner flow.
```
