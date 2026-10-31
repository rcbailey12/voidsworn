# Oracle drift report, Oct 30, 2026

Produced by running `oracle_drift_guard.js` against the clone at `~/workspace/voidsworn-fresh`,
HEAD `cbffcafef9d3bb1c653feb72430f7a125871e315` (the Oct 30, 2026 pin state; the clone's game
files are clean at that HEAD). Guard exit code 0, no errors, and a second run produced a
byte-identical report. This document is the interpretation. The guard output itself is the
facts, and any later run can be diffed against this snapshot.

## Headline

The vendored oracles are honestly pinned and exactly reproducible, and every README claim
about them checks out. The drift is staleness, not corruption: the two parity suites certify
against two different snapshots of the game (Oct 27 for the rules suite, Oct 26 for the
campaign suite), and the live game has since moved past both. The hand-copied constants are
in better shape than the audit feared: the hull tables are exact copies, and the genuinely
divergent tables (BIOMES, PLANETS) are presentation data where the Godot side has visibly
re-authored rather than silently rotted.

## (a) Vendored copies: what differs, and by how much

- core.js: identical in all three places (SHA-256 `05df6a9b140ea1ad`, 37,674 bytes). No drift.
- battle.js: three different copies, all 1,403 lines. Root vs rules oracle: 17 lines added,
  17 removed (34 changed). Root vs campaign oracle: 19 and 19 (38 changed). Rules oracle vs
  campaign oracle: 2 and 2 (4 changed, around lines 474 and 510, the step-7 CHORUS_BITE and
  FEED_CAP changes the rules README itself describes).
- data.js: three different copies. Root vs rules oracle: 196 added, 198 removed (394 changed
  lines of about 697). Root vs campaign oracle: 201 added, 204 removed (405 changed). Rules
  oracle vs campaign oracle: 22 added, 23 removed (45 changed).

The size and shape match the documented history: the campaign pin (Oct 26) predates pass 3
tuning, the rules pin (Oct 27) includes it, and the root files have since taken step 9 tuning
(commit `d551697`) and the step 10 / lore round 8 string pass (commit `90aaf85`), which is why
the data.js gap to root is mostly display strings and rename churn layered over tuning.

## (b) Pin claims: all hold

- Rules oracle: vendored battle.js, data.js and core.js each match the content of those files
  at the claimed pin `cb55ec9` exactly (hash equality against `git show`). The secondary claim
  that core.js is unchanged since `d8b47c6` also holds.
- Campaign oracle: vendored battle.js, data.js, core.js, campaign_run.js, campaign_meta.js and
  ui3d.js each match the claimed pin `d8b47c6` exactly. The single exception is campaign3d.js,
  and it is the README's own disclosed fix: the vendored copy differs from the pin at lines 56
  to 57 only (one line changed, the mid-line comment moved to the end of the line), exactly as
  documented. Counted as a disclosed exception, not a broken claim.
- Two rules-oracle files (fnames.js, campaign_hooks.js) are extracts from other root files, not
  full-file copies, so no file hash can verify them. Unverifiable by this method, flagged as such.
- Summary: 10 file checks against pinned content, 10 held, 0 contradicted.

One fragility sits inside that clean result. The line-56 fix exists only in the vendored
oracle copy; the root campaign3d.js still carries the mid-line comment form the campaign
README flags as a bug (the vendored copy differs from today's root at lines 56 and 58, the
second being a later strings change). The README's catching-up protocol says to re-copy once
the root file is fixed, which covers it, but until the root is fixed the only corrected copy
of that line in the project is a test fixture.

## (c) Constants: exact where it matters, re-authored where it does not

Totals: 120 entries compared, 95 matched, 25 differed, 25 browser-only, 0 godot-only.

Exact copies (zero drift):

- AI_HULLS: 36 of 36 entries matched (`godot/render/hull_table.gd` vs ships3d.js).
- CLS_LEN: 13 of 13 matched.
- FAC3D shared colour fields (win, eng, bolt, beam, shield, six factions): 30 of 30 matched.
- FINISH base hex vs browser FAC3D hull hex: 6 of 6 matched. (FINISH's metal and roughness
  fields are Godot-only by design; there is no browser table to copy them from.)
- ROCK_SET and ROCK_TINT: 9 of 9 matched.

Divergent, with reasons visible in the source:

- BIOMES: 1 of 6 factions matched (hegemony, exact), 5 differed. The Godot values live in the
  `nebula` field of `godot/fx/faction_looks.json`, and that file's loader
  (`godot/fx/faction_look.gd`) declares the JSON the single deliberate source for faction
  looks, with repaints planned. So the battle-sky colours in the port are a rework in
  progress, not a copy that slipped. Presentation only; no rules impact. Worth a sign-off
  look before the effects pass treats either palette as final.
- ROCKS (battle.js ROCK_KINDS `col` vs world.gd ROCKS albedo): all 5 kinds differ, and that is
  expected. The browser value is a tint multiplier, the Godot value is an absolute albedo, and
  the Godot comment records a deliberate darkening (round 10: real asteroids are dark). Same
  table, two quantities. Not drift; the guard keeps the numbers visible in case either side
  changes silently later.
- PLANETS: the messiest table. Neither Godot table is a copy of the browser PLANET_LOOKS.
  `godot/world/world.gd` has 8 entries and every compared field differs in all 8 (the values
  look hand re-derived, darker across the board); entry 7 is also flagged as a gas giant where
  the browser look 7 is an ice world, so the disagreement is semantic, not just numeric.
  `godot/ui/campaign/map3d_system.gd` has a different table again: 7 entries, a kind sequence
  (0, 1, 2, 2, 3, 4, 0) that does not correspond to the browser's eight looks, and an entry 0
  whose first two colours match world.gd's entry 0 while its atmosphere matches neither.
  The browser's per-entry pc and pd fields exist in neither Godot table, and FAC_PLANETS (the
  per-faction planet picks) has no Godot counterpart at all; the world code picks planets by
  biome index into its own table. Presentation only, but anyone expecting the same planet in
  the same biome slot on both builds will not get it, and the two Godot screens (battle world
  and campaign map) do not agree with each other either.
- Browser-only FAC3D fields: per faction, `hull`, `dark`, `trim` and `tip` have no counterpart
  in the Godot hull table (hull is duplicated inside FINISH; dark, trim and tip are simply not
  in hull_table.gd). The `tip` colour is the one to note: if the port needs tip glow colours,
  they are not yet copied anywhere the guard can see.

## Which drifts are real risks to parity certification

1. The two suites certifying different games (the single most important drift). A green
   rules-parity run today attests the port against the game as of Oct 27 (`cb55ec9`); a green
   campaign-parity run attests it against Oct 26 (`d8b47c6`); the two oracles themselves
   differ (battle.js by 4 lines, data.js by 45). Neither attests the live game at HEAD, whose
   data.js is 394 to 405 changed lines away from the oracles. Because the pins are accurate
   and documented, this is a known, bounded staleness, and the fix is procedural: re-pin both
   oracles to one agreed commit before cutover and re-run the golden tests, so that
   "parity certified" names a single game. Until then, any parity claim should carry its pin.
2. The campaign3d.js line-56 fix living only in a test fixture (above). Small, but it is the
   one place where the oracle is more correct than the game it mirrors.
3. Nothing in the constants threatens rules parity. The hull tables that feed the renderer
   are exact. The divergent tables are all presentation (sky, rocks, planets), where the risk
   is visual mismatch at sign-off, not wrong game behaviour.

Benign, on the record: the campaign3d disclosed exception (documented, one line), the ROCKS
quantity change (documented, deliberate), the BIOMES divergence (the JSON is the declared
source going forward), and the oracle-vs-root gaps themselves (the normal consequence of a
pin doing its job mid-sprint).

## Verdict

For the cutover, the drift is manageable and now measurable. The paperwork problem the audit
feared (claims contradicted by files) does not exist: 10 of 10 verifiable pin claims hold.
What exists is a staleness problem with a clean remedy, plus one presentation-table tangle
(PLANETS) that needs an owner decision about which table is canonical. Run the guard before
quoting any parity result; when the re-pin happens, this report's numbers are the before
picture.
