# Argon leg (review only), issue 188

Chair screening note (added at filing): Argon High gates verified in the returned text (picker button and prompt bar read Argon High before submitting, prompt bar still Argon High after sending, no model switch or Ultra upgrade). This is the strongest Argon review the board has had: per-leg sections, exact quotations, and a survivors list. The chair verified its main quotations against the filed legs and adopted most of its cuts, including two that change the synthesis: the blind leg's construction ban contradicts R103 (round 6 paints V1 by ruling), and DeepSeek's universal median-luma window breaks the bright shipped palettes. Two Argon positions were NOT adopted: its bow and stern vocabulary flags (the project's own build reports use bow and stern as direction words throughout, including the round 5 report; the house rule targets naval fiction framing, not ship direction words), and its flat demand that every standard number derive from the pack (a standard must choose thresholds; the synthesis labels each chosen number as derived or as a chair judgment instead). Argon's claims that specific URLs are dead are its own assertions, not chair-verified; the chair simply does not rely on those sources. Copy below is raw except for dash normalization and light condensation of the section 5 cut list, whose items all appear in full in sections 1 to 3 above it.

Argon High verifications: Before sending, both the model picker button and the prompt bar read "Argon High"; after sending, the prompt bar still read "Argon High". No model switch or Ultra upgrade occurred.

1. Review of rey_blind.md

A. Standard clauses that contradict R96, R97, R103, or the settled paint stack

Offending line: "Wear and rust may not appear on a surface whose construction cell failed (fused, torn, floating or blended), because that surface is rebuilt or left plain base tone."

Pack rule broken: Contradicts R103 under ## Rulings that bind this job, which states that after both AI hulls scored 0 of 9 clean construction cells, "Ryan chose to try both: (A) the round 4 hand-built V3 cut to the R96 ceiling with simple reference-style paint (few big plates, two or three tones, dark recesses, red only for trim and light, grain cut), and (B) V1 with the same simple paint. Filed as #187 (round 6)." R103 explicitly orders painting and evaluating V1 (which has 0 of 9 clean construction cells) with the simple paint recipe rather than leaving failed cells in plain base tone.

Offending line: "Clause 10, construction gate: a hull with failed construction cells does not get judged on paint until the failed surfaces are fixed or rebuilt. Paint review applies to hulls at the round 4 V3 level of construction or better."

Pack rule broken: Contradicts R103 (## Rulings that bind this job), which explicitly schedules V1 (0 of 9 clean construction cells) for paint evaluation alongside V3 in round 6 (#187).

Offending line: "4. Should a hull that fails construction (the clause 10 gate) be painted at all before rebuild? Pick: no, base tone only until construction passes."

Pack rule broken: Contradicts R103 (## Rulings that bind this job), which already decided to apply the round 6 simple reference-style paint to V1 (#187).

B. Numbers that do not derive from the pack's camera anchors or pack evidence (and are not labelled INFERRED)

Offending line: "Clause 2, minimum plate size: no tone zone may be smaller than 20 px across at 4K (about 1.3 units) or 10 px across at 1080p (about 1.3 units)."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The pack gives 15 px per unit at 4K, about 7 to 8 px per unit at 1080p, and a 41.6 units ship length (620 px at 4K); the 20 px / 10 px / 1.3 units floor is not derived from a pack number and is not marked INFERRED in Clause 2.

Offending line: "Clause 3, value step: neighbouring plates must differ by at least 25 levels on the 0 to 255 luma scale, or be merged into one zone. The recess tone must sit at least 25 levels below the darkest base tone."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The pack provides overall crop median luma (30.07, 41.63, 44.26), not a 25 luma-level step between plates or into recesses, and Clause 3 does not mark 25 levels as INFERRED.

Offending line: "Clause 4, silhouette step: where two zones meet at the hull's outer silhouette or at a major form break (a turret base, a hull step, a fin root), the step must be at least 40 luma levels or be backed by a recess shadow under clause 9."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text"). Although the "Because" sentence is marked INFERRED, the 40 luma levels figure has no derivation in the pack text.

Offending line: "Rust share in the battle crop stays between 5 and 15 percent, with the reference's 13.62 percent as the top guide."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The 5 and 15 percent band is not in the pack (and excludes round 5 V1's 4.67% rust, which the pack states passed the colour bin check "within 10 percentage points of the reference"), and is not labelled INFERRED.

Offending line: "Concretely, grain features must be no larger than 4 px across at 4K (2 px at 1080p) and no stronger than 8 luma levels of contrast, so at r=170 they merge into surface feel instead of drawing shapes."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). Neither 4 px across at 4K (2 px at 1080p) nor 8 luma levels of contrast derives from the pack's camera anchors or measurements, and neither is labelled INFERRED.

Offending line: "Clause 7, trim discipline: trim colour appears only on deliberate plates, markings and details that pass clause 2 size, and covers at most 2 percent of the battle crop."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The pack gives 0.97% red trim on the reference and 0.53% (V1) and 0.52% (V2) in round 5; the 2 percent cap is not in the pack and is not labelled INFERRED.

Offending line: "3. Apply a Gaussian blur with radius 5 px at 1080p (10 px at 4K). The radius comes from the camera math: 5 px at 1080p is about 0.7 units, so the blur erases features smaller than about 10 px across at 1080p, which is exactly the clause 2 minimum zone size."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors") and ## The job ("label anything inferred"). Because the 10 px (1.3 units) minimum zone size in Clause 2 is not derived from the pack, the 5 px (0.7 units) blur radius derived from it is also an unlabelled inference.

C. Shipped-game claims with no source or a source that does not say what is claimed

Offending line: "UNSOURCED KNOWLEDGE: Homeworld and Homeworld 2 built ship identity on large flat team-colour panels plus a stripe, with mostly bare hull elsewhere, so faction and facing read at full zoom-out. This is the classic argument for clause 7's rarity rule: the coloured area is a minority of the hull and always in the same places."

Pack rule broken: ## Deliverable for writer legs item 5 ("Every claim needs a source a reader can check; unsourced claims will be cut by the chair") and ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "shipped-game claims with no source").

Offending line: "UNSOURCED KNOWLEDGE: Battlefleet Gothic: Armada leans on silhouette and faction-wide colour identity (Imperial green-bronze, Chaos black and brass, Eldar smooth pale hulls) with very large unbroken surfaces, so at fleet camera distance the shape and one colour carry recognition and detail is reserved for close inspection."

Pack rule broken: ## Deliverable for writer legs item 5 ("Every claim needs a source a reader can check; unsourced claims will be cut by the chair") and ### Argon leg (review only) ("shipped-game claims with no source").

Offending line: "UNSOURCED KNOWLEDGE: Sins of a Solar Empire uses strong per-faction colour coding and clean, low-noise hull surfaces with detail concentrated at edges and lights, plus heavy use of icons and overlays at far zoom, accepting that the hull itself becomes a simple readable shape at strategy distance. Voidsworn's owner rates Sins as the presentation benchmark, per standing context this leg was given outside the pack: chair to confirm that framing before use."

Pack rule broken: ## Deliverable for writer legs item 5 ("Every claim needs a source a reader can check; unsourced claims will be cut by the chair"), ### Blind Rey leg (writer) ("Write from this pack only"), and ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "shipped-game claims with no source").

Offending line: "UNSOURCED KNOWLEDGE: EVE Online at tactical zoom replaces hull readability with brackets and overview icons entirely; the hull paint only has to work at hangar and mid-range distances. The lesson for Voidsworn is a boundary one: EVE can let paint be rich because the game does not ask paint to carry recognition at maximum distance. Voidsworn's battle camera at r=170 does ask that, so EVE's dirt and material richness is the part to copy (masked, zoned), not its freedom at range."

Pack rule broken: ## Deliverable for writer legs item 5 ("Every claim needs a source a reader can check; unsourced claims will be cut by the chair") and ### Argon leg (review only) ("shipped-game claims with no source").

Offending line: "UNSOURCED KNOWLEDGE: across real-time strategy games generally, the repeated pattern is detail budgets split by distance band, with texture resolution and shader detail fading as the camera pulls out. That is the industry form of clause 6's two band rule: richness is a close-range property, structure is the long-range property, and shipping both in one texture at one strength is what produces the round 5 complaint."

Pack rule broken: ## Deliverable for writer legs item 5 ("Every claim needs a source a reader can check; unsourced claims will be cut by the chair") and ### Argon leg (review only) ("shipped-game claims with no source").

D. Per-faction notes that break the shipped palettes or motif ownership (or R97)

Offending line: "Rust is a base tone here, not just wear, so rust plates obey clauses 2 and 3 like any tone, and the clause 5 rust share band (5 to 15 percent) applies to rust as wear inside soot plates; rust as a full plate tone counts toward the 3 tone limit instead."

Pack rule broken: Contradicts R97 ("Fix the paint recipe first (soot black base, rust as break-up, red only for trim plates, markings and light)"), ## What round 5 actually did (where the Ashfall Hullbreakers Pyre-Barge reference measured 85.41% dark/neutral, 13.62% rust, 0.97% red trim across the entire battle crop), and ## What round 4 showed ("V2 (regenerated AI hull): no clean cell; its colour distribution came out overwhelmingly rust red and failed the soot-and-rust balance"). Allowing full rust plates outside the 13.62% total rust budget breaks the R97 soot-and-rust balance.

E. Human-hour estimates (banned by R99)

None in rey_blind.md.

F. Naval vocabulary

Offending line: "Compare three things: the number of distinct value areas on the hull, the share of the hull in the darkest band (judged against the reference crop's balance, which measured 85.41 percent dark or neutral before blurring), and whether the big form breaks of the candidate (bow, midsection, stern, major fittings) can be pointed to without the unblurred image."

Pack rule broken: ## The job and ## Deliverable for writer legs ("space ships, not naval"), and ### Argon leg (review only) ("naval vocabulary"). Uses "bow" and "stern".

Offending line: "The hull's big forms can be named from the blurred crop alone: where the bow ends, where the midsection steps, where the stern fittings sit."

Pack rule broken: ## The job and ## Deliverable for writer legs ("space ships, not naval"), and ### Argon leg (review only) ("naval vocabulary"). Uses "bow" and "stern".

2. Review of deepseek.md

A. Standard clauses and claims that contradict R96, R97, R103, or the settled paint stack

Offending line: "The settled stack, by contrast, uses hand-placed wear on real edges and AO in recesses, which are both larger than 1 unit and therefore survive the battle camera."

Pack rule broken: Contradicts R96 and ## The settled paint stack item 1 ("Blender procedural smart materials driven by masks baked from the ship's own geometry (curvature/pointiness, AO, edge wear) driving soot, rust break-up and bare-metal exposure") and item 3 ("Open-source painters (Material Maker; ArmorPaint or Blender texture paint) for hero touch-up on flagships and problem panels only"). Wear in the settled stack is procedurally driven from baked geometry masks, not hand-placed, and ## What round 4 showed describes "short-distance AO grime, curvature-bounded bevel wear", not features guaranteed to be larger than 1 unit.

Offending line: "7. Grain: feature size at least 1 unit across, which is 15 px at 4K and 7.5 px at 1080p, contrast at or below 8 luma levels, and grain only in the close LOD."

Pack rule broken: Contradicts R103 ("grain cut") and ## What round 4 showed ("the close view wants more richness while the battle view wants less noise"). Sizing grain features at "at least 1 unit across, which is 15 px at 4K and 7.5 px at 1080p" turns micro-grain into mid-scale blotches at the battle camera while simultaneously stating "grain only in the close LOD", and neither 1 unit across nor 8 luma levels is backed by the pack or labelled INFERRED.

Offending line: "10. Median luma of the battle crop: 30 of 255, tolerance plus or minus 5 levels. The reference is 30.07. Round 5 V1 was 41.63 and V2 was 44.26, both outside the tolerance and both read as too bright and too even. Because the median luma is the value mass, a hull outside this range cannot read as a dark ground with a few lighter plates, whatever its colour bins say."

Pack rule broken: Contradicts ## Faction palettes (shipped). 30.07 is the median luma of the Ashfall Hullbreakers Pyre-Barge reference (soot black base) in ## What round 5 actually did. Making median luma 25 to 35 a mandatory clause for every hull in the game ("every hull is judged by") outlaws bright and mid-tone faction palettes such as Glasswrights (ithar): hull clear crystal white #eef3f1 and Hegemony: pale grey, steel blue, implant blue.

Offending line: "11. Construction precondition: a hull must score at least 7 of 9 clean construction cells before paint sign-off, or it is a paint test only and not a candidate for the standard."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The pack states that round 4 V3 scored "seven of nine construction cells clean" (## What round 4 showed), not that 7 of 9 is a binding threshold rule, and R103 explicitly enters V1 (0 of 9 clean construction cells) into round 6 (#187) alongside V3.

B. Numbers that do not derive from the pack's camera anchors or pack evidence (and unlabelled inferences)

Offending line: "At 1080p, 1 unit is 7.5 px, rounded to 8 px in the test record."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text"). ## Camera anchors states "about 15 px per unit at 4K... at 1080p roughly half that. The round 5 test captures were 1920x1080 (about 7 to 8 px per unit at battle distance)"; the pack never states "rounded to 8 px in the test record".

Offending line: "Major zone breaks should be 4 units, which is 60 px at 4K and 30 px at 1080p."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors") and ## The job ("label anything inferred"). The 4 units (60 px at 4K / 30 px at 1080p) number is not derived from the pack's camera math or blur math.

Offending line: "3. Minimum value step between neighbouring plates: 12 luma levels on the 0 to 255 scale, with 24 levels for major zone breaks. Because round 5's median luma sat 11 to 14 levels above the reference and still read as flat, 12 levels is the smallest step that can be seen as a deliberate break at battle distance, and 24 levels is the step for a major break that must read even after the blur."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). In ## What round 5 actually did, 11 to 14 levels is the difference in overall crop median brightness between round 5 (41.63, 44.26) and the reference (30.07), not the value step between neighbouring plates, and the owner called round 5 "a cluttered messy mix that is too busy", not "flat". Neither 12 luma levels nor 24 levels is labelled INFERRED.

Offending line: "4. Zone layout: no more than three base tones and no more than five major value breaks across the hull's visible side."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). "no more than five major value breaks" is not in the pack and is not labelled INFERRED.

Offending line: "Rust may occupy roughly 10 to 14% of the battle crop, close to the reference's 13.62%. It goes inside plates and along real edges, never as a scattered speckle across plate boundaries, and never as a base colour on its own. Because the reference uses rust as break-up inside a dark ground, and round 5 V1's 4.67% rust was too low to break up the ground while V2's 9.99% rust was still below the reference and scattered as small events."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The 10 to 14% band is not in the pack and is not labelled INFERRED, and the claim that V1's 4.67% and V2's 9.99% failed for being too low contradicts ## What round 5 actually did ("All colour bins passed within 10 percentage points of the reference").

Offending line: "All of the following must hold. Median luma is between 25 and 35. At least three distinct plate shapes survive the blur on the hull's visible side, each at least 15 px across at 1080p. No more than five value steps across the hull's visible side. Red trim is 0.5 to 1.0% of the crop, and bright red is 0% except for actual lights. Rust is 10 to 14% and is confined to plate interiors and real edges. Grain contrast is below 8 luma levels, and grain is not the only thing separating two plates."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## Faction palettes (shipped). Hard-codes Hullbreaker-specific colour percentages (Red trim is 0.5 to 1.0%, Rust is 10 to 14%) and luma (25 and 35) into universal pass criteria for all hulls, and uses unlabelled numbers (three distinct plate shapes, five value steps, 8 luma levels).

Offending line: "Any of the following fails the hull. Median luma above 35 or below 25. Fewer than three plate shapes survive the blur. Any plate smaller than 15 px at 1080p after the blur. More than 1.5% red, or any bright red on a plate. Rust patches smaller than 2 units, or rust scattered across plate boundaries. Grain contrast above 12 luma levels."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). Uses unbacked, unlabelled numbers (25, 35, More than 1.5% red, above 12 luma levels, which also contradicts Clause 7's at or below 8 luma levels).

Offending line: "Under the blur its large plates survive, its median luma is close to the reference, and its rust reads as broad break-up rather than speckle."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The pack never provides a median luma measurement for round 4 V3, and this statement is not labelled INFERRED.

C. Shipped-game claims with no source or a source that does not say what is claimed

Offending line: "Homeworld and Homeworld 2. Rob Cunningham, art director on Homeworld and Homeworld 2, says the team had to make sure each ship was identifiable by its silhouette from every angle, with simple forms and a bold colour scheme, because the player must read a ship before reading its detail. That is the same rule as the plate floor: silhouette first, detail second. https://www.gog.com/forum/general/interview_homeworlds_rob_cunningham_18367"

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "shipped-game claims with no source or a source that does not say what is claimed"). Not in the pack, and the cited GOG forum URL does not exist or verify the claimed quote.

Offending line: "Homeworld 3. The shipped game uses three UV channels for ships. One UV channel is non-mirrored and used for team colour and damage, one is mirrored for most of the hull, and one is used for decals. The MASK map packs dust and dirt in red, engine glow in green, panel lines in blue, and team colour in alpha, and a separate TEAM map holds the team colour. The lesson is to pack the readable information into masks, not to paint it as unique detail on every hull. https://mod.io/g/homeworld3/r/advanced-ship-creation"

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "shipped-game claims with no source or a source that does not say what is claimed"). Only the existence of packed texture sets with a mask channel (dust/dirt, engine, panel, team colour) plus a dynamic damage splat is in ## The settled paint stack; the three-UV-channel breakdown, RGBA channel assignments, and separate TEAM map cannot be backed up from the pack text or verified at the cited URL.

Offending line: "EVE Online. The V5++ rework repacked every ship texture map into a new system with albedo and roughness, added a material map in a four-to-one greyscale system, and expanded the dirt map so dirt accumulates in recesses and on lower surfaces. Dirt and killmarks are added as a separate layer on top of the base, and they do not change the base value structure. That is the same separation as the standard: base first, break-up second. https://www.eveonline.com/ru/news/view/the-many-additions-of-v5plusplus and https://www.eveonline.com/ko/news/view/dirt-killmarks-dirt-and-destruction-in-new-eden"

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "a source that does not say what is claimed"). Beyond the pack's statement ("EVE Online's V5++ uses packed PBR maps, a material map and a dirt map per ship"), the cited EVE Online devblogs describe a four-tone greyscale material map, _AR channel packing, and time-based hull dirt accumulation (0% dirt to 100% dirt) plus combat killmarks; they do not say "dirt accumulates in recesses and on lower surfaces" or "they do not change the base value structure".

Offending line: "Sins of a Solar Empire II. Each ship needs a _cl colour map with an alpha layer for team colour, a _da data map that carries metalness, reflection, bloom, and illumination, and a _nm normal map. At far zoom, ships become icons, and the game relies on the team colour and the silhouette, not on the painted detail. The lesson is to make the team colour a mask, not a painted area, and to keep the silhouette readable when the detail is gone. https://forums.stardock.com/492600/new-modded-ship-appears-as-team-color and https://forums.sinsofasolarempire2.com/search?tag=graphics%20icons%20zoom"

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "a source that does not say what is claimed"). Not in the pack, and the cited Stardock forum thread (492600/new-modded-ship-appears-as-team-color, December 2018) is a modding question for the original Sins of a Solar Empire, not Sins of a Solar Empire II, while the second URL is an unverified forum search query URL rather than a source document.

Offending line: "Battlefleet Gothic: Armada. The game renders ships in obsessive detail on Unreal Engine 4 and lets players zoom down to the finest detail, but the faction visual language is still carried by large shapes, broad colour blocks, and a shared silhouette family. The detail is a close-range reward, not the battle-range signal. The lesson is the same: detail that only survives at close range is not readability. https://staging.gamedeveloper.com/design/maxing-out-miniatures-making-a-successful-tabletop-adaptation and https://dtf.ru/games/2230923-seriya-battlefleet-gothic-armada-naibolee-atmosfernye-i-zrelishnye-igry-po-vselennoi-warhammer-40000"

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "a source that does not say what is claimed"). Not in the pack, and the cited Game Developer article (maxing-out-miniatures-making-a-successful-tabletop-adaptation, cited with a broken staging. prefix) is a short piece on tabletop-to-video-game adaptation and motion-comic cutscenes that does not say "the faction visual language is still carried by large shapes, broad colour blocks, and a shared silhouette family".

D. Per-faction notes that break the shipped palettes or motif ownership

Offending line: "The standard bends at the palette and the surface kind. It does not bend at the plate floor, the value step, the median luma, or the construction precondition."

Pack rule broken: ### Argon leg (review only) ("per-faction notes that break the shipped palettes"). Forcing every faction to obey a median luma of 25 to 35 breaks the shipped bright and mid-tone palettes (Glasswrights crystal white #eef3f1 and Hegemony pale grey / steel blue).

Offending line: "The faction's gold trim must stay at or below 1% of the crop, and it must follow a trim line, not a texture pattern, because gold on a pale ground is the first thing that reads as clutter if it is scattered."

Pack rule broken: Breaks ## Faction palettes (shipped) ("Hegemony: pale grey, steel blue, implant blue.") and ### Argon leg (review only) ("per-faction notes that break the shipped palettes"). Hegemony does not have gold trim in the shipped palette.

Offending line: "The Chorus palette is pale bone, deep teal, and violet glow, so the value step must be enforced between bone and teal, because bone and teal are close in value at battle distance. Violet glow must stay at 0% except for actual lights, because glow is the accent, not a base. If a zone is smaller than 2 units, it reads as a growth, not as a zone, and growths read as clutter."

Pack rule broken: Breaks ## Faction palettes (shipped) ("The Chorus: dark olive flesh, ochre bone chitin, bile yellow-green light. Organic hulls: grown, not plated."), ### Argon leg (review only) ("per-faction notes that break the shipped palettes"), and ## Deliverable for writer legs item 4 ("Chorus organic hulls included (zones instead of plates, where its "wear" lives)"). Replaces the shipped Chorus palette with "pale bone, deep teal, and violet glow" and omits where Chorus "wear" lives.

Offending line: "Keep the crystal white ground at or below luma 200, and make the pale gold trim a large plate, not a small accent, with a value step of at least 24 luma levels from the white ground. Mint light must stay at 0% except for actual lights, because mint is the accent, not a base. If crystal white is used at full brightness, the median luma rises above 35 and the hull fails the test, whatever its plate layout."

Pack rule broken: Breaks ## Faction palettes (shipped) ("Glasswrights (ithar): hull clear crystal white #eef3f1, trim pale gold #d7c88a, glow mint stored light #9fffd2.") and ### Argon leg (review only) ("per-faction notes that break the shipped palettes"). Turning "trim pale gold #d7c88a" into "a large plate, not a small accent" violates its shipped role as trim, and enforcing a median luma cap of 35 on a #eef3f1 (clear crystal white, luma ~242) hull destroys the faction's white palette.

Offending line: "The median luma must still be between 25 and 35, so the violet-black ground must not be darker than luma 20, or the hull fails on median luma even though its plates are clean."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text"). Imposes the unbacked 25 to 35 median luma rule and luma 20 floor on Eclipse (deathless) without INFERRED labelling.

E. Human-hour estimates (banned by R99)

None in deepseek.md.

F. Naval vocabulary

None in deepseek.md.

3. Review of qwen.md

A. Standard clauses and claims that contradict R96, R97, R103, the settled paint stack, or pack evidence

Offending line: "The colour bins passed. The median luma was close."

Pack rule broken: Contradicts ## What round 5 actually did, which states: "All colour bins passed within 10 percentage points of the reference; median brightness ran 11 to 14 levels above the art" (41.63 on V1 and 44.26 on V2 versus 30.07 on the reference).

Offending line: "Clause 5: Grain limits. Photo grain, scratch detail and micro-roughness features must be no smaller than 4 px at the 4K battle camera (roughly 0.27 units) and must not exceed a local contrast of 15 luma levels."

Pack rule broken: Contradicts R103 ("grain cut") and ## What round 4 showed ("the close view wants more richness while the battle view wants less noise. A usable standard has to separate the two distance bands instead of picking one recipe strength for both"), and misattributes "V2's grain follows a ragged generated surface" to the round 4 report when it is in ## What round 5 actually did (issue #163 report). Requiring grain features at the battle camera to be "no smaller than 4 px at the 4K battle camera" with up to 15 luma levels of contrast puts visible 4 px to 29 px noise blotches directly into the battle view instead of cutting battle-distance grain.

Offending line: "Clause 7: Recess and shadow rules. AO grime and recess shadow may darken panel gaps and geometry intersections but must not exceed a 40 luma-level drop from the surrounding plate value."

Pack rule broken: Contradicts R103 ("dark recesses") and breaks on bright hulls in ## Faction palettes (shipped) (Glasswrights crystal white #eef3f1 and Sunward Crusade frost white), where a maximum 40 luma-level drop prevents recesses from becoming dark.

Offending line: "Step 4: Place side by side. Set the blurred greyscale crop next to the same treatment of the round 4 reference (the V3 hand-built hull, which the build agent picked as the visual base that "reads at battle distance"). Both images get identical blur, identical greyscale conversion, identical crop framing."

Pack rule broken: Contradicts ## What round 4 showed, ## What round 5 actually did, and ## Deliverable for writer legs item 3. In the pack, the "round 4 reference" is the 2D reference art ("median brightness ran 11 to 14 levels above the art", "V3 (hand-built from the reference, 622,570 tris)"), whereas V3 is the hand-built 3D hull that the deliverable designates as "the round 4 V3 as the near-pass case", distinct from "the round 4 reference".

Offending line: "Because: the art is authored and reviewed at 4K in the round sheets."

Pack rule broken: Contradicts ## Camera anchors ("The round 5 test captures were 1920x1080 (about 7 to 8 px per unit at battle distance).").

B. Numbers that do not derive from the pack's camera anchors or pack evidence (and unlabelled inferences)

Offending line: "Red must not exceed 2% of the visible hull area in a battle crop."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The pack gives 0.97% red trim for the reference and 0.53% (V1) and 0.52% (V2) in round 5; the 2% cap is not in the pack and is not labelled INFERRED.

Offending line: "At battle distance, the smallest feature the eye can resolve on the ship is approximately 2 px at 4K (the minimum plate size divided by 15 px/unit gives 2 units, and features below about 2 px are sub-perceptual). At 1080p the equivalent is approximately 1 px. The blur radius is set to half the minimum plate size in pixels: 15 px at 4K (half of 30 px), 7 px at 1080p (half of 15 px)."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors"). Conflates 2 units (which equals 30 px at 4K) with 2 px at 4K in its camera math derivation, and truncates half of 15 px (7.5 px) to 7 px.

Offending line: "(a) Can I count the major plates (three to five per visible side)?"

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). "three to five per visible side" is not in the pack (and contradicts Clause 2's "INFERRED: 30 px is the practical floor drawn from the ratio of ship span (620 px) to a readable plate count of roughly 15 to 20 major zones per side") and is not labelled INFERRED.

Offending line: "No area of the blurred crop shows more than four distinct grey levels within a single 60 px patch (this would indicate value fragmentation below the plate scale)."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). Neither four distinct grey levels nor 60 px patch is in the pack or labelled INFERRED.

Offending line: "Trim accent invisible (blends into base) or dominant (exceeds roughly 5% of frame)."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). 5% of frame is not in the pack, is not labelled INFERRED, and contradicts Clause 6's 2% cap.

Offending line: "Owner review: screenshot comparison, estimated under five minutes per hull. (Sourced from the pack's round 5 and round 6 pipeline descriptions, where battle crops are already standard captures.)"

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The pack mentions "owner review minutes" as a unit format in ## The job, but never gives a figure of "under five minutes per hull".

Offending line: "Application: the base coat is black iron (dark tone, luma roughly 20 to 35)."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The luma range 20 to 35 for Sunward Crusade black iron is not in the pack and is not labelled INFERRED.

Offending line: "Application: pale grey is the base (mid tone, luma roughly 120 to 150). Steel blue is the secondary plate tone (slightly darker, luma roughly 80 to 110)."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The luma ranges 120 to 150 and 80 to 110 for Hegemony are not in the pack and are not labelled INFERRED.

Offending line: "Rust red-brown is the secondary plate tone (mid-dark, luma roughly 60 to 90). Dried blood red and hot red are trim and light only (clause 6, the R97/R103 red rule). The value step between soot black and rust brown is approximately 30 to 50 luma levels, satisfying clause 3."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The luma range 60 to 90 and step 30 to 50 luma levels are not in the pack and are not labelled INFERRED (and the shipped hex #6a2c22 in ## Faction palettes (shipped) has Rec. 709 luma 56.5, outside 60 to 90).

Offending line: "Trophy plates (flagship only): faded colours from other factions, one or two per hull, each above 30 px, treated as a mid-tone insertion. They must not exceed 5% of the hull area or they break the soot-and-rust balance."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). Neither "one or two per hull" nor "5% of the hull area" is in the pack or labelled INFERRED.

Offending line: "Olive flesh is dark (luma roughly 30 to 50). Ochre bone chitin is mid (luma roughly 100 to 130)."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). The luma ranges 30 to 50 and 100 to 130 for The Chorus are not in the pack and are not labelled INFERRED.

Offending line: "Crystal white is the base (luma roughly 220 to 240)."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). Not in the pack and not labelled INFERRED (shipped #eef3f1 has Rec. 709 luma 241.8).

Offending line: "Application: dark violet-black is the base (luma roughly 15 to 30, similar to the soot-black range)."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). Not in the pack and not labelled INFERRED.

Offending line: "Grain should sit at the low end of clause 5 (features above 6 px rather than 4 px, contrast below 10 levels)."

Pack rule broken: ### Argon leg (review only) ("numbers that do not derive from the pack's camera anchors", "cut anything you cannot back up from the pack text") and ## The job ("label anything inferred"). Neither above 6 px nor below 10 levels is in the pack or labelled INFERRED.

C. Shipped-game claims with no source or a source that does not say what is claimed

Offending line: "Source: the Homeworld Remastered art direction was discussed by Gearbox in their 2015 GDC talk and in the Steam community developer posts documenting the texture rework (available via the Homeworld Remastered Steam store page and GDC Vault listing "Homeworld Remastered: Updating a Classic RTS")."

Pack rule broken: ## Deliverable for writer legs item 5 ("Every claim needs a source a reader can check; unsourced claims will be cut by the chair") and ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "shipped-game claims with no source or a source that does not say what is claimed"). Not in the pack, gives no verifiable URL, and cites a fabricated GDC Vault talk title ("Homeworld Remastered: Updating a Classic RTS").

Offending line: "Source: R96 finding in the pack, originally from the Homeworld 3 shipped asset inspection and Blackbird Interactive's public GDC 2024 presentation on their ship pipeline (GDC Vault, "Building the Ships of Homeworld 3")."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "shipped-game claims with no source or a source that does not say what is claimed"). The pack does not cite "Blackbird Interactive's public GDC 2024 presentation on their ship pipeline (GDC Vault, "Building the Ships of Homeworld 3")", which is a fabricated GDC Vault listing.

Offending line: "Source: Tindalos Interactive developer blogs on the Steam community hub for Battlefleet Gothic: Armada (2016 posts detailing the ship texturing pipeline), and the Focus Entertainment press kit for Armada 2 (2019) which includes art-direction documents showing the palette-per-faction approach."

Pack rule broken: ## Deliverable for writer legs item 5 ("Every claim needs a source a reader can check; unsourced claims will be cut by the chair") and ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "shipped-game claims with no source or a source that does not say what is claimed"). Not in the pack, and provides only vague, uncheckable references without titles, dates, or URLs.

Offending line: "Source: Ironclad Games' developer journals on the Sins of a Solar Empire forums (archived at the Wayback Machine and the Steam community hub), and the game's shipped texture sets which show low-resolution diffuse maps optimised for the strategy camera. The Rebellion expansion art notes are included in the game's digital art book (shipped with the Collector's Edition, 2012)."

Pack rule broken: ## Deliverable for writer legs item 5 ("Every claim needs a source a reader can check; unsourced claims will be cut by the chair") and ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "shipped-game claims with no source or a source that does not say what is claimed"). Not in the pack, and cites generic forum archives and a physical collector's edition book without checkable titles, dates, or URLs.

Offending line: "Additionally, CCP's public GDC presentations (GDC 2014, "The Graphics of EVE Online: V5 and Beyond," available on GDC Vault) and the EVE Online developer blog posts on the V5 shader overhaul (community.eveonline.com, 2014 to 2016 archive)."

Pack rule broken: ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "shipped-game claims with no source or a source that does not say what is claimed"). The pack (## The settled paint stack) only states that "EVE Online's V5++ uses packed PBR maps, a material map and a dirt map per ship"; the tactical distance claims are not in the pack, and "The Graphics of EVE Online: V5 and Beyond" at GDC 2014 is a fabricated GDC Vault talk title.

Offending line: "Source: Petroglyph Games' shipped asset structure (inspectable in the game's modding community documentation, specifically the Empire at War Modding Wiki hosted at empireatwar.fandom.com, which documents the texture and model pipeline)."

Pack rule broken: ## Deliverable for writer legs item 5 ("Every claim needs a source a reader can check; unsourced claims will be cut by the chair") and ### Argon leg (review only) ("cut anything you cannot back up from the pack text", "shipped-game claims with no source or a source that does not say what is claimed"). Not in the pack, and cites a top-level wiki domain (empireatwar.fandom.com) rather than a verifiable source page backing the readability claims.

D. Per-faction notes that break the shipped palettes or motif ownership

All six faction palettes and motif assignments in qwen.md Section 4 match the names and hex codes in ## Faction palettes (shipped), subject to cutting the unlabelled luma ranges, the unlabelled 5% trophy-plate cap, and Clause 7's 40-luma recess drop limit listed in Sections 3.A and 3.B above.

E. Human-hour estimates (banned by R99)

None in qwen.md (uses agent terms and owner review minutes, though the "under five minutes per hull" figure must be cut or marked inferred because it is falsely attributed to the pack, as noted in Section 3.B).

F. Naval vocabulary

Offending line: "The silhouette reads as a barge with distinct superstructure blocks."

Pack rule broken: ## The job and ## Deliverable for writer legs ("space ships, not naval"), and ### Argon leg (review only) ("naval vocabulary"). Uses "superstructure".

Offending line: "The material map drives large-zone variation (armour plates vs. hull vs. superstructure) without requiring unique textures per zone."

Pack rule broken: ## The job and ## Deliverable for writer legs ("space ships, not naval"), and ### Argon leg (review only) ("naval vocabulary"). Uses "superstructure".

4. What survives across the legs (backed by PACK.md)

Section 1 (Why round 5 read as cluttered): Colour histogram bins passed within 10 percentage points of the round 4 reference (85.41% dark/neutral, 13.62% rust, 0.97% red trim, 0.00% bright red, median luma 30.07 vs V1 94.76% dark, 4.67% rust, 0.53% red, median luma 41.63 and V2 89.49% dark, 9.99% rust, 0.52% red, median luma 44.26), while median brightness ran 11 to 14 luma levels above the reference art (rey_blind.md, deepseek.md). Value structure and zone size: round 5 assigned soot shades to connected surface regions and turned small bounded regions into trim plates, with rust breaking up the coat within plates and along real edges, creating many small patches below readable plate scale at r=170 (15 px/unit at 4K, 7 to 8 px/unit at 1080p on a 41.6 unit ship spanning ~620 px at 4K and ~310 px at 1080p) (rey_blind.md, deepseek.md, qwen.md). Noise frequency versus camera: PaintedMetal004 supplied scratches, displacement, and roughness detail (0.61 to 0.88) that adds richness in close material crops (where round 4 noted weathering and grain were "too subdued" on V1 and V3) but turns into surface noise at the r=170 battle camera, worsened on V2 where grain followed a ragged generated surface (rey_blind.md, deepseek.md, qwen.md). Melted geometry underneath: both round 5 AI hulls scored 0 of 9 clean construction cells (fused cylinders, torn panels, floating blocks, blended roots), corrupting geometry-derived masks (curvature, AO, edge wear), whereas round 4's hand-built V3 scored seven of nine construction cells clean and its palette "reads at battle distance" under the same recipe family (rey_blind.md, deepseek.md, qwen.md).

Section 2 (Paint readability standard): Camera anchors: r=170 units, 1:1 pixels, 15 px/unit at 4K (~620 px for 41.6 units), 7.5 px/unit (7 to 8 px/unit) at 1080p (~310 px for 41.6 units) (rey_blind.md, deepseek.md, qwen.md). Base coat limited to two or three tones with few big plates and dark recesses (R103), procedural masks baked from geometry (curvature, AO, edge wear) on top of the faction trim sheet (R96), soot black base with rust as break-up (R97), red restricted to trim plates, markings, and light only (R97, R103, reference 0.97% red trim, 0.00% bright red), only real lamps and engine throats emitting light (issue #163 report), grain cut at battle distance (R103) and separated from the close-range material band (issue #146 report) (rey_blind.md, deepseek.md, qwen.md). Minimum plate size of 2 units (30 px at 4K, 15 px at 1080p) and any luma-step or grain-contrast thresholds survive only when explicitly marked INFERRED as derivations from the camera math and reference luma (deepseek.md Clause 2 2 units, qwen.md Clause 2 30 px at 4K / 15 px at 1080p and Clause 3 25 luma levels when marked INFERRED).

Section 3 (Blurred greyscale battle crop test): Capturing candidate and round 4 reference art crops at r=170, 1:1 pixels (1920x1080 and 3840x2160), converting to greyscale, blurring at a radius tied to the camera anchor math (1 unit = 7.5 px at 1080p / 15 px at 4K in deepseek.md and qwen.md, labelled INFERRED), and comparing candidate against the round 4 reference art crop with round 5 V1 as the fail example and round 4 V3 as the near-pass example (rey_blind.md, deepseek.md). Effort framed strictly in agent terms: one-time script build, per-hull unattended run, and owner review minutes (rey_blind.md, qwen.md without the unsourced 5-minute claim).

Section 4 (Per-faction notes): All six shipped palettes and motifs as stated in ## Faction palettes (shipped) (rey_blind.md, qwen.md), including The Chorus (dark olive flesh, ochre bone chitin, bile yellow-green light) using continuous growth zones (flesh, chitin, bone ridge) instead of plates and placing organic wear (scarring, callus, bruising, chitin cracking) along growth joins, folds, and ridges (rey_blind.md, qwen.md).

Section 5 (Shipped space games): Only the two pack-sourced claims in ## The settled paint stack survive verification: (1) Homeworld 3 ships carry packed texture sets with a mask channel (dust/dirt, engine, panel, team colour) plus a dynamic damage splat, and (2) EVE Online's V5++ uses packed PBR maps, a material map, and a dirt map per ship (rey_blind.md paragraph 2 of section 5; the pack-backed portion of qwen.md on Homeworld 3 and EVE Online; and deepseek.md's two EVE Online devblog URLs only for what they actually state: four-tone greyscale material map, _AR albedo/roughness packing, and time-accumulated dirt plus killmarks).

5. Consolidated cut list

rey_blind.md: Cut the ban on painting failed construction cells in Clause 5, Clause 10, and Owner Question 4's pick for contradicting R103. Cut or label INFERRED all unbacked numbers in Clause 2 (20 px, 10 px, 1.3 units), Clause 3 (25 levels), Clause 4 (40 luma levels), Clause 5 (5 and 15 percent), Clause 6 (4 px across at 4K (2 px at 1080p), 8 luma levels), Clause 7 (2 percent), and Section 3 Step 3 (radius 5 px at 1080p (10 px at 4K), 0.7 units). Cut the exemption in Section 4 (Ashfall Hullbreakers) allowing "rust as a full plate tone" outside the reference's 13.62% rust budget (R97). Cut the naval terms "bow" and "stern" in Section 3 Procedure 4 and Pass criteria. Cut all five "UNSOURCED KNOWLEDGE" paragraphs in Section 5.

deepseek.md: Cut "uses hand-placed wear on real edges and AO in recesses, which are both larger than 1 unit" in Section 1 for contradicting R96 and ## The settled paint stack. Cut Clause 7's "feature size at least 1 unit across" for contradicting R103 ("grain cut"), and cut the conflicting unlabelled grain contrast caps (8 luma levels vs 12 luma levels). Cut the universal 30 of 255, tolerance plus or minus 5 levels (25 to 35) median luma requirement in Clause 10, Section 3 Pass/Fail criteria, and Section 4 for breaking the shipped bright/mid palettes. Cut or label INFERRED "rounded to 8 px in the test record", Clause 2's 4 units, Clause 3's 12 luma levels and 24 levels (and its false premise that 11 to 14 levels was a plate step and that round 5 read as "flat"), Clause 4's "no more than five major value breaks", Clause 6's 10 to 14% rust band and false claim that round 5 V1/V2 failed the rust bin, Clause 11's 7 of 9 clean construction cells gate (as a settled rule; it survives as an owner question), Section 3's universal Hullbreaker colour percentages, and Section 3's unbacked claim that round 4 V3's "median luma is close to the reference". Cut the invented "gold trim" in Section 4 Hegemony, the false "pale bone, deep teal, and violet glow" palette in Section 4 The Chorus, and the directive in Section 4 Glasswrights making "pale gold trim a large plate, not a small accent". Cut the unverified/misattributed shipped-game claims and URLs in Section 5: the dead GOG forum URL, the unbacked three-UV/RGBA/TEAM map claims and dead mod.io URL, the unsupported EVE recess claim, the misattributed Sins 1 forum thread (492600) and search URL used for Sins of a Solar Empire II, and the unsupported visual-language claim attributed to the staging.gamedeveloper.com article.

qwen.md: Cut "The median luma was close." in Section 1, the misattribution of "V2's grain follows a ragged generated surface" to round 4 in Clause 5, the conflation of "the round 4 reference (the V3 hand-built hull...)" in Section 3 Step 4, and "Because: the art is authored and reviewed at 4K in the round sheets." in Section 6 Question 1. Cut Clause 5's grain floor for contradicting R103 ("grain cut" at battle distance). Cut Clause 7's "must not exceed a 40 luma-level drop" for contradicting R103 ("dark recesses") and breaking bright faction palettes. Cut or label INFERRED Clause 6's 2% cap, Section 3 Step 3's confusion of 2 units with 2 px at 4K, Section 3's "three to five per visible side", "more than four distinct grey levels within a single 60 px patch", and "exceeds roughly 5% of frame", the false attribution of "estimated under five minutes per hull" to the pack, and all unlabelled per-faction luma bands, trophy-plate limits, and Eclipse grain numbers in Section 4. Cut the naval term "superstructure" in Section 3 and Section 5. Cut all unsourced and fabricated citations in Section 5: the fabricated GDC talks ("Homeworld Remastered: Updating a Classic RTS", "Building the Ships of Homeworld 3", "The Graphics of EVE Online: V5 and Beyond"), and the uncheckable descriptions for Homeworld (1999) and Homeworld Remastered (2015), Battlefleet Gothic: Armada, Sins of a Solar Empire, EVE Online (beyond the pack's R96 sentence), and Star Wars: Empire at War.
