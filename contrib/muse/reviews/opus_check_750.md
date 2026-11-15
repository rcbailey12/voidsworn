# Outside check: PR 750, Eclipse E13 mote and E14 flare build sheets (issue 739)

Refs #256. PR 750 is MERGED (head opus/issue-739 bc483532, base a90ad9aeb8), so these conditions are follow-ups to clear before the PC recipe run and before the sheets stand as the accepted build record. Checked against the Board's four briefed points: the E14 flat-ring reading of R233, the forward gauss turret against designs.md's fixed housing, E13's plate rooting, and the new even_panels and lay_panels in tools/blender/kits/eclipse/parts.py.

## Verdict: GO WITH CONDITIONS

No build failure was found in the pack's evidence. Fit, audit, contract, stage 7 export, density and weapon match are reported PASS on both sheets, and every deviation the council checked is listed on its sheet, which is what R236 requires. The conditions are record and doctrine fixes: two places where the accepted text now contradicts the accepted build, one family-level lore conflict that should be ruled on once, and one kit claim stronger than its code.

## Council

- Blind Rey (chair, before the pack): GO WITH CONDITIONS (flat ring defensible under R233 with the factions.md cost flagged; turret reading game-faithful; rooting picture-faithful and disclosed; two soft spots in even_panels).
- DeepSeek (DeepThink on, Search off, verified both ends): GO WITH CONDITIONS. Its R236 precedence argument on the rooting (condition 2) and its code-level alignment analysis (condition 3) are adopted.
- Flash (Flash-Lite, verified both ends): GO WITH CONDITIONS (turret CONDITION agreeing with condition 2's subject; ring, rooting and panels as NOTEs). Two leg slips recorded below; nothing rests on them.
- Qwen: seat empty by the Qwen3.8-Max daily cap (hit earlier on Nov 14; no window opened, no substitution).
- Grok: seat empty, bot wall (29th consecutive).

## The four briefed points

### 1. E14's flat ring against R233

R233's operative words, "the E14 flare is built with one closed ring", are met: twelve curved shade plates with narrow even gaps on one closed box-section hoop, 6.0 across (0.63 of the 9.52 length), its bow plate the ship's bow. designs.md's "full broken ring of large curved shade plates with clear gaps between them" is consistent with gapped plates carried on a closed hoop. The flat plane is not in R233's words; it is design call 1 on the sheet, inside the Board's R233 authority ("the Board is the final designer and director between an accepted concept and the build"), supported by the ring study (flat reads as one closed ring from above and from every battle bearing; upright reads as a bar from above) and by Ryan's Nov 12 words quoted on the sheet ("I agree with your take": the flare never reads as a small zenith from above). The concept's three views disagree on the plane, so no picture verdict settles it; the pack and the sheet both say so.

**Condition 1 (family doctrine, folds in both ships).** The flat ring inverts factions.md's shade doctrine, quoted on the sheet itself: the shade faces the enemy and the guns fire through gaps behind its rim. The build's ring "faces up, not forward" (a sunshade over the gun heart, rim edge-on to the enemy) and both E14 guns fire over it; E13's gun likewise "fires over the plates, not through a gap behind a shade rim", against designs.md's family language ("guns firing through gaps in the shade"). Both departures are listed on their sheets, so the process complies with R236, but R236 also says ships "should fit the design, lore bible and ship details from the game", and factions.md is a game document. Rule on it once, for the Eclipse family: either the Board records that ring and fan shades are held over the heart and guns fire over them (the zenith precedent the E14 sheet cites), or factions.md's shade line is amended to cover both postures. Not a rebuild condition; a ruling the record currently lacks.

**Note.** The E14 README says the upright ring "fails R233's own test". R233's words contain no from-above test; the criterion is the whole-concept and family-distinctness reading (R229, and R233's "family distinctness included"). The sheet should say that, not "R233's own test" (DeepSeek).

### 2. The forward gauss turret against designs.md's fixed housing

The build is right on precedence, and the council is unanimous. designs.md: "the fixed forward gun (data: gauss fixed) as a dark housing with a recessed aperture and a thin green focus ring, the muzzle set back inside the housing, never a protruding tube". data.js gives d_jackal w:[['gauss','T'],['gauss','F']]: F is an arc, not a fixing. weapon_match's FITS table offers gauss only as the null cannon on a turret, so a fixed housing fails the weapon match the issue's Done when requires to PASS. The build's F1 (twin turret on the gun heart's roof, turning only through the F arc, 60 degrees either side, weapon match PASS) is the game-faithful reading, and the deviation is listed on the sheet.

**Condition 2 (accepted text corrected, two places).** (a) designs.md's "fixed forward gun" and "never a protruding tube" wording should be amended or annotated with the ruling, so the next reader is not sent back to a fixed housing the game cannot build. The build also does not carry designs.md's recessed aperture or green focus ring; the Board should confirm the rail turret meets that line's intent or record the departure beside it. (b) E13's rooting sentence (point 3) in the same edit.

### 3. E13's plate rooting

Verified reversed. designs.md: "The plates root together at the bow and fan out and sweep back over the body like the blades of a hand fan... their tips reaching past the body's sides toward the stern." The build gathers the five plates at the stern root collar (stations 72.1 to 81.5 percent) and fans them forward, tips flanking the nose; the gun sits at that root on the block roof, turning all round (gauss T, weapon match PASS). The sheet's defence: "The beauty, the sheet's plan and the round 1 Fan direction all draw it so; designs.md says rooted at the bow. The build follows the pictures Ryan accepted."

DeepSeek's precedence point is adopted: R236's licence ("we can revise or adjust the actual ships away from the concept, they're just a base") is about the muse concept. designs.md is the accepted family design text, part of "the design... from the game" that R236 says ships should fit, so following the picture over the text runs against R236's stated order. R233 gives the Board the authority to make the call with it listed and shown to Ryan, which the sheet does (it is the first change-list item). What is missing is the ruling landing in the text.

**Condition 2(b) (restated here for clarity).** Record the ruling in designs.md: the fan roots at the stern and opens forward, superseding the bow-rooting sentence, so the accepted text and the accepted build stop contradicting each other.

**Note.** Both sheets head their change lists "Changed from the picture", but the rooting row and the fixed-housing row changed FROM designs.md to match (or to satisfy) something else. Rename the section or split it into changed-from-the-picture and changed-from-designs.md (DeepSeek).

### 4. even_panels and lay_panels (parts.py) against the R243 claim

The functions are real: purely additive in the PR (appended after plate_slab, no existing lines touched); each panel is the kit's plate_slab (chamfered slab, two flush fasteners); equal thickness (0.035) and an even gap within a face; keep-outs honoured (a panel whose centre falls within a mount's radius plus a margin is left out); tone changes in bands along the mass; lay_panels writes one hull object per tone plus a fastener object and registers the panel line for the inventory. E11 and E12 keep their accepted plating.

**Condition 3 (claim or code, Board's choice).** The kit README and the docstring claim more than the code guarantees: "rows lined up from section to section", panels of neighbouring sections lining up so "every row runs on unbroken", the tone "the same on every face". The code computes each face's split from that face's own dimensions (na = round(flen / size), nc = round(fw / size)) and the tone band from the current band's own na (m = mats[((i * na + a) // band) % len(mats)]), so panel boundaries and band boundaries drift wherever neighbouring faces or sections differ in size. Alignment holds within a face, not across the ship. Either key the split to world position along the mass so rows and bands actually run through, or weaken the README and docstring to what the code does. R243's "dead even and ordered to align" is met at the single-face level today.

**Notes.** Panel sizes run about 0.5x to 1.5x the nominal world size by rounding (DeepSeek). A face under half the nominal size in either dimension is skipped entirely and silently, which sits awkwardly against the E13 sheet's "Even, aligned panels on every face (R243)"; worth one line in the kit README. lay_panels registers a single inventory line for the whole panel set, which its docstring states accurately.

## Other findings

- **Note (internal inconsistency, chair-verified in both READMEs).** The E13 budget header says the export route is "the same route for all three"; the E14 header says "for all four". With four Eclipse sheets now delivered, E13's "three" is the stale one.
- **Note.** E13's outline overlap (51.1 percent) is measured at held first-fit camera angles, not a free fit; disclosed on the sheet, so acceptable, but it is not a free-fit number (DeepSeek).
- **Note.** The line-up caption mixes hull lengths (28.0, 14.5, 9.5, 6.5) with data.js sizes (1.3, 0.82, 0.62, 0.5) without saying which is which; a half-line of clarification would help (DeepSeek).
- **Leg slips, recorded, nothing rests on them.** Flash attached a condition to the ring study file's "internal help text", which is not in the pack and was not evidenced; not adopted. Flash also reported run records (run_all_checks.js and others "exited successfully with 0 FAIL") that the pack does not contain; the sheets' own reported results are what this check relies on.

## Verified by the chair against the sources

Lengths (E13 model 6.52 against 6.5; E14 9.52 against 9.5); weapon slots against data.js (d_scythe gauss T only; d_jackal gauss T and gauss F; both weapon_match records PASS); breach anchors (E13 two, Frigate; E14 three, Destroyer); the ring at 0.63 of length; the root collar and plate stations in E13's feature table; the parts.py patch read in full; designs.md read in full; R233 and R236 read in FINDINGS. The same PR also adds the previously missing E11 and E12 rows to the build-sheet index, disclosed in the diff.

## Not checked

Any picture (sheets, previews, whole compares, ring study, line-up): all picture claims, including the outline overlaps and the study's reads, are taken as reported. No geometry was rerun (fit, clash, audit, contract, export, density are the sheets' reported results). weapon_match.py's FITS source was not read; the table's effect is as both sheets and two legs consistently report it. The PC recipe run, paint bake and scene gate are Board steps after this check, outside the PR.
