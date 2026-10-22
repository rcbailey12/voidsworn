# Ship pipeline audit: AI ship models (C19_51 and the 35 after it)

Audit of the ship-model pipeline in the Voidsworn repo, answering questions 0 to 6 in `docs/ship_pipeline/AUDIT_BRIEF.md`. Every claim was checked against the clone: scripts, kit code, game code, the concept painting, and the C19 renders. Guesses are tagged. Nothing in the repo was changed.

Overall verdict, one line per area:

- Q0: Bake is not enough. Move detail into one shared shader layer for hull and kit.
- Q1: The front half of the pipeline scales. The hand kit does not. Do not start ship 2 until the kit becomes templates plus a manifest.
- Q2: The C19 kit has 12 real faults: floating parts, wrong-face parts, leftover AI geometry, and one mismatched funnel pair. All fixable, all listed with coordinates.
- Q3: Front armour should be book-stack steps, not slope plates. The bridge top should be one tall rear masthead cluster plus a front light visor, not corner scatter.
- Q4: Automate the leftover check first (it is exact), then waviness, then debris. Mangled-part detection can rank, never decide.
- Q5: The kit gain of 0.5 is the solver pinned at its own floor. One joint solve, one gain, and delete the 0.3 self-light fudge.
- Q6: Memory breaks first, on the phone, well before 36 hulls land. The first-spawn race is fixed on the waited battle path and still open in four other places.

---

## Q0. Detail consistency: baked detail layer, or one shared in-game detail material?

**Pick: one shared in-game detail material. The v10 baked layer is not enough and never can be. Baking detail into parts stops being the plan.**

Evidence:

1. The baked layer exists on one side of the seam only. In `tools/blender/project_paint.py:93` the DETAIL block runs only when `base_img is None`, which is the hand-built parts case (lines 21-24). The hull has a base image, so the hull gets zero baked detail. Two detail languages by construction.
2. The baked layer is colour only. `project_paint.py:97-110` multiplies a Brick pattern (Scale 38, Mortar .45), a Noise pattern (Scale 900), and a Bevel edge factor (up to 1.6) into the albedo. No normal change, no roughness change. Painted seams do not catch light. Hull detail does: photographic paint plus a real tangent-space normal map (`tools/blender/pixal_to_game.py` writes `CODE_n.webp`).
3. The brick grid is one fixed rectangle pattern in object space, the same on a gun barrel as on a plate. It knows nothing about the concept's panel layout. The hull's panel lines come from the concept itself. The two will never read as one system up close.
4. Baked density varies per part, which is the owner's exact complaint. Kit parts use a smart-project atlas (angle 55, margin .006) baked at 4096, then the phone kit texture is cut down in `pixal_to_game.py`. Atlas share depends on part size, so sharpness depends on packing, not on the ship.
5. In game the two materials are built differently. Hull paint (`ships3d.js:904-908`, `aiPaintMatFor`) clones the AI hull material and keeps its HullFx plugin. The kit (`ships3d.js:777-779`, `aiKitMat`) is a bare `BABYLON.PBRMaterial`: albedo, emissive, flat metallic .08, flat roughness .68, no bump texture, no HullFx plugin at all.
6. The painted hull currently turns shader detail off on purpose. `gfx3d.js:18` makes `HULLFX_PLATE` false for AI hulls, `gfx3d.js:45` gates the grime block with `#ifndef HULLFX_PAINT`, and `gfx3d.js:87` gates the close-up plating block with `!defined(HULLFX_PAINT)`. Three regimes today: shader plating on unpainted hulls, none on painted hulls, none on kits.

A shared layer is buildable, and the vehicle exists. `HullFxPlugin` (`gfx3d.js:16-181`) already injects into the PBR fragment shader at albedo, normal, metallic-roughness, and final colour, and it works in ship-local coordinates (`gfx3d.js:27`). Its plating picks a dominant axis instead of true triplanar sampling (`gfx3d.js:95`). Hull and kit are both scaled by the same ship length in `applyAIHull`, so one pattern scale in ship units fits both. What will not work: a settings-only fix inside `aiKitMat` as written. It sets textures and scalars only. Detail needs the plugin path on both materials.

Cost, honestly. No phone timing for a new block exists in the clone, so no millisecond figure is offered. True triplanar (3 fetches per map per fragment) should not go on the phone path. The dominant-axis pattern costs one packed texture fetch plus derivative normal work, and the existing AI plating block already spends several hash calls per fragment and ships on concept hulls today. Guess: affordable at close zoom on the Pixel, wasteful at fleet zoom. Measure with the repo's own frame-time logger (p50/p90 per battle) with the block on and off before shipping. Desktop cost on the RTX 5080 is negligible.

What it does to the paint: the detail overlay multiplies on top of the concept's own picture. Shader seams will cross painted markings and will not line up with the photo's own seams. Cap strength at the levels the existing AI block uses (`gfx3d.js:115`: seam darkening 0.24 max, plate tone plus or minus 0.12), multiplicative only. The hull has a real bump map in game, so hull detail normal strength must be lower than kit strength, or the hull gets double relief. One system, two strength constants. And be clear about the limit: shader detail cannot remove the baked shadows and lump shading in the hull photo, and cannot fix wavy hull shape. The brief already calls the remaining close-up gap mostly shape. This fix closes the texture-density half of the complaint only.

Fix steps:

1. Add one HullFx detail block in `gfx3d.js`: dominant-axis packed detail sample (or procedural seams and grit reusing the existing hash functions), albedo multiplier capped near 1.0, derivative normal perturb, roughness break-up. Reuse the distance and footprint fades at `gfx3d.js:91-106` as they are.
2. In `aiPaintMatFor`, stop excluding painted hulls from detail. Set a detail flag and the lower hull strength.
3. In `aiKitMat`, attach `HullFxPlugin` with the same seed, style, and detail settings as the hull paint material, at the higher kit strength. Same settings object, not constants typed twice.
4. Gate it like `HULLFX_HI`: full on desktop, cheap version or off on phone if the frame logger says so.
5. Run `project_paint.py` with `DETAIL=0` once the shader block lands. Keep the older vertex-colour grime for `KEEP` regions only, since those have no projected photo. BLOB_SWEEP section 4b then reads: same shader detail on hull and parts, checked at the seam.

---

## Q1. Is this pipeline right for 35 more ships?

**Pick: no, not as it stands. The front half (views, Pixal mesh, paint projection) scales. The back half (hand kit) does not. Ship 1 was an invention run plus 8 kit revisions, not a template run. Start ship 2 the same way and the project becomes 35 bespoke builds, not a fleet.**

### The real step count

`README.md` lists 10 steps. The real count is 12 work blocks, covered for C19_51 by five job files (`c19_1_views.bat`, `c19_1b_views_front_back.bat`, `c19_2_mesh_fit_paint.bat`, `c19_3_lod.bat`, `c19_4_kit_to_game.bat`).

Automatic: multi-view prep, fitcam, hull paint projection, phone LOD, most of the to-game pack.

Owner gates: side view approval before anything else runs (hard gate, `README.md` step 1), kit verdict per version, final in-game verdict including the Pixel check only he can do.

Skilled hand work: the blob sweep decision (9-cell grid in `BLOB_SWEEP.md` section 1, each cell clean or rebuild with a part named), the kit itself, `KEEP` box picking and colour sampling for kit paint, and the per-ship Pixal view recipe (C19 ran tests A to D, then E1 and E2 in one job; E2 won; that search repeats per ship).

Owner touchpoints, counted honestly: floor of 3 for a repeat mechanical ship (side approval, kit v1 verdict, final verdict). Realistic for a Priority 1 ship: 4 to 6 (guess). Ship 1 actual: at least 7 distinct owner feedback rounds recorded in the brief, plus the side approval and the TRELLIS.2 rejection before the pipeline existed. Chorus and Ithar add a style approval per faction up front (`SHIP_QUEUE.md` says ask before inventing a hand-built style for them).

### Sessions per ship (estimates, tagged as such)

Kit versions on C19 ran v3, v4, v5, v6, v7, v8 draft (never run), v9, v10. Each revision is: edit script, run the kit job on the PC (kit, LOD, paint bake, 11 render angles, game pack twice, in-game shots on 2 maps), review, owner verdict. That loop is the repeat cost, and it had not shrunk to zero by v10. The detail mismatch complaint is still open in `SHIP_QUEUE.md`.

Estimated totals at current process: Priority 1 mechanical (8 ships left) at 2 to 4 sessions each, Priority 2 mechanical (14) at 1 to 2, Priority 3 craft (2) at half a session, Chorus and Ithar (11) at 2 to 3 if a method is found. Total about 69 sessions, range roughly 45 if everything goes well to 90 plus if kit loops run like C19. At one session a day that is 2 to 4 months of ship work alone. There is no ship 2 data point yet; smaller escorts being faster is an assumption, not a measurement.

### Steps most likely to fail or eat taste calls on ships 2 to 36

1. Back views. `README.md` step 1 says it plainly: back views often fail, drop them. C19 needed a second job just for front and back. The left side has the mirror trap too.
2. Side view length. One image cannot pin a ship's length; TRELLIS.2 died on exactly this. The side gate catches it, but catching it means rerolls.
3. Pixal view recipe. Sides only gave a soft deck on C19; sides plus concept won. That balance is per ship. Expect 2 mesh runs per ship plus a pick.
4. Which parts blurred. `BLOB_SWEEP.md` section 2 lists what the AI reliably mangles: all guns, rocket racks, bridge tiers, masts, funnels, tanks, drums, lamps, the bow, engine nozzles, armour stacks, sponsons. Read plainly: the default kit is most of the visible detail on the ship. Blobs are not the exception. They are the job.
5. Fitcam fit quality. Paint sharpness rests on the concept camera fit (good is IoU about 0.89 to 0.90). No job gate stops a bad fit.
6. Paint levelling. Separate gains and a fudge today (see Q5). It held on one red Corsair ship. It will drift on pale Ithar hulls and dark Deathless hulls.
7. Detail mismatch at fixed scales. The v10 detail bake uses fixed brick and noise scales in ship space. Wrong on a small frigate, wrong on a super-dreadnought. Root cause stays: clean parts on a lumpy hull. See Q0.
8. Leftovers. On C19 an old AI gun barrel survived next to each new one. Finding leftovers is a manual render hunt per ship. See Q4.

### Chorus and Ithar: 11 of the 35, not edge cases

Chorus (6 ships). The kit does not transfer, for three plain reasons. The kit vocabulary is hard-surface: `hs_lib.py` makes boxes, cylinders, bevelled frustums, lofts; `c19_kit.py` cuts with axis-aligned boxes and rebuilds with mounts, plates, paired guns. Chorus has no mounts, no pairs, no guns. On a mechanical ship the blurred part sits on the hull and can be cut off; on a Chorus ship the blurred part is the hull surface (a sac, a membrane, a vein field), and cutting a box out leaves a hole in an organic form. And the kit paint path bakes albedo only, so glowing veins and sacs have no emissive path at all.

Proposal (unproven, tagged): keep the Pixal hull whole. Add organic overlays that conform to the surface using the same BVH ray tools `c19_kit.py` already uses: tube veins laid along surface curves, sacs as scaled spheres sunk into the surface (an ellipsoid helper already exists in `c19_kit.py`, used for a casemate), plus an engine-side emissive material for the glow, the same trick already used for Ithar sails in `ships3d.js`. All free, all Blender. But nobody has built one. Plain statement: no proven approach exists yet for Chorus at the owner's quality bar. Pilot on B19, a Priority 2 frigate, and get the style approved before touching the capitals B22 or B16.

Ithar (5 ships). Thin sails are the problem. A multi-view mesh model needs volume; a sail membrane has almost none, so Pixal will thicken it, melt it, or drop it. Edge-on, the generated views barely see it, so paint projection has nothing to project. The 250k LOD collapse will shred what is left.

Here an approach does exist in the repo, just not in the pipeline doc. `NEXT.md` v55: erase the sails with Qwen-Image-Edit, mesh the hull core, put the sails in the engine. `ships3d.js` already has a v53 sail card test on one hull: `cropAISails` cuts the AI fan sails at the root and `aiSailMat` replaces them with thin double-sided glassy cards (alpha 0.34, no back-face culling). So: do not mesh sails at all. Kit the hull core and masts with the normal kit, trace each sail outline from the concept by hand, build it as an engine card. Remaining costs: one hand-traced outline per ship, plus the open Ithar yaw bugs on I16 and I8 already logged in `NEXT.md`. Pilot on I14 before the capitals.

### The hard-coded coordinates problem

`c19_kit.py` is 319 lines for one ship. Frame calibration in the header (1 unit = 931 px) belongs to C19's view set. Bow seam literals `XT -.490`, `XS -.245`. `BOXES`: 10 hand-measured cut regions. `GUNS`: 4 hand-placed base and tip points. The rocket rack at x .217 with tube pitch .0202 builds 80 plus objects from one loop; funnels at .0666 and .0827; mast at .035; the front slab staircase at 5 listed x positions. Total part objects across all loops: well over 100. The job files hard-code more: `c19_4` has two `KEEP` boxes with C19 coordinates, and `c19_2` hard-codes the concept filename, view folders, and fitcam search values.

Credit where due: the script is not pure literals. It already measures the hull with BVH rays: `face_y` grids, `deck0` and `prof` for the front slope profile, an outermost-hit search for the tank axis, `surf_down` and `surf_in` to snap parts onto the real surface. The measuring engine is reusable. The region bounds that tell it where to measure are not.

Recommendation (one pick): parametric template kit driven by hull landmarks, fed by a per-ship manifest, not a per-ship script.

- Extract the measurement helpers into one shared module. Landmarks per ship, found automatically: bow tip, stern, deck line, flank faces, superstructure block, tank and engine zones. The methods are already proven in `c19_kit.py`.
- Build a part template library, per faction where needed: turret, casemate, long gun, rack, funnel, bridge tier, tank, thruster, bow loft, slab stack. Each template takes position, scale, and facing from landmarks.
- Per ship, a human writes a short manifest (part type, rough zone, size class), not 319 lines of Python. The agent can draft the manifest from the blob sweep grid.
- Automatic mangled-region detection should feed this as a proposal list for cut boxes, not replace it. Detection of blur on a mesh is unsolved (see Q4), and a wrong auto-cut destroys good geometry.
- Rejected: fewer bigger parts (the owner's complaints are precisely about small parts, so cutting part count cuts the quality he asked for) and accepting the current cost (rejected by the session maths above).

Pilot the template system on one Priority 2 mechanical escort and time it. If a templated escort still takes more than 1 session, stop and rethink before any Priority 1 ship.

### Ranked fixes before ship 2

1. Build the template kit plus manifest. Pilot on one Priority 2 escort. This is the whole ballgame.
2. Split the queue into 4 tracks with different done rules: mechanical kit track (22 ships), Ithar sail-card track (5), Chorus organic track (6, method not yet invented), light track for Priority 3 craft (2, plus the B23 spore ship): views, mesh, paint, LOD, no kit. This stops the false "35 times full price" plan.
3. One parameterised job driver per ship. Today every `c19_*.bat` hard-codes `C19_51`, folder names, `KEEP` boxes, and the concept file. Replace with one CODE-driven chain that pauses only at the side gate and the mesh pick.
4. Pilot Chorus on B19 and Ithar on I14, cheap ships first, style approval from the owner, before their Priority 1 capitals.
5. Fix paint levelling once, as a system (see Q5), with gains recorded per ship in the queue file and a seam check at close zoom added to the gate.
6. Run the 20-ship stress test and settle hosting now (see Q6). Duplicate C19 plus existing hulls is enough. Decide the `.vsm` streaming and hosting plan before producing 400 plus MB of hulls in a format that may need repacking.
7. Default the mesh recipe to E2 (sides plus concept plus front) and drop the back view by default. Generate a back only when the stern or underside is actually bare.
8. Auto-build the 9-cell blob sweep sheet and add the thin-debris and leftover proposal pass (see Q4). The verdict stays human. The assembly should not be.

Fine as is, do not touch: Pixal3D at full detail plus meshoptimizer `.vsm` with no desktop decimation (it beat TRELLIS.2 and Hunyuan on the owner's own verdicts); concept paint projection with fitcam registration; the side approval gate; the 250k phone LOD step; the BVH snap-on measurement helpers; `BLOB_SWEEP.md` as the definition of done; the Corsair junky exception.

---

## Q2. The C19 kit against BLOB_SWEEP section 3 and the concept

All coordinates read from `tools/blender/hs/c19_kit.py` as written. Frame per the file header: bow at -x, z up, y lateral. Renders cited by name from `docs/ship_pipeline/c19_example/`; concept is `docs/ship_pipeline/concepts/C19_51.webp`.

**1. The window band floats off the bridge front face. Section 3 break (never floating, on a visible mount).**
The tier front face runs from x -.088 at z .056 to x -.068 at z .102 (tier defined by `x0, x1, zb, zt = -.088, .059, .056, .102`). At the band height z .092 the face sits at x -.0723. The band `winband` is centred at x -.082 with rotated half thickness about .0042 in x, so its inner surface reaches only x -.0778. Gap about .0055 at band centre, worse toward the top. No strut or bracket is coded between band and face. The 8 `light{k}` boxes sit in the band, not on the tier. Visible in `kit_v8_draft_bridge_plates.webp` and `kit_v9_front_armour_clay.webp`: the black light strip juts off the red face like a shelf, with a shadow gap under it.

**2. A lump of AI geometry survives at the bridge front centre. Section 2 leftover break.**
In both the v8 and v9 renders there is a ragged grey wrapped log lying on the plinth at front centre, below the window band, in front of the tier face. No kit part occupies that spot. Likely cause (inference; the visual fact is direct): the bridge cut box is `(-.100, .068, -.088, .088, .058, .140)`, so it stops at x -.100, and any AI face centred forward of -.100 survives. The concept's front drums lived exactly there. The AI original is still in place right next to the rebuilt bridge.

**3. Bridge drums are on the wrong face. Concept break.**
Concept, bridge crop: two rusty drums sit side by side on the FRONT face of the bridge, ends facing forward, next to a square window and a round porthole. A third netted drum lies on the right side face. Kit: `cyl(f'drum{s_}', (-.0075, s_ * .0625, .078), .0125, .053, axis='X')` puts one drum on each SIDE. Tier half width at z .078 is about .053, so the drums at y plus or minus .0625 sit fully outboard of the tier, over the plinth. The saddles do not sit on the tier shoulders as the comment claims: `surf_down` at those positions hits the plinth top at z .065, so each saddle is a .004 tall nub standing on the plinth. In `kit_v9_front_armour_clay.webp` the drums read as two grey ears sticking out of the bridge sides. Also missing from the kit front face entirely: the concept's square window and round porthole.

**4. The front long guns keep their AI base. Leftover risk written into the cut predicate.**
Guns are cut by `seg_d(c, a, b) < .022 and c.z > a.z + .010`. Both `GUNS` pairs have `a.z = .006`, so only AI faces with centre z above .016 and within .022 of the segment are removed. The front pair, base `(-.045, s*.100, .006)` to tip `(-.059, s*.145, .080)`, has no other cover: the bridge box caps at |y| .088 and the side block cuts are at z -.060 and below. So the AI gun's base, mount, and lower barrel survive by construction. The kit then places `gunball{i}` and `gun{i}` at a `surf_in` point with a blended direction, a different line from the original segment. A surviving stub next to a new barrel on a different line is exactly the broken-pair failure section 2 warns about. The aft pair gets backup from `cut_extra` (`.20 <= x <= .32, .105 <= |y| <= .175, .012 <= z <= .10`), but the strips at z below .012 or |y| below .105 stay uncovered there too.

**5. The mast brace connects nothing. Section 3 break.**
`barrel('brace', (-.032, 0, .123), (.98, 0, .30), .06, .0018)` runs from (-.032, 0, .123) to about (.025, 0, .141). At the start, `rooftank` at (-.020, 0, .117) with radius .010: the brace start sits .012 off the tank axis in x, floating about .002 off the tank surface. At the far end, the main mast is a vertical at x .035 with radius .0035: the brace tip at x .025 stops about .006 short of the mast surface. Both ends hang in air.

**6. Yard arms point the wrong way. Concept break.**
`box('yard', (.008, 0, .176), (.026, .003, .003))` and `box('yard2', (.040, 0, .214), (.016, .0025, .0025))` are long in x, fore and aft. A yard arm spans sideways, in y. In the concept bridge crop the mast carries clear horizontal cross bars spanning sideways, plus a ladder. The kit yards read as fore-aft rails. The rungs are also off: `rung{k}` boxes at (.038, 0, .115 + k*.022) sit beside the mast pole (x .035, radius .0035), half sunk in it, not on a ladder frame.

**7. Front whip and searchlight bases hang off the front edge of the roof. Section 3 break, partial.**
Roof front edge is at x -.069, top at z .106 (`roof` box centred ((x0+x1)/2 + .010, 0, zt + .002)). The front whip pair sits at x -.070 with `whipbase` radius .003 at the same x: most of the base disc is forward of the roof edge. Searchlights: `searchyoke{s_}` at (-.070, s_*.036, ZR + .002), spanning x -.073 to -.067, so only 2mm of it rests on the roof, and `searchlight{s_}` at x -.072, axis X, length .010, is mostly cantilevered past the edge. Visible in the v8 render: the front searchlights perch on the roof lip with the pale lenses hanging over.

**8. Bow bollards float about .003 over the deck edge. Section 3 break, small but systematic.**
Bollards are `cyl(f'bollard{x_}{s_}', (x_, s_*(w_ - .012), zdk + .004), .0035, .008)` for x in (-.400, -.345, -.290), with `zdk = -.082`, so every bollard bottom sits at z -.082. But -.082 is the deck CENTRE height in `bow_sec`. The deck top falls toward the edges: at the bollard offsets (y ratio about .84 to .90 of local half width) the section points put the surface at about -.0845 to -.085. Gap about .0025 to .003 at all three stations, because a centreline height was used for edge parts. `hatch2` and `hatch3` have the same fault at about .001.

**9. Funnels are a mismatched pair. Concept mismatch.**
One loop builds `fun1` radius .0064 at (.0666, .010) with top .163, and `fun2` radius .0118 at (.0827, -.012) with top .156: radius ratio 1.84x, centres offset .0161 in x and .022 in y, flat caps (cap disc plus bore). In the concept bridge crop and in `views_left.webp` the two stacks behind the mast are a matched pair: same diameter, same banding, domed caps, on one line. This is the owner's "inconsistent in size and scope" complaint, present in numbers. Corsair junkiness covers a lot, but a paired stack at near double width is past junky.

**10. Front slabs: uniform strips, too narrow, wrong surface. Concept mismatch (design fix in Q3).**
Slab x positions `xs_ = [-.242, -.208, -.175, -.143, -.112]` give each of the 4 slabs about .030 of x run. Widths `.128 - .006*k`: .128, .122, .116, .110, a 14 percent taper total. Thickness a flat .016 for all. Each slab is a wide shallow strip, roughly 3 to 1 width against slope run, and every slab gets the same furniture: `frontrim{k}` (lower edge strip only) and `frontplaque{k}`, a smooth raised rectangle. In the concept the slabs are near square, the bottom one clearly biggest, each higher one clearly smaller, engraved raised-rim panels on the bottom and third slabs only, the second plain dark, the top a stack of thin plates. In `kit_v9_front_armour_clay.webp` the kit slabs read as four identical smooth steps with identical tombstone plaques, centred with wide red margins and debris showing on both shoulders. The concept column fills almost the full width of the front face.

**11. Slope debris outside the cut strip is left in place, next to the rebuilt slabs.**
`cut_extra` cleans the slope only where `-.245 <= c.x <= -.11 and abs(c.y) < .072 and prof(c.x) - .015 <= c.z <= prof(c.x) + .06`. Anything at |y| above .072, or higher than prof + .06, stays. In the v9 clay render there are rows of small black blocky debris running diagonally down both red shoulders beside the slab column, and jagged black chunks at both bottom corners of the slope. No kit part sits at those spots. AI geometry left standing next to the rebuilt armour, which section 2 says to check for.

**12. Rocket rack stands on one off-centre column. Placement sense, moderate.**
The rack's only support is `cyl('column', (.202, 0, (zc0 + .097)/2), .021, .097 - zc0)`, base set from `surf_down(.202, 0, .07)`. The frame it holds, `rackframe` at (.217, 0, .102) size (.150, .07, .006), spans x .142 to .292, so the column meets it at about 40 percent of its length. The end cheeks `rackcheek1` at (.144, 0, .102) and `rackcheek2` at (.290, 0, .102) bottom out at z .082 and support nothing; no surf call is made for them. In `views_left.webp` the rack sits on two chunky ribbed pedestals. One central post with a long overhang aft reads wrong, even for Corsair.

What passes, for the record. Funnels (placement), stern pedestals, deck lamps, and the thruster set (`thrplate/thr/thrbell/thrglow` at x -.015, .017, .049) use `surf_down` or a BVH ray and sit on real surface. The bow chaser pair aims forward off the prow, which the rules allow, and its base and house stack cleanly. Side blocks embed .030 into the measured flank with `sidepanel` on the outer face. The casemate and long gun brackets embed into the flank. The bow loft overlaps the AI hull by .010 at the seam.

One library warning: `hs_lib.tank()` is broken. Both dome spheres are built into one bmesh and translated once, so one end gets a double dome. `c19_kit.py` never calls `tank()`, `tubes()`, `greebles()`, or `vents()`, so this ship is unaffected. It will bite the first kit that uses it, and any template library built on `hs_lib.py` (see Q1) must fix it first.

---

## Q3. Better designs: front armour and bridge top

### Front armour: book-stack steps, not slope plates

What the painting shows (front slope crop of `C19_51.webp`, the dark column descending the front face): a stack of book-like slabs. Each slab's broad top face carries most of the detail. The bottom slab is the biggest, its right side wall deep like the spine of a thick book, with fine horizontal layer lines on the side wall. The second slab up is plain, darker, smoother. The third carries a raised border rim with a recessed engraved panel inside it. The top is not a slab at all, it is a small stack of thin plates. The column fills nearly the full width of the front face, and slab sizes shrink hard as they climb.

The pick. Keep the centreline column and the existing `prof(x)` anchoring, x from -.242 to -.108. Replace the 4 slope-parallel plates with 5 level steps. Each step is a wedge: underside follows `prof`, top face tilts at about half the slope angle, so each step has a deep front face and a shallow back edge, like a stair tread.

Layout, bottom to top (x_front is the downhill front edge; lengths overlap the step below by .005):

| step | x_front | length | width | front face height |
|------|---------|--------|-------|-------------------|
| 1 | -.242 | .042 | .152 | .032 |
| 2 | -.205 | .038 | .140 | .028 |
| 3 | -.172 | .034 | .126 | .024 |
| 4 | -.143 | .030 | .108 | .020 |
| 5 | -.118 | .024 | .088 | .016 total, as a laminate stack |

Rules for the author:

- Width tapers .152 to .088, 42 percent, not 14. Step lengths step down with the widths, so each tread reads near square from above, as in the painting.
- Each step's front (downhill) face is near vertical. Each tread overlaps the step below by .005 in x and rests on it. No gaps, no floating strips.
- Add a skirt cheek on both sides of every step: a box at y plus or minus (w/2 - .004), thickness .008, whose bottom edge drops .008 below the step underside and follows `prof`. This hides the edge gap where a flat step bridges the faceted front face, the current design's weak point (it samples `prof` only at y -.05, 0, .05 and builds .128 wide parts).
- Delete `frontplaque` and `frontrim` as built. No smooth raised tombstones, no single lower rim strip.

Surface treatment, per step, matching the painting's alternation:

- Steps 1 and 3: a raised perimeter rim on the tread, border .010 wide, raised .0025. Inside it, a panel recessed .001 carrying engraved detail: 3 thin dark grooves across the panel plus a central block of 4 short grooves (thin inset boxes, .001 deep, DARK). Engraving is recessed and dark, never a raised smooth plaque.
- Steps 2 and 4: plain. No panel, no rim. One centre seam groove across the width, .001 deep, and nothing else. The plain steps are what make the detailed ones read.
- Step 5: three thin plates, each .004 thick, widths .088, .082, .076, each offset .002 in x from the one below, top plate rim only. This is the laminated cluster at the top of the painting's column.
- All steps: two thin dark grooves (.0015 deep, DARK) running the full width of the front face at one third and two thirds of its height, plus the same two lines continued on both side faces. That is the page-layer striation visible on the painting's slab side walls.
- Colour alternates by step, sampled dark like the painting: step 1 (.055, .055, .060), step 2 darker blue-black (.030, .032, .040), step 3 (.060, .060, .065), step 4 (.045, .045, .050), step 5 stack (.065, .065, .070). Bevel .0015 on tread edges (tighter than the current .0025, machined not cushioned), .003 on the downhill front corners for wear. Keep the v10 DETAIL projection pass on all of it (or the Q0 shader detail, once it lands).

### Bridge top: one crowded masthead cluster at the rear, visor at the front

What the painting shows (bridge crop, the black silhouette against the white background above the red roof): the density is vertical, not flat. A tall main mast with cross bars spanning sideways and a ladder, a second thinner mast with its own cross bar, an angled pipe dropping from the mast area down to a small box at the roof, and two tall banded stacks with domed caps standing close on the right of the masts. A rail runs along the roof edge. At the roof's front edge sits a small dark sloped plate carrying the orange light strip. The roof front half is otherwise bare red. The current kit roof reads plain because it does the opposite: low, small items scattered at the four corners of a big flat red plate.

The pick. One assembly, two parts. Delete the corner scatter. Build a rear masthead group on a base plate, and a front light visor. Everything mounts on one of those two, or on a mast.

Rear group:

- Base plate: box centred (.030, 0, ZR + .002), size (.100, .090, .004), STEEL dark. It sits on the roof rear half and gives the whole cluster one footprint. The front half of the roof stays clean red, as in the painting.
- Main mast: keep `mast` at (.035, 0) but lengthen it: base z .102, top z .260 (height .158). Two true cross yards spanning y: yard A at z .205, size (.004, .150, .004); yard B at z .238, size (.004, .110, .004). Small ball caps, radius .003, at all four yard tips. This also fixes the Q2 yard direction fault.
- Second mast: `mast2` at (.009, 0), top z .200, one cross bar at z .185 spanning y .090.
- Ladder on the main mast, facing the bow: two rails at (x .031, y plus or minus .006) from z .106 to z .200, rungs every .012 (8 rungs), each (.002, .012, .002). Delete the current loose `rung{k}` boxes.
- Crow's nest: keep at (.035, 0, .186), widen radius to .014, keep the rail and posts. It sits just under yard A.
- Angled pipe, replacing the floating `brace`: a barrel run from (.033, 0, .225) on the main mast down to (-.030, -.020, .108), radius .0028, ending on a junction box (.012, .012, .010) standing on the base plate at (-.030, -.020), with a small valve wheel (cylinder radius .006, thickness .002, axis Y) on the box. Both ends land on named parts.
- Stacks: bring the funnels into the cluster and make them the matched pair from the painting. Both radius .0095, both at x .064, y +.014 and -.014, bases from `surf_down` as now, tops at z .185, bands every .018, domed cap on each (hemisphere squashed to .5 height, the `rooftankcap` pattern). This deletes the slim/stout diagonal pair flagged in Q2 finding 9.
- Delete `radardish` and `radarhub`. The painting has no dish and it reads as a toy. In their place, one plain greeble box (.014, .010, .008) on the base plate at (.055, .028) and one stub antenna, height .020, at the top of mast2.
- The two roof vents stay, moved onto the base plate at (.016, plus or minus .030). Raise `roofhatch` to height .006 on the plate or delete it; at .003 tall and half sunk it is invisible either way.
- Whip antennas: keep only two, at the rear corners of the base plate, (.070, plus or minus .040), height .050, bases on the plate. Off the roof front corners entirely.

Front unit:

- Delete `winband` and the 8 floating `light{k}` boxes. In their place, a visor at the roof front edge, where it can actually attach: a dark plate (.030, .070, .002) tilted 30 degrees nose-down, centred at (-.066, 0, .104), held by two feet boxes (.004, .004, .006) at y plus or minus .028 running from the plate down to the roof front edge (roof front x -.069, top z .106). Six orange lights in a row on the visor face. This is the small sloped light plate the painting shows at the roof's front edge, and it bolts the lights to the roof instead of hovering them off the tier face.

Net effect: the roof stops being a flat red plate with needles at its corners. It gets one tall, dense, vertical cluster at the rear (masthead .158 above the roof, against a tier height of .046, so the silhouette triples), one solid lit visor at the front, and clean red between them, which is the painting's arrangement.

---

## Q4. Automating the blob sweep

**Pick: build the leftover check first (exact, cheap, can gate a job), then waviness (mostly written already), then debris. Mangled-part detection comes last and only ever ranks suspects. It never decides.**

First, what exists. No blob detector exists today. Grep for sweep, debris, wavy across `tools/blender/` finds nothing that scores a mesh. `contrib/README.md` asks for exactly this. Reusable pieces:

- `tools/blender/hs/planesnap.py`: the detection half of a waviness checker, already written. Numpy vertex and face arrays, area-weighted smoothed face normals, face adjacency from shared edges, region growing by BFS seeded on largest area, gated on normal angle (default 14 deg) and plane distance (default .006), plane refit by SVD, regions under a minimum area dropped. Only the snap half is extra for a checker.
- `tools/blender/hs/cleanup.py`: no detection (SMOOTH modifier, dissolve decimate, triangulate, weighted normals). Reuse only its smoothing as a reference surface.
- `tools/blender/fix_hull.py`: pure numpy on the exported game JSON. It has `comps(I, n)`, a union find over triangle indices, and a `keep_main` rule (biggest component plus any component whose centroid sits inside the biggest component's bounding box padded by 8%). Good logic, wrong place: it runs after int16 quantising. Run the same logic in Blender, before quantising.
- `tools/blender/hs/c19_kit.py`: the manual step to automate. It builds `BVHTree.FromBMesh` twice (uncut and cut hull) and measures with `ray_cast`: `face_y()` casts a 6 by 4 grid of inward rays, `deck0()` casts down, `prof()` takes the median of three `deck0()` calls, `surf_down()` and `surf_in()` find the surface under a part. It cuts by face centre inside the hard-coded `BOXES`, or within `seg_d < .022` of a gun segment, or the hand-written rules in `cut_extra()`. One of those rules is the stick debris rule, written by hand for one ship: slope skin plus "the stick debris above it" in the band `prof(c.x) - .015 <= c.z <= prof(c.x) + .06`. Every box is measured by hand, per ship. That is the cost to kill.
- `tools/blender/project_paint.py`: two patterns to copy. Per-vertex BVH ray visibility, and per-vertex scores stored as mesh attributes (`me.attributes.new(name, 'FLOAT', 'POINT')` with `foreach_set`). That is how a checker should store scores.
- `tools/blender/hullbake.py`: `BVHTree.FromPolygons` plus `find_nearest`, and `bpy.ops.mesh.separate(type='LOOSE')` for its `keep_main` op. That separate call is C code and is the fast way to get connected components. A Python BFS over 2M faces is not fast.
- `tools/blender/render_multi.py` already imports a second GLB via env `EXTRA` and gives it a vertex colour material. That is the marked-up render path, for free.

Scale note: every threshold below is a fraction of ship length L, taken from the bounding box after `transform_apply`, the way `planesnap.py` and `c19_kit.py` both start. Do not copy absolute numbers out of those two scripts; they were tuned on other meshes in other frames. All threshold numbers below are guesses. The only calibration set that exists is C19_51, where the owner verdicts are known: bow wavy, side blocks wavy, rack and side guns and bridge blobby, stick debris on the front slope, one old barrel left beside each new barrel. Tune on that ship first.

Proposed home: one new script, `tools/blender/hs/blob_check.py`, run like the rest (`blender -b -P blob_check.py -- hull.glb [kit.glb] out_prefix`), plus one double-click `.bat` in `tools/pc/jobs/`. It writes a text grid, an annotated GLB, and close-up PNGs (format at the end).

### Class 4 first: leftover AI geometry after a kit cut

`BLOB_SWEEP.md` section 2: when a part is rebuilt, check the AI original is fully gone. On the Pyre-Barge an old gun barrel survived next to each new one and broke the matched pairs. This is the most automatable class because a reference exists: two meshes go in, the cut hull and the kit.

- Test A, predicate recheck. `c19_kit.py` kills a face only if its centre falls inside a box, within `seg_d < .022` of a gun segment, or inside a `cut_extra()` rule. A face straddling a box edge has its centre outside and most of its area inside, and survives. Recheck with all three vertices plus the centre: any hull face with any vertex inside the original cut volume is a leftover suspect. Exact and free. It needs the kit script to export its cut volumes as a sidecar JSON (boxes, gun segments, `cut_extra()` parameters) instead of keeping them as local constants.
- Test B, proximity to kit. Take hull faces whose centres fall inside a kit part bounding box expanded by 0.01 L (guess). For those faces only, build a BVH of the kit and `find_nearest` per face centre. Distance under 0.002 L (guess) with a roughly parallel normal means two skins on top of each other. Group flagged faces by adjacency and score each group by area, face count, and height above the nearest large plate.
- Test C, the barrel case. The kit script knows its barrels: `GUNS` stores (base, tip) pairs and `hs_lib.py` `barrel()` builds along a direction. Export every barrel and tube axis as a segment in the sidecar. Run thin-group detection (Class 1) restricted to the kit neighbourhood and test each group with `seg_d` against the kit segments. A thin hull group within 0.022 L of a kit barrel axis, roughly parallel, and not part of the kit mesh is the old barrel. Same `seg_d` call the cut already makes; the checker asserts the count is zero after the cut.
- The hard part is real: intended contact looks like leftover. A snapped-on part touches the hull. Separate them by connectivity: intended contact connects through unflagged hull faces to a large plate extending well outside the part box. A leftover patch is closed inside the expanded part box, or not connected to any large plate. Compute, per flagged group, whether it connects to a region larger than about ten times the group area (guess). Mount or leftover. The BFS runs on the flagged subset plus its border, not the whole mesh. Cheap.
- Verdict: pass or fail per kit part. This one can be a hard gate. Put the check in the kit `.bat` after the kit script runs and before `pixal_to_game.py` (in `c19_4_kit_to_game.bat` terms, between the kit call and the `lod_make.py` call on the cut hull). A fail stops the job. Text form: "Part: side gun, port. FAIL. 38 hull faces within 0.002 L of the kit part. One isolated patch, 0.011 L wide, under the barrel. See render 4."

### Class 2 second: wavy or lumpy flat regions

This class is mostly solved already. Copy the detection half of `planesnap.py` and stop before the snap.

- Metrics, two per fitted plate. Planarity residual: for each face centre C in a region with fitted plane (n, d), residual is |n @ C - d|. Report RMS and 95th percentile, as fractions of L. Plus normal spread: mean and 95th percentile of the dihedral angle between adjacent faces. Residual catches amplitude; dihedral catches short-wavelength ripple a plane fit averages away.
- Method: smoothed normals, region grow from the largest face, SVD plane per region, both metrics per region. Keep regions over the minimum area; small regions are parts, not plates, and go to Class 3. `planesnap.py` already uses the residual as a grow gate (`abs(n0 @ C[g] - d0) > TOL * 1.5`); the checker just reports the distribution it currently throws away.
- Thresholds (guesses): flag wavy if RMS residual is over 0.0015 L or 95th percentile over 0.003 L. Calibrate against the C19 side blocks, which the owner called wavy, and against a hand-built `hs_lib.py` box, flat by construction. If those two do not separate cleanly, the metric is wrong, not the threshold.
- Verdict: per-plate list plus a heatmap render (residual stored as a FLOAT point attribute, colour ramp blue flat to red wavy), mapped into the 9-cell grid of `BLOB_SWEEP.md` section 1 by centroid. Output line: "Midship, side. Plate 7. Area 4.1% of hull. RMS wave 0.0031 L. FAIL, wavy." That line is also the work order: a wavy plate with a good plane fit is a `planesnap.py` snap job. A plate where region growing fragments into many small regions is not wavy, it is curved or mangled; send it to Class 3 or a hand rebuild. Do not snap it; snapping a fragmented region distorts edges.
- Cost: cheapest of the four on the verdict side (vectorised numpy; the Python BFS grow is the slow part). Run the verdict on the 250k LOD. One honesty limit: collapse decimate smooths ripple, and ripple narrower than the LOD edge length (roughly L/500 at 250k tris) reads flat on the LOD and still looks wavy in a close render. So for plates that matter, add a full-mesh check: a grid of `ray_cast` hits on the plate (the `face_y()` grid pattern) and the spread of hit positions along the plane normal. Hundreds of rays, cheap.

### Class 1 third: thin stick debris

Owner hit this at the bow. `BLOB_SWEEP.md` section 2: thin spiky or crossed sticks, AI wire debris. Two cases need two tests. Case A is a loose piece. Case B is a stick still welded to the hull. The C19 debris was case B, sitting on the slope skin. A loose-piece test alone would have missed it.

- Metrics per connected component: triangle count, surface area, volume, bounding box extents sorted e1 >= e2 >= e3, aspect e1/e2, thinness e3/L, centroid position against the main component box. For case B, per-vertex local thickness and protrusion height.
- Case A method: copy the object, `bpy.ops.mesh.separate(type='LOOSE')` as in `hullbake.py`, score each piece with numpy. Flag a component if it is not the largest, its triangle count is under 0.1% of the total (guess), and either its centroid falls outside the main box padded by 8% (the `fix_hull.py` `keep_main` rule) or e1/L < 0.05 (guess) with aspect over 4 (guess).
- Case B method, on the 250k LOD: build `BVHTree.FromBMesh`. For each sampled vertex, `ray_cast` along the negative normal; hit distance is local thickness t. Thin means t < 0.005 L (guess). Thin alone is not enough: masts, rails, and barrels are thin and real. Add protrusion: build a heavily smoothed copy (the `SMOOTH` modifier from `cleanup.py`, more iterations) and measure displacement d = |v - v_smoothed|. Sticks stand proud of the local surface, so d is large. Hull plate vertices can have small t across a plate edge but small d. Take faces where both tests fire, group them with the face adjacency graph `planesnap.py` already builds, score each group as in case A.
- Extra tests. Pairing: real thin parts come in matched pairs (section 3). Mirror a flagged group's vertices across the centreline and query with `BVHTree.find_nearest` or the `scipy.spatial.cKDTree` chamfer pattern in `hs/to_game.py` and `trellis_bake.py`. No mirror hit within 0.01 L (guess) means unpaired. Unpaired plus thin plus proud is a strong debris signal. Crossed sticks: `BVHTree.overlap` between two flagged groups gives volume overlap pairs; follow with a `find_nearest` distance pass. Overlap alone is not intersection proof.
- Verdict: never auto-delete. A numbered candidate list plus a close-up render per candidate. Text form: "Stick candidate 3. Bow, top. 142 tris. Length 0.038 L. Thickness 0.002 L. Stands 0.012 L above the slope plate. No mirror pair. Verdict needed: delete, or real part." Colour the faces red in the annotated GLB. Also export each candidate's bounding box in kit script coordinates: that box drops straight into a `BOXES` list in the next kit script. That is the real saving. The hand-written `cut_extra()` stick rule becomes generated.
- Cost warning: case A is cheap on the full 2M mesh (topology and bounding boxes, C-code separate step) and must run there, because collapse decimate can delete a stick or weld it to the hull on the LOD. Case B must run on the LOD: a per-vertex Python ray loop over about 1M vertices is the `project_paint.py` loop pattern, minutes to tens of minutes on the PC, and it will not fit the 8 GB sandbox.

### Class 3 last: blurred or mangled parts

Be blunt about the limit first. Geometry has no labels. Nothing in a mesh says a blob was meant to be seven tubes. This class cannot be a detector in the same sense as Classes 2 and 4. It can be a scorer inside a named region. Region names still come from a human looking at the concept.

Three scores per region, all computable:

1. Sharp edge fraction. For each edge shared by two faces, dihedral angle from the face normals; sharp means over 30 deg. That number is not invented: `cleanup.py` splits at `shade_auto_smooth` 32 deg, `planesnap.py` applies weighted normals after a 40 deg auto smooth, `hs_lib.py` bevels parts so edges catch light. Hand-built parts are full of sharp edges. AI blobs have almost none. Score is sharp edges divided by all edges in the region.
2. Normal variance at part scale. For each sampled vertex, neighbours within radius 0.01 L (guess) from `mathutils.kdtree.KDTree` (imported in `hullbake.py`) or `scipy.spatial.cKDTree` (as in `hs/to_game.py`). Compute 1 - |mean of unit normals|. A flat plate scores near 0. A crisp part scores high, with normals in several deliberate directions. A blob scores in the middle and, the key point, smoothly: also report how much the value varies inside the region. Blobs are uniform. Real parts are patchy.
3. Detail energy. Displacement between the mesh and a Laplacian smoothed copy (the `cleanup.py` SMOOTH modifier at higher iterations), averaged over the region, divided by region area. Crisp geometry moves a lot under smoothing. A blob is already smooth, so it barely moves. Low detail energy per unit area is the blob signature.

Plus a fourth where a pair exists: mirror asymmetry. Mirror the region across the centreline and take the median `find_nearest` distance to the other side (the `err()` pattern in `hullbake.py`). A mangled side gun usually differs from its pair. Corsair is exempt, per section 3.

Method: region first, score second. Regions come two ways. One, coarse boxes: not the measured cut boxes, one loose box per part type drawn once per ship, big enough to contain the part. Minutes of work, not hours. Two, automatic protrusion segmentation as a suggestion layer: vertices with low local thickness from Class 1 case B that sit outside the Class 2 plates form protrusion groups; a human names them. Then score every region. Calibrate all three scores against known good geometry: run the same code on the output of `c19_kit.py`, hand-built and owner approved in shape. If a score cannot separate the AI rack from the rebuilt rack on C19, drop that score. Do not ship it.

Also output what the kit author actually needs, which is measurement, not just a verdict. Per region: centroid, bounding box, principal axes from a covariance eigendecomposition (`np.linalg.eigh(np.cov(...))`, the maths in `fix_hull.py` and `bexport_frame` in `hullbake.py`), plus the surface point and outward normal under the centroid from `surf_down()` and `surf_in()` style ray casts. That is the seed data for a kit part: where it sits, how big, which way it points.

Threshold: rank, do not gate. Report the three scores and a combined rank across the ship's regions. Flag the worst third for rebuild (guess, and a weak one). Absolute cutoffs will not transfer between a battleship and a fighter, or between Hegemony and Chorus.

Verdict format: a ranked suspect list with close-up clay renders, one per region, camera aimed at the region centroid with distance set from region size (the `hs/render.py` camera maths). Text form: "Region: stern side gun, port. Sharp edges 2% (rebuilt reference 21%). Normal variance low and uniform. Mirror error 0.018 L. Rank 1 of 9. Likely rebuild." The owner or kit author still makes the call. That matches the pipeline as written: section 2 already rebuilds these parts by default. The automation's value is ordering the work, catching the one that would have been missed, and pre-measuring the cut.

Cost: dihedral and normals are vectorised numpy and run fine on the LOD. Neighbourhood queries must be sampled, not per vertex; copy the sampling patterns already in the repo (`hullbake.py` samples with `rng.choice(len(H), min(4000, len(H)))`; `hs/to_game.py` strides with `[::7]`).

### One verdict format for all four classes

The owner is not a coder and judges by screenshots. Numbers alone will not work. One `.bat` run writes three things:

1. A filled 9-cell grid matching `BLOB_SWEEP.md` section 1, ready to paste into the ship's row in `SHIP_QUEUE.md`. One line per cell with the worst finding and a verdict word: clean, check, or rebuild. Example: "Bow, top: rebuild. Stick candidate 2, wavy plate 3."
2. An annotated GLB: hull plus kit, with a FLOAT_COLOR attribute: red for stick candidates, orange for wavy plates, purple for blob suspects, yellow for leftovers. Rendered with `render_multi.py` at the standard angles. He already reads those sheets.
3. Close-up PNGs, one per flagged item, clay style from `hs/render.py`, camera aimed at the item, named with grid cell and class, for example `bow_top_stick2.png`. Under each, in the text file, one sentence in plain words and the numbers behind it.

Keep the raw scores in a JSON sidecar for the kit author. The owner never needs to open it.

### What cannot be automated honestly

1. Concept matching. Whether the ship looks like its painting is not a geometry question. The only existing tool that touches it is the fitcam pair (`fitcam_render.py`, `fitcam_fit.py`), and it scores one whole-ship silhouette IoU, about 0.89 for a good fit. It says nothing about whether this lump is the right lump. Per-part identity comes from eyes on renders next to the concept. The 9-cell review in section 1 stays human.
2. Naming a part. A scorer can say a region is smooth, symmetric or asymmetric, and featureless. It cannot say gun, tank, or funnel. Labels come from position plus the concept. Any tool that claims to find "the guns" on an unseen faction is guessing.
3. Debris versus real thin part. A stick, an antenna, a rail post, and a barrel are the same shape class. Pairing, position, and protrusion narrow the list. The final call is the owner's. Auto-deleting thin geometry will delete real parts.
4. Faction taste exceptions. Corsair may be junky and paint mismatch is on theme there (section 3). Chorus are living bio-ships and Ithar have sails (`SHIP_QUEUE.md`); for them the sweep is about clean organic forms. Every metric above assumes flat plates and sharp edges are good. Run them on a Chorus hull and they will flag the whole ship. Do not.
5. Whether waviness matters. RMS residual is a fact. Whether it reads at zoom 1.0 and 0.5 on a phone, the test in `BLOB_SWEEP.md` section 5, is a judgement. Same for the Q0 detail mismatch: a number can rank the lumps. It cannot decide if the look is acceptable.
6. Placement sense. Two parts of section 3 are measurable and should be checked, because `c19_kit.py` already enforces them by hand: snap gap (the `find_nearest` distance between a kit part and the hull; floating or sunk shows up as a number) and gun aim (cast `ray_cast` along the barrel axis and check it does not hit the hull, plus a dot product against the outward surface normal from `surf_in()`). Whether a hard point is a sensible place for a gun is not measurable. That stays a human call, and Q2 shows the current kit needs exactly that check.
7. Paint failures. The grey blob rack was a paint failure, not a shape failure. A geometry sweep will pass it. One paint check is honest and cheap and belongs in the same script: in the projected albedo from `project_paint.py`, measure chroma and variance inside each kit part region (numpy work like `paint_level.py`). Near zero chroma and near zero variance means unpainted grey. Flag it. Whether colours match the concept stays an eye call, per section 4.
8. Hidden leftovers that never show. Class 4 will find AI geometry buried inside the hull or under a part where no camera sees it. Finding it is automatic. Deciding it is worth another cut, versus a small triangle and draw cost, is not.
9. The thresholds themselves. Every guessed number above needs labelled examples. One ship, C19_51, is labelled today. Expect misfires on the next three or four ships, especially other factions. Budget for the owner to correct the checker, and keep the checker in report-only mode until it has been right on at least three ships in a row. Class 4 is the exception: its tests are geometric identities, not tuned thresholds, so it can gate a job sooner.

Build order: Class 4 first (exact, cheap, catches the failure the owner already paid for once). Class 2 second (`planesnap.py` with the snap removed and a report added). Class 1 third. Class 3 last, and call it a ranker, not a detector.

---

## Q5. The paint path: a principled fix for kit and hull brightness

**Pick: one joint solve, one gain, applied to both files, and delete the 0.3 emissive fudge. The current two-solve setup cannot match the two paints by construction, and the kit solve is not even solving: it is pinned at the solver's floor.**

The code. `tools/blender/paint_level.py`, function `level`, lines 6-14:

- Line 7: texel mask `m = a.sum(2) > 6/255`. The mean is over texels of that one file only.
- Line 8: `target = c[cm][:, :3].mean() / 255 * K`, the mean of the whole concept cut-out, alpha over 200, with K default .8.
- Line 9: `lin = a ** 2.2; lo, hi = .5, 8.` The gain search range is 0.5 to 8.
- Line 11: soft roll-off above 0.6 linear.
- Line 12: 40-step bisection on the mean sRGB value over mask `m`.

`tools/blender/pixal_to_game.py` calls it twice, independently, with the same default K: line 52 for the hull, line 89 for the kit. There is no separate kit constant and no separate hull constant anywhere in the code. The brief's two gains (kit 0.5, hull 2.35) are the two solved return values. Note: those numbers appear only in `AUDIT_BRIEF.md` (lines 74-75); no run log in the clone shows them. But 0.5 is exactly the `lo` bound at `paint_level.py:9`. A solved value of 0.5 means the bisection ran into the floor: even at minimum gain the kit file's mean was at or above target, so the solver could not darken it enough. The hull's 2.35 sits inside the range, so that solve at least finished. One solve worked, one clamped. That is the whole story of the mismatch.

The fudge: `ships3d.js:778`, `aiKitMat`: `const f=G.kitFill??.3; m.emissiveTexture=t; m.emissiveColor=new C3(f,f,f)`. The kit gets 0.3 of its own paint as unlit emissive. The hull paint material gets none (`aiHullMat` sets emissive black and `aiPaintMatFor` does not restore it). Emissive does not respond to sun angle, so kit brightness has a floor the hull lacks, and the match changes with view and light angle no matter what the files say. Texture level and light gain are already shared, by the way: both use `G.paintGain` (0.95 phone, 1.15 desktop) and `G.paintLight`. Roughness is not shared: kit .68 at line 779, hull paint .62 at line 906.

Why two different gains exist at all: the difference under the solvers is real. The two files are not the same kind of texture, despite the brief's "projected from the same pictures".

1. Different fallback paint. Hull, `project_paint.py:67-68`: fallback is the Pixal mesh's own base image, weighted `wb = 0.06` at line 84. `paint_level.py:1` says what that paint is: TRELLIS-family paint "comes out about 2.5x too dark". Every texel a camera saw weakly is dragged toward that dark base. Kit, `project_paint.py:69-74`: fallback is hand vertex colours multiplied by grime noise mapped to 0.62-1.18. Bright hand paint, not dark de-lit paint.
2. Different extra multipliers on the kit only. The DETAIL block (`project_paint.py:93-110`) multiplies kit paint by brick, grit, and an edge factor up to 1.6 before levelling. The hull has no equivalent step. (If Q0 lands and DETAIL turns off, this multiplier goes away, which changes the kit file's mean again.)
3. Unprojected regions on the kit only. `KEEP` boxes (`project_paint.py:40-45, 60`) zero the projection weights, so those texels stay raw vertex colour and still count in the levelling mean.
4. Different texel populations. `level` averages over each file's own mask. The hull atlas covers the whole ship, including backs, undersides, and badly seen areas full of dark fallback texels. The kit atlas is smart-project packed small parts, mostly well seen. The target is the concept's mean over a 3/4 view silhouette. Matching two different populations to one scalar mean does not make them match each other. A mean is one number; it says nothing about the red gun turret versus the hull plate next to it.
5. Different tonal curves after solving. At gain 2.35 much of the hull sits in the soft roll-off above 0.6 (`paint_level.py:11`). At gain 0.5 the kit never reaches it. Same mean, compressed highlights on one side, linear on the other.

What is accident, not necessity: `paint_level.py` was written for TRELLIS hull maps (header, line 1) and reused unchanged on a photographic kit texture. And `pixal_to_game.py` solves each file alone against the whole-concept mean, gated only on the `CONCEPT` environment variable existing (lines 51 and 89). In `tools/pc/jobs/c19_3_lod.bat` that variable is never set, so the hull got no levelling at all there; in `c19_4_kit_to_game.bat:8` it is set once and silently drives both solves. Fragile plumbing, not a design.

Fix steps:

1. Split `paint_level.level` into `solve_gain(paths, concept, K)` and `apply_gain(path, g)`. Same bisection, same roll-off, but the solver takes a list of files.
2. In `pixal_to_game.py`, solve once over the pooled painted texels of hull and kit together (both masks concatenated, one target, one K of 0.8, one concept reference). Apply that single g to both files. Delete the second solve at line 89 and replace it with the apply call. One reference, one gain, one tonal curve for both.
3. If the pooled solve still hits a bound, widen `lo` from .5 to .05 so a clamp becomes visible in the log instead of silent, and print both files' in and out means separately as a diagnostic. Do not then fix a remaining mean difference with a second per-file gain. A remaining difference after a joint gain is a content difference, and it gets fixed in paint or not at all.
4. In `ships3d.js:778`, remove the emissive term from `aiKitMat` (default `G.kitFill` to 0, delete `emissiveTexture` and `emissiveColor` for the painted kit). Set kit roughness to .62 to match `aiPaintMatFor`. After this, kit and hull obey the same light with the same albedo transform, at every angle, not just in the screenshot that was checked.
5. Re-run the level step after the Q0 change. Turning DETAIL off changes the kit file's mean, so any gain solved before that is stale.
6. Verify by measurement, not by eye: after a joint-level run, take the existing in-game close shots (`c19_4_kit_to_game.bat` already shoots belt and planet maps at zoom 1.0 and 0.5) and compare a named kit part against the hull plate touching it. Proposal, not a repo standard: if the part still reads off by eye on both maps, the next suspect is the hull fallback weight `wb = 0.06` and the dark Pixal base, not another gain.

One honest caveat: a joint gain makes the transform identical, which is the principled part. It does not guarantee the pooled mean is the right target for either file, since the target is still a whole-concept average. It guarantees the two paints can no longer drift apart by construction, which is what the owner is actually complaining about.

---

## Q6. In-game path and the size and performance plan

**Pick: memory breaks first, on the Pixel, and the loading design makes it worse. `loadAIHulls` fetches all 36 hulls at boot, decodes them serially, and never evicts decoded geometry. Do not add hull 6 until the stress test at the end of this section passes on a real Pixel 10 XL.**

Scope note: `.vsm` sizes below are from the brief and the task (desktop 8-14 MB, phone about 3.5 MB), not measured: no `.vsm` files are in this clone. Only `C19_51` is in `AI_VSM` today.

### How hulls and kits load, fail, and fall back

Intended design (`README.md` step 9): load `hulls_hi/CODE.vsm` on desktop or `hulls/CODE.vsm` on phone/medium, plus `CODE_kit.json` and the maps, after adding the code to `AI_VSM`.

Actual code, `loadAIHulls` in `ships3d.js`:

- `AI_HULLS` has 36 entries. `AI_VSM` has 1: `C19_51`. The other 35 still load as base64 JSON, not `.vsm`.
- Directory pick: `G.mobile` or quality medium gives `hulls/`, else `hulls_hi/`. Exception: `AI_HI_ON_PHONE` (11 capitals) forces `hulls_hi/` even when the base directory is `hulls/`.
- Fetch is parallel, decode is not. `loadAIHulls` runs `Promise.all` over all 36 `get(id)` calls at once, no concurrency cap, no priority for the fleet the player is about to fight. Each `get` for an `AI_VSM` id tries `fetch(dd+id+'.vsm')` first, awaits `MeshoptDecoder.ready`, reads the header in `decodeVSM` order, and if `h.kit` is set fetches `dd+id+'_kit.json'` as a second fetch. If the `.vsm` fetch fails, is not ok, or `MeshoptDecoder` is undefined, `get` falls through to `fetch(dd+id+'.json')`.
- Decodes are serialised on a shared queue in `loadAIHulls`. An idle yield uses `setTimeout 0` only if about 10 ms has passed and the page is not hidden. Results go into `AI_HULL_DATA[k]` via `decodeVSM` or `decodeAIHull`, plus `decodeKit` if a kit was fetched. Then `dropModel(k)` invalidates `MODEL_CACHE` for that class.
- Start: `startHullLoad` in `perf3d.js`, called from `main3d.js` before `titleScreen()`. The player sees the title and a small corner counter from `hullProgressUI` in `perf3d.js`: "Loading ship hulls X/36", bottom right, non-blocking.
- Battle gate: `whenHullsReady` in `perf3d.js` wraps only `battleScreen` and `ACT.c3skirmish`. If loading is still running it shows the `hullwait` modal with the count and a Start now button, and auto-proceeds after 12 s.

Failure behaviour, by layer:

- Fetch fail in `get`: if the hi JSON fails, `get` increments `HULLS_LOAD.fallback` and tries `hulls/<id>.json`. If that also fails it throws. The outer handler increments `failed`, pushes to `bad`, logs "AI hull not loaded". No retry, no player error. That hull is absent from `AI_HULL_DATA`.
- `.vsm` fail for `C19_51`: silently downgrades to the old JSON hull for `C19_51` (16k in `hulls/`, 38k in `hulls_hi/` in this clone), not to procedural. That JSON fallback only exists because the old file is still shipped.
- Decode fail: `decodeVSM` throws on bad magic `0x314d5356`. `decodeAIHull` and `decodeKit` can throw on bad base64. The decode try in `loadAIHulls` catches it, increments `failed`, logs "AI hull not decoded". Hull stays absent. Note: if `decodeKit` throws after the hull line has already assigned `AI_HULL_DATA[k]`, the hull survives without a kit but the counters say failed.
- Kit fetch fail inside `get`: caught separately, logs "hull kit not loaded", returns the hull with no kit. Silent missing parts.
- Kit apply fail in `applyAIHull`: try/catch logs "hull kit", ship continues with no `hull_kit` mesh.
- Build fallback: `buildShipModelFresh` always calls `buildShipModelProc` first, building the full procedural ship (`buildGothic` / `buildWedge` / `buildJunk` / `buildBio` / `buildSail` / `buildTomb`). Only if `aiHullsOn()` and `AI_HULL_DATA[k]` exists does it call `applyAIHull`, which disposes the procedural hull and emblem meshes and replaces them. If `applyAIHull` throws, it logs "AI hull swap failed" and the procedural ship stays. If the data is missing, nothing logs at build time. The ship is playable, just procedural. Same pattern in `craftInstance`: `craftFromMesh` first, procedural `buildCraft` if it returns null.
- Texture fail: `aiPaintTouch` and `aiTexTouch` have explicit fail handlers and log. `aiKitMat` is weaker: it creates `BABYLON.Texture(dir+code+'_kit_a.webp')` with no error callback. A missing kit paint has no coded fallback.
- `file:` protocol or no fetch: `loadAIHulls` sets state to skipped and resolves at once. All ships procedural by design.

`aiKitMat` and `G.kitFill`: `aiKitMat(fac, code, dir)` caches one material per kit. If code is set it loads `<code>_kit_a.webp` as both albedo and emissive texture, with emissive colour f = `G.kitFill ?? .3` on all channels. `G.kitFill` is not set anywhere else in the JS, so the 0.3 self-light always applies. No-code kits get no texture, metallic 0.55.

### The first-spawn race: verdict

Mitigated on the main battle path. Not fixed everywhere. The v52 finding does not reproduce for a patient campaign battle start, and does reproduce in four other cases.

Why the main path now holds: `main3d.js` starts `loadAIHulls` before the title. `whenHullsReady` blocks `battleScreen` and `c3skirmish` until `HULLS_LOAD.promise` settles. While blocked, no `buildShipModel` runs for that battle, so `buildShipModelFresh` sees the final `AI_HULL_DATA`.

Where it still races:

1. Skip and timeout in `whenHullsReady`. The Start now button and the 12 s auto-proceed both call `go()` while state is still loading. The battle then builds through `createView` > `buildShipModel` > `buildShipModelFresh`. Any class not yet in `AI_HULL_DATA` builds procedural and is cached in `MODEL_CACHE`.
2. Already-built ships never swap in battle. When a late decode finishes, `dropModel(k)` only deletes the `MODEL_CACHE` entry and queues the prototype for disposal at the next `disposeAllViews`. Live clones are not rebuilt. So one battle can hold procedural ships from the start and, if a reinforcement later triggers a fresh `buildShipModel` for a class whose cache was dropped, an AI version of the same class. Mixed skins, same class, same battle.
3. Ungated builders. `setupShowcase` in `campaign3d.js`, called from `titleScreen`, calls `setupBattle` directly, not the wrapped `battleScreen`. The fleet showcase, and the wreck and background-traffic builders in `scene3d.js` that call `buildShipModel` directly, also bypass `whenHullsReady`. Those ships build at title and traffic time, right after the fetch started, and will usually be procedural.
4. `setupBattle` called directly from `ui3d.js` is not wrapped. Only its two named wrappers are.

So: refuted for a waited campaign or skirmish start. Confirmed for skip, timeout, showcase, wrecks, traffic, and direct `setupBattle` calls.

### The size math

Given figures: desktop `.vsm` 8 to 14 MB, phone about 3.5 MB, desktop 1.5 to 2M triangles, phone 250k, 36 hulls. Maps are separate files, not inside the `.vsm` (`vsm_pack.mjs` packs only vertex and index streams). C19 jobs use TEXRES 4096 for `hulls_hi` and 2048 for `hulls`.

Total download, geometry only, if all 36 become `.vsm` and `loadAIHulls` keeps fetching all 36 at boot:

- Desktop: 288 MB low, 504 MB high, 396 MB mid.
- Phone, naive: 126 MB.
- Phone with the `AI_HI_ON_PHONE` directory logic applied to `.vsm`: 25 x 3.5 + 11 x 11 = about 209 MB mid. This extrapolates the current JSON directory logic to `.vsm`; the code path is the same, so treat it as likely, not measured.
- Plus maps per painted hull: albedo, normal, AO/metal, kit albedo. Current JSON set on disk for scale: `hulls/` 31 MB total, `hulls_hi/` 79 MB total for 36 hulls including JSON geometry and maps. Painted `.vsm` hulls add a large albedo on top.

Decoded geometry per hull. `decodeVSM` expands to position Float32 (12 B/vert), normal Float32 (12 B/vert), uv Float32 (8 B/vert), index Uint32 (4 B/index): 32 B/vert plus 12 B/triangle in JS arrays in `AI_HULL_DATA`. Babylon then makes its own GPU copies, and `applyAIHull` makes another scaled Float32 copy, splits it with `compactHalf` into fore and aft, and `makeWholeProto` clones it again. Assumption (guess): unique verts about 0.5 x triangles for a closed dense mesh.

- Desktop, 1.75M triangles mid, about 875k verts: index 21.0 MB, position 10.5 MB, normal 10.5 MB, uv 7.0 MB. JS total about 49 MB per hull. At 2M triangles and 1M verts: about 56 MB. If verts equal triangles, up to about 84 MB.
- Phone, 250k triangles, about 125k verts: about 7 MB per hull.

`AI_HULL_DATA` is never evicted. All 36 stay resident for the page life:

- Desktop JS geometry alone: 36 x 49 = about 1,764 MB mid.
- Phone JS geometry alone: 36 x 7 = about 252 MB before the hi-phone exception. With 11 hi hulls at desktop size: 25 x 7 + 11 x 49 = about 714 MB.

One battle, 20 ships, worst case all distinct classes, geometry only:

- Desktop: active prototypes hold a second copy of the JS data as Babylon buffers, so roughly 980 MB GPU-side plus the 1,764 MB retained set. Duplicates are cheap: `buildShipModel` clones the cached prototype and clones share geometry.
- Phone: about 140 MB GPU-side in the naive case, far higher if the distinct set includes the hi-phone capitals.

Texture memory, GPU decoded RGBA, mipmaps x1.33:

- Desktop per painted hull: albedo 4096 squared x 4 = 67.1 MB raw, 89 MB with mips. Normal 2048 (capped in `pixal_to_game.py`, `tex.res = min(res, 2048)`) = 22 MB with mips. AO/metal map the same, 22 MB. Total about 133 MB per hull, about 222 MB with a 4096 kit albedo.
- Phone per painted hull: albedo 2048 = 22 MB with mips, normal 22, AO/metal 22: about 66 MB, about 88 MB with kit.
- 20 distinct in one battle: desktop about 2.66 GB, phone about 1.32 GB. Mitigation in code: `aiTexTouch` and `aiPaintTouch` load lazily per class used, and `aiTexReleaseAll`, called from `disposeAllViews` in `fx3d.js`, disposes all battle maps at teardown. So the texture working set is per-battle distinct count, not 36. It is still per-battle distinct count, and 20 distinct breaks the Pixel budget on textures alone.
- Vertex load per frame, desktop: 20 x 1.75M = 35M triangles, rendered again for the shadow cascade and again for the SSAO geometry buffer on high and ultra (`dietGBuffer` in `perf3d.js` limits that pass to near-board meshes, which includes the ships). Phone: 20 x 250k = 5M triangles per frame before the shadow re-render.

The Pixel 10 XL is the constraint and it fails on memory first, not on disk. The retained decoded set plus one diverse battle's textures exceeds a mobile browser tab's practical memory well before 36 hulls land.

### What breaks first, ranked

1. Memory: retained decoded geometry in `AI_HULL_DATA` plus the per-battle texture working set. No eviction for geometry at all. Breaks first on the Pixel, likely as a tab kill or forced texture failures, around the high single digits of distinct painted capitals in one battle (guess; the exact count depends on the real unique-vertex ratio and shipped map sizes).
2. Download and first-load wait. 288 to 504 MB desktop, 126 to about 209 MB phone, fetched all at once at boot with no fleet priority. On a real phone connection the 12 s cap in `whenHullsReady` will fire routinely, which reopens the race above by design. Players will learn to tap Start now and get procedural fleets.
3. First-spawn CPU stalls. Per distinct class, first build pays `decodeVSM` (meshopt decode plus a per-vertex JS loop), then in `applyAIHull`: `compactHalf` over all verts, `HullQ` grid builds (56x56 bins per axis over all triangles, lazy per axis), and `seatOnHull` ray casts. That cost lands inside battle setup for every new class at once. 20 distinct classes means 20 of those in one setup, plus `battleWarm` work in `scene3d.js`.
4. Texture and material spread. One `aiPaintMatFor` material per hull code, up to 3 maps plus a kit map each, no shared atlas. More distinct hulls means more texture binds and shader recompiles when a new paint material first appears, not just more memory.
5. Draw calls. Not first. `makeWholeProto` merges hull meshes by material; an AI ship is roughly 2 hull halves plus 1 kit mesh plus 1 merged plume. 20 ships is roughly 80 to 120 hull-side draws, doubled by shadows. Manageable next to 35M triangles of vertex work. It becomes the problem only if kit parts stop being one merged kit mesh per ship.
6. Other: no distance LOD. The phone 250k mesh is used at all ranges, and a frigate pays the same as a capital. `AI_HI_ON_PHONE` negates the phone saving exactly on the biggest ships. And kit failure is decoupled from hull failure at every layer, so partial ships (hull with no guns or racks) ship silently.

### Test plan before scaling past a handful of AI hulls

Do not add hull 6 until these pass on a real Pixel 10 XL and on the desktop PC, in the built game, not the sandbox.

Stress fleets:

- Fleet A, worst case distinct: 20 slots filled with 20 different classes, at least 6 of them painted `.vsm` hulls including `C19_51`, at least 4 from `AI_HI_ON_PHONE`, both factions mixed so per-faction and per-hull materials all appear. Include a carrier with squadrons (the `craftInstance` path) and the station objective (the `objProto` path).
- Fleet B, duplicate control: same 20 slots, only 4 distinct classes repeated. This isolates distinct-class cost from ship-count cost. If B is fast and A is not, the problem is per-class memory and decode, not draw calls.
- Fleet C, cold start: clear site data and browser cache, load the game, tap into Fleet A as fast as the UI allows, do not wait on the title. Record whether the wait modal appears, whether skip or timeout fires, and which hull path telemetry reports.
- Fleet D, warm start: same as C after one full load and one battle teardown, then Fleet A again. Checks cache reuse and that teardown actually freed texture memory.

Measure per run, from existing telemetry and the profiler (`PERFCAP` in `perf3d.js`, `?prof=1`):

- `HULLS_LOAD` final state via `hullPath()`: loaded/total, failed list, fallback count, milliseconds. Plus hull wait telemetry: milliseconds and why (done, timeout, skip, error).
- Download: total MB transferred to first battle start, cold and warm, from the browser network log. Time from boot to load done.
- Frame times from the perf CSV: frame total p50, p90, p99 during setup, during a full-board broadside turn, and at close zoom on one capital. Active triangle count and draw calls from the same CSV.
- Memory: JS heap and GPU texture count before battle, at battle start, after 5 minutes, after teardown, from `sceneCensus` telemetry plus browser memory tooling. Count live textures and `AI_TEX` entries.
- Stalls: longest single frame and total setup milliseconds in battle start telemetry, plus a count of frames over 100 ms during setup. That is where the `decodeVSM` and `applyAIHull` spikes will show.
- Correctness: screenshot every ship in Fleet A at close zoom. Check kit present, paint present, no procedural ship in the waited path, no mixed skins for one class.

Pass and fail numbers (proposed; owner to confirm):

- Cold download to done: under 60 s on a throttled 10 Mbps connection, and total geometry download for the full 36 under 150 MB on phone. The current plan gives 126 to 209 MB, so this likely fails and forces lazy per-fleet loading. Fail means do not scale.
- Waited battle: why = done, zero procedural ships in Fleet A screenshots, zero mixed classes. Any timeout or skip on the throttled run is a fail for the loading design, not for the tester.
- Frame budget on Pixel, Fleet A, broadside turn: p90 at or under 33.3 ms, p99 at or under 50 ms, no setup frame over 250 ms, total setup under 3 s. The v52 baseline already had p90 44 to 60 ms on low-poly hulls, so expect this to fail first on geometry. That is the point of running it now.
- Memory on Pixel: no tab reload or WebGL context loss across Fleets A, D, A again. Texture count returns to within 10% of pre-battle after teardown. JS heap growth after teardown under 50 MB.
- Desktop: Fleet A p90 at or under 16.7 ms at native resolution with shadows and SSAO on, or the desktop `.vsm` triangle target comes down.

If Fleet A fails memory or p90, the fixes to test next, in order: load only the hulls the next battle needs instead of all 36 in `loadAIHulls`; evict `AI_HULL_DATA` for classes not in the current run; drop `AI_HI_ON_PHONE` for `.vsm` hulls; cap painted albedo at 2048 on desktop until the triangle count drops.

---

## Closing note: the three things to do first

1. Q1 fix 1 and 2: template kit plus manifest, piloted on one Priority 2 escort, and the queue split into 4 tracks. Everything else in this audit gets cheaper once the kit stops being a per-ship script.
2. Q5 plus Q0, in that order: the joint paint solve and fudge removal are small and make every future ship's paint check honest; the shared shader detail layer then closes the owner's latest complaint at the seam.
3. Q6's stress test before hull 6, and Q4's Class 4 leftover gate inside the kit job before ship 2's kit runs. Both are cheap. Both catch failures that have already happened once.
