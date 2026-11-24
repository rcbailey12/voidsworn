# Embers of the Hollow Sun: the rulebook

The index and shared rules for the whole project (issue 492, FINDINGS R190). Each rule says what to do, why (the problem
Ryan was reacting to, in his words where they exist), who set it and when, and its old ids. Rules of play and balance numbers
are not here (R190's scope): they live in the browser oracle, godot/rules and their FINDINGS rows (for example battles growing
over a run toward about 20 ships, a guide and not a cap, R1; capture as add, strip or ransom, R4).

Ryan, Nov 11 2026: "Those old hard coded rules with no context or detail artifically restricing us are exactly what I'm worried
about across the board" (R190), and at 20:05 CST: "Let's ensure we're documenting all these decisions and approaches. I don't
want this drift to keep happening or where we get confused on how we're doing things."

Set by: **Ryan** (his own call, his words exist), **Board** (a Claude Board thread wrote it), **agent** (Muse, Codex or a
worker). Ids are FINDINGS rows (R, D, F, G, X) or register ids from contrib/opus/reviews/rules_sweep/.

## 0. How rules work here

0.1 **Every rule carries its reason, beside it.** Why: three old rules with no reason were built to the letter on Nov 11 (sliced
wrecks R186, the flash counter R187, the movement call R189). Ryan: "I think some of the findings got misinterpreted." Set:
Ryan, Nov 11 (R189, R190). A rule nobody can give a reason for does not go in this book.

0.2 **A ruling is landed only when the same pull request edits this book or the working document for its area** (the
playbook, RECIPE.md, AGENTS.md). Why: rulings filed in FINDINGS never reached the documents builders read (R209, R211). Set:
Ryan, Nov 11 (R214). FINDINGS stays as the dated history; this book is the live source. Each FINDINGS row from R281 on
says where it landed ("landed in <repo path>") or says "one-off job decision"; the memory lint
(contrib/opus/tools/memory_lint_tests.js) fails a row that says neither, so a ruling cannot sit in FINDINGS alone (R291,
issue 890).

0.3 **Which document wins.** This book; then the playbook for the area; then AGENTS.md; then briefs. HANDOFF.md and LOOP.md
win for current status only. Between two of Ryan's rulings the later one wins, and the entry here is edited, never only a new
FINDINGS row. Why: corrections written as new rows left the old wording reading as the rule (R183's withdrawn gate line).
Set: Board, Nov 11, from Muse's outside sweep (contrib/muse/reviews/rules_sweep_2026_11.md, Parts 4 and 6).

The numbered rules in the path-scoped files linked below are part of this book and have the same priority. Claude Code
loads them when it reads matching files. Other seats follow the section links when working in that area.

0.4 **A number in a document is a starting point judged by eye, unless it protects comfort, frame rate, saves, crashes or rules
parity.** A number names its measurement, or says it is a tuning value. Why: every hit size was tuned under a cap that was
never the guideline it cited (R187); Ryan wanted the audit to find "these weird arbitrary, like, guidance on that is making
it, you know, more restricted and less realistic and cinematic than it should be". Set: Ryan, Nov 7 (R121: assumed gates stop
binding until a measurement earns them back) and Nov 11 (R187: "Keep comfort, loosen rest").

0.5 **Order follows the faction; motion and breaks never feel staged.** Hullbreaker armour is irregular patchwork. Eclipse
panels are precise, dead even, ordered and aligned, with seams and slight relief (Ryan, Nov 13, R243: "make the eclipse panels
actually panels and dead even and ordered to align"). Glasswrights are blown glass without panels; Chorus surfaces are grown,
without plates. Sunward and Hegemony follow factions.md. Instant motion, identical beats, straight cuts and one scale still
read as staged. Why: the wrecks "feel like they're just getting sliced in half" (R186); applying that to every faction's
surface erased the Eclipse's machine precision. Set: Ryan's complaints, Board's wording (R187), corrected by Ryan (R243).

0.6 **A rule that rests on a fact that can change names what ends it** (a model's version, a plan's limit, a tool that is
down). Why: the Codex cloud ban, the Fable helper counts and the Kimi sentence outlived their facts. Set: Board, Nov 11 (Muse
sweep Part 4).

0.7 **A rule that says the game does something needs a capture or a check that shows it, or the words "not built yet".** Why:
specs described braking jets and slow motion the game did not have (issue 492). Set: Board, Nov 11.

0.8 **After a day with many rulings, the Board has an outside model check that each one landed in the document a worker reads
(a dropped-context sweep).** Batch rulings that only set a rule (no working method) may land in this book alone. Why: the
insides rule was recorded but never reached the builder's playbook (R209, R211); Muse's method audit found
the screens half of R218 written nowhere (issue 558). Set: Board, Nov 12 (R211, issue 558).

0.9 **How a route is set up (any multi-step pipeline: ships, effects, captures, installs).** (a) A method change is done
only when one real item has gone end to end through it into the game on Ryan's PC; each stage passing alone is not a pass.
(b) Each fact has one home: the first step that decides it writes it, and every later step reads it from there instead of
keeping its own copy; a mirror refreshed from that home under a check (the oracle copies, 12.4) is not a second home. (c) A check tests what its rule says and reads the item's own numbers (length, seams, part shapes),
never the shape of the first item it was written for. (d) Anything Ryan's PC runs (.bat launchers, installs, caches) gets
one real run there before it counts as done, within 3.3 (nothing deleted on the PC without Ryan's yes). No new test or gate is added for this rule; it shapes how routes are built
and briefed. Why: Codex's A16 dry run (issue 587) found eight gaps from these four habits: the build sheet and the recipe
kept separate copies of the same facts, three checks assumed the old C15s cruiser (its 14.5 length, an extra seam,
closed engine bells), a launcher quoting bug and a stale game cache only show on Windows in a real install, and no ship
had gone from sheet to game since the sheet method changed. Set: Board, Nov 12, on Ryan's ask to learn from the gaps at
the level of design and setup, not patches (R225).


0.10 **How the repo carries memory (R251).** A standing rule comes only from Ryan's words, quoted in FINDINGS and landed here; a row
that stretches his words past what he named says so and asks him. Board choices for one day or one job (effort, caps, job order,
wrappers, which seat took a job) are operating notes in LOOP.md, never rules. A new ruling names what it replaces and the old row is
marked SUPERSEDED, so no two live rules conflict. One live place per kind: rules in this book, what is open and who has it on GitHub itself
(checked live before any dispatch), what runs on the PC in LOOP.md's newest LATEST lines and The seats, the hand-over in HANDOFF section 0 (about one page; older sections go to docs/archive), history in FINDINGS.
LOOP.md's LATEST lines roll into a dated summary once they pass about 15. Muse audits for stale or conflicting docs now and then.
Why: several models and fresh chats read the repo cold; on Nov 14 a one-day choice nearly became a rule, an A20 note was stretched to
every ship before Ryan ratified it (R244), and a summary line inverted Ryan's call on A18 and A19.

0.11 **Claude Code runs the no-exception checks as hooks.** The [hook setup](../.claude/hooks/README.md) covers seat
assignment, credential protection, direct pushes, punctuation and the Godot parse check. Tool calls and turn endings give
workers feedback before review (issue 1660).

## 1. Working with Ryan

1.1 **Plain words, the answer first, your pick and why; no em dashes; no human-hour estimates** (estimate in agent runs and
review rounds from the board's own history). Why: he is not a coder; and "every time estimate has been wildly off. its human
based, not multiple LLMs and agent based." Set: Ryan (AGENTS.md; R99, Nov 4). Ids: agents-31, agents-36, R99d.

1.2 **Pictures for anything visual: one per item, its code name on it, about 1280 px wide and no taller than 720 px.** Why: he
judges by pictures, cannot see tall stacked sheets, and "I can't tell which one is a11" (R185). Set: Ryan (R185, Nov 11);
sizes Board (HANDOFF). Ids: agents-32, handoff-05, R185c.

1.3 **When Ryan points at a picture from memory, find it and show it with its code name before building on it.** Why: the
Board read "our prior concept" as the wrong picture and three rounds were drawn against it (R196). Set: Board, Nov 11.

1.4 **Anything he runs himself is a double-click .bat** (Windows 10, PowerShell 5.1, no Python of his own). Why: not a coder.
Set: Ryan. Id: agents-33.

1.5 **Before anything bigger than a quick fix, ask 3 to 5 plain multiple-choice scope questions in one batch**, each choice
said as what he will see. Why: he steers by picks ("Options first, then build", R167). Set: Ryan. Ids: agents-34,
musebrief-03.

1.6 **Questions for Ryan go to him in the agent's own chat, never as GitHub tags or comments; message him only when something
lands or needs him: two lines and one image.** Why: his own instruction on where he reads (Nov 2) and what he wants to see.
Set: Ryan. Ids: agents-11, loop-05.

1.7 **Picks, looks and money are Ryan's.** Payments, top-ups and sign-ups stay his. Why: his game and his accounts. Set: Ryan
(AGENTS.md seat table; R126b).

1.8 **Ryan's non-urgent picks go in two numbered Pick Sheets a day, Morning and Evening; he answers in the form `1=B, 2=Yes`.**
Product and visual calls that can wait are batched there, each with its pick and one current labelled picture. Outside the
sheets the Board interrupts him only for an emergency: PC disk under 75 GB, a key to paste, or a stuck job to kill. Why:
"Move Ryan's non-urgent product/visual calls into two numbered Pick Sheets per day (Morning and Evening, format `1=B, 2=Yes`).
Only interrupt outside that batch for emergencies (disk <75 GB, key paste, stuck kill)." (Ryan, Nov 22 2026, 12:09 UTC, owner decisions of the studio ops upgrade plan, thread "Upgrade studio ops and PC harness"). Set: Ryan, Nov 22 (R408).

## 2. The Board and the agents

2.1 **The Board owns the whole board.** One Claude thread in the Project (Opus 5.5 since Nov 11) holds design calls, the final
technical call and every merge; it starts agreed work on its own, picks the seat, keeps the open GitHub issues moving, and
asks Ryan only for design, key decisions, reviews of what he will see, and conflicts. Why: agreed items were left behind
whenever new work arrived ("The station is a good example of something we already aligned on but is still sitting there",
R194); and "you own the codebase and github. you are my orchestrator and control the building" (R202). Set: Ryan, Nov 8 to 11
(R119: "sure merge, you're the owner now"; R167, R194, R202). Duties: contrib/opus/LOOP.md "The Board's standing duties".

2.2 **Nobody grades their own work.** Workers never merge their own pull requests. An Opus-built, game-facing change gets an
outside check (Muse, issue 256) before or straight after merge; a tools-only pull request that other jobs wait on may merge on
the Board's diff review while Muse is idle, with the check still asked for. Set: Ryan (R119, R132, R133, R167); the exception
Board (R162). Ids: agents-13, claude-04, R132c, R162b.

2.3 **Review every pull request by its diff, never its title, then sweep its impact** (every caller, saves and old profiles,
the Godot rules and their saved results, every UI path, which tests really ran), then the pictures. Merge only on green, and only after every check
job has finished. Why: a merged change left existing profiles with Heat closed (R129); PR 542 merged before its parity jobs
ended (LOOP, Nov 12). Set: Board (R129); Ryan's project instructions. Ids: R129a, loop-03.

Pictures carry their revision and stage. Every picture shown to Ryan is labelled with the revision that produced it and its
stage (sheet built, paint proof, installed in game, cloud direction check for a cloud, software or placeholder render (issue 1567), Ryan accepted); a stale picture is never shown as current, and if the
picture is stale the review stops there rather than judging it. A visual pull request merges only after its picture has been
compared with the concept and the ruling it answers, in a view that actually shows the feature being judged, and the Board
says plainly in the pull request where it misses. What a ruling can measure is measured on the painted output and reported
(the plate-character measure, issue 875); passing the countable checks is not visual acceptance. Why: the painted ships
passed fit, weapon match, triangles and density while missing their rulings, and a pre-fix picture was shown as the fix
(R289). Set: Board, Nov 16 2026 (issue 880).

2.4 **The job board is GitHub issues with owner labels, each opening with the fixed block** (Owner, Brief, Deliver to, Branch,
Effort or Models, Done when; optional `Base: <branch>`; ship builds add Route per part, Inside, Paint stack, Budget, R214). Agents deliver on
`codex/`, `muse/`, `work/` or `opus/issue-N` branches; nobody pushes to main except LOOP.md and FINDINGS. Why: any agent can
pick up a job without asking, and main stays reviewed. Set: Ryan, Nov 2 and 4 (R75, R102). Ids: agents-04, agents-05,
agents-09. A run brief for a PC job goes into the issue body (under the fixed block, marked as the job now): the runner
builds the task from the body only and never reads comments (R281).
When the Board needs Ryan's answer on a job, it adds the `ryan` label and one issue-body line `Ask Ryan: <one question> | Picture: <link>`, then removes both when he answers; Mission Control reads only this marker so it cannot mistake a dispatch lock for a question (Ryan, Nov 17, issue 951).
The PC runner merges `origin/<branch>` from the optional Base line and commits that merge before starting the agent;
a conflict stops before the agent with the checkout kept. Briefs name Base instead of asking an agent to merge while
also forbidding commits. The runner sets the running label and one status comment per job branch (edited in place on
retries and at the end), naming seat, machine, lane folder, branch, start time, ceiling, last commit and how to resume.
Before checkout or model calls, every PC runner refuses closed or running jobs and a delivery branch or open PR for the job from another seat prefix (same-prefix reruns are allowed); a body with exactly one fixed block and no run history needs no marker and is passed whole, otherwise exactly one line outside code fences containing `THIS IS THE JOB NOW` in heading, bold or plain form selects the fixed block plus that run; Effort (Codex) is required only for Codex, and the label and status comment must be set and read back before work, while later reporting failures are logged without changing the result (R291, issue 888). It clears its own running claim at the end. Why: merge-left partials
on 800, 815 and 44, and jobs with no visible running seat. Set: Ryan R270, issue 846 (788 step 3).

One current instruction. A job's current run brief sits at the top of its issue body, under the fixed block, marked as the
job now; older runs are marked done in the body. A brief in a comment is not an instruction: the PC runner builds the task
from the body only, so a comment brief silently reruns the old job. Why: 373 run 3 was briefed in a comment and came back
as a rerun of run 2. Set: Board (R281).

An open issue is not proof the work is undone. Issues here stay open after their pull requests merge (2.5), so before
queueing or relabelling an issue, search for a merged pull request that names it; on every merge, close the issue in the
same step when its scope is done, and where a merge is partial, say what scope remains. Artoo's dispatch sweep (2.7)
lists open issues with merged pull requests before each queueing round; the sweep is the audit, not the mechanism. Why:
780, 781, 783 and 824 were queued again after pull requests 796, 787, 825 and 832 had merged (Ryan: "Why did you miss all
those old jobs were already merged? That's a big miss."). Set: Board (R288).

2.5 **Never write a GitHub closing word before an issue number in a commit; use `gh api` REST, never GraphQL.** Why: commit
1429ca3 closed PR 320 by accident; GraphQL is blocked here (ends when it is unblocked). Set: Board. Ids: loop-15, loop-20.

2.6 **The seats.** Ends when a seat's plan or model changes; the live state is LOOP.md "The seats".

| Work | Seat | Why |
|---|---|---|
| Board: reviews, merges, specs, visual calls, picks put to Ryan | One Claude thread, Opus 5.5 | judgement is the bottleneck (R128, R194) |
| Every ship model in Blender (blockouts, build sheets, hulls, kits, the station); hard or open-ended builds; read-only code audits | Opus 5.5 workers; not capped while Ryan's ultra plan clears the backlog (Ryan, Nov 19), back to two or three at once when it ends | Ryan: "I think builds in blender should come from Opus" (R205); the earlier "keep it to 2 or 3 threads at once, and propose big threads before starting them" (project instructions) is lifted for the backlog push (Ryan, Nov 19) |
| Well-specified code: rules, tests, scripts, screens to a spec | DeepSeek V4.1 Flash workhorse on the PC | merged on one review pass for nine cents (R127, R134) |
| Pipeline and engine jobs that need Codex's depth (export, import, effects plumbing); captures and benches only when no cheaper seat can run them | Codex on the PC, up to four local lanes, one job per lane (lanes C and D code only; R268, R301), while its weekly usage lasts | "Codex and deepseek should do other work to free you up on these crucial items" (R206); "We're starting to run low on codex usage ... We may just need to move other things to opus instead of codex being the workhorse with DeepSeek" (R219) |
| Checks of a seat's own work: a different model checks it (Codex's pipeline work is traced or checked by Opus or Muse) | Opus worker or Muse | "It feels like that makes sense to be checked by a different model" (R219) |
| Concept pictures by image to image, research, design text, outside checks | Muse (Rey chairs); Ryan starts every run | several models, an outside view (R128) |
| Ideation and legs | Grok and Google Flash, through Muse: a leg in every Muse action, beside DeepSeek and Qwen (R231) | free and broad; Qwen's daily cap emptied three seats on Nov 12 |

The standing seat rules (rewritten Nov 15 from Muse's opus_check_719; dated seat state, such as whether this month's API
credit is live, is status and lives in LOOP.md "The seats"):
- Seat order (R242): "DeepSeek for cheap, sonnet for mid size, opus via api or helpers for blender or other large work. Codex
  for others that only it can do and then Kimi depending on results."
- Blender ship builds are Opus's (R205: "I think builds in blender should come from Opus"), back on from Nov 14 evening (R253).
- Codex only for what no other seat can do (R234: "use it when it can only do something others can't"); GPT 6.1 Sol (2.7).
- Kimi is no longer a seat (R257, Ryan, Nov 15: "Kimi is maxed out until 12/12. I just cancelled. I don't think it's worth
  continuing given the usage issues"). Its jobs go to DeepSeek (mid-size code) or an Opus worker; nothing is sent to Kimi.
- Codex is on the Pro plan (R264, Ryan, Nov 15: "it's on the pro plan, so significant usage upgrade") and runs up to four local
  lanes (R268; the fourth, lane D, is code only: R301, Nov 16). SUPERSEDED, kept so nobody follows it: "Codex is near its weekly limit ... the Board runs the PC GPU steps" (R257,
  ended by R264 the same day).
- The API arms (opus, sonnet) run on the Max plan's monthly API credit (Ryan, Nov 12); same model family as the Board, so never
  the different-model check of Opus work (R219).
- The Board thread may use the Fable advisor (R252: "this chat stands"; none is visible in the Project Board thread on Nov 16, so no document claims it is on); no Fable helpers (R180); not taken: Gemini 4 Hydrogen
  (R250).
Superseded, kept so nobody follows them: "Kimi on its own subscription only, no API route (R238), through the Kimi Code CLI
arm; it stays (R250 item 4)" (SUPERSEDED by R257); "the Kimi Code plan holds about 30 minutes of agent work per 5-hour window, so it takes
short reviews only, never builds" (Nov 12, the OpenCode route; SUPERSEDED by R250) and "Codex is the main builder, Blender builds
included" (Nov 14; SUPERSEDED by R253). Ids: R128, R180e, R205, R206, R219, R234, R238, R242, R250, R252, R253, R257, agents-12.

2.7 **Codex runs the model Ryan picked: GPT 6.1 Sol today, pinned by name in tools/pc/codex_issue.bat.** Never a weaker
model by accident (Luna) and never switched to another one (Astra) without his yes; no Codex cloud tasks or cloud reviews,
because a cloud task runs the default model OpenAI picks and cannot be pinned (OpenAI's Codex models page, Nov 2026). Code-only
jobs run on a third local lane on the PC instead (lane C, R268, Ryan Nov 15: "yeah lane c is fine"), pinned like the others.
If OpenAI lets cloud tasks pin a model, this can be asked again.
Why: "We don't want to force using Astra or something. Just not accidentally run Luna or something, that's why we usually
use Sol 6.1" (R216). Ends when Ryan picks another model. Set: Ryan, Nov 2 (R75), Nov 11 (R216) and Nov 15 (R268). Ids: R75b, R268, agents-07.
Exception (R270, R295): Artoo, Ryan's ChatGPT dot, is an independent technical reviewer. It runs in OpenAI's cloud and
comments by itself, with no approval from Ryan per post, on pull requests and issues (one PR's findings on that PR; general
sweeps on the standing issue 906). Its scope is merge issues, bugs and other technical problems, never design or taste. Every
comment starts with "Artoo (technical review):", because it posts through Ryan's account and must never be read as his words,
and names the commit it read. It never pushes, edits files, merges, closes, relabels or decides a rule; every finding is checked
by the Board against live main before anything changes (0.10), and the Board replies with what it did. Before each merge the
Board reads the PR's Artoo comments on its current head commit and settles each one first. A finding that does not block
the merge, or arrives after it (Artoo's or Muse's), is settled the same day: the Board fixes it in that turn or adds one line
for it on issue 906 (fixed, queued as issue N, or declined and why). Why: the Nov 17 audit found five such findings (PRs 910,
919, 924, 937, 571) with no reply and no tracking item, one of them six hours old, while blocking findings were answered in
minutes (Ryan approved the audit fixes, Nov 17). Artoo went live Nov 16 (it wakes on
PR events and checks issues about hourly). Why: "i want artoo
commenting independently by itself for those comments and reviews. it shouldn't impact design or taste designs but looking for
merge issues, bugs or other technical issues, absolutely should be independent" (Ryan, Nov 16, R295; replaces R270's read-only
librarian clause).

2.8 **Muse: a blind Rey leg written before Rey reads the others, on research, design and review jobs** (not on low-code fix
jobs). Why: "Let's ensure muse is running its own blind leg room not just chairing." Set: Ryan, Nov 3 (R89). Ids: R89,
agents-10, muse-07. Every Muse action (research, design, review and outside checks, and low-code fixes) runs legs from DeepSeek, Qwen,
Grok and Google Flash, with Rey chairing. Why: "let's have muse use grok and Google flash LLMs in all its actions too" (Ryan,
Nov 12, R231); more outside views, and no check runs on one leg when a model hits its cap.

2.9 **A Muse issue is never edited once Ryan may have started it; new scope is a new issue.** Why: Rey kept to the version it
had read and the Board's later edit was lost (R200). Set: Board, Nov 11.

2.10 **Every outside finding is checked against the repo before anything is built on it; name the root cause, and check the
arithmetic yourself.** Why: the Board told Ryan the flash counter was "13 times" too strict; by viewing angle it was 5 to 7
(R193). Set: Ryan (R45, Oct 26); Board (R193). Ids: R45a, X22.
Fix the cause for every future thread, not the one case: an audit or a fix names the system cause and changes the tool,
workflow or document that let it happen (a tool or workflow before a new rule); one-off patches are listed and removed once
a global fix covers them. Why: "I don't want to overly respond to one time issues with patch, I want to address the core
underlying issue so it doesn't happen for future threads or work streams. Global fixes" (Ryan, Nov 16). Example: stale
status lines in HANDOFF and LOOP were hand-fixed again and again until GitHub itself became the one live record of open
work (0.10, issue 890). Set: Ryan (R291).

2.11 **Outside audits follow docs/REVIEW_PROTOCOL.md**: a fresh session, symptoms not theories, file, line and a short exact
quote per finding, OBSERVED or INFERRED. Findings come ranked, most important first; the job may set the count (reworded from
"at most 10"). Why: outside reviews came back half-read or made up. Set: Ryan (R154); Board (REVIEW_PROTOCOL). Ids: R154a,
review-01, review-02, review-03.

2.12 **Outside agents work in contrib/<agent>/; Muse may deliver low-code fixes (text, data, tests, tools, docs) as pull
requests; a rules or data change is made in Godot only (3.1).** Why: "keep muse cooking" (R81); Godot is the only rules
source since R405 (the browser twin is retired). Set: Ryan, Nov 2 (R81); Ryan, Nov 22 (R405). Ids: R81, agents-15, muse-06.

2.13 **A job's scope lists every folder its earlier runs touched, and every baked picture keeps its bake script in the repo.**
Why: PR 327 merged without its bake scripts (R157). Set: Board.

2.14 **Effort follows the kind of job** (an operating note, not a rule, under 0.10 and R251: the Board may change it in LOOP.md):
high for the Board, audits and design passes; medium for first builds judged by eye; low for well-specified code. Why: a miss on
a look costs a whole extra round (R168). Set: Board.

2.15 **The repo is the record.** Rulings go to FINDINGS with Ryan's words and the problem he was reacting to; board state to
LOOP.md; rules to this book. Why: the other models only see the repo. Set: Ryan (project instructions; R189).

2.16 **Argon stays off.** Why: "My subscription ran out and it just wasn't that useful to justify the cost" (R216). Ends when
Ryan pays for it again. Set: Ryan, Nov 5 and 11 (R216).

2.17 **A fix lands in the shared kit, so it reaches everything of its kind at once.** Every fix or look change goes where all
ships, screens or systems of that kind read it: a faction's skin in its kit stack (every ship of that faction rebakes from it),
a parts option every hull of the family uses, pipeline fixes in shared helpers, AI rules in battle.js and rules.gd together,
and every start screen's fonts, buttons, labels, rows, cards and sounds in godot/ui/theme/orders_kit.gd (9.15). Each pull
request names who else picks the change up; the Board returns a one-off fix unless the pull request says why it is specific.
Why: "let's make sure all the changes we're doing are cohesive and tied together. so like the fixes to the chorus skin should
apply everywhere once we land it, etc." Set: Ryan, Nov 19 (R333).

2.18 **No paid OpenAI API review of a pull request that a free seat already covers.** Artoo (ChatGPT) or the Claude code review
seat reviews it; `[openai]` audit jobs on the API key are filed only for work no subscription seat can do. Why: "Stop filing
paid `[openai]` API PR audits (like #1647) whenever free Artoo (ChatGPT) or Claude `/code-review` already covers the PR. Save
cash OpenAI API credits only for tasks no subscription seat can do." (Ryan, Nov 22 2026, 12:09 UTC, owner decisions of the studio ops upgrade plan, thread "Upgrade studio ops and PC harness"). Issue 1647, OK'd before this ruling, finishes.
Set: Ryan, Nov 22 (R406).

2.19 **A paid API call never loses its work: no tight answer caps, and every call saves partial output as it streams.** Any
script that calls a paid model API (Claude, OpenAI, Kimi, DeepSeek) sets the output limit to the model's ceiling, not a small
guess, sets no advisory task budget, and streams the answer, the visible thinking summary and the raw event stream to files
as they arrive, so a cut, a timeout or a max-tokens stop still leaves every event the provider returned, and marks the
deliverable as complete, partial or missing in its result file. Hidden reasoning that the provider never returns cannot be
saved, so long jobs ask for visible checkpoints. Spend limits Ryan approved (a credit cap on a key) are separate and stay. Why: on Nov 22 the Fable
review of the Gate 2 sound plan (issue 1752) hit a 64,000-token cap entirely in unsaved thinking, cost about $3.83 and
returned an empty review. "yes, stop randomly capping and make sure thatr work gets saved" (Ryan, Nov 22 2026, 20:53 UTC).
Set: Ryan, Nov 22 (R418).

## 3. PC and tools

3.1 **The product is the Godot 4 game on Ryan's Windows PC only, and Godot (`godot/`) is the only rules source.** The browser
rules (data.js, core.js, battle.js and the campaign files at the repo root) are retired: frozen history that no rules change
touches and the game never reads. A rules or campaign change edits the Godot files and the table files
(`godot/rules/data/tables.json`, `godot/campaign/data/campaign_tables.json`; reseal their checksums with
`godot --headless --path godot --script res://rules/tools/reseal_tables.gd`). CI compares every battle, the 30 seeded campaign
runs and the Nemesis scenarios byte for byte with the reviewed saved Godot results in the repo, beside the cache on/off safety
net; a pull request that changes them updates the saved results in the same pull request (`godot/rules/test/saved/README.md`,
`node godot/campaign/test/node/saved_campaign.js update`) and says why each changed battle or run moved. The ship pipeline reads
weapon lists and hull entries from the Godot rules table (`tools/recipe/gamedata.py`, issue 1667, R422).
The balance simulator (`node sim3d.js`) plays the frozen browser rules, so it measures
nothing new until its Godot port (issue 1656) lands. Why: "RETIRE THE BROWSER JS TWIN (RULEBOOK 3.1): Approved. Land a clean
retirement PR BEFORE coding starts on #1453 Build Variety parts (including #1652). Godot (`godot/`) is now the sole rules source
of truth, backed by headless Godot tests." (Ryan, Nov 22 2026, 12:09 UTC, R405). It replaces Path D's keep-both rule (R312),
under which every rules change went into both copies; at retirement both copies matched on all 289 battles and 30 campaign
runs (issue 1654). "Godot seems way better. It's very noticeable now." (R32); PC-only (Oct 24). Set: Ryan. Ids: R32, R33a,
agents-02, R312, R405.

3.2 **Heavy work runs on Ryan's PC (RTX 5080) through the queue; the cloud sandbox is for editing.** Why: the sandbox has about
8 GB and no GPU and runs out of memory on full meshes. Set: Ryan, Oct 21. Id: agents-23.

3.3 **Jobs and the janitor may remove only the leftovers covered here.** Everything else stays until Ryan says yes. Keep every job's PC folder lean, and the Board lists the PC folder sizes at each disk check.
Why: the PC disk filled on Nov 11 (C: 0.0 GB free, 550 GB in voidsworn_test, mostly old run copies), the queue
watcher stopped and every PC job waited until Ryan freed space himself (LOOP.md, Nov 12 02:15 and 02:20 UTC). On Nov 18 the drive fell under the 60 GB job floor from about 45 kept workspace copies and 390 GB of job scratch in the temp folder; Ryan chose (Nov 18 20:46 UTC) to let jobs clean up after themselves (R326).
On Nov 19, about 350 GB disappeared overnight (392 GB free after the Nov 18 cleanup, 41 GB the next morning). The hand cleanup removed 173 folders and raised free space to 199 GB. It kept 42 checkout copies, 26 because generated campaign outputs, audio UIDs or onboarding output were outside the safe list.
Set: Ryan, Nov 18 (R326) and Nov 19, 16:30 UTC (R336); lean folders and the disk check Board, Nov 11. Ids: ships-10, loop-17.
Ryan's yes to a delete counts when he gives it in the Board thread himself, typed in his own words. The Board passes it to the PC session with his message id as the receipt and the PC acts on it; nobody asks him to repeat it or to go to the PC just to say yes. A note from the coordinator, a helper or another agent is still not his yes. Why: on Nov 21 he typed "Yes remove saved runs" three times from his phone and the PC refused each as a relay, so the cleanup nearly waited a night with C: under the job floor. Set: Ryan, Nov 22, 04:35 UTC, "Yes fix that" (R400).
An install or refresh that deletes nothing is already approved: a tools_live install, a lane runner refresh, a watcher swap or a playtest promotion that keeps the old copy runs without asking Ryan again (`lane_tools_refresh.ps1 -NoRotate`; on the PC, `ALLOW_NODELETE_INSTALLS.bat` lets Claude run exactly that command without a prompt). Anything that deletes or rotates away a file still needs his own yes, as above. Why: on Nov 22 the PC refused two tools_live installs until he typed an OK himself, holding the Codex lane fix and the relay re-proof. Set: Ryan, Nov 22, 20:13 UTC, "alos yes any install that deletes nothing is approved" (R417).

Before setting aside an earlier checkout, the runner reuses it only when its working tree is clean and all local history
(including reflogs) is in the freshly fetched mirror. It allows ignored Godot `.godot` and `.import` caches, Python
`__pycache__` and `.pyc` caches, regenerated `golden/*.jsonl`, `out/` and `parity_campaign_log.txt` under
`godot/campaign/test/`, regenerated `golden/`, `out/` and `parity_log.txt` under `godot/rules/test/`, ignored Godot `.uid`
files including script UIDs and those under `godot/audio/build/`, and
ignored `.onboarding_checks/` output. All ignored files under `godot/gen/` and other ignored files under `godot/assets/ships/` must match the same path in
the shared build by size and SHA-256 (issue 1107). For removal only, never for reuse, a differing ship or `godot/gen/` file
is a candidate when the shared build holds the same file written strictly later; a copy file with no trusted time (before
2000 or in the future) is kept, and each such call logs both times and sizes. Times only nominate: the janitor copies
those files once each into `salvage\superseded_store\<sha256>.bin`, reads each back by size and SHA-256, lists them in
`salvage\<lane>_<name>_superseded\superseded_manifest.txt`, and only then removes the copy;
any failed check keeps it (issue 1180 run 7, Board Nov 20; Artoo on PR 1260). The safe list also includes stage 7 leftovers in `godot/.stage7-replaced-*`
and `godot/assets/ships/manifest.bak_*`. The runner fetches and switches to the new branch with those files in place. A collision or an
uncertain check keeps the earlier checkout beside repo. More than two `repo-kept-*` copies triggers a warning naming each
copy and its size. Why: repeated full copies filled C:, and deleting a supposedly clean checkout could lose
unique ignored work (issue 860, run 2, Board Nov 16).
A checkout that changes while the runner starts is never reset; the job stops instead.

Workhorse runs share one checkout per arm in `work217/slot_<arm>/repo`, reused under the same checks as the Codex lanes.
The arm's slot lock (`repo.checkout.lock` beside it) and the issue lock are inherited by the whole work_issue.bat process
tree, so they stay held until every process of that run has exited, even if the PowerShell that took them dies; the
Codex lane lock works the same way (Artoo on PR 1250). A work217 tools refresh takes every supported arm's slot lock,
live and dry run, creating any that do not exist yet, so a fresh arm cannot start mid-refresh (Artoo on PR 1334). Logs and results stay in each run's own `out/` folder. The old
`remove_repo_copy_after_push` setting no longer applies. Code-only lanes C and D and the Workhorse slots omit
`docs/shots/`, `docs/ship_pipeline/build_sheets/`, `contrib/muse/design/`, `hulls_hi/` and `rocks_hi/` unless the opening
fixed block's Brief or Deliver to line names a path there. A checkout on the same runner-managed sparse profile is reused;
a profile change sets the previous checkout aside beside the slot. A left-out file that is on disk while Git marks it
skip-worktree counts as possible hidden work and keeps the checkout. The janitor prunes older `repo-kept-*` copies beside
each slot like a board lane's, and accepts a runner-managed sparse copy under the same checks. Why: a fresh Workhorse
checkout per run and picture folders in code jobs drove up disk use (issue 1186).


Helper PC jobs with `OJ_SLOTS=1` (issue 1659; the template's switch, off until the Board's Windows proof) reset one of three warm slots under `voidsworn_test\slots`
(slot_gpu_1, slot_gpu_2, slot_cpu: reused `clone --local` copies of the mirror, the import cache kept) to their pin instead
of making a checkout per attempt; the last job's unproven leftovers are saved into its own attempt before each reset, a
slot whose leftovers cannot be saved is set aside with `hold.txt` for the Board, and the reset deletes only inside `slots`
(docs/playbooks/pc.md). Why: a fresh checkout cost about 10 GB real per attempt (ships copy plus import cache), measured
on the Nov 22 deletes; Ryan approved the warm slots on Nov 22 (studio ops upgrade, Wave 2.1). Set: Ryan, Nov 22.
Older bats without it keep their own pinned checkouts, which they remove once the attempt passed and every result file is
on a relay branch: the Board runs the job head's checkout step right after each relay, and the same job's later tails
repeat it. A file the job left in a checkout that is not a proven rebuildable leftover is saved into the job's own
`out_<name>\checkout_leftovers` first (at most 200 MB, read back by SHA-256); more, a staged change, a stash or a local
commit keeps the checkout. Failed and unfinished attempts are left to the janitor's rules. A ship job drops only its
clone's import cache on PASS; its publish removes the clone after the relay, saving leftovers the same way. Nothing
outside the job's own folders is touched. Why: on Nov 21 every passing job kept a 14 to 22 GB checkout for a
build_info.json or a few .import files, and C: fell from 176 to 55 GB in three hours (issue 1497; relay and Git-state
checks from Artoo on PR 1498).
Set: Board, Nov 21, under R326; playbook detail in docs/playbooks/pc.md.

Parity removes its own default temp folder when it finishes, pass or fail. After writing the result, the runner cleans up
its own recorded scratch at every ending. It keeps the newest failed, timed-out or cancelled run's scratch for one day for
a retry. The janitor runs from the queue watcher between 3:00 and 6:00 AM Central and at runner start when C: is under `janitor_free_gb`
(default 150 GB), at most once an hour across all lanes for low space. The runner then checks its 60 GB floor.
The janitor keeps the newest `repo-kept-*` copy in each of `board`, `board_b`, `board_c` and `board_d`. Older copies and
finished `work217/issue-<N>-<arm>/<stamp>/repo` folders must be untouched for at least three hours and pass the same
rebuildable-file, Git history and lock checks. Workhorse `out/` folders and runner settings and hashes stay in place.
The checkout age uses the newest working file write time and skips `.git`. Git checks use `--no-optional-locks` with the
filesystem monitor and diff index refresh disabled so inspecting a checkout leaves it unchanged. Why: an index write can
make an old copy look fresh on the next scan or look like an edit during the current scan (issue 1180).
If an otherwise eligible copy holds tracked edits, untracked files or local-only commits and has been untouched for at least
one day, the janitor saves a binary patch against HEAD, a separate staged patch, a zip of untracked work and, when needed,
a bundle of local-only commits under `voidsworn_test/salvage/<lane>_<name>/`. It checks that the patches apply, the bundle
verifies and the zip entries match before it removes the copy. An unreadable checkout, unknown ignored file or failed check
keeps the copy. Salvage folders are kept. Why: old job copies can be large and still hold work worth saving. Set: Ryan,
Nov 19, 17:01 UTC, "Yes, after a checked backup" (R339).

Helper PC jobs get their checkout from `tools\pc\helper_clone.bat <job folder> <branch> [ships] [job steps]`: one `git clone --local`
of the shared `repo-mirror.git` per helper folder (objects shared, no new download), reused on later runs without ever
resetting local work, and ship files copied and checked by get_ship_files.bat, never hardlinked, because tools rewrite
them in place. A helper .bat never clones from GitHub itself (issue 1180, Board Nov 20). The helper runs its job steps
through helper_clone.bat, which holds the folder's `.voidsworn-run-active` lease until they end, so no second run can
switch that checkout mid-job. Before copying ships it stops if a file it would replace differs from both the shared build
and the folder's own last copy (`ships_copied.txt`), so local work is never overwritten (Artoo on PR 1275). After the
Board relays a PASS, `helper_clone.bat <job folder> release` checks that the latest attempt ran its job steps and they
exited 0 (a setup-only call or an early stop never qualifies) and that every out file is on a relay branch (the relay repo's pc-out branch, or an older board/pc-out one), then
removes only the ship and gen copies still matching that record and the `.godot` import cache; the clone stays, and a
FAILED run keeps everything (R326, own leftovers). Ship jobs and the look bench give their tools an owned TEMP folder. A helper proof job's head (opus_job_head.bat, issue 1303) removes, at its tail and only after a PASS, the pinned checkouts its own checkout step listed in that attempt folder whose HEAD is still the pin and whose files hold no work beyond the import cache, ship copies still matching their source, byte copies of tracked files and the .import/.uid sidecars of those (rebuildable from the mirror; about 16 GB each); a failed job keeps them, and its out folders, logs and ship records always stay. Stage 7 removes its checked export scratch after a
successful install. A TEMP folder untouched for three hours can be removed when it carries a valid `.voidsworn-run-owner`
token or a runner's `status.json` names its exact path with the same token and creation time (a record without both, or
a folder that no longer matches it, is report-only). Older scratch with no token can go after a day untouched only when
its whole name is one our tools generate (`voidsworn-run-[<issue>-]<32 hex>`, `voidsworn-parity-<6 characters>` from
run_parity.js, `stage7-checked-<code>-<8 characters>` from manifest_merge.py), its issue lock is free and no running
process names it (the whole folder name, so `opus121` never matches `opus1211`). Links inside any TEMP scratch, owned or
older, are removed as links and never followed, and the log names each link's target; a folder another account owns
(Codex sandbox scratch) cannot be read, so it is left in place and the rest is removed. Other name matches are report-only, and agent-chosen
names go to Ryan as a one-off list. The janitor removes an `opus<N>` helper folder (with any suffix, such as `opus<N>out*`, `opus1369b` or `opus1211_run6`, and playtest folders `pt<MMDD><letters>`, issue 1396) after a day untouched
only when no running process names it, every file in its out folders is a blob committed on a relay branch (the relay repo's pc-out-* or an older board/pc-out-*)
in the repo mirror (a loose blob is not a receipt), and everything else in it is a checkout Git shows as rebuildable with
all local commits in the mirror; files the relay skipped and other files are listed and keep the folder. helper_clone's
own top-level files (`.voidsworn-run-active`, `attempt.txt`, `repo_commit.txt`, `ships_copied.txt`) do not count as
other files. The janitor takes the helper folder's lease before deciding and holds it through the deletion, removing the
lease file and the then-empty folder last, so a held lease keeps the folder (PR 1275). When such a folder is kept, its Git checkouts (at any depth, links never followed) can still go on their own after the whole folder is 6 hours untouched, under the same lease, issue lock and process checks, when Git shows nothing in them beyond rebuildable install outputs and every local commit is in the mirror; their HEAD and status are logged first, and the out folders, pictures, logs and every file outside a checkout stay (issue 1396, Ryan's typed OK in the Board thread, Nov 20). Each janitor run also runs the job head's relay proof (`opus_job_head.ps1 dropjobs`) over every passed job attempt that still lists checkouts, so a relay that lands after the job's tail still frees them; it runs per job folder only after the same keep list, lease, issue lock, process and pause checks, removes only what that proof clears and logs the rest (Board, Nov 22; Artoo on PR 1592). A ship job's clone `<job>\repo` (its `out\result.txt` starts with ship_job's `start` line) is never removed by the janitor, whole folder or checkout-only: `publish_ship.bat` installs with it and removes it after a published PASS, and an abandoned one goes to the Board as a one-off (review of PR 1592). A checkout whose HEAD or local-branch reflog holds a commit no mirror ref reaches, or that has a second worktree, is kept (review of PR 1592). A ship file with no twin in the shared build
is a superseded candidate when the build holds that ship code installed later, and a generated file under `godot/gen` with
no build twin is one when the build's `gen/manifest.json` was written later (the newer gen no longer makes it); both are archived like any other
(issue 1180 run 8, Board Nov 20). A held issue lock or a held helper lock protects scratch. The Board's keep list, `voidsworn_test\janitor_keep.txt` (one exact folder path per line, `#` for notes), keeps any candidate that is a listed path, holds one or sits inside one, logged as "kept: on the Board keep list"; a keep list that cannot be read stops the janitor (issue 1180, Board Nov 20). Active board `repo` folders, `build*`,
repo mirrors, `recipe`, `runner_backups` and other locations stay out of the scan.
Jobs also stop refilling TEMP themselves (issue 1180, Board Nov 20). The runner self-test removes its evidence folder
after a PASS (RUNNER_SELFTEST_KEEP=1 keeps it). The watchdog removes the Godot profile folder it made for one launch once
every process of that launch has exited, links as links, never a job's own profile (PC_KEEP_GODOT_PROFILE=1 keeps it).
Ship jobs and the look bench hand their owned TEMP folder to `tools/pc/scratch_done.ps1` at the end: a pass removes it;
a failure marks it `.voidsworn-run-failed` with the job's name and keeps only the newest failure per job, which the
janitor keeps for one day. While their tools run, both put `tools/pc/pysite` on PYTHONPATH, whose sitecustomize makes
Python's `tempfile.mkdtemp` folders with a plain mkdir that inherits the TEMP folder's access (only inside the job's own `voidsworn-run-*` scratch; any other folder keeps Python's private one, Artoo after PR 1537), and the picture
provenance self-test removes its own folder after a PASS (issue 1535: Python 3.12.4+ on Windows gives mkdtemp folders a
private access list, and 31 such folders, about 49 GB, could not be removed by cleanup 4 on Nov 21; the PC proof board/pc-out-1535 showed that private list alone is the cause, with no elevation involved). When a job_wrap job ends, the janitor runs once more with `--after-job` in a
hidden window. That run shares the hourly allowance with the low-space trigger, skips without a word while another
janitor holds its lock, any `gpu_slot_N` or `gpu_solo` claim file is non-empty or the Board's pause is on, and stops
between folders if a GPU claim starts, so a solo measurement is never timed alongside it. The watchdog and scratch_done.ps1 check the
Board's pause right before each removal and keep the folder for a later pass. Why: these four leftovers
refilled C: by about 120 GB a day between nightly runs (issue 1180 dry run 2).
The log gives each candidate's size, decision and reason, along with free space before and after. The Board reads the dry
run before the first live run. A pause removes nothing (3.11).

3.3a **PC results go to the private relay repo, never the main repo.** Videos, sheets, renders and logs from PC jobs go to
`rcbailey12/voidsworn-relay` on branch `pc-out-<job>`, the attempt folder at `<attempt folder name>/` in its tree, through
`tools\pc\relay_push.bat <job> <attempt folder>` (out_* folders and the top text files; files over 10 MB stay on the PC,
listed in `skipped_over_10MB.txt`), in pushes of at most 512 MB each (GitHub refuses a push over 2 GiB); a relay stopped
between pushes proves nothing until it is run again. The PR comment carries the links it prints. A job's cleanup proves the relay the same way
as before, now from `relay/pc-out-<job>` (relay_branch.txt) or an older board/pc-out branch. No new board/pc-out branch is
pushed to the main repo. Stale board/pc-out-* and board/pin-* branches go only through `tools\pc\PRUNE_RELAY_BRANCHES_DRY.bat`
(lists, deletes nothing) and then `PRUNE_RELAY_BRANCHES_LIVE.bat` after Ryan's own yes on that list; a branch still named by
a queued job, in `voidsworn_test\prune\keep.txt`, under 3 days old, used by an open PR or still needed to prove a PC job's
relay is kept, and the live run checks every one of those again just before each delete, so a keep line or queued job
added after the dry run still keeps an unmoved branch. Why: the main repo was 22.66 GB with 701 branches, 316 board/pc-out and 133 board/pin (Nov 22); Ryan picked
"Private GitHub relay repo" (Nov 22 2026, 12:14 UTC, decision card in thread "Upgrade studio ops and PC harness"), and approved
the plan: "Route binary PC outputs ... to a disposable private relay repo (`rcbailey12/voidsworn-relay`, wiped monthly) ...
Ship a safe double-click Windows `.bat` script (dry-run default first) ... to prune the 447 stale `board/pc-out-*` and
`board/pin-*` branches" (12:09 UTC). Set: Ryan, Nov 22 (R410).

3.4 **GPU work is sized to the job and to what the RTX 5080 can hold, not to a fixed job count; frame-time measurements run
solo. Lanes C and D stay code only.** The Board decides per job how many share the card: light captures and probes can run side by
side, heavy bakes and Blender renders take more of it, and nothing is started that would run the card out of its 16 GB of
graphics memory. The launchers take and release claims themselves through tools/pc/gpu_slots.js (shared capacity from
Downloads\voidsworn_test\gpu_slots.json, {"sharedSlots":2} by default, raised by the Board; captures weigh 1, Blender and heavy
bakes 2, with PC_GPU_WEIGHT for the job's chosen weight), or a solo claim that waits for every slot
to empty and blocks new GPU work while it measures. Slot files are replaced atomically. A slot or solo claim with damaged JSON
is moved to a retained `gpu_slot_corrupt_*` file so admission can resume. Damaged capacity settings stop admission.
Claims name the issue, job directory or script. The watchdog and its GPU child each have a recorded PID, start time and
executable name. The child is recorded before it can start work. A failed kill logs the survivors and leaves an
`orphaned_child` claim until those exact processes are gone. Claims from older ship checkouts stay held while their PID
is alive. Admission checks a snapshot outside the shared lock at most once a second. If the lookup fails or the claim files
change during the lookup, admission waits and checks again. Child registration waits for the lock before starting the child.
Drain GPU jobs before updating all shared tools copies together, since older launchers cannot track the child.
A partial write or a reused PID could block the queue, and losing
the watchdog or failing to kill its child could free capacity while the child was still using it (Board, issue 1193).
`gpu_go.txt` still wins: no new GPU work starts unless its first line is `GPU cleared` (optionally followed by `: reason`);
the gaming pause in 3.11 is unchanged. Why: "that one GPU job at a time is an outdated rule, we should be flexible based on the task and what my
graphicsa card can actually handle as a 5080. we don't want to overwhelm it but we don't want to artificially restrict small
jobs and extend things out" (Ryan, Nov 16, R293). Solo measurements keep speed numbers honest. Replaces the two-job cap
(R276, Nov 15) and the one-job limit before it (R173b, effects-09); the gaming pause (R173) remains. Set: Ryan, Nov 16 (R293).

Each wrapped step has a ceiling sized to its work. A solo claim follows that ceiling by default.
`PC_GPU_SOLO_MAX_S` can set an earlier limit from acquisition. A job with several timed sessions claims the card once
per session. The watchdog counts output, new files in the step's output folder, and CPU time across the process tree
as progress. The idle limit is 300 seconds for Godot and 600 seconds for other tools. A step can raise it with
`TMO_IDLE_S`. The Jolt job-system line stops the step immediately. A step may add a pattern through
`TMO_FATAL_PATTERN`. A stop returns 124, retains the child logs, and records the step and reason in `timeouts.log`.
GPU admission has a separate clock. It defaults to 1500 seconds in the agent runners, below their 30-minute stall
limit, and 3600 seconds in the shared ship runner. Why: a Jolt stall in the issue 1078 probe held the GPU solo for
almost an hour and queued work timed out behind it (Board, Nov 19, issue 1192).

3.5 to 3.7 **PC harness.** See the [PC harness rules](../.claude/rules/pc-harness.md) for queue and watchdog jobs, Board PC control and PC clones.

3.8 **Free tools and sources, local first; a paid service only with Ryan's yes, for that one evaluation.** Why: money is his.
Set: Ryan (AGENTS.md; R110). Ids: R110b, agents-20, audit-02.

3.9 **Performance has one binding law: the measured scene gate, 12.5 ms of the 16.7 ms frame on the #207 scene** (frame median
at 1080p, GPU ms at 4K). Triangles, draw calls and surfaces are reported, never capped. 60 fps at 4K is the goal, 1440p the
floor. Why: new content needs a spending limit, Ryan plays at 1440p and 4K (R116); "measurements exist to find where fidelity
can scale up and where performance forces scale down" (R121). Set: Ryan, Nov 6 to 8 (R111, R113, R116, R121, R122a). Ids:
R111a, R111b, R113, R116, R121a, R121b.

3.10 **The repo stays public.** Why: the outside tools (Muse and its models) read it without logins (R216). Set: Ryan (R10,
R216).

3.11 **A pause never loses or deletes work.** When Ryan wants the PC (GPU or CPU), the Board runs tools/pc/pause_all.bat
(now, or at a time): it withdraws the GPU go, closes only chain windows still waiting to start, and ends the Board's own AI
processes (only those whose command line names the voidsworn_test job folders; never Ryan's own apps), so
each running job's runner commits and pushes its work to the issue's -partial branch; job windows mid-run are never closed and
nothing is deleted. The pause waits for each lane's runner (main, B, C, D and DeepSeek work217) to leave running, then checks
its status.json, run_commit.txt and confirmed_commit.txt against GitHub with git ls-remote. pc_pause.txt reports each job as
done (finished and its delivery branch holds its confirmed commit), checkpoint verified (its -partial branch holds the
runner's confirmed commit), or unresolved (anything else, including checks still running, a failed verification or a timeout).
Leftover running records are listed with their last activity, not counted in the wait or unresolved jobs, and never changed.
Only the final "safe to restart" line in pc_pause.txt means a restart is safe; any unresolved job instead gives
"NOT safe to restart: <jobs>". On Ryan's go the Board restarts every paused job from its verified -partial branch and recovers
unresolved work before restarting the PC. Why: "I don't want to cause anything to get lost or deleted with the pauses as well,
so let's bake that in" (R272); quiet agent processes did not prove a runner in final checks had pushed (R309, issue 944).
Set: Ryan, Nov 15; audit fixes approved Nov 17 (R309).

3.12 **No GPU capture on a pull request before its checks are green and its diff has passed review.** `player_path`, `look_bench`
and other heavy GPU captures are queued only after "All checks" is green and Artoo or the code review seat has passed the diff
at that head commit; a later push needs both again. Overnight, when the PC is idle, gpu_go.txt is clear and main changed game
files, `build\export` refreshes by itself (issue 1663): the root watcher runs `tools/pc/overnight_export.ps1` every 10
minutes when idle, and it queues one `overnight_export_job.bat` only between 1 and 5 AM Central, with gpu_go.txt clear, 75 GB
free on C:, no job, GPU claim or Voidsworn, Godot or Blender process running, and main's `godot/` tree changed since the
last overnight export; one try a night. The job exports main through the existing g2_export check, smoke and promotion and
never changes `build\godot`; g2_export refuses to replace `build\export` while Voidsworn is running, so the game Ryan
launches is never swapped under him. R319 still holds for playtest captures (`g2_pt_*`): those wait for Ryan to ask. Why: "Never queue `player_path`, `look_bench`, or heavy GPU captures on
a PR until `checks` is green and Artoo (or the code review seat) has passed the diff." and "Auto-refresh `build\export` overnight
when idle (`gpu_go.txt` clear) and `main` changed game files." (Ryan, Nov 22 2026, 12:09 UTC, owner decisions of the studio ops upgrade plan, thread "Upgrade studio ops and PC harness"). Set: Ryan, Nov 22 (R407, R408).

3.13 **Every review of a Godot FX, rendering, ship import, audio or battle-feel pull request applies the independent-audit
skill** (`.agents/skills/independent-audit/SKILL.md`) before merge and before its GPU capture: Opus, Codex and Muse review runs
alike, findings grouped Blocking, High / Medium, Ready, naming the commit read. Why: Neon's wrap-up pass found silent
regressions on PR 1699 (shield-blocked brownouts, a miss streak divided by speed, two competing light-dim paths) that green
checks missed; Ryan: "Instruct Opus, Codex, and Muse review runs to apply `independent-audit` before merging any Godot FX,
rendering, ship import, audio, or battle-feel PR." (Ryan, Nov 22 2026, 16:48 UTC, Board thread). Set: Ryan, Nov 22 (R413).

3.14 **One global look and sound standard; no subsystem is tuned alone.** Every ship exterior and interior, weapon effect,
wound, death, hulk, debris piece, station, planet, rock, sky and sound follows the six laws of
`contrib/opus/plans/global_cohesion_standard.md`: (1) one value ladder (deep space near black; ship interiors and wreck cavities
darker than lit armor, walls at most 0.11 linear; full glow only on cores, weapons and small accent strips, non-core interior
emission at most 0.25); (2) interior materials come from each faction's own role table, never from the `kit.py` diagram
colours, with structure (bone, frame, truss) kept apart from wall and flesh finishes; (3) one identity per faction across
hull, interior, weapons, wounds, deaths, hulks and sound; (4) the world and audio tracks (10.11, the sound plan using Godot
4.7 native `AudioStreamSynchronized`/`AudioStreamInteractive` in Gate 3) obey the same ladder and palette; (5) the standard's
automated anti-drift checks (export, Godot world, exterior and palette, sound pack) are added and kept green; (6) AAA ship
exterior lighting, per-faction micro-detail, PBR separation and Godot 4.7 engine hygiene (#1777, #1778, #1779, #1780:
default-on Space PBR reflection IBL and per-faction `ao_light_affect`, zoom-tracked crisp contact shadows without `LookRim`
plastic glare, BC5 ship normal compression (already true BC5: S3TC with the normal source, as Godot 4.7 has no RGTC mode; guarded by `ship_look_v2_check`), native per-faction PBR channels and six faction tiling micro-detail
normal/roughness maps, true paint-vs-metal separation, massive-scale cues, a hard export ban on lossy `.jpg` normal and ORM
maps, battle 3D LUT + kill-cam DoF + selective SSR/CompositorEffect benchmark, plus cached `.gdshader` PSOs, BC7 world VRAM
compression, FSR 2.2 AA option and empty volumetric fog gating). A fix for one faction is made at the shared root for all
six. Why: silo patches kept drifting (chalk-white Directorate corridors, neon Chorus organs from diagram colours, clay-ish
ship exteriors under black-space reflection defaults, purple and mustard leaks, unwired 8K planet maps, runtime shader
stutters and raw RGBA8 VRAM bloat); Ryan: "We are moving from one-off visual tweaks to one global visual, material, world,
and audio standard so subsystems stop drifting in silos." and "Yeah, A for all. Let's do everything and anything we can here."
(Nov 22 2026, tracker #1774). Set: Ryan, Nov 22 (R420).
R421 (Ryan, Nov 22 2026, on the Fable and Astra cohesion reviews): no Glasswright refraction (dark glass with clearcoat
and fresnel instead); anisotropy stays at 0 until #1778 bakes flow maps; before Ship Look V2 goes default-on, the warm sun
reflection lobe is desaturated to a neutral warm-white so Eclipse stays obsidian-violet in deep shadow. Interiors (#1763,
#1755) merge only after the #1755 breach-material and strip-mask fixes and one joint intact, breached and broken sheet under
the #1786 lighting. The world PRs fold in the audit cleanups before merge: an obsidian Eclipse hulk finish (#1772), a
procedural planet fallback when the remix is off (#1776), crystal `_lo` LODs (#1782); the planet relief map's VRAM is
budgeted in #1780.
R423 (Ryan, Nov 23 2026, decision card on PR 1772's hulk pictures; its 0.04 and 0.025 floors were replaced by R425 below): hulks sat in band 3 at 0.04 to 0.045 linear base
(burnt, dull, Eclipse obsidian at the floor), with one exception: Chorus hulks only go below the band 3 floor, to about
0.025 (0.025 to 0.03, the low end of Eclipse's interior range), because at the floor the tan chitin wrecks were still the
lightest shapes in a hulk field at camera 170. Eclipse hulks are unchanged. Code: `godot/assets/ships/a4_props.gd`
HULK_BAND and CHORUS_HULK_BAND, checked by station_size_check and unwired_station_hulk_check.
R425 (Ryan, Nov 23 2026, on the Chorus material probe for PR 1772): a wreck is never lighter than its own live paint
dimmed to 60 percent; the hulk floor only stops pure black (0.005 linear). The 0.04 floor (R420) and R423's 0.025 for
Chorus had lifted dark paint back up: the Chorus body (about 0.021 live) rendered undimmed and the Hullbreaker hull went
from 0.027 live to 0.040 dead. Ceilings stay (0.045, Chorus 0.03); Eclipse obsidian keeps its 0.04 floor (R421). The
60 percent (and the 40 percent cap on dead metal, Wave 0 on Sheet M) scale the encoded paint tint, so in linear light a
wreck keeps about a third (dead metal about a seventh) of its paint; the band and ceilings are measured in linear light.
R426 (Ryan, Nov 23 2026 03:22 UTC, on the #1777 before and after sheets): Ship Look V2 is the default look for every
hull, the darker Hullbreaker red included; `VS_SHIP_LOOK_V2=0` keeps the old look for A/B captures only, and new ship
work is judged under V2 (`look.gd` `ship_look_v2_enabled()`, guarded by `ship_look_v2_check`).

## 4. Ships and concepts

See the [ship rules](../.claude/rules/ships.md) for concepts and faction shapes (4.1 to 4.11).

## 5. Ship build pipeline

See the [ship rules](../.claude/rules/ships.md) for build sheets, hulls, kits and exports (5.1 to 5.18).

## 6. Battle look

See the [Godot battle rules](../.claude/rules/godot-battle.md) for battle camera, effects, damage and shields (6.1 to 6.17).

## 7. Movement

See the [Godot battle rules](../.claude/rules/godot-battle.md) for movement playback and rules (7.1 to 7.9).

## 8. Battle sound

See the [Godot battle rules](../.claude/rules/godot-battle.md) for sound and music (8.1 to 8.5).

## 9. Screens and interface

See the [Godot UI rules](../.claude/rules/godot-ui.md) for interface, controls and screen behavior (9.1 to 9.19).

## 10. The campaign map, space and the board

10.1 **The battle board is a cinematic scene, not a board game**: no grey plate, living terrain, a faint grid only near the
active ship and the cursor, a key for the full tactical view. Why: "it almost ends up just looking like a board game on top of
a cool background" (R70); "Yep, C." (R72). Set: Ryan. Ids: R70, R72.

10.2 **Background rocks never read bigger than a planet or loom over the fleet**; the old numbers (0.05 rad, planets 4.4 times
wider) are tuning values judged on the loom turntable. Rocks turn slowly. Why: the cap's purpose was scale (R124); "Reword to
the purpose" (R191); "Nah, I like the rotation of asteroids" (R212). Set: Ryan. Ids: R79b, R124a, R191, R212.

10.3 **Planets from real data, remixed past recognition.** Why: "but really remix. Shouldn't be obvious planets we know" (R163).
Set: Ryan. Id: R163b.

10.4 **Hulls stay crisp inside gas; gas dims only the stars and sky.** Why: his yes to the terrain research picks ("Agree with
picks", R82). Set: Ryan. Id: R82b.

10.5 **Wreckage fields use ship-derived pieces, never flat panels.** Why: his yes on the debris pass picture (R107). Set: Ryan.

10.6 **The campaign map is the Briefing layout over the real 3D scene**: the approach to the star across three sectors, routes
only, names only on the current stop and the next jumps, fight stops showing the enemy as a small seeded group, regions as
scenery with one landmark. Why: "Briefing is it but I want that merged with the graphical quality of the original map, minus
clutter and noise of it." (R165); "It's hard to read all the stops after the first." (R170); "it's hard to read the paths with
the orbit lines around the star AND the lines for pathing." (R174); "It's just a wall of 3 ships everywhere." (R181). Set:
Ryan. Ids: R164c, R165a, R170c, R174a, R174b, R181, briefing-01.

10.7 **Stations are built from the accepted concept (Vesper Reach, T2 damaged) through the ship recipe, with far more surface
detail than the first pass.** Why: "T2 damaged" (R206); stations looked plain (R109). Set: Ryan. Ids: R109, R206.

10.8 **A battle opens with both fleets in view; markers at the screen edge only where a ship can leave the view.** Set: Ryan
(R62, R216).

10.9 **The battle nebula is one rose colour (the hydrogen pink of real glowing gas) in every region and against every
faction; no indigo to purple gradient.** It replaces R82's violet and the faction tint share (world_living.gd NEBULA_*).
Why: "shouldn't we have nebulas be one color? ... I want it to be semi realistic", then "Yes agree on rose" on the NEB1268
sheet (Nov 20 2026); rose reads apart from the teal ion storm; Ryan listed indigo to purple gradients among the AI-made
tells (R174). Set: Ryan (R82, R216, R353).

10.10 **The battle board is the dead star's gravity well.** Why: it is the game's identity, the Hollow Sun setting (R216).
Set: Ryan, Oct 24 (R216).

10.11 **The battle sky is Grounded Cinematic Space: mostly near-black, never wall-to-wall star snow.** About 400 star
pinpoints in a 45-degree battle frame (about 96% fewer than the Nov 22 sky; Ryan picked 400 over 1,200, R421), faint stars gathered along a tilted galactic band,
a steep brightness curve so only a few hero stars gleam, and opaque dark dust lanes (`star_floor = 0.0`; the `VS_STAR_FLOOR`
override stays for tuning sheets) that black out the stars behind them. No mustard fog and no purple Eclipse nebula (10.9).
Planets, rocks, comets, stations and hulks are lifted to one bar across every region: the 8K rocky planet maps (godot/world/rocks/r01) and all
five foreground planet types on the high-relief planet pipeline, five asteroid biomes that read apart (the ice belt pale with frost, the nebula slot's
ice comets dark with a few dirty ice patches, dim vents and faint anti-sun tails beyond the far edge; free-floating crystal
clusters are scrapped: Ryan, Nov 22, "It doesn't make sense. It'd need to be like an ice comet"), `station_T2` at every cluster size, and derelict hulks from all six factions. The track plan and its five
silent-regression traps are `contrib/opus/plans/world_consistency_v2.md`; each track runs independent-audit (3.13) before its
GPU captures (3.12). Why: the Nov 22 world audit found A-tier pieces beside D-tier outliers, and about 85,000 sky stars read
as white static behind ships, hexes and arcs; Ryan approved Option A on all four areas (tracker #1764). Set: Ryan, Nov 22 2026
(R419).

## 11. Story, names and the campaign

11.1 **The lore is lore_bible_r8.md; display names follow it and rename_map_final.md; ids never change.** Why: saves, sims and
parity hashes stay untouched (lore_roles brief). Set: Ryan, Oct 27 (R59). Ids: R59a, R59b, R44b, agents-22, lore-01.

11.2 **Science fiction, not fantasy: nothing that echoes Warhammer 40k in names, motifs or look.** Why: he rejected two lore
rounds as "high fantasy" (muse lore brief) and asked to rename everything 40k-adjacent, milder words included (R44). Set:
Ryan, Oct 26. Ids: R44a, lore-03.

11.3 **Species: the Hullbreakers never look like the Predator; the Glasswrights are organic and evolved to shape glass, not made
of it.** Why: avoid a known film creature; the species is not made of glass (R66). Set: Ryan. Ids: R66, packages-01.

11.4 **Story text passes Ryan's final read per faction.** Set: Ryan (R45b).

11.5 **The "Playtest: everything unlocked" switch stays on, with renown progression intact underneath, until Ryan says
progression is ready to test.** Why: he tests the whole game, not the unlock path (R69). Set: Ryan (R69). Id: progression-01.

11.6 **The dawn finale plays on every run from run 5 on that reaches the final boss** (the sector 3 boss), not only on run 5.
Why: a player who reaches the boss on run 6 or later never saw it. Replaces the run 5 only part of R78 Q18. Set: Ryan, Nov
20 2026 01:11 UTC ("Picks ok" on the backdrop audit check, Board thread). Job: issue 1271.

11.7 **On a first run, Battle 2 opens on Battle 1's open strip** (open space, strip arena, line deployment, edge feature);
its Corsairs and the forced round 3 to 4 enemy reinforcements stay. Why: Battle 2 was a big difficulty jump before the first
shipyard (Neon review finding 9, PR 1380; the council playtest lost seed 121 there). Set: Ryan, Nov 20 2026 19:45 UTC ("Give it
Battle 1's open strip", Board thread card). Id: R366. Job: issue 1393.


11.8 **Retreat returns the fleet to the stop it came from; the fight stays on the map, and the 10% hull cost stays.** A
retreat never completes the node or clears a Nemesis meeting. Why: an independent audit (Nov 21, F-05) found a round-1
retreat skipped any non-boss fight for 10% hull and could lock out Nemesis-held service stops. Both rules copies (3.1).
Set: Ryan (R381, issue 1480).

11.9 **Chorus biomass pays for refits, upgrade tracks, rerolls and the late market, as credits do for other fleets.** Why:
Chorus turns its whole purse and payouts into biomass, so credit-only shops starved it (audit F-13). Set: Ryan (R382,
issue 1484). How: biomass pays when it covers the price, otherwise credits, one purse per purchase; a Chorus run still earns
credits (repair stipends, ransoms, scrap, declined protocols), so biomass only would strand them (Board reading, Nov 22, PR 1627).

11.10 **Overrunning the Nemesis flagship, a hunt target or a convoy transport by boarding counts as destroying it** for
kills, loot and objectives. The hull does not join your fleet. Why: a capture broke Nemesis outcomes and hunt and intercept wins (audit F-01). Set: Ryan
(R383, issue 1479).

11.11 **The Eclipse rival's revived fight is the Sector 3 boss battle**, not an extra fight. Why: audit (issue 1480 item 1);
checked against issue 1271. Set: Ryan (R384).

## 12. Automatic checks

12.1 **Checks protect crashes, saves, rules parity, comfort and frame rate. A test that pins a look number is updated in the
same pull request that changes the picked look.** Why: tests fixed hit sizes, piece counts and cue counts that the audit fixes
had to move (contrib/codex/reviews/rules_sweep_checks.md). Set: Board, Nov 11 (0.4).

12.2 **A check's state comes from the real functions, never typed by hand; missing things fail loudly; one source per fact.**
Why: a fixture typed by hand let 137 checks pass while real play was broken (R155). Set: Board, after the outside audit
(R154, R155). Ids: R155a, handoff-08.

12.3 **Every push to an agent branch runs the checks once; every test script under godot/**/test/ has its line in
godot/tools/ci/godot_checks.txt.** Why: a missing test must fail loudly (PR 400). Set: Board. Ids: handoff-07, loop-10.
A push that changes only .md files and pictures under docs/, contrib/ or the repo root (tools/ci/docs_only.js) runs the
standing checks and skips the four Godot jobs; the "All checks" job gives every run one mark, and a merge conflict with
main fails the run. Why: docs-only review pushes ran 45 runner-minutes of Godot work for nothing (audit GH-03, issue 1487).

12.4 **A rules or data change is made in Godot only and passes the saved-results checks (3.1); a pull request that updates
the saved results says why each changed battle or run moved.** Why: the oracle copies drifted (R155); the browser twin is
retired (R405). Set: Board; Ryan, Nov 22 (R405).
Id: R155b.

12.5 **The look bench: bench a commit twice and keep the second run; a change differs where it is meant to and nowhere else;
a new baseline is committed only when the Board accepts the change.** Why: the first run pays for shader warm-up (R162).
Set: Board. Ids: R162c, program-07, skill-sv-02, skill-sv-03.

12.6 **The player-path recording of Battles 1 to 3 is the acceptance check for visual and teaching changes.** Use
`tools/pc/jobs/player_path.bat` on the shared installed build with a fresh, isolated profile and player defaults. Judge the change
in those recordings. Use the look bench and bot captures for comparison and diagnosis. Earlier captures hid the
cut-ins, danger overlay, teaching cards, target card and battle voice that a new player encounters. The look bench also
draws meshes at full detail. Set: Ryan, Nov 19 (R328).
