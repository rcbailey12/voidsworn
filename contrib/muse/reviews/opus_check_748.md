# Outside check: PR 748, Sunward flagship (ascendant) build sheet from S8 (issue 738)

Refs #256

## Verdict: GO WITH CONDITIONS

PR 748 was open when the Board briefed this check and has since MERGED (2026-11-15T04:40:25Z, head opus/issue-738 6282cb83), so the one condition is a follow-up for the Board's record, not a merge blocker. The sheet is thorough: fit CLASH 0 across all eight categories with four turrets swept, weapon match PASS, contract, audit, manifest and inventory checks all PASS, every change from S8 listed with its reason, and the one real risk in the job (the gun-deck peel's clear band) surfaced by the sheet itself with numbers and named fixes.

## Council

- Blind Rey (chair, before the pack): GO WITH CONDITIONS, one condition (the B-3 clearance expectation, point 2).
- DeepSeek (DeepThink on, Search off, verified both ends): GO WITH CONDITIONS, three conditions. Its point 2 condition is adopted. Its point 1 condition is not adopted (the item it could not find is in the list; quoted under point 1). Its point 3 condition is answered down to a note on the PR's own evidence (point 3).
- Flash (Flash-Lite, verified both ends): GO, with point 2 graded CONDITION as an open-risk follow-up. Its quoted "exact words" are paraphrases that match nothing in the pack (recorded under leg slips); its verdict direction agrees with the chair and nothing rests on its wording.
- Qwen: seat empty by the Qwen3.8-Max daily cap (hit earlier on Nov 14; no window opened, no substitution).
- Grok: seat empty, bot wall (30th consecutive).

## Point 1: the change list against S8 and R232

Passes. The chair checked the list against the Sunward pack's section 9 (Ryan's ruled answers, Nov 12, 2026). Question 1 (replace the fork; each class's bow designed for that class; the lance recess only where the class carries the lance; no lance added to the Daybreak's data): the build replaces the fork with a forged spearhead, one point at mid height, diamond in section, and data.js ascendant carries no lance. Question 2 (the spire row stands on every class, profiles vary, tallest amidships, the ember glow holds): the build's bank becomes one row of seven spires on the centreline spine block, tallest at the middle of the row, four profiles (blade, raked, stepped, twin). Question 3 concerns the Hearth carrier, not this ship.

The rest of the list is reasoned from the governing texts: five broadside ports a side, not S8's seven, because hbattery fires five shots and seven single guns would leave two silent (R241); S8's four deck turrets kept in their grid as two pairs, each pair one data.js slot (the Sear pair single-emitter, the flak pair twins sharing three shots, the SPLIT stated); the hull deeper (2.75 against S8's 2.2) for the two deck rows and real insides (R215); widest at the stern third per factions.md, with the outline still widest amidships as S8's is; bells bigger and deeper-set (factions.md); command slits in the spine block's forward face rather than a deck house (R185). The proportions table discloses the departure honestly (length:beam 6.38 on S8's sheet against 5.22 on the build; length:height 12.11 against 8.03) and the outline overlap (86.2 percent) is reported, not treated as a bar.

DeepSeek's condition on this point is not adopted: it could not find the spire height increase as a distinct item in feature_table.md's list. The item is there: "The spires stand taller than S8's bank: the tallest 2.6 over the spine block (3.1 over the deck) against S8's 1.8", with its reason (factions.md's "a row of tall radiator spires"; the battle camera at 34 degrees). The list is complete as the README claims.

## Point 2: the 0.38 and 0.34 clearances at the gun-deck split (B-3)

**CONDITION (the check's one condition).** The numbers, all from the sheet: B-3 is a level plane at z -0.72 running stations 32.6 to 59.3 percent of the 27.0-unit hull, a span of about 7.2 units; the nearest insides sit 0.38 above it (the gun deck slab) and 0.34 below it (the shell rooms). The game's peel, as the sheet quotes fx_death.gd, tears with a V kink of 0.08 per unit along the span and three waves of 0.008 of the length each (0.216 on this hull). Measured from mid-span the kink alone displaces about 0.29 at the span ends; kink plus a wave crest approaches 0.5, which is what E11 empirically needed (at 1.45 its B-3 left 15 deck triangles past the torn plating; at 1.7, 0.5 clear, it passed). On the sheet's own figures, then, the 0.34 below band is likely, not merely possibly, breached near the span ends.

The sheet does everything right about this: it flags the band as an Open risk in its own README, names the deciding test (the PC's death_seam_check on the stage 7 export, which this job's Done when puts after Board and Ryan review), and names both fixes. The condition is about what the Board records now: (1) record the expectation, not just the possibility, of a B-3 failure on current numbers; (2) pick the preferred fix path before the paint stack and recipe staging build on this hull, because the two fixes differ in consequence (deepening the hull about 0.25 changes the proportions this sheet approves; moving the shell rooms into the galleries does not); (3) run death_seam_check when the stage 7 export exists and do not treat the sheet as death-clean until it passes. This is not a criticism of the sheet: surfacing the risk with numbers is the sheet doing its job.

## Point 3: the layout.py edits

Passes, with one note. The patch (+9 -4) makes three changes, each commented with its issue. 'radiator' joins the KITK tuple so the new Sunward kit's radiator spire features route as kit-built in the generated inventory, matching the new tools/blender/kits/voidsworn/parts.py. An optional blend_where header line lets a sheet rendered off the PC state where its blockout actually is instead of printing a PC path it never had; when the key is absent the old line prints unchanged, so the edit is backward compatible and, in effect, an honesty improvement. The weapons header text drops a section number ("lore bible 7" becomes "the lore bible"). No layout, fit or weapon logic changes.

**NOTE (DeepSeek's point, answered on the PR's evidence).** Adding a kind to the shared KITK tuple would re-route that kind on any sheet that uses it, and the pack alone does not show other sheets' manifests. The PR's own record answers the practical concern: PR 748 touches no other sheet's files (outside the S8 folder, only the build-sheets index README and layout.py itself), and build_manifest_tests.js passes for 10 sheets against their committed manifests, so no existing sheet's routing changed. The residual is forward-looking only: a future sheet using kind 'radiator' now gets kit routing by default, which the KITK comment already states plainly.

## Other findings

- **NOTE (chair-verified).** The README's checks table reports the fit check at "739 rays"; fit_report.md and the feature table both say 741 rays, and the PR body's pasted FIT line agrees with 741. The README figure looks like the stale one; correct it to 741.
- **NOTE.** The scene gate is unmeasured ("Reported, not capped; scene gate not measured"). Disclosed on the sheet and not a bar in this job; it stays open for the PC run.
- **NOTE.** The density result (no flags; lowest radiator 0.93 triangles, 0.83 edges) is the sheet's reported outcome; the R224 threshold itself is not in the pack, so no leg verified the rule, only the report.
- **Leg slips, recorded so nothing rests on them.** Flash's three "exact words relied on" quotations are paraphrases matching nothing in the pack, and its point 2 gloss (a risk about "the game's grid density" and future insides pieces) misstates the peel risk; Flash's grades are recorded, its evidence is not used. DeepSeek rendered one patch comment path as tools/blender/kits/v2/parts.py; the patch reads tools/blender/kits/voidsworn/parts.py. Neither slip touches a finding above.

## Verified by the chair against the sources

Weapon slots against data.js ascendant (hbattery P, hbattery S, turret T, flak T; ability nova; no hangar, no lance) exact, and the muzzle arithmetic behind the contract line (5 + 5 broadside, 2 turret emitters, 4 flak barrels = 16). Breach anchors: eight, Dreadnought base 8 with Sunward +0, alternating sides along the broadside deck line. Length 27.0 per CLS_LEN['Dreadnought']. The change list read in full in feature_table.md; the layout.py patch read in full; R232 read in the faction pack's section 9 and in FINDINGS.

## Not checked

Any picture (sheet, compare, weapon review, battle camera, outline check): picture claims, including the 86.2 percent outline overlap, are taken as reported. No geometry was rerun; fit, audit, contract, manifest, inventory and inside-skin results are the sheet's reported outcomes, produced with the issue's helper scripts where the README marks them with an asterisk. tools/blender/kits/voidsworn/parts.py internals were not line-checked beyond its README. fx_death.gd was not read; the peel figures are the sheet's quotations of it, and the E11 precedent is as the sheet and FINDINGS report it.
