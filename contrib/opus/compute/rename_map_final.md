# Rename map, final (lore round 8, approved Oct 27 2026, R59)

Written by L (lore rollout helper). Source of truth: `lore_bible_r8.md` and the canonical table in `contrib/opus/briefs/lore_rollout_2026-10-27.md`. This file supersedes `rename_map.md` (Oct 26): its inventory of where strings live was reused, its new names were not (Brand, Flux, Verdict arc, Chord lance, Deathless Court, writ/warrant/edict, the Court words and others are all retired).

**Read at:** main `e243729` (every Where cell below was produced by grepping the exact Old string at that commit; `(not found)` would mean the row is stale). Generated files are not listed and follow by re-export: `godot/rules/data/tables.json`, `godot/campaign/data/campaign_tables.json`, the oracle copies under `godot/*/test/oracle/`, and `voidsworn-3d.html`.

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

