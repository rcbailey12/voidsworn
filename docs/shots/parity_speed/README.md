# Issue 978: parallel parity evidence

The [four-worker PC launcher](parallel_normal.log) passes the full suite. Every expected battle must have both records, a successful browser
process and a successful Godot battle completion label. Worker exit codes and batch completion are checked separately.
Missing Godot records run alone for diagnosis and remain FAIL. The launchers share `node/run_parity.js`; `parity_main.gd`
only gained two batch labels. No battle rules, oracle files, fixtures, campaign implementation or workflow files changed.

## Source and method

Source pin: `7d4db9de71111eedfe72635c88516f5228bad9af`, branch `codex/issue-978`, Godot 4.7.2, bundled Node 22.11.0.
PC: Ryzen 7 5800X, 16 logical CPUs, about 32 GB RAM. All Godot commands were headless, with no GPU work.

The serial runs used the [original shell script at the source pin](https://github.com/rcbailey12/voidsworn/blob/7d4db9de71111eedfe72635c88516f5228bad9af/godot/rules/test/run_parity.sh)
in fresh temporary project copies, once in fixture order and once in reverse. The parallel runs used the same battle
inputs: default four workers through `parity.bat nopause`, and three workers in reversed order through `run_parity.sh`
under Git Bash. A final native Windows run exercised the finished launcher and its unchanged campaign hand-off.
[Input hashes](inputs.sha256.tsv) verify 14 identical inputs across the checkout and three source copies.
The serial and batch paths in the Godot harness differ only in the new batch labels.

All browser and Godot record files were compared with `cmp -s`, without JSON conversion or normalization.
[The transcript](equivalence.log) names every battle. [The comparison script](equivalence-cmp.sh) checks both writers,
both orders, and the final PC run. [Record hashes](records.sha256.tsv) give the byte count and SHA-256 for every file.
Only the nondeterministic `.timing.json` files are excluded from byte comparisons; the enemy think-time reports remain
in each full run log. Raw records and throwaway fault copies stay in TEMP rather than enlarging this repository.
Paths in the saved logs are shortened for review; record bytes were compared unedited.

| Equivalence check | Browser records | Godot records |
| --- | --- | --- |
| Serial against four workers, normal order | 281 / 281 identical | 281 / 281 identical |
| Serial against three workers, reverse order | 281 / 281 identical | 281 / 281 identical |
| Serial normal against serial reversed | 281 / 281 identical | 281 / 281 identical |
| Parallel normal against parallel reversed | 281 / 281 identical | 281 / 281 identical |
| Serial against final native PC launcher | 281 / 281 identical | 281 / 281 identical |
| `VS_NO_MEMO=1` | Skipped: no hook in this head | Skipped: no hook in this head |

## Planted failures

Each source fault was planted only in its own throwaway project copy. Focused battle lists exercised the fault and
its following battles; those runs also kept the random-number, math, threat and thread checks. Each planted run exited 1.
Missing-record checks withheld a file by renaming it in a throwaway output folder, then restored it. This gives the same
missing-file condition without deleting anything on the PC. Both missing sides were tested through the runner's verifier.

| Plant | Observed result | Evidence |
| --- | --- | --- |
| Crash in `s5`, one batch containing `s5 s1 s2` | `s5` fails alone too, exit 3221225501; `s1` and `s2` stay FAIL although they pass alone | [Crash log](fault_crash.log) |
| NOT PORTED in `s1`, followed by `s2` | `s1` fails with exit 3 and the rule name; `s2` passes, proving the flag is cleared | [Not-ported log](fault_not_ported.log) |
| Fault F1 in both facing sites | `t_ecl_silentarchive` fails at turn 31, `state.units[3].hexMoved`, Node 4 against Godot 2; PRNG 2816775278 on both | [F1 log](fault_f1.log) |
| Missing Godot `s1.jsonl` | Named FAIL; passes alone, exit 0, still FAIL | [Missing Godot record](fault_missing_godot.log) |
| Missing browser `s2.jsonl` | Named FAIL with the missing filename | [Missing browser record](fault_missing_browser.log) |
| One-second worker deadline, batch `s4 s1` | Worker tree stopped; both battles stayed FAIL and passed alone | [Timeout log](fault_timeout.log), [termination log](watchdog_termination.log) |

The watchdog test initially exposed a sandbox restriction on `taskkill`. The runner now retains the worker wait handle if
Windows refuses termination, reports that failure, and waits for the actual worker instead of orphaning Godot. The native
PC retest proved that `taskkill /T /F` stops this test's complete process tree before records are inspected.
[Launcher exit tests](launcher_exit.log) also prove that a successful campaign command cannot clear a rules failure,
and that a failing campaign command makes the launcher fail.

## Measured time

Times include the whole rules step: data export, random numbers, math, browser goldens, Godot battles, comparisons,
threat maps, threads/hard stop and enemy think-time reporting. The PC launcher total additionally includes campaign parity.
These are shared-load measurements, not isolated performance benchmarks: lane D's status reported issue 979 running,
and my serial, reversed-order and fault-proof processes overlapped. Other processes' command lines were unavailable
inside the sandbox. The final native run overlapped both serial runs until the normal run finished, and the short GPU-slot self-test rerun. The parity fault checks had finished.

| Run | Whole rules step | Whole launcher or CI parity job | Result |
| --- | --- | --- | --- |
| [PC serial, fixture order](serial_normal.log) | 1673.156 s (27m 53.156s) | Not included in this shell run | PASS |
| [PC serial, reverse order](serial_reversed.log) | 1709.938 s | Not included in this shell run | PASS |
| [PC parallel, four workers, first shared-load run](parallel_normal_shared.log) | 574.264 s (9m 34.264s) | 675.530 s, including campaign | PASS |
| [PC parallel, three workers, reverse order](parallel_reversed.log) | 651.242 s (10m 51.242s) | Not included in this shell run | PASS |
| [PC parallel, four workers, final native run](parallel_normal.log) | 423.210 s | 484.747 s, including campaign | PASS |
| CI serial reference, run 44105588767 | 1133 s (18m 53s) | 1244 s (20m 44s) | PASS |
| CI parallel, this branch | Pending runner push | Pending runner push | Not run yet |

The [serial CI reference](https://github.com/rcbailey12/voidsworn/actions/runs/44105588767) ran commit
`fda538f6fafddafe0b9c1f1f377b39d8ee0e4007`, one commit ahead of the source pin, with no rules/parity changes.
[Saved job timestamps](ci_serial_reference.json) show that the slowest job, and therefore the whole-check job duration,
was rules parity at 1244 seconds; game checks took 516 seconds and standing checks took 214 seconds.

New CI step, parity-job and slowest-job times must be filled from this branch's first post-push check, then the post-merge
check for the requested landed measurement. This task forbids committing, pushing or workflow edits, so those numbers
cannot exist during this local run. No workflow change is needed: the existing parity step invokes `run_parity.sh`,
which now defaults to four workers and prints its whole-step time. The Windows shell twin was run through Git Bash;
native Linux execution remains for that CI run.

## Other checks and limits

`node contrib/opus/tools/run_all_checks.js` completed in 993.111 seconds, exit 1: 61 PASS, 2 KNOWN, 2 FAIL.
[Full standing-check log](standing_checks.log):

- `gpu_slots_tests`: the sandbox refused a temporary hard link to the bundled Node executable. The native rerun passed
  all 12 test groups in 12.05 seconds, with fake executables and no GPU. [Rerun log](gpu_slots_native.log).
- `picture_provenance_tests`: existing `tools/blender/kits/hegemony_station/capture.gd` lines 169 and 203 save unstamped
  pictures. Its Git blob is `ff049b62a22f4171ce4956edb268f507e757b56d` both in HEAD and in the working tree. This task
  leaves that unrelated file unchanged.

Node syntax, empty-output-folder protection, invalid worker-count refusal and `git diff --check` passed.
The external Claude review link was inaccessible; the live issue body and its copied prototype and fault definitions
were used. No commits, pushes or workflow changes were made.
