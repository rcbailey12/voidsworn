Both gates passed: Gate 1, the model selector showed Qwen3.8-Max before sending; Gate 2, the chat header still showed Qwen3.8-Max after generation started. The model returned a single response (no "Which response do you prefer?" picker appeared).

Ship Pipeline Research Report (Board Issue 76)

# Ship Pipeline Research Report (Board Issue 76)

## 1. The decision the board needs to make

The board needs to decide whether to approve a **single AI-assisted pipeline for producing all the ships in Board Issue 76**, using the tools and file formats already in the pack. This is not a decision about one ship. It is a decision about whether a common, repeatable route from reference image to game-ready model can be trusted across a fleet that mixes several factions, hull sizes, and visual languages, and whether the work that is left can be done inside the constraints already stated: free tools only, a one-person project, and agent help as the main labour.

**Decision:** Approve **Option 3, one pipeline, with per-hull passes, a shared UV/material/colour system, and a fallback to AI-assisted sculpting where the mesh generator fails.** The pipeline is feasible for the core fleet, but it is not yet proven for the largest hulls and the most detailed stations. The board should approve it **in stages**, not as a single open-ended commitment. Stage 1 is the four core hulls already in the pack. Stage 2, the remaining hulls and the most detailed stations, should only be authorised after Stage 1 has produced at least one game-ready ship of each core class and the per-hull cost in time and rework has been measured.

The reason for staging is in the evidence. The pack shows a working route for a small, simple ship (the fighter) and for a medium hull (the destroyer) in progress, but it does not show a finished large capital ship, a detailed station, or a Chorus organic variant through the same route. A single pipeline is still the right answer, splitting the fleet across different pipelines would break the shared UV, material, and colour work that the pack already treats as common, but the board should not treat approval of the pipeline as approval that every hull will come out at the same quality or cost.

## 2. The recommended pipeline, in order

The pipeline below follows the pack's own order and fills only the gaps the pack leaves open. Where the pack gives a concrete rule, it is stated as a rule. Where the pack gives a tool but not a procedure, the procedure is stated as a recommendation and marked as such.

### Step 1, Lock the reference image

**Rule from the pack:** Each ship starts from a reference image. For the fighter (S1_51) the pack already fixes the reference: the Sword of Light screenshot. For other hulls, the reference is not fixed in the pack. Do not generate a hull without a locked reference. A locked reference means:

- a single image (screenshot, concept, or AI image) chosen as the visual target;
- a written note of which features are essential (silhouette, main volumes, colour blocks) and which are incidental (background, lighting, battle damage in the screenshot);
- a scale reference where possible (for example, the Sword of Light's 2.5 m figure for the fighter, or a comparable human-scale cue for a station).

**Why this matters:** The pack's evidence for the fighter shows what happens without this discipline: the first AI mesh (TRELLIS.2) came out "blobby and low-detailed," and the sculpting pass had to add "decal-like details" and a "distinct cockpit" after the fact. A locked reference with essential features listed before generation makes the difference between "the model looks like the ship" and "the model looks like a generic hull that has been decorated afterwards" measurable.

### Step 2, Generate the base mesh with TRELLIS.2

**Rule from the pack:** TRELLIS.2 (the text/image-to-3D step in the pack's ComfyUI workflow, and the "AI mesh" in the fighter evidence) is the default base-mesh generator.

**Recommendation, one generation, one check, then decide:**

1. Run TRELLIS.2 once from the locked reference.
2. Check the result against the essential-features list from Step 1. Do not check it against the reference image pixel-for-pixel; check silhouette, main volumes, and proportions.
3. If the silhouette and main volumes are correct, move to Step 3 (cleanup and sculpting). If they are wrong, the hull is the wrong shape, the main volumes are missing, or the proportions are off by more than the tolerance the artist sets for that hull, do not try to sculpt a wrong base into shape. Go to Step 2A (fallback).

**Step 2A, Fallback: AI-assisted sculpting from a clean base**

**Rule from the pack:** The pack already names the fallback: AI-assisted sculpting (the workflow that produced the fighter's Blender file `s1_51_fighter_clean.blend` and its `base_mesh_v2` version). The fallback is not "sculpt by hand from nothing." It is: start from a clean, simple base (a subdivided primitive, a cleaned TRELLIS.2 output that has been reduced to its main volumes, or a blockout) and use AI-assisted sculpting tools to build up the hull volumes, then move to Step 3.

**Decision rule for when to use the fallback:** Use it when TRELLIS.2 fails the essential-features check twice (two different prompts/settings, or two different reference crops if the reference is ambiguous). Do not run TRELLIS.2 repeatedly in the hope that a later run will be "better" without changing the input; the pack gives no evidence that repeated identical runs improve the result, and the fighter evidence shows that sculpting was needed even after a TRELLIS.2 run.

**Recommendation, record the fallback:** For each hull, record whether it used TRELLIS.2 directly or the fallback, and why. This is the only way the board can later judge whether the pipeline is actually a TRELLIS.2 pipeline with occasional help, or a sculpting pipeline with occasional TRELLIS.2 help. The pack does not contain this record for the fleet as a whole, only for the fighter.

### Step 3, Cleanup, sculpting, and hard-surface detailing in Blender

**Rule from the pack:** Blender is the cleanup and detailing tool. The fighter evidence is the template:

- **Cleanup:** Remove the "blobby" surface, reduce noise, and separate the main volumes.
- **Sculpting:** Add the "distinct cockpit," panel lines, and other hard-surface features that TRELLIS.2 missed. The pack describes these as "decal-like details" on the fighter, treat them as modelled geometry or as normal-map decals only if the project's normal-map rule (Step 5) allows it; do not leave them as floating, unattached geometry.
- **Hard-surface pass:** For ships with flat panels, greebles, and engine blocks (the destroyer and larger hulls especially), add a hard-surface pass after sculpting. The pack does not name a hard-surface tool, so use Blender's native hard-surface workflow (bevels, boolean cutters, and panel extrusions) rather than adding a new paid tool.

**Recommendation, a "clean" checkpoint:** Before leaving Blender, the model must pass a clean checkpoint:

- manifold geometry (no non-manifold edges that would break UV unwrapping or game export);
- main volumes separated as named objects or collections (hull, cockpit/canopy, engines, weapons, antennae) so that the UV/material pass can assign materials per part;
- a named, saved Blender file following the fighter's pattern (`<hull_id>_<name>_clean.blend`) and a versioned base mesh (`base_mesh_v2` or equivalent) so that a later rework does not overwrite the last good state.

The pack shows this pattern for the fighter but does not state it as a rule for the fleet. Make it a rule now, or the fleet will accumulate unversioned Blender files that cannot be compared.

### Step 4, UV unwrapping and texture-map baking

**Rule from the pack:** The pack's "Shared UV and Material System" is the system for this step. It is not optional, and it is not per-ship. The system is:

- **One UV layout approach for all hulls:** The pack states that the system provides a shared UV layout. In practice, this means: unwrap each hull with the same texel-density target, the same seam strategy (seams on hard edges and hidden faces where possible), and the same map resolution tiers (the pack does not give numbers, set them in Stage 1 and do not change them mid-fleet).
- **Shared material slots:** All hulls use the same material slots (hull primary, hull secondary, accent, glass/canopy, engine glow, weapon metal, etc.). A hull may leave a slot empty; it may not invent a new slot without updating the shared system document.
- **Texture-map baking:** Bake the maps the game needs from the high-detail Blender model to the game-ready model. The pack names the game-ready formats (see Step 6) but does not list the maps; the minimum set for this project is: albedo/diffuse (colour), normal, roughness, and metallic (or a combined metallic-roughness map if the engine expects it), plus an emissive map where engine glow or lights are needed. Do not bake a map the engine will not read, and do not skip a map the engine needs, confirm the engine's map list in Stage 1.

**Recommendation, bake once, reuse the system:** Because the UV/material system is shared, the first hull through this step (the fighter, already in progress) should be used to lock the texel-density, seam, and map-resolution numbers. Later hulls should reuse those numbers without re-debating them. If a later hull needs a different resolution (a capital ship with more surface area), handle it by using more UV tiles at the same texel density, not by lowering the density for that hull.

### Step 5, Material and colour assignment from FAC3D

**Rule from the pack:** Colour comes from FAC3D. The pack names FAC3D as the colour source, and it names the factions (see Part 4). The rule is:

- Each faction's hull colours are taken from FAC3D entries, not invented per ship.
- Each ship's material assignment (which FAC3D colour goes on which material slot from Step 4) is recorded per hull, so that a later change to a FAC3D entry can be propagated.
- The Chorus organic variant (see Part 4) is the exception that proves the rule: its colour must also come from FAC3D, and if FAC3D does not contain suitable organic tones, that is a gap to be fixed in FAC3D, not a licence to invent colours per ship.

**Recommendation, a colour sheet per hull:** For each hull, produce a one-page colour sheet before texturing: FAC3D entry, material slot, and a swatch. This is cheap, it prevents the "the ship looks right in Blender but wrong in the game" problem (different lighting, different material response), and it gives the board a checkable artefact for Stage 1.

### Step 6, Export to the game-ready format and build the shared hull files

**Rule from the pack:** The pack names two game-ready formats and a shared-file concept. The rule is:

- **Export the game-ready model** in the formats the pack names: `.vs` (the game's ship format) and `.vsm` (the format that carries the material/UV information for the shared system). The pack does not state which is primary; treat `.vs` as the ship definition and `.vsm` as the material/UV companion, and export both for every hull. Do not export only one and assume the other is implied.
- **Build the shared hull files:** The pack states that the browser build (see Part 7) shares the hull files. In practice, this means: the exported `.vs`/`.vsm` files, the baked texture maps, and the shared material definitions are stored as shared assets, not duplicated per ship. A ship that reuses a hull (for example, a variant) reuses the shared file and overrides only its colour/material assignment, not the geometry.
- **Browser-build check:** After export, load the hull in the browser build and check that it loads, that its materials appear, and that its scale is correct. The pack states the browser build is "frozen to break fixes" (see Part 7), that does not mean it cannot be used to check; it means the pipeline must not require a browser-build change to make a hull work.

**Recommendation, an export checklist per hull:** Before a hull is called "game-ready," it must pass:

- loads in the browser build without errors;
- materials and colours match the colour sheet from Step 5;
- scale matches the reference (for example, the fighter's 2.5 m figure, or the station's stated size);
- UVs and textures appear correctly (no stretched, missing, or mirrored textures on visible faces);
- the file is named and stored following the shared-file rule, not as a one-off in a personal folder.

### Step 7, Per-hull review and sign-off

**Rule from the pack:** The pack does not state a formal sign-off step, but the board decision requires one. The recommendation is:

- **Per-hull review:** After Steps 1-6, the hull is reviewed against its locked reference (Step 1), its colour sheet (Step 5), and its export checklist (Step 6). The review is recorded as pass, pass-with-notes, or fail-with-rework-list. A hull with a fail is not "in progress", it is blocked until the rework list is cleared.
- **Stage sign-off:** Stage 1 is signed off only when at least one hull of each core class (fighter, destroyer, and the other core hulls in Part 4) has passed per-hull review. Stage 2 is not authorised on the basis of a single successful fighter.

This step is where the board's staging decision is enforced. Without it, "the pipeline works" will be claimed on the basis of the easiest hull.

## 3. Evidence summary, what the pack actually proves, and what it does not

### What the pack proves

1. **A TRELLIS.2 base can be cleaned and detailed in Blender to a recognisable ship.** The fighter (S1_51) is the proof. The pack's fighter folder contains a Blender file, a cleaned base mesh, and a description of the sculpting that was needed. The fighter is recognisably a Sword of Light fighter, with a distinct cockpit and panel details that TRELLIS.2 alone did not provide. This proves the *route*, TRELLIS.2 to Blender cleanup/sculpting to game-ready model, for a small, simple hull.
2. **A shared UV/material/colour system is already defined, at least in outline.** The pack names the Shared UV and Material System, names FAC3D as the colour source, and names the game formats (`.vs`, `.vsm`). This proves the *intent* and the *vocabulary* for a common system, even if the pack does not give the numbers (texel density, map resolutions) that would make it fully reproducible.
3. **The destroyer (S2_23) is in progress through the same route.** The pack lists the destroyer as a core hull and places it in the same pipeline. This proves the pipeline is not fighter-only in intent, but the pack does not contain a finished destroyer to prove it in fact.
4. **The project's constraints are understood.** Free tools only, one-person project, agent help, these are stated in the pack and are consistent with the tools named (TRELLIS.2 via ComfyUI, Blender, FAC3D, and the game's own formats). No paid tool is required by the pipeline as described.

### What the pack does NOT prove

1. **That TRELLIS.2 works for large or complex hulls.** The pack contains no finished capital ship, no finished station, and no finished organic variant. The largest hulls (capital ships, stations) have more surface area, more hard-surface detail, and more internal structure than a fighter. TRELLIS.2's "blobby" tendency, already visible on the fighter, is likely to be worse, not better, on a large hull where the reference image cannot show all faces at once. The pack gives no evidence that the fallback (AI-assisted sculpting) scales to a capital ship within a one-person project.
2. **That the shared UV/material system works at fleet scale.** The pack names the system but does not show it applied to more than one hull, nor does it give the texel-density, seam, or resolution numbers. A system that works for a 2.5 m fighter may not work for a station without either very large textures or multiple UV tiles, and the pack does not say which approach is taken.
3. **That FAC3D covers all factions and variants.** The pack names FAC3D as the colour source and names the factions, but it does not list the FAC3D entries for each faction, and it does not confirm that FAC3D contains organic tones for the Chorus spore variant. This is a gap, not a proof of failure, but it means the colour step cannot be called "proven" until the entries are checked.
4. **That the browser build will load the shared hull files without change.** The pack states the browser build is frozen to break fixes but shares the hull files. It does not show a browser-build load test for a newly exported hull, and it does not state whether the new UVs, new material maps, or the `.vsm` format affect that build's ability to load the files. This is assumed, not proven.
5. **That the per-hull time and rework cost is acceptable.** The pack gives no time estimates, no rework counts, and no cost per hull. The board cannot judge whether "one pipeline for all ships" is affordable in a one-person project without Stage 1 measurements. The fighter's history (TRELLIS.2, sculpting, cleanup) suggests significant rework per hull, but the pack does not quantify it.

**Bottom line on evidence:** The pack proves a *route* for a small ship and defines a *system* for the fleet. It does not prove the route or the system at fleet scale. That is why the decision in Part 1 is staged.

## 4. Fleet coverage, which ships the pipeline must handle, and where it is weakest

The pack's fleet, as far as it can be reconstructed from the hull lists and faction notes, is:

| Hull ID | Name / Class | Faction / Type | Pipeline status in pack |
|---------|--------------|----------------|-------------------------|
| S1_51 | Fighter | Sword of Light | In progress / template, TRELLIS.2 + Blender cleanup, reference locked (Sword of Light screenshot) |
| S2_23 | Destroyer | (Core hull, faction not separately stated in the pack extract) | In progress, same pipeline, no finished model in pack |
| B23_51 | Spore | Chorus (organic variant) | Priced / listed, not analysed individually, needs organic variant handling (see below) |
| (Other core hulls) | (Core fleet, the pack refers to "four core hulls" but does not name all four in the extract provided) | (none stated) | Not individually evidenced, treat as Stage 1 scope to be confirmed |
| Capital ships | Larger hulls | (Multiple factions) | Not evidenced as finished, Stage 2, highest risk |
| Stations | Detailed stations | (Multiple factions) | Not evidenced as finished, Stage 2, highest risk for detail and scale |

**Notes on the table:**

- Hull IDs S1_51, S2_23, and B23_51 are taken directly from the pack. Where the pack does not give a name or faction for a hull, the table says so rather than inventing one.
- "Priced but not analysed individually" for the spore means: the pack lists the spore as a fleet item with a cost/price note, but it does not contain a per-hull analysis of its geometry, reference, or colour. Do not treat a price note as a pipeline proof.
- The "four core hulls" phrase is in the pack, but the pack extract provided for this report does not name all four. Stage 1 scope must be confirmed by listing the four by ID before Stage 1 starts; otherwise the board will be signing off Stage 1 without knowing what it contains.

### Weakest points by hull type

1. **Capital ships, scale and detail.** A capital ship is not a larger fighter. It has more decks, more weapon mounts, more engine blocks, and a silhouette that cannot be captured in a single reference image. TRELLIS.2 is most likely to fail the essential-features check here, and the fallback (sculpting) is most expensive here. This is the highest-risk category for time, not just for quality.
2. **Stations, detail density and UV scale.** A station is a detailed, multi-part structure. Its UV/texture problem is different from a ship's: either the textures become very large, or the station is split into multiple UV tiles/materials, which the shared system must support. The pack does not say it does. Stations are also the most likely to expose the browser-build question (Part 7): a station with many parts and materials is the hardest test of "shares the hull files without a browser change."
3. **Chorus spore (B23_51), organic form and colour.** The spore is a Chorus craft and may need an organic variant. Organic form is the opposite of the hard-surface workflow that works for the fighter and destroyer: it needs smooth, curved, non-panelled surfaces, and it needs a colour palette that may not be in FAC3D. The pipeline as described (TRELLIS.2, hard-surface detailing) may be the wrong emphasis for this hull. The organic variant should be treated as a separate per-hull pass within the same pipeline (same UV/material system, same export, different sculpting emphasis), not as a failure of the pipeline, but it must be planned as a variant, not assumed to fall out of the standard pass.
4. **Small, simple ships (fighter, bomber), lowest risk.** The fighter proves the route; the bomber (S2_23 is the destroyer, the pack also mentions a bomber in the per-hull notes, but does not give it a separate ID in the extract) is small and simple and should follow the fighter's template with the least rework. These are the right Stage 1 candidates to lock the shared-system numbers.

## 5. Risks, and how to mitigate them

| Risk | Likelihood / Impact | Mitigation (owner: the single artist/agent team, unless stated) |
|------|---------------------|----------------------------------------------------------------|
| TRELLIS.2 fails on large/complex hulls (capital ships, stations), wrong silhouette, missing volumes, blobby surface that cannot be cleaned economically | High likelihood for capital/stations; High impact (rework or fallback cost) | Use the two-attempt rule (Part 2, Step 2A) and do not keep re-running TRELLIS.2. Move to AI-assisted sculpting early for large hulls, and measure the sculpting time in Stage 1 on the destroyer as a proxy for capital-ship effort. If the destroyer's sculpting time is already high, do not authorise capital ships until a cheaper blockout method is found. |
| Shared UV/material system does not scale, texel density, map resolution, or tile count breaks on large hulls/stations | Medium likelihood; High impact (rework of all hulls if numbers change mid-fleet) | Lock texel density, seam strategy, and map resolutions on the fighter in Stage 1 and do not change them mid-fleet. For large hulls, use more UV tiles at the same density, not lower density. Record the numbers in the shared-system document before Stage 2. |
| FAC3D does not cover a faction or the Chorus organic palette | Medium likelihood; Medium impact (colour cannot be assigned from FAC3D, pipeline stalls at Step 5) | Check FAC3D entries for every faction and for Chorus organic tones before Stage 1 texturing starts. If entries are missing, add them to FAC3D as a prerequisite task, do not invent colours per ship. This check is cheap and should be done first. |
| Browser build cannot load new shared hull files without change, despite being "frozen to break fixes" | Low to Medium likelihood; High impact (hulls cannot be tested in-game, or require a browser change the pack says is frozen) | Test browser loading on the first Stage 1 hull (fighter) before proceeding to other hulls. If it fails, escalate to the board: the pipeline approval assumes the browser can load the files, and a failure here is a board-level decision, not an artist-level workaround. |
| Per-hull rework cost is higher than a one-person project can sustain | Medium to High likelihood; High impact (fleet slips, quality drops, or hulls are cut) | Measure per-hull time and rework in Stage 1 (TRELLIS.2 attempts, sculpting hours, cleanup hours, UV/texture hours). Use those measurements to set a per-hull budget for Stage 2. If Stage 1 already exceeds the budget, cut scope (fewer hulls, simpler variants) rather than lowering quality across the fleet. |
| Reference images are not locked, so "looks like the ship" is subjective | Medium likelihood; Medium impact (rework loops, disagreements on sign-off) | Require a locked reference and essential-features list (Part 2, Step 1) for every hull before generation. No reference, no generation. |
| File/version chaos, unversioned Blender files, duplicated textures, per-ship material inventions | Medium likelihood; Medium impact (fleet becomes unmaintainable) | Enforce the clean-checkpoint and naming rules (Part 2, Steps 3 and 6) and the shared-material-slot rule (Step 4). No new material slot without updating the shared-system document. |
| AI-generated detail is "decal-like" or floating, not real geometry | Medium likelihood (already seen on fighter); Low to Medium impact (looks wrong up close, breaks normal maps) | In the Blender hard-surface pass, either model the detail as geometry or bake it correctly as a normal-map decal following the Step 4 map rules. Do not leave floating geometry in the game-ready export. |

## 6. Recommendation and staging

**Approve Option 3, one pipeline, with per-hull passes, a shared UV/material/colour system, and a fallback to AI-assisted sculpting where the mesh generator fails, in stages:**

**Stage 1, Prove the pipeline on the core fleet (authorise now)**

- Scope: The four core hulls (to be listed by ID before work starts, S1_51 fighter and S2_23 destroyer are two of them; the other two must be confirmed from the pack's full hull list).
- Deliverables per hull: locked reference, TRELLIS.2 or fallback record, clean Blender file, UV/material/colour sheet, exported `.vs`/`.vsm` + textures, browser-load check, and per-hull review (pass/pass-with-notes/fail).
- Exit criteria: At least one hull of each core class has passed per-hull review; the shared-system numbers (texel density, map resolutions, material slots) are locked and documented; per-hull time and rework are measured; FAC3D coverage is confirmed for the core factions; the browser-load check has passed for at least one hull.
- Board action at exit: Review the Stage 1 measurements and decide whether to authorise Stage 2, cut scope, or change the pipeline.

**Stage 2, Extend to the remaining fleet (authorise only after Stage 1 exit criteria are met)**

- Scope: Remaining hulls, capital ships, and stations, plus the Chorus spore organic variant as a separate per-hull pass.
- Deliverables: Same per-hull deliverables as Stage 1, plus a fleet-level check that the shared UV/material system still holds at capital/station scale.
- Exit criteria: All Stage 2 hulls pass per-hull review, or the board explicitly accepts a reduced fleet (fewer hulls, simpler variants) on the basis of Stage 1 measurements.

**What not to approve:**

- Do not approve an open-ended "one pipeline for all ships, no staging" commitment. The pack does not prove the pipeline at capital/station scale, and an open-ended approval would hide that gap.
- Do not approve a split pipeline (different tools/systems per faction or per hull size) without a separate board decision. Splitting would break the shared UV/material/colour work that is the main benefit of a single pipeline, and the pack gives no evidence that a split is needed.
- Do not approve adding a paid tool to fix a pipeline gap without a separate cost decision. The pack's constraint is free tools only; if a gap can only be fixed with a paid tool, that is a board cost decision, not an artist workaround.

## 7. What the board should ask for next

1. **The four core hulls, by ID.** Confirm the Stage 1 scope in writing before work starts. The pack extract for this report does not name all four.
2. **The shared-system numbers.** Texel density, UV seam strategy, map resolutions, and material-slot list, locked on the fighter and documented before other hulls proceed.
3. **The FAC3D check.** A one-page confirmation that FAC3D contains entries for every core faction and for Chorus organic tones, or a list of missing entries to be added.
4. **The browser-load test.** Evidence that the first Stage 1 hull loads in the browser build with correct materials, scale, and textures.
5. **Stage 1 measurements.** Per-hull time (TRELLIS.2 attempts, sculpting, cleanup, UV/texture) and rework counts, reported at Stage 1 exit, to set the Stage 2 budget.

## 8. Gaps and unknowns, what this report does NOT claim

This report is limited to the pack provided. The following are **not** claimed, and should not be treated as proven by this report:

1. **The full hull list.** The pack extract provided does not name all four core hulls, all capital ships, or all stations by ID. Any fleet total derived from this report alone would be incomplete.
2. **The shared UV/material system numbers.** Texel density, map resolutions, and the full material-slot list are not in the pack extract. This report recommends locking them in Stage 1; it does not state them as pack facts.
3. **The engine's map list.** The minimum map set in Part 2, Step 4 (albedo, normal, roughness, metallic, emissive where needed) is a recommendation based on common game practice, not a pack-stated engine requirement. Confirm it in Stage 1.
4. **The `.vs` / `.vsm` relationship.** The pack names both formats but does not state which is primary or how they relate. This report treats `.vs` as the ship definition and `.vsm` as the material/UV companion as a working assumption, to be confirmed in Stage 1.
5. **The per-hull time, cost, or quality for capital ships and stations.** No finished capital ship or station is in the pack, so no time, cost, or quality claim is made for them. Stage 1 measurements on the destroyer are a proxy, not a proof.
6. **The squadron craft in detail.** The fighter (S1_51), bomber (S2_23), and spore (B23_51) are priced but not analysed individually. The spore is a Chorus craft and may need the organic variant. The fighter and bomber are small and simple. Detailed treatment is deferred to the per-hull pass.
7. **The browser build.** The pack states the browser build is frozen to break fixes but shares the hull files. This report does not evaluate whether the proposed changes (new UVs, new material maps, .vsm format) affect the browser build's ability to load the shared files. The pack says the browser build is frozen, so this is assumed to be handled by the existing file format, but it is not verified here.
8. **The specific TRELLIS.2 / Pixal3D settings that might reduce waviness and bumps at the generation step.** This report treats the AI mesh as a given input and focuses on cleanup. Whether different generation settings, prompts, or conditioning could reduce the defects at the source is not investigated. The pipeline README step 3 (ComfyUI, TRELLIS.2 cascade) may have tunable parameters, but that is outside the scope of this research.
9. **A cost comparison with outsourcing or buying stock 3D ship kits.** The pack's constraints (free tools only, one-person project, agent help) make this unlikely, but the option of purchasing or downloading existing 3D ship asset packs and adapting them is not evaluated.
10. **The exact FAC3D entries for the Chorus organic palette.** This report states that Chorus colour must come from FAC3D but does not inspect the current FAC3D entries to confirm they include suitable organic tones. If the Chorus palette in FAC3D is incomplete, adding entries is a prerequisite for the organic variant.
