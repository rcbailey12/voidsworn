# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 15, 2026, 01:30 UTC)

## 0. Status at Nov 14, 2026, 19:30 CST (Nov 15 01:30 UTC; read this first)

**What to trust.** docs/RULEBOOK.md for rules (0.10: only Ryan's quoted words make a rule; one-day Board choices are notes in
LOOP.md). contrib/opus/LOOP.md for status: "The seats" and the newest LATEST lines. contrib/opus/OPEN_WORK.md for every open
issue and parked pull request and what each waits on. FINDINGS R236 to R252 are the newest rulings. The Nov 14 hand-over is in
docs/archive/HANDOFF_0_2026-11-14.md; nothing under docs/archive/ is followed.

**The Board.** One Claude thread in the Project, Opus 5.5 at high effort, with the Fable advisor on (Ryan, R252: "this chat
stands"). Seats today (LOOP.md): Codex the main builder while the Claude API credit is out (till about Nov 21); Kimi on the
kimicode arm for mid-size code, rules and balance; DeepSeek for small exact jobs; Muse for design, checks and audits (Ryan starts
it; briefs go on issue 256).

**Landed this thread (Nov 15 00:00 to 01:30 UTC).** PR 712 (hand-over, RULEBOOK 0.10), 711 (Muse audit 706), 714 (one scale
table, docs/playbooks/scale.md, and scale_check.gd with six KNOWN rows that jobs 373, 368, 369 clear), 690 (PC runners: shared
mirror, clone retry, preflight, safe chains, resume from partial), 691 (visible weapons match the game, R241), 694 (Eclipse
round 3, R243), 702 (debrief), 707 (Eclipse portraits), 695, 703, 709, 692, 719 (R251 clean-up and R252), 724.

**Ryan's calls tonight (R252).** Eclipse core kept, he judges it in play; the Glasswright Loom replaces the old body plan
(issue 727 rewrites the design); Hullbreaker trophy patches bigger and paler like the concepts (issue 726); Fable advisor on.
He cleared his GPU for Codex through the night until morning: gpu_go.txt in the PC root starts with "GPU cleared"; the
Board overwrites its first line in the morning (it cannot delete on the PC).

**Running on the PC.** DeepSeek 720, 721, 729; Kimi 371 run 3 (resumed from work/issue-371-kimicode-partial), then 722;
Codex chain 15A from 21:42 CST: 367, 368, 373, 726 (cap 7200 s); Eclipse paint from main (ECL_PAINT_MAIN_1115.bat). Next
Codex window: 369, 688 (resolve its -partial against 691's A20 sheet first), 728.

**First jobs for the next Board check.** Merge 731 (runner hot fix) before Kimi reaches 722; merge 701 and 715 on green;
review each Codex run 2 by its pictures; send Ryan one picture per landed visual change. Held, with run 2 briefs in their
issues: 705 (the finale dawn drew a tan hex sheet), 700 (the station), 704 (balance pack). The runner lessons from its first
live runs (the Git helper recursion, Kimi's preflight reply) are in LOOP.md and issue 730.
