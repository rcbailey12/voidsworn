# Issue 935 leg: DeepSeek (DeepThink ON, Search OFF, verified before and after; no sign-in required; em and en dashes in the original normalized to hyphens per the repo no-dash rule)

# Glasswright (ithar) Paint-Stack Leg

## 1. Colour zones and lighting

The stack uses the shared bake path: albedo, ORM, detail normal, and separate emissive surfaces (paint_stack.py:1-19). Surface zones are opaque Principled materials; glow zones become separate emissive surfaces via split() / GLOW_ZONES (paint_stack.py:42, paint_stack.py:57). Glass is never transparent in the bake path: baked images are created with alpha=False (paint_stack.py:142) and zone_material sets no transmission or transparency (paint_stack.py:392).

| Zone name | Kind | sRGB pair | Lighting / grading |
|---|---|---|---|
| clear | surface albedo | #dccacf / #fff4f4 | Clear glass highlights and broad lit faces. Low roughness, metallic 0. Two tones per plate island from island id. R short AO darkens seams and lens wells; G edges brighten cut bevels and drive silver/rainbow fringe; B long AO adds interior depth. No emission. |
| milky | surface albedo | #8b7a7d / #af9ca0 | Pearly mid glass. Roughness a little higher than clear, metallic 0. B long AO is the main depth driver; G edges keep rims readable. No emission. |
| silver | surface metal | #8b7a7d / #fff4f4 - correction argued | No sampled silver-vein hue exists; silver veins are the metallic/specular component of pearly mid glass plus clear highlights. Use pearly lo and clear hi as the metal range. Metallic 0.85-1.0, roughness 0.10-0.20. Driven by G edges plus noise/island id. No emission. |
| amber | surface albedo | #9a5c2a / #d99466 | Amber pane body. Roughness 0.18-0.32. G edges darken pane borders; R short AO recesses; B long AO deepens cavity. No emission; inner light comes from iamber. |
| violet | surface albedo | #652680 / #b874de | Violet pane body, same grading as amber. No emission; inner light comes from iviolet. |
| green | surface albedo | #4c630d / #879e48 | Green pane body, same grading as amber. No emission; inner light comes from igreen. |
| iamber | emissive | #9a5c2a / #d99466 | Amber pane core. Final emissive peak 0.20-0.70 linear luminance, kept below the game’s 0.8 glow threshold (look.gd:120-126). Reads as inside glass because the core is recessed behind the amber body/lip, whose R/G/B masks darken the rim; the core itself is flat (hegemony/stack.py:386). |
| iviolet | emissive | #652680 / #b874de | Violet pane core, same strength and inside-read discipline as iamber. |
| igreen | emissive | #4c630d / #879e48 | Green pane core, same strength and inside-read discipline as igreen. [Chair note: the leg's self-reference here reads "as igreen" in the original; from the table's pattern it means iamber. Recorded as a leg slip; nothing rests on it.] |
| ilance | emissive | #e26833 / #fff4f4 - correction argued | Lance/optic glow. Sample gives hot-orange lance-point clusters; use orange lo to white hi for point-to-core grading. Final peak 1.6-4.0 linear; this is a designated glow surface and may cross 0.8. White core with orange point clusters; rainbow fringe is approximated on the surrounding G-edge/bevel, not in the flat core. Reads as hull-stored light let out through a recessed bow optic; B long AO and G edges on the rim sell the cavity. |
| istern | emissive | #e9c9d2 / #fff4f4 - correction argued | Stern bloom. Sample gives pale, bloom-affected stern optic; pair with clear hi. Final peak 1.2-3.0 linear. Use the engine-glow baker’s hot-core grading (paint_stack.py:862) for the stern optic; reads as a soft white bloom inside the stern lens, not flame. |
| ilining | emissive | #e9c9d2 / #fff4f4 | Interior core light only, final peak 0.15-0.45 linear. Keeps the core’s light while room liners stay dark. |
| dark | surface albedo | no sampled hull pair | Interior room liner only, not a hull colour zone. One dark liner per room, as the recipe requires; the core keeps ilining. |

Glow discipline: only ilance and istern are allowed above the game’s 0.8 glow threshold; pane cores and ilining stay below it. This follows the Hegemony precedent that intact non-glow surfaces must not cross threshold (hegemony/stack.py:331-344), and avoids the earlier burnout where baked emissive covered over a quarter of the hull above threshold (look.gd:18-19). The game exports with glTF emissive strength 4.0 (look.gd:47-49), so final peak values above are stated after export strength.

No soot, rust, blood, steel, or brass zones: the faction never uses rust, smoke, or flame, and its metal is the grown-in silver vein.

## 2. Faking glass

Glass is faked as opaque, polished, low-roughness PBR with a metal vein network and separate emissive cores.

clear and milky are metallic 0, low roughness, two-tone per plate island. The two tones give the blown-glass striation read; R short AO puts darkness only in seams and lens wells; G edges put bright cut edges and silver/rainbow-adjacent fringe on bevels; B long AO deepens the apparent interior.

silver is a high-metallic, low-roughness surface zone driven by G edges and noise, so veins read as metal grown through glass rather than applied lines.

Stored light is never transmission. It is separate emissive surfaces: iamber/iviolet/igreen cores recessed behind pane bodies, ilance at the bow optic, and istern at the stern. The “inside” read is a contrast trick: the surrounding surface zone gets R/G/B darkening at the lip, while the flat emissive core stays bright (hegemony/stack.py:386).

The rainbow fringe is only approximated: G edges plus face normal/world position tint the bevel with a narrow accent band. It is not spectral.

Game side must add, if anything: a view-dependent Fresnel/specular rim term for the clear/milky zones, and optionally a spectral edge ramp keyed to the G edge mask, to make the opaque PBR read more like glass. Without that, the stack reads as polished ceramic/stone with metal veins, not glass.

Honestly out of reach with this bake path: true transparency, refraction, lensing, caustics, volumetric inner glow, depth-sorted “inside” geometry, and a true rainbow spectrum. The bake path has no transmission or alpha (paint_stack.py:392, paint_stack.py:142), so those must not be promised.

## 3. Masks and procedural drivers

No new mask is required. Pane cores are separate GLOW objects, so the stack does not need a transmission/thickness mask; adding one would require a new bake channel, while the shared header defines only R/G/B masks and baked images are alpha=False (paint_stack.py:1-19, paint_stack.py:142).

| Layer / effect | Masks and drivers | Use |
|---|---|---|
| Two-tone plate base | island id | Per-plate-island lo/hi tone for clear, milky, amber, violet, green; breaks repetition and gives blown-glass patchiness. |
| Crevice darkening | R short AO | Seams between panes, lens wells, bow-optic recess, stern-optic recess; darkens surface zones, never the glow core. |
| Cut edges, silver veins, fringe | G edges + face normal + world position | Bright bevels, silver vein network, narrow rainbow-adjacent fringe. Face normal selects grazing/top bevels; world position breaks the fringe into bands. |
| Interior depth | B long AO | Milky depth, long cavities, pane recesses, stern/bow optic cavity read. |
| Silver vein branching | G edges + noise + island id | Veins follow bevel/edge network but are broken by noise and seeded per island; not a uniform edge-wear line. |
| Pane mottling | noise + island id + world position | Low-frequency stained-glass variation inside amber/violet/green bodies. |
| Pane-core inside read | surrounding R/G/B only | The core is flat emissive; the body/lip around it gets R short AO, G edge, and B long AO so the core appears recessed. |
| Stern hot core | bake_engine_glow | Engine-throat emission map with hot core grading out and per-engine variation (paint_stack.py:862). |

## 4. Material names

A Glasswright build sheet must use exactly these material names.

ZONES - surface: clear, milky, silver, amber, violet, green, dark.

GLOW - emissive: ilance, istern, iamber, iviolet, igreen, ilining.

dark is interior liner only. ilining is the core’s retained light. No other paint-zone names are valid for this faction; in particular, do not use soot, rust, blood, steel, or brass.

## 5. Trim sheet and decals

Glasswright uses neither the trim sheet nor decals. The shared machinery can build a trim sheet of rivets, scuffs, stripes, and box-projected marks, and can add decals (paint_stack.py:1-19), but this faction must disable both.

Reason: the binding faction rule is that every structural part is shaped with care and is also the ornament; lenses are grown in as one continuous skin with no pod, bracket, ring mount, or visible seam (R196). Rivets, scuffs, stripes, and applied decals would read as bolted-on decoration or surface appliqué, contradicting the grown-glass skin. The ornament is geometry plus mask-driven silver veins, cut-edge fringe, and pane structure. Trim and decal layer weights in LAYERS must be zero.

## 6. Risks and fallbacks

| Risk | Fallback |
|---|---|
| Pane cores or lance bloom exceed the 0.8 glow threshold over too much hull area, repeating the earlier burnout (look.gd:18-19, look.gd:120-126). | Clamp iamber/iviolet/igreen final peak to 0.70 or below; keep only ilance and istern above threshold. If bloom is still too broad, drop pane cores to surface-only amber/violet/green and rely on albedo plus ilining for the inside read. |
| Opaque PBR reads as plastic or ceramic, not glass, because the bake path has no transmission (paint_stack.py:392, paint_stack.py:142). | Strengthen Fresnel/specular on clear/milky, increase silver-vein contrast, and add the game-side Fresnel rim. If that is unavailable, lean into stylized stained glass: darker seams, stronger pane colour, and accept opaque glass as the faction’s look. |
| The rainbow fringe approximation looks like ordinary edge wear or mud. | Restrict it to G-edge bevels only, use a three-stop accent band rather than a full spectrum, and reduce its width. If still bad, remove the fringe from the baked stack and keep shield_edge: "rainbow" as a game-side shield/UI effect only. |
