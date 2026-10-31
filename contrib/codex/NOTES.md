# Codex pre-reset review and proposed cleanup

## Current start point after the Oct 30 upload

Reviewed main **17268efa081059a6923daa9e19e8b345a437714d**. Start with
`reviews/post_upload_closing_2026_10_31.md` and the refreshed proposed
`contrib/muse/RETURN_INDEX.md`. The original review below is historical.

The PR now incorporates the uploaded main head. The new closing packet inventories
176 changed paths (149 Muse, 18 DeepSeek, 9 Gemini), records a current 125-row
register supplement, and preserves all 80 assertions in the repaired proposed suite.
It reproduces 8 pass / 72 fail without changing gameplay assertions. The new
shared-loader exports are preserved.

Additional proposed full copies:

- Campaign/UI/battle test helpers accompany the new suite; the campaign loader
  now resolves its committed sibling harness.
- The cutover gate refuses missing-required-check success and treats a vanished
  tracked test as a regression. It also validates converter/fixture result counts.
  The proposed gate still ends INCOMPLETE because parity vectors are absent.
- The Monte Carlo driver restores source hull prices before every run. The
  original compounds a nominal x1.25 price across runs; do not use A2/A3/A4/A5
  for balance decisions until corrected reruns. Shard/boon-grid repository defaults
  are repaired for adoption; these copies need the original companion files.
- Consolidated text and Nemesis assemblies carry the already-filed explicit
  corrections. Four text anchors match source; full text application is not certified.

Reproduce the focused gate and price-isolation checks:

```sh
node contrib/codex/reviews/post_upload_2026_10_31/probes.js .
node contrib/codex/proposed/contrib/muse/tools/findings_tests/findings_tests.js .
node contrib/codex/proposed/contrib/muse/tools/cutover_gate/gate.js . --out /tmp/voidsworn-reviewed-gate
```

All originals, gameplay code and assets remain unchanged by the proposed overlay.
The affected price cells were not rerun, so this packet contains no replacement
balance recommendations. Large campaign results, visuals and raw external claims
remain scoped as the closing review says.

## Initial packet at cc2d35fd (historical)

October 31, 2026. Reviewed source: cc2d35fd7054458c1e5707561bb9c6a5da2e4227. Requested scope: Muse, Qwen, Google/Argon and DeepSeek contributions from the past week; verify the findings and syntheses, and propose solutions.

## Deliverables

- `reviews/pre_opus_reset_2026_10_31.md`: ten ranked findings, source quotes, proposed fixes and verification limits.
- `reviews/reset_audit_2026_10_31/claim_ledger.csv`: all 125 current register rows with independent dispositions. It does not certify every historical raw-model claim.
- `reviews/reset_audit_2026_10_31/source_inventory.csv`: 833 retrieved original files, including all 636 requested contribution files; line counts, last-line starts and verified blob hashes.
- `reviews/reset_audit_2026_10_31/independent_probes.json` and `verify_claims.js`: reproducible counterexamples and campaign checks.
- Other `.txt` files in that review folder: recorded test outputs. Expected baseline failures are not hidden or edited away.

## Proposed overlay

Everything under `proposed/` mirrors an intended repository path. These are full replacement copies for Opus to review, not applied edits. Strip `contrib/codex/proposed/` when adopting a file. No game source is changed by this packet.

| Intended target | What changes and why |
|---|---|
| contrib/muse/RETURN_INDEX.md | Current reset router with authority, status, corrections and late-return gaps. |
| contrib/muse/NOTES.md, READING_PLAN.md, OPUS_HANDOFF.md | Add historical-state banners routing to RETURN_INDEX; preserve their original content below the banner. |
| contrib/muse/tools/harness/game_loader.js | Export genSector, startBattle, terrainConnected and onBoard, which the already-filed callers use. |
| contrib/muse/tools/harness/fleet_invariants.js, fleet_scaling.js, softlock_sweep.js | Resolve default repository path from the committed layout. |
| contrib/muse/tools/harness/save_fuzz.js | Resolve root path; use the seeded RNG for random garbage and enumerate each fixed garbage envelope once. |
| contrib/muse/tools/harness/validators/table_xref.js | Resolve default repository path from the committed layout. |
| contrib/muse/tools/harness/validators/naming_lint.js | Resolve default root; reject zero existing targets instead of a misleading clean result. |
| contrib/muse/tools/findings_tests/findings_tests.js | Fix shared-loader import and default repo path; leave all 48 gameplay assertions unchanged, including ones this review disputes. |
| contrib/muse/tools/importer_fixtures/generate_fixtures.js | Fix loader import and default root; accept explicit repository and output paths so regeneration can be reviewed without overwriting filed fixtures. |

The allowlist copy accompanies naming_lint so the proposed tree runs independently. It is unchanged from Muse's file.

## Validation

From repository root, these run the proposed copies without adopting them:

```sh
node contrib/codex/proposed/contrib/muse/tools/findings_tests/findings_tests.js .
node contrib/codex/proposed/contrib/muse/tools/harness/softlock_sweep.js . 1500 4
node contrib/codex/proposed/contrib/muse/tools/harness/save_fuzz.js . 300 4242
node contrib/codex/proposed/contrib/muse/tools/importer_fixtures/generate_fixtures.js . /tmp/voidsworn-importer-review
node contrib/codex/reviews/reset_audit_2026_10_31/verify_claims.js .
```

The findings runner exits 1 with 40 failed assertions at this pin; the map sweep exits 1 with 84 elite-guarantee failures. Both are expected baseline results, not an acceptance claim about the game. The importer verification and deterministic fuzzer pass. Generated fixture output is temporary review data, not an adopted fixture replacement. The independent probe script reuses the campaign parity environment, which changes globals, and is intended to run in its own Node process.

The overlays are intended to be adopted at their mirrored original paths. Their no-argument defaults are calculated for those paths. Until adoption, pass the repository argument as shown; pass explicit prose targets to the proposed naming linter.

Windows wrappers and Godot runtime checks were not executed here. This is a review packet and proposed cleanup, not a game fix or approval of the 360 tree texts.
