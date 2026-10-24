# VOIDSWORN KIT SPECIFICATIONS

Model: DeepSeek, DeepThink ON, Search OFF. Filed verbatim from the DeepSeek chat report; em dashes normalized to hyphens, wording otherwise unchanged. One transient "Server is temporarily unavailable" interrupted the first generation; it was resumed via Continue and completed in full.

Status: Draft specifications for the four mechanisms named in the kit proposal. This document specifies; it does not audit or verdict the proposal.

Grounding convention used throughout: Every claim about an existing document is tagged OBSERVED with a quote under 20 words, or INFERRED. Quotes tagged OBSERVED (brief) come from kit_spec_brief.txt; quotes tagged OBSERVED (kit) come from ship_kit_upgrade.md. Numeric values marked PROPOSED are design parameters for sign-off, not asset measurements. No asset facts are invented.

Scope constants taken from the brief: the kit performs "dressing, paint unification, and VSM format conversion of existing meshes" - OBSERVED (brief) - and is "NOT hull shape generation" - OBSERVED (brief). The platform is "PC-only in Babylon" - OBSERVED (brief). Battle target is "target battle size around 20 ships" - OBSERVED (brief). The subjects are "space ships, never naval ships" - OBSERVED (brief). Colour authority is "FAC3D is the single colour source" - OBSERVED (brief). Colour law is "cyan means shields, nothing else is cyan" - OBSERVED (brief). Thirty-six meshes exist: "36 AI-generated hull meshes already exist and load" - OBSERVED (brief). Exactly one finished VSM exists: "only hull C19_51 on the compressed .vsm plus _kit.json path" - OBSERVED (brief).

## SPECIFICATION 1 - HULL MANIFEST JSON SCHEMA, COORDINATE SYSTEM, SOCKETS, AND PLACEMENT RULES

### 1.1 Purpose and non-purpose

The manifest is the authored data record for dressing an existing hull mesh. It is a record of intent, not a hull definition. The kit proposal says "Hulls become data (a manifest plus a faction grammar pack)" - OBSERVED (kit). The brief limits the record to "faction pack, size class, station overrides, and a module list with landmark placements (prow, bridge, hangar, gun deck, engine)" - OBSERVED (brief). The kit proposal names the same fields: "station overrides (length, beam, thickness profile)" and "module list with landmark placements" - OBSERVED (kit).

The manifest does not contain raw hull vertex data, raw mesh topology, colour literals, shader source, gameplay stats, or hand-authored world transforms for modules. It contains socket requests, not free coordinates. The build's placer resolves requests into transforms against the bound existing mesh. This is the first mechanism by which forbidden placements become unexpressible: the authoring surface has no field in which to write a forbidden coordinate.

### 1.2 Coordinate system

1.2.1 Handedness and axes. Ship-local space is right-handed, metric, and defined as:

- +Z = forward (toward the prow).
- +X = starboard.
- +Y = dorsal (toward the keel-up direction; for space hulls this is the authored "up", not a waterline normal).
- Right-handed check: X x Y = Z.

Babylon.js is conventionally left-handed; the recommendation is to set scene.useRightHandedSystem = true for the game scene, or to apply exactly one conversion quaternion at VSM import. INFERRED: the repository's current handedness is not stated in either granted document. The manifest's handedness is therefore an explicit schema constant, and the importer must declare a sourceHandedness field in its build report so a mismatch is caught rather than silently mirrored.

1.2.2 Origin. The origin is the hull datum, defined as:

- Longitudinal zero: the midpoint of the bound mesh's axis-aligned bounding box along Z, unless the hull binding supplies a datumS override.
- Vertical zero: the hull's longitudinal centerline plane (the plane containing the Z axis and the authored up direction). It is not a waterline. The brief says "space ships, never naval ships" - OBSERVED (brief) - so no waterline semantics are permitted in the schema.
- Lateral zero: the centerline plane X = 0.

1.2.3 Units. Metres. All manifest lengths are metres. Scale factors are dimensionless. Angles are degrees at the authoring surface and radians internally; the schema declares degrees.

1.2.4 Station parameter. s in [0, 1], with s = 0 at the aft extremity and s = 1 at the fore extremity, measured along the bound mesh's longitudinal axis. Station overrides and socket sRange constraints use this parameter. This matches the kit proposal's station-list model - "A hull is a list of stations" - OBSERVED (kit) - while acknowledging that AI meshes may not have authored stations. INFERRED: for existing meshes, s is a normalized projection onto the bounding-box longitudinal axis, refined by the guide surface described in Specification 2.

1.2.5 Socket-local frame. Each resolved socket is a transform T = (p, q, s_scale) mapping socket-local coordinates to ship-local coordinates:

- Socket-local +Y = outward surface normal for surface anchors; for centerline and hardpoint anchors it is the authored up reference.
- Socket-local +Z = module forward. For most modules this points toward the prow; a socket may declare forwardMode: "prow" | "outward" | "aft".
- Socket-local +X = Y x Z, normalized. This guarantees a right-handed socket frame with determinant +1.
- q is a unit quaternion in [x, y, z, w] order, mapping socket-local to ship-local.
Mirrored sockets are generated by reflecting X and rebuilding the basis so the determinant remains +1: reflect the position across X = 0, reflect the +X and +Z axes, keep +Y, and renormalize. The placer, not the author, performs this operation.

### 1.3 Size classes and budgets

The brief requires a size class field. INFERRED: the granted documents do not enumerate class names. The schema therefore uses a closed enum that must be replaced by the project's actual class taxonomy before the first build. PROPOSED provisional enum:

["light", "line", "heavy", "capital"]

The kit proposal requires "Per-class vertex and triangle ceilings for desktop, enforced at build time" - OBSERVED (kit). The manifest does not carry the ceiling numbers; it carries a classCeilingRef that resolves to a versioned budget record. This keeps ceilings in one table and makes a manifest unable to self-grant a larger budget. INFERRED: a manifest that embedded its own ceiling would let an author raise the budget by editing the hull, which defeats the gate.

PROPOSED budget record shape, stored outside the manifest:

{
  "id": "desktop.capital.v1",
  "platform": "desktop",
  "sizeClass": "capital",
  "maxTriangles": 0,
  "maxVertices": 0,
  "maxTextureKB": 0,
  "measurementBasis": "p95-of-class-plus-kit-allowance",
  "status": "provisional-pending-measurement"
}

The zeroes are deliberate: they must be filled by measurement of the existing 36 meshes before sign-off. The brief states desktop hulls are "roughly 2,400 to 38,000 triangles each" - OBSERVED (brief) - so a ceiling below 38,000 triangles for the largest existing class would make an existing hull unshippable. INFERRED: the ceiling derivation must measure the actual distribution per class, not assume a round number.

### 1.4 Socket definitions

A socket is a named, typed attachment frame on the hull. Sockets are produced by the placer from socket requests. The five landmark families required by the brief are "prow, bridge, hangar, gun deck, engine" - OBSERVED (brief). The schema defines these as the required landmark enum and allows pack-extended landmarks (for example spire_aft, fin_dorsal, fin_ventral, sensor, donor_panel) only when the faction pack declares them.

1.4.1 Socket request fields

| Field | Type | Required | Meaning |
|---|---|---|---|
| id | string, pattern ^[a-z][a-z0-9_]*\.[0-9]+$ | yes | Stable socket request identifier, e.g. gun_deck.0. |
| landmark | enum | yes | One of prow, bridge, hangar, gun_deck, engine, or a pack-declared extension. |
| ordinal | integer >= 0 | yes | Deterministic ordering within the landmark. |
| anchor | enum | yes | surface, centerline, bulkhead, hardpoint, bbox_normalized. |
| side | enum | no | port, starboard, center; default center for centerline landmarks, both for bilateral landmarks. |
| sRange | [number, number] | no | Restricts the longitudinal search window; both in [0,1], first <= second. |
| normalConeDeg | number, 0-90 | no | Maximum allowed deviation between socket +Y and the guide-surface normal. |
| offsetM | number | no | Surface offset along socket +Y; default 0. |
| forwardMode | enum | no | prow, outward, aft; default prow except for engine, default aft. |
| mirror | enum | no | inherit, force, forbid; default inherit from pack symmetry policy. |
| clearanceM | number >= 0 | no | Reserved clearance sphere radius at the socket. |
| tags | array of strings | no | Semantic tags such as shieldEmitter, budgetOptional, decal. |

1.4.2 Landmark semantics and required multiplicity

PROPOSED minimum multiplicities by size class. These are design rules, not asset facts.

| Landmark | Anchor default | Light | Line | Heavy | Capital | Notes |
|---|---|---|---|---|---|---|
| prow | centerline | 1 | 1 | 1 | 1 | Must lie on X = 0, s >= 0.85 unless pack overrides. |
| bridge | surface or centerline | 1 | 1 | 1 | 1 | Dorsal; normalConeDeg <= 35 for surface anchors. |
| hangar | bulkhead | 0-1 | 1 | 1-2 | 2-4 | Mouth cone must be clear; see 1.5.5. |
| gun_deck | surface | 1-2 | 2-4 | 4-8 | 6-12 | Bilateral by default; firing arc cone clear. |
| engine | bulkhead | 1 | 2 | 2-4 | 3-6 | Aft-facing; exhaust cone clear. |
| spire_aft | surface | 0 | 0-2 | 2-4 | 3-6 | Voidsworn pack extension; "spire mounts aft" - OBSERVED (kit). |
| fin_dorsal / fin_ventral | surface | 0 | 0-1 | 1-2 | 2-3 | Ithar pack extension. |

OBSERVED (kit): the six packs are described in one line each: "Voidsworn (gothic sections, vertical emphasis, spire mounts aft)" - OBSERVED (kit) - and the proposal states "A new hull that violates its pack should be impossible to express, not merely discouraged" - OBSERVED (kit). The multiplicity table above is the pack-level constraint that the validator compiles into the pack schema.

1.4.3 Anchor modes

- surface: the placer raycasts or projects against the bound mesh's guide surface; position is the hit point plus offsetM along the surface normal. The socket +Y is the smoothed surface normal within normalConeDeg.
- centerline: position is forced to X = 0; Y and Z are derived from the guide surface's centerline curve at the requested s. Used for prow and centerline domes.
- bulkhead: position is on a pack-declared transverse plane (for example the hangar mouth plane or engine block plane), with +Y along the hull's up reference and +Z pointing aft for engines.
- hardpoint: a named point supplied by the hull binding's _kit.json or a pack registry; the placer does not invent it. This is the only anchor that can exist without a guide-surface hit.
- bbox_normalized: position is bounds.min + t * (bounds.max - bounds.min) for a declared t; used only for early manifest stubs before a mesh binding exists. PROPOSED: such manifests are marked status: "stub" and cannot pass the asset build gate.

### 1.5 Placement rules

The following rules are normative. Each is enforced by the placer and/or the build validator (Specification 3), not by author discipline.

1.5.1 No module without a socket. Every module placement references a socket request ID. There is no module field for a raw position, rotation, or scale-relative-to-hull. The schema has additionalProperties: false, so a raw transform cannot be added.

1.5.2 Placer exclusivity. Only the build placer writes resolved transforms. The authoring manifest contains socketRequests; the build emits manifest.resolved.json containing sockets with p, q, scale, resolvedAgainst (mesh hash), and placerVersion. The asset build accepts only a resolved manifest whose packFingerprint and meshHash match the current inputs. INFERRED: this is the mechanical implementation of "impossible to express": a forbidden coordinate has no legal place to be written.

1.5.3 Deterministic ordering. Sockets for a landmark are sorted by s ascending, then X ascending, then Y ascending. Ordinals are assigned in that order. This makes manifests reproducible and makes a diff meaningful.

1.5.4 Symmetry policy. The faction pack declares one of:

- bilateral: every non-centerline socket is mirrored; mirror: "forbid" is a schema error.
- centerline-only: only X = 0 sockets are legal; any side: "port" or "starboard" is a schema error.
- asymmetric-seeded: mirroring is forbidden; the placer uses seed to choose among pack-permitted variants. The kit proposal says Corsairs have "asymmetry enforced by seed: no mirrored feature placement" - OBSERVED (kit).
- free-seeded: mirroring allowed but seeded; PROPOSED not used by any current pack.
Voidsworn symmetry is not specified in the granted documents. INFERRED / PROPOSED: use bilateral with a centerline preference for the Basilica example, because gothic sections and a central keep read as bilateral, but this must be confirmed before pack sign-off.

1.5.5 Functional cones. Each landmark declares a keep-out cone:

- hangar: a cone of half-angle PROPOSED 25 degrees extending 2.5 x the hangar mouth's largest dimension forward of the mouth plane; no module may intersect it.
- engine: a cone of half-angle PROPOSED 20 degrees extending 1.5 x engine block length aft; no module may intersect it.
- gun_deck: a firing arc of PROPOSED +/-60 degrees in the deck plane and +20 degrees elevation; no module may occlude more than 10% of the arc.
- prow: a forward cone of half-angle PROPOSED 15 degrees extending 1.0 x beam forward of the prow tip; no module may intersect it.
These are design rules, not asset facts. They exist so that "a gun deck that cannot fire" and "a hangar mouth blocked by a spire" are build failures, not art review comments.

1.5.6 Clearance and overlap. Every socket has a clearance sphere. Every module declares a clearance sphere at unit scale; the placer scales it by the class scale and checks pairwise overlap among modules and against the hull's convex-ish proxy (the guide surface's capsule tree). Overlap is resolved by priority: lower priority number wins; ties are resolved by socket order. If the placer cannot resolve, it fails; it does not nudge a module into a legal-looking but unintended position.

1.5.7 Dress tolerance. Because the kit is dressing and not hull generation - "NOT hull shape generation" - OBSERVED (brief) - the placer may not displace the bound hull's vertices. Modules may sit on the surface, recess into a pack-declared bulkhead, or wrap a trim band, but the base mesh vertices are immutable. PROPOSED dress tolerance: any guide-surface deviation from the bound mesh greater than 1.0% of local beam is a build failure; the kit must not "correct" the AI mesh's silhouette.

1.5.8 Scale rule. Module scale = sizeClassScale[sizeClass] x placement.scale x socket.scale. sizeClassScale is declared by the pack. Placement scale is clamped to PROPOSED [0.25, 4.0]. A module cannot scale beyond the pack's declared silhouette envelope.

1.5.9 Budget accounting. Each module declares trianglesAtUnitScale and textureKBAtUnitScale. The manifest's budgets.declaredKitTriangles is the sum after scale; the build recomputes it from the actual baked module geometry and fails on mismatch beyond PROPOSED 2%. The class ceiling applies to base mesh plus kit, not kit alone.

1.5.10 Paint channels only, never colours. The manifest's paint block names FAC3D channels (hull, dark, trim, glow) and a gainPolicy. It contains no RGB, hex, or named colour. The kit proposal says "FAC3D is the single colour source" - OBSERVED (kit). A colour literal in a manifest is a schema violation, not a style preference.

1.5.11 Two-tone minimum. The pack enforces base plus trim; the kit proposal says "Two-tone minimum per hull is enforced by the pack" - OBSERVED (kit). The manifest must declare both hull and trim channels as present. A manifest with only hull is unexpressible in a pack whose schema requires both.

1.5.12 Seed. seed is a uint32. It affects only pack-permitted choices (Corsair asymmetry, Chorus growth-ring phase). It never affects geometry outside the pack, never changes a socket's landmark, and never overrides a budget.

1.5.13 Variants. A variant is a manifest diff against a base manifest: same hullBinding, same factionPack, same sizeClass, changed modules or stationOverrides within pack limits. The kit proposal says variants "become manifest diffs, not rebuilds" - OBSERVED (kit). The schema supports this through variantOf: <manifest id>; the build resolves the base first, applies the diff, and validates the result as a whole.

### 1.6 JSON Schema

The following is the proposed schema. It is deliberately closed (additionalProperties: false) and deliberately lacks any free-transform field. Pack-specific schemas are generated from this base by the grammar-pack compiler (Specification 3), narrowing enums and adding if/then rules.

{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://voidsworn.local/schema/hull-manifest-1.0.json",
  "title": "Voidsworn Hull Manifest (authoring record)",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "schemaVersion", "id", "displayName", "factionPack", "sizeClass",
    "role", "seed", "hullBinding", "stationOverrides", "socketRequests",
    "modules", "paint", "budgets", "acceptance", "provenance"
  ],
  "properties": {
    "schemaVersion": { "const": "1.0" },
    "id": {
      "type": "string",
      "pattern": "^[a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*$"
    },
    "displayName": { "type": "string", "minLength": 1, "maxLength": 64 },
    "variantOf": { "type": "string", "pattern": "^[a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*$" },
    "factionPack": {
      "enum": ["voidsworn", "hegemony", "corsairs", "chorus", "ithar", "deathless"]
    },
    "sizeClass": { "enum": ["light", "line", "heavy", "capital"] },
    "role": { "enum": ["hero", "standard", "variant", "stub"] },
    "seed": { "type": "integer", "minimum": 0, "maximum": 4294967295 },
    "hullBinding": { "$ref": "#/$defs/hullBinding" },
    "stationOverrides": {
      "type": "array",
      "maxItems": 64,
      "items": { "$ref": "#/$defs/stationOverride" }
    },
    "socketRequests": {
      "type": "array",
      "minItems": 1,
      "maxItems": 128,
      "items": { "$ref": "#/$defs/socketRequest" }
    },
    "modules": {
      "type": "array",
      "maxItems": 256,
      "items": { "$ref": "#/$defs/modulePlacement" }
    },
    "paint": { "$ref": "#/$defs/paint" },
    "budgets": { "$ref": "#/$defs/budgets" },
    "acceptance": { "$ref": "#/$defs/acceptance" },
    "provenance": { "$ref": "#/$defs/provenance" }
  },
  "$defs": {
    "vec3": {
      "type": "array",
      "items": { "type": "number" },
      "minItems": 3,
      "maxItems": 3
    },
    "quat": {
      "type": "array",
      "items": { "type": "number" },
      "minItems": 4,
      "maxItems": 4
    },
    "hullBinding": {
      "type": "object",
      "additionalProperties": false,
      "required": ["registryKey", "tier", "sourceHandedness"],
      "properties": {
        "registryKey": { "type": "string", "pattern": "^[a-z][a-z0-9_/]*$" },
        "meshId": { "type": "string" },
        "vsmPath": { "type": "string" },
        "kitPath": { "type": "string" },
        "tier": { "enum": ["desktop"] },
        "sourceHandedness": { "enum": ["right", "left"] },
        "boundsM": {
          "type": "object",
          "additionalProperties": false,
          "required": ["min", "max"],
          "properties": {
            "min": { "$ref": "#/$defs/vec3" },
            "max": { "$ref": "#/$defs/vec3" }
          }
        },
        "measuredTriangles": { "type": "integer", "minimum": 0 },
        "measuredVertices": { "type": "integer", "minimum": 0 },
        "meshHash": { "type": "string" }
      }
    },
    "stationOverride": {
      "type": "object",
      "additionalProperties": false,
      "required": ["s"],
      "properties": {
        "s": { "type": "number", "minimum": 0, "maximum": 1 },
        "widthScale": { "type": "number", "minimum": 0.25, "maximum": 4 },
        "thicknessScale": { "type": "number", "minimum": 0.25, "maximum": 4 },
        "verticalOffsetM": { "type": "number" },
        "sectionFamily": {
          "enum": ["round", "gothic_arch", "wedge", "slab", "rib", "bio"]
        },
        "bevelM": { "type": "number", "minimum": 0 },
        "hard": { "type": "boolean", "default": false }
      }
    },
    "socketRequest": {
      "type": "object",
      "additionalProperties": false,
      "required": ["id", "landmark", "ordinal", "anchor"],
      "properties": {
        "id": { "type": "string", "pattern": "^[a-z][a-z0-9_]*\\.[0-9]+$" },
        "landmark": {
          "enum": [
            "prow", "bridge", "hangar", "gun_deck", "engine",
            "spire_aft", "fin_dorsal", "fin_ventral", "sensor", "donor_panel"
          ]
        },
        "ordinal": { "type": "integer", "minimum": 0 },
        "anchor": { "enum": ["surface", "centerline", "bulkhead", "hardpoint", "bbox_normalized"] },
        "side": { "enum": ["port", "starboard", "center", "both"] },
        "sRange": {
          "type": "array",
          "items": { "type": "number", "minimum": 0, "maximum": 1 },
          "minItems": 2,
          "maxItems": 2
        },
        "normalConeDeg": { "type": "number", "minimum": 0, "maximum": 90 },
        "offsetM": { "type": "number" },
        "forwardMode": { "enum": ["prow", "outward", "aft"] },
        "mirror": { "enum": ["inherit", "force", "forbid"] },
        "clearanceM": { "type": "number", "minimum": 0 },
        "tags": {
          "type": "array",
          "items": { "type": "string", "pattern": "^[a-z][a-z0-9_]*$" },
          "uniqueItems": true
        }
      }
    },
    "modulePlacement": {
      "type": "object",
      "additionalProperties": false,
      "required": ["moduleId", "socketRef", "scale", "priority"],
      "properties": {
        "moduleId": { "type": "string", "pattern": "^[a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*\\.v[0-9]+$" },
        "socketRef": { "type": "string", "pattern": "^[a-z][a-z0-9_]*\\.[0-9]+$" },
        "scale": { "type": "number", "minimum": 0.25, "maximum": 4 },
        "mirror": { "enum": ["inherit", "force", "forbid"] },
        "priority": { "type": "integer", "minimum": 0, "maximum": 999 },
        "budgetOptional": { "type": "boolean", "default": false },
        "tags": {
          "type": "array",
          "items": { "type": "string", "pattern": "^[a-z][a-z0-9_]*$" },
          "uniqueItems": true
        }
      }
    },
    "paint": {
      "type": "object",
      "additionalProperties": false,
      "required": ["channels", "twoTone", "gainPolicy"],
      "properties": {
        "channels": {
          "type": "object",
          "additionalProperties": false,
          "required": ["hull", "trim"],
          "properties": {
            "hull": { "const": "hull" },
            "dark": { "const": "dark" },
            "trim": { "const": "trim" },
            "glow": { "const": "glow" }
          }
        },
        "twoTone": { "const": true },
        "gainPolicy": { "enum": ["measured-v1", "fixed-1.0"] },
        "shieldMaskTag": { "const": "shieldEmitter" }
      }
    },
    "budgets": {
      "type": "object",
      "additionalProperties": false,
      "required": ["classCeilingRef", "declaredKitTriangles", "declaredKitTextureKB"],
      "properties": {
        "classCeilingRef": { "type": "string", "pattern": "^desktop\\.[a-z]+\\.[0-9]+$" },
        "declaredKitTriangles": { "type": "integer", "minimum": 0 },
        "declaredKitTextureKB": { "type": "integer", "minimum": 0 },
        "allowOptionalDrop": { "const": false }
      }
    },
    "acceptance": {
      "type": "object",
      "additionalProperties": false,
      "required": ["plateId", "silhouetteSheetId"],
      "properties": {
        "plateId": { "type": "string" },
        "silhouetteSheetId": { "type": "string" }
      }
    },
    "provenance": {
      "type": "object",
      "additionalProperties": false,
      "required": ["author", "date", "packFingerprint", "builderVersion"],
      "properties": {
        "author": { "type": "string" },
        "date": { "type": "string", "format": "date" },
        "packFingerprint": { "type": "string" },
        "builderVersion": { "type": "string" }
      }
    }
  }
}

### 1.7 Complete example manifest for a hero hull

Hero: Basilica, Voidsworn, capital. The kit proposal's rollout says "Loft v2 plus the Voidsworn grammar pack, proven on one manifest: the Basilica hero from the art pack" - OBSERVED (kit).

Important grounding note: the example's numeric coordinates, dimensions, module IDs, and socket ordinals are illustrative schema values, not measurements of any existing asset. The brief does not state which existing mesh the Basilica dress binds to. The binding therefore uses a registry key, voidsworn/hero/basilica, resolved at build time by hull_registry.json; the actual meshId and vsmPath are Not specified. This keeps the example complete as a data record without inventing an asset fact.

{
  "schemaVersion": "1.0",
  "id": "voidsworn.basilica.hero",
  "displayName": "Basilica",
  "factionPack": "voidsworn",
  "sizeClass": "capital",
  "role": "hero",
  "seed": 190451,
  "hullBinding": {
    "registryKey": "voidsworn/hero/basilica",
    "tier": "desktop",
    "sourceHandedness": "right",
    "boundsM": {
      "min": [-96.0, -38.0, -240.0],
      "max": [96.0, 52.0, 240.0]
    }
  },
  "stationOverrides": [
    { "s": 0.0, "widthScale": 0.82, "thicknessScale": 0.90, "verticalOffsetM": 0.0, "sectionFamily": "gothic_arch", "hard": true },
    { "s": 0.18, "widthScale": 0.94, "thicknessScale": 0.96, "verticalOffsetM": 1.5, "sectionFamily": "gothic_arch", "bevelM": 0.8 },
    { "s": 0.46, "widthScale": 1.0, "thicknessScale": 1.0, "verticalOffsetM": 0.0, "sectionFamily": "gothic_arch", "bevelM": 1.2 },
    { "s": 0.74, "widthScale": 0.88, "thicknessScale": 0.92, "verticalOffsetM": -1.0, "sectionFamily": "gothic_arch", "bevelM": 0.6 },
    { "s": 0.93, "widthScale": 0.62, "thicknessScale": 0.74, "verticalOffsetM": -2.0, "sectionFamily": "gothic_arch", "hard": true },
    { "s": 1.0, "widthScale": 0.18, "thicknessScale": 0.30, "verticalOffsetM": -3.0, "sectionFamily": "gothic_arch", "hard": true }
  ],
  "socketRequests": [
    { "id": "prow.0", "landmark": "prow", "ordinal": 0, "anchor": "centerline", "side": "center", "sRange": [0.88, 1.0], "forwardMode": "prow", "normalConeDeg": 20, "clearanceM": 18.0, "tags": ["structural"] },
    { "id": "bridge.0", "landmark": "bridge", "ordinal": 0, "anchor": "surface", "side": "center", "sRange": [0.52, 0.68], "normalConeDeg": 30, "offsetM": 0.4, "forwardMode": "prow", "clearanceM": 22.0, "tags": ["command"] },
    { "id": "hangar.0", "landmark": "hangar", "ordinal": 0, "anchor": "bulkhead", "side": "port", "sRange": [0.30, 0.44], "forwardMode": "outward", "clearanceM": 28.0, "tags": ["launch"] },
    { "id": "hangar.1", "landmark": "hangar", "ordinal": 1, "anchor": "bulkhead", "side": "starboard", "sRange": [0.30, 0.44], "forwardMode": "outward", "clearanceM": 28.0, "tags": ["launch"] },
    { "id": "gun_deck.0", "landmark": "gun_deck", "ordinal": 0, "anchor": "surface", "side": "port", "sRange": [0.20, 0.36], "normalConeDeg": 25, "offsetM": 0.2, "forwardMode": "outward", "clearanceM": 14.0, "tags": ["weapon"] },
    { "id": "gun_deck.1", "landmark": "gun_deck", "ordinal": 1, "anchor": "surface", "side": "starboard", "sRange": [0.20, 0.36], "normalConeDeg": 25, "offsetM": 0.2, "forwardMode": "outward", "clearanceM": 14.0, "tags": ["weapon"] },
    { "id": "gun_deck.2", "landmark": "gun_deck", "ordinal": 2, "anchor": "surface", "side": "port", "sRange": [0.58, 0.72], "normalConeDeg": 25, "offsetM": 0.2, "forwardMode": "outward", "clearanceM": 14.0, "tags": ["weapon"] },
    { "id": "gun_deck.3", "landmark": "gun_deck", "ordinal": 3, "anchor": "surface", "side": "starboard", "sRange": [0.58, 0.72], "normalConeDeg": 25, "offsetM": 0.2, "forwardMode": "outward", "clearanceM": 14.0, "tags": ["weapon"] },
    { "id": "engine.0", "landmark": "engine", "ordinal": 0, "anchor": "bulkhead", "side": "center", "sRange": [0.0, 0.10], "forwardMode": "aft", "clearanceM": 30.0, "tags": ["propulsion"] },
    { "id": "engine.1", "landmark": "engine", "ordinal": 1, "anchor": "bulkhead", "side": "port", "sRange": [0.0, 0.10], "forwardMode": "aft", "clearanceM": 24.0, "tags": ["propulsion"] },
    { "id": "engine.2", "landmark": "engine", "ordinal": 2, "anchor": "bulkhead", "side": "starboard", "sRange": [0.0, 0.10], "forwardMode": "aft", "clearanceM": 24.0, "tags": ["propulsion"] },
    { "id": "spire_aft.0", "landmark": "spire_aft", "ordinal": 0, "anchor": "surface", "side": "center", "sRange": [0.08, 0.22], "normalConeDeg": 35, "offsetM": 0.3, "forwardMode": "prow", "clearanceM": 16.0, "tags": ["silhouette", "voidsworn"] },
    { "id": "spire_aft.1", "landmark": "spire_aft", "ordinal": 1, "anchor": "surface", "side": "port", "sRange": [0.12, 0.26], "normalConeDeg": 35, "offsetM": 0.3, "forwardMode": "prow", "clearanceM": 12.0, "tags": ["silhouette", "voidsworn"] },
    { "id": "spire_aft.2", "landmark": "spire_aft", "ordinal": 2, "anchor": "surface", "side": "starboard", "sRange": [0.12, 0.26], "normalConeDeg": 35, "offsetM": 0.3, "forwardMode": "prow", "clearanceM": 12.0, "tags": ["silhouette", "voidsworn"] }
  ],
  "modules": [
    { "moduleId": "voidsworn.prow.ram.v1", "socketRef": "prow.0", "scale": 1.0, "mirror": "forbid", "priority": 10, "budgetOptional": false, "tags": ["structural"] },
    { "moduleId": "voidsworn.bridge.keep.v1", "socketRef": "bridge.0", "scale": 1.0, "mirror": "forbid", "priority": 20, "budgetOptional": false, "tags": ["command", "silhouette"] },
    { "moduleId": "voidsworn.hangar.mouth.v1", "socketRef": "hangar.0", "scale": 1.0, "mirror": "force", "priority": 30, "budgetOptional": false, "tags": ["launch"] },
    { "moduleId": "voidsworn.hangar.mouth.v1", "socketRef": "hangar.1", "scale": 1.0, "mirror": "force", "priority": 30, "budgetOptional": false, "tags": ["launch"] },
    { "moduleId": "voidsworn.gun.broadside.v1", "socketRef": "gun_deck.0", "scale": 1.0, "mirror": "force", "priority": 40, "budgetOptional": true, "tags": ["weapon"] },
    { "moduleId": "voidsworn.gun.broadside.v1", "socketRef": "gun_deck.1", "scale": 1.0, "mirror": "force", "priority": 40, "budgetOptional": true, "tags": ["weapon"] },
    { "moduleId": "voidsworn.gun.broadside.v1", "socketRef": "gun_deck.2", "scale": 1.0, "mirror": "force", "priority": 41, "budgetOptional": true, "tags": ["weapon"] },
    { "moduleId": "voidsworn.gun.broadside.v1", "socketRef": "gun_deck.3", "scale": 1.0, "mirror": "force", "priority": 41, "budgetOptional": true, "tags": ["weapon"] },
    { "moduleId": "voidsworn.engine.gothic.v1", "socketRef": "engine.0", "scale": 1.0, "mirror": "forbid", "priority": 50, "budgetOptional": false, "tags": ["propulsion"] },
    { "moduleId": "voidsworn.engine.gothic.v1", "socketRef": "engine.1", "scale": 0.85, "mirror": "force", "priority": 51, "budgetOptional": false, "tags": ["propulsion"] },
    { "moduleId": "voidsworn.engine.gothic.v1", "socketRef": "engine.2", "scale": 0.85, "mirror": "force", "priority": 51, "budgetOptional": false, "tags": ["propulsion"] },
    { "moduleId": "voidsworn.spire.aft.v1", "socketRef": "spire_aft.0", "scale": 1.0, "mirror": "forbid", "priority": 60, "budgetOptional": true, "tags": ["silhouette", "voidsworn"] },
    { "moduleId": "voidsworn.spire.aft.v1", "socketRef": "spire_aft.1", "scale": 0.8, "mirror": "force", "priority": 61, "budgetOptional": true, "tags": ["silhouette", "voidsworn"] },
    { "moduleId": "voidsworn.spire.aft.v1", "socketRef": "spire_aft.2", "scale": 0.8, "mirror": "force", "priority": 61, "budgetOptional": true, "tags": ["silhouette", "voidsworn"] },
    { "moduleId": "common.shield.emitter.v1", "socketRef": "bridge.0", "scale": 1.0, "mirror": "forbid", "priority": 70, "budgetOptional": false, "tags": ["shieldEmitter", "shield"] }
  ],
  "paint": {
    "channels": { "hull": "hull", "dark": "dark", "trim": "trim", "glow": "glow" },
    "twoTone": true,
    "gainPolicy": "measured-v1",
    "shieldMaskTag": "shieldEmitter"
  },
  "budgets": {
    "classCeilingRef": "desktop.capital.1",
    "declaredKitTriangles": 18400,
    "declaredKitTextureKB": 6144,
    "allowOptionalDrop": false
  },
  "acceptance": {
    "plateId": "plates/voidsworn/basilica_home.png",
    "silhouetteSheetId": "sheets/voidsworn/hero_grid.png"
  },
  "provenance": {
    "author": "kit-authoring",
    "date": "2026-10-24",
    "packFingerprint": "voidsworn@sha256:REPLACED_AT_BUILD",
    "builderVersion": "kit-builder/1.0.0"
  }
}

What the example demonstrates: a hero capital manifest with a bound existing mesh by registry key, six station overrides that refine but do not regenerate the hull, fifteen socket requests across the five required landmarks plus Voidsworn's aft spires, fifteen module placements including mirrored pairs, a shield emitter as the only cyan-legal module, no colour literals, a class ceiling reference rather than a self-granted budget, and acceptance hooks. The coordinates are schema illustrations, not asset measurements.

### 1.8 Resolved manifest (build output, not authored)

The build emits a companion manifest.resolved.json with the same id plus:

{
  "resolved": {
    "meshHash": "<sha256 of bound mesh>",
    "packFingerprint": "<sha256 of pack>",
    "placerVersion": "placer/1.0.0",
    "sockets": [
      {
        "id": "bridge.0",
        "landmark": "bridge",
        "p": [0.0, 21.4, 18.2],
        "q": [0.0, 0.0, 0.0, 1.0],
        "scale": 1.0,
        "normal": [0.0, 0.97, 0.24],
        "anchorHit": "guide-surface",
        "clearanceM": 22.0
      }
    ],
    "budgetReport": {
      "baseTriangles": 0,
      "kitTriangles": 0,
      "totalTriangles": 0,
      "ceilingTriangles": 0,
      "textureKB": 0,
      "ceilingTextureKB": 0,
      "status": "pending-measurement"
    }
  }
}

The zeroes are placeholders until the measurement pass populates them. The authoring schema cannot express these resolved transforms, which is the point.

## SPECIFICATION 2 - LOFT INTERPOLATION SCHEME RECOMMENDATION

### 2.1 Role of loft v2 in this kit

The kit proposal calls this "Section loft v2 (replaces corner-cut sanding)" - OBSERVED (kit) - and says "the loft interpolates stations with smooth curves and computes true normals" - OBSERVED (kit). The brief constrains the role: "loft v2's role here is dressing and refinement of existing meshes, not generating hull shapes from scratch" - OBSERVED (brief).

Therefore loft v2 has two outputs:

1. A guide surface used internally for socket projection, trim-band conformity, and station-override evaluation. It is not shipped as the hull.
2. Dressing geometry - trim bands, bevel strips, rib overlays, panel seams - lofted along the guide surface and merged with the existing mesh.

The existing hull mesh remains the silhouette source. Loft v2 may refine surface framing for dressing; it may not replace the hull. INFERRED: if the guide surface deviates from the bound mesh beyond the dress tolerance in 1.5.7, the build must fail rather than "improve" the hull.

### 2.2 Data model

A station is:

Station {
  s: number in [0,1]           // longitudinal parameter, 0 aft, 1 fore
  center: Vec3                 // ship-local position of section centroid at this s
  width: number                // half-beam in X
  thickness: number            // half-height in Y
  verticalOffset: number       // centroid Y offset from datum
  sectionFamily: Family        // round | gothic_arch | wedge | slab | rib | bio
  familyParams: number[]       // family-specific, normalized
  bevelM: number               // explicit per-station bevel, 0 = hard edge
  hard: boolean                // C0 crease station
  upHint: Vec3                 // optional roll reference
}

The family parameter vectors are:

| Family | Parameters (normalized unless noted) | Section character |
|---|---|---|
| round | exponent (superellipse n, 2 = ellipse, >2 = boxier) | Smooth closed convex curve. |
| gothic_arch | apexHeight, shoulderHeight, baseWidth, pointSharpness | Two arcs meeting at a pointed apex; flat or slightly curved bottom. |
| wedge | apexX, chineHeight, deckFlat | Triangular plan with a chine; one clean edge per side. |
| slab | cornerRadius, sideTaper, deckCamber | Rounded rectangle; industrial. |
| rib | ribCount, ribDepth, gapRatio, coreScale | Segmented arcs over a dark core; open rib cage. |
| bio | lobeCount, lobeAsymmetry, ringPhase, ringDepth | Smooth asymmetric lobes with growth-ring segmentation. |

OBSERVED (kit): the pack list uses these exact family names: "round, gothic arch, wedge, slab, rib, bio" - OBSERVED (kit). The parameter names above are PROPOSED design parameters, not asset facts.

### 2.3 Recommendation

Recommendation: a hybrid of centripetal Catmull-Rom for the station sweep and monotone cubic Hermite (PCHIP) for scalar profile curves, with explicit hard-station tangent splitting and feature-anchored arc-length resampling for section correspondence.

This is not a single global spline. It is a small, explicit scheme with one rule per data type:

1. Station centers (center): centripetal Catmull-Rom, alpha = 0.5, interpolating.
2. Scalar profiles (width, thickness, verticalOffset, bevelM): monotone cubic Hermite (PCHIP) in s, clamped to the pack envelope.
3. Family shape parameters: Catmull-Rom on the parameter vector within a family, clamped to the family's legal domain; no interpolation across families except at a declared transition station.
4. Section correspondence: feature-anchored arc-length resampling to a fixed vertex count per class.
5. Normals: analytic per-section normal, frame-transported along the loft, split at hard stations.

2.3.1 Why centripetal Catmull-Rom

- It interpolates authored stations exactly. A B-spline approximates; a station's authored width would not appear in the result. For dressing an existing mesh, station overrides are measurements or refinements that must be honored. Interpolation is the correct semantic.
- Centripetal parameterization (alpha = 0.5) avoids the cusps, loops, and self-intersections that uniform Catmull-Rom produces when station spacing is uneven. AI meshes and hand-authored overrides will have uneven spacing.
- It is local: moving one station changes only adjacent segments. That makes manifest diffs predictable and keeps a variant from reflowing the whole hull.
- It has a simple analytic derivative, which supports true normals and tangent frames without finite-difference noise.
OBSERVED (kit): the current loft uses corner cutting: "Corner cutting survives only as an explicit per-station bevel parameter, never as a global smoothing pass" - OBSERVED (kit). Catmull-Rom plus explicit hard stations is the direct replacement for global corner cutting: smoothness is the default, creases are authored.

2.3.2 Why PCHIP for scalar profiles

Width and thickness are positive, bounded quantities. Catmull-Rom can overshoot on a sharp change, producing a bulge wider than any authored station. PCHIP is monotone-preserving between local extrema and does not overshoot. It gives C1 continuity with no ringing. For a hull whose class envelope is a hard budget, overshoot is not a cosmetic issue; it can breach the silhouette envelope or the collision proxy.

PCHIP's trade-off is lower curvature smoothness (it is C1, not C2). For width and thickness that is acceptable: the eye reads the section shape, not the second derivative of beam. For the centerline path, where curvature continuity matters more, Catmull-Rom is used.

2.3.3 Why not cubic B-spline

A cubic B-spline is smooth and well-behaved, but it does not pass through its control stations. To make it pass through authored stations one must solve for control points, and the resulting curve still shrinks toward the control polygon. For a gothic arch or a wedge, that shrinkage softens exactly the edge the pack wants. The kit proposal's acceptance test demands "hard deliberate edges where the grammar wants them" - OBSERVED (kit). B-spline is the wrong default for that requirement; it remains a possible choice for a pack that explicitly wants a soft, non-interpolating profile, but no current pack does.

2.3.4 Why not a single global Catmull-Rom for everything

Because scalar profiles need overshoot protection and section families need domain clamping. A single spline type would either allow width overshoot or force the centerline path to be monotone when it should be free. The hybrid is deliberately two schemes with a clear boundary.

### 2.4 Section families and correspondence

2.4.1 Family evaluation

Each family is a closed parametric curve in the station's local X-Y plane, evaluated at parameter t in [0,1) with a defined feature set. For example, gothic_arch has feature points at keel (t = 0), port base (t = 0.15), port shoulder (t = 0.30), apex (t = 0.50), starboard shoulder (t = 0.70), starboard base (t = 0.85), and back to keel. wedge has keel, port chine, port deck edge, apex/deck center, starboard deck edge, starboard chine. rib has rib roots and rib tips, with gaps as explicit feature intervals. bio has lobe peaks and valleys.

Feature-anchored resampling: every family exposes a named feature list with normalized arc-length positions. To loft between two stations of the same family, the scheme resamples each feature interval to a fixed number of vertices, so feature k at station A corresponds to feature k at station B. This prevents the vertex sliding and twisting that plain uniform arc-length resampling produces when a gothic apex shifts relative to a shoulder.

PROPOSED vertex counts per section, by size class:

| Class | Section vertices | Ring count guidance |
|---|---|---|
| light | 32 | 12-24 |
| line | 48 | 16-32 |
| heavy | 64 | 20-40 |
| capital | 96 | 24-48 |

These are design budgets, not asset facts. They must be reconciled with the class triangle ceilings in Specification 4.

2.4.2 Family changes

A section family change is legal only at a hard: true station and only with a transition ring. The transition ring is generated by resampling both families to the common feature count and blending their positions with a monotone weight over one station interval. PROPOSED limits:

- At most one family change per continuous run of ten stations.
- At most three family changes per hull.
- A family change may not occur within 10% of the prow or stern cap.
- rib to any non-rib family requires a hard station and a core-scale transition; rib is structurally segmented and cannot blend smoothly into bio.
INFERRED: these limits are not in the granted documents; they are proposed to keep the guide surface from becoming a hull-generation tool by another name. They may be relaxed per pack with sign-off.

### 2.5 Station-to-station continuity rules

The following rules are normative for loft v2 in dressing mode.

2.5.1 Default continuity is G1. Along a smooth run, the guide surface tangent is continuous to within PROPOSED 2 degrees between adjacent segments. Curvature need not be continuous (PCHIP is C1, not C2), but tangent direction must be.

2.5.2 Hard stations are G0 and split normals. At a hard: true station, the loft uses two one-sided tangents and duplicates the ring's vertices for normal generation. The surface is C0 there. The resulting crease is deliberate. This is the only legal way to get a hard edge; there is no global smoothing pass.

2.5.3 Bevel is explicit and local. bevelM is a per-station scalar that chamfers the station ring. It is C0-continuous and monotone within a run: a bevel may grow or shrink but may not oscillate without an intervening station. A global bevel is not a legal parameter. OBSERVED (kit): "Corner cutting survives only as an explicit per-station bevel parameter, never as a global smoothing pass" - OBSERVED (kit).

2.5.4 Station spacing ratio. Adjacent station spacing ratio must lie in PROPOSED [0.35, 2.85]. Centripetal parameterization tolerates more, but this bound keeps the guide surface's sampling density reasonable for socket projection.

2.5.5 No unstationed inflection. A sign change in the second difference of width or thickness must have a station within PROPOSED 0.05 in s. A hull may not "just happen" to bulge between authored stations.

2.5.6 Curvature radius floor. The local curvature radius of the centerline path must be at least PROPOSED 0.5 x local thickness. Tighter curvature produces self-intersection at the section ring and is a build failure.

2.5.7 Positivity and envelope. width > 0, thickness > 0, and every sampled section must lie within the pack's declared silhouette envelope for the size class. A negative or zero dimension is a schema-invalid station; an envelope breach is a validator failure.

2.5.8 End conditions. The first and last stations use natural end conditions (zero second derivative for the centerline; zero slope for PCHIP profiles) unless the pack declares a cap tangent. Prow and stern caps are pack-defined: Voidsworn uses a pointed gothic cap; Hegemony uses a wedge cap; Chorus uses a rounded bio cap. A cap is a station family evaluation at the extremity, not a separate mesh primitive.

2.5.9 Roll reference. Each station carries an optional upHint. If absent, the loft uses parallel transport of the previous station's up vector, with a fallback to world +Y at the first station. A roll discontinuity greater than PROPOSED 10 degrees between adjacent stations requires a hard station. This prevents the guide surface from twisting under a module socket.

2.5.10 No self-intersection. The build samples the guide surface at PROPOSED twice the section vertex count and checks adjacent rings for inverted quads, zero-area triangles, and ring crossings. Any hit is a build failure with the station index and s value.

### 2.6 True normals

The kit proposal says the loft "computes true normals" - OBSERVED (kit). The scheme computes them as follows:

1. For each station, evaluate the section curve and its analytic derivative in the station plane.
2. Compute the loft tangent along s from the analytic derivative of the Catmull-Rom centerline and the PCHIP profile derivatives.
3. The surface normal at a section vertex is normalize(cross(loftTangent, sectionTangent)), oriented outward using the section's winding.
4. Accumulate normals per vertex using angle-weighted averaging within a smooth run. Angle weighting is chosen over area weighting because section rings have uneven segment lengths near sharp features; angle weighting is stable there.
5. At hard stations, do not average across the crease. Duplicate the ring, assign one-sided normals, and mark the edge as a crease in the generated dressing mesh.
6. Weld vertices only within a smooth run; never weld across a hard station.

PROPOSED normal smoothing angle threshold: 60 degrees. Edges with a dihedral angle above 60 degrees are treated as creases even if not marked hard, because the geometry has effectively become hard. This is a safety net, not a substitute for authoring hard stations.

### 2.7 Dressing-mode constraints

- The guide surface is evaluated in ship-local coordinates, not re-centered.
- Socket projection uses the guide surface's closest-point query; the hit must be within PROPOSED 0.5% of beam of the bound mesh surface, or the placer falls back to the mesh's own BVH and flags a guide-surface mismatch.
- Trim bands are lofted as offsets of the guide surface by offsetM and clipped to the hull's existing UV islands where possible. INFERRED: the existing AI meshes' UV layout is not specified; if they lack usable UVs, trim bands must be generated as separate geometry with their own UVs, which increases the kit texture budget.
- No loft v2 output may replace the bound hull mesh in the VSM. The VSM conversion step merges dressing geometry with the existing hull; it does not swap the hull for the guide surface.
- If the guide surface cannot be fitted within dress tolerance, the manifest's station overrides are reduced or removed; the build does not widen tolerance to make the fit pass.

## SPECIFICATION 3 - VALIDATOR DESIGN

### 3.1 Objective

The kit proposal states the target: "A new hull that violates its pack should be impossible to express, not merely discouraged" - OBSERVED (kit). The brief adds: "A parameter set alone does not satisfy this; describe the constraint mechanism" - OBSERVED (brief).

The validator is therefore not a checklist run after authoring. It is a grammar-pack compiler plus a generated authoring API plus a fail-closed build gate. The primary mechanism is representational: forbidden states have no type, no schema branch, and no builder method. The secondary mechanism is geometric: continuous constraints that cannot be enumerated in a type are checked by the placer and the build, and they fail rather than clamp.

### 3.2 Constraint mechanism: four layers

Layer 0 - Grammar pack as source of truth

Each faction pack is a machine-readable record:

{
  "packId": "voidsworn",
  "version": "1.0.0",
  "sectionFamilies": ["gothic_arch"],
  "symmetry": "bilateral",
  "landmarks": {
    "prow":     { "min": 1, "max": 1, "anchors": ["centerline"] },
    "bridge":   { "min": 1, "max": 1, "anchors": ["surface", "centerline"] },
    "hangar":   { "min": 1, "max": 2, "anchors": ["bulkhead"] },
    "gun_deck": { "min": 2, "max": 12, "anchors": ["surface"] },
    "engine":   { "min": 1, "max": 6, "anchors": ["bulkhead"] },
    "spire_aft":{ "min": 0, "max": 6, "anchors": ["surface"] }
  },
  "modules": {
    "voidsworn.prow.ram.v1": {
      "landmarks": ["prow"],
      "classes": ["heavy", "capital"],
      "mirrorSafe": false,
      "trianglesAtUnitScale": 1200,
      "textureKBAtUnitScale": 512,
      "requiresTraits": []
    },
    "voidsworn.bridge.keep.v1": {
      "landmarks": ["bridge"],
      "classes": ["line", "heavy", "capital"],
      "mirrorSafe": false,
      "trianglesAtUnitScale": 2400,
      "textureKBAtUnitScale": 1024,
      "requiresTraits": ["command"]
    },
    "voidsworn.spire.aft.v1": {
      "landmarks": ["spire_aft"],
      "classes": ["heavy", "capital"],
      "mirrorSafe": true,
      "trianglesAtUnitScale": 800,
      "textureKBAtUnitScale": 256,
      "requiresTraits": ["silhouette"]
    }
  },
  "paint": {
    "requiredChannels": ["hull", "trim"],
    "optionalChannels": ["dark", "glow"],
    "shieldTag": "shieldEmitter"
  },
  "budgets": {
    "classCeilingRefs": {
      "light": "desktop.light.1",
      "line": "desktop.line.1",
      "heavy": "desktop.heavy.1",
      "capital": "desktop.capital.1"
    }
  }
}

The pack is the only place where allowed modules, landmarks, families, symmetry, and class compatibility are declared. INFERRED: this is how the kit proposal's six one-line pack descriptions become enforceable rather than documentary. For example, Corsairs' "asymmetry enforced by seed: no mirrored feature placement" - OBSERVED (kit) - becomes "symmetry": "asymmetric-seeded"; a Corsair manifest with mirror: "force" has no legal schema branch.

Layer 1 - Pack compiler emits a closed schema and a typed builder

The pack compiler runs whenever a pack file changes. It emits:

1. packs/<pack>/schema.json - a JSON Schema 2020-12 document derived from the base manifest schema, with:
   - factionPack narrowed to a const of the pack ID.
   - sectionFamily narrowed to the pack's sectionFamilies enum.
   - moduleId narrowed to the pack's module keys plus shared modules explicitly allowed.
   - landmark narrowed to the pack's landmark keys.
   - if/then rules for class compatibility: a module absent from a class's allowlist is not a legal moduleId for that class.
   - dependentSchemas for symmetry: asymmetric-seeded makes mirror: "force" a schema violation; centerline-only makes side: "port" a violation.
   - additionalProperties: false everywhere.
2. packs/<pack>/types.ts - TypeScript discriminated unions with literal types. Example shape:

export type VoidswornModuleId =
  | "voidsworn.prow.ram.v1"
  | "voidsworn.bridge.keep.v1"
  | "voidsworn.spire.aft.v1"
  | "common.shield.emitter.v1";

export type VoidswornLandmark =
  | "prow" | "bridge" | "hangar" | "gun_deck" | "engine" | "spire_aft";

export interface VoidswornPack {
  readonly factionPack: "voidsworn";
  readonly symmetry: "bilateral";
  readonly sectionFamilies: readonly ["gothic_arch"];
  readonly modules: Readonly<Record<VoidswornModuleId, ModuleSpec>>;
}

3. packs/<pack>/builder.ts - the only public constructor. It exposes methods whose signatures only accept pack-legal pairs:

place(module: "voidsworn.bridge.keep.v1", socket: "bridge.0"): void; // legal
place(module: "voidsworn.bridge.keep.v1", socket: "gun_deck.0"): never; // no overload

In TypeScript, calling the second overload is a compile error: no overload matches. The builder does not export a raw Manifest interface. The only way to produce a manifest object is to call the builder, and the builder brands its output with a non-serializable symbol so a hand-written JSON object cannot be passed to the build as if it were builder output. INFERRED: this is the strongest practical version of "impossible to express" in a TypeScript/Babylon stack; it moves the failure from review to the compiler.

The build additionally checks a packFingerprint in provenance. A manifest built against an older pack fails with PACK_STALE before any geometry work.

Layer 2 - Placer as sole writer of transforms

The authoring manifest has socketRequests, not sockets. The placer:

- Resolves each request against the bound mesh's guide surface.
- Enforces anchor mode, sRange, side, normalConeDeg, offsetM, forwardMode, mirror, and clearanceM.
- Applies pack symmetry.
- Runs clearance and functional-cone checks.
- Emits manifest.resolved.json.

If a request cannot be resolved, the placer fails with a diagnostic. It does not pick the nearest legal point, because a silent nudge would hide a manifest that cannot be built as authored. INFERRED: the absence of a free transform field in Layer 1 means there is nothing for the author to hand-tune, so the placer's refusal is the only sensible outcome.

Layer 3 - Build-time validator

Runs after packing and placement, before baking and VSM conversion. It is fail-closed: no artifact is written on any error, and a previous artifact is not overwritten.

### 3.3 What is checked

3.3.1 Schema and provenance

| Check | Code | Layer |
|---|---|---|
| Manifest validates against pack schema | SCHEMA_INVALID | Build |
| Manifest was produced by the pack builder (brand present) | BUILDER_PROVENANCE | Build |
| packFingerprint matches current pack | PACK_STALE | Build |
| meshHash matches bound mesh | MESH_STALE | Build |
| schemaVersion supported | SCHEMA_VERSION | Build |

3.3.2 Grammar

| Check | Code |
|---|---|
| Section family is in pack's allowed set | PACK_SECTION_FAMILY |
| Module ID is in pack's module set | PACK_MODULE_UNKNOWN |
| Module is allowed for the manifest's size class | PACK_MODULE_CLASS |
| Module's required traits are present on the hull/manifest | PACK_TRAIT_MISSING |
| Landmark multiplicity within pack min/max | PACK_LANDMARK_COUNT |
| Symmetry policy obeyed (no forced mirror under asymmetric pack; no side under centerline pack) | PACK_SYMMETRY |
| Required landmarks present | PACK_LANDMARK_REQUIRED |
| Station override family matches pack (or is an allowed transition) | PACK_STATION_FAMILY |
| Two-tone channels present | PAINT_TWO_TONE |

3.3.3 Geometry

| Check | Code |
|---|---|
| Socket anchor hit exists | SOCKET_NO_HIT |
| Socket normal within cone | SOCKET_NORMAL_CONE |
| Socket s within requested range | SOCKET_S_RANGE |
| Socket side matches resolved X sign | SOCKET_SIDE |
| Module clearance spheres do not overlap illegally | SOCKET_CLEARANCE |
| Hangar cone clear | CONE_HANGAR |
| Engine exhaust cone clear | CONE_ENGINE |
| Gun deck arc not occluded beyond threshold | CONE_GUN_ARC |
| Prow cone clear | CONE_PROW |
| Guide-surface deviation within dress tolerance | DRESS_TOLERANCE |
| No self-intersection / inverted quads / zero-area triangles | LOFT_TOPOLOGY |
| Normals unit length and outward | NORMAL_INVALID |
| No NaN or infinite positions | GEOM_NAN |
| Base mesh vertices unchanged | HULL_MUTATED |

3.3.4 Budget

| Check | Code |
|---|---|
| Base + kit triangles <= class ceiling | BUDGET_TRIANGLES |
| Base + kit vertices <= class ceiling | BUDGET_VERTICES |
| Texture KB <= class ceiling | BUDGET_TEXTURE |
| Manifest declared budget matches measured within 2% | BUDGET_DECLARATION_DRIFT |
| Base mesh alone exceeds ceiling | BUDGET_BASE_EXCEEDS |
| VSM tier metadata includes lazy-load/eviction flags if required | BUDGET_STREAMING_META |

The kit proposal's gate is explicit: "a hull that exceeds its class budget fails the build, loudly, before it reaches a device" - OBSERVED (kit).

3.3.5 Paint and colour law

| Check | Code |
|---|---|
| No colour literals in manifest | PAINT_COLOUR_LITERAL |
| FAC3D resolves every declared channel | PAINT_CHANNEL_MISSING |
| Gain policy file present and hash-matched | PAINT_GAIN_MISSING |
| Cyan-family hue only on shieldEmitter-tagged texels/modules | PAINT_CYAN_RESERVED |
| Emissive path contains no additive fudge | PAINT_EMISSIVE_FUDGE |
| Two-tone minimum satisfied in baked texels, not just manifest | PAINT_TEXEL_TWO_TONE |

OBSERVED (brief): "cyan means shields, nothing else is cyan" - OBSERVED (brief). The validator samples the baked albedo/emissive atlas and converts to OKLCH; PROPOSED cyan band is hue 180-210 degrees with chroma > 0.08. Any texel in that band without a shield tag fails. This is a hard gate, not a warning.

3.3.6 VSM conversion and load metadata

| Check | Code |
|---|---|
| .vsm header valid and version supported | VSM_HEADER |
| _kit.json present and consistent with resolved manifest | KIT_JSON_MISMATCH |
| Mesh hash in _kit.json matches .vsm payload | KIT_JSON_HASH |
| Triangle count in header matches measured | VSM_TRI_COUNT |
| Normals encoded in supported format | VSM_NORMAL_FORMAT |
| LOD/eviction metadata present | VSM_LOD_META |
| No unbounded boot load flag for a hull beyond budget | VSM_LOAD_POLICY |

OBSERVED (kit): the load risk is stated: "roughly 252 MB of geometry across 36 hulls" and "about 1.32 GB of texture memory" - OBSERVED (kit). The kit must ship with budgets, and the proposal says "lazy loading or eviction for off-screen factions" may apply - OBSERVED (kit). The validator checks that the metadata needed for that policy exists.

### 3.4 When it runs

The validator runs at build time, in four stages:

1. Pack compile - when a faction pack changes. Emits schema, types, builder. Failure is a pack authoring error; no manifests can be built against the pack until it passes.
2. Authoring typecheck / precommit - when a manifest author runs the local build or commits. TypeScript rejects illegal module/landmark pairs; schema validation rejects illegal JSON. This is the earliest and cheapest failure.
3. Asset build - after mesh binding, measurement, placement, and baking. Runs the full check table. This is the gate that produces or refuses the .vsm and _kit.json.
4. Final artifact validation - after VSM write, re-reads the written files and re-checks header, hashes, counts, and _kit.json parity. Fail-closed: if this stage fails, the artifact is deleted and the build is marked failed.

INFERRED: runtime validation is not the primary mechanism. A runtime check can log a violation but cannot make it unexpressible; build time is where the gate belongs. A lightweight load-time assertion may remain as a tripwire, but it is not the design.

### 3.5 What a violation looks like

A violation is a structured diagnostic, not a stack trace. Every diagnostic has:

{
  "severity": "error",
  "code": "PACK_SYMMETRY",
  "manifestId": "voidsworn.basilica.hero",
  "pack": "voidsworn@1.0.0",
  "path": "/modules/12/mirror",
  "rule": "voidsworn.symmetry.bilateral.forbid-mirror",
  "message": "Voidsworn pack is bilateral; mirror:'forbid' is not a legal value for a non-centerline socket.",
  "expected": "\"inherit\" or \"force\"",
  "actual": "\"forbid\"",
  "remediation": "Remove the mirror override or place the module on a centerline socket.",
  "docs": "docs/kit/packs/voidsworn#symmetry",
  "buildId": "kit-2026-10-24T18-22-01Z-7f3a"
}

Three violation classes:

- Class A - unrepresentable. The author cannot write it: TypeScript has no overload, or the pack schema has no enum member. The coder sees a compiler error or a schema error at authoring time. Example: place("voidsworn.bridge.keep.v1", "gun_deck.0") -> TS2769: No overload matches this call.
- Class B - representable but geometrically illegal. The manifest is type-legal, but the placer or build cannot satisfy a continuous constraint (clearance, cone, dress tolerance). The coder sees a diagnostic JSON plus a human-readable summary. Example: CONE_HANGAR.
- Class C - budget. The manifest is legal and geometrically valid, but the measured cost exceeds the class ceiling. The coder sees a cost breakdown and a remediation list. Example: BUDGET_TRIANGLES.

Class A is the design's primary answer to "impossible to express." Classes B and C exist because continuous geometry and measured cost cannot be fully enumerated in a type; they are made fail-closed rather than advisory.

### 3.6 Failure output the coder gets

On failure, the build prints a banner and writes a report. The banner is deliberately loud:

================================================================
KIT BUILD FAILED - 3 errors, 1 warning
manifest: voidsworn.basilica.hero
pack:     voidsworn@1.0.0
build:    kit-2026-10-24T18-22-01Z-7f3a
artifact: NOT WRITTEN (previous artifact preserved)
================================================================
[E] BUDGET_TRIANGLES  /budgets/declaredKitTriangles
    base 38,000 + kit 18,400 = 56,400 > ceiling 52,000 (desktop.capital.1)
    remediation: remove budgetOptional modules in priority order:
      - voidsworn.spire.aft.v1 @ spire_aft.1 (1,200 tri)
      - voidsworn.spire.aft.v1 @ spire_aft.2 (1,200 tri)
      - voidsworn.gun.broadside.v1 @ gun_deck.2 (900 tri)
    note: base mesh alone is under ceiling; kit must fit the remainder.

[E] PAINT_CYAN_RESERVED  /paint/channels/glow
    cyan-family texels found on module voidsworn.engine.gothic.v1
    (hue 188.4 degrees, chroma 0.14) without tag "shieldEmitter".
    remediation: move the glow to a non-cyan FAC3D channel or tag the
    module as a shield emitter. Cyan is reserved for shields.

[E] SOCKET_CLEARANCE  /modules/9
    voidsworn.engine.gothic.v1 @ engine.1 clearance 24.0 m overlaps
    voidsworn.spire.aft.v1 @ spire_aft.1 clearance 12.0 m by 2.7 m.
    remediation: move spire_aft.1 forward (sRange min 0.18) or reduce
    engine.1 scale to 0.75.

[W] BUDGET_DECLARATION_DRIFT  /budgets/declaredKitTextureKB
    declared 6144 KB, measured 6402 KB (4.2% over declaration, under ceiling).
================================================================
Full report: build/reports/kit-2026-10-24T18-22-01Z-7f3a.json
Exit code: 3 (budget)
================================================================

Exit codes: 0 success, 2 validation error, 3 budget error, 4 pack compile error, 5 VSM/artifact error. CI treats any nonzero as failure. The previous artifact is preserved, so a failed build cannot ship a half-dressed hull.

### 3.7 Why this satisfies "impossible to express"

A parameter set alone would let an author write "mirror": "force" under an asymmetric pack and rely on a validator to reject it. That is discouraged, not impossible. This design removes the field's illegal value from the pack schema, removes the builder overload that would accept it, removes the raw transform field entirely, and makes the placer the only writer of positions. The remaining checks cover continuous geometry that no finite type can enumerate; those are fail-closed and produce diagnostics rather than silent fixes. The combination is the constraint mechanism: the authoring surface is generated from the grammar, and the build refuses anything the grammar cannot place.

## SPECIFICATION 4 - PAINT-GAIN APPROACH

### 4.1 Objective and existing state

The kit proposal requires "one gain across hull and kit texels, the 0.3 emissive fudge in aiKitMat deleted" - OBSERVED (kit). The brief restates it: "One gain across hull and kit texels, replacing the 0.3 emissive fudge in aiKitMat." The colour authority is "FAC3D is the single colour source" - OBSERVED (brief). The colour law is "cyan means shields, nothing else is cyan" - OBSERVED (brief).

The gain is a light-transfer normalization, not a colour grade. It compensates for the difference between the FAC3D source values and what the material graph plus lighting rig actually delivers to the framebuffer, so that hull texels and kit texels land on the same response curve. It is applied once, globally, to both sets. It is not a per-faction tint, not a per-hull exposure, and not a per-material fudge.

INFERRED: the existing aiKitMat emissive fudge is a constant additive term that hides a mismatch between kit and hull response. Deleting it without a replacement would make kit modules darker than hulls; replacing it with a per-material constant would recreate the same divergence in a new place. A single measured gain is the correct replacement.

### 4.2 Gain model

Let:

- L_material(texel) = linear luminance after FAC3D channel lookup, HullFx roughness/wear modulation, and the standard battle lighting rig, excluding the 0.3 emissive add.
- L_target(texel) = linear luminance of the FAC3D source swatch under the same rig at reference exposure, i.e. the value the art direction intends.
- g = one scalar gain for the build.

The gain is applied in linear space:

albedo_out = FAC3D.channel(texel) * g
emissive_out = FAC3D.glow(texel) * g * shieldMask(texel)

No additive term. No per-channel multiplier. No hue rotation. The scalar preserves hue and chroma ratios; it changes only magnitude. This is what makes it compatible with the cyan law: a non-cyan texel cannot become cyan through scalar multiplication, and a cyan texel cannot lose its cyan identity through scalar multiplication. Hue checks are still run because texture filtering and compression can shift hue slightly; the validator catches that.

### 4.3 How the gain value is derived

Recommendation: measured, robust least-squares, global, with a fixed fallback and a hard residual gate.

4.3.1 Measurement rig

A calibration scene is built once per lighting-rig version. It contains:

- A FAC3D palette chart: every channel (hull, dark, trim, glow) sampled across its declared value range, at the same bit depth and compression as the game atlas.
- Two material paths: the hull path and the kit path, with the 0.3 emissive add removed from aiKitMat.
- The standard battle lighting rig: same lights, same tone mapping, same exposure as a 20-ship battle. The brief says "target battle size around 20 ships" - OBSERVED (brief).
- A render target readback in linear space before tone mapping, plus a post-tone-mapping readback for sanity.

4.3.2 Solve

For all sampled texels i in both hull and kit sets:

g = argmin_g sum w_i (g * L_material_i - L_target_i)^2

Closed form:

g = sum w_i L_material_i L_target_i / sum w_i L_material_i^2

Weights w_i are PROPOSED robust Huber weights with a tuning constant of 1.345, computed in one reweighting pass. This prevents a small number of specular or glow outliers from dragging the gain.

PROPOSED clamp: g in [0.75, 1.25]. A gain outside that range means the material graph or the lighting rig is wrong, not that the gain should be larger. In that case the calibration fails and the fix is in the material graph, not the gain.

PROPOSED residual gate: weighted RMS relative error after gain must be <= 3%. Above 3%, calibration fails with PAINT_GAIN_RESIDUAL. The gain file is not written, and no hull can build with gainPolicy: "measured-v1". A hull may fall back to gainPolicy: "fixed-1.0" only with an explicit manifest change and a warning in the build report; INFERRED: shipping with the fallback is a temporary state, not a silent default.

4.3.3 Storage and application

The gain is stored in paint_gain.json:

{
  "version": "measured-v1",
  "lightingRigHash": "sha256:...",
  "fac3dHash": "sha256:...",
  "gain": 1.0625,
  "gainEncoded": 272,
  "residualRms": 0.018,
  "sampleCount": 4096,
  "clamp": [0.75, 1.25],
  "created": "2026-10-24",
  "status": "calibrated"
}

gainEncoded is the 8-bit fixed-point value used by the shader (round(g * 256)), so the CPU and GPU agree. The shader receives one uniform, uPaintGain, and applies it in linear space. The gain file is hash-referenced by the manifest's paint.gainPolicy; a mismatch is PAINT_GAIN_MISSING.

4.3.4 Why measured rather than fixed

A fixed gain of 1.0 is only correct if the material graph is already unity. The presence of the 0.3 emissive fudge is evidence that it is not - INFERRED from the kit proposal's statement that the fudge exists and should be deleted. A fixed gain chosen by eye would be another fudge. Measurement ties the value to the actual FAC3D chart and lighting rig, and the residual gate makes the result falsifiable: if the fit is bad, the build says so.

4.3.5 Why global rather than per-faction or per-hull

The requirement is "one gain across hull and kit texels" - OBSERVED (kit). A per-faction gain would let one pack drift relative to another and would make the silhouette-sheet acceptance test partly a lighting test. A per-hull gain would reintroduce the per-hull material divergence the kit is trying to retire. The global gain is the discipline: if a hull looks wrong under the global gain, the fix is its FAC3D channel assignment or its module set, not a local exposure.

### 4.4 Emissive path after the fudge is deleted

The 0.3 additive emissive is removed. The emissive contribution becomes:

E = FAC3D.glow * g * shieldMask

where shieldMask is 1.0 on texels/modules tagged shieldEmitter and 0.0 elsewhere. PROPOSED: non-shield glow channels (engine glow, running lights) are allowed only if their hue is outside the cyan band; they use the same g and the same FAC3D glow channel, but they are not called shields. The cyan law is enforced on the baked result, not on the tag alone. The kit proposal says "FAC3D is the single colour source" - OBSERVED (kit) - so the glow channel is a FAC3D channel, not a shader constant.

INFERRED: deleting the fudge may reduce kit brightness on hulls whose FAC3D glow value is low. That is the intended correction; if a hero plate requires more glow, the fix is the FAC3D glow value for that channel, not a return of the additive term. The calibration residual gate will catch a rig that cannot be normalized by one scalar.

### 4.5 Hulls that exceed their class budget

The kit proposal's gate is absolute: "a hull that exceeds its class budget fails the build, loudly, before it reaches a device" - OBSERVED (kit). The validator's budget check is described in 3.3.4. The paint-gain specification adds the texture side and the remediation policy.

4.5.1 Budget components

For each hull:

totalTriangles = baseMeshTriangles + kitModuleTriangles
totalVertices  = baseMeshVertices  + kitModuleVertices
totalTextureKB = hullAtlasKB + kitAtlasKB + decalKB

The class ceiling applies to the totals. The base mesh is measured, not estimated. The kit modules are measured after baking, not taken from the manifest's declaration; the declaration is checked for drift.

OBSERVED (kit): the texture pressure is real: "about 1.32 GB of texture memory" for a 20-ship battle - OBSERVED (kit). PROPOSED per-ship texture budget = (1.32 GB / 20) x 0.8 safety factor = approx 52.8 MB per ship, split PROPOSED 60% hull atlas / 40% kit atlas and decals. This is a derived design budget, not an asset measurement; it must be replaced by the desktop stress test's actual numbers. The kit proposal says "no hull 6 until a fully loaded battle passes on desktop" - OBSERVED (kit) - so the stress test is the authority for the final number.

4.5.2 Failure behavior

When a hull exceeds a ceiling, the build fails with BUDGET_TRIANGLES, BUDGET_VERTICES, or BUDGET_TEXTURE. It does not:

- Decimate the existing hull mesh. The brief says "NOT hull shape generation" - OBSERVED (brief) - and the kit may not alter the bound hull. Decimating an AI hull would change its silhouette and invalidate its acceptance plate.
- Decimate kit modules silently. A silent LOD swap would make the build report lie about what ships.
- Raise the class ceiling. The ceiling is versioned and signed off; a manifest cannot self-grant.
- Drop modules automatically. allowOptionalDrop is const false in the schema. A separate kit budget-fit command may propose a drop list, but the author must apply the diff and rebuild. This keeps the build deterministic and the report honest.

4.5.3 Remediation ladder

The diagnostic lists the cost breakdown and a remediation ladder in this order:

1. Remove budgetOptional modules in descending triangle cost, lowest priority first. The report lists each module, its socket, and its cost.
2. Reduce module scale within the pack's legal range. Scale is not free: the report shows the triangle and texture delta.
3. Downscale the kit atlas to the next power-of-two tier, with a texture-quality warning. This is a manifest-level paint/budget change, not a silent build action.
4. Merge kit modules that share a material and socket neighborhood into a single baked module, if the module library supports a merged variant. INFERRED: this depends on the module library's actual implementation, which is not specified.
5. Escalate to the hull owner if the base mesh alone exceeds the ceiling (BUDGET_BASE_EXCEEDS). The kit cannot fix this; the hull must be re-authored, re-budgeted, or excluded. The kit proposal's queue math - "the 36-hull queue becomes parameter work" - OBSERVED (kit) - assumes the base meshes fit their classes. If one does not, that assumption is false for that hull and must be surfaced, not hidden.
6. Ceiling change with sign-off is the last resort. It requires a new classCeilingRef version, a documented reason, and a re-run of the desktop stress gate. A manifest cannot do it alone.

4.5.4 Texture-specific behavior

If kitAtlasKB alone exceeds its share, the build fails with BUDGET_TEXTURE and the report shows per-module texture cost. The remediation ladder applies; atlas downscale is preferred over module removal because it preserves silhouette. If hullAtlasKB exceeds its share but the total is under ceiling, the build warns (BUDGET_TEXTURE_SHARE) and proceeds; the hard gate is the total.

4.5.5 Relation to streaming and eviction

The kit proposal allows "lazy loading or eviction for off-screen factions" if the desktop stress test demands it - OBSERVED (kit). The budget report therefore includes a streaming block:

{
  "streaming": {
    "factionPack": "voidsworn",
    "loadPolicy": "lazy",
    "evictable": true,
    "estimatedResidentMB": 41.2,
    "estimatedBattleMB": 824.0
  }
}

A hull whose loadPolicy is boot and whose resident size pushes the 20-ship battle over the texture budget fails with VSM_LOAD_POLICY. INFERRED: the exact streaming mechanism is not specified in the granted documents; the specification requires the metadata and the gate, not a particular eviction algorithm.

### 4.6 Colour-law enforcement at paint time

The cyan check is part of the paint gate, not a separate art review. It runs on the baked atlas after gain:

1. Convert each texel's final linear RGB to OKLCH.
2. If hue in PROPOSED [180 degrees, 210 degrees] and chroma > PROPOSED 0.08, the texel is cyan-family.
3. A cyan-family texel is legal only if its source module carries the shieldEmitter tag and its shieldMask is 1.0.
4. Any other cyan-family texel fails with PAINT_CYAN_RESERVED, including cyan that arises from FAC3D trim values, from compression artifacts, or from a glow channel that is not a shield.
5. The check samples at full atlas resolution for the kit and at the hull atlas's native resolution for the hull; both are included.

OBSERVED (brief): "cyan means shields, nothing else is cyan" - OBSERVED (brief). The gate is absolute; there is no "small accent" exception. If a pack's art direction wants a cyan-looking trim, the correct fix is to change the FAC3D channel value to a non-cyan hue, not to add an exception.

## WHAT EVIDENCE WOULD CHANGE MY RECOMMENDATIONS

1. Measured topology of the 36 existing meshes. If they lack coherent station correspondence, usable UVs, or manifold surfaces, the loft guide surface may be unable to fit within dress tolerance. The recommendation would change from "loft guide plus socket projection" to "socket projection only, no loft v2 guide in dressing mode." INFERRED: the brief gives triangle counts but not topology or UV quality.
2. The actual material graph of aiKitMat and HullFx. If the 0.3 emissive term is load-bearing for visibility at the target exposure, deleting it may require a gain above the proposed 1.25 clamp. The recommendation would change to "fix the material graph first, then calibrate," rather than widening the clamp.
3. The actual FAC3D channel definitions and value ranges. If FAC3D's glow channel is not intended for engine/running lights, the emissive path in 4.4 needs a separate channel. If cyan appears in any FAC3D trim value, the cyan gate would fail existing content and the fix would be a FAC3D change, not a validator exception.
4. Desktop stress-test results. The proposed 52.8 MB per-ship texture budget is derived from the kit proposal's 1.32 GB figure. If the actual stress test shows a different ceiling, the budget table and the 60/40 split change. If eviction is mandatory, the streaming gate becomes a hard build requirement rather than a conditional one.
5. Babylon scene handedness in the repo. If the scene is left-handed and changing it would break existing content, the manifest's right-handed authoring frame would need a single import conversion with a declared sourceHandedness, and the validator would need a mirror-detection check on winding order. The coordinate specification would not change, but the importer would.
6. The actual size-class taxonomy and per-class ceilings. The proposed enum light/line/heavy/capital and the zeroed budget records are placeholders. Real class names and measured p95 values would replace them. If a class has only one hull, a p95 ceiling is meaningless; the derivation would change to a per-hull allowance plus kit budget.
7. Voidsworn's actual symmetry rule. The example manifest assumes bilateral. If the art direction calls for a centerline-only or asymmetric Voidsworn, the pack schema, the example, and the mirroring rules change.
8. The Basilica's actual bound mesh. The example uses a registry key because the brief does not name the mesh. If the Basilica is a new kit hull rather than a dress on an existing mesh, the hull binding and the dress-tolerance rules change substantially.
9. The VSM binary format's constraints. If the format cannot store split normals, crease groups, or per-module tags, the hard-station normal strategy and the cyan/shield tag check need a sidecar or a different encoding. The validator's VSM checks would change accordingly.
10. Whether the build system can run TypeScript codegen and enforce branded types. If the pipeline is JSON-only, Layer 1's compile-time impossibility weakens to schema-only impossibility. The validator would need a stronger runtime provenance mechanism, and "impossible to express" would become "impossible to accept at build," which is weaker.
11. The actual module library and its costs. The example's module IDs and triangle counts are illustrative. Real module costs change the budget ladder and may make the budgetOptional policy insufficient.
12. The target display, tone mapping, and exposure. The gain calibration target depends on them. If the game uses a different tone mapper in battle than in the calibration scene, the measured gain is invalid and the recommendation would change to "calibrate in the battle tone-mapping path only."

## NOT SPECIFIED

The following could not be decided from the brief or the granted kit document. They are recorded as open, not assumed.

1. Size-class names and count. The brief requires a size class field but does not enumerate classes. light/line/heavy/capital is proposed, not observed.
2. Per-class vertex, triangle, and texture ceilings. No numbers are given. The budget record is zeroed pending measurement.
3. Which existing mesh each hero manifest binds to. The Basilica's mesh ID, .vsm path, and _kit.json path are not stated. The example uses a registry key.
4. Voidsworn's symmetry rule. Only Hegemony (symmetry enforced) and Corsairs (asymmetry enforced by seed) are described in the kit document. Voidsworn's rule is inferred as bilateral for the example.
5. The repository's Babylon handedness. The brief says PC-only in Babylon but does not state useRightHandedSystem.
6. FAC3D channel names, value ranges, and the exact cyan hue band. The colour law is stated; the numerical band is proposed.
7. Whether loft v2 must output a mesh in dressing mode or only a guide surface. The brief says dressing and refinement; the internal/external output split is inferred.
8. The module library's actual contents and costs. The example's module IDs and triangle counts are illustrative.
9. The VSM binary layout and the _kit.json schema. Only the existence of the .vsm plus _kit.json path for C19_51 is observed.
10. Whether the hulls_hi/ tier is used on PC. The brief mentions hulls/ and hulls_hi/ tiers and 108 files per tier, but does not say which tier the PC build ships.
11. The target display, tone mapping, and exposure for gain calibration. Not stated.
12. Acceptance plate IDs and silhouette sheet IDs. The example uses placeholder paths.
13. Whether lazy loading or eviction is mandatory. The kit document makes it conditional on the desktop stress test.
14. The exact meaning of "station overrides" for AI meshes that may have no authored stations. The normalized s projection is inferred.
15. Whether the 36 existing hulls have UVs suitable for a shared atlas or for projected trim bands. Not stated.
16. Who signs off a class-ceiling change. The kit document says budgets are non-negotiable and enforced at build time, but does not name the authority.
17. Whether variants inherit budgets from the base manifest or are measured independently. The kit document says variants are manifest diffs; the budget inheritance rule is inferred as independent measurement with a shared ceiling reference.
18. Whether the silhouette acceptance check is automated or human. The kit document describes viewer-based rejection; the build hook is specified as metadata only.
19. The exact triangle counts per existing hull by class. The brief gives a range ("roughly 2,400 to 38,000 triangles each") but not a per-class distribution.
20. The actual aiKitMat shader source and where the 0.3 emissive add sits. The kit document names the fudge; the code location beyond aiKitMat is not quoted in the granted excerpt.

End of draft.
