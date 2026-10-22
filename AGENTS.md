# Voidsworn: rules for any AI agent (Claude, Argon, or another model)

Voidsworn is a Babylon.js hex fleet-tactics roguelite built into one HTML file (`python3 build.py`). The owner is Ryan. He is not a coder:
he plays on a Pixel 10 XL and a Windows PC, and he judges work by screenshots.

## Auditing? Start with `docs/ship_pipeline/AUDIT_BRIEF.md`

It holds the goal, the full history, every piece of owner feedback word for word, the open issues and the questions we want answered.

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
