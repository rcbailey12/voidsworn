# Job C Godot project and shipping review (Gemini leg, Argon High, Oct 26, 2026)

Filed verbatim from a fresh Gemini chat. Ran Oct 26, 2026, 07:05-07:21 CDT (runtime-measured, 15m).

Model verification (required by the assignment): signed in as Ryan Bailey (rcbailey12@gmail.com), Google AI Pro confirmed in the sidebar. On arrival the picker was on Flash (3.8 Flash selected) and the Thinking level was Low; both were changed before submitting, and both indicators were rechecked right before sending: the model picker button read "currently Argon High" and the prompt bar dropdown read "Argon High". Picker state verified before submitting. No fallback model was used.

Chair note on process (not part of Gemini's review): the pack was entered with the default fill path, not paste-entry mode; the page did not hang. The page showed small citation source chips after some paragraphs (for example "Godot Engine", "Game Dev Space", "The Godot Barn"); those chips are page furniture, not model prose, and are left out of the review text below. The page also showed a footer note "Reframing answer to avoid copyright violation": against the pack's request to quote the licence text, the model gave the licence header and paraphrased clause summaries rather than the full verbatim MIT text. That gap is in the review itself and is preserved as delivered. No sidebar chat was opened, nothing was saved to any repo, bought, or posted. This is a commissioned blind review leg for the travel sprint (not a leads-only shelf); it is screened like the other legs. See the screening note for the chair's flags, including the direct conflict between this leg's Part 1 verdict and the DeepSeek C leg's Part 1 verdict.

## Gemini review (verbatim)

1. Part 1: GodotSteam Licence (X18 Claim)

Verdict: REFUTED for GodotSteam 4.20 through 4.23.2 (with UNSURE retained strictly for the standalone GodotSteamKit license text on godotsteam.com, which is not indexed in public search results).

Evidence from Primary and Mirror Sources

Repository Home and Current Version: GodotSteam is maintained by GP Garcia (Gramps) across two primary repository locations: GitHub (https://github.com/GodotSteam/GodotSteam) and Codeberg (https://codeberg.org/godotsteam/godotsteam), with documentation hosted at https://godotsteam.com. As of October 20, 2026, GodotSteam 4.20 (released June 24, 2025, with 4.20.1 on July 16, 2025 for Steamworks SDK 1.64) has been superseded by GodotSteam 4.23.2 (targeting Godot 4.x and Steamworks SDK 1.65, with precompiled bundles built for Godot 4.7.2).

No Drop of MIT in 4.20 or Newer: Across the GodotSteam 4.20.1, 4.21, and 4.23.2 releases:

The official Godot Asset Library listing (https://godotengine.org/asset-library/asset/2445, updated October 20, 2026 by Gramps for version 4.23.2) and Godot Asset Store listing (https://store.godotengine.org/asset/godotsteam/godotsteam-gdextension/) explicitly declare the license as MIT.

The shipped addons/godotsteam/readme.md for version 4.21+ (which includes the 4.20 compatibility changelog entry noting that Godot 4.7 changed callable_method_pointer.h to callable_mp.h) states under its License heading that the project uses the MIT license, immediately following a No LLM Policy / No "AI" Policy notice restricting AI-generated issues, patches, and pull requests.

The shipped addons/godotsteam/license.md file in the 4.20/4.21 GDExtension addon package (https://git.game-dev.space/minimata/cheapest-game/src/commit/264a5351543251266040fdd641a7f8af0a2ba413/addons/godotsteam/license.md) is the standard 23-line MIT License.

Licence Identification and Terms Found

The addons/godotsteam/license.md file in the GodotSteam 4.20+ GDExtension package opens with the following header and copyright attribution:

MIT License
Copyright (c) 2015-Current | GP Garcia, Chris Ridenour, and Contributors
View all contributors at https://godotsteam.com/contribute/contributors/

Immediately following that header, lines 6 through 23 contain the unmodified, word-for-word standard MIT License text:

Grant clause: Grants any person obtaining a copy of the software and documentation files permission, free of charge and without restriction, to use, copy, modify, merge, publish, distribute, sublicense, and sell copies of the software.

Condition clause: Requires that the copyright notice above and the permission notice be included in all copies or substantial portions of the software.

Disclaimer clause: Provides the software "as is" without warranty of any kind and absolves the authors and copyright holders of any liability for claims or damages.

Comparison: MIT vs. GodotSteamKit

GodotSteam vs. Standard MIT: Identical. GodotSteam 4.20 through 4.23.2 uses the standard MIT license text with the contributor URL line added to the copyright header.

GodotSteam vs. GodotSteamKit: GodotSteamKit (https://godotsteam.com/projects/godotsteamkit) is a separate starter-kit project by Gramps containing helper scenes and custom nodes (such as lobby, voice, and avatar frameworks referenced in tutorials on thegodotbarn.com, where the tutorial articles themselves are licensed under CC-BY). The addons/godotsteam/readme.md file links to godotsteam.com/projects/godotsteamkit in its top navigation table next to 4.20 in the compatibility table below it, which is the most likely reason an automated summary conflated GodotSteam 4.20 with GodotSteamKit (INFERRED). Because the standalone license text on https://godotsteam.com/projects/godotsteamkit is not indexed in public search results, the exact license of GodotSteamKit itself remains UNSURE.

Plain-Words Consequences for a Commercial Steam Release of Voidsworn

What blocks selling the game on Steam: Nothing in GodotSteam's license blocks selling Voidsworn commercially on Steam.

Redistribution (what you may do): You may bundle, modify, and redistribute the compiled GodotSteam GDExtension binaries (libgodotsteam*.dll) inside your commercial Steam build without restriction.

Attribution (what must be disclosed or shipped): You must include the GodotSteam copyright notice (Copyright (c) 2015-Current | GP Garcia, Chris Ridenour, and Contributors) and the standard MIT permission/disclaimer notice in your shipped third-party legal notices (such as a LICENSES.txt file in the game install folder or an in-game credits/legal screen), alongside the Godot Engine MIT notice.

Source disclosure (what you do NOT have to do): MIT is not copyleft. You do not have to disclose or open-source Voidsworn's game code, shaders, or rules port.

Fees or approval conditions: Zero royalties, zero license fees, and no commercial approval required from GodotSteam's authors.

Steamworks SDK terms (separate from GodotSteam): GodotSteam wraps Valve's proprietary steam_api64.dll (Steamworks SDK 1.64 for GodotSteam 4.20.x, or SDK 1.65 for GodotSteam 4.21 through 4.23.2). Shipping steam_api64.dll is governed by the Valve Steamworks SDK Access Agreement, which requires an active Steamworks partner account and permits redistributing steam_api64.dll for your Steam release. You may not redistribute the unpublished Steamworks SDK source headers to non-licensees, and you should not submit AI-generated PRs or issues to the upstream GodotSteam repository.

2. Part 2: Godot 4.7 Windows Export Checklist

All documentation links below point to the official Godot 4.7 documentation (docs.godotengine.org/en/4.7/), matching the project's Godot 4.7.2 target.

Item 1: Texture Compression for 8K Ship Textures

Godot 4.7 Docs Links:

https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html

https://docs.godotengine.org/en/4.7/classes/class_resourceimportertexture.html

Formats Available and What to Pick for Windows Desktop:

Set Compress -> Mode (compress/mode) to VRAM Compressed (the default for 3D textures).

Enable Compress -> High Quality (compress/high_quality = true). On desktop platforms, enabling High Quality selects BPTC (BC7 for LDR color/albedo/ORM textures and BC6H for HDR textures) instead of older S3TC (BC1/BC3, which suffers from 4x4 block color bleeding and banding on subtle hull gradients and emissive trim).

For normal maps, keep Compress -> Normal Map enabled so Godot stores two-channel RGTC (BC5) and reconstructs the Z channel in the shader.

Ensure Mipmaps -> Generate (mipmaps/generate = true) is enabled so zoomed-out ships on the hex board sample lower mip levels instead of aliasing.

Ensure Project Settings rendering/textures/vram_compression/import_s3tc_bptc is enabled (true by default on desktop).

Failure Mode if Skipped:

If left Uncompressed or Lossless/Lossy (non-VRAM): A single uncompressed 8K (8192x8192) RGBA8 texture with mipmaps consumes roughly 357 MB of VRAM (268.4 MB base level plus 33 percent mip chain). With roughly 20 ships on the board using albedo, normal, ORM, and emissive maps, skipping VRAM compression will consume multiple gigabytes of VRAM, blow past the desktop GPU budget, stall PCIe uploads during scene load, and crash or thrash to system RAM. With BPTC (BC7/BC5 at 1 byte per pixel), an 8K texture with mipmaps drops to roughly 89.5 MB (a 4x VRAM reduction).

If High Quality (BPTC) is skipped on Forward+: Textures fall back to S3TC (BC1/BC3), causing visible block artifacts on dark Voidsworn/Deathless hulls, gradient banding on Ithar pearl sails, and broken HDR compression if any HDR texture maps are used (S3TC does not support HDR compression).

Item 2: Shader Pre-Compilation to Avoid First-Use Hitches

Godot 4.7 Docs Links:

https://docs.godotengine.org/en/4.7/tutorials/performance/pipeline_compilations.html

https://docs.godotengine.org/en/4.7/classes/class_renderingdevice.html

https://docs.godotengine.org/en/4.7/classes/class_performance.html

How Godot 4.7 Does It:

Ubershaders and Pipeline Precompilation: Godot 4.7 uses ubershaders (introduced in 4.4) to compile a broad fallback pipeline when meshes or materials load, while compiling specialized fast-path PSOs asynchronously in background threads. However, pipelines that depend on dynamic render-pass state, vertex formats, transparency, or particle/VFX nodes that only enter the scene tree on weapon fire are not compiled until their first draw call unless instanced ahead of time (Pipeline precompilation instancing).

Shader Baker on Export: Godot 4.7 includes the Shader Baker (introduced in 4.5, documented under Shader baker in pipeline_compilations.html). When enabled in the export preset, the Shader Baker pre-bakes shaders into the Intermediate Representation of the target graphics driver at export time to speed up initial startup and driver compilation.

Important 4.7 Constraint: Per pipeline_compilations.html, "The shader baker will only export shaders that match the rendering/rendering_device/driver project setting for the target platform."

What the Developer Must Do Before Shipping:

Keep rendering/shader_compiler/shader_cache/enabled turned on in Project Settings.

Enable the Shader Baker in the Windows export preset, and verify that rendering/rendering_device/driver.windows matches the primary shipping driver (vulkan or d3d12) so the baked shaders are actually used at runtime.

Build a warmup / precompilation instancing step (Pipeline precompilation instancing): during the battle loading screen (or for 1 to 2 frames behind a loading curtain), instantiate a hidden warmup node containing one tiny quad/mesh for every ship hull shader, shield shader, lance beam shader, and each of the 7 weapon particle/VFX materials inside a viewport that matches the battle scene's WorldEnvironment, MSAA, and directional light setup so the GPU driver compiles the exact RenderPass + VertexFormat + Material PSO combinations before turn 1 begins.

Verify zero runtime spikes using Godot 4.7's built-in Pipeline precompilation monitors in the Profiler (Performance.PIPELINE_COMPILATIONS_CANVAS, PIPELINE_COMPILATIONS_MESH, PIPELINE_COMPILATIONS_SURFACE, PIPELINE_COMPILATIONS_DRAW, PIPELINE_COMPILATIONS_SPECIALIZATION). Any non-zero count on PIPELINE_COMPILATIONS_DRAW during combat indicates a missed warmup material.

Failure Mode if Skipped:

The first time a lance beam fires, a shield ripples, a ship hits a new step on the 6-step damage ladder, or a death explosion spawns, the main thread or rendering driver stalls for 15 to 150 ms to compile the specialized PSO on demand, causing a visible frame hitch right on the combat climax. If the Shader Baker is enabled while rendering/rendering_device/driver.windows is mismatched with the runtime driver, the baked shader cache is silently ignored.

Item 3: Vulkan (and D3D12) with a Compatibility Fallback

Godot 4.7 Docs Links:

https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html

https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.6.html

https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html

When Each Renderer is Used and Important Godot 4.7 Windows Nuance:

Forward+ (forward_plus): The primary desktop renderer, powered by the RenderingDevice backend (vulkan or d3d12 on Windows). Critical note for Godot 4.7: Starting in Godot 4.6 and continuing in 4.7, Direct3D 12 (d3d12) is the default RenderingDevice driver for new projects on Windows, controlled by rendering/rendering_device/driver.windows. Because godot/project.godot currently does not set rendering/rendering_device/driver.windows, Godot 4.7 will default to d3d12 on Windows and only switch to vulkan if D3D12 initialization fails (or if you explicitly set rendering/rendering_device/driver.windows="vulkan" in project.godot).

Compatibility (gl_compatibility): Powered by OpenGL 3.3 / OpenGL ES 3.0 (opengl3 or opengl3_angle over D3D11 on Windows). Used as the fallback for older GPUs or drivers that cannot initialize a RenderingDevice context (d3d12 or vulkan).

How the Fallback is Selected:

In project.godot, rendering/renderer/rendering_method="forward_plus" sets the primary renderer.

Within RenderingDevice, if the primary driver (d3d12 or vulkan) fails to initialize on startup, Godot automatically attempts the alternate RenderingDevice driver on Windows.

However, as documented in Godot 4.7 issue #120409, automatic fallback from a crashing Forward+ Vulkan driver to gl_compatibility does not reliably catch driver-level initialization crashes on older GPUs. Therefore, you must also ship a Steam Launch Option (or launcher wrapper flag) passing --rendering-method gl_compatibility (and optionally --rendering-driver vulkan or --rendering-driver d3d12) so players can force Compatibility mode from Steam before the engine initializes RenderingDevice.

What is Lost on Compatibility (gl_compatibility):

BPTC High-Quality Texture Compression is Disabled: Per importing_images.html (4.7), "High-quality VRAM texture compression is only supported in the Forward+ and Mobile renderers. When using the Compatibility renderer, this option is always considered disabled." If you only export BPTC textures without S3TC fallback or if import_s3tc_bptc is misconfigured, textures will degrade to S3TC (BC1/BC3) or fail to load.

Compute Shaders and RenderingDevice APIs: RenderingDevice is unavailable (null), meaning no custom compute shaders, no CompositorEffect post-processing (https://docs.godotengine.org/en/4.7/tutorials/rendering/compositor.html), and no GPU-driven compute trails.

Global Illumination and Reflections: VoxelGI, SDFGI, and Screen-Space Reflections (SSR) are not supported in Compatibility (renderers.html).

Volumetric Fog and Clustered Lighting: Volumetric fog is unavailable, and lighting switches from Forward+ clustered forward rendering to multi-pass/per-object OpenGL lighting with stricter per-mesh light/shadow limits.

Item 4: Known NVIDIA Driver Issues for Godot 4.7 on Windows

Manual vs. Issue Tracker Status: The Godot 4.7 manual (docs.godotengine.org/en/4.7/) does not have a dedicated 4.7-specific NVIDIA driver page, but the official Godot GitHub issue tracker documents two specific Windows + NVIDIA driver failures reproduced in Godot 4.7 / 4.7.1 / 4.7.2:

Godot 4.7 Forward+ / Vulkan Initialization Crash on Older NVIDIA GPUs (Regression from 4.6):

Link: https://github.com/godotengine/godot/issues/120409

Details: On Windows 10/11 systems with older NVIDIA Maxwell/Kepler GPUs (such as GeForce 750M and 920M where NVIDIA no longer ships newer D3D12 Typed UAV Load drivers), Godot 4.7 first logs ERROR: No support for Typed UAV Load Additional Formats has been found on D3D12, switches to Vulkan 1.1.95 - Forward+, and immediately crashes to desktop before the window finishes loading. This worked in Godot 4.6 under Forward+ Vulkan, regressed in 4.7-dev1, and remains present in 4.7.1 and 4.7.2. Workaround is forcing Mobile or Compatibility (--rendering-method gl_compatibility).

Godot 4.7.2 Access Violation Followed by NVIDIA 0x141 (VIDEO_ENGINE_TIMEOUT_DETECTED) Display Hang:

Link: https://github.com/godotengine/godot/issues/122828 (and related #122221)

Details: Reproduced in Godot 4.7.2.stable on Windows with NVIDIA drivers when running under the Compatibility renderer (opengl3 and opengl3_angle / D3D11) across multi-window or separate game-window sessions, causing an unrecoverable NVIDIA display driver timeout (0x141) where monitors lose signal.

Vulkan Steam Overlay Note (GodotSteam Docs):

Link: https://store.godotengine.org/asset/godotsteam/godotsteam-gdextension/

Details: GodotSteam's Known Issues note that the Steam Overlay may fail to hook under Vulkan when launched from the editor on Windows, though exported builds launched via the Steam client hook properly.

3. Part 3: Project Layout and Autoload Review (godot/ Tree)

Check of godot/fx/API.md: Checked public search indices for github.com/rcbailey12/voidsworn (godot/fx/API.md, godot/fx/, godot/world/, and commit f45852c8). None of the repository files on github.com/rcbailey12/voidsworn are indexed by Google Search (0 results returned). Accordingly, per the blind-leg rules, godot/fx/API.md is recorded in Section 4 ("Not checked") as UNSURE, and this review evaluates the exact godot/ state provided in Section 2.

1. Autoloads ([autoload] in godot/project.godot)

Current State Observed: godot/project.godot has no [autoload] section at all. Zero autoloads are registered.

What is Good: Starting with zero autoloads prevented the battle rules port (godot/rules/) from depending on global engine singletons. Because rules.gd and battle_api.gd do not reference autoload nodes, they can be instantiated deterministically in headless golden tests (godot/rules/test/) (godot/project.godot, lines 1-3).

Specific Risk as Scenes Land (godot/main/, godot/campaign/, godot/scenes/battle/): When campaign state, audio, FX pools (godot/fx/), and Steam integration land, developers commonly register BattleAPI, CampaignState, SteamManager, and FxManager as global autoload singletons and call them directly from deep child nodes (for example, a ship UI widget calling a global BattleAPI singleton directly). That creates hidden global state, breaks headless isolated testing of scenes, and risks initialization-order bugs or leaked references across roguelite run resets (INFERRED from standard Godot scene architecture and the planned directory list in Section 2).

Concrete Fix:

Keep godot/rules/ (battle_api.gd, rules.gd, jsm.gd) strictly out of [autoload]. A battle session should be instantiated as a RefCounted object (or owned by the battle root controller) and passed down to godot/scenes/battle/.

Restrict [autoload] in godot/project.godot to true process-lifetime services only (for example, PlatformSteam wrapping GodotSteam so callbacks tick in _process(), and a top-level AppRouter or SettingsManager), documented in https://docs.godotengine.org/en/4.7/tutorials/best_practices/autoloads_versus_internal_nodes.html.

2. Silenced GDScript Warnings ([debug] in godot/project.godot)

Current State Observed: godot/project.godot sets 17 GDScript compiler warnings to 0 (ignored) under [debug], including integer_division=0, narrowing_conversion=0, untyped_declaration=0, inference_on_variant=0, unsafe_property_access=0, unsafe_method_access=0, unsafe_cast=0, unsafe_call_argument=0, and return_value_discarded=0.

Verdict on Silencing integer_division=0 Project-Wide: UNSAFE as a project-wide setting. While silencing these warnings inside godot/rules/ is understandable because rules.gd and jsm.gd emulate JavaScript's dynamic Variant types and handle integer truncation explicitly against golden tests, setting integer_division=0 and narrowing_conversion=0 in godot/project.godot disables those checks across the entire Godot project.

Specific Risk: Every new script written in godot/main/, godot/campaign/, godot/scenes/battle/, godot/fx/, and godot/world/ inherits integer_division=0 and unsafe_*=0. In GDScript, int / int silently truncates toward zero (for example, 1 / 2 evaluates to 0, unlike JavaScript where 1 / 2 is 0.5). In camera interpolation, hex-to-world coordinate math, UI health bars, shader parameter lerps, or damage preview calculations outside godot/rules/, an accidental int / int division or float-to-int narrowing conversion will silently produce 0 with zero editor warnings, introducing the exact truncation bug the rules port's trap list warns against.

Concrete Fix:

Re-enable critical warnings in godot/project.godot (integer_division=1, narrowing_conversion=1, unsafe_property_access=1, unsafe_method_access=1, unsafe_call_argument=1, return_value_discarded=1) so all new scene, UI, FX, and campaign code is protected.

Suppress the JS-port-specific warnings locally at the top of godot/rules/rules.gd and godot/rules/jsm.gd using Godot 4.7's file-level @warning_ignore annotations (or @warning_ignore_start("integer_division") / @warning_ignore_restore blocks), or configure debug/gdscript/warnings/exclude_addons if rules is treated as an excluded path.

3. Giant Script Evaluation (godot/rules/rules.gd at 117,728 bytes)

Current State Observed: godot/rules/rules.gd is 117,728 bytes (~115 KB, roughly 2,800 to 3,500 lines of GDScript INFERRED from byte size) in a single file, alongside battle_api.gd, jsm.gd, and data/tables.json.

Verdict: Acceptable for godot/rules/rules.gd right now; do NOT split rules.gd while JS parity golden testing is active.

Why It Should Stay One File Now: Because godot/rules/ has an explicit architectural constraint to preserve the JavaScript source order and function names for golden-test parity against the browser game, splitting rules.gd into multiple files right now would break 1-to-1 diffability against the JS reference, complicate shared module scope/state, and increase port maintenance friction.

Specific Risk:

GDScript's script parser and built-in editor analyzer slow down noticeably on single files exceeding 100 KB, and circular or untyped cross-calls inside a 117 KB file lack compile-time type boundaries.

Developers building godot/scenes/battle/ or godot/main/ may treat a 117 KB file as normal project style and write a monolithic 100 KB battle_scene.gd that mixes hex input, camera rigs, ship 3D meshes, VFX spawning, and HUD layout.

Concrete Fix (What Should Split and When):

Keep godot/rules/rules.gd intact as a single file until the browser version is retired and Godot becomes the sole canonical rules codebase.

Once JS parity is frozen and retired, if new faction abilities or campaign modifiers expand the rules further, split pure stateless lookup/calculation helpers (such as hex geometry math, weapon table resolvers, or AI scoring heuristics) into preload-ed helper classes while keeping state mutations routed through battle_api.gd.

Enforce a strict file-size ceiling outside godot/rules/: No script in godot/main/, godot/scenes/battle/, godot/campaign/, godot/fx/, or godot/world/ should exceed ~400 to 500 lines (~15 to 20 KB). Split battle presentation into focused controllers (HexBoardView, ShipPawn3D, BattleHudController, BattleCameraRig, FxDirector).

4. Scene Coupling and Signals vs. Direct Calls (battle_api.gd Boundary)

Current State Observed: The scene layer talks to godot/rules/ exclusively through godot/rules/battle_api.gd using a three-part contract: commands in, view() out, and event stream out.

What is Good About This Boundary: This is an ideal decoupling architecture for a turn-based tactical roguelite. godot/rules/ has zero dependency on Node3D, SceneTree, cameras, shaders, or frame timing. Commands flow inward via direct method calls on battle_api.gd, state snapshots flow outward via view(), and discrete combat occurrences (shots fired, shield hits, hull damage steps, ship deaths) flow outward via the event stream.

Specific Risks That Could Break This Boundary as Scenes Land:

Direct-Mutation Leak via view() References (Scene Coupling Risk): In GDScript, Dictionary and Array values are passed by reference. If battle_api.gd's view() returns references to internal dictionaries or arrays owned by rules.gd (or if UI/scene scripts cache a dictionary from view() and mutate it to store UI selection state, preview highlights, or sort order), the scene will silently corrupt the authoritative rules state.

Synchronous Signal Spaghetti During Event Playback (Signals vs. Direct Calls Risk): When a player issues a command into battle_api.gd, the rules engine resolves the action immediately and emits an event stream (for example: move_ship -> fire_lance -> shield_hit -> damage_step_3 -> ship_destroyed). If battle_api.gd or the battle scene wires those events directly to synchronous Godot signals that immediately update UI and 3D transforms at the same timestamp as view(), the ship's health bar will drop to zero and the ship pawn will snap to its final hex before the 3D movement, lance beam shader, and death sequence animations have played in godot/fx/.

Concrete Fix:

Enforce Read-Only / Deep-Copy Snapshots on view(): Ensure battle_api.gd returns either freshly constructed snapshot dictionaries/arrays (or calls .duplicate(true) / .make_read_only() on returned Dictionary and Array containers in Godot 4.7) so no script in godot/scenes/battle/ can ever mutate rules.gd state by reference.

Use Direct Calls Downward, Signals Upward, and an Async Presentation Queue for the Event Stream:

UI/Input -> Controller -> battle_api.gd: Input and HUD nodes emit signals upward (for example, hex_clicked(q, r), weapon_selected(slot)). The BattleSceneController receives those signals and makes direct method calls into battle_api.gd.

battle_api.gd -> Presentation Sequencer (FxDirector): Do not bind HUD and 3D ship nodes directly to raw rules state changes. Instead, have BattleSceneController pull the event stream array from battle_api.gd after each command and feed it into an asynchronous Presentation Queue (await fx_director.play_event(ev)). Each event steps the 3D animations (godot/fx/) and updates the HUD sequentially, only syncing to the final view() snapshot once the event queue drains.

5. What to Re-Check When godot/main/ Lands

When godot/main/ (and godot/scenes/battle/, godot/campaign/, godot/fx/, godot/world/) lands on main, repeat Part 3 against these specific checks:

Inspect godot/project.godot: Check run/main_scene, any newly registered [autoload] entries, whether rendering/rendering_device/driver.windows is explicitly set, and whether GDScript warnings remain globally silenced (=0).

Audit import/preload graph across directories: Verify that no file in godot/rules/ preloads or references anything in godot/main/, godot/scenes/, godot/fx/, or godot/world/, and that godot/scenes/battle/ only imports godot/rules/battle_api.gd (never reaching directly into rules.gd or jsm.gd).

Verify view() and Event Stream Consumption in godot/scenes/battle/: Check whether the battle scene mutates any Dictionary/Array returned by battle_api.gd, and verify that combat events are sequenced asynchronously rather than resolving 3D visuals and UI state on the same frame.

Check Scene Ownership and Cleanup on Transition: Verify how godot/main/ transitions between campaign map and tactical battle scenes (making sure WorldEnvironment, 3D ship meshes, and particle emitters in godot/fx/ and godot/world/ are cleanly freed without orphan nodes or leaked RIDs).

4. Not Checked

Direct live file trees and line contents of github.com/rcbailey12/voidsworn beyond Section 2 (UNSURE): Public search engines have zero indexed pages for github.com/rcbailey12/voidsworn. As a result, I could not independently fetch the live GitHub repository tree to verify whether commit f45852c8 (godot/fx/API.md, godot/fx/, godot/world/) is now visible on main, nor read the internal line numbers of godot/rules/API.md, godot/rules/battle_api.gd, godot/rules/jsm.gd, or godot/rules/rules.gd. All repo observations in Part 3 are strictly bound to the file text and metadata provided in Section 2 of the prompt.

Standalone GodotSteamKit license text at https://godotsteam.com/projects/godotsteamkit (UNSURE): While addons/godotsteam/license.md and addons/godotsteam/readme.md for GodotSteam 4.20 through 4.23.2 were verified from primary mirrors and Asset Library/Store metadata as MIT, the specific subpage https://godotsteam.com/projects/godotsteamkit is not indexed in search results, so the exact license text of the separate GodotSteamKit starter-kit project could not be quoted directly.

5. Repo Claims Tied to Files and Lines Read

Every repository claim in this review is tied to the exact file text and state provided in Section 2 (with INFERRED marking conclusions drawn from those facts):

godot/.gitignore, godot/project.godot, godot/rules/: Top-level contents of godot/ on branch main (Section 2, godot/ directory listing).

godot/project.godot (lines 1-2, header comments): States ; Voidsworn in Godot 4.7 (plan section G). godot/rules/ is the battle rules (GDScript, golden-tested against the JS game); scenes, render and UI live beside it. Used to verify the golden-test parity requirement and isolation of godot/rules/.

godot/project.godot (lines 3-5, [application]): Sets config_version=5 and config/name="Voidsworn". Has no run/main_scene, no [autoload] section, and no [rendering] driver override (INFERRED: Godot 4.7 will therefore use its default Windows d3d12 RenderingDevice driver unless configured).

godot/project.godot (lines 6-23, [debug]): Sets all 17 listed GDScript warnings (inference_on_variant, untyped_declaration, unsafe_property_access, unsafe_method_access, unsafe_cast, unsafe_call_argument, shadowed_variable, shadowed_variable_base_class, confusable_local_declaration, confusable_local_usage, return_value_discarded, incompatible_ternary, integer_division, narrowing_conversion, unused_variable, unused_parameter, shadowed_global_identifier) to 0. Used to verify that integer_division=0 is silenced project-wide rather than scoped to godot/rules/.

godot/rules/rules.gd (file size metadata in Section 2): 117,728 bytes in one file (INFERRED: roughly 2,800 to 3,500 lines of GDScript), retaining JS order and function names per Section 2 notes.

godot/rules/battle_api.gd (boundary specification in Section 2): Defines the sole interface between scenes and rules (commands in, view() out, event stream out). INFERRED risks regarding GDScript pass-by-reference Dictionary/Array mutation on view() and synchronous vs. queued event playback are derived from GDScript's reference semantics applied to this boundary.
