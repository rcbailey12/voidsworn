# Playbook: ships

Issue 405. Written by the Board (Fable 5.2), Nov 11 2026. Format: docs/playbooks/PROGRAM.md. Use this to take one ship from
nothing to a hull in the game. The detailed stage notes are docs/ship_pipeline/RECIPE.md; this page is the order of work, the
gates, and who does what.

## 0. The settled method (binding on every ship build; Ryan, Nov 11 2026, R214)

A ruling that changes how ships are built is not landed until the same pull request edits this file or RECIPE.md (R214).
Each line below is a ruling Ryan made; the source is named so anyone can check it.

1. **Parts and hull.** Hand-built parts by default; AI-made parts only through a reviewed part library per faction (R96 Q5).
   The hull is traced in clean faceted sections from an AI shape reference made from the concept (recipe stages 2 and 3):
   the AI mesh is a tracing guide and a grime source, never shipped (RECIPE.md stage 2).
2. **Paint.** Procedural materials driven by masks baked from the ship's own geometry (curvature, ambient occlusion, edge
   wear), plus trim sheets and decals; colours may be sampled from the concept; the concept picture is never projected onto
   the ship (R96 Q1). Local AI texturing only after a one-hull proof of unlit PBR output (R96 Q1).
3. **The recipe.** Seven stages run in order from tools/recipe, one shared plumbing module with no look of its own, one kit
   per faction; the worked example is the Hullbreaker cruiser C15s_23 (issue 209 rounds 6 to 8; checks opus_check_336 and
   opus_check_341).
4. **Breakable by design, comprehensive insides.** Real hull thickness, decks, bulkheads and machinery spaces, authored break
   lines with matching inner faces and damage textures (R98). Insides are built through the whole hull, not only in the break
   pieces (Ryan, Nov 11: "better to be comprehensive with internal if we can without performance issues", R215); they stay
   hidden until a piece breaks away, so they cost memory, not frame time, and their cost is reported (R111). Rim bands at break
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

## 1. Target

- The faction's sheet in docs/playbooks/factions.md is the law for look: silhouette, shape language, colours, where guns
  sit, how it breaks, and its "Never" list. The rules for every faction at the top of that file apply to every hull.
- Ryan: "these are SPACE ships" (Oct 22). "It should vary by size of ship, faction, etc. We want things to be on theme"
  (Nov 10, hard points). "all the factions shapes and stuff came before we redesigned them" (Nov 10): the 36 concepts in
  docs/ship_pipeline/concepts/ are history, not targets.
- A ship is judged at the battle camera first (camera 170 on the look bench): one silhouette, one main colour, one accent.

## 2. Inputs (what must exist before a hull is started)

1. Ryan's picked direction for the faction (docs/playbooks/factions.md, "The concept redo"; FINDINGS has each pick).
2. A fleet brief for the faction: one written feature table per ship (class, length, beam, weapon slots from data.js, engines,
   break lines, the three or four features that make it that ship). The table outranks every picture.
3. A three-view concept sheet for the ship, to contrib/muse/design/concept_standard_2026_11/standard.md: side, top, front, one
   light, plain background. A generated sheet is an identity and proportion reference: it never settles counts.
4. The faction's parts kit and paint (tools/blender/kits/FACTION/kit.py and paint.py). A faction's first hull builds them.
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

## 2c. Parts that read and fit together (R217)

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
- Hits, wounds, breaks and deaths use the insides where they exist.

## 3. Steps

| Step | What | Where | Seat |
|---|---|---|---|
| A | Direction pictures, three per faction | Muse issue from the factions.md directions | Muse's image models |
| B | Ryan picks one direction per faction | one sheet per faction, the Board's pick stated | Ryan |
| C | Fleet brief: feature table per ship | docs/ship_pipeline/fleets/FACTION.md | Board or an Opus helper (high effort) |
| D | The build sheet per ship (R203, R209, R213): one Blender blockout designed from the accepted concept, true views, feature table, INSIDE section, changes from the picture | docs/ship_pipeline/build_sheets/SHIP/ | Opus worker builds, Board checks beside the concept, Ryan looks |
| E | Recipe stages 1 to 7 on the PC, one ship at a time | tools/recipe/1_concept_in.bat to 7_export.bat; ship file tools/recipe/ships/SHIP.json from _template.json | Opus worker (R205: every Blender model is Opus's) |
| F | Blob sweep: nine cells, bow, midship, stern from top, side and below, beside the concept views | docs/ship_pipeline/BLOB_SWEEP.md | Opus worker or Codex renders, Board looks, Ryan's eye decides |
| G | The ship in the game on the look bench, battle camera first | tools/pc/jobs/look_bench.bat | Codex |
| H | Ryan sees one image: the ship at the battle camera beside its concept | | Board |

The seven recipe stages, each a double-click file that stops with FAILED and a non-zero exit when it should:
1 concept in, 2 the AI shape reference (TRELLIS.2, a shape and grime source only, never shipped), 3 the traced hull and the
outline gate, 4 the faction parts kit and its audit, 5 the paint bake, 6 the LOD chain and its cost, 7 the game export with
hard points.

## 4. The checks that prove it

- Stage 3: the outline gate, 90 percent of the concept's outline at the concept's own camera. FAIL means not ready for parts.
- Stage 4: the audit lists nothing: no part floats or is sunk, nothing crosses a break line, no gun aims backward or into
  the ship. audit_selftest.py proves the audit can fail.
- Stage 7: check_export.py passes: every weapon slot in the ship's data.js list has a hard point, every hard point is on the
  mesh, and the breach anchors meet their contract. The contract's count comes from the hull's class and faction
  (factions.md, "Breach anchors by class"; issue 363), never from a constant.
- Stage 6 reports cost; costs are never capped (R111).
- The insides (R209): a break render of each authored break line at the battle camera and at camera 60 shows decks, frames
  and machinery, never a hollow or flat interior. A hull that shows one is not done.
- The blob sweep is a viewing instrument, not a pass bar (R121): the Board lists what it sees, Ryan decides.

## 5. Traps

- One three-quarter concept is not enough: rounds 7 and 8 could not fit the bow from it (R162). Three views, always.
- Generated sheets hold identity, palette and view angle, and never counts or aspect (Muse's C15s trial). Write the table first.
- Sea-ship parts creep back in every generated picture: porthole rows, lattice masts, cranes, keel fins, stepped decks. Check
  every sheet against the "Never" list before it reaches the recipe.
- The AI shape reference mangles guns, bridges, masts, tanks, bows and nozzles. They are rebuilt from the kit by default.
- Hand-built parts must carry the hull's level of surface detail, or the ship looks assembled from two games.
- Heavy work runs on the PC, one GPU job at a time. Never delete anything on the PC.
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
Done when: stages 1 to 7 end without FAILED; the outline gate, the audit and check_export.py pass and their output is pasted in the report; the manifest matches the build sheet (run_all_checks); a break render of every break line shows decks and frames, never a hollow; the nine-cell blob sweep and one battle camera bench image are committed. What Ryan will see: the ship at the battle camera beside its concept.
Build sheet: docs/ship_pipeline/build_sheets/SHIP/ (passed standard.md on <date>; Ryan's look on <date>)
Route per part: kit, hand-built, or generated (generated names its reviewed part-library entry, R96 Q5)
Inside: the sheet's INSIDE section (decks, frames, spaces and machinery through the whole hull, armour, break lines by the faction's rule, breach anchors)
Paint stack: the faction paint by name (tools/blender/kits/FACTION/paint.py), its masks, trim sheets and decals (R96 Q1)
Budget: triangles, draw calls and surfaces reported; scene gate ms measured on the 5080 (R111)
```

The four last lines are filled in before the build starts. A change to the sheet during the build is written on the sheet,
with its reason, so it reaches Ryan as a decision (R214).

The pull request body carries the evidence (R214): the build sheet link, the manifest, the budget numbers, the stage
results, and every change made to the sheet. A build pull request without it comes back from the outside check as BLOCKING.

## 8. Seat

Codex runs the recipe. Muse draws. DeepSeek does well-specified tool repairs (a check, a table, a file format). The Board
writes the fleet briefs, accepts sheets, looks at every sweep and puts one image in front of Ryan. Hand a picture back to the
Board whenever a gate passes but the ship looks wrong: a pass on the numbers is not a pass on the look.
