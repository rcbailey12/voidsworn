# Sunward Crusade: paint direction (issue 689, R243)

Status: direction for Ryan's yes or no at the swatch review. No stack is built from this page until he rules.
Ruling answered: FINDINGS R243 (Ryan, Nov 13, 2026): "Sunward could have more triangle sleek panels." Hull order follows lore: a black iron blade with burning spires (docs/playbooks/factions.md). Reference picture: S8 (contrib/codex/design/concept_round5_2026_11/voidsworn_S8_sheet.jpg), shape settled, style not reached, so its colours are sampled and its plate grid is not copied.
Form: docs/ship_pipeline/RECIPE.md, "The paint stack for sheet ships". CONCEPT pairs are (dark, light) sRGB show-tones; the stack divides by LIGHT_GAIN 1.45 and the battle lift read from godot/render/look.gd. No lift number is stated on this page. Glow colours live in godot/fx/faction_looks.json and are read by the stack, never copied here.
Council: blind Rey, DeepSeek, Qwen and Flash legs chaired; Grok's seat empty (bot wall). Where the legs split, the summary file records the chair's call.

## 1. Panel shape and order

Two regions, one forged order:

- Flat fields (the blade's flanks, the broadside decks, the spine base): sleek triangular plates, long edge on the hull axis, point forward, nested point-to-base so the rows run straight along the decks. The guide's broadside decks sit in long straight rows, so the triangles flatten on the deck bands and keep those rows straight.
- Curved parts (spire roots, engine bell housings, the tapered edges): the shared stack's rectangular grid at the smaller patch size, because a triangular grid shears on compound curves. The two regions blend across a one-cell seam band, no hard switch.

patch_warp is 0 and stays 0: Sunward plates are forged, not scavenged. Hullbreaker's warp is Hullbreaker opt-in only (R240, PR 682). A comment in the stack should say so, so a future editor does not "fix" the order into warp. plate_var and island_tone carry the forged variation instead: no two castings cool quite alike, but every plate is placed on purpose.

LAYERS (Sunward):

- patch_big (.070,.038,.028): the flat-field triangles.
- patch_small (.030,.018,.014): curved-part rectangles and triangular infill.
- patch_over (.060,.036,.026), patch_over_share .08: over-plates at deck edges and spire roots only.
- patch_seam .0014, seam_dark .90.
- patch_warp 0, patch_band 0, patch_split 0.
- plate_var .22, island_tone .50, mottle .05, grain 0.
- rough .68, rough_floor .55, metal .48.
- grime .55, scuff .35, wear 1.0 (edge wear last, over decals).
- rivets 1, rivet_pitch .011.
- rust 0 in every zone.

## 2. CONCEPT pairs

Sampled from S8 by the chair (k-means, 9 clusters, background excluded by corner colour). Pairs are (dark, light):

- iron (body plates): ((25,22,21),(82,81,81)), hex #191615 / #525151. The hull's mid sits at cluster #434242 (24.5 percent of the picture).
- iron_shade (recessed fields): ((8,8,7),(59,53,50)), hex #080807 / #3b3532.
- spire (radiator bars, plate side): ((169,73,17),(218,111,21)), hex #a94911 / #da6f15, the S8 ember deep cluster and filtered mean.
- spire_hot (bar centres): ((218,111,21),(252,171,59)), hex #da6f15 / #fcab3b, the ember hot decile.
- bell (engine bell housings): the spire pair; the glow inside the throat is the game's engine colour, read from faction_looks.json.
- frost (markings only): single tone (231,244,255), hex #e7f4ff, the sRGB read of the game's voidsworn accent (linear 0.8, 0.9, 1.0). Frost white is essentially absent from S8 (one pixel at the filter), so it comes from the guide's "frost-white markings" plus the game accent, never from the picture.
- liner (interior): ((13,11,10),(26,21,18)), hex #0d0b0a / #1a1512, dark with a faint warm tint. The core keeps its light.

## 3. ZONES notes

- rust 0 everywhere (guide: never rust).
- grime: body .55, recessed .70, gun decks .60, spire roots .20 (heat burns them cleaner), bells .30. Grime is dark carbon soot, colour of the iron_shade dark end, never rust streaks.
- roughness floor .55 in every zone; spire bars rough .55, metal .50 (heat scale); body metal .48, recessed .35.
- patchwork share is the patch_over_share .08 above; there is no other overlap. These plates are forged to fit, not scavenged.

## 4. Trim and wear

- Rivet lines are the trim: rows along the triangles' long edges and the deck bands, pitch .011 to start. The builder A/B tests .013 at camera 170 (heavier forging may want the coarser pitch) and reports which reads.
- Frost-white markings are decals only, never a plate family: a spine line, broadside deck row numbers, heat-shed marks at the spire roots. Cap: at most 6 percent of any visible face, so the black blade still reads black at camera 170.
- Wear shows dulled bright iron at the edges, tones #656564 to #848382 (S8's lit-edge clusters). Those clusters are wear tones only, never plate tones.
- Edge wear runs last, over the decals.

## 5. Lights and glow

- Ember zones: spire bars, engine bell throats, window slits. Colours are the game's (faction_looks.json voidsworn engine and accent), read by the stack.
- Thresholds: bell throats sit at about 0.75 of the game's 0.8 glow threshold, deep-set so the bloom stays contained; spire bar tips reach about 0.78, just under the threshold, with the gradient running deep #a94911 at the root to hot #fcab3b at the tip. The spires shed the reactor's heat (guide), so they are the ship's signature glow, but nothing on the intact ship crosses into bloom.
- Frost markings are not emissive. There are no separate running lights: the ember line is the light. (One leg proposed small frost-white running points on the blade's edge; the chair did not adopt it, because a second, cool accent breaks the one-accent read. It is listed in the summary as a question for Ryan.)
- Never blue light (guide). The builder verifies no Sunward emissive has blue over green.

## 6. Camera 170 read

One silhouette: a long narrow dagger with tall spires. One main colour: black iron, hull median inside the iron pair's band. One accent light: the ember line along the spine and the stern bells. The triangular order, the rivet lines and the frost marks are close-up bonuses; if the triangles only show up close, the identity still holds, because the panel order is the surface's lore, not the silhouette.

Checks for the builder: surface check at stage 5; camera 170 read; emissive audit (nothing over threshold on the intact ship, no blue over green); frost coverage audit against the 6 percent cap; a lift test in the form of the Chorus one (no hue swing after the battle lift).

## 7. NOT ADOPTED

- The even rectangular grid as the whole hull order: rejected by R243. It survives only on curved parts, at the small size.
- Hullbreaker patch_warp: rejected, R240 opt-in only.
- Rust in any layer: rejected by the guide.
- Blue light: rejected by the guide.
- Frost white as a plate family: rejected; the guide says markings, and S8 carries none.
- #848382 and #656564 as plate tones: lit-edge clusters, wear tones only.
- The S8 picture projected onto the hull: RECIPE forbids it; colours are sampled, the picture is never projected.
- A battle lift number stated on this page: the stack reads look.gd.

Sources: FINDINGS R243 and R240; docs/playbooks/factions.md (Sunward lines, camera 170 rule); RECIPE stack section; the Hullbreaker and Eclipse LAYERS as worked form; S8 chair samples; godot/fx/faction_looks.json (voidsworn).
