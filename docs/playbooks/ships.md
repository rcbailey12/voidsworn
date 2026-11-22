# Playbook: ships

Issue 405. Written by the Board (Fable 5.2), Nov 11 2026. Format: docs/playbooks/PROGRAM.md. Use this to take one ship from
nothing to a hull in the game. The detailed stage notes are docs/ship_pipeline/RECIPE.md; this page is the order of work, the
gates, and who does what.

## 0. The settled method (binding on every ship build; Ryan, Nov 11 2026, R214)

A ruling that changes how ships are built is not landed until the same pull request edits this file or RECIPE.md (R214).
Each line below is a ruling Ryan made; the source is named so anyone can check it.

1. **Parts and hull.** Hand-built parts by default; AI-made parts only through a reviewed part library per faction (R96 Q5).
   The hull is traced in clean faceted sections from an AI shape reference made from the concept (recipe stages 2 and 3):
   the AI mesh is a tracing guide and a grime source, never shipped (RECIPE.md stage 2). A ship with an approved build sheet
   (item 5) is not traced again: the sheet is its hull, the recipe builds the sheet through one build contract and reads every
   fact from it (RECIPE.md "Ships built from a build sheet", issue 592); stage 2's reference still comes from the accepted
   concept, for the outline score and the grime.
2. **Paint.** Procedural materials driven by masks baked from the ship's own geometry (curvature, ambient occlusion, edge
   wear), plus trim sheets and decals; colours may be sampled from the concept; the concept picture is never projected onto
   the ship (R96 Q1). Local AI texturing only after a one-hull proof of unlit PBR output (R96 Q1). A ship built from a build
   sheet is painted by its faction kit's paint stack (issue 601): the ship json says `"bake": "stack"`, the stack is written
   once per faction (`tools/blender/kits/FACTION/stack.py`: colours sampled from the concept, the layers, the trim sheet, the
   decal rules) on the shared machinery (`tools/blender/kits/shared/paint_stack.py`: masks baked from the ship's own geometry,
   the bake), and the sheet's materials say where each colour zone sits. A faction with no stack yet stays unpainted
   (RECIPE.md "The paint stack for sheet ships"). Nobody paints a ship by hand.
   What the Hullbreaker stack must show (R228, Ryan, Nov 12 2026 14:21 CST, agreeing with the Board's review of A16 pass 1:
   "Yep completely agree with your findings"), set in the faction stack for every Hullbreaker sheet ship, never on one ship:
   (1) a plate patchwork at the concept's density, many small plates each with its own tone (brick-red rust and dried blood
   most, soot, gun-metal, bare-steel scrapes and purple trophy panels), driven by panel cells and the modelled plates' own islands (the stack's
   PATCH_FAMILIES, patch_cell); (2) contrast: black seams and dark recesses, brighter worn edges and scrapes, never flat grey
   at camera 170; (3) rust is a dark brick red, never pink, judged under the battle lift (1.25, R227); (4) red running lights
   visible as small red points at battle size; brightness, not size, carries the read (the Board's correction of its first
   call, Nov 12): small round lamps 0.0115 of the ship's length across (0.3 units on A16: about 1 px at camera 170, 3 px at
   camera 60), on hull and deck edges only, never on a machine (turret, gun, launcher, engine), deep red
   (#c41e14), emissive but under the game's glow threshold so no halo, about 16 in all: a row along each flank at the
   sheet's lamp height plus deck-edge points, built by the stack's RUNNING_LIGHTS rule and reported in the job's lights.json
   (point lights: the standing light check reports their size, the 2 px floor is for painted window and trim lights);
   (5) engine glow is the
   game's: the export marks each bell (hp_eng with its radius) and the game's engine effect draws the plume there, with the
   sheet's own emissive throat and bell lining, a hot red-orange deep in the bell and a dimmer red lining so the dark rim and
   lip read, never a flat peach cap; the paint never fakes a glow. And from the first PC run (Board and Ryan, Nov 12 16:32
   CST): every surface seen from outside carries the stack, an inside seen through an opening reads as the dark liner, never a
   room colour (stage 5's surface check, zero pixels allowed); plates come in large and small sizes, offset rows and a few
   overlaid patches, never a regular grid (RULEBOOK 0.5); no salt-and-pepper grain at close range (edge wear, grime and plate
   tone carry the look); big part faces carry the hull's plates and seams (R224 in paint). Pass 5 (Board, the two-ship
   PC run): painted metal has a roughness floor (no white specular glare at the game's key light; bells and dishes matte, the
   concept's metal is dull and grimy); light grey is for scrapes and small patches only, never whole big plates; the trophy
   grey is weathered dark; grime goes over everything; in the game the stack's surfaces take the soft rim light (look.gd RIM
   soft: the full rim specular flared white on them at the close cameras); the throat glow sits deep in the bell, the lip and rim stay dark, and (Ryan, Nov 12 19:16 CST: "more variation to the
   engine glow so it's not so uniform, just disc color") it varies: a hot core in the centre of the throat (the plug cone glows hottest, never black) grading out to deeper red and orange, uneven hot
   spots and soot streaks across the throat. R308 (Ryan, Nov 17): every engine on one ship shares its colour, strength, core
   reach and hot-spot pattern, scaled to its bell radius; bigger bells glow over a bigger area, never brighter. Every faction
   gets this through the shared stack, baked into
   the engine glow's own emission map by the stack (ENGINE_GLOW); the game's moving plume sits on top, so no flame is painted.
   Issue 651 (A18 to A20, the Board as designer): only a lit engine glows; a cold spare bell (an engine with no throat glow
    of its own, A20's on the deck) keeps its throat and plug dark. A parked craft takes its sheet zones and its nozzle joins
   the engine glow, and a sheet zone the stack has no colour for gets one in the faction stack, sampled from the beauty that
   shows it (the lilac trophy plate, from A20's); the list is in RECIPE.md "The paint stack for sheet ships".
   R240 (Ryan, Nov 13 2026 18:03 CST, on the reshaped A18 to A20: "The armor plates and patchwork is sometimes super even and
   ordered which doesn't make sense", and "some sort of weird paint pattern in the opening of the carrier"), in the
   Hullbreaker stack for every Hullbreaker ship: the patchwork never reads even or ordered: plate sizes wander along every
   axis, rows come in bands whose edges step every few columns, every column and strip shifts its own cells, a share of the
   plates is split once more at a random place, so no tile repeats and no seam runs on across a face (stack LAYERS
   patch_warp, patch_band, patch_split; shared paint_stack._grid; a stack without patch_warp keeps the even grid, so the
   Eclipse stay precise and ordered, R243). A hangar mouth reads as a dark, deep bay with a few warm
   deck lights and worn edging, nothing patterned inside it: no warning stripes (replaces issue 651's striped mouth), the
   fit-out inside in the dark liner's zone, only the rim and its torn teeth in worn iron (stack zone iron_edge), a few small
   warm lamps at uneven depths by the floor (glow zone lamp, amber, under the glow threshold).
   R306/R307 (Ryan, Nov 16, issue 936): rust red and dried blood are the main armour tones, like KB1CC run 2; grey salvage is
   a clear minority. The faction stack gives armour rust underpaint and 85 percent rust/blood patch-family weight; machinery,
   seams, soot and wear stay weathered. Per-ship colour registers, sampled and graded from the accepted A16 to A20 concepts,
   live in `CONCEPT_REGISTERS` in the stack: saturated brick rust, brighter worn metal and the concept's violet strength.
   Near-white is exposed metal and small scrapes; R274's larger grey trophy plates remain dark salvaged metal, at R252 size.
   Plate geometry and tiling scale are unchanged in this run; report the painted-output plate measure for review.
   **The Glasswright finish** (R337, Ryan Nov 18 and 19 2026: "glass like, so almost reflective", restart CD5 from the concept;
   issue 1183), set in `tools/blender/kits/ithar/` for every Glasswright sheet ship, never on one ship (R333): opaque,
   reflective champagne pearl ribbons (warm, never lilac grey: issue 1282), many and fine, each a bundle of strands with silver
   lines and a colour shift, over a core of emissive amber, violet and emerald stained-glass mosaic panels lit from behind (hot
   in the middle, dark at the lead edge); ribbons cover under half the hull; a slender spindle, about 4 to 1; stones are cut and
   glowing, and optics are small glints, never domes (round 5 outside read, Nov 19). Judge each round at camera 170 beside the
   concept first. Never see-through: every intact-hull surface has transmission 0 and the interior shows only in the break-up.
   No wear. The bake marks it authored_look so the game keeps its values (R329). The game's rim back light skips Glasswright
   hulls (`godot/render/look.gd` READ ithar rim_light 0, issue 1315): its specular flared white on the pearl lips.
   **The Eclipse paint** (issue 642, set in `tools/blender/kits/eclipse/stack.py` for every Eclipse sheet ship, never on one
   ship; factions.md Eclipse and Ryan's rulings): a black shade with a thin ring of violet-white fire at its edge; all violet, no green on the hull (Ryan, Nov 20 2026,
   issue 1419, replacing the green corona of Nov 10 and R237; the installed E11 to E14 keep the green until the stack is
   repainted and rebaked, contrib/opus/plans/eclipse_1419.md). (1) Dark
   violet-black plates judged under the game's Eclipse battle lift 2.2 (R227): the stack's colours are the tones to show at the
   lift, divided by it (read from look.gd), never lavender or grey; (2) separation by structure, not noise (Ryan, Nov 13 2026
   11:06 CST, on the first E11 picture: "Not a ton of details elsewhere, it looks like grainy paint almost. Everything kind of
   blends together"): clear value steps between big calm panels and plate families (near-black heat-shield plates most, deep
   violet, a lighter dusk violet, a few mauve and cool dark gunmetal plates, rare pale plates on small plates only), dark seams
   wide enough to read at camera 170, brighter worn edges on rims and plate lips, a different finish for the shade plates
   (matte), the body behind them (satin) and the machines (worked metal), no fine mottle or grain and almost no per-island tone;
   no rust or soot; a roughness floor of 0.50. R243 (Ryan, Nov 13): panels are dead even, ordered and aligned across the hull
   and crescent, with recessed seams and slight relief; the stack bakes that relief into the hull's detail normal. E11's
   accepted colour pairs stay unchanged. This order is the Eclipse's own, never the Hullbreakers' patchwork;
   (3) the corona is light, not paint (Ryan, same message: "that green looks so plain
   and stark, just like neon paint"; still binding in violet): the corona line on every shade rim is a faint ring of light, thin at rest,
   brighter arcs and dimmer stretches along it with a few short breaks, a soft falloff into the plate edge, cold violet-white at
   its hottest (white-gold on the brightest arcs) and deeper violet where dim, in faction_looks.json's Eclipse colours. R243: brighter through the same thin strip so it reads at camera 170, including
   E12's ring segments; brighter arcs may cross the game's glow threshold. The core glows violet-white, white-hot
   only at its very centre, reading at camera 170; never light pooled in hollows, ribs or sockets, and no green anywhere on the hull. Every light is drawn on one
   emission map; only the hull's rim trim material is marked hull_surface for breach clearance, never engines, core or lens.
   (4) engines are an eclipse ring of pale light round a
   black shade disc, in the game's Eclipse engine colour paled toward white, with shared brightness, tint, hot spots and
   dim gaps, no flame; (5) no added running lamps (the red lamps are a Hullbreaker rule; the Eclipse show only the corona, the
   core and the rings, and the sheet's corona strip lights; Board accepted, R236); (6) the stack's surfaces are rim_soft, parts
   carry the hull's plates and seams (R224 in paint), the liner is dark violet-black, and stage 5's surface check is 0 px;
   (7) even side to side (Ryan, Nov 15 2026 07:02 CST, R256, on E13: "let's make sure that the paint actually is even on each
   side, it's not consistent now"; issue 783): the paint mirrors across the centre line (stack LAYERS mirror: every pattern reads
   (x, |y|, z), a plate and its mirror twin share one random, shared paint_stack.mirror_islands; the starboard marks copy the port
   ones, the top mark on the centre line; the corona's arcs and breaks mirror), and the sheet and the kit build twins alike: a
   mirrored part reads its corners, rows and strips the same way on both sides, never from ring point 0 or one edge of a plate
   (E13's layer lines and panel rows, the kit's plate_slab fasteners and housing panels). Measured on a top view with the port
   half mirrored onto the starboard (tools/blender/build_sheets/studies/mirror_check.py), reported, not a bar (RULEBOOK 0.4).
   Each engine ring shares the ship's normalized pattern (R308).
   **New finishes keep their own look in the game** (R329, the Board, Nov 19 2026, on an outside review of the Glasswright and
   Chorus builds): a new no-wear paint stack sets AUTHORED_LOOK, the export writes the glTF extra authored_look, and look.gd
   keeps that material's albedo, emission, metallic and specular as painted (factor 1.0) instead of the old A4 calibration; the
   old A4 and the approved satin finishes stay byte-identical. Every finish sheet carries an accepted ship (C19_51) in the same
   light as a value reference.
   **The Chorus armour and paint** (R341, Ryan, Nov 19 2026 22:04 UTC: "the armor should be comprehensive and across the entire
   body, minus things like the spine, maw, 'engines', weapons, etc. it should be almost like an armadillo, pangolin, etc. not
   exactly the same, still alien, but think about it as a warship. we should have that textured feel and armored shell defense";
   issue 1234). Every Chorus sheet calls the shared kit's `plates.armour` (tools/blender/kits/chorus/plates.py, R333), never
   its own plates: thick keratin scutes in bands from belly to back on both flanks, each band lapping the one below and offset
   half a scute, every free lip standing proud aft over the next scute's root. Round 2 (the Board and Ryan, Nov 19: not round
   pebble plates; "close the gap around open skin"): each scute comes to a point or a squared chisel aft, is thickest at the lip
   with a dark shadow gap under it and carries one or two raised keels; the bands run from belly to spine, smaller scutes
   fill round each fitting, sacs and knolls get caps of smaller scutes (`plates.dome_caps`, the sac's bile window open at its
   crown) and a gland's knoll a ring round its slopes, its vent and spines open. Round 3 (Neon's review, Nov 19): fewer, bolder bands
   (5 or 6), a roof keel splitting each face into a lit and a shaded plane, the lip thickest; a scute that meets a fitting is
   shortened or cut back from that side, never replaced by a patch of small scutes; a seed per ship. The keep-outs are read from the sheet's own
   fittings (guns, maws, glands, sacs, siphons, vents, the spine row; `keep` names grown-in features such as a face or C13's
   knolls), so they stand in sockets of wet hide, siphons and vents in wider ones clear of their jets; what lies on the hull
   (C12's tendrils, `skip`) lies over it. No skin folds, pore fields or flank veins under the shell. The paint
   (tools/blender/kits/chorus/stack.py): warm brown hide between the plates, not dark olive; horn-brown scutes with coarse
   grooves along their length, pits, growth lines parallel to the lip, a dark root and a paler worn lip, all reading at camera 26; the trailing veils dark torn membrane with
   a faint warm glow, not flat lime; the bile light only in sac windows and deep in the vents. Round 3 (Neon): the hide deep wet
   maroon-umber well under the horn; pale weathered horn on the keel crests and lips (the shell's scute_ridge and
   scute_progress), charred at the roots, waxy crests and chalky grooves; a restrained yellow-green glow at each veil's root and
   along its ribs (kit material veilroot), the torn tips dark; the sac windows narrow bile slits under the caps. Ryan accepted
   round 3 on Nov 19 2026 23:38 UTC ("Accept, keep yellow-green glow"): the yellow-green glow stays. C13's bare stern and the
   skin between its knolls are fixed in the C13 rebuild (issue 1154).
   Judge the paint at 2048 maps or more (the PC bakes 4096) and at the camera 170 pixel size as well as close.
3. **The recipe.** Seven stages run in order from tools/recipe, one shared plumbing module with no look of its own, one kit
   per faction; the worked example is the Hullbreaker cruiser C15s_23 (issue 209 rounds 6 to 8; checks opus_check_336 and
   opus_check_341).
4. **Breakable by design, comprehensive insides (performance permitting, R215).** Real hull thickness, decks, bulkheads and machinery spaces, authored break
   lines with matching inner faces and damage textures (R98). Insides are built through the whole hull, not only in the break
   pieces (Ryan, Nov 11: "better to be comprehensive with internal if we can without performance issues", R215); they stay
   hidden until a piece breaks away; their cost is reported per build (R111) and the measured scene gate decides whether the full set ships (R215; issue 557's test hull: 25,008 more triangles, three more material draws, gate PASS). Rim bands at break
   lines and openings plus a dark inner liner (R99 Q1) stay as the layer the intact ship shows. How a ship breaks follows the
   current destruction approach, not R99 Q2's fixed line count (R215): blown apart, never sliced (R186: uneven pieces, no
   straight line across the hull, a missing bite where the core went, ragged scorched rims), break lines placed by the faction's
   rule (factions.md "How it breaks") and breach anchors by class and faction (HARDPOINTS.md, issue 363). Section 2b says
   what the build sheet must show.
5. **Build sheet first.** No ship is built from a beauty picture alone: it needs a build sheet that passes
   contrib/muse/design/concept_standard_2026_11/standard.md (R203), with the INSIDE section (R209).
6. **The concept guides; the builder designs.** Section 2a (R207, R213): identity from the picture, every other decision the
   designer's own, each listed on the sheet.
7. **Seats.** Every ship model made in Blender (blockouts, hulls, kits, the station) is an Opus worker's (R205).
8. **Costs.** Triangles, draw calls and surfaces per ship are reported, never capped; the only binding law is the measured
   scene gate on the RTX 5080 (R111, R121). Challengers earn adoption by Ryan's judgement on comparison sheets with costs
   reported (R121).
9. **Fidelity and fit.** Section 2c: parts read as what they are, the fit check with zero clashes (R217); a parts inventory
   before modelling, one detail level across the ship, kit first, the massing checked by ratios and structure counts, and
   the side-by-side judged by someone other than the builder before Ryan sees it (R218).
10. **The route is proven by a ship in the game.** RULEBOOK 0.9 (R225): a change to how ships are built is done only when
   one ship has gone from its build sheet to the game on Ryan's PC; the sheet writes each fact once (masses, seams, insides,
   mounts, length) and the recipe reads it; recipe checks read the ship's own entry, never a prior ship's shape (C15s's was the case that bit).

11. **Visible weapons are the game's weapons (R241, Ryan, Nov 13).** Every visible gun, turret, launcher and weapon organ
   belongs to a `data.js` weapon slot: its kind and mount fit that weapon (data.js carries no mount size, so size is judged by eye
   against the class, and checked only between mounts of one slot), its registered muzzle becomes that slot's
   `hp_w<slot>` at the visible weapon, and it faces the data arc. Turning pieces stay under their turret pivot. No extra or
   decorative weapons. Ryan allows multiple mounts for one slot when they are consistent with its firing and turning:
   matching kind, mount, barrel count and size, with their own muzzles and every mount firing on each volley under the
   game's rotating muzzle order. `tools/blender/build_sheets/weapon_match.py` checks the built ship against `data.js`,
   including its shot count. Every build mode and `contract.to_recipe` refuse a failure. The sheet carries the slot and
   mount table (`weapon_match.json`) and lists each design change. Run `weapon_match_selftest.py` to prove the check rejects
   broken inputs. Why: Ryan wants the visible weapons to line up with firing, effects and turns, including shared batteries. The SAME rule (one slot's mounts match in kind,
   mount, barrels and size within x1.3) and SPLIT rule (every mount fires on every volley) are the Board's reading of Ryan's
   "consistent and line up with the in game behavior" (Nov 15, ratified on PR 691), not his words: change them if he rules otherwise.
   Squadron craft (issue 769, R253): a fighter's guns (data.js `guns`, arc T) turn on a traverse ring like any turret; a bomber's
   bomb tubes (`bombs`, arc T) may sit fixed forward in a launcher, because a craft turns onto its target on a strafing run
   (weapon_match.py FITS rows `guns` and `bombs`, with self-test faults). The Chorus spore swarm (data.js `spore`, `sporeb` arc T,
   a bomber-role craft) shows its two acid sacs fixed on its flanks the same way (FITS row `sporeb`: type acid_sac on a launcher,
   with self-test faults; issue 793). This is the Board's reading for craft, not Ryan's
   words: change it if he rules otherwise. A craft sheet is LENGTH 1.6 (CLS_LEN Squadron, drawn 3.84, scale.md) and carries a
   small inside only because the build contract needs one: the game shows a craft's death as a spark (fx_death.gd _wing_death).
12. **Openings have depth; big flanks have shape (R244, Ryan, Nov 14 2026).** A round opening is a real recess with a lip,
   depth and working detail (a tube, launcher or thruster throat, lit or dark as its job says), never a flat painted disc.
   Cut the housing behind the opening too: a detailed tube embedded in a closed hull still reads as a disc. Big hull flanks
   carry angled facets, chamfers and stepped planes as their concept shows. Why: on A20 Ryan saw "just circles" at the bow
   and "flat walls" where the concept was angular. A20 is the first correction (issue 688); this binds every sheet ship.
13. **One shared ship job (issue 1174, Board, Nov 19 2026).** Every ship build run on the PC is a three-line wrapper around
   `tools/pc/jobs/ship_job.bat` (docs/ship_pipeline/ship_job/README.md): it stops after a failed stage, takes shots only of
   this run's own checked install, waits up to 3600 s for the GPU and ends "done PASS" or "done FAILED: <step>", then
   "all done". Why: on Nov 19 the C12 and C13 runners and S9's first run took pictures after a failed build, and 1155, 1157
   and 1158 failed a stage on the old 300 s GPU wait.
14. **One fix reaches every ship of its kind (R333, Ryan, Nov 19 2026).** A fix or look change lands in the faction kit, the
   paint stack, the shared parts or a shared helper, never in one ship's file alone, and its pull request names which other
   ships pick it up and how (rebuilt from the kit, rebaked from the stack, or already calling the shared option). A change
   that is truly one ship's says why in its pull request. Why: "let's make sure all the changes we're doing are cohesive and
   tied together. so like the fixes to the chorus skin should apply everywhere once we land it". First case: the Sunward spire
   treatment is one parts option, `radiator(..., glow='slats')` (factions.md, Sunward), used by S8 (issue 1158) and every
   later Sunward build. Second case: how bright the spire ember is lives only in the Sunward stack (`SPIRE` in
   tools/blender/kits/voidsworn/stack.py), never in a ship's sheet; a change there reaches S8, S9, S10, SF3 and SB4 on their
   next stage 5 rebake (Ryan, Nov 20 2026 13:43 UTC: "A bit brighter", applied to every Sunward ship, not one hull).
15. **A build is not "in" until build\godot holds it (issue 1311, Board, Nov 20 2026).** A ship job installs only into its
   own clone. After Ryan says yes to its pictures, the Board queues `tools/pc/jobs/publish_ship.bat JOB_DIR CODE COMMIT GLB_SHA`
   with the full commit from the job's receipt and the full glb sha256 from its export's CODE_export.json. It refuses a
   receipt that is not a passed ship_job run of exactly that commit (tail "all done", or "all done" then "pin ok COMMIT"),
   and an export whose files are not the listed hashes or not what the job checked. It keeps the old ship and its cache
   scenes in build\godot\_replaced\CODE_<stamp>\ with an UNDO_CODE.bat, installs through manifest_merge.py --install,
   rebuilds the ship cache, reads it back and takes the in-game shots from build\godot. The undo restores only that ship's
   files and manifest rows, under the install lock, and refuses if the ship changed since. Why: Ryan accepted Warden S9 and
   CD5 on Nov 19, but build\godot still held their Nov 1 hulls, and a capture job drew the old CD5.
16. **No ship reaches Ryan without a surface-detail PASS (issue 1517, Nov 21 2026).** Stage 5's detail check
   (tools/recipe/detail_check.py) gates every ship of every faction built through the recipe, hulls and strike craft alike, against
   its faction's floors (docs/ship_pipeline/detail_floors.md), and a FAIL fails the stage. A pick or publish picture of a
   build is made only with `tools/recipe/offer_sheet.py JOB_OUT OUT.jpg`, which refuses a job whose
   `out/recipe/log_detail.txt` has no PASS, takes as proof only the job's own pictures stamped with its commit and the
   sheet's stage (the in-game shots for "installed in game"; a concept goes in only as a labelled `--reference`; a shot
   from a dirty tree only when every dirty file is the install ship_job.bat recorded for that job: its own ship files, its
   manifest row, the watchdog hand-off, .import and .uid, issue 1539),
   and prints the three numbers on the sheet; `publish_ship.py receipt` refuses the
   same job. A ship under its floor passes only with a dated opt-out holding Ryan's own words in its recipe json
   (`"surface_detail": {"opt_out": {"date": "YYYY-MM-DD", "ryan": "..."}}`). Why: Navy O2 and O3 went to Ryan for a publish OK
   while the check only reported their flat skins (it failed Chorus ships alone), and he caught it himself: "Just make sure
   the level of detail is on both so they don't look like clay". The same happened with an earlier build of strike craft KF1 ("it
   looks unfinished"). Torpedo and rocket bodies (the munitions builder, PR 1416) have no stage 5 bake, so no atlas to
   measure: they are not covered until they get one.

### Named variant parts (issue 812)

A sheet can build a data.js variant without adding its weapons to the base hull. Its `VARIANTS` dictionary maps the exact
data.js id to a callback, for example `{'d_jackal_h': build_guard}` in `ships/deathless_E14.py`. The common entry point is
`tools/blender/build_sheets/variants.py`: it checks the variant's data.js base, sets `K.game_ship` and `K.variant`, calls the
base `build(K)`, calls that variant's callback, then finishes the deferred plates. A missing or wrong-family variant fails
before any build. Callbacks use the normal kit helpers, so the parts, turret nodes, fit records and hard points have one home.
For a replacement, the base builder reads `K.variant` to omit the replaced weapon before the callback adds its replacement;
never delete meshes after building and leave their muzzle or fit records behind.

Preview a variant with `build.py deathless_E14 OUT fit --variant=d_jackal_h` inside Blender. Every build mode runs weapon
matching against that selected id, and writes into `OUT/d_jackal_h/`, keeping the base sheet's output separate. `render` also
renders it. A variant recipe JSON names the same `sheet`, its own `game_ship`, and a `game_code` equal to that data.js id.
Use the normal seven recipe stages with that JSON: `sheet_hull` builds the selection, the contract writes its identity into
the blend, and stage 7 refuses a blend for a different ship or a variant aimed at a base hull folder. Class, faction and
hangar values inherit from the data.js base when absent on the variant. The existing paint stack paints the selected parts.

Install the separate variant folder with stage 7 as usual. ShipView selects the installed folder by the unit's `tpl` id from
the rules view, with no second variant table. If that folder is absent it keeps the faction/class hull. The variant inherits
the base hull's board clearance, so the Archive guard's upright E14 ring stays above the board.

Worked cases: `deathless_E14_guard.json` adds the Archive guard's stern null spire; `deathless_E13_sentinel.json` adds the
Mote sentinel's belly spire opposite its dorsal cannon (a roof spire blocked traverse); `deathless_E12_turreted.json` replaces
the fore cannon and fixed arc with the kit's existing corona arc on a turning foot on the fore saddle. Its aft cannon and
spire remain. `variant_parts.py` assembles that foot and projector from the Eclipse kit, without copying their shapes. All
three pass weapon matching, fit and sweep clearance, and their actual exported GLBs pass the export check. The E11 to E14
base builds have identical evaluated world-space triangles to their pre-change snapshots, including insides and shell
modifiers. These are geometry proofs with unbaked exports; full paint bakes and the normal installed scene gate still belong
to the ship build that ships those assets.

Reproduce the geometry and export proof with Blender:

```
blender -b -t 4 --python-exit-code 1 -P tools/blender/build_sheets/variant_selftest.py -- OUT --baseline=BEFORE.json
```

`BEFORE.json` is an optional pre-change snapshot from the self-test's `bases` triangle counts and SHA256 values (only
`triangles` and `sha256` per sheet). The self-test builds E11 to E14 and all three variants, tests wrong selections, exports
unbaked GLBs, and runs `check_export.py` on each. Set `VARIANT_EXPORTS=OUT`, then run Godot headless with
`--path godot --script res://render/test/variant_ship_check.gd` to run the real GLB cache builder and load the variants through
ShipView. Without the environment variable the same check uses small CI fixtures. `variant_review.py -- OUT SHOTS` inside
Blender makes one labelled 1280 by 720 comparison per variant from those exported GLBs, on the CPU. Keep scratch in TEMP and
review sheets in the job's shots folder. No test export is installed into the live game by these checks.

## 1. Target

- The faction's sheet in docs/playbooks/factions.md is the law for look: silhouette, shape language, colours, where guns
  sit, how it breaks, and its "Never" list. The rules for every faction at the top of that file apply to every hull.
- Ryan: "these are SPACE ships" (Oct 22). "It should vary by size of ship, faction, etc. We want things to be on theme"
  (Nov 10, hard points). "all the factions shapes and stuff came before we redesigned them" (Nov 10): the 36 concepts in
  docs/ship_pipeline/concepts/ are history, not targets.
- A ship is judged at the battle camera first (camera 170 on the look bench): one silhouette, one main colour, one accent.

## 2. Inputs (what must exist before a hull is started)

The fleet list (docs/ship_pipeline/FLEET.md, made from docs/ship_pipeline/fleet.json; issue 1421) names, for every ship the
game draws, the concept Ryan approved, its ruling, its job and whether the new build is installed. Read its row before
writing a concept or build brief, and copy its "Approved pick" line into the brief. A new pick is added to fleet.json in
the same pull request that records it.

1. Ryan's picked direction for the faction (docs/playbooks/factions.md, "The concept redo"; FINDINGS has each pick).
   Every concept or build brief names the folder of that faction's earlier accepted picks (for the Glasswrights,
   contrib/muse/design/glasswright_family_2026_11/, Ryan's Nov 16 picks; search contrib/muse/design/ for the faction first),
   so a new run cannot skip them (issue 1415: the 1146 clay redo ignored Ryan's Nov 16 Glasswright picks, Nov 20 2026).
2. A fleet brief for the faction: one written feature table per ship (class, length, beam, weapon slots from data.js, engines,
   break lines, the three or four features that make it that ship). The table outranks every picture.
3. A three-view concept sheet for the ship, to contrib/muse/design/concept_standard_2026_11/standard.md: side, top, front, one
   light, plain background. A generated sheet is an identity and proportion reference: it never settles counts.
4. The faction's parts kit and paint (tools/blender/kits/FACTION/kit.py and paint.py; for sheet ships, parts.py and the paint
   stack stack.py). A faction's first hull builds them.
5. A build sheet that passes standard.md (R203, Ryan: "good enough to actually hand build from in blender"): true side, top,
   underside and bow-on views of one design at one scale, rendered from one Blender blockout; the length from data.js; a
   scale bar; the feature table; an INSIDE section (below); and a "Changed from the picture" list (R207).

## 2a. The concept guides; the builder designs (R207)

Ryan, Nov 11 2026: "use the concept pictures to guide the build. Where there are gaps like eclipse rings not all having
structural connections or if guns look oddly proportioned or something similar that, you should build differently. Use it
to guide, not the very final exact design." And: "Opus should have final decision making as the designer. It should follow
all of the other guidance we've discussed across the faction guides, lore, playbooks." The accepted picture sets identity
(mass, silhouette from above, character, palette, where the big features sit). The Opus builder corrects what would not work
as a real built object and lists each change, with its reason, on the build sheet before the build. Questions go to Ryan only
when the picture, the faction guide and the lore conflict, or a change would alter the ship's identity.
Ryan, Nov 12 2026 (R233): "You're the final designer and director. Muse is just concepting." The Board makes the design
calls between concept and build, family distinctness included, and shows Ryan the result rather than asking first. First
case: the Eclipse flare (E14) carries one closed ring, so from above it never reads as a small zenith (E12, the split ring).
Ryan, Nov 13 2026 (R236): "The muse concepts are inspiration. You are the final designer and builder. All ships should fit the
design, lore bible and ship details from the game. We can revise or adjust the actual ships away from the concept, they're just
a base." So what a ship must fit is, in order: the game's own ship entry (data.js: class, size, weapons and their arcs, hangar,
speed), the faction guide and the lore bible, the playbooks; the concept is the starting base. Where they disagree, the game
data and the lore win and the build moves away from the picture, listed on the build sheet with its reason. A concept that
needs a data change (C12's forward gun, issue 649) is a data job first, never a silent build change.

## 2c. Parts that read and fit together (R217)

Ryan's words in this section are quoted. The mechanisms (gun slots from data.js, the blockout over the stage 2 reference,
heights against a side view, the parts inventory, the fit check, ratios and structure counts) are the Board's method under
R202, written to answer the failures he named in R213, R217 and R218.

Ryan, Nov 11 2026 21:24 CST, on build sheets round 2 (A16, A17): "The tubes at the front of a16 concept are just circles on the
actual build? also the guns are visibly blocking the rockets and appear to be in front of an engine at one point. we need to
do a check to see how the parts interact together, how they fit the actual ship and the total cohesive package together.
there also just appears to be a lot less fine detail and texture ... the engines look like big tubes, the weapons look so
simple and just tubes". On A17: "the front is also just a flat block which does not match the concept." So, from round 3 on:
- Every part is modelled as the thing it is, at the build sheet already: an engine is a bell with a throat, inner cone,
  cooling rings and a mount, not a cylinder; a gun is a base, a mantlet, a breech and a barrel with a muzzle, not a tube; a
  launch tube has depth, a lip and a dark bore, not a disc on the hull; a rocket rack shows its cells. Surface texture (seams,
  grit, wear, paint) comes in the build; part shape does not wait for it.
- The bow and every big mass follow the concept's own shaping (bevels, steps, overhangs, cut-ins); a flat block where the
  concept has shape is a fault.
- The fit check, run on every build sheet and every build: no part sits inside another; no gun's firing arc passes through
  another part or the hull; no part sits in an engine's exhaust cone; no launcher's exit is blocked; every part sits on the
  hull on a mount. The sheet carries a fit view (top and side with firing arcs and exhaust cones drawn) and a fit report
  listing each clash and how it was fixed. A clash left in is a blocking finding.
- The Board judges every sheet beside its concept at the same size before Ryan sees it (R198, R213), part by part.

Ryan, Nov 11 2026 21:34 CST (R218): "how else do we scale that to the other parts of the ship? Engines and guns are the
reference but we want to carry that through to the whole model. Don't just patch singular behavior or examples, use it for
global learning and shaping the approach". So the method, for every ship of every faction and the station:
- The parts inventory. Before modelling, list every feature the concept shows, region by region (bow, midship, stern; top,
  side, below): hull plates and armour steps, superstructure tiers, sensor and antenna gear, radiators, hatches and bays,
  thrusters, engines, guns, launchers, claws and grapples, pipes and tanks, lights, faction marks. Each line names the part
  type, how many, where, and its sub-parts (what makes it read as that thing: a radiator has fins and a frame, a hatch has a
  rim and a seam, an armour plate has a thickness step and a bevel, a tier has a face, a roof line and openings). Nothing on
  the concept is left as plain surface on the model unless the sheet says why.
- One detail level for the whole ship. Every part is modelled to the same level as its neighbours: if the guns have
  breeches and muzzles, the hull has plate steps and the tiers have openings. A region of plain blocks beside detailed parts
  is a fault (Ryan's "the level of texture and details seem to vary wildly", Oct 21).
- Kit first. Each faction's kit (tools/blender/kits/FACTION/) holds every part type at that level, built once and reused by
  every ship of the faction, so the next ship starts at the bar instead of rebuilding to it.
- The fit check covers every part, not only guns and engines: antennas, radiators, hatches, claws and lights get the same
  clash, arc, exhaust and mount tests.
- The comparison is region by region. The nine-cell blob sweep views (bow, midship, stern from top, side and below) are
  rendered beside the concept at the same view, and the inventory is ticked off per cell: present, shaped, detailed. That
  table is on every sheet and every build.
- Every round's feedback goes into this section as a general rule, never only into the one ship's notes.
- Every part has a job (R221). A part that does nothing on the ship (Ryan on the Hullbreaker chains: "let's get rid of the
  chains randomly around the ship. There's no purpose") is cut; the inventory names each part's job, and a part with none
  does not ship. Junky is still on-brand for Hullbreakers, but junk that is bolted on for a reason.
- Parts must not look like they conflict, not only not clash (R221: "There's a gun directly behind the rocket pods on a16
  which seems like it conflicts?"). The fit check adds each launcher's backblast cone and each rack's firing lane, and a
  gun whose barrel points at or sits in another weapon's lane or blast is a clash even when no mesh touches.
- No gun behind or aiming through a sensor (R240, Ryan, Nov 13 2026 18:03 CST: "I still see some guns right behind or facing
  satellite dishes and antennae"). The fit check's SENSOR test (clash.py check 3c) sweeps each gun's whole firing volume
  (every bearing of its data.js slot arc, every elevation it can reach, out to 60 percent of the ship's length) against the
  box of every dish, antenna and mast piece, padded by the gun's calibre; any hit fails the sheet, even where the barrel
  would fire just over the dish. The fix is the designer's: lift the gun on a barbette, lower or move the sensor, or both,
  listed on the sheet's fix table.
- Weapons carry the hull's detail density, measured (R224: Ryan on the Eclipse weapons, "They also just look smoother and
  less detailed, maybe slightly less poly than the rest of the ship"). The fit check reports, per part type, triangles
  per square unit of surface and edge features (seams, steps, bevels, greebles) per square unit against the hull's own; a
  part type more than 25 percent under the hull on either is flagged on the sheet and fixed in the build. This applies to
  every faction and every part type, not only weapons. The paint carries it too (issue 601): the paint stack puts its
  scuffs, rivet rows and wear on at ship scale, the same on a gun as on a hull plate, and stage 5 measures every part type's
  texels and paint detail per square unit against the hull's beside the mesh numbers (tools/recipe/density.py, the job's
  density.json; a part type under 0.75 of the hull is flagged).
- Weapons are designed per faction from the lore (R221: "their turrets look the same as hullbreakers. We should have those
  be more unique per factions and fit the actual weapons they use per lore Bible and faction rules"). Each faction kit's
  guns, turrets and launchers are built from what that faction's weapons are (data.js weapon ids, the lore bible, the
  faction sheet in factions.md): their mount, housing, barrel and muzzle say how the weapon works. No turret silhouette is
  shared between factions; the sheet shows each weapon type beside its lore line.
- Seams go round machines (R226, RULEBOOK 5.17): a gun, turret, casemate, launcher, engine, thruster, claw or sensor mast
  sits wholly in one piece, so the sheet moves or kinks each seam's plan path round them; plating, ribs, rails and openings
  such as a launch bay may tear across. The stage 4 audit tests each seam along its path and fails only a machine on it.
  A longitudinal seam (a peel) is one level plane in the game: the sheet sets its height clear of every machine under it, one
  per compartment, as many as the faction's breaking needs (issue 618: E11 peels its dorsal tiers and its crescent layers).
  The plane takes everything above it, so the insides need a clear band just above it (E11's deck kept 0.5 below its peel);
  a peel through decks, septa or rooms leaves their halves outside the torn hull (issue 623: C10's belly peel, 1512 triangles,
  was dropped). A transverse path runs on straight past both flanks (E11 to 6.2 off the axis, C10 to 7.5): the game weighs the
  tear's height by how far across the path a point is, so a path that stops at the flank tears the insides and the plating at
  different places there (C11: 171 triangles outside, 0 once the paths ran on). death_seam_check counts both.
- Detail scales with the part's size (issue 618, from R224 measured on E11): a kit part built large keeps the hull's detail
  density only if its plate courses, rings and bands are laid at the hull's own plate size in world units, never as a fixed
  count per part. The E11 projector at 7.6 long read 0.44 of the hull's triangles per square unit with the counts that served
  E12's 1.05 emitter; the Eclipse kit now lays its plates by size (tools/blender/kits/eclipse/parts.py, panels).
- Every face reads as stacked scrap where the faction's language is scrap brick (the Board on issue 633 round 1, Nov 13: the
  Hullbreaker class builds read as big smooth grey faces with a few small greebles; R196, R197): plates laid in courses at the
  hull's plate size in world units both ways, patches over joints and over plates, upward faces terraced in steps, never flat
  lids (the sheet kit's courses plating, tools/blender/build_sheets/kit.py, opt-in per ship).
- The outline from above is measured before dressing (the same review, R233): the plan's width at stations along the length,
  off the concept sheet's top view, so the class's defining shape (a wedge prow, a tapering nose, a bow block) is carried by
  the hull itself, never by a part bolted to the same box.
- Massing is checked as hard as parts (Board, Nov 12, from round 3: every part passed its tick while the hull still read as a
  lump). The sheet reports the concept's and the build's length to beam to height ratios, and the per-cell table adds a
  structure count: distinct masses, tiers and steps per cell, concept against build. A part list that passes over the wrong
  massing is not a pass.
- Build and judge from the whole concept and every sheet view first. A crop is only for close comparison after the whole
  view matches (R229, Ryan Nov 12: the A17 grabbers were lost to a bow crop).
- The builder never grades its own sheet alone: the Board (or another model) judges the side-by-side before Ryan sees it
  (RULEBOOK 2.2, R219).

## 2b. The insides (R98, R209)

Ryan, Nov 11 2026: "keeping in mind the hits, the breaks, the deaths and everything that affects the internals of the ship so
we don't run into the issues of before with just empty looking husks". What he was reacting to: broken pieces that were
"visibly empty" (R98) and wrecks that looked sliced (R186). So:
- The build sheet's INSIDE section gives deck levels, bulkhead and frame stations, the core and the engine room, magazines and
  machinery spaces, armour thickness by zone, and the break lines placed by the faction's rule (factions.md "How it breaks";
  the breach anchors of HARDPOINTS.md, issue 363).
- Every hull has real thickness and those insides, sized to read at the battle camera when a piece breaks away: decks, frames,
  machinery shapes, lit or burning spaces; never flat caps or a hollow shell. Chorus: flesh, bone and organs. Glasswrights:
  layered glass and light.
- Hits, wounds, breaks and deaths use the insides where they exist (RULEBOOK 6.14, R416; `contrib/opus/plans/cohesive_damage_v2.md`).
  To keep the whole chain from ship build through weapons, hit wounds, capability losses and destruction singular and cohesive:
  (1) when a faction's paint stack (`tools/blender/kits/<faction>/stack.py`) is next rebaked (#1422 Eclipse, #1681 Navy, #1684
  Hullbreakers, and Sunward's next update), raise `INSIDE_TINT` from 0.18 toward 0.55 so baked rooms retain faction material
  contrast through live breaches and wrecks while staying dark behind closed seams, and flip Eclipse `CORE_RGB` to violet
  (#1422, zero green inside); runtime Wounds V2 (#1741) lifts existing installed ships immediately without waiting on rebakes;
  (2) keep weapon hard points (`hp_w<slot>_*`), turning turret nodes (`turret_*`), engine nozzles (`hp_eng_*`) and bay doors
  (`door_*`) accurately tagged by slot and section, because live capability-loss damage reads those exact nodes when weapons,
  engines or shield generators go offline.

## 3. Steps

| Step | What | Where | Seat |
|---|---|---|---|
| A | Direction pictures, three per faction | Muse issue from the factions.md directions | Muse's image models |
| B | Ryan picks one direction per faction | one sheet per faction, the Board's pick stated | Ryan |
| C | Fleet brief: feature table per ship | docs/ship_pipeline/fleets/FACTION.md | Board or an Opus helper (high effort) |
| D | The build sheet per ship (R203, R209, R213): one Blender blockout designed from the accepted concept, true views, feature table, INSIDE section, changes from the picture | docs/ship_pipeline/build_sheets/SHIP/ | Opus worker builds, Board checks beside the concept, Ryan looks |
| E | Recipe stages 1 to 7 on the PC, one ship at a time | tools/recipe/1_concept_in.bat to 7_export.bat; ship file tools/recipe/ships/SHIP.json from _template.json, naming the build sheet ("sheet", hull module sheet_hull; worked example corsair_A16.json) | Opus worker (R205: every Blender model is Opus's) |
| F | Blob sweep: nine cells, bow, midship, stern from top, side and below, beside the concept views | docs/ship_pipeline/BLOB_SWEEP.md | Opus worker or Codex renders, Board looks, Ryan's eye decides |
| G | The ship in the game on the look bench, battle camera first | tools/pc/jobs/look_bench.bat | Codex |
| H | Ryan sees one image: the ship at the battle camera beside its concept | | Board |
| I | Only after Ryan's yes: publish the checked build into build\godot (section 0, rule 15) | tools/pc/jobs/publish_ship.bat JOB_DIR CODE COMMIT GLB_SHA | Board queues it |

The seven recipe stages, each a double-click file that stops with FAILED and a non-zero exit when it should:
1 concept in, 2 the AI shape reference (TRELLIS.2, a shape and grime source only, never shipped), 3 the traced hull and the
outline overlap, 4 the faction parts kit and its audit, 5 the paint bake, 6 the LOD chain and its cost, 7 the game export with
hard points.

## 4. The checks that prove it

- Stage 3: the outline overlap with the concept at the concept's own camera is reported, not a pass bar (RULEBOOK 5.8; was
  90 percent, R147). The stage prints the number and its picture; read them and say so in the report.
- Stage 4: the audit lists nothing: no part floats or is sunk, no machine crosses a break line (R226; structure may), no gun
  aims backward or into the ship. audit_selftest.py proves the audit can fail. Transverse seams are required, the longitudinal seam is optional.
  A sheet ship first passes sheet_contract_selftest.py (the sheet's data reached the recipe unchanged but for units).
- Stage 7: check_export.py passes: every weapon slot in the ship's data.js list has a hard point, every hard point is on the
  mesh (an engine point at the centre of an open bell passes by its bell: rim, throat and clear exhaust), every turret rests
  inside its own arc, and the breach anchors meet their contract. An install refreshes the game's ship cache and reads the
  ship back through ShipView, or the stage fails. The contract's count comes from the hull's class and faction
  (factions.md, "Breach anchors by class"; issue 363), never from a constant.
- Stage 5: the surface-detail check passes against the faction's floors (section 0, rule 16; issue 1517). A FAIL is a
  flat clay skin: fix it in the faction's paint stack (R333), never by lowering the floor.
- Stage 6 reports cost; costs are never capped (R111).
- The insides (R209): a break render of each authored break line at the battle camera and at camera 60 shows decks, frames
  and machinery, never a hollow or flat interior. A hull that shows one is not done.
- The blob sweep is a viewing instrument, not a pass bar (R121): the Board lists what it sees, Ryan decides.

## 5. Traps

- A model-space height is undone by ShipView's fit and centring. For board clearance use `HULL_LIFT` in
  `godot/render/hull_table.gd`, in drawn game units after fitting (E14, D20_23: R266, issue 811). Unlisted hulls keep zero
  lift. Keep the rules root on its hex; the hull, markers and visual centre carry the lift. Camera framing and fallback
  effects use that visual centre; authored hard points, weapons and shields follow the fitted mesh. Check at camera 170
  and at the lowest idle bob before changing the height.
- One three-quarter concept is not enough: rounds 7 and 8 could not fit the bow from it (R162). Three views, always.
- Generated sheets hold identity, palette and view angle, and never counts or aspect (Muse's C15s trial). Write the table first.
- Sea-ship parts creep back in every generated picture: porthole rows, lattice masts, cranes, keel fins, stepped decks. Check
  every sheet against the "Never" list before it reaches the recipe.
- The AI shape reference mangles guns, bridges, masts, tanks, bows and nozzles. They are rebuilt from the kit by default.
- Hand-built parts must carry the hull's level of surface detail, or the ship looks assembled from two games.
- A model's own visual check is a hint, never proof (an AI inspector once passed a prop clipping through a sill); the scripted
  stage 4 audit is the check. Generators drop thin wires, text and fine greebles: build those in code (from the archived
  harness brief, docs/archive/briefs/blender_build_harness.md).
- Heavy work runs on the PC; GPU work is sized to the job (RULEBOOK 3.4, R293). Deleting on the PC follows RULEBOOK 3.3:
  jobs and the cleanup janitor may remove their own rebuildable leftovers under its safe rules; nothing else without Ryan.
- A hull whose weapon list changes in data.js needs stage 7 again, or check_export.py fails on a missing hard point.

## 6. Worked example

The Hullbreaker cruiser C15s_23, ship rounds 7 and 8, pull request 401: tools/recipe/, tools/recipe/ships/C15s_23.json,
101,892 triangles, 28 hard points (18 gun muzzles from its four weapon slots, 3 engines, 6 breach anchors, 1 core). Its
concept is one of the old ones: the redo replaces the concept, not the recipe.

## 7. Job template (one ship through the recipe)

```
Owner: opus (an Opus worker builds every ship in Blender, R205)
Brief: docs/playbooks/ships.md (section 0 binds); docs/ship_pipeline/RECIPE.md; docs/playbooks/factions.md (the FACTION sheet); the ship's build sheet docs/ship_pipeline/build_sheets/SHIP/
Deliver to: tools/recipe/ships/SHIP.json, tools/blender/kits/FACTION/ (only what this hull adds), docs/shots/ships/SHIP/ (blob sweep, bench sheet), docs/ship_pipeline/build_sheets/SHIP/manifest.json
Branch: opus/issue-<number>
Effort: one Opus worker; GPU jobs through the PC queue
Done when: stages 1 to 7 end without FAILED; the outline overlap is reported, the audit and check_export.py pass and their output is pasted in the report; the manifest matches the build sheet (run_all_checks); a break render of every break line shows decks and frames, never a hollow; the nine-cell blob sweep and one battle camera bench image are committed. What Ryan will see: the ship at the battle camera beside its concept.
Approved pick: <the line from `node contrib/opus/tools/fleet_list.js --pick "FACTION|Class"`: the concept Ryan approved, with its ruling>
Build sheet: docs/ship_pipeline/build_sheets/SHIP/ (passed standard.md on <date>; Ryan's look on <date>)
Route per part: kit, hand-built, or generated (generated names its reviewed part-library entry, R96 Q5)
Inside: the sheet's INSIDE section (decks, frames, spaces and machinery through the whole hull, armour, break lines by the faction's rule, breach anchors)
Paint stack: the faction paint by name (sheet ships: tools/blender/kits/FACTION/stack.py, "bake": "stack"; traced hulls: paint.py), its masks, trim sheets and decals (R96 Q1)
Budget: triangles, draw calls and surfaces reported; scene gate ms measured on the 5080 (R111)
```

The four last lines are filled in before the build starts. A change to the sheet during the build is written on the sheet,
with its reason, so it reaches Ryan as a decision (R214).

The pull request body carries the evidence (R214): the build sheet link, the manifest, the budget numbers, the stage
results, and every change made to the sheet. A build pull request without it comes back from the outside check as BLOCKING.

## 8. Seat

An Opus worker builds every ship model and runs the recipe (R205, RULEBOOK 2.6); Codex runs captures and benches that
shape no ship. Muse draws. DeepSeek does well-specified tool repairs (a check, a table, a file format). The Board
writes the fleet briefs, accepts sheets, looks at every sweep and puts one image in front of Ryan. Hand a picture back to the
Board whenever a gate passes but the ship looks wrong: a pass on the numbers is not a pass on the look.

## 9. Solid objects near ships share the hull finish (Ryan, Nov 20 2026, R362)

Anything solid that flies or floats near a ship is built from the ship part kits and gets the hull finish: the faction's
paint, the LOOK.hull brightness band (look.gd READ) and the rim light (look_rim.gd), at a detail level that holds up
beside the hulls at c26. That covers torpedoes and rockets (the torpedo redesign thread), strike craft (fighters,
bombers, spores; issue 1373), battlefield wreckage (issue 1362) and anything new of the same kind. Glowing effects
(beams, shields, flashes, explosions, skies) stay effects and are not covered. Why: code-made tubes, boxes and grey scrap
sat beside fully painted hulls and made the whole scene look cheaper (inventory:
/mnt/project-files/board/asset_sources_1120/blender_vs_code.md). A new solid object that skips the kits needs Ryan's yes.

**Torpedoes and rockets (issue 1379 run 2).** `tools/blender/build_sheets/munitions/munitions.py` builds each body from its
faction kit's own parts (plates, rivet rings, the craft drive, the rack's rocket noses) in the old casing's frame (+X the
nose, x -1.15 to 1.15) and writes `godot/fx/munition_bodies/<faction>_<look>.glb` (small files, kept in the repo like the rocks).
`fx_weapons.gd` flies that body with LOOK.hull on every surface; a faction with no file keeps the code casing.
`fx/test/munition_body_check.gd` checks the frame and the finish. A new torpedo faction adds a builder there, never a
code shape. Each body is painted by its faction's paint stack (`kits/<kit>/stack.py` through `kits/shared/paint_stack.py`,
the Hullbreaker stack at its craft sizes) into small 512 atlases, so it wears the same paint as the hulls (Ryan, Nov 20:
"are we going to paint it and add more detail after?"). A munition is a few pixels on the board, so it carries detail at
the ships' density (seams, fins, conduits, slits, bolts) and its baked albedo may be lifted per faction (`LIFT` in
munitions.py; Sunward 2.3, since the black-iron finish read near black in game: Ryan, Nov 20, "Brighten"). A kit body
drives like a ship: a ship-size engine core at its nozzle and the ships' own engine trail (SH.TRAIL, faction engine colour
and trail style, a short wake), never a flame card, a halo or smoke puffs (Ryan, Nov 20: "the trails/engine effects look
super basic and weird"; fx_weapons.gd `_kit_trail_*`). A munition shot down by point defence never burns and never
flashes like a hit (look PD-C, Ryan's pick Nov 21 from board/torpedo_rework/tp_pd_*.jpg, after "it's hard to distinguish
whats a hull hit vs explosion"): pale tracer dashes from the target to the round, cold blue-white sparks, dark flak puffs,
and the round's drive goes out and it tumbles away trailing grey smoke (fx_weapons.gd `_pd_fire`, `_shot_down`). Fire and
an orange fireball belong only to a round that reaches the hull.
A munition leaves its own ship (Ryan, Nov 21: the torpedo "appears out of thin air" and "shoots straight up"; picks from
board/torpedo_rework/launch_1121/TL_*.jpg, "Yes much better"): it starts at its mount, slides clear along the tube with
its drive and baked nozzle glow dark (a torpedo for 0.7 s, rockets 0.14 s, the star 0.22 s), lights with a flash at the
nozzle, then turns onto the target. It flies flat (issue 1713, Ryan Nov 22: "I'd think we'd keep it flat"): a deck
tube's slide rises at most about 20 degrees, and from ignition the flight never climbs above the higher of its ignition
point and the target (`torpedo_flat_flight_check`). Drawn size against the ships (`ROUND_SIZE`): torpedoes 0.5 and
rockets 0.7 of the old round, with trail and flashes to match; the slide distance does not shrink with it
(fx_weapons.gd `_launch`, `_launch_step`, `_ignite`).

## 10. The ship detail standard (Ryan, Nov 22 2026, R411; RULEBOOK 5.18)

Ryan approved the Ship Graphical Detail and Consistency Upgrade Plan as the standing standard for every ship from now on.
A build brief, sheet or PR for any ship follows all four; a ship that cannot says why on its sheet.

1. **Maps by size band.** Stage 7 exports at 4096 for flagships and battleships (length 21 and up), 2048 for cruisers,
   carriers, destroyers and frigates (6.5 to 16.5), 1024 for strike craft (1.6). The export reads the band from
   `length_world`; no per-ship flag (issue 1680, RECIPE.md stage 7).
2. **AO light and LODs.** Every hull's material gets a calibrated `ao_light_affect` from its faction's look.gd READ row
   (0.35 to 0.55, Glasswrights 0.2), never Godot's 0.0, and the importer generates Godot mesh LODs for far cameras
   (issues 1678, 1679).
3. **One authored look per faction.** When a faction is next baked or repainted, its stack writes `authored_look = 1`
   calibrated to the single battle light rig, and that faction's READ albedo lift stops applying to those hulls. Order as
   the work lands: Eclipse (1422), Navy flagship H4_11 (1681), Glasswright flagship I8_37 (1682), Chorus (1683),
   Hullbreakers (1684), Sunward at its next fleet update. Never lift a single ship by hand to match.
4. **Hard points and turrets.** Every new destroyer and larger carries `hp_rcs` and `hp_board`, and articulated turrets
   where the faction uses them (HARDPOINTS.md). Known gaps: V16_37 (next Sunward update), D20_23 (inside 1422).

Priorities Ryan set: P1 engine and lighting first, no rebakes (1678 import fixes and LODs, 1679 AO light and reflection
gradient, sharing its sheet with 1463 SG); P2 folds into active bakes (1680 map bands and re-exports, 1422 Eclipse relief,
1681 H4_11, 1682 I8_37, 1683 Chorus recess glow); P3 roster and polish (1412 Navy escorts, 1145 Sunward Bastion and Hearth,
1684 Hullbreaker mesh diet and relief, tied to the 1645 hitch, 1685 faction idle motion). None of it holds an active
gameplay PR.

