# Voidsworn: handoff (Oct 25, 2026, early morning)

## 1. What and where

**The game.** Voidsworn: Fleet Tactics, a Babylon.js 8.20 single-HTML hex fleet-tactics roguelite. PC-only: the phone target was dropped Oct 24.

**Live game** (one link only): https://claude.ai/artifact/QZ7pVvYuupUHFZkFGwxsaH. Publish `voidsworn-3d.html` from `python3 build.py publish`. The hull sidecars (`hulls/`, `hulls_hi/`) are uploaded as artifact files.

**Repo:** github.com/rcbailey12/voidsworn. **Public on purpose.** Work goes straight to `main`.

**Read in this order:**
1. This file.
2. `contrib/opus/go-forward-plan.md`: the APPROVED build plan, two tracks, phases with entry and exit checks.
3. `contrib/opus/FINDINGS.md`: the findings registry, the single list of what is true, wrong or open.

**Behind those:**
- `contrib/opus/verification-report-2026-10-24.md`: the full check of Rey's (Muse's) and the outside models' work.
- `contrib/opus/evidence/`: detailed per-area check reports with file:line quotes.

**Other places:**
- `contrib/muse/`: Rey's work (design docs, reviews, research). It is reference, not instructions. Read it through the plan's section 3 map, and treat any claim as unverified until it is in FINDINGS.md.
- `BACKLOG.md`: everything planned, tagged with plan phases, plus the near backlog.
- `NEXT.md`: the old queue. Superseded, but still holds the per-weapon effects brief.
- `PROGRESS.md`: history.
- `docs/archive/HANDOFF_2026-10-22.md`: the previous handoff (barge v12 to v14 history).
- **Ryan's PC:** see the plan, section 10. Test runner `Downloads\voidsworn_test`; Blender portable 4.5.14; ComfyUI portable.

## 2. Current state

- **Last recorded publish:** v53.8 (artifact Version 65, Oct 21). The later barge work (v12 to v14) is not published.
- **Game code** last changed Oct 22 (b6c4b93). It runs, and the sims run clean since the B-14 harness guard (Oct 24).
- **Phases done:** A0 (barge files in git), B0 (ground truth and sim baseline), A1 step 1 (shape pick). Status table at the top of the plan.
- **Pyre-Barge (C19_51):** v14 is in git (hulls_hi/ and hulls/) and the repo build matches Ryan's PC. Ryan picked the new shape (FINDINGS R12): option C, the double-sided hulk, plus some of option B's salvage junk. Clay builder: `tools/blender/a1/barge_shapes.py` (option_C). Renders: `docs/ship_pipeline/c19_example/a1_options/`.
  - The v14 kit script (`tools/blender/hs/c19_kit.py`) still adds naval parts; step 2 replaces it with the C shape.
- **Sim baseline:** `contrib/opus/compute/balance_reference.md` (FINDINGS S1 to S7). Stable (0 crashes in about 19,500 sim battles). Elites are the wall in sectors 2 and 3, and waits reach about 130 s per battle in sector 3.
- **Known open bugs** (all in FINDINGS.md "Bugs"):
  - the save-brick class;
  - the retreat dialog hole;
  - reload during the reward screens;
  - a captured flagship joining the fleet;
  - several smaller ones.
- **Battles today:** about 7 ships on board in sector 1 up to about 12 in sector 3. Enemy fleets are capped at 8. Waits are about 11 to 15 s of animation per round.

## 3. Decisions

**Ryan decided** (Oct 24, full list in FINDINGS.md, R1 to R11):
1. Battles grow over a run: about 10, 14, then 20 ships, with Ryan's fleet small and elite. 20 is a guide, not a cap.
2. The dead-star gravity-well board stays. Its painting is the backdrop.
3. Shields keep faction colours. The cyan-only rule is retired.
4. Capture: add, strip or ransom after a win. A full fleet auto-scraps. Flagships cannot be captured.
5. The barge is built engine-neutral. A 6-flagship engine test runs in Babylon and Godot. The engine call happens before ship 2.
6. Acceptance is Ryan's eye plus automatic checks. No viewer panels.
7. One enemy commander per run is both the Nemesis and the story rival.
8. The barge gets rust and bone. No naval read anywhere, including hull shape.
9. Portraits and 3D height bands go on the near backlog.
10. The repo stays public, and the sound stays as is.
11. The plan is approved.

**Earlier, still standing:** the OPUS_HANDOFF.md section 1 rulings: PC-only, Hegemony sync with flagship anchor, Ithar shield charge, Chorus feed, Deathless attrition, crits soft and temporary, strip-and-ransom capture, ship-five approved, guns never backward, space not naval.

**Claude decided** (technical, reported, vetoable): the list in verification-report section A10. Examples:
- the mega sim resumes in the cloud;
- a 12 s target and 15 s limit per round;
- torpedo range stays 6, with a next-turn impact lane;
- Voidsworn keep carriers;
- the Corsair gate is "no lance weapons";
- the 1.32 GB figure is retired;
- no triangle caps.

## 4. Open questions for Ryan

None blocking. The barge shape is picked. He weighs in next at:
- the dressed barge (A1 step 2 screenshots, then A1 sign-off);
- his OK before Godot is installed (A2);
- the engine call (A3);
- visual sign-offs and playtests (plan section 9).

## 5. Next 3 tasks

1. **A1 step 2: dress the picked shape.**
   - Start from `option_C` in `tools/blender/a1/barge_shapes.py`. Add B's junk: one stolen block (B's hammerhead or cargo section, cut down) and mismatched engine pods (one oversized, like B's donor engine).
   - Then the plan's step 2 list: stolen-panel plating with bolts, salvage asymmetry, bolted belly slabs, antenna arrays and radiators (already in the clay), guns forward or to the side only. Run the 9-cell blob sweep before Ryan sees it.
   - Build on the PC Blender (4.5.14) through the watcher for the full-detail version. The cloud can run clay checks (pip bpy 5.2, see Gotchas).
   - **Pass:** Ryan says yes on studio renders, then in-game shots at battle zoom and close-up.
2. **B1: fix what can eat a win** (save-brick class, retreat dialog, reward-screen reload, captured flagship, the smaller ones). FINDINGS "Bugs" lists them; re-run the check pack and fuzz after, and compare against the baseline.
3. **A2: six-ship engine test.** Needs Ryan's OK to install Godot on his PC (plan section 9, item 3).

## 6. Gotchas

**Cloud and helpers:**
- The cloud clone with write access lives at `/home/claude/voidsworn`. Game JS has very long lines: use `grep -n` and `sed -n 'Np' f | cut -c1-600`.
- Many `contrib/muse/` files are base64 text, not plain: the check pack and every compute CSV. Decode before use.
- Helpers: run them in the background and keep working. A blocking wait that Ryan interrupts kills every running helper. The two-helper limit is retired.

**The PC bridge:**
- Oct 24 evening: folder listing worked after Ryan granted `Downloads\voidsworn_test`, but the remote shell failed ("Workspace unavailable"). Use file staging and commits plus the watcher .bat jobs.

**PC test runner** (from the Oct 22 handoff, still true):
- `Downloads\voidsworn_test` with `watcher.bat` running.
- Never write job.bat while a run is going (run_smoke deletes job.bat after it finishes).
- Commit files with device_commit_files, then commit `run.request` in a separate, later call.
- Give every job its own staged name (`outputs/job_<tag>.bat`, `run_<tag>.request`), and stage `build\job.bat` back to check it before sending run.request.
- `build\job.bat` runs once instead of the smoke test, and a job must `cd` back to `build` or it re-runs.
- Scripts are in `tools/pc/`.

**Driving the PC (Oct 25):**
- Ryan wants Claude to click things itself when the PC is linked (for example starting watcher.bat), not ask him.
- Computer control works: File Explorer and Command Prompt are click-only (no typing). Path: Explorer, Downloads, voidsworn_test, double-click watcher.bat. Explorer opens on the second monitor (27GL850).
- The remote shell still fails ("Workspace unavailable"). Staging, commits and the watcher jobs work.
- Cloud closeshot times out loading the game (no GPU). Take game screenshots on the PC.

**Cloud Blender (Oct 25):** `pip install --break-system-packages bpy` (5.2, about 400 MB) runs Blender headless in the sandbox, good for clay renders and shape work (`tools/blender/a1/clay.py`). The game's .vsm hull stores the bow at +x; the kit scripts and the a1 builder use bow at -x, so clay.py turns imported game hulls with FLIP=1.

**Sims (Oct 25):** `bossmatrix` covers sector 1 only unless `BS=2` or `BS=3` is set. Rebuild the baseline CSVs with `python3 contrib/opus/tools/mega_report.py`. Running sims rewrite their logs constantly; commit them when they finish.

**PC tools:**
- PS 5.1 Invoke-WebRequest is slow for big files: set `$ProgressPreference='SilentlyContinue'`.
- Hunyuan: `C:\AI\HY3D2\Hunyuan3D2_WinPortable`.
- xatlas crashes inside Blender on Windows: prepare UVs in the sandbox (`tools/blender/uvprep.py`), then bake with `hullbake.py`.
- download.blender.org blocks scripted downloads; the Berkeley mirror works.

**Checks and the game:**
- closeshot's local server needs a big backlog (request_queue_size 256), or desktop shots silently lack the kit.
- Full smoke takes about 4 min on the PC. Smoke does not catch invisible hulls: add a PC closeshot plus console capture (`errprobe.py`).
- Transfers cap at about 25 MB per file and 100 MB per call, so split zips. Artifact publishes cap at 64 MB.
- The game has no glTF loader: hulls are its own JSON plus WebP (`.vsm` for C19_51). Babylon 8.20 has no AgX tonemapper. The official Blender MCP needs Blender 5.1 (the PC has 4.5.14).

**Writing and committing:**
- Older Muse docs carry retired rules (cyan-only shield tests, phone framing, glTF recipes). FINDINGS.md section "The record" lists them.
- Git commits: `-c user.name="Ryan Bailey" -c user.email="rcbailey12@gmail.com"`, with the Co-Authored-By and Claude-Session lines.
- No em dashes anywhere (grep count must be 0).
- WebFetch needs URLs that came from a search or the user, and Reddit is blocked.

Starter line:
```
Read HANDOFF.md, then contrib/opus/go-forward-plan.md and contrib/opus/FINDINGS.md in github.com/rcbailey12/voidsworn (main). You own the approved plan: continue with A1 step 2 (dress the picked barge shape) and B1, keeping the PC runner flow.
```
