# Embers of the Hollow Sun: the rulebook

The one list of rules in force for the whole project (issue 492, FINDINGS R190). Each rule says what to do, why (the problem
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
(checked live before any dispatch; contrib/opus/OPEN_WORK.md is only a timestamped nightly index of it, issue 890), what runs on the PC in LOOP.md's newest LATEST lines and The seats, the hand-over in HANDOFF section 0 (about one page; older sections go to docs/archive), history in FINDINGS.
LOOP.md's LATEST lines roll into a dated summary once they pass about 15. Muse audits for stale or conflicting docs now and then.
Why: several models and fresh chats read the repo cold; on Nov 14 a one-day choice nearly became a rule, an A20 note was stretched to
every ship before Ryan ratified it (R244), and a summary line inverted Ryan's call on A18 and A19.

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

## 2. The Board and the agents

2.1 **The Board owns the whole board.** One Claude thread in the Project (Opus 5.5 since Nov 11) holds design calls, the final
technical call and every merge; it starts agreed work on its own, picks the seat, keeps contrib/opus/OPEN_WORK.md moving, and
asks Ryan only for design, key decisions, reviews of what he will see, and conflicts. Why: agreed items were left behind
whenever new work arrived ("The station is a good example of something we already aligned on but is still sitting there",
R194); and "you own the codebase and github. you are my orchestrator and control the building" (R202). Set: Ryan, Nov 8 to 11
(R119: "sure merge, you're the owner now"; R167, R194, R202). Duties: contrib/opus/LOOP.md "The Board's standing duties".

2.2 **Nobody grades their own work.** Workers never merge their own pull requests. An Opus-built, game-facing change gets an
outside check (Muse, issue 256) before or straight after merge; a tools-only pull request that other jobs wait on may merge on
the Board's diff review while Muse is idle, with the check still asked for. Set: Ryan (R119, R132, R133, R167); the exception
Board (R162). Ids: agents-13, claude-04, R132c, R162b.

2.3 **Review every pull request by its diff, never its title, then sweep its impact** (every caller, saves and old profiles,
both rule twins, every UI path, which tests really ran), then the pictures. Merge only on green, and only after every check
job has finished. Why: a merged change left existing profiles with Heat closed (R129); PR 542 merged before its parity jobs
ended (LOOP, Nov 12). Set: Board (R129); Ryan's project instructions. Ids: R129a, loop-03.

Pictures carry their revision and stage. Every picture shown to Ryan is labelled with the revision that produced it and its
stage (sheet built, paint proof, installed in game, Ryan accepted); a stale picture is never shown as current, and if the
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
status lines in HANDOFF and LOOP were hand-fixed again and again until contrib/opus/OPEN_WORK.md was regenerated nightly
from GitHub (issue 890). Set: Ryan (R291).

2.11 **Outside audits follow docs/REVIEW_PROTOCOL.md**: a fresh session, symptoms not theories, file, line and a short exact
quote per finding, OBSERVED or INFERRED. Findings come ranked, most important first; the job may set the count (reworded from
"at most 10"). Why: outside reviews came back half-read or made up. Set: Ryan (R154); Board (REVIEW_PROTOCOL). Ids: R154a,
review-01, review-02, review-03.

2.12 **Outside agents work in contrib/<agent>/; Muse may deliver low-code fixes (text, data, tests, tools, docs) as pull
requests, and a rules or data change is made the same way in the Godot port.** Why: "keep muse cooking" (R81); the twins must
not drift (R155b). Set: Ryan, Nov 2 (R81). Ids: R81, agents-15, muse-06.

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

## 3. PC and tools

3.1 **The product is the Godot 4 game on Ryan's Windows PC only; the browser rules (data.js, core.js, battle.js and the
campaign files) are a live reference copy: every rules change goes into both until Ryan approves their retirement.** The browser
game and pages ship nothing. Parity runs in full on every push, never skipped and never cut (no skip rule), made faster by
running battles in parallel workers (issue 978), and a Godot-only safety net runs beside it (issue 979, then saved Godot
results with a changed-battles review on rules PRs, piloted for whether its review cost is worth it). Ten rules PRs is a
progress checkpoint, not approval to retire parity. The browser rules stay until the replacement data home, a Godot balance
simulator, the ported tests and the PC tools work and are verified; retirement is then a separate recommendation to Ryan.
Why: "Godot seems way better. It's very noticeable now." (R32); PC-only (Oct 24); "Let's go with Path D ... Don't implement
the skip rule or reduce coverage ... Keep the browser rules until the replacement data, balance simulator, relevant tests and
tools are working and verified, and bring me a separate retirement recommendation then." (R312). The old "frozen" wording was
wrong: every new rule since went into both copies (round 2 review, Nov 17). Set: Ryan. Ids: R32, R33a, agents-02, R312.

3.2 **Heavy work runs on Ryan's PC (RTX 5080) through the queue; the cloud sandbox is for editing.** Why: the sandbox has about
8 GB and no GPU and runs out of memory on full meshes. Set: Ryan, Oct 21. Id: agents-23.

3.3 **Jobs and the janitor may remove only the leftovers covered here.** Everything else stays until Ryan says yes. Keep every job's PC folder lean, and the Board lists the PC folder sizes at each disk check.
Why: the PC disk filled on Nov 11 (C: 0.0 GB free, 550 GB in voidsworn_test, mostly old run copies), the queue
watcher stopped and every PC job waited until Ryan freed space himself (LOOP.md, Nov 12 02:15 and 02:20 UTC). On Nov 18 the drive fell under the 60 GB job floor from about 45 kept workspace copies and 390 GB of job scratch in the temp folder; Ryan chose (Nov 18 20:46 UTC) to let jobs clean up after themselves (R326).
On Nov 19, about 350 GB disappeared overnight (392 GB free after the Nov 18 cleanup, 41 GB the next morning). The hand cleanup removed 173 folders and raised free space to 199 GB. It kept 42 checkout copies, 26 because generated campaign outputs, audio UIDs or onboarding output were outside the safe list.
Set: Ryan, Nov 18 (R326) and Nov 19, 16:30 UTC (R336); lean folders and the disk check Board, Nov 11. Ids: ships-10, loop-17.

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


Helper PC jobs (`opus_job_head.bat`) remove their own pinned checkouts once the attempt passed and every result file is
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
exited 0 (a setup-only call or an early stop never qualifies) and that every out file is on a board/pc-out branch, then
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
names go to Ryan as a one-off list. The janitor removes an `opus<N>` or `opus<N>out*` helper folder after a day untouched
only when no running process names it, every file in its out folders is a blob committed on a board/pc-out relay branch
in the repo mirror (a loose blob is not a receipt), and everything else in it is a checkout Git shows as rebuildable with
all local commits in the mirror; files the relay skipped and other files are listed and keep the folder. helper_clone's
own top-level files (`.voidsworn-run-active`, `attempt.txt`, `repo_commit.txt`, `ships_copied.txt`) do not count as
other files. The janitor takes the helper folder's lease before deciding and holds it through the deletion, removing the
lease file and the then-empty folder last, so a held lease keeps the folder (PR 1275). A ship file with no twin in the shared build
is a superseded candidate when the build holds that ship code installed later, and a generated file under `godot/gen` with
no build twin is one when the build's `gen/manifest.json` was written later (the newer gen no longer makes it); both are archived like any other
(issue 1180 run 8, Board Nov 20). A held issue lock or a held helper lock protects scratch. The Board's keep list, `voidsworn_test\janitor_keep.txt` (one exact folder path per line, `#` for notes), keeps any candidate that is a listed path, holds one or sits inside one, logged as "kept: on the Board keep list"; a keep list that cannot be read stops the janitor (issue 1180, Board Nov 20). Active board `repo` folders, `build*`,
repo mirrors, `recipe`, `runner_backups` and other locations stay out of the scan.
Jobs also stop refilling TEMP themselves (issue 1180, Board Nov 20). The runner self-test removes its evidence folder
after a PASS (RUNNER_SELFTEST_KEEP=1 keeps it). The watchdog removes the Godot profile folder it made for one launch once
every process of that launch has exited, links as links, never a job's own profile (PC_KEEP_GODOT_PROFILE=1 keeps it).
Ship jobs and the look bench hand their owned TEMP folder to `tools/pc/scratch_done.ps1` at the end: a pass removes it;
a failure marks it `.voidsworn-run-failed` with the job's name and keeps only the newest failure per job, which the
janitor keeps for one day. When a job_wrap job ends, the janitor runs once more with `--after-job` in a
hidden window. That run shares the hourly allowance with the low-space trigger, skips without a word while another
janitor holds its lock, any `gpu_slot_N` or `gpu_solo` claim file is non-empty or the Board's pause is on, and stops
between folders if a GPU claim starts, so a solo measurement is never timed alongside it. The watchdog and scratch_done.ps1 check the
Board's pause right before each removal and keep the folder for a later pass. Why: these four leftovers
refilled C: by about 120 GB a day between nightly runs (issue 1180 dry run 2).
The log gives each candidate's size, decision and reason, along with free space before and after. The Board reads the dry
run before the first live run. A pause removes nothing (3.11).

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

3.5 **Every PC queue job is wrapped in the tmo.bat watchdog, ends with exit /b, and carries no |, &, < or > in its
arguments.** Agent runs stop after STALL_MIN minutes without progress (default 30), or at a hard ceiling (default six
hours; CODEX_CAP and WORK_CAP override the ceiling in seconds). Progress is a changed file write time in the run repo,
a new commit, or new bytes in log.txt (also stderr for workhorse runs). Git housekeeping does not count. A stall or ceiling
stop writes its reason, changed files and last log lines to the out folder's resume.txt and the -partial commit message;
the next run reads that note. timeouts.log records STALLED after N min or CEILING. Short queue commands and runner checks
keep their explicit time limits. Why: hung Godot windows blocked the queue for about three hours (G-3), but the old two-hour
agent cap killed jobs that were still working (367 and 371). Ryan, Nov 15: "do we need to get rid of that random 2 hour rule
if it's timing out actual work?" He took up a stall check, a high backstop and a saved resume note (issue 818). Set: Board
(G-3), Ryan (issue 818). Ids: G-3, feel-06, skill-pb-05.

PC jobs never use Ryan's real game profile. The watchdog gives each Godot start a fresh profile so captures cannot overwrite his settings (issue 1228, Nov 19).

PC jobs run one tools copy and report honestly (issue 1194, Board, Nov 20). `lane_tools_refresh.ps1 -Build tools_live`
installs main's tools as a verified, never-edited version under `Downloads\voidsworn_test\tools_live\` with its own
hashes, named by `tools_live\current.txt`; every `tmo.bat` outside it hands its step to that copy, so an old `build\tools`
or branch checkout never runs its own watchdog or slot reader (self-tests set `TMO_OWN_COPY=1`). The main watcher refreshes
tools_live and `build\tools` between jobs. Old lane backups and old tools_live versions rotate instead of stopping the
refresh: a backup goes only when every file in it is kept in a newer copy or a saved main snapshot, a version only when it
was replaced over a day ago and no running process names it (the refresh's own rebuildable copies, 3.3). Job bats run
their steps through `tools/pc/job_wrap.bat`: a GPU label on every claim, the tool preflight before any clone or GPU claim
(exit 2 on a missing tool), the strict watchdog hash check, a stop on a failed step unless it is marked optional, non-empty
declared outputs, and `done PASS` or `done FAILED: <steps>` then `all done`, with a non-zero exit after any failure. Helper
(Opus) proof bats start from `tools/pc/jobs/opus_job_template.bat` and call `opus_job_head.bat` from tools_live: exact
commit pins in a fresh checkout per attempt, the safe ships copy with a tracked-file check, the throwaway profile and
Ryan's options hashed before and after; the Board checks only that a bat calls the head (docs/playbooks/pc.md, issue
1303, Board Nov 20: seven bats sent back on Nov 19 and 20 for the same four mistakes). The
watchers log each job's exit code and move a failed job to `queue\failed` (`queue_b\failed`). `PC_DOCTOR.bat` is a
read-only look at the GPU claims (owner, child, age, health), damaged slot files, stuck Godot or Blender processes and
failed jobs. Why: a stale Nov 18 `build\tools` copy ran the hung 1078 probe, jobs wrote "all done" after failed steps,
the watcher filed every job as done, and a missing ffmpeg or Pillow showed only after an hour on the GPU (Neon's PC
pipeline audit, checked by the Board, Nov 19).

3.6 **The Board may double-click .bat files on the PC itself by computer use, a few clicks at a time, releasing the lock at
once, never while Ryan is playing; it never drives the PC by remote clicks to unstick a job.** Why: "can't you use computer
use for all of this?" (R126); holding the lock hides his windows; Task Manager ignores remote clicks. Set: Ryan (R126); Board
(the limits). Ids: R126a, R126b, loop-16, skill-pb-06.

3.7 **Clone on the PC with `git -c core.autocrlf=false`.** Why: CRLF breaks the campaign table export. Set: Board. Id: loop-14.

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

## 4. Ships and concepts

4.1 **Space ships, never sea ships, in the whole shape.** No boat profile, keel, raked prow, deck house, mast, funnel, crane,
railings, porthole rows or anything hanging off; a worked belly. Why: Ryan, Oct 22: "careful that these don't stretch into
obvious naval-looking ships. again, these are SPACE ships"; Nov 11: "I don't understand the random things hanging off, it reads
as naval. We need to do a full pass across all ships and factions so not naval" (R185). Set: Ryan (Oct 22, Oct 24, R185). Ids:
agents-19, agents-25, R8b, R185a, concepts-16. Detail: docs/playbooks/concepts_round2.md gate line 11.

4.2 **No gun faces backward or into the ship at rest; a turret may turn aft only to follow a target its rules arc lets it hit
(6.16, R222).** Why: "no ship in the game fires backward" (Oct 22). Set: Ryan (Oct 22; the turret line Nov 12, R222).
Ids: agents-17, blob-03, R222.

4.3 **Parts look like they belong: snapped to the real hull on a visible mount, in matched pairs at sensible hard points; the
Hullbreakers may be junky.** Why: bolt-ons on the AI hulls floated, sank or sat anywhere (Oct 21). Set: Ryan, Oct 21. Ids:
agents-18, agents-24, factions-02.

4.4 **A ship reads as armed from above at thumbnail size; each faction mounts its forward weapon its own way, never a long
barrel on the nose tip; no two factions share an outline from above; identity shows under the battle camera.** Why: "It's
really hard to tell if there's any guns right now so it barely looks like a warship" (R176); "same giant gun directly on nose.
It's good to have forward facing but it always looks the same across factions" (R183). Set: Ryan's complaints; wording Board
(R176, R183). Ids: R176b, R183a, R183b, concepts-04, concepts-05.

4.5 **Every faction is its own: its own parts kit and shape language; only invisible plumbing is shared.** Why: "all the
factions are supposed to be unique and different. Having the same parts everywhere is against that" (R151). Set: Ryan. Ids:
R151b. The faction sheets (shape, colour, where guns sit, how it breaks, its Never list) are docs/playbooks/factions.md.

4.6 **One concept style for every faction: realistic and detailed, like a photograph of a real built object**
(contrib/muse/design/concept_directions_2026_11/corsair_A.jpg); a picture that reads as an illustration, a toy or a cartoon
fails. Ryan judges the style, side by side; the Board never declares it. Why: "Pretty realistic and detailed to help with the
builds... this style is how it should look in game" (R197); "It's semi realistic but not quite" (R198). Set: Ryan, Nov 11.

4.7 **When Ryan likes a picture, the next image job edits that picture**; colour alone never sends a picture back; when image
rounds cannot reach the style without breaking the shape, stop and use the Opus build-sheet route. Why: six Hullbreaker rounds
were lost redescribing a liked picture in words (R192); "we can fix color ourselves rather than get stuck in a loop with color
fixes with image generation" (R204). Set: Ryan and Board, Nov 11 (R192, R204, R206).

4.8 **No generated concept reaches a build, or Ryan, without the Board's review against the written gate**
(docs/playbooks/concepts_round2.md). The gate's ratios and fractions (proportions per class, the stern fraction) are starting
points for a drawing, not identity. Why: "I need you to do a much more in depth review and refinement before these ever go to
actual builds" (R172); Hegemony's 4.5 : 1 was overruled by R183's 3 : 1. Set: Ryan (R172); the ratio note Board. Ids: R172a,
R172b, concepts-08, concepts-14.

4.9 **Start from what was already liked.** Why: two rounds were lost designing the Glasswrights and Hullbreakers afresh and
sanding off what made them theirs (R180). Set: Board lesson after Ryan's review (R180). Ids: R180c, factions-17.

4.10 **The finished battle is Sunward Crusade against Eclipse, on the dead-star board.** Why: one finished fight proves every
recipe and is the reference for later jobs (R167: "I want this to end with something that opus or other models can run
from"). Set: Ryan (R167, R180). Ids: R167b, R180d, handoff-01.

4.11 **Every part has a job and every weapon is its faction's own.** A part with no purpose is cut; weapons, turrets and
launchers are designed per faction from the lore bible and the faction sheet (how the weapon works shows in its mount,
housing, barrel and muzzle), never a shared silhouette; a gun in another weapon's firing lane or backblast is a clash. Why:
Ryan on the Hullbreakers: "let's get rid of the chains randomly around the ship. There's no purpose" and "a gun directly
behind the rocket pods on a16 ... seems like it conflicts"; on Eclipse: "their turrets look the same as hullbreakers" (R221).
Set: Ryan, Nov 12 (R221). Parts carry the hull's detail density: triangles and edge features per square unit, per part
type, within 25 percent of the hull's, reported on every sheet (R224: "They also just look smoother and less detailed, maybe
slightly less poly than the rest of the ship").

## 5. Ship build pipeline

5.1 **No ship is built until its build sheet passes the concept standard** (contrib/muse/design/concept_standard_2026_11/standard.md:
true side and top at one scale, underside, bow-on, length from game data, scale bar, a feature table that outranks the
pictures). Why: "I want to make sure that they are good enough to actually hand build from in blender" (R203). Set: Ryan,
Nov 11.

5.2 **The concept guides the build; it is not traced.** The Opus builder is the designer of record: it keeps the picture's
identity (mass, outline from above, character, palette, where the big features sit), fixes what would not work as a built
object, takes guns from the hull's data.js slots as batteries that make sense, carries every tier and change of height the
picture shows, and lists every change on the sheet. Why: "Use it to guide, not the very final exact design" (R207); "The guns
look randomly placed and don't make sense... the builds look like square blocks basically" and "The concept should inform and
guide but it's not a final play by play guide" (R213). Set: Ryan, Nov 11. Ids: R25 (concepts are inspiration), R207, R213.
The Board (Opus) is the final designer and director; Muse concepts. Between an accepted concept and the build the Board makes
the design calls, family distinctness included (a class that reads as a small copy of another class from above is changed in
the build), lists them on the sheet and shows Ryan the result instead of asking first. Ryan's picks of concepts and his
verdicts on pictures stand. Why: "You're the final designer and director. Muse is just concepting" (R233). Set: Ryan, Nov 12.

5.3 **The settled build method is binding** (docs/playbooks/ships.md section 0; docs/ship_pipeline/RECIPE.md): the hull designed
on the approved build sheet (5.1, 5.2), which the recipe builds as it is and never traces again (issue 592), with the stage 2
AI shape reference made from the accepted concept as an outline and grime reference only, never shipped; hand-built parts, AI parts only through a reviewed faction
library; paint from geometry masks, trim sheets and decals, never projected concept art; the seven stages. Why: projected
concept paint was dropped on all 36 hulls (R82); Ryan adopted the research route (R96); the method kept drifting between
documents (R214). Set: Ryan (R82, R96, R214, R215). Ids: R82d, R96a, R96c, R150a.

5.4 **Breakable by design, with comprehensive insides.** Every hull has real thickness and insides through the whole hull
(decks, frames, spaces, machinery; Chorus flesh and bone; Glasswright layered glass), rim bands and a dark liner where the
intact ship shows; the build check fails a hull whose broken pieces show a hollow or flat inside. Hulls built before this rule
rely on the game-side interior fallback (issue 167). Why: "the broken open pieces
are visibly empty" (R98); "so we don't run into the issues of before with just empty looking husks" (R209); "I think it's
better to be comprehensive with internal if we can without performance issues" (R215). Set: Ryan, Nov 4 and 11. Ids: R70,
R98a, R98b, R99a, R209, R215.

5.5 **Breaks follow the faction's rule and the class, never a fixed count or a straight cut**; hard points and breach anchors
scale with class and faction, read from one table (factions.md; the check reads it, issue 363). Why: "is 28 hard points for
every ship? It should vary by size of ship, faction, etc. We want things to be on theme." (R164); wrecks must look blown
apart (R186). Set: Ryan (R164, R186, R215). R99 Q2 (two transverse lines plus one longitudinal) and AGENTS.md's "two or three
break lines" are retired. Ids: R164d, R99b, R98b, ships-07, factions-04.

5.6 **Hand-built parts carry the hull's level of surface detail.** Why: "the level of texture and details seem to vary wildly"
(Oct 21). Set: Ryan. Id: agents-28.

5.7 **Structure first: the massing carries the concept's variety of shape before any detail.** Why: "There's so much less
variety in the shape and structure of it, so it's not just adding but almost removal." (R140). Set: Ryan, Nov 9. Ids: R140,
R213.

5.8 **The outline overlap against the concept is reported, not a pass bar** (was 90 percent, R147). Why: the builder is told
to depart from the picture where it does not work (R207), and a 90 percent pass let a wrong bow through (R157). Set: Board,
Nov 11 (reworded). Ids: R147, ships-05, recipe-03.

5.9 **The blob sweep (nine cells: bow, midship, stern from top, side and below) is a viewing instrument for Ryan's eye, not a
pass bar.** Why: assumed gates stop binding until measured (R121). Set: Ryan (R121d). Ids: agents-27, ships-08, blob-01.

5.10 **The guns are never bent to fit a score.** Why: casemate barrels had been bent to raise the outline match (R156). Set:
Ryan ("I agree with all of your takes", R156). Id: R156a.

5.11 **Every recipe stage is one double-click, stops on its own failure with a non-zero exit, deletes nothing, and stage 7
copies aside what it replaces before copying into the game.** Why: Ryan is not a coder; missing things fail loudly (R158).
Set: Board and Muse's conditions (R158). Ids: recipe-01, recipe-02, recipe-08.

5.12 **Ship assets ship as glb copied into the PC build; .vsm belongs to the frozen browser game.** Why: Godot cannot load
.vsm. Set: Board (G-9, G-11).

5.13 **Assets only under CC0 (Kenney, KayKit, Poly Haven, ambientCG); Quaternius is out.** Why: its licence is not CC0 (D11).
Set: Board. Ids: D11, X14.

5.14 **A build pull request carries its done-when evidence and a method line** (build sheet link, manifest, budget numbers,
changes made to the sheet); the outside check returns one without them as blocking. Why: R214. Set: Ryan, Nov 11.

5.15 **Parts read as what they are and fit together: the fit check.** Engines are bells with throats and rings, guns have a base,
mantlet, breech and muzzle, launch tubes have depth; the bow and big masses carry the concept's shaping. No part inside
another, in another gun's arc, in an exhaust cone or blocking a launcher; a fit view and fit report on every sheet and build.
Why: round 2 sheets had guns blocking rockets and in front of an engine, tubes as flat circles, engines and guns as plain
tubes, and a flat-block bow (Ryan, Nov 11, R217). Set: Ryan, Nov 11 (R217). Ids: ships-2c.

5.16 **Fidelity is whole-ship: a parts inventory, one detail level, kit first, region by region.** Every feature the concept
shows is listed with its sub-parts and modelled; every part sits at the same detail level as its neighbours; each faction's
kit holds every part type at that level; the fit check covers every part; the sheet ticks the inventory per blob-sweep cell
beside the concept. Feedback on one part becomes a rule for all parts. Why: "Engines and guns are the reference but we want
to carry that through to the whole model. Don't just patch singular behavior or examples, use it for global learning and
shaping the approach" (Ryan, Nov 11, R218). Set: Ryan, Nov 11 (R218). Ids: ships-2c.

5.17 **A machine never crosses a seam; structure that crosses a seam is torn at it, insides included.** Guns, turrets,
casemates, launchers, engines, thrusters, claws and sensor masts ride whole with one piece: the seam moves, or kinks round
them in plan. Hull plating, frames, ribs, rails, openings such as a launch bay, and every inside (decks, bulkheads, rooms,
the liner) tear across a seam, along the same ragged line as the plating over them: no inside panel stays whole across a
break or sticks out past its piece's broken hull. The stage 4 audit reads each part's kind from the build (the faction kit's
MACHINES) and fails only a machine across a seam; the export carries each seam's path and each machine's box, and the game's
death cut reads them there (fx/test/death_seam_check.gd: zero machines split, zero insides outside their piece). Why: a cut
gun reads as sliced, a torn plate as blown apart (R186, "blown apart, never sliced"); whole deck and bulkhead slabs stuck out
of the broken A16 as big flat squares (Ryan, Nov 12, issue 600). Set: Board, Nov 12 (R226; insides added from Ryan's eye,
issue 600). Ids: ships-2c.

## 6. Battle look

6.1 **Judge everything at the battle camera (camera 170, the radius Ryan plays at) at true pixel size, before any close-up.**
Why: review sheets were made closer than the camera can go (R157); Ryan plays at the standard radius and zooms in for effects
(R123). Set: Board (R157, R160); camera harness Ryan (R123c). Ids: R157a, program-02, skill-sv-01.

6.2 **Comfort is protected for everyone.** At most three big flashes a second, "big" by the W3C guideline's combined area in a
10 degree window, worked from a stated screen (default 32 inch at 24 inches); a reduce flashing option that keeps sizes and
softens the rise and fall. Tune inside the counter; never quote a strictness figure without doing the arithmetic. Why: WCAG
2.3.1 photosensitivity; Ryan: "Count by area" (R193). Set: Ryan (R187, R193); Board (R187b). Ids: R49d, R187b, uispec-04,
plan-08.

6.3 **Every explosion is route B: flash plus hot core.** Why: Ryan: "Far right in both for sure." (R170). Set: Ryan, Nov 10.

6.4 **Flame flashes and snuffs out: no flame over 0.70 s, no hot core at full heat over 0.25 s; this cap is for flame only.**
Sparks, debris, gas and cooling embers live longer, so hits throw things and leave marks. Why: fire looked wrong for space and
deaths felt sudden (R88); the cap had been applied to everything, so nothing was thrown (R193: "Flame only"). Set: Ryan (R88,
R158, R193). Ids: R88b, R158a, effects-03, deaths-02.

6.5 **Wrecks look blown apart, never sliced**: uneven pieces, no straight line across the hull, a missing bite where the core
went, ragged scorched rims, fragments between. A lance kill may stay cleaner along the beam. Why: "It's like straight lines and
even halves. It doesn't feel like an explosion or major hit happened." (R186). Set: Ryan, Nov 11. Ids: R186, deaths-05,
deaths-09, deaths-11.

6.6 **The kill moment holds and slows on cruiser, capital and flagship kills** (the camera stays through the core flash, a
short skippable slow beat). Why: "just do big ships and flagship for slow mo" (R73); "Hold and slow" (R193). Set: Ryan (R73,
R193); replaces the Board's R123 "the camera is never taken for a capital death". Ids: R73a, R123a, deaths-04, uispec-05.

6.7 **Effects start on the ship** (a hard point, a breach anchor or the hit surface), never at a box corner or in empty space.
Why: "random thrusters or smoke popped up away from the ship itself? it looks all wrong" (R150). Set: Ryan (R150); method
Board (R153). Built: the attach point service in godot/fx/fx_hull.gd (authored point, else surface ray, else skipped and
counted), checked by godot/fx/test/attach_check.gd (issue 370). Ids: R150b, R153, effects-05.

6.8 **Hits are weighty and readable at the battle camera**: mass-scaled shudder and kicks corrected by thrusters, damage on the
hull itself with per-weapon marks, wounds that cool to scars, thrown matter big enough to read at camera 170; light on
neighbouring hulls stays faint until the counter measures lit area. Why: "a simple cartoonish push back. It doesn't feel
weighty, cinematic or accurate." (R50); "it's just an orange shape with weird smoke, the actual underlying ship looks the same"
(R39); "Merge, then push harder" (R208). Set: Ryan (R39, R43, R50, R208). Ids: R39, R43, R50a, R208.

6.9 **No flat lines for fire or hits**: weapon fire and hits are baked sims (flipbooks), sparks are small glowing points with
curved, slowing trails. Why: "It looks so simple and like Microsoft paint." (R146). Set: Ryan, Nov 9. Ids: R146, R90a.

6.10 **A bigger ship dies longer, not just larger; each faction breaks its own way; the flash core stays near white so a death
always reads as a death.** Why: every faction died the same faint puff (deaths_and_hits.md). Set: Board, Nov 11, from Muse's
staging table; the sizes and times are tuning values (0.4). Ids: deaths-03, deaths-10. Detail:
docs/playbooks/deaths_and_hits.md. R367 (Ryan, Nov 20 2026, decision card: "Full faction deaths"): each metal faction dies in its
own colours and break as deaths_and_hits.md "How each faction dies" describes, replacing the shared orange fire; the colours
come from faction_looks.json, the one faction colour file (Eclipse violet-white and white-gold, not green). Built for the
Glasswrights and Eclipse in issue 1399; the Crusade, Hegemony and Hullbreakers follow.

6.11 **Shields in space keep their faction colours; at rest, Rim and Gap: a faint rim in the faction edge colour on live
sides, a dark gap where a side is open, nothing else** (R246, Nov 14). Why: his Oct 24 ruling (the cyan-only rule retired) and his
Rim and Gap pick with Muse (R246). Set: Ryan (R3, R246). SUPERSEDED, kept so nobody follows it: "at rest invisible, a faint edge
glow on zoom, hover or a recent hit" (R163, ended by R246). Ids: R3a, R163a, R246, effects-04.

6.12 **Effects may spend the RTX 5080's headroom inside the scene gate, with a lower setting kept.** Set: Ryan (R88c). See
3.9.

6.13 **Plasma is light blue.** Why: his call on the damage marks reference (R46). Set: Ryan, Oct 26. Ids: R46a, lore-04.

6.14 **Normal hits mark the hull (scorch, wounds, scars); a hull opens into a real break only when a section is nearly gone or
on death.** 20 percent of a section's hull is the starting value, judged by eye. Why: cut-out holes on every hit "looked like
hollow cardboard" (Nov 1 playtest). Set: Ryan (R80, R216).

6.15 **Section damage tint may show on small ships if it reads at camera 170**; the hits pass tries it by eye on frigates (the
old ban had no reason and is retired). Set: Ryan (R80, retired R216).

6.16 **Spend death effect cost where the eye is (the tell, the break, the core flash); long cooling stays cheap.** 2 s and 14 s
are starting values. Why: deaths now run 3.5 to over 10 seconds in three beats (R186, R193). Set: Ryan (R90, R216).

6.17 **Turret guns turn to face their target when they fire; fixed side guns (casemates, broadside batteries) stay fixed.**
A turret traverses smoothly (never snaps, RULEBOOK 7.1), within its arc, and returns to rest; the gun's muzzle and its effects
start at the turned barrel. Why: today every gun is a fixed mesh (no aim code in godot/render/ship_view.gd or
godot/fx/fx_weapons.gd); turning turrets make a fight read and suit the detailed guns now being built (R217). Set: Ryan, Nov 11
(R219: "I agree with your design on turrets"). A turret may turn aft only to follow a target its rules arc lets it hit
there; at rest no gun ever points backward (4.2). Set: Ryan, Nov 12 (R222: "yes agree on your turret facing rule"). Built (issue 560): a turret is its own node in the ship's glb
(docs/ship_pipeline/HARDPOINTS.md "Turrets"; the kit marks it, tools/blender/kits/README.md); the attach point service in
godot/fx/fx_hull.gd turns it, checked by godot/render/test/turret_check.gd. Hulls exported before it keep fixed guns.

## 7. Movement

7.1 **Movement is never sudden, jerky or stop-start, and feels like space**: thrusters fire wherever a ship would need them
(braking, turning, stopping a turn, sliding). Why: "I don't want things to look jerky and the smooth call was because movement
was very stop/start and sudden. Thrusters should be involved when it makes sense on braking and turns." (R189). Set: Ryan,
Nov 11. Replaces the letter of R76 ("thruster puffs only on turns, no side-to-side shuffle"). Ids: R76a, R189a, movespec-01.

7.2 **The main engine does the travelling.** A one-hex sidestep or back-off may slide on thrusters; a longer run turns its nose
onto the course and burns the main engine; anything flown on thrusters alone is visibly slower and gentler. Why: "for one tile
over, it tracks but not when they're going like 3-10 tiles down just almost skating on thrusters" (R195). Set: Ryan, Nov 11.

7.3 **One ship moves at a time, at a weighty pace (about twice as slow as Nov 1); longer enemy turns are accepted; cinematic is
the default with a brisk option.** Why: "I don't want to sacrifice the feel of the game/space/the ships." (R50). Set: Ryan
(R50, R64); option Board (R50d). Ids: R50b, R50d, R64a, movespec-06.

7.4 **Movement playback never changes rules results.** A LOOK change keeps the route, end hex and facing; a RULE change (route
or facing) needs Ryan's own ruling and touches both rule twins. Why: R188's frame for the audit. Set: Board, Nov 11 (R188).

7.5 **No roll into turns.** Why: nothing in space leans a ship; the audit reversed the earlier bank (movement_audit_code.md).
Set: Board, Nov 11. Id: movespec-04 (the 4 degree bank, retired).

7.6 **Flip and burn stays off for now, to be looked at again now that braking jets are on screen.** Why: left alone on the
Board's advice (R193). Set: Ryan (R64, R193). Ids: R64c, feel-02.

7.7 **Every number in contrib/opus/briefs/movement_spec.md is a tuning value chosen by eye from motion strips.** Set: Board
(R189's rewrite). Ids: R131a, R131b, movespec-02, movespec-03, movespec-05, movespec-07.

7.8 **Strike craft move like small agile craft (quick turns, short burns), still never jerky.** Why: small craft should feel
quick, inside 7.1 (R189, R195). Set: Ryan (R55, R216).

## 8. Battle sound

8.1 **A battle sounds clean and tactical; never thin and weak, cheesy or arcade-like, harsh or annoying.** No zaps, pews,
rising whooshes or stock explosions; weight in the low and low-mid with a soft top. Why: "The sounds that I've heard from the
game so far are bad" (R163). Set: Ryan (R163, R171). Ids: R171b, program-13, sound-01, sound-03.

8.2 **Weapons stay dry; big moments get weight**: deaths, capital hits and shield breaks get tails, sub-bass, a bed for the
length of the picture, ducking under the core flash and a beat of near-silence after a capital dies. Why: "short and dry" was
built as no tails, so a ten second death had a one second sound (audit item 9); Ryan said "Go, in my order" (R193). Set:
Board's reword, Ryan's go (R187, R193). Id: sound-02.

8.3 **The gun chooses the sound of its hit**, by weapon and by what it struck. Why: one family of hit clips played whatever
fired (audit item 8). Set: Ryan's go (R193); built in issue 506.

8.4 **Variation: a cue heard often never plays the same take twice in a row; four takes is the starting count.** Set: Board
(reworded from "at least four"). Id: sound-04.

8.5 **Free and licensed sources only; music from free licensed tracks first; in battle brass and tactical percussion, a synth
drone on the map.** Why: money and licences (3.8); his picks of Muse's decision pack ("For muse picks, agreed on all counts",
R37). Set: Ryan (R37, R40). Ids: R37b, R40a, sound-05.

## 9. Screens and interface

9.1 **One interface for the whole game: the ember orders sheet; lime is retired.** Words on a smooth darkening of the scene, no
panels, square corners, one accent (ember #ff8a3a) for the next action, NEM red for the Nemesis only. Why: "The whole thing
clearly reads as a Claude based UI." (R137); "the faction specific views went wayyyy too hard. We still need one specific UI
for the game that is consistent." (R141); "Retire lime" (R191). Set: Ryan (R137, R141, R176, R191). Ids: R137b, R141, R149,
R176a, rail-01, rail-04. Detail: docs/playbooks/screens.md.

9.2 **Avoid the AI-made look**: neon accent on dark slate, glass or frosted panels, pill buttons, identical cards, indigo to
purple gradients, glowing blurs. Why: "I really like the concept but it's getting pretty busy and it also reads as AI generated
still" (R164); his list (R174). Set: Ryan. Ids: R164c, R174c.

9.3 **Say less**: a screen holds only what its decision needs; the rest is one hover or key away; nothing is deleted from the
game, and the pull request lists every moved item. Why: "We don't need to over explain EVERYTHING in this one UI." (R177).
Set: Ryan. Ids: R177, screens-06, briefing-05, rail-05.

9.4 **Readable: nothing read below 17 px at 1080, 4.5 to 1 contrast over the brightest and darkest board, no overlaps at any
fleet size.** One floor, 17 (the old 12 px floor is retired). Why: Ryan asked for a readability pass (R176); text overlapped
the flagship name (R177). Set: Ryan (R176); one floor Board. Ids: rail-06, uispec-02, R136b.

9.5 **Battle screen: KEEL, the bottom shelf and two corner blocks.** Ryan picked KEEL v5 on Nov 17 (issue 1021) to open up
the board, replacing the E1 Ledger rail. **Glacier #92b8e8 is for shield readouts only, on every screen; the shields drawn in
space keep faction colours.** Set: Ryan, Nov 11 (R210: "Glacier pale blue", "Yes, that's right"). Replaces R3's "interface
shield bars stay cyan". Ids: R3b, plan-02. See docs/playbooks/screens.md for the layout.

9.6 **In battle, faction colour never touches names, plates, bars or panels; the enemy faction is its crest and plain name.**
Why: one UI with faction colour only as a small accent (R141). Set: Board (R125). Ids: R125b, uistyle-06.

9.7 **One UI scale law, k = clamp(height / 1080, 0.6, 2.2) times the player's UI scale, in ui_scale.gd only.** Why: six copies
disagreed. Set: Board (R136). Ids: R136a, uispec-01.

9.8 **Comfort settings (UI scale, reduce motion, reduce flashing) are reachable mid-battle; the developer surface hides behind
a dev flag.** Set: Board (R125). Id: R125a.

9.9 **Opening a screen never changes the run or the save.** Why: Muse found a draw call that created a record (PR 349). Set:
Board. Id: screens-11.

9.10 **Options first, then build**: anything new in look is shown as two or three options, Ryan picks, then it is built.
Why: "Options first, then build" (R167); "every step" of the redesign shows distinct options (R137c). Set: Ryan. Ids: R137c,
program-01.

9.11 **Torpedoes fire now: they fly and land in the same activation as any gun, after a heavy flight of about 1.5 s, and
show their hit chance like any gun.** No lane on the board, no hex aim, no parked torpedo and no strike at the next turn; point
defence and screening wings still get their chance to shoot a salvo down. Why: "i really dont like the way torpedoes look today
and how they act. the arrow lines, the delay, etc. it's not intuitive, it doesnt fit the vibe, UI or graphics of the rest of
the game" (Nov 20, 17:59 UTC); he picked TP-B "Fire now" over a lock-on and a cleaner lane (18:46 UTC). Set: Ryan, Nov 20.
Id: R364 (replaces R76b's lane and next-turn strike; the visible flight and the clear hit or miss stay).

9.12 **The run debrief shows, in order: headline, first loss, what this run bought, the heir, the recap, the next run, exits.**
Why: a run is meant to be lost; the debrief names what the death bought (contrib/opus/briefs/debrief_spec.md). Set: Ryan
(R137a). Id: debrief-01.

9.13 **After a battle: one prize screen, one confirm; a prize may open for detail before the confirm.** Set: Ryan (R23, R216).

9.14 **Keep every ship reachable from the battle HUD when the fleet outgrows its space.** KEEL pages the fleet strip when it
fills; hover gives the full name and health. This replaces E1's "and N more" hover (R220, Ryan: "yes that's fine"). Why: a
large fleet can outgrow the available space, but the strip is also how the player picks a ship. See issue 1021.

9.15 **The start screens (title, Settings, Credits, faction and admiral, flagship aspect, Progression, Lineage, Help) build
from one kit, godot/ui/theme/orders_kit.gd, on glass_shell's orders sheet.** One font set (Big Shoulders Display heads,
Barlow words, Azeret Mono figures), one ember primary per screen with quiet secondaries, labels that wrap inside their
container, rows with one control column, cards whose actions line up, the Back left and the primary right, and the ui_*
sounds on hover, press, back and confirm. Esc goes Back on every start page. The player's UI scale is never capped: a layout
fits 831 design pixels tall (Larger at any 16:9 window) instead. Why: the start flow mixed three font sets and every screen
built its own widgets (Neon front-end audit, Nov 19; R333 cohesion), and Ryan: "the title screen is SUPER basic,
faction/admiral selection is also very basic and also formatting looks odd and not lined up". Set: Board under R333 (issue
1217). Detail: docs/playbooks/screens.md section 2.

9.16 **The game is mouse and keyboard only: no controller play in battle or on the map.** Menus may keep their arrow-key and
Enter focus. Why: Neon's player audit (Nov 21) found menus promise controller focus while battle and map have no gamepad
input; Ryan scoped the game to mouse and keyboard. Key rebinding, a colorblind mode and an in-game rules reference are later
work (issue 1454). Set: Ryan (R380).

9.17 **A ship's move and turn can be undone until it does something that cannot be taken back** (fires, rams, boards, uses
an ability, leaves by an exit edge, or ends its activation). Why: a misclick in a permadeath game should not cost a ship
(Neon player audit, Nov 21). Both rules copies (3.1). Set: Ryan (R376, issue 1450).

9.18 **A campaign battle saves at the start of each round and resumes there**, with Save and Quit to title in the battle
menu; the snapshot clears when the battle ends. Why: a crash or a real-life interruption sent a 20 minute boss fight back to
round 1 (Neon player audit, Nov 21). Set: Ryan (R378, issue 1451).

9.19 **New boss and build-variety content is options first** (9.10): bosses get a second phase at half health from an
options sheet Ryan picks (issue 1452); capstone perks, relics, admiral command twists and own Glasswright and Chorus abilities
come as a design pack first (issue 1453). Set: Ryan (R377, R379).

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
issue 1484).

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

12.4 **A change to data.js or battle.js names every copy it must refresh, and rules parity passes.** Why: the oracle copies
drifted (R155). Set: Board. Id: R155b.

12.5 **The look bench: bench a commit twice and keep the second run; a change differs where it is meant to and nowhere else;
a new baseline is committed only when the Board accepts the change.** Why: the first run pays for shader warm-up (R162).
Set: Board. Ids: R162c, program-07, skill-sv-02, skill-sv-03.

12.6 **The player-path recording of Battles 1 to 3 is the acceptance check for visual and teaching changes.** Use
`tools/pc/jobs/player_path.bat` on the shared installed build with a fresh, isolated profile and player defaults. Judge the change
in those recordings. Use the look bench and bot captures for comparison and diagnosis. Earlier captures hid the
cut-ins, danger overlay, teaching cards, target card and battle voice that a new player encounters. The look bench also
draws meshes at full detail. Set: Ryan, Nov 19 (R328).
