# Voidsworn takeover: verification report (first return)

Opus, Oct 24 2026. Repo: main at d5d0227, identical to GitHub main. Game code last changed Oct 22 (b6c4b93), so every review written Oct 23 and 24 was checking the same code I checked.

## Verdict

The pile is useful as leads, and most code citations hold. But four premises that plans were being built on are wrong when checked against the game itself:

1. **Battle size.** "Around 20 ships" is described as today's scale. Today's battles are about 7 to 13 ships.
2. **Dead Star.** The ruling treats a gravity well as new work. A dead-star gravity well already ships.
3. **Shield colour.** The colour law is written as if shields are cyan today. In 3D they wear faction colours, while the tutorial tells players cyan.
4. **The Pyre-Barge.** It is the first commission, but its current files are not in GitHub. They exist only on your PC, and its build script still adds sea-ship parts.

A fifth thing is a real defect rather than a wrong premise: the save-brick bug class the council ranked first is still in the code, along with the retreat dialog hole and one of the two reload bugs (A4).

- **Most consequential error:** the battle-size baseline (finding A2.1). Density gates, the difficulty dial, performance budgets, the texture estimate and the engine test all assume about 20 ships as the norm. The real game runs about half that, with an enemy cap of 8, and is already at the proposed wait limit.
- **Highest-risk unverified assumption:** that the game can hold its target battle (about 20 detailed ships plus the full effects pass) at a smooth frame rate on your PC. No measurement exists, in either engine. The engine choice, the kit budgets and the effects pass all rest on it, so it gets measured first.

## Your answers (Oct 24, 21:44 and 21:49 CDT)

- **1A.** Battles grow over a run: roughly 10, 14, then 20 ships, with your fleet small and elite. 20 is not a hard cap; difficulty should make sense.
- **2A.** The dead-star gravity well stays. The painting is its backdrop and a finale backdrop.
- **3B.** Shields keep their faction colours. The cyan-only rule is retired for 3D shields.
- **4A.** Boarded enemies switch sides in battle. After a win: add, strip or ransom; auto-scrap when full; no flagship capture.
- **5A, revised by you.** The barge is engine-neutral. The engine test is 6 different flagships (one per faction) in both Babylon and Godot. Copying up to about 20 ships is an optional last step.
- **Defaults agreed:**
  - your eye plus automatic checks;
  - one enemy commander serves as the Nemesis and the story rival;
  - rust-and-bone barge;
  - naval reads removed from the hull shape too, not just the parts;
  - portraits on the backlog;
  - the repo stays public.

## Follow-up answers (Oct 24, 22:07 to 22:13 CDT)

- **Sound:** stays as is, Sonniss clips included.
- **Engine crits:** Ryan did not raise it. The read that battle-long engine damage fits "soft and current" stands unless he says otherwise.
- **Height bands:** near backlog, not this pass.
- **The plan:** approved at 22:13 CDT.

## How I checked

- Read the handoff, reading plan, conversation context and notes in full, then the rest of the pile.
- Helpers did a first pass on each section in parallel. I re-checked every finding used below against the code myself.
- Ran the game's own headless simulation (the sim the earlier reviews used) on the current code:
  - ship counts per battle;
  - modelled animation wait per round;
  - a boss matrix run;
  - the decoded check pack (0 FAIL, 15 CHECK at d5d0227).
- Web checks only for load-bearing tool and licence facts, against official pages.
- **Your PC:** it came online late. I read file listings in `Downloads\voidsworn_test` (the barge v14 files are there; the mega sim folder is not), but the remote shell would not start.
- **Not checked at all:** the Blender install itself and the 40 local images.
- Labels: VERIFIED, WRONG, STALE or UNCHECKABLE; OBSERVED (seen) or INFERRED (reasoned).

## A1. Repo state

1. VERIFIED. Local and remote main are both d5d0227 ("Handoff: batch 8 complete...", Oct 24 19:14).
2. VERIFIED. No game file changed since b6c4b93 (Oct 22 13:02). The compute basis 51337c2 has the same game code as HEAD.
3. OBSERVED, flag. The repo is publicly readable: an anonymous clone works. HANDOFF.md line 6 says "(private)".
4. OBSERVED, flag. Many files are committed as base64 text, not plain files: `contrib/muse/tools/checkpack/checks.js`, `RUN_CHECKS.bat` and every CSV in `contrib/muse/compute/`. NOTES.md's encoding fix covered 18 files but not these. As committed, the check pack will not run. Decoded, it runs: 0 FAIL, 15 CHECK at d5d0227, the same as its Oct 23 result.
5. OBSERVED. The barge's current files are not in git. ships3d.js:764 marks C19_51 as the compressed-format hull (`AI_VSM=new Set(['C19_51'])`), but no `C19_51.vsm` or `C19_51_kit.json` is tracked. A build from the repo falls back to the old AI hull, so v14 exists only on your PC.

## A2. Rulings and premises checked against the game

Each item: what the record says, then what the code says.

**1. Battle size: WRONG baseline. OBSERVED, measured.** Resolved by your answer 1A.
- The record: CONVERSATION_CONTEXT.md:49 says "Target battle size stays near the current scale (around 20 ships)".
- I ran 60 battles per row with the harness's standard fleets on current code (`startBattle`, ships on board at the start, fighter wings counted separately):

| | Ships on board, average (max) | Your ships | Enemy ships |
|---|---|---|---|
| Sector 1 | 6.6 to 7.3 (10) | 4 | 2.6 to 3.3 |
| Sector 2 | 8.8 to 9.8 (12) | 5 | 3.8 to 4.8 |
| Sector 3 | 9.1 to 12.3 (13) | 5 | 4.1 to 7.3 |

- Enemy fleets are capped at 8 ships: battle.js:147 `while(budget>=1 && list.length<8`.
- They only ever shrink to match you: battle.js:136 "a strong fleet never meets more".
- Your fleet is limited by command points: 10 at start (+4 with unlocks), +3 per sector (core.js:278-281, campaign_run.js:312).
- INFERRED: with a full frigate-heavy fleet in sector 3 you could reach about 15 to 20 total, but that is the edge case, not the norm.
- Note: "ramp by more ships" (OPUS_HANDOFF.md:19) conflicts directly with battle.js:136, which deliberately stops enemies outgrowing you.

**2. Turn waits are already at the proposed limit: OBSERVED in the harness timing model, not on screen.**
- Campaign sim, 15 battles per row, using the current timing model ("new"):

| | Wait per battle | Wait per round |
|---|---|---|
| Sector 1 | 46 to 77 s | about 11 s |
| Sector 2 | 80 to 98 s | about 11 to 12 s |
| Sector 3 | 95 to 132 s | about 15 s |

- The density draft's target is 12 s per round, with a hard gate of 15, at 20 ships. INFERRED: doubling ships at today's animation lengths roughly doubles the wait.

**3. The "12 vs 15 wait inconsistency": WRONG as stated. OBSERVED.**
- density_statement_deepseek_draft.md, table row "Animation-wait budget per round", reads "≤12 s/round target; ≤15 s/round hard gate".
- That is a target and a pass/fail line, not a contradiction. The real issue is item 2.

**4. Dead Star "not a gravity well mechanic, no new engine work" (OPUS_HANDOFF.md:38): premise WRONG. OBSERVED.** Resolved by your answer 2A.
- The well already exists, in battle.js:
  - `wellTick` (272-277): +1 move slingshot, a drag inward, and "Tidal stress" damage on the rim;
  - the AI avoids it (277);
  - set up on dead-star boards (305), with an in-game explanation (343), ticked each turn (374).
- The "Dead star" board shape is listed for 6 of 8 fight types (battle.js:58-65), on storm and graveyard maps (battle.js:51).
- The rest of the record assumed the opposite:
  - plate_mapping_synthesis.md (condition 2) prices a well as new engine work;
  - gemini_background_pack_argon_high.md:247 calls gravity "a NEW mechanic".

**5. Shield colour: the law describes a change, not current state. OBSERVED.** Resolved by your answer 3B: faction colours stay.
- In 3D, shields wear faction colour: fx3d.js:3 "shields wear their faction's colour", and the shield ring uses FAC3D shield colour (fx3d.js:32). Voidsworn shields are orange, Hegemony blue, Corsair red, Ithar jade.
- The tutorial says "Cyan is shields" (ui3d.js:625), and the UI shield numbers are cyan #62ccff (head.html:15).
- Other cyan in the game today:
  - the hex grid (scene3d.js:254, "a faint cyan grid");
  - one weapon effect's embers (wfx3d.js:209-210);
  - Rare rarity, also #62ccff (data.js:386).
- The art direction knows this and proposes the change (art_direction_rey.md:9-12). Later documents label the cyan law "OBSERVED" as if it were current state:
  - gemini_visual_ideas_argon_high.md:3;
  - gemini_background_pack_argon_high.md:17;
  - barge_upgrade_deepseek_draft.md, section 2.

**6. Amber already means hull. OBSERVED.**
- fx3d.js:2 reads "amber is always hull"; HULL_HEX is #ffae42 (fx3d.js:4); the tutorial teaches it (ui3d.js:625).
- The proposed shield-state ramp "cyan to amber to white-hot" (OPUS_HANDOFF.md:72) collides with hull, not only with gold.
- The Argon pack's amber beams and windows (#ffaa44, #ff944d) sit next to HULL_HEX.

**7. Only four factions have shields. OBSERVED.**
- Chorus 0 of 8 hulls and Deathless 0 of 6 have shields (census, data.js).
- WRONG:
  - art_direction_rey.md:96 gives Chorus and Deathless shield ripple styles;
  - the "six distinct shield reads" lead (OPUS_HANDOFF.md:106) can be four at most;
  - the Flash Gemini pack gives Deathless a cyan shield (gemini_visual_ideas.md:159).

**8. Motion rule: WRONG in the handoff. OBSERVED.**
- OPUS_HANDOFF.md:62 says "the motion rule rewards staying still".
- The base rule punishes it: a ship that did not move is +10 to hit (MOVE_BASE `still:10`, battle.js:390; motionHit 458; applied 469; the UI reads "Sitting still: +10 to hit", ui3d.js:451).
- Only the boon Anchored Volley (`i_still`, data.js:398) rewards a still ship.
- The onboarding synthesis gets this right, so the pile contradicts itself.

**9. Capture today. OBSERVED.** Resolved by your answer 4A.
- On a win, every captured ship joins your fleet with no command point check (campaign3d.js:81).
- Your ships can never be captured (battle.js:674-675, comment "your ships are never captured").
- "Strip" and "ransom" appear nowhere in the repo except OPUS_HANDOFF.md:21. "Scuttle" appears nowhere. "Derelict" came from the DeepSeek torpedo draft (line 179).
- So the fleet-cap rule and the strip-or-ransom ruling are unimplemented, and the terms are undefined.

**10. Reanimate report: done, VERIFIED. OBSERVED.**
- battle.js:702: once per battle, a dying Deathless ship has a 20% (enemy) or 35% (player) chance to come back at 30% hull.
- Every Deathless hull has `reanimate:true` (data.js:96-98), and the Heat option "Undying" extends it to all enemies (battle.js:314).
- DeepSeek's asymmetry claim is right; Rey's audit (which treated it as an engine ask) is wrong.
- Deathless do have crew (CREW_MULT 1, battle.js:81), so the proposed "boarding immunity" would be new.

**11. Rarity and gold: the repair targets the wrong item. OBSERVED.**
- RARITY (data.js:386) has three tiers: Common #cfc6b0, Rare #62ccff, Epic #c58bff. Epic is already violet. There is no legendary or mythic tier.
- So "epic recolor to violet-magenta" (gold_law_synthesis.md:43) fixes nothing. The art direction's Rare move to soft violet #b78cff (art_direction_rey.md:13) would make two violets.
- Gold in the UI is much wider than the five documents the repair lists:
  - 64 uses of the `gilt` class (#d0a64b) across UI code, including encounter names (campaign_run.js:55);
  - 16 uses of #f0b35a (captures, crew numbers);
  - Duo boons in #ffd27a (campaign_run.js:287).
- The real cost of the gold law is UI code.

**12. Corsair colours: the documents mix two palettes. OBSERVED.**
- The barge draft and the Argon pack treat glow #e0402c as observed. That is the data.js FACTIONS value (data.js:116). In 3D, Corsair engines use FAC3D `eng:new C3(1,.38,.16)` (ships3d.js:5), the orange that collides with Voidsworn.
- Argon's Voidsworn trim #c8501f is also the data.js value; FAC3D says #9c3a1c. The ruling is that FAC3D wins (CONVERSATION_CONTEXT.md:26).
- Read correctly, the art direction's Corsair shift (art_direction_rey.md:24) is a proposal to change FAC3D, not the current state.

**13. Tonemapping and lights today. OBSERVED.**
- ACES tonemapping (scene3d.js:29), bloom threshold 0.5 (scene3d.js:27), Babylon 8.20.0 (build.py:3).
- Fill light is about 19% of the key light (scene3d.js:21-22).
- Babylon offers ACES, Khronos PBR Neutral and Standard. It has no AgX.

**14. Torpedoes today. OBSERVED.**
- Range 6 (Star torpedo 5), cooldown 2 (data.js:8, 15, 20).
- Hit or miss is rolled at launch (battle.js:589). A 0.55 to 1.15 s flight plays (wfx3d.js:365-380), and damage lands after it (battle.js:597-604), all inside one activation.
- No torpedo stays in flight across turns.
- Proposals treating torpedoes and boarding as new systems are wrong, as the torpedo synthesis already says. Making the flight real is a rules change in battle.js.

**15. Texture memory: the 1.32 GB figure is mislabelled, not underived. OBSERVED.**
- It is derived in contrib/rey/reviews/ship-pipeline-audit.md:435-439, as the phone figure for 20 different hulls at an assumed 2048 map set; desktop there is 2.66 GB. ship_kit_upgrade.md:15 cites it as the 20-ship figure.
- My own measurement from the real files, `hulls_hi/` (two maps per hull; 38 at 2048, 26 at 1024, 8 at 512):
  - the worst 20 different hulls need about 0.82 GB uncompressed;
  - about 0.2 GB with GPU compression.
- The "553 files, 157.5 MB" inventory is disk size, so it is not comparable to either figure.

**16. Fun-only build. OBSERVED.**
- The game shows no admiral portraits anywhere: no portrait code in any build file. The Chorus portrait decisions block nothing in the build.

## A3. The handoff's known-traps list, item by item

1. **1.32 GB "asserted without derivation": WRONG.** It is derived, but as the phone figure and on assumed map sizes (A2.15). Still not to be reused, as the trap list says.
2. **Flash Gemini pack is leads only: VERIFIED, with one screening error.**
   - Invented admirals and hulls: VERIFIED ("High Castellan Vane", "Wrath of the Saint", gemini_visual_ideas.md Part B and Part D).
   - Deathless shield: VERIFIED (line 159). Deathless skull: VERIFIED (line 448).
   - "Invented patrons" is WRONG: Kharon, Vyre, The Hunger Below and Astra are real game patrons (data.js:388 onward).
   - The Argon High re-run is not as clean as filed. It labels data.js colours as observed FAC3D values, labels the cyan law as current state, and proposes amber accents next to the hull colour (A2.5, A2.6, A2.12). It still beats the Flash pack as a reference.
3. **Price ladder and plate mapping are single leg: VERIFIED.** Both files say so. The Qwen retry is not due until Oct 25, 09:45 CDT. Both also carry STALE text: the price synthesis still lists the Hegemony loss as open, and plate mapping assumes the dead-star well is new.
4. **Density 12 vs 15: WRONG** (A2.3). **20 and 24 as a leaning: VERIFIED.**
5. **Research batches are leads, with weak sources: VERIFIED.** Details in A5. The BG3 claim is correctly quarantined. The Godot 6-week qualifications appear only in the handoff; DeepSeek's batch 1 file still presents it unqualified.
6. **Phone-first framing:**
   - tool_guides.md framing was already re-tiered (line 7, commit 834bcb6). Its 13 remaining phone mentions are incidental, so the trap line and OPUS_HANDOFF.md:96 are STALE on that file.
   - visual_expansion_research.md (78 mentions, framed phone-first at line 3) and graphics_craft.md:5 ("phone first, desktop tier") still need the pass: VERIFIED.
7. **Portrait manifest "local-only, not in the repo": WRONG as worded.**
   - The manifest is in the repo: contrib/muse/design/IMAGE_MANIFEST.md, 40 images of which 9 are portraits. The images themselves are local only.
   - Its Chorus rows are STALE against OPUS_HANDOFF.md:33.
   - Voice v4 final, Matriarch v3 pending, and Mending needing new direction: VERIFIED as stated in the handoff.
8. **Mega sim Run 1 incomplete: VERIFIED from the record; the local folder is UNCHECKABLE (PC offline).**
   - The CampaignSim crash still reproduces on current code: sim3d.js:112, `OBJS_SEEN[B.obj.type]` undefined.
   - The one-line guard fixes it in a scratch copy, and the campaign sim then runs clean.
   - The boss matrix runs in the cloud (sector 1 in 35 s at n=1).
   - Decision in A10, item 1.
9. **Quaternius is QAL v1.0, not CC0: VERIFIED** on quaternius.com/license.html ("Last updated: 8/28/2026"). Caveat: older listings still say CC0, and the licence in force when files were obtained governs. Rey's batch 8 file still says CC0 with no note.

## A4. Reviews, compute data and the bug queue

**Compute data** (re-derived from the code, which is identical to its basis commit):

| Claim | Verdict | Detail |
|---|---|---|
| Content census (45 hulls, 25 weapons, 36 boons, 12 relics, 13 modules, 24 admirals, 8 encounters, 6 factions) | VERIFIED | |
| Asset inventory, 553 files and 157.5 MB | VERIFIED | |
| All 36 hulls in both tiers, 108 files per tier | VERIFIED | |
| Code index, "1,016 definitions" | WRONG | 1,021 with a real parser. Five definitions sharing a line with another statement were missed (for example ENC_SPECIAL, battle.js:66). The "zero duplicate names" part is VERIFIED. |
| "Only C19_51 has .vsm plus _kit.json" (READING_PLAN.md:9) | WRONG as a statement about files | Those files exist nowhere in git history. It is true only of the code list (ships3d.js:764). |
| Referential integrity, 4 of 6 spot checks | VERIFIED | |
| "bulwark is never referenced" | WRONG | sim3d.js:469 references it. |
| "All 12 legacy unlocks never referenced" | WRONG | They are read as META.unlocked.X, for example core.js:280-285. |

**Protocol reviews:**
- Code citations hold almost perfectly: plain parts 17 of 17, ship loading 14, battle rules 23 (one drifted by 4 lines), enemy AI 21, effects and world 14, UI 23.
- space_3d.md: its 14 citations hold, but its delta-v bands exist only as a proposal. There is no band or altitude state in code.
- independent_audit.md has 3 WRONG claims:
  - "34 hulls and 12 variants": it is 33 plus 12;
  - "37 boons": it is 36;
  - "finishBattle only guards on B.finished, which the normal flow never sets": finishBattle sets it itself, at campaign3d.js:66. The retreat hole it describes is still real.
- Rey's ship pipeline audit: 7 claims are STALE because the v55 audit fixes landed after it:
  - the 0.3 kit self-light (now 0, ships3d.js:790);
  - the bare kit material (now cloned from the hull material, :788);
  - the missing error callback (:789);
  - the separate paint solves (now joint, pixal_to_game.py:112-116);
  - the line count of c19_kit.py (555, not 319);
  - the procedural hull staying after a failed load (disposed first, :827).

**Bug queue at d5d0227** (helper read plus node probes; I re-read the key lines):

| Bug | Status | Where | Note |
|---|---|---|---|
| Save-brick class | PRESENT | renamed hull: core.js:180, :164; unknown relic: campaign_run.js:46; captain with no name: core.js:126; stale admiral: campaign_meta.js:196 | Each throws. A save holding `stats:null` still crashes the title screen (campaign_meta.js:38). |
| Retreat dialog | PRESENT | ui3d.js:484 (no open-dialog check); campaign3d.js:95 (no re-check of a live battle) | |
| Reload bug 1, node eaten by a mid-battle reload | LOOKS FIXED | | Nothing saves during battle, and continuing replays the seeded node (campaign_meta.js:42). Not tested in a browser. |
| Reload bug 2, reload during the reward screens | PRESENT | campaign_run.js:274 (salvage pick saves); :309 (node completes) | A reload in between loses the boon, refit and relic. Event fights still skip seeding (campaign3d.js:50). |
| Captured flagship joins your fleet | PRESENT | campaign3d.js:81 | No command point check. Selling one turns credits into NaN (campaign_run.js:181). Your answer 4A removes this. |
| Free blink teleport after a stalled animation | PRESENT | battle.js:944 | |
| Nova cooldown spent by an abandoned cast | PRESENT | battle.js:953 | |
| Towing past the command cap | PRESENT | campaign_run.js:272 | |
| Zero-fleet win recorded as a loss | PRESENT | battle.js:771, campaign3d.js:88 | |
| Reserve captain overwriting a hired veteran | PRESENT | campaign3d.js:99 | |
| Alternating fire-check bypass | LATENT | ui3d.js:410 | The return value is ignored, but the line sits inside the same check. Not exploitable today; a one-line fix. |
| Watchdog softlock | LATENT | ui3d.js:667 | No softlock in practice. |
| Legacy shop | DEAD UI, NOT MISSING | | No buy buttons, but main3d.js:11 unlocks every legacy upgrade and admiral free on every boot. That matches your no-grind wish, so not a bug. |
| Council chair's top 10 | NONE DONE IN CODE | | |

**Critical hits: the handoff paraphrase is wrong on durations. OBSERVED** (battle.js:554-565):
- **Engine hit:** -1 speed that stacks and lasts the rest of the battle (no countdown; reset only by section repair, battle.js:541). It is not a 2-round effect.
- **Shield hit:** stops regeneration for 2 turns. Existing shield points still absorb.
- **Weapon hit:** one gun out for 2 turns.
- **Fire:** 2 ticks of 6 hull.
- **New bug:** a weapon or shield crit on a system already destroyed by section damage (off=999) resets it to 2, so a crit can bring a destroyed system back (lines 563 and 562 against 547-548).
- **Section destruction** knocks systems out until repaired, within the battle.
- **My read:** nothing carries past the battle, so "soft and current only" holds. Battle-long engine damage and section knockouts fit "current". I fix the resurrection bug as technical work. If "temporary" meant a couple of rounds even for engines, say so.

## A5. Research batches 1 to 8 (both legs each)

**Proof of reading.** All 16 files were read in full, plus the handoff summaries. The line counts match the inventory: Rey legs 101 to 266 lines, DeepSeek legs 75 to 283.

**Where the legs disagree (all heuristics; none measured on this game):**

| Number | Rey leg | DeepSeek leg | Handoff kept |
|---|---|---|---|
| Hitstop, normal hit | 3 to 6 frames | 2 to 5 frames | DeepSeek |
| Hitstop, kill | none | 8 to 12 frames | DeepSeek |
| Shake length | 0.2 to 0.5 s | at most 0.25 s | DeepSeek |
| Shake decay | 4.0 per s | 1.0 to 1.5 per s | not stated |
| Wind-up (anticipation) | 18 to 36 frames | 6 to 12 frames | DeepSeek |
| Rim light | 25 to 50% of key | 50 to 80% of key | DeepSeek |
| Starting tonemapper | ACES | Neutral | "test item" |
| Draw call budget | 500 to 1,000 | 1,500 | not stated |

- Batch 7 is filed as "reconciled, no substantive conflicts", yet it takes the DeepSeek value on every row above.
- The 6 to 8 slot shield-impact buffer is DeepSeek only. Its own source calls it a heuristic, and the other sources range from 3 to 24. Rey's leg marked it "not verified, spike item", and the handoff dropped that caveat.
- The 10% / 2% / 0.5% screen-coverage budgets come from a truncated path to an AI-agent skill document.
- DeepSeek's 1,500 draw calls is credited to Babylon's docs. Babylon's optimisation page has no such figure.

**Handoff summaries that misstate their batch:**

1. Batch 4, "1942":
   - The legs cite different things: Rey's leg the 1942 WWII carrier doctrine, DeepSeek's the 1942 arcade game.
   - "World of Warships patrol fighters are the better precedent" is the chair's own conclusion, not in either file.
2. Batch 2, "project is Godot-based": the correction was inserted as "CHAIR CORRECTION" notes into DeepSeek's file (lines 173, 178, 200), a file labelled verbatim. The handoff says DeepSeek corrected itself.
3. Batch 1, Godot 6-week claim:
   - The qualifications (second-hand, unnamed project, no fixed scope, sceptical replies) exist only in OPUS_HANDOFF.md:111.
   - DeepSeek's batch 1 file (lines 117-119) presents "a playable game in six weeks" as an observed community report.
   - The Reddit post itself: UNCHECKABLE (blocked).
4. Batch 6, "two separate textures get silently dropped": WRONG for Blender 4.5's exporter, which combines separate metal and roughness images into one texture. The bump-maps-never-export part is VERIFIED.
5. Batch 2, "Cascadeur not found": DeepSeek's leg found Cascadeur 2026.2 with an MCP server. The handoff reports only Rey's result.
6. Batch 1, "Electron 120 to 160 MB runtime per OS": in the source that is a one-time download on the build machine, not what players download.
7. Batch 8, Quaternius: correct, but Rey's file still says CC0 (lines 109, 124-127) with no note.

**Spot checks against official sources:**

| Claim | Result |
|---|---|
| Godot Compatibility renderer lacks SDFGI and screen-space reflections | VERIFIED (Godot renderers doc, 4.4 and master) |
| glTF stores roughness in green, metalness in blue | VERIFIED (glTF 2.0 spec) |
| Babylon's TAA is a separate pipeline | VERIFIED (8.20.0 typings; the game builds it separately, scene3d.js:105) |
| Babylon supports damage-toggle variants (KHR_materials_variants) | VERIFIED |
| Godot's importer supports those variants | WRONG: it does not, so "variants plus keep both engines open" does not hold |
| Godot MultiMesh needs one identical mesh | VERIFIED |
| AgX as a Babylon test item | WRONG: Babylon has ACES, Khronos PBR Neutral and Standard only (Godot 4.4 has AgX) |
| Official Blender Lab MCP server exists | VERIFIED (blender.org/lab/mcp-server), but it needs Blender 5.1 or newer; your PC runs 4.5.14 (CLAUDE.md:3) |
| DeepSeek's "PBRMaterial.ormTexture" | WRONG: no such property. The game already wires its packed maps another way (ships3d.js:65-67) |

**Contradictions with the current game (OBSERVED):**
- Bloom threshold is 0.5, against the research's 1.0 to 1.2.
- The fill light is weaker than proposed, and there is no Fresnel rim on hulls.
- Hulls load from a custom JSON plus WebP format, with no glTF loader in the build. The "GLB as source" proposals assume a path the game does not have yet.
- Batch 5's "Voidsworn already has delta-v offsets" is false: it exists only as the space_3d.md proposal.
- Torpedoes: see A2.14.

**Weak sources:**
- Batch 8 has no links at all in either leg, so every price, count and licence claim in it is uncheckable as filed.
- Batch 7's DeepSeek leg has one full link out of 107 citations.
- Batch 5's DeepSeek leg cites 39 forum or Reddit sources.
- Treat every number in batches 5 and 7 as a starting guess to be tuned on screen.

## A6. Gemini packs (checked myself)

- **Flash pack.** See A3.2.
- **Argon High visual pack.** Usable for effect language and silhouette ideas only.
  - Do not take its swatches: they mix data.js and FAC3D values and propose amber accents.
  - Its "Deathless 4 hulls" undercounts: the game has 6 Deathless hull entries, 4 counting roster plus flagship.
  - Part D Chorus specs are already superseded by the DeepSeek regenerate briefs (handoff line 33).
- **Argon High background pack.** The five terrain anchors match battle.js:193 (VERIFIED).
  - Its Dead Star section (lines 235-247) is WRONG on mechanics (A2.4).
  - Its hex grid proposal is a change from today's cyan grid; the pack treats it as compliance.
  - Treatments are usable. The Babylon notes need re-scoping if the engine changes.

## A7. Syntheses and single-leg drafts

Every synthesis quotes its legs faithfully. The arithmetic checks out:
- the difficulty corrections;
- sRGB 128 to 0.2159 and the cap 0.0864;
- all 12 price ladder prices (nearest 5, ties up).

**What fails is premises against the code or against later rulings:**

1. **Gold law.**
   - Its base text assumes the selection ring is white and the flagship marker a faction chevron. Both are gold today: ui3d.js:238 `ringMesh(new C3(1,.75,.3)`; fx3d.js:70 is a gold torus.
   - The rarity ladder check is moot (three tiers, Epic already violet).
   - The migration list misses 64 gold uses in UI code.
2. **Difficulty dial.**
   - Its main open question is already answered: fleetPower (battle.js:122), the per-sector budget (battle.js:133), and the flagship scaling tables.
   - Its sector ramp runs to sector 5, but runs end at sector 3 (campaign_run.js:311).
   - Its plus-or-minus 2 ship offsets "against about 20-ship battles" are stale under answer 1A.
   - Notch 3 "Veteran" would clash with the existing AI toggle's name.
3. **Onboarding.**
   - The Veteran default comes from campaign3d.js:3, so the "change the aiVet default" option would do nothing.
   - "No enemy-turn signal" is wrong: the top bar shows "Enemy activation" (ui3d.js:86).
   - Fix 10 is already in the game (ui3d.js:626).
   - On PC, "Tap" wording is already swapped out (campaign_meta.js:13).
4. **Kit spec.**
   - Correction 3 says "five singletons"; there are six single-hull classes.
   - Its cyan gate is stale under answer 3B.
5. **Torpedo and boarding.**
   - boardUnit runs to battle.js:682, not 679.
   - The repel flag's source is known (set :669, cleared :371).
   - It is unfair to DeepSeek on "fuel": DeepSeek also used a fixed speed.
   - Its capture framing is stale under 4A.
6. **Asymmetry.** Three recommendations are stale against your rulings:
   - "no Ithar recharge now";
   - "change Hegemony least";
   - Chorus feed and reanimate still framed as open.
7. **Price ladder.**
   - The code has no per-faction price field: only a global multiplier (core.js:181), a global class unlock (campaign_run.js:139), and every Voidsworn hull carrying its own cost (data.js:61-66).
   - Several multipliers price classes a faction does not have (no Deathless or Hegemony carriers; no BB+ outside Voidsworn and Hegemony).
8. **Plate mapping.** "No well mechanic is defined anywhere" is WRONG (A2.4), and the "solar flare" hook already exists (battle.js:25, 376).
9. **Chorus regenerate draft.** It reintroduces "suture filaments", the stitching the reword legs flagged.
10. **Density draft.**
    - "6 to 8 activations at 20 ships" contradicts the code: every ship activates every round, so 20 ships means about 20 activations.
    - The 5-notch dial is labelled OBSERVED but is a proposal.
11. **Deathless wording draft.** It edits passage G, which your ruling keeps unchanged.
12. **Tool guides re-tier draft.** Its line numbers predate 834bcb6.
13. **Barge draft.** It cites the cyan law 8 times. Its other code claims hold.

## A8. Design documents

**Gate and rule problems:**
- **The cyan law is written as hard fail tests:** beauty_corner_spec.md:77, :95 and visual_qa_pack.md:7, :76, :145, :214. Under today's code, and under answer 3B, every shield shot fails.
- **Shield tests for shieldless factions:** both specs ask for shield-hit shots of Chorus and Deathless.
- **The beauty corner's triangle range** (2,400 to 38,000) contradicts your "no artificial triangle limits" and the barge's own 1.5 to 2 million triangle build.
- **Six terrain kinds:** beauty_corner_spec.md:24 and art_direction_rey.md:62 list six. The code has five plus the dead-star board shape.
- **graphics_craft.md** was never re-tiered: 20 "Phone cost:" lines.

**The barge record is stale:**
- README:6 says the barge is "done end to end"; SHIP_QUEUE.md:17 says it is awaiting a verdict.
- Your v14 verdict "it's pretty close" is in NEXT.md:56: clean up blocky undetailed areas and add real material texture.
- The kit script still builds naval parts: a mast with yards (c19_kit.py:173), funnels (:160), a hull "falling to the keel" (:38), a keel plate (:403).
- AUDIT_SYNTHESIS.md:208-218 prescribes bollards, yards, a crow rail and a ladder, all banned in BLOB_SWEEP.md:40.
- AUDIT_SYNTHESIS.md:163 still allows stern guns.

**The reference docs teach a pipeline the game does not use:**
- tool_guides.md and visual_expansion_research.md build recipes around .glb files and gltfpack. The game loads its own JSON and WebP hull files and has no glTF loader (ships3d.js:801).
- tool_guides.md:274 names the wrong Babylon 8.20 KTX2 setting: it is `URLConfig`, not `JSModuleURL`.
- visual_expansion_research.md:175 says FXAA should be off with MSAA. The game runs both (scene3d.js:26).
- Several Blender add-ons described as bundled have been separate downloads since Blender 4.2.

**Owner rulings missing from the reference docs:**
- Quaternius listed as CC0 (GRAPHICS_REFERENCES.md:127; field guide :31, :253);
- cyan-only shields in 7 places;
- sound called "the big gap", though Kenney and Sonniss clips shipped Oct 20;
- parallax and the glow layer pitched as new, though both are in the game;
- paid tools still listed.

**Sound licence (new flag).** sfx_data.js:1 embeds Sonniss GDC 2026 clips. The field guide (line 350) says their licence forbids handing the sound files to anyone else. A public repo arguably does that. Question below.

## A9. Not checked

- Anything on screen. All shield, wording and colour findings are from code, not the running game.
- Your PC beyond file listings: the remote shell would not start tonight.
- The mega sim's local run folder: not in Downloads\voidsworn_test. It is likely on Rey's side. Moot, because the legs rerun in the cloud.
- The 40 concept images and their hashes: not in the repo.
- Batch 8 vendor prices and licences: no links in either leg.
- The Reddit Godot post: blocked.
- Older Quaternius copies.
- Zero-K veterancy.
- Rey's hidden screening files and chair reconciliations: not in the repo.
- Full reads of the Gemini texture_pass and ship_pipeline_audit, and the Codex ship-model audit. These were spot-checked only.

## A10. Technical calls I have made

These are mine to make. Each is reported with its reason, and you can veto any of them.

1. **Mega sim: resume by leg, in the cloud, not a full rerun.**
   - Game code has not changed since Oct 22, so the legs that passed stand (checks, fuzz 2000, campaign 200).
   - The missing legs run on current code with the one-line crash guard: boss matrix, faction matrix, matrix, archetype matrix.
   - Output: balance_reference.md plus CSVs, as the "before" baseline.
2. **Wait budget.** A 12 s per round target and a 15 s limit, at every battle size. Battles get faster before they get bigger.
3. **Low shields** show as gaps and pulsing in the faction's own shield colour, not a colour ramp. Amber already means hull.
4. **Tonemapper.** A measured side-by-side of ACES (today) and Khronos PBR Neutral in Babylon, scored on how true the faction colours and Command gold stay. AgX is tested only in the Godot side of the engine test (Babylon lacks it). You give the visual verdict.
5. **Outside assets** are recoloured through the master material on import. No outside palette comes in raw.
6. **Corsair prohibition:** "no lance-kind (long-range) weapons", already true of their roster. The proposed "missile or bombard" kinds do not exist.
7. **Torpedoes:**
   - range stays 6 (5 for the Star torpedo), and the cooldown stays;
   - no magazine;
   - range 10 is rejected, since it would outrange every gun (the longest is 7);
   - the real change is a visible lane and impact on the next turn.
8. **Hegemony sync** will not stack with the Anchored Volley boon, the only thing that rewards standing still.
9. **Budgets.**
   - No per-hull triangle caps, per your "no artificial triangle limits"; the beauty corner's 38,000 limit is retired.
   - One frame-time check on your PC decides.
   - The 1.32 GB figure is retired. Real files say about 0.82 GB uncompressed or 0.2 GB compressed for the worst 20 different hulls.
10. **Kit proof ship:** the Pyre-Barge, not the Basilica. Your ruling outranks the kit synthesis.
11. **Blender automation:** the community MCP server on your Blender 4.5.14. The official one needs 5.1, so adding a separate 5.1 install is decided after one test. Nothing is installed in this phase.
12. **Check pack** adopted: decoded from base64 into my folder once you approve the plan.
13. **Tool guides decisions D1 to D9:**
    - D1 already done (834bcb6).
    - D2 replaced by item 9.
    - D3: draw call targets come from our own measurement.
    - D4: LOD stays, inside one desktop tier.
    - D5: gltfpack simplification off for hero hulls, and only if a glTF path is ever added.
    - D6: WebGL2 stays the default if Babylon stays.
    - D7: phone-chosen values replaced by measured desktop values.
    - D8: the phone parenthetical dropped.
    - D9: proceed, with Blender 4.5.14 from CLAUDE.md.
14. **Rarity colours.** Rare moves off the interface's shield cyan, to a hue clearly apart from both cyan and Epic's violet. Gold stays for Command and patrons. The 64 gold uses in the interface, the gold selection ring and the gold flagship ring are audited as part of the gold-law work, and you see screenshots.
15. **Voidsworn carriers stay, priced up.** A carrier ban would break Commodore Ashgrove, whose kit is carriers (data.js:204).
16. **Crit resurrection bug gets fixed** (A4). Crit rules otherwise stay as they are.
17. **Corsair red shields against red enemy markers:** enemy markers get a shape plus a colour no faction shield uses. The shields keep their colour (answer 3B).
18. **Barge files into git first** (plan phase A0). Found on your PC: `Downloads\voidsworn_test\build\hulls_hi\C19_51.vsm`, `C19_51_kit.json` and the kit and finish maps.

