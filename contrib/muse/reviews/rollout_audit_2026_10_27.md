# Rollout audit synthesis: Audits C, D and E (chair)

Brief: contrib/opus/briefs/muse_2026-10-27c_rollout_audit.md. All eight blind legs pinned to main commit 806233f766bfdfd98c61fbe5bebb834cc11bbe6c (Oct 27, 2026). Legs: Rey, DeepSeek, Argon and Qwen on Audits C and D (rename map against the bible, and whether the rollout landed), and the same four on Audit E (G4 bench, Stream B balance, A4 pass 5 ships, G2 movement, portraits and crests). Legs filed at contrib/muse/reviews/rollout_CD_rey.md and rollout_E_rey.md, contrib/deepseek/rollout_CD_raw_2026_10_27.md and rollout_E_raw_2026_10_27.md (plus identical reviews copies), contrib/gemini/reviews/rollout_CD_argon_2026_10_27.md and rollout_E_argon_2026_10_27.md, contrib/qwen/rollout_CD_raw_2026_10_27.md and rollout_E_raw_2026_10_27.md (plus identical reviews copies). Screening notes sit outside the repo with the chair's working papers. Every claim below is tagged CONFIRMED BY 2+ LEGS, SINGLE LEG or UNSURE, with severity BLOCKER (Ryan cannot test on return), FIX or NOTE. Claims the chair verified personally are marked chair-verified.

## Summary for Ryan

- Nothing in the rollout blocks your return test. The rename map is faithful to the approved bible, and the strings that have landed match the map string for string.
- Three small wording fixes are confirmed: the Eclipse blurb says "stealing starlight" where you ruled energy, not light; one item name (Salvage swarm) stretches the one-meaning rule for salvage; and a Hullbreaker admiral's surname, Steelgrin, turns out to be a Warhammer character's name (the bible itself suggested it, which is why it slipped through).
- Two headline performance claims are still unproven, not wrong: the 20-ship freeze fix has no re-bench yet, and the win-rate recovery was measured on the same seeds it was tuned on, with the fresh-seed confirmation still to come. The faction spread figure of 9 points is also not evidenced in the pack (the only matrix shown still reads 17).
- One ship claim fails on the studio's own photos: the big Crusade dreadnought (V1b) still has a pointed, drooping nose, not the blunt level prow the pass claimed. The five Hegemony prows do pass.
- The six faction crests are fine. Two legs scored them against the wrong picture (the admiral badge sheet); the chair read the actual crest files and they match the bible. The admiral sheet still shows old names, which was already on the to-do list.

## Audit C: the rename map against the bible

Verdict: SOUND, no BLOCKER. All four legs agree every canonical table row is in the map exactly, and the vetoable calls V1 to V18 fit the bible with the exceptions below.

C-1 (FIX, CONFIRMED BY 2+ LEGS, chair-verified): the Eclipse faction blurb (map section 1, data.js:125) reads "stealing starlight to light a new sun". Your round 8 ruling (FINDINGS R58, bible line 14) is "Energy, not light. Eclipse siphon stellar energy." All four legs flagged it (Argon, DeepSeek and Qwen as FIX, Rey as NOTE). Fix: "siphoning stellar energy to light a new sun" (DeepSeek and Argon both propose this wording).

C-2 (FIX, SINGLE LEG, chair-verified): "Grax Steelgrin" (V5) collides with Warhammer. DeepSeek CD found that Steelgrin is a Warhammer Fantasy Skaven surname; the chair verified it on the Warhammer Lexicanum character list, which includes Kaskitt Steelgrin. The other three legs missed it because bible 4.9 itself names Grax Steelgrin as its example, but bible 1.4 forbids names lifted from known franchises. DeepSeek's alternative: Grax Ironmaw. This is question 1 for Ryan, because the bible's own example is the source.

C-3 (FIX, CONFIRMED BY 2+ LEGS, severity split): "Salvage swarm" (data.js:271, the Eclipse salvage item name) is the one place salvage reads as something beyond the item type, against section 5c's one-meaning rule. All four legs flagged the string; DeepSeek and Argon call it a 5c breach (FIX), Rey and Qwen judge it acceptable because what it names is a piece of salvage (NOTE). The chair carries it as a small FIX with the split recorded, because the map's own 5c exists to keep the word to one meaning. DeepSeek's alternative: Scrap swarm. Question 3 for Ryan. The related ship name "Salvage Right" (ui3d.js:20) is a deliberate keep as a proper name (NOTE, three legs).

C-4 (NOTE, CONFIRMED BY 2+ LEGS, chair-verified): the Eclipse Nemesis title pool (data.js:462) has four titles, adding plain "Nadir" to the bible's three (High Nadir, Eclipse-prime, Archivist). Nadir is also the top Eclipse rank. DeepSeek tags it a rank and title clash (FIX); Qwen and Rey tag NOTE (Rey notes the bible itself tolerates the overlap). The map adds it deliberately ("canonical titles plus the top rank"). Question 4 for Ryan.

C-5 (NOTE, CONFIRMED BY 2+ LEGS): the Glasswright Nemesis pool likewise adds a fourth title, "Duelist", beyond bible 6.9's three; bible 6.5 describes that Nemesis as a duelist, so the addition is consistent (Qwen, Argon).

C-6 (NOTE, SINGLE LEG, chair spot-verified): two single words in ship pools collide with famous names. Thornback (Chorus pool, ui3d.js:21) is a Warhammer 40k Tyranid Carnifex sub-species (chair-verified on the Lexicanum). Moonveil (Glasswright pool, ui3d.js:22) is Elden Ring's Moonveil katana (chair-verified). Argon CD raised both inside a longer list; the rest of its list does not carry (Everwatch and Unyielding Oath are the bible's own keeps at 2.10, same class as Steelgrin; Shrieker, Oathkeeper and Moonsorrow are generic words, UNSURE). Question 6 for Ryan.

C-7 (NOTE, SINGLE LEG): the portrait template risk. Argon CD: the map's section 12 row (line 510) tells P to substitute display names into the template "A Nemesis of the %s", which read literally gives "A Nemesis of the the Chorus" and "A Nemesis of the Eclipse". The chair confirms the map row says what Argon quotes; whether the applied line in make_batches.py actually produces that is UNSURE (Rey CD fetched the file and found the section 12 rows applied, but neither leg quoted the applied Nemesis line in full). A check item for P, not a confirmed defect.

C-8 (NOTEs, SINGLE LEG each, chair-screened): Argon CD's remaining C items downgrade on screening. The refit and Nemesis adaptation word sharing (Prism matrix, Waveguide spine, Tasting pores, Long-memory sight, Spark flak) is disclosed in the map itself as deliberate (map line 206 note; lines 419 to 423), so NOTE, not FIX. The Archive as an Eclipse item name (logbook, data.js:269) next to the Archive the place: real, NOTE. Konrad and Marit shared between the Hegemony captain and Nemesis first-name pools: NOTE (the admiral-exclusion rule itself holds; Rey CD construction-checked it). Possessive apostrophes in section 5 item names against bible 1.4 rule 4: NOTE (the rule was applied to ship names; several item possessives are inherited from the old text). Rock shoals and the kept Archipelago against "space, not sea": NOTE, already disclosed in map section 14.

C-9 (PASS, CONFIRMED BY 2+ LEGS): coverage. In the nine B-owned browser files at the pin, no retired display word survives as a display string. The chair grep established this, Rey CD independently re-derived it by classifying every string literal, and DeepSeek and Qwen checked the chair's samples and concurred. Nonzero hits are ids, keys, save keys, CSS classes or comments. The Godot side of the sweep is not yet applied (G1, G3 and L rows still to land, on plan), so full-repo coverage is proven for the browser game only (NOTE on scope, all legs).

## Audit D: did the rollout land correctly

Verdict: LANDED AS CLAIMED where it has landed, no BLOCKER. All four legs agree in substance; Argon CD's FIX verdict rests on the still-to-do items, which the brief excludes from findings.

D-1 (PASS, CONFIRMED BY 2+ LEGS): Stream B's strings step (90aaf85) matches the map on every spot check any leg ran, across weapons, hulls, blurbs, admirals, events, pools, cores and campaign text. The one step beyond display strings is disclosed in both the map (row 4.0) and step 10: the new CLS_NAME table and clsName function, a display mapping only; no id, key, rule, number or random draw changed.

D-2 (UNSURE, CONFIRMED BY 2+ LEGS): step 10's headline numbers cannot be re-derived from the pack. No leg could recount the 331 replacements (no diff in evidence) or re-run the check pack 0 FAIL claim (no test output in evidence). Nothing any leg sampled contradicts either number. Carried as UNSURE, not as a defect.

D-3 (PASS, CONFIRMED BY 2+ LEGS): G2's title and tagline landed exactly. The tagline in godot/ui/battle/brand.gd matches V1 word for word (Rey CD fetched the file at the pin; the other legs confirm from the map's applied rows). The exe file name and save folder stayed pinned, per the ids-never-change rule. One caveat (NOTE, Rey): the exe launch test at ef5cab2 predates the title and strings commits, so the current tree's exe has not had its own recorded launch test in the pack evidence.

D-4 (NOTE, CONFIRMED BY 2+ LEGS): G1 and G3 parity records predate the strings step, exactly as HANDOFF plans. G1's headline is at bdb1a9d (oracle cb55ec9) and G3's campaign record at 9711a7e (oracle d8b47c6), both before 90aaf85. Their re-pins and re-runs are still to do, so Godot parity on the current tree is unproven but not behind schedule. Argon CD's extra worry, that G3's re-pin will also pick up step 9's RAMP change unrouted, is UNSURE and speculative (campaign parity compares campaign state; RAMP lives in battle.js); flagged for Opus to confirm or dismiss when G3 re-pins.

D-5 (NOTE, SINGLE LEG): one visible cross-layer mismatch. Rey CD fetched godot/story/data/arcs.json at the pin: it still lists all six old arc unlock names while data.js lists the six new ones from map section 8. The map's section 11 rows exist to close this, and L's story rewrite is still to do, so this is the planned intermediate state. It becomes a FIX if it is still open when Ryan tests a Godot build whose story screens show unlock names. The same leg verified L's voices step (voices.json carries the map's rows, zero retired words) and the portraits batch file (section 12 renames applied; old words survive only in the batch history the map explicitly keeps, plus one subject line and the NEM2 subject descriptions, which must be renamed before those subjects are queued again).

## Audit E: the rest of Oct 27's work

Verdict: GO WITH CONDITIONS, no BLOCKER. The day's two headline claims are unproven rather than wrong, and one ship claim fails on the sheets.

E-1 (FIX, CONFIRMED BY 2+ LEGS): no post-fix re-bench exists. All four legs: the G4 death-cut fix (2aac0ca) is described and its logic maps to the stated cause, but the r19 re-bench that would prove it has not landed (README: "the r19 run re-measures"; HANDOFF lists it still to do). The 4.3 s freeze stands as fixed on paper only.

E-2 (FIX, CONFIRMED BY 2+ LEGS): even with the freeze fixed, the r18 record's 1% lows at 20 ships need their own explanation. Forward+ 4K sits at 9 fps (109.8 ms) against a 143 fps average, and Compatibility, the shipped safe mode, at 18 fps with a 1.6 s worst frame. Rey and Argon press this hardest; Argon's explanation (overlapping 4K shader and fill-rate spikes, since the CPU cause does not scale with resolution) is an inference, UNSURE until r19 lists the long frames. Qwen notes the Compatibility freeze is shorter but real, with a possible second cause, UNSURE.

E-3 (FIX, CONFIRMED BY 2+ LEGS): the step 9 win rate is measured on its own tuning seeds. All four legs: after the RAMP easing, seeds 7101 and 7102 read 20% and 19%, but those are the same two seeds the attribution and candidates were tuned on, the after-figures have no raw runs in the pack (Rey), and the promised fresh-seed PC confirmation (7103, 7104, jobs sb_ramp_*) is still "results to follow". The attribution table itself reconciles exactly with the raw file (Rey verified row by row; the file's missing variant legend is a small documentation gap). DeepSeek's extra point, that the table supports the diagnosis more than the choice of lever, is a SINGLE LEG NOTE; the other legs accept easing enemy fleets over reverting the two deliberate rule fixes as the coherent read of the same table.

E-4 (FIX, CONFIRMED BY 2+ LEGS): the 9-point faction spread is not evidenced in the pack. Three legs (Rey, DeepSeek, Argon) found the same gap: the only faction matrix included (pass 3 report at bcc7e47) shows a 17-point spread with Chorus ahead, and the post-tuning tables behind the G-13 "17 to 9" claim are not in the pack; the admiral band table (53 to 85%) is likewise absent, so the band is NOT CHECKED. Qwen accepts the figures on the strength of the steps' construction (steps 8 and 9 do not touch sector 1 or the matrices, which all legs agree on). Carried as an evidence FIX, worded plainly: probably right, currently unproven on paper.

E-5 (FIX, chair-verified, legs split): the V1b prow fails the pass 5 claim. Rey E read both sheets as a fail; DeepSeek E and Argon E read them as a pass. The chair viewed bow_before_after_H8_H7_V1b.jpg and V1b_r_23_sweep_painted.webp directly: the after bow is still pointed in top view and droops in side view, with a small tip added, while all five Hegemony bows on the facing rows are flat, square-cut and level (those PASS, all legs and the chair agree). Question 5 for Ryan. Related V1b items: its rows of lit windows remain (Rey; already tracked in HANDOFF still to do as "V1b's vents and porthole rows"). Argon's black foredeck pit is present in the before image too (chair view), so it is a pre-existing feature, not a pass 5 artifact (NOTE).

E-6 (NOTE, SINGLE LEG each): other visual reads at lineup zoom. DeepSeek: rows of small lit windows on the Hegemony frigate and destroyer sit close to the banned porthole-row pattern (chair view confirms the rows exist; they are rectangular, and CLAUDE.md bans round porthole rows, so this is a judgement call for A4). Argon: leftover blobby hull regions on H4, V15, V16, V17 and funnel-like stacks on C15 and C16 (Rey reads the Corsair line as on-brand under its exception; region-level check for A4). Rey: A4's own lineup captions still say "turbolaser" and "Interdictor-class" (sheets drawn before their strings step; flagged so the sweep does not miss the A4 sheets). The Pyre-Barge triangle count (256k) is NOT CHECKED by any leg, per the brief.

E-7 (PASS with NOTEs, CONFIRMED BY 2+ LEGS): movement, as far as stills go. The 680324c strips support turn in place on jets, then burn (Rey, Argon; DeepSeek marks UNSURE at this zoom), and a sidestep with the main drive dark (Rey, Argon). The R55 eased stop, the settle and flip-and-burn are NOT CHECKED by any leg: the A/B clips folder docs/shots/g2/3be2896/ has not landed (still to do), and stills cannot settle a stop. The 3be2896 commit text claims the braking behaviour and a worst enemy round of 14.3 s, same outcomes.

E-8 (PASS, chair-verified): the six faction crests match the bible. Argon E and DeepSeek E scored crest FAILs against crests_all.webp, which is the 24 admiral Command badge sheet, not the faction crests (Rey E identified this correctly). The chair read all six godot/portraits/crests/faction_<id>.svg files at the pin: half sun (Crusade), five linked nodes (Hegemony), scrap teeth ring (Hullbreakers), nine open mouths (Chorus), a beam through a lens splitting rainbow (Glasswrights), black disc with a white-gold ring (Eclipse). The motifs are there. What the admiral sheet does show is pre-rollout names (Cryptlord Anuket, Seraph Vaelen, The Mending Choir where the bible now says Throng, and the Egyptian-flavoured Eclipse names), flagged by three legs; regenerating contact sheets with mapped names is already HANDOFF still to do, so this is a tracked NOTE, not a new finding.

E-9 (PASS, CONFIRMED BY 2+ LEGS): all six palette rows in faction_looks.json match the bible colour lines, field by field, in all four legs that could read them (Qwen included, from text). Two small notes ride along (Rey, Argon): Hegemony damage_glow is white-gold, the Eclipse corona colour, stated in the cc8aeed commit text as a deliberate pick ("Hegemony white-gold"), so a choice to confirm rather than a slip; and the hull_fix rim tint is blue for every faction, which the G4 README describes as "a Fresnel rim in the faction tint" (UNSURE how visible in game). Portrait repaints to round 8 looks are still to do and were NOT CHECKED by any leg (no portrait images in any pack).

## Not checked (all legs)

- The r19 re-bench, the sb_ramp_* fresh-seed runs, and the post-t2 faction and admiral tables: none exist in the evidence yet.
- B's 331 count and check pack output as raw artifacts (D-2).
- Portrait art against the round 8 looks, and the Pyre-Barge triangle count.
- Motion feel beyond the two 680324c strips (no A/B clips at the pin, mp4s not attachable).

## Questions for Ryan

1. The admiral name Steelgrin (question from C-2). One reviewer found that Steelgrin is already a Warhammer character's surname, which your own naming rules say to avoid. The approved story book suggested the name in the first place, which is how it slipped through.
   - A (recommended): Rename him now, while names are still cheap to change. Suggested: Grax Ironmaw.
   - B: Keep Steelgrin. It is a descriptive surname, and the Warhammer character is obscure.
2. The Eclipse blurb wording (from C-1). The faction description says Eclipse are "stealing starlight", but you ruled they siphon energy, not light.
   - A (recommended): Fix the one word: "siphoning stellar energy to light a new sun".
   - B: Keep "starlight" as poetic licence in this one blurb.
3. The item name Salvage swarm (from C-3). Your rule says the word salvage should only mean the item type, so the word stays unambiguous. One item name uses it in a way two reviewers read as stretching that rule.
   - A (recommended): Rename it to Scrap swarm so the rule is airtight.
   - B: Keep Salvage swarm. What it names is a piece of salvage, so it stays inside the rule.
4. The extra Eclipse title (from C-4). The enemy-commander title pool quietly gained a fourth title, plain "Nadir", which is also the faction's top rank.
   - A (recommended): Drop plain Nadir from the title pool; keep the three approved titles.
   - B: Keep it. The map added it on purpose, and the overlap is inside one faction.
5. The dreadnought's nose (from E-5). The ship pass claimed a blunt, level front for the big Crusade dreadnought, but its own before-and-after photos show the nose still pointed and drooping. The five Hegemony ships did get the blunt treatment properly.
   - A (recommended): Send it back for the same blunt, level prow the Hegemony ships got.
   - B: Accept the pointed nose as this ship's look and correct the pass claim instead.
6. Two ship names in the random pools (from C-6). Thornback is a Warhammer monster name and Moonveil is a famous Elden Ring sword. Both are single ordinary-looking words in the random ship name pools.
   - A (recommended): Swap both now, while pool edits are cheap.
   - B: Keep both. Single common words are fair game.
