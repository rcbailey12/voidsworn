# D1 design-document verification (HEAD d5d0227, read-only)

Method: every file below read in full with Read or cat -n; code checked with grep -n / sed -n | cut. Verdict keys: VERIFIED, WRONG, STALE (true once, overtaken by later edit or owner ruling), UNCHECKABLE. Each finding marked OBSERVED (seen in a file) or INFERRED (reasoned from observed facts).

## Proof of reading

| # | File | Lines | First 40 chars of last line |
|---|---|---|---|
| 1 | contrib/muse/design/art_direction_rey.md | 157 | `Pushed to contrib/muse/design/ Oct 23, 2` |
| 2 | contrib/muse/design/ship_kit_upgrade.md | 44 | `No hand-measured coordinates for new hul` |
| 3 | contrib/muse/design/beauty_corner_spec.md | 126 | `This spec was first written phone-first ` |
| 4 | contrib/muse/design/visual_qa_pack.md | 225 | `This pack was first written phone-first ` |
| 5 | contrib/muse/design/graphics_craft.md | 108 | `Babylon's exact tone mapping type names ` |
| 6 | contrib/muse/design/design_council_audit.md | 96 | `One recommended next step: build loft v2` |
| 7 | contrib/muse/design/CONVERSATION_CONTEXT.md | 76 | `Oct 24, 2026 refinement: Ryan stated the` |
| 8a | docs/ship_pipeline/README.md | 83 | `- Game frame: bow +x, up +y, port +z. Ba` |
| 8b | docs/ship_pipeline/SHIP_QUEUE.md | 51 | ``Concept paintings: `Downloads\voidsworn_`` |
| 8c | docs/ship_pipeline/BLOB_SWEEP.md | 63 | `  - the seam between rebuilt parts and t` |
| 8d | docs/ship_pipeline/GRAPHICS_REVIEW.md | 24 | ``  material on the visible clone (`ship.s`` |
| 8e | docs/ship_pipeline/TEXTURE_PASS.md | 43 | `pick. Free tools and CC0 assets only.` |
| 8f | docs/ship_pipeline/AUDIT_SYNTHESIS.md | 103 | `- The first-battle race is fixed on the ` |

New facts established this pass (beyond the given list):
- hulls_hi/*.json field `t` sums to 930,166 triangles; min 2,400 (B23_51), max 38,000 (V1b_r_23). C19_51 hulls_hi JSON is the old 38,000-triangle hull.
- Only C19_51 files in git: hulls(_hi)/C19_51.json, _m.webp, _n.webp, docs/ship_pipeline/concepts/C19_51.webp. No .vsm, _kit.json, _f/_fn/_kit_f/_kit_n, or painted _a webp.
- contrib/muse/design/img/ is not tracked (IMAGE_MANIFEST.md lists 40 webp paths in it).
- fx3d.js:4 `SHIELD_HEX='#62ccff'`; battle.js:606 shield damage text uses #62ccff. Rare rarity #62ccff collision is real (UI side).
- Rey audit memory figures: phone 252 MB / 714 MB geometry (ship-pipeline-audit.md:428), desktop 1,764 MB (:427); texture 20 distinct "desktop about 2.66 GB, phone about 1.32 GB" (:437).
- Code already has: aiKitMat with no 0.3 self-light (ships3d.js:787,790), HullFx on kit parts (ships3d.js:795-796), shared detail layer for hull and parts (gfx3d.js:105), TAARenderingPipeline on ultra (scene3d.js:105), MSAA 4 plus FXAA together (scene3d.js:26), letterbox cineBars (fx3d.js:387), DoF on ultra cinematic (fx3d.js:402), stencil only with ?shots (scene3d.js:13), Deathless reanimation (battle.js:702, data.js:96 `reanimate:true`), boarding (battle.js:652-657).
- Dead Star is a board shape, not a terrain kind: battle.js:192 `kind:ds?'deadstar'`, battle.js:305 `well:shape==='deadstar'`; terrain kinds are five (battle.js:193).
- v14 kit still builds naval tells: c19_kit.py:173 "tall main mast with two yards spanning sideways"; :38 "a lower hull falling to the keel"; :160 funnels; :403 "on a keel plate".

---

## 1. art_direction_rey.md

Verdict: palette and code citations accurate; colour law STALE; rarity premise WRONG; shield shapes assigned to shieldless factions WRONG; portrait status STALE.

1. VERIFIED (OBSERVED) :3,18 FAC3D ships3d.js:2-8 and FACTIONS data.js:110-125 (block ends at :127). All four drift pairs match: data.js:111 trim '#c8501f' vs ships3d.js:3 '#9c3a1c'; :115 '#b8402a' vs :5 '#a3542c'; :121 '#eef3f1' vs :7 '#e4ebe7'; :124 '#1d2220' vs :8 '#2c3431'.
2. STALE (OBSERVED) :7 "Cyan means shields. Nothing else is cyan, and shields are nothing else." Retired Oct 24 evening; code shields are faction-coloured (ships3d.js:3-8 `shield:` per faction; fx3d.js:3,32). Hex grid is cyan too (scene3d.js:254).
3. WRONG (OBSERVED) :13 "epic stays gold-adjacent only if gold is freed up". data.js:386 Epic col '#c58bff' (violet). INFERRED: proposed Rare "#b78cff" would sit beside Epic #c58bff, creating a new collision.
4. VERIFIED (OBSERVED) :9 "rarity Rare sits on the same #62ccff as shields (data.js:386)": fx3d.js:4 SHIELD_HEX '#62ccff'.
5. WRONG (OBSERVED) :96 shield ripples "Chorus blistered ... Deathless cracked-glass". Chorus "No shields at all" (data.js:119); Deathless sh:0 (data.js:96).
6. VERIFIED (OBSERVED) terrain kinds battle.js:193; storm "aim 10 points worse" battle.js:15; MOVE_FEEL corsair jit .38 (ships3d.js:13), chorus cyc 1.5 (ships3d.js:14); FAC_MAP battle.js:56; v53 off-white comment ships3d.js:7.
7. WRONG (OBSERVED) :62 "a plate per terrain kind" then six plates incl. Dead Star. Five terrain kinds; deadstar is a board shape (battle.js:192,305). Ruling (Dead Star plate = well-board backdrop) fixes the intent, not the wording.
8. WRONG at HEAD (OBSERVED) :3 "Concept plates generated with this pack live in img/ alongside this file." img/ untracked; CONVERSATION_CONTEXT.md:36-38 admits it.
9. STALE (OBSERVED) :104 "nine final portraits" and "The Chorus is complete at four of four". Ruling: Voice v4 final, Matriarch v3 candidate, Mending needs new direction, portraits parked.
10. VERIFIED (OBSERVED) :121-151 admiral names, doctrines and Commands match data.js:201-230 (24 admirals); commit 40d5497 exists; selection ring is currently amber (ui3d.js:238 `new C3(1,.75,.3)`), so the "goes white" proposal starts from a true state.

## 2. ship_kit_upgrade.md

Verdict: code line citations all VERIFIED; memory figures mis-framed (phone numbers); two to-dos already done; budgets unnumbered.

1. VERIFIED (OBSERVED) :11-14 loftVD ships3d.js:149 defaults cut .11 / iters 2 / sub 3; gothic chunks :473; fuselage :579; buildShipModel :666; AI_VSM :764; HullFx on AI parts :786-796.
2. WRONG framing (OBSERVED) :15 "roughly 252 MB of geometry ... about 714 MB ... about 1.32 GB of texture memory". All three are phone figures (ship-pipeline-audit.md:428,437). Desktop: 1,764 MB geometry, 2.66 GB texture. Under PC-only the risk is understated.
3. STALE (OBSERVED) :27 "the 0.3 emissive fudge in aiKitMat deleted" (as a to-do). Done: ships3d.js:787 "The old 0.3 self-light is gone".
4. STALE (OBSERVED) :7 "C19_51 took 8 revisions ... to reach 'awaiting owner verdict'". Record now runs to v14 with verdict "pretty close" (NEXT.md:58).
5. WRONG/STALE (OBSERVED) :12 "exactly one hull, C19_51, exists as a finished VSM asset". AI_VSM lists it, but no C19_51.vsm or _kit.json in git and no sign-off.
6. VERIFIED (OBSERVED) :7 "35 of 36 queued hulls are not started" (SHIP_QUEUE 36 rows; AI_HULLS 36 codes ships3d.js:704-712). "69 build sessions" is the Rey audit estimate (ship-pipeline-audit.md:66), not a measurement.
7. UNCHECKABLE (OBSERVED) :25 "12 of 45 hulls are same-stat weapon swaps": repeated in reviews/asymmetry_decision.md:40; origin census not checked.
8. Gate, unmeasured (OBSERVED) :31 "Per-class vertex and triangle ceilings for desktop" with no numbers. Conflicts with README.md:4 "No artificial triangle limits".
9. Gate, undefined (OBSERVED) :32 "no hull 6 until a fully loaded battle passes on desktop". "Fully loaded" unstated; ruling has size growing toward about 20 at run end. Differs from CONVERSATION_CONTEXT.md:56 (sign-off gates ship 2).
10. Human panel (OBSERVED) :33 "any two hulls a viewer cannot tell apart". Viewer panel undefined. INFERRED :23 "detail defined once in gfx3d.js" partly exists already (gfx3d.js:105 v55 shared detail layer).

## 3. beauty_corner_spec.md

Verdict: re-tiered for PC, but hard fail gates enforce the retired cyan law; triangle gate collides with the barge; terrain set wrong.

1. STALE (OBSERVED) :77 fail gate "a shield effect that uses any colour other than ice cyan"; :95 "Any faction-coloured shield pixel fails." Retired law; every current shield (faction-coloured) fails.
2. WRONG (OBSERVED) :47 shield ripple "All factions ... Chorus blistered ... Deathless cracked glass". Both factions have 0 shields.
3. WRONG (OBSERVED) :24 "the game's actual terrain set: Belt, Storm, Graveyard, Planet, Station, Dead Star". Five kinds (battle.js:193); deadstar is a shape.
4. VERIFIED (OBSERVED) :67 "2,400 to 38,000 triangles. All 36 desktop hulls total 930,166". Recomputed from hulls_hi JSON `t`.
5. Conflict (INFERRED) :67,77 fail on "a per-hull triangle count above its tier range": the barge VSM is "1.5-2M triangles" (README.md:63), 40x to 50x the range.
6. Mismatch (OBSERVED) :31 bloom start "threshold 0.7 and weight 0.5"; shipped is bloomThreshold .5, bloomWeight .55 (scene3d.js:27), though :101 says settings are shared "by copy".
7. STALE (OBSERVED) :110 "research memo uses a bloom threshold around 0.85": that is the memo's "Recommended phone configuration" (visual_expansion_research.md:175), moot under PC-only.
8. Phone leftovers (OBSERVED) 9 lines mention phone; live one :52 "(dropped on phone, where the move and letterbox carry the shot)"; :59 "### Phone tier" heading kept.
9. Unmeasured gates (OBSERVED) :65 "sustained 60 fps", :66 "under 1,000" draw calls (community guidance), :68 texture ceiling "set by measurement", :87 10% regression. Human panels: :91 "judged by eye", :93 "a viewer", :120 owner verdict.
10. UNCHECKABLE (OBSERVED) :20 reference plates "ship_voidsworn_basilica.webp" etc. in img/, not in repo. INFERRED: :111 gold conflict rests partly on the wrong "epic rarity stays gold-adjacent" premise.

## 4. visual_qa_pack.md

Verdict: re-tiered for PC; colour law STALE throughout; shield shots specified for shieldless factions; timing conflicts with beauty corner.

1. STALE (OBSERVED) :7 "cyan means shields, nothing else is cyan"; :76 "No cyan anywhere except shields"; :145 reviewer Q2; :214 cyan audit. INFERRED: cyan hex grid (scene3d.js:254) fails every battle shot.
2. WRONG (OBSERVED) :33 per-hull shield hit "Chorus blistered ... Deathless cracked glass". 0 shields for both.
3. VERIFIED intent (OBSERVED) :8 colourblind shield check: still valid, more needed with faction-coloured shields (INFERRED).
4. Conflict (OBSERVED) :20 "bloom at the shipped threshold and weight" (0.5/0.55) vs beauty_corner_spec.md:31 start 0.7/0.5.
5. Conflict (OBSERVED) :101 "push-ins are slow (about 1.2 seconds for a Command or boss arrival)" vs beauty_corner_spec.md:37 boss arrival "3.5 second move".
6. Partly STALE (OBSERVED) :111 "18 plates against five terrain kinds": Dead Star plate now mapped to the well board by ruling.
7. Human panels (OBSERVED) :75 "a viewer who has never seen the hull names the faction in under three seconds"; :159 owner verdict; :130 external models not verdicts.
8. Unmeasured (OBSERVED) :102 "acknowledge within about 100 ms. Animations run under 300 ms"; :91 luminance sampling needs a facet reference no doc defines numerically.
9. Phone (OBSERVED) 8 lines, all struck (:21,:51,:163,:225); residual "every tier" :27.
10. Code tension (OBSERVED) :12 "MSAA on desktop": game runs MSAA 4 plus FXAA (scene3d.js:26), which graphics_craft.md:31 forbids.

## 5. graphics_craft.md

Verdict: not re-tiered; still phone-first throughout; several recipes ignore what the code already does.

1. STALE phone-first (OBSERVED) :5 "(phone first, desktop tier, ...)"; 20 "Phone cost:" lines; 28 lines mention phone.
2. STALE (OBSERVED) :17 "judge it on the phone screen, not the monitor"; :58 "checked on a phone screenshot, not a monitor"; :63 "which the phone tier already budgets for".
3. VERIFIED (OBSERVED) :9 ACES recipe matches scene3d.js:29; :30 `pipeline.samples` 4 matches scene3d.js:26.
4. Code conflict (OBSERVED) :31 "Never both MSAA and FXAA at once". scene3d.js:26 `pipe.samples=4; pipe.fxaaEnabled=true;`.
5. Gap (OBSERVED) :30,108 TAA described as optional; game already builds TAARenderingPipeline on ultra (scene3d.js:105).
6. INFERRED :54 HighlightLayer needs `{ stencil: true }`; engine enables stencil only with ?shots (scene3d.js:13), so outlines need an engine change.
7. Gap (OBSERVED) :13 "starting pair is threshold 0.7 and weight 0.5"; shipped 0.5/0.55 (scene3d.js:27) not mentioned.
8. VERIFIED (OBSERVED) :17 ".3dl LUTs as six tiny files" is the research memo's proposal (visual_expansion_research.md:15). INFERRED not in code (game uses ColorCurves, scene3d.js:30).
9. VERIFIED (OBSERVED) :48 1.2 s push-in "already uses this timing" (visual_expansion_research.md:366); letterbox exists (fx3d.js:387).
10. UNCHECKABLE: web sources and Babylon API names not re-opened; :41 "a 20 ship battle" fits the ruling's end-of-run size, not today's 7 to 13.

## 6. design_council_audit.md

Verdict: largely STALE (written against phone-first drafts since edited); four factual WRONGs.

1. WRONG (OBSERVED) :32 "Current battles run around 20 ships"; :85 "current roughly 20". Today 7 to 13, enemy cap 8 (battle.js:147). The 1.32 GB figure is the phone 20-distinct case.
2. STALE (OBSERVED) :70 "The cyan shield law is the pack's best idea ... Keep it." Retired.
3. WRONG (OBSERVED) :17 epic rarity "stays gold-adjacent" counted as a gold use. data.js:386 Epic '#c58bff'.
4. WRONG (OBSERVED) :77 "Reassembly is a mechanic ... a system the game may not have". battle.js:702 'Reanimating'; data.js:96 reanimate:true.
5. STALE quotes (OBSERVED) :30 "glow is the first thing lost at phone size" (now "small size", art_direction:30); :44 "ceilings for phone" (now desktop, ship_kit:31); :47 "the Pixel remains the reference device" (no longer in CONVERSATION_CONTEXT).
6. STALE (OBSERVED) :58 "all twelve plates generated" (art_direction:155 now 13+18); :59 "three design documents" (fixed in CONVERSATION_CONTEXT:7; survives at IMAGE_MANIFEST.md:3).
7. STALE (OBSERVED) phone framing, 11 lines: :11 "phone-size readability", :87 "phone and desktop", :89 "Run the phone-size readability test".
8. STALE (OBSERVED) :46 "detail defined once in gfx3d.js (... it does not exist yet)": gfx3d.js:105 v55 shared detail layer for hull and parts.
9. STALE (OBSERVED) :49 luminance cap "has no measurement method": beauty_corner_spec.md:94 now gives one. :85 action 1 battle size now ruled (grows toward about 20).
10. UNCHECKABLE (OBSERVED) :9 "four of 40 SHA-256 hashes ... all four match": images not in repo. VERIFIED :50 five terrain kinds; :75 plates local-only.

## 7. CONVERSATION_CONTEXT.md

Verdict: PC-only ruling recorded correctly; colour, portrait and battle-size sections STALE; engine comparison plan missing.

1. STALE (OBSERVED) :26 "The colour laws in the art direction doc stand as written. Cyan means shields". Retired Oct 24 evening.
2. STALE (OBSERVED) :30 "The Chorus admiral set is complete at four of four"; :32 "the Matriarch v1 (v2 is final)", "Mending Choir v1 ... v2, pure flesh, is final". Ruling: Matriarch v3 candidate, Mending new direction, parked.
3. WRONG + STALE (OBSERVED) :49 "Target battle size stays near the current scale (around 20 ships)". Current is 7 to 13 (battle.js:147); ruling: grows across a run toward about 20, ramp by more ships allowed.
4. STALE (INFERRED) :76 "spectacle comes from effects and camera, not from more ships" conflicts with ruling that difficulty may ramp by more ships.
5. VERIFIED (OBSERVED) :44 "hulls_hi meshes and maps for all 36 hulls, about 930k triangles" (36 json, 72 webp, 930,166).
6. VERIFIED (OBSERVED) :49 PC-only ruling, no phone tier/pass/gate, engine stays Babylon. Missing: the open engine question's 6-ship Babylon vs Godot comparison.
7. VERIFIED (OBSERVED) :56 "Pyre-Barge sign off, which gates ship 2" matches no sign-off. OPUS_HANDOFF.md:96 notes section 7 is otherwise stale where later rulings closed items.
8. VERIFIED (OBSERVED) cited files exist: reviews/council_audit.md, career_story.md, asymmetry_decision.md; GRAPHICS_REFERENCES.md section 6 (:268); research memo section 6 (:269), 7 (:339).
9. VERIFIED (OBSERVED) :36-38 images not in repo (img/ untracked).
10. Tension (OBSERVED) :70 "one to three player capital ships per battle" (Rogue Trader) vs ruling toward about 20 at run end; the doc does not reconcile counts.

## 8. docs/ship_pipeline (C19_51 state)

Verdict: tool paths VERIFIED; status lines STALE; key barge assets absent from git; phone steps STALE; naval-tell conflicts.

README.md
1. STALE (OBSERVED) :6 "one ship done end to end, the Warlord's Pyre-Barge". No sign-off; v14 is a checkpoint.
2. Internal contradiction (OBSERVED) :72 "plus a 0.3 paint self-light (`G.kitFill`)" vs :82 "no self-light, `G.kitFill` 0". Code agrees with :82 (ships3d.js:787,790).
3. STALE phone (OBSERVED) :60 "Phone LOD ... to 250k"; :64 "hulls/CODE.vsm (phone/medium)"; :67 "on desktop and phone".
4. VERIFIED (OBSERVED) all named tools tracked: comfy_run.py, mv_prep.py, voidsworn_pixal_views.py, fitcam_render/fit.py, project_paint.py, c19_kit.py, hs_lib.py, detail_lib.py, lod_make.py, pixal_to_game.py, vsm_pack.mjs, render_multi.py, closeshot.py; jobs c19_1..c19_14g; 36 concept webp; c19_example renders.
5. WRONG at HEAD (OBSERVED) :64 game loads "hulls_hi/CODE.vsm ... plus CODE_kit.json": neither tracked for C19_51; :58 _f/_fn/_kit_f/_kit_n webp not tracked.

SHIP_QUEUE.md
6. STALE (OBSERVED) :17 C19_51 "v14 ... awaiting owner verdict". v14 verdict "it's pretty close" recorded (NEXT.md:58, TEXTURE_PASS.md:3). S column blank is VERIFIED consistent with no sign-off; 9-cell grid (BLOB_SWEEP:15) not recorded.

BLOB_SWEEP.md / GRAPHICS_REVIEW.md / TEXTURE_PASS.md
7. VERIFIED (OBSERVED) GRAPHICS_REVIEW :71 faceOut/faceOutMesh (ships3d.js:818,824), G.diagNoFaceOut, :80 twoSidedLighting false (ships3d.js:794), G.hull2s (:937), G.finAO (:781). STALE :79 "real-GPU and Pixel check"; BLOB_SWEEP :57 "Shots on desktop and phone"; TEXTURE_PASS :117 "the Pixel", :122 "Pixel 10 XL".
8. Conflict (OBSERVED) BLOB_SWEEP :40 bans "yardarms with rigging" and keels; c19_kit.py:173 "two yards spanning sideways", :38 "lower hull falling to the keel", :403 "keel plate".

AUDIT_SYNTHESIS.md
9. STALE (OBSERVED) :170-171 HullFx "switched off on painted hulls and never attached to parts": now attached (ships3d.js:795-796). :163 "the owner's rule allows stern guns aft" contradicts BLOB_SWEEP:33 "never backward".
10. Conflict (OBSERVED) :208-218 fix list "bollard heights", "yards spanning sideways", "an open crow rail", "a ladder": all banned naval tells (BLOB_SWEEP:40). :225 "hull files exist only on the PC" still VERIFIED.

---

## B. Phone-first framing still present

| File | Lines mentioning phone/Pixel | Live (not struck) |
|---|---|---|
| graphics_craft.md | 28 (20 "Phone cost:") | all; :5 "phone first" |
| design_council_audit.md | 11 | all (audit premises) |
| beauty_corner_spec.md | 9 | :52 "dropped on phone"; rest struck |
| visual_qa_pack.md | 8 | none live |
| CONVERSATION_CONTEXT.md | 4 | none live (history plus ruling) |
| docs/ship_pipeline/README.md | 4 | :60,:63,:64,:67 |
| TEXTURE_PASS.md | 3 (Pixel) | :117,:122 |
| AUDIT_SYNTHESIS.md | 2 | :177-178 |
| GRAPHICS_REVIEW.md / BLOB_SWEEP.md | 1 each | :79 / :57 |
| ship_kit_upgrade.md | 2 | :15 phone memory figures unlabelled |

## C. Gates, budgets and acceptance tests

Depend on unmeasured numbers: per-class triangle/vertex ceilings (ship_kit:31, no numbers); desktop VRAM ceiling (beauty_corner:68); "fully loaded battle" (ship_kit:32, beauty_corner:105, battle size undefined); 60 fps and under 1,000 draw calls (beauty_corner:65-66, community guidance); 40% luminance cap (no facet reference value anywhere); overdraw about 2.0 (graphics_craft:68); UI 100 ms/300 ms (visual_qa:102).

Need human viewer panels: silhouette sheet "a viewer" (ship_kit:33, beauty_corner:93, visual_qa:11); "names the faction in under three seconds" (visual_qa:75); screenshot vs plate "by eye" (beauty_corner:91); owner verdict loop (visual_qa:157-185); external-model second opinions (visual_qa:130).

Conflict with each other or the facts: cyan-only shield gates (beauty_corner:77,95; visual_qa:76) vs ruling and code; shield gates for shieldless Chorus/Deathless; triangle range 2,400-38,000 vs barge 1.5-2M and README:4 "No artificial triangle limits"; bloom 0.7/0.5 vs shipped 0.5/0.55; push-in 1.2 s vs 3.5 s; "no hull 6" vs "sign-off gates ship 2"; gold check vs Chorus/Ithar trim (self-flagged, beauty_corner:111).

## D. Pyre-Barge C19_51

- v13d (OBSERVED HANDOFF.md:65): pixal_to_game push-pull fills atlas gaps, job c19_7_infill.bat. SHIP_QUEUE:17 labels v13d "clean shell hull (owner OK'd shape)". The shape OK quote ("approach and shape is correct, needs refinements and extra detail", HANDOFF.md:56) was given on the v12 bare shell draft (INFERRED attribution drift).
- v14 (OBSERVED HANDOFF.md:72-78, NEXT.md:55): mixed-shape trimmed plating, belly slabs, uneven rows, baked roughness/metal and fine normal maps, lighting fixes. Owner: "it's pretty close" with blocky plain parts and missing texture (NEXT.md:58-61). Not signed off.
- "Upgraded" (OBSERVED contrib/muse/OPUS_HANDOFF.md:76-78): loft v2 plus Corsair grammar pack, desktop-only budgets, paint/material unification, effects pass, material audit; "V14 ... is the starting point, not the target"; "the upgrade is dressing, paint, materials, and effects on top of a proven shape." STALE vs ruling: shape may change wherever it reads naval. Current naval reads in the kit: yards, funnels, keel (c19_kit.py:173,160,38,403).
- Dependencies in repo: c19_kit.py (555 lines), detail_lib.py (309), hs_lib.py, project_paint.py, pixal_to_game.py, vsm_pack.mjs, render_multi.py, closeshot.py, jobs c19_1..c19_14g, concepts/C19_51.webp, c19_example renders, docs/feedback/2026-10-22 (3 png), reviews/kit_spec_synthesis.md, contrib/deepseek/reviews/barge_upgrade_deepseek_draft.md, kit_spec_deepseek_draft.md.
- Not in repo: C19_51.vsm, C19_51_kit.json, finish maps (_f/_fn/_kit_f/_kit_n), painted atlases, the concept pick flux11_C19_51_cut.png, comfy_io/C19_51 (mesh, 250k LOD the ST table was measured on), ambientCG sets and index.csv, art plates (img/). Not built: loft v2, grammar packs, module library, manifests.

## E. Contradictions between documents

1. Bloom start: beauty_corner:31 and graphics_craft:13 (0.7/0.5) vs visual_qa:20 shipped (0.5/0.55 in code) vs research memo phone 0.85.
2. Arrival push-in: visual_qa:101 about 1.2 s vs beauty_corner:37,52 3.5 s.
3. Triangle policy: ship_kit:31 and beauty_corner:67 ceilings vs README:4 no limits and AUDIT_SYNTHESIS:197-200 "measure first".
4. Platform: graphics_craft phone-first (:5,:17,:58) vs PC-only re-tier in beauty_corner, visual_qa, ship_kit, CONVERSATION_CONTEXT:49.
5. Progression gate: ship_kit:32 / beauty_corner:105 "no hull 6" vs CONVERSATION_CONTEXT:56 sign-off gates ship 2.
6. Battle size: council:32 "around 20" now; CONVERSATION_CONTEXT:49 "stays near ... 20", :70 one to three; code 7 to 13.
7. MSAA plus FXAA: graphics_craft:31 "Never both" vs code scene3d.js:26.
8. Kit self-light: README:72 vs README:82 (code agrees with :82).
9. Stern guns: AUDIT_SYNTHESIS:163 allows aft vs BLOB_SWEEP:33 never backward.
10. Detail block: council:46 "does not exist yet" vs ship_kit:23 to-do vs gfx3d.js:105 existing shared layer.
11. 1.32 GB: ship_kit:15 presents it as the load risk; OPUS_HANDOFF calls it "asserted without derivation"; Rey audit :437 derives it as the phone case.

## Not checked

fx3d.js shield comments and ui3d.js:625 (given as verified); visual_expansion_research.md, tool_guides.md, GRAPHICS_REFERENCES.md beyond headings and quoted lines; image hashes (images absent); graphics_craft web sources and Babylon API constant names; "Gold currently means five things" count; origin of the 12-of-45 census; AUDIT_SYNTHESIS line refs into c19_kit.py at commit 2cfbde2 (lines 283, 313-315); 69-session estimate inputs; whether all hulls load at boot (INFERRED from ships3d.js:803 Promise.all, no eviction found).
