# Briefing for Opus on return (Nov 7, 2026)

Paste-ready text for the owner to hand Opus when it comes online (about 18:40 CST, Nov 7, 2026). The full audit is in this same folder: synthesis.md and legs/.

---

Opus, welcome back. Start-here briefing for the Voidsworn repo, Nov 7, 2026. The audit behind it is at contrib/muse/reviews/repo_state_2026_11/ (synthesis.md, legs/, this briefing). Read this, then the synthesis, then act.

While you were capped (Nov 5 to 7), Rey ran the board. Muse jobs #200, #201, #202 were delivered Nov 5 as PRs #203, #204, #205; all three are still open. On Nov 6 a full audit stack ran and Ryan ruled on all of it the same day: #207 ceiling rulings plus the benchmark scene job, #208 graphics, #209 build-route comparison, #210 FX (including the S15 listen pass and the movement spec), #211 Foley probe, #212 destruction and camera, #213 environment, #215 UI, plus tooling notes #206 and #214. On Nov 7, #216 (repo memory hygiene, council memory) was filed. Ryan's #201 rulings were pushed to PR #204 on Nov 6; #201 has no open questions.

Two seats are empty. ChatGPT is down until its reset in about 3 days (around Nov 10): you cover the checker and red-team seat until it returns. Rey can run independent legs on request, which keeps a second pair of eyes on your own merges. Codex is down for a while: per Ryan's Nov 5 note in LOOP.md, you own the board and do codex jobs yourself, relabeling an issue opus before you start it.

Three traps. One: LOOP.md's state, queue, and holds are dated Nov 5 and predate the audit stack; its codex queue points at a runner that is down. Two: PRs #203 and #204 carry the same wrong title (both say "R109: station detail pass #199..."); #203 is the #200 delivery, #204 is the #201 delivery, #205 is correctly titled. Review by diff, never by title. Three: AGENTS.md still describes a Babylon one-file game and phone play; both are stale, and #216 is the fix.

Proposed first session (a proposal; re-sequence as you see fit): (1) review and merge or hold PRs #203 to #205, #204 first since #201 feeds #120 to #122; (2) rewrite LOOP.md to Nov 7, including relabeling or blocking #198 and #199 so the PC watcher cannot queue them for a down Codex; (3) run #207's benchmark before any ceiling-dependent settlement builds; (4) triage #208, #210, #212, #213, #215 into named jobs, with #208 alone carrying the station assert fixes. Parked: #193 waits on Ryan's paid-service call; #194 waits behind #209. Ryan still owes the S15 listen pass (one sitting; the #211 probe judgement rides it), the #193 call, and sheet judgements if #198 or #199 ever land.
