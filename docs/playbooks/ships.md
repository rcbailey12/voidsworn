# Playbook: ships

Issue 405. Written by the Board (Fable 5.2), Nov 11 2026. Format: docs/playbooks/PROGRAM.md. Use this to take one ship from
nothing to a hull in the game. The detailed stage notes are docs/ship_pipeline/RECIPE.md; this page is the order of work, the
gates, and who does what.

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

## 3. Steps

| Step | What | Where | Seat |
|---|---|---|---|
| A | Direction pictures, three per faction | Muse issue from the factions.md directions | Muse's image models |
| B | Ryan picks one direction per faction | one sheet per faction, the Board's pick stated | Ryan |
| C | Fleet brief: feature table per ship | docs/ship_pipeline/fleets/FACTION.md | Board or an Opus helper (high effort) |
| D | Three-view sheets per ship, checked against the table and the sheet's "Never" list | docs/ship_pipeline/concepts/ (new files; old ones stay as history) | Muse draws, Board accepts |
| E | Recipe stages 1 to 7 on the PC, one ship at a time | tools/recipe/1_concept_in.bat to 7_export.bat; ship file tools/recipe/ships/SHIP.json from _template.json | Codex (GPU) |
| F | Blob sweep: nine cells, bow, midship, stern from top, side and below, beside the concept views | docs/ship_pipeline/BLOB_SWEEP.md | Codex renders, Board looks, Ryan's eye decides |
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
Owner: codex
Brief: docs/playbooks/ships.md; docs/ship_pipeline/RECIPE.md; docs/playbooks/factions.md (the FACTION sheet); docs/ship_pipeline/fleets/FACTION.md (the row for SHIP)
Deliver to: tools/recipe/ships/SHIP.json, tools/blender/kits/FACTION/ (only what this hull adds), docs/shots/ships/SHIP/ (blob sweep, bench sheet)
Branch: codex/issue-<number>
Effort (Codex): high
Done when: stages 1 to 7 end without FAILED; the outline gate, the audit and check_export.py pass and their output is pasted in the report; the nine-cell blob sweep and one battle camera bench image are committed. What Ryan will see: the ship at the battle camera beside its concept.
```

One hull is one to three Codex runs (the trace tuning and the paint bake are the long steps), plus one Ryan look. A faction's
first hull costs more, because it builds the kit and the paint.

## 8. Seat

Codex runs the recipe. Muse draws. DeepSeek does well-specified tool repairs (a check, a table, a file format). The Board
writes the fleet briefs, accepts sheets, looks at every sweep and puts one image in front of Ryan. Hand a picture back to the
Board whenever a gate passes but the ship looks wrong: a pass on the numbers is not a pass on the look.
