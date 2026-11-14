# Glasswrights: paint direction (issue 689, R243)

Status: direction for Ryan's yes or no at the swatch review. No stack is built from this page until he rules.
Ruling answered: FINDINGS R243 (Ryan, Nov 13, 2026): "glasswrights shouldn't have any panels but be more like blown glass." Hull order follows lore: a leaf of cut glass lit from inside, on a silver spine and rim (docs/playbooks/factions.md; G13 base carried by G15). R192: every part is shaped with care and is also the ornament. R196: lenses are grown in, one continuous skin, no pod, bracket, ring mount or visible seam. Reference picture: G15 (contrib/muse/design/concept_round7_2026_11/ithar_G15_sheet.jpg), shape settled, lenses not reached, so its colours are sampled with two picture artefacts rejected below.
Form: docs/ship_pipeline/RECIPE.md, "The paint stack for sheet ships". CONCEPT pairs are (dark, light) sRGB show-tones; the stack divides by LIGHT_GAIN 1.45 and the battle lift read from godot/render/look.gd. No lift number is stated on this page. Glow colours live in godot/fx/faction_looks.json and are read by the stack, never copied here.
Council: blind Rey, Qwen and Flash legs chaired (DeepSeek covered Sunward only); Grok's seat empty (bot wall). Where the legs split, the summary file records the chair's call.

## 1. Panel shape and order: there are none

No panels, no seams, no rivets, no trim sheet, no decals. In LAYERS terms the whole patch family is switched off: patch_big 0, patch_small 0, patch_over 0, patch_over_share 0, patch_seam 0, seam_dark 0, patch_warp 0, patch_band 0, patch_split 0, plate_var 0, rivets 0, rust 0 in every zone.

What carries the surface instead:

- Glass depth tint by AO. The glass zone's pair runs from its dark end at full AO to its light end at zero AO, so curvature and depth shade the skin the way thickness shades blown glass. No hue is added: the pair itself is the tint.
- Silver structure zones (the spine and the rim) with gradient boundaries, not seam lines: the glass is grown onto the silver (R196), so the transition blends over a short distance and never steps.
- The rainbow fringe on the edge mask, cut edges only, at low saturation. The fringe takes the place of the worked stacks' final step: where other factions run edge wear last, Glasswrights runs the fringe last, over everything.

## 2. CONCEPT pairs

Sampled from G15 by the chair (k-means, 9 clusters, background excluded by corner colour). Pairs are (dark, light):

- glass (the skin): ((134,134,136),(210,209,210)), hex #868688 / #d2d1d2. The light end is a hard cap, not a target: the hull's rendered median should sit at the mid cluster #9d9c9e, and no glass pixel should pass #d2d1d2 before the LIGHT_GAIN and lift conversion. This is the E11 lesson written as a number: the unpainted E11 blew out glowing white in game, and the hot clusters here (#f4f3f3 at 8.4 percent, filter hot #fcfcfb) are specular catches in the picture, not albedo. Painting them is how a silver ship goes white.
- silver (spine and rim): ((109,107,110),(182,181,183)), hex #6d6b6e / #b6b5b7. The bright filter mean #c7c6c8 is a catch tone for the rim's brightest edge only, never a field tone.
- liner (interior): ((26,26,30),(42,42,48)), hex #1a1a1e / #2a2a30. The one liner that is not near-black, because light lives inside this hull; still dark, with a faint cool tint. The core keeps its light.
- optic (bow lens and stern optic, at rest): the game's ithar colours, read from faction_looks.json; the plate-side seat is clear glass over the silver pair.

## 3. ZONES notes

- glass: roughness base .12 with rough_floor .30 and rim_soft on, so the rim light breaks into fringe sparkle instead of a white flare. If the builder's probe still flares at a .30 floor, raise the floor first (test .32, then .34), then dim the fringe; never raise the CONCEPT light end. metalness 0.0.
- silver: rough .36, rough_floor .34, metalness .75 (polished silver, not chrome).
- wear .15 on the silver only, as faint polishing; the glass does not scuff, and a cracked Glasswright hull is breach geometry, not a paint layer. grime .10, in the deepest AO recesses only. scuff .03, a handling haze on the rim.
- rust 0 everywhere (guide: never rust, smoke, flame).

## 4. Trim and wear

There is no trim and there are no applied marks of any kind: no trim sheet, no decals, no stencil marks, no rivets. The ornament is the shape itself (R192). If the game later needs identification on these hulls, it must be carried by the glass shape or the pattern of the stored light, not by paint; that question is carried to the summary.

## 5. Lights and glow

- Stored light: the core glows deep inside the glass in the game's ithar engine colour, read from faction_looks.json. The stack multiplies the core's show strength by glass depth, so the light reads dimmed and deep (about 0.60 to 0.70 of threshold at the surface), never as a bare bulb.
- The bow optic at rest is a clear lens with a faint gleam (core about 0.78, just under threshold); the prism lance at full strength is the game's weapon colour when firing. The rainbow fringe rides the optic's cut edge.
- The stern optic is a soft white bloom at about 0.72, diffuse, no flame (guide).
- No running lights: the stored light is the ship's light, and it is structural, not applied.

## 6. Camera 170 read

One silhouette: a leaf of cut glass on a silver spine. One main colour: silver, the lightest hull in the game, held to the value rule above so it reads silver and never white: at the battle lift, the hull's median pixel sits in the silver and glass pairs' band, around #9d9c9e, never at #f4f3f3. One accent light: the stored light glowing deep inside. The fringe is a close-up bonus and is not expected to read at 170.

Checks for the builder: surface check at stage 5; camera 170 read with only the CONCEPT pairs and the stored light, nothing else, to prove the silhouette carries it; value cap audit (glass output never above #d2d1d2 pre-conversion); rim flare probe at the .30 floor before any full paint; emissive audit.

## 7. NOT ADOPTED

- G15's brass fittings (filtered mean #8c714d, about 3.2 percent of the picture): rejected. The guide says polished silver, and R196 forbids the brackets and mounts the brass belongs to.
- G15's coloured panes (green, violet, amber fills, about 5 percent of pixels): rejected. The guide says clear glass with a rainbow fringe on cut edges; the colour lives on the edge, never as a pane fill.
- Panels, seams, rivets, a trim sheet, decals: rejected by R243 and R196.
- #f4f3f3 and #fcfcfb as surface tones: specular catches, not albedo; see the value cap.
- Rust, smoke, flame, wings, petals, sails, crystal shapes: rejected by the guide.
- A battle lift number stated on this page: the stack reads look.gd.

Open for the builder and the Board: the roughness floor probe (.28 / .30 / .32) result decides whether .30 stands; the lens build must keep R196's no-seam rule or this page's no-seams direction is violated upstream of paint.

Sources: FINDINGS R243; R192 and R196 as carried in docs/playbooks/factions.md; factions.md (Glasswrights lines, camera 170 rule); RECIPE stack section; the Hullbreaker and Eclipse LAYERS as worked form; G15 chair samples; godot/fx/faction_looks.json (ithar).
