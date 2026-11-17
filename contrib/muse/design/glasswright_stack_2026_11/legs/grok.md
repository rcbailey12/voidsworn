# Issue 935 leg: Grok (free grok.com, Fast mode, verified before submitting; signed in as Ryan Bailey; em and en dashes in the original normalized to hyphens per the repo no-dash rule)

# Glasswright (ithar) Paint Stack Spec

Faction kit: `tools/blender/kits/ithar/stack.py`.
Shared machinery: `tools/blender/kits/shared/paint_stack.py`.
This leg defines the complete paint behaviour for Glasswright ships so a coder can implement the stack without further design input. All colour decisions are driven by the approved CD5 concept samples and the binding faction rules. No other faction stacks are referenced.

## 1. Colour Zones

Every structural surface is glass-and-metal continuous skin. Colour zones therefore describe optical behaviour rather than separate materials. All surface zones are albedo-driven (no transmission). Glow zones are pure emissive surfaces kept separate by the shared split logic.

| Zone name | sRGB pair (lo, hi) | Source | Lighting | Notes |
|-----------|--------------------|--------|----------|-------|
| clear | (#dccacf, #fff4f4) | clear-glass highlights / broad lit faces | surface albedo | High-value, low-saturation pearly glass. Two-tone island variation only. |
| milky | (#8b7a7d, #af9ca0) | pearly mid glass | surface albedo | Mid-value body of the leaf. |
| silver | (#c8c4c8, #e8e4e8) | derived (veins) | surface albedo | Thin metallic veins running through the glass. Slightly cooler and higher metal than the surrounding glass. |
| amber | (#9a5c2a, #d99466) | amber panes | surface albedo + subtle internal glow hint via mask | Stained-glass pane colour. |
| violet | (#652680, #b874de) | violet panes | surface albedo + subtle internal glow hint via mask | Stained-glass pane colour. |
| green | (#4c630d, #879e48) | green panes | surface albedo + subtle internal glow hint via mask | Stained-glass pane colour. |
| lance | (#e26833, #f8a060) | lance-tip clusters (median + brighter companion) | emissive | Prism-lance core. White-hot centre with rainbow fringe achieved by secondary colour mix driven by edge mask. |
| stern | (#e9c9d2, #f8f0f4) | stern-optic cluster | emissive | Soft white bloom at the stern optic. |
| optic | (#f0f4ff, #ffffff) | derived from weapon / engine look values | emissive | Secondary hull lenses and bow optic faces that must remain above the 0.8 glow threshold. |

**Emissive strength ranges (linear, post-look.gd scale)**
- `lance`: peak 3.5-4.5, fall-off to 1.2 at the fringe. Reads as light stored deep inside the glass and released through the optic.
- `stern`: peak 2.8-3.5, soft radial fall-off. Reads as a gentle internal bloom.
- `optic`: flat 2.0-2.8. Surface emission only; no deep grading required.

Grading is achieved with the existing drivers: short-AO (R) for core intensity, long-AO (B) for overall fall-off, and edge mask (G) for the rainbow fringe on the lance. No new bake is required for the core glow itself; the shared `bake_engine_glow` path already supplies a hot-core map that can be re-coloured per zone.

Silver veins are treated as a surface zone so they receive the same edge-wear and AO treatment as the glass, keeping the continuous-skin rule intact.

## 2. Faking Glass

The bake path produces albedo, ORM and a detail normal only (`paint_stack.py` header lines 1-19; baked images created with `alpha=False` at line 142; `zone_material` at line 392 builds a plain Principled BSDF). Nothing in the shared machinery sets transmission or transparency on a baked material.

**Exact fake:**
- Albedo carries the clear / milky / stained colours with high value and low saturation.
- Metallic is set low (0.05-0.15) on pure glass zones and raised (0.6-0.85) only on the silver-vein zone.
- Roughness is driven low (0.08-0.18) on clear faces, rising slightly on milky and pane zones, and higher still on edges via the G-mask so cut edges pick up a subtle rainbow fringe in the albedo itself.
- The detail normal supplies micro-facets that catch light like blown glass.
- All true emission is kept on separate glow objects (lance, stern, optic) so the main hull never exceeds the 0.8 threshold that previously burned out a hull (`look.gd` lines 18-19, 120-126).

**Game-side additions required:**
- A post-process or material override that can tint the specular lobe with a thin rainbow (already implied by `shield_edge: "rainbow"` in faction_looks.json).
- Optional screen-space refraction or a cheap cubemap reflection pass on the clear-glass materials if the art direction demands more "see-through" quality; this is not produced by the paint stack.

**Honestly out of reach:**
- True volumetric light storage and transmission through the hull.
- Accurate chromatic aberration or lens distortion on the secondary optics.
- Any real refraction of background geometry through the glass skin.

The visual result must still read as "one continuous skin of glass and metal, lit from inside" under the game's existing lighting and glow threshold.

## 3. Masks and Drivers

Existing masks (baked once per atlas from ship geometry):
- R - short-reach ambient occlusion
- G - edge mask (bevel normal vs face normal)
- B - long-reach ambient occlusion

Procedural drivers available to every layer: island id, noise, world position, face normal.

**Layer usage:**

| Layer | Primary drivers | Purpose |
|-------|-----------------|---------|
| Base colour (clear / milky) | island id + short AO (R) | Two-tone plate variation; darker in concavities. |
| Silver veins | noise + world-position gradient along long axis + edge mask (G) | Thin metallic threads that follow the leaf form; denser near edges. |
| Stained panes (amber / violet / green) | world-position bands + face normal (facing camera bias) + long AO (B) | Soft rectangular or leaf-shaped panes that appear embedded; darker at the roots. |
| Edge wear / rainbow fringe | edge mask (G) + short AO (R) | Rainbow tint and slight darkening only on sharp cut edges. |
| Internal glow hint (non-emissive) | long AO (B) inverted | Subtle lift in the deepest parts of clear glass so light appears stored inside. |
| Lance / stern / optic emission | short AO (R) for core, edge mask (G) for fringe, long AO (B) for overall fall-off | Matches the shared engine-glow bake style. |

**New mask required:** none. All required variation can be expressed with the three existing channels plus the procedural drivers. If a future ship needs sharper pane boundaries, a simple world-position band mask can be generated at runtime inside the stack without a new bake pass.

## 4. Material Names

Build-sheet objects must use exactly these zone names (existing style: short, lowercase, no spaces).

**ZONES** (surface, albedo-driven):
`clear`, `milky`, `silver`, `amber`, `violet`, `green`

**GLOW** (emissive, kept as separate surfaces):
`lance`, `stern`, `optic`

These names are collected by `split()` (paint_stack.py line 42) and by the faction stack's `GLOW_ZONES` list (line 57). Any object whose material name is in GLOW is treated as an emissive zone; everything else falls into the surface bake.

## 5. Trim Sheet and Decals

This faction does **not** use a trim sheet or decals.

Reason: the first artistic rule requires that every structural part is already the ornament. Lenses are grown in as continuous skin; there are no rivets, scuffs, stripes, panel lines or external hardware to project. Adding a trim sheet would violate the "no visible seam, no pod, no bracket" constraint and would fight the flowing blown-glass silhouette. All surface variation is therefore generated procedurally from the masks and the two-tone CONCEPT pairs.

## 6. Risks and Fallbacks

1. **Glow threshold breach**
 Risk: baked emissive contribution or overly bright albedo on clear glass pushes any part of the hull above the 0.8 threshold used by `look.gd`, recreating the earlier burn-out.
 Fallback: keep every emissive surface in the GLOW set only; clamp surface albedo value ≤ 0.92; rely on the shared bake path that never writes emission into the main albedo map.

2. **Loss of continuous-skin reading**
 Risk: silver veins or pane boundaries become too hard-edged and read as separate mounted optics, violating R196.
 Fallback: drive vein and pane masks with soft noise + long AO rather than hard world-position cuts; keep metallic contrast modest (≤ 0.85) so the veins remain part of the same material family.

3. **Rainbow fringe disappearing under game lighting**
 Risk: the edge-mask rainbow tint is too subtle once the final ORM and detail normal are applied, leaving the prism lance looking like ordinary white light.
 Fallback: strengthen the fringe by mixing a secondary albedo colour (sampled from the lance-tip orange and the faction weapon colour) solely on the G-channel; if still insufficient, the game-side specular tint already present for `shield_edge: "rainbow"` can be reused on the lance material.

---

All colour pairs, zone names and glow disciplines above are sufficient for a coder to write `tools/blender/kits/ithar/stack.py` and the corresponding entry in `godot/fx/faction_looks.json` without further design decisions.
