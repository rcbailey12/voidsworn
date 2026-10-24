# DRAFT: Tool guides re-tier plan for Voidsworn (PC-only)

Model: DeepSeek, DeepThink ON, Search OFF. Filed verbatim from the DeepSeek chat report; em dashes normalized to hyphens, wording otherwise unchanged. The brief was pasted into the prompt (chat file upload failed: no usable file input), and verbatim excerpts of tool_guides.md (heading structure, framing passages, line-indexed tier list, quality gates, local image models intro and licence warning) were pasted alongside it, with an instruction that DeepSeek quote only from those excerpts and mark anything unverifiable as Opus-to-confirm. Process note from the run: DeepThink ran 41 seconds; existing session signed in as Ryan Bailey, no phone prompt. This draft is a proposal for the owner (Ryan) and for Opus, not a ruling. Opus owns the actual doc edit.

Status: DRAFT for Ryan and for Opus. Nothing here is decided until Ryan rules. Opus owns the actual doc edit.

Basis of this draft: the granted excerpts of tool_guides.md (heading structure, lines 1-30, lines 186-212, the line-indexed tier list, the quality gates section lines 684-695, and the local image models section lines 696-714). Line numbers below refer to that version. Where I need a passage that is not in the granted excerpts, it is marked Opus-to-confirm - no passage is quoted or invented in its place.

Standing OBSERVED facts carried into every section below:

- [OBSERVED, doc] The doc is still phone-first in framing: two-tier budgets, a "phone first with a desktop tier" brief at line 188, and phone-versus-desktop splits inside the Babylon part.
- [OBSERVED, brief] Oct 24, 2026 PC-only ruling: PC-only in Babylon, phone target dropped entirely. The desktop GPU budget is the design floor. No phone tier, no phone pass, no phone acceptance gate.
- [OBSERVED, brief] Open check, not resolved here: the official Blender Lab MCP requires Blender 5.1 or newer; the PC's installed Blender version is unchecked. Carried in section 5.

## 1. Section-by-section re-tier table

Dispositions are PROPOSED. Every reason line is a PROPOSED judgement resting on the OBSERVED quote or the OBSERVED ruling named.

### 1A. Framing

| # | Location | Disposition | Reason (one line) |
| 1 | Line 3-4, byline paragraph ("From Rey (Muse)... shipped hulls, effects and sounds.") | Keep verbatim | [OBSERVED] Contains no tier or phone framing; nothing to re-tier. |
| 2 | Line 7, merged chain: "phone-tier compression gate" | Rewrite | [PROPOSED] The gate survives, its phone qualification does not; PC-only makes it a desktop compression gate. |
| 3 | Line 7, merged chain: "bake to the game tiers" | Rewrite | [PROPOSED] Plural tiers no longer exist; singular budget. |
| 4 | Line 7, merged chain: "keep the phone tier alive" | Strike | [PROPOSED] This is the load-bearing phone justification of the whole chain; PC-only removes it. |
| 5 | Line 13, Top finds: "regression on the phone tier" | Rewrite | [PROPOSED] The HDR/AA trap is real on desktop; the example regression must be re-anchored to the desktop target. |
| 6 | Line 15, Top finds: "The gltfpack two-tier recipe" and "-si and -ts flags added for the phone tier" | Rewrite | [PROPOSED] Two-tier recipe framing goes; whether -si/-ts stay in the desktop recipe is Opus-to-confirm, since the granted text ties them to the phone tier. |
| 7 | Line 29, Part 1 intro: "The game ships one HTML build with two asset tiers (phone meshes and desktop meshes)" | Rewrite | [PROPOSED] Direct two-tier statement in the Part 1 premise; must become one desktop tier. Rest of the sentence (meshoptimizer, painted materials, vertex colour AO) is tier-neutral and can stand. |
| 8 | Line 188, Part 2 intro: "phone first with a desktop tier" | Rewrite | [OBSERVED, brief] This is the named line-188 framing; PC-only inverts it to desktop-only. The rest of the intro (many ships, faction-readable effects, beams, shields, cinematic camera) is tier-neutral. |
| 9 | Line 438, Part 3 intro: "feeding a Babylon.js game with phone and desktop asset tiers" | Rewrite | [PROPOSED] Same two-tier premise, in the glue part. |
| 10 | Line 264, heading: "#### KTX2 and Basis: the phone memory win" | Rewrite | [PROPOSED] Heading states a phone framing; the underlying fact (line 266: "KTX2 shrinks GPU memory") holds on desktop. |

### 1B. Budget sections

| # | Location | Disposition | Reason (one line) |
| 11 | Line 178, "8. Triangle budget per tier." - the instruction text ("per hull, per tier", "fail the build") | Rewrite | [PROPOSED] Drop "per tier"; the fail-the-build gate is exactly what the brief keeps as the desktop floor. |
| 12 | Line 178 - "desktop hulls run roughly 2,400 to 38,000 triangles" | Keep verbatim | [OBSERVED] The doc's own desktop number; it is the only budget figure that survives, and quoting it invents nothing. |
| 13 | Line 178 - "phone roughly 1,200 to 16,000" | Strike | [PROPOSED] Phone budget figure; no phone tier exists. |
| 14 | Line 178 - "all hulls load at boot, so the budget is a fleet total, not a per-hull wish" | Keep verbatim | [OBSERVED] Tier-neutral and still the reason the budget is a fleet total. |
| 15 | Line 282, draw call budget - "roughly 500 to 1000 draw calls at 60 fps on desktop browsers" | Keep verbatim | [OBSERVED] Desktop figure, with its "community practice, not an engine guarantee" caveat attached. |
| 16 | Line 282 - "and roughly 100 to 300 on mobile browsers" | Strike | [PROPOSED] Mobile figure; no phone target. |
| 17 | Line 282 - "from a mobile Babylon guide" (source attribution) | Keep, flag | [PROPOSED] Do not silently drop the provenance - the doc's honesty practice is to label sources; Opus should decide whether the mobile-guide origin still supports the desktop figure or needs re-sourcing (Opus-to-confirm). |
| 18 | Line 691, quality gate: "Two numbers per hull, phone tier and desktop tier, set by the project." | Rewrite | [PROPOSED] Two numbers become one; "set by the project" stays, so no new budget is invented here. |
| 19 | Line 691 - "A hull over its phone budget fails; decimation is not optional polish." | Rewrite | [PROPOSED] The fail rule is an acceptance gate and must survive, re-pointed at the desktop budget. |
| 20 | Line 692 - "the texture resolution must match the tier (a 4K map on a phone tier hull is waste, and it is the texture budget problem the asset inventory already flagged)" | Rewrite | [PROPOSED] Coverage/overlap rule is kept verbatim; the parenthetical resolution clause is phone-anchored and needs replacement wording from Opus (Opus-to-confirm the exact replacement - I will not draft a new texture rule here). |
| 21 | Line 12, Top finds: "The guide puts the budget gate in the .bat chain so it cannot be skipped." | Keep verbatim | [OBSERVED] The gate mechanism is tier-neutral and is the enforcement the desktop floor depends on. |

### 1C. Every other phone-first passage found

| # | Location | Disposition | Reason (one line) |
| 22 | Line 45: "Use Separate while a hull is being debugged, Binary for the shipped tier." | Keep verbatim | [PROPOSED] "Shipped tier" here is build state, not phone-versus-desktop; flag it so the strike pass does not sweep it up. |
| 23 | Line 85: "Name outputs <hull_code>_hi.glb and <hull_code>.glb for the two tiers, from the same source" | Rewrite | [PROPOSED] Two-tier naming goes; whether _hi survives as the bake-source name is Opus-to-confirm. |
| 24 | Line 94: "For the phone tier, triangle budget comes first and compression second." | Rewrite | [PROPOSED] The ordering (triangles before compression) is true on desktop and worth keeping; only the phone qualifier goes. |
| 25 | Line 95: "KTX2 is the phone memory win. ... the actual phone bottleneck." | Rewrite | [PROPOSED] The WebP-versus-KTX2 distinction (transmission vs GPU memory) is desktop-true; the word "phone" is doing the framing. |
| 26 | Line 109: "That is the phone tier. Bake the removed detail into the normal map (section 5)." | Rewrite | [PROPOSED] Keep the bake-the-detail-back instruction; drop the phone-tier sentence. |
| 27 | Line 110: "Detail that reads at desktop distance is noise at phone distance." | Strike | [PROPOSED] Pure phone-distance art judgement; with no phone target it is not a criterion. |
| 28 | Line 111: "Desktop tier at full detail, phone tier as the same mesh with a Decimate pass... Two separately modeled hulls drift; one model with two ratios does not." | Rewrite | [PROPOSED] The one-model-multiple-ratios principle is classic LOD practice and should survive; it must be re-framed as LOD within one desktop tier, which depends on decision D4 below. |
| 29 | Line 163: "so the simplification pass (section 4) can delete them for the phone tier without touching the hull" | Rewrite | [PROPOSED] Purpose clause is phone-anchored; if LOD stays in scope the separability point survives, otherwise it goes (Opus-to-confirm against section 4's body, not granted). |
| 30 | Line 205: "pipeline.fxaaEnabled = true is the cheap AA alternative on phones." | Rewrite | [PROPOSED] The flag is real and stays; "on phones" is the only thing wrong with the sentence. |
| 31 | Line 208: "Depth of field, motion blur and SSAO2 all cost performance every frame; treat them as desktop tier only." | Rewrite | [PROPOSED] "Desktop tier only" loses meaning when desktop is the only tier; the cost warning must be restated as a budgeting rule, not as a tier boundary. |
| 32 | Line 210: "Phone versus desktop: phone gets FXAA (or MSAA 2), bloom at reduced scale, ACES grade, no depth of field, no motion blur, no SSAO. Desktop gets MSAA 4, full bloom, and the depth effects." | Rewrite | [PROPOSED] Strike the phone half; the "Desktop gets MSAA 4, full bloom, and the depth effects" clause is the doc's own desktop baseline and can be reused without inventing settings. |
| 33 | Line 217: "...it is the right tool for shields, engine glow, beam cores and faction accents on a phone." | Rewrite | [PROPOSED] The four use cases are core to Voidsworn and stay; drop "on a phone". |
| 34 | Line 219: "glow.mainTextureSamples (2 is a common phone friendly value)." | Rewrite | [PROPOSED] Setting stays; the value 2 was chosen for phones and must not be silently promoted to the desktop default - replacement value is decision D7, not mine to set. |
| 35 | Line 243: "which matters when the phone texture budget is the hard limit." | Rewrite | [PROPOSED] Texture budget still matters; the phone is no longer the reason. |
| 36 | Line 266: "transcodes at load time to whatever the GPU supports (BC7 on desktop, ASTC or ETC2 on mobile)" | Rewrite | [PROPOSED] Keep the mechanism and the BC7 desktop target verbatim; the mobile clause is informational and should be trimmed rather than asserted as a shipped path. |
| 37 | Line 312: "engine.setHardwareScalingLevel(1.5) when fill rate limits the phone; values below 1 render above native resolution and cost performance." | Rewrite | [PROPOSED] The API and the sub-1 warning are tier-neutral facts; the 1.5 example is a phone value, replacement is decision D7. |
| 38 | Line 371: "On phones, halve capacities and drop sub-emitters first; the optimizer's ParticlesOptimization step does this automatically if enabled." | Rewrite | [PROPOSED] "Drop sub-emitters first" and the optimizer step are transferable ordering; "on phones, halve capacities" is a phone rule. |
| 39 | Line 409: "WebGPU availability on mobile browsers is uneven... Do not ship a WebGPU only build while the phone is the reference device." | Rewrite | [PROPOSED] The phone-as-reference-device rule is void; the WebGL-fallback question must be re-grounded by Opus (Opus-to-confirm - the granted text gives only the mobile rationale, so I will not manufacture a desktop one). |
| 40 | Line 459: "run twice with different simplification and texture scale for the two tiers" | Rewrite | [PROPOSED] "Run twice... two tiers" is the two-tier export recipe; single run, single tier. |
| 41 | Line 466: "at least one Babylon forum user reported iPhone problems with Draco that made them switch." | Keep verbatim, flag | [PROPOSED] This is labelled secondhand evidence for the Draco-versus-meshopt choice, not a phone tier; Opus should decide whether it still earns its place once the mobile testing rationale is gone. |
| 42 | Line 494: "...which makes them good defaults for a desktop tier." | Rewrite | [PROPOSED] Drop "for a desktop tier" - they are now simply the defaults; the XUASTC-to-BC7 transcode fact is quoted, not extended. |
| 43 | Line 678: "separate phone and desktop tiers. The phone tier is the gate: if a hull fails the phone budget, it goes back to step 3, not forward with a warning." | Rewrite | [PROPOSED] Two-tier shipping and the phone gate both go; "goes back to step 3, not forward with a warning" is the acceptance discipline and must survive. |
| 44 | Line 741: "to the gltfpack and KTX2 step from the glue section, phone tier first." | Strike | [PROPOSED] Sequencing rule that exists only to order two tiers. |

### 1D. False positives - do not edit in the strike pass

| # | Location | Disposition | Reason (one line) |
| 45 | Line 142 "studio tiers $199 and $349"; line 645 "their licences are tiered. Read the tier, not the headline."; lines 649-666 Meshy/Rodin/Genie "free tier" commercial-use rows; line 754 "Luma Genie free tier terms" | Keep verbatim | [OBSERVED] Licence and pricing tiers, not asset tiers. |
| 46 | Line 423 "The Babylon.js Editor is a community managed desktop application (Apache 2.0, around version 5.5)" | Keep verbatim | [OBSERVED] "Desktop application" is software class, not a phone-versus-desktop asset tier. |
| 47 | Line 184: "Blender 5 claims in secondary sources were not relied on, and version-sensitive details (Auto Smooth location, Principled Emission support) should be checked against the installed Blender version." | Keep verbatim | [OBSERVED] Tier-neutral and it is the doc's own hook for the open Blender check in section 5. |
| 48 | Lines 684-690, quality gates: silhouette readability, manifold and solid, no floaters | Keep verbatim | [OBSERVED] No phone or tier framing in the granted text of these gates. |
| 49 | Honesty notes (lines 23-27) | Keep verbatim | [OBSERVED] No tier framing in the granted text. |

## 2. Rewritten framing paragraphs (desktop-only)

Both paragraphs are [PROPOSED]. They use only facts already in the granted text plus the OBSERVED PC-only ruling from the brief. No new budgets, no new tool recommendations, no new version facts.

### 2a. Doc opening

Two parts here, because the byline paragraph is already tier-neutral.

Byline paragraph - keep verbatim [OBSERVED]: "From Rey (Muse), Oct 24, 2026. Commissioned by Ryan as the how-to companion to the field guide: concrete settings, flags, commands and workflows for the tools Opus actually runs, drawn from official docs, repos, forums and community threads. Companion to mod_scene_field_guide.md in this folder: that document is mechanisms and assets to steal; this one is how to run the toolchain that turns them into shipped hulls, effects and sounds."

[PROPOSED] One optional sentence to insert after it, stating the scope the rest of the document assumes: Voidsworn is PC-only as of Oct 24, 2026: one desktop build, the desktop GPU budget is the design floor, and no phone tier exists anywhere in this document. (Ryan to approve or cut - see decision D1.)

Rewritten merged-chain paragraph [PROPOSED]:

An AI mesh and an AI texture enter the pipeline separately and join only at the bake. The mesh goes through a seven-step cleanup (audit, remesh and retopology, silhouette-safe decimation, UV unwrap, kit parts attached at manifest landmarks, high-to-low bake, desktop compression gate) and the texture goes through a local estimation chain (CHORD or Hunyuan paint or UltraTex from one flat-lit image, ControlNet for structure, IPAdapter for look, a style LoRA trained on the final plates for consistency). The cleaned hull and the estimated maps meet in Blender, bake to the game budget, and ship through gltfpack plus KTX2 into Babylon, where thin instances, frozen materials and a self-hosted KTX2 transcoder hold the frame budget on the desktop target. Every part below is one link of that chain, and the checker pattern (AJV schema validation, a reference checker for dangling ids, a golden-save compatibility test) guards the joints.

What changed, all of it deletion or re-anchoring [PROPOSED]: "phone-tier compression gate" to "desktop compression gate"; "bake to the game tiers" to "bake to the game budget"; "keep the phone tier alive" to "hold the frame budget on the desktop target". Nothing else in the paragraph moved.

### 2b. Budget section (line 178, pre-export checklist item 8)

Original [OBSERVED]: "8. Triangle budget per tier. Print the triangle count after export, per hull, per tier, and fail the build if a hull exceeds its budget. The game's own numbers give the shape of it: desktop hulls run roughly 2,400 to 38,000 triangles, phone roughly 1,200 to 16,000, and all hulls load at boot, so the budget is a fleet total, not a per-hull wish."

Rewritten [PROPOSED]:

Triangle budget. Print the triangle count after export, per hull, and fail the build if a hull exceeds its budget. The game's own numbers give the shape of it: desktop hulls run roughly 2,400 to 38,000 triangles, and all hulls load at boot, so the budget is a fleet total, not a per-hull wish.

This is a pure deletion of the per-tier language and the phone range. The surviving desktop range is the doc's own figure, quoted, not a new budget.

### 2c. Secondary budget passage (line 282, draw calls) - rewritten for consistency

Original [OBSERVED]: "Community guidance from a mobile Babylon guide puts the practical budget at roughly 500 to 1000 draw calls at 60 fps on desktop browsers and roughly 100 to 300 on mobile browsers. Treat that as community practice, not an engine guarantee, and measure with the Inspector."

Rewritten [PROPOSED]:

Community guidance from a mobile Babylon guide puts the practical budget at roughly 500 to 1000 draw calls at 60 fps on desktop browsers. Treat that as community practice, not an engine guarantee, and measure with the Inspector.

The source attribution is deliberately left in place rather than tidied away, because the doc's honesty practice is to label where a number comes from. Opus may prefer to re-source the figure; that is decision D3.

## 3. Transferable optimization advice to KEEP

All dispositions [PROPOSED]; each item is described by its content as it appears in the granted text. Items marked Opus-to-confirm are ones where I can see the heading but not the body, and I will not assert the body's contents.

### Pipeline and export mechanics

- The glTF occlusion hook (line 11): occlusion only exports through a custom node group literally named glTF Settings with an Occlusion input. [OBSERVED] Nothing about it is phone-specific; it is the mechanism the game's ORM-packed painted materials depend on.
- Compression is not simplification (line 12): "KTX2 fixes memory, only triangle cuts fix framerate," and the budget gate lives in the .bat chain so it cannot be skipped. [OBSERVED] Directly matches the brief's "desktop GPU budget is the design floor."
- gltfpack -kn (line 15): keeps named hardpoint nodes the game addresses by name. [OBSERVED] Tier-neutral and load-bearing for the game loader.
- The gltfpack-and-KTX2 ship step with a hard fail (line 678): a hull that fails the budget "goes back to step 3, not forward with a warning." [OBSERVED] This is the acceptance discipline; only its phone anchor changes.
- The checker pattern (line 16): AJV schema validation per data file runnable as a .bat step, a reference checker modelled on RPFM's broken-key diagnostics, and a golden-save compatibility test per shipped version. [OBSERVED] Nothing tier-related in the granted text.
- KTX2 versus WebP (line 95): WebP shrinks transmission size, KTX2 shrinks GPU memory; gltfpack -tc is the one-flag route. [OBSERVED] The memory argument is stronger, not weaker, on a desktop GPU budget floor.
- XUASTC block sizes 4x4, 6x6, 8x6 transcode directly to BC7, skipping an encode step (line 494). [OBSERVED] Desktop-relevant by construction; the doc itself says BC7 is the desktop target at line 266.
- Draco versus meshopt tradeoff (line 466, partially quoted): the tradeoff itself is a desktop choice. [OBSERVED/partial] Body text beyond the quoted iPhone sentence is Opus-to-confirm.

### Babylon rendering and performance

- The HDR and AA trap (lines 196-201): with hdr = true the scene renders to an offscreen texture and canvas AA silently stops applying until pipeline.samples is set; with hdr = false and image processing only, canvas AA applies until bloom is enabled. [OBSERVED] This is a desktop regression source and is the single most valuable item in Part 2 to keep intact.
- The desktop baseline on line 210: "Desktop gets MSAA 4, full bloom, and the depth effects." [OBSERVED] Already a desktop statement - reuse it rather than writing a new one.
- Thin instances versus SPS with numbers (line 14): the same asteroid field measured at 15 fps with a solid particle system and 60 fps with thin instances. [OBSERVED] Settles the debris and asteroid architecture; contains no phone framing.
- Draw call budgeting with the Inspector (line 282): measure rather than trust the community figure. [OBSERVED] The measuring practice survives; the mobile number does not.
- Particle optimization ordering (line 371): drop sub-emitters first, and the optimizer's ParticlesOptimization step does it automatically if enabled. [OBSERVED] Transferable ordering; the "halve capacities" phone rule is not.
- Hardware scaling mechanics (line 312): engine.setHardwareScalingLevel exists, and "values below 1 render above native resolution and cost performance." [OBSERVED] The fact survives; the 1.5 example value does not.
- Section bodies I can only see as headings - "Freezing, culling and the render loop", "#### LOD", "SceneOptimizer and performance priority", "Shader compilation stalls", "Disposal pitfalls, the memory leak checklist", "SPS versus thin instances" body beyond the Top finds summary: Opus-to-confirm that each contains no phone-first framing and that the advice is desktop-transferable. I am not asserting their contents.

### Asset craft and quality gates

- One model, multiple ratios (line 111): "Two separately modeled hulls drift; one model with two ratios does not." [OBSERVED] The principle transfers to LOD generation inside a single desktop tier. Whether LOD stays in scope is decision D4.
- Quality gates, lines 686-690 (silhouette readability at in-game size, manifold and solid via the 3D Print Toolbox, no floaters, no nested internal shells): [OBSERVED] All tier-neutral and all cheap; keep verbatim.
- Baked lighting check (line 693): the colour map must be flat-lit; painted shadows are rejected or re-textured rather than compensated for in material settings. [OBSERVED] Tier-neutral.
- Reject on sight (line 694): melted or fused detail where a gun should read as a separate part, mirrored or smeared text and insignia, asymmetry on a symmetric hull, seams across the most visible face. [OBSERVED] Tier-neutral.
- Kit parts as the AI mesh fix (line 17): hand-built kit parts are the fix for an AI mesh's fused, unreadable detail; the AI hull supplies the big form, the kit supplies readable guns, tanks and slabs at manifest landmarks, and the bake makes the cleaned hull read like the dense original. [OBSERVED] Entirely tier-neutral and central to the game's look.

### AI and texture tooling

- Safe local image bases on 16 GB (lines 18, 702-714): Qwen-Image under Apache 2.0 (quantized builds fit 16 GB), FLUX.1 schnell or klein 4B (both Apache 2.0); self-hosted FLUX.1 dev is the trap, with clauses 2(d) and 4(a)(i) of v1.1.1 in tension, and a LoRA trained on a dev base inheriting the restriction. [OBSERVED] This is a licence question, not a device question; a PC-only ruling changes nothing about it.
- The local texture chain (line 19): CHORD estimates a full PBR set from one flat-lit image, Hunyuan paint bakes multi-view diffusion onto UVs with inpainting for unseen areas, UltraTex paints six views at once at around 6.8 GB VRAM. [OBSERVED] VRAM fit on a 16 GB card is a desktop concern now, not a mobile one.
- ComfyUI as the runner (lines 698-700): node graph workflows, automatic GPU offloading, workflow embedded in every PNG, GPL-3.0. [OBSERVED] Tier-neutral.
- The honesty convention itself (lines 23-27): secondhand forum and Reddit wisdom labelled as such throughout, gaps flagged in place. [OBSERVED] This is the practice the doc's credibility rests on and it should be preserved through the edit.

## 4. What must NOT come back

[PROPOSED] Prohibition list. Opus should treat these as edit-time rules for the doc, not suggestions.

- No phone tier, in any form. Not as a section, not as a "for completeness" appendix, not as an "also consider" aside, not as a "for lower-end PCs" substitute that reproduces the same split under a new name. The desktop GPU budget is the floor.
- No phone acceptance gates. Specifically, no gate of the shape at line 678 ("The phone tier is the gate... it goes back to step 3") and no gate of the shape at line 691 ("A hull over its phone budget fails"). One budget, one fail condition.
- No two-tier budgets. No paired numbers at line 178, no paired draw-call figures at line 282, no paired per-hull numbers at line 691, no paired texture-resolution clause at line 692.
- No two-tier export recipe. No "run twice with different simplification and texture scale for the two tiers" (line 459); no -si/-ts justified by a phone tier (line 15) unless Ryan rules separately that those flags earn a place on desktop grounds.
- No phone-chosen values promoted to desktop defaults by inertia. Line 219's glow.mainTextureSamples value of 2, line 312's 1.5 hardware scaling, and line 205's FXAA-on-phones rationale were all phone decisions; reinstating the numbers as desktop defaults without a ruling is a way of smuggling the tier back in.
- No phone distance in art judgement. Line 110's "noise at phone distance" is not a criterion any more; decimation and LOD are justified by the desktop budget, not by a viewing distance the game no longer has.
- No phone framing retained as historical colour. No "this used to matter on phones," no strikethrough-with-note, no parenthetical "(mobile: ...)" left in place "for reference." The ruling is a cut, not an annotation.
- No mobile testing requirement rebranded. Line 409's "Do not ship a WebGPU only build while the phone is the reference device" cannot survive in any form that still implies mobile verification is an acceptance step. Whether a WebGL fallback remains required is a separate decision (D6), not a licence to keep the mobile clause.

## 5. Open item: Blender version check

[OBSERVED, brief] The official Blender Lab MCP requires Blender 5.1 or newer. The Blender version installed on the PC is an open check and has not been verified in this pass.

[OBSERVED, doc, line 184] The doc already flags its own exposure: "Blender 5 claims in secondary sources were not relied on, and version-sensitive details (Auto Smooth location, Principled Emission support) should be checked against the installed Blender version."

Status: OPEN. Not resolved here, and deliberately not resolved by me.

Owner: Opus - to check the installed Blender version on the PC.

Consequence while open [PROPOSED]: no Blender-version-specific claim should be written into the re-tiered doc. Part 1 guidance that depends on version-sensitive details (Auto Smooth location, Principled Emission support, and anything gated by the MCP's 5.1 requirement) stays flagged in place until Opus reports the installed version. If the installed version is below 5.1, that is a separate problem for Ryan, not a doc edit.

What this draft does not do [PROPOSED]: it does not assert which version is installed, does not assume 5.1 is present, and does not recommend an upgrade path.

## Decisions Ryan must make

D1 - Scope sentence. Approve or cut the one-line PC-only scope statement proposed for insertion after the byline paragraph (section 2a).

D2 - Single triangle budget. Confirm whether the doc's own desktop range, "roughly 2,400 to 38,000 triangles" (line 178), becomes the single per-hull budget, and confirm the fleet-total framing that follows it. The doc says the numbers are the project's, so the ruling is yours.

D3 - Draw call figure. Confirm that the 500-1000 desktop figure at line 282 stands as the working target, and whether it keeps its current "from a mobile Babylon guide" provenance or needs re-sourcing by Opus.

D4 - LOD in scope or not. Line 111's one-model-multiple-ratios principle and line 163's simplification pass both depend on this. If LODs stay, they are LODs inside one desktop tier; if not, those passages get cut rather than re-framed. This also settles decision D4's knock-on for line 85's _hi.glb naming.

D5 - gltfpack -si and -ts. The granted text ties both flags to the phone tier (line 15). Rule whether they remain in the desktop recipe on their own merits or come out.

D6 - WebGL fallback. The doc's only stated reason for testing the fallback is mobile unevenness (line 409). Rule whether a tested WebGL fallback remains a requirement on the desktop target; Opus cannot ground this from the granted text alone.

D7 - Phone-chosen values. Rule on replacements for the three values that were picked for phones: glow.mainTextureSamples (currently 2, line 219), setHardwareScalingLevel (currently 1.5, line 312), and the AA approach (line 205). The doc's own desktop line 210 states MSAA 4, full bloom and the depth effects - confirm that is the baseline and let Opus fill the remaining two from measurement, not from invention.

D8 - Texture resolution clause. Line 692's parenthetical is phone-anchored. Rule whether Opus writes a replacement desktop clause or simply drops the parenthetical and leaves coverage/overlap as the whole gate.

D9 - Sign-off order. Confirm that the doc edit waits on the open Blender check (section 5) or proceeds with that section flagged, and confirm Opus owns the edit as stated in the brief.
