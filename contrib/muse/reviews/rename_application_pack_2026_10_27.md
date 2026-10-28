Rename application pack (Oct 27 program item 9). Purpose: turn Ryan's six rollout-audit rulings (Oct 27, 17:58 and 18:02 PDT, recorded in the rollout synthesis) into an exact edit list at HEAD 68b42ce406286eb95ea7df6aaf3f683c1231b51d, so Opus applies them without re-deriving locations. Line numbers are at the pin; if a file has moved since, grep the quoted string. Collision checks are chair spot checks (web searches, Oct 27, 2026), not trademark clearance, and are labelled as such where they matter.

RULING 1: RENAME STEELGRIN. Replacement: IRONMAW (DeepSeek's suggestion; pending Opus confirmation).
Collision check: Steelgrin is a named Warhammer Fantasy Skaven character, verified on the Lexicanum during the rollout audit. Ironmaw shows only fan and tabletop-scale uses (Pathfinder forum characters, an Ironmaw Helm homebrew item, a hero on a small indie game wiki, one unverified low-quality page for a Sword of Convallaria character). No major franchise character. Clearly cleaner than the name it replaces.
Apply at: data.js:221 (the admiral display name); tools/portraits/make_batches.py:49 (plus the species fix below); tools/portraits/crests.py:28; tools/portraits/phone_sheets.py:15; tools/portraits/batches/b1b.json, b1c.json, b1q.json; lore_bible_r8.md:302 (bible example, L lane); godot/story/test/story_test.gd lines 195 and 276 and godot/story/README.md:96 (L lane, per rename map row 493).
Map errata (Opus's call): rename_map_final.md rows 288, 493 and 505 and call V5 at line 520 reference Steelgrin and need updating when the rename lands.
Species fix riding along: the make_batches.py:49 prompt describes Grax as a hulking scarred human space pirate warlord; the ruled species is the furred bear/wolf Hullbreaker form, and the map's P row at line 505 already orders the fix. Same edit, same file.
Not by hand: Godot tables and oracle copies carrying Steelgrin refresh on the G1/G3 re-pins.

RULING 2: STARLIGHT BLURB FIX APPROVED. One line: data.js:127, the Eclipse faction blurb's "stealing starlight" becomes "siphoning stellar energy", per Ryan's energy-not-light ruling. No other location: the sweep found the phrase's story-layer instances in godot/story/outlines.md and outlines_variants.md, which are L Job 2 scope and take the same replacement there.

RULING 3: KEEP SALVAGE SWARM. No change. Recorded so no future pass "fixes" it: Ryan considered the 5c one-meaning stretch and kept the name, with a rename-later-if-it-bothers-me condition.

RULING 4: DROP PLAIN "NADIR" FROM THE ECLIPSE NEMESIS TITLE POOL. One edit: data.js:464, remove the fourth title 'Nadir' from the titles array ['High Nadir', 'Eclipse-prime', 'Archivist', 'Nadir']. Deliberately NOT touched: the Eclipse rank named Nadir at data.js:525 stays; it is the faction's top rank, and the ruling covers only the Nemesis title pool. 'High Nadir' and 'Eclipse-prime' stay as they are; the synthesis records the tensions around both and Ryan ruled only on the plain title.

RULING 5: V1B PROW FLAGGED. No string work. The flag, Ryan's top-vs-side read and the waviness observation went to A4, and the hull surface diagnosis (item 12 pack, contrib/muse/reviews/hull_surface_diagnosis_2026_10_27.md) carries the evidence and the proposed settling check. Nothing in this pack changes for ruling 5.

RULING 6: SWAP THORNBACK AND MOONVEIL OUT OF THE SHIP NAME POOLS.
Apply at: ui3d.js:21 (Thornback, Chorus skirmish pool) and ui3d.js:22 (Moonveil, Glasswright skirmish pool). The Godot fnames copies refresh on the re-pins.
Replacement proposals (chair proposals, not ruled names; Opus confirms or substitutes): Thornback becomes HOOKMAW (no exact-name hits in chair search; fits the Chorus mouth and hunger motif, the Ninefold Maw being their flagship). Moonveil becomes LENSVEIL (no exact-name hits in a search that also covered Starveil and Veilglass; fits the Glasswright optical family of lens, aperture and focus).

ADDENDUM, RULING 7 (Ryan, Oct 28, 2026): SWAP "Acceptable Loss" OUT of the Crusade ship name pool (SHIP_NAMES), the same treatment as ruling 6. Ruled in answer to the text synthesis's question 1. Chair replacement suggestion on record: "Debt Paid", fitting the Crusade debt-keeping voice; proposal only, Opus to take or replace.

RESOLVED SINCE THE PACK WAS COMPILED: the Hunger Below question this pack originally carried (rename_map_final.md line 49 sets 'H-3 Crucible, "the Hunger Below"' as canonical against the full-audit Q7 nickname-only ruling) was answered by Ryan on Oct 28, 2026: the Hunger Below stays in the display name, the map stands, no errata needed on that row. Recorded as an addendum in the rollout synthesis.

APPLICATION ORDER AND OWNERSHIP: rulings 2 and 4 are one-line data edits, safe any time. Ruling 1 spans the B lane (data.js), the P lane (portraits files) and the L lane (bible example, story test and README); the map errata is Opus's call in his own file. Rulings 6 and 7 are pool edits in ui3d.js and data.js. Nothing in this pack authorises hand-editing generated Godot tables; those refresh on the re-pins per the sweep (item 1 pack).
