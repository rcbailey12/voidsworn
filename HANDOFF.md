# Voidsworn: handoff (Oct 25, 2026, afternoon)

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

- **Phase status** (top of the plan): A0, B0, A1 DONE. B1 waits only on Ryan's playtest. B2 items 1 to 3 built; PC checks running. A2 in progress. A3 to A5 and B3 to B5 not started.
- **Last recorded publish:** v53.8 (artifact Version 65, Oct 21). Nothing since is published; the playtest build is `index_test.html` from `build.py test`.
- **Barge (C19_51) v15:** shape and paint approved as steps (R13, R14); final sign-off with its effects in A5 (R16). Source of truth: `tools/blender/a1/barge_v15.py` plus `assets/ships/C19_51/`.
- **B1 (fix what can eat a win):** every listed fix in main with scripted checks (`contrib/opus/tools/b1_tests.js`, 39 ok), onboarding 1 to 5, enemy markers, and B-16 (AI hulls vanished on first damage) fixed. PC smoke passed.
- **B2 (faster, then bigger battles):** in main (1908387, f86f04a, 09f4439, c747220):
  - one PACE table (core.js) read by game and sim; enemy turns and follow-up shots faster; Enter or Space hurries an enemy turn;
  - the size ramp (battle.js RAMP): about 9 / 13 / 18 ships on board by sector (soft ceiling 10 / 14 / 20), leaner escorts, budgets scaled by the player's fleet power;
  - capture: add, strip or ransom on ONE batched prize screen with defaults (R23); ransom pays less with repeats; full fleet auto-scraps with a toast; flagships blocked;
  - sim `real` timing model (FINDINGS S8): 7.3 to 14.2 s per round at the new sizes (limit 15, target 12; sector 3 slightly over target).
  - **Running on the PC now** (job in `voidsworn_test\build`, outputs `b2_fuzz.txt`, `b2_boss.txt`, `b2_pace.txt`, tails in smoke_log.txt): `fuzz 2000`, `bossmatrix 32` (sector 1, escorts at 0.3), `pacecheck.py`. Read them, update FINDINGS F2, S5 and S6, then Ryan's playtest of B1 plus B2 is the exit.
- **A2 engine test** (contrib/opus/enginetest/; SPEC.md is the brief; scope trimmed by Ryan, R20; environment added, R21; Babylon moved to 9.30.0 for fairness, R22):
  - Babylon (8.20 build) ran on the PC: 6 ships 1.0 ms a frame at 4K, 24 ships 1.9 ms. Black squares on the real GPU fixed (NaN guards). Its builder is moving to 9.30, then max mode, 40 ships, physics, presentation, board slice, environment.
  - Godot 4.7.2 (v2) ran on the PC: 6 ships 2.2 ms at 4K, 24 ships 6.8 ms and 40 ships 14.4 ms (about 4 ms per frame unexplained, being profiled), max mode 5.2 ms but it loses hull albedo (bug). Its builder is fixing that list, then board, environment and the .exe.
  - Shared max-detail six ships (8K PBR, emissive, more geometry) plus env assets (dead-star sky, asteroids) are being built by a third helper (tools/blender/a2detail/, PC job tools/pc/jobs/a2_detail.bat).
  - Raw PC results: `contrib/opus/enginetest/results/run_2026-10-25/`. RESULTS.md and the blind reveal come after all three land. Hold pictures from Ryan until then (one combined blind reveal, R18).
- **Outside models:** Muse runs DeepSeek and Qwen from briefs in `contrib/opus/briefs/`. Done: engine choice and B2 syntheses (picked up, X13), Muse's audit of Opus (accepted, X15). Running: `muse_2026-10-25b_while_opus_paused.md` (A5 effects sheets, B3 admiral levers, port plan, FINDINGS follow-up pass).
- **Project skills** now exist in `.claude/skills/` (ship-kit, screenshot-verdict, playtest-and-balance). Use them.

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

None blocking. He weighs in next at:
- the B1 plus B2 playtest run (what to feel: quicker enemy turns, Enter or Space to hurry, bigger fleets with fragile escorts, the one-screen prize choice; plus the B1 list: reward-screen reloads, the retreat dialog, boarding a flagship, a full Corsair fleet, Standard AI on a fresh profile);
- the engine call (A3) after the blind reveal and RESULTS.md;
- visual sign-offs (plan section 9).

## 5. Next tasks

1. **B2 checks:** read the PC results (fuzz must show 0 exceptions; sector 1 boss matrix against the 50 to 90% band; pace check), update FINDINGS and the plan, sync c747220 (campaign_run.js, head.html) to the PC build, then ask Ryan for the playtest.
2. **A2:** run each helper's milestone on the PC as it lands (fresh staging folder per job; verify job.bat; separate run.request). When Babylon 9.30, Godot fixes and the max-detail assets are all in: run main, stress, 40 and max at 1440p and 4K for both, collect matching stills, write RESULTS.md (numbers, the Muse engine synthesis points, X12 Steam overlay, port cost), build the blind side-by-side (A and B labels), then A3 with Ryan.
3. **Muse returns:** check the four syntheses from the afternoon brief and fold them into A5, B3 and the A3 page; apply the follow-up registry edits.

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

**Oct 25 lessons:**
- Re-using a staged path with device_commit_files can write a stale earlier copy: stage every job from a fresh folder and compare `build\job.bat` byte for byte before sending run.request.
- `pkill -f <pattern>` or `pgrep -f` inside a Bash call matches that call's own command line and kills the shell (exit 144). Find node PIDs with `ps` and filter instead.
- Bigger B2 battles make `fuzz 2000` take about an hour on the PC.
- Effects that look fine in software rendering can show black squares on the real GPU (NaN); guard shaders (screenshot-verdict skill).

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
Read HANDOFF.md, then contrib/opus/go-forward-plan.md and contrib/opus/FINDINGS.md in github.com/rcbailey12/voidsworn (main). You own the approved plan: read the B2 PC check results and get Ryan's B1 plus B2 playtest, keep A2 moving (run each engine milestone on the PC, then RESULTS.md and the blind reveal for A3), and fold in Muse's afternoon syntheses.
```
