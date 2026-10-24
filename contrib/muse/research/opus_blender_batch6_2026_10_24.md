# Opus 5.5 plus Blender workflows: tips, tricks, and approaches for the known failure modes (Oct 24, 2026)

Filing note: this is the first leg of batch 6 (Opus 5.5 plus Blender workflow research), done blind with web search only. No live browser use, no sign-in, no posting, voting, or commenting. No finding below rests on Reddit material; where a source is a forum post, vendor blog, or secondary summary, that is flagged. Sourced claims are kept separate from inference in every finding. No code is included. Em dashes in the returned text have been normalized to hyphens; wording is otherwise unchanged. Chair screening is separate; reconciliation with the DeepSeek second leg comes when that leg lands.

## (a) Blender MCP servers and agent-driven Blender

FINDING 1 - The official Blender Lab MCP server exists and is pitched at analysis and scripting, not generation.
Source: Is There an Official Blender MCP? Blender Lab vs MCP for Blender vs Paid Servers (2026) - https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026
SOURCED: The official server lives with Blender Lab, reached v1.0.0 in April 2026, and is the server behind Anthropic's Blender connector for Claude. Blender's own framing is analysis, debugging, and scripting; the Blender Foundation chair is quoted as saying no generative AI functionality is currently available or planned inside Blender itself.
MY INFERENCE: Expect the official server to be the stable, conservative choice for inspecting scenes and running scripts, not a creative partner.
DECISION: ADOPT - use the official server as the default for scene inspection and scripted work.
FLAG: The source is a third-party comparison blog, not Blender documentation itself.

FINDING 2 - The community server is the widely adopted one, and it is a thin bridge, not a modeling brain.
Source: blender-mcp, PyPI - https://pypi.org/project/blender-mcp/1.9.0/ ; The 3 MCP Servers I Use to Let Claude Work Inside Blender - https://medium.com/@lince-mathew/the-3-mcp-servers-i-use-to-let-claude-work-inside-blender-6794b0ecd09f
SOURCED: The community server (originally ahujasid/blender-mcp, now also published as mcp-for-blender) pairs a Blender add-on listening on the local machine with a small MCP bridge process. Its tool surface covers scene and object info, creating and modifying primitives, materials, rendering, and executing arbitrary Blender Python. The Medium author notes the key difference from plain scripting: with MCP, Claude can look at the scene and check its own work instead of working blind.
MY INFERENCE: The community server's real value is the closed loop (inspect, act, render, re-inspect), not the size of its tool list.
DECISION: ADOPT - use the community server where the official one is too narrow, especially for the screenshot loop.
FLAG: The Medium piece is one practitioner's setup, not a benchmark.

FINDING 3 - MCP alone is insufficient for real remodeling, and the failure mode is structural, not cosmetic.
Source: Blender MCP is impressive but not that useable (yet) - https://vibingtalk.com/index.php?threads%2Fblender-mcp-is-impressive-but-not-that-useable-yet.1564293%2F ; Blender MCP Guide: Setup, Claude Integration and Real Workflows - https://vagon.io/blog/how-to-use-blender-mcp-with-anthropic-claude-ai
SOURCED: Forum critics argue most MCP demos pass generated Python to Blender one run at a time, with no undo grouping, no structured output, and no way to tell whether a failure came from the model, the script, or the scene state; one notes that for classic box modeling the tool-call stream says almost nothing about intent. The Vagon guide agrees MCP does not produce clean topology, deformation-friendly rigs, or production-ready hero models, and recommends working in passes (blockout, then materials, then lighting, then details) instead of one-shot prompts.
MY INFERENCE: Remodeling an existing mesh fails through MCP because the agent has no persistent structured representation of the mesh to edit against; it regenerates operations rather than editing a plan.
DECISION: ADAPT - treat MCP as the hands, and keep a deterministic, versioned script plus a saved scene as the real work product; never let a live MCP session be the only record of an asset.
FLAG: The forum thread is anecdotal and opinionated; the Vagon guide is vendor-adjacent content. The convergence of the two is the evidence, not either alone.

FINDING 4 - The agent-Blender loop that works is script, render, screenshot, critique, fix, with a save before every session.
Source: Blender MCP, Blender for Visual Investigation - https://blendervisualinvestigation.com/knowledge-base/docs/techniques/utility-workflows/blender-mcp/ ; blender-mcp, PyPI - https://pypi.org/project/blender-mcp/1.0.2/
SOURCED: The investigation guide's method is to inspect every AI-executed change in the outliner before saving, diff the object list before and after each session, and validate against a manual check or a deterministic measurement tool. It warns the server executes model-generated code without guards, undo is unreliable, and the user should save before every session. The community server's own docs list timeout errors as a known failure and advise simplifying requests or breaking them into smaller steps.
MY INFERENCE: The loop is only trustworthy if the render and the object-list diff are treated as test output, not as a casual glance.
DECISION: ADOPT - script, render, screenshot, critique, fix, with a pre-session save and a post-session object-list diff as mandatory steps.

FINDING 5 - Headless Blender is the fallback when the interactive MCP session is the bottleneck.
Source: Blender Render Automation skill - https://terminalskills.io/skills/blender-render-automation ; PNG Rendering with Blender, cadquery-mcp-server docs - https://deepwiki.com/rishigundakaram/cadquery-mcp-server/4.2-png-rendering-with-blender ; Blender Python API tips and tricks - https://projects.blender.org/archive/blender-archive/src/commit/25e57c39b120fd6ce6ffa022f400fd5d9f9242fc/doc/python_api/rst/info_tips_and_tricks.rst
SOURCED: Blender's own docs describe running Blender without its interface and executing a script from the command line, then checking output by rendering an image, saving a new blend file, or writing results to a file. The CAD verification pipeline described in the DeepWiki page uses exactly this shape: a subprocess runs a generated Python script inside a headless Blender instance, renders six views of a model, and feeds them to a vision model for verification. The render-automation skill notes that EEVEE in background mode still needs a working graphics context, while Cycles works headlessly.
MY INFERENCE: When MCP sessions time out or the GUI session dies, the same script run headlessly plus rendered views gives the agent eyes without the interactive session.
DECISION: ADOPT - keep every asset-generating script runnable headlessly, and make rendered multi-view images the standard verification artifact.

## (b) Separable parts for rigging and animation

FINDING 6 - Fused parts are a binding failure, not a cosmetic one, and the fix starts at generation time.
Source: How to AI Auto-Rig a 3D Character: A Complete Guide 2026 - https://www.meshy.ai/tutorials/character-auto-rigging-workflow
SOURCED: When separate parts are modeled touching each other, the binding step cannot tell which vertices belong to which bone, so fused parts move together; the classic symptoms are a cape dragging the spine and a sword generated in-hand deforming with the arm. The guide's fix is to regenerate with separation language (arms away from body, hands open, no held items), generate props separately and attach them to a bone after rigging, or separate the geometry in Blender before rigging for minor intersections.
MY INFERENCE: Separation is a generation constraint, not a cleanup step; by rigging time it is already expensive.
DECISION: ADOPT - separation language in every character brief, props always generated separately, and a fused-part check before any rigging attempt.

FINDING 7 - The pre-rigging checks that catch a fused mesh are cheap and specific.
Source: How to AI Auto-Rig a 3D Character (same as Finding 6) ; How to Create 3D Animation with Auto Rigging - https://help.meshy.ai/en/articles/16231707-how-to-create-3d-animation-with-auto-rigging
SOURCED: The guides' checks are: orbit the model and inspect armpits, hands, and anywhere clothing or props meet the body; regenerate in a T-pose or A-pose with feet spread apart so the rigging process has clear separation; and run through pose errors, asymmetry, poor topology, fused geometry, and grounding before rigging. The auto-rigging FAQ lists fused geometry as a distinct failure class with regeneration-with-separation as the remedy.
MY INFERENCE: A five-minute orbit-and-pose check saves a rigging session that would otherwise fail halfway through weight painting.
DECISION: ADOPT - a written pre-rig checklist (armpits, hands, prop contact points, feet apart, neutral pose, grounded feet) run on every generated character before rigging.

FINDING 8 - Research confirms fused limbs are a structural consequence of generating shape first and skeleton second.
Source: AniGen: Unified Fields for Animatable 3D Asset Generation - https://arxiv.org/html/2604.08746
SOURCED: The paper argues that the standard sequential pipeline (generate a static mesh, then predict skeleton and skinning as post-processing) often produces topological mismatches where the geometry lacks the structural integrity required for articulation, giving fused limbs as the example; its proposed remedy is to model shape, skeleton, and skinning as one spatially aligned representation.
MY INFERENCE: Until generators ship that unified approach, the practical defense is separable generation plus manual separation, not better post-processing.
DECISION: ADAPT - treat any single-mesh generated character as a prototype that needs a separation pass, and budget for it; do not assume a future model version fixes fusion.
FLAG: This is a research paper describing its own method; the diagnosis is useful, the proposed solution is not a shipping tool.

## (c) Humanoid and character steering

FINDING 9 - Lock the reference image early; text alone is the weakest steering.
Source: How to Generate AI 3D Models Without Losing Your Prompt's Style - https://www.tripo3d.ai/blog/explore/ai-3d-model-generator-translating-prompts-without-style-loss ; AI Character Generation: Mastering Proportions from Start to Finish - https://www.tripo3d.ai/blog/explore/how-to-generate-characters-with-ai-and-keep-proportions
SOURCED: The style guide's process is to find or create a 2D concept image embodying the exact style, feed it into an image-to-3D pathway, and still use a supporting text prompt for elements the image does not show clearly. The proportions guide states image-to-3D is its unequivocal method for specific, accurate proportions because the reference image acts as a spatial constraint that reduces anatomical guesswork, while text-to-3D is for rapid ideation.
MY INFERENCE: For a character that must match an existing style guide, the reference image is the specification; the prompt is commentary on it.
DECISION: ADOPT - no character generation starts from text alone; a locked reference image plus a short reinforcing prompt is the entry requirement.

FINDING 10 - Iterate on one thing at a time, and validate macro form before any detail.
Source: AI 3D Generation: Balancing Micro Detail and Macro Form - https://www.tripo3d.ai/blog/explore/ai-3d-model-generator-and-micro-detail-versus-macro-form ; AI Character Generation: Mastering Proportions (same as Finding 9)
SOURCED: The macro-form workflow starts with a chunky, unambiguous volume, refines silhouette only (ignoring surface texture entirely and judging the model as a pure shadow), and validates scale and proportions against a human reference before adding a single wrinkle or bolt. Detail is then applied through segmentation to one part at a time, so the model does not get inappropriate detail smeared across it. The proportions checklist adds silhouette check, landmark alignment using primitive shapes as guides (wrists at mid-hip, elbows at the waist), volume consistency and symmetry, and joint placement checked against a visualized skeleton.
MY INFERENCE: The most common steering failure is detailing a broken silhouette; the sequence (silhouette, proportions, then detail, one segment at a time) is the fix.
DECISION: ADOPT - silhouette-first, proportions-second, detail-last, with landmark guides and a joint-placement check as gates between stages.

FINDING 11 - Free generation without steering produces vague, unusable models; structured briefs are the difference.
Source: AI 3D Character Prototyping: My Expert Workflow and Best Practices - https://www.tripo3d.ai/blog/explore/ai-3d-model-generator-for-character-prototyping-only ; Character Creation in 3D: A Complete Guide for Artists - https://www.tripo3d.ai/blog/explore/character-creation-3d-2025
SOURCED: The prototyping guide treats prompts as a brief for a junior artist and uses a structured formula (subject, 3-5 defining features, pose, style reference, technical terms like clean topology and symmetrical), warning that vague prompts yield vague, often unusable models. The character guide warns that rushing into 3D without clear visual guides leads to inconsistent proportions and endless revisions, and that modeling should begin with a simple blockout to establish scale and silhouette before refinement.
MY INFERENCE: "Let the agent be creative" is the failure mode for characters; creativity belongs in the concept stage, and the generation brief should read like a spec.
DECISION: ADOPT - structured briefs with subject, defining features, pose, style reference, and technical requirements; free generation only for early ideation batches, never for a production character.
FLAG: Both sources are vendor blogs (Tripo); the advice converges with independent rigging guides above, but the sources themselves are marketing-adjacent.

FINDING 12 - Treat every AI-generated rig as a prototype that must be audited and rebuilt to a standard.
Source: AI 3D Model Retargeting: Rigging for Humanoid Standards - https://www.tripo3d.ai/blog/explore/ai-3d-model-generator-retargeting-rigs-to-humanoid-standards ; Skeletal animation guide - https://morphic.com/ai-glossary/skeletal-animation
SOURCED: The retargeting guide's audit checks hierarchy (hips, spine, chest, neck, head ordering; limbs correctly parented), joint naming consistency, bone axis orientation, skeleton-to-mesh proportion match, and skinning via basic test rotations; it notes AI rigs commonly have illogical hierarchies, missing control joints like clavicles, and skeletons that do not reflect the mesh's proportions, causing knees or elbows to bend in the wrong place. The Morphic guide adds that weight painting should be tested at extreme joint rotations before committing, since shoulders, hips, and wrists are the most common failure points.
MY INFERENCE: The audit is the steering loop's last gate; skipping it is how a character that looks fine in a neutral pose collapses in animation.
DECISION: ADOPT - a rig audit (hierarchy, naming, orientation, proportions, extreme-rotation weight test) before any generated character is accepted.

## (d) Long-generation failures and timeouts

FINDING 13 - The durable pattern is bounded sessions sharing state on disk, not one long session.
Source: How to keep a Claude Code agent running for days without losing context - https://dev.to/wrg32786/how-to-keep-a-claude-code-agent-running-for-days-without-losing-context-520b
SOURCED: The author states plainly that you do not keep one context window alive for days; you run a chain of bounded sessions sharing durable state on disk (a progress file, a task list, git history) and make the handoff between sessions automatic and checkable, because most of what goes wrong happens at the boundary between sessions, not inside them. Claude Code's own mechanisms are automatic compaction, project instruction files re-injected from disk, and session resume commands.
MY INFERENCE: A 26-minute generation that dies with nothing is a session-design failure: the work should have been chunked so each chunk leaves a file behind.
DECISION: ADOPT - every long asset job is designed as bounded sessions over file-backed state, with the handoff written before the session ends, not after.

FINDING 14 - The end-of-session ritual is: persist state, verify the write, then clear.
Source: Claude Code Context Management Guide - Long-Running Sessions - https://www.sitepoint.com/claude-code-context-management/
SOURCED: The guide's session-handoff pattern is to ask Claude to persist current state to the instruction file before ending, verify the update actually landed (for example by checking the file diff), and only then clear the session; the next session starts by reading that file and summarizing where work left off. It warns that the instruction file carries its assumptions into future sessions, so stale entries must be reviewed and removed.
MY INFERENCE: The verify-the-write step is the part most people skip, and it is exactly what turns a handoff from a wish into a resume point.
DECISION: ADOPT - persist, verify by reading back, then clear; never clear on the agent's word that it saved.

FINDING 15 - When a session is wedged or a prompt is rejected, preserve state before retrying, in a fixed order.
Source: Claude Code "Prompt Is Too Long": Fix It Without Losing Work - https://www.kitstarter.dev/blog/claude-code-prompt-is-too-long
SOURCED: The guide's recovery order is: try compacting once with a focus on plan, changed files, test state, and remaining work; rewind to an earlier turn and compact; clear and restart with a short handoff containing goal, changed files, test state, and next action; and only if the interface itself is wedged, restart the client and resume. It explicitly warns against spending retries proving the same failure.
MY INFERENCE: Retrying a timed-out generation unchanged is the most expensive response; the first action after a timeout should be to capture partial output and state, then resume from it.
DECISION: ADOPT - on any timeout or wedged session, capture partial output and write a handoff first, then retry from the handoff, never by repeating the original request.

FINDING 16 - Batch runners that shut the agent down on a timer only work if progress lives in a file.
Source: Running Claude Code in Batches for Automated Workflows - https://devguide.dev/blog/running-claude-code-in-batches-for-automated-workflows ; Claude Code Session Handoff - https://dev.to/alfredoizjr/claude-code-session-handoff-how-to-resume-work-without-re-explaining-everything-39n2
SOURCED: The batch-runner author found the context window gets foggy after about 25 items, so the solution was a script that launches Claude Code, lets it work a fixed window, shuts it down gracefully, and restarts it, with the prompt "resume" working only because the task tracks progress in a file or database. The handoff guide adds the pre-close habit: before closing, have the agent save what is done, what is next, and any decision that would be painful to re-derive, and notes that memory only holds what actually gets saved.
MY INFERENCE: Partial output is only resumable if each chunk writes its own artifact; a generation that writes nothing until it finishes cannot be resumed by any handoff trick.
DECISION: ADAPT - chunk generation so each step writes an intermediate file (partial mesh, script, or render), and make "writes nothing until done" a rejected job design.

## (e) Approved-parts persistence

FINDING 17 - Change exactly one variable per iteration and freeze everything else.
Source: Heuristic-Locked-Asset-Generation - https://gist.github.com/h4rm0n1c/ab3580a459380b631b08d6da51ac0315
SOURCED: The protocol's first rule is that each iteration introduces exactly one new variable (a pose, an emotion, a prop, an interaction) and everything else is frozen. Prompts are structured into locked style, locked structure, the asset delta (the only new information), negatives, and output requirements; once written, the prompt is considered locked. Critique uses fixed categories (style mismatch, anatomy violation, drift detected) rather than vibes, and repeated failures are folded back as new explicit rules with escalating constraint levels up to locked geometry (rearrange only, no invention).
MY INFERENCE: This is the strongest published answer to "the agent reset my approved parts": the approved parts are not a preference in prose, they are a locked section of the brief plus a one-variable rule.
DECISION: ADOPT - one-variable-per-iteration plus locked style and structure sections in every regeneration brief.

FINDING 18 - A controlled regeneration protocol: freeze what works, change one lever, compare against the previous take with the same rubric.
Source: Controlled regeneration protocol, Phase 12 Part 3 - http://ai-vid-creation.vercel.app/source/phase-12/part-3-continuity-handoffs-and-controlled-regeneration.pdf
SOURCED: The protocol is to freeze everything that already works (reference files, aspect ratio, camera if acceptable), state the failure in one sentence, choose the smallest plausible lever, make one meaningful change, render and compare against the previous take with the same rubric, and if the failure persists through the stop rule, escalate to a different method rather than piling on constraints. A take matrix keeps A/B comparisons interpretable.
MY INFERENCE: The comparison step is what makes approval durable: without a same-rubric render comparison, "approved" is just a feeling the next session cannot verify.
DECISION: ADOPT - freeze, one lever, render, compare with the same rubric, and a stop rule that forces a method change instead of more constraints.

FINDING 19 - Prompt detail alone does not enforce persistence; declarative memory is not procedural enforcement.
Source: Feature Request: Enforce Persistent Brand Rules Across Image Generation, Assets, QA, and Delivery - https://community.openai.com/t/feature-request-enforce-persistent-brand-rules-across-image-generation-assets-qa-and-delivery/1389735
SOURCED: The author reports that after dozens of correction cycles, additional prompt detail reached diminishing returns because understanding a rule did not control tool selection, asset retrieval, or generation behavior; the system needs to recognize "this version was approved" and "never regenerate this asset" as persistent production constraints, not reference information. The proposed character-identity lock keeps face, proportions, clothing, colors, and design language fixed while only performance (pose, expression, viewpoint) changes.
MY INFERENCE: For a mesh pipeline, the equivalent enforcement is mechanical, not textual: freeze the approved mesh file, version it, and regenerate only the changed part against it.
DECISION: ADAPT - enforce approval mechanically (frozen approved files, versioned parts, regeneration scoped to the changed part) rather than by asking the model harder in prose.
FLAG: This is a user feature request on a vendor forum, not a shipped capability; its value is the diagnosis, not a tool to buy.

FINDING 20 - Local-edit tooling now exists that changes one marked region and leaves the rest untouched.
Source: Meshy Edit: Fix One Part of an AI 3D Model Before You Print - https://stack-archive.com/blog/meshy-edit-local-ai-3d-model-edits-slicer-2026/ ; MIT's InstructMesh Repairs AI Generated 3D Models Before Printing - https://www.fabbaloo.com/news/mits-instructmesh-repairs-ai-generated-3d-models-before-printing
SOURCED: Meshy Edit lets a user select a region and prompt a change to that region only, leaving the rest of the geometry untouched, with every edit creating a new version and leaving the original in the user's assets. InstructMesh takes the same shape further: the user highlights a problem region, the system picks from a small set of geometric operations on an intermediate voxel representation, and the user previews the change before accepting.
MY INFERENCE: Region-scoped editing is the right primitive for approved-parts persistence; whole-model regeneration is the wrong primitive and should be the last resort.
DECISION: ADAPT - prefer region-scoped edits (or Blender-side separation plus re-assembly) over whole-model regeneration whenever only one part needs to change; keep the approved original versioned alongside every edit.
FLAG: Meshy Edit is a vendor feature report via a secondary aggregator; InstructMesh is research, not a shipping product. Both are leads, not procurement decisions.

## (f) Export and import validation

FINDING 21 - The export gate is: reimport into an empty file and verify, never trust the export dialog.
Source: Blender Model Rules - https://wiki.playgwo.com/en/guide/models.html ; Export AI Models from Blender Without Breaking Textures: My Expert Guide - https://www.tripo3d.ai/blog/explore/how-to-export-ai-models-from-blender-without-breaking-textures
SOURCED: The model rules require applying rotation and scale to mesh objects, recalculating accidentally inverted normals rather than forcing the whole weapon double-sided, separating transparent and emissive parts into named meshes, exporting only required objects, and then reimporting the result into an empty Blender file to verify direction, scale, node names, hierarchy, material slots, and rigid weights. The export guide's rule is to immediately import the exported file into a blank project in the target application and check texture presence and mapping, scale and orientation, and material properties under different lighting.
MY INFERENCE: Reimport is the single highest-value validation step because it catches every class of export loss in one pass.
DECISION: ADOPT - no asset is accepted without a reimport-into-empty-file check plus an import into the target viewer, with scale, orientation, textures, and materials each explicitly confirmed.

FINDING 22 - Texture and material validation is a checklist, not a glance: color spaces, map types, and dropped maps.
Source: glTF Model Specifications - https://deepwiki.com/immersive-web/webxr-input-profiles/7.1-gltf-model-specifications ; A Practical Browser-to-Blender Workflow for Retexturing an Existing GLB - https://medium.com/@dayue1068/a-practical-browser-to-blender-workflow-for-retexturing-an-existing-glb-359f4c3d27fd
SOURCED: The specification checklist requires PBR metallic-roughness workflow, textures embedded in the GLB, normal maps in OpenGL convention, base color in sRGB with metallic-roughness as linear data, UVs in range, and no unused nodes or materials; its issue table names the classic failures (wrong color space, inverted normal map from a DirectX-versus-OpenGL mismatch, missing geometry from node parenting). The retexturing guide's checklist adds that base color must use the intended color space, normal, roughness, and metallic must be treated as data, and the normal map must pass through a normal-map node.
MY INFERENCE: The "textures stored uncompressed while normal or metallic-roughness maps get dropped" failure is a checklist failure: each map needs an explicit presence, color-space, and node-routing check.
DECISION: ADOPT - a per-map audit (albedo sRGB, normal OpenGL convention via a normal node, roughness and metallic as linear data, all maps embedded) on every export.

FINDING 23 - Scale, pivot, and orientation failures are prevented by applying transforms and fixing the origin before export.
Source: Blender Model Rules (same as Finding 21) ; How do I export Blender models with the MSFS 2024 SDK? - https://flyawaysimulation.com/ask/answers/export-blender-models-msfs-2024-sdk/
SOURCED: Both guides require setting real-world scale (one Blender unit to one meter in the MSFS case), applying rotation and scale, removing unintended negative scale from mirrored objects, placing the origin where the model should pivot or meet the ground, and preserving the armature transform used by the animation project. The model rules add that for reversed, offset, or incorrectly scaled parts, the checks are the shared reference space, anchor spelling, node ownership, and extra root transforms.
MY INFERENCE: Pivot and scale errors look like engine bugs but are almost always unapplied transforms or a misplaced origin; the fix belongs in the pre-export checklist, not in engine-side compensation.
DECISION: ADOPT - apply transforms, fix the origin, and remove negative scale as mandatory pre-export steps, verified on reimport.

FINDING 24 - Decimation tears meshes when topology is not preserved; the controls exist and must be set deliberately.
Source: STL decimation for 3D printing: Blender and slicer tools - https://3dx.info/navigating-advanced-stl-mesh-decimation-techniques-for-optimized-3d-printing-performance/ ; How to Optimize Blender Models - Reduce Vertices and Boost - https://longroadhomeproject.com/how-to-reduce-vertices-in-blender/
SOURCED: Decimation rearranges triangles, so a clean mesh is not guaranteed to stay clean; bad edges, holes, and collapsed thin walls can appear, and the recommended check is the slicer repair warning plus Blender's mesh-analysis tools plus a slice-through inspection. The MeshLab filter reference lists the relevant guards: preserve boundary, preserve normal (to avoid flipped faces), preserve topology (to avoid collapses that close holes or squeeze handles), and planar simplification. The Blender guide adds that the vertex-group feature is the most useful and least used: paint a group over faces, hands, or a logo and weight it so those regions keep their edges while flat areas do most of the collapsing, and decimate in small increments rather than one aggressive pass.
MY INFERENCE: "Simplification tore my mesh apart" is what happens when decimation runs without topology preservation, protected regions, and a post-pass manifold check.
DECISION: ADOPT - decimate in small steps with topology preservation on, vertex groups protecting detail regions, and a non-manifold check after every pass; never accept a decimated mesh without that check.

FINDING 25 - A generated model's first stop should be a retopology and UV pass before the export checklist even starts.
Source: Export AI Models from Blender Without Breaking Textures (same as Finding 21)
SOURCED: The guide uses a generation tool as a preprocessing step to feed a complex generated model back through intelligent retopology and UV unwrapping, producing a clean animation-ready mesh with a single UV atlas and separated standard PBR maps (albedo, roughness, normal), which it describes as eliminating hours of manual cleanup before the export checklist begins.
MY INFERENCE: Running the export checklist on a raw generated mesh wastes the checklist; retopology and UV normalization first makes the checklist meaningful.
DECISION: ADAPT - retopology plus single-atlas UV plus separated PBR maps as a standard preprocessing step for generated meshes, before export validation.
FLAG: Vendor guide describing its own tool's preprocessing; the workflow shape is sound, the tool claim is unverified here.

## (g) Workflow apparatus around Opus 5.5

FINDING 26 - Opus plans and reviews; cheaper models build; the review gate sits before files change, not after.
Source: Claude Code Subagents: Setup, Config, and When to Use Them - http://dev.to/rosgluk/claude-code-subagents-setup-config-and-when-to-use-them-44m7 ; Stop Wasting Opus on Claude Pro (Claude Code Sub-Agents), video description - https://www.youtube.com/watch?v=eFSP0i_DbpY
SOURCED: The subagent guide's Explore, Plan, Execute pattern uses cheap subagents for noisy exploration, keeps the human review gate where it matters (before any agent modifies files, via plan mode), and routes cheap-to-verify work to smaller models while reserving the strongest model for reasoning-heavy steps; it notes the subagent skills field can preload full skill content into a subagent's startup context. The orchestration video describes the same shape as roles: an Opus orchestrator that plans, scores, routes, and reviews but never edits files or runs builds, with read-only scouts, implementers, and a reviewer, tasks logged with checkable criteria, and a cap on reviews per task.
MY INFERENCE: For 3D work this maps to Opus owning the brief, the acceptance gates, and the review, while smaller models or scripted passes do the bulk generation and the screenshot loop.
DECISION: ADOPT - Opus as planner and reviewer, never the bulk executor; plan mode as the gate before any geometry or material change; tasks specified with checkable criteria.

FINDING 27 - Delegation only saves effort when it is baked into the session; external handoffs cost more than they save.
Source: Does delegating save Claude quota? I measured 6 setups on 28 real tasks - https://vibingtalk.com/index.php?threads/does-delegating-save-claude-quota-i-measured-6-setups-on-28-real-tasks-haiku-alone-passed-every-check-for-93-less-handing-work-to-cheaper-models-c.1896464/
SOURCED: The benchmark's headline is that a small model alone passed every check at far lower cost, but the discussion notes only a minority of its outputs were merge-as-is versus most for Opus, so review time eats much of the saving; the handoff that actually worked was a small-model subagent inside the same session, while handing off via an external tool cost more because the lead model paid for the spec and review round trip, and an Opus-led version saved nothing because most of the bill was Opus's own planning and review turns.
MY INFERENCE: For asset work, in-session delegation with Opus reviewing is the efficient shape; bouncing briefs between separate chats or tools is the expensive one.
DECISION: ADAPT - delegate inside the session (subagents with preloaded skills), keep Opus's planning and review turns short and criteria-based, and do not route asset work through external chat handoffs.
FLAG: Forum benchmark with self-reported methodology; treat the numbers as directional, not precise.

FINDING 28 - Keep instruction files lean and path-scoped; skills load on demand, the main instruction file loads every session.
Source: How I do serious engineering on the Claude plan - https://medium.com/@ttebify/how-i-do-serious-engineering-on-the-20-claude-plan-ce95faf2dfac
SOURCED: The author treats the main instruction file as compression (a one-line note on where something lives saves the agent reading files to find out), keeps it under roughly 200 lines per Anthropic's guidance, and puts specialized instructions in skills, which load on demand only when invoked. The same piece describes starting heavy tasks with an argument rather than an edit, including plan mode with the strongest model for planning before switching to a cheaper model for execution, and a cheap debate pattern where several agents answer independently and the lead keeps the consensus plus any outlier worth a look.
MY INFERENCE: A bloated instruction file taxes every session; the 3D workflow belongs in small, path-scoped skills (geometry rules, material rules, export rules) that load only when the work touches those paths.
DECISION: ADOPT - lean main instruction file, path-scoped 3D skills loaded on demand, and plan mode with the strongest model before execution.

FINDING 29 - Skill-shaped pipelines already exist for Blender work, organized as director plus specialist skills with a screenshot-compare loop.
Source: blender-skills, SkillsLLM - https://skillsllm.com/skill/blender-skills ; Agentic XR Development Workflow Guide - https://educatian.github.io/agentic-xr-workflow/
SOURCED: The blender-skills collection runs every skill directly in Blender via MCP and organizes work as pipelines (a director skill plus specialists for hard surface, character, UV, materials, optimization, export), including a reference-image-match pipeline that runs reference analysis, camera match, geometry tiers, materials, lighting, and a screenshot-compare loop ending in visual-match and validation checklists. The XR workflow guide's smoke-test pattern is to list the MCP tools, call the scene-info tool, and check the result is non-empty before doing real work, and it warns the MCP server only runs while a Blender process is open with the server started, so disappearing tools mid-session usually mean the Blender window closed.
MY INFERENCE: The pipeline shape (director, specialists, screenshot-compare loop, validation checklist) is directly reusable for kit-style asset work, and the smoke test is a cheap guard against the most common MCP failure.
DECISION: ADOPT - director-plus-specialist skill shape with a screenshot-compare loop and validation checklist as the final gate; run the MCP smoke test at the start of every session.

FINDING 30 - Screenshot-diff critique loops need named critics and a gameplay-distance viewpoint, not generic "does this look good" prompts.
Source: blender-skills reference-image-match pipeline (same as Finding 29) ; PNG Rendering with Blender, CAD verification pipeline (same as Finding 5)
SOURCED: The reference-match pipeline ends in a screenshot-compare loop against a visual-match checklist, and the CAD pipeline renders six views of a model and feeds them to a vision model for verification against the design. Both make the critique comparative (new render versus reference or versus previous take) rather than absolute.
MY INFERENCE: A critic persona that compares two renders against a written checklist catches drift that a free-form "looks good" judgment misses, and the comparison should happen at the distance the asset will actually be seen from.
DECISION: ADAPT - named critic checks (geometry critic, material critic, silhouette critic) comparing each new render against the locked reference and the previous take, at gameplay viewing distance, against a written checklist.

## Cross-cutting synthesis for this workflow

1. MCP is the hands, not the brain: the official server for inspection and scripting, the community server for the closed loop, and a versioned script plus saved scene as the real work product.
2. Separation is a generation constraint: separable parts, props generated separately, and a pre-rig orbit-and-pose check before any rigging.
3. Characters are steered by locked reference images, silhouette-first proportions with landmark guides, one-segment-at-a-time detail, and a rig audit at extreme rotations.
4. Long jobs are chains of bounded sessions over file-backed state; every chunk writes an intermediate file, and the handoff is verified by reading it back before the session clears.
5. Approved parts are protected mechanically: one variable per iteration, locked brief sections, frozen approved files, region-scoped edits, and same-rubric render comparison against the previous take.
6. No asset is accepted without reimport into an empty file, a per-map texture audit, applied transforms with a fixed origin, and a post-decimation manifold check.
7. Opus plans and reviews behind a plan-mode gate; cheaper in-session subagents execute with preloaded skills; instruction files stay lean and path-scoped.

## Flags and unverified items carried forward

- No finding rests on Reddit material; several rest on vendor blogs (Tripo, Meshy), forum threads (Vibing Talk), or third-party comparisons, and those are flagged where they appear.
- The official Blender MCP server's version history and the community server's tool counts are as reported by third parties; confirm against the current release notes before standardizing on one.
- Meshy Edit and InstructMesh are leads, not procurement decisions; neither was hands-on tested here.
- The delegation benchmark's cost numbers are self-reported and directional only.
- Headless EEVEE rendering needs a graphics context; Cycles is the safe headless choice, per the render-automation source.
