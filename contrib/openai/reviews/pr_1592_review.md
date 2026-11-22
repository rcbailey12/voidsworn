# PR 1592 review (issue 1620)

**Hold before a live run.** The whole-folder pass can trust a pruned relay receipt or proceed without a held lease. The new automatic relay sweep can remove a checkout with local history that exists only in its reflog. The Windows fixture passes do not cover those cases.

PR head: `ef0efc3b135b`. Main: `7ef3f96c21e6`. Diff base: `f7f356813728`.

## Findings

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | Pruned relay still authorizes whole-folder deletion | INFERRED | `tools/pc/janitor.ps1:163` | `if ($script:relayReceipts) { return $script:relayReceipts }` | The whole-folder check builds a run-wide set of result blobs. The new relay subprocess can fetch and prune the mirror before the next folder is checked. Results reachable only from the pruned relay branch can still pass the cached membership test. | Use fresh relay refs for live whole-folder deletion; invalidate any cached result on a ref change. Test a prune between two folders. | High |
| 2 | Whole-folder deletion can proceed without owning the lease | INFERRED | `tools/pc/janitor.ps1:266` | `Open-CleanupLock (Join-Path $dir.FullName '.voidsworn-run-active') $true` | Existing-only mode returns no handle when the file is missing. A `helper_clone` start after the process snapshot can acquire the lease while the janitor deletes the folder's contents. PR 1592 extends this older gap to more job names. | Reject linked job roots before opening child files. Create and hold the lease on live runs, taking care that a janitor-created lease does not affect the age check. Make start and cleanup use the same lease. | High |
| 3 | Automatic relay cleanup can lose reflog-only commits | INFERRED | `tools/pc/jobs/opus_job_head.ps1:575` | `$tips = @((Run-Git -C $repo rev-parse HEAD) \| Select-Object -Last 1)` | The inherited proof checks current tips and stash and does not walk reflogs or check for linked worktrees. A detached checkout can return to its pin and look clean while its reflog still holds an unpushed commit. The new automated sweep can delete the only copy. | Require the shared cleanup proof's reflog and live-worktree checks before removal. Add fixtures for both. | High |
| 4 | Resume write can truncate a linked target | INFERRED | `tools/pc/janitor.ps1:621` | `[IO.File]::WriteAllLines($resumePath, [string[]]$lines)` | If `janitor_resume.txt` is a file symlink, a capped live run can truncate the writable target, including a file outside `voidsworn_test`. The resume value itself only changes where a fresh directory enumeration starts. | Refuse non-plain resume files; write a fresh sibling and atomically replace a validated plain file. | High |
| 5 | Checkout-only cleanup can break a pending ship publish | INFERRED | `docs/RULEBOOK.md:377` | `its Git checkouts (at any depth, links never followed) can still go on their own` | There is no exception for a ship clone still needed for publish. A clean rebuild whose install output matches the shared build can qualify before publish; `tools/pc/jobs/publish_ship.bat:103` requires build tools in that exact clone. | Specify and enforce a published-or-abandoned guard, and align the playbook at lines 69-76. | Medium |
| 6 | Sweep strands a renamed checkout after removal fails | INFERRED | `tools/pc/jobs/opus_job_head.ps1:770` | `if (-not $left.Count) { continue }` | Only original checkout names count. If a lock or read-only descendant leaves just `new.removing`, the sweep never reaches `Complete-Removing`. The same can happen if PowerShell 5.1 cannot traverse a long descendant path after renaming. | Admit matching removal records and tomb folders to the existing validation under the same guards. Dry mode should only report them. | High |
| 7 | The cap does not stop lane and Workhorse checkout work | OBSERVED | `tools/pc/janitor.ps1:580` | `Clear-WorkRunRepos @($runs \| Where-Object { $_.Lane -eq 'work217' })` | Lane and recorded Workhorse passes can start another checkout after the deadline. Both run before the first TEMP cap check. | Check the deadline between checkout candidates in those passes and give each pass a resume cursor. Let the folder in progress finish. | High |
| 8 | Resume lookup uses a different sort order | OBSERVED | `tools/pc/janitor.ps1:481,484` | `Sort-Object Name` and `[StringComparison]::OrdinalIgnoreCase` | Windows PowerShell 5.1 sorts `opus1211_run6` before `opus12110`, but the ordinal lookup judges it greater. A cursor for `opus12110` starts at `opus1211_run6` instead; when only one candidate fits per run, that can repeat indefinitely. | Use one comparison for sorting and lookup, and prefer an exact-name match when the cursor still exists. | High |
| 9 | Dry-run mirror cache omits HEAD | INFERRED | `tools/pc/runner_common.ps1:459` | `'for-each-ref','--format=%(objectname) %(refname)'` | The cache key excludes HEAD, but `rev-list --all` includes it. If a detached mirror HEAD moves away from a commit only it held, the dry run can still call the checkout rebuildable. Live mode bypasses the cache. | Include resolved HEAD or walk only snapshotted ref tips. | High |
| 10 | Playbook promises a broader cap than the code enforces | OBSERVED | `docs/playbooks/pc.md:80` | `once it is spent the run starts no new folder` | Only TEMP and root-job folders honor the documented stop point. | Update the wording to match the corrected cap from finding 7. | High |

**Recommended next step:** Keep PR 1592 off live PC cleanup until the deletion gates are fixed and confirmed on isolated Windows fixtures, then repeat the Board's dry run.

## `tools/pc/janitor.ps1`

**Defects (OBSERVED and INFERRED):** findings 1, 2, 4, 7 and 8. The strict checkout-only path does call the shared proof without salvage, so a modified, unpushed or unarchived superseded checkout stays. It rejects links in a checkout before deleting it. The linked-root guard in finding 2 also belongs before the relay preflight probes for `out_*` or creates a lease; the job head currently only refuses a linked root after that parent-side probe.

## `tools/pc/jobs/opus_job_head.ps1`

**Defects (INFERRED):** findings 3 and 6. The normal relay gate checks the named branch on origin, checks the exact result paths against the mirror tree, and lets `dry` skip the fetch and delete. That gate does not establish the checkout's full Git state. The sweep inherits the job head's link-aware removal and retry code; no Windows live long-path or read-only failure was reproduced here.

## `tools/pc/runner_common.ps1`

**Defect (INFERRED):** finding 9. Ordinary ref pruning between checks changes the dry-run cache key, and live mode reads the commit list fresh per checkout.

## `docs/RULEBOOK.md`

**Defect (INFERRED):** finding 5. Section 3.3 otherwise records the new six-hour checkout-only gate separately from the one-day whole-folder gate and retains the keep list, process and lease checks.

## `docs/playbooks/pc.md`

**Defect (OBSERVED):** finding 10. The relay and dry-mode invocation documented here matches the new entry point.

## `contrib/opus/tools/mirror_cache_1396_tests.js`

**Sound (OBSERVED) for the advertised branch-prune case.** It uses real Git, keeps the checkout unchanged, and checks that the cached and uncached paths both refuse the commit after its sole branch is removed. The full standing-check runner picks it up by filename.

## `contrib/opus/tools/opus_job_head_tests.js`

**Sound (OBSERVED) for the added cases.** The fixtures verify a dry sweep does not fetch, a stale or missing relay cannot unlock a checkout, and a live sweep removes the relayed checkout without removing its result. The Windows run only checks the static contract; the behavioral fixtures are gated to Linux/pwsh. Add the tomb-only and reflog cases when fixing the head.

## `contrib/opus/tools/runner_cleanup_tests.js`

**Sound (OBSERVED) for the added cases.** It checks nested dirty and unpushed repos, an unrelayed master and log, held leases, the keep list, and resume order for TEMP/root. Its zero-cap fixture asserts only `folder time` and relay rows are absent; it would not catch work done before those loops. Extend it with a removable lane/Workhorse candidate at zero cap when fixing the cap.

## Read record

Raw PR blobs, line count and first 40 characters of the last line (or the whole line when shorter):

| File | Lines | Last-line prefix |
|---|---:|---|
| `tools/pc/janitor.ps1` | 636 | `exit 0` |
| `tools/pc/jobs/opus_job_head.ps1` | 894 | `}` |
| `tools/pc/runner_common.ps1` | 1640 | `exit 0` |
| `docs/RULEBOOK.md` | 979 | `draws meshes at full detail. Set: Ryan, ` |
| `docs/playbooks/pc.md` | 86 | ``through `"%JW%" run`. The head and `cont`` |
| `contrib/opus/tools/mirror_cache_1396_tests.js` | 70 | `console.log('PASS mirror_cache_1396_test` |
| `contrib/opus/tools/opus_job_head_tests.js` | 663 | `console.log('PASS ps1 fixtures: current ` |
| `contrib/opus/tools/runner_cleanup_tests.js` | 807 | `}` |

Large shared runner read by range: 1-230, 280-804 and 920-1040, plus the last line. Those ranges cover the cache change, Git and filesystem proof, locks and affected callers. Other files were reviewed at the changed hunks and through the relevant surrounding paths.

## Checks and reach

```text
PASS mirror_cache_1396_tests: the reused mirror commit list ends when a ref is pruned, so a commit only the pruned ref held keeps its checkout
PASS runner cleanup: scratch ownership, failed-run retention, pause, and rebuildable kept checkouts
PASS janitor: dry and live decisions, retained edits and history, issue locks, age, safe paths, and the automatic rate limit
PASS head: tools_live only, new attempt folder, job_wrap init, watchdog hashes, throwaway profile, options hash, safe ships copy, honest tail
PASS template: five fill lines, head from tools_live, every step through the head and job_wrap
PASS ps1: shared mirror lock, full pins, deletes only through the link-safe walk of its own checkouts
SKIP opus job head fixtures: they need pwsh (Linux CI runs them)
PASS PowerShell 5.1 parse: tools/pc/janitor.ps1
PASS PowerShell 5.1 parse: tools/pc/jobs/opus_job_head.ps1
PASS PowerShell 5.1 parse: tools/pc/runner_common.ps1
PASS resume-order reproducer: cursor opus12110 restarts at opus1211_run6
```

`git diff --check origin/main...pr1592` exited 0. The resume reproducer confirms the defect in finding 8. The first runner-cleanup attempt stopped at `git check-ignore` because the extracted fixture tree lacked Git metadata; the rerun with a scratch Git repository and the PR's ignore files passed both rows above.

- Callers: Searched the PR tree for the changed helpers, cache/cursor state and `dropjobs`. Traced the janitor, the existing job tail and publish entry points, and the shared kept-checkout and reuse paths.
- Saves: No game profile or run save reader, writer or format changed in the diff. The new cursor is a local janitor file; the fixtures cover missing and existing cursors and dry-run preservation.
- Twins: No JS or Godot rules or tables changed; no re-export needed.
- UI: No game screen or visual asset changed; no captures needed.
- CI: `.github/workflows/checks.yml:107` runs the full standing pack on Ubuntu. `contrib/opus/tools/run_all_checks.js:157` discovers all three affected `*_tests.js` files automatically; the head's behavioral rows run there with pwsh.

## Not checked

The live PC folder tree and the Board's DRY2 receipt were not used. No live production deletions, long-path or read-only Windows stress run, Linux head fixture run, full standing pack or local Godot parity run. The review is limited to the PR's runner changes and the paths they reach; it made no game changes.
