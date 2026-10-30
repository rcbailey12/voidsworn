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
- `fleet_scaling.js` - the player-power scaling band with a RUN loaded:
  a strong fleet (7 heavy hulls at full hull) must never push the enemy
  budget past the pwMax clamp cap, and mean enemy CP must order
  strong >= baseline >= battered per sector within fill slack, with the
  strong/battered ratio inside pwMax/pwMin plus slack.
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
node fleet_scaling.js [repoDir]
node save_fuzz.js [repoDir] [rounds] [seedBase]
```

repoDir defaults to ../../voidsworn-fresh relative to this folder's parent
layout used by the chair; pass the checkout path explicitly anywhere else.
Exit code 0 means every assertion held; failures print with their cell or
round and the seed reproduces them (mutations use the game's own rnd).

## Results at filing (Oct 29, 2026)

- fleet_invariants: 18,144 fleets generated, 18,145 checks, 0 failures.
- fleet_scaling: 0 failures. Mean enemy CP by sector (strong / baseline /
  battered): s1 8.0 / 8.0 / 8.0, s2 16.4 / 15.0 / 14.8, s3 26.3 / 21.4 /
  16.0. Note for the reviewer: in sector 1 the scaling does not express at
  all (identical means), because the budget (about 8 CP) is small against
  whole-hull costs; it expresses from sector 2 and is wide by sector 3
  (ratio 1.64 against a 1.73 clamp band). Whether sector 1 should respond
  is a design question, not a defect claim.
- save_fuzz: 300 seeded rounds + garbage envelopes + round-trip, 0 failures.
  The repair layer behaved as designed throughout: unknown ids are dropped
  and logged, malformed halves are nulled, credits are forced finite.

## Scope note (what this package deliberately does not duplicate)

- Battle execution already has a harness: the repo's own sim3d.js runs
  seeded battles and campaigns through the same files with its animation
  stub surface and a player bot, across dozens of modes. A second battle
  runner from the chair would duplicate it. This package covers the two
  surfaces sim3d does not: fleet-generation contracts (sim3d consumes
  genEnemyFleet but asserts nothing about it) and the save layer (sim3d
  stubs Persist out entirely, so the real load/repair path had no fuzz
  coverage).
- Godot parity golden records already exist and are Opus-owned
  (godot/rules/test/node/golden.js, godot/campaign/test/node/
  golden_campaign.js). No new fixtures are proposed here.

## Known limits (for the reviewer)

- The fuzzer mutates one envelope at a time and does not fuzz the cloud
  reconciliation path in Persist.connect (needs the db stub).
- fleet_scaling fixes the enemy faction (hegemony) and column (3) for the
  ordering probe; the per-fleet cap check does sweep all factions.
