# Rename map, final (lore round 8, approved Oct 27 2026, R59)

Written by L (lore rollout helper). Source of truth: `lore_bible_r8.md` and the canonical table in `contrib/opus/briefs/lore_rollout_2026-10-27.md`. This file supersedes `rename_map.md` (Oct 26): its inventory of where strings live was reused, its new names were not (Brand, Flux, Verdict arc, Chord lance, Deathless Court, writ/warrant/edict, the Court words and others are all retired).

**Read at:** main `00d2b4b` (no covered file changed between `e243729` and `00d2b4b`) (every Where cell below was produced by grepping the exact Old string at that commit; `(not found)` would mean the row is stale). Generated files are not listed and follow by re-export: `godot/rules/data/tables.json`, `godot/campaign/data/campaign_tables.json`, the oracle copies under `godot/*/test/oracle/`, and `voidsworn-3d.html`.

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
| `<h1>Voidsworn</h1>` | `<h1>Embers of the Hollow Sun</h1>` | campaign_meta.js:30; ui3d.js:624 | B | Title screen (browser). G2 landed the Godot title in 49f0d85. |
| `Command a crusade of gothic capital ships through three hostile sectors. Every hull you lose stays lost, and so does its captain.` | Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain. | campaign_meta.js:31; godot/ui/battle/brand.gd:11; godot/ui/campaign/campaign_ui.gd:301 | B, G2, G3 | The tagline (vetoable V1). Any faction can be picked, so it no longer says crusade. |
| `<title>Voidsworn: 3D battle prototype</title>` | `<title>Embers of the Hollow Sun</title>` | head.html:6 | B | Browser tab title. |
| `<span class="t">Voidsworn</span>` | `<span class="t">Embers of the Hollow Sun</span>` | ui3d.js:62 | B | Battle top bar (browser). |
| `<div class="ibox"><h1>Voidsworn</h1>` | `<div class="ibox"><h1>Embers of the Hollow Sun</h1>` | ui3d.js:624 | B | Skirmish setup header (browser). |
| `Voidsworn is a roguelite.` | Embers of the Hollow Sun is a roguelite. | campaign_meta.js:150; godot/ui/campaign/campaign_ui.gd:1008 | B, G3 | How to play, first line. |
| `n:'Voidsworn Crusade'` | n:'Sunward Crusade' | data.js:111 | B | Canonical. |
| `n:'Ashfall Corsairs'` | n:'Ashfall Hullbreakers' | data.js:115 | B | Canonical. |
| `n:'The Ithar'` | n:'The Glasswrights' | data.js:121 | B | Canonical. |
| `n:'The Deathless Dynasty'` | n:'Eclipse' | data.js:124 | B | Canonical, no "the". Watch sentences that put "the" in front of `F.n` (none found in the JS; G1/G3 check theirs). |
| `blurb:'Gothic crusader battleships. Heavy armor, lance batteries and broadsides that hit like a cathedral falling.'` | blurb:'The frontier the Hegemony wrote off, come to stop the Siphoning. Black-iron battleships: heavy armor, lances, and broadsides that hit harder on the move.' | data.js:111 | B | |
| `blurb:'An imperial war-machine of wedge-hulled destroyers. Ion cannons strip shields; carriers launch fighter screens.'` | blurb:'The Registry’s navy: linked crews, wedge hulls and drone escorts. Ion cannons strip shields; carriers launch fighter screens.' | data.js:113 | B | |
| `blurb:'Pirate raiders in stolen hulls. Fast, thin shields, and far too many torpedoes.'` | blurb:'Furred pack hunters in ships that run dark, stripping every wreck. Fast, thin shields, and far too many rockets.' | data.js:116 | B | |
| `blurb:'A hungering bio-swarm. No shields at all, but their flesh knits back together every round.'` | blurb:'A living weapon that ate its makers. No shields at all, but their flesh knits back together every round.' | data.js:119 | B | |
| `blurb:'An ancient, dying elder race. Blindingly fast, heavily shielded, fragile once the shields fall.'` | blurb:'Few, long-lived masters of light and crystal. Blindingly fast, heavily shielded, fragile once the shields fall.' | data.js:122 | B | |
| `blurb:'Machine necropolis-ships. Gauss weapons tear through shields, and wrecks sometimes stand back up.'` | blurb:'Starwright minds in machine bodies, stealing starlight to light a new sun. Null weapons cut through shields and armor, and wrecks rebuild themselves.' | data.js:125 | B | |
| `deathless:'reclamation'` | deathless:'Homecoming' | data.js:271 | B | RUN_WORD (canonical). Shows as "Launch the Homecoming". |
| `WIN_TITLE={voidsworn:'The crusade endures',hegemony:'The Hegemony stands',corsair:'The loot is yours',chorus:'The Chorus swells',ithar:'The Ithar endure',deathless:'The Dynasty rises'}` | WIN_TITLE={voidsworn:'The crusade endures',hegemony:'The Hegemony stands',corsair:'Strongest keeps it',chorus:'The Chorus swells',ithar:'The light is kept',deathless:'Noon returns'} | campaign_meta.js:178 | B | Run-end headline per faction. |

## 2. Cores (was patrons), protocols (was boons), signals (was sigils), sync (was favour)

The words: patron becomes **core**, boon becomes **protocol**, sigil becomes **signal**, favour becomes **sync**. In prose: "a core offers three protocols", "battles carrying a core's signal", "your sync with that core". A core is "it", not "they" or "she".

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Kharon, the Iron Saint'` | n:'K-1 Kharon, the Unbent' | data.js:620 | B | Canonical. |
| `n:'Vyre, the Storm Queen'` | n:'V-2 Vyre, the Storm Queen' | data.js:621 | B | Canonical. |
| `n:'The Hunger Below'` | n:'H-3 Crucible, "the Hunger Below"' | data.js:622 | B | Canonical. |
| `short:'The Hunger'` | short:'Crucible' | data.js:622 | B | |
| `n:'Astra, the Silent Star'` | n:'A-4 Astra, the Silent Star' | data.js:623 | B | Canonical. |
| `n:'Rook, the Breaker'` | n:'R-5 Rook, the Breaker' | data.js:624 | B | Canonical. |
| `n:'The Ember Choir'` | n:'S-6 Seren, the Last Flame' | data.js:625 | B | Canonical. |
| `short:'The Choir'` | short:'Seren' | data.js:625 | B | |
| `glyph:'E'` | glyph:'S' | data.js:625 | B | The S-6 badge letter (id `ember` stays). |
| `quote:'Sing, and let the void burn with you.'` | quote:'Burn, and let the dark burn with you.' | data.js:625 | B | No faction sings. |
| `FAVOUR_TIERS=[{at:0,n:'Watching'},{at:4,n:'Favoured',d:'Their boons are rare more often.'},{at:12,n:'Devoted',d:'If they watch your run, you start with one of their boons.'},{at:25,n:'Chosen',d:'Their boons are never common.'}]` | FAVOUR_TIERS=[{at:0,n:'Listening'},{at:4,n:'Partial sync',d:'Its protocols are rare more often.'},{at:12,n:'Synced',d:'If it is in range of your run, you start with one of its protocols.'},{at:25,n:'Full sync',d:'Its protocols are never common.'}] | data.js:588 | B | Sync tiers (vetoable V9). Constant name stays. |
| `n:"Saint's Plating"` | n:'Unbent Plating' | data.js:631 | B | Protocol name. |
| `n:'Choir Warheads'` | n:'Incendiary Warheads' | data.js:659 | B | |
| `n:'Hymn of Reloading'` | n:'Hot Tubes' | data.js:660 | B | |
| `n:'Brood Tithe'` | n:'Brood Harvest' | data.js:677 | B | Tithe is a church word. |
| `d_bastion:{duo:['iron','storm'],n:'Bastion'` | d_bastion:{duo:['iron','storm'],n:'Fortress' | data.js:666 | B | Bastion is now the Crusade battleship class (one name, one owner). |
| `'Boon of '+PATRONS[rw.p].short` | 'Signal of '+PATRONS[rw.p].short | campaign_run.js:18 | B | Map badge label. |
| `"Boon of " + str(C.PATRONS[rw["p"]]["short"])` | "Signal of " + str(C.PATRONS[rw["p"]]["short"]) | godot/ui/campaign/campaign_ui.gd:582 | G3 | Same, Godot. |
| `<h3>Boons</h3>` | `<h3>Protocols</h3>` | campaign_run.js:66 | B | Map sidebar. |
| `None yet. Win at a node with a patron’s sigil to earn one.` | None yet. Win at a node carrying a core’s signal to earn one. | campaign_run.js:66 | B | |
| `Patrons this run: ` | Cores in range: | campaign_run.js:67 | B | |
| `boon:'A boon is a bonus from a patron that lasts for the rest of this run. Rarity sets how strong it is.'` | boon:'A protocol is a bonus from a core that lasts for the rest of this run. Rarity sets how strong it is.' | campaign_run.js:391 | B | Reward definition line (key `boon` stays). |
| ` offers a boon</button>` | ` offers a protocol</button>` | campaign_run.js:418 | B | Reward button. |
| `" offers a boon"` | " offers a protocol" | godot/ui/campaign/campaign_ui.gd:1165 | G3 | Godot. |
| `Boons in action: ` | Protocols in action: | campaign_run.js:421 | B | |
| `No boon triggered this battle. Check the Fleet boons section on a ship to see what sets each one off.` | No protocol triggered this battle. Check the Fleet protocols section on a ship to see what sets each one off. | campaign_run.js:421; godot/ui/campaign/campaign_ui.gd:1159 | B, G3 | |
| `<h4>Fleet boons</h4>` | `<h4>Fleet protocols</h4>` | ui3d.js:150 | B | Ship panel (browser). |
| `"Fleet boons"` | "Fleet protocols" | godot/scenes/battle/battle.gd:2956 | G2 | Ship panel (Godot battle). |
| ` Boons active: ` | ` Protocols active: ` | campaign3d.js:58 | B | campaign3d tooltip. |
| `"Take boon"` | "Take protocol" | godot/main/campaign_fallback_ui.gd:12 | G2 | Fallback UI button. |
| `who counts you Devoted: <b>` | now Synced with you: <b> | campaign_meta.js:105 | B | Reads "A gift from K-1 Kharon, the Unbent, now Synced with you: Thunder Broadside." |
| `", who counts you Devoted: [b]"` | ", now Synced with you: [b]" | godot/ui/campaign/campaign_ui.gd:435 | G3 | Godot copy. |
| `Patrons watching this ${runWord()}: ` | Cores in range of this ${runWord()}: | campaign_meta.js:106 | B | Aspect screen. |
| `. Win battles marked with their sigil to earn their boons.` | . Win battles carrying their signal to earn their protocols. | campaign_meta.js:106; godot/ui/campaign/campaign_ui.gd:442 | B, G3 | Aspect screen (both games). |
| `"Patrons watching this "` | "Cores in range of this " | godot/ui/campaign/campaign_ui.gd:442 | G3 | Godot. |
| `Long-range auspex confirms` | Long-range scans confirm | campaign_meta.js:112; godot/ui/campaign/campaign_ui.gd:1114 | B, G3 | Sector I intro (both games). |
| `Battles marked with a patron’s sigil pay out that patron’s boons, so the route you choose shapes your build.` | Battles carrying a core’s signal pay out that core’s protocols, so the route you choose shapes your build. | campaign_meta.js:113; godot/ui/campaign/campaign_ui.gd:1125 | B, G3 | Sector I intro (both games). |
| `['favour','Patron favour']` | ['favour','Core sync'] | campaign_meta.js:120 | B | Progression tab label (id `favour` stays). |
| `"Patron favour"` | "Core sync" | godot/ui/campaign/campaign_ui.gd:937 | G3 | Godot tab label. |
| `Every boon you take raises that patron's favour (rare boons count double, epic triple).` | Every protocol you take raises your sync with that core (rare protocols count double, epic triple). | campaign_meta.js:127; godot/ui/campaign/campaign_ui.gd:976 | B, G3 | Both games. |
| `<b>patrons</b> grow fond of you as you take their boons, offering rarer boons and eventually a gift at the start of a run` | <b>cores</b> sync with you as you take their protocols, offering rarer protocols and eventually a gift at the start of a run | campaign_meta.js:151 | B | How to play (browser; Godot copy in 9.2). |
| `Patrons, boons and your flagship` | Cores, protocols and your flagship | campaign_meta.js:166; godot/ui/campaign/campaign_ui.gd:1019 | B, G3 | How to play header (both). |
| `Each run, four of six patrons watch your run. Battles on the map carry a patron’s sigil: win there and that patron offers three boons, and you take one. Boons change the rules` | Each run, four of the six cores are in range. Battles on the map carry a core’s signal: win there and that core offers three protocols, and you take one. Protocols change the rules | campaign_meta.js:167; godot/ui/campaign/campaign_ui.gd:1019 | B, G3 | How to play (browser). |
| `Each run, four of six patrons watch your run. Battles on the map carry a patron’s sigil: win there and that patron offers three boons, and you take one. Boons change the rules` | Each run, four of the six cores are in range. Battles on the map carry a core’s signal: win there and that core offers three protocols, and you take one. Protocols change the rules | campaign_meta.js:167; godot/ui/campaign/campaign_ui.gd:1019 | B, G3 | How to play (Godot). |
| `Hold boons from two patrons and a duo boon can appear.` | Hold protocols from two cores and a duo protocol can appear. | campaign_meta.js:167; godot/ui/campaign/campaign_ui.gd:1019 | B, G3 | Both. |
| `without boons.` | without protocols. | campaign_meta.js:165; godot/ui/campaign/campaign_ui.gd:1018 | B, G3 | Ram rule in How to play (both). |
| `const TERMS := {"patron": "patron", "patrons": "patrons", "sigil": "sigil", "boon": "boon", "boons": "boons", "favour": "favour"}` | const TERMS := {"patron": "core", "patrons": "cores", "sigil": "signal", "boon": "protocol", "boons": "protocols", "favour": "sync"} | godot/ui/campaign/campaign_ui.gd:29 | G3 | G3's one-edit switch for the map screen. Check each `term(...)` sentence still reads ("Cores watching" becomes "Cores in range": see 10.2). |
| `(repair stops count in its favour)` | (repair stops count toward it) | godot/ui/campaign/map3d.gd:812 | G3 | Ordinary word, but "favour" is retired from display text. |

## 3. Weapons

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Macro battery'` | n:'Gun battery' | data.js:5 | B | Generic name (shown on variant cards and anywhere a faction has no override). Battlefleet Gothic word. |
| `n:'Heavy macro battery'` | n:'Heavy gun battery' | data.js:6 | B | |
| `turbo:{n:'Turbolaser'` | turbo:{n:'Pulse laser' | data.js:11 | B | Canonical. Hegemony still shows its own override, Plasma lance. |
| `hturbo:{n:'Heavy turbolaser'` | hturbo:{n:'Heavy pulse laser' | data.js:12 | B | Canonical. |
| `bioplasma:{n:'Bio-plasma'` | bioplasma:{n:'Bile spray' | data.js:17 | B | Generic; Chorus shows Spine volley. |
| `spores:{n:'Spore mines'` | spores:{n:'Spore drifts' | data.js:18 | B | Bible Chorus weapon. |
| `pulsar:{n:'Pulsar lance'` | pulsar:{n:'Prism lance' | data.js:19 | B | Canonical. |
| `gauss:{n:'Gauss flayer'` | gauss:{n:'Null cannon' | data.js:21 | B | Canonical. |
| `gsentry:{n:'Gauss sentries'` | gsentry:{n:'Null sentries' | data.js:22 | B | Canonical. |
| `doom:{n:'Doom arc'` | doom:{n:'Corona arc' | data.js:23 | B | Canonical. |
| `shard:{n:'Shuriken cannon'` | shard:{n:'Shard cannon' | data.js:24 | B | Bible Glasswright weapon. |
| `gauss:'Gauss',sq:'Squadron'` | gauss:'Null',sq:'Squadron' | data.js:30 | B | KIND_NAME weapon kind label (canonical). |
| `autocannon:'Las-repeater',battery:'Las-battery',hbattery:'Heavy las-broadside',turret:'Las-turret',lance:'Penance lance',torp:'Hellfire torpedo',flak:'Censer flak'` | autocannon:'Sear repeater',battery:'Sear battery',hbattery:'Heavy sear broadside',turret:'Sear turret',lance:'Oath lance',torp:'Cinder torpedo',flak:'Spark flak' | data.js:35 | B | Crusade names, all from the bible (2.11). |
| `pulsar:'Pulsar lance',startorp` | pulsar:'Prism lance',startorp | data.js:39 | B | Glasswright override. |
| `deathless:{gauss:'Gauss flayer',doom:'Doom arc',gsentry:'Gauss pylon',flak:'Gauss shredder'}` | deathless:{gauss:'Null cannon',doom:'Corona arc',gsentry:'Null spire',flak:'Null shredder'} | data.js:40 | B | Canonical. |
| `flay:{w:'flayed by gauss fire'` | flay:{w:'unmade by null fire' | battle.js:925 | B | Kill cause (id `flay` stays). |
| `n:'Nova cannon'` | n:'Spinal cannon' | data.js:136 | B | Ability shared by three flagships; Nova Cannon is Battlefleet Gothic's prow gun. Vetoable V12. |
| `<div class="h">Nova impact</div>` | `<div class="h">Spinal shell impact</div>` | ui3d.js:449 | B | Targeting tooltip. |
| `Nova blast hits ` | Spinal shell hits | battle.js:1211; godot/rules/rules.gd:3530 | B, G1 | Battle log (both games). |

## 4. Hulls, classes, drives and abilities

**4.0 Class display map (new, B adds; G1 and G3 read it from the tables).** Add to data.js, next to HULLS: `const CLS_NAME={'Battle-barge':'War-barge','Bio-titan':'Colossus','Ark':'Lattice-ship','Tomb-ark':'Archive-ship'}; function clsName(c){ return CLS_NAME[c]||c; }` and use `clsName(...)` wherever a class is shown: ui3d.js:107 (`u.cls`), campaign_run.js:45, :189 (group label only, not the grouping key), :473; Godot hud.gd:384, :448, battle.gd ship panel lines that print `cls`, campaign_ui.gd:631, :1198, map3d.gd tooltips. The `cls` values themselves stay (they key ship models, sizes and fx).

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Penitent-class cruiser'` | n:'Vigil-class cruiser' | data.js:63 | B | Canonical. |
| `n:'Reliquary-class carrier'` | n:'Hearth-class carrier' | data.js:64 | B | Canonical. |
| `n:'Cathedral-class battleship'` | n:'Bastion-class battleship' | data.js:65 | B | Canonical. |
| `n:'Ascendant-class dreadnought'` | n:'Daybreak-class dreadnought' | data.js:66 | B | Canonical. |
| `n:'Interdictor destroyer'` | n:'Cordon destroyer' | data.js:73 | B | Canonical. |
| `n:'Vanguard star cruiser'` | n:'Vanguard cruiser' | data.js:74 | B | "Star cruiser" is a Star Wars class word. |
| `n:'Dominion star dreadnought'` | n:'Dominion dreadnought' | data.js:75 | B | Same. |
| `n:'Corsair raider'` | n:'Hullbreaker raider' | data.js:78 | B | Canonical. |
| `n:'Corsair reaver'` | n:'Hullbreaker gutship' | data.js:79 | B | Canonical. |
| `n:'Corsair marauder'` | n:'Hullbreaker wrecker' | data.js:80 | B | Canonical. |
| `n:'Corsair hulk-carrier'` | n:'Hullbreaker hulk-carrier' | data.js:81 | B | Canonical. |
| `cls:'Battle-barge'` | (stays; shows as War-barge via 4.0) | data.js:82 | B | Name `Warlord's Pyre-Barge` kept (canonical). |
| `n:'Chorus razorfiend'` | n:'Chorus bladeback' | data.js:86 | B | Canonical. |
| `n:'Chorus brood-mother'` | n:'Chorus brood-sac' | data.js:87 | B | Canonical. |
| `n:'Hive Leviathan'` | n:'The Ninefold Maw' | data.js:88 | B | Canonical; class shows as Colossus via 4.0. |
| `n:'Ithar wisp'` | n:'Glasswright sliver' | data.js:90 | B | Canonical. |
| `n:'Ithar shadowblade'` | n:'Glasswright lancet' | data.js:91 | B | Canonical. |
| `n:'Ithar songship'` | n:'Glasswright prism' | data.js:92 | B | Canonical. |
| `n:'Ithar wraithcarrier'` | n:'Glasswright aperture' | data.js:93 | B | Canonical. |
| `n:'Worldsong Ark'` | n:'The Unfinished' | data.js:94 | B | Canonical; class shows as Lattice-ship via 4.0 (vetoable V3). |
| `n:'Deathless scythe'` | n:'Eclipse mote' | data.js:96 | B | Canonical. |
| `n:'Deathless jackal'` | n:'Eclipse flare' | data.js:97 | B | Canonical. |
| `n:'Deathless harvester'` | n:'Eclipse zenith' | data.js:98 | B | Canonical. |
| `n:'The Undying Throne'` | n:'The Unsetting' | data.js:99 | B | Canonical; class shows as Archive-ship via 4.0. |
| `n:'Fan sails'` | n:'Crystal vanes' | data.js:108 | B | Glasswright drive rule (bible 6.3: vanes, not sails). |
| `n:'Phase drive'` | n:'Fold drive' | data.js:109 | B | Eclipse drive rule (bible 7.3, 7.5). |
| `phase:{n:'Dimensional shift'` | phase:{n:'Fold skip' | data.js:143 | B | Eclipse ability, matches the fold drive. |
| `reclaim:{n:'Reanimation beam'` | reclaim:{n:'Repair swarm' | data.js:144 | B | Bible 7.5: repair swarms. |
| `' reanimates '` | ' rebuilds ' | battle.js:1189 | B | Battle log for the repair swarm (both games). |
| `" reanimates "` | " rebuilds " | godot/rules/rules.gd:3477 | G1 | Godot copy. |
| `'Reanimating'` | 'Rebuilding' | battle.js:938 | B | Floating text. |
| `"Reanimating"` | "Rebuilding" | godot/rules/rules.gd:2736 | G1 | Godot copy. |
| `'Reawakens'` | 'Restarts' | battle.js:936 | B | Floating text for the revive relic. |
| `"Reawakens"` | "Restarts" | godot/rules/rules.gd:2733 | G1 | Godot copy. |
| `The phylactery hums. ${t.name} reawakens at 25% hull.` | Second ignition. ${t.name} restarts at 25% hull. | battle.js:936 | B | Revive relic log. |
| `logm("The phylactery hums. " + String(t["name"]) + " reawakens at 25% hull.", "s")` | logm("Second ignition. " + String(t["name"]) + " restarts at 25% hull.", "s") | godot/rules/rules.gd:2733 | G1 | Godot copy. |
| `deathless:{n:'Endless legion',d:` | deathless:{n:'Archive restore',d: | battle.js:480 | B | Eclipse faction rule name (battle.js FACTION_RULES). |
| `The first Deathless ship to fall each battle` | The first Eclipse ship to fall each battle | battle.js:480 | B | Same rule text. |
| `'Endless legion: the first to fall reassembles next round.':'Endless legion spent.'` | 'Archive restore: the first to fall reassembles next round.':'Archive restore spent.' | battle.js:526 | B | Ship panel. |
| `"Endless legion: the first to fall reassembles next round."` | "Archive restore: the first to fall reassembles next round." | godot/scenes/battle/battle.gd:2884 | G2 | Godot ship panel; also its "Endless legion spent." on the same line becomes "Archive restore spent." |
| `Ithar hulls cannot Brace.` | Glasswright hulls cannot Brace. | battle.js:478 | B | Glasswright rule text. |
| `corsair:{n:'Close in',d:'Corsairs field no lance weapons` | corsair:{n:'Close in',d:'Hullbreakers field no lance weapons | battle.js:481 | B | |
| `d:'Corsairs field no lance weapons (no long-range beams): they win up close.'` | d:'Hullbreakers field no lance weapons (no long-range beams): they win up close.' | data.js:539 | B | FAC_GATES. |
| `d:'Ithar hulls cannot Brace for impact: they live by shields and speed.'` | d:'Glasswright hulls cannot Brace for impact: they live by shields and speed.' | data.js:539 | B | FAC_GATES. |
| `hegemony:{id:'barrage',n:'Imperial broadside'}` | hegemony:{id:'barrage',n:'Registry broadside'} | battle.js:1109 | B | Enemy flagship Command. |
| `chorus:{id:'restore',n:'Hive regrowth'}` | chorus:{id:'restore',n:'Brood regrowth'} | battle.js:1109 | B | Hive is a Tyranid word. |
| `deathless:{id:'restore',n:'Rise again'}` | deathless:{id:'restore',n:'Restore from the Archive'} | battle.js:1109 | B | |
| `deadstar:'Dead star'` | deadstar:'Hollow Sun' | battle.js:18 | B | Battle shape label (canonical: the black hole is the Hollow Sun; vetoable V13). |
| `['deadstar','Dead star']` | ['deadstar','Hollow Sun'] | ui3d.js:15 | B | Skirmish shape picker. |
| ` is torn apart by the dead star's gravity.` | ` is torn apart by the Hollow Sun's gravity.` | battle.js:283; godot/rules/rules.gd:969 | B, G1 | Battle log (both games). |
| `tidal:{w:'torn apart by the dead star'` | tidal:{w:'torn apart by the Hollow Sun' | battle.js:925 | B | Kill cause. |
| `A dead star warps this field.` | The Hollow Sun warps this field. | battle.js:355; godot/scenes/battle/battle.gd:475; godot/rules/rules.gd:1257 | B, G2, G1 | Battle start log (both games, three places). |
| `colossus:'Colossus'` | colossus:'Giant wreck' | battle.js:18 | B | Battle shape label; Colossus is now the Ninefold Maw's class (one name, one owner). |
| `shoals:'Shoals'` | shoals:'Rock shoals' | battle.js:18 | B | Optional, sea word softened (vetoable V13). |
| ` on the auspex.` | ` on the scanners.` | battle.js:354; godot/story/data/voices.json:76; godot/scenes/battle/battle.gd:472; godot/rules/rules.gd:1256 | B, L, G2, G1 | Battle start log (both games). |
| `will drop out of warp at the start of round {r}` | will jump in at the start of round {r} | battle.js:23 | B | Battle event warning. |
| `go:'Enemy reinforcements drop out of warp.'` | go:'Enemy reinforcements jump in.' | battle.js:23 | B | |
| `A friendly ship drops out of warp to help.` | A friendly ship jumps in to help. | battle.js:24 | B | |

## 5. Refits (modules), relics, perks

Generic MODULES and RELICS show for the Sunward Crusade (it has no MOD_NAMES or RELIC_NAMES row) and for any faction gap, so they are written in the Crusade's voice where a word is needed.

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `auspex:{n:'Auspex array'` | auspex:{n:'Scanner array' | data.js:153 | B | Bible 1.2: scanners. (Not "Vigil": that is now a hull class.) |
| `capacitor:{n:'Void shield capacitor'` | capacitor:{n:'Screen capacitor' | data.js:156 | B | Bible 1.2: the Crusade calls shields screens. |
| `loaders:{n:'Macro loaders'` | loaders:{n:'Battery loaders' | data.js:158 | B | |
| `cogitator:{n:'Targeting cogitator'` | cogitator:{n:'Targeting reckoner' | data.js:164 | B | Bible 1.2: reckoner. |
| `deflector:{n:'Deflector savant'` | deflector:{n:'Shield savant' | data.js:170 | B | Deflector is the Hegemony's word; perks are for everyone. |
| `lanceadept:{n:'Lance adept'` | lanceadept:{n:'Lance savant' | data.js:175 | B | Adept is the Adeptus word. |
| `martyr:{n:'Reliquary of the Martyr'` | martyr:{n:'The Chalked Roll' | data.js:187 | B | Crusade relic (names chalked on the hull). |
| `cogitator:{n:'Archeotech rangefinder'` | cogitator:{n:'Founders’ rangefinder' | data.js:188 | B | Bible 1.2: founders' tech. |
| `lattice:{n:'Xeno shield lattice'` | lattice:{n:'Alien shield matrix' | data.js:189 | B | "Lattice" is now the Starwright megastructure only. |
| `phylactery:{n:'Deathless phylactery'` | phylactery:{n:'Eclipse backup frame' | data.js:191 | B | Generic name; Eclipse's own is Second Ignition. |
| `compass:{n:'Wraithbone compass'` | compass:{n:'Founders’ compass' | data.js:193 | B | |
| `coils:{n:'Blessed plasma coils'` | coils:{n:'Hand-wound plasma coils' | data.js:196 | B | No blessings; the Crusade does it by hand. |
| `loaders:'Turbolaser cyclers'` | loaders:'Pulse cyclers' | data.js:259 | B | Hegemony refit. |
| `magazine:'Proton magazine'` | magazine:'Fusion magazine' | data.js:259 | B | Star Wars proton torpedoes. |
| `magazine:'Extra torpedo racks'` | magazine:'Extra rocket racks' | data.js:260 | B | Hullbreakers fire rockets. |
| `auspex:'Hunting eyes'` | auspex:'Tasting pores' | data.js:261 | B | The Chorus has no eyes (bible 5.3). Also in NEM_ADAPT_FAC (6.x). |
| `prow:'Wraithbone keel',auspex:'Farsight crystal',drive:'Solar sail extension'` | prow:'Waveguide spine',auspex:'Interferometer lens',drive:'Solar vane extension' | data.js:262 | B | Bible 6.10 refits. |
| `regen:'Dawnlight lattice',loaders:'Shuriken feeders'` | regen:'Stored-light reservoir',loaders:'Shard hoppers' | data.js:262 | B | Dawn is the Crusade's motif; Lattice is taken. |
| `damcon:'Song of mending'` | damcon:'Annealing kilns' | data.js:262 | B | No faction sings. |
| `cogitator:'Seer’s sight'` | cogitator:'Clear eye' | data.js:262 | B | Bible 6.10. |
| `deathless:{prow:'Living-metal plating',auspex:'Tomb sight',drive:'Inertialess drive',gyro:'Gravitic vanes',capacitor:'Quantum shield node',regen:'Quantum regenerator',loaders:'Gauss accelerators',crystal:'Doom-arc focus',magazine:'Arc capacitors',flakplus:'Sentry nodes',damcon:'Repair scarabs',hangar:'Scarab hive',cogitator:'Calculus lattice'}` | deathless:{prow:'Sunshade plating',auspex:'Long-memory sight',drive:'Fold engine',gyro:'Gravitic stabilisers',capacitor:'Corona-ward node',regen:'Corona-ward regenerator',loaders:'Null accelerators',crystal:'Corona-arc focus',magazine:'Arc capacitors',flakplus:'Sentry nodes',damcon:'Repair drones',hangar:'Drone bay',cogitator:'Long-count reckoner'} | data.js:263 | B | Eclipse refits, bible 7.10 where it names one. |
| `cogitator:'Imperial targeting array'` | cogitator:'Registry targeting array' | data.js:265 | B | |
| `compass:'Hyperdrive motivator'` | compass:'Jump-drive regulator' | data.js:265 | B | Star Wars line. |
| `armourweave:'Durasteel weave'` | armourweave:'Hardsteel weave' | data.js:265 | B | Star Wars material. |
| `martyr:'Captain’s lucky skull'` | martyr:'Dead captain’s harness' | data.js:266 | B | Hullbreaker trophies are machines and plates, never skulls (bible 4.3). |
| `lattice:'Ithar shield shard'` | lattice:'Glasswright shield shard' | data.js:266 | B | |
| `compass:'Wraithbone compass',banner:'Trophy war banner'` | compass:'Wake-tracker',banner:'Trophy war banner' | data.js:266 | B | Bible 4.1: wake-trackers. |
| `logbook:'Pirate king’s logbook'` | logbook:'Warlord’s kill tally' | data.js:266 | B | |
| `cogitator:'Compound eye cluster',lattice:'Stolen shield lattice'` | cogitator:'Heat-tasting pits',lattice:'Swallowed shield cells' | data.js:267 | B | No eyes; Lattice taken. |
| `logbook:'Memory of the hive'` | logbook:'Taste of old prey' | data.js:267 | B | Hive; Memory belongs to story and dialogue only (bible 1.3). |
| `cogitator:'Seer’s eye',lattice:'Prism lattice'` | cogitator:'Ancestral lens',lattice:'Prism matrix' | data.js:268 | B | |
| `banner:'Banner of the lost world'` | banner:'Banner of Ardent' | data.js:268 | B | |
| `martyr:'Crown of the first dynasty'` | martyr:'Last image of Ardent' | data.js:269 | B | Bible 7.8 ritual. |
| `phylactery:'Phylactery of the Undying'` | phylactery:'Second Ignition' | data.js:269 | B | Bible 7.10. |
| `ledger:'Tithe ledger'` | ledger:'Siphon ledger' | data.js:269 | B | |
| `salvage:'Harvest engine',coils:'Chronometron',logbook:'Annals of the dynasty',armourweave:'Living-metal weave'` | salvage:'Salvage swarm',coils:'Long clock',logbook:'The Archive',armourweave:'Sunshade weave' | data.js:269 | B | |
| `salvagers:{n:'Salvage protocols'` | salvagers:{n:'Salvage crews' | data.js:249 | B | "Protocol" now belongs to the cores. |
| `d:'Voidsworn fleets may take one Ascendant-class dreadnought.'` | d:'Sunward Crusade fleets may take one Daybreak-class dreadnought.' | data.js:240 | B | Legacy unlock. |
| `n:'Aspect of the Hive'` | n:'Aspect of the Brood' | data.js:691 | B | Hive. |

## 6. Admirals and Commands

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Admiral Castellan Vex'` | n:'Admiral Roderic Vex' | data.js:203 | B | Castellan is a 40k rank; every Crusade admiral is rank, given name, surname (vetoable V4). |
| `n:'Inquisitor-Captain Malek Draven'` | n:'Oath-Captain Malek Draven' | data.js:204 | B | Canonical. |
| `n:'Grand Admiral Ilsa Kassar'` | n:'First Admiral Ilsa Kassar' | data.js:215 | B | Canonical rank. |
| `star cruisers hold +1 wing` | cruisers hold +1 wing | data.js:217 | B | Reyes's doctrine text. |
| `n:'Shield wall protocol'` | n:'Shield wall order' | data.js:218 | B | Maren's Command; "protocol" belongs to the cores. |
| `n:'Warlord Grax Ironjaw'` | n:'Warlord Grax Steelgrin' | data.js:219 | B | Bible 4.9 example; Ironjawz is Age of Sigmar. |
| `n:'Sable Venn, the Smiling Knife'` | n:'Sable the Smiling Knife' | data.js:220 | B | No human surnames; a sable is a furred hunter, so the name stays (vetoable V5). |
| `n:'Old Mott Brannigan'` | n:'Old Mott' | data.js:221 | B | No surname (Brannigan is Futurama). |
| `n:'Patch and pray'` | n:'Patch and weld' | data.js:222 | B | Vesh's Command; no prayer. |
| `n:'The Mending Choir'` | n:'The Mending Throng' | data.js:225 | B | Bible 5.3. |
| `doc:'Acid chorus'` | doc:'Acid tide' | data.js:226 | B | Read as music. |
| `n:'Discordant volley'` | n:'Spitting volley' | data.js:226 | B | Music word. |
| `n:'Aelith Dawnsail'` | n:'Tamsa of the Clear Aperture' | data.js:227 | B | Glasswright name plus optical family line (bible 6.9); carrier admiral, aperture is the carrier class (vetoable V6). |
| `n:'Seraph Vaelen',doc:'Lance choir'` | n:'Saro of Long Focus',doc:'Focused lances' | data.js:228 | B | Lance admiral. |
| `n:'Chord of light'` | n:'Burning glass' | data.js:228 | B | Saro's Command. |
| `n:'Thorne of the Veil',doc:'Veil tactics'` | n:'Vell of the Third Mirror',doc:'Refraction tactics' | data.js:229 | B | Evasion admiral. |
| `n:'Phase drift',d:'Every ship gains` | n:'Scatter the light',d:'Every ship gains | data.js:229 | B | Vell's Command (Phase drift was also an Eclipse adaptation name). |
| `n:'Mirelle Starwarden'` | n:'Brin of the Fourth Lens' | data.js:230 | B | Shield admiral. |
| `n:'Overlord Nekhet the Undying',doc:'Eternal legion'` | n:'Nadir Aurex, Ninth Frame',doc:'Endless restoration' | data.js:231 | B | Canonical name. Nekhet is the regrowth admiral whose portrait is the broken ring mind, which the bible gives to Aurex (vetoable V7). |
| `n:'Reanimation protocol'` | n:'Release the repair swarms' | data.js:231 | B | Aurex's Command. |
| `n:'Sekhmar the Reaper',doc:'Reaping arcs',d:'Doom arcs deal +20% damage` | n:'Umbra Vessane, Third-Housed',doc:'Corona strikes',d:'Corona arcs deal +20% damage | data.js:232 | B | Canonical name; the offence admiral. |
| `n:'Harvest of souls'` | n:'Noon volley' | data.js:232 | B | Vessane's Command ("We remember noon"). |
| `n:'Cryptlord Anuket',doc:'Silent hunters'` | n:'Ostrel of the Long Copy',doc:'Silent hunters' | data.js:233 | B | Canonical name; the patient flanker. |
| `n:'Tomb-blade strike'` | n:'Out of the shadow' | data.js:233 | B | Ostrel's Command. |
| `n:'Khepra the Patient',doc:'Living stone'` | n:'Seveth, Twice-Restored',doc:'Layered plates' | data.js:234 | B | Canonical name; the durable admiral (twice restored). |
| `cmd:{id:'iron',n:'Living stone'` | cmd:{id:'iron',n:'Sunshade wall' | data.js:234 | B | Seveth's Command. |

## 7. Events, faction verbs, event results

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `b:'Your auspex finds an ancient gothic warship drifting without power, its hull etched with prayers no one has spoken in ten thousand years.'` | b:'Your scanners find an ancient warship drifting without power, its hull etched with Starwright script no one has read in a thousand years.' | data.js:274 | B | |
| `s:'Risky. Could hold archeotech, could hold something awake.'` | s:'Risky. Could hold founders’ tech, could hold something awake.' | data.js:275 | B | |
| `l:'Leave it to its prayers'` | l:'Leave it to the dark' | data.js:277 | B | |
| `s:'A clean cut: archeotech and salvage, nothing wakes.'` | s:'A clean cut: founders’ tech and salvage, nothing wakes.' | data.js:320 | B | |
| `owes you a favour` | owes you one | data.js:322 | B | "Their captain pays well and owes you one: ..." |
| `t:'The astropath’s vision',b:'Your fleet astropath wakes screaming. She has seen where a relic lies, but reaching it means sailing through a warp-rift.'` | t:'A signal in the static',b:'Your signals officer has pulled an old founders’ beacon out of the static. A relic lies beyond it, but reaching it means crossing a rift.' | data.js:282 | B | Event id `astropath` stays. No psychics (bible 1.2). |
| `b:'Your sensor officer has decoded a ghost signal: an old Navy relic cache, deep inside a hyperspace rift.'` | b:'Your sensor officer has decoded a ghost signal: an old Navy relic cache, deep inside a rift.' | data.js:282 | B | Hegemony variant. |
| `corsair:{t:'The navigator’s hunch',b:'Your half-mad navigator swears she can smell treasure on the far side of a rift. She is usually right. Usually.'}` | corsair:{t:'The tracker’s nose',b:'Your best tracker swears she can smell old metal on the far side of a rift. She is usually right. Usually.'} | data.js:282 | B | Hullbreakers hunt by scent and sound. |
| `chorus:{t:'A scent in the void',b:'The brood-mind tastes something ancient and delicious beyond a rift in space.'}` | chorus:{t:'A scent in the dark',b:'The swarm tastes something old and delicious beyond a rift.'} | data.js:282 | B | |
| `ithar:{t:'A seer’s dream',b:'Your seer dreams of a lost treasure of your people, sleeping beyond a rift.'}` | ithar:{t:'A glint beyond the rift',b:'Your mirrors catch a glint of old Starwright glass beyond a rift: a lost treasure of your people.'} | data.js:282 | B | |
| `deathless:{t:'A dynastic beacon',b:'An old dynastic beacon pulses from beyond a rift. Something of the dynasty is still out there.'}` | deathless:{t:'An Archive beacon',b:'An Archive beacon from before the collapse pulses beyond a rift. Something of Ardent is still out there.'} | data.js:282 | B | |
| `t:'Warp storm'` | t:'Rift storm' | data.js:288 | B | |
| `t:'An Ithar seer',b:'A lone Ithar vessel matches your course. Its seer offers a trade: one of your refits for one of their treasures.'` | t:'A Glasswright wanderer',b:'A lone Glasswright vessel matches your course. Its keeper offers a trade: one of your refits for one of their treasures.' | data.js:291 | B | Event id `seer` stays. |
| `l:'Sing back to her',s:'She trades a relic for a song. No refit lost.'` | l:'Answer her tone in glass',s:'She trades a relic for the courtesy. No refit lost.' | data.js:325 | B | Option key `song` stays (Glasswright-only blue option). |
| `The seer smiles and gives anyway.` | The keeper smiles and gives anyway. | campaign_run.js:355; godot/campaign/campaign.gd:1920 | B, G3 | Event result (both games). |
| `t:'A void-shrine',b:'An orbital shrine to a forgotten saint hangs over a dead world. Your crews ask to make an offering.'` | t:'A wall of names',b:'A memorial station hangs over a dead world, its walls chalked with the names of a crusade that never came home. Your crews ask to leave an offering.' | data.js:300 | B | Faction-power string (vetoable V10). Event id `shrine` stays. |
| `hegemony:{b:'An old orbital shrine hangs over a dead world. Spacers are a superstitious lot, and your crews ask to leave an offering.'}` | hegemony:{b:'An old memorial station hangs over a dead world. Spacers are a superstitious lot, and your crews ask to leave an offering.'} | data.js:300 | B | |
| `corsair:{b:'An orbital shrine to some forgotten saint hangs over a dead world. Even pirates hedge their bets: your crews ask to leave an offering.'}` | corsair:{b:'An old memorial station hangs over a dead world, heaped with other packs’ trophies. Your crews want to leave one of their own.'} | data.js:300 | B | |
| `ithar:{t:'A shrine of the old world',b:'A shrine from before your people’s fall hangs over a dead world. Your crews ask to leave an offering.'}` | ithar:{t:'A mirror of the old world',b:'A mirror array from before your people’s fall still turns over a dead world. Your crews ask to leave an offering.'} | data.js:300 | B | |
| `l:'Pray and hope'` | l:'Chalk your names and hope' | data.js:302 | B | |
| `The saint answers. Every ship repairs 30% of its hull.` | Luck holds. Every ship repairs 30% of its hull. | campaign_run.js:362; godot/campaign/campaign.gd:1952 | B, G3 | Event result (both games). |
| `b:'A lifeboat of Hegemony officers begs for asylum.` | b:'An escape pod of Hegemony officers begs for asylum. | data.js:304 | B | Lifeboat is a sea word. |
| `b:'A corsair cache hidden in the rings of a gas giant.` | b:'A Hullbreaker cache hidden in the rings of a gas giant. | data.js:307 | B | |
| `t:'The tithe vault',b:'An abandoned tithe station` | t:'The toll vault',b:'An abandoned toll station | data.js:333 | B | Tithe is a church word. Event id `tithe` stays. |
| `l:'Let the living metal knit it'` | l:'Let the repair drones knit it' | data.js:344 | B | |
| `t:'A song in the dark',b:'A dying Ithar songship is singing its own lament. The melody carries old star charts in it, for those who can hear.'` | t:'A tone in the dark',b:'A dying Glasswright prism rings with one long clear tone as its light fades. The tone carries old star charts in it, for those who can read it.' | data.js:362 | B | |
| `l:'Join the song'` | l:'Answer the tone' | data.js:364 | B | Faction-power string. |
| `l:'Trade a relic for its archive'` | l:'Trade a relic for its charts' | data.js:365 | B | The archive is Eclipse's word. |
| `t:'A sealed tomb-world',b:'A planet of black glass hums under your keels. Deep below, something counts the seconds until it wakes.'` | t:'A siphon array',b:'A ring of black collectors circles a dimming star, drinking its energy. Something aboard counts the seconds until you come in range.' | data.js:366 | B | Event id `tomb` stays. |
| `l:'Wake it and take what it guards',s:'Fight an elite Deathless battle. Win a relic.'` | l:'Break the array and take what it guards',s:'Fight an elite Eclipse battle. Win a relic.' | data.js:367 | B | |
| `l:'Map it from orbit and leave'` | l:'Chart it and leave' | data.js:368 | B | |
| `t:'A sleeping tomb-world',b:'A tomb-world of your own dynasty, its legions dormant. A word from you would wake one of them.'` | t:'A dormant hull yard',b:'An Eclipse yard from before the collapse drifts in the dark, its hulls stored without minds. A copy from the Archive would wake one of them.' | data.js:369 | B | Event id `tombhome` stays. |
| `l:'Wake one scythe',s:'A Deathless scythe joins the fleet at full hull.'` | l:'Wake one mote',s:'An Eclipse mote joins the fleet at full hull.' | data.js:370 | B | |
| `l:'Take its tithe instead'` | l:'Strip it for parts instead' | data.js:371 | B | |
| `t:'A pirate haven'` | t:'A raider den' | data.js:412 | B | |
| `s:'Fight an elite Corsair battle. Win a relic.'` | s:'Fight an elite Hullbreaker battle. Win a relic.' | data.js:413 | B | |
| `s:'A Corsair raider joins with a veteran captain.'` | s:'A Hullbreaker raider joins with a veteran captain.' | data.js:415 | B | |
| `voidsworn:{id:'vigil',n:'Hold a vigil',` | voidsworn:{id:'vigil',n:'Keep the dawn watch', | data.js:497 | B | Crusade verb (bible 2.9 ritual); Vigil is now a hull class. Id `vigil` stays. |
| `freeD:'free after an offering at a void-shrine'` | freeD:'free after an offering at a wall of names' | data.js:497 | B | Faction-power string. |
| `freeD:'free once you have joined the song'` | freeD:'free once you have answered the tone' | data.js:501 | B | Faction-power string. |
| `deathless:{id:'waken',n:'Waken the legion',d:'Next battle, the endless legion has one more return.'` | deathless:{id:'waken',n:'Back up the fleet',d:'Next battle, Archive restore brings back one more ship.' | data.js:502 | B | Faction-power string. Id `waken` stays. |
| `freeD:'free once a tomb-world has woken for you'` | freeD:'free once a dormant yard has woken a hull for you' | data.js:502 | B | Faction-power string. |
| `(Corsairs) tow a small hull home` | (Hullbreakers) tow a small hull home | campaign_run.js:390 | B | Salvage reward line. |
| `Auspex confirms ` | Scanners confirm | campaign_run.js:540; godot/ui/campaign/campaign_ui.gd:1118 | B, G3 | Sector II and III intro (both games). |
| `"Auspex confirms [b]"` | "Scanners confirm [b]" | godot/ui/campaign/campaign_ui.gd:1118 | G3 | Godot copy. |

## 8. Hull variants and fleet archetypes

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `n:'Penitent gun-cruiser',d:'Swaps the prow lance for a dorsal macro battery: guns in every arc.'` | n:'Vigil gun-cruiser',d:'Swaps the prow lance for a dorsal sear battery: guns in every arc.' | data.js:550 | B | |
| `d:'No hangar; a third turbolaser turret instead.'` | d:'No hangar; a third plasma lance turret instead.' | data.js:552 | B | The Hegemony shows `turbo` as Plasma lance. |
| `n:'Reaver gunboat'` | n:'Turret gutship' | data.js:553 | B | Gunboat is a sea word. |
| `n:'Razorfiend stalker'` | n:'Bladeback stalker' | data.js:556 | B | |
| `n:'Wisp lancer',d:'A pulsar lance in place of the shuriken cannon.'` | n:'Sliver lancer',d:'A prism lance in place of the prism shards.' | data.js:557 | B | |
| `n:'Songship warden'` | n:'Warded prism' | data.js:558 | B | Warden is a Crusade class. |
| `n:'Scythe sentinel',d:'Adds gauss sentries:` | n:'Mote sentinel',d:'Adds a null spire: | data.js:559 | B | Eclipse shows `gsentry` as Null spire. |
| `n:'Harvester tomb-turret',d:'Its doom arc sits on a turret` | n:'Turreted zenith',d:'Its corona arc sits on a turret | data.js:560 | B | |
| `n:'Penitent lantern-cruiser'` | n:'Vigil lance-cruiser' | data.js:564 | B | Arc unlock; lanterns are off-limits for the Crusade (bible 2.4). Must match godot/story/data/arcs.json (L). |
| `n:'Interdictor column escort'` | n:'Cordon column escort' | data.js:565 | B | Arc unlock. |
| `n:'Gilded marauder'` | n:'Trophy wrecker' | data.js:566 | B | Arc unlock (Hullbreaker trophy plates). |
| `n:'Sun-eater razorfiend',d:'Its tendril cluster becomes a second bio-plasma spitter on a turret;` | n:'Sun-eater bladeback',d:'Its tendril cluster becomes a second spine volley on a turret; | data.js:567 | B | Arc unlock. |
| `n:'Archive wraithcarrier'` | n:'Ringing aperture' | data.js:568 | B | Arc unlock (the Ringing Field, bible 6.10). |
| `n:'Jackal court guard',d:'Both gauss guns on turrets and a gauss sentry, 10 less hull.'` | n:'Archive guard flare',d:'Both null cannons on turrets and a null spire, 10 less hull.' | data.js:569 | B | Arc unlock. |
| `voidsworn:'Zealot flotilla'` | voidsworn:'Frontier flotilla' | data.js:592 | B | Archetype names. |
| `ithar:'Wisp flight',deathless:'Scythe harvest'` | ithar:'Sliver flight',deathless:'Mote cloud' | data.js:592 | B | |
| `voidsworn:'Cathedral line'` | voidsworn:'Bastion line' | data.js:593 | B | |
| `chorus:'Titan pod',ithar:'Songline'` | chorus:'Bloat pod',ithar:'Prism line' | data.js:593 | B | |
| `voidsworn:'Reliquary group'` | voidsworn:'Hearth group' | data.js:594 | B | |
| `corsair:'Raider nest',chorus:'Hive cluster',ithar:'Wraith host',deathless:'Harvest ark'` | corsair:'Hulk den',chorus:'Brood cluster',ithar:'Aperture host',deathless:'Repair host' | data.js:594 | B | |

## 9. Nemesis tables, adaptations, captain and ship name pools

One name, one owner (bible 1.4): no captain pool rolls an admiral's given name or surname, no Nemesis pool rolls a boss or admiral name, no epithet repeats across admiral, scar and persona. Whole lists are quoted because the list itself changes. Lists keep their length and shape; `scarBy` entries must stay members of `scars`.

### 9.1 Nemesis name parts, titles, scars (data.js NEM_FAC)

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `pre:['Krag','Vash','Rusk','Gor','Snag','Black','Red','Mad','Skarn','Jagg']` | pre:['Krag','Drog','Rusk','Gor','Snag','Hask','Grul','Murg','Skarn','Jagg'] | data.js:459 | B | Hullbreaker: harsh one-syllable fronts (bible 4.9); Vash sat next to Vesh the Collector. |
| `post:['Tooth','Maw','Gut','Vane','Hook','Knuckle','Rot','Grin','Spur','Wreck']` | post:['Tooth','Maw','Gut','Vise','Hook','Knuckle','Rot','Grin','Spur','Wreck'] | data.js:459 | B | Vane is a Crusade surname. |
| `titles:['Reaver-king','Warlord','Scrap-baron','Pirate prince']` | titles:['Apex','First Claw','Den-alpha','Warlord'] | data.js:459 | B | Canonical Nemesis titles. |
| `scars:['the Burned','Ironjaw','Half-Face','the Uncaught','Patchwork','One-Eye'],scarBy:{fled:['the Uncaught'],burn:['the Burned','Half-Face'],wound:['Ironjaw','Patchwork','One-Eye']}` | scars:['the Burned','Broken-Jaw','Half-Face','the Uncaught','Patchwork','One-Eye'],scarBy:{fled:['the Uncaught'],burn:['the Burned','Half-Face'],wound:['Broken-Jaw','Patchwork','One-Eye']} | data.js:460 | B | Ironjaw is gone with Grax. |
| `pre:['Ald','Cor','Esm','Hal','Ord','Gyr','Wulf','Sig','Mor','Ed'],post:['ric','mar','wyn','gar','wine','mund','red','ith','helm','wold'],titles:['Ash-king','Regent','Barrow-king','Dust-sovereign']` | pre:['Mar','Kae','Hal','Tor','Ess','Ul','Vor','Iv','Sar','Den'],post:['un','lo','vane','eth','ane','ix','or','ael','en','ast'],titles:['High Nadir','Eclipse-prime','Archivist','Nadir'] | data.js:462 | B | Eclipse: old Starwright names (bible 7.9; Marun, Kaelo and the sample Halvane can roll on purpose, the four admirals cannot). Canonical Nemesis titles plus the top rank. |
| `fem:['Esm','Ed','Sig']` | fem:['Ess','Kae','Iv'] | data.js:463 | B | |
| `scars:['the Twice-Dead','the Rebuilt','Cracked-Crown','the Unfinished','Hollow-Eye','the Patient'],scarBy:{fled:['the Patient','the Unfinished'],burn:['Hollow-Eye','the Rebuilt'],wound:['the Twice-Dead','Cracked-Crown','the Rebuilt']}` | scars:['the Twice-Dead','the Rebuilt','Cracked-Visor','Half-Restored','Hollow-Eye','of the Late Copy'],scarBy:{fled:['of the Late Copy','Half-Restored'],burn:['Hollow-Eye','the Rebuilt'],wound:['the Twice-Dead','Cracked-Visor','the Rebuilt']} | data.js:463 | B | Iteration language (bible 7.9). The Unfinished is the Glasswright flagship; the Patient is a persona; no crowns. |
| `pre:['Ael','Ith','Sae','Ny','Cael','Lir','Tal','Fae','Ely','Ors'],post:['wyn','riel','thas','lune','vael','dris','eth','nor','iel','ane'],titles:['Seraph','Starwarden','Duelist','Wing-lord']` | pre:['Kor','Sev','Tal','Ol','Ves','Dre','Ish','Ren','Cal','Ny'],post:['ek','is','oro','an','et','ul','ith','im','os','ae'],titles:['Lens-keeper','First Mirror','Keeper of Astra','Duelist'] | data.js:465 | B | Glasswright: short and crisp, less elvish (bible 6.9). Canonical Nemesis titles plus Duelist. |
| `fem:['Ael','Sae','Fae','Ely','Lir']` | fem:['Ves','Ish','Ny','Dre'] | data.js:466 | B | |
| `scars:['the Cracked Prism','Dimmed','the Scarred Sail','Thornwing','the Unbowed','Ashwake'],scarBy:{fled:['the Unbowed','Ashwake'],burn:['Dimmed','the Cracked Prism'],wound:['the Scarred Sail','Thornwing','the Cracked Prism']}` | scars:['the Cracked Prism','Dimmed','the Scarred Vane','Thornwing','the Unbowed','Ashwake'],scarBy:{fled:['the Unbowed','Ashwake'],burn:['Dimmed','the Cracked Prism'],wound:['the Scarred Vane','Thornwing','the Cracked Prism']} | data.js:466 | B | Vanes, not sails. |
| `pre:['Seventh','Hollow','Wet','Grieving','Ninefold','Brine','Pale','Deep','Thrumming','Gnawing']` | pre:['Seventh','Hollow','Wet','Sour','Bloated','Brine','Pale','Deep','Thrumming','Gnawing'] | data.js:468 | B | Ninefold plus Maw would roll the boss; grief belongs to the Glasswrights. |
| `titles:['Spawn-mother','Elder Throat','Gorge-mind','Brood-queen']` | titles:['Spawn-mother','Elder Throat','Gorge-mind','Maw-mother'] | data.js:468 | B | Canonical (bible 5.9); brood-queen is a Tyranid word. |
| `pre:['Konrad','Ilsa','Viktor','Aldric','Petra','Halvar','Ruprecht','Katrin','Sanne','Gerold']` | pre:['Konrad','Marit','Viktor','Aldric','Petra','Halvar','Ruprecht','Katrin','Sanne','Gerold'] | data.js:471 | B | Ilsa is First Admiral Kassar. |
| `titles:['Grand Admiral','Fleet Marshal','Line Admiral','High Commodore']` | titles:['First Admiral','Fleet Marshal','Line Admiral','High Commodore'] | data.js:471 | B | Canonical rank. |
| `fem:['Ilsa','Petra','Katrin','Sanne']` | fem:['Marit','Petra','Katrin','Sanne'] | data.js:472 | B | |
| `scars:['the Burned Admiral','Ironside','One-Arm','the Unbroken','Scarface','the Survivor'],scarBy:{fled:['the Survivor','the Unbroken'],burn:['the Burned Admiral','Scarface'],wound:['One-Arm','Ironside','Scarface']}` | scars:['the Burned Admiral','Ironside','One-Arm','the Unbroken','Scar-Cheek','the Survivor'],scarBy:{fled:['the Survivor','the Unbroken'],burn:['the Burned Admiral','Scar-Cheek'],wound:['One-Arm','Ironside','Scar-Cheek']} | data.js:472 | B | Scarface is a film title. |
| `pre:['Saint','Brother','Censor','Provost','Shriver','Votary','Arch-deacon','Cantor','Sister','Lector']` | pre:['Leofric','Margit','Osmund','Ida','Berthold','Hedda','Wendel','Agathe','Gunther','Edda'] | data.js:474 | B | Crusade: old European given names (bible 2.10); every church title out. |
| `titles:['Crusade-master','High Votary','Lord Censor','Arch-shriver']` | titles:['High Warden','Warden of the Roll','Dawnwarden','Oath-warden'] | data.js:474 | B | Bible 2.10 titles. |
| `fem:['Sister'],masc:['Brother']` | fem:['Margit','Ida','Hedda','Agathe','Edda'],masc:['Leofric','Osmund','Berthold','Wendel','Gunther'] | data.js:475 | B | |
| `scars:['the Branded','Ironhand','the Martyr-Scarred','Burnt-Psalm','the Unrepentant','Ashface'],scarBy:{fled:['the Unrepentant'],burn:['the Branded','Burnt-Psalm','Ashface'],wound:['Ironhand','the Martyr-Scarred']}` | scars:['the Branded','Iron-Armed','the Frost-Scarred','Burnt-Oath','the Debt-Bound','Ashface'],scarBy:{fled:['the Debt-Bound'],burn:['the Branded','Burnt-Oath','Ashface'],wound:['Iron-Armed','the Frost-Scarred']} | data.js:475 | B | Martyr, psalm and repentance are church words; Iron Hands is a Space Marine chapter. |
| `undying:{n:'Endless dead'` | undying:{n:'Spare frames' | data.js:451 | B | Nemesis trait (id stays). |

### 9.2 Nemesis adaptations (NEM_ADAPT_FAC)

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `deathless:{shields:'Quantum ward',pd:'Gauss pylons',armor:'Grave-alloy shell',evasion:'Phase drift',aim:'Barrow sight',special:{id:'legion',n:'Wider legion'` | deathless:{shields:'Corona ward',pd:'Null spires',armor:'Sunshade shell',evasion:'Fold skips',aim:'Long-memory sight',special:{id:'legion',n:'Deeper backups' | data.js:481 | B | Id `legion` stays. |
| `armor:'Dawnglass spine',evasion:'Starwind vanes',aim:'Farsight crystals'` | armor:'Waveguide spine',evasion:'Starwind vanes',aim:'Interferometer lenses' | data.js:482 | B | Bible 6.10 refit words. |
| `ithar:{shields:'Prism lattice'` | ithar:{shields:'Prism matrix' | data.js:482 | B | |
| `aim:'Hunting eyes'` | aim:'Tasting pores' | data.js:483 | B | |
| `voidsworn:{shields:'Ward rites',pd:'Censer flak',armor:'Blessed plate',evasion:'Litany of speed',aim:'Augury rites'` | voidsworn:{shields:'Screen drills',pd:'Spark flak',armor:'Riveted plate',evasion:'Oath of speed',aim:'Hand-laid sights' | data.js:485 | B | No rites, censers, blessings or litanies. |

### 9.3 Captain pools (CAP_FIRST, CAP_LAST, CAPTAINS)

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `const CAP_FIRST = ['Ilse','Corvin','Maren','Tobias','Anselm','Vera','Casimir','Odile','Lucan','Serafine','Aurek','Helka','Brannoc','Isolde','Garrick','Mireille','Dagan','Thessaly','Rourke','Elsbeth','Konrad','Yara','Osric','Ninette','Halvard','Petra','Lysander','Calla'];` | const CAP_FIRST = ['Ilse','Corvin','Mathilde','Tobias','Anselm','Vera','Casimir','Odile','Lucan','Sabine','Emeric','Helka','Brannoc','Rosalind','Garrick','Margery','Dagan','Thessaly','Rourke','Elsbeth','Aldous','Yara','Osric','Ninette','Hadrian','Clemence','Lysander','Calla']; | data.js:253 | B | Maren is a Hegemony admiral's surname, Aurek sits next to Aurex, Serafine is seraph, Konrad, Halvard and Petra belong to the Hegemony, Isolde and Mireille echoed old Ithar names. |
| `'Holloway','Sable','Wyndham'` | 'Holloway','Sedley','Wyndham' | data.js:254 | B | Sable is the Hullbreaker admiral. |
| `'Okonkwo','Brandt','Salo'` | 'Okonkwo','Ashby','Salo' | data.js:254 | B | Brandt is a Hegemony surname. |
| `first:['Konrad','Ilsa','Dace','Mara','Oskar',` | first:['Konrad','Marit','Joost','Mara','Anders', | data.js:519 | B | Hegemony captains could roll Ilsa Kassar, Dace Vorn, Oskar Maren. |
| `last:['Reiter','Kassel','Brandt','Vorn',` | last:['Reiter','Kassel','Brandt','Vollmer', | data.js:519 | B | Vorn is Commodore Dace Vorn. |
| `corsair:{ranks:['Mate','Skipper','Captain','Reaver-captain','Warlord'],first:['Rusty','Grim','Mad','One-Eye','Lucky','Red','Scrap','Knuckles','Salt','Patch','Dutch','Sly','Bones','Tiny','Hooks','Jinx'],last:['Krogg','Brannigan','Mallory','Blackwater','Rook','Sharkey','Gutter','Varrick','the Knife','Two-Guns','Tallow','Ironjaw','Spatchcock','Quill','Rattigan','Slade']}` | corsair:{ranks:['Claw','Fang','Howler','Ripper','Warlord'],first:['Krogg','Gash','Rorr','Brak','Hulg','Drask','Olk','Thrag','Grisk','Vorg','Gnarl','Karsk','Bruk','Ulm','Rask','Tusk'],last:['the Gutter','Rattlebone','Two-Claws','Scrapback','Longjaw','Gristle','Chainback','Ashfur','Red-Muzzle','Torn-Ear','Rustcoat','the Quiet','Bent-Tooth','Boltneck','Greyback','the Tracker']} | data.js:520 | B | Canonical ranks. Harsh names plus fight-earned epithets, no human surnames (bible 4.9); Rook is the core R-5. |
| `chorus:{ranks:['Spawn-mind','Brood-node','Throat','Elder throat','Matriarch'],names:['Seventh Mouth','Hollow Song','Deep Murmur','Thrumming Coil','Pale Bloom','Wet Whisper','Ninefold','Grieving Tide','Brine Hymn','Moult','Ashk-of-Many','Sallow Choir','Undertow','Last Spore','Coiled Psalm','Lantern Gut']}` | chorus:{ranks:['Spawn-mind','Node','Throat','Elder throat','Great throat'],names:['Seventh Mouth','Hollow Gut','Deep Murmur','Thrumming Coil','Pale Bloom','Wet Whisper','Ninth Tooth','Gnawing Tide','Brine Mouth','Moult','Ashk-of-Many','Sallow Rasp','Undertow','Last Spore','Coiled Gullet','Lantern Gut']} | data.js:521 | B | Bible 5.9 and 5.10. |
| `ithar:{ranks:['Wing','Sail','Seraph','High seraph','Starwarden'],first:['Siriel','Aelith','Vaelen','Thandor','Ilyra','Caelis','Ithrien','Nyssa','Orrin','Saelune','Talvar','Eluned','Faewyn','Liraen','Corvel','Ysolde'],last:['Starglass','Dawnsail','Veilborn','Moonreach','Sunward','Lightwhisper','Skyhollow','Silverwake','Brightmere','Glasswing','Nightbloom','Farcall']}` | ithar:{ranks:['Glimmer','Glint','Facet','Mirror','Lens-keeper'],first:['Oskel','Ilvy','Teo','Kesh','Lun','Pell','Ressa','Taro','Imre','Nell','Tobin','Avin','Sefa','Davin','Orra','Fen'],last:['of the Second Lens','of the Bright Collector','of the Long Beamline','of the Quiet Mirror','of the Ninth Facet','of the Cold Lens','of the Far Collector','of the First Prism','of the Split Beam','of the Slow Focus','of the Silver Array','of the Deep Mirror']} | data.js:522 | B | Bible 6.9 and 6.10. Captains read "Oskel of the Second Lens". Sunward is now the Crusade's name. |
| `deathless:{ranks:['Warden','Overseer','Cryptlord','Overlord','Dynast'],names:['Imhoten','Setekh','Amuneth','Rahotep','Tauret','Menkara','Khepset','Nefrah','Osirak','Ptahmet','Sobekar','Thutem','Wadjen','Hekamun'],epithets:['the Hollow','the Patient','the Silent','the Undying','of the Ninth Tomb','the Unbroken','the Pale','the Ever-Watching','the Iron-Hearted','of the Sunless Court']}` | deathless:{ranks:['Shade','Gloam','Umbra','Midnight','Nadir'],names:['Quorel','Benth','Ivess','Toran','Odrun','Desmae','Selith','Vantor','Imra','Caddex','Rhosse','Altheve','Keshet','Pallun'],epithets:['of the Second Frame','of the Fifth Frame','the Thrice-Copied','of the Old Copy','the Seventh-Housed','the Once-Restored','of the Clean Copy','of the Twelfth Frame','the Never-Dark','of the Last Backup']} | data.js:523 | B | Canonical ranks; Starwright names; iteration epithets (bible 7.9). Warden was also a Crusade class. |

### 9.4 Ship name pools

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `const SHIP_NAMES = ['Unyielding Oath','Saint Vesper’s Wrath','Ashen Vigil','Lament of Iron','Bright Censure','Hymn of Ruin','Oathkeeper','Merciless Litany','Cinder Psalm','Pale Crusader','Everwatch','Grave Tithe','Sanctified Fury','Iron Requiem','Dawn of Cinders','Martyr’s Resolve','Judgement Bell','Votive Flame','Sorrow’s Edge','Penance Undying','Relentless Canticle','Obsidian Choir','Hallowed Anvil','Last Benediction','Wrathful Seraph','Cold Absolution','Thorn of Heaven','Vigilant Censer'];` | const SHIP_NAMES = ['Unyielding Oath','Wrath of Vesper','Ashen Vigil','Long Watch','Bright Censure','Banked Fire','Oathkeeper','Merciless Frost','Cinder Vow','Pale Crusader','Everwatch','Debt of Vesper','Cold Fury','Iron Dusk','Dawn of Cinders','Resolve of the Reach','Judgement Bell','Oath Flame','Edge of Winter','Unpaid Debt','Relentless Ember','Obsidian Brand','Black Anvil','Acceptable Loss','Burning Spire','Cold Reckoning','Thorn of the Reach','Vigilant Ash']; | data.js:252 | B | Crusade: oath, fire and cold (bible 2.10). Every church word out; no apostrophes. |
| `'HNS Ironclad','HNS Resolute','HNS Bastion','HNS Ascendancy','HNS Vindicator','HNS Castellan'` | 'HNS Optimal','HNS Resolute','HNS Consensus','HNS Ascendancy','HNS Projection','HNS Punctual' | data.js:525 | B | Ironclad is a sea word; Bastion is a Crusade class; Vindicator and Castellan are 40k. |
| `corsair:['Bilge Rat','Salt Debt','Last Laugh','Nine Lives','Scrapjaw','Black Ledger','Gilded Liar','Rattletrap','Widow’s Wager','Low Tide']` | corsair:['No Quarter','Gut Hook','Chain of Teeth','Forty Captains','Second Death','Scrapjaw','Cold Trail','Rattletrap','Long Howl','Last Scent'] | data.js:526 | B | Threats and kills (bible 4.9); sea words out. |
| `chorus:['Shrieking Coil','Brood Vessel Om','Mournful Gut','Spine Choir','Hive-node Vesk','Crawling Hymn','Wet Psalm','Gnawing Bloom','Tide of Teeth','Hollowsong']` | chorus:['Shrieking Coil','Brood Vessel Om','Sour Gut','Spine Gullet','Node Vesk','Crawling Maw','Wet Mouth','Gnawing Bloom','Tide of Teeth','Hollowgut'] | data.js:527 | B | |
| `ithar:['Glass Requiem','Morningveil','Starfall','Quiet Wing','Lumen Arc','Silver Lament','Aurora’s Grace','Farlight','Moonsorrow','Petal Storm']` | ithar:['Last Reflection','Morningveil','Starfall','Quiet Wing','Lumen Arc','Silver Lament','Held Spectrum','Farlight','Moonsorrow','What We Built'] | data.js:528 | B | Light and grief (bible 6.9). |
| `deathless:['Tomb of Nine Kings','Ankh of Ash','Silent Procession','Dust Eternal','The Unsleeping','Obelisk of Night','Crypt of Teeth','Sunless Barge','Pale Sovereign','Ever-Watch']` | deathless:['Remembered Noon','Warmth Recalled','Silent Procession','Long Night','The Unsleeping','Shade of Noon','Ninth Winter','Sunless Hours','Cold Archive','Noon Kept'] | data.js:529 | B | Memory, darkness, the lost sun. |
| `hegemony:['HNS Dominator','HNS Relentless','HNS Sovereign','HNS Executor','HNS Imperious','HNS Harbinger',` | hegemony:['HNS Dominator','HNS Relentless','HNS Sovereign','HNS Comptroller','HNS Allocation','HNS Forecast', | ui3d.js:19 | B | Skirmish names (ui3d.js FNAMES). Executor is Star Wars; Harbinger is Mass Effect. |
| `corsair:['Rust Maw','Gutter Queen','Red Tithe',` | corsair:['Rust Maw','Gutter Queen','Red Tally', | ui3d.js:20 | B | |
| `'Salvage Right','Hollow Crown']` | 'Salvage Right','Bent Crown'] | ui3d.js:20 | B | |
| `chorus:['Hive-node Ashk','Brood Vessel Ul','Shrieker','Mawling','Gorefeather','Sac-mother','Thornback','Tidehunger','Wet Choir','Crawling Hymn']` | chorus:['Node Ashk','Brood Vessel Ul','Shrieker','Mawling','Gorebloom','Sac-mother','Thornback','Tidehunger','Wet Maw','Crawling Gut'] | ui3d.js:21 | B | |
| `ithar:['Silverthorn','Dawnwhisper','Lament of Stars','Glass Heron','Moonveil','Farsinger','Pale Current','Starfall','Quiet Blade','Evening Tide']` | ithar:['Silverthorn','Clear Whisper','Lament of Stars','Glass Heron','Moonveil','Far Focus','Pale Current','Starfall','Quiet Prism','Evening Tide'] | ui3d.js:22 | B | |
| `deathless:['Eternal Vigil','The Unbroken','Sepulchre','Tomb of Ashes','Grave Sovereign','Ossuary','Never-Ending','Obelisk','Dust Throne','Silent Heir']` | deathless:['Long Noon','The Unbroken','Last Light Kept','Copy of Ardent','Ninth Shade','Cold Memory','Never-Ending','Gnomon','Dust of Noon','Silent Heir'] | ui3d.js:23 | B | |
| `"ship": "Saint Ignatius"` | "ship": "Banked Fire" | godot/scenes/campaign/campaign_scene.gd:59 | G2 | Screenshot fixture (shows on the Hall of the fallen). Its captain "Ordo Halvar" becomes "Casimir Holloway" (Ordo is an Inquisition word). |

## 10. Help text and Godot-only screen text

### 10.1 How to play (both games)

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `gauss weapons mostly ignore them` | null weapons mostly ignore them | campaign_meta.js:160; godot/ui/campaign/campaign_ui.gd:1015 | B, G3 | |
| `Hegemony ion pulses, Corsair overburn, Chorus regrowth and frenzy, Ithar phase jumps, Deathless reanimation beams, and the Voidsworn’s burns, reloads and shield surges` | Hegemony ion pulses, Hullbreaker overburn, Chorus regrowth and frenzy, Glasswright phase jumps, Eclipse repair swarms, and the Crusade’s burns, reloads and shield surges | campaign_meta.js:165 | B | |
| `patrons grow fond of you as you take their boons, offering rarer boons and eventually a gift at the start of a run` | cores sync with you as you take their protocols, offering rarer protocols and eventually a gift at the start of a run | godot/ui/campaign/campaign_ui.gd:1009 | G3 | Godot copy of the 2.x row (the browser line has `<b>` tags). |

### 10.2 Godot screens (G2, G3)

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `const TAGLINE := "Command a crusade of gothic capital ships through three hostile sectors. Every hull you lose stays lost, and so does its captain."` | const TAGLINE := "Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain." | godot/ui/battle/brand.gd:11 | G2 | Same tagline as row 1.2 (G2). |
| `term("patrons", true) + " watching"` | term("patrons", true) + " in range" | godot/ui/campaign/campaign_ui.gd:573 | G3 | Map sidebar box title after the TERMS switch ("Cores in range"). |
| `" · win at a " + term("sigil") + " for a " + term("boon")` | " · win at a " + term("sigil") + " for a " + term("boon") | godot/ui/campaign/campaign_ui.gd:573 | G3 | Reads "win at a signal for a protocol" after the switch: fine as is, listed so nobody hunts for it. |
| `"Win at a stop with a " + term("patron") + "'s " + term("sigil") + " and that " + term("patron") + " offers a " + term("boon") + "."` | "Win at a stop carrying a " + term("patron") + "'s " + term("sigil") + " and that " + term("patron") + " offers a " + term("boon") + "." | godot/ui/campaign/campaign_ui.gd:573 | G3 | Tooltip; "carrying" reads better with signal. |
| `"None yet. Win at a node with a " + term("patron") + "’s " + term("sigil") + " to earn one."` | "None yet. Win at a node carrying a " + term("patron") + "’s " + term("sigil") + " to earn one." | godot/ui/campaign/campaign_ui.gd:660 | G3 | |
| `"startRun": "Launch the crusade"` | "startRun": "Launch" | godot/main/campaign_fallback_ui.gd:7 | G2 | Fallback UI label; the run word depends on the faction (Homecoming, raid ...). |

G2's own rows already landed in 49f0d85 (title, window title, project name, product name and description; exe file name kept as Voidsworn.exe, save folder kept). Nothing else for G2 in project.godot or export_presets.cfg. `godot/main/FEATURES.md` mentions the old exe and folder names only as file paths; keep.

## 11. Story layer (godot/story, L)

L rewrites `godot/story/` to round 8 in Job 2 (arcs, outlines, titles, unlocks, chronicle and career text, Nemesis story lines, voices, tokens.gd, tests, README). Every id, hook, trigger and data shape stays. The rows below are the ones other streams read or mirror; the full text changes are in L's commits and `lore_rollout_notes.md`.

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `"unlock_name": "Penitent lantern-cruiser"` | "unlock_name": "Vigil lance-cruiser" | godot/story/data/arcs.json:9 | L | Must match data.js HULL_VARIANTS (8.x). |
| `"unlock_name": "Interdictor column escort"` | "unlock_name": "Cordon column escort" | godot/story/data/arcs.json:17 | L | |
| `"unlock_name": "Gilded marauder"` | "unlock_name": "Trophy wrecker" | godot/story/data/arcs.json:25 | L | |
| `"unlock_name": "Sun-eater razorfiend"` | "unlock_name": "Sun-eater bladeback" | godot/story/data/arcs.json:33 | L | |
| `"unlock_name": "Archive wraithcarrier"` | "unlock_name": "Ringing aperture" | godot/story/data/arcs.json:41 | L | |
| `"unlock_name": "Court guard destroyer"` | "unlock_name": "Archive guard flare" | godot/story/data/arcs.json:49 | L | Already differed from data.js ("Jackal court guard"); both now say Archive guard flare. |
| `Lances and gauss guns make up` | Lances and null guns make up | godot/story/data/titles.json:10 | L | Title rule text. |
| `"Warlord Grax Ironjaw` | "Warlord Grax Steelgrin | godot/story/test/story_test.gd:195,276; godot/story/README.md:96 | L | Test fixtures and README sample. |
| `Admiral Castellan Vex` | Admiral Roderic Vex | data.js:203; tools/portraits/make_batches.py:41; godot/story/story.gd:155,181; godot/story/test/story_test.gd:233,235 | B, P, L | Test fixtures and comments (data.js row is in 6). |
| `const FEMININE := [` | (list rewritten to the new pools) | godot/story/tokens.gd:19 | L | tokens.gd pronoun fallback: drop Isolde, Mireille, Serafine, Maren, Ilsa, Aelith, Ilyra, Nyssa, Saelune, Eluned, Faewyn, Liraen, Ysolde, Tauret, Nefrah, Khepset; add Mathilde, Sabine, Rosalind, Margery, Clemence, Marit, Margit, Ida, Hedda, Agathe, Edda, Tamsa, Ilvy, Ressa, Nell, Sefa, Orra, Desmae, Imra, Rhosse, Altheve, plus the Nemesis prefixes from NEM_FAC fem lists. |

## 12. Portraits (P)

P landed the round 8 prompts in e243729. What is left in `tools/portraits/make_batches.py` is the batch 1 and 2 history (subjects already painted, kept so old batches can be rebuilt). If any of those subjects is queued again, change the names in it first:

| Old | New | Where | Owner | Note |
|---|---|---|---|---|
| `Portrait of Admiral Castellan Vex of the Voidsworn Crusade` | Portrait of Admiral Roderic Vex of the Sunward Crusade | tools/portraits/make_batches.py:41 | P | |
| `Portrait of Grand Admiral Ilsa Kassar` | Portrait of First Admiral Ilsa Kassar | tools/portraits/make_batches.py:45 | P | |
| `Portrait of Warlord Grax Ironjaw of the Ashfall Corsairs` | Portrait of Warlord Grax Steelgrin of the Ashfall Hullbreakers | tools/portraits/make_batches.py:49 | P | And the human-pirate description becomes the furred bear and wolf species (brief, Portraits row). |
| `Portrait of Overlord Nekhet the Undying of the Deathless Dynasty` | Portrait of Nadir Aurex, Ninth Frame, of Eclipse | tools/portraits/make_batches.py:58 | P | |
| `Portrait of The Mending Choir` | Portrait of The Mending Throng | tools/portraits/make_batches.py:26 | P | |
| `Portrait of Aelith Dawnsail of the Ithar` | Portrait of Tamsa of the Clear Aperture, a Glasswright | tools/portraits/make_batches.py:53,91 | P | |
| `'Portrait of a Nemesis, a rival enemy commander of the Ithar: %s. %s'` | 'Portrait of a Nemesis, a rival enemy commander of the Glasswrights: %s. %s' | tools/portraits/make_batches.py:191 | P | |
| `'A Nemesis of the %s, a rival enemy war-organism: %s. %s' % (_fac.capitalize()` | use a display name map: chorus "the Chorus", deathless "Eclipse" | tools/portraits/make_batches.py:193,205 | P | `_fac.capitalize()` would print "Deathless". |

## 13. Vetoable calls (L's picks where the bible is silent)

Opus or Ryan can veto any of these; each is a few strings to swap.

- **V1 Tagline:** "Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain." (any faction can be played, so not "crusade").
- **V2 Faction blurbs:** six new one-liners in section 1 (gameplay half kept, lore half from the bible).
- **V3 Ship classes:** `cls` stays as the internal key; new display map: War-barge, Colossus (canonical), **Lattice-ship** for The Unfinished (the bible gives no class; it is built around the largest piece of the Lattice), Archive-ship (canonical).
- **V4 Crusade admirals:** Castellan Vex becomes **Admiral Roderic Vex**; Oath-Captain Malek Draven (canonical), Commodore Sera Ashgrove and High Admiral Oryn Thale kept.
- **V5 Hullbreaker admirals:** **Warlord Grax Steelgrin**, **Old Mott** (no surname), **Sable the Smiling Knife** (human surname Venn dropped; a sable is a furred hunter, so the name fits the species), Vesh the Collector kept.
- **V6 Glasswright admirals** (name plus optical family line): aelith = **Tamsa of the Clear Aperture** (carriers), vaelen = **Saro of Long Focus** (lances; Command "Burning glass"), thorne = **Vell of the Third Mirror** (evasion; Command "Scatter the light"), mirelle = **Brin of the Fourth Lens** (shields). Corin skipped: Corin Reyes is Hegemony.
- **V7 Eclipse admirals by doctrine:** nekhet = **Nadir Aurex, Ninth Frame** (regrowth starter, and its portrait is the bible's broken ring mind), sekhmar = **Umbra Vessane, Third-Housed** (corona-arc offence), anuket = **Ostrel of the Long Copy** (silent flanker), khepra = **Seveth, Twice-Restored** (the durable one). Commands: Release the repair swarms, Noon volley, Out of the shadow, Sunshade wall.
- **V8 Name pools:** all pools in section 9. Hullbreaker captains are harsh names plus fight epithets ("Krogg the Gutter", "Thrag Longjaw"); Glasswright captains carry family lines ("Oskel of the Second Lens"); Eclipse captains carry iteration epithets ("Benth of the Fifth Frame"); Crusade Nemesis titles are the bible's (High Warden, Warden of the Roll, Dawnwarden, Oath-warden) over old European given names; Eclipse Nemesis titles High Nadir, Eclipse-prime, Archivist, Nadir; Glasswright Lens-keeper, First Mirror, Keeper of Astra, Duelist.
- **V9 Cores:** sync tiers **Listening, Partial sync, Synced, Full sync**; protocols renamed only where a church or song word or a clash forced it (Unbent Plating, Incendiary Warheads, Hot Tubes, Brood Harvest, Fortress). The S-6 badge letter is S.
- **V10 Faction-power strings:** void-shrine becomes **"A wall of names"** (a memorial station chalked with a lost crusade's names), and the Crusade verb becomes **"Keep the dawn watch"** (free after an offering there); "joined the song" becomes **"answered the tone"** (a dying Glasswright prism ringing one clear tone); "Waken the legion" becomes **"Back up the fleet"**; tomb-world becomes **"A siphon array"** (the hostile event) and **"A dormant hull yard"** (the Eclipse-only twin); the Eclipse rule "Endless legion" becomes **"Archive restore"**.
- **V11 Events:** the astropath becomes a signals officer and a founders' beacon (no psychics); the Ithar seer becomes a Glasswright wanderer and its keeper; the tithe vault becomes a toll vault; the pirate haven a raider den; "The saint answers" becomes "Luck holds".
- **V12 Nova cannon** becomes **Spinal cannon** (shared by three flagships, so a neutral name).
- **V13 Battle shapes:** the gravity-well board's label is "Hollow Sun" (canonical row: the dead star is the Hollow Sun); Colossus becomes "Giant wreck" (Colossus is now the Maw's class); Shoals becomes "Rock shoals"; Archipelago kept.
- **V14 Relics keep the word "relic"** as the item type (a roguelite term, not the Crusade honour word the bible bans); only church-flavoured relic names change.
- **V15 Arc unlocks:** Vigil lance-cruiser, Cordon column escort, Trophy wrecker, Sun-eater bladeback, Ringing aperture, Archive guard flare.
- **V16 Run-end headlines:** Hullbreakers "Strongest keeps it", Glasswrights "The light is kept", Eclipse "Noon returns" (the others kept).
- **V17 Refits and relics the bible does not name:** section 5 (for example Scanner array, Screen capacitor, The Chalked Roll, Wake-tracker, Tasting pores, Annealing kilns, Long-count reckoner, Siphon ledger, Long clock).
- **V18 Small ones:** Hegemony "Shield wall order" (protocol now belongs to the cores), "Salvage crews" (was Salvage protocols), "Spitting volley", "Acid tide", Hegemony ship names Optimal, Consensus, Projection, Punctual, Comptroller, Allocation, Forecast.

## 14. Looked at and kept

- Generic words: void (Open void, Deep void, Quiet void), relic (the item type), crusade (the Crusade's run word and "Pale Crusader", "Crusader's wrath"), Warden-class and Harrow-class, Lance array, Phase jump (Glasswright short jumps), Prism charge, Undying foes (Heat), Zealots (Nemesis trait), Ion cannon, Plasma drive, Deflector (Hegemony words), Bright Censure, Judgement Bell (bells belong to the Crusade), Ashen Vigil and Everwatch (bible ship names), Funeral Pyre and Pyre of Stars, Warlord's Pyre-Barge (canonical), Wolfpack (the Hullbreakers are wolf-like pack hunters), Archipelago.
- Chorus: the Matriarch of Nine Throats, Razormaw, Voice of the Deep, drone-spawn, spitter, brood, Spawning surge, Blood frenzy, Regrowth tide, Deep Murmur, Lantern Gut.
- Hegemony: the Iron Mandate, picket, vanguard, dominion, the rest of the HNS names, all admirals except Kassar's rank.
- Ids, save keys, CSS class names and code comments (the sweep in Job 3 reports display strings only).

## 15. Grep check

Every Old cell was searched as an exact substring (also with `’` and `’` swapped) across: data.js, battle.js, core.js, campaign_run.js, campaign_meta.js, campaign3d.js, ui3d.js, head.html, main3d.js, tools/portraits/make_batches.py, godot/project.godot, godot/export_presets.cfg, godot/main/FEATURES.md, godot/story (gd, json, md, py; not review_incorporation.md, which is history), godot/ui, godot/main, godot/scenes, godot/rules (code and tests), godot/campaign (code and tests, not oracle), godot/portraits. Rows found: all; rows missing: 0. core.js, main3d.js and godot/portraits/*.gd had no display hits (ids only).
