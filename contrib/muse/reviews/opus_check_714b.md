# Outside check: Board commit 7e034f65 on work/issue-710-deepseek (scale_check KNOWN list)

Verdict: GO WITH CONDITIONS.

The brief asked two questions: does the ratchet work, and can anything outside today's six rows hide behind the KNOWN list. The chair traced both in the code, and the council concurred on the mechanics.

## The ratchet works

In row() (godot/render/test/scale_check.gd), a name found in KNOWN increments known_seen; if that row now passes, fails increments and the printed verdict reads "FAIL (known row now passes: delete its KNOWN line, <job>)". If it still fails, the verdict is "KNOWN (<job> clears it)" and the check stays green. The run exits quit(0 if fails == 0 else 1), so the job that fixes a size must delete the KNOWN line in the same change or its own PR goes red. docs/playbooks/scale.md says the same in words (section 3: "a KNOWN row that passes fails the check until it is deleted"; section 4's exit-1 description matches the code), and the file's header comment agrees. Doc and code tell one story. It is the same ratchet shape as contrib/opus/tools/checks_baseline.json, as the code comment notes.

## The six are the right six, and nothing else hides today

KNOWN is a const dictionary matched by exact row name. The chair audited every row() call in the branch's scale_check.gd: each of the six names ("station (one hex)", "station (5+ hexes)", "map station node", "nebula (one hex cloud)", "ion storm (one hex cloud)", "asteroid field biggest rock") is measured exactly once, and each names its clearing job (373 for the three station rows, 368 for nebula and ion storm, 369 for the biggest rock), matching scale.md section 3's table. Similar-sounding rows that are different measurements are correctly outside the list: "nebula (tying veil)" still fails loudly if it leaves its range. A KNOWN entry naming an object the check no longer measures fails the run at the end (known_seen != KNOWN.size()), so the list cannot silently rot.

## Condition

1. The seal on the list is procedural, not mechanical. OBSERVED. Nothing outside the six can hide today, but a future one-line edit adding a seventh entry for an existing measured row would pass the end guard and silence that row; the only barrier is the const's own comment ("Nothing else may be added here without the Board's review") and code review itself. The chair's blind leg graded that the right level of guard for a list whose purpose is to be edited as jobs land; DeepSeek graded it a condition, and the chair adopts DeepSeek's grading for the record, because the brief asked the question directly. Condition: the Board either accepts the procedural seal on the record (it is the same property checks_baseline.json has: a baseline edit is also one visible line), or hardens it, for example by checking the KNOWN keys against a fixed approved set in the same file's test data. Either answer closes this; leaving it unremarked does not.

## Notes

- known_seen counts sightings, not unique keys. If a KNOWN name were ever measured twice, a duplicate sighting could mask a missing KNOWN key and the end guard would pass wrongly. Not live today (the audit above: each name measured exactly once). Tracking the seen names as a set and comparing against KNOWN.keys() closes it whenever the file is next touched. DeepSeek.
- The summary line's wording slightly mislabels its count: it prints "%d of %d objects fail outside the KNOWN list", but the fails counter also includes a KNOWN row that now passes and the known_seen mismatch, neither of which is an object failing outside the list. The exit code is right in all three cases; only the sentence is imprecise. Blind Rey leg.
- "ion storm (one hex cloud)" measures the same nebula variable as the nebula row (branch file line 153). That is PR 714's shipped measurement design, unchanged by this commit, and both rows are KNOWN under the same job (368), so the KNOWN treatment is unaffected. Blind Rey leg.
- Flash's single condition is not adopted: it claims the ratchet's FAIL string prints only the job string and does not note that the row passed. The string reads "FAIL (known row now passes: delete its KNOWN line, %s)" with the job appended; the noting is there. A leg slip, recorded. In substance Flash affirmed the ratchet and the guard.

## Legs and gates

Blind Rey leg first (chair, no pack): GO, two notes (both carried above). DeepSeek (DeepThink on, Search off, verified before and after): GO WITH CONDITIONS, the condition and the set-counting note above. Flash (Gemini "Quick answers 3.5 Flash-Lite", verified selected before and after): GO WITH CONDITIONS on a misread, answered above; its substance concurs. Qwen: seat empty, the Qwen3.8-Max daily limit was reached before this leg ran (the pack sits sent in its chat, unanswered); no substitution was made. Grok: seat empty, bot wall at grok.com, the twenty-second consecutive empty seat. Both recorded, never filled.

## Not checked

The check actually running green on the PC or in CI at this commit (no run output in the fetched material), whether issues 368, 369 and 373 still own those sizes, and the rest of scale_check.gd outside the diff and the row-call audit.
