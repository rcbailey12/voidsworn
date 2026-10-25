# Findings follow-up pass (chair, Job D of the Oct 25b brief)

Scope: a sample of FINDINGS.md rows the Oct 25 audit did not substantively assess, checked against main on Oct 25, 2026 (HEAD fb5c1309 at check time, the Job C synthesis commit). The audit's substantive coverage, per X15, was the X11 to X14 pass, R16 wording, D21, K1, and the plan, plus its headline findings (W1 skills, M1 AJV). Rows inside that coverage are excluded here to avoid duplicating the audit. Rows outside it were sampled for four things: stale premises, dropped consensus items, unverified licences, and citations without full coverage. Each finding below gives the registry row, what was checked, and a suggested registry edit. Opus applies the edits; this pass changes nothing in the registry itself.

Chair verdict on the pass: 10 findings. Two items are resolved by this pass itself (ambientCG licence, D3 via v15). The rest are status corrections and check items, not verdict changes. Nothing here reopens a Ryan ruling.

## 1. X14 ambientCG: RESOLVED at the primary source (licence, verified)

Row: X14, "OPEN only for ambientCG (check its own licence page before first use)". Checked Oct 25: ambientCG's own licence page, https://docs.ambientcg.com/license, reads: "All ambientCG assets are provided under the Creative Commons CC0 1.0 Universal License." It adds: "You can include the raw files in your project, for example a video game." That is the primary source X14 was waiting for, and it matches the secondary-source reports X14 already carried.

Suggested edit: X14 status "OPEN only for ambientCG" becomes DONE, 4 of 4 checked at a primary or official listing (Kenney Space Station Kit CC0 on its itch page; KayKit Space Base Bits CC0 on the Godot Asset Library listing; Poly Haven all assets CC0 on its licence page; ambientCG CC0 on its own licence page, checked Oct 25). Quaternius stays excluded (QAL v1.0).

## 2. X10 narrowed: licences resolved, prices still unchecked (record, corrected)

Row: X10, "Batch 8 sources: Weak. No links in either leg; every price and licence claim is unchecked as filed." The licence half of that sentence is no longer true: finding 1 above, plus the X14 checks, resolve the licence claims for the four asset sources in the plan. The price half is untouched: batch 8 prices were never checked, and no finding in this pass checks them.

Suggested edit: X10 verdict narrows to prices only: "Batch 8 prices unchecked as filed; licence claims for the four plan sources resolved via X14." Do not delete X10; its warning about the legs' missing links still stands for anything else batch 8 asserts.

## 3. D3 FIXED via barge v15 (code, verified)

Row: D3, "Kit script builds space-only parts: WRONG. c19_kit.py:173 mast with yards, :160 funnels, :38 keel line, :403 keel plate. OPEN (A1 removes them)." Checked Oct 25 against tools/blender/a1/barge_v15.py on main (243 lines, the A1 step 2 script behind R13/R14): a full-file search finds mast, funnel, and keel only at line 5 and line 104, and both hits are comments documenting the removal, line 5 ("Space, not naval (CLAUDE.md): no keel, stem, sheer, crossbar mast or funnels") and line 104 ("radiators (no funnels)"). Yard, bollard, crow, and jackstaff have zero hits. The geometry calls are radiator_pair, engine_bell, bow_guns, and side_guns, all forward or out, never back, consistent with R8.

Suggested edit: D3 status OPEN becomes FIXED for the barge via v15, with a qualification: c19_kit.py itself still contains the naval parts as history and is not the live kit path; the general kit rule (whether the kit system produces space-only parts for hulls beyond the barge) belongs to A4/K1, not to this row. Do not edit c19_kit.py on the strength of this finding.

## 4. D22 verdict contradicts its status (record, corrected)

Row: D22, "Sonniss clips in a public repo (field guide line 350; sfx_data.js carries them as base64)". Verdict column: OPEN. Status column: "CLOSED by Ryan, Oct 25: 'Disregard the Sonniss thing, we're fine.' Sound stays as is (R10)." A row cannot be both OPEN and closed by Ryan in the same entry; as written, a reader scanning verdicts will treat the Sonniss question as live, which it is not.

Suggested edit: D22 verdict OPEN becomes DECIDED (or RESOLVED, to match D21's wording), keeping the Ryan quote and the R10 pointer in the status. No change to the sound itself; R10 already records that the sound stays as is.

## 5. S6 status stale: Job B levers delivered Oct 25 (record, corrected)

Row: S6, "Hegemony boss is the hardest opener; Grax the weakest start. bossmatrix s1: vs Hegemony 47%; Grax 36%, Vex 54%; Voice and Vesh 94%. OPEN (B3)." The B3 lever work for exactly these four outliers landed Oct 25: contrib/muse/reviews/b3_admiral_levers_synthesis.md (commit df442a98, two legs, GO WITH CONDITIONS), with test-first perk-number levers (grax damage +10% to +15%; vesh regen 5% to 4% then 3%; mending regen 6% to 5% then 4%; voice damage +15% to +12% then +10%). S6 does not mention it, so a reader will think B3 lever work has not started.

Suggested edit: S6 status adds: "Levers delivered Oct 25 (b3_admiral_levers_synthesis.md, df442a98); awaiting the post-escort-fix rerun and sim testing. The B0 numbers above are unchanged." S6 stays OPEN until the rerun and the sim test land; the edit records progress, not completion. S5 (rerun pending on the PC) stays as is and now also gates those levers, per the synthesis condition 1.

## 6. R5 partially superseded by R20 (record, corrected)

Row: R5, "Engine: the barge is built engine-neutral. The test is 6 flagships, one per faction, in both Babylon and Godot. Copying up to about 20 ships is optional. Ryan and Opus pick before ship 2." Row R20 (trimmed scope) says the same six ships are reused for crowds, crowd runs at 24 and 40 only, max detail and best lighting stay, simple debris physics, depth of field, shake and grading, a simple hex board slice, Godot .exe and Babylon in the browser, and that the trimmed scope overrides R17 to R19 where they differ. R20 does not mention R5, but its scope extends past R5's "up to about 20 ships" (crowds at 24 and 40) and replaces R5's test description in practice.

Suggested edit: R5 gains an annotation: "Test scope superseded by R20 (crowds at 24 and 40, simple hex slice, Godot .exe / Babylon browser). The pick-before-ship-2 clause still stands; the engine pick has not happened." Do not delete R5; its engine-neutral barge clause and its pick clause remain live.

## 7. D20 repo manifest Voice row stale (record, verified with numbers)

Row: D20, "Image manifest 'local only, not in repo': Half right. The manifest is in the repo (contrib/muse/design/IMAGE_MANIFEST.md); the 40 images are local only. Chorus rows are superseded." Checked Oct 25 against the repo manifest on main: the Voice row lists adm_voice_of_the_deep.webp at 403,732 bytes, SHA-256 a1bfcea02c7e1c57483dd41d3745c3bed7432c00fb730c480a98c04ca12d790e. The approved Voice v4 (Ryan, Oct 24, final, superseding v1) is 519,924 bytes, SHA-256 6790c41e5afcbc416cb23773cf89db9c54b653dd8952932138f024b015b886b6. The repo manifest therefore predates the approved v4; the local manifest update has not been pushed. The Matriarch row (688,858 bytes) correctly predates v3, which awaits Ryan's verdict and must not be listed as final.

Suggested edit: D20 adds: "Repo manifest Voice row stale as of Oct 25: it lists the pre-v4 file (403,732 bytes); the approved v4 (519,924 bytes, SHA 6790c41e...) lives in the local manifest update, unpushed. Push the manifest update with the next design push. Do not update the Matriarch row until its verdict lands." Mending needs a fresh direction from Ryan and is not affected by this edit.

## 8. F6 distance claim omits Epic (and Rare) violet (coverage gap, check item, not a verdict)

Row: F6 fix note: "Enemy markers FIXED (7f03908: fx3d.js FOE_C violet, worst-case colour-blind distance 0.42 from all six shield colours, the gold ring and friend green; broken hex outline for enemies, ui3d.js fpHexMeshBroken; nameplates in head.html). Note: Epic rarity is also violet (#c58bff)." Verified: fx3d.js:4 sets FOE_C to C3(.62,.22,1), a violet. Epic is #c58bff (data.js:386), also violet, and it appears in the same row's note but NOT in the distance list (six shield colours, gold ring, friend green). Rare #62ccff (fx3d.js:4, SHIELD_HEX fallback) is also nearby in blue and is not in the list either. No collision is claimed here: the distance metric's method is not stated in the row, so this pass does not compute a rival figure.

Suggested edit: F6 gains a check item: "Measure FOE_C against Epic #c58bff (and Rare #62ccff) in UI contexts where enemy markers and rarity badges both appear, and record the distances alongside the 0.42 figure; change one of the violets only if a measured distance fails the same threshold." Until that measurement exists, the 0.42 claim must be quoted with its list (shield colours, gold, friend green), not as a general violet safety claim.

## 9. K2 pointer: Oct 25 inputs now exist for several A5 items (record, corrected)

Row: K2, "Look and effects items from batch 5 and 7 not yet scheduled by name. OPEN, scheduled. For A5: prefiltered environment map, VFX importance band, screen-size effect LOD with a check that it is on, emissive on its own slot, glow before tone mapping, the tone mapper three-way test (Babylon: ACES vs PBR Neutral; Godot: adds AgX), lighting first then materials then post, single key with 25 to 40% cool fill and Fresnel rim, bloom threshold 0.5 to about 1.0 (scene3d.js), torpedo telegraph (two-stage warning, about 800 ms ramp to white) and the interception call, the luminance background scan. OPEN (A5, B4)." K2's "not yet scheduled by name" remains true: scheduling is A5 entry's job, and this pass does not schedule anything. But three Oct 25 inputs now cover several K2 items as proposals, and K2 does not point at them: the Job A synthesis (a5_effects_sheets_synthesis.md, GO WITH CONDITIONS) adopts the SPEC pins, the FAC3D table, the torp telegraph and interception call (as DeepSeek K2 proposals, UNSURE pending scheduling by name), the merged flash rule, and the damage ladder; and the two Gemini effects shelves (Godot and Babylon 9.30, Argon High, leads only) cover the tone mapper test, bloom thresholds, emissive handling, and screen-size LOD as leads.

Suggested edit: K2 adds: "Oct 25 inputs exist for A5 entry: Job A synthesis (a5_effects_sheets_synthesis.md) plus the Gemini Godot and Babylon 9.30 effects shelves. Scheduling by name still belongs to A5 entry; the torp telegraph and interception call remain proposals UNSURE pending that scheduling." Do not mark any K2 item done on the strength of a shelf or a synthesis.

## 10. F14 partial progress: FAC3D adopted in Oct 25 syntheses, unification still open (record, corrected)

Row: F14, "Corsair glow #e0402c, Voidsworn trim #c8501f as 'observed': Mixed sources. Those are data.js FACTIONS values (data.js:115, 111). FAC3D, the agreed single source, differs: Corsair engine C3(1,.38,.16), Voidsworn trim #9c3a1c (ships3d.js:3, 5). OPEN (palette unification)." The unification itself is still open: nothing in this pass reconciles the data.js FACTIONS values with FAC3D. But the Oct 25 syntheses now adopt FAC3D as the single source in practice: the Job A synthesis carries the full FAC3D table as its spine, and the tactical UI readability shelf uses the FAC3D values for all six factions (verified in its screening). That is adoption, not unification, and the distinction matters.

Suggested edit: F14 adds: "Partial progress Oct 25: Job A synthesis and the UI readability shelf both adopt FAC3D as the single source. Unification stays OPEN until the data.js FACTIONS values are reconciled with or retired in favor of FAC3D." Do not mark F14 done on the strength of adoption in review documents.

## Rows sampled and rows not sampled

Sampled (10 findings above): X14, X10, D3, D22, S6, R5, D20, F6, K2, F14.

Not sampled in this pass (for a later pass or for Opus's own registry hygiene): the remaining F rows (F1 to F4, F7 to F13, F15 to F27 except F6 and F14), S1 to S5 and S7 to S8 except S6, B-1 to B-16, D1 to D2 and D4 to D19 except D3 and D20, and X1 to X9. Two cautions on that list: first, a row not sampled here is not thereby verified; second, several of those rows carry their own pending items that this pass did not re-check (F2 and F3 real-browser pacecheck pending on the PC; F13 gold-law work with screenshots for Ryan; F14's own unification; B-15 chair's top 10 items 3 to 10; S4 skirmish spread, which the Job B boss-spread synthesis does not cover; S5 rerun pending on the PC).

Method limit: audit mention counts were used only to deprioritize rows, never as proof of assessment. A row the audit mentions in passing may still hold an unassessed premise; a later pass should re-sample with that in mind, starting with F13, B-15, and S4.

## Not checked

- Whether c19_kit.py is referenced anywhere live besides history (finding 3 verifies v15's content, not every reference to the old script).
- The FOE_C versus Epic distance itself (finding 8 is a check item, not a measurement).
- Batch 8 prices (finding 2 narrows X10; it does not check a single price).
- Any registry row outside the sample above, including all B rows except where noted.
- Whether Opus has already applied any of these edits after this pass was written; Opus owns the registry and applies the edits, so the registry on main is the authority, not this file.
