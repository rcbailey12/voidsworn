Voidsworn ways-of-working audit, Nov 25 2026: tested fixes. Nothing here has been pushed.
Files sit at the repo path they replace or add. The .diff and patches_ci/*.patch files show each change against main 96149fb.
- .github/workflows/auto_pr.yml holds both auto_pr changes together (stale-work restart, and keeping PR notes on refresh).
- .github/workflows/checks.yml holds the CI changes from patches_ci/checks.patch.
- watchers.diff patches tools/pc/watcher.bat and watcher_b.bat.
- tools/pc/compact_repos.ps1: run once as a dry run, then with -Live, after the old relay branches are deleted on GitHub.
- dispatch_path_test.js: node dispatch_path_test.js .github/workflows/auto_pr.yml
