Refs #1180

The Windows dry run listed **17 cleanup candidates totaling 20.98 GiB** and removed nothing. Live cleanup and verification of the 150 GB target await Board review. [Dry-run report](<C:/Users/rcbai/Downloads/voidsworn_test/board_d/issue-1180/janitor_run2_dry.txt>)

Updated `tools/pc/` to verify generated Godot files, scan finished workhorse checkouts, and verify backups before removing old copies with local work. The nightly window is 3 to 6 a.m. Central, helper folders get three days, and both helper launchers use private TEMP folders. Stage 7 now removes its checked scratch after a successful install. Updated `docs/RULEBOOK.md` §3.3 and added standing tests.

The Windows standing checks passed with two existing baseline findings. The checkout started at main, so I applied the run 1 patch from the local issue ref. No commit or push.