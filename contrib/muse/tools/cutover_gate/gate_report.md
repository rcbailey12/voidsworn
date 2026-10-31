# Voidsworn cutover gate report

Ran: 2026-10-31T01:21:22.719Z
Repo: /home/hatch/workspace/voidsworn-fresh
Clone HEAD: cbffcafef9d3bb1c653feb72430f7a125871e315
Baseline: recorded 2026-10-31T01:20:34.975Z against HEAD cbffcafef9d3bb1c653feb72430f7a125871e315
Total runtime: 7.6s

## Overall verdict: INCOMPLETE (a component did not run)

| Component | Verdict | Time | Result |
|---|---|---|---|
| Findings regression suite | KNOWN-FAIL | 5.1s | 80 tests, 8 pass, 72 fail (a fail is a pinned, unfixed defect) |
| Oracle drift guard | KNOWN-FAIL | 0.7s | oracle pins 10/10 held, 6 of 9 vendored pairs differ, constants 95/120 matched (25 differed, 25 browser-only): the recorded state is staleness, not corruption |
| Validator: table cross-references | PASS | 0.2s | 0 dangling-reference failures, 11 warnings (warnings are the known watch list) |
| Validator: naming linter | KNOWN-FAIL | 0.4s | 1 hard hits (retired display names in current-voice docs), 100 label candidates for human triage, 13 historical/id mentions (info) |
| Importer fixture loader checks | PASS | 0.6s | 21/21 fixture stores load through the game's own loadLocal, pass saneSave, and match their recorded loaded state |
| Importer reference converter tests | PASS | 0.4s | 22/22 converter checks pass (21 fixture cases plus the synthetic repaired-copy fallback) |
| Telemetry reference demonstration | PASS | 0.1s | reference logger demonstration passes: the filed same-run join misses the inherited-weakness violation, the lineage join catches it with no false positive |
| Parity vector corpus (plug-in slot) | NOT RUN | 0.0s | parity vector corpus not built yet (beyond-scope slate 3 item); this slot activates automatically when parity_vectors/run_vectors.js exists |

## Findings regression suite: KNOWN-FAIL

What it proves: Every BLOCKER/FIX finding from the audit programs stays pinned by a test that fails while the defect is unfixed and flips when a fix lands.

Result: 80 tests, 8 pass, 72 fail (a fail is a pinned, unfixed defect)
Signature matches the baseline exactly.

## Oracle drift guard: KNOWN-FAIL

What it proves: The Godot port's vendored JS oracles and hand-copied constants have not drifted beyond the recorded staleness, and every README pin claim still holds against git history.

Result: oracle pins 10/10 held, 6 of 9 vendored pairs differ, constants 95/120 matched (25 differed, 25 browser-only): the recorded state is staleness, not corruption
Signature matches the baseline exactly.

## Validator: table cross-references: PASS

What it proves: No id in the game data tables dangles: rosters, weapons, patrons, relic names, price and gate rows all resolve.

Result: 0 dangling-reference failures, 11 warnings (warnings are the known watch list)
Signature matches the baseline exactly.

## Validator: naming linter: KNOWN-FAIL

What it proves: Current-voice documents do not use retired display names (hard hits), and old faction labels are triaged (candidates).

Result: 1 hard hits (retired display names in current-voice docs), 100 label candidates for human triage, 13 historical/id mentions (info)
Signature matches the baseline exactly.

## Importer fixture loader checks: PASS

What it proves: All 21 recorded browser save stores still load through the game's own loadLocal, pass saneSave, and produce exactly their recorded loaded state.

Result: 21/21 fixture stores load through the game's own loadLocal, pass saneSave, and match their recorded loaded state
Signature matches the baseline exactly.

## Importer reference converter tests: PASS

What it proves: The reference browser-to-portable save converter converts every fixture with complete accounting: no id or value disappears unreported.

Result: 22/22 converter checks pass (21 fixture cases plus the synthetic repaired-copy fallback)
Signature matches the baseline exactly.

## Telemetry reference demonstration: PASS

What it proves: The telemetry spec addendum's lineage join catches the cross-run Nemesis adaptation clash that the filed same-run join misses.

Result: reference logger demonstration passes: the filed same-run join misses the inherited-weakness violation, the lineage join catches it with no false positive
Signature matches the baseline exactly.

## Parity vector corpus (plug-in slot): NOT RUN

What it proves: When built (beyond-scope slate 3 item): deterministic battle-layer behavior vectors captured from the browser engine match the Godot port's replays.

Reason: parity vector corpus not built yet (beyond-scope slate 3 item); this slot activates automatically when parity_vectors/run_vectors.js exists

Verdict key: PASS = clean and unchanged. KNOWN-FAIL = unchanged, and the baseline itself records known failures (pinned defects, recorded drift, one lint hard hit). REGRESSION = something moved for the worse; look before anything ships. IMPROVEMENT = a baseline failure cleared; a fix landed or a test rotted, so look, then refresh the baseline with --update-baseline. NOT RUN = the component could not run; it is never counted as a pass.
