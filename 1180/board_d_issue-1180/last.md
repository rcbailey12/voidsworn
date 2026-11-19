Implemented issue #1180 and left the changes uncommitted. The PC dry run listed **18 folders totaling 90.4 GiB of logical size** and removed nothing. It kept 48 folders it could not read and 13 containing linked paths. The Board has the report for review before live rollout. [Dry-run log](<C:/Users/rcbai/Downloads/voidsworn_test/janitor_20261119-1114.txt>)

- Added `tools/pc/janitor.ps1` and `janitor.bat`, wired into `watcher.bat` after 3:00 AM Central and into both runners below 150 GB, before the 60 GB floor check.
- Updated the shared Git cleanup checks and runner endings. The runners keep the newest failed scratch per issue for one day and honor the PC pause.
- Extended `runner_cleanup_tests.js` and updated `runner_selftest.js` and `docs/RULEBOOK.md` §3.3.

The full standing suite passed with its existing baseline allowances. The Windows runner self-test passed all 134 checks. The brief limits PC verification to dry run, so live disk recovery remains unverified.

**FINDINGS**

R336 (issue 1180) landed in `docs/RULEBOOK.md` §3.3 and `tools/pc`. It extends R326 with nightly and low-space cleanup, a wider shared list of rebuildable files, and one-day retention of the newest failed scratch.

**New `runner_hashes.txt` lines**

```text
597873c52167ff0fa48b123f62a2d930d5461e374dc019faad9ca11f4468339a  codex_issue.bat
0843c11d644ecf22f4eab864987764c1e9871d14b1370c801bb3ae80e661bca1  codex_issue.ps1
4741192e876698a02c3fe8e01fe045f29b6dba0bde2b9e2d576c25b793c3f549  runner_common.ps1
7f79f07d097f81462ab985a1204f62e60f6520dc925e58d20e0ff06e1291e010  work_issue.bat
8086c6367340ee032ec45e834363ed6e9c7df088a6cfff7d78f075ecd5428020  work_issue.ps1
c0b911d1202af16311a5559feadca062a370b2a0edb633f27a81cc4b1844f368  janitor.ps1
a430850f528eb95d5fc22d6b5772db97af7d69bd9ddc39260a72d66ae59e56c9  janitor.bat
```