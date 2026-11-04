Qwen leg: ship look round 3 research
Model gates: Gate 1 passed (selector showed Qwen3.8-Max before sending). Gate 2 passed (chat header still showed Qwen3.8-Max after generation started). Note: the first Qwen run in this job returned a completely unrelated report (institutional trust) despite both gates passing; it was discarded and this leg is the retry in a fresh chat.

# Voidsworn - Ship Look Round 3 - Writer Leg Report

**Leg:** Qwen writer leg (independent of the DeepSeek leg)
**Date:** 2026-11-04
**Deliverable:** One report answering the four issue #147 questions, with a ranked Round 4 proposal and owner questions.
**Branch:** Ship look round 3 (post-round-3 evidence; R92 = round 2 report, R102 = round 3 report, R82 = round 2 owner questions)
**Independent note:** This report is based only on the evidence pack provided. I did not see the DeepSeek leg's draft. Where the pack conflicts with the Qwen leg's earlier draft, the pack's FINDINGS rulings win.

## Question 1 - Painting and Materials

### 1a. Verdict

The grid and double-lighting failures are not a painting-skill problem. They are a mapping problem. A 2D painting, however good, is projected onto a 3D hull through UVs. Where UVs stretch, the grid shows. Where a painted highlight is baked into albedo, it double-lights in-game. The fix is to stop painting the hull and start building the hull's look from geometry and materials.

**Winner: a procedural material graph, baked once per faction, applied to all 36 hulls.**

| Rank | Route | Cost (human / machine) | What it fixes | Why it wins / fails |
|---|---|---|---|---|
| 1 | Procedural material graph, baked once per faction | ~1-2 h human for initial faction material graph; ~15-30 min human per hull to apply and tweak; bake is ~10-20 min machine time per hull at 2048x2048. | Eliminates the grid (no 2D painting is mapped). Eliminates double lighting (albedo is flat; wear, edge-highlight, AO are computed from geometry). Gives per-panel variation from curvature and AO without painting. Directly produces the "matte soot black and rust plate" read from the Hullbreaker spec. | Directly addresses the three failure modes. Baking once per material graph amortises across all 36 hulls, rather than paying per hull. |
| 2 | Trim sheet (single 2048x2048 sheet, reused) | Trim sheet: ~6-10 h human one-time per faction. Per hull: ~1-3 h human to lay UVs onto the trim + place decals. | Provides consistent panel-line detail, bolted-plate texture, hazard stripes, and faction markings across all 36 hulls without per-hull painting. The "patched scrap plate, bolted on rough" Hullbreaker language is built once into the trim and reused. Decals earn their place per R82 Q2. | Keeps 2D painting but constrains it to a single, reusable sheet. Lower upfront cost than a full graph, but UV placement per hull keeps scaling cost and the grid cannot be fully removed without a second UV set. |
| 3 | Unique texture per hull (hand-painted 2048x2048 set) | Per hull: ~8-12 h human to paint a 2048x2048 set; bake ~10-20 min machine per hull. x36 hulls = ~288-432 h human. | If every map is painted by hand, the grid can be avoided by painting only where the mesh says so, but every hull restarts the work. | Rejected as fleet strategy. It is the approach that produced the current 36x bespoke cost. It may remain as a rescue for one hero hull only. |
| 4 | Concept-paint to mesh wrap (FLUX / ComfyUI painting wrapped onto a mesh) | Per hull: ~2-4 h human concept + cleanup; ~30-60 min machine inference. | Does not fix. A 2D painting wrapped onto a mesh inherits the grid whenever UVs are distorted, and double lighting is inherent to a painted map. | Rejected. It is the source of the grid and double-lighting failures, not a solution to them. |

### 1b. Why the rejected routes fail at fleet scale

- **Unique texture per hull:** At 36 hulls, the cost is 288-432 h human. It is not a pipeline; it is 36 one-off paintings. It also creates 36 unrelated looks, which is the opposite of a fleet identity.
- **Concept to mesh:** The round 3 evidence is unambiguous. The Pyre-Barge concept was wrapped onto a mesh and the grid reappeared on the curved hull sections. The painting was good; the mapping was not.
- **Trim sheet as sole solution:** A trim sheet is a good second layer, not a first layer. It gives panel lines and decals, but it does not give the hull its base material. Without a material graph underneath, the trim sits on a flat, unconvincing base.

**The cost curve is decisive.** The material graph costs ~1-2 h once, then ~15-30 min per hull. The unique-texture route costs ~8-12 h per hull, every time. At hull 1 the graph is already cheaper; at hull 36 it is cheaper by an order of magnitude.

### 1c. The recommended material stack

1. **Base material graph (faction):** One graph per faction. Soot black base, rust plate variation, wear from curvature and AO, edge highlight from geometry. Baked to 2048x2048.
2. **Trim sheet (faction):** Panel lines, bolts, hazard stripes, faction markings. One sheet per faction, reused.
3. **Decal atlas (fleet):** Trophy plates, kill marks, hull numbers, warning labels. Applied as decals, not painted into albedo.
4. **Wear pass (per hull):** Curvature and AO-driven wear, plus hand-placed damage on hero hulls only.
5. **Second UV set for trim (where needed):** If the grid reappears on a curved section, a second UV set for the trim alone removes it without repainting.

**What this does not do:** It does not paint the hull. It does not wrap a concept painting onto a mesh. It does not require a new texture per hull.

**How it maps to the round 3 evidence:** Round 3 proved the material graph works on the Pyre-Barge (no grid, no double lighting, fleet-consistent). It also proved the trim sheet works as a second layer. The combination is the recommendation.

## Question 2 - AI vs hand-built meshes

### 2a. Verdict

**AI meshes lose on all three tests: topology, silhouette, and fleet consistency.** Hand-built meshes win on all three. AI meshes are not a shortcut; they are a rework trap.

### 2b. Evidence from the rounds

- **Round 1 - AI mesh from a single concept image:** The mesh was blobby, with no hard-surface topology. Panel lines were painted, not modelled. The silhouette was soft and unreadable at distance.
- **Round 2 - AI mesh from multi-view images (ComfyUI):** Better silhouette, but topology was still unusable for animation and for the material graph. The mesh could not be UV'd cleanly, so the grid returned.
- **Round 3 - AI mesh with hand cleanup:** After 6-8 h of hand cleanup, the mesh was usable, but the cleanup cost exceeded the cost of building the mesh by hand from the start. The AI step added no value.

**The retired pipeline step was:** FLUX concept, ComfyUI multi-view images, mesh generation (Pixal3D / Meshy / TripoSG), hand cleanup. ComfyUI then synthesises a handful of views from one concept image; those views are then fed to an image-to-3D model. The step is retired because it produced meshes that needed more cleanup than a hand build, and it broke the material pipeline.

### 2c. The remaining honest AI role

AI is not banned. It has a narrow, honest role:

1. **Concept exploration:** FLUX / ComfyUI for silhouettes and mood, not for final meshes.
2. **Greeble library (deferred):** AI-generated greebles (pipes, conduits, vents) as a supplement, not as hulls. See owner question Q5.
3. **Reference, not production:** AI images as reference for hand builders, not as input to mesh generation.

**What to stop:** Stop feeding AI images into mesh generators for hulls. Stop budgeting hand-cleanup time for AI meshes. Build hulls by hand from the reference sheet.

## Question 3 - AI mesh models

### 3a. Verdict

No AI mesh model is ready to produce fleet hulls. The ranking below is for the narrow roles above (concept, greeble, reference), not for hull production.

### 3b. Ranking

| Rank | Model | Verdict | Use in Voidsworn | Source |
|---|---|---|---|---|
| 1 | Hunyuan3D-2.5 (Tencent) | Best open image-to-3D for hard-surface reference, but still needs cleanup for production. INFERRED - could not verify against a primary source in this session. | Reference silhouettes, greeble exploration. Not hulls. | INFERRED |
| 2 | TRELLIS successors (Microsoft / TRELLIS-2 / structured latents) | Strong on structured generation, but topology is still not game-ready. INFERRED. | Reference, greeble exploration. | INFERRED |
| 3 | Step1X-3D (StepFun) | Good single-image to 3D, but blobby on hard-surface detail. INFERRED. | Concept only. | INFERRED |
| 4 | Hi3DGen (HiDream?) | Best on detail preservation, worst on topology. INFERRED. | Concept only. | INFERRED |
| 5 | Meshy / TripoSG (closed, API) | Fast, but closed and inconsistent for fleet work. | Do not use for fleet hulls. | Pack / R102 |

**What this ranking means:** Even the best model (Hunyuan3D-2.5) is a reference tool, not a hull builder. The gap is topology, not appearance. Appearance can be faked in a render; topology cannot be faked in a game.

### 3c. What to build in Round 4

- **Hand-built Pyre-Barge hull** from the reference sheet, using the material graph + trim sheet stack.
- **No AI mesh** in the Round 4 comparison. The comparison is between hand-built routes, not between AI and hand.

### 3d. What to stop

Stop evaluating new AI mesh models for hulls until a model can demonstrate game-ready topology on a hard-surface test. The next evaluation should be a topology test, not a beauty test.

## Question 4 - Reference sheet

### 4a. Verdict

**The sheet is usable, with two fixes.** It is the best single reference the project has, but it is not yet a production sheet.

### 4b. What the sheet gets right

- **Silhouette:** The Hullbreaker silhouette is clear, readable, and distinct from other factions.
- **Material language:** "Matte soot black and rust plate, patched scrap plate, bolted on rough" is specific and buildable.
- **Panel logic:** Panel lines follow structure, not decoration. They are where plates meet, not where an artist felt like drawing a line.
- **Fleet consistency:** The sheet shows how the same language scales from a small hull to the Pyre-Barge flagship.

### 4c. What needs fixing

1. **Trophy plates:** The sheet shows trophy plates on the Pyre-Barge, but does not specify whether they are fleet-wide or flagship-only. R82 Q2 says flagship-only. The sheet should be annotated to say so.
2. **Colour callouts:** The sheet's rust and soot values are not specified as material values (roughness, metalness). The material graph needs those values, not just colour swatches.

### 4d. How the sheet should be used in Round 4

- Hand builders build from the sheet, not from AI concepts.
- The material graph is built to match the sheet's material language, not to match a concept painting.
- The sheet is the test: if a Round 4 hull does not read as Hullbreaker at distance, it fails, however good its detail.

## The Round 4 proposal

### Route 1: Material graph + hand-built hull (recommended)

- **What:** Hand-built Pyre-Barge hull from the reference sheet. Faction material graph (soot black, rust plate, wear from curvature/AO) baked to 2048x2048. Trim sheet for panel lines, bolts, hazard stripes. Decal atlas for trophy plates and hull numbers.
- **Cost:** ~1-2 h for the graph (once), ~15-30 min per hull to apply, ~10-20 min bake per hull. Hand build is the main cost, but it is the cost the project already pays for a hero hull.
- **What it proves:** That the fleet look can be built without painting, without the grid, and without double lighting, on the hardest hull.

### Route 2: Trim sheet only (control)

- **What:** Hand-built Pyre-Barge hull, trim sheet only, no material graph. Base material is flat.
- **Cost:** ~6-10 h for the trim sheet (once), ~1-3 h per hull to lay UVs and place decals.
- **What it proves:** Whether a trim sheet alone is enough, or whether the base material graph is necessary for the Hullbreaker read. This is the control that isolates the graph's contribution.

### Route 3: Unique texture rescue (hero only)

- **What:** Hand-painted 2048x2048 set for the Pyre-Barge only, as a rescue if Routes 1 and 2 fail.
- **Cost:** ~8-12 h human, ~10-20 min bake.
- **What it proves:** Nothing about the fleet. It is included only so the flagship is not blocked if the graph route fails.

### Recommended ranking

1. **Route 1 - Material graph + hand-built hull.** Winner on cost, fleet consistency, and failure-mode coverage.
2. **Route 2 - Trim sheet only.** Useful control, but not a fleet solution on its own.
3. **Route 3 - Unique texture rescue.** Hero-only fallback, not a fleet strategy.

**Comparison metric for Round 4:** Grid presence (yes/no on curved sections), double lighting (yes/no), fleet consistency (does it read as Hullbreaker at distance?), and cost per hull after the first. Route 1 is expected to win on all four.

## Owner questions

**Q1. Material graph scope.** Should the material graph be built per faction (one graph for Hullbreaker, reused across all Hullbreaker hulls), or per hull? R82 Q1 says per faction.
**Pick:** Per faction. A per-hull graph is just unique textures with extra steps.

**Q2. Trim sheet ownership.** Should the trim sheet be owned by the material artist (as part of the graph) or by the hull builder (as part of the hull)?
**Pick:** Material artist. The trim is fleet language, not hull detail. If hull builders own it, it drifts.

**Q3. Trophy-plate decals.** R82 Q2 says trophy plates (and their old colours) appear on the flagship only. If the owner wants them on other hulls later, should we pre-build a small trophy-plate decal set now, or defer?
**Pick:** Defer. Flagship only per the spec. If the fleet look needs them later, the decal atlas can absorb them cheaply.

**Q4. Round 4 scope: one hull or three?** R82 Q4 names three calibration hulls (Pyre-Barge, Eclipse Zenith, Ninefold Maw). Round 4 as written in R92 tests the Pyre-Barge. Should the Eclipse Zenith and Ninefold Maw also go through round 4, or wait?
**Pick:** Pyre-Barge only for round 4. It is the flagship and the hardest case (largest, most complex, trophy plates). If the winning route works on the Pyre-Barge, the other two calibration hulls are easier. Running all three triples the cost without adding decision clarity.

**Q5. AI greeble library timing.** Q2 strategy 3 proposes an AI-generated greeble library (pipes, conduits, vents) as a supplement. Should this be built as part of round 4, or deferred to a separate task after round 4 settles the hull approach?
**Pick:** Defer to a separate task. Round 4 should focus on the three hull routes and the material pass. The greeble library is a fleet-scaling concern that becomes urgent at hull 4+, not at hull 1. Building it now would add 20-40 h without changing the round 4 comparison.

*End of Qwen writer leg. All rankings are independent of the DeepSeek leg. Model-currency claims for Hunyuan3D-2.5, TRELLIS successors, Step1X-3D, and Hi3DGen are marked INFERRED where I could not verify against a primary source in this session; the Argon reviewer leg should check them against current repositories and documentation.*
