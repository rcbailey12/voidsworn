# The rules oracle, pinned

These are the game's `data.js`, `core.js` and `battle.js`, copied unchanged from main at e80a6a0. The rules and strings there were last changed by stream B in f770e06 (steps 0 to 12: everything up to pass 3 tuning, step 9's RAMP easing, and the two strings-only lore round 8 steps, 90aaf85 and f770e06), plus:

- `fnames.js`, the `FNAMES` table from `ui3d.js` at e80a6a0, with the lore round 8 ship names (the browser defines it and `core.js` shipName reads it);
- `campaign_hooks.js`, `nemAdaptName` from `campaign_run.js` at e80a6a0 (unchanged since d8b47c6) (battle.js calls it when it exists, and the browser always loads it).

The parity harness runs these files, not the live ones at the repo root, so stream B can change the JS rules without breaking the port's golden test.

History: b71c8d7 (Oct 25, the sprint start), c7b1a78 (Oct 26), d8b47c6 (Oct 27), 6b1571e, 59f13a5 and bcc7e47 (Oct 27, data.js only), cb55ec9 (Oct 27, pass 3 tuning), e80a6a0 (Oct 31: step 9 RAMP, strings steps 10 and 12).

**Catching up:** when stream B changes the rules (`contrib/opus/compute/port_notes.md` lists each step), the change is ported to `godot/rules/` with a new golden scenario, then these files are re-copied from the new commit and this note is updated.
