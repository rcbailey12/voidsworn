# Repo hygiene audit, Nov 12, 2026 (issue 558, Part C)

Checked live against the repo on Nov 11, 2026, about 22:30 CST: open pull requests, branch list, open issues and their labels, job blocks against RULEBOOK 2.6. Every item below carries its fix; closing, merging and deleting are the Board's actions, this audit is the list.

## Pull requests: 7 open

Live and correctly parked: 562 (this job's auto-PR), 561 (the R219 rulebook sweep, filed tonight), 547 (issue 532 round 3), 544 and 524 (checked in Parts A2 and A1 of this issue).

- **PR 536 (codex/issue-532), close it or mark it draft.** HANDOFF section 0 states its role in terms: it "stays open as the reference only." An open PR claims a review nobody will ever do; the branch keeps the reference after the PR closes. FIX: the Board closes 536 with a line pointing at the branch, or converts it to draft if it wants the reference in the PR list.
- **PR 543 (work/issue-357-deepseek), close as superseded or rebase.** The issue 558 brief records that it conflicts with main. Its parent issue 357 is labelled opus while the delivery sits on a workhorse branch, so the label and the seat disagree. The traps work it carries is being re-scoped tonight by issues 563 (check-suite hygiene) and 564 (retired-number enforcement). FIX: the Board closes 543 as superseded by 563 and 564, or rebases it and re-labels 357 to the seat that will finish it.

## Branches: at least 200, 7 of them live

Two full API pages of 100 came back and the list was still going. Only the 7 open-PR heads are live work. The rest are delivery branches for merged and closed work going back to October (codex/issue-, muse/issue-, opus/issue- prefixes), round branches (opus/issue-209-r2 to r8, four opus/issue-271 variants) and one-offs (onb1, muse/issue-test, muse/repo-state-2026-11, codex/ion1, codex/pre-opus-reset-review-2026-10-31, board/handoff-nov10, board-automation, audit/pass1-3, fx/destruction, fx/destruction3).

- FIX, standing rule for the Board to adopt: a delivery branch is deleted when its PR merges or closes; the merged PR and its commits keep the record, the branch is not the record.
- FIX, one-time pass: delete every branch with no open PR, except any the Board names as a kept reference (536's branch if the Board wants the reference browsable after closing the PR, board/handoff-nov10 if it is still in use). The audit deliberately does not list 200 names; the rule plus the exceptions is the deliverable.

## Issues: done but still open (43 open at the check)

- **515 (muse), close.** Round 8 was delivered and merged (PR 528), Ryan's picks are recorded as R201, and the redraws were re-filed under R200 and R201 to new issues. Nothing in the issue remains that is not carried elsewhere. FIX: close with a pointer to R201.
- **209 (opus), confirm and close, or name the remaining arm.** The build-route comparison this issue exists to settle is decided, and its verdict is now the settled recipe: ships.md section 0 cites checks 336 and 341 as the proof. FIX: the Board confirms the comparison is closed and closes 209, or states in the issue what arm remains open.
- **216 (opus), fold the remainder into 545 and close, or re-scope.** The Nov 7 tooling note (repo memory hygiene plus a council memory file): its hygiene half was overtaken by the issue 492 cleanup (PR 555) and by issues 540 and 545; the council memory file still waits on Opus's placement call, which is the one live ask left in it. FIX: move that one ask into 545 and close 216, or re-scope 216 to the placement decision alone.

## Seats: job blocks against RULEBOOK 2.6

Clean on the point R205 settled. No open issue's job block hands a Blender ship build to Codex; issue 532 sits correctly with opus. Codex-labelled open issues are 557 (export keeps authored interiors, fracture prefers authored seams), 463 (366c small craft deaths), 100, 92, 44, 42 and 41 (R78-era game code jobs, all blocked).

- Nearest edge, flagged for the Board to overrule or confirm: 557 touches the recipe's export stage. Its work is code on the export, not modelling, so the seat stands under 2.6 as written; it is listed because it is the closest any open block comes to the line.

## Labels

- **Issue 256 is closed, still labelled muse, and still the Board's posting place for check requests**: both Part A requests for this very job arrived on it after closure. It works, and it is the oddity the brief named. FIX: the Board either reopens 256 as the standing check issue (its title already says so) or moves the standing check home to a fresh issue and retires 256's label.
- Issue 357's opus label disagrees with its delivery seat (see PR 543 above). Issue 515's muse label is right; the issue is done, not mislabelled. No other label mismatches found in the open set.

## What is not a finding

Hygiene is alive, not neglected: while this audit ran, the Board filed issues 559, 560, 563 and 564 and PR 561, metabolising R219 and the outside checks' open notes (563 explicitly carries "the open notes from outside checks 248, 274, 341, 349"). The list above is the residue that has no owner yet, which is what an audit is for.
