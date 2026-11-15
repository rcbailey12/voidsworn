# Outside check: PR 776, Sunward fighter SF3 and bomber SB4 build sheets, the shared squadron craft method (issue 769)

Refs #256.

## Verdict: GO WITH CONDITIONS

One condition, and it is about the record, not the build: the PR builds the SF3 fighter on a ruling Ryan did not make, and its design call 7 proposes correcting the delivery notes that record the ruling he did make. The bomber and the shared craft method, which is what the Board asked this check to cover, pass: the craft reading of rule 11 is sound and honestly labelled, the 1.6 size is scale.md's own, the insides question is genuinely open and correctly left to the Board, and bombs on fixed forward tubes with arc T are consistent from data.js to the FITS table to the sheet.

## Council

- Blind Rey (chair, before the pack): GO WITH CONDITIONS, one condition (the fighter record).
- DeepSeek (DeepThink on, Search off, verified both ends): GO WITH CONDITIONS, the same single condition, and notes agreeing with the blind leg on every Board point. No point of disagreement needed chair resolution.
- Flash: not attempted. The Google sign-in for the cloud browser is still blocked on the phone approval outstanding since the 767/770 attempts at 02:30 CST; per the leg discipline no new sign-in prompt was triggered overnight. The seat is recorded as blocked on that approval.
- Qwen: empty by the Qwen3.8-Max daily cap (selector verified at Qwen3.8-Max, pack attached and sent, daily-limit notice returned, no generation). Third capped attempt this morning; the Nov 14 cap had still not reset by 05:51 CST.
- Grok: empty, bot wall ("Your request was blocked"), 37th consecutive empty seat. Nothing was sent.

## The condition: the fighter record

**CONDITION.** Ryan's ruling on the issue 757 set is SF4 and SB4, recorded in the delivery notes the same night (Nov 14, 2026, about 23:51 CST): SB4 confirms the council's unanimous pick, and SF4 (the Hammerhead Wedge) is his call over the council's SF3. The PR body instead gives the concepts of record as "SF3 and SB4 (R255, Ryan Nov 14 23:57 CST: 'Agree on sf3 and sb4')", both sheet READMEs repeat that line, and design call 7 proposes that "the notes' ruling line naming SF4 should be corrected to R255's SF3". No message from Ryan says "Agree on sf3 and sb4"; the quote and the SF3 pick exist only in the Board's own R255 line and in factions.md's status row, which opus_check_770 condition 1 already flagged for correction to SF4. The PR's own note concedes the conflict with design_notes_757 and resolves it the wrong way: the primary record is the owner's message and the delivery notes that record it, not the later summary line. Correct R255 and factions.md to SF4 and SB4, withdraw design call 7, and treat the SF3 sheet as a build of the unpicked direction. The Board's brief held this PR "for Ryan's fighter pick, SF3 or SF4"; the pick exists, so the hold can be lifted by correcting the record rather than by asking Ryan again. The SB4 half is unaffected: every record agrees on SB4.

## The Board's points

### The craft reading of rule 11: passes

The ships.md addition states the reading, names its sources (issue 769, R253), and labels itself in terms: "This is the Board's reading for craft, not Ryan's words: change it if he rules otherwise", the same discipline rule 11's own text uses for the Board's capital-ship reading. It lands with its document in the same PR (R214). The FITS rows match it exactly ('guns': a gun on a turret only; 'bombs': a bomb_tube on a launcher only), the weapon_match.py comment gives the reason from the game (a craft turns onto its target on a strafing run, fx_weapons.gd), and the self-test proves the rows: clean fighter and bomber PASS, bombs shown as a gun turret refused (KIND), the fighter's all-round guns in a fixed casemate refused (TURRET), guns shown as bomb tubes refused (KIND), a second cassette refused (EXTRA). NOTE: one dimension is unplanted, a bomb_tube on a turning mount (the bombs row allows launcher only). Same class of gap as the hturbo fixed-mount gap noted on opus_check_775; worth one plant when the file is next touched.

### Size 1.6 per scale.md: passes

Verified against scale.md, the R247 scale table. CLS_LEN for Squadron is 1.6; the board draws a craft at 1.6 x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84; the table's Squadron rows give Fighter 3.84 and Bomber 3.84 with the note "same wing frame as a fighter, only its load differs". Both sheets are LENGTH 1.6 with model lengths 1.602 and 1.601 in their checks.json, and the true-scale picture measures the flagship at 43.2 (27.0 x 1.6) against each craft at 3.9. The concept notes' 3.2 and 4.2 were concept-stage figures; "scale.md wins" is the right call, and design call 5 correctly routes any change through scale.md and the SQUADRON_K job rather than the sheets. The bomber reads apart by mass, as the sheets claim: beam 0.80 against the fighter's 0.38, depth 0.43 against 0.19.

### The insides-on-craft contract question: open, and correctly left open

Both craft carry a small inside and one transverse seam only because the build contract refuses a sheet without them; the game shows a craft's death as a spark and hides it (fx_death.gd _wing_death), so no peel ever uses the seam. The two insides differ in kind: SB4's (908 triangles, two magazine rows with eight bombs, the bombardier) is the bomber's story and worth keeping under any ruling; SF3's (112 triangles) is compliance only. Design call 2 asks the Board for a Squadron contract exception and records that contract.py was left alone, which is the right restraint. NOTE for the ruling itself: an exception should be written into the contract's own terms (what a craft sheet must still prove: weapon match, fit, and a stated interior position), not granted as a one-off waiver on these two sheets, or every later faction's craft reopens the question. Nothing here blocks: both sheets pass the contract as it stands.

### Bombs on fixed forward tubes with arc T: passes

Consistent end to end. data.js gives the bomber bombs on arc T (2 shots, pierce); the sheet builds one two-tube cassette forming the bow face, bores 0.22 deep with the next bomb seated (R244 depth, not a flat disc); SB4's weapon_match.json records bombs T, 2 shots, BT bomb_tube on a launcher, PASS. The apparent contradiction (a fixed mount on an all-round arc) is exactly what the ships.md craft reading and the FITS comment address, and design call 4 puts the reading to the Board for confirmation in plain terms. The fighter's opposite treatment matches its own row: guns on a traverse ring, swept all round in the fit check (turrets_swept 1, ARC 0), SF3's weapon_match.json recording guns T, 3 shots, G1 gun on a turret with 3 barrels, PASS.

## Other findings

NOTE (density). Unlike the capital sheets, the craft density runs carry R224 flags, and the PR reports them without a gloss: SF3 radiator 0.23, louvres 0.45, drive edges 0.53 of the hull; SB4 cassette 0.45 and 0.31. They belong with design call 1 (the budget pick): the forged plating is 12,462 of the fighter's 18,606 triangles and does not read at 30 px on screen, while the flagged parts are the sparse ones. If the Board drops modelled plates on craft, both the budget and these ratios move; the pick should be made with the two together.

NOTE (merge order). PR 775 (merged) and this PR both rewrote weapon_match_selftest.py from different bases: 775's merged version reports 26 planted faults and 14 sheet ships, with the five Hegemony plants; this PR's reports 25 and 15, with the four craft plants and no Hegemony block. When this PR merges, both blocks must survive (30 planted faults, 16 sheet ships). PR 775's body flagged the overlap ("PR 776 adds to it too"); this PR's body does not mention it.

NOTE. S8 is unchanged by the Sunward kit additions, on the PR's evidence: the fit run after the kit change reproduces the committed numbers (401 objects, 741 rays, weapon match PASS) and the body states the baseline taken before the change was identical. The shared tool changes (build.py px_per_unit and view_pad, layout.py label_scale and bar_units) are default-preserving for every other sheet, as the patches show.

Accepted as reported: outline overlaps 90.8 (SF3) and 90.5 percent (SB4); how sheet craft reach the game is open (the game builds craft in code, squadron_craft.gd; the recipe entries carry a placeholder game_code; no stage 7 export or install, design call 6); the scene gate is not measured; the bomber's mouths read only when it faces the camera (design call 3, with the true-scale and battle pictures as the evidence).

## Verified by the chair against the sources

scale.md's Squadron rows and scale formula against both sheets' LENGTH and checks.json figures; the ships.md patch text and the weapon_match.py and weapon_match_selftest.py patches line by line; both weapon_match.json files against the data.js wing entries; the issue 757 delivery notes for Ryan's ruling and its wording; both sheet READMEs for the inside, seam and cassette claims.

## Not checked

The SF3 sheet's build quality (held with the fighter question; only its record and its part in the shared method were checked); the pictures, including the battle camera and true-scale shots, which are the Board's and Ryan's to judge; contract.py itself; how sheet craft will reach the game.
