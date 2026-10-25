# Job C doc verification note (chair, Oct 25, 2026)

Scope: the doc claims the Job C synthesis left as re-check items (synthesis conditions 3 and 4). This note checks them against the primary docs directly. It changes no synthesis verdict on its own; Opus applies what it confirms. The remaining code greps and spike runs are Opus's, listed at the end.

## Babylon 9.0.0 question: RESOLVED, no 9.0.0 breaking entries on either page

The Job C synthesis left this OPEN because its two legs consulted different pages. Both pages were read directly on Oct 25, and the legs' disagreement is now resolved, not split:

- Breaking Changes page (https://doc.babylonjs.com/breaking-changes/): there is NO 9.0.0 section. The newest entry is 9.15.0, then the page jumps back to 8.10.1. This confirms the DeepSeek leg's report by direct chair read.
- What's New page (https://doc.babylonjs.com/whats-new, the URL cited in the filed Qwen leg): its 9.0.0 section lists features only (Clustered Lighting, Textured Area Lights, Node Particle Editor, Particle Flow Maps and Attractors, Volumetric Lighting, Frame Graph, Animation Rendering, Advanced Gaussian Splat Support, Editor, Inspector v2, Viewer Updates, Playground Updates, Large World Rendering, Geospatial Camera, 3D Tiles Support, Physically Based Atmosphere, OpenPBR Support Alpha, Dynamic IBL Shadows, Signed Distance Field Text, Outline Renderer, Nav Mesh Updates, Audio Engine Updates, 3MF Exporter). No WebGPUEngine entry, no thin-instances entry, no breaking-change entries at all in the 9.0.0 section.
- The two entries the Qwen leg attributed to 9.0.0 are version-misattributed. On the Breaking Changes page they sit under 7.2.2 ("Remove WebGPUEngine Dependency on Engine", PR 14931) and 7.0.0 (ArrayBufferView added to SceneLoader methods, PR 13946; thin instances staticBuffer default true, PR 14679). Both predate the 8.20 baseline, so neither is a cost of an 8.20 to 9.30 move. The Qwen leg's error was version attribution, not invention: the entries exist, under older versions.

Consequence for the synthesis: condition 4 is satisfied. There are no 9.0.0 breaking entries on either official page. The 9.x break surface is the 9.15.0 decorator migration alone, plus one in-path item below.

## Babylon: the genuine 9.x break and the in-path 8.54.2 item

- 9.15.0 decorators (Breaking Changes page): "Migration to TC39 (Stage 3) decorators. This only affects you if your own code applies Babylon.js decorators (such as @serialize, @serializeAsVector3, @expandToProperty, @addAccessorsForMaterialProperty, or @editableInPropertyPage) to classes you author. Code that merely uses Babylon.js classes is unaffected." The game is plain JS per the Job C synthesis, so the remaining step is Opus's code grep confirming no decorator use. The page's own limiting sentence is the strongest evidence available short of that grep.
- 8.54.2 NPE Texture block (What's New page): "NPE Texture block .texture updates" carries a [*Breaking Change*] tag (PR #18058). 8.54.2 is AFTER the 8.20 baseline, so it IS in the move path. Whether the game touches NPE texture blocks is an Opus code grep. The record suggests hand-written particles (wfx3d.js), not Node Particle Editor graphs, but that is inference, not a grep. Do not claim the game is unaffected until the grep runs.
- BoundingBoxRenderer: the only mention on the whole What's New page is a 7.37.2 feature addition ("Instanced BoundingBoxRenderer", PR #15911), not a breaking change and pre-baseline. The Qwen leg's 8.22.3 BoundingBoxRenderer access-change report is NOT confirmed on either official page and stays a community-reported lead.
- 8.10.1 camera orientation fix (right-handed scenes) is pre-baseline and correctly excluded, as both legs did.

## Godot spike docs: confirmed in substance, with branch caveats

- JSON float trap (Qwen leg): CONFIRMED in substance at Godot's own docs. The JSONParseResult note, identical across the doc branches found, reads: "The JSON specification does not define integer or float types, but only a number type. Therefore, parsing a JSON text will convert all numerical values to float types." The loader must re-type integers, exactly as the synthesis says. Caveat: the pages found are 3.x branches; the 4.7-branch JSON class page is a one-line spike confirmation. The 2^53 exactness point follows from double representation and is stated as arithmetic, not as a doc quote; a spike test value above 2^53 settles it empirically.
- HashingContext SHA-256 (DeepSeek leg): CONFIRMED at Godot's docs (4.0 branch found, API stable across the 3.2, 3.6, 4.0, 4.2, and 4.3 branches surfaced): HashingContext with HASH_SHA256 = 2 and the start, update, finish API, with hex_encode on the result. The golden-file SHA-256 design in the synthesis rests on a real API. Caveat: same one-line 4.7-branch confirmation as above; the API is unchanged across every branch found, so this is low risk.
- glTF import LOD defaults (DeepSeek leg): CONFIRMED in substance at Godot's docs (mesh LOD page, 4.3 branch; ResourceImporterScene, 4.2 branch; a 4.7 doc mirror shows the same defaults): mesh LOD generation happens automatically by default for imported 3D scenes (glTF, .blend, Collada, FBX), via meshoptimizer, switching by screen size; meshes/generate_lods defaults to true; per-mesh disable lives in Advanced Import Settings; LOD0 is the imported mesh, so the triangle budget must be set in Blender first; artist-made LODs use visibility ranges (HLOD) instead; OBJ does not get auto-LOD unless imported as a scene. The synthesis's LOD statements stand.
- Headless invocation: PARTLY confirmed. Godot's command line tutorial (docs, latest branch) confirms the general form: `godot --headless --path path_to_project` plus the command (the tutorial's example is `--export-release`). The exact C# golden-runner invocation on 4.7.2 (which .NET editor binary name on Windows, plus the scene or script argument form for a headless run that prints PASS/FAIL and exits) is NOT confirmed by the docs snippets found and stays a spike-time check. Do not quote a C# headless command line from this note.
- .NET version for 4.7: CORROBORATED, not yet primary-confirmed. Two independent secondary sources agree the 4.7 .NET build requires .NET SDK 8.0 or newer (a 4.7.1 install guide; a Godot 4.7+ Asset Store listing requiring ".NET 8 SDK or newer"), and that agrees with the UI shelf's ".NET 8 in 4.7" line against ".NET 10" for 4.8 beta. The official C# basics mirrors found state .NET 6.0, but those mirrors are 4.0-era docs. Recorded here as: .NET 8 for 4.7, pending a one-line confirmation against Godot's own current C# basics page at spike time. The legs' .NET 8 versus .NET 10 disagreement resolves to 8 for 4.7 on the evidence available; 10 belongs to the 4.8 beta claim.

## What remains for Opus (not done by this note)

- Code greps: decorators, WebGPUEngine, thin instances, NPE texture block use, BoundingBoxRenderer access. The greps decide whether the 9.15 decorator break, the 8.54.2 NPE break, and the unverified 8.22.3 report touch this game at all.
- Spike runs: exact C# headless invocation on 4.7.2; 4.7-branch confirmations for the JSON, HashingContext, and LOD pages; .NET 8 confirmation against Godot's own current C# page; PRNG Test 0 and the golden-file design itself, which this note does not test.
- The large visual and behavioral regression pass remains the real cost of the Babylon move, as both Job C legs agreed. Nothing in this note reduces that pass.

## Not checked

- Any Babylon or Godot page not named above, including the 9.30 and 9.31 patch notes beyond the items listed.
- Whether Opus has already run any of the greps or spike checks above; Opus's own records are the authority, not this note.
- Batch 9 and the modeling pipeline guide pack, which are separate streams with their own deliverables.
