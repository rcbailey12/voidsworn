# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 24, 2026; status lines refreshed for issue 1506)

## 0. Status (section 0 checked Nov 24, 2026; read this first)

**What to trust.** docs/RULEBOOK.md for rules (0.10: only Ryan's quoted words make a rule; one-day Board choices are notes in
LOOP.md). contrib/opus/LOOP.md for status: "The seats", "Known traps" and the newest LATEST lines. The newest rulings are the
FINDINGS rows from R236 on (its last row is always the newest; this file names no range top, so a ruling landing on main never
makes it stale). The Nov 14 hand-over is in docs/archive/HANDOFF_0_2026-11-14.md; nothing under docs/archive/ is followed.

**The Board.** One Claude thread in the Claude Code Project, Opus 5.5 at high effort (no Fable advisor visible there, Nov 16).
Worker threads are started in the same Project: each gets a fresh cloud copy of the repo and the "voidsworn" cloud environment
(Godot 4.7.2 headless; Ryan selected it Nov 16), works one issue on its own branch and never merges (RULEBOOK 2.2). Opus builds
every Blender ship and paint stack (R205); not capped while Ryan's plan clears the backlog (Ryan, Nov 19; RULEBOOK 2.6), big new threads proposed to Ryan first. Codex is on the Pro
plan (R264), local only, six lanes on the PC (R268, R301, issue 2057): main (tools build_b, repo
board\repo, mirror repo-mirror.git; GPU jobs), lane B (build_c, board_b\repo, repo-mirror-b.git; Godot UI), lane C (build_d,
board_c\repo, repo-mirror-c.git; code-only), lane D (build_e, board_d\repo; code-only, R301), lanes E and F (build_f and build_g,
board_e and board_f, repo-mirror-e.git and repo-mirror-f.git; code-only, issue 2057, live Nov 25). No Codex cloud: its model cannot be pinned (R268). DeepSeek takes code, mid-size
included; Kimi is gone (R257); Muse does design, iteration and outside review only, never sound work; sound and anything important
goes to Neon (Ryan, Nov 19; Neon's own accounts R363, started by the Board through T3 Code on the PC, R428). GPU work is sized to the job and the
5080 (R293). Every PC write is read back before it is relied on (LOOP Known traps).

**Artoo.** Ryan's ChatGPT dot is an independent technical reviewer (R295, RULEBOOK 2.7): it comments by itself on PRs and
issues (general sweeps on issue 906), on merge issues, bugs and technical problems only, never design or taste, each comment
marked "Artoo (technical review):" and naming the commit it read. The Board checks each finding against live main and replies.

**Running now.** GitHub itself is the record of what is open and who has it (open issues and their labels; check it live
before dispatch, RULEBOOK 0.10). LOOP's newest LATEST line says what runs on the PC.

**Next in the queue.** Everything else queued or running is in LOOP's newest LATEST line and the open issues on GitHub.

**Ryan's open picks.** FL5 The Manifest and CR4 The Honours Board are settled as the fleet and Career directions (R285, R286;
builds 868, 869). Effects round 3 (815), the 368 storm look (717) and the shield hit (855) are closed.