# Outside check: PR 775, the Iron Mandate (h_boss) build sheet from IM5 (issue 768)

Refs #256. PR 775 merged after Board review, so the conditions below are follow-ups, not merge gates.

## Verdict: GO WITH CONDITIONS

Two conditions: the seam clearance gets the same expectation-and-sequencing record as the Dominion (opus_check_767 condition 1), on numbers that need it more; and the sheet's proportions table prints a build hull length to beam of 2.66 that no stated beam produces, which must be reconciled with the 2.46 the design call asks the Board to rule on. The sheet itself is sound: weapon match passes against data.js exactly, opus_check_767 condition 2 is answered in full, and the kit additions leave H10 unchanged on the patch evidence.

## Council

- Blind Rey (chair, before the pack): GO WITH CONDITIONS, one condition (the seam record).
- DeepSeek (DeepThink on, Search off, verified both ends): GO WITH CONDITIONS. Its seam condition is adopted as condition 1; its proportions condition is adopted as condition 2; its H10 evidence condition is answered down to a note (the chair inspected the parts.py patch directly, and H10's data has no slot the new builders serve); its Ryan-quote condition is graded a note here, in line with opus_check_770 (see point (a)).
- Flash: not attempted. The Google sign-in for the cloud browser is still blocked on the phone approval outstanding since the 767/770 attempts at 02:30 CST; per the leg discipline no new sign-in prompt was triggered overnight. The seat is recorded as blocked on that approval, to be run with Ryan present if he wants it.
- Qwen: empty by the Qwen3.8-Max daily cap (selector verified at Qwen3.8-Max, pack attached and sent, daily-limit notice returned, no generation). The cap hit on Nov 14 had still not reset by 04:12 CST on Nov 15.
- Grok: empty, bot wall ("Your request was blocked"), 35th consecutive empty seat. Nothing was sent.
- Pack defect, the chair's: the pack's section 7 (the Hegemony faction-law text) failed to embed, and the Board points' section pointers were off by one as a result. DeepSeek flagged both and worked from the PR body's own quotations of factions.md. Recorded so the gap is visible; the findings below do not rest on the missing section.

## The Board's four points

### (a) The design calls, especially length to beam 2.46 and the canyon at 0.3 of the beam

The length-to-beam deviation is disclosed, reasoned, and grounded in the concept Ryan locked. factions.md's "about 3 : 1" is the line-ship language, and the line ship holds it (the Dominion built at 3.14 hull). IM5's own top view measures about 2.5 by hand (2.53: 706 px by 279 px), and the build's stated figures check arithmetically: 31.0 over 12.6 across the pit swells is 2.46, and 31.0 over 12.0 across the knuckles is 2.58 (chair-recomputed; the sheet's own checks.json gives L_to_B_hull 2.46). The boss's broader read is the R255 pick itself, not builder drift.

**CONDITION 2.** The proportions table (PR body and sheet README) prints a third build figure, hull length to beam 2.66, that does not follow from any beam the sheet states: 31.0 over 2.66 implies a beam of about 11.65, and no stated beam (12.0 knuckles, 12.6 swells, 12.76 beam_top in checks.json) is 11.65. Reconcile the three figures (2.46, 2.58, 2.66) and record which measure each is, so the number the Board and Ryan rule on is the number the sheet's tools produce. (DeepSeek's condition, adopted. The envelope figure 2.45 does reconcile: the 31.2 model over the 12.76 beam is 2.44.)

The canyon: 3.8 across the lips over the 12.6 beam is 0.30 of the beam (chair-recomputed; the floor at 3.1 is about 0.25). It is narrower than the concept's about 0.4, per the refinement adopted in the issue 758 record (kept narrow so the ridges never read as separate hulls), and it is disclosed in the change list and the design calls. NOTE: the sheet would be clearer stating the 0.3 against the lips, since the floor measure is 0.25.

NOTE. The Board's brief says "the eight design calls in the PR body"; the PR body's design-call section has eleven bullets and the README's has eight. The 14-item change list gives a reason for every change, so the R233/R236 disclosure is met either way, but the Board should know which list it is ruling on.

NOTE. The PR body and the sheet README both quote Ryan as "Im5 is my preference" (R255). His recorded words are "Im5 for sure, it looks good", followed by the final lock above all that superseded IM1. DeepSeek grades this a condition; the chair keeps it a note, for the same reason as in opus_check_770 (the record names the right ship, so nothing downstream is misdirected), but it is now the third and fourth documents carrying the softened quote, after factions.md and the PR 770 row. When the Board makes the correction opus_check_770 asked for, these two instances should be swept into the same fix.

### (b) The seam clearance: CONDITION 1

The insides stop 0.08 to 0.10 beyond each seam path's padded band (the sandbox helper pads the band by 0.1), so the stand-off from the path itself is 0.18 to 0.20. That is better than the Board's brief phrasing ("0.08 to 0.10 past each seam band") and still far under the peel's needs: on a 31.0 hull one tear wave alone is 0.248 (0.008 of the length), more than the whole stand-off, and the kink beside the longest piece (B-1 at 10.2 to B-2 at 1.2, 9.0 units) adds about 0.36 at mid-piece, for a worst case around 0.6 against the E11 precedent of about 0.5 clear. Both seated legs reached the same condition independently, in the form the Board set on the Dominion:

**CONDITION 1.** Record the expectation, not just the possibility, of a death_seam_check failure at the seams where insides sit at the minimum stand-off, and run death_seam_check on the stage 7 export before paint or recipe staging builds on these room positions, pulling the insides back where it counts triangles outside their piece.

NOTE (DeepSeek): the README's checks-table phrasing ("0 inside objects within 0.1 of any seam path (nearest 0.08 to 0.10 beyond that band)") is easy to misread; the actual number is the nearest inside 0.08 to 0.10 beyond the 0.1-padded band.

### (c) The five Hegemony self-test faults: opus_check_767 condition 2 is answered

The self-test now runs 26 planted faults over 14 sheet ships (was 21 and 13), with a clean h_boss PASS line and five plants on the Hegemony rows: the ion cannon built as a turning gun turret (KIND), an ion emitter trench on a turning mount (the ion row's mount side), the heavy lance built as a fixed emitter trench (KIND), an hturbo trench on a turning mount (KIND), and the new turbo row's trench plant (KIND). Both of the 767 rows are proven to reject a wrong build, the ion row in both dimensions. That is what condition 2 asked for, and more (the turbo row is this PR's own and got its plant in the same pass).

NOTE (both seated legs, independently): one dimension remains unplanted, an hturbo gun on a fixed mount. Both hturbo plants fail on type (a trench cannot show hturbo), so the row's mount set {turret, casemate} is never exercised by a right-type, wrong-mount build. Worth one plant when the file is next touched; it goes beyond what condition 2 required and is not a condition here.

### (d) The kit additions and H10

The additions leave H10 unchanged, on evidence the chair inspected directly rather than the PR's assertion alone. The parts.py patch extends the MACHINES and GUN_BUILDERS table lines and adds three builders (pipe, capbank, exchanger) plus the turbo gun builder; no existing builder's code changes. H10's data (hturbo P, hturbo S, ion F, flak T) has no turbo slot and uses none of the new part types, so the additions cannot fire on an H10 rebuild. The PR states the rebuild reproduces the committed H10 fit numbers exactly (355 objects, 80 parts, 0 clashes, weapon match PASS) in both the body and the README's checks table, and build_manifest_tests passes all 14 sheets with the A16 fixture hash intact (kit.py untouched). The inventory.py and sheet_extras.py edits are guarded None handling for a concept with no side view, as described.

NOTE (DeepSeek's condition, answered down): DeepSeek would have the H10 fit output pasted rather than stated, since the fixture hash covers kit.py and not parts.py. The patch inspection above is the stronger evidence and the chair has it; but the point stands as practice: a pasted fit block would make the claim self-proving in the PR, the way the other checks are pasted.

NOTE (DeepSeek): the fit output's "parts: 114" and the audit's "parts: 404" count different things (kit parts against all parts on the sheet_hull build; the Dominion showed the same split, 80 against 282). Recording the two measures once, in the kit README or the fit report header, would stop the difference being read as an error.

## Other findings

- Weapons verified against data.js: weapon_match.json reproduces h_boss exactly (hturbo P, hturbo S, turbo T, ion F, flak T), PASS with 0 problems; the data has no hangar and none is built, and nova has no mount. The new turbo FITS row mirrors hturbo's (gun; turret or casemate) and T1 is built as a turret on the midships bridge, all round as the T arc requires. R240: 30 pairs, 0 hits, with the bow deck lowered 0.45 to 0.6 so the bridge lance clears the sensor fin.
- Density: flags [], with antenna nearest the line at 0.98 of the hull's triangles per square unit (spinal and hatchbox at 1.11). No PR sentence overclaims the table this time.
- Disclosed and accepted as reported: the model is 31.2 long against the class 31.0 (the contract scales it); outline overlap 91.9 percent at a low fitted camera (14 degrees; a higher start converged to 78.8, stated openly); the cutaway through the open canyon shows the lower hull and the bridges' insides rather than the ridges' (the ridges' insides are proven by the vertex test, 0 of 5,192 outside the skin); the six rectangular nozzles pass the sandbox open-bell run with the export not run; the budget (104,912 outside, 7,944 inside; about 15,400 of it the canyon plant) is reported, not capped, and the scene gate is not measured.

## Verified by the chair against the sources

data.js h_boss and the hturbo, turbo, ion and flak entries against weapon_match.json slot for slot; the parts.py, weapon_match.py, inventory.py and sheet_extras.py patches line by line (additions and table extensions only); the L:B and canyon arithmetic from the sheet's stated dimensions and its checks.json (L_to_B_hull 2.46, beam_top 12.762, model 31.2); the tear arithmetic on the 31.0 hull and the B-1 to B-2 piece length from the sheet's break stations; the issue 758 record for IM5's shape, the adopted canyon refinement and Ryan's ruling words.

## Not checked

The design file hegemony_IM5.py and the feature table in full; the pictures, including the R229 whole-concept compare, which are the Board's and Ryan's to judge; the stage 7 export and death_seam_check, which do not exist yet; the H10 rebuild itself (the claim rests on the PR's stated numbers plus the chair's patch inspection, not on a re-run).
