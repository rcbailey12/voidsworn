# Hegemony Navy: paint direction (issue 689, R243)

Status: direction for Ryan's yes or no at the swatch review. No stack is built from this page until he rules.
Ruling answered: FINDINGS R243 (Ryan, Nov 13, 2026): "Hegemony also pretty rigid and clean." Hull order follows lore: a pale wedge with a line of blue light, machined, modular, horizontal, a well-kept navy that is never rusty (docs/playbooks/factions.md; R204). Reference picture: H10 (contrib/muse/design/concept_round7_2026_11/hegemony_H10_sheet.jpg), shape settled, style not reached, so its colours are sampled and its rendering is not copied.
Form: docs/ship_pipeline/RECIPE.md, "The paint stack for sheet ships". CONCEPT pairs are (dark, light) sRGB show-tones; the stack divides by LIGHT_GAIN 1.45 and the battle lift read from godot/render/look.gd. No lift number is stated on this page. Glow colours live in godot/fx/faction_looks.json and are read by the stack, never copied here.
Council: blind Rey, Qwen and Flash legs chaired (DeepSeek covered Sunward only); Grok's seat empty (bot wall). Where the legs split, the summary file records the chair's call.

## 1. Panel shape and order

The even grid IS the direction. Hegemony panels are flush rectangles in two identical module sizes, repeated across the whole fleet, with straight seams and no variation a sister ship would not share. patch_warp is 0 and the stack carries an R243 comment saying the even grid is deliberate, so nobody "fixes" it into warp later.

One addition the plain grid cannot say on its own: the module joints. Where hull sections butt and where the twin rails meet the hull, a seamline zone (the module band) carries a double-width seam (about three times patch_seam), a deeper seam_dark .96 and an AO-driven recess, so the ship reads as assembled modules rather than one slab at mid range. The band is structure, not ornament: it sits only where the ship genuinely comes apart. (One leg flagged that Ryan might read any band as ornament, which the guide forbids; the question is carried to the summary for his ruling at the review.)

LAYERS (Hegemony):

- patch_big (.070,.048,.038), patch_small (.032,.021,.018): the two module sizes, identical on every ship.
- patch_over (.085,.055,.045), patch_over_share .05: over-plates at the rail joints only.
- patch_seam .0016, seam_dark .94. Module band: seam width x3, seam_dark .96.
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

The value question, settled: the guide's words say "pale grey", and the H10 sample is a steel-blue grey whose main clusters run #212b3b to #48505e, darker than the words. The concept governs (the issue brief samples hexes from the concepts), and the fleet reads pale beside Sunward's black iron and Eclipse's violet-black, which is the comparison the guide's sentence lives in. The cap that keeps this honest: plates are never brightened past #626d7d (the trim pair's light end). The lit cluster #888f9f is a light catch and a wear tone, never a plate tone. If Ryan wants the fleet visibly lighter than the concept, that is his call at the review and it departs from the sample; the summary lists it.

## 3. ZONES notes

- rust 0 everywhere (guide; R204, a well-kept navy, never rusty).
- grime: body .30, recessed .45, module bands .40, nozzles .30, trim .20. Light soot at the nozzle faces is the whole of it.
- roughness floor .52 in every zone; trim rough .55, metal .50; nozzle housings metal .48.
- symmetry is a build rule, not a paint value: every decal, wear patch and scuff on one side is mirrored on the other (guide: never asymmetry). The builder adds a port and starboard mirror check.

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
