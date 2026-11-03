| ID | Quoted text | Code truth | Proposed corrected text | CERTAIN or AMBIGUOUS |
|---|---|---|---|---|
| ABILITIES:reload | "Torpedo tubes are ready to fire again immediately." | PACK cooldown: firing sets the tube's cooldown; a cd 2 weapon fires again on the third turn, and a launched torpedo strikes next turn. The pack gives no reload implementation, so "immediately" is unconfirmed and conflicts with normal tube state. | "Torpedo tubes reload now. A salvo already in flight still strikes next turn." | AMBIGUOUS |
| ADMIRALS:khepra | "Your ships take 50% less hull damage this round. Gets stronger each round you hold it." | Same cmd.id iron as Thale, Maren and Mirelle, whose texts say 40% less hull damage. The pack gives no iron Command implementation fact. | "Your ships take reduced hull damage this round." | AMBIGUOUS |
| BOONS:h_board | "and a failed boarding always sabotages a system." | The record's fx is only {boardPct:.25*m}; no sabotage key or clause is present. | "Boarding parties fight as 25% more crew at Common, rising with rarity." | CERTAIN |
| BOONS:h_feast | "its carrier gains a spare wing and repairs [X]% hull." | The record's fx is only {feast:.05*m}; no spare-wing key is present. | "When your squadron destroys a target, its carrier repairs 5% hull at Common, rising with rarity." | CERTAIN |
| TIPS:select | "Or Brace: the ship stays put, takes less damage, and does not take the +10, but it cannot move or fire again this turn." | ORDERS:brace says: "The ship can move first, but can’t brace after it has fired, and bracing ends its turn." | "Or Brace: the ship can move first, then takes less damage and does not take the +10, but bracing ends its turn and it cannot fire." | CERTAIN |
| TIPS:c_clock | "Every jump moves the clock at the top." | data.js NEM_CLOCK comment says the clock fills with every fight you win and every loud choice. PACK supplies no chair fact for the map clock. | "The clock moves when you win fights and make loud choices. When it runs out, the Nemesis catches up and the fights ahead get harder. Side stops pay, but they can move the clock." | AMBIGUOUS |
| TIPS:c_tree | "each point of Heat gives +2 experience to the admiral you fly and +1 to your faction's shared pool" | data.js HEAT comment says each level adds 10% renown. PACK supplies no chair fact for Heat rewards. | "Each point of Heat adds 10% renown and makes the run harder." | AMBIGUOUS |
| CARDS:c_clock | "Every jump moves the clock at the top." | Same as TIPS:c_clock: data.js NEM_CLOCK comment says wins and loud choices fill the clock; no chair fact. | "The clock moves when you win fights and make loud choices. When it runs out, the Nemesis catches up and the fights ahead get harder. Side stops pay, but they can move the clock." | AMBIGUOUS |
| CARDS:c_tree | "each point of Heat gives +2 experience to the admiral you fly and +1 to your faction's shared pool" | Same as TIPS:c_tree: data.js HEAT comment says each level adds 10% renown; no chair fact. | "Each point of Heat adds 10% renown and makes the run harder." | AMBIGUOUS |

Coverage

| Table | Audited | Flagged |
|---|---|---|
| WTRAITS | 10 | 0 |
| ABILITIES | 14 | 1 |
| ORDERS | 1 | 0 |
| RELICS | 13 | 0 |
| MODULES | 13 | 0 |
| ADMIRALS passives and Commands | 48 | 1 |
| FACTIONS blurbs, MOVE_RULES, FAC_GATES | 14 | 0 |
| BOONS including duo and legendary | 48 | 2 |
| FAVOUR_TIERS d texts | 3 | 0 |
| HEAT d texts | 7 | 0 |
| TIPS browser | 15 | 3 |
| Godot CARDS | 6 | 2 |
| Total | 192 | 9 |

UNVERIFIED

- WTRAITS:hellfire: "6 damage a turn for 2 turns" is not in f (ignite=1 only).
- WTRAITS:spines: "3 armor points, up to 15" cannot be read from shred=.03 without the shred implementation.
- WTRAITS:acid: "4 hull a turn for 2 turns" is not in f (acid=1 only).
- ABILITIES:evasive and ABILITIES:launch: no implementation facts in PACK.
- ABILITIES:nova: PACK explicitly says the nova block is not quoted; mark UNVERIFIED.
- RELICS:cogitator: "95% (75% against Full burn)" is not in run:{firstSure:1}.
- RELICS:phylactery: "25% hull" is not in run:{revive:1}.
- RELICS:banner: "up to +45%" is not in run:{bloodied:.15}.
- RELICS:salvage: "15 credits and repair 8% hull" is not in run:{salvage:1}.
- RELICS (from coverage: RELICS audited 13, flagged 0; the four items above are listed as unverified, not flagged).
- MODULES:flakplus: text says "+2 shots and +1 range"; the record has only fx:{flakPlus:1}, and PACK gives no mapping.
- ADMIRALS Commands with ids scramble, iron, surge and restore lack implementation facts; Khepra's iron Command is flagged AMBIGUOUS above.
- BOONS:a_mark: text says "aims 10 better"; fx has only {markLance:1}.
- BOONS:L_hunger: "99 spares" is not in {hangar:2,endless:1}.
- BOONS:L_star: "95% (75% against Full burn)" is not in {lanceSure:1}.
- HEAT: all seven d texts state numeric effects, but PACK supplies no chair-verified HEAT implementation fact.
- Chorus Feed doctrine: the FEED constants and generated doctrine text are not present in the attached data.js, so that doctrine text could not be audited here.

Not checked

Flavour, story and event text; names that state no rule; the naming lint. Also not audited because they are outside PACK's enumerated audit tables: LEGACY, EVENTS, SECTOR_CONDS, NODE_MODS, ARCHETYPES, WING_STANCES, WING_PERKS, FAC_VERBS, NEM_TRAITS, NEM_PERSONA, NEM_FAC behaviours, NEM_ADAPT, NEM_LINES, ASPECTS and STORY_BEAT3.
