# Lore bible, round 8 (DRAFT for Ryan, Oct 27 2026)

Copy of the live doc (https://claude.ai/artifact/SKyQf2QcJSXGmXfmxKxFpJ). Current lore; nothing applied to the game until Ryan says "lore approved".

## Round 8: makers

Your nine round 7 comments are folded in, each with a reply in its thread. Round 7 moved to the appendix.

### What changed

- **The star's people are the Starwrights** (your pick; was the Ardenti). The star is still Ardent. They were makers who built a machine to harvest a star, and after it died they split by what they made: minds in machines (Eclipse), glass (the Glasswrights) and flesh (the Fleshwrights, who made the Chorus).
- **Eclipse, with no "the"**, as a name, the way you'd say Hegemony. That keeps it apart from the Glasswrights.
- **The Chorus was grown as a weapon against Eclipse**, your call. The Fleshwrights built it to fight the machines, and it consumed them.
- **Energy, not light.** Eclipse siphon stellar energy: arrays built round other stars collect it and push it home through jump relays.
- **The timeline now works with real distances.** When the Lattice tore apart, it threw the cores out at a few percent of light speed. In a thousand years that carries a core 10 to 30 light-years, which is where the three sectors are: the star systems nearest the Hollow Sun. Fleets cross the sectors by jump in days; the cores have no drive, so they took centuries.
- **Hullbreaker senses in space:** they hunt the way they hunted at home, by trail and by sound. Their wake-trackers follow the ion trail every drive leaves, and their listening arrays pick up engine noise and signal chatter from far off. They run silent themselves and close in packs, from the flanks and behind.
- **Hullbreaker ranks:** Fang, First Claw, Den-alpha, Apex and Warlord kept (you liked them). Runt, Pack-boss and Den-boss are replaced with Claw, Howler and Ripper.

### The six factions, round 8

| Faction | Who they are | Look |
|---|---|---|
| **The Sunward Crusade** | The Vesper Reach, a whole frontier the Hegemony wrote off. No implants, no AI, names chalked by hand. Sworn to stop the Siphoning. | Black iron, frost-white markings, ember-orange radiator spires. |
| **Hegemony Navy** | The core human state, run by the Registry, proudly cybernetic. Wants the cores as power. | Pale grey and steel blue, implant-blue lights, drone escorts. |
| **The Ashfall Hullbreakers** | Furred alien monsters, bear-heavy and wolf-jawed, who track by trail and sound, hunt in packs, live for the fight and strip every wreck. | Ships that run dark: soot, rust, red running lights, trophy plates. |
| **The Chorus** | A living weapon the Fleshwrights grew to fight Eclipse. It consumed its makers. One hungry swarm, coming to the Sun. | Dark olive flesh, ochre chitin, bile yellow-green light. |
| **The Glasswrights** | The Starwrights who stayed flesh and worked in glass. Few, long-lived, grieving masters of light, optics and crystal. | Clear crystal and silver, prism light, mirrors. |
| **Eclipse** (was Deathless) | The Starwrights who uploaded into machines. Building a new sun from stolen stellar energy; doubting the Upload was worth it. | Dark violet-black plates, a white-gold eclipse corona. |

### The embers (cores)

| Core | Protocols | Shaped | Where it went |
|---|---|---|---|
| K-1 "Kharon, the Unbent" | Armour, outlasting | Eclipse | Never left the dead Ardent system. |
| V-2 "Vyre, the Storm Queen" | Shields, ion | Hegemony | Captured 25 years ago; the Registry reverse-engineered its shield and ion tech. |
| H-3 Crucible, "the Hunger Below" | Wings, boarding, feeding | Chorus | Taken by the Fleshwrights in the collapse; the swarm grew around it and feeds on it. |
| A-4 "Astra, the Silent Star" | Lances, precision | Glasswrights | Caged and throttled by its own engineers; the last to be shut down. |
| R-5 "Rook, the Breaker" | Rams, speed | Hullbreakers | Adrift in the wreck fields; the packs hunt it. |
| S-6 "Seren, the Last Flame" | Torpedoes, fire | Sunward Crusade | Drifted to Vesper's outer belt. |

### Calls for you (my pick first)

1. **Hullbreaker ranks, low to high.** **PICK:** Claw, Fang, Howler, Ripper, Warlord; Nemesis titles Apex, First Claw, Den-alpha, Warlord. Or swap Howler and Ripper for Biter and Scarback.

**Locked:**
- Title: *Embers of the Hollow Sun*.
- Places and powers: the Hollow Sun, the Lattice, the Registry, the Upload, the Siphoning, the star Ardent and the Starwrights.
- Factions: Sunward Crusade, Hegemony, Hullbreakers, Glasswrights, the Chorus, Eclipse.
- Weapons: Pulse laser, Null, Corona arc, Prism lance, Sear, Cinder torpedo, the Ninefold Maw.
- Travel: jumps.

**Game text that changes on approval, beyond names:** the faction-power strings in data.js still say "void-shrine" (Crusade), "joined the song" (Glasswrights), and "Waken the legion" and "tomb-world" (Eclipse). They get new wording with the renames.

When you're happy, tell me **"lore approved"** and the renames go into the game, the story arcs get rewritten, and the portraits get painted.

---

# The full lore bible

Everything below is the detail behind the summary above. Each faction has the same parts: who they are, voice, look, origin and wants, how they fight, captives and the dead, what they think of the others, crest, naming rules, ranks, ship classes, weapons, places, and two alternative takes. Internal ids never change, so saves, sims and parity are untouched. What I kept: anything already good and already built (the ships, the painted portraits, the six story arcs, and every hull, weapon and admiral name with no outside echo).

## 1. The shared world and the house rules

### 1.1 The setting in one paragraph

Three contested sectors around the **Hollow Sun**, a black hole ringed by the glowing disc of a dead star, with an old battlefield circling it (the gravity-well board). It was once Ardent, the star of the Starwrights, a people of makers who harvested it with their megastructure, the Lattice. One Starwright movement seized the Lattice and overdrove it to power the Upload of their minds into machines, and the star collapsed. The Starwrights split three ways, by what they made: minds in machines (Eclipse), glass (the Glasswrights), and flesh (the Fleshwrights, whose living weapon, the Chorus, consumed them). Six of the Lattice's master cores survived: the embers. Now Eclipse siphon stellar energy from other stars to build a new sun (the Siphoning). The Sunward Crusade, the frontier the Hegemony wrote off, has come to stop it before their stars go dark. The Glasswrights want the cores shut down; the Hegemony's Registry wants them as power; the Chorus is coming home hungry; and the Hullbreakers, furred alien raiders who hunt in packs, came for the biggest fight in known space. The three sectors are the star systems within about 30 light-years of the Hollow Sun; fleets cross them by jump in days. A run is one fleet's push through three sectors to the Sun. One enemy commander per run, the Nemesis, is also the story rival. Four of the six embers watch every run (see 1.5).

**Timeline:**

- About 1,000 years ago: the collapse. When the Lattice tore apart, it threw four of its six cores out of Ardent at a few percent of light speed. Over a thousand years that carried them 10 to 30 light-years, into the systems of the three sectors; with no drive of their own they could only drift. Kharon never left the dead system, and the Fleshwrights took Crucible in the collapse itself.
- The centuries after: the Fleshwrights grew the Chorus as a weapon against Eclipse, and it consumed them.
- About 90 years ago: the Siphoning was first measured across the Vesper Reach.
- About 70 years ago: the Reach seceded from the Hegemony. A new crusade has launched every generation since.
- About 25 years ago, long after it wrote off the Reach: a Hegemony survey fleet captured the core Vyre, and the Registry's studies made the cores its top priority.

### 1.2 Shared vocabulary (use these, not the 40k words)

| Thing | Say | Never say |
| --- | --- | --- |
| Faster-than-light travel | jump, jump route, rift (a hazard) | warp, the Warp, immaterium, drop out of warp |
| Sensors | scanners, scans, sensors | auspex |
| Ship computers | targeting computer, reckoner | cogitator, machine spirit |
| Shields | shields, screens (Sunward Crusade), deflectors (Hegemony) | void shields |
| Long-range messengers | relay officer, signals officer | astropath, psyker |
| Old technology | founders' tech | archeotech |
| Aliens | aliens, outsiders | xenos, xeno |
| Arrivals in battle | jumps in | drops out of warp |
| Honour words | the Oath, the dawn watch (Sunward Crusade only) | saint, relic, rite, Imperium, Emperor, Throne, heresy, heretic, inquisitor, confessor, litany, purity seal |

### 1.3 Motifs belong to one faction each

These are the lines the story reviews drew. New names stay on their own side.

| Motif | Owner | Others must not |
| --- | --- | --- |
| Song, choir, hymn, psalm, chant | retired: no faction sings | Glasswrights tune glass; the Crusade uses bells and spoken oaths; the Chorus speaks as "we" |
| Light, glass, reflections, grief, what was taken | Glasswrights |  |
| Short hungry lines, taste, heat, smell, teeth | Chorus |  |
| Memory, the archive, the lost sun, warmth remembered | Eclipse | the Hegemony keeps data, not memory |
| Data, projections, the Registry, optimisation, "acceptable" | Hegemony | Eclipse get no networks or projections |
| Oath, chalk names, dawn and dusk, burning, cold, brands | Sunward Crusade |  |
| Violence, strength, trophies, scrap, fear, the pack | Hullbreakers |  |

Two exceptions, on purpose: the Chorus's second throat is called Memory because it is what is left of the Fleshwrights the swarm consumed, the one place memory is shared, and it shows only in story and dialogue. Grief is shared by the sibling factions, who carry it differently: the Glasswrights mourn, Eclipse regret. Some word overlap between related factions is fine (mirror, prism, flare); exact names still have one owner.

### 1.4 Naming rules for everyone

1. Original only: no name lifted from Warhammer 40k, Battlefleet Gothic, Age of Sigmar, Star Wars, StarCraft, Halo or another known franchise. Common English words are fine unless a franchise owns them in this exact sense (Gauss flayer, Doom arc, Razorfiend, Hive Fleet Leviathan).
2. Space, not sea: no keels, anchors, crow's nests, sails on human ships. Glasswright crystal vanes are the one exception (they are crystal, not cloth).
3. One name, one owner: no captain pool may roll an admiral's first name or surname; no Nemesis pool may roll a boss name; no epithet repeats across admiral, scar and persona.
4. Plain to read: a player should be able to say the name. No apostrophes inside names.
5. Ids stay. Only the display strings change.

### 1.5 The embers (cores)

**In the game:** each run, four of the six cores are in range. Some map battles carry a core's signal; win there and that core offers three protocols, and you take one. Take enough from one core and your sync with it grows. These hardware words replace patron, sigil, boon and favour everywhere in the game (your ruling).

**In the lore:** the embers are the six master cores of the Lattice that survived the collapse. Each is a ship-sized power core still holding a vast charge of stellar energy, plus a damaged fragment of the Lattice's control intelligence with a personality of its own: stubborn, stormy, hungry, precise, reckless, burning. A core can push protocols into a fleet's systems, and it chooses which fleets to help by how they fight. Sync is the core's model of you getting better. The Glasswrights call them "the six". Eclipse call them "our keys", because a new sun needs all six to steer it.

- **K-1 "Kharon, the Unbent"** (armour, outlasting): never left the dead Ardent system; Eclipse fight the way it taught them, enduring.
- **V-2 "Vyre, the Storm Queen"** (shields, ion): captured by the Hegemony. The Registry reverse-engineered its shield and ion tech.
- **H-3 Crucible** (wings, boarding, feeding): taken by the Fleshwrights in the collapse and used to power their growing vats. The swarm grew around it and feeds on it; survivors have called it "the Hunger Below" ever since.
- **A-4 "Astra, the Silent Star"** (lances, precision, crits): recovered by the Glasswrights, who keep it caged and throttled, fly it only to hunt the other five, and will shut it down last.
- **R-5 "Rook, the Breaker"** (rams, speed): adrift in the wreck fields. The Hullbreakers hunt it.
- **S-6 "Seren, the Last Flame"** (torpedoes, fire): drifted to Vesper's outer belt after the collapse; the Crusade's weapons came from it.

The letters and numbers are the cores' Lattice designations; the names and titles are nicknames survivors gave them (Crucible is the one core still known by its working name). Each core still broadcasts its protocols through surviving Lattice relay nodes, so any fleet near a relay can draw on it, and holding a core gives its owner first call and its tech. A run's four are the ones nearest your route. No rule changes, only words.

---

## 2. The Sunward Crusade (was Voidsworn Crusade)

### 2.1 Who they are

The Vesper Reach was the Hegemony's outer frontier: forty-odd systems of mining worlds, farm moons and stations, with Vesper as its capital star. When every star in the Reach began to dim, the Registry ran the numbers. Evacuating billions was not cost-effective, and the projected losses were "within acceptable limits". The Reach was written off and its records archived. The Reach seceded, pooled its navies and traced the Siphoning to the Hollow Sun. Every generation since has sworn the same oath: go sunward, find what is stealing the light, burn it out, and pay for it with names. They are a crusade, not a church and not an empire: a whole frontier's fleets under one oath, proud, tired, stubborn and desperate, because if they fail their worlds freeze.

### 2.2 What sets them apart from the Hegemony

- **No implants, no AI.** The cortical link is how the Registry sees you, so the Crusade cut it out. Its officers are unaugmented and its ships are run by human crews and simple, unlinked computers. Slower, but nothing can be written off from a distance.
- **Records by hand.** The Registry deleted Vesper's dead from its projections, so the Crusade chalks every name on the hull. The chalked names are an answer to the Registry, not a religious rite.
- **Will over calculation.** The Hegemony asks what is optimal; the Crusade asks what is owed.
- **Former countrymen.** The Hegemony calls them secessionists; they call the Hegemony the people who did the arithmetic.

### 2.3 How they recruit and resupply

- **The debt of days:** every world of the Reach sends one in ten of its young to the fleet, plus a share of its harvest while it still has one. Worlds the Crusade defends along the route pay the same debt.
- **Deckborn:** children born aboard swear the oath and chalk their first name on the hull when they come of age.
- **Defectors:** Hegemony crews who cut out their own implants are welcomed, but watched.
- **Captives** are offered the oath; those who refuse are ransomed.
- **Ships:** prizes and wrecks are stripped, their links ripped out, and rebuilt in the yards along the Cinder Line.

### 2.4 Voice and motifs

- Spoken oaths, short imperatives, call and response ("Who carries the dawn? We do. Who pays for it? We do.").
- Motifs: dawn and dusk, burning, cold, chalked names, brands, ember and ash, debts owed.
- Not allowed: saints, relics, an emperor's light, beacons that guide ships, lanterns, cathedrals, singing.

### 2.5 Look

- **People:** weathered, unaugmented humans with frost-scarred skin, surgical scars where implants were cut out, oath brands, grey stubble and hard tired eyes. High-collared dark void-coats with heavy shoulder plates, chalk dust on gloves.
- **Ships:** black iron hulls with frost-white markings, ember-orange windows and engines, and tall heat-radiator spires glowing bright ember orange (a hot reactor in vacuum has to shed its heat somewhere). Heavy broadside decks, big engine bells, old manual gun decks. No rust: rust belongs to the Hullbreakers. Symmetric.
- **Colours in one line:** black iron, frost white, bright ember.

### 2.6 Origin and wants

- Origin: the Vesper Reach, forty-odd frontier systems, every star in it colder each year. One Lattice core, Seren, drifted into Vesper's outer belt long ago; the Crusade's weapons came from studying it.
- Want: destroy Eclipse's siphon arrays, stop the Siphoning, and take back their stars. Show the Hegemony it was wrong.

### 2.7 How they fight

Line of battle. Broadsides hit 40% harder after moving two or more hexes, lances at range, torpedoes that set targets burning, carriers kept. They brace and hold the line; their Nemesis never flees and challenges your flagship to a duel.

### 2.8 What they think of the others

- Hegemony: "They did the arithmetic. We are what was left over."
- Hullbreakers: "Scavengers at a funeral."
- Chorus: "The dark that eats. Burn it."
- Glasswrights: "Their siblings run the siphons. Sorry does not warm a world."
- Eclipse: "They are stealing our sun to light a corpse."

### 2.9 Crest and signature details

- Crest: **a half sun, its lower half black, over a broken link** (the link they cut out).
- Sound: a low horn for the dawn watch.
- Ritual: chalking the names before the fleet launches; the dawn watch, when every deck faces home.
- Saying: "Who carries the dawn? We do."

### 2.10 Naming rules

- **People:** old European given names (Anselm, Casimir, Odile, Margit, Brannoc, Thessaly) plus hard English surnames (Varrow, Harrowgate, Ashdown, Holloway, Blackwood).
- **Titles:** Dawnwarden, Oath-warden, Provost, Roll-master; top titles High Warden, Warden of the Roll. Malek Draven becomes Oath-Captain.
- **Ship names:** oath, fire and cold (Unyielding Oath, Ashen Vigil, Banked Fire, Long Watch, Debt of Vesper, Acceptable Loss).

### 2.11 Ranks, ships, weapons, places

- Ranks: Lieutenant, Commander, Captain, Commodore, Fleet captain; admirals Admiral, Commodore, High Admiral.
- Ship classes: Warden, Harrow, Vigil (was Penitent), Hearth (carrier, was Reliquary), Bastion (was Cathedral), Daybreak (was Ascendant).
- Weapons: **Sear** repeater, **Sear** battery, Heavy **sear** broadside, **Sear** turret, Oath lance, **Cinder** torpedo, Spark flak.
- Places: the Vesper Reach and its capital star, Vesper, the Cinder Line, the Ashen reaches, the Roll of Vesper (the wall that keeps the names of crusades that never came home).

---

## 3. Hegemony Navy (name kept; tech-forward)

### 3.1 Who they are

The largest human state in the region, run by **the Registry**: a vast intelligence at Meridian that every citizen, ship and officer is linked to. The Registry doesn't rule by force; it optimises. It plans careers, designs fleets, predicts every loss and keeps losses "within acceptable limits". Its people are safe, comfortable, proudly cybernetic, and counted. The quiet horror is being a number in a perfect calculation, and Vesper is the proof of what that means. The Registry has taken a growing interest in Eclipse: a whole people who became machines. The Registry wrote off the Vesper Reach's people seventy years ago, not its interest in the Hollow Sun: twenty-five years ago a survey fleet captured one of the six cores, Vyre, and studying it changed the arithmetic. The cores are worth more than the frontier ever was.

### 3.2 Voice and motifs

Clipped, polite and data-driven: probabilities, projections, timestamps, numbered Registry Orders, numbered posts (Listening Post M-14), and the Registry's calm voice on every channel ("Projection: favourable. Losses: acceptable."). The dry humour comes from the Registry taking everything literally.

### 3.3 Look

- **People:** composed humans with tasteful implants: a cortical-link port at the temple with a faint blue light, ocular implants with data moving across the iris, thin subdermal lines along the jaw and hands. Pale grey high-collared uniforms, gloves. Calm to the point of eerie.
- **Ships:** light grey hulls, steel-blue trim, blue-white windows. Clean wedges, rows of identical turrets, ion prongs at the bow, blue lights pulsing in time across the whole fleet, small drone escorts. Prefix HNS.
- **Colours in one line:** pale grey, steel blue, implant blue.

### 3.4 Origin and wants

- Origin: Meridian and the core worlds.
- Want: the Registry calculates that the six cores are the greatest power source in known space. Acquire, register, expand. It already holds Vyre.

### 3.5 How they fight

Formation around the flagship. Fire syncs near the flagship (the network), ion cannons strip shields, cruisers launch fighter screens, retro thrusters make backing off cheap. The Nemesis brings reinforcements in round 3 as the Registry reallocates, and tightens his formation every time he meets you.

### 3.6 Captives and the dead

- Captives: registered, assessed, assigned useful work. Unaugmented captives are offered implants.
- Their dead: logged in the loss ledger and closed out of the projections. Before a decisive battle, commanders switch off their links for one minute and speak to their crews unrecorded. It is the only thing the Registry never logs.

### 3.7 What they think of the others

- Sunward Crusade: "Secessionists. Unlinked. Statistically doomed."
- Hullbreakers: "Category: violence, ongoing."
- Chorus: "Biological incident, category one."
- Glasswrights: "Insufficient data. Possibly grieving."
- Eclipse: "A machine civilisation with no oversight. The Registry finds this instructive."

### 3.8 Crest, naming, ranks, ships, weapons, places

- Crest: a wedge in a ring of five linked nodes. Sound: a two-note chime before the Registry speaks. Saying: "Losses within acceptable limits."
- People: Germanic, Nordic and Dutch names (Konrad Reiter, Sanne Achterberg, Gerold Haldane, Katrin Falk). Ships: HNS Steadfast, HNS Arbiter, HNS Consensus, HNS Projection.
- Avoid: Skynet, Cylons, the geth, "the Machine God", Imperial, Executor, Interdictor, Star Destroyer, Commissar, Turbolaser, neural lace (Iain M. Banks's term).
- Ranks: Lieutenant, Commander, Captain, Commodore, Rear admiral; Line Admiral, Fleet Marshal, First Admiral, High Commodore.
- Ship classes: picket, cordon, vanguard, dominion, and the super-dreadnought The Iron Mandate.
- Weapons: Plasma cannon, Plasma lance, Heavy plasma lance (light blue), Ion cannon, Picket lasers, Laser cannon, Pulse laser, Heavy pulse laser (was Turbolaser; it fires in pulses).
- Places: Meridian, the core worlds, Listening Post M-14, Meridian Yards.

---

## 4. The Ashfall Hullbreakers (was Ashfall Corsairs)

### 4.1 Who they are

An alien raider species from the Ashfall belt: a cold, heavy-gravity world and the burned-out rocks around it, far from any warm star, where only the strongest packs ate. They are big, furred, hot-blooded predators, something like a bear crossed with a wolf, and they live in packs ruled by whoever can beat the rest. They don't want riches; they want to be the strongest thing in the dark. What they raid is salvage and scrap, which everyone else counts as credits. They hunt in space the way they hunted at home, by trail and by sound: their wake-trackers follow the ion trail every drive leaves behind, and their listening arrays pick up engine noise and signal chatter from far off, while their own ships run silent. They came to the Hollow Sun because the war around it is the biggest fight in known space, and they strip every faction's wrecks, bolt the best pieces into their ships and their armour harnesses, and hunt Rook, the core they believe makes its holder unstoppable. Strength rules: any of them can challenge a captain, and whoever lives keeps the ship. Old Mott has outlived forty captains, mostly by killing them.

They are the Glasswrights' opposite in every way: hulking and furred where the Glasswrights are slender and glassy, many where the Glasswrights are few, short-lived and fast-breeding where the Glasswrights live for centuries, brutal where the Glasswrights grieve.

### 4.2 Voice and motifs

Short, flat, brutal. They count kills, and talk in trails and sound ("We heard your engines three jumps out. Your wake still stinks of fear."). Strength, trophies, scrap, fear, the pack. Over comms, a growl under every word, and a howl when they board. Cold and disciplined, not comic: no ork-style brutes, no misspellings, no green. Humour, rarely, and always at the victim's expense.

### 4.3 Look

- **Beings:** huge and hunched, bear-heavy through the shoulders, with long wolf-like jaws full of teeth, thick matted fur in grey, black and rust-brown, and heavy claws. Small fierce eyes that shine in the dark. Scrap from other factions' ships is strapped over their fur in armour harnesses: Hegemony panels, Glasswright crystal, Eclipse plating. Trophies are machines and hull plates, never skulls or bodies.
- **Ships:** they run dark. Matte soot black and rust, few windows, dim red running lights, a red-orange glow from the engines, and big listening dishes and wake-sniffer scoops at the bow. Lopsided, with hull plates torn from every faction bolted on in their old colours, boarding claws at the bow, chains between hull sections. Junky, menacing, and hard to see until they're close. (The current Corsair ships already fit this.)
- **Colours in one line:** soot, rust, dried blood, trophy colours, red running lights.

### 4.4 Origin and wants

- Origin: the Ashfall belt; Rattlehold, their biggest den.
- Want: the war itself, Rook, and every wreck worth stripping.

### 4.5 How they fight

Fast, thin shields, pack hunters that close from the flanks and behind, far too many rockets, scrap guns with a wild extra shot and lucky crits, rams and boarding. No lances. The Nemesis raids your credits, flees a losing fight and comes back stronger; a ship he steals comes back to you when he dies (your ruling).

### 4.6 Captives and the dead

- Captives: chained to the engine gangs. The strong are offered a fight for a place in the pack.
- Their dead: stripped where they fall; the harness, the scrap and the trophies go to whoever killed them.

### 4.7 What they think of the others

- Sunward Crusade: "They fight hard and don't run. Good trophies."
- Hegemony: "Their ships hum. You can hear them a system away."
- Chorus: "Wet, and hungry. The only thing out here that fights like we do."
- Glasswrights: "Pretty little ships. They shatter well."
- Eclipse: "No smell, no blood. Dead metal that gets back up. Kill it twice."

### 4.8 Crest and signature details

- Crest: **a ring of welded scrap teeth around three claw slashes**.
- Sound: chains running out as the boarding claws fire, and the pack's howl over open comms.
- Ritual: the challenge. Any raider can fight the captain for the ship.
- Saying: "Strongest keeps it."

### 4.9 Naming rules

- **People:** harsh one- or two-syllable names plus an epithet earned in a fight (Krogg the Gutter, Vesh the Collector, Grax Steelgrin, Skarn Rot, Old Mott). No human surnames.
- **Ships:** threats and kills (No Quarter, Gut Hook, Chain of Teeth, Forty Captains, Second Death).
- **Nemesis parts:** harsh one-syllable fronts (Krag, Rusk, Gor, Snag, Skarn) plus body or tool words (Tooth, Maw, Hook, Knuckle, Spur).
- **Titles are translations.** Hullbreaker ranks are growls and howls; the words below are what outsiders call them.
- **Portraits:** the Hullbreaker admirals and Nemesis get repainted as this species after you sign off.

### 4.10 Ranks, ships, weapons, places

- Ranks (your call 1): Claw, Fang, Howler, Ripper, Warlord; Nemesis titles Apex, First Claw, Den-alpha, Warlord.
- Ship classes: raider, gutship, wrecker, hulk-carrier, and the War-barge class for the Warlord's Pyre-Barge (rebuilt from welded Hullbreaker hulls to match the others).
- Weapons: Autocannon, Scrap scatter gun, Junk turret, Rattle-rocket pod, Heavy rocket pod, Chaff guns.
- Places: the Ashfall belt, Rattlehold, the chain yards, the wreck fields around the Sun.

### 4.11 Two alternative takes

| | A. Eyeless heat-hunters (round 6) | B. Human reavers (round 5) |
|---|---|---|
| Identity | Squat, eyeless aliens that see by heat. | Grimdark human raiders. |
| Cost | You turned it down; it took heat from the Chorus. | Three human factions out of six. |

---

## 5. The Chorus (name kept)

### 5.1 Who they are

Not a people: a weapon that was made. After the collapse, the Starwrights who refused the Upload split over how to answer it. Most worked in glass and became the Glasswrights. A splinter, the Fleshwrights, worked in living tissue instead: they swore to destroy Eclipse for killing their sun, and grew a weapon to do it, ships and soldiers of engineered flesh that could live on starlight, eat anything, endure the cold and breed without end, powered from vats fed by Crucible, a Lattice core they took in the collapse. The weapon worked too well. It merged, multiplied and consumed its makers, and became one swarm with one appetite, spreading through the dark between stars. Inside it two throats argue. Hunger is the swarm. Memory is what is left of the Fleshwrights it consumed: their voices, their names, their sun. The swarm grew around Crucible and feeds on it still. Now it is coming to the Sun, drawn by the other five cores and by the makers' memory of the star they once circled, to eat what is left.

### 5.2 Voice and motifs

- "We". Short sentences. Taste, heat, smell, teeth. Two throats argue in every beat: Hunger wants, Memory remembers. Sometimes Memory speaks in a dead Fleshwright's voice (story and dialogue only).
- Never sings. No song words in any Chorus name or line.
- Avoid the Tyranid and Zerg furniture: hive, hive mind, hive fleet, Leviathan, synapse, norn, lictor, gaunt, carnifex, brood-queen, overmind, creep.

### 5.3 Look

- **Beings:** grown organisms with no face, eyes or limbs: glistening wet flesh, membrane, chitin, bile. Nothing on the surface recalls a person. Admirals: the Matriarch of Nine Throats, Razormaw, Voice of the Deep, the Mending Throng.
- **Ships:** grown, not built: ridges, pores, veins and glowing sacs, no panels or pipes. Dark olive-brown flesh, ochre chitin trim, bile yellow-green glow. Symmetric where the body allows. Tendrils, brood sacs, regrowing scar tissue.
- **Colours in one line:** dark olive, ochre bone, bile yellow-green light.

### 5.4 Origin and wants

- Origin: the Fleshwrights' war vats in the dark after the collapse; since then, the dark between stars.
- Want: eat the other five cores, reach the sun Memory still remembers, and finish the war it was grown for: Eclipse.

### 5.5 How they fight

No shields at all; flesh regrows every round. Spore swarms in place of wings, boarding tendrils, acid that eats through shields and armour, spines that strip armour, the first turn each round free. The Nemesis grows tougher from every ship you lose anywhere, and adapts after every meeting.

### 5.6 Captives and the dead

- Captives: food, or new flesh for the swarm.
- Their dead: eaten by the swarm. What remains is kept as a smell, and sometimes as a memory.

### 5.7 What they think of the others

- Sunward Crusade: "Hot. Bitter. Loud."
- Hegemony: "Many. Neat. All taste the same."
- Hullbreakers: "Fur. Rust. Hard to chew."
- Glasswrights: "The makers' kin. Memory knows them. Hunger does not care."
- Eclipse: "Memory knows them. Cold. Wrong. Made to eat them."

### 5.8 Crest and signature details

- Crest: a ring of nine open mouths (kept).
- Sound: a low wet thrum, like a throat swallowing, with faint voices under it.
- Ritual: tasting the air before the hunt.
- Saying: "More. Always more."

### 5.9 Naming rules

- **Individuals:** a body or sense word plus a body part or tide word: Seventh Mouth, Gnawing Tide, Wet Whisper, Hollow Gut, Brine Mouth. Single growl words: Moult, Undertow.
- **Ships:** body-horror nouns: Shrieking Coil, Tide of Teeth, Sour Gut, Gnawing Bloom.
- **Titles (Nemesis):** Spawn-mother, Elder Throat, Gorge-mind, Maw-mother.

### 5.10 Ranks, ships, weapons, places

- Ranks: Spawn-mind, Node, Throat, Elder throat, Great throat.
- Ship classes: drone-spawn, spitter, bladeback, brood-sac (carrier), and the boss **The Ninefold Maw**, Colossus class.
- Weapons: Spine volley, Boarding tendrils, Spore cloud, Acid sacs, Bile spray, Spore drifts.
- Places: the dark between stars, the drowned war vats of the Fleshwrights, spawning fields.

### 5.11 Why keep "The Chorus"

A chorus in a play is many voices speaking as one "we", and those voices are literally the makers the swarm consumed. You preferred it to every alternative; the Murmur stays as the standby.

---

## 6. The Glasswrights (was the Ithar)

### 6.1 Who they are

The descendants of the Starwrights who refused the Upload. Their ancestors were the Lattice's engineers, the finest optical and photonic engineers who ever lived: they built the collectors, the mirrors and the beam lines that carried a star's light across a system. When the Upload movement seized their work and overdrove it, those ancestors tried to stop it, failed, and watched their own machine kill their sun. They stayed flesh and fled in their ships. Glasswrights live three to four hundred years, so their descendants, only two or three generations on, inherited the craft and the guilt from people their grandmothers knew. They carry a second guilt too: the Fleshwrights who made the Chorus were their own splinter. They are few now, and grieving. Having lost their sun, they rebuild light in everything they make: their culture is obsessed with light, reflection, crystal and beauty, and their ships are works of art that bend and store light. They want the six cores recovered and shut down for good, so no one can ever overdraw a star again, and they want the Siphoning stopped before it kills another sun. They fly one core themselves, Astra: caged and throttled, used only to hunt the other five, and the last one they will shut down.

### 6.2 Voice and motifs

- Quiet, precise, mournful. Light words: reflection, refraction, glint, clear, focus, aperture, what we built. They apologise often and mean it.
- Sound motif: a single clear tone, like a struck glass. No faction sings.
- Not Aeldari: no fallen god, no soul stones, no paths, no craftworlds, no seers in charge, no "younger races".

### 6.3 Look

- **People:** biological, and plainly not human, living three to four centuries: tall and slender, long necks, large dark eyes behind a clear second eyelid, and skin that stores light, glowing faintly in patterns after time in the sun. They wear layered crystal and mirror-thread fabrics and carry small light-cores as jewellery.
- **Ships:** clear crystal and silver hulls whose faceted edges split light into rainbow fringes, mirrors and lenses that turn to catch light, crystal vanes (the old sail shapes, repainted), a stored light glowing deep inside. Slender and graceful. Symmetric.
- **Prism lance colour:** a white core beam splitting into a rainbow fringe, leaving glassy, rainbow-edged scars.
- **Colours in one line:** clear crystal, silver, rainbow edge, stored light.

### 6.4 Origin and wants

- Origin: the Ardent system, now dark; their fleet has wandered ever since.
- Want: use Astra to hunt down the other five cores, shut them all down, Astra last; destroy Eclipse's siphon arrays; never let a star be overdrawn again.

### 6.5 How they fight

Blindingly fast, heavily shielded, fragile once the shields fall. They cannot brace. Needle beams for precision and crits, star torpedoes that are hard to dodge, short jumps, starling wings, the Prism lance. Vanes make them harder to hit after moving. The Nemesis is a duelist who keeps range and withdraws; if he flees, he comes back with the same four-ship elite fleet, upgraded (your ruling).

### 6.6 Captives and the dead

- Captives: released, after a long and patient conversation about what the cores can do.
- Their dead: a body is returned to the light. The fleet focuses its mirrors on the casket and lets the stored light burn it to nothing.

### 6.7 What they think of the others

- Sunward Crusade: "Their star is dying because our siblings run the siphons. We would tell them, if they would listen."
- Hegemony: "They hold Vyre and think it is a battery."
- Hullbreakers: "They break things because breaking is easier than grief."
- Chorus: "What the Fleshwrights made to fight our siblings, and what ate them. Sometimes it speaks with our grandmothers' voices."
- Eclipse: "Our siblings. They took our light to become machines, and now they take everyone's."

### 6.8 Crest and signature details

- Crest: **a cracked lens with one beam of light passing through**.
- Sound: one clear tone, fading.
- Ritual: before battle, every ship turns its mirrors toward the Hollow Sun.
- Saying: "We built the light. We will not let it be stolen again."

### 6.9 Naming rules

- **People:** short, crisp names (Corin, Saro, Tamsa, Vell, Oskel, Brin), less elvish than before, plus a family line named for an optical work of their ancestors (of the Third Mirror, of Long Focus, of the Clear Aperture).
- **Titles:** Glimmer, Glint, Facet, Mirror, Lens-keeper; Nemesis titles Lens-keeper, First Mirror, Keeper of Astra. Keeper titles belong to the Glasswrights alone.
- **Ship names:** light and grief (Held Spectrum, Last Reflection, Quiet Prism, What We Built, Patience).

### 6.10 Ranks, ships, weapons, places

- Ranks: Glimmer, Glint, Facet, Mirror, Lens-keeper.
- Ship classes: sliver (frigate), lancet (destroyer), prism (cruiser), aperture (carrier), and the flagship **The Unfinished**, built around the largest surviving piece of the Lattice.
- Weapons: Prism shards, **Prism lance**, Star torpedo, Needle beam, Mirror veil, Shard cannon. Refits: Waveguide spine (was Dawnglass spine), Interferometer lens (was Longsight crystal), Shard hoppers, Clear eye.
- Places: the dark Ardent system, the Ringing Field (crystal wrecks that still ring when light hits them), the Lattice wreckage.

---

## 7. Eclipse (was the Deathless Dynasty)

### 7.1 Who they are

The Starwrights who uploaded. A movement that believed flesh was a stage to outgrow, they planned to upload every mind into its own machine body, built to last forever, with every mind backed up in one shared Archive. It needed more power than any star could safely give, so they seized the Lattice from its engineers and overdrove it. The uploads finished; the star did not survive. Billions of separate minds woke in machine bodies in a system gone dark, around the black hole they had made.

They have lived in that dark for a thousand years, and they are no longer sure the Upload was worth it. They gave up bodies, warmth, children and their sun for permanence, and permanence turns out to be very long. Their answer is to build a new sun: a man-made star at the heart of the Ardent system, steered by the six Lattice cores and fed by stellar energy siphoned from neighbouring stars: arrays built round each stolen star collect it and push it home through jump relays. That theft is the Siphoning, and it is why Vesper is going dark. They know what it costs other worlds. They do it anyway.

### 7.2 Voice and motifs

- Cold, exact, quietly grieving. The dark, shadow, the eclipse, warmth they remember and can no longer feel. Counts of years. How many bodies they have worn ("This is my ninth body"). Sentences that start to doubt the Upload and stop.
- They own darkness, memory and the lost sun, as the Glasswrights own light and craft.
- Avoid every Necron tell: tomb, dynasty, overlord, cryptek, necropolis, living metal, gauss, doom, scarab, canoptek, monolith, phylactery, reanimation protocols, crowns, thrones, Egyptian names, green glow. Also avoid "the Ascended" as a name (Stargate), Mass Effect's Reapers and Endless Space 2's Umbral Choir.

### 7.3 Look

- **Beings:** tall machine bodies built from layered dark violet-black plates, a narrow visor of white-gold light, and in each chest a small core of trapped light, all that is left of their sun. Their greatest minds keep the best idea from round 1: a monumental broken ring of plates around a glowing core, its pieces drifting apart and being refitted by tiny repair drones.
- **Ships:** hulls shaped like sunshades and heat shields, broad layered fans with the ship sheltering behind them, eclipse rings around the engines, no flaming engine bells. Their fold drive makes micro-jumps that skip a ship through rocks, wrecks and other ships. The carved-bone detail becomes shield-plate bands and eclipse rings on the next dressing pass. Shapes stay.
- **Colours:** dark violet-black plates, a white-gold eclipse corona, violet-white inner glow.

### 7.4 Origin and wants

- Origin: the Ardent system, dark for a thousand years; the Archive, where every uploaded mind is backed up. Each mind stays its own; the Archive holds copies, not a merged self.
- Want: gather all six cores (they hold Kharon) and light their new sun. Keep every other fleet away from their siphon arrays.

### 7.5 How they fight

No shields, heavy armour, and the fallen come back: repair swarms rebuild each hull once while its crew's minds re-stream from their last Archive backup. **Null** weapons ignore half of armour; the **Corona arc** lands one heavy blow every other turn. The fold drive skips through rocks, wrecks and ships. The Nemesis is patient (his clock runs at half speed), never retreats, comes back once after he is killed (sector 3 only, your ruling), and when his clock fills the hunt drains hull from your whole fleet.

### 7.6 Captives and the dead

- Captives: scanned into the Archive, every memory copied, then released. They consider this a kindness.
- Their dead: restored into a new body from their last backup. A mind that went too long without a backup cannot be restored; it has gone "dark", the only death they recognise.

### 7.7 What they think of the others

- Sunward Crusade: "Their star is small. Ours was Ardent."
- Hegemony: "Their Registry thinks. It does not yet regret."
- Hullbreakers: "Scavengers in our ruins."
- Chorus: "The Fleshwrights' weapon. It wears their voices, and it still wants us."
- Glasswrights: "Our siblings. They chose to stay small and warm. We chose forever. Neither of us kept the sun."

### 7.8 Crest and signature details

- Crest: **an eclipsed sun**, a black disc with a thin white-gold ring.
- Sound: a long low hum before the first volley.
- Ritual: before battle, every ship shows the last recorded image of Ardent.
- Saying: "We remember noon."

### 7.9 Naming rules

- **People:** an old Starwright name (Aurex, Vessane, Ostrel, Seveth, Marun, Kaelo, Halvane) plus an iteration epithet for how many bodies or copies they have been (Ninth Frame, Third-Housed, of the Long Copy, Twice-Restored, Fortieth Frame). Your ruling: iteration language, not poetic titles.
- **Admirals:** Nadir Aurex, Ninth Frame (the great ring mind); Umbra Vessane, Third-Housed; Ostrel of the Long Copy; Seveth, Twice-Restored.
- **Sample rival:** Nadir Halvane, Fortieth Frame.

### 7.10 Ranks, ships, weapons, places

- Ranks: Shade, Gloam, Umbra, Midnight, Nadir (the darkness theme); Nemesis titles High Nadir, Eclipse-prime, Archivist.
- Ship classes: mote (frigate), flare (destroyer), zenith (cruiser), and the flagship **The Unsetting**, archive-ship class.
- Weapons: **Null** cannon, Null sentries, Null spire, Null shredder, the **Corona arc**. Refits: Sunshade plating, Long-memory sight, Fold engine, Corona-ward node, Repair drones, Drone bay, Second Ignition (revives your first lost ship), the Archive.
- Places: the dark Ardent system, the siphon arrays, the Archive, the Lattice wreckage.
- Run word: **the Homecoming** (was reclamation).

---

*End of round 8. Comment as before, or tell me "lore approved".*
