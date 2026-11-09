# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 9, 2026, 15:20 CST)

## 0. Status at Nov 9, 2026, 15:10 CST (read this first)

**Board:** the Board thread in the Claude Code Project owns the board and its merges (R119). Worker threads never merge their own PRs. LOOP.md holds the live state; FINDINGS.md holds every ruling (R133 to R151 are from Nov 8 and 9). Every PR gets a diff review plus the R129 impact sweep. Opus-built code gets Rey's outside check on #256 (R132). Threads are scheduled tasks; cloud-only unless the job needs the PC (Blender, captures). Never write fix, fixes, close, closes, resolve or resolves followed by #N in a commit: it closes that issue or PR (LOOP known traps). The auto_pr workflow appends "Closes #N" to every agent PR; change it to Refs on #256 PRs before merging.

**Seats (AGENTS.md seat map, R128):** DeepSeek V4 Flash in OpenCode on the PC is the coding workhorse (work217\tools\work_issue.bat, queued through Downloads\voidsworn_test\queue). V4 Pro is the second try and the GPU or effects seat (set WORK_MODEL=deepseek/deepseek-v4-pro; the repo runner is fixed in PR #320, the PC copy is swapped when no run is active). Muse does text, research and outside checks (Rey chairs). Opus threads take the hardest and most visual jobs. Since Nov 9 15:05 CST the Board thread runs on Fable 5.2 (R152): it owns the board, reviews and merges; Opus 5.5 stays on worker threads (ship rounds, screen builds, plans); Rey keeps the outside check on Opus code.

**Done Nov 9:**
- Progression Job 7 finished (PRs #298, #302, #304, #306).
- Tree skills in battle (#305): plan merged (PR #307), Ryan answered all five questions A (R145). Glasswrights (PR #313), Sunward Crusade (PR #317), Eclipse (PR #322), Chorus (PR #323) merged: 101 skills fire, checked by parity fixtures. Muse rewrote every skill that did nothing (PR #324, 74 rewrites, Grax boarding, Vorn's Interdiction strike, Eclipse shield-free, 144 mastery texts). Ryan has a phone page of the texts (artifact 250c3767).
- Battle screen redesign merged (PR #314): Glass Shell layout in the Lime Tactical identity (R145, R148, R149), Rey's conditions met, PC captures in Downloads\voidsworn_test\opus271b\out_final.
- Runner fixes: godot/.gitignore keeps PC-built ship assets and .uid files out (PR #310, R144); deepseekpro model id (PR #320).
- Muse: Crusade Nemesis voice (PR #328), outside checks of #248 to #314 (PRs #321, #326).

**Running now (Nov 9 21:10 UTC):**
- #329 Hullbreakers full tree on DeepSeek. Then one at a time: Hegemony full tree, the x rows of the first four factions with their final texts into data.js, mastery level effects, then a balance pass. Then wire the Crusade NEM_VOICE block (PR #328) into data.js.
- #281 gun smoke (PR #327, V4 Pro): baked Mantaflow flipbooks at 1.5x (Ryan: "definitely looks better"). Run 6 did not remove the stray puffs; the board found the cause (R153: braking thruster puffs drawn at the hull's bounding box corners, godot/fx/fx_ship.gd _rcs). Run 7 brief is on #281; PR #327 is on hold until its clips are clean. PR #309 (Flash runs) is shut when #327 merges.
- #209 ship round 6 (PC thread since 20:58 UTC): Ab5 (hull traced from the AI shape, 90.3 percent outline, R147, R150) gets Hullbreaker-kit weapons and concept paint, plus docs/ship_pipeline/RECIPE.md with one .bat per stage (R151: recipe first; a parts kit per faction with only plumbing shared, Hullbreakers a scavenged mix; weapons and paint before the game).

**Next, to propose to Ryan first (big):** roll Lime Tactical (contrib/opus/briefs/ui_style.md) out to the title, campaign map, end screen with the #92 debrief, and menus. After the ship recipe is proven: redo the concepts (Glasswrights and Eclipse first, R138) and run every ship through the recipe.

**Waiting on Ryan:** his read of the skill text page; adding Downloads\voidsworn_test to the new Board thread (it has no PC folder yet, so it cannot queue PC runs); ship round 6 sheets when they land. Older: #48 calls, #250 scope, S15 sound pass.

**Done Nov 8:** #223 stalls fix merged; #222 runner reviewed, guard fixed (#224); #217 trial closed (R127: #241 Heat gate merged); #201 checks applied to #120 to #122 (R120); Nov 6 audits triaged into jobs #227 to #238 (R121 to R125), records filed by Muse (#247, R130); movement spec (#251, R131); seat map (#244); Glasswright species design (#249; consistent visuals are #250); #246 Heat back-fill merged (PR #254, Flash); the R129 self-check list landed in the runner's task file (PR #253).

**Open now:** #120 merged (PR #248, Flash; R134 Flash beat V4 Pro and Kimi). Opus worker threads (scheduled tasks, R133): #231 UI spec (since 13:45 CST) and #121 Nemesis behaviour (since 14:24, branched from #120); no PRs yet. Muse #256 is the standing outside check on Opus code (R132): comment the PR number there and remove blocked. Next: #122, #230 (when a thread slot frees), #264 (campaign parity in CI), #221 (PC profiling). PC jobs start by dropping a .bat into Downloads\voidsworn_test\queue (LOOP Known traps).

**Waiting on Ryan:** #48 calls (design read, Brin's pronoun, close package question 2); #250 scope questions when it starts; S15 sound listen pass.

The Oct 26 to Nov 7 history (sections 0a to 6 and the Nov 1 block, including "Gotchas" and "PC test runner") is in docs/archive/handoff_history_2026_11.md.
