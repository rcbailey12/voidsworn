<!-- Chair filing note: Qwen returned TWO parallel complete responses to this leg; both are filed in full below (Response 1, then Response 2) and neither was selected, per standing practice. Em dashes normalized to hyphens. -->

## Response 1

FIXTURES HAVE GAPS

Missing cases

meta_history | A long-lived META with many fallen-crew entries accumulated over several runs, non-empty stats.wonFacs, mastery/favour spread across several admirals and patrons, and earned variants/unlocks alongside lifetime spend | An importer that carries only the last fallen entry, treats the containers as single-valued, or recomputes lifetime counters from the current run silently erases progression history.

settled_run | A finished run at the win/defeat boundary - sector cleared or fleet destroyed, reward/cap increment still pending, run about to be nulled and its results folded into META | The importer either imports a dead run as playable, double-applies the end-of-run sink/reward, or drops the win before META has recorded it.

options | Persisted boot/options state (opts.unlockAll true and false, plus any user settings kept outside the {meta, run} envelope) | An envelope-only import drops preferences, and unlock-stripping cannot distinguish a granted profile from a player who turned the boot grant off.

first_launch | A store with neither voidsworn.v1 nor .bak, and half-saves where only META or only RUN is sound | "Fresh" is actually a written default save; an importer may assume the primary key exists or discard a salvageable half instead of producing a default profile.

fleet_edges | Fleet at cpCap/maximum ship count, a sole surviving ship, a listed ship at 0 hp or above derived max hp, captains with pending points or max rank, and repeated/recycled uids | Cap validation or an index-based flagship assumption drops legal ships, breaks flagUid, or loses captain upgrade state that the five-ship, flagship-first fixture never reaches.

reward_stages | Banked rewards at every stage (boon, mod, prize/wreck, promo), with modOffer, wrecks and valid prizes populated, rw kinds other than boon, and a choice taken but the stage not yet advanced | An importer that hard-codes the single relic stage with modOffer: null and empty prize/wreck lists drops fixed offers or re-rolls/re-pays a reward the player already partly took.

sector_edge | Partially and fully cleared maps: last column reached, non-battle node types (dock, elite, boss, event/shop/rest), branch/dead-end edges, pos/curNode on an unentered node, sector-clear cpCap bump pending | Position and completion are carried only for one early battle node here; an importer can mis-map the player, re-roll a completed sector, or lose the cap increase.

nemesis_late | An evolved Nemesis: beaten > 0, scars/scarKinds, epithets and active epithet, non-empty adapt/signatures/seen, held ship, gloat, honed, revived/dead/strike, clock 0, both weaknesses revealed | The fixture only shows a first-meeting Nemesis with empty optional fields and nulls; nested late-game state and null-versus-absent handling can be dropped or reset.

meta_repair | Unknown or retired ids inside META (unlocked, admirals, variants, mastery, favour, fallen ship references), and pre-v2/partially missing envelopes needing migrateMeta/migrateRun | Only run ids are repaired, and no fixture exercises the meta side or an actual older-version migration, so the importer may invent a second repair policy or choke on fields the browser would have backfilled.

both_corrupt | Primary and .bak both unusable, missing .bak, a primary that parses but fails saneSave, wrong envelope shape or unknown SAVE_VERSION | The README's "keep whichever half is sound" fallback and version/shape rejection are entirely untested; an importer may throw, accept garbage, or discard a recoverable META.

Weak cases

- midrun - The flagship is fleet[0] and flagUid points at it, so uid-based linkage versus a positional assumption is never distinguished. The README's "bought hull variant vs_harrow_t" is not pinned by the generator, which takes the first non-arc key in HULL_VARIANTS; nothing actually buys it with renown. The Nemesis is re-implemented field-by-field in the generator because newNemesis is outside the loaded harness files, so "field for field from campaign_run.js" and legal trait/weakness pairing are asserted, not exercised.
- unlocked - The generator runs the two grant loops itself; it never boots main3d.js or sets opts.unlockAll, so the documented guard and the off branch are not exercised. There is no earned-full-unlock negative control for the proposed strip heuristic, and the grant is never carried alongside an in-progress run.
- repaired - The README's claim that the raw input "passes saneSave" is never checked: verify() calls saneSave only on the loaded output. The .repaired write-once audit copy is snapshotted but no second load/save is performed, and the silent changes (giftBoon, reward.stage, emptied prizes) are hard-coded prose in silentlyChanged rather than derived and asserted.
- corrupt - Only good-backup recovery is generated. The both-unusable/half-salvage rule, absent backup, and the claim that a subsequent saveLocal will not rotate the truncated primary are not exercised: nothing saves after recovery, and nothing asserts the store was left untouched.
- fresh - None as a default-meta case, though it models a save that has already been written, not a true absent-store first launch (see Missing cases).

Not checked

- The emitted fixture JSON files are not supplied. Every concrete value - 155 hp flagship, vs_harrow_t, "Thrumming Throat"/chorus traits, seven map columns, node id 1-0, 12 repair entries, 10 dropped ids, promo stage, 2,141-of-3,893 truncation - is a claim about runtime output that the fixed seeds alone cannot establish without the game tables.
- The browser sources (data.js, core.js, battle.js, campaign_run.js, main3d.js) and the harness loader are absent. migrateMeta, migrateRun, repairRunIds, saneSave/saneMeta/saneRun, newShip/genSector defaults, NEM_FAC/NEM_WEAK, the marker stamps and the backup-rotation implementation cannot be inspected.
- The Godot side is absent: campaign.gd, its defaultMeta, its ported repair/sanity functions and its hex-number writer/reader. Field-for-field parity, marker convergence and float-geometry round-tripping are unverified.
- No importer implementation or importer-vs-loaded comparison exists here. The generator's final pass only proves each store loads through the browser's own loadLocal without throwing and passes saneSave; "All fixtures pass" is not evidence about the Godot importer, and there are no negative tests.
- Persistence side effects over time are unobserved: storage after a second save, write-once behaviour of .repaired, backup rotation with an unparseable primary, and fidelity of the harness's Map store to real localStorage.
- Real-save reachability and policy are unverified: whether long-lived metas, late-stage Nemesis states and earned full unlocks occur in the player base; whether the boot grant really contaminates "close to every" save; and the unresolved ruling on import-as-is versus strip versus flag (including the cited audit and Ryan's confirmation).

## Response 2

FIXTURES HAVE GAPS

Missing cases

settings / options blob | A long-lived save carries player settings (audio volumes, difficulty, UI preferences, keybinds) alongside or inside the envelope | No fixture contains a settings key, so the importer has no example to decide carry-vs-drop; it will silently lose them or reject the envelope as an unknown shape.

fleet at size cap | A run whose fleet array is at the game's maximum ship count (e.g. 6 or 8 hulls) | The midrun has 5 ships; if the importer or Godot UI hard-codes an array size assumption from the fixture, it will truncate or reject a full fleet at the cap.

genuine SAVE_VERSION 1 envelope | A real v:1 save whose meta and run shapes actually differ from v:2, requiring migrateMeta / migrateRun to restructure fields rather than just stamp v: 2 | Every fixture is written by current-version code, so the migration path is exercised only as a no-op stamp; a true v:1 to v:2 reshape is never tested and the importer could skip or mis-order real migration steps.

reward stages beyond 'relic' | A banked reward at the mod-offer stage (modOffer populated), a prize stage with captured-hull entries, or a fully completed reward (stage 'done' / null) | The midrun covers only stage 'relic'; the importer could drop or mis-map modOffer and prizes arrays it has never seen populated, or fail to recognise a terminal stage.

run with no Nemesis (run.nem null) | A sector-1 run early enough that the Nemesis has not yet been generated, so run.nem is null or absent | The importer may assume run.nem is always a populated object and throw a null-reference or import a garbage Nemesis into the Godot save.

meta containing junk or stale ids | A meta whose unlocked or admirals maps reference ids not present in the Godot tables (renamed, modded, or removed between versions) | The README and generator confirm meta ids receive no repair pass on either side; with no fixture showing this, the importer has no guidance and could carry broken references into the Godot profile.

both primary and backup unusable | localStorage holds a truncated primary AND a truncated or missing .bak, so neither envelope parses | The corrupt fixture always has a good fallback; the importer's saneSave / saneMeta / saneRun partial-recovery path (keep whichever half is sound) is never exercised.

sector 3+ / late-sector run | A run in sector 3 or beyond with a wider map, more columns, higher cpCap, and a larger foes table | Only sectors 1 and 2 appear; the importer could assume sector-2 map dimensions or cpCap ceilings and mis-handle larger structures.

destroyed or 0-hp ship in fleet | A fleet member at 0 hp or flagged dead/sunk after a battle, still present in the fleet array | All midrun ships are damaged but alive; the importer might import a 0-hp ship as a valid combatant or crash on a state it expects to be filtered out.

deep meta history | A meta with many fallen entries (10+), high stats.runs (50+), multiple stats.wonFacs entries, and several purchased variants | The fixtures carry at most one fallen entry and four runs; array handling, Godot-side history display, and any per-entry validation are untested at realistic long-play sizes.

Weak cases

None. Each fixture exercises what its name claims: fresh is a default meta with no run; midrun carries a sector-2 run with fleet, map, relics, boons, a banked reward, and a Nemesis; unlocked replays the boot-grant sequence and preserves the pre-grant .bak; repaired seeds unknown ids and type corruption and records the game's own repair output; corrupt truncates the primary and demonstrates backup recovery. The reward object and Nemesis in midrun are assembled by hand because campaign_run.js sits outside the harness, but the resulting state passes loadLocal and saneSave in the verification pass, so the fixture still exercises the importer-facing shape it claims to represent.

Not checked

- Actual game-code behaviour behind the harness. The generator calls loadGame(REPO) and evaluates expressions in a vm sandbox, but campaign_run.js (which owns newNemesis, reward-granting, and sector-progression logic) is explicitly outside the loaded files. The Nemesis and reward objects are replicated by hand in the generator; a drift between the generator's field list and the live game code would not be caught by anything in these files.
- saneSave / saneMeta / saneRun validation coverage. The verification pass calls saneSave on the loaded state, but the source of those functions is not in the fixture files. Whether they actually reject the edge states listed under Missing cases (0-hp ships, junk meta ids, both-corrupt stores) cannot be confirmed here.
- Godot-side parity. The README states the Godot defaultMeta matches the browser one field-for-field and that repairRunIds exists in campaign.gd, but neither the Godot source nor its persistence format is included. Field-name drift, the hex-float encoding the Godot writer uses, and the Godot migration stamps cannot be cross-checked against the browser fixtures from these files alone.
- Determinism of the Nemesis and map rolls. The generator seeds rndSeed per fixture, but whether the harness's PRNG is identical across Node versions and platforms (and therefore whether the loaded snapshots in the fixture files remain byte-stable) is not verifiable from the README or generator.
- localStorage concurrency and quota behaviour. The fixtures model a single synchronous write/read cycle. Real browser storage can have concurrent-tab writes, partial flushes, or quota-eviction artifacts; none of those are represented or testable from these files.
