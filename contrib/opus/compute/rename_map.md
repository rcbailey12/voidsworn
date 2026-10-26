# R44 rename map: Warhammer 40k-adjacent names (DRAFT for Ryan)

Status: DRAFT, Oct 26 2026, stream B. Nothing in sections 1 to 8 is applied. It waits for Ryan's approval, relayed by the coordinator. When applied: display names only (the `n`, `t`, `b`, `d` strings and log lines); every internal id stays (`gauss`, `doom`, `pulsar`, `shard`, `las`, `hellfire`, `cogitator`, `auspex`, `phylactery`, `tombhome`, style `tomb`, hull ids and so on), so saves, sims and the Godot port are untouched except for text.

Section 9 lists the few names already changed, inside the new R42 Nemesis tables only (not yet player-facing in any build), at the story helper's request.

How this was found: every string in data.js tables (2,660 strings) plus the string literals in battle.js, core.js, campaign_run.js, campaign_meta.js, campaign3d.js, ui3d.js and head.html, checked against a list of about 150 40k terms (Imperium, Ecclesiarchy, Mechanicus, Tyranid, Necron, Aeldari, Ork, Chaos). head.html had none. The story text in `godot/story/` is the story helper's and is not listed here.

How to read the tables: **Current** is what the player sees today; **Where** is the table or file; **New** is the proposed name; **Why** is one line. "Mild" means a common English word that 40k also uses; Ryan asked for those too, so each has a proposal, and the few I would keep are in section 8.

## 1. Weapon names (all factions)

The weapon families are renamed as families, so a faction's guns still read as one set.

| Current | Where | New | Why |
|---|---|---|---|
| Las-repeater | FAC_WNAMES voidsworn | Brand repeater | "Las" is the Imperial lasgun prefix. A brand is a burning iron: fire and penance, the Voidsworn voice. |
| Las-battery | FAC_WNAMES voidsworn | Brand battery | Same family. |
| Heavy las-broadside | FAC_WNAMES voidsworn | Heavy brand broadside | Same family. |
| Las-turret | FAC_WNAMES voidsworn | Brand turret | Same family. |
| Hellfire torpedo | FAC_WNAMES voidsworn | Pyre torpedo | Hellfire is an Imperial missile and round. The torpedo sets the target burning, and pyres are already Voidsworn. |
| Macro battery | W.battery | Gun battery | Macro-battery is Battlefleet Gothic's Imperial broadside gun. |
| Heavy macro battery | W.hbattery | Heavy gun battery | Same. |
| Bio-plasma | W.bioplasma | Bile plasma | Bio-plasma is a named Tyranid weapon. Bile keeps the Chorus's wet, eaten-alive feel. (The Chorus already shows "Spine volley".) |
| Spore mines | W.spores | Spore drifts | Spore Mines are a Tyranid unit. (The Chorus already shows "Spore cloud".) |
| Pulsar lance | W.pulsar and FAC_WNAMES ithar | Dawn lance | Pulsar lances are the Aeldari lance in Battlefleet Gothic. Dawn fits the Ithar's light and wing imagery. |
| Shuriken cannon | W.shard | Shard cannon | Shuriken cannon is an Aeldari weapon. (The Ithar already show "Prism shards".) |
| Gauss flayer | W.gauss and FAC_WNAMES deathless | Flux cutter | The Gauss flayer is the Necron signature gun. Flux keeps the "ignores armour" physics feel without the Necron word. |
| Gauss sentries | W.gsentry | Flux sentries | Same family. |
| Gauss pylon | FAC_WNAMES deathless | Flux warden | Gauss Pylon is a Necron fortification. |
| Gauss shredder | FAC_WNAMES deathless | Flux shredder | Same family. |
| Gauss (weapon kind label) | KIND_NAME.gauss | Flux | The kind label on cards and tooltips follows the family. |
| Doom arc | W.doom and FAC_WNAMES deathless | Ruin arc | Echoes the Necron Doomsday Ark. |
| "gauss weapons mostly ignore them" | campaign_meta.js help text | "flux weapons mostly ignore them" | Follows the family. |
| "flayed by gauss fire" | battle.js kill causes | "unmade by flux fire" | Follows the family. |

## 2. Hulls, factions and fleet names

| Current | Where | New | Why |
|---|---|---|---|
| The Deathless Dynasty | FACTIONS.deathless.n | The Deathless Court | Necron armies are Dynasties. A court of dead kings is ours. |
| "Machine necropolis-ships. Gauss weapons tear through shields..." | FACTIONS.deathless.blurb | "Machine barrow-ships. Flux weapons tear through shields..." | Necropolis is the Necron tomb-world word; the gun family changes. |
| The Dynasty rises | campaign_meta.js run-end line | The Court rises | Same. |
| Hive Leviathan | HULLS.b_boss | Brood Colossus | Hive Fleet Leviathan is the best-known Tyranid fleet. |
| Ithar wraithcarrier | HULLS.i_carrier | Ithar lightcarrier | Wraithships are the Aeldari ship line. |
| Archive wraithcarrier | HULL_VARIANTS i_carrier_a (new arc unlock) | Archive lightcarrier | Same. |
| Harvester tomb-turret | HULL_VARIANTS d_harvester_t | Harvester barrow-turret | Tomb is the Necron home word (tomb world, Tomb Blade, Tomb Kings). Barrow, an old burial mound, is ours. |
| Tomb-ark (class line) | HULLS.d_boss.cls | Barrow-ark | Echoes the Necron Ghost Ark and Doomsday Ark. |
| Wraith host | ARCHETYPES.carrier.names.ithar | Starling host | Wraith again; starlings are already the Ithar wings. |
| Hive cluster | ARCHETYPES.carrier.names.chorus | Brood cluster | Hive is the Tyranid word (Hive Mind, Hive Fleet). |
| Aspect of the Hive | ASPECTS.hive | Aspect of the Brood | Same. |
| Hive-node Vesk | MORE_SHIP_NAMES chorus | Brood-node Vesk | Same. |
| Hive-node Ashk | ui3d.js showcase names | Brood-node Ashk | Same. |
| Tomb of Nine Kings | MORE_SHIP_NAMES deathless | Barrow of Nine Kings | Tomb (and Tomb Kings). |
| Tomb of Ashes | ui3d.js showcase names | Barrow of Ashes | Same. |
| Obelisk of Night | MORE_SHIP_NAMES deathless | Stele of Night | The Obelisk is a Necron war machine. |
| Ankh of Ash | MORE_SHIP_NAMES deathless | Urn of Ash | The ankh is part of the Egyptian, Necron-coded look (see section 6). |

## 3. Admirals, captain ranks and commands

| Current | Where | New | Why |
|---|---|---|---|
| Inquisitor-Captain Malek Draven | ADMIRALS.malek | Censor-Captain Malek Draven | Inquisitor is one of the most recognisable 40k titles. A Roman censor judges morals; it fits the Voidsworn ("Bright Censure"). |
| Admiral Castellan Vex | ADMIRALS.vex | Admiral Provost Vex | Mild: Castellan is an Imperial Knight and a Space Marine rank. A provost keeps order. |
| Overlord Nekhet the Undying | ADMIRALS.nekhet | Dust-sovereign Aldmar the Undying | Overlord is the Necron noble rank; Nekhet is Egyptian-coded (section 6). |
| Cryptlord Anuket | ADMIRALS.anuket | Grave-warden Esma | Echoes the Necron Cryptek; Anuket is an Egyptian goddess. |
| Sekhmar the Reaper | ADMIRALS.sekhmar | Halric the Reaper | Egyptian-coded name (section 6). |
| Khepra the Patient | ADMIRALS.khepra | Morcant the Patient | Egyptian-coded name (section 6). |
| Reanimation protocol | ADMIRALS.nekhet.cmd | Reassembly protocol | Necron Reanimation Protocols. The game already says ships "reassemble". |
| Tomb-blade strike | ADMIRALS.anuket.cmd | Grave-knife strike | Tomb Blades are a Necron unit. |
| "Doom arcs deal +20% damage..." | ADMIRALS.sekhmar.d | "Ruin arcs deal +20% damage..." | Follows the gun family. |
| Cryptlord, Overlord, Dynast (ranks 3 to 5) | CAPTAINS.deathless.ranks | Grave-warden, Dust-sovereign, Regent | All three are Necron ranks or near them. |
| of the Ninth Tomb | CAPTAINS.deathless.epithets | of the Ninth Barrow | Tomb. |
| Imhoten, Setekh (and the rest of the list) | CAPTAINS.deathless.names | see section 6 | Imhoten is one letter from Imotekh the Stormlord, the best-known Necron phaeron; Setekh sits next to Necron and Egyptian naming (the verifier's flag; "Dynast Setekh the Patient" was flagged in the story review too). |
| Imperial broadside | battle.js BOSS_CMD hegemony | Admiralty broadside | Imperial points at the Imperium. Admiralty is the Hegemony's own word. |
| Hive regrowth | battle.js BOSS_CMD chorus | Brood regrowth | Hive. |

## 4. Refits, relics, boons, abilities and perks

| Current | Where | New | Why |
|---|---|---|---|
| Auspex array | MODULES.auspex | Augury array | Auspex is the Imperial scanner. Augury keeps the omen-reading Voidsworn tone. |
| Targeting cogitator | MODULES.cogitator | Targeting reckoner | Cogitator is the Imperial computer word. A reckoner does sums. |
| Void shield capacitor | MODULES.capacitor | Ward capacitor | Void shields are Imperial ship and Titan shields. |
| Macro loaders | MODULES.loaders | Battery loaders | Follows Gun battery. |
| Lance adept | PERKS.lanceadept | Lance savant | Mild: Adept is the Adeptus word. "Savant" is already in use ("Deflector savant"). |
| Nova cannon | ABILITIES.nova | Sunburst cannon | The Nova Cannon is Battlefleet Gothic's Imperial prow gun. |
| Reanimation beam | ABILITIES.reclaim | Reassembly beam | Reanimation (Necron). |
| "Deathless reanimation beams" | campaign_meta.js help text | "Deathless reassembly beams" | Same. |
| Archeotech rangefinder | RELICS.cogitator | Founders' rangefinder | Archeotech is a 40k-only word. |
| Xeno shield lattice | RELICS.lattice | Outlander shield lattice | Xeno and xenos are the Imperium's word for aliens. |
| Deathless phylactery | RELICS.phylactery | Deathless heart-urn | The phylactery is a Necron lord's relic (and a lich's). An urn fits a barrow court. |
| "The phylactery hums." | battle.js relic log line | "The heart-urn hums." | Same. |
| Wraithbone compass | RELICS.compass; RELIC_NAMES corsair | Dawnglass compass | Wraithbone is the Aeldari ship material. |
| Wraithbone keel | MOD_NAMES ithar.prow | Dawnglass spine | Wraithbone, and "keel" is a sea-ship word (house rule). |
| Shuriken feeders | MOD_NAMES ithar.loaders | Shard hoppers | Shuriken (and Tyranid feeders). |
| Living-metal plating | MOD_NAMES deathless.prow | Grave-alloy plating | Living metal is the Necron hull material. |
| Living-metal weave | RELIC_NAMES deathless.armourweave | Grave-alloy weave | Same. |
| Tomb sight | MOD_NAMES deathless.auspex | Barrow sight | Tomb. |
| Gauss accelerators | MOD_NAMES deathless.loaders | Flux accelerators | Gun family. |
| Doom-arc focus | MOD_NAMES deathless.crystal | Ruin-arc focus | Gun family. |
| Repair scarabs | MOD_NAMES deathless.damcon | Repair motes | Canoptek Scarabs are the Necron repair swarm. |
| Scarab hive | MOD_NAMES deathless.hangar | Mote hive | Scarab, and hive. |
| Crown of the first dynasty | RELIC_NAMES deathless.martyr | Crown of the first court | Dynasty. |
| Annals of the dynasty | RELIC_NAMES deathless.logbook | Annals of the court | Dynasty. |
| Phylactery of the Undying | RELIC_NAMES deathless.phylactery | Heart-urn of the Undying | Phylactery. |
| Chronometron | RELIC_NAMES deathless.coils | Stilled hourglass | The Chronometron is a named Necron Cryptek relic. |
| Imperial targeting array | RELIC_NAMES hegemony.cogitator | Admiralty targeting array | Imperial. |
| Memory of the hive | RELIC_NAMES chorus.logbook | Memory of the brood | Hive. |

## 5. Events and map text

| Current | Where | New | Why |
|---|---|---|---|
| "Your auspex finds an ancient gothic warship..." | EVENTS derelict, body | "Your scanners find an ancient cathedral-hulled warship..." | Auspex, and "gothic warship" names Battlefleet Gothic. |
| "Could hold archeotech" / "archeotech and salvage" | EVENTS derelict, options | "Could hold founders' tech" / "founders' tech and salvage" | Archeotech. |
| The astropath's vision; "Your fleet astropath wakes screaming" | EVENTS astropath (id kept) | The far-dreamer's vision; "Your fleet's far-dreamer wakes screaming" | Astropaths are the Imperium's telepathic messengers. |
| A dynastic beacon; "An old dynastic beacon... Something of the dynasty" | EVENTS astropath, Deathless variant | A court beacon; "An old court beacon... Something of the court" | Dynasty. |
| Warp storm | EVENTS[4].t | Rift storm | The Warp is the 40k hell-dimension. "Rift" is already the game's word in other events. |
| A sealed tomb-world | EVENTS tomb (id kept) | A sealed barrow-world | Tomb world is the Necron home. |
| A sleeping tomb-world; "A tomb-world of your own dynasty" | EVENTS tombhome (id kept) | A sleeping barrow-world; "A barrow-world of your own court" | Same. |
| "Let the living metal knit it" | EVENTS[13] option | "Let the grave-alloy knit it" | Living metal. |
| "free once a tomb-world has woken for you" | FAC_VERBS deathless.freeD | "free once a barrow-world has woken for you" | Tomb world. |
| "reinforcements will drop out of warp"; "drop out of warp"; "A friendly ship drops out of warp" | battle.js battle events | "...will jump in"; "jump in"; "A friendly ship jumps in" | Warp. |
| "...ships on the auspex." | battle.js battle start log | "...ships on the scanners." | Auspex. |
| "Auspex confirms" | campaign_run.js sector intro | "Scanners confirm" | Auspex. |
| "Long-range auspex confirms" | campaign_meta.js sector intro | "Long-range scans confirm" | Auspex. |
| Void shield rites; Auspex rites | NEM_ADAPT_FAC voidsworn | Ward rites; Augury rites | Same words as the refits. (Already applied, section 9.) |

## 6. One family call: Deathless naming

The Deathless names are Egyptian-coded throughout (Nekhet, Sekhmar, Anuket, Khepra, Imhoten, Setekh, Rahotep, Ptahmet, Sobekar, the jackal hull, the ankh). Egyptian-flavoured undying machine kings are the Necron signature, so swapping single names leaves the family reading Necron. Two ways:

- **A, small:** keep the Egyptian style; rename only the closest names (Imhoten to Hotenra, Setekh to Sethren) plus the ranks and words above.
- **B, recommended:** move the Deathless to a barrow-court style, Old English and Norse grave-mound kings (think Sutton Hoo: barrows, urns, mounds, sleeping courts). It is ours, it still reads ancient and royal, and it matches the barrow and court words above.
  - Admirals: Nekhet to Aldmar, Sekhmar to Halric, Anuket to Esma, Khepra to Morcant (section 3).
  - Captain names (CAPTAINS.deathless.names, 14): Aldmar, Corvic, Esma, Halric, Ivor, Morcant, Ordric, Wynn, Edda, Gyrth, Hild, Sigeric, Tova, Wulfmar.
  - Hull: Deathless jackal to Deathless gravehound; Jackal court guard (new arc unlock) to Gravehound court guard. The jackal is Anubis.
  - Nemesis name parts: section 9 (already switched in the new table).

## 7. Outside 40k, other well-known franchises (Ryan's call, low priority)

R44 is about 40k. These sit next to other franchises and are listed so Ryan can decide in the same pass.

| Current | Where | New | Why |
|---|---|---|---|
| Turbolaser, Heavy turbolaser (base names; the Hegemony already shows "Plasma lance") | W.turbo, W.hturbo; "turbolaser" in the Vanguard gunship text | Pulse cannon, Heavy pulse cannon | Star Wars. |
| Hyperdrive motivator | RELIC_NAMES hegemony.compass | Jump-drive regulator | A Star Wars line. |
| Durasteel weave | RELIC_NAMES hegemony.armourweave | Hardsteel weave | Star Wars material. |
| Dominion star dreadnought | HULLS.h_dominion | Dominion line dreadnought | "Star Dreadnought" is a Star Wars class word. |
| High Templar | NEM_FAC voidsworn title | High Votary | StarCraft (and 40k's Black Templars). Already applied, section 9. |

## 8. Looked at and kept (say if you want any of these changed too)

- **Lance, Penance lance, Lance array:** a core weapon kind used across the genre; renaming would touch every card.
- **Penitent, Saint, Brother, Arch-deacon, Lector, Crusade, Crusade-master, Pale Crusader, Litany, Censer, Reliquary, Cathedral-class:** plain church and history words, not 40k inventions. Voidsworn is built on them.
- **Undying, Reaper, scythe, harvester, Silent Procession, the Unsleeping:** generic death words.
- **Hulk, Gun-hulk, Warlord, Reaver, Scrap-baron, and Corsair name parts like Krag, Gor, Snag, Skarn, Jagg:** generic pirate and brute names; nothing Ork-specific (no Waaagh, no Ork spellings).
- **Navigator (The navigator's hunch), Seer's eye, Seer's sight, Solar sail extension, Interdictor, Ion cannon, Deflector:** generic sci-fi words.
- **Purge the moon:** plain English.
- **HNS Castellan, HNS Vindicator (ship names):** mild; say if you want them in the Provost pass.

## 9. Already changed (new R42 Nemesis tables only, story helper's request, Oct 26)

These tables are new and not in any player build yet, so they were changed now. Revert is a one-line edit if Ryan prefers otherwise.

| Table | Was | Now | Why |
|---|---|---|---|
| NEM_FAC deathless titles | Phaeron, Dynast, Tomb-lord, Overlord | Ash-king, Regent, Barrow-king, Dust-sovereign | Phaeron is a real Necron rank; the rest as section 3. |
| NEM_FAC deathless name parts | Ankh, Sekh, Neph, Amen, Thut, Osir, Ptah, Kher, Mer, Seth / amun, ekhet, ophis, arkh, enmet, ankh, esut, hotep, umet, akh | Ald, Cor, Esm, Hal, Ord, Gyr, Wulf, Sig, Mor, Ed / ric, mar, wyn, gar, wine, mund, red, ith, helm, wold | Egyptian, Necron-coded (section 6, option B). |
| NEM_FAC voidsworn name parts | Inquisitor, Castellan, Confessor, Templar, Chaplain, Penitent | Censor, Provost, Shriver, Votary, Cantor, Sister | 40k titles; Penitent clashed with the hull class; Sister balances Brother. |
| NEM_FAC voidsworn titles | High Templar, Lord Inquisitor, Arch-confessor | High Votary, Lord Censor, Arch-shriver | Same. |
| NEM_FAC chorus name parts (post) | Hymn, Choir, Psalm | Gullet, Rasp, Spawn | Song words now belong to the Ithar; the Chorus voice is de-songed. |
| NEM_FAC chorus titles | Matriarch, Hive-mind | Spawn-mother, Gorge-mind | Matriarch was the admiral's defining word (The Matriarch of Nine Throats); Hive-mind is Tyranid. |
| NEM_FAC chorus scar epithets | the Scarred Choir, Half-Sung, Scabsong | the Scarred Maw, Half-Eaten, Scabhide | De-songed. |
| NEM_FAC hegemony name parts (post) | Lindqvist | Ostrander | "Petra Lindqvist" was the story outlines' sample rival and could be rolled verbatim. |
| NEM_ADAPT_FAC | Wraithbone keel; Living-metal shell; Tomb sight; Void shield rites; Auspex rites | Dawnglass spine; Grave-alloy shell; Barrow sight; Ward rites; Augury rites | Sections 4 and 5. "Gauss pylons" waits for the gun family (section 1). |

## When Ryan approves

- data.js strings, then the log and help lines in battle.js, campaign_run.js, campaign_meta.js and ui3d.js (each listed above with its file).
- G1 and G3 pick up the data.js strings through the tables exporter; the few battle.js log lines need the same text in `godot/rules/` (G1), and the campaign lines in `godot/campaign/` (G3). The story helper changes its own text in `godot/story/` (for example "Dynast Setekh").
- Ids stay, so saves, the sims and parity hashes are unaffected (names are not in the parity canon).
- After applying: grep the game files for every "Current" word (count 0 except section 8), and the em dash count stays 0.
