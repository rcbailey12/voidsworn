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
