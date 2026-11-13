# Build manifest: schema and check (issue 550, R214 mechanism 3)

Every ship built from a build sheet writes `docs/ship_pipeline/build_sheets/SHIP/manifest.json` (tools/blender/build_sheets/
layout.py writes it with the sheet). The manifest says how each part was made; the sheet says how it must be made. Ryan, Nov
11 2026 (R214): "make the researched build approach binding on every ship build, not just recorded." So the manifest is
checked against the sheet, not trusted: `contrib/opus/tools/build_manifest_tests.js`, a row of run_all_checks (GitHub runs it
on every pull request). It reads only files in git; no Blender, no PC.

## The manifest (manifest.json)

| Field | Type | Meaning |
|---|---|---|
| `code` | string | the ship code, the folder name |
| `sheet_version` | number | the sheet version it was written from |
| `routes_note` | string | what the routes mean; names the kit file, e.g. `tools/blender/kits/hullbreakers/parts.py` |
| `kit` | string, optional | the kit file; when absent the check reads the `tools/blender/kits/...py` path out of `routes_note` |
| `turret_marking` | string | how a turret is marked in the model (R219) |
| `parts` | list | one entry per feature table row, below |
| `masses` | list | one entry per Major masses row: `name`, `route`, and `library_entry` when generated |
| `break_pieces` | list | one entry per break piece the sheet's break lines make, below |
| `insides` | string | the interior statement (R215); must not be empty |

A part: `id` (the feature table ID), `kind`, `what` (the feature table's Fitting text, word for word), `count` (the leading
number of the Count cell), `route`, `source` (picture or designed), `inventory` (R218 inventory keys); guns add `turret`,
and turrets `pivot_object`, `arc_lo`, `arc_hi` (R219). A generated part adds `library_entry`.

A break piece: `name`, `stations` ("A to B percent"), `bounded_by` (the break line names), `full_interior` (must be `true`).

## Routes (R96 Q5, R214)

| Route | Means | Extra rule |
|---|---|---|
| `kit` | built by the faction parts kit | the kit file the manifest names must be in git |
| `hand-built` | modelled for this hull | none |
| `generated` | from a reviewed part-library entry | `library_entry` names `<library>/<entry>`, and that entry is reviewed |

Any other word fails.

## What the sheet says (feature_table.md)

- **Parts:** the `## Feature table` section, its `| ID |` table. A `Route` column, when present, states each row's route:
  `kit`, `hand-built`, `generated`, or `generated: <library>/<entry>` (then the manifest must name the same entry). With no
  Route column every row is `kit` (a fitting comes from the kit by default, ships.md section 0 item 1). A sheet with any part
  that is not kit must carry the Route column, so the decision is on the sheet where Ryan sees it (ships.md section 7).
- **Masses:** the `## Major masses` section, its `| Mass |` table. Same Route column rule; with none, every mass is
  `hand-built` (the hull is traced and built by hand, R215 point 4).
- **Break pieces:** the `## INSIDE` section, its `| Break line |` table. A Station cell that reads `N` or `N (seam wanders
  ...)` is a transverse line at N percent; one that reads `A to B (along)` is a line along the hull. The pieces follow the rule
  layout.py uses: transverse lines, sorted from the prow, cut the hull into `bow piece`, `midships piece 1` ... `midships
  piece n`, `stern piece`; each piece is bounded by the transverse lines at its ends; a line along the hull that runs through
  a piece splits it into `<name>, upper half` and `<name>, lower half`, both also bounded by that line.

## Part libraries

A reviewed part library lives at `docs/ship_pipeline/part_libraries/<library>/library.json` (none exists yet, so today no part
may be generated):

```
{"library": "<library>", "entries": [
  {"id": "<entry>", "what": "...", "file": "<path to the part>",
   "reviewed": {"by": "<who reviewed it>", "date": "YYYY-MM-DD", "ref": "<issue or review file>"}}
]}
```

An entry counts as reviewed only when `reviewed.by`, `reviewed.date` and `reviewed.ref` are all filled in.

## What fails

| Code | Fails when |
|---|---|
| ROUTE | a part's or mass's route differs from the sheet's, or is not one of the three words |
| LIBRARY | a generated part or mass names no `<library>/<entry>`, names a library or entry that does not exist, names an entry not reviewed, or names another entry than the sheet |
| INTERIOR | a break piece the sheet's break lines make is missing from the manifest or has `full_interior` other than `true`; or `insides` is empty |
| PARTS | a feature table row has no manifest part, a manifest part has no row, or an ID is listed twice |
| MASSES | a Major masses row has no manifest mass, or the other way round |
| COUNT | a part's `count` or `what` differs from its feature table row |
| BOUNDS | a manifest piece's `bounded_by` differs from the sheet's, or the manifest has a piece the sheet's lines do not make |
| KIT | there are kit parts and the manifest names no kit file, or the file is not in git |
| FORMAT | a table or list the check needs is missing or does not read |

A piece whose `stations` differ from the sheet's break lines by more than 0.15 percent is printed as a note, not a failure.

## Proof it can fail

The standing run also checks the deliberately broken fixture `contrib/opus/tools/fixtures/build_manifest_mismatch/` (seven
planted faults, its README lists them) and single-fault copies of the A16 manifest, each refused for its own reason. One
sheet by hand:

    node contrib/opus/tools/build_manifest_tests.js docs/ship_pipeline/build_sheets/SHIP [part library root]
