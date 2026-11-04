# Issue 172: station detail pass brief. Chair synthesis

Verdict: GO WITH CONDITIONS. The conditions are the five owner questions in section 12; everything else in this brief is settled and buildable. The brief turns the R94 locked station shapes into a detail pass Codex can run. It rests on FINDINGS R79, R84, R91, R94, R96 and R98, the #102 structures synthesis, tools/blender/hs/station_kit.py as shipped, and PR #151. Chair screening of the four legs is summarised in section 9; the legs are filed beside this synthesis.

## 1. The governing doctrine: additions only

R94 locks the R91 shape pass (the towers, gantry, refinery column, drums and tanks as approved in PR #151) and in the same ruling directs the detail pass to add more height and asymmetry seen from above. Both writer legs tripped on the tension between those two halves: Qwen moved, resized and deleted locked elements; DeepSeek edited locked heights while claiming to freeze them. The chair resolves it as one rule for the whole pass:

- No locked primitive moves, resizes in plan, or is deleted. Positions, radii and footprints from station_kit.py stand.
- Height and asymmetry come from ADDITIONS: new elements placed on or beside the locked ones, cap stacks and housings on top of locked parts, cross-arms, extra fin blades, and stepped boxes sitting on the spine top face.
- Every addition that is meant to read as shape from the battle camera is at least 2 units proud of the surface it sits on (the #102 read rule). Anything smaller is secondary read or texture, and is labelled as such, never sold as silhouette.
- The standing audit asserts in station_kit.py (total length exactly 46; skyline hi z >= 15) are not rewritten. New asserts for new elements may be added. If an assert turns out to encode pre-detail geometry, it is flagged for Opus, not edited in this job.

## 2. The diagnosis (all legs converge)

The flat top-down read has a measurable cause, verified in the pack: every spine top face sits on one plane at z = 2 across 46 units, and every R91 tall element sits on the service side inside the footprint, so height exists in side view but the plan silhouette barely changes. The refinery is near mirror symmetric. The fix is therefore plan-view work: break the z = 2 plane with stepped masses of differing heights, and break the outline symmetry with additions placed off-centre, while the tall skyline stays where R91 put it.

Camera anchors (#102, carried): battle camera about 170 units out, 15.4 px per unit at 4K (INFERRED arithmetic). Features 2 units or larger read as shape; 1 to 2 units secondary read; below 1 unit texture only; below 0.5 units wasted geometry. Gaps under 4 units read as noise. Berth openings clear 6 units. Working face (+Y: cradle, berths, batteries, lit guides) vs service face (-Y: radiators, tanks, cable runs) separation stands, and no new tall element goes on the working face (see owner question 3; the chair position is that the docking side stays clean so berth and cradle reads survive).

## 3. Fleet station detail brief

Locked baseline (station_kit.py:96-134): 46-unit spine, axial battleship cradle on +Y (outer rail y = 13), two service-side frigate berths, four twin batteries at x = +/-11.5 with separate turret origins, control tower at x = 0 (top z about 11.4, antenna panels to about 16), secondary sensor tower at x = -18 (top about 8, sensors to about 12.7), service truss top z = 8.5, radiator fins at x = +/-6 (top about 8).

Additions and stepping (all new geometry, nothing above edited):

1. Stepped dorsal boxes on the spine top face at x = -12, -4, +4, +12, clear of the x = 0 tower and of each other by at least 4 units: top faces at z = 4.5, 5.0, 4.0 and 6.5 respectively, so every step stands at least 2 units proud of the z = 2 plane and the four heights are all different. These are equipment housings and sensor blocks, not plain slabs: each carries a top-face detail (dish, dome, hatch ring or antenna base) from the close-zoom language in section 5.
2. Gantry arch over the spine at x = +2 to +5: legs land ON the spine top face at its y edges (y about -2 and -6) and rise from z = 2, so no leg intersects the module volume; the crossbeam is at least 2 units deep where it crosses the spine outline, top about z = 9. It reads as a working frame over the spine, echoing the cradle's working language without touching the working face.
3. Cross-arm on the secondary sensor tower at x = -18, at about z = 9.5, extending in plan on the service side only. The tower's own top (z = 8, sensors to 12.7) is unchanged; the arm is what breaks its plan symmetry.
4. One additional radiator fin blade on the -x bank at x = -6, set at a slight angle to its neighbours; the +x bank gets a wider cowl housing instead. Existing fins are untouched; the asymmetry is in what was added.
5. A service-side docking arm extension at +x (the +14 arm in DeepSeek's leg): a plain arm with a lit dock lip, on the service face, clear of the berth openings.

Close zoom (section 5 language applies): cradle rails get guide strips and clamp housings at ship contact points; battery cowlings carry the faction trim; the tower carries lit window clusters and status lamps; berth lips are lit in faction glow.

## 4. Refinery detail brief

Locked baseline (station_kit.py:137-159): same spine, unarmed; intake and output drums radius 3 at x = +/-16; central cracking tower radius 3, top about z = 12.8, process sensors to about 17.7; service tanks at x = +/-13, y = -12; heat radiators at x = +/-13, top about z = 10; pipe bridges at drum height.

The #102 rule stands for this pass: one tall element only (the central tower, in the 12 to 16 band). No second element enters that band (owner question 2 asks whether Ryan wants to revisit this after screenshots; the chair pick is to hold).

Additions and stepping:

1. Drum cap stack on the -x drum: a stepped cap housing taking its top to about z = 9. The +x drum gets a wider, lower flange housing (top about z = 7) instead. Same drums, different caps: the process line reads intake-heavy.
2. Secondary process column at x = +7 on the service side, top about z = 11: below the tall band, so it is a mid-height element, and it is the refinery's main plan asymmetry. Pipework connects it to the tower and the +x drum at drum height.
3. Tank cap housings of different heights on the two service tanks (taller housing on -x, low housing on +x). The tanks themselves are untouched.
4. One additional radiator fin blade on the -x bank, mirroring the fleet move; +x bank unchanged.
5. An elevated pipe run from the central tower to the -x drum at about z = 8. At 1 unit diameter this is secondary read, labelled as such; it exists to give the top view a diagonal line, not as a silhouette claim.

Cut from the legs: the vent/flare stack (oil-rig vocabulary, 1.5-unit width below the shape threshold, and a second tall element against #102); stepped edits to the tanks and radiators themselves; any claim that the refinery shares the fleet station's axial cradle (only the spine and kit are shared; the cradle is fleet-only).

## 5. Close-zoom detail language (both stations)

One rule governs everything in this section: below 1 unit is texture, trim or normal work, never mesh; nothing below 0.5 units is modelled at all. Panel seams, bolt rings, coupler collars, guide strips, handhold lines and window strips are trim-sheet and normal-map content. Mesh detail at close zoom lives in the 1 to 2 unit band: clamp housings, hatch rings, dish and dome tops on the dorsal boxes, dock lip frames, sensor heads.

- Panels: large plate fields with seams at about 1.5-unit spacing in the trim, heavier plating on the spine and cradle, lighter on housings; wear concentrated at working faces (cradle rails, berth lips, drum caps) via the edge-wear mask, not painted on uniformly.
- Lights: lit window clusters on towers and housings (a life sign, kept sparse); status lamps on the refinery tower and tank housings; guide strips along the cradle and berths; all glow in the owning faction's colour.
- Radiators: fin faces get a heat-gradient trim treatment (dark root, faint emissive tip in faction glow at low intensity); the added blades carry the same treatment.
- Antenna arrays: the existing arrays stand; additions are limited to sensor heads and bases on the dorsal boxes. No lattice of sub-0.5 members.
- Docking arms: clamp housings, lit lips, guide strips. No vehicle props are modelled in the kit; traffic is a game-side system and is noted here only so the brief does not promise it.
- Vocabulary: the brief uses space-station terms only. Cut from the legs and not to be reintroduced: flare stack, tank farm, processing shed, skiff, port and starboard, oil staining, ladder cages, valve wheels. Substitutes in use above: process housing, tank group, work pod (game-side only), +x and -x, scorch staining.

## 6. Faction dressing

Geometry is faction-neutral and shared (R84, #102). The station takes the map faction's paint (FAC_MAP, battle.js:59): faction colour appears on panel bands, battery cowlings, dock lips and lit accents over neutral structure, and nowhere in silhouette. Panel depth, seam style and wear weight are identical for every faction; only colour and glow change. Verified palettes from the #72 faction look pack: Glasswrights hull #eef3f1, trim #d7c88a, glow #9fffd2; Hullbreakers hull #6a2c22, trim #b8402a, glow #e0402c. The other four factions use the same hull, trim and glow values as their shipped ship paint in the game's faction paint definitions; the build job reads them from there rather than from this brief, so no palette is restated (or invented) here.

## 7. Paint and material stack

Apply the R96 Q1 stack to stations in this pass (both writer legs converge; the chair adopts it):

- The three export material slots (structure, armor, accent; station_kit.py:26-37, :212) are KEPT. Each flat Principled colour is replaced by the procedural material driven by masks baked from the station's own geometry: curvature/pointiness, AO and edge wear, per the ship paint recipe, with the soot, rust and trim behaviour following the owning faction's palette.
- Masks are baked per spine module and per major element, plus one station-wide AO bake (Qwen's contribution, adopted). Baked masks are real additional texture maps and are counted in the texture step of the build job; they are not free.
- One shared 2048 trim sheet carries the section 5 detail language for both station kinds. No projected concept art anywhere in the chain.
- Local AI texturing stays gated on the same one-hull unlit PBR proof as ships (R96 Q1); stations do not get a parallel proof.

## 8. Breakable by design (R98, method from #171)

Stations follow the #171 method (delivered and ruled): real wall thickness, internal decks and bulkheads, authored break lines with capped interior faces and damage textures in the same baked-mask paint system.

- Fleet station, two authored lines: (1) the radial-arm and spine junction at the x = -11.5 battery arm (the #102 stage 4 anchor; batteries degrade before the spine breaks, per R80/#102); (2) the axial cradle and spine junction. Interior: two deck levels spaced across the spine module height (the module spans z = -2 to +2; decks straddle the mid-plane, exact z is a build parameter), bulkheads at the break planes.
- Refinery, two authored lines: (1) the -x drum mount; (2) the +x tank mount (the #102 stage 4 anchors are tank or drum mount). No break line topples the central tower in this pass.
- Wall thickness starting band 0.2 to 0.3 units (INFERRED build parameter from the Qwen leg; the #171 steps measure and adjust).
- Chair proposal, labelled as such (owner question 4): thin truss and gantry frame members get authored damage decals at break lines instead of interior faces. No such exemption exists in R98 as written; this brief proposes it because a hollow frame member has no interior to show, and asks the owner to confirm.
- Hulks come from the same models; the refinery hulk doubles as boneyard dressing (#102).

## 9. Budget

No triangle or frame count for the current stations exists in any source (#102 not checked, carried forward), and neither writer leg measured anything. The two leg proposals, both INFERRED and unmeasured:

- DeepSeek: fleet <= 40k tris, refinery <= 45k, stations <= 1.0 ms in a 20-ship frame. (Its framing of this as a share of the R96 ceiling is wrong: the 306k / 3.9 ms figure is the measured cost of 20 ships alone, so a station budget is additive headroom to be justified, not a carve-out.)
- Qwen: fleet 18k to 22k, refinery 14k to 18k, 0.25 to 0.35 ms. Its own component breakdown sums to 13.5k to 19k for the fleet station, so read its fleet bound as about 19k.

The chair position (owner question 1): design to the tighter bound (about 20k tris per station, about 0.35 ms) and treat the DeepSeek bound as a hard ceiling that needs a screenshot justification to approach. Either way, counting the current kit is step 1 of the build job, and the detail design is finalised against the measured count, not against either leg's guess. Cost in this brief is stated in triangles and milliseconds only.

## 10. Step list for the Codex detail job

1. Count first: run Blender triangle counts and a frame capture on the current station kit (both kinds) next to 20 ships; record the numbers in the job's delivery notes. No design numbers are final until this lands.
2. Add the kit parts for section 3 and 4 additions (dorsal boxes with detail tops, gantry arch, tower cross-arm, extra fin blades with cowls, service docking arm, drum cap stack and flange, secondary process column, tank cap housings, elevated pipe run) as new station_kit.py builders, additions only; locked builders untouched.
3. Flag any new part that the relay beacon or the intercept transports could reuse, in the delivery notes (owner question 5).
4. Build the trim sheet and the section 5 detail language into it; apply as texture/trim content only (no sub-1-unit mesh).
5. Apply the section 7 paint stack: per-module and per-element mask bakes, station-wide AO, three slots kept, faction palettes read from the game's paint definitions.
6. Breakable pass per section 8 and the #171 method: thickness, decks, bulkheads, the four authored break lines, capped interiors, damage mask variant.
7. Re-run the PR #151 validation suite (25 standing checks, attachment and gun-clearance checks, GLB round trips, headless Godot imports) plus new asserts for the added elements; flag, do not edit, any assert that encodes pre-detail geometry.
8. Capture the judgement set at 4K: plan view and battle angle at about 170 units, and close zoom at 46 and 30 units, both stations, with a docked battleship and frigate for scale. The pass is judged on these, per R94's loop.
9. Report measured triangle counts and frame cost against the section 9 bounds in the delivery notes.

## 11. Screening notes

- Blind Rey leg: written from the issue brief alone. Its station taxonomy (ring and disc forms, four station types, per-faction silhouettes) conflicts with R79, R84 and R94 and is screened out; its flat-read diagnosis and height-stepping principle converge with the pack and are used.
- DeepSeek leg: the strongest geometry draft. It flagged its own two rule tensions (the working-face mast; the refinery second tall element) and put them to the owner; the chair cuts the mast and holds the tall-element rule (questions 2 and 3 record the asks). Its budget framing, its refinery cradle claim, its sub-threshold silhouette claims (a 1.5-unit step, a 1.5-unit-wide stack) and its oil-rig vocabulary are cut or corrected above. Its additions, stepping plan and paint application are the spine of sections 3, 4 and 7.
- Qwen leg: useful on paint pipeline detail (per-module bakes, station-wide AO, trim resolution) and on breakable parameters. Its locked-geometry moves (drum radius, tower shift, tank replacement, truss move, antenna reshape, pipe rerouting) are all rejected under the additions-only doctrine; its single-material-slot proposal, per-faction panel depths, spine module coordinates, deck heights and texture arithmetic are corrected or cut above.
- Argon review: adopted in large part (see its filed header for the chair's itemised disposition, including the two places the chair narrowed it: the additions-only reading of R94, and sub-0.5 detail as reclassification rather than a cut of the detail language). Its reference fact checks stand: neither writer leg retrieved a single source, one cited station ("Rociofuerte") does not exist, and several station descriptions are wrong. Section 12 therefore carries design lessons only, no descriptions.
- Reference lessons (UNVERIFIED leg material, convergent across legs): odd counts and staggered heights beat symmetry; one dominant vertical with mid-height secondaries; silhouette work before surface detail; every visible system should look like it does a job; wear concentrates at working faces. No reference station is described or relied on beyond these lessons.

## 12. Owner questions (chair picks first)

1. Station budget bound. Design target: the tighter bound (about 20k tris per station, about 0.35 ms) with the DeepSeek bound (40k/45k, 1.0 ms) as a hard ceiling, counting first either way. The alternative is designing straight to the DeepSeek bound. Chair pick: the tighter target. Stations are set dressing next to 20 hero ships, greeble detail converts to trim and normals if the count runs tight, and a station that eats a quarter of the frame will read as a budget problem in every screenshot review.
2. A second tall element on the refinery (anything entering the 12 to 16 band beside the central tower). Chair pick: not in this pass. #102 set one tall element deliberately, this brief gets its asymmetry from mid-height additions, and R94's own loop judges on screenshots: if the detailed refinery still reads flat, a second tall element is a one-part follow-up with evidence behind it.
3. A tall element on the fleet station's working face (DeepSeek's sensor mast at x = +7.5). Chair pick: no. The working face carries the cradle, berths, batteries and lit guides; a mast there competes with the docking read, which is the fleet station's whole job. The fleet asymmetry in section 3 comes from the spine top and the service side.
4. The truss and gantry interior exemption (chair proposal in section 8): thin frame members get authored damage decals instead of interior faces at break lines. Chair pick: adopt, and let Opus confirm in the build job. A hollow frame has no interior to cap; the decal keeps the damage read without forcing fake bulkheads into a truss.
5. Shared-parts flagging: the build job flags new kit parts the relay beacon or intercept transports could reuse. Chair pick: yes. It costs one list in the delivery notes and saves a re-audit when those props get their own pass.

## 13. Not checked

- The PR #151 review sheets (board/issue-61/shots/r91/ fleet_review.jpg, refinery_review.jpg, stations_comparison.jpg) live on the owner's PC and were not readable from here; the brief works from station_kit.py, the #102 synthesis and the PR #151 validation summary instead.
- No Blender triangle counts or frame measurements were run for this research; all budget numbers are labelled INFERRED and the build job counts first (step 1).
- No reference source was retrieved by any leg; section 11's lessons are unverified leg material and no part of the brief depends on a specific reference station.
- The four non-look-pack faction palettes were not restated; section 6 defers them to the game's paint definitions at build time.
