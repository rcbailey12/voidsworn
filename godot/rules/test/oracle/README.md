# The rules oracle, pinned

These are the game's `data.js`, `core.js` and `battle.js`, copied unchanged from commit b71c8d7 (Oct 25 2026, the last change to them before the travel sprint). The parity harness runs these files, not the live ones at the repo root, so stream B can change the JS rules during the sprint without breaking the port's golden test.

**Catching up:** when stream B changes the rules (`contrib/opus/compute/port_notes.md` lists each step), the change is ported to `godot/rules/` with a new golden scenario, then these three files are re-copied from the new commit and this note is updated.
