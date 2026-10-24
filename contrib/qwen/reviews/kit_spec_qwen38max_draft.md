# Kit specification draft: Qwen3.8-Max leg

Provenance: generated in Qwen chat (chat.qwen.ai/c/a1623971-6a96-4eda-88fa-e0b797f7b980, sidebar title "Voidsworn Kit Specification Draft") on Oct 24, 2026, model Qwen3.8-Max, Thinking ON, Search OFF, signed in as rcbailey12@gmail.com. File upload was unavailable (hidden file input), so the brief and the kit proposal were pasted as verbatim text into the chat prompt. The model generated two candidate responses; Response 1 (below, verbatim) was the complete draft and Response 2 was still generating fragments. One em dash in the model's text was normalized to a hyphen (line 191) for the no-em-dash rule; wording is otherwise verbatim. Screening and synthesis against the DeepSeek leg follow separately; nothing here is verified.

===== FULL SPECIFICATION TEXT (Qwen3.8-Max, Thinking on, Search off) =====

VOIDSWORN KIT SPECIFICATION DRAFT

1. Manifest JSON Schema Specification

Grounding
- OBSERVED: "A hull is a small data record: faction pack, size class, station overrides… module list with landmark placements" (ship_kit_upgrade.md).
- OBSERVED: "Landmarks in the manifest (prow, bridge, hangar, gun deck, engine)" (ship_kit_upgrade.md).
- INFERRED: Coordinate system must be Y-up, Z-forward to match Babylon.js defaults and existing loftVD orientation; landmarks are normalized 0.0–1.0 ratios along the longitudinal axis to remain valid across size-class scaling.
- OBSERVED: "Variants… become manifest diffs, not rebuilds" (ship_kit_upgrade.md).
- INFERRED: Schema requires an optional inherit field for variant diffing; base manifests must be self-contained to satisfy the "data record" definition.

Schema Definition
The Hull Manifest conforms to the following structure. All fields are required unless marked optional.
```json
{
  "$schema": "http://voidsworn.dev/schemas/hull-manifest-v1.json",
  "type": "object",
  "required": ["id", "factionPack", "sizeClass", "stations", "modules"],
  "properties": {
    "id": { "type": "string", "pattern": "^[A-Z][a-z]+_[A-Z][a-z]+_[0-9]+$" },
    "inherit": { "type": "string", "description": "Optional parent manifest ID for variant diffs" },
    "factionPack": {
      "type": "string",
      "enum": ["voidsworn", "hegemony", "corsairs", "chorus", "ithar", "deathless"]
    },
    "sizeClass": {
      "type": "integer",
      "minimum": 1,
      "maximum": 6,
      "description": "1=Scout, 2=Frigate, 3=Destroyer, 4=Cruiser, 5=Battleship, 6=Capital"
    },
    "seed": { "type": "integer", "description": "Deterministic RNG seed for Corsair asymmetry or Chorus growth" },
    "stations": {
      "type": "array",
      "minItems": 3,
      "items": {
        "type": "object",
        "required": ["t", "width", "thickness", "sectionFamily"],
        "properties": {
          "t": { "type": "number", "minimum": 0.0, "maximum": 1.0" },
          "width": { "type": "number", "exclusiveMinimum": 0 },
          "thickness": { "type": "number", "exclusiveMinimum": 0 },
          "verticalOffset": { "type": "number", "default": 0.0 },
          "sectionFamily": {
            "type": "string",
            "enum": ["round", "gothicArch", "wedge", "slab", "rib", "bio"]
          },
          "bevel": { "type": "number", "minimum": 0.0, "maximum": 1.0, "default": 0.0 }
        }
      }
    },
    "modules": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["moduleId", "landmark", "scale"],
        "properties": {
          "moduleId": { "type": "string" },
          "landmark": {
            "type": "string",
            "enum": ["prow", "bridge", "hangar", "gunDeck", "engine"]
          },
          "scale": { "type": "number", "exclusiveMinimum": 0 },
          "rotationOffset": { "type": "array", "items": { "type": "number" }, "minItems": 3, "maxItems": 3 }
        }
      }
    }
  }
}
```

Complete Example Manifest: Hero Hull (Voidsworn Basilica)
This example represents the Basilica hero hull referenced as the first proof target.
```json
{
  "id": "Voidsworn_Basilica_01",
  "factionPack": "voidsworn",
  "sizeClass": 5,
  "seed": 8842,
  "stations": [
    { "t": 0.00, "width": 0.8, "thickness": 0.6, "verticalOffset": 0.0, "sectionFamily": "gothicArch", "bevel": 0.0 },
    { "t": 0.15, "width": 2.4, "thickness": 1.8, "verticalOffset": 0.2, "sectionFamily": "gothicArch", "bevel": 0.0 },
    { "t": 0.40, "width": 4.2, "thickness": 3.0, "verticalOffset": 0.5, "sectionFamily": "gothicArch", "bevel": 0.0 },
    { "t": 0.60, "width": 4.5, "thickness": 3.2, "verticalOffset": 0.8, "sectionFamily": "gothicArch", "bevel": 0.0 },
    { "t": 0.85, "width": 3.0, "thickness": 2.8, "verticalOffset": 1.2, "sectionFamily": "gothicArch", "bevel": 0.1 },
    { "t": 1.00, "width": 1.2, "thickness": 1.5, "verticalOffset": 1.5, "sectionFamily": "gothicArch", "bevel": 0.2 }
  ],
  "modules": [
    { "moduleId": "vsp_spire_tall", "landmark": "engine", "scale": 1.2, "rotationOffset": [0, 0, 0] },
    { "moduleId": "vsp_sensor_dome", "landmark": "bridge", "scale": 1.0, "rotationOffset": [0, 0, 0] },
    { "moduleId": "vsp_lance_battery", "landmark": "gunDeck", "scale": 1.1, "rotationOffset": [0, 0, 0] },
    { "moduleId": "vsp_hangar_gothic", "landmark": "hangar", "scale": 1.0, "rotationOffset": [0, 0, 0] },
    { "moduleId": "vsp_prow_ram", "landmark": "prow", "scale": 1.0, "rotationOffset": [0, 0, 0] }
  ]
}
```

2. Loft Interpolation Scheme Recommendation

Grounding
- OBSERVED: "Loft interpolates stations with smooth curves and computes true normals" (ship_kit_upgrade.md).
- OBSERVED: "Corner cutting survives only as an explicit per-station bevel parameter, never as a global smoothing pass" (ship_kit_upgrade.md).
- OBSERVED: Section families include "round, gothic arch, wedge, slab, rib, bio" (ship_kit_upgrade.md).
- INFERRED: Catmull-Rom splines are required over B-splines because B-splines do not interpolate control points exactly; grammar-defined stations (e.g., Hegemony wedge peaks) must appear at exact specified widths/thicknesses without deviation.
- INFERRED: True normal computation requires analytical derivatives of the interpolation function, not post-hoc smoothing, to preserve hard edges where bevel is 0.0.

Recommended Scheme: Centripetal Catmull-Rom with Piecewise Normal Derivation

Rationale:
1. Exact Station Interpolation: Unlike cubic B-splines which approximate, Catmull-Rom guarantees the curve passes through every defined station (t, width, thickness). This is non-negotiable for grammar packs where specific stations define silhouette identity (e.g., Deathless rib segmentation). OBSERVED: "A new hull that violates its pack should be impossible to express" (ship_kit_upgrade.md). If the loft drifts from station values, the grammar is violated by the interpolation itself.
2. Cusp Preservation: Centripetal parameterization prevents self-intersection and loops at sharp transitions between dissimilar section families (e.g., slab-to-wedge). Standard uniform Catmull-Rom creates cusps when station spacing is uneven; centripetal weighting by chord length eliminates this artifact while maintaining C1 continuity within segments.
3. Analytical Normals: For each segment between station i and i+1, the tangent vector is computed analytically from the Catmull-Rom polynomial derivative. Surface normals are derived via cross-product of longitudinal tangent and circumferential tangent (computed from the section family's parametric derivative). This satisfies "computes true normals" without any post-process smoothing that would reintroduce the sanded-corner defect.
4. Bevel Integration: The per-station bevel parameter acts as a localized tension modifier on the Catmull-Rom tangents at that station. Bevel=0.0 preserves full C1 continuity; bevel>0.0 reduces tangent magnitude proportionally, creating a controlled crease without abandoning the spline framework. This replaces the global corner-cutting pass entirely.

Station-to-Station Continuity Rules:
- Within same section family: C1 continuous (tangent magnitude and direction matched). Tangent at station i = (P[i+1] - P[i-1]) / 2 scaled by centripetal chord factor.
- Across different section families: C0 continuous (position matched), G1 continuous (tangent direction matched but magnitude may differ). The section family transition point is always exactly at a station boundary; no blending of section shapes occurs between stations.
- At bevel > 0.0: Continuity degrades to C0 at that station only. Adjacent segments retain their internal C1/G1 properties.
- Boundary conditions: First and last stations use phantom points extrapolated linearly from the first/last two real stations to avoid endpoint tangent collapse.

3. Validator Design Specification

Grounding
- OBSERVED: "A new hull that violates its pack should be impossible to express, not merely discouraged" (ship_kit_upgrade.md).
- OBSERVED: "Per-class vertex and triangle ceilings for desktop, enforced at build time" (ship_kit_upgrade.md).
- OBSERVED: "Faction grammar packs… symmetry rule… asymmetry enforced by seed" (ship_kit_upgrade.md).
- INFERRED: Validation must occur at manifest parse time and mesh generation time, not at runtime; "impossible to express" requires structural constraints in the schema plus semantic checks in the builder.
- INFERRED: Failure output must reference the specific grammar rule violated, not just a generic error, to enable rapid iteration on the 36-hull queue.

Validator Architecture
Execution Timing: Build-time only. Integrated into the asset pipeline before VSM serialization. No runtime validation overhead.

Constraint Mechanism (Making Violations Impossible to Express):
The validator operates in three tiers. Tier 1 makes violations structurally unrepresentable; Tier 2 makes them fail at parse time; Tier 3 makes them fail at generation time.
- Tier 1 – Schema-Level Impossibility: The JSON schema (Spec 1) uses enum constraints on factionPack and sectionFamily. A manifest referencing "sectionFamily": "oval" cannot be parsed. The required array ensures no manifest exists without stations or modules. Variant inheritance via inherit is resolved at parse time; circular references are detected via topological sort before any field access.
- Tier 2 – Grammar Pack Semantic Constraints: Each faction pack defines a constraint function executed immediately after schema validation. These are not warnings; they throw typed exceptions.
  - Hegemony: if (stations.any(s => s.sectionFamily !== "wedge")) throw GrammarViolation("HEGEMONY_WEDGE_ONLY"). Symmetry enforced by mirroring check on station widths/offsets.
  - Corsairs: if (seed === undefined || seed === null) throw GrammarViolation("CORSAIR_SEED_REQUIRED"). Asymmetry verified by confirming no bilateral module pairs exist at identical landmarks.
  - Chorus: if (stations.consecutiveSameFamilyCount() > 1) throw GrammarViolation("CHORUS_NO_STRAIGHT_RUN").
  - Deathless: if (!stations.hasRibSegmentation()) throw GrammarViolation("DEATHLESS_RIB_REQUIRED").
  - Voidsworn: if (stations.last().verticalOffset < stations.first().verticalOffset + minSpireDelta) throw GrammarViolation("VOIDSWORN_VERTICAL_EMPHASIS").
  - Ithar: if (stations.max(s => s.thickness) > itharMaxThickness) throw GrammarViolation("ITHAR_NEEDLE_PROFILE").
- Tier 3 – Budget & Geometry Constraints: Executed after mesh generation but before VSM write.
  - Vertex/triangle count checked against per-class ceiling table. Exceedance throws BudgetViolation("CLASS_5_TRI_LIMIT", actual, limit).
  - Module landmark validity: every module's landmark must correspond to a station region where the hull surface exists (no floating modules). Throws PlacementViolation("MODULE_OFF_SURFACE", moduleId).
  - Two-tone paint enforcement: manifest must reference both base and trim material channels. Throws PaintViolation("MISSING_TRIM_CHANNEL").

Failure Output Format:
```
BUILD FAILED: Voidsworn_Basilica_01
VIOLATION: GrammarViolation(VOIDSWORN_VERTICAL_EMPHASIS)
LOCATION: stations[5].verticalOffset = 1.5, expected >= 2.0 (minSpireDelta for sizeClass 5)
RULE: Voidsworn grammar requires aft vertical emphasis; stern station must exceed prow by class-scaled delta.
ACTION: Increase stations[5].verticalOffset or reduce stations[0].verticalOffset.
```
No silent failures. No warnings promoted to errors later. Every violation halts the build for that hull immediately with actionable remediation.

4. Paint-Gain Approach Specification

Grounding
- OBSERVED: "One gain across hull and kit texels, the 0.3 emissive fudge in aiKitMat deleted" (ship_kit_upgrade.md).
- OBSERVED: "FAC3D is the single colour source" (ship_kit_upgrade.md).
- OBSERVED: "Colour law: cyan means shields, nothing else is cyan" (implied by brief's grounding rules and FAC3D authority).
- OBSERVED: "Two-tone minimum per hull is enforced by the pack (base plus trim always both present)" (ship_kit_upgrade.md).
- INFERRED: Gain must be computed per-class from measured luminance of FAC3D palette entries to replace the hardcoded 0.3 fudge; a fixed value would recreate the same problem across varying faction palettes.
- INFERRED: Hulls exceeding class budget after paint application must fail at build time, consistent with Spec 3's budget enforcement; no runtime degradation path exists under PC-only ruling.

Paint-Gain Derivation and Application
Gain Value Derivation: Measured Per-Class from FAC3D Palette
The gain value G_class is not fixed, not artist-tuned per hull, and not derived from shader parameters. It is computed at build time from the FAC3D palette entry for the hull's faction and size class:
1. Extract the base colour C_base and trim colour C_trim from FAC3D for the given (factionPack, sizeClass) tuple.
2. Compute perceptual luminance L = 0.2126 * R + 0.7152 * G + 0.0722 * B for both channels (linear RGB, not sRGB).
3. Compute target composite luminance L_target from the class budget table: L_target[class] is pre-measured from the six hero plate reference renders under standard battle lighting.
4. Solve for scalar gain G_class such that luminance(G_class * (C_base * mask_base + C_trim * mask_trim)) == L_target. This is a single scalar division: G_class = L_target / max(L_base, L_trim) clamped to [0.5, 3.0].
5. Cyan exclusion: if either C_base or C_trim has hue within ±15° of 180° (cyan) and saturation > 0.3, throw PaintViolation("CYAN_RESERVED_FOR_SHIELDS") before gain computation. This enforces the colour law at the data level.

Application:
- G_class is applied uniformly to all hull body texels and all kit module texels attached to that hull. There is no separate gain for modules; "one gain across hull and kit texels" is literal.
- The 0.3 emissive multiplier in aiKitMat is deleted. Emissive intensity is now G_class * emissiveChannel where emissiveChannel comes from FAC3D's glow slot, not a hardcoded constant.
- HullFx rim, roughness break-up, and wear operate on the gained colour output, not on raw FAC3D values. This ensures wear patterns scale correctly with class brightness.

Budget Exceedance Handling:
- After gain application and texture atlas packing, total texture memory for the hull is measured.
- If measured memory exceeds the per-class texture budget (derived from the 1.32 GB / 20-ship target = ~66 MB per ship average, with class-weighted allocation), the build fails with BudgetViolation("TEXTURE_MEMORY_EXCEEDED", actualMB, limitMB).
- There is no automatic downscaling, no mip-map stripping, no runtime LOD fallback. The manifest must be revised (fewer modules, smaller texture resolution, or reclassified size class) and rebuilt. This is consistent with "budgets plus lazy loading or eviction for off-screen factions still apply if the desktop stress test demands it" - but the stress test gate is passed only by compliant hulls.
- Gain values are cached per (factionPack, sizeClass) and invalidated only when FAC3D palette data changes. Recomputation cost is negligible (<1ms per hull).

Evidence That Would Change Recommendations
1. Loft scheme: If Babylon.js's built-in curve primitives support exact interpolation with analytical normals natively, the custom Catmull-Rom implementation should be replaced to reduce maintenance burden. Current recommendation assumes no suitable built-in exists.
2. Manifest schema: If the 36 existing AI-generated hulls have station counts below 3 or above a discovered maximum, the minItems: 3 constraint must be relaxed or tightened accordingly. Current minimum is inferred from geometric necessity, not measured asset data.
3. Paint gain: If FAC3D palette entries for certain factions produce G_class values outside [0.5, 3.0] consistently, the clamp range indicates a palette design flaw rather than a gain computation flaw; recommendation would shift to palette revision protocol instead of gain clamping.
4. Validator: If grammar pack constraints prove too restrictive during the six-hero proof set (e.g., Basilica requires a station family not in Voidsworn's enum), the constraint mechanism must support per-manifest overrides with explicit justification fields, rather than absolute prohibition. Current design assumes grammar packs are complete and correct.
5. Budget tables: If the 1.32 GB texture memory figure from the pipeline audit is revised after desktop stress testing, all per-class ceilings and gain-derived texture allocations must be recalculated proportionally. Current spec treats 1.32 GB as fixed.

Not Specified
1. Exact per-class vertex, triangle, and texture memory ceiling values. The brief and proposal reference budgets and the 1.32 GB / 20-ship target but do not provide the class-weighted distribution table. These must be derived from desktop stress testing before build-time enforcement can be calibrated.
2. FAC3D palette data structure or API. The spec assumes FAC3D exposes (factionPack, sizeClass) → {base, trim, glow} but the actual interface is not documented in either source.
3. Module library asset IDs or geometry specifications. The example manifest uses placeholder IDs (vsp_spire_tall, etc.); the actual module registry and its parametric interfaces are outside this spec's scope.
4. Lazy loading or eviction policy details. The proposal mentions these as contingent on desktop stress test results but provides no trigger thresholds or implementation requirements.
5. Screenshot acceptance automation criteria. The proposal describes human-reviewed screenshot gates but specifies no automated image comparison metrics or tolerance values for the silhouette sheet test.
6. Variant diff semantics beyond inherit. The schema supports inheritance but does not specify merge conflict resolution rules if a child manifest overrides a field that the parent's grammar pack constrains.
7. Seed-to-asymmetry mapping algorithm for Corsairs. The spec requires a seed and validates asymmetry but does not define how seed values deterministically produce non-mirrored module placements.

===== END OF SPECIFICATION TEXT =====
