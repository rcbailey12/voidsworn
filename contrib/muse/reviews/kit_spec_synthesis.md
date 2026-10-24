# Kit spec synthesis: DeepSeek + Qwen 3.8-Max (chair: Rey)

Job: draft the four kit mechanisms (manifest JSON schema + complete example, loft interpolation scheme, validator design, paint-gain approach) from ship_kit_upgrade.md plus the brief. Both legs filed under contrib/deepseek/reviews/kit_spec_deepseek_draft.md and contrib/qwen/reviews/kit_spec_qwen38max_draft.md. Screening notes in the goal hidden_files folder.

Chair verdict: GO WITH CONDITIONS. The legs are complementary, not competing. DeepSeek's draft is the fuller machine and the one to adopt as the base; Qwen's draft contributes framing and one rationale DeepSeek agrees with. Both need the same measurement pass before any number in either draft hardens.

## Consensus (adopt)

- Closed manifest schema: no free-transform field, no colour literals, no self-granted budgets. Modules attach only via socket requests; the placer is the sole writer of resolved transforms; ceilings live outside the manifest as versioned references.
- The pack is the source of truth: allowed families, landmarks, modules, symmetry, and class compatibility are declared once per faction and compiled into the authoring surface.
- Dressing, not generation: base mesh vertices are immutable; loft output is a guide surface plus dressing geometry, never a replacement hull.
- Cyan is a baked-result gate, not a style note: Qwen's data-level exclusion plus DeepSeek's OKLCH texel check after gain. Adopt both layers.
- Basilica as the proof manifest, bound by registry key until a real mesh is named. Both legs are honest that the binding is illustrative.
- Every ceiling, budget, and gain value is pending measurement. Neither leg's numbers are adoptable as-is.

## DeepSeek-only, adopted as the base

- Four-layer constraint mechanism: pack record, pack compiler emitting closed schema plus TypeScript types plus a typed builder, placer, fail-closed build gate. This is the direct answer to "impossible to express, not merely discouraged," and it is stronger than Qwen's three-tier validator, which it subsumes.
- Loft hybrid: centripetal Catmull-Rom for station centers, PCHIP for scalar profiles (width, thickness, offsets), hard stations for creases, feature-anchored resampling for section correspondence, analytic normals split at hard stations. Qwen argued Catmull-Rom alone; the hybrid fixes Catmull-Rom's overshoot problem on positive bounded profiles.
- Gain calibration as a falsifiable procedure: Huber-weighted least squares over a FAC3D palette chart under the battle lighting rig, clamp [0.75, 1.25], 3% residual gate, fixed-1.0 fallback only by explicit manifest change. Qwen's gain was a formula shape; this is a measurement procedure.
- Budget remediation ladder in order: drop budgetOptional modules, reduce scale, downscale atlas, merge modules, escalate base-exceeds to the hull owner, ceiling change with sign-off last. Plus structured diagnostics with codes, exit codes, and previous-artifact preservation.
- Dress tolerance (1.0% of beam), functional cones (hangar, engine, gun arc, prow), clearance spheres with priority resolution, and streaming/eviction metadata gates.

## Qwen-only, carried

- The validator's three-tier framing (schema, geometry, budget) as a reading aid over DeepSeek's check tables. The tables themselves are DeepSeek's.
- The centripetal Catmull-Rom rationale (interpolation semantics, locality for manifest diffs), which DeepSeek adopts for centers.
- The honest Not Specified list, which overlaps DeepSeek's and adds: the model's own admission that its size ladder was invented and its validator code defect (see below).

## Corrections to DeepSeek (all verified by grep or parse)

1. Example count: the text claims fifteen socket requests; the manifest has fourteen. Modules (fifteen) and stations (six) are correct.
2. Example violates its own table: capital gun_deck minimum is six in section 1.4.2, but the Basilica example has four.
3. Size-class enum is invented. data.js HULLS cls values are Frigate, Destroyer, Cruiser, Carrier, Battleship, Battle-barge, Dreadnought, Super-dreadnought, Ark, Bio-titan, Tomb-ark, Squadron. Twelve classes, five singletons. The schema enum must be replaced by this taxonomy or a documented mapping, and p95 ceilings are meaningless for the singleton classes (DeepSeek's own caveat).
4. FAC3D has no "glow" channel. ships3d.js:2-8 keys are hull, dark, trim, win, eng, bolt, beam, shield, tip. Spec 4's FAC3D.glow needs a mapping before the gain spec is implementable.
5. The 0.3 fudge is already gone. ships3d.js:787 says so, and ships3d.js:790 defaults G.kitFill to 0. Spec 4's deletion step is done; what remains is the calibration and confirming kitFill stays off.
6. Handedness is undecided. Nothing in the repo sets useRightHandedSystem, so the scene is Babylon's left-handed default, and ships3d.js:717 shows mesh orientation varies per hull (two built side-on). DeepSeek's right-handed authoring frame needs a conversion decision, not a silent default.
7. The 52.8 MB per-ship texture budget derives from the kit doc's 1.32 GB figure, which Pack J established as asserted without derivation. Honest derivation, unverified input; the desktop stress test is the authority.
8. Two modules share bridge.0 (keep plus shield emitter). The schema allows it; the clearance rules need an explicit co-location rule.

## Corrections to Qwen (from its screening, restated for the merge)

- Its schema JSON does not parse (stray quote). DeepSeek's schema does, so DeepSeek's is the base document.
- Its size ladder (Scout through Capital, 1-6) is likewise invented against the same data.js taxonomy.
- Its validator example code contained a homoglyph defect (Cyrillic letters in an identifier). Do not copy code from that leg without retyping.
- Its paint gain is a formula shape inheriting the same unverified 1.32 GB figure, not a calibration procedure. DeepSeek's Spec 4 replaces it.
- Its "Y-up, Z-forward" axis claim is unverified as a universal rule; DeepSeek asserts +Z forward too, but the repo evidence (per-hull orientation variance) says neither claim holds for all 36 meshes without a per-mesh orientation record.

## Open decisions (Ryan's or Opus's, not the chair's)

- Size-class taxonomy: adopt data.js cls values directly, or map them to a smaller kit ladder (e.g. merge Ark/Bio-titan/Tomb-ark/Super-dreadnought into a capital band)? The mapping changes every ceiling.
- Handedness: change the scene to right-handed, or convert once at VSM import with a declared sourceHandedness and a mirror-detection check?
- FAC3D glow mapping: which real channel (eng, beam, win) carries the gain spec's glow role?
- Voidsworn symmetry: bilateral is assumed by both legs; the kit doc never pins it.
- Basilica bound mesh: which existing mesh does the proof manifest dress?
- Pipeline: can the build run TypeScript codegen and enforce branded types, or does enforcement fall back to schema-only (DeepSeek's item 10)?

## Recommended next step

Opus runs the measurement pass first, before adopting either draft as the rewrite basis: per-real-class triangle and texture distributions across the 36 meshes, the FAC3D channel mapping, and a handedness and per-mesh orientation audit. Every ceiling, the gain calibration, and the schema enum depend on that pass, and it settles four of the six open decisions with data instead of argument. After it lands, the merged spec is DeepSeek's draft with corrections 1, 2, 4, and 8 applied and the size enum replaced.
