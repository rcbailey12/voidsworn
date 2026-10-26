# R44 and R47 rename map: every player-facing name to change (DRAFT for Ryan)

Status: DRAFT, Oct 26 2026, naming-and-lore helper. Supersedes stream B's first draft of this file (e5d959a), which it builds on: every row of that draft is here, either kept, changed (section 13 says which and why) or moved to the kept list. Nothing is applied. When Ryan approves:
- **stream B** applies the data.js strings and the JS log and help lines (data.js, battle.js, campaign_run.js, campaign_meta.js, ui3d.js), then the G1 and G3 owners mirror the few hard-coded Godot copies listed here (godot/rules/rules.gd, godot/scenes/battle/battle.gd, godot/ui/campaign/campaign_ui.gd, godot/main/title.gd);
- **the story helper** applies everything under `godot/story/` (section 9) and the `tokens.gd` name list (section 14);
- **the portraits helper** updates the prompts in `tools/portraits/make_batches.py` (section 11) before the next batch.

Rules:
- Display strings only. Every internal id stays (`deathless`, `d_scythe`, `d_jackal`, `d_harvester`, `b_razor`, `i_carrier`, `gauss`, `doom`, `pulsar`, `shard`, `las`, `hellfire`, `auspex`, `cogitator`, `phylactery`, event ids `astropath`, `tomb`, `tombhome`, style `tomb`, admiral ids `nekhet`, `sekhmar`, `anuket`, `khepra`, `vex`, `malek`, `mending`, `grax`, `mott`, portrait files and crest files). Saves, sims and parity hashes are unaffected (names are not in the parity canon).
- Generated files follow by themselves: `godot/rules/data/tables.json` and `godot/campaign/data/campaign_tables.json` come from the tables exporter, `godot/campaign/test/oracle/*.js` are copies of the JS, and `voidsworn-3d.html` is a build. They are not listed.
- The why of every new name, and the alternatives, are in `lore_bible.md`. The phone version is `lore_summary.md`.

How the "Where" column was made: a script searched the files for each exact old string (data.js, battle.js, core.js, campaign_run.js, campaign_meta.js, campaign3d.js, ui3d.js, head.html, main3d.js, everything under godot/story, godot/ui, godot/main, godot/scenes, godot/portraits, godot/rules (code only), godot/campaign/campaign.gd and tools/portraits/make_batches.py), at main 06b96d7. head.html, core.js, campaign3d.js and main3d.js had no hits. Where an old string is part of a longer line, the table quotes enough to find it.

**Tags in the Why column:** "Mild" means a common word that 40k also uses, changed because Ryan asked for the milder words too (R44). Sections 10 and 11 are outside 40k and are Ryan's call.

## Decisions Ryan may want to weigh in on (details in lore_bible.md section 8)

1. **Deathless naming family:** court of record (pick), barrow kings (stream B's draft), or Egyptian lightly renamed.
2. **Deathless hull ladder:** writ, warrant, edict, The Unadjourned (pick). Scythe, Jackal and Harvest Ship are all Battlefleet Gothic Necron classes, so all three must change.
3. **Faction names:** "The Deathless Dynasty" becomes "The Deathless Court" (the story already says the Court). The Chorus, Hegemony, Voidsworn, Corsairs and Ithar keep their names.
4. **Weapons:** Brand (Las-), Cinder torpedo (Hellfire), Flux (Gauss), Verdict arc (Doom arc), Chord lance (Pulsar lance), The Ninefold Maw (Hive Leviathan).
5. **Ranks and titles:** Censor-Captain Malek Draven, Admiral Severin Vex, Deathless ranks Bailiff to Chancellor, sample rival High Magistrate Halvane the Unpardoning (was Justiciar; Ryan OK'd Justiciar for now).
6. **Outside 40k:** Star Wars echoes in the Hegemony, Grax Ironjaw (Age of Sigmar), Old Mott Brannigan (Futurama), the Ember Choir patron (song word).


## 1. Factions, blurbs and the title screen

| Old | New | Where (file:line) | Why |
|---|---|---|---|
| The Deathless Dynasty | The Deathless Court | data.js:95,124 | Necron armies are Dynasties. The story already calls them the Court (outlines.md). |
| Machine necropolis-ships. Gauss weapons tear through shields, and wrecks sometimes stand back up. | Machine vault-ships of an undying court. Flux weapons cut through shields, and wrecks sometimes stand back up. | data.js:125 | Necropolis is the Necron home word; gun family renamed. |
| The Dynasty rises | The Court rises | campaign_meta.js:178 | Dynasty. |
| An imperial war-machine of wedge-hulled destroyers. | A disciplined war-machine of wedge-hulled destroyers. | data.js:113 | "Imperial" points at the Imperium. |
| Gothic crusader battleships. | Spired crusader battleships. | data.js:111 | "Gothic battleships" names Battlefleet Gothic. |
| Command a crusade of gothic capital ships through three hostile sectors. | Command a crusade of black-iron capital ships through three hostile sectors. | campaign_meta.js:31; godot/ui/campaign/campaign_ui.gd:257; godot/main/title.gd:66 | Title-screen tagline; "gothic capital ships" is the Battlefleet Gothic read. The most-seen line in the game. |

## 2. Weapons

| Old | New | Where (file:line) | Why |
|---|---|---|---|
| Las-repeater | Brand repeater | data.js:35 | "Las" is the Imperial lasgun prefix. A brand is a burning torch and a branding iron: fire, oath and penance. |
| Las-battery | Brand battery | data.js:35 | Same family. |
| Heavy las-broadside | Heavy brand broadside | data.js:35 | Same family. |
| Las-turret | Brand turret | data.js:35 | Same family. |
| Hellfire torpedo | Cinder torpedo | data.js:35 | Hellfire is an Imperial missile and round. Not "Pyre torpedo" (stream B): Pyre is already the Corsair boss (Pyre-Barge) and two Ember boons. |
| Macro battery | Gun battery | data.js:5 | Battlefleet Gothic Imperial broadside gun. |
| Heavy macro battery | Heavy gun battery | data.js:6 | Same. |
| dorsal macro battery | dorsal gun battery | data.js:549 | Variant text follows. |
| Bio-plasma | Bile plasma | data.js:17 | Named Tyranid weapon. |
| Spore mines | Spore drifts | data.js:18 | Tyranid unit. |
| Pulsar lance | Chord lance | data.js:19,39 | Aeldari lance in Battlefleet Gothic. "Chord" gives the song motif to the only faction that owns it, and matches Vaelen's "Chord of light". Option: Dawn lance (stream B). |
| Shuriken cannon | Shard cannon | data.js:24 | Aeldari weapon. Ithar override already shows "Prism shards". |
| A pulsar lance in place of the shuriken cannon. | A chord lance in place of the shard cannon. | data.js:556 | Variant text follows. |
| Gauss flayer | Flux cutter | data.js:21,40 | Necron signature gun. Flux keeps the "goes through armour" physics feel. |
| Gauss sentries | Flux sentries | data.js:22 | Same family. |
| Adds gauss sentries | Adds flux sentries | data.js:558 | Variant text follows. |
| Both gauss guns on turrets, a gauss sentry | Both flux guns on turrets, a flux sentry | data.js:568 | Arc unlock text follows. |
| a second bio-plasma volley | a second bile plasma volley | data.js:566 | Arc unlock text follows. |
| Gauss pylon | Flux spire | data.js:40 | Gauss Pylon is a Necron fortification; "pylon" alone is StarCraft. Not "Flux warden" (warden is a Voidsworn hull). |
| Gauss shredder | Flux shredder | data.js:40 | Same family. |
| gauss:'Gauss' | gauss:'Flux' | data.js:30 | Weapon kind label on cards and tooltips (KIND_NAME). |
| Doom arc | Verdict arc | data.js:23 | Echoes the Necron Doomsday Ark. "Verdict" is the Court's word: one heavy judgement every other turn. Option: Ruin arc (stream B). |
| doom:'Doom arc' | doom:'Verdict arc' | data.js:40 | Deathless override, same. |
| Its doom arc sits on a turret | Its verdict arc sits on a turret | data.js:559 | Variant text follows. |
| Doom arcs deal +20% damage | Verdict arcs deal +20% damage | data.js:231 | Admiral text follows. |
| flayed by gauss fire | unmade by flux fire | battle.js:925 | Kill-cause log line. |
| gauss weapons mostly ignore them | flux weapons mostly ignore them | campaign_meta.js:160; godot/ui/campaign/campaign_ui.gd:897 | How-to-play text. |
| Lances and gauss guns make up | Lances and flux guns make up | godot/story/data/titles.json:10 | Title rule text. |

## 3. Hulls and classes

| Old | New | Where (file:line) | Why |
|---|---|---|---|
| Hive Leviathan | The Ninefold Maw | data.js:88 | Hive Fleet Leviathan is the best-known Tyranid fleet. Bosses are proper names (The Iron Mandate, The Unadjourned); nine mouths is the Chorus crest. Options: Brood Colossus (stream B), The Gorging Deep. |
| cls:'Bio-titan' | cls:'Colossus' | data.js:88 | Bio-titan is a Tyranid class word. |
| Chorus razorfiend | Chorus bladeback | data.js:86; godot/story/unlocks.md:19 | Razorfiend is a Tyranid cruiser class in Battlefleet Gothic (lexicanum "Razorfiend Cruiser"). |
| Razorfiend stalker | Bladeback stalker | data.js:555 | Same. |
| Sun-eater razorfiend | Sun-eater bladeback | data.js:566; godot/story/unlocks.md:19; godot/story/data/arcs.json:33 | Arc unlock name follows. |
| Ithar wraithcarrier | Ithar cradleship | data.js:93; godot/story/unlocks.md:20 | Wraithships are the Aeldari line. "Cradle" is already the Ithar refit word (Wing cradle, Star torpedo cradle). Option: lightcarrier (stream B). |
| Archive wraithcarrier | Archive cradleship | data.js:567; godot/story/unlocks.md:20; godot/story/data/arcs.json:41 | Arc unlock name follows. |
| Deathless scythe | Deathless writ | data.js:96,369; godot/story/outlines.md:311 | Scythe-class Harvest Ship is a Battlefleet Gothic Necron class. Court ladder: writ, warrant, edict (a writ is the smallest order of a court). |
| Deathless jackal | Deathless warrant | data.js:97 | Jackal-class Raider is a Battlefleet Gothic Necron class, and the jackal is Anubis. |
| Deathless harvester | Deathless edict | data.js:98 | Same Necron harvest-ship family. |
| The Undying Throne | The Unadjourned | data.js:99 | Throne is the Necron and Imperial seat. The first Court's session was adjourned and never closed; its flagship is that session, still sitting. Options: The Undying Bench, The Last Session. |
| cls:'Tomb-ark' | cls:'Vault-ark' | data.js:99 | Echoes the Necron Ghost and Doomsday Arks. The story uses vaults. |
| Scythe sentinel | Writ sentinel | data.js:558 | Variant follows. |
| Harvester tomb-turret | Turret edict | data.js:559 | Variant follows; tomb. |
| Court guard destroyer | Honour-guard warrant | godot/story/unlocks.md:21; godot/story/data/arcs.json:49 | Arc unlock name follows the hull (story side). |
| Jackal court guard | Honour-guard warrant | data.js:568 | Arc unlock name follows the hull (data.js side, c88567c). |
| cls:'Battle-barge' | cls:'War-barge' | data.js:82 | The Battle Barge is the Space Marine flagship type. |

## 4. Admirals, Commands and ranks

| Old | New | Where (file:line) | Why |
|---|---|---|---|
| Admiral Castellan Vex | Admiral Severin Vex | data.js:202; godot/story/story.gd:154,180; godot/story/test/story_test.gd:233,235; tools/portraits/make_batches.py:41 | Castellan is an Imperial Knight and Space Marine rank. Every other Voidsworn admiral is rank, first name, surname, so Vex gets a first name. Option: Admiral Provost Vex (stream B). |
| Inquisitor-Captain Malek Draven | Censor-Captain Malek Draven | data.js:203 | Inquisitor is among the most recognisable 40k titles. A censor judges; fits the ship name Bright Censure. Option: Oath-Captain. |
| Overlord Nekhet the Undying | Chancellor Aumery the Undying | data.js:230; tools/portraits/make_batches.py:58 | Overlord is the Necron noble rank; Nekhet is Egyptian-coded (Necron look). |
| Sekhmar the Reaper | Magistrate Morvaunt the Reaper | data.js:231 | Egyptian-coded name. |
| Cryptlord Anuket | Gaudry of the Quiet Writ | data.js:232 | Echoes the Necron Cryptek; Anuket is an Egyptian goddess. Epithet fits "Silent hunters". |
| Khepra the Patient | Orrance the Abiding | data.js:233 | Egyptian-coded; "the Patient" is also a Nemesis scar, a captain epithet and a Nemesis personality. |
| Reanimation protocol | Reassembly protocol | data.js:230; godot/story/data/voices.json:336 | Necron Reanimation Protocols. The game already says ships "reassemble". |
| Tomb-blade strike | Writ of seizure | data.js:232; godot/story/data/voices.json:368 | Tomb Blades are a Necron unit. Court voice. |
| The Mending Choir | The Mending Throng | data.js:224; tools/portraits/make_batches.py:26 | Song belongs to the Ithar only (story rule). A throng is many bodies in one crowd. Portrait files keep the id "mending". Option: The Suture-Mother. |
| doc:'Acid chorus' | doc:'Acid spray' | data.js:225 | Doctrine label read as music. |
| Imperial broadside | Admiralty broadside | battle.js:1109 | Hegemony boss Command; Imperial. |
| Hive regrowth | Brood regrowth | battle.js:1109 | Chorus boss Command; Hive is the Tyranid word. |
| ranks:['Warden','Overseer','Cryptlord','Overlord','Dynast'] | ranks:['Bailiff','Assessor','Recorder','Magistrate','Chancellor'] | data.js:522 | Cryptlord, Overlord, Dynast are Necron ranks. Court offices, lowest to highest. |
| 'Elder throat','Matriarch' | 'Elder throat','Great throat' | data.js:520 | Chorus rank 5: "Matriarch" is the admiral's defining word; every random brood-queen captain would share it. |
| Lance adept | Lance savant | data.js:175 | Adept is the Adeptus word. "Savant" already in use (Deflector savant). |

## 5. Refits, relics, abilities, aspects, archetypes, Nemesis adaptations and faction verbs

| Old | New | Where (file:line) | Why |
|---|---|---|---|
| Auspex array | Vigil array | data.js:153 | Auspex is the Imperial scanner. Vigil is a Voidsworn word (Hold a vigil, Everwatch). Option: Augury array (stream B). |
| Targeting cogitator | Targeting reckoner | data.js:164 | Cogitator is the Imperial computer word. |
| Void shield capacitor | Ward capacitor | data.js:156 | Void shields are Imperial. |
| Macro loaders | Battery loaders | data.js:158 | Follows Gun battery. |
| Nova cannon | Sunburst cannon | data.js:136 | The Nova Cannon is Battlefleet Gothic's Imperial prow gun. Option: Spinal cannon. |
| Nova impact | Sunburst impact | ui3d.js:448 | Targeting tooltip follows. |
| Reanimation beam | Reassembly beam | data.js:144 | Necron reanimation. |
| Deathless reanimation beams | Deathless reassembly beams | campaign_meta.js:165 | Help text follows. |
| ' reanimates ' | ' reassembles ' | battle.js:1189; godot/rules/rules.gd:3222 | Battle log for the reclaim ability. |
| Archeotech rangefinder | Founders' rangefinder | data.js:188 | Archeotech is a 40k-only word. |
| Xeno shield lattice | Alien shield lattice | data.js:189 | Xeno and xenos are the Imperium's word for aliens. |
| Deathless phylactery | Deathless reprieve | data.js:191 | A Necron lord's relic (and a lich's). The relic revives your first lost ship: a reprieve, in the Court's law. |
| The phylactery hums. | A reprieve is granted. | battle.js:936; godot/rules/rules.gd:2477 | Battle log follows. |
| Wraithbone compass | Dawnglass compass | data.js:193,265 | Wraithbone is the Aeldari ship material (base relic and the Corsair name). |
| Wraithbone keel | Dawnglass spine | data.js:261 | Wraithbone; "keel" is a sea-ship word. |
| Farsight crystal | Longsight crystal | data.js:261,481 | Farsight is a famous Tau commander. |
| Shuriken feeders | Shard hoppers | data.js:261 | Shuriken (and Tyranid "feeders"). |
| Seer’s sight | Archivist’s eye | data.js:261 | Mild: seer plus a dying elder race is the Farseer read; the story's Ithar have archivists, not seers. |
| Seer’s eye | Archivist’s lens | data.js:267 | Mild, same. |
| Living-metal plating | Vault-iron plating | data.js:262 | Living metal is the Necron hull material. |
| Tomb sight | Recorder's sight | data.js:262 | Tomb; record motif. |
| Inertialess drive | Phase engine | data.js:262 | Inertialess Drive is a Battlefleet Gothic Necron rule. Matches the Deathless drive rule name (Phase drive). |
| Quantum shield node | Seal-ward node | data.js:262 | Quantum shielding is a Necron vehicle rule. |
| Quantum regenerator | Seal-ward regenerator | data.js:262 | Same. |
| Gauss accelerators | Flux accelerators | data.js:262 | Gun family. |
| Doom-arc focus | Verdict-arc focus | data.js:262 | Gun family. |
| Repair scarabs | Repair attendants | data.js:262 | Canoptek Scarabs are the Necron repair swarm. The Deathless portraits already show small attending drones. |
| Scarab hive | Attendant bay | data.js:262 | Scarab and hive. |
| Crown of the first dynasty | Seal of the first Court | data.js:268 | Dynasty and crown (the story took the crown off the Deathless crest). |
| Phylactery of the Undying | Reprieve of the Undying | data.js:268 | Phylactery. |
| Chronometron | Session clock | data.js:268 | A named Necron Cryptek relic. |
| Annals of the dynasty | Annals of the Court | data.js:268 | Dynasty. |
| Living-metal weave | Vault-iron weave | data.js:268 | Living metal. |
| Harvest engine | Forfeiture engine | data.js:268 | Mild: the harvest motif is the Necron harvest-ship family. Forfeiture is the Court seizing goods. |
| Imperial targeting array | Admiralty targeting array | data.js:264 | Imperial. |
| Memory of the hive | Memory of the brood | data.js:266 | Hive. |
| Aspect of the Hive | Aspect of the Brood | data.js:690 | Hive. |
| chorus:'Hive cluster' | chorus:'Brood cluster' | data.js:593 | Fleet archetype name; hive. |
| ithar:'Wraith host' | ithar:'Starling host' | data.js:593 | Wraith; starlings are already the Ithar wings. |
| chorus:'Titan pod' | chorus:'Bloat pod' | data.js:592 | Titan (Bio-titan) is a Tyranid class word. |
| deathless:'Scythe harvest' | deathless:'Writ procession' | data.js:591 | Hull renamed; harvest. |
| deathless:'Harvest ark' | deathless:'Attendant ark' | data.js:593 | Harvest. |
| shields:'Quantum ward' | shields:'Seal ward' | data.js:480 | Nemesis adaptation; quantum shielding. |
| pd:'Gauss pylons' | pd:'Flux spires' | data.js:480 | Nemesis adaptation; gun family. |
| armor:'Grave-alloy shell' | armor:'Vault-iron shell' | data.js:480 | Nemesis adaptation (stream B already moved it off living metal; vault, not grave, to match the story). |
| aim:'Barrow sight' | aim:'Recorder\'s sight' | data.js:480 | Nemesis adaptation (stream B moved it off tomb; record motif). |
| aim:'Farsight crystals' | aim:'Longsight crystals' | data.js:481 | Nemesis adaptation; Farsight. |
| aim:'Augury rites' | aim:'Vigil rites' | data.js:484 | Nemesis adaptation; matches the Vigil array refit. |
| evasion:'Litany of speed' | evasion:'Oath of speed' | data.js:484 | The story already moved Voidsworn off "litany" (rite-keepers, oath-readers). |
| n:'Waken the legion' | n:'Wake the reserve' | data.js:501 | Ties the verb to the story's sleeping reserve (Deathless beat 2). |
| deathless:'reclamation' | deathless:'assize' | data.js:270 | What a Deathless run is called (RUN_WORD). Reclaiming worlds is a Necron theme; an assize is a court travelling its circuit to try cases. Option: session. |
| free once a tomb-world has woken for you | free once a vault-world has woken for you | data.js:501 | Tomb world. |

## 6. Events, battle log and map text

| Old | New | Where (file:line) | Why |
|---|---|---|---|
| Your auspex finds an ancient gothic warship drifting without power, its hull etched with prayers no one has spoken in ten thousand years. | Your scanners find an ancient spired warship drifting without power, its hull etched with prayers no one has spoken in nine thousand years. | data.js:273 | Auspex; "gothic warship"; "ten thousand years" is the Imperium's stock span. |
| Could hold archeotech | Could hold founders' tech | data.js:274 | Archeotech. |
| archeotech and salvage | founders' tech and salvage | data.js:319 | Archeotech. |
| The astropath’s vision | The far-dreamer’s vision | data.js:281 | Astropaths are the Imperium's telepaths (event id astropath kept). |
| Your fleet astropath wakes screaming | Your fleet’s far-dreamer wakes screaming | data.js:281 | Same. |
| sailing through a warp-rift | sailing through a rift | data.js:281 | The Warp. |
| A dynastic beacon | A Court beacon | data.js:281 | Dynasty. |
| An old dynastic beacon pulses from beyond a rift. Something of the dynasty is still out there. | An old Court beacon pulses from beyond a rift. Something of the Court is still out there. | data.js:281 | Dynasty. |
| A seer’s dream | An archivist’s dream | data.js:281 | Mild (Farseer read). |
| Your seer dreams | Your archivist dreams | data.js:281 | Mild, same. |
| t:'Warp storm' | t:'Rift storm' | data.js:287 | The Warp. "Rift" is already the game's word. |
| An Ithar seer | An Ithar archivist | data.js:290 | Mild; the event becomes an archivist trading treasures (fits the story's fussy Ithar archivists). |
| Its seer offers a trade | Its archivist offers a trade | data.js:290 | Mild, same. |
| A sealed tomb-world | A sealed vault-world | data.js:365 | Tomb world is the Necron home (event id tomb kept). |
| hums under your keels | hums beneath your hulls | data.js:365 | Keel is a sea-ship word (house rule). |
| A sleeping tomb-world | A sleeping vault-world | data.js:368 | Tomb world. |
| A tomb-world of your own dynasty, its legions dormant. | A vault-world of your own Court, its legions dormant. | data.js:368 | Tomb world, dynasty. |
| l:'Wake one scythe' | l:'Wake one writ' | data.js:369 | Hull renamed. |
| A Deathless scythe joins the fleet at full hull. | A Deathless writ joins the fleet at full hull. | data.js:369 | Hull renamed. |
| Let the living metal knit it | Let the vault-iron knit it | data.js:343 | Living metal. |
| will drop out of warp | will jump in | battle.js:23 | The Warp (battle event warning). |
| Enemy reinforcements drop out of warp. | Enemy reinforcements jump in. | battle.js:23 | Same. |
| A friendly ship drops out of warp to help. | A friendly ship jumps in to help. | battle.js:24 | Same. |
| on the auspex. | on the scanners. | battle.js:354; godot/story/data/voices.json:76; godot/scenes/battle/battle.gd:433; godot/rules/rules.gd:1225 | Battle start log; auspex. |
| Long-range auspex confirms | Long-range scans confirm | campaign_meta.js:112; godot/ui/campaign/campaign_ui.gd:995 | Sector intro; auspex. |
| Auspex confirms | Scanners confirm | campaign_run.js:540; godot/ui/campaign/campaign_ui.gd:999 | Godot sector intro; auspex. |

## 7. Nemesis name tables (data.js NEM_FAC, NEM_LINES)

Written against main 06b96d7, which already has stream B's c88567c clean-up (section 13).

| Old | New | Where (file:line) | Why |
|---|---|---|---|
| pre:['Ald','Cor','Esm','Hal','Ord','Gyr','Wulf','Sig','Mor','Ed'] | pre:['Hal','Sed','Thur','Os','Bel','Cor','Tan','Wyst','Ful','Ermen'] | data.js:461 | Stream B already moved these off Egyptian (c88567c) to barrow-king roots. Court-tongue roots instead (bible 7.9). The fem list follows: fem:['Bel','Ermen'] (was Esm, Ed, Sig). |
| post:['ric','mar','wyn','gar','wine','mund','red','ith','helm','wold'] | post:['vane','ric','mont','isant','bert','gar','cred','mund','ance','ard'] | data.js:461 | Same. Can roll "Halvane", the story's sample rival, on purpose. |
| titles:['Ash-king','Regent','Barrow-king','Dust-sovereign'] | titles:['Lord Chancellor','High Magistrate','Master of Rolls','Lord Recorder'] | data.js:461 | Kings and crowns put back what the story removed (the crest lost its crown). Court offices. (Before c88567c: Phaeron, Dynast, Tomb-lord, Overlord.) |
| 'Cracked-Crown' | 'Cracked-Seal' | data.js:462 | Crown; the seal is the Court's object. Also in its scarBy list. |
| 'Hollow-Eye','the Patient' | 'Hollow-Eye','the Adjourned' | data.js:462 | "the Patient" is also a persona, a captain epithet and Khepra's epithet. Also in its scarBy list (fled). |
| pre:['Saint','Brother','Censor','Provost','Shriver','Votary','Arch-deacon','Cantor','Sister','Lector'] | pre:['Saint','Brother','Censor','Provost','Oath-reader','Votary','Arch-deacon','Pilgrim','Sister','Lector'] | data.js:473 | Shriver means confessor (the story moved to oath-readers); a cantor is a singer (song is Ithar). The rest of stream B's list stands. |
| 'Lord Censor','Arch-shriver' | 'Lord Censor','Keeper of the Rite' | data.js:473 | Shriver as above. Ties to the story's Rite and rite-keepers. |
| 'Burnt-Psalm' | 'Burnt-Oath' | data.js:474 | Song word. Also in its scarBy list. |
| 'the Branded','Ironhand' | 'the Branded','Iron-Armed' | data.js:474 | Mild: Iron Hands is a Space Marine chapter. Also in its scarBy list. |
| pre:['Seventh','Hollow','Wet','Grieving','Ninefold' | pre:['Seventh','Hollow','Wet','Grieving','Bloated' | data.js:467 | "Ninefold" plus "Maw" would roll the boss name The Ninefold Maw. |
| pre:['Konrad','Ilsa','Viktor' | pre:['Konrad','Marit','Viktor' | data.js:470 | Ilsa is Grand Admiral Ilsa Kassar's first name; a rival named Ilsa reads as her. The fem list follows (Ilsa to Marit). |
| post:['Tooth','Maw','Gut','Vane' | post:['Tooth','Maw','Gut','Vise' | data.js:458 | Vane is also a Voidsworn surname; keeps each faction's pool its own. |
| scars:['the Burned','Ironjaw' | scars:['the Burned','Steeljaw' | data.js:459 | Follows Grax (section 10). Also in its scarBy list. |

## 8. Name pools: captain names and ship names (clashes included)

Clash rule (lore_bible.md 1.4): no captain pool may roll an admiral's name, and no two factions share a given name. Whole lists are quoted where the list itself changes.

| Old | New | Where (file:line) | Why |
|---|---|---|---|
| 'Ilse','Corvin' | 'Ilse','Crispin' | data.js:252 | Corvin sits beside Corvane (Voidsworn surname) and Corvel (Ithar). |
| 'Isolde','Garrick','Mireille' | 'Rosalind','Garrick','Margery' | data.js:252 | Isolde vs Ithar Ysolde; Mireille vs Ithar admiral Mirelle Starwarden. |
| 'Konrad','Yara' | 'Aldous','Yara' | data.js:252 | Konrad is also a Hegemony first name. |
| 'Halvard','Petra' | 'Hadrian','Perpetua' | data.js:252 | Halvard vs Hegemony Halvar and the rival Halvane; Petra is also Hegemony. |
| 'Holloway','Sable' | 'Holloway','Sedley' | data.js:253 | Sable is the Corsair admiral Sable Venn. |
| first:['Konrad','Ilsa','Dace','Mara','Oskar' | first:['Konrad','Marit','Joost','Mara','Anders' | data.js:518 | Hegemony captains could roll the admirals Ilsa Kassar, Dace Vorn, Oskar Maren. |
| last:['Reiter','Kassel','Brandt','Vorn' | last:['Reiter','Kassel','Brandt','Vollmer' | data.js:518 | Vorn is Commodore Dace Vorn. |
| 'Krogg','Brannigan' | 'Krogg','Mulligan' | data.js:519 | Brannigan is the Corsair admiral (and see section 10). |
| 'Tallow','Ironjaw' | 'Tallow','Steeljaw' | data.js:519 | Ironjaw is the Corsair admiral (and see section 10). |
| names:['Seventh Mouth','Hollow Song' | names:['Seventh Mouth','Hollow Gut' | data.js:520 | Song word. |
| 'Ninefold','Grieving Tide','Brine Hymn' | 'Ninth Tooth','Grieving Tide','Brine Mouth' | data.js:520 | Song word; Ninefold reserved for the boss. |
| 'Sallow Choir' | 'Sallow Rasp' | data.js:520 | Song word. |
| 'Coiled Psalm' | 'Coiled Gullet' | data.js:520 | Song word. |
| first:['Siriel','Aelith','Vaelen' | first:['Siriel','Saephine','Ilvaris' | data.js:521 | Aelith and Vaelen are Ithar admirals. |
| last:['Starglass','Dawnsail' | last:['Starglass','Dawnmere' | data.js:521 | Dawnsail is Aelith Dawnsail. |
| names:['Imhoten','Setekh','Amuneth','Rahotep','Tauret','Menkara','Khepset','Nefrah','Osirak','Ptahmet','Sobekar','Thutem','Wadjen','Hekamun'] | names:['Sedric','Thurstan','Wystan','Belisant','Corbet','Fulke','Hamon','Ivetta','Joscelin','Maud','Rohese','Tancred','Ermengarde','Osmont'] | data.js:522 | Egyptian, Necron-coded; Imhoten is one letter from Imotekh, Setekh sits next to the Necron Sautekh dynasty. Court-tongue names (bible section 6). |
| 'of the Ninth Tomb' | 'of the Ninth Vault' | data.js:522 | Tomb. |
| Hymn of Ruin | Ember of Ruin | data.js:251 | Voidsworn ship name; song belongs to the Ithar. |
| Merciless Litany | Merciless Penance | data.js:251 | Litany (the story removed litanists). |
| Cinder Psalm | Cinder Vow | data.js:251; godot/story/test/career_shots.gd:13 | Song word. |
| Relentless Canticle | Relentless Witness | data.js:251 | Song word. |
| Obsidian Choir | Obsidian Lantern | data.js:251 | Song word; iron lanterns are the story's image. |
| Wrathful Seraph | Wrathful Brand | data.js:251 | Seraph is an Ithar rank. |
| HNS Castellan | HNS Constant | data.js:524 | Castellan (40k rank). |
| HNS Vindicator | HNS Punctual | data.js:524 | The Vindicator is a Space Marine tank. Punctual is a Hegemony joke. |
| Spine Choir | Spine Gullet | data.js:526 | Song word. |
| Hive-node Vesk | Brood-node Vesk | data.js:526 | Hive. |
| Crawling Hymn | Crawling Maw | data.js:526; ui3d.js:21 | Song word (data.js and ui3d.js). |
| Wet Psalm | Wet Mouth | data.js:526 | Song word. |
| 'Hollowsong' | 'Hollowgut' | data.js:526 | Song word. |
| Tomb of Nine Kings | Vault of Nine Seals | data.js:528 | Tomb, kings. |
| Ankh of Ash | Urn of Ash | data.js:528 | The ankh is Egyptian, Necron-coded. |
| Obelisk of Night | Stele of Night | data.js:528 | The Obelisk is a Necron war machine. |
| Crypt of Teeth | Ledger of Teeth | data.js:528 | Crypt (Cryptek); record motif. |
| 'HNS Executor' | 'HNS Comptroller' | ui3d.js:19 | Executor is Vader's flagship (Star Wars). |
| 'Hive-node Ashk' | 'Brood-node Ashk' | ui3d.js:21 | Showcase name; hive. |
| 'Wet Choir' | 'Wet Maw' | ui3d.js:21 | Showcase name; song. |
| 'Crawling Hymn'] | 'Crawling Gut'] | ui3d.js:21 | Showcase name (ui3d.js), song; differs from the data.js rename so the two lists do not share a name. |
| 'Tomb of Ashes' | 'Vault of Ashes' | ui3d.js:23 | Showcase name; tomb. |
| 'Obelisk','Dust Throne' | 'Stele','Dust Seat' | ui3d.js:23 | Showcase names; obelisk, throne. |

## 9. Story layer (godot/story: titles, arcs, voices, rival lines, outlines, tests)

The story helper applies these. Hull, weapon and admiral renames in sections 2 to 4 also reach the story text wherever those names appear.

| Old | New | Where (file:line) | Why |
|---|---|---|---|
| "deathless": "the Flayer" | "deathless": "the Sentencer" | godot/story/data/titles.json:11 | Flayed Ones (Necron). |
| "the Doombringer" | "the Bringer of Writs" | godot/story/data/titles.json:13 | Doom (gun family). |
| "the Lord of Scarabs" | "the Lord of Attendants" | godot/story/data/titles.json:15 | Scarabs. |
| "deathless": "the Reaper" | "deathless": "the Headsman" | godot/story/data/titles.json:27 | Clashes with Magistrate Morvaunt the Reaper; the Court executes by sentence. |
| "the Purifier" | "the Pyrebrand" | godot/story/data/titles.json:27 | Grey Knights Purifiers (and StarCraft). |
| "chorus": "the Brood-Mother" | "chorus": "the Swarm-Mother" | godot/story/data/titles.json:15 | Same words as the Chorus brood-mother hull. |
| from tomb green to gold | from vault green to gold | godot/story/data/arcs.json:47 | Arc paint note; tomb. |
| "unlock_name": "Archive wraithcarrier" | "unlock_name": "Archive cradleship" | godot/story/data/arcs.json:41 | Hull rename. |
| "unlock_name": "Court guard destroyer" | "unlock_name": "Honour-guard warrant" | godot/story/data/arcs.json:49 | Hull rename. |
| "unlock_name": "Sun-eater razorfiend" | "unlock_name": "Sun-eater bladeback" | godot/story/data/arcs.json:33 | Hull rename. |
| Confession extracted. | Judgement delivered. | godot/story/data/voices.json:29 | Confession (the story took confessor to 0). |
| {rival} is on the auspex. | {rival} is on the scanners. | godot/story/data/voices.json:76 | Auspex. |
| Another sector of squatters. | Another sector of trespassers. | godot/story/data/voices.json:326 | "Squatters" on old crownworlds is the Necron line (Sonnet review). The story says trespassers and occupants. |
| Another crown for the reclamation. | Another case for the record. | godot/story/data/voices.json:331 | Crown; reclamation (Necron "reclaim"). |
| Reanimation protocol. Every hull, rebuilt. | Reassembly protocol. Every hull, rebuilt. | godot/story/data/voices.json:336 | Command renamed. |
| Doom arcs charged. | Verdict arcs charged. | godot/story/data/voices.json:345 | Gun family. |
| Tomb-blade strike. All blades, now. | Writ of seizure. Every hull, now. | godot/story/data/voices.json:368 | Command renamed. |
| Heretic. Kneel before the saints | Oathbreaker. Kneel before the saints | godot/story/data/voices.json:392 | Heretic. |
| the dynasty's ground | the Court's ground | godot/story/data/voices.json:412 | Dynasty. |
| The dynasty has noted you. | The Court has noted you. | godot/story/data/rival_lines.json:416 | Dynasty. |
| The dynasty does not accept this ending. | The Court does not accept this ending. | godot/story/data/rival_lines.json:447 | Dynasty. |
| entered my tomb | entered my vault | godot/story/data/rival_lines.json:458 | Tomb. |
| The living metal remembers and thickens. | The vault-iron remembers and thickens. | godot/story/data/rival_lines.json:454 | Living metal. |
| One fewer squatter. | One fewer trespasser. | godot/story/data/rival_lines.json:443 | Squatter. |
| Squatter detected. Correct. | Trespasser detected. Correct. | godot/story/data/rival_lines.json:476 | Squatter. |
| The litany calls that a test | The Rite calls that a test | godot/story/data/rival_lines.json:22 | Litany (Voidsworn rival). |
| at the end of the litany | at the end of the Rite | godot/story/data/rival_lines.json:34 | Litany. |
| a verse in my litany of hate | a line in my oath of hate | godot/story/data/rival_lines.json:51 | Litany, and "verse" is a song word. |
| Sing over the ashes. | Pray over the ashes. | godot/story/data/rival_lines.json:39 | Voidsworn rival singing; song belongs to the Ithar. |
| A Deathless scythe joins the fleet. | A Deathless writ joins the fleet. | godot/story/outlines.md:311 | Outline beat 3 blue option; hull rename. |
| custodian | vault-keeper | godot/story/outlines.md:24,285,290,294,305,314; godot/story/outlines_variants.md:188,191,193,207 | Mild: Custodian Guard and Custodian Wardens are 40k units (Adeptus Custodes). Every Deathless "custodian" in the outlines and variants. |
| session adjourned ten thousand years ago | session adjourned nine thousand years ago | godot/story/outlines.md:285 | Mild: "ten thousand years" is the Imperium's stock span. Optional. |
| Justiciar | High Magistrate | godot/story/test/career_shots.gd:42; godot/story/test/story_test.gd:248,254,255 | Sample rival "Justiciar Halvane the Unpardoning" becomes "High Magistrate Halvane the Unpardoning". Justicar is a Grey Knights rank and a Chaos Gate: Daemonhunters class; one letter apart. Ryan OK'd the name for now (R47), so this is a weigh-in. |
| Admiral Castellan Vex | Admiral Severin Vex | data.js:202; godot/story/story.gd:154,180; godot/story/test/story_test.gd:233,235; tools/portraits/make_batches.py:41 | Test fixtures and comments follow the admiral (story.gd, story_test.gd). |
| Warlord Grax Ironjaw | Warlord Grax Steelgrin | data.js:218; godot/story/README.md:96; godot/story/test/story_test.gd:195,276; tools/portraits/make_batches.py:49 | Follows section 10 if Ryan agrees (README, tests). |
| "Hollow Song", "title": "Matriarch" | "Hollow Gut", "title": "Spawn-mother" | godot/story/test/story_test.gd:323 | Test fixture follows the Chorus pools. |

## 10. Outside 40k (Ryan's call)

Not Warhammer. Listed so Ryan can decide in the same pass; my lean is to change them.

| Old | New | Where (file:line) | Why |
|---|---|---|---|
| Warlord Grax Ironjaw | Warlord Grax Steelgrin | data.js:218; godot/story/README.md:96; godot/story/test/story_test.gd:195,276; tools/portraits/make_batches.py:49 | Not 40k: Ironjawz are the Age of Sigmar orc faction (Games Workshop). His portrait already has "a grin of steel". |
| Old Mott Brannigan | Old Mott Rafferty | data.js:220 | Not 40k: Zapp Brannigan is Futurama's famous space captain. The story only ever says "Old Mott". |
| n:'Turbolaser' | n:'Pulse cannon' | data.js:11 | Star Wars. Hegemony already shows "Plasma lance" for it. |
| n:'Heavy turbolaser' | n:'Heavy pulse cannon' | data.js:12 | Star Wars. |
| a third turbolaser turret | a third pulse cannon turret | data.js:551 | Variant text follows. |
| Turbolaser cyclers | Plasma cyclers | data.js:258 | Star Wars. |
| Proton magazine | Fusion magazine | data.js:258 | Star Wars proton torpedoes. |
| Hyperdrive motivator | Jump-drive regulator | data.js:264 | A Star Wars line. |
| Durasteel weave | Hardsteel weave | data.js:264 | Star Wars material. |
| Vanguard star cruiser | Vanguard cruiser | data.js:74 | "Star cruiser" is a Star Wars class word. |
| star cruisers hold +1 wing | cruisers hold +1 wing | data.js:216 | Admiral text follows. |
| Dominion star dreadnought | Dominion dreadnought | data.js:75 | "Star Dreadnought" is a Star Wars class word. |
| Interdictor destroyer | Cordon destroyer | data.js:73; godot/story/unlocks.md:17 | The Interdictor is a Star Wars cruiser class. A cordon is what the Hegemony does to a system. |
| Interdictor column escort | Cordon column escort | data.js:564; godot/story/unlocks.md:17; godot/story/data/arcs.json:17 | Arc unlock follows. |
| ember:{n:'The Ember Choir' | ember:{n:'The Ember Host' | data.js:624 | Not 40k: a cross-faction patron that sings. Song belongs to the Ithar; optional. Boons follow: Choir Warheads to Ember Warheads, Hymn of Reloading to Rite of Reloading, quote "Burn, and let the void burn with you." |

## 11. Portrait prompts (not shown to players, but they set the look)

`tools/portraits/make_batches.py`. Already-made paintings keep their files; these words go before the next batch so new faces stop drifting toward 40k.

| Line | Words now | Change to | Why |
|---|---|---|---|
| 41 | "Admiral Castellan Vex" | "Admiral Severin Vex" | Admiral rename |
| 42 | "ornate ceramite shoulder plates, red wax votive seals and parchment oath strips pinned to the chest" | "ornate armoured shoulder plates, names chalked in white across the chest plate, a brand scar on the brow" | Ceramite is a 40k material; wax seals with parchment strips are the Imperial purity seal; the chalked names are the Voidsworn's own motif |
| 43, 73 | "tall gothic viewport", "battered gothic armour" | "tall spired viewport", "battered black-iron armour" | Battlefleet Gothic read |
| 14, 18 | plate texts "gothic warship bridge interior with candles and reliquaries", "black tomb-like machine vault" | "spired warship bridge lit by iron lanterns", "black machine vault lined with record script" | Same; tomb |
| 49 | "Warlord Grax Ironjaw" | "Warlord Grax Steelgrin" (if section 10 is approved) | Age of Sigmar |
| 58 | "Overlord Nekhet the Undying of the Deathless Dynasty" | "Chancellor Aumery the Undying of the Deathless Court" | Admiral and faction rename |
| 26 | "The Mending Choir" | "The Mending Throng" | Admiral rename |
| 70 | "a gaunt zealot inquisitor-admiral" | "a gaunt zealot censor-admiral" | Inquisitor |
| 71 | "war-priest commander ... heavy ceramite plates covered in scripture" | "war-priest commander ... heavy iron plates chalked with names" | Ceramite; the purity-scripture look |
| 72 | "flagellant-admiral ... litany tattoos" | "penitent admiral ... oath brands" | Flagellant and litany are Imperial (Ecclesiarchy) tells |
| 73 | "an old castellan" | "an old crusade-master" | Castellan |
| 78 | "commissar-admiral" | "political-officer admiral" | Commissar is the Imperial Guard officer |
| 97 | "a hive-mind mass" | "a thinking mass" | Hive mind is Tyranid |
| 102 | "a gaunt Ithar inquisitor" | "a gaunt Ithar duelist" | Inquisitor |
| 104 | "Ithar war-matriarch" | "Ithar house-elder" | Matriarch is the Chorus admiral's word |
| 106 | "an Ithar archon" | "an Ithar archivist" | Archon is the Drukhari (dark Aeldari) ruler |
| 110 | "a cluster of black obelisk processors" | "a cluster of black record-stacks" | Obelisk is a Necron war machine |
| 112 | "thousands of tiny black beetle-shaped drones" | "thousands of tiny black attendant drones" | Beetle swarm reads as Canoptek Scarabs |
| 114 | "a sarcophagus-shaped machine split open" | "a sealed vault door split open" | Sarcophagus is the Necron and Egyptian tell |

The style line for Deathless portraits stays: a machine mind with no humanoid body, ceramic plates and black metal round a green core, attendant drones. It is the best original idea in the faction and is not Necron (Necrons are metal skeletons).

## 12. Looked at and kept

Say if you want any of these changed too.

- **Generic military and church words:** Lance, Penance lance, Lance array; Penitent, Saint, Brother, Arch-deacon, Lector, Crusade, Crusade-master, Pale Crusader, Censer, Reliquary, Cathedral-class, Votive; Warden-class (warden alone is generic, though "Custodian Wardens" is a 40k unit); Tithe (the tithe vault, Tithe ledger, Grave Tithe: an old church word, mild); Iron Requiem (a mass for the dead; mild).
- **Death words:** Undying, the Reaper, Harvest of souls, Reaping arcs, Silent Procession, the Unsleeping, Sepulchre, Ossuary, legion and legions (Roman; the approved story uses them).
- **Corsair words:** Corsairs (generic pirates, even though 40k also has Aeldari Corsairs), Hulk, Gun-hulk, Warlord, Reaver, Scrap-baron, Reaver-king, Krag, Gor, Snag, Skarn, Jagg, the Uncaught.
- **Generic sci-fi:** Navigator, Solar sail extension, Interdiction (a doctrine word, not a ship), Ion cannon, Deflector, Plasma drive, Adamant armourweave, Gravitic vanes, Calculus lattice and engine, Dimensional shift, Phase jump, Phase drive.
- **Ithar names:** Shadowblade, Songship, Worldsong Ark, Seraph, Starwarden (no 40k class or rank of these names).
- **Chorus names:** the Matriarch of Nine Throats, Razormaw, Voice of the Deep, brood, brood-mother, drone-spawn, spawn, Discordant volley.
- **Hegemony ship names:** HNS Imperious, HNS Tyrant, HNS Dominator, HNS Arbiter (generic words); Lindqvist as a captain surname only.
- **Void words:** void-shrine and the like ("void" is the game's own word: Voidsworn).
- **Story lines:** "Choose which sin you will confess" (the story helper kept it on purpose), Kharon the Iron Saint (the Greek ferryman, not 40k's Kharn).
- **Penitent-class cruiser:** 40k has "Penitent Engines", but the word is plain English, the hull is built and the arc unlock "Penitent lantern-cruiser" uses it.

## 13. What changed from stream B's draft (e5d959a)

Agreed and kept as stream B wrote them: Brand (Las-), Gun battery, Bile plasma, Spore drifts, Shard cannon, Flux cutter and family, the Deathless Court, the Court rises, Censor-Captain, Reassembly protocol, Admiralty broadside, Brood regrowth, Brood-node, Brood cluster, Starling host, Aspect of the Brood, Memory of the brood, Targeting reckoner, Ward capacitor, Battery loaders, Lance savant, Sunburst cannon, Reassembly beam, Founders' rangefinder and founders' tech, Dawnglass compass and spine, Shard hoppers, Flux accelerators, Annals of the Court, far-dreamer, Rift storm, jump in, scanners, Urn of Ash, Stele of Night, every section 7 Star Wars row, and the Chorus, Hegemony and Dawnglass rows of its section 9.

Changed, with the reason:

| Stream B proposed | Now | Why |
|---|---|---|
| Pyre torpedo | Cinder torpedo | Pyre is already the Corsair boss (Warlord's Pyre-Barge) and two Ember boons |
| Dawn lance | Chord lance | Gives the song motif to the Ithar, who own it; Dawn stays an option |
| Flux warden | Flux spire | Warden is a Voidsworn hull |
| Ruin arc | Verdict arc | The Court's own word |
| Brood Colossus | The Ninefold Maw | Bosses are proper names; nine mouths is the crest |
| lightcarrier | cradleship | "Cradle" is already the Ithar refit word |
| barrow (barrow-world, Barrow-ark, barrow-turret, Barrow sight, of the Ninth Barrow, Barrow of Nine Kings, Barrow of Ashes) | vault (vault-world, Vault-ark, Turret edict, Recorder's sight, of the Ninth Vault, Vault of Nine Seals, Vault of Ashes) | The approved story moved the Deathless to vaults, seals and writs |
| Grave-alloy | Vault-iron | Same |
| Deathless gravehound (jackal) and kept scythe and harvester | writ, warrant, edict | Scythe, Jackal and Harvest Ship are all Battlefleet Gothic Necron classes |
| The Undying Throne kept | The Unadjourned | Throne |
| Dust-sovereign Aldmar, Halric the Reaper, Grave-warden Esma, Morcant the Patient | Chancellor Aumery the Undying, Magistrate Morvaunt the Reaper, Gaudry of the Quiet Writ, Orrance the Abiding | Court tongue; "the Patient" repeats across admiral, scar, persona and captain epithet |
| Grave-warden, Dust-sovereign, Regent (ranks) | Bailiff, Assessor, Recorder, Magistrate, Chancellor | Kings and crowns came off the Deathless in the story |
| Ash-king, Regent, Barrow-king, Dust-sovereign (Nemesis titles) | Lord Chancellor, High Magistrate, Master of Rolls, Lord Recorder | Same |
| Old English barrow name parts (Ald, Cor, Esm / ric, mar, wyn) | Court-tongue parts (Hal, Sed, Thur / vane, ric, mont) | Same family idea, fewer kings; can roll the story's Halvane |
| Grave-knife strike | Writ of seizure | Court voice |
| Repair motes, Mote hive | Repair attendants, Attendant bay | Matches the attendant drones in the Deathless portraits |
| Deathless heart-urn | Deathless reprieve | The relic revives a lost ship: a reprieve in the Court's law; urn was barrow |
| Stilled hourglass | Session clock | Court word |
| Crown of the first court | Seal of the first Court | No crowns |
| Augury array, Augury rites | Vigil array, Vigil rites | Ties to the Voidsworn verb Hold a vigil |
| Admiral Provost Vex | Admiral Severin Vex | Every other Voidsworn admiral is rank, first name, surname |
| Outlander shield lattice | Alien shield lattice | Plainer |
| Voidsworn Nemesis "Shriver", "Cantor", "Arch-shriver" | Oath-reader, Pilgrim, Keeper of the Rite | Shriver means confessor (the story moved to oath-readers); a cantor is a singer |
| Kept "Litany" (section 8) | Litany out of names (Merciless Penance, Oath of speed, rival lines to "the Rite") | The story already replaced litanists with rite-keepers |
| Kept HNS Castellan and HNS Vindicator (asked) | HNS Constant, HNS Punctual | Vindicator is a Space Marine tank |

Added (not in stream B's draft): the title-screen tagline and faction blurbs ("gothic", "imperial"), Razorfiend, Bio-titan, Battle-barge, Inertialess drive, Quantum shield node and regenerator, Quantum ward, Farsight, Ironhand, the Mending Choir, Acid chorus, Chorus rank Matriarch, song words in Voidsworn ship names and Chorus pools, the captain-pool clashes (section 8), the Deathless run word (assize), the whole story layer (section 9), the Corsair crest, custodian, Justiciar, the portrait prompts (section 11), HNS Executor, Proton magazine, Interdictor, Grax Ironjaw, Old Mott Brannigan and the Ember Choir.

Stream B's section 9 edits (the new Nemesis tables) landed on main in c88567c, after its draft: Egyptian parts became barrow-king roots, the Voidsworn and Chorus lists were cleaned, and four adaptations were renamed. Section 7 here is written against that main (06b96d7) and changes only what still needs it.

## 14. Notes for whoever applies this

- **tokens.gd** (`godot/story/tokens.gd`, the FEMININE fallback list): remove Isolde, Mireille, Ilsa, Aelith, Tauret, Nefrah, Khepset; add Rosalind, Margery, Perpetua, Marit, Saephine, Belisant, Ivetta, Maud, Rohese, Ermengarde. Petra and Mara stay (still in the Hegemony pool).
- **Hard-coded Godot copies** of JS text (not generated): godot/rules/rules.gd:1225 ("on the auspex"), :2477 ("The phylactery hums."), :3222 (" reanimates "); godot/scenes/battle/battle.gd:433; godot/ui/campaign/campaign_ui.gd:247, :796, :891, :895; godot/main/title.gd:66. Each is in the tables above.
- **Story tests** (story_test.gd, career_shots.gd) carry sample names (Admiral Castellan Vex, Warlord Grax Ironjaw, Justiciar Halvane, Hollow Song, Cinder Psalm); update them with the text so the tests still match.
- **Internal docs** that mention old class names (tools/blender/a4/K1_DECISIONS.md band table: Battle-barge, Bio-titan, Tomb-ark; FINDINGS; reviews) are history and need no change.
- **After applying:** grep the game and story files for every Old string in sections 1 to 10 (count 0, except rows Ryan chose to keep and the kept list in section 12), and the em dash count stays 0.
