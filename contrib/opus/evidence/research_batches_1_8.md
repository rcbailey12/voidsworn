# B: Research-batch verification (Voidsworn, HEAD d5d0227)

Read-only verification of the 16 research legs (8 Rey "leg 1", 8 DeepSeek "leg 2") and the OPUS_HANDOFF.md summaries. Nothing in the repo was modified. Every finding is marked OBSERVED (seen in a file, in code, or on a fetched primary source) or INFERRED.

Access limits hit during spot-checks (reported, not routed around): docs.godotengine.org, quaternius.com, projects.blender.org and reddit.com gave proxy 403s to curl. reddit.com, buzzradr.com and projects.blender.org (via WebFetch) also failed with "permission request not answered". GitHub raw sources (godot-docs, godot, glTF spec, glTF-Blender-IO) and npm tarballs (@babylonjs/core, @babylonjs/loaders) were reachable, so primary checks use those. In each case the source used is the source behind the official site.

## 1. Proof of reading

All 16 files were read in full, plus OPUS_HANDOFF.md (sections 2 and 5 in particular). Line counts come from `wc -l`. "Last line" is the first 40 characters of the last non-empty line.

| File | Lines | Last line (first 40 chars) |
|---|---|---|
| muse/research/engine_comparison_2026_10_24.md | 101 | `- Rate limits or blocks encountered: non` |
| deepseek/research/engine_comparison_deepseek_2026_10_24.md | 156 | `All of this remains leads. The coder dec` |
| muse/research/subreddit_mining_batch2_2026_10_24.md | 105 | `- No rate limit or block stopped this ro` |
| deepseek/research/batch2_workflows_deepseek_2026_10_24.md | 202 | `Notes on this leg: sign-in was not requi` |
| muse/research/nemesis_events_batch3_2026_10_24.md | 127 | `- The WB Nemesis system patent was menti` |
| deepseek/research/batch3_nemesis_deepseek_2026_10_24.md | 283 | `- Nothing in this research required sign` |
| muse/research/wings_tactics_batch4_2026_10_24.md | 118 | `- The carrier air defense piece is histo` |
| deepseek/research/batch4_wings_deepseek_2026_10_24.md | 75 | `DeepSeek itself flagged the 1942 interce` |
| muse/research/physics_graphics_motion_batch5_2026_10_24.md | 131 | `- The Star Citizen GPU particle claim (1` |
| deepseek/research/batch5_physics_graphics_motion_deepseek_2026_10_24.md | 215 | `END OF RESEARCH FINDINGS.` |
| muse/research/opus_blender_batch6_2026_10_24.md | 224 | `- Headless EEVEE rendering needs a graph` |
| deepseek/research/batch6_opus_blender_deepseek_2026_10_24.md | 105 | `No code was produced or requested. Nothi` |
| muse/research/effects_batch7_2026_10_24.md | 266 | `- Secondary summaries used and flagged: ` |
| deepseek/research/batch7_effects_deepseek_2026_10_24.md | 182 | `END OF RESEARCH FINDINGS.` |
| muse/research/asset_packs_batch8_2026_10_24.md | 265 | `- The Babylon PBR slot mapping in Findin` |
| deepseek/research/batch8_asset_packs_deepseek_2026_10_24.md | 104 | `Method notes: all five prompts were run ` |
| muse/OPUS_HANDOFF.md | 138 | `- Work only inside contrib/muse/ (Rey) a` |

## 2. Per-batch agreement and disagreement

"Primary" means official docs, a spec, a licence page or a developer's own statement. "Heuristic" means a guide value, a blog value, or the leg's own inference.

### Batch 1: engine comparison
| Topic | Leg 1 (Rey) | Leg 2 (DeepSeek) | Status |
|---|---|---|---|
| Overall lean | Stay Babylon to ship fastest; Godot 4 is the mover; Bevy not justified | Same | AGREE |
| Godot migration time | "weeks" (playable port) to "a few months" (full parity); labelled inference | No number given ("substantial but tractable", reasoned range only) | Only leg 1 gives a range. Heuristic, no source. The handoff labels it "an inference" correctly but does not say it is single-leg. |
| Babylon desktop draw-call budget | 500 to 1,000 at 60 fps (dev.to author's own estimate, flagged) | 1,500 "desktop threshold", attributed to babylonjs.com and doc.babylonjs.com (bare root URLs plus "cursor 0") | DISAGREE (500-1000 vs 1500). OBSERVED: Babylon's "Optimizing your scene" doc source (BabylonJS/Documentation, optimize_your_scene.md) has no 1,500 figure. DeepSeek's attribution to official docs is unsupported. Both numbers are heuristics. |
| Electron size | none | "120 to 160 MB runtime per OS" (npm gameshipper) | Single leg. OBSERVED: the gameshipper README says "The first build for each OS downloads Electron (120 to 160 MB, cached after that)". That is a download on the build machine, not a shipped runtime or a player download. It comes from a third-party tool README, not from Electron. The handoff repeats "runtime per OS" framing. |
| Tauri size | none | none | No figure exists in either leg. |
| MultiMesh caveat | Same mesh many times, one material per surface (Godot 4.0 docs) | Identical geometry required; mixed-shape plating may resist (GitHub repo) | AGREE. Verified (section 4f). |
| Godot 6-week claim | Quarantined: "must not be cited until the original post is found and read" (line 97) | "OBSERVED as a community report" via a BuzzRadr summary: "solo developer with no prior coding... created a playable game in six weeks" (line 119) | DISAGREE in framing. Leg 2 treats it as evidence of a quick playable prototype. Neither file carries the handoff's qualifications (section 3). |
| BG3 autonomous playthrough | Listed UNVERIFIED, "explicitly NOT used as evidence" (line 97) | absent | Quarantined (section 3). |

### Batch 2: subreddit mining and workflows
| Topic | Leg 1 | Leg 2 | Status |
|---|---|---|---|
| Forward+ vs Compatibility | Renderer trap, from a vibingtalk mirror comment | Official Godot 4.4 renderers page (B1, B2) | AGREE. Verified. |
| Decals in Compatibility | n/a | "Decals are Forward+/Mobile only" (B3, non-canonical zh-cn .rst URL) | OBSERVED as correct for released docs (4.4, 4.5, 4.6, 4.7, stable branches: "Not supported"). The godot-docs master branch now lists Compatibility decals as supported (8 per surface, 64 per view), so the claim is version-sensitive. |
| Babylon MCP | "THIN": no editor-level live loop found | Official @babylonjs/mcp-servers for the node and graph editors exist; inspector MCP is immature | Partial disagreement, but both can be true. OBSERVED on npm: @babylonjs/mcp-servers 9.32.0 (created 2026-06-04) and babylonjs-inspector-mcp 0.1.1. |
| "Project is Godot-based" | n/a | The leg's own SKIP verdicts on D6, D7 and bottom line 6 used this ground | Corrected inline by CHAIR CORRECTION notes, not by DeepSeek (section 3). |
| Cascadeur | "NOT found in this round" | Found: Cascadeur 2026.2 with a new MCP server (CG Channel, C6) | DISAGREE. The handoff reports only leg 1 ("Cascadeur not found this round"). |
| Tripo | ADAPT for prototyping and candidate parts | SKIP for hero ships, ADAPT for blockouts | AGREE in substance. |
| Noise-mask damage shader | n/a | DamageAmount 0-100, threshold, instance uniforms (godotshaders) | Single leg here; batch 7 leg 1 also has it. Community shader, not checked. |

### Batch 3: Nemesis and events
| Topic | Leg 1 | Leg 2 | Status |
|---|---|---|---|
| Rival template (Mordor) and XCOM Chosen | Visible hierarchy, memory, intel; knowledge bar plus covert counterplay | Same; adds "adapts to playstyle" reads as marketing (F7) | AGREE. |
| Adaptation model | L4D-director style: counter the last battle's tactics and relent after a punishing loss | 2 fixed weaknesses plus 1 new strength per sector, capped, at least 2 counter-tools | Compatible. Leg 2 is more conservative. Both are inference. |
| Succession | Known lieutenant fills the vacancy | Deterministic highest-Power inherits (Shadow of War Fandom), but Wikipedia says captains battle for the slot (flagged conflict) | AGREE on shape. The handoff's "deterministic succession" drops the source conflict leg 2 flagged. |
| Numbers | FTL: 12 distress events, 2 with medbay blue options (Steam thread); StS2 HP escalation 3, 6, 12, 24 (guide blog) | FTL about 320 events (player estimate); StS 52 events (fan archive); Crying Suns 300+ (App Store listing) | All secondary. No primary source for any count. |

### Batch 4: wings and tactics UI
| Topic | Leg 1 | Leg 2 | Status |
|---|---|---|---|
| Stances as positioning and targeting | Yes (Homeworld, Stellaris) | Yes | AGREE. |
| "1942" | Item 7: historical US carrier air-defence doctrine of 1942 (dougcflattop substack), "framing source, not evidence about any game" (line 118) | Item 6: "1942 (video game)" on Wikipedia, no switchable stance, SKIP | DIFFERENT REFERENTS. Leg 1 cites WWII doctrine; leg 2 checked the arcade game (section 3). |
| Screen as intercept zone | 1942 doctrine framing | World of Warships patrol fighters, 2.5 to 3.6 km, about 60 s (official WoWs wiki), flagged as consumables, not a stance | Leg 2 has the game precedent. Neither file says "better precedent". |
| Starsector FRR | Decay at or below 2/3 complement, 30% floor, B-Deck at 50% | Same (wiki.gg plus forum) | AGREE. Fan wiki, version-dependent. |
| Zero-K veterancy | A developer explains why Zero-K has NO veterancy bonuses (Steam discussion) | Zero-K veterancy "mainly increases health, reduces reload time and weapon inaccuracy" (Steam news, Cold Take #15) | DISAGREE on a factual point. UNCHECKED: the Steam news page did not render its text. |
| Battlefleet Gothic | Armada video game: 45 s duration, 120 s cooldown, about 20% (namu wiki plus Steam) | Tabletop rules: Leadership check (fan-hosted PDF root URL) | Different games under one name. Both weak. |
| Switch cadence | Price the switch (BattleTech morale) | One free switch per round, further switches priced (inference, flagged) | Compatible. The handoff value is leg 2's inference. |

### Batch 5: physics, graphics, motion
| Topic | Leg 1 | Leg 2 | Status |
|---|---|---|---|
| Hitstop | 3 to 6 frames (0.05 to 0.1 s) heavy impact | none in batch 5 | Leg 1 only. Secondary summaries of talks, flagged as starting values. |
| Shake | 0.2 to 0.5 s decaying | Reserve screen shake for capital events | Compatible. |
| Deadlock playback | About 15 s per turn (Prima review) | n/a | Batch 7 leg 1 cites 12 s per turn (Steam forum). Cross-batch conflict, both secondary. |
| Torpedo | Flight time as a dodge window (EVE wiki, historical Shkval) | Real flight time with impact-time damage; damage-on-launch rejected (player forum posts) | AGREE. Code comparison in section 5. |
| Tonemapping | n/a | "Babylon DefaultRenderingPipeline (bloom, ACES/AgX tonemap)" (finding 18); Godot has AgX since 4.4 | WRONG for Babylon: AgX does not exist in Babylon 8.x or 9.x (section 4g). Godot 4.4 AgX is VERIFIED (Environment.xml at 4.4-stable has TONE_MAPPER_AGX). |
| Bloom | n/a | bloomScale about 0.5 to 1.0 (CSDN, truncated URL) | Heuristic. |
| ORM | n/a | Godot R=AO, G=Roughness, B=Metallic; Babylon "defaults to ORM-style" | Godot claim is consistent with the glTF spec. Babylon uses metallicTexture plus channel flags, which the game already does (section 5). |
| "Reconciled, no substantive conflicts" | | | Fair for batch 5. |

### Batch 6: Opus plus Blender
| Topic | Leg 1 | Leg 2 | Status |
|---|---|---|---|
| Official Blender Lab MCP | Exists, v1.0.0 April 2026, behind Anthropic's connector (StraySpark blog) | Minimal Python-exec plus summaries, 26 tools (StraySpark), CLI variants (README) | AGREE. Existence VERIFIED on blender.org (section 4h). Dates and tool counts are secondary. |
| Community server | ahujasid blender-mcp, closed loop | blender-mcp-ultra (about 248 tools), safe mode | Compatible. |
| Dropped maps mechanism | Per-map audit checklist | "Two separate textures: the exporter silently drops them; bump maps are never exported" (Stack Overflow revision) | Bump: VERIFIED. Separate metal/rough: WRONG for the current exporter (section 4b). |
| Acceptance gate | Reimport into an empty file, per-map audit, transforms, decimation check | glTF-Validator (Khronos docs via Vulkan tutorial), ModelCheck-style | Compatible. |

### Batch 7: focused effects pass (the numbers that matter)
| Number | Leg 1 | Leg 2 | Handoff | Source tier |
|---|---|---|---|---|
| Hitstop | 3 to 6 frames (0.05 to 0.1 s); one guide 60 to 120 ms; no URLs returned | 2 to 5 frames normal, 8 to 12 kills and crits (eremes81 GitHub manuscript, path truncated; raduacg repo) | "2-5 frames normal, 8-12 kills" | Heuristic, all secondary. DISAGREE on bounds; leg 1 has no kill tier. |
| Shake duration | 0.2 to 0.5 s decaying (no URL) | at most 0.25 s, positional, exponential decay (StraySpark blog); action conventions 0.1 to 0.6 s by tier (raduacg) | "at most 0.25s" | Heuristic. DISAGREE (leg 1's upper bound is twice leg 2's). |
| Shake bands | trauma cap about 12 px, decay 4.0/s, +0.4 per hit (no URL) | light 2 to 3, medium 4 to 6, heavy 8 to 10 px (leg 2's own halving of action values); trauma decay 1.0 to 1.5/s, 0.15 per light hit (truncated GitHub path) | "trauma-squared" only | Heuristic. DISAGREE on decay (4.0 vs 1.0 to 1.5 per second). |
| Anticipation | 0.3 to 0.6 s (18 to 36 frames) | 6 to 12 frames heavy, none on light (raduacg) | "6-12 frames heavy" | Heuristic. DISAGREE, roughly 3x. |
| Flash cap | 3 per second (WCAG summary by Stark) | 3 per second, 25% or 20% screen area (Game Accessibility Guidelines, Xbox XAG 118) | "3 flashes/second hard cap plus disable toggle" | AGREE. Primary guideline sources cited (not re-fetched here). |
| Shield impact buffer | NOT verified, "spike item, not adopted spec" (A4) | 6 to 8 slots; leg 2 flags "eight is enough" as a heuristic (Vav Labs tutorial). Sibling sources range 3 to 4 (GameDev SE), 16 (godotshaders), 24 with 6 on mobile (FORGE3D) | "6-8 slot multi-impact buffer" | Heuristic, single leg. Leg 1's "spike item" status is not carried. |
| Bloom threshold | above 1.0 (hobby project configs at 0.9 to 1.44 via DeepWiki auto-summaries) | about 1.0 to 1.2; Unity URP docs say "~1" in HDR (primary for Unity only) | "about 1.0-1.2" | AGREE. Partly primary (Unity docs), engine-dependent. |
| Emissive multipliers | none | accents 3 to 5x, cores above 10x (bitsoulhosting blog says 3 to 20x, URL truncated; the split is leg 2 inference) | "accents 3-5x and cores above 10x" | Heuristic, single leg. |
| Starting tonemapper | ACES Filmic (E3) | Neutral first; if ACES, rebalance (Unity docs, devlog) | "test item (Neutral vs AgX vs ACES)" | DISAGREE on the starting choice. AgX is not available in Babylon. |
| Fill and rim | rim "25-50% intensity in one guide" (no URL); fill about half of key or less (batch 5) | fill 25 to 40% of key, rim 50 to 80% of key (cc-blender-skill, path truncated; course PDF) | "25-40% cool fill plus Fresnel rim at 50-80% of key" | DISAGREE on rim (25-50 vs 50-80). Heuristic. |
| Screen coverage | none (overdraw first, no numbers) | hero at most 10%, common at most 2%, distant at most 0.5% (omer-metin "skills-for-antigravity" GitHub doc, path truncated, "not fully verified") | same | Single leg. The source is an AI-agent skill reference doc. Heuristic. |
| Torpedo telegraph | three-part spec (inference) | 800 ms ramp to white (Hades student thesis, 2D) | "about 800 ms" | Heuristic. |

The handoff calls batch 7 "reconciled, no substantive conflicts". On the numbers above it adopts leg 2's values each time and does not mention leg 1's differing values. Its batch disclaimer ("all batch 7 numbers are starting heuristics") is accurate.

### Batch 8: asset packs and templates
| Topic | Leg 1 | Leg 2 | Status |
|---|---|---|---|
| Kit-first, CC0-only in the public repo, no fleet pack | Yes | Yes | AGREE. |
| Quaternius licence | CC0 (C1, C4; Cinevva and Klyo aggregators, WEAK) | Pass 1 said CC0; Pass 3 corrected it to QAL v1.0, unsafe for a public repo | Correction VERIFIED with nuance (section 4c). The leg 1 file is not annotated. |
| Babylon ORM slot | Forum hypothesis: roughness to microSurfaceTexture, metal to metallicTexture, AO to ambientTexture; "verify first" | "Babylon.js PBRMaterial exposes ormTexture" | Leg 2 WRONG. OBSERVED: no ormTexture property in @babylonjs/core 8.20.0 or 9.32.0. The game already uses metallicTexture plus channel flags at ships3d.js:67 (section 5). |
| KHR_materials_variants | n/a | ADOPT for damage toggles; "keep both engines open" | Babylon loader supports it; Godot importer does not (section 4e). |
| Draw calls at 20 ships | Material count drives draw calls | Draw calls are not the bottleneck; texture memory and material count are | Compatible. |
| Trim sheets | One master plus per-faction variants | 2 to 4 sheet set | Compatible. |

## 3. Handoff summary fidelity

1. **1942 correction (batch 4): PARTLY MISREPRESENTS.** OBSERVED: leg 1 item 7 cites the 1942 historical carrier doctrine (substack) and says it is "historical doctrine, not game design ... used ... as a framing source" (wings_tactics_batch4:118). DeepSeek item 6 checked "1942 (video game)" on Wikipedia and found no stance system (batch4_wings_deepseek:17). The handoff's stated reason, "no documented switchable stance found", is about the arcade game, not the source leg 1 cited. Neither file says that World of Warships patrol fighters are the "better precedent"; that comparison is the chair's. Leg 1's file still presents the doctrine as the "Screen doctrine statement" with no annotation. INFERRED: the DeepSeek brief may have named "1942-style intercept bands"; I could not determine this, because the briefs are not in the repo.
2. **"Project is Godot-based" (batch 2 leg 2): substance faithful, attribution wrong.** OBSERVED: the correction appears as "CHAIR CORRECTION" at D6 (line 173), D7 (line 178) and bottom line 6 (line 200), inserted into a file whose filing note says "wording is otherwise verbatim". The handoff says "DeepSeek leg 2 CORRECTS its own framing". DeepSeek returned SKIP on the Godot ground; Rey corrected it.
3. **BG3 "autonomous playthrough" claim: correctly quarantined.** OBSERVED: engine_comparison_2026_10_24.md:97 lists it as "UNVERIFIED secondary-summary claims, explicitly NOT used as evidence", "relevant only as autonomous playtesting potential, and only if verified" (39 hours, $712 in tokens). subreddit_mining_batch2:104 says "still quarantined". It does not appear in any DeepSeek file or in the handoff.
4. **Godot 6-week claim: the qualifications are NOT in any research file.** OBSERVED: the username "Delicious-Shower8401", "second-hand", "unnamed project", "no fixed scope", "part 1" and "skeptical" appear only in OPUS_HANDOFF.md:111 (grep across contrib/). Leg 1 batches 1 and 2 quarantine the claim pending a read. DeepSeek batch 1 (lines 117-119) presents BuzzRadr's version, "a solo developer with no prior coding or gamedev background created a playable game in six weeks", as an OBSERVED community report, with no annotation. That contradicts the handoff's own description. The handoff's qualifications come from a "live thread read delivered in chat" that is not filed in the repo. UNCHECKABLE (section 4i).
5. **Quaternius correction (batch 8): correct on substance; recorded only in the handoff and the DeepSeek file.** OBSERVED: asset_packs_batch8 lines 109 and 124-127 still say Quaternius is CC0, with no correction note. Nuance missing from both files and the handoff: older Quaternius listings still say CC0 (section 4c).

Other places where the handoff misstates its source:
- Batch 6, "the exact dropped-maps mechanism (... two separate textures get silently dropped ...)": WRONG for the current Blender exporter (section 4b). The Zenodo audit's dropped maps happened in a Unity import path (batch 2 leg 2, C9), not in a Blender export.
- Batch 5 and batch 7 tonemapper test items include AgX, which Babylon does not offer (section 4g).
- Batch 2, "Cascadeur not found this round": leg 2 found it.
- Batch 1: "Electron ... 120 to 160 MB runtime per OS" is a build-machine download in the source. The handoff notes the garbled DeepSeek Bevy URL (safe.search.brave.com "best games to win real money") but not leg 1's garbled `112.cachefly.net/bevyengine/bevy_editor_prototypes/...` URL, which backs the "editor prototypes archived" claim.
- Batch 6, "official Blender Lab MCP server" as a standardization candidate: the official page requires Blender 5.1 or newer. The project pins Blender 4.5.14 (CLAUDE.md:3).
- Batch 8, KHR_materials_variants together with "keep both open": Godot's importer does not support variants.

## 4. Web spot-checks against primary sources

| # | Claim | Result | Primary source used |
|---|---|---|---|
| a | Godot 4 Compatibility lacks SDFGI and SSR; Forward+ has both | **VERIFIED.** The renderers table marks SDFGI and Screen-Space Reflections "Not supported" for Compatibility and Mobile, "Supported" for Forward+, in both the 4.4 and master branches. Extra: Compatibility shadows use "a multi-pass approach and less accurate blending", with no PCSS for directional lights and no contact shadows (supports "weak shadows"). | raw.githubusercontent.com/godotengine/godot-docs/4.4/tutorials/rendering/renderers.rst and .../master/... (the source of docs.godotengine.org/en/4.4/tutorials/rendering/renderers.html, which was blocked or truncated for my tools) |
| b1 | glTF metallicRoughnessTexture: roughness in G, metalness in B | **VERIFIED.** Spec: "Its green channel contains roughness values and its blue channel contains metalness values ... The red and alpha channels are ignored." | raw.githubusercontent.com/KhronosGroup/glTF/main/specification/2.0/Specification.adoc (line 2638) |
| b2 | Blender glTF exporter never exports bump maps | **VERIFIED (in effect).** The exporter doc lists only a tangent-space Normal Map node as the normal input. The exporter source (glTF-Blender-IO main v5.4.7 and the blender-v4.5-release branch) has zero Bump-node handling. | github.com/KhronosGroup/glTF-Blender-IO docs/blender_docs/scene_gltf2.rst; addons/io_scene_gltf2 source |
| b3 | (handoff and leg 2) Separate metal and roughness textures are silently dropped | **WRONG for current exporters.** The doc says the add-on "may attempt to adapt the image to the correct form during exporting". image.py maps Metallic to channel B and Roughness to channel G and composes them into one image. Only one texture is kept, with a UI warning, when "Keep Original" is on (default False). Checked on the 4.5 branch, which matches the project's Blender 4.5.14. | glTF-Blender-IO blender-v4.5-release addons/.../exp/material/image.py; __init__.py export_keep_originals |
| c | Quaternius licence: CC0 or QAL v1.0? | **VERIFIED: QAL v1.0 for current downloads.** quaternius.com/license.html reads "Quaternius Asset License (QAL) v1.0, Last updated: 8/28/2026": commercial use, no credit, and "You just can't resell or redistribute the assets themselves as assets". Section 7 says the licence version in effect when you obtained the assets governs. CAVEAT: quaternius.itch.io/lowpoly-spaceships still says "CC0 License", the Godot asset library lists "Quaternius Ultimate Spaceships Pack" as CC0, and a 7-year-old Quaternius itch.io post says "the license is CC0". Copies obtained earlier under CC0 may differ; not settled. The quaternius.com homepage was blocked. | https://quaternius.com/license.html ; https://quaternius.itch.io/lowpoly-spaceships ; https://godotengine.org/asset-library/asset/edit/7189 ; https://itch.io/post/660289 |
| d | Babylon TAARenderingPipeline is separate from DefaultRenderingPipeline | **VERIFIED.** In @babylonjs/core 8.20.0 typings, `class TAARenderingPipeline extends PostProcessRenderPipeline`. DefaultRenderingPipeline toggles are sharpen, bloom, depth of field, FXAA, image processing, glow layer, chromatic aberration and grain; there is no TAA. The game creates TAA separately (scene3d.js:105). | npm @babylonjs/core@8.20.0 (the version loaded at voidsworn-3d.html:309) |
| e | KHR_materials_variants: Babylon loader? Godot importer? | **Babylon: VERIFIED supported** (@babylonjs/loaders 8.20.0 has glTF/2.0/Extensions/KHR_materials_variants with SelectVariant, GetAvailableVariants and Reset). **Godot: NOT supported.** godotengine/godot master (commit c8256a8, 2026-10-23) modules/gltf names no KHR_materials_variants; its supported list is animation_pointer, lights_punctual, materials_emissive_strength, materials_pbrSpecularGlossiness, materials_unlit, node_visibility and texture_transform, plus texture extensions. | npm @babylonjs/loaders@8.20.0; github.com/godotengine/godot modules/gltf (sparse clone) |
| f | Godot MultiMesh needs one identical mesh for all instances | **VERIFIED.** MultiMesh has a single `mesh` member ("Mesh resource to be instanced"); per-instance variation is transform, color and custom data only; instances are "spatially indexed as one"; blend shapes are ignored. | raw.githubusercontent.com/godotengine/godot/master/doc/classes/MultiMesh.xml |
| g | Babylon 8.x tone mapping: AgX? Khronos PBR Neutral? ACES? | **ACES: yes. Khronos PBR Neutral: yes. AgX: NO.** ImageProcessingConfiguration has TONEMAPPING_STANDARD=0, TONEMAPPING_ACES=1 and TONEMAPPING_KHR_PBR_NEUTRAL=2. The list is the same in 8.20.0, 8.56.2 (the last 8.x) and 9.32.0. DeepSeek batch 5 finding 18 ("ACES/AgX") is WRONG for Babylon. Godot 4.4 does have TONE_MAPPER_AGX. | npm @babylonjs/core 8.20.0, 8.56.2, 9.32.0; godot 4.4-stable doc/classes/Environment.xml |
| h | Official Blender Lab MCP server released around April 2026 | **EXISTS (VERIFIED).** The official page, authored by the Blender Foundation, calls it "A lightweight MCP ... server for Blender", ships add-on v1.0.3, requires Blender 5.1 or newer, links to projects.blender.org/lab/blender_mcp, and warns that it "will execute LLM generated code ... without any guards". The April 2026 date is secondary only: StraySpark says v1.0.0 on 27 April 2026, and Digital Production (30 April 2026) says "available now for Blender 5.1". The "26 tools" and "behind Anthropic's connector" claims come only from StraySpark, which sells a competing server. projects.blender.org was blocked. | https://www.blender.org/lab/mcp-server/ (primary); strayspark.studio and digitalproduction.com (secondary) |
| i | Reddit post, r/ClaudeAI, u/Delicious-Shower8401, Oct 23, 2026 | **UNCHECKABLE.** The reddit.com URL (1xdhkzb) was blocked ("permission request not answered"), the BuzzRadr summary was blocked, and search did not surface the post or the username. | n/a |

Extra spot-checks made along the way:
- DeepSeek batch 2 B3, decals not in Compatibility: VERIFIED for released docs. Master now differs (section 2).
- DeepSeek batch 8 "PBRMaterial.ormTexture": WRONG (no such property in 8.20.0 or 9.32.0).
- DeepSeek batch 1 "1,500 draw calls" in Babylon docs: NOT FOUND in optimize_your_scene.md.
- gameshipper's 120 to 160 MB Electron figure: present, but as a build-time download.

## 5. Contradictions between the research and the game's current code

**Torpedo handling (the requested check).** OBSERVED: the code does neither of the two models the research describes. A torpedo resolves inside one activation. Hit or miss is rolled at launch, a short travelling visual plays, and damage is applied when the visual lands.
- battle.js:571: the weapon is marked fired and its cooldown set at launch.
- battle.js:589: every shot's hit or miss is rolled before any animation (`shots.push(rnd()*100<hc)`).
- battle.js:593: `await animWeapon(u,w,t,shots)`. wfx3d.js:392 sends torpedoes to `torpRun`. wfx3d.js:365-380 flies each torpedo for 0.55 to 1.15 s depending on faction (`TF.dur`) and awaits all arrivals (line 380). The point-defence tracers during flight (`pdFire`, wfx3d.js:376) are cosmetic only.
- battle.js:595: if the battle stalls during the animation, the shot is abandoned and the gun is refunded.
- battle.js:597-604: damage is applied via `applyHit` only after the animation returns. battle.js:619 handles the kill.
- Torpedo data (data.js:8, 15, 20) has range 5 to 6, cooldown 2 and `evMult:2`. battle.js:462 doubles target evasion against torpedoes, a static stand-in for dodgeability.
- There is no in-flight torpedo state across turns: no projectile list in battle.js, and fx3d.js:284 `updateProjectiles(dt){}` is an empty stub.

Implication (INFERRED): this is not strictly the "damage at fire time" model DeepSeek rejects (batch5_deepseek:198-199), because damage lands with the visual. But the outcome is fixed at launch and the target cannot react, which is exactly DeepSeek's concern. Adopting the batch 5 and batch 7 recommendation (multi-turn flight, predicted intercept, impact-time resolution, telegraph during the player's turn) is a rules change that would add a new projectile state to battle.js, not a presentation tweak.

Other divergences between the research and the code (OBSERVED in code):
- **Babylon ORM wiring already exists.** ships3d.js:65-67 builds a PBRMaterial with `metallicTexture=maps.orm`, `useRoughnessFromMetallicTextureGreen`, `useMetallnessFromMetallicTextureBlue` and `useAmbientOcclusionFromMetallicTextureRed`. Batch 8 leg 1 B2's forum hypothesis (roughness to microSurfaceTexture) and leg 2's "ormTexture" both contradict this working code.
- **Bloom threshold.** scene3d.js:27 sets `bloomThreshold=.5` (weight .55, kernel 72, scale .5), and a GlowLayer runs as well (scene3d.js:24). Batch 7 both legs recommend about 1.0 to 1.2.
- **Tonemapper.** The game uses ACES (scene3d.js:29) plus a ColorCurves teal and warm grade. Leg 2 recommends Neutral first; AgX is not available in Babylon.
- **Light rig.** Sun 3.2, fill 0.6 (assigned to `G.rim`) and hemi 0.1 (scene3d.js:21-23). The fill is about 19% of the key, below the batch 7 proposal of 25 to 40%. There is no Fresnel rim in the hull material path I checked. Batch 5 leg 1 says the game has a "two-light rig"; there are three lights plus a GlowLayer.
- **Asset pipeline.** Hulls are a custom JSON plus WebP format fetched from hulls/ and hulls_hi/ (ships3d.js:800-801; 36 .json and 72 .webp in hulls/). No Babylon glTF loader is bundled (0 matches for loaders in voidsworn-3d.html, build.py and head.html). The KHR_materials_variants and "GLB as the source" proposals assume a runtime path the game does not have.
- **Blender version.** The official Blender Lab MCP needs Blender 5.1 or newer; CLAUDE.md:3 pins blender-4.5.14.
- **Delta-v offsets.** Batch 5 leg 1 item 2 says "Voidsworn already has delta-v offsets from a reference plane". I found that only as a proposal in contrib/muse/reviews/space_3d.md:26; grep found no band or delta-v mechanic in battle.js, ships3d.js, main3d.js or scene3d.js. INFERRED: the claim is a proposal, not code. The grep was limited.
- Consistent with code: soft crits (battle.js:554-564), shield regen (battle.js:365), the motion rule (motionHit battle.js:458, applied at 469), separate TAA (scene3d.js:105).

## 6. Weak-source inventory

Method: the URLs in each file were extracted and classified by domain pattern (scripts in the scratchpad's scripts/ folder). Categories are mutually exclusive in this order: garbled, truncated, forum/Reddit/mirror, fan or auto-generated wiki, store listing, marketing/vendor/aggregator blog. "Root-only" counts URLs with no path, which point to no specific page (this column overlaps the others). "No-URL" counts source statements that give no link. The counts come from regex and are approximate; the per-URL list is in the appendix.

| File | Unique cites | Forum/Reddit | Fan/auto wiki | Store listing | Mktg/vendor/aggregator | Root-only URL | Truncated/garbled | No-URL source lines |
|---|---|---|---|---|---|---|---|---|
| B1 leg 1 | 55 | 13 | 1 | 0 | 10 | 0 | 1 garbled (112.cachefly.net) | 0 (Reddit leads explicitly unread) |
| B1 leg 2 | 35 | 5 | 1 | 3 | 13 | 18 | 1 garbled (safe.search.brave.com) | 29 "cursor N, lines" pointers instead of page anchors |
| B2 leg 1 | 29 | 10 (3 vibingtalk/resetera mirrors, 3 reddit sub/thread links unread) | 0 | 6 (itch devlogs, aggregator) | 1 | 0 | 0 | 2 (sprite-sheet thread, fishing post) |
| B2 leg 2 | 39 | 0 | 0 | 3 | 8 | 1 | 0 (1 non-canonical zh-cn .rst) | 0 |
| B3 leg 1 | 21 | 3 | 3 | 0 | 8 | 0 | 0 | 0 (Menace via GameFAQs mirror) |
| B3 leg 2 | 52 | 10 | 18 | 1 (App Store) | 0 | 1 | 3 mid-slug cuts (vice, RPS, gamedeveloper) | 0 |
| B4 leg 1 | 21 | 7 | 5 | 1 (Scribd manual) | 0 | 0 | 0 | 0 |
| B4 leg 2 | 31 | 5 | 6 | 2 | 0 | 5 | 0 (1 generic forum index URL) | 2 (generic Starsector forum, generic GameFAQs) |
| B5 leg 1 | 30 | 7 | 3 | 0 | 7 | 1 | 0 | 0 |
| B5 leg 2 | 125 | 39 (1 libreddit mirror) | 7 | 6 | 8 | 21 | 3 "..." cuts, 1 mid-slug, 1 garbled EBSCO library proxy | 1 ("no single URL", finding b20) |
| B6 leg 1 | 43 | 3 | 3 | 1 | 17 | 0 | 0 | 0 |
| B6 leg 2 | 35 | 4 (incl. X article, LinkedIn post) | 0 | 4 | 3 | 0 | 0 | 0 |
| B7 leg 1 | 19 | 3 | 7 (6 DeepWiki auto-summaries, Halopedia) | 0 | 1 | 1 (reebo.com) | 0 | 10 "full URL not returned" |
| B7 leg 2 | 107 (1 http, 106 bare domain or path) | 19 | 7 | 4 | 17 | 21 | about 12 flagged truncated paths | 24 truncation or "not fully verified" flags |
| B8 leg 1 | 0 URLs | n/a | n/a | n/a | n/a | n/a | n/a | 52 Source lines, all no-URL (48 tagged WEAK, 6 STRONG) |
| B8 leg 2 | 0 URLs | n/a | n/a | n/a | n/a | n/a | n/a | All sources named without links, including the Quaternius correction |

Key points: batch 8 has no checkable URL in either leg, including every price, count and licence claim. Batch 7 leg 2's numeric starting values rest mostly on truncated GitHub paths of AI-agent skill documents. DeepSeek batch 1 uses 18 root-only URLs plus "cursor" pointers for claims it labels OBSERVED.

## 7. Not checked
- Vendor prices, pack counts and licence terms in batch 8 (Synty, Grey Fleet, MSGDI, ArtStation tiers, Fab, CGTrader, Tripo, Meshy, Hunyuan, Rodin, Luma).
- Zero-K veterancy fact (the Steam news page did not render).
- Starsector, WoWs, BattleTech and XCOM numbers against game files.
- WCAG and Xbox XAG flash thresholds (cited by both legs; not re-fetched).
- The godotshaders noise-mask shader parameters and multi-impact shader slot counts.
- The Blender Lab MCP v1.0.0 release date and tool count from the primary repo (projects.blender.org blocked).
- The 6-week Reddit post (blocked).
- Whether older Quaternius CC0 copies remain CC0.
- Godot "one material per surface" in MultiMesh (only the single-mesh rule was checked).
- Babylon draw-call figures on any Babylon doc page other than optimize_your_scene.md.
- Leg 1 batch 5 Deadlock and Star Citizen claims.
- Whether the DeepSeek briefs named "1942-style intercept bands".
- Rey's hidden screening files and chair reconciliations (not in the repo).

## Appendix: per-URL weak-pattern list (regex classification)

#### asset_packs_batch8_2026_10_24.md (2 unique cites, 2 weak-pattern)
- root-only(no specific page): `3DTextures.me`
- store/listing: `itch.io`

#### effects_batch7_2026_10_24.md (19 unique cites, 13 weak-pattern)
- forum: `https://forums.tomshardware.com/threads/smoke-and-explosion-fps-spikes-do-they-cause-the-gpu-or-cpu.712248/`
- forum: `https://steamcommunity.com/app/544610/discussions/0/4700161192395595557/?l=italian`
- forum: `https://www.hard-light.net/forums/index.php?PHPSESSID=iqitstbqbpjbbunrvakpajhp9v&topic=23754.0`
- marketing/vendor-or-aggregator blog: `https://generalistprogrammer.com/tutorials/game-particle-effects-complete-vfx-programming-guide-2025`
- root-only(no specific page): `https://www.reebo.com/`
- truncated: `https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-`
- wiki/secondary-wiki: `https://deepwiki.com/amrayach/house-of-letters/4.4-post-processing-effects`
- wiki/secondary-wiki: `https://deepwiki.com/calaveiraUwU/Slotmachine/4.1-post-processing-effects`
- wiki/secondary-wiki: `https://deepwiki.com/deepnight/gamefeel/4.3-visual-effects-system-(fx`
- wiki/secondary-wiki: `https://deepwiki.com/gtibo/VFX-sketchbook-Godot-4.x/5.1-gpu-particle-systems`
- wiki/secondary-wiki: `https://deepwiki.com/noire-dev/opensandbox-SDK/6.4-visual-effects-and-marks`
- wiki/secondary-wiki: `https://deepwiki.com/yangrc1234/AtmosphereScatter/8.1-post-processing-setup`
- wiki/secondary-wiki: `https://www.halopedia.org/index.php?title=Energy_projector&diff=cur&oldid=904529`

#### engine_comparison_2026_10_24.md (55 unique cites, 25 weak-pattern)
- forum: `https://forum.babylonjs.com/t/best-practices-for-optimizing-babylon-js-scenes-not-just-on-lower-end-devices/58688`
- forum: `https://forum.babylonjs.com/t/fresnel-effect-on-pbrmaterial-without-replacing-original-material/57682`
- forum: `https://forum.babylonjs.com/t/gpu-particle-system-start-delay-if-active-particles-is-full/60561`
- forum: `https://forum.babylonjs.com/t/how-to-optimize-a-scene-with-10k-mesh-instances/8634`
- forum: `https://forum.babylonjs.com/t/mesh-with-thin-instance-slower-than-with-full-vertices/46756`
- forum: `https://forum.babylonjs.com/t/mission-to-improve-render-performance/13881`
- forum: `https://forum.babylonjs.com/t/optimising-a-scene-with-a-lot-of-mesh/55018`
- forum: `https://forum.babylonjs.com/t/pbr-fresnel-effect/22800`
- forum: `https://forum.babylonjs.com/t/performance-implications-after-disable-instances/50253`
- forum: `https://news.ycombinator.com/item?id=26137496`
- forum: `https://vibingtalk.com/index.php?threads/how-are-people-making-genuinely-good-looking-games-with-claude-opus-5-5.1611563/`
- forum: `https://www.reddit.com/r/ClaudeCode/comments/1x5uzqx/how_are_people_making_genuinely_goodlooking_games/`
- forum: `reddit.com`
- garbled: `https://112.cachefly.net/bevyengine/bevy_editor_prototypes/discussions/1`
- marketing/vendor-or-aggregator blog: `https://generalistprogrammer.com/comparisons/unity-vs-godot`
- marketing/vendor-or-aggregator blog: `https://indietooling.com/posts/bevy-0-20-stride-4-4`
- marketing/vendor-or-aggregator blog: `https://indietooling.com/posts/fyrox-vs-bevy-rust-engines`
- marketing/vendor-or-aggregator blog: `https://rustify.rs/articles/rust-for-game-development-bevy-2026`
- marketing/vendor-or-aggregator blog: `https://tech-insider.org/best-game-engines-for-indie-devs-2026/`
- marketing/vendor-or-aggregator blog: `https://www.geeky-gadgets.com/building-games-with-claude-ai/`
- marketing/vendor-or-aggregator blog: `https://www.neural4d.com/how-tos/how-to-use-ai-3d-models-in-godot`
- marketing/vendor-or-aggregator blog: `https://www.open-source-tools.com/godot-engine`
- marketing/vendor-or-aggregator blog: `https://www.strayspark.studio/blog/gdscript-vs-csharp-godot-2026-choosing-scripting-language`
- marketing/vendor-or-aggregator blog: `https://ziva.sh/blogs/gdscript-vs-csharp`
- wiki/secondary-wiki: `https://deepwiki.com/dgmurphy/mortarcommand/7-rendering-and-visuals`

#### nemesis_events_batch3_2026_10_24.md (21 unique cites, 14 weak-pattern)
- forum: `https://forums.larian.com/ubbthreads.php?ubb=showflat&Number=849537&page=all`
- forum: `https://steamcommunity.com/app/212680/discussions/0/611696927924171813/`
- forum: `reddit.com`
- marketing/vendor-or-aggregator blog: `gamedesign.gg`
- marketing/vendor-or-aggregator blog: `https://gamedesign.gg/articles/roguelike-and-roguelite-design/`
- marketing/vendor-or-aggregator blog: `https://gamerblurb.com/articles/slay-the-spire-2-crystal-sphere-event-guide`
- marketing/vendor-or-aggregator blog: `https://gamerblurb.com/articles/slay-the-spire-2-tablet-of-truth-event-guide-best-choice`
- marketing/vendor-or-aggregator blog: `https://storyroll.app/blog/how-to-run-a-space-opera-campaign`
- marketing/vendor-or-aggregator blog: `https://techsive.com/when-games-are-too-bloated-shadow-of-war-case/`
- marketing/vendor-or-aggregator blog: `https://www.gaminginstincts.com/middle-earth-shadow-mordor-whos-nemesis/`
- marketing/vendor-or-aggregator blog: `https://www.geekextreme.com/game-mechanics-reddit-debates/`
- wiki/secondary-wiki: `https://ftl.fandom.com/wiki/Augmentations`
- wiki/secondary-wiki: `https://ftl.fandom.com/wiki/Meta:Event_Conventions`
- wiki/secondary-wiki: `https://xcom.fandom.com/wiki/The_Chosen`

#### opus_blender_batch6_2026_10_24.md (43 unique cites, 24 weak-pattern)
- forum: `https://community.openai.com/t/feature-request-enforce-persistent-brand-rules-across-image-generation-assets-qa-and-delivery/1389735`
- forum: `https://vibingtalk.com/index.php?threads%2Fblender-mcp-is-impressive-but-not-that-useable-yet.1564293%2F`
- forum: `https://vibingtalk.com/index.php?threads/does-delegating-save-claude-quota-i-measured-6-setups-on-28-real-tasks-haiku-alone-passed-every-check-for-93-`
- marketing/vendor-or-aggregator blog: `https://devguide.dev/blog/running-claude-code-in-batches-for-automated-workflows`
- marketing/vendor-or-aggregator blog: `https://help.meshy.ai/en/articles/16231707-how-to-create-3d-animation-with-auto-rigging`
- marketing/vendor-or-aggregator blog: `https://morphic.com/ai-glossary/skeletal-animation`
- marketing/vendor-or-aggregator blog: `https://stack-archive.com/blog/meshy-edit-local-ai-3d-model-edits-slicer-2026/`
- marketing/vendor-or-aggregator blog: `https://terminalskills.io/skills/blender-render-automation`
- marketing/vendor-or-aggregator blog: `https://vagon.io/blog/how-to-use-blender-mcp-with-anthropic-claude-ai`
- marketing/vendor-or-aggregator blog: `https://www.fabbaloo.com/news/mits-instructmesh-repairs-ai-generated-3d-models-before-printing`
- marketing/vendor-or-aggregator blog: `https://www.kitstarter.dev/blog/claude-code-prompt-is-too-long`
- marketing/vendor-or-aggregator blog: `https://www.meshy.ai/tutorials/character-auto-rigging-workflow`
- marketing/vendor-or-aggregator blog: `https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026`
- marketing/vendor-or-aggregator blog: `https://www.tripo3d.ai/blog/explore/ai-3d-model-generator-and-micro-detail-versus-macro-form`
- marketing/vendor-or-aggregator blog: `https://www.tripo3d.ai/blog/explore/ai-3d-model-generator-for-character-prototyping-only`
- marketing/vendor-or-aggregator blog: `https://www.tripo3d.ai/blog/explore/ai-3d-model-generator-retargeting-rigs-to-humanoid-standards`
- marketing/vendor-or-aggregator blog: `https://www.tripo3d.ai/blog/explore/ai-3d-model-generator-translating-prompts-without-style-loss`
- marketing/vendor-or-aggregator blog: `https://www.tripo3d.ai/blog/explore/character-creation-3d-2025`
- marketing/vendor-or-aggregator blog: `https://www.tripo3d.ai/blog/explore/how-to-export-ai-models-from-blender-without-breaking-textures`
- marketing/vendor-or-aggregator blog: `https://www.tripo3d.ai/blog/explore/how-to-generate-characters-with-ai-and-keep-proportions`
- store/listing: `https://skillsllm.com/skill/blender-skills`
- wiki/secondary-wiki: `https://deepwiki.com/immersive-web/webxr-input-profiles/7.1-gltf-model-specifications`
- wiki/secondary-wiki: `https://deepwiki.com/rishigundakaram/cadquery-mcp-server/4.2-png-rendering-with-blender`
- wiki/secondary-wiki: `https://wiki.playgwo.com/en/guide/models.html`

#### physics_graphics_motion_batch5_2026_10_24.md (30 unique cites, 17 weak-pattern)
- forum: `http://forums.atomictorch.com/index.php?PHPSESSID=1qktaihevduum5a6s2ga2t6i96&topic=137.0`
- forum: `http://theminiaturespage.com/boards/msg.mv?id=201632`
- forum: `https://forum.babylonjs.com/t/best-practices-for-optimizing-babylon-js-scenes-not-just-on-lower-end-devices/58688`
- forum: `https://polycount.com/discussion/135152/pbr-beat-up-metal`
- forum: `https://steamcommunity.com/app/1575940/discussions/1/578298707369444055`
- forum: `https://tildes.net/~games/192w/i_desperately_want_to_enjoy_turn_based_games_but_can_never_get_into_them_what_can_i_do_to_change`
- forum: `reddit.com`
- marketing/vendor-or-aggregator blog: `https://pinpdf.com/6-techniques-that-define-high-quality-3d-hard-surface-modeli-f2975e3f1330bc88350abde1946ea372.html`
- marketing/vendor-or-aggregator blog: `https://web.phenixxgaming.com/2020/03/11/how-not-to-make-a-turn-based-tactics-game/`
- marketing/vendor-or-aggregator blog: `https://wolfsgamingblog.com/2017/09/05/battlestar-galactica-deadlock-review-time-to-frack-some-toasters/`
- marketing/vendor-or-aggregator blog: `https://www.gameskinny.com/?p=191263`
- marketing/vendor-or-aggregator blog: `https://www.manuelsanchezdev.com/blog/game-feel-principles-animated-godot`
- marketing/vendor-or-aggregator blog: `https://www.playtex.ai/downloads/the-game-developers-pbr-texture-handbook.pdf`
- marketing/vendor-or-aggregator blog: `https://www.slashskill.com/game-feel-and-juice-the-complete-guide-to-making-your-game-satisfying/`
- wiki/secondary-wiki: `http://wiki.eveuniversity.org/index.php?title=Missile_mechanics&diff=216833&oldid=85232`
- wiki/secondary-wiki: `https://starcitizen.tools/Comm-Link:The_New_Damage_System`
- wiki/secondary-wiki: `https://tvtropes.org/pmwiki/pmwiki.php/scrappymechanic/turnbasedstrategy`

#### subreddit_mining_batch2_2026_10_24.md (29 unique cites, 18 weak-pattern)
- forum: `https://users.rust-lang.org/t/is-there-a-standard-recommended-ide-for-rust/137499/14`
- forum: `https://vibingtalk.com/index.php?threads/how-are-you-guys-making-actually-good-3d-games-with-claude-mine-look-like-shit.616472/`
- forum: `https://vibingtalk.com/index.php?threads/i-built-a-3d-roguelite-with-claude-blender-and-godot-heres-how-i-actually-used-ai.1886835/`
- forum: `https://www.reddit.com/r/ClaudeAI/comments/1xdhkzb/no_coding_or_gamedev_background_6_weeks_with_opus/`
- forum: `https://www.reddit.com/r/ClaudeGameDev/`
- forum: `https://www.reddit.com/r/aigamedev/`
- forum: `https://www.resetera.com/threads/durante-thoughts-on-ai-in-game-development-from-the-trenches-reddit.1668020/`
- forum: `reddit.com`
- forum: `reddit.com/r/ClaudeGameDev`
- forum: `vibingtalk.com`
- marketing/vendor-or-aggregator blog: `https://thehype.news/claude-opus-5-5-3d-game/`
- root-only(no specific page): `godotshaders.com`
- store/listing: `https://agentica.itch.io/stylo-godot/devlog/1722466/stylo-godot-012-is-out-six-stylized-shaders-for-godot-4`
- store/listing: `https://bllackcat1.itch.io/scifi-combat-fx-godot/devlog/1718670/adding-a-shield-hit-a-hit-flash-and-a-shockwave-to-a-godot-4-enemy-in-about-five-minut`
- store/listing: `https://dadddydarko.itch.io/brightdeck-vfx-pixel-shaders-godot/devlog/1722605/brightdeck-vfx-is-out-pixel-art-shaders-for-godot-4`
- store/listing: `https://reeboolabs.itch.io/godot-character-shaders`
- store/listing: `https://theresanaiforthat.com/company/donchitos/repository/Claude-Code-Game-Studios/`
- store/listing: `itch.io`

#### wings_tactics_batch4_2026_10_24.md (21 unique cites, 13 weak-pattern)
- forum: `https://forums.sinsofasolarempire.com/304193/page/2/`
- forum: `https://gamefaqs.gamespot.com/boards/643003-fire-emblem-awakening/66875829`
- forum: `https://steamcommunity.com/app/334920/discussions/0/1696045708661224875/?l=dutch`
- forum: `https://steamcommunity.com/app/552990/discussions/0/3082124889517666593/`
- forum: `https://steamcommunity.com/app/573100/discussions/0/1796278072845347795/?l=hungarian`
- forum: `https://www.resetera.com/threads/exemplary-ui-design-in-games-warning-gifs.4080/`
- forum: `reddit.com`
- store/listing: `https://www.scribd.com/doc/97870330/Homeworld-Manual-PC`
- wiki/secondary-wiki: `https://battletech.fandom.com/wiki/Skills`
- wiki/secondary-wiki: `https://en.namu.wiki/w/Battlefleet%20Gothic:%20Armada`
- wiki/secondary-wiki: `https://noobsincombat.fandom.com/wiki/Features`
- wiki/secondary-wiki: `https://starsector.fandom.com/wiki/Fighter`
- wiki/secondary-wiki: `https://stellaris.fandom.com/wiki/Space_warfare`

#### batch2_workflows_deepseek_2026_10_24.md (39 unique cites, 13 weak-pattern)
- marketing/vendor-or-aggregator blog: `G3D.AI`
- marketing/vendor-or-aggregator blog: `https://g3d.ai/research/consistent-ai-3d-asset-batches`
- marketing/vendor-or-aggregator blog: `https://podscan.fm/podcasts/claude-code-daily/episodes/claude-code-briefing-for-23-august-browser-game-production-loop-superpowers-skill-audit-subagen`
- marketing/vendor-or-aggregator blog: `https://wavespeed.ai/blog/3d-model-access/tripo-ai-review/`
- marketing/vendor-or-aggregator blog: `https://www.strayspark.studio/blog/generative-3d-tools-comparison-meshy-rodin-tripo-csm-2026`
- marketing/vendor-or-aggregator blog: `https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026`
- marketing/vendor-or-aggregator blog: `https://www.tripo3d.ai/blog/modular-3d-assets-for-games`
- marketing/vendor-or-aggregator blog: `https://www.wayline.io/blog/asset-packs-vs-kitbashing`
- root-only(no specific page): `https://cascadeur.com/`
- root-only(no specific page): `workflows.ru`
- store/listing: `https://godotengine.org/asset-library/asset/5264`
- store/listing: `https://godotengine.org/asset-library/asset/5335`
- store/listing: `https://godotengine.org/asset-library/asset/5434`

#### batch3_nemesis_deepseek_2026_10_24.md (52 unique cites, 30 weak-pattern)
- forum: `https://forums.elderscrollsonline.com/en/discussion/672843/event-fatigue`
- forum: `https://steamcommunity.com/app/1302830/discussions/0/3824156220925328474/`
- forum: `https://steamcommunity.com/app/212680/discussions/0/558749824086798445/`
- forum: `https://steamcommunity.com/app/212680/discussions/0/594031066432592842?l=english#1`
- forum: `https://steamcommunity.com/app/268500/discussions/0/598536819815131874/#1`
- forum: `https://steamcommunity.com/id/Robineus/recommended/593380/`
- forum: `https://www.kickstarter.com/projects/106952529/crying-suns/posts/2636004`
- forum: `https://www.subsetgames.com/forum/viewtopic.php?f=11&t=16537#1`
- forum: `https://www.subsetgames.com/forum/viewtopic.php?f=11&t=16907#1`
- forum: `https://www.subsetgames.com/forum/viewtopic.php?f=11&t=17113#1`
- root-only(no specific page): `Rutab.net`
- store/listing: `https://apps.apple.com/us/app/crying-suns/id1522331260`
- wiki/secondary-wiki: `Sarna.net`
- wiki/secondary-wiki: `https://battletech.fandom.com/wiki/Factions`
- wiki/secondary-wiki: `https://darkestdungeon.wiki.gg/wiki/Altar_of_Hope/The_Timeless_Wood?diff=prev&oldid=21372`
- wiki/secondary-wiki: `https://en.namu.wiki/w/%EC%8A%AC%EB%A0%88%EC%9D%B4%20%EB%8D%94%20%EC%8A%A4%ED%8C%8C%EC%9D%B4%EC%96%B4`
- wiki/secondary-wiki: `https://endless-space-2.fandom.com/wiki/Minor_Factions`
- wiki/secondary-wiki: `https://ftl.fandom.com/wiki/Blue_Options?curid=6058&oldid=73216`
- wiki/secondary-wiki: `https://monster-train.fandom.com/wiki/Pact_Shards?diff=9193&oldid=9191`
- wiki/secondary-wiki: `https://shadowofwar.fandom.com/wiki/Uruks?direction=prev&oldid=61257`
- wiki/secondary-wiki: `https://slay-the-spire.fandom.com/wiki/Donu_and_Deca`
- wiki/secondary-wiki: `https://slay-the-spire.fandom.com/wiki/Mind_Bloom`
- wiki/secondary-wiki: `https://slay-the-spire.fandom.com/wiki/Nemesis`
- wiki/secondary-wiki: `https://slaythespire.wiki.gg/wiki/Cursed_Tome?diff=prev&oldid=14356`
- wiki/secondary-wiki: `https://slaythespire.wiki.gg/wiki/Events?diff=prev&oldid=14356`
- wiki/secondary-wiki: `https://spire-archive.com/`
- wiki/secondary-wiki: `https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/Hades#4`
- wiki/secondary-wiki: `https://www.sarna.net/wiki/MechWarrior_5:_Mercenaries`
- wiki/secondary-wiki: `https://xcom.fandom.com/wiki/Resistance_Factions?veaction=edit&section=1`
- wiki/secondary-wiki: `https://xcom.fandom.com/wiki/The_Chosen?curid=14384&diff=59399&oldid=59398`

#### batch4_wings_deepseek_2026_10_24.md (31 unique cites, 16 weak-pattern)
- forum: `https://forums.sinsofasolarempire.com/`
- forum: `https://fractalsoftworks.com/forum/index.php`
- forum: `https://fractalsoftworks.com/forum/index.php?topic=17050.msg269174#msg269174`
- forum: `https://openxcom.org/forum/`
- forum: `https://steamcommunity.com/app/268500/discussions/`
- root-only(no specific page): `https://flogus.free.fr/`
- root-only(no specific page): `https://gamefaqs.gamespot.com/`
- root-only(no specific page): `https://www.naeu.playblackdesert.com/`
- store/listing: `https://mod.io/g/sins-of-a-solar-empire-ii/m/icon-clarity`
- store/listing: `mod.io`
- wiki/secondary-wiki: `https://battletech.fandom.com/wiki/Skills`
- wiki/secondary-wiki: `https://pillarsofeternity2.wiki.fextralife.com/Fighter+Stances`
- wiki/secondary-wiki: `https://starsector.wiki.gg/wiki/Fighter`
- wiki/secondary-wiki: `https://stellaris.paradoxwikis.com/Space_warfare`
- wiki/secondary-wiki: `https://www.bta3062.com/`
- wiki/secondary-wiki: `https://xcom.fandom.com/wiki/Training_Center`

#### batch5_physics_graphics_motion_deepseek_2026_10_24.md (125 unique cites, 79 weak-pattern)
- forum: `http://www1.matrixgames.com/forums/tm.asp?m=841795`
- forum: `https://bb.oolite.space/viewtopic.php?p=248835`
- forum: `https://blender.stackexchange.com/questions/258621/how-to-properly-panel-a-low-poly-space-ship`
- forum: `https://bugtracker.arcengames.com/view.php?id=28769&nbn=1#bugnotes`
- forum: `https://eve-search.com/thread/457138-1`
- forum: `https://forum.egosoft.com/`
- forum: `https://forums.em8er.com/threads/vfx-design-and-the-aesthetic-of-large-battles.2239/#post-67924`
- forum: `https://forums.frontier.co.uk/`
- forum: `https://forums.inovaestudios.com/t/i-novae-engine-screenshot-thread/582/632`
- forum: `https://forums.inovaestudios.com/t/weekly-update-98/6731/11`
- forum: `https://forums.sinsofasolarempire.com/`
- forum: `https://forums.snapshotgames.com/t/hey-how-do-i-skip-animations/10295/4#1`
- forum: `https://forums.snapshotgames.com/t/pp-now-finished-a-couple-of-times-some-feedback/10651/1`
- forum: `https://forums.snapshotgames.com/t/pp-now-finished-a-couple-of-times-some-feedback/10651/1#1`
- forum: `https://forums.snapshotgames.com/t/speed-skip-animations/711`
- forum: `https://forums.stardock.com/111904/timing-in-ship-battles/page/1#1004135`
- forum: `https://forums.sufficientvelocity.com/threads/thancs-a-newtonian-space-tbt.5954/`
- forum: `https://forums.warframe.com/`
- forum: `https://fractalsoftworks.com/forum/`
- forum: `https://freeorion.org/forum/viewtopic.php?t=1896&view=print`
- forum: `https://gamedev.stackexchange.com`
- forum: `https://gamedev.stackexchange.com/questions/213129/how-to-plan-the-animation-of-a-complex-combat-between-two-groups-of-units/213152`
- forum: `https://gamedev.stackexchange.com/questions/24113/separation-of-world-state-and-animation-in-a-turn-based-game/24118`
- forum: `https://gamedev.stackexchange.com/revisions/60c09b4c-b880-47b3-9849-68d4291d4a82/view-source`
- forum: `https://gaming.stackexchange.com/questions/255927/is-there-any-way-to-speed-up-actions-in-xcom-2/257687`
- forum: `https://interstellarspacegame.com/forums/index.php?threads/turn-based-tactical-combat.51/`
- forum: `https://libreddit.perennialte.ch/r/StrategyRpg/comments/w2cjqu/benefits_of_a_hex_based_grid_in_tactical_combat/igsgcyx/?context=3`
- forum: `https://polygone.gamedev.net/forums/topic/668841-tactical-rpg-tactics/5232392/`
- forum: `https://steamcommunity.com/app/2432860/discussions/0/598538723409372933`
- forum: `https://steamcommunity.com/app/839770/discussions/0/6407003171826231613`
- forum: `https://steamcommunity.com/app/887570/discussions/3/599659929547193446/`
- forum: `https://steamcommunity.com/id/_nul/recommended/1332760/?l=spanish#1`
- forum: `https://unreal2.epic-prod-us2.discourse.cloud/t/support-advanced-turn-based-tile-toolkit/21930/2380`
- forum: `https://warhammer-empire.com/theforum/index.php/topic`
- forum: `https://www.gamedev.net/forums/topic/54903-space-combat-no-more-turning-battles/?page=3`
- forum: `https://www.hard-light.net/forums/index.php?topic=74622.0`
- forum: `https://www.slitherine.com/forum/`
- forum: `https://www1.matrixgames.com/forums/`
- forum: `polygone.gamedev.net`
- garbled: `https://0web.b.ebscohost.com.library.scad.edu/search/X?Queuing+theory+--+Games.&SORT=D#1`
- marketing/vendor-or-aggregator blog: `http://njjxkj.cn/NewsDetail.aspx?ID=1988`
- marketing/vendor-or-aggregator blog: `https://craftpbr.com/blog/curvature-map-guide`
- marketing/vendor-or-aggregator blog: `https://www.gamespress.com/Bringing-Sci-Fi-to-Life-The-Real-Science-Behind-The-Expanse-Osiris-Reb`
- marketing/vendor-or-aggregator blog: `https://www.gamespress.com/ru/Starship-Strategy-RPG-Relic-Space-Out-Now-on-Steam-Early-Access`
- marketing/vendor-or-aggregator blog: `https://www.gamespress.com/zh-TW/Open-World-Space-Game-Relic-Space-Arriving-on-Steam-Early-Access-in-Q3`
- marketing/vendor-or-aggregator blog: `https://www.proceduralpixels.com/blog/texture-baking---trading-vram-for-gpu-performance`
- marketing/vendor-or-aggregator blog: `https://www.strayspark.studio/blog/add-believable-edge-wear-to-game-assets-in-blender`
- marketing/vendor-or-aggregator blog: `https://www.strayspark.studio/blog/godot-3d-optimization-guide`
- root-only(no specific page): `GameDev.net`
- root-only(no specific page): `archive.org`
- root-only(no specific page): `https://blog.csdn.net/`
- root-only(no specific page): `https://robertsspaceindustries.com`
- root-only(no specific page): `https://store.steampowered.com`
- root-only(no specific page): `https://support.keenswh.com`
- root-only(no specific page): `https://tesera.ru/`
- root-only(no specific page): `https://ufoai.org/`
- root-only(no specific page): `https://www.matrixgames.com/`
- root-only(no specific page): `https://www.rockpapershotgun.com/`
- root-only(no specific page): `https://www.sjgames.com/`
- root-only(no specific page): `https://www.slitherine.com/`
- root-only(no specific page): `https://www.specialist-arms.com/`
- root-only(no specific page): `https://www.starfleetgames.com/`
- root-only(no specific page): `https://www.syfy.com/`
- store/listing: `https://store.steampowered.com/app/1889990/Tactics_Adrift/`
- store/listing: `https://store.steampowered.com/app/476530/Children_of_a_Dead_Earth/`
- store/listing: `https://ultimategameassets.com`
- store/listing: `https://www.adastragames.com/attack-vector-tactical/`
- store/listing: `https://www.eprison.de/steamdb/app`
- store/listing: `https://www.nobleknight.com/P/2148353677/`
- truncated: `https://ffg-forum-archive.entropicdreams.com/topic/223153-damn-those-slow-torpedoes/page/1/#comment-`
- truncated: `https://raw.githubusercontent.com/gamedev-skills/awesome-gamedev-agent-skills/.../godot-3d-essentials/SKILL.md`
- truncated: `https://steamcommunity.com/app/.../discussions/0/`
- wiki/secondary-wiki: `https://encyclopedia.thefreedictionary.com/Impulse-based+turn+system`
- wiki/secondary-wiki: `https://starcitizen.tools`
- wiki/secondary-wiki: `https://starcitizen.tools/Comm-Link:Design_Notes_-_New_Damage_System`
- wiki/secondary-wiki: `https://starcitizen.tools/Comm-Link:Monthly_Report_-_May_2015`
- wiki/secondary-wiki: `https://wargroovewiki.com/mediawiki/index.php?title=Settings&oldid=6916`
- wiki/secondary-wiki: `https://wiki.eveuniversity.org/Visual_effects`
- wiki/secondary-wiki: `https://wiki.sinsofasolarempire2.com/`

#### batch6_opus_blender_deepseek_2026_10_24.md (35 unique cites, 12 weak-pattern)
- forum: `https://blog.cgcookie.com/forums/topic/problem-with-backface-culling/`
- forum: `https://stackoverflow.com/revisions/56b287da-2d4e-4c20-af0b-2430c8cdb43b/view-source`
- forum: `https://www.linkedin.com/posts/chuckdurham_introduction-there-is-a-lot-of-noise-right-activity-7425202187716349952-5iDd`
- forum: `https://x.com/posi_posi8/article/2096190894403952869`
- marketing/vendor-or-aggregator blog: `https://customuse.com/learn/prepare-ai-3d-models-for-animation`
- marketing/vendor-or-aggregator blog: `https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026`
- marketing/vendor-or-aggregator blog: `https://www.tripo3d.ai/blog/gpt-6-astra-3d-character-workflow`
- root-only(no specific page): `modifier.app`
- store/listing: `https://apify.com/ocean3d/modelcheck`
- store/listing: `https://extensions.blender.org/add-ons/blendiff/`
- store/listing: `https://skillsmp.com/zh/creators/nvidia-omniverse/omniverse-labs/projects-ov-blender-example-skills-blender-python-execution`
- store/listing: `https://www.mcpworld.com/en/detail/b78a562618e645e437a69cf7cb72c58d`

#### batch7_effects_deepseek_2026_10_24.md (107 unique cites, 69 weak-pattern)
- forum: `computergraphics.stackexchange.com`
- forum: `discussions.unity.com/t/released-dynamic-decals/:`
- forum: `forum.quartertothree.com`
- forum: `forums.frontier.co.uk`
- forum: `forums.inovaestudios.com`
- forum: `forums.tigsource.com/index.php?topic=72781.45:`
- forum: `fractalsoftworks.com/forum`
- forum: `fractalsoftworks.com/forum/index.php?topic=1724.msg19170:`
- forum: `gamedev.stackexchange.com/questions/213129:`
- forum: `gamedev.stackexchange.com/questions/87408:`
- forum: `hard-light.net/forums/index.php?topic=41002.20:`
- forum: `polycount.com/discussion/191314:`
- forum: `realtimevfx.com/t/profiling-tips/5334/3:`
- forum: `realtimevfx.com/t/smoke-lighting-and-texture-re-usability-in-skull-bones/:`
- forum: `speedrun.com/slay_the_spire/forums/dg73b:`
- forum: `steamcommunity.com/app/268500/discussions/:`
- forum: `steamcommunity.com/app/4718360/allnews/:`
- forum: `the-starport.com`
- forum: `wiki.popcornfx.com/index.php?title=Performance_budget_indicators:`
- marketing/vendor-or-aggregator blog: `adeptusineptus123.github.io/Skinned-Mesh-Painter/:`
- marketing/vendor-or-aggregator blog: `animaticsassetstore.com`
- marketing/vendor-or-aggregator blog: `bitsoulhosting.com`
- marketing/vendor-or-aggregator blog: `brainscape.com`
- marketing/vendor-or-aggregator blog: `bugnet.io`
- marketing/vendor-or-aggregator blog: `colorpick.app/blog/color-game-design-psychology-player-experience:`
- marketing/vendor-or-aggregator blog: `daniellong.org/portfolio/godot-shaders/:`
- marketing/vendor-or-aggregator blog: `docs.forge3d.com/force-field/shaders.md:`
- marketing/vendor-or-aggregator blog: `gameidea.org`
- marketing/vendor-or-aggregator blog: `imaginode.ai`
- marketing/vendor-or-aggregator blog: `morevfxacademy.com`
- marketing/vendor-or-aggregator blog: `northwestmediasystems.com`
- marketing/vendor-or-aggregator blog: `sarahclaritystudios.com`
- marketing/vendor-or-aggregator blog: `sf-studio.gitbook.io`
- marketing/vendor-or-aggregator blog: `sonilo.com`
- marketing/vendor-or-aggregator blog: `strayspark.studio/blog:`
- marketing/vendor-or-aggregator blog: `xiyuesheji.com`
- root-only(no specific page): `GameDev.net`
- root-only(no specific page): `Theseus.fi`
- root-only(no specific page): `adventuresincausality.com`
- root-only(no specific page): `chsxf.medium.com`
- root-only(no specific page): `courses.cs.washington.edu`
- root-only(no specific page): `cryengine.com`
- root-only(no specific page): `dev.epicgames.com`
- root-only(no specific page): `docs.unity.com`
- root-only(no specific page): `docs.unity3d.com`
- root-only(no specific page): `gaijinentertainment.github.io`
- root-only(no specific page): `gdad.wiki`
- root-only(no specific page): `gitcode.com`
- root-only(no specific page): `low-drag-mc.github.io`
- root-only(no specific page): `medium.com`
- root-only(no specific page): `playground.ru`
- root-only(no specific page): `positech.co.uk`
- root-only(no specific page): `pub.dev`
- root-only(no specific page): `store.steampowered.com`
- root-only(no specific page): `tesera.ru`
- root-only(no specific page): `wiki.lesta.ru`
- root-only(no specific page): `www1.matrixgames.com`
- store/listing: `assetstore.unity.com`
- store/listing: `assetstore.unity.com/packages/tools/particles-effects/shipvfx-399680:`
- store/listing: `itch.io/profile/sergeyg-space`
- store/listing: `ultimategameassets.com`
- truncated: `github.com/mcp-tool-shop-org/ai-rpg-engine/compare/v2.4.0...main:`
- wiki/secondary-wiki: `advancewars.fandom.com/wiki/Advance_Wars_1%2B2:_Re-Boot_Camp`
- wiki/secondary-wiki: `bioshock.fandom.com`
- wiki/secondary-wiki: `kittenspaceagency.wiki.gg/wiki/Version_2026.9.10.5438:`
- wiki/secondary-wiki: `starcitizen.tools`
- wiki/secondary-wiki: `tvtropes.org`
- wiki/secondary-wiki: `xcom.fandom.com`
- wiki/secondary-wiki: `zh.ashesofcreation.wiki`

#### batch8_asset_packs_deepseek_2026_10_24.md (1 unique cites, 1 weak-pattern)
- root-only(no specific page): `rodin3ds.com`

#### engine_comparison_deepseek_2026_10_24.md (35 unique cites, 28 weak-pattern)
- forum: `https://forum.babylonjs.com/t/performance-compared-to-godot-and-other-engines/59731`
- forum: `https://p.jlai.lu`
- forum: `https://www.reddit.com/r/ClaudeAI/comments/1xdhkzb/no_coding_or_gamedev_background_6_weeks_with_opus/`
- forum: `https://www.reddit.com/r/Unity3D`
- forum: `https://www.reddit.com/r/rust/comments/1niyavg/community_reflection_on_bevys_fifth_year/`
- garbled: `https://safe.search.brave.com/goggles?q=best%20games%20to%20win%20real%20money`
- marketing/vendor-or-aggregator blog: `https://bitsoulhosting.com`
- marketing/vendor-or-aggregator blog: `https://brainxx.site`
- marketing/vendor-or-aggregator blog: `https://buzzradr.com/ai/ai_topic_dwtuxg`
- marketing/vendor-or-aggregator blog: `https://cadmus.page`
- marketing/vendor-or-aggregator blog: `https://daily.dev`
- marketing/vendor-or-aggregator blog: `https://engineranked.com`
- marketing/vendor-or-aggregator blog: `https://engineranked.com/article/bevy-vs-godot-systems-heavy-2d-2026`
- marketing/vendor-or-aggregator blog: `https://factory.com`
- marketing/vendor-or-aggregator blog: `https://flockbay.com`
- marketing/vendor-or-aggregator blog: `https://scriptsforunity.com`
- marketing/vendor-or-aggregator blog: `https://www.deskifier.com`
- marketing/vendor-or-aggregator blog: `https://www.strayspark.studio`
- marketing/vendor-or-aggregator blog: `https://www.strayspark.studio/blog/bevy-rust-game-engine-2026-indie-guide`
- root-only(no specific page): `https://doc.babylonjs.com`
- root-only(no specific page): `https://docs.godotengine.org`
- root-only(no specific page): `https://vav-labs.com`
- root-only(no specific page): `https://webcodingcenter.com`
- root-only(no specific page): `https://www.babylonjs.com`
- store/listing: `https://lobehub.com`
- store/listing: `https://superhivemarket.com`
- store/listing: `https://www.npmjs.com/package/gameshipper`
- wiki/secondary-wiki: `https://deepwiki.com/bytemeadow/godot-bevy/6.2-performance-comparisons`
