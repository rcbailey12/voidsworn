# Astra (audit): global cohesion, engine and graphics

## Summary for Ryan

The six laws give the fleet a common look on paper. The gap is where one system hands a ship to the next. Hold the two ship-interior PRs for a joint check. The ship builder still paints whole Chorus organs luminous green. When a hit opens a ship, the game drops the artist's surface detail and draws its own material over the room. Both changes can pass their own checks. Ask for one painted ship shown intact, breached and broken apart under the same battle light before rolling this out across the fleet.

Keep the planet, rock and station work moving separately. The headless checks found all six hulk factions and all four new crystal models. Two smaller fixes matter in play: Eclipse wrecks receive Hullbreaker soot, and turning off the planet remix removes the surface detail from two worlds. The proposed ship-normal compression change can be dropped. Ryan's installed engine already produced the requested format.

## Revisions

Blind review for issue 1783. Main was `e4b7d0343`. PR 1781 was open, so the engine standard and its proposed rulebook wording below use `8d4c3fd06`. The implementation heads were PR 1772 `ec62731cd`, PR 1776 `427475e00`, PR 1782 `4a15ed51b`, PR 1755 `5db436b13`, and PR 1763 `87e114db1`. Issue 1777 had an implementation brief and no open PR at the start. No PR comments or other reviewers' reports were used.

## Blocking

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Smallest fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | A breach replaces the new ship kit's material | OBSERVED | PR 1755 `godot/fx/fx_shaders.gd:2403` | `ALBEDO = mix(baked, lit, open_f);` | At full exposure the authored albedo contributes zero. The material transfer in `godot/fx/fx_hull.gd:485` copies base color, its texture and constant glow. The trim normal, roughness, occlusion and emission mask from PR 1763 never reach the shader. Every Chorus or Glasswright room also receives 0.05 metallic at line 2407, including bone and glass. A painted cutaway can pass while the same compartment loses its finish in battle. | Bind the kit's maps and role when present, then apply breach light and wreck wear to that material. Keep the procedural pattern for legacy rooms. Check one textured room through a hit and death. | High |
| 2 | The builder still treats diagram colors as finished materials | OBSERVED | PR 1763 `tools/blender/kits/chorus/stack.py:334` | `em = sb.inputs['Emission Strength'].default_value` | The vat and gland pass their diagram emission strengths of 2.0 and 0.6 to a whole-surface emitter. Bone takes the same wet trim as flesh. The Directorate trim starts at (.17, .175, .185), and Eclipse still takes its archive tint from the source room. The export check at `tools/recipe/check_export.py:248` verifies UVs, map presence and triangles. The validator accepted a V2 fixture both before and after one room gained full-surface lime emission at strength 2. | Use the room names as keys to the six faction role tables. Give bone a dry finish, emit only through the appropriate mask, and check the exported textures times their factors on the actual room surfaces. | High |
| 3 | The proposed BC5 fix calls a nonexistent Godot constant | OBSERVED | PR 1781 `contrib/opus/plans/global_cohesion_standard.md:135` | `Image.COMPRESS_RGTC` | In Godot 4.7.2 the constant lookup returned false. On a 64 by 64 RGB normal map, the existing call at `godot/render/build_assets.gd:159` returned OK and format 21, exactly `Image.FORMAT_RGTC_RG` (BC5). Following the brief literally would break the asset builder. | Keep the current call, check its return value and decoded format on a representative ship normal, and correct the #1777 brief before implementation. | High |

## High

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Smallest fix | Confidence |
|---|---|---|---|---|---|---|---|
| 4 | The Directorate's thin emergency strip covers nearly the whole wall | OBSERVED | PR 1755 `godot/fx/fx_shaders.gd:2342` | `r.z = line(uv.y * 0.5 + 0.5, 0.025) * 1.2;` | The distance test in line 2307 is inverted. Over one period, the strip mask is fully on for 95% and nonzero for 97.5%. The 0.25 emission clamp limits brightness per pixel while allowing a broadly luminous wall. A cavity light adds to that result. | Make the mask peak at the seam and fall to zero across its specified width. Check the lit area of one period and view the wall with both cavity lights active. | High |
| 5 | The rocky planet's largest map sits outside the planned color compression saving | OBSERVED | PR 1776 `godot/world/world_bake.gd:166` | `authored_image.convert(Image.FORMAT_RGBAF)` | The branch loader produced 128.0 MiB of RGB8 color and 682.7 MiB of RGBA float relief with mips. It caches the Images and supplies them to ImageTexture. Even perfect removal of the color map saves at most 15.8% of this pair. The #1780 estimate of two raw RGBA8 maps understates the input. The probe measured decoded image bytes. Resident GPU memory requires the solo PC run. | Budget the two maps separately. Keep the packed height precise through mip generation, then store height and other masks in suitable channels. Compare poles and terminators and measure peak VRAM on a rocky board before promising a saving. | High |
| 6 | Eclipse graveyard paint takes the Hullbreaker soot finish | OBSERVED | PR 1772 `godot/assets/ships/a4_props.gd:389` | `b.albedo_color = Color(0.32, 0.29, 0.27)` | The same violet source returned identical brown multipliers for Eclipse and Hullbreakers in the branch's own finish function. The hulk check rejects green on Eclipse but accepts this brown. Its brightness check also reads the multiplier alone, so a dark painted texture can still crush the hull. | Give Eclipse a powered-down obsidian finish that keeps its paint. Exercise a textured Eclipse material alongside a Hullbreaker and compare the actual albedo product. | High |

## Medium

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Smallest fix | Confidence |
|---|---|---|---|---|---|---|---|
| 7 | Two board planets lose their old surface when the remix is off | OBSERVED | PR 1776 `godot/world/world_planet.gd:117` | `if not rocky_available(): return` | With `VS_PLANET_REMIX=0`, both rocky (0) and barren (5) completed installation with the flat stand-in, no map and no planet code. Main drew procedural terrain in both cases. The same early return applies when the R01 descriptions are missing. The normal headless check requires the maps and misses this path. | Choose an existing procedural rocky/barren surface when R01 is unavailable. Run the two looks with the flag off and assert that surface detail is bound. | High |
| 8 | Crystal clusters ship without the requested low-detail meshes | OBSERVED | PR 1782 `godot/world/tools/crystal_kit.py:125` | `path = out / ('crystal_%02d.glb' % SEEDS.index(seed))` | The four outputs have 2,132 to 2,384 triangles each. Only the full crystal meshes are listed and used. The check opens the scan LODs, then validates only the full crystals. Law 4 and the world plan explicitly assign crystal LODs to #1361, but that issue's done-when asks for pictures and frame cost. | Add the low meshes to the builder, choose them for distant clusters, and make the crystal check open a near/far pair. Verify the tactical silhouette and triangle count at distance. | High |
| 9 | The two sky targets select different results | OBSERVED | Main `contrib/opus/plans/world_consistency_v2.md:91` | `Cut star density by ~85%` | On the plan's own 6,800 to 11,600 visible-dot baseline, 15% left is 1,020 to 1,740. A threshold or star-floor setting can pass the proposed gate while leaving several times the intended 250 to 500 pinpoints. A change to visibility or magnitude could reconcile them, but the two counts then measure different things. | Use the visible count as the acceptance measure. Name the 45-degree view, exposure, resolution and brightness threshold. Check an off-band and an on-band frame, then a short pan for flicker. | High |

## Low

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Smallest fix | Confidence |
|---|---|---|---|---|---|---|---|
| 10 | The written merge sequence calls shared files independent | OBSERVED | PR 1781 `contrib/opus/plans/global_cohesion_standard.md:170` | `Wave A (Parallel, Zero File Overlap)` | Stations and planets both edit `godot/render/board.gd`. All four Godot PRs edit `godot/tools/ci/godot_checks.txt`. The board edits are in different routines, but a resolution that keeps just one list addition quietly loses a gate. The plan also asks #1763 to lock the cutaway before the #1741 and #1777 lighting it needs for calibration. | Land #1724 before the shared exporter changes. Integrate the world changes in turn and verify the combined test list. Give #1741 and #1743 one joint lighting check on the #1777 settings before signing off the palette. | High |

## Engine order and acceptance

1. **Establish the #1780 baseline first.** Record cold and warm loads, first shot and first death, 20-ship p99 against 12.5 ms, and peak VRAM at 1080p and 4K. Track memory separately for color, height and sky. Try skipping empty fog and using distance LODs first. Preserve any live fog volume that can appear later. For shader stutter, measure draw-time pipeline compilations with the actual mesh, material and MSAA settings. Moving source strings to files alone cannot prove a warm pipeline. [Godot pipeline compilation guide](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
2. **Prove #1777 on an intact and a hit ship, then finish #1778 before rebakes.** Reflection lighting, direct-light AO, shadow distance and distinct surface finishes all serve the battle camera. The #1777 gate checks that maps resolve in the look setup. PR 1755's exterior wrapper at `godot/fx/fx_hull.gd:428` substitutes its own shader when damage starts. Neither the lighting nor wounds done-when assigns the first-hit handoff for these new exterior channels. Have #1777 compare the detail, clearcoat and faction finish just before and after the swap. For #1778, inspect the encoded image and channels. BC5 can carry a two-channel normal. A packed three-channel occlusion/roughness/metallic map needs all three. Compare tactical camera 170 for shimmer and close camera 26 for surface identity.
3. **Judge the value ladder on the same ship under the same light.** The planet and exterior bands overlap from 0.04 to 0.25. A 0.10 wall and a 0.04 armor base can each pass their own band. Keep 0.11 as the non-exempt wall material ceiling, measure the local emission mask and its strength separately, and compare the rendered cavity with its neighboring lit armor after the two lights, exposure and grade. Preserve the bone/glass and core exceptions. Put the six-faction, fixed-exposure comparison on a named joint deliverable. #1743's current proof asks for two contrasting builds. The approved Eclipse violet on hulls and weapons, the rose battle nebula, and the ban on purple sky wash need separate samples. The #1755 head still contains [0.34, 0.14, 0.52] in the Eclipse nebula at `godot/fx/faction_looks.json:108`. Give that sky change to #1766 when the shared palette file is integrated. Include the unlit and lit Chorus finish for the magenta and soot check.
4. **Benchmark #1779 after lighting and sky settle.** A region LUT and restrained close-camera depth of field are worth testing. Keep tactical text, hex outlines and targets sharp. Treat SSR, refraction, distortion and decals as individual comparisons with the Compatibility path. The screen texture used for refraction is captured before transparent effects, so a transparent beam behind glass is a poor acceptance target. Compare FSR2 and 4x MSAA at matched output resolution during a slow pan with moving beams and hex lines. Keep the current default pending the solo run. [Godot screen-reading guide](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html)
5. **Give sound a playback check at Gate 3.** A clean 72-item manifest can coexist with a cue fired twice per volley or a music change halfway through a bar. Keep the Wave A listening decision and check the real weapon trigger, four-stem bar transition, and pause/resume of the SFX filter in one battle. Keep #1362 responsible for faction kit debris and cut faces. Include a map-hole hulk in its comparison: PR 1772's `godot/world/blocker_visuals.gd:68` still uses the shard fallback directly, while the six-faction test exercises terrain hulks.

## Checks and commands

- Used GitHub REST to list open PR numbers, head refs and SHAs, and read the issue bodies. Read the plans and source as raw pinned Git blobs with `git show <ref>:<path>`. Compared `git diff origin/main...origin/opus/issue-<n>` for 1767, 1765, 1361, 1741 and 1743. Used `git diff --name-only` to check overlap and `git ls-tree` and `rg -n` for assets, flags, material bindings and callers.
- Exported each tested revision to a separate temporary folder with `git archive`. Ran Godot 4.7.2 with `--headless --path <branch>/godot --script res://<check>`. PR 1772's `world/test/unwired_station_hulk_check.gd` reached all six factions on 31 terrain cells. Its scene and manifest stand-ins prove routing. PR 1776's `world/test/planet_v2_check.gd` and PR 1782's `world/test/rock_scan_check.gd` each reported zero failures. The latter read all six full/low scan pairs and four crystal meshes. PR 1755's `fx/test/wounds_v2_check.gd` exercises both values of the wounds flag, the thin-plate and normal checks, cavity lights and the handoff to wrecks. PR 1763's `python tools/recipe/contract_tables_selftest.py` passed.
- PR 1772 also passed `assets/ships/test/station_size_check.gd`, including its old-path toggle. After `godot --headless --import` in the temporary PR 1755 project, `wounds_v2_check` reported PASS with no script errors.
- Tested #1763's material gate with its C19_51 V2 geometry fixture, synthetic neutral base/normal/ORM textures and a matching manifest in a temporary folder. Ran `python tools/recipe/check_export.py tools/recipe/ships/corsair_A16.json fixture_probe` before and after changing one room's emission factor and strength. Both runs returned PASS. This isolates the gate from the Blender paint stage.
- Reproduced findings 3, 5, 6 and 7 in temporary Godot scripts using `--headless --script`. Probes called the production compression expression, the R01 loader and `Image.get_data_size()`, `A4P.derelict()`, and `PL.install_board()` with the remix disabled. Sampled the shader expression in finding 4 at 100,000 evenly spaced midpoints with Python. Zero GPU captures were run.

- `node contrib/opus/tools/run_all_checks.js` on the review checkout exited 1. Of 114 rows, 107 passed, 2 matched known baselines, and 5 failed. `doc_check_tests` resolved a link outside the checkout, `fleet_list_tests` could not find concept art excluded by sparse checkout, `runner_selftest` hit an assertion, `g2_export_selftest` lacked its fixture log, and `stage5_fail_selftest` failed its sheet-paint-views case. These are standing-suite results on main. The per-PR checks above used the named branch heads.
- Reopened every finding's quoted line at its pinned revision. All ten matched. The review passed the whitespace and no-em-dash checks.

<details>
<summary>Raw source record for the review protocol</summary>

Line counts use the pinned Git blobs. The final-line field quotes its first 40 characters using JSON escapes for tabs and quotes. Empty quotes mean the last line is blank. For large files the final column gives the implementation diff windows and additional source ranges traced. The binary meshes were checked through the rock test. The two cloud direction sheets inspected were AC1361_rev2_c26 and PV2_board_c170. PV2 carries the older 53093566 stamp, and AC1361 uses bench lighting. Installed appearance is still open.

**Main**

| Raw file | Lines | Start of last line (JSON string) | Large-file sections |
|---|---:|---|---|
| `docs/RULEBOOK.md` | 703 | `"draws meshes at full detail. Set: Ryan, "` | 1-38, 137-165, 249-257, 530-551, 607-629 |
| `.claude/rules/godot-battle.md` | 142 | `"R37). Set: Ryan (R37, R40). Ids: R37b, R"` |  |
| `.claude/rules/ships.md` | 182 | `"stage 6's hand chain stays an analysis p"` |  |
| `contrib/opus/plans/global_cohesion_standard.md` | 169 | `""` |  |
| `contrib/opus/plans/world_consistency_v2.md` | 171 | ``"5. **Palette rule trap:** Grep `world_sk"`` |  |
| `contrib/opus/plans/cohesive_damage_v2.md` | 202 | `"5. Solo GPU frame-time gate check (20-sh"` |  |
| `godot/render/build_assets.gd` | 577 | `"\t\t\t\treturn"` |  |
| `docs/REVIEW_PROTOCOL.md` | 35 | `"- Claude checks every claim against the "` |  |
| `godot/world/world_living.gd` | 1496 | `"\t\tif c != null: m.set_shader_parameter(p"` |  |

**PR 1781**

| Raw file | Lines | Start of last line (JSON string) | Large-file sections |
|---|---:|---|---|
| `contrib/opus/plans/global_cohesion_standard.md` | 186 | `""` |  |
| `docs/RULEBOOK.md` | 707 | `"draws meshes at full detail. Set: Ryan, "` | 543-556 / 537-551, 613-630 |

**PR 1772**

| Raw file | Lines | Start of last line (JSON string) | Large-file sections |
|---|---:|---|---|
| `godot/assets/ships/a4_props.gd` | 391 | `"\treturn b"` |  |
| `godot/world/test/unwired_station_hulk_check.gd` | 157 | `"\t\t_report(worst == \"\", \"%s derelicts sta"` |  |
| `godot/world/blocker_visuals.gd` | 226 | `"\tnode.global_position = centre + Vector3"` |  |
| `godot/render/board.gd` | 1233 | `"\t\tBV.outline(blocker_highlights, hex_wor"` |  |
| `godot/assets/ships/test/station_size_check.gd` | 297 | `"\t\t\tn.free()"` |  |
| `godot/bench/look_bench.gd` | 909 | `"\t_clear()"` |  |
| `godot/tools/ci/godot_checks.txt` | 246 | `"headless&#124;main/test/player_path_map_ready"` |  |

**PR 1776**

| Raw file | Lines | Start of last line (JSON string) | Large-file sections |
|---|---:|---|---|
| `godot/world/world_planet.gd` | 845 | `"\"\"\""` |  |
| `godot/render/board.gd` | 1203 | `"\t\tBV.outline(blocker_highlights, hex_wor"` |  |
| `godot/world/world_bake.gd` | 467 | `"\treturn true"` |  |
| `godot/world/test/planet_v2_check.gd` | 135 | `"\tquit(0 if failures == 0 else 1)"` |  |
| `godot/world/planet_v2_shots.gd` | 317 | `"\tawait _save(name)"` |  |
| `docs/shots/issue-1765/README.md` | 19 | ``"```"`` |  |
| `godot/scenes/battle/battle.gd` | 7040 | `"\tget_tree().quit(code)"` | 797 |
| `godot/tools/ci/godot_checks.txt` | 246 | `"headless&#124;main/test/player_path_map_ready"` |  |
| `godot/world/world.gd` | 1504 | `"\tif _living != null: _living.use_ship_de"` | 581-603 |
| `godot/world/world_sky.gd` | 531 | `"\treturn out"` |  |

**PR 1782**

| Raw file | Lines | Start of last line (JSON string) | Large-file sections |
|---|---:|---|---|
| `godot/world/world.gd` | 1493 | `"\tif _living != null: _living.use_ship_de"` | 902-925, 1049-1059, 1070-1082, 1120-1138 |
| `godot/world/world_rocks.gd` | 627 | `"\t\treturn n"` |  |
| `godot/world/tools/crystal_kit.py` | 137 | `"        build(s, out)"` |  |
| `godot/world/test/rock_scan_check.gd` | 143 | `"\t\t_: return bytes.decode_u8(at) / 255.0"` |  |
| `contrib/opus/tools/issue1361/README.md` | 11 | `"Compatibility renderer: a SPECULAR that "` |  |
| `contrib/opus/tools/issue1361/rock_bench.gd` | 70 | `"\tquit()"` |  |
| `godot/tools/ci/godot_check_times.txt` | 168 | `"rules_1649_test 3"` |  |
| `godot/tools/ci/godot_checks.txt` | 247 | `"headless&#124;main/test/player_path_map_ready"` |  |
| `godot/world/rocks/rocks.json` | 236 | `"}"` |  |
| `godot/world/rocks/scans.json` | 163 | `"}"` |  |
| `godot/world/tools/rockgen.py` | 394 | `"    main()"` |  |
| `godot/world/tools/scan_facet.py` | 121 | `"    main()"` |  |
| `tools/pc/jobs/planet369_remix.py` | 295 | `"        rocks()"` |  |

**PR 1755**

| Raw file | Lines | Start of last line (JSON string) | Large-file sections |
|---|---:|---|---|
| `godot/fx/fx_shaders.gd` | 2798 | `"\"\"\""` | 1575-1582, 1643-1706, 1756-1794, 1896-1924, 2098-2125, 2170-2172, 2197-2244, 2267-2428 / 2273-2427 |
| `godot/fx/fx_hull.gd` | 2001 | `"\t\t\t\t(lb[\"node\"] as Node3D).transform = ("` | 2, 128-133, 152-158, 307-319, 357-379, 402-413, 475-516 / 248-315, 353-402, 422-451, 475-514 |
| `godot/fx/fx_breach.gd` | 2386 | `"\tm.set_shader_parameter(\"glow\", Vector3("` | 24-25, 58-73, 92-96, 165-168, 530-550, 907-923, 1218, 1727-1763, 1789-1858, 1902-1919, 1972, 2003-2386 / 544-563, 1793-1866, 2014-2200, 2261-2386 |
| `godot/fx/test/wounds_v2_check.gd` | 381 | `"\tquit(0 if failures == 0 else 1)"` |  |
| `godot/fx/faction_looks.json` | 112 | `"}"` |  |
| `godot/fx/fx_ship.gd` | 2967 | `"\t\t_dmg_request(fx)"` | 1788-1855, 1927-1955, 2037, 2136-2178, 2950-2952 / 1785-1860, 1924-1960, 2030-2045, 2133-2194, 2526-2654 |
| `godot/fx/fx.gd` | 2284 | `"\treturn hk"` | 1138-1140, 1193, 1450-1459, 2273-2283 |
| `godot/fx/fx_death.gd` | 4248 | `"\t\tnd.global_position -= back"` | 1419, 1525-1526, 1809-1810 |
| `godot/fx/fx_weapons.gd` | 2696 | `""` | 33, 2100-2101 |
| `godot/bench/look_moments_wounds_v2.json` | 1985 | `"}"` | 1-1985 |
| `godot/fx/API.md` | 629 | `"neither these tools nor their pictures r"` | 271-288 |
| `godot/tools/ci/godot_checks.txt` | 247 | `"headless&#124;main/test/player_path_map_ready"` |  |

**PR 1763**

| Raw file | Lines | Start of last line (JSON string) | Large-file sections |
|---|---:|---|---|
| `tools/blender/kits/chorus/stack.py` | 347 | `"    return material"` |  |
| `tools/blender/build_sheets/kit.py` | 1230 | `"        self.tbd.append(what)"` | 499-509 / 54-124, 1142-1158 |
| `tools/blender/kits/eclipse/stack.py` | 530 | `"    return out"` |  |
| `tools/blender/kits/hegemony/stack.py` | 695 | `"    return [(tuple(int(v) for v in C[j])"` |  |
| `tools/blender/kits/shared/interior_trim.py` | 250 | `"    return trim_material(name, fac, spec"` |  |
| `tools/recipe/check_export.py` | 429 | `"    main()"` |  |
| `tools/recipe/contract_tables_selftest.py` | 95 | `"    sys.exit(main())"` |  |
| `docs/playbooks/ships.md` | 620 | `""` | 441-461 |
| `docs/ship_pipeline/RECIPE.md` | 717 | ``"- `shape_ref_yaw` 22.0 is the C15s_23 va"`` | 202-207, 501-505 |
| `godot/fx/test/fixtures/C19_51_unbaked.sheet.txt` | 16 | `"# fixture sha256 5b1a17a14421af1fa8b833a"` |  |
| `tools/blender/build_sheets/cutaway.py` | 151 | `"print('[cutaway] wrote', os.path.join(OU"` |  |
| `tools/blender/build_sheets/interior_kit.py` | 690 | `"    return summary"` |  |
| `tools/blender/kits/hullbreakers/stack.py` | 657 | `"                violet=km(im[(im[:, 2] >"` |  |
| `tools/blender/kits/ithar/hull.py` | 1072 | `"        review(mod, Path(args[1]))"` | 670-709, 739-754 |
| `tools/blender/kits/ithar/stack.py` | 600 | `"    return m"` |  |
| `tools/blender/kits/shared/hardpoints.py` | 301 | `"    return probs"` |  |
| `tools/blender/kits/shared/paint_stack.py` | 1346 | `"    bake_existing_atlas(stack, args.sour"` | 1230-1237 |
| `tools/blender/kits/voidsworn/stack.py` | 636 | `"    return [(tuple(int(v) for v in C[j])"` |  |
| `tools/recipe/7_export.bat` | 64 | `"exit /b 1"` |  |
| `tools/recipe/check_export_selftest.py` | 312 | `"sys.exit(1 if bad else 0)"` |  |
| `tools/recipe/export7.py` | 665 | `"print('[export7] written', OUT, flush=Tr"` |  |
| `tools/recipe/sheet_fixture_hash.py` | 154 | `"    sys.exit(main())"` |  |

</details>

**Recommended next step.** Pair the interior builder and wounds changes on the painted Chorus Bladeback (B21_11). Verify the material inputs, strip coverage and intact-to-wreck handoff before asking for the six-faction battle capture.

**Not checked:** Lane C is code only. Installed-battle appearance, camera-pan shimmer, actual VRAM, 20-ship frame times, Blender cutaway fits and zero seam leaks need their PC jobs. Audio playback and the unimplemented #1777 to #1780 features were reviewed as plans. The linked engine behavior is documented. Its cost and appearance on Ryan's PC remain unmeasured.
