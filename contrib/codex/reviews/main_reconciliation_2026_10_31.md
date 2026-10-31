# Main reconciliation and Opus return packet

Reviewed main `355a2ac70860db4446f040a5787b19c2d746d779`, compared with the previous closing-review pin `17268efa081059a6923daa9e19e8b345a437714d` and draft PR #1 head `4b062b8b38294b322146624d286f2fb83fc06d58`. The PR incorporates current main before these repairs. No main ref, root gameplay source or Godot runtime source is changed by this reconciliation.

Muse's new work is accepted for handoff with the small provenance wording qualification below. The corrected driver restores source hull prices at the start of each run before applying the multiplier. The corrected rows and high-n A3 report supersede the original price-grid conclusions. The canonical corrections settle the four disputed claims. Seven Qwen raw/review pairs are byte-identical; all seven legs and all nine seat addenda were reviewed. Their fold-in closes the audit, with player and gamedev explicitly remaining three-prong seats. Pack-based engineering claims do not override direct source evidence. The golden writers include CUT/SOLID (`godot/rules/test/node/golden.js:145`, `godot/rules/test/parity_main.gd:60-63`); that disagreement is not a new missing-hash implementation job.

## Findings at the reviewed main pin

Quotes and line numbers below refer to **355a2ac7**, before the PR repairs.

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix/status | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | Gate can treat missing evidence as success or improvement | OBSERVED | `contrib/muse/tools/cutover_gate/gate.js:93,465` | `verdict: cur.badSet.length ? 'KNOWN-FAIL' : 'PASS',` | A missing baseline can look clean; the original overall ordering also lets improvement outrank a component that did not run. Disappearing failures must not look fixed. | Fixed on PR: missing baseline is NOT RUN; missing checks outrank improvement; tracked items must actually pass; disappeared items regress. Adapters reject inconsistent counts, identities and exits. | High |
| 2 | Default naming scan points outside the committed layout and accepts no documents | OBSERVED | `contrib/muse/tools/harness/validators/naming_lint.js:63,104` | `process.exit(hard ? 1 : 0);` | Zero hits says nothing if zero files were scanned. Other verification runners have the same stale default-path pattern. | Fixed on PR: repo-relative defaults, sibling shared loader, explicit document coverage, missing/empty targets exit 2. Importer generation takes explicit source/output arguments. Save fuzz garbage choices are seeded and fixed garbage envelopes enumerated. | High |
| 3 | FS-5 survives as an actionable build request beside its correction | OBSERVED | `contrib/muse/reviews/balance_design_bible_2026_10_30.md:180` | `Chorus: build the feed and grow system its texts already promise` | An implementer following the open-decision list could build a second feed system. | Fixed on PR in the Bible, faction synthesis, gamedev synthesis and final synthesis. Only growth/presentation remain open. Original persona legs and the correction record are preserved. Four entrypoints retain Muse's correction headers/history while routing readers to the current work order. | High |
| 4 | A3's new-seed wording is broader than the filed grid supports | OBSERVED | `contrib/muse/reviews/chorus_a3_highn_2026_10_31.md:11,22`; `price_grid_correction_2026_10_31.md:15` | `a range no earlier Chorus row used` | The A3 extension 21300-22799 overlaps A1's seeds 22000-22299 under a different intervention. These are new A3 runs, rather than globally unused Chorus seeds. | Wording qualification for Muse: “new to A3.” No rerun or withdrawal of the reported A3 result is warranted by this overlap. The experiment/report remains unchanged on this PR. | High |

## Changes prepared on PR #1

The assigned tooling repairs now live at their canonical `contrib/muse/tools/` paths on the PR. Muse's corrected `montecarlo/driver.js` and the recorded cutover baseline are byte-identical to main. Only the Monte Carlo entry runners' default source paths changed; no experiment was rerun. No assertion was deleted or weakened.

The gate also requires its drift source inputs and rejects shrinking comparison coverage. A difference disappearing from the drift adapter is conservatively a regression until explicitly reviewed, because that adapter does not yet emit a complete set of passing comparison identities. Missing baseline creation remains an explicit `--update-baseline` operation; normal runs never write it.

Retired Codex tool and entrypoint overlays were removed, including the superseded driver candidate. The proposed shipwright/elite/browser/Godot/oracle changes and corrected text/Nemesis assemblies remain proposed. They were not copied into runtime source. Their previous validation still applies to the unchanged runtime pin, subject to rerunning scoped checks after adoption.

`contrib/muse/OPUS_HANDOFF.md` now starts with the current integration order. `RETURN_INDEX.md`, `READING_PLAN.md` and `NOTES.md` route to it while preserving the corrections-batch headers and earlier material. `contrib/codex/OPUS_START_HERE.md` adds a concrete acceptance checklist for the next playable phased battle, covering inspection, movement rehearsal, explicit fire, cancel/brace/pass, accurate hints and a fleet-density capture.

## Verification

Evidence directory: `main_reconciliation_2026_10_31/`.

| Check | Result |
|---|---|
| Real 80-assertion suite from canonical layout | 8 PASS / 72 FAIL, unchanged game behavior. These assertions require the ledger's dispositions; this is not a count of 72 accepted bugs. |
| Adversarial gate/lint probes | 24/24 pass: missing baseline, lost passing/failing identities, genuine fix, unchanged failure, incomplete precedence, duplicate/truncated/empty results, abnormal exits, empty/missing lint targets and reduced/missing drift coverage. |
| Actual gate control | Findings/drift/naming KNOWN-FAIL; xref/fixture loading/reference converter/telemetry PASS; parity slot NOT RUN. Overall INCOMPLETE, exit 1. Baseline unchanged. |
| Naming lint with no arguments from `/tmp` | 40 documents scanned, 1 hard hit, 100 candidates, 13 historical/id mentions. Missing and empty targets fail. |
| Fleet invariant smoke | 1,512 fleets, 1,513 checks, zero failures (one seed per cell). |
| Fleet scaling with default source from `/tmp` | Zero failures. |
| Seeded save fuzz | 30 rounds plus fixed garbage and round-trip, zero failures; two identical-seed runs have byte-identical output. |
| Portable importer generation | Wrote into a separate temporary directory; all generated fixtures verified by the game's loader, including repaired/corrupt pairs. Canonical fixtures unchanged. |
| Softlock smoke | Six maps and 480 battle setups, zero failures. This smoke is not a replacement for the earlier 4,500-map evidence. |
| Scope/diff checks | No root JS or Godot runtime changes between the old/new main pins. No new canonical driver, baseline, fixture-data or runtime changes in this repair. `git diff --check 6436b2e HEAD` passes for this repair. Full historical PR checks also flag existing CSV CRLF line endings; those earlier evidence bytes are preserved. |

## Read receipt and boundaries

`review_inventory.json` records all 42 changed files between the closing-review pin and 355a2ac7, their byte hashes, line counts, exact first 40 characters of the last line, and changed line ranges. New reports and seven unique Qwen legs were read in full; identical raw duplicates were verified by bytes. Existing documents were reviewed by changed hunks and relevant surrounding passages, rather than claiming a fresh end-to-end read of the entire historical corpus. Nine Qwen fold-in addenda and the final closure were read. Source was read from local Git objects at the exact pin, then all 42 pinned raw GitHub files were retrieved and checked against that content by length and FNV-1a64. The raw-byte SHA-256 hashes are in the inventory and the retrieval check is in `raw_retrieval_verification.json`; no rendered-page folding was used.

The FS-5 search receipt classifies residual matches: the original gamedev persona leg and the canonical correction quote remain historical evidence; corrected working documents no longer commission a missing feed system. No external raw leg was rewritten.

Recommended next step: Opus adopts the tooling repair, then the two already validated gameplay candidates in small commits, before implementing the next bounded module/Nemesis fixes and demonstrating one playable phased battle. Keep PR #1 draft. No more price grids, A3 confirmation or Qwen collection is pending.

## Not checked

Muse's archived raw shards and visuals were not mounted here; only the archive index and recorded checksums were reviewed. The reported aggregates were not independently regenerated. The minor seed wording issue does not establish a numerical error. No Windows launcher execution, rendered Godot battle, GPU/Pixel performance, audio listening, full content/lore sign-off, shipping importer transport, or general battle parity corpus was verified in this pass. Prior targeted Godot campaign results remain scoped proof and do not make the cutover gate complete.
