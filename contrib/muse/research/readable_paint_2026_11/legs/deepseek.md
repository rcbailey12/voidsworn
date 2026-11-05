# DeepSeek leg (writer), issue 188

Chair screening note (added at filing): raw DeepSeek copy, dash-normalized only. Two palette errors verified against the pack and corrected in the chair synthesis: the Chorus palette given in section 4 (pale bone, deep teal, violet glow) is not the shipped palette (dark olive flesh, ochre bone chitin, bile yellow-green light), and the Hegemony note invents a gold trim (the shipped palette is pale grey, steel blue, implant blue). The universal median-luma window in clause 10 and the test is also qualified in the synthesis (it anchors on the Hullbreaker reference; other factions measure against their own reference).

1. Why the round 5 paint read as cluttered, mechanism by mechanism

The short answer is that round 5 matched the colour histogram and still failed the eye. The reference measured 85.41% dark or neutral, 13.62% rust, 0.97% red trim, and median luma 30.07 of 255. Round 5 V1 measured 94.76% dark, 4.67% rust, 0.53% red, and median luma 41.63. V2 measured 89.49% dark, 9.99% rust, 0.52% red, and median luma 44.26. The colour bins were inside 10 percentage points of the reference, but the median brightness ran 11 to 14 levels above the art, and the owner still read the result as "a cluttered messy mix that is too busy." The failure is therefore not a palette failure. It is a structural failure in four layers.

Value structure. The first thing the eye reads at battle distance is the value mass, not the hue. Round 5 V1 had more area classified as dark than the reference, 94.76% against 85.41%, but its median luma was still 11.56 levels brighter than the reference. The dark bin was populated, but the dark areas were not dark enough to form a stable ground. INFERRED: the recipe lifted the soot shades into a narrow mid-dark band, so the hull read as one even grey field with small accents on top, instead of a dark field with a few deliberate lighter plates. The reference works because its dark mass is deep enough to let the rust and red sit as separate events. Round 5 passed the bin count and lost the depth.

Zone size. The round 5 recipe assigned soot shades to connected surface regions, not UV bands. Small bounded regions became trim plates. That sounds geometry-driven, but it means the paint followed whatever regions the mesh happened to expose. On a generated hull, those regions are numerous, irregular, and small. At the battle camera the Pyre-Barge is 41.6 units long, which is about 620 px at 4K and about 310 px at 1080p. A "plate" that is only a few pixels across does not read as a plate. It reads as speckle. The round 5 paint therefore created many small value events, and the eye reads many small value events as clutter, even when the overall colour percentages are close to the reference.

Noise frequency versus the camera. Round 5 used a grayscale CC0 photo texture, PaintedMetal004, for scratches, displacement, and roughness. At close range that texture adds richness. At battle distance, where 1 unit is about 7 to 8 px at 1080p, the scratch and grain features fall below 1 unit and therefore below the size that can survive as a deliberate mark. They do not disappear. They become a high-frequency field that the eye cannot resolve into shapes, so the hull reads as noisy rather than detailed. The settled stack, by contrast, uses hand-placed wear on real edges and AO in recesses, which are both larger than 1 unit and therefore survive the battle camera.

Melted geometry underneath. This is the mechanism the paint cannot fix. Both round 5 hulls scored 0 of 9 clean construction cells. The report describes fused cylinders, torn panels, and a broken silhouette, with no clean plate boundaries for the paint to follow. When the geometry has no plate boundaries, the paint cannot invent them. The recipe assigned shades to whatever regions the mesh exposed, and those regions were the melted regions. The result is a paint job that follows melted geometry, which is why the owner read it as cluttered even though the colour bins were close. The round 4 V3 hull, which scored 7 of 9 clean construction cells, shows the contrast: its palette read at battle distance because its geometry gave the paint clean plates to follow.

2. The paint readability standard

The standard is written for the battle camera at about 170 units. The Pyre-Barge is 41.6 units long. At 4K that is about 620 px long, and at 1080p it is about 310 px long. At 4K, 1 unit is 15 px. At 1080p, 1 unit is 7.5 px, rounded to 8 px in the test record. Each clause gives the rule, the number, and the reason in one line, because the standard must be checkable from a battle crop without opening the source file.

1. Base coat tones: two or three, no more. One deep soot or dark neutral ground, at most one mid plate tone, at most one light plate tone. Rust and red are not base coat tones. Because R97 fixes red as trim and light, and the reference keeps rust at 13.62% as break-up, not as a base, two or three base tones are enough to give a dark ground and a few deliberate lighter plates without creating a new value event for every region.

2. Minimum plate size: 2 units across, which is 30 px at 4K and 15 px at 1080p. Major zone breaks should be 4 units, which is 60 px at 4K and 30 px at 1080p. INFERRED: the test blur radius is 1 unit, so a 2 unit plate is twice the blur radius and survives as a shape, while a 1 unit plate is the same size as the blur and disappears. Because round 5's small bounded regions became trim plates below this floor, they read as speckle, not as plates.

3. Minimum value step between neighbouring plates: 12 luma levels on the 0 to 255 scale, with 24 levels for major zone breaks. Because round 5's median luma sat 11 to 14 levels above the reference and still read as flat, 12 levels is the smallest step that can be seen as a deliberate break at battle distance, and 24 levels is the step for a major break that must read even after the blur.

4. Zone layout: no more than three base tones and no more than five major value breaks across the hull's visible side. Plate boundaries must follow a construction edge, a trim line, or a deliberate faction seam. They may not follow a UV seam, a texture tile edge, or a region that only exists because the mesh happened to expose it. Because round 5 followed whatever regions the mesh exposed, it created many small breaks, and many small breaks read as clutter.

5. Wear goes on real edges only. Bounded convex wear follows actual geometry edges, as in the settled stack. Wear may not sit on flat plate interiors, and it may not follow a texture pattern. Because wear that sits on flat interiors becomes a new value event, and a new value event on a flat plate reads as noise at battle distance.

6. Rust is a break-up field, not a base colour and not a speckle. Rust may occupy roughly 10 to 14% of the battle crop, close to the reference's 13.62%. It goes inside plates and along real edges, never as a scattered speckle across plate boundaries, and never as a base colour on its own. Because the reference uses rust as break-up inside a dark ground, and round 5 V1's 4.67% rust was too low to break up the ground while V2's 9.99% rust was still below the reference and scattered as small events.

7. Grain: feature size at least 1 unit across, which is 15 px at 4K and 7.5 px at 1080p, contrast at or below 8 luma levels, and grain only in the close LOD. Grain may not be the only thing separating two plates. Because round 5's PaintedMetal004 grain was smaller than 1 unit at battle distance, it became noise rather than texture.

8. Trim and light discipline: red trim stays at or below about 1% of the battle crop, bright red stays at 0% except for actual lights, and red is never a base plate colour. The reference measures 0.97% red trim and 0.00% bright red. R97 and R103 both restrict red to trim plates, markings, and light, because red is the faction's accent and an accent that covers a plate stops being an accent.

9. Recesses and shadows: use geometry AO for recess grime, and keep the recess value below the surrounding plate value by at least 12 luma levels. Because the settled stack uses AO as the recess grime source, and a recess that is not darker than its surrounding plate does not read as a recess at battle distance.

10. Median luma of the battle crop: 30 of 255, tolerance plus or minus 5 levels. The reference is 30.07. Round 5 V1 was 41.63 and V2 was 44.26, both outside the tolerance and both read as too bright and too even. Because the median luma is the value mass, a hull outside this range cannot read as a dark ground with a few lighter plates, whatever its colour bins say.

11. Construction precondition: a hull must score at least 7 of 9 clean construction cells before paint sign-off, or it is a paint test only and not a candidate for the standard. Because V3 scored 7 of 9 and its palette read at battle distance, while V1 and V2 scored 0 of 9 and no paint rescued them. Paint cannot manufacture clean plate boundaries on melted geometry.

3. The test: blurred greyscale battle crop against the reference

The test is designed to answer one question: does the hull still show deliberate plate structure after the battle camera and the blur have removed everything smaller than 1 unit? If the answer is yes, the paint is readable. If the answer is no, the paint is clutter, whatever its close-range richness.

Procedure

1. Capture the battle crop at r=170 units, 1:1 pixels, with the same crop box and the same camera angle as the reference crop. Use 1920x1080 for the 1080p gate and 3840x2160 for the 4K reference record.
2. Convert both crops to greyscale using standard luma weights: 0.2126 R plus 0.7152 G plus 0.0722 B.
3. Apply a Gaussian blur with a radius of 1 world unit at the battle camera. At 1080p that is 7.5 px, rounded to 8 px in the test record, and at 4K it is 15 px.
4. Count the distinct plate shapes that survive the blur on the hull's visible side. A surviving plate is a shape at least 15 px across at 1080p, with a value step of at least 12 luma levels from its neighbour.
5. Measure the median luma of the candidate crop and compare it with the reference median of 30.07.
6. On the unblurred colour crop, measure the red trim percentage, the bright red percentage, and the rust percentage, and check that no plate is smaller than the plate floor.

Pass criteria

All of the following must hold. Median luma is between 25 and 35. At least three distinct plate shapes survive the blur on the hull's visible side, each at least 15 px across at 1080p. No more than five value steps across the hull's visible side. Red trim is 0.5 to 1.0% of the crop, and bright red is 0% except for actual lights. Rust is 10 to 14% and is confined to plate interiors and real edges. Grain contrast is below 8 luma levels, and grain is not the only thing separating two plates. Every plate boundary aligns with a construction edge or a deliberate trim line.

Fail criteria

Any of the following fails the hull. Median luma above 35 or below 25. Fewer than three plate shapes survive the blur. Any plate smaller than 15 px at 1080p after the blur. More than 1.5% red, or any bright red on a plate. Rust patches smaller than 2 units, or rust scattered across plate boundaries. Grain contrast above 12 luma levels. Plate boundaries that do not match construction edges.

Pass example: the round 4 reference. Under the 8 px blur, the reference keeps a deep dark ground around luma 30, with broad rust break-up and a few deliberate lighter plates that still read as shapes. Its colour measures are 85.41% dark, 13.62% rust, 0.97% red, and median luma 30.07, all inside the pass criteria. It passes because its plates are larger than the blur radius, its value steps are larger than 12 levels, and its rust is broad break-up, not speckle.

Fail example: round 5 V1. V1 measures 94.76% dark, 4.67% rust, 0.53% red, and median luma 41.63. Under the blur it becomes a roughly uniform mid-grey field with scattered flecks, and no plate shape survives as a deliberate shape. It fails on median luma, on plate count, and on rust coverage.

Near-pass example: round 4 V3. V3 is hand-built, scores 7 of 9 clean construction cells, and its palette reads at battle distance. Under the blur its large plates survive, its median luma is close to the reference, and its rust reads as broad break-up rather than speckle. It is a near pass because the test does not check close-range richness, and because V3 still needs a final check on red trim and grain contrast at the battle LOD.

What the test deliberately does not do. It does not judge colour hue, it does not judge close-range material richness, and it does not reward detail that only appears at close range. It is a battle-camera test, and a hull that passes it can still fail a close-range art review.

4. Per-faction notes

The standard bends at the palette and the surface kind. It does not bend at the plate floor, the value step, the median luma, or the construction precondition. A faction may change its colours, but it may not shrink its plates, flatten its value steps, or skip the construction check.

Sunward Crusade. Black iron is the deep ground, frost white is the large value break, and bright ember is light and trim only. The risk is that frost white is so bright it blows out the value structure, so frost white must be a large plate, not a small accent, and it must be at least 24 luma levels above the black iron ground. Bright ember must stay at or below 1% of the crop, as in the standard, because ember is the accent, not a base. If frost white is used as a small trim, it becomes a bright fleck, and bright flecks read as clutter.

Hegemony. Pale grey and steel blue are close in value, so this faction needs the value step enforced more strictly than the standard. Pale grey must be the light plate, steel blue must be the mid plate, and the step between them must be at least 24 luma levels, not 12, because at battle distance a 12 level step between two close values disappears. The faction's gold trim must stay at or below 1% of the crop, and it must follow a trim line, not a texture pattern, because gold on a pale ground is the first thing that reads as clutter if it is scattered.

Ashfall Hullbreakers. The palette gives matte soot black, rust red-brown plate, dried blood red trim, and hot red glow. Rust is already a plate colour here, so the standard's rust rule bends: rust may be a plate, but it may not be a speckle, and it must still be inside a plate and along a real edge. Dried blood red trim must stay at or below 1% of the crop, and hot red glow must stay at 0% except for actual lights, because the faction already has two reds and a third red event reads as clutter. The soot black ground must stay at least 24 luma levels below the rust plate, or the rust plate does not read as a break.

The Chorus. Organic hulls are grown, not plated. The standard bends by replacing plates with zones. A zone is a continuous surface area at least 2 units across, with a value step of at least 12 luma levels from its neighbour. The Chorus palette is pale bone, deep teal, and violet glow, so the value step must be enforced between bone and teal, because bone and teal are close in value at battle distance. Violet glow must stay at 0% except for actual lights, because glow is the accent, not a base. If a zone is smaller than 2 units, it reads as a growth, not as a zone, and growths read as clutter.

Glasswrights. Clear crystal white is a very high value base, so the risk is blowing out the value structure. Keep the crystal white ground at or below luma 200, and make the pale gold trim a large plate, not a small accent, with a value step of at least 24 luma levels from the white ground. Mint light must stay at 0% except for actual lights, because mint is the accent, not a base. If crystal white is used at full brightness, the median luma rises above 35 and the hull fails the test, whatever its plate layout.

Eclipse. Dark violet-black plates are the deepest palette in the fleet, so this faction risks the opposite failure: the hull reads as a single dark mass with no plate breaks. The white-gold corona must be a large plate, not a small accent, with a value step of at least 24 luma levels from the violet-black ground, and the violet-white inner glow must stay at 0% except for actual lights. The median luma must still be between 25 and 35, so the violet-black ground must not be darker than luma 20, or the hull fails on median luma even though its plates are clean.

5. How shipped space games keep hulls readable at strategy-camera distance

The common pattern is not unique painted detail. It is a small number of shared, packed maps plus a team colour mask, with large value breaks and a silhouette that reads before any detail. Detail is added at close range, not at strategy range, and it is added as damage, dirt, and decals on top of a readable base, not as the base itself.

Homeworld and Homeworld 2. Rob Cunningham, art director on Homeworld and Homeworld 2, says the team had to make sure each ship was identifiable by its silhouette from every angle, with simple forms and a bold colour scheme, because the player must read a ship before reading its detail. That is the same rule as the plate floor: silhouette first, detail second.
https://www.gog.com/forum/general/interview_homeworlds_rob_cunningham_18367

Homeworld 3. The shipped game uses three UV channels for ships. One UV channel is non-mirrored and used for team colour and damage, one is mirrored for most of the hull, and one is used for decals. The MASK map packs dust and dirt in red, engine glow in green, panel lines in blue, and team colour in alpha, and a separate TEAM map holds the team colour. The lesson is to pack the readable information into masks, not to paint it as unique detail on every hull.
https://mod.io/g/homeworld3/r/advanced-ship-creation

EVE Online. The V5++ rework repacked every ship texture map into a new system with albedo and roughness, added a material map in a four-to-one greyscale system, and expanded the dirt map so dirt accumulates in recesses and on lower surfaces. Dirt and killmarks are added as a separate layer on top of the base, and they do not change the base value structure. That is the same separation as the standard: base first, break-up second.
https://www.eveonline.com/ru/news/view/the-many-additions-of-v5plusplus
and
https://www.eveonline.com/ko/news/view/dirt-killmarks-dirt-and-destruction-in-new-eden

Sins of a Solar Empire II. Each ship needs a _cl colour map with an alpha layer for team colour, a _da data map that carries metalness, reflection, bloom, and illumination, and a _nm normal map. At far zoom, ships become icons, and the game relies on the team colour and the silhouette, not on the painted detail. The lesson is to make the team colour a mask, not a painted area, and to keep the silhouette readable when the detail is gone.
https://forums.stardock.com/492600/new-modded-ship-appears-as-team-color
and
https://forums.sinsofasolarempire2.com/search?tag=graphics%20icons%20zoom

Battlefleet Gothic: Armada. The game renders ships in obsessive detail on Unreal Engine 4 and lets players zoom down to the finest detail, but the faction visual language is still carried by large shapes, broad colour blocks, and a shared silhouette family. The detail is a close-range reward, not the battle-range signal. The lesson is the same: detail that only survives at close range is not readability.
https://staging.gamedeveloper.com/design/maxing-out-miniatures-making-a-successful-tabletop-adaptation
and
https://dtf.ru/games/2230923-seriya-battlefleet-gothic-armada-naibolee-atmosfernye-i-zrelishnye-igry-po-vselennoi-warhammer-40000

The transferable pattern is consistent across all five: use shared packed maps with masks, keep the base value structure simple, add dirt, damage, and decals as separate layers, and make the silhouette and the team colour readable before any detail. That is the standard in shipped form.

6. Owner questions

1. Do we adopt the 2 unit plate floor, which is 15 px at 1080p, or a larger 4 unit floor for capital ships?
Recommended pick: 2 units as the universal floor, with 4 units for major zone breaks. Why: 2 units is the smallest size that survives the 8 px blur at 1080p, and 4 units is the size of a major zone break in the standard.

2. Do we keep the 12 luma value step, or raise it to 24 luma for all plates?
Recommended pick: 12 luma for ordinary plates, 24 luma for major zone breaks. Why: 12 luma is the smallest step that reads as a deliberate break, and 24 luma is the step for a major break that must survive the blur.

3. Do we adopt the 25 to 35 median luma range, or a wider 20 to 40 range for factions with very dark or very bright palettes?
Recommended pick: 25 to 35 as the universal range, with a faction exception only if the faction passes the blur test. Why: 25 to 35 is the range of the reference, and a wider range would let a hull that reads as too bright or too dark pass the test.

4. Do we allow rust as a plate colour for Ashfall, or keep rust as break-up only for all factions?
Recommended pick: allow rust as a plate for Ashfall only, with rust as break-up for all other factions. Why: Ashfall's palette already uses rust as a plate, and the standard bends for Ashfall, but rust as a plate for all factions would make rust a base colour, not break-up.

5. Do we adopt the 7 of 9 construction precondition, or allow paint sign-off on hulls that score lower?
Recommended pick: 7 of 9 as the precondition, with no exception. Why: V3 scored 7 of 9 and its palette read at battle distance, while V1 and V2 scored 0 of 9 and no paint rescued them, so paint cannot be signed off on a hull that has no clean plates to follow.
