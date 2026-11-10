# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 9, 2026, 23:45 CST)

## 0. Status at Nov 9, 2026, 23:45 CST (Nov 10 05:45 UTC; read this first)

**Board:** the Board thread in the Claude Code Project owns the board and its merges (R119) and runs on Fable 5.2 (R152). Worker threads and helpers never merge their own PRs. LOOP.md holds the live state; FINDINGS.md holds every ruling (R152 to R161 are from Nov 9 and 10). Every PR gets a diff review plus the R129 impact sweep. Claude-built code gets the outside check on #256 (R132). Never write fix, fixes, close, closes, resolve or resolves followed by #N in a commit or PR text: it closes that issue. The PC token cannot push workflow files: such changes arrive as a patch the Board applies.

**Seats (AGENTS.md seat map):** DeepSeek V4 Flash in OpenCode on the PC is the coding workhorse (work217\tools\work_issue.bat, started by dropping a .bat into Downloads\voidsworn_test\queue). V4 Pro is the second try. Muse does text, research and outside checks (Rey chairs, blind Rey leg first). Opus 5.5 takes the hard and visual jobs. A thread made by the Board's scheduler has NO link to the PC (R160): PC-dependent work runs as a helper inside the Board thread, which has the PC folder, or the Board queues the job files itself. Two or three Claude contexts at once, the Board included.

**The outside audit is DONE (R154 to R161).** Three passes by fresh Fable 5.2 sessions with no project history, each checked by the Board line by line and attacked by the Muse council:
- Pass 1, code health: contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md (13 findings, 11 confirmed).
- Pass 2, graphics and effects: contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md with 43 captures in docs/shots/audit_2026_11/ (15 findings, 12 confirmed).
- Muse's attack on both: contrib/muse/reviews/audit_pass1_holes_2026_11.md (no finding fell; repairs and order changed; five misses).
- Pass 3, the job list: contrib/claude_fable/reviews/audit_pass3_issue_scoping_2026_11.md and audit_pass3_issues.json. 28 jobs filed as issues #350 to #377, each opening with the fixed block; section 5 of that file is the order and the lanes (tree jobs one at a time, one GPU job at a time).
- The three root causes the audit named, now standing rules for every job the Board writes: checks start from made-up state (so a fixture's state comes from the real functions, never typed by hand); missing things fall back quietly (so missing things must fail loudly); facts live in several hand-synced places (so every job names every copy it refreshes, until #360 removes the copies). For anything visual: the battle camera (r 170) first.
- Already repaired: tree skills picked in a real run reach the battle (PR #346); the oracle copies match and a hard check guards them (PR #346); the weapon bake scripts are back in the repo (PR #340).

**Running now (Nov 10 05:45 UTC), overnight, Ryan asleep (R160: the Board keeps independent work moving; the GPU is the Board's all night):**
- Tree skills (#305): job 7a (#347, the 26 waiting Glasswright and Crusade rows) on DeepSeek Flash. Then #360 (delete the oracle copies), job 7b (Eclipse and Chorus, 23 rows), #361 (tree table walk), mastery level effects, the balance pass, the Crusade voice wiring.
- Ships (#209): round 7, draft PR #341. The PC run baked and exported Ab7 (102,072 triangles; the export check and its self-test pass; 28 hard points; the game loads it). The battle capture failed on a script parse error; a helper is repairing it, building the sheets battle camera first and finishing the report. It merges only after the Board's look and Ryan's.
- UI rollout 1 (#344, R159): campaign map and between-battle pages in Lime Tactical, PR #349, a helper on Opus 5.5 with its own PC captures.
- Audit jobs released so far: #350 (placeholder hulls fail loudly) on DeepSeek Flash. Next open ones: #356, #357, #364, #374, #375 (workhorse), #355 (the Board sorts the known-failure list), #351 (the look bench, first GPU job after the ship sheets), #352 (Muse, the hit and death staging table), #359 (GitHub's checks open the game).
- Muse: #343, the findings ledger for Oct 28 to Nov 10; then #352.

**Waiting on Ryan:** his look at the round 7 ship sheets and the campaign map contact sheet; three audit questions (shield look at rest, planet from real NASA and USGS data which retires #140, three to five games whose hits and shields he likes); his read of the skill text page (artifact 250c3767); the S15 sound listen pass. Picks that come later on a sheet: the explosion route (#353), the nebula route (#368). No playtest build until the new UI and the first new hulls land.

The Oct 26 to Nov 7 history (sections 0a to 6 and the Nov 1 block, including "Gotchas" and "PC test runner") is in docs/archive/handoff_history_2026_11.md.
