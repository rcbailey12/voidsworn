# Repo memory review, the Board's leg (issue 788)

Written blind: the Board did not open Muse's or DeepSeek's legs before filing this. Nov 15 2026, Opus 5.5 (the Board thread).

## The short answer

The repo is the right home, but it holds the same fact in too many places and lets four kinds of writer (Ryan in two chats,
the Board, workers, scheduled reminders) change direction without a single record. Build three layers on top of what exists:
an append-only record of Ryan's own words, one current-truth page per topic that cites them, and a librarian that only flags
and proposes. Add two things the always-on agents article names that we lack: a register of every scheduled reminder, and a
"running" mark on each job in GitHub. Retire copies of anything GitHub already tracks.

## 1. Failure modes this month, with evidence

| # | What went wrong | Evidence | Root cause |
|---|---|---|---|
| F1 | Two records of one pick | Sunward fighter: Muse's notes say SF4 (Ryan in Muse's chat about 23:51 CST Nov 14); the Board recorded SF3 (Ryan in the Board chat 23:57). opus_check_770 condition 1 and opus_check_776; settled by R256 and Muse's PR 792 | Ryan's words arrive in two chats and each chat writes its own record; neither sees the other |
| F2 | A reminder acted on an overturned decision | The 07:30 CST trigger (trig_01Y1WgWXu7n8s8CSLiuHC9Wb) told the Board to end the GPU window; Ryan had extended it at 06:51 ("You can still use gpu until I say otherwise") | Scheduled prompts carry instructions frozen at write time and nothing checks them against later rulings |
| F3 | A PC file write reported success and did not land | gpu_go.txt: the 06:51 rewrite never reached the PC, so Codex chain 15C ran 367 and 368 CPU-only (board/issue-367/last.md: "GPU captures remain pending because gpu_go.txt says GPU not cleared") | No read-back after a write; LOOP "Known traps" now says so |
| F4 | Issue briefs grow by appending | Issues 41, 371, 367, 368, 726 carry "Board, run 2" and "run 3" paragraphs below a brief that still says the older thing (371's Deliver to still names fx files while its run notes say rules) | The brief is never rewritten; a worker must reconcile layers itself |
| F5 | A check tied two files so every ruling broke every branch | doc_check_tests.js required HANDOFF's "R a to R b" range top to equal FINDINGS' newest row; each Board push of a FINDINGS row (R258 to R263) failed Standing checks on every open PR until a HANDOFF PR landed (PR 796 hit it; fixed by PR 799) | A copy of a fact (the newest ruling number) kept in a second file |
| F6 | Board choices read as rules | RULEBOOK 0.10 and R251 exist because Board one-day choices were followed as rules; R244's A20 note was stretched before Ryan ratified it | No mark on each line saying whose words it is |
| F7 | The same fact in four places drifts | Eclipse gun posture: factions.md said guns fire through gaps; E13 and E14 were built firing over the shade; designs.md said E13's plates root at the bow; opus_check_750 found all three; R256 settled it | Design pages, playbooks and sheets each restate the doctrine |
| F8 | Work in flight lost track across a restart | Two server restarts stopped the Opus workers (Nov 15 about 01:25 and 10:25 CST); the Board found and resumed them by memory of the chat | No durable "running now" record outside the Board's context |
| F9 | Pictures named in a report but not committed | PR 716's REPORT.md links sheets on the PC (C:/Users/.../review_20261115/sheets/); none are in the branch | Done-when did not require the pictures in the repo |
| F10 | Summaries replaced the record | This thread itself ran on a compacted summary; the Board resumed from it. LOOP's LATEST lines and HANDOFF are summaries too | Summaries are written for the writer's next turn, not checked against the record |

## 2. What the three layers fix, and what they do not

- Ryan's words record: fixes F1 (one record, both chats write to it the same turn), F6 (only lines citing it are rules), F10
  (summaries point at it instead of paraphrasing).
- Current-truth pages: fix F7 (one home per fact), F4 if briefs point at a page and a delta instead of restating.
- Librarian: catches F1, F5, F7 after the fact, F2 if it reads the reminder register, F9 if it checks PR bodies for linked files.
- Not fixed by the layers: F3 (a tooling habit: read back every PC write), F8 (needs the running mark), F2 at fire time (needs
  reminders that carry a pointer and re-check, not an instruction).

Also needed:
- A reminder register (LOOP section "Timers"): every send_later and trigger with its purpose, the ruling or state it assumes,
  and when it stops mattering. A fired reminder re-reads LOOP and the record before acting.
- A `running` label on each in-flight issue plus one status comment edited in place (seat, machine, folder or worktree,
  branch, start, cap, how to resume). The PC runner sets and clears it with gh; the Board does it for sandbox workers.
- Briefs rewritten, never appended: a run note replaces the brief's section it changes, and the issue keeps a short "Changes"
  list with dates.

## 3. What the librarian checks

Mechanical, a script on every push and nightly (GitHub Actions, no AI, no cost):
1. Every "R<n>" cited in a current-truth page or playbook exists in FINDINGS, and its status is not SUPERSEDED.
2. No file names a "newest ruling" number (the F5 trap): ranges, if any, are open-ended.
3. Every repo path a doc, brief or PR body names exists on main or on the PR's branch; a C:/ path in a PR body is flagged (F9).
4. Each open issue body: no "run N" paragraphs below the brief (F4); its Deliver to paths exist.
5. LOOP's Timers section: no entry past its expiry; every entry names its assumption.
6. Each `running` label: a commit or status update within its cap, else flag (F8).
7. No em dashes, line length, the existing standing checks.

Judgment, the nightly sweep by a different model family from the Board:
1. New lines in Ryan's words record since the last sweep: is each reflected in the right current-truth page, and has any older
   line it overturns been marked superseded there?
2. Contradictions between current-truth pages, playbooks, design pages and sheets (the F7 class).
3. Lines that read as rules but cite no words of Ryan (F6).
4. Briefs whose direction no longer matches the current-truth page.
5. Message load: how many messages the Board sent Ryan and which needed him (the article's eval on message volume).

Never: decide or rewrite a rule, edit Ryan's words, close an issue, merge, delete, or change game code. It opens one fix-up PR
for mechanical fixes and one report for judgment items; the Board rules.

## 4. Where things live

- Ryan's words: new `docs/record/ryan_words.md`, append-only, one entry per message that rules on anything: date, time, chat
  (Board, Muse, other), the quote verbatim, what he was looking at (picture or question), and the R id the Board gives it.
  FINDINGS stays as the ruling index and history; each FINDINGS row cites its entry.
- Current-truth pages: `docs/truth/` with one page each for the seats, the PC, each faction, each ship and craft, the screens,
  open work. Each line cites an R id. factions.md and screens.md become these pages for their areas (keep paths with a pointer).
- History, unchanged: FINDINGS, docs/archive/, contrib/<agent>/reviews/.
- Retire as copies: HANDOFF section 0 becomes a short generated view (seats, running, waiting on Ryan) built from the truth
  pages and GitHub; OPEN_WORK.md becomes a GitHub issue query plus the truth page for open work.
- Status GitHub already tracks lives only in GitHub (issue state, owner label, PR state, checks, running label).

## 5. The per-turn cost to each seat

- Any chat Ryan rules in: append his words to the record that turn (one entry), with what he was looking at.
- The Board: cite an R id on any rule line; rewrite a brief instead of appending; register every reminder; set and clear
  `running`; read back every PC write.
- Workers: cite the truth page they built from; commit every picture they cite.
- Muse: write Ryan's words to the record itself when he rules in its chat (this is the F1 fix; Muse is the second chat).

## 6. Can Muse be the standing librarian?

Muse's judgment is good (opus_check_770 found F1; opus_check_750 found F7). It cannot run without Ryan starting it, so it
cannot be the nightly sweep. Give Muse the deep outside checks of builds and the weekly design-doc audit; give the nightly
sweep to a seat that starts itself (section 10) and the mechanical checks to a script.

## 7. The librarian, concretely

- Runs: the script on every push and at 02:00 CST; the judgment sweep nightly at 03:00 CST and on each hand-over (the Board
  pokes it); a weekly Muse audit when Ryan starts Muse.
- Inputs: ryan_words.md, docs/truth/, FINDINGS, RULEBOOK, playbooks, open issues and their bodies, open PRs and their bodies,
  LOOP (Timers and LATEST), GitHub labels.
- Output: one standing issue "Librarian report" with a dated comment per sweep: findings ranked, each with evidence and a
  proposed fix; one fix-up PR for the mechanical items only. The Board answers each finding in LOOP.
- Skill: a `librarian` SKILL.md in .claude/skills/ (and the same text at contrib/librarian/LIBRARIAN.md for non-Claude seats):
  the checks above in order, the never list, the report format, and the test cases.
- Proof: a fixture set under contrib/librarian/test/ that replays this month's failures (F1, F2, F4, F5, F6, F7, F9) as small
  planted repos or file sets; the script and the judgment sweep must flag each; run the script's part in CI.

## 8. The always-on agents article, mapped

Event inbox: we have several (two chats, GitHub, triggers); one record of Ryan's words is the inbox that matters. Timers: add
the register. Memory: keep only what GitHub cannot hold; point, never copy. Dreaming: the librarian. Saving before compaction:
the Board writes LOOP before long work and at every hand-over. Starting quiet: the librarian counts the Board's messages.

## 9. Ryan's answers of 08:37 tested

GitHub as the one source holds: each fact gets one home, and the `running` label plus status comment works for every seat that
can reach GitHub. What breaks: Muse and the dot cannot set labels without a GitHub token; the Board sets them on their behalf.
A label set by a PC run that dies keeps saying running; the cap check (3.6) catches it.

## 10. The dot

Fits the nightly judgment sweep: it starts itself, is a different model family (GPT-6 Astra), keeps context between runs, and
has Custom Rules for the never list. Its background mode is read-only, which is right for a sweep: it posts the report, the
Board makes fixes. Needs: read access to the repo (GitHub connector), one standing instruction (the skill text), a Custom Rule
prohibiting writes except one comment on the librarian issue, and a RULEBOOK 2.7 line allowing it (2.7 bars Codex cloud work
today). Test: run it once against the fixture set before it goes nightly. Board pick: the dot for the nightly sweep, the script
for the mechanical checks, Muse for weekly audits and build checks.
