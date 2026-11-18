# Issue 935 blind leg: Rey (written before any other leg)

## What the bake path can and cannot do (the frame for everything below)

The shared stack bakes albedo, ORM and a hull detail normal per atlas, and keeps glow zones as their own emissive surfaces (tools/blender/kits/shared/paint_stack.py lines 8 to 19, the header's five steps; split() at line 42 sorts objects into hull, parts, glow and interior, with GLOW_ZONES filled by the faction stack through use()). Nothing in paint_stack.py sets transmission or alpha on a baked material: baked images are created with alpha=False (line 142) and zone_material builds a plain Principled surface (line 392). So real glass, meaning refraction and see-through transmission, is outside the bake path entirely. The Glasswright look has to be faked from four things the path does support: bright low-roughness albedo, the baked masks, separate emissive surfaces for the lit zones, and what the game adds on top (godot/render/look.gd: rim light, the per-faction hull_fix, glow threshold 0.8 at lines 120 to 126, glTF emissive strength 4.0 per the header comment at lines 47 to 49).

## Colour zones, sampled from the CD5 concept

Method: concept.jpg (1536 by 1024, from codex/issue-912) read as pixels; background excluded (mean luminance over 0.06); each zone is the median and quartiles of the pixels in its hue class. Pairs below are (p25, p75) in sRGB, the CONCEPT (lo, hi) convention the finished stacks use (tools/blender/kits/hegemony/stack.py lines 40 to 47).

- clear (the clear blown-glass skin, highlights and broad lit faces): lo #dccacf, hi #fff4f4, median #f5e2e3. Lit as a surface, not emissive: albedo pair, low roughness, the read carried by value and rim.
- milk (milky, pearly glass, the softer mid-tone faces): lo #8b7a7d, hi #af9ca0, median #9f8c90. Surface. The mauve-grey cast is the concept's warm lighting on pearl; keep the samples, the stacks already compensate for the render pipeline's colour shift in their own way (hegemony stack.py lines 62 to 68, the SAT note).
- amber (amber inner panes): lo #9a5c2a, hi #d99466, median #b77748. Inside glow: emissive, graded, brightest at pane centre.
- violet (violet inner panes): lo #652680, hi #b874de, median #914aaf. Inside glow, as amber.
- green (green inner panes): lo #4c630d, hi #879e48, median #647c2b. Inside glow, as amber.
- silver (the veins): not sampled as a hue class (the veins are the bright filament network inside the clear zones, reading as part of the clear pair's top end). Spec it as a layer, not a zone: near-white #f5e2e3 to #fff4f4 driven by the edge mask, metalness up, roughness low.
- glow (the bow lance optic and the forward lances): the concept's lance tips sample hot orange (#e26833, median of the tip clusters), but that is the concept's bloom talking. The game's own weapon colour for ithar is near-white (godot/fx/faction_looks.json, ithar weapon [0.92, 0.96, 1.0] linear), and RECIPE.md's paint stack table puts glow colours in faction_looks.json, read by the stack's glow_material. So the optic glow follows faction_looks, not the orange sample. Emissive surface, over the glow threshold: this is the one zone meant to bloom.
- light glow (the small optics along the hull, the secondary guns): in the concept these are small green and violet points; spec them as emissive surfaces coloured by their pane colour at optic strength, or faction_looks weapon colour where the sheet does not name a pane colour.
- bloom (the stern optic cluster, the engine): concept samples pale pink-white (#e9c9d2 median over the cluster, which is faceted violet-white lenses under bloom). The game colour is faction_looks ithar engine [0.82, 0.94, 1.0] linear, pale blue-white, and the engine bloom is the game's effect; the paint side is an emissive stern surface in that colour, graded like the shared engine glow (paint_stack.py bake_engine_glow, line 862).

## How each zone is lit

- Surface zones (clear, milk): albedo only, no emission. Roughness low for clear (0.05 to 0.15), higher for milk (0.25 to 0.4, it is the frosted read). Metalness 0; the metal look is a trap here, the concept's shine is dielectric.
- Pane zones (amber, violet, green): emission with the pane colour, strength graded 0.35 to 0.8 across the pane (centre high, edges low), held at or under the game's 0.8 glow threshold so the panes read lit-from-inside without blooming into mush. The Hegemony stack sets the precedent: nothing on the intact ship crosses the threshold except designated glow surfaces (stack_hegemony.py lines 331 to 344, GLOW). Inside versus surface: the gradient is the inside read; a flat emission is a surface sticker and will fail the look.
- Optic zones (glow, light glow, bloom): true emissive surfaces through the stack's glow path (split() glow group, GLOW_ZONES, glow_material), strength in the 2.0 to 4.0 range the game expects (look.gd line 47: emissive strength 4.0), so they cross the threshold and bloom like the other factions' glow surfaces.

## Masks

The bake gives three masks per atlas (paint_stack.py line 8 and RECIPE.md step 3): R short-reach AO, G convex edges, B long-reach AO. Plus the procedural drivers zone_material already uses: island id, noise, world position, face normal (up).

- Silver veins: G (edges). The veins in the concept run along the pane and plate borders; the edge mask is exactly that network. Vein brightness peaks on G, fading off it.
- Pane inside glow gradient: 1 minus G (pane centres are far from edges), multiplied by (1 minus B) so panes seated deep in recesses glow less. No new mask needed for the gradient itself.
- Clear glass shading: R and B as usual for cavity shading; the patchwork/island tone machinery should run at very low amounts for glass (plate_var small), because the concept's clear skin is continuous, not plated.
- Rainbow fringe on cut edges: G again, as a hue rotation at the very top of the edge band. Note the game already owns a rainbow for this faction (faction_looks.json ithar shield_edge is the string "rainbow"), so the fringe has a game-side home if the bake version reads as noise.
- NEW MASK NEEDED: a depth mask. The stored light sits deep inside the hull and the panes are lit from behind the skin; neither AO channel measures "how much glass is in front of the light". Bake a fourth mask image alongside the existing three: inward occlusion, the AO of the interior shell seen from the pane and skin surfaces (the same bake machinery, reversed reach), used to grade pane emission and to tint the clear skin (deeper glass reads darker and more saturated). Name it in the spec as mask set 2, R channel: depth. Without it the inside glow can only be faked per-island, which will read flat on the big panes.

## Material names a Glasswright sheet must use

Following the existing zone vocabulary (RECIPE.md paint stack table: soot, rust, iron, pale, violet, lilac, steel, dark, brass; glow, ember, light glow), the ithar sheet names: clear, milk, amber, violet, green, silver, glow, light glow, bloom. The stack's ZONES carries clear, milk, amber, violet, green and silver; GLOW carries glow, light glow and bloom. Inside rooms keep the shared dark liner (RECIPE.md step 6), with the core keeping its light: for Glasswright the liner tint is the stored light colour, pale seafoam-white.

## Trim sheet and decals

None. Glasswright ships carry no rivets, stripes or decals; the trim sheet machinery should be switched off in LAYERS for this faction (amounts zero), and the ornament is the glass itself (factions.md, the Glasswrights: every structural part is shaped with care and is also the ornament, R192). The licence line problem disappears with it.

## Three risks, with fallbacks

1. No transmission: the faked glass reads as opaque glossy plastic or pearl at battle camera, not glass. Fallback: shift the read onto the panes and the rim (raise clear albedo value, lean on look.gd's rim and the ithar hull_fix [0.1, 0.25, 1.0]), and increase the milk share, since milky glass fakes better than clear. If it still fails, the honest remainder is a game-side fresnel term, which is a look.gd change and the Board's call, not the stack's.
2. Emissive panes blow out: pane emission over the 0.8 threshold blooms and the stained panes merge into one glow (the A4 burn-out precedent, look.gd lines 18 to 19). Fallback: drop pane emission to zero and carry the panes as bright albedo under the surface zones' lighting, keeping emission only in the optic zones; the panes still read by colour and value.
3. Node graph size: the glass layers (vein network, fringe, pane grading, depth mask) grow the zone graphs; A20's trophy material already exceeded Cycles' SVM stack (RECIPE.md paint stack section, the issue 726 note). Fallback: drop the fringe layer first (it has a game-side home), then grade panes with the island driver instead of the depth mask, keeping the graph inside the budget the Hullbreaker trophy route already proved (the ps_height_bake split exists for exactly this pressure).
