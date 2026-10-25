# Batch 9 DeepSeek leg (filed return, Oct 25, 2026)

Chair header: this is the verbatim return from a fresh DeepSeek chat, run Oct 25, 2026, 4:13 to 4:22 PM CDT. DeepThink ON and Search ON were verified before the prompt was submitted (both toggles were off at first and were switched on). No other chat was opened or referenced. DeepSeek reviewed 192 web pages. The chat URL was not captured in the handoff, so this filed text is the record. Wording below is the model's, except this header. Screening notes live separately and are not part of this leg.

## 1. Godot space-scene craft: sky, starfield, nebula, asteroids, lighting

Sky and starfield shaders exist as community listings, not benchmarked builds.

- "Procedural Sky Stars" (Godot Asset Store, listed 2026-08-21): sky shader for Godot 4, no textures, fully GPU based, multi-layer stars, per-star twinkle, slow sky drift, set up via ShaderMaterial on the WorldEnvironment sky. The listing gives no performance numbers. https://store.godotengine.org/asset/mrpatientniko/procedural-sky-stars/
- "Scrolling Starry Background" (Godot Shaders, 2025-07-17): a canvas_item shader that overlays a few TextureRect nodes, uses very small star textures, and makes the nebula from a NoiseTexture with a constant-interpolation gradient. It is a 2D background approach, not a 3D sky. https://godotshaders.com/shader/scrolling-starry-background/#main
- "Space background shader" (Godot Shaders, dated 2026-10-22): uses cellular noise for clouds, dither areas, rifts, and stars. The author says it is "not terribly efficient by any means" and calls it a proof of concept; the author notes using Godot 4.7.1 even though the page is tagged 4.6. https://godotshaders.com/shader/space-background-shader/
- "Starlight 1.3" (Godot Asset Library, 2025-01-03): a different approach, renders 100,000 stars positionally in 3D using MultiMeshInstance3D rather than a skybox. Claims low performance cost, works with Forward+, Mobile, and Compatibility renderers, MIT license. https://godotengine.org/asset-library/asset/2221

Nebula backgrounds: the community pattern is noise textures or shader noise plus gradients (NoiseTexture plus gradient in the Scrolling Starry Background; cellular noise with color ramps and dithering in the Space background shader). None of these sources give measured GPU cost.

Asteroid fields: Devlog #102 "NODEvember, The Crescent Ring" (2023-11-28, Medium; a blog summary, and only the search snippet could be read) says the team converted asteroids to multimeshes inside Godot to significantly reduce draw calls, which it calls critical for performance as the world grows. https://enter-realm.medium.com/devlog-102-nodevember-the-crescent-ring-7f9f8e6b7e6f

A firsthand Steam demo update for "Management In Space" (2026-07-13) reports Godot was not processing MultiMeshes properly, and the developer worked around it by updating them directly to the RenderServer. It gives no frame-rate numbers.

Lighting: the official Godot 4.7 release notes (published 2026-06-18) add HDR output and AreaLight3D, a new rectangular real-time light that can produce softer shadows and more realistic reflections. https://godotengine.org/releases/4.7/?trk=public_post_comment-text

For a space scene with a distant sun, DirectionalLight3D remains the normal choice, but no source found specifically benchmarks a space lighting setup. One firsthand bug report (issue #110436, Godot 4.5 beta 7) shows many moving lights and individual mesh tiles can create high CPU time in "Preparing to Render 3D scene". https://github.com/godotengine/godot/issues/110436

## 2. Godot fleet rendering at scale: MultiMesh, instancing, LOD

Official MultiMesh docs: drawing thousands of MeshInstance3D nodes is slow because each object is submitted and drawn individually; MultiMesh draws thousands of instances in one draw call. Caveats: a MultiMesh is spatially indexed as one object, so individual instances cannot be frustum culled; and it shares a light limit, so once the maximum lights are consumed by some instances, the rest receive no lighting. (The chat cited a community GitHub mirror of the docs page: https://github.com/AThousandShips/godot-docs/blob/2f904cd21624cf6137dc8d3f1eba651be4e0c7e9/classes/class_multimesh.rst#1 )

For 24 to 40 ships, individual MeshInstance3D nodes should be fine; the cost driver is unique materials (each unique material on a mesh adds a draw call). A community reference cites a rule of thumb of under about 1,000 draw calls for 60 fps on desktop. For 200 asteroids sharing one mesh and one material, MultiMesh collapses the field to roughly one draw call. The practical pattern: MeshInstance3D for ships that need individual logic and different meshes, MultiMeshInstance3D for asteroids and repeated debris.

LOD generation on import: official docs say it happens automatically for glTF, .blend, Collada, and FBX scenes, but not for OBJ unless the OBJ is imported as a scene. It applies to MeshInstance3D, MultiMeshInstance3D, GPUParticles3D, and CPUParticles3D, and uses the meshoptimizer library. (The chat cited the docs through a Japanese-locale 4.3 page: https://docs.godotengine.org/ja/4.3/tutorials/3d/mesh_lod.html#configuring-mesh-lod-performance-and-quality )

A firsthand bug report (issue #104919, Godot v4.4 stable mono, 2026-02-28) says automatic LODs on an imported subdivided cube changed at far too close a distance, and LOD Bias values above 1 did nothing; disabling LOD generation was the only fix. Test LOD distances instead of trusting defaults. https://github.com/godotengine/godot/issues/104919

Community experience: a Reddit thread from 2024-02-12 titled "I spent a long time looking for a way to place a large number of my 3D objects" (firsthand) reports Godot's built-in MultiMesh gave sufficiently high performance, and recommends LOD, lower polygon counts, quads, or Sprite3D impostors if more is needed. A firsthand GitHub issue from the deep-yellow project (issue #47, 2026-02-02) measured about 4,900 Sprite3D billboard sprites dropping FPS from roughly 60+ to about 14 in a procedural level, and cited reports of about 10,000 Sprite3D nodes at about 8 FPS on high-end hardware. That is individual nodes, not MultiMesh, and it shows the cost of many individual draw calls. https://github.com/aebrer/deep-yellow/issues/47

## 3. C# versus GDScript at large-project scale

Refactoring tooling: C# has the stronger story. A community reference file dated 2026-04-09 says C# works with VS Code or Rider with "excellent" tooling, static checks, and refactoring tools, while GDScript's built-in editor tooling is only "OK". The same source recommends C# for non-trivial gameplay code, long-lived projects, and larger teams, and GDScript for quick prototypes, editor tools, and simple scripts. (A community reference file, not a forum report: https://github.com/LazyIsEfficient/agentic-os/blob/main/.claude/skills/godot-engineer/references/gdscript-vs-csharp.md#1 )

A studio blog comparison by StraySpark (2026-03-31; a blog summary, not a firsthand community test) says C# gives more compile-time safety and better IDE refactoring support, while GDScript is faster to write and read, and estimates C# is roughly 40 to 60 percent more verbose. https://www.strayspark.studio/blog/gdscript-vs-csharp-godot-2026-choosing-scripting-language

Compile and iteration: the 2026-04-09 reference rates GDScript iteration "very fast" with no build step and fast hot reload, versus C# with a slower compile step and limited hot reload that usually requires a restart. A firsthand Reddit report (2024-05-03, "My experience making a pre-alpha ENTIRELY in C#") says C# was generally 2 to 3 times slower to work with than GDScript, but also found C# runtime faster even at calling engine APIs in 4.x. A separate firsthand Reddit side-by-side test (2024-06-21) creating 3,000 bullets through the Physics/Rendering servers found statically typed GDScript only about 10 percent FPS slower than C#, so the runtime gap is workload dependent.

Debugging: C# integrates with Visual Studio and Rider and is rated "excellent"; GDScript's built-in debugger is rated "adequate".

Platform export limits (official docs): C# projects support all desktop platforms since Godot 4.2; Android support is experimental; iOS support is experimental with limitations (macOS required, iOS simulator templates x64 only); C# projects currently cannot export to the web platform. The StraySpark blog estimates about 30 to 60 MB extra export size for the .NET runtime. (The chat cited the docs through a Portuguese-locale source page: https://docs.godotengine.org/pt-br/4.x/_sources/tutorials/scripting/c_sharp/index.rst.txt )

For a PC-only game, the web export limit does not matter and desktop export is supported; the main costs are the compile step and slower iteration.

## 4. Godot 4.7 migration experiences from 4.6

The official "Upgrading from Godot 4.6 to Godot 4.7" page says most 4.6 games and apps should migrate relatively safely, and it marks each change as GDScript-compatible, C# binary-compatible, or C# source-compatible. It lists: Object.is_class changes its class parameter type from String to StringName; ZIPPacker.start_file adds optional permissions and modified_time parameters; OptimizedTranslation.generate changes return type from void to bool; CPUParticles2D/3D and GPUParticles2D/3D request_particles_process add an optional process_time_residual parameter; Control.accessibility_live changes type from DisplayServer.AccessibilityLiveMode to AccessibilityServer.AccessibilityLiveMode; RichTextLabel renames ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT to UPDATE_WIDTH_UNIT, add_image changes width and height parameter types from int to float and renames width_in_percent to width_unit with type changing from bool to RichTextLabel.ImageUnit (same rename for height); Font.find_variation adds optional palette_index and custom_colors; TreeItem.select adds optional set_as_cursor; Image.save_exr and save_exr_to_buffer add optional color_image and max_linear_value; ImageTexture.get_format moves to the base class Texture2D. This is official documentation, not a community report. https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html

What actually broke in practice:

- Input device IDs. Firsthand issue #118025 (reproducible since 4.7 dev 2): the 4.7 device ID change for keyboards and mice breaks projects that use InputEvent.device directly; a project setting may be needed to keep old behavior. https://github.com/godotengine/godot/issues/118025
- Forward+ performance regression in beta. Firsthand issue #119963 (2026-06-02, 4.7 beta 4, AMD Radeon RX 570): 60 percent or greater FPS loss in Forward+ versus 4.6.3; the Bistro demo went from 189 FPS in 4.6.3 to 75 FPS in 4.7 beta 4, attributed to fragment shader VGPR usage rising from 84 to 256 with occupancy dropping from 3 to 1. This is a beta report, not a stable 4.7 measurement. https://github.com/godotengine/godot/issues/119963

The official 4.7 release notes (2026-06-18) describe a polish and quality-of-life release with HDR output, AreaLight3D, Control offset transforms, and the new Asset Store, and tell users to read the migration guide before upgrading. A third-party "Godot 4.7 Upgrade Checklist" (2026-06-18, godotlearning.com; a blog summary, not a firsthand migration log) recommends testing UI and Control animation, rendering and materials, Android and mobile input, and export templates. https://godotlearning.com/blog/godot-4-7-upgrade-checklist

## 5. Godot 4 3D performance expectations on desktop GPUs

Official guidance: Forward+ is a clustered forward renderer that can greatly speed up rendering on desktop hardware but is substantially less efficient on mobile; draw calls and state changes matter, so a scene with 20,000 objects and 20,000 different materials will be slow while the same objects with 100 materials will be much better. That is official guidance, not a measured benchmark.

Measured reports found (concrete numbers only where the source measured them):

- Issue #82238 (Godot v4.1.1, NVIDIA GeForce MX110 laptop GPU, i5-8250U): a very simple scene with one box and a skybox ran around 85 FPS without glow and dropped to 50 FPS with glow added. A laptop GPU, not a desktop GPU, but it shows post-processing can cost a large fraction of frame time on weaker hardware. https://github.com/godotengine/godot/issues/82238
- Issue #97903 (Godot 4.4 dev3, NVIDIA GTX 1050 Ti desktop GPU, Ryzen 5 2600): one GPUParticles3D smoke grenade with about 80 on-screen particles gave Forward+ lowest FPS of 63, 73, and 74 across three trials versus 201, 206, and 218 on the Compatibility renderer; two grenades gave Forward+ lowest 40, 52, 57 versus Compatibility 151, 176, 170. Transparent particles are much more expensive in Forward+. https://github.com/godotengine/godot/issues/97903
- Issue #119963 (4.7 beta 4, AMD Radeon RX 570): Bistro demo dropped from 189 FPS in 4.6.3 to 75 FPS, with increased opaque render times and shader VGPR usage rising from 84 to 256. https://github.com/godotengine/godot/issues/119963
- Issue #110436 (Godot 4.5 beta 7, AMD RX 6600, i3-10105F): many moving lights and individual mesh tiles caused high CPU time in "Preparing to Render 3D scene"; performance improved substantially with fewer lights. No FPS numbers given. https://github.com/godotengine/godot/issues/110436
- deep-yellow issue #47 (2026-02-02): about 4,900 Sprite3D billboard sprites dropped FPS from roughly 60+ to about 14; cited reports put about 10,000 Sprite3D nodes at about 8 FPS on high-end hardware. A warning that many individual draw-call nodes are expensive. https://github.com/aebrer/deep-yellow/issues/47

What the sources point to as frame costs in the forward renderer: draw calls from individual meshes with unique materials, transparent or particle effects, glow and post-processing, many moving lights, and shader occupancy regressions. MultiMesh and LOD are the documented mitigations for object count and vertex cost. The 24 to 40 ship range is small enough that individual ship meshes should be viable, but the asteroid field should be batched, and transparent effects and lights should be profiled rather than assumed free.

## Not checked

- I could not verify a firsthand measured benchmark for exactly 24 to 40 ships plus 200 asteroids in Godot 4.7. No source found gives that exact load.
- I could not verify the performance cost of the specific community sky and nebula shaders (Procedural Sky Stars, Scrolling Starry Background, Space background shader) on desktop GPUs. Those sources give no FPS numbers.
- I could not verify whether the 60 percent Forward+ regression in issue #119963 is fixed in stable 4.7.x. The report is against 4.7 beta 4.
- I could not verify C# hot reload behavior specifically in Godot 4.7. The community sources that discuss hot reload refer to 4.6.
- I could not open the full Devlog #102 Medium article. The asteroid MultiMesh comment comes from the search snippet, not the full post.
- I did not find a community report that specifically measures lighting a space scene in Godot 4.7. The lighting performance reports found are general 3D light reports, not space specific.
- I did not find an official Godot 4.7 performance benchmark for the forward renderer on desktop GPUs. The measured numbers above come from community bug reports, not official engine benchmarks.
