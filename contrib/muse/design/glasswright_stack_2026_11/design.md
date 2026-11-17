# Glasswright (ithar) paint stack: build-ready design spec

Issue 935. Spec only: this document defines `tools/blender/kits/ithar/stack.py` so Codex can implement it without guessing. No code, no Blender work, no changes outside this folder.

Chaired from five legs (legs/ in this folder): a blind Rey leg written first, then DeepSeek, Qwen, Grok and Flash legs run against the same evidence pack. Where the legs disagreed, this spec picks one answer and records the disagreement in section 8.

The faction, binding (docs/playbooks/factions.md, the Glasswrights): an instrument for light, built as a warship. R192: every structural part is shaped with care and is also the ornament. R196: lenses grown in, one continuous skin of glass and metal, no pod, bracket, ring mount or visible seam. Shape: a long leaf of flowing twisted blown glass lit from inside. Colours: clear and pearly glass with silver veins, a rainbow fringe on cut edges, stored light deep inside, and since the CD5 flagship (FINDINGS R298) amber, violet and green panes lit from inside like stained blown glass. The prism lance is stored light let out through the bow optic, white core with rainbow fringe; engines are a soft white bloom at the stern optic, no flame. Never rust, smoke or flame.

## 1. The machinery frame (verified on main)

The shared stack (tools/blender/kits/shared/paint_stack.py, header lines 1 to 19) unwraps hull and parts into two atlases, bakes three masks per atlas from the ship's own geometry (R short-reach AO, G edges from bevel normal against face normal, B long-reach AO), builds one procedural material per (zone, atlas) from the faction stack's CONCEPT, ZONES and LAYERS, bakes albedo, ORM and a hull detail normal, and keeps glow zones as their own emissive surfaces. split() (line 42) sorts each object into hull, parts, glow or interior; an object is in the glow set when its emissive_zone or the faction stack's GLOW_ZONES (filled by use(stack), line 57) names it. zone_material (line 392) builds a plain Principled BSDF. Baked images are created with alpha=False (line 142). Nothing in the file sets transmission or transparency on a baked material. bake_engine_glow (line 862) gives engine throats their own emission map, a hot core grading out with per-engine variation. The concept is never projected; colours may be sampled from it.

Consequences the whole spec rests on:

- Real glass (refraction, see-through transmission) is outside the bake path. The look is faked; section 3 says exactly how and what stays out of reach.
- An object is either a surface object or a glow object, never both. A stained pane that must show a tinted body and glow from inside is therefore two things in the sheet: a surface zone object (the pane body) and a glow zone object seated in it (the pane core). This split, from the DeepSeek leg, is the spec's structural backbone.
- Glow colours live in godot/fx/faction_looks.json and are read by the stack's glow_material (RECIPE.md, the paint stack section). The ithar entry (linear RGB): weapon [0.92, 0.96, 1.0], engine [0.82, 0.94, 1.0], damage_glow [0.85, 0.92, 1.0], accent [0.88, 0.9, 0.96], shield_edge "rainbow", wound_kind 2.
- The game reads glow against a 0.8 threshold (godot/render/look.gd lines 120 to 126) and existing hulls export at glTF emissive strength 4.0 (look.gd lines 47 to 49). All emissive strengths in this spec are final peaks after that strength. An earlier hull burned out because its baked emissive map sat above threshold over about a quarter of the hull (look.gd lines 18 to 19). The Hegemony precedent: nothing on the intact ship crosses the threshold except designated glow surfaces (tools/blender/kits/hegemony/stack.py lines 331 to 344); glow_material (line 386) builds flat emissive materials with a peak per zone.

## 2. Colour zones

Sampling method: the approved CD5 concept (1536 by 1024, from branch codex/issue-912, docs/ship_pipeline/build_sheets/ithar_CD5/concept.jpg) read as pixels, background excluded, each zone the median and quartiles of its hue class. Pairs are (p25, p75) sRGB, the CONCEPT (lo, hi) convention of the finished stacks (hegemony/stack.py lines 40 to 47). Reference crops: crops/crop_bow_lances.jpg, crops/crop_pane_field.jpg, crops/crop_stern_optics.jpg.

### 2.1 Surface zones (ZONES; albedo and ORM only, zero emission)

| Zone | CONCEPT pair (lo, hi) | Median | Roughness | Metalness | Role |
|---|---|---|---|---|---|
| clear | #dccacf, #fff4f4 | #f5e2e3 | 0.08 to 0.15 | 0.0 | The clear blown-glass skin: highlights and broad lit faces. Two tones per plate island from island id, at low plate variation; the concept's skin is continuous, not plated. |
| pearl | #8b7a7d, #af9ca0 | #9f8c90 | 0.22 to 0.35 | 0.0 | Pearly, milky mid glass: the body of the leaf where the glass thickens. The mauve-grey cast is the concept's warm lighting on pearl; keep the samples. |
| vein | #c0c4cc, #e8eaf0 | argued, not sampled | 0.10 to 0.18 | 0.85 to 1.0 | The silver veins. The pair is argued: the concept's veins read near-neutral silver, and the sampled clear class is too warm to stand in for metal. A cool neutral pair keeps the veins reading as metal inclusions, not tinted glass. |
| amber | #9a5c2a, #d99466 | #b77748 | 0.12 to 0.20 | 0.0 | Amber pane body: the stained tint when the pane's core is not the brightest thing in frame. |
| violet | #652680, #b874de | #914aaf | 0.12 to 0.20 | 0.0 | Violet pane body, as amber. |
| green | #4c630d, #879e48 | #647c2b | 0.12 to 0.20 | 0.0 | Green pane body, as amber. |
| dark | (interior liner, no concept sample) | n/a | per shared interior default | 0.0 | Interior room liner only, one per room, as the recipe requires. Not a hull colour. |

Surface shading: R darkens seams, lens wells and the lip where a pane core seats; G brightens cut bevels and carries the fringe layer (section 4); B deepens long cavities and the inside of the leaf's twist. No soot, rust, grime, blood, steel or brass layers: the faction never rusts, smokes or burns, and its only metal is the grown-in vein. Those LAYERS amounts are zero.

### 2.2 Glow zones (GLOW; separate emissive surfaces via split() and glow_material)

| Zone | Colour | Final peak | Grading | Reads as |
|---|---|---|---|---|
| ilance | faction_looks weapon [0.92, 0.96, 1.0] | 4.0 at the core, falling to 0 at the optic disc edge | Radial, bake_engine_glow style (paint_stack.py line 862) re-purposed for the bow optic, with per-lance variation | The prism lance and the bow optic: hull-stored light let out. The one zone family meant to cross the 0.8 threshold and bloom. Secondary optics the sheet wants at full weapon strength also use ilance. |
| ibloom | faction_looks engine [0.82, 0.94, 1.0]; the stern lens object's own albedo keeps the sampled facet median #e9c9d2 | 3.0 to 3.5 | Wide soft falloff through bake_engine_glow, very low per-engine variation; the engines are steady, not combusting | A soft white bloom at the stern optic. No flame, no flicker. |
| ipane_a | Amber pair hi #d99466 | 0.35 to 0.70 | Per pane: brightest at the pane centre, falling to zero at the pane border, driven by the pane's own UV island and reduced where B long AO is high (deep-seated panes glow less). In glow_material terms the base emissive is the final peak divided by the 4.0 export strength, about 0.09 to 0.18. | Light inside amber glass, held under the 0.8 threshold so it never blooms. |
| ipane_v | Violet pair hi #b874de | 0.35 to 0.70 | As ipane_a | Light inside violet glass. |
| ipane_g | Green pair hi #879e48 | 0.35 to 0.70 | As ipane_a | Light inside green glass. Small secondary optics seated in a pane take that pane's glow zone. |
| ilining | faction_looks accent [0.88, 0.9, 0.96] | 0.15 to 0.45, flat | None | Interior only: the core room keeps its light (the stored-light reservoir) while the room liners stay dark. |

Glow discipline, binding: on the intact ship only ilance and ibloom cross the 0.8 threshold, and only inside their optic discs. Pane cores and ilining stay under it. The orange in the concept's lance-tip clusters (median #e26833) is the concept render's bloom, not the lance colour: RECIPE puts glow colours in faction_looks.json, so ilance follows the near-white weapon colour. The orange is used once, as the warm end of the fringe fallback (section 4).

Damage glow is not a paint zone. The game already owns it: faction_looks damage_glow [0.85, 0.92, 1.0] is the stored white light inside Glasswright hull damage, applied at runtime. The stack reserves nothing for it.

## 3. Faking glass

Exactly this, and nothing more is promised:

1. Value carries it. clear is very high value at near-zero saturation on an opaque Principled surface with low roughness and the Principled specular left at default. pearl drops to mid value at slightly higher roughness, so thick glass reads satin where thin glass reads bright.
2. Roughness grades like thickness. Across clear and pearl, roughness runs from the thin-blown end (about 0.08) to the thick-ridge end (about 0.35), driven by the thickness mask (section 4), with a low-frequency noise perturbation of about plus or minus 0.03 so the surface never reads as uniform plastic.
3. Depth is faked with B. Long-reach AO multiplies subtly (5 to 10 percent) into the clear and pearl albedo, so concavities and the inside of the twist read as light attenuating through glass. This is the strongest thickness cue the opaque path has.
4. Stored light is emissive geometry, not transmission. Pane cores are separate glow objects seated flush in their pane bodies (R196: one continuous skin, no visible seam; the seating shadow comes from R on the body's lip, not from a gap). The core is flat emissive in the Hegemony manner; the inside read is the contrast between the bright flat core and the mask-darkened rim around it.
5. Cut edges catch light. The G mask drives a bright, very low roughness strip on cut edges, with the fringe tint of section 4 over it.

What the game side must add: nothing blocking. look.gd already applies a rim light and a per-faction hull_fix, and the ithar shield_edge "rainbow" already gives the fringe a game-side home. Two optional enhancements, the Board's call, not this stack's: a stronger view-dependent fresnel term on the clear and pearl zones if the first bake reads flat, and confirming a reflection source (probe or sky) reaches the hull shader, since low-roughness specular with nothing to reflect reads as plastic.

Honestly out of reach in this bake path: true transparency and seeing interior geometry through the hull, refraction and lensing, caustics, volumetric inner glow, subsurface scattering (the milky read is roughness and AO, not SSS), and a true spectral rainbow (the fringe is a hue approximation). None of these may be promised from the stack.

## 4. Masks, layers and drivers

Existing masks (per atlas, from the shared header): R short-reach AO, G edges, B long-reach AO. Procedural drivers: island id, noise, world position, face normal.

| Layer | Drivers | Spec |
|---|---|---|
| Two-tone base (clear, pearl, pane bodies) | island id | lo or hi per plate island; low variation amounts for the glass zones, the skin is continuous. |
| Cavity and seating shading | R | Seams, lens wells, pane lips, optic recesses. Darkens surface zones only, never a glow core. |
| Silver vein network | G plus ridged noise plus world position | Veins follow the edge network and the leaf's long axis, broken by noise and seeded per island so they read grown, not stamped. Density higher mid-leaf, sparser toward the tips (world position ramp on the noise threshold). Vein visibility also gated by the thickness mask: veins show where the glass is thin. |
| Rainbow fringe | G plus face normal | A hue cycle over a feathered band about 3 texels wide (the G mask dilated), hue keyed to the face normal's azimuth around the long axis so neighbouring edges differ slightly. If the cycle aliases at game distance, fall back to a fixed two-colour gradient: warm #e26833 at one end of the edge, engine blue at the other. If it still reads as noise, drop the layer; shield_edge "rainbow" carries the read game-side. |
| Depth shading | B | As section 3, item 3. |
| Pane core grading | the pane's own UV island plus B plus thickness | Radial falloff per pane, centre high; B and thickness reduce deep or thick panes. |
| Lance and stern grading | bake_engine_glow | Radial hot-core maps, per-optic variation (low for ibloom). |
| Blown-glass irregularity | noise | Low-frequency roughness perturbation, about plus or minus 0.03, on clear and pearl. |

NEW MASK REQUIRED: thickness (T). One new mask image baked alongside the existing mask atlas, R channel used. What it measures: local glass thickness, the distance from the outer hull surface inward along the face normal to the first hit on the interior shell. Thin blown faces read low; the spine, optic housings and lance root read high. How it is baked: the shared machinery already raycasts from the surface for its AO bakes; T is one more inward raycast pass per atlas with the distance recorded instead of occlusion, stored in its own image because baked images are alpha=False (paint_stack.py line 142) and the ORM alpha is not available. What it drives: the clear and pearl roughness gradient (thin is glossier), the pane core emission multiplier (thin glass glows more), and vein visibility. Interim approximation until the bake lands: inverted, heavily blurred B. Less accurate, needs no shared-file change, and the stack must read T through one accessor so the swap is a one-line change.

## 5. Material names a Glasswright sheet must use

ZONES (surface): clear, pearl, vein, amber, violet, green, dark.
GLOW (emissive): ilance, ibloom, ipane_a, ipane_v, ipane_g, ilining.

dark is interior liner only; ilining is interior only. No other paint names are valid for this faction. In particular a sheet must not use soot, rust, blood, steel, brass, or the generic glow, ember or light glow for Glasswright parts: the optics are ilance or a pane glow zone, the stern is ibloom.

## 6. Trim sheet and decals

Neither. Unanimous across all five legs, and the reasoning is the faction's first rules: the shared trim sheet is rivets, scuffs and box-projected stripes, and decals are applied marks; both read as bolted-on or stuck-on detail, which R192 (the structure is the ornament) and R196 (one continuous skin, no visible seam) forbid. The stack sets every trim-sheet and decal LAYERS amount to zero and skips the box-projection pass. The richness other factions get from trim is carried here by the vein network, the fringe, the pane colours and the roughness variation.

## 7. Risks and fallbacks

1. Emissive coverage burns out. The hull is covered in glow-capable surfaces; if pane cores or the world-position stored-light gradient push too much area over the 0.8 threshold, the A4 burnout repeats (look.gd lines 18 to 19). Fallbacks, in order: the pane clamp of section 2.2 is binding (final peak at most 0.70); the stack reports the share of glow-atlas texels above threshold at bake time (the Qwen leg's 12 percent is the reference point for that report; it is reported, not a gate); if a baked ship still blooms across its panes, drop the pane cores to albedo-only pane bodies and carry the inside read with ilining and rim.
2. The fake reads as plastic or glazed ceramic. No transmission, no SSS, and low-roughness specular with a weak reflection source is exactly the plastic recipe; two legs called the game-side fresnel the single most important addition. Fallbacks, in order: bake Qwen's static fresnel approximation (face-normal driver brightens each glass island's edges by 8 to 12 percent and darkens centres by 3 to 5 percent) and raise all glass roughness by a flat 0.05; raise the pearl share, since milky glass fakes better than clear; raise vein contrast. The honest remainder is a real fresnel in look.gd, which is a game-side change and the Board's call.
3. Node graph size. The vein network, fringe, pane grading and thickness layers grow the zone graphs, and the Hullbreaker trophy material already exceeded Cycles' SVM limit once (RECIPE.md, the issue 726 note; the ps_height_bake split exists for exactly this pressure). Fallbacks, in order: drop the fringe layer first (it has a game-side home in shield_edge "rainbow"); then grade panes per island without the thickness mask; keep every layer's driver count inside what the trophy route proved.

## 8. Chair notes: how the legs were merged

- Structure: DeepSeek's pane body plus pane core split is adopted because split() (paint_stack.py line 42) makes it mechanical, not stylistic. Rey's blind leg and the Grok and Flash legs graded emission inside a single pane zone; that cannot survive the split, so their grading ideas were moved onto the core zones.
- Names: chaired to short single words in the existing style. Flash's underscored names (clear_glass, lance_glow and similar) were not adopted; they match no existing stack. Qwen's edge zone was folded into the fringe layer, since the fringe is a layer over clear and pearl, not an object a sheet can assign. Qwen's idamage was not adopted: damage glow is game-side already (section 2.2). Grok's optic zone was folded into ilance and the pane glow zones.
- Vein colour: Qwen's argued cool pair over DeepSeek's warm reuse of the pearl and clear pair, and over Grok's derived #c8c4c8 to #e8e4e8, because the veins must read as metal against warm-lit glass.
- Lance colour: Rey and Qwen put the core in faction_looks weapon colour per RECIPE; Grok and Flash took the concept's orange tip sample as the colour itself. Chaired to faction_looks; the orange survives only as the fringe fallback's warm end.
- New mask: Rey's depth mask and Qwen's thickness mask are the same need (how much glass sits between the viewer and the stored light). Chaired as one mask, thickness, with Qwen's inward-raycast bake and Rey's uses. DeepSeek, Grok and Flash asked for no new mask; their specs work without one, but none of them grades pane emission or roughness by local thickness, and the CD5 look needs it.
- Leg slips, recorded, nothing rests on them: Flash cited the hull burnout to hegemony/stack.py lines 18 to 19; the note is in look.gd lines 18 to 19, as the pack stated. DeepSeek's igreen row refers to itself where the table's pattern means iamber. Qwen's pane strengths are internally inconsistent (an effective 1.8 to 2.4 claimed to sit under a 0.8 threshold); section 2.2 resolves it with final peaks of 0.35 to 0.70 and the base value stated as final divided by 4.0.

Legs: legs/blind_rey.md, legs/deepseek.md, legs/qwen.md, legs/grok.md, legs/flash.md. Gates: DeepSeek DeepThink on and Search off, verified before and after. Qwen selector Qwen3.8-Max before submitting, header Qwen3.8-Max after; single answer, no A/B choice. Grok Fast mode, verified before submitting. Flash signed in, picker "Quick answers 3.5 Flash-Lite" verified before and after.
