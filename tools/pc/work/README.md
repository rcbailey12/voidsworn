# Workhorse runner (#217)

OpenCode, headless, on Ryan's PC: one board issue, one model, no one watching. Built and tested by Opus on Nov 7 2026.

## OpenAI arm (issue 985)

Ryan double-clicks `tools/pc/openai_api_key.bat` (the Board can copy it as `OPENAI_API_KEY.bat`) and pastes his key.
It saves only the user setting `VOIDSWORN_OPENAI_API_KEY`, never a file. The runner reads that setting from HKCU for
each live run and passes it through its local environment. It never reads or changes an `OPENAI_API_KEY` user or machine
setting, so Codex keeps its ChatGPT sign-in. Ryan sets a monthly budget in the OpenAI platform settings too.

The Board runs `RUN_RETRY.bat <issue> openai 7200` using its installed retry launcher, or
`work_issue.bat <issue> openai` directly (`WORK_CAP=7200` for the same two-hour ceiling). Code jobs default to
`openai/gpt-6.2-sol` at high effort. For a review, set both `WORK_MODEL=openai/gpt-6.1-terra` and
`WORK_EFFORT=medium` in the job's launcher. The OpenAI arm accepts `low`, `medium`, `high` or `max` in any case.
An invalid value falls back to high with an ignored-setting message. The existing provider guard ignores a
`WORK_MODEL` from another provider. Add a named entry in `openaiPrices` in `work_issue.ps1` and configure the
model and its variants in OpenCode before using another OpenAI model.

The runner passes `--variant <effort>` to the preflight and the agent, and stamps it in `out\model.txt`,
`out\status.json` and `out\result.txt`. OpenCode 1.19.5 merges the selected model variant's
`reasoningEffort` into the provider options. The OpenAI Responses request carries it as `reasoning.effort`.
[OpenCode 1.19.5 request source](https://github.com/anomalyco/opencode/blob/v1.19.5/packages/opencode/src/session/llm/request.ts#L71-L82)

The arm uses `opencode_lean.json` with helper tasks disabled and the same preflight, guards, model stamp, partial pushes
and standing checks as Sonnet. It disables bundled plugins for the run so an OpenCode ChatGPT OAuth login cannot replace
the API endpoint. Deploy `openai_api_key.bat`, `work/mock_llm.js` and both changed OpenCode configs with the runner files.

When the OpenAI agent exits and its last error is a retryable HTTP 429, the runner resumes that OpenCode session with
`--session`. It waits for the provider's stated delay, or 5 seconds if there is no first delay. Subsequent waits are at least
30, 60, 120, 240 and 240 seconds, and each respects a longer delay named by the provider. The waits use the same
`WORK_CAP` as the agent. The stall watchdog starts fresh with each attempt, after the wait. `result.txt` records
`rate limited, resumed N of 6`. If time runs out or the resumes are used up, the usual partial-run path saves the work.
Other failures follow that path immediately. All attempts append events to `log.txt`, which is copied once to
`events.jsonl` for the spend estimate. The runner logs only the HTTP status, retry flag and wait hint from provider errors.

The spend limit is `openai_budget_usd=94` in `work217\runner_settings.txt` (also the default when absent), starting with
the $94 remaining for November 2026. `WORK_ROOT` moves both settings and ledger together. Before a paid probe the runner
refuses a run at or above that month's budget. After the agent, including partial runs and failed probes, it appends one
JSON line per run to `work217\openai_spend.txt`: UTC date, issue, model, input/cached-input/output tokens, estimated USD,
running monthly total and budget. A run id prevents duplicate entries when stats are refreshed; an exclusive file handle
protects updates from concurrent writers. The UTC calendar month resets the total; the budget setting remains until changed.
Invalid ledger data or unknown usage blocks another paid run until the Board reconciles it. No keys or prompts go in it.

An accounting failure after the agent marks the run partial with `spend accounting unknown`. The usual staging, guard
and preservation push still run, to `work/issue-N-openai-partial`, with no pull request and no checked-run result.
Failures before the agent still stop before preservation. If the main ledger is invalid or locked, an independent
unknown entry is saved as `work217\openai_spend_unknown\<run-hash>.json`. These entries block later paid starts even
after the main ledger is repaired or its lock is released, and unknown entries remain blocking across month changes.
To clear a stop, the Board first waits for any ledger writer to finish, keeps the run's logs and existing accounting
files, then reconciles its usage against the provider's usage records. Repair invalid main-ledger lines and add or
correct that run's row with verified counts, USD cost, monthly total and `status: "estimated"`, keeping its `run` id.
Then change the matching independent entry to `status: "estimated"` too, if present. Do not clear an entry just because
the lock is free. Rerun the `openai-budget` helper to confirm the ledger and remaining budget permit a paid start.

`out\openai_estimate.txt`, `result.txt` and `stats.txt` carry the run estimate. Counts come from OpenCode's emitted
`step_finish` stats for the preflight and agent, including cache reads. OpenCode input is uncached input; output
and reasoning are separate, so the ledger adds both at the output rate. The single price table uses the brief's USD per million
tokens: 6.2 Sol and 6.1 Sol each use 2.00 input, 0.10 cached input and 10.00 output. 6.1 Terra uses 1.00, 0.05 and 5.00
([OpenAI pricing](https://developers.openai.com/api/docs/pricing)). These are estimates from emitted usage, not a billing
balance: hidden title calls or interrupted responses without final usage may be absent, and long-context or service-tier
surcharges are not included in the brief's flat rates. An in-flight run can cross the
budget, and simultaneous starts can both pass it; the check stops later starts. The platform budget is Ryan's separate setting.

Free proof: `tools\pc\runner_selftest.bat` includes the OpenAI arm with stub agents, no key and no network. It checks
model and effort in the preflight and agent commands and run records, ignored settings on other arms, missing-key
refusal, provider overrides, spend arithmetic, repeat recording, month rollover and budget refusal. Missing token
fields, an invalid ledger and a busy ledger lock each prove that agent changes reach the
partial branch and the next paid start is refused. Those fault cases commit and push only to tiny local TEMP remotes.
Run `node tools/pc/runner_openai_resume_selftest.js` on Windows with OpenCode installed to check the 429 recovery
against a local mock API. It checks session reuse, spend across attempts, the six-resume limit, the time cap and other HTTP failures.
Ordinary `work_issue.bat <issue> openai dryrun` uses the local stand-in provider in `opencode_mock.json`, which logs
the request's `reasoning.effort` in `out\mock_log.txt`. It never loads the saved OpenAI key or adds spend to the
real ledger. Like the older arms' dry runs it still uses GitHub
for checkout and push validation. The selftest isolates those too and never publishes to GitHub.

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
- **Disk (issue 1186).** Each arm reuses one checkout, `work217\slot_<arm>\repo`, under the same reuse checks as the
  Codex lanes; each run keeps only its own `issue-<n>-<arm>\<stamp>\out\`. One run owns a slot at a time: the slot lock
  (`repo.checkout.lock` beside it) is inherited by the whole work_issue.bat process tree, so it stays held until every
  process of that run has exited. A slot holding unpublished work is set aside as `repo-kept-*` beside it and reported;
  the janitor later prunes older kept copies under its usual checks. Slots leave out `docs/shots/`, the build sheets,
  `contrib/muse/design/`, `hulls_hi/` and `rocks_hi/` unless the issue's Brief or Deliver to line names a path there.
  Every run ends with "disk: run folder" and "disk: shared checkout" sizes in result.txt. The old
  `remove_repo_copy_after_push` switch (WORKHORSE_CLEANUP.bat) is retired and changes nothing.

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
  openai, opus, sonnet and deepseek use OpenCode with the job's model; kimicode always uses Kimi Code CLI and its saved subscription
  login (no API key required); Codex uses the pinned gpt-6.2-sol (CODEX_MODEL in codex_issue.bat). Error events fail even with exit 0. result.txt gets a one-line
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

Deploy work_issue.bat/.ps1, codex_issue.bat/.ps1, runner_common.ps1, review_evidence.ps1, run_timeout.ps1, tmo.bat, gpu_slots.js,
chain_issue.bat and work/mock_llm.js together to each runner tools folder only when EVERY lane is idle (issue 847),
then write the lane's work217\runner_hashes.txt with `runner_common.ps1
hashwrite <tools folder> <hash file>` so the issue 722 checks below can guard the copies. Existing settings and
refused-file guards still apply. status.json records a run
id, branch, state, reason and commit; updates are atomic, with previous versions kept. Unexpected stops stay running and a
chain times out instead of guessing success. Helper failures use exit 14; other runner exit codes keep their earlier meaning.

Each Codex lane uses one exclusive lock beside its checkout (`repo.checkout.lock`). The launcher takes it before writing
the issue folder and keeps it through final reporting. A second launch on that lane stops before touching any run files,
even for another issue. Lane tools refresh takes the same lock. Update the Board's separate refresh script when deploying
the launchers. The lock file stays on disk and Windows releases its handle when the owning process exits.

Before claiming, the runner checks the fixed block's Owner and Branch against the launch. A workhorse branch must include
the exact arm. Board-assigned workhorse jobs can use `Owner: codex` or name the arm. Dry-run push overrides still validate
the assigned branch. GitHub's runner comment says `finished` only after `checked_push`.

Lane tools refresh (issue 1018). Before each job, after any predecessor has finished, run
`powershell -NoProfile -File "%V%\lane_tools_refresh.ps1" -Build build_c` followed by `if errorlevel 1 exit /b 1`.
Here `%V%` is `%USERPROFILE%\Downloads\voidsworn_test` and `lane_tools_refresh.ps1` is the Board's launcher copy
outside the folder being refreshed. Use `build_b`, `build_c`, `build_d`, `build_e` or `work217` for the runner being called.
The command checks that seat's issue status, fetches public `origin/main` through `lane_tools_source`, and keeps the previous
tools in `runner_backups\<build>_<yyyyMMdd_HHmmss>\tools` when it installs a change. Matching tools use no backup slot.
A running job stops the refresh. Older backups rotate instead of stopping it (issue 1194): the newest three stay, and an
older one is removed only when every file in it is kept in the live tools, a newer backup or a saved main snapshot.
`-Build build` refreshes the main queue's `build\tools` (the watcher runs it between jobs), and `-Build tools_live`
installs the canonical copy every `tmo.bat` hands its steps to (RULEBOOK 3.5). The installed commit or failure is recorded
in `lane_tools_refresh.txt`.

GPU claims (R276, issue 847): `tmo.bat` uses `gpu_slots.js` for Godot rendering, Blender and explicit
`PC_GPU_MODE=shared|solo` launches. Two holders live in `voidsworn_test\gpu_slot_1` and `gpu_slot_2` (JSON: issue, PID,
start time, mode, token); `gpu_solo` reserves priority for a solo waiter. Empty files mean released, dead PIDs are
reclaimed, and files are never deleted. A short exclusive localhost bind on port 47847 serializes updates across tools
copies; no client connects or sends data, and the OS releases it on process exit. A busy port waits rather than overbooking.
The go file accepts `GPU cleared` or `GPU cleared: reason` on its first line; anything else waits. GPU waits do not spend
the child timeout, and a one-minute heartbeat keeps the outer agent's stall watch informed. Lane C refuses GPU work.
Deploy the changed `jobs\` and `tools\recipe\` launchers too. Run jobs from this installed tools tree with its adjacent
watchdog and helper; do not borrow a watchdog from an old benchmark checkout. No real GPU run or deployment is part of
lane C's code-only check: the Board does that only when every lane is idle.

Free proof: double-click `tools\pc\runner_selftest.bat`. It makes tiny Git fixture data and stub agents under TEMP, runs all
OpenAI, Opus, Sonnet, DeepSeek, legacy Kimi, Kimi Code and Codex, and prints its evidence folder. It makes no commits, pushes
or model calls. Standing checks call the JS test too;
non-Windows CI checks the entry-point contract and reports the Windows matrix skipped. Test-only overrides are enabled by
WORK_TEST_AGENT plus dryrun, or CODEX_TEST_AGENT plus CODEX_TEST_ROOT: PC_TEST_SOURCE, PC_TEST_MIRROR, PC_TEST_ISSUE,
PC_TEST_PREFLIGHT and PC_TEST_GIT isolate dependencies; PC_TEST_RETRY_SECONDS shortens waits;
PC_TEST_STOP_BEFORE_PUBLISH=1 keeps files but stops before any commit or push. Never set these on a real job.

## Runner 3 (issue 722, Nov 15 2026; Muse audit 706 findings 6 and 7)

Three start checks, shared through runner_common.ps1 and run by both entry points right after init, before the chain
wait, the mirror fetch and any model call:

- **Resolved model stamp.** Every run writes the resolved model id into out\status.json ("model") and result.txt
  ("model: <id>"), and result.txt warns when it differs from the arm's default, whatever the provider: a
  same-provider WORK_MODEL override (invisible to PR 636's provider guard) warns here. The kimicode arm stamps the
  Kimi Code CLI model (kimi-code/kimi-for-coding, or WORK_KIMI_MODEL) whenever the CLI or its test stand-in runs;
  other arms stamp the OpenCode model; Codex stamps its pinned gpt-6.2-sol.
- **Free-space floor.** The run refuses to start when the drive holding Downloads\voidsworn_test has less than
  min_free_gb free: one line in result.txt, status failed, exit 14. No mirror fetch, no model probe, no agent, and a
  chained child waiting on the run fails closed. min_free_gb is a tuning value in work217\runner_settings.txt;
  work_issue.bat seeds 60 when it creates the file, and a missing line or file keeps 60.
- **Board hashes.** When the Board copies the runner files to a PC tools folder it writes work217\runner_hashes.txt:
  `powershell -NoProfile -ExecutionPolicy Bypass -File runner_common.ps1 hashwrite <tools folder> <hash file>`. At
  start each runner compares the SHA-256 of its own folder's work_issue.bat, work_issue.ps1, codex_issue.bat,
  codex_issue.ps1, runner_common.ps1, review_evidence.ps1, run_timeout.ps1, tmo.bat and gpu_slots.js against that file. A mismatch, a missing file or an empty file is a warning
  in result.txt, never a stop, so a run never dies because the Board has not hashed a fresh copy yet. Both lanes read
  that one work217 file.

Free proof: the same double-click selftest (`tools\pc\runner_selftest.bat`) covers all three in test mode: the stamp
and its same-provider warning, the floor (direct and end to end, plus the tuning value and the 60 default), and
hashwrite/hashcheck agreement, mismatch, missing file, and a full run that starts anyway with a drift warning.
Test-only knobs: PC_TEST_SETTINGS (settings file), PC_TEST_SPACE_FREE_MB (fake free space in MB), PC_TEST_HASHES
(hashes file). Never set these on a real job.

## Legacy Kimi reasoning effort (issue 656, Opus, Nov 13 2026)

Live kimicode jobs now use Kimi Code CLI (issue 687). WORK_EFFORT and the OpenCode variants below apply to the legacy
OpenCode dry-run path only; the CLI uses its own saved settings and WORK_KIMI_MODEL. This patch adds no CLI effort flag.

- `WORK_EFFORT=low`, `high` or `max` (any case) before calling work_issue.bat adds `--variant <effort>` to the OpenCode run.
  Leaving it unset uses the default. The legacy kimicode path and the OpenAI arm above accept `WORK_EFFORT`.
  Other arms ignore it with a message. The effort shows in out\model.txt and the
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
