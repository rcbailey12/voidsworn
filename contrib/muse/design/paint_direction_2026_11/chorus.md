# Chorus: paint direction (issue 689, R243)

Status: direction for Ryan's yes or no at the swatch review. No stack is built from this page until he rules.
This page translates the settled Chorus paint pack (issue 670, contrib/muse/design/chorus_paint_2026_11/pack.md, delivered and merged Nov 13, 2026) into the stack form of docs/ship_pipeline/RECIPE.md. It re-opens nothing: every colour, floor and rule below is the 670 settlement restated in CONCEPT, ZONES and LAYERS terms. Ruling answered: FINDINGS R243 (Ryan, Nov 13, 2026): surface order follows faction lore, and Chorus is grown, no plates. Guide: something vast and eyeless that was grown as a weapon; dark olive-brown hide, ochre bone and chitin, bile yellow-green light from inside (docs/playbooks/factions.md). R204: the C10 and C11 pictures came out greyer than the faction, and colour is set in the build, not by more picture rounds.
Form: CONCEPT pairs are (dark, light) sRGB show-tones; the stack divides by LIGHT_GAIN 1.45 and the battle lift read from godot/render/look.gd. No lift number is stated on this page. Glow colours live in godot/fx/faction_looks.json and are read by the stack, never copied here.
Council: blind Rey, Qwen and Flash legs chaired (DeepSeek covered Sunward only); Grok's seat empty (bot wall). The legs agreed this page is a translation; the chair restored the 670 numbers wherever a leg's stack sketch drifted from them (see the summary).

## 1. Panel shape and order: grown, no plates

There are no plates. The shared stack's patch machinery is reused as hide mottling cells: soft tonal cells that blend into each other, warped organically, with furrows coming from AO, never from seam lines. patch_seam is 0 and there is no seam layer. Where a built hull has seams, Chorus has scar furrows: a separate line layer of irregular paths (width about .0016), colour #35301f, deepened by AO rather than painted dark, with a regrowth halo of #6b6036 two to three pixels wide beside each furrow. If the stack's seam code can only draw straight lines, Chorus gets its own furrow layer; the builder confirms which (open question, below).

Symmetry rule (guide): the base mottling and hide tone are symmetric where a body would be; scars and regrowth are asymmetric, applied after the symmetric base.

LAYERS (Chorus, mottling translation):

- patch_big (.065,.045,.035), patch_small (.028,.020,.016): mottling cells, not plates.
- patch_over (.080,.055,.045), patch_over_share .12: overlapping cells for depth.
- patch_seam 0, seam_dark 0.
- patch_warp .55, patch_band 1.6, patch_split .50: the warp value is the one whose behaviour is proven in the shared stack (Hullbreaker's); on soft-blending cells it reads gentler than on plates.
- plate_var .55, island_tone .70, mottle full (the primary texture), grain .30 at the 670 grain scale.
- rivets 0, rust 0, metalness 0.0 in every zone.

## 2. CONCEPT pairs

The 670 hexes, exactly. Pairs are (dark, light); single-tone zones repeat their tone.

- hide: ((55,51,31),(87,80,58)), hex #37331f / #57503a, with the cells centred on the settled main tone #423d27. The dorsal fields sit in the pair's lower half toward the old dorsal tone #37331f; the belly fields use the belly tone #57503a as their light end.
- mottling band: ((74,67,42),(94,86,53)), hex #4a432a / #5e5635.
- membrane: #5c5536, single tone.
- chitin: #a37f36, single tone.
- bone: #bda05c, single tone.
- scar furrow: #35301f, single tone. Regrowth: #6b6036, single tone, a separate zone from the furrow, never blended into it.
- liner: #16170f, single tone. The core keeps its light.

## 3. ZONES notes (the 670 settlement, restated)

- Roughness ranges with floors, per tissue: hide .62 to .80, floor .60; membrane .45 to .60, floor .42, with rim_soft on; chitin .60 to .82; bone .72 to .88; scar .80 to .90; regrowth .58 to .70; liner .90. Metalness 0.0 everywhere.
- Layer order: base tones, patchwork (mottling) cells, seams and recesses (here: furrows and AO recesses), grime (#2a2820 at 12 to 18 percent), decals (skipped, Chorus carries none), abrasion last, emissive on a separate pass.
- Membrane is opaque in the atlases; translucency is faked by dimmed emissive (0.4 to 0.6 multiplier) behind thin membrane, per 670.
- Wear is biological: abrasion and scar tissue, not scuffing. There are no directional scratches.

## 4. Trim and wear

No trim, no decals, no markings: everything on the surface is tissue. Wear is the scar and regrowth layers (670: four to six scar bands, three regrowth patches proposed there and carried as an open question below).

## 5. Lights and glow

- Bile light in the 670 steps: deep #77811f at 30 to 40 percent of the game's 0.8 glow threshold, mid #9dab2c at 55 to 65 percent, hot core #c2cf45 at 85 percent. The hottest spot on the ship stays at 85 percent post-lift. The game's chorus engine colour is read from faction_looks.json; these hexes are the plate-side steps the 670 pack settled.
- Behind membrane, the emissive is dimmed by the 0.4 to 0.6 multiplier before it is compared to those steps.
- No running lights: the bile glow from inside the body is the ship's only light.

## 6. Camera 170 read

One silhouette: a vast, eyeless, grown mass. One main colour: dark olive-brown hide. One accent light: the bile lights glowing from inside, faint luminous patches, never sharp. Chorus is the darkest hull in the game; at 170 the mottling, scars, chitin and bone are all close-up bonuses.

Checks for the builder (the 670 union, carried over): surface check at stage 5; camera 170 read; the lift test (a hue shift over 8 degrees or a value rise over 15 percent after the battle lift fails); roughness floor and specular clamp per tissue; glow step audit against the three bile steps; cold-spare check; metalness audit (0.0 everywhere, no exceptions).

## 7. NOT ADOPTED

- C10's orange inner glow (filtered mean #dc7c18, hot #faae39): rejected by R204 and the 670 settlement. Bile is yellow-green.
- The C10 and C11 pictures' grey-brown values as colour authority: rejected by R204; the samples confirm the value range only, never the hue.
- Metal of any kind, red or magenta flesh, eyes, legs: rejected by the guide.
- Plates, seams, rivets, trim: rejected; grown, not built.
- Any re-derivation of the palette from the pictures: rejected; 670 settled it on Nov 13, 2026.

Open questions carried from 670 for the Board (unchanged): membrane transmission in the renderer versus the dimmed-emissive fake; the sealed sac glow default; scar trim sheet scope and variant count; the membrane pulse boundary (static stack gradient versus game VFX); breach interior detail beyond the liner; grain scale by class. New from this translation: whether the stack's seam layer can draw irregular furrow paths, or Chorus needs its own furrow layer.

Sources: issue 670 pack (contrib/muse/design/chorus_paint_2026_11/pack.md); FINDINGS R243 and R204; docs/playbooks/factions.md (Chorus lines, camera 170 rule); RECIPE stack section; godot/fx/faction_looks.json (chorus); C10 chair samples (value cross-check only).
