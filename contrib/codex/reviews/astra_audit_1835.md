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

## Run 4 recheck

**Send PR 1835 back before its first live job.** GitHub reported head `2e000b614b25e87c4e9faf80f8610ce00952bf80`. All 30 daemon groups and all 141 shared runner checks passed on Windows. Two run 3 items still block a live job. Item 5 leaves gaps when publishing or clearing a slot hold. Item 6 misses Ryan's compatibility play launcher.

The comparison starts at the run 3 head `ae304378` and includes `ddf4b937` and `2e000b61`. Paths in the verdict tables are relative to `tools/pc/`.

### Blocking

| Item | Verdict | Evidence | File:line | Exact quote | Consequence and requested fix | Confidence |
|---|---|---|---|---|---|---|
| 6 | PARTLY, BLOCKING | OBSERVED | `mission/pc_daemon.js:478` | `return !/--?\w/.test(rest);` | The final check now runs after the GitHub reads, detects ordinary windowed play and holds on a failed query. The shipped compatibility launcher passes a renderer flag at `play_godot_safe.bat:3`. A Windows call to the classifier returned false for both resulting play commands, the export and windowed Godot. The watchdog uses the same flag rule at `run_timeout.ps1:637`. Recognize both play launchers in both checks and add their actual arguments to the fixture. | High |
| 5, cleanup | PARTLY, BLOCKING | INFERRED | `mission/pc_daemon.js:415` | `fs.renameSync(f.marker, aside);` | The lease is checked at line 413. Cleanup then moves even a Board-edited hold out of `hold.txt` before reading it. If the read or restoration fails, line 703 logs that the marker stays and line 716 releases the slot. A crash in that window also leaves only the renamed file. The allocator at `jobs/opus_job_head.ps1:914` checks only `hold.txt`. Keep the slot unavailable while either file awaits resolution, and preserve any newer Board hold during restoration. | High |
| 5, creation | PARTLY, BLOCKING | OBSERVED | `mission/pc_daemon.js:406` | `fs.writeFileSync(marker, text, { flag: 'wx' });` | The daemon proves the lease at line 668. Ship copying and the GitHub recheck run before it publishes the marker at line 675. Publication and the watchdog's final gate accept the earlier proof even if the lease was released in between. The helper also protects a living, unreleased owner at `jobs/opus_job_head.ps1:1154`. Require the same live slot and token at publication and before launch. Cover a release before publication as well as the existing release before removal. | High |

### High / Medium

| Item | Verdict | Evidence | File:line | Exact quote | Consequence and requested fix | Confidence |
|---|---|---|---|---|---|---|
| D | PARTLY, SHOULD-FIX, High | OBSERVED | `mission/pc_daemon.js:757` | `this.tools.relay(e.job, e.attempt, st)` | A successful pin now lasts through the options check, slot release and first relay. A failed pin skips the options hash at line 710 but still reaches delivery at line 732. With no pin, the relay resolves the current tools directory again. Keep the failed result locally until a verified tools version is available for delivery. | High |
| H | PARTLY, SHOULD-FIX, Medium | INFERRED | `mission/pc_daemon.js:808` | `const d = new Daemon({ vt, gh: null, tools: null });` | Board clearance now persists for the selected attempt. The clearance command also treats an active attempt's unmatched start as interrupted, because this new process has an empty set of attempts it owns. A mistaken clearance can suppress recovery if the real daemon later stops. Require a recorded interruption for that attempt before accepting clearance. | High |

### Ready / Verified

| Item | Verdict | Evidence | File:line | Exact quote | What passed | Confidence |
|---|---|---|---|---|---|---|
| G | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:343` | `/^# pc-step-settings: 1\r?$/m.test` | After the bundle hash check, the pin requires the watchdog's version marker. The old-watchdog fixture refused to pin. The matching watchdog at line 575 carries the marker and ran in the Windows group. | High |
| 8 | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:166` | `j.run_id === wr.id` | The daemon fetches jobs for the chosen run and attempt, then checks the aggregate name, run ID, attempt, SHA, status and conclusion. The same-run fixture rejected attempt 1's green job for attempt 2. The live jobs endpoint for run 45243420809 returned the expected ID, attempt and SHA fields. | High |
| 10 | FIXED, NOTE | OBSERVED | `mission/pc_daemon_selftest.js:666` | `tools.clearInFlight(flight);` | A real PowerShell holder locked the temporary CPU slot. The watchdog waited for the stand-in's descendant, removed its profile and scratch contents, then the helper proved the lease still live and cleared the marker. After the holder exited, a second removal was refused and its marker survived. | High |
| I | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:401` | `plainChain(scratch);` | Scratch setup and validation finish before the hold is written. The Windows junction fixture failed the path check and left no hold. | High |
| J | FIXED, NOTE | OBSERVED | `run_timeout.ps1:574` | `if ($LibraryOnly) { return }` | Library mode returns before record initialization at line 577. Dot-sourcing main and the PR with all six daemon settings unset preserved both caller variables, `$rec` and `$pcStepRec`. | High |
| gpu_go.txt | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:558` | `return e.code !== 'ENOENT';` | Only a missing file clears a read error. A directory in place of the pause file stopped discovery and the final recheck. The fixture made no worker calls. | High |

### Windows checks and source record

- `node tools/pc/mission/pc_daemon_selftest.js` passed **30/30** at the PR head with Node 22.11.0. The Windows group used a real slot holder and Job Object, a Node worker and two stand-in launch gates. The accepting gate ran the worker. The refusing gate returned 125 before it started.
- `node tools/pc/runner_selftest.js` passed **141 checks**, exit 0, from the same pin with the standing suite's lane environment filter. It used local fixture repositories. The standing-checks job on GitHub also reported success for this head.
- The shared watchdog diff against main `9afbc41d` adds 91 lines and removes 11. The adapter supplies six daemon settings at `mission/pc_daemon.js:451` and line 452. The watchdog reads and clears them at lines 580 to 587. Normal runs now keep an in-memory step record and use .NET to set and restore profile variables. With all six settings unset, the same CPU child on main and the PR received its inherited profile paths, printed the same output and returned exit 17. The final daemon gate, extended tree wait, slot scratch and on-disk record remain opt-in.
- In a disposable Windows profile, the actual `--clear` command accepted the recorded interrupted attempt once (exit 0), declined a repeat (exit 2), and left the hold for the Board. The cleared attempt dropped out of the interruption list.

GitHub's pinned file contents matched the local Git blobs. The last column records up to 40 characters from the final line. For the two files over 60 KB, the slot helper reads covered lines 851 to 1058, 1061 to 1090, 1097 to 1184 and 1554 to 1557. The runner suite reads covered lines 1 to 142 and 1476 to 1536, plus its complete execution.

| File | Lines | Final line begins |
|---|---:|---|
| `tools/pc/mission/pc_daemon.js` | 845 | `  expectMissing, checkRoot, checkSlotRep` |
| `tools/pc/mission/pc_daemon_selftest.js` | 682 | `})().catch(e => { console.error('FAIL: '` |
| `tools/pc/jobs/opus_job_head.ps1` | 1557 | `}` |
| `tools/pc/run_timeout.ps1` | 923 | `}` |
| `tools/pc/mission/PC_DAEMON.bat` | 13 | `exit /b %RESULT%` |
| `docs/playbooks/pc.md` | 197 | `Node and retire its wrapper. The selftes` |
| `contrib/opus/tools/run_all_checks.js` | 355 | `module.exports = { rowEnv, classifyFindi` |
| `tools/pc/runner_selftest.js` | 1536 | `} })();` |
| `tools/pc/play_godot_safe.bat` | 3 | `call "%~dp0play_godot.bat" --rendering-m` |
| `tools/pc/play_godot.bat` | 45 | `exit /b 0` |

**Board decision.** Return PR 1835 for items 5 and 6. Recheck hold recovery, loss of a lease before launch, and both compatibility play commands before the first live job.

Not checked: a production daemon, slot reset, Board hold edit during cleanup, interactive play session, GPU work, installed tool refresh or real relay delivery. The local run covered the two requested Windows suites and focused comparisons. The full standing suite result came from GitHub.

## Run 5 recheck

**Send PR 1835 back for one slot allocation race.** GitHub reported head `38fc0e7a4f82d7576f33d7e6da6386e81c898674`, one commit after run 4 at `2e000b61`. Both Windows suites passed. Compatibility play is recognized, loss of the lease stops launch, and cleanup preserves an edited marker. A waiting job can still miss the restored Board hold and reuse the slot.

### Run 4 findings at this head

Paths in the tables are relative to `tools/pc/` unless they begin with `docs/`.

| Item | Verdict | Evidence | File:line | Exact quote | Result or requested fix | Confidence |
|---|---|---|---|---|---|---|
| 5, cleanup | PARTLY, BLOCKING | INFERRED | `jobs/opus_job_head.ps1:914`, `:916`; `mission/pc_daemon.js:425` | `(Join-Path $dir 'hold.txt')`, `-Filter 'hold.txt.*.clearing'`, `fs.linkSync(aside, f.marker); fs.unlinkSync(aside);` | The allocator skips a surviving aside. The hard link restores an edited hold and refuses to overwrite a newer one. The two allocator checks can still miss the same hold during restoration. Recheck both names while the new holder owns the lease, before accepting the slot. | High |
| 6, compatibility play | FIXED, NOTE | OBSERVED | `play_godot_safe.bat:3`, `mission/pc_daemon.js:489`, `run_timeout.ps1:638` | `--rendering-method gl_compatibility` | The export and windowed Godot both count as play in both classifiers. Ordinary watchdog jobs now also wait during compatibility play with all daemon settings unset. This is safe for the shipped launchers. Jobs with a script flag still classify as jobs. The existing Codex and test exemptions and eight-hour wait limit are at watchdog lines 645 to 646. | High |
| 5, creation and launch | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:405`, `:410`, `:599`, `:856` | `this.slotCheck(attempt, lease);`, `fs.writeFileSync(marker, text, { flag: 'wx' });`, `d.recheck(pr, spec, { dir, token }, attempt)` | After scratch setup, publication requires a fresh live proof. The watchdog calls the final gate at `run_timeout.ps1:712`. After the approval and play checks, it repeats the helper proof and refuses launch on lease loss. The slot helper checks the holder process, start time, owner token and locked lease at lines 941 to 947. | High |
| D, delivery | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:784`, `:785`, `mission/pc_daemon_selftest.js:529` | `if (!this.tools.pinned) { this.tools.pin(st); pinnedHere = true; }`, `['pin', 'relay']` | Delivery uses the attempt's verified tools version or verifies a version before retrying. A failed pin left the result pending and made zero relay calls. The retry fixture verified a pin and a relay without rerunning the job. This is version verification. The installer compares the staged files at `lane_tools_refresh.ps1:378`; the per-attempt bundle checks the watchdog and job-head files at `jobs/opus_job_head.ps1:1081`. | High |
| H, Board clearance | FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:614`, `:616`, `:840` | `const lost = this.live ? this.interrupted() : [];`, `d.recordedInterruptions().find` | A live daemon holding its lease records the interruption. Clearance requires an uncleared interruption for the selected attempt. The Windows command refused an open start, accepted a recorded interruption once and preserved the Board hold. | High |

**Why cleanup still blocks.** A waiting allocator may check `hold.txt` while the edited file is aside. Cleanup can then restore `hold.txt` and remove the aside before the allocator checks for `*.clearing`. Both probes return empty. If the claimant resumes after the old daemon releases the lease at `mission/pc_daemon.js:741`, it can acquire the slot. The new holder checks the previous owner at `jobs/opus_job_head.ps1:1154`. The reset checks the lease at line 996 and calls `Reset-SlotInner` at line 998. Neither path rereads the hold. Windows fixtures preserved the edited and newer holds during a conflict and refused allocation with a static aside. The remaining race is inferred from the order of operations.

### Other findings

| Item | Severity | Evidence | File:line | Exact quote | Consequence and requested fix | Confidence |
|---|---|---|---|---|---|---|
| Final gate receipts | SHOULD-FIX | INFERRED | `mission/pc_daemon.js:853`, `:854`; `jobs/opus_job_head.ps1:953` | `tools.pinTo(fs.readFileSync(path.join(attempt, 'pc_daemon_tools.txt'), 'utf8').trim());`, `[IO.File]::ReadAllText($f).Trim()` | An empty tools receipt falls back to the current installation at daemon line 316. The gate and helper also take the expected slot and token from the same receipt. A replaced receipt naming a different live lease would prove that lease. Bind the final gate to the tools directory, slot and token established before the watchdog wait, and refuse a missing or inconsistent value. | High |
| Recovery instructions | SHOULD-FIX | OBSERVED | `mission/pc_daemon.js:843`, `docs/playbooks/pc.md:191` | `the Board removes the two hold files` | A stop during cleanup may leave only the token's clearing file in the slot. Following the clearance message can leave that slot unavailable. Name the matching clearing file and have the Board inspect it alongside any newer hold before releasing the slot. | High |
| Shared watchdog documentation | NOTE | OBSERVED | `docs/playbooks/pc.md:172`, `run_timeout.ps1:638` | `unset, the watchdog behaves as before` | The shared play wait changed for ordinary jobs. Document that exception so someone investigating a waiting job can identify the cause. | High |

### Windows checks

- `node tools/pc/mission/pc_daemon_selftest.js` passed **30/30**, exit 0, with Node 22.11.0. This was the author's 29 groups plus the Windows group. A real PowerShell holder and watchdog ran against a temporary CPU slot. The accepting gate ran a Node stand-in and waited for its descendant. The refusing gate returned 125 before the worker started. A subsequent clear with a released lease kept the marker.
- `node tools/pc/runner_selftest.js` passed **141 checks**, exit 0, using the standing suite's lane environment filter, local Git fixtures and stub workers.
- With fixture process records, the actual PowerShell `Test-RyanPlaying` returned false at the run 4 pin and true at this pin for both shipped compatibility commands. At this pin it also accepted a renderer-driver choice and excluded a scripted job and a console process. No game launch was needed.
- With only `hold.txt.<token>.clearing` in a temporary CPU slot, the real slot command reported `no free cpu slot`, kept the file and issued no lease receipt. In a disposable Windows profile, the actual `--clear` command returned 2 for an open start, 0 after an interruption was recorded, and 2 on repeat.
- GitHub reported success for the full standing suite and the aggregate check at this head. [Standing checks](https://github.com/rcbailey12/voidsworn/actions/runs/45253523605/job/137969186830) and [All checks](https://github.com/rcbailey12/voidsworn/actions/runs/45253523605/job/137974779087).

### Source record

The GitHub contents at the pin matched the Git blob IDs and the text used on Windows after normalizing line endings. The large-file reads focused on daemon lines 280 to 307, 313 to 509 and 527 to 879, slot helper lines 1 to 52, 854 to 971, 981 to 1059, 1061 to 1115 and 1116 to 1186, and runner self-test lines 1 to 145 and 1484 to 1536. Both test files ran in full.

| File | Lines | First 40 characters of final line, or entire shorter line |
|---|---:|---|
| `tools/pc/mission/pc_daemon.js` | 879 | `  expectMissing, checkRoot, checkSlotRep` |
| `tools/pc/mission/pc_daemon_selftest.js` | 714 | `})().catch(e => { console.error('FAIL: '` |
| `tools/pc/mission/PC_DAEMON.bat` | 13 | `exit /b %RESULT%` |
| `tools/pc/jobs/opus_job_head.ps1` | 1559 | `}` |
| `tools/pc/run_timeout.ps1` | 925 | `}` |
| `tools/pc/play_godot_safe.bat` | 3 | `call "%~dp0play_godot.bat" --rendering-m` |
| `tools/pc/play_godot.bat` | 45 | `exit /b 0` |
| `tools/pc/lane_tools_refresh.ps1` | 437 | `}` |
| `docs/playbooks/pc.md` | 200 | `Node and retire its wrapper. The selftes` |
| `contrib/opus/tools/run_all_checks.js` | 355 | `module.exports = { rowEnv, classifyFindi` |
| `tools/pc/runner_selftest.js` | 1536 | `} })();` |

**Board decision.** Return PR 1835 before its first live job. Recheck both hold names under the newly acquired lease. A Windows regression should show that a waiting claimant leaves an edited Board hold and the underlying checkout intact across cleanup and release.

Not checked: an actual overlap of two claimants, a production slot reset or daemon, a damaged launch receipt, interactive play, GPU work, an installed-tools refresh or a real relay upload. The watchdog integration used stand-in gates. The full standing suite result came from GitHub.

## Run 6 recheck

**Return PR 1835 before its first live job.** GitHub reported head `01e984891b137e8d7840ad4f2a6c15fdae1fc4dd` at the start and end of this review. The Board hold survived the Windows regression, and the final gate refused every missing or mismatched receipt tested. One new blocker remains. After refusing launch, cleanup can release another job's lease.

### Findings

Paths beginning with `jobs/` or `mission/` are relative to `tools/pc/`.

| # | Finding | Evidence | File:line | Exact quote | Why it matters and requested fix | Confidence |
|---|---|---|---|---|---|---|
| 1 | New, BLOCKING. Release after a refused launch | INFERRED | `mission/pc_daemon.js:713`, `:741`, `jobs/opus_job_head.ps1:975`, `:983`, `:986` | `this.tools.slotRelease(attempt, st)` | The refusal stops the worker, then cleanup rereads the rejected slot receipt. The helper checks the token in the selected slot's owner record, but never checks that the recorded attempt is the one being released. If the receipt names another active lease, cleanup can mark that job released and signal its holder to exit while the job still uses its checkout. Bind release to the original slot and token, and require the owner record to name the same attempt before either write. | High |
| 2 | Run 5 item 5 cleanup, FIXED, NOTE | OBSERVED | `jobs/opus_job_head.ps1:925`, `:943`, `:944`, `:1008`, `:1009` | `(Test-SlotHeld $dir $token) -and (Test-SlotHold $dir)` | The claimant checks both hold names after its holder takes the lease. It checks them again under the reset lock before changing the checkout. On Windows it released the slot and preserved the hold, file and HEAD. | High |
| 3 | Run 5 final gate receipts, FIXED, NOTE | OBSERVED | `mission/pc_daemon.js:709`, `:867`, `:869`, `:874`, `:880` | `gateBinding(attempt, this.tools.pinned, lease)` | The watchdog receives the original attempt, tools folder, slot and token before it waits. The gate reads receipts from that attempt, compares them to the bound values and passes the bound lease to the live check. All six negative Windows cases returned 3. Finding 1 concerns the later release. | High |
| 4 | Run 5 recovery text, FIXED for a valid receipt, NOTE | OBSERVED | `mission/pc_daemon.js:422`, `:846`, `:847`, `docs/playbooks/pc.md:195` | `hold.txt.${token}.clearing` | The actual Windows clearance command named the same token-specific file as cleanup and told the Board to check any newer hold beside it. Both files kept their contents. | High |
| 5 | New, SHOULD-FIX. Clearance with an incomplete receipt | OBSERVED | `mission/pc_daemon.js:842`, `:846`, `:847` | `d.note(e.sha, e.job, e.pr, 'cleared', e.attempt);` | With a slot path but no token, Windows recorded clearance, returned 0 and printed `hold.txt.undefined.clearing`. Validate the receipt before recording clearance or giving removal instructions. An attempt that never took a slot needs only the daemon-hold instructions. | High |
| 6 | Run 5 watchdog documentation, FIXED, NOTE | OBSERVED | `docs/playbooks/pc.md:174`, `:175` | `its game wait now also counts compatibility play` | The playbook now tells the Board why an ordinary job can wait during compatibility play. | High |

### Windows evidence

- **Waiting claimant.** The stock slot suite passed its static check and explicitly skipped the live group on Windows at `contrib/opus/tools/opus_job_slots_tests.js:35`. In TEMP, I ran the new fixture's writes and assertions from lines 250 to 264 with Windows PowerShell, the pinned helper, and a native background launcher in place of the CI shell. The claimant held the lease and reset lock when the fixture wrote the edited Board hold and `survivor_output.bin`. It refused the reset and its holder exited. The two files matched byte for byte. HEAD stayed at `ba888a19` despite the request for `886a72c6`. With only the clearing file left, the next claim also failed.
- **Daemon and runner.** `node tools/pc/mission/pc_daemon_selftest.js` passed 31/31 on Node 22.11.0, including the Windows group in addition to the author's 30. The real watchdog waited for the stand-in's descendant and returned 125 before worker start on gate refusal. `node tools/pc/runner_selftest.js` passed 141 checks using the standing suite's lane environment filter. Both commands exited 0.
- **Receipts and clearance.** On the pinned `--recheck` command, missing, empty and mismatched tools receipts each returned 3. A missing slot receipt, a different slot and a different token each returned 3. In a disposable Windows profile, `--clear` with a valid receipt returned 0 once and 2 on repeat. A separate interrupted attempt with an incomplete receipt produced finding 5.
- **CI.** GitHub reported success for the standing suite and the aggregate check at this SHA. [Standing checks](https://github.com/rcbailey12/voidsworn/actions/runs/45268300834/job/138021028909) and [All checks](https://github.com/rcbailey12/voidsworn/actions/runs/45268300834/job/138026154321).

### Source record

The raw file contents from GitHub at the pin matched the Windows test sources after line-ending normalization. The comparison starts at the run 5 head `38fc0e7a`. For the large files, the focused source reads covered daemon lines 270 to 430, 555 to 600, 671 to 748 and 831 to 903, slot helper lines 81 to 88, 855 to 1078, 1117 to 1201 and 1566 to 1570, and runner self-test lines 1 to 135 and 1489 to 1536.

| File | Lines | First 40 characters of final line, or entire shorter line |
|---|---:|---|
| `tools/pc/mission/pc_daemon.js` | 903 | `  expectMissing, checkRoot, checkSlotRep` |
| `tools/pc/mission/pc_daemon_selftest.js` | 737 | `})().catch(e => { console.error('FAIL: '` |
| `tools/pc/jobs/opus_job_head.ps1` | 1570 | `}` |
| `contrib/opus/tools/opus_job_slots_tests.js` | 278 | `}` |
| `tools/pc/run_timeout.ps1` | 925 | `}` |
| `tools/pc/runner_selftest.js` | 1536 | `} })();` |
| `contrib/opus/tools/run_all_checks.js` | 355 | `module.exports = { rowEnv, classifyFindi` |
| `docs/playbooks/pc.md` | 205 | `Node and retire its wrapper. The selftes` |

**Board decision.** Send PR 1835 back for finding 1. Before merge, require a Windows regression showing that a refused launch leaves another active attempt's owner record and lease intact.

Not checked: a production daemon, an actual cross-attempt release, or a live GPU or relay job. The Windows slot fixture introduced the hold during the reset wait. It did not schedule the daemon's rename and restore between two allocator probes. The watchdog integration used stand-in gates. The full standing suite result came from GitHub.

## Run 7 recheck

**Recommend merging PR 1835 at `7aff7a5f8ada307b5d640c953f22c93676a7f74a`.** The run 6 release blocker and clearance finding both passed on Windows. GitHub reported this SHA as the PR head. The pinned daemon self-test passed 31/31 on Node 22.11.0, including the real Windows watchdog group.

### Release ownership

X and Y each took a separate temporary slot through the pinned helper on Windows PowerShell 5.1. The stock slot suite passed its static check and skips its live group on Windows. The Windows fixture below exercised the cases at `contrib/opus/tools/opus_job_slots_tests.js:269` through line 295. All `jobs/` and `mission/` paths below start at `tools/pc/`.

After **each** of a, a2, b and c, the fixture compared X's `owner.txt` and holder receipt byte for byte, checked the same holder PID was alive, found no `release_<token>` and got Windows sharing violation 32 on an exclusive open of `.slot-lease`.

| Case | Finding | Evidence | File:line | Exact quote | Windows result | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| a | NOTE, copied receipt | OBSERVED | `jobs/opus_job_head.ps1:995` | `does not name this attempt and token` | With X's receipt copied to Y and `OJ_SLOT_EXPECT` set to that receipt, `slotrelease Y` exited 1 and identified the owner mismatch. | None | High |
| a2 | NOTE, missing receipt | OBSERVED | `jobs/opus_job_head.ps1:976` | `slot kept: no slot.txt` | With X's receipt moved aside and its original expectation still set, `slotrelease X` exited 1. The lock check worked while the receipt was absent. | None | High |
| b | NOTE, ordinary tail | OBSERVED | `jobs/opus_job_head.ps1:996` | `it was left alone` | With the copy still in Y and `OJ_SLOT_EXPECT` unset, `slotrelease Y` exited 0 and reported that it left the slot alone. | None | High |
| c | NOTE, wrong token | OBSERVED | `jobs/opus_job_head.ps1:986` | `no longer matches the lease it was given` | With X's receipt restored and the expected token changed, `slotrelease X` exited 1. | None | High |
| d | NOTE, matching lease | OBSERVED | `jobs/opus_job_head.ps1:1004` | `slot $($parts[0]) let go` | With X's matching receipt and expectation, release exited 0. The owner record gained a `released` line, the holder marker disappeared, and an exclusive open succeeded. | None | High |

### Reporting, clearance and run 6 checks

| # | Finding | Evidence | File:line | Exact quote | Windows result | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 6 | NOTE, refused release reporting | OBSERVED | `mission/pc_daemon.js:762`, `mission/pc_daemon.js:753`, `mission/pc_daemon_selftest.js:514` | `failed.push('slot release')`, `The slot was NOT let go`, `the outputs are still delivered` | After a worker ran, `done.txt` read `done FAILED: slot release`. The log and picture remained, and the ledger recorded `FAILED` then `delivered` through the fixture relay. The gate-refused job recorded `ABORTED` and its report said the slot was kept. | None | High |
| 7 | NOTE, interrupted attempt clearance | OBSERVED | `mission/pc_daemon.js:863`, `mission/pc_daemon.js:869`, `mission/pc_daemon.js:866` | `Nothing was recorded`, `this attempt took no slot`, `hold.txt.${parts[1]}.clearing` | With a slot path but no token, `--clear` exited 3, preserved every ledger byte and printed no `undefined`. With no receipt it exited 0 and named only `pc_daemon\hold.txt` for removal. A valid receipt exited 0, named the matching clearing file and the newer hold to inspect, then exited 2 on repeat. Both slot hold files and the daemon hold retained their contents. | None | High |
| 8 | NOTE, hold under the lease | OBSERVED | `jobs/opus_job_head.ps1:1022` | `was set aside (hold.txt) after this attempt took it` | A hold written during the instrumented reset wait stopped the claimant with exit 1. The hold and survivor file kept their bytes, HEAD stayed at `2e312f0d` despite a request for `42ded109`, and the lease unlocked. With just the clearing file present, the next claim also exited 1. | None | High |
| 9 | NOTE, launch gate receipts | OBSERVED | `mission/pc_daemon.js:887`, `mission/pc_daemon.js:889` | `is not the version the step was bound to`, `is not the lease the step was bound to` | The actual `--recheck` exited 3 for missing, empty or mismatched tools receipts, and for a missing slot receipt, a different slot or a different token. With both slots held and X's receipt copied into Y, the gate bound to Y also exited 3. Calling cleanup with Y's original lease exited 1. X passed the same byte, PID, signal and lock checks afterward. | None | High |

### Source record

The four raw files from GitHub at the reviewed SHA matched the sources used on Windows after line-ending normalization. The ranges below identify the focused reads. The daemon self-test ran in full.

| File | Lines | First 40 characters of final line, or entire shorter line | Focused reads |
|---|---:|---|---|
| `tools/pc/jobs/opus_job_head.ps1` | 1586 | `}` | 74 to 88, 826 to 846, 851 to 1079, 1134 to 1214, 1578 to 1586 |
| `tools/pc/mission/pc_daemon.js` | 923 | `  expectMissing, checkRoot, checkSlotRep` | 279 to 303, 367 to 376, 706 to 716, 748 to 770, 846 to 923 |
| `tools/pc/mission/pc_daemon_selftest.js` | 770 | `})().catch(e => { console.error('FAIL: '` | 1 to 35, 220 to 234, 506 to 521, 608 to 632, 733 to 770 |
| `contrib/opus/tools/opus_job_slots_tests.js` | 310 | `}` | Windows skip at 35 to 38 and slot fixtures at 247 to 295 |

**Board decision.** Merge PR 1835 at the reviewed head. Release required the matching owner and lease in every Windows case, and the daemon reported both types of refusal. GitHub reported success for the [standing suite](https://github.com/rcbailey12/voidsworn/actions/runs/45278697669/job/138057380559) and [All checks](https://github.com/rcbailey12/voidsworn/actions/runs/45278697669/job/138063296212).

Not checked: a production daemon job, GPU execution or a real relay upload. The two-slot fixture invoked the real gate and cleanup separately. The reporting self-test used a fixture relay. The full standing suite result came from GitHub.
