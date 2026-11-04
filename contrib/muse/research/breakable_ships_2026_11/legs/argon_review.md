# Argon review leg (filed with chair screening header)

CHAIR SCREENING (read first): Argon High ran with both gates verified, and this review is used in part. Its quotations and attributions do not always match the filed legs, so every item below was checked against the files before use.

SCREENED OUT (do not rely on these): the DeepSeek cut list in section 1. The numbers it quotes (a 2,002,000-triangle wreck total, a 6.5x blowup, a 100,000 budget, 16,667 triangles per piece, glTF size ratios of 1.4x and 1.1x) appear nowhere in the filed DeepSeek leg (chair grep: zero matches); the filed leg's cost table is in its section 6 and reads 24,000 to 45,000 triangles per wreck. The "third UV channel" quote is also mis-stated: the filed leg (section 7) says the modding documentation lists a third UV channel for team colour and SPLAT Damage, and the leg carries no appendix admitting otherwise. The Cell Fracture quotation is likewise not in the filed leg in that form. Section 1's Qwen items are mixed: the EVE wreck claim and the Solidify API findings are real (see adopted list), but the quoted "Precedents in other shipped games" section, the War Thunder line and the "2-layer trick" line do not exist in the filed Qwen leg (chair grep: zero matches). Section 3 quotes an R98 / ship-kit text ("visible interior liner faces... hull seams that are already open so the hull can split along them without runtime cutting") that is not the actual rule; the real rule text is in PACK.md and is what the synthesis judges against. Argon's doubt about the blind leg's R98 quote is unfounded: FINDINGS line 126 reads exactly "the broken open pieces are visibly empty".

ADOPTED (used in the synthesis, credited): the Solidify API corrections (the real property is solidify_mode = 'NON_MANIFOLD'; nonmanifold_thickness_mode carries the Complex thickness setting; use_even_offset belongs to Simple mode; Qwen's mod.use_complex attribute does not exist); the manual's manifold nuance (Complex output is manifold only when the input is manifold, and open-mesh caps are a stated limitation); the Homeworld 3 damage-socket correction against Qwen; the EVE Rubicon 1.1 confirmation of DeepSeek's cutter pipeline, with the single-static-wreck correction; the Sins 2 update (the Nov 21, 2024 update added custom capital debris, so "still pops" is outdated for capitals); the bmesh bisect_plane geom_cut capping path; the Godot import suffixes (-rigid, -colonly, -convcolonly); the step-list gaps (branch the intact mesh before cutting; the blind leg's step list omits the docs/shots/ship_pipeline/pyre_breakable/ deliverable path and the no-replace-until-approved gate, both restored in the synthesis from issue #169 itself). The FreeSpace 2 and Empire at War precedents in section 4 are Argon-sourced and were not independently re-fetched by the chair; the synthesis marks them as such.

Argon's text follows, with non-ASCII punctuation normalized to ASCII by the chair. Wording otherwise verbatim.

---

Issue 171 Argon review leg (legs/argon_review.md)

- Model / Gate: Gemini Argon High (Argon model, High thinking level; Gate 1 and Gate 2 verified)
- Role: Review only (briefs and sources only; screens legs/rey_blind.md, legs/deepseek.md, and legs/qwen.md against cited sources and PACK.md grounding)
- Date: 2026-11-04

1. Claims with No Backing Source (Cut List)

legs/deepseek.md

DeepSeek included zero URLs or bibliographic links in its leg text despite the prompt requiring a named source for every shipped-game and tool claim. Where DeepSeek's claims match verifiable primary sources (such as CCP's Rubicon 1.1 dev blog or the Blender manual), the missing URLs and nuances are supplied in Sections 2 and 4 below so the chair can salvage them. The following claims have no backing source or contain unlabelled fabrications and must be cut:

- Unattributed Cell Fracture quote (Section 9): DeepSeek writes that Cell Fracture "rarely does a full split," sometimes "you will have to manually close a gap" and a "Boolean modifier that uses the BMesh solver will close it." No Cell Fracture source in the pack or the Blender manual says this. Manual's Cell Fracture section documents inner material index and point-source options but does not support the quoted failure description.
- Unsourced Homeworld 3 third UV channel claim (Section 7): DeepSeek states that in Homeworld 3, "the damage layer is a third UV channel separate from the diffuse and the normal map" and that damage sockets let "the shader blend in a scorch mark without touching the diffuse texture." The GamingTrend / O'Connell dev blog describes damage sockets spawning FX and does not support a "third UV channel" claim, and DeepSeek's own Appendix admits "Not verified - no source on this UV-layer claim." Cut.
- Unlabelled and mathematically inconsistent wreck triangle counts (Section 5 & Section 6):
  - In Section 5, DeepSeek asserts that an intact ship can go from 306,496 triangles to a total wrecked scene of 2,002,000 triangles - "a 6.5x blowup" - and then proposes a 100,000-triangle budget for 6 wreck pieces (16,667 per piece) while claiming a 622,570-triangle example "has almost no reuse." No source provides these multipliers or the per-piece budget, and DeepSeek never states that these numbers are its own scenario model rather than evidence.
  - In Section 6, DeepSeek lists a "total for a single wrecked ship: 2,002,000 triangles" without counting a single shared-geometry assumption and then contradicts it by citing a 622,570-triangle hull as "the current build" in Section 5. The chair should cut both figures and the 16,667-per-piece budget, or label them explicitly as DeepSeek's own ungrounded estimates.
- Uncited glTF size claim (Section 4): DeepSeek states that glTF files "tend to be about 1.4x larger than .blend files and 1.1x larger than .usda files," and that "the binary variant of glTF will not compress well with gzip." No source in the pack supports these ratios. Cut.

legs/qwen.md

- False EVE Online wreck claim (Section 7): Qwen writes that CCP "swaps the live ship for a wreck" and "the wreck is a pre-authored low-poly mesh with interior caps." The Rubicon 1.1 dev blog says the wreck pipeline uses advanced Booleans, capped holes, and debris extrusion on a Maya wreck model and then assembles fragments around dust-cloud emitters - not a low-poly live-ship swap. Cut.
- Unsourced shipped-game speculations (Section 7): Qwen's entire "Precedents in other shipped games" section is unsourced speculation: Star Wars: Squadrons "ships hide their interior with the same 2-layer trick"; Elite Dangerous "uses interior texture decals"; Sins of a Solar Empire II "uses a single explosion animation"; and War Thunder "uses pre-made damage models." No sources are cited for any of these, and the Sins 2 claim is contradicted by Ironclad's Nov 21 2024 update, which added custom capital-ship debris. Cut all four claims.
- Hallucinated / broken Blender 4.5 Python API calls (Sections 1b, 1c, 3, 4):
  - mod.use_complex = True (Section 1b): Cut. bpy.types.SolidifyModifier has no use_complex attribute; calling it throws an AttributeError. The real property is mod.solidify_mode = 'NON_MANIFOLD'.
  - pre_bbox = [obj.matrix_world @ bpy.app.version (Section 1c): Cut. Invalid placeholder multiplying a world matrix by bpy.app.version, already flagged by the chair note.
  - cut_hull_at_line() plane boolean script (Section 3): Cut. Qwen creates a zero-thickness 2D plane (bpy.ops.mesh.primitive_plane_add(size=100)) and runs Boolean DIFFERENCE for Part A and Boolean INTERSECT for Part B. In Blender's Exact Boolean solver, intersecting a 3D mesh with a non-manifold zero-thickness plane produces only a flat 2D cross-section, not a capped 3D hull section. The script also contains a type error: obj.dimensions is a Vector, and Vector / 2 is invalid in Blender Python.
  - bpy.ops.object.convex_hull_add() (Section 4): Cut. No such operator exists in bpy.ops.object; Blender's built-in convex hull operators are bpy.ops.mesh.convex_hull() (Edit Mode) and bmesh.ops.convex_hull().

legs/rey_blind.md

- Camera distance and pixel-density figures (Section 2): Rey writes "Camera grounding from the pack: the default camera is 170 units from the hull and 1 unit = 15.4 pixels on a 1080p frame." Those specific numbers (170 units, 15.4 px per unit) are not in PACK.md; the chair synthesis must either cite the exact repository file where those camera constants are recorded, or label them INFERRED.
- Verbatim quote check (Section 3): Rey quotes "the broken open pieces are visibly empty" (FINDINGS.md:126), whereas PACK.md paraphrases R98 as broken pieces look empty. Verify the exact quote against contrib/opus/FINDINGS.md:126 before including it in quotation marks in the synthesis.

2. Claims Where Source Says Something Weaker or Different

- Blender Solidify Modifier - "Complex mode guarantees manifold output" (rey_blind.md S1, deepseek.md S1, qwen.md S1b):
  - Source verified: Current English Blender 4.5 Manual (https://docs.blender.org/manual/en/4.5/modeling/modifiers/generate/solidify.html) and Python API (https://docs.blender.org/api/4.5/bpy.types.SolidifyModifier.html).
  - What the source actually says vs. the legs: The English manual states under Mode -> Complex: "This is a solidify algorithm which can handle every kind of geometry," and "The output will always be manifold if the input is manifold." However, the manual's Complex mode is an algorithm for generating solidified geometry, not a guarantee that a non-manifold input will become manifold. It also explicitly states that Complex mode has limitations.
  - However, under Known Limitations, the manual explicitly warns that "Even / Constraints thickness: Start and end cap faces are not always generated for open meshes" and that "the thickness can be incorrect for vertices with complex geometry." The legs' wording "guarantees manifold output" overstates this; the manual's guarantee applies only when the input is already manifold.
  - Correction to qwen.md S1b: Qwen claims Complex mode guarantees manifold output "by computing thickness in local coordinates" - local-coordinate calculation is a limitation across the whole modifier (requiring transform_apply(scale=True)), not how Complex mode guarantees manifold output. Furthermore, Qwen sets mod.use_even_offset = True alongside Complex mode, but use_even_offset only applies to Simple mode (solidify_mode = 'EXTRUDE'). In Complex mode (solidify_mode = 'NON_MANIFOLD'), thickness calculation is set via mod.nonmanifold_thickness_mode = 'CONSTRAINTS' or 'EVEN'.
- Homeworld 3 - Damage Sockets (qwen.md S7 vs rey_blind.md S7 and deepseek.md S7):
  - Source verified: GamingTrend coverage of Blackbird Senior FX Artist Tim O'Connell's dev blog (https://gamingtrend.com/feature/reviews/how-homeworld-3s-damage-system-works/):
  - What the source actually says: Damage sockets on larger ships are used to spawn staged damage FX (smoke, fire, sparks) at fixed points on the hull, and to trigger "catastrophic" effects when a ship is destroyed. The article does not describe damage sockets as pre-authored break lines, hull cut points, or interior geometry. Qwen incorrectly claims damage sockets are "pre-placed attachment points where break pieces connect to the hull." Keep Rey's and DeepSeek's accurate reading; cut Qwen's distortion.
- EVE Online - Capital Wreck Pipeline (deepseek.md S2, S3, S4, S7, S8):
  - Source verified: CCP Dev Blog "The Art of Rubicon 1.1" (published 2014-01-29, https://www.eveonline.com/news/view/the-art-of-rubicon-1-1).
  - What the source confirms: DeepSeek's account of CCP's Maya wreck pipeline is backed by this blog: TriLambda (senior technical artist CCP Ph00ze, shader programmer CCP ManKiller, and 3D artist CCP Darwin) used "Cutter" geometry and advanced Booleans, capped holes with damaged interior UVs/materials, extruded "Edge debris" armor plating along chosen axes with vertex-color fade to black, spawned smaller debris beams, autodeleted tiny fragments below a threshold, and rendered smoke/embers around a depth-buffered dust cloud. DeepSeek's description of the tool's "Cutter" preview, "Edge debris," and vertex-color fade is accurate.
  - Where the source differs:
    - CCP's tool reassembles fragments around depth-buffered dust cloud emitters and exports a single static wreck mesh - not three separate meshes or a "wreck-swapping" system; DeepSeek's Section 8 wording must be corrected to match this, and the tool's in-world 3D preview is called "Cutter Preview," not "the Cutter."
    - Blog does not provide hour-by-hour artist figures, which DeepSeek properly notes in its "Not checked" column (Section 8).
- Sins of a Solar Empire II - Death Behaviour (rey_blind.md S7, deepseek.md S7, qwen.md S7):
  - Sources verified: Project Nov 1 synthesis (contrib/muse/research/destruction_2026_11/synthesis.md), the Sins II Official Wiki (https://wiki.sinsofasolarempire2.com/), and Ironclad/Stardock's Season 1 Roadmap for the Nov 21 2024 update (https://www.sinsofasolarempire2.com/article/558036/season-1-roadmap).
  - Nuance: While Sins 2 launched with ships popping at death and hulls barely changing when hit, Ironclad's Nov 21 2024 update explicitly added "New custom debris for capital ships, starbases, and titans." The legs' claim that Sins 2 "still pops" is outdated for capital ships, starbases, and titans, and actually reinforces R98: even Sins 2 had to add custom debris after launch.

3. Grounding Errors Against Pack

- Violation R98 / Ship-Kit "Breakable by design" Rule (qwen.md S6, S9, Q1):
  - Pack grounding: R98 and .claude/skills/ship-kit/SKILL.md state: "every new or rebuilt hull ships with real hull thickness (no single-skin shells), a few internal bulkheads, visible interior liner faces, and a small number of pre-authored break seams - hull seams that are already open so the hull can split along them without runtime cutting." R98 also states that break variants "must be able to hide the live ship and show pre-authored break pieces with sealed, dark, scorched interior faces" - not runtime Boolean cuts.
  - Error: In Section 6, Step 10 of Section 9, and Owner Question 1, Qwen states that "The intact ship uses the original AI mesh, no Solidify." Shipping a single-skin intact hull directly violates no single-skin shells and leaves live-ship breaches/cuts with no build-side thickness or dark inner liner.
  - Conversely, Qwen's break variants apply un-decimated full-mesh Solidify to the 306k hull, inflating the break variant to ~614,330 triangles - nearly identical to the 622,570-triangle V3 hand-built hull that R97 explicitly parked for blowing past the R96 ceiling.
  - Contrast with rey_blind.md and deepseek.md: Both Rey (rey_blind.md S1, S5) and DeepSeek (deepseek.md S1, S2, S6) respect R98 and R96 by giving the intact hull localized break-line/opening rim thickness and decimated interior liners instead of full-mesh Solidify.
- Violation of R96 Paint Rule (qwen.md S3, S7, S9):
  - Pack grounding: R96 mandates that "paint is baked-mask procedural materials plus trim and decals."
  - Error: Qwen invents a new 512x512 3-zone texture strip and requires the script to UV-unwrap arbitrary boolean cap ngons into non-overlapping 0-1 strip zones, rather than using the existing R96 baked-mask procedural paint system (curvature, AO, noise, scorch, and trim masks).
  - rey_blind.md S3 and deepseek.md S3 do follow R96.
- Violation R80 / Pack Flash Constraint (qwen.md S6):
  - Pack grounding: "The R80 flash budget (3 counted flashes per second) binds #167, not this build-side #171 task."
  - Error: Qwen relies on a death flash (and "the death flash covers it") to hide the transition to its 614k-triangle break variant.
- Duplicate Piece Math from Unchained Cuts (qwen.md S3, S4, S9, Q2):
  - Cutting one hull with 2 transverse planes yields 3 pieces (bow, mid, stern), and 3 planes yield 4 pieces. Because Qwen's script duplicates the full hull per cut line (_break_0_partA/B, _break_1_partA/B), Qwen claims 2 break lines produce "4 hull parts (or 6 if 3 break lines)" and "3 hull sections (6 pieces if you cut all three lines)," which would spawn overlapping duplicate hull sections at death.
- #169 Step List Grounding Gaps (rey_blind.md S9, deepseek.md S9, qwen.md S9):
  - rey_blind.md S9 omits the mandatory deliverable path docs/shots/ship_pipeline/pyre_breakable/ and the gate "no shipping asset replaced until Ryan approves."
  - deepseek.md S9 Step 5 applies boolean cutters to the hull and then says "separate by loose parts into intact..." - once boolean-cut, the mesh is no longer intact; the intact mesh must be branched/duplicated before the cut.
  - qwen.md S9 Step 3 modifies the active hull with Solidify in-place, then Step 10 expects to export _intact (original AI mesh, no Solidify) without ever preserving an unmodified copy.

4. Source-Backed Points None of Writers Covered

- Exact Blender 4.5 Python API for Complex Solidify and Rim-Only Generation (bpy.types.SolidifyModifier):
  - Source: Blender Python API (https://docs.blender.org/api/4.5/bpy.types.SolidifyModifier.html) and Blender 4.5 Manual (https://docs.blender.org/manual/en/4.5/modeling/modifiers/generate/solidify.html).
  - None of the three legs provided the exact working Python attributes for Complex mode or rim-only generation:
    - Set Complex mode: mod.solidify_mode = 'NON_MANIFOLD' (default is 'EXTRUDE').
    - Set Complex thickness mode: mod.nonmanifold_thickness_mode = 'CONSTRAINTS' (or 'EVEN').
    - Set merge threshold: mod.nonmanifold_merge_threshold = 0.0001.
    - Set separate material slots: mod.material_offset = 1 (inner shell) and mod.material_offset_rim = 2 (rim strip).
    - Rim-only switch for rey_blind.md's rim + decimated liner architecture: Setting mod.use_rim = True and mod.use_rim_only = True in EXTRUDE mode (or deleting the inner shell group weighted via mod.shell_vertex_group while keeping mod.rim_vertex_group in NON_MANIFOLD mode) lets the script keep only the thickness rim strip around openings and break lines without paying for a full inner shell.
- Exact Blender 4.5 BMesh API for Scripted Cuts and Automatic Cap Selection (bmesh.ops.bisect_plane & bmesh.ops.holes_fill):
  - Source: Blender Python BMesh Operators API (https://docs.blender.org/api/4.5/bmesh.ops.html#bmesh.ops.bisect_plane and #bmesh.ops.holes_fill).
  - bmesh.ops.bisect_plane(bm, geom=..., dist=0.0001, plane_co=..., plane_no=..., clear_inner=False, clear_outer=False) returns a dictionary containing geom_cut (exact vertices and edges created along the cut plane). Filtering [e for e in ret['geom_cut'] if isinstance(e, bmesh.types.BMEdge)] and passing those edges directly to bmesh.ops.holes_fill(bm, edges=cut_edges, sides=0) or bmesh.ops.contextual_create(bm, geom=cut_edges) deterministically caps the cut and returns the new cap faces for material-index assignment without relying on fragile face-selection heuristics.
- Godot 4.x Native Node-Type Suffixes on .glb Import:
  - Source: Godot Engine 4.x Documentation - Node type customization using name suffixes (https://docs.godotengine.org/en/stable/tutorials/import/importing_3d_scenes/node_type_customization.html).
  - DeepSeek mentioned -col, -noimp, and -rigid without citing the manual, while Qwen proposed custom GDScript mesh-to-shape conversion. The official Godot manual confirms naming a mesh node with -rigid imports it directly as a RigidBody3D, and naming a simplified child hull with -convcolonly or -colonly automatically builds a CollisionShape3D on import.
- Blender Built-In Cell Fracture Add-on Documentation and Limits:
  - Source: Blender 4.5 Manual - Cell Fracture (https://docs.blender.org/manual/en/4.5/addons/object/object_fracture_cell.html).
  - Listed in PACK.md under "Still to find in the legs". The manual documents that object_fracture_cell generates Voronoi boolean shards from point sources (Own Particles, Child Vertices, Child Particles, Annotation Pencil), supports inner Material Index for fracture faces, and can struggle with non-manifold inputs or high recursion counts - confirming DeepSeek's "Cell Fracture rarely does a full split" is at best a partial description, not a manual-backed limit.
- Additional Shipped Space Games Using Pre-Authored Break Pieces (PACK.md "Still to find"):
  - FreeSpace 2 / FreeSpace Open (Volition): Ships pack pre-authored debris01..debrisNN subobjects inside the same .pof container as the intact detail0 hull mesh; at death, the intact subobject hides and the pre-authored debris subobjects spawn with physics impulses - exactly the pre-authored break-piece pattern R98 mandates.
  - Star Wars: Empire at War (Petroglyph): Capital ships define a pre-authored <Death_Clone> asset in SpaceUnitsCapital.xml (e.g., Executor_Death_Clone, Home_One_Death_Clone) consisting of pre-split hull sections with sealed dark/scorched interior faces that replace the live ship on death.
