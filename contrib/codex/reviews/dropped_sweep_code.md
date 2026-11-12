# Dropped-context sweep, leg C: code against the words

Refs #540. Reviewed main `0155c1772845dda3bd455a96825c48d714658537` on Ryan's PC, Nov 11, 2026. GitHub's main endpoint matched the checkout when the review started. Source citations below refer to that commit, not a worker branch. No game, tool or working-document changes. No commit or push.

The important gap is between the Blender build and the game: the recipe can make insides, but stage 7 removes them, and the game generates its own fractures instead of reading the builder's break lines. The old-hull fallback exists and ran on every non-squadron cached ship asset. That is a different claim from new hulls carrying authored insides through hits and deaths.

## Findings

Each row records one carry decision. PARTLY includes work explicitly still queued; it does not mean the Board forgot it. OBSERVED means the cited source or execution was inspected. An absent consumer is a bounded search of the export and rendering paths below, not a claim about every branch on GitHub. Quotes in the quote column are exact excerpts, each shorter than 20 words. FINDINGS.md means `contrib/opus/FINDINGS.md` throughout.

| # | Finding: what was agreed or found | OBSERVED/INFERRED | File:line, ruling or issue | Exact quote | Where it should live now | Whether it is there | Verdict | Why it matters | Your fix / Board routing | Confidence |
|---|---|---|---|---|---|---|---|---|---|---|
| C1 | New hulls must retain thickness and authored insides through damage and death. Export deliberately excludes them, and the export gates do not prove the inside rule. | OBSERVED | FINDINGS.md:126 (R98), :237 (R209); docs/playbooks/ships.md:46-49,78-79; tools/blender/r209/bakeAb6.py:156; tools/recipe/export7.py:69,80-82,156,306; tools/recipe/standing.py:179; tools/recipe/check_export.py:163-191 | ships:47: "never flat caps or a hollow shell"; export7:69: `o.get('role') != 'interior'`; export7:80: "the game's ship has no inner skin" | A retained interior representation in the exported ship or break assets, a damage/death reader, and a stage-7 proof using the written assets. | The bake calls `C.breakable`; export filters interior-role objects, disables/removes `skin`, and writes neither wreck nor damage GLBs. The standing checks cover outline, battle outline, paint, blink, licences and lights. The export checker checks points, maps and manifest counts, not interiors or break captures. Generic procedural cavities/caps remain the runtime substitute. | DROPPED | A good Blender break picture can pass review while the installed ship loses exactly what made it solid. R209's new-build requirement is not implemented by an export PASS. | Carry an explicit export-to-runtime interiors job under #209 and the new builds #532/#373, with actual installed-ship wounds and breaks at 170 and 60. Fail the build when that evidence is missing or hollow/flat. Do not remove the old-hull fallback. | high |
| C2 | Authored structural break lines should determine where a rebuilt hull comes apart. The builder's lines never reach a game reader. | OBSERVED | FINDINGS.md:126 (R98), :237 (R209); docs/playbooks/deaths_and_hits.md:59-60,111-112; tools/blender/r209/common.py:22-26; tools/recipe/export7.py:168,251-252,284-285; godot/fx/fx_death.gd:711-764,815-847,1647-1656 | deaths:59: "three pieces along its authored lines"; common:26: `sc['r209_t_lines'] = list(T_LINES)`; fx_death:832: `plan = fracture_plan(fx, s, r)` | A defined break-line/chunk format in the recipe contract, written by export and consumed before runtime fallback cutting. | Blender stores scene-only `r209_t_lines`, `r209_l_line` and decks. Export writes points and a few ship extras, without those lines. The game's `_break_lines(job)` reads its generated fracture plan, not Blender metadata. Big non-Chorus ships get seeded size ratios, tilted breaks and a bite; Chorus gets warped seed cuts. | DROPPED | Modelling a magazine, glass layer or organ beside an authored seam cannot control what the game exposes. Merely exporting more interior meshes does not connect the fracture contract. | Assign the writer and reader together. Prove that changing one authored line moves the installed ship's actual break, while legacy hulls still use the fallback. The recipe already admits `_wreck.glb` is unwritten at RECIPE.md:124-128; this is unfinished integration, not lost source material. | high |
| C3 | Built death behavior has not been carried back consistently into the working API and playbook. | OBSERVED | FINDINGS.md:214 (R186), :221 (R193); godot/fx/API.md:116-117; docs/playbooks/deaths_and_hits.md:33,47,59; godot/fx/fx_death.gd:49-68,711-810; godot/fx/fx.gd:1093-1100; godot/scenes/battle/battle.gd:2162-2188,2207-2232 | API:116: "two capped halves at 1.38 effect seconds"; deaths:33: "The camera is never taken from the player for a death."; R193: "Hold and slow" | The current death API and deaths_and_hits.md, with implemented behavior separated from future designs. | A capital now breaks at 2.0, flashes at 2.28 and releases three main pieces. Non-Chorus big wrecks have irregular fractures and missing matter. The battle holds the cut-in through the core and enables the slow beat. The API still describes the older universal two-half timing and small-ship ribbon; the playbook still forbids taking the camera. | CONTRADICTED | The next worker can restore obsolete behavior while following the document literally. The kill beat was carried into code, not lost again. | #492 should carry #484 and #521 into these exact passages, retaining the reasons and the deferred small/faction rows. Update the API with the implementation, rather than reverting the implementation to old prose. | high |
| C4 | Small-ship deaths and weapon/faction-specific breaks are still only partly built, but have explicit follow-up homes. | OBSERVED | docs/playbooks/deaths_and_hits.md:65-86,94-112; godot/fx/fx_death.gd:44-48,815-833,2188-2192,2279-2284; GitHub #463, #461 carried item (b) | deaths:71: "about 255 px"; fx_death:46: `cut = 0.55`; #461: "today the cut is prepared before the killing weapon is known" | #463 for small deaths; #461 for lance cuts; rebuilt-faction jobs for faction deaths. | Destroyers still share the length-based small flash row with frigates. Small deaths use the old short timeline. Precomputation fixes the fracture before a killing weapon is known, so a later lance cause does not select an authored beam cut. The playbook explicitly defers new faction deaths until hull rebuilds. #463 is open; #461 and PR #524 are open. | PARTLY | These are visible gaps, but counting them as newly dropped work would duplicate existing assignments. | Keep #463's R186/R209 obligations and #461's carried lance item when the briefs are refreshed. Test the eventual cause-specific geometry itself. Do not count new faction death designs as delivered by generic old-hull caps. | high |
| C5 | Gun-sized hit recipes, lasting matter/scars and the latest torpedo flash ruling are not all on main yet. | OBSERVED | docs/playbooks/deaths_and_hits.md:118-130; FINDINGS.md:236 (R208); godot/fx/fx_weapons.gd:1073-1077; godot/fx/fx_ship.gd:1031-1039; godot/fx/API.md:282; GitHub #461, PR #524, #538 | R208: "Yes, 140"; fx_weapons:1076: `(154.0 if torpedo else 56.0) * target_scale`; fx_ship:1039: `_marks.pop_front()` | The live hit implementation, the hit playbook and the #461/#538 delivery chain. | Main's staged hit chooses scale from the target; the torpedo base is still 154. Old marks are evicted after bounded section/ship budgets. The API records those budgets, while the playbook says scars stay. The #461 brief already calls out target-only sizing and deleted scars. PR #524 was unmerged when checked; #538 explicitly follows it. | PARTLY | The newer ruling is not proof that the installed main branch already behaves that way. Merging a report or accepting a future pick cannot stand in for the code change. | Follow PR #524 through its outside check and merge, then #538. Recheck 140, gun-dependent sizing and scar retention on the resulting main; carry the final behavior into the playbook. Do not file these again as orphaned work. | high |
| C6 | Shields have faction colour and idle invisibility, but not the promised persistent down-facing gap/hull surface model. | OBSERVED | docs/playbooks/effects.md:15-16 (R163); godot/fx/fx_ship.gd:322-323,395-428,467-474,757-765; GitHub #371/#372 as recorded in OPEN_WORK.md | effects:15: "a downed side reads as a dark gap"; fx_ship:396: `var sph = SphereMesh.new()`; fx_ship:763: `if _last_sh >= 0.0 and shs > _last_sh + 0.5:` | The shield surface and per-facing state reader in #371/#372, then the API and proof strips. | The current shield is a scaled sphere. Sync sums all four shields for regen; a break sends a transient direction/time. This path does not preserve four facing health values for a lasting missing side. It is hidden except during timed effects. | PARTLY | Invisible at rest is already present. A persistent quadrant gap and a hull-following surface are separate, unfinished behaviors. | Keep #371/#372 and the options-sheet dependency. Require the down-facing state to remain visible on a later hit/hover after the break animation, not just during the burst. | high |
| C7 | Hard points are exported and checked, but most effects still use the old guessed attach path. | OBSERVED | docs/ship_pipeline/HARDPOINTS.md:119-134; tools/recipe/export7.py:218-249; tools/recipe/check_export.py:94-162; godot/fx/fx_hull.gd:480-504,507-542; godot/fx/fx_ship.gd:811-823; GitHub #370 | HARDPOINTS:129: "If the ray misses too, **skip that shot's effect**"; fx_hull:519: `c.z - dir.z * W * 0.5` | #370's attach reader and its call sites, using the already delivered #363 contract. | Engine points have a reader. Gun mounts still use sampled rows and can return a box point after a ray miss; damage anchors still use random surface samples. The searched FX/render paths do not consume the exported weapon/breach/core/boarding point contract. #370 is explicitly open. | PARTLY | A correct exported point count does not mean the game fires or breaks from those points. | Carry the completed #363 contract into #370's implementation and proof. Include breach/core readers and skip counts, not only barrel smoke. Keep this separate from authored structural break lines in C2. | high |
| C8 | The movement follow-up and kill slow-motion wiring reached code, a working spec and checks. | OBSERVED | FINDINGS.md:221,223 (R193/R195); contrib/opus/briefs/movement_spec.md:42-74,131-143; godot/scenes/battle/battle.gd:1669-1735,2162-2188,2207-2232; godot/fx/fx.gd:1093-1100; #521 | movement_spec:54: "A move of two hexes or more is flown nose first"; battle:1678: `const SLIDE_PACE := 1.45`; fx:1100: `death_slowmo()` | Already in the movement spec, battle/FX implementation and #521 checks. | `nose_first_check` passes. `kill_slowmo_check` starts the cruiser beat at 1.67 versus core 1.66, capital at 2.28, and checks off/skip cases. The spec explicitly records straight-astern and one-hex dogleg exceptions; those are implementation choices with reasons, not undocumented code. | CARRIED | This is a positive carry check against the earlier ledger's stale claim that only tests call the beat. It does not establish Ryan's visual acceptance of every exception. | Keep the implemented spec and tests as the build reference; correct the older death-camera prose via C3. No new movement job from this row. | high |
| C9 | Issue #167's old-hull interior fallback exists and runs across the current cached hull set. It is not an authored-interior pipeline. | OBSERVED | FINDINGS.md:126 (R98); GitHub #167; godot/fx/fx.gd:980-995; godot/fx/fx_death.gd:815-865,946-1075,1081-1225,1292-1369; godot/fx/fx_hull.gd:247-261; godot/fx/test/destruction_steps_check.gd:63-81 | #167: "capped cut faces or an interior material on back faces"; fx_death:1075: `_seal_piece(pc)`; fx_death:939: `mat.set_shader_parameter("organic", pc.get("organic", false))` | Already in the live generic damage/cut paths and checks. The new-build pipeline still needs C1/C2. | Production precompute completed for 33 non-squadron PC cached assets: 30 combat hulls plus 3 objectives. Every piece reporting boundary edges had cap geometry. Three craft assets were excluded from this fracture test because the live wing path differs. Six faction captures at camera 60 show backed faces/ribs; Chorus uses flesh/bone. The other five use the shared metal fallback. | CARRIED | The fallback was not merely described and forgotten. Its existence, branch coverage and visible appearance are now separately evidenced. This test does not prove every boundary is watertight or that flat caps meet R209 for future builds. | Retain the fallback for older ships. Use the six captures below as its present baseline; do not use a cap count as approval of new machinery rooms or faction interiors. | high |
| C10 | Reverse carry gap: main wreck pieces are constrained to their split altitude, but the death API/playbook omit that behavior. | OBSERVED | godot/fx/fx_death.gd:2064,2121-2132; godot/fx/test/death_plane_check.gd:63-68; godot/fx/API.md:114-119; docs/playbooks/deaths_and_hits.md:47-61 | fx_death:2064: `rb.axis_lock_linear_y = true`; fx_death:2132: `vel.y = 0.0`; death_plane_check:68: "physics cannot push wrecks below the board" | A reason beside wreck drift/physics in the death API and working playbook. | Code and its test deliberately lock main rigid pieces in Y and zero their release velocity in Y; they still tumble. Searched playbooks, the FX API and movement spec do not document the constraint. This is about main wreck pieces, not all thrown debris. | DROPPED | A later worker implementing free three-dimensional drift from the prose can undo the board-visibility protection without knowing it exists. This is a documentation gap, not a request to change physics. | Carry the existing constraint and its test's reason into #492's death documentation. A different wreck-flight design needs its own decision and captures. | high |

The one recommended next step is to assign C1 and C2 as one export-to-runtime job before accepting the next rebuilt hull as breakable in the game. Its proof should use an installed ship, show a wound and every authored break at cameras 170 and 60, and show that moving an authored seam moves the real fracture. The other rows either have an existing job or need a precise documentation carry.

## PC evidence

The GPU was checked first: Blender was initially running, so captures waited. At the capture window Blender was absent and GPU utilisation was 3 percent. Captures used the existing `fx_inside_probe.gd`, current production FX and PC-built cached `gen` assets in an isolated TEMP project, through `tools/pc/tmo.bat`. No placeholders were reported. Forward+, NVIDIA GeForce RTX 5080, 1280 by 720. Only the private probe gained one extra shot at exactly camera radius 60, 3.5 effect seconds after the actual split. No production effect code was changed.

These are old-hull fallback captures, not new recipe hull exports. Labels identify the actual code. Open the individual images for the interior detail; the overview is reduced.

| Faction | Camera-60 capture | Non-squadron cached assets whose production cut completed |
|---|---|---|
| Sunward Crusade | [V17_37](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-540/shots/imported_0155c177/V17_37_camera60.jpg) | V14_23, V15_37, V16_37, V17_37, V18_51, V1b_r_23 |
| Hegemony Navy | [H4_11](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-540/shots/imported_0155c177/H4_11_camera60.jpg) | H10_23, H4_11, H7_23, H8_23, H9_23; also O1_37, O2_37, O3_11 objective assets |
| Ashfall Hullbreakers | [C19_51](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-540/shots/imported_0155c177/C19_51_camera60.jpg) | C13s_23, C14s_23, C15s_23, C16s_23, C19_51 |
| The Glasswrights | [I8_37](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-540/shots/imported_0155c177/I8_37_camera60.jpg) | I11_37, I14_23, I15_11, I16_11, I8_37 |
| Eclipse | [D22_23](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-540/shots/imported_0155c177/D22_23_camera60.jpg) | D20_23, D21_23, D22_23, D9_23 |
| The Chorus | [B16_23](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-540/shots/imported_0155c177/B16_23_camera60.jpg) | B16_23, B19_11, B20_11, B21_11, B22_11 |

![Six old-hull fallback captures at camera 60](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-540/shots/imported_0155c177/six_factions_camera60.jpg)

The full retained batch in that folder also includes battle-camera, wound and cooling stills for those six hulls. Initial captures in the parent shots folder had missing imported legacy textures and square gas sprites. They were preserved and rejected as visual evidence. After importing the isolated project's textures, the second batch completed without missing-loader errors. The pictures above are from that second batch. The fallback's large metal cross-sections can still read as dark plates with a grid of ribs; their presence is not an art-quality pass.

## Checks and limits of the results

- `node contrib/opus/tools/run_all_checks.js`: exit 0, 44 PASS, 2 KNOWN, 0 FAIL, 0 SKIP. The KNOWN rows are the existing seven findings failures (KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5) and twelve oracle constant differences. These were not changed.
- Godot 4.7.2 headless: `destruction_steps_check.gd`, `death_plane_check.gd`, `destruction_staging_check.gd`, `kill_slowmo_check.gd`, `flash_area_check.gd` and `nose_first_check.gd` all exited 0 and reported their passing assertions. The five FX tests were repeated after the private texture import because initial runs had missing-loader errors. No such errors remained in the repeated runs.
- Passing assertions do not mean clean engine logs: the repeated five FX runs emitted 40 existing missing-`death_timeline` metadata errors, plus one Windows root-certificate-store error per process. The six-faction capture likewise emitted six missing-timeline errors and still completed. `fx.gd:1087` reads the metadata without a default before a ship has a timeline. No script errors were recorded in the repeated FX runs. This review did not change that code.
- A TEMP-only hull scan invoked production ShipView setup, FX registration and `DEATH.precompute` on the 33 non-squadron manifest assets, waited for the actual worker output and inspected its cap arrays: 33 PASS, 0 failures. This is a boundary-backing check, not a full mesh-manifold test. It observed 3,029 zipper-triangulation fallback loops across the set, so the box-fixture sealing proof must not be silently promoted into a proof of every real hull's topology. Craft B23_51, S1_51 and S2_23 use a different live wing path and were not presented as fracture passes.
- The six-faction renderer probe exited 0. Every linked individual image was opened and visually checked. The reduced overview was composed from those images, with no generated replacement art.
- Scratch scripts, logs, private imports and test runtime files stayed in TEMP. Only this report is a repository deliverable; pictures are in the task's required issue-540 shots folder. No tracked game, asset, tool or working-document edits.

## Source handling

Read the task, HANDOFF section 0, FINDINGS, PROGRAM, REVIEW_PROTOCOL and AUDIT_BRIEF first; the old pipeline README, blob sweep and queue are context, not substitutes for the current Godot recipe. Both rule registers were searched for interiors, break lines, wrecks, shields, movement, deaths and hard points. Their proposed REWORD/RETIRE verdicts were not treated as owner decisions. R208/R209 were checked directly against FINDINGS because they postdate the registers.

Raw source was opened through `https://github.com/rcbailey12/voidsworn/raw/0155c1772845dda3bd455a96825c48d714658537/<path>` for the cited implementation/contract files. Local line reads were used for long files, without GitHub's folded display. Issue #167 was closed/completed; #363 was closed/completed; #370, #461, #463 and #538 were open; #521 was closed/completed. PR #524 was open/unmerged at head `a57fa3916b89d9fe919625d90c2c691e36cc136c`. These states were fetched read-only during this review, not inferred from OPEN_WORK's older table. No comments, labels or issues were changed.

## Read proof

The table gives physical line counts and the first 40 characters of the last line, encoded as JSON where a tab needs escaping. It records files read or searched, not a claim to have read every line. Sources opened raw match the local normalized text for all 30 implementation/contract files checked. The complete files were available through their end. Large-file line ranges explicitly inspected are listed after the table; remaining text was searched only.

| File | Lines | Last line, first 40 characters |
|---|---:|---|
| `AGENTS.md` | 122 | `"Time estimates (Ryan, Nov 4 10:40 CST, F"` |
| `CLAUDE.md` | 12 | `"- The Board thread in the Claude Code Pr"` |
| `CODEX_TASK.md` | 49 | `"_Generated by [Claude Code](https://clau"` |
| `HANDOFF.md` | 92 | `"The Oct 26 to Nov 7 history (sections 0a"` |
| `contrib/muse/reviews/dropped_sweep_2026_11.md` | 82 | `"Effect on the counts above: 38 rows in t"` |
| `contrib/opus/FINDINGS.md` | 388 | `"\| X17 \| Muse follow-up pass over unasses"` |
| `contrib/opus/OPEN_WORK.md` | 88 | `"\| PR 518 \| HANDOFF.md fix (round 8 is si"` |
| `contrib/opus/briefs/movement_spec.md` | 143 | `"- Ryan's eye: the motion strips at the b"` |
| `contrib/opus/reviews/rules_sweep/register_docs.json` | 4119 | `"]"` |
| `contrib/opus/reviews/rules_sweep/register_findings.json` | 6709 | `"]"` |
| `contrib/opus/tools/run_all_checks.js` | 250 | `"module.exports = { classifyFindings, cla"` |
| `docs/REVIEW_PROTOCOL.md` | 35 | `"- Claude checks every claim against the "` |
| `docs/archive/handoff_history_2026_11.md` | 300 | `"**Waiting on Ryan:** #48 calls (design r"` |
| `docs/playbooks/PROGRAM.md` | 175 | `""` |
| `docs/playbooks/deaths_and_hits.md` | 153 | `"Each is one or two Codex runs and one lo"` |
| `docs/playbooks/effects.md` | 92 | `"and checks from outside. The Board makes"` |
| `docs/playbooks/factions.md` | 267 | `"  readable under the hide, with no metal"` |
| `docs/playbooks/ships.md` | 117 | `"Board whenever a gate passes but the shi"` |
| `docs/ship_pipeline/AUDIT_BRIEF.md` | 105 | `"- The heavy steps only run on the owner'"` |
| `docs/ship_pipeline/BLOB_SWEEP.md` | 63 | `"  - the seam between rebuilt parts and t"` |
| `docs/ship_pipeline/HARDPOINTS.md` | 187 | `"old A4 hulls: they keep their existing p"` |
| `docs/ship_pipeline/README.md` | 83 | `"- Game frame: bow +x, up +y, port +z. Ba"` |
| `docs/ship_pipeline/RECIPE.md` | 198 | `"- `shape_ref_yaw` 22.0 is the C15s_23 va"` |
| `docs/ship_pipeline/SHIP_QUEUE.md` | 51 | `"Concept paintings: `Downloads\\voidsworn_"` |
| `godot/assets/ships/README.md` | 125 | `"- Nothing here depends on the old `hulls"` |
| `godot/assets/ships/manifest.json` | 1725 | `"}"` |
| `godot/fx/API.md` | 374 | `"- `fx/test/check_destruction.bat` now in"` |
| `godot/fx/fx.gd` | 1392 | `"\ttmp.queue_free()"` |
| `godot/fx/fx_breach.gd` | 1860 | `"\t\t_tube(pt, points, e.R * 0.06, e.R * 0."` |
| `godot/fx/fx_death.gd` | 2437 | `"\t\t\tl[\"base\"] = 0.7 * gate"` |
| `godot/fx/fx_hull.gd` | 599 | `"\treturn Vector3(r * cos(an), r * sin(an)"` |
| `godot/fx/fx_shaders.gd` | 1944 | `"\"\"\""` |
| `godot/fx/fx_ship.gd` | 1332 | `"\t\t_dmg_request(fx)"` |
| `godot/fx/fx_weapons.gd` | 1353 | `"\t\t\t(m as ShaderMaterial).set_shader_para"` |
| `godot/fx/test/check_destruction.bat` | 51 | `"exit /b 1"` |
| `godot/fx/test/death_leap_check.gd` | 81 | `"\tquit(1 if failures else 0)"` |
| `godot/fx/test/death_plane_check.gd` | 96 | `"\tquit(1 if failures else 0)"` |
| `godot/fx/test/destruction_steps_check.gd` | 198 | `"\t\t\tedges[key] = int(edges.get(key, 0)) +"` |
| `godot/fx/test/fx_inside_probe.gd` | 263 | `"\tfx.camera = cam"` |
| `godot/fx/test/kill_slowmo_check.gd` | 81 | `"\tquit(1 if failures > 0 else 0)"` |
| `godot/gen/manifest.json` | 990 | `"}"` |
| `godot/project.godot` | 64 | `"}"` |
| `godot/render/build_assets.gd` | 487 | `"\t\t\t\treturn"` |
| `godot/render/hull_table.gd` | 56 | `"\treturn Color(hex).srgb_to_linear()"` |
| `godot/render/ship_view.gd` | 1432 | `"\t\tring.rotation.y = -rotation.y"` |
| `godot/rules/API.md` | 192 | `"- **Maths:** sin, cos, atan2, exp, hypot"` |
| `godot/scenes/battle/battle.gd` | 5487 | `"\tget_tree().quit(code)"` |
| `godot/scenes/battle/test/nose_first_check.gd` | 175 | `"\t\tfails.append(\"%s: flown on thrusters, "` |
| `godot/tools/ci/godot_checks.txt` | 85 | `"gpu\|fx/test/vent_look_probe.gd\|env:VENT_"` |
| `tools/blender/r209/armA7.py` | 198 | `"    print('[209]', json.dumps(meta)[:300"` |
| `tools/blender/r209/armA8.py` | 177 | `"    print('[209]', json.dumps(meta)[:300"` |
| `tools/blender/r209/bakeAb6.py` | 222 | `"    main()"` |
| `tools/blender/r209/common.py` | 251 | `"    return o"` |
| `tools/recipe/7_export.bat` | 59 | `"exit /b 1"` |
| `tools/recipe/check_export.py` | 195 | `"    main()"` |
| `tools/recipe/contract_selftest.py` | 202 | `"    sys.exit(main())"` |
| `tools/recipe/contract_tables_selftest.py` | 77 | `"    sys.exit(main())"` |
| `tools/recipe/export7.py` | 313 | `"print('[export7] written', OUT, flush=Tr"` |
| `tools/recipe/ships/C15s_23.json` | 301 | `"}"` |
| `tools/recipe/ships/_template.json` | 22 | `"}"` |
| `tools/recipe/standing.py` | 262 | `"    sys.exit(main())"` |

Large files (over 1,500 lines or 60 KB), partial review:

- `contrib/opus/FINDINGS.md`: 1-100 (opening context); individual rows R98, R99, R186, R190, R193-R195, R208-R212; 223 and 238-245 reopened; other cited rows quote-checked.
- `contrib/opus/reviews/rules_sweep/register_docs.json`: all JSON records parsed; rule text filtered for the scoped systems; no full prose review or adoption of draft verdicts.
- `contrib/opus/reviews/rules_sweep/register_findings.json`: all JSON records parsed; rule text filtered for the scoped systems; no full prose review or adoption of draft verdicts.
- `godot/assets/ships/manifest.json`: targeted searches / relevant entries, not a full read.
- `godot/fx/fx.gd`: 798-827, 974-1000, 1084-1106.
- `godot/fx/fx_breach.gd`: targeted searches / relevant entries, not a full read.
- `godot/fx/fx_death.gd`: 1-210, 570-628, 700-960, 946-1077, 1080-1385, 1382-1645, 1645-1670, 1750-1930, 1934-2090, 2090-2170, 2160-2205, 2274-2307, 2297-2307, 2360-2437.
- `godot/fx/fx_shaders.gd`: targeted searches / relevant entries, not a full read.
- `godot/fx/fx_weapons.gd`: 55-74, 1070-1120.
- `godot/scenes/battle/battle.gd`: 1667-1740, 2158-2240.

Every quote in the findings quote column was re-opened at its cited line; 27 local line/quote checks passed, plus the issue-body excerpts checked against the fetched #167/#461 bodies. No quoted code excerpt exceeds 19 words. The review ends with limitations rather than claiming the three-leg task is finished.


## Not checked

- No new recipe hull was baked, installed or destructively re-exported. C1/C2 are source-path findings, not a claim that a particular unexported Blender file has no insides.
- No visual pass on all 36 assets, every authored seam, every weapon or every faction's future design. The 33-asset scan is CPU geometry coverage; the six linked hulls are visual samples. No new full battle film, 20-ship/4K performance claim, rules parity rerun or balance audit.
- The full `check_destruction.bat` was not run: it also starts GPU fleet/probe jobs beyond this read-only sweep. Its relevant headless checks were run separately. Initial invalid texture captures were not used as proof.
- Unlisted portions of large source files and unrelated campaign, sound, UI and rule-of-play code were not reviewed. The listed read ranges delimit the code claims.
- No full closed-issue/merged-PR follow-up census or whole-project document carry review: those are legs M and O. Leg M's report exists in this checkout; leg O's named report does not. This delivers leg C only. The Board's ledger/rulebook merge and issue routing remain Board work.
