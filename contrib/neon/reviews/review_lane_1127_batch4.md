# Neon Review Lane - 2026-11-27 Batch 4 (Issue #2251)

Reviewed against `origin/main` at `e23fe088f9b659037efc860db1eed072ed8417f4` (post-`#2236`/`#2237` rules merges).
Priority order: unblocking PRs first (runner/CI, FX/cut-ins, perf), then UI mock-ups and ship/effects proofs, then text/story.
Every open passing PR in the repo now has a `Neon (review):` verdict at its current head commit (PR `#2225` was verified unchanged at `c36515dca`, already reviewed in Run 1; Neon's own `#2256`, `#2266`, `#2267` skipped).

| PR | Issue | Branch | Head SHA | Merge vs `origin/main` (`e23fe088f`) | Verdict | Top findings |
|---|---|---|---|---|---|---|
| #2207 | #2181 | `codex/issue-2181` | `00496fcb459cea930baeaa4ba340b80d4f57f721` | Clean (6 conflicts vs `#2167`) | **COMBINE FIRST** | `janitor.ps1:396-407,443-447` fast helper path skips `Assert-CleanupSnapshot` before `Remove-HelperFolder`; W11 is patch-only (`w11-after-2196.patch`) and supersedes `#2167` in 6 files. (`disk_space.ps1` hash fix confirmed at `runner_common.ps1:1554`.) |
| #2196 | #2179 | `codex/issue-2179` | `c75307d65cc7def27fdac57d84486c99676a8d5e` | Clean (2 conflicts vs `#2220`) | **COMBINE FIRST** | Live `.github/workflows/` untouched (`workflows.patch` for Board rollout) and F9 stays off (`guard.cjs:39`); conflicts with `#2220` in `run_checks.sh` and `godot_shard_tests.js`; per-run `godot_checks-*` and `.onboarding_checks/<scratch>/xdg` dirs lack pass-only cleanup. (Push-target, `stale_work.js` ancestry, and shared-scratch fixes confirmed.) |
| #2253 | #2194 | `work/issue-2194-deepseek` | `2856c8e8439a98a099a2842ffa6ade7850ccb1b4` | Clean (conflicts vs `#2104`, `#2257`) | **COMBINE FIRST** | Duet fixes themselves are solid, but `battle.gd`/`hud.gd` reparent legacy `set_plate` controls and conflict with `#2104` (3 files), while `fx_weapons.gd:779-782` `_burst(..., book := true)` conflicts with `#2257`. |
| #1852 | #1843 | `codex/issue-1843` | `5d710fdddd6a82f18145bd2691fdcbc64166541a` | **CONFLICT** (`battle.gd`) | **FIX FIRST** | Merge conflict in `battle.gd`; duplicate `RenderingServer.frame_pre_draw.connect(_mark_draw_round)` in `kill_frame_probe.gd:35,43`; `round_2_compile_1843.bat:60-66` accepts exit code 3 (`VERDICT_FAILED`) and returns 0 without an aggregate gate verdict; `PIN_CONTROL` predates `e23fe088f`; RTX 5080 proof still open. |
| #2259 | #1402 | `codex/issue-1402` | `1d3be51afea2b5c854d9b782a30431d0d3f0aef4` | Clean | **FIX FIRST** | `reward_card.js:15,19` labels `H9_23` as `"Cordon cruiser"` (duplicating `H8_23` `"Cordon destroyer"`; `FLEET.md:29-31` maps `H9_23` to Vanguard Cruiser and `H10_23` to Dominion Battleship). Fix labels and re-render the two 4-wreck PNGs with provenance before Ryan's pick. |
| #2264 | #1422 | `codex/issue-1422` | `0fbdfc4f6f105efb9ec77c5e0ed7c710c858eb4f` | Clean | **FIX FIRST** | Superseded by Ryan's run 2 brief ("More violet, agreed", Nov 27 12:40 UTC): `stack.py:303-308` washes core and corona toward white; render `eclipse_stack_run2.png` before rebaking. Also fix E13 hull code in issue `#1422` note (`D9_23`, not `D21_23`). |
| #2258 | #2250 | `codex/issue-2250` | `c6de59ccfb79f04e930b9daae843002014c55eea` | **CONFLICT** (20 files) | **COMBINE FIRST** | Conflicts with merged `#2236`/`#2237` on `origin/main` in `campaign_tables.json`, `results.json`, `nem.txt.br`, and 17 `c*.jsonl.br` archives. Merge `origin/main`, keep both rules and Chorus dialogue, regenerate saved fixtures, and rerun parity + `chorus_speech_tests.js`. (Non-blocking note: 8 rewritten GDScript Chorus lines are outside `chorus_speech_tests.js`.) |

## Notes
- No PR was merged, no PR branch was pushed to, no issue was closed, and no PC/GPU job was queued.
- Verified zero em dashes (`U+2014`) and en dashes (`U+2013`) in all review comments and in this file.
