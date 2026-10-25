# Brief for Muse: engine choice and battle-size checks (Oct 25, 2026)

From Opus (builder and owner of the go-forward plan). Ryan asked for outside models (DeepSeek, Qwen, others) to be used as workers, with Muse orchestrating and filing results in GitHub. Two jobs, independent of each other. Both are checks and research, not builds: nothing here edits game code.

## House rules
- Read first: `HANDOFF.md`, `contrib/opus/go-forward-plan.md` (phases A2, A3, B2), `contrib/opus/FINDINGS.md` (decisions R1 to R21), `contrib/opus/enginetest/SPEC.md`.
- Run each outside model blind: give it the job text and the facts below, not another model's answer. Then reconcile.
- Every claim about an engine's current features, prices, licences or platform support needs a primary source (official docs, release notes, the engine's own repository) with a link. If sources disagree, say so. Tag anything unsure as UNSURE.
- Claims about this repo must cite file:line. Repo claims from outside models get checked before they go in the synthesis (Gemini's record: 18 wrong of 70).
- Plain words, no em dashes.
- File raw returns in `contrib/deepseek/` and `contrib/qwen/` (and `contrib/<model>/` for others), the extracted working copies in their `reviews/`, and the synthesis in `contrib/muse/reviews/`. Do not edit anything under `contrib/opus/`, game code, or HANDOFF.md.
- Commit straight to main with a clear message. Opus picks the results up from there.

## Job 1: engine choice, Godot 4.7 or Babylon.js 8.20 (feeds the A3 weigh-in)

Context: Voidsworn is a PC-only (Windows, Steam-style release) 3D hex fleet-tactics roguelite, built today as one Babylon.js 8.20 web page. Ryan is not a coder; Claude builds everything. Opus is running a measured head-to-head on Ryan's PC (RTX 5080): the same six flagships, effects, physics, a hex-board slice and a standalone build in both engines (SPEC.md). The measured results and blind stills arrive separately. This job covers what the benchmark cannot show.

Facts about today's code (sizes in bytes, repo root): battle.js 131,980 (battle rules); core.js 35,854; data.js 57,094; campaign_run.js 45,992; campaign_meta.js 32,143; campaign3d.js 20,442; sim3d.js 95,792 (headless balance sim run in Node); ships3d.js 140,145; scene3d.js 101,841; fx3d.js 96,189; wfx3d.js 64,707; vfx3d.js 33,958; gfx3d.js 50,040; ui3d.js 114,406; sfx.js 52,712 plus sfx_data.js 482,216. The rules and sim (data, core, battle, campaign, sim3d) are plain JavaScript with no engine calls; the rest is Babylon-specific rendering, effects and UI.

Questions, each answered with sources and a short verdict:
1. **Porting cost.** If Godot wins, what is the realistic path for the rules and sim code: rewrite in GDScript or C#, or keep JavaScript running inside Godot (any maintained JS runtime for Godot 4.7?), or keep the headless sim in Node and port only the game? Estimate the work in rough units (files, lines) and name the risks (rule drift between sim and game).
2. **Shipping a PC game.** For each engine: Windows build route (Godot export; Babylon via Electron, Tauri, NW.js or a plain browser), install size, Steam integration (achievements, cloud saves, overlay) and the libraries for it, controller support, crash reporting, auto-update.
3. **Long-term risk.** Licence terms, release cadence and support for the exact versions, size and health of each community, breaking-change history, and what happens to WebGL2 versus WebGPU in Babylon.
4. **Tools for a non-coder plus an AI builder.** Which engine is easier for Claude to drive headless and test automatically (command-line runs, screenshots, scripted checks), and which is easier for Ryan to open and look at.
5. **Effects and presentation ceiling.** Particles, volumetrics, many dynamic lights, post-processing and physics as each engine offers them natively today; where each needs plugins or hand-written shaders.
6. **Your pick** with the two strongest reasons, and what would change it.

Deliverable: `contrib/muse/reviews/engine_choice_synthesis.md` (one page of verdicts up top, then the detail), with the per-model returns filed as above.

## Job 2: battle-size ramp and capture sanity check (feeds B2)

Context: plan phase B2 grows battles over a run toward about 10, 14 and 20 ships on the board by sector (R1: a guide, not a cap; Ryan's fleet stays small and elite, 4 to 7 ships), replaces an 8-ship enemy cap, and reworks capture after a win to add, strip (parts or modules) or ransom (credits), with a full fleet auto-scrapping and sector flagships never capturable (R4). An Opus helper is implementing and simulating it now; its numbers land in `contrib/opus/compute/` later.

Questions:
1. Design risks of letting enemy fleets outgrow the player's by 3 to 4 times in a turn-based hex game: tempo, focus fire, alpha strike, turn length, readability. What do comparable games do (cite them): Battlefleet Gothic Armada, BattleTech, Into the Breach, Hardspace or others you can source.
2. How should the ramp scale: ship count, ship quality, or both, and how should the difficulty settings shift it.
3. Capture economy: common pitfalls when prizes can be added, stripped or ransomed (snowballing, credit floods, decision fatigue after every battle), and simple guardrails.
4. Three to five concrete things to measure in the sim to catch those problems early.

Deliverable: `contrib/muse/reviews/b2_ramp_capture_synthesis.md`, same filing rules.

## Not wanted
- No game code edits, no new design docs that change decided rulings (FINDINGS R1 to R21 stand), no repo-state claims without file:line.
