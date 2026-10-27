# Lore rollout brief (Oct 27, 2026): "lore approved"

Ryan said **"lore approved"** on Oct 27, 2026 (15:28 PT), on lore round 8 (`contrib/opus/compute/lore_bible_r8.md`; live doc https://claude.ai/artifact/SKyQf2QcJSXGmXfmxKxFpJ). The one open call takes Opus's pick: Hullbreaker ranks Claw, Fang, Howler, Ripper, Warlord; Nemesis titles Apex, First Claw, Den-alpha, Warlord.

## Rules for everyone
- **Ids never change.** Only display strings, art and colours: `voidsworn`, `corsair`, `ithar`, `deathless`, `chorus`, `hegemony`, every hull, weapon, admiral, patron, boon, event and file id stays. Saves, sims and parity hashes are untouched (names are not in the parity canon).
- **The bible wins.** `lore_bible_r8.md` is the source. The old `contrib/opus/compute/rename_map.md` (Oct 26) is a useful inventory of where strings live, but many of its new names are superseded (Brand, Flux, Verdict arc, Chord lance, Deathless Court and others are all retired).
- **The final map** is `contrib/opus/compute/rename_map_final.md`, written by the lore rollout helper (L). Until it lands, only the canonical names below are settled; do not invent names for anything else.
- Plain words, no em dashes; commit to main with the usual identity and trailers; own folders only.

## Canonical names (settled now)

| Thing | Old display | New display |
|---|---|---|
| Game title | Voidsworn | **Embers of the Hollow Sun** |
| Faction `voidsworn` | Voidsworn Crusade | **Sunward Crusade** |
| Faction `hegemony` | Hegemony Navy | Hegemony Navy (kept) |
| Faction `corsair` | Ashfall Corsairs | **Ashfall Hullbreakers** |
| Faction `chorus` | The Chorus | The Chorus (kept) |
| Faction `ithar` | The Ithar | **The Glasswrights** |
| Faction `deathless` | The Deathless Dynasty | **Eclipse** (no "the") |
| The star / its people | (none) | Ardent / the **Starwrights**; Fleshwrights made the Chorus |
| The black hole | Dead star / Hollow Sun | **the Hollow Sun** |
| Patrons / boons / favour / sigil | patron, boon, favour, sigil | **core** (the embers), **protocol**, **sync**, **signal** |
| Patron names | Kharon the Iron Saint, Vyre the Storm Queen, The Hunger Below, Astra the Silent Star, Rook the Breaker, The Ember Choir | K-1 Kharon, the Unbent; V-2 Vyre, the Storm Queen; H-3 Crucible, "the Hunger Below"; A-4 Astra, the Silent Star; R-5 Rook, the Breaker; S-6 Seren, the Last Flame |
| Las- weapons | Las-repeater, Las-battery, Heavy las-broadside, Las-turret | Sear repeater, Sear battery, Heavy sear broadside, Sear turret |
| Hellfire torpedo | Hellfire torpedo | Cinder torpedo |
| Gauss family | Gauss flayer, Gauss pylon, Gauss shredder, Gauss sentries, kind label Gauss | Null cannon, Null spire, Null shredder, Null sentries, kind label Null |
| Doom arc | Doom arc | Corona arc |
| Pulsar lance | Pulsar lance | Prism lance |
| Turbolaser | Turbolaser, Heavy turbolaser (generic names) | Pulse laser, Heavy pulse laser |
| Hive Leviathan (Bio-titan) | Hive Leviathan | The Ninefold Maw (Colossus class) |
| Crusade classes | Warden, Harrow, Penitent, Reliquary, Cathedral, Ascendant | Warden, Harrow, Vigil, Hearth, Bastion, Daybreak |
| Hegemony classes | picket, interdictor, vanguard, dominion, The Iron Mandate | picket, cordon, vanguard, dominion, The Iron Mandate |
| Hullbreaker classes | raider, reaver, marauder, hulk-carrier, Pyre-Barge | raider, gutship, wrecker, hulk-carrier, Warlord's Pyre-Barge (War-barge class) |
| Chorus classes | drone-spawn, spitter, razorfiend, brood-mother, Hive Leviathan | drone-spawn, spitter, bladeback, brood-sac, The Ninefold Maw |
| Glasswright classes | wisp, shadowblade, songship, wraithcarrier, Worldsong Ark | sliver, lancet, prism, aperture, The Unfinished |
| Eclipse classes | scythe, jackal, harvester, The Undying Throne | mote, flare, zenith, The Unsetting (archive-ship class) |
| Hegemony rank | Grand Admiral | First Admiral |
| Malek's title | Inquisitor-Captain | Oath-Captain |
| Eclipse ranks | (Deathless ranks) | Shade, Gloam, Umbra, Midnight, Nadir; Nemesis High Nadir, Eclipse-prime, Archivist |
| Hullbreaker ranks | (Corsair ranks) | Claw, Fang, Howler, Ripper, Warlord; Nemesis Apex, First Claw, Den-alpha, Warlord |
| Eclipse admirals | Nekhet, Sekhmar, Anuket, Khepra | Nadir Aurex, Ninth Frame; Umbra Vessane, Third-Housed; Ostrel of the Long Copy; Seveth, Twice-Restored (L maps them to the four admiral ids by doctrine) |
| Run words | crusade, campaign, raid, hunt, voyage, reclamation | crusade, campaign, raid, hunt, voyage, **Homecoming** |

L decides and lists, as vetoable calls, everything the bible leaves open: Glasswright and Crusade admiral names, the Hullbreaker admirals under the "no human surnames" rule (Grax Steelgrin; Old Mott with no surname; whether Sable Venn stays), ship-name pools with church words (Saint, Hymn, Psalm, Litany, Censer, Requiem, Benediction, Seraph, Canticle, Choir and similar), captain pools, Nemesis pools, events, boons, faction blurbs, the tagline, and the faction-power strings (void-shrine, joined the song, Waken the legion, tomb-world).

## Who does what

| Stream | Job |
|---|---|
| **L, lore rollout (new helper)** | 1. Write `rename_map_final.md`: every player-facing string, old to new, with file:line, across data.js, battle.js, core.js, campaign_run.js, campaign_meta.js, campaign3d.js, ui3d.js, head.html, main3d.js and godot/ (story, ui, main, scenes, rules code, campaign code, portraits), and tools/portraits/make_batches.py. 2. Rewrite `godot/story/` (arcs, outlines, titles, unlocks, chronicle text, tokens.gd) to the round 8 lore. 3. After every stream lands, sweep the repo for retired words and report leftovers. |
| **B** | Apply the map to data.js and the JS files (display strings only); re-run the check pack and unit tests; log the change in port_notes.md as a strings-only step. |
| **G1** | Re-export tables after B lands; mirror the hard-coded strings in godot/rules (code and tests); re-run parity (names are not in the canon, so it must still pass). |
| **G3** | Re-export campaign tables after B lands; mirror strings in godot/ui/campaign and godot/campaign; crest and faction colour hooks in the campaign UI. |
| **G2** | `brand.gd`: TITLE "Embers of the Hollow Sun" and the new tagline from the map; strings in godot/main and godot/scenes; the Windows build name and window title; FEATURES.md. |
| **G4** | `godot/fx/faction_looks.json` to the new palettes (below); shield colours stay per faction (Chorus and Eclipse have none). |
| **A4** | Faction repaints of the hulls, shapes kept: Crusade black iron, frost white, bright ember (no rust); Glasswrights clear crystal, silver, rainbow edge, stored light; Eclipse violet-black plates, white-gold corona, violet-white inner glow, with shield-plate bands and eclipse rings on the next dressing pass; Chorus dark olive flesh, ochre chitin, bile yellow-green glow. Hullbreakers and Hegemony keep their paint; Hullbreaker hulls may gain listening dishes and wake scoops at the bow. |
| **Portraits** | Paint the final looks: Hullbreakers as furred bear and wolf monsters with eyeshine and scrap harnesses; Glasswrights tall, slender, light-storing skin, second eyelid; Eclipse machine bodies of violet-black plates with a white-gold visor and a chest light-core; Crusade unaugmented, frost-scarred, implant scars; Hegemony tasteful implants; Chorus faceless grown organisms. New crests from the bible. Update tools/portraits/make_batches.py prompts. PC lane A, through tmo.bat. |

## Order
L's map first (B and the Godot mirrors wait for it); G2's title, G4's palette, A4's repaints and the portraits can start now from this brief.
