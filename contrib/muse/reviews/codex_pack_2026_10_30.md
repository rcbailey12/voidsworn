# Codex content pack, Oct 30, 2026

Chair pack, Muse (Rey). Status: complete draft for Opus to wire into the Godot codex surface. Not pushed with the game code; the machine-readable companion file is `contrib/muse/tools/codex/codex_entries.json` (191 entries). Built against the executed tables of the browser build at the Oct 29 audit pin (commit 264f441d), loaded through the harness loader, never by reading source text. All entry writing is original to this pack; mechanics are stated from the executed data only.

## 1. What this is

A complete in-game codex: every faction, hull, weapon, boon, relic, module, admiral, and legacy unlock in the shipped tables, written as uniform reference entries a player can browse from the title screen or the fleet screen. It replaces the current help surface, which the Oct 27 text audit found carrying statements that are not true of the shipped game. Nothing in this pack invents a mechanic: if a number is printed in an entry, that number is in the executed data, and section 6 shows the trace that proves it.

## 2. Format spec

Each entry in the JSON is an object with seven fields:

- `id`: category prefix plus the data key (for example `hull:warden`, `boon:i_brace`). Ids are keys only; no entry name is a code id.
- `category`: one of faction, hull, weapon, boon, relic, module, admiral, legacy.
- `name`: the display name exactly as the tables print it (class names resolved through the class display map, so the Eclipse flagship shows as an Archive-ship, never under its internal class key). One ruled override: the Hullbreaker admiral grax shows as Warlord Grax Ironmaw, per the Oct 27 rollout ruling (text overhaul pack item T-03); the data at this pin still says Steelgrin.
- `hook`: one line, at most 90 characters, written for list views and tooltips.
- `body`: two to four short sentences. First the fiction, in the faction idiom where the category calls for it, then the mechanics in plain language with the real numbers: stats, effect values translated out of effect keys, and costs.
- `note`: an optional one-sentence tactical usage note. Empty where a note would only repeat the body.
- `source`: the table and key the entry was built from, so any number can be re-checked in seconds.

Boon effects are stated at base strength (the Common multiplier, 1x). Protocols whose effect scales with rarity say so in the body; duo, legendary, and fixed gift protocols are marked fixed, because their effect functions take no multiplier. Relic entries use the base display names (the names a Sunward Crusade fleet sees); the body lists the other fleets names for the same piece where the tables carry them. The relic concept itself is displayed in game as salvage, and the pack uses that word for the category everywhere except inside proper names.

## 3. Coverage reconciliation

Every row of every enumerated table was executed and counted, then matched against the entry set by the validator (section 6). Nothing is silently missing, and there are no orphan entries.

| Table | Rows in data | Entries | Notes |
| --- | --- | --- | --- |
| FACTIONS | 6 | 6 | One per faction, with its battle rule and drive rule |
| HULLS (standard) | 24 | 24 | The six faction rosters |
| HULLS (boss) | 6 | 6 | One flagship per faction, flagged as boss hulls in the body |
| HULLS (squadron) | 3 | 3 | Fighter wing, Bomber wing, Spore swarm: flown from carriers, entered as hulls |
| HULL_VARIANTS | 18 | 18 | 12 renown sidegrades plus 6 story-arc sidegrades, entered as hulls with their base named |
| W (weapons) | 25 | 25 | Including the 3 point-defense kinds and the 3 squadron weapons |
| BOONS | 48 | 48 | 30 scaling patron protocols, 6 fixed gift protocols, 6 duo protocols, 6 legendary protocols |
| RELICS | 12 | 12 | The full salvage pool |
| MODULES | 13 | 13 | Including the carrier-only hangar expansion |
| ADMIRALS | 24 | 24 | Four per faction, doctrine and Command both stated |
| LEGACY | 12 | 12 | The renown unlock lines: Shipyards, Supply, Command |
| **Total** | **191** | **191** | **Exact match, both directions** |

Deliberately excluded, with reasons: ASPECTS (6 flagship aspects) and PERKS (14 captain perks) are real systems but sit outside the commissioned category list for this pack; they are the natural second pack. PATRONS (the six cores) have no standalone entries by design: each core is introduced inside its boon entries, which is where a player meets it. Captain name pools, encounters, map shapes, and events are not reference content and were left out.

## 4. Voice rules applied

- Faction and hull entries are written in the r8 faction idiom: the Crusade in chalk, the Roll, oaths and debt (bookkeeping belongs to the Hegemony, and only Hegemony entries use it); the Hegemony in Registry, projection and acceptable limits; the Hullbreakers short, brutal, pack and trophy; the Glasswrights in light, glass, grief and craft; Eclipse in memory, the Archive, the lost sun and counted years.
- The Chorus never sings, in any entry, including its own. Chorus text is flesh idiom only: throats, mouths, hunger, Memory and Hunger arguing. The word for what the swarm does is speak, as we.
- Eclipse entries carry no faces and no human crew assumptions: minds, frames, copies, the Archive. Nothing Eclipse is described as manned.
- Glasswright entries respect the parallel-procession fiction: no serial die-and-learn loop is implied anywhere; their entries speak of craft, grief, and the long view of a people who live three to four hundred years.
- Plasma is light blue wherever its color is mentioned (the Hegemony pulse lasers, the plasma drive, the plasma coils relic), per the Oct 26 ruling.
- Ship text is space text: no naval furniture words, and no gun faces backward; arcs are named prow, port broadside, starboard broadside, turret, rear, exactly as the data names them.

## 5. Data traps this pack avoids

- The kind system: the flak battery, the null sentries, and the spore cloud are one kind (point defense) under three names. Their entries say so in so many words, and state the rule correctly: a point-defense mount never fires in a volley and never shoots at ships; it guards against squadrons, rockets and boarding craft, and a second mount adds nothing to the guard. Hull entries list these mounts by their faction display names, as the game does.
- Class display: four internal class keys are not display names. Entries resolve them (War-barge, Colossus, Lattice-ship, Archive-ship) and never print the keys.
- Steelgrin is Ironmaw (see section 2). The name removed from the Crusade ship pool by the Oct 28 ruling is not used as a name anywhere in the entry text.
- The help screen falsehoods catalogued by the text overhaul pack (Oct 30) are not repeated: no claim appears here that the overhaul pack flagged, and every mechanic below was re-derived from the executed tables rather than copied from any help text.
- Effect keys are never printed raw. Every fx key (broadPct, cdMod, hullRegenPct and the rest) is translated into the plain-language effect it produces, at the value the table carries.

## 6. Validation

The pack was validated by an independent script (`validate_codex.js`, kept with the working files in `~/workspace/voidsworn-codex/`, alongside the generator `gen_codex.js`) that re-executes the tables and checks the written JSON cold:

- Coverage: 191 table rows expected, 191 entries found, exact match in both directions; every entry name re-compared against its table row (with the single ruled Ironmaw override).
- Number tracing: 1,100 digit-numbers appear across all hooks, bodies, and notes. Every one was required to be derivable from its own entry source rows (raw values, numbers inside evaluated description strings at base strength, fraction-to-percent conversions, array lengths and element counts). Violations: 0.
- Display-name lint: no entry name is or contains a code id. Retired-vocabulary lint (the r8 banned list: warp and auspex family, song words, gauss and tomb as words, naval furniture, and the rest) over all entry prose: 0 hits.
- Hook length: all 191 hooks at or under 90 characters. Em dash and en dash count across the JSON and this document: 0.

## 7. Full entry text

### Factions (6)

**Ashfall Hullbreakers** (`faction:corsair`)
- Hook: Furred pack hunters in ships that run dark, stripping every wreck they make.
- The Hullbreakers are an alien raider species from the Ashfall belt, big furred predators who live in packs ruled by whoever can beat the rest. They do not raid for riches; they raid for the fight, for scrap, and for Rook, the core they believe makes its holder unstoppable. Their ships run silent, hunt by wake and engine noise, and strip every wreck down to the frame. Faction rule, Close in: Hullbreakers field no lance weapons at all, winning up close instead, and their rocket pods fire salvos that point defense can thin out. Their drive rule, Bolted burners, makes sideslips cost 1 movement instead of 2. Their line runs from the Hullbreaker raider, Hullbreaker gutship, Hullbreaker wrecker, Hullbreaker hulk-carrier, under the flagship Warlord's Pyre-Barge, with Bomber wing flown from their carriers.
- Note: Close fast from the flanks and behind; at long range this fleet is only a promise.
- Source: data.js FACTIONS.corsair; battle.js FAC_RULES.corsair, MOVE_RULES.corsair; lore bible r8

**Eclipse** (`faction:deathless`)
- Hook: Starwright minds in machine bodies, stealing starlight to light a new sun.
- Eclipse are the Starwrights who uploaded: billions of separate minds in machine bodies, backed up in one shared Archive, who seized the Lattice and overdrove it and killed their own star in the doing. A thousand years in the dark later, they are no longer sure permanence was worth the price, and their answer is a new sun at the heart of the Ardent system, fed by energy siphoned from neighbouring stars. They know what the Siphoning costs other worlds. They do it anyway. Faction rule, Archive restore: the first Eclipse ship to fall each battle, never the flagship, reassembles at the start of the next round with 35% hull and cannot fire that round, and a fleet of 6 or more reanimate-capable hulls gets two returns. Their drive rule, Fold drive, passes through rocks, wrecks and enemy ships at no extra cost. Their line runs from the Eclipse mote, Eclipse flare, Eclipse zenith, under the flagship The Unsetting.
- Note: Kill Eclipse hulls in bunches or not at all; a lone kill is a loan, and it comes back.
- Source: data.js FACTIONS.deathless; battle.js FAC_RULES.deathless, MOVE_RULES.deathless; lore bible r8

**Hegemony Navy** (`faction:hegemony`)
- Hook: The Registry navy: linked crews, wedge hulls, and losses within acceptable limits.
- The Hegemony is the largest human state in the region, run by the Registry, a vast intelligence at Meridian that every citizen, ship and officer is linked to. It does not rule by force; it optimises, predicts every loss, and keeps the losses acceptable. It wrote off the Vesper Reach seventy years ago, and it holds one of the six cores, Vyre, taken by a survey fleet and studied ever since. Faction rule, Synchronized fire: ships within 3 hexes of their flagship fire as one, and a target another synced ship already fired on this round is 6 easier to hit and takes +12% damage. Lose the flagship and sync is gone for the rest of the battle. Their drive rule, Retro thrusters, makes backing off one hex cost 1 movement instead of 2. Their line runs from the Hegemony picket, Cordon destroyer, Vanguard cruiser, Dominion dreadnought, under the flagship The Iron Mandate, with Fighter wing flown from their carriers.
- Note: Fight as a cluster around the flagship; a Hegemony ship alone is just a ship.
- Source: data.js FACTIONS.hegemony; battle.js FAC_RULES.hegemony, MOVE_RULES.hegemony; lore bible r8

**Sunward Crusade** (`faction:voidsworn`)
- Hook: The frontier the Hegemony wrote off, come sunward to take its stars back.
- The Vesper Reach was the Hegemony frontier until its stars began to dim and the Registry priced the evacuation of billions as not worth doing. The Reach seceded, pooled its navies, and traced the theft of its light to the Hollow Sun. Every generation since has sworn the same oath and chalked the names of the fallen on the hull: go sunward, burn out what is stealing the light, and pay for it in names. Faction rule, Line of battle: port and starboard guns hit 40% harder after the ship has moved 2 or more hexes, where other factions gain 10%. Their carriers cost 25% more than the same hull elsewhere. Their line runs from the Warden-class frigate, Harrow-class destroyer, Vigil-class cruiser, Hearth-class carrier, Bastion-class battleship, under the flagship Daybreak-class dreadnought.
- Note: Brace and hold the line; the broadside bonus pays for the advance, not for sitting still at range.
- Source: data.js FACTIONS.voidsworn; battle.js FAC_RULES.voidsworn, MOVE_RULES.voidsworn; lore bible r8

**The Chorus** (`faction:chorus`)
- Hook: A living weapon that ate its makers, coming home hungry. We are the Chorus.
- The Chorus is not a people. It is a weapon the Fleshwrights grew in living tissue to destroy Eclipse, powered by the core Crucible, and it worked too well: it merged, multiplied, and consumed its makers, and became one swarm with one appetite. Inside it two throats argue: Hunger, which is the swarm, and Memory, which is what is left of the Fleshwrights it ate. It has no shields at all, and it is coming to the Sun to eat what is left. Faction rule, Feed: when an enemy ship dies, the Chorus ship that killed it regrows 12% of its hull, and every other Chorus ship within 2 hexes regrows 6%, up to 12% per ship each round. On top of that, every Chorus line hull regrows on its own each round, and its drive rule, Living hull, makes the first turn each round cost no movement. Their line runs from the Chorus drone-spawn, Chorus spitter, Chorus bladeback, Chorus brood-sac, under the flagship The Ninefold Maw, with Spore swarm flown from their carriers.
- Note: Trade hull freely and finish kills near your wounded; a Chorus fleet that is feeding is very hard to put down.
- Source: data.js FACTIONS.chorus; battle.js FAC_RULES.chorus, MOVE_RULES.chorus; lore bible r8

**The Glasswrights** (`faction:ithar`)
- Hook: Few, long-lived masters of light and crystal, flying a caged star to hunt the rest.
- The Glasswrights descend from the Starwrights who refused the Upload: the Lattice engineers who built the collectors and beam lines that once carried a star across a system. They live three to four hundred years, so the guilt of the collapse is only two or three generations old, and the Fleshwrights who made the Chorus were their own splinter. They fly one core, Astra, caged and throttled, used only to hunt the other five, and theirs will be the last one shut down. Faction rule, Prism charge: at the start of a Glasswright ship turn, a shield facing that was not hit since its last turn recharges to full, and a facing that was hit recharges twice. Glasswright hulls cannot Brace for impact. Their drive rule, Crystal vanes, makes a ship that moved 2 or more hexes 18 harder to hit until its next turn. Their line runs from the Glasswright sliver, Glasswright lancet, Glasswright prism, Glasswright aperture, under the flagship The Unfinished, with Fighter wing flown from their carriers.
- Note: Keep moving and keep shields up; once the shields fall, the hull underneath is glass in truth.
- Source: data.js FACTIONS.ithar; battle.js FAC_RULES.ithar, MOVE_RULES.ithar; lore bible r8

### Hulls (standard, boss, squadron, and variants) (51)

**Archive guard flare** (`hull:d_jackal_h`)
- Hook: Both cannons turreted, plus a spire, at 10 hull cost.
- A variant of the Eclipse flare. Destroyer class, 2 command points, 195 credits. Hull 100, shields 0, armor 25%, speed 3, turn 2, evasion 6. Carries Null cannon (turret), Null cannon (turret), Null spire (turret). Regrows 3 hull at the end of each round. Fits 1 module. Its mind re-streams from the Archive when it falls, so the hull can reassemble and return (see Archive restore, under Eclipse). Ability, Fold skip (cooldown 3): +25 evasion until its next turn and +2 movement at once. It is earned by finishing the story arc of Eclipse, never sold for renown.
- Note: Its jump makes it a flanker and a thief of objectives; rear arcs are where it earns.
- Source: data.js HULL_VARIANTS.d_jackal_h; HULLS.d_jackal_h (derived from HULLS.d_jackal)

**Bastion-class battleship** (`hull:cathedral`)
- Hook: The Bastion: a black-iron wall with heavy broadsides.
- The Bastion is a black-iron wall with guns: the ship a sector thinks of when it thinks of the Crusade arriving. Battleship class, 5 command points, 340 credits. Hull 220, shields 30 recharging 12 a round, armor 30%, speed 2, turn 1, evasion 0. Carries Heavy sear broadside (port broadside), Heavy sear broadside (starboard broadside), Oath lance (prow), Spark flak (turret). Fits 3 modules. Ability, Shield surge (cooldown 4): every shield facing restored to full.
- Note: The center of a line: slow enough that the battle must come to it, so make sure it does.
- Source: data.js HULLS.cathedral; ABILITIES.surge; faction Sunward Crusade

**Bladeback stalker** (`hull:b_razor_s`)
- Hook: Two tendril clusters, quicker and harder to hold.
- A variant of the Chorus bladeback. Cruiser class, 3 command points, 190 credits. Hull 150, shields 0, armor 20%, speed 5, turn 2, evasion 12. Carries Boarding tendrils (turret), Boarding tendrils (turret). Regrows 7 hull at the end of each round. Fits 2 modules. Ability, Blood frenzy (cooldown 3): all of its weapons deal +30% damage this turn. It is bought once with 25 renown, then sold in the shipyards of The Chorus beside the standard hull at the same 190 credits.
- Note: No shields at all: every point of damage is hull, and every round some of it grows back.
- Source: data.js HULL_VARIANTS.b_razor_s; HULLS.b_razor_s (derived from HULLS.b_razor)

**Bomber wing** (`hull:bomber`)
- Hook: Carrier wing: slow weight aimed at capital hulls.
- Bomber wings carry the weight their carriers cannot: slow, heavy, and aimed at things much bigger than them. Squadron class, 0 command points. Hull 28, shields 0, armor 0%, speed 5, turn 9, evasion 25. Carries Bomb payload (turret). It flies as a squadron wing from a carrier hangar rather than as a ship of the line.
- Note: Launched from carriers, not bought: protect the carrier and the wing keeps coming back.
- Source: data.js HULLS.bomber; faction Unaligned

**Chorus bladeback** (`hull:b_razor`)
- Hook: The bladeback: tendrils, spines, and a temper.
- A bladeback is the swarm at its most honest: tendrils, spines, and a temper, all pointed at the nearest hull. Cruiser class, 3 command points, 190 credits. Hull 150, shields 0, armor 20%, speed 4, turn 2, evasion 4. Carries Boarding tendrils (turret), Spine volley (prow). Regrows 7 hull at the end of each round. Fits 2 modules. Ability, Blood frenzy (cooldown 3): all of its weapons deal +30% damage this turn.
- Note: No shields at all: every point of damage is hull, and every round some of it grows back.
- Source: data.js HULLS.b_razor; ABILITIES.frenzy; faction The Chorus

**Chorus brood-sac** (`hull:b_brood`)
- Hook: The brood-sac: a mother carrying swarms.
- A brood-sac is a mother the size of a cruiser, carrying swarms the way other ships carry ammunition. Carrier class, 5 command points, 370 credits. Hull 200, shields 0, armor 20%, speed 2, turn 1, evasion 0. Carries Spine volley (prow), Spore cloud (turret). Regrows 8 hull at the end of each round. Hangar for 3 wings. Fits 3 modules. Ability, Launch squadron (cooldown 1): launches a replacement wing into a free hex beside it; a carrier starts each battle with its wings already in flight and holds one spare wing per hangar slot.
- Note: Keep it behind the line and let the wings spend themselves; the hull is the investment.
- Source: data.js HULLS.b_brood; ABILITIES.launch; faction The Chorus

**Chorus drone-spawn** (`hull:b_drone`)
- Hook: Drone-spawn: a mouth that will not stay broken.
- A drone-spawn is the swarm smallest true ship: a mouth, a tendril, and flesh that will not stay broken. Frigate class, 1 command points, 45 credits. Hull 46, shields 0, armor 5%, speed 5, turn 3, evasion 15. Carries Boarding tendrils (turret). Regrows 4 hull at the end of each round. Fits 1 module. Ability, Rapid regrowth (cooldown 3): regrows 25% of its hull at once.
- Note: Screens, scouts and finishes wounded ships; do not ask it to hold a line alone.
- Source: data.js HULLS.b_drone; ABILITIES.regrow; faction The Chorus

**Chorus spitter** (`hull:b_spitter`)
- Hook: A gland with a hull around it. It spits spines.
- The spitter is a gland with a hull around it, grown to throw spine volleys until something stops it. Destroyer class, 2 command points, 100 credits. Hull 82, shields 0, armor 10%, speed 4, turn 2, evasion 8. Carries Spine volley (turret), Spine volley (prow). Regrows 5 hull at the end of each round. Fits 1 module. Ability, Rapid regrowth (cooldown 3): regrows 25% of its hull at once.
- Note: No shields at all: every point of damage is hull, and every round some of it grows back.
- Source: data.js HULLS.b_spitter; ABILITIES.regrow; faction The Chorus

**Cordon column escort** (`hull:h_interdictor_e`)
- Hook: Flak added, hull lightened: an escort for the column.
- A variant of the Cordon destroyer. Destroyer class, 2 command points, 130 credits. Hull 60, shields 18 recharging 7 a round, armor 15%, speed 3, turn 2, evasion 10. Carries Ion cannon (prow), Plasma lance (turret), Picket lasers (turret). Fits 1 module. Ability, Ion pulse (cooldown 3): every enemy ship within 4 hexes loses half of each shield facing. It is earned by finishing the story arc of Hegemony Navy, never sold for renown.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULL_VARIANTS.h_interdictor_e; HULLS.h_interdictor_e (derived from HULLS.h_interdictor)

**Cordon destroyer** (`hull:h_interdictor`)
- Hook: The Cordon: ion fire that says no to shields.
- The Cordon exists to say no: no shields, no approach, no exceptions, delivered by ion fire. Destroyer class, 2 command points, 130 credits. Hull 74, shields 18 recharging 7 a round, armor 15%, speed 4, turn 2, evasion 10. Carries Ion cannon (prow), Plasma lance (turret). Fits 1 module. Ability, Ion pulse (cooldown 3): every enemy ship within 4 hexes loses half of each shield facing.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULLS.h_interdictor; ABILITIES.ionpulse; faction Hegemony Navy

**Daybreak-class dreadnought** (`hull:ascendant`)
- Hook: The Daybreak: one per fleet, and worth every point.
- The Daybreak is the Reach answer to a flagship: one per fleet at most, a dawn other fleets navigate by. Dreadnought class, 8 command points, 520 credits. Hull 370, shields 32 recharging 15 a round, armor 35%, speed 1, turn 1, evasion 0. Carries Heavy sear broadside (port broadside), Heavy sear broadside (starboard broadside), Sear turret (turret), Spark flak (turret). Fits 3 modules. Ability, Spinal cannon (cooldown 3): 40 damage to a hex 3 to 9 away and 20 to everything beside that hex, friends included. It flies as the Crusade flagship at a sector end, and Crusade fleets that earn the Dreadnought hulls legacy may field one of their own (see Legacy). Unique: a fleet may field only one.
- Note: A flagship and a battle objective in itself; build the fleet around killing or protecting it.
- Source: data.js HULLS.ascendant; ABILITIES.nova; faction Sunward Crusade

**Dominion dreadnought** (`hull:h_dominion`)
- Hook: The Dominion: capital plasma on both flanks.
- The Dominion is the wedge grown to capital scale: plasma on both flanks and the patience of a state behind it. Battleship class, 6 command points, 370 credits. Hull 230, shields 32 recharging 12 a round, armor 25%, speed 2, turn 1, evasion 0. Carries Heavy plasma lance (port broadside), Heavy plasma lance (starboard broadside), Ion cannon (prow), Picket lasers (turret). Hangar for 1 wings. Fits 3 modules. Ability, Launch squadron (cooldown 1): launches a replacement wing into a free hex beside it; a carrier starts each battle with its wings already in flight and holds one spare wing per hangar slot.
- Note: Keep it behind the line and let the wings spend themselves; the hull is the investment.
- Source: data.js HULLS.h_dominion; ABILITIES.launch; faction Hegemony Navy

**Eclipse flare** (`hull:d_jackal`)
- Hook: A flare: two null cannons and no fear of death.
- A flare is a mote grown ambitious: two null cannons and the patience of something that has died before. Destroyer class, 2 command points, 195 credits. Hull 110, shields 0, armor 25%, speed 3, turn 2, evasion 6. Carries Null cannon (turret), Null cannon (prow). Regrows 3 hull at the end of each round. Fits 1 module. Its mind re-streams from the Archive when it falls, so the hull can reassemble and return (see Archive restore, under Eclipse). Ability, Fold skip (cooldown 3): +25 evasion until its next turn and +2 movement at once.
- Note: Its jump makes it a flanker and a thief of objectives; rear arcs are where it earns.
- Source: data.js HULLS.d_jackal; ABILITIES.phase; faction Eclipse

**Eclipse mote** (`hull:d_scythe`)
- Hook: A mote: an old mind in a replaceable body.
- A mote is the smallest Eclipse frame: a mind older than nations in a body built to be replaced. Frigate class, 1 command points, 100 credits. Hull 56, shields 0, armor 20%, speed 4, turn 2, evasion 14. Carries Null cannon (turret). Regrows 3 hull at the end of each round. Fits 1 module. Its mind re-streams from the Archive when it falls, so the hull can reassemble and return (see Archive restore, under Eclipse). Ability, Fold skip (cooldown 3): +25 evasion until its next turn and +2 movement at once.
- Note: Screens, scouts and finishes wounded ships; do not ask it to hold a line alone.
- Source: data.js HULLS.d_scythe; ABILITIES.phase; faction Eclipse

**Eclipse zenith** (`hull:d_harvester`)
- Hook: The zenith: null turrets and a corona arc.
- The zenith is the Eclipse line ship: null fire on turrets, a corona arc in the prow, and a crew that streams back from the Archive. Cruiser class, 4 command points, 390 credits. Hull 145, shields 0, armor 30%, speed 2, turn 1, evasion 0. Carries Null cannon (turret), Null cannon (turret), Corona arc (prow), Null spire (turret). Regrows 4 hull at the end of each round. Fits 2 modules. Its mind re-streams from the Archive when it falls, so the hull can reassemble and return (see Archive restore, under Eclipse). Ability, Repair swarm (cooldown 3): restores 20% hull to the most damaged friendly ship within 3 hexes, itself included.
- Note: Heavy armor and no shields: lances and torpedoes are the honest way through.
- Source: data.js HULLS.d_harvester; ABILITIES.reclaim; faction Eclipse

**Fighter wing** (`hull:fighter`)
- Hook: Carrier wing: fast, fragile, first to die well.
- A fighter wing is a handful of small arguments with engines, flown by pilots too young to know better and too fast to argue with. Squadron class, 0 command points. Hull 18, shields 0, armor 0%, speed 6, turn 9, evasion 35. Carries Interceptor guns (turret). It flies as a squadron wing from a carrier hangar rather than as a ship of the line.
- Note: Launched from carriers, not bought: protect the carrier and the wing keeps coming back.
- Source: data.js HULLS.fighter; faction Unaligned

**Glasswright aperture** (`hull:i_carrier`)
- Hook: The aperture: wings pass through it like light.
- The aperture is a carrier built like an eye: wings pass through it the way light passes through glass. Carrier class, 5 command points, 340 credits. Hull 140, shields 28 recharging 10 a round, armor 5%, speed 4, turn 2, evasion 12. Carries Prism lance (prow), Needle beam (turret). Hangar for 2 wings. Fits 3 modules. Ability, Launch squadron (cooldown 1): launches a replacement wing into a free hex beside it; a carrier starts each battle with its wings already in flight and holds one spare wing per hangar slot.
- Note: Keep it behind the line and let the wings spend themselves; the hull is the investment.
- Source: data.js HULLS.i_carrier; ABILITIES.launch; faction The Glasswrights

**Glasswright lancet** (`hull:i_blade`)
- Hook: The lancet: shards, then one star torpedo.
- The lancet is the sliver grown deliberate: shards for the approach, a star torpedo for the sentence. Destroyer class, 2 command points, 170 credits. Hull 60, shields 16 recharging 8 a round, armor 0%, speed 6, turn 3, evasion 24. Carries Prism shards (prow), Star torpedo (prow). Fits 1 module. Ability, Phase jump (cooldown 3): jumps to any open hex within 3, straight past rocks and ships.
- Note: Its jump makes it a flanker and a thief of objectives; rear arcs are where it earns.
- Source: data.js HULLS.i_blade; ABILITIES.blink; faction The Glasswrights

**Glasswright prism** (`hull:i_song`)
- Hook: A prism: a lens that returns light as beams.
- A prism is a lens that learned to fight: it gathers light, argues with it, and returns it as beams. Cruiser class, 4 command points, 290 credits. Hull 90, shields 26 recharging 10 a round, armor 5%, speed 5, turn 2, evasion 16. Carries Prism lance (prow), Prism lance (prow), Needle beam (turret). Fits 2 modules. Ability, Shield surge (cooldown 4): every shield facing restored to full.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULLS.i_song; ABILITIES.surge; faction The Glasswrights

**Glasswright sliver** (`hull:i_wisp`)
- Hook: A sliver: almost nothing there, and it is fast.
- A sliver is a knife of crystal that thinks it is a ship: almost nothing there, and what is there is fast. Frigate class, 1 command points, 90 credits. Hull 30, shields 12 recharging 6 a round, armor 0%, speed 7, turn 3, evasion 28. Carries Prism shards (prow). Fits 1 module. Ability, Phase jump (cooldown 3): jumps to any open hex within 3, straight past rocks and ships.
- Note: Screens, scouts and finishes wounded ships; do not ask it to hold a line alone.
- Source: data.js HULLS.i_wisp; ABILITIES.blink; faction The Glasswrights

**Gun-hulk** (`hull:c_hulk_g`)
- Hook: The hangar welded shut, guns welded on, 20 more hull.
- A variant of the Hullbreaker hulk-carrier. Carrier class, 4 command points, 290 credits. Hull 190, shields 16 recharging 6 a round, armor 20%, speed 2, turn 1, evasion 0. Carries Scrap scatter gun (port broadside), Scrap scatter gun (starboard broadside), Junk turret (turret). Fits 2 modules. It is bought once with 25 renown, then sold in the shipyards of Ashfall Hullbreakers beside the standard hull at the same 290 credits.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULL_VARIANTS.c_hulk_g; HULLS.c_hulk_g (derived from HULLS.c_hulk)

**Harrow torpedo-destroyer** (`hull:vs_harrow_t`)
- Hook: Twin torpedo tubes, no turret: a one-shot assassin.
- A variant of the Harrow-class destroyer. Destroyer class, 2 command points, 130 credits. Hull 78, shields 14 recharging 6 a round, armor 15%, speed 4, turn 2, evasion 12. Carries Cinder torpedo (prow), Cinder torpedo (prow). Fits 1 module. Ability, Reload torpedoes (cooldown 3): its torpedo tubes are ready to fire again at once. It is bought once with 20 renown, then sold in the shipyards of Sunward Crusade beside the standard hull at the same 130 credits.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULL_VARIANTS.vs_harrow_t; HULLS.vs_harrow_t (derived from HULLS.harrow)

**Harrow-class destroyer** (`hull:harrow`)
- Hook: Crusade destroyer with a torpedo and a promise.
- A working destroyer of the Reach, built around one torpedo tube and one promise: get close enough once. Destroyer class, 2 command points, 130 credits. Hull 78, shields 14 recharging 6 a round, armor 15%, speed 4, turn 2, evasion 12. Carries Cinder torpedo (prow), Sear turret (turret). Fits 1 module. Ability, Reload torpedoes (cooldown 3): its torpedo tubes are ready to fire again at once.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULLS.harrow; ABILITIES.reload; faction Sunward Crusade

**Hearth-class carrier** (`hull:reliquary`)
- Hook: The Hearth: a carrier that brings its wings home.
- The Hearth carries the fleet children of the sky: wings in its hangars and room for the names of everyone they bring home. Carrier class, 4 command points, 325 credits. Hull 130, shields 22 recharging 9 a round, armor 15%, speed 2, turn 1, evasion 0. Carries Sear turret (turret), Spark flak (turret). Hangar for 2 wings. Fits 2 modules. Ability, Launch squadron (cooldown 1): launches a replacement wing into a free hex beside it; a carrier starts each battle with its wings already in flight and holds one spare wing per hangar slot.
- Note: Keep it behind the line and let the wings spend themselves; the hull is the investment.
- Source: data.js HULLS.reliquary; ABILITIES.launch; faction Sunward Crusade

**Hegemony picket** (`hull:h_picket`)
- Hook: Hegemony frigate: one identical node of the wedge.
- A Registry picket: one node of the wedge, identical to its sisters, exactly where the projection says it should be. Frigate class, 1 command points, 70 credits. Hull 40, shields 10 recharging 5 a round, armor 10%, speed 5, turn 3, evasion 18. Carries Plasma cannon (prow), Picket lasers (turret). Fits 1 module. Ability, Evasive burn (cooldown 3): +25 evasion until its next turn and +2 movement at once.
- Note: Screens, scouts and finishes wounded ships; do not ask it to hold a line alone.
- Source: data.js HULLS.h_picket; ABILITIES.evasive; faction Hegemony Navy

**Hullbreaker gutship** (`hull:c_reaver`)
- Hook: The gutship: cracks shells, argues with insides.
- The gutship is built to open things: a torpedo to crack the shell, scatter guns to argue with what is inside. Destroyer class, 2 command points, 110 credits. Hull 68, shields 10 recharging 5 a round, armor 10%, speed 5, turn 2, evasion 15. Carries Rattle-rocket pod (prow), Scrap scatter gun (starboard broadside). Fits 1 module. Ability, Reload torpedoes (cooldown 3): its torpedo tubes are ready to fire again at once.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULLS.c_reaver; ABILITIES.reload; faction Ashfall Hullbreakers

**Hullbreaker hulk-carrier** (`hull:c_hulk`)
- Hook: The hulk-carrier: a den that flies, wings in its ribs.
- The hulk-carrier is a welded-together den that happens to fly, with bomber wings nesting in its ribs. Carrier class, 4 command points, 290 credits. Hull 170, shields 16 recharging 6 a round, armor 20%, speed 2, turn 1, evasion 0. Carries Junk turret (turret), Junk turret (turret). Hangar for 2 wings. Fits 2 modules. Ability, Launch squadron (cooldown 1): launches a replacement wing into a free hex beside it; a carrier starts each battle with its wings already in flight and holds one spare wing per hangar slot.
- Note: Keep it behind the line and let the wings spend themselves; the hull is the investment.
- Source: data.js HULLS.c_hulk; ABILITIES.launch; faction Ashfall Hullbreakers

**Hullbreaker raider** (`hull:c_raider`)
- Hook: Hullbreaker frigate: fast, dark, already behind you.
- A raider is the pack in miniature: fast, dark, thin-skinned, and already behind you. Frigate class, 1 command points, 55 credits. Hull 46, shields 8 recharging 4 a round, armor 5%, speed 6, turn 3, evasion 28. Carries Autocannon (turret). Fits 1 module. Ability, Overburn (cooldown 3): +3 movement at once, and a ram this turn hits 50% harder.
- Note: Screens, scouts and finishes wounded ships; do not ask it to hold a line alone.
- Source: data.js HULLS.c_raider; ABILITIES.overburn; faction Ashfall Hullbreakers

**Hullbreaker wrecker** (`hull:c_marauder`)
- Hook: The wrecker: scatter broadsides and a rocket pod.
- A wrecker is a flying scrapyard with intent: scatter broadsides, a rocket pod, and claws for whatever survives. Cruiser class, 3 command points, 200 credits. Hull 120, shields 16 recharging 7 a round, armor 15%, speed 4, turn 2, evasion 6. Carries Scrap scatter gun (port broadside), Scrap scatter gun (starboard broadside), Rattle-rocket pod (prow), Chaff guns (turret). Fits 2 modules. Ability, Overburn (cooldown 3): +3 movement at once, and a ram this turn hits 50% harder.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULLS.c_marauder; ABILITIES.overburn; faction Ashfall Hullbreakers

**Mote sentinel** (`hull:d_scythe_s`)
- Hook: A mote with a null spire: a sentinel against wings.
- A variant of the Eclipse mote. Frigate class, 1 command points, 100 credits. Hull 56, shields 0, armor 20%, speed 4, turn 2, evasion 14. Carries Null cannon (turret), Null spire (turret). Regrows 3 hull at the end of each round. Fits 1 module. Its mind re-streams from the Archive when it falls, so the hull can reassemble and return (see Archive restore, under Eclipse). Ability, Fold skip (cooldown 3): +25 evasion until its next turn and +2 movement at once. It is bought once with 15 renown, then sold in the shipyards of Eclipse beside the standard hull at the same 100 credits.
- Note: Screens, scouts and finishes wounded ships; do not ask it to hold a line alone.
- Source: data.js HULL_VARIANTS.d_scythe_s; HULLS.d_scythe_s (derived from HULLS.d_scythe)

**Picket interceptor** (`hull:h_picket_i`)
- Hook: A turret laser and quicker feet for the picket screen.
- A variant of the Hegemony picket. Frigate class, 1 command points, 70 credits. Hull 40, shields 10 recharging 5 a round, armor 10%, speed 5, turn 3, evasion 24. Carries Plasma cannon (turret), Picket lasers (turret). Fits 1 module. Ability, Evasive burn (cooldown 3): +25 evasion until its next turn and +2 movement at once. It is bought once with 15 renown, then sold in the shipyards of Hegemony Navy beside the standard hull at the same 70 credits.
- Note: Screens, scouts and finishes wounded ships; do not ask it to hold a line alone.
- Source: data.js HULL_VARIANTS.h_picket_i; HULLS.h_picket_i (derived from HULLS.h_picket)

**Ringing aperture** (`hull:i_carrier_a`)
- Hook: A third wing, paid for in shields and speed.
- A variant of the Glasswright aperture. Carrier class, 5 command points, 340 credits. Hull 140, shields 22 recharging 10 a round, armor 5%, speed 3, turn 2, evasion 12. Carries Prism lance (prow), Needle beam (turret). Hangar for 3 wings. Fits 3 modules. Ability, Launch squadron (cooldown 1): launches a replacement wing into a free hex beside it; a carrier starts each battle with its wings already in flight and holds one spare wing per hangar slot. It is earned by finishing the story arc of The Glasswrights, never sold for renown.
- Note: Keep it behind the line and let the wings spend themselves; the hull is the investment.
- Source: data.js HULL_VARIANTS.i_carrier_a; HULLS.i_carrier_a (derived from HULLS.i_carrier)

**Sliver lancer** (`hull:i_wisp_l`)
- Hook: A prism lance where the shard cannon was.
- A variant of the Glasswright sliver. Frigate class, 1 command points, 90 credits. Hull 30, shields 12 recharging 6 a round, armor 0%, speed 7, turn 3, evasion 28. Carries Prism lance (prow). Fits 1 module. Ability, Phase jump (cooldown 3): jumps to any open hex within 3, straight past rocks and ships. It is bought once with 15 renown, then sold in the shipyards of The Glasswrights beside the standard hull at the same 90 credits.
- Note: Screens, scouts and finishes wounded ships; do not ask it to hold a line alone.
- Source: data.js HULL_VARIANTS.i_wisp_l; HULLS.i_wisp_l (derived from HULLS.i_wisp)

**Spitter stinger** (`hull:b_spitter_s`)
- Hook: A prow gun traded for tendrils: brutal up close.
- A variant of the Chorus spitter. Destroyer class, 2 command points, 100 credits. Hull 82, shields 0, armor 10%, speed 4, turn 2, evasion 8. Carries Spine volley (turret), Boarding tendrils (turret). Regrows 5 hull at the end of each round. Fits 1 module. Ability, Rapid regrowth (cooldown 3): regrows 25% of its hull at once. It is bought once with 15 renown, then sold in the shipyards of The Chorus beside the standard hull at the same 100 credits.
- Note: No shields at all: every point of damage is hull, and every round some of it grows back.
- Source: data.js HULL_VARIANTS.b_spitter_s; HULLS.b_spitter_s (derived from HULLS.b_spitter)

**Spore swarm** (`hull:spore`)
- Hook: Chorus swarm wing: shed, not flown.
- A spore swarm is not flown. It is shed, a cloud of hungry mouths that drifts toward warmth. Squadron class, 0 command points. Hull 26, shields 0, armor 0%, speed 5, turn 9, evasion 25. Carries Acid sacs (turret). It flies as a squadron wing from a carrier hangar rather than as a ship of the line.
- Note: Launched from carriers, not bought: protect the carrier and the wing keeps coming back.
- Source: data.js HULLS.spore; faction The Chorus

**Sun-eater bladeback** (`hull:b_razor_e`)
- Hook: A second spine volley, faster regrowth, one hex slower.
- A variant of the Chorus bladeback. Cruiser class, 3 command points, 190 credits. Hull 150, shields 0, armor 20%, speed 3, turn 2, evasion 4. Carries Spine volley (turret), Spine volley (prow). Regrows 9 hull at the end of each round. Fits 2 modules. Ability, Blood frenzy (cooldown 3): all of its weapons deal +30% damage this turn. It is earned by finishing the story arc of The Chorus, never sold for renown.
- Note: No shields at all: every point of damage is hull, and every round some of it grows back.
- Source: data.js HULL_VARIANTS.b_razor_e; HULLS.b_razor_e (derived from HULLS.b_razor)

**The Iron Mandate** (`hull:h_boss`)
- Hook: The Iron Mandate: the Registry final word.
- The Iron Mandate is the Registry final word in a battle: a super-dreadnought named like an order, because it is one. Super-dreadnought class, 12 command points. Hull 560, shields 40 recharging 10 a round, armor 30%, speed 1, turn 1, evasion 0. Carries Heavy plasma lance (port broadside), Heavy plasma lance (starboard broadside), Plasma lance (turret), Ion cannon (prow), Picket lasers (turret). Ability, Spinal cannon (cooldown 3): 40 damage to a hex 3 to 9 away and 20 to everything beside that hex, friends included. It is a boss hull: the enemy flagship of its faction, met at the end of a sector, not a shipyard purchase.
- Note: A flagship and a battle objective in itself; build the fleet around killing or protecting it.
- Source: data.js HULLS.h_boss; ABILITIES.nova; faction Hegemony Navy

**The Ninefold Maw** (`hull:b_boss`)
- Hook: The Ninefold Maw: nine throats, one appetite.
- The Ninefold Maw is the swarm grown to titan scale: nine throats, one appetite, and a hangar full of hunger. Colossus class, 12 command points. Hull 650, shields 0, armor 25%, speed 2, turn 1, evasion 0. Carries Spine volley (prow), Spine volley (prow), Boarding tendrils (turret), Spore cloud (turret). Regrows 20 hull at the end of each round. Hangar for 3 wings. Ability, Launch squadron (cooldown 1): launches a replacement wing into a free hex beside it; a carrier starts each battle with its wings already in flight and holds one spare wing per hangar slot. It is a boss hull: the enemy flagship of its faction, met at the end of a sector, not a shipyard purchase.
- Note: A flagship and a battle objective in itself; build the fleet around killing or protecting it.
- Source: data.js HULLS.b_boss; ABILITIES.launch; faction The Chorus

**The Unfinished** (`hull:i_boss`)
- Hook: The Unfinished: an apology with guns, Lattice-built.
- The Unfinished is built around the largest surviving piece of the Lattice, and the Glasswrights fly it like an apology with guns. Lattice-ship class, 11 command points. Hull 470, shields 34 recharging 14 a round, armor 20%, speed 3, turn 2, evasion 6. Carries Prism lance (prow), Prism lance (prow), Prism lance (turret), Needle beam (turret), Mirror veil (turret). Ability, Shield surge (cooldown 4): every shield facing restored to full. It is a boss hull: the enemy flagship of its faction, met at the end of a sector, not a shipyard purchase.
- Note: A flagship and a battle objective in itself; build the fleet around killing or protecting it.
- Source: data.js HULLS.i_boss; ABILITIES.surge; faction The Glasswrights

**The Unsetting** (`hull:d_boss`)
- Hook: The Unsetting: the fleet memory, made hull.
- The Unsetting is an archive that fights: the fleet memory made hull, named for the sun that never sets because it never rose again. Archive-ship class, 12 command points. Hull 480, shields 0, armor 35%, speed 1, turn 1, evasion 0. Carries Null cannon (turret), Null cannon (turret), Corona arc (prow), Null shredder (turret). Regrows 8 hull at the end of each round. Ability, Spinal cannon (cooldown 3): 40 damage to a hex 3 to 9 away and 20 to everything beside that hex, friends included. It is a boss hull: the enemy flagship of its faction, met at the end of a sector, not a shipyard purchase.
- Note: A flagship and a battle objective in itself; build the fleet around killing or protecting it.
- Source: data.js HULLS.d_boss; ABILITIES.nova; faction Eclipse

**Trophy wrecker** (`hull:c_marauder_g`)
- Hook: A second rocket pod where the flak was. Slower, meaner.
- A variant of the Hullbreaker wrecker. Cruiser class, 3 command points, 200 credits. Hull 120, shields 16 recharging 7 a round, armor 15%, speed 3, turn 2, evasion 6. Carries Scrap scatter gun (port broadside), Scrap scatter gun (starboard broadside), Rattle-rocket pod (prow), Rattle-rocket pod (prow). Fits 2 modules. Ability, Overburn (cooldown 3): +3 movement at once, and a ram this turn hits 50% harder. It is earned by finishing the story arc of Ashfall Hullbreakers, never sold for renown.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULL_VARIANTS.c_marauder_g; HULLS.c_marauder_g (derived from HULLS.c_marauder)

**Turret gutship** (`hull:c_reaver_t`)
- Hook: Scatter on a turret: the gutship stops caring about facing.
- A variant of the Hullbreaker gutship. Destroyer class, 2 command points, 110 credits. Hull 68, shields 10 recharging 5 a round, armor 10%, speed 5, turn 2, evasion 15. Carries Rattle-rocket pod (prow), Scrap scatter gun (turret). Fits 1 module. Ability, Reload torpedoes (cooldown 3): its torpedo tubes are ready to fire again at once. It is bought once with 15 renown, then sold in the shipyards of Ashfall Hullbreakers beside the standard hull at the same 110 credits.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULL_VARIANTS.c_reaver_t; HULLS.c_reaver_t (derived from HULLS.c_reaver)

**Turreted zenith** (`hull:d_harvester_t`)
- Hook: The corona arc on a turret: it need not turn to fire.
- A variant of the Eclipse zenith. Cruiser class, 4 command points, 390 credits. Hull 145, shields 0, armor 30%, speed 2, turn 1, evasion 0. Carries Null cannon (turret), Corona arc (turret), Null spire (turret). Regrows 4 hull at the end of each round. Fits 2 modules. Its mind re-streams from the Archive when it falls, so the hull can reassemble and return (see Archive restore, under Eclipse). Ability, Repair swarm (cooldown 3): restores 20% hull to the most damaged friendly ship within 3 hexes, itself included. It is bought once with 30 renown, then sold in the shipyards of Eclipse beside the standard hull at the same 390 credits.
- Note: Heavy armor and no shields: lances and torpedoes are the honest way through.
- Source: data.js HULL_VARIANTS.d_harvester_t; HULLS.d_harvester_t (derived from HULLS.d_harvester)

**Vanguard cruiser** (`hull:h_vanguard`)
- Hook: A cruiser that carries a wing and holds the line.
- A vanguard cruiser is a carrier that refused to be only a carrier: guns forward, a wing in reserve, a place in the line. Cruiser class, 4 command points, 250 credits. Hull 140, shields 24 recharging 10 a round, armor 20%, speed 3, turn 1, evasion 4. Carries Plasma lance (turret), Plasma lance (turret), Ion cannon (prow). Hangar for 1 wings. Fits 2 modules. Ability, Launch squadron (cooldown 1): launches a replacement wing into a free hex beside it; a carrier starts each battle with its wings already in flight and holds one spare wing per hangar slot.
- Note: Keep it behind the line and let the wings spend themselves; the hull is the investment.
- Source: data.js HULLS.h_vanguard; ABILITIES.launch; faction Hegemony Navy

**Vanguard gunship** (`hull:h_vanguard_g`)
- Hook: The hangar traded for a third plasma turret.
- A variant of the Vanguard cruiser. Cruiser class, 4 command points, 250 credits. Hull 140, shields 24 recharging 10 a round, armor 20%, speed 3, turn 1, evasion 4. Carries Plasma lance (turret), Plasma lance (turret), Plasma lance (turret), Ion cannon (prow). Fits 2 modules. It is bought once with 25 renown, then sold in the shipyards of Hegemony Navy beside the standard hull at the same 250 credits.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULL_VARIANTS.h_vanguard_g; HULLS.h_vanguard_g (derived from HULLS.h_vanguard)

**Vigil gun-cruiser** (`hull:vs_penitent_g`)
- Hook: The lance traded for a third battery: guns in every arc.
- A variant of the Vigil-class cruiser. Cruiser class, 3 command points, 200 credits. Hull 120, shields 20 recharging 8 a round, armor 20%, speed 3, turn 2, evasion 5. Carries Sear battery (port broadside), Sear battery (starboard broadside), Sear battery (turret). Fits 2 modules. Ability, Concentrated fire (cooldown 3): all of its weapons deal +30% damage this turn. It is bought once with 25 renown, then sold in the shipyards of Sunward Crusade beside the standard hull at the same 200 credits.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULL_VARIANTS.vs_penitent_g; HULLS.vs_penitent_g (derived from HULLS.penitent)

**Vigil lance-cruiser** (`hull:vs_penitent_l`)
- Hook: Two prow lances: the heavy punch points one way.
- A variant of the Vigil-class cruiser. Cruiser class, 3 command points, 200 credits. Hull 120, shields 20 recharging 8 a round, armor 20%, speed 3, turn 2, evasion 5. Carries Oath lance (prow), Oath lance (prow), Sear battery (turret). Fits 2 modules. Ability, Concentrated fire (cooldown 3): all of its weapons deal +30% damage this turn. It is earned by finishing the story arc of Sunward Crusade, never sold for renown.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULL_VARIANTS.vs_penitent_l; HULLS.vs_penitent_l (derived from HULLS.penitent)

**Vigil-class cruiser** (`hull:penitent`)
- Hook: The Vigil: broadsides both flanks, lance in the prow.
- The Vigil is the line made solid: broadsides on both flanks and an oath lance in the prow, built to move up and stay. Cruiser class, 3 command points, 200 credits. Hull 120, shields 20 recharging 8 a round, armor 20%, speed 3, turn 2, evasion 5. Carries Sear battery (port broadside), Sear battery (starboard broadside), Oath lance (prow). Fits 2 modules. Ability, Concentrated fire (cooldown 3): all of its weapons deal +30% damage this turn.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULLS.penitent; ABILITIES.focus; faction Sunward Crusade

**Warded prism** (`hull:i_song_w`)
- Hook: Warded: stronger shields, one lance on a turret.
- A variant of the Glasswright prism. Cruiser class, 4 command points, 290 credits. Hull 90, shields 34 recharging 10 a round, armor 5%, speed 5, turn 2, evasion 16. Carries Prism lance (turret), Needle beam (turret). Fits 2 modules. Ability, Shield surge (cooldown 4): every shield facing restored to full. It is bought once with 25 renown, then sold in the shipyards of The Glasswrights beside the standard hull at the same 290 credits.
- Note: A line hull: it earns its points in formation, firing with its squadron, not alone.
- Source: data.js HULL_VARIANTS.i_song_w; HULLS.i_song_w (derived from HULLS.i_song)

**Warden-class frigate** (`hull:warden`)
- Hook: Crusade frigate: cheap, quick, and first into the line.
- The smallest oath-bound hull on the Cinder Line: a picket with a chalked roll of names along its spine and guns laid by hand. Frigate class, 1 command points, 70 credits. Hull 45, shields 10 recharging 5 a round, armor 10%, speed 5, turn 3, evasion 20. Carries Sear repeater (prow), Spark flak (turret). Fits 1 module. Ability, Evasive burn (cooldown 3): +25 evasion until its next turn and +2 movement at once.
- Note: Screens, scouts and finishes wounded ships; do not ask it to hold a line alone.
- Source: data.js HULLS.warden; ABILITIES.evasive; faction Sunward Crusade

**Warlord's Pyre-Barge** (`hull:c_boss`)
- Hook: The Pyre-Barge: welded from beaten enemies.
- The Pyre-Barge is welded from the hulls of beaten enemies, and its warlord intends to add yours. War-barge class, 10 command points. Hull 600, shields 30 recharging 8 a round, armor 25%, speed 2, turn 1, evasion 0. Carries Scrap scatter gun (port broadside), Scrap scatter gun (starboard broadside), Heavy rocket pod (prow), Chaff guns (turret). Hangar for 2 wings. Ability, Launch squadron (cooldown 1): launches a replacement wing into a free hex beside it; a carrier starts each battle with its wings already in flight and holds one spare wing per hangar slot. It is a boss hull: the enemy flagship of its faction, met at the end of a sector, not a shipyard purchase.
- Note: A flagship and a battle objective in itself; build the fleet around killing or protecting it.
- Source: data.js HULLS.c_boss; ABILITIES.launch; faction Ashfall Hullbreakers

### Weapons (25)

**Autocannon** (`weapon:autocannon`)
- Hook: Three light shots, honest range: the frontier repeater.
- A rapid repeater, the oldest gun on the frontier: cheap, honest, and always loaded. Battery weapon, the standard gun kind: it fires in the broadside and turret volleys that most hulls are built around. Fires 3 shots of 5 damage. Range 4, most accurate inside 2 hexes: base accuracy 80, losing 8 per hex beyond that. Critical chance 5%. Names vary by fleet: Sunward Crusade call it the sear repeater; Ashfall Hullbreakers call it the autocannon.
- Source: data.js W.autocannon; FAC_WNAMES; battle.js weapon resolution

**Bile spray** (`weapon:bioplasma`)
- Hook: The spine volley: two living shots that bite past armor.
- A volley of living spines and bile, spat from glands along the hull. Chorus crews call it the spine volley. Bio-weapon: grown armament, carried by Chorus hulls. Fires 2 shots of 12 damage. Range 4, most accurate inside 3 hexes: base accuracy 74, losing 8 per hex beyond that. Critical chance 8%. 20% of its damage passes straight through shields. Names vary by fleet: The Chorus call it the spine volley.
- Source: data.js W.bioplasma; FAC_WNAMES; battle.js weapon resolution

**Boarding tendrils** (`weapon:tendril`)
- Hook: Range one: tendrils hold the target and open it.
- Boarding tendrils do not shoot a ship; they hold it and open it. Bio-weapon: grown armament, carried by Chorus hulls. Fires 2 shots of 13 damage. Range 1, most accurate inside 1 hexes: base accuracy 85, losing 0 per hex beyond that. Critical chance 12%. 50% of its damage passes straight through shields. Names vary by fleet: The Chorus call it the boarding tendrils.
- Source: data.js W.tendril; FAC_WNAMES; battle.js weapon resolution

**Bomb payload** (`weapon:bombs`)
- Hook: Bomber weight: slow damage that ignores most armor.
- A bomb payload is dropped, not fired: weight, falling toward a hull. Squadron weapon: only carrier wings carry it, and it is worked into their strike, not a ship volley. Fires 2 shots of 9 damage. Range 1, most accurate inside 1 hexes: base accuracy 78, losing 0 per hex beyond that. Critical chance 10%. 60% of its damage passes straight through shields. Damage is multiplied 0.2x against squadrons.
- Source: data.js W.bombs; FAC_WNAMES; battle.js weapon resolution

**Corona arc** (`weapon:doom`)
- Hook: The corona arc: one enormous hit, then a reload.
- The corona arc is a piece of a star, held in a ring and let go once, hard. Lance weapon: a single heavy beam built to punch through to the hull of big ships. Fires 1 shot of 40 damage. Range 5, most accurate inside 4 hexes: base accuracy 78, losing 6 per hex beyond that. Critical chance 12%. 60% of its damage passes straight through shields. After firing it needs 2 turns before it can fire again. Names vary by fleet: Eclipse call it the corona arc.
- Source: data.js W.doom; FAC_WNAMES; battle.js weapon resolution

**Dorsal turret** (`weapon:turret`)
- Hook: Two steady shots that cover every arc.
- A dorsal turret, the gun that covers the arcs the broadsides cannot. Battery weapon, the standard gun kind: it fires in the broadside and turret volleys that most hulls are built around. Fires 2 shots of 8 damage. Range 5, most accurate inside 3 hexes: base accuracy 74, losing 8 per hex beyond that. Critical chance 5%. Names vary by fleet: Sunward Crusade call it the sear turret; Ashfall Hullbreakers call it the junk turret; The Glasswrights call it the needle beam.
- Source: data.js W.turret; FAC_WNAMES; battle.js weapon resolution

**Flak battery** (`weapon:flak`)
- Hook: Point defense. It never fires on ships; it guards against wings.
- A spray of short-fused shells meant to fill the space a squadron has to cross. Point-defense kind: the guard kind. The flak battery, the null sentries and the spore cloud are the same kind under three names, and every rule that speaks of one speaks of all three. Point defense: this mount never fires in a volley and never shoots at ships. It stands guard instead, shooting at incoming squadrons, rockets and boarding craft with 3 shots of 3 damage out to range 2, dealing 3x damage against squadrons and only 60% against capital ships. One point-defense mount is enough to keep the guard; a second adds nothing to it. Names vary by fleet: Sunward Crusade call it the spark flak; Hegemony Navy call it the picket lasers; Ashfall Hullbreakers call it the chaff guns; The Glasswrights call it the mirror veil; Eclipse call it the null shredder.
- Source: data.js W.flak; FAC_WNAMES; battle.js weapon resolution

**Gun battery** (`weapon:battery`)
- Hook: The standard broadside gun: four shots, mid range.
- The standard broadside gun of the line, laid by hand on Crusade decks. Battery weapon, the standard gun kind: it fires in the broadside and turret volleys that most hulls are built around. Fires 4 shots of 6 damage. Range 5, most accurate inside 3 hexes: base accuracy 72, losing 8 per hex beyond that. Critical chance 5%. Names vary by fleet: Sunward Crusade call it the sear battery.
- Source: data.js W.battery; FAC_WNAMES; battle.js weapon resolution

**Heavy gun battery** (`weapon:hbattery`)
- Hook: Five heavy shots per volley: the battleship argument.
- The heavy broadside: more barrels, heavier shells, the argument a battleship makes. Battery weapon, the standard gun kind: it fires in the broadside and turret volleys that most hulls are built around. Fires 5 shots of 7 damage. Range 5, most accurate inside 3 hexes: base accuracy 72, losing 8 per hex beyond that. Critical chance 6%. Names vary by fleet: Sunward Crusade call it the heavy sear broadside.
- Source: data.js W.hbattery; FAC_WNAMES; battle.js weapon resolution

**Heavy pulse laser** (`weapon:hturbo`)
- Hook: Three heavy pulses at the longest laser reach.
- The heavy pulse laser: the pulse beaten bigger, for capital work. Battery weapon, the standard gun kind: it fires in the broadside and turret volleys that most hulls are built around. Fires 3 shots of 9 damage. Range 6, most accurate inside 4 hexes: base accuracy 72, losing 7 per hex beyond that. Critical chance 6%. Names vary by fleet: Hegemony Navy call it the heavy plasma lance.
- Source: data.js W.hturbo; FAC_WNAMES; battle.js weapon resolution

**Heavy torpedoes** (`weapon:htorp`)
- Hook: Two heavy torpedoes per salvo, then a reload.
- Heavy torpedoes: two tubes of the biggest argument a Hullbreaker can bolt on. Torpedo weapon: a slow, heavy strike that has to reload between shots. Fires 2 shots of 34 damage. Range 6, most accurate inside 6 hexes: base accuracy 60, losing 0 per hex beyond that. Critical chance 15%. 30% of its damage passes straight through shields. After firing it needs 2 turns before it can fire again. A target evasion counts 2x against it, so nimble ships dodge it well. Names vary by fleet: Ashfall Hullbreakers call it the heavy rocket pod.
- Source: data.js W.htorp; FAC_WNAMES; battle.js weapon resolution

**Interceptor guns** (`weapon:guns`)
- Hook: Fighter guns: light, close, and cruel to other wings.
- Interceptor guns: the quick, light cannon a fighter wing strafes with. Squadron weapon: only carrier wings carry it, and it is worked into their strike, not a ship volley. Fires 3 shots of 4 damage. Range 1, most accurate inside 1 hexes: base accuracy 82, losing 0 per hex beyond that. Damage is multiplied 2.2x against squadrons. It manages only 50% of its damage against capital ships.
- Source: data.js W.guns; FAC_WNAMES; battle.js weapon resolution

**Ion cannon** (`weapon:ion`)
- Hook: Built to strip shields: two and a half times shield damage.
- An ion cannon does not wound a ship; it unmakes the shield standing in front of it. Lance weapon: a single heavy beam built to punch through to the hull of big ships. Fires 1 shot of 12 damage. Range 6, most accurate inside 5 hexes: base accuracy 80, losing 6 per hex beyond that. Critical chance 4%. It deals 2.5x damage to shields. Names vary by fleet: Hegemony Navy call it the ion cannon.
- Source: data.js W.ion; FAC_WNAMES; battle.js weapon resolution

**Lance array** (`weapon:lance`)
- Hook: One beam, long reach, most of it through shields.
- A beam that arrives before its sound would: one line of light, one hole. Lance weapon: a single heavy beam built to punch through to the hull of big ships. Fires 1 shot of 20 damage. Range 7, most accurate inside 6 hexes: base accuracy 82, losing 6 per hex beyond that. Critical chance 10%. 60% of its damage passes straight through shields. Names vary by fleet: Sunward Crusade call it the oath lance.
- Source: data.js W.lance; FAC_WNAMES; battle.js weapon resolution

**Laser cannon** (`weapon:laser`)
- Hook: Two accurate shots at short to mid range.
- A plain, dependable cannon of light, standard across a dozen fleets. Battery weapon, the standard gun kind: it fires in the broadside and turret volleys that most hulls are built around. Fires 2 shots of 7 damage. Range 4, most accurate inside 3 hexes: base accuracy 80, losing 8 per hex beyond that. Critical chance 5%. Names vary by fleet: Hegemony Navy call it the plasma cannon.
- Source: data.js W.laser; FAC_WNAMES; battle.js weapon resolution

**Null cannon** (`weapon:gauss`)
- Hook: Three null shots, over half of each straight through shields.
- A null cannon fires mass that is barely there, and arrives the same way through shields and plate. Null weapon: its damage is built to pass through defenses that stop ordinary fire. Fires 3 shots of 6 damage. Range 5, most accurate inside 3 hexes: base accuracy 74, losing 8 per hex beyond that. Critical chance 5%. 60% of its damage passes straight through shields. Names vary by fleet: Eclipse call it the null cannon.
- Source: data.js W.gauss; FAC_WNAMES; battle.js weapon resolution

**Null sentries** (`weapon:gsentry`)
- Hook: Point defense, Eclipse style: null sentries on watch.
- Null sentries are small patient guns that wait for something small to come close. Point-defense kind: the guard kind. The flak battery, the null sentries and the spore cloud are the same kind under three names, and every rule that speaks of one speaks of all three. Point defense: this mount never fires in a volley and never shoots at ships. It stands guard instead, shooting at incoming squadrons, rockets and boarding craft with 3 shots of 3 damage out to range 2, dealing 3x damage against squadrons and only 60% against capital ships. One point-defense mount is enough to keep the guard; a second adds nothing to it. Names vary by fleet: Eclipse call it the null spire.
- Source: data.js W.gsentry; FAC_WNAMES; battle.js weapon resolution

**Prism lance** (`weapon:pulsar`)
- Hook: Two prism beams that cut deep past shields.
- A prism lance: a white core beam that splits into a rainbow fringe and leaves glassy scars. Lance weapon: a single heavy beam built to punch through to the hull of big ships. Fires 2 shots of 12 damage. Range 6, most accurate inside 5 hexes: base accuracy 80, losing 6 per hex beyond that. Critical chance 10%. 60% of its damage passes straight through shields. Names vary by fleet: The Glasswrights call it the prism lance.
- Source: data.js W.pulsar; FAC_WNAMES; battle.js weapon resolution

**Pulse laser** (`weapon:turbo`)
- Hook: Two heavier pulses, light blue over Hegemony hulls.
- A pulse laser, firing in hard beats; Hegemony ships light theirs light blue. Battery weapon, the standard gun kind: it fires in the broadside and turret volleys that most hulls are built around. Fires 2 shots of 9 damage. Range 5, most accurate inside 3 hexes: base accuracy 74, losing 8 per hex beyond that. Critical chance 5%. Names vary by fleet: Hegemony Navy call it the plasma lance.
- Source: data.js W.turbo; FAC_WNAMES; battle.js weapon resolution

**Scatter cannons** (`weapon:scatter`)
- Hook: Five pellets at knife range. No reach, no apology.
- Scatter cannons are sawn-off violence: many pellets, no manners, no range. Battery weapon, the standard gun kind: it fires in the broadside and turret volleys that most hulls are built around. Fires 5 shots of 5 damage. Range 3, most accurate inside 2 hexes: base accuracy 78, losing 10 per hex beyond that. Critical chance 6%. Names vary by fleet: Ashfall Hullbreakers call it the scrap scatter gun.
- Source: data.js W.scatter; FAC_WNAMES; battle.js weapon resolution

**Shard cannon** (`weapon:shard`)
- Hook: Three crystal shots that also trouble squadrons.
- A shard cannon fires slivers of the hull own crystal kin, ground to edges. Battery weapon, the standard gun kind: it fires in the broadside and turret volleys that most hulls are built around. Fires 3 shots of 6 damage. Range 4, most accurate inside 2 hexes: base accuracy 80, losing 8 per hex beyond that. Critical chance 6%. Damage is multiplied 1.6x against squadrons. Names vary by fleet: The Glasswrights call it the prism shards.
- Source: data.js W.shard; FAC_WNAMES; battle.js weapon resolution

**Spore burst** (`weapon:sporeb`)
- Hook: Acid sacs: a wing weapon that keeps eating.
- Acid sacs burst on contact and keep eating after the swarm has passed. Squadron weapon: only carrier wings carry it, and it is worked into their strike, not a ship volley. Fires 2 shots of 10 damage. Range 1, most accurate inside 1 hexes: base accuracy 78, losing 0 per hex beyond that. Critical chance 8%. 60% of its damage passes straight through shields. Damage is multiplied 0.3x against squadrons. Names vary by fleet: The Chorus call it the acid sacs.
- Source: data.js W.sporeb; FAC_WNAMES; battle.js weapon resolution

**Spore drifts** (`weapon:spores`)
- Hook: Point defense, grown: a spore cloud that bursts on wings.
- A drifting cloud of spores that bursts around anything small enough to fly through it. Point-defense kind: the guard kind. The flak battery, the null sentries and the spore cloud are the same kind under three names, and every rule that speaks of one speaks of all three. Point defense: this mount never fires in a volley and never shoots at ships. It stands guard instead, shooting at incoming squadrons, rockets and boarding craft with 3 shots of 4 damage out to range 2, dealing 3x damage against squadrons and only 60% against capital ships. One point-defense mount is enough to keep the guard; a second adds nothing to it. Names vary by fleet: The Chorus call it the spore cloud.
- Source: data.js W.spores; FAC_WNAMES; battle.js weapon resolution

**Star torpedo** (`weapon:startorp`)
- Hook: One star torpedo: hard to dodge, deep through shields.
- A star torpedo rides a sliver of stored starlight, and is very hard to shake off. Torpedo weapon: a slow, heavy strike that has to reload between shots. Fires 1 shot of 38 damage. Range 5, most accurate inside 5 hexes: base accuracy 66, losing 0 per hex beyond that. Critical chance 15%. 40% of its damage passes straight through shields. After firing it needs 2 turns before it can fire again. A target evasion counts 2x against it, so nimble ships dodge it well. Names vary by fleet: The Glasswrights call it the star torpedo.
- Source: data.js W.startorp; FAC_WNAMES; battle.js weapon resolution

**Torpedo salvo** (`weapon:torp`)
- Hook: One huge hit, then a reload. Evasion counts double against it.
- A torpedo is a small ship that hates one other ship very much, briefly. Torpedo weapon: a slow, heavy strike that has to reload between shots. Fires 1 shot of 42 damage. Range 6, most accurate inside 6 hexes: base accuracy 64, losing 0 per hex beyond that. Critical chance 15%. 30% of its damage passes straight through shields. After firing it needs 2 turns before it can fire again. A target evasion counts 2x against it, so nimble ships dodge it well. Names vary by fleet: Sunward Crusade call it the cinder torpedo; Ashfall Hullbreakers call it the rattle-rocket pod.
- Source: data.js W.torp; FAC_WNAMES; battle.js weapon resolution

### Boons (core protocols, duos, legendaries) (48)

**Afterburners** (`boon:r_burn`)
- Hook: Rook protocol: the whole fleet, one step faster.
- A protocol of R-5 Rook, the Breaker. Rook, the Breaker, drifts in the wreck fields, hunted by the Hullbreakers who think it makes its holder unstoppable. Its protocols arrive first. Effect: +1 speed across the fleet. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.r_burn; PATRONS.rook

**Anchored Volley** (`boon:i_still`)
- Hook: Kharon protocol: hold still, hit harder.
- A protocol of K-1 Kharon, the Unbent. Kharon, the Unbent, never left the dead system, and Eclipse learned endurance from it. Its protocols hold. Effect: A ship that has not moved this activation deals +25% damage with broadsides and batteries. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.i_still; PATRONS.iron

**Arc Discharge** (`boon:s_arc`)
- Hook: Vyre protocol: broken shields bite their owners.
- A protocol of V-2 Vyre, the Storm Queen. Vyre, the Storm Queen, is the core the Registry captured and studied. Its protocols are shields, kept and broken. Effect: When your fire knocks out an enemy shield facing, its generator shorts and the ship takes 9 hull damage. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.s_arc; PATRONS.storm

**Battering Prow** (`boon:r_prow`)
- Hook: Rook protocol: rams that take half a hull.
- A protocol of R-5 Rook, the Breaker. Rook, the Breaker, drifts in the wreck fields, hunted by the Hullbreakers who think it makes its holder unstoppable. Its protocols arrive first. Effect: Rams deal +35% damage and can take up to 50% of a target hull, and the rammer recoil is halved. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.r_prow; PATRONS.rook

**Blind Spot** (`boon:a_rear`)
- Hook: Astra protocol: rear arcs are where ships die.
- A protocol of A-4 Astra, the Silent Star. Astra, the Silent Star, is the core the Glasswrights keep caged and throttled. Its protocols are one clean line of light. Effect: Hits on an enemy rear arc deal +25% damage. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.a_rear; PATRONS.star

**Boarding Frenzy** (`boon:h_board`)
- Hook: Crucible protocol: boarders that always leave a mark.
- A protocol of H-3 Crucible, "the Hunger Below". Crucible, the Hunger Below, powered the Fleshwrights vats; the swarm grew around it and feeds on it still. Its protocols feed. Effect: Boarding parties fight as 25% more crew, and a failed boarding always sabotages a system on the target. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.h_board; PATRONS.hunger

**Broadside Inferno** (`boon:d_inferno`)
- Hook: Duo, Seren and Kharon: broadsides that burn.
- A duo protocol of S-6 Seren, the Last Flame and K-1 Kharon, the Unbent, offered when a fleet runs in sync with both cores at once. Effect: Broadside hits have a 40% chance to start a fire, and your fires burn hotter, 10 a turn, and a turn longer. Duo protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.d_inferno; PATRONS.ember+iron

**Brood Harvest** (`boon:h_brood`)
- Hook: Crucible gift: capital kills hatch free wings.
- A protocol of H-3 Crucible, "the Hunger Below". Crucible, the Hunger Below, powered the Fleshwrights vats; the swarm grew around it and feeds on it still. Its protocols feed. Effect: Each enemy capital ship your fleet destroys lets your nearest carrier launch a free wing, if it has a free hex beside it. A fixed gift protocol: it does not scale with rarity.
- Source: data.js BOONS.h_brood; PATRONS.hunger

**Burning Swarm** (`boon:d_burnswarm`)
- Hook: Duo, Crucible and Seren: wings that set fires.
- A duo protocol of H-3 Crucible, "the Hunger Below" and S-6 Seren, the Last Flame, offered when a fleet runs in sync with both cores at once. Effect: Squadron hits have a 30% chance to start a fire. Duo protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.d_burnswarm; PATRONS.hunger+ember

**Capacitor Surge** (`boon:s_cap`)
- Hook: Vyre protocol: bigger shields, fleet-wide.
- A protocol of V-2 Vyre, the Storm Queen. Vyre, the Storm Queen, is the core the Registry captured and studied. Its protocols are shields, kept and broken. Effect: Shields +20% across the fleet. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.s_cap; PATRONS.storm

**Chain Lightning** (`boon:s_chain`)
- Hook: Vyre gift: a broken facing takes its neighbors down.
- A protocol of V-2 Vyre, the Storm Queen. Vyre, the Storm Queen, is the core the Registry captured and studied. Its protocols are shields, kept and broken. Effect: When your fire knocks out an enemy shield facing, the two facings beside it lose a third of their strength. A fixed gift protocol: it does not scale with rarity.
- Source: data.js BOONS.s_chain; PATRONS.storm

**Chain Reaction** (`boon:e_chain`)
- Hook: Seren protocol: the dead explode.
- A protocol of S-6 Seren, the Last Flame. Seren, the Last Flame, drifted to the Reach outer belt, and the Crusade weapons came from studying it. Its protocols burn. Effect: Enemy ships you destroy explode, dealing 20 damage to every enemy within 2 hexes. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.e_chain; PATRONS.ember

**Evasive Burn** (`boon:r_jink`)
- Hook: Rook protocol: move hard, become a rumor.
- A protocol of R-5 Rook, the Breaker. Rook, the Breaker, drifts in the wreck fields, hunted by the Hullbreakers who think it makes its holder unstoppable. Its protocols arrive first. Effect: Ships that moved 3 or more hexes are 15 harder to hit until their next turn. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.r_jink; PATRONS.rook

**Eye of the Storm** (`boon:L_storm`)
- Hook: Legendary Vyre: shields reborn every turn.
- The legendary protocol of V-2 Vyre, the Storm Queen. Vyre, the Storm Queen, is the core the Registry captured and studied. Its protocols are shields, kept and broken. Effect: Every shield facing on every ship refills completely at the start of each of your turns. Legendary protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.L_storm; PATRONS.storm

**Feast on the Fallen** (`boon:h_feast`)
- Hook: Crucible protocol: kills feed the carrier.
- A protocol of H-3 Crucible, "the Hunger Below". Crucible, the Hunger Below, powered the Fleshwrights vats; the swarm grew around it and feeds on it still. Its protocols feed. Effect: When your squadron destroys a target, its carrier gains a spare wing and repairs 5% of its hull. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.h_feast; PATRONS.hunger

**Fortress** (`boon:d_bastion`)
- Hook: Duo, Kharon and Vyre: brace, and be whole.
- A duo protocol of K-1 Kharon, the Unbent and V-2 Vyre, the Storm Queen, offered when a fleet runs in sync with both cores at once. Effect: Bracing also refills every shield facing and blocks an extra 10% of hull damage. Duo protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.d_bastion; PATRONS.iron+storm

**Funeral Pyre** (`boon:e_hunt`)
- Hook: Seren protocol: the wounded stay wounded, and die.
- A protocol of S-6 Seren, the Last Flame. Seren, the Last Flame, drifted to the Reach outer belt, and the Crusade weapons came from studying it. Its protocols burn. Effect: +20% damage against ships below half hull, and ships you hit while they are below half hull can no longer regrow hull or reanimate. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.e_hunt; PATRONS.ember

**Hardened Chitin** (`boon:h_chitin`)
- Hook: Crucible protocol: tougher wings.
- A protocol of H-3 Crucible, "the Hunger Below". Crucible, the Hunger Below, powered the Fleshwrights vats; the swarm grew around it and feeds on it still. Its protocols feed. Effect: Squadrons have +30% hull. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.h_chitin; PATRONS.hunger

**Hot Tubes** (`boon:e_reload`)
- Hook: Seren protocol: hotter tubes, faster reloads.
- A protocol of S-6 Seren, the Last Flame. Seren, the Last Flame, drifted to the Reach outer belt, and the Crusade weapons came from studying it. Its protocols burn. Effect: Torpedoes reload 1 turn faster. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.e_reload; PATRONS.ember

**Hunter's Line** (`boon:d_hunter`)
- Hook: Duo, Astra and Rook: speed becomes crits.
- A duo protocol of A-4 Astra, the Silent Star and R-5 Rook, the Breaker, offered when a fleet runs in sync with both cores at once. Effect: Ships that moved 3 or more hexes gain +25% critical chance. Duo protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.d_hunter; PATRONS.star+rook

**Incendiary Warheads** (`boon:e_war`)
- Hook: Seren protocol: torpedoes, a quarter harder.
- A protocol of S-6 Seren, the Last Flame. Seren, the Last Flame, drifted to the Reach outer belt, and the Crusade weapons came from studying it. Its protocols burn. Effect: Torpedoes deal +25% damage. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.e_war; PATRONS.ember

**Ion Lance** (`boon:d_ionlance`)
- Hook: Duo, Vyre and Astra: lances that unshield.
- A duo protocol of V-2 Vyre, the Storm Queen and A-4 Astra, the Silent Star, offered when a fleet runs in sync with both cores at once. Effect: Lances strip double the shield per hit. Duo protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.d_ionlance; PATRONS.storm+star

**Ion Lash** (`boon:s_ion`)
- Hook: Vyre protocol: every hit strips more shield.
- A protocol of V-2 Vyre, the Storm Queen. Vyre, the Storm Queen, is the core the Registry captured and studied. Its protocols are shields, kept and broken. Effect: Your weapons strip 22% more shield per hit. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.s_ion; PATRONS.storm

**Iron Discipline** (`boon:i_brace`)
- Hook: Kharon protocol: brace, and bite back.
- A protocol of K-1 Kharon, the Unbent. Kharon, the Unbent, never left the dead system, and Eclipse learned endurance from it. Its protocols hold. Effect: Bracing blocks an extra 10% of damage, and braced ships strike back: every enemy attack that hits one deals 18 damage to the attacker in return. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.i_brace; PATRONS.iron

**Juggernaut** (`boon:d_jugg`)
- Hook: Duo, Kharon and Rook: the unstoppable ram.
- A duo protocol of K-1 Kharon, the Unbent and R-5 Rook, the Breaker, offered when a fleet runs in sync with both cores at once. Effect: Rams deal +50% damage and the rammer takes no recoil. Duo protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.d_jugg; PATRONS.iron+rook

**Killing Light** (`boon:a_crit`)
- Hook: Astra protocol: crits that wreck systems.
- A protocol of A-4 Astra, the Silent Star. Astra, the Silent Star, is the core the Glasswrights keep caged and throttled. Its protocols are one clean line of light. Effect: +6% critical chance, critical hits deal x1.75 damage, and every critical hit wrecks a system on the target ship. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.a_crit; PATRONS.star

**Kindling** (`boon:e_kindle`)
- Hook: Seren protocol: some hits simply catch.
- A protocol of S-6 Seren, the Last Flame. Seren, the Last Flame, drifted to the Reach outer belt, and the Crusade weapons came from studying it. Its protocols burn. Effect: Hull hits have a 12% chance to start a fire. Fires burn 10 a turn for 2 turns. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.e_kindle; PATRONS.ember

**Lightning Reflex** (`boon:s_ev`)
- Hook: Vyre protocol: the whole fleet gets harder to hold.
- A protocol of V-2 Vyre, the Storm Queen. Vyre, the Storm Queen, is the core the Registry captured and studied. Its protocols are shields, kept and broken. Effect: +6 evasion across the fleet. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.s_ev; PATRONS.storm

**Long Silence** (`boon:a_long`)
- Hook: Astra protocol: range stops taxing the first hex.
- A protocol of A-4 Astra, the Silent Star. Astra, the Silent Star, is the core the Glasswrights keep caged and throttled. Its protocols are one clean line of light. Effect: Your fire ignores the first hex of long-range accuracy penalty. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.a_long; PATRONS.star

**Marked for Death** (`boon:a_mark`)
- Hook: Astra gift: the first lance hit paints the target.
- A protocol of A-4 Astra, the Silent Star. Astra, the Silent Star, is the core the Glasswrights keep caged and throttled. Its protocols are one clean line of light. Effect: Each round, the first enemy ship your lances hit is marked: your whole fleet aims 10 better against it until the round ends. A fixed gift protocol: it does not scale with rarity.
- Source: data.js BOONS.a_mark; PATRONS.star

**Momentum** (`boon:r_mom`)
- Hook: Rook protocol: movement becomes damage.
- A protocol of R-5 Rook, the Breaker. Rook, the Breaker, drifts in the wreck fields, hunted by the Hullbreakers who think it makes its holder unstoppable. Its protocols arrive first. Effect: Ships deal +5% damage for each hex they moved this activation, up to 4 hexes. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.r_mom; PATRONS.rook

**One Clean Line** (`boon:L_star`)
- Hook: Legendary Astra: lances that cannot miss the dark.
- The legendary protocol of A-4 Astra, the Silent Star. Astra, the Silent Star, is the core the Glasswrights keep caged and throttled. Its protocols are one clean line of light. Effect: Lances hit 95% of the time and pass straight through shields. Legendary protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.L_star; PATRONS.star

**Pyre of Stars** (`boon:L_ember`)
- Hook: Legendary Seren: every kill is a second weapon.
- The legendary protocol of S-6 Seren, the Last Flame. Seren, the Last Flame, drifted to the Reach outer belt, and the Crusade weapons came from studying it. Its protocols burn. Effect: Every enemy ship you destroy explodes for 40 damage to every enemy within 2 hexes. Legendary protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.L_ember; PATRONS.ember

**Ravenous Wings** (`boon:h_wings`)
- Hook: Crucible protocol: wings that bite harder.
- A protocol of H-3 Crucible, "the Hunger Below". Crucible, the Hunger Below, powered the Fleshwrights vats; the swarm grew around it and feeds on it still. Its protocols feed. Effect: Squadrons deal +25% damage. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.h_wings; PATRONS.hunger

**Shield Wall** (`boon:i_wall`)
- Hook: Kharon gift: your brace covers your neighbors.
- A protocol of K-1 Kharon, the Unbent. Kharon, the Unbent, never left the dead system, and Eclipse learned endurance from it. Its protocols hold. Effect: Bracing covers every ship beside the braced ship too: they take the brace hull cut until its next turn. A fixed gift protocol: it does not scale with rarity.
- Source: data.js BOONS.i_wall; PATRONS.iron

**Shockwave** (`boon:r_shock`)
- Hook: Rook protocol: the ram splashes.
- A protocol of R-5 Rook, the Breaker. Rook, the Breaker, drifts in the wreck fields, hunted by the Hullbreakers who think it makes its holder unstoppable. Its protocols arrive first. Effect: Rams also hit every other enemy beside the target for 25% of the ram damage. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.r_shock; PATRONS.rook

**Silent Aim** (`boon:a_aim`)
- Hook: Astra protocol: every gun aims truer.
- A protocol of A-4 Astra, the Silent Star. Astra, the Silent Star, is the core the Glasswrights keep caged and throttled. Its protocols are one clean line of light. Effect: +5 aim for every weapon. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.a_aim; PATRONS.star

**Slip the Net** (`boon:r_slip`)
- Hook: Rook gift: fire, then move away.
- A protocol of R-5 Rook, the Breaker. Rook, the Breaker, drifts in the wreck fields, hunted by the Hullbreakers who think it makes its holder unstoppable. Its protocols arrive first. Effect: Your ships may move after firing, up to half the movement they had left, without climbing or diving. A fixed gift protocol: it does not scale with rarity.
- Source: data.js BOONS.r_slip; PATRONS.rook

**Spread Pattern** (`boon:e_spread`)
- Hook: Seren gift: even missed torpedoes burst.
- A protocol of S-6 Seren, the Last Flame. Seren, the Last Flame, drifted to the Reach outer belt, and the Crusade weapons came from studying it. Its protocols burn. Effect: Torpedoes that run wide still burst: every enemy within 1 hex of the aim hex takes 30% of one torpedo damage. A fixed gift protocol: it does not scale with rarity.
- Source: data.js BOONS.e_spread; PATRONS.ember

**Starlight Lances** (`boon:a_lance`)
- Hook: Astra protocol: lances, a third harder again.
- A protocol of A-4 Astra, the Silent Star. Astra, the Silent Star, is the core the Glasswrights keep caged and throttled. Its protocols are one clean line of light. Effect: Lances deal +35% damage. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.a_lance; PATRONS.star

**Storm Mantle** (`boon:s_regen`)
- Hook: Vyre protocol: shields that mend themselves faster.
- A protocol of V-2 Vyre, the Storm Queen. Vyre, the Storm Queen, is the core the Registry captured and studied. Its protocols are shields, kept and broken. Effect: Each turn, every shield facing on every ship restores an extra 18% of its strength. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.s_regen; PATRONS.storm

**Swarm Hatch** (`boon:h_hatch`)
- Hook: Crucible protocol: one more wing in the air.
- A protocol of H-3 Crucible, "the Hunger Below". Crucible, the Hunger Below, powered the Fleshwrights vats; the swarm grew around it and feeds on it still. Its protocols feed. Effect: Carriers field an extra wing. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.h_hatch; PATRONS.hunger

**The Endless Swarm** (`boon:L_hunger`)
- Hook: Legendary Crucible: the swarm does not end.
- The legendary protocol of H-3 Crucible, "the Hunger Below". Crucible, the Hunger Below, powered the Fleshwrights vats; the swarm grew around it and feeds on it still. Its protocols feed. Effect: Carriers field two more wings and never run out of spare wings. Legendary protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.L_hunger; PATRONS.hunger

**Thunder Broadside** (`boon:i_broad`)
- Hook: Kharon protocol: broadsides hit a fifth harder.
- A protocol of K-1 Kharon, the Unbent. Kharon, the Unbent, never left the dead system, and Eclipse learned endurance from it. Its protocols hold. Effect: Broadside guns deal +20% damage. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.i_broad; PATRONS.iron

**Unbent Plating** (`boon:i_plate`)
- Hook: Kharon protocol: armor for the whole fleet.
- A protocol of K-1 Kharon, the Unbent. Kharon, the Unbent, never left the dead system, and Eclipse learned endurance from it. Its protocols hold. Effect: +8% armor across the fleet. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.i_plate; PATRONS.iron

**Unbreakable** (`boon:L_iron`)
- Hook: Legendary Kharon: death, declined once per ship.
- The legendary protocol of K-1 Kharon, the Unbent. Kharon, the Unbent, never left the dead system, and Eclipse learned endurance from it. Its protocols hold. Effect: Every ship survives its first killing blow each battle at 1 hull. Legendary protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.L_iron; PATRONS.iron

**Unbroken Line** (`boon:i_line`)
- Hook: Kharon protocol: neighbors in the line share the load.
- A protocol of K-1 Kharon, the Unbent. Kharon, the Unbent, never left the dead system, and Eclipse learned endurance from it. Its protocols hold. Effect: Ships next to another of your ships take 12% less hull damage. Shown at base strength; rarer copies of the protocol scale the effect up.
- Source: data.js BOONS.i_line; PATRONS.iron

**Unstoppable** (`boon:L_rook`)
- Hook: Legendary Rook: the ram that takes most of a hull.
- The legendary protocol of R-5 Rook, the Breaker. Rook, the Breaker, drifts in the wreck fields, hunted by the Hullbreakers who think it makes its holder unstoppable. Its protocols arrive first. Effect: Rams deal 50% more damage, can take 70% of a target hull, and the rammer takes no recoil. Legendary protocols are fixed: they do not scale with rarity.
- Source: data.js BOONS.L_rook; PATRONS.rook

### Relics (salvage) (12)

**Adamant armourweave** (`relic:armourweave`)
- Hook: Adamant woven like cloth, behaving like a wall.
- Adamant armourweave is plate that thinks it is fabric: it flexes with the hull and stops fire like a fortress. Effect: +6% armor across the fleet. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Hardsteel weave; Ashfall Hullbreakers call it Scrap armor weave; The Chorus call it Carapace weave; The Glasswrights call it Sunstone weave; Eclipse call it Sunshade weave.
- Source: data.js RELICS.armourweave; RELIC_NAMES

**Alien shield matrix** (`relic:lattice`)
- Hook: Alien geometry, worn as a second skin of light.
- A shield matrix built on geometry no living engineer fully follows, looted or traded out of the dark. Effect: Shields +15% across the fleet. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Deflector matrix prototype; Ashfall Hullbreakers call it Glasswright shield shard; The Chorus call it Swallowed shield cells; The Glasswrights call it Prism matrix.
- Source: data.js RELICS.lattice; RELIC_NAMES

**Captured war banner** (`relic:banner`)
- Hook: Kills make the killer hungrier, visibly.
- A captured war banner, flown from the flagship aerial so every ship in the fleet can see what it is for. Effect: Every enemy ship one of your ships destroys gives that ship +15% damage for the rest of the battle, up to +45%. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Captured war banner; Ashfall Hullbreakers call it Trophy war banner; The Chorus call it Prey’s war banner; The Glasswrights call it Banner of Ardent; Eclipse call it Standard of the conquered.
- Source: data.js RELICS.banner; RELIC_NAMES

**Eclipse backup frame** (`relic:phylactery`)
- Hook: A spare body, kept warm against the day a mind needs it.
- An Eclipse backup frame: a hull kept empty and ready, so that a fall is an interruption, not an end. Effect: The first of your ships destroyed each battle reawakens at 25% hull. The same piece of salvage wears other names in other fleets: Eclipse call it Second Ignition.
- Source: data.js RELICS.phylactery; RELIC_NAMES

**Founders’ compass** (`relic:compass`)
- Hook: It points at where you meant to go.
- A founders compass that does not care about north, because there is no north out here; it cares about intent. Effect: +1 speed across the fleet. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Jump-drive regulator; Ashfall Hullbreakers call it Wake-tracker; The Chorus call it Migration current; Eclipse call it Gravitic compass.
- Source: data.js RELICS.compass; RELIC_NAMES

**Founders’ rangefinder** (`relic:cogitator`)
- Hook: A founders sight: the first shot never lies.
- Founders tech from before the collapse, a rangefinder that remembers where things are going to be. Effect: Each ship first attack in every battle hits 95% of the time. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Registry targeting array; Ashfall Hullbreakers call it Stolen Navy rangefinder; The Chorus call it Heat-tasting pits; The Glasswrights call it Ancestral lens; Eclipse call it Calculus engine.
- Source: data.js RELICS.cogitator; RELIC_NAMES

**Hand-wound plasma coils** (`relic:coils`)
- Hook: Hand-wound, and they run light blue, as plasma should.
- Plasma coils wound by hand because the Reach trusts hands, and they burn light blue, the colour plasma runs when it is honest. Effect: Ability cooldowns come back 1 turn sooner across the fleet. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Overclocked reactors; Ashfall Hullbreakers call it Hot-rodded reactor; The Chorus call it Quickening gland; The Glasswrights call it Starlight coils; Eclipse call it Long clock.
- Source: data.js RELICS.coils; RELIC_NAMES

**Log of Admiral Rhel** (`relic:logbook`)
- Hook: An admiral who survived long enough to be worth reading.
- The campaign log of Admiral Rhel, annotated in three hands, two of them successors who died proving a margin note wrong. Effect: +30% captain experience. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Admiralty logbook; Ashfall Hullbreakers call it Warlord’s kill tally; The Chorus call it Taste of old prey; The Glasswrights call it Log of the last voyage; Eclipse call it The Archive.
- Source: data.js RELICS.logbook; RELIC_NAMES

**Scrap rig** (`relic:salvage`)
- Hook: Nothing in a wreck is waste.
- A scrap rig of clamps, cutters and stubbornness, worked by crews who see a battlefield as a warehouse that fought back. Effect: After each battle, gain 15 credits and repair 8% of hull. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Scrap rig; Ashfall Hullbreakers call it Scrap rig; The Chorus call it Scavenger gut; Eclipse call it Salvage swarm.
- Source: data.js RELICS.salvage; RELIC_NAMES

**Smuggler’s ledger** (`relic:ledger`)
- Hook: Every debt the dark owes you, collected at gunpoint.
- A smuggler ledger, half accounting and half threat, that somehow always settles in your favor after a fight. Effect: +25% credits from battles. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Smuggler’s ledger; Ashfall Hullbreakers call it Smuggler’s ledger; The Chorus call it Hoard of the deep; The Glasswrights call it Ledger of the exiles; Eclipse call it Siphon ledger.
- Source: data.js RELICS.ledger; RELIC_NAMES

**Tamed spore culture** (`relic:spore`)
- Hook: The swarm own growth, persuaded to knit your hulls.
- A tamed spore culture that grows over damage the way its wild kin grow over everything. Effect: Every ship regenerates 3 hull per turn. On a shieldless fleet this is the closest thing to a second hull. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Captured Chorus culture; The Chorus call it Ancestral spore culture.
- Source: data.js RELICS.spore; RELIC_NAMES

**The Chalked Roll** (`relic:martyr`)
- Hook: When one of ours dies, the rest of us mend.
- A record of the fallen that refuses to let a death be only a loss: the names are read, and the fleet closes up around the gap. Effect: When one of your ships is destroyed, every other ship repairs 15% of its hull. The same piece of salvage wears other names in other fleets: Hegemony Navy call it Medal of the Grand Fleet; Ashfall Hullbreakers call it Dead captain’s harness; The Chorus call it Heart of the first brood; The Glasswrights call it Tear of the dying star; Eclipse call it Last image of Ardent.
- Source: data.js RELICS.martyr; RELIC_NAMES

### Modules (13)

**Battery loaders** (`module:loaders`)
- Hook: Every battery fires one more shot.
- Battery loaders drill the gun crews and rebuild the hoists until another shot fits in the volley. Effect: Battery weapons fire +1 shot. Costs 90 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Pulse cyclers; Ashfall Hullbreakers fit it as Ammo hoppers.
- Source: data.js MODULES.loaders; MOD_NAMES

**Damage control crews** (`module:damcon`)
- Hook: Crews that patch 4% of the hull every turn.
- Damage control crews with foam, plate and no respect for the concept of a lost cause. Effect: Repairs 4% of hull at the start of each of your turns. Costs 85 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Damage control teams; Ashfall Hullbreakers fit it as Welding gangs.
- Source: data.js MODULES.damcon; MOD_NAMES

**Flak batteries** (`module:flakplus`)
- Hook: Point defense with more shots and longer reach.
- Extra point-defense mounts and the fire control to use them: the guard gets louder and longer. Effect: Point defense fires +2 shots and reaches +1 hex further. Costs 55 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Point-defense array; Ashfall Hullbreakers fit it as Bolted-on flak.
- Source: data.js MODULES.flakplus; MOD_NAMES

**Gyro-stabilisers** (`module:gyro`)
- Hook: Turn easier, drift harder to hit.
- Gyro-stabilisers let a hull swing its facing without spending its soul on the turn. Effect: +1 turn allowance and +5 evasion. Costs 60 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Attitude thrusters; Ashfall Hullbreakers fit it as Jury-rigged gyros.
- Source: data.js MODULES.gyro; MOD_NAMES

**Hangar expansion** (`module:hangar`)
- Hook: Carriers only: one more wing in flight.
- A hangar expansion carves room for one more wing and the crews to keep it flying. Effect: Carriers only: +1 squadron in flight. Costs 90 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Expanded hangar bay; Ashfall Hullbreakers fit it as Welded-on hangar.
- Source: data.js MODULES.hangar; MOD_NAMES

**Lance focusing crystal** (`module:crystal`)
- Hook: Lances focused to a quarter more damage.
- A focusing crystal sits in the lance path and argues the beam into a finer point. Effect: Lance damage +25%. Costs 80 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Ion focus lens; Ashfall Hullbreakers fit it as Cracked lens array.
- Source: data.js MODULES.crystal; MOD_NAMES

**Plasma drive** (`module:drive`)
- Hook: One more hex of speed, everywhere it matters.
- A plasma drive tuned past its handbook limits, burning light blue and hot. Effect: +1 speed. Costs 75 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Ion drive upgrade; Ashfall Hullbreakers fit it as Overbored thrusters.
- Source: data.js MODULES.drive; MOD_NAMES

**Reinforced prow** (`module:prow`)
- Hook: More hull, more armor, at the pointy end.
- Extra plate worked into the prow and frame, where a ship meets the fight first. Effect: +15% hull and +5% armor. Costs 70 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Reinforced bow plating; Ashfall Hullbreakers fit it as Scrap ram plating.
- Source: data.js MODULES.prow; MOD_NAMES

**Scanner array** (`module:auspex`)
- Hook: A scanner array: every gun aims 10 truer.
- A proper scanner array, replacing guesswork and prayer with ranges and bearings. Effect: +10 aim for every weapon. Costs 80 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Fire-control computer; Ashfall Hullbreakers fit it as Stolen gun sights.
- Source: data.js MODULES.auspex; MOD_NAMES

**Screen capacitor** (`module:capacitor`)
- Hook: Shields a third again as strong.
- A screen capacitor banks charge so the shields stand thicker when the fire starts. Effect: +30% shield strength. Costs 80 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Deflector capacitor; Ashfall Hullbreakers fit it as Salvaged shield cells.
- Source: data.js MODULES.capacitor; MOD_NAMES

**Shield regenerator** (`module:regen`)
- Hook: Shields that come back half again as fast.
- A shield regenerator cycles the facings back up before the enemy finishes reloading. Effect: +50% shield regeneration. Costs 70 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Deflector regenerator; Ashfall Hullbreakers fit it as Hot-wired regenerator.
- Source: data.js MODULES.regen; MOD_NAMES

**Targeting reckoner** (`module:cogitator`)
- Hook: A reckoner that finds the weak point 10% more often.
- A targeting reckoner, a ship computer that does nothing but study where ships break. Effect: +10% critical chance. Costs 75 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Targeting computer; Ashfall Hullbreakers fit it as Gunner’s lucky charm.
- Source: data.js MODULES.cogitator; MOD_NAMES

**Torpedo magazine** (`module:magazine`)
- Hook: Torpedoes reload sooner and hit harder.
- A torpedo magazine moves the reload path inside the armor and adds sting to every tube. Effect: Torpedo reload time 1 turn shorter, and torpedo damage +15%. Costs 85 credits, and a hull needs a free module slot to fit it. The same works wear other names abroad: Hegemony Navy fit it as Fusion magazine; Ashfall Hullbreakers fit it as Extra rocket racks.
- Source: data.js MODULES.magazine; MOD_NAMES

### Admirals (24)

**Admiral Roderic Vex** (`admiral:vex`)
- Hook: Line of battle: broadsides hit harder under Vex.
- Roderic Vex holds a line the way other men hold a grudge: completely, and at ruinous expense to anyone who tests it. Doctrine, Line of battle: Broadside weapons deal +15% damage. Command, Fire for effect: Every ship fires a free volley at the best target its guns can reach, right now. Opens with Vigil-class cruiser, Harrow-class destroyer, Warden-class frigate. A starting admiral, available from your first run.
- Note: Spend the Command when the whole fleet can bear on targets; a volley fired at empty arcs is a volley lost.
- Source: data.js ADMIRALS.vex; faction Sunward Crusade

**Brin of the Fourth Lens** (`admiral:mirelle`)
- Hook: Prism hulls: shields thick and quick to return.
- Brin of the Fourth Lens builds prisms the way others build walls, and then stands behind the light. Doctrine, Prism hulls: All ships gain +15% shields, and shields recharge 20% faster. Command, Prism ward: All shields refill and your ships take 40% less hull damage this round. Opens with Glasswright prism, Glasswright sliver, Glasswright sliver. Unlocked with 80 renown.
- Note: Spend it at the start of the round you expect to be hit hardest, not after.
- Source: data.js ADMIRALS.mirelle; faction The Glasswrights

**Commodore Dace Vorn** (`admiral:vorn`)
- Hook: Interdiction: aim and crits, Registry style.
- Dace Vorn interdicts. He decides where the enemy fleet is allowed to be, and then fines it for being there. Doctrine, Interdiction: +10 aim and +10% critical chance. Command, Interdiction strike: Every ship deals +30% damage this round. Opens with Cordon destroyer, Cordon destroyer, Hegemony picket, Hegemony picket. Unlocked with 30 renown.
- Note: Spend it on the round you have already lined up; the bonus does not carry to the next.
- Source: data.js ADMIRALS.vorn; faction Hegemony Navy

**Commodore Sera Ashgrove** (`admiral:ashgrove`)
- Hook: Carrier doctrine: tougher wings that hit harder.
- Sera Ashgrove counts her fleet in wings, and brings every one of them home, or goes back and gets them. Doctrine, Carrier doctrine: Squadrons deal +40% damage, carriers hold +1 wing, and squadrons have +25% hull. Command, Scramble all wings: Every carrier launches an extra wing, even past its hangar limit, then all squadrons strike again at once with +50% damage this round. Opens with Hearth-class carrier, Harrow-class destroyer, Warden-class frigate. Unlocked with 45 renown.
- Note: Spend it when your wings are already out and in reach of targets worth striking twice.
- Source: data.js ADMIRALS.ashgrove; faction Sunward Crusade

**First Admiral Ilsa Kassar** (`admiral:kassar`)
- Hook: Fire discipline: more shots, each a touch lighter.
- Ilsa Kassar runs her fleet the way the Registry runs its accounts: every shot entered, every loss acceptable, barely. Doctrine, Fire discipline: Batteries fire one extra shot per volley, but every gun hits 5% lighter. Command, Synchronized broadside: Every ship fires a free volley at the best target its guns can reach, right now. Opens with Vanguard cruiser, Hegemony picket. A starting admiral, available from your first run.
- Note: Spend the Command when the whole fleet can bear on targets; a volley fired at empty arcs is a volley lost.
- Source: data.js ADMIRALS.kassar; faction Hegemony Navy

**Fleet Marshal Corin Reyes** (`admiral:reyes`)
- Hook: Strike group: wings up, cruisers carrying.
- Corin Reyes commands a strike group the way the Registry plans a quarter: wings out, margins kept, nothing wasted. Doctrine, Strike group: Squadrons deal +10% damage, cruisers hold +1 wing, and squadrons have +25% hull. Command, Launch the strike group: Every carrier launches an extra wing, even past its hangar limit, then all squadrons strike again at once with +50% damage this round. Opens with Vanguard cruiser, Hegemony picket, Hegemony picket. Unlocked with 45 renown.
- Note: Spend it when your wings are already out and in reach of targets worth striking twice.
- Source: data.js ADMIRALS.reyes; faction Hegemony Navy

**High Admiral Oryn Thale** (`admiral:thale`)
- Hook: Iron doctrine: hull and shields for everyone.
- Oryn Thale is the Crusade made patient: iron, endurance, and the names chalked after the battle, not before. Doctrine, Iron doctrine: All ships gain +15% hull and +10% shields. Command, Iron wall: All shields refill and your ships take 40% less hull damage this round. Opens with Bastion-class battleship, Warden-class frigate. Unlocked with 80 renown.
- Note: Spend it at the start of the round you expect to be hit hardest, not after.
- Source: data.js ADMIRALS.thale; faction Sunward Crusade

**Line Admiral Oskar Maren** (`admiral:maren`)
- Hook: Armored column: the fleet as a wall.
- Oskar Maren is a column of armor with a flag on it, and the Registry projection for his battles is one word: favourable. Doctrine, Armored column: All ships gain +15% hull and +10% shields. Command, Shield wall order: All shields refill and your ships take 40% less hull damage this round. Opens with Dominion dreadnought, Hegemony picket. Unlocked with 80 renown.
- Note: Spend it at the start of the round you expect to be hit hardest, not after.
- Source: data.js ADMIRALS.maren; faction Hegemony Navy

**Nadir Aurex, Ninth Frame** (`admiral:nekhet`)
- Hook: Endless restoration: the fleet rebuilds itself.
- Nadir Aurex is on his ninth frame, and speaks of the previous eight the way other admirals speak of previous postings. Doctrine, Endless restoration: Ships regrow 4% of their hull each round. Command, Release the repair swarms: Every ship repairs 25% of its hull and patches damaged sections, even destroyed ones. Opens with Eclipse zenith, Eclipse flare. A starting admiral, available from your first run.
- Note: Spend it after the damage, not before: it patches even destroyed sections back into the fight.
- Source: data.js ADMIRALS.nekhet; faction Eclipse

**Oath-Captain Malek Draven** (`admiral:malek`)
- Hook: Hunter-killer: fast torpedoes, cruel rear arcs.
- Malek Draven swore the oath as a boy in the Reach and hunts the way the Reach taught him: from behind, once. Doctrine, Hunter-killer: Torpedoes reload a turn faster, and rear-arc hits deal +50% damage. Command, Hunter's salvo: Torpedoes reload at once and every ship deals +30% damage this round. Opens with Harrow-class destroyer, Harrow-class destroyer, Warden-class frigate, Warden-class frigate. Unlocked with 30 renown.
- Note: Spend it on the round you have already lined up; the bonus does not carry to the next.
- Source: data.js ADMIRALS.malek; faction Sunward Crusade

**Old Mott** (`admiral:mott`)
- Hook: Junkyard carriers: wings from welded dens.
- Old Mott has outlived forty captains, mostly by killing them, and keeps his carriers welded, fed, and pointed at the fight. Doctrine, Junkyard carriers: Squadrons deal +25% damage, hulks hold +1 wing, and squadrons have +25% hull. Command, Release the swarm: Every carrier launches an extra wing, even past its hangar limit, then all squadrons strike again at once with +50% damage this round. Opens with Hullbreaker hulk-carrier, Hullbreaker gutship. Unlocked with 45 renown.
- Note: Spend it when your wings are already out and in reach of targets worth striking twice.
- Source: data.js ADMIRALS.mott; faction Ashfall Hullbreakers

**Ostrel of the Long Copy** (`admiral:anuket`)
- Hook: Silent hunters: rear arcs and a low profile.
- Ostrel of the Long Copy has been copied so often that the Archive keeps the original under guard. The copy hunts just fine. Doctrine, Silent hunters: +20% damage on rear-arc hits and +10 evasion. Command, Out of the shadow: Every ship deals +30% damage this round. Opens with Eclipse flare, Eclipse flare, Eclipse mote, Eclipse mote. Unlocked with 45 renown.
- Note: Spend it on the round you have already lined up; the bonus does not carry to the next.
- Source: data.js ADMIRALS.anuket; faction Eclipse

**Razormaw** (`admiral:razormaw`)
- Hook: Hunter pack: speed and rear-arc teeth.
- Razormaw is the pack instinct of the swarm given a single throat: if it bleeds and it is slower than us, it is food. Doctrine, Hunter pack: +1 speed and +15% damage on rear-arc hits. Command, Blood frenzy: Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round. Opens with Chorus bladeback, Chorus spitter, Chorus drone-spawn. Unlocked with 30 renown.
- Note: Spend it to arrive a round early; position bought with the Command is position the enemy must answer.
- Source: data.js ADMIRALS.razormaw; faction The Chorus

**Sable the Smiling Knife** (`admiral:sable`)
- Hook: Knife work: rear arcs and criticals.
- Sable the Smiling Knife hunts the way her namesake does: quiet, low, and finished before the noise starts. Doctrine, Knife work: +50% damage on rear-arc hits and +10% critical chance. Command, Knife in the dark: Torpedoes reload at once and every ship deals +30% damage this round. Opens with Hullbreaker gutship, Hullbreaker gutship, Hullbreaker raider, Hullbreaker raider. Unlocked with 30 renown.
- Note: Spend it on the round you have already lined up; the bonus does not carry to the next.
- Source: data.js ADMIRALS.sable; faction Ashfall Hullbreakers

**Saro of Long Focus** (`admiral:vaelen`)
- Hook: Focused lances: beams with patience behind them.
- Saro of Long Focus has waited out duels longer than most species live, and then fired once. Doctrine, Focused lances: Lances deal +20% damage and gain +10 aim. Command, Burning glass: Every ship fires a free volley at the best target its guns can reach, right now. Opens with Glasswright prism, Glasswright lancet. Unlocked with 30 renown.
- Note: Spend the Command when the whole fleet can bear on targets; a volley fired at empty arcs is a volley lost.
- Source: data.js ADMIRALS.vaelen; faction The Glasswrights

**Seveth, Twice-Restored** (`admiral:khepra`)
- Hook: Layered plates: hull, and then more hull.
- Seveth has been restored twice, and has armored for a third death he does not intend to have. Doctrine, Layered plates: All ships gain +20% hull. Command, Sunshade wall: All shields refill and your ships take 40% less hull damage this round. Opens with Eclipse flare, Eclipse flare, Eclipse flare. Unlocked with 80 renown.
- Note: Spend it at the start of the round you expect to be hit hardest, not after.
- Source: data.js ADMIRALS.khepra; faction Eclipse

**Tamsa of the Clear Aperture** (`admiral:aelith`)
- Hook: Wing-mistress: carriers and wings, refined.
- Tamsa of the Clear Aperture keeps her carriers the way her ancestors kept lenses: clean, aligned, and aimed at the light. Doctrine, Wing-mistress: Squadrons deal +25% damage, carriers hold +1 wing, and squadrons have +25% hull. Command, Starling flight: Every carrier launches an extra wing, even past its hangar limit, then all squadrons strike again at once with +50% damage this round. Opens with Glasswright aperture, Glasswright sliver. A starting admiral, available from your first run.
- Note: Spend it when your wings are already out and in reach of targets worth striking twice.
- Source: data.js ADMIRALS.aelith; faction The Glasswrights

**The Matriarch of Nine Throats** (`admiral:matriarch`)
- Hook: Brood swarm: more swarms, hitting harder.
- The Matriarch of Nine Throats is the swarm grown a general: nine mouths, and every one of them giving the same order. Eat. Doctrine, Brood swarm: Spore swarms deal +25% damage, broods hold +1 swarm, and squadrons have +25% hull. Command, Spawning surge: Every carrier launches an extra wing, even past its hangar limit, then all squadrons strike again at once with +50% damage this round. Opens with Chorus brood-sac, Chorus drone-spawn, Chorus drone-spawn. A starting admiral, available from your first run.
- Note: Spend it when your wings are already out and in reach of targets worth striking twice.
- Source: data.js ADMIRALS.matriarch; faction The Chorus

**The Mending Throng** (`admiral:mending`)
- Hook: Regrowth: the fleet knits itself closed.
- The Mending Throng is the swarm remembering, through Memory, that flesh can be persuaded to close. Doctrine, Regrowth: Ships regrow 4% of their hull each round. Command, Regrowth tide: Every ship repairs 25% of its hull and patches damaged sections, even destroyed ones. Opens with Chorus bladeback, Chorus drone-spawn. Unlocked with 45 renown.
- Note: Spend it after the damage, not before: it patches even destroyed sections back into the fight.
- Source: data.js ADMIRALS.mending; faction The Chorus

**Umbra Vessane, Third-Housed** (`admiral:sekhmar`)
- Hook: Corona strikes: arcs first, everything second.
- Umbra Vessane, third-housed, keeps her corona arcs the way Eclipse keeps everything: counted, cold, and ready. Doctrine, Corona strikes: Corona arcs deal +20% damage, and every weapon deals +10% more. Command, Noon volley: Every ship fires a free volley at the best target its guns can reach, right now. Opens with Eclipse zenith, Eclipse mote, Eclipse mote. Unlocked with 30 renown.
- Note: Spend the Command when the whole fleet can bear on targets; a volley fired at empty arcs is a volley lost.
- Source: data.js ADMIRALS.sekhmar; faction Eclipse

**Vell of the Third Mirror** (`admiral:thorne`)
- Hook: Refraction tactics: nobody can hold a firing solution.
- Vell of the Third Mirror fights in reflections: by the time you have found the real ship, it has moved twice. Doctrine, Refraction tactics: +8 evasion for every ship. Command, Scatter the light: Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round. Opens with Glasswright lancet, Glasswright lancet, Glasswright sliver, Glasswright sliver. Unlocked with 45 renown.
- Note: Spend it to arrive a round early; position bought with the Command is position the enemy must answer.
- Source: data.js ADMIRALS.thorne; faction The Glasswrights

**Vesh the Collector** (`admiral:vesh`)
- Hook: Scrap armor: the fleet patches itself.
- Vesh the Collector takes ships apart to learn how they died, then wears the lesson as armor. Doctrine, Scrap armor: Ships patch 5% of their hull each round and have +10% armor. Command, Patch and weld: Every ship repairs 25% of its hull and patches damaged sections, even destroyed ones. Opens with Hullbreaker hulk-carrier, Hullbreaker gutship. Unlocked with 80 renown.
- Note: Spend it after the damage, not before: it patches even destroyed sections back into the fight.
- Source: data.js ADMIRALS.vesh; faction Ashfall Hullbreakers

**Voice of the Deep** (`admiral:voice`)
- Hook: Acid tide: every weapon bites harder.
- Voice of the Deep is the throat that speaks first for the dark between stars, and what it says is usually a menu. Doctrine, Acid tide: +15% damage with every weapon. Command, Spitting volley: Every ship fires a free volley at the best target its guns can reach, right now. Opens with Chorus bladeback, Chorus spitter, Chorus drone-spawn. Unlocked with 80 renown.
- Note: Spend the Command when the whole fleet can bear on targets; a volley fired at empty arcs is a volley lost.
- Source: data.js ADMIRALS.voice; faction The Chorus

**Warlord Grax Ironmaw** (`admiral:grax`)
- Hook: Ram and board: speed and damage, pack style.
- Grax Ironmaw earned the name the Hullbreaker way, in a challenge, and the pack has not questioned it since. Doctrine, Ram and board: +1 speed for every ship and +10% damage. Command, Full burn: Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round. Opens with Hullbreaker wrecker, Hullbreaker gutship, Hullbreaker gutship. A starting admiral, available from your first run.
- Note: Spend it to arrive a round early; position bought with the Command is position the enemy must answer.
- Source: data.js ADMIRALS.grax; faction Ashfall Hullbreakers; display name per text overhaul pack T-03 (Oct 27 rollout ruling)

### Legacy (renown unlocks) (12)

**Battleship hulls** (`legacy:u_battleship`)
- Hook: Battleship hulls join your shipyards.
- Renown spent at the yards changes what the yards can build for you, on every run after. Effect: Battleship-class hulls appear in shipyards. Costs 60 renown, bought once, in the Shipyards line.
- Source: data.js LEGACY.u_battleship

**Carrier hulls** (`legacy:u_carrier`)
- Hook: Carrier hulls join your shipyards.
- Renown spent at the yards changes what the yards can build for you, on every run after. Effect: Carrier hulls appear in shipyards. Costs 30 renown, bought once, in the Shipyards line.
- Source: data.js LEGACY.u_carrier

**Command authority I** (`legacy:cmd1`)
- Hook: +2 fleet command points, every run.
- Command authority is the paperwork of trust: more of the fleet answers to one plan. Effect: +2 fleet command points. Costs 35 renown, bought once, in the Command line.
- Source: data.js LEGACY.cmd1

**Command authority II** (`legacy:cmd2`)
- Hook: +2 more fleet command points, every run.
- Wider command authority, earned the slow way, in fleets that came home. Effect: +2 more fleet command points. Costs 70 renown, bought once, in the Command line. Requires Command authority I first.
- Source: data.js LEGACY.cmd2

**Dreadnought hulls** (`legacy:u_dread`)
- Hook: One Daybreak dreadnought, for Crusade fleets.
- The biggest permission the yards can give: a dreadnought of the Reach, one per fleet. Effect: Sunward Crusade fleets may take one Daybreak-class dreadnought. Costs 120 renown, bought once, in the Shipyards line. Requires Battleship hulls first.
- Source: data.js LEGACY.u_dread

**Founders’ salvage** (`legacy:founder`)
- Hook: Begin each run with a random piece of salvage.
- The founders left a great deal lying around the dark; some of it still works. Effect: Begin each run with a random piece of salvage. Costs 60 renown, bought once, in the Supply line.
- Source: data.js LEGACY.founder

**Master shipwrights** (`legacy:wrights`)
- Hook: Shipyard prices 15% lower, every run.
- Master shipwrights do not charge less because they like you. They charge less because they waste nothing. Effect: Shipyard prices are 15% lower. Costs 45 renown, bought once, in the Supply line.
- Source: data.js LEGACY.wrights

**Recovery crews** (`legacy:salvagers`)
- Hook: +20% credits from battles, every run.
- Recovery crews are the difference between a wreck and a payday. Effect: +20% credits from battles. Costs 40 renown, bought once, in the Supply line.
- Source: data.js LEGACY.salvagers

**Veteran officers** (`legacy:vets`)
- Hook: Starting captains begin ranked and perked.
- Veteran officers are what a fleet keeps when it cannot keep ships. Effect: Starting captains begin at Commander rank with a perk. Costs 50 renown, bought once, in the Command line.
- Source: data.js LEGACY.vets

**War chest I** (`legacy:chest1`)
- Hook: +75 starting credits, every run.
- A war chest is the fleet remembering to pack for the war it actually got. Effect: +75 starting credits. Costs 20 renown, bought once, in the Supply line.
- Source: data.js LEGACY.chest1

**War chest II** (`legacy:chest2`)
- Hook: +75 more starting credits, every run.
- A deeper war chest, packed by people who have seen the first one run out. Effect: +75 more starting credits. Costs 40 renown, bought once, in the Supply line. Requires War chest I first.
- Source: data.js LEGACY.chest2

**War chest III** (`legacy:chest3`)
- Hook: +75 more starting credits, every run.
- The deepest war chest: the difference between a plan and a hope, in credits. Effect: +75 more starting credits. Costs 65 renown, bought once, in the Supply line. Requires War chest II first.
- Source: data.js LEGACY.chest3

