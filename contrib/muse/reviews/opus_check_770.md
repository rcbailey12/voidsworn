# Outside check: PR 770, Board doc answers to opus_check_748 and opus_check_750

Refs #256. PR 770 is merged, so the conditions below are corrections and completions to the record, not merge gates.

## Verdict: GO WITH CONDITIONS

Most of what PR 770 set out to answer lands: opus_check_748's condition is answered in full, and opus_check_750's conditions 2(b) and 3 and all of its notes are answered. Three things remain: the factions.md Sunward row records the wrong fighter as Ryan's pick (SF3 for his SF4), opus_check_750's condition 1 (the Eclipse shade-doctrine ruling) is not answered anywhere in the PR, and condition 2(a)'s second half (the recessed aperture and green focus ring) is not recorded.

## Council

- Blind Rey (chair, before the pack): GO WITH CONDITIONS, three conditions (the SF3 record; condition 1 unanswered; condition 2(a) half answered).
- DeepSeek (DeepThink on, Search off, verified both ends): NO-GO, five conditions. Three are adopted (conditions 1 to 3 below). Two are answered down to notes: its 748 part-3 point (the death check run is future work by that condition's own terms, and the commitment is already carried on the sheet) and its grading of the IM5 quote as a condition (a note here, for the reason given). Its NO-GO is not adopted: the PR's failures are correctable records on a merged doc PR, not a build or a rules change that has to stop.
- Flash: attempted, not run. The Google sign-in for the cloud browser stopped at a phone approval at 02:33 CST with no one available to approve it; the seat is recorded as attempted with the approval outstanding, and nothing was sent.
- Qwen: empty by the Qwen3.8-Max daily cap (selector verified at Qwen3.8-Max, pack attached and sent, daily-limit notice returned, no generation). The cap hit on Nov 14 had not reset by 02:37 CST on Nov 15.
- Grok: empty, bot wall ("Your request was blocked"), 34th consecutive empty seat. Nothing was sent.

## Board point (a): the answers against the conditions

### opus_check_748's condition: answered

The condition asked the Board to record the expectation of a B-3 death-seam failure, pick the fix path before paint and recipe staging build on the hull, and run death_seam_check when the stage 7 export exists. The S8 README's new Board note does the first two in the condition's own terms: "on these numbers the Board expects death_seam_check to fail at B-3, not just possibly. The fix path is chosen now, before the paint stack and recipe build on this hull: move the shell rooms into the galleries (insides only), so the outside Ryan accepted (R254) keeps its proportions. Deepening the hull is the fallback only if the move cannot clear 0.5." The run itself is future work by the condition's own terms, and the sheet's open-risk text already carries it ("Not run here: the death check needs the stage 7 export on the PC"), with the fallback clause presupposing the check as the measure. DeepSeek would have the note restate the run commitment explicitly; that would make the note self-contained, and it is worth doing at the next touch, but the condition is answered. The same PR also corrects the stale ray count the 748 check flagged (739 to 741).

### opus_check_750 condition 1: not answered. CONDITION 2

Condition 1 asked the Board to rule once for the Eclipse family: either record that ring and fan shades are held over the heart and guns fire over them, or amend factions.md's shade line to cover both postures. PR 770 does neither. The chair verified the current texts: factions.md still reads "Guns sit: behind the shade's rim, firing through gaps between plates", and designs.md's own family line still reads "guns firing through gaps in the shade". The two build notes record the built facts for E13 and E14, and the E14 note does ratify the flat ring ("the ring lies flat as a sunshade over the gun heart (design call 1 on the sheet, R233), with both guns firing over it"), but no text rules the doctrine question, so the next Eclipse sheet built from factions.md contradicts both accepted builds again. The PR body does not claim to answer condition 1; this check records it as still owed rather than silently dropped.

**CONDITION 2.** Record the family ruling condition 1 asked for, in factions.md's Eclipse guns line or as a ruling beside it, so the doctrine and the two accepted builds stop contradicting each other.

### opus_check_750 condition 2(a): answered in half. CONDITION 3

The mount half is answered exactly. The E14 build note: "data.js gives the flare gauss T and gauss F, and F is a firing arc, not a fixed mount; the only gauss mount the weapon match accepts is a turret. So the forward gun is built as a low rail turret limited to the forward arc, not the fixed housing described above". That annotation covers the fixed-housing wording and, with it, the muzzle set back in the housing. The condition's other half is untouched: "The build also does not carry designs.md's recessed aperture or green focus ring; the Board should confirm the rail turret meets that line's intent or record the departure beside it." The note never mentions the recessed aperture or the green focus ring, and the E14 text standing above the note still describes both as the design ("a dark housing with a recessed aperture and a thin green focus ring, the muzzle set back inside the housing, never a protruding tube").

**CONDITION 3.** Record beside the E14 build note whether the recessed aperture and the green focus ring are dropped from the flare's design or still owed on the rail turret.

### opus_check_750 condition 2(b): answered

The E13 build note records the stern rooting and its supersession: "the build roots the five plates together at the stern, at a root collar, and fans them forward with their tips flanking the nose... This supersedes the bow-rooting sentence above for the build." NOTE: the note sits two paragraphs below the rooting sentence rather than beside it, so a skim reader can still take the old sentence as live; adjacency would be cleaner at the next touch.

### opus_check_750 condition 3 and the notes: answered

Condition 3 (the even_panels claim) is answered in full, by the weaken-the-claim route the condition offered. The kit README now states what the code does not promise: "each face is split from its own size, so panel rows meet across sections only where neighbouring faces are the same size; panels run about half to one and a half times the nominal size by rounding; a face under half the size either way gets no panels". The parts.py docstring is narrowed the same way, and the chair verified the parts.py patch is docstring only, no code change, as the PR body claims. The notes are answered: both sheet READMEs now head the section "Changed from the picture and from designs.md (R207, R233, R236), and why"; both budget headers read "the same route for all four Eclipse sheets"; and the E14 README's ring study now fails "the whole-concept and family-distinctness reading (R229; R233 "family distinctness included")" instead of "R233's own test". The line-up caption note is deferred to the next line-up run, and the PR body says so openly; that is a stated disposition, not an answer, and it is acceptable as one.

## Board point (b): rulings versus record fixes. CONDITION 1

**CONDITION 1.** The factions.md Sunward status row misrecords Ryan's fighter pick. The row reads "fighter SF3, bomber SB4", "craft picked (R255)", quotes R255 as "Agree on sf3 and sb4", and links contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/SF3.jpg. The delivery record says the opposite, in the ruling addendum on the issue 757 notes: "Ryan ruled SF4 and SB4 (Nov 14, 2026, about 23:51 CST) as his picks from this round's six. SB4 confirms the council's unanimous pick. SF4 is his call over the council's fighter pick." SF3 was the council's pick, not Ryan's, and the quoted words are not his. The row also says craft build sheets are running (issue 769); if that brief takes its fighter from this row, it builds the unpicked ship. Correct the row to SF4 with his ruling, and confirm issue 769's brief names SF4.

NOTE. The Hegemony row's R255 quote, "Im5 is my preference", is not Ryan's words either, and it understates them: the record is "Im5 for sure, it looks good", followed by "IM5 is his final lock above all... IM5 supersedes the IM1 pick from issue 741 as the Iron Mandate direction". DeepSeek grades this a condition; the chair grades it a note, because the row names the right ship and points issue 768 at the right build, so nothing downstream is misdirected. But the column purports to quote Ryan, and a final lock is not a preference; correct the quote at the same touch as condition 1. The same row's Dominion line ("DOMINION SHEET BUILT (PR 767, Board review passed), Ryan judges it next") matches the record, as does the Sunward row's flagship line (sheet accepted under R254, paint stack at issue 756).

NOTE. The designs.md build notes and the S8 fix-path note are design rulings, not pure record fixes, and the PR body's first line ("No game code or rules change") is accurate only for code and game rules. That is not a defect: the supersessions are the answers opus_check_750's conditions required, made under the Board's R236 authority as final designer, and the S8 fix path is the decision opus_check_748's condition asked the Board to make and record. They are flagged here because the Board's brief asked for rulings to be flagged as rulings, and the record is cleaner when the PR body names them as such.

## Verified by the chair against the sources

Every patch in PR 770 against the delivered texts of opus_check_748 and opus_check_750 (their conditions and notes, quoted from the delivered files); designs.md in full after the PR (the build notes, the standing E14 housing text, the family line); factions.md's Eclipse guns line after the PR; the parts.py patch (docstring only); the issue 757 and issue 758 ruling addenda against the factions.md status rows. The PR's own citations map correctly onto the delivered checks (its "conditions 2a and 2b" are opus_check_750's condition 2(a) and 2(b); its "condition 3" is the panel claim).

## Not checked

Whether issue 769's brief itself names SF3 or SF4 (the row is the evidence in the pack; the brief is the thing condition 1 asks the Board to confirm); the R254 Sunward quote in the factions.md row ("Everything for sunward flagship is good...") against Ryan's words, which are not in the pack; the E13 and E14 sheets' own texts beyond what the patches and the delivered check quote; the stage 7 export and death_seam_check, which do not exist yet.
