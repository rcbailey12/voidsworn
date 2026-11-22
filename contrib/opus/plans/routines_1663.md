# Two routines, proposed for the Board (issue 1663, Wave 4.2)

Ryan approved the plan on Nov 22 2026 (thread "Upgrade studio ops and PC harness"): "Wave 4 Routines/scheduled tasks:
propose, don't create without the Board's check." Nothing here is created. The Board reads it, changes what it wants, and
then creates each routine itself (a Claude Code scheduled trigger on this repo) or says no.

Both routines are cloud Claude sessions on `rcbailey12/voidsworn`. Neither merges, closes a pull request, pushes to main,
deletes a branch or touches Ryan's PC. Each one ends by posting one message to the Board thread; the Board acts on it.

## 1. Daily garden (docs and hygiene)

- **When:** every day at 5:30 AM Central (before the Morning Pick Sheet).
- **Cost:** one Opus run, read-mostly. Estimate from the board's history: about the size of one review pass.
- **Does:**
  1. Lists merged pull requests of the last 24 hours and the issues each names. An issue whose scope is done and still
     open goes on a "close these" list (R288); a `running` label on an issue with no live job goes on a "stale label" list.
  2. Lists open pull requests: red checks over 12 hours, conflicts with main, drafts untouched for 3 days, and branches of
     the job shapes (`opus/`, `codex/`, `muse/`, `work/`, `neon/issue-*`) with no pull request.
  3. Runs the standing checks' memory and doc lints on main (`contrib/opus/tools/run_all_checks.js` subset: findings,
     rulebook links, em dashes) and lists anything red.
  4. Looks for drift between `AGENTS.md` and `CLAUDE.md`, and between RULEBOOK rule numbers and the FINDINGS rows that cite
     them.
  5. If a fix is small and only text (a broken link, a stale path in a playbook), it pushes `opus/issue-<garden issue>`
     with the fix, so the usual checks and review run. Anything else is only listed.
- **Posts:** one message to the Board thread: the lists, each line with its link, and the branch it pushed if any.
- **Never:** closes, merges, relabels or comments on GitHub itself; the Board does that from the list.

## 2. Pick Sheet compile (twice a day)

- **When:** 7:30 AM and 5:30 PM Central, half an hour before each sheet is due (docs/playbooks/PROGRAM.md "Pick Sheets").
- **Cost:** one Opus run each, small.
- **Does:**
  1. Reads the open picks: issues and pull requests labelled `ryan`, decision cards still open in the project's threads,
     and the "Owed" list in `docs/playbooks/PROGRAM.md`.
  2. Drops anything that is status or a technical call the Board can make (RULEBOOK 2.1), and anything answered since.
  3. Drafts the sheet in the PROGRAM.md format: numbered, lettered options, the Board's pick and why, one current
     labelled picture per item (it links the newest picture already on the issue or in `/mnt/project-files/board/`; it never
     makes a new one).
  4. Marks an item that rolled over once already so the Board decides it with its own pick (the format's rule).
- **Posts:** the draft to the Board thread. The Board checks it and sends it on; Ryan never gets a sheet straight from the
  routine.
- **Never:** posts in the project chat, messages Ryan, or answers a pick.

## What the Board decides

1. Yes or no for each, and the times (Ryan is on Central time).
2. Whether the garden may push small text fixes (step 5) or only list them.
3. Which issue number the garden's fix branch uses (a standing issue, like 906 for sweeps).
