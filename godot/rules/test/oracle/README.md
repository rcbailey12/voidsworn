# The rules oracle, pinned

These are the game's `data.js`, `core.js` and `battle.js`, copied unchanged from commit d8b47c6 (Oct 26 2026 evening: stream B steps 0 to 4, the v54 battle backlog, pass 2 tuning, B-21, the R42 and R49 Nemesis and the customization reserve), plus:

- `fnames.js`, the `FNAMES` table from `ui3d.js` at the same commit (the browser defines it and `core.js` shipName reads it);
- `campaign_hooks.js`, `nemAdaptName` from `campaign_run.js` at the same commit (battle.js calls it when it exists, and the browser always loads it).

The parity harness runs these files, not the live ones at the repo root, so stream B can change the JS rules without breaking the port's golden test.

History: b71c8d7 (Oct 25, the sprint start), c7b1a78 (Oct 26), d8b47c6 (Oct 27).

**Catching up:** when stream B changes the rules (`contrib/opus/compute/port_notes.md` lists each step), the change is ported to `godot/rules/` with a new golden scenario, then these files are re-copied from the new commit and this note is updated.
