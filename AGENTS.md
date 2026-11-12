# Voidsworn: rules for any AI agent (Claude or another model; Argon is blocked since Nov 5)

Embers of the Hollow Sun (repo name voidsworn) is a hex fleet-tactics roguelite. The product is the Godot 4 port in `godot/`, played on
Ryan's Windows PC only; the browser JS game is the rules oracle, frozen except for rules fixes. The owner is Ryan. He is not a coder:
he judges work by screenshots. Start with HANDOFF.md section 0 and contrib/opus/FINDINGS.md (fixed Nov 7, R110; the rest of this file
is reviewed in #216). The plan and the per-area recipes are in `docs/playbooks/` (PROGRAM.md first).

## Auditing? Follow `docs/REVIEW_PROTOCOL.md` exactly (mandatory), then `docs/ship_pipeline/AUDIT_BRIEF.md`

It holds the goal, the full history, every piece of owner feedback word for word, the open issues and the questions we want answered.

## The job board (Ryan, Nov 2, 2026)

- Every job is an open GitHub issue: https://github.com/rcbailey12/voidsworn/issues. The label says who has it: `codex` (Codex on
  Ryan's PC), `muse` (Rey and its models), `opus` (Claude), `ryan` (waiting on Ryan), plus `blocked`.
- Agents deliver by pushing a branch named `codex/issue-<number>`, `muse/issue-<number>`, `work/issue-<number>` (or `work/issue-<number>-<arm>`) or `opus/issue-<number>`. Never push to main (R75). The only exception is LOOP.md and FINDINGS, which are committed straight to main as a docs-only exception (R102).
  GitHub then opens the pull request by itself (.github/workflows/auto_pr.yml, for the agent branch shapes; other branches need a manual PR), and the same push runs the checks once
  (.github/workflows/checks.yml: standing checks, no em dashes in changed files, Godot rules parity, Godot game checks). The Board thread reviews and merges.
  A branch whose name does not start with codex/, muse/, work/ or opus/ gets no automatic checks: open its pull request by hand, then start them by hand (Actions tab, "checks", "Run workflow", pick the branch; or `gh workflow run checks.yml --ref <branch>`).
- Codex stays local on Ryan's PC. `codex_board.bat` (Downloads\voidsworn_test) checks the board every 10 minutes and
  queues each new codex issue on lane B (tools/pc/codex_issue.bat): fresh checkout, Codex at the issue's effort, push.
  No Codex cloud tasks or cloud reviews: they run an older model than the local one. Codex was un-parked on Nov 10 2026 (R170): the Board launches each Codex job itself through the PC queue (contrib/opus/LOOP.md says how), and new codex issues also carry `blocked` so the old watcher cannot run them a second time.
- Every issue opens with this fixed block, so any agent can pick it up without asking:
  ```
  Owner: codex | muse | opus
  Brief: <path to the brief, or "below">
  Deliver to: <folder or files>
  Branch: <agent>/issue-<number>
  Effort (Codex): high | xhigh   or   Models (Muse): <set>
  Done when: <the check that proves it, and what Ryan will see>
  ```
- Ship build issues add four lines to the block (Ryan, Nov 11 2026, R214; template in docs/playbooks/ships.md section 7):
  Route per part, Inside, Paint stack, Budget. Every build pull request body carries its done-when evidence and a method line
  (build sheet link, manifest, budget numbers, changes made to the sheet); the outside check (issue 256) returns a build PR
  without them as BLOCKING.
- A ruling that changes a working method is not landed until the same pull request edits the working document a worker
  reads for that area (the playbook, RECIPE.md, this file) (R214).
- Muse's standing instructions: `contrib/opus/briefs/muse_standing_rule.md`.
- Muse research, design and review jobs always include a blind Rey leg written before Rey reads the other legs (Ryan, Nov 3, R89). Write the Models line as: Rey writes a blind leg first, DeepSeek and Qwen write, Flash and Grok ideation only, Rey chairs; Argon blocked since Nov 5.
- Questions for Ryan go to him directly in the agent's own chat, not as GitHub tags or comments (Ryan, Nov 2).

## Who does what (seat map, Ryan and Opus, Nov 8 2026, FINDINGS R128; Board seat moved to Fable 5.2 on Nov 9, R152)

Match the job to the seat that is best at it, and keep the paid seats for what only they do well. The board (Fable 5.2 since R152; older notes that say Opus for the board mean this seat) assigns by this table; LOOP.md says which seats are live today.

| Work | Seat | Why |
|---|---|---|
| Board, PR review and merges, specs, visual calls, questions for Ryan | Claude, the project's Board thread (Fable 5.2 for the Nov 9 and 10 design window, R152; Opus for the build-out, R169) | the reviewer is the bottleneck; spend Claude on judgment, not bulk typing (2 or 3 threads at once) |
| Well-specified coding: rules, campaign, UI, scripts, tests | Workhorse: DeepSeek V4.1 Flash in OpenCode on the PC (tools/pc/work_issue.bat) | merged on one review pass for $0.09 on #26 (R127) |
| Hard or open-ended multi-file coding, ship rounds, screen builds, plans | Opus 5.5 worker threads (the hardest jobs while the Claude plan has room, R132, R152) | Kimi is off except a real job both DeepSeek models fail (R132, R134); it was slower and 50x the price per job on the API |
| Every ship model made in Blender: blockouts, hulls, kits, the station (R205) | Opus worker threads | Ryan, Nov 11: "I think builds in blender should come from Opus" |
| GPU work that shapes no ship: bakes, renders, captures, benchmarks, exports | Codex on the PC | Codex knows the pipeline tools; the workhorse is untested on GPU jobs |
| Research, design text, audits, second-opinion reviews | Muse (Rey chairs; blind Rey leg; DeepSeek and Qwen write) | several models, an outside view |
| Ideation and wide brainstorms | Flash and Grok (free), through Muse | cheap and broad |
| Independent checker on an Opus-built change | Rey (or ChatGPT when back) | nobody grades their own work |
| Concept art and visual references | Rey's image models; production art through local ComfyUI and Blender on the PC | free and local first |
| Picks, looks, money | Ryan | his game and his accounts |

## If you are not the main agent: work in your own folder

- Put everything you make in `contrib/<your-agent-name>/` (for example `contrib/argon/`). Do not edit files outside it: no game
  source, no tools, no docs, no `hulls*/` assets. Muse is the exception: it may deliver low-code fixes in text, data, tests, tools and docs as PRs (R81); the copy-in-folder rule stays for every other outside agent.
- Proposing a change to an existing file? Put a copy of the whole changed file in your folder at the same relative path, for example
  `contrib/argon/tools/blender/hs/h10_kit.py`, plus a `NOTES.md` that says what changed and why.
- Reviews go in `contrib/<your-agent-name>/reviews/<topic>.md`.
- The main agent merges what works. See `contrib/README.md`.

## Ship models (the current big job)

- Start with `docs/ship_pipeline/README.md` (the pipeline), then `docs/ship_pipeline/BLOB_SWEEP.md` (what "done" means), then
  `docs/ship_pipeline/SHIP_QUEUE.md` (all 36 hulls and their status).
- Worked example: the Pyre-Barge, `C19_51`. The live hand-built parts builder is `tools/blender/a1/barge_v15.py`; `tools/blender/hs/c19_kit.py` is history and not the live kit path (FINDINGS D3). The job files are in
  `tools/pc/jobs/c19_*.bat`.
- Owner's placement rules for hand-built parts:
  - snapped onto the real hull, on visible mounts;
  - guns aimed forward or out to the side, never backward (no ship in the game fires backward), never into the ship;
  - matched symmetric pairs;
  - Corsair is the exception and may be junky.
- Space ships, not naval ships: no keels, jackstaffs, bollards, crow's nests, yardarms or mast ladders (owner, Oct 22). Guns never face backward.
- Free tools only. No triangle limits: costs are reported, never capped (R111). The current Godot pipeline exports ship assets as glb copied into the PC build (G-9, G-11); the meshoptimizer `.vsm` format belongs to the frozen browser game, not the Godot product.

## Owner rulings and lore (moved from CLAUDE.md, Nov 8 2026)

- Owner rulings of Oct 24 that override older docs:
  - PC-only;
  - shields keep faction colours (the cyan-only rule is retired);
  - battles grow over a run toward about 20 ships (a guide, not a cap);
  - the dead-star gravity-well board stays;
  - capture is add, strip or ransom.
- **Lore approved (owner, Oct 27 2026; FINDINGS R59).** The game is *Embers of the Hollow Sun*. Display names follow `contrib/opus/compute/lore_bible_r8.md` and `contrib/opus/compute/rename_map_final.md`; ids never change: `voidsworn` = Sunward Crusade, `corsair` = Ashfall Hullbreakers, `ithar` = the Glasswrights, `deathless` = Eclipse, `chorus` = the Chorus, `hegemony` = Hegemony Navy. Where these rules say Corsair, read Hullbreakers (still the haphazard, junky exception).

## Ryan's PC first (moved from CLAUDE.md, Nov 8 2026)

- **Ryan's PC first (owner, Oct 21 2026).** Anything heavy runs on Ryan's PC through the test watcher, not in the cloud sandbox: AI model runs (ComfyUI, Pixal3D, Qwen, TRELLIS, Hunyuan), Blender bakes and renders (`voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe`, GPU), closeshots, smoke tests, load probes. The PC has an RTX 5080 (16 GB), 32 GB RAM and 400+ GB free. The sandbox (about 8 GB RAM, CPU only) is for editing code, small conversions and looking at results; it runs out of memory on full-detail meshes.
- How the PC runner works, and its pitfalls: see `docs/archive/handoff_history_2026_11.md` ("PC test runner").
- ComfyUI portable: `Downloads\ComfyUI_windows_portable` (v0.42.1), driven headless by `tools/pc/comfy_run.py`; job I/O in `Downloads\voidsworn_test\comfy_io\CODE\`.
- Ryan is not a coder: double-click .bat files for anything he runs himself, plain words, screenshots of results.

## Ship parts and look (moved from CLAUDE.md, Nov 8 2026)

- **Ship parts look like they belong (owner, Oct 21 2026).** Hand-built bolt-ons on the AI hulls (guns, racks, funnels, masts, drums, turrets) must make sense where they sit: snapped onto the real hull surface (never floating or sunk), on a visible mount (plate, ball, saddle, column), guns aimed forward or out to the side, never backward (owner, Oct 22: no ship in the game fires backward; bow guns may face forward along the prow, never aimed back into the ship), and placed in matched, symmetric pairs at sensible hard points. Corsair is the exception: haphazard and junky is on-brand there. Soft or blobby AI areas near the bridge and superstructure get rebuilt by hand the same way (tools/blender/a1/barge_v15.py is the live worked example; tools/blender/hs/c19_kit.py is history and not the live kit path, FINDINGS D3).
- **Space ships, not naval ships (owner, Oct 22 2026: "careful that these don't stretch into obvious naval-looking ships. again, these are SPACE ships").** Keep the concept's look, but never add sea-ship tells: no boat keels or raked stems, jackstaffs, bollards, anchors, crow's nests, yardarms with rigging, mast ladders, lifeboats, portholes in rows along a waterline. Prefer the space versions: armoured flat bellies with chines, sensor housings and antenna arrays, equipment pods, recessed lights, main engine bells and thruster pods, docking hatches, heat radiators. Owner, Oct 24 2026: this covers the whole hull shape (bow profile, keel line, deck line), not only bolted-on parts; crossbar masts and smokestack funnels count as naval tells and become antenna arrays and heat radiators.
- **Breakable by design (owner, Nov 4 2026, FINDINGS R98).** Every new or rebuilt hull gets real hull thickness, a few internal decks and bulkheads, and two or three authored break lines with matching interior faces and damage textures, so broken pieces never look hollow. Chorus hulls get flesh and bone inside. Older hulls rely on the game-side interior fallback (#167).
- **Blob sweep for every AI ship (owner, Oct 21 2026: "ensure we catch all of those for all other ships").** Before showing a ship, review it region by region against the concept: bow / midship / stern, each from the top, the side and below (9 cells, studio renders at the same angles as the concept views). The sweep is a viewing instrument for Ryan's eye, with no clean-or-rebuild pass bar (R121). Things the AI reliably mangles and that get rebuilt by default:
  - guns of any size (turrets, casemates, long cannons, bow chasers, stern guns), rocket racks and launchers
  - bridge and superstructure tiers, masts, funnels, antennas, rails
  - tanks, drums, torpedo/fuel cylinders, lamps and light rows
  - the bow (usually wavy: rebuild as a faired loft from the AI hull's own sections)
  - engine nozzles and ventral thrusters, armour plate stacks, side sponson blocks
  - any thin spiky or crossed sticks (AI wire debris)
  Hand-built parts carry the AI hull's level of surface detail (seams, grit, worn edges; owner: "the level of texture and details seem to vary wildly").
  Parts the concept shows poorly (tops, undersides, racks seen end-on) keep their own hand paint (project_paint KEEP boxes) instead of projection, or they come out a grey blob.
- **Pipeline gotchas (browser-oracle history, Oct 21 2026; the browser build is frozen, R32 and R33):** the game's ship size comes from hull + kit together (pixal_to_game reads the kit for bounds; cutting the AI bow without it stretched the ship 1.33x). Kit material lights by stored normals (no two-sided lighting); the old 0.3 paint self-light now defaults to 0 (ships3d.js:790). closeshot's server needs a big backlog or desktop shots silently drop the kit.

## Owner preferences that apply to any agent

- Plain words, short, lead with the answer, no em dashes, give your pick rather than a neutral list.
- Show screenshots of anything visual.
- Anything Ryan runs himself is a double-click `.bat` file (Windows 10, PowerShell 5.1, no real Python of his own).
- Before anything bigger than a quick fix, ask 3 to 5 plain-language multiple-choice scope questions in one batch.

## Heavy work

Heavy work runs on Ryan's PC (RTX 5080) through the test runner: AI models, Blender bakes and renders, game screenshots. How the
runner works and its pitfalls are in `docs/archive/handoff_history_2026_11.md` ("Gotchas") and `docs/ship_pipeline/README.md`.

`CLAUDE.md` is a short pointer to this file plus Claude-only notes. Keep the two in step.

Time estimates (Ryan, Nov 4 10:40 CST, FINDINGS R99): never estimate in human hours; every human-hour estimate so far has been wildly off, because the work is done by agents, not people. Estimate in Codex runs (one run is capped at one hour; Nov 4 runs took 11 to 60 minutes, and a heavy GPU bake-off can need two), plus the number of Ryan review rounds, and base it on the board's own history (board\issue-N timestamps and PR times), not on what a human artist would spend. Say what drives the count (GPU bakes, retries, review rounds).
