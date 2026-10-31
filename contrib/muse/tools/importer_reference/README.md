# Importer reference converter

**This is a reference implementation, not the shipping importer.** The
shipping importer is Opus's to build on the Godot side. This converter
exists so he can port tested behavior instead of a spec: every rule below
is exercised against the fixtures in `../importer_fixtures/` by
`run_tests.js`, and the outputs match the fixtures' recorded loaded
states field for field except where a documented policy in this README
says otherwise.

The problem it addresses: the Godot cutover loses browser progression
unless an importer carries the browser save (localStorage key
`voidsworn.v1`, SAVE_VERSION 2) into the desktop build. The red team
audit added three findings the converter is built around:

- No browser-to-desktop transport exists. This converter takes the store
  as given (see Input); moving the bytes is a separate, unsolved piece.
- Imported META carries the `unlockAll` boot grant (main3d.js fills
  `meta.unlocked` and `meta.admirals` in memory on every boot, and the
  next save serializes the filled maps), so migrated profiles would
  arrive fully unlocked. The converter makes that a named decision point
  (see Options), not an accident.
- The browser's own load path drops and repairs ids silently in places
  (giftBoon, reward stage resets, emptied prize lists). The converter's
  drop report names every one of them anyway (see The accounting rule).

## Files

- `converter.js`: the converter. Node, no dependencies beyond `fs`,
  `path`, `vm`. Library (`convert(store, options)`) plus a small CLI.
- `run_tests.js`: the fixture test runner, including the independent
  accounting check.
- This README.

## Method

The converter does not reimplement the browser's load policy. It loads
the game's own `data.js` and `core.js` headlessly from a checkout
(`--game-dir`, or `VOIDSWORN_GAME_DIR`, defaulting to
`~/workspace/voidsworn-fresh`) and runs the game's own
`Persist.loadLocal` against the supplied store, the same way the
fixture generator produced the fixtures' `loaded` states. Migration
(`migrateMeta`, `migrateRun`) and repair (`repairRunIds`) behavior
therefore cannot drift from the browser's, and the Godot side already
ports the same functions, so the policy ports once, consistently.

On top of the loaded state the converter applies its own policy layer
(boot grant, meta unknown ids, reward safe point) and builds the report
from an explicit recursive diff of the selected source envelope against
the final output. Because the report comes from the diff, changes the
game's repair pass makes without listing them are still named.

## Input

A store object: raw localStorage strings keyed by full storage key.

```json
{
  "voidsworn.v1": "{\"meta\": {...}, \"run\": {...}}",
  "voidsworn.v1.bak": "{\"meta\": {...}, \"run\": {...}}",
  "voidsworn.v1.repaired": "{\"meta\": {...}, \"run\": {...}}"
}
```

Only `voidsworn.v1` is required; `.bak` and `.repaired` are used when
present. The CLI also accepts a fixture file directly (it reads the
file's `store` field).

Source selection mirrors `Persist.loadLocal`, in order:

1. Primary parses and passes `saneSave`: use it.
2. Else the backup parses and passes `saneSave`: use it, and report the
   recovery (the state is one save behind, the same cost the browser
   player would pay).
3. Else the primary parses to an object: per-half salvage. A half that
   fails `saneMeta` or `saneRun` is dropped whole, reported as one
   `dropped-half` entry with the half's full id inventory in
   `detail.ids`; the sound half is kept.
4. Else the `.repaired` audit copy parses and passes `saneSave`: the
   converter recovers from it and reports that it did. **The browser
   never loads this copy.** This is a converter policy, listed under
   Open decisions.
5. Else, if any copy existed: total loss, reported as a `total-loss`
   entry and a new-player profile. If nothing was stored at all: a
   new-player profile, reported as no save found.

## The portable desktop save

```json
{
  "format": "voidsworn-desktop-save",
  "formatVersion": 1,
  "sourceSaveVersion": 2,
  "meta": { "...": "the migrated meta, field names identical to the browser meta" },
  "run": { "...": "the migrated run, or null" },
  "provenance": {
    "convertedBy": "contrib/muse/tools/importer_reference/converter.js",
    "referenceImplementation": true,
    "source": "primary | backup | primary-salvaged | repaired-copy | none | none-total-loss",
    "recoveredFromBackup": false,
    "grantMode": "strip | keep",
    "metaUnknownMode": "drop | carry"
  }
}
```

Shape rules:

- `meta` and `run` keep the browser field names verbatim (the Godot
  `defaultMeta` already mirrors them field for field). Every field the
  fixtures exercise is carried, including the deep ones shallow
  importers skip: `heatBest`, `favour`, `fallen`, the Nemesis object's
  scars, epithets, signatures and `revived`, banked reward offers,
  captain `pending` promotion points, and the run's `_repairs` list.
- References inside the run (`uid`s, `flagUid`, `pos`, `curNode`) are
  preserved verbatim; renumbering them breaks the flagship link and the
  map position.
- Numbers are plain JSON numbers. The Godot writer's hex float encoding
  is a save-time concern of the desktop build, not of this shape.
- `run` is `null` when there is no run to carry, including the settled
  post-`endRun` state: results are already folded into the meta and the
  converter never folds them a second time.

## The import drop report

```json
{
  "header": {
    "source": { "kind": "...", "recovered": false, "notes": ["..."] },
    "grant": { "signatureDetected": true, "mode": "strip", "strippedIds": ["..."], "baseline": "..." },
    "metaUnknownIds": { "mode": "drop", "droppedIds": ["..."] },
    "safePoint": { "inputStage": "relic", "emittedStage": "relic", "skipped": [] }
  },
  "counts": { "dropped": 0, "altered": 0, "added": 0, "stripped": 0, "skippedStages": 0, "halvesDropped": 0, "notes": 0 },
  "entries": [
    { "action": "dropped", "stage": "load", "path": "run.relics", "id": "zzz_relic", "reason": "..." }
  ]
}
```

Entry actions: `dropped`, `altered`, `added` (the load diff),
`stripped` (grant policy), `skipped-stage` (reward safe point),
`dropped-half` (per-half salvage), `total-loss`, `source-note`. Every
entry carries a human-readable `reason`. `stage` on an entry is
the phase that produced it (`load` for the game migration and repair
pass, `policy` for the converter's own layer); the reward entries use a
separate `stage_name` field for the reward stage they concern, so the
two meanings never collide.

## The accounting rule

**If the converter drops it, the report names it.** Concretely: for any
id present in the selected source envelope and absent from the output,
and for any tracked scalar (credits, admiral, faction, reward stage,
per-ship hp, and the rest of the runner's list) whose value changed,
there is a report entry naming it, with a reason. `run_tests.js`
enforces this with a second, independent implementation (id inventories
per container plus tracked scalars, sharing no code with the
converter's recursive diff) and fails the fixture if any disappearance,
addition or change is unreported. A half dropped wholesale is the one
grouped case: the `dropped-half` entry names the half and lists every
id it held, and the accounting check treats that as covering the half.

## Reward safe point

A save can sit mid-reward-chain, with offers banked and fixed by design
(a reload must resume the same choices; the converter carries offers
verbatim and never re-rolls them). The emitted save is the post-load
banked state, with one rule: if the current stage's banked payload did
not survive conversion (a `relic` stage whose relic list was repaired
empty, a `pick` stage whose offers were discarded, a `prize` or
`salvage` stage with nothing left), the reward advances to the next
stage in chain order (`relic, prize, salvage, pick, promo`) that still
has contents, and each skipped stage is named in a `skipped-stage`
entry. A stored stage that is not a valid stage at all (the repaired
fixture's `banana`, which the game's repair resets to `promo` without
listing it) is likewise named as skipped, with its lost contents named
as drops. `promo` is terminal and always presentable, so a reward is
never advanced past it and never nulled by this rule.

## Options

`convert(store, options)` and the matching CLI flags:

- `grant: 'strip' | 'keep'`, default `'strip'` (CLI `--grant=keep`).
  The decision point, not a detail: when the boot-grant signature is
  detected (meta holds **all** LEGACY unlock keys and **all** roster
  admirals), `strip` removes the keys the grant added and lists each
  one as a `stripped` entry. The earned baseline is the store's `.bak`
  meta, which predates the granting save: keys the backup already holds
  are kept as earned. With no backup baseline, strip falls back to the
  default profile (`unlocked` emptied, `admirals` back to `{vex:
  true}`) and the entries say that is what happened. If the backup
  itself already shows full coverage, nothing is stripped: the coverage
  predates any grant this store can show and is treated as earned.
  `keep` preserves the grant and the report header says so in terms.
  Variants, mastery, favour and everything else are untouched by the
  grant in both modes (the boot code only fills the two maps).
- `metaUnknown: 'drop' | 'carry'`, default `'drop'` (CLI
  `--meta-unknown=carry`). Meta ids get no repair pass on either side:
  the browser keeps unknown ids in `unlocked`, `admirals`, `variants`,
  `mastery`, `favour` and `heatBest`, and the Godot `migrateMeta` keeps
  them too. `drop` removes them, each named in the report, so a reused
  id in a future build cannot resurrect stale progression. `carry`
  mirrors the browser and keeps them, with a `source-note` per id
  recording that they were seen and carried.
- `gameDir` (CLI `--game-dir=PATH`, or `VOIDSWORN_GAME_DIR`): the
  checkout whose `data.js` and `core.js` define the tables and the load
  policy for this conversion.

## Running the tests

```
node run_tests.js [--game-dir=/path/to/voidsworn]
```

The runner executes the converter against all 21 fixture cases in
`../importer_fixtures/` (18 single-file cases and 3 input/output pairs;
24 fixture JSON files, 26 files in that directory including its README
and generator), plus one synthetic check of the `.repaired` fallback.
Per case it checks: conversion does not throw; the output passes the
game's own `saneSave`; the output matches the fixture's recorded
`loaded` state (adjusted only for the default grant-strip on fixtures 3
and 6 and the default meta-drop on fixture 13, with the opposite modes
required to match exactly); the accounting rule holds; and the
fixture-specific assertions (recovery source, grant strip counts of 35
and 30 keys, the skipped `banana` stage, the 0 hp clamp to 1, the
dropped halves) hold.

Current result: **21 of 21 fixture cases pass, 22 of 22 checks
including the synthetic one.**

## Open decisions for Opus

The converter takes defaults so it can be tested; none of these
defaults is a ruling. Strip versus ratify in particular is Opus's and
Ryan's call, and this README deliberately does not make it.

1. **Strip or ratify the boot grant.** Default here is `strip`, back to
   what the backup copy shows was earned. Ratifying (`keep`) is one
   flag. Known edge the bak-diff rule cannot resolve: a purchase made
   legitimately in the single save between the backup and the granting
   save is indistinguishable from a granted key and would be stripped;
   and a profile whose granting save has already rotated into the
   backup gives the detector no pre-grant baseline (the fallback strips
   to defaults, which is harsher). Whether to detect at all, and how to
   treat those edges, is open.
2. **Meta unknown ids: drop or carry.** Default here is `drop`. The
   browser and the current Godot migration both carry. Dropping is
   safer against id reuse; carrying is the behavior players' saves
   already exhibit. Open.
3. **The `.repaired` fallback.** The converter recovers from the
   write-once audit copy when primary and backup are both dead, and
   reports it. The browser never loads that copy. Whether the shipping
   importer may is open.
4. **Reward safe point presentation.** The converter advances past a
   stage whose banked contents did not survive and names the skipped
   stages in the report. Whether the desktop resume flow should instead
   receive the stage as-is, and how much of the report (including the
   run's `_repairs` list, which the browser shows on Continue) is
   surfaced to the player, is open.
5. **Backup precedence.** The converter follows the browser exactly:
   the backup is a fallback for a damaged primary, never a source when
   the primary loads, even when the backup visibly holds more (fixture
   17's backup holds the pre-`endRun` run; the primary's settled state
   wins). Whether cutover should offer the player a choice is open.
6. **Transport.** Unsolved here and upstream: there is still no path
   that moves the browser store to the desktop build (file export,
   paste-in, cloud). The converter's input contract (a store object of
   raw strings) is the seam whichever transport is built should target.
7. **Cloud reconciliation.** `Persist.connect` pushes local over the
   cloud envelope on any `saneSave` failure, with no half-salvage. The
   converter only handles the local store; how imported profiles
   interact with the existing cloud save needs a ruling before the
   shipping importer writes anything.
8. **Final desktop format.** `formatVersion: 1` above is this
   reference's proposal. The Godot campaign already writes its own
   format; whether the shipping importer targets that format directly
   or passes through this intermediate shape is Opus's call.
