# CI speed (issue 1487): before and after

Audit GH-03, GH-04, GH-11 and GH-05 part 2. Branch opus/issue-1487, PR 1494.

## Checkout time per job

| Job | Before (audit, run 44852724945) | After (run 44859999525) |
|---|---|---|
| Standing checks | 187 s | 35 s |
| Godot rules parity | 96 s | 18 s |
| Rules safety net | 99 s | 17 s |
| Godot game checks | 359 s | 20 s |
| A16 death seam | 392 s | 41 s |
| Total checkout | about 1,133 s (19 runner-minutes) | 131 s (about 2 runner-minutes) |

Merging main in now takes 1 to 2 s per job (history without file contents). Godot comes from main's cache in 2 to 3 s
once cache_warm.yml has run on main; until then each job downloads it as before.

## Whole run

- Code push (run 44859999525, every check ran): 20.6 minutes wall clock, Godot game checks the longest at 17.8 minutes.
  The game job is now mostly the 1080 s check list and the 174 s asset import; issue 1430 and job J3 (issue 1489) cover those.
- Docs-only push: the changes job (5 s), the standing checks and "All checks" run; the four Godot jobs are skipped.
  The run is linked in PR 1494.

## Open pull requests that would skip the Godot jobs (checked Nov 21 2026)

10 of 33: 1061, 1163, 1201, 1285, 1314, 1320, 1322, 1391, 1397, 1485. The rest change code, data or workflow files.

## Not done here

- Caching the Godot asset import (godot/.godot/imported, about 3 minutes per game run): not in the brief; a stale import
  cache could hide a broken texture, so it needs its own look.
- main_commit_lint.yml: issue 1488 rewrites it on the compare API with no checkout.
- Old per-branch Blender cache copies: left to expire on GitHub's own 7-day rule (no deletes from this job).
