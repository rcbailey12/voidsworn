# Round 4 image prompts, issue 468

Built-in `image_gen.imagegen` only. No exact backend model ID is exposed. All 21 successful calls are recorded below in ship order. Each sheet used its named reference first; corrections used the preceding sheet; beauties used the selected sheet. H7's first orchestration attempt failed before calling the image tool because a prompt-list value was not yet available; it produced no image and is not counted as a generation try.

The C19 WEBP was converted to RGB PNG at `%TEMP%/issue468_C19_51.png` solely for image-tool input. Pillow performed format conversion and final resizing only. No artwork was drawn or retouched in code.

## Sunward

### S7

Inputs:
- `contrib/codex/design/concept_round2_2026_11/voidsworn_S1b_sheet.jpg`
- `contrib/codex/design/concept_round2_2026_11/voidsworn_S1a_sheet.jpg`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-6fa68ad3-06f9-457e-a69a-99379af82312.png`

```text
Edit target image 1 is S1b, image 2 is S1a supplying heavy gallery guns only. Make the final Sunward S7 design sheet. Precisely preserve S1b's black iron dagger, giant forward lance, ember organ-pipe radiator bank, low command block, two engine bells and four small twin-barrel flak turrets arranged as two symmetric pairs. Replace ONLY both broadside batteries with S1a's SEVEN short thick heavy barrels per flank, one ordered recessed gallery each, dark ports. Top view above and exact flat orthographic side view below, bow RIGHT, equal horizontal scale, plain dark grey, no text. Pixel design target on 1536x1024 canvas: each ship 1440 px long, top beam 288 px including guns, side height 202 px including radiators. Same ship in both projections, two port-side flak silhouettes in side view where far pair overlaps. Lance forward, galleries straight outward, flak forward. Low single command and sensor patch. Retain all other design features, no new guns, no naval details. Heavy visible barrels must read at 384px thumbnail.
```

### S7try2

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-6fa68ad3-06f9-457e-a69a-99379af82312.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-33847957-0c89-4446-951e-352f1c6abeef.png`

```text
Precise correction of this S7 sheet, all else unchanged. It FAILS counted weapons: TOP currently has SIX gallery barrels per flank, needs SEVEN. SIDE currently has THREE flak silhouettes, needs TWO. Correct both projections: seven identical short THICK heavy barrels in the upper-edge gallery and seven in lower-edge gallery in top; seven dark heavy muzzles in side. FOUR total small twin-barrel flak turrets in top, exactly the existing two symmetric pairs, and exactly TWO side silhouettes because far-side pair occludes behind near-side pair. Delete the extra forward side flak. Retain lance, command block, iron dagger hull, orange organ-pipe radiator bank, two side-by-side engine bells, existing proportions, same flat top-above-side-below bow-right grey-background no-text layout. No third row or extra gun.
```

### S7beauty

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-33847957-0c89-4446-951e-352f1c6abeef.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-a1e457fe-ddd6-4e5b-bb69-9173b5655d07.png`

```text
Use case stylized-concept. Make Sunward S7 beauty view from this accepted design sheet, preserve exact ship and mounts. Three-quarter FRONT and ABOVE camera, see top, forward lance and near broadside and two engine bells at stern, near-black space, restrained cinematic light, no text. Hero is long black iron dagger with ember organ-pipe radiator bank aft, low command, chalk scratches, enormous forward lance. Precisely SEVEN short THICK heavy gallery barrels each flank, dark ports, four small TWIN-barrel flak turrets in two symmetric pairs on top, no other guns. Retain proportions about 5:1:0.7. Exactly ONE separate smaller escort nearby at 35 percent hero length: same black iron/ember/chalk grammar, different simpler narrow spearhead hull with one forward lance, short radiator bank, one engine and only THREE near-side gallery barrels, no four-turret array. Escort is not a miniature copy. Hatch/rivet sizes same physical scale so hero has many more plates and rivets. Hero fully in frame, no firing, no other craft or planets.
```

## Hegemony

### H7

Inputs:
- `C:/Users/rcbai/Downloads/voidsworn_test/board/repo/contrib/muse/design/concept_round3_2026_11/hegemony_H5_sheet.jpg`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-f82f3b6f-a196-42b8-80f7-98c114920a1c.png`

```text
Use case stylized-concept. Reference H5 supplies exact wedge-forward, twin-rail-aft plan only: REDRAW with bow RIGHT. Make Hegemony H7 orthographic design sheet, top above, side below, same scale, dark grey, no text. 1536x1024 canvas, target solid ship extents 1400px long, 311px beam including guns, 156px side height. Pale machined grey wedge bow whose backbone forks aft into two parallel modular rails joined by low bridges, one clearly dark hangar door between rails, FOUR distinct stern engine blocks, two per rail, rectangular blue-white apertures together about 40 percent of stern. Precisely two heavy turbolaser turrets, port/starboard mirrored on wedge shoulders, each long twin barrels aimed directly OUTWARD, not aft. Two thick ion weapon prongs project forward from bow. ONE small flak turret on upper centreline. All muzzles dark. Strong visible ordered weapons at thumbnail. Cure plainness using panel breaks, recessed maintenance trenches, low sensor array beside ONE low command block, repeated small hatch rows at constant scale, darker blue-grey accent panels, fine continuous implant-blue light along both rails and every module joint. Three transverse module seams are break lines. No extra weapons, no aircraft fins, no mast, no warm light or rust. Top and side geometrically consistent; far-side turret overlaps near-side turret in side projection. Real detailed surface but clear silhouette.
```

### H7try2

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-f82f3b6f-a196-42b8-80f7-98c114920a1c.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-f55e16e5-161b-4701-a98a-395fe3971016.png`

```text
Correct this H7 orthographic sheet ONLY where projections and weapon arcs fail. TOP: rotate port heavy twin turret barrels 90 degrees outward toward TOP edge of canvas and starboard heavy twin turret barrels 90 degrees outward toward BOTTOM edge. Both guns fire directly away from hull, not forward or backward, keep turrets mirrored. SIDE: these outward guns are viewed END ON, one near turret with two dark round muzzles, far turret fully occluded behind it. Engines: FOUR blocks are horizontally side by side on stern, TWO per rail, NOT stacked vertically. Thus top retains four engine rectangles, strict side shows ONE overlapping stern engine block silhouette, not two stacked engines or rails. ONE flak turret must occupy same fore-aft position in both projections, around x=950. Give flak two visible small barrels rather than silver balls. Add ONE low command block and adjacent flat sensor patch around x=1080, keep below turret height. Preserve wedge and separated twin rails, one dark hangar doorway between them, detailed pale/blue-grey panels, blue lines at joints, bow RIGHT, top above side below, grey backdrop, no text. Target 1400px long, top maximum beam 311px (including outward barrels), side overall height 156px. No other weapons or aircraft fins.
```

### H7try3

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-f55e16e5-161b-4701-a98a-395fe3971016.png`
- `C:/Users/rcbai/Downloads/voidsworn_test/board/repo/contrib/muse/design/concept_round3_2026_11/hegemony_H5_sheet.jpg`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-e3506de0-a4d7-4f1f-b378-d6a291b4d8a5.png`

```text
Final H7 correction, bow RIGHT. Image 1 has correct outward twin turrets and detailed wedge; KEEP those. It FAILS twin-rail/engine layout: remove centre engine tongue and central aft hull. Restore TWO separate parallel aft rails with an EMPTY GAP between exactly as reference image 2, only two narrow crossbridges. Place FOUR engines at LEFT STERN as TWO blocks on end of upper rail and TWO on end of lower rail. No engine at centreline, no third rail. One dark hangar DOOR in forward wall of gap, not a long third rail. Strict SIDE projection must show ONLY ONE rail and ONE engine silhouette, because all four blocks are side-by-side laterally, NOT two vertically stacked rails. Keep two heavy twin turrets pointing outward in TOP and ONE end-on turret in SIDE. Widen body relative to gun length: total length 1400px, total top beam including barrels 360px, side height 156px. Shorten both heavy barrels enough to fit beam but they must remain long twin barrels. Preserve single forward ion prong pair, one flak, low command, sensor, pale grey/blue-grey armour, blue light each joint, dark mouths, no text, dark grey background, top above side below equal scale.
```

### H7beauty

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-e3506de0-a4d7-4f1f-b378-d6a291b4d8a5.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-84d16301-98fe-4f4d-91c6-a461168e4ff1.png`

```text
Hegemony H7 beauty from selected reference sheet, use TOP view as authority for fore-aft component positions. Three-quarter FRONT ABOVE, bow in right foreground, show entire wedge and twin rails behind it, near-black space no text. Preserve detailed pale machined grey, blue-grey accent panels, recessed trenches, tiny constant-scale hatch rows, blue light strips along rails and joints. Exactly TWO outward-pointing heavy TWIN turbolaser turrets on wedge shoulders, ONE pair thick forward ion prongs at bow, ONE small twin-barrel flak near centreline x about900 as TOP shows, ONE low command/sensor ahead of flak. TWO parallel aft rails, EMPTY gap, one dark hangar door at FRONT of gap, FOUR engine blocks two per rail at rear, no central engine tongue. Guns dark ports, no firing. Exactly ONE smaller distinct escort beside hero at one-third length: short single-spine modular wedge frigate, two hull modules, one small twin turret, short bow ion prongs, two aft engines, NO twin rails or hangar gap. Same physical hatch/panel/light size on both so capital has more. No extra craft, ornament, warm lights, aircraft fins, sea parts.
```

## Eclipse

### E7

Inputs:
- `C:/Users/rcbai/Downloads/voidsworn_test/board/repo/contrib/muse/design/concept_directions_2026_11/deathless_C.jpg`
- `C:/Users/rcbai/Downloads/voidsworn_test/board/repo/contrib/codex/design/concept_round2_2026_11/deathless_E4_sheet.jpg`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-e779e416-1c93-432c-80ff-ad2fa66bda27.png`

```text
Use case stylized-concept. Create Eclipse E7 Annulus cruiser design sheet. Ref 1 supplies forward-facing broken ring of shade plates and green central core ONLY; ref 2 supplies violet scaled hull material, thin green rim lines and dark stern drive cones ONLY. New coherent cruiser, smaller class than flagship. Strict orthographic TOP above and SIDE below, bow RIGHT, matched scale on dark grey, no text. 1536x1024, target each ship 1400px long, 400px beam, 400px overall side height INCLUDING upright ring (3.5:1:1). Slim real violet-black overlapping-scale hull behind ring, structural spine from stern through hub of ring to large axial doom cannon firing FORWARD through central aperture. Bow ring is UPRIGHT in transverse plane, a circle facing RIGHT, not a horizontal hoop, no crescent horns. Its equally spaced broken shade sectors supported by solid radial braces back to hub, thin pale green-white edges, small bright green core at hub, no broad glowing pools. In strict top/side views transverse ring is seen EDGE ON as one narrow segmented crossbar at bow, never face-on circle. Ring should NOT hide turret barrels: two substantial twin-barrel gauss turrets in order on upper centreline behind ring, barrels aimed diagonally forward and sufficiently elevated to clear ring through its top gap; ONE small sentry turret aft, dark muzzles. Single low command block and one low sensor patch. Three dark drive cones side by side at stern, pale thin exit rims, no flame, aperture group 35 percent stern. Two hull break seams. Symmetric. No extra guns, hangars, skulls, ribs, bone, naval or airplane details. Must read as heavily armed at thumbnail.
```

### E7try2

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-e779e416-1c93-432c-80ff-ad2fa66bda27.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-44b7679f-b417-45d0-b144-2173feb7878d.png`

```text
Correct E7 sheet: FAIL gate 9, current cruiser about 6:1, needs 3.5:1. On 1536x1024 canvas use 1400px ship length, 400px maximum beam and 400px overall side height. Both top and side need the same 400px transverse bow-ring span. Widen real scaled-violet hull too (about 300px), not just ring. Ring remains upright and forward-facing, edge-on as narrow broken segmented crossbar in both strict projections. Preserve broken ring round small green core, heavy forward doom barrel, violet scales and thin green rim lines. Exactly TWO upper centreline twin gauss turrets behind ring. TOP must show gauss barrels straight RIGHT along centreline; SIDE shows them pitched upward sufficiently to shoot OVER ring upper edge. No sideways barrel yaw. One small sentry turret aft. Stern THREE drive cones side by side horizontally: TOP shows three, SIDE shows one overlapping silhouette, not three stacked vertically. One command block, one sensor patch, two transverse break seams. Grey plain background, no text, top above side below, matching horizontal scale, symmetrical. Preserve machinery details and dark ports.
```

### E7try3

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-44b7679f-b417-45d0-b144-2173feb7878d.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-bc5084ee-e8a1-4238-80da-2163c06c0e7e.png`

```text
Final geometry correction E7, keep all materials, weapons, hull, same-scale bow-right orthographic layout. The upright circular ring has inconsistent diameter: top edge-on span about 416px, side about360px. Make BOTH edge-on ring spans 416px, same diameter and segmentation, side crossbar from y=550 to y=966 around core at y=758, top from y=60 to y=476 around core y=268. Keep three horizontal stern engines correctly occluded in side. Preserve two gauss turrets, one sentry, doom F barrel through ring, one command and sensor, two hull seams. Ensure gauss turrets elevated above hull, barrels angled up in SIDE to fire through top gap or over ring; in TOP straight forward right. Ring segments broken by gaps with rim green-white lines; frame supports ring, core small green, no pool glow. No added objects, grey background no text.
```

### E7beauty

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-bc5084ee-e8a1-4238-80da-2163c06c0e7e.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-762c88c5-4c62-4631-965d-0490fb36bc98.png`

```text
Eclipse E7 Annulus CRUISER beauty from selected sheet. Three-quarter FRONT and ABOVE camera that REVEALS circular bow ring face, bow to right foreground, stern left, whole ship on near-black no text. Violet-black overlapping-scale real hull behind an UPRIGHT transverse BROKEN CIRCULAR RING of shade plates surrounding small bright GREEN core. Ring faces forward, is circular rather than crescent, its sectors supported by radial braces to hub; cold green-white only thin rims and small core, no pooled glow. Exactly one massive doom cannon shoots forward through ring centre, two large twin-barrel gauss turrets on UPPER CENTRELINE aft of ring elevated to fire over its upper gap, one small sentry turret aft, one low command and one small sensor patch, three dark stern drive cones side-by-side no fire. Preserve two transverse break collars and about3.5:1 overall length/beam. Exactly ONE smaller distinct escort at one-third length nearby: short fan-plated wedge WITHOUT ring, single gauss turret and small sentry, two drive cones, same violet/green family but fewer parts. Consistent hatch/panel scale between ships. No muzzle flashes, extra weapons, extra craft, floating ring satellites, skulls, ribs, bone, naval details.
```

### E7beautytry2

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-762c88c5-4c62-4631-965d-0490fb36bc98.png`
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-bc5084ee-e8a1-4238-80da-2163c06c0e7e.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-e3980eda-1176-4af1-9ab5-6dbdc936716f.png`

```text
Precise E7 beauty correction. Image1 FAILS weapons: it duplicated the dorsal row onto near FLANK. REMOVE the ENTIRE lower near-side row: both flank gauss turrets, flank small sentry, flank command block and flank sensor. Replace that strip with uninterrupted scaled violet armour. KEEP ONLY the UPPER CENTRELINE row from design sheet image2: two large twin-barrel gauss turrets, one small sentry aft, one command, one sensor. Exactly FOUR total weapon installations on hero counting the doom cannon through bow ring. Keep the broken upright circular ring, doom cannon, green core, thin green rims, three stern cones, all hull shape and ONE escort unchanged. No new ships, no text.
```

## Glasswright

### G7

Inputs:
- `C:/Users/rcbai/Downloads/voidsworn_test/board/repo/contrib/muse/design/concept_directions_2026_11/ithar_B.jpg`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-666bce51-7f03-44e7-91f7-186eb2b91838.png`

```text
Use case stylized-concept. Glasswright G7 Long Prism warship orthographic design sheet, TOP above, SIDE below, bow RIGHT, same scale, dark grey no text. Reference supplies clear glass with light moving inside ONLY, absolutely NOT its broad slab layout nor its many little guns. ONE long THREE-SIDED clear glass prism, triangular cross section one ridge up. The hull IS transparent glass, not grey faceted armour, not a crystal atop a metal hull. Target extents on 1536x1024: 1400px length, 280px maximum beam and 280px side height, about 5:1:1. Three thin SILVER structural beams along long edges, a few narrow silver ribs, warm white flowing light visible deep through transparent glass, rainbow fringe ONLY at glass edges. Silver engine cap at LEFT stern, THREE white drive rings facing aft, arranged triangularly, total apertures about 35 percent stern area. At RIGHT bow, flat optical face ends glass, silver bow collar carries TWO large plain forward-facing pulsar lenses in armoured iris mounts, one port one starboard, together form main forward battery with dark outer irises. Along TOP RIDGE, from bow to stern: ONE large pulsar lens turret in iris mount, ONE distinct conventional heavy gun turret with visible forward barrel and dark muzzle, ONE smaller flak turret, ONE low silver command block, ONE small integrated sensor cluster. Exactly FIVE weapon mounts: two bow lenses, one top lens, one gun turret, one flak. No additional little rail guns. Top and side positions agree; paired bow lenses overlap in side. Large visible weapons and transparent glowing bar identity survive thumbnail. Continuous edge-beam backbone and two narrow collar break seams. Symmetry. No wings, petals, insect shapes, opaque metallic hull, blue-grey facets, flame, smoke, sea details or floating parts.
```

### G7try2

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-666bce51-7f03-44e7-91f7-186eb2b91838.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-a0c25bcc-2158-4d4b-a5d6-1084b69a09ba.png`

```text
Fix G7 geometry, retain clear glass flowing warm-white light and silver materials. FAIL gate 8/9: top is perspective tapered wedge. It must be a LONG CONSTANT-SECTION TRIANGULAR PRISM, not pyramid, not wedge, no taper. Draw exact ORTHOGRAPHIC top view above: long RECTANGULAR silhouette with three PARALLEL lengthwise silver beams, middle beam is upper ridge, 1400px length x 280px beam. Side below is also a 1400x280px rectangular elevation with same endpoints. End caps same cross section, bow flat optical face, not pointed. Bow RIGHT. Stern LEFT engine cap holds exactly THREE white drive rings in triangular configuration all facing LEFT (their circular faces not visible as face-on circles in orthographic top/side). Top ridge mounts from right bow to left stern: one large lens turret at x=1140 with horizontal forward-facing iris (not upward-facing dome), one heavy gun turret at x=900 with forward dark barrel, one small flak at x=700, low command block x=500, integrated flat sensor x=430. TWO bow pulsar lenses port/starboard on bow collar x=1450, forward facing RIGHT, visible heavy silver iris housings, no extra gun at tip. Lens pair overlaps in side. Exactly FIVE weapons. Keep dark grey plain background no text, internal warm-white light, rainbow on glass edges only. Engine, command, sensor, gun mounts must read as real hardware on thin silver frame around glass, not broad grey hull.
```

### G7try3

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-a0c25bcc-2158-4d4b-a5d6-1084b69a09ba.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-76ee18c3-2e10-4b91-af12-d863f74540b5.png`

```text
G7 final correction. FAIL proportions: current bar is roughly 8:1 instead of 5:1. Make on a 1536x1024 sheet each solid ship length 1400px (x68 to1468), top maximum beam 280px, side maximum height 280px. Shorten horizontal gaps rather than widening weapon mounts. Keep constant-section clear TRIANGULAR prism, one ridge up, three silver longitudinal beams, no taper. Top above side below exact flat ORTHOGRAPHIC, bow RIGHT. Warm WHITE internal flowing light, not orange fire; rainbow only edges. FIVE mounts unchanged in number and ordered from bow aft: two BOW forward-facing pulsar lenses, ONE TOP forward-facing pulsar iris turret, ONE gun turret, ONE small flak turret, then low command and sensor. The top pulsar currently faces upward as a dome, FIX to a heavy iris projector whose optic faces RIGHT forward. Show housing sides in TOP/SIDE, not face-on glowing circle. Bow paired lenses likewise face RIGHT (two housings in TOP, ONE overlapping housing in SIDE). THREE aft drive rings triangular configuration: two lateral lower rings, one upper central; TOP sees two lower plus central upper overlap, SIDE sees two vertical levels with lower lateral pair overlapping, not three vertically stacked. Keep silver cap narrow, no broad metal hull. Dark weapon irises, no additional guns, grey background no text.
```

### G7beauty

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-76ee18c3-2e10-4b91-af12-d863f74540b5.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-02fd87e3-a62f-474c-b449-afad97e1603b.png`

```text
Glasswright G7 Long Prism beauty from this selected design sheet. THREE-QUARTER FRONT ABOVE camera, bow RIGHT foreground, stern LEFT, whole ship on near-black space no text. The body IS one long constant-cross-section THREE-SIDED clear glass prism, one ridge up, warm WHITE stored light flowing visibly inside, silver beams along its THREE edges and a few silver ribs, rainbow fringe ONLY along glass edges. No opaque metal hull, no taper into pointed crystal. Preserve FIVE weapon mounts and order: two large FORWARD pulsar lenses on silver BOW collar (port/starboard, not above/below), ONE large forward-facing pulsar iris turret on TOP ridge near bow, ONE substantial conventional gun turret behind it, ONE small flak turret aft, then one low silver command and sensor. Dark outer irises and gun muzzles; lens centres softly white. THREE white DRIVE RINGS at stern engine cap, one upper centre and two lower lateral. About5:1:1 dimensions, no flame. Exactly ONE smaller DISTINCT escort at one-third hero length: shorter clear triangular prism, two frame ribs, only one bow pulsar lens, one little defence gun, one white stern drive ring; same silver/glass/white-light grammar, NOT capital shrunk. Equal physical hatch/seam size so capital has more hardware. No extra ships, insect shapes, wings, petals, grey crystal armour, tiny scattered guns or metal slab.
```

## Hullbreaker

### A7

Inputs:
- `C:/Users/rcbai/AppData/Local/Temp/issue468_C19_51.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-a247cb9e-b57d-4a50-94e4-2c2c70c56147.png`

```text
Use case stylized-concept. Ashfall Hullbreaker A7 Pyre-Barge flagship, original patched salvage character made a SPACE ship. Reference supplies mismatched massive slab armour, red oxide black iron, welded stepped off-centre hull blocks of differing sizes, big tubes, tanks and drums. Keep that material and patched stacked mass, replace ONLY sea-ship shape and fittings. Bow becomes a BLUNT ram of one salvaged armour plate, flat armoured belly, no boat stem or keel. No mast, funnels, deck rails, cranes, portholes: heat radiators, recessed vents and low listening sensors instead. No yellow olive green camouflage. Orthographic TOP above SIDE below, bow RIGHT, equal scale, plain dark grey no text. 1536x1024 target each ship 1400px long, top beam 400px, side height 360px (3.5:1:0.9). Plan outline emphatically IRREGULAR STEPPED: widths and offsets vary bow, shoulders, midship, stern; one huge salvaged slab on port, several smaller starboard blocks, visibly bolted and welded, soot/rust/steel patches and worn nonverbal marks. NOT tube, NOT tidy rectangle. Continuous strong central structural spine, two chained transverse break seams. Weapons exactly: one bounded rack of MANY SHORT scatter tubes on EACH flank, main rack mounts symmetric aimed directly outward, balanced on thrust axis; heavy torpedo ONE cluster of BIG forward tubes through blunt prow; ONE low flak turret on top, all muzzles dark. Exactly TWO dark HANGAR MOUTHS, one low each flank, distinct from tube racks. Main engines balance: three stern nozzles, big centre and smaller matched pair left/right, combined apertures 40 percent stern. One low armoured command block and one low listening dish/scoop cluster. No extra gun rows. Realistic heavy worn surface and clear weapons from thumbnail top. Side must agree with top, far-side equipment occluded, centre plus side engines overlapping laterally rather than stacked.
```

### A7try2

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-a247cb9e-b57d-4a50-94e4-2c2c70c56147.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-0d54eb53-6ad4-44be-bd61-cce295a6ca57.png`

```text
Correct A7 projections, preserve beautiful original patched red-oxide salvage blocks, irregular stepped silhouette, asymmetrical armour, prow cluster, tanks/drums/chains, one command and sensors, one top flak. TOP: scatter rack at upper edge must be MANY SHORT PARALLEL TUBES aimed UP OUTWARD to page top, rack at lower edge aimed DOWN OUTWARD to page bottom, so see tube SIDES from above, not faces opening at viewer. Exactly one rack each flank, no new guns. Two hangars are SIDE doors, not roof pits: remove both rectangular top-facing black pits and show one dark side-facing bay mouth at each outside hull edge, near aft shoulder, not behind a scatter rack. SIDE: one near-side hangar mouth and one near-side scatter rack muzzles viewed end on, far side hidden. Engines THREE laterally side by side: big centre, equal small port/starboard; top shows three, SIDE shows big centre cone partially behind one smaller near cone on SAME HORIZONTAL AXIS, never three vertically stacked nozzles. Dark muzzles. Stern only dim red engine light, vents dim red instead of brilliant orange. Plain grey no text, top above side below, bow RIGHT, same scale, target 1400px length / 400px beam / 360px side height. No boat fittings.
```

### A7try3

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-0d54eb53-6ad4-44be-bd61-cce295a6ca57.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-6d738ea0-bb25-444e-8254-082bf770bd10.png`

```text
Final A7 correction, retain this patched salvage identity, blunt plate prow, ordered outward scatter rack per flank, forward heavy torpedo tube cluster, one flak, one low command, one listening cluster, tanks, stepped irregular plan and side hangar. Correct stern to exactly THREE engine cones total: one large centre plus ONE small port and ONE small starboard. Top shows big centre between just two equal small cones, REMOVE the two extra little centre-adjacent engine tips. Side shows big centre and one overlapping near-side small cone at same horizontal centre height, far cone hidden, NO top/bottom extra engines. Restore heavy proportions on 1536x1024 canvas: 1400px length, 400px top beam, 360px side height, do not make long thin bar. Both views equal scale bow RIGHT. Two side hangar doors: one each flank aft, must be detectable as deep dark edge notches in TOP and one near-side big dark doorway in SIDE. No roof hangars. Preserve ports dark, dim RED glows, rust red/black/bare steel, no yellow green olive patches, no mast funnels sea details. Main racks mirrored so their fire goes outboard and slightly forward, no additional weapons.
```

### A7beauty

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-6d738ea0-bb25-444e-8254-082bf770bd10.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-4c49e1d0-905d-46f6-8097-d52541b6201b.png`

```text
Hullbreaker A7 beauty from selected sheet. Entire hero three-quarter FRONT ABOVE bow RIGHT foreground, near-black no text. Preserve original Pyre-Barge character: massive mismatched stacked hull blocks and bolted salvage armour, stepped asymmetrical outline, red oxide and black iron, bare-steel patches, tanks drums chains worn nonverbal markings, blunt single salvaged plate ram prow, flat armoured belly, heat vents/radiators. EXACT mounts: ONE rack of many short scatter tubes per flank, mirrored main racks fire OUTWARD and slightly forward, ONE heavy cluster of BIG torpedo tubes through prow aimed forward, ONE small flak turret top, TWO dark side hangar mouths one per flank near aft shoulders. One low armoured command block and one listening dish/scoop cluster. THREE aft engine cones only, one big centre plus matched small side pair. Dim red glows, black weapon ports. No extra gun batteries. Exactly ONE smaller DISTINCT lean pack-hunter escort at one-third length beside hero: blunt broad head, lean narrow tail, patched asymmetrical scavenged plates, one little forward torpedo cluster, one small scatter rack, two engines, no hangars, no tall superstructure. Equal physical hatch/tube/bolt sizes across both, fewer parts on escort. NO yellow olive green camouflage, boat prow keel masts funnels railings cranes or aircraft fins.
```

### A7beautytry2

Inputs:
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-4c49e1d0-905d-46f6-8097-d52541b6201b.png`
- `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/exec-6d738ea0-bb25-444e-8254-082bf770bd10.png`

Output: `C:\Users\rcbai\.codex\generated_images\01a1caa2-5b55-7521-824d-9f319078a3ad\exec-b06e48bc-e8aa-4121-b0ae-dbd3428184c3.png`

```text
Precise A7 beauty correction. Keep hero patched slab shape, armour colours, tanks chains command sensor flak, prow torpedo cluster, three aft engines and exactly ONE escort unchanged. FAIL gate6: two hangar mouths are stacked on visible NEAR flank. This ship has exactly TWO hangars TOTAL, one port one starboard, not two on same flank. Keep LOWER near-side bay mouth at aft shoulder. Remove UPPER stacked bay mouth and fill with solid mismatched bare-steel/red-oxide patched slab armour. Far-side bay is hidden on opposite flank, do not add another visible door. Keep near scatter rack and show far scatter rack tips along opposite outer edge if visible, no extra guns. No other changes, near-black background no text.
```
