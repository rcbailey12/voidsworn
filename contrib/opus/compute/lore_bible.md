# Voidsworn lore bible (DRAFT for Ryan)

Status: DRAFT, Oct 26 2026, naming-and-lore helper (R44, R47, R48). Nothing here is applied. Ryan approves or changes it; then stream B applies the data.js and JS text, the story helper applies the `godot/story/` text, and the portraits helper uses section 3 of each faction for new prompts. Internal ids never change (`deathless`, `d_scythe`, `gauss`, `doom`, `phylactery`, style `tomb` and so on), so saves, sims and parity are untouched.

Companion files:
- `rename_map.md`: every player-facing name to change, old and new, with file:line.
- `lore_summary.md`: the one-page phone version, with the options side by side.

How to read this:
- Section 1 is the shared world and the house rules every name must follow.
- Sections 2 to 7 are the six factions. Each has the same parts: who they are, voice, look, origin and wants, how they fight, captives and the dead, what they think of the others, crest and signature details, naming rules, ranks, ship classes, weapons, places, and two alternative takes.
- Section 8 is the big calls with options and my pick marked.
- Section 9 is what I checked for collisions with other games and trademarks.

What I kept: anything already good and already built. The A4 ships, the painted portraits, the six story arcs (R45, "approved in direction") and the hull, weapon and admiral names that carry no outside echo stay as they are. The bible describes them so new work matches.

---

## 1. The shared world and the house rules

### 1.1 The setting in one paragraph

Three contested sectors around the **Hollow Sun**, a dead star gone black, ringed in slow fire, with an old battlefield circling it (the gravity-well board, R2). Every faction has a reason to reach it: the Voidsworn to relight its beacon, the Hegemony to make it an anchorage, the Corsairs for a sunken treasure fleet, the Chorus for the warm thing at its core, the Ithar for their lost light-archive, the Deathless for the first Court sleeping in a vault beneath it. A run is one fleet's push through three sectors to the Sun. One enemy commander per run, the Nemesis, is also the story rival (R7). Six **patrons** (Kharon the Iron Saint, Vyre the Storm Queen, The Hunger Below, Astra the Silent Star, Rook the Breaker, and the ember patron) watch every run; they belong to no faction.

### 1.2 Shared vocabulary (use these, not the 40k words)

| Thing | Say | Never say |
|---|---|---|
| Faster-than-light travel | jump, jump route, rift (a hazard) | warp, the Warp, immaterium, drop out of warp |
| Sensors | scanners, scans, sensors | auspex |
| Ship computers | targeting computer, reckoner | cogitator, machine spirit |
| Shields | shields, wards (Voidsworn), deflectors (Hegemony) | void shields |
| Long-range messengers | far-dreamer (Voidsworn), signals officer | astropath, psyker |
| Old technology | founders' tech | archeotech |
| Aliens | aliens, outsiders | xenos, xeno |
| Arrivals in battle | jumps in | drops out of warp |
| Faith words | Saint, relic, the Rite (Voidsworn only) | Imperium, Emperor, Throne, heresy, heretic, inquisitor, confessor, litany, purity seal |

### 1.3 Motifs belong to one faction each

These are the lines the story reviews drew (X21, S-2). New names stay on their own side.

| Motif | Owner | Others must not |
|---|---|---|
| Song, choir, chord, lament, verse, hymn, psalm | Ithar | Chorus never sings; Voidsworn use bells and spoken call and response |
| Short hungry lines, taste, heat, smell, teeth | Chorus | |
| Law, record, writs, seals, sentences, the Court | Deathless | Hegemony gets no ancient law |
| Forms, numbers, appendices, triplicate, "acceptable" | Hegemony | Deathless get no bureaucracy jokes |
| Oath, chalk names, beacons, lanterns, bells, brands | Voidsworn | |
| Shares, debts, nicknames, jokes, luck | Corsairs | |

### 1.4 Naming rules for everyone

1. Original only: no name lifted from Warhammer 40k, Battlefleet Gothic, Age of Sigmar, Star Wars, StarCraft, Halo or another known franchise. Common English words are fine unless a franchise owns them in this exact sense (Gauss flayer, Doom arc, Razorfiend, Hive Fleet Leviathan).
2. Space, not sea (CLAUDE.md): no keels, anchors, crow's nests, sails on human ships. Ithar light sails are the one exception (they are light, not cloth).
3. One name, one owner: no captain pool may roll an admiral's first name or surname; no Nemesis pool may roll a boss name; no epithet repeats across admiral, scar and persona.
4. Plain to read: a player should be able to say the name. No apostrophes inside names.
5. Ids stay. Only the display strings change.

---

## 2. Voidsworn Crusade (name kept)

### 2.1 Who they are

The Voidsworn are humans descended from the first oath-fleet, which sailed to relight the Hollow Sun a thousand years ago and burned in its fire. Every generation swears the same oath: light the dark, and pay for it with names. They are a crusade, not an empire: a moving order of ships with no homeworld left, living off beacon-moons, pilgrims and prizes. They are proud, tired and devout, and they keep count of the dead the way other fleets keep count of ammunition.

### 2.2 Voice and motifs

- Register: second-person liturgy. Imperatives. Call and response ("Who lights the dark? We do. Who pays for it? We do.").
- Motifs: names chalked on the flagship's hull, beacons and iron lanterns, bells, brands (burning irons), ember and ash.
- Borrowed church words allowed: Saint, relic, the Rite, pilgrims, penance. That is the one borrowed register (S-2).
- Not allowed: heresy and heretic, inquisitors, confessors, litanies, templars, chaplains, purity seals, and singing (song is Ithar).

### 2.3 Look

- **People:** weathered humans. Shaved heads with oath brands (raised burn scars in the shape of a name), grey stubble, hard tired eyes. High-collared dark armoured void-coats with heavy shoulder plates. Brass reliquaries on chains. Chalk dust on gloves and plates: the oath is chalked or branded, not pinned.
- **Portrait note:** the current Vex prompt uses "ceramite shoulder plates, red wax votive seals and parchment oath strips". Wax seals with parchment strips are the Imperial purity seal, and ceramite is a 40k material. For new portraits: "armoured plates", "names chalked on the plates", "a brand on the brow".
- **Ships (A4, FAC3D):** black steel hulls (#4a4440, shadows #1c1918), rust-red trim (#9c3a1c), ember-orange windows, engines and bolts (about #ff6b1f to #ff8530). Tall spired superstructures that read as beacon towers and lantern cages, heavy broadside decks, conduit runs along the flanks, big ember engine bells. Bilateral symmetry (K1). Spires and lanterns, not gargoyles and arches: "spired", not "gothic".
- **Colours in one line:** black iron, ember, ash, chalk white.

### 2.4 Origin and wants

- Origin: no homeworld survives. The fleet moves along the Cinder Line, a chain of beacon-moons named for saints (Saint Vesper's beacon-moon is the first stop in the arc).
- Want: relight the Hollow Sun's beacon where the first oath-fleet burned. Do not come home without it.

### 2.5 How they fight

Line of battle. Broadsides hit 30% harder after moving two hexes (Broadside doctrine), lances at range, torpedoes that set targets burning, carriers kept (Reliquary). They brace, they hold the line, and their zealot Nemesis never flees and challenges your flagship to a duel.

### 2.6 Captives and the dead

- Their dead: every captain chalks one name on the flagship's hull before sailing. Lost ships get chalked beside them. The Hall of the Fallen holds the names of crusades that did not come home.
- Captives: offered the oath ("She takes the oath" in the mercenary event). Those who refuse are ransomed. Prizes are "redeemed" (the title "Redeemer of Hulls").

### 2.7 What they think of the others

- Hegemony: "Clerks with guns. They count what we name."
- Corsairs: "Thieves of saints' gold. They keep their word to a crew, which is more than most."
- Chorus: "The dark that eats. Burn it."
- Ithar: "They remember the Sun lit. They will not help us light it."
- Deathless: "A court that judges the living for living."

### 2.8 Crest and signature details

- Crest: a cracked halo over a sword (story, kept).
- Sound: a bell tolling.
- Ritual: chalking the names before the fleet sails; reading the oath on every deck.
- Saying: "Who lights the dark? We do."

### 2.9 Naming rules

- **People:** old European given names (Anselm, Casimir, Odile, Serafine, Brannoc, Thessaly) plus hard English surnames (Varrow, Harrowgate, Ashdown, Holloway, Blackwood).
- **Titles (Nemesis and story):** Saint, Brother, Sister, Censor, Provost, Votary, Oath-reader, Lector, Arch-deacon, Pilgrim; top titles Crusade-master, High Votary, Lord Censor, Keeper of the Rite.
- **Ship names:** adjective plus a noun of oath, fire, vigil or judgement (Unyielding Oath, Ashen Vigil, Bright Censure, Votive Flame, Judgement Bell). New names avoid song words (hymn, psalm, choir, canticle) and Ithar words (seraph).
- **Avoid:** Inquisitor, Confessor, Templar, Chaplain, Castellan, Litany, Heretic, Imperial, Emperor, Throne, Terra, purity.

### 2.10 Ranks

Captains: Lieutenant, Commander, Captain, Commodore, Fleet captain (shared navy ranks, kept). Admirals: Admiral, Commodore, High Admiral, and the Censor-Captain title for Malek Draven.

### 2.11 Ship classes

`<church object or office>-class <type>`: Warden, Harrow, Penitent, Reliquary, Cathedral, Ascendant (all kept; none is a Battlefleet Gothic class). New hulls: Lantern-class, Tocsin-class, Vigil-class. The arc unlock "Penitent lantern-cruiser" already fits.

### 2.12 Weapons

Fire or penance word plus a plain gun word: **Brand** repeater, **Brand** battery, Heavy **brand** broadside, **Brand** turret, Penance lance, **Cinder** torpedo, Censer flak. Refits: Vigil array, Ward capacitor, Battery loaders, Targeting reckoner.

### 2.13 Places

Beacon-moons named for saints, the Cinder Line, the Ashen reaches, the Hall of the Fallen.

### 2.14 Two alternative takes

| | A. The Lantern Crusade | B. The Oath-Fleet |
|---|---|---|
| Name | The Lantern Crusade (Voidsworn stays the game title) | The Voidsworn Oath-Fleet |
| Identity | Lamplighters of the dark: a crusade whose whole faith is keeping lights burning; less saint, more lighthouse keeper. | Sworn knightly houses rather than a church: oaths, heraldry, debts of honour, no saints at all. |
| Naming | Light words: Wick, Lamp, Ember, Kindle. Sample: Lamp-Captain Odile Varrow, the Wick of Vesper, Kindle battery. | House names and heraldry: Lord-Sworn Anselm of House Ashdown, Dame Serafine Holloway; ships named for oaths (The Third Promise). |
| Look | Brass lantern cages on every spire, warm gold light instead of ember orange. | Heraldic colour bands over black steel, house banners as hull paint. |
| Cost | Retunes the faction's colour; the "Las" rename becomes "Lamp". | Loses saints and the Rite, which the approved story uses. |

---

## 3. Hegemony Navy (name kept)

### 3.1 Who they are

The largest human state in the region, run by the Admiralty at Meridian and by its paperwork. The Hegemony is not cruel; it is correct. It registers worlds, numbers its ships, issues Pacification Orders, and holds losses "within acceptable limits", defined in an appendix of nine pages. Its quiet horror is being counted.

### 3.2 Voice and motifs

Documents, numbers, understatement. Forms in triplicate, timestamps (0340, 0412 ship time), numbered orders (Pacification Order 41), numbered posts (Listening Post K-7). Bureaucracy jokes live here and nowhere else.

### 3.3 Look

- **People:** composed humans in pale grey high-collared uniforms, flat blue enamel rank bars, clean geometric shoulder boards, gloves. No naval caps or sailor uniforms. Faces lit by blue targeting grids.
- **Portrait note:** one Nemesis prompt says "commissar-admiral". Commissar is the Imperial Guard political officer. Use "political officer" or "intelligence admiral".
- **Ships (A4, FAC3D):** light grey hulls (#c4ccd5, shadows #5a6573), steel-blue trim (#3a78d0), blue-white windows (about #c7e5ff) and blue engines and bolts (#73b8ff to #80c8ff). Wedge hulls with flat planes and clean panel lines, rows of identical turrets, ion prongs at the bow, recessed running lights. Ship prefix HNS (Hegemony Navy Ship).
- **Colours in one line:** pale grey, steel blue, white light.

### 3.4 Origin and wants

- Origin: the Registry worlds around Meridian, the Admiralty's seat.
- Want: secure the Hollow Sun as a fleet anchorage. Pacify, register, count.

### 3.5 How they fight

Formation around the flagship. Synchronized fire near the flagship, ion cannons that strip shields, fighter screens from cruisers, cheap backing off (Retro thrusters). The Nemesis brings reinforcements in round 3 and drills his formation tighter.

### 3.6 Captives and the dead

- Captives: processed by regulation, interned or exchanged, entered in the register by number.
- Their dead: name, rank and number on the Roll. The memorial is the list. A commander reading the list on an open channel before a decisive engagement is the one unrecorded tradition.

### 3.7 What they think of the others

- Voidsworn: "Religious irregulars. Useful. Unlicensed."
- Corsairs: "A line item: piracy, ongoing."
- Chorus: "A biological incident, category one."
- Ithar: "A treaty we cannot read."
- Deathless: "They claim prior title to our worlds. Legal is reviewing."

### 3.8 Crest and signature details

- Crest: a wedge in a ring of five stars (kept).
- Sound: a two-note chime before every fleet-wide order.
- Ritual: the unrecorded speech before a decisive engagement.
- Saying: "Losses within acceptable limits."

### 3.9 Naming rules

- **People:** Germanic, Nordic and Dutch given names and surnames (Konrad Reiter, Sanne Achterberg, Gerold Haldane, Katrin Falk).
- **Ships:** HNS plus a steady adjective or an office noun (HNS Steadfast, HNS Resolute, HNS Arbiter, HNS Punctual, HNS Comptroller). New ones may be quietly funny in a clerk's way.
- **Avoid:** Imperial, Executor, Star Destroyer and star-cruiser class words, Vindicator, Castellan, Commissar.

### 3.10 Ranks

Captains: Lieutenant, Commander, Captain, Commodore, Rear admiral (kept). Admirals and Nemesis titles: Line Admiral, Fleet Marshal, Grand Admiral, High Commodore (kept).

### 3.11 Ship classes

Plain role nouns: picket (frigate), cordon (destroyer), vanguard (cruiser), dominion (dreadnought), and the named super-dreadnought The Iron Mandate.

### 3.12 Weapons

Physics noun plus gun noun: Plasma cannon, Plasma lance, Heavy plasma lance, Ion cannon, Picket lasers. Base names under them: Laser cannon, Pulse cannon (was Turbolaser), Heavy pulse cannon.

### 3.13 Places

Administrative and numbered: Listening Post K-7, the gravity shoals of sector II, the Anchorage, Meridian, the Registry.

### 3.14 Two alternative takes

| | A. The Mandate Navy | B. The Concord Admiralty |
|---|---|---|
| Name | The Mandate Navy (the state is "the Mandate"; ties to the boss The Iron Mandate) | The Concord Admiralty |
| Identity | Same counted, correct navy; the name stresses the authority to rule. Avoids Starsector's "Hegemony" (section 9). | A merchant league's navy: insurance, charters, shareholders; war is a contract with penalty clauses. |
| Naming | Same Germanic names; ships "MNS Steadfast". | Company titles: Charter-Captain, Factor, Director; ships named for virtues of trade (CNS Solvent, CNS Due Diligence). |
| Look | Unchanged. | Pale grey with gold company stripes, logos stencilled on hulls. |
| Cost | Every "Hegemony" string (data, story, portraits); the story voice stays. | Retunes the story's Admiralty voice. |

---

## 4. Ashfall Corsairs (name kept)

### 4.1 Who they are

Pirates of the Ashfall dens, a belt of burned-out mining rocks around a dead world, with Rattlehold the biggest and loudest. They fly stolen hulls, bound together by shares, debts and nicknames. They are funny, greedy and loyal to a crew, and every one of them is going to the Hollow Sun because Old Mott's grandmother saw the manifests.

### 4.2 Voice and motifs

Gallows jokes, people's names, money. Shares counted out loud, debts remembered, luck, dents framed. Old Mott is the recurring face.

### 4.3 Look

- **People:** scarred humans, cybernetic red eyes, riveted prosthetic jaws, shaved heads with burn scars, patchwork armour welded from three fleets' plates in clashing colours, stolen medals and torn insignia, grease and rust, boarding axes.
- **Ships (A4, FAC3D, R14):** deliberately asymmetric (K1). Rust-red hulls (#6a2c22, shadows #28140f), rust-orange trim (#a3542c), red-orange engines and bolts (#ff6129, #f2331a). Bolted stolen panels in rust, Hegemony grey, bare steel and bone; mismatched engine pods; one side heavier; rams; salvage bolted on. Haphazard and junky is on-brand.
- **Colours in one line:** rust, blood red, stolen grey, bone.

### 4.4 Origin and wants

- Origin: the Ashfall dens; Rattlehold.
- Want: get there first, get rich, get out, and be a story in the dens.

### 4.5 How they fight

Fast, thin shields, far too many rockets (rocket salvos that point defence can shoot down), scrap guns with an extra wild shot and lucky crits, rams and boarding. No lances (the gate). Cheap sideslips (Bolted burners). The Nemesis raids your credits and flees a losing fight to come back richer.

### 4.6 Captives and the dead

- Captives: ransomed, or offered a berth ("a raider captain asks for a berth").
- Their dead: a drink poured, the dead captain's share paid to whoever they named, their hull scrapped for the crew.

### 4.7 What they think of the others

- Voidsworn: "Holy fools with gold on their altars."
- Hegemony: "Best shipyard in space. They just don't know they're selling."
- Chorus: "Don't get eaten. Don't let anything with teeth board you."
- Ithar: "Pretty ships. Prettier shield shards."
- Deathless: "The only buyers who pay in coin older than the dens."

### 4.8 Crest and signature details

- Crest today: "a skull with a gear for a jaw". **Recommend changing it:** a skull with a cog is the core of the Adeptus Mechanicus emblem (Cog Mechanicus). Pick: **a skull biting a gold coin** (pirates plus money, their two motifs). Option: a grinning skull with a riveted iron jaw (matches Grax's portrait).
- Sound: the cheer when shares are called.
- Ritual: counting shares out loud before a fight (bad luck, so they always do it).
- Saying: "Get there first. Get rich. Get out."

### 4.9 Naming rules

- **People:** a nickname plus a hard surname (Rusty Krogg, One-Eye Mallory, Lucky Sharkey), or a name plus a "the" epithet (Vesh the Collector, Sable Venn the Smiling Knife).
- **Ships:** jokes, debts and luck (Last Laugh, Salt Debt, Widow's Wager, Nine Lives, Black Ledger).
- **Nemesis parts:** harsh one-syllable fronts (Krag, Rusk, Gor, Snag, Skarn) plus body or tool words (Tooth, Maw, Hook, Knuckle, Spur).
- **Avoid:** Ork-isms (Waaagh, Warboss, "-z" plurals, Ork spellings), Ironjaw (Age of Sigmar's Ironjawz), Brannigan (Futurama).

### 4.10 Ranks

Captains: Mate, Skipper, Captain, Reaver-captain, Warlord (kept). Nemesis titles: Reaver-king, Warlord, Scrap-baron, Pirate prince (kept).

### 4.11 Ship classes

Raider, reaver, marauder, hulk-carrier, and the War-barge class (was Battle-barge, the Space Marine flagship type) for the Warlord's Pyre-Barge.

### 4.12 Weapons

Junk or noise word plus gun: Autocannon, Scrap scatter gun, Junk turret, Rattle-rocket pod, Heavy rocket pod, Chaff guns (all kept).

### 4.13 Places

The Ashfall dens, Rattlehold, the Gutter, Blackwater, the rocks.

### 4.14 Two alternative takes

| | A. The Rattlehold Free Captains | B. The Scrapborn |
|---|---|---|
| Name | The Free Captains of Rattlehold | The Scrapborn |
| Identity | Swashbuckling charter of free captains with a pirate code and a vote; more rogue, less thug. | Salvage clans born on hulks: families, not crews; they strip wrecks and live in them. |
| Naming | Captain honorifics and flourishes: Captain Sable Venn, Free Captain Mallory; ships with grand names (The Unpaid Debt). | Clan names and kin words: Mott of Clan Rattigan, Old Mother Krogg; ships are named homes (Grandmother's Kettle). |
| Look | Cleaner stolen hulls, painted gold trim, flags. | Welded habitat hulks, laundry-line cable runs, lights in every window. |
| Cost | Grax and the brute portraits read off-tone. | The approved arc's "dens" voice needs a pass. |

---

## 5. The Chorus (name kept, recommended)

### 5.1 Who they are

A swarm of grown bodies with one appetite. It speaks as "we" because it is many: a chorus in the old stage sense, many voices saying one thing, not singing. Inside the swarm two throats argue, Hunger and Memory. It came from warm shallow sea worlds full of drifting spawn and now hunts between stars. Something warm and very old waits at the Hollow Sun's core: the first meat.

### 5.2 Voice and motifs

- "We". Sentences of nine words or fewer. Taste, heat, smell, teeth. Two throats argue in every beat.
- Never sings. No song words in any Chorus name or line: hymn, psalm, choir, chant, song, verse, melody, canticle.
- Avoid the Tyranid furniture: hive, hive mind, hive fleet, Leviathan, bio-titan, synapse, norn, lictor, gaunt, carnifex, bio-plasma, spore mines, razorfiend.

### 5.3 Look

- **Beings:** alien grown organisms with no face, eyes or limbs. Glistening wet flesh, membrane, chitin, bile, deep-sea biology (the portrait prompts already say this). Admirals: the Matriarch of Nine Throats (nine uneven throat-tubes over a brood mass), Razormaw (a ring of chitin blades round a lure light), Voice of the Deep (a hollow dome of abyssal membrane), the Mending Throng (a living suture-cocoon stitching itself shut).
- **Ships (A4, FAC3D):** grown, not built: ridges, pores, veins and glowing sacs, no panels or pipes. Purple-black flesh (#57364c, shadows #211419), ochre chitin trim (#a4913a), bile yellow-green glow (#d9eb40 range). Bilateral where the body allows, lopsided where it does not (K1). Tendrils, brood sacs, regrowing pink scar tissue.
- **Colours in one line:** bruise purple, ochre bone, bile light.

### 5.4 Origin and wants

- Origin: the warm shallows of sea worlds (the Warm Shallows in the arc).
- Want: eat; grow; remember the taste of everything.

### 5.5 How they fight

No shields at all; flesh regrows every round. Spore swarms in place of wings, boarding tendrils, acid that eats through shields and armour, spines that strip armour, the first turn each round free (Living hull). The Nemesis grows tougher from every ship you lose anywhere, and adapts after every meeting.

### 5.6 Captives and the dead

- Captives: food, or hosts for spawn.
- Their dead: eaten by the swarm. What remains is kept as a smell. "The mines take some of us. We eat those too."

### 5.7 What they think of the others

- Voidsworn: "Hot. Bitter. Loud."
- Hegemony: "Many. Neat. All taste the same."
- Corsairs: "Rust. Salt. Run fast."
- Ithar: "Old. Sweet. Glass in the teeth."
- Deathless: "Not meat. Wrong."

### 5.8 Crest and signature details

- Crest: a ring of nine open mouths (kept).
- Sound: a low wet thrum, like a throat swallowing.
- Ritual: tasting the air before the hunt.
- Saying: "More. Always more."

### 5.9 Naming rules

- **Individuals:** a body or sense adjective plus a body part or tide word: Seventh Mouth, Grieving Tide, Wet Whisper, Hollow Gut, Brine Mouth, Lantern Gut. Single growl words: Moult, Undertow.
- **Ships:** body-horror nouns: Shrieking Coil, Tide of Teeth, Mournful Gut, Gnawing Bloom, Brood-node Vesk.
- **Titles (Nemesis):** Spawn-mother, Elder Throat, Gorge-mind, Brood-queen.

### 5.10 Ranks

Spawn-mind, Brood-node, Throat, Elder throat, Great throat (rank 5 was Matriarch, the admiral's own word).

### 5.11 Ship classes

Grown-role nouns: drone-spawn (frigate), spitter (destroyer), bladeback (cruiser, was razorfiend), brood-mother (carrier), and the boss **The Ninefold Maw**, Colossus class (was Hive Leviathan, Bio-titan).

### 5.12 Weapons

Body part plus action: Spine volley, Boarding tendrils, Spore cloud, Acid sacs (kept). Base names under them: Bile plasma (was Bio-plasma), Spore drifts (was Spore mines).

### 5.13 Places

The Chorus names places by taste and temperature: the Warm Shallows, the Split Node, the Cold, spawning fields.

### 5.14 Why keep "The Chorus"

The name is a song word, and the story rule says the Chorus does not sing. But a chorus in a play is a crowd that speaks as one "we", which is exactly the Chorus register. Keeping it costs nothing and the story already reads that way. The 2021 space shooter "Chorus" (Deep Silver Fishlabs) is a game title, not a faction (section 9). If Ryan wants the song word gone entirely, the options are below.

### 5.15 Two alternative takes

| | A. The Ninefold | B. The Gorge |
|---|---|---|
| Name | The Ninefold | The Gorge |
| Identity | Named for the nine mouths on the crest: nine bodies, nine throats, one hunger. Same as today, without the song word. | One colossal appetite, more coral reef than animal: it grows over worlds and digests them slowly. |
| Naming | Numbers and mouths: the Third Mouth, Ninth Tooth; boss The First Mouth. | Verbs of eating: Gnaw, Swallow, Gulp, Rot; ships named as meals (Last Supper of Om). |
| Look | Unchanged. | Fungal and coral textures, slower, more sessile ships, spore towers. |
| Cost | Every "Chorus" display string, portraits and story; the id stays. | Retunes the look and the swarm play. |

---

## 6. The Ithar (name kept)

### 6.1 Who they are

An old and very few people whose ships are sung into shape from light and glass. They have not named a child in four hundred years. They live in Houses, led by the First Singers, and everything they have ever known is kept by archivists: fussy, exact and grieving. The Hollow Sun was their lamp once, when their House still had a name worth lighting; the light-archive of every House waits at its heart. Every ship is a line of a song that ends with it, and nothing is coming after them to sing the rest.

What makes them theirs and not Aeldari: no fall caused by their own god, no soul stones, no paths, no craftworlds, no seers ruling, no "younger races". Their tragedy is memory: too much of it, kept too carefully, by too few.

### 6.2 Voice and motifs

Memory and past tense, light and glass, long sentences, grief with an archivist's fussy humour (indexes, cross-indexes, footnotes, "filed under unusual"). Song belongs to them alone: lament, choir, chord, verse.

### 6.3 Look

- **Beings:** clearly not human and not elves: elongated skulls on very long slender necks, huge wide-set solid black eyes, pale translucent porcelain skin with glowing gold light channels beneath it, long seven-fingered hands. Armour of glass-like petals. Nothing aquatic.
- **Portrait note:** the Nemesis prompts say "Ithar inquisitor" and "Ithar archon". Inquisitor is 40k; Archon is the Drukhari (dark Aeldari) ruler title. Use "Ithar duelist" and "Ithar house-elder".
- **Ships (A4, FAC3D):** pearl white hulls (#e4ebe7) with darker fittings (#6c8179) so seams read, gold filigree inlay (#d7c88a), soft jade lenses, engines and bolts (#9effd1 range). See-through fanned light sails like stained glass made of light (A4 rebuilt them). Slender, curved, few straight lines. Bilateral.
- **Colours in one line:** pearl, gold thread, jade light.

### 6.4 Origin and wants

- Origin: the lost homeworld whose lamp was the Hollow Sun. The Houses now voyage.
- Want: bring the light-archive home before the short-lived break it open for scrap; be remembered properly, in the right order.

### 6.5 How they fight

Blindingly fast, heavily shielded, fragile once the shields fall. They cannot brace (the gate). Needle beams for precision and crits, star torpedoes that are hard to dodge, phase jumps, starling wings, lances. Fan sails make them harder to hit after moving. The Nemesis is a duelist who keeps range and withdraws to fight again.

### 6.6 Captives and the dead

- Captives: interviewed, recorded in full, then released, or kept as guests until their story is filed.
- Their dead: a ship's last song is recorded into glass; the fleet dims its running lights; a mourning lamp is lit.

### 6.7 What they think of the others

- Voidsworn: "They want to relight our lamp. They will need instructions."
- Hegemony: "They file things. We approve, cautiously."
- Corsairs: "They steal our shield shards and sell them back to us."
- Chorus: "It eats songs. Do not let it hear you."
- Deathless: "They remember longer than we do and feel nothing about it. That is unforgivable."

### 6.8 Crest and signature details

- Crest: a single sail over a falling star (kept).
- Sound: glass ringing faintly when starlight touches it.
- Ritual: the lament sung over a wreck (the Glass Choir).
- Saying: "There will be another hour."

### 6.9 Naming rules

- **People:** soft, liquid names of two or three syllables, rich in l, r, th, y, ae, ending -iel, -une, -wyn, -ith, -en (Siriel, Saelune, Ilyra, Faewyn, Caelis). Surnames are compounds of light, sky and glass (Starglass, Moonreach, Silverwake, Glasswing).
- **Titles:** Seraph, High seraph, Starwarden, Wing-lord, Duelist; Houses: "House of the Ninth Lamp".
- **Ships:** light, dusk and grief (Morningveil, Silver Lament, Glass Requiem, Farlight, Petal Storm). Song words welcome here.
- **Avoid:** Farseer, Autarch, Exarch, Archon, Eldrad, craftworld, wraith-, spirit stone, shuriken, pulsar, "younger races", Farsight.

### 6.10 Ranks

Wing, Sail, Seraph, High seraph, Starwarden (kept).

### 6.11 Ship classes

Wisp (frigate), shadowblade (destroyer), songship (cruiser), cradleship (carrier, was wraithcarrier), and the Worldsong Ark.

### 6.12 Weapons

Light or glass word plus a form: Prism shards, **Chord** lance (was Pulsar lance), Star torpedo, Needle beam, Mirror veil. Base: Shard cannon (was Shuriken cannon). Refits: Dawnglass spine, Longsight crystal, Shard hoppers, Archivist's eye.

### 6.13 Places

The Glass Choir (a field of crystal wrecks that still ring), lamp-buoys, the Grave of Houses, the hall of the First Singers.

### 6.14 Two alternative takes

| | A. The Ithar Houses | B. The Glasswrights |
|---|---|---|
| Name | The Houses of Ithar | The Glasswrights |
| Identity | Rival noble archive-Houses who feud over whose memory is correct; politics, not just grief. | Makers, not singers: their ships are cut and polished, their pride is craft; the song becomes a tuning. |
| Naming | "of House X" on every name: Aelith of the Ninth Lamp; titles House-elder, Heir. | Craft words: Master Cutter Vaelen, Polisher Nyssa; ships named for techniques (Fine Bevel). |
| Look | House sigils etched on sails, each House a different sail tint. | Faceted crystal hulls instead of pearl, more prism flare. |
| Cost | Small; fits the arc ("Grave of Houses"). | Loses song, the faction's motif; the arc needs a pass. |

---

## 7. The Deathless Court (renamed from "The Deathless Dynasty")

### 7.1 Who they are

A court of machine minds that held these sectors before the living came. Long ago its session was adjourned and the Court went down into sealed vaults beneath dead worlds, the first Court beneath the Hollow Sun. Its record lists every holding, every seal, every trespass. Now it wakes by writ, rank by rank, as the law prescribes, to resume the session and correct the occupants. It does not hate. It adjudicates. It cannot forgive a broken law, and it forgets nothing.

### 7.2 Voice and motifs

- Law and record, polite contempt, no feeling words. Writs, warrants, seals, summons, sentences, the record, "entered", "noted", "corrected".
- The Court is ancient law and ceremony; the Hegemony is modern paperwork and numbers. No bureaucracy jokes here (no forms, no triplicate, no appendices).
- Avoid every Necron tell: tomb, tomb-world, dynasty, dynast, phaeron, overlord, cryptek or cryptlord, necropolis, living metal, gauss, doom, scarab, canoptek, monolith, obelisk, phylactery, reanimation protocols, crowns and thrones, Egyptian names and the ankh, "squatters" on old crownworlds.

### 7.3 Look

- **Beings:** no humanoid body and no skeleton. A Deathless mind is a monumental broken ring of bone-white ceramic computation plates and black metal around a cold green core, its sensor lights in place of a face, its cracked segments floating apart and being refitted by small attendant drones with thin green beams (the Nekhet portrait prompt; keep this, it is the faction's best original idea).
- **Portrait note:** three Nemesis prompts lean Necron: "black obelisk processors", "thousands of tiny black beetle-shaped drones" (scarabs), "a sarcophagus-shaped machine". Use "a cluster of black record-stacks orbiting a green core", "a swarm of tiny attendant drones", "a sealed vault door split open".
- **Ships (A4, FAC3D):** black hulls (#2c3431, shadows #121715) with terminal-green trim and light (#1fbf4a, glow #33ff59 range). Bilateral. Phase drive: no flaming engine bells, a cold green shimmer, and they pass through rocks and wrecks. Today's A4 dressing is "carved ossuary: rib bands, carved glyph panels, vertebra knobs, green slits" (tools/blender/a2detail/dress.py:9). Bone ribs with green light sits close to the Necron look. **Weigh-in for Ryan, low priority:** on the next dressing pass, read the same parts as a court of record (glyph panels become columns of record script, rib bands become vault bands, fewer vertebra knobs, seal rings at hard points). No rebuild needed now.
- **Arc paint:** Court Gold (obsidian with gold inlay; the glow turns from vault green to gold).
- **Colours in one line:** black stone, green record-light, court gold.

### 7.4 Origin and wants

- Origin: the vaults beneath dead worlds; the first Court beneath the Hollow Sun; "the old holdings", three sectors now occupied by the living.
- Want: clear the processional route, resume the session, enter every trespass and collect the debt.

### 7.5 How they fight

No shields, heavy armour, and the dead get up again: an endless legion where every hull reassembles once. Flux weapons ignore half of armour; the verdict arc lands one heavy blow every other turn. Phase drive goes through rocks, wrecks and ships. The Nemesis is patient (his clock moves at half speed), never retreats, comes back once after he is killed, and when his clock fills the hunt drains hull from your whole fleet.

### 7.6 Captives and the dead

- Captives: entered in the record as exhibits, or as guests awaiting a hearing. Hearings take centuries ("The hearing is expected to take several centuries").
- Their dead: not dead, reassembled; a hull that cannot be rebuilt is entered as "adjourned".
- Enemy dead: catalogued, and entered as the session's exhibits.

### 7.7 What they think of the others

- Voidsworn: "Petitioners who never filed."
- Hegemony: "A junior jurisdiction. Its forms are adequate."
- Corsairs: "Repeat offenders."
- Chorus: "An unlicensed appetite. It has no standing."
- Ithar: "Former neighbours. Their claim has lapsed."

### 7.8 Crest and signature details

- Crest: an open eye above a sealed vault door, a seal ring between them (story, kept).
- Sound: three slow low tones, like a seal pressed into stone, before the first volley.
- Ritual: the writ read aloud to the legions before battle: the offender's name, the hour of the offence, the penalty.
- Saying: "The law permits either. It forgets neither."

### 7.9 Naming rules (pick: the court tongue)

- **Sound:** a worn, stately tongue built from Old English and Norman-French roots of the age of courts and charters. Two or three syllables. Firm onsets (H, S, Th, M, G, C, B, Or). Endings -ane, -ric, -mont, -aunt, -ance, -isant, -ard, -cred, -gar.
- **Examples:** Halvane, Aumery, Morvaunt, Gaudry, Orrance, Sedric, Thurstan, Belisant, Tancred, Ermengarde, Osmont.
- **Title pattern:** office plus name plus legal epithet. Offices: Bailiff, Assessor, Recorder, Magistrate, Chancellor; top Nemesis titles Lord Chancellor, High Magistrate, Master of Rolls, Lord Recorder. Epithets: the Unpardoning, of the Quiet Writ, the Abiding, the Adjourned, of the Ninth Vault, the Undying.
- **Admirals:** Chancellor Aumery the Undying, Magistrate Morvaunt the Reaper, Gaudry of the Quiet Writ, Orrance the Abiding.
- **Sample rival:** High Magistrate Halvane the Unpardoning (was Justiciar; see 8.6).

### 7.10 Ranks

Bailiff, Assessor, Recorder, Magistrate, Chancellor (was Warden, Overseer, Cryptlord, Overlord, Dynast).

### 7.11 Ship classes

Instruments of a court, rising in authority: **writ** (frigate, was scythe), **warrant** (destroyer, was jackal), **edict** (cruiser, was harvester), and the flagship **The Unadjourned**, Vault-ark class (was The Undying Throne, Tomb-ark). Variants: Writ sentinel, Turret edict, Honour-guard warrant (arc unlock). Scythe, Jackal and Harvest Ship are all Battlefleet Gothic Necron classes (lexicanum), so the whole ladder has to change.

### 7.12 Weapons

The **Flux** family for the guns (Flux cutter, Flux sentries, Flux spire, Flux shredder; kind label Flux), and a court word for the signature cannon: **Verdict arc**. Refits and relics: Vault-iron plating, Recorder's sight, Phase engine, Seal-ward node, Repair attendants, Attendant bay, Seal of the first Court, Deathless reprieve (revives your first lost ship), Session clock, Annals of the Court.

### 7.13 Places

Vaults and vault-worlds, the processional route, the old holdings, the Ninth Vault, the Sunless Court.

### 7.14 Run word

Today a Deathless run is a "reclamation". Reclaiming worlds is a Necron theme. Pick: **assize** (a court travelling its circuit to try cases: exactly what the run is). Option: session.

### 7.15 Two alternative takes

| | B. The Barrow Court (stream B's draft) | C. Egyptian, lightly renamed |
|---|---|---|
| Name | The Deathless Court | The Deathless Court |
| Identity | Grave-mound kings of an old northern style (think Sutton Hoo): barrows, urns, sleeping royal courts. | Today's Egyptian-coded kings with the closest names swapped. |
| Naming | Old English kings: Aldmar, Halric, Esma, Morcant, Wulfmar; titles Regent, Barrow-king, Ash-king, Dust-sovereign; "barrow-world", "Barrow-ark". | Hotenra, Sethren, Amuneth; titles kept minus Overlord, Cryptlord, Dynast. |
| Look | Rust-gold grave goods on black hulls, urn shapes. | Unchanged. |
| Against | Brings back kings and crowns the story removed (the crest lost its crown in S-2); Tolkien barrow-wights and Skyrim's barrow draugr sit nearby. | Still reads Necron: "Egyptian undying machine kings" is the Necron signature, and all four story reviewers flagged it. |

---

## 8. The big calls, with options (pick marked)

### 8.1 Deathless naming family

| Option | Sample | For | Against |
|---|---|---|---|
| **A. Court of record (PICK)** | Chancellor Aumery the Undying; ranks Bailiff to Chancellor; hulls writ, warrant, edict; vault-worlds | Matches the approved story (writs, seals, vaults, the Court); no kings; furthest from Necron | Legal words are less "spooky" than tombs |
| B. Barrow court (stream B) | Dust-sovereign Aldmar; barrow-worlds | Ancient and eerie | Kings and crowns come back; Tolkien and Skyrim nearby |
| C. Egyptian, lightly renamed | Hotenra, Sethren | Cheapest | Still Necron |

### 8.2 Deathless hull ladder

| Option | Frigate / destroyer / cruiser / flagship | Note |
|---|---|---|
| **A. Court instruments (PICK)** | writ / warrant / edict / The Unadjourned | Rising authority; odd and memorable in the log ("Deathless warrant destroyed") |
| B. Court officers | tipstaff / bailiff / assessor / The High Bench | Clashes with the rank names |
| C. Plain | sentinel / lancer / reclaimer / The Undying Bench | Safe, forgettable |

### 8.3 Faction names

| Faction | Options (pick first) |
|---|---|
| Deathless Dynasty | **The Deathless Court (PICK)**, The Sealed Court, The Undying Bench |
| The Chorus | **Keep (PICK)**, The Ninefold, The Gorge |
| Hegemony Navy | **Keep (PICK)**, The Mandate Navy, The Concord Admiralty (only if Starsector's Hegemony bothers you) |
| Voidsworn Crusade, Ashfall Corsairs, The Ithar | **Keep (PICK)**; alternatives in each faction's section |

### 8.4 Most visible weapon renames

| Old | Options (pick first) |
|---|---|
| Las-repeater, Las-battery, Las-turret | **Brand (PICK)**, Ember, Lamp |
| Hellfire torpedo | **Cinder torpedo (PICK)**, Pyre torpedo (clashes with the Pyre-Barge), Brand torpedo |
| Gauss flayer (and the Gauss kind) | **Flux cutter (PICK)**, Severing ray, Null cutter |
| Doom arc | **Verdict arc (PICK)**, Ruin arc (stream B), Sentence lance |
| Pulsar lance | **Chord lance (PICK)**, Dawn lance (stream B), Prism lance |
| Shuriken cannon | **Shard cannon (PICK)**, Glass cannon, Splinter cannon |
| Nova cannon | **Sunburst cannon (PICK)**, Spinal cannon, Hammer cannon |
| Hive Leviathan | **The Ninefold Maw (PICK)**, Brood Colossus (stream B), The Gorging Deep |

### 8.5 Most visible rank and title renames

| Old | Options (pick first) |
|---|---|
| Inquisitor-Captain Malek Draven | **Censor-Captain (PICK)**, Oath-Captain, Witness-Captain |
| Admiral Castellan Vex | **Admiral Severin Vex (PICK)**, Admiral Provost Vex (stream B), Lord-Admiral Vex |
| Deathless ranks Cryptlord, Overlord, Dynast | **Bailiff, Assessor, Recorder, Magistrate, Chancellor (PICK)**; barrow set Thane, Reeve, Warden, Regent, Barrow-king; mixed set Custodian, Assessor, Warden, Regent, Sovereign |
| Overlord Nekhet the Undying | **Chancellor Aumery the Undying (PICK)**, Dust-sovereign Aldmar the Undying (stream B), Hotenra the Undying |

### 8.6 The sample rival "Justiciar Halvane the Unpardoning"

Ryan said the name is fine for now (R47). Two facts for the final call: "Justicar" (one letter shorter) is the Grey Knights squad-leader rank and a class in Chaos Gate: Daemonhunters; "Justiciar" itself is a real medieval English office. Options: **High Magistrate Halvane the Unpardoning (PICK)**, keep Justiciar, Lord Chancellor Halvane the Unpardoning. "Halvane" and "the Unpardoning" fit the court tongue as they are.

### 8.7 Smaller calls Ryan may want to see

- **Song words outside the Ithar:** the patron "The Ember Choir" (boons Choir Warheads, Hymn of Reloading) and the Chorus admiral "The Mending Choir". Pick: The Ember Host and The Mending Throng. Keep if you like the sound; they are not 40k.
- **Grax Ironjaw** (Age of Sigmar's Ironjawz) and **Old Mott Brannigan** (Futurama's Zapp Brannigan): not 40k. Pick Grax Steelgrin and Old Mott Rafferty; easy to keep.
- **Star Wars echoes** in the Hegemony (Turbolaser, Interdictor, star cruiser, star dreadnought, Hyperdrive motivator, Durasteel, Proton, HNS Executor): pick rename (rename_map.md section 10).
- **Corsair crest** (skull and gear): pick a skull biting a gold coin.
- **Deathless ship dressing** reads "ossuary": steer the next pass toward "court of record" (7.3).
- **Mild Ithar seer words** (Seer's sight, Seer's eye, the Ithar seer event): pick archivist, which the story already uses.

---

## 9. Collision checks (what I searched, Oct 26 2026)

Web searches run for this pass (results linked):

| Checked | Finding | Verdict |
|---|---|---|
| Deathless scythe, jackal, harvester | Battlefleet Gothic Necron classes: Scythe Class Harvest Ship, Jackal Class Raider (lexicanum: https://wh40k.lexicanum.com/wiki/Scythe_Harvest_Ship, https://wh40k.lexicanum.com/wiki/Jackal_Class_Raider) | Rename all three |
| Chorus razorfiend | Tyranid Razorfiend Cruiser (https://wh40k.lexicanum.com/wiki/Razorfiend_Cruiser) | Rename |
| Ithar ship words | Eldar classes include Shadow, Hellebore, Solaris, Wraithship (https://wh40k.lexicanum.com/wiki/Shadow, https://wh40k.lexicanum.com/wiki/Hellebore_Frigate) | "Wraith" goes; "shadowblade" and "songship" kept (no class of that name) |
| Justiciar | Grey Knights Justicar, and a Chaos Gate: Daemonhunters class (https://www.chaosgate.com/daemonhunters/news/justicar-build-guide-aspect-aegis) | Weigh-in (8.6) |
| Custodian | Adeptus Custodes Custodian Guard and Custodian Wardens (https://www.warhammer-community.com/en-gb/articles/LRraZYf4/starting-an-adeptus-custodes-army-in-warhammer-40000-everything-you-need-to-know-from-painting-to-lore/) | Mild: story "custodian" to "vault-keeper" |
| Ironjaw | Age of Sigmar Ironjawz (https://www.warhammer-community.com/en-gb/articles/tuxs19Pq/warhammer-age-of-sigmar-faction-focus-ironjawz/) | Mild, Ryan's call |
| Corsair crest (skull and gear) | Search inconclusive; from knowledge, the Adeptus Mechanicus emblem is a skull, half machine, inside a cog | Recommend change |
| "Voidsworn" | No game, faction or mark found (nearest: Gloomhaven's "Voidwarden", Deepwoken's "Voidwalker") | Game title safe |
| "The Deathless Court" | No game faction found (nearest: Choice of the Deathless, Peter Newman's novel The Deathless) | Safe |
| "Ithar" | No game or novel race found | Safe |
| "The Chorus" | Chorus (2021) is a Deep Silver Fishlabs space shooter, title only (https://gameinformer.com/preview/2021/09/23/chorus-looks-to-reinvent-the-space-shooter) | Keep; note it |
| "Hegemony" | The Hegemony is a major faction in Starsector, a space fleet game (https://starsector.wiki.gg/wiki/Hegemony); also a common word (Mass Effect's Batarian Hegemony) | Keep; alternative listed |
| "Ashfall" | Ashfall is a NetEase shooter title | Keep as a place name |
| Verdict arc, Flux cutter | "Flux Weapons" in the Lost Souls MUD; "Verdict" is a Helldivers 2 pistol and a Destiny weapon (single words) | No collision for the pairs |
| Chord lance, Brand battery, Cinder torpedo | Nothing | Safe |
| The Ninefold Maw, The Unadjourned | Nothing | Safe |
| Cradleship | Nothing in games | Safe |

From knowledge, not re-searched (well known): Hive Fleet Leviathan, Gauss flayer, Doom(sday) Ark, Canoptek Scarabs, phylactery, Phaeron, Dynasty, Overlord, Cryptek, tomb world, living metal, Inertialess Drive, quantum shielding, Chronometron, Imotekh, Sautekh, Shuriken cannon, Pulsar lance, Wraithbone, Farsight, Archon, Nova Cannon, Macro battery, void shields, Battle Barge, auspex, cogitator, astropath, warp, archeotech, xenos, Inquisitor, Castellan, Templar, Chaplain, Commissar, Vindicator, ceramite, Iron Hands, Purifiers (Grey Knights and StarCraft), pylon (StarCraft), Executor and Interdictor (Star Wars), Zapp Brannigan (Futurama).

Not checked: trademark registries (USPTO, EUIPO). If the game goes to Steam under its own name, a registry search on "Voidsworn" before launch is the step I would add.
