# Workhorse runner (#217)

OpenCode, headless, on Ryan's PC: one board issue, one model, no one watching. Built and tested by Opus on Nov 7 2026.

Ryan's two double-click files (copies sit in Downloads\voidsworn_test; the scripts they call are in Downloads\voidsworn_test\work217\tools\):
- `WORKHORSE_SETUP.bat` (tools/pc/work_setup.bat): installs OpenCode 1.19.5 with npm, asks once for the DeepSeek and Moonshot
  API keys (saved as user settings DEEPSEEK_API_KEY and MOONSHOT_API_KEY, never in a file), checks each key and balance, then asks
  each model for one word through OpenCode. Result in work217\setup_result.txt.
- `WORKHORSE_TRIAL.bat` (tools/pc/work_trial.bat): issue #26 by the DeepSeek arm, then by the Kimi arm. Summary in
  work217\trial_summary.txt.

One run (tools/pc/work_issue.bat `<issue> <deepseek|kimi> [dryrun]`):
1. Fresh clone of main in work217\issue-N-arm\<date_time>\repo on branch work/issue-N-arm (no deletes; latest.txt names the newest).
2. WORK_TASK.md: runner notes (Git Bash, checks, parity command, Godot path, shot folder) plus the issue body, read live from GitHub.
3. Balance read, then `opencode run --auto --format json -m <model>` under tmo.bat (one hour cap). Events in out\events.jsonl.
4. Balance read again a minute later; out\stats.txt holds steps, tool calls, tokens, OpenCode's own cost estimate, and the real charge
   (balance before minus after).
5. Shots from out\shots are copied to docs/shots/issue-N-arm/, then commit (Ryan's git identity) and push; auto_pr opens the PR with
   the agent's report and the run stats as its description.

Models: arm `deepseek` = deepseek/deepseek-flash (DeepSeek V4.1 Flash); arm `kimi` = moonshotai/kimi-k3.1-pro (Kimi K3.1 Pro). Both are
built into OpenCode's catalog; keys come from the environment.

Things learned on the PC (Nov 7):
- OpenCode 1.19.5 starts fine on this Windows 10 PC (the help-text bug #8233 does not show).
- On Windows its shell falls back to PowerShell 5.1, where `&&`, grep and tail fail. The runner sets SHELL to Git Bash.
- Its shell commands stop after 2 minutes by default; parity takes about 8. The runner sets
  OPENCODE_EXPERIMENTAL_BASH_DEFAULT_TIMEOUT_MS to 30 minutes.
- `opencode.json` here allows everything except `git commit` and `git push` (the runner does those; caught anywhere in a command, and `git -c` too) and recursive deletes (`rm -r`, `rmdir`, `Remove-Item`; Ryan's rule: nothing is deleted on his PC). The dry run proves the push, a chained push and a delete outside the repo are refused.
- OPENCODE_DISABLE_MODELS_FETCH keeps the model list and price table pinned to the installed version.

Free dry run: `work_trial.bat dryrun` swaps in work/mock_llm.js, a stand-in model on port 8765 that drives a fixed script (look, write a
file, standing checks, Godot parity, a refused push, a refused chained push, a refused delete, report), and uses `git push --dry-run`. It costs nothing and checks the whole
Windows path end to end.

## Runner 2 (issue 377, Opus, Nov 12 2026)

What the runner does after the agent stops, in order (tools/pc/work_issue.bat; codex_issue.bat does the same through
work_issue.ps1):
- **Partial runs.** An agent exit code that is not 0 (the time cap gives 124), or a merge the agent left unfinished, makes the
  run PARTIAL: it pushes to `work/issue-N-arm-partial` (or `codex/issue-N-partial`), skips the runner checks, and its commit
  title starts "PARTIAL RUN". tools/pc/issue-377-auto_pr.patch makes auto_pr.yml open no pull request for those branches.
- **Refuse list** (`work_issue.ps1 guard`, after `git add -A`). Never committed: files over WORK_MAX_FILE_MB (default 8),
  anything under godot/gen, godot/.godot or godot/assets/ships/<hull>/ (previews and test stay allowed), new .uid files, new
  or re-saved .import files. Each refused file is unstaged and copied to out\refused\ (never deleted); the list goes to
  result.txt, out\refused.txt and the PR text. A changed file outside the issue's "Deliver to" line is a warning only.
- **No force push** (`work_issue.ps1 commit`). The run's one commit is made with git plumbing and its exit code checked; when
  the branch already exists on GitHub its tip becomes the commit's second parent, so a rerun is a plain fast-forward and the
  earlier run's commit stays reachable. The commit text ends with "Run-Number: k".
- **The issue 541 check.** Before the push the commit must carry exactly the staged change (out\diffstat.txt); after it
  (`work_issue.ps1 confirm`) GitHub's branch must be that commit, with that diff (out\pushed_diffstat.txt). A difference
  stops the run: "DIFF MISMATCH" in result.txt, out\DIFF_MISMATCH.txt, exit code 10, nothing (more) pushed. On Nov 11 the
  old runner's commit aborted on an empty commit.txt (the disk was full) and its push carried only the agent's own merge.
- **Disk.** Every run ends with "run folder size" in result.txt. work217\runner_settings.txt holds Ryan's switch
  (`remove_repo_copy_after_push=no` by default; WORKHORSE_CLEANUP.bat, from tools/pc/work_cleanup_setting.bat, turns it on).
  With it on, a run whose push was checked removes its own repo\ copy and keeps out\. A dry run never removes anything.

Every path after the agent has run still writes "pushed", "no changes" or "failed" into result.txt (the size lines come
after it), so launcher chains that wait on those words keep working.
Exit codes: 0 pushed, 7 no changes, 8 push refused (change.patch kept), 10 diff mismatch, 11 commit failed, 12 the branch's
earlier tip could not be read, 13 the refuse step failed.

Dry-run knobs (only with `dryrun`): WORK_DRY_SCENARIO (refuse, timecap, merge: scripts in mock_llm.js), WORK_TEST_BRANCH
(push for real to a branch outside codex/, muse/, work/ and opus/, so no PR opens), WORK_SKIP_CHECKS=1, WORK_DRY_SPARSE
(a lean blobless clone of the named folders), WORK_TEST_FAULT=skipcommit (replays the issue 541 failure). WORK_ROOT moves
the run folders. codex_issue.bat has CODEX_TEST_ROOT, CODEX_TEST_AGENT, CODEX_TEST_BRANCH and CODEX_TEST_SPARSE. The proof
runs are in contrib/opus/reviews/runner2_377.md.
