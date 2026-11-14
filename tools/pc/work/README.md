# Workhorse runner (#217)

OpenCode, headless, on Ryan's PC: one board issue, one model, no one watching. Built and tested by Opus on Nov 7 2026.

Ryan's two double-click files (copies sit in Downloads\voidsworn_test; the scripts they call are in Downloads\voidsworn_test\work217\tools\):
- `WORKHORSE_SETUP.bat` (tools/pc/work_setup.bat): installs OpenCode 1.19.5 with npm, asks once for the DeepSeek and Moonshot
  API keys (saved as user settings DEEPSEEK_API_KEY and MOONSHOT_API_KEY, never in a file), checks each key and balance, then asks
  each model for one word through OpenCode. Result in work217\setup_result.txt.
- `WORKHORSE_TRIAL.bat` (tools/pc/work_trial.bat): issue #26 by the DeepSeek arm, then by the Kimi arm. Summary in
  work217\trial_summary.txt.

One run (tools/pc/work_issue.bat `<issue> <deepseek|kimi> [dryrun]`):
1. Refresh the shared bare repo, then clone main from disk into work217\issue-N-arm\<date_time>\repo on branch work/issue-N-arm.
   Merge that arm's partial branch if present (no deletes; latest.txt names the newest).
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
  or re-saved .import files. Each refused file is unstaged and copied to out\runs\<date_time>\refused\ (never deleted; a folder per
  run, so Codex reruns that share board\issue-N keep every earlier copy); the list goes to result.txt, that folder's
  refused.txt and the PR text. A changed file outside the issue's "Deliver to" line is a warning only.
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

result.txt is for people. Chains use status.json as described below; matching words in result.txt cannot prove success.
Exit codes: 0 pushed, 7 no changes, 8 push refused (change.patch kept), 10 diff mismatch, 11 commit failed, 12 the branch's
earlier tip could not be read, 13 the refuse step failed.

Dry-run knobs (only with `dryrun`): WORK_DRY_SCENARIO (refuse, timecap, merge: scripts in mock_llm.js), WORK_TEST_BRANCH
(push for real to a branch outside codex/, muse/, work/ and opus/, so no PR opens), WORK_SKIP_CHECKS=1, WORK_DRY_SPARSE
(a local clone checking out only the named folders), WORK_TEST_FAULT=skipcommit (replays the issue 541 failure). WORK_ROOT moves
the run folders. codex_issue.bat has CODEX_TEST_ROOT, CODEX_TEST_AGENT, CODEX_TEST_BRANCH and CODEX_TEST_SPARSE. The proof
runs are in contrib/opus/reviews/runner2_377.md.

## Reliable starts and restarts (issue 687, Board note)

Ryan approved these five changes on Nov 14 after overlapping downloads, expired login, spent credit and a failed predecessor
cost several runs. Both entry points, `work_issue.bat` and `codex_issue.bat`, use `runner_common.ps1`:

- **One download source on the PC.** `%USERPROFILE%\Downloads\voidsworn_test\repo-mirror.git` is a bare mirror of GitHub.
  Every job fetches it under an exclusive file lock and clones from that disk copy while still holding the lock. The first
  fetch downloads the history; later fetches download changes. Local clones hardlink immutable Git objects, have no alternates,
  and set origin back to GitHub, so a push never writes into the mirror. A killed runner releases the lock automatically.
- **Three attempts.** Each mirror fetch, local clone and earlier-branch fetch gets three attempts total, 120 seconds apart.
  A failed clone folder is renamed beside repo and kept before the next attempt. Network failure stops before the model.
- **Model preflight.** Before ship copying or agent work, a tiny prompt must return exactly RUNNER_READY within 90 seconds.
  opus, sonnet and deepseek use OpenCode with the job's model; kimicode always uses Kimi Code CLI and its saved subscription
  login (no API key required); Codex uses the pinned gpt-6.1-sol. Error events fail even with exit 0. result.txt gets a one-line
  reason and preflight_log.txt holds the details. No automatic model fallback or login is attempted.
- **Safe chains.** Use `chain_issue.bat "<first run out>\status.json" work_issue.bat 642 opus` (or `codex_issue.bat 687`).
  The child writes its own result, then waits before checkout or model use. Only status checked_push with a commit id releases
  it: a non-partial real push confirmed by the diff check, with passing runner standing checks and parity. Both runners run
  those checks; failed checks can still push work for review but cannot release a chain. Partial, no changes, failed, dry/test,
  missing status and a changed predecessor run all stop it. Waiting is capped at 12 hours (PC_WAIT_SECONDS overrides it).
  PC_WAIT_RUN can pin the predecessor's run id. Point to the exact run, not a moving latest.txt. Replace older external
  waiters that search result.txt with this launcher; those unversioned PC files are not changed by this patch.
- **Resume by default.** The fresh branch starts at current main and merges `<branch>-partial` before task generation.
  Both task files name the partial branch and commit and tell the agent to finish that work. A merge conflict stops before
  preflight, preserving the checkout for the Board. Existing Codex checkouts are renamed and kept instead of reset or cleaned.
  Already committed resumed work can still reach a checked push when the agent needs no further edits.

Deploy work_issue.bat/.ps1, codex_issue.bat/.ps1, runner_common.ps1, chain_issue.bat and work/mock_llm.js together to each
runner tools folder while its lane is idle. Existing settings and refused-file guards still apply. status.json records a run
id, branch, state, reason and commit; updates are atomic, with previous versions kept. Unexpected stops stay running and a
chain times out instead of guessing success. Helper failures use exit 14; other runner exit codes keep their earlier meaning.

Free proof: double-click `tools\pc\runner_selftest.bat`. It makes tiny Git fixture data and stub agents under TEMP, runs all
five arms, and prints its evidence folder. It makes no commits, pushes or model calls. Standing checks call the JS test too;
non-Windows CI checks the entry-point contract and reports the Windows matrix skipped. Test-only overrides are enabled by
WORK_TEST_AGENT plus dryrun, or CODEX_TEST_AGENT plus CODEX_TEST_ROOT: PC_TEST_SOURCE, PC_TEST_MIRROR, PC_TEST_ISSUE,
PC_TEST_PREFLIGHT and PC_TEST_GIT isolate dependencies; PC_TEST_RETRY_SECONDS shortens waits;
PC_TEST_STOP_BEFORE_PUBLISH=1 keeps files but stops before any commit or push. Never set these on a real job.

## Reasoning effort (issue 656, Opus, Nov 13 2026)

Live kimicode jobs now use Kimi Code CLI (issue 687). WORK_EFFORT and the OpenCode variants below apply to the legacy
OpenCode dry-run path only; the CLI uses its own saved settings and WORK_KIMI_MODEL. This patch adds no CLI effort flag.

- `WORK_EFFORT=low`, `high` or `max` (any case) before calling work_issue.bat adds `--variant <effort>` to the OpenCode run.
  Unset, nothing is added and every arm runs as before. Only the kimicode arm takes it; on any other arm, or with any other
  value, the runner prints "WORK_EFFORT ... ignored" and runs at the default. The effort shows in out\model.txt and the
  "model:" line of stats.txt (for example `kimicode/kimi-for-coding --variant low`).
- The variants live in opencode_lean.json (and the stand-in copy in opencode_mock.json): each kimicode model has
  `variants.low/high/max = { "reasoningEffort": "<effort>" }`, which OpenCode 1.19.5 sends to the API as the body field
  `reasoning_effort`; the relay in kimi_effort_smoke.js saw it on every agent call. Without those variants OpenCode drops
  `--variant` silently (exit 0, no effort field sent), so to give another arm an effort, write its variants into its config,
  prove them with the smoke tool, and add the arm to the check in work_issue.bat.
- `node tools/pc/work/kimi_effort_smoke.js` (key in KIMI_CODE_API_KEY) runs tiny identical OpenCode runs, one per effort,
  through a local relay that logs what each call sent and the tokens it used; `--upstream stub` does it free, `--direct N`
  makes N bare API calls per effort instead. Results and the trial settings: contrib/opus/reviews/kimi_effort_smoke_656.md.
- Every OpenCode session makes one extra small call to title the session (no tools, about 640 prompt tokens); with the
  variants written in, it goes out with reasoning_effort "low" whatever WORK_EFFORT says.
