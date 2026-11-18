# Outside check: PR 943 (auto_pr for muse/ branches; RULEBOOK 2.7 findings rule)

Refs #256. PR 943 head 4bd90780, checked Nov 18, 2026. Council: blind Rey (chair; full-file verification below), DeepSeek, Qwen (Qwen3.8-Max, verified both ends, no A/B), Flash. Grok seat not run for this batch (parked, bot wall).

## Verdict: GO WITH CONDITIONS

The change does what fixes D and C of the Nov 17 audit (R309) require: "muse/*" with "!muse/wip-*" after it gives every single-segment muse/ branch a PR and opts scratch branches out, the empty-issue-number path is safe in both the create and refresh paths, classic branch shapes behave exactly as before, and the RULEBOOK 2.7 text matches the PR body. The legs' one technical condition (an unguarded standing-issue sed with empty n) is discharged by the chair's full-file inspection below. What remains is a wording condition.

## What the chair verified directly (OBSERVED, full workflow file at head)

The pack deliberately carried only the diff, so all three legs flagged the refresh path's standing-issue branch as NOT CHECKED. The chair read the complete auto_pr.yml at head 4bd90780:

1. STANDING is "256" (line 41). The create path sets word="none" when n is empty (line 71) BEFORE the standing case (line 72), which tests whether " $n " appears in " $STANDING ". With n empty the test string is two spaces, which cannot match " 256 ", so word stays "none" exactly as configured. No "Refs #" with a blank number can be produced.
2. The refresh path's standing protection is the guard_standing function: it iterates over the numbers in STANDING, never over n, and rewrites closing words for those numbers. n is never used there, so the empty-n refresh path is safe; the fallback append is additionally guarded by [ -z "$n" ] || (line 110). Qwen's condition 1 option (b) is satisfied by this inspection; DeepSeek's condition 1 is closed.
3. One fragility, noted not blocking: the create path's empty-n safety leans on STANDING's exact spacing. If STANDING ever gained a double space, the two-space test string would match and word would flip to "Refs" with an empty number. Safe as configured today.
4. Approval chain: FINDINGS R309 (read by the chair in the PR 980 check) records Ryan's Nov 17 decision-card ruling "Yes, all eight", listing all eight audit fixes including C (RULEBOOK 2.7) and D (auto_pr covers every muse/ branch, AGENTS.md). DeepSeek's and Qwen's NOT CHECKED on the approval is discharged. The five PRs cited in the 2.7 Why (910, 919, 924, 937, 571) are the audit's citations and were not individually re-verified in this check.

## Condition

1. Wording overclaim (all three legs): "every Muse delivery, whatever its branch name" (workflow comment and PR body) and "Any other muse/ branch also gets a pull request" (AGENTS.md) are broader than the glob. "muse/*" matches one segment after muse/ only; a nested name like muse/design/deep would get no PR. Every muse branch to date is single-segment, and the two stranded branches the fix exists for (muse/look-pass-726, muse/glasswright-family) are covered. Either narrow the wording to single-segment names or switch the pattern to "muse/**" if nested delivery branches are ever intended. Not a merge block; the texts should not promise more than the glob does.

## Notes

- Classic shapes (codex/issue-*, work/issue-*, opus/issue-*, muse/issue-*): unanimous, behaviour identical; the grep guard only skips derivation when there is no issue number to derive.
- The concurrency protection from the Nov 10 PR 409 failure is untouched.
- CI on head 4bd90780 was not separately re-read for this check; the workflow change affects branch pushes, and this PR's own checks were green in the batch's earlier CI sweep (all four PRs' heads showed Standing checks, parity, game checks and open-pr success).
