# Outside check: PR 709 (DeepSeek arm, issue 644, text floor 17)

Refs #256. Checked at the PR head, work/issue-644-deepseek f7cd5a6c, against issue 644's Done when and the Board's Nov 14 redirect in the issue.

## Verdict: GO WITH CONDITIONS

Council: blind Rey, Qwen and Flash GO WITH CONDITIONS on the same single condition; DeepSeek NO-GO on the same substance, graded harder (recorded below); Grok's seat stayed empty (grok.com bot wall). The PR changes one file, a measurement review, and the no-change shape is exactly what the Board's redirect prescribed: measure first, and if main already meets the floor, change no game file and write the review.

## What was verified

The size floor is genuinely met on main, and the chair verified the load-bearing claims independently rather than taking the review's word: godot/ui/ui_scale.gd reads MIN_TEXT := 17, so the floor check the issue wanted raised from 12 to 17 is already at 17 and passing (ui_spec_tests, 170 checks); the review's per-screen table names the smallest read text on each of the five screens at 17 px at 1080, measured by the shot script and the screens' own headless checks; the fleet list, the case Ryan flagged (R177), shows no overlaps at 1 or 12 ships, and the six flagged pairs are explained convincingly (a loading cover on a checkout with no built hulls, and one button pair occluded by an opaque slide-over panel the tree walker cannot see); docs/shots/text_floor_644/ on main holds a before and after pair for each of the five screens, which is the picture set the Done when asks for. The review's contrast arithmetic is exact: the chair recomputed every figure (Career 3.61:1 on the card, 4.05:1 and 4.47:1 on the darker backgrounds, the proposed fix at 4.57:1) and matched it to the second decimal. Standing checks are reported 48 PASS, 2 KNOWN, 0 FAIL, with parity passing.

## Condition

**Issue 644 must not close on this PR until the Career contrast item is resolved on the record.** RULEBOOK 9.4, cited in the issue's brief and quoted in its Why section, sets one readability standard with two floors: nothing read below 17 px at 1080, and 4.5 to 1 contrast. The Career screen's dim read labels (RUNS, No service yet, Empty refit slot, the experience lines) use BONE3 #7d7768 on the card IRON #182133, which is 3.61:1, and under 4.5:1 on every background the review measured (best case 4.47:1). The review names this plainly and prices the fix at one line (Career BONE3 to at least #8f8878, verified 4.57:1 on the card), but leaves it on the argument that the issue's gate is the size floor. The Done when's letter is size-only, so this does not block the PR; but closing the 9.4 readability issue with a known, measured 9.4 breach neither fixed nor ruled out of scope would leave the record wrong, and the review must not remain the only record of it. The Board should either land the one-line fix (here or as a tracked follow-up), or rule on the record that the Career dim labels are not read text under 9.4. (All four legs raised this; DeepSeek graded it NO-GO, arguing the redirect's own terms, "if any fails, fix only those", make a no-change close dishonest. The chair grades it a condition rather than a NO-GO because the PR delivers exactly the measurement step the redirect ordered and discloses the failure instead of hiding it; what the NO-GO protects against, closing 644 as fully passed, is prevented by this condition.)

## Notes

- The measurement's own current pictures live outside the repo (the job's out/shots folder); the committed before/after set on main comes from the earlier build work. That satisfies the issue, but the review's measurements and its pictures are not in the same place, and no new image enters the repo with this PR.
- The PR body's list of the build's committed pairs names a campaign_fleet before/after pair; the chair verified the committed set in docs/shots/text_floor_644/ holds campaign_map_before/after.jpg, and no campaign_fleet pair exists there (campaign_fleet_1440.jpg is a PC capture in the pc subfolder). A naming slip in the body, worth correcting so the record points at the real pair.
- The measurements were taken on a checkout with no built hulls: the campaign map sat on its loading cover for the first shots and the clean fleet shots came after the sector loaded; the battle HUD's figures come from its headless ledger check because the orders sheet paints words as draw items. All disclosed in the review.
- The head branch (work/issue-644-deepseek) differs from the branch named on the issue card (opus/issue-644), superseding the closed Kimi PR 698. Administrative only.

## Leg records

DeepSeek's second finding, that the PR body's "One finding, not changed" paragraph ends mid-sentence, is a pack artifact: the pack excerpted the body, and the full body completes the sentence ("would fix it (4.57:1) if the Board wants a follow-up"). Nothing rests on it.

## Not checked

The current pictures in out/shots (outside the repo); the committed before/after pairs pixel by pixel (the chair confirmed the set exists on main with the expected names, sizes and the ember look not re-judged); contrast for every read text rather than the smallest per screen (the review's method, and the risk concentrates at the smallest sizes); whether any decorative sub-17 marks exist that the review did not list (the issue allows listed decorative exceptions; the review lists none, and the literal scan covers godot/ui and godot/main).
