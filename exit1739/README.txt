Issue 1739 evidence (Board, Nov 22 19:09 UTC), read-only copies.
timeouts.log: the shared one tmo writes (queue\logs\timeouts.log, per run_timeout.ps1 line 548). Its last entry is 2026-11-20T10:31:45, so it has NO entries for these Nov 22 runs: tmo stopped nothing, and node exit 1 is run_all_checks.js's own exit.
The node check is codex_issue.bat line 182: call "%TP%tmo.bat" 1800 node contrib\opus\tools\run_all_checks.js > checks_node.txt.
All three runs have the same four FAIL rows in checks_node.txt: picture_provenance_tests, publish_ship_tests, pysite_1535_tests, relay_push_tests.
No separate tmo exit-trace file exists for these runs; log_tmo_lines.txt is the last 40 tmo-related lines of each agent log.txt.
