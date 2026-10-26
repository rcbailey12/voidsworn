# The campaign oracle, pinned

These are the game's JS files, copied unchanged, that the campaign parity test runs against:

- `data.js`, `core.js`, `battle.js`: from commit b71c8d7 (Oct 25 2026), the same commit G1 pinned in `godot/rules/test/oracle/`. They were still identical at 29d431c.
- `campaign_run.js`, `campaign_meta.js`, `campaign3d.js`: from commit 29d431c (Oct 26 2026). These had not changed since b71c8d7 either.
- `ui3d.js`: from commit 29d431c. It is presentation; only two of its tables are evaluated: `FNAMES` (ship names for non-Voidsworn fleets, which the browser's `shipName` uses) and `TIPS` (the battle onboarding tips, exported for the battle UI).

The parity harness and the campaign table exporter read these files, not the live ones at the repo root, so stream B can change the JS rules during the sprint without breaking the campaign port's golden test.

**Catching up:** when stream B changes a campaign rule, port the change to `godot/campaign/`, re-copy the six files from the new commit, run `node godot/campaign/test/node/export_campaign.js` to refresh `godot/campaign/data/campaign_tables.json`, run the parity test, and update the commit numbers above.
