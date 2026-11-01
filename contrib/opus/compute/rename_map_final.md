# Rename map, final (lore round 8, approved Oct 27 2026, R59)

Written by L (lore rollout helper). Source of truth: `lore_bible_r8.md` and the canonical table in `contrib/opus/briefs/lore_rollout_2026-10-27.md`. This file supersedes `rename_map.md` (Oct 26): its inventory of where strings live was reused, its new names were not (Brand, Flux, Verdict arc, Chord lance, Deathless Court, writ/warrant/edict, the Court words and others are all retired).

**Read at:** main `10c9c65` (first written at `e243729`; Where cells re-grepped at `10c9c65`, and a cell starting "applied:" means the owner has already made that change) (every Where cell below was produced by grepping the exact Old string at that commit; `(not found)` would mean the row is stale). Generated files are not listed and follow by re-export: `godot/rules/data/tables.json`, `godot/campaign/data/campaign_tables.json`, the oracle copies under `godot/*/test/oracle/`, and `voidsworn-3d.html`.

## Rules for whoever applies a row

- **Ids never change.** Faction ids (`voidsworn`, `corsair`, `ithar`, `deathless`, `chorus`, `hegemony`), hull, weapon, admiral, patron, boon, event, trait, style and file ids, save keys (`boons`, `patrons`, `favour`, `giftBoon`, `boonOffer` ...), action names (`takeBoon` ...), telemetry names, CSS classes (`.gothic`, `.boon`, `.sigil`) and `user://voidsworn_*` save paths all stay. Only text a player can read changes.
- **Ship class (`cls`) is a key, not just a label.** `ships3d.js`, `godot/render/hull_table.gd`, the fx probes and `FLIP_CLASSES` look hulls up by `cls` (`Battle-barge`, `Bio-titan`, `Ark`, `Tomb-ark`). So `cls` values stay, and the new class names show through a display map (row 4.0). Vetoable call V3.
- **Who applies:** Owner column. B = stream B (data.js and the browser JS files), G1 = godot/rules (code and tests), G2 = godot/main, godot/scenes, brand.gd, project and export settings, G3 = godot/ui/campaign, godot/campaign (and godot/ui/career if ever needed), L = godot/story and tokens.gd, P = portraits (tools/portraits, godot/portraits). A Godot owner also mirrors any row whose text reaches Godot through the re-exported tables; those rows show only the JS file in Where.
- **Where a Godot file copies a JS line**, the same row lists both; apply the same New text in both so the two games say the same thing.
- **No em dashes**, plain words. Write the New text in the file's own escaping (data.js uses `’` for the apostrophe in many strings; keep whatever the line already uses).
- After applying, grep your files for every Old string you own: the count should be 0, except where the Note says "kept" or the Old is a substring that stays legal in another line.

Owner key: **B**, **G1**, **G2**, **G3**, **L**, **P** (see above).

## 1. Title, factions, blurbs, run words

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `<h1>Voidsworn</h1>` | `<h1>Embers of the Hollow Sun</h1>` | applied: campaign_meta.js:30; ui3d.js:624 | B | Title screen (browser). G2 landed the Godot title in 49f0d85. |
| `Command a crusade of gothic capital ships through three hostile sectors. Every hull you lose stays lost, and so does its captain.` | Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain. | godot/ui/campaign/campaign_ui.gd:303 | G3 | The tagline (vetoable V1). Any faction can be picked, so it no longer says crusade. |
| `<title>Voidsworn: 3D battle prototype</title>` | `<title>Embers of the Hollow Sun</title>` | applied: head.html:6 | B | Browser tab title. |
| `<span class="t">Voidsworn</span>` | `<span class="t">Embers of the Hollow Sun</span>` | applied: ui3d.js:62 | B | Battle top bar (browser). |
| `<div class="ibox"><h1>Voidsworn</h1>` | `<div class="ibox"><h1>Embers of the Hollow Sun</h1>` | applied: ui3d.js:624 | B | Skirmish setup header (browser). |
| `Voidsworn is a roguelite.` | Embers of the Hollow Sun is a roguelite. | godot/ui/campaign/campaign_ui.gd:1010 | G3 | How to play, first line. |
| `n:'Voidsworn Crusade'` | n:'Sunward Crusade' | applied: data.js:113 | B | Canonical. |
| `n:'Ashfall Corsairs'` | n:'Ashfall Hullbreakers' | applied: data.js:117 | B | Canonical. |
| `n:'The Ithar'` | n:'The Glasswrights' | applied: data.js:123 | B | Canonical. |
| `n:'The Deathless Dynasty'` | n:'Eclipse' | applied: data.js:126 | B | Canonical, no "the". Watch sentences that put "the" in front of `F.n` (none found in the JS; G1/G3 check theirs). |
| `blurb:'Gothic crusader battleships. Heavy armor, lance batteries and broadsides that hit like a cathedral falling.'` | blurb:'The frontier the Hegemony wrote off, come to stop the Siphoning. Black-iron battleships: heavy armor, lances, and broadsides that hit harder on the move.' | applied: data.js:113 | B | |
| `blurb:'An imperial war-machine of wedge-hulled destroyers. Ion cannons strip shields; carriers launch fighter screens.'` | blurb:'The Registry’s navy: linked crews, wedge hulls and drone escorts. Ion cannons strip shields; carriers launch fighter screens.' | applied: data.js:115 | B | |
| `blurb:'Pirate raiders in stolen hulls. Fast, thin shields, and far too many torpedoes.'` | blurb:'Furred pack hunters in ships that run dark, stripping every wreck. Fast, thin shields, and far too many rockets.' | applied: data.js:118 | B | |
| `blurb:'A hungering bio-swarm. No shields at all, but their flesh knits back together every round.'` | blurb:'A living weapon that ate its makers. No shields at all, but their flesh knits back together every round.' | applied: data.js:121 | B | |
| `blurb:'An ancient, dying elder race. Blindingly fast, heavily shielded, fragile once the shields fall.'` | blurb:'Few, long-lived masters of light and crystal. Blindingly fast, heavily shielded, fragile once the shields fall.' | applied: data.js:124 | B | |
| `blurb:'Machine necropolis-ships. Gauss weapons tear through shields, and wrecks sometimes stand back up.'` | blurb:'Starwright minds in machine bodies, stealing starlight to light a new sun. Null weapons cut through shields and armor, and wrecks rebuild themselves.' | applied: data.js:127 | B | |
| `deathless:'reclamation'` | deathless:'Homecoming' | applied: data.js:273 | B | RUN_WORD (canonical). Shows as "Launch the Homecoming". |
| `WIN_TITLE={voidsworn:'The crusade endures',hegemony:'The Hegemony stands',corsair:'The loot is yours',chorus:'The Chorus swells',ithar:'The Ithar endure',deathless:'The Dynasty rises'}` | WIN_TITLE={voidsworn:'The crusade endures',hegemony:'The Hegemony stands',corsair:'Strongest keeps it',chorus:'The Chorus swells',ithar:'The light is kept',deathless:'Noon returns'} | applied: campaign_meta.js:178 | B | Run-end headline per faction. |

## 2. Cores (was patrons), protocols (was boons), signals (was sigils), sync (was favour)

The words: patron becomes **core**, boon becomes **protocol**, sigil becomes **signal**, favour becomes **sync**. In prose: "a core offers three protocols", "battles carrying a core's signal", "your sync with that core". A core is "it", not "they" or "she".

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Kharon, the Iron Saint'` | n:'K-1 Kharon, the Unbent' | applied: data.js:622 | B | Canonical. |
| `n:'Vyre, the Storm Queen'` | n:'V-2 Vyre, the Storm Queen' | applied: data.js:623 | B | Canonical. |
| `n:'The Hunger Below'` | n:'H-3 Crucible, "the Hunger Below"' | applied: data.js:624 | B | Canonical. |
| `short:'The Hunger'` | short:'Crucible' | applied: data.js:624 | B | |
| `n:'Astra, the Silent Star'` | n:'A-4 Astra, the Silent Star' | applied: data.js:625 | B | Canonical. |
| `n:'Rook, the Breaker'` | n:'R-5 Rook, the Breaker' | applied: data.js:626 | B | Canonical. |
| `n:'The Ember Choir'` | n:'S-6 Seren, the Last Flame' | applied: data.js:627 | B | Canonical. |
| `short:'The Choir'` | short:'Seren' | applied: data.js:627 | B | |
| `glyph:'E'` | glyph:'S' | applied: data.js:627 | B | The S-6 badge letter (id `ember` stays). |
| `quote:'Sing, and let the void burn with you.'` | quote:'Burn, and let the dark burn with you.' | applied: data.js:627 | B | No faction sings. |
| `FAVOUR_TIERS=[{at:0,n:'Watching'},{at:4,n:'Favoured',d:'Their boons are rare more often.'},{at:12,n:'Devoted',d:'If they watch your run, you start with one of their boons.'},{at:25,n:'Chosen',d:'Their boons are never common.'}]` | FAVOUR_TIERS=[{at:0,n:'Listening'},{at:4,n:'Partial sync',d:'Its protocols are rare more often.'},{at:12,n:'Synced',d:'If it is in range of your run, you start with one of its protocols.'},{at:25,n:'Full sync',d:'Its protocols are never common.'}] | applied: data.js:590 | B | Sync tiers (vetoable V9). Constant name stays. |
| `n:"Saint's Plating"` | n:'Unbent Plating' | applied: data.js:633 | B | Protocol name. |
| `n:'Choir Warheads'` | n:'Incendiary Warheads' | applied: data.js:661 | B | |
| `n:'Hymn of Reloading'` | n:'Hot Tubes' | applied: data.js:662 | B | |
| `n:'Brood Tithe'` | n:'Brood Harvest' | applied: data.js:679 | B | Tithe is a church word. |
| `d_bastion:{duo:['iron','storm'],n:'Bastion'` | d_bastion:{duo:['iron','storm'],n:'Fortress' | applied: data.js:668 | B | Bastion is now the Crusade battleship class (one name, one owner). |
| `'Boon of '+PATRONS[rw.p].short` | 'Signal of '+PATRONS[rw.p].short | applied: campaign_run.js:18 | B | Map badge label. |
| `"Boon of " + str(C.PATRONS[rw["p"]]["short"])` | "Signal of " + str(C.PATRONS[rw["p"]]["short"]) | godot/ui/campaign/campaign_ui.gd:584 | G3 | Same, Godot. |
| `<h3>Boons</h3>` | `<h3>Protocols</h3>` | applied: campaign_run.js:66 | B | Map sidebar. |
| `None yet. Win at a node with a patron’s sigil to earn one.` | None yet. Win at a node carrying a core’s signal to earn one. | applied: campaign_run.js:66 | B | |
| `Patrons this run: ` | Cores in range: | applied: campaign_run.js:67 | B | |
| `boon:'A boon is a bonus from a patron that lasts for the rest of this run. Rarity sets how strong it is.'` | boon:'A protocol is a bonus from a core that lasts for the rest of this run. Rarity sets how strong it is.' | applied: campaign_run.js:391 | B | Reward definition line (key `boon` stays). |
| ` offers a boon</button>` | ` offers a protocol</button>` | applied: campaign_run.js:418 | B | Reward button. |
| `" offers a boon"` | " offers a protocol" | godot/ui/campaign/campaign_ui.gd:1167 | G3 | Godot. |
| `Boons in action: ` | Protocols in action: | applied: campaign_run.js:421 | B | |
| `No boon triggered this battle. Check the Fleet boons section on a ship to see what sets each one off.` | No protocol triggered this battle. Check the Fleet protocols section on a ship to see what sets each one off. | godot/ui/campaign/campaign_ui.gd:1161 | G3 | |
| `<h4>Fleet boons</h4>` | `<h4>Fleet protocols</h4>` | applied: ui3d.js:150 | B | Ship panel (browser). |
| `"Fleet boons"` | "Fleet protocols" | applied: godot/main/FEATURES.md:15; godot/scenes/battle/battle.gd:2956 | G2 | Ship panel (Godot battle). |
| ` Boons active: ` | ` Protocols active: ` | applied: campaign3d.js:58 | B | campaign3d tooltip. |
| `"Take boon"` | "Take protocol" | applied: godot/main/FEATURES.md:15; godot/main/campaign_fallback_ui.gd:12 | G2 | Fallback UI button. |
| `who counts you Devoted: <b>` | now Synced with you: <b> | applied: campaign_meta.js:105 | B | Reads "A gift from K-1 Kharon, the Unbent, now Synced with you: Thunder Broadside." |
| `", who counts you Devoted: [b]"` | ", now Synced with you: [b]" | godot/ui/campaign/campaign_ui.gd:437 | G3 | Godot copy. |
| `Patrons watching this ${runWord()}: ` | Cores in range of this ${runWord()}: | applied: campaign_meta.js:106 | B | Aspect screen. |
| `. Win battles marked with their sigil to earn their boons.` | . Win battles carrying their signal to earn their protocols. | godot/ui/campaign/campaign_ui.gd:444 | G3 | Aspect screen (both games). |
| `"Patrons watching this "` | "Cores in range of this " | godot/ui/campaign/campaign_ui.gd:444 | G3 | Godot. |
| `Long-range auspex confirms` | Long-range scans confirm | godot/ui/campaign/campaign_ui.gd:1116 | G3 | Sector I intro (both games). |
| `Battles marked with a patron’s sigil pay out that patron’s boons, so the route you choose shapes your build.` | Battles carrying a core’s signal pay out that core’s protocols, so the route you choose shapes your build. | godot/ui/campaign/campaign_ui.gd:1127 | G3 | Sector I intro (both games). |
| `['favour','Patron favour']` | ['favour','Core sync'] | applied: campaign_meta.js:120 | B | Progression tab label (id `favour` stays). |
| `"Patron favour"` | "Core sync" | godot/ui/campaign/campaign_ui.gd:939 | G3 | Godot tab label. |
| `Every boon you take raises that patron's favour (rare boons count double, epic triple).` | Every protocol you take raises your sync with that core (rare protocols count double, epic triple). | godot/ui/campaign/campaign_ui.gd:978 | G3 | Both games. |
| `<b>patrons</b> grow fond of you as you take their boons, offering rarer boons and eventually a gift at the start of a run` | <b>cores</b> sync with you as you take their protocols, offering rarer protocols and eventually a gift at the start of a run | applied: campaign_meta.js:151 | B | How to play (browser; Godot copy in 9.2). |
| `Patrons, boons and your flagship` | Cores, protocols and your flagship | godot/ui/campaign/campaign_ui.gd:1021 | G3 | How to play header (both). |
| `Each run, four of six patrons watch your run. Battles on the map carry a patron’s sigil: win there and that patron offers three boons, and you take one. Boons change the rules` | Each run, four of the six cores are in range. Battles on the map carry a core’s signal: win there and that core offers three protocols, and you take one. Protocols change the rules | godot/ui/campaign/campaign_ui.gd:1021 | G3 | How to play (browser). |
| `Each run, four of six patrons watch your run. Battles on the map carry a patron’s sigil: win there and that patron offers three boons, and you take one. Boons change the rules` | Each run, four of the six cores are in range. Battles on the map carry a core’s signal: win there and that core offers three protocols, and you take one. Protocols change the rules | godot/ui/campaign/campaign_ui.gd:1021 | G3 | How to play (Godot). |
| `Hold boons from two patrons and a duo boon can appear.` | Hold protocols from two cores and a duo protocol can appear. | godot/ui/campaign/campaign_ui.gd:1021 | G3 | Both. |
| `without boons.` | without protocols. | godot/ui/campaign/campaign_ui.gd:1020 | G3 | Ram rule in How to play (both). |
| `const TERMS := {"patron": "patron", "patrons": "patrons", "sigil": "sigil", "boon": "boon", "boons": "boons", "favour": "favour"}` | const TERMS := {"patron": "core", "patrons": "cores", "sigil": "signal", "boon": "protocol", "boons": "protocols", "favour": "sync"} | (the owner reworded this line since the map was written: recheck by hand) | see note | G3's one-edit switch for the map screen. Check each `term(...)` sentence still reads ("Cores watching" becomes "Cores in range": see 10.2). |
| `(repair stops count in its favour)` | (repair stops count toward it) | godot/ui/campaign/map3d.gd:812 | G3 | Ordinary word, but "favour" is retired from display text. |

## 3. Weapons

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Macro battery'` | n:'Gun battery' | applied: data.js:5 | B | Generic name (shown on variant cards and anywhere a faction has no override). Battlefleet Gothic word. |
| `n:'Heavy macro battery'` | n:'Heavy gun battery' | applied: data.js:6 | B | |
| `turbo:{n:'Turbolaser'` | turbo:{n:'Pulse laser' | applied: data.js:11 | B | Canonical. Hegemony still shows its own override, Plasma lance. |
| `hturbo:{n:'Heavy turbolaser'` | hturbo:{n:'Heavy pulse laser' | applied: data.js:12 | B | Canonical. |
| `bioplasma:{n:'Bio-plasma'` | bioplasma:{n:'Bile spray' | applied: data.js:17 | B | Generic; Chorus shows Spine volley. |
| `spores:{n:'Spore mines'` | spores:{n:'Spore drifts' | applied: data.js:18 | B | Bible Chorus weapon. |
| `pulsar:{n:'Pulsar lance'` | pulsar:{n:'Prism lance' | applied: data.js:19 | B | Canonical. |
| `gauss:{n:'Gauss flayer'` | gauss:{n:'Null cannon' | applied: data.js:21 | B | Canonical. |
| `gsentry:{n:'Gauss sentries'` | gsentry:{n:'Null sentries' | applied: data.js:22 | B | Canonical. |
| `doom:{n:'Doom arc'` | doom:{n:'Corona arc' | applied: data.js:23 | B | Canonical. |
| `shard:{n:'Shuriken cannon'` | shard:{n:'Shard cannon' | applied: data.js:24 | B | Bible Glasswright weapon. |
| `gauss:'Gauss',sq:'Squadron'` | gauss:'Null',sq:'Squadron' | applied: data.js:30 | B | KIND_NAME weapon kind label (canonical). |
| `autocannon:'Las-repeater',battery:'Las-battery',hbattery:'Heavy las-broadside',turret:'Las-turret',lance:'Penance lance',torp:'Hellfire torpedo',flak:'Censer flak'` | autocannon:'Sear repeater',battery:'Sear battery',hbattery:'Heavy sear broadside',turret:'Sear turret',lance:'Oath lance',torp:'Cinder torpedo',flak:'Spark flak' | applied: data.js:35 | B | Crusade names, all from the bible (2.11). |
| `pulsar:'Pulsar lance',startorp` | pulsar:'Prism lance',startorp | applied: data.js:39 | B | Glasswright override. |
| `deathless:{gauss:'Gauss flayer',doom:'Doom arc',gsentry:'Gauss pylon',flak:'Gauss shredder'}` | deathless:{gauss:'Null cannon',doom:'Corona arc',gsentry:'Null spire',flak:'Null shredder'} | applied: data.js:40 | B | Canonical. |
| `flay:{w:'flayed by gauss fire'` | flay:{w:'unmade by null fire' | applied: battle.js:925 | B | Kill cause (id `flay` stays). |
| `n:'Nova cannon'` | n:'Spinal cannon' | applied: data.js:138 | B | Ability shared by three flagships; Nova Cannon is Battlefleet Gothic's prow gun. Vetoable V12. |
| `<div class="h">Nova impact</div>` | `<div class="h">Spinal shell impact</div>` | applied: ui3d.js:449 | B | Targeting tooltip. |
| `Nova blast hits ` | Spinal shell hits | godot/rules/rules.gd:3530 | G1 | Battle log (both games). |

## 4. Hulls, classes, drives and abilities

**4.0 Class display map (new, B adds; G1 and G3 read it from the tables).** Add to data.js, next to HULLS: `const CLS_NAME={'Battle-barge':'War-barge','Bio-titan':'Colossus','Ark':'Lattice-ship','Tomb-ark':'Archive-ship'}; function clsName(c){ return CLS_NAME[c]||c; }` and use `clsName(...)` wherever a class is shown: ui3d.js:107 (`u.cls`), campaign_run.js:45, :189 (group label only, not the grouping key), :473; Godot hud.gd:384, :448, battle.gd ship panel lines that print `cls`, campaign_ui.gd:631, :1198, map3d.gd tooltips. The `cls` values themselves stay (they key ship models, sizes and fx).

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Penitent-class cruiser'` | n:'Vigil-class cruiser' | applied: data.js:65 | B | Canonical. |
| `n:'Reliquary-class carrier'` | n:'Hearth-class carrier' | applied: data.js:66 | B | Canonical. |
| `n:'Cathedral-class battleship'` | n:'Bastion-class battleship' | applied: data.js:67 | B | Canonical. |
| `n:'Ascendant-class dreadnought'` | n:'Daybreak-class dreadnought' | applied: data.js:68 | B | Canonical. |
| `n:'Interdictor destroyer'` | n:'Cordon destroyer' | applied: data.js:75 | B | Canonical. |
| `n:'Vanguard star cruiser'` | n:'Vanguard cruiser' | applied: data.js:76 | B | "Star cruiser" is a Star Wars class word. |
| `n:'Dominion star dreadnought'` | n:'Dominion dreadnought' | applied: data.js:77 | B | Same. |
| `n:'Corsair raider'` | n:'Hullbreaker raider' | applied: data.js:80 | B | Canonical. |
| `n:'Corsair reaver'` | n:'Hullbreaker gutship' | applied: data.js:81 | B | Canonical. |
| `n:'Corsair marauder'` | n:'Hullbreaker wrecker' | applied: data.js:82 | B | Canonical. |
| `n:'Corsair hulk-carrier'` | n:'Hullbreaker hulk-carrier' | applied: data.js:83 | B | Canonical. |
| `cls:'Battle-barge'` | (stays; shows as War-barge via 4.0) | data.js:84 | B | Name `Warlord's Pyre-Barge` kept (canonical). |
| `n:'Chorus razorfiend'` | n:'Chorus bladeback' | applied: data.js:88 | B | Canonical. |
| `n:'Chorus brood-mother'` | n:'Chorus brood-sac' | applied: data.js:89 | B | Canonical. |
| `n:'Hive Leviathan'` | n:'The Ninefold Maw' | applied: data.js:90 | B | Canonical; class shows as Colossus via 4.0. |
| `n:'Ithar wisp'` | n:'Glasswright sliver' | applied: data.js:92 | B | Canonical. |
| `n:'Ithar shadowblade'` | n:'Glasswright lancet' | applied: data.js:93 | B | Canonical. |
| `n:'Ithar songship'` | n:'Glasswright prism' | applied: data.js:94 | B | Canonical. |
| `n:'Ithar wraithcarrier'` | n:'Glasswright aperture' | applied: data.js:95 | B | Canonical. |
| `n:'Worldsong Ark'` | n:'The Unfinished' | applied: data.js:96 | B | Canonical; class shows as Lattice-ship via 4.0 (vetoable V3). |
| `n:'Deathless scythe'` | n:'Eclipse mote' | applied: data.js:98 | B | Canonical. |
| `n:'Deathless jackal'` | n:'Eclipse flare' | applied: data.js:99 | B | Canonical. |
| `n:'Deathless harvester'` | n:'Eclipse zenith' | applied: data.js:100 | B | Canonical. |
| `n:'The Undying Throne'` | n:'The Unsetting' | applied: data.js:101 | B | Canonical; class shows as Archive-ship via 4.0. |
| `n:'Fan sails'` | n:'Crystal vanes' | applied: data.js:110 | B | Glasswright drive rule (bible 6.3: vanes, not sails). |
| `n:'Phase drive'` | n:'Fold drive' | applied: data.js:111 | B | Eclipse drive rule (bible 7.3, 7.5). |
| `phase:{n:'Dimensional shift'` | phase:{n:'Fold skip' | applied: data.js:145 | B | Eclipse ability, matches the fold drive. |
| `reclaim:{n:'Reanimation beam'` | reclaim:{n:'Repair swarm' | applied: data.js:146 | B | Bible 7.5: repair swarms. |
| `' reanimates '` | ' rebuilds ' | applied: battle.js:1189 | B | Battle log for the repair swarm (both games). |
| `" reanimates "` | " rebuilds " | godot/rules/rules.gd:3477 | G1 | Godot copy. |
| `'Reanimating'` | 'Rebuilding' | applied: battle.js:938 | B | Floating text. |
| `"Reanimating"` | "Rebuilding" | godot/rules/rules.gd:2736 | G1 | Godot copy. |
| `'Reawakens'` | 'Restarts' | applied: battle.js:936 | B | Floating text for the revive relic. |
| `"Reawakens"` | "Restarts" | godot/rules/rules.gd:2733 | G1 | Godot copy. |
| `The phylactery hums. ${t.name} reawakens at 25% hull.` | Second ignition. ${t.name} restarts at 25% hull. | applied: battle.js:936 | B | Revive relic log. |
| `logm("The phylactery hums. " + String(t["name"]) + " reawakens at 25% hull.", "s")` | logm("Second ignition. " + String(t["name"]) + " restarts at 25% hull.", "s") | godot/rules/rules.gd:2733 | G1 | Godot copy. |
| `deathless:{n:'Endless legion',d:` | deathless:{n:'Archive restore',d: | applied: battle.js:480 | B | Eclipse faction rule name (battle.js FACTION_RULES). |
| `The first Deathless ship to fall each battle` | The first Eclipse ship to fall each battle | applied: battle.js:480 | B | Same rule text. |
| `'Endless legion: the first to fall reassembles next round.':'Endless legion spent.'` | 'Archive restore: the first to fall reassembles next round.':'Archive restore spent.' | applied: battle.js:526 | B | Ship panel. |
| `"Endless legion: the first to fall reassembles next round."` | "Archive restore: the first to fall reassembles next round." | applied: godot/scenes/battle/battle.gd:2884 | G2 | Godot ship panel; also its "Endless legion spent." on the same line becomes "Archive restore spent." |
| `Ithar hulls cannot Brace.` | Glasswright hulls cannot Brace. | applied: battle.js:478 | B | Glasswright rule text. |
| `corsair:{n:'Close in',d:'Corsairs field no lance weapons` | corsair:{n:'Close in',d:'Hullbreakers field no lance weapons | applied: battle.js:481 | B | |
| `d:'Corsairs field no lance weapons (no long-range beams): they win up close.'` | d:'Hullbreakers field no lance weapons (no long-range beams): they win up close.' | applied: data.js:541 | B | FAC_GATES. |
| `d:'Ithar hulls cannot Brace for impact: they live by shields and speed.'` | d:'Glasswright hulls cannot Brace for impact: they live by shields and speed.' | applied: data.js:541 | B | FAC_GATES. |
| `hegemony:{id:'barrage',n:'Imperial broadside'}` | hegemony:{id:'barrage',n:'Registry broadside'} | applied: battle.js:1109 | B | Enemy flagship Command. |
| `chorus:{id:'restore',n:'Hive regrowth'}` | chorus:{id:'restore',n:'Brood regrowth'} | applied: battle.js:1109 | B | Hive is a Tyranid word. |
| `deathless:{id:'restore',n:'Rise again'}` | deathless:{id:'restore',n:'Restore from the Archive'} | applied: battle.js:1109 | B | |
| `deadstar:'Dead star'` | deadstar:'Hollow Sun' | applied: battle.js:18 | B | Battle shape label (canonical: the black hole is the Hollow Sun; vetoable V13). |
| `['deadstar','Dead star']` | ['deadstar','Hollow Sun'] | applied: ui3d.js:15 | B | Skirmish shape picker. |
| ` is torn apart by the dead star's gravity.` | ` is torn apart by the Hollow Sun's gravity.` | godot/rules/rules.gd:969 | G1 | Battle log (both games). |
| `tidal:{w:'torn apart by the dead star'` | tidal:{w:'torn apart by the Hollow Sun' | applied: battle.js:925 | B | Kill cause. |
| `A dead star warps this field.` | The Hollow Sun warps this field. | godot/rules/rules.gd:1257 | G1 | Battle start log (both games, three places). |
| `colossus:'Colossus'` | colossus:'Giant wreck' | applied: battle.js:18 | B | Battle shape label; Colossus is now the Ninefold Maw's class (one name, one owner). |
| `shoals:'Shoals'` | shoals:'Rock shoals' | applied: battle.js:18 | B | Optional, sea word softened (vetoable V13). |
| ` on the auspex.` | ` on the scanners.` | godot/rules/rules.gd:1256 | G1 | Battle start log (both games). |
| `will drop out of warp at the start of round {r}` | will jump in at the start of round {r} | applied: battle.js:23 | B | Battle event warning. |
| `go:'Enemy reinforcements drop out of warp.'` | go:'Enemy reinforcements jump in.' | applied: battle.js:23 | B | |
| `A friendly ship drops out of warp to help.` | A friendly ship jumps in to help. | applied: battle.js:24 | B | |

## 5. Refits (modules), relics, perks

Generic MODULES and RELICS show for the Sunward Crusade (it has no MOD_NAMES or RELIC_NAMES row) and for any faction gap, so they are written in the Crusade's voice where a word is needed.

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `auspex:{n:'Auspex array'` | auspex:{n:'Scanner array' | applied: data.js:155 | B | Bible 1.2: scanners. (Not "Vigil": that is now a hull class.) |
| `capacitor:{n:'Void shield capacitor'` | capacitor:{n:'Screen capacitor' | applied: data.js:158 | B | Bible 1.2: the Crusade calls shields screens. |
| `loaders:{n:'Macro loaders'` | loaders:{n:'Battery loaders' | applied: data.js:160 | B | |
| `cogitator:{n:'Targeting cogitator'` | cogitator:{n:'Targeting reckoner' | applied: data.js:166 | B | Bible 1.2: reckoner. |
| `deflector:{n:'Deflector savant'` | deflector:{n:'Shield savant' | applied: data.js:172 | B | Deflector is the Hegemony's word; perks are for everyone. |
| `lanceadept:{n:'Lance adept'` | lanceadept:{n:'Lance savant' | applied: data.js:177 | B | Adept is the Adeptus word. |
| `martyr:{n:'Reliquary of the Martyr'` | martyr:{n:'The Chalked Roll' | applied: data.js:189 | B | Crusade relic (names chalked on the hull). |
| `cogitator:{n:'Archeotech rangefinder'` | cogitator:{n:'Founders’ rangefinder' | applied: data.js:190 | B | Bible 1.2: founders' tech. |
| `lattice:{n:'Xeno shield lattice'` | lattice:{n:'Alien shield matrix' | applied: data.js:191 | B | "Lattice" is now the Starwright megastructure only. |
| `phylactery:{n:'Deathless phylactery'` | phylactery:{n:'Eclipse backup frame' | applied: data.js:193 | B | Generic name; Eclipse's own is Second Ignition. |
| `compass:{n:'Wraithbone compass'` | compass:{n:'Founders’ compass' | applied: data.js:195 | B | |
| `coils:{n:'Blessed plasma coils'` | coils:{n:'Hand-wound plasma coils' | applied: data.js:198 | B | No blessings; the Crusade does it by hand. |
| `loaders:'Turbolaser cyclers'` | loaders:'Pulse cyclers' | applied: data.js:261 | B | Hegemony refit. |
| `magazine:'Proton magazine'` | magazine:'Fusion magazine' | applied: data.js:261 | B | Star Wars proton torpedoes. |
| `magazine:'Extra torpedo racks'` | magazine:'Extra rocket racks' | applied: data.js:262 | B | Hullbreakers fire rockets. |
| `auspex:'Hunting eyes'` | auspex:'Tasting pores' | applied: data.js:263 | B | The Chorus has no eyes (bible 5.3). Also in NEM_ADAPT_FAC (6.x). |
| `prow:'Wraithbone keel',auspex:'Farsight crystal',drive:'Solar sail extension'` | prow:'Waveguide spine',auspex:'Interferometer lens',drive:'Solar vane extension' | applied: data.js:264 | B | Bible 6.10 refits. |
| `regen:'Dawnlight lattice',loaders:'Shuriken feeders'` | regen:'Stored-light reservoir',loaders:'Shard hoppers' | applied: data.js:264 | B | Dawn is the Crusade's motif; Lattice is taken. |
| `damcon:'Song of mending'` | damcon:'Annealing kilns' | applied: data.js:264 | B | No faction sings. |
| `cogitator:'Seer’s sight'` | cogitator:'Clear eye' | applied: data.js:264 | B | Bible 6.10. |
| `deathless:{prow:'Living-metal plating',auspex:'Tomb sight',drive:'Inertialess drive',gyro:'Gravitic vanes',capacitor:'Quantum shield node',regen:'Quantum regenerator',loaders:'Gauss accelerators',crystal:'Doom-arc focus',magazine:'Arc capacitors',flakplus:'Sentry nodes',damcon:'Repair scarabs',hangar:'Scarab hive',cogitator:'Calculus lattice'}` | deathless:{prow:'Sunshade plating',auspex:'Long-memory sight',drive:'Fold engine',gyro:'Gravitic stabilisers',capacitor:'Corona-ward node',regen:'Corona-ward regenerator',loaders:'Null accelerators',crystal:'Corona-arc focus',magazine:'Arc capacitors',flakplus:'Sentry nodes',damcon:'Repair drones',hangar:'Drone bay',cogitator:'Long-count reckoner'} | applied: data.js:265 | B | Eclipse refits, bible 7.10 where it names one. |
| `cogitator:'Imperial targeting array'` | cogitator:'Registry targeting array' | applied: data.js:267 | B | |
| `compass:'Hyperdrive motivator'` | compass:'Jump-drive regulator' | applied: data.js:267 | B | Star Wars line. |
| `armourweave:'Durasteel weave'` | armourweave:'Hardsteel weave' | applied: data.js:267 | B | Star Wars material. |
| `martyr:'Captain’s lucky skull'` | martyr:'Dead captain’s harness' | applied: data.js:268 | B | Hullbreaker trophies are machines and plates, never skulls (bible 4.3). |
| `lattice:'Ithar shield shard'` | lattice:'Glasswright shield shard' | applied: data.js:268 | B | |
| `compass:'Wraithbone compass',banner:'Trophy war banner'` | compass:'Wake-tracker',banner:'Trophy war banner' | applied: data.js:268 | B | Bible 4.1: wake-trackers. |
| `logbook:'Pirate king’s logbook'` | logbook:'Warlord’s kill tally' | applied: data.js:268 | B | |
| `cogitator:'Compound eye cluster',lattice:'Stolen shield lattice'` | cogitator:'Heat-tasting pits',lattice:'Swallowed shield cells' | applied: data.js:269 | B | No eyes; Lattice taken. |
| `logbook:'Memory of the hive'` | logbook:'Taste of old prey' | applied: data.js:269 | B | Hive; Memory belongs to story and dialogue only (bible 1.3). |
| `cogitator:'Seer’s eye',lattice:'Prism lattice'` | cogitator:'Ancestral lens',lattice:'Prism matrix' | applied: data.js:270 | B | |
| `banner:'Banner of the lost world'` | banner:'Banner of Ardent' | applied: data.js:270 | B | |
| `martyr:'Crown of the first dynasty'` | martyr:'Last image of Ardent' | applied: data.js:271 | B | Bible 7.8 ritual. |
| `phylactery:'Phylactery of the Undying'` | phylactery:'Second Ignition' | applied: data.js:271 | B | Bible 7.10. |
| `ledger:'Tithe ledger'` | ledger:'Siphon ledger' | applied: data.js:271 | B | |
| `salvage:'Harvest engine',coils:'Chronometron',logbook:'Annals of the dynasty',armourweave:'Living-metal weave'` | salvage:'Salvage swarm',coils:'Long clock',logbook:'The Archive',armourweave:'Sunshade weave' | applied: data.js:271 | B | |
| `salvagers:{n:'Salvage protocols'` | salvagers:{n:'Recovery crews' | applied: data.js:251 | B | "Protocol" now belongs to the cores. |
| `d:'Voidsworn fleets may take one Ascendant-class dreadnought.'` | d:'Sunward Crusade fleets may take one Daybreak-class dreadnought.' | applied: data.js:242 | B | Legacy unlock. |
| `n:'Aspect of the Hive'` | n:'Aspect of the Brood' | applied: data.js:693 | B | Hive. |

## 5b. Relic becomes salvage (the item type; Opus veto of V14)

Phrase by phrase. "Salvage" is uncountable: say "salvage" or "a piece of salvage". Ids never change.

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Relic of the founders',d:'Begin each run with a random relic.'` | n:'Founders’ salvage',d:'Begin each run with a random piece of salvage.' | applied: data.js:249 | B | Legacy unlock. |
| `s:'Gain a relic. A random ship takes heavy damage.'` | s:'Gain salvage. A random ship takes heavy damage.' | applied: data.js:285 | B | |
| `l:'Trade a module for a relic',s:'Lose a random installed module. Gain a relic.'` | l:'Trade a module for salvage',s:'Lose a random installed module. Gain salvage.' | applied: data.js:294 | B | |
| `s:'Fight an elite Chorus battle. Win a relic.'` | s:'Fight an elite Chorus battle. Win salvage.' | applied: data.js:300 | B | |
| `s:'Gain a relic. A refit from the hold burns out instead of a hull.'` | s:'Gain salvage. A refit from the hold burns out instead of a hull.' | applied: data.js:326 | B | |
| `l:'Leave one of your relics as an offering'` | l:'Leave a piece of salvage as an offering' | applied: data.js:330 | B | |
| `s:'Gain a relic, and the charts show you` | s:'Gain salvage, and the charts show you | applied: data.js:366 | B | |
| `s:'Lose a relic. Reveal a Nemesis weakness and gain 120 credits.'` | s:'Lose a piece of salvage. Reveal a Nemesis weakness and gain 120 credits.' | applied: data.js:367 | B | |
| `t:'A relic auction',b:'A neutral station is auctioning relics recovered from a dead crusade.` | t:'A salvage auction',b:'A neutral station is auctioning salvage recovered from a dead crusade. | applied: data.js:402 | B | |
| `s:'Gain a relic.'` | s:'Gain salvage.' | applied: data.js:403 | B | Auction bid. |
| `l:'Trade one of your relics for one of theirs',s:'Lose a relic, gain a different one and 40 credits.'` | l:'Trade a piece of your salvage for one of theirs',s:'Lose a piece of salvage, gain a different piece and 40 credits.' | applied: data.js:404 | B | |
| `d:'Tougher enemies with veteran captains. Drops a relic.'` | d:'Tougher enemies with veteran captains. Drops salvage.' | applied: campaign_run.js:2 | B | Map node info. |
| `"veteran fleet, drops a relic"` | "veteran fleet, drops salvage" | (the owner reworded this line since the map was written: recheck by hand) | see note | Godot map. |
| `<h3>Relics</h3>` | `<h3>Salvage</h3>` | applied: campaign_run.js:68 | B | Map sidebar. |
| `"Relics"` | "Salvage" | applied: godot/main/campaign_fallback_ui.gd:12 | G2 | Godot map sidebar heading. |
| `nd.relic===1?'a relic':` | nd.relic===1?'a piece of salvage': | applied: campaign_run.js:226 | B | Blue option requirement. |
| `"a relic"` | "a piece of salvage" | godot/campaign/campaign.gd:1504 | G3 | Godot copy. |
| `Relic gained: ` | Salvage gained: | godot/campaign/campaign.gd:1924 | G3 | Event result (both games). |
| `No relics left to find. +80 credits instead.` | No salvage left to find. +80 credits instead. | godot/campaign/campaign.gd:1926 | G3 | Both games. |
| `relic:'A relic is a fleet-wide effect that lasts for the rest of this run.'` | relic:'Salvage is a fleet-wide effect that lasts for the rest of this run.' | applied: campaign_run.js:393 | B | Reward definition (key `relic` stays). |
| `Relics are fleet-wide bonuses that last for the run.` | Salvage gives fleet-wide bonuses that last for the run. | godot/ui/campaign/campaign_ui.gd:1022 | G3 | How to play (both). |
| `"Take relic"` | "Take salvage" | applied: godot/main/FEATURES.md:15; godot/main/campaign_fallback_ui.gd:12 | G2 | Fallback UI. |
| `the most rewards (relic 4, ` | the most rewards (salvage 4, | (the owner reworded this line since the map was written: recheck by hand) | see note | Route tooltip. |
| `%d refit%s, %d relic%s, %d credit reward%s` | %d refit%s, %d salvage, %d credit reward%s | (the owner reworded this line since the map was written: recheck by hand) | see note | Route tooltip; drop the matching plural argument. |

### 5c. Keep salvage to one meaning (Opus ruling, Oct 27)

The wreck step after a battle becomes "Strip", and the Salvage rig item becomes Scrap rig, so "salvage" only ever means the item type.

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `salvage:'Salvage: work one wreck from this fight.` | salvage:'Strip: work one wreck from this fight. | applied: campaign_run.js:390 | B | REWARD_DEF (key `salvage` stays). The rest of the line follows row 7 ("(Hullbreakers) tow a small hull home"). |
| `data-act="salvageStep">Salvage the field</button>` | data-act="salvageStep">Strip the wrecks</button> | applied: campaign_run.js:418 | B | Action name stays. |
| `<h2>Salvage the field</h2>` | `<h2>Strip the wrecks</h2>` | applied: campaign_run.js:472 | B | |
| `"Salvage the field"` | "Strip the wrecks" | godot/ui/campaign/campaign_ui.gd:1166,1199 | G3 | Godot (button and header). |
| `<h2>Salvaged refits</h2>` | `<h2>Recovered refits</h2>` | applied: campaign_run.js:484 | B | Refit offer header. |
| `"Salvaged refits"` | "Recovered refits" | godot/ui/campaign/campaign_ui.gd:1211 | G3 | Godot. |
| `salvage:{n:'Salvage rig'` | salvage:{n:'Scrap rig' | applied: data.js:197 | B | Item (id `salvage` stays). |
| `salvage:'Salvage rig'` | salvage:'Scrap rig' | applied: data.js:267,268 | B | Hegemony and Hullbreaker RELIC_NAMES. |
| `<p class="gilt">Salvage: +${v} credits.</p>` | `<p class="gilt">Spoils: +${v} credits.</p>` | applied: campaign_run.js:407 | B | Credit reward line; L's suggestion on the same principle (vetoable). |
| `"Salvage: +"` | "Spoils: +" | godot/campaign/campaign.gd:2075 | G3 | Godot copy. |

## 6. Admirals and Commands

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Admiral Castellan Vex'` | n:'Admiral Roderic Vex' | applied: data.js:205 | B | Castellan is a 40k rank; every Crusade admiral is rank, given name, surname (vetoable V4). |
| `n:'Inquisitor-Captain Malek Draven'` | n:'Oath-Captain Malek Draven' | applied: data.js:206 | B | Canonical. |
| `n:'Grand Admiral Ilsa Kassar'` | n:'First Admiral Ilsa Kassar' | applied: data.js:217 | B | Canonical rank. |
| `star cruisers hold +1 wing` | cruisers hold +1 wing | applied: data.js:219 | B | Reyes's doctrine text. |
| `n:'Shield wall protocol'` | n:'Shield wall order' | applied: data.js:220 | B | Maren's Command; "protocol" belongs to the cores. |
| `n:'Warlord Grax Ironjaw'` | n:'Warlord Grax Steelgrin' | applied: data.js:221 | B | Bible 4.9 example; Ironjawz is Age of Sigmar. |
| `n:'Sable Venn, the Smiling Knife'` | n:'Sable the Smiling Knife' | applied: data.js:222 | B | No human surnames; a sable is a furred hunter, so the name stays (vetoable V5). |
| `n:'Old Mott Brannigan'` | n:'Old Mott' | applied: data.js:223 | B | No surname (Brannigan is Futurama). |
| `n:'Patch and pray'` | n:'Patch and weld' | applied: data.js:224 | B | Vesh's Command; no prayer. |
| `n:'The Mending Choir'` | n:'The Mending Throng' | applied: data.js:227 | B | Bible 5.3. |
| `doc:'Acid chorus'` | doc:'Acid tide' | applied: data.js:228 | B | Read as music. |
| `n:'Discordant volley'` | n:'Spitting volley' | applied: data.js:228 | B | Music word. |
| `n:'Aelith Dawnsail'` | n:'Tamsa of the Clear Aperture' | applied: data.js:229 | B | Glasswright name plus optical family line (bible 6.9); carrier admiral, aperture is the carrier class (vetoable V6). |
| `n:'Seraph Vaelen',doc:'Lance choir'` | n:'Saro of Long Focus',doc:'Focused lances' | applied: data.js:230 | B | Lance admiral. |
| `n:'Chord of light'` | n:'Burning glass' | applied: data.js:230 | B | Saro's Command. |
| `n:'Thorne of the Veil',doc:'Veil tactics'` | n:'Vell of the Third Mirror',doc:'Refraction tactics' | applied: data.js:231 | B | Evasion admiral. |
| `n:'Phase drift',d:'Every ship gains` | n:'Scatter the light',d:'Every ship gains | applied: data.js:231 | B | Vell's Command (Phase drift was also an Eclipse adaptation name). |
| `n:'Mirelle Starwarden'` | n:'Brin of the Fourth Lens' | applied: data.js:232 | B | Shield admiral. |
| `n:'Overlord Nekhet the Undying',doc:'Eternal legion'` | n:'Nadir Aurex, Ninth Frame',doc:'Endless restoration' | applied: data.js:233 | B | Canonical name. Nekhet is the regrowth admiral whose portrait is the broken ring mind, which the bible gives to Aurex (vetoable V7). |
| `n:'Reanimation protocol'` | n:'Release the repair swarms' | applied: data.js:233 | B | Aurex's Command. |
| `n:'Sekhmar the Reaper',doc:'Reaping arcs',d:'Doom arcs deal +20% damage` | n:'Umbra Vessane, Third-Housed',doc:'Corona strikes',d:'Corona arcs deal +20% damage | applied: data.js:234 | B | Canonical name; the offence admiral. |
| `n:'Harvest of souls'` | n:'Noon volley' | applied: data.js:234 | B | Vessane's Command ("We remember noon"). |
| `n:'Cryptlord Anuket',doc:'Silent hunters'` | n:'Ostrel of the Long Copy',doc:'Silent hunters' | applied: data.js:235 | B | Canonical name; the patient flanker. |
| `n:'Tomb-blade strike'` | n:'Out of the shadow' | applied: data.js:235 | B | Ostrel's Command. |
| `n:'Khepra the Patient',doc:'Living stone'` | n:'Seveth, Twice-Restored',doc:'Layered plates' | applied: data.js:236 | B | Canonical name; the durable admiral (twice restored). |
| `cmd:{id:'iron',n:'Living stone'` | cmd:{id:'iron',n:'Sunshade wall' | applied: data.js:236 | B | Seveth's Command. |

## 7. Events, faction verbs, event results

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `b:'Your auspex finds an ancient gothic warship drifting without power, its hull etched with prayers no one has spoken in ten thousand years.'` | b:'Your scanners find an ancient warship drifting without power, its hull etched with Starwright script no one has read in a thousand years.' | applied: data.js:276 | B | |
| `s:'Risky. Could hold archeotech, could hold something awake.'` | s:'Risky. Could hold founders’ tech, could hold something awake.' | applied: data.js:277 | B | |
| `l:'Leave it to its prayers'` | l:'Leave it to the dark' | applied: data.js:279 | B | |
| `s:'A clean cut: archeotech and salvage, nothing wakes.'` | s:'A clean cut: founders’ tech and salvage, nothing wakes.' | applied: data.js:322 | B | |
| `owes you a favour` | owes you one | applied: data.js:324 | B | "Their captain pays well and owes you one: ..." |
| `t:'The astropath’s vision',b:'Your fleet astropath wakes screaming. She has seen where a relic lies, but reaching it means sailing through a warp-rift.'` | t:'A signal in the static',b:'Your signals officer has pulled an old founders’ beacon out of the static. Old salvage lies beyond it, but reaching it means crossing a rift.' | applied: data.js:284 | B | Event id `astropath` stays. No psychics (bible 1.2). |
| `b:'Your sensor officer has decoded a ghost signal: an old Navy relic cache, deep inside a hyperspace rift.'` | b:'Your sensor officer has decoded a ghost signal: an old Navy salvage cache, deep inside a rift.' | applied: data.js:284 | B | Hegemony variant. |
| `corsair:{t:'The navigator’s hunch',b:'Your half-mad navigator swears she can smell treasure on the far side of a rift. She is usually right. Usually.'}` | corsair:{t:'The tracker’s nose',b:'Your best tracker swears she can smell old metal on the far side of a rift. She is usually right. Usually.'} | applied: data.js:284 | B | Hullbreakers hunt by scent and sound. |
| `chorus:{t:'A scent in the void',b:'The brood-mind tastes something ancient and delicious beyond a rift in space.'}` | chorus:{t:'A scent in the dark',b:'The swarm tastes something old and delicious beyond a rift.'} | applied: data.js:284 | B | |
| `ithar:{t:'A seer’s dream',b:'Your seer dreams of a lost treasure of your people, sleeping beyond a rift.'}` | ithar:{t:'A glint beyond the rift',b:'Your mirrors catch a glint of old Starwright glass beyond a rift: a lost treasure of your people.'} | applied: data.js:284 | B | |
| `deathless:{t:'A dynastic beacon',b:'An old dynastic beacon pulses from beyond a rift. Something of the dynasty is still out there.'}` | deathless:{t:'An Archive beacon',b:'An Archive beacon from before the collapse pulses beyond a rift. Something of Ardent is still out there.'} | applied: data.js:284 | B | |
| `t:'Warp storm'` | t:'Rift storm' | applied: data.js:290 | B | |
| `t:'An Ithar seer',b:'A lone Ithar vessel matches your course. Its seer offers a trade: one of your refits for one of their treasures.'` | t:'A Glasswright wanderer',b:'A lone Glasswright vessel matches your course. Its keeper offers a trade: one of your refits for one of their treasures.' | applied: data.js:293 | B | Event id `seer` stays. |
| `l:'Sing back to her',s:'She trades a relic for a song. No refit lost.'` | l:'Answer her tone in glass',s:'She trades salvage for the courtesy. No refit lost.' | applied: data.js:327 | B | Option key `song` stays (Glasswright-only blue option). |
| `The seer smiles and gives anyway.` | The keeper smiles and gives anyway. | godot/campaign/campaign.gd:1920 | G3 | Event result (both games). |
| `t:'A void-shrine',b:'An orbital shrine to a forgotten saint hangs over a dead world. Your crews ask to make an offering.'` | t:'A wall of names',b:'A memorial station hangs over a dead world, its walls chalked with the names of a crusade that never came home. Your crews ask to leave an offering.' | applied: data.js:302 | B | Faction-power string (vetoable V10). Event id `shrine` stays. |
| `hegemony:{b:'An old orbital shrine hangs over a dead world. Spacers are a superstitious lot, and your crews ask to leave an offering.'}` | hegemony:{b:'An old memorial station hangs over a dead world. Spacers are a superstitious lot, and your crews ask to leave an offering.'} | applied: data.js:302 | B | |
| `corsair:{b:'An orbital shrine to some forgotten saint hangs over a dead world. Even pirates hedge their bets: your crews ask to leave an offering.'}` | corsair:{b:'An old memorial station hangs over a dead world, heaped with other packs’ trophies. Your crews want to leave one of their own.'} | applied: data.js:302 | B | |
| `ithar:{t:'A shrine of the old world',b:'A shrine from before your people’s fall hangs over a dead world. Your crews ask to leave an offering.'}` | ithar:{t:'A mirror of the old world',b:'A mirror array from before your people’s fall still turns over a dead world. Your crews ask to leave an offering.'} | applied: data.js:302 | B | |
| `l:'Pray and hope'` | l:'Chalk your names and hope' | applied: data.js:304 | B | |
| `The saint answers. Every ship repairs 30% of its hull.` | Luck holds. Every ship repairs 30% of its hull. | godot/campaign/campaign.gd:1952 | G3 | Event result (both games). |
| `b:'A lifeboat of Hegemony officers begs for asylum.` | b:'An escape pod of Hegemony officers begs for asylum. | applied: data.js:306 | B | Lifeboat is a sea word. |
| `b:'A corsair cache hidden in the rings of a gas giant.` | b:'A Hullbreaker cache hidden in the rings of a gas giant. | applied: data.js:309 | B | |
| `t:'The tithe vault',b:'An abandoned tithe station` | t:'The toll vault',b:'An abandoned toll station | applied: data.js:335 | B | Tithe is a church word. Event id `tithe` stays. |
| `l:'Let the living metal knit it'` | l:'Let the repair drones knit it' | applied: data.js:346 | B | |
| `t:'A song in the dark',b:'A dying Ithar songship is singing its own lament. The melody carries old star charts in it, for those who can hear.'` | t:'A tone in the dark',b:'A dying Glasswright prism rings with one long clear tone as its light fades. The tone carries old star charts in it, for those who can read it.' | applied: data.js:364 | B | |
| `l:'Join the song'` | l:'Answer the tone' | applied: data.js:366 | B | Faction-power string. |
| `l:'Trade a relic for its archive'` | l:'Trade salvage for its charts' | applied: data.js:367 | B | The archive is Eclipse's word. |
| `t:'A sealed tomb-world',b:'A planet of black glass hums under your keels. Deep below, something counts the seconds until it wakes.'` | t:'A siphon array',b:'A ring of black collectors circles a dimming star, drinking its energy. Something aboard counts the seconds until you come in range.' | applied: data.js:368 | B | Event id `tomb` stays. |
| `l:'Wake it and take what it guards',s:'Fight an elite Deathless battle. Win a relic.'` | l:'Break the array and take what it guards',s:'Fight an elite Eclipse battle. Win salvage.' | applied: data.js:369 | B | |
| `l:'Map it from orbit and leave'` | l:'Chart it and leave' | applied: data.js:370 | B | |
| `t:'A sleeping tomb-world',b:'A tomb-world of your own dynasty, its legions dormant. A word from you would wake one of them.'` | t:'A dormant hull yard',b:'An Eclipse yard from before the collapse drifts in the dark, its hulls stored without minds. A copy from the Archive would wake one of them.' | applied: data.js:371 | B | Event id `tombhome` stays. |
| `l:'Wake one scythe',s:'A Deathless scythe joins the fleet at full hull.'` | l:'Wake one mote',s:'An Eclipse mote joins the fleet at full hull.' | applied: data.js:372 | B | |
| `l:'Take its tithe instead'` | l:'Strip it for parts instead' | applied: data.js:373 | B | |
| `t:'A pirate haven'` | t:'A raider den' | applied: data.js:414 | B | |
| `s:'Fight an elite Corsair battle. Win a relic.'` | s:'Fight an elite Hullbreaker battle. Win salvage.' | applied: data.js:415 | B | |
| `s:'A Corsair raider joins with a veteran captain.'` | s:'A Hullbreaker raider joins with a veteran captain.' | applied: data.js:417 | B | |
| `voidsworn:{id:'vigil',n:'Hold a vigil',` | voidsworn:{id:'vigil',n:'Keep the dawn watch', | applied: data.js:499 | B | Crusade verb (bible 2.9 ritual); Vigil is now a hull class. Id `vigil` stays. |
| `freeD:'free after an offering at a void-shrine'` | freeD:'free after an offering at a wall of names' | applied: data.js:499 | B | Faction-power string. |
| `freeD:'free once you have joined the song'` | freeD:'free once you have answered the tone' | applied: data.js:503 | B | Faction-power string. |
| `deathless:{id:'waken',n:'Waken the legion',d:'Next battle, the endless legion has one more return.'` | deathless:{id:'waken',n:'Back up the fleet',d:'Next battle, Archive restore brings back one more ship.' | applied: data.js:504 | B | Faction-power string. Id `waken` stays. |
| `freeD:'free once a tomb-world has woken for you'` | freeD:'free once a dormant yard has woken a hull for you' | applied: data.js:504 | B | Faction-power string. |
| `(Corsairs) tow a small hull home` | (Hullbreakers) tow a small hull home | applied: campaign_run.js:390 | B | Salvage reward line. |
| `Auspex confirms ` | Scanners confirm | godot/ui/campaign/campaign_ui.gd:1120 | G3 | Sector II and III intro (both games). |
| `"Auspex confirms [b]"` | "Scanners confirm [b]" | godot/ui/campaign/campaign_ui.gd:1120 | G3 | Godot copy. |

## 8. Hull variants and fleet archetypes

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Penitent gun-cruiser',d:'Swaps the prow lance for a dorsal macro battery: guns in every arc.'` | n:'Vigil gun-cruiser',d:'Swaps the prow lance for a dorsal sear battery: guns in every arc.' | applied: data.js:552 | B | |
| `d:'No hangar; a third turbolaser turret instead.'` | d:'No hangar; a third plasma lance turret instead.' | applied: data.js:554 | B | The Hegemony shows `turbo` as Plasma lance. |
| `n:'Reaver gunboat'` | n:'Turret gutship' | applied: data.js:555 | B | Gunboat is a sea word. |
| `n:'Razorfiend stalker'` | n:'Bladeback stalker' | applied: data.js:558 | B | |
| `n:'Wisp lancer',d:'A pulsar lance in place of the shuriken cannon.'` | n:'Sliver lancer',d:'A prism lance in place of the prism shards.' | applied: data.js:559 | B | |
| `n:'Songship warden'` | n:'Warded prism' | applied: data.js:560 | B | Warden is a Crusade class. |
| `n:'Scythe sentinel',d:'Adds gauss sentries:` | n:'Mote sentinel',d:'Adds a null spire: | applied: data.js:561 | B | Eclipse shows `gsentry` as Null spire. |
| `n:'Harvester tomb-turret',d:'Its doom arc sits on a turret` | n:'Turreted zenith',d:'Its corona arc sits on a turret | applied: data.js:562 | B | |
| `n:'Penitent lantern-cruiser'` | n:'Vigil lance-cruiser' | applied: data.js:566 | B | Arc unlock; lanterns are off-limits for the Crusade (bible 2.4). Must match godot/story/data/arcs.json (L). |
| `n:'Interdictor column escort'` | n:'Cordon column escort' | applied: data.js:567 | B | Arc unlock. |
| `n:'Gilded marauder'` | n:'Trophy wrecker' | applied: data.js:568 | B | Arc unlock (Hullbreaker trophy plates). |
| `n:'Sun-eater razorfiend',d:'Its tendril cluster becomes a second bio-plasma spitter on a turret;` | n:'Sun-eater bladeback',d:'Its tendril cluster becomes a second spine volley on a turret; | applied: data.js:569 | B | Arc unlock. |
| `n:'Archive wraithcarrier'` | n:'Ringing aperture' | applied: data.js:570 | B | Arc unlock (the Ringing Field, bible 6.10). |
| `n:'Jackal court guard',d:'Both gauss guns on turrets and a gauss sentry, 10 less hull.'` | n:'Archive guard flare',d:'Both null cannons on turrets and a null spire, 10 less hull.' | applied: data.js:571 | B | Arc unlock. |
| `voidsworn:'Zealot flotilla'` | voidsworn:'Frontier flotilla' | applied: data.js:594 | B | Archetype names. |
| `ithar:'Wisp flight',deathless:'Scythe harvest'` | ithar:'Sliver flight',deathless:'Mote cloud' | applied: data.js:594 | B | |
| `voidsworn:'Cathedral line'` | voidsworn:'Bastion line' | applied: data.js:595 | B | |
| `chorus:'Titan pod',ithar:'Songline'` | chorus:'Bloat pod',ithar:'Prism line' | applied: data.js:595 | B | |
| `voidsworn:'Reliquary group'` | voidsworn:'Hearth group' | applied: data.js:596 | B | |
| `corsair:'Raider nest',chorus:'Hive cluster',ithar:'Wraith host',deathless:'Harvest ark'` | corsair:'Hulk den',chorus:'Brood cluster',ithar:'Aperture host',deathless:'Repair host' | applied: data.js:596 | B | |

## 9. Nemesis tables, adaptations, captain and ship name pools

One name, one owner (bible 1.4): no captain pool rolls an admiral's given name or surname, no Nemesis pool rolls a boss or admiral name, no epithet repeats across admiral, scar and persona. Whole lists are quoted because the list itself changes. Lists keep their length and shape; `scarBy` entries must stay members of `scars`.

### 9.1 Nemesis name parts, titles, scars (data.js NEM_FAC)

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `pre:['Krag','Vash','Rusk','Gor','Snag','Black','Red','Mad','Skarn','Jagg']` | pre:['Krag','Drog','Rusk','Gor','Snag','Hask','Grul','Murg','Skarn','Jagg'] | applied: data.js:461 | B | Hullbreaker: harsh one-syllable fronts (bible 4.9); Vash sat next to Vesh the Collector. |
| `post:['Tooth','Maw','Gut','Vane','Hook','Knuckle','Rot','Grin','Spur','Wreck']` | post:['Tooth','Maw','Gut','Vise','Hook','Knuckle','Rot','Grin','Spur','Wreck'] | applied: data.js:461 | B | Vane is a Crusade surname. |
| `titles:['Reaver-king','Warlord','Scrap-baron','Pirate prince']` | titles:['Apex','First Claw','Den-alpha','Warlord'] | applied: data.js:461 | B | Canonical Nemesis titles. |
| `scars:['the Burned','Ironjaw','Half-Face','the Uncaught','Patchwork','One-Eye'],scarBy:{fled:['the Uncaught'],burn:['the Burned','Half-Face'],wound:['Ironjaw','Patchwork','One-Eye']}` | scars:['the Burned','Broken-Jaw','Half-Face','the Uncaught','Patchwork','One-Eye'],scarBy:{fled:['the Uncaught'],burn:['the Burned','Half-Face'],wound:['Broken-Jaw','Patchwork','One-Eye']} | applied: data.js:462 | B | Ironjaw is gone with Grax. |
| `pre:['Ald','Cor','Esm','Hal','Ord','Gyr','Wulf','Sig','Mor','Ed'],post:['ric','mar','wyn','gar','wine','mund','red','ith','helm','wold'],titles:['Ash-king','Regent','Barrow-king','Dust-sovereign']` | pre:['Mar','Kae','Hal','Tor','Ess','Ul','Vor','Iv','Sar','Den'],post:['un','lo','vane','eth','ane','ix','or','ael','en','ast'],titles:['High Nadir','Eclipse-prime','Archivist','Nadir'] | applied: data.js:464 | B | Eclipse: old Starwright names (bible 7.9; Marun, Kaelo and the sample Halvane can roll on purpose, the four admirals cannot). Canonical Nemesis titles plus the top rank. |
| `fem:['Esm','Ed','Sig']` | fem:['Ess','Kae','Iv'] | applied: data.js:465 | B | |
| `scars:['the Twice-Dead','the Rebuilt','Cracked-Crown','the Unfinished','Hollow-Eye','the Patient'],scarBy:{fled:['the Patient','the Unfinished'],burn:['Hollow-Eye','the Rebuilt'],wound:['the Twice-Dead','Cracked-Crown','the Rebuilt']}` | scars:['the Twice-Dead','the Rebuilt','Cracked-Visor','Half-Restored','Hollow-Eye','of the Late Copy'],scarBy:{fled:['of the Late Copy','Half-Restored'],burn:['Hollow-Eye','the Rebuilt'],wound:['the Twice-Dead','Cracked-Visor','the Rebuilt']} | applied: data.js:465 | B | Iteration language (bible 7.9). The Unfinished is the Glasswright flagship; the Patient is a persona; no crowns. |
| `pre:['Ael','Ith','Sae','Ny','Cael','Lir','Tal','Fae','Ely','Ors'],post:['wyn','riel','thas','lune','vael','dris','eth','nor','iel','ane'],titles:['Seraph','Starwarden','Duelist','Wing-lord']` | pre:['Kor','Sev','Tal','Ol','Ves','Dre','Ish','Ren','Cal','Ny'],post:['ek','is','oro','an','et','ul','ith','im','os','ae'],titles:['Lens-keeper','First Mirror','Keeper of Astra','Duelist'] | applied: data.js:467 | B | Glasswright: short and crisp, less elvish (bible 6.9). Canonical Nemesis titles plus Duelist. |
| `fem:['Ael','Sae','Fae','Ely','Lir']` | fem:['Ves','Ish','Ny','Dre'] | applied: data.js:468 | B | |
| `scars:['the Cracked Prism','Dimmed','the Scarred Sail','Thornwing','the Unbowed','Ashwake'],scarBy:{fled:['the Unbowed','Ashwake'],burn:['Dimmed','the Cracked Prism'],wound:['the Scarred Sail','Thornwing','the Cracked Prism']}` | scars:['the Cracked Prism','Dimmed','the Scarred Vane','Thornwing','the Unbowed','Ashwake'],scarBy:{fled:['the Unbowed','Ashwake'],burn:['Dimmed','the Cracked Prism'],wound:['the Scarred Vane','Thornwing','the Cracked Prism']} | applied: data.js:468 | B | Vanes, not sails. |
| `pre:['Seventh','Hollow','Wet','Grieving','Ninefold','Brine','Pale','Deep','Thrumming','Gnawing']` | pre:['Seventh','Hollow','Wet','Sour','Bloated','Brine','Pale','Deep','Thrumming','Gnawing'] | applied: data.js:470 | B | Ninefold plus Maw would roll the boss; grief belongs to the Glasswrights. |
| `titles:['Spawn-mother','Elder Throat','Gorge-mind','Brood-queen']` | titles:['Spawn-mother','Elder Throat','Gorge-mind','Maw-mother'] | applied: data.js:470 | B | Canonical (bible 5.9); brood-queen is a Tyranid word. |
| `pre:['Konrad','Ilsa','Viktor','Aldric','Petra','Halvar','Ruprecht','Katrin','Sanne','Gerold']` | pre:['Konrad','Marit','Viktor','Aldric','Petra','Halvar','Ruprecht','Katrin','Sanne','Gerold'] | applied: data.js:473 | B | Ilsa is First Admiral Kassar. |
| `titles:['Grand Admiral','Fleet Marshal','Line Admiral','High Commodore']` | titles:['First Admiral','Fleet Marshal','Line Admiral','High Commodore'] | applied: data.js:473 | B | Canonical rank. |
| `fem:['Ilsa','Petra','Katrin','Sanne']` | fem:['Marit','Petra','Katrin','Sanne'] | applied: data.js:474 | B | |
| `scars:['the Burned Admiral','Ironside','One-Arm','the Unbroken','Scarface','the Survivor'],scarBy:{fled:['the Survivor','the Unbroken'],burn:['the Burned Admiral','Scarface'],wound:['One-Arm','Ironside','Scarface']}` | scars:['the Burned Admiral','Ironside','One-Arm','the Unbroken','Scar-Cheek','the Survivor'],scarBy:{fled:['the Survivor','the Unbroken'],burn:['the Burned Admiral','Scar-Cheek'],wound:['One-Arm','Ironside','Scar-Cheek']} | applied: data.js:474 | B | Scarface is a film title. |
| `pre:['Saint','Brother','Censor','Provost','Shriver','Votary','Arch-deacon','Cantor','Sister','Lector']` | pre:['Leofric','Margit','Osmund','Ida','Berthold','Hedda','Wendel','Agathe','Gunther','Edda'] | applied: data.js:476 | B | Crusade: old European given names (bible 2.10); every church title out. |
| `titles:['Crusade-master','High Votary','Lord Censor','Arch-shriver']` | titles:['High Warden','Warden of the Roll','Dawnwarden','Oath-warden'] | applied: data.js:476 | B | Bible 2.10 titles. |
| `fem:['Sister'],masc:['Brother']` | fem:['Margit','Ida','Hedda','Agathe','Edda'],masc:['Leofric','Osmund','Berthold','Wendel','Gunther'] | applied: data.js:477 | B | |
| `scars:['the Branded','Ironhand','the Martyr-Scarred','Burnt-Psalm','the Unrepentant','Ashface'],scarBy:{fled:['the Unrepentant'],burn:['the Branded','Burnt-Psalm','Ashface'],wound:['Ironhand','the Martyr-Scarred']}` | scars:['the Branded','Iron-Armed','the Frost-Scarred','Burnt-Oath','the Debt-Bound','Ashface'],scarBy:{fled:['the Debt-Bound'],burn:['the Branded','Burnt-Oath','Ashface'],wound:['Iron-Armed','the Frost-Scarred']} | applied: data.js:477 | B | Martyr, psalm and repentance are church words; Iron Hands is a Space Marine chapter. |
| `undying:{n:'Endless dead'` | undying:{n:'Spare frames' | applied: data.js:453 | B | Nemesis trait (id stays). |

### 9.2 Nemesis adaptations (NEM_ADAPT_FAC)

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `deathless:{shields:'Quantum ward',pd:'Gauss pylons',armor:'Grave-alloy shell',evasion:'Phase drift',aim:'Barrow sight',special:{id:'legion',n:'Wider legion'` | deathless:{shields:'Corona ward',pd:'Null spires',armor:'Sunshade shell',evasion:'Fold skips',aim:'Long-memory sight',special:{id:'legion',n:'Deeper backups' | applied: data.js:483 | B | Id `legion` stays. |
| `armor:'Dawnglass spine',evasion:'Starwind vanes',aim:'Farsight crystals'` | armor:'Waveguide spine',evasion:'Starwind vanes',aim:'Interferometer lenses' | applied: data.js:484 | B | Bible 6.10 refit words. |
| `ithar:{shields:'Prism lattice'` | ithar:{shields:'Prism matrix' | applied: data.js:484 | B | |
| `aim:'Hunting eyes'` | aim:'Tasting pores' | applied: data.js:485 | B | |
| `voidsworn:{shields:'Ward rites',pd:'Censer flak',armor:'Blessed plate',evasion:'Litany of speed',aim:'Augury rites'` | voidsworn:{shields:'Screen drills',pd:'Spark flak',armor:'Riveted plate',evasion:'Oath of speed',aim:'Hand-laid sights' | applied: data.js:487 | B | No rites, censers, blessings or litanies. |

### 9.3 Captain pools (CAP_FIRST, CAP_LAST, CAPTAINS)

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `const CAP_FIRST = ['Ilse','Corvin','Maren','Tobias','Anselm','Vera','Casimir','Odile','Lucan','Serafine','Aurek','Helka','Brannoc','Isolde','Garrick','Mireille','Dagan','Thessaly','Rourke','Elsbeth','Konrad','Yara','Osric','Ninette','Halvard','Petra','Lysander','Calla'];` | const CAP_FIRST = ['Ilse','Corvin','Mathilde','Tobias','Anselm','Vera','Casimir','Odile','Lucan','Sabine','Emeric','Helka','Brannoc','Rosalind','Garrick','Margery','Dagan','Thessaly','Rourke','Elsbeth','Aldous','Yara','Osric','Ninette','Hadrian','Clemence','Lysander','Calla']; | applied: data.js:255 | B | Maren is a Hegemony admiral's surname, Aurek sits next to Aurex, Serafine is seraph, Konrad, Halvard and Petra belong to the Hegemony, Isolde and Mireille echoed old Ithar names. |
| `'Holloway','Sable','Wyndham'` | 'Holloway','Sedley','Wyndham' | applied: data.js:256 | B | Sable is the Hullbreaker admiral. |
| `'Okonkwo','Brandt','Salo'` | 'Okonkwo','Ashby','Salo' | applied: data.js:256 | B | Brandt is a Hegemony surname. |
| `first:['Konrad','Ilsa','Dace','Mara','Oskar',` | first:['Konrad','Marit','Joost','Mara','Anders', | applied: data.js:521 | B | Hegemony captains could roll Ilsa Kassar, Dace Vorn, Oskar Maren. |
| `last:['Reiter','Kassel','Brandt','Vorn',` | last:['Reiter','Kassel','Brandt','Vollmer', | applied: data.js:521 | B | Vorn is Commodore Dace Vorn. |
| `corsair:{ranks:['Mate','Skipper','Captain','Reaver-captain','Warlord'],first:['Rusty','Grim','Mad','One-Eye','Lucky','Red','Scrap','Knuckles','Salt','Patch','Dutch','Sly','Bones','Tiny','Hooks','Jinx'],last:['Krogg','Brannigan','Mallory','Blackwater','Rook','Sharkey','Gutter','Varrick','the Knife','Two-Guns','Tallow','Ironjaw','Spatchcock','Quill','Rattigan','Slade']}` | corsair:{ranks:['Claw','Fang','Howler','Ripper','Warlord'],first:['Krogg','Gash','Rorr','Brak','Hulg','Drask','Olk','Thrag','Grisk','Vorg','Gnarl','Karsk','Bruk','Ulm','Rask','Tusk'],last:['the Gutter','Rattlebone','Two-Claws','Scrapback','Longjaw','Gristle','Chainback','Ashfur','Red-Muzzle','Torn-Ear','Rustcoat','the Quiet','Bent-Tooth','Boltneck','Greyback','the Tracker']} | applied: data.js:522 | B | Canonical ranks. Harsh names plus fight-earned epithets, no human surnames (bible 4.9); Rook is the core R-5. |
| `chorus:{ranks:['Spawn-mind','Brood-node','Throat','Elder throat','Matriarch'],names:['Seventh Mouth','Hollow Song','Deep Murmur','Thrumming Coil','Pale Bloom','Wet Whisper','Ninefold','Grieving Tide','Brine Hymn','Moult','Ashk-of-Many','Sallow Choir','Undertow','Last Spore','Coiled Psalm','Lantern Gut']}` | chorus:{ranks:['Spawn-mind','Node','Throat','Elder throat','Great throat'],names:['Seventh Mouth','Hollow Gut','Deep Murmur','Thrumming Coil','Pale Bloom','Wet Whisper','Ninth Tooth','Gnawing Tide','Brine Mouth','Moult','Ashk-of-Many','Sallow Rasp','Undertow','Last Spore','Coiled Gullet','Lantern Gut']} | applied: data.js:523 | B | Bible 5.9 and 5.10. |
| `ithar:{ranks:['Wing','Sail','Seraph','High seraph','Starwarden'],first:['Siriel','Aelith','Vaelen','Thandor','Ilyra','Caelis','Ithrien','Nyssa','Orrin','Saelune','Talvar','Eluned','Faewyn','Liraen','Corvel','Ysolde'],last:['Starglass','Dawnsail','Veilborn','Moonreach','Sunward','Lightwhisper','Skyhollow','Silverwake','Brightmere','Glasswing','Nightbloom','Farcall']}` | ithar:{ranks:['Glimmer','Glint','Facet','Mirror','Lens-keeper'],first:['Oskel','Ilvy','Teo','Kesh','Lun','Pell','Ressa','Taro','Imre','Nell','Tobin','Avin','Sefa','Davin','Orra','Fen'],last:['of the Second Lens','of the Bright Collector','of the Long Beamline','of the Quiet Mirror','of the Ninth Facet','of the Cold Lens','of the Far Collector','of the First Prism','of the Split Beam','of the Slow Focus','of the Silver Array','of the Deep Mirror']} | applied: data.js:524 | B | Bible 6.9 and 6.10. Captains read "Oskel of the Second Lens". Sunward is now the Crusade's name. |
| `deathless:{ranks:['Warden','Overseer','Cryptlord','Overlord','Dynast'],names:['Imhoten','Setekh','Amuneth','Rahotep','Tauret','Menkara','Khepset','Nefrah','Osirak','Ptahmet','Sobekar','Thutem','Wadjen','Hekamun'],epithets:['the Hollow','the Patient','the Silent','the Undying','of the Ninth Tomb','the Unbroken','the Pale','the Ever-Watching','the Iron-Hearted','of the Sunless Court']}` | deathless:{ranks:['Shade','Gloam','Umbra','Midnight','Nadir'],names:['Quorel','Benth','Ivess','Toran','Odrun','Desmae','Selith','Vantor','Imra','Caddex','Rhosse','Altheve','Keshet','Pallun'],epithets:['of the Second Frame','of the Fifth Frame','the Thrice-Copied','of the Old Copy','the Seventh-Housed','the Once-Restored','of the Clean Copy','of the Twelfth Frame','the Never-Dark','of the Last Backup']} | applied: data.js:525 | B | Canonical ranks; Starwright names; iteration epithets (bible 7.9). Warden was also a Crusade class. |

### 9.4 Ship name pools

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `const SHIP_NAMES = ['Unyielding Oath','Saint Vesper’s Wrath','Ashen Vigil','Lament of Iron','Bright Censure','Hymn of Ruin','Oathkeeper','Merciless Litany','Cinder Psalm','Pale Crusader','Everwatch','Grave Tithe','Sanctified Fury','Iron Requiem','Dawn of Cinders','Martyr’s Resolve','Judgement Bell','Votive Flame','Sorrow’s Edge','Penance Undying','Relentless Canticle','Obsidian Choir','Hallowed Anvil','Last Benediction','Wrathful Seraph','Cold Absolution','Thorn of Heaven','Vigilant Censer'];` | const SHIP_NAMES = ['Unyielding Oath','Wrath of Vesper','Ashen Vigil','Long Watch','Bright Censure','Banked Fire','Oathkeeper','Merciless Frost','Cinder Vow','Pale Crusader','Everwatch','Debt of Vesper','Cold Fury','Iron Dusk','Dawn of Cinders','Resolve of the Reach','Judgement Bell','Oath Flame','Edge of Winter','Unpaid Debt','Relentless Ember','Obsidian Brand','Black Anvil','Acceptable Loss','Burning Spire','Cold Reckoning','Thorn of the Reach','Vigilant Ash']; | applied: data.js:254 | B | Crusade: oath, fire and cold (bible 2.10). Every church word out; no apostrophes. |
| `'HNS Ironclad','HNS Resolute','HNS Bastion','HNS Ascendancy','HNS Vindicator','HNS Castellan'` | 'HNS Optimal','HNS Resolute','HNS Consensus','HNS Ascendancy','HNS Projection','HNS Punctual' | applied: data.js:527 | B | Ironclad is a sea word; Bastion is a Crusade class; Vindicator and Castellan are 40k. |
| `corsair:['Bilge Rat','Salt Debt','Last Laugh','Nine Lives','Scrapjaw','Black Ledger','Gilded Liar','Rattletrap','Widow’s Wager','Low Tide']` | corsair:['No Quarter','Gut Hook','Chain of Teeth','Forty Captains','Second Death','Scrapjaw','Cold Trail','Rattletrap','Long Howl','Last Scent'] | applied: data.js:528 | B | Threats and kills (bible 4.9); sea words out. |
| `chorus:['Shrieking Coil','Brood Vessel Om','Mournful Gut','Spine Choir','Hive-node Vesk','Crawling Hymn','Wet Psalm','Gnawing Bloom','Tide of Teeth','Hollowsong']` | chorus:['Shrieking Coil','Brood Vessel Om','Sour Gut','Spine Gullet','Node Vesk','Crawling Maw','Wet Mouth','Gnawing Bloom','Tide of Teeth','Hollowgut'] | applied: data.js:529 | B | |
| `ithar:['Glass Requiem','Morningveil','Starfall','Quiet Wing','Lumen Arc','Silver Lament','Aurora’s Grace','Farlight','Moonsorrow','Petal Storm']` | ithar:['Last Reflection','Morningveil','Starfall','Quiet Wing','Lumen Arc','Silver Lament','Held Spectrum','Farlight','Moonsorrow','What We Built'] | applied: data.js:530 | B | Light and grief (bible 6.9). |
| `deathless:['Tomb of Nine Kings','Ankh of Ash','Silent Procession','Dust Eternal','The Unsleeping','Obelisk of Night','Crypt of Teeth','Sunless Barge','Pale Sovereign','Ever-Watch']` | deathless:['Remembered Noon','Warmth Recalled','Silent Procession','Long Night','The Unsleeping','Shade of Noon','Ninth Winter','Sunless Hours','Cold Archive','Noon Kept'] | applied: data.js:531 | B | Memory, darkness, the lost sun. |
| `hegemony:['HNS Dominator','HNS Relentless','HNS Sovereign','HNS Executor','HNS Imperious','HNS Harbinger',` | hegemony:['HNS Dominator','HNS Relentless','HNS Sovereign','HNS Comptroller','HNS Allocation','HNS Forecast', | applied: ui3d.js:19 | B | Skirmish names (ui3d.js FNAMES). Executor is Star Wars; Harbinger is Mass Effect. |
| `corsair:['Rust Maw','Gutter Queen','Red Tithe',` | corsair:['Rust Maw','Gutter Queen','Red Tally', | applied: ui3d.js:20 | B | |
| `'Salvage Right','Hollow Crown']` | 'Salvage Right','Bent Crown'] | applied: ui3d.js:20 | B | |
| `chorus:['Hive-node Ashk','Brood Vessel Ul','Shrieker','Mawling','Gorefeather','Sac-mother','Thornback','Tidehunger','Wet Choir','Crawling Hymn']` | chorus:['Node Ashk','Brood Vessel Ul','Shrieker','Mawling','Gorebloom','Sac-mother','Thornback','Tidehunger','Wet Maw','Crawling Gut'] | applied: ui3d.js:21 | B | |
| `ithar:['Silverthorn','Dawnwhisper','Lament of Stars','Glass Heron','Moonveil','Farsinger','Pale Current','Starfall','Quiet Blade','Evening Tide']` | ithar:['Silverthorn','Clear Whisper','Lament of Stars','Glass Heron','Moonveil','Far Focus','Pale Current','Starfall','Quiet Prism','Evening Tide'] | applied: ui3d.js:22 | B | |
| `deathless:['Eternal Vigil','The Unbroken','Sepulchre','Tomb of Ashes','Grave Sovereign','Ossuary','Never-Ending','Obelisk','Dust Throne','Silent Heir']` | deathless:['Long Noon','The Unbroken','Last Light Kept','Copy of Ardent','Ninth Shade','Cold Memory','Never-Ending','Gnomon','Dust of Noon','Silent Heir'] | applied: ui3d.js:23 | B | |
| `"ship": "Saint Ignatius"` | "ship": "Banked Fire" | applied: godot/scenes/campaign/campaign_scene.gd:59 | G2 | Screenshot fixture (shows on the Hall of the fallen). Its captain "Ordo Halvar" becomes "Casimir Holloway" (Ordo is an Inquisition word). |

## 10. Help text and Godot-only screen text

### 10.1 How to play (both games)

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `gauss weapons mostly ignore them` | null weapons mostly ignore them | godot/ui/campaign/campaign_ui.gd:1017 | G3 | |
| `Hegemony ion pulses, Corsair overburn, Chorus regrowth and frenzy, Ithar phase jumps, Deathless reanimation beams, and the Voidsworn’s burns, reloads and shield surges` | Hegemony ion pulses, Hullbreaker overburn, Chorus regrowth and frenzy, Glasswright phase jumps, Eclipse repair swarms, and the Crusade’s burns, reloads and shield surges | applied: campaign_meta.js:165 | B | |
| `patrons grow fond of you as you take their boons, offering rarer boons and eventually a gift at the start of a run` | cores sync with you as you take their protocols, offering rarer protocols and eventually a gift at the start of a run | godot/ui/campaign/campaign_ui.gd:1011 | G3 | Godot copy of the 2.x row (the browser line has `<b>` tags). |

### 10.2 Godot screens (G2, G3)

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `const TAGLINE := "Command a crusade of gothic capital ships through three hostile sectors. Every hull you lose stays lost, and so does its captain."` | const TAGLINE := "Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain." | applied: godot/ui/battle/brand.gd:11 | G2 | Same tagline as row 1.2 (G2). |
| `term("patrons", true) + " watching"` | term("patrons", true) + " in range" | godot/ui/campaign/campaign_ui.gd:575 | G3 | Map sidebar box title after the TERMS switch ("Cores in range"). |
| `" · win at a " + term("sigil") + " for a " + term("boon")` | " · win at a " + term("sigil") + " for a " + term("boon") | godot/ui/campaign/campaign_ui.gd:575 | G3 | Reads "win at a signal for a protocol" after the switch: fine as is, listed so nobody hunts for it. |
| `"Win at a stop with a " + term("patron") + "'s " + term("sigil") + " and that " + term("patron") + " offers a " + term("boon") + "."` | "Win at a stop carrying a " + term("patron") + "'s " + term("sigil") + " and that " + term("patron") + " offers a " + term("boon") + "." | godot/ui/campaign/campaign_ui.gd:575 | G3 | Tooltip; "carrying" reads better with signal. |
| `"None yet. Win at a node with a " + term("patron") + "’s " + term("sigil") + " to earn one."` | "None yet. Win at a node carrying a " + term("patron") + "’s " + term("sigil") + " to earn one." | godot/ui/campaign/campaign_ui.gd:662 | G3 | |
| `"startRun": "Launch the crusade"` | "startRun": "Launch" | applied: godot/main/campaign_fallback_ui.gd:7 | G2 | Fallback UI label; the run word depends on the faction (Homecoming, raid ...). |

G2's own rows already landed in 49f0d85 (title, window title, project name, product name and description; exe file name kept as Voidsworn.exe, save folder kept). Nothing else for G2 in project.godot or export_presets.cfg. `godot/main/FEATURES.md` mentions the old exe and folder names only as file paths; keep.

## 11. Story layer (godot/story, L)

L rewrites `godot/story/` to round 8 in Job 2 (arcs, outlines, titles, unlocks, chronicle and career text, Nemesis story lines, voices, tokens.gd, tests, README). Every id, hook, trigger and data shape stays. The rows below are the ones other streams read or mirror; the full text changes are in L's commits and `lore_rollout_notes.md`.

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `"unlock_name": "Penitent lantern-cruiser"` | "unlock_name": "Vigil lance-cruiser" | applied: godot/story/data/arcs.json:22 | L | Must match data.js HULL_VARIANTS (8.x). |
| `"unlock_name": "Interdictor column escort"` | "unlock_name": "Cordon column escort" | applied: godot/story/data/arcs.json:43 | L | |
| `"unlock_name": "Gilded marauder"` | "unlock_name": "Trophy wrecker" | applied: godot/story/data/arcs.json:64 | L | |
| `"unlock_name": "Sun-eater razorfiend"` | "unlock_name": "Sun-eater bladeback" | applied: godot/story/data/arcs.json:85 | L | |
| `"unlock_name": "Archive wraithcarrier"` | "unlock_name": "Ringing aperture" | applied: godot/story/data/arcs.json:106 | L | |
| `"unlock_name": "Court guard destroyer"` | "unlock_name": "Archive guard flare" | applied: godot/story/data/arcs.json:127 | L | Already differed from data.js ("Jackal court guard"); both now say Archive guard flare. |
| `Lances and gauss guns make up` | Lances and null guns make up | applied: godot/story/data/titles.json:10 | L | Title rule text. |
| `"Warlord Grax Ironjaw` | "Warlord Grax Steelgrin | applied (now "Warlord Grax Ironmaw", section 16) | L | Test fixtures and README sample. |
| `Admiral Castellan Vex` | Admiral Roderic Vex | applied: data.js:205; tools/portraits/make_batches.py:41; godot/story/story.gd:155,181; godot/story/test/story_test.gd:233,235 | B, P, L | Test fixtures and comments (data.js row is in 6). |
| `const FEMININE := [` | (list rewritten to the new pools) | godot/story/tokens.gd:19 | L | tokens.gd pronoun fallback: drop Isolde, Mireille, Serafine, Maren, Ilsa, Aelith, Ilyra, Nyssa, Saelune, Eluned, Faewyn, Liraen, Ysolde, Tauret, Nefrah, Khepset; add Mathilde, Sabine, Rosalind, Margery, Clemence, Marit, Margit, Ida, Hedda, Agathe, Edda, Tamsa, Ilvy, Ressa, Nell, Sefa, Orra, Desmae, Imra, Rhosse, Altheve, plus the Nemesis prefixes from NEM_FAC fem lists. |

## 12. Portraits (P)

P landed the round 8 prompts in e243729. What is left in `tools/portraits/make_batches.py` is the batch 1 and 2 history (subjects already painted, kept so old batches can be rebuilt). If any of those subjects is queued again, change the names in it first:

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `Portrait of Admiral Castellan Vex of the Voidsworn Crusade` | Portrait of Admiral Roderic Vex of the Sunward Crusade | applied: tools/portraits/make_batches.py:41 | P | |
| `Portrait of Grand Admiral Ilsa Kassar` | Portrait of First Admiral Ilsa Kassar | applied: tools/portraits/make_batches.py:45 | P | |
| `Portrait of Warlord Grax Ironjaw of the Ashfall Corsairs` | Portrait of Warlord Grax Steelgrin of the Ashfall Hullbreakers | applied: tools/portraits/make_batches.py:49 | P | And the human-pirate description becomes the furred bear and wolf species (brief, Portraits row). |
| `Portrait of Overlord Nekhet the Undying of the Deathless Dynasty` | Portrait of Nadir Aurex, Ninth Frame, of Eclipse | applied: tools/portraits/make_batches.py:58 | P | |
| `Portrait of The Mending Choir` | Portrait of The Mending Throng | applied: tools/portraits/make_batches.py:26 | P | |
| `Portrait of Aelith Dawnsail of the Ithar` | Portrait of Tamsa of the Clear Aperture, a Glasswright | applied: tools/portraits/make_batches.py:53,91 | P | |
| `'Portrait of a Nemesis, a rival enemy commander of the Ithar: %s. %s'` | 'Portrait of a Nemesis, a rival enemy commander of the Glasswrights: %s. %s' | applied: tools/portraits/make_batches.py:192,308 | P | |
| `'A Nemesis of the %s, a rival enemy war-organism: %s. %s' % (_fac.capitalize()` | use a display name map: chorus "the Chorus", deathless "Eclipse" | (the owner reworded this line since the map was written: recheck by hand) | see note | `_fac.capitalize()` would print "Deathless". |

## 16. Ryan's naming rulings of Oct 27 and 28 (verified by Opus, folded in Oct 31)

Source: contrib/muse/reviews/rollout_audit_2026_10_27.md, "Ryan's rulings" and the Oct 28 ruling; text_synthesis_2026_10_27.md:46. These rows override the same strings anywhere above. Kept by ruling: H-3 Crucible, "the Hunger Below" (display name stands) and Salvage swarm.

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Warlord Grax Steelgrin'` | n:'Warlord Grax Ironmaw' | data.js:221 | B | Ruling 1: Steelgrin is a Warhammer Fantasy surname. Replaces V5's Steelgrin. |
| `~tools/portraits/crests.py and phone_sheets.py~` | 'Grax Ironmaw' (was 'Grax Steelgrin') | tools/portraits/crests.py:28; tools/portraits/phone_sheets.py:15 | P | Name tables outside the grep scope, located by hand. |
| `Portrait of Warlord Grax Steelgrin` | Portrait of Warlord Grax Ironmaw | tools/portraits/make_batches.py:49 | P | |
| `"Warlord Grax Steelgrin"` | "Warlord Grax Ironmaw" | applied: godot/story/test/story_test.gd:195,276 | L | Story test fixtures. |
| `stealing starlight to light a new sun.` | siphoning stellar energy to light a new sun. | data.js:127 | B | Ruling 2 ("energy, not light"). Rest of the blurb unchanged. |
| `titles:['High Nadir','Eclipse-prime','Archivist','Nadir']` | titles:['High Nadir','Eclipse-prime','Archivist'] | data.js:464 | B | Ruling 4: back to the bible's three titles. Replaces part of row 9.1. |
| `'Sac-mother','Thornback','Tidehunger'` | 'Sac-mother','Sour Spine','Tidehunger' | ui3d.js:21 | B | Ruling 6: Thornback is a Tyranid name. |
| `'Glass Heron','Moonveil','Far Focus'` | 'Glass Heron','Still Glass','Far Focus' | ui3d.js:22 | B | Ruling 6: Moonveil is an Elden Ring sword. |
| `'Black Anvil','Acceptable Loss','Burning Spire'` | 'Black Anvil','Debt Paid','Burning Spire' | data.js:254 | B | Oct 28 ruling: swap it out; "Debt Paid" is the chair's suggestion on record (vetoable). Bible 2.10's sample list still names Acceptable Loss: Opus's file. |

## 17. Small renames accepted by Opus (Oct 31)

From L's read of the Muse reviews (lore_rollout_notes.md section 3), accepted by Opus. B applies them in data.js; G1 and G3 get them by re-exporting the tables.

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Founders’ salvage'` | n:'Founders\u2019 cache' | data.js:249 | B | Legacy unlock; the item-type word stays out of item names. |
| `logbook:'The Archive'` | logbook:'Archive extract' | data.js:271 | B | Eclipse logbook item; "the Archive" stays the place. |
| `phylactery:{n:'Eclipse backup frame'` | phylactery:{n:'Backup frame' | data.js:193 | B | Text pack T-07: the base name shows for every faction. Eclipse's own name stays Second Ignition. |

Nemesis cards in neutral words (text pack T-30 to T-60), because the Nemesis can be he, she or it. Repeated sentences are listed once and apply at every place they occur:

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `His ships take 25% more damage on rear-arc hits.` | Enemy ships take 25% more damage on rear-arc hits. | data.js:429 | B | Text pack T-30 (INV-0899). |
| `Ion and lance hits strip 50% more shield from his ships.` | Ion and lance hits strip 50% more shield from enemy ships. | data.js:430 | B | Text pack T-31 (INV-0901). |
| `Torpedoes are 15 easier to land on his ships.` | Torpedoes are 15 easier to land on enemy ships. | data.js:431 | B | Text pack T-32 (INV-0903). |
| `His ships carry 30% fewer crew to repel boarders.` | Enemy ships carry 30% fewer crew to repel boarders. | data.js:432 | B | Text pack T-33 (INV-0905). |
| `His ships aim 10 worse at targets 2 hexes away or closer.` | Enemy ships aim 10 worse at targets 2 hexes away or closer. | data.js:433 | B | Text pack T-34 (INV-0907). |
| `His escorts break and flee once his flagship falls below 60% hull.` | Enemy escorts break and flee once the flagship falls below 60% hull. | data.js:434 | B | Text pack T-35 (INV-0909). |
| `His ships have 1 less movement.` | Enemy ships have 1 less movement. | data.js:435 | B | Text pack T-36 (INV-0911). |
| `His ships aim 6 better.` | Enemy ships aim 6 better. | data.js:450 | B | Text pack T-37 (INV-0913). |
| `His ships have 8% more armor.` | Enemy ships have 8% more armor. | data.js:450 | B | Text pack T-38 (INV-0915). |
| `His ships have 1 more movement.` | Enemy ships have 1 more movement. | data.js:450 | B | Text pack T-39 (INV-0917). |
| `His ships have 12% more hull.` | Enemy ships have 12% more hull. | data.js:451 | B | Text pack T-40 (INV-0919). |
| `His ships have 10% more critical chance.` | Enemy ships have 10% more critical chance. | data.js:451 | B | Text pack T-41 (INV-0921). |
| `His ships have 20% more shields.` | Enemy ships have 20% more shields. | data.js:437,451 | B | Text pack T-42 (INV-0923). |
| `His ships carry 30% more crew.` | Enemy ships carry 30% more crew. | data.js:452 | B | Text pack T-43 (INV-0925). |
| `His ships regrow 4 more hull each turn.` | Enemy ships regrow 4 more hull each turn. | data.js:452 | B | Text pack T-44 (INV-0927). |
| `His carriers field one more wing.` | Enemy carriers field one more wing. | data.js:452 | B | Text pack T-45 (INV-0929). |
| `One more of his ships reassembles after falling.` | One more enemy ship reassembles after falling. | data.js:453 | B | Text pack T-46 (INV-0931). |
| `His ships are 8 harder to hit.` | Enemy ships are 8 harder to hit. | data.js:453 | B | Text pack T-47 (INV-0933). |
| `His guns reach 1 hex further.` | Enemy guns reach 1 hex further. | data.js:453 | B | Text pack T-48 (INV-0935). |
| `His ships deal 12% more damage to a ship next to them.` | Enemy ships deal 12% more damage to a ship next to them. | data.js:454 | B | Text pack T-49 (INV-0937). |
| `His torpedoes reload a turn faster.` | Enemy torpedoes reload a turn faster. | data.js:454 | B | Text pack T-50 (INV-0939). |
| `Two of his ships bolt on point defense.` | Two enemy ships bolt on point defense. | data.js:438 | B | Text pack T-52 (INV-0944). |
| `His ships have 10% more armor.` | Enemy ships have 10% more armor. | data.js:439 | B | Text pack T-53 (INV-0947). |
| `His ships have 8 more evasion.` | Enemy ships have 8 more evasion. | data.js:440 | B | Text pack T-54 (INV-0950). |
| `His ships aim 8 better.` | Enemy ships aim 8 better. | data.js:441 | B | Text pack T-55 (INV-0953). |
| `Bigger crew` | Bigger fleet | data.js:482 | B | Text pack T-56 (INV-1157 (corsair special, name)). |
| `One more ship joins his fleet.` | One more ship joins the fleet. | data.js:482 | B | Text pack T-57 (INV-1158 (corsair special)). |
| `One more of his ships reassembles.` | One more enemy ship reassembles. | data.js:483 | B | Text pack T-58 (INV-1160 (deathless special)). |
| `His ships are 6 more harder to hit.` | Enemy ships are 6 harder to hit. | data.js:484 | B | Text pack T-59 (INV-1162 (ithar special)). |
| `His ships regrow 3 more hull each turn.` | Enemy ships regrow 3 more hull each turn. | data.js:485 | B | Text pack T-60 (INV-1164 (chorus special)). |

Kept on purpose (Opus, Oct 31): the Eclipse rule name "Archive restore" in the verb text (text pack T-05 not taken), and the Chorus captain name Lantern Gut.

## 13. Vetoable calls (L's picks where the bible is silent)

Opus or Ryan can veto any of these; each is a few strings to swap.

- **V1 Tagline:** "Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain." (any faction can be played, so not "crusade").
- **V2 Faction blurbs:** six new one-liners in section 1 (gameplay half kept, lore half from the bible).
- **V3 Ship classes:** `cls` stays as the internal key; new display map: War-barge, Colossus (canonical), **Lattice-ship** for The Unfinished (the bible gives no class; it is built around the largest piece of the Lattice), Archive-ship (canonical).
- **V4 Crusade admirals:** Castellan Vex becomes **Admiral Roderic Vex**; Oath-Captain Malek Draven (canonical), Commodore Sera Ashgrove and High Admiral Oryn Thale kept.
- **V5 Hullbreaker admirals:** **Warlord Grax Ironmaw** (was Steelgrin; Ryan, Oct 27, section 16), **Old Mott** (no surname), **Sable the Smiling Knife** (human surname Venn dropped; a sable is a furred hunter, so the name fits the species), Vesh the Collector kept.
- **V6 Glasswright admirals** (name plus optical family line): aelith = **Tamsa of the Clear Aperture** (carriers), vaelen = **Saro of Long Focus** (lances; Command "Burning glass"), thorne = **Vell of the Third Mirror** (evasion; Command "Scatter the light"), mirelle = **Brin of the Fourth Lens** (shields). Corin skipped: Corin Reyes is Hegemony.
- **V7 Eclipse admirals by doctrine:** nekhet = **Nadir Aurex, Ninth Frame** (regrowth starter, and its portrait is the bible's broken ring mind), sekhmar = **Umbra Vessane, Third-Housed** (corona-arc offence), anuket = **Ostrel of the Long Copy** (silent flanker), khepra = **Seveth, Twice-Restored** (the durable one). Commands: Release the repair swarms, Noon volley, Out of the shadow, Sunshade wall.
- **V8 Name pools:** all pools in section 9. Hullbreaker captains are harsh names plus fight epithets ("Krogg the Gutter", "Thrag Longjaw"); Glasswright captains carry family lines ("Oskel of the Second Lens"); Eclipse captains carry iteration epithets ("Benth of the Fifth Frame"); Crusade Nemesis titles are the bible's (High Warden, Warden of the Roll, Dawnwarden, Oath-warden) over old European given names; Eclipse Nemesis titles High Nadir, Eclipse-prime, Archivist, Nadir; Glasswright Lens-keeper, First Mirror, Keeper of Astra, Duelist.
- **V9 Cores:** sync tiers **Listening, Partial sync, Synced, Full sync**; protocols renamed only where a church or song word or a clash forced it (Unbent Plating, Incendiary Warheads, Hot Tubes, Brood Harvest, Fortress). The S-6 badge letter is S.
- **V10 Faction-power strings:** void-shrine becomes **"A wall of names"** (a memorial station chalked with a lost crusade's names), and the Crusade verb becomes **"Keep the dawn watch"** (free after an offering there); "joined the song" becomes **"answered the tone"** (a dying Glasswright prism ringing one clear tone); "Waken the legion" becomes **"Back up the fleet"**; tomb-world becomes **"A siphon array"** (the hostile event) and **"A dormant hull yard"** (the Eclipse-only twin); the Eclipse rule "Endless legion" becomes **"Archive restore"**.
- **V11 Events:** the astropath becomes a signals officer and a founders' beacon (no psychics); the Ithar seer becomes a Glasswright wanderer and its keeper; the tithe vault becomes a toll vault; the pirate haven a raider den; "The saint answers" becomes "Luck holds".
- **V12 Nova cannon** becomes **Spinal cannon** (shared by three flagships, so a neutral name).
- **V13 Battle shapes:** the gravity-well board's label is "Hollow Sun" (canonical row: the dead star is the Hollow Sun); Colossus becomes "Giant wreck" (Colossus is now the Maw's class); Shoals becomes "Rock shoals"; Archipelago kept.
- **V14 (vetoed by Opus, Oct 27): relic becomes salvage.** The bible's 1.2 table lists "relic" as a never-say word, so the item type label changes too: **salvage** ("drops salvage", "Salvage: Wake-tracker", the Salvage heading, "a piece of salvage" where a count is needed). Ids stay (`RELICS`, `relic`, `relics`, `takeRelic`, `payRelic`, `relicChoice`, `eventRelic`, `relicName`). Rows in section 5b. Opus then ruled (5c): the wreck step becomes "Strip the wrecks" and Salvage rig becomes Scrap rig, so salvage has one meaning.
- **V15 Arc unlocks:** Vigil lance-cruiser, Cordon column escort, Trophy wrecker, Sun-eater bladeback, Ringing aperture, Archive guard flare.
- **V16 Run-end headlines:** Hullbreakers "Strongest keeps it", Glasswrights "The light is kept", Eclipse "Noon returns" (the others kept).
- **V17 Refits and relics the bible does not name:** section 5 (for example Scanner array, Screen capacitor, The Chalked Roll, Wake-tracker, Tasting pores, Annealing kilns, Long-count reckoner, Siphon ledger, Long clock).
- **V18 Small ones:** Hegemony "Shield wall order" (protocol now belongs to the cores), "Recovery crews" (was Salvage protocols), "Spitting volley", "Acid tide", Hegemony ship names Optimal, Consensus, Projection, Punctual, Comptroller, Allocation, Forecast.

## 14. Looked at and kept

- Generic words: void (Open void, Deep void, Quiet void), crusade (the Crusade's run word and "Pale Crusader", "Crusader's wrath"), Warden-class and Harrow-class, Lance array, Phase jump (Glasswright short jumps), Prism charge, Undying foes (Heat), Zealots (Nemesis trait), Ion cannon, Plasma drive, Deflector (Hegemony words), Bright Censure, Judgement Bell (bells belong to the Crusade), Ashen Vigil and Everwatch (bible ship names), Funeral Pyre and Pyre of Stars, Warlord's Pyre-Barge (canonical), Wolfpack (the Hullbreakers are wolf-like pack hunters), Archipelago.
- Chorus: the Matriarch of Nine Throats, Razormaw, Voice of the Deep, drone-spawn, spitter, brood, Spawning surge, Blood frenzy, Regrowth tide, Deep Murmur, Lantern Gut.
- Hegemony: the Iron Mandate, picket, vanguard, dominion, the rest of the HNS names, all admirals except Kassar's rank.
- Ids, save keys, CSS class names and code comments (the sweep in Job 3 reports display strings only).

## 15. Grep check

Every Old cell was searched as an exact substring (also with `’` and `’` swapped) across: data.js, battle.js, core.js, campaign_run.js, campaign_meta.js, campaign3d.js, ui3d.js, head.html, main3d.js, tools/portraits/make_batches.py, godot/project.godot, godot/export_presets.cfg, godot/main/FEATURES.md, godot/story (gd, json, md, py; not review_incorporation.md, which is history), godot/ui, godot/main, godot/scenes, godot/rules (code and tests), godot/campaign (code and tests, not oracle), godot/portraits. Rows found: all; rows missing: 0. core.js, main3d.js and godot/portraits/*.gd had no display hits (ids only).
