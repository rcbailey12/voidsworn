# Tool guides: Blender, Babylon, pipeline glue, and AI models

From Rey (Muse), Oct 24, 2026. Commissioned by Ryan as the how-to companion to the field guide: concrete settings, flags, commands and workflows for the tools Opus actually runs, drawn from official docs, repos, forums and community threads. Companion to mod_scene_field_guide.md in this folder: that document is mechanisms and assets to steal; this one is how to run the toolchain that turns them into shipped hulls, effects and sounds.

## The merged chain (the whole document in one paragraph)

An AI mesh and an AI texture enter the pipeline separately and join only at the bake. The mesh goes through a seven-step cleanup (audit, remesh and retopology, silhouette-safe decimation, UV unwrap, kit parts attached at manifest landmarks, high-to-low bake, phone-tier compression gate) and the texture goes through a local estimation chain (CHORD or Hunyuan paint or UltraTex from one flat-lit image, ControlNet for structure, IPAdapter for look, a style LoRA trained on the final plates for consistency). The cleaned hull and the estimated maps meet in Blender, bake to the game tiers, and ship through gltfpack plus KTX2 into Babylon, where thin instances, frozen materials and a self-hosted KTX2 transcoder keep the phone tier alive. Every part below is one link of that chain, and the checker pattern (AJV schema validation, a reference checker for dangling ids, a golden-save compatibility test) guards the joints.

## Top finds

- **The glTF occlusion hook** (Part 1): glTF occlusion only exports through a custom node group literally named `glTF Settings` with an `Occlusion` input. This is the exact mechanism the game's ORM-packed painted materials need, and it is invisible if you only look at the shader graph.
- **Compression is not simplification** (Part 1): KTX2 fixes memory, only triangle cuts fix framerate. The guide puts the budget gate in the .bat chain so it cannot be skipped.
- **The HDR and AA trap** (Part 2): with DefaultRenderingPipeline hdr=true, the scene renders to an offscreen texture and canvas anti-aliasing silently stops applying until `pipeline.samples` is set. The single most likely cause of a "cinematic pipeline looks worse" regression on the phone tier.
- **Thin instances versus solid particles, with numbers** (Part 2): a verified forum thread measured the same asteroid field at 15 fps with a solid particle system and 60 fps with thin instances. That settles the debris and asteroid architecture directly.
- **The gltfpack two-tier recipe** (Part 3): one tool covers geometry, quantization, instancing, simplification and texture conversion, with `-kn` keeping named hardpoint nodes the game addresses by name, and `-si` and `-ts` flags added for the phone tier.
- **The checker pattern, made concrete** (Part 3): AJV schema validation per data file runnable as a .bat step, a custom reference checker modeled on RPFM's broken-key diagnostics, and a golden-save compatibility test per shipped version, which is the Endless Sky deprecated-ships answer turned into automation.
- **Kit parts are the AI mesh fix** (Part 4): hand-built kit parts are not decoration on an AI mesh, they are the fix for its worst property, fused and unreadable detail. The AI hull supplies the big form, the kit supplies readable guns, tanks and slabs at manifest landmarks, and the bake makes the cleaned hull read like the dense original.
- **Safe local image bases on 16 GB** (Part 4): Qwen-Image under Apache 2.0 (quantized builds fit 16 GB) and FLUX.1 schnell or klein 4B (both Apache 2.0). Self-hosted FLUX.1 dev is the trap: sources disagree on whether its licence allows commercial use of outputs, and a LoRA trained on a dev base inherits the restriction either way.
- **The local texture chain** (Part 4): CHORD estimates a full PBR set from one flat-lit image, Hunyuan paint bakes multi-view diffusion onto UVs with inpainting for unseen areas, and UltraTex paints six views at once at around 6.8 GB VRAM. Faction paint consistency becomes a pipeline step instead of a per-asset fight.

## Honesty notes

Forum and Reddit wisdom is labeled secondhand throughout, not documentation. Each part flags its own gaps in place; the load-bearing ones: the Blender part's addon prices come partly from third-party tables rather than vendor stores, so check at purchase; the Babylon part's default pipeline details rest partly on forum threads and a third-party walkthrough because the official page surfaced is deprecated; the glue part's Effekseer to web details rest on summaries of the repo rather than its own docs, and no official Babylon plugin exists; the AI part's TripoSG licence, DreamGaussian commercial terms, Hunyuan3D's reported regional licence exclusions, and the Flux dev fine print all went unverified or disputed, and the safe recommendations hold under either reading. The AI part also runs about 8 percent over its word guide, kept rather than thinned.

The four parts run about 13,500 words between them.

## Part 1: Blender for a real time game asset pipeline

For Opus, building ship hulls for a Babylon.js hex fleet tactics game. The game ships one HTML build with two asset tiers (phone meshes and desktop meshes), compresses with meshoptimizer tooling, and uses painted materials with vertex colour AO and gradients. Documentation is cited as documentation; forum and Reddit wisdom is marked secondhand community practice.

### 1. glTF export: what actually survives

The Blender glTF manual is the authority here, and it is blunt about the format's limits.

- **Geometry.** Quads and n-gons are converted to triangles on export. Discontinuous UVs and flat-shaded edges raise the exported vertex count, because those vertices are split for export. Curves and other non-mesh data are not preserved at all; convert to mesh first. Source: https://docs.blender.org/manual/de/2.81/addons/import_export/io_scene_gltf2.html
- **Materials.** Only a Principled BSDF metal/rough PBR workflow exports, plus Shadeless (Unlit). The channels that survive are base color, metallic, roughness, baked ambient occlusion, normal map, and emissive. Everything else in a shader graph is decoration that Blender shows and the game never sees.
- **Occlusion has a special hook.** No node arrangement makes Blender use an occlusion map the way glTF intends, so the exporter looks for a custom node group literally named `glTF Settings` with an input named `Occlusion`, and takes the image texture attached there. glTF stores occlusion in the red channel, so it can share one image with roughness (green) and metallic (blue): the ORM pack.
- **Normal maps.** Connect an Image Texture node (Color Space set to Non-Color) into a Normal Map node (Tangent Space, the only space glTF supports), then into the Principled BSDF normal input. Bake with space Tangent, R +X, G +Y, B +Z. A bump map does not export at all; a three.js forum thread confirms the failure mode, a model that looks flat in the viewer because its bump never left Blender. Convert bump to a baked normal map first. Source: https://discourse.threejs.org/t/blender-gltf-export-material-issue/35588
- **Emissive.** An image connected to an Emission shader node exports as the emissive texture. In the manual version checked, the Emission input of the Principled BSDF node itself was not supported, so use a separate Emission node and check this against the installed version.
- **Backface culling and alpha.** The Eevee material Backface Culling setting controls glTF's DoubleSided flag (inverse). Prefer Opaque or Alpha Clip over Alpha Blend; the manual warns Alpha Blend can behave unexpectedly in real time engines. Hulls should almost always be Opaque.
- **Images.** glTF requires PNG or JPEG; the exporter converts anything else automatically, which costs export time. Keep source textures PNG or JPEG from the start.
- **Vertex colors export.** The exporter has a Vertex Colors toggle. This is the route for the vertex colour AO and gradient language the game already uses: bake to a vertex color layer, export with the toggle on, and confirm the layer name survives in the target loader.
- **UV transforms.** A UV Map node plus a Mapping node exports through the KHR_texture_transform extension, but not all readers support it. For a Babylon target, prefer baking transforms into the UV layout itself.
- **Custom properties survive.** Custom properties on objects are preserved in glTF export, which is the clean way to carry hull metadata (hardpoint names, mount positions) instead of sidecar files.
- **Format choice.** glTF Binary (.glb) packs everything into one file. glTF Separate (.gltf + .bin + textures) is easier to inspect by hand. Use Separate while a hull is being debugged, Binary for the shipped tier.

### 2. Headless batch pipeline: the script is the pipeline

Blender's own Python API tips page gives the core command: `blender --background --python myscript.py`, optionally with a blend file first (`blender myscene.blend --background --python myscript.py`). Background mode is the whole pipeline; nothing here needs the GUI. Source: https://docs.blender.org/api/dev/info_tips_and_tricks.html

One-liner export, verified on a tutorial page:

```
Blender -b input.blend --python-expr "import bpy; bpy.ops.export_scene.gltf(filepath='output.glb')"
```

Source: https://til.jakelazaroff.com/blender/export-a-blender-file-to-glb-from-the-command-line/

A batch script follows one pattern (example pattern from a secondary tutorial; the API calls themselves are standard):

```python
import bpy, os
basedir = "/path/to/blends"
output_dir = "/path/to/output"
for f in os.listdir(basedir):
    if not f.endswith(".blend"):
        continue
    bpy.ops.wm.open_mainfile(filepath=os.path.join(basedir, f))
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(output_dir, f.replace(".blend", ".glb")),
        export_format="GLB",
        export_apply=True,
        export_draco_mesh_compression_enable=True,
    )
```

Source: https://copyprogramming.com/howto/using-three-js-exporter-in-a-python-script

Rules that make this reliable:

- **One .bat per step, on Ryan's PC.** The owner runs double-click .bat files (Windows 10, PowerShell 5.1). A hull pipeline .bat should call the Blender executable by full path, then the export script, then the optimizer, so the whole chain is one double-click. Print triangle counts and output sizes at each step; a silent pipeline hides regressions.
- **export_apply=True is load-bearing.** It exports the evaluated mesh, modifiers included. Without it, an unapplied Mirror or Decimate silently exports half a hull or the unreduced mesh. Source: https://github-wiki-see.page/m/gree/hubs-docs-jp/wiki/creators-using-the-blender-gltf-exporter
- **Keep the .blend as source, never the .glb.** Re-export from source on every change; rebuilding must be cheap enough to do for all 36 hulls at once.
- **Deterministic naming.** Name outputs `<hull_code>_hi.glb` and `<hull_code>.glb` for the two tiers, from the same source, so the game loader never has to guess which file is which tier.
- **CI shape.** The standard pipeline shape is: artist saves .blend, a script detects the change, Blender headless exports glTF, glTF-Transform or gltfpack optimizes, output is committed or pushed. For this project the "CI" is the .bat chain on the PC, but the stage order is identical. Source: https://franrivalbigprojects.github.io/cross-pipeline-tools-functional/

### 3. Post-export optimization: gltfpack and glTF-Transform

Two free tools do the work Blender's exporter does not:

- **gltfpack** (ships with the meshoptimizer library, MIT) optimizes meshes for vertex fetch and transform cache, quantizes geometry, merges meshes to cut draw calls, prunes redundant nodes, and can simplify meshes on request. Key flags, verified in the man page: `-c` / `-cc` for compressed output, `-tc` for KTX2 textures, `-si R` to simplify to a fraction of the original size, `-sa` to simplify aggressively, `-kn` to keep named nodes (use this: named nodes are how the game finds hardpoints). Source: https://manpages.debian.org/testing/gltfpack/gltfpack.1
- **glTF-Transform** (CLI) offers one-command optimize (`gltf-transform optimize input.glb output.glb --texture-compress webp --texture-resize 1024`) plus separate `draco`, `resize`, dedupe and prune commands. Draco cuts geometry buffers by 90 percent or more, at the cost of a WASM decoder at runtime.
- **Compression is not simplification.** An A-Frame documentation page states this plainly: compression does not particularly affect framerate; if the model has too many triangles or draw calls, compression will not change that, and the model should be simplified instead. For the phone tier, triangle budget comes first and compression second. Source: https://aframe.io/docs/master/components/gltf-model.html
- **KTX2 is the phone memory win.** WebP shrinks transmission size; KTX2 shrinks GPU memory, the actual phone bottleneck. gltfpack `-tc` is the one-flag route to it.

### 4. Decimation and LOD: cut triangles, keep the silhouette

The Decimate modifier has three modes, per the Blender manual:

- **Collapse** (default): merges vertices progressively, taking shape into account. Ratio is the fraction of faces kept, measured in triangles, so a quad mesh keeps more faces than the ratio suggests unless Triangulate is on. A vertex group plus Factor limits decimation to part of the mesh, which is how gun housings and engine blocks survive while flat hull plates get cut. Symmetry can be preserved on one axis.
- **Un-Subdivide**: reverses a subdivision. Use even iteration counts (two iterations equal one subdivide). Only sensible on grid topology that has not been edited since subdividing.
- **Planar**: dissolves faces on mainly flat surfaces, controlled by Angle Limit. Delimit options protect edges: Normal (do not dissolve across flipped normals), Material (do not dissolve across material borders), Seam (do not dissolve across UV seams). For hulls, Planar with Delimit by Material is the right first pass: flat armor plates collapse, panel lines and material borders survive.

Source: https://docs.blender.org/manual/de/2.80/modeling/modifiers/generate/decimate.html

Community practice (secondhand, from tutorials and forum threads):

- **The silhouette rule.** Pull Ratio down until the silhouette starts to break, then back off one step. That is the phone tier. Bake the removed detail into the normal map (section 5).
- **Delete tiny greebles first.** A BlenderArtists thread on simplifying a complex ship reports the biggest early win came from deleting tiny greebles and flattening over-beveled small cylinders, 20k to 30k faces, before any Decimate pass. Detail that reads at desktop distance is noise at phone distance. Source: https://blenderartists.org/t/simplifying-a-complex-model/1377921
- **Build the LOD chain from one source.** Desktop tier at full detail, phone tier as the same mesh with a Decimate pass (or gltfpack `-si` at export). Two separately modeled hulls drift; one model with two ratios does not.
### 5. Baking: Cycles only, and the settings that matter

Baking is a Cycles feature; Eevee cannot bake. The manual's setup rules: the mesh needs a UV map, and the active (last selected) image texture node is the bake target. Selected to Active casts rays from the low-poly object inward toward the high-poly object; Ray Distance or Cage Extrusion controls where those rays start, and a manual cage object gives the most control. Margin extends the bake past UV island borders to soften seams. Source: https://docs.blender.org/manual/ja/2.80/render/cycles/baking.html

Practical settings, from the manual plus tutorial consensus (secondhand for the numbers):

- **Bake types per map:** Normal (tangent space) for surface detail, Ambient Occlusion for contact shadow, Diffuse color only for albedo (never bake lighting into albedo unless deliberate), Emit for glow.
- **Selected to Active order:** select high-poly objects first, Shift-select the low-poly last so it is active. Both must be visible in viewport and render.
- **Cage Extrusion 0.1 to 0.5, or Ray Distance roughly 1 percent of the object's largest dimension.** Too small and rays miss the high-poly (blank maps); too large and rays hit the wrong surface. A manual cage is a duplicated low-poly inflated slightly (Alt+S in Edit Mode).
- **Margin 4 to 16 pixels**, and bake at 2x or 4x the ship resolution then downscale: seams shrink and aliasing drops.
- **Colorspace discipline.** Color maps (base color, emissive) use sRGB. Data maps (normal, roughness, metallic, AO) use Non-Color. Getting this wrong is the classic "maps look too bright or washed out" bug, and exporters do not fix it for you.
- **Vertex colour AO and gradients.** The game already uses vertex colour for AO and gradients. The Bake to Vertex Color addon (free, GitHub) transfers an image to a vertex color layer across selected objects, the bridge from a baked AO image to the vertex colour language. TexTools (below) covers the same ground with 14-plus bake modes.
- **Paid shortcut.** SimpleBake (paid, Superhive) auto-detects which maps a material needs, previews each bake, and handles selected-to-active plus AO, curvature and thickness in one operation. Worth it only if manual baking becomes the bottleneck. Source: https://superhivemarket.com/products/simplebake---simple-pbr-and-other-baking-in-blender-2

### 6. Normals and shading: the hard surface look lives here

The single most valuable modifier combination for ships is bevel plus weighted normals, in that order:

- **Weighted Normal modifier.** Weighting modes per the manual: Face Area (larger faces influence more), Corner Angle (Blender's default combination method), or Face Area and Angle multiplied. Influence at 50 is uniform weighting; above 50 biases toward large faces, below 50 toward small ones. Keep Sharp preserves sharp edges. Face Influence lets the Bevel modifier's face strength (weak, medium, strong) steer the result. Source: https://docs.blender.org/manual/es/3.4/modeling/modifiers/modify/weighted_normal.html
- **Why face area weights matter.** A technical explainer notes that default corner angle weights compensate for triangulation but not spacing, while face area weights make large planar faces dominate, preserving the planes of a beveled hard surface. The inverse warning: face area weights are counterproductive on surfaces meant to be smooth. Use them on hull plates, not curved domes. Source: https://tools.fondant.gg/custom-normals/laplacian-technical/
- **Bevel first, weighted normal second, Harden Normals on.** The bevel gives edges a highlight-catching chamfer; the weighted normal pass keeps flat faces flat. Reversing the order is how beveled hulls get the soft, melted look.
- **Sharp edges and Auto Smooth.** Mark edges sharp where two plates must read as separate, and let the weighted normal modifier respect them (Keep Sharp). In Blender 4.1 and later, Auto Smooth moved into the Shade Smooth by Angle operator; check the installed version's location rather than trusting older tutorials. Custom split normals do not survive every operation; clearing them and re-applying the bevel plus weighted normal stack is the reliable reset when shading goes wrong.
- **Green channel caution.** An Unreal forum thread reports baked normal maps with flipped green channels, fixed by flipping the green channel of the baked map. The glTF standard is +Y up; if a baked normal map lights from the wrong side in Babylon, flip the green channel before re-baking.
- **Paid normal tooling.** Normal Magic 2.0 (paid, Superhive) adds Boolean Pro (transfers normals from input geometry, avoiding boolean artifacts) and surface projection of normals and UVs. Buy only if boolean shading artifacts become a recurring cost. Source: https://superhivemarket.com/products/normalmagic/?ref=1435

### 7. Addons that matter, with cost and licence flags

| Addon | What it does | Cost / licence |
|---|---|---|
| TexTools | Free UV and texturing toolkit: texture size and padding controls, UV channel cycling, checker maps, texel density tools, 14-plus bake modes. The utility baker plus UV tools in one panel. | Free. Source: http://www.renderhjs.net/textools/blender/ and https://github.com/SavMartin/TexTools-Blender |
| UVPackmaster | GPU-accelerated UV packing, tighter than Blender's built-in Pack Islands, with pixel margin, rotation lock and group-to-tile modes. A free lite version exists with limits; the full engine is paid. Prices seen in roundups vary (about $39 and up); check at purchase. | Paid engine plus free lite. Setup notes: https://uvpackmaster.com/doc3/blender/3.2.6/10-uvpackmaster-setup/ |
| Zen UV | Fast UVs with consistent texel density, popular in game pipelines. | Paid; price not confirmed in this pass. |
| SimpleBake | One-operation PBR baking with preview and auto-detected maps (section 5). | Paid, Superhive. |
| Hard Ops + Boxcutter | The standard hard surface pair: Boxcutter cuts shapes onto a mesh with gestures, Hard Ops manages the booleans, bevels and non-destructive stack behind them. Iteration speed is the win; boolean-heavy results still need cleanup before export. | About $20 each, third-party price table. Source: https://empirecmd.com/empire-university/3d-11-software/blender/blender-add-ons/blender-add-ons |
| MESHmachine | Fixes booleans and meshes for clean export; the recommended pairing with Hard Ops. | Paid. |
| DECALmachine | Surface detail without geometry: mesh decals, trim sheets, atlasing, baking for export. Panel lines and markings without triangles. | About $50, third-party price table. |
| KIT OPS 3 PRO | Assembles props from kit libraries. Relevant to the ship kit idea: hulls as assemblies of placed kit parts. | Paid. |
| BlenderKit | Asset library integrated into Blender: models, materials, HDRIs, brushes. Assets carry either a Royalty-Free licence or CC0. Royalty-Free assets can be used commercially but cannot be resold as assets; CC0 assets are free of copyright. Treat BlenderKit as reference and greeble source, not as hulls to ship, and check each asset's licence badge before use. Source: https://www.cgchannel.com/2026/01/get-over-1000-free-3d-sculpting-brushes-from-blenderkit/ |
| Blender's built-ins | 3D Print Toolbox (mesh analysis), Node Wrangler (shader graph speed), MeasureIt, and the shipped glTF exporter. Enable 3D Print Toolbox before any export gate; it is free and already installed. | Free, ships with Blender. |

Built-in first is a real strategy: Blender's Pack Islands (margin 0.001 to 0.003 to prevent bleeding) plus Average Island Scale for uniform texel density covers most hull UV work, and a checker texture pass makes stretched UVs, bad seams and overlapping islands visible before any bake. Source: https://korvix3d.com/blog/uv-unwrapping-in-blender-7-tips-to-never-get-messy-textures-again

### 8. Hard surface modeling for sci-fi ships (secondhand community practice)

These techniques come from BlenderArtists tutorials and a beginner spaceship tutorial, not from the manual. Treat them as workshop practice, verified by usage, not as documentation.

- **Blockout rhythm.** Loop cut, extrude, scale, repeat. Fuselage shape comes from loop cuts and the knife tool for diagonal edges that break blockiness. Engine nozzles are extrude, scale down, extrude again. Source: https://blender.tekriss.com/blender-2-8-beginner-tutorial-spaceship/
- **Extrude individual faces for detail.** When extruding multiple faces for windows or vents, use Alt+E, Extrude Individual Faces. Extruding shared geometry creates mesh-within-mesh that looks fine in wireframe and breaks normals.
- **Bevel everything, slightly.** The bevel tool (Ctrl+B) with small segments softens edges just enough to catch light. A perfectly sharp edge reads as unfinished in real time lighting. Nothing excessive: one or two segments on most hull edges.
- **Booleans with discipline.** Position the cutter, apply the Boolean modifier set to Difference, delete the cutter object. Leaving cutters in the scene is how mystery geometry appears months later. After any boolean, run the section 9 checks; booleans are the top source of non-manifold edges.
- **Paneling by separation.** A classic hull paneling tutorial: select the faces that form a plate, separate them, extrude slightly, move back to the hull surface, then bevel the plate edges by extruding once more a tiny amount and scaling the new faces inward. The result reads as armor plating without texture work. Save before separating; there is no undoing it cleanly. Source: https://blenderartists.org/t/tutorial-spaceship-hull-paneling/335444
- **Greebles suggest scale.** Small attached shapes make the ship read as large. A fast method from an old tutorial: duplicate the subdivided hull, convert the copy to a mesh, select small faces, copy them into a separate object, extrude. Keep greebles on their own object so the simplification pass (section 4) can delete them for the phone tier without touching the hull. Source: https://blenderartists.org/t/tut-spaceship-modeling-with-smooth-surfaces/340232
- **Model one side, mirror the rest.** Symmetrical hulls: model half, Mirror modifier, apply at export. The Decimate modifier's Symmetry option keeps the mirrored halves consistent during reduction.
- **Purpose-built beats random greebles.** Give every structure a job (radiators, sensor clusters, point defense mounts) rather than scattering random boxes. A mount that exists in the model can become a hardpoint in the manifest.

### 9. Pre-export failure checklist (script it)

Run these before any hull reaches the game, in this order. Every item below is either a Blender operator or a validator flag, so the whole list can become a Python check script in the .bat chain.

1. **Transforms applied.** Object scale must read 1, 1, 1; rotation 0, 0, 0; location near the origin. Ctrl+A, All Transforms. Scaling in Edit Mode instead of Object Mode avoids the problem entirely, and a community checklist flags unapplied scale as the most common export surprise. Source: https://github-wiki-see.page/m/gree/hubs-docs-jp/wiki/creators-using-the-blender-gltf-exporter
2. **Modifiers resolved.** Either apply them or export with export_apply=True. Mirror, Decimate, Bevel and Weighted Normal must all be in the evaluated mesh.
3. **Normals outward.** Overlays, Face Orientation: blue is outward, red is flipped. Select all, Shift+N, Recalculate Outside. Check again; it guesses on enclosed or two-sided geometry and can get it wrong.
4. **No doubles, no loose parts.** Mesh, Clean Up, Merge by Distance (threshold far below the smallest real feature, or fine detail collapses), then Delete Loose. Repeat until the vertex count stops changing.
5. **No degenerate faces.** Mesh, Clean Up, Degenerate Dissolve. A Khronos forum thread traces a glTF validation error (ACCESSOR_VECTOR3_NON_UNIT, a zero-length normal) to exactly this: degenerate faces produce zero normals. Source: https://community.khronos.org/t/gltf-2-0-validation-error-accessor-vector3-non-unit/105517
6. **Manifold.** Select, Select All by Trait, Non Manifold, and work the categories one at a time: wire edges (Delete Loose), boundaries (fill or bridge), multiple faces (delete internal and duplicate faces), non-contiguous (Recalculate Outside). The 3D Print Toolbox Check All button flags non-manifold geometry, intersecting faces and thin walls in one pass. Sources: https://3dx.info/how-to-fix-non-manifold-edges-in-stl-files-for-flawless-3d-prints/ and https://dev.to/ankurbhardwaj/before-you-print-a-checklist-for-turning-an-obj-into-a-good-stl-5d91
7. **UVs present and sane.** Every material needs a UV map; bakes need non-overlapping UVs on the bake target. Run a checker texture pass: stretched UVs show as elongated rectangles, bad seams as discontinuities, overlaps as identical patterns on two parts.
8. **Triangle budget per tier.** Print the triangle count after export, per hull, per tier, and fail the build if a hull exceeds its budget. The game's own numbers give the shape of it: desktop hulls run roughly 2,400 to 38,000 triangles, phone roughly 1,200 to 16,000, and all hulls load at boot, so the budget is a fleet total, not a per-hull wish.
9. **Validate the file, then load it in the target.** Run the Khronos glTF Validator (CLI or web) on every export; it catches spec violations such as zero-length normals and broken accessors. Then load the .glb in the Babylon.js Sandbox: a validator pass is not a render pass, and a file can be spec-legal and still look wrong.
10. **Screenshot the hull in game.** A render in Blender is not proof. The flat-black silhouette sheet and the in-game screenshot are the acceptance tests, and they belong in the same folder as the .blend file.

### Sources and confidence notes

Documentation (Blender manual, man pages, addon home pages) is stated as fact. Forum threads, tutorials and roundups are secondhand community practice and are labeled as such. Items not fully verified: TexTools' GitHub URL is taken from search results, not an opened repo page; UVPackmaster pricing varies between sources, so check at purchase; SimpleBake and Zen UV prices were not confirmed; Hard Ops, Boxcutter and DECALmachine prices come from a third-party addon table, not the vendor stores; several BlenderArtists threads are old (pre-2.8 era in two cases) and menu locations may have moved; Blender 5 claims in secondary sources were not relied on, and version-sensitive details (Auto Smooth location, Principled Emission support) should be checked against the installed Blender version.

## Part 2: Babylon.js engine guidance

For Opus, building Voidsworn: a Babylon.js hex fleet tactics game shipped as one HTML build, phone first with a desktop tier, many ships on screen, faction readable effects, beams, shields, particles, background plates and cinematic camera work. Each entry gives the concrete setting, API or pattern, a source URL, and the phone versus desktop note where it matters. Forum wisdom is marked as community practice, and third party walkthroughs are labeled as such.

### 1. Rendering pipeline

#### DefaultRenderingPipeline: the HDR and AA trap

Use the DefaultRenderingPipeline, not the older StandardRenderingPipeline: the official docs page for the standard pipeline says it is no longer maintained.

- https://doc.babylonjs.com/features/featuresDeepDive/postProcesses/standardRenderingPipeline/

The default pipeline constructor is `new BABYLON.DefaultRenderingPipeline(name, hdr, scene, [camera])`. The `hdr` flag has a trap that forum threads return to again and again: with `hdr = true` the scene renders into an offscreen texture, and the canvas default antialiasing does not apply to that texture. You must set `pipeline.samples` (MSAA, up to `engine.getCaps().maxMSAASamples`) to get edges clean again. With `hdr = false` and only image processing effects, the pipeline renders directly to the framebuffer so canvas AA applies, but the moment you enable bloom or another effect it switches to the post process path and you lose AA again unless `samples` is set.

- https://forum.babylonjs.com/t/enabling-hdr-in-defaultpipeline-disables-aa/14656
- https://forum.babylonjs.com/t/enable-image-processing-jagged/41997

Practical settings, from forum threads and a third party walkthrough:

- `pipeline.fxaaEnabled = true` is the cheap AA alternative on phones. FXAA softens edges slightly; MSAA 4 is sharper but costs fill rate.
- `pipeline.bloomEnabled = true`, `bloomThreshold` around 0.7, `bloomWeight` around 0.5, `bloomScale` around 0.5.
- `pipeline.imageProcessing.toneMappingEnabled = true` with `toneMappingType = BABYLON.ImageProcessingConfiguration.TONEMAPPING_ACES`, plus contrast and vignette, is the cinematic grade in one place.
- Depth of field, motion blur and SSAO2 all cost performance every frame; treat them as desktop tier only.

Phone versus desktop: phone gets FXAA (or MSAA 2), bloom at reduced scale, ACES grade, no depth of field, no motion blur, no SSAO. Desktop gets MSAA 4, full bloom, and the depth effects. Every enabled pipeline effect adds full screen passes and draw calls.

- https://forum.babylonjs.com/t/default-rendering-pipeline-drawcall/58546
- https://forum.babylonjs.com/t/controlling-the-render-pipeline-with-typescript/4733

#### GlowLayer: selective bloom, and its occlusion catch

GlowLayer renders chosen meshes' emissive color into its own blurred texture and composites it over the frame. Cheaper than full pipeline bloom because it is selective, it is the right tool for shields, engine glow, beam cores and faction accents on a phone.

- `new BABYLON.GlowLayer(name, scene)`, `glow.intensity`, `glow.blurKernelSize`, `glow.mainTextureSamples` (2 is a common phone friendly value).
- `glow.addIncludedOnlyMesh(mesh)` limits the layer to exactly the meshes that should glow; `addExcludedMesh(mesh)` removes meshes from it.
- `glow.customEmissiveColorSelector` lets you override what color a mesh glows with, and `glow.setMaterialForRendering(mesh, tempMaterial)` swaps in a temporary material just for the glow pass, useful when a mesh's real material is too dim or too hot to glow well.
- `glow.neutralColor` sets the color that produces no glow.

Pitfalls, all from forum threads:

- Glow renders on top of the scene and is not occluded by other meshes by default. The forum fix is to add occluder meshes with `addExcludedMesh`, or use a depth pre-pass on the glowing material plus a mask built from a second camera. For Voidsworn, the practical version is simpler: keep glowing parts (shield bubbles, engine bells, beam cores) as separate meshes or submeshes so they can be included or excluded cleanly.
- Glow uses the emissive channel, so a mesh under direct light can blow out to white. The forum fix is to separate glowing parts onto their own material and compensate with a negative `directIntensity` on PBR materials while raising `emissiveIntensity`, so the glow stays strong at distance without whitening up close.
- HighlightLayer is the alternative for selection halos: it needs `stencil: true` at engine creation and costs more than GlowLayer, so use it only for the selected ship. SelectionOutlineLayer draws a crisp editor style outline.

- https://www.webcodingcenter.com/babylon-js/post-processes-and-rendering-pipelines--the-glow-layer-and-highlight-layer.html
- https://forum.babylonjs.com/t/glowlayer-effect-occlusion-problem/48153
- https://forum.babylonjs.com/t/any-ideas-why-glowlayer-is-turning-white/40644

### 2. Materials and shaders

#### PBRMaterial: the two defaults that surprise newcomers

PBRMaterial implements a Cook-Torrance model with image based lighting. Two defaults catch people out:

- `metallic` and `roughness` start as null. Until you set one of them (or a metallicTexture), the material runs in specular glossiness mode, not metallic roughness mode. Always set both explicitly on hull materials.
- `albedoColor` is linear, like glTF baseColorFactor. Convert hex colors with `Color3.FromHexString(...).toLinearSpace()` or your faction palette will render washed out.

Channel packing for the metallic texture: `useRoughnessFromMetallicTextureGreen = true` with `useRoughnessFromMetallicTextureAlpha = false` reads roughness from green, `useMetallnessFromMetallicTextureBlue = true` reads metalness from blue, `useAmbientOcclusionFromMetallicTextureRed = true` reads occlusion from red. This is the texture budget trick that lets one map carry three material channels, which matters when the phone texture budget is the hard limit.

Environment lighting: assign `scene.environmentTexture` once with `CubeTexture.CreateFromPrefilteredData(url, scene)` using a .env file; every PBR material uses it for diffuse and specular. `scene.environmentIntensity` scales both; `material.environmentIntensity` scales one material. StandardMaterial ignores the scene environment and needs a `reflectionTexture` spelled out. IBL has no occlusion, so keep environmentIntensity low in enclosed scenes and bake occlusion into textures.

- https://www.webcodingcenter.com/babylon-js/the-standard-and-pbr-materials--pbrmaterial-and-the-metallic-roughness-workflow.html
- https://www.webcodingcenter.com/babylon-js/textures-environment-and-image-based-lighting--image-based-lighting-from-an-environment-texture.html

#### Node Material: self host the JSON

The Node Material Editor (nme.babylonjs.com) builds shader graphs visually. The save story matters for a single file build:

- `material.serialize()` writes JSON: settings plus a blocks array where each block records its class, properties and inputs. `NodeMaterial.Parse(json, scene)` rebuilds and compiles it.
- `NodeMaterial.ParseFromFileAsync(name, url, scene)` loads that JSON from your own hosting. `NodeMaterial.ParseFromSnippetAsync(id, scene)` fetches from Babylon's snippet server. Snippet round trips measured 0.36 to 1.3 seconds in a third party test, so use snippets for prototyping and self host the JSON or `generateCode()` output in production.
- Textures are saved by URL inside the JSON, so the images must travel with it. `NodeMaterial.IgnoreTexturesAtLoadTime = true` skips them when you assign your own.
- Node Materials need an `Instances` block in the graph to work with instanced meshes. A graph built without it renders on only one instance, a forum reported failure mode that looks like a bug but is a missing block.

- https://www.webcodingcenter.com/babylon-js/the-node-material-editor--saving-and-loading-node-materials-as-json.html
- https://www.webcodingcenter.com/babylon-js/the-node-material-editor--loading-a-node-material-snippet-at-runtime.html
- https://forum.babylonjs.com/t/node-material-from-external-file/37536/5
- https://forum.babylonjs.com/t/the-problem-with-instances-and-nodematerial-load-from-nme-json/46537

#### KTX2 and Basis: the phone memory win

A 1K JPEG expands to about 5.6 MB of VRAM uncompressed; forum estimates put 2K at about 22 MB and 4K at about 90 MB per texture. Basis Universal inside a KTX2 container transcodes at load time to whatever the GPU supports (BC7 on desktop, ASTC or ETC2 on mobile). One forum case cut a scene from 286 MB of VRAM to 73 MB by compressing, and a third party walkthrough measured an 86 KB PNG becoming 12 KB as ETC1S and 37 KB as UASTC.

- `new BABYLON.Texture(url, scene)` accepts .ktx2 URLs directly, and glTF uses them through KHR_texture_basisu.
- ETC1S is tiny but blocky: use it for color textures. UASTC is larger and near lossless: use it for normal maps and data textures. The glTF Transform commands are `gltf-transform etc1s in.glb out.glb --slots "baseColorTexture"` and `gltf-transform uastc in.glb out.glb --slots "!baseColorTexture"`, with `--zstd` controlling the supercompression level.
- The transcoder decoder is fetched automatically from Babylon's CDN by default. Point `BABYLON.KhronosTextureContainer2.JSModuleURL` at your own copy to self host it. For Voidsworn's single file build this is not optional polish: an offline build must not depend on a CDN fetch at first texture load.
- Forum tip: `BABYLON.KhronosTextureContainer2.DefaultNumWorkers = 0` when workers cause trouble.
- Texture color space: set `gammaSpace = false` for normal, roughness and metallic maps. `hasAlpha` stays false until you set it, so a texture never blends by accident.

- https://www.webcodingcenter.com/babylon-js/loading-gltf-and-the-asset-container--ktx2-and-basis-universal-texture-compression.html
- https://forum.babylonjs.com/t/how-to-use-ktx2-basis-compressed-normals/16021
- https://forum.babylonjs.com/t/compressing-babylon-gltf-scenes-to-produce-high-end-experiences-for-mobile-devices/45582

### 3. Performance

#### Draw call budget and batching

Community guidance from a mobile Babylon guide puts the practical budget at roughly 500 to 1000 draw calls at 60 fps on desktop browsers and roughly 100 to 300 on mobile browsers. Treat that as community practice, not an engine guarantee, and measure with the Inspector.

- Merge static geometry with `BABYLON.Mesh.MergeMeshes(meshes, true)` and dispose the originals. Background plates, terrain and static station geometry are merge candidates.
- `mesh.createInstance(name)` shares geometry and material across copies, one draw call per material group.
- Thin instances are the strongest batching tool: one master mesh, one draw call, 64 bytes (a 4x4 matrix) per instance. Use `thinInstanceAdd` for a few, or `thinInstanceSetBuffer("matrix", data, 16, staticFlag)` for bulk. The static flag matters: a forum thread on millions of quads found passing `true` raised the frame rate to 60 on an ANGLE Direct3D backend where the dynamic default stalled.
- Thin instances pick at the instance level, not the face level. If a ship needs face level picking, it is not a thin instance candidate.

- https://dev.to/paulcrinigan/making-a-babylonjs-game-run-well-in-a-mobile-browser-4j5
- https://forum.babylonjs.com/t/mesh-with-thin-instance-slower-than-with-full-vertices/46756
- https://www.webcodingcenter.com/babylon-js/rendering-many-objects-efficiently--keeping-booknest-s-bookstore-fast-on-modest-hardware.html

#### SPS versus thin instances: the asteroid answer

The Solid Particle System merges many particles into a single mesh and a single draw call. A forum thread on procedural asteroid belts, opened and verified, gives the decision rule with numbers:

- Static rocks: SPS and thin instances perform the same, one draw call each.
- Rocks moving or rotating individually: thin instances win because a per instance matrix change is cheaper than rewriting SPS vertex and normal data. The thread's example, all rocks rotating every frame, measured SPS at 15 fps against thin instances at 60 fps (300 to 330 absolute).
- SPS particles can be 2D or 3D, carry per particle color and UVs from one shared texture, have normals and lighting, and are pickable. They cannot be deformed per instance except through the vertex shader (pass a seed attribute and perturb with noise in the shader).
- For Voidsworn: tumbling asteroid fields and debris are thin instances; static wreck fields are SPS candidates. Do not put ship hulls in either; ships need individual materials and picking.

- https://forum.babylonjs.com/t/using-sps-versus-thininstances-for-rendering-procedural-asteroids/22305

#### Freezing, culling and the render loop

From the official forum's optimization megathread and community guides:

- `mesh.freezeWorldMatrix()` on anything that does not move. `scene.freezeMaterials()` once materials are settled. `scene.blockMaterialDirtyMechanism = true` for stable materials, and call `material.markDirty(true)` after any later change.
- `mesh.isPickable = false` by default; set true only on ships and UI targets. `mesh.cullingStrategy = BABYLON.AbstractMesh.CULLINGSTRATEGY_BOUNDINGSPHERE_ONLY` is cheaper than the default box test.
- `scene.skipFrustumClipping = true` only if you have measured that frustum tests cost more than the overdraw they save. `scene.skipPointerMovePicking = true`, `scene.autoClear = false` when the scene fills the viewport, and clear the pointer predicates you do not use.
- Never allocate in the render loop; reuse vectors with `TmpVectors` and the `xxxToRef` variants.
- `engine.setHardwareScalingLevel(1.5)` when fill rate limits the phone; values below 1 render above native resolution and cost performance.

- https://forum.babylonjs.com/t/ideas-for-rendering-and-optimizing-complex-scenes/47511?page=2
- https://forum.babylonjs.com/t/best-practices-for-optimizing-babylon-js-scenes-not-just-on-lower-end-devices/58688

#### LOD

`mesh.addLODLevel(distance, simplerMesh)` swaps in a lighter mesh beyond a distance; `null` as the mesh stops drawing beyond that distance. `mesh.useLODScreenCoverage = true` switches thresholds to screen fractions between 0 and 1, where a larger value means more detail, the opposite order from distance thresholds. Instances inherit their source mesh's levels. Build lighter meshes offline (Blender Decimate, glTF Transform simplify) rather than generating them at runtime. Simplified meshes are named `yourMesh.name + "Decimated"`; dispose old ones before regenerating or levels stack.

- https://www.webcodingcenter.com/babylon-js/rendering-many-objects-efficiently--level-of-detail-with-addlodlevel.html
- https://forum.babylonjs.com/t/some-question-about-using-lod-to-simplify-mesh/56598

#### SceneOptimizer and performance priority

SceneOptimizer watches the frame rate and, while it stays below a target, applies optimizations in priority order, one every `trackerDuration` milliseconds. Presets are Low, Moderate and High degradation allowed, differing in how far they shrink textures and resolution. Build a custom `SceneOptimizerOptions(fps, ms)` from steps the game tolerates, and use improvement mode (the fourth constructor argument) to restore effects on fast devices. Two warnings from experience:

- The preset's first step merges similar meshes, which breaks per mesh picking. If ships must stay pickable, exclude the merge step.
- `RenderTargetsOptimization` disables render targets, and GlowLayer uses render targets, so a stock optimizer will silently kill the glow. A forum thread on exactly this failure recommends removing that step from the list when glow matters.

`scene.performancePriority` is the blunt version of the same idea: `BackwardCompatible`, `Intermediate`, `Aggressive`. Intermediate freezes materials when ready (so later changes need `markDirty`), sets `alwaysSelectAsActiveMesh` on new meshes, sets `isPickable` false on new meshes, turns on `skipPointerMovePicking` and turns off `autoClear`. Aggressive is the community recommendation for mobile, but verify ship picking still works after enabling it, because Intermediate's picking changes already bite.

- https://www.webcodingcenter.com/babylon-js/rendering-many-objects-efficiently--the-scene-optimizer-and-automatic-degradation.html
- https://forum.babylonjs.com/t/i-am-using-scene-optimizer-for-performance-improvement-but-it-reduces-the-glow-layer-intensity-from-the-scene/52101
- https://forum.babylonjs.com/t/hdr-texture-rotation-with-scene-performance-priority/52005

#### Shader compilation stalls

Babylon uses KHR_parallel_shader_compile where available, so compilation is asynchronous by default. Practical rules from forum threads:

- To force synchronous compilation (for example before a screenshot), set `engine.getCaps().parallelShaderCompile = undefined` (forum variants also use null). Otherwise use `scene.executeWhenReady` before the first frame that must be clean.
- `material.forceCompilation(mesh)` recompiles a single material. Use it during a loading screen to pre-warm every material the first battle needs, so the first volley does not hitch on a compile.
- On WebGPU, custom GLSL is translated by WebAssembly builds of glslang and TWGSL fetched from Babylon's CDN on first use. That is a startup cost to self host or avoid by authoring in WGSL.

- https://forum.babylonjs.com/t/screenshots-using-custom-ifdef-block-within-a-pbrcustommaterial/42144
- https://forum.babylonjs.com/t/when-is-customshadernameresolve-called/36783
- https://forum.babylonjs.com/t/help-understanding-webgl-extension-mechanism/24919

### 4. Particles and effects

#### Three systems, three jobs

- ParticleSystem (CPU): the behavior rich system. Emitter shapes are point, box, sphere, cone and cylinder. Key properties are `emitRate`, `manualEmitCount` for one shot bursts (which disables emitRate), `minLifeTime` and `maxLifeTime`, `minSize` and `maxSize`, `color1`, `color2` and `colorDead` gradients, `preWarmCycles` to avoid a first frame pop, `disposeOnStop` for one shot systems, and sub-emitters that spawn a second system when a particle dies. Blend modes are `BLENDMODE_ONEONE` (additive, the default, right for fire, sparks and beams) and `BLENDMODE_STANDARD` (alpha blend, right for smoke).
- GPUParticleSystem: the same API on the GPU under WebGL2, falling back to ParticleSystem automatically where WebGL2 is unavailable. Prefer it for continuous volume like engine exhaust and ambient battlefield dust.
- Solid Particle System: one mesh, one draw call, particles with normals and lighting. Disable the compute flags you do not update (`computeParticleRotation`, `computeParticleTexture`, `computeParticleColor`, `computeParticleVertex`) to cut per frame work, and freeze the SPS mesh world matrix when it is static.

Sprite sheets animate a particle's picture through `isAnimationSheetEnabled`, `startSpriteCellID` and `endSpriteCellID`, reading cells from one shared texture. The standard glow sprite is a small canvas radial gradient dot, white center fading to transparent.

- https://www.webcodingcenter.com/babylon-js/particles--sub-emitters-and-particle-animation.html
- https://www.webcodingcenter.com/babylon-js/particles--emitter-shapes-and-particle-textures.html
- https://gamedevacademy.org/how-to-create-particle-systems/
- https://grideasy.github.io/tutorials/Solid_Particle_System

#### Beams, shields and glow construction

No dedicated beam primitive surfaced in this pass, so the construction pattern is assembled from verified pieces rather than copied from one example:

- Beam core: a thin stretched cylinder or box between muzzle and target, additive blending, emissive material, inside the GlowLayer for the halo. Fade by scaling alpha and length over a few frames, then dispose. Pool beam meshes and reuse them.
- Shield hit: a short lived particle burst at the impact point plus a flash on the shield bubble mesh (a fresnel rim Node Material or a scaled emissive pulse), with the bubble itself as a separate mesh so the GlowLayer can include it without glowing the whole hull.
- Explosion: a ParticleSystem burst with a sub-emitter puff on particle death, exactly the pattern in the sub-emitter walkthrough, plus one SPS debris chunk set for capital kills.
- Particle capacity is fixed at construction, so size systems for the biggest battle. On phones, halve capacities and drop sub-emitters first; the optimizer's ParticlesOptimization step does this automatically if enabled.

The Node Particle Editor (npe.babylonjs.com) authors particle systems as graphs and saves them as JSON or snippet, the same self hosting rule as Node Materials.

### 5. Debugging and inspection

#### Inspector, Spector and profiling

- The Inspector opens with `scene.debugLayer.show()` and, in the Playground, with Ctrl Alt Shift I. It is not bundled with the engine: it downloads on first use (a third party measurement put the bundle at about 2.27 MB). The Statistics tab shows frames per second, draw calls, active meshes and shader compilation capability. A 9.32.0 release note adds Inspector Lite with debug helpers and capture tools for lighter weight inspection.
- Spector.js is the Babylon team's WebGL capture tool (MIT, in the BabylonJS GitHub organization). The forum's standard advice for a performance mystery is a Spector capture, which reveals hidden passes and forgotten render targets.
- For frame timing, use SceneInstrumentation plus the browser devtools performance tab. `engine.getGlInfo()` reports the GL implementation, and shader errors surface through `getShaderInfoLog` and material `onError` callbacks.

- https://www.webcodingcenter.com/babylon-js/the-inspector-and-babylon-js-s-online-tools--opening-the-inspector-at-runtime.html
- https://www.webcodingcenter.com/babylon-js/the-inspector-and-babylon-js-s-online-tools.html
- https://gamedev.net/news/babylonjs-9320-released-r6628/

#### Disposal pitfalls, the memory leak checklist

This is the most repeated forum topic after performance, and it maps directly onto a game that loads and unloads many hulls:

- `mesh.dispose()` does not free textures. `material.dispose(true, true)` disposes its textures. `mesh.dispose(true, true)` disposes recursively and forces material and texture disposal, but it will also kill materials and textures shared with other meshes, so never use it on a mesh whose material is shared.
- Skeletons are not disposed with their mesh because they can be shared. Dispose them explicitly with `mesh.skeleton.dispose()`.
- When a texture is disposed, set the material slot that referenced it to null, or the material keeps a dead reference. `scene.onTextureRemovedObservable` is the forum recommended hook for sweeping leftover references.
- Context lost handling caches CPU copies of textures so they can be rebuilt. That cache is a real RAM cost; `doNotHandleContextLost` removes it at the price of no automatic restore.
- On WebGPU, a Dawn quirk shares 4 MB heaps between small resources, so GPU numbers can look like a leak when they are heap reuse (Chromium issue 377410074). Verify by closing the tab.
- Render targets are the other silent allocator: GlowLayer, probes and shadow maps all allocate them. A probe at 256 pixel faces refreshing once is cheap; one refreshing every frame with a long render list is not.

- https://forum.babylonjs.com/t/dispose-doesnt-free-the-memory/10403
- https://forum.babylonjs.com/t/how-to-delete-the-loaded-gltf-and-babylon-files/7535
- https://forum.babylonjs.com/t/graphics-memory-problem-of-rendertargettexture-in-webgpu/54477
- https://forum.babylonjs.com/t/procedural-texture-memory-leak/53627

### 6. WebGPU

- Create the engine first, then the scene. `const engine = new BABYLON.WebGPUEngine(canvas, { antialias: true }); await engine.initAsync();` then `new BABYLON.Scene(engine)`. A scene cannot move to another engine afterwards, so the backend decision must happen before any scene resource exists.
- Feature detect properly: `navigator.gpu` can exist with no adapter behind it, so use `await BABYLON.WebGPUEngine.IsSupportedAsync`, falling back to `new BABYLON.Engine(canvas, true)` in a try catch around init.
- Guard backend specific choices with `engine.isWebGPU`. Core engine shaders exist in WGSL; a Node Material generates GLSL unless its `shaderLanguage` is set to WGSL, and custom GLSL is translated by WebAssembly glslang and TWGSL fetched from Babylon's CDN on first use (self hostable through the glslang and twgsl options).
- WebGPU only features worth knowing: `ComputeShader` for GPU compute work, and snapshot rendering (`engine.snapshotRendering = true`), which records one frame's draw calls and replays them. Snapshot rendering saves JavaScript submission time, not GPU time, so it helps CPU bound scenes and does nothing for a GPU bound battle.
- Phone note: WebGPU availability on mobile browsers is uneven, so the WebGL fallback must stay tested, not just present. Do not ship a WebGPU only build while the phone is the reference device.

- https://www.webcodingcenter.com/babylon-js/the-engine-the-scene-and-the-render-loop--feature-detecting-and-falling-back-from-webgpu-to-webgl.html
- https://www.webcodingcenter.com/babylon-js/the-engine-the-scene-and-the-render-loop--webgpuengine-versus-engine.html
- https://forum.babylonjs.com/t/playground-engine-question/26498

### 7. Real projects

- The engine itself is the best readable codebase: BabylonJS/Babylon.js on GitHub, Apache 2.0, TypeScript, with Playground examples and the Demos section as the pattern library. When a pattern is unclear, the engine source and a Playground reproduction beat a tutorial.
- Shell Shockers, the Blue Wizard Digital browser FPS, runs on Babylon.js and passed 200 million lifetime players. It is closed source, so the lesson is scale proof, not code. Mobile versions existed until their shutdown in 2024.

- http://babylonjs.com/games/
- https://en.wikipedia.org/wiki/Shell_Shockers

- The Babylon.js Editor is a community managed desktop application (Apache 2.0, around version 5.5), available for Windows, macOS and Linux, with built in project templates. It exports .babylon scenes and integrates with VSCode for script debugging. For Voidsworn it fits the "beauty corner" role: a scene tool for proving a look, not a replacement for the code driven game pipeline.

- https://www.webcodingcenter.com/babylon-js/the-inspector-and-babylon-js-s-online-tools.html

- Spector.js, the frame capture tool, is MIT licensed and lives in the BabylonJS GitHub organization.

### What could not be verified in this pass

- A dedicated beam primitive or canonical beam Playground example: no page opened in this pass showed one, so the beam construction above is assembled from verified pieces (additive mesh, GlowLayer, particle burst) and is marked as such rather than presented as a copied example.
- The current official DefaultRenderingPipeline documentation page: the doc search returned the deprecated standard pipeline page, which was opened and verified, while default pipeline details rest on forum threads and a third party walkthrough. Treat the HDR and AA rules as forum confirmed, not doc page confirmed.
- Spector.js current install and usage details beyond forum mentions and its organization listing.
- Several entries rest on webcodingcenter.com, a third party guide that restates official behavior with worked examples, rather than on doc.babylonjs.com itself. Those entries are labeled third party above. The engine API names and forum threads are independently verified.

## Part 3: Pipeline glue tooling

The boring half of the asset pipeline: the commands that turn Blender output into files a browser game can actually ship, and the checks that stop bad data reaching the player. Written for a Windows PC build (PowerShell 5.1, double click .bat launchers) feeding a Babylon.js game with phone and desktop asset tiers.

### 1. gltfpack and meshoptimizer

gltfpack (Arseny Kapoulkine, MIT licence) is the single most valuable tool in this whole section. It reorders meshes for vertex and transform cache efficiency, quantizes geometry, merges meshes to cut draw calls, resamples animations, prunes redundant nodes, and optionally simplifies and compresses. Native binaries are recommended over the npm package: they handle larger files, run faster, and support texture compression.

```
gltfpack -i scene.gltf -o scene.glb
```

The flags that matter for this pipeline:

- `-cc`: produce compressed output with EXT_meshopt_compression. Pair it with gzip or brotli on the server: meshopt output is designed to compress further, and without that second pass much of the gain evaporates. `-c` is the lighter variant; `-cf` adds an uncompressed fallback for loaders without WebAssembly support.
- `-si 0.8`: simplify to 80 percent of the original triangle count (0 to 1). `-sa` simplifies aggressively, ignoring quality. Simplification is the only step here that improves framerate; compression only shrinks downloads.
- `-mi`: serialize repeated mesh references with EXT_mesh_gpu_instancing. `-mm` merges instances of the same mesh instead. For a fleet game with many copies of one hull, `-mi` is the obvious first try.
- `-kn`: keep named nodes and meshes attached to named nodes, so the game can still move parts by name after optimization. Without it, gltfpack merges and renames freely. `-km` keeps named materials and disables material merging. `-ke` keeps extras data.
- `-tc`: convert all textures to KTX2 with BasisU supercompression (needs KHR_texture_basisu). `-tu` switches the texture codec to UASTC (higher quality, larger files). `-tq 8` sets texture quality 1 to 10, default 8. `-ts 0.5` scales texture dimensions by a ratio. `-tp` rounds textures to the nearest power of two for WebGL 1 compatibility. `-tw` converts textures to WebP instead (needs EXT_texture_webp).
- Quantization controls: `-vp 14` position bits (1 to 16), `-vt 12` UV bits, `-vn 8` normal and tangent bits, `-vc 8` color bits. Defaults are sane; raise `-vp` only if small parts visibly snap.
- `-r report.json`: write a JSON report of what changed. Wire this into the build log so a bad optimization is visible before it ships.
- `-noq`: disable quantization entirely. Useful as a debug escape hatch, not a shipping setting.

A sensible starting recipe for a hull, run twice with different simplification and texture scale for the two tiers:

```
gltfpack -i hull.gltf -o hull_hi.glb -cc -mi -kn -ke -r hull_hi.json
gltfpack -i hull.gltf -o hull.glb -cc -mi -kn -ke -si 0.6 -ts 0.5 -r hull.json
```

Draco versus meshopt, the honest tradeoff: Draco (KHR_draco_mesh_compression) often produces the smallest geometry files but decodes more slowly, and at least one Babylon forum user reported iPhone problems with Draco that made them switch. Meshopt decodes much faster, and its size is close to Draco once gzip is applied on top. Meshopt is also lossy: repeatedly compressing and decompressing a model loses precision, so compression must be the last stage of the pipeline and uncompressed originals must be kept. Babylon.js supports KHR_mesh_quantization from 4.1 and EXT_meshopt_compression from 5.0 without extra setup. Note that gltfpack does not support Draco at all and discards unknown extensions, so a Draco workflow means gltf-transform or the Blender exporter instead, not gltfpack.

Sources: https://meshoptimizer.org/gltf/ , https://manpages.debian.org/testing/gltfpack/gltfpack.1 , https://gltf-transform.dev/modules/extensions/classes/EXTMeshoptCompression , https://forum.babylonjs.com/t/simplify-reorder-quantize-and-compress-meshoptimizer-babylon-sandbox/52034

### 2. Texture compression tooling: KTX2, basisu, toktx

A 1K JPEG expands to about 5.6 MB of video memory as raw RGBA. Block compressed formats are sampled directly by the GPU, but no single format runs everywhere, so Basis Universal stores an intermediate in a KTX2 file that is transcoded at load time to whatever the GPU supports. ETC1S is tiny but blocky; UASTC is larger and near lossless. In glTF they arrive through KHR_texture_basisu.

Two encoders, one job:

- `ktx` (KTX-Software, Khronos, Apache 2.0): the modern CLI. Typical commands, verified against the Khronos migration guide and a Babylon worked example:

```
ktx create --format R8G8B8A8_SRGB --assign-tf srgb --generate-mipmap --encode basis-lz texture.png texture-etc1s.ktx2
ktx create --format R8G8B8A8_SRGB --assign-tf srgb --generate-mipmap --encode uastc --zstd 18 texture.png texture-uastc.ktx2
ktx create --format ASTC_4x4_SRGB_BLOCK texture.png texture-astc.ktx2
ktx create --format BC7_SRGB_BLOCK texture.png texture-bc7.ktx2
ktx info texture.ktx2
```

Use linear transfer function, not sRGB, for normal, roughness and metallic maps.

- `basisu` (Binomial, Apache 2.0): the original Basis Universal CLI. Example for a high quality UASTC encode:

```
basisu -xuastc_ldr_6x6 -quality 75 -effort 4 texture.png
```

Quality runs 1 to 100, effort 0 to 10 with 3 the default. XUASTC block sizes 4x4, 6x6 and 8x6 transcode directly to BC7, skipping an encode step, which makes them good defaults for a desktop tier.

Wiring it into a build: gltf-transform's `etc1s` command calls `ktx` per texture of a whole model, so `gltf-transform etc1s in.glb out.glb` is the one command version of the pipeline. Or let gltfpack do it with `-tc` in the same pass as geometry optimization. Either way, encode at build time, never at runtime: encoding is far too slow for the browser.

On the Babylon side, `new BABYLON.Texture(url, scene)` accepts .ktx2 URLs directly and fetches the transcoder from Babylon's CDN by default. For a self contained game, override `KhronosTextureContainer2.JSModuleURL` to point at a local copy of `babylon.ktx2Decoder.js`; the WASM modules are then grabbed from the same location. Forum reports confirm relative paths do not work here because the worker is created from a blob URL, so use an absolute path. The `@babylonjs/ktx2decoder` package also supports a worker pool setup for parallel transcoding.

Sources: https://docs.vulkan.org/tutorial/latest/15_GLTF_KTX2_Migration.html , https://binomialllc.github.io/basis_universal/ , https://www.webcodingcenter.com/babylon-js/loading-gltf-and-the-asset-container--ktx2-and-basis-universal-texture-compression.html , https://forum.babylonjs.com/t/load-ktx2-de-transcoder-from-own-server/30324/2

### 3. Effekseer to Babylon: two routes, no official bridge

Effekseer (MIT licence) is the particle authoring tool the field guide already recommends. Getting its effects into a Babylon game has two honest routes, and no official Babylon plugin exists, so do not plan around one.

Route A: EffekseerForWebGL. This is a community build that compiles the Effekseer C++ engine to WebAssembly (effekseer.wasm plus effekseer.core.js and the effekseer.js API wrapper, with a minified production build). It renders Effekseer effects in a WebGL context, driven from JavaScript through wrapped functions like EffekseerInit, EffekseerUpdate and EffekseerDraw, with texture and binary loading handed back to JavaScript callbacks. The catch for this game: it is its own renderer, not a Babylon particle system, so compositing it with a Babylon scene means either a second canvas layered over the first or rendering into the same context by hand. Workable for full screen overlays and background bursts, awkward for particles that must sit inside the 3D board and occlude correctly.

Route B: bake to flipbooks, and let Babylon play them. Effekseer can export an effect as an image sequence; pack the frames into a sprite sheet (see section 7) and drive it with Babylon's own particle system or billboarded planes. This loses live parameter tweaking but gains correct depth, sorting and batching inside the scene, and the flipbook is a plain texture the KTX2 pipeline already handles. For a tactics game whose effects are mostly explosions, muzzle flashes and engine trails, route B is the pragmatic default, with route A reserved for a showcase effect if compositing proves clean.

Alternatives for baking flipbooks: Blender's own particle system rendered to an image sequence, or a small script that renders one effect frame per Blender frame and stitches the PNGs. Either way the flipbook, not the live effect, is what ships.

Sources: https://deepwiki.com/effekseer/EffekseerForWebGL , https://deepwiki.com/effekseer/EffekseerForWebGL/3.3-javascript-processing-pipeline

### 4. Audio tooling: generate in code, compress in batch

Two layers, matching the field guide's sound findings.

Generate: ZzFX (KilledByAPixel, MIT licence) is a tiny JavaScript synth, under 1 KB compressed, with 20 parameters per sound and no audio files at all. A sound is one function call with a parameter array, for example `zzfx(...[,,129,.01,,.15,,,,,,,,5])` for a drum hit. The ZzFX sound designer web app lets a non coder shape sounds and copy the arrays out, and the Playdate port confirms sounds can also be saved as WAV files from the designer interface for shipping. ZzFXM, by Keith Clark, adds tiny sequenced music on the same engine. The cleanest pipeline for UI and light weapon sounds is: design in the web app, paste the parameter arrays into a sounds table in the game code, and ship zero audio files for that layer. Per faction variants are parameter tweaks, not new assets.

Compress: everything that is a real recording (Sonniss bundles, Freesound grabs) goes through ffmpeg (GPL/LGPL depending on build) in batch. The Windows command prompt loop, which also works inside a .bat file with doubled percent signs:

```
for %f in (*.wav) do ffmpeg -i "%f" -c:a libvorbis -q:a 5 "%~nf.ogg"
```

In a .bat file that becomes `for %%f in (*.wav) do ffmpeg -i "%%f" -c:a libvorbis -q:a 5 "%%~nf.ogg"`. Vorbis quality 5 lands around 160 kbps nominal and roughly halves a typical MP3 source; quality 3 is the voice and UI tier. Fold positional sounds to mono (`-ac 1`) while converting, since stereo buys nothing for a sound placed in 3D. For music, Opus (`-c:a libopus -b:a 96k`) beats Vorbis at the same size, but ship both .ogg and .mp3 for any track that must play everywhere: dual format fallback is the standard safe pattern, and the game picks the first format the browser reports it can play.

Sizes to plan around: a one second UI blip at Vorbis quality 3 is a few kilobytes; a three minute music track at Opus 96k is about 2 MB. Batch conversion of a whole folder is one command, so there is no excuse for hand converting files one at a time.

Sources: https://github.com/KilledByAPixel/ZzFX , https://www.skypack.dev/view/zzfx , https://copyprogramming.com/howto/how-to-make-a-ffmpeg-mp3-to-ogg , https://thefreeconverter.com/blog/mp3-to-ogg-for-games

### 5. Batch scripting on Windows: Blender headless inside a .bat

The core pattern, verified against the Blender command line docs and a glTF converter tutorial: Blender runs headless with `-b`, runs a Python script with `-P`, and arguments after `--` go to the script, not to Blender.

```
blender -b hull.blend -P export_hull.py -- --out hulls\hull.gltf
```

Inside export_hull.py, `bpy.ops.export_scene.gltf` does the export, and every export parameter is settable from the script, so the script is the reproducible definition of the export, not whatever the artist last clicked in the GUI. Useful extras: `-y` (or `--enable-autoexec`) lets drivers and scripts run in background mode; `--factory-startup` makes the run independent of the artist's user preferences, which is the single most important flag for reproducibility; `--log-file build.log` plus output redirection captures failures instead of losing them to a closed console window. Argument order matters: the .blend file must come before `--python`, or Blender runs the script and then opens the file.

A .bat skeleton for one hull, with the failure behavior that matters (stop on first error, write to a temp file and rename only on success, so a crashed run never leaves a half written asset):

```
@echo off
setlocal
set BLENDER=C:\Program Files\Blender Foundation\Blender 4.5\blender.exe
set HULL=%1
"%BLENDER%" -b --factory-startup "blend\%HULL%.blend" -P tools\export_hull.py -- --out "build\%HULL%.gltf" > "logs\%HULL%.log" 2>&1
if errorlevel 1 ( echo FAILED: %HULL% & exit /b 1 )
gltfpack -i "build\%HULL%.gltf" -o "build\%HULL%_tmp.glb" -cc -mi -kn -ke
if errorlevel 1 ( echo FAILED gltfpack: %HULL% & exit /b 1 )
move /y "build\%HULL%_tmp.glb" "game\hulls\%HULL%.glb"
echo OK: %HULL%
```

The write to temp and rename pattern is borrowed from blender-batch-renderer (MIT), which also documents why it writes frames to temporary names first: a crash must never leave a broken frame that looks finished. The same logic applies to assets. A PowerShell 5.1 loop over a hull list reads the same way:

```
$hulls = Get-Content hulls.txt
foreach ($h in $hulls) { & .\BUILD_HULL.bat $h; if ($LASTEXITCODE -ne 0) { throw "Build failed: $h" } }
```

Keep every tool on PATH or referenced by absolute path at the top of the script, and pin tool versions in a tools README: a build that silently changes because gltfpack updated is a build that cannot be reproduced.

Sources: https://javagl.github.io/glTF-Tutorials/BlenderGltfConverter/ , https://docs.polygoniq.com/renderset/1.8.0/advanced_topics/headless_rendering/ , https://github.com/GermanCGArtist/blender-batch-renderer

### 6. Versioning and data checks: schema validation and reference checkers

Two layers again: shape validation (is this file well formed) and reference validation (do the ids it mentions actually exist). The second layer is the one that catches save breaking renames.

Shape validation with AJV, the standard JSON Schema validator (MIT). The aquaproj registry action shows the canonical pattern, and it runs in GitHub Actions: install ajv-cli, then `ajv --spec draft2020 -s registry.json -d registry.yaml`, which exits non-zero on failure and blocks the change. The json-schema-org community repo shows the same pattern as a path scoped workflow: checkout, set up Node 20, `npm install ajv ajv-formats`, run an inline Node script that compiles the schema with `allErrors: true` and exits 1 on any error, triggered only when the data file itself changes. For this game the direct translation is: one schema per data file (hulls, weapons, admirals, boons), one `ajv validate -s schema.json -d data.json` per file, run as a .bat step before any build, and the same command wired into a GitHub Actions workflow scoped to the data paths.

Reference validation is a small custom script, not a schema feature: load every data file, collect every id, then walk every reference (a hull's weapon ids, an admiral's command ids, a save file's hull ids) and fail loudly on a dangling one. The model is RPFM's broken key diagnostics for Total War tables, and the field guide's own rule: a checker lives in the build. The strongest version of this check for this game is a save compatibility test: keep one golden save from each shipped version, and fail the build if the current data cannot load it. That test is the Endless Sky deprecated ships file, automated.

For the meshes themselves, the Khronos glTF Validator (Apache 2.0, on npm as gltf-validator) validates a .glb or .gltf against the spec and reads mesh data for errors like non-normalized normals and inaccurate bounding volumes, which plain JSON schema validation cannot see. It is a library, not a CLI: `validator.validateBytes(new Uint8Array(asset))` returns a report object, so wrap it in a ten line Node script and call that from the .bat. Run it after gltfpack, on the shipped file, not the Blender export.

Sources: https://deepwiki.com/aquaproj/registry-action/3.3-validate-json-schema-action , https://deepwiki.com/json-schema-org/community/4.1-ambassadors-program , https://socket.dev/npm/package/gltf-validator/overview/2.0.0-dev.3.10

### 7. Extra free tools that fit this pipeline

- FreeTexturePacker (odrick, free): packs sprite sheets from folders of PNGs with rotation, trimming and multipacking, exporting JSON, XML, CSS and Phaser, Godot and Cocos2d formats. Desktop builds for Windows, Mac and Linux plus a web version, and a CLI package for scripted builds. This is the flipbook packer for section 3 and the UI atlas packer in one tool.
- ShoeBox (free): a collection of small game dev tools including a drag and drop sprite sheet builder that outputs a packed PNG plus an XML descriptor. Less scriptable than FreeTexturePacker, faster for one off sheets.
- So2K TexturePacker (web app, free): runs entirely in the browser with no uploads, and its genuinely useful trick is channel packing: assign maps to R, G, B and A channels, and build texture atlases on a grid up to 20 by 20. That channel packing step is exactly how a Halo style multipurpose map gets built without Photoshop.
- Babylon Sandbox (free, Babylon.js): drag a .glb in and see it with the real engine, including the meshoptimizer simplification, reorder, quantize and compress tools built into the Sandbox itself. The fastest visual check that an optimization did not break a hull, and the forum thread on it confirms both KHR_mesh_quantization and EXT_meshopt_compression are supported by the Babylon loader.
- gltf.report (free, open source): a browser based glTF editor and inspector for poking at a file's structure without Blender. Good for answering "what did gltfpack actually do to my nodes" questions.
- TexturePacker (codeandweb, paid perpetual licence with an indie discount): the commercial alternative if FreeTexturePacker ever falls short, notably for polygon outline trimming that reduces overdraw. Flagged as paid, not free.

Sources: https://deepwiki.com/odrick/free-tex-packer , https://axolstudio.com/articles/2023-07-23-tims-tips-1-texture-packing-sprites/ , https://github.com/So2K/TexturePacker , https://forum.babylonjs.com/t/simplify-reorder-quantize-and-compress-meshoptimizer-babylon-sandbox/52034

## Part 4: AI meshes and local image models

Written for Opus. Context: the 36 hull meshes in this game were AI generated, and they read as blocky and plain in places (side gun housing boxes, side gun tanks, front armour slabs, engine block). The concept plates and admiral portraits were made with a local image model on the owner's RTX 5080 PC (16 GB VRAM, PowerShell 5.1, double click .bat launchers). This section covers how to turn AI output into game assets instead of starting over, and how to keep the local image model in the loop for textures and style.

### 1. What an AI mesh actually is

Every generator below produces the same class of object: a dense, uneven triangle soup with baked appearance and no notion of parts. A gun housing, a tank and a slab are not separate objects with names; they are bumps in one fused surface. Expect these defects on sight:

- Non-manifold edges, holes, zero-area faces, disconnected floaters, and internal shells the camera never sees.
- Uneven triangle density: huge flat areas carry thousands of triangles while sharp details are mush.
- Bad or missing UVs: auto-generated UVs overlap, stretch, or cover only part of the surface, so a painted texture lands in the wrong place.
- Baked lighting in the texture: shadows and highlights painted into the colour map, which then double up under the game lights.
- No LOD, no part separation, no named hardpoints. Nothing in the file knows where a gun mount is.

The pipeline in this section exists because of that list. Never feed a raw AI mesh straight into the game build. The mesh is a high-poly source, not a finished asset.

### 2. AI mesh generators: open tools

#### Microsoft TRELLIS and TRELLIS.2

TRELLIS is a large 3D asset generation model from Microsoft Research. The original (December 2024) takes text or image prompts and outputs meshes, radiance fields, or 3D Gaussians from a unified structured latent representation, trained on 500K objects with models up to 2B parameters. Its install notes call for 16 GB or more of GPU memory. TRELLIS.2 (December 2025) is a 4B parameter image-to-3D model that outputs a single PBR-ready GLB with base colour, roughness, metallic and opacity at up to 1536 cubed resolution, in about 3 seconds at 512 cubed and about 60 seconds at 1536 cubed on an H100. It handles open surfaces and non-manifold geometry by design, which is a strength for generation and a warning for cleanup: the output is allowed to be non-manifold, so the gates in section 4 still apply. TRELLIS.2 needs 24 GB VRAM and Linux per its own documentation, so it does not fit comfortably on the owner's 16 GB card; use it through a hosted demo or API, or stick to the original TRELLIS at lower settings.

- Study: https://microsoft.github.io/TRELLIS/
- TRELLIS.2 repo: https://github.com/microsoft/TRELLIS.2
- Licence: MIT for TRELLIS.2, including commercial use, per its documentation. Some dependencies (nvdiffrast, nvdiffrec) carry their own licences. Licence summary: https://deepwiki.com/microsoft/TRELLIS.2

#### TripoSG and TripoSR (VAST AI Research)

TripoSG is a 1.5B parameter image-to-3D foundation model built on rectified flow transformers with an SDF-based VAE, trained on 2 million curated image-to-SDF pairs. It needs a CUDA GPU with more than 8 GB VRAM, so it fits the 16 GB card. Its smaller sibling TripoSR is a fast single-image reconstruction model that runs on a consumer GPU and even has a CPU mode, and it is explicitly MIT licensed for code and weights, including commercial use.

- Study: https://huggingface.co/VAST-AI/TripoSG and https://www.tripo3d.ai/blog/vast-open-source-month
- TripoSR licence: https://triposr.org/open-source
- Licence flag: TripoSG's weights and inference code are open sourced by VAST, but this pass could not verify a specific licence text for TripoSG itself. Read the LICENSE file in the TripoSG repo before shipping anything made with it. Do not assume TripoSR's MIT terms carry over.

#### OpenAI Shap-E

Shap-E generates the parameters of implicit functions from text or image prompts, rendered as textured meshes or radiance fields. It is old by this field's standards and its outputs are low resolution with missing detail. It is fully local.

- Study: https://github.com/openai/shap-e (repo name; see the search results for the project page)
- Licence: MIT, including commercial use.

#### DreamGaussian

DreamGaussian is a generative Gaussian splatting framework that produces a textured mesh in about 2 minutes from a single image, roughly 10 times faster than the score distillation methods it replaced, by converting Gaussians to a mesh and refining texture in UV space. It is the clearest proof that a Gaussian or splat output still needs a mesh extraction and texture refinement stage before it is a game asset.

- Study: https://arxiv.org/html/2309.16653v2 and https://github.com/dreamgaussian/dreamgaussian
- Licence: research code; check the repo LICENSE before shipping. This pass did not verify a commercial use statement for DreamGaussian, so treat it as a prototyping tool until checked.

#### Hunyuan3D 2.1 (Tencent, noted with caution)

Hunyuan3D 2.1 is included because its paint pipeline (section 6) is the most complete open mesh texturing system found, and its meshes are described as holeless with a dedicated PBR paint stage and multi-view input. Its full pipeline is reported to need about 29 GB VRAM, and its community licence is reported to exclude the EU, UK, and South Korea. Both points are secondhand (a comparison article, not the licence text), so verify both before adopting it. On a 16 GB card it is a hosted or API tool, not a local one.

### 3. AI mesh generators: hosted tools

Hosted tools trade control for convenience, and their licences are tiered. Read the tier, not the headline.

#### Meshy

Meshy 7 generates image-to-3D in about a minute with a dedicated texturing pass producing PBR maps, exports GLB, FBX, OBJ, USDZ, STL, BLEND, 3MF and DXF, and lets paid users set a target polygon count and choose triangle or quad topology. Free tier outputs are licensed CC BY 4.0: commercial use is allowed with attribution to Meshy, in the form "Model created with Meshy, CC BY 4.0 License". Paid plans grant full ownership with no attribution. Free tier assets are also public, so never prototype an unannounced design on the free tier.

- Study: https://help.meshy.ai/en/articles/9992001-can-i-use-meshy-assets-commercially-license-copyright-explained and https://www.meshy.ai/features/image-to-3d
- Licence: CC BY 4.0 free tier, full ownership paid tier. No provider warrants that an output is free of third-party IP, so never feed in copyrighted characters or logos.

#### Hyper3D Rodin

Rodin (Gen-2.5) is quality-first, with image-to-3D, multi-image input, a Smart Low-Poly mode, HD textures, baked normals, and GLB export. Its export page states that resources are provided under CC BY-NC-SA 4.0 unless a commercial licence is purchased, while the Business plan (about $120 per month in older reporting) carries an any-use licence. The tiers matter more here than at Meshy: a free tier model is not shippable in a commercial game without the commercial licence.

- Study: https://dev.to/meiferreira/hyper3d-rodin-review-2026-i-tested-the-free-ai-3d-generator-end-to-end-5a6d
- Licence: CC BY-NC-SA 4.0 on the free path per the export page; any-use licence on Business. Verify current terms at signup, since pricing reporting for this product varies by year.

#### Luma Genie

Genie exports OBJ, FBX, GLB and USDZ and is consistently described as best for concept prototyping, with retopology, UV mapping, or mesh cleanup needed before production quality. Paid tiers list commercial use; the free tier's terms are not documented on the pricing page, so treat free tier outputs as unconfirmed for shipping.

- Study: https://lumalabs.ai/legal/enterprise-terms-of-service and https://thetoolsverse.com/tools/genie-lumalabs
- Licence: paid tiers include commercial use per third-party pricing reporting; free tier unconfirmed. Check at signup.

### 4. The cleanup pipeline: AI mesh to game mesh

This is the core workflow. It is the same sequence in every cleanup guide found, and it is what turns the existing 36 hulls from sources into shippable assets.

1. **Audit before touching anything.** Import the mesh, delete nothing yet, and run Blender's 3D Print Toolbox (a bundled extension in current Blender, installed from Edit, Preferences, Get Extensions) with Check All. Record non-manifold edges, holes, loose geometry, intersections, degenerate faces, and thin faces. Export the raw import as a rollback file before any repair step.
2. **Repair manifold issues, on a copy.** In Edit Mode: Mesh, Clean Up, Merge by Distance with a small distance (0.001 m is the commonly cited value) to weld duplicate vertices without collapsing detail, then delete loose geometry, then Mesh, Normals, Recalculate Outside (Shift+N). For what remains, use the toolbox's Make Manifold, but note its own manual warning: it attempts fixes by filling holes and removing edges, and it can delete or invent geometry. Run it on a saved copy and diff the result against the original, especially on surfaces that are meant to stay open.
3. **Control polygon count, protecting the silhouette.** For hulls that are never rigged, apply a Decimate modifier and reduce the ratio while watching the silhouette in the viewport, not the triangle count. For anything that will deform, use retopology instead: RetopoFlow or Quad Remesher for a quad-based mesh over the decimated form. Hard-surface rule from the guides: for blocky AI forms, manually remodel the key detail areas (gun housings, tanks, slabs) using the AI mesh as a guide, rather than retopologising mush. That is exactly the kit approach: the AI hull supplies the big form, hand-built kit parts supply the readable detail.
4. **UVs.** After any retopology or decimation, re-unwrap. Smart UV Project is acceptable for simple forms; complex hulls need hand-marked seams. Check for overlap in the UV Editor and check UV coverage: a hull whose UVs cover only part of the texture space will show stretched or missing paint.
5. **Bake high to low.** Keep the original dense mesh as the bake source and the cleaned mesh as the target. Bake normal, ambient occlusion, and roughness from high to low so the cleaned hull keeps the surface detail the decimation removed. This is the step that makes a 2,000 triangle hull read like a 200,000 triangle one at game distance.
6. **Attach kit parts at landmarks, not coordinates.** Hand-built guns, tanks, and slabs mount onto the cleaned hull at named landmarks (bow mount, dorsal spine, flank hardpoint) recorded in the hull manifest, never at hand-measured coordinates per hull. The landmark set is what makes the kit reusable across all 36 hulls. After attachment, bake again so the kit parts share the hull's maps.
7. **Compress and ship.** Run the existing gltfpack and KTX2 step from the glue section of this guide set, with separate phone and desktop tiers. The phone tier is the gate: if a hull fails the phone budget, it goes back to step 3, not forward with a warning.

MeshLab is a free, open source alternative for the repair steps (Repair non-manifold edges and vertices, then Close Holes), useful for batching the audit across all 36 hulls without opening Blender by hand each time.

- Study: https://triverse.ai/blog/ai-3d-generation-troubleshooting, https://dev.to/mileswill/how-to-fix-a-broken-glb-from-an-ai-3d-generator-8bn, https://www.tripo3d.ai/blog/explore/ai-3d-model-generator-mesh-cleanup-as-a-postprocess-model, https://3dx.info/how-to-fix-non-manifold-edges-in-stl-files-for-flawless-3d-prints/

### 5. Quality gates: judge before it enters the queue

Run these gates on every hull before it is accepted. A hull that fails a gate goes back to the step named, it does not ship with a note.

- **Silhouette readability.** Render the hull flat black against white at the size it appears in game. If the faction and class do not read from the silhouette alone, the hull fails, regardless of texture quality. This is the game's own silhouette-sheet test, and it is the cheapest gate in the list.
- **Manifold and solid.** Zero non-manifold edges, zero holes, zero zero-area faces after step 2. The 3D Print Toolbox Solid check must pass.
- **No floaters.** No disconnected components except deliberately separate kit parts. Nested internal shells get deleted; they cost triangles and break baking.
- **Triangle budget.** Two numbers per hull, phone tier and desktop tier, set by the project. A hull over its phone budget fails; decimation is not optional polish.
- **UV coverage and overlap.** UV islands must cover the texture space without overlap, and the texture resolution must match the tier (a 4K map on a phone tier hull is waste, and it is the texture budget problem the asset inventory already flagged).
- **Baked lighting check.** The colour map must be flat-lit. If shadows are painted into the albedo, the hull will look wrong under every game light. Reject or re-texture (section 6) rather than compensating with material settings.
- **Reject on sight.** Melted or fused detail where a gun should be a separate readable part; mirrored or smeared text and insignia; asymmetric geometry on a hull that is supposed to be symmetric; texture seams running across the most visible face.

### 6. Local image models on a 16 GB card

The card is the constraint, so the table below is organised by what actually fits, not by what is newest. ComfyUI is the runner for all of these: node graph workflows, automatic GPU offloading, and the workflow embedded in every PNG it produces, so a result can be reopened as its own recipe. ComfyUI itself is GPL-3.0.

| Model | Size and fit on 16 GB | Licence in plain words |
| --- | --- | --- |
| Stable Diffusion XL 1.0 (3.5B, native 1024) | Comfortable. The recommended card for full performance is 16 GB. | CreativeML Open RAIL++-M. Commercial use allowed, no revenue cap, with use-based restrictions (no illegal or harmful use). |
| Stable Diffusion 3.5 Medium (2.5B) | Comfortable. | Stability AI Community Licence: free for organisations under $1M annual revenue; above that an Enterprise licence is required. |
| Stable Diffusion 3.5 Large (8B) | Tight. Runs with offloading and lower settings; expect slow iteration. | Same Community Licence and $1M threshold as Medium. |
| Qwen-Image (20B) | Only quantized. The FP8 edit model needs about 20 GB; the INT4 and NF4 quantized builds (Nunchaku, SDNQ) fit 16 GB, and the 4-step Lightning LoRA cuts steps sharply. | Apache 2.0, including commercial use. This is the cleanest licence in the image set and a real reason to standardise on it. |
| FLUX.1 schnell (12B) | Only quantized (GGUF or FP8 with offloading). Community guides report a quantized Flux base fitting 8 GB cards at 1024 with text encoder offloading, so 16 GB is workable but slow. | Apache 2.0, including commercial use. |
| FLUX.1 dev (12B) | Same quantized-only story as schnell. | FLUX.1 [dev] Non-Commercial Licence. See the warning below; do not build production assets on self-hosted dev. |
| FLUX.2 klein 4B | Fits comfortably; the 4B variants are the Apache 2.0 ones. | Apache 2.0 for the 4B klein variants. The 9B klein variants are gated under other terms. |
| FLUX.3 Image Klein | Check VRAM per the model card before adopting; it is newer than the other entries here. | FLUX Kommunity Licence v1.0: non-commercial and research, plus free commercial use for individuals and companies under $5M annual revenue. Not blanket permission for commercial fine-tuning or distribution. |

Flux dev warning, stated carefully because two sources disagree on the fine print: one licence survey reports that the v1.1 revision removed the line that allowed commercial use of generated outputs and now defines non-commercial purpose to exclude any use where payment arises from the outputs; another review holds that outputs themselves may be used commercially but running the dev model in revenue-generating activity needs a BFL commercial licence. Either reading blocks the same practical case: a shipped game built on self-hosted dev weights. The safe routes are FLUX.1 schnell (Apache 2.0), the 4B klein models (Apache 2.0), or images generated through BFL's own API, which carries commercial rights. A LoRA trained on a dev base inherits the dev restriction, so train style LoRAs on schnell or klein bases instead.

- Study: https://terms.law/ai-output-rights/stable-diffusion/, https://www.webcodingcenter.com/ai-image-generation/running-open-models-locally--stable-diffusion-sdxl-and-their-licenses.html, https://aifoss.dev/blog/open-weight-licences-that-block-commercial-use-2026/, https://www.bestfreewebresources.com/flux-lora-licence-guide-2026, https://7minai.com/news/flux-3-image-klein-open-weights-vram/, https://huggingface.co/nunchaku-tech/nunchaku-qwen-image, https://huggingface.co/drbaph/Qwen-Image-Edit-2511-FP8, https://en.wikipedia.org/wiki/ComfyUI

### 7. ComfyUI workflows for this game

#### PBR texture sets from a single image

Two routes, both verified as real workflows. First, CHORD: a ComfyUI graph that generates a tileable texture from text (prompt it flat-lit, orthographic top-down, seamless tiling), then runs a material estimation model that predicts base colour, normal, roughness, and metalness from that texture, plus a height map derived from the normal. Feed it an existing plate instead of text and it estimates the same set from the plate. Keep the input flat-lit and shadow free or the estimates inherit the baked light. Second, the Hunyuan3D paint pipeline: render the mesh from multiple views, run multi-view diffusion conditioned on a reference image and the geometric feature maps, bake the views onto the UVs with view-weighted blending, then inpaint the gaps the cameras never saw. Typical settings are view size 512, 10 to 15 steps, guidance 3.0, texture size 1024, with xatlas doing the unwrap. A newer option in the same family is UltraTex, which paints six views at once through a FLUX.2 Klein loader and bakes them back to the mesh's UVs, reported to peak around 6.8 GB VRAM in its low-VRAM build. UltraTex is recent (SIGGRAPH Asia 2026) and its ComfyUI nodes are community built, so treat it as promising but less proven than the Hunyuan paint route.

- Study: https://www.runcomfy.com/comfyui-workflows/chord-model-workflow-in-comfyui-pbr-material-generation, https://deepwiki.com/visualbruno/ComfyUI-Hunyuan3d-2-1/6.3-hunyuan3dpaintpipeline, https://gachoki.com/ultratex-ai-texturing-6gb-vram/

#### Consistency across a set: ControlNet, IPAdapter, LoRA

These three tools answer three different consistency problems, and the guides agree on which is which. ControlNet controls structure: Canny preserves edges, Depth preserves 3D structure, Tile preserves detail through upscaling, Reference matches style without a LoRA. IPAdapter controls appearance: it conditions generation on a reference image, so it is the tool for "make it look like this plate" across a batch, with strength around 0.3 for a hint, 0.6 for clear influence, and 0.9 to 1.0 for dominance. Use them together: ControlNet holds the composition, IPAdapter holds the look. VRAM note from a community guide: SDXL plus one ControlNet needs roughly 10 to 14 GB at 1024, which fits the 16 GB card; Flux plus one ControlNet needs roughly 20 to 22 GB, which does not, unless the base is GGUF quantized. For the game's faction paint problem, the concrete recipe is: render a flat orthographic view of the cleaned hull, run Depth plus a faction paint reference through IPAdapter, and let the result become the albedo source for the PBR estimation step above. The faction colour law (cyan means shields, nothing else is cyan) belongs in the prompt and in the reference image, not in a post-process fix.

For a whole set in one style, train a style LoRA with Kohya: 15 to 30 images is the commonly cited range for a style LoRA, 1024 square, captions that describe the content and let the style be learned implicitly, plus a unique trigger token that does not collide with existing vocabulary. Quality beats quantity: 20 sharp, varied images beat 75 inconsistent ones. SDXL LoRA training is usually quoted at 24 GB, but low-VRAM options (8-bit optimizers, gradient checkpointing, smaller batch) are standard community practice on 16 GB cards; expect slower training, not impossible training. A LoRA trained on the final plates is the durable version of the game's art direction: every future plate, portrait, or background goes through it, and the trigger token is what keeps the factions from drifting apart over a batch.

- Study: https://localaimaster.com/blog/comfyui-complete-guide, https://insiderllm.com/guides/controlnet-guide-beginners/, https://huggingface.co/nux1111/comfyui_controlnet_aux, https://localaimaster.com/blog/image-lora-training-local-guide, https://civitai.com/articles/21114/complete-lora-training-tutorial-civitai-kohya-runpod-and-colab-explained-step-by-step

#### Iteration, repair, and upscaling

Img2img is the iteration loop for a plate: keep the composition, change the prompt or the reference, denoise around 0.7 to 0.95 for meaningful change without losing the layout. Inpainting is the repair loop: mask a bad detail (a melted gun, a smeared insignia, a wrong-coloured panel), regenerate only the mask, and keep the rest. Use the dedicated inpainting checkpoint for the base model where one exists. Upscaling is the last step, not the first: Real-ESRGAN x4plus is the standard general upscaler and x2plus is the balanced choice for albedo, SwinIR-M x2 is cleaner for metallic-roughness maps (it introduces less noise), and BSRGAN handles normal map gradients well. Real-ESRGAN is BSD 3-Clause, so upscaling is licence clean. Upscale the albedo and the maps separately with the model suited to each, and never upscale a map with baked lighting still in it.

- Study: https://www.cgchannel.com/2022/08/check-out-open-source-ai-image-upscaler-real-esrgan/985/, https://deepwiki.com/visualbruno/ComfyUI-Hunyuan3d-2-1/4.5-advanced-texturing-with-metadata-and-upscaling

### 8. Merging the two: the full chain

#### Chain A: AI hull to game hull

AI mesh (any generator in section 2 or 3) to audit (3D Print Toolbox, rollback export) to manifold repair on a copy to decimation or retopology with silhouette checks to UV unwrap to high-to-low bake to kit parts attached at manifest landmarks to a second bake to the gltfpack and KTX2 step from the glue section, phone tier first. The hand-built kit is not decoration on top of the AI mesh; it is the mechanism that fixes the AI mesh's worst property (fused, unreadable detail) by replacing the detail areas with named, reusable parts.

#### Chain B: AI image to game texture

Reference plate or text prompt to ControlNet plus IPAdapter generation for the faction look to flat-lit albedo to CHORD or Hunyuan paint estimation (base colour, normal, roughness, metalness, height) to per-map upscaling to KTX2 compression to the Babylon PBR material. For portraits and backgrounds, the same chain stops at the image stage: LoRA plus IPAdapter for consistency, inpainting for repairs, Real-ESRGAN for the final resolution, and no PBR estimation needed.

Keep the two chains separate in the tooling (ComfyUI .bat for images, Blender .bat for meshes) and join them only at the bake step, where the image chain's output becomes the mesh chain's texture input. The local image model is the texture and style layer on top of a Blender-first mesh pipeline, because no image model fixes topology.

### 9. What could not be verified

- TripoSG's own licence text: open sourced by VAST, specific terms unverified. Check the repo LICENSE before shipping.
- DreamGaussian's commercial terms: research code, no commercial statement verified. Prototyping only until checked.
- Hunyuan3D 2.1's VRAM need (about 29 GB) and its community licence exclusions (EU, UK, South Korea): both secondhand from a comparison article, not the licence text.
- Luma Genie free tier terms: undocumented on the pricing page. Paid tiers list commercial use.
- Rodin pricing varies by reporting year; the CC BY-NC-SA free path statement comes from the export page as quoted in search results, not from a terms page opened in this pass.
- Flux dev licence fine print: two secondary sources disagree on whether outputs alone are commercially usable under the v1.1 text. The recommendation (use schnell, klein 4B, or the BFL API for production) is safe under either reading.
- LoRA training VRAM on 16 GB: community practice, not a vendor guarantee. Expect slow training with 8-bit optimizers and gradient checkpointing.
- UltraTex: recent and community noded. Promising, less proven than the Hunyuan paint route.
