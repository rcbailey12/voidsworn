# D2 reference and tooling verification (read-only)

Repo HEAD d5d0227. Game code unchanged since Oct 22. Babylon API facts checked against the babylonjs@8.20.0 npm build (fetched into scratch, not into the repo). Nothing in the repo was modified.

## Proof of reading

| # | File | Lines (wc -l) | First 40 chars of last line | Read |
|---|---|---:|---|---|
| 1 | contrib/muse/design/visual_expansion_research.md | 421 | `All URLs above were opened or returned b` | full |
| 2 | contrib/muse/design/GRAPHICS_REFERENCES.md | 436 | `8. Rogue Trader wiki, Space Combat page ` | full |
| 3 | contrib/muse/design/mod_scene_field_guide.md | 392 | `Check before you ship: Shadertoy default` | full |
| 4 | contrib/muse/design/claude_skills.md | 86 | `3. Add the two process fixes that need n` | full |
| 5 | contrib/muse/design/tool_guides.md | 762 | `- UltraTex: recent and community noded. ` | full (1-419, 420-762) |
| 6 | contrib/muse/design/verification_sweep.md | 165 | `Only two items remain fully open: TripoS` | full |
| 7a | contrib/gemini/reviews/effects_world.md | 97 | `  - Live GPU profiler timings on the Pix` | partial (table 74-97) |
| 7b | contrib/gemini/reviews/texture_pass.md | 118 | ``  - `tools/blender/hs/detail_lib.py`, `t`` | spot (rows 99-110) |
| 7c | contrib/gemini/reviews/ship_pipeline_audit.md | 180 | ``   * In [`ships3d.js`](https://github.co`` | spot (27, 50-56, 143, 180) |
| 7d | contrib/gemini/NOTES.md | 28 | ``   - Passes explicit `view|mask|az|el|we`` | full |
| 8a | contrib/codex/reviews/ship-model-audit-2026-10-21.md | 267 | `- Scope and acceptance: [AUDIT_BRIEF.md]` | spot (86-94) |
| 8b | contrib/codex/reviews/ship_loading.md | 32 | `Not checked: No other game source, asset` | full |

Phone/Pixel/mobile mention counts: visual_expansion 71, tool_guides 13, codex ship-model-audit 10, gemini ship_pipeline_audit 6, field guide 3, claude_skills 2, effects_world 2, texture_pass 2, GRAPHICS_REFERENCES 1, sweep 1, NOTES 0, ship_loading 0.
Cyan-shield mentions: visual_expansion 3, GRAPHICS_REFERENCES 2, field guide 1, tool_guides 1.

## 1. visual_expansion_research.md: phone-first technique catalogue; partly redundant with shipped code

1. STALE (B): line 3 "must perform on a mid-range Android phone (a Pixel is the reference device)"; 71 phone mentions, including 7.7 "Cinematic phone budget" and the 6.6 verdict ("the Pixel line is exactly the class of device...").
2. STALE (owner ruling): line 157 shield ripple "in the shield colour (cyan, per the art direction colour law)"; also 387 and 410.
3. WRONG against code / E: line 175 "FXAA off when MSAA samples are on". The game runs both: scene3d.js:26 `pipe.samples=4; pipe.fxaaEnabled=true;`; setQuality (scene3d.js:113) only drops FXAA when TAA is on.
4. E: bloom threshold "about 0.85" (175, 374). The game uses 0.5 (scene3d.js:27) and tool_guides:210 says 0.7. That is three different values.
5. STALE: 5.1 recommends plain parallax on hero hulls. It already ships: ships3d.js:66 `m.useParallax=true; ... parallaxScaleBias=.022`.
6. STALE: pick 7 "GlowLayer ... Gate it by device tier". The GlowLayer is already always on (scene3d.js:24), with tiered blur (scene3d.js:113).
7. WRONG pipeline assumption: 4.1 (209) and 7.3 (376) say to add gltfpack `-si/-mi/-tc/-kn`. "Already uses meshoptimizer" is VERIFIED (meshopt3d.js:1 decoder; tools/blender/vsm_pack.mjs uses MeshoptEncoder), but the hulls are custom JSON/.vsm plus WebP (ships3d.js:801) and no glTF loader is bundled, so the gltfpack flags have nothing to act on.
8. VERIFIED (Babylon 8.20.0 build): line 173 defaults bloomThreshold .9, bloomKernel 64, bloomScale .5, bloomWeight .15.
9. E / STALE: the 6.6 WebGPU hybrid "worth it" (top-10 #10) and the 6.1 Godot "worth it later" verdicts pre-empt the open engine question (the 6-ship Babylon vs Godot test comes first). Godot is judged on its web and Android exports, which do not matter for a PC-only game; desktop Forward+ is the relevant comparison. Line 322 credits Babylon 9 features that 8.20 lacks.
10. D (from knowledge, not checked against the install): 4.4 (228) calls Discombobulator "bundled with Blender". It shipped inside Add Mesh: Extra Objects, which became a downloadable extension in Blender 4.2, so it is not bundled in 4.5.14. VERIFIED: six factions (ships3d.js:61).

## 2. GRAPHICS_REFERENCES.md: external study list; two stale rulings

1. STALE (C): line 127 Quaternius "Licence: CC0 per the pack pages". The current licence is QAL v1.0.
2. STALE: the cyan-shields law at 39 and 194.
3. UNCHECKABLE (not in code): "Voidsworn's three delta-v bands" (19, 304). No such mechanic exists in battle.js, core.js or data.js; it is a design proposal only.
4. VERIFIED: "per-facing shields" (395). data.js:404 "knocks out an enemy shield facing"; battle.js:15 "every facing".
5. VERIFIED: borrowed 40k terms are still in data.js (57, 292), for example data.js:35 'Las-turret', 'Penance lance'.
6. VERIFIED: the 18-plate catalogue (179); CONVERSATION_CONTEXT.md:30 "18 background plates".
7. VERIFIED: line 370 framing "PC-only Babylon tactics game". graphics_craft.md and CONVERSATION_CONTEXT.md both exist.
8. UNCHECKABLE: 392 "bloom threshold set so plates never bloom". This cannot be checked from code at the game's 0.5 threshold without measuring plate luminance.

## 3. mod_scene_field_guide.md: good licence hygiene; sound section stale; internal contradictions

1. STALE (C): Quaternius "CC0" (31) and 253 "the site FAQ states all models are under CC0". The current licence is QAL v1.0.
2. STALE: "Sound, the big gap" (341), "the missing sound layer" (246) and Sonniss "closes most of the sound gap" (22). The game already ships Kenney CC0 and Sonniss GDC 2026 clips (sfx_data.js:1, commit 9f28d1f, Oct 20) layered over synthesised sound (sfx.js:2).
3. E internal: 298 Materialize "verified through a third party walkthrough only" contradicts 38 and 392 ("GPLv3 ... confirmed via the vendor FAQ"). The sweep (item 9) confirms GPLv3, so 298 is stale.
4. STALE: 337 "matched to the cyan shield colour law".
5. C (public repo): 350 says Sonniss sound files may not be handed to anyone else. The public repo carries those clips as base64 in sfx_data.js. The doc does not address whether a public source repo counts as redistribution, so this needs an owner decision.
6. C: ArmorPaint binaries $19 (288), Laigter paid binaries (293), PanksCreations premium tier (273) and alkakrab's paid pack (360) are all flagged in place. They fit the free-only rule only through build-from-source or the free tiers.
7. VERIFIED: "census CSVs in its compute pack" (160); contrib/muse/compute/census_*.csv.
8. VERIFIED: "the shield dome in fx3d" (311); fx3d.js:419 `shieldDome(v,d,...)`.

## 4. claude_skills.md: headline recommendation blocked by the PC's Blender

1. STALE (D): line 5 calls the official Blender MCP "the single biggest capability jump", and 85 trials it "on the condition that the PC's Blender is 5.1 or newer". The PC runs portable 4.5.14 (CLAUDE.md:3), so only the community blender-mcp (Blender 3.0+, line 54) applies.
2. STALE (B): "Pixel stress gate before hull 6" (21) and "the Pixel stress gate" (70). The phone gate is retired.
3. VERIFIED: AGENTS.md:38 has the 3-to-5 multiple-choice rule (cited at 44); docs/REVIEW_PROTOCOL.md exists (68); the 36-hull queue (70) matches the 36 JSONs in hulls/ and hulls_hi/.
4. VERIFIED: no .claude/skills folder exists yet, so recommendation 1 is still open.
5. UNCHECKABLE: the bundled `/run`, `/verify`, `/run-skill-generator` skills and "commit instructions run the verify skill" (27). Not verified.
6. STALE minor: "roughly 52,000 words of design material" (11). The design folder is now about 74,650 words (wc).

## 5. tool_guides.md: desktop re-tier note added, but the body assumes a glTF pipeline and has one wrong API

1. WRONG (D, Babylon 8.20.0): 274 and 502 say to override `KhronosTextureContainer2.JSModuleURL`. In 8.20.0 the KTX2 decoder is relocated through `KhronosTextureContainer2.URLConfig` (`jsDecoderModule`, `wasmUASTCToBC7`, ...). `JSModuleURL` belongs to BasisTools. The sweep's item 13 gives the correct form.
2. WRONG against the repo: 89 (`<hull_code>_hi.glb` / `.glb`), 557 (`game\hulls\%HULL%.glb`) and 183 (load the .glb in the Sandbox). The game loads hulls/<id>.json (.vsm for C19_51) plus _m/_n.webp (ships3d.js:801; hulls_hi holds 36 json and 72 webp). No glTF loader is bundled. Top find 15 (the glTF occlusion hook "the game's ORM materials need") does not apply either: ORM is built at runtime (ships3d.js:62-67).
3. STALE: the 551 path `C:\Program Files\Blender Foundation\Blender 4.5\blender.exe`. The real binary is the portable `voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe` (CLAUDE.md:3).
4. WRONG for 4.5.14 (D, from knowledge): 154 says 3D Print Toolbox and MeasureIt are "free and already installed". Since 4.2 they are extensions you download; line 676 itself says "installed from Edit, Preferences, Get Extensions", so the doc contradicts itself.
5. D: GPUParticleSystem "falling back to ParticleSystem automatically" (358) is likely wrong, because Babylon expects you to check `GPUParticleSystem.IsSupported` yourself (not confirmed in the source). "9.32.0 ... Inspector Lite" (383) is a Babylon 9 feature; it is absent from the 8.20 build.
6. VERIFIED: 182 "desktop hulls roughly 2,400 to 38,000". hulls_hi `t` runs 2400 to 38000; hulls/ runs 1200 to 16000. The "retired" low tier is still shipped, and the code still has phone paths (ships3d.js:716 `AI_HI_ON_PHONE`, scene3d.js:112 `G.mobile`).
7. STALE: 729 "cyan means shields, nothing else is cyan".
8. E internal: 757 says the Hunyuan VRAM and exclusions are "secondhand ... not the licence text", while 645 and 27 say they were verified in the sweep. Rodin pricing "varies by reporting year" (663, 759) is also stale after sweep item 14.
9. C: the paid add-on table (146-152), plus SimpleBake (128) and Normal Magic (139), conflicts with the free-only rule. These should be marked out of scope rather than priced.
10. D: Blender manual citations are from 2.80, 2.81 and 3.4 (39, 109, 118, 134), and the emission export note (43) comes from the 2.81 manual. The doc does flag these for checking against 4.5.14.

## 6. verification_sweep.md: mostly sound; stale on the Blender version and its own line numbers

1. STALE: line 161 "The PC's installed Blender version is still the open check". It is resolved: 4.5.14 (CLAUDE.md:3). That rules out the official MCP, which needs 5.1+.
2. STALE (B): the item 10 replacement wording (90), "On a phone GPU, MSAA or FXAA remains the right default".
3. STALE references: the cited tool_guides lines 142-147, 184, 637 and 752 no longer match the file; 637 and 752 are blank. The corrections did land at 641 and 756 (DreamGaussian) and 146-151 (prices).
4. VERIFIED: TAARenderingPipeline is separate from the default pipeline, and the game uses it (scene3d.js:105). The reprojectHistory, clampHistory and disableOnCameraMove properties exist in 8.20. TONEMAPPING_ACES=1, STANDARD=0, KHR_PBR_NEUTRAL=2.
5. VERIFIED: the item 13 URLConfig key names are present in the 8.20 build.
6. C: items 11 and 14 supply prices for paid add-ons and services (UVPackmaster $55, DECALmachine $54.99, Rodin, Luma). These are out of scope under the free-only rule.

## 7. Gemini

- NOTES.md: "Blender 4.5's default AgX tone-mapper" is VERIFIED; the 4.x default view transform is AgX, which fits 4.5.14. The edits it describes are to contrib copies and were not checked.
- effects_world.md: 3 sampled quotes land on their cited lines (fx3d.js:35 `ShaderMaterial('ringM'`, scene3d.js:662 `G.glow.addExcludedMesh(moon)`, fx3d.js:161 `const hr=clamp(u.hp/u.maxHp`). Line 97 mentions "Pixel 10 XL" timings (B, minor).
- ship_pipeline_audit.md: line 54 "desktop loads hulls_hi/C19_51.vsm at 1.5M to 2M triangles" is UNCHECKABLE at HEAD. C19_51 is the only AI_VSM hull (ships3d.js:764), but no .vsm file is committed, and the repo fallback hulls_hi/C19_51.json is 38,000 tris. Line 56 "60k for phone" is STALE (B).
- texture_pass.md: not verified.

## 8. Codex

- ship_loading.md: VERIFIED. All 8 quotes match their cited ships3d.js lines, for example :801 `try{ r=await fetch(dd+id+'.json'); }catch(e){}`. It reviewed commit c623419, but ships3d.js is unchanged since Oct 22, so the findings still apply.
- ship-model-audit-2026-10-21.md: only spot-read; 10 phone mentions; quotes not verified.

## Not checked

The texture_pass, ship_pipeline_audit and codex ship-model-audit bodies; the c19_kit.py claims; gltfpack flags against a current man page (they look right, but -tc native-only and "no Draco" are unconfirmed); basisu XUASTC flags; Babylon Editor and Kenney counts; and all game-comparison facts in GRAPHICS_REFERENCES sections 4-7. The Blender 4.5 extension status (3D Print Toolbox, MeasureIt, Discombobulator) is from knowledge, not checked against the PC install.
