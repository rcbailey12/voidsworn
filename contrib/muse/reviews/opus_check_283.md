# Outside check: PR #283, issue #264 CI runs campaign parity and the Nemesis scenarios (Refs #256)

Checked at PR head 83669cdb (branch opus/issue-264). Method, proportionate to a one-file workflow change: a blind leg from the primary sources alone, plus chair verification of the workflow file, both new scripts, the pre-existing rules parity script and the PC twin against the board's three named questions.

## Verdict: GO

All three of the board's questions answer yes, no, and yes respectively: the steps really fail the job on a FAIL, the seed range matches the PC's 30 runs, and the always-run conditions cannot hide a failed Godot download. Two low notes, neither blocking.

## The board's three questions

1. Do the steps really fail the job on a FAIL? Yes. Campaign parity accumulates failures in a counter and exits 1 when any check differs (run_parity_campaign.sh:20). The Nemesis scenarios script exits 1 on each of its three failure paths: the JS run failing (:4), Godot writing nothing (:6), and any record differing (:7). The pre-existing rules parity script does the same (run_parity.sh:18, chair-verified at this head). The steps invoke the scripts directly with no continue-on-error anywhere in the job, so a script FAIL fails the step, and a failed step fails the job.
2. Does the seed range match the PC's 30 runs? Yes. The workflow passes both bounds explicitly (checks.yml:54); the script maps them (A from arg 1, default 1; Z from arg 2, default 24) and builds the list with seq, so the workflow's 1 and 30 override the script's 1 to 24 default, exactly as the PR body says. The PC twin builds its list with "for /L %%S in (1,1,30)" (parity_campaign.bat:29). Seeds 1 to 30 on both sides.
3. Can the always-run conditions hide a failed download? No. Each check step's condition (!cancelled() plus the download outcome being exactly success) drops the implicit success gate so a later check still runs after an earlier check fails, which is the stated intent (one red run shows every failure, checks.yml:47). But a job's conclusion stays failure when any step without continue-on-error has failed; later steps running or passing do not clear it. A failed download therefore does two things, both visible: it skips all three checks (their gate is not met) and it fails the job through the download step itself. The download also fails reliably on a bad fetch: curl has no --fail flag, so an HTTP error page would be saved as the zip, but the unzip on the next line rejects a non-zip under the runner's default shell settings and fails the step. There is no path in this file where the download fails and the job goes green.

## Also verified

- Crash handling inside the scripts is sound even though neither reads the Godot exit code. In campaign parity a crashed or missing Godot leaves per-seed output files absent, and each absence is counted as a failure (run_parity_campaign.sh:17). In the scenarios script, empty output exits 1 (:6) and a partial write still fails the byte compare (:7).
- The rest of the workflow is untouched, as claimed. The diff sits entirely inside the godot-parity job; the standing-checks job is unchanged; the job id and display name are kept (checks.yml:32-33), so a required-check setting keyed on that name still matches. The only change to the download step is the added id the new conditions need. The PR body's "not added" claim holds: no step runs the PC-only *_test.gd unit tests.
- The PR body's "168 records" for the scenarios step is the count at this branch's base. The step compares whatever the scripts produce, so once #280 lands (211 records) the same step covers the larger set with no further change.

## Notes (low, neither blocks)

1. Both scripts create but never clear their output folders (run_parity_campaign.sh:8; run_nem_scenarios.sh:3), so on a dirty local workspace a stale file could mask a Godot crash. In CI every run starts from a fresh checkout and those folders are not committed, so this is a local-runs caveat only.
2. Small pre-existing twin drift in failure accounting: the .bat plays its golden runs without an errorlevel check at that point (parity_campaign.bat:39) while the .sh counts a failed JS run immediately (run_parity_campaign.sh:12). The .sh is stricter and CI runs only the .sh, so the step name's "same as tools/pc/parity_campaign.bat" is accurate on seeds and phases and slightly stricter on one failure path. Not introduced by this PR.

## Not checked

- The Node helpers and Godot test scripts under the two wrappers (export_campaign.js, golden_campaign.js, compare_campaign.js, nem_scenarios.js, parity_campaign.gd, nem_scenarios.gd): this check covers the workflow and the shells' failure semantics, which is what #264 changes.
- The PR's own CI run and its timings (whole job 10 min 8 s against a 30 minute limit): reported by the PR, consistent with the sandbox figures it quotes, not independently observed.
- Repository branch protection settings themselves; only the job id and name continuity behind the required-check claim was verified.
