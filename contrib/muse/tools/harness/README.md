# Voidsworn verification harness (chair-built, for Opus to review)

Status: DRAFT for Opus review, Oct 29, 2026. Built by Rey under Ryan's
savings-pass commission (do Opus-bound verification work with the council so
Opus only has to verify). These are plain Node scripts with no dependencies;
they load the shipped browser rules files headlessly and assert contracts
against them. They change no game code.

Run against the rules code at main 264f441d (the working clone's data.js,
core.js and battle.js are unchanged since that pin; everything pushed after
it is contrib-only).

## Files

- `game_loader.js` - loads data.js + core.js + battle.js into a Node vm
  context with minimal stubs (window, in-memory localStorage, performance).
  Exposes the named tables, genEnemyFleet, the Persist layer and the save
  sanity/repair functions. Shared by both harnesses.
- `fleet_invariants.js` - seeded sweep over genEnemyFleet: every faction x
  sector 1-3 x column 0-6 x kind (skirmish/elite/boss) x archetype
  (none/swarm/heavy/carrier), 12 seeds per cell. Asserts determinism, roster
  membership, boss-first on boss rolls, no Eclipse launch hull on any
  archetype (Oct 29 Q2 ruling), total CP within the budget formula's cap,
  and fleet size within the soft ceiling. Plus a 50-seed sensitivity probe.
- `save_fuzz.js` - mutation fuzzer for Persist.loadLocal: builds a baseline
  save with the game's own constructors, then applies 300 seeded mutations
  (truncation, character corruption, wrong types, unknown ids in every
  id-bearing field, bad credits, bogus reward stages) plus fixed garbage
  envelopes and a round-trip. Asserts loadLocal never throws and the loaded
  META/run pass the game's own saneMeta/saneRun checks with all surviving
  ids valid and credits finite.

## How to run

```
node fleet_invariants.js [repoDir] [seedsPerCell]
node save_fuzz.js [repoDir] [rounds] [seedBase]
```

repoDir defaults to ../../voidsworn-fresh relative to this folder's parent
layout used by the chair; pass the checkout path explicitly anywhere else.
Exit code 0 means every assertion held; failures print with their cell or
round and the seed reproduces them (mutations use the game's own rnd).

## Results at filing (Oct 29, 2026)

- fleet_invariants: 18,144 fleets generated, 18,145 checks, 0 failures.
- save_fuzz: 300 seeded rounds + garbage envelopes + round-trip, 0 failures.
  The repair layer behaved as designed throughout: unknown ids are dropped
  and logged, malformed halves are nulled, credits are forced finite.

## Known limits (for the reviewer)

- The fleet sweep runs with RUN null, so the player-power budget scaling
  (fleetPower vs RAMP.refP) is inactive. A RUN-loaded variant is the natural
  next harness: it would exercise the pwMin/pwMax clamp band.
- The fuzzer mutates one envelope at a time and does not fuzz the cloud
  reconciliation path in Persist.connect (needs the db stub).
- No battle-execution harness yet: startBattle/aiTurn need the animation
  stub surface sim3d.js already defines; porting that surface into
  game_loader is the next step and would let seeded full-battle invariants
  (no NaN hull, battle always terminates, winner consistency) run here.
