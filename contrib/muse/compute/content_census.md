# Content census and strings corpus

Generated Oct 23, 2026 from repo HEAD 51337c2. Method: data.js, core.js and battle.js loaded under Node with the same browser-global stubs sim3d.js uses, tables read directly from the evaluated source. Strings corpus: a literal scanner over the 18 build files plus head.html, filtered by the heuristic below. Scripts: census.js and strings.js in the compute working folder.

## Census tables (CSVs in this folder)

| File | Source table | Rows |
|---|---|---|
| census_hulls.csv | HULLS (data.js) | 45 |
| census_weapons.csv | W (data.js) | 25 |
| census_boons.csv | BOONS (data.js) | 36 |
| census_relics.csv | RELICS (data.js) | 12 |
| census_modules.csv | MODULES (data.js) | 13 |
| census_admirals.csv | ADMIRALS (data.js) | 24 |
| census_encounters.csv | ENCOUNTERS (battle.js) | 8 |
| census_factions.csv | FACTIONS (data.js) | 6 |

All eight requested tables extracted. No extraction failures.

Notes on shape: boon description (d) and effect (fx) fields are functions of a magnitude argument in the source, so census_boons.csv exports them as their function source text. Relic and module effects export as JSON of their run or fx objects. Hull weapons export as weapon-id:arc pairs joined by semicolons.

## Breakdowns

Hulls by faction: voidsworn 8, chorus 8, hegemony 7, corsair 7, ithar 7, deathless 6, no faction field 2 (the squadron craft).

Hulls by class: Cruiser 11, Frigate 9, Destroyer 9, Carrier 5, Squadron 3, Battleship 2, Dreadnought 1, Super-dreadnought 1, Battle-barge 1, Bio-titan 1, Ark 1, Tomb-ark 1.

Weapons by kind: battery 9, lance 4, flak 3, torp 3, sq 3, bio 2, gauss 1.

Boons by patron: iron 5, storm 5, hunger 5, star 5, rook 5, ember 5, no patron field 6 (those six carry a duo field instead).

Admirals by faction: 4 each across all six factions, 24 total.

Other content tables counted, no CSV requested: patrons 6, events 11, abilities 13, perks 14, aspects 6, legacy entries 12, captains 6, archetypes 3.

## Strings corpus

strings_corpus.csv: 1,507 rows, columns file, line, string. Heuristic: a literal qualifies if it contains a space and a capital letter, or is longer than 12 characters with letters. Excluded: URLs, file paths, colour codes, CSS blocks, dynamic template fragments, shader code markers, bare identifiers, escape-heavy blobs, and long space-free encoded data (the meshopt and sound-data payloads). The corpus is a working sweep, not a proof: a small number of code-adjacent strings (selectors, decoder filter names, debug labels) pass the heuristic and remain in the file.

Rows per file:

| File | Strings |
|---|---|
| data.js | 798 |
| ui3d.js | 205 |
| battle.js | 112 |
| ships3d.js | 86 |
| scene3d.js | 60 |
| campaign_run.js | 58 |
| campaign_meta.js | 49 |
| sfx.js | 39 |
| perf3d.js | 29 |
| gfx3d.js | 21 |
| meshopt3d.js | 11 |
| campaign3d.js | 9 |
| head.html | 8 |
| fx3d.js | 7 |
| core.js | 6 |
| main3d.js | 4 |
| wfx3d.js | 3 |
| vfx3d.js | 2 |
| sfx_data.js | 0 |
