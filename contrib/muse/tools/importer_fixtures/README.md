# Cutover importer test fixtures

Fixtures for building and testing an importer that carries browser saves
into the Godot build. Background: the browser game stores one JSON envelope
at localStorage key `voidsworn.v1`, shaped `{meta, run}` at SAVE_VERSION 2.
The Godot campaign writes a fresh format at `user://voidsworn_campaign.json`
and its code states browser saves are not carried over (campaign.gd, the
persistence section header). The chair saves audit of Oct 29, 2026 found
that without an importer, all META progression and any in-progress run are
lost at cutover. These fixtures are the input/output pairs an importer can
be developed and checked against.

## How they were made

`generate_fixtures.js` builds every save with the game's own constructors
and persistence code (defaultMeta, runDefaults, newShip, genSector,
Persist.saveLocal and Persist.loadLocal from core.js, loaded headlessly
through the harness loader in voidsworn-harness). No fixture JSON was
hand-written. Run it to regenerate:

    node generate_fixtures.js

The script ends with a verification pass: it re-reads every file from disk,
loads each store through a fresh game instance's own loadLocal, checks the
loaded state passes saneSave, and checks it matches the loaded state
recorded in the fixture. All fixtures pass.

## File format

Each fixture file holds some of:

- `store`: the exact localStorage contents as raw strings, keyed by
  `voidsworn.v1` and, where one exists, `voidsworn.v1.bak`. This is the
  importer's input.
- `envelope`: the parsed primary envelope, when it parses.
- `loaded`: what the game's own Persist.loadLocal produces from that store
  in a fresh runtime (migrateMeta, migrateRun and repairRunIds applied).
  This is the state a correct importer should end up carrying.

Fixtures 4 and 5 are pairs: an `_input` file (the store as found) and an
`_output` file (the loaded state, plus what the load did).

## Rules that apply to every fixture

- A run as stored carries no `v` field; migrateRun stamps `v: 2` on load.
  Meta gains the markers `backfilled: 1` and `wonFix41: 1` and an empty
  `stats.wonFacs` on first load. The `loaded` states include these stamps.
- The Godot side mirrors the browser field names (its defaultMeta matches
  the browser one field for field) and ports the same migration, repair and
  sanity functions, so the importer can reuse the same accept and repair
  policy instead of inventing a second one.
- Numbers: the browser envelope is plain JSON. The Godot writer encodes
  non-integer numbers in its own hex string form on save; the importer only
  has to read plain JSON numbers. In practice the float carriers are map
  node geometry (node `y` fractions such as 0.16666666666666666).
- Ids in saves are data ids (h_vanguard, martyr, i_broad), never display
  names. Display names live in the tables on both sides.
- Ship `uid` strings, `run.pos` and `run.curNode` node ids, and
  `run.flagUid` are references inside the run. Preserve them verbatim or
  the flagship link and the map position break.
- Reward offers (`reward.relics`, `reward.boonOffer`, `reward.modOffer`,
  `reward.prizes`) are fixed into the save when the reward is banked, by
  design, so a reload resumes the same choices. The importer carries them
  as data and never re-rolls them.

## 1. fresh.json

Contains: a store with only `voidsworn.v1`. The envelope is a brand-new
meta (renown 0, unlocked {}, admirals {vex: true}, all other containers
empty) and `run: null`. The loaded meta is the same content after
migrateMeta, with the first-load markers added.

Expected importer outcome: produce a new-player Godot profile, default meta
and no run. Nothing to decide. (A fresh Godot profile sets the same two
markers itself, so the two starting states converge.)

## 2. midrun.json

Contains: a developed meta and an in-progress run.

- Meta: renown 130; LEGACY unlocks u_carrier, chest1, vets; admirals vex
  and kassar; one bought hull variant (vs_harrow_t); mastery {kassar: 17,
  vex: 6}; favour {iron: 3}; stats {runs: 4, best: 2, wins: 1}; one fallen
  entry from an earlier run.
- Run: faction hegemony, admiral kassar, sector 2, credits 265, cpCap 13.
  Fleet of five: a vanguard flagship damaged to 155 hp with capacitor and
  gyro modules fitted and a veteran captain (xp 40, rank 1, perks gunnery
  and ironhull), two interdictors (one at full hull, one at 12 hp), a
  picket with prow fitted at 85 percent hull, and a dominion at full hull.
  flagUid points at the flagship. Relics martyr and ledger held; boons
  i_broad (rarity 1) and i_plate; patrons iron and storm; aspect bulwark;
  heat h_flag; unfitted modules regen and auspex in inventory; one fallen
  ship recorded.
- Map: a real genSector(2) map, 7 columns with edges, rolled encounters
  and node rewards. The start node and node 1-0 are done; pos and curNode
  are 1-0.
- Reward: banked mid-choice after an elite win. Stage is relic; the relic
  choice is cogitator or spore; a patron boon offer of three iron boons
  (i_still rarity 1, i_brace rarity 0, i_line rarity 2) is also fixed and
  unmade; rw is {k: 'boon', p: 'iron'}; no prizes or wrecks.
- Nemesis: faction chorus, name Thrumming Throat, traits deadeye and
  regrowth, weaknesses slow and flank with slow already revealed, met
  once, clock 3. (Built field for field after campaign_run.js
  newNemesis, which sits outside the harness's loaded files, with values
  drawn from the data.js NEM_FAC and NEM_WEAK tables.)

Expected importer outcome: full carry, field for field, on both halves:
progression, the fleet with damage, fittings and captains, the map with
position, the banked reward with its fixed offers, and the Nemesis with
its revealed weakness. This is the fixture that proves an importer can
preserve an in-progress run and not just progression; if runs cannot be
carried, this fixture quantifies exactly what a migrating player loses.

## 3. unlocked.json

Contains: the baked-in boot grant. The meta's own history is modest
(renown 60, 3 runs, best sector 1, no wins, variants empty), yet its
unlocked map holds all 12 LEGACY keys and its admirals map holds all 24
admirals. The store also holds `voidsworn.v1.bak`: the same meta one save
earlier, with unlocked {} and admirals {vex: true}. That pair is the
fingerprint of the mechanism. On every boot, main3d.js applies the grant
in memory (both maps filled) unless opts.unlockAll is false; the first
ordinary save after a boot serializes the filled maps, and saveLocal
rotates the pre-grant envelope into the backup slot. The grant is a
testing leftover (confirmed by Ryan on Oct 28, 2026: the game was fully
unlocked originally for testing). None of it was bought; the as-designed
sinks would have cost 1,815 renown.

Expected importer outcome: this fixture is a decision, not a mapping.
The options:

- Import as-is: migrated players keep every doctrine and admiral, and
  the progression redesign is moot for them. Because any browser save
  written after one boot and one save carries the grant, that is close
  to every migrating player.
- Detect and strip: the signature is unlocked covering all LEGACY keys
  and admirals covering the whole roster while variants is empty and
  lifetime stats cannot support the spend. Strip unlocked and admirals
  back to what the meta history supports (for this fixture: no doctrine
  unlocks, admirals back to {vex: true}) and let the player earn under
  the new progression.
- Import as-is but flag the profile, so a later ruling can act on
  exactly the set of granted profiles.

Whichever option is ruled, the importer is the last clean place to apply
it, and the .bak pair in this fixture lets a test confirm the detection
distinguishes a granted unlock from an earned one.

## 4. repaired_input.json and repaired_output.json

Contains: one envelope that is structurally sound (it passes saneSave)
but seeded with unknown ids and two corrupt values, written to the store
raw. The output file is what loadLocal made of it.

Removed ids (10, enumerated in the output file's droppedIds): relic
zzz_relic, reward-offer relic zzz_relic2, boon zzz_boon, patron
zzz_patron, inventory refit zzz_mod, ship refit zzz_mod2, captain perk
zzz_perk, heat zzz_heat, the ship hull zzz_hull (the whole ship is
dropped, shipsDropped 1), and the reward prize hull zzz_prize.

Repairs and resets: the output run's repair list holds 12 entries.
Admiral zzz_admiral was reset to vex, the first admiral of the run's
faction in the table. Aspect zzz_aspect was set to null. Credits, stored
as the string "lots", were reset to 0. Two changes are silent (not in the
repair list): giftBoon zzz_gift was set to null, and reward stage
"banana" was reset to promo; the prize list was emptied without a repair
entry. The store afterwards holds the raw input preserved at
`voidsworn.v1.repaired`, the browser's write-once audit copy.

Expected importer outcome: apply the same repair policy the Godot port
already implements (repairRunIds exists in campaign.gd), import the
repaired state, never import an id that is not in the Godot tables, keep
the raw pre-repair envelope, and surface the repair list to the player
the way the browser's Continue screen does. Note the asymmetry an
importer must not miss: meta ids get no repair pass on either side; only
run ids are validated.

## 5. corrupt_input.json and corrupt_output.json

Contains: a primary envelope truncated at 2,141 of 3,893 characters
(mid-string, unparseable), with `voidsworn.v1.bak` holding the previous
save intact: renown 75, a sector 1 run with two ships and 120 credits.
The output shows loadLocal recovering from the backup (recovered true);
the loaded state is that older save, migrated. The later save (renown
140, 480 credits, 3 battles fought) is unrecoverable and gone. The load
does not rewrite storage: the truncated primary and the good backup both
remain in place, and the next saveLocal will not rotate the truncated
primary into the backup slot (it only rotates values that parse), so the
good backup survives until a second new save replaces it.

Expected importer outcome: mirror the browser fallback semantics. A
damaged primary falls back to the backup one save behind; the cost is
exactly one save of progress, the same cost the browser player would
have paid. If both copies are unusable, keep whichever half (meta or
run) is sound, per saneSave, saneMeta and saneRun. Report that a
recovery happened rather than presenting the rolled-back state as
current.

## Using the fixtures

Point the importer at a fixture's `store` object as its localStorage
input and compare its result against `loaded` (or the `_output` file for
the pairs). A pass is an exact field-for-field match after the Godot
side's own migration stamps, except where fixture 3's decision says
otherwise.
