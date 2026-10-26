# Voidsworn: handoff (Oct 25, 2026, night)

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

- **Phase status** (top of the plan): A0, B0, A1, A2 DONE. B1 and B2 wait only on Ryan's fuller playtest. A3 DECIDED with a proof running (R28). A4, A5 and B3 to B5 not started.
- **Last recorded publish:** v53.8 (artifact Version 65, Oct 21). Nothing since is published; the playtest build is `index_test.html` from `build.py test`, run on the PC with `voidsworn_test\play.bat` (opens Edge).
- **Barge (C19_51) v15:** shape and paint approved as steps (R13, R14); final sign-off with its effects in A5 (R16). Source of truth: `tools/blender/a1/barge_v15.py` plus `assets/ships/C19_51/`.
- **B1:** every listed fix in main with scripted checks (`contrib/opus/tools/b1_tests.js`, 39 ok). PC smoke passed.
- **B2:** built and PC-checked (contrib/opus/compute/b2/pc_checks_2026-10-25.txt): one PACE table, faster enemy turns, Enter or Space to hurry, the size ramp (about 9 / 13 / 18 ships by sector), capture on one batched prize screen (R23), admiral fixes in data.js (sector 1 boss spread 57 to 89%, inside the 50 to 90 band, S6 FIXED; 96 runs per admiral for admiral calls, S10). Ryan's first short playtest (2 encounters, in Edge): turns a bit quicker, bigger enemies fine, occasional hitches (B-17; `hitchprobe.py` is ready for a PC run, lower priority now that the game may move to Godot).
- **Slow-play fix:** Ryan's Chrome had fallen back to software rendering. play.bat now opens Edge, and the game shows a red banner when the browser is not using the graphics card (scene3d.js, 6dd31d4).
- **A2 engine test DONE:** `contrib/opus/enginetest/RESULTS.md` (numbers, blind reads, port cost). Blind page: https://claude.ai/artifact/LtFoz3Fyatn2bVGLSL9FjE (A = Babylon, B = Godot). Godot won lighting, detail and asteroids; Babylon won effects clearly; Godot's shield is not visible; Chorus and Deathless too dark in Godot; Ithar broken in both (asset).
- **A3 engine call (R28): Godot, after a short proof.** Two helpers are on it:
  - effects parity: the Godot builder (agent ad36c07a1a9f9cf41) rebuilds Babylon's breach, venting and smoke, explosions, trails, shield ripple and board laser in `contrib/opus/enginetest/godot/`, plus the dark-hull fix; then Opus runs the shots on the PC and shows Ryan side by side;
  - rules parity: the B2 helper (agent a373165be9bedd0f7) ports one seeded battle to GDScript in `contrib/opus/enginetest/godot_rules/` with an exact PRNG port and a per-turn state hash against the Node sim; `tools/pc/parity.bat` prints PASS or FAIL.
  - Both pass: the game moves to Godot (port plan: contrib/muse/reviews/engine_port_plan_synthesis.md; the Node sim stays the golden oracle; voidsworn-3d.html stays the fallback during the port). Either struggles: Babylon 9.30 stays.
- **Outside models:** Muse runs DeepSeek and Qwen from briefs in `contrib/opus/briefs/`. Done: engine choice and B2 syntheses (picked up, X13), Muse's audit of Opus (accepted, X15). Also done: `muse_2026-10-25b_while_opus_paused.md` (A5 effects sheets, B3 admiral levers, port plan, FINDINGS follow-up pass; registry edits applied).
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
- the proof results (side-by-side effects sheets plus parity PASS or FAIL), then the final switch;
- a fuller B1 plus B2 playtest when convenient (reward-screen reloads, the retreat dialog, boarding a flagship, a full Corsair fleet, the one-screen prize choice);
- visual sign-offs (plan section 9).

## 5. Next tasks

1. **A3 proof:** when each helper reports, run its job on the PC (fresh staging folder; verify job.bat; separate run.request; restart watcher.bat by computer control if needed). Build A/B sheets of the effects (reuse `contrib/opus/enginetest/blind/blind.py`; labels can be open now), run `parity.bat`, record the result in FINDINGS and the plan, then give Ryan the switch call.
2. **If Godot:** turn the port plan into plan phases (A4 then builds in Godot); K1 still comes before A4. **If Babylon:** move the game to 9.30 (X16) and fold the effects lessons into A5.
3. **Later:** B-17 hitch probe (only if Babylon stays), B3 notes (Hegemony boss 54%, Deathless 96%, Chorus 59% in the subset), fix the Ithar source mesh, A5 using Muse's effects sheets.

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

**Oct 25 night lessons:**
- The watcher window gets closed sometimes; if a job does not start in a minute, restart it by computer control (grants expire after 30 minutes idle: resolve_access, then request_access again).
- A slow game on Ryan's PC: check the WebGL renderer first (Claude in Chrome javascript_tool). "Microsoft Basic Render Driver" means software rendering.
- Depth of field in test stills made Ryan think the ship detail was blurry; keep it off except mild on hero shots.
- Messaging a finished helper by its agent id resumes it with its context.

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
Read HANDOFF.md, then contrib/opus/go-forward-plan.md and contrib/opus/FINDINGS.md in github.com/rcbailey12/voidsworn (main). You own the approved plan. The engine call is Godot after a short proof (R28): collect the effects-parity and rules-parity helper results, run both on Ryan's PC, show him side-by-side effects sheets and the parity PASS or FAIL, then plan the port or stay on Babylon 9.30.
```
