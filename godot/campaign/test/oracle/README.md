# The campaign oracle, pinned

These are the game's JS files, copied unchanged, that the campaign parity test runs against:

- All seven files from commit c88567c (Oct 26 2026: stream B steps 0 to 3, pass 2 tuning, R42 Nemesis v2, the R42 story fields and the R41 arc hull variants; see `contrib/opus/compute/port_notes.md`): `data.js`, `core.js`, `battle.js`, `campaign_run.js`, `campaign_meta.js`, `campaign3d.js` and `ui3d.js`. G1's rules oracle (`godot/rules/test/oracle/`) is pinned separately.
- **One fix on top, in `campaign3d.js` line 56:** at c88567c a `// R42 ...` comment was added in the middle of the line, which comments out `prepBattle(); const setupMs=...` so every campaign battle throws (`setupMs is not defined`) in the browser game too. The pinned copy moves that comment to the end of the line; nothing else differs. Reported to stream B; re-copy once the root file is fixed.
- `ui3d.js` is presentation; only two of its tables are evaluated: `FNAMES` (ship names for non-Voidsworn fleets, which the browser's `shipName` uses) and `TIPS` (the battle onboarding tips, exported for the battle UI).
- History: b71c8d7 / 29d431c (the first port), then c7b1a78, then c88567c.

The parity harness and the campaign table exporter read these files, not the live ones at the repo root, so stream B can change the JS rules during the sprint without breaking the campaign port's golden test.

**Catching up:** when stream B changes a campaign rule, port the change to `godot/campaign/`, re-copy the six files from the new commit, run `node godot/campaign/test/node/export_campaign.js` to refresh `godot/campaign/data/campaign_tables.json`, run the parity test, and update the commit numbers above.
