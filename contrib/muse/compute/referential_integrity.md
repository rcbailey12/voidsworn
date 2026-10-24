# Voidsworn referential integrity

Basis: repo HEAD 51337c2. Generated mechanically by hidden_files/compute/code_index.js (Compute Run 2).

Headline: **0 referenced-but-undefined exceptions** and **49 defined-but-never-referenced ids** across 16 categories.

## Method

- Id universes are not scraped with regexes. data.js is loaded in a Node vm (it is pure data at load time) and the real table objects are read: W, HULLS, FACTIONS, ABILITIES, ORDERS, MODULES, PERKS, RELICS, ADMIRALS (including the Object.assign additions), LEGACY, PATRONS, BOONS, ASPECTS, WTRAITS, EVENTS, FAC_WNAMES, FAC_WTRAIT and the name-list tables. ENCOUNTERS, ENC_POOL, ENC_SPECIAL and BOSS_CMD are extracted as literals from battle.js and evaluated the same way.
- There is no standalone commands table in the game. The command universe is the set of cmd.id values found on admirals plus the ids in BOSS_CMD; it is derived, and labelled as such.
- Referenced-but-undefined checks: (a) cross references inside the data itself (hull weapon lists and ability/faction fields, admiral starting fleets, factions rosters and boss fields, boon patron fields, module only fields, legacy req chains, event faction exclusions and reward ships, the FAC_WNAMES / FAC_WTRAIT / MOD_NEED / MOD_NAMES / RELIC_NAMES / BOON_NEED key tables, SECTOR_POOL, ENC_POOL, ENC_SPECIAL, BOSS_CMD); (b) literal table-index accesses in code (for example HULLS['warden']) across the 20-file corpus; (c) in battle.js, command dispatch comparisons (c.id===...) and encounter-type comparisons (o.type===, .enc===, enc===).
- Defined-but-never-referenced: an id counts as referenced if, outside its own defining table, it appears anywhere in the corpus as an exact string literal or as an object key. Data-internal references (starting fleets, weapon lists, name tables) therefore count. Heuristic limits: ids constructed at runtime by string concatenation, ids stored in save files and never written as literals in code, and ids reached only through computed property access will be reported as never referenced even if the game can produce them at runtime. Treat the never-referenced lists as review queues, not verdicts.
- Enumeration: several tables are consumed by iteration (Object.keys / Object.entries / for..in) rather than by naming individual ids. Where a category section lists enumeration sites, ids in its never-referenced list can still be live content handed out by iteration (random boon offers, perk rolls, the legacy shop, admiral select). The lists stay factual under the definition above, but for those categories they are expected to be mostly non-actionable.
- FAC_WNAMES, FAC_WTRAIT, MOD_NAMES and RELIC_NAMES are two-level rename tables of the shape {faction: {id: name}}; their outer keys are checked against factions and their inner keys against the relevant id universe. They omit voidsworn, whose names are the defaults, so a missing voidsworn key is not an exception.
- Scope note: fx keys (the hpPct / broadPct vocabulary), terrain and map ids, node types and icon names are separate vocabularies and are not covered here.

## Hulls / ship templates (HULLS)

Universe: 45 ids.

Clean: every referenced id is defined, and every defined id is referenced at least once.

## Weapons (W)

Universe: 25 ids.

Clean: every referenced id is defined, and every defined id is referenced at least once.

## Boons (BOONS)

Universe: 36 ids.

This table is enumerated in code at: core.js:146, core.js:147, core.js:150, core.js:291. Its ids can be handed out by iteration without ever appearing as literals.

Defined but never referenced:

- `i_plate`
- `i_line`
- `s_ev`
- `h_board`
- `a_aim`
- `a_long`
- `r_burn`
- `r_jink`
- `d_hunter`

## Relics (RELICS)

Universe: 12 ids.

This table is enumerated in code at: core.js:194, campaign_run.js:247. Its ids can be handed out by iteration without ever appearing as literals.

Clean: every referenced id is defined, and every defined id is referenced at least once.

## Modules (MODULES)

Universe: 13 ids.

This table is enumerated in code at: core.js:188. Its ids can be handed out by iteration without ever appearing as literals.

Clean: every referenced id is defined, and every defined id is referenced at least once.

## Admirals (ADMIRALS)

Universe: 24 ids.

This table is enumerated in code at: core.js:274, campaign_meta.js:53, campaign_meta.js:119, campaign3d.js:105, main3d.js:11. Its ids can be handed out by iteration without ever appearing as literals.

Defined but never referenced:

- `kassar`
- `vorn`
- `maren`
- `grax`
- `sable`
- `mott`
- `vesh`
- `razormaw`
- `mending`
- `voice`
- `vaelen`
- `thorne`
- `mirelle`
- `nekhet`
- `anuket`
- `khepra`

## Commands (admiral cmd.id values + BOSS_CMD)

Universe: 6 ids.

Clean: every referenced id is defined, and every defined id is referenced at least once.

## Factions (FACTIONS)

Universe: 6 ids.

This table is enumerated in code at: data.js:327, core.js:129. Its ids can be handed out by iteration without ever appearing as literals.

Clean: every referenced id is defined, and every defined id is referenced at least once.

## Patrons (PATRONS)

Universe: 6 ids.

This table is enumerated in code at: core.js:138, core.js:279, campaign_meta.js:121. Its ids can be handed out by iteration without ever appearing as literals.

Clean: every referenced id is defined, and every defined id is referenced at least once.

## Encounters (ENCOUNTERS, battle.js)

Universe: 8 ids.

Clean: every referenced id is defined, and every defined id is referenced at least once.

## Abilities (ABILITIES, extra category)

Universe: 13 ids.

Clean: every referenced id is defined, and every defined id is referenced at least once.

## Perks (PERKS, extra category)

Universe: 14 ids.

This table is enumerated in code at: core.js:132, core.js:289, campaign_run.js:127. Its ids can be handed out by iteration without ever appearing as literals.

Defined but never referenced:

- `gunnery`
- `killer`
- `deflector`
- `ironhull`
- `steady`
- `lanceadept`
- `stubborn`
- `rapid`
- `hunter`
- `laststand`
- `flanker`

## Legacy unlocks (LEGACY, extra category)

Universe: 12 ids.

This table is enumerated in code at: campaign3d.js:105, main3d.js:11. Its ids can be handed out by iteration without ever appearing as literals.

Defined but never referenced:

- `u_carrier`
- `u_battleship`
- `u_dread`
- `chest1`
- `chest2`
- `chest3`
- `cmd1`
- `cmd2`
- `vets`
- `founder`
- `wrights`
- `salvagers`

## Aspects (ASPECTS, extra category)

Universe: 6 ids.

This table is enumerated in code at: campaign_meta.js:94. Its ids can be handed out by iteration without ever appearing as literals.

Defined but never referenced:

- `bulwark`

## Orders (ORDERS, extra category)

Universe: 1 ids.

Clean: every referenced id is defined, and every defined id is referenced at least once.

## Weapon traits (WTRAITS, extra category)

Universe: 10 ids.

Clean: every referenced id is defined, and every defined id is referenced at least once.

