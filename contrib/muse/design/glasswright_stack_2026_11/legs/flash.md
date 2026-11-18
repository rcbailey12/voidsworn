# Issue 935 leg: Gemini Flash (Quick answers 3.5 Flash-Lite, picker verified before and after; signed in as Ryan Bailey)

Design Spec: Glasswright (ithar) Ship Paint System

1. Colour Zones

The Glasswright paint stack divides materials into surface albedo layers and emissive glow layers. All colour zones map directly to the sampled sRGB pairs from the CD5 concept image while honoring the optical aesthetic:

- clear_glass (Clear glass highlights & broad lit faces): #dccacf (lo) to #fff4f4 (hi); median #f5e2e3. Lit: Surface albedo with high specular reflectivity and low roughness.
- milky_glass (Pearly mid glass): #8b7a7d (lo) to #af9ca0 (hi); median #9f8c90. Lit: Surface albedo, diffusing light across the twisted leaf hull.
- silver_veins (Structured structural joins and veins): Derived from metallic accents. Lit: Surface albedo, high metalness, low roughness, reflecting ambient light.
- amber_panes (Stained blown glass inserts): #9a5c2a (lo) to #d99466 (hi); median #b77748. Lit: Surface albedo with a warm internal optical scattering response.
- violet_panes (Stained blown glass inserts): #652680 (lo) to #b874de (hi); median #914aaf. Lit: Surface albedo.
- green_panes (Stained blown glass inserts): #4c630d (lo) to #879e48 (hi); median #647c2b. Lit: Surface albedo.
- lens_glow / lance_glow (Primary & secondary weapon optics, prism lance core): Hot orange clusters (#e26833) grading into faction weapon game colour [0.92, 0.96, 1.0]. Lit: Emissive. Strength range: 2.0 to 4.0 (matching glTF emissive strength precedent). Reads as inside the glass by utilizing ambient occlusion masks (R/B channels) to grade the light from the core to the surface, and by confining emission to designated glow zones only, avoiding surface burn-out.
- stern_bloom (Engine stern optic): Pale cluster (#e9c9d2) grading into faction engine game colour [0.82, 0.94, 1.0]. Lit: Emissive via bake_engine_glow (tools/blender/kits/shared/paint_stack.py:862), creating a soft white bloom with a hot core grading out and per-engine variation.

2. Faking Glass

Since the shared machinery bakes images with alpha=False (tools/blender/kits/shared/paint_stack.py:142), does not use transmission, and outputs standard channels (albedo, ORM, detail normal, separate emissive surfaces), true glass is impossible in the bake path.

What is faked: High specular highlights, crisp edge wear, and simulated internal depth are baked directly into the albedo and ORM maps. Metallic silver veins reflect light, while internal glow zones (tools/blender/kits/shared/paint_stack.py:19) and the G channel) add a sharp rainbow fringe or silver specular catch on cut edges.

What the game side must add: The Godot renderer applies bloom effects (configured via godot/fx/faction_looks.json and look.gd glow threshold 0.8) to catch emissive surfaces without burning out the hull. The shield edge shader applies the "rainbow" visual property.

What is honestly out of reach: True refraction, physical light bending through transparent volumes, and seeing interior geometry through the hull are out of reach. Transparency cannot be represented in the opaque bake path.

3. Masks

The stack relies on the standard shared machinery baking masks into the RGB channels of the mask atlas (tools/blender/kits/shared/paint_stack.py:19):

- R Channel (Short AO): Drives localized cavity darkening within the glass folds and vein intersections, grounding the glass.
- G Channel (Edges): Drives the sharp rainbow fringe and silver wear along cut glass edges and panel boundaries.
- B Channel (Long AO): Drives broad volume occlusion, giving the twisted blown-glass leaf a sense of deep internal volume.

Procedural Drivers:

- Island ID / Face Normal: Separates plate islands for two-tone glass variations.
- World Position & Noise: Drives subtle internal organic density variations across the continuous glass skin, keeping the hull from looking uniform.

New Mask Needed: None required; the standard R,G,B masks and spatial drivers fully support the optical layering. No new mask is introduced.

4. Material Names

Glasswright build sheets must use the following exact zone naming convention, split into surface ZONES and emissive GLOW sets:

ZONES (Surface Albedo / PBR):
- clear_glass
- milky_glass
- silver_veins
- amber_panes
- violet_panes
- green_panes

GLOW (Emissive Surfaces):
- lens_glow
- lance_glow
- stern_bloom

5. Trim Sheet and Decals

Usage: The Glasswright faction does not use standard industrial trim sheets (rivets, scuffs, box-projected stripes) or decals.

Why: Rule R192 dictates that every structural part is shaped with care and serves as its own ornament. A riveted industrial trim sheet would violate the continuous blown-glass skin (R196) and the "no visible seam" rule. Any decoration must be grown into the glass itself via silver veins or stained panes, not applied as a decal.

6. Three Risks with a Fallback

- Risk: High emissive coverage from stained glass panes and weapon optics pushes too much surface area above the 0.8 glow threshold, causing a burn-out similar to the earlier hull failure (tools/blender/kits/hegemony/stack.py:18-19). [Chair note: this cite is wrong; the burn-out note is in look.gd lines 18-19, as the pack stated. Recorded as a leg slip; nothing rests on it.]
Fallback: Restrict emission strictly to designated GLOW zones and use short AO (R channel) multiplication to clamp emissive intensity inside surface crevices.
- Risk: Without transmission or real refraction, the glass sheets may look flat and read like polished plastic or ceramic rather than blown glass.
Fallback: Maximize roughness contrast using the G-channel edge mask to create brilliant razor-sharp specular highlights on edges while keeping broad faces softer and more diffuse.
- Risk: Sampled concept glass colours (#dccacf, #9f8c90, etc.) combined with procedural noise may blend into muddy, low-contrast gradients under standard lighting.
Fallback: Enforce strict sharp steps between plate islands using Island ID drivers rather than smooth noise blends, preserving the distinct stained-glass pane identities.
