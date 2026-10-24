# Verification sweep, round 4 part 1

Checked 2026-10-24 against primary sources: official pages, repos, model cards, and licence texts actually opened, not search snippets alone, wherever the item says "opened". Where a primary page could not be opened, the report says so. Nothing in this file edits the design documents; it only states what should change in them.

Verdict tally: 15 VERIFIED, 3 CORRECTED, 2 STILL UNVERIFIED.

- VERIFIED means the design doc claim holds against a primary source, or the flagged gap is now closed by one.
- CORRECTED means the design doc text is wrong or stale and must change; exact replacement wording is given.
- STILL UNVERIFIED means the primary source was not found after repeated attempts; what was tried is stated.

## 1. FLUX.1 dev licence: VERIFIED

Primary source opened: https://raw.githubusercontent.com/black-forest-labs/flux/refs/heads/main/model_licenses/LICENSE-FLUX1-dev (FLUX.1 [dev] Non-Commercial License v1.1.1, the current text in Black Forest Labs' own repo).

The disagreement the design docs flagged is real, and it lives inside this single licence text, not just between secondary sources:

- Clause 2(d): "You may use Output for any purpose (including for commercial purposes), except as expressly prohibited herein. You may not use the Output to train, fine-tune or distill a model that is competitive with the FLUX.1 [dev] Model."
- Clause 4(a)(i): bars using the model, any Derivative, "or any data produced by the FLUX.1 [dev] Model" for any commercial or production purposes.
- Clause 1(a): a Derivative includes any customized or fine-tuned version of the model; "For the avoidance of doubt, Outputs are not considered Derivatives."
- Clause 2(a): "Any restrictions set forth herein regarding the FLUX.1 [dev] Model also apply to any Derivative you create."

So the doc's safe reading stands unchanged: a LoRA trained on a dev base explicitly inherits the restriction, and a shipped game built on self-hosted dev weights is blocked under the conservative reading. The only addition worth making to tool_guides.md is a citation of v1.1.1 clauses 2(d) and 4(a)(i) as in tension, replacing the vaguer "two secondary sources disagree" note. The recommended safe routes (FLUX.1 schnell Apache 2.0, 4B klein Apache 2.0, BFL API images) are unaffected.

## 2. REDmod: VERIFIED

Primary sources: CD Projekt Red's modding support page, https://www.cyberpunk.net/en/modding-support (named as the official support page in the GOG listing for REDmod), and the official REDmod documentation text describing the tools/redmod folder structure.

What the official docs actually cover: mods load from the game's mods folder; scripts in mods/name/scripts compile into a modded script blob; tweak files in mods/name/tweaks compile into a modded tweakDB blob; sound files in mods/name/customSounds are staged to load; deployment and load order are handled with REDlauncher, Vortex Mod Manager, or WolvenKit integration; legacy archive mods in archive/pc/mod still load but their load order cannot be managed with REDmod. REDmod is the official Cyberpunk 2077 Modding Tools free DLC.

This closes the field guide gap ("REDmod specifics rest on the community wiki, not a CD Projekt Red manual page"). TweakDB is covered officially through the tweaks folder compiling to a modded tweakDB blob. No doc change needed beyond dropping the community-wiki-only caveat.

## 3. SKSE: VERIFIED

Primary source opened: https://skse.silverlock.org/

The official site is live, maintained, and names the current builds: Anniversary Edition build 2.3.1 (game version 1.7.104), GOG Anniversary Edition build 2.2.6 (game version 1.6.1179), Special Edition build 2.0.20 (game version 1.5.97), classic build 1.7.3, VR build 2.0.12. A warning dated 2026-08-14 notes an incoming Bethesda update after two and a half years without one. The site also states SKSE supports only the latest Steam version, and does not support the Windows Store, Game Pass, or Epic releases. This closes the field guide gap ("SKSE site never opened").

## 4. Hunyuan3D 2.1: VERIFIED

Primary source: the LICENSE and README text of https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1, read via the repo mirror (the LICENSE sections are quoted there in full).

Confirmed: shape generation needs 10 GB VRAM, texture generation 21 GB, the complete pipeline 29 GB. The Tencent Hunyuan 3D 2.1 Community License defines Territory as worldwide excluding the European Union, the United Kingdom, and South Korea. Model Derivatives (fine-tunes, distillations, synthetic-data training) are subject to the full restrictions; Outputs (meshes, textures) are not Model Derivatives and are owned by the user. Commercial use above 1 million monthly active users triggers a licence requirement. One secondary article adds an attribution requirement plus retaining a "Created with Hunyuan3D" identifier; that attribution line is the only part still secondhand.

This closes the tool guide gap: the 29 GB figure and the EU, UK, and South Korea exclusions are no longer "reported" or "secondhand". They can be stated as licence facts.

## 5. TripoSG licence: STILL UNVERIFIED

Tried: the VAST-AI/TripoSG Hugging Face model card (no licence field appears in the card text; intended uses include gaming and VFX asset creation; CUDA GPU above 8 GB VRAM required), VAST's own open source month blog post (calls the weights and inference code open source but names no licence), and a refactored copy (gen-lab/TripoSG) that says only "released under the same license as the original project" without naming it.

TripoSplat's MIT licence was found (github.com/VAST-AI-Research/TripoSplat), but that is a different project and must not be carried over to TripoSG, exactly as the design docs already warn. Do not cite TripoSR MIT either. Until VAST publishes a licence file for TripoSG itself, the doc's caution stands and TripoSG stays out of any shipped-asset recommendation.

## 6. DreamGaussian: CORRECTED

Primary source: the repo's own LICENSE, read via the Hugging Face mirror of the dreamgaussian project and corroborated by GitHub API fork metadata (licence key MIT).

DreamGaussian's own code is MIT licensed (copyright 2023 dreamgaussian), including the rights to use, copy, modify, merge, publish, distribute, sublicense, and sell. The design docs are therefore wrong to call it "research code" with "no commercial statement verified" and "prototyping only until checked" (tool_guides.md lines 637 and 752).

Exact replacement wording for line 637: "Licence: MIT (repo LICENSE, copyright 2023 dreamgaussian). Commercial use of the DreamGaussian code itself is permitted. The remaining check is its gaussian-splatting-derived dependency (diff-gaussian-rasterization), which descends from INRIA's non-commercial research-licensed code, so confirm that dependency's terms before shipping a pipeline built on it."

Exact replacement wording for line 752: "DreamGaussian's own code is MIT; the open item is the gaussian-splatting dependency's terms, not the tool itself."

## 7. FTL Hyperspace licence: STILL UNVERIFIED

Tried: the FTL-Hyperspace repo wiki (Building on Windows, Contributing to Hyperspace) and three targeted licence searches with different phrasings. No LICENSE file, licence statement, or licence header surfaced anywhere. The repo is real and active (clone at github.com/FTL-Hyperspace/FTL-Hyperspace, build scripts in buildscripts/windows, output Hyperspace.dll), but its licence terms are simply not found in this pass. It is possible the repo carries no licence file at all; confirming that needs a listing of the repo root, which search did not provide. Do not assert GPL, MIT, or any other licence for Hyperspace.

## 8. ESA imagery and audio terms: VERIFIED (imagery); audio still open

Primary source opened: https://photolibrary.esa.int/terms-and-conditions/

Imagery terms, verbatim in substance: the ESA Website provides images and videos for education, editorial, and information purposes only; all other uses (for example commercial ones) are excluded and require a specific licence. Clause (v): images or videos "shall not be used for a commercial purpose, such as but not limited to, entertainment, advertisement, merchandising, etc. A commercial use requires a separate written authorisation by ESA." Some items are licensed under CC BY-SA 3.0 IGO and must be used under that licence. No use may imply ESA endorsement, and non-ESA copyright material needs its holder's separate written approval.

Replacement wording for the field guide: "ESA imagery is not free to ship commercially. Default ESA images and videos are education, editorial, and information only; commercial use needs a separate written authorisation from ESA. Only items explicitly marked CC BY-SA 3.0 IGO may be used under that licence's terms."

Audio: no ESA audio terms page was found. The photolibrary terms cover images and videos only, so the design docs' "ESA audio terms unverified" flag stays open. Do not cite the imagery terms for audio.

## 9. Materialize: VERIFIED

Primary source: Bounding Box Software's own FAQ, quoted in the jMonkeyEngine forum thread that reproduces it: "What's the license, how am I allowed to use Materialize? GNU General Public License v3. Use it for whatever you want."

The same thread carries the standard FSF position that GPL does not extend to the output of a program unless the output contains parts of the original software or calls its APIs. So the conclusion is: Materialize itself is GPLv3, and textures generated with it are safe to ship; only embedding Materialize code in the game would trigger GPL obligations. This closes the field guide gap ("licence page via third-party walkthrough only").

## 10. Babylon.js DefaultRenderingPipeline, TAA, and tone mapping: CORRECTED

This item overturns a load-bearing claim in graphics_craft.md, so it is stated plainly.

The doc says (line 30): "Babylon's default pipeline offers MSAA and FXAA, not a built in TAA pass, so do not plan around TAA." And (line 108): "Babylon has no built in TAA pass in the default pipeline as far as the opened sources show; if a TAA post-process exists in a newer version, it was not found here."

That is now wrong in its broad form. Babylon ships a TAARenderingPipeline as a separate rendering pipeline. Evidence: the official Babylon forum thread "TAA Rendering Pipeline Not Working" (September 2025) reports it broke in 8.24.1 with a MultiRenderTarget and was fixed by PR; it documents the properties reprojectHistory, clampHistory, and disableOnCameraMove, and the rule that TAA should be created before any other post-process (or after an edge post-process with history reprojection and clamping enabled). TAA exists; it is simply not inside DefaultRenderingPipeline.

Exact replacement wording for line 30: "Babylon ships a TAARenderingPipeline, but it is a separate pipeline, not part of DefaultRenderingPipeline. The default pipeline offers MSAA (pipeline.samples) and FXAA (pipeline.fxaaEnabled) only. If TAA is wanted, create the TAA pipeline before other post-processes, or set reprojectHistory and clampHistory to tame ghosting. On a phone GPU, MSAA or FXAA remains the right default."

Exact replacement wording for line 108: "Babylon has a built-in TAA rendering pipeline (TAARenderingPipeline), separate from DefaultRenderingPipeline; the earlier 'not found' note is superseded."

Two parts of the same item are VERIFIED and need no change: the tone mapping constants are BABYLON.ImageProcessingConfiguration.TONEMAPPING_ACES and TONEMAPPING_STANDARD (confirmed by a Babylon team answer on the official forum; ACES maps to value 1), and the HDR and AA trap is confirmed by a Babylon team explanation (with hdr=true the pipeline renders offscreen and canvas AA stops applying until pipeline.samples is set for MSAA). One caveat remains: the current DefaultRenderingPipeline doc page itself was still not opened in this pass (search returned the deprecated standard pipeline page), so the trap rests on official forum answers rather than the doc page.

## 11. Blender addon pricing: CORRECTED

The design docs' gap note (tool_guides.md line 184) is now fully closable. Vendor prices, all current as of this pass:

- TexTools: free. GitHub (original savage-studio repo; maintained fork SavMartin/TexTools-Blender, also cited as franMarz/TexTools-Blender). Free UV and texturing toolkit, 14-plus bake modes. The doc's "GitHub URL from search results, not an opened repo page" caveat can be dropped for the free status; the repo pages confirm it.
- UVPackmaster 4: $55 single user, $199 studio 2 to 5 users, $349 studio 6 to 10 users, on Superhive (formerly Blender Market). This supersedes the doc's "about $39 and up" roundup figure and kills the $2 Gumroad figure as stale. The addon code is GPL; the packing engine is under its own EULA.
- SimpleBake: $20 on Superhive. This closes the doc's "price not confirmed" gap.
- Zen UV: the Zen Bundle (all four Zen addons) is $49 on the vendor Gumroad page (sergeytyapkin.gumroad.com); Zen UV 5 standalone is about $39 per a current roundup. Zen UV 3 support has ended; Zen UV 5 is the current generation. This closes the doc's "price not confirmed" gap.
- Hard Ops plus Boxcutter Ultimate Bundle: $38 on Superhive. This replaces the doc's "about $20 each, third-party price table" with a vendor-listed bundle price.
- DECALmachine: $54.99 on Superhive and on the vendor Gumroad page (machin3.gumroad.com). This replaces the doc's "about $50, third-party price table" with a vendor price.

Exact replacement wording for tool_guides.md line 142: "UVPackmaster 4: $55 single user on Superhive (studio tiers $199 and $349); free lite version exists with limits." For line 143: "Zen UV 5: about $39 standalone; Zen Bundle (all four Zen addons) $49 on Gumroad." For line 145: "Hard Ops plus Boxcutter Ultimate Bundle: $38 on Superhive." For line 147: "DECALmachine: $54.99 on Superhive and Gumroad." For line 184, delete the price caveats for these six addons; the remaining caveats (old BlenderArtists threads, version-sensitive details) stand.

## 12. Effekseer to web and Babylon: VERIFIED

Primary sources: the EffekseerForWebGL repo (effekseer org), read via its repo mirror, and the official Effekseer tool documentation at https://effekseer.github.io/Help_Tool/en/ToolReference/index.html.

Confirmed: EffekseerForWebGL is a real WASM build. The integration pattern is load effekseer.min.js and effekseer.wasm, call initRuntime, create a context, init it with the WebGL context, load effects with loadEffect, play them, and call update then draw each frame. It shares the host WebGL context and saves and restores WebGL state (VAO, VBO, IBO, texture bindings, shader program) to avoid conflicts. The documented integration pattern is for Three.js (shared context, Effekseer renders after Three.js, camera matrices synchronized). No official Babylon plugin was found anywhere, confirming the design docs' claim. A Babylon integration would follow the same shared-context pattern as the Three.js one; it is not a shipped plugin. The official tool docs also confirm CLI batch conversion: .efkproj files convert to .efk without the GUI (the -cui flag), which supports the batch pipeline in the glue doc.

The glue doc's gap narrows but does not fully close: the WebGL details were confirmed against repo-derived documentation rather than the repo's own docs pages directly. The "no official Babylon plugin" claim itself is confirmed.

## 13. Babylon KTX2 transcoder self-hosting: VERIFIED

Primary sources: official Babylon forum answers (Babylon team) and the webcodingcenter KTX2 guide that mirrors the official mechanism.

Confirmed: Babylon loads .ktx2 natively; by default the transcoder comes from Babylon's CDN. Self-hosting is done by setting KhronosTextureContainer2.URLConfig before loading (jsDecoderModule, wasmUASTCToASTC, wasmUASTCToBC7, jsMSCTranscoder, wasmMSCTranscoder, wasmZSTDDecoder), as shown in a Babylon team answer. The modern route is the @babylonjs/ktx2decoder npm package, introduced specifically so the WASM files and code can be hosted locally instead of on Babylon's CDN (official forum thread, April 2024). This replaces the design docs' caveat that "the absolute-path requirement rests on a forum thread": the mechanism is confirmed by Babylon team answers plus a dedicated local-hosting package. No doc change needed beyond dropping that caveat and naming the ktx2decoder package as the preferred route.

## 14. Luma Genie free tier and Rodin pricing: VERIFIED

Luma Genie: a vendor-page check dated September 2026 found the Luma pricing page documents no free tier and no trial terms at all; the only free-access language on the site is a "Try for free" button. Confirmed paid tiers: Plus $30 per month, Pro $90 per month, Ultra $300 per month (yearly $300, $900, $3000). The legacy free Dream Machine tier for older accounts is watermarked and non-commercial. This confirms the design docs' "undocumented on the pricing page" flag as a positive finding rather than a gap: the free tier terms are undocumented because the vendor page documents no free tier. Genie is also no longer a standalone product per the same vendor-page check.

Rodin: vendor page opened via search (https://rodin3ds.com/): Free $0 (free previews, basic generation, 10 private assets, direct credits $1.50 each), Creator $30 per month ($288 per year, about 60 models per month), Business $120 per month ($1,152 per year, about 416 models per month, complete API access, commercial licence), Enterprise custom. This closes the design docs' "Rodin pricing varies by reporting year" gap with current vendor figures. One sub-point stays open: Rodin free-tier commercial use is silent on the pricing page (a 2026 review flags it explicitly unverified), so do not assume free-tier outputs are commercially usable; paid plans state a commercial licence.

## 15. Starsector API documentation: VERIFIED (confirmed absence)

Two searches found no hosted official API javadoc. What exists instead: the API ships as the starfarer-api jar inside the game install (the community mod template references it from local libs), and the Fandom modding hub itself states "for current modding documentation please refer to the official Starsector forum." The design docs' statement therefore stands as written: no official javadoc surfaced; cite the official forum modding hub and the shipped jar, not a javadoc site.

## 16. Darkest Dungeon official modding guide: VERIFIED

Primary source: the Steam Community guides listing for Darkest Dungeon (app 262060) at https://steamcommunity.com/app/262060/guides/ lists "Darkest Dungeon - Modding Guide [Official]" by RedHookTyler, described as "Official modding guide by Red Hook Studios. Learn the basics of how to mod Darkest Dungeon!" This closes the field guide gap ("official Steam modding guide could not be opened directly"). The guide exists, is official, and is authored by Red Hook staff.

## 17. Naev art licences and Slay the Spire BaseMod licence: VERIFIED

Naev: project licence info (via the OSS listing of the project) states code under GNU GPLv3 and media under a mix of GPLv2, GPLv3, CC BY, CC BY-SA 3.0, and public domain. Naev has moved to Codeberg; the GitHub org is now a mirror. The design docs' caution is therefore confirmed as the correct posture: Naev art licences are per-asset and mixed, so any reuse needs per-asset checking, not a blanket CC assumption.

BaseMod: the licence is MIT (daviscook477/BaseMod, the Slay the Spire modding API and dev console). This closes the field guide gap ("BaseMod licence deliberately not named"). It is now named: MIT.

## 18. Iris shader loader and Lenny's Mod Loader: VERIFIED

Iris: the Iris repo README itself (github.com/IrisShaders/Iris) names the official site as https://irisshaders.dev and points to the developer docs in the repo. Note for the docs: irisshaders.net is the older domain, while irisshaders.org and iris-shaders.com are copycat and SEO domains, not the project. This closes the field guide gap ("Iris official site and repo not opened").

Lenny's Mod Loader (LML): an RDR2 tool by LMS, distributed through the rdr2mods.com tools page and Nexus Mods; no standalone official site was found beyond those listings, and current community guidance treats LML plus ScriptHook as the two required pieces for RDR2 modding. This closes the field guide gap ("LML download page not opened") with the honest form of the answer: the distribution pages are the official pages.

## 19. Rogue Trader blueprint format: VERIFIED (confirmed absence)

No Owlcat developer document describing the blueprint format was found. What exists is the community OwlcatModdingWiki beginner guide, which states: "Blueprints are provided in the blueprints.zip file in the game directory" and "a blueprint dump is pinned in #mod-dev-technical on Discord." Blueprint internals therefore remain inferred from mod behaviour, exactly as the field guide states. Per the task brief, absence is a finding, not a failure: the correct doc wording is that no Owlcat developer document describes the format, and the community wiki plus the shipped blueprints.zip dump are the sources.

## 20. Blender Lab MCP server: VERIFIED (with one licence caveat)

Primary source opened: https://www.blender.org/lab/mcp-server/

The official page confirms the security warning verbatim: "The MCP server will execute LLM generated code in Blender without any guards in place to protect your data from removal or being sent to a remote location. To keep your data safe it is recommended to use a virtual machine, or a system without access to sensitive information." It also confirms the install flow: a Blender add-on (drag and drop twice, first to add the Blender Lab repository, second to install the add-on) plus a separate MCP server process, with a .mcpb bundle for newer clients.

Blender version requirement: Blender 5.1 or newer, confirmed by three independent October 2026 comparisons (dev.to comparison with links checked 2026-10-06; strayspark comparison; termo.ai skill page), and by the v1.0.0 add-on release on projects.blender.org. This confirms the design docs' 5.1 requirement.

Licence caveat: GPL-3.0-or-later is reported by the strayspark comparison describing the project's own terms, but the official page fetched here does not itself state a licence. So the licence line remains single-secondary-sourced; the version requirement is fully confirmed. The PC's installed Blender version is still the open check from the design docs, unchanged by this sweep.

## Items for the next sweep

Only two items remain fully open: TripoSG's licence (item 5) and the FTL Hyperspace licence (item 7). Both need a repo root listing or a direct repo file read rather than more search; neither should be asserted from sibling projects. Three sub-points stay open inside otherwise verified items: ESA audio terms (item 8), Rodin free-tier commercial use (item 14), and the Blender Lab MCP licence line's primary source (item 20). The current DefaultRenderingPipeline doc page (item 10) is also still unopened, though its key claims now rest on official forum answers.
