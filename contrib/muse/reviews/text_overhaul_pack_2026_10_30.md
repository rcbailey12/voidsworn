# Text overhaul pack, Oct 30, 2026

Chair deliverable for Opus. Every player-facing string in the shipped browser build, extracted at pin 264f441d43a54e3679950dcc4457133b40811807 (verified identical to the working clone for game code), line-edited, and delivered as exact swaps.

Companion file: strings_inventory.csv (1,685 strings: 1,630 from data.js, 55 curated rows for the other shipped files). Every row below carries its inventory id (INV-nnnn) plus the file and line or the data path, so a row can be applied without re-deriving anything.

## How to apply

1. A row is an exact string swap at the cited path or line, unless the Replacement cell says REMOVE.
2. Ids never change. Only display strings change.
3. Rows marked PROPOSAL have a verified defect and a chair-proposed wording. If Ryan dislikes the wording, pick another; the defect stands either way.
4. Section 2 lists what a string swap cannot fix: code items, one ruled data addition, and four decisions for Ryan. Nothing in section 2 blocks section 1.
5. No replacement string in this pack contains an em dash, a naval ship word, or a backward-facing gun. Plasma stays light blue. Display names follow the rename map.

## Section 1: replacements

### A. Settled rulings and audited fixes not yet in the data

| Row | Id / location | Current | Replacement | Source |
|---|---|---|---|---|
| T-01 | INV-0436, data.js:254, SHIP_NAMES[23] | Acceptable Loss | REMOVE (no replacement ruled; see DEC-2) | Ryan ruling, Oct 28, 2026: swap the name out of the Crusade pool. Still present at the pin. |
| T-02 | INV-0157, data.js, FACTIONS.deathless.blurb | Starwright minds in machine bodies, stealing starlight to light a new sun. | Starwright minds in machine bodies, siphoning stellar energy to build a new sun. | Rollout audit fix, already ruled. Bible r8: "Energy, not light. Eclipse siphon stellar energy" (line 14); "Building a new sun from stolen stellar energy" (line 28). |
| T-03 | INV-0309, data.js:221, ADMIRALS.grax.n | Warlord Grax Steelgrin | Warlord Grax Ironmaw | Oct 27 rollout audit ruling. Supersedes rename_map_final.md:288, which still says Steelgrin; the map needs the same edit. |
| T-04 | INV-1005, data.js:464, NEM_FAC.deathless.titles[3] | Nadir | REMOVE (keep "High Nadir" at titles[0]) | Oct 27 rollout audit ruling: plain "Nadir" drops out of the Eclipse Nemesis title pool. It also duplicates the faction's own top rank name. |
| T-05 | INV-1315, data.js, FAC_VERBS.deathless.d | Next battle, Archive restore brings back one more ship. | Next battle, one more of your destroyed ships reassembles. | Oct 27 text synthesis, batch 7: "Archive restore" is a mechanic name that exists nowhere else in the game. |
| T-06 | INV-0608, data.js, RELIC_NAMES.deathless.salvage | Salvage swarm | Reclamation swarm (PROPOSAL) | Oct 27 rollout audit: the display word "salvage" has one meaning (the relic system itself), so a relic name built from it collides. |
| T-07 | INV-0253, data.js, RELICS.phylactery.n | Eclipse backup frame | Backup frame (PROPOSAL) | Relics synthesis, Oct 30, 2026, FIX 5: the base name leaks to every non-Eclipse faction, because RELIC_NAMES rows that lack a phylactery entry fall back to it (relicName, core.js). Only Eclipse overrides it ("Second Ignition"). |

### B. Card accuracy: the text must say what the numbers do

Verified against the fx and weapon data at the pin.

| Row | Id / location | Current | Replacement | Source |
|---|---|---|---|---|
| T-08 | INV-0291, ADMIRALS.kassar.d | Batteries fire one extra shot per volley, but every gun hits 5% lighter. | Batteries fire one extra shot per volley, but all damage is 5% lower. | Oct 27 text synthesis, batch 7. fx is dmgPct:-.05, all damage, not a hit penalty. |
| T-09 | INV-0356, ADMIRALS.vaelen.d | Lances deal +20% damage and gain +10 aim. | Lances deal +20% damage, and every weapon gains +10 aim. | Oct 27 text synthesis, batch 7. fx {lancePct:.2, aim:10}; the aim is global. |
| T-10 | INV-0281, ADMIRALS.ashgrove.d | Squadrons deal +40% damage and carriers hold +1 wing. | Squadrons deal +40% damage and carriers hold +1 wing. Squadron hull +25%. | Oct 27 text synthesis, batch 7: hidden fx sqHp:.25, never mentioned in the text. |
| T-11 | INV-0301, ADMIRALS.reyes.d | Squadrons deal +10% damage and cruisers hold +1 wing. | Squadrons deal +10% damage and cruisers hold +1 wing. Squadron hull +25%. | Same: hidden sqHp:.25. |
| T-12 | INV-0321, ADMIRALS.mott.d | Squadrons deal +25% damage and hulks hold +1 wing. | Squadrons deal +25% damage and hulks hold +1 wing. Squadron hull +25%. | Same: hidden sqHp:.25. |
| T-13 | INV-0331, ADMIRALS.matriarch.d | Spore swarms deal +25% damage and broods hold +1 swarm. | Spore swarms deal +25% damage and broods hold +1 swarm. Swarm hull +25%. | Same: hidden sqHp:.25. |
| T-14 | INV-0351, ADMIRALS.aelith.d | Squadrons deal +25% damage and carriers hold +1 wing. | Squadrons deal +25% damage and carriers hold +1 wing. Squadron hull +25%. | Same: hidden sqHp:.25. |
| T-15 | INV-1468, HULL_VARIANTS.d_harvester_t.d | Its corona arc sits on a turret: it no longer has to turn to fire. | Its corona arc sits on a turret: it no longer has to turn to fire. One null cannon is removed to make room. | Ryan ruling, Oct 29, 2026 (battle Q8): silent weapon deletions get fixed or disclosed. The variant drops the base hull's second gauss and says nothing. Verified line by line in the Argon red team gamedev leg, Oct 30, 2026. |
| T-16 | INV-1460, HULL_VARIANTS.b_razor_s.d | Two tendril clusters, +1 speed and +8 evasion. | Two tendril clusters instead of the spine volley, +1 speed and +8 evasion. | Same ruling. The variant drops the base b_razor's bioplasma (displayed as the spine volley for the Chorus) without disclosing it. Also in the findings-to-tests ledger (ROS-2). |
| T-17 | INV-1464, HULL_VARIANTS.i_song_w.d | One lance on a turret, 30% more shields. | One lance on a turret instead of two, 30% more shields. | Same ruling. The base hull carries two prow lances; the variant carries one. The current text never says one was removed. |
| T-18 | INV-1488, MASTERY_PERKS[4].d | Your flagship starts at Mk II, its captain a Captain with a perk. | Your flagship starts at Mk II, its captain two ranks up with a perk. | Code check at the pin (core.js:335): mastery 4 sets the flagship captain to rank index 2, which is "Captain" only for the Crusade. The other five factions read Commander, Howler, Mouth, Keeper, Warden. |

### C. The launch family: "carrier" is a class, launch is the mechanic

Hegemony has no Carrier-class hull. Its launch ships are a cruiser (h_vanguard) and a battleship (h_dominion). Text that says "carriers" is wrong for Hegemony fleets and loose everywhere else. Source: Oct 27 text synthesis, batch 8, extended to the identical Command string and the help screen.

| Row | Id / location | Current | Replacement | Source |
|---|---|---|---|---|
| T-19 | INV-0209, MODULES.hangar.d | Carriers only: +1 squadron in flight. | Launch ships only: +1 squadron in flight. | Batch 8. The module gates on only:'launch', not on the Carrier class. |
| T-20 | INV-0165, ABILITIES.launch.d | Carriers start each battle with their wings in flight. This launches a replacement for a lost wing into an adjacent hex; each carrier has one spare wing per hangar slot. | Launch ships start each battle with their wings in flight. Launching replaces a lost wing into an adjacent hex; each launch ship has one spare wing per hangar slot. | Batch 8. |
| T-21 | INV-0149, FACTIONS.hegemony.blurb | The Registry's navy: linked crews, wedge hulls and drone escorts. Ion cannons strip shields; carriers launch fighter screens. | The Registry's navy: linked crews, wedge hulls and drone escorts. Ion cannons strip shields; its cruisers and battleships launch fighter screens. | Batch 8. |
| T-22 | INV-0283, ADMIRALS.ashgrove.cmd.d | Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | Every launch ship sends out an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | Batch 8 family. The scramble Command string is identical for four admirals (T-22 to T-25). |
| T-23 | INV-0303, ADMIRALS.reyes.cmd.d | Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | Every launch ship sends out an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | Batch 8 named this one: Reyes is the Hegemony admiral, and Hegemony has no carrier. |
| T-24 | INV-0323, ADMIRALS.mott.cmd.d | Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | Every launch ship sends out an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | Same shared string. |
| T-25 | INV-0353, ADMIRALS.aelith.cmd.d | Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | Every launch ship sends out an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | Same shared string. |
| T-26 | INV-1571, ASPECTS.hive.d | Your flagship launches a squadron wing at the start of every battle (+1 wing if it is already a carrier), and its wings deal +30% damage. | Your flagship launches a squadron wing at the start of every battle (+1 wing if it is already a launch ship), and its wings deal +30% damage. | Same family, found in the overhaul sweep. |
| T-27 | INV-1638, campaign_meta.js:163, help screen | Carriers start every battle with their wings already flying; the wings fight on their own unless you order them | Launch ships start every battle with their wings already flying; the wings fight on their own unless you order them | Same family, help screen copy of the ability text. |
| T-28 | INV-1639, campaign_meta.js:163, help screen | The carrier's launch only replaces wings you lose. | A launch ship's ability only replaces wings you lose. | Same family. |
| T-29 | INV-1680, ui3d.js:545, quickLaunch toast | No open hex next to the carrier to launch from. | No open hex next to the ship to launch from. | Same family. |

### D. Nemesis text: one gender is hard-coded into raw-displayed strings

The Nemesis is generated male, female, or neuter, and the game owns a pronoun layer (nemSay, nemPr) for exactly this. The behaviour cards (NEM_FAC.beh.d) and the spoken lines (NEM_LINES) pass through it. The tables below do not: their d strings reach the Nemesis panel, the trait and weakness lists, and the battle debrief exactly as written, so every Nemesis reads male. The fix at data level is neutral wording, which is correct for all three genders and needs no code change. The durable fix (route the display sites through nemSay) is CODE-3 in section 2.

#### D1. Weaknesses (NEM_WEAK, data.js:429-435)

| Row | Id | Current | Replacement |
|---|---|---|---|
| T-30 | INV-0899 | His ships take 25% more damage on rear-arc hits. | Enemy ships take 25% more damage on rear-arc hits. |
| T-31 | INV-0901 | Ion and lance hits strip 50% more shield from his ships. | Ion and lance hits strip 50% more shield from enemy ships. |
| T-32 | INV-0903 | Torpedoes are 15 easier to land on his ships. | Torpedoes are 15 easier to land on enemy ships. |
| T-33 | INV-0905 | His ships carry 30% fewer crew to repel boarders. | Enemy ships carry 30% fewer crew to repel boarders. |
| T-34 | INV-0907 | His ships aim 10 worse at targets 2 hexes away or closer. | Enemy ships aim 10 worse at targets 2 hexes away or closer. |
| T-35 | INV-0909 | His escorts break and flee once his flagship falls below 60% hull. | Enemy escorts break and flee once the flagship falls below 60% hull. |
| T-36 | INV-0911 | His ships have 1 less movement. | Enemy ships have 1 less movement. |

#### D2. Traits (NEM_TRAITS, data.js:450-454)

| Row | Id | Current | Replacement |
|---|---|---|---|
| T-37 | INV-0913 | His ships aim 6 better. | Enemy ships aim 6 better. |
| T-38 | INV-0915 | His ships have 8% more armor. | Enemy ships have 8% more armor. |
| T-39 | INV-0917 | His ships have 1 more movement. | Enemy ships have 1 more movement. |
| T-40 | INV-0919 | His ships have 12% more hull. | Enemy ships have 12% more hull. |
| T-41 | INV-0921 | His ships have 10% more critical chance. | Enemy ships have 10% more critical chance. |
| T-42 | INV-0923 | His ships have 20% more shields. | Enemy ships have 20% more shields. |
| T-43 | INV-0925 | His ships carry 30% more crew. | Enemy ships carry 30% more crew. |
| T-44 | INV-0927 | His ships regrow 4 more hull each turn. | Enemy ships regrow 4 more hull each turn. |
| T-45 | INV-0929 | His carriers field one more wing. | Enemy carriers field one more wing. |
| T-46 | INV-0931 | One more of his ships reassembles after falling. | One more enemy ship reassembles after falling. |
| T-47 | INV-0933 | His ships are 8 harder to hit. | Enemy ships are 8 harder to hit. |
| T-48 | INV-0935 | His guns reach 1 hex further. | Enemy guns reach 1 hex further. |
| T-49 | INV-0937 | His ships deal 12% more damage to a ship next to them. | Enemy ships deal 12% more damage to a ship next to them. |
| T-50 | INV-0939 | His torpedoes reload a turn faster. | Enemy torpedoes reload a turn faster. |

#### D3. Adaptations (NEM_ADAPT, data.js:437-441)

| Row | Id | Current | Replacement |
|---|---|---|---|
| T-51 | INV-0941 | His ships have 20% more shields. | Enemy ships have 20% more shields. |
| T-52 | INV-0944 | Two of his ships bolt on point defense. | Two enemy ships bolt on point defense. |
| T-53 | INV-0947 | His ships have 10% more armor. | Enemy ships have 10% more armor. |
| T-54 | INV-0950 | His ships have 8 more evasion. | Enemy ships have 8 more evasion. |
| T-55 | INV-0953 | His ships aim 8 better. | Enemy ships aim 8 better. |

#### D4. Faction adaptations (NEM_ADAPT_FAC specials, data.js:482-487)

| Row | Id | Current | Replacement |
|---|---|---|---|
| T-56 | INV-1157 (corsair special, name) | Bigger crew | Bigger fleet |
| T-57 | INV-1158 (corsair special) | One more ship joins his fleet. | One more ship joins the fleet. |
| T-58 | INV-1160 (deathless special) | One more of his ships reassembles. | One more enemy ship reassembles. |
| T-59 | INV-1162 (ithar special) | His ships are 6 more harder to hit. | Enemy ships are 6 harder to hit. |
| T-60 | INV-1164 (chorus special) | His ships regrow 3 more hull each turn. | Enemy ships regrow 3 more hull each turn. |
| T-61 | INV-1166 (hegemony special) | His synchronized fire reaches one hex further. | Synchronized fire reaches one hex further. |
| T-62 | INV-1168 (voidsworn special) | His ships deal 8% more damage. | Enemy ships deal 8% more damage. |

T-56 and T-59 are also plain defects, found by all three Oct 27 text legs: the name says "crew" while the effect adds a ship, and "6 more harder to hit" is broken grammar. The house style for the same stat is "8 harder to hit" (NEM_TRAITS.veil).

#### D5. Personas (NEM_PERSONA, data.js:457-459)

| Row | Id | Current | Replacement |
|---|---|---|---|
| T-63 | INV-0962 (patient) | Waits for you to come to him. | Waits for you to close in. |
| T-64 | INV-0964 (proud) | Leads from the front with his flagship. | Leads from the front, flagship first. |
| T-65 | INV-0968 (methodical) | Holds his line and advances only in formation. | Holds the line and advances only in formation. |

#### D6. The Eclipse behaviour card: a false claim, not a pronoun problem

| Row | Id / location | Current | Replacement | Source |
|---|---|---|---|---|
| T-66 | INV-1006, NEM_FAC.deathless.beh.d | Patient: his clock moves at half speed. He never retreats. Destroyed early, he simply reassembles; destroyed in the last sector, he rises once more for one final fight. When his clock fills, the hunt drains 6% hull from every ship you have (never below 1 hull). | Patient: his clock moves at half speed. Destroyed early, he simply reassembles; destroyed in the last sector, he rises once more for one final fight. When his clock fills, the hunt drains 6% hull from every ship you have (never below 1 hull). | Oct 27 text synthesis, batch 9. This string does pass through nemSay, so the pronouns are fine. The defect is factual: the behaviour object has revive:1 and no noFlee, and an Eclipse Nemesis can flee and be escaped from. The bible gives never-flees to the Crusade Nemesis, whose card (voidsworn.beh) correctly claims it. Only the false sentence is removed. |

#### D7. Hard-coded male literals in campaign_run.js

These are plain returned or rendered literals. They are shown raw (panel HTML, strike messages, debrief text), so neutral swaps are safe today. CODE-3 covers the better long-term routing.

| Row | Id / location | Current | Replacement |
|---|---|---|---|
| T-67 | INV-1643, campaign_run.js:80, Nemesis panel strike warning | His fleet is coming: your next fight is his. | The Nemesis fleet is coming: your next fight is the Nemesis. |
| T-68 | INV-1648, campaign_run.js:274, nemClockAdd | Your next fight will be against his fleet. | Your next fight will be against the Nemesis fleet. |
| T-69 | INV-1649, campaign_run.js:294, nemAdaptWhy fallback | his own way of war | its own way of war |
| T-70 | INV-1677, campaign_run.js:278, nemStrike raid | His raiders hit your supply line: -${c} credits. He holds them; kill him to take them back. | Enemy raiders hit your supply line: -${c} credits. The Nemesis holds them; kill the Nemesis to take them back. |
| T-71 | INV-1678, campaign_run.js:279, nemStrike raid | With your coffers empty, his raiders cut out the crippled ${cand.name} and tow her away. Kill him and you take her back. | With your coffers empty, enemy raiders cut out the crippled ${cand.name} and tow it away. Kill the Nemesis and you take it back. |
| T-72 | INV-1679, campaign_run.js:279, nemStrike raid | His raiders find nothing worth taking. | Enemy raiders find nothing worth taking. |

### E. Weapon trait text: state the numbers

Source: Oct 27 text synthesis, batch 7. Trait text is appended to the weapon line in the ship panel, so a trait that hides its numbers hides them where the player makes fitting decisions. Numbers below are read from the trait functions at the pin. Fire damage is battle.js:383 and :712 (a burning ship takes 6 a turn, for 2 turns).

| Row | Id / location | Current | Replacement |
|---|---|---|---|
| T-73 | INV-0069, WTRAITS.las.d | holds its aim at long range | holds its aim at long range (+4 aim, half the range falloff) |
| T-74 | INV-0072, WTRAITS.scrap.d | an extra shot, wild aim, lucky crits | an extra shot, -12 aim, +3% crit |
| T-75 | INV-0076, WTRAITS.needle.d | precise: better aim and more criticals | precise: +6 aim, +8% crit |
| T-76 | INV-0071, WTRAITS.plasma.d | a quarter burns through shields | a quarter burns through shields, +1 damage |
| T-77 | INV-0070, WTRAITS.hellfire.d | sets the target burning | sets the target burning (6 damage a turn for 2 turns) |

The sixth trait in the batch, star ("fast: hard to dodge"), is not in this table. Its number points the other way from its words. See DEC-3.

### F. Event text accuracy

| Row | Id / location | Current | Replacement | Source |
|---|---|---|---|---|
| T-78 | INV-0635, EVENTS.beacon, option "Seize the cargo", s | +100 credits. Their escort might remember your colours. | +100 credits, but their escort will hunt you: your next fight is an ambush, and the Nemesis clock moves on. | Oct 27 events synthesis, finding 3. The option carries ambush:true and, by the splice at data.js:326, nemClock:1 and the greed flag. None of it is disclosed. The bait event in the same table discloses its own ambush in words, so the standard exists and beacon misses it. |
| T-79 | INV-0625, EVENTS.derelict, option "Cut out its core with lances", s | A clean cut: founders' tech and salvage, nothing wakes. | A clean cut: a refit and 40 credits, and nothing wakes. | Oct 27 events synthesis, notes. The option pays a module and 40 credits (r:{mod:1, cred:40}), not salvage. Since the rename, "salvage" is a defined term, so the current wording is wrong on its face. |
| T-80 | INV-0643, EVENTS.astropath, corsair variant b | Your best tracker swears she can smell old metal on the far side of a rift. She is usually right. Usually. | Your best tracker swears she can hear old metal settling on the far side of a rift. She is usually right. Usually. | Bible r8 and the Oct 27 text audit, batch 10: Hullbreakers track by trail and sound, never by smell. This is the same motif the withdrawn Nemesis line used. The Chorus variant in the same event ("tastes something old") is correct, because taste and smell belong to the Chorus (r8:96, r8:332). |

### G. Voice and register

| Row | Id / location | Current | Replacement | Source |
|---|---|---|---|---|
| T-81 | INV-0371, ADMIRALS.nekhet.d | Ships regrow 4% of their hull each round. | Ships rebuild 4% of their hull each round. | Argon red team narrative leg, Oct 30, 2026 (voice family). Nekhet is an Eclipse admiral; "regrow" is the Chorus register. The Chorus mending admiral's "regrow" text is correct and stays. |
| T-82 | INV-1414, MORE_SHIP_NAMES.corsair[9] | Last Scent | Last Trail (PROPOSAL) | Same trail-and-sound rule as T-80 (r8, Hullbreaker section). A ship name built on scent leans on the removed motif. |
| T-83 | INV-1664, ui3d.js:650, TIPS "close" | Ramming speed (X) charges the first enemy dead ahead. Boarding (G) sends crews into an adjacent enemy; win and the ship is yours. | Ramming speed (X) charges the first enemy dead ahead. Boarding (G) sends a boarding party into an adjacent enemy; win and the ship is yours. | Shipped tutorial text assumes a human crew. Chorus and Eclipse fleets have no crews to send. The tip fires in every run. |
| T-84 | INV-1675, campaign3d.js:92, corsair prize toast | Prize money: the crews strip a ${mod} and 20 credits from the ${prize} before anyone signs for her. | Prize money: the crews strip a ${mod} and 20 credits from the ${prize} before anyone signs for it. | A ship is not "her" in this game's register; every other ship reference in the shipped text uses "it". One word. |
| T-85 | INV-0617, RUN_WORD.deathless | Homecoming | homecoming (NOTE, optional) | The other five run words are lower-case common nouns (crusade, campaign, raid, hunt, voyage), and the word renders mid-sentence on the launch button ("Launch the Homecoming" against "Launch the crusade"). Take it or leave it; flagged so the inconsistency is a choice, not an accident. |

### H. Help screen and interface copy

The help screen is the game's contract with a new player, in a game where run 1 is near-impossible by design. Three of its load-bearing claims are false at the pin.

| Row | Id / location | Current | Replacement | Source |
|---|---|---|---|---|
| T-86 | INV-1634, campaign_meta.js:150, help lede | Embers of the Hollow Sun is a roguelite. Each run crosses three sectors, each ending in a flagship battle. Ships and captains you lose are gone for the run; every faction, admiral and ship is available from the start. | Embers of the Hollow Sun is a roguelite. Each run crosses three sectors, each ending in a flagship battle. Ships and captains you lose are gone for the run. Every faction can be played from the start; admirals and hull variants are unlocked with renown between runs. | Oct 27 text synthesis and the Rey red team narrative leg, Oct 30, 2026. Admirals cost renown (ADMIRALS cost fields) and hull variants sit behind LEGACY gates. The same screen contradicts the claim two paragraphs later. |
| T-87 | INV-1635, campaign_meta.js:151, help, what carries between runs | After each sector flagship falls, the fleet docks at a shipyard before its next fight. | Shipyards appear as stops on the sector map, selling hulls, refits and repairs between fights. | Chair code check: afterBattle contains no shipyard step. Shipyards are map nodes (shipyardScreen is reached from the map). |
| T-88 | INV-1636, campaign_meta.js:167, help, cores and protocols | Protocols change the rules (fires, chain explosions, rams that shake the whole formation) and come in Common, Rare and Epic strength. | Protocols change the rules (fires, chain explosions, rams that shake the whole formation) and come in Common, Rare, Epic and Legendary strength. | RARITY has four tiers; Legendary is index 3. The help text omits it. |
| T-89 | INV-1637, campaign_meta.js:167, help, aspect pick | At the start of a run you also pick one of three aspects for your flagship, which shapes how it fights for the whole run. | At the start of a run you also pick one of three aspects for your flagship (a fourth unlocks as an admiral masters their fleet), which shapes how it fights for the whole run. | aspectScreen offers a fourth aspect at admiral mastery 2 or more (campaign_meta.js:101). "One of three" is only true for a brand-new admiral. |
| T-90 | INV-1640, campaign_meta.js:171, help, keys line | Tab next ship, Q/E turn, 1-6 arm a weapon, B brace, A toggle arcs, Esc or right-click to cancel, Enter end turn. (rendered with kbd tags) | Tab next ship, Q/E turn, 1-6 arm a weapon, B brace, V toggle arcs, X ram, G board, Esc or right-click to cancel, Enter end turn. | Chair code check against onKey (ui3d.js): V toggles arcs; there is no A binding. The current line teaches a key that does nothing and omits ram and board. |
| T-91 | INV-1632, campaign_meta.js:68, locked admiral card | Unlock for ${a.cost} renown in Legacy | Unlock for ${a.cost} renown | The screen is named Progression, not Legacy. The pointer is also false a second way: no screen sells admirals at all (see CODE-1). The pointerless text is true today; restore a pointer only when the purchase is wired. |
| T-92 | INV-1654, ui3d.js:62, settings panel tooltip | Copy your recent play data to paste to Claude | Copy your recent play data | Player-facing copy naming the developer's AI assistant. Argon red team uiux leg, Oct 30, 2026, finding 6 (chair-verified in buildHud). |
| T-93 | INV-1676, campaign3d.js:120, title settings row | Copy report for Claude | Copy report | Same item, second surface. |
| T-94 | INV-1672, campaign3d.js:22, copy report toast | Report copied. Paste it into your chat with Claude. | Report copied. | Same item, third surface. |

### I. Battle log literals

| Row | Id / location | Current | Replacement | Source |
|---|---|---|---|---|
| T-95 | INV-1670, battle.js:586, boss flee log | ${fl.name} breaks off and jumps out with what is left of his fleet. He will be back. | ${fl.name} breaks off and jumps out with what is left of the fleet. It will be back. | Hard-coded male for a flagship whose commander is generated. The neighbouring adaptation log (battle.js:573) already switches pronouns correctly, so the standard exists in the same file. |
| T-96 | INV-1671, battle.js:600, boss burning log | His escorts lose their nerve and flee. | Its escorts lose their nerve and flee. | Same item. The subject is the flagship, a ship. |

Section 1 total: 96 strings.

## Section 2: flags

### Code items: a string swap cannot fix these

**CODE-1. Admiral purchase is not wired to any screen.** ACT.buyAdmiral exists (campaign_meta.js:175) and works, but legacyScreen never renders it: its tabs are variants, mastery, favour, heat, fallen, and none of them sells an admiral. So a locked admiral shows a cost and no way to pay it. T-91 makes the card text honest; the real fix is rendering the purchase, most naturally in the Progression mastery tab. Connects to the Argon uiux leg's "missing unlock UI" item, Oct 30, 2026.

**CODE-2. Two displays read the Crusade rank table for every faction.** needText (campaign_run.js:227, INV-1647) builds a requirement as "a " + RANKS[nd.vet] + " or better", and the reward screen (campaign_run.js:411, INV-1650) prints "promoted to ${RANKS[x.rank]}". RANKS is the Crusade table. Per-faction rank names exist (CAPTAINS[fac].ranks, and rankName() already uses them, correctly, in promoteModal). Fix: both sites use rankName or CAPTAINS[RUN.fac].ranks. Until then, a Glasswright player is told they need "a Captain or better" and a Hullbreaker captain is "promoted to Captain".

**CODE-3. Nemesis pronoun routing (long-term version of section D).** Section D makes the shipped strings neutral, which is correct for every gender. If Opus prefers gendered text where the game already owns the machinery, the durable fix is to route the section D display sites (Nemesis panel trait and weakness titles, the debrief adaptation lines) through nemSay or nemPr, the way NEM_FAC.beh.d and NEM_LINES already are. Chair pick: ship the neutral swaps now; route later only if gendered Nemesis text is wanted as a feature.

**CODE-4. The shipwright event heals the wrong second ship.** The event text is right and the code is wrong. In applyOutcome (campaign_run.js), r.upgradeOne sorts the fleet by hull fraction and fully repairs and upgrades index [0]; r.repairOne then re-sorts and takes index [1]. Because the first heal changes the sort, the promised second-ship repair lands on a different ship than the player was shown. The wright event's paid option (data.js, splice at line 331) promises "a second ship is fully repaired". Fix the index handling, not the text. Found by the Argon red team narrative leg, Oct 30, 2026, finding 9; chair-verified in code.

**CODE-5. Purchase surfaces name weapons by their base names, ship cards by faction names.** The shipyard hull card (campaign_run.js:171, INV-1644) and the Progression variant card (campaign_meta.js:124, INV-1633) render W[id].n. Ship cards render the derived faction names (nameWeapons, FAC_WNAMES at data.js:34-41). So the same gun is "Gauss cannon" on the buy screen and "Null cannon" on the ship the player just bought. Oct 27 text synthesis, batch 3. Fix: both purchase surfaces render the derived names for the player's faction.

**CODE-6. Eclipse takes no article, and three templates force one.** Faction names are stored with their article ("The Chorus", "the Sunward Crusade" by usage), and Eclipse is the exception: no "the", ever (bible r8, line 12). Three sites strip a leading "The " and then add their own "the ", which is correct for every faction except Eclipse: the run end screen's "Try the ${...}" (campaign_meta.js:207, INV-1641), its victory line "brings the ${...} home" (campaign_meta.js:208, INV-1642), and the map insert "Rival raiders from the ${...} and the ${...}" (campaign3d.js:28, INV-1673). An Eclipse player reads "Try the Eclipse" and "brings the Eclipse home". Fix in code: build these phrases from the full name, or special-case deathless.

**CODE-7. Five "free after" promises depend on a comparison the consumers never make.** Event choices write flags as the chosen option's key (campaign_run.js, eventFlags), but needMet tests only presence (the nd.flag branch: RUN.flags[...] != null), and the faction verb free conditions test the same way. So the drill is free after ANY defector outcome, not just selling the defector back; the saboteur "face" option opens on a defector the player never questioned; and three more verb freeD texts promise a specific earlier choice. The texts (FAC_VERBS freeD fields and the five affected option texts) are accurate the moment the two consumer functions compare the stored key. Oct 27 events synthesis, finding 1 (the audit's top finding). Fix is in needMet and verbFree, not in any string.

**CODE-8. The seer event's Glasswright option can never fire.** EVENTS.seer carries not:['ithar'], and its spliced option (data.js:327) needs fac:'ithar'. One of the two is the leftover. Oct 27 events synthesis, finding 2: the direction (drop the exclusion, or drop the option) is a design call for Opus. No text change either way.

**CODE-9. Haven still has no free exit (ruled addition, text supplied).** Ryan ruled on Oct 28, 2026: every fight-start event guarantees a free exit, and haven gains a leave option. At the pin, haven still offers only raid (a fight), tribute (40 credits, disabled when broke), and a Hullbreaker-only recruit. The wave 5 free-exit eval flags seven events, but six are pay-or-suffer events outside the ruling's fight-start scope; the regression test EVT-5, scoped to the ruling as written, fails on haven alone (chair reconciliation, Oct 30, 2026). Add as a fourth option: {k:'leave', l:'Leave the den alone', s:'Nothing happens.', r:{}}. Data addition, not a swap.

**CODE-10. Legacy class keys (optional sweep).** CLS_NAME maps four internal class keys to display names: Battle-barge to War-barge, Bio-titan to Colossus, Ark to Lattice-ship, Tomb-ark to Archive-ship. Chair check at the pin: every display path found (roster card, salvage screen, map fleet rows, class refit labels) routes through clsName(), so "Tomb-ark", the Eclipse flagship's cls key (data.js:101), does not reach the player today. The Rey red team narrative leg's framing ("displays a class name from the bible's forbidden list") is stronger than the evidence. The residual risk is any future raw use of .cls. Renaming the four keys in HULLS and dropping the map is a small sweep if Opus wants the risk gone.

**CODE-11. The decommission NaN is latent, not live.** The shipyard button (campaign_run.js:176, INV-1645) computes sell from HULLS[tpl].cost, which is undefined for eight hulls, so the label would print NaN. Chair check: the cost-less hulls are the three squadron templates and the five boss hulls. Squadrons never sit in the fleet as ships, and captures exclude boss hulls (finishBattle), so no cost-less hull can currently reach the button. The confirmation modal already uses prizeScrap, which handles the value properly. Guard the button the same way when convenient; it is not a live defect. (The Argon narrative leg reported it without the reachability check.)

**CODE-12. Debug tooling inside the player settings panel.** buildHud (ui3d.js:62) ships "Report a problem" (tooltip: "Save a snapshot of the game state for debugging", INV-1651 and INV-1652), "Diagnostics" (INV-1655), and the "Concept-art hulls" test toggle (INV-1658) to every player. T-92 to T-94 remove the Claude references from this surface. Whether debug tools belong in the shipped panel at all is a UI decision for Opus. Argon red team uiux leg, Oct 30, 2026, finding 6 (chair-verified).

### Decisions for Ryan

**DEC-1. Chorus song register: enforce the bible, or amend it.**
Story: bible r8 bans song for every faction, three times. The motif table (r8:96): "Song, choir, hymn, psalm, chant: retired: no faction sings; the Chorus speaks as 'we'." The Chorus section (r8:333): "Never sings. No song words in any Chorus name or line." The Glasswright section (r8:399): "No faction sings." Your own approved Chorus learning fiction (Oct 28, 2026) is flesh idiom, not song: "broods grown with the last generation's adaptations".
What the shipped game does today: it is compliant. The Chorus admiral is "The Mending Throng" (r8:338's own list), and no shipped Chorus string sings. The song register lives in the Oct 29 draft assemblies that Opus has not implemented yet: the firstrun recommended set's Chorus lines ("the brood sings its first true note", "learning songs of survival"), parts of the tier 3 Chorus texts, and one chair-selected chorus reword that also puts the admiral "in the dark water" (a naval image, Argon narrative finding 4).
Stakes: if the drafts ship as written, the Chorus contradicts its own bible in the first lines a new player reads, and every later Chorus text inherits the split. If r8 is amended instead, the ban's other job (keeping the Crusade on bells and oaths, the Glasswrights on tone) needs re-scoping too.
Cost: deciding now is cheap: a rewrite pass over the Chorus lines in two filed drafts. Deciding after implementation costs the same rewrite plus re-testing in Godot. Chair pick: enforce r8. The flesh register (taste, heat, smell, teeth) is more distinctive than song, and it is already the register the shipped game and your approved fiction use.

**DEC-2. The replacement name for "Acceptable Loss", and the bible's example list.**
T-01 removes the name from the shipped pool, per your Oct 28 ruling. No replacement was ruled. The chair suggestion on file is "Debt Paid", which fits the Crusade pool (oath, fire, cold, debt). One wrinkle: the bible itself lists "Acceptable Loss" as a Crusade ship name example (r8:192), so the bible needs the same swap whenever it is next edited. Cost: one word from you. If "Debt Paid" does not land, any oath-and-debt name works; the pool has 27 other names, so the game is not blocked on this.

**DEC-3. The star weapon trait: the words or the number is wrong.**
WTRAITS.star.d says "fast: hard to dodge". The trait sets evMult 1.2, which makes the target's evasion count MORE (the attack tooltip labels evMult above 1 as "(slow: evasion counts Nx)"). Either the trait should set evMult below 1 (a real fast weapon), or the text should stop claiming speed. Oct 27 text synthesis, batch 7 raised the family; the chair could not settle this one from text, because it is a balance question wearing a text defect. Cost: one number or one string, but the number changes weapon balance, so it is yours or Opus's with data, not a copy edit.

**DEC-4. Proposal wordings (small).** Three replacements in section 1 are chair proposals over verified defects: "Reclamation swarm" (T-06), "Backup frame" (T-07), "Last Trail" (T-82), plus the optional "homecoming" (T-85). A one-word veto on any of them costs nothing; the defects they fix stand regardless.

### Notes, not flags

**Out of scope: the Godot story stream.** The Argon narrative leg's findings about godot/story (outlines.md predating r8, retired Court and writ vocabulary being minted by new story text, an incorporation review graded by its own author) concern a separate workstream's drafts, not shipped browser strings. They are recorded here so they are not lost; they belong in the story stream's own pass, not this pack.

**Adjacent filed draft: the firstrun set's Crusade register.** The firstrun framing recommended set (filed, not shipped) writes the Crusade in a bookkeeping register ("entered in the ledger", "our clerks"). In r8 the ledger and the clerks belong to the Hegemony (r8:231: "Their dead: logged in the loss ledger"); the Crusade keeps chalked names, the Roll of Vesper, and debts (r8:152-156, r8:191-199). No clean swap exists inside the filed drafts, because all three models wrote the Crusade the same way. It needs a short re-voice pass before Opus implements the set. Recorded for the narrative synthesis.

**Checked and cleared (no action; recorded so they are not re-litigated).**
1. "Lantern Gut" (CAPTAINS.chorus.names). The Argon narrative leg flagged it against the bible's lantern ban. The ban (r8:156) sits in the Crusade's not-allowed list, and rename_map_final.md:537 lists Lantern Gut under "looked at and kept" for the Chorus. Not a defect.
2. "The Mending Choir". The Rey narrative leg cited the shipped admiral as still named "the Mending Choir" in data.js. At this pin she is "The Mending Throng", matching r8:338. The leg's citation is stale; no shipped string needs changing. (A code comment at data.js:660 says "The Ember Choir"; comments are not player-facing and it names a core's boon family, not the Chorus.)
3. Terrain numbers. TERRAIN_INFO (battle.js:13) matches the battle tooltips and the sector condition text (nebula 15, debris 10, storm shield and aim penalties). No defect.
4. NEM_ADAPT "why" strings ("you leaned on lances and ion fire", and the rest) are already neutral. Only the nemAdaptWhy fallback needed T-69.

## Section 3: coverage statement

**What was extracted.** data.js was executed in Node at the pin and every display field was walked: names, descriptions, blurbs, help-facing tables, event titles, bodies, variants and options (including the spliced options added after the base table), Nemesis tables (weaknesses, traits, adaptations, personas, behaviour cards, titles, scar titles, name fragments, spoken lines), protocols, patrons, aspects, perks, modules, relics and their faction name tables, hulls and variants, admirals and their Commands, name pools, ranks, verbs, wing stances and perks, sector conditions, node modifiers, heat rules, archetypes. That produced 1,630 inventory rows. The other shipped files (campaign_meta.js, campaign_run.js, ui3d.js, battle.js, campaign3d.js, main3d.js, scene3d.js, head.html) were read in full or in every string-bearing region, and 55 further rows were curated by hand: screens, panels, tooltips, tutorial tips, toasts, battle log lines, boot and error notices. Total: 1,685 strings in strings_inventory.csv, each with file, line, context, and id.

**How line numbers were found.** For data.js, the nth occurrence of the exact string at or after its table's declaration. For template-built strings in other files, the cited line is the line of the template. A row's data path (for example ADMIRALS.grax.n) is the reliable locator; the line is a courtesy.

**What was deliberately left.** Internal ids and keys; CSS and layout strings; code comments; numeric tuning values; name-fragment syllables are inventoried but not edited (they are parts of generated names, reviewed as pools, and no defect was found in them); the Godot tree (the port has its own text state, and the browser build is the shipped text of record at this pin); voidsworn-3d.html, which is the built artifact of these same sources; perf3d.js profiler strings and sim3d.js test text, which are developer tooling, not game copy. fx3d.js, ships3d.js, sfx.js, gfx3d.js, vfx3d.js, wfx3d.js and meshopt3d.js were grep-checked for sentence-like literals and toasts: no player-facing game copy found.

**What could not be verified.** Strings assembled at runtime from fragments (salvage yield sentences, debrief beat sentences built from NEM_BEAT_WORD) were inventoried at the fragment level; their assembled forms were spot-checked, not enumerated. The star trait contradiction (DEC-3) could not be settled from text. Whether any tree pick may touch fleet composition is a design question recorded elsewhere and does not affect any string here.

**Counts.** Inventory: 1,685 strings. Section 1: 96 replacement strings (including 2 removals, 3 chair-proposed wordings, and 1 optional note). Section 2: 12 code items, 4 decisions, 3 notes. Every filed text leg behind this pack (Oct 27 text and events audits, Oct 29 to 30 red team narrative legs, relics synthesis) was re-checked against the code at the pin; where a leg's claim did not survive the check, the pack says so (CODE-10, CODE-11, and cleared items 1 and 2).
