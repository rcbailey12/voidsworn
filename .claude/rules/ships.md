---
paths:
  - "docs/ship_pipeline/**"
  - "docs/playbooks/{ships,factions,concepts_round2}.md"
  - "tools/{blender,recipe}/**"
  - "hulls/**"
  - "hulls_hi/**"
  - "godot/assets/ships/**"
---

Read the [ships playbook](../../docs/playbooks/ships.md) for the build method and the [ship recipe](../../docs/ship_pipeline/RECIPE.md) for the stages.

## 4. Ships and concepts

4.1 **Space ships, never sea ships, in the whole shape.** No boat profile, keel, raked prow, deck house, mast, funnel, crane,
railings, porthole rows or anything hanging off; a worked belly. Why: Ryan, Oct 22: "careful that these don't stretch into
obvious naval-looking ships. again, these are SPACE ships"; Nov 11: "I don't understand the random things hanging off, it reads
as naval. We need to do a full pass across all ships and factions so not naval" (R185). Set: Ryan (Oct 22, Oct 24, R185). Ids:
agents-19, agents-25, R8b, R185a, concepts-16. Detail: docs/playbooks/concepts_round2.md gate line 11.

4.2 **No gun faces backward or into the ship at rest; a turret may turn aft only to follow a target its rules arc lets it hit
(6.16, R222).** Why: "no ship in the game fires backward" (Oct 22). Set: Ryan (Oct 22; the turret line Nov 12, R222).
Ids: agents-17, blob-03, R222.

4.3 **Parts look like they belong: snapped to the real hull on a visible mount, in matched pairs at sensible hard points; the
Hullbreakers may be junky.** Why: bolt-ons on the AI hulls floated, sank or sat anywhere (Oct 21). Set: Ryan, Oct 21. Ids:
agents-18, agents-24, factions-02.

4.4 **A ship reads as armed from above at thumbnail size; each faction mounts its forward weapon its own way, never a long
barrel on the nose tip; no two factions share an outline from above; identity shows under the battle camera.** Why: "It's
really hard to tell if there's any guns right now so it barely looks like a warship" (R176); "same giant gun directly on nose.
It's good to have forward facing but it always looks the same across factions" (R183). Set: Ryan's complaints; wording Board
(R176, R183). Ids: R176b, R183a, R183b, concepts-04, concepts-05.

4.5 **Every faction is its own: its own parts kit and shape language; only invisible plumbing is shared.** Why: "all the
factions are supposed to be unique and different. Having the same parts everywhere is against that" (R151). Set: Ryan. Ids:
R151b. The faction sheets (shape, colour, where guns sit, how it breaks, its Never list) are docs/playbooks/factions.md.

4.6 **One concept style for every faction: realistic and detailed, like a photograph of a real built object**
(contrib/muse/design/concept_directions_2026_11/corsair_A.jpg); a picture that reads as an illustration, a toy or a cartoon
fails. Ryan judges the style, side by side; the Board never declares it. Why: "Pretty realistic and detailed to help with the
builds... this style is how it should look in game" (R197); "It's semi realistic but not quite" (R198). Set: Ryan, Nov 11.

4.7 **When Ryan likes a picture, the next image job edits that picture**; colour alone never sends a picture back; when image
rounds cannot reach the style without breaking the shape, stop and use the Opus build-sheet route. Why: six Hullbreaker rounds
were lost redescribing a liked picture in words (R192); "we can fix color ourselves rather than get stuck in a loop with color
fixes with image generation" (R204). Set: Ryan and Board, Nov 11 (R192, R204, R206).

4.8 **No generated concept reaches a build, or Ryan, without the Board's review against the written gate**
(docs/playbooks/concepts_round2.md). The gate's ratios and fractions (proportions per class, the stern fraction) are starting
points for a drawing, not identity. Why: "I need you to do a much more in depth review and refinement before these ever go to
actual builds" (R172); Hegemony's 4.5 : 1 was overruled by R183's 3 : 1. Set: Ryan (R172); the ratio note Board. Ids: R172a,
R172b, concepts-08, concepts-14.

4.9 **Start from what was already liked.** Why: two rounds were lost designing the Glasswrights and Hullbreakers afresh and
sanding off what made them theirs (R180). Set: Board lesson after Ryan's review (R180). Ids: R180c, factions-17.

4.10 **The finished battle is Sunward Crusade against Eclipse, on the dead-star board.** Why: one finished fight proves every
recipe and is the reference for later jobs (R167: "I want this to end with something that opus or other models can run
from"). Set: Ryan (R167, R180). Ids: R167b, R180d, handoff-01.

4.11 **Every part has a job and every weapon is its faction's own.** A part with no purpose is cut; weapons, turrets and
launchers are designed per faction from the lore bible and the faction sheet (how the weapon works shows in its mount,
housing, barrel and muzzle), never a shared silhouette; a gun in another weapon's firing lane or backblast is a clash. Why:
Ryan on the Hullbreakers: "let's get rid of the chains randomly around the ship. There's no purpose" and "a gun directly
behind the rocket pods on a16 ... seems like it conflicts"; on Eclipse: "their turrets look the same as hullbreakers" (R221).
Set: Ryan, Nov 12 (R221). Parts carry the hull's detail density: triangles and edge features per square unit, per part
type, within 25 percent of the hull's, reported on every sheet (R224: "They also just look smoother and less detailed, maybe
slightly less poly than the rest of the ship").

## 5. Ship build pipeline

5.1 **No ship is built until its build sheet passes the concept standard** (contrib/muse/design/concept_standard_2026_11/standard.md:
true side and top at one scale, underside, bow-on, length from game data, scale bar, a feature table that outranks the
pictures). Why: "I want to make sure that they are good enough to actually hand build from in blender" (R203). Set: Ryan,
Nov 11.

5.2 **The concept guides the build; it is not traced.** The Opus builder is the designer of record: it keeps the picture's
identity (mass, outline from above, character, palette, where the big features sit), fixes what would not work as a built
object, takes guns from the hull's data.js slots as batteries that make sense, carries every tier and change of height the
picture shows, and lists every change on the sheet. Why: "Use it to guide, not the very final exact design" (R207); "The guns
look randomly placed and don't make sense... the builds look like square blocks basically" and "The concept should inform and
guide but it's not a final play by play guide" (R213). Set: Ryan, Nov 11. Ids: R25 (concepts are inspiration), R207, R213.
The Board (Opus) is the final designer and director; Muse concepts. Between an accepted concept and the build the Board makes
the design calls, family distinctness included (a class that reads as a small copy of another class from above is changed in
the build), lists them on the sheet and shows Ryan the result instead of asking first. Ryan's picks of concepts and his
verdicts on pictures stand. Why: "You're the final designer and director. Muse is just concepting" (R233). Set: Ryan, Nov 12.

5.3 **The settled build method is binding** (docs/playbooks/ships.md section 0; docs/ship_pipeline/RECIPE.md): the hull designed
on the approved build sheet (5.1, 5.2), which the recipe builds as it is and never traces again (issue 592), with the stage 2
AI shape reference made from the accepted concept as an outline and grime reference only, never shipped; hand-built parts, AI parts only through a reviewed faction
library; paint from geometry masks, trim sheets and decals, never projected concept art; the seven stages. Why: projected
concept paint was dropped on all 36 hulls (R82); Ryan adopted the research route (R96); the method kept drifting between
documents (R214). Set: Ryan (R82, R96, R214, R215). Ids: R82d, R96a, R96c, R150a.

5.4 **Breakable by design, with comprehensive, detailed insides.** Every hull has real thickness and insides through the whole hull
(decks, frames, spaces, machinery; Chorus flesh and bone; Glasswright layered glass), rim bands and a dark liner where the
intact ship shows; the build check fails a hull whose broken pieces show a hollow or flat inside. Starting with the Blender
Interior Kit V2 (issue 1743, R416 Layer 3), new ship builds and rebakes replace plain untextured chamfered boxes and flat slabs
with modeled interior modules (ribbed decks, framed arch bulkheads, cylindrical reactors/turbines/racks, sculpted organic sacs
and bone struts, collared crystal waveguides), UV-mapped to a shared per-faction interior trim atlas (`albedo`, `normal`, `orm`,
optional `emission`, supported by `tools/recipe/export7.py`) and verified by a build-sheet cutaway render while staying 0 px
clean on `surface_check.py`. Glasswright thick panes (`kits/ithar/hull.py` mosaic_core) carry the smoked lining
(`gw_smoke`, walls at most 0.11) on their inner face, so a cut shows dark glass, not the bright mosaic (R427 Wave 0). Glasswright insides are pale pearl glass, not dark: their own wall ceiling (`wall_max` 0.45 in faction_looks.json ithar interior) replaces the 0.11 one, and the light cores and room crystals glow amber, violet and green inside the area light budget (Ryan, Nov 24 2026: dark grey "will look extremely odd as wreckage"; his pick "Pearl glass with glowing colour"). Hulls built before this rule rely on the runtime Wounds V2 triplanar interior shader and breach-mouth
3D dressing (issue 1741) or, for legacy hollow hulls, the game-side interior fallback (issue 167). Why: "the broken open pieces
are visibly empty" (R98); "so we don't run into the issues of before with just empty looking husks" (R209); "I think it's
better to be comprehensive with internal if we can without performance issues" (R215); auditing all 45 ships under R416 showed
plain untextured boxes and flat slabs behind the hull skin (Ryan, Nov 22). Set: Ryan, Nov 4, 11 and 22. Ids: R70, R98a, R98b,
R99a, R209, R215, R416.

5.5 **Breaks follow the faction's rule and the class, never a fixed count or a straight cut**; hard points and breach anchors
scale with class and faction, read from one table (factions.md; the check reads it, issue 363). Why: "is 28 hard points for
every ship? It should vary by size of ship, faction, etc. We want things to be on theme." (R164); wrecks must look blown
apart (R186). Set: Ryan (R164, R186, R215). R99 Q2 (two transverse lines plus one longitudinal) and AGENTS.md's "two or three
break lines" are retired. Ids: R164d, R99b, R98b, ships-07, factions-04.

5.6 **Hand-built parts carry the hull's level of surface detail.** Why: "the level of texture and details seem to vary wildly"
(Oct 21). Set: Ryan. Id: agents-28.

5.7 **Structure first: the massing carries the concept's variety of shape before any detail.** Why: "There's so much less
variety in the shape and structure of it, so it's not just adding but almost removal." (R140). Set: Ryan, Nov 9. Ids: R140,
R213.

5.8 **The outline overlap against the concept is reported, not a pass bar** (was 90 percent, R147). Why: the builder is told
to depart from the picture where it does not work (R207), and a 90 percent pass let a wrong bow through (R157). Set: Board,
Nov 11 (reworded). Ids: R147, ships-05, recipe-03.

5.9 **The blob sweep (nine cells: bow, midship, stern from top, side and below) is a viewing instrument for Ryan's eye, not a
pass bar.** Why: assumed gates stop binding until measured (R121). Set: Ryan (R121d). Ids: agents-27, ships-08, blob-01.

5.10 **The guns are never bent to fit a score.** Why: casemate barrels had been bent to raise the outline match (R156). Set:
Ryan ("I agree with all of your takes", R156). Id: R156a.

5.11 **Every recipe stage is one double-click, stops on its own failure with a non-zero exit, deletes nothing, and stage 7
copies aside what it replaces before copying into the game.** Why: Ryan is not a coder; missing things fail loudly (R158).
Set: Board and Muse's conditions (R158). Ids: recipe-01, recipe-02, recipe-08.

5.12 **Ship assets ship as glb copied into the PC build; .vsm belongs to the frozen browser game.** Why: Godot cannot load
.vsm. Set: Board (G-9, G-11).

5.13 **Assets only under CC0 (Kenney, KayKit, Poly Haven, ambientCG); Quaternius is out.** Why: its licence is not CC0 (D11).
Set: Board. Ids: D11, X14.

5.14 **A build pull request carries its done-when evidence and a method line** (build sheet link, manifest, budget numbers,
changes made to the sheet); the outside check returns one without them as blocking. Why: R214. Set: Ryan, Nov 11.

5.15 **Parts read as what they are and fit together: the fit check.** Engines are bells with throats and rings, guns have a base,
mantlet, breech and muzzle, launch tubes have depth; the bow and big masses carry the concept's shaping. No part inside
another, in another gun's arc, in an exhaust cone or blocking a launcher; a fit view and fit report on every sheet and build.
Why: round 2 sheets had guns blocking rockets and in front of an engine, tubes as flat circles, engines and guns as plain
tubes, and a flat-block bow (Ryan, Nov 11, R217). Set: Ryan, Nov 11 (R217). Ids: ships-2c.

5.16 **Fidelity is whole-ship: a parts inventory, one detail level, kit first, region by region.** Every feature the concept
shows is listed with its sub-parts and modelled; every part sits at the same detail level as its neighbours; each faction's
kit holds every part type at that level; the fit check covers every part; the sheet ticks the inventory per blob-sweep cell
beside the concept. Feedback on one part becomes a rule for all parts. Why: "Engines and guns are the reference but we want
to carry that through to the whole model. Don't just patch singular behavior or examples, use it for global learning and
shaping the approach" (Ryan, Nov 11, R218). Set: Ryan, Nov 11 (R218). Ids: ships-2c.

5.17 **A machine never crosses a seam; structure that crosses a seam is torn at it, insides included.** Guns, turrets,
casemates, launchers, engines, thrusters, claws and sensor masts ride whole with one piece: the seam moves, or kinks round
them in plan. Hull plating, frames, ribs, rails, openings such as a launch bay, and every inside (decks, bulkheads, rooms,
the liner) tear across a seam, along the same ragged line as the plating over them: no inside panel stays whole across a
break or sticks out past its piece's broken hull. The stage 4 audit reads each part's kind from the build (the faction kit's
MACHINES) and fails only a machine across a seam; the export carries each seam's path and each machine's box, and the game's
death cut reads them there (fx/test/death_seam_check.gd: zero machines split, zero insides outside their piece). Why: a cut
gun reads as sliced, a torn plate as blown apart (R186, "blown apart, never sliced"); whole deck and bulkhead slabs stuck out
of the broken A16 as big flat squares (Ryan, Nov 12, issue 600). Set: Board, Nov 12 (R226; insides added from Ryan's eye,
issue 600). Ids: ships-2c.

5.18 **The ship detail standard: textures by size, AO and LODs on import, one authored look, full hard points.** For every
ship from now on: (1) stage 7 exports maps by the ship's length band, flagships and battleships (length 21 and up) at 4096
(stage 5 already bakes 4096), cruisers, carriers, destroyers and frigates (6.5 to 16.5) at 2048, strike craft (1.6) at 1024
(issue 1680); (2) every hull gets a calibrated `ao_light_affect` (never Godot's default 0.0; per faction in look.gd READ, 0.35
to 0.55, Glasswrights 0.2) and automatic Godot mesh LODs on import (issues 1678, 1679); (3) each faction's paint stack moves
to `authored_look = 1`, calibrated to the one battle light rig, the next time that faction is baked or repainted, and its
look.gd READ albedo lift (Navy 0.4x, Eclipse 2.2x and the rest) retires with it; (4) every new destroyer and larger carries
`hp_rcs` and `hp_board` hard points, plus articulated turrets where the faction uses them. Comparison sheets go on Ryan's Pick
Sheet; GPU captures only after green checks and Artoo (3.12). Why: hero hulls were downsampled to 2048 while fighters carried
39 MB of maps, baked seam AO vanished under the key light, and each faction leaned on a different after-the-fact lift
(Ryan's Ship Graphical Detail and Consistency Upgrade Plan). Set: Ryan, Nov 22 2026 (R411). Replaces the Nov 19 park of
far-away LODs until a speed check (R328 notes, issue 1152) and, for the game, issue 592's "the game loads no LOD chain":
stage 6's hand chain stays an analysis product, the game makes its own LODs at import.
