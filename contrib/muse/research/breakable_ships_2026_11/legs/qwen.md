Chair gate note: Qwen leg for issue #171, run 2026-11-04 from the main chat. Gate 1 passed: the selector was set from the Qwen3.7-Plus default to Qwen3.8-Max before sending. Gate 2 passed: the chat header still showed Qwen3.8-Max after generation started. PACK.md was attached to the send message; no verification slider appeared; single complete response, no picker. The leg's own date line reads 2026-11-05; the run happened 2026-11-04 (chair note, the leg is otherwise verbatim). Chair screening: this leg's EVE Online section is labelled INFERRED by the leg itself and is superseded by the DeepSeek leg's sourced account of CCP's cutter and boolean wreck pipeline. Its code snippets are illustrative; one silhouette-check line is a placeholder that does not run. Its interior geometry counts (about 30 triangles of flat bounding-box planes) are the sparse end of the range and are not the chair's adopted interior design.

legs/qwen.md
Leg: Qwen (writer) - Issue #171, breakable ships by design, the Blender build method (R98)
Model: Qwen3.8-Max (gate 1 and gate 2 verified by the launcher)
Date: 2026-11-05
Inputs: PACK.md only, plus web sources found and cited below. No other leg consulted.

1. Real hull thickness from a single-skin AI mesh

Problem
The AI-generated hulls in this project are single-skin shells (confirmed by the Nov 1 destruction synthesis: "the hull skin is single-sided, so any opening shows through the far wall"). The Solidify step must produce real, watertight thickness without inflating the exterior silhouette and without breaking on the non-manifold geometry AI meshes commonly carry.

Blender operations (all built-in, Blender 4.5)

Stage 1a - Clean the AI mesh.
AI hull meshes frequently arrive with non-manifold edges, duplicate vertices, interior faces, and zero-area faces. The script must sanitise before any thickness is applied.

```python
import bpy, bmesh

obj = bpy.context.active_object  # the AI hull, already in kit frame
bm = bmesh.from_edit_mesh(obj.data) if obj.mode == 'EDIT' else bmesh.new()
if obj.mode != 'EDIT':
    bm.from_mesh(obj.data)

bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
bmesh.ops.dissolve_degenerate(bm, verts=bm.verts, dist=0.0001)
# Remove interior faces (faces whose normal dot with their centroid direction is inverted)
bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_area() < 1e-8], context='FACES')
bm.to_mesh(obj.data)
bm.free()
obj.data.update()
```

Then run the built-in Merge by Distance (threshold 0.0001 m) and Delete -> Degenerate via bpy.ops.mesh in edit mode, or the bmesh equivalents above. Non-manifold edges are not "fixed" by merging alone; the script must next run Mesh -> Cleanup -> Fill Holes (bpy.ops.mesh.fill_holes(sides=0)) to cap any open boundary loops the AI left. This does not guarantee full manifold output, but it removes the worst cases before Solidify.

Stage 1b - Solidify modifier.
Apply a Solidify modifier with the following settings:

| Parameter | Value | Reason |
|---|---|---|
| Thickness | 0.06 m (6 cm) for capital-ship hull plating; 0.03 m for frigate-scale | Real hull plating is thin relative to ship size; the battle camera cannot resolve less. INFERRED: 6 cm chosen as a visible-but-proportionate value at battle-camera distance; must be validated in #169 close-zoom recordings. |
| Offset | -1.0 (fully inward) | Keeps the exterior silhouette identical to the AI mesh. The inner wall is generated inside the hull. |
| Even Thickness | ON | Prevents thickness variation at sharp angles, which AI meshes have many of. |
| Complex | ON | The Blender manual states complex mode "guarantees a manifold output" by computing thickness in local coordinates and handling self-intersections. This is the critical setting for dirty AI geometry. (Source: Blender Solidify modifier manual; the pack surfaces the Spanish 3.3 mirror at https://docs.blender.org/manual/es/3.3/modeling/modifiers/generate/solidify.html; the current English equivalent is https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/solidify.html.) |
| Rim | ON | Generates the edge strip connecting outer and inner walls at open boundaries, so break-line cuts later have a closed rim. |

Scripted application:

```python
mod = obj.modifiers.new(name="Solidify_hull", type='SOLIDIFY')
mod.thickness = 0.06
mod.offset = -1.0
mod.use_even_offset = True
mod.use_complex = True
mod.use_rim = True
# Apply the modifier so the result is baked into the mesh for boolean cuts later
bpy.ops.object.modifier_apply(modifier=mod.name)
```

Applying the modifier (rather than leaving it live) is necessary because later boolean and knife operations need a concrete mesh.

Stage 1c - Verify silhouette.
After Solidify, the script must confirm the exterior silhouette has not changed. Method: store the bounding-box corner coordinates before and after; they must match within 0.001 m on all axes. If they diverge, the offset was not fully inward or complex mode pushed a face outward; the script logs and halts.

```python
pre_bbox = [obj.matrix_world @ bpy.app.version  # placeholder; actual: store before Solidify]
# Compare post-Solidify bbox corners to pre-stored values
```

INFERRED: A more robust silhouette check would raycast outward from the original surface normals and confirm no new surface is hit closer than the original, but the bounding-box check is the minimum scriptable gate.

Stage 1d - Material assignment for the inner wall.
The inner wall generated by Solidify gets a second material slot. The script assigns the project's dark-interior material (see section 2 darkness rule) to the inner faces. In Blender 4.5, Solidify exposes mod.material_offset to assign the inner-shell faces to a different material index. Set mod.material_offset = 1 and ensure the object has at least two material slots: slot 0 = exterior paint (baked-mask procedural), slot 1 = dark interior structure.

What the script must NOT do
Must not use any Blender 5.x-only API (the PC runs 4.5.14; cloud bpy is 5.2). All operations above are 4.x-stable.
Must not be an unrepeatable hand edit. Every step is a bpy call in tools/blender/hull_repair/.

2. Internal decks and bulkheads sized for the battle camera

How many, how detailed
The pack's Done-when says "a few internal decks and bulkheads sized for the battle camera." The Nov 1 synthesis's first finding is: "interiors must be dark, not lit like the exterior; darkness is the fix, not more rooms."
Recommendation: 2 decks, 2-3 bulkheads per hull section.
Decks: Flat planes (subdivided once along the long axis, twice along the short axis, giving 2x3 = 6 quads = 12 triangles per deck). At battle-camera distance (INFERRED: the R96 measurements are at a distance where 306k tris fill the screen for 20 ships; individual deck surface detail below ~4 subdivisions is sub-pixel), 12 triangles per deck is sufficient. The deck gets the dark-interior material with a faint rib normal-map baked into the procedural trim sheet - no extra geometry for ribs.
Bulkheads: Vertical planes perpendicular to the ship's long axis (kit-frame x-axis: bow -x). Each bulkhead is a single quad (2 tris) or, if a doorway cutout is needed for the close-zoom recording, a quad with one rectangular hole (8 tris). 2-3 bulkheads spaced at roughly 1/4, 1/2, 3/4 of the hull length.
Total interior geometry per hull: 2 decks x 12 tris + 3 bulkheads x 2 tris = 30 triangles. This is negligible against the 306k ceiling.
INFERRED: If the close-zoom recordings in #169 reveal the interior looks too empty, a third deck or a pair of angled brace struts (4 tris each) could be added for ~20 more triangles. The darkness rule means these additions are barely visible, so the budget is generous.

Darkness rule
The interior material must be:
Very dark (albedo near 0.02-0.05), not lit by the scene's exterior lighting. In Godot, this is achieved by placing interior faces on a separate material that ignores the main directional light or uses a very low energy environment. INFERRED: In Godot 4.7 Forward+, this can be a StandardMaterial3D with albedo_color near black and emission set to a very faint warm glow only at damage edges (handled by #167's shader).
No emissive panels, no lit windows. The Nov 1 synthesis is explicit: darkness is the fix.
Compatible with #167's game-side fallback: #167 seals and darkens cuts procedurally; this authored version provides the same dark bands and structure, but pre-built. The material bands (dark structure, faint ribs) must match #167's procedural bands so there is no visual discontinuity between an authored break and a fallback-sealed cut.

Script

```python
import bpy, math

def add_interior(hull_obj, deck_count=2, bulkhead_count=3):
    # Get hull bounding box in local space
    bbox = [hull_obj.matrix_world.inverted() @ (hull_obj.matrix_world @ bpy.mathutils.Vector(c))
            for c in hull_obj.bound_box]
    min_x = min(v.x for v in bbox)
    max_x = max(v.x for v in bbox)
    min_y = min(v.y for v in bbox)
    max_y = max(v.y for v in bbox)
    min_z = min(v.z for v in bbox)
    max_z = max(v.z for v in bbox)
    length = max_x - min_x
    height = max_z - min_z
    width  = max_y - min_y

    # Decks: horizontal planes at 1/3 and 2/3 height
    for i in range(deck_count):
        frac = (i + 1) / (deck_count + 1)
        z = min_z + height * frac
        bpy.ops.mesh.primitive_plane_add(size=1)
        deck = bpy.context.active_object
        deck.name = f"{hull_obj.name}_deck_{i}"
        deck.scale = (length * 0.92, width * 0.88, 1)
        deck.location = (( min_x + max_x ) / 2, ( min_y + max_y ) / 2, z)
        deck.data.materials.append(get_dark_interior_mat())
        # Subdivide once each axis for 6 quads
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.subdivide(number_cuts=1)
        bpy.ops.object.mode_set(mode='OBJECT')

    # Bulkheads: vertical planes at 1/4, 1/2, 3/4 length
    for i in range(bulkhead_count):
        frac = (i + 1) / (bulkhead_count + 1)
        x = min_x + length * frac
        bpy.ops.mesh.primitive_plane_add(size=1)
        bh = bpy.context.active_object
        bh.name = f"{hull_obj.name}_bulkhead_{i}"
        bh.rotation_euler[1] = math.radians(90)  # rotate to vertical, perpendicular to x
        bh.scale = (width * 0.88, height * 0.90, 1)
        bh.location = (x, (min_y + max_y) / 2, (min_z + max_z) / 2)
        bh.data.materials.append(get_dark_interior_mat())
```

INFERRED: The 0.92 / 0.88 inset factors keep decks and bulkheads slightly inside the inner hull wall so they do not z-fight with the Solidify inner surface. Exact insets depend on hull shape and must be tuned per-hull in the first #169 run.

3. Two or three authored break lines with capped interior faces and damage textures

Choosing the break lines
Break lines are pre-authored cuts where the hull will separate at death. The Done-when specifies 2-3 lines. Placement criteria:
Structural logic: Lines go at natural structural boundaries - where the bow section meets the midships, where the midships meets the stern/engine block. This reads as "the ship broke at its weak points."
Camera visibility: At least one break line must be on the side facing the battle camera in the most common engagement angle. INFERRED: For the Pyre-Barge, the broadside is the most common camera angle, so at least one break line should run along the broadside.
Not parallel: Two parallel break lines produce three slab pieces that look uniform. Angle at least one line 10-20 deg off the perpendicular to the long axis for visual variety.

Cutting the hull
The script uses Boolean Difference with a cutting slab, or the Bisect tool, to split the hull mesh along each break line.
Method A - Boolean with a cutting slab (recommended for scriptability):

```python
import bpy, bmesh
from mathutils import Vector, Matrix
import math
def cut_hull_at_line(hull_obj, cut_origin, cut_normal, cut_index):
    """Split hull_obj along a plane defined by cut_origin and cut_normal.
    Produces two new objects: hull_part_A and hull_part_B."""
    # Create a large cutting plane
    bpy.ops.mesh.primitive_plane_add(size=100)
    cutter = bpy.context.active_object
    cutter.name = f"_cutter_{cut_index}"
    cutter.location = cut_origin
    # Orient the plane so its normal matches cut_normal
    cutter.rotation_euler = cut_normal.to_track_quat('Z', 'Y').to_euler()
    # Boolean Difference: hull minus cutter gives one side
    # Boolean Intersect: hull n cutter gives the other side
    # Duplicate hull first
    bpy.ops.object.select_all(action='DESELECT')
    hull_obj.select_set(True)
    bpy.context.view_layer.objects.active = hull_obj
    bpy.ops.object.duplicate()
    hull_copy = bpy.context.active_object
    # Part A: Difference
    bool_diff = hull_obj.modifiers.new(name=f"cut_diff_{cut_index}", type='BOOLEAN')
    bool_diff.operation = 'DIFFERENCE'
    bool_diff.object = cutter
    bool_diff.solver = 'EXACT'  # Blender 4.x Exact solver handles non-manifold better
    bpy.ops.object.modifier_apply(modifier=bool_diff.name)
    # Part B: Intersect on the copy
    bool_int = hull_copy.modifiers.new(name=f"cut_int_{cut_index}", type='BOOLEAN')
    bool_int.operation = 'INTERSECT'
    bool_int.object = cutter
    bool_int.solver = 'EXACT'
    bpy.ops.object.modifier_apply(modifier=bool_int.name)
    # Delete cutter
    bpy.data.objects.remove(cutter, do_unlink=True)
    hull_obj.name = f"{hull_obj.name.rsplit('.', 1)[0]}_part_A_{cut_index}"
    hull_copy.name = f"{hull_copy.name.rsplit('.', 1)[0]}_part_B_{cut_index}"
    return hull_obj, hull_copy
```

The Exact boolean solver is critical: the Fast solver produces non-manifold output on complex AI meshes. The Exact solver is slower but runs offline in a build script, so time is acceptable. (Source: Blender Boolean modifier manual, https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/boolean.html.)
Method B - Bisect (simpler, but less control over cap geometry):
bpy.ops.mesh.bisect(plane_co=cut_origin, plane_no=cut_normal, use_fill=True) cuts and optionally fills the cut face. However, use_fill produces a single ngons cap that may not triangulate cleanly for Godot. Method A is preferred because the boolean produces clean triangulated caps.
INFERRED: For the Pyre-Barge specifically, 2 break lines are sufficient (bow/midships and midships/stern). A third line could split the superstructure if the close-zoom recordings show the upper hull needs its own break.

Capping the cut faces
After the boolean split, each break surface is an open boundary. The script must cap it:
Select the boundary edge loop of the cut face on each part.
bpy.ops.mesh.edge_face_add() to create a cap face, or use bmesh.ops.contextual_create for a cleaner fill.
Assign the cap face to a dedicated material slot: the break-interior material.
The cap face is the surface the player sees when the hull splits. It must show the interior structure: dark base with faint rib lines and a damage-texture band at the torn edge.

Material bands on caps
The cap material follows #167's visual language:
Base: Very dark (albedo ~0.03), matching the interior darkness rule.
Structure ribs: Faint raised lines baked into the procedural trim sheet. The project's paint system is "baked-mask procedural materials plus trim and decals" (FINDINGS R96). The cap UVs are laid out onto the trim sheet's "interior structure" band.
Damage edge: A narrow band (outer 15-20% of the cap UV) with the damage texture: soot, scorched structure, glowing torn edges. The glow is handled by #167's shader (emission that cools over time), not baked into the texture. The texture provides the mask; #167 provides the emission animation.
INFERRED: The damage texture set can be a single 512x512 trim-strip with three zones (clean interior / scorched transition / torn edge glow-mask), shared across all break caps on all hulls. This keeps texture memory flat regardless of hull count.

Scripting the cap material assignment

```python
def assign_break_cap_material(part_obj, cap_face_indices, mat_interior, mat_damage_edge):
    """Assign material bands to cap faces.
    mat_interior: dark structure material (trim-sheet band 3)
    mat_damage_edge: damage texture material (trim-sheet band 4)"""
    mesh = part_obj.data
    # Ensure material slots exist
    if mat_interior.name not in [m.name for m in mesh.materials]:
        mesh.materials.append(mat_interior)
    if mat_damage_edge.name not in [m.name for m in mesh.materials]:
        mesh.materials.append(mat_damage_edge)

    for fi in cap_face_indices:
        # Inner faces (not on the boundary rim) get interior mat
        # Rim faces (touching the break edge) get damage mat
        mesh.polygons[fi].material_index = (
            mesh.materials.index(mat_damage_edge) if is_rim_face(mesh, fi) else mesh.materials.index(mat_interior)
        )
```

INFERRED: is_rim_face checks whether a cap face shares an edge with the original hull boundary. In practice, the script can identify rim faces by checking which cap faces have at least one edge on the mesh boundary (edge with only one adjacent face before capping).

4. Export so Godot can swap the pieces in at death

Object naming convention
Each break piece is a separate Blender object with a strict naming scheme so the Godot death code can find and swap them:
{ship_name}_intact          # the full hull, used during gameplay
{ship_name}_break_{i}_partA # piece on one side of break line i
{ship_name}_break_{i}_partB # piece on the other side
{ship_name}_break_{i}_capA  # cap face mesh for partA's cut surface (parented to partA)
{ship_name}_break_{i}_capB  # cap face mesh for partB's cut surface (parented to partB)
{ship_name}_deck_{j}        # interior deck j (parented to the relevant break part)
{ship_name}_bulkhead_{j}    # interior bulkhead j (parented to the relevant break part)
INFERRED: Parenting decks and bulkheads to the break parts they belong to means they move with the correct piece when the hull splits. The script assigns each interior element to the part whose bounding volume contains it.

Origins and pivots
Each break part's origin is set to the centroid of its break-line cap face. This means when Godot applies physics or animation to the piece, it rotates around the break line, not around the hull center. The script:

```python
def set_origin_to_break_centroid(part_obj, cap_face_indices):
    verts = [part_obj.data.vertices[vi].co
             for fi in cap_face_indices
             for vi in part_obj.data.polygons[fi].vertices]
    centroid = sum(verts, Vector()) / len(verts)
    # Move origin to centroid
    part_obj.data.transform(Matrix.Translation(-centroid))
    part_obj.matrix_world.translation += part_obj.matrix_world @ centroid
```

One GLB with named objects vs. separate files
Recommendation: one .glb file containing all parts as named objects.
Source: The Godot forum thread on importing multi-part Blender exports confirms that "a glb imports as one scene whose objects arrive as separate nodes, and an inherited scene or Save Branch as Scene gives per-part control in Godot" (https://forum.godotengine.org/t/importing-multiple-parts-from-blender/128940). Godot's docs confirm glTF 2.0 (.glb preferred) is the recommended 3D format (https://docs.godotengine.org/en/4.2/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).
A single .glb means:
One import step in Godot.
All parts arrive as children of a root node, each named per the convention above.
The death code finds parts by name: get_node("PyreBarge_break_0_partA").
Materials are shared within the file, reducing duplicate shader compilations.
The intact hull (_intact) is the visible node during gameplay. At death, the script/code hides _intact and shows all _break_* nodes, applying impulses to their physics bodies.

What the death code receives
The Godot scene for a breakable ship contains:
PyreBarge_intact - MeshInstance3D, visible during life.
PyreBarge_break_0_partA, _break_0_partB, _break_1_partA, _break_1_partB - RigidBody3D nodes with collision shapes generated from their meshes (via Shape3D.create_from_mesh() or a trimesh collision). Initially hidden and frozen.
At death: hide _intact, show all break parts, unfreeze, apply radial impulse from the damage point.
INFERRED: The collision shapes for break parts can be low-poly convex hulls generated at export time (Blender's bpy.ops.object.convex_hull_add() on a decimated copy) to keep physics cost low. The visual mesh stays high-poly; the collision is separate.

Static geometry merge at export
The pack states "static geometry merges at export." The intact hull is one merged mesh. The break parts are NOT merged with each other (they must be separate objects), but each part's hull shell + cap + decks + bulkheads within that part ARE merged into one mesh object before export. This reduces draw calls per part to 1 (or 2 if the damage-edge material is a separate pass).

```python
# Merge all children of a break part into the part object
def merge_part_children(part_obj):
    children = [c for c in part_obj.children if c.type == 'MESH']
    if not children:
        return
    bpy.ops.object.select_all(action='DESELECT')
    part_obj.select_set(True)
    for c in children:
        c.select_set(True)
    bpy.context.view_layer.objects.active = part_obj
    bpy.ops.object.join()
```

5. Chorus organic variant

Chorus hulls get "flesh and bone inside instead of metal" (ship-kit rule, FINDINGS R98). The method changes in the following ways:

| Structure replaces | Metal hull | Chorus hull |
|---|---|---|
| Hull plating (Solidify, uniform) | Solidify, uniform | Flesh membrane (Solidify with variable thickness: thicker at "muscle" ridges, thinner at membrane stretches). INFERRED: use weight-paint-driven thickness via Solidify's vertex-group thickness input. |
| Decks (flat planes) | Flat planes | Bone ribs: curved tubes (bpy.ops.curve.primitive_bezier_circle_add extruded along a path, then converted to mesh). 3-5 ribs per section, ~20 tris each. |
| Bulkheads (flat quads) | Flat quads | Membrane walls: slightly curved planes with a translucent dark-red material. 2-3 per section. |
| Break-line caps: dark metal, ribs, glow | Dark metal, ribs, glow | Break-line caps: raw flesh texture (dark red-black), exposed bone cross-sections at the rim, faint bioluminescent glow at torn edges (replaces the "glowing hot edges" of #167 with a cold organic glow). INFERRED: The #167 shader must have a Chorus variant emission profile (green-blue instead of orange-white). |
| Damage texture: soot, scorched metal | Soot, scorched metal | Damage texture: bruised flesh, torn membrane, ichor stain. |

Script differences
The Solidify step uses mod.vertex_group = "flesh_thickness" where the vertex group encodes per-vertex thickness variation. The interior generation function swaps add_decks_bulkheads() for add_bone_ribs_membranes(). The break-line boolean and export pipeline are identical - only the interior content and materials change.
INFERRED: The Chorus variant adds roughly 100-150 triangles per hull (ribs + membranes) versus 30 for metal hulls. Still negligible against the ceiling.

Compatibility with #167
Issue #167 explicitly covers Chorus: "flesh and bone inside, not metal." The authored Chorus interior must use the same darkness rule and the same material-band structure as #167's procedural fallback, so a Chorus hull that hasn't been rebuilt yet (covered by #167's procedural seal) looks consistent with one that has been authored.

6. Triangle and draw-call cost per hull against the R96 ceiling

The ceiling
FINDINGS R96: ~306,000 triangles, ~3.9 ms GPU at 20 ships (RTX 5080, Godot 4.7.2 Forward+, 1080p, MSAA 4x). The stage-5 repaired Pyre-Barge hull is 305,857 triangles. V1 with markings is 307,477 tris at 3.887 ms. The intact ship already sits at the ceiling.

Where interiors live
Critical decision: interiors must NOT ride on the intact ship.
The intact hull is already at 305,857 tris. Adding even 30 triangles of decks/bulkheads is technically possible, but the Solidify modifier doubles the hull surface. Solidify on a 306k-tri hull produces roughly 612k tris (inner + outer wall + rim). This is 2x over the ceiling.
Therefore: the Solidify interior and all break-piece geometry live ONLY on the broken variants that replace the intact mesh at death.
The intact ship uses the original single-skin AI mesh with no Solidify. At death, the intact mesh is hidden and the break-piece variants (which carry Solidify thickness, caps, decks, bulkheads) are shown. The player never sees the transition frame where both exist simultaneously (the swap is instantaneous, and the death flash covers it - though the R80 flash budget of 3 counted flashes per second binds #167, not this method).

Cost table

| Component | Tris (per hull) | Present on intact? | Present on break variants? |
|---|---|---|---|
| Hull outer shell (original AI mesh) | ~306,000 | Yes | Yes (per part) |
| Hull inner shell (Solidify) | ~306,000 | No | Yes (per part) |
| Rim edges (Solidify) | ~2,000 | No | Yes |
| Decks (2 x 12 tris) | 24 | No | Yes |
| Bulkheads (3 x 2 tris) | 6 | No | Yes |
| Break caps (3 lines x 2 sides x ~50 tris) | ~300 | No | Yes |
| Total per break-variant set | ~614,330 | - | Yes |
| Total intact | ~306,000 | Yes | - |

The break-variant set is ~614k tris, but these pieces are shown only for the dying ship, one at a time, and drift away and despawn within seconds. At 20 ships, at most 1-2 are dying simultaneously. The 3.9 ms budget is for 20 intact ships; the death moment briefly adds ~308k tris for one ship's break pieces. INFERRED: This is within the GPU budget for a 1-2 second window, especially since the death flash and particle effects already spike the frame. Must be validated in #169 recordings.

Draw calls
Each break part is one merged mesh with at most 2 material slots (interior + damage edge). Two break lines produce 4 parts + caps = ~4-8 draw calls per dying ship, replacing the 1 draw call of the intact hull. Net increase: 3-7 draw calls for ~2 seconds. INFERRED: negligible against Forward+ batching at 20 ships.

If interiors must ride on the intact ship
If Ryan decides the intact ship must show interior through existing battle-damage holes before death, the Solidify cost must be paid by cutting the AI mesh. The 306k-tri hull would need to be cut to ~153k tris (decimate) to leave room for the inner shell. This is a significant visual downgrade. Not recommended. The game-side fallback (#167) already seals and darkens existing holes on intact hulls, so no interior is visible until death.

7. How shipped space games author breakable ships

Homeworld / Homeworld 3 (Blackbird Interactive / Gearbox)
The Homeworld 3 dev blog (covered by GamingTrend, quoting Blackbird Senior FX Artist Tim O'Connell) describes a procedural Ship Breaking tool in Houdini that "simulates hull collapse and also models the internal rooms and mechanisms of a ship, then warps them so they bulge out." Larger ships have damage sockets - pre-placed attachment points where break pieces connect. Splat Damage alters surface geometry at impact points. (Source: https://gamingtrend.com/news/homeworld-3-devs-release-new-blog-post-discussing-weapon-and-unit-damage/)
The Nov 1 destruction synthesis adds: "Homeworld 3 is the best sourced case there: modelled interiors baked into the wreck offline, via Blackbird's Houdini Ship Breaking tool." The interiors are pre-modelled, not runtime-generated. The break is authored offline and the pieces are swapped at death, which is exactly the method this research proposes for this project.
Key takeaway: Homeworld 3 proves the authored-break-with-modelled-interiors method at ship scale. Their tool is Houdini (paid, not available here), but the method translates to Blender boolean cuts + Solidify interiors.

EVE Online (CCP Games)
INFERRED - no direct source found in this leg: EVE Online ships do not break apart into visible pieces at death. Ships explode in a particle/sound effect and are replaced by a wreck object (a static, pre-modelled damaged hull). The wreck is a separate asset, not a runtime fracture of the live ship. CCP dev blogs discuss the explosion VFX pipeline but do not describe authored break lines on the live ship. The wreck system is closest to the "swap at death" model proposed here, but the wreck is a single pre-made asset rather than break pieces.
Source status: INFERRED. A CCP dev blog or GDC talk would be needed to confirm. The pack lists "EVE Online break-up or wreck authoring sources (CCP dev blogs)" as still to find.

Battlefleet Gothic: Armada (Tindalos Interactive / Focus Entertainment)
The Nov 1 destruction synthesis states: "Battlefleet Gothic: Armada proves the whole dark drifting hulk." Ships that are destroyed become drifting hulks - dark, unlit, static meshes that persist in the scene. The hulk is the ship model with lights off and damage decals applied, not a fractured mesh. INFERRED: The hulk is likely a pre-authored variant of the ship model with damage textures, not a runtime break. This supports the "dark interior, no extra geometry" principle.
Source status: INFERRED. The pack lists "Battlefleet Gothic: Armada hulk authoring sources" as still to find.

Sins of a Solar Empire 2 (Ironclad Games)
The Nov 1 destruction synthesis: "Sins of a Solar Empire 2 hulls barely change when hit and ships pop at death (the cautionary case)." Ships do not deform, break, or show damage during combat; at death they simply vanish in a particle effect. No break pieces, no wrecks, no interiors.
Source status: The Nov 1 synthesis is the source. Sins 2 is the cautionary example of what NOT to do: no visual death feedback beyond a pop.

Other shipped space games
INFERRED - no verified source found in this leg:
Star Wars: Squadrons (EA Motive): Ships show progressive damage states (hull scoring, piece loss) but these appear to be pre-authored LOD damage states, not runtime fracture. No public GDC talk or dev blog found in this leg.
Elite Dangerous (Frontier): Ships do not break apart. Damage is shown via hull integrity percentage and surface scorch decals. No break pieces.
Star Citizen (Cloud Imperium): Ships have component-level damage and some large ships have interior spaces, but the break-apart-at-death model is not confirmed as shipped. INFERRED: Ship dismemberment is on the roadmap but not confirmed shipped as of this writing.
The pack lists "any shipped space game that ships pre-authored break pieces rather than runtime fracture" as still to find. Homeworld 3 is the strongest sourced example. No other game with a confirmed pre-authored break-piece pipeline was found in this leg.

Summary table

| Game | Method | Interiors? | Source |
|---|---|---|---|
| Homeworld 3 | Houdini Ship Breaking tool, pre-modelled interiors, damage sockets | Yes, modelled and baked offline | GamingTrend dev blog coverage (URL in pack) |
| EVE Online | INFERRED: pre-made wreck swap, no live-ship break | Wreck only, no live interior | INFERRED; CCP dev blog not found |
| Battlefleet Gothic: Armada | Dark drifting hulk, damage decals | Dark interior implied, no geometry | Nov 1 synthesis; INFERRED detail |
| Sins of a Solar Empire 2 | No damage, pop at death | None | Nov 1 synthesis |
| Star Wars: Squadrons | INFERRED: LOD damage states | No | INFERRED; no source found |

8. Hours per hull once the script exists

First hull (Pyre-Barge, #169)

| Task | Hours |
|---|---|
| Script the Solidify + clean pipeline, validate on the AI mesh, fix non-manifold issues specific to this hull | 4 |
| Place and tune interior decks/bulkheads, check at battle camera and close zoom | 2 |
| Author 2-3 break lines, run booleans, fix cap geometry, assign materials | 4 |
| Build damage texture trim strip (soot, scorched, glow-mask) and UV caps onto it | 3 |
| Export pipeline: naming, origins, merge, .glb, import into Godot, verify tri counts match | 2 |
| Godot death-code integration test: swap, physics impulse, despawn | 3 |
| Before/after recordings at battle camera and close zoom, iterate | 2 |
| Total first hull | ~20 hours |

INFERRED: The first hull is slow because the script is being written and the AI mesh's specific non-manifold issues are being handled for the first time. The boolean cuts may need manual vertex cleanup on the first hull.

Repeat hulls (scripted)

| Task | Hours |
|---|---|
| Run the script on the new AI hull (Solidify, clean, interior, break lines, caps, materials, export) | 1 |
| Review output: check silhouette, cap quality, interior placement; fix any hull-specific issues | 1 |
| Godot import and death-code test | 0.5 |
| Recording and sign-off | 0.5 |
| Total per repeat hull | ~3 hours |

INFERRED: Repeat hulls are fast because the script handles everything. The 1-hour review catches hull-specific non-manifold geometry or unusual hull shapes that the script's generic cleanup misses. If the AI mesh library stabilises (per FINDINGS R96, AI parts go through a reviewed per-faction library), the review time may drop to 30 minutes.

Chorus hulls
INFERRED: Add ~2 hours per hull for the organic variant (placing bone ribs and membranes instead of decks/bulkheads, swapping materials). First Chorus hull: ~24 hours. Repeat Chorus: ~5 hours.

9. Proposed step list for issue #169

This is the ordered step list Codex follows for the Pyre-Barge build-side job. It assumes #163 has picked the hull, #167 has landed, and this research (#171) has merged.
All steps are Blender scripts in tools/blender/hull_repair/. No unrepeatable hand edits.
Ingest the kept round-5 Pyre-Barge hull into the build chain. Confirm it is in kit frame (x aft / bow -x, y port, z up). Log triangle count. Gate: must be <= 306,000 tris (R96 ceiling). If over, halt and report.
Clean the AI mesh. Merge by distance (0.0001 m), dissolve degenerate faces, fill holes. Log vertex/face counts before and after. Gate: no non-manifold edges remain (check with bmesh non-manifold query).
Solidify. Apply Solidify modifier: thickness 0.06 m, offset -1.0, even thickness ON, complex ON, rim ON, material_offset = 1 (dark interior material). Apply the modifier. Gate: exterior bounding box unchanged within 0.001 m.
Generate interiors. Add 2 decks, 3 bulkheads per section 2. Assign dark-interior material. Parent each to the break part it will belong to (determined after step 5). Gate: interior tri count <= 50.
Author break lines. Define 2 break planes (bow/midships, midships/stern) with positions and normals in a config dict. Run boolean Exact cuts per section 3. Produce 4 hull parts (or 6 if 3 break lines). Gate: each part is a closed mesh (no open boundary edges except at the break line).
Cap break faces. Fill the break-line boundary on each part. Assign cap faces to break-interior material (trim-sheet interior band) and damage-edge material (trim-sheet damage band). Gate: no unassigned faces.
Build the damage trim strip. Create or verify the 512x512 trim strip with three zones (clean interior / scorched / glow-mask). UV-map all cap faces onto the appropriate zone. Gate: UVs within 0-1, no overlaps between zones.
Set origins and pivots. Each break part's origin -> centroid of its break-line cap face. Gate: origin within 0.01 m of cap centroid.
Merge per part. Join hull shell + cap + decks + bulkheads within each break part into one object. Gate: one mesh object per part.
Name and export. Rename all objects per the naming convention (section 4). Export one .glb containing: _intact (original AI mesh, no Solidify), all _break_* parts. Gate: reimport in Blender, triangle counts match export log.
Godot import and assembly. Import the .glb into the Godot project. Verify all parts arrive as named nodes. Generate convex collision shapes for break parts. Wire the death code: hide _intact, show _break_*, apply impulse. Gate: death sequence plays correctly in an isolated scene.
Record before/after. Record at battle camera and close zoom: intact ship, death moment, break pieces drifting, interior visible at close zoom. Save to docs/shots/ship_pipeline/pyre_breakable/. Gate: interiors are dark, caps show material bands, no see-through shells, no empty voids.
Measure. Log triangle count and GPU frame time at 20 ships (intact) and at 1 death event (break pieces). Compare against R96 ceiling (306k tris, 3.9 ms). Gate: intact <= 306k tris, <= 3.9 ms. Death spike <= 5.5 ms for <= 2 seconds. INFERRED: 5.5 ms allows for the brief 2x tri load of one dying ship; must be validated.
Write the build step. Document the script stages in tools/blender/hull_repair/README.md so the next hull can reuse the pipeline. Gate: README updated, script runs end-to-end on a clean checkout.
Submit for Ryan's approval. No shipping asset replaced until Ryan approves. Deliverable: tools/blender/hull_repair/ scripts + prototype outputs under docs/shots/ship_pipeline/pyre_breakable/.

Owner questions (at most five, with recommended pick)
Q1: Interior visibility on the intact ship.
The intact hull cannot carry Solidify interiors without exceeding the R96 ceiling. Interiors appear only at death (break-variant swap).
(A) Accept: interiors only on break variants, intact hull stays single-skin. # RECOMMENDED - stays within ceiling, #167 fallback covers intact-hull damage.
(B) Decimate the intact hull to ~153k tris and add Solidify so interiors are always present. - Significant visual downgrade.
(C) Raise the R96 ceiling for ships with interiors. - Requires re-benchmarking all 20-ship scenes.
Q2: Number of break lines on the Pyre-Barge.
(A) 2 break lines (bow/mid, mid/stern), producing 3 hull sections (6 pieces with caps). # RECOMMENDED - sufficient visual variety, lower tri cost, simpler physics.
(B) 3 break lines, producing 4 sections (8 pieces). - More dramatic but adds ~300 tris and 2 more physics bodies.
(C) Let the script decide based on hull length (2 if < 200 m, 3 if >= 200 m). - Adds complexity for marginal benefit.
Q3: Break-piece physics in Godot.
(A) RigidBody3D with convex collision, radial impulse at death, despawn after 8 seconds. # RECOMMENDED - simple, matches Homeworld 3's drifting-wreck feel.
(B) RigidBody3D with trimesh collision (more accurate tumbling). - Higher physics cost, marginal visual gain.
(C) Keyframed animation (no physics, pre-authored drift paths). - Cheaper but less reactive to damage position.
Q4: Damage texture scope.
(A) One shared 512x512 trim strip for all hulls and all factions (metal variant + Chorus variant = 2 strips). # RECOMMENDED - minimal texture memory, consistent look.
(B) Per-faction trim strips (6 strips). - More visual variety but 6x texture memory and 6x authoring time.
(C) Per-hull unique damage textures. - Best quality but unscalable.
Q5: Chorus variant timing.
(A) Build the Chorus organic variant script alongside the metal script in #169, test on one Chorus hull. # RECOMMENDED - ensures the pipeline handles both from the start, avoids a retrofit.
(B) Ship the metal pipeline first in #169, add Chorus in a follow-up issue. - Faster #169 delivery but risks pipeline assumptions that don't fit organic hulls.
(C) Defer Chorus until a Chorus hull enters the build pipeline. - May be never; risks the rule going stale.

Not checked / still to find
EVE Online wreck authoring: no CCP dev blog or GDC talk found. The claim that EVE uses pre-made wreck swaps is INFERRED.
Battlefleet Gothic: Armada hulk authoring detail: no Tindalos dev blog or interview found. The dark-hulk claim comes from the Nov 1 synthesis.
Sins of a Solar Empire 2: the pop-at-death behaviour is sourced from the Nov 1 synthesis. No Ironclad dev blog found.
Blender Cell Fracture add-on: mentioned in the pack as a source seed. This leg does not use Cell Fracture because it produces Voronoi (random) fractures, not authored break lines. The pack requires authored lines. Cell Fracture documentation: https://docs.blender.org/manual/en/latest/addons/object/cell_fracture.html (INFERRED URL; verify).
Blender 4.5 Solidify "complex" mode: the pack surfaces the Spanish 3.3 manual. The English 4.5 equivalent should be verified at https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/solidify.html. The claim that complex mode "guarantees manifold output" is from the pack's source seed description; verify against the current manual text.
Star Wars: Squadrons, Elite Dangerous, Star Citizen break methods: all INFERRED, no sources found.
Godot 4.7.2-specific .glb import behaviour with named objects: the forum thread is from an earlier Godot version. Verify that 4.7.2 imports multi-object .glb files as separate nodes without flattening.
Exact boolean solver performance on 306k-tri meshes: the script runs offline, but if a single boolean takes > 10 minutes, the build chain may need chunking. Not tested in this leg.
The 0.06 m hull thickness value: INFERRED. Must be validated at close zoom in #169 recordings. Too thin looks like paper; too thick looks wrong at break lines.
End of Qwen leg. Produced from PACK.md and cited web sources only. No other leg consulted. All inferred claims labelled INFERRED.
