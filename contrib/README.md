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

The live jobs are the open GitHub issues (the job board, AGENTS.md); start there. The October tasks that used to be listed here
(a parts script modelled on `tools/blender/hs/c19_kit.py`, the old `docs/ship_pipeline/SHIP_QUEUE.md`) are browser-era history,
not the Godot product. Ships are now built through the recipe (docs/playbooks/ships.md section 0) by Opus workers (RULEBOOK
2.6). Work that still helps from outside:

- **Review a playbook or the rulebook** (docs/playbooks/, docs/RULEBOOK.md): a rule with no reason, a step that cannot be
  followed as written, or two documents that disagree. Follow docs/REVIEW_PROTOCOL.md.
- **Write measurement helpers** that find problems automatically (thin spiky components, wavy surfaces, hollow break faces),
  so reviews are less manual.

## Merging

The main agent reads `NOTES.md` and runs anything heavy on Ryan's PC. Merged pieces move to their real paths with a commit message that
credits the folder they came from.
