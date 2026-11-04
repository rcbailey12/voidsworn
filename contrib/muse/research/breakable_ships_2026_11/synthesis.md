# Breakable ships by design: the Blender build method (issue 171, R98)

Chair synthesis of four legs: a blind Rey leg (written first, before any other leg), DeepSeek (writer), Qwen (writer), and an Argon review of the three. Screening notes for every leg, including the Argon review itself, are in section 9. Anything not tied to a named source or a repository file is labelled INFERRED.

## 1. Verdict

GO WITH CONDITIONS. The method below is settled and scriptable today with Blender 4.5 built-ins: Solidify in Complex mode for thickness, Boolean Exact with closed jagged cutters (or bmesh bisect_plane) for break lines, caps backed by a bulkhead at each break plane, damage painted inside the existing R96 baked-mask system, and one .glb per hull carrying the intact ship plus named break pieces for the Godot death swap. The one condition is owner question 1: the intact ship's thickness reading. R98 says every new or rebuilt hull ships with real hull thickness, and the intact Pyre-Barge already sits at the R96 ceiling (305,857 tris for the stage 5 hull; 307,477 tris with markings; 3.887 ms at 20 ships in the isolated test scene). A full Solidify of the intact hull roughly doubles its triangles and breaks the ceiling outright, so all three writer legs and the chair converge on the same reading: the intact ship carries thickness where it can be seen (rim bands at the authored break lines and around openings, plus a decimated dark inner liner), and the full interior lives in the broken-piece variants, which are only on screen as wrecks. That reading is an interpretation of R98's wording, so it goes to the owner rather than being assumed.

Five headline decisions:

1. Thickness comes from Solidify Complex mode, inward only, applied per break piece and as local bands on the intact ship. Full-hull Solidify on the intact ship is rejected (breaks R96).
2. Interiors are sparse by design: decks clipped to the hull cross-section, one bulkhead at each break plane doubling as the cap's backing plate, ribs as texture plus a few large boxes near openings. No room layouts, no interior lights. Qwen's bounding-box planes (about 30 triangles) are rejected: they are not clipped to the hull and would poke through curved plating.
3. Break lines: two transverse lines standard, plus one longitudinal line on capital hulls (owner question 2). Cutters are closed, jagged volumes in the EVE pattern, not flat planes; the scripted alternative is bmesh.ops.bisect_plane with its geom_cut edges fed to holes_fill for deterministic caps.
4. Damage texture work extends the R96 baked-mask paint system with a damage mask set (soot, scorch, torn edge bands). No new texture pipeline. Qwen's shared 512x512 trim strip is rejected as a replacement system; its one useful idea, cap bands painted as zones, survives inside the R96 graph.
5. Export is one .glb per hull: the intact ship at the ship origin, each break piece as a named object with its origin at the piece centre of mass, break line ids in the node names, and Godot import suffixes (-colonly / -convcolonly children) for collision, per the Godot manual.

## 2. The method, stage by stage

Stage 0, clean the input mesh. Apply scale first (Solidify thickness is computed in local coordinates; the Blender manual flags this as a limitation across the whole modifier). Then Merge by Distance, recalculate normals, fill stray holes, separate loose shells. This matters because Complex mode's manifold promise is conditional: per the Blender 4.5 manual, the output is always manifold if the input is manifold. It is not a repair guarantee for non-manifold input, and the manual warns that start and end cap faces are not always generated for open meshes. All three writer legs overstated this as a guarantee; the Argon review's correction is adopted.

Stage 1, branch before cutting. Duplicate the cleaned hull twice: one copy becomes the intact ship, one becomes the break-variant master. (Argon caught both writer step lists modifying the hull in place and then expecting an intact copy to still exist; the branch must come first.)

Stage 2, thickness on the intact ship. On the intact copy, Solidify runs only where thickness can be seen: bands 1 to 2 m wide on each side of every authored break line, and rims around openings, using rim-only generation (in Complex mode, keep the rim vertex group and delete the shell group; in Simple mode, use_rim with use_rim_only). Behind those bands, add a decimated dark inner liner so a near-miss view into a breach (#167's game-side cuts) still reads as depth, not a hollow shell. Net intact cost target: +3,000 to +6,000 triangles before trimming, offset to roughly +0 to +2,000 by decimating hidden exterior greeble detail during the same repair pass. The intact ship must stay inside the R96 ceiling; that is a hard gate in the step list for #169, not a hope.

Stage 3, thickness on the break pieces. On the variant master, Solidify runs in Complex mode with the correct API: mod.solidify_mode = 'NON_MANIFOLD' (there is no use_complex attribute; Qwen's snippet would throw), mod.nonmanifold_thickness_mode = 'CONSTRAINTS', offset -1 so all thickness grows inward, material_offset for the inner shell slot and material_offset_rim for the rim strip. Starting thickness band: 0.4 to 0.8 in the project's unit scale, tuned at close zoom in the #169 recordings (owner plays at 4K, about 15.4 px per unit at the battle camera of about 170 units; those figures are chair grounding carried from the #51 and #135 research, not from this pack). Qwen's 0.03 to 0.06 m band is screened as paper-thin at that scale.

Stage 4, interiors. Build the interior set once per hull, before cutting, so the cutter splits it with the hull: one spine deck plus one cross deck (2 to 3 decks total), each clipped to the inner cross-section of the hull at its position, 0.2 to 0.3 thick; one bulkhead plate at each authored break plane, displaced slightly inward from the cut face, which becomes the visible cap backing; a handful of large rib boxes near openings; the rest of the rib and pipe read is texture. Interior material is near-black by rule: albedo 0.01 to 0.03, roughness 0.8 to 1.0, no lights. This is the Nov 1 destruction synthesis rule (dark interiors, single-sided hull skin answered by real thickness) carried into the build.

Stage 5, cut at the authored break lines. Primary: Boolean Exact solver (Self Intersection and Hole Tolerant on) with closed, beveled, jagged cutter volumes, the EVE Rubicon pattern. Planar alternative for the scripted path: bmesh.ops.bisect_plane returns geom_cut, the exact cut edges; feeding those edges to bmesh.ops.holes_fill caps the opening deterministically and returns the cap faces for material assignment (Argon, from the Blender BMesh API docs). Cell Fracture is rejected for authored lines: it is a Voronoi shard generator driven by point sources, random by design, and the pack's question was authored lines. After cutting, add edge debris: short extrusions along the cut rim with a vertex-colour fade to black (EVE pattern, confirmed against the CCP dev blog), and displace the cap/bulkhead faces slightly so no two mating faces are coplanar.

Stage 6, caps and damage paint. Each open face is closed by its bulkhead plate wearing damage materials in bands, extending the R96 baked-mask paint graph (curvature, AO, noise masks) with a damage variant: armour band, structural band, scorched interior, and a hot torn edge band 0.05 to 0.1 wide that hands off to the #167 hot-edge shader in game. Soot, scorch and torn variants of the mask set are the whole texture cost; there is no per-hull hand painting in the base method.

Stage 7, export. One .glb per hull variant set. Node names carry the break line ids (for example hull_intact, hull_break_a_bow, hull_break_a_mid). The intact object keeps the ship origin; each piece's origin sits at its centre of mass so Godot's death swap can spin and drift pieces believably (Qwen's cap-face centroid is rejected: it puts the pivot on the cut face, so pieces would swing around their wound). Collision children use Godot's documented import suffixes (-colonly, -convcolonly) so no custom import script is needed. Two export traps are called out in the step list: keep pieces as separate objects or the exporter/static merge collapses them into one mesh, and assert the reimported triangle count as a hard fail so a silent doubling is caught in the build, not in a frame-time graph.

## 3. The Chorus organic variant

Same stages, different vocabulary. Decks become transverse bone ribs (6 to 10, spaced along the hull); bulkheads become low-poly flesh masses; the inner liner becomes membrane sheets 0.1 to 0.3 thick, with membrane thickness varied by vertex groups so it reads grown, not extruded (that vertex-group idea is Qwen's one adopted Chorus point). Cutters follow chitin and bone seams and stay jagged. Cap bands become membrane, raw flesh, charred bone, and hot ichor at the torn edge. Cost runs lower than metal: roughly 6,000 to 12,000 triangles of interior per break piece against 8,000 to 15,000 for metal (INFERRED, from the DeepSeek leg's table). Density for the first Chorus hull is owner question 4.

## 4. Cost against the R96 ceiling

All figures INFERRED from the legs' tables; nothing here was measured on the real mesh (see Not checked).

- Intact ship: bands plus liner add about +3,000 to +6,000 triangles gross, about +0 to +2,000 net after trimming hidden exterior detail in the same pass. The ceiling holds only if the trim happens; that is why it is a gate in the #169 steps.
- One wreck (all break pieces with interiors): about 24,000 to 45,000 triangles of interior and cap geometry across the pieces, on top of the hull's own triangles split among them. Wrecks are transient and few; the 20-ship intact measurement is not the binding budget for them.
- Draw calls: at most about 9 per wreck (3 pieces times up to 3 materials). Twenty simultaneous wrecks would be about 140 draw calls, which no battle produces; the binding case is a handful of wrecks plus the live fleet.
- Rejected accounting: Qwen's variant set applies un-decimated full-mesh Solidify per piece and totals about 614,000 triangles for one ship's variants. That is the V3 mistake (622,570 tris, parked by R97) repeated, and it also leans on a death flash to hide the swap, which spends against the R80 flash budget that belongs to #167. Not adopted.

## 5. How shipped games author breakable ships

- EVE Online (CCP dev blog, "The Art of Rubicon 1.1", 2014-01-29): the strongest sourced precedent. A small team (one senior technical artist, one shader programmer, one 3D artist) built a cutter tool: reusable cutter volumes plus advanced Booleans, all holes capped with damaged-interior materials and correct UVs, edge debris extruded with a vertex-colour fade to black, tiny fragments auto-deleted, and the fragments reassembled around depth-buffered dust-cloud emitters as a single static wreck mesh. Animated breakup was rejected for capitals. After the tooling existed, the team produced 27 capital wrecks for Rubicon 1.1. Two chair corrections: the deliverable is one reassembled static wreck, not three swappable meshes (our Godot swap differs, and that is fine, but the precedent should not be misquoted), and the blog gives no per-wreck hour figures.
- Homeworld 3 (Blackbird; Tim O'Connell dev blog, via GamingTrend): ship breaking is done offline in Houdini; interiors are modelled and warped to bulge at the break; damage sockets spawn staged damage FX at fixed points and trigger catastrophic effects at death. Sockets are not break lines or attachment points (Qwen's reading is cut; the Argon correction is adopted). The Nov 1 project synthesis remains the base account.
- Battlefleet Gothic: Armada: hulks and pre-authored break states, community-level evidence only (Nov 1 synthesis). No primary source was found in this pass.
- Sins of a Solar Empire II: the cautionary case, now with a postscript. It launched with ships popping at death; the Nov 21, 2024 update added custom debris for capital ships, starbases and titans (Ironclad/Stardock Season 1 roadmap, via the Argon review). Even Sins 2 had to retrofit authored debris, which is the R98 argument made by someone else's patch notes.
- FreeSpace 2 / FreeSpace Open and Star Wars: Empire at War (Argon-sourced, not independently re-fetched by the chair): FreeSpace packs pre-authored debris subobjects in the same container as the intact hull and swaps them in at death with physics impulses; Empire at War capital ships define a pre-authored Death_Clone asset of pre-split, sealed sections. Both match the R98 pattern exactly if Argon's account holds.

## 6. Hours per hull

Two leg estimates disagree by a lot, and the synthesis does not average them.

- DeepSeek (INFERRED): first hull 70 to 101 hours total, including 30 to 40 hours of script and pipeline setup; repeat hulls 12 to 20 hours.
- Qwen (INFERRED): first hull about 20 hours, repeats about 3 hours, Chorus +2. Its own script snippets contain non-running code, which undercuts its setup-cost confidence.
- Chair position (owner question 5): plan against the DeepSeek range. The shipped-game evidence points the same way: EVE and Homeworld both front-loaded serious tooling before per-ship costs fell. Qwen's numbers read as the cost once the script exists and works first try.

## 7. Proposed step list for issue 169 (Pyre-Barge, build side)

1. Take the hull round 5 (#163) keeps, on the R96 paint stack. Branch the cleaned mesh into intact and variant-master copies before any cutting.
2. Author the break lines on the master: two transverse, plus longitudinal if owner question 2 adopts it. Record line ids.
3. Build the interior set on the master (decks clipped to cross-section, bulkhead at each break plane, rib boxes near openings, near-black interior material).
4. Solidify: Complex mode, inward, CONSTRAINTS thickness mode, per the API in section 2 stage 3. Bands and liner on the intact copy; full treatment on the variant master.
5. Cut with jagged closed cutters (Boolean Exact) or the bisect_plane path; add edge debris with vertex-colour fade; displace caps off coplanar.
6. Paint: run the R96 baked-mask graph plus the damage mask variant; assign cap bands.
7. Trim the intact copy's hidden exterior detail until the intact triangle count is back inside the R96 ceiling. Gate: if it cannot get inside, stop and report rather than shipping over ceiling.
8. Export one .glb with named pieces, centre-of-mass piece origins, break ids in names, -colonly collision children. Assert reimport triangle counts.
9. Record at battle distance and close zoom in Godot; check the grazing-angle crop and the head-on material crop, same acceptance set as round 4.
10. Deliver screenshots and recordings to docs/shots/ship_pipeline/pyre_breakable/. No shipping asset is replaced until Ryan approves (gate restored from issue #169's own text; the blind leg's step list omitted it).
11. Write the method deltas back into tools/blender/hull_repair/ notes so hull two starts from the script, not from memory.

## 8. Owner questions (chair picks first)

Q1. Intact-ship thickness reading. A: bands at break lines plus a decimated dark liner on the intact ship, full interiors only in break variants (chair pick; keeps R96, honours R98 where thickness can be seen). B: full Solidify on the intact ship and waive the ceiling for rebuilt hulls (roughly doubles intact triangles; the 20-ship frame cost follows). C: full Solidify on the intact ship, then decimate the exterior to fit the ceiling (pays for thickness with exterior detail, the thing rounds 1 to 3 kept losing).

Q2. Break lines on capital hulls. A: two transverse plus one longitudinal (chair pick; the longitudinal split reads from the top-down battle camera and breaks up the sliced-loaf look). B: two transverse only (cheaper, simpler caps; every capital dies the same way).

Q3. Damage textures. A: extend the R96 baked-mask paint graph with a damage mask set, cap bands painted inside that graph (chair pick; one paint system for the whole fleet). B: a separate shared trim-strip texture just for caps (Qwen; a second texture system to maintain, and its UV scheme for boolean cap ngons is unproven).

Q4. First Chorus hull interior density. A: bone ribs and membranes everywhere, plus one flesh mass per break piece, then measure and decide whether more flesh is worth it (chair pick). B: ribs and membranes only (cheapest; risks reading as a cage, not a creature). C: full flesh masses at every bulkhead position from the start (richest; most hours and triangles before the method is proven).

Q5. Planning basis for hours. A: budget on the DeepSeek range, 30 to 40 hours of scripting inside a 70 to 101 hour first hull, 12 to 20 hours per repeat (chair pick). B: budget on Qwen's range, about 20 hours first hull and 3 per repeat, and treat overruns as they come.

## 9. Screening notes

- Blind Rey leg: adopted as the architecture base (cut first, rim plus liner on the intact ship, interiors only in variants, one .glb, centre-of-mass origins). Its R98 quotation is exact (FINDINGS line 126, chair-verified). Its camera figures are chair grounding from #51/#135, labelled as such in section 2. Its step list omitted the #169 deliverable path and approval gate; restored in section 7.
- DeepSeek leg: the method core is adopted (Solidify settings, jagged cutters, EVE pipeline, interior counts, hours). It filed no URLs; the CCP blog and Blender manual links in this synthesis were supplied by the Argon review and checked for consistency against the leg's account. Its "Cutter" naming is corrected to Cutter Preview, and its wreck wording is corrected to EVE's single reassembled static wreck.
- Qwen leg: largely screened. Its code snippets do not run (a nonexistent Solidify attribute, a placeholder line, a zero-thickness plane Boolean that cannot produce a capped 3D section, a nonexistent convex hull operator), its EVE account contradicts the CCP blog, its Homeworld socket reading is wrong, its shipped-game section is unsourced and labelled INFERRED by the leg itself, its intact ship violates the thickness rule it was briefed on, and its variant triangle total repeats the parked V3 error. Adopted from it: membrane thickness variation via vertex groups for the Chorus, and the questions it surfaced on export naming, which the synthesis answers from the Godot manual instead.
- Argon review: used in part. Its API corrections, manual nuances, EVE confirmation, Sins 2 update and step-list catches are adopted and credited. Its quotation-based cut lists do not survive checking: the DeepSeek numbers it quotes are not in the filed leg (chair grep, zero matches), the Qwen "Precedents" quotations are not in the filed Qwen leg, and the R98 text it quotes against Qwen is not the rule text in the pack. Those items are screened in the header of the filed Argon leg so the record shows both the review and its limits.

## Not checked

- No Blender run on the real Pyre-Barge mesh: Solidify Complex behaviour, cutter results and every triangle figure in section 4 are unmeasured until #169 builds it.
- Argon's FreeSpace 2 and Empire at War accounts were not independently re-fetched.
- The English Blender manual and Godot suffix pages Argon cites were not re-opened by the chair; the pack's Spanish-mirror manual excerpt was the seed, and Argon's API points are consistent with it and with the legs' failures.
- Whether #167's game-side caps and this build-side method agree on hot-edge band widths is a #167/#169 coordination point, not settled here.

## 10. Owner rulings (Ryan, Nov 4, 2026)

Ryan agreed with all five chair picks. Recorded here; section 8 holds the full question text.

1. Q1 ADOPTED: option A. The intact ship carries thickness bands at the break lines plus a decimated dark liner; full interiors live only in the break variants. The R96 ceiling stands.
2. Q2 ADOPTED: two transverse break lines plus one longitudinal line on capital hulls.
3. Q3 ADOPTED: damage textures extend the R96 baked-mask paint graph with a damage mask set. No second texture system.
4. Q4 ADOPTED: first Chorus hull gets bone ribs and membranes everywhere plus one flesh mass per break piece, then a measurement before any denser flesh work.
5. Q5 ADOPTED WITH THE OWNER'S CAVEAT: the DeepSeek range is the planning basis for issue #169's scope, but Ryan's objection is recorded with it: hour estimates in this research line keep missing because they are anchored on human studio production (the EVE and Homeworld teams were people), not on the agent pipeline that actually does this work (one scripted pass, run by agents, per hull mostly unattended compute plus owner review minutes). Future muse research should state effort in those agent terms, sourced from this board's own completed jobs where possible, and should not present human-team timelines as corroboration for an agent estimate. The chair accepts the correction; the EVE/Homeworld hours framing in section 6 is superseded by this note as a planning basis, though the method evidence from those sources stands.
