## 1. Proof of reading

The pack contains 12 relics (READ). Relic effects have two channels: `fx` stat modifiers folded through `fleetFxList` / `sumFx` with admiral and boon fx, and `run` keys folded by `runFx` for run-long/battle effects (READ). One acquisition path: an elite win offers a choice of 1 of 2 random unheld relics; a boss win offers 1 of 3 (READ).

Verdict: MOSTLY DISTINCT.

## 2. Findings

1. [BLOCKER] Phylactery revive and Eclipse reanimate are separate systems, but the pack does not state order, consumption, or whether both can fire on the same death; an Eclipse fleet holding phylactery may double-pay or resolve ambiguously (READ: "Separate from the Eclipse faction reanimate mechanic"; INFERRED risk).
2. [FIX] Martyr's avenge triggers on every player ship destruction with no per-battle cap, unlike revive's `B.reviveUsed` flag; sacrificing a ship can heal the rest of the fleet repeatedly (READ: "no per-battle cap in this code"; INFERRED incentive).
3. [FIX] `payRelic` removes the last relic in the list, not a player-chosen relic; an event cost can strip a key or newly acquired relic arbitrarily (READ: "splice(RUN.relics.length-1,1)").
4. [FIX] Relic offers have no decline-for-credits option while boons do; combined with only one usefulness exclusion, this can force a dead pick (READ: "No decline-for-credits option on the relic step"; INFERRED defect if dead picks exist).
5. [FIX] `relicUseful` excludes only lattice for shieldless fleets; coils can be dead with no cooldown abilities, banner weak in low-kill fleets, and martyr dead in a one-ship/no-non-squadron fleet (READ: "excludes ONLY lattice for a shieldless fleet"; INFERRED dead states).
6. [NOTE] Relic `fx` objects are pushed into the same list as admiral and boon fx, so lattice/compass/armourweave/spore/coils stack additively on shared keys; no two relics share a key, but these are same-key additive modifiers versus other systems (READ: "pushed into the SAME list"; INFERRED).
7. [NOTE] Ledger's `credPct` stacks with the META salvagers unlock's `credPct +.2`; economy analysis must isolate relic credit income (READ: "META salvagers unlock adds credPct +.2").
8. [NOTE] Fallback naming is functional, but phylactery's base name is "Eclipse backup frame," leaking Eclipse into non-Eclipse factions that lack a phylactery entry (READ: "base name of phylactery is 'Eclipse backup frame'"; INFERRED flavor defect).
9. [NOTE] The `cogitator` id exists in both RELICS and MODULES; the pack shows independent save validation and separate display-name tables, but not all offer/reward code, so no confusion path is demonstrated (READ: "checks relics against RELICS and inventory against MODULES independently"; INFERRED no path shown).

## 3. Checks

### a. Effect audit

Within the 12 relics, each effect is distinct in kind/key: martyr avenge; cogitator firstSure; lattice shPct; spore hullRegen; phylactery revive; ledger credPct; compass speed; banner bloodied; salvage post-battle credits/repair; coils cdMod; logbook xpPct; armourweave armor (READ). No relic is a smaller or larger copy of another relic on the same key (READ/INFERRED from table).

Against admiral doctrines and boons, the pack does not list their keys/values, so exact size-copy comparison is not possible (READ gap). The shared additive keys are `shPct`, `speed`, `armor`, `hullRegen`, and `cdMod`; lattice, compass, armourweave, spore, and coils therefore stack additively with any doctrine/boon using those keys (READ fold; INFERRED copy risk). Ledger is also same-key with META salvagers' `credPct +.2` (READ).

### b. The two revive systems

Phylactery is a relic `run:{revive:1}` effect: first player ship destroyed each battle restarts at 25% hull, with `B.reviveUsed` per battle (READ). Eclipse reanimate is a separate hull/faction system with its own conditions (READ). The pack does not specify resolution order or whether both can fire on the same death (READ gap; INFERRED collision risk). For an Eclipse fleet holding phylactery, both systems may be eligible on a death; without order/consumption rules this is a double-pay or ambiguity risk (INFERRED). For a non-Eclipse fleet holding phylactery, only the relic revive applies to player ships; Eclipse reanimate is not the player's faction mechanic (INFERRED from faction separation). Against Eclipse enemies, the player's phylactery should not alter enemy reanimate, but the pack does not show enemy-side interaction (INFERRED/READ gap).

### c. Avenge

Avenge triggers on every player ship destruction, heals every other living non-squadron player ship by 15% max hull, and has no per-battle cap (READ). That is a perverse incentive in at least some states: losing a ship can heal the survivors, so sacrificial chaff can be rewarded (INFERRED). It can also snowball healing across multiple deaths, though it does nothing if no other living non-squadron ship exists (INFERRED). Revive is disciplined by a per-battle flag; avenge is not (READ). Whether this is intentional martyr fantasy or an exploit is not stated (READ gap).

### d. Offer fairness

The filter excludes only lattice for shieldless fleets (READ). Other dead/near-dead states: coils is dead with no cooldown abilities; banner is weak in low-kill/low-damage fleets; martyr is dead in a one-ship fleet or with no living non-squadron others; compass is questionable if speed is unused/capped, but the pack does not define speed mechanics; spore is weak in short/no-damage battles; phylactery is dead in no-death battles; ledger/salvage/logbook are weak without battles/XP; armourweave depends on armor existing (READ table; INFERRED states). A weak pick can be an acceptable random-offer cost, but truly dead picks should be filtered if fleet state is known (INFERRED). The current filter is too narrow for that standard (READ/INFERRED).

### e. Acquisition and loss

Elite 2-choice and boss 3-choice are fine as reward tiers (READ; INFERRED fine). No decline on the relic step is a real defect only if offers can be dead; given the narrow usefulness filter, that risk is real (READ no decline; INFERRED defect). `payRelic` removing the last relic rather than a chosen one is a real defect: it removes player agency and can take a key or just-acquired relic unpredictably (READ). No duplication in offers is fine (READ).

### f. Naming coverage

Fallback to base name is fine as graceful degradation, and coverage gaps are mainly flavor opportunities (INFERRED). The exception is phylactery: its base name "Eclipse backup frame" carries another faction's name, so non-Eclipse factions lacking a phylactery entry see an Eclipse-branded relic (READ base name/coverage; INFERRED defect). That should be fixed with a neutral base name or fuller coverage.

### g. Cogitator key collision

No confusion path is demonstrated by the pack: save validation checks relics against RELICS and inventory against MODULES independently, and display names are separate tables (READ). Relic offers filter unheld relic ids, but module offer/reward code is not in the pack (READ/INFERRED). So the answer is INFERRED no demonstrated path, not proven absence. Settle it by inspecting module reward/offer code, any shared id lookup, display lookup, and save migration for legacy ids.

## 4. Not checked

- Exact admiral doctrine and boon keys/values, so same-key stacking sizes cannot be quantified.
- Battle.js order/flags for phylactery revive versus Eclipse reanimate on the same death.
- Speed mechanics/caps, armor existence, ability rosters, XP caps, and credit sinks.
- Full module offer/reward/display code beyond the separate validation and naming tables.
- Event UI/choice details and whether `payRelic` can remove a just-granted relic.
- Enemy Eclipse reanimate interaction with player phylactery.
- Legacy save migration/id collision behavior beyond `keep()`.

## 5. Designer questions

1. Should phylactery revive and Eclipse reanimate ever fire on the same death, and if so which consumes first? Stakes: double revival or inconsistent faction value.
2. Is avenge meant to reward sacrificial losses, or should it be capped per battle/per ship? Stakes: martyr fantasy versus snowball/perverse incentive.
3. Should all dead relic picks be filtered and should `payRelic` be player-chosen? Stakes: forced dead picks and arbitrary loss of key relics distort run agency.
