# Voidsworn: Visual Expansion Research

Audience: Opus (coder) and Ryan (owner). Scope: implementation resources for the real in-game visuals of Voidsworn, a Babylon.js WebGL space tactics game in custom JavaScript, shipped as web files, that must perform on a mid-range Android phone (a Pixel is the reference device). Concept art already exists in this folder. This memo is about tools, asset sources, techniques, and engine alternatives that can actually be used.

House rules applied throughout: every entry names a verified URL, states its licence or cost in plain words, says exactly how it plugs into a Babylon.js browser game (or what a port would replace), and gives a phone-performance note. Anything paid, non-commercial, or not usable in a shipped game is flagged in place. No entry relies on a link that was not opened or returned by search during research on 2026-10-23.

The cinematic target is a major theme of this memo, not an appendix. Section 7 is devoted to it: what actually creates the Sins of a Solar Empire look and feel, and how each element is approximated in Babylon on a phone budget. Sections 3 and 7 together carry the detailed implementation sketches.

## Top 10 highest-leverage picks

1. **Material Maker (procedural PBR hull paneling).** Author tileable panel, metal, and emissive texture sets offline and drop them into PBRMaterial slots. Zero runtime cost beyond the textures themselves. Section 2.
2. **KTX2 texture compression via KTX-Software or gltfpack -tc.** The single biggest memory and load win on a phone. A 1K JPEG expands to about 5.6 MB of VRAM uncompressed; KTX2 keeps textures compressed on the GPU. Section 2 and Section 4.
3. **ambientCG and Poly Haven (CC0 PBR libraries).** Free, no attribution, commercial use allowed. Mine them for neutral metals, panels, and one downscaled environment HDRI for PBR reflections. Section 2.
4. **DefaultRenderingPipeline with HDR, bloom, and MSAA samples set.** One pipeline object gives bloom, FXAA, image processing, vignette, and colour grading. This is the backbone of the cinematic look. Sections 3 and 7.
5. **Per-region colour grading LUTs (.3dl files).** Six tiny files, one per faction region, swapped on region entry. Nearly free at runtime, large identity payoff. Sections 3 and 5.
6. **Kenney Particle Pack sprites in one atlas, driving Babylon CPU and GPU particle systems.** CC0 sprites for muzzle flash, shield hits, explosions, and engine glow. CPU systems for logic-controlled bursts, GPU systems for continuous glow and dust. Section 3.
7. **GlowLayer as the selective alternative to full bloom.** Cheaper glow for engines and weapons when full-screen bloom is too expensive on the Pixel. Gate it by device tier. Section 3.
8. **gltfpack (meshoptimizer) simplification plus instancing.** Compression alone does not raise framerate; simplification and draw-call reduction do. Use -si for LOD ratios and -mi for repeated parts. Section 4.
9. **Layered backgrounds: SpaceScape or NASA/ESA plates plus a procedural starfield layer plus parallax planes.** Bake skyboxes offline at 1024 per face, keep plates under the 40 percent luminance readability cap from the art direction doc. Sections 1 and 7.
10. **Hybrid route: stay on Babylon, add a WebGPU engine path where available (with the port caveat attached).** Babylon ships a WebGPUEngine beside its WebGL engine, with compute shaders, while the same scene code runs on both. This earns a top-10 slot because it raises the effects ceiling (compute particles, snapshot rendering) without a rewrite. Caveat: the engine choice is made before the scene exists, a WebGPU scene cannot be swapped to WebGL afterwards, and a WebGL fallback path must be maintained and tested. Verdict and detail in Section 6.6. No full engine port earns a top-10 slot for this game today; Godot 4 is the strongest alternative and is rated worth it later, not now (Section 6.1).

## 1. Background sources

### 1.1 NASA Image and Video Library
- URL: https://images.nasa.gov ; usage terms: https://www.nasa.gov/nasa-brand-center/images-and-media/
- Licence in plain words: NASA content generally is not subject to US copyright and may be used for educational or informational purposes, including computer graphical simulations and web pages. NASA should be acknowledged as the source. Use must not imply NASA endorsement.
- Flags: the NASA insignia, logotype, and seal are NOT public domain and may not be used. Some material hosted on NASA sites is third-party copyrighted, is marked as such, and conveys no rights. Check each item before use.
- Babylon plug-in: download a nebula or planetary image, convert it to six cube faces or use it as an equirectangular source for a CubeTexture, following the Babylon skybox workflow in Section 5.2. The library API at https://images-api.nasa.gov supports search and asset endpoints if automated harvesting is ever wanted.
- Phone note: asset-time only. Bake at 1024 per face and compress to KTX2. Never ship the multi-megabyte originals.

### 1.2 ESA/Hubble images
- URL: https://www.esa.int/ESA_Multimedia/Terms_and_conditions_of_use_of_images_and_videos_available_on_the_esa_website/
- Licence in plain words: individual ESA/Hubble images commonly carry CC BY 4.0 (a checked example, the ESA Science page for NGC 3344, states "Copyright: ESA/Hubble, NASA, CC BY 4.0"). CC BY 4.0 allows commercial use with clear, visible credit. 
- Flags: the ESA site as a whole is NOT free. ESA general terms state some images are CC BY-SA 3.0 IGO (share-alike, which can complicate a shipped game) and that commercial use of other ESA website images requires separate written authorisation. Rule: use only items whose own page states a CC licence, record the credit line in the asset inventory, and skip anything share-alike or unlabelled.
- Babylon plug-in: same plate and skybox workflow as NASA.
- Phone note: same as NASA. Bake small, compress, credit in a credits screen.

### 1.3 SpaceScape (skybox generator)
- URL: https://github.com/petrocket/spacescape
- Licence in plain words: the repository README states the MIT License, copyright 2010 Alex Peterson. MIT allows commercial use of the tool. Generated skyboxes are tool output; the README licence covers the code, so treat output as yours to use, which is the normal reading for a generator of this kind.
- What it does: creates seamless space skyboxes (six cube faces) with point stars, billboard stars, and noise nebula layers. Version 0.5 added HDR/EXR export (per its SourceForge wiki and the author site, found in search results).
- Babylon plug-in: generate a skybox per region offline, export six faces, load with CubeTexture and a skybox mesh (Section 5.2), or feed the faces into the layered background stack in Section 7.5.
- Phone note: the build is CMake with OGRE plus Qt5 and the repo shows 0 releases, so expect to build from source or find a binary elsewhere. That friction is one-time and offline. Ship faces at 1024, KTX2 compressed.
- Flag: build friction only. Not paid.

### 1.4 Kenney Skyboxes: Space (OpenGameArt)
- URL: https://opengameart.org/content/skyboxes-space
- Licence in plain words: CC0 (Kenney assets are CC0). The page requests credit to Kenney.nl but states it is not mandatory.
- What it carries: 5 skyboxes in panoramic spherical format, download kenney_skyboxes-space.zip, 7.9 MB.
- Babylon plug-in: convert each panorama to a cubemap (Babylon docs link a GPU-accelerated equirectangular to cubemap converter from the skybox page) or use the layered plate approach in Section 7.5.
- Phone note: panoramas at 2048 wide are fine as sources; bake cube faces down to 1024 and compress.

### 1.5 Screaming Brain Studios: Planet Surface Skyboxes
- URL: https://screamingbrainstudios.itch.io/planet-surface-skyboxes
- Licence in plain words: released under Public Domain (CC0), commercial use allowed.
- What it carries: 64 planet surface skyboxes (32 cubemap plus 32 panorama). Cubemap frames are 512x512 assembled into 2048x1536 cross images; panoramas are 2048x1024.
- Babylon plug-in: best fit is planet-surface boards (a battle fought in low orbit or over a surface horizon), not deep-space plates. Slice cross images into six faces for CubeTexture.
- Phone note: 512 faces are already phone-sized. Upscaling them would waste memory; use as is.

### 1.6 OpenGameArt in general (standing warning)
- URL: https://opengameart.org
- Licence in plain words: mixed per upload (CC0, CC-BY, CC-BY-SA, GPL, OGA-BY all appear). A free download is not automatically shippable.
- Rule: filter per file, record the licence in the asset inventory, avoid CC-BY-SA and GPL assets for a shipped game unless the share-alike consequence is accepted deliberately.

### 1.7 Flagged paid background packs (not needed)
- Deep Space HDR Skyboxes Vol. 2 on itch.io at $3.99 and NebulaKit Skyboxes Vol. 1 at $5 (one free Deep Field sky as a trial) were found in earlier research. Flag: paid. Given Sections 1.1 to 1.5, neither is needed.

## 2. Texture and material sources

### 2.1 ambientCG
- URL: https://ambientcg.com
- Licence in plain words: CC0. No attribution required. Commercial use allowed.
- What it carries: over 2,000 PBR materials, over 420 HDRIs, plus 3D assets. JPG/PNG map sets, EXR HDRIs, up to 8K. A documented API exists and needs no key (per the ambientCG listings and a secondary guide at app.cinevva.com, found in search results).
- Hull-relevant use: mine the metal, panel, and painted-metal families. Download at 1K, pack channels (roughness, metalness, AO into separate colour channels of one texture) rather than shipping three greyscale files.
- Babylon plug-in: maps go directly into PBRMaterial slots (baseColor, normal via bumpTexture, metallic/roughness packed texture, ambient occlusion).
- Phone note: never ship 8K sets. 1K per hull family, KTX2 compressed (Section 2.5).

### 2.2 Poly Haven
- URL: https://polyhaven.com ; licence page: https://polyhaven.com/license
- Licence in plain words: all assets CC0, described on its licence page as effectively public domain. Commercial use OK, no credit required, redistribution allowed. Free keyless API.
- What it carries: over 850 PBR textures, over 990 HDRIs, over 520 models, 1K to 8K (HDRIs to 16K), with complete map sets (diffuse, normal, roughness, displacement, AO).
- Hull-relevant use: one neutral space or studio HDRI, downscaled and converted to a Babylon environment texture (.env) for PBR reflections on hulls, plus a small set of metal and panel textures. Environment lighting is what makes PBR hulls read as metal instead of plastic.
- Babylon plug-in: scene.environmentTexture from the converted .env; textures into PBRMaterial as above.
- Phone note: downscale the HDRI hard before conversion. A large HDRI wastes memory for a background the player barely sees in reflections.

### 2.3 Material Maker (RodZill4)
- URL: https://rodzilla.itch.io/material-maker ; docs: https://rodzill4.github.io/material-maker/doc/intro.html
- Licence in plain words: MIT License (per its GitHub README, found in search results). Free on itch.io, pay what you want, $0 allowed. Version 1.6 is current.
- What it does: Godot-based procedural texture authoring and 3D painting, about 200 nodes. Exports static PBR texture sets (albedo, metallic, roughness, emission, normal, depth).
- Why it is pick number 1: Voidsworn needs authored, tileable hull paneling in six faction identities, not generic photographed metal. Material Maker graphs can be parameterised per faction (panel density, greeble scale, emissive window and strip colours from FAC3D) and re-exported, which no download library gives.
- Babylon plug-in: exported PNG sets drop straight into PBRMaterial slots. Export at 1K, pack channels, KTX2 compress.
- Phone note: offline tool, zero phone cost. The only phone decision is output resolution.

### 2.4 Laigter (azagaya)
- URL: https://azagaya.itch.io/laigter ; source: https://github.com/azagaya/laigter
- Licence in plain words, with a flag: the itch.io page states binaries are now PAID while the source remains open on GitHub (Qt build). Output maps are your own work. Flag: do not budget this as free unless building from source.
- What it does: generates normal, specular, parallax, and ambient occlusion maps from 2D images, with real-time preview, a tileable mode, and a CLI for batch processing (per itch comments and DeepWiki, found in search results).
- Hull-relevant use: turn flat faction decals, greeble plates, and panel line art into lit detail (normal plus AO) without modelling the relief.
- Babylon plug-in: generated maps into PBRMaterial bumpTexture and ambientTexture slots; height output feeds parallax (Section 5.1).
- Phone note: offline tool, zero runtime cost.

### 2.5 KTX2 and Basis Universal (texture compression pipeline)
- URLs: https://github.khronos.org/KTX-Software/ktxtools/ktx_create.html (encoder commands) and https://binomialllc.github.io/basis_universal (Basis Universal, encoder library Apache 2.0)
- Licence in plain words: KTX-Software tools and the Basis encoder are open source and free to use, including commercially.
- How it works: Basis data stored in KTX2 is transcoded at load to the format the GPU supports. ETC1S is tiny but blocky; UASTC is larger and near-lossless. Reference numbers from the Babylon KTX2 documentation coverage (webcodingcenter.com, found in search results): a 1K JPEG expands to about 5.6 MB VRAM uncompressed, while an 86,050-byte PNG became 12,398 bytes as ETC1S and 37,468 bytes as UASTC.
- Babylon plug-in: BABYLON.Texture accepts .ktx2 URLs directly. Babylon fetches the transcoder from its CDN by default; KhronosTextureContainer2.URLConfig can relocate it, which matters for a self-hosted or offline build. Encode with `ktx create --encode basis-lz` or `--encode uastc`, or via gltfpack -tc (Section 4.1).
- Phone note: this is the highest-value pipeline step in the memo. Textures stay compressed in VRAM, which is the difference between a 1K texture set per faction being affordable or not.

### 2.6 Flagged: FreePBR (not free for a shipped commercial game)
- Finding: a guide found in search results on 2026-10-23 (app.cinevva.com) states FreePBR downloads are free for personal use and commercial use requires a one-time payment ($16 per that guide). Flag: keep it out of the pipeline unless Ryan chooses to pay. Sections 2.1 and 2.2 cover the same need at CC0.

## 3. Effects resources

This section is deliberately detailed. Each Babylon technique includes an implementation sketch (passes, textures, properties) and a phone cost, so a coder can start from it.

### 3.1 Kenney Particle Pack (sprite source)
- URL: https://kenney.nl/assets/particle-pack
- Licence in plain words: CC0. Commercial use allowed, no attribution required.
- What it carries: 80 sprites at 512x512 for particles, light cookies, and shaders.
- Babylon plug-in: use chosen sprites as the particleTexture for Babylon ParticleSystem and GPUParticleSystem. Pack the chosen sprites into one atlas so each system needs one texture.
- Phone note: 512 sprites are sources, not shipping size. Downscale atlas cells to 128 or 256 for phone builds.

### 3.2 Babylon CPU ParticleSystem (logic-controlled bursts)
- Source basis: Babylon particles documentation coverage (webcodingcenter.com, found in search results).
- Behaviour: JavaScript-updated pool of camera-facing quads, one draw call per system. Pool capacity should be sized at emit rate times lifetime; a full pool stops emitting.
- Use for: muzzle flash, shield hit sparks, explosions with sub-emitters, any burst the game logic must start, stop, and aim.
- Implementation sketch: one shared atlas texture (Section 3.1); per effect, a small pool created once and reused (never allocate per shot); set emitRate to 0 when idle and burst via manualEmitCount; blend mode additive for energy, standard for smoke and debris; cap concurrent active systems (a working phone budget is 6 to 10 small systems).
- Phone note: CPU cost scales with live particle count, not pool size. Keep bursts in the low hundreds of live particles. Overdraw (large soft sprites overlapping) costs more than count; keep sprites small on screen.

### 3.3 Babylon GPUParticleSystem (continuous effects)
- Source basis: Babylon forum threads on GPU particles (forum.babylonjs.com, found in search results).
- Behaviour: simulation runs on the GPU with no CPU oversight. Dead particles recycle immediately into new ones. manualEmitCount exists but needs a stop() workaround for clean one-shot bursts. Per-system cost is dominated by fragment overdraw.
- Use for: engine glow halos, nebula dust, drive trails with soft sprites, ambient battlefield embers. Anything continuous and fire-and-forget.
- Implementation sketch: one GPU system per continuous effect class, shared across ships where colour can be set per system instance; small sprite size with falloff texture; no per-frame JavaScript touching the system.
- Phone note: prefer GPU systems for continuous effects precisely because they cost no CPU, but watch overdraw. A screen-filling nebula dust layer at full resolution will hurt more than the ships do. Render dust at half resolution if it is ever added as a post layer.

### 3.4 Babylon Solid Particle System, SPS (real 3D debris and fields)
- Source basis: Babylon SPS documentation mirror (grideasy.github.io, found in search results).
- Behaviour: one mesh, one material and texture, one draw call for the whole system. An immutable SPS (setParticles called once, outside the render loop) is explicitly recommended for static fields such as distant buildings, asteroids, and scraps.
- Use for: asteroid fields, wreck fields, debris that must catch light and occlude correctly, which sprites cannot do.
- Implementation sketch: build one SPS per field with a low-poly rock or wreck geometry (100 to 300 triangles), instance count in the low hundreds, immutable where the field is static; a second small mutable SPS for fresh battle debris that settles and is then frozen.
- Phone note: avoid per-frame setParticles on the phone. Immutable SPS is nearly free after build; mutable SPS re-uploads buffers.

### 3.5 Babylon procedural textures (zero-download effects)
- Source basis: Babylon procedural textures documentation coverage (webcodingcenter.com, found in search results).
- What exists: the @babylonjs/procedural-textures library adds wood, marble, brick, grass, road, fire, cloud, starfield, and Perlin noise. Core Babylon has NoiseProceduralTexture and custom ProceduralTexture via fragment shader. Textures are drawn by shader into a render target, are tiny on the wire, and can animate.
- Use for: StarfieldProceduralTexture as an animated star layer behind plates (Section 7.5); fire and noise textures for engine glow and explosion cores; cloud noise for nebula tint layers.
- Implementation sketch: generate once at load at 512, cache the texture, reuse across materials. Animate via texture animation properties or a time uniform in a custom procedural shader, not by regenerating.
- Phone note: generation is a one-time GPU cost at load. Runtime cost is that of a normal texture sample. Do not regenerate per frame.

### 3.6 Node Material and the Node Material Editor, NME (authored effects)
- URL: https://doc.babylonjs.com/features/featuresDeepDive/materials/node_material/
- Licence in plain words: part of Babylon.js, Apache License 2.0. Free, commercial use allowed.
- What it does: node materials assemble vertex and pixel shader behaviour from blocks, can reuse engine lighting, fog, and bones blocks, and the docs tree includes node material particle shaders and procedural textures. Graphs can be authored visually in the NME, saved as JSON, and loaded at runtime.
- Runtime loading, verified: NodeMaterial.ParseFromSnippetAsync(id, scene) fetches a graph from the Babylon snippet server by immutable id (example id 2F999G in the docs coverage), and ParseFromFileAsync loads JSON you host yourself (webcodingcenter.com NME coverage, found in search results). Measured snippet round trips in that coverage ran 0.36 to 1.3 seconds, so snippets are for prototyping; production should self-host the JSON or build graphs in code.
- Implementation sketches:
  - Shield hit ripple: a node material on a slightly inflated hull shell (or a sphere segment for capital ships). Inputs: hit position as a Vector3 uniform, hit time. Graph: distance from fragment world position to hit position, minus (time since hit times speed), passed through a smoothstep band, multiplied by fresnel, output as emissive in the shield colour (cyan, per the art direction colour law). Fade the band alpha out over about 0.6 seconds. One material instance per ship, two uniforms updated per hit.
  - Engine glow falloff: fresnel-driven emissive on a cone or disc at each exhaust, intensity uniform tied to throttle or movement state. No texture needed.
  - Trail ribbons: the Babylon trail effect walkthrough (babylonjs.medium.com, found in search results) builds trails in the NME by sampling a curve texture twice with a small V offset (-0.001) to derive direction, computing a camera-facing bitangent from the cross product of view direction and curve direction, and shaping alpha with a sine across width times a sine along length. That graph is a complete starting point for projectile and missile trails (Section 7.4).
- Phone note: node materials compile to the same shaders as hand-written ones. Cost is the fragment work you build. Keep ripple and glow graphs short; avoid per-pixel texture samples beyond one or two.

### 3.7 ShaderMaterial (full custom GLSL or WGSL)
- URL: https://doc.babylonjs.com/features/featuresDeepDive/materials/shaders/shaderMaterial/
- Licence in plain words: part of Babylon.js, Apache 2.0.
- What it does, verified from the docs page opened in research: ShaderMaterial passes data from the scene to your vertex and fragment shaders and applies the result to any mesh. Shader code can be supplied via the ShadersStore, script elements, source strings, or external .vertex.fx and .fragment.fx files. Attributes and uniforms are declared in option arrays; any attribute used must be listed, and worldViewProjection must be declared if used. Texture uniforms go in the samplers array and are set with setTexture; scalars and vectors with setFloat and setVector3.
- Use for: shockwave rings (Section 7.3), charge-up distortions, and any effect the node system expresses awkwardly.
- Image processing warning, verified: if an ImageProcessingPostProcess or DefaultRenderingPipeline is active, a custom shader outputting gl_FragColor will look brighter than intended unless the shader includes the imageProcessingCompatibility include or the material toggles the IMAGEPROCESSINGPOSTPROCESS define (docs page: https://doc.babylonjs.com/features/featuresDeepDive/materials/shaders/image_processing). Budget ten minutes for this the first time a custom shader meets the pipeline, because everyone hits it once.
- Phone note: a fullscreen ShaderMaterial post effect costs a full-screen pass. Confine custom shaders to meshes (rings, shells, cones) wherever possible.

### 3.8 DefaultRenderingPipeline (the post backbone)
- URL: https://doc.babylonjs.com/features/featuresDeepDive/postProcesses/defaultRenderingPipeline/
- Licence in plain words: part of Babylon.js, Apache 2.0.
- Verified feature set, from the docs page opened in research: constructed as new DefaultRenderingPipeline(name, hdr, scene, cameras). Properties include samples (MSAA sample count; 1 by default), imageProcessing (contrast, exposure, colour grading via a .3dl ColorGradingTexture or a PNG, and ColorCurves with global, highlights, midtones, and shadows density, exposure, hue, and saturation), bloom (bloomEnabled, bloomKernel 64, bloomScale 0.5, bloomThreshold 0.9, bloomWeight 0.15), chromaticAberration (aberrationAmount 30 by default), depthOfField (fStop 1.4, focalLength 50, focusDistance 2000, lensSize 50), fxaa, glowLayer (blurKernelSize 16, intensity 1), grain (intensity 30, animated flag), and sharpen (edgeAmount 0.3, colorAmount 1).
- Phone-critical note, verified in forum evidence during research: with HDR on, set pipeline.samples (for example 4) or edges suffer, because the HDR path renders into offscreen targets where default MSAA does not apply.
- Recommended phone configuration (starting point, to be tuned on the Pixel): HDR on, samples 4, bloom on with threshold about 0.85 and weight modest (the Sins look is bloom-heavy but phone fill rate is the constraint, Section 7.2), FXAA off when MSAA samples are on (paying for both is waste), grain off or very low and non-animated, sharpen low. Depth of field off during gameplay, on only for scripted camera moments (Section 7.2).
- Flag: the older StandardRenderingPipeline is deprecated and its own docs page says it is no longer maintained. Do not build on it.

### 3.9 GlowLayer and HighlightLayer
- Source basis: Babylon post-processing documentation coverage (webcodingcenter.com, found in search results).
- GlowLayer: renders the emissive colour and texture of chosen meshes into a blurred texture composited over the frame. Controls include intensity, blurKernelSize, addIncludedOnlyMesh, and customEmissiveColorSelector. Use it as selective glow (engines, weapon muzzles, capital ship windows) when full bloom is too costly.
- HighlightLayer: stencil-based outlines for selection. Useful for the selected ship and target brackets without UI sprites.
- Phone note: both still cost extra render targets. Gate GlowLayer by device tier; HighlightLayer on a single selected mesh is cheap.

### 3.10 LensRenderingPipeline (photographic lens effects)
- Source basis: Babylon lens effects documentation mirror (grideasy.github.io, "Using depth of field and other lens effects", found in search results).
- What it chains, verified: three post processes. First, chromatic aberration, shifting red, green, and blue channels slightly, stronger at the edges. Second, highlights enhancing, keeping only highlights for use by the depth-of-field blur. Third, depth of field, which also adds edge lens blur, lens distortion, depth-of-field blur from an optics equation, bokeh shapes in blurred areas, a grain effect (noise or a custom texture), and darkening of out-of-focus objects.
- Usage, verified: define a parameters object (edge_blur, chromatic_aberration, distortion, and related fields, each around 1.0 in the example) and construct new BABYLON.LensRenderingPipeline(name, parameters, scene, ratio, camera), or attach cameras afterwards via scene.postProcessRenderPipelineManager. Note the parameter change recorded in the Babylon changelog coverage: dof_focus_depth (range 0 to 1) is deprecated in favour of dof_focus_distance (range 0 to infinity).
- Use for: scripted cinematic moments only (boss arrival, Command use), where its cost is paid for a few seconds and the photographic feel is the point. Section 7.2 gives the shot recipes.
- Phone note: this is the most expensive pipeline in the memo. Never run it as the always-on gameplay pipeline on a phone. Swap it in for a cutscene-style beat, then swap back to the DefaultRenderingPipeline configuration.

### 3.11 Colour grading LUTs (.3dl) as a pipeline
- Source basis: the DefaultRenderingPipeline docs (Section 3.8) confirm colour grading via ColorGradingTexture with a .3dl file, and Babylon ships sample LUTs (LateSunset.3dl and HorrorBlue.3dl appear in forum and docs texture listings found in search results).
- Technique: author one LUT per faction region in an external editor (screenshot the game, grade it, export the .3dl), ship six tiny files, and swap imageProcessing.colorGradingTexture on region entry. Combined with ColorCurves for per-region hue shifts in highlights and shadows, this gives each faction's space a distinct grade without touching materials.
- Phone note: a LUT lookup is one texture sample in a pass that already exists. This is the cheapest identity lever in the entire memo.

### 3.12 Shader sources: what is actually usable (honest licence check)
- Babylon NME snippet server and self-hosted JSON: usable. Graphs you load are yours or shared by their authors through the snippet system; self-host for production (Section 3.6). Licence risk: low. Treat a stranger's snippet like sample code: read it before shipping it.
- Babylon community and forum shaders: usable with care. Forum code is posted to be reused, but there is no uniform licence. Prefer code from Babylon team members and the official docs, and rewrite rather than copy where the snippet is long.
- Shadertoy: FLAG, mostly NOT usable in a shipped commercial game. The common Shadertoy licence, visible in shader headers across the site and in the Wikibooks Shadertoy collection opened in research, is Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported. NonCommercial means exactly what it says, and ShareAlike would force the derivative shader out under the same terms. Individual authors can grant other terms, and some shaders state different licences in their headers, so the rule is: read the header, and unless it states a permissive licence or you have written permission, use Shadertoy for learning the technique only and write your own implementation. This applies directly to nebula and shockwave shaders, which are plentiful there and tempting.
- iq (Inigo Quilez) articles and similar technique write-ups: the techniques (raymarched nebulae, analytic shockwaves, palette functions) are ideas, not code to paste. Implement from the maths, in your own code, and there is no licence problem.

## 4. Ship geometry tooling

### 4.1 meshoptimizer and gltfpack
- URL: https://meshoptimizer.org/gltf/
- Licence in plain words: MIT License, stated on the page opened in research ("gltfpack is available to anybody free of charge, under the terms of MIT License"). Free, commercial use allowed.
- Verified capabilities, from that page: gltfpack optimises meshes for vertex fetch and transform cache, quantises geometry, merges meshes to reduce draw calls, and simplifies on request. Default output loads in Babylon.js 4.1+ (KHR_mesh_quantization). With -c it writes EXT_meshopt_compression files, which Babylon.js supports in 5.0+ without further setup. A -cf flag writes an uncompressed fallback. Texture compression via -tc writes KTX2 (KHR_texture_basisu). Useful flags: -cc (stronger compression, pair with gzip), -tc, -tw (WebP), -mi (mesh instancing), -si R (simplify to ratio R), -kn (keep named nodes), -km (keep materials), -ke (keep extras).
- The honest limit, verified on the glTF Transform EXTMeshoptCompression page (https://gltf-transform.dev/modules/extensions/classes/EXTMeshoptCompression): decompression happens before GPU upload, compression is lossy, and it does not improve runtime performance directly. Framerate improves from simplification (fewer vertices) and draw-call reduction, not from compression. Compress last, keep uncompressed originals.
- Babylon plug-in: this project already uses meshoptimizer. The additions worth adopting are -si LOD passes per hull class, -mi for repeated kit parts, and -tc so the KTX2 step (Section 2.5) happens in the same pass.
- Phone note: simplification ratios are the phone lever. A capital ship at full detail for the close camera, simplified to about 0.5 and 0.25 for mid and far, is the pattern.

### 4.2 glTF Transform (scripted pipeline)
- URL: https://gltf-transform.dev/modules/extensions/classes/EXTMeshoptCompression (extension docs; the CLI covers resize, webp, etc1s, uastc, and meshopt commands per search results)
- Licence in plain words: open source tooling, free to use. Check the repo licence at adoption time.
- Use for: a scripted, repeatable asset pipeline (import, resize textures, generate LODs, compress, emit a manifest) instead of manual gltfpack calls per hull. Pairs with the ship kit work order already in this design folder.
- Phone note: offline only.

### 4.3 SpaceshipGenerator (a1studmuffin)
- URL: https://github.com/a1studmuffin/SpaceshipGenerator
- Licence in plain words: MIT per the SourceForge mirror page found in earlier research. Free, commercial use allowed.
- What it does, verified via the GitHub API and raw README in search results: a Blender add-on that procedurally generates spaceships from a random seed. Box hull, horizontal symmetry, bevel modifier, randomised extrusion for front, rear, and asymmetry, faces categorised by orientation to place engines, antennae, turrets, and lights. Needs Blender 2.80+. Ships carry three PNG texture types (lighting, windows, engines).
- Use for: a study model for Voidsworn's own procedural kit parameters (its categorise-faces-then-place-features approach maps directly onto the ship kit grammar packs), and as a seed generator for background wreck silhouettes.
- Flag: not a source of final hero hulls. Its output reads generic next to the faction silhouette grammars in the art direction doc.
- Phone note: offline generator. Output needs simplification (Section 4.1) before it is phone-safe.

### 4.4 Blender plus Discombobulator (greeble workflow)
- URLs: https://www.blender.org/about/license/ and the Blender Manual page for Discombobulator (docs.blender.org)
- Licence in plain words: Blender's licence page states what you create with Blender is your sole property, free to use as you like, including commercially. The bundled Discombobulator add-on is listed in the manual as GPL and bundled with Blender; the models and maps you produce with it are your output, which is the standard and safe reading for add-on output.
- What Discombobulator does, per the manual: creates greeble objects from selected quad faces, with protrusion height and taper controls, repeat levels, and a Doodads mode that scatters your own mesh across the protrusions.
- Workflow: apply to simple hull lofts for panel relief, then bake the relief to normal maps (with Laigter or Blender baking) and simplify the mesh hard before export. The relief the player sees at distance is the normal map, not the geometry.
- Phone note: never ship raw Discombobulator geometry. Bake and simplify, always.

### 4.5 Flagged paid geometry tools (not needed)
- "Blender Spaceship Generator" on Superhive (formerly Blender Market) at $39.00 and a Procedural Spaceship Generator Blender file on Gumroad at $15+, both found in research. Flag: paid. Sections 4.3 and 4.4 cover the need for free.

## 5. Novel or unexplored approaches

### 5.1 Parallax depth on plates and hull textures
- URL: https://doc.babylonjs.com/features/featuresDeepDive/materials/using/parallaxMapping
- Verified facts, from the docs page opened in research: parallax mapping offsets texture UVs using a height map encoded in the alpha channel of the normal map. Babylon calls it very fast, "almost free" if bump mapping is already on. Parallax Occlusion Mapping samples the height map in a loop, looks better, and "there can be a performance hit". Properties: useParallax, useParallaxOcclusion, parallaxScaleBias (0.05 to 0.1 reasonable, up to 0.2 with occlusion).
- Application: plain parallax on hero hulls so panel relief shifts correctly as the camera orbits; occlusion only on the flagship or boss hull. For backgrounds, two or three large transparent nebula planes at different depths in front of the skybox give real parallax as the camera pans, which a flat plate cannot.
- Phone note: plain parallax is the cheap win. Occlusion is a per-pixel loop; ration it to one hull.

### 5.2 Skyboxes and domes (the loading workflow)
- URL: https://doc.babylonjs.com/features/featuresDeepDive/environment/skybox/
- Verified facts, from the docs page opened in research: CubeTexture loads six square power-of-two faces (1024x1024 recommended for efficiency) by appending _px, _nx, _py, _ny, _pz, _nz to a base URL. A CubeTexture can only be used as a reflection or refraction texture; a skybox applies it as reflectionTexture with coordinatesMode set to SKYBOX_MODE on a large box with backFaceCulling off, disableLighting on, and infiniteDistance set so the box follows the camera. scene.createDefaultSkybox(envTexture, true, 1000) is the one-line alternative. A single equirectangular image needs conversion to a cubemap, and the docs link a GPU-accelerated community converter. Ground projection (version 6.27.0+) can fake a ground from the skybox with BackgroundMaterial, which matters for planet-surface boards.
- Phone note: 1024 faces, KTX2. Six 1024 faces uncompressed are about 24 MB of VRAM; compressed, a fraction of that. This is why Section 2.5 comes first.

### 5.3 AI upscaling locally (Real-ESRGAN and Upscayl)
- URLs: https://github.com/upscayl/upscayl (GUI) and Real-ESRGAN coverage at cgchannel.com (found in search results)
- Licence in plain words: Real-ESRGAN is BSD 3-Clause, with compiled executables for Windows, Linux, and macOS. Upscayl is the free open-source GUI front end using Real-ESRGAN models via the ncnn Vulkan backend; its backend is AGPLv3, which matters only if redistributing the tool, not for images it produces. Its FAQ states a Vulkan-compatible GPU is required and most integrated GPUs and CPUs will not work.
- Application: Ryan's RTX 5080 qualifies. Upscale 512px concept plates and low-resolution texture sources at asset time, then downscale and compress for the game. Also useful for rescuing NASA plate crops that are slightly too small for a 1024 face.
- Phone note: asset-time only, zero phone cost.

### 5.4 Gaussian splatting and billboard-cluster nebulae
- URL: https://doc.babylonjs.com/features/featuresDeepDive/mesh/gaussianSplatting
- Verified facts, from the docs page opened in research: Babylon's GaussianSplattingMesh loads .splat and .PLY files through the standard loaders (the page also covers .spz and .SOG formats). Each splat is a semi-transparent ellipsoid projected onto a billboard. Parts can be combined into one container while maintaining a global sorting order, each part independently transformable, with a documented maximum part count the user is responsible for checking. Visibility per part interacts with density: a visibility of 0.1 can still look almost opaque if enough splats share a pixel. Picking falls back to bounding volumes or a GPU picker, since there is no triangle geometry. Debug plugins visualise projected splat size and per-pixel overdraw. Babylon 8 coverage (radiancefields.com, found in search results) adds that splat VRAM dropped from 64 to 32 bytes per splat and that the NME gained Gaussian splatting blocks.
- Verdict for Voidsworn: promising for one hero nebula cluster or a menu backdrop; risky for gameplay on a phone, because transparent overdraw is exactly the phone's weakest point and sorting cost grows with splat count. The practical alternative that delivers most of the look: billboard-cluster nebulae, a few dozen large soft sprites (Section 3.1 atlas, nebula puffs) placed in an SPS or sprite manager at varied depths and scales, tinted per region, with the procedural starfield behind them. Prototype the cluster first; reach for splats only if the cluster visibly fails.
- Phone note: if splats are trialled, trial them in the menu scene only, capped, with the overdraw debug plugin open.

### 5.5 Instanced debris and asteroid fields
- Source basis: Babylon forum threads on thin instances (forum.babylonjs.com, found in search results) document thinInstanceSetBuffer("matrix", ...) with per-instance colour buffers; static buffers are the fast path and are now the default, while dynamic buffers allow per-instance updates at a cost. A Babylon mobile-performance walkthrough (dev.to, found in search results) frames the numbers: one uncompressed 4096x4096 texture uses 64 MB of GPU memory, KTX2 cuts texture memory by about 75 percent, and thin instances handle thousands of identical objects with almost no CPU cost.
- Application: one rock geometry, thousands of thin instances with per-instance colour tint, static buffer, for belt fields that fill the background of a board. Combine with Section 3.4: SPS where debris needs to be lit and individual, thin instances where it needs to be numerous.
- Phone note: static thin instances are the cheapest large-count technique in Babylon. Keep the source geometry under a few hundred triangles.

### 5.6 Colour grading LUT pipeline (process, not just tech)
Covered as a technique in Section 3.11. The unexplored angle is process: build a small grading ritual (capture, grade in an external editor, export .3dl, name by region and faction, store with the background plate it was graded against) so new regions arrive with their grade included, the way they already arrive with a plate. Six regions, six LUTs, one swap on entry.

## 6. Beyond Babylon: engine routes compared

Framing for this whole section: Voidsworn today is an existing Babylon.js browser game, all content and logic in JavaScript, distributed as web files, played on phones including a Pixel. A port is therefore not a rendering upgrade; it is a rewrite of the game in a new language and toolchain, plus a new distribution story. Each route is judged on four points: what visual ceiling it raises and how, distribution reality for this game's audience, port cost in plain terms, and a verdict line.

### 6.1 Godot 4
- URLs: https://docs.godotengine.org/en/stable/about/faq.html ; web export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html ; Android export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html ; renderers overview: http://docs.godotengine.org/en/latest/tutorials/rendering/renderers.html
- Licence and cost, verified from the FAQ page opened in research: Godot is free and open source under the MIT License, free for any purpose including commercial, free to modify and redistribute. Documentation is CC BY 3.0. Cost: $0, forever, no royalties, no seats.
- What it unlocks visually: three renderers (renderers overview, found in search results). Forward+ is the most advanced, desktop only, using Vulkan, Direct3D 12, or Metal through the RenderingDevice backend, with clustered lighting, compute shaders, and RenderingDevice direct GPU access. Mobile is a reduced-feature renderer on the same modern APIs, suited to mobile and desktop. Compatibility is the least advanced, OpenGL-based, and is the web renderer. A renderer comparison (slicker.me, found in search results) itemises the gaps: SSAO and SSIL, screen-space reflections, and volumetric fog are Forward+ only; TAA is Forward+ only; GPU particles run on compute in Forward+ and Mobile, while in Compatibility GPUParticles fall back silently to CPU simulation (a Godot class reference note also confirms emit_particle is unsupported in Compatibility). In plain terms: on desktop and native Android, Godot 4 gives a modern Vulkan pipeline, a strong built-in particle system (GPUParticles3D with process materials, turbulence, trails, and sub-emitters), a visual shader editor, and good built-in post (glow, fog, adjustments). On the web, which is where Voidsworn's audience is, it gives the Compatibility renderer, which is the weakest of the three.
- Distribution reality for this game: web export requires WebAssembly and WebGL 2.0 and runs the Compatibility renderer only, because Forward+ and Mobile are designed around modern low-level APIs and Godot does not support WebGPU (web export docs, opened in research). C# projects cannot be exported to the web in Godot 4 at all (same docs, stated as an attention item; the FAQ repeats that C# support is currently missing on the web platform). Threaded web exports need SharedArrayBuffer, which requires cross-origin isolation headers (Cross-Origin-Opener-Policy: same-origin and Cross-Origin-Embedder-Policy: require-corp, per the docs' serving section) and blocks ads and third-party integrations on the hosting page; since 4.3 a single-threaded export is the default and preferred route, at some performance cost. The docs also state plainly that native Android exports will always perform better than the web export by a significant margin, and that the web export is WebAssembly rather than native code. Android export itself is well documented (OpenJDK 17, Android SDK platform and build tools 35, NDK r28b, Gradle builds for Play AAB files, per the Android page opened in research), so a native Android Godot build is a real option, but it is a different product from a web link: store listing, signing, and updates replace "send a URL".
- Port cost in plain terms: total rewrite. Officially supported languages are GDScript, C#, and C++ (FAQ). None of them is JavaScript, and there is no transpiler that carries a Babylon codebase across. All game logic (battle, campaign, AI, saves) is reimplemented in GDScript (the recommended, best-integrated option, Python-like) or C# (which then blocks the web export, the game's current channel). All Babylon scene code, materials, and effects are rebuilt as Godot scenes, nodes, and resources. Models and textures survive (glTF in, PNG and KTX2 out) and design documents survive; code does not. Realistic scale: this is a reimplementation of the whole game, measured in months of coder time, with the web version visually weaker (Compatibility renderer) than the native one.
- Phone note: native Android on the Mobile renderer is genuinely good and would likely outperform the current WebGL build. Web on a phone is the opposite: Compatibility renderer, single-threaded Wasm, CPU particles.
- **Verdict: worth it later.** Godot is the only full port that is free, credible, and phone-friendly (native Android), and if Voidsworn ever wants a store-shipped native app, this is the route. It does not earn that cost while the game is web-distributed and still changing fast, and its web renderer would be a visual step sideways or down from Babylon with a WebGPU path.

### 6.2 Unreal Engine 5
- URLs: licence: https://www.unrealengine.com/en-US/license ; pixel streaming pricing example: https://www.eagle3dstreaming.com/pricing ; pixel streaming cost and latency analysis: https://game-ace.com/blog/unreal-engine-pixel-streaming/ ; mobile fit analysis: https://game-ace.com/blog/unreal-engine-for-mobile-games/
- Licence and cost, verified from the licence page opened in research: free for game developers until a product passes $1 million USD in lifetime gross revenue; above that, a 5 percent royalty on revenue above the first $1 million (reducible to 3.5 percent with a same-time Epic Games Store launch; Epic Games Store revenue itself is royalty-free). Seat pricing ($1,850 per seat per year) applies to non-game commercial use over $1 million annual revenue, not to a shipped game. Source code access is included.
- What it unlocks visually: the highest ceiling in this section, on hardware that can run it. Lumen (fully dynamic global illumination and reflections, no lightmap baking, reacting to scene changes in real time), Nanite (virtualised geometry that streams film-quality source art without manual LOD or normal-bake pipelines), and Niagara (a deep, GPU-capable VFX system) are the three headline systems, summarised in the UE5 feature coverage found in search results (blog.truegeometry.com). For a space tactics game, the honest translation is: Lumen would make capital ships light each other and their own explosions, Nanite would end LOD authoring for hero hulls, and Niagara would raise every effect in Section 3 by a generation.
- Distribution reality for this game, and it is disqualifying on its own: there is no official web export. Epic dropped HTML5 support years ago and has not restored it (pixel streaming analysis, medium.com, found in search results). The shipped workaround is pixel streaming: the game runs on a cloud GPU and the browser receives video. Verified costs and latencies: a managed provider example (Eagle 3D Streaming, opened via search results) charges $0.10 per minute after a 300-minute monthly Core allowance, per concurrent stream capacity; a platform comparison (vagon.io) cites Arcware at about 10 euros a month plus about 0.15 euros per streaming minute, and self-hosting means paying AWS or Azure GPU time plus the engineering to run it. Latency baselines from the Game-Ace analysis: 70 to 140 ms same-region on AWS or GCP GPU instances, plus 40 to 120 ms cross-region. For a turn-based tactics game the latency is survivable; the per-minute, per-player hosting bill for a free web game is not, and every player needs a GPU slot, so audience size becomes a cost centre instead of a link. A third-party WebGPU RHI for UE5 was announced on the Epic forums in 2026 (forums.unrealengine.com, found in search results); it is a vendor tool, not an Epic export path, and is not a basis for planning.
- Mobile reality: UE5 does ship to Android and iOS natively (Vulkan on Android, Metal on iOS), but the mobile analyses found in search results are blunt: Nanite and Lumen were built for desktop and console GPUs and remain constrained on mobile, Nanite needs compute shaders and VRAM for its geometry cache (recent flagships only), Lumen's hardware ray tracing paths are unavailable on most mobile chips and the software fallback is heavy, and most mobile Unreal teams still bake lighting and use traditional LODs, shipping on the Mobile Forward renderer with feature gates for premium tiers (game-ace.com; dev.to mobile analysis). App sizes also run larger than equivalent Unity builds. In other words, on the Pixel, a UE5 port would mostly not be running the features that justified the port.
- Port cost in plain terms: total rewrite, the largest in this section. C++ or Blueprints; no JavaScript carry-over; a new asset pipeline (Unreal projects, materials, Niagara systems); new build, signing, and (for web) streaming infrastructure; and an engine whose editor and iteration loop are far heavier than a text editor and a browser refresh. Team-of-studios tooling applied to a solo-plus-AI project.
- **Verdict: not worth it.** Highest ceiling, wrong game. The web channel disappears, phone players get the cut-down feature set anyway, and the port cost is the largest on the list. Revisit only if Voidsworn becomes a native PC-first product.

### 6.3 three.js with WebGPU
- URLs: WebGPU renderer docs: https://threejs.org/docs/WebGPURenderer.html ; migration and compute coverage: https://www.utsubo.com/blog/webgpu-threejs-migration-guide ; version and ecosystem analysis: https://www.utsubo.com/blog/threejs-2026-what-changed
- Licence and cost, in plain words: three.js is open source under the MIT License and free for commercial use. Cost: $0.
- What it unlocks visually: the same language and the same web channel, with a newer GPU API. WebGPURenderer (entry point three/webgpu since r171, November 2024, per the Utsubo analysis) brings compute shaders to JavaScript: the migration guide's worked example simulates 200,000 particles entirely on the GPU using TSL (Three Shader Language), with instancedArray GPU-resident buffers, renderer.compute() passes, and a SpriteNodeMaterial reading the simulated buffer directly. TSL compiles one shader graph to WGSL or GLSL for the WebGL 2 fallback, which WebGPURenderer provides automatically for browsers without WebGPU (confirmed in the three.js forum thread found in search results: the renderer does not require WebGPU support, but compute features must be avoided if the fallback is required). The same analysis is honest that WebGPU is not faster everywhere, with forum reports of WebGPURenderer running slower than WebGLRenderer on some scenes, so migration for speed alone needs profiling.
- What it does not unlock: Babylon's built-in game tooling. three.js is a renderer library, not an engine with Babylon's particle systems, post pipelines, GUI, and loaders integrated. Moving means reimplementing or reassembling those layers (community post-processing, custom particle systems in TSL) while gaining compute.
- Distribution reality: identical to today. Static web files, no store, no streaming, no per-player cost. WebGPU availability on Android Chrome is now broad, and the WebGL 2 fallback covers the rest, at the price of maintaining two capability tiers.
- Port cost in plain terms: a rendering-layer rewrite, not a game rewrite. Game logic, data, AI, campaign, and saves are plain JavaScript and carry over with discipline; scene construction, materials, effects, and post are Babylon API throughout and must be rebuilt against three.js APIs. Smaller than Godot or Unreal by a wide margin, still measured in weeks, and it trades a mature integrated toolchain for a larger but more fragmented ecosystem (the npm gap is real: about 12.2 million weekly downloads for three versus about 315k for @babylonjs/core in the September 2026 week cited by Utsubo, which buys tutorials and answers, not features).
- Phone note: WebGPU on a Pixel-class Android GPU is the same hardware Babylon's WebGPU engine targets (Section 6.6). The compute win is real for particles and fields; the fallback tier is WebGL 2, same as today.
- **Verdict: not worth it now, credible later.** It is the only port that keeps the language, the channel, and the logic. But Section 6.6 gets most of the same WebGPU benefit inside Babylon without the rendering-layer rewrite, so three.js only wins if Babylon's WebGPU path stalls or its tooling stops fitting.

### 6.4 Unity (WebGL and Android)
- URLs: pricing analyses: https://blog.promise.legal/game-engine-license-agreements-unreal-unity-godot/ and https://aplusgamesstudio.com/blog/unity-pricing-2026 ; web build settings: https://docs.unity3d.com/Manual/web-optimization-player.html
- Licence and cost, verified from the pricing analyses found in search results: the Runtime Fee was cancelled completely in September 2024. Unity Personal is free up to $200,000 in revenue and funding over the last 12 months, with the splash screen optional in Unity 6. Above that, Unity Pro is required, at $2,200 per seat per year on the January 2025 terms, rising to $2,310 per seat per year (or $210 per month) in the January 2026 update. Enterprise is custom-priced and required above $25 million. No per-install fees.
- What it unlocks visually: a mature engine with URP (Universal Render Pipeline) for phones, a large VFX ecosystem (VFX Graph, Shader Graph, a deep asset store), and the strongest native Android tooling and profiling story in this section. For a stylised space game, URP plus VFX Graph is a genuine step up in effects authoring from hand-rolled Babylon systems.
- Distribution reality: Unity does export to WebGL, which keeps a web channel, but the web build is WebAssembly with a fixed, pre-allocated heap model (Unity docs coverage found in search results: initial memory size configurable, maximum memory up to 4096 MB with known browser bugs above 2048 MB in older Chrome and Firefox, threading limited and dependent on SharedArrayBuffer hosting headers, mobile browsers especially constrained). Unity WebGL builds are also notoriously heavy to download for a web-first audience used to a link that opens fast. Native Android is Unity's home turf and would be excellent, but again changes the product from a link to a store app.
- Port cost in plain terms: total rewrite in C#. Unity's language, editor, prefab and scene workflow, and asset pipeline replace everything except models, textures, and design documents. The 2023 to 2024 pricing episode is also a real, documented trust cost: the fee was announced, walked back, then cancelled, and the current commitment to yearly pricing changes is policy, not contract (per the Promise Legal analysis). That does not block adoption; it belongs in the decision.
- Phone note: native Android, excellent. WebGL on a phone browser, the weakest mainstream option in this section.
- **Verdict: not worth it.** It asks for the same total rewrite as Godot, charges rent above a revenue threshold Godot does not have, and its web export is a worse fit for this game's audience than the Babylon build that already exists.

### 6.5 Bevy (Rust)
- URLs: https://lib.rs/crates/bevy (licence and overview) ; platform and backend coverage: https://Bevy-cheatbook.github.io/gpu/intro.html ; production readiness analysis: https://rustify.rs/articles/rust-for-game-development-bevy-2026
- Licence and cost, verified: Bevy is free and open source, dual-licensed under MIT or Apache 2.0 at your option (lib.rs). No fees, no royalties.
- What it unlocks visually: a data-driven ECS engine built on wgpu, which targets Vulkan, Metal, DirectX 12, WebGPU, and WebGL 2 from the same code (Cheat Book backend table: Android on Vulkan or GLES3, web on WebGPU or WebGL2). Rendering is modern and programmable, and recent releases add ambitious features (the 0.20 release coverage cites Solari path tracing work). What it does not have is the point: no official visual editor (code-first; scenes are built in Rust), a 3D tooling layer that lags its 2D, and breaking API changes every release with migration guides to absorb (production analysis, found in search results, rates it production-ready for indie and jam work for teams already comfortable in Rust).
- Distribution reality: web via WebAssembly on WebGPU or WebGL2, and native Android, both real. Build sizes and load behaviour are respectable precisely because the engine is small.
- Port cost in plain terms: total rewrite in Rust, plus learning Rust and ECS architecture, plus building the editor tooling and effects systems that Babylon, Godot, and Unity include. For an AI-coder plus owner workflow tuned to JavaScript iteration in a browser, this is the worst fit on the list despite the cleanest licence.
- Phone note: technically capable (Vulkan on Android, WebGPU on web). The constraint is development cost, not the device.
- **Verdict: not worth it.** A fine engine for a Rust team starting a new game. It is not a visual upgrade path for an existing JavaScript game.

### 6.6 Hybrid: keep Babylon, add a WebGPU path and compute passes
- URLs: compute shader docs reference: https://doc.babylonjs.com/features/featuresDeepDive/materials/shaders/computeShader/ ; WebGPUEngine coverage: https://www.webcodingcenter.com/webgpu/webgpu-libraries-and-the-ecosystem--babylon-js-s-webgpuengine-a-pointer-to-chapter-7.html and https://wpdean.com/what-is-babylon-js/
- Licence and cost: Babylon.js, Apache License 2.0. Cost: $0. No new vendor.
- What it unlocks, verified from the coverage found in search results: Babylon ships a WebGPUEngine beside its WebGL Engine. You create it with new BABYLON.WebGPUEngine(canvas), await engine.initAsync(), and the rest of the scene code is unchanged. Most of Babylon's main shaders are now written in WGSL; custom GLSL shaders are converted by a downloaded WebAssembly tool, which costs startup time. WebGPU brings compute shaders through Babylon's ComputeShader class (the Babylon forum guidance points to the compute shader docs page above, where device and pipeline management is hidden behind the class), snapshot rendering (engine.snapshotRendering = true records one frame's draw calls and replays them, saving JavaScript time but not GPU time), and lower-level control of graphics resources. Babylon 9 (March 2026, per the release coverage) added clustered lighting and volumetric lighting and a Frame Graph system, which raise the WebGL ceiling too.
- The caveats, verified and stated plainly: a browser without WebGPU cannot run the WebGPU engine; an existing WebGPU scene cannot be swapped to WebGL afterwards; the engine must be picked before the scene and its resources exist; WebGL remains supported side by side for the foreseeable future (as of October 2026, per the documentation summary). So the hybrid is two engine configurations sharing one codebase, with a capability check at boot, a WebGL fallback that must stay tested, and compute effects (GPU particle fields, compute-driven debris, volumetric passes) that must degrade gracefully to the Section 3 systems on the fallback.
- Distribution reality: unchanged. Same web files, same link, progressive enhancement by device. The Pixel line is exactly the class of device where Android Chrome WebGPU is available, so the reference device gets the upgrade and older devices keep today's game.
- Port cost in plain terms: no port. The work is an engine-selection branch at startup, WGSL versions or conversions of custom shaders, a compute pass or two behind capability flags, and a second test tier. Days to weeks, incrementally, with rollback by flipping the boot flag.
- Phone note: WebGPU on tile-based Android GPUs rewards exactly what this game needs (compute particles instead of CPU particles, fewer driver round trips). Measure on the Pixel; keep the WebGL path as the floor.
- **Verdict: worth it.** The only route in this section that raises the visual ceiling for the audience the game actually has, at a small fraction of any port's cost. This is why it holds slot 10 in the Top 10.

### 6.7 Section summary
| Route | Visual ceiling gain for this game | Web channel kept | Port cost | Verdict |
| --- | --- | --- | --- | --- |
| Godot 4 | High on native Android, low on web (Compatibility renderer) | Yes, weakest renderer | Total rewrite (GDScript) | Worth it later |
| Unreal Engine 5 | Highest on desktop, mostly gated off on phones | No (pixel streaming, per-minute cost) | Total rewrite (C++/Blueprints), largest | Not worth it |
| three.js WebGPU | Moderate (compute, TSL), loses integrated tooling | Yes, same as today | Rendering-layer rewrite (JS kept) | Not worth it now, credible later |
| Unity | Moderate to high (URP, VFX Graph), best native Android tooling | Yes, heavy WebGL builds | Total rewrite (C#), seat fees above $200k | Not worth it |
| Bevy | Moderate, immature 3D tooling, no editor | Yes (WebGPU/WebGL2) | Total rewrite (Rust), steepest learning curve | Not worth it |
| Babylon hybrid WebGPU | Moderate (compute, snapshot rendering, Babylon 9 lighting) | Yes, unchanged, progressive | No port; incremental branch | Worth it |

## 7. The cinematic target: Sins of a Solar Empire as the benchmark

Owner direction: the target feel is cinematic, explicitly benchmarked against Sins of a Solar Empire (2008, Ironclad Games and Stardock) and Sins of a Solar Empire II (2024). This section first establishes, from verified sources, what actually creates that look and feel, then maps each element to a Babylon implementation on a phone budget, with enough detail to start coding from.

### 7.1 What creates the Sins look and feel (sourced)

**Scale contrast you can traverse in one move.** The defining Sins shot is the continuous zoom. A PC Gamer review excerpt carried by Arcader describes it directly: it is "so impressive to seamlessly switch from looking at a map of one or more solar systems to being able to pick out individual lights on a ship, rust on a hull or a missile zeroing in on its unfortunate target", and calls the battles "a kaleidoscope of deadly lasers and colourful space hulks, elevated by absurdly minuscule details and appropriately dramatic lighting" (https://arcader.org/news/sins-of-a-solar-empire-2-review/). Player testimony on the official forums makes the same point at ship level: "it is so cool to zoom up right next to a flak frigate and compare it to the size of a Capital that is sitting right next to it" (https://forums.sinsofasolarempire2.com/335646/get;2013644). The lesson is not raw detail; it is that frigate and capital ship coexist in one scene at honestly different scales, and the camera can travel between them without a cut.

**Silhouette readability at distance, solved with iconography, not just models.** Sins battles are commanded zoomed out, where hulls shrink to specks. The original game's answer, documented in the bit-tech review, is the Empire Tree: because "the game arena is so huge, it isn't really possible to use a mini-map", a tree along the left lists all your planets and the ships in orbit, and shows enemy ships in the vicinity so you can see which planets are under attack (https://www.bit-tech.net/reviews/gaming/pc/sins_of_a_solar_empire/2/). Ironclad later added a selection-based Empire Window mode specifically "to reduce clutter" (official forums: https://forums.sinsofasolarempire.com/157606/get;1393935), and pre-release forum discussion records an established "change with zoom-range system" for icons (https://forums.sinsofasolarempire.com/148616/get;1313957). In other words, Sins treats zoom-dependent representation (model, icon, or fleet pip) as a designed system, and treats UI clutter as a bug worth an engine feature.

**Bloom-heavy weapons fire over a dark, graded field.** Every Sins 2 review found in research lands on the same image: battles where "lasers and missiles fill the screen" (Esportingo visual spectacle section: https://esportingo.com/sins-of-a-solar-empire-2-review-a-complex-yet-rewarding-interstellar-strategy-experience/), "the glint of sunlight off a capital ship's hull" and "explosions that scatter debris across the battlefield" (https://www.gamingonpc.com/reviews/sins-of-a-solar-empire-2-review/), and "fleets collide in beautifully lit starfields, explosions ripple across hulls with updated effects" (Steam community discussion: https://steamcommunity.com/app/1575940/discussions/1/578298707369444055). The components are consistent: a single strong key light (the local star), bright additive beam and projectile cores that bloom, hulls lit dramatically against near-black space, and persistent debris that sells the explosion after the flash.

**Living turrets and tracked detail.** Sins 2 reviews repeatedly single out "rotating, target-tracking turrets" as the detail that makes large battles read as alive rather than as sprites exchanging fire (Esportingo and Game Up News: https://gameupnews.com, review of Sins of a Solar Empire 2, found in search results). Motion on the hull, not just motion of the hull, is a signature.

**A warning from the same sources: spectacle dies if the UI fights it.** The Steam discussion above praises the battles as "the modern upgrade fans have waited for" and in the same post calls the interface "white and blue boxes, flat panels, zero thematic flair", concluding "the visuals say epic space opera, but the UI says corporate database". Cinematic feel in Sins is therefore fragile in a specific way Voidsworn can exploit: Sins wins the 3D frame and loses some of it back to UI chrome. Restraint and theming in the UI layer is part of the benchmark, not a separate concern.

**Performance headroom is part of the feel.** The Arcader-carried review notes performance "never noticed dipping below 70 fps with everything cranked up" on PC. Cinematic reads as cinematic only at a stable framerate; a stuttering bloom pass reads as cheap. On a phone this translates to a hard rule used throughout this section: effects are budgeted, tiered, and cut before the framerate is.

### 7.2 Camera: scale framing and cinematic moves

Sins framing in Voidsworn terms: the board camera needs three readable distances (fleet view, squadron view, hero view) and smooth, eased travel between them, with capital ships and flagships framed large and low when the player commits to hero view.

Babylon implementation:
- Keep one ArcRotateCamera for play. Animate target, alpha, beta, and radius together for every scripted move; never cut except on sector jumps.
- Use Babylon Animation with easing for all camera moves. Verified from the Babylon animation documentation coverage (grideasy.github.io, found in search results): animations are keyframed (frame and value pairs via setKeys), easing functions include CircleEase, CubicEase, and SineEase, each settable to EASEIN, EASEOUT, or EASEINOUT via setEasingFunction and setEasingMode, and BezierCurveEase(x1, y1, x2, y2) gives a custom cubic-bezier curve. Animation.CreateAndStartAnimation is the one-call form for a single property.
- Shot recipes (starting values, tune on device):
  - Boss or capital arrival: 3.5 second move. Radius from 1.6x fleet view to hero framing, beta dropping toward the hull's waterline equivalent (in space terms, toward its main plane) so the ship looms, BezierCurveEase biased to a slow finish (for example 0.32, 0.0, 0.2, 1.0). Letterbox bars in (Section 7.6) over the first 0.4 seconds. Depth of field from the LensRenderingPipeline (Section 3.10) enabled only for this shot, focus distance locked to the arriving ship.
  - Command use: 1.2 second push-in of about 15 percent radius on the commanding ship, ease-out, a brief bloomWeight lift in the DefaultRenderingPipeline (Section 3.8), then release back. No letterbox; this is emphasis, not a cutscene.
  - Defeat of a capital ship: slow radius increase (pull back) over the explosion's life so the fireball and debris field (Sections 3.4 and 5.5) stay in frame, ending on the SPS debris.
- Cost: camera animation is CPU-trivial. Depth of field is the only expensive element and is confined to the arrival shot. On the phone tier, drop the DOF and keep the move and the letterbox; the shot still works.

### 7.3 Beams, projectiles, charge-up, and shockwaves

The Sins weapons look decomposes into four reusable Babylon builds:

**Beams.** A beam is a stretched, additive cylinder or ribbon between muzzle and target with a bright core and a soft shell, plus a muzzle flash sprite and an impact glow sprite with sub-emitter sparks (CPU particles, Section 3.2). Build: core mesh with a Node Material (Section 3.6) scrolling a noise texture along its length so the beam boils instead of sitting static; shell mesh at 1.6x diameter, alpha about 0.25, same scroll at half speed. Fade both in over 40 ms and out over 80 ms; a beam that pops in at full alpha reads as a UI element, not a weapon. Bloom (threshold about 0.85) does the rest; the core's emissive must exceed 1.0 in HDR to cross the threshold. Phone cost: two transparent cylinders per active beam. Cap concurrent beams (a working budget is 12) and shorten shell life first when tiering down.

**Projectiles and missiles.** A small emissive core mesh (instanced, Section 5.5) plus a trail (Section 7.4) plus a point of engine glow sprite. Tracking turrets (the Sins 2 detail from Section 7.1) are a Voidsworn win available cheaply: turret submeshes rotated toward their current target each frame is a handful of matrix updates, and it makes exchanges read as aimed. Keep turret meshes as separate named nodes through the gltfpack step (-kn, Section 4.1) so they survive optimisation addressable.

**Charge-up.** For capital weapons and Command abilities: a growing glow sprite at the muzzle (scale and intensity on the same easing curve as the camera push-in, Section 7.2), a particle inflow (CPU system with negative radial velocity, or a GPU system with a converging emitter), a rising emissive pulse on the weapon's emissive texture channel, and a sound-synced release into beam or projectile plus a recoil offset on the firing hull (a 0.2 to 0.5 unit positional impulse decaying over 0.5 seconds). The charge is what makes the shot feel heavy; the shot itself can stay simple.

**Shockwaves.** A ring mesh with a ShaderMaterial (Section 3.7): uniforms for start time and max radius; fragment computes a thin bright band at the current radius with fresnel-weighted alpha, expanding on an ease-out curve and fading by radius. One draw call, no particles. Add a second, slower dust ring using the SPS debris puff for capital deaths. Phone cost: negligible geometry, one transparent pass. This is the single cheapest "cinematic" effect in the memo relative to how it reads.

### 7.4 Engine trails and projectile trails

Two Babylon routes, pick per use:
- TrailMesh (built in): constructed as new TrailMesh(name, generator, scene, diameter, length, autoStart), it extrudes a ribbon behind a moving node (constructor signature verified in Babylon forum guidance found in search results). Use for ship engine trails where the ship count is modest. Known quirk from the same forum record: trails can start with a stray segment from the origin unless the generator's world matrix is computed before starting (computeWorldMatrix on the source mesh), and there is no built-in reset, so pool and reuse trail meshes rather than recreating them per burst.
- NME curve-texture trails: the Babylon trail walkthrough (babylonjs.medium.com, Section 3.6) derives direction from two samples of a curve texture, orients each vertex to face the camera via a cross product, and shapes alpha with sine across width times sine along length. Use this for missiles and projectiles, where hundreds of short trails must be cheap and camera-facing, and where the trail path is already known analytically.
- Styling rule from the art direction doc: trail colour is propulsion colour by faction, never cyan (cyan means shields). Trail length scales with ship class; capital trails are long, faint, and wide, fighter trails short and bright.
- Phone cost: trails are transparent overdraw. Budget total trail screen area, not count; fade trails by camera distance and drop fighter trails entirely at fleet view (they are invisible anyway under the zoom-icon system, Section 7.5).

### 7.5 Skybox grandeur and fleet readability at distance

**Layered skybox stack** (replaces a single flat plate):
1. Base: a SpaceScape or NASA/ESA skybox (Section 1) at 1024 per face, graded by the region LUT (Section 3.11), held under the art direction luminance cap so hulls stay readable.
2. Star layer: StarfieldProceduralTexture (Section 3.5) on the skybox material or a slightly smaller inner box, so stars can twinkle and drift independently of the nebula plate.
3. Parallax planes: two or three large soft nebula sprites (Section 5.4 billboard clusters) at mid distance, giving camera parallax the plate cannot.
4. Hero object: one per region (a planet with atmosphere fresnel shell, a station silhouette, a dead star with corona sprite), placed off-axis from the default camera so the default board framing always has a composition anchor.
Phone cost: one skybox, one extra texture sample layer, a handful of sprites. This stack is how a static plate stops looking static.

**Fleet silhouette readability** (the Sins Empire Tree lesson, translated):
- Three representation tiers by camera radius, swapped at thresholds: full model, simplified model (the -si LODs from Section 4.1), and icon (a faction-coloured silhouette sprite with class glyph). Sins solves this with its zoom-range icon system and Empire Tree (Section 7.1); Voidsworn's board equivalent is the tier swap plus a persistent fleet strip in the UI that mirrors the Empire Tree's job: every capital ship, its location, and its status, always visible, doubling as a camera jump list.
- Silhouette first: at fleet view, what reads is outline plus propulsion glow plus faction colour accents. That is why the art direction doc's silhouette grammars and FAC3D colour law matter more at distance than any texture. Test readability by screenshotting fleet view and shrinking it; if classes are not distinguishable at thumbnail size, the LOD or the icon tier needs work, not the texture.
- Selection and status stay in HighlightLayer outlines and UI pips (Section 3.9), never in emissive changes to hulls, so a selected fleet does not break the cinematic grade.

### 7.6 Cinematic UI restraint and free composition tricks (zero runtime cost)

These cost nothing on the GPU and are pure presentation discipline, several of them direct responses to the Sins 2 UI criticism in Section 7.1:
- Letterboxing: two CSS bars that slide in for arrival and story beats (Section 7.2) and out for play. DOM, not post-processing. Free.
- Shot composition: frame battles with the rule of thirds by offsetting the default camera target from the board centre toward the hero object (Section 7.5); keep the local star (key light) coming from a consistent screen direction per region so fleets are always lit dramatically from the same side.
- UI restraint during spectacle: when a capital ship dies or a Command fires, fade non-essential HUD panels to about 30 percent opacity for the duration of the effect and restore after. The Sins lesson is that chrome competes with spectacle; Voidsworn can simply get out of its own way.
- Colour discipline: the grade (Section 3.11), the colour law (cyan is shields, gold is patrons and Command), and UI accent colours drawn from the same FAC3D source keep the frame unified. A cinematic frame is mostly a frame where nothing clashes.
- Vignette: available in the DefaultRenderingPipeline image processing (Section 3.8). A slight permanent vignette focuses the board and costs one pass that already exists. Grain stays off during play; it reads as noise on a small phone screen at arm's length.

### 7.7 Cinematic phone budget (summary)
- Always on: DefaultRenderingPipeline (HDR, samples 4, bloom, vignette, LUT grade), beams and trails within caps, layered skybox stack, LOD and icon tiers.
- Moment-only: LensRenderingPipeline depth of field (arrival shots), bloom weight lifts (Command), shockwave rings (capital events).
- Never on phone: full-time depth of field, animated grain, uncapped GPU particle fields, raw Discombobulator geometry, uncompressed textures.
- Tiering rule: when the Pixel cannot hold the target framerate, cut in this order: fighter trails at distance, shell layers on beams, GlowLayer, bloom weight, then MSAA samples. Never cut the LUT grade, the skybox stack, or camera easing; those are the feel, and they are nearly free.

## Sources note

All URLs above were opened or returned by search during research on 2026-10-23 and are cited at the entry they support. Licence statements are quoted or paraphrased from the licence or terms page named in each entry. Where a claim rests on secondary coverage rather than a primary page (for example pixel streaming prices, which vary by provider), the entry says so and gives the provider example rather than a universal figure. Prices for flagged paid items are as found on their store pages during research and will drift; the flags will not.
