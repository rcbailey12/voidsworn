# Runner 2 (issue 377): what changed, how each part was proved, how the Board swaps the PC copy

Opus worker, Nov 12 2026. Branch opus/issue-377. Nine free dry runs on Ryan's PC (stand-in model and a stand-in for Codex, no
paid calls, 0 cents), all in Downloads\voidsworn_test\opus377 (about 0.1 GB). The proof files are in runner2_377/ beside this
file; the run kit that produced them is runner2_377/kit/.

## The answer first

- (a), (b), (c) and both Board additions each pass a dry run on the PC. The issue 541 case fails loudly and pushes nothing.
- **The issue 541 root cause was not the merge.** The old runner's `git commit -F commit.txt` aborted because commit.txt was
  empty: out\commit.txt in work217\issue-541-deepseek\20261111_183631 is 0 bytes, written at 19:41:56 CST, two minutes after
  the disk filled (19:39 CST). The runner never checked the commit's exit code (old work_issue.bat:124 to 125), so
  `git push -q -f origin work/issue-541-deepseek` pushed HEAD, which was the agent's own merge commit. Its five edits stayed
  staged (out\diffstat.txt lists them). The old runner still wrote "pushed" (runner2_377/issue541_old_runner/result.txt).
  Runner 2 fixes the cause (the commit can no longer fail without a stop, and an empty message gets a plain one) and adds the
  Board's check (the commit, and then GitHub's branch, must carry exactly out\diffstat.txt).
- **Before the Board swaps the runner on the PC, apply tools/pc/issue-377-auto_pr.patch.** Until auto_pr.yml carries it, a
  push to work/issue-N-arm-partial matches 'work/issue-*' and would open a pull request.

## What changed

| File | Change |
|---|---|
| tools/pc/work_issue.bat | (a) PARTIAL when the agent's exit code is not 0 (124 is the time cap) or it left a merge unfinished (lines 147 to 157): the push goes to `<branch>-partial` and the runner checks are skipped. (b) guard step after `git add -A` (line 168). (c) commit step (193), push with no force (197), confirm step (199). Disk: settings file created with the switch off (94, 211 to 215), size report and opt-in cleanup at every ending (241). Dry-run knobs: WORK_TEST_BRANCH (refused if it starts with codex/, muse/, work/ or opus/, line 70), WORK_DRY_SCENARIO, WORK_SKIP_CHECKS, WORK_DRY_SPARSE (lean blobless clone, 123 to 129), WORK_TEST_FAULT, WORK_ROOT. Every path that ran the agent still writes "pushed", "no changes" or "failed" into result.txt, so WORKHORSE_CHAIN2.bat's wait (findstr on those words) still works. |
| tools/pc/work_issue.ps1 | prep also writes out\deliver_to.txt. The guard step writes everything it makes (refused\, refused.txt, scope_warnings.txt, guard.md) into a folder of its own per run, `<out>\runs\<date_time>\`, named in out\guard_dir.txt; the commit step reads guard.md from there (Muse's condition on PR 575). New modes: `guard` (line 219), `commit` (295), `confirm` (389), `tidy` (415); helpers from line 47 (Scope-Paths 54, Refuse-Reason 71). No email or identity in the script: the .bat sets GIT_AUTHOR_* and GIT_COMMITTER_* to the same identity the old `git -c user.name ... commit` used. |
| tools/pc/codex_issue.bat | The same partial, guard, commit, push and confirm steps (lines 81 to 104), through work_issue.ps1 in the same folder. Self-located (`%~dp0`) instead of `%B%\tools\pc`: identical when run from build_b\tools\pc, as every CODEX_RUN_*.bat does. The push-failure patch is now `git diff --binary` from the agent's HEAD (format-patch skips merge commits). Guard failure exits 13, not 9, so it cannot be read as the usage limit (exit 9). Test knobs CODEX_TEST_ROOT, CODEX_TEST_AGENT, CODEX_TEST_BRANCH, CODEX_TEST_SPARSE. |
| tools/pc/issue-377-auto_pr.patch | Not pushed as a workflow edit. Adds `'!codex/issue-*-partial'` and `'!work/issue-*-partial'` after the branch patterns, and a first line in the step that exits for any `*-partial` branch before it calls gh. |
| tools/pc/work_cleanup_setting.bat | Ryan's one switch (copy it to the PC root as WORKHORSE_CLEANUP.bat): asks YES or NO, writes work217\runner_settings.txt. Removes nothing itself. |
| tools/pc/work/mock_llm.js | Three dry-run scenarios (refuse, timecap, merge); the default script is unchanged. Port wait raised to five minutes. |
| tools/pc/work/README.md | A "Runner 2" section: the steps, exit codes, knobs. |

Outside the issue's Deliver to line: mock_llm.js, README.md, work_cleanup_setting.bat and this report with its proof folder.
They are the runner's own test model, its document (R214: a method change lands with its document) and the Board's cleanup
ask; no game file is touched.

### How the commit works now (c)

The run makes one commit with `git write-tree` and `git commit-tree` (no hooks, no editor; its exit code is checked). Its
parents: the agent's HEAD (with any merge the agent made under it), MERGE_HEAD if the agent left one, and, when the branch
already exists on GitHub, that branch's tip (fetched first). Its tree is this run's alone, so a rerun replaces the files as
before, but the earlier run stays in history and the push is a plain fast-forward: no `-f`, no `--force-with-lease`. If
anyone moved the branch between the fetch and the push, the push is refused and out\change.patch keeps the work. The
commit text ends with `Run-Number: k` (the earlier tip's number plus one, or 2 if it has none).

### The diff check (Board addition 1)

`commit` writes out\diffstat.txt and out\diff_numstat.txt from the index just before committing, then compares
`git diff --numstat <agent HEAD> <commit>` with the staged numstat and checks nothing is left staged. Any difference: no push,
"!!! DIFF MISMATCH" in result.txt, out\DIFF_MISMATCH.txt, out\change.patch, exit 10. After the push `confirm` reads GitHub's
branch back (`git ls-remote`), requires it to be the runner's commit, and compares the diff again (out\pushed_diffstat.txt).

### Disk (Board addition 2)

Every run ends with `run folder size: X GB (repo copy Y GB, out Z MB)` in result.txt. work217\runner_settings.txt is created
by the first run with `remove_repo_copy_after_push=no`. Only when Ryan sets it to yes (WORKHORSE_CLEANUP.bat), the run's push
was checked, the run folder sits under work217 and holds repo\.git and out\result.txt, does the runner remove that run's
repo\ (Remove-Item, then `rd` with a long-path prefix if anything is left) and report the GB freed. out\ is always kept. A dry
run only says what it would remove.

## How each part was proved (dry runs on the PC, Nov 12 00:48 to 00:56 CST)

Runs 1 to 4, 6 and 9 used the real runner path (OpenCode headless, Git Bash, tmo.bat, prep reading issue 377 live from GitHub)
with the stand-in model, and pushed for real to `runner377/...` test branches (no pull request, no checks:
auto_pr.yml and checks.yml only match codex/, muse/, work/ and opus/). GitHub shows 0 pull requests and 0 Actions runs for
every test branch.

| Run | Proves | Result (file in runner2_377/) |
|---|---|---|
| 1 refuse | (b) | 5 refused with reasons (9.0 MB file, B16_23 ship file, re-saved muzzle_flow.png.import, godot/gen file, new .uid), 2 warned as outside Deliver to; commit carries only the 3 allowed files; refused copies kept in out\refused (the 9 MB file at full size; since runs 7 to 9 the folder is out\runs\<date_time>\refused). run1_refuse_result.txt, run1_refuse_refused.txt |
| 2 timecap | (a) | `opencode exit 124`, "PARTIAL RUN, stopped at the time cap of 60 s: the work goes to runner377/issue-377-deepseek-partial", checks skipped, commit title "PARTIAL RUN, not a finished job". run2_timecap_result.txt |
| 3 merge, rerun | (c), 541 fixed, disk gate | the stand-in merged runner377/side with a merge commit (as on 541), then edited 3 files; commit ed6940907 has parents 21c8f44 (the agent's merge) and 813aeb535 (run 1); "carries the staged change (3 files); earlier tip 813aeb535 kept as its parent, so the push needs no force"; diffstat.txt and pushed_diffstat.txt are identical; with the setting on: "a real run would now remove ...\repo (0.01 GB) and keep out\; nothing removed". run3_* |
| 4 merge, 541 fault | Board addition 1 | WORK_TEST_FAULT=skipcommit leaves the edits staged on top of the agent's merge, as the 541 run did: "!!! DIFF MISMATCH: push stopped ... staged: 3 file(s); in the commit to push: 0", exit 10, change.patch holds all 3 edits, GitHub's branch unchanged (still ed6940907), repo copy kept ("this run did not end in a checked push"). run4_* |
| 5 codex | codex_issue.bat | stand-in for Codex exits 1 after copying a ship file in: PARTIAL to runner377/codex-377-partial, the C19_51 ship file refused, pushed diff checked. run5_* |
| 6 refuse again | run numbering | the same as run 1 (hull name now keeps its case); commit 512d373b3 is "run 3", Run-Number: 3, earlier tip ed6940907 kept. run6_* |
| 7, 8 Codex reruns | Muse's condition on PR 575 | two stand-in Codex runs sharing one board-style out folder (cx\issue-377), each copying in a ship file whose text names its run: refused copies kept in cx\issue-377\runs\20261112_074254\refused and ...\runs\20261112_074304\refused, and reading both back gives "glb from stand-in run A" and "glb from stand-in run B" (nothing overwritten); runs 2 and 3 of runner377/codex-377-partial, each keeping the earlier tip, Codex run 1 (8db590306) still reachable (behind_by 0). run7_*, run8_*, run7_8_codex_refused_copies_contents.txt |
| 9 workhorse refuse | the final code on the workhorse | 5 refused into out\runs\20261112_074325\refused; PR text points at that folder; run 4 of the test branch. run9_workhorse_refuse_result.txt |

On GitHub after run 6: `compare/813aeb535...runner377/issue-377-deepseek` and `compare/ed6940907...runner377/issue-377-deepseek`
both answer "ahead", behind_by 0: the first and second runs' commits are reachable from the branch after two reruns.

auto_pr patch: `git apply --check` passes on main; the patched step, run locally with a stub `gh`, prints
"partial run branch work/issue-377-deepseek-partial: no pull request (issue 377)" and never calls gh, for both
work/...-partial and codex/...-partial. GitHub's workflow syntax page: "A matching negative pattern (prefixed with !) after a
positive match will exclude the Git ref", and a `!` pattern needs at least one positive pattern beside it (it has four).

The old runner on the same failure (the "fails on main first" case) is the real 541 run: runner2_377/issue541_old_runner/
holds its result.txt ("opencode exit 0 ... pushed work/issue-541-deepseek"), push.txt (a successful push) and diffstat.txt
(the five edits that never reached GitHub).

## How the Board swaps the PC copy safely

1. Apply the auto_pr patch first (`git apply tools/pc/issue-377-auto_pr.patch` on a branch, merge it). Without it a partial
   run on a real work/ branch opens a pull request.
2. Wait until no workhorse or Codex run is active: no `opencode` or `codex` process; for the workhorse, every
   work217\issue-*\latest.txt run has "pushed", "no changes" or "failed" in its out\result.txt (WORKHORSE_CHAIN2.bat runs 564,
   376, 238, 234, 569 in turn tonight, from work217\tools); for Codex, queue\running holds no CODEX job. cmd reads a .bat
   while it runs, so replacing work_issue.bat under a live run can break that run.
3. Copy, never delete: from a fresh checkout of main, copy tools\pc\work_issue.bat, work_issue.ps1 and work\mock_llm.js into
   work217\tools (and work\), and tools\pc\codex_issue.bat and work_issue.ps1 into build_b\tools\pc (codex_issue.bat now needs
   work_issue.ps1 beside it). Keep the old ones as *.bak377 if you want a way back.
4. Copy tools\pc\work_cleanup_setting.bat to the PC root as WORKHORSE_CLEANUP.bat. Tell Ryan in one line what it does; it is
   off until he types YES.
5. The first real run writes work217\runner_settings.txt (switch off) and ends result.txt with its folder size.

## What I am not sure of

- **The real removal was never run.** RULEBOOK 3.3 says nothing is deleted on Ryan's PC without his yes, so the dry runs only
  proved the gate (off: kept; on but no checked push: kept; on and checked: "would remove" with the exact path). Remove-Item
  on a real 20 GB checkout with long paths is untested; if it leaves files, the runner says "only partly removed" with the
  size left. The first real run after Ryan turns it on should be read.
- The after-push mismatch path (`confirm` failing) was only proved on its pass path (runs 1, 2, 3, 5, 6). The before-push path
  catches the 541 shape; `confirm` catches a branch moved or rewritten during the push.
- checks.yml still runs on work/issue-*-partial pushes ('work/**'). Harmless, costs Actions minutes; add the same `!` lines
  there if the Board wants none.
- (Fixed after Muse's check, runs 7 and 8.) Codex's out folder (board\issue-N) is shared between reruns; the refuse step now
  writes into a folder per run, so no rerun overwrites an earlier refused copy. Codex's other files in board\issue-N
  (result.txt, commit.txt, log.txt, last.md) are still overwritten by a rerun, as before this job.
- The time-cap partial run skips the runner checks (they would add up to 40 minutes to a run that already used its cap).
- A refused .import is only unstaged: the re-saved file stays in the run's working folder, as before.

## For LOOP.md "Known traps" (the Board edits LOOP, not this job)

- "A duplicate run of an already merged job force-pushes the branch": no longer true for the workhorse and Codex runners
  after the swap; a rerun keeps the earlier run as a parent.
- The Nov 12 02:20 trap note ("after every workhorse run compare the run's out\diffstat.txt with the pushed branch's diff"):
  the runner now does it and says "pushed diff checked" or "DIFF MISMATCH" in result.txt.

Refs #377
