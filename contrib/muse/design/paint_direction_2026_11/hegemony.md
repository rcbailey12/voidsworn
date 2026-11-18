# Hegemony Navy: paint direction (issue 689, R243)

Status: direction for Ryan's yes or no at the swatch review. No stack is built from this page until he rules. RULED Nov 14, 2026: approved (amendments, where any, are in summary.md).
Ruling answered: FINDINGS R243 (Ryan, Nov 13, 2026): "Hegemony also pretty rigid and clean." Hull order follows lore: a pale wedge with a line of blue light, machined, modular, horizontal, a well-kept navy that is never rusty (docs/playbooks/factions.md; R204). Reference picture: H10 (contrib/muse/design/concept_round7_2026_11/hegemony_H10_sheet.jpg), shape settled, style not reached, so its colours are sampled and its rendering is not copied.
Form: docs/ship_pipeline/RECIPE.md, "The paint stack for sheet ships". CONCEPT pairs are (dark, light) sRGB show-tones; the stack divides by LIGHT_GAIN 1.45 and the battle lift read from godot/render/look.gd. No lift number is stated on this page. Glow colours live in godot/fx/faction_looks.json and are read by the stack, never copied here.
Council: blind Rey, Qwen and Flash legs chaired (DeepSeek covered Sunward only); Grok's seat empty (bot wall). Where the legs split, the summary file records the chair's call.

## 1. Panel shape and order

The even grid IS the direction. Hegemony panels are flush rectangles in two identical module sizes, repeated across the whole fleet, with straight seams and no variation a sister ship would not share. patch_warp is 0 and the stack carries an R243 comment saying the even grid is deliberate, so nobody "fixes" it into warp later.

One addition the plain grid cannot say on its own: the module joints. Where hull sections butt and where the twin rails meet the hull, a seamline zone (the module band) carries a double-width seam (about three times patch_seam), a deeper seam_dark .96 and an AO-driven recess, so the ship reads as assembled modules rather than one slab at mid range. The band is structure, not ornament: it sits only where the ship genuinely comes apart. (One leg flagged that the band might read as ornament, which the guide forbids; Ryan ruled at the swatch review, Nov 14, 2026, that it does not read as ornament. The band stands.)

LAYERS (Hegemony):

- patch_big (.070,.048,.038), patch_small (.032,.021,.018): the two module sizes, identical on every ship.
- patch_over (.085,.055,.045), patch_over_share .05: over-plates at the rail joints only.
- patch_seam .0016, seam_dark .94. Module band: seam width x3, seam_dark .96.
  As built (Board, Nov 15 2026, PR 796 calls 2 and 3): the sheets model the even grid in geometry (flush slabs at the 0.6
  module pitch, kits/hegemony/parts.py module_panels), and a painted grid at these sizes cannot fall on the modelled gaps, so on
  the plated zones (hgrey, hpanel) the painted grid's seams are faint (strength .35; .60 on the recessed fields) and the cells'
  calm tones carry the painted grid; the module band's seams keep full strength. At a band the joint between the two trim rings
  is dark all across (0.08 world: .0038 ship lengths on H10, .0026 on IM5) and a one-sided seam 1.5 patch_seam wide runs where
  each ring meets the plating, so the rings read as clean trim.
- patch_warp 0, patch_band 0, patch_split 0.
- plate_var .07, island_tone .10, mottle 0, grain 0. The lowest variation of any faction: the fleet is identical by doctrine.
- rough .58, rough_floor .52, metal .45.
- grime .30, scuff .08, wear light (edge wear last, over decals).
- rivets 0 (flush fasteners, no visible rivet lines).
- rust 0 in every zone.

## 2. CONCEPT pairs

Sampled from H10 by the chair (k-means, 9 clusters, background excluded by corner colour). Pairs are (dark, light):

- hull (body modules): ((20,28,42),(72,80,94)), hex #141c2a / #48505e.
- hull_shade (recessed fields): ((11,16,28),(33,43,59)), hex #0b101c / #212b3b.
- trim (steel-blue strips at module edges and the rails): ((43,57,77),(98,109,125)), hex #2b394d / #626d7d.
- implant (light strips and nozzle faces, plate side): ((87,182,229),(189,241,253)), hex #57b6e5 / #bdf1fd, the H10 blue filter mean and hot decile. The emissive colour itself is the game's, read from faction_looks.json.
- nozzle (rectangular nozzle housings): ((33,43,59),(72,80,94)), hex #212b3b / #48505e.
- liner (interior): ((10,14,22),(21,29,43)), hex #0a0e16 / #151d2b, dark with a faint cold tint. The core keeps its light.

The value question, settled: the guide's words say "pale grey", and the H10 sample is a steel-blue grey whose main clusters run #212b3b to #48505e, darker than the words. The concept governs (the issue brief samples hexes from the concepts), and the fleet reads pale beside Sunward's black iron and Eclipse's violet-black, which is the comparison the guide's sentence lives in. The cap that keeps this honest: plates are never brightened past #626d7d (the trim pair's light end). The lit cluster #888f9f is a light catch and a wear tone, never a plate tone. Ryan confirmed the value call at the swatch review (Nov 14, 2026): the sample holds, no deliberate lightening.

The hue hold (Board, Nov 15 2026, PR 796 calls 2 and 3): AgX and the warm key grey the steel-blue out of these dark tones (the
first H10 bake measured blue over red 1.26 against the concept's 1.46), so the stack paints each tone's distance from its own
grey 1.5 times (SAT 1.5, luminance kept, the Eclipse stack's method), every tone still held under the #626d7d cap. With the
R262 step below, the boost is 1.3: the brighter plates grey out less under AgX, and at 1.5 the battle hue drifted bluer than the
concept (blue over red 1.56 against 1.46); at 1.3 it holds.

One step lighter for battle (Ryan, Nov 15 2026, R262): Ryan picked "Fix engines, lighten a step"; the sampled pairs above stay the record,
and the stack paints the plate tones (hull, the plate-family step, hull_shade, trim, nozzle) one step toward the cap: each
tone's brightest channel x (linear) goes to cap x (x / cap) ** PLATE_STEP, the other channels scaled with it so the hue holds,
nothing past #626d7d (the trim pair's light end is the cap and stays there). The worn edges are the cap tone already, so they
stay the lightest tone. Glow colours, the light gain and the look.gd lift are unchanged. PLATE_STEP and the before and after
battle medians are in the stack and PR 796.

## 3. ZONES notes

- rust 0 everywhere (guide; R204, a well-kept navy, never rusty).
- grime: body .30, recessed .45, module bands .40, nozzles .30, trim .20. Light soot at the nozzle faces is the whole of it.
- roughness floor .52 in every zone; trim rough .55, metal .50; nozzle housings metal .48.
- symmetry is a build rule, not a paint value: decals on one side are mirrored on the other (guide: never asymmetry); the shared wear and scuff noise is not mirrored (it would need a shared change). The builder adds a port and starboard mirror check.

## 4. Trim and wear

- Trim is the steel-blue strip at module edges and along the twin rails, one seam wide, plus the stencil marks: identical small marks at module corners (H10 carries "HD-14" as the picture's example), symmetric, low contrast.
- Wear is dulled pale edges shifting toward #626d7d, confined mostly to the module bands and nozzle housings. This is a maintained fleet: wear .08 scuff reads as machining and handling marks, at Eclipse's level, and no lower, or the hull goes CG-clean.
- Edge wear runs last, over the decals.

## 5. Lights and glow

- Implant-blue strips run the hull's blue line; the flat row of rectangular nozzle faces glows blue-white at the stern; a faint point at the sensor fin tip. Colours are the game's (faction_looks.json hegemony engine and weapon), read by the stack.
- Thresholds: strips at about 0.74 at rest, pulsing to about 0.79 at the peak, never crossing the 0.8 threshold; nozzle faces about 0.76; fin tip about 0.65. The pulse timing is the game's (the strips pulse in time across the whole fleet, per the guide); the stack supplies colour and ceiling only.
- The strips are the running lights; there are no separate navigation points.
- Never warm light on the intact ship (guide). The white-gold damage glow is the game's, inside damage only, and is not a fleet accent.

## 6. Camera 170 read

One silhouette: a heavy thick wedge on twin rails, big shoulder turrets, one low sensor fin, symmetric. One main colour: the steel-blue grey of the hull pair, pale beside the black and violet fleets. One accent light: the blue line. Seams, bands and stencil marks are close-up bonuses; at 170 the hull is a clean, uniform wedge, and that cleanliness is the identity.

Checks for the builder: surface check at stage 5; camera 170 read; symmetry mirror check; emissive audit (strips never over threshold, no warm emissive on the intact ship); value cap audit (no plate brighter than #626d7d).

## 7. NOT ADOPTED

- Rust, asymmetry, ornament, warm light: rejected by the guide, each one.
- #888f9f as a plate tone: lit-edge cluster (7.6 percent), light catch and wear only.
- #0b101c as a body tone: deep shadow cluster, shade zone only.
- Any warp, banding or split in the grid: rejected by R243; the even grid is the lore.
- The white-gold damage glow as a design colour: the game's, damage only.
- The H10 picture projected onto the hull: RECIPE forbids it; colours are sampled, the picture is never projected.
- A battle lift number stated on this page: the stack reads look.gd.

Sources: FINDINGS R243 and R204; docs/playbooks/factions.md (Hegemony lines, camera 170 rule); RECIPE stack section; the Hullbreaker and Eclipse LAYERS as worked form; H10 chair samples; godot/fx/faction_looks.json (hegemony).
