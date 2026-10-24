# DeepSeek Council, Pack B Lens 2: Sci-Fi

Extracted by Rey from the raw DeepSeek transcript (contrib/deepseek/council_audit.txt). Claims are DeepSeek's, unverified, reproduced for Opus to judge. Quotes are verbatim from the transcript.

Source: Pack B chat, Lens 2 (Sci-Fi). 10 findings, in the model's order.

## 1. 40k vocabulary is not an influence; it is the base language
- Citation: data.js:40
- Quote: "deathless:{gauss:'Gauss flayer',doom:'Doom arc',gsentry:'Gauss pylon',flak:'Gauss shredder'}"
- Mark: OBSERVED
- Model's reasoning: Deathless is, in the model's words, Necrons with the labels changed: Gauss flayer, Doom arc, Tomb-ark, reanimation, phylactery, Overlord, Cryptlord, Dynast. The same borrowing runs through Voidsworn (data.js:35: "Penance lance", "Hellfire torpedo", "Censer flak"), Chorus (data.js:38: bio-plasma, spore cloud, boarding tendrils), and Ithar (data.js:193: "Wraithbone compass"; data.js:24: "Shuriken cannon"). The model names the source franchise as Warhammer 40,000.

## 2. Hegemony Navy is Star Wars Imperial Navy pastiche
- Citation: data.js:113
- Quote: "An imperial war-machine of wedge-hulled destroyers. Ion cannons strip shields; carriers launch fighter screens."
- Mark: OBSERVED
- Model's reasoning: Wedge hulls, ion cannons, fighter screens, "Turbolaser" (data.js:11), "Proton magazine" (data.js:258), "Hyperdrive motivator" and "Durasteel weave" (data.js:264) are Star Wars vocabulary, not generic space-opera terms.

## 3. Patron text calls every run a "crusade," contradicting the faction run words
- Citation: data.js:384
- Quote: "Each run four of six patrons watch the crusade"
- Mark: OBSERVED
- Model's reasoning: data.js:270 defines Hegemony runs as campaign, Corsair as raid, Chorus as hunt, Ithar as voyage, Deathless as reclamation. A Hegemony or Corsair player is still told the patrons watch their "crusade."

## 4. Patrons have no explained cosmology or link to the six factions
- Citation: data.js:388
- Quote: "quote:'Stand. Fire. Stand again.'"
- Mark: INFERRED
- Model's reasoning: Kharon and the other five get a name, colour, theme, glyph and one-line quote. The pack never says what a patron is, why they watch runs, why their sigils appear on battles, or whether any faction worships or serves them, so a new player never gets this explained.

## 5. "Choir" names a patron, a Chorus admiral, and the Chorus faction
- Citation: data.js:393
- Quote: "short:'The Choir'"
- Mark: OBSERVED
- Model's reasoning: The patron is "The Ember Choir"; the Chorus admiral is "The Mending Choir" (data.js:224); the faction is "The Chorus" (data.js:118). The writing gives no rule for distinguishing patron, admiral, and faction.

## 6. "The Hunger Below" duplicates the Chorus faction's identity without explaining the difference
- Citation: data.js:390
- Quote: "theme:'Squadrons, boarding and feeding on the fallen'"
- Mark: INFERRED
- Model's reasoning: The Chorus is "A hungering bio-swarm" (data.js:119) with boarding tendrils and spore mines. The model asks whether the Hunger is the Chorus's god, a separate entity, or the same hunger; the pack never says.

## 7. The war has no premise or stakes beyond one-line faction blurbs
- Citation: data.js:111
- Quote: "Gothic crusader battleships. Heavy armor, lance batteries and broadsides that hit like a cathedral falling."
- Mark: INFERRED
- Model's reasoning: Every faction gets a single blurb. Nothing explains who the Voidsworn are, why they crusade, what the player commands, why the six factions fight, or what winning a run means in-world.

## 8. Faction admirals are renamed copies of the same four commands
- Citation: data.js:214
- Quote: "cmd:{id:'barrage',n:'Synchronized broadside'"
- Mark: OBSERVED
- Model's reasoning: Hegemony Kassar's "Synchronized broadside" is the same barrage effect as Voidsworn Vex's "Fire for effect" (data.js:209); the same duplication runs through hunt, scramble, iron, surge, and restore. The admirals have names and doctrines, but their Commands are not faction-specific writing.

## 9. "HNS" is never expanded or explained
- Citation: data.js:320
- Quote: "HNS Steadfast"
- Mark: OBSERVED
- Model's reasoning: Hegemony ship names use "HNS" throughout, but the pack never states what it stands for, whether Hegemony is human, or what its naval hierarchy means. A new player gets an acronym with no in-world meaning.

## 10. "Iron" is spread across unrelated factions and patrons until it stops identifying anyone
- Citation: data.js:76
- Quote: "The Iron Mandate"
- Mark: OBSERVED
- Model's reasoning: The Hegemony boss is "The Iron Mandate"; the Voidsworn patron is "Kharon, the Iron Saint" (data.js:388); the Corsair admiral is "Grax Ironjaw" (data.js:218); Thale has "Iron doctrine" (data.js:205); Deathless epithets include "the Iron-Hearted" (data.js:318). The model says the word is used as a universal grimdark adjective, not a faction marker.

## Not checked
"Not checked: I did not examine actual codex/tutorial text, dialogue, voice, or any lore files not included in this pack. I did not verify outside-franchise details beyond the names and terms quoted above."
