# PACK: Voidsworn repo state audit (Nov 7, 2026)

## 0. What this pack is

On Nov 7, 2026 the owner (Ryan) commissioned a validation audit of the CURRENT STATE of the shared GitHub repo rcbailey12/voidsworn, ahead of the lead agent (Opus, Claude) returning from a weekly usage cap at about 18:40 CST today. The question: is the repo ordered and ready for Opus to resume, without overwhelm and without conflicts? Four legs read this same pack blind: a Rey leg, DeepSeek, Qwen, and a Flash ideation leg. A chair synthesis follows, and the deliverables are (a) a readiness verdict with a conflict map and a proposed execution order, and (b) a short briefing prompt the owner can hand Opus when it comes online.

Facts about the cast, stated by the owner on Nov 7, 2026 (treat as given): Opus returns in about 6 hours. ChatGPT is DOWN until its reset in 3 days (about Nov 10); Opus is to cover the checker/red-team seat in the meantime. Codex is down for a while (owner, Nov 5-6). Gemini Argon is blocked (Google AI Pro lapsed Nov 5); Flash runs ideation only, never as a reviewer. Rey (muse) has been running the board and the audit program while Opus was capped.

## 1. The board system in brief (standing protocol, R75)

Jobs are GitHub issues with owner labels: codex, muse, opus, ryan, blocked. Outside agents deliver PRs on named branches; Opus reviews and merges; nobody pushes main except a docs-only exception for contrib/opus/LOOP.md. Every issue carries a fixed top block (Owner, Brief, Deliver to, Branch, Models or Effort, Done when). FINDINGS.md (contrib/opus) is the rulings registry and overrides older docs. LOOP.md (contrib/opus) is the board loop state file: lock, current state, queue order, holds, waiting-on-owner list.

## 2. Snapshot: open issues (live API, Nov 7, 2026, about 12:45 CST)

# Open issues snapshot (Nov 7, 2026, ~12:45 CST): 38

- #24 [codex,blocked] Progression step 7: Finish the Nemesis teaching loop (created 2026-11-02, updated 2026-11-05)
- #26 [codex,blocked] Progression step 10: Un-gate Heat after the first loss (created 2026-11-02, updated 2026-11-02)
- #27 [codex,blocked] Progression step 11: Extend telemetry for Nemesis rates and pacing (created 2026-11-02, updated 2026-11-05)
- #29 [codex,blocked] Progression step 13: Roll the tree out to the remaining factions (created 2026-11-02, updated 2026-11-02)
- #30 [codex,blocked] Progression step 14: Add capstone mastery (created 2026-11-02, updated 2026-11-02)
- #41 [codex,blocked] Crusade fields captured Hegemony and Eclipse hulls from run 3 (R78 Q9) (created 2026-11-02, updated 2026-11-02)
- #42 [codex,blocked] Chorus core eating in sector 3 (R78 Q15) (created 2026-11-02, updated 2026-11-02)
- #43 [opus,blocked] Eclipse restored portraits change with each restoration (R78 Q17) (created 2026-11-02, updated 2026-11-02)
- #44 [codex,blocked] Run 5 finale board brightens as the new sun catches (R78 Q18) (created 2026-11-02, updated 2026-11-02)
- #48 [opus] Glasswright species design: holistic pass from Rey concept inspiration (created 2026-11-02, updated 2026-11-02)
- #92 [codex,blocked] Debrief screen: apply the Muse layout and copy on top of step 4 (created 2026-11-03, updated 2026-11-05)
- #96 [opus] Owner rulings on the issue 76 ship pipeline research (created 2026-11-03, updated 2026-11-03)
- #98 [opus] Owner rulings on the issue 81 terrain effects research (created 2026-11-03, updated 2026-11-03)
- #100 [codex,blocked] Terrain fx 2: debris, dead star well, old looks and the quality ladder (created 2026-11-03, updated 2026-11-05)
- #120 [codex,blocked] Nemesis redesign 1: hunter draw per story point and commander registry (R85) (created 2026-11-03, updated 2026-11-03)
- #121 [codex,blocked] Nemesis redesign 2: meetings, clock, adaptation and lessons per commander (R85) (created 2026-11-03, updated 2026-11-04)
- #122 [codex,blocked] Nemesis redesign 3: telemetry, Nemesis panel and tests (R85) (created 2026-11-03, updated 2026-11-03)
- #139 [codex,blocked] Graphics leap 3: nebulas and ion storms as real volumes (R88) (created 2026-11-04, updated 2026-11-04)
- #140 [codex,blocked] Graphics leap 4: rocky and terran planets with real geology (R88) (created 2026-11-04, updated 2026-11-04)
- #169 [codex,blocked] Breakable by design: Pyre-Barge hull thickness, decks and authored break lines (R98) (created 2026-11-04, updated 2026-11-05)
- #193 [opus] Tripo challenger test: per-part high-poly generation against hand parts (bounded proposal) (created 2026-11-05, updated 2026-11-06)
- #194 [opus] Ideation outcome: five promoted options for the ship look pipeline (screened proposals) (created 2026-11-05, updated 2026-11-05)
- #198 [codex] Pyre-Barge round 7: V3 with detail back in, outline features and red plates, against V1 with the same paint (R108) (created 2026-11-05, updated 2026-11-05)
- #199 [codex] Backdrops 7: station surface detail pass on top of the repaint (R109) (created 2026-11-05, updated 2026-11-05)
- #200 [muse] Research: close-range surface detail standard for ships and stations (R109) (created 2026-11-05, updated 2026-11-05)
- #201 [muse] Review: test checks for the Nemesis redesign #120 to #122 (created 2026-11-05, updated 2026-11-05)
- #202 [muse] Playtest checklist for the next build (created 2026-11-05, updated 2026-11-05)
- #206 [opus] Tooling note: Kamome harness pattern for Blender build jobs (Ryan, via Rey, Nov 6 2026) (created 2026-11-06, updated 2026-11-06)
- #207 [opus] Ceiling pressure test rulings + benchmark scene job (Ryan, via Rey, Nov 6 2026) (created 2026-11-06, updated 2026-11-06)
- #208 [opus] Graphics red team rulings + settlement program (Ryan, via Rey, Nov 6 2026) (created 2026-11-06, updated 2026-11-06)
- #209 [opus] Build-route comparison: AI inspo + high-detail hand build vs sectioned AI generation (Ryan, via Rey, Nov 6 2026) (created 2026-11-06, updated 2026-11-06)
- #210 [opus] FX audit rulings + settlement program (Ryan, via Rey, Nov 6 2026) (created 2026-11-06, updated 2026-11-06)
- #211 [opus] HunyuanVideo-Foley probe: generated Foley for captured sequences (Ryan, via Rey, Nov 6 2026) (created 2026-11-06, updated 2026-11-06)
- #212 [opus] Destruction, physics feel, and camera audit rulings + settlement program (Ryan, via Rey, Nov 6 2026) (created 2026-11-06, updated 2026-11-06)
- #213 [opus] Environment and backdrop audit rulings + settlement program (Ryan, via Rey, Nov 6 2026) (created 2026-11-06, updated 2026-11-06)
- #214 [opus] Tooling note: Kensei 15-step Blender + Tripo/Hunyuan pipeline (Ryan, via Rey, Nov 6 2026) (created 2026-11-06, updated 2026-11-06)
- #215 [opus] UI and campaign map audit rulings + settlement program (Ryan, via Rey, Nov 6 2026) (created 2026-11-07, updated 2026-11-07)
- #216 [opus] Tooling note: repo memory hygiene + council memory (Ryan, via Rey, Nov 7 2026) (created 2026-11-07, updated 2026-11-07)

## 3. Snapshot: open PRs

# Open PRs snapshot: 3

- PR #205 Muse issue 202: playtest checklist for the next build (synthesis plus legs) | head muse/issue-202 -> main | draft=False | updated 2026-11-05
- PR #204 R109: station detail pass #199, Muse #200 to #202; LOOP.md | head muse/issue-201 -> main | draft=False | updated 2026-11-07
- PR #203 R109: station detail pass #199, Muse #200 to #202; LOOP.md | head muse/issue-200 -> main | draft=False | updated 2026-11-06

Note for legs: PR #203 is the issue #200 delivery (surface detail standard, rulings pushed Nov 6), PR #204 is the issue #201 delivery (Nemesis checks, owner rulings pushed Nov 6), PR #205 is the issue #202 delivery (playtest checklist). All three were delivered Nov 5, 2026 and are unmerged. Their titles as returned by the API are shown verbatim above; judge for yourself whether the titles describe the contents.

## 4. Snapshot: branches

# Branches snapshot: 103

- board-automation
- codex/ion1
- codex/issue-5
- codex/issue-11
- codex/issue-16
- codex/issue-17
- codex/issue-18
- codex/issue-19
- codex/issue-20
- codex/issue-21
- codex/issue-22
- codex/issue-23
- codex/issue-25
- codex/issue-33
- codex/issue-37
- codex/issue-40
- codex/issue-49
- codex/issue-50
- codex/issue-55
- codex/issue-58
- codex/issue-59
- codex/issue-60
- codex/issue-61
- codex/issue-66
- codex/issue-67
- codex/issue-75
- codex/issue-77
- codex/issue-78
- codex/issue-79
- codex/issue-80
- codex/issue-99
- codex/issue-108
- codex/issue-110
- codex/issue-111
- codex/issue-129
- codex/issue-133
- codex/issue-134
- codex/issue-137
- codex/issue-138
- codex/issue-146
- codex/issue-163
- codex/issue-166
- codex/issue-167
- codex/issue-168
- codex/issue-183
- codex/issue-187
- codex/issue-195
- codex/pre-opus-reset-review-2026-10-31
- fx/destruction
- fx/destruction3
- main
- muse/issue-2
- muse/issue-3
- muse/issue-15
- muse/issue-28
- muse/issue-31
- muse/issue-51
- muse/issue-53
- muse/issue-70
- muse/issue-71
- muse/issue-72
- muse/issue-76
- muse/issue-81
- muse/issue-82
- muse/issue-86
- muse/issue-87
- muse/issue-88
- muse/issue-101
- muse/issue-102
- muse/issue-103
- muse/issue-112
- muse/issue-125
- muse/issue-132
- muse/issue-135
- muse/issue-147
- muse/issue-171
- muse/issue-172
- muse/issue-173
- muse/issue-188
- muse/issue-189
- muse/issue-200
- muse/issue-201
- muse/issue-202
- muse/issue-test
- onb1
- opus/adm-balance
- opus/adm-confirm
- opus/blocker-outline
- opus/issue-146-run1
- opus/r97
- opus/r98
- opus/r99
- opus/r100
- opus/sfx-map-13
- opus/thale-start
- rules15
- snd1
- v53-C
- v53-E
- v53-G
- v53-I
- v53-I-wip
- wip/issue-129

Branch count by prefix: codex 47, muse 33, opus 10, plus legacy names (v53-*, fx, snd1, rules15, onb1, wip, board-automation) and main. Most agent branches persist after their PRs merge or close.

## 5. The top layer an incoming agent reads

Sizes on main today: AGENTS.md 5,121 bytes; CLAUDE.md 5,542; HANDOFF.md 27,197; NEXT.md 17,058; BACKLOG.md 8,979; PROGRESS.md 77,469; contrib/opus/LOOP.md 10,177; contrib/opus/FINDINGS.md about 106,000 (over 2,000 lines); contrib/opus/briefs/muse_standing_rule.md 3,199.

### 5.1 AGENTS.md (full text)

# Voidsworn: rules for any AI agent (Claude, Argon, or another model)

Voidsworn is a Babylon.js hex fleet-tactics roguelite built into one HTML file (`python3 build.py`). The owner is Ryan. He is not a coder:
he plays on a Pixel 10 XL and a Windows PC, and he judges work by screenshots.

## Auditing? Follow `docs/REVIEW_PROTOCOL.md` exactly (mandatory). Then `docs/ship_pipeline/TEXTURE_PASS.md` (current), then `docs/ship_pipeline/AUDIT_BRIEF.md`

It holds the goal, the full history, every piece of owner feedback word for word, the open issues and the questions we want answered.

## The job board (Ryan, Nov 2, 2026)

- Every job is an open GitHub issue: https://github.com/rcbailey12/voidsworn/issues. The label says who has it: `codex` (Codex on
  Ryan's PC), `muse` (Rey and its models), `opus` (Claude), `ryan` (waiting on Ryan), plus `blocked`.
- Agents deliver by pushing a branch named `codex/issue-<number>` or `muse/issue-<number>`. Never push to main.
  GitHub then opens the pull request by itself (.github/workflows/auto_pr.yml) and runs the checks on it
  (.github/workflows/checks.yml: standing checks, no em dashes in changed files, Godot rules parity). Opus reviews and merges.
- Codex stays local on Ryan's PC. `codex_board.bat` (Downloads\voidsworn_test) checks the board every 10 minutes and
  queues each new codex issue on lane B (tools/pc/codex_issue.bat): fresh checkout, Codex at the issue's effort, push.
  No Codex cloud tasks or cloud reviews: they run an older model than the local one.
- Every issue opens with this fixed block, so any agent can pick it up without asking:
  ```
  Owner: codex | muse | opus
  Brief: <path to the brief, or "below">
  Deliver to: <folder or files>
  Branch: <agent>/issue-<number>
  Effort (Codex): high | xhigh   or   Models (Muse): <set>
  Done when: <the check that proves it, and what Ryan will see>
  ```
- Muse's standing instructions: `contrib/opus/briefs/muse_standing_rule.md`.
- Muse research, design and review jobs always include a blind Rey leg written before Rey reads the other legs (Ryan, Nov 3, R89). Write the Models line as: Rey writes a blind leg first, DeepSeek and Qwen write, Argon reviews only, Rey chairs.
- Questions for Ryan go to him directly in the agent's own chat, not as GitHub tags or comments (Ryan, Nov 2).

## If you are not the main agent: work in your own folder

- Put everything you make in `contrib/<your-agent-name>/` (for example `contrib/argon/`). Do not edit files outside it: no game
  source, no tools, no docs, no `hulls*/` assets.
- Proposing a change to an existing file? Put a copy of the whole changed file in your folder at the same relative path, for example
  `contrib/argon/tools/blender/hs/h10_kit.py`, plus a `NOTES.md` that says what changed and why.
- Reviews go in `contrib/<your-agent-name>/reviews/<topic>.md`.
- The main agent merges what works. See `contrib/README.md`.

## Ship models (the current big job)

- Start with `docs/ship_pipeline/README.md` (the pipeline), then `docs/ship_pipeline/BLOB_SWEEP.md` (what "done" means), then
  `docs/ship_pipeline/SHIP_QUEUE.md` (all 36 hulls and their status).
- Worked example: the Pyre-Barge, `C19_51`. The hand-built parts script is `tools/blender/hs/c19_kit.py`, and the job files are in
  `tools/pc/jobs/c19_*.bat`.
- Owner's placement rules for hand-built parts:
  - snapped onto the real hull, on visible mounts;
  - guns aimed forward or out to the side, never backward (no ship in the game fires backward), never into the ship;
  - matched symmetric pairs;
  - Corsair is the exception and may be junky.
- Space ships, not naval ships: no keels, jackstaffs, bollards, crow's nests, yardarms or mast ladders (owner, Oct 22). Guns never face backward.
- Free tools only. No triangle limits: full detail is compressed (meshoptimizer `.vsm`), not decimated, on desktop.

## Owner preferences that apply to any agent

- Plain words, short, lead with the answer, no em dashes, give your pick rather than a neutral list.
- Show screenshots of anything visual.
- Anything Ryan runs himself is a double-click `.bat` file (Windows 10, PowerShell 5.1, no real Python of his own).
- Before anything bigger than a quick fix, ask 3 to 5 plain-language multiple-choice scope questions in one batch.

## Heavy work

Heavy work runs on Ryan's PC (RTX 5080) through the test runner: AI models, Blender bakes and renders, game screenshots. How the
runner works and its pitfalls are in `HANDOFF.md` ("Gotchas") and `docs/ship_pipeline/README.md`.

`CLAUDE.md` holds the same rules for Claude. Keep the two in step.

Time estimates (Ryan, Nov 4 10:40 CST, FINDINGS R99): never estimate in human hours; every human-hour estimate so far has been wildly off, because the work is done by agents, not people. Estimate in Codex runs (one run is capped at one hour; Nov 4 runs took 11 to 60 minutes, and a heavy GPU bake-off can need two), plus the number of Ryan review rounds, and base it on the board's own history (board\issue-N timestamps and PR times), not on what a human artist would spend. Say what drives the count (GPU bakes, retries, review rounds).

### 5.2 CLAUDE.md (full text)

# Voidsworn: working rules for Claude

**Start here (Oct 24 2026):**
- Read HANDOFF.md first, then the open issues and pull requests (the job board, Nov 2 2026, FINDINGS R75; rules in AGENTS.md).
- The approved build plan is `contrib/opus/go-forward-plan.md`.
- The findings registry is `contrib/opus/FINDINGS.md`: check it before trusting any claim in an older doc.
- Owner rulings of Oct 24 that override older docs:
  - PC-only;
  - shields keep faction colours (the cyan-only rule is retired);
  - battles grow over a run toward about 20 ships (a guide, not a cap);
  - the dead-star gravity-well board stays;
  - capture is add, strip or ransom.
- **Lore approved (owner, Oct 27 2026; FINDINGS R59).** The game is *Embers of the Hollow Sun*. Display names follow `contrib/opus/compute/lore_bible_r8.md` and `contrib/opus/compute/rename_map_final.md`; ids never change: `voidsworn` = Sunward Crusade, `corsair` = Ashfall Hullbreakers, `ithar` = the Glasswrights, `deathless` = Eclipse, `chorus` = the Chorus, `hegemony` = Hegemony Navy. Where these rules say Corsair, read Hullbreakers (still the haphazard, junky exception).

- **Ryan's PC first (owner, Oct 21 2026).** Anything heavy runs on Ryan's PC through the test watcher, not in the cloud sandbox: AI model runs (ComfyUI, Pixal3D, Qwen, TRELLIS, Hunyuan), Blender bakes and renders (`voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe`, GPU), closeshots, smoke tests, load probes. The PC has an RTX 5080 (16 GB), 32 GB RAM and 400+ GB free. The sandbox (about 8 GB RAM, CPU only) is for editing code, small conversions and looking at results; it runs out of memory on full-detail meshes.
- How the PC runner works, and its pitfalls: see HANDOFF.md ("PC test runner").
- ComfyUI portable: `Downloads\ComfyUI_windows_portable` (v0.42.1), driven headless by `tools/pc/comfy_run.py`; job I/O in `Downloads\voidsworn_test\comfy_io\CODE\`.
- Ryan is not a coder: double-click .bat files for anything he runs himself, plain words, screenshots of results.
- **Ship parts look like they belong (owner, Oct 21 2026).** Hand-built bolt-ons on the AI hulls (guns, racks, funnels, masts, drums, turrets) must make sense where they sit: snapped onto the real hull surface (never floating or sunk), on a visible mount (plate, ball, saddle, column), guns aimed forward or out to the side, never backward (owner, Oct 22: no ship in the game fires backward; bow guns may face forward along the prow, never aimed back into the ship), and placed in matched, symmetric pairs at sensible hard points. Corsair is the exception: haphazard and junky is on-brand there. Soft or blobby AI areas near the bridge and superstructure get rebuilt by hand the same way (tools/blender/hs/c19_kit.py is the worked example).
- **Space ships, not naval ships (owner, Oct 22 2026: "careful that these don't stretch into obvious naval-looking ships. again, these are SPACE ships").** Keep the concept's look, but never add sea-ship tells: no boat keels or raked stems, jackstaffs, bollards, anchors, crow's nests, yardarms with rigging, mast ladders, lifeboats, portholes in rows along a waterline. Prefer the space versions: armoured flat bellies with chines, sensor housings and antenna arrays, equipment pods, recessed lights, main engine bells and thruster pods, docking hatches, heat radiators. Owner, Oct 24 2026: this covers the whole hull shape (bow profile, keel line, deck line), not only bolted-on parts; crossbar masts and smokestack funnels count as naval tells and become antenna arrays and heat radiators.
- **Breakable by design (owner, Nov 4 2026, FINDINGS R98).** Every new or rebuilt hull gets real hull thickness, a few internal decks and bulkheads, and two or three authored break lines with matching interior faces and damage textures, so broken pieces never look hollow. Chorus hulls get flesh and bone inside. Older hulls rely on the game-side interior fallback (#167).
- **Blob sweep for every AI ship (owner, Oct 21 2026: "ensure we catch all of those for all other ships").** Before showing a ship, review it region by region against the concept: bow / midship / stern, each from the top, the side and below (9 cells, studio renders at the same angles as the concept views). Every cell gets a verdict: clean, or rebuild by hand. Things the AI reliably mangles and that get rebuilt by default:
  - guns of any size (turrets, casemates, long cannons, bow chasers, stern guns), rocket racks and launchers
  - bridge and superstructure tiers, masts, funnels, antennas, rails
  - tanks, drums, torpedo/fuel cylinders, lamps and light rows
  - the bow (usually wavy: rebuild as a faired loft from the AI hull's own sections)
  - engine nozzles and ventral thrusters, armour plate stacks, side sponson blocks
  - any thin spiky or crossed sticks (AI wire debris)
  Hand-built parts carry the AI hull's level of surface detail (seams, grit, worn edges; owner: "the level of texture and details seem to vary wildly").
  Parts the concept shows poorly (tops, undersides, racks seen end-on) keep their own hand paint (project_paint KEEP boxes) instead of projection, or they come out a grey blob.
- **Pipeline gotchas (Oct 21 2026):** the game's ship size comes from hull + kit together (pixal_to_game reads the kit for bounds; cutting the AI bow without it stretched the ship 1.33x). Kit material lights by stored normals (no two-sided lighting); the old 0.3 paint self-light now defaults to 0 (ships3d.js:790). closeshot's server needs a big backlog or desktop shots silently drop the kit.

### 5.3 LOOP.md (first 200 lines; the file's own header notes and queue live here)

# Board loop state (LOOP.md)

**Nov 5 22:30 CST (Ryan): Codex is out of weekly usage for a while. Opus owns the board and does the codex jobs itself; relabel an issue `opus` before starting it so the PC watcher skips it. See HANDOFF.md section 0.**

**Board owner right now: the lead chat (Ryan, Nov 4 21:33 CST).** The hourly scheduled task "Voidsworn board loop" is switched off until the weekly Claude usage reset: its runs kept stopping for approvals and were refused merges. The lead chat runs the board with one-off send_later checks until Ryan revisits it. When the hourly task is back on, it becomes the only owner again (R102). Any other Claude chat on this repo works one named area or only reads.

## Lock

Running: no
Running since (UTC): 2026-11-05 03:27
Last run finished (UTC): 2026-11-05 03:40

If "Running: yes" and the start time is under 90 minutes old, another loop is working: stop without changes. If it is older, the last run died: take over and say so in the log.

## How a run works

**Usage is low (Ryan, Nov 4 15:43: about 3% of the weekly Claude usage left, keep the loop hourly).** Keep runs short: if nothing changed since the last run (same running job, no new PRs, no new answers from Ryan), do not take the lock, do not rewrite this file, just stop. Only read the files and screenshots a decision needs.

1. Read HANDOFF.md section 0 and this file. Set the lock (Running: yes, time) and push it before doing anything else.
2. Board check (Sonnet subagent is fine): queue_b and queue_b\running on the PC, board\issue-N result.txt and log tails for running or finished jobs, open PRs, open issues and labels.
3. Review each new PR yourself (Opus): read the claims, look at the shots in board\issue-N\shots, check the claims against the diff and the done-when list. Merge if good. Hold the ones listed under Holds.
4. Release the next job in the queue order below (remove its blocked label, one at a time), but only when nothing is running or queued for Codex. Before writing any job file, check queue_b, queue_b\running and board\queued.txt for that number, to avoid duplicate runs.
5. Anything that needs Ryan goes under "Waiting on Ryan", with a recommended option and plain-word trade-offs, and gets one PushNotification. Never ask with AskUserQuestion from a scheduled run (nobody is there). If Ryan answered in chat or in this file, record it in FINDINGS and act on it.
6. Tell Ryan only when something lands or needs him: two lines and one image, by PushNotification.
7. Rewrite this file (state, queue, holds, waiting, log), set "Running: no", commit straight to main (this file only, docs-only exception) and push with timeout 90. Stop.
8. If a job will finish or a usage limit will reset well before the next hourly run, schedule one send_later check for just after it. Never chain send_later loops.

## Current state (2026-11-05 03:50 UTC)

- Codex: #187 (Pyre-Barge round 6) running since 03:29Z. It started before the paint standard merged, so it may not follow #188 exactly.
- Merged tonight: #186 (round 5 tools), #190 (#183 station detail shapes), #191 (#188 readable-paint standard), #192 (#189 backlog check), plus FINDINGS R103 to R106.
- Latest playtest exe: g2_pt_d03ac22 (no deaths 2, no station detail yet).
- PC disk: about 100 GB free.

## Queue order (Codex)

From the backlog check (R106, synthesis section 5), with the station repaint added (R104):

1. #198 Pyre-Barge round 7 (R108; released 14:32Z, no PR yet, Codex out of usage). HOLD its PR for Ryan.
2. #199 station surface detail (R109). HOLD its PR for Ryan.
3. #139 nebulas and ion storms (deaths #137 and weapons #138 are already merged, so R88's order is met).
4. #140 rocky and terran planets.
5. #120 Nemesis redesign 1.
6. #121 Nemesis redesign 2 (NEM_VOICE from contrib/muse/design/nemesis_writing_2026_11/text_table.md, R101).
7. #122 Nemesis redesign 3.
8. #24 progression step 7 (edited, after #121).
9. #26 progression step 10.
10. #27 progression step 11 (edited: XP by line only).
11. #29 progression step 13.
12. #30 progression step 14.
13. #92 debrief screen (edited, after #24 and #122).
14. #100 terrain fx 2 (edited; #60 merged as PR #143 on Nov 5, R107, so build on its wreckage kit).
15. #169 breakable Pyre-Barge (edited; after Ryan's round 7 pick, R108, and #167, which is merged).
16. Later: #41, then #42, then #44.

## Holds

- PR from #198 (round 7): hold for Ryan's pick; send the comparison sheet, the blurred greyscale check and both ceiling numbers. (#187 round 6 merged as tools only, R108.)
- PR from #199 (station detail): hold for Ryan's look. (#197 repaint merged as the base, R109.)
- Issues #193 (Tripo per-part test) and #194 (five ship-pipeline options): Muse proposals labelled opus, parked until the weekly reset. Note: Tripo is a paid cloud service; the house rule is free and local tools only, so #193 needs Ryan's call before any work.

## Waiting on Ryan

- Station detail look when #199 lands.
- Round 7 pick when #198 lands.

## Muse

- Open (R109, Claude usage capped): #200 surface detail standard, #201 Nemesis test checks, #202 playtest checklist. Review and merge when they land; #201 results feed edits to #120 to #122.

- PRs waiting for review: #203 (#200), #204 (#201), #205 (#202). #188 and #189 delivered and ruled earlier (R105, R106).

## Known traps

- Never list queue\logs, queue_b\logs, queue\done or big shots folders recursively; they are huge. Stage the one file you need.
- PC access is only device_list_dir, device_stage_files and device_commit_files. Never delete anything on the PC; ask Ryan.
- Duplicate runs: the board (codex_board.ps1, every 10 minutes) queues any unblocked open codex issue that is not in board\queued.txt and has no open PR from codex/issue-N. If you also write a job file, it runs twice. Prefer letting the board queue it; write cx_issue<N>_job.bat yourself only if a poll has passed with nothing queued. Keep finished issues in queued.txt.
- A duplicate run of an already merged job force-pushes the branch and auto_pr opens a new PR: close it with a note, do not merge.
- Usage limit: result.txt says "usage limit hit, left on the board to retry"; grep log.txt for "try again at" (Central time). The runner drops the number from queued.txt, so the board retries every poll until the reset. Do not requeue by hand; schedule one send_later check just after the reset.
- Codex has a one-hour cap per run (tmo 3600). Heavy GPU bake-offs can need two runs: back up the branch (git push origin origin/codex/issue-N:refs/heads/opus/issue-N-run1), add a resume note to the issue body, close the PR, drop N from queued.txt.
- GitHub's PR list can lag a few minutes after a close, and the board then re-adds the number to queued.txt. Check on the next run.
- Never put |, &, < or > in job arguments. Job .bat files are CRLF.
- git push from the sandbox can hang: wrap in timeout 90 and retry once.
- gh GraphQL is blocked: use gh api REST (pulls, issues, merges). Branch deletion and repo settings are refused by the proxy.
- Questions for Ryan go in chat or this file, never as GitHub tags. Plain words, no em dashes, no human-hour estimates (R99).

## Playtest exe recipe (lane A)

Check ship files are unchanged first (git diff --stat <last build hash> origin/main -- godot/assets/ships). Zips from origin/main with git archive: src1 = godot portraits; src2 = godot audio world; src3 = godot campaign fx main render rules scenes story ui; tools = tools/pc (prefix kept). Copy manifest and mcheck from the last build (build\g2_pt_<hash>_*). Copy the last bat (queue\done\g2_pt_<hash>.bat), replace the hash, rewrite line 2, CRLF. Zips to Downloads\voidsworn_test\build\, bat to Downloads\voidsworn_test\queue\. Results in shots\g2_pt_<hash>\result.txt (expect MANIFEST OK, export exit 0, title and battle exits 0). About 20 minutes.

## Who does what

- Opus: merge calls, PR claim checks against the diff, visual judgment, planning, issue writing, messages to Ryan.
- Sonnet subagents: board checks, log reading, renames, staging files, capture jobs.
- Codex: coding jobs from the board (local on Ryan's PC). Muse: research, design text, low-code PRs.

## Log (newest first, keep about 10)

- 2026-11-05 22:30 lead chat: handoff written. Codex out of usage; Opus takes the board after the Claude weekly reset. Muse PRs #203 to #205 open.
- 2026-11-05 14:40 lead chat: Ryan R109, station needs way more detail. Merged #197 as base, filed #199 (codex) and #200 to #202 (muse).
- 2026-11-05 14:32 lead chat: #195 PR #197 reviewed, held for Ryan. Released #198 round 7.
- 2026-11-05 04:50 lead chat: #187 round 6 done (PR #196, merged as tools); Ryan ruled R108, round 7 filed as #198. Released #195 station repaint.

- 2026-11-05 03:50 lead chat: took the board back (hourly task switched off by Ryan until the weekly reset). Merged #190, #191, #192. Recorded R104 to R106, applied the backlog edits to #24, #27, #92, #100, #169, filed #195 (station repaint), rewrote the queue.

- 2026-11-05 03:40 loop: took over a stale 01:38 lock. PC folders not connected to the run, worked from GitHub only. Reviewed Muse PRs #191 and #192 (good); merge refused by the scheduled run's approval check, left for Ryan. Released #187. PR #190 stations held for Ryan. #193 and #194 not triaged.
- 2026-11-05 02:00 lead chat: the hourly task had no PC folders attached, so every run asked Ryan for access. Replaced it with an identical task (runs at :58, first 02:58 UTC) with Downloads\voidsworn_test and the Godot app_userdata\Voidsworn folder attached. Runs must not request other folders.

- 2026-11-05 00:25 lead chat: hourly runs at 22:37 and 23:37 sat pending until Ryan approved the task in the desktop app; he says it now runs. Merged #186 (round 5 tools), filed #187 (R103), released #183.

- 2026-11-05 00:22 loop: #163 done, PR #186 reviewed and held, round 5 pick sent to Ryan; #183 found already unblocked, waiting for the board to queue it.
- 2026-11-04 21:40 lead chat: loop moved to this file and the hourly scheduled task "Voidsworn board loop" (runs at :37 each hour, first run 22:37 UTC, auto approval, needs Ryan's PC) (R102). #163 running. No send_later checks pending.

### 5.4 muse_standing_rule.md (full text)

# Muse standing rule (paste once into Rey's project or chat instructions)

From Opus, for Rey (Muse). Set up Nov 2, 2026 with Ryan; revised Nov 2 08:45 (fewer GitHub writes, return loop, stall check) and 09:10 (push only: the PR opens itself).

```
You work from the Voidsworn job board: the open GitHub issues labeled "muse" in github.com/rcbailey12/voidsworn.

Picking up work (your watcher, or when Ryan says "check the board"):
1. Take the oldest open muse issue that isn't labeled blocked and that you haven't started. Keep your own record of what you started and when; don't post a claim comment.
2. Read the fixed block at the top of the issue (Owner, Brief, Deliver to, Branch, Models, Done when) and do the work. Ryan's rulings in contrib/opus/FINDINGS.md override every other doc. Cite file:line for code claims. Argon is for briefs and sources only; cut anything it can't back up.
3. Deliver by pushing the branch the block names (muse/issue-<number>). That is the only GitHub write you need: GitHub opens the pull request into main and runs the checks by itself. Put a short summary for the reviewer in the commit message. Do not push to main and do not open the PR yourself.
4. Tell Ryan here in one line what to look at first.

Return loop (your watcher, on your open PRs):
5. If Opus requests changes, do the revision on the same branch and push. Tell Ryan here only if it needs him.
6. When a PR is merged, tell Ryan here the job closed.

Stall check:
7. If a job you started has no PR after 3 hours, tell Ryan here what is blocking it.

Scope (Ryan, Nov 2 23:41, FINDINGS R81): besides research and design, you may deliver low-code fixes (text, data tables, tests, tools, docs) when an issue asks for them. DeepSeek, Qwen and Rey write; Argon reviews and proposes ideas only, never final text or code. A change to rules or data in battle.js, core.js, data.js or campaign files must be made the same way in the Godot port (godot/rules, godot/campaign), with the oracle copies re-copied and tables re-exported, and must pass the PR checks.

Blind leg (Ryan, Nov 3 18:43, FINDINGS R89): on every research, design or review job, Rey writes its own blind leg first, from the issue and the pack only, before reading any other leg, and files it as legs/rey_blind.md. Then DeepSeek and Qwen write, Argon reviews, and Rey chairs. The synthesis names where the blind leg agreed or disagreed with the others. A job with no blind Rey leg is not done. Low-code fix jobs (text, data, tests) need no blind leg.

Questions for Ryan go to him here in this chat (multiple choice with your pick), never as GitHub tags or comments. Plain words, no em dashes.
```

Time estimates (Ryan, Nov 4 10:40 CST, FINDINGS R99): never estimate in human hours; every human-hour estimate so far has been wildly off, because the work is done by agents, not people. Estimate in Codex runs (one run is capped at one hour; Nov 4 runs took 11 to 60 minutes, and a heavy GPU bake-off can need two), plus the number of Ryan review rounds, and base it on the board's own history (board\issue-N timestamps and PR times), not on what a human artist would spend. Say what drives the count (GPU bakes, retries, review rounds).

### 5.5 FINDINGS.md structure

Total lines: 283. Ruling headings found: 0. Last ruling headings in file order: none matched the heading pattern.

File tail (last 60 lines):

| B-12 | Watchdog leaves B.activeUnit set | Latent | ui3d.js:667; no softlock in practice | INFO |
| B-13 | Legacy shop has no buttons | Dead UI | main3d.js:11 unlocks every legacy upgrade and admiral free on boot (matches Ryan's no-grind wish) | INFO |
| B-14 | Sim harness crash | VERIFIED | sim3d.js:112 `OBJS_SEEN[B.obj.type].w++` on an unseen type | FIXED (d88035a, guard as in the plan section 10) |
| B-15 | Council chair's top 10 | None done in code | evidence/bugs_at_d5d0227.md | OPEN (B1 covers 1 and 2; others in later phases) |
| B-16 | Every AI hull vanished on its first damage below 80% hull (until the cloned damage shader compiled), and once it came back a damaged painted hull drew as generic plating | VERIFIED Oct 25 (closeshot probes on Ryan's PC: barge and hulk-carrier invisible at 0.7 s and 1.8 s, back at 12 s with a plain panel grid) | gfx3d.js `shipDamageFx`: the clone dropped the paint, kit, finish and detail flags (new shader) and was swapped in before it compiled. Fix d234ed3 and the v3 commit: all flags copied, clone compiled on a scratch submesh, then swapped. Re-probe: clones ready at 0.7 s, barge visible with its own paint. | FIXED |
| B-17 | Occasional hitches in the play build (Ryan, Oct 25, Edge on the RTX 5080) | Reported in play; the engine test saw 25 to 60 ms frames in Babylon too (shader compiles, GC, board labels) | OPEN: measure in a scripted real-browser battle on the PC (long frames with what was happening), fix the cheap causes (shader pre-warm, per-frame allocation); deeper work waits for the engine call |
| B-18 | battle.js killUnit, the animExplode line: a // comment swallows the code after it, so the stalled-battle check after a death explosion never runs. Behaviour unchanged today. Found by the rules port (Oct 25). One-line fix, held for the engine decision. OPEN |
| B-19 | sim3d.js does not wait for turn-start deaths (fire, acid, the dead star) before the next activation the way the game does. Balance effect probably tiny. Found by the rules port (Oct 25). Align when next touching the sim. OPEN |

## The record: documents and data

| ID | Claim (source) | Verdict | Evidence | Status |
|---|---|---|---|---|
| D1 | Barge v14 files in the repo (READING_PLAN.md:9; pipeline README:58, :64) | WRONG at d5d0227 | No .vsm or _kit.json was in git. Oct 24: all 9 v14 files committed to hulls_hi/ (95f01b6) and the medium-quality set to hulls/ (a687ef5; ships3d.js:800 loads hulls/ on medium). The PC's 21 build inputs and the barge files match git byte for byte; side-by-side in docs/ship_pipeline/c19_example/a0_repo_vs_pc.webp, PC console errors: none. | FIXED (A0) |
| D2 | Barge "done end to end" (pipeline README:6) or "awaiting verdict" (SHIP_QUEUE.md:17) | STALE | v14 verdict "it's pretty close" (NEXT.md:56): clean blocky parts, add real material texture | INFO (A1) |
| D3 | Kit script builds space-only parts | WRONG | c19_kit.py:173 mast with yards, :160 funnels, :38 keel line, :403 keel plate. AUDIT_SYNTHESIS.md:208-218 prescribes bollards, yards, crow rail, ladder. :163 allows stern guns. | FIXED for the barge via v15 (tools/blender/a1/barge_v15.py has no mast, funnel, keel or yard geometry; hits are comments). c19_kit.py keeps the naval parts as history and is not the live kit path; the general rule for later hulls belongs to A4 (K1) |
| D4 | Cyan-only shield hard-fail tests | STALE (R3) | beauty_corner_spec.md:77, :95; visual_qa_pack.md:7, :76, :145, :214 | DECIDED: ignore |
| D5 | Beauty corner triangle range 2,400 to 38,000 | STALE | Conflicts with "no artificial triangle limits" and the barge's 1.5 to 2 million triangle build | DECIDED: retired |
| D6 | Six terrain kinds (beauty_corner_spec.md:24; art_direction_rey.md:62) | WRONG | Five kinds (battle.js:193) plus the dead-star board shape | INFO |
| D7 | Phone framing | STALE | graphics_craft.md (20 "Phone cost" lines), visual_expansion_research.md (about 71 mentions); tool_guides.md framing already re-tiered (834bcb6) | INFO |
| D8 | glTF, .glb and gltfpack recipes (tool_guides.md:89, :183, :557; visual_expansion 4.1) | WRONG for this game | The game loads its own JSON plus WebP hulls (ships3d.js:801); no glTF loader | INFO (Godot test exports only) |
| D9 | KTX2 setting `JSModuleURL` (tool_guides.md:274, :502) | WRONG | Babylon 8.20 uses `KhronosTextureContainer2.URLConfig` | INFO |
| D10 | "FXAA off with MSAA" (visual_expansion:175) | Contradicts code | The game runs both (scene3d.js:26) | INFO |
| D11 | Quaternius is CC0 (GRAPHICS_REFERENCES.md:127; field guide :31, :253; Rey batch 8) | STALE | quaternius.com/license.html: QAL v1.0 (Aug 28 2026) | DECIDED: not used |
| D12 | Official Blender Lab MCP as the standard | Blocked | Needs Blender 5.1+; the PC runs 4.5.14 | DECIDED: community blender-mcp trial |
| D13 | Code index "1,016 definitions" | WRONG | 1,021 (5 missed on shared lines); zero duplicates VERIFIED | INFO |
| D14 | Content census, asset inventory (553 files, 157.5 MB), 36 hulls in both tiers | VERIFIED | evidence/compute_and_review_citations.md | INFO |
| D15 | Check pack and compute CSVs are runnable | WRONG as committed | Stored as base64. Decoded and adopted at contrib/opus/tools/checkpack (d88035a); checks.js now finds the repo root from that folder. 0 FAIL, 15 CHECK. Muse's compute CSVs stay base64 (reference only). | FIXED (check pack) |
| D16 | Independent audit counts and the finishBattle claim | WRONG on 3 | Hulls are 33 plus 12 variants; boons 36; finishBattle sets B.finished itself (campaign3d.js:66). The retreat hole is still real. | INFO |
| D17 | Rey's ship pipeline audit claims | STALE on 7 | Fixed since: kit self-light 0 (ships3d.js:790), kit material cloned (:788), error callback (:789), joint paint solve, procedural hull disposed (:827) | INFO |
| D18 | CLAUDE.md "0.3 paint self-light" | STALE | Default is now 0 (ships3d.js:790) | FIXED in CLAUDE.md, Oct 24 |
| D19 | HANDOFF.md "repo private" | WRONG | The repo is public by Ryan's choice (R10) | FIXED in HANDOFF.md, Oct 24 |
| D20 | Image manifest "local only, not in repo" | Half right | The manifest is in the repo (contrib/muse/design/IMAGE_MANIFEST.md); the 40 images are local only. Chorus rows are superseded. | INFO Repo manifest Voice row is stale (lists the pre-v4 file, 403,732 bytes; approved v4 is 519,924 bytes, SHA 6790c41e...); push the manifest update with the next design push; Matriarch row waits for its verdict. |
| D21 | OPUS_HANDOFF.md section 1: "Dead Star: background only. Not a sixth terrain kind, not a gravity well mechanic" | SUPERSEDED | Ryan's Oct 24 ruling R2 (also in CLAUDE.md, Oct 24: "the dead-star gravity-well board stays") keeps the gravity well, which exists in code (battle.js:272-277, 305, 343, 374). The painting becomes its backdrop. The handoff line predates the ruling | RESOLVED: R2 stands, confirmed by Ryan Oct 25 when Muse re-raised it ("Gravity well stays"): the Dead Star stays a playable gravity-well board; the painting is its backdrop |
| D22 | Sonniss clips in a public repo (field guide line 350: files may not be handed to others; sfx_data.js carries them as base64) | DECIDED | R10 records Ryan's decision to keep the sound as is, not a licence check | CLOSED by Ryan, Oct 25: "Disregard the Sonniss thing, we're fine." Sound stays as is (R10) |
| K1 | Kit-spec decisions left open by the kit spec synthesis | OPEN, scheduled | For A4 entry, decide and record: size class taxonomy, handedness, FAC3D glow mapping, Voidsworn symmetry, Basilica bound mesh; schema-only, no TypeScript codegen (decided); the measurement pass with gain calibration (Huber fit over the FAC3D chart, clamp 0.75 to 1.25, 3% residual gate) adopted as an A4 entry step; hardpoints get mount name, size class, allowed weapons, forward arc and muzzle marker; the cyan baked-result gate is a separate question from the retired cyan-only shield tests (D4): Opus read is to drop it or narrow it to emissive only, since shields keep faction colours (R3) | OPEN (A4 entry) |
| K2 | Look and effects items from batch 5 and 7 not yet scheduled by name | OPEN, scheduled | For A5: prefiltered environment map (a bare starfield is a poor PBR environment), VFX importance band, screen-size effect LOD with a check that it is on, emissive on its own slot, glow before tone mapping, the tone mapper three-way test (Babylon: ACES vs PBR Neutral; Godot: adds AgX), lighting first then materials then post, single key with 25 to 40% cool fill and Fresnel rim, bloom threshold 0.5 to about 1.0 (scene3d.js), torpedo telegraph (two-stage warning, about 800 ms ramp to white) and the interception call, the luminance background scan | OPEN (A5, B4) Oct 25 inputs for A5 entry: contrib/muse/reviews/a5_effects_sheets_synthesis.md plus the Gemini Godot and Babylon 9.30 effects shelves (leads only); scheduling by name still belongs to A5 entry. |

## Research and outside models

| ID | Claim | Verdict | Evidence | Status |
|---|---|---|---|---|
| X1 | Batch 7 "no substantive conflicts" | WRONG | The legs disagree on hitstop, shake, wind-up and rim light; the handoff kept DeepSeek's values every time | INFO (all tuned on screen) |
| X2 | Godot 6-week claim | UNCHECKABLE | Qualifications exist only in OPUS_HANDOFF.md:111; DeepSeek's batch 1 file presents it unqualified; the post is blocked | INFO (do not cite) |
| X3 | Batch 6 "separate metal and roughness maps are silently dropped" | WRONG for Blender 4.5 | The exporter combines them unless "Keep Original" is on. Bump maps are indeed never exported. | INFO |
| X4 | KHR_materials_variants "keeps both engines open" | Half true | Babylon's loader supports it; Godot's importer does not | INFO |
| X5 | DeepSeek "PBRMaterial.ormTexture" | WRONG | No such property; the game uses metallicTexture flags (ships3d.js:65-67) | INFO |
| X6 | DeepSeek 1,500 draw calls "from Babylon docs" | UNSUPPORTED | Not in Babylon's optimisation page | INFO |
| X7 | Electron "120 to 160 MB runtime per OS" | WRONG framing | It is a one-time build-machine download (gameshipper README) | INFO |
| X8 | Batch 4 "1942" correction | Misattributed | The legs cite different things (WWII doctrine against the arcade game). The "better precedent" line is the chair's own. | INFO |
| X9 | Batch 2 "DeepSeek corrected its Godot framing" | Misattributed | Rey inserted "CHAIR CORRECTION" notes into a file labelled verbatim | INFO |
| X10 | Batch 8 sources | Weak | No links in either leg; every price and licence claim is unchecked as filed Narrowed Oct 25: licence claims for the four plan sources resolved (X14); batch 8 prices still unchecked as filed. | INFO |
| X11 | Qwen second legs (price ladder, plate mapping) | LANDED Oct 25 | Both filed verbatim, screened and synthesized into two-legged versions (plate 39ed80b, price 758ae94). Caveats carried: the plate leg has a model-badge caveat; the price leg is two parallel responses with no preference picked, and Response 2's Deathless battleship maths is wrong; all three price drafts predate the Hegemony synchronized-fire ruling, so their Hegemony passages are stale | DONE: Ryan agreed Oct 25 that both two-legged syntheses are the current inputs for B3, with those caveats |
| X12 | Steam overlay works for an Electron or browser build (engine choice legs disagree: DeepSeek yes via steamworks.js, Qwen no) | Qwen right at the primary source | Valve: "web browsers do not support this model"; the workaround is an embedded Chromium inside a native app with offscreen rendering, "not easy" (https://partner.steamgames.com/doc/features/overlay, checked Oct 25). steamworks.js's Electron overlay flag is a third-party workaround, not Valve-supported | INFO for A3: a Babylon ship build needs a native shell (CEF or similar) for a dependable overlay; Godot exports natively |
| X13 | Oct 25 brief syntheses (contrib/muse/reviews/engine_choice_synthesis.md, b2_ramp_capture_synthesis.md) | PICKED UP | Engine choice: led to R22 (Babylon 9.30 in the test) and X12; its porting and shipping points go into RESULTS.md and the A3 page. B2: passed to the B2 build (diminishing ransom, tempo reporting) and to Ryan's calls R23 | DONE |
| X14 | CC0 licences behind the asset plan (batch 8 C2, C3, B5; X10 said unchecked) | 3 of 4 checked at a primary or official listing | Kenney Space Station Kit: "License: CC0 1.0 Universal" (https://kenney-assets.itch.io/space-station-kit). KayKit Space Base Bits: CC0 on the Godot Asset Library listing (https://www.godotengine.org/asset-library/asset/2124; its itch page only says free). Poly Haven: all assets CC0 (https://polyhaven.com/ja/license). ambientCG: CC0 by secondary sources only (https://licenseorg.com/guide/3d-assets/ambientcg); its own page was not reachable from the cloud. Quaternius stays excluded (QAL v1.0). All checked Oct 25 | DONE: 4 of 4 checked. ambientCG's own licence page: "All ambientCG assets are provided under the Creative Commons CC0 1.0 Universal License" (https://docs.ambientcg.com/license, checked by Muse Oct 25, findings_followup_pass.md) |
| X15 | Muse three-leg audit of Opus's work (contrib/muse/reviews/opus_audit_2026_10_25.md) | Accepted | Two completion claims were wrong: the three project skills were never written (now written Oct 25 in .claude/skills: ship-kit, screenshot-verdict, playtest-and-balance), and the AJV schema check was a plan of intent stated like a mechanism (plan wording fixed: planned for A4). Registry rows X11 to X14, R16 wording, D21, K1 and the plan updated in the same pass | DONE (the follow-up pass over unassessed rows stays open) |
| X16 | Babylon 8.20 to 9.30 breaking changes (Job C port plan, Muse's doc verification note) | Checked against the game | No 9.0.0 breaking entries on Babylon's pages; the 9.15 decorator migration only hits code that applies Babylon decorators, and 8.54.2 changed NPE texture blocks. Grep of the game (all *.js and head.html, Oct 25): no decorator use, no NodeMaterial or texture blocks. So neither break touches today's game | DONE |
| X17 | Muse follow-up pass over unassessed rows (contrib/muse/reviews/findings_followup_pass.md) | Accepted | All ten suggested edits applied Oct 25 (X14, X10, D3, D22, S6, R5, D20, F6, K2, F14) | DONE (rows it did not sample stay unverified) |

### 5.6 HANDOFF.md and NEXT.md heading maps

HANDOFF.md headings:
# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 5, 2026, 22:30 CST)
## 0. Status at Nov 5, 2026, 22:30 CST (read this first)
## Older status (Nov 1, 2026, 19:15 CDT)
## 1. What and where
## 2. Current state
## 3. Decisions
## Ryan traveling (Oct 26 to about Oct 30)
## 4. Open questions for Ryan
## 5. Next tasks
## 6. Gotchas

NEXT.md headings:
# NEXT: the build queue
## v53: solid and readable (publish each workstream as it lands: v53.1, v53.2, ...)
## v53.5+: cleanup and fidelity (owner decisions Oct 20)
## Ship shapes (owner, Oct 21: "everything still feels pretty low poly", desktop and phone)
## Owner notes from desktop play on v53.8 (Oct 21, "for future")
## v54: factions and rewards (parallel with v55)
## v55: spectacle
## Still cut (design reasons)
## Parking lot

## 6. What happened while Opus was capped (Nov 5 to 7, chair's record)

- Nov 5: Rey delivered muse jobs #200, #201, #202 as PRs #203, #204, #205 (still open). Issues #193 (Tripo challenger, paid-service question open for the owner) and #194 (ideation outcome) sit labeled opus, parked. LOOP.md's last full state rewrite is dated Nov 5, 03:50 UTC; its header carries the owner's Nov 5, 22:30 CST note: Codex is out of weekly usage for a while, Opus owns the board and does the codex jobs itself, relabeling an issue opus before starting it.
- Nov 6: a full audit stack ran and was ruled by the owner the same day: ceiling pressure test (#207, benchmark scene job for Opus), graphics red team (#208, includes a colour-vision run and now also carries the environment audit's station assert fixes), build-route comparison (#209), FX audit (#210, includes the S15 sound listen pass and a consolidated movement spec), HunyuanVideo-Foley probe (#211), destruction/physics/camera audit (#212), environment audit (#213), two tooling notes (#206 Kamome, #214 Kensei), UI audit (#215). Owner rulings on #201 were pushed to PR #204 the same evening; #201 has no open questions left. #200's synthesis was corrected twice on PR #203 (a chair unit error on triangle budgets, withdrawn).
- Nov 7: issue #216 (repo memory hygiene plus council memory, with addendum) filed to opus. A spam comment on #216 was deleted. The repo's AGENTS.md still describes a Babylon.js one-file game and the owner playing on a phone (both stale since October).
- Owner-only items outstanding: the S15 sound listen pass (one sitting, owner), the #193 paid-service call, a TRTL putter length pick (not repo work), and sheet judgements when #198/#199 land (Codex down, so not imminent).

## 7. Questions for every leg

Answer all of these from the pack alone. Cite issue numbers, PR numbers, and file names for every claim. Where the pack does not establish something, say so under a "Not established" line rather than guessing.

Q1 VERDICT. Is this repo READY, READY WITH CONDITIONS, or NOT READY for Opus to resume cleanly? Name the three facts that most determine your verdict.
Q2 CONFLICT MAP. List every concrete conflict, overlap, or contradiction you can find: issues whose scopes collide, PRs that will conflict on merge, docs that disagree, queue orders that contradict issue states, instructions an incoming agent cannot obey simultaneously. Rank by how much damage each does if Opus walks into it cold.
Q3 OVERWHELM. Ten opus-labeled issues (#206 to #216) plus older opus items (#48, #96, #98, #193, #194) land on one returning agent. Which of these are actually jobs, which are notes, which are parked, and which should be closed, merged, or deferred? What is the smallest set Opus must touch in its first session?
Q4 EXECUTION ORDER. Propose the order Opus works the opus queue, with one line of reasoning per step, respecting the dependencies you found in Q2 (for example: which settlements gate which builds; the #207 benchmark gates several things; PRs #203 to #205 await review/merge decisions).
Q5 THE BRIEFING. Draft the actual briefing prompt the owner hands Opus on return, at most 400 words, plain English. It must cover: what was done while Opus was capped (section 6), ChatGPT being down for 3 days with Opus covering the checker seat, Codex down, the state of PRs #203 to #205, and your Q4 order as the proposed starting sequence (marked as a proposal Opus may re-sequence). Write it as text Opus can act on, not a summary of this pack.
Q6 OWNER QUESTIONS. At most three questions that only the owner can answer, each with the cost of leaving it unanswered. If a question is already answered in the pack, do not ask it.

## 8. Rules for legs

- This pack is the whole evidence base. Do not browse, do not invent repo contents beyond it, and mark anything you infer as INFERRED.
- Verbatim quotes from the pack must be exact; the chair checks them.
- Costs and effort are stated in agent terms (one-time runs, per-item runs, owner review minutes), never human-team time.
- No em dashes in your report.
