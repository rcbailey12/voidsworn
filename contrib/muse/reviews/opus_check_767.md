# Outside check: PR 767, Hegemony Dominion build sheet from H10 (issue 759)

Refs #256. PR 767 merged after Board review, so the conditions below are follow-ups, not merge gates.

## Verdict: GO WITH CONDITIONS

Two conditions: the B-1 to B-3 seam clearance is recorded as an expectation, with the death check sequenced before anything builds on the room positions; and the weapon_match self-test gains a planted fault for each of the two new FITS rows. The sheet itself is sound: weapon match passes against data.js exactly, the fit record is clean, and the two flagged design calls are disclosed plainly enough to rule on.

## Council

- Blind Rey (chair, before the pack): GO WITH CONDITIONS, two conditions (seam clearance; self-test faults for the new rows).
- DeepSeek (DeepThink on, Search off, verified both ends): GO WITH CONDITIONS. Its seam condition is adopted as condition 1. Its SPLIT-field condition is not adopted (see point (d): the S8 sheet's weapon_match.json has the identical record form). Its self-test point, graded a note there, is adopted as condition 2 with the blind leg.
- Flash: attempted, not run. The Google sign-in for the cloud browser stopped at a phone approval at 02:30 CST with no one available to approve it; the seat is recorded as attempted with the approval outstanding, and nothing was sent.
- Qwen: empty by the Qwen3.8-Max daily cap. The selector was verified at Qwen3.8-Max and the pack was attached and sent, but the only answer was the daily-limit notice; no generation took place. The cap hit on Nov 14 had not reset by 02:30 CST on Nov 15.
- Grok: empty, bot wall ("Your request was blocked"), 33rd consecutive empty seat. Nothing was sent.

## The four briefed points

### (a) The design calls, especially the belly pickets and one lance turret a side

Both calls are sound against the data and the rules, and both are disclosed in a "Design calls for the Board (and Ryan)" section of the PR body, in plain terms: "Picket lasers on the belly, not the deck. They cover the underside and keep the deck clear, but the battle camera (from above) does not see them."

The pickets (flak T, 3 shots over F1 and F2, two emitters each) sit on the belly armour step. The binding rule is R240, and the fit record answers it: SENSOR 0 over 30 gun and sensor pairs, with the sensor fin dorsal on the centreline and the pickets ventral. The PR's reason for not putting them on the rail decks is specific and checkable: "the sensor fin sits inside their all-round 0 to 60 degree volume, 3 to 9 units away (the R240 test sweeps every bearing and elevation of the slot)". The chair viewed the sheet's underside and battle-camera pictures: from below the two picket turrets read clearly on the belly step; from the battle camera (port beam, 34 degrees above) they are not visible, exactly as disclosed, and the ship reads armed through the two shoulder lance turrets.

One sentence leans further than the camera supports. The RULEBOOK 4.4 justification says the ship "still reads armed from above through the two lance turrets and the trench". The trench is in the bow face, facing forward; at the sheet's own battle camera it is edge-on at best, and in the picture the chair viewed it does not register. The two lance turrets carry the reads-armed claim on their own. NOTE: count the turrets, not the trench, in the 4.4 line.

One lance turret a side is what the data orders: h_dominion carries hturbo P and hturbo S and nothing else for the lances, H10's turret count and places are kept, the split is recorded (two barrels a turret, both fire every volley), and the fit report's reach table shows both turrets clearing their whole slot arcs (HP and HS each 25 sweep steps clear over 30 to 150). NOTE, a data fact rather than a defect: neither lance fires forward of 30 degrees off the bow, so the bow arc rides on the ion trench's single shot. That is data.js speaking, not the sheet.

### (b) The seam clearance: CONDITION 1

The insides stop 0.14 to 0.16 short of each break line, against the two precedents this project has already measured: E11 needed about 0.5, and S8's B-3 at 0.34 to 0.38 was judged likely to fail (opus_check_748, condition since answered by the Board in PR 770 with the expectation recorded). The figures are also not measured the same way. The precedents are clearances against the displaced tear; this sheet's figure is a plan stand-off from the nominal seam path: the sandbox inside_check.py pads the path's x range by 0.1 and finds the nearest insides 0.04 to 0.06 beyond the padded band, which sums to the PR's 0.14 to 0.16 (chair-verified arithmetic). The tear itself, as the S8 sheet quotes fx_death.gd, deviates by a V kink of 0.08 per unit along the span plus three waves of 0.008 of the length each: on a 21.0 hull one wave alone is 0.168, more than the whole stand-off, before any kink. Beside the longer pieces here (the wedge piece between B-1 and B-2 runs about 7.5 units, the rails pieces about 5.0), kink plus a wave crest reaches roughly 0.4 to 0.5 by the same arithmetic opus_check_748 used.

Nothing is hidden: the PR body flags it as a design call ("Seam clearance: insides stop 0.14 to 0.16 short of the furthest kink of each seam path. If the PC's death_seam_check counts inside triangles outside their piece, pull them back") and the README lists it first among its open risks. The condition is the record and the sequence, in the same form the Board accepted for S8:

**CONDITION 1.** Record the expectation, not just the possibility, of a death_seam_check failure at the seams where insides sit at the minimum stand-off, and run death_seam_check on the stage 7 export before paint or recipe staging builds on these room positions, pulling the insides back where it counts triangles outside their piece.

### (c) R244: shaped flanks, openings with depth

Met on the record. The wedge's flanks are "faceted round a vertical flank band (upper and lower facets, chamfers, a chine)" and the rails are chamfered blocks in two tiers with "a recessed mid band", so no flank is a flat wall. The openings carry depth in the sheet's own numbers: the ion trench is "a 1.3 by 0.7 trench recessed 1.2 deep in the blunt bow face, coil-lined", the nozzle pods have "a thick-lipped mouth with a blue-white throat and guide vanes" with the throat recessed, and the thrusters are "rectangular nozzles with depth". The one flush element, the drone doors ("a seam line only"), is a closed door under the R232 ruling for this ship, not an opening, and the hangar inside it is modelled. The chair's look at the underside picture supports the text: the belly is panelled and stepped, not a flat wall. The final call on the pictures belongs to the Board's R229 compare and Ryan's pack 9.3 judgement, which this check does not replace.

The citation form is right, and the chair verified it against current main: ships.md section 0 ends at item 11, and item 11 is the weapon-match rule (R241). There is no numbered rule 12, so R244 is correctly cited as a ruling.

### (d) The new weapon_match rows: CONDITION 2

The rows match the data and the build. 'hturbo': ({'gun'}, {'turret', 'casemate'}) against HP and HS, recorded in weapon_match.json as type "gun", mount "turret", 2 barrels each for the slot's 3 shots; 'ion': ({'ion_trench'}, {'fixed'}) against I1, type "ion_trench", mount "fixed", 1 muzzle for 1 shot. weapon_match.json passes with 0 problems, and its four slots reproduce data.js h_dominion exactly ([['hturbo','P'],['hturbo','S'],['ion','F'],['flak','T']]).

**CONDITION 2.** The self-test record does not prove the new rows reject a wrong build. The pasted output shows a generic volleys fixture ("5 shots over 3 twin mounts fire every mount on all 6 offsets"), the table line ("13 sheet ships, every data.js weapon has a FITS row and a shot count") and the summary "PASS weapon match self-test (21 planted faults, 13 sheet ships in the table)". That proves the rows exist, accept this build, and that the table is complete; no pasted line shows a planted fault against hturbo or ion (an ion built as a gun, an hturbo built as a trench, a trench on a turning mount). The audit self-test in the same PR holds itself to the other standard ("the audit failed as it must", nine cases). Plant one fault per new row.

NOTE (DeepSeek's SPLIT condition, not adopted). DeepSeek would also require an explicit split field in weapon_match.json, since R241 says the split "is recorded (SPLIT)" while the json carries only shots, barrels and muzzles. The chair checked the standing form: the S8 sheet's weapon_match.json is identical in structure, including its flak slot at 3 shots over F1(2) and F2(2), and opus_check_748 accepted that record with the split stated in the sheet's prose, as it is here ("3 shots over 4 emitters, both fire every volley"). The split is recorded in the machine record in the tool's established form (shots per slot, barrels and muzzles per mount) and in words on the sheet. An explicit allocation field would be a tool change across all 13 sheets, not an H10 defect.

NOTE. The hturbo row also allows a casemate, which this sheet does not use and the row's own comment does not mention ("issue 759: low shoulder turrets"). A future Hegemony sheet could pass weapon_match with a fixed casemate lance on a broadside arc. Ratify that widening or restrict the row to turret.

## Other findings

- NOTE. One PR sentence is stronger than its own table. The design call "Hegemony clean vs one detail level" says "no part type is under the hull (R224 passes)", but the density output pasted in the same PR body puts hatchbox at 0.93 and antenna at 0.94 of the hull's triangles per square unit (chair-recomputed: 9345.4 over 9933.9 is 0.94), and the README's checks table says the same. R224 passing is about the rule's own bar (the density run's flags are []); the sentence should say no part type is flagged, or state the bar. The guns figure in the same call is exact (gun at 5.28 times the hull).
- NOTE. Disclosed and accepted as reported, not bars: the model is 21.2 long against the class 21.0 and "the contract scales it to 21.0"; outline overlap 93.5 percent; the envelope length to beam moves 2.64 to 2.35 because the lance barrels reach 0.6 past the shoulder bays at rest. The rectangular nozzles pass a sandbox run of the export's open-bell function (12 of 12 sectors on all four) but "the export has not run", stated in the README's open risks. The cutaway caveat (the centreline cut shows the wedge's and hangar's insides but not the rails') is stated in the PR body.
- NOTE. The feature table's bulkhead line lists the rail frames R1 to R7 twice verbatim. Cosmetic, but the sheet is a contract other tools read; worth tidying when the sheet is next touched.

## Verified by the chair against the sources

data.js h_dominion and the hturbo, ion and flak entries against weapon_match.json slot for slot; the inside_check.py band arithmetic (0.1 padding plus 0.04 to 0.06 equals the PR's 0.14 to 0.16); the fit report's turret reach table against the P and S arcs; the S8 weapon_match.json record form against this sheet's; the density ratios from the PR's own pasted table; ships.md section 0 on current main (11 items, item 11 is R241); the underside and battle-camera pictures against the (a) and (c) claims.

## Not checked

The design file hegemony_H10.py and the kit parts.py line by line (the pack carries the kit README, the tool patches and the sheet documents, not the full sources); the remaining pictures, including the R229 whole-concept compare, which are the Board's and Ryan's to judge; the stage 7 export and death_seam_check, which do not exist yet; the scene gate, not measured on this sheet, as it discloses.
