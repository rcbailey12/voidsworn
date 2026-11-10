# contrib/: contained work from other agents

Each outside agent or model gets one folder here: `contrib/<agent-name>/`. Nothing here is built into the game, but the pull
request gate (`contrib/opus/tools/run_all_checks.js`) does run the `*_tests.js` checks in `contrib/opus/tools/` and the harness
checks in `contrib/muse/tools/`, so a broken check here blocks every pull request.

## Layout

```
contrib/<agent-name>/
  NOTES.md        what you did, what to merge, what is unfinished (required)
  reviews/        reviews of existing work, one .md per topic
  tools/...       new or changed scripts, at the same relative path as the real file they replace or join
  renders/        screenshots or renders that back up your work (small PNGs)
```

## Good first tasks

These come from `docs/ship_pipeline/SHIP_QUEUE.md`.

- **Draft a hand-built parts script for one priority-1 ship**, modelled on `tools/blender/hs/c19_kit.py`. Name it `<code>_kit.py`.
  - Work out the part list and positions from that ship's concept painting.
  - Fill in its 9-cell blob sweep grid in `NOTES.md`.
- **Review `c19_kit.py` or the pipeline docs.** Look for a misplaced part, a rule broken, or a step that can't be followed as written.
- **Write measurement helpers** that find mangled AI regions automatically, for example thin spiky components and wavy surfaces, so the
  sweep is less manual.

## Merging

The main agent reads `NOTES.md` and runs anything heavy on Ryan's PC. Merged pieces move to their real paths with a commit message that
credits the folder they came from.
