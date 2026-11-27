# Neon Review Lane: Batch 2 (Nov 27, 2026)

- **Issue:** #2251 (next batch, Board Nov 27 06:05 UTC)
- **Base tested against:** `origin/main` at `91ee81f6f4f83e7ae1b7127f5383d6434f45ea4e`
- **Tally:** **3 MERGE** (`#2236`, `#2017`, `#2226`), **1 FIX FIRST** (`#1980`), **1 COMBINE FIRST** (`#2167`). Every PR has a matching `Neon (review):` comment posted on GitHub.

## Verdicts

| PR | Issue | Branch @ Commit | Local Merge vs `origin/main` (`91ee81f6f`) | Verdict | Findings / Conflict Files | One-line Summary |
| --- | --- | --- | --- | --- | --- | --- |
| #2236 | #2206 | `codex/issue-2206` @ `d17da6a311758be371a2db5e20031554b58f0b55` | Clean | **MERGE** | None. | Cleanly delivers all R460 picks (C1, W9, C2, C3, C4, H4) and regenerates the 21 portrait-updated campaign archives on post-`061f6268` main with `All checks` green; ready as the base for #2237 (#2205). |
| #2017 | #2001 | `codex/issue-2001` @ `1cb2f7d4a79bdd91dc7a518aaf1b278549bce913` | Clean | **MERGE** | None (GPU before/after grade via `capture.bat` runs after review per R407). | Restores main's `_shutdown(code)` in `look_bench.gd` and all 3 missing CI rows, keeps Material Maker strictly opt-in (`VS_MM_TRIAL=1`), preserves diagnostic stills on failed after-grades, and reframes Terran c26 from baked masks with `All checks` green. |
| #1980 | #1974 | `codex/issue-1974` @ `82983313c5da75b5e8b004dcf530cf92d05736aa` | Clean textually; breaks semantically on main (`fx_weapons.gd:2032`) | **FIX FIRST** | Saved partial `e8e3f8f5` is NOT in PR head (`battle.gd:3583` `elif hull_hit or bool(h["crit"]):`, `godot_checks.txt:182` reverted #2039 description); Glasswright test fix is NOT in PR head (`standalone_hit_check.gd:105-106` reads missing `WEAP.IMPACT_RESPONSE.glass.tint`). | Carry forward `e8e3f8f5`, merge `origin/main`, update `standalone_hit_check.gd:105-106` for `faction_glow` (`FLOOK.of("ithar").damage_glow`), and rerun CI. |
| #2226 | #1405 | `codex/issue-1405` @ `cea46ccf39cd40f9d08aef8e9f8816f57987d2e4` | Clean | **MERGE** | None. | Run 2 cleanly drops parked C9 and C35, restores live title framing to main, keeps C26 unwired, adds provenance-stamped 1280x720 `C4A_close_rim.jpg` and `C4B_wide_orbit.jpg` with the gold wordmark, and passes `All checks`. |
| #2167 | #2144 | `codex/issue-2144` @ `3389280da9c0afbc7ea6c3b1aceaf971edc1d05e` | **Conflicts (1 file vs main + 5 files / 12 overlaps vs #2207)** | **COMBINE FIRST** | Conflicts vs `origin/main` in `tools/pc/runner_selftest.js` and semantically in `tools/pc/runner_common.ps1:2400-2409` vs `origin/main:2370-2385` (`#2263`); Run 5 made zero edits leaving `opus_job_head.ps1:216-217` and `janitor.ps1:212,234` unfixed; collides with #2207 (`00496fcb4`) across 12 files (`janitor.ps1`, `opus_job_head.ps1`, `janitor_r455_tests.js`, `janitor_relay.ps1`, `relay_push.bat`, `runner_selftest.js`, `runner_common.ps1`). | Run 5 failed to read its brief; rebase/combine onto `origin/main` + #2207 (keeping #2207's `[NullString]::Value`, live legacy origin confirmation, `Invoke-StorageUpkeep`, and mirror fetch refspecs) and fix `opus_job_head.ps1:216-217` before live rollout. |

## Not Checked

- Live Godot 4 GPU rendering, RTX 5080 `capture.bat` grading for PR #2017, 1080p playtesting of `deploy_grid.gd` for PR #2236, and live Windows PowerShell execution of `janitor.ps1` / `opus_job_head.ps1` for PR #2167.
