# Round 5 exact image prompts

Built-in `image_gen.imagegen` only. 21 completed calls. Original PNGs remain untouched at the paths below. Selected sheets: S_sheet2, H_sheet2, E_sheet3, A_sheet3. Selected beauties: S_beauty, H_beauty3, E_beauty3, A_beauty3.

Initial references: S7, H7 and A7 sheets under `contrib/codex/design/concept_round4_2026_11/`; Eclipse `contrib/muse/design/concept_directions_2026_11/deathless_C.jpg` and `contrib/codex/design/concept_round2_2026_11/deathless_E4_sheet.jpg`; Hullbreaker `docs/ship_pipeline/concepts/C19_51.webp`, converted to `%TEMP%/voidsworn475_C19.png` with Pillow before use. Each correction references its preceding image; A_sheet2 also references C19. Every first beauty references its selected sheet. H_beauty2, E_beauty2 and A_beauty2 reference both prior beauty and selected sheet; subsequent corrections reference prior beauty.

Sheet prompts state target pixel dimensions. README records actual delivered proportions. Pillow only converted, resized, encoded and extracted/composited silhouettes from the tool's pictures; no ship was drawn in code.

## S_sheet

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-1db23885-c2ee-4be9-a048-6a5d67c4732e.png`

```text
Use case: precise-object-edit. Make the Sunward S8 orthographic design sheet from reference S7. Change ONLY the bow: remove the entire projecting lance barrel; split the broad armoured blade prow into two heavy triangular blade halves with a DEEP empty open slot between, fork tips at the right, recessed ember emitter deep at root of slot, NOTHING beyond tips. These are hull halves not gun prongs. Keep black iron broad shoulders, rear organ-pipe ember radiator bank, two engine bells, EXACT seven short heavy outward-pointing barrels on EACH flank in ordered galleries, four little flak turrets in two matched pairs, chalk marks, protected low command and sensor. Visible mounted guns, dark ports. Same ship in TOP above and SIDE below, bow RIGHT, parallel orthographic flat on, same pixel length and scale, plain uniform dark grey, no text, no labels. Preserve S7 body proportions without its removed barrel; aim ship top 1390x360 pixels and side 1390x240 on a 1536x1024 sheet. Slot clear from top at thumbnail size. No extra weapons, masts, rails, sea fittings. Ports dark; only ember light.
```

## S_sheet2

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-ff8486c3-4e5b-4c8a-9b7f-2d9a5170e64a.png`

```text
Correct this S8 sheet, changing ONLY the lower SIDE projection at the bow. Gate line 8: top and side must be consistent orthographic projections. The fork is TWO HORIZONTAL SIDE-BY-SIDE hull blades, NOT vertically separated. In pure SIDE view the two halves overlap, so bow is ONE solid tapered armoured wedge, no visible fork slot, no lower jaw, no visible emitter. Keep the entire upper TOP view pixel-identical, including its open fork. Keep lower stern and body and seven dark gun ports and two overlapping flak silhouettes unchanged. No text. Uniform grey background.
```

## H_sheet

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-98a9f42b-4fa0-404b-a97c-fb2b02a8629e.png`

```text
Use case: stylized-concept. Hegemony H8 dreadnought sheet based on H7 reference, KEEP wedge forward then two parallel structural hull rails with ONE dark hangar door in gap, blue edge lines, machined pale-grey module detailing. Radically THICKEN and WIDEN to heavy dreadnought, never slender. Target top body 1320 pixels length by 440 beam excluding turrets (3:1), overall including turrets near 3:1 as well by keeping barrels short enough. Each rail is huge thick hull block one-third wedge width, central gap one-third. Side armour hull height 110 pixels, stepped armour belts. Bow right: cut pointed tip FLAT, blunt armour face, ion weapon is wide recessed horizontal blue emitter trench FLUSH in face. NO gun, NO prongs, NO protrusion at bow. Exactly TWO largest heavy turbolaser turrets on wedge shoulders at widest point, each twin long barrels pointing outboard and slightly forward, never through hull. ONE small centreline flak turret and low protected command and sensor. FOUR stern engine blocks two per rail, aligned lengthwise, rear left. In SIDE projection rails overlap, only nearer pair visible, side-view nozzles edge-on not facing viewer. Same ship TOP above SIDE below same scale same length orthographic flat-on, bow RIGHT, dark plain grey no text no labels. Guns dark bore holes. No masts, sea fittings, fins, warm light, rust. Heavy hardest-to-break armoured warship.
```

## H_sheet2

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-315fa168-3d89-4231-a013-96128ddd6495.png`

```text
Correct H8 proportions and gun arcs. Current sheet FAILED requested heavy proportions: top is about 1960 long and only 420 wide, a slender 4.7:1. Redraw SAME H8 design radically SHORTER AND BROADER, top silhouette 1350 pixels long by 450 pixels wide INCLUDING guns on a 1536x1024 canvas. Solid hull wedge beam 450 too. Wedge and twin rails both must be FAT, compress length to TWO THIRDS of current while expanding beam. Each rail 150px thick, gap 150px; stern width same as shoulder width. Side hull body thickness 112px (quarter of 450 beam), total side turret height 170px. Flat cut-off blunt bow, flush blue trench no nose gun. Biggest twin shoulder turrets point DIRECTLY OUTWARD perpendicular to ship axis (up/down in TOP view), no forward aiming. One little centreline flak and command block and sensor. FOUR engines two per rail arranged laterally, in SIDE only overlapping edge-on engine blocks at left, never four lined along length. TOP above SIDE below equal length, bow RIGHT, uniform grey background, no text. No nose prongs. Preserve pale grey machined modular materials and ONE hangar between thick rails, stepped armour belts. Prioritise heavy mass and real 3:1 hull plan over reference length.
```

## H_sheet3

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-c31e9bf3-bce8-4cfb-9145-fa09fd7fa32b.png`

```text
Final correction H8 same ship. Keep TOP layout, blunt recessed ion bow, twin rails, one bay, pale grey blue. Top hull currently 1340x520 versus desired 1340x447; reduce hull beam moderately to 450 pixels while preserving thick armour, rails 150px wide each. Shorten outward turret barrels so TOTAL top beam INCLUDING barrels is 500px, length 1400px (about 3:1). Thick dreadnought not needle. SIDE projection error: engines are four rectangular blocks arranged SIDE BY SIDE transversely, same height. In pure side view they overlap as ONE edge-on rectangular engine housing at left, not TWO STACKED engines. Side hull body height 112px (one quarter hull beam), no turret protruding below belly. Show one shoulder turret in side, its outward barrels aimed directly toward camera show only two dark muzzle holes. Same centreline flak x-position between top and side (just ahead of shoulder turret, not shifted aft). Add one small flat sensor patch beside command block. TOP above SIDE below bow right same length and same scale plain dark grey no text. No extra weapons no nose barrel.
```

## E_sheet

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-71d155d5-becb-497b-a5fc-feded6d8af07.png`

```text
Use case stylized-concept. Eclipse E8 RING CRUISER orthographic sheet, two refs: Annulus image for separate shade plate construction ONLY; E4 for violet scaled armour, thin green rim lines, dark drive cones ONLY. Replace their layouts completely. The ship IS a flat horizontal BROKEN RING, NOT a tube with a ring attached. TOP view upper: entire circular ring face-on, about 950px diameter outer width, overall ship length about 1235px (1.3:1). Ring outer beam 80 percent of total length. EIGHT separate thick curved violet-black scaled shade plates arranged around circle with clear grey gaps. Larger missing segment at RIGHT bow. No continuous rim hoop and NO radial wheel spokes. Slim dark horizontal structural spine passes left-right through ring centre with small brightest green reactor sphere in cage exactly at centre. Only a few thin dark support struts, not a wheel. Two visible twin gauss turrets on spine, one BEFORE core and one AFTER, elevated clear fields forward; one much smaller stern sentry. Those three turrets plus ONE flush green-lit doom aperture at right front end of spine, WITHIN missing ring segment. Nothing projecting beyond ring as a gun. Left aft spine short engine block with three dark longitudinal cones. One low protected command block and one small sensor patch integrated aft spine. Two transverse break collars. SIDE view below: ring seen perfectly EDGE-ON as THIN HORIZONTAL BAND, all eight plates at same vertical plane, spine inside, sphere and three turrets above. NEVER vertical ring, never circle in side view. Same length/scale TOP above SIDE below, bow RIGHT, plain uniform dark grey background, no text, no escort. Wide square-ish canvas to fit circular top plus thin side. Green only thin rims and little core/aperture, dark gun ports, no flames, no bones, no extra weapons.
```

## E_sheet2

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-48e0cdbb-49c6-49ee-95e5-5959d77f08d2.png`

```text
Correct E8 sheet SAME flat broken ring. Keep eight separate violet scaled plates and thin green rim, green caged centre core, two gauss spine turrets plus one small aft sentry, no extra guns. Two required fixes: (1) NO projecting doom cannon housing. Shorten the front/right spine: terminate as a blunt flush green APERTURE within the open gap BETWEEN foremost plate ends, at x near 1000 rather than x1100, no long tube outside ring. The aperture is part of spine shape. (2) Three dark engine cones at left stern lie SIDE BY SIDE horizontally in TOP. In pure SIDE view they overlap as ONE dark cone edge-on, not three vertically stacked cones. Orthographic consistency: top and side exactly same x endpoints/length and identical gun x positions. Ring edge-on in SIDE is thin flat band spanning its actual x extent, NOT a thick tubular hull. Improve length/beam toward 1.3:1 by extending rear ENGINE BLOCK left only, not nose weapon; ring width remains about80% overall length. Plain dark grey no text. Bow RIGHT. No spokes or continuous hoop.
```

## E_sheet3

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-2390918a-e661-497a-97a3-b9e4af562a5c.png`

```text
Final targeted E8 fix, preserve existing ring layout and front aperture, same eight or ten separate plates, green caged core and three turrets. Current TOP aft/left engines incorrectly merged into a single cone: replace with THREE separate dark drive cones SIDE BY SIDE across width, all point left, each on same engine block and same height. Extend ONLY aft engine block leftward so overall length about 1.3 times ring outer beam, ring remains circular with outer beam about80 percent total length. Keep front doom aperture flush at spine end BETWEEN ring plate tips no barrel. Orthographic side only ONE cone visible because three lateral cones overlap. Exact same overall length in TOP and SIDE, bow right. Correct side ring shading as thin flat edge-on plate band, not round tube. Keep all top gun x positions in side. Low command block and sensor visible aft, TWO transverse collars. TOP above SIDE below no text dark grey plain background. No wheel spokes, no hoop connecting separated plates.
```

## A_sheet

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-16db482e-0f88-4bfa-8954-9f4c11ddfc7a.png`

```text
Use case stylized-concept. Hullbreakers A10 FLAGSHIP orthographic design sheet. Reference A7 for RED OXIDE BLACK IRON bare steel patched bolted skin and chains/tanks. Reference C19 for stacked patched-together CHARACTER ONLY, OMIT its sea ship fittings. Redesign plan as FOUR salvage hull blocks of clearly different widths and lengths, offset left/right of centreline, LARGE obvious irregular silhouette STEPS, no long tube. One whole block is stolen old pale grey armour with stripped red patches. Continuous structural spine and two chained section joins. Length about 3.5x beam; thick side hull about .9 beam. TOP DECK carries exactly TWO HUGE BOX ROCKET LAUNCHERS, largest deck objects, many SHORT DARK TUBE mouths in rectangular grids, one angled out PORT one out STARBOARD, matched balanced positions but mismatched salvage housings: one on tall girder frame one on old turret ring. Launcher mounts INSIDE hull footprint, not hung off flanks. No other main guns. ONE small centreline flak turret, ONE low protected command block, ONE small listening-dish sensor cluster. Bow RIGHT blunt single salvaged RAM PLATE. FOUR SMALL flush torpedo mouths set LOW in bow armour, two each side of ram plate, NO projecting nose pipes or gun. Exactly TWO dark hangar door mouths on flanks, one per flank, no roof doors. Three stern engine bells left, big centre smaller matched lateral pair; all same thrust axis. Side projection overlaps engine pair correctly, no vertical stack. Orthographic TOP above SIDE below same scale same length, plain uniform dark grey no text. Top about 1380x395 pixels side about 1380x350. Clear top rocket grids first read at thumbnail size. Ports dark. NO yellow olive green camouflage, NO masts funnels deck rails keels boat stem or yacht decks. Stepped outer hull blocks, not naval superstructure.
```

## A_sheet2

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-3ede69af-1e91-4615-92b1-ee1fffc42fb9.png`

```text
A10 correction: previous image FAILED top silhouette and balanced main rockets. Redraw substantially, do NOT preserve long thin bar. Overall TOP body 1400px long by 450px wide (3.1:1), SIDE 1400px long by 360px tall. Four irregular hull blocks with LARGE width changes: stern block width300, aft-mid block width450 offset port60, forward-mid block width330 offset starboard70, blunt bow block width230 offset port30. Abrupt large OUTLINE STEPS, thick stacked stolen ship chunks, old pale grey section. Keep red oxide black steel tanks chains. Main rockets: exactly TWO big box grid launchers AT SAME LONGITUDINAL STATION near middle, one PORT one STARBOARD across spine. Both mounted ON TOP DECK within hull outline. Port box angles outward/up in TOP, starboard outward/down, not both toward viewer. One on girder frame other on old turret ring. They balance across thrust axis despite asymmetric salvage. One small flak just forward of launchers, low command aft and one dish sensor. Bow RAM plate blunt, four SMALL dark TORPEDO ROUND MOUTHS flush low bow armour, two per side of ram, no nose barrel. TWO hangar mouths total one on EACH opposing flank, so pure SIDE shows ONE only. Three stern cones in TOP across width, only ONE overlapping cone profile in SIDE. Same ship orthographic TOP above SIDE below bow RIGHT. Plain uniform dark grey no text, no masts rails funnels keels camouflage yellow green. Fewer panels than prior because body is much shorter, preserve panel scale.
```

## A_sheet3

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-28be50f5-1b22-4749-85f8-a8d4f54ac6c4.png`

```text
Final A10 targeted correction. Keep current launcher placement, upper girder / lower turret ring pair on TOP at same x, their opposite outward firing directions, blunt ram plate with four flush torpedo mouths, one flak, one bridge/dish cluster, three engines, one bay visible in side and far-side bay hidden. Hull still FAILED: about 1720px length /340px beam, far too thin and long. Make it MUCH SHORTER AND THICKER: overall solid ship TOP length1400 /beam440 pixels, SIDE length1400 /height360 pixels including launchers. Four hull chunks of clearly unequal widths and lateral offsets: width320 stern, width440 aft middle offset upward50, width300 forward middle offset downward60, width220 bow offset upward30. TWO big square outline steps each side, asymmetrical, no tube. Much greater width change than before. Shorten each middle module by one-third, keep tank and bolt sizes same so fewer panels. Target 3.2:1 top ratio and .8 height/beam. Heavy chunky stolen hull sections, not yacht decks. At bow no visible gun protrusions. Plain grey background TOP above SIDE below same orthographic length and scale, bow RIGHT. No text. RED OXIDE BLACK IRON bare steel and old pale grey only no green/yellow/olive. Preserve skins and chains.
```

## S_beauty

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-1016d304-b7a8-4170-9ab7-5e3b26870e6c.png`

```text
Use case stylized-concept. Sunward S8 beauty made from this selected sheet exactly: same black iron broad-shouldered blade, TWO horizontal armoured forked prow halves, open slot deep recessed ember lance emitter, nothing projects beyond tips. Seven short heavy barrels EACH flank, four small twin flak turrets in two symmetric pairs, rear bank of glowing ember organ-pipe radiators, two big ember engine bells, chalk marks, low command. 3/4 FRONT and ABOVE view reveals top fork and ordered broadside weapons, hero fills frame but no cropping. ONE escort only, significantly smaller DIFFERENT family ship: short compact blade, tiny fork prow, one engine, three broadside barrels per flank, one little flak turret, three short radiator fins rather than hero bank, same hatch/bolt scale. Escort alongside with clear gap. Near black background, upper left studio light, crisp dark ports, detailed concept render. No firing, no labels, no text, no other ships, no nose barrel, no masts/railings/sea hull. Preserve all hero layout and counts from sheet.
```

## H_beauty

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-fc95f3e0-2311-46db-bf31-c54736f63903.png`

```text
Use case stylized-concept. Hegemony H8 beauty from selected sheet, same thick blunt wedge and twin broad armoured hull rails, a single recessed dark hangar between rails, four stern engine blocks two each rail, stepped armour belts, machined pale grey and blue grey panels, precise blue light lines. NO prongs or barrels on NOSE: wide horizontal recessed blue emitter trench FLUSH within blunt bow face. TWO huge heavy turbolaser turrets mounted on shoulders one each side, twin long barrels pointed OUTWARD slightly forward clear of hull, biggest weapons. One small centreline flak, one protected low command and one flat sensor cluster. Must look like heavy navy dreadnought, about 3:1 body length/width, NOT needle. Hero fully visible, 3/4 front above camera looks toward blunt bow and down top to see both rails and turrets. Near black background upper-left studio illumination, no text no firing. ONE smaller distinct Hegemony escort beside it: short squat blunt wedge with a single central spine (NOT twin-rail hero shrunk), two engines, one twin top turret, small flush blue bow emitter. Same real panel/hatch sizes fewer modules on escort. No ornament masts sea fittings rust warm light.
```

## H_beauty2

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-4da71977-5211-4e36-87c0-b29f7af51b49.png`

```text
Correct ONLY weapons on this H8 beauty using selected sheet as layout authority. Remove EXTRA round blue-lit turret/housing at deck centre behind small flak: that circle must be flat armour panels. Exactly TWO heavy shoulder turrets, ONE small centreline flak, ONE low angular command block, ONE flat sensor patch, no other gun-like structures. Turn twin shoulder heavy barrels OUTWARD from centre axis, one port one starboard, not forward along ship toward nose or over hull: each aims clear of hull edge in own lateral direction. Preserve rest including thick blunt wedge flush horizontal blue ion trench at bow, two thick rails one dark hangar four stern engines, and exactly one short SINGLE-SPINE escort with one top gun and blunt bow. Same composition materials upper-left light black background. No text.
```

## H_beauty3

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-85f1ccc7-2389-45af-af03-feb009257b32.png`

```text
Final H8 beauty correction. Remove completely the EXTRA CIRCULAR blue-windowed structure at middle of deck near x1170 y285 in 2048-wide reference; replace that round footprint with ordinary FLAT pale armour panels. Keep only low ANGULAR command block toward right and small flak with dark muzzle holes near centre. EXACT two big shoulder turrets and one little flak, no fourth turret. IMPORTANT ship bow is RIGHT, engines LEFT. Near shoulder turret now points backward LEFT: WRONG. Rotate near turret twin barrels outboard toward LOWER RIGHT of image, about 4 o'clock, fully clear of hull, never left toward engines. Far shoulder turret twin barrels toward UPPER RIGHT about 1 o'clock, outboard rather than axial. Guns cannot fire backwards or into hull. Keep all other geometry: blunt flush blue trench bow no nose gun, two broad rails four stern engine blocks one hangar, one distinct small single-spine escort. Same materials framing black background no text.
```

## E_beauty

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-3dc499e0-1702-4a14-9098-b68412912d3c.png`

```text
Use case stylized-concept. Eclipse E8 cruiser beauty from selected sheet. Hero IS FLAT HORIZONTAL BROKEN RING, eight separate thick violet scaled curved shade plates around small caged brightest green reactor sphere. Huge open areas inside ring, clear gaps between separate plates, wider gap at bow. Ring lies in horizontal plane, battle camera sees entire circular face foreshortened, NOT upright ring on nose. Overall length1.3xbeam ring80 percent overall length. Slim longitudinal dark spine through centre; only a few thin dark ties connect plates, NO wheel spokes and NO hoop. Two twin gauss turrets on spine one ahead of core and one aft, one small stern sentry, flush green doom aperture at front spine end WITHIN opening between foremost plate ends. No nose barrel. Short aft engine block with THREE DARK cones SIDE BY SIDE not serial, rear-facing on one axis. Low command block and sensor aft. Thin green-white rim lines only and little green core/aperture, dark ports. 3/4 FRONT ABOVE to clearly show horizontal ring, near-black backdrop upper-left soft studio light, hero fully visible no cropping. Exactly ONE distinct small escort alongside: slim short spine carrying HALF RING arc of THREE violet plates, one top gauss turret, two dark drive cones, tiny green core. Not mini full ring. Same plate/turret detail scale, no other ships. No flames bones pooled green gunfire labels or text.
```

## E_beauty2

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-7703fac1-d8fc-4346-877f-fa499d56ee16.png`

```text
E8 beauty targeted fix. Keep same flat broken ring of eight separate scaled violet plates, core, two gauss turrets, front flush aperture and ONE three-plate half-ring escort. Remove thin perimeter links between adjacent plates: absolutely NO hoop or rail joining plates around ring. Each plate connects only by a FEW thin dark ties toward longitudinal spine, not radial spoked-wheel pattern. Add exactly ONE clearly small sentry gun turret near stern where current round knob is; do not add any other weapons. Rear three cones must be THREE separate engine nozzles ACROSS WIDTH side-by-side, all point rearwards, not three cones in a row ALONG LENGTH. Compact engine block. Darken saturated magenta plates to deep VIOLET BLACK E4 material, retain thin green-white rim and tiny green core brightest. Forward doom aperture should be recessed in end of short spine between front plate ends, not a long tube. No other changes same camera black background escort stays half-ring THREE PLATES.
```

## E_beauty3

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-05bef15d-eb82-4f52-a0c2-2a8ac3f72de5.png`

```text
Final E8 beauty correction: remove ALL short curved bars connecting ADJACENT shade plates at their inner or outer rims. Every inter-plate gap MUST be empty black all the way through. NO perimeter hoop, no rim rail, no small bridging links. Each of eight separate plates is supported instead by thin dark struts going toward the longitudinal spine; use only a few slender asymmetrical support ties, NOT radial wheel spokes. Preserve horizontal ring plane, current dark violet scaled plates green thin edges, one small brightest caged core, two gauss spine turrets plus one small aft sentry, blunt recessed front aperture, three dark side-by-side stern engine cones and ONE three-plate half ring escort. Keep everything else and same camera black backdrop no labels text no extra ships.
```

## A_beauty

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-e3142619-685f-493d-bfbb-74e8d6ea1a0a.png`

```text
Use case stylized-concept. Hullbreaker A10 beauty based EXACTLY on selected chunky sheet. Hero thick salvaged spaceship made of four huge offset hull sections of different widths, abrupt lopsided steps, old pale-grey aft section red oxide patches black iron bare steel bolts chains tanks, no tube. Biggest deck objects exactly TWO mismatched huge box rocket launchers at same longitudinal station either side of spine, both ON TOP, one on girder frame one old turret ring, one aims PORT outward other STARBOARD outward, short dark tube GRID mouths clearly visible. ONE small flak turret, ONE low command block and one listening dish sensor. Blunt ram armour bow, FOUR SMALL flush torpedo mouths low in bow armour two either side of single ram plate, NO protruding barrel or pipe nozzles on nose. Three stern engine bells big centre smaller lateral matched pair, stern thrust only. Two dark hangar mouths total one each opposing flank, viewer sees ONE near flank mouth, far mouth hidden. 3/4 FRONT ABOVE view see deck rockets and blunt bow, fully visible hero no cropping, near-black background upper-left studio lighting crisp worn detailed concept. Exactly ONE distinct smaller escort beside it: lean short pack-hunter salvage tug two stepped blocks, one SMALL deck rocket box, two stern engines, no hangars, smaller blunt ram with flush two torpedo mouths, same bolt/hatch scale as hero fewer parts. Not hero shrunk. No masts funnels rails sea keel text labels other ships yellow olive green camouflage. Red lights dim dark ports.
```

## A_beauty2

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-cb58c6af-6a90-4c9c-a9ec-658e5ec5a51c.png`

```text
A10 beauty correct ONE thing: the two deck rocket BOX launchers must face OPPOSITE sides of ship. Keep nearer launcher on old turret ring aimed outward toward viewer/lower-right, dark grid mouths visible. Rotate FAR launcher on tall girder frame 180 degrees around vertical so it faces PORT away from viewer/upper-left across its own flank. For far launcher viewer now sees its SOLID ARMOURED BACK, not its tube grid; short side profile tubes may be visible at far edge. Never aim aft along ship, only directly outboard. This is a symmetric port/starboard main weapon system using mismatched salvage housings. Exactly two launchers, ONE flak, four small flush bow torpedo mouths, no extra guns. Keep entire rest unchanged including four stepped hull chunks, ONE near-side hangar, three stern bells, low command/dish, exactly one smaller two-block single-launcher escort. Same black background materials camera no text.
```

## A_beauty3

Source: `C:/Users/rcbai/.codex/generated_images/01a1cad6-2a84-7952-b229-394b5753878c/exec-77b0e2bb-51a8-4531-87ce-c2c3cf2827cb.png`

```text
Final A10 rocket arc correction ONLY far launcher on girder frame: ship bow points LOWER RIGHT, engines UPPER LEFT. Far launcher must point OUTBOARD toward UPPER RIGHT, 1 to 2 o'clock, NEVER left toward stern. Turn the far box so its tube mouths are on its UPPER RIGHT END, mostly hidden by casing from this camera, and solid rear panel faces LOWER LEFT toward viewer. Current tubes visible on left end are wrong: replace left end with solid armour cap. Keep near turret-ring launcher facing LOWER LEFT outboard clear of near flank, its grid visible. No fore/aft rockets. Rest same four chunky hull sections, three engines, four flush torpedo mouths, one flak, bridge/dish, one near bay, one little single-rack two-engine escort. No text extra weapons or ships.
```

