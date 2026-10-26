# Voidsworn story outlines: blind review

Reviewer: Claude Sonnet, 2026-10-26. Read: `godot/story/outlines.md` in full, `data.js` skimmed for faction names and weapon/ship naming only. No other review files were read.

## Verdict

The outlines are a solid skeleton with good instincts. The length discipline (100 to 150 words), the "every option costs something and doing nothing is never offered" rule, and the idea that six factions see the same Hollow Sun differently are all right. The best individual beats (Hegemony "Acceptable Limits", Ithar "The Lamp-Buoy", Chorus "The Drowned Song", Deathless "A Crown on the Wrong Head") would hold up in any good event game.

But as written, the arcs do not yet deliver the two things Ryan most wants from them:

1. **A rival who is personal.** The rival is a name slot plus a gruesome calling card. He never reacts to what you did, never differs in manner from one run to the next, and speaks exactly one line (taken from a 3-line table per faction).
2. **Choices that echo.** In all six arcs, one of the two beat 1 choices is a dead branch (its flag is never read), beat 3 reads no flags at all, and the "blue" option that a good beat 1 choice unlocks is strictly better than both normal options, so by run 3 it is a known optimum, not a dilemma.

There is also a concrete bug: the sample rivals include two women (Petra Lindqvist, Ilyra Glasswing) and one unknown-gender name, but the text uses "he/him/his" 53 times. And six of six beat 1 cards open with the same move (the rival leaves a grisly token), which will read as a tic by the second faction a player tries.

None of this needs a rewrite. It needs about five targeted changes (top 10 list at the end).

---

## 1. What the research says (and how I used it)

Caveat on method: most pages were read through a fetch tool that summarises, and a few (GDC Vault) only give session abstracts. I treat quotes as the page's wording only where marked, and the rest as paraphrase. I found no useful primary source for Sins of a Solar Empire 2 (its story layer is thin) and only a review-level source for BattleTech. Nothing below is padded to cover that.

**Rivals and nemeses**
- Monolith's own framing of the Nemesis system is emotional range and memorability: orcs the player enjoys hating (and ones they come to love), with "exceptional moments" and "long-term relationships". Chris Hoge, GDC session summary: [Helping Players Hate (or Love) Their Nemesis](https://www.gdcvault.com/play/1025150/contactUs).
- Michael de Plater says the system works by picking a few "anchors" (such as being killed by an orc) and letting players fill the gaps. His models are the surviving villain in a tabletop game and Batman's rogues, whose scars point back at the hero. Source: [GamesBeat interview](https://gamesbeat.com/shadow-of-mordors-nemesis-system-draws-from-burnout-football-and-an-architecture-book/).
- Players describe the pay-off in concrete terms: a captain you thought dead returns and cites the wound you gave him, and his face shows the sword marks. Dying promotes him. Source: [PC Gamer on Shadow of Mordor](https://www.pcgamer.com/games/action/shadow-of-mordor-is-worth-revisiting-for-the-nemesis-system-alone). Randomised names, traits and personalities do the rest ([Game Developer, Shadow of War system analysis](https://www.gamedeveloper.com/design/core-system-analysis-of-middle-earth-shadow-of-war)).
- Failure modes: the system loses force when the player is strong enough to kill threats before they can evolve ([Inverse](https://inverse.com/article/33370-middle-earth-shadow-of-war-needs-to-fix-the-nemesis-system)), and the team's own postmortem warns that feature creep pulled it away from the core promise of "personal villains" ([Shadow of Mordor postmortem digest](https://gamebanshee.com/k3axd)). Lesson for Voidsworn: keep the rival small, but make what little there is depend on the player's history.

**Short choice beats**
- Slay the Spire: Anthony Giovannetti calls risk versus reward the core design ([Think Like a Game Designer](https://justingarydesign.substack.com/p/anthony-giovannetti-crafting-slay)). Mega Crit says that for Slay the Spire 2 they want to avoid events where you "simply do nothing and pass through", and that a choice can be among poor options and still be a good event ([PCGamesN](https://www.pcgamesn.com/slay-the-spire-2/events-redesign)). Voidsworn already follows this. Credit where due.
- FTL: Justin Ma says the story "isn't something that is told to you by a writer" and comes from play, with events shaped by your crew and equipment ([Epic Games, A Decade of FTL](https://store.epicgames.com/news/a-decade-of-ftl-faster-than-light?lang=pt)). The outlines never mention a named captain or the actual fleet.
- Into the Breach: sparse text that supports the mechanics is cheap and effective, but the lack of a finale or any payoff for the worlds you saved left one critic with little lasting impact ([Game Developer comparison with Tactical Breach Wizards](https://www.gamedeveloper.com/design/let-s-compare-and-contrast-the-narrative-design-of-tactical-breach-wizards-and-into-the-breach)). Voidsworn has a finale, which is a real advantage. It should be spent well.
- BattleTech: reviewers liked the writing and crew, but the expendable MechWarriors got little development, which weakened the tie between tactical losses and the story ([DualShockers](https://dualshockers.com/battletech-review/)). Same risk for Voidsworn's captains.
- Darkest Dungeon: Red Hook calls hiring Wayne June as narrator "one of the best decisions we've made" and wrote the trailers and dialogue for his cadence ([Game Developer, Road to the IGF](https://www.gamedeveloper.com/audio/road-to-the-igf-red-hook-studios-i-darkest-dungeon-i-); [GameSpot](https://www.gamespot.com:443/articles/the-gothic-sensibilities-of-darkest-dungeon/1100-6424880/)). One strong, consistent voice carries tone more than plot does.
- Stellaris: events and flavour text are praised early, then criticised for drying up, and event pop-ups not being logged weakens the sense of an ongoing story ([Scientific Gamer review](https://scientificgamer.com/thoughts-stellaris/)). The Chronicle on the Career screen is Voidsworn's answer to the logging problem. Good.

**Repetition and runs**
- Hades: Greg Kasavin asked why not "have the characters acknowledge and be self aware of the cycle", has characters comment on how you play (weapon choice, resources), and treats death as part of the story ([ScreenHub](https://www.screenhub.com.au/news-article/features/digital/jini-maxwell/hades-greg-kasavin-breaks-down-supergiants-unique-approach-to-narrative-262459); [But Why Tho](https://butwhytho.net/2021/08/13/interview-developing-hades-with-supergiant-games-greg-kasavin/)). The lesson is not "write more"; it is "react to what this player did".
- Emily Short on storylets and salience: content is tagged with conditions, the best-fitting card is picked, broad defaults cover most cases and more specific variants are added over time, and variants are cheap to add when consequences are limited ([Beyond Branching](https://emshort.blog/2016/04/12/beyond-branching-quality-based-and-salience-based-narrative-structures/)). Her GDC session abstract also recommends paying off big decisions with character crises at dramatic moments ([Choice and Character](https://www.gdcvault.com/play/1016584/Choice-and-Character-Lessons-from)).

**Moral choices**
- Mass Effect's paragon/renegade is criticised as a false dichotomy that ignores context ([PopMatters](https://www.popmatters.com/156517-mass-effect-2495868136.html)) and as a meter that judges you against a hidden standard instead of giving real consequences ([GamesBeat](https://gamesbeat.com/morality-metrics-in-videogames/)). A choice is meaningful when it has real gains and real losses and the game lets the player judge. Voidsworn has no meter, which is correct. Keep it that way.
- Warhammer 40,000: Rogue Trader: the RPG Codex review praises tone and setting but says companions ignore the player's incriminating statements, faction motivations are held back for a late exposition dump, and alignment options blur into generic good and generic evil ([RPG Codex](https://rpgcodex.net/article.php?id=12918)). Direct warnings for the callback and finale design here.

---

## 2. Per faction

### 1. Voidsworn Crusade, "The Oath at the Hollow Sun"
- **Strongest: Beat 2, The Burning Choir.** A looping recording sung by a dead hand is a strong image, and "the oath allows no answer that is both swift and holy; choose which sin you will confess" is the best choice framing in the document: the two options cost different things (time versus fury) and the faction's own vocabulary names the dilemma.
- **Weakest: Beat 3.** The two options ("Sing the Rite" and "litany of names") are nearly the same action, singing, with different stat rewards, so the choice is a menu pick. It ends on "The oath does not ask you to survive. It asks you to finish", which is the stock closing line of a thousand grimdark cards. Also the chalk names are introduced for the first time at the finale.
- **Biggest fix: plant the chalk names in beat 1 and cash them in at beat 3, and make the saint's hand matter at the end.** The chalk names are the arc's best original image and are currently buried. The hand is carried or sold in beat 1, shows up as a warm casket in beat 2, and then vanishes.
  - Beat 1 insert (original): *Before the fleet leaves the shrine, every captain chalks one name on the flagship's hull, the person they refuse to have forgotten. The litanists do not bless the names. They only count them.*
  - Beat 3, if the hand was carried (original): *{rival} asks for nothing but the hand. The names on the hull are the only part of this he cannot take.* If sold: *The pilgrims who bought it send a single word on the open channel: "Forgiven." It does not help.*
  - Name the option by what is said: **Read the chalk names aloud, living and dead** (replaces "Answer him with the litany of names").
- Voice note: this is the arc closest to Warhammer 40,000 (see section 3).

### 2. Hegemony Navy, "Pacification Order 41"
- **Strongest: Beat 2, Acceptable Limits.** Best beat in the whole document. Eleven haulers, one escort, "a lieutenant of nineteen", "watch eleven crews die on schedule", plus the dryness of "within acceptable limits". It has a real person, a number, and a rules-versus-conscience tension without a good/evil meter.
- **Weakest: Beat 3.** The unrecorded speech is a great idea, but the player never says anything: the choices are "Speak of duty" or "Read the names from the listening post". Two problems: the listening post crew were never named in beat 1 (they only spelled the rival's name), and the lieutenant from beat 2 is dropped completely.
- **Biggest fix: bring the lieutenant back and let the player say actual words.**
  - If you broke the column out (original): *On the open channel a young voice reports eleven haulers formed up on your port side. Nobody ordered it. The flag captain does not remark on it.*
  - If you didn't: *The column's eleven registry numbers scroll across the flag captain's slate. He has read them twice. He does not ask what you will say. He only turns the slate toward you.*
  - Options with words: **"We were told to hold. We will hold forward."** / **Read the eleven numbers, then the post's crew.**
- Smaller: the nine-page appendix and "stamped in triplicate" gags are great. Do more of this and less of the portentous closer.

### 3. Ashfall Corsairs, "Saints' Gold"
- **Strongest: Beat 1, The Gift Box** (for voice) and **Beat 2, Rattlehold Auction** (for choice design). The quartermaster who wants a bomb in the box versus the bosun who wants a party is exactly the right comic split, and "Nobody has ever called the bosun honest before, and he looks uneasy about it" is the best single joke in the document. The auction has three real approaches, one with a credit price, one with an ambush start, and one earned by an earlier choice.
- **Weakest: Beat 3.** "Promise double shares" (20 XP) versus "Promise nothing, and mean it" (+60 credits) has a good question under it ("which crews are which") that is never answered on screen. The win text gives the same ending whichever promise you made. The rival chaining his fleet to the wrecks "daring you to shoot through his own prize" is a strong setup that is never used.
- **Biggest fix: make the promise be a promise.** Store it and have the epilogue and the next run's opener remember it. Also give the party branch (a dead branch today) a payoff, and use Old Mott as the faction's recurring face (he weeps in beat 3 but is a pure prop).
  - Win, double shares (original): *The split takes three days and one hanging offence. Mott signs for his grandmother's share and has it framed.*
  - Win, no promise: *Nobody cheers. Everybody counts. Then, quietly, the quartermaster buys the first round with his own money, which has never happened.*
  - Beat 2 callback for the party (original): *Mott recognises the auctioneer's ledger hand from the party. He is still ashamed of what he said there. The bosun gives you a look that says use it.*

### 4. The Chorus, "Eat the Sun"
- **Strongest: Beat 2, The Drowned Song.** The only beat where a choice gives a ship (teach the spawn the song, a drone joins). "The hunger has never had to choose before" is a good line and the argument between "oldest throats" is a character beat, not a lecture. This is where the Chorus feels like its own thing and not a copy of something else.
- **Weakest: Beat 3.** "The swarm does not answer in words. It has never needed them" followed by a page of words. It ends on "There is only forward. There has only ever been forward." Both options are generic stat picks (regrow or weakness).
- **Biggest fix: write the Chorus in the short lines its own voice note promises, and give it two argumentative throats the player can listen to.** The voice brief says "short lines" but the cards run long, lyrical sentences that look like the Ithar and Voidsworn cards. Two named throats (say, Hunger and Memory) arguing each beat would give the player someone to side with, which is what Darkest Dungeon's narrator and Hades' cast do for their games. Beat 3 rewritten in the Chorus voice (original):

  > The sun sings. Every throat hears it.
  > He stands in front of the song.
  > Hunger says: open every mouth.
  > Memory says: sing it back first. Learn it. Then eat.
  > Nine mouths. One answer. Soon.

- Also: the "Eat the dead" branch sets a flag (`ch_ate`) that nothing reads.

### 5. The Ithar, "The Grave of Houses"
- **Strongest: Beat 1, The Lamp-Buoy.** Small, specific, intimate: an old thing offers its last song, and taking it ends it. The best moral choice in the document in the sense GamesBeat means, with a real gain (weakness) and a real cost the player judges for themselves. The blue payoff in beat 2 (the song "rises unbidden in your throat") is the best-designed callback, because it is emotional, not just a number.
- **Weakest: Beat 3.** "Raise the sails" (20 XP) is the emptiest label in the set. The central fact of the faction, that when the Ithar die nothing is born to replace them, is first said at the finale, which is where a reveal is worst (compare the Rogue Trader exposition complaint).
- **Biggest fix: pay off the mercy branch and plant the "no children" fact in beat 1.** Mercy sets a flag nothing reads. Give mercy its own blue in beat 2 that is a different trade, not a weaker one:
  - **Hum the warning, not the song** (original): the captains remember the buoy's warning and the wrecks do not scream at them. 20 XP, no damage, no weakness. The song path gives weakness, no XP.
  - Plant it early: *The elders have not named a child in four hundred years. The buoy hums a lullaby anyway.*

### 6. The Deathless Dynasty, "The Court Restored"
- **Strongest: Beat 2, A Crown on the Wrong Head.** "The overseers have calculated the insult to eleven decimal places" is the most distinct voice in the set, and the law-versus-insult choice is a real values clash. It is the only one where the faction's character (law above survival) is the dilemma.
- **Weakest: Beat 1.** The beheaded warden "facing the door, watching for you" is the sixth grisly token in six arcs, and the two options (honed legions, or +50 credits) are functionally generic. Patience pays money, which is a strange reward for a species that waits ten thousand years for fun.
- **Biggest fix: make a broken law cost something that comes back.** "Wake the reserve" says the law is broken and nothing ever follows from it except the clock. A faction defined by law and census should keep books.
  - Beat 3, if the reserve was woken (original): *The census engines list the reserve legions as "irregular". They stand at the formation's edge. The honour guard will not stand beside them.* Then the honour-guard option repairs 10% instead of 20%, or the reserve fights in a stated place. The player sees the cost they chose.
  - If patient and the flaw was triggered: *The crown's maker hid a flaw, and now a rival wearing it learns what that flaw was.* (A different payoff from the other branch.)

---

## 3. Cross-cutting

### Do choices feel meaningful, and do consequences get felt?
- **Good:** no "do nothing" options, every option has a price, no morality meter, and the sector pacing (one choice per sector) is respectful of the player's time.
- **Problem 1, dead branches.** In every arc only one of the two beat 1 options has a beat 2 callback. The other option (the quick-reward one: sold the hand, followed orders, threw the party, ate the dead, let the buoy sleep, ran the vengeance protocol) writes a flag nobody reads. Count: Voidsworn `vesper_sold`, Hegemony `hg_orders`, Corsair `cs_party`, Chorus `ch_ate`, Ithar `it_mercy`, Deathless `dd_vengeance`. Six flags, zero readers.
- **Problem 2, the blue option is a superset.** In all six arcs the unlocked blue option gives a weakness reveal plus extras and usually avoids the clock penalty. Example: Hegemony blue = column saved + weakness + 15% repair, versus 25% repair + clock penalty (disobey) or +80 credits (proceed). On the first run it reads like a reward for remembering. On the third run it is a solved puzzle: always pick the beat 1 path that unlocks it. Fix: make blue a different trade (shown above for the Ithar), or make the unlocking choice carry a visible cost that stays on (e.g. the clock penalty carries into beat 3).
- **Problem 3, beat 3 reads nothing.** It does not check any flag and the win/loss lines are the same whatever you did. This is the Rogue Trader failure in miniature: the player's earlier choices are not acknowledged at the climax. Fix: each win and loss line gets one flag-conditional sentence (cheap: 6 arcs x 2 flags x 2 endings = 24 sentences).
- **Problem 4, beat 3 choices are the same kind of choice in every arc.** Five of six are "gain 20 XP" versus "repair 20%" or "weakness". The label says one thing, the reward is a menu item. Make the label a thing the player says or does, and let the fiction differ.
- **Problem 5, no aftermath text.** The outlines list effects (credits, XP) but no one-sentence result line after each choice. Mordor and Hades both make you feel consequences through reaction, not numbers. A 15 to 25 word result line per option is the cheapest felt-consequence tool available, about 36 lines in total.
- **Problem 6, the fleet does not appear.** FTL's events lean on your crew and ship. These beats talk about "your captains" in the abstract. One named captain per card (pulled from the real roster, for example the highest-XP or the newest) would add personal stakes for the cost of a token.

### Is the rival memorable and personal across runs?
Not yet. What the rival is today:
- Beat 1: he leaves a token. Beat 2: he sets a trap. Beat 3: he stands in the way and says one line from a table keyed only to his faction. Every Deathless rival says the same three lines; every Corsair rival says the same three. That is a recurring prop, not a nemesis.
- He never knows what you did. The text is the same whether you beat his fleet in sector 2 or ran, whether he killed three of your ships or none. Mordor's pay-off was memory: wounds, promotions after killing you, a captain you thought dead returning to cite the damage.
- Nothing about him changes between runs except his name and faction. Mordor's is randomised traits and personalities on top of history.

Cheap fixes (all use things the game already tracks, with the assumption that I could not check what stream B stores):
1. **Grudge facts.** Pass in three or four run facts: his clock level, whether you beat him in an earlier fight, your first lost ship, your best captain. Use one in the beat 3 hail ("You lost the *{ship}* three sectors back. I kept the bell.").
2. **A temper**, rolled with the name: for example Proud, Patient, Hungry, Cruel. One faction-neutral insert sentence per temper per beat (12 sentences in total) that swaps in for the grim token. Written without pronouns so it works for any commander.
3. **He speaks in all three beats**, even if only five words, not just at the end.
4. **The Hollow Sun is his too.** The six factions each read the dead star differently (relic, anchorage, treasure, seed, archive, tomb). That is a real strength. But the rival's hail should say what the Sun is to him. Replacement hail table, original:

| His faction | Hail that names what the Sun is to him |
|---|---|
| Voidsworn | "That coal is a reliquary and I am the last priest it has. Your hands are not clean enough to light it." |
| Hegemony | "The survey says the anchorage holds nine fleets. It will hold one. Stand down and be counted." |
| Corsair | "I got here first, so it's mine. That's the entire law out here. Say hello to my chains." |
| Chorus | "It is warm in our mouths already. You are only the part in the way." |
| Ithar | "This was my house's lamp before your people learned fire. I only came to see it put out properly." |
| Deathless | "I held this tomb before your kind had a word for sun. Kneel, and be entered as a guest." |

### Is the rival's mismatch with his faction a problem?
Yes. The text treats the rival as a human-like individual with the same manner whichever faction he comes from. A few examples of 30 possible pairings (6 player arcs x 5 rival factions) that read oddly:
- Corsair beat 2: the rival "has bought the auctioneer, the guards and most of the docking clamps". If he is a Chorus or Deathless commander, this is absurd.
- Voidsworn beat 1: keepers "nailed to their own doors" and a message cut in stone. Chorus rival? A written threat from a hive mind?
- Ithar beat 3: "cold, careful lances, as if peeling fruit" implies Ithar-style weapons.
- Hegemony beat 1: the crew arranged to spell his name. Fine for a Hegemony commander, strange for a Chorus one.

The fix is a one-sentence slot, `{rival_mark}`, that the rival's faction fills (5 variants, so 30 total across the six arcs), plus pronoun-free phrasing. The placeholders `{he}`, `{his}` can also work if the Nemesis name generator knows gender. As written, gender is a bug: 20 "he", 14 "him", 19 "his", and two sample names are plainly female.

### Are the six factions' voices distinct?
- **Clearly distinct:** Hegemony (paperwork, acceptable limits, stamps), Corsairs (jokes, shares, grudges), Deathless (census, contempt, correction). These three do it in sentence shape, not just nouns.
- **Blurred together:** Voidsworn, Chorus, Ithar. All three use the same register: elegiac, cold, "a thousand years", "dead star", "old", "silence". The Chorus was supposed to speak in short lines and the Ithar in grief and light, but both read as slow, lyrical prose, like the Voidsworn card. If you block out the faction nouns on beat 3 of those three arcs, you cannot tell them apart.
- **Shared tic:** most beat 3 cards end on a balanced aphorism ("It does not ask you to survive. It asks you to finish." / "There is only forward. There has only ever been forward." / "They never sang that the Ithar would fade quietly." / "What was ours is ours."). Four of six use the same device. Pick one or two arcs that keep it and cut the rest.
- **Suggested voice rules** (a half-page style card the writer can check against):
  - Hegemony: documents and numbers; humour by understatement.
  - Corsair: gallows jokes; names of people; money.
  - Deathless: law and count; polite contempt; no emotion words.
  - Voidsworn: second-person liturgy, imperatives; short call-and-response lines.
  - Chorus: sentences under eight words; "we"; senses (taste, heat, hum).
  - Ithar: past tense and memory; light and glass images; long sentences allowed here only.

### How will it read on the 5th or 20th run?
Today it is 3 fixed cards per faction. A player who sticks to one faction (the likely case: this is a roguelite, and players learn one fleet first) sees the same three cards on every run. By run 5 they skim; by run 20 they skip, and the blue option is a solved puzzle. Hades does the opposite: it keeps reacting to what this player did, and acknowledges the cycle in-world.

Recommendations, cheapest first:
1. **Flag-conditional epilogues and hail lines** (above). Zero new beats.
2. **A pool of 2 to 3 variants per sector per faction** that share flags and effects but change the situation. The arc spine stays the same (Hollow Sun), but sector 2's trap, for example, rotates. Cost: 6 factions x 3 sectors x 2 extra = 36 cards, about 5,000 words. Emily Short notes variants are cheap when consequences are limited; yours are.
3. **A shared rival-incident pool**, rival-faction-flavoured not player-faction-flavoured: about 12 short cards (for example, "{rival} offers a truce", "a captured ship of theirs is for sale", "his officer defects") with 4 to 5 variants by rival faction. These are the cards that make a rival feel like a continuing figure, and they work for any player faction. Cost: about 12 x 5 short lines.
4. **Use the Chronicle as memory.** If captain names persist between runs, put names from the last lost fleet into the chalk list or the litany or the names read on the open channel. Short, personal, and nothing else in the genre can fake it.
5. **A short form for old players.** After N finished runs of the same arc, show a 40-word version with the same choice. Cheap and respects the player's time.
6. **A lint.** `check_outlines.py` already checks length and dashes. Add a render of all 30 faction/rival pairings so a human can read one run of each and catch mismatches like the auctioneer one.

### Clichés and closeness to Warhammer 40,000
The text does not copy any line that I recognise. The issue is premise and vocabulary. Matching, as one reader sees it:
- **Voidsworn**: Imperium crusade and Adepta Sororitas flavour: saints, relics, litanists, confessors, heretics, "the pyre", plus weapon names in `data.js` ("Las-repeater", "Penance lance", "Hellfire torpedo", "Censer flak").
- **Hegemony**: Imperial Navy and Administratum satire ("Admiralty", "acceptable losses", bureaucratic dread).
- **Corsairs**: Ork freebooter feel in "scrap scatter gun", "junk turret", "Warlord's Pyre-Barge" and a rogue-trader treasure hunt.
- **Chorus**: Tyranids almost point for point (a hungry swarm, a hive mind, devouring a sun, "Hive Leviathan" as the boss ship, which is the name of a real Tyranid hive fleet, plus "brood-mother", "hive cluster").
- **Ithar**: Aeldari: a dying elder race, songships, "wraith" carriers, "the younger races", and the "when we die nothing replaces us" theme.
- **Deathless**: Necrons: dynasties and dynasts, tomb worlds, waking from a long sleep, reclaiming crownworlds from "squatters", overlords and cryptlords, "gauss flayer", "doom arc".

That is all six factions mapped to one existing setting. For a personal project it is a design choice; for anything public, "Hive Leviathan", the gauss and doom weapon names, and "Dynast" are the closest (the rest are common SF). Whatever Ryan decides on that, the story can still be original by giving each faction one twist the source setting lacks, using ideas already in the outlines:
- Voidsworn: not heretic-hunting but **a debt of names** (the chalk list). Oaths as a ledger the dead can call in.
- Hegemony: keep the bureaucracy comedy, but make it a **quiet horror about being counted**. This one is already the most original.
- Chorus: not appetite alone but **a hive that learns songs and speaks with the voices of what it ate** (the "teach the spawn the song" beat is the seed of this).
- Ithar: not a doomed elegant race but **archivists who are annoyed**: grief expressed as fussy, funny preservationism. Fewer tragic aphorisms.
- Deathless: keep the census voice, but give the Dynasty **a bookkeeping flaw**: they cannot forgive a debt, and that is what will end them.
- Corsairs: already the freest of the six. Keep.

Other clichés in the text itself:
- **The gruesome calling card, six times in six beat 1s**: nailed keepers, a crew in vacuum spelling a name, a severed tattooed hand, a brood-node cut open, a buoy's memories eaten, a beheaded warden watching the door. Keep two or three, and make the others a different kind of first contact (a courtesy, a bribe, a trade offer, a stolen flag returned).
- **"Dead star, old, cold, thousand years"** appears across five arcs.
- **The rival arrives first and waits in the wrecks** at beat 3 in every arc.
- Smaller: "Choose which sin you will confess", "the hunger has never had to choose before", "the Dynasty has had setbacks before" are good, but similar closing-twist structures stack up.

---

## 4. Ranked top 10 changes

1. **Give the rival history and a manner.** Add run-fact "grudges" (first lost ship, best captain, whether you beat or fled him), a temper roll with faction-neutral insert sentences, and at least a short spoken line in all three beats. This is the single biggest gap versus what makes Mordor's rivals stick.
2. **Rewrite the beat 3 hail so the rival says what the Hollow Sun means to him,** not a generic taunt (table above). It costs 6 lines, turns the finale into six readings of one place, and fixes the generic "one rival line" problem.
3. **Kill the dead branches and give beat 3 memory.** Every beat 1 option needs a beat 2 callback, and every beat 3 win and loss line needs a flag-conditional sentence. Six flags today are written and never read.
4. **Make blue a sidegrade, not a superset.** Give each blue option a different trade (XP versus weakness, damage versus clock). Otherwise the beat 1 choice is solved by run 3.
5. **Fix the rival-faction mismatch and the pronouns.** Add `{rival_mark}` slots (the five-faction variants) and pronoun-free text or gendered tokens. Two sample names are female and the text uses "he" 53 times.
6. **Add a variant pool and a short form.** Two to three variants per sector per faction, a 12-card shared rival-incident pool, and a 40-word skim version after several finished runs.
7. **Use the Chronicle as cross-run memory.** Put lost captain names and past outcomes into later runs' chalk lists, litanies and hails.
8. **Add a 15 to 25 word result line after each choice,** and rewrite the beat 3 labels as things said or done ("Read the chalk names aloud") instead of stat menu names.
9. **Separate the voices.** Sentence-length and device rules per faction (Chorus short lines; Ithar fussy, not only tragic), and cut the closing aphorism from at least four of six beat 3s. Replace three of the six gruesome beat 1 tokens.
10. **Plant and name your payoffs, and take one step away from Warhammer.** Plant the chalk names, Mott, the lieutenant, the buoy, and the Ithar's "no children" fact in beat 1 and cash them in at beat 3. Add one original twist per faction (section 3) and review the closest nouns in `data.js` (Hive Leviathan, gauss, doom arc, Dynast) if this will ever be public.

## 5. What I would not change
- The three-beat structure and word count.
- No "do nothing" option anywhere.
- Text only, no portraits. The Chorus and Deathless are better without faces.
- One shared dead-star board. The Hollow Sun as six different meanings is the best idea in the document. Spend more on it.
- The Hegemony and Corsair voices. Do not sand them down while fixing the others.
