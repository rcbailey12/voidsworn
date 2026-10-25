# Findings registry

Owner: Opus. Started Oct 24 2026 at main d5d0227 (game code unchanged since Oct 22).

This is the single list of what is true, wrong or open about the game and the design record. Rules:
- Every new claim from Rey (Muse), DeepSeek, Qwen or Gemini enters as UNVERIFIED and is checked before anything is built on it.
- A fix updates its row in the same commit.
- Detail and quotes: `verification-report-2026-10-24.md` and `evidence/`.

**Verdicts:**
- VERIFIED: true at the stated commit.
- WRONG: false, with the correction.
- STALE: true once, superseded.
- UNCHECKABLE: says what would check it.

**Status:**
- OPEN: needs work.
- FIXED: done.
- DECIDED: a ruling or technical call settles it.
- INFO: a fact to keep in mind.

## Decisions taken Oct 24 (Ryan)

| ID | Decision |
|---|---|
| R1 | Battle size grows over a run: about 10, 14, then 20 ships on board. 20 is a guide, not a cap. Difficulty decides. Your fleet stays small and elite (4 to 7 ships). Wings do not count. |
| R2 | The dead-star gravity-well board stays. The Dead Star painting is its backdrop and a finale backdrop. |
| R3 | Shields keep their faction colours. The cyan-only shield rule is retired for 3D shields. Interface shield bars stay cyan. |
| R4 | Capture: boarded enemies switch sides in battle. After a win each prize gets add, strip or ransom. A full fleet auto-scraps. Sector flagships cannot be captured. |
| R5 | Engine: the barge is built engine-neutral. The test is 6 flagships, one per faction, in both Babylon and Godot. Copying up to about 20 ships is optional. Ryan and Opus pick before ship 2. A downloadable app is fine if Godot wins. |
| R6 | Acceptance is Ryan's eye plus automatic checks. No viewer panels. |
| R7 | One enemy commander per run is both the Nemesis and the story rival. |
| R8 | The barge gets the Corsair rust-and-bone palette. Naval reads are removed from the whole hull shape, not just the parts; mast and funnels become antenna arrays and heat radiators. |
| R9 | Portraits go on the near backlog. Three height bands for 3D space go on the near backlog. Neither is part of this pass. |
| R10 | The repo stays public. Sound stays as is, Sonniss clips included. |
| R11 | Plan approved (contrib/opus/go-forward-plan.md). The old two-helper limit is retired. |
| R12 | Barge shape (A1 step 1, Oct 24 late): option C, the double-sided hulk (diamond bow, matching blocks top and bottom, side engine pods, fins up and down), with some of option B's salvage junk bolted on (a stolen block, mismatched engine pods) so it reads Corsair. Renders: docs/ship_pipeline/c19_example/a1_options/. |
| R13 | Barge v15 shape and kit approved (A1 step 2, Oct 25 morning): "Yes, go to paint". Step 3 (paint and material texture) is next; the plating reading faint and the plain top surface in-game are its targets. |
| R14 | Barge paint approved (A1 step 3, Oct 25): bolted stolen panels in rust, Hegemony grey, bare steel and bone; "Yes, on to effects". Painted patch cells were tried and dropped (they read as warship dazzle camouflage, a naval tell). |
| R15 | Oct 25, 09:06: Ryan OK'd installing Godot (portable) for the A2 engine test, which starts alongside the end of A1. Ryan, 09:07: follow the entire plan from the handoff and the GitHub plans, stopping only at the weigh-in points. |

## Premises and rulings checked against the game

| ID | Claim (source) | Verdict | Evidence | Status |
|---|---|---|---|---|
| F1 | "Current scale around 20 ships" (CONVERSATION_CONTEXT.md:49; council audit; density draft) | WRONG | Measured: sector 1 about 7 (max 10), sector 2 about 9 to 10 (max 12), sector 3 about 9 to 12 (max 13). Enemy list capped at 8 (battle.js:147). Enemies never outgrow the player (battle.js:136). | DECIDED (R1), work in B2 |
| F2 | Late-fight waits 95 to 120 s | VERIFIED, refined | Campaign sim "new" model: 46 to 132 s per battle, about 11 to 15 s per round at today's sizes | OPEN (B2: speed first) |
| F3 | Density draft: "6 to 8 activations per round at 20 ships" | WRONG | Every ship activates every round (battle.js:359-362), so 20 ships means about 20 activations | INFO |
| F4 | Density "12 vs 15 wait inconsistency" (OPUS_HANDOFF.md:60) | WRONG | Draft table: 12 s is the target, 15 s the hard gate | DECIDED (12 target, 15 limit) |
| F5 | Dead Star "not a gravity well mechanic, no new engine work" | WRONG premise | Well ships today: battle.js:272-277, 305, 343, 374. Board shape in 6 of 8 fight types (battle.js:58-65). | DECIDED (R2) |
| F6 | "Cyan means shields" as current state (Argon packs, barge draft) | WRONG as current state | Shields are faction-coloured (fx3d.js:3, :32). The tutorial says "Cyan is shields" (ui3d.js:625). The hex grid is cyan (scene3d.js:254). Rare is #62ccff (data.js:386). | DECIDED (R3). Tutorial line FIXED (0fe88b8: points at the cyan shield bars, bubble in faction colour). Enemy markers FIXED (7f03908: fx3d.js `FOE_C` violet, worst-case colour-blind distance 0.42 from all six shield colours, the gold ring and friend green; broken hex outline for enemies, ui3d.js `fpHexMeshBroken`; nameplates in head.html). Note: Epic rarity is also violet (#c58bff). |
| F7 | Amber shield-state ramp | Conflict | Amber already means hull (fx3d.js:2, HULL_HEX #ffae42 at :4) | DECIDED: low shields shown as gaps in the faction colour |
| F8 | Six factions get shield effects (art_direction_rey.md:96; QA and beauty specs) | WRONG | Chorus (0 of 8 hulls) and Deathless (0 of 6) have no shields | INFO |
| F9 | "The motion rule rewards staying still" (OPUS_HANDOFF.md:62) | WRONG | Base rule: +10 to hit a still ship (battle.js:390, 458, 469). Only boon i_still (data.js:398) rewards stillness. | DECIDED: sync does not stack with i_still |
| F10 | Capture rules | VERIFIED gap | Prizes always join after a win with no command point check (campaign3d.js:81). Player ships cannot be captured (battle.js:674-675). "Strip" and "ransom" were undefined. | DECIDED (R4), work in B2 |
| F11 | Reanimate exists (DeepSeek), or is an engine ask (Rey) | DeepSeek VERIFIED | battle.js:702: once per battle, 20% enemy / 35% player, back at 30% hull. All Deathless hulls have reanimate (data.js:96-98). Heat h_undying (battle.js:314). Deathless do have crew (battle.js:81). | INFO (report gate satisfied) |
| F12 | Epic rarity is "gold-adjacent" (gold law; art direction) | WRONG | Only 3 tiers: Common #cfc6b0, Rare #62ccff, Epic #c58bff, which is already violet (data.js:386) | DECIDED: Rare moves off cyan; Epic stays |
| F13 | Gold law assumes a white selection ring and a faction chevron flagship marker | WRONG | Ring is gold (ui3d.js:238). Flagship ring is a gold torus (fx3d.js:70). 64 uses of the gilt class (#d0a64b) in UI code. | OPEN (gold-law work, screenshots for Ryan) |
| F14 | Corsair glow #e0402c, Voidsworn trim #c8501f as "observed" | Mixed sources | Those are data.js FACTIONS values (data.js:115, 111). FAC3D, the agreed single source, differs: Corsair engine C3(1,.38,.16), Voidsworn trim #9c3a1c (ships3d.js:3, 5). | OPEN (palette unification) |
| F15 | Torpedoes travel and herd movement | WRONG for today | Hit is rolled at launch (battle.js:589); 0.55 to 1.15 s flight visual (wfx3d.js:365-380); damage after the visual (battle.js:597-604), all in one activation. Range 6 (5 Star torpedo), cooldown 2 (data.js:8, 15, 20). | DECIDED: next-turn impact with a lane, in B3 |
| F16 | Crits are 2-round effects (handoff paraphrase) | WRONG on engine | Engine crit is -1 speed, stacking, for the rest of the battle (battle.js:561; reset only on repair, :541). Shield crit stops regen 2 turns; weapon crit is 2 turns; fire is 2 ticks of 6. Nothing persists past the battle. | INFO (fits "soft and current") |
| F17 | Crit revives destroyed systems | VERIFIED bug | A weapon or shield crit sets off=2 or shieldOff=2 over a section-destroyed 999 (battle.js:562-563 against 547-548) | FIXED (B1: battle.js `systemDamage` turns a crit on a destroyed system into a fire; b1_tests F17; 0fe88b8) |
| F18 | 1.32 GB texture figure "asserted without derivation" | WRONG | Derived as the phone figure (contrib/rey/reviews/ship-pipeline-audit.md:435-439). Real hulls_hi maps: worst 20 different hulls about 0.82 GB uncompressed, about 0.2 GB compressed. | DECIDED: figure retired |
| F19 | Tonemapper test with AgX | WRONG for Babylon | Babylon 8.20 offers Standard, ACES, KHR PBR Neutral. The game uses ACES (scene3d.js:29), bloom threshold 0.5 (:27). | DECIDED: ACES vs Neutral in Babylon; AgX only in Godot |
| F20 | The game shows admiral portraits | WRONG | No portrait code in any build file | INFO (portraits on backlog) |
| F21 | Battle rules run without a renderer | VERIFIED | sim3d.js evals data.js, core.js, battle.js (about 216 KB). The renderer and interface are about 780 KB, not counting sound data. | INFO (engine call input) |
| F22 | Voidsworn carrier ban (price ladder) | Conflict | Breaks Commodore Ashgrove, carrier doctrine, starts with a Reliquary (data.js:204) | DECIDED: carriers stay, priced up |
| F23 | Corsair gate "missile or bombard kind" | WRONG premise | Kinds are only battery, flak, lance, torp, bio, gauss, sq | DECIDED: "no lance-kind weapons" |
| F24 | A threat budget or fleet power must be invented (difficulty dial) | WRONG | fleetPower (battle.js:122), per-sector budget (battle.js:133), BOSS_SCALE and BOSS_FAC exist. Runs end at sector 3 (campaign_run.js:311). | INFO (the B2 ramp builds on these) |
| F25 | AI default comes from aiVet() | WRONG | `let AI_LEVEL='veteran'` (campaign3d.js:3) | FIXED (B1: campaign3d.js defaults to Standard; main3d.js keeps Veteran for players with runs played and no saved choice; 0fe88b8) |
| F26 | "No enemy-turn signal" | WRONG | The top bar shows "Enemy activation" (ui3d.js:86) | FIXED (B1, 7f03908: ui3d.js `aiChip` \"Enemy acting\" chip, the acting ring breathes, Threat tip from round 2) |
| F27 | Onboarding fix 10 (single-weapon keys) | Already done | ui3d.js:626 | FIXED |

## Baseline numbers (B0, Oct 25, game code at d5d0227)

Full tables: `compute/balance_reference.md` and the CSVs beside it. Every later balance change is compared against these.

| ID | Finding | Evidence | Status |
|---|---|---|---|
| S1 | The game is stable in the sim | fuzz 2000: 0 exceptions, 0 rule breaks; about 19,500 sim battles in all, 0 crashes, 3 timeouts in the campaign's 2,400 | INFO |
| S2 | Elites are the difficulty wall, not bosses | Campaign sim: elite wins 84% (s1), 52% (s2), 64% (s3); bosses 82%, 79%, 98% | OPEN (B2 ramp) |
| S3 | Waits already reach about 130 s per battle at today's sizes | Campaign sim "new" timing: 40 s (s1 battle) to 130 s (s3 elite) | OPEN (B2: speed before size) |
| S4 | Wide faction spread in skirmish | matrix 50: Corsair 98 avg, Chorus 93, Ithar 90, Voidsworn 69, Deathless 62, Hegemony 59; Deathless vs Corsair 14%. Player bot edge is large in this mode (mirrors 78 to 100%). fmatrix spread is moderate (57 to 68). | OPEN (B3) |
| S5 | Starting fleets cannot beat sector 2 or 3 bosses | bossmatrix with start fleets only: 71% (s1), 24% (s2), 3% (s3). Growth over a run carries the whole difficulty curve. | INFO (B2 ramp input) |
| S6 | Hegemony boss is the hardest opener; Grax the weakest start | bossmatrix s1: vs Hegemony 47%; Grax 36%, Vex 54%; Voice and Vesh 94% | OPEN (B3) |
| S7 | The bossmatrix harness only covers sector 1 by default | Sector comes from env BS (sim3d.js:325); sectors 2 and 3 were run with BS=2 and BS=3 | INFO |

## Bugs at d5d0227

| ID | Bug | Verdict | Evidence | Status |
|---|---|---|---|---|
| B-1 | Save-brick class | VERIFIED | `repairRunIds` (core.js, from `normalizeRun`) checks every saved id; `migrateMeta` refills null containers; raw save kept as `voidsworn.v1.repaired`; Continue falls back to "Start fresh (keep a copy)" (campaign_meta.js). b1_tests B-1a to B-1f. bf0fc0b | FIXED (B1) |
| B-2 | Retreat dialog lets the keyboard play on; "Jump out" turns a finished win into a retreat | VERIFIED | ui3d.js `onKey` ignores battle keys under a dialog; campaign3d.js `c3retreatYes` checks over, busy, finished and ending; `endBattleFlow` closes an open retreat question. b1_tests B-2. 258ce02 | FIXED (B1) |
| B-3 | Reload bug 1: mid-battle reload eats the node | Looks FIXED | Scripted: no run save in battle.js or ui3d.js; the only save there is meta-only. b1_tests B-3. d35f702 | FIXED (confirmed) |
| B-4 | Reload bug 2: reload during reward screens loses boon, refit, relic | VERIFIED | campaign_run.js marks the node done when rewards are banked and keeps pending picks as `RUN.reward` with fixed offers; `resumeReward` after reload; event fights seeded (campaign3d.js). b1_tests B-4, reload at every step. d35f702 | FIXED (B1) |
| B-5 | Captured flagship joins the fleet past the cap; selling it makes credits NaN | VERIFIED | battle.js `captureChance` 0 for sector flagships, boarding cripples but never flips them; campaign3d.js scraps prizes past the cap; core.js `shipValue`/`prizeScrap`; NaN credits repaired on load. b1_tests B-5. 0fe88b8 | FIXED for B1 (add, strip or ransom still B2) |
| B-6 | Free blink teleport after a stalled animation | VERIFIED | battle.js blink sets the cooldown even when its animation stalls. b1_tests B-6. 0fe88b8 | FIXED (B1) |
| B-7 | Nova cooldown spent by an abandoned cast | VERIFIED | battle.js Nova cooldown set only after the blast lands. b1_tests B-7. 0fe88b8 | FIXED (B1) |
| B-8 | Towing ignores the command point cap | VERIFIED | campaign_run.js tow offered only under the command cap, checked again on pick. b1_tests B-8. 0fe88b8 | FIXED (B1) |
| B-9 | Zero-fleet win recorded as a loss | VERIFIED | campaign3d.js `finishBattle`: a win with an empty fleet gets a garrison ship and goes to rewards. b1_tests B-9. 0fe88b8 | FIXED (B1) |
| B-10 | Reserve captain overwrites a hired veteran | VERIFIED | campaign3d.js: a reserve captain skips hired veterans; hull re-derived for the new captain. b1_tests B-10. 0fe88b8 | FIXED (B1) |
| B-11 | Alternating-mode fire check ignores its return | Latent | ui3d.js direct fire: `if(!guard(s)) return;`. b1_tests B-11. 0fe88b8 | FIXED (B1) |
| B-12 | Watchdog leaves B.activeUnit set | Latent | ui3d.js:667; no softlock in practice | INFO |
| B-13 | Legacy shop has no buttons | Dead UI | main3d.js:11 unlocks every legacy upgrade and admiral free on boot (matches Ryan's no-grind wish) | INFO |
| B-14 | Sim harness crash | VERIFIED | sim3d.js:112 `OBJS_SEEN[B.obj.type].w++` on an unseen type | FIXED (d88035a, guard as in the plan section 10) |
| B-15 | Council chair's top 10 | None done in code | evidence/bugs_at_d5d0227.md | OPEN (B1 covers 1 and 2; others in later phases) |
| B-16 | Every AI hull vanished on its first damage below 80% hull, until the cloned damage material's shader compiled (seconds on software GL, likely a blink on GPU) | VERIFIED Oct 25 (closeshot probe on Ryan's PC: barge and hulk-carrier invisible at 0.7 s and 1.8 s after damage, visible again at 12 s) | gfx3d.js `shipDamageFx` swapped materials before they were ready. Fix 334adbd: the intact material stays until the damaged one is ready. | FIXED (334adbd), PC re-check pending |

## The record: documents and data

| ID | Claim (source) | Verdict | Evidence | Status |
|---|---|---|---|---|
| D1 | Barge v14 files in the repo (READING_PLAN.md:9; pipeline README:58, :64) | WRONG at d5d0227 | No .vsm or _kit.json was in git. Oct 24: all 9 v14 files committed to hulls_hi/ (95f01b6) and the medium-quality set to hulls/ (a687ef5; ships3d.js:800 loads hulls/ on medium). The PC's 21 build inputs and the barge files match git byte for byte; side-by-side in docs/ship_pipeline/c19_example/a0_repo_vs_pc.webp, PC console errors: none. | FIXED (A0) |
| D2 | Barge "done end to end" (pipeline README:6) or "awaiting verdict" (SHIP_QUEUE.md:17) | STALE | v14 verdict "it's pretty close" (NEXT.md:56): clean blocky parts, add real material texture | INFO (A1) |
| D3 | Kit script builds space-only parts | WRONG | c19_kit.py:173 mast with yards, :160 funnels, :38 keel line, :403 keel plate. AUDIT_SYNTHESIS.md:208-218 prescribes bollards, yards, crow rail, ladder. :163 allows stern guns. | OPEN (A1 removes them) |
| D4 | Cyan-only shield hard-fail tests | STALE (R3) | beauty_corner_spec.md:77, :95; visual_qa_pack.md:7, :76, :145, :214 | DECIDED: ignore |
| D5 | Beauty corner triangle range 2,400 to 38,000 | STALE | Conflicts with "no artificial triangle limits" and the barge's 1.5 to 2 million triangle build | DECIDED: retired |
| D6 | Six terrain kinds (beauty_corner_spec.md:24; art_direction_rey.md:62) | WRONG | Five kinds (battle.js:193) plus the dead-star board shape | INFO |
| D7 | Phone framing | STALE | graphics_craft.md (20 "Phone cost" lines), visual_expansion_research.md (about 71 mentions); tool_guides.md framing already re-tiered (834bcb6) | INFO |
| D8 | glTF, .glb and gltfpack recipes (tool_guides.md:89, :183, :557; visual_expansion 4.1) | WRONG for this game | The game loads its own JSON plus WebP hulls (ships3d.js:801); no glTF loader | INFO (Godot test exports only) |
| D9 | KTX2 setting `JSModuleURL` (tool_guides.md:274, :502) | WRONG | Babylon 8.20 uses `KhronosTextureContainer2.URLConfig` | INFO |
| D10 | "FXAA off with MSAA" (visual_expansion:175) | Contradicts code | The game runs both (scene3d.js:26) | INFO |
| D11 | Quaternius is CC0 (GRAPHICS_REFERENCES.md:127; field guide :31, :253; Rey batch 8) | STALE | quaternius.com/license.html: QAL v1.0 (Aug 28 2026) | DECIDED: not used |
| D12 | Official Blender Lab MCP as the standard | Blocked | Needs Blender 5.1+; the PC runs 4.5.14 | DECIDED: community blender-mcp trial |
| D13 | Code index "1,016 definitions" | WRONG | 1,021 (5 missed on shared lines); zero duplicates VERIFIED | INFO |
| D14 | Content census, asset inventory (553 files, 157.5 MB), 36 hulls in both tiers | VERIFIED | evidence/compute_and_review_citations.md | INFO |
| D15 | Check pack and compute CSVs are runnable | WRONG as committed | Stored as base64. Decoded and adopted at contrib/opus/tools/checkpack (d88035a); checks.js now finds the repo root from that folder. 0 FAIL, 15 CHECK. Muse's compute CSVs stay base64 (reference only). | FIXED (check pack) |
| D16 | Independent audit counts and the finishBattle claim | WRONG on 3 | Hulls are 33 plus 12 variants; boons 36; finishBattle sets B.finished itself (campaign3d.js:66). The retreat hole is still real. | INFO |
| D17 | Rey's ship pipeline audit claims | STALE on 7 | Fixed since: kit self-light 0 (ships3d.js:790), kit material cloned (:788), error callback (:789), joint paint solve, procedural hull disposed (:827) | INFO |
| D18 | CLAUDE.md "0.3 paint self-light" | STALE | Default is now 0 (ships3d.js:790) | FIXED in CLAUDE.md, Oct 24 |
| D19 | HANDOFF.md "repo private" | WRONG | The repo is public by Ryan's choice (R10) | FIXED in HANDOFF.md, Oct 24 |
| D20 | Image manifest "local only, not in repo" | Half right | The manifest is in the repo (contrib/muse/design/IMAGE_MANIFEST.md); the 40 images are local only. Chorus rows are superseded. | INFO |

## Research and outside models

| ID | Claim | Verdict | Evidence | Status |
|---|---|---|---|---|
| X1 | Batch 7 "no substantive conflicts" | WRONG | The legs disagree on hitstop, shake, wind-up and rim light; the handoff kept DeepSeek's values every time | INFO (all tuned on screen) |
| X2 | Godot 6-week claim | UNCHECKABLE | Qualifications exist only in OPUS_HANDOFF.md:111; DeepSeek's batch 1 file presents it unqualified; the post is blocked | INFO (do not cite) |
| X3 | Batch 6 "separate metal and roughness maps are silently dropped" | WRONG for Blender 4.5 | The exporter combines them unless "Keep Original" is on. Bump maps are indeed never exported. | INFO |
| X4 | KHR_materials_variants "keeps both engines open" | Half true | Babylon's loader supports it; Godot's importer does not | INFO |
| X5 | DeepSeek "PBRMaterial.ormTexture" | WRONG | No such property; the game uses metallicTexture flags (ships3d.js:65-67) | INFO |
| X6 | DeepSeek 1,500 draw calls "from Babylon docs" | UNSUPPORTED | Not in Babylon's optimisation page | INFO |
| X7 | Electron "120 to 160 MB runtime per OS" | WRONG framing | It is a one-time build-machine download (gameshipper README) | INFO |
| X8 | Batch 4 "1942" correction | Misattributed | The legs cite different things (WWII doctrine against the arcade game). The "better precedent" line is the chair's own. | INFO |
| X9 | Batch 2 "DeepSeek corrected its Godot framing" | Misattributed | Rey inserted "CHAIR CORRECTION" notes into a file labelled verbatim | INFO |
| X10 | Batch 8 sources | Weak | No links in either leg; every price and licence claim is unchecked as filed | INFO |
| X11 | Qwen second legs (price ladder, plate mapping) | PENDING | Retry Oct 25, about 09:45 CDT | OPEN (re-verify when filed) |
