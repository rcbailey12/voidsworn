# Repo memory, issue 788: the Board's synthesis of three legs

Nov 15 2026, the Board (Opus 5.5). Legs: the Board's (contrib/opus/reviews/repo_memory_788.md, PR 801), Muse's
(contrib/muse/reviews/repo_memory_788.md, merged in PR 790; Rey chaired, DeepSeek, Qwen and Flash seated, Grok empty) and
DeepSeek's (contrib/deepseek/reviews/repo_memory_788.md, PR 803, standing in for the Codex leg). Each leg was written blind.
Ryan's dot ran a separate read-only sweep the same day; its finds were fixed in PR 807.

## Where all three agree (adopt as is)

1. **One record of Ryan's words.** Append-only, verbatim, timestamped, naming the chat that heard it, written by that chat in
   the same turn. This is the single inbox the always-on agents article calls for; the SF3 and SF4 conflict (F1) came from two
   chats keeping two records.
2. **One home per fact, pointers over copies.** Anything GitHub tracks (issue state, owner, PR state, checks) lives only in
   GitHub. HANDOFF and LOOP keep what GitHub cannot hold and point at the rest.
3. **"Running" lives in GitHub.** A `running` label plus one status comment edited in place (seat, machine, folder or worktree,
   branch, started, cap, last commit, how to resume), set and cleared by whatever starts the job, by script where one exists.
4. **A timer register.** Every scheduled reminder listed with its purpose and the ruling it assumes; a reminder whose ruling
   is superseded is void. LOOP already has a Timers section (started Nov 15); it becomes the register.
5. **The librarian only flags and proposes.** Never decides a rule, never edits Ryan's words, never closes, merges or deletes.
   At most one fix-up PR per sweep, mechanical fixes only, plus one report.
6. **Mechanical checks are a script in CI**, extending contrib/opus/tools/doc_check_tests.js (run_all_checks.js picks up any
   new *_tests.js). No model, no cost, starts without Ryan.
7. **Muse cannot be the nightly seat** (Ryan starts every Muse run; its council is often short-handed), but is the best judge
   for hand-overs and audits.
8. **Proof by replay.** Fixtures that replay this month's failures (F1 to F10 across the legs); the librarian is not done
   until it flags each.

## Where they differ, and the Board's call

| Question | Board leg | Muse leg | DeepSeek leg | Call |
|---|---|---|---|---|
| Nightly judgment seat | Ryan's dot | Muse at hand-overs only | Muse at hand-overs only | **The dot nightly, Muse at hand-overs and audits.** The dot starts itself, is a different model family from the Board, and its first sweep found real drift (PR 807). Muse's and DeepSeek's legs did not weigh the dot. Needs Ryan's yes and a RULEBOOK 2.7 line. |
| Two conflicting quotes | not covered | CONFLICT on the page, CONTESTED blocks dispatch even when checks are green | CONFLICT rule | **Adopt CONTESTED.** PR 776 was green and wrong; only Ryan's next words clear it. |
| What a truth-page line may cite | Ryan's words (an R id) | Ryan's words or an artefact (a check, a sheet, a measurement) | Ryan's words | **Either.** Forcing every line onto a quote invites stretched quotes, the R251 failure in a new form. A typed code (SF3, IM5) must appear literally in what it cites. |
| Where truth pages live | new docs/truth/ | the existing playbooks (factions.md, ships.md, scale.md, screens.md) plus a seats page and a PC page | new pages | **The existing playbooks**, each with a header naming it the live page; the seats text moves out of LOOP to docs/playbooks/seats.md. Less churn, same effect. |
| OPEN_WORK.md | retire | generate from GitHub, marked generated, never dispatched from | generate | **Generate** (two legs and Muse's council agree). |
| Issue briefs | rewrite the body, keep a dated Changes list | body is the fixed block; the live brief is one CURRENT BRIEF comment | rewrite | **Rewrite the body; old text to a comment** (what 371 got on Nov 15). Every runner and worker already reads the body. |
| Words log file | docs/record/ryan_words.md | docs/words/2026-11.md, one file a month | one folder | **docs/words/YYYY-MM.md**, one a month: greppable, small. |
| Size caps on HANDOFF and LOOP | none | counted by the check | none | **Adopt:** HANDOFF section 0 about a page, LOOP LATEST about 15 lines, enforced by the check. |

## Build plan, smallest provable first (DeepSeek's order, Board-adjusted)

| Step | What | Seat | Size |
|---|---|---|---|
| 1 | docs/words/2026-11.md seeded from FINDINGS quotes R236 on; the writer rule in RULEBOOK and AGENTS.md (the chat that hears Ryan logs him that turn); Muse's standing rule gets the same line | Board | 1 run |
| 2 | memory_lint_tests.js: R ids exist and are not superseded, typed codes appear in the cited quote, no ruling ranges, named paths exist, no "run N" paragraphs in issue bodies, HANDOFF and LOOP size caps, words log append-only | DeepSeek, Board review | 1 to 2 runs, 1 review round |
| 3 | running label plus status comment: the PC runners (codex_issue.bat, work_issue.bat) set and clear it with gh; the Board does it for sandbox workers | Codex lane C | 1 run |
| 4 | Timers register formalised in LOOP; seats page split out; truth-page headers on the playbooks; CONTESTED marker | Board | 1 run |
| 5 | Generated open-work page and the nightly GitHub Actions sweep (mechanical, opens the fix-up PR) | DeepSeek | 1 run |
| 6 | Librarian skill (.claude/skills/librarian/SKILL.md, mirrored at contrib/librarian/LIBRARIAN.md) and the replay fixtures; the dot's first fixture run, then nightly | Board writes, dot runs | 1 run plus Ryan's setup |
| 7 | Muse's hand-over pass on the script's report | Muse when Ryan starts it | per hand-over |

Steps 1 to 3 already catch most of F1 to F10; 5 to 7 come after the lint is green on main.

## What Ryan decides

1. The dot as the nightly judge (and the RULEBOOK 2.7 line that allows it, read-only plus one comment on a librarian issue).
2. Go on the build order above, or a smaller first cut (steps 1 to 3 only).
3. How the librarian reaches him: a short nightly report only when it finds something, or a weekly roll-up.
