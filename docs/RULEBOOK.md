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
Ryan, Nov 11 (R214). FINDINGS stays as the dated history; this book is the live source.

0.3 **Which document wins.** This book; then the playbook for the area; then AGENTS.md; then briefs. HANDOFF.md and LOOP.md
win for current status only. Between two of Ryan's rulings the later one wins, and the entry here is edited, never only a new
FINDINGS row. Why: corrections written as new rows left the old wording reading as the rule (R183's withdrawn gate line).
Set: Board, Nov 11, from Muse's outside sweep (contrib/muse/reviews/rules_sweep_2026_11.md, Parts 4 and 6).

0.4 **A number in a document is a starting point judged by eye, unless it protects comfort, frame rate, saves, crashes or rules
parity.** A number names its measurement, or says it is a tuning value. Why: every hit size was tuned under a cap that was
never the guideline it cited (R187); Ryan wanted the audit to find "these weird arbitrary, like, guidance on that is making
it, you know, more restricted and less realistic and cinematic than it should be". Set: Ryan, Nov 7 (R121: assumed gates stop
binding until a measurement earns them back) and Nov 11 (R187: "Keep comfort, loosen rest").

0.5 **Tidy is a fault on screen.** Even, straight, identical, instant, capped, on rails or one scale reads as staged. Why: the
wrecks "feel like they're just getting sliced in half" (R186). Set: Ryan's complaint, Board's wording (R187).

0.6 **A rule that rests on a fact that can change names what ends it** (a model's version, a plan's limit, a tool that is
down). Why: the Codex cloud ban, the Fable helper counts and the Kimi sentence outlived their facts. Set: Board, Nov 11 (Muse
sweep Part 4).

0.7 **A rule that says the game does something needs a capture or a check that shows it, or the words "not built yet".** Why:
specs described braking jets and slow motion the game did not have (issue 492). Set: Board, Nov 11.

0.8 **After a day with many rulings, the Board has an outside model check that each one landed in the document a worker reads
(a dropped-context sweep).** Batch rulings that only set a rule (no working method) may land in this book alone. Why: the
insides rule was recorded but never reached the builder's playbook (R209, R211); Muse's method audit of R201 to R218 found
the screens half of R218 written nowhere (issue 558). Set: Board, Nov 12 (R211, issue 558).

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

2.4 **The job board is GitHub issues with owner labels, each opening with the fixed block** (Owner, Brief, Deliver to, Branch,
Effort or Models, Done when; ship builds add Route per part, Inside, Paint stack, Budget, R214). Agents deliver on
`codex/`, `muse/`, `work/` or `opus/issue-N` branches; nobody pushes to main except LOOP.md and FINDINGS. Why: any agent can
pick up a job without asking, and main stays reviewed. Set: Ryan, Nov 2 and 4 (R75, R102). Ids: agents-04, agents-05,
agents-09.

2.5 **Never write a GitHub closing word before an issue number in a commit; use `gh api` REST, never GraphQL.** Why: commit
1429ca3 closed PR 320 by accident; GraphQL is blocked here (ends when it is unblocked). Set: Board. Ids: loop-15, loop-20.

2.6 **The seats.** Ends when a seat's plan or model changes; the live state is LOOP.md "The seats".

| Work | Seat | Why |
|---|---|---|
| Board: reviews, merges, specs, visual calls, picks put to Ryan | One Claude thread, Opus 5.5 | judgement is the bottleneck (R128, R194) |
| Every ship model in Blender (blockouts, build sheets, hulls, kits, the station); hard or open-ended builds; read-only code audits | Opus 5.5 workers, two at most while the Board runs | Ryan: "I think builds in blender should come from Opus" (R205); the five-hour limit was hit with three (R194) |
| Well-specified code: rules, tests, scripts, screens to a spec | DeepSeek V4.1 Flash workhorse on the PC | merged on one review pass for nine cents (R127, R134) |
| Pipeline and engine jobs that need Codex's depth (export, import, effects plumbing); captures and benches only when no cheaper seat can run them | Codex on the PC, one job at a time, while its weekly usage lasts | "Codex and deepseek should do other work to free you up on these crucial items" (R206); "We're starting to run low on codex usage ... We may just need to move other things to opus instead of codex being the workhorse with DeepSeek" (R219) |
| Checks of a seat's own work: a different model checks it (Codex's pipeline work is traced or checked by Opus or Muse) | Opus worker or Muse | "It feels like that makes sense to be checked by a different model" (R219) |
| Concept pictures by image to image, research, design text, outside checks | Muse (Rey chairs); Ryan starts every run | several models, an outside view (R128) |
| Ideation | Flash and Grok, through Muse | free and broad |

No Fable helpers: Ryan's Fable allowance is spent ("I just used the final fable reset", R180). Kimi is off and was never fairly
tested (only the pay-as-you-go tier, R164). Codex's weekly usage is watched at every board check (it was at 19 percent with
six days to its reset on Nov 11, R219): when it runs low, code jobs go to the DeepSeek workhorse and Opus workers, and Codex
keeps only what needs it. Ids: R128, R180e, R205, R206, R219, agents-12.

2.7 **Codex runs the model Ryan picked: GPT 6.1 Sol today, pinned by name in tools/pc/codex_issue.bat.** Never a weaker
model by accident (Luna) and never switched to another one (Astra) without his yes; no Codex cloud tasks or cloud reviews.
Why: "We don't want to force using Astra or something. Just not accidentally run Luna or something, that's why we usually
use Sol 6.1" (R216). Ends when Ryan picks another model. Set: Ryan, Nov 2 (R75) and Nov 11 (R216). Ids: R75b, agents-07.

2.8 **Muse: a blind Rey leg written before Rey reads the others, on research, design and review jobs** (not on low-code fix
jobs). Why: "Let's ensure muse is running its own blind leg room not just chairing." Set: Ryan, Nov 3 (R89). Ids: R89,
agents-10, muse-07.

2.9 **A Muse issue is never edited once Ryan may have started it; new scope is a new issue.** Why: Rey kept to the version it
had read and the Board's later edit was lost (R200). Set: Board, Nov 11.

2.10 **Every outside finding is checked against the repo before anything is built on it; name the root cause, and check the
arithmetic yourself.** Why: the Board told Ryan the flash counter was "13 times" too strict; by viewing angle it was 5 to 7
(R193). Set: Ryan (R45, Oct 26); Board (R193). Ids: R45a, X22.

2.11 **Outside audits follow docs/REVIEW_PROTOCOL.md**: a fresh session, symptoms not theories, file, line and a short exact
quote per finding, OBSERVED or INFERRED. Findings come ranked, most important first; the job may set the count (reworded from
"at most 10"). Why: outside reviews came back half-read or made up. Set: Ryan (R154); Board (REVIEW_PROTOCOL). Ids: R154a,
review-01, review-02, review-03.

2.12 **Outside agents work in contrib/<agent>/; Muse may deliver low-code fixes (text, data, tests, tools, docs) as pull
requests, and a rules or data change is made the same way in the Godot port.** Why: "keep muse cooking" (R81); the twins must
not drift (R155b). Set: Ryan, Nov 2 (R81). Ids: R81, agents-15, muse-06.

2.13 **A job's scope lists every folder its earlier runs touched, and every baked picture keeps its bake script in the repo.**
Why: PR 327 merged without its bake scripts (R157). Set: Board.

2.14 **Effort follows the kind of job**: high for the Board, audits and design passes; medium for first builds judged by eye;
low for well-specified code. Why: a miss on a look costs a whole extra round (R168). Set: Board.

2.15 **The repo is the record.** Rulings go to FINDINGS with Ryan's words and the problem he was reacting to; board state to
LOOP.md; rules to this book. Why: the other models only see the repo. Set: Ryan (project instructions; R189).

2.16 **Argon stays off.** Why: "My subscription ran out and it just wasn't that useful to justify the cost" (R216). Ends when
Ryan pays for it again. Set: Ryan, Nov 5 and 11 (R216).

## 3. PC and tools

3.1 **The product is the Godot 4 game on Ryan's Windows PC only; the browser game is frozen as the rules oracle** (changed only
for rules fixes, so the parity check has something true to compare against). Why: "Godot seems way better. It's very
noticeable now." (R32); PC-only (Oct 24). Set: Ryan. Ids: R32, R33a, agents-02.

3.2 **Heavy work runs on Ryan's PC (RTX 5080) through the queue; the cloud sandbox is for editing.** Why: the sandbox has about
8 GB and no GPU and runs out of memory on full meshes. Set: Ryan, Oct 21. Id: agents-23.

3.3 **Never delete anything on Ryan's PC; keep every job's PC folder lean, and the Board lists the PC folder sizes at each
disk check.** Why: the PC disk filled on Nov 11 (C: 0.0 GB free, 550 GB in voidsworn_test, mostly old run copies), the queue
watcher stopped and every PC job waited until Ryan freed space himself (LOOP.md, Nov 12 02:15 and 02:20 UTC). Set: Ryan
(project instructions: never delete); lean folders and the disk check Board, Nov 11. Ids: ships-10, loop-17.

3.4 **One GPU job at a time, and check Ryan is not using the GPU first.** Why: a long bake holds every later job, and he uses
the GPU himself ("can we have codex pause gpu usage?", R173). Set: Ryan (R173); Board (queue). Ids: R173b, effects-09.

3.5 **Every PC queue job is wrapped in the tmo.bat watchdog, ends with exit /b, and carries no |, &, < or > in its
arguments.** Why: hung Godot windows blocked the queue for about three hours (G-3). Set: Board. Ids: G-3, feel-06,
skill-pb-05.

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

## 4. Ships and concepts

4.1 **Space ships, never sea ships, in the whole shape.** No boat profile, keel, raked prow, deck house, mast, funnel, crane,
railings, porthole rows or anything hanging off; a worked belly. Why: Ryan, Oct 22: "careful that these don't stretch into
obvious naval-looking ships. again, these are SPACE ships"; Nov 11: "I don't understand the random things hanging off, it reads
as naval. We need to do a full pass across all ships and factions so not naval" (R185). Set: Ryan (Oct 22, Oct 24, R185). Ids:
agents-19, agents-25, R8b, R185a, concepts-16. Detail: docs/playbooks/concepts_round2.md gate line 11.

4.2 **No gun faces backward or into the ship.** Why: "no ship in the game fires backward" (Oct 22). Set: Ryan. Ids: agents-17,
blob-03.

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

5.3 **The settled build method is binding** (docs/playbooks/ships.md section 0; docs/ship_pipeline/RECIPE.md): the hull traced
from the stage 2 AI shape reference, which is never shipped; hand-built parts, AI parts only through a reviewed faction
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
docs/playbooks/deaths_and_hits.md.

6.11 **Shields in space keep their faction colours; at rest invisible, a faint edge glow on zoom, hover or a recent hit, a
downed side a dark gap.** Why: his Oct 24 ruling (the cyan-only rule retired) and his yes to the Board's resting pick (R163).
Set: Ryan (R3, R163). Ids: R3a, R163a, effects-04.

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
(R219: "I agree with your design on turrets").

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

9.5 **Battle screen: E1 Ledger. Glacier #92b8e8 is for shield readouts only, on every screen; the shields drawn in space keep
faction colours.** Set: Ryan, Nov 11 (R210: "E1 Ledger", "Glacier pale blue", "Yes, that's right"). Replaces R3's "interface
shield bars stay cyan". Ids: R3b, plan-02.

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

9.11 **Torpedoes show their hit chance and a visible flight with a clear hit or miss.** Why: his playtest call (R76). Set:
Ryan, Nov 2. Id: R76b.

9.12 **The run debrief shows, in order: headline, first loss, what this run bought, the heir, the recap, the next run, exits.**
Why: a run is meant to be lost; the debrief names what the death bought (contrib/opus/briefs/debrief_spec.md). Set: Ryan
(R137a). Id: debrief-01.

9.13 **After a battle: one prize screen, one confirm; a prize may open for detail before the confirm.** Set: Ryan (R23, R216).

9.14 **A fleet too big for the battle sheet shows its first ships (at least two lines) and folds the rest into "and N more",
with a hover that lists them.** Why: the narrower sheet (R218) cannot list twenty ships. Set: Ryan, Nov 11 (R220: "yes that's
fine").

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

10.9 **Nebula colour is picked per region by eye on the sky sheet; no indigo to purple gradient; the faction tint share is a
tuning value.** Why: Ryan listed indigo to purple gradients among the AI-made tells (R174). Set: Ryan (R82, R216).

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

## 12. Automatic checks

12.1 **Checks protect crashes, saves, rules parity, comfort and frame rate. A test that pins a look number is updated in the
same pull request that changes the picked look.** Why: tests fixed hit sizes, piece counts and cue counts that the audit fixes
had to move (contrib/codex/reviews/rules_sweep_checks.md). Set: Board, Nov 11 (0.4).

12.2 **A check's state comes from the real functions, never typed by hand; missing things fail loudly; one source per fact.**
Why: a fixture typed by hand let 137 checks pass while real play was broken (R155). Set: Board, after the outside audit
(R154 to R161). Ids: R155a, handoff-08.

12.3 **Every push to an agent branch runs the checks once; every test script under godot/**/test/ has its line in
godot/tools/ci/godot_checks.txt.** Why: a missing test must fail loudly (PR 400). Set: Board. Ids: handoff-07, loop-10.

12.4 **A change to data.js or battle.js names every copy it must refresh, and rules parity passes.** Why: the oracle copies
drifted (R155). Set: Board. Id: R155b.

12.5 **The look bench: bench a commit twice and keep the second run; a change differs where it is meant to and nowhere else;
a new baseline is committed only when the Board accepts the change.** Why: the first run pays for shader warm-up (R162).
Set: Board. Ids: R162c, program-07, skill-sv-02, skill-sv-03.
