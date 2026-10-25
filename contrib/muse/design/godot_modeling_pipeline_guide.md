# Blender to Godot modeling pipeline guide (chair, Oct 25, 2026)

Purpose: one build-from guide for the Godot path, if Godot wins the engine call. It covers the Blender to glTF to Godot chain for ship hulls and space-scene props, plus the space-scene side (sky, lighting, background). It is written for A4 (kit) and A5 (effects and environment) work. It does not decide the engine call, and nothing here applies to the Babylon path except where noted.

Claim tiers used below: DOC means read directly from Godot or Blender docs (branch noted); PRACTICE means a standard workflow convention that Opus verifies on the first import, not a doc quote; PROJECT means a rule from this project's own records (FINDINGS, SPEC, K1). Where a doc page was found on an older branch, the branch is named and a 4.7 re-check is listed at the end.

## 1. The chain in one paragraph

Model in Blender, export glTF 2.0 binary (.glb), copy the .glb and its textures into the Godot project, let Godot import it as a scene, then instantiate it through an inherited scene so the imported file itself is never edited. That last step matters: reimport overwrites the imported scene, so all game-side changes (root type, added nodes, material tweaks) live in the inherited scene, not in the import. (DOC, Godot importing scenes, 4.0 branch; the inherited-scene pattern is the same doc's workflow.)

Format choice: glTF 2.0 is Godot's recommended format, with full support for text (.gltf) and binary (.glb). Prefer .glb for shipping (smaller, single file); use .gltf only when a text diff of the model is needed. OBJ is supported but limited: no pivots, skeletons, animations, UV2, or PBR materials, so it is not a hull format. FBX goes through an external FBX2glTF program with a proprietary SDK and is not recommended where glTF works. Blender .blend files can be imported directly, but only because Godot calls Blender to export to glTF transparently, which requires Blender installed; exporting the .glb yourself is the explicit, reproducible version of the same step. (DOC, Godot importing scenes, 4.0 branch.)

## 2. Blender prep checklist (before export)

- Real size, applied transforms. Scale and rotation must be applied in Blender before export, so the exported mesh carries no surprise transform. (PRACTICE; verify on first import.)
- Triangle budget set here. Godot's importer generates LODs from the imported mesh but does not reduce it: LOD0 is the mesh you export. A 1.9 million face hull still costs 1.9 million faces up close. Set the budget in Blender, not in the import settings. (DOC, Godot mesh LOD page, 4.3 branch.)
- Quads and n-gons convert to triangles on export. Discontinuous UVs and flat-shaded edges raise the exported vertex count, because those vertices are split. Curves and other non-mesh data are not preserved and must be converted to meshes first. (DOC, Blender glTF manual, 3.2 branch, read directly.)
- Remove floaters and holes, and clean up any geometry that will never be seen. Every stray vertex ships. (PRACTICE.)
- Skeleton in rest pose before export, if the asset has one. A mesh deformed by bones at export time imports deformed. (DOC, Godot importing scenes, 4.0 branch.)
- Do not bundle artist-made LOD meshes into the .glb. They arrive as extra stacked mesh nodes, not as LODs. Artist LODs use visibility ranges (HLOD) in Godot instead. (DOC, Godot mesh LOD page, 4.3 branch.)

## 3. The ORM material contract (the single most important section)

This project already decided ORM as the single material contract (batch 8 spine). Here is what that means at the node level, in both directions.

- One ORM image carries three maps: Occlusion in R, Roughness in G, Metallic in B. glTF and Godot's ORMMaterial3D share this layout, and Godot's glTF importer wires the same layout into StandardMaterial3D via channel selectors. (DOC, Blender glTF manual, 3.2 branch, read directly: metallic in B, roughness in G, occlusion in R via a glTF Settings node group with an Occlusion input.)
- In Blender, build the ORM with a Separate RGB node: connect the image texture, separate RGB, connect G to Roughness and B to Metallic on the Principled BSDF. The exporter recognizes this arrangement as matching the glTF standard and copies the image verbatim instead of re-encoding it. Set the image texture's Color Space to Non-Color for all data maps (ORM, normal). (DOC, Blender glTF manual, 3.2 branch, read directly.)
- Occlusion specifically: there is no Principled BSDF occlusion socket. The exporter looks for a custom node group named glTF Settings with an input named Occlusion, and uses the image attached there as the glTF occlusion map. The effect need not show in Blender; it is an export-only hook. The easiest way to create the group is to import an existing glTF model that contains an occlusion map and copy its group. (DOC, Blender glTF manual, 3.2 branch, read directly.)
- Normal maps: tangent space, +Y up, through a Normal Map node (default Tangent Space setting) into the Principled BSDF normal input, image Color Space Non-Color. Godot expects OpenGL-style Y+ normals; a DirectX-baked map needs Normal Map Invert Y in the Godot Import dock plus a reimport. (DOC for the glTF side, Blender glTF manual, 3.2 branch; the Godot Invert Y step is PRACTICE from the import workflow, verify on first import.)
- Emissive: connect an image texture to the Emission input on the Principled BSDF, or use an Emission shader node. If the emissive map stands alone, set Base Color to black and Roughness to 1.0 to minimize the other channels' influence. Emissive is its own slot in the K2 effects list (emissive on its own slot, glow before tone mapping), so keep it as a separate map, not baked into base color. (DOC, Blender glTF manual, 3.2 branch.)
- Base color, metallic, and roughness may also be plain values on the Principled BSDF when no image is used. Image textures used by materials must be PNG or JPEG; the exporter converts other formats automatically at the cost of export time. (DOC, Blender glTF manual, 3.2 branch, read directly.)
- Backface culling: for materials where only front faces are visible, turn on Backface Culling in the Eevee material settings; the inverse of that setting controls glTF's DoubleSided flag. Leave it off for double-sided materials. (DOC, Blender glTF manual, 3.2 branch.)
- Alpha: glTF supports Opaque, Alpha Blend, and Alpha Clip. Transparency is complex for real-time engines and may behave unexpectedly after export; where possible use Alpha Clip, or place Opaque polygons behind only a single layer of Alpha Blend polygons. (DOC, Blender glTF manual, 3.2 branch.)
- Extensions: clearcoat and transmission exist as glTF extensions (KHR_materials_clearcoat, KHR_materials_transmission), but transmission support is not yet widespread in real-time engines. Do not build a hull material on transmission. (DOC, Blender glTF manual, 3.2 branch.)

## 4. Export settings (Blender glTF exporter)

The exporter settings that matter for this project, from the manual: export format .glb; include only the objects meant to ship (selection or collection, not the whole scene with reference rigs); apply transforms; include UVs and normals; use the Principled BSDF node arrangements from section 3 so materials copy verbatim. The full export-settings panel (including the +Y up axis option and animation options) was not re-read for this guide; the first export should be checked against the current Blender manual branch, listed at the end. (DOC, partial, Blender glTF manual, 3.2 branch; the unchecked panel items are PRACTICE until read.)

## 5. Import into Godot

- Copy the .glb and its textures into the project and let Godot import on editor focus. The imported scene's root is a Node3D named Scene Root by default; set the root type and name in the Import dock (for example a ship hull's inherited scene root) and reimport. Then create a New Inherited Scene from the .glb and do all game work there. (DOC, Godot importing scenes, 4.0 branch, plus the inherited-scene workflow from the same doc family.)
- Import dock settings that matter: meshes/generate_lods defaults to true (auto LOD on, meshoptimizer, switching by screen size); meshes/create_shadow_meshes defaults to true; meshes/ensure_tangents defaults to true; nodes/apply_root_scale defaults to true with nodes/root_scale 1.0. Per-mesh LOD disable lives in Advanced Import Settings. (DOC, ResourceImporterScene, 4.2 branch; 4.7 defaults shown in a doc mirror match, but the 4.7 branch page itself is a re-check item.)
- Collision: the standard pattern is to select the imported mesh in the inherited scene and use the Mesh menu's Create Single Convex Collision Sibling, which adds a CollisionShape3D matching the mesh. For hulls, a simple convex or box approximation is usually the right call over exact mesh collision; exact collision on a detailed hull is a performance cost for no gameplay gain in a hex game. (PRACTICE from the Godot tutorial workflow, verify at A3.)
- Reimport behavior: changing an import setting and clicking Reimport regenerates the imported scene. Game-side nodes live in the inherited scene and survive; edits made directly in the imported scene do not. (DOC, Godot importing scenes workflow.)

## 6. Hardpoints, pivots, and mount points (K1 fields)

The K1 decision (PROJECT, from FINDINGS K1 and the Job C synthesis) is that hardpoints carry: mount name, size class, allowed weapons, forward arc, and muzzle marker. In Blender, the standard way to carry these through glTF is empties: an empty object at each mount position, named for the mount, becomes a Node3D in the imported Godot scene, and the game reads its transform for the muzzle position and forward direction. (PRACTICE: empties to Node3D is the documented glTF node mapping in general, but this guide did not re-read the empty-mapping doc page, so the first import must confirm that mount empties arrive with names and transforms intact.)

Rules for mount empties (PROJECT plus PRACTICE):
- One empty per mount, named exactly for the mount (no spaces, no duplicates).
- The empty's local forward axis is the firing direction; the forward arc is a game rule read from the mount record, not from the empty's shape.
- The empty sits at the muzzle, not at the hull surface; the barrel or launcher mesh is separate geometry.
- The ship root empty (or the scene root) is the pivot for rotation and for the hex-grid placement math; do not offset the mesh from its root in Blender and expect Godot to compensate.
- Scale and orientation: Godot is Y-up with -Z forward; glTF is Y-up; Blender is Z-up and the exporter converts. The conversion is the exporter's job, but the first import must be eyeballed: a ship that arrives lying on its side or facing backward is an exporter axis setting, not a model error. (PRACTICE, verify on first import.)

## 7. Space scene side: sky, lighting, background

This section serves the A2 environment round (shared dead-star nebula sky, seeded asteroid field) and A5 environment work. It does not replace the background pack's treatments, which stand as the art direction.

- WorldEnvironment with Background mode Sky. The Environment resource's Sky subresource takes a SkyMaterial. Three built-in choices (DOC, Godot environment and post-processing, 4.3 branch): PanoramaSkyMaterial (a 2:1 panorama image; use an HDR format such as .hdr or .exr for high dynamic range; a very bright spot in an HDR panorama can cause sparkles on reflections, fixed by enabling HDR Clamp Exposure on the texture and reimporting); ProceduralSkyMaterial (procedural gradient and sun, sun position derived from the first DirectionalLight3D nodes, up to 4 suns); PhysicalSkyMaterial (physically based scattering, 1 sun, slightly more expensive than Procedural). A custom sky shader is the fourth option, for procedural clouds or a starfield; the batch 9 hash-grid sky shader technique is the candidate implementation for the starfield case.
- Freely licensed HDRIs live on Poly Haven (DOC, same page). Poly Haven is CC0 (PROJECT, from X14: checked at its primary listing). A Poly Haven HDRI used as a panorama sky is licence-clean for the public repo, but it is a placeholder for the background pack's authored nebula, not the final art.
- Lighting (PROJECT, from K2 and R21): a single key light with 25 to 40 percent cool fill and a Fresnel rim, lighting first then materials then post. The dead star is the key light's motivation in the shared A2 environment. The background pack's treatments (nebula, dead star, asteroid field) set the look; this guide sets the nodes that carry it.
- Fog: Godot's Environment supports fog, but a space scene's fog is usually off or extremely subtle; the background pack, not this guide, decides whether any fog exists. (PRACTICE.)
- Asteroids: the ~200 asteroid field is a MultiMesh case (batch 9, section 2): one material per surface, user-provided visibility AABB, lights-per-object limit applying to the whole MultiMesh. Individual hero asteroids with unique damage or paint are not MultiMesh candidates. (DOC for the MultiMesh limits, 4.0 branch; the field size is PROJECT from SPEC.)

## 8. Licence rules for anything recommended here

- Only CC0 assets, assets with a checked licence, or project-original work go into the public repo. The four plan sources checked at primary or official listings are Kenney Space Station Kit, KayKit Space Base Bits, Poly Haven, and ambientCG (all CC0, per X14 as updated by Job D). Quaternius is QAL v1.0, not CC0, and is UNSAFE for the public repo; do not recommend it or any asset whose licence has not been checked at its own listing. (PROJECT, from X14 and batch 8.)
- Community shader sites (godotshaders.com and similar) are leads, not cleared assets: check each shader's licence before it enters the repo. The batch 9 sky shader thread's technique is shader math described in a forum post, not a copied shader; implementing the technique from the description is the clean path. (PROJECT rule applied to a new source.)

## 9. First-import verification checklist (Opus, at A3)

1. Mount empties arrive with names and transforms intact.
2. ORM maps land in the right channels (R occlusion, G roughness, B metallic) with no channel swap.
3. Normal map orientation is correct (no inverted lighting); if inverted, apply Normal Map Invert Y and reimport.
4. Ship arrives upright and facing forward (axis conversion correct).
5. LOD0 triangle count matches the Blender budget; auto LOD switches at a sensible screen size.
6. Inherited scene survives a reimport with game-side nodes intact.
7. Collision sibling (convex) matches the hull well enough for hex placement math.

## Not checked

- The current Blender manual glTF exporter page (3.2 branch read; the export-settings panel details were not re-read).
- The 4.7 branches of the Godot importing scenes, mesh LOD, ResourceImporterScene, and environment pages (4.0, 4.2, and 4.3 branches found; a 4.7 doc mirror shows matching import defaults).
- The glTF empty-to-Node3D mapping doc page (practice stated, first import must confirm).
- The Asset Store listing for KayKit Space Base Bits (Asset Library replacement claim, batch 9 check item, still open).
- Whether the hash-grid sky shader performs as described on 4.7 (4.2.1-era technique; A5 test item).
- Any Babylon-side modeling chain (this guide is Godot-only by design; the Babylon kit work lives in the kit commission and A4).
