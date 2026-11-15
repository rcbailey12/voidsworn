# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 15, 2026, 20:35 UTC)

## 0. Status at Nov 15, 2026, 14:35 CST (20:35 UTC; read this first)

**What to trust.** docs/RULEBOOK.md for rules (0.10: only Ryan's quoted words make a rule; one-day Board choices are notes in
LOOP.md). contrib/opus/LOOP.md for status: "The seats", "Known traps" and the newest LATEST lines. The newest rulings are the
FINDINGS rows from R236 on (its last row is always the newest; this file names no range top, so a ruling landing on main never
makes it stale). The Nov 14 hand-over is in docs/archive/HANDOFF_0_2026-11-14.md; nothing under docs/archive/ is followed.

**The Board.** One Claude thread in the Project, Opus 5.5, Fable advisor on (R252). Seats: Opus workers build every Blender ship
and paint stack (sandbox bpy at /home/claude/bpy739, each in its own worktree /home/claude/w<issue>, about three at once, the
sandbox disk is tight); Codex is on the Pro plan (R264), local only, three lanes on the PC (R268): main (tools build_b, repo
board\repo, mirror repo-mirror.git; GPU jobs), lane B (build_c, board_b\repo, repo-mirror-b.git; Godot UI), lane C (build_d,
board_c\repo, repo-mirror-c.git; code-only). No Codex cloud: its model cannot be pinned (R268). DeepSeek takes code, mid-size
included; Kimi is gone (R257); Muse does design, checks and audits when Ryan starts it. Ryan's GPU go stands until he says
otherwise (gpu_go.txt, read back). Every PC write is read back before it is relied on (LOOP Known traps).

**The librarian trial.** Ryan's ChatGPT dot ran a first read-only sweep (Nov 15) and found real drift: RULEBOOK 2.6 Codex line,
2.14, 4.2 against R222, 6.11 against R246, factions.md lines, LOOP's waiting list, stale issue briefs. All fixed in PR 807
(merged) and the brief edits on 41, 372, 507. Board pick: the dot as the nightly read-only librarian, a script for mechanical
checks, Muse for audits; part of the issue 788 plan.

**Running now and just landed.** Live status is in contrib/opus/LOOP.md (the newest LATEST line) and on GitHub (open PRs, issue labels); this file no longer restates it, so it cannot go stale (the dot's librarian check of Nov 15 found PRs 804 and 810 described here as pending after both merged).

**Next in the queue.** Board: the issue 788 synthesis (legs: PR 801 Board, 790 Muse merged, PR 803 DeepSeek), then the one-page
plan for Ryan. Opus: 793 (squadron craft builds; R259), 783 (E13 paint even side to side; R256). PC runs by the Board: S8 recipe
(x1.85 paint), Hullbreaker paint after 688, Hegemony recipe, E13 and E14 recipe after 804; re-render the H10 and IM5 sheet
pictures; fix the UI audit's blank campaign captures. Muse (Ryan starts it): 794 fleet hybrid, Career, event screens; 256
checks. Note: the Board sandbox clone /home/claude/voidsworn has uncommitted edits to tools/pc runner files from the lane setup;
check them against main before discarding.

**Ryan's open picks.** The fleet screen (FL1 and FL2 hybrid, in Muse's chat). The 788 plan.
