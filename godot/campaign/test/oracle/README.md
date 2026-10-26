# The campaign oracle, pinned

These are the game's JS files, copied unchanged, that the campaign parity test runs against:

- All seven files from commit c7b1a78 (Oct 26 2026: stream B steps 0 to 3, see `contrib/opus/compute/port_notes.md`), the same commit G1 pinned in `godot/rules/test/oracle/`: `data.js`, `core.js`, `battle.js`, `campaign_run.js`, `campaign_meta.js`, `campaign3d.js` and `ui3d.js`.
- `ui3d.js` is presentation; only two of its tables are evaluated: `FNAMES` (ship names for non-Voidsworn fleets, which the browser's `shipName` uses) and `TIPS` (the battle onboarding tips, exported for the battle UI).
- History: b71c8d7 / 29d431c (the first port) until the re-pin to c7b1a78.

The parity harness and the campaign table exporter read these files, not the live ones at the repo root, so stream B can change the JS rules during the sprint without breaking the campaign port's golden test.

**Catching up:** when stream B changes a campaign rule, port the change to `godot/campaign/`, re-copy the six files from the new commit, run `node godot/campaign/test/node/export_campaign.js` to refresh `godot/campaign/data/campaign_tables.json`, run the parity test, and update the commit numbers above.
