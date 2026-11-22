---
name: ship-kit
description: Use when building, dressing, painting or exporting any hull, part kit or the station for Embers of the Hollow Sun (build sheets, Blender blockouts, tools/recipe stages 1 to 7, tools/blender/kits, hard points, the glb export). Points at the binding build method and the ship rules every part must pass.
---

# Ship kit: build, check, export

This skill is a pointer. The method is binding and lives in the repo, not here (rewritten Nov 11 2026, issue 492; the old
browser-era Pyre-Barge procedure is archived at docs/archive/skills/ship-kit_SKILL_2026-11-11.md).

## Read first, in this order
1. docs/RULEBOOK.md sections 4 (ships and concepts) and 5 (the build pipeline): each rule with its reason. It wins.
2. docs/playbooks/ships.md: section 0 (the settled method, binding, R214), the steps, the checks, the traps and the job
   template with its four build lines (Route per part, Inside, Paint stack, Budget).
3. docs/ship_pipeline/RECIPE.md: what each of the seven tools/recipe stages does and how it fails.
4. docs/playbooks/factions.md: the faction's sheet (shape, colour, where guns sit, how it breaks, its Never list) and the
   breach anchors by class; docs/ship_pipeline/HARDPOINTS.md for the hard point contract.
5. The ship's build sheet in docs/ship_pipeline/build_sheets/<ship>/, which must pass
   contrib/muse/design/concept_standard_2026_11/standard.md before any build (R203).

## The rules in one breath (the rulebook has the reasons)
- Space ships, never sea ships, in the whole shape (RULEBOOK 4.1). No gun faces backward or into the ship (4.2).
- Parts snapped to the real hull on a visible mount, in matched pairs at sensible hard points; the Hullbreakers may be junky (4.3).
- The concept guides, it is not traced; the builder designs and lists every change on the sheet (5.2).
- Insides through the whole hull; breaks by the faction's rule and the class, never a fixed count or a straight cut (5.4, 5.5).
- Hand-built parts carry the hull's level of surface detail (5.6). Paint from geometry masks, trim sheets and decals; the
  concept is never projected (5.3).
- Costs reported, never capped; the only binding law is the measured scene gate (3.9). The outline overlap and the blob
  sweep are reported for Ryan's eye, not pass bars (5.8, 5.9).
- Every ship model made in Blender is an Opus worker's (RULEBOOK 2.6, R205).

## Procedure
1. Build sheet first (standard.md), with its INSIDE section and its "Changed from the picture" list.
2. Recipe stages 1 to 7 on the PC (tools/recipe/1_concept_in.bat to 7_export.bat; ship file tools/recipe/ships/<ship>.json
   from _template.json; faction kit and paint in tools/blender/kits/<faction>/). Each stage stops with FAILED and a non-zero exit.
3. Stage 4's audit (tools/recipe/audit.py; audit_selftest.py proves it can fail) and stage 7's check_export.py must pass.
4. The nine-cell blob sweep (docs/ship_pipeline/BLOB_SWEEP.md) and the ship at the battle camera on the look bench
   (tools/pc/jobs/look_bench.bat; the screenshot-verdict skill), beside its concept.
5. The pull request body carries the done-when evidence and the method line (build sheet link, manifest, budget numbers,
   changes made to the sheet), or the outside check returns it as BLOCKING (RULEBOOK 5.14).

## PC runs
Heavy work runs on Ryan's PC through the job queue, one GPU job at a time (RULEBOOK 3.2 to 3.5): see the playtest-and-balance
skill's "PC runner" section. Keep the job's PC folder lean. Never delete anything on the PC.
