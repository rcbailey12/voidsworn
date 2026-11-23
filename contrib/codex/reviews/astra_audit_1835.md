# Codex (audit): PR 1835, issue 1662

Send PR 1835 back before the first Windows proof. GitHub reported head `2a0ff9911207ec14ada839daa5e241574b4cc925` on branch `claude/project-thread-wug77i`.

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Proposed fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | BLOCKING. Approval can expire before launch. | OBSERVED | `tools/pc/mission/pc_daemon.js:448` | `const g = gate({ pull, comments, checkRuns, ledger });` | Only the initial list checks the ready label. The fetched PR's labels are ignored. A push, closure or newer go during slot or GPU waits goes unseen before the child starts. The checkout stays pinned to the earlier approved commit. | Check the label on the fetched PR, require the ready-label claim to succeed, then refresh the head, open state, owner go and checks after waiting and immediately before spawn. Release reservations if approval changed. | High |
| 2 | BLOCKING. The process lock can admit two starters. | INFERRED | `tools/pc/mission/pc_daemon.js:401` | `fs.renameSync(tmpFile, file);` | A readable lock with a live PID is refused even with an old heartbeat. Recovery from a dead or unreadable lock has no exclusive owner. Two starters can each pass the read-back at line 403 and enter startup cleanup before either heartbeat detects the other. Initial creation also briefly exposes an empty file. | Hold one OS-backed exclusive lease throughout startup, sweep and work. Fail closed on an unreadable lock. | High |
| 3 | BLOCKING. A child closing can free a slot while a descendant still runs. | INFERRED | `tools/pc/mission/pc_daemon.js:198` | `child.on('close', (code, signal) => finish(code, signal));` | The watchdog checks the direct child's close and stdio. A descendant with separate stdio can outlive it. Cleanup then releases the profile, slot and GPU. Repeated taskkill requests at line 203 also identify their target only by the original numeric PID. | Use the existing Windows Job Object watchdog to track tree membership, confirm zero active processes before cleanup, and retain identified survivors on failure. | High |
| 4 | BLOCKING. Restart clears quarantine before sweeping profiles. | OBSERVED | `tools/pc/mission/pc_daemon.js:378` | `this.quarantined = null;` | Five failed stop requests hold resources for the current daemon. The result JSON records quarantine, but startup never restores it. A replacement daemon sweeps matching profiles at line 624, and the GPU claim at line 342 names only the old daemon PID. A surviving worker can lose both protections. | Persist a hold with the attempt, slot, profile and worker identity. Honor it before any startup sweep or job admission, and register surviving processes with the slot and GPU owners. | High |
| 5 | BLOCKING. Profile cleanup trusts the supplied PC root. | INFERRED | `tools/pc/mission/pc_daemon.js:221` | `const root = path.resolve(slotsRoot)` | Line 617 accepts a relative or unrelated root override. An empty override falls back, but a missing user profile makes that fallback relative. The deletion guard checks slots, profiles and the target, omitting the PC root and its ancestors. A startup sweep can therefore remove matching folders outside the intended physical tree. Profile creation at line 515 follows the path before that guard runs. | Require the configured absolute PC root and validate its physical ancestry before leasing, creating or sweeping. Validate the attempt and the expected leased checkout too. The trimmed slot receipt at line 311 can be empty or relative and send ship copies or the child working directory to the launch directory. | High |
| 6 | BLOCKING. GPU work can start without GPU admission. | OBSERVED | `tools/pc/mission/pc_daemon.js:512` | `if (spec.gpu !== 'none')` | A CPU slot permits graphical Godot. A GPU slot also accepts a claim of none. The game check uses the slot name, and the claim uses the comment's mode and weight. A graphical job can skip clearance, a timing run can share the card and Blender defaults to weight one. A pause or game start during a slot wait is not rechecked before spawn. | Use the existing executable and argument classifier to select mode and weight, enforce the CPU-only contract, and check pause and game state after waiting. Treat an unsuccessful process query as unknown. | High |
| 7 | BLOCKING. An older owner approval can win. | OBSERVED | `tools/pc/mission/pc_daemon.js:124` | `.find(Boolean)` | A newer owner comment beginning with a malformed go header returns null at line 57, so an older valid approval can still start the job. The ascending comments scan also stops at 30 pages even when the last page is full. Its prefix cannot establish the newest approval on a longer thread. | Select the most recent owner go directive before validating its contents. An invalid directive or incomplete comment history should hold the job. | High |
| 8 | SHOULD-FIX. The check name does not identify the required workflow. | INFERRED | `tools/pc/mission/pc_daemon.js:129` | `r.name === CHECK_NAME && r.head_sha === sha` | The SHA, completion status and conclusion are checked. A same-name result from a different check producer or workflow at that SHA also matches. The code never establishes that it came from this repo's checks.yml. | Verify the GitHub Actions workflow identity and its aggregate job for the approved head. Hold when the producer or rerun is ambiguous. | High |
| 9 | SHOULD-FIX. One unreadable saved result can stall the entire queue. | OBSERVED | `tools/pc/mission/pc_daemon.js:560` | `JSON.parse(fs.readFileSync(path.join(e.attempt, 'pc_daemon_result.json'), 'utf8'))` | Normal relay and comment failures leave a result pending and do not rerun the job. A read or parse failure happens outside that retry handler. Redelivery runs before discovery, so the same broken record can stop every poll. A missing result file at line 596 is skipped silently while its ledger key remains consumed. | Write completion metadata atomically. Handle each pending attempt independently and report a missing or unreadable record once while retaining it for recovery. | High |
| 10 | SHOULD-FIX. The Windows self-test stops before the cleanup and recovery groups. | OBSERVED | `tools/pc/mission/pc_daemon_selftest.js:130` | `assert.equal(got, 2, 'the second request ended it')` | Two unchanged Windows runs passed eight groups then failed here with three callbacks. The second callback does call taskkill. Counting callbacks on a 100 ms retry clock also measures when Node receives close. The only grandchild assertion at line 132 explicitly skips Windows. | Use a controlled clock for retry counts. In a separate Windows test, verify the actual process tree ends, then run the remaining groups under the intended PC account. | High |

## What passed and what the tests prove

- **Run gate.** For a stable snapshot, lines 117 to 135 require an open same-repo PR, the configured owner login and association, a full matching SHA, a nonempty reviewer line and a completed successful check. The reviewer line is the owner's attestation. The fake PR at self-test line 21 has no labels and still earns a run verdict. The dry launcher takes one look. Live work requires the Windows live flag.
- **Artoo fixes at 7948168f and 2a0ff991.** The tests exercise an old heartbeat with a live PID, a start without a result, a failed relay followed by delivery without another worker launch, repeated stop requests and a quarantined second poll. The done marker accompanies the relay link, and the delivered ledger entry follows a successful result comment. The lock test uses sequential callers in one process. The quarantine test reuses the same daemon. Neither covers simultaneous startup or recovery after the daemon exits.
- **Windows self-test.** The unchanged script exited 1 twice at line 130. A separate diagnostic run kept every assertion and continued after each failed group. It passed 22 of 23 Windows groups, including the stop-count assertion on that run. The directory symlink fixture failed to create its link with `EPERM`. The 24th group, which checks grandchild death, runs only off Windows. A separate disposable directory-junction check passed: removing the profile kept the target and its marker intact.
- **PowerShell and paths.** Node passes executables and arguments separately to PowerShell 5.1, robocopy and the worker. Placeholder expansion occurs after tokenization, preserving a substituted path with spaces. Literal comment arguments split on whitespace and have no quoting syntax. With the pinned scripts in a temporary tools directory, the real preflight and hashes calls passed at 129- and 327-character result paths. They used Node as the test tool and an empty temporary settings directory.

## Cleanup trace

| Operation | Destination and boundary |
|---|---|
| Profile sweep and end-of-job cleanup | Daemon lines 220 to 239, 467 to 477 and 534 to 537. Only a direct child named `pcd-profile-` plus 32 lowercase hex digits qualifies. The walk uses lstat, unlinks nested links, removes directories after their children, and clears the file write flag before unlinking. The prefix is its only ownership record. See findings 2, 4 and 5. |
| Other direct removal | Lines 249 to 257 unlink the daemon's own random GitHub request JSON in TEMP. The DELETE at line 274 removes one GitHub label. The daemon has no rm or rmSync call. |
| Ship copy and slot reset | Lines 319 to 331 pass two explicit robocopy source/destination pairs with /E and exclusions. Neither call uses /MIR or /PURGE. The slot helper uses a fixed slot name, a lease and a reset lock, saves unproven leftovers, then force-checks out the pin and cleans the slot repo. It preserves the Godot cache and import sidecars. It also removes its own obsolete slot markers and, when moving to another slot, the attempt's slot.txt. |
| Relay and watchdog | The relay removes its own temporary index, skipped-file list and empty work directory. Replacing a previous delivery updates Git's index for the attempt. The daemon's only taskkill at lines 162 to 166 passes a child PID, /T and /F as separate arguments and checks the exit code. Finding 3 covers the missing tree-exit proof. |

## Source record

GitHub's raw contents for all five changed files matched the pinned Git blobs byte for byte. Line counts and the first 40 characters of each final line follow.

| PR file | Lines | Final line begins |
|---|---:|---|
| `tools/pc/mission/pc_daemon.js` | 634 | `module.exports = { parseGo, gate, watch,` |
| `tools/pc/mission/pc_daemon_selftest.js` | 345 | `})().catch(e => { console.error('FAIL: '` |
| `tools/pc/mission/PC_DAEMON.bat` | 13 | `exit /b %RESULT%` |
| `docs/playbooks/pc.md` | 168 | `slot lease, the ships checks, the prefli` |
| `contrib/opus/tools/run_all_checks.js` | 355 | `module.exports = { rowEnv, classifyFindi` |

Supporting paths below are under `tools/pc/`. The cited helpers matched the review base for the slot, preflight, relay and GPU calls.

| Helper | Lines | Relevant lines inspected | Final line begins |
|---|---:|---|---|
| `jobs/opus_job_head.ps1` | 1549 | 75 to 97, 150 to 261, 826 to 848, 853 to 1058, 1105 to 1234, 1507 to 1549 | `}` |
| `runner_common.ps1` | 1778 | 1 to 46, 1644 to 1705, 1765 to 1778 | `exit 0` |
| `relay_push.ps1` | 192 | Attempt checks, relay tree, cleanup and receipt in lines 1 to 192 | `if ($pics.Count -eq 30) { Write-Output '` |
| `gpu_slots.js` | 418 | Claim clearance and owner tracking, classifier and CLI | `module.exports = { Slots, modeFor, weigh` |
| `run_timeout.ps1` | 843 | Windows Job Object and survivor checks, including lines 396 to 446 | `}` |

**Board next step.** Return PR 1835 for the blocking fixes. Recheck the revised head and run the Windows regression tests before queueing its first live proof.

Not checked: a live daemon, a real warm-slot reset, installed ship copies, a Godot or Blender job, GPU timing, a relay upload, GitHub writes or actual loss of files or processes. The first live PC proof is the Board's decision after review. The full standing suite was outside this review-only run.

## Run 2 recheck

**Send PR 1835 back before its first live job.** GitHub reported head `a33b94f4fea8c6a89174488209f20c77e2e4de3b`. The unchanged Windows daemon self-test passed all 25 groups. Its real socket tests cover daemon exclusion. Its fake watchdog can return a clean exit in cases where the Windows helper still has descendants.

### The ten run 1 findings

Paths in the two tables are relative to `tools/pc/`. Line numbers refer to the reviewed head.

| Run 1 | Verdict and severity | Evidence | File:line | Exact quote | What changed, what remains, and proposed fix | Confidence |
|---|---|---|---|---|---|---|
| 1 | PARTLY, BLOCKING. The owner can change a job before launch. | OBSERVED | `mission/pc_daemon.js:510` | `g.spec.job !== spec.job` | The fetched ready label, successful claim and post-slot check now work. The comparison checks only job name and SHA. A newer go with different arguments or script passes, then line 513 builds the old command. The watchdog can also wait for play or GPU admission after this check (`run_timeout.ps1:596,636`). Compare the entire approved instruction at the worker start, after both waits. Abort and release the slot on a change. | High |
| 2 | FIXED, NOTE. One live daemon holds the PC lease. | OBSERVED | `mission/pc_daemon.js:363` | `host: '127.0.0.1', port, exclusive: true` | Live startup waits for the bind before polling at line 632. The Windows self-test refused a second holder and reacquired the port after the holder process exited. | High |
| 3 | PARTLY, BLOCKING. A CPU worker can outlive a successful step. | OBSERVED | `run_timeout.ps1:717` | `(-not $gpuToken -or -not $usage.Active)` | Timeout cleanup checks Job Object membership. On normal exit without a GPU claim, the helper accepts the root exit with active descendants, keeps their spool and returns the root code at lines 720 to 722. It has already cleared kill-on-close at line 214. Daemon lines 195 and 539 accept zero and release the slot. Require an empty Job Object before releasing any daemon slot, including headless jobs. | High |
| 4 | PARTLY, BLOCKING. A recorded quarantine survives restart. An interrupted job can lose its slot. | INFERRED | `jobs/opus_job_head.ps1:1165` | `(Test-SameProcess $owner $ownerStart)` | The restart fixture proves an existing hold stops discovery. The slot holder watches the Node parent (helper lines 871, 906). The daemon writes the hold only after its separate watchdog reports back (daemon lines 516 to 528). If Node exits mid-step, the holder can release the slot while the worker lives. Persist the in-flight attempt and protect the slot until a surviving supervisor or recovery check proves the tree empty. | High |
| 5 | PARTLY, BLOCKING. A well-formed receipt can name the wrong slot. | INFERRED | `mission/pc_daemon.js:267` | `!SLOT_REPO.test(path.basename(slot))` | The live root is fixed, link ancestors are rejected, and the daemon profile sweep is gone. The receipt can still name another existing plain slot. The helper records the actual slot and lease token in `slot.txt` at line 924. The daemon uses the receipt for copies, launch and quarantine, then releases the slot belonging to the attempt. Match the receipt to the held lease and requested kind before using it. Test with two existing slots. | High |
| 6 | PARTLY, BLOCKING. GPU admission and the game check still have gaps. | OBSERVED | `mission/pc_daemon.js:97` | `kv.flow === 'blender' ? 'none' : 'auto'` | The installed classifier now handles normal graphical Godot, timing runs and Blender weights. A CPU-slot Blender request silently defaults to no claim, even though the script's GPU use is unknown. Node checks for Voidsworn before starting PowerShell. The helper treats a failed game query as clear, stops waiting after eight hours, and can then wait for the GPU without rechecking play (`run_timeout.ps1:583,596,636`). Require an explicit CPU-only declaration for Blender and a successful game check at actual admission. | High |
| 7 | FIXED, NOTE. The most recent owner go decides. | OBSERVED | `mission/pc_daemon.js:142` | `const go = parseGo(newest.body);` | Lines 135 and 139 to 145 refuse incomplete comment history and select the newest owner directive before parsing its header. The Windows tests cover an out-of-order list, a malformed newer header and the full-page cap. | High |
| 8 | PARTLY, SHOULD-FIX. Workflow identity is checked but a previous run can still qualify. | INFERRED | `mission/pc_daemon.js:147` | `w.path === CHECKS_WORKFLOW && w.head_sha === sha` | The producer, path, suite and SHA now match. The suite set includes older runs and omits run status and attempt. The aggregate depends on upstream jobs (`.github/workflows/checks.yml:338`), so a fresh run that has yet to start its aggregate can leave an older success as the newest started check. Require the latest applicable workflow run and attempt to finish successfully and use its aggregate. | High |
| 9 | FIXED, NOTE. A missing or unreadable result no longer stalls the queue. | OBSERVED | `mission/pc_daemon.js:387` | `fs.renameSync(tmp, file);` | The writer publishes complete JSON by rename. Lines 564 to 572 report a bad record once per daemon process, and line 608 isolates errors by attempt. The Windows test corrupted one saved record and observed the next job run. The JSON and ledger still have separate writes at lines 551 to 552. Recovery from a crash between them is outside this fix. | High |
| 10 | PARTLY, SHOULD-FIX. The Windows suite now finishes but does not prove worker-tree cleanup. | OBSERVED | `mission/pc_daemon_selftest.js:144` | `runStep: async o => { seen.push(o);` | All 25 groups ran. The flaky retry-count assertion is gone. The tests use real processes for the Node backstop and lease, but empty PowerShell files and a fake step for the watchdog contract. The quarantine fixture supplies a failure message. Run a Windows integration test through the real daemon adapter and watchdog, asserting that the slot remains held until the last CPU descendant exits. | High |

### Additional findings introduced by the fix

| # | Finding | Evidence | File:line | Exact quote | Why it matters and proposed fix | Confidence |
|---|---|---|---|---|---|---|
| A | BLOCKING. Blender loses its disposable profile. | OBSERVED | `run_timeout.ps1:454` | `$app.FileVersionInfo.FileDescription -notlike 'Godot Engine*'` | The previous daemon redirected both application-data directories for both flows. Daemon line 515 now passes the parent environment. The watchdog returns without making a profile for Blender, and its launcher passes that environment through at line 527. Blender therefore receives Ryan's ordinary profile paths. The after-job hashes cover two Godot option files. Give Blender its own user directories and verify them with a stand-in process before accepting the run. | High |
| B | BLOCKING. The watchdog's profile cleanup moved outside the specified slots folder. | OBSERVED | `run_timeout.ps1:464` | `[IO.Path]::GetTempPath()` | The helper uses inherited runner scratch or makes a TEMP folder, creates the Godot profile beneath it, then removes it at line 517. Its walk handles nested links separately and targets its own profile. Issue 1662 specifically confines daemon profile removal to slots. Supply an owned scratch root inside the held slot's profile area and test the actual created and removed paths. | High |
| C | SHOULD-FIX. An unavailable GitHub check consumes a job that never started. | OBSERVED | `mission/pc_daemon.js:498` | `failed.push(name)` | If the new lookup at line 509 throws, the step wrapper records a failure. The watchdog is skipped, the aborted branch at line 540 is missed, and line 552 records a terminal FAILED result. Restoring access and reapproving the same job and SHA cannot retry it. Record an unverified prelaunch check as aborted, release the slot, and keep the job eligible. | High |
| D | SHOULD-FIX. The new watchdog entry point checks only that the helper exists. | OBSERVED | `mission/pc_daemon.js:283` | `!fs.existsSync(path.join(pc, f))` | Line 344 resolves the current tools version again at launch. A refresh can change it after preflight, and the daemon does not compare the script to the installed hashes. PC harness rule 3.5 calls for the strict watchdog hash check. Use the existing bundle verifier (`jobs/opus_job_head.ps1:1073` through 1087) and run the verified version for the attempt. | High |
| E | SHOULD-FIX. Quoting can merge two Windows arguments. | OBSERVED | `mission/pc_daemon.js:339` | `const q = a => /\s/.test(a)` | The new adapter joins arguments into a single Windows command line. Through the real helper, a directory argument with spaces and a trailing backslash absorbed the next argument. The child exited zero with one incorrect argument. Use Windows argument quoting that preserves trailing backslashes before a closing quote. Check the argument array received by the child. | High |
| F | SHOULD-FIX. A job's log can trigger a persistent quarantine. | OBSERVED | `mission/pc_daemon.js:193` | `/KILL FAILED/.test(out)` | The watchdog copies child output into its own output stream (`run_timeout.ps1:297`). The daemon scans that mixed stream before checking exit status. An ordinary diagnostic that quotes a prior failure can therefore set both holds despite successful completion. Return tree status through a separate watchdog-owned record. Keep child logs for diagnosis. | High |

### Windows checks and cleanup

- The unchanged self-test ran on Windows with Node 22.11.0. All 25 groups passed. The path group exercised an actual directory junction. The backstop group observed that its direct test child was still alive and then stopped it.
- Two CPU-only argument checks used the reviewed adapter, Windows PowerShell and the pinned watchdog to start a Node argument printer under temporary paths. A 136-character argument and a 348-character argument containing spaces both arrived intact. A third check, with the trailing separator in finding E, failed the argument comparison even though the child returned zero.
- The pinned GitHub Actions run reported success for both the standing checks and the aggregate. The aggregate's suite ID matched the workflow's suite ID, 122317796651. [Workflow run 45201679061](https://github.com/rcbailey12/voidsworn/actions/runs/45201679061)
- Direct Node cleanup is limited to its temporary GitHub request file (line 218). The two robocopy calls use `/E` and neither uses `/MIR` or `/PURGE` (lines 321 to 330). The slot helper still checks its lease, saves unproven leftovers and limits its forced checkout and clean to the slot repo. The watchdog removes its own profile, marker and spool files (`run_timeout.ps1:509` to 524 and 765 to 773). The relay still removes its temporary index, skipped-file list and empty work directory. Finding B covers the change in profile location.

### Source record

The raw GitHub content matched the pinned Git blobs byte for byte for the five PR files and the supporting files below. The last column gives the exact first 40 characters of the final line, or the whole line if shorter.

| File | Lines | Final line begins |
|---|---:|---|
| `tools/pc/mission/pc_daemon.js` | 642 | `  checkRoot, checkSlotRepo, plainChain, ` |
| `tools/pc/mission/pc_daemon_selftest.js` | 412 | `})().catch(e => { console.error('FAIL: '` |
| `tools/pc/mission/PC_DAEMON.bat` | 13 | `exit /b %RESULT%` |
| `docs/playbooks/pc.md` | 175 | `preflight, the watchdog and the relay; l` |
| `contrib/opus/tools/run_all_checks.js` | 355 | `module.exports = { rowEnv, classifyFindi` |
| `tools/pc/run_timeout.ps1` | 843 | `}` |
| `tools/pc/gpu_slots.js` | 418 | `module.exports = { Slots, modeFor, weigh` |
| `tools/pc/jobs/opus_job_head.ps1` | 1549 | `}` |
| `tools/pc/runner_common.ps1` | 1778 | `exit 0` |
| `tools/pc/tmo.bat` | 42 | `exit /b 125` |
| `tools/pc/relay_push.ps1` | 192 | `if ($pics.Count -eq 30) { Write-Output '` |
| `.github/workflows/checks.yml` | 350 | `          echo "PASS" \| tee -a "$GITHUB_` |

For the large PowerShell helpers, the slot review covered `opus_job_head.ps1` lines 862 to 1058, 1063 to 1234 and 1541 to 1549. The preflight review covered `runner_common.ps1` lines 1644 to 1705 and its exit at 1778.

**Board decision.** Return the PR. Recheck the corrected launch gate, profile boundaries and slot lifetime on Windows before queueing a live proof.

Not checked: a live daemon, Ryan's installed tools bundle, a real slot reset, Godot or Blender, GPU admission under load, a live relay or any GitHub write. The full standing suite result above is from CI. Locally, this review ran the daemon suite and the focused CPU argument checks.

## Run 3 recheck

**Return PR 1835 before its first live job.** GitHub reported head `ae3043786ee192abf6c415a76f3af366ce337b41` on `claude/project-thread-wug77i`. The Windows test now proves the matching watchdog waits for a CPU descendant. Three conditions still need a fix before launch. The installed watchdog must understand the new settings, the slot must still be held when its marker is removed, and the final play check must recognize a windowed Godot session.

### Run 2 verdicts

Paths in the evidence tables start at `tools/pc/`. Each verdict describes the pinned code. The watchdog verdicts assume the daemon is paired with the reviewed watchdog. Finding G covers how the live launcher can select an older one.

| Item | Verdict | Evidence | File:line | Exact quote | Result or remaining fix | Confidence |
|---|---|---|---|---|---|---|
| 1 | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:536` | `JSON.stringify(g.spec) !== JSON.stringify(spec)` | The daemon compares the entire parsed instruction. The watchdog calls the same check after the play wait and GPU admission at `run_timeout.ps1:704`. A changed command or an unavailable approval stops the start. | High |
| 3 | FIXED, NOTE | OBSERVED | `run_timeout.ps1:785` | `-not ($gpuToken -or $waitTree) -or -not $usage.Active` | With the daemon's tree wait set, a normal CPU exit requires zero active Job Object members and drained output. The Windows test saw the descendant's final file before the watchdog returned. A record without proof of an empty tree triggers quarantine. | High |
| 4 | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:385` | `fs.writeFileSync(marker, text, { flag: 'wx' });` | The slot gets its hold before the watchdog starts. The shared slot helper skips it at `jobs/opus_job_head.ps1:914`. A replacement daemon detects the unfinished attempt and holds new starts at `mission/pc_daemon.js:551`. Finding H covers what happens after Board clearance. | High |
| 5 | PARTLY, BLOCKING | OBSERVED | `mission/pc_daemon.js:394` | `fs.unlinkSync(f.marker);` | Lines 365 to 373 check slot path, kind, attempt and token, then accept a saved holder message. The two-slot test rejects the wrong receipt. The daemon omits the live PID, start time and OS lock checks, including at removal. Use the slot helper's live proof for creation and removal. See the marker check below. | High |
| 6 | PARTLY, BLOCKING | OBSERVED | `mission/pc_daemon.js:436` | `IMAGENAME eq Voidsworn*` | CPU Blender now requires an explicit `gpu: none`. The final check runs after GPU admission, but its process filter misses a windowed Godot play session that starts during that wait. The watchdog recognizes both executable families at `run_timeout.ps1:625`. Use that full play check after the GitHub reads and hold on a failed process query. | High |
| 8 | PARTLY, SHOULD-FIX | OBSERVED | `mission/pc_daemon.js:162` | `r.check_suite?.id === wr.check_suite_id` | The latest workflow run must complete successfully. An older green run can no longer qualify while a newer one is pending. The aggregate is selected by suite and start time. The test uses two different suites and sets every run attempt to 1 at `mission/pc_daemon_selftest.js:28`. Verify the aggregate's job in the chosen run and attempt, including a rerun of the same workflow run. | High |
| 10 | PARTLY, SHOULD-FIX | OBSERVED | `mission/pc_daemon_selftest.js:588` | `assert.ok(fs.existsSync(later),` | The new group runs real PowerShell, the Node stand-in and its descendant. It checks tree exit, arguments, profile cleanup and a refused start. Line 567 makes a scratch directory without taking a lease. The separate marker test uses a saved holder message. Add a real lease to the Windows fixture and assert that it stays held until the descendant exits. | High |
| A | FIXED, NOTE | OBSERVED | `run_timeout.ps1:548` | `$set["BLENDER_USER_$n"] = Join-Path $Profile ('blender\' + $n.ToLowerInvariant())` | The profile applies to Blender too. The stand-in saw both application-data paths and the Blender config path inside its disposable profile. | High |
| B | FIXED, NOTE | OBSERVED | `run_timeout.ps1:468` | `$scratch = Join-Path (Get-ScratchParent)` | The adapter clears inherited runner scratch and supplies the slot's checked scratch directory. The profile and child logs were created underneath it, and the real Windows cleanup left it empty. | High |
| C | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:673` | `this.note(sha, spec.job, n, 'aborted', attempt);` | A failed GitHub read during recheck becomes an abort. The daemon lets the slot go and keeps the same SHA and job eligible when the Board restores the ready label. | High |
| D | PARTLY, SHOULD-FIX | OBSERVED | `mission/pc_daemon.js:660` | `} finally { this.tools.unpin(); }` | The watchdog now uses the version whose four bundle hashes were checked. The daemon drops that pin before the after-job options hash, slot release and first relay. A refresh can switch helpers during the same attempt. The after-job hash is attempted even when verification failed. Retain the verified path through completion and skip that helper when verification fails. | High |
| E | FIXED, NOTE | OBSERVED | `mission/pc_daemon_selftest.js:591` | `assert.deepEqual(seen.argv, [spaced, '--next', 'plain'],` | The real child received the directory with a space and trailing backslash as one argument, followed by two distinct arguments. | High |
| F | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:211` | `rec.treeEmpty !== true` | The daemon reads tree status from the separate watchdog record. A quoted kill failure in child output no longer triggers quarantine. A missing record still holds the slot. | High |

### Additional findings introduced by the fix

| # | Finding | Evidence | File:line | Exact quote | Why it matters and proposed fix | Confidence |
|---|---|---|---|---|---|---|
| G | BLOCKING. A valid older watchdog can start the job. | INFERRED | `mission/pc_daemon.js:337` | `path.join(path.dirname(pc), 'hashes.txt')` | The launcher at `mission/PC_DAEMON.bat:10` starts the checkout's daemon. On this PC, installed bundle `b627b4e9b919` matched its manifest for all four checked files. Its watchdog matched main's Git blob `b507727f5` and lacks the new settings. That pairing can start Blender with the ordinary profile and skip the final gate. Line 210 discovers the missing record after the command returns. Require the verified helper to report the required capabilities before launching a job. | High |
| H | SHOULD-FIX. Clearing an interrupted attempt's holds cannot resume the daemon by itself. | INFERRED | `mission/pc_daemon.js:551` | `if (lost.length && !this.held())` | Each poll rediscovers the same unmatched start in the ledger. After the Board verifies the tree and removes both holds as documented, the next poll recreates the daemon hold. Record the Board's clearance against that specific attempt so future polls can resume. | High |
| I | SHOULD-FIX. Scratch setup can strand a slot before a worker starts. | INFERRED | `mission/pc_daemon.js:387` | `fs.mkdirSync(scratch, { recursive: true });` | The marker already exists. If scratch creation or its path check throws, the caller at line 629 never receives the marker. It releases the lease and the shared helper skips the slot indefinitely. Prepare and validate scratch before publishing the marker. | High |
| J | NOTE. Library mode changes caller state with all step settings unset. | OBSERVED | `run_timeout.ps1:570` | `$script:rec = [ordered]@{` | Line 571 returns from library mode after this assignment. A dot-sourcing caller's existing `$rec` was overwritten in the Windows comparison. Keep per-step bookkeeping out of library initialization. | High |

### Shared watchdog and marker check

The direct diff of `run_timeout.ps1` against main `d6d74b2144c680fa1219498ad768b245d6d150d9` adds 85 lines and removes 11. A search of the pinned tree found one production writer of the six settings, the daemon adapter at lines 425 to 426. The watchdog reads and clears them at lines 574 to 581. `PC_STEP_GATE_JS` and `PC_STEP_GATE_ARG` feed the launch check at line 704. `PC_STEP_WAIT_TREE` controls the exit test at line 785, `PC_STEP_SCRATCH_PARENT` controls the scratch location at line 491, `PC_STEP_PROFILE_ANY` selects the extra profile handling at lines 455 and 545, and `PC_STEP_RECORD` controls the write at line 914. With them unset, the scratch parent falls back to TEMP, ordinary Godot profiling still applies, CPU steps retain their prior exit condition, and no daemon gate or record runs.

The diff also changes behavior for a caller that dot-sources the watchdog with `-LibraryOnly`. A Windows comparison with all six settings unset found that main preserved a caller variable named `$rec`, while the PR replaced it with an `OrderedDictionary` before returning (J). For normal invocations, record bookkeeping runs unconditionally, and lines 544 to 557 use .NET to save, set and restore APPDATA and LOCALAPPDATA. I found no default change to job output, exit, profile destination or cleanup in the diff or the ordinary CPU comparison below.

The daemon constructs one slot filename, `hold.txt`, and uses exclusive creation. It records the attempt and token and compares the full text before unlinking. A marker that already differs at comparison time is kept. The compare and unlink are separate operations, so a Board edit between them is unprotected. A missing record or unproven tree keeps the hold. The production path calls cleanup before its own slot release. **The held-slot requirement is still unproven.** The existing `Test-SlotHeld` checks PID and start time, current owner token and a locked lease file at `jobs/opus_job_head.ps1:939` to 945. The daemon checks only receipt files and does not repeat the live or directory checks at unlink. The Windows marker fixture at `mission/pc_daemon_selftest.js:228` writes `held 3 4`; it successfully clears a marker without taking an OS lease. The separate TEMP request-file unlink at `mission/pc_daemon.js:251` predates this fix.

### Windows checks

- `node tools/pc/mission/pc_daemon_selftest.js` passed **29 of 29 groups** on Windows with Node 22.11.0. Both real watchdog invocations ran, one admitting the stand-in and one refusing it.
- `node tools/pc/runner_selftest.js` reported **139 checks passed, exit 1** with the standing checks' environment filter. The delivery-cleanup case at line 1035 expected a successful runner exit. Its DeepSeek stand-in had already exited with Windows status `0xC0000142` during preflight. An earlier invocation inherited the lane's `CODEX_MODEL` and failed the default-model assertion at line 1202. That assertion passed in the filtered run.
- A focused retry selected only the existing delivery-cleanup group in a TEMP copy of the suite. All **6 of 6 cases** passed, including the failed-checks case. The four shared startup checks also passed. The full runner result above remains a failure.
- With all six daemon settings unset, the same CPU child ran under main and the PR watchdog. Both preserved the inherited profile paths, forwarded the same output, returned the child's exit code 17 and reported background output continuing in a TEMP spool. Both comparisons passed.

### Source record

GitHub's file contents matched the local Git blobs byte for byte at the review pin. The final column gives up to 40 characters of the final line. The large slot helper was consulted at lines 856 to 980, 1061 to 1090 and 1141 to 1175. For the large runner self-test, the reads covered lines 1 to 155, 1010 to 1049, 1179 to 1221 and 1452 to 1536, plus the complete test execution.

| File | Lines | Final line begins |
|---|---:|---|
| `tools/pc/mission/pc_daemon.js` | 784 | `  expectMissing, checkRoot, checkSlotRep` |
| `tools/pc/mission/pc_daemon_selftest.js` | 608 | `})().catch(e => { console.error('FAIL: '` |
| `tools/pc/run_timeout.ps1` | 917 | `}` |
| `tools/pc/mission/PC_DAEMON.bat` | 13 | `exit /b %RESULT%` |
| `docs/playbooks/pc.md` | 190 | `Node and retire its wrapper. The selftes` |
| `contrib/opus/tools/run_all_checks.js` | 355 | `module.exports = { rowEnv, classifyFindi` |
| `tools/pc/jobs/opus_job_head.ps1` | 1549 | `}` |
| `tools/pc/runner_selftest.js` | 1536 | `} })();` |
| `tools/pc/runner_selftest.bat` | 6 | `exit /b %ERRORLEVEL%` |

**Board decision.** Send PR 1835 back for the watchdog compatibility check, live slot proof and complete play check. Recheck those fixes on Windows before the first live job.

Not checked: a live daemon or leased production slot, execution of the installed bundle, an actual play session, Blender or Godot, GPU contention, a relay upload, GitHub writes, or the full standing suite. The two requested suites used local fixtures. The lane verification issue tracked in #1854 is separate from PR 1835.
