# Chorus paint design pack: hide, chitin, membrane and inner light

Issue 670. Council: blind Rey, DeepSeek, Qwen, Flash (all legs per R231; Grok's seat is empty, its window was blocked by grok.com's bot wall on two attempts, recorded here rather than filled). Chaired by Rey. The colour and material sheet is `colour_material_sheet.jpg` beside this file: a grown hull in the settled palette over the nine material swatches. The sheet is illustrative; the hex table in section 1 governs (one swatch, the regrowth patch, renders pinker than the spec allows; regrowth stays tan-olive, never pink).

This pack is what the Chorus stack builder works from: `tools/blender/kits/chorus/stack.py` on the shared machinery (`tools/blender/kits/shared/paint_stack.py`), written once for the faction. Ships opt in with `"bake": "stack"`; the sheet's materials say where each zone sits. Everything here follows the binding paint method (ships.md section 0 item 2): procedural materials from masks baked from the ship's own geometry, colours sampled from the concept, the concept picture never projected, nobody paints by hand.

## 1. Colour zones

Hexes are albedo starting values, sampled from the faction colour notes and the accepted concepts (the C10 and C11 renders came out greyer than the faction colours; per R204 the build works from the faction notes, not the grey renders, and one leg's question on that point is answered by the standing rule). Every tone is judged under the Chorus battle lift (section 5), never at albedo.

| Zone | Hex | Where it sits, and what drives it |
|---|---|---|
| Hide, main | #423d27 | The dominant hull surface: dorsal, lateral, tail. The one main colour at camera 170. Base zone mask at low-to-mid curvature; kept off sharp ridges and deep creases by the curvature mask. |
| Hide, old dorsal | #37331f | The spine line, crown mounds, the oldest growth toward the stern. Vertical gradient mask, dorsal side. |
| Hide, belly | #57503a | Lower flanks, under-mouth, undersides of sacs and trailing membranes' roots. The same gradient mask, ventral side; warmer and paler than the dorsal hide. |
| Hide, mottling range | #4a432a to #5e5635 | The patchwork (section 4): many small irregular hide cells, each its own tone inside this band, driven by geometry islands plus a low-frequency blotchy noise mask, seeded per ship. Never fine grain. |
| Membrane | #5c5536 | Trailing drive membranes, vent linings, throat walls past the sphincter, the thin skin over brood sacs. A membrane-thinness mask baked from surface-to-surface distance; where the wall is thin, this zone overrides hide. |
| Chitin | #a37f36 | Ridges, spines, hooked tendrils, spine rings around throats, spine-gland clusters, vent rims. High convex curvature plus the part-kind tag from the manifest. |
| Bone | #bda05c | Paler and drier than chitin: exposed structural bone at breach rims, mouth-ring structure, joint-like hard parts. Bone zone mask plus high convexity. |
| Scar furrow | #35301f | Old tear lines and healed breach seams: dark, dry furrows with a raised lip in the detail normal. Placed by build-sheet scar annotations as decal strips; irregular, never straight. |
| Regrowth | #6b6036 | New tissue over old damage: shoulders and flanks (C13's ragged shoulder patches are the type case), re-sealed sac boundaries. Soft feathered mask (falloff over 8 to 12 texels); the boundary is carried by tone and roughness shift, never a drawn line. |
| Inner light, deep | #77811f | Emissive only, never in the albedo atlas. Deep in throats, low-activity organs, glow seen through thick tissue. |
| Inner light, mid | #9dab2c | Active vents, gland walls, throat walls grading outward. |
| Inner light, hot core | #c2cf45 | Small cores: the bile gland's centre, the middle of an active vent. Brightness, not size, carries the read. |
| Insides liner | #16170f | Every interior face: throat chambers, sac interiors, vent channels. One liner material per room, faint olive tint; the core keeps its own light. |

## 2. Material character (the ORM story)

Metalness is 0.0 on every Chorus surface, without exception; the metal entry in look.gd's Chorus line is a shader parameter, not licence to paint metal. The stack bakes albedo, ORM and a detail normal, and every painted surface is flagged rim_soft (soft rim light, 0.25 of specular). Roughness is the wetness channel; there is no separate wetness map.

| Tissue | Roughness | Wetness and mask behaviour |
|---|---|---|
| Hide | 0.62 to 0.80, floor 0.60 | Matte with a faint oily sheen. AO deepens folds and root pits (roughness up, tone down); broad convex swellings ease roughness slightly for the wet sheen the C10 sheet assigns to paint. Detail normal: fine wrinkle grain running along the body, low strength (0.3 to 0.5), plus fold lines from curvature. Mottling cells vary roughness by about plus or minus 0.04. |
| Membrane | 0.45 to 0.60, floor 0.42 | The wettest tissue. The thinness mask drives roughness down where the wall is thinnest; AO influence is reduced about 40 percent so thin skin does not read muddy. Detail normal: fine radial wrinkles. The floor is the specular risk on this faction, so rim_soft must be confirmed on every membrane surface (check 4). |
| Chitin | 0.60 to 0.82 | Dry, hard. AO is strengthened (about 1.2x) in ridge grooves and spine bases to seat the ridges. Abrasion (section 4) lightens crests toward bone and eases roughness to about 0.50 on the worn face only. |
| Bone | 0.72 to 0.88 | Driest tissue. Porous grain in the detail normal; no wet sheen anywhere. |
| Scar furrow | 0.80 to 0.90 | Dry and furrowed; its own decal normal (furrow ridges, cracked lines). |
| Regrowth | 0.58 to 0.70 | Smoother and wetter than scar: new, not-yet-hardened tissue. The wrinkle grain is interrupted across it and the normal goes lumpy and low-frequency; that interruption is what sells regrowth at close cameras. |
| Liner | 0.90 | Flat matte; reads as shadow with a faint colour. Any wetness or light inside a cavity comes from the organ, not the liner. |
| Inner light | not applicable | Emissive surfaces bypass the ORM; the surrounding throat wall or vent rim carries its own tissue values. |

## 3. The inner light system

Where it shows: the bile gland deep inside C10's double throat, past the sphincter; active engine vents (C10 siphons and tail vents, C13's trailing membrane drive vents, C11 engine parts); the pore rosettes at the tips of C10's five spore gland necks; thin membrane over active brood sacs; a faint graded glow along trailing membrane edges; and light visible through any breach or open birth slit.

How it varies, so it never becomes the flat neon Ryan named on the Eclipse line ("plain and stark, just like neon paint" is the failure state):

- Every lit organ is its own emissive mesh with its own material instance: base brightness 0.6 to 1.0 of the faction ceiling, hue offset within plus or minus 4 degrees of the bile band (a rosette may lean a touch greener, a vent a touch more yellow), and a baked gradient.
- The gradient runs from the hot core at the deep point or centre out to the deep bile at the edges, with two or three uneven hot spots placed by a per-organ noise seed, and darker streaks down throat walls (the engine throat rule restated for a gland).
- Depth: glow seen through membrane is dimmer and more diffuse than glow seen directly. The thinness mask multiplies emissive intensity by 0.4 to 0.6 where membrane covers the source, so the light reads as coming from inside the body.
- Between ships: per-ship seeds drive hot-spot placement and hue offsets, so C10's nine sources never match C12's or C14's arrangement.

Brightness discipline under lift 1.9: the faction emissive ceiling is set so the brightest hot spot, after the Chorus lift, sits at 85 percent of the game's glow threshold (no halo); mid glow sits at 55 to 65 percent; deep glow at 30 to 40 percent, barely a suggestion in a dark throat. Every emissive material is tested under the Chorus READ entry before the stack ships; anything that clips or blooms gets pulled down at the base value.

The boundary with the game: the stack paints the static, graded emissive surface. The pulse, the thrust flare and any animated brightness are the game's effect layer on top, exactly as engine glow is the game's on the metal factions. The paint never fakes a glow.

The cold-spare rule for flesh: the build sheet marks each organ active or dormant, and the stack assigns emissive only to active ones. A dormant sac, a cold siphon, a spare vent and a closed throat stay dark hide, dark membrane or liner. Only a lit organ glows.

## 4. Seams, wear and the patchwork on a plateless body

What replaces plate seams:

- Fold lines: the primary seam equivalent. Where hide bends (mouth lips, flank joints, tendril and gland-neck bases), AO-driven creases darken toward #2c2a20 with a roughness increase, staying matte and shadowed.
- Ridge boundaries: where chitin meets hide, a thin dark line (#2e2c22) at the curvature boundary seats the ridge.
- Scar seams: dark furrows with a raised lip (section 1), following the sheet's scar annotations.
- Regrowth boundaries: feathered tone and roughness transitions, never a line.
- Organ rings: a darker ring where a sac, gland or vent housing meets the hull.

What replaces panel cells (R228 item 1 restated for flesh): the hide is divided into biological regions by the geometry itself (dorsal, lateral, belly, neck, tail, mound, tendril bases, and each part's own island: brood, engine, gun, thruster). Each cell takes a slight tonal variation inside the mottling band (about plus or minus 3 to 5 percent value, plus or minus 2 degrees hue), seeded per cell, with the low-frequency mottling noise inside it. Density follows the concept: large blotches on C10's broad flanks, tighter and more irregular on C13's lumpy hide. Scar and regrowth patches break the cells further as damage patchwork.

What replaces edge wear: abrasion on chitin crests, spine tips and tendril hooks (lightening toward bone, roughness easing on the worn face); fold-crease compression (darker, micro-cracked normal at the tightest folds); membrane abrasion where membranes rub hide (roughness up, translucency read down); tear edges at breach anchors and birth slits (a dark, wet rim at roughness about 0.50 with a thin emissive bleed where the inner light leaks out).

Layer order for the Chorus stack: base tissue tones; hide patchwork cells and mottling; seams and recesses (folds, ridge boundaries, scar seams, AO); a grime pass over everything (dark olive #2a2820 at 12 to 18 percent, settling in folds, around spine bases, under sacs); decals (scar strips, tear edges, regrowth patches placed as decals); abrasion last. Emissive surfaces stay separate throughout. There is no decal trim content for this faction beyond the scar strips; identity marks are grown, not applied.

## 5. Judged under the Chorus lift

The Chorus READ entry in godot/render/look.gd: lift 1.9 (the strongest of any faction), rim 0.45, rim_tint 0.55, emit 1.0, spec 0.5, with rim_soft on stack surfaces. The lift test is a stack check, not a hope: render the painted ship under this entry; if any zone's hue shifts by more than 8 degrees or its value rises by more than 15 percent against the faction note, the base albedo comes down until the post-lift result matches. The known lift traps, restated for flesh from R227 and R228: hide washing out to the grey-green of the C10 and C11 concept renders (the exact failure R204 already flagged in those pictures), bile blowing out to white-yellow, and any warm tone drifting pink. Rust turning pink on the Hullbreakers is the same lesson: tones are picked post-lift.

## 6. The lessons, restated for flesh

1. Patchwork density (R228 item 1): many small units, each with its own tone, driven by cells and the parts' own islands. For flesh: hide mottling cells and biological regions, not plates (section 4).
2. Contrast (R228 item 2): dark seams and recesses, brighter worn points, never flat at camera 170. For flesh: fold lines and AO against abraded chitin crests and the bile points.
3. Judge colour under the lift (R228 item 3, R227): the pink-rust and lavender failures both came from judging at albedo. Section 5's tolerance is the guard.
4. Brightness, not size (R228 item 4): the inner light reads as points, slits and deep cores at battle size; keep it under the glow threshold so there is no halo (section 3).
5. The game owns the glow's motion (R228 item 5): the stack bakes one graded emissive state per organ; pulsing and flares are the game's layer. The painted throat varies (hot core, grading, hot spots, streaks), each organ its own.
6. Roughness floor: no white specular glare at the key light. On Chorus the risk surface is membrane, not metal; the floors in section 2 plus rim_soft carry it.
7. Grime over everything, and no salt-and-pepper: the grime pass is in the layer order; every noise mask in this pack is low-frequency and blotchy.
8. Only a lit organ glows: the cold-spare rule, section 3.
9. A zone the stack has no colour for gets one in the faction stack, sampled from the beauty that shows it, with the method written beside the sample. If a Chorus sheet brings a new tissue, it lands in section 1 of this pack by the same route.
10. The Eclipse lesson (R235, R237): inner light with no grading, depth or variation reads as neon. Section 3's per-organ gradients, hot spots and membrane dimming are the direct answer.

## 7. Never list

No metal and no metalness above 0.0 anywhere. No red, magenta, pink or violet in any zone, including scar, regrowth, grime and damage tints (scorch at a tear is dark brown-black; any fluid the paint implies is dark bile-green). No flat single-colour emissive. No regular grid, repeating segment pattern or plate-like cell structure in the mottling. No salt-and-pepper grain. No projected concept picture. No painted fake glow. No white specular glare. No liner colour visible from outside, and no outside surface without a stack material. Nothing in the paint may suggest an eye, a face, legs, or a cute or grub-like read.

## 8. Checks the stack builder runs

1. Surface check (stage 5, standing): fails on any pixel of liner or room colour seen from outside, or any outside surface with no stack material. For Chorus it also proves the liner covers the double mouth, sphincter chamber, vent channels and sac interiors.
2. Camera 170 read: one silhouette, one main colour (olive-brown hide), one accent family (ochre chitin and bone), bile glow points visible but never overpowering the hull. Catches flat hide, over-busy mottling, mis-scaled glow.
3. Lift test (section 5): hue shift over 8 degrees or value rise over 15 percent on any zone fails it. Catches the grey washout and the pink drift before Ryan sees them.
4. Roughness floor and specular clamp: no ORM pixel under its tissue floor; no specular highlight over 70 percent white under the key light; rim_soft confirmed on every membrane surface.
5. Glow threshold: every emissive surface measured post-lift against the section 3 percentages, and verified non-flat (a gradient and at least one hot spot each).
6. Cold-spare verification: every organ the sheet marks dormant renders with zero emissive.
7. Metalness audit: the baked ORM atlases sampled; the metal channel is zero everywhere.

## 9. Open questions for the Board

1. Membrane translucency: this pack fakes it inside the opaque atlas machinery (dimmed emissive behind thin membrane, section 3). If the Board wants true transmission or sub-surface on membrane, the shared machinery needs an extension; that is a Board call before the stack is written.
2. Sealed sacs: the pack's working rule is that a sac the sheet marks active shows dimmed glow through its membrane and a dormant one stays dark. For C10's six sacs the sheet does not yet mark states; the Board should confirm the default (the pack assumes active sacs glow faintly, because the faction note says the body is lit from inside).
3. Scar trim sheet: scars are placed from sheet annotations as decal strips. Does the Chorus kit get its own scar trim sheet (the legs propose four to six scar-band variants and three regrowth-patch variants), and do C13's lumpy asymmetric scars need unique strips or the shared set under different seeds?
4. Membrane pulse boundary: the pack gives the stack the static gradient and the game the pulse, by the engine rule. Trailing drive membranes are the one place the glow sits on a moving surface; the Board should confirm the same boundary holds there.
5. Breach interiors: at breach anchors the pack gives liner plus the tear-edge treatment plus the organ's light. If the Board wants modelled interior flesh and bone detail at the big ships' extra breach anchor, that is modelling scope the stack builder needs named before materials are assigned there.
6. Grain scale by class: should wrinkle grain and mottling density scale with hull size (C10 at 28 units against the frigate classes), or stay at one world-space density across the faction? The pack assumes world-space density (one scale, so small ships read finer), but the Board should confirm.
