# DRAFT - Price ladder and roster gate proposal (Voidsworn design, PC-only Babylon)

Model: DeepSeek, DeepThink ON, Search OFF. Filed verbatim from the DeepSeek chat report (chat titled "Voidsworn price ladder draft"); em dashes normalized to hyphens if any, wording otherwise unchanged. The granted brief file was attached to the chat and the model was instructed to follow it exactly.

Status: DRAFT for Ryan and Opus. Not a ruling. Scope is PC-only Babylon. No economy hook design is included.

## OBSERVED and given facts used

- OBSERVED: current ladder at data.js:329 gives hulls without explicit cost h.cost = Math.round((60*cp+10)/5)*5. Every cp-1 frigate costs 70 and every cp-2 destroyer costs 130, regardless of faction.
- RULED Oct 24, 2026 identities: Voidsworn armored broadside line; Hegemony standard baseline at 1.0; Corsairs close-range salvage raiders; Chorus swarm that eats; Ithar elite glass skirmishers; Deathless elite attrition.
- APPROVED prohibitions to encode: Ithar cannot Brace; Chorus no shipyard repair, with scope across shipyard, Drydock, and Field repairs OPUS TO CONFIRM; Deathless no-shield is already an OBSERVED roster fact, all Deathless hulls sh:0.
- Do not change: cp values, hull stats, weapon stats, admiral costs. This draft changes costs and availability only.

## 1. Per-faction price table - PROPOSED

PROPOSED multipliers apply to the existing default ladder cost for that hull class. PROPOSED worked examples use nearest-5 rounding with ties up, matching the current convention. Multipliers are proposals, not current values.

| Faction | Frigate | Destroyer | Cruiser | Carrier | BB+ | Identity tie, one line |
| Hegemony | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | Baseline standard: stays 1.0 because no approved trait replaces baseline. |
| Voidsworn | 1.20 | 1.15 | 1.10 | 1.25 | 1.05 | Armored broadside line: screen pays a premium, line hulls stay near baseline, carrier is priced out or gated. |
| Corsairs | 0.85 | 0.90 | 1.15 | 1.20 | 1.40 | Close-range salvage raiders: cheap small raiders, expensive heavy projection. |
| Chorus | 0.70 | 0.75 | 1.30 | 1.40 | 1.60 | Swarm that eats: cheap many bodies, capital hulls priced out. |
| Ithar | 1.30 | 1.35 | 1.25 | 1.30 | 1.35 | Elite glass skirmishers: all hulls pricier, fewer hulls, destroyer premium blocks cheap screen spam. |
| Deathless | 1.35 | 1.30 | 1.20 | 1.40 | 1.15 | Elite attrition: high small-hull premium keeps hull count low, lower BB+ premium lets few old powerful machines anchor. |

PROPOSED worked frigate and destroyer examples

OBSERVED base costs: frigate 70, destroyer 130.

| Faction | PROPOSED frigate | PROPOSED destroyer |
| Hegemony | 70 | 130 |
| Voidsworn | 85 | 150 |
| Corsairs | 60 | 115 |
| Chorus | 50 | 100 |
| Ithar | 90 | 175 |
| Deathless | 95 | 170 |

Hegemony baseline paragraph: Hegemony remains at 1.0 because its defining trait is still open and the brief forbids inventing a new Hegemony trait. The shield-stripper idea is questioned because Chorus and Deathless are shieldless, so I do not propose a replacement trait or a faction discount. Until Ryan rules, any Hegemony multiplier other than 1.0 would be an unapproved trait.

Implementation note, price table: DATA-ONLY. Use a per-faction per-class multiplier field or explicit h.cost overrides. Do not alter cp or stats. OPUS TO CONFIRM whether the current data model supports per-faction class multipliers without code.

## 2. Roster gate list - PROPOSED

| Faction | PROPOSED gate | Fleet-building decision created | Implementation note |
| Voidsworn | Lose carrier hull class. | Forces broadside line and escorts; cannot project strike craft. | OPUS TO CONFIRM: class availability flag may be DATA-ONLY, but the facts do not confirm a carrier class gate flag exists. |
| Hegemony | OPEN - no gate proposed in this draft. | The each-faction-loses principle is not satisfied for Hegemony until Ryan rules; inventing a trait here would violate the brief. | OPUS TO CONFIRM / owner ruling. |
| Corsairs | Lose long-range missile or bombard weapon kind. | Close-range raider must close distance; cannot stand off and bombard. | OPUS TO CONFIRM whether weapon-kind availability flags exist; if not, NEEDS CODE. |
| Chorus | No repair: shipyard, Drydock, and Field repairs. Approved prohibition, scope OPUS TO CONFIRM. | Damaged swarm must be replaced or fed, not repaired; economy hook remains separate. | NEEDS CODE repair gate; scope OPUS TO CONFIRM. |
| Ithar | Cannot Brace. Approved prohibition. | Glass skirmishers must use range and positioning; fewer hulls are punished harder without Brace tanking. | NEEDS CODE boolean gate in canOrder. |
| Deathless | No shields. OBSERVED already: all Deathless hulls sh:0. | Cannot shield-tank; must use armor and attrition. | DATA-ONLY already roster fact; no new gate. OPUS TO CONFIRM if a shield-system availability flag is desired. |

## 3. Fleet sketch per faction - PROPOSED

- Voidsworn: 1 to 2 cruiser or BB+ line anchors, 3 to 5 destroyers, few frigates. Price shape is higher screen cost and near-baseline line cost. Cannot do cheap frigate swarm or carrier strike projection if the carrier gate is approved.
- Hegemony: mixed baseline fleet at 1.0 prices. No gate in this draft. Cannot claim a specialist faction identity until Ryan rules the open Hegemony trait.
- Corsairs: many cheap frigates and destroyers, some cruisers, rare BB+ because of 1.40 multiplier. Cannot do long-range bombard if that gate is approved; must close distance.
- Chorus: large numbers of cheap frigates and destroyers, few or no cruisers, carriers, or BB+ because of high multipliers. Cannot repair damaged hulls under the approved prohibition; must replace or feed, with economy hook out of scope.
- Ithar: fewer, pricier hulls across all classes. Cannot Brace. Must use range and positioning; cannot brawl or tank with cheap screen spam.
- Deathless: few small hulls, more capital or old-machine anchors because BB+ multiplier is lower than small-hull multipliers. Cannot shield-tank. Fleet is elite attrition, not swarm.

## 4. Implementation notes summary

- Price table: DATA-ONLY.
- Voidsworn carrier gate: OPUS TO CONFIRM class flag support.
- Hegemony gate: OPUS TO CONFIRM / owner ruling.
- Corsair long-range weapon gate: OPUS TO CONFIRM flag support, otherwise NEEDS CODE.
- Chorus repair prohibition: NEEDS CODE, scope OPUS TO CONFIRM.
- Ithar Brace prohibition: NEEDS CODE boolean gate in canOrder.
- Deathless no-shield: DATA-ONLY, already OBSERVED roster fact.

Least sure item: the Hegemony roster gate. It is OPEN because the brief forbids inventing a Hegemony trait and no approved Hegemony loss is in the facts. Ryan ruling the Hegemony defining loss, plus Opus confirming whether class and weapon availability flags are data-only, would settle it.
