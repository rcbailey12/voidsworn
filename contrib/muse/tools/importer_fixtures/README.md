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
through the harness loader in voidsworn-harness). Two fixtures also run
game code from the campaign files the harness does not load: fixture 17
calls endRun itself (campaign_meta.js, with tel and runRenown extracted
from campaign3d.js), and the wreck yields in fixtures 10 and 11 are
computed by salvageYield (campaign_run.js). No fixture JSON was
hand-written. Run it to regenerate:

    node generate_fixtures.js

The script ends with a verification pass: it re-reads every file from disk,
loads each store through a fresh game instance's own loadLocal, checks the
loaded state passes saneSave, checks it matches the loaded state
recorded in the fixture, and asserts the fixture-specific behaviors the
sections below describe (the repair input passing saneSave, the corrupt
fixture's second-save backup behavior, the 0 hp clamp in fixture 15, and
more). All fixtures pass.

Fixtures 1 to 5 are the original set. Fixtures 6 to 21 were added in a
second pass answering two gap-check legs on the original set (DeepSeek
filed; Qwen's list merged into the same pass).

## File format

Each fixture file holds some of:

- `store`: the exact localStorage contents as raw strings, keyed by
  `voidsworn.v1` and, where one exists, `voidsworn.v1.bak`. This is the
  importer's input.
- `envelope`: the parsed primary envelope, when it parses.
- `loaded`: what the game's own Persist.loadLocal produces from that store
  in a fresh runtime (migrateMeta, migrateRun and repairRunIds applied).
  This is the state a correct importer should end up carrying.

Fixtures 4, 5 and 18 are pairs: an `_input` file (the store as found) and
an `_output` file (the loaded state, plus what the load did).

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
  once, clock 3. (Assembled field by field in the generator, because
  newNemesis lives in campaign_run.js, outside the harness loader's
  files; the construction follows that function against the data.js
  NEM_FAC and NEM_WEAK tables. The name, traits and weaknesses are
  pinned to the values named here, so the fixture cannot drift if the
  seeded draws or table order change.)

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

Contains: one envelope that is structurally sound but seeded with
unknown ids and two corrupt values, written to the store raw. The output
file is what loadLocal made of it. Verified explicitly, in the generator
and again in its verification pass: the raw input envelope passes
saneSave (the output file records this as inputPassesSaneSave), so the
load takes the repair path, not the backup-fallback path.

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
run) is sound, per saneSave, saneMeta and saneRun (fixtures 18 to 20 pin
those shapes). Report that a recovery happened rather than presenting
the rolled-back state as current.

The rotation claim above is now asserted, not just reasoned: the
generator performs one saveLocal from the recovered state and records
the result in the output file's secondSave field (the good backup is
unchanged and the new primary parses), and the verification pass
re-derives the same behavior from the input store.

## 6. partial_grant.json

Contains: fixture 3's boot grant on top of a profile with genuinely
earned content, so detection can be tested against a mixed profile. The
history is real play: renown 210, 7 runs, 1 win (hegemony), mastery
{kassar: 23, sable: 9}, favour {iron: 5, storm: 2}, two fallen entries,
three earned LEGACY unlocks (chest1, vets, u_carrier), three earned
admirals (vex, kassar, sable) and two bought variants (vs_harrow_t,
c_reaver_t). On top of that sits the full grant: all 12 LEGACY keys and
all 24 admirals. An in-progress sector 1 voidsworn run rides along
(three starter ships, two battles fought, a fresh Nemesis not yet met).
The `.bak` slot holds the earned envelope from before the granting boot:
the same meta with only the three earned unlocks and three admirals.

Expected importer outcome: whichever way fixture 3's decision goes, this
is the fixture that tests it. A detection that only checks "everything
unlocked" fires here too, but a blanket strip back to defaults would
wrongly delete the earned unlocks, both variants and the win. The `.bak`
pair is the ground truth for what was earned; the variants are untouched
by the grant in both copies.

## 7. longlived_meta.json

Contains: a veteran profile with no run in progress. Renown 460; 8 of 12
LEGACY unlocks (u_carrier, u_battleship, chest1, chest2, cmd1, vets,
founder, wrights); 9 admirals; 5 bought variants (vs_harrow_t,
c_reaver_t, h_vanguard_g, b_spitter_s, i_wisp_l); mastery spread over 8
admirals (8 to 64); favour spread over all six patrons (2 to 15); stats
{runs: 16, best: 3, wins: 3} with wonFacs voidsworn, corsair and chorus;
heatBest {voidsworn: 2, corsair: 1}; six fallen entries across four
factions and all three sectors.

Expected importer outcome: full carry of every meta container, including
the ones a shallow importer might skip (heatBest, favour, fallen). The
unlocks are partial, so the fixture 3 signature does not trip and no
decision is needed; this is the depth test for the meta half, and the
counterpart to fixture 2's run depth.

## 8. early_run.json

Contains: a sector 1 run at its first moment. Vex's three starter ships
(penitent, harrow, warden) at full hull, credits 120, cpCap 10, a fresh
genSector(1) map with nothing done, pos on the start node, curNode null,
all run stats zero, and a meta that records exactly one run started. The
two fields that are the point: `reward` is null and `nem` is null.

Construction note: reward null is the value the reward chain itself
leaves behind when a chain completes (campaign_run.js afterBattle sets
RUN.reward to null); before the first battle the key is simply absent,
which loads identically, and this fixture stores the null explicitly.
For nem: the current build creates the Nemesis at run start, but the
field's own default in runDefaults is null and the campaign creates him
lazily on demand (ensureNemesis), so any save written before he exists
loads with nem null. The fixture pins that null shape directly.

Expected importer outcome: carry the run as a just-started run. A null
reward means no banked reward and a null nem means no Nemesis yet; both
are ordinary states, not corruption, and neither should trip a repair or
a rejection.

## 9. reward_mod.json

Contains: a hegemony sector 2 run parked on a banked refit offer after
an event node. The reward's stage is `pick`, its rw is {k: 'mod'}, and
modOffer holds three module ids (prow, auspex, drive) drawn from the
game's own modulePool for this fleet.

Note for the importer: there is no 'mod' stage value in the game. A
refit offer lives at stage 'pick' with rw.k 'mod' and the offer banked
in modOffer when the screen is first shown; repairRunIds accepts only
the stage values prize, salvage, pick, relic and promo, and resets any
other string to 'promo' (fixture 4 shows a 'banana' stage becoming
'promo'). An importer that looks for a 'mod' stage will never find one.

Expected importer outcome: carry the reward at stage 'pick' with its
banked modOffer verbatim, so a resumed game shows the same three
modules.

## 10. reward_prize.json

Contains: a corsair sector 2 run parked at the prize stage after a
battle. Two captured ships await a decision, recorded field for field as
campaign3d.js records them: a reaver at 72 percent hull and a hegemony
interdictor at 35 percent, each with name, faction, weapon kinds,
ability, shields and cp. prizeSel holds ['strip']: the first prize has
already been marked for stripping, and those picks are saved in the
reward by design. Behind the prizes sits one wreck, a raider destroyed
by blast, whose yield was computed by the game's own salvageYield
(module loaders, 19 credits, tow offered, since the run is corsair and
the wreck is a small home-faction hull). rw {k: 'boon', p: 'ember'} and
the salvage step still wait behind the prize stage.

Expected importer outcome: carry the prizes, the recorded prizeSel pick
and the wreck with its fixed yield. Never recompute the yield and never
re-roll the prizes; both were fixed when the reward was banked.

## 11. reward_salvage.json

Contains: a corsair sector 1 run parked at the salvage stage, two wrecks
and no prizes. The first wreck is intact: an interdictor destroyed by
blast, yield module loaders and 28 credits, tow not offered (the tow
rule's own checks decline it). The second is scrap: a raider destroyed
by flay, which the salvage rules treat as unmade, so its yield is
credits only at the scrap rate (25 credits) and its module is null.
Both yields were computed by the game's own salvageYield.

Expected importer outcome: carry both wrecks with their fixed yields,
including the null module on the scrap wreck. Together with fixtures 2,
9, 10 and 12, every stage value repairRunIds accepts (relic, pick,
prize, salvage, promo) now has a fixture.

## 12. reward_promo.json

Contains: a hegemony sector 2 run at the last stage of an elite reward
chain. The relic step is already done: the taken relic (ledger) sits in
run.relics and the reward's relics list is empty. There are no prizes or
wrecks, boonOffer and modOffer are null, and the chain is parked at
stage 'promo', where the resume flow runs captain promotions. The
flagship's captain makes the stage matter: xp 55, rank 1, one unspent
promotion point in cap.pending.

Expected importer outcome: carry the reward at stage 'promo' and the
captain's pending point, so the promotion the player was about to make
is still waiting after migration.

## 13. meta_junk.json

Contains: a modest meta (renown 95, 3 runs, best sector 2, one fallen
entry) seeded with an unknown id in every meta container: unlocked
zzz_legacy, admirals zzz_admiral, variants zzz_variant, mastery
zzz_admiral at 40, favour zzz_patron at 9, heatBest zzz_heat at 2. The
loaded state keeps every one of them, next to the real ids (chest1, vex,
vs_harrow_t, iron, voidsworn).

Expected importer outcome: this fixture pins the asymmetry fixture 4
names. Meta ids get no repair pass on either side: migrateMeta never
validates them, so the browser keeps them and the Godot port's
migrateMeta keeps them too. The importer must make its own policy call
here: carry them (they are inert while no table uses the id, but they
would resurrect if a future build reused the id) or drop ids its own
tables do not know. What it must not do is assume the browser already
cleaned them.

## 14. nemesis_late.json

Contains: a hegemony sector 3 run (four ships, position in the third
column, battles 12, elites 3, bosses 2) whose Nemesis is deep into his
arc. He is Eclipse (data id deathless), and his late state is the point:
beaten 2, met 3, scars 2 with scarKinds blast and flay, epithets the
Twice-Dead and Hollow-Eye drawn from the faction's scarBy pools for
those causes (current epithet Hollow-Eye), both weaknesses (flank, ion)
revealed, adaptations pd plus the faction special legion (within the
sector cap), signatures tithe, revive, tithe, clock 2, last_beat torp,
revived true.

Construction note: assembled field by field in this generator, like
fixture 2, because newNemesis lives in campaign_run.js, outside the
harness loader's files; the late-state values are the ones the game's
own nemAdapt, nemScar and nemSignature machinery produces.

Expected importer outcome: full carry of the Nemesis object, including
the fields an importer built against fresh saves might default away
(scars, epithets, signatures, revived, last_beat). A Nemesis who resets
at cutover loses two sectors of history the player earned.

## 15. fleet_edges.json

Contains: a voidsworn sector 3 run whose fleet fills the command point
cap exactly: 16 ships, every one cp 1 (mostly wardens, with captured
raider, drone, wisp, scythe and picket hulls mixed in, the way prizes
join a fleet), against cpCap 16. There is no ship-count cap anywhere in
the code; command points are the only bound, so 16 is the largest fleet
this cpCap admits. The corners: the sixth ship is stored at hp 0; one
ship sits at 40 percent hull; flagUid points at the fourth ship, not the
first; and the second ship's captain holds xp 30 with 2 unspent
promotion points.

What the load does with the 0 hp ship is part of the fixture:
repairRunIds sets a non-positive or non-numeric hp to 1 rather than
dropping the ship, so the loaded fleet still has 16 ships and that ship
is at 1 hp.

Expected importer outcome: carry all 16 ships in order, preserve flagUid
and the pending points, and either reproduce the hp clamp or document a
different ruling for a ship stored at 0 hp. Do not impose a ship-count
limit the game does not have.

## 16. sector3_run.json

Contains: a chorus run in sector 3, mid-map: five ships (brood flagship,
spitter, razor, two drones), credits 260, cpCap 16, relic spore held,
a regen module in inventory, heat h_flag, the start node and one battle
in each of the second and third columns done, pos on the third column
node, stats {battles: 11, elites: 3, bosses: 2, kills: 70, lost: 3}, and
a meta with 8 runs, a win and hunger favour 8. Its Nemesis (Eclipse,
data id deathless) is mid-arc: beaten once, scarred once (scarKind cut,
epithet the Twice-Dead from his own faction's pools), one weakness
revealed, one adaptation in place (legion, his faction special), one
tithe signature on record.

Expected importer outcome: full carry, the sector 3 counterpart to
fixture 2's sector 2 carry: a developed map in the final sector, a
swarm-faction fleet, and a Nemesis partway through his adaptation arc.

## 17. settled_run.json

Contains: the state the game actually stores at the win boundary,
produced by calling the game's own endRun(true) inside the generator
(campaign_meta.js loaded with DOM stubs; tel and runRenown extracted
from campaign3d.js; a pinned clock so the stamps are reproducible). The
run that ended was a corsair sector 3 run: sable, 14 battles, 4 elites,
3 bosses, 88 kills, heat h_flag, one fallen captain. The primary
envelope holds the folded meta and `run: null`: renown 200 became 333
(runRenown 121 for those stats, times the 1.1 heat multiplier h_flag
carries, rounded), wins 1 became 2, wonFacs gained corsair, the fallen
captain was appended to meta.fallen, mastery for sable went from 20 to
67 (battles, elites and bosses, plus 10 for the victory), heatBest
gained corsair 1, and a run_end entry sits in meta.tel. The `.bak` slot
holds the pre-end save, the same run still in progress, and the file's
preEndRun field repeats that run for convenience.

Not constructible: a stored envelope holding the finished run with its
results not yet folded into meta. endRun folds the results, nulls the
saved run and saves in the same call, and saveRun refuses to snapshot a
run whose over flag is set, so no save path the game has produces that
state, and this set does not hand-forge it. If an importer ever met one
(a hand-edited or partially written save), it would have to choose
between folding the results itself and discarding the run; the game
offers no precedent.

Expected importer outcome: import the folded meta and no run, and do not
fold anything a second time. The pre-end backup is the only place the
finished run still exists.

## 18. corrupt2_input.json and corrupt2_output.json

Contains: fixture 5's setup with both copies damaged: the primary
truncated at 45 percent of its length and the `.bak` at 30 percent, so
neither parses. The output records the boot state loadLocal is left
with: the untouched default meta (no first-load markers, because
migrateMeta never runs), no run, recovered false. Total loss, exactly
what the browser player would face.

Expected importer outcome: produce a new-player profile and report the
total loss of the old one rather than inventing a partial recovery.
Once parsing fails on both copies there is no sound half to keep; the
per-half salvage in fixtures 19 and 20 only engages when the envelope
itself parses.

## 19. half_meta.json

Contains: an envelope that parses, whose meta half is sound (renown
175, admirals vex and kassar, mastery {vex: 20}, a hegemony win) but
whose run half is not a sane run (fleet is the string 'broken', map is
null), with no backup. The loaded state keeps the meta, migrated with
its first-load markers, and drops the run to null.

Expected importer outcome: carry the meta, start the player with no run,
and report that the run half was unsalvageable. This is the browser's
own per-half rule (saneSave, saneMeta, saneRun) applied to an envelope
that parses.

## 20. half_run.json

Contains: the mirror image. An envelope that parses, whose run half is
a sound sector 1 run (two ships, a real genSector(1) map) but whose meta
half is not a sane meta (unlocked is an array, not an object), with no
backup. The loaded state keeps the run, migrated, and leaves the boot
default meta in place of the dropped one (the untouched default, again
without first-load markers, because migrateMeta never runs on it).

Expected importer outcome: carry the run and give the player a default
meta, and surface the meta loss rather than presenting the run as a new
player's. Losing progression while keeping a run is the stranger of the
two half outcomes, and a player will want to know it happened.

## 21. absent_store.json

Contains: an empty store. Neither `voidsworn.v1` nor its `.bak` exists,
as on a first launch or after site storage was cleared. loadLocal is a
no-op against it; the recorded loaded state is the boot default meta
(without first-load markers, since migrateMeta never runs) and no run.

Expected importer outcome: the same as fixture 1, a new-player profile.
The difference from fresh.json is only in what the store holds (nothing
at all, against a saved default envelope); both should be treated as no
save to carry.

## Using the fixtures

Point the importer at a fixture's `store` object as its localStorage
input and compare its result against `loaded` (or the `_output` file for
the pairs). A pass is an exact field-for-field match after the Godot
side's own migration stamps, except where fixture 3's decision says
otherwise.
