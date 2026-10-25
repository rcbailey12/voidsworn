# Batch 9: Godot space craft, fleet rendering, C# at scale, 4.7 migration, 3D performance (Rey leg, Oct 25, 2026)

Method: topic-batched reads in the standing Reddit and forum mining program (read-only, no posting, voting, or bulk scraping). Three Godot forum threads were read in full text: the sky shader starfield thread, the C# worth-it thread, and the spaceship demo performance thread. Godot and Blender doc pages were read directly for the doc claims. Everything else below rests on search snippets and is flagged as snippet-only. One honest method limit up front: this batch's community side came from the Godot forum, not from Reddit threads. The searches run for this batch surfaced blogs, forum threads, and doc pages, but no r/godot thread with usable firsthand content. A later pass can target Reddit threads directly; do not cite this leg as Reddit evidence.

All version and date tags are the sources' own. Nothing here decides the engine call, which belongs to the A2 benchmark plus blind stills. Items marked for A2, A3, or A5 are pointers for Opus, not decisions.

## 1. Sky and starfield: the hash-grid technique, and the cost of the naive version

Source: Godot forum, "How to make an efficient/performant 3D sky shader starfield?", Godot 4.2.1, January 2024, read in full.

- The original poster fed 1000 star positions as a uniform array and looped over all of them per pixel. Their own measurement on their own scene: FPS halved from 60 to 30 at 1000 stars, before adding star sizes or variation. That number is one builder's scene, not a benchmark, but the mechanism is general: per-pixel cost grows with star count.
- The accepted answer (elementbound) replaces the loop with a hash grid: divide the sky coordinate space into fixed-size cells, compute the cell from the pixel coordinate, hash the cell coordinate for a random star position inside the cell, and use one extra hash value as a presence chance to control density. Multiple layers with different cell and star sizes give different star types, and modulating the presence chance with a function gives a milky way band.
- The original poster also wanted a visible sun and a procedurally varied starfield per game cycle. The hash-grid answer supports both: the sun comes from the directional light direction in the sky shader, and varying the hash seed varies the field.
- Caveat: this is a 4.2.1-era thread. The technique is shader math, not version-specific API, but a 4.7 check belongs in A5 before adoption. The background pack's treatments stand regardless; this thread is a candidate implementation for the starfield part, not a replacement for the pack.

For Voidsworn: if the Godot path wins, the space background in A5 has a concrete starting technique (hash-grid sky shader) that avoids the per-pixel loop trap. The A2 environment round (shared dead-star nebula sky, seeded asteroid field) is the place to test it, not a doc claim.

## 2. Fleet rendering at scale: MultiMesh, LOD defaults, and what they do not do

Sources: Godot docs (MultiMesh class page, 4.0 branch found; mesh LOD page, 4.3 branch; ResourceImporterScene, 4.2 branch; a 4.7 doc mirror showing the same import defaults). Branch caveat applies to all doc claims in this section: re-check on the 4.7 branch at A3 time.

- MultiMesh draws thousands of instances with a single draw call, per the docs. The limits that matter for this game: all instances of each surface share one material; the visibility AABB must be provided by the user (instances far apart still all render, since the whole MultiMesh is spatially indexed as one object); the lights-per-object limit applies to the whole MultiMesh, so once the limit is consumed by some instances, the rest get no lighting; blend shapes are ignored.
- Mesh LOD generation happens automatically by default for imported 3D scenes (glTF, .blend, Collada, FBX), via meshoptimizer, switching by screen size. The import default meshes/generate_lods is true. Per-mesh disable lives in Advanced Import Settings. Two consequences: LOD0 is the imported mesh, so the triangle budget must be set in Blender first (a 1.9 million face import still costs 1.9 million faces up close); and artist-made LOD meshes are not treated as LODs if bundled into the .glb (they arrive as extra mesh nodes), so artist LODs use visibility ranges (HLOD) instead. OBJ does not get auto-LOD unless imported as a scene.
- For Voidsworn: the crowd cases (24 and 40 ships) and the ~200 asteroid field are exactly the MultiMesh shape, but with two cautions. First, per-ship faction paint and damage states fight the one-material-per-surface rule, so MultiMesh fits asteroids and repeated props better than hero hulls with individual paint and damage. Second, the lights-per-object limit means a many-lights scene needs its lighting plan checked against MultiMesh use, not assumed. Both cautions are A3 spike items, not verdicts.

## 3. C# versus GDScript at large-project scale: practitioner notes, not benchmarks

Source: Godot forum, "Is it worth using C# in Godot?", Godot 4.4.1, July 2025, read in full. Plus a May 2025 forum thread on script visualization (snippet only).

- The recurring practitioner line: GDScript for rapid prototyping and small projects; C# for bigger games in the long run, because of static typing, IDE refactoring, and debugging. The counterweight, stated by C# users themselves: every test run pays a compile step, so the time between debugging sessions is longer than GDScript's.
- Setup friction is real but solvable: Rider is repeatedly praised for Godot C# out of the box; VS Code needs launch.json edits for breakpoints to hit; a poster who could not hit breakpoints was told to set the correct IDE in Godot settings (advanced mode, mono settings). Minor annoyances reported: structs and enums cannot be exported to animation player arguments, and signal connections do not auto-create methods.
- Platform limit, stated in the thread and consistent with Godot's docs: C# cannot export to web (a Godot 3 path exists, not a 4.x path). This game is PC-only, so the limit does not bite, but it is a permanent constraint on any future web demo.
- Refactoring tooling weakness (May 2025 thread, snippet only): a poster chose C# for large projects specifically because GDScript refactoring tooling still lacks, and pointed at external IDEs for GDScript as the workaround. Snippet only, not a full read.
- .NET version (from the Job C doc verification pass, same day): .NET SDK 8.0 or newer for the 4.7 .NET build, corroborated by two secondary sources, pending a one-line confirmation against Godot's own current C# page. Do not quote .NET 10 for 4.7; that number belongs to a 4.8 beta claim.

For Voidsworn: this section feeds the Job C language spike, which Opus decides. The spike should measure the two things the threads actually disagree on: compile and iteration time on a rules-sized codebase, and refactoring tooling on a real rename. Blog verdicts ("C# for large projects") are not evidence for either.

## 4. Godot 4.7 migration: an official guide exists, and one citation needs re-pointing

Sources: Godot docs migration guide (docs.godotengine.org, latest branch, snippet plus page title); secondary 4.7.1 and 4.7.2 notes (snippet only).

- An official "Upgrading from Godot 4.6 to Godot 4.7" guide exists, with a breaking-changes table that carries GDScript compatibility and C# binary and source compatibility columns per change. The guide's own framing is that most 4.6 games should migrate relatively safely, with the table as the checklist. No firsthand migration report was read in this batch; the guide is documentation, not experience.
- 4.7.1 (July 2026) and 4.7.2 maintenance releases exist. The A2 test runs 4.7.2 per FINDINGS R22; the migration guide is the 4.6 to 4.7 step, and the 4.7.x patches are a separate, smaller step.
- Citation check item (secondary claim, not verified): a 4.7.1 guide states the Asset Library is gone in 4.7, replaced by the Asset Store. If true, the X14 KayKit citation (CC0 on the Godot Asset Library listing) needs re-pointing to the Asset Store listing before first use. This is a check item for Opus, not a verdict: the claim rests on one secondary source, and the Asset Store listing itself was not read in this batch.

## 5. Godot 3D performance expectations: scene-dependent, and the demo numbers come with their own caveats

Source: Godot forum, "Performance - Abandoned Spaceship Demo", Godot 4.3, March 2024, read in full.

- The poster's own numbers on the unoptimized spaceship demo scene (their words: the scene renders 2.5 million primitives from shadows, VFX, and lights while the models are simple): high-end Windows PC 60 FPS at all resolutions; MacBook Air M1 8GB 30-33 FPS at 720p, 15 FPS at 1080p, 8-12 FPS at 1600p High-DPI; 2014 GTX 960M notebook 18-35 FPS at 720p with stuttering, 20 FPS at 1080p; Mobile Renderer much faster on both weak machines (45-50 FPS at 1080p, 60 FPS at 720p).
- The poster's own caveats, which this leg adopts: there is no like-for-like Unity or Unreal scene, so no engine verdict follows; the compared commercial games are heavily optimized; turning off SSAO, SSIL, and the tonemapper gained only 2-3 FPS on their scene, so the cost sits in the scene itself, not in one toggle.
- For Voidsworn: the usable lesson is narrow. An unoptimized forward-rendered scene with millions of primitives and many lights is slow on weak hardware, and the Mobile Renderer is a large fallback lever. Nothing here predicts the A2 numbers for this game's scenes, and nothing here overrides them. The A2 ceiling round (24, 48, and 96 ship sweeps trimmed to 24 and 40 crowds, rich-effects mode, max detail) is the measurement that matters; forum numbers are context, not evidence for the engine call.

## What this batch does not do

- It does not recommend an engine, a language, or a rendering path. The A2 benchmark plus blind stills decide the engine; the language spike decides C# versus GDScript; A5 decides the background implementation.
- It does not verify any Reddit thread. A Reddit-targeted pass is still open if Ryan wants one.
- It does not re-check the Job C synthesis. The Job C doc verification note (same day) owns the doc claims; this batch owns community experience.

## Sources

- Godot forum, "How to make an efficient/performant 3D sky shader starfield?" (4.2.1, Jan 2024), https://forum.godotengine.org/t/how-to-make-an-efficient-performant-3d-sky-shader-starfield/45394 (read in full).
- Godot forum, "Is it worth using C# in Godot?" (4.4.1, Jul 2025), https://forum.godotengine.org/t/is-it-worth-using-c-in-godot/116103 (read in full).
- Godot forum, "Performance - Abandoned Spaceship Demo" (4.3, Mar 2024), https://forum.godotengine.org/t/performance-abandoned-spaceship-demo/52099 (read in full).
- Godot docs, MultiMesh class page (4.0 branch found), https://docs.godotengine.org/en/4.0/classes/class_multimesh.html (snippet plus doc text).
- Godot docs, mesh LOD page (4.3 branch), https://docs.godotengine.org/en/4.3/tutorials/3d/mesh_lod.html (snippet plus doc text).
- Godot docs, ResourceImporterScene (4.2 branch), https://docs.godotengine.org/en/4.2/classes/class_resourceimporterscene.html (snippet plus doc text).
- Godot docs, "Upgrading from Godot 4.6 to Godot 4.7" (latest branch), https://docs.godotengine.org/en/latest/tutorials/migrating/upgrading_to_godot_4.7.html (snippet plus page title).
- Godot docs, command line tutorial (latest branch), http://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html (snippet plus doc text; headless form only).
- Godot docs, JSONParseResult and JSON class pages (3.x branches found) for the JSON float note (snippet plus doc text; 4.7-branch confirmation still open, per the verification note).
- Godot docs, HashingContext class page (4.0 branch found), https://docs.godotengine.org/en/4.0/classes/class_hashingcontext.html (snippet plus doc text).
- Blender manual, glTF 2.0 (3.2 branches found), https://docs.blender.org/manual/fi/3.2/addons/import_export/scene_gltf2.html (snippet plus doc text; current-branch re-check still open).

## Not checked

- Any Reddit thread (see method limit above).
- The full text of the May 2025 script-visualization thread (snippet only).
- The 4.7 branches of the MultiMesh, LOD, JSON, and HashingContext doc pages (older branches found; the verification note carries the same caveat).
- The current Blender manual glTF exporter page (3.2 branches found).
- The Asset Store listing for KayKit Space Base Bits, and the Asset Library replacement claim (check item, section 4).
- Whether the hash-grid sky shader technique performs as described on 4.7 (4.2.1-era thread; A5 test item).
- The DeepSeek second leg for this batch, which is running separately; this leg does not summarize it.
