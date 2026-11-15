# Issue 788, DeepSeek leg: how the repo carries decisions and status

Blind leg. I did not open `contrib/muse/reviews/repo_memory_788.md`, the Board's synthesis, or any other leg of this
review. I read the repo at commit `02fd6084` (Sun Nov 15 11:18:56 2026 -0600). This is a read-only review: no game code,
rules, tables, saves or assets are touched. The only file this leg adds is this one.

---

## Delivery report (for the PR)

**What changed.** One new file, `contrib/deepseek/reviews/repo_memory_788.md`. Nothing else. `git status` at the end shows
only this file plus the pre-existing untracked `WORK_TASK.md`.

**Checks I ran.**
- `node contrib/opus/tools/run_all_checks.js`: every row PASS except `doc_check_tests` (FAIL, pre-existing on main, see
  below) and the two baseline rows `findings_tests` and `oracle_drift_guard` (KNOWN). Exact rows:
  - `doc_check_tests | FAIL | 0.13 | FAIL HANDOFF.md section 0 names the ruling range R236 to R257, but the newest FINDINGS row is R261 (the range top R257 is 4 rulings behind)`
  - `findings_tests | KNOWN | 1.11 | KNOWN: 7 listed failure(s): KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5`
  - `oracle_drift_guard | KNOWN | 0.69 | KNOWN: 12 constant difference(s) within the baseline`
  - `oracle_copy_test | PASS | 0.25 | PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files`
  - `checks | PASS | 0.14 | PASS: within the pack baseline`
  - `table_xref | PASS | 0.08 | PASS: exit 0`
  - `fixture_check | PASS | 0.32 | PASS fixture corrupt2 pair`
- `node contrib/opus/tools/doc_check_tests.js`: `FAIL HANDOFF.md section 0 names the ruling range R236 to R257, but the newest FINDINGS row is R261 (the range top R257 is 4 rulings behind)` and
  `FAIL: 1 entry document problem(s)`.

The `doc_check_tests` failure is on main before this leg and is itself evidence for question 1 (finding F4 below). I did
not fix it because this job is the review, not the librarian build, and changing `HANDOFF.md` would be a second job.

**Skipped, and why.**
- Rules parity and campaign parity: skipped. No root rule file, table, Godot file or save field changed, so there is
  nothing for parity to compare. The runner runs parity after this leg and adds its real rows.
- Godot import and UI screenshots: skipped. No scene, UI, texture or asset changed, so no shot would show this leg.
  The `out/shots` folder is created with a note saying so.
- `rust`/other toolchains: none in this repo.

**How the change reaches the rest of the game.**
- Callers: no function, constant or save field changed. I searched the repo for every fact I cite (SF3 and SF4, the E14
  ring, the E13 shade, Kimi, the GPU go, "run 2" bodies) and cited each use; no call site needs a fix.
- Saves: no save field or profile format touched. Old profiles load as before because no `.gd`, `.js` or `.json` file
  changed.
- Twins: no `battle.js`, `data.js` or `core.js` change, so no re-export of `godot/rules/data/tables.json` or
  `godot/campaign/data/campaign_tables.json`. `oracle_copy_test` PASS above proves the two sides still match.
- UI: no value shown on any screen changed. Not applicable.
- CI: no new test file, so `contrib/opus/tools/run_all_checks.js` is unchanged. GitHub runs three jobs from
  `.github/workflows/checks.yml`: `standing-checks`, `Godot rules parity`, `Godot game checks`.

---

## How to read this leg

The job asks nine questions. I answer each with file paths and line numbers, and mark each finding OBSERVED (I saw it
in the file at `02fd6084`) or INFERRED (my reasoning from what I saw). Short quotes are exact. I follow the evidence
discipline of `docs/REVIEW_PROTOCOL.md` (no theories without a quote, "Not checked" at the end) but not its 10 finding
cap, because the job fixes the nine questions.

The short answer: the repo already has most of the parts, but it has five habits that let a wrong or stale direction
reach a worker. They are: (1) the same fact is written by hand in several places; (2) a summary line is trusted over the
message it summarises; (3) status files copy GitHub state instead of pointing at it; (4) a scheduled action does not
re-read the fact it acts on; (5) a brief is appended to instead of rewritten. The three layers fix four of the five. The
fifth needs one small writer rule, not a new layer.

---

## 1. Failure modes: how a wrong or stale direction reached a worker in Nov 2026

Ten findings, most important first. The first one cost a build round.

| # | Finding | Kind | Evidence (file:line) | Exact quote | Why it matters |
|---|---|---|---|---|---|
| F1 | Two chats heard the same pick, and the repo had two records. The Sunward fighter was SF4 in Muse's delivery notes and SF3 in the Board's FINDINGS row and `factions.md`. | OBSERVED | `contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/design_notes_757.md:58`; `contrib/opus/FINDINGS.md:285`; `docs/playbooks/factions.md:226`; `contrib/opus/LOOP.md:71` | "Ryan ruled SF4 and SB4 (Nov 14, 2026, about 23:51 CST)" and "Agree on sf3 and sb4" | PR 776 built the fighter the Board's row named, then was held. One record conflict cost one build round and one outside check (opus_check_770 and 776). |
| F2 | A quote attributed to Ryan existed only in a later summary. No message said "Agree on sf3 and sb4"; it was the Board's line, and it propagated into `factions.md` and the issue briefs. | OBSERVED | `contrib/opus/FINDINGS.md:285`; `contrib/muse/reviews/opus_check_776.md:19` | "No message from Ryan says \"Agree on sf3 and sb4\"" | A summary can invent owner words. Once in `factions.md`, the wrong words are read cold by the next chat as the ruling. |
| F3 | The same design fact lived in two documents and they drifted. `factions.md` says guns never fire through a shade; `designs.md` still says they do. `designs.md` still says E14's ring lies flat; R256 withdrew that. | OBSERVED | `docs/playbooks/factions.md:166`; `contrib/muse/design/class_family_deathless_2026_11/designs.md:5`; `designs.md:23`; `contrib/opus/FINDINGS.md:286` | "guns firing through gaps in the shade" and "the ring lies flat as a sunshade" | The next Eclipse sheet built from `designs.md` contradicts the two accepted builds and Ryan's own words. |
| F4 | The hand-over's ruling range was stale. `HANDOFF.md` names R236 to R257; the newest row is R261. The standing check fails on main today. | OBSERVED | `HANDOFF.md:7`; live `doc_check_tests` output; earlier instance `contrib/opus/LOOP.md:78` | "FINDINGS R236 to R257 are the newest rulings" and "the range top R257 is 4 rulings behind" | A fresh chat reads a hand-over that stops four rulings short, including the fix to F1. |
| F5 | One status file contradicted itself. LOOP's newest line says SF3 stands; LOOP's "Waiting on Ryan" still asks SF3 or SF4. | OBSERVED | `contrib/opus/LOOP.md:69`; `contrib/opus/LOOP.md:87` | "R256 (PR 779, open): SF3 stands" and "which Sunward fighter, SF3 (Board chat 23:57) or SF4 (Muse chat 23:51)?" | A worker reading the waiting list asks Ryan a question he already answered, or waits for an answer that exists. |
| F6 | A one-day Board choice was read as a rule. RULEBOOK 0.10 records that an A20 note was stretched to every ship before Ryan ratified it, and that a summary line inverted his call on A18 and A19. | OBSERVED | `docs/RULEBOOK.md:68-76`; `contrib/opus/FINDINGS.md:281` | "an A20 note was stretched to every ship before Ryan ratified it (R244)" | Board operating choices become global rules, which is exactly Ryan's "single patch behavior applied incorrectly" worry. |
| F7 | A stored timer fired an instruction that Ryan had already replaced. A 07:30 check-in was scheduled to close the GPU window; Ryan extended the GPU at 06:51 and the step is now called void. | OBSERVED | `contrib/opus/LOOP.md:75`; `contrib/opus/LOOP.md:68`; `contrib/opus/LOOP.md:69` | "07:30 CST (close the GPU window: overwrite gpu_go.txt's first line)" and "the 07:30 morning trigger's 'end the GPU window' step is void" | A future action acted on a fact that changed after it was written. The script had no re-read step. |
| F8 | Issue bodies were appended with "run 2" and "run 3" notes instead of being rewritten. This is why RULEBOOK 2.9 exists. | OBSERVED | `contrib/opus/OPEN_WORK.md:18`; `contrib/opus/OPEN_WORK.md:23`; `contrib/opus/LOOP.md:72`; `docs/RULEBOOK.md:175-177` | "run 2 brief in the issue body" and "A Muse issue is never edited once Ryan may have started it" | A run reads the top of the body and does the old job. The rule's own reason says the later edit was lost (R200). |
| F9 | A tool rewrote the record. A Board push to a worker branch made `auto_pr` rewrite the PR text from the commit message, dropping the worker's evidence and closing line. | OBSERVED | `contrib/opus/LOOP.md:95` | "dropping the worker's evidence and its closing line" | The PR is the worker's outbox and its proof. A later push erases it, so the Board reviews a different record than the worker wrote. |
| F10 | The open-work ledger was stale and incomplete. It says it was rewritten at 01:20 UTC and has no rows for issues 780 to 785, PR 779 or PR 778, all live by 13:35 UTC. | OBSERVED | `contrib/opus/OPEN_WORK.md:4`; `contrib/opus/LOOP.md:69` | "Rewritten Nov 15 2026, 01:20 UTC" | Board duty 1 says it is read at every board check. A stale ledger hides agreed work, which is the exact failure R194 was written for. |

Two more live instances, same class, kept out of the table to respect the review protocol's cap:

- F11, seats in three homes and one stale: `docs/RULEBOOK.md:150` says "Kimi is no longer a seat", `HANDOFF.md:13` says
  cancelled, but `contrib/opus/LOOP.md:42` still gives Kimi a launch recipe, with no SUPERSEDED mark. OBSERVED.
- F12, in-flight state lives in prose: `HANDOFF.md:26` says "Running. Opus workers 780, 781, 726", and
  `contrib/opus/LOOP.md:71` says a server restart "stopped the three Opus workers" and they resumed by hand. OBSERVED
  for the prose, INFERRED for the lack of a machine-readable in-flight record.

Cost, in the board's own units (agent runs and review rounds, not human hours): F1 and F2 cost the PR 776 build, its
hold, two outside checks (opus_check_770, opus_check_776) and a rebuild decision. F4 and F10 cost a Board review round
each. F7 could have stopped a running GPU job. F3 costs whichever sheet is built next from `designs.md`.

---

## 2. Which of the three layers would prevent these, which would not, and what else is needed

| Failure | Layer 1: verbatim words | Layer 2: current-truth pages | Layer 3: librarian | What else is needed |
|---|---|---|---|---|
| F1 two records | Helps most: both quotes sit side by side with time and chat, so the later one is visibly later. It does not decide. | Helps: one ship page has one fighter line, with a supersession note. | Flags two live claims for one key; routes to Muse or Ryan. | A rule that a topic line may cite only one live word set, and a key registry so "ship:sunward:fighter" has one home. |
| F2 invented quote | Prevents: the quote must resolve to a record entry, or the line fails. | Helps if every line must cite. | Mechanical: quote not found, fail. | The writing chat must log the words in the same turn, before it writes the summary. |
| F3 duplicate homes | Does not prevent by itself. | Prevents if the second home becomes a pointer, and superseded lines are removed. | Flags two live values for one key. | A key registry and one-home lint. Pointers, not copies. |
| F4 stale hand-over | Does not prevent. | Prevents if HANDOFF is generated from the pages, or at least checked. | Mechanical: range vs newest FINDINGS. Already built (doc_check 1b). | Make it block the PR at commit time, not only a nightly. |
| F5 self-contradiction | Does not prevent. | Prevents if the waiting list is generated from open issues, not hand-written. | Flags the same question in two states. | Replace the hand-written waiting list with a pointer to the `waiting-on` label or a generated block. |
| F6 Board choice as rule | Prevents if a rule line must cite Ryan's words, and a Board-only line must say so. | Helps: one rules page, each line names its source class. | Judgment: is this a stretch? Flag, never fix. | A rule-writing rule: a Board choice is a LOOP note; only Ryan's words make a rule (RULEBOOK 0.10). |
| F7 stale timer | Does not prevent: the words were right when stored. | Helps if a timer page names the fact it acts on. | Mechanical: timer has a source, an end, and a re-read target; on fire, re-read first. | The firing action must re-read the current truth. A registry is not enough without the re-read. |
| F8 appended briefs | Helps: the words record the scope change with a time. | Prevents if the topic page is rewritten, not appended. | Flags "run 2" in an issue body and asks for a rewrite or a new issue. | A writer rule: rewrite the brief, never append (RULEBOOK 2.9 already says this for Muse issues). |
| F9 tool rewrites PR text | Does not prevent. | Does not prevent. | Cannot see it after the fact unless the body is snapshotted. | Runner fix: save the body before a push, restore it after. Not a memory-layer job. |
| F10 stale ledger | Does not prevent. | Prevents if the ledger is generated as a pointer table. | Mechanical: every open issue has a row; every row points at an open item. | Replace hand-maintained status with `gh` output and a short "what it waits on" column. |

The honest split: layer 1 stops an invented quote from becoming a live line and makes conflicts visible; layer 2
prevents duplicated and stale facts; layer 3 catches everything mechanical that remains. None of them prevent a wrong
decision by the Board or a tool that rewrites a PR body. Those need the rule and the runner fix named in the last
column.

One limit to state plainly: layer 1 stops a quote that resolves to no record, but it cannot prove that a record entry
matches the chat it claims to come from. The writer rule (the chat that heard the words writes them the same turn) is
what makes the record trustworthy; the lint can only check that later lines agree with it. A second witness, the chat
transcript, is outside the repo. The best the repo can do is require the chat name, the local and UTC time, the exact
text and the issue or PR, and cross-check two records of the same words when two chats heard them (the SF3 case shows
why that cross-check matters).

---

## 3. What the librarian should check, and what it must never do

### Mechanical checks a script can run on every push (Node, no model, no GPU)

1. Schema: every current-truth page has the required front matter; every live line ends with a citation (`R<n>`,
   `words:<path>#<anchor>`, `issue <n>`, `PR <n>`); no uncited status line.
2. Citations resolve: every `R<n>` exists in `contrib/opus/FINDINGS.md`; every `words:` anchor exists in the layer-1
   record, and the quote matches exactly (character for character after whitespace normalisation); every issue and PR
   number exists (when online; `--offline` mode skips this row with SKIP, never PASS).
3. Supersession: a live line may not cite a FINDINGS row marked SUPERSEDED. Every new ruling names what it replaces
   and the replaced line is marked or removed.
4. One home per key: a key registry (`ship:<faction>:<code>:<field>`, `seat:<name>`, `pc:<topic>`,
   `work:<issue-or-pr>`) maps each key to exactly one page. Other pages may hold a pointer, not a value. Two live values
   for one key fail.
5. Hand-over freshness: `HANDOFF.md` section 0 names a FINDINGS range whose top is within N of the newest row
   (`doc_check_tests.js` already does this with N = 3); its length stays about one page; older content is archived.
6. Status files do not restate GitHub: no "Running. <workers>" prose, no "WAITING ON green CI" row that GitHub already
   answers; only a pointer or a generated block.
7. Open work: every open issue has a row; every row points at an open item; every PR row's open or merged state matches
   GitHub; every `waiting-on` names an owner and a thing.
8. Running labels: every `running` label has one status comment with seat, machine, folder or worktree, branch, started
   time, cap and how to resume; any label past its cap with no new commit since `started` is flagged. A job with no
   label is not running.
9. Timers: every scheduled action has a source (`words:` or `R<n>`), a fire time, an end condition and the page it must
   re-read before acting. An expired timer must be marked fired or removed. A timer that acts on a mutable fact and
   names no re-read target fails.
10. Briefs: an issue body containing "run 2" or "run 3" (or a second "Brief:" block) is flagged for a rewrite or a new
    issue, not auto-fixed.
11. Paths, links, dates: every path exists (already built); no relative words ("today", "now", "current") without a
    date; no stale date in a live page.
12. Size: RULEBOOK stays a rules book; HANDOFF stays about one page; LOOP LATEST rolls at about 15 lines (RULEBOOK 0.10
    already sets these); no current-truth page over a stated ceiling.

### Judgment checks for Muse, or the Board when Muse is not running

- Is a summary line a fair quote of Ryan's words, or a stretch past what he named? (RULEBOOK 0.10, R251 item 1)
- Is a Board choice being written as a standing rule? (R251 item 2)
- Do two pages contradict in meaning even when the words differ? (the Eclipse guns doctrine, F3)
- Which of two owner quotes is later, and is the later one really about the same thing? (timestamps make the order
  mechanical; sameness is judgment)
- Is a "run 2" note a clarification or new scope?
- Is the current-truth page actually true, not just internally consistent?
- Should an issue be closed or folded into another? The librarian may propose; only the Board closes.

### What it must never do

- Never decide a rule, overturn a ruling, or edit Ryan's words.
- Never edit layer 1 (append-only record). The only exception is a secret redaction, and then only the secret is
  replaced, with a note and the original kept out of the public repo.
- Never close an issue, merge a PR, or push to main.
- Never touch game code, rules, tables, saves, assets, the PC queue or the GPU.
- Never rewrite a finding's meaning; it flags and routes.
- Never message Ryan directly. It writes one report and one PR; the Board decides what reaches Ryan (RULEBOOK 1.6).
- Never edit another agent's live branch; one fix-up PR per sweep, on its own branch.

---

## 4. Where things should live

### Become current-truth pages (layer 2)

| Page | Holds | Takes over from | Keeps pointing at |
|---|---|---|---|
| `docs/memory/truth/seats.md` | who is a seat now, which arm is on, what each is for, what starts it | LOOP "The seats" status lines; the status half of RULEBOOK 2.6 | RULEBOOK 2.6 (rules), issue 256 (Muse), the runner files |
| `docs/memory/truth/pc.md` | the PC, the queue, the GPU go holder and its end, the known traps | LOOP "Known traps"; the PC lines scattered in HANDOFF | RULEBOOK 3.2 to 3.9, `tools/pc/` |
| `docs/memory/truth/open-work.md` | one row per open issue and PR, and what it waits on | `contrib/opus/OPEN_WORK.md` | GitHub (`gh issue list`, PR state), never restates it |
| `docs/memory/truth/faction-<name>.md` (6) | one row per ship: state, picked words, next step, open risk | the status rows of `docs/playbooks/factions.md`; the build notes in `contrib/muse/design/class_family_*/designs.md` | the build sheets, the concept pictures, FINDINGS |
| `docs/memory/truth/scale.md` | the size rules and the KNOWN rows | `docs/playbooks/scale.md` status bits | RULEBOOK 3.9, `scale_check.gd` |
| `docs/memory/truth/timers.md` | every scheduled action, its source, its end, its re-read target | the chat `send_later` notes in LOOP; the 07:30 and 21:50 check-ins | the issue or PR it acts on |
| `docs/memory/truth/running.md` | a query, not a list: `gh issue list --label running` and the comment format | HANDOFF "Running" line; LOOP "RUNNING" prose | GitHub labels and comments |

`docs/memory/truth/rules.md` should not exist as a copy. The RULEBOOK stays the rules. Topic pages cite RULEBOOK section
numbers; a duplicate rule text is exactly F3.

### Stay history

- `contrib/opus/FINDINGS.md`: the dated ruling history. It stays the evidence of record for every R row.
- `docs/archive/`: every old hand-over, old LOOP history, old ledger. Never followed; the doc_check already keeps them
  out of scope.
- Build sheets, audit reports, evidence folders, review legs: records of a run, not current truth.

### Retire as hand-maintained pages

- `HANDOFF.md` section 0 as a hand-written status page: becomes a short generated index (about one page) that points at
  the topic pages and the newest rulings. Its "What to trust" block stays.
- `contrib/opus/OPEN_WORK.md` as a hand-maintained ledger: becomes the generated pointer table at
  `docs/memory/truth/open-work.md`.
- LOOP "The seats" status half: the rules stay in RULEBOOK 2.6; the status moves to `seats.md`.
- LOOP "Waiting on Ryan": becomes a generated block from the issues labelled `waiting-on-ryan`, not a hand list.
- LOOP LATEST: keep, but roll at about 15 (already the rule); it is a chronological log, not a second truth page.

Ryan already picked this shape: keep RULEBOOK and FINDINGS, and let HANDOFF and OPEN_WORK become librarian-kept pages
(WORK_TASK, Ryan's words). This section only makes the split concrete.

---

## 5. The cost: what each agent does differently every turn

Keep it to two actions.

1. **Log Ryan's words the same turn.** Whichever chat heard them appends one entry to the layer-1 record:
   timestamp (local and UTC), chat or seat, the verbatim text, and the issue or PR it concerns. One file write or one
   command. No summary, no paraphrase.
2. **Cite the line you write.** A status line gets one citation (`words:...#...` or `R<n>` or `issue <n>`). One bracket.

Two more, only when they apply:

- **Rewrite a brief, never append.** A new scope is a new issue or a rewritten body (RULEBOOK 2.9). One edit, net text
  about the same.
- **Set or clear the running label and its one status comment.** The PC runner and the Board do this in the same step
  as starting or reporting a job. No agent cost, two `gh` calls.

What each seat does not do any more: restate a GitHub fact in a doc. That is the biggest text saving, and it removes a
whole class of drift.

The Board adds one command at each hand-over: run the lint, then rewrite HANDOFF from the topic pages instead of from
memory. Muse adds one habit: name the quote it is checking, so the citation is already there.

---

## 6. Can Muse be the standing librarian?

**Verdict: Muse can be the judgment half, not the standing half. A script must carry the mechanical half, and the
nightly sweep must work with no model at all.**

What the repo says:
- Muse runs only when Ryan starts it. `contrib/opus/LOOP.md:44` says "RYAN STARTS EVERY MUSE RUN", and the standing
  rule is RULEBOOK 2.8 / R89. A nightly librarian on Muse would either break that rule or need a new ruling from Ryan.
- Muse's council is often not all there. The same-day checks record Qwen empty by its daily cap and Grok empty at the
  bot wall (`contrib/muse/reviews/opus_check_770.md:14-15`; `contrib/muse/reviews/opus_check_776.md:13-15`). A
  librarian that needs four legs will be empty on many nights.
- Muse is good at exactly the judgment this needs. `opus_check_770` and `opus_check_776` caught the wrong fighter
  record, the wrong quote, and the unanswered condition by reading the sources against each other. That is the work a
  script cannot do.

So the split:
- **Script (GitHub Actions, no model):** every mechanical check in section 3, the one fix-up PR, the report, the
  running-label and timer flags. It starts without Ryan, costs no tokens and no GPU.
- **Muse (Ryan starts it):** one judgment pass per hand-over, on a short pack: the lint table, the flagged conflicts,
  the handful of quotes in doubt, and the diff of the fix-up PR. It names the later word and the fair reading. It never
  edits layer 1 or decides a rule.
- **Board:** owns the conflicts Muse escalates, merges the fix-up PR, and asks Ryan only for his own words or a rule
  change.

What Muse needs: the standing brief on issue 256 (so it reads one place), read-only repo access, a cap of about 30 to
45 minutes of agent time, a fixed output path, and the hard limits in section 3. What it must not need: the PC, the
GPU, a GitHub write token, or Ryan awake for the nightly.

---

## 7. The librarian itself

### (a) How it runs

| Trigger | Seat | What it does | Starts without Ryan? | Cost per run |
|---|---|---|---|---|
| Every push to main and every PR branch | GitHub Action (the existing `standing-checks` job), plus a new `memory_lint.test.js` row | all mechanical checks; fail the PR on a hard violation | yes | about 1 to 3 s of Node inside a job that already runs |
| Nightly, 09:00 UTC | GitHub Action on a schedule | lint; if drift, open one fix-up PR and one report issue; if clean, post nothing | yes | about 1 minute of ubuntu; no model |
| Every merge | the push run above | re-check; a merge is the natural enforcement point | yes | same as push |
| Every hand-over | the retiring Board, then Muse when Ryan starts it | lint, rewrite HANDOFF from the pages, Muse judges the flagged conflicts | Board yes; Muse needs Ryan | one Board command; one Muse run at the hand-over |
| Every PC job start and report | the PC runner (`tools/pc/work_issue.bat`, `codex_issue.bat`) and the Board for sandbox workers | set or clear the `running` label and edit the one status comment with `gh` | yes | two `gh` calls, no model |
| When a timer fires | whoever made it, via the chat; the nightly Action for repo timers | re-read the current-truth page named by the timer before acting | yes | one command; one Action minute |

The nightly job needs `contents: write` and `pull-requests: write` only. It does not need a model, the PC, the GPU or a
chat. If GitHub Actions is down, nothing is lost: the next push runs the same checks.

### (b) How it works

**Inputs, in reading order:**
1. the layer-1 record of Ryan's words (the only owner source);
2. the current-truth pages;
3. `contrib/opus/FINDINGS.md` (history and R rows);
4. `docs/RULEBOOK.md` (rules and reasons);
5. open issues and their bodies (scope and the "run 2" problem);
6. open PRs and their bodies and checks;
7. `contrib/opus/LOOP.md` (the log and the running prose);
8. `HANDOFF.md` (the hand-over);
9. scheduled reminders (the timer page and the chat notes);
10. the `running` labels and their status comments.

**Checks in order:** the twelve mechanical checks in section 3, cheapest first (schema, then citations, then
supersession, then one-home, then freshness, then GitHub state, then timers, then briefs, then paths, dates and size).
Stop at the first hard failure that would make later checks meaningless (for example, a schema failure in one page
skips that page, not the whole run). Every check prints PASS, FAIL or SKIP with a file and line.

**Output:**
- one fix-up PR per sweep, on `opus/memory-<date>` (or `muse/memory-<date>` when Muse runs it), containing only
  mechanical fixes: citations, pointers replacing copies, removal of lines whose supersession is already recorded,
  HANDOFF range update, LOOP roll count, generated open-work table, expired timers, dead paths;
- one short report in the PR body and as an issue comment on the tracking issue: the check table, what it fixed, what
  it flagged and did not fix, and what it refused to touch;
- no PR when the tree is clean (quiet by default);
- a single digest to the Board, not to Ryan.

**What it fixes itself versus flags:**
- fixes: a citation that resolves to the wrong row or a dead path; a copy that should be a pointer when the home is
  unambiguous; a superseded line whose supersession is already recorded in FINDINGS or RULEBOOK; the HANDOFF range;
  the LOOP roll count; the generated open-work table; an expired timer with a recorded end; a missing row for an open
  issue.
- flags only: any quote mismatch; any two live values for one key; any Board choice written as a rule; any issue or PR
  state it cannot read; any "run 2" body; any running label past cap; any secret in a word entry; any semantic
  contradiction between pages.

**Hard limits:** section 3, "What it must never do". The most important three: never decides a rule, never edits Ryan's
words, never closes an issue.

### (c) Skills and tools

A new `.claude/skills/repo-librarian/SKILL.md`, written like the existing three: a pointer, not a copy. It should say:
- when to run (nightly, push, hand-over, after a conflict);
- the three layers and the schema, pointing at `docs/memory/SCHEMA.md` and `docs/memory/README.md`;
- the twelve checks, pointing at `contrib/opus/tools/memory_lint.js`;
- the output contract: one PR, one report, quiet when clean;
- the hard limits, verbatim;
- the quote discipline: the owner's words verbatim, with time and chat, never a summary;
- the writer rules for other agents: log the words, cite the line, rewrite the brief, set the label.

Existing patterns that fit:
- the LLM wiki pattern's ingest, query and lint maps exactly to layer 1 (ingest), layer 2 (query) and the lint script.
  No external agent-skill package is needed; the three local skills are the right form.
- `contrib/opus/tools/doc_check_tests.js` is already the first lint. The new work is the citation, one-home,
  supersession, timer and running-label checks, not a new framework.
- `contrib/opus/tools/run_all_checks.js` is the gate. A new test file must be added there or GitHub never runs it
  (the job's own rule). The new file is `memory_lint.test.js` with planted fixtures.
- `contrib/opus/tools/naming_lint_game.js` and `checks_baseline.json` are the precedent for a baseline and an allowlist:
  a known violation sits on a list that can only shrink, and a new one fails.
- `docs/REVIEW_PROTOCOL.md` supplies the evidence discipline for the report: file, line, exact quote, OBSERVED or
  INFERRED, and "Not checked".

### (d) How every other agent works with it

| Seat | One or two things per turn |
|---|---|
| Any chat that hears Ryan | append his words verbatim, with time and chat, the same turn; cite the line it writes |
| Board | set the running label and status comment when it starts a sandbox worker; run the lint at hand-over and rewrite HANDOFF from the pages; route flags |
| PC runner | set and clear the label and comment in the same step as start and report; stamp the branch's last commit time as the heartbeat |
| Muse | in an outside check, name the owner quote and the R row for each finding; at hand-over, judge the flagged conflicts |
| DeepSeek, Qwen, Grok, Flash | cite the brief line or owner words they rely on; never write a new rule from a Board note |
| Ryan | nothing new: he keeps talking in his chats, and the new rule that a new scope is a new issue (2.9) already fits |

### (e) How we know it works

A fixture test, `contrib/opus/tools/memory_lint.test.js`, with planted faults seeded from the real failures. Each
fixture has one expected FAIL line and one expected PASS after the fix-up:

1. F1 and F2, the fighter: two word entries in different chats, a page line citing only the earlier one, and a
   `factions.md` row with a quote that exists in no entry. Expect FAIL on "quote not in record" and "two live values
   for ship:sunward:fighter". After the fix-up, the later word (09:04 "Sf3 is right") is the live line and the earlier
   one is marked superseded.
2. F3, the Eclipse doctrine: `factions.md` says guns never fire through the shade; `designs.md` says they do; the E14
   ring is flat in one and upright in the other. Expect two one-home failures.
3. F4, the hand-over range: a fixture HANDOFF naming a range four rulings behind. Expect the existing doc_check FAIL.
4. F5, the self-contradiction: a status page with "SF3 stands" and a waiting line asking SF3 or SF4. Expect a
   same-key conflict.
5. F6, a Board note as a rule: a RULEBOOK-shaped line with no owner citation and a source marked Board. Expect "rule
   without owner words".
6. F7, the timer: a page entry "close the GPU window at 07:30" with no end and no re-read target, plus a later word
   extending the window. Expect "timer acts on a mutable fact without a re-read".
7. F8, the brief: an issue body with a second "Brief:" block or a "run 2" note. Expect "brief appended; rewrite or new
   issue".
8. F9, the PR body: a runner fixture where a push replaces the body. This is not a lint on prose; it is a runner
   selftest case: save the body, push, restore. Expect "body preserved".
9. F10, the ledger: an open issue with no row. Expect "open issue has no row".
10. F11, the seats: a seat page and a launch page disagree on Kimi. Expect "two live values for seat:kimi".
11. F12, running: a label with `started` four hours ago, cap two hours, no commit since. Expect "running past cap".
12. F4 again, as the regression test: the real HANDOFF must pass after the librarian fixes it, and `doc_check_tests`
    must stay PASS on main.

Add `memory_lint.test.js` to `run_all_checks.js`, so GitHub runs it on every PR. The test is the proof: plant the
failure, watch the lint fail, fix it, watch it pass. A nightly "mutation" run can take main, plant one known fault in a
scratch branch, and assert the same failure.

---

## 8. Mapping the always-on agent article

The article is the one Ryan sent on Nov 15 08:31 (`https://claude.com/resources/articles/building-always-on-agents`).
It names five primitives and seven practices. I map each to this repo, with what we have, what is missing, and whether
it is worth adding. My short answer: the repo already has an inbox (issues), a timer habit (chat `send_later`), memory
(FINDINGS, RULEBOOK), permissions (labels, branch shapes, no self-merge) and an outbox (PRs). What it lacks is one
inbox for Ryan's words, a timer registry with revalidation, and a curated memory pass. Those three are worth adding.

| Primitive or practice | What we have | What is missing | Worth adding? |
|---|---|---|---|
| Event inbox | GitHub issues are the job inbox; the PC queue is a real one-at-a-time inbox (`tools/pc/watcher.bat`); issue 256 is Muse's | one inbox for Ryan's words: they arrive in two chats, and that is F1 and F2 | Yes. Layer 1 is the inbox of record. No new system: one append-only folder in the repo. |
| One active worker per inbox | the PC queue runs one job at a time; one Codex job; the Board lock (`contrib/opus/LOOP.md:5-11`) | a chat or sandbox worker can start without a label, so two workers can hold one issue | Yes. The `running` label is the claim on the issue. A job with no label is not running. |
| Timers, one-off | chat `send_later`, used for check-ins (`contrib/opus/LOOP.md:58`) | a record of what the timer will do and what it depends on | Yes, but only as a page. The 07:30 failure is the proof (F7). |
| Timers, recurring | the PC watcher loop and the Codex board watcher every 10 minutes; no repo-level schedule | a recurring schedule that fires into the inbox, not into a chat memory | Yes. A GitHub Action cron is the natural home; it fires into GitHub, which every seat can read. |
| Memory: only what cannot be looked up | FINDINGS, RULEBOOK, LOOP, HANDOFF; build sheets and concept pictures | the rule is violated: HANDOFF and OPEN_WORK restate GitHub state (F10, F12) | Yes. Keep only owner words, the current truth, and why; point at GitHub for the rest. |
| Memory: pointers to the issue tracker | OPEN_WORK names issues and PRs | it also copies their state, so the pointer is buried in a summary | Yes. A pointer table with issue number and one "waits on" cell. |
| Dreaming: curate and replace outdated entries | Muse audits "now and then" (RULEBOOK 0.10); the Board rolls LOOP at about 15 | a regular pass that removes superseded lines and compacts status | Yes. This is the nightly librarian sweep. It is the same shape as "dreaming": read, curate, replace, do not append. |
| Save key facts before compaction or a new session | HANDOFF section 0, LOOP LATEST, FINDINGS | the owner words and the in-flight state are not saved automatically; a server restart loses the workers (F12) | Yes. Layer 1 and the `running` label are exactly "save the facts before compaction". |
| Starting quiet, earning attention | RULEBOOK 1.6: message Ryan only when something lands or needs him (`docs/RULEBOOK.md:97`) | no measure of how often that rule is broken | Yes, a small one: the nightly report is silent when clean; the monthly count of messages is the eval. |
| Permissions | labels (`codex`, `muse`, `opus`, `ryan`, `blocked`), branch shapes, no self-merge, the PC lock, the GPU go file | no single table of who may write what, and the librarian's write scope | Yes. One table in the schema: each seat's write scope. The librarian writes only its own branch. |
| Outbox | PRs, issue comments, messages to Ryan | duplicate PRs on a re-run (`contrib/opus/LOOP.md:119`); a later push can erase the body (F9) | Yes. One fix-up PR per sweep; dedupe by branch name; save and restore the PR body. |
| Evals for message volume | none | a count of PRs, issues and Ryan messages per day, and a target | Worth a small one. It tells the Board whether the librarian is earning its attention or making noise. |

The Board's starting list of gaps holds up, with one correction:
- no single inbox: confirmed (F1, F2).
- no timer registry: confirmed (F7). But a registry alone is not enough; the firing action must re-read the fact.
- LOOP and HANDOFF copy state GitHub holds: confirmed (F10, F12). Fix by pointing and by generating.
- no in-flight record that survives a restart: confirmed (`contrib/opus/LOOP.md:71`, `HANDOFF.md:26`). The `running`
  label is the right home because it lives on GitHub, not in a sandbox that can restart.

---

## 9. Ryan's follow-up: is the repo the source of truth, and does one home per fact work?

**Verdict: the principle is right and the repo should be the one source of truth for every seat. The proposal holds
for GitHub facts and breaks in four places unless it is enforced.**

Where it holds:
- Issue open or closed, owner, PR state and checks are already the best record, and every seat can read them with
  `gh api` REST. LOOP already says to read them (`contrib/opus/LOOP.md:52`).
- The repo is the only place all seats can read: Ryan said it (RULEBOOK 2.15), and the public repo is how Muse's
  models read it (RULEBOOK 3.10).
- "One home per fact" is the correct test. The live failures are all duplicate homes (F3, F11) or a copy that drifted
  (F4, F10).

Where it breaks, and what to do:
1. **Ryan's words are not in the repo.** They arrive in two chats, and the repo holds only summaries. That is how F1
   and F2 happened. GitHub cannot hold them, so layer 1 must. The Board's answer should say this explicitly: the repo
   is the source of truth only for what has been copied in, and the copy needs a time, a chat and a verbatim quote.
   The honest limit: the lint can prove that a later line agrees with the copy, not that the copy equals the chat. When
   two chats heard the same words, require both copies and flag any difference; that is the only cross-check the repo
   can run.
2. **Status files still restate GitHub.** `HANDOFF.md:26` says "Running. Opus workers 780, 781, 726";
   `contrib/opus/OPEN_WORK.md:13` says "WAITING ON green CI". These are the exact things the proposal says to stop
   doing. A rule in a document is not enough; the lint must fail a prose status line, and the pages must be generated.
3. **The `running` label plan is sound but needs four details.** (a) One status comment, edited by id, never appended.
   (b) A cap and a heartbeat: `started` in the comment, and the branch's last commit time; the librarian flags a label
   past cap with no new commit. (c) The PC runner and the Board must set the label in the same step as the start, and
   clear it in the same step as the report; a server restart must not lose it because it lives on GitHub. (d) A job
   with no label is not running, and the old board watcher must check the label before it re-queues (this also fixes
   the duplicate-run trap at `contrib/opus/LOOP.md:118`). What breaks: the label and the comment are two writes, so a
   crash between them leaves one; the lint should treat a label with no comment as a failure, not a pass. The PC
   runner needs `gh` logged in; if it is not, the job must say so and not start. The repo is public, so the status
   comment must never name a token or a private path.
4. **"HANDOFF and LOOP keep only what GitHub cannot hold"** is the right list: Ryan's words, the current truth, why a
   choice was made, and what to do next. In practice they keep a fifth thing, "what is running", which GitHub can hold.
   Move that to the label and the comment, and the hand-over drops to about one page by itself.

What else Ryan should decide (one question, because it changes a rule):
- May an append-only layer-1 file go straight to main under the same docs-only exception as LOOP and FINDINGS, or must
  it ride an agent branch and a PR? My pick: allow the append-only record to main, because it is never edited and the
  merge is the record. The alternative delays the one thing that must be captured the same turn. Either way it should
  be written in the RULEBOOK, not left to habit.
- The public-repo risk: a verbatim quote can contain a secret or personal detail. My pick: a secret scan blocks the
  write, and the only edit ever allowed in layer 1 is replacing the secret with `[redacted]`, with a note. That is a
  narrow, stated exception to "never edit Ryan's words".

If those two are settled, the Board's answer holds up: GitHub is the source of truth for GitHub facts, the repo is the
source of truth for owner words, current truth and why, and the librarian is the thing that keeps the second honest.

---

## Not checked

- The other legs of this review (`contrib/muse/reviews/repo_memory_788.md` and the Board's synthesis): not opened, to
  keep this leg blind.
- GitHub itself: I did not call `gh` or the network, so issue bodies and PR bodies are read through the repo's copies
  and LOOP's quotes, not live. A live check may find that some of the drift in F4, F5 and F10 is already fixed on
  GitHub but not in this checkout.
- The exact content of Ryan's chats: I read the quotes as recorded in the repo. I did not verify them against a chat
  transcript, which the repo does not have. That is the gap layer 1 is meant to close.
- The newspaper article's full text beyond the five primitives and seven practices named in the job brief: I mapped
  from the brief's list, not from a fetch.
- The UI and the PC runner: no run, no screenshot. This leg changes no visual or runner surface.
- Parity: not run, because no rule or game file changed. The runner runs it after this leg.

## Recommended next step

Build the smallest useful version first, not the whole design: (1) the layer-1 folder and the writer rule; (2) the
citation, one-home and supersession checks in `memory_lint.test.js`, added to `run_all_checks.js`; (3) the generated
open-work table and the HANDOFF range fix; (4) the `running` label in the PC runner and the Board. That is enough to
catch F1 to F10. The nightly Action and the Muse judgment pass come after the lint is green on main, so the first
build is provable on its own.
