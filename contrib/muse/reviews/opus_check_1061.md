# Outside check: PR 1061 (HANDOFF section 0, Ryan's open picks point at the live board)

Refs #256. PR 1061 head 34fb10b4, checked Nov 18, 2026. Council: blind Rey (chair; diff, CI and pointer audit below), DeepSeek, Qwen (Qwen3.8-Max, verified both ends, no A/B), Flash. All three legs GO WITH CONDITIONS. Grok seat not run for this batch (parked, bot wall).

## Verdict: GO WITH CONDITIONS

The brief's two tests pass cleanly, and the direction (pointers over a hand list) is sound: the old paragraph was demonstrably rotting. But the new paragraph's promise is not yet true on the live board. At check time the three pointers between them surface none of Ryan's open picks, and the one verified still-open pick the old text carried (issue 211, the Foley probe) falls through all three. The conditions are Board follow-ups, not changes to this PR's text, and the first one is a single label.

## What the chair verified directly (OBSERVED)

1. Scope: full-file diff of HANDOFF.md between base cef236c0 and head 34fb10b4. The only change in the file is the section 0 "Ryan's open picks" paragraph (old lines 29-30, new lines 29-31). Nothing else in section 0 or the file moved; the file still ends without a trailing newline.
2. Doc checks: CI check runs on the head, read through the API: Standing checks (the suite that runs doc_check_tests) success, Godot rules parity success, Godot game checks success, Rules safety net (Godot only) success, open-pr success.
3. The old list was partly stale, as the change assumes: PR 717 (the storm look) was merged on Ryan's instruction recorded in FINDINGS R310; FL5 and CR4 are described as settled in the old text itself. The chair did not verify the current status of the other two old items (815, 855), so the loss finding rests on 211 alone.
4. Pointer audit against the live board at check time: open issues carrying the ryan label: zero. Issue 211 is open and labelled opus, not ryan. LOOP's newest LATEST lines (Nov 17, 17:45 to 18:10 UTC) name neither 211 nor any picture awaiting Ryan's pick. "Pull requests held for his look" has no label, list or query a reader can run.
5. The new text's last sentence is accurate: section 0 already tells readers settled rulings live in FINDINGS, newest row last.

## Conditions (unanimous; Board follow-ups, in order)

1. Put the ryan label on issue 211, and on any other currently open owner pick, before or immediately after this merges. Until then the first pointer is a dead end and the paragraph's "cannot go stale" is a claim about a system that does not exist yet. (DeepSeek's sharper alternative: keep 211 named in HANDOFF until the label is on.)
2. Give the third pointer a mechanism: a label or standing query that identifies PRs held for Ryan's look, or the pointer is not actionable by any reader who is not the Board.
3. The LOOP LATEST pointer only works if LATEST lines actually name pictures awaiting Ryan's pick when one exists; worth one line in the Board's own routine, since the newest LATEST lines at check time did not.

## Notes

- "Cannot go stale" is true of the paragraph's own text (a pointer does not rot the way a list does) and overstated as a promise about findability; the council split on the wording and agreed on the substance. With condition 1 done, the sentence is fair.
- Nothing in this check touches whether the Foley probe should stay open; that pick is Ryan's, and it is currently parked in HANDOFF as his open item (the Nov 16 hand-over recheck found the same). This check only records that the new paragraph, today, would hide it.
