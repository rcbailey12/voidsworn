# C2: synthesis and single-leg draft verification (read-only, HEAD d5d0227)

Labels: VERIFIED / WRONG / STALE / UNCHECKABLE, then OBSERVED (seen in file) or INFERRED (reasoned from what was seen).
Legs: DS = contrib/deepseek/reviews/*_deepseek_draft.md, QW = contrib/qwen/reviews/*_qwen38max_draft.md. Syntheses are in contrib/muse/reviews/.

## 1. gold_law_synthesis.md
Proof: 117 lines; last line "- The acceptance measurability panel rec". Legs: DS 33 lines ("The one conflict this repair handles wor"), QW 48 lines ("End of draft. Awaiting Ryan's ruling. Op").
Verdict: faithful to both legs, but it rests on brief claims that HEAD contradicts (ring colour, flagship marker, rarity ladder, UI gold use).
1. VERIFIED OBSERVED. The table split is quoted correctly. QW renames 4 and recolours Epic only (QW:15-19); DS renames Chorus only (DS:14-18).
2. VERIFIED OBSERVED. The viewer test merge is faithful: DS:31 "1920x1080, 100% UI scale, default combat camera distance"; QW:41 "three different battle scenes".
3. WRONG OBSERVED. The synthesis adopts DS's "The selection ring is white" (DS:9). At HEAD ui3d.js:238 has `OV.selRing=ringMesh(new C3(1,.75,.3)...)`, which is amber-gold. This may be a ruled change that is not built yet.
4. WRONG OBSERVED. The synthesis adopts "the flagship marker is a faction-coloured chevron" (DS:9). At HEAD fx3d.js:70 has `flagRing ... emMat('flagM',new C3(1.5,1.15,.45))`, a gold torus. The prow chevron exists separately (fx3d.js:28).
5. WRONG OBSERVED. Condition 1 asks to "confirm the full ladder (common through mythic)". data.js:386 has only Common, Rare and Epic, and "Epic ... col:'#c58bff'" is already violet. There is no legendary or mythic tier, so the Epic RECOLOR is already true in code (it is a doc-only issue).
6. WRONG INFERRED. The migration list (both legs) covers docs only. The law says gold is "rationed to patrons and Command UI only", but the UI class "gilt" #d0a64b is used 64 times in UI code, for example on traversed campaign-map paths (campaign_run.js:36, stroke '#d0a64b'). Code is missing from the migration list.
7. VERIFIED OBSERVED. Chorus trim #a4913a and Ithar trim #d7c88a are live in code: ships3d.js:6 and ships3d.js:7 (FAC3D), and data.js:121 `trim:'#d7c88a'`.
8. VERIFIED INFERRED. The adjacency warning holds: the rose-violet Nursery fallback sits near the Epic colour #c58bff (data.js:386).

## 2. luminance_facet_synthesis.md
Proof: 160 lines; last line "- The in-game frame cross-check (Qwen's ". Legs: DS 79 lines ("Weakest point of this spec: the new back"), QW 103 lines ("End of draft. Awaiting Ryan's ruling.").
Verdict: faithful and the arithmetic is right. One wrong claim about the repo's folders.
1. VERIFIED. sRGB 128 converts to 0.215861 linear, which rounds to 0.2159. 0.40 x 0.2159 = 0.08636, which rounds to 0.0864. The unrounded route gives 0.086344, which rounds to 0.0863 (DS:31). Synthesis lines 33-40 are correct.
2. VERIFIED OBSERVED. The point-count note is right. QW:52 claims "20 fixed points + 1 brightest-pixel point = 21", but it lists 4+1+4+4+6 = 19 fixed points (20 in total). Also, the 4 diagonal ends are the same points as the 4 corners.
3. VERIFIED OBSERVED. The clocks are QW's: "within one working week" (QW:74) and "two-week fix window" (QW:87).
4. WRONG OBSERVED. Line 110 says "The repo has none of these directories today". docs/ and tools/ do exist at HEAD; only assets/, art/ and src/ are missing. "single-file game" is also loose: the source is many .js files that build.py packs into one page.
5. VERIFIED OBSERVED. No luminance code exists (no grep hits for luminance in *.js), so "Not checked: frame script as implemented tool" is accurate.
6. UNCHECKABLE. The 18 plates are not in the repo (CONVERSATION_CONTEXT.md section 5 says "The images are not in this repo").
7. Note on the QW leg only (WRONG INFERRED): QW:33 says the cap "corresponds to roughly sRGB 83". Grey 83 is 0.0865, which is over the cap; the highest neutral grey that passes is 82 (0.0844). The synthesis does not repeat this.

## 3. acceptance_measurability_synthesis.md
Proof: 174 lines; last line "- The at-a-glance 15-viewer / 5-second c". Legs: DS 200 lines ("The test these numbers handle worst is t"), QW 176 lines ("End of draft. All numbers and thresholds").
Human-viewer panels the synthesis requires:
- Silhouette: 7 viewers for each same-faction pair (all unordered pairs); session cap 8 hulls.
- Faction at a glance: 7 viewers per hull, plus at least 1 viewer with a documented mild colour-vision deficiency. That viewer is not counted in the pass, so in practice 8 per hull. Session cap 6 hulls.
- Gold-trim confusion: 7 viewers per comparison, screened for normal colour vision (Ishihara), shown 1 reference crop. Session cap 10.
- Colourblind shield, layer 1: 8 viewers per simulated shot, 2 simulations per shot. Session cap 12 images.
- Colourblind shield, layer 2: 3 viewers with documented deuteranopia or protanopia, on 100% of shield-hit shots.
- Settler study: a 15-viewer panel with a 5-second window (line 137).
- Luminance: 0 viewers (instrumental). The luminance spec's blind mask test uses 2 operators, not viewers.
Findings:
1. VERIFIED OBSERVED. The scaling is faithful: DS 11 of 12, 10 and 9 (DS:38-40) become 6 of 7, 5 and 4 (synth:41-44). DS gold uses 12 per comparison (DS:101); QW gold passes at 6 of 7 (QW:84).
2. WRONG OBSERVED/INFERRED (arithmetic). Line 115 says "11 judgements per shot". DS needs 8 viewers on each of 2 simulations (DS:170-172), so 16 simulated judgements plus 3 real viewers is at least 19. The figure 11 counts people, not judgements.
3. WRONG OBSERVED. Line 144 says "down to Qwen's 5s (lightest)". QW uses 5 only for the silhouette test; it uses 7 for at-a-glance and gold, and 3 for colourblind (QW:21, 50, 79, 136).
4. UNCHECKED GAP OBSERVED. DS contradicts itself: 11 of 12 is both "pass" (DS:73) and "borderline" (DS:74). The synthesis fixes this quietly (6 of 7 passes, exactly 5 is a hold) but never states a timing fail line (4 or fewer).
5. VERIFIED OBSERVED. The shield wording is colour-neutral, with no cyan anywhere in the file. That fits the ruling that shields are faction-coloured (fx3d.js:3 "shields wear their faction's colour"). Chorus and Deathless have no shield-hit shots.
6. VERIFIED. The luminance section matches the facet synthesis (cap 0.0864, full scan).

## 4. chorus_reword_synthesis.md and chorus_regenerate_deepseek_draft.md
Proof: synthesis 90 lines ("- Regenerate cost or queue position, if "); DS reword 50 lines ("OBSERVED: the problem is not only the ph"); QW reword 81 lines ("END OF DRAFT. ALL REWORDS ABOVE ARE PROP"); regenerate 97 lines ("Open question for owner (PROPOSED): How ").
Verdict: the reword synthesis is faithful to its legs but STALE overall. The regenerate draft's abilities are correct, but it brings sutures back in.
1. VERIFIED OBSERVED. The picks quote correctly: DS 1.2 "tubes fused at the base into a pulsing mass" (DS:14); QW B "ragged lip of regrowing flesh" (QW:45); the QW C "knotting" flag (QW:72).
2. STALE. Line 5 says "Reword vs regenerate vs waive remains undecided" and the next step checks "Matriarch v2, Voice of the Deep, Mending Choir v2". The rulings now are: Voice v4 final, Matriarch v3 candidate, Mending needs a new direction, and the DeepSeek regenerate briefs govern.
3. STALE. Line 10 says "Mending Choir fix is effectively settled as a text option". The ruling says Mending needs a new direction.
4. VERIFIED OBSERVED. The regenerate abilities match code: data.js:222 "Spawning surge ... +50% damage this round"; data.js:225 "Discordant volley"; data.js:224 "regrow 6% ... Regrowth tide ... 25%".
5. WRONG INFERRED (rule conflict). The regenerate draft uses "suture-like filaments" (regen:23), "suture filaments" (regen:65, 83, 89) and "knitting closed under crossing suture filaments" (regen:77). Both reword legs flagged "stitching/sutures" as a constructed-thing violation (DS:37; QW:55).
6. STALE. The Voice regenerate briefs (regen:45-67) are moot now that Voice v4 is final.

## 5. price_ladder_synthesis.md (single leg)
Proof: 71 lines ("  draft by design."); DS leg 71 lines ("Least sure item: the Hegemony roster gat").
Verdict: the arithmetic and the leg are right and the Hegemony note is current, but several multipliers apply to classes those factions never sell.
1. VERIFIED OBSERVED. data.js:329 `h.cost=Math.round((60*cp+10)/5)*5` gives 70 for cp1 and 130 for cp2.
2. VERIFIED (arithmetic). All 12 worked values recompute correctly: 85/150, 60/115, 50/100, 90/175, 95/170. The only exact tie is the Chorus destroyer: 97.5/5 = 19.5, which rounds up to 100.
3. VERIFIED/ANSWER OBSERVED. There is no per-faction price multiplier field. Only a global `priceMult()` exists (core.js:181: wrights .85, h_coffers 1.25, sector price), applied at campaign_run.js:150. Per-faction tables exist only for crew and boarding (battle.js:81-82, CREW_MULT and BOARD_MULT).
4. VERIFIED/ANSWER OBSERVED. There is no per-faction class flag. Carrier, battleship and dreadnought availability is a global meta unlock (campaign_run.js:139 `META.unlocked.u_carrier`), mapped to each faction by `equivHull` (core.js:199).
5. VERIFIED/ANSWER OBSERVED. There is no weapon-kind availability flag. Kinds are only battery, flak, lance, torp, bio, gauss and sq, so the "missile or bombard" gate (DS:47) names kinds that do not exist. Corsairs carry torps (data.js:79-80).
6. WRONG INFERRED. The table prices classes these factions never sell. The Deathless roster is frigate, destroyer and cruiser only (data.js:126). Hegemony has no carrier (data.js:114). Chorus, Corsairs, Ithar and Deathless have no BB+ in their rosters (bosses are excluded). So "Deathless ... 1.15 BB+" (synth:16) and DS:59 "more capital or old-machine anchors" do not apply.
7. WRONG OBSERVED. "Not checked: whether explicit h.cost overrides already exist" can be answered: every Voidsworn hull has one (data.js:61-66: 70, 130, 200, 260, 340, 520; the ladder would give 190, 250, 310 and 490 for the last four).
8. VERIFIED OBSERVED. Squadrons are skipped by pricing (data.js:328 `if(!h||h.sq) continue`). The Ithar Brace gate fits `canOrder` (battle.js:795). The Hegemony staleness note matches the sync-primary ruling.

## 6. plate_mapping_synthesis.md (single leg)
Proof: 68 lines ("  presume."); DS leg 67 lines ("END OF DRAFT").
Verdict: WRONG and STALE on Dead Star; right that no anomaly or plate hooks exist.
1. WRONG OBSERVED. DS:40 says "no well mechanic is defined anywhere", and synth:16-18 calls a well "new engine work". The gravity well already ships: battle.js:270 "v47 gravity well (dead star maps)", with wellTick at battle.js:272-277 and set up at battle.js:305.
2. STALE. Recommending "finale role, not ... a well mechanic" (synth:16; DS:37) and condition 2 are both overtaken by the ruling: the existing well board stays, and the plate is its backdrop plus a finale backdrop.
3. VERIFIED OBSERVED. There are five map kinds (campaign_run.js:24 MAP_NAME: belt, station, planet, storm, graveyard). Dead star is a board shape, not a map kind (battle.js:18), and it is allowed only on storm and graveyard (battle.js:51 DEEP_MAPS, battle.js:297).
4. VERIFIED OBSERVED. There are no "anomaly" hooks: 0 grep hits in any *.js file.
5. ANSWER OBSERVED. Plates are not referenced in code. The battle backdrop is built per faction by `composeBackdrop(fac)` (gfx3d.js:303-304). "Pulsar" in code is a weapon (data.js:19), not a plate.
6. WRONG INFERRED (partial). Synth:31 lists "solar flare events" among hooks that are not verified. An in-battle flare event does exist (battle.js:25 `flare:{n:'Solar flare'`; battle.js:376).
7. VERIFIED INFERRED. No hooks were found for storm rotation, home sector, finale or boss phase 2 (0 grep hits in the battle and campaign files).

## 7. Single-leg DeepSeek drafts
deathless_wording: 178 lines ("7. Approve or reject the listed passage-").
1. VERIFIED OBSERVED. All 18 quoted phrases exist in contrib/muse/design/art_direction_rey.md, at lines 24, 30, 41, 55, 56, 97, 104 and 108.
2. STALE OBSERVED. Line 144 proposes "Passage G: change 'sensor light instead of faces'", and decision 7 includes G. The ruling is that passage G stays unchanged.
3. STALE (framing). The draft frames Deathless as "machine intelligences" (line 25), with no "transcended" or sentient-robot framing. The bone-as-metaphor and no-faces recommendations do match the rulings.
4. VERIFIED OBSERVED. Nekhet exists as a Deathless admiral (data.js:230). #cfd4c8 appears only in the doc, not in code.

tool_guides_retier: 207 lines ("D9 - Sign-off order. Confirm that the do").
1. VERIFIED OBSERVED. About 38 quoted passages match their stated line numbers in the version before commit 834bcb6 (for example 178 "2,400 to 38,000" and 678 "The phone tier is the gate").
2. STALE OBSERVED. HEAD already carries the re-tier (834bcb6, "re-tier framing to desktop-first"). Lines have shifted about +4 (182, 286, 695), and most of the quoted phone lines are gone. The version that was applied differs from the draft: line 182 still reads "per hull, per tier", and line 9 says "simplified-tier compression gate".
3. WRONG INFERRED. The draft says the "PC's installed Blender version is unchecked". The repo records portable Blender 4.5.14 (CLAUDE.md:3, HANDOFF.md:22, NEXT.md:34), which is below the 5.1 the Blender Lab MCP needs.

density_statement: 52 lines ("- PROPOSED decision: whether the density").
1. VERIFIED OBSERVED. The quotes are in CONVERSATION_CONTEXT.md at lines 49, 70, 72, 76 and 9.
2. VERIFIED (arithmetic). 18 x 6.6 = 118.8, which is within 120. 15 x 6.6 = 99.
3. WRONG INFERRED. "6-8 activations total ... at target" with 20 ships does not fit the code. Every ship activates in its side's turn (battle.js:359-362 resets each unit; battle.js:1128 `u.activated=true`), so 20 ships means about 20 activations per round.
4. WRONG OBSERVED. "OBSERVED (brief): the difficulty dial has 5 notches" is mislabelled. The 5 notches are a proposal (difficulty_dial_synthesis.md:10). Code has 7 HEAT toggles (data.js:374-381).

barge_upgrade: 61 lines ("PROPOSED QUESTION: What manifest landmar").
1. STALE OBSERVED. The retired cyan law appears 8 times. Line 23 says "Cyan means shields and nothing else is cyan", and line 33 says shield hits use cyan. At HEAD the Corsair shield is red: ships3d.js:5 `shield:new C3(.85,.16,.1)`, read through shCol (fx3d.js:3).
2. VERIFIED OBSERVED. C19_51 is the Corsair Battle-barge (ships3d.js:707), the only VSM hull (ships3d.js:764 `AI_VSM=new Set(['C19_51'])`), and has glow #e0402c (data.js:115). There are 36 hull codes in hulls/, and FAC3D is the colour source (ships3d.js:2).
3. WRONG OBSERVED. Line 45 says the "flat-black silhouette-sheet test ... reads as the faction at a glance". That merges two tests: the at-a-glance test uses the lit hero shot (DS acceptance:67).
4. UNCHECKABLE. No .vsm or *_kit.json files are in the repo (the loader path exists at ships3d.js:771). Whether all 36 hulls load was not run.

## Not checked
- Whether the 18 plates or the Chorus portraits are in the repo (they are not here).
- Hull triangle counts behind the "2,400 to 38,000" figure.
- The Chorus trim material's metallic setting in the shader.
- The colour of the prow chevron material slot (fx3d.js:28).
- Runtime loading of the hulls, and whether the 5 time-limited Qwen legs are still pending.
