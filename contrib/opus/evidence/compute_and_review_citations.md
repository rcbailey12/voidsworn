# A2: compute pack and review citation verification

Basis: /home/claude/rcbailey12/voidsworn at HEAD d5d0227 (game JS identical to 51337c2; `git diff 03e149f HEAD -- '*.js' head.html` touches only contrib/muse/tools/checkpack/checks.js). Read only. Scripts and outputs in scratchpad/a2b/ (idx.js uses the TypeScript parser for a real AST; census.js, c2.js and ri.js load data.js+core.js+battle.js the way sim3d.js does; chk.py checks file:line:quote).

## Part 1: compute data

| Claim | Verdict | My numbers |
|---|---|---|
| code_index: 1,016 definitions | WRONG | 1,021 top-level definitions (763 function, 221 const, 27 let, 9 class, 1 var). All 1,016 indexed entries match name, file and line exactly. The index skips 5 that sit on the same line as an earlier statement (or are a later declarator): unknownId core.js:73, ENC_SPECIAL battle.js:66, AI_HULL_DATA ships3d.js:712 (2nd declarator of the const at 704), TORPS fx3d.js:283, reportError campaign3d.js:5. Per file: core 94, battle 204, ships3d 119, fx3d 94, campaign3d 25 (others as listed). None of the 5 is dead (4 to 12 refs each). |
| code_index: zero duplicate names | VERIFIED | 0 duplicates across all 1,021. (build.py's own guard matches only `^function`, so it cannot see reportError or unknownId either.) |
| content_census: 45/25/36/12/13/24/8/6 | VERIFIED | HULLS 45, W 25, BOONS 36, RELICS 12, MODULES 13, ADMIRALS 24, ENCOUNTERS 8, FACTIONS 6; CSV row counts match. Breakdowns also match (hull factions 8/8/7/7/7/6 + 2 none; admirals 4 each; boons 5 per patron + 6 duo; weapon kinds 9/4/3/3/3/2/1; patrons 6, events 11, abilities 13, perks 14, aspects 6, legacy 12, captains 6, archetypes 3). |
| asset_inventory: 553 files, 157.5 MB | VERIFIED | 553 CSV rows, every path exists, 0 size mismatches, 157,516,415 bytes. Scope note: the CSV leaves out 7 tracked .md files under contrib/gemini and 3 tracked __pycache__ .pyc files under tools/blender (type filter, not an error). |
| all 36 hull meshes in both tiers, 108 files per tier | VERIFIED | hulls/ 108, hulls_hi/ 108, identical listings, 36 codes x (.json, _m.webp, _n.webp). All tracked. |
| "only C19_51 has .vsm plus _kit.json" | WRONG as a file claim | Zero .vsm and zero _kit.json files on disk, in git ls-files, or anywhere in git history (all branches). asset_inventory.md itself says this correctly (line 125). The wording comes from contrib/muse/READING_PLAN.md:9 (and packJ_design_audit.txt:119, deepseek barge draft:13); it is true only as a code path: AI_VSM = {C19_51} at ships3d.js:764, loader at :801 fetches .vsm then _kit.json, falls back to JSON. |
| dead_code: 13 candidates | VERIFIED (13/13, more than 5) | Each name occurs exactly once as an identifier in the 20-file corpus; fxBookLoad's 2 extra hits are comments (wfx3d.js:72, vfx3d.js:118). Definition lines re-checked for 8 (all match). |
| RI: 0 referenced-but-undefined | VERIFIED | Hull weapon ids all in W, admiral start ships all in HULLS, boon patrons all in PATRONS: 0 bad. |
| RI: admirals kassar, khepra never referenced | VERIFIED | Definition only. |
| RI: boon i_plate never referenced; enumeration at core.js:146,147,150,291 | VERIFIED | Definition only; all 4 sites are Object.keys(BOONS). |
| RI: perk gunnery never referenced | VERIFIED | Definition only. |
| RI: aspect bulwark never referenced | WRONG (by its own rule) | sim3d.js:469 has the literal 'bulwark', and sim3d.js is in the stated corpus. (Enumeration site campaign_meta.js:94 verified.) |
| RI: all 12 legacy unlocks never referenced | WRONG (definition artifact) | Every one is read by name: META.unlocked.chest1/2/3, cmd1/2, founder, vets at core.js:280-285, wrights core.js:181, salvagers core.js:156, u_carrier/u_battleship/u_dread campaign_run.js:139. The scan counts only string literals and object keys, not property access. |

## Part 2: review citations

Verdicts: VERIFIED = quote/feature at the cited line at HEAD; DRIFTED = exists at another line; WRONG = not in the file at HEAD, or the claim is contradicted.

| File | Lines | First 40 chars of last line | Checks | VERIFIED | DRIFTED | WRONG |
|---|---|---|---|---|---|---|
| muse/reviews/plain_parts.md | 45 | `- detail_lib.py helpers bvh_of, frame, o` | 17 | 17 | 0 | 0 |
| muse/reviews/ship_loading.md | 39 | `- G.tex, dynTex and the HullFx plugin in` | 14 | 14 | 0 | 0 |
| muse/reviews/battle_rules.md | 32 | `- Line of sight symmetry (whether hexLin` | 24 | 23 | 1 | 0 |
| muse/reviews/enemy_ai.md | 24 | `Not checked: ui3d.js and fx3d.js (presen` | 21 | 21 | 0 | 0 |
| muse/reviews/effects_world.md | 29 | `Not checked: ships3d.js and gfx3d.js (bu` | 14 | 14 | 0 | 0 |
| muse/reviews/ui.md | 25 | `Not checked: campaign3d.js and the other` | 23 | 23 | 0 | 0 |
| muse/reviews/independent_audit.md | 164 | `sfx.js internals (the no-music finding i` | 16 | 13 | 0 | 3 |
| muse/reviews/space_3d.md | 112 | `The 3D scene's per-ship vertical offsets` | 14 | 14 | 0 | 0 |
| rey/reviews/ship-pipeline-audit.md | 489 | `3. Q6's stress test before hull 6, and Q` | 35 | 13 | 15 | 7 |

### plain_parts.md (basis fad56d6)
All 10 finding quotes VERIFIED at the cited lines (detail_lib.py 56, 136, 184, 191, 198, 308; c19_kit.py 321, 379, 429, 456) plus refs c19_kit 287, 334, 531, 538-539, 540 and detail_lib 174. Proof-of-reading lengths (309, 555, 80) match HEAD. Substance spot checks: cell/damage appear only in the signature (line 198); dents `* .5` at 308 confirmed.

### ship_loading.md (basis b7a5a73)
All 7 finding quotes VERIFIED (ships3d.js 963, 827, 783, 946, 789, 803, 765) plus 797, 780, 968, 942, 961, 772, 801. ships3d.js 983 lines, last line `}`, longest line 1,116 chars: all VERIFIED.

### battle_rules.md (basis 77a6f32)
All 7 evidence quotes VERIFIED (battle.js 722, 777-778, 508, 518, 635-636, 644, 276, 641, 246, 251, 956-957, 958-967; sim3d.js:35). B.alt + startSideTurn('enemy') confirmed at sim3d.js 85, 106, 121, 144, 331, 346, 362, 379, 496; classic mode 40/84 runs botTurn first (claim holds). gainResolve at 358, storm 372, wellTick 272, objAfterMove at 735 with calls only at 437, 445, 944. Header sizes (1143 lines/129,042 bytes; 575/91,559) VERIFIED.
- DRIFTED: "expectedVs (battle.js:497)": function is defined at battle.js:501.

### enemy_ai.md (basis 7866493)
All 9 quotes VERIFIED (battle.js 997, 1018, 684, 478, 510, 1106, 1023, 1114, 875; sim3d.js:72), plus 998, 455, 1030 (evalThreat's los-free loop; def at 1027), 1037, 636, 645, 892, 893, 1025, 1014, sim3d.js:8.

### effects_world.md (basis 764f299)
All 10 quotes VERIFIED (scene3d.js 96, 91; vfx3d.js 147, 77; fx3d.js 147, 87, 161, 56, 524, 412) plus scene3d 106, 108 (VolumetricLightScatteringPostProcess), vfx3d 143, fx3d 45-51. File lengths and last lines (625/200/463/684) VERIFIED.

### ui.md (basis cdc4074)
All 10 quotes VERIFIED (ui3d.js 551, 36, 659, 618, 342, 534; head.html 115, 284, 138, 257) plus ui3d 549, 572 (auto-select in aiStep), 633, 2, 3, 672; head.html 128, 140, 212, 285, 286, 287 (#b_set .sl hidden, glyph 17px), 288. ui3d.js 724 / head.html 308 lines and last lines VERIFIED.

### independent_audit.md (basis 03e149f)
VERIFIED: ui3d.js:484, campaign3d.js 94, 95, 65 (finishBattle def), campaign_run.js:73, core.js:297, main3d.js:11, campaign_meta.js 136-137, data.js:61, core.js:179, the battleScreen warden quote (campaign3d.js:51), the toast quote (campaign_meta.js:11), scope line counts (122/321/209/302/20/448).
- WRONG: "34 hulls and 12 variants": HULLS has 45 = 33 base + 12 variants (HULL_VARIANTS 12).
- WRONG: "37 boons": 36 (30 patron + 6 duo). Rest of that census line matches (25, 12, 13, 14, 6, 24, 8, 12 shapes, 5 regions, 5 conditions, 7 Heat, 3 archetypes, 2 node mods, 11 events).
- WRONG (substance): "finishBattle only guards on B.finished, which the normal end-of-battle flow never sets": finishBattle sets B.finished=true itself at campaign3d.js:66, and the normal flow reaches it via c3continue (line 93). The bug window (B.over set, Continue not yet tapped, then Jump out) still stands.

### space_3d.md (basis 99345bc, design proposal)
VERIFIED: QUAD_NAME quote (core.js:34), battle.js 388, 412, 270 (gravity-well comment; wellTick 272), scene3d.js 265 (CreateDisc board discs), 371 (d.y=0), 7 (hexWorld y=0), ui3d.js 363 (scene.pick), 365 (k=-ray.origin.y/ray.direction.y), 366 (disambiguation comment), fx3d.js 13-14 (four arcs merged into the ring; makeShieldRing itself at 30).
- Delta-v bands / altitude in code: NONE. No u.band, no band state, no delta-v, no altitude field in the 20-file corpus. The only height is fx3d.js:182-196 altK, transient hop animation keys (+9 climb / -7.5 dive) inside animMove; unit state stays flat, as the review says. Other "band" hits are unrelated (battle.js:74 deployment column band, scene3d.js:178-190 nebula shader, fx3d.js:54 hull-arc helper). Proposal only: confirmed.

### rey/reviews/ship-pipeline-audit.md (no basis commit stated; added in c038806, Oct 21)
VERIFIED: project_paint.py 21-24; gfx3d.js 16, 18, 27 (vHfxL=positionUpdated, ship-local); paint_level.py 1, 9, 11; c19_4_kit_to_game.bat:8; c19_3_lod.bat has no CONCEPT; AI_VSM = {C19_51}; AI_HI_ON_PHONE 11 entries; 12 s auto-proceed (perf3d.js:26); kit_a error path, disposeAllViews -> aiTexReleaseAll; hull dir sizes 31/79 (MiB).
DRIFTED: project_paint.py 93 -> 100 (DETAIL when base_img is None); 97-110 -> 157-163 (Brick 38/.45 at 157, noise 900 at 159, edge 1.6 at 163); 84 -> 90 (wb = 0.06); 69-74 -> 114 (.62, 1.18); 40-45 and 60 -> 46-51 (KEEP); ships3d.js 904-908 -> 934 (aiPaintMatFor); 777-779 -> 785 (aiKitMat); gfx3d.js 45 -> 46, 87 -> 104, 115 -> 134 (seam 0.24, plate 0.12); AUDIT_BRIEF.md 74-75 -> 76.
WRONG at HEAD (most are superseded by the v55 fixes made after this audit):
1. ships3d.js:778 quote `const f=G.kitFill??.3; m.emissiveTexture=t; m.emissiveColor=new C3(f,f,f)`: not in file. Now ships3d.js:790 `const f=G.kitFill||0; if(f>0){...}` (comment at 787: "The old 0.3 self-light is gone").
2. "G.kitFill not set anywhere ... so the 0.3 self-light always applies": default is now 0; never applies unless set.
3. Q0 item 5 "kit is a bare BABYLON.PBRMaterial ... no HullFx plugin": aiKitMat now clones aiHullMat (ships3d.js:788) and keeps HullFx.
4. "aiKitMat creates the kit_a texture with no error callback": ships3d.js:789 has an error callback (warn only).
5. pixal_to_game.py "calls it twice ... line 52 hull, line 89 kit": now one joint solve over both maps (lines 112-116).
6. "c19_kit.py is 319 lines": 555 at HEAD (319 at c038806).
7. "If applyAIHull throws ... the procedural ship stays": applyAIHull disposes the procedural hull at ships3d.js:827 before building the new one, so a later throw leaves no hull (matches ship_loading finding 2).

## Not checked
- The other ~10 rey Q2/Q3 coordinate claims about c19_kit.py parts (renders/geometry); the Q6 memory arithmetic.
- Whether claims 6-7 in the rey list were true at c038806 (only HEAD was judged).
- independent_audit Part 2/3 opinions and genre claims; space_3d design content beyond the code facts.
- The balance reference (Run 1) and strings_corpus.csv (1,507 rows) were not re-derived.
- References-per-file and top-30 reference counts in code_index.md were not recomputed.
- The built voidsworn-3d.html was not compared with sources.
