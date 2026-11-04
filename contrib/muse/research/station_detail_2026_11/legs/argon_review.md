# Argon review leg (filed with chair screening header)

CHAIR SCREENING (read first): Argon High ran with both gates verified, and this is the strongest Argon review of the recent run: it is grounded in PACK.md and station_kit.py line references, and most of it is adopted in the synthesis. Items the chair did NOT adopt as stated, with reasons:

- The blanket claim that any height change "mutates locked R94 elements". R94 locks the shape pass (the element set and layout approved in PR #151) and in the same ruling directs the detail pass to add more height and asymmetry seen from above. The synthesis resolves this as an additions-only doctrine: locked primitives are not moved, resized in plan, or deleted, but new elements may be added and surface stepping added on top. Argon's specific catches under this heading are adopted wherever a leg MOVED or RESIZED a locked element (all of the Qwen list; DeepSeek's tank and radiator edits), and not adopted where a leg only added height on top.
- The budget framing: Argon is right that DeepSeek's 85k / 1.0 ms reads as additive on top of the 306k / 3.9 ms measurement, and right about Qwen's internal sum mismatch (its components total 13.5k to 19k, not 18k to 22k). Neither leg measured anything; the synthesis carries no adopted number, only two unmeasured bounds as an owner question, with counting as step 1 of the Codex job.
- Sub-0.5-unit detail: adopted as a reclassification, not a cut. Everything under 1 unit is texture, trim or normal work, never mesh; the legs' close-zoom language survives under that rule.
- The blind Rey leg: Argon's screening is adopted. The blind leg was written from the issue brief alone and its station taxonomy (rings, discs, four types, per-faction silhouettes) conflicts with R79, R84 and R94; the synthesis uses it only where it converges with the pack (the flat-read diagnosis and the height-stepping principle).
- Reference fact checks (Coriolis is a cuboctahedron, DS9 has three pylons, Tycho is a ring station, "Rociofuerte" is not an Expanse station): adopted. Neither writer leg retrieved a single source, so the synthesis carries no reference descriptions, only the convergent design lessons, labelled unverified.

Adopted in full: the working-face mast cut, the refinery axial-cradle error, the flare stack cut (rule and vocabulary), the material-slot cut, the faction panel-depth cut, the audit-assert catch (reframed: flag for Opus, do not rewrite), the deck z-math correction, the plan-view axis correction, the vocabulary list, and the surviving-claims map in its section 5.

Argon's text follows, with non-ASCII punctuation normalized to ASCII by the chair. Wording otherwise verbatim.

---

Both gates verified: the model picker button and the prompt bar both read "Argon High" before sending, and the prompt bar again read "Argon High" after sending.

1. Claims Not Supported by the Evidence Pack (Ruling and Geometry Violations)
DeepSeek Draft (deepseek.md)

Violates working-face vs. service-face separation: Section 3.1 places a new control/sensor mast at x = +7.5 on the working face (+Y side) and explicitly states this "breaks the current 'all tall elements on service side' rule for the detail pass". In PACK.md, the #102 synthesis locks working-face vs. service-face separation as a shared rule (berths, batteries, and lit guides on the working face; radiators, tanks, and cable runs on the service face, with all R91 skyline towers on -Y). DeepSeek contradicts its own Section 2 claim that "working face vs service face separation retained".

Mutates locked R94 elements while claiming to freeze them: Section 9 instructs Codex to "Freeze the R94 locked shapes", and R94 approves the R91 towers, gantry, refinery column, drums, and tanks as the locked shape. Yet Sections 3.1 and 3.2 directly alter the dimensions of those locked primitives:

Raises the locked x = -18 secondary sensor tower top from z = 8 (station_kit.py:122-134) to z = 10.5.

Changes the locked fleet radiator fins at x = +/-6 (both top about z = 8 in station_kit.py:122-134) to z = 10 on -x and z = 8.5 on +x.

Alters the locked refinery service tanks at x = +/-13, y = -12 by raising -x to z = 6 and lowering +x to z = 4.5.

Lowers the locked refinery +x heat radiator bank from top about z = 10 (station_kit.py:137-159) to z = 8.5 and angles one fin 15 degrees outboard.

Breaks the #102 refinery single-tall-element rule twice: PACK.md states under #102 synthesis: "Refinery: one tall element only in the #102 spec (12 to 16 units)". Section 3.2 adds two more tall vertical elements to the refinery: a secondary process column (x = +7, y = -4, top about z = 11) and a flare/vent stack (x = -5, y = -9, top about z = 14). R94 asks for height and asymmetry seen from above, but it does not repeal #102's single-tall-element rule for the refinery.

Falsely claims the refinery shares the fleet station's axial cradle: Section 4.2 states that refinery docking includes "the axial cradle shared with the fleet kit". Per PACK.md (station_kit.py:81-159), only the 46-unit spine is shared; the axial battleship cradle (y = 13) belongs exclusively to the fleet station (station_kit.py:96-120).

Mislocates the fleet station Stage 4 break line and invents an R98 exemption: PACK.md (#102 synthesis) specifies that the fleet station Stage 4 break occurs "at a radial-arm and spine junction". Section 6 places the fleet break lines at the x = -11.5 battery/spine junction and the axial-cradle/spine junction. Section 6 also claims "thin gantry/truss members are exempt from break-line interiors", an exemption that does not exist in R98.

Invents vehicle props not in the kit: Sections 4.1 and 4.2 add "small shuttle/loader props" and "small maintenance skiffs" to the station meshes. R79 restricts the kit to "the game's own ship parts" and R96 Q5 restricts new parts to hand-built station kit parts or a reviewed per-faction part library.

Misattributes #129 to the R96 Q1 mask bake pipeline: Section 11 states: "The R96 Q1 station mask bake pipeline is proposed by analogy to ships; confirm with the ship repair test (#129) winner before locking the station method". In PACK.md, #129 is referenced in R91 for detail part construction ("detail built with whichever method wins the ship repair test (#129), possibly AI-generated parts"), whereas the R96 Q1 procedural mask-baked paint route is already a binding ruling.

Qwen Draft (qwen.md)

Moves, resizes, and deletes R94 locked geometry: PACK.md R94 locks the R91 pass shapes. Qwen's Chair Gate Note acknowledges this violation up front. Specifically, Sections 1.3, 1.4, and 7 illegally alter locked R94 primitives:

Moves the fleet station's locked service truss to x = +9.

Reshapes the fleet station's locked x = 0 antenna array into a 7 x 5 L-shape.

Shrinks the refinery's locked x = +16 output drum from radius 3 (station_kit.py:137-159) to radius 2.2.

Shifts the refinery's locked central cracking tower off-centre to x = +2 and leans it.

Deletes the refinery's mirrored service tank pair at x = +13, y = -12 and replaces it with a single radius 3.5 tank and a 4 x 3 x 2 "processing shed".

Lowers the refinery's locked x = +13 heat radiator from z = 10 to z = 7.5.

Reroutes the refinery's locked drum-height pipe bridges into a 10-degree diagonal and a z = 5 bridge.

Directs Codex to rewrite standing audit assertions: Section 7 instructs Codex to "Update the audit assert (station_kit.py:202-208) to check new z values". Modifying the audit test suite to pass altered baseline geometry is not authorized by PACK.md.

Breaks the #102 refinery single-tall-element rule: Section 1.4(b) adds a secondary vertical pipe column running from z = 4 to z = 11 next to the cracking tower, violating #102's "one tall element only" rule for the refinery.

Violates fleet station R80/#102 break-line rules: PACK.md states that fleet station "batteries degrade before the spine breaks; stage 4 break at a radial-arm and spine junction". Section 6.3 places Break Line 1 across the spine itself (x = -4.6, between modules 2 and 3), Break Line 2 at the x = +11.5 dorsal battery mount, and Break Line 3 at the y = 13 cradle rail, omitting the radial-arm and spine junction. Similarly, Section 6.4 Break Line 2 topples the refinery cracking tower at its base, whereas #102 specifies the refinery Stage 4 break is "at a tank or drum mount".

Collapses the three export material slots into one: PACK.md (station_kit.py:26-37, 212) exports static parts into one mesh with three material slots (structure, armor, accent). Section 5.7 proposes "Replacing the three material slots (structure, armour, accent) with a single procedural material per station type", which removes the slot separation used for structure, armor, and faction trim/accents.

Introduces faction-specific geometry depth: Section 2.5 specifies "Panel lines crisp" for Glasswrights versus "Panel lines deeper" for Hullbreakers, while Section 2.1 models panel lines as 0.15-unit recessed geometry. Under R84 Q4 and #102, station geometry is strictly faction-neutral and shared across all maps.

Drops required close-zoom traffic and life signs from the station brief: PACK.md ("Done when") requires close-zoom detail language for "traffic and life signs" per station type. Sections 2.1 and 2.2 punt ship traffic, pipe flow animations, and venting particles to "game-side" systems outside the station detail pass.

Rey Blind Draft (rey_blind.md)

Because rey_blind.md was written without reading PACK.md, its core structural premises conflict with binding rulings and must be screened out by the chair:

Assumes disc, ring, and torus stations ("symmetric disc or ring", "past the ring on one side", "hub, ring segments"), contradicting the locked 46-unit linear spine in R79, R91, and R94.

Assumes four station types (dock/shipyard, refinery/industrial, fortress/defence, habitat/trade hub), contradicting R79's two-station limit (fleet station and refinery).

Proposes bespoke faction silhouettes and geometry (Hullbreaker bolted-on captured hulls, Chorus organic bulbs and membranes, Glasswright transparent prisms and lens towers, Eclipse off-centre core tower, Sunward Crusade gothic arches and cathedral spires), directly violating R84 Q4 and #102 ("faction identity in paint and lit accents only, never silhouette").

Proposes keeping 6 to 10 separate module meshes per station and breaking only at module joints ("never through a module"), contradicting station_kit.py:212 (which merges static geometry into one mesh at export) and R98 (authored break lines with internal decks, bulkheads, and hull thickness).

2. Unverified, Unbacked, or Hallucinated Sources

Zero verified sources across all three drafts:

deepseek.md Section 8 admits its reference list is [INFERRED reference list; not yet verified frame-by-frame in this run] and cites only generic placeholders ("series production design and screen captures", "in-game captures and public wiki").

qwen.md Section 3 marks all eight of its reference entries Verification: NOT VERIFIED via live search. Description from training knowledge.

rey_blind.md marks its references (from memory, sources for the chair to verify).

Hallucinated and factually false reference claims:

Hallucinated station name (qwen.md Section 3.8): Qwen cites "Rociofuerte and Tycho Station (The Expanse, Alcon Entertainment / Syfy, 2015-2022)". There is no "Rociofuerte" station in The Expanse (a hallucinated mashup of the ship Rocinante).

False description of Tycho Station (deepseek.md Section 8 and qwen.md Section 3.8): DeepSeek claims Tycho Station is a reference for "refinery column, tanks and process read", and Qwen claims Tycho Station has a "silhouette [that] is lumpy and asymmetric because modules are added over time and do not match". In The Expanse, Tycho Station is a symmetric mobile engineering platform dominated by a giant circular habitat ring around central spherical construction domes, not an asymmetric lumpy cluster or a refinery column.

False geometry for Elite Dangerous stations (qwen.md Section 3.6): Qwen states "the Coriolis station is a cube with a central docking slot. The Orbis is a ring with a flattened profile". A Coriolis station is a 14-sided cuboctahedron (not a cube), and an Orbis station is a long axial spindle with rotating habitat rings and solar arrays (not just a flattened ring).

False geometry for Deep Space Nine (qwen.md Section 3.1): Qwen describes DS9 as having a single "central pylon" that is "tall and asymmetric relative to the ring plane". DS9 has a central core and three radially symmetric curved docking pylons (each sweeping above and below the ring plane), not one asymmetric central pylon.

False geometry for Mass Effect's Citadel (qwen.md Section 3.3): Qwen states the Citadel's five arms "create a clear pinwheel silhouette". The five Ward arms extend axially forward from the Presidium ring rather than radiating like a flat pinwheel.

False geometry for Babylon 5 (deepseek.md Section 8): DeepSeek cites Babylon 5 for a "tall central spine". Babylon 5 is a horizontal rotating cylinder with an axial docking/support spine running along its length, not a tall vertical spine.

3. Numbers That Do Not Follow from Camera and Budget Anchors

Camera & Geometry Math Errors (170 units out, 15.4 px/unit at 4K; < 0.5 units = wasted geometry; < 1 unit = texture only; 1-2 units = secondary read; >= 2 units = shape; gaps < 4 units = noise)

deepseek.md Sub-0.5-Unit Wasted Geometry and Threshold Failures:

Wasted geometry (< 0.5 units): Section 4 proposes 0.05-0.1-unit panel seam gaps, a 0.2-unit radiator edge frame, 0.1-0.2-unit antenna lattice members (1.54 to 3.08 px at 4K), 0.2-unit cradle guide rails, 0.2-unit refinery locking collars, and 0.3-0.5-unit control tower windows. Any of these built as mesh geometry rather than texture/trim violates the < 0.5 units is wasted geometry anchor.

Misclassified secondary-read props: Section 4.1 labels 0.5-1.5-unit shuttle/loader props as "texture-read at battle camera", but 1.0 to 1.5 units falls in the 1 to 2 units is secondary read band, not the < 1 unit texture band.

Shape additions that fail the >= 2 unit silhouette rule:

Section 3.1 places a stepped dorsal box at x = -12 with top face at z = 3.5 on the z = 2 spine. Its height above the spine is 3.5 - 2.0 = 1.5 units, which is below the 2-unit threshold required to read as shape.

Section 3.1 restricts the open gantry arch (x = +2 to +5) to "under 2 units member thickness", which guarantees the arch members fall below the 2-unit shape threshold.

Section 3.2 gives the refinery flare stack a 1.5-unit diameter and the elevated pipe run a 1-unit diameter; both are under 2 units in plan width and cannot read as primary shape from 170 units.

Section 3.2 steps the service tanks to z = 6 and z = 4.5, a 1.5-unit differential that fails the 2-unit threshold.

Gaps under 4 units and footprint collisions:

In PACK.md, the spine sits at y = -4 with width 6 (spanning y = -7 to y = -1). DeepSeek's gantry arch at x = +2 to +5 spans y = -6 to +6, meaning its -Y leg lands at y = -6 inside the spine module volume instead of clearing y = -7.

Placing <= 4-unit dorsal boxes at x = -4 and x = +4 alongside the x = 0 control tower, the x = +2 to +5 gantry arch, and the x = +7.5 mast creates gaps well under the 4-unit noise floor (and direct overlap at x = +2 to +5).

qwen.md Coordinate, Dimension, and Camera Math Errors:

False spine module coordinates: Section 1.3(a) places the five spine modules at x = -18.4, x = -9.2, x = 0, x = +9.2, and x = +18.4. In PACK.md (station_kit.py:81-94), five modules span from x = -18.4 to 18.4 (36.8 units between the 4 x 8 x 5 end caps, making total length 46). Treating -18.4 and +18.4 as module centres with 9.2-unit spacing would push the five modules out to x = +/-23.0 (46 units before adding the two 4-unit end caps, making the station 54 units long and failing the length == 46 audit check).

Broken internal deck z-math: In PACK.md, each spine module is 9.2 x 6 x 4 at y = -4, z = 0 (top face at z = 2), so the module extends vertically from z = -2 to z = +2. Section 6.6 places the two internal decks at z = 0.5 and z = 1.2, crowding both decks into a 0.7-unit band near the top face and leaving 2.5 units empty below.

Plan-view axis confusion: Section 1.3(e) splays the antenna array in "plan view" by extending "4 units in +x and the short arm 2.5 units in -z (plan view)". Looking down from the top-down battle camera, the plan-view axes are X and Y; Z is vertical height.

Sub-0.5-unit geometry built as mesh: Sections 2.1, 2.2, 6.5, and 6.6 propose mesh geometry below the 0.5-unit wasted-geometry threshold: 0.15-unit panel line depth, 0.3-unit coupler collars, 0.2-unit bolt heads, 0.3-unit antenna struts, 0.15-unit cable tubes, 0.2-unit sensor stalks, 0.4-unit cargo guide arms, 0.2 to 0.3-unit hull wall thicknesses, and 0.15-unit interior ceiling pipes.

Overlapping silhouette breaks (< 4-unit gap violation): Section 1.5 counts x = +13 (tank and shed) and x = +16 (output drum and manifold) as separate longitudinal silhouette breaks. A radius 3.5 tank at x = +13 reaches x = +16.5, and a radius 2.2 drum at x = +16 starts at x = +13.8; they overlap in X with zero gap, violating the < 4 units read as noise rule.

Triangle and Frame Budget Math Errors (R96 Q3 anchor: ~306k triangles and 3.9 ms measured at 20 ships)

deepseek.md Blows Past the R96 Q3 Ceiling:

Section 7 notes that the R96 Q3 ceiling (306k triangles, 3.9 ms) is measured at 20 ships and states "The 20-ship frame includes the ships; stations are additive".

DeepSeek then allocates <= 40k triangles for the fleet station, <= 45k for the refinery, and <= 85k triangles (~28% of 306k) / <= 1.0 ms (~26% of 3.9 ms) for stations in a 20-ship frame.

Because 306k triangles and 3.9 ms is already the measured cost of 20 ships near the stage 5 barge ceiling, adding 85k triangles and 1.0 ms pushes a 20-ship + station frame to ~391k triangles and ~4.9 ms. Conversely, if kept inside 306k / 3.9 ms, taking 85k / 1.0 ms for stations reduces the 20 ships to 221k triangles (~11k per ship) and 2.9 ms, which contradicts the R96 Q3 benchmark.

qwen.md Fails Basic Addition and Mixes Station Texture Budgets:

Component sum does not match stated station total: Section 4.2 budgets the fleet station at 18,000 to 22,000 triangles. However, summing Qwen's own Section 4.3 fleet station breakdown (4,000-5,000 spine + 2,500-3,500 towers/masts/antenna + 2,000-3,000 cradle/arms + 1,500-2,000 batteries + 1,500-2,500 radiators/trusses + 2,000-3,000 greeble) equals 13,500 to 19,000 triangles, not 18,000 to 22,000.

Invented 20-ship subtotal: Section 4.2 claims 20 ships at stage 5 barge density consume 250,000 to 270,000 triangles, contradicting PACK.md, which states that ~306k triangles and 3.9 ms is measured at 20 ships.

Invalid texture memory math: Section 5.5 adds both fleet-only textures (1024 x 1024 cradle/berth hardware) and refinery-only textures (2048 x 2048 drums/cracking tower/tanks) into a single per-station sum of ~20 million texels (80 MB). It also claims per-module baked curvature, AO, and edge-wear masks require "not separate texture memory" because they are "baked into the above maps", which is impossible when those maps are shared trim sheets and decal atlases.

4. Naval and Oil-Rig Vocabulary Creeping Into the Briefs

PACK.md House Rule: "space stations, not naval or oil-rig looks". While PACK.md retains legacy code identifiers from station_kit.py (berths, cracking tower, drums, gantry, hull, bulkhead, dorsal/ventral, turret), the drafts introduce new naval, maritime, and offshore oil-rig/petrochemical vocabulary that violates the house rule:

deepseek.md:

"flare/vent stack", "flare stack", "2-unit flare tip", "flare stack base" (Sections 3.2, 4.2, 9, 10): Offshore oil-rig / petrochemical gas-burning flare stack (physically nonsensical in vacuum).

"vertical ladder cages and platform rings at 3-unit intervals" (Section 4.2): Terrestrial oil-rig / refinery 1G fall-protection ladder cages and catwalk rings.

"valve wheels" and "sampling probes" (Section 4.2): Terrestrial oil-patch plumbing hardware.

"maintenance skiffs" (Section 4.2): Maritime boat terminology.

qwen.md:

"Tank farm" (Section 1.4c): Petrochemical refinery / oil-terminal terminology.

"processing shed (4 x 3 x 2 units)" / "shed" (Sections 1.4c, 1.5, 3.8, 7): Terrestrial industrial yard shed.

"port versus starboard" (Section 1.3c): Naval ship directional terminology applied to a station (where PACK.md uses +x/-x and working face (+Y) / service face (-Y)).

"oil staining" (Section 3.7): Oil-rig / terrestrial machinery grime.

"empty or residual fluid surface" (Section 6.4): Assumes a 1G horizontal liquid pool inside a ruptured tank.

rey_blind.md:

"flare or vent stack" (Section "Silhouette and height rules"): Oil-rig flare stack.

"gun decks stepped like a ziggurat" (Section "Silhouette and height rules"): Naval warship / terrestrial fortress terminology.

"tug" (Section "Close zoom detail language"): Maritime harbor boat terminology.

5. Surviving Draft Claims and What Backs Them in PACK.md

Scope locked to two station kinds (fleet station and refinery) from one shared Blender kit, with relay beacon and intercept transports out of scope except shared parts: Survives in deepseek.md Section 1 and qwen.md Section 8 Q4. Backed by PACK.md R79 (FINDINGS line 107) and #102 synthesis.

Baseline R91/R94 coordinates, dimensions, and standing assertions:

Shared 46-unit spine (5 modules across x = -18.4 to 18.4, each 9.2 x 6 x 4 at y = -4, z = 0, top face at z = 2, couplers, 4 x 8 x 5 end caps; audit asserts length == 46 and skyline hi z >= 15).

Fleet station: +Y axial battleship cradle (outer rail y = 13), two service-side frigate berths, four twin batteries at x = +/-11.5 dorsal/ventral with separate turret origins, x = 0 control tower (top z = 11.4, antenna panels to z = 16), x = -18 secondary sensor tower (top z = 8, sensors to z = 12.7), service truss (top z = 8.5), radiator fins at x = +/-6 (top z = 8).

Refinery: unarmed, shared spine, intake/output drums (radius 3, axis Y) at x = +/-16, central cracking tower (radius 3, centre z = 6.6, length 12.4, top z = 12.8, accent band, process sensors to z = 17.7), service tanks at x = +/-13, y = -12, heat radiators at x = +/-13 (top z = 10), drum-height pipe bridges.

Survives in deepseek.md Section 1 and qwen.md Sections 1.3-1.4 baseline descriptions. Backed by PACK.md R84, R91, R94, and station_kit.py:81-212.

Cause of the flat top-down read and need for top-face stepping and outline asymmetry: Survives in deepseek.md Section 1, qwen.md Section 1.1, and rey_blind.md points 1-4. Backed by PACK.md R94 (line 122) and Chair Observations 1 and 2.

Battle-camera resolution thresholds and #102 layout rules: Camera at ~170 units out (15.4 px/unit at 4K, labelled INFERRED); >= 2 units for shape, 1-2 units secondary read, < 1 unit texture only, < 0.5 units wasted geometry; < 4-unit gaps read as noise; berth openings clear 6 units; long spine first; working face (+Y) vs. service face (-Y); at least three silhouette breaks along the length. Survives in deepseek.md Section 2 and qwen.md Sections 1.2 and 1.5. Backed by PACK.md #102 synthesis.

Faction-neutral geometry and palette dressing rules: One kit serves all maps (FAC_MAP battle.js:59); faction identity restricted to panel bands, battery cowlings, dock lips, and lit accents over neutral structure; verified palettes for Glasswrights (hull #eef3f1, trim #d7c88a, glow #9fffd2) and Hullbreakers (hull #6a2c22, trim #b8402a, glow #e0402c), with remaining palettes pulled from #72 synthesis at synthesis time. Survives in deepseek.md Sections 2, 4.1, 4.2, 10, 11 and qwen.md Sections 1.5, 2.3, 2.4, 8, 9. Backed by PACK.md R84 (line 112), #102 synthesis, and #72 synthesis.

R96 Q1 and Q5 paint and part stack: Replace flat Principled BSDF materials (roughness 0.58, metallic 0.45, station_kit.py:26-37) with procedural materials driven by masks baked from station geometry (curvature, AO, edge wear) plus trim sheets and decals; no projected concept art; one-hull unlit PBR proof before any local AI texturing; hand-built parts by default, AI parts only via a reviewed per-faction library. Survives in deepseek.md Section 5 and qwen.md Sections 5.1 and 5.8. Backed by PACK.md R96 (line 124) and station_kit.py:26-37.

R98 breakable-by-design and R80/#102 station destruction rules: Real hull thickness, internal decks and bulkheads, two or three authored break lines with matching interior faces and damage textures (starting with Pyre-Barge #169, method research #171; game side #167); fleet station 4 integrity stages, batteries degrade before spine breaks, stage 4 break at radial-arm and spine junction, destruction hulk from same model; refinery stage 4 break at a tank or drum mount, hulk doubles as boneyard dressing. Survives in deepseek.md Section 6 (excluding the axial-cradle break line and truss exemption) and qwen.md Sections 6.1, 6.2(d), 6.4 (Break Lines 1 and 3), and 6.8. Backed by PACK.md R80, R98 (line 126), and #102 synthesis.

PR #151 validation suite and "Not checked" items: 25 standing checks, attachment and gun-clearance checks, GLB round trips, headless Godot imports, 4K captures at 46 and 30 units with real Battleship and Frigate models; board/issue-61/shots/r91/ review sheets unreadable; #102 triangle counts not run. Survives in deepseek.md Sections 9 and 11 and qwen.md Sections 7 and 9. Backed by PACK.md #102 synthesis and PR #151.

6. Cut List

Cut from deepseek.md:

The working-face mast at x = +7.5 (+Y side) that violates working-face vs. service-face separation (Sections 3.1, 9, 10).

All edits to locked R94 primitive heights/angles: raising the x = -18 tower from z = 8 to z = 10.5, changing x = +/-6 fleet radiators from z = 8 to z = 10 / 8.5, stepping x = +/-13 refinery tanks to z = 6 / 4.5, and dropping/angling the +x refinery radiator to z = 8.5 (Sections 3.1, 3.2, 9).

The refinery secondary column (x = +7, y = -4, z = 11) and refinery flare/vent stack (x = -5, y = -9, z = 14) that violate #102's single-tall-element rule and introduce oil-rig flare terminology (Sections 3.2, 4.2, 9, 10).

All sub-2-unit features claimed as primary silhouette shapes: the 1.5-unit-tall dorsal box at x = -12 (z = 3.5), the < 2-unit-thick gantry arch at x = +2 to +5 (which also collides with the spine at y = -6), the 1.5-unit diameter flare stack, the 1-unit diameter elevated pipe run, and the 1.5-unit tank step (Sections 3.1, 3.2).

All sub-0.5-unit geometry items unless explicitly restricted to normal/trim maps: 0.05-0.1-unit panel gaps, 0.2-unit radiator frames, 0.1-0.2-unit antenna lattice members, 0.2-unit guide rails and locking collars, and 0.3-0.5-unit window meshes (Sections 4.1, 4.2).

The false claim that the refinery shares the fleet station's axial cradle (Section 4.2).

Bespoke shuttle/loader props and "maintenance skiffs" added to the station kit (Sections 4.1, 4.2).

Oil-rig and maritime vocabulary: "flare/vent stack", "flare stack", "flare tip", "vertical ladder cages and platform rings", "valve wheels", "sampling probes", and "maintenance skiffs" (Sections 3.2, 4.2, 9, 10).

The fleet station break line at the axial-cradle/spine junction (replace with a radial-arm and spine junction per #102) and the unsourced R98 interior exemption for gantry/truss members (Sections 6, 9).

The additive 85k-triangle / 1.0 ms station budget allocation that pushes the 20-ship frame over the 306k / 3.9 ms R96 Q3 ceiling (Sections 7, 10).

The unverified reference list in Section 8 (especially the false claim that Tycho Station has a refinery column and tanks, and that Babylon 5 has a tall central spine).

The misattribution of #129 (ship repair geometry test) to the R96 Q1 mask-bake material pipeline (Section 11).

Cut from qwen.md:

All moves, resizes, and deletions of locked R94 primitives: moving the fleet service truss to x = +9, reshaping the x = 0 antenna array, shrinking the x = +16 output drum to radius 2.2, shifting/leaning the central cracking tower to x = +2, replacing the x = +13 tank pair with a radius 3.5 tank and "processing shed", dropping the x = +13 radiator to z = 7.5, and re-angling the pipe bridges (Sections 1.3, 1.4, 7).

The instruction to rewrite station_kit.py:202-208 audit assertions (Section 7).

The erroneous spine module centres (x = -18.4, -9.2, 0, +9.2, +18.4), the -z "plan view" antenna dimension, the overlapping silhouette break claim at x = +13 and x = +16, and the misplaced internal deck heights (z = 0.5 and z = 1.2 in a z = -2 to +2 module) (Sections 1.3, 1.5, 6.6).

The refinery secondary pipe column (z = 4 to 11) that violates #102's single-tall-element rule (Section 1.4b).

All sub-0.5-unit mesh geometry (0.15-unit panel grooves, 0.2-unit bolts, 0.3-unit collars/struts, 0.15-unit cables/conduits, 0.2-0.3-unit wall thicknesses) (Sections 2.1, 2.2, 6.5, 6.6).

Per-faction panel line depth differences ("Panel lines deeper" on Hullbreakers vs. "crisp" on Glasswrights) that violate faction-neutral geometry (Section 2.5).

Punting close-zoom traffic and life signs out of the station brief to "game-side" systems (Sections 2.1, 2.2).

All eight unverified reference entries in Section 3, specifically cutting the hallucinated "Rociofuerte" station, the false description of Tycho Station, the false "cube" / "flattened ring" descriptions of Elite Dangerous Coriolis/Orbis stations, the single "central pylon" claim for DS9, and the "pinwheel" claim for the Citadel.

The mismatched fleet triangle breakdown (13.5k-19k vs. 18k-22k), the invented 250k-270k 20-ship subtotal, and the 80 MB texture budget that combines fleet and refinery maps while claiming per-module baked masks take zero memory inside shared trim sheets (Sections 4.2, 4.3, 5.5).

The proposal to collapse the three export material slots (structure, armor, accent) into a single material slot (Section 5.7).

Fleet Break Line 1 across the spine (x = -4.6) and Break Line 3 at the cradle rail, plus Refinery Break Line 2 toppling the cracking tower (replace with #102's radial-arm/spine junction for fleet and tank/drum mounts for refinery) (Sections 6.3, 6.4, 7).

Oil-rig and naval vocabulary: "Tank farm", "processing shed", "shed", "port versus starboard", "oil staining", and "residual fluid surface" (Sections 1.3c, 1.4c, 1.5, 3.7, 3.8, 6.4, 7).

Cut from rey_blind.md:

All ring, disc, torus, and radial-symmetry station assumptions.

The four-station taxonomy (shipyard, refinery, fortress, habitat/trade hub).

All per-faction geometry and silhouette proposals (Hullbreaker captured hulls, Chorus organic bulbs/membranes, Glasswright glass prisms/lens towers, Eclipse off-centre core tower, Sunward Crusade gothic cathedral spires).

The 6-to-10 separate module segmentation scheme with break lines only at joints.

Unsourced budget percentages (15 to 20 percent of ship triangle total, < 40 draw calls) and unverified from-memory reference entries.

Oil-rig and naval/maritime terms: "flare or vent stack", "gun decks", and "tug".
