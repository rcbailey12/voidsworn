# DeepSeek independent research leg: workflows, lighting, shaders, asset pipelines, engine MCPs (Oct 24, 2026)

Filing note: this is DeepSeek's independent research leg on the batch 2 themes (good-looking games with Claude, lighting and shaders, asset pipelines, engine MCPs), run blind to the first leg, with DeepThink ON and Search ON, no files granted, no code written, returned through the browser task. The adopt/adapt/skip verdicts below are the leg's own. Em dashes in the returned text have been normalized to hyphens; wording is otherwise verbatim. Chair screening is separate.

LEGEND: "Source" = title and exact URL as cited by the DeepSeek research; "What it says" = paraphrase of the source's claim (sourced); "Verdict" = inference for the Voidsworn project; "Could not verify" items follow the findings.

## (a) CLAUDE WORKFLOWS FOR GAME DEVELOPMENT

A1. Anthropic's Agent Skills feature
Source: Introducing Agent Skills - Claude/Anthropic, https://claude.com/blog/skills
What it says: Skills are folders of instructions, scripts, and resources that Claude loads only when relevant. They are composable, portable across Claude apps/Claude Code/API, cheap to load, and can include executable code; there is also organization-wide skill management, a partner skill directory, and publication as an open standard.
Verdict: ADOPT. Encode the ship-kit grammar, damage-state naming, shader conventions, and turn-resolution invariants as project skills so every session inherits the same rules without a giant prompt.

A2. LibreGameDev-Claude-Code: game-specific plugin/skill pack
Source: HermeticOrmus/LibreGameDev-Claude-Code - GitHub, https://github.com/HermeticOrmus/LibreGameDev-Claude-Code
What it says: A Claude Code marketplace pack of 20 game-development plugins, each with an agent, slash command, and skill, covering Godot/Unity/Unreal/web, plus a CLAUDE.md template, hooks, and reference docs. The author's thesis is that generic AI assistants produce code that compiles but "feels off" for games without game-specific feedback-loop knowledge.
Verdict: ADAPT. Borrow the Godot-engineer agent pattern and CLAUDE.md template as a starting point, but prune to the fleet-tactics domain rather than installing 20 generic plugins.

A3. Claude Code subagents for context isolation
Source: Create custom subagents - Claude Code Docs, https://code.claude.com/docs/en/sub-agents
What it says: Subagents work in their own context window with custom prompts, tool access, and permissions, keeping side tasks (search results, logs, file dumps) out of the main conversation. Built-in Explore/Plan subagents skip CLAUDE.md and git status to keep research fast; subagents can be resumed and keep their own memory.
Verdict: ADOPT. Use read-only subagents for shader research, kit audit sweeps, and long console-log triage so the main build context stays focused.

A4. CLAUDE.md, auto-memory, and lean persistent instructions
Source: How Claude remembers your project - Claude Code Docs, https://code.claude.com/docs/en/memory
What it says: Each session starts fresh; knowledge persists via user-written CLAUDE.md files and Claude-written auto-memory. CLAUDE.md should be specific and concise, with subdirectory rules loaded on demand. Docs stress CLAUDE.md is context, not enforced configuration; hard blocks need a PreToolUse hook. A best-practices write-up recommends keeping CLAUDE.md under ~200 lines.
Verdict: ADOPT. Keep a lean root CLAUDE.md holding the strict visual grammar and kit rules; put ship-class/VFX-specific rules in path-scoped files that load on demand.

A5. Plan mode as a read-only checkpoint
Source: Choose a permission mode - Claude Code Docs, https://code.claude.com/docs/en/permission-modes
What it says: Plan mode makes Claude research and propose changes without editing source; it reads files, runs exploration, writes a plan, and stays blocked on edits until the plan is approved. The plan can be edited in an editor, and plan mode can be the project default.
Verdict: ADOPT. Require a plan-mode pass before any change touching the kit grammar, damage-state shader stack, shield rendering, or scene hierarchy - the areas where bad edits are expensive to unwind.

A6. Sessions, resume/fork, and file-backed state for long builds
Sources: Work with sessions - Claude Code Docs, https://code.claude.com/docs/en/agent-sdk/sessions ; Claude-Code-Game-Studios production notes - AtomGit, https://atomgit.com/WonderfulLife/Claude-Code-Game-Studios/tree/main/production
What it says: Sessions persist conversation history to disk and can be continued, resumed by ID, or forked to try alternatives. The docs note sessions persist the conversation, not the filesystem, and point to file checkpointing for reverting file changes. The game-studios project adds the practical pattern: file-backed state, incremental writing, and auto-recovery hooks that dump session state before context compression (its "active.md" avoids "prompt too long" crashes).
Verdict: ADOPT. Resume/fork sessions for long builds, but keep the authoritative design state - part inventory, damage-state matrix, stat tables, grammar rules - in version-controlled Markdown, not chat memory.

A7. Godot's A.I. Essentials Toolkit: screenshot and editor-control loop
Source: A.I. Essentials Toolkit - Godot Asset Library, https://godotengine.org/asset-library/asset/5264
What it says: This community toolkit runs a lightweight HTTP server inside the Godot editor, giving any AI assistant editor and running-game screenshots, scene-tree dumps, property read/write, game start/stop, and GDScript parse-error validation. Two servers cooperate: an editor plugin (port 7777) for scene editing and a game autoload (port 7778) capturing the real running viewport. Stated goal: move AI from "blindly predicting code" to "edit, screenshot, see it's wrong, fix it, screenshot again." (Ports are the toolkit's claim; not independently verified.)
Verdict: ADOPT. This is the single most relevant Claude workflow for visual iteration on ships, shields, and damage states because it closes the see-change-verify loop inside the engine.

A8. Screenshot-grounded critique skills
Sources: vision-multimodal skill - fcsouza/agent-skills, https://github.com/fcsouza/agent-skills/blob/main/plugins/game-dev/infrastructure/claude-code-game-workflow/vision-multimodal.md ; critique-loop skill - barmoshe/claude-creative-stack, https://github.com/barmoshe/claude-creative-stack/blob/main/skills/critique-loop/SKILL.md
What it says: Claude Code accepts images directly (paste, drag-and-drop, programmatic capture via Playwright MCP). The vision-multimodal skill documents UI/HUD debugging, level review, game-state diagnosis, and before/after comparison. The critique-loop skill formalizes structured self-critique with personas including a shader-critic and a game-feel-critic, producing a numbered P0/P1/P2 punch list and screenshot-grounded critiques.
Verdict: ADOPT/ADAPT. Add a screenshot-diff critique loop at gameplay camera distance, using shader-critic and game-feel-critic personas, so visual drift across 20 ships is caught against the grammar rather than against isolated beauty renders.

A9. Treating the AI workflow as a production loop, not a one-shot
Source: Claude Code Briefing for 23 August - Podscan, https://podscan.fm/podcasts/claude-code-daily/episodes/claude-code-briefing-for-23-august-browser-game-production-loop-superpowers-skill-audit-subagent-fan-out-limits-plan-mode-checkpoints
What it says: A browser game moved from a one-month demo to a four-month beta by treating AI work as a production loop - many small steps, review/test/validate each one, use plan mode as a checkpoint for scope and recovery, and cap subagent fan-out. The project did not succeed by asking a model to build a complete game in one shot.
Verdict: ADAPT. Use plan-mode checkpoints and explicit subagent budgets; a solo fleet-tactics build benefits more from disciplined iteration than from large one-shot generations.

## (b) LIGHTING, SHADERS, AND VISUAL QUALITY

B1. Godot Forward+ vs Compatibility: official guidance
Source: Renderers - Godot Engine 4.4 docs, https://docs.godotengine.org/en/4.4/tutorials/rendering/renderers.html
What it says: Godot 4 has three renderers - Forward+ (most advanced, desktop-only, Vulkan/D3D12/Metal, RenderingDevice backend), Mobile (fewer features, faster for simple scenes), and Compatibility (least advanced, OpenGL, low-end desktop and web). The docs say to choose Forward+ when developing for desktop on hardware with Vulkan/D3D12/Metal support, developing a 3D game, and wanting the most advanced rendering features.
Verdict: ADOPT Forward+. A PC-only 3D fleet-tactics game with shields, decals, and post-processing is squarely the Forward+ target.

B2. Forward+ has the full feature set; Compatibility is a different visual target
Source: Renderers - feature comparison table (same page as B1), https://docs.godotengine.org/en/4.4/tutorials/rendering/renderers.html
What it says: The comparison table lists Forward+ as supporting all rendering features while Compatibility lacks advanced rendering features; switching between Compatibility and Forward+ requires more adjustment than between Mobile and Forward+. Forward+ has the highest base rendering cost but the lowest scaling cost.
Verdict: ADOPT and commit early. Do not build a Compatibility fallback for this project; it would force separate decal, shield, and lighting paths and undermine the strict visual grammar.

B3. Decals are Forward+/Mobile only
Source: Using decals - Godot docs (cited by DeepSeek at https://docs.godotengine.org/zh-cn/4.x/_sources/tutorials/3d/using_decals.rst.txt - see verification flag below)
What it says: Decals are supported in Forward+ and Mobile but not Compatibility. They are projected textures that apply PBR properties to opaque or transparent surfaces in real time without generating mesh, suited to bullet impacts, explosion scorches, dirt, and detail variation; they can fade over time and be freed with queue_free() for performance.
Verdict: ADOPT. Use decals for hull scorches, impact marks, and battle wear, but pool and fade them - 20 ships in a turn-based battle can accumulate many projected surfaces.

B4. Progressive damage with a noise-mask shader
Source: Blend damage revealed with noise texture mask - Godot Shaders, https://godotshaders.com/shader/blend-damage-revealed-with-noise-texture-mask/
What it says: The shader blends a base "untouched" texture with a damage texture using a noise texture as a mask. It exposes DamageAmount (0-100) and a threshold, so damage appears in blots and gradually covers the surface. It uses instance uniform parameters, allowing per-ship variation without unique materials.
Verdict: ADOPT. Excellent fit for progressive damage states on modular ship parts - it preserves the base material grammar and expresses damage as a controllable blend rather than a separate model.

B5. Mesh deformation as a damage cue
Source: Texture Based Damage Deform - Godot Shaders, https://godotshaders.com/shader/texture-based-damage-deform/
What it says: A simple spatial shader that deforms the mesh in the vertex stage based on a damage value and a damage texture, described as useful for showing objects damaged.
Verdict: ADAPT. Use sparingly on a few modular parts for dents or crumple, but keep deformation inside the kit's silhouette rules; uncontrolled deformation would break the strict visual grammar.

B6. Shield effects: intersection highlight and multi-impact architecture
Sources: Shield Shader with Intersection Highlight - Godot Shaders, https://godotshaders.com/shader/shield-shader-with-intersection-highlight/ ; How to Make an Energy Shield in Godot 4 - Vav Labs, https://vav-labs.com/blog/how-to-make-energy-shield-godot-4/
What it says: The Godot Shaders shield uses depth comparisons to highlight intersections with other objects, plus fresnel and a threshold (with a Compatibility NDC path noted). Vav Labs' fuller guide argues a convincing shield needs three visual states - field exists, contact has position/power, response fades without erasing recent hits - and builds a separate shell mesh, holographic shader, local-space multi-impact buffer, particles, positional audio, and a gameplay-owned damage system.
Verdict: ADOPT. A separate presentation shell with a local-space impact buffer is the right architecture for fleet shields, where several ships/weapons can hit the same shield in one turn.

B7. Environment and post-processing for visual quality
Source: Environment and post-processing - Godot Community docs, https://docs.godot.community/tutorials/3d/environment_and_post_processing.html
What it says: SSIL provides screen-space indirect lighting for small details and dynamic geometry and is meant to complement VoxelGI, SDFGI, and LightmapGI; it can be combined with SSR and/or SSAO for greater visual quality at a performance cost. SDFGI is only available in Forward+, not Mobile or Compatibility. The docs also cover glow/bloom with HDR threshold and intensity controls.
Verdict: ADAPT. Use SDFGI, SSAO, SSIL, and glow selectively for the fleet battlefield; turn-based pacing gives more lighting budget than a real-time action game, but stacking every effect on 20 ships still costs.

B8. Custom post-processing via a full-screen quad
Source: Advanced post-processing - Godot docs, https://docs.godotengine.org/en/4.2/tutorials/shaders/advanced_postprocessing.html
What it says: Custom post-processing that needs the depth buffer should use a MeshInstance3D with a screen-covering QuadMesh rather than a Viewport, because a Viewport cannot access the depth buffer and the effect is not visible in the editor. The vertex shader sets POSITION = vec4(VERTEX, 1.0) to bypass normal transforms and keep the quad screen-covering.
Verdict: SKIP/ADAPT. The built-in WorldEnvironment stack should cover most needs; only write a custom depth-based post pass if you need a specific fleet-holo, damage-readability, or selection-outline effect the built-ins cannot deliver.

## (c) ASSET PIPELINES

C1. Blender MCP: official server vs community server
Sources: Is There an Official Blender MCP? - StraySpark, https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026 ; Blender Lab MCP server - Blender Projects, https://projects.blender.org/lab/blender_mcp
What it says: The Blender Lab ships an official MCP server (documented via Blender's infrastructure) with a deliberately small 26-tool surface pitched at analysis, debugging, and scripting rather than generative art. The widely used community project formerly called "blender-mcp" renamed itself to mcp-for-blender to avoid confusion. "Official" means made by Blender developers, not the only MCP that works with Claude. The Blender Foundation has stated no generative AI functionality is currently available or planned inside Blender itself.
Verdict: ADOPT for kit automation. Use Blender MCP to automate export, validation, and batch processing of modular ship parts - not to generate the art.

C2. dcc-mcp-blender: headless automation and workflow orchestration
Source: dcc-mcp-blender - PyPI, https://pypi.org/project/dcc-mcp-blender/0.2.10/
What it says: This Blender MCP server uses a blocking dispatcher with an explicit headless loop so automation does not depend on Blender UI timers. It supports workflow orchestration (workflows.run, workflows.resume), optional semantic skill recall, render-job persistence, and explicit security switches to disable arbitrary Python/script execution.
Verdict: ADAPT. Useful for batch kit processing and export validation, but keep the arbitrary-script escape hatches disabled unless you fully trust the agent and project context.

C3. Tripo AI: production assets require more than a good preview
Source: Tripo AI Review 2027: 3D Quality, API, and Cost - WaveSpeed, https://wavespeed.ai/blog/3d-model-access/tripo-ai-review/
What it says: Tripo accepts text, single-image, or multi-view input. The review distinguishes a draft from a production asset: a production game asset may need controlled topology, UVs, separated parts, a riggable pose, and a polygon budget. Detailed textures can hide poor topology in previews. Acceptance checks include silhouette, part placement, material separation, scale after import, and whether material slots describe useful regions or merely divide one baked appearance.
Verdict: SKIP for hero ships. A strict modular ship grammar and controlled silhouettes are better served by hand-authored kit parts; Tripo is more plausible for blockouts or background props.

C4. Generative 3D tool comparison: Tripo P1 as stylized/fast
Source: Generative 3D Tools Compared: Meshy, Rodin, Tripo, and CSM - StraySpark, https://www.strayspark.studio/blog/generative-3d-tools-comparison-meshy-rodin-tripo-csm-2026
What it says: Rates Meshy 5 as the most consistently usable generalist with the best PBR textures, Rodin Gen-2 as highest geometric fidelity for hard-surface/mechanical objects, Tripo P1 as the best stylized/hand-painted look and fastest generation, and CSM Cube 2 as the best retopology - though CSM is no longer available after acquisition. The author names Tripo P1 as their go-to for stylized assets.
Verdict: ADAPT. If AI generation is used at all, Tripo P1 is the most plausible for stylized blockouts - but every generated part should be retopologized/rebuilt to the kit's grid, pivots, and material rules.

C5. Modular kit rules: grid, pivots, texture density
Source: Modular 3D Assets for Games: An AI Workflow Guide - Tripo AI, https://www.tripo3d.ai/blog/modular-3d-assets-for-games
What it says: Modular assets are reusable pieces designed to snap together on a shared grid. The guide stresses a shared measurement system (e.g., 1 m, 2 m, 4 m modules), consistent pivots and forward direction, texture-density and trim-sheet discipline, and texture atlasing/material reuse to keep draw calls down. It lists three ways to build a modular library: custom kit, bought asset pack, or AI-generated base meshes refined into game-ready pieces.
Verdict: ADOPT the rules, not necessarily the AI. Grid, pivot, texture-density, and material-reuse discipline is exactly what a strict ship-kit grammar needs; enforce it in Blender and validate it in Godot.

C6. Cascadeur for physics-assisted animation
Sources: Nekki releases Cascadeur 2026.2 - CG Channel, https://www.cgchannel.com/2026/08/nekki-releases-cascadeur-2026-2-with-animation-layers/ ; Cascadeur official site, https://cascadeur.com/
What it says: Cascadeur is a standalone 3D character animation tool focused on physics-assisted keyframe animation - AutoPosing, AutoPhysics, AI inbetweening, motion generation, ragdoll, rigging, retargeting - exporting FBX, Collada, and USD for game engines. The 2026.2 release adds an animation-layer system, easing controls, BVH import, and a new MCP server.
Verdict: ADAPT/SKIP. Turn-based fleet combat likely needs little character animation; if crew, boarding, or cinematic sequences become real requirements, Cascadeur is a strong option - but it is not central to ship-to-ship combat visuals.

C7. Asset packs vs kitbashing: consistency vs identity
Source: When to Use Asset Packs Instead of Kitbashing - Wayline, https://www.wayline.io/blog/asset-packs-vs-kitbashing
What it says: A shipped-game postmortem describes kitbashing as appealing for unique designs but prone to a "Frankenstein's monster" effect when assets come from disparate sources - clashing textures, varying poly counts, disjointed aesthetics. Asset packs offer consistency but can produce generic environments with limited personality. The recommended middle path: define the aesthetic, document a style guide, limit distinct packs, and kitbash purposefully for focal points and gaps.
Verdict: ADOPT custom kit. For a 20-ship fleet with a strict grammar, a custom modular kit with a written style guide is more controllable than asset packs, with selective kitbashing only for exceptions.

C8. Consistency from a shared art-direction grammar and anchor kit
Source: Consistent AI 3D Asset Batches: Reference Kits - G3D.AI, https://g3d.ai/research/consistent-ai-3d-asset-batches
What it says: Consistency comes from a shared grammar for shape, proportion, edge language, materials, wear, and color; an approved reference kit of anchor assets; frozen technical constraints; batch review at gameplay distance; and tracking exceptions rather than hiding them. Prompt similarity alone does not guarantee shared construction, topology, or material behavior. Recommends writing observable rules - dominant primitives, proportion ranges, corner radii, bevel language, panel density, material families, saturation limits, wear placement, forbidden motifs - and reviewing silhouettes in a lineup under one neutral rig and final project lighting.
Verdict: ADOPT. This is essentially the operating manual for a strict modular ship-kit grammar, including how to review batches and record exceptions.

C9. Pipeline audit: most AI-asset problems were pipeline problems
Source: Fit for the Engine? Image-to-3D Meshes, Their Pipeline, and an AI Assistant's Explanations in a Completed Unity Game - Zenodo, https://zenodo.org/records/23228593
What it says: A solo developer built a complete Unity game with AI coding assistants and 26 image-to-3D meshes. The audit found the raw meshes were closed and edge-manifold with UV layouts resembling the game's purchased meshes; most problems came from the pipeline around the generator - e.g., the importer reversed character fronts, the import path stored each 4096^2 base map uncompressed while dropping normal and metallic-roughness maps, and MeshLab simplification tore a mesh into 2,433 pieces. Of 39 testable assistant claims about the assets, 8 were wrong under the stricter judge, and four wrong claims blamed the generator for what the pipeline did. Defects visible in play were fixed; most off-screen defects shipped.
Verdict: ADOPT as a caution. Budget more time for import validation, map preservation, scale/pivot checks, and gameplay-distance review than for generation itself - the generator is often not the main problem.

## (d) ENGINE MCPs FOR GODOT AND BABYLON.JS

D1. Godot Editor MCP: broad editor and runtime control
Source: Godot Editor MCP - Godot Asset Library, https://godotengine.org/asset-library/asset/5434
What it says: Bridges a live Godot editor to an AI agent over WebSocket. Exposes 180 typed tools across 29 categories - inspection, scene editing, scripts, physics, runtime, testing, debugging, and more - and is game-agnostic. Every tool is tagged read_only, mutating (with dry_run), destructive (requires confirmation), or runtime. Supports GUT test suites headlessly and auto-reconnects if the editor or server starts in either order.
Verdict: ADOPT. Strong general-purpose Godot MCP for scene editing, script work, runtime checks, and tests; the safety classes matter when an agent can delete nodes or scenes.

D2. Breakpoint MCP: deep runtime and deterministic playtesting
Source: Breakpoint MCP - Godot Asset Library, https://godotengine.org/asset-library/asset/5335
What it says: Exposes both the live Godot editor and the running game through an in-game runtime autoload. Provides 291 tools across four capability planes: editor authoring (scene/node/resource CRUD, editor screenshots, undoable mutations via EditorUndoRedoManager), in-game runtime bridge (inspect SceneTree, get/set properties, call methods, emit signals, inject input, read performance monitors, freeze time, step exact frames, seed RNG, snapshot state, screenshot diffs), language/debug (GDScript and C# LSP, breakpoints via Debug Adapter Protocol), and headless CLI. Destructive tools are confirmation-gated, with a "Pause Agent" toggle.
Verdict: ADOPT/ADAPT. Very powerful for verifying turn resolution, UI state, and deterministic combat outcomes - but heavier than needed for pure asset work; use it selectively for runtime verification.

D3. godot-mcp-flash: lightweight screenshot and console loop
Source: godot-mcp-flash - npm, https://www.npmjs.com/package/godot-mcp-flash
What it says: A streamlined fork of Coding-Solo's godot-mcp with visual verification, project discovery, and scene/script analysis. It can launch the Godot editor, read console output, run a project or single scene in debug mode, capture output/errors, create scenes and add nodes, load sprites/textures, export MeshLibrary resources, validate GDScript syntax, and render a scene to return a screenshot (requires a real display).
Verdict: ADOPT as a lightweight option. Good if you want a screenshot + console + scene-edit loop without the larger tool surface of Editor MCP or Breakpoint.

D4. Godot-MCP-Native: native implementation and CLI discovery
Source: Godot-MCP-Native - GitHub, https://github.com/yurineko73/Godot-MCP-Native
What it says: A Godot plugin integrating AI assistants via MCP without a Node.js dependency. Offers 155 tools - 30 core and 125 supplementary - covering nodes, scripts, scenes, editor control, debug, and project tools. Includes a gdmcp CLI for coding agents that uses progressive discovery rather than loading all 155 tool schemas into context.
Verdict: ADAPT. Choose it if you want to avoid Node and prefer a CLI-oriented agent workflow; the progressive-discovery approach is sensible for keeping context small.

D5. Coding-Solo godot-mcp: the baseline
Source: Coding-Solo/godot-mcp - GitHub, https://github.com/Coding-Solo/godot-mcp
What it says: The widely used baseline Godot MCP can launch the Godot editor, run projects in debug mode, capture console output, control project execution, get the Godot version, list projects, create scenes, add nodes, load sprites, export MeshLibrary resources, and manage UIDs for Godot 4.4+.
Verdict: SKIP in favor of the forks above. The baseline is useful but has fewer visual/runtime verification tools than godot-mcp-flash, Godot Editor MCP, or Breakpoint MCP.

D6. Babylon.js official MCP servers: authoring-graph control
Source: Babylon.js MCP Servers - official docs, https://doc.babylonjs.com/toolsAndResources/mcpServers/
What it says: Babylon.js packages MCP servers in @babylonjs/mcp-servers. They create, edit, validate, import, export, and live-sync Babylon.js authoring graphs. Included servers cover the Node Material Editor, Node Geometry Editor, Node Render Graph Editor, Node Particle Editor, GUI Editor, Flow Graph Editor, and Smart Filters Editor. The graph servers can start a local editor session and return a session URL pasted into the matching editor's MCP session panel for live updates. The session server binds to 127.0.0.1 and stops when the MCP process exits or after 15 minutes of inactivity.
Verdict (as returned): SKIP, on the stated ground that the project is Godot-based. CHAIR CORRECTION: this ground is wrong. Voidsworn is currently built in Babylon.js, and Godot is an open question, not a decision. The correct verdict is CONDITIONAL: Babylon's graph-editor MCP servers matter if the project stays in Babylon, and are irrelevant only if Godot wins. The source itself (official Babylon MCP servers for node editors) is new and useful either way.

D7. babylonjs-inspector-mcp: inspecting a running Babylon scene
Source: babylonjs-inspector-mcp - npm, https://www.npmjs.com/package/babylonjs-inspector-mcp
What it says: Intended to let an LLM inspect a running BabylonJS scene: structured JSON scene data, WebGL introspection via Spector.js frame captures (draw calls, shader source, WebGL state, texture bindings), and VLM scene understanding from screenshots/depth maps/multi-view renders, plus a scene_evaluate escape hatch. However, its own README says it is early-development 0.x and that the browser-side client is still a stub, so tools connect and validate but return "no scene connected."
Verdict (as returned): SKIP, on the stated ground that the project is Godot-based. CHAIR CORRECTION: same correction as D6. The inspector is immature per its own README regardless of engine, so SKIP on maturity grounds stands; the Godot-based rationale does not.

## WHAT COULD NOT BE VERIFIED (leg's own flags)

- No hands-on testing: no MCP server, shader, or asset tool was installed or run. All findings are based on review of documentation, READMEs, and published reviews - not on measured performance in a 20-ship turn-based game.
- Some claims derive from search snippets rather than pages opened; those are weaker.
- Tool counts and features are version-dependent: Godot MCP counts (155, 180, 291) and Tripo model versions will change; re-check current releases before committing.
- A.I. Essentials Toolkit is a community asset, not an official Godot component; its ports (7777/7778) and stability were not independently verified.
- Blender MCP naming is genuinely confusing (official "Blender Lab" server vs community "mcp-for-blender"); the 26-tool figure comes from a secondary comparison article, not an audit of the official repo.
- Tripo quality claims are a mix of vendor marketing and third-party reviews; nothing was benchmarked against a modular ship kit with a strict grammar, so "skip for hero ships" is inference.
- Cascadeur's new MCP server (2026.2) was only mentioned in release coverage; its tool surface and Godot integration depth were not verified.
- The decals citation URL given (a Chinese-locale .rst source file path) is a non-canonical deep link; the claim (decals unsupported in Compatibility) is standard Godot documentation, but that exact URL should not be treated as the canonical reference.
- Babylon inspector MCP is explicitly pre-release (0.x, browser client a stub per its own README), so its "inspect running scene" claim is aspirational, not verified.
- No source directly tests Claude-driven visual iteration on a fleet-tactics roguelite; recommendations are extrapolations from adjacent game-dev, shader, MCP, and asset-pipeline sources.

## BOTTOM-LINE SYNTHESIS (leg's inference)

1. If moving to Godot: target Forward+ only - decals, noise-mask progressive damage, a separate multi-impact shield shell, and a restrained SDFGI/SSAO/glow environment stack are the techniques that carry the look.
2. Keep the custom modular ship kit governed by a written art-direction grammar, grid/pivot/texture-density rules, and anchor assets - not asset packs or raw text-to-3D hero ships.
3. Use Claude Code with a lean CLAUDE.md, project skills encoding the grammar, plan-mode checkpoints, context-isolating subagents, and file-backed design state so long builds survive context compression.
4. Pair a Godot MCP with a screenshot loop: A.I. Essentials Toolkit or godot-mcp-flash for a light loop; Godot Editor MCP or Breakpoint MCP for deeper scene, runtime, and deterministic-playtest control. Do not install several simultaneously.
5. Blender MCP for kit automation, not art generation; Tripo only for blockouts; Cascadeur only if character/crew animation becomes a real requirement.
6. Skip Babylon.js MCP entirely unless the engine choice changes. CHAIR CORRECTION: this inverts the actual situation. The engine choice has NOT changed; Babylon is current, Godot is the open question. The correct form is: Babylon MCP relevance is conditional on staying in Babylon; Godot MCP relevance is conditional on moving.

Notes on this leg: sign-in was not required (a working DeepSeek session already existed in the browser profile). DeepThink and Search were ON. No files were granted or attached. No code was written.
