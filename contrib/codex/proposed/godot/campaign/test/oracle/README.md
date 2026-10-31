# Proposed campaign oracle update for the elite and shipwright fixes

Prepared and verified with Godot 4.7.2 on October 31, 2026. Base repository:
17268efa081059a6923daa9e19e8b345a437714d. This is a proposed controlled update,
not a wholesale re-pin of the campaign oracle to current root JS.

The original d8b47c6 campaign pin and existing campaign3d comment exception remain
the base. Two additional intentional exceptions are prepared here:

- core.js: the guaranteed elite may fall back to a shipyard/drydock node when
  no battle/event node is available. Only the fallback expression changes.
- campaign_run.js: retain the upgraded ship uid and exclude it from companion
  repair targeting when another ship exists. Only that outcome-selection logic changes.

Adopt these two files together with the matching selected campaign.gd hunks.
The proposed campaign.gd also combines both fixes. Existing campaign tables
regenerate to the same checksum; no data export replacement is required for
these two function-only edits. No battle-rule oracle is changed by this packet.

Validation: both original and proposed Godot scripts compile; 30 seeded campaign
runs match their respective JS oracles; 64 Nemesis scenario records match; all
4,500 map vectors and six shipwright vectors match exactly. The original reproduces
84 elite-map and three shipwright contract failures; the candidate has zero.
Evidence and repeatable tools are under contrib/codex/reviews/godot_validation_2026_10_31/
and contrib/codex/tools/godot_validation/.

## Original oracle provenance (historical base)

# The campaign oracle, pinned

These are the game's JS files, copied unchanged, that the campaign parity test runs against:

- All seven files from commit d8b47c6 (Oct 26 2026: stream B steps 0 to 4: pass 2 tuning, R42 Nemesis v2, the R42 story fields, the R41 arc hull variants, the R49 Nemesis rulings and the customization reserve; see `contrib/opus/compute/port_notes.md`): `data.js`, `core.js`, `battle.js`, `campaign_run.js`, `campaign_meta.js`, `campaign3d.js` and `ui3d.js`. G1's rules oracle (`godot/rules/test/oracle/`) is pinned separately.
- **One fix on top, in `campaign3d.js` line 56:** since c88567c a `// R42 ...` comment was added in the middle of the line, which comments out `prepBattle(); const setupMs=...` so every campaign battle throws (`setupMs is not defined`) in the browser game too. The pinned copy moves that comment to the end of the line; nothing else differs. Reported to stream B; re-copy once the root file is fixed.
- `ui3d.js` is presentation; only two of its tables are evaluated: `FNAMES` (ship names for non-Voidsworn fleets, which the browser's `shipName` uses) and `TIPS` (the battle onboarding tips, exported for the battle UI).
- History: b71c8d7 / 29d431c (the first port), then c7b1a78, then c88567c, then d8b47c6.

The parity harness and the campaign table exporter read these files, not the live ones at the repo root, so stream B can change the JS rules during the sprint without breaking the campaign port's golden test.

**Catching up:** when stream B changes a campaign rule, port the change to `godot/campaign/`, re-copy the six files from the new commit, run `node godot/campaign/test/node/export_campaign.js` to refresh `godot/campaign/data/campaign_tables.json`, run the parity test, and update the commit numbers above.
