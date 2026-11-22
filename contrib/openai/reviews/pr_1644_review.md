# PR 1644 review: checkout cleanup after relay

Reviewed `e7be08e33c` against `origin/main` at `8a3c5d026f`, merge base `e0c8b4076e`. Verdicts use line numbers from the PR tip.

**Hold before enabling live cleanup.** The waiter inherits a resume path that deletes before the relay and mirror gates, and its new active-use and path checks do not fully fence the removal.

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | A resumed removal bypasses fresh relay proof and the mirror lock | OBSERVED | `tools/pc/jobs/opus_job_head.ps1:516` | `@(Complete-Removing $attempt $listed)` | The new automatic caller inherits this path. A relay tip merely needs to exist before `Drop-Attempt` can finish a recorded tomb. It finishes it before the mirror lock at line 524 and before the proof at line 531. If the branch was rewritten after the original rename, its current contents need not match the results. The record names a commit and folder, not a verified relay. | Lock and reprove the relay before completing a tomb, even if only the tomb remains. Tie the tomb record to the listed pin and test a moved relay with different bytes. | High |
| 2 | Active-use guard misses job-folder commands and can go stale before removal | INFERRED | `tools/pc/jobs/opus_job_head.ps1:599-600,869` | `$proc.Line -notmatch '\bdropwait\b'` | The scan checks only the attempt path and exempts any command containing `dropwait`. The Windows probe confirmed that a command naming only the parent job is missed; the janitor checks that path. A queued consumer can start after the scan but before the leases are taken or during the mirror wait. The leases cover cooperating runners, but `opus_job_head.bat init` does not take that job lease. | Share the janitor's parent-path check after taking the locks, identify waiter processes narrowly, and recheck just before the rename. Require any queued consumer of an existing attempt to reserve the same lease from queue admission through use. | High |
| 3 | The existing tail cleanup can race the waiter | INFERRED | `tools/pc/jobs/opus_job_head.ps1:817,823` | `Drop-Attempt $sib.FullName` | A later tail still sweeps earlier attempts without the waiter's job lease or process and keep-list checks. The mirror lock serializes fresh checkout drops, but it does not cover the earlier tomb path in finding 1. Both callers can reach the same removal record. | Make every caller use the same locked, guarded removal path, including sibling sweeps and resumed removals. Revalidate the candidate under the locks. | High |
| 4 | Result-root junctions are followed during proof | OBSERVED | `tools/pc/jobs/opus_job_head.ps1:477,480,522` | `$pending.Push((Get-Item -LiteralPath $d -Force))` | The reused proof checks reparse points on the entries inside each result tree, but pushes a root `out_*` directory before checking that root. The Windows dry probe confirmed that it reads files through a junction at the root, so another folder's bytes can stand in for the attempt's results. The deletion walk itself removes static child junctions as links. | Require each result root to be a plain in-attempt directory before hashing it. Add a junction-at-result-root refusal fixture. | High |
| 5 | New log and lock opens are not confined to plain files | OBSERVED | `tools/pc/jobs/opus_job_head.ps1:844,872,877` | `Start-Transcript -LiteralPath $env:OJ_DROPWAIT_LOG -Append` | The log path is taken from the environment, and even the standard path can already be a link. A transcript can append outside the job. The raw lock opens also skip the janitor's plain-file check. The dry path can start the transcript too, though it does not delete. | Derive the log from a validated job path, create a new plain log without following links, and reuse the janitor's checked lock opener. Skip log writes in dry mode. | High |
| 6 | The deadline does not bound Git or a proof in progress | OBSERVED | `tools/pc/jobs/opus_job_head.ps1:861,891` | `if ($clock.Elapsed.TotalSeconds + $poll -gt $limit)` | The time check comes only after synchronous `ls-remote` and proof. A stuck network or credential prompt can strand a hidden process indefinitely. A poll near the end can also enter a 30-minute mirror wait while holding the job and issue locks. Failed attempts with listed checkouts poll too, because the PASS check is inside `Drop-Attempt`. | Skip failed and unfinished attempts before polling. Set a deadline before work starts, disable prompts, bound Git and lock waits by the remaining time, and let only an already-started removal finish safely. | High |
| 7 | A transient proof failure can stall cleanup on an unchanged relay | INFERRED | `tools/pc/jobs/opus_job_head.ps1:868,886` | `$seen = $tip; $retry = $false` | The first poll can see origin, then a second `ls-remote` or mirror fetch inside the proof can fail. Those failures do not match the retry strings. The same tip will then be ignored, and a janitor scan can see the sleeping waiter naming the job and skip the job too (`tools/pc/janitor.ps1:150-156,496`). | Return explicit proof outcomes and retry transient read, fetch and lock failures. Do not let an idle waiter prevent the janitor from taking the shared cleanup locks. | High |
| 8 | The tail reports success when the launcher fails | OBSERVED | `tools/pc/jobs/opus_job_head.bat:185-186` | `if defined OJ_WAIT` | Launcher output is discarded; this condition is set before launch and the next line writes a success message regardless of the exit code. The parent deliberately returns the job's result, so launch failure is otherwise invisible. | Make launch errors terminating, log launch success or failure separately, and keep the original job exit code. | High |
| 9 | The new fixtures do not exercise the Windows handoff or relayed dry path | OBSERVED | `contrib/opus/tools/opus_job_head_tests.js:100,458-459,470` | `if (windows \|\| spawnSync` | Windows runs static assertions only, Linux directly invokes the script, and the dry waiter fixture has no relay. The scope assertion checks a different job, not a relayed sibling of the same job. | Add an isolated Windows launcher fixture and test dry with a matching relay, a relayed sibling, and the lease/mirror and tomb boundaries. | High |
| 10 | The playbook promises safeguards the code does not provide | OBSERVED | `docs/playbooks/pc.md:70-74` | `every 5 minutes for up to 12 hours` | The time bound does not cover the blocking calls in finding 6. The claimed same proof for the attempt has the tomb exception in finding 1. | Fix the gates and bound first, then describe the actual deadline, resume proof and dry behavior. | High |

**Recommended next step:** Keep the waiter off live PC jobs until the shared removal path is fixed, then run a Windows dry pass and isolated Windows deletion fixtures.

## `contrib/opus/tools/opus_job_head_tests.js`

**OBSERVED: Coverage defect.** Finding 9. The Windows launcher is only checked as text. The executable fixture skips Windows and calls the PowerShell file directly on Linux, so it cannot prove the batch command detaches, passes paths with spaces, or releases inherited handles. The isolated launcher probe below did confirm the quoted arguments reach a child.

## `docs/playbooks/pc.md`

**OBSERVED: Documentation defect.** Finding 10. The documented opt-out is correctly limited to the waiter, and the command and normal log location match the batch tail.

## `tools/pc/jobs/opus_job_head.bat`

**OBSERVED: Launch reporting defect.** Finding 8. `OJ_KEEP_CHECKOUTS=1` gates both tail cleanup calls, and `OJ_NO_DROPWAIT=1` gates only the waiter.

## `tools/pc/jobs/opus_job_head.ps1`

**OBSERVED and INFERRED: Safety and reliability defects.** Findings 1-7. The normal, fresh-drop path compares local Git blob hashes at the expected relay paths, confirms the GitHub ref matches the mirror tip, and holds the shared mirror lock through the history checks and deletion. Branch appearance alone does not authorize a fresh drop. The existing listed-over-10-MB exception leaves those files in the results folder; it is not byte proof for those files. The waiter calls only the named attempt. Dry skips both file-removal paths, lock creation and fetching; it can still write the transcript noted above. `Get-ListedLeft` preserves the janitor's existing checkout and tomb selection.

## Read record

Raw Git blobs from the reviewed PR. The last column shows the first 40 characters of the final line, or the whole line if shorter.

| File | Lines | Last-line prefix |
|---|---:|---|
| `contrib/opus/tools/opus_job_head_tests.js` | 748 | `console.log('PASS ps1 fixtures: current ` |
| `docs/playbooks/pc.md` | 98 | ``through `"%JW%" run`. The head and `cont`` |
| `tools/pc/jobs/opus_job_head.bat` | 187 | `exit /b %OJ_RC%` |
| `tools/pc/jobs/opus_job_head.ps1` | 1044 | `}` |

The PowerShell blob exceeds 60 KB. Read ranges: 1-66 (contract), 67-229 (setup and salvage), 230-620 (removal, mirror and relay proof), 621-798 (Git state and other actions), 799-925 (cleanup actions), 926-1044 (ship paths and end).

## Checks and reach

```text
PASS head: tools_live only, new attempt folder, job_wrap init, watchdog hashes, throwaway profile, options hash, safe ships copy, honest tail
PASS template: five fill lines, head from tools_live, every step through the head and job_wrap
PASS ps1: shared mirror lock, full pins, deletes only through the link-safe walk of its own checkouts
SKIP opus job head fixtures: they need pwsh (Linux CI runs them)
PASS Windows PowerShell 5.1 parse: PR 1644 job head
PASS Windows batch launcher: quoted script and attempt paths reach the hidden child
PASS Windows dry waiter: relay exists on fixture origin, no fetch, lease creation, or removal
PASS Windows process-guard probe: attempt-path command holds; parent job-path command is missed
PASS Windows junction probe: relay proof reads through a junction at the result root
PASS Windows resume probe: fixture tomb is removed with a held mirror lock and missing relay bytes
```

The last three probe passes reproduce the defects. The first launcher probe did not find its fixture batch file by bare name; using `.\only-launch.bat` fixed the probe. `git diff --check origin/main...pr1644` passed; the report whitespace check printed no errors.

- Callers: Searched the PR tree for the waiter, shared helpers and settings. Traced the batch tail, sibling `dropcheckouts` and janitor `dropjobs` paths, and the runner lease and mirror lock conventions.
- Saves: The four changed files contain no game profile or run save reader, writer, or format change. The waiter reads existing attempt records; no save migration is involved.
- Twins: No JS or Godot rules or tables changed; no re-export or oracle copy check needed.
- UI: No game screens changed; no captures needed. The affected user-facing tool surfaces are the tail status and waiter transcript.
- CI: `.github/workflows/checks.yml:107` runs the full Ubuntu standing pack; `contrib/opus/tools/run_all_checks.js:153-157` discovers this existing `*_tests.js` file. Linux runs the PowerShell fixtures. The code PR also triggers the Godot jobs; a docs-only review delivery skips those jobs.

## Not checked

No production cleanup or PC queue run. The production inherited handles, full 12-hour timeout, and a real queue admission race were not exercised. Linux behavioral fixtures were skipped by the Windows test; local standing checks and Godot parity were left to the runner for this review-only delivery. No GPU or visual work was needed.
