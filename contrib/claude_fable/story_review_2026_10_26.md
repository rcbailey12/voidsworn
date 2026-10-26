# Blind review: the six faction story arcs (godot/story/outlines.md)

Reviewer: Claude Fable, Oct 26 2026. Independent read, no other review files consulted. Nothing in the repo was changed except this file.

Short verdict: the voices are good and several lines are genuinely strong, but the six arcs are one story template worn six ways, the rival is the same sadist in every run, and the choices mostly fail as dilemmas because the numbers behind them are lopsided or dead. The writing is ahead of the design. Fix the skeleton and the prose will carry it.

---

## Part 0. What the research says short choice-driven beats need

I read primary interviews, postmortems and well-regarded design writing on the games Ryan named. The lessons that matter for a 100 to 150 word card read three times per run:

**1. Every option must do something, and not every option should be good.** Mega Crit, redesigning events for Slay the Spire 2: "This time around we're trying to avoid having any options where you simply do nothing and pass through," and events "don't all have positive choices for the player" ([PCGamesN](https://www.pcgamesn.com/slay-the-spire-2/events-redesign)). Red Hook's design goal for Darkest Dungeon was the same in one line: "We set out to make you feel like there's a cost" ([GamesBeat interview with Bourassa and Sigman](https://gamesbeat.com/darkest-dungeon-designers-really-arent-sadists-were-realists/3/)).

**2. Choices feel real when the player can predict the result, and when the result comes back later in a form the player did not choose.** Nikhil Kashyap's analysis of Telltale's choices: meaningful choices need that "the player has a basis to predict the consequence of each option," consequence can be deferred, and it can show up in how characters react rather than in the thing the choice was nominally about. He also defends explicit feedback like the "will remember that" toast because it tells players a choice landed ([Game Developer](https://gamedeveloper.com/design/meaningful-decisions-in-branching-narratives)). The sub-Q piece on branching choices adds that "what the player chooses matters, but not as much as what choices are offered," and that "the shorter choice text is better at expressing the tone and significance of an action" ([sub-Q](https://sub-q.com/making-interactive-fiction-branching-choices/)). Both apply directly: the outlines' option labels are good and short; the consequences almost never come back.

**3. Repetition is the enemy, and the two known cures are variant text and self-awareness.** FTL's own modding community notes that vanilla events leading to combat "usually draw their texts from a text list," which hides the repetition, and that writing "3 or 4 different flavor texts" per encounter is a reasonable floor ([Subset Games forum](https://subsetgames.com/forum/viewtopic.php?p=94011)). Justin Ma described FTL's events as "choose your own adventure" cards that make a run feel like an episodic sci-fi show, with each race having "unique personalities, ships and encounters" ([Engadget](https://www.engadget.com/2012-09-19-the-joystiq-indie-pitch-ftl-faster-than-light.html)). Greg Kasavin's cure in Hades was the other one: "I try to acknowledge these little aspects of player behaviour," and since players see the same boss many times, "why not have the characters acknowledge and be self aware of the cycle?" ([ScreenHub](https://www.screenhub.com.au/news-article/features/digital/jini-maxwell/hades-greg-kasavin-breaks-down-supergiants-unique-approach-to-narrative-262459)). On the GDC podcast he framed the whole roguelike story problem as: the thing that carries forward is the player's knowledge, so build the story on that, for example a roguelike where bosses remember earlier fights ([GDC](https://gdconf.com/news/roguelikes-and-narrative-design-hades-creative-director-greg-kasavin-gdc-podcast-ep-16)). Hades also makes death move the story forward instead of resetting it ([itch.io essay on loops and arcs](https://itch.io/blog/774695/to-hell-and-back-again-a-look-at-loops-and-arcs-in-hades)).

**4. A rival is personal when he remembers specific things, carries visible marks of them, and gets stronger when he beats you.** Michael de Plater on the Nemesis system: the design picks "anchors of gameplay" rather than scripting everything; the model is the tabletop villain who survives and comes back, "taking that guy and bringing him back as a recurring villain"; scars make history visible; and the Madden commentary model turns a career into a story ([GamesBeat](https://gamesbeat.com/shadow-of-mordors-nemesis-system-draws-from-burnout-football-and-an-architecture-book/)). A captain who kills the player is promoted and returns harder ([Wikipedia](https://en.wikipedia.org/wiki/Middle-earth:_Shadow_of_Mordor)). Critics loved it because each rival was "likely never existed in anyone else's game" ([PCWorld](https://www.pcworld.com/article/406012/middle-earth-shadow-of-wars-unqiue-nemesis-system-makes-battles-even-more-personal.html)), and the one notable complaint is the one Voidsworn should fear: Destructoid found it gimmicky where it added "different appearances and weaknesses without making villains feel personal" (via Wikipedia above). The core-systems analysis notes each captain "will remember the player whether from a previous battle or killing their ally" ([Game Developer](https://www.gamedeveloper.com/design/core-system-analysis-of-middle-earth-shadow-of-war)). Lesson: a random name and two random weaknesses is the gimmick half. The memory half is the part that works.

**5. Less text, placed at the moment the mechanic bites, beats more text.** Into the Breach's story is zone-leader briefings, a few lines at run end, and pilot barks on damage, kills and saves; the point is "to use the essence of narrative to inspire players to engage with the core mechanics" ([Game Developer](https://www.gamedeveloper.com/design/let-s-compare-and-contrast-the-narrative-design-of-tactical-breach-wizards-and-into-the-breach)). Its lines work because they raise questions the game never answers and because "mechanics carry characterization" ([Kotaku](https://kotaku.com/into-the-breach-tells-its-story-through-its-characters-1824159682)). The Darkest Dungeon narrator works for the same reason: he speaks "every time mortality is clarified in a single blow or the tide changes," warns after an easy win and exults when a hero rises, and otherwise stays out of the way ([TechRaptor](https://techraptor.net/gaming/features/darkest-dungeon-narrator)).

**6. Faction voice comes from a predicament, not a vocabulary.** The Sins of a Solar Empire 2 lore gives each faction a trap it cannot leave: the TEC "faces a near hopeless dilemma," the Vasari "are simply unable to withdraw without catastrophic losses," the Advent are exiles who built a myth of destiny from their persecution ([Sins 2 lore](https://www.sinsofasolarempire2.com/lore)). Harebrained Schemes let the Great Houses be "felt" rather than shown ([GamingBolt](https://gamingbolt.com/battletech-interview-the-biggest-battletech-game-yet)), and the Flashpoint reviewer praised "excellent little self-contained stories" where pursuing a traitor "came with a massive hit to reputation with his faction" that changed prices and rewards afterwards ([GameCritics](https://gamecritics.com/steven-brown/battletech-flashpoint-review/)). The Rogue Trader review is a warning: the Dogmatic path was "the most consistently written and perhaps most interesting option" because it had one clear idea, while the Heretical path "mixes actual heresy and Chaos worship with about an equal amount of random senseless Chaotic Evil," and the plot "loses most of its coherence" once the player stops driving it ([RPG Codex](https://rpgcodex.net/content.php?id=12918)). One clear idea per faction, held to, beats a wide vocabulary.

Those six lessons are the yardstick below.

---

## Part 1. Per faction

### 1. Voidsworn Crusade: "The Oath at the Hollow Sun"

**What works.** The voice is consistent and the best lines are earned: "Choose which sin you will confess." "The oath does not ask you to survive. It asks you to finish." The chalk names on the hull are a concrete image that pays off in the loss line ("The chalk names burn with the hull"). The win line giving the player a verse with their name in it is the right kind of reward for a crusade. The saint's iron hand warming in its casket is a good bracketed callback.

**What falls flat.** Beat 1 is three cards in one: setting, mission, rival, and a choice, and the choice is not a dilemma. A relic versus 60 credits is a maths question, and most players will carry the hand every run because the blue option in beat 2 then hands them both rewards for free. Selling a saint's hand has no story cost at all: the keepers beg, you sell it, and nobody ever mentions it again. The Ashen Vigil "choir still singing over open channels" is a strong image but it is the third singing faction in the document (see cross-cutting). Beat 3's choice (20% repair versus 20 experience) has no story in it.

**Biggest improvement.** Make selling the hand cost something the crusade would feel, and make carrying it cost something too. Suggested rewrite of the beat 1 options:

- *Carry the hand into battle.* Gain a relic. He knows where it is: the clock moves on one.
- *Sell it to the pilgrims.* +60 credits. The litanists strike your name from the Rite until you earn it back. (Beat 3 option "Answer him with the litany of names" is greyed out with the note "the litanists will not sing a name that sold the saint." A blue option appears instead: *Buy back the name (60 credits).*)

And give the blue in beat 2 a price so it is a choice, not a cheat code: *Raise the hand before the crews.* The hand goes cold in the raising. Lose the relic; a weakness revealed and 15 experience for every captain.

A trimmed beat 1 opening, to show how much can go: "The litanists read the charge on every deck while the fleet holds station over Saint Vesper's moon. The confessors bring a second matter. {rival} has emptied the reliquary and nailed the keepers to their own doors. He left one thing on the altar: the saint's iron hand, and a message cut into the stone beneath it. I will return for this, and for you."

### 2. Hegemony Navy: "Pacification Order 41"

**What works.** This is the best arc. "The definition of acceptable is attached as an appendix of nine pages" is the best line in the document. "Intelligence has a file on him and nothing in it that helps." The listening post crew "arranged to spell a name" is a genuinely chilling calling card. Beat 2 is the only real dilemma in the six: obey and let eleven crews die on schedule, or disobey. The lieutenant of nineteen is the right detail. "There is one tradition left in the Navy that no appendix governs" turns the faction's own coldness into the emotional beat. The loss line ("Within a month a new commander receives it, sealed, numbered and without courtesy") is the best ending in the set and is already a cross-run hook.

**What falls flat.** The rewards undercut the dilemma. Disobeying gives 25% repairs and the column; obeying gives 80 credits. There is no price for disobedience beyond the clock, and no shame for obedience. The Admiralty never reacts either way. In beat 3 the two choices (speak of duty, read the names) are both good writing with arbitrary rewards attached (why does duty give experience and names give repairs?).

**Biggest improvement.** Let the Admiralty and the column remember. Beat 2 rewrite:

- *Disobey and break them out.* The escort's lieutenant forms on your flagship: a Hegemony picket joins the fleet. Noted at the Admiralty: no bonus this sector, and the clock moves on one. (flag `hg_broke`)
- *Proceed to the objective.* Admiralty bonus: +80 credits. The column's last signal is logged. (flag `hg_left`)
- Blue, needs the black box: *Strike where he is weak.* The column lives, a weakness revealed, and the lieutenant joins you.

Then beat 3 reads the flag. If `hg_left`: "The list from the listening post has eleven new names on it. Your flag captain has already added them, in the correct format." The option *Read the names* then means something different in that run, and the player will feel it without being told. If `hg_broke`: "Authorisation arrives with a second sheet attached: a reprimand, unsigned. The lieutenant's picket is holding station off your bow and has not asked for orders."

Also swap the beat 3 rewards so they fit: *Read the names* gives experience (the crews fight harder for the dead), *Speak of duty* gives repairs (the crews go back to work).

### 3. Ashfall Corsairs: "Saints' Gold"

**What works.** Funniest and most human arc. "Nobody believes him and everybody is going." "Which makes you either clever or dead." "Nobody has ever called the bosun honest before, and he looks uneasy about it." "Counting shares out loud already, which is bad luck." Old Mott is a real character and ties to the admiral roster. The win line ("Mott's grandmother was right about the crowns and wrong about the saints. Nobody minds. The split takes three days and two fistfights") is the best win in the set. The loss line, your hull joining the treasure fleet in the ice, is a gift for cross-run memory (see Part 2).

**What falls flat.** The gift box holds a severed tattooed hand; the Voidsworn arc opens with a severed iron hand on an altar. Two hands in six beats. Beat 2's auction is a good set-piece but all three options reveal a weakness, so the choice is only about the price, and the ambush penalty on stealing is the only teeth in the arc. Beat 3's "Promise nothing, and mean it: +60 credits held back for repairs" is dead money if credits do not matter after the last fight (check this; if they do not carry to the Career screen, this option is a trap dressed as thrift).

**Biggest improvement.** Make the auction about what you walk out with, not three flavours of the same prize:

- *Steal it and burn the docks.* The box is yours and so is whatever was on the clamps: gain a relic. Your next fight starts as an ambush.
- *Outbid him (80 credits).* He loses face in front of every crew in the hold: the clock goes back one, and a weakness is revealed.
- Blue, needs the rigged box: *Remind him what was in the last box.* He flinches. The auctioneer, sensing a change in ownership, knocks it down to you for 30 credits: a weakness revealed, and the dens remember who made him flinch (+20 credits).

And replace the gift-box hand with something that is not a hand: the last fence's docking chit with a hole burned through it, or his ship's name-plate with the Corsair's own added underneath.

### 4. The Chorus: "Eat the Sun"

**What works.** The identity choice in beat 1 (eat the dead, or carry the silence so the hunger remembers whom to hate) is the most faction-true choice in the document. "The oldest throats argue in a sound like grinding teeth." "The hunger has never had to choose before." "There is only forward. There has only ever been forward." Teaching the spawn so a drone joins is exactly the kind of consequence the rest of the arcs lack. The loss line ("waiting for the next mouth") is good.

**What falls flat.** The header promises "short lines" and the cards do not deliver them; the Chorus sentences are the same length and rhythm as everyone else's. More seriously, the Chorus is written as a singing faction: "something old is singing," "its song carved out," "teach the spawn the song," "sing back to the sun." The Ithar arc is also about song (songships, the Glass Choir, laments, the archive that answers singing), and the Voidsworn arc has a hymn-ship and a choir. Three of six factions sing. The data.js flavour for the Chorus is hunger, hunting eyes, venom, predator instinct, and nothing about music; the name "Chorus" is the only musical thing about them. Beat 2's "a world that sang once" is an Ithar beat with the names changed.

**Biggest improvement.** Give the Chorus its own senses: scent, taste, heat, teeth. Keep the "many as one" idea, drop the song. Example rewrite of beat 1 in actually short lines (about 95 words):

"The Chorus wakes hungry. Every throat, one want. Three sectors out, the Hollow Sun: a dead star with something warm at the core. Old meat. The first meat. Eat it, or forget how to be many. On the first night the swarm finds a brood-node split open. The young inside untouched. Uneaten. Left to spoil. Nothing hunts like that. Something left it for the swarm to find. {rival}. The smell of him is in the wound. The swarm can eat the dead and grow. Or it can leave the dead and keep the smell, so the hunger knows what to chase."

Then "Teach the spawn the song" becomes "Feed the spawn from the swarm's own flesh" (every ship loses 5% hull, a drone joins), which is a real cost for a real gain. And "Sing back to the sun" becomes "Taste the air he came through."

### 5. The Ithar: "The Grave of Houses"

**What works.** The grief voice is held throughout and the time scale is used well: captains "barely four centuries" weeping at their stations. "He breaks them slowly, one by one, so you can hear it" is the most personal thing the rival does in any arc. "As if peeling fruit." Beat 1's choice (take the buoy's song and end it, or let it sleep) is a real mercy-versus-advantage dilemma and the best beat 1 in the set. The win line (the youngest captain learning a nine-thousand-year-old song "and sings it badly, and the elders weep") is the most moving line in the document.

**What falls flat.** "Before the younger races break it open" is the most recognisable Warhammer Eldar phrase in the document and should go. "When the Ithar die now, nothing is born to replace them" is the same borrowed idea in plainer words; it can stay if the phrasing is the Ithar's own. The beat 3 choices are the generic pair again. The arc's only cost is 5% damage in beat 2; nothing the Ithar choose ever loses them anything that matters to a dying people.

**Biggest improvement.** The Ithar should pay in the currency the arc keeps saying is precious: ships that cannot be replaced. Beat 3 rewrite:

- *Raise the sails.* Every captain gains 20 experience.
- *Send the oldest ship ahead to sing to the archive.* Your most damaged ship takes 20% hull damage drawing his lances. The archive answers: a weakness revealed and every other ship repairs 15%.

And replace "the younger races" with something the Ithar would say: "before the short-lived break it open for scrap."

### 6. The Deathless Dynasty: "The Court Restored"

**What works.** Contempt is a good spine and the arc holds it: "as if he has any right to stand there," "the squatters must be corrected," "You have waited ten thousand years. You can wait a few more minutes for the guns to charge." The warden's head left facing the door is the second-best calling card after the listening post. Beat 2's law dilemma (wake the reserve and break a law older than most stars, or keep the law and go in short) is a real choice with a felt consequence (a ship joins). The win line's court taking its seats "one by one, in perfect silence" is right.

**What falls flat.** "The overseers have calculated the insult to eleven decimal places" is the Hegemony's joke (the nine-page appendix) told again by a different faction. Both are "cold bureaucracy as comedy," and the Hegemony got there first and better. "Keep the law" rewarding 20 experience is a strange reward for restraint and makes the law feel like nothing. "Tomb-world," "dynasty," "wake in ranks," and "the crown" are the parts of the Deathless that read most like a direct lift (see Part 2). The "Be patient" path is strictly dominant (credits now, then the crown's flaw later, clock back).

**Biggest improvement.** Make keeping the law pay off late, where the player feels it. Beat 2: *Keep the law.* Nothing now. The court will know. (flag `dd_lawful`). Beat 3: the option *Wake the court's honour guard* becomes a blue option that needs `dd_lawful`: "The court does not wake for a fleet that broke its law." That turns restraint into the arc's best reward and turns waking the reserve into a true trade: a jackal now, no honour guard later. Also lean the voice away from ledgers and toward time and law: replace "eleven decimal places" with something like "The overseers have ruled on the insult. The ruling is forty pages long and every page says the same word."

---

## Part 2. Cross-cutting

### Are the choices real dilemmas with felt consequences?

Mostly no. Four problems stack up.

**The template is visible by the second run.** Every arc is: beat 1 = risky option (intel or relic, clock +1) versus safe option (credits or experience) and a flag; beat 2 = two options plus a blue that needs the beat 1 risky flag and gives both rewards; beat 3 = 20 experience versus 20% repairs. Six arcs, one skeleton. Once a player sees it, the arcs stop being stories and become a rewards menu.

**Blue options are strictly dominant, so beat 1 has a right answer.** In five of six arcs the flagged path in beat 1 unlocks a beat 2 option that is better than both non-blue options combined (Voidsworn: weakness and 15 xp; Hegemony: column lives, weakness, repairs; Chorus: weakness and clock back; Ithar: weakness and no damage; Deathless: weakness and clock back). The research point from Slay the Spire 2 applies: an option that is free and best is not a choice. Give every blue a price (spend the relic, lose a ship's hull, break a law that locks something later), or give the other beat 1 path its own blue in beat 2 so both roads have a payoff.

**"A weakness is revealed" is handed out like confetti and is worth nothing after the second one.** data.js rolls exactly two Nemesis weaknesses per run. The arcs offer a weakness reveal in Voidsworn beat 2 (all three options), Hegemony beats 1 and 2, Corsair beat 2 (all three options), Chorus beats 1, 2 and 3, Ithar beats 1, 2 and 3, Deathless beat 2. Ordinary events (beacon, deserters, informant, defector, and more) also hand them out. By beat 3 most fleets already know both weaknesses, so the arcs' main currency is often dead. Replace most of the story reveals with things the player can feel: a ship joining (used only twice, and it is the most story-felt reward on the allowed list), a relic, the clock going back, or his next fight starting with him at a disadvantage.

**Beat 3 is not a choice in any arc.** Experience versus repairs, right before the last fight, with no story difference. Experience 30 seconds before the final battle is worth very little, and credits at that point (Corsair) may be worth nothing. Two fixes, either works:
- Make beat 3 the place the run cashes in. Nothing carries past the Hollow Sun, so the natural last choice is "who gets the money": *Spend every credit on the pilgrims' blessing: every ship repairs 10% per 50 credits spent.* Versus *Hold the credits for the Chronicle* if credits count for anything on the Career screen. That is a real decision and it is in-theme for all six factions (tithe, requisition, shares, feeding, offering, census).
- Or lock and unlock beat 3 options by beat 1 and 2 flags (examples in Part 1), so the last card is where earlier choices come due.

**Consequences never arrive in story form.** Flags are read only to show a blue option in beat 2. Beat 3 never reads beat 1 or 2, and the win and loss lines are fixed. The Telltale lesson is that consequence should show up later in reactions, not just in the thing you chose. Cheapest fix: one bracketed line per flag in beat 3 (six arcs, two flags each, twelve short lines) and one variant win line per arc keyed to the biggest choice.

**No outcome text after choosing.** The option label shows the numbers (good: the player can predict), but nothing is said after the click. FTL and Slay the Spire both give a sentence of result. One line per option (about 36 lines total) would make the choices feel like they happened. Example for Voidsworn "Sell it to the pilgrims": "The pilgrims pay in coin that smells of incense. The keepers do not look at you again."

### Is each faction's voice distinct?

Four of six are distinct and held. Hegemony (ledger and silence), Corsair (gallows humour and shares), Ithar (grief and long time), Voidsworn (litany and confession) all read as themselves. Two problems:

- **The Chorus sounds like the Ithar.** Both arcs are about song, both have a world or a choir that once sang, both end with singing to the star. See Part 1.4: give the Chorus smell, taste and teeth and keep song for the Ithar.
- **The Deathless sounds like the Hegemony.** Both lean on cold bureaucratic precision as the joke (appendix of nine pages, insult to eleven decimal places, the census, the report). The Hegemony owns that register and does it better. The Deathless have a stronger idea in the draft that is under-used: law and the court. A civilisation that is a legal ruling with guns. Lean there.
- **All six beat 1 openings are the same sentence.** "The [faction] [does its thing]. Three sectors [of something] lie between you and the Hollow Sun, a dead star where [faction's history]." The sector intro already exists; move the Hollow Sun exposition there and let each beat 1 open on the rival's deed.

### Does the rival feel personal, and does he remember the player?

**He is the same person in every arc.** Each beat 1 opens with the rival leaving a theatrical cruelty as a calling card: keepers nailed to doors, a crew arranged to spell his name, a severed hand in a gift box, a brood-node cut open and left, buoys fed on and wrecks broken slowly, a warden's head facing the door. Each beat 2 has him set a trap and wait. Each beat 3 has him dug in at the Hollow Sun. That is one villain: a patient sadist who leaves messages. But the design says the rival can come from any of the five other factions, and the voice table at the end is six different people (a cold clerk, a cheerful thief, a hunger, a grieving elder, a count that is not finished). The arcs' deeds contradict the table. A Hegemony rival who nails keepers to doors is not the one who says "Stand down, or be removed from the record." The fix is a `{rival_deed}` slot in each beat 1, filled by his faction, six short lines written once and reused across all six arcs with one bridging sentence. Original examples:

- Voidsworn rival: "He burned the place clean and left one thing unburned, so you would know it was chosen."
- Hegemony rival: "He left a notice, numbered and countersigned, listing what he had taken and when he would be back for the rest."
- Corsair rival: "He took everything that was not bolted down, then came back for the bolts, and left a bill."
- Chorus rival: "What he left was eaten to the frame. What he did not eat was arranged in a ring, facing inward."
- Ithar rival: "He took nothing. He only stayed long enough for everything there to forget its own name."
- Deathless rival: "He catalogued the place before he emptied it. The catalogue was left on the door, with your name on the last page."

**He never remembers anything you did.** The one hail line per rival faction is fixed, and it does not read the flags. This is the Destructoid complaint about the Nemesis system in one sentence: random name and random weaknesses without the villain feeling personal. The memory half is cheap here because the flags already exist. Two or three hail variants per rival faction keyed to the most visible flag would do it. Examples (original):

- Corsair rival, if the player sold the saint's hand: "Heard you sold the hand. Good instinct. Bad timing."
- Hegemony rival, if the player left the column: "You let the haulers die for a bonus. I read the report. I would have done the same. That is why neither of us should be here."
- Deathless rival, if the player broke the law to wake the reserve: "You opened a tomb that was not yours to open. The count has you down for it."
- Ithar rival, if the player took the buoy's song: "You ended a thing older than your fleet to learn my route. Then we are not so different, and I am sorry for you."

**His gender is wrong half the time.** Every arc says "he" and "his," and the sample names include Petra Lindqvist and Ilyra Glasswing. Either the generator only rolls men, or the text needs `{he}` `{him}` `{his}` tokens, or the prose avoids pronouns. This is a bug, not a note.

**He does not get stronger for beating you.** The Nemesis system's most-copied idea is promotion: the captain who kills you comes back harder and remembers it. Voidsworn's rule (beating him ends him; a new name every run) throws this away. One exception keeps the rule mostly intact: if the last run ended in a loss to {rival}, the next run's generator may roll the same name and faction with one of his weaknesses closed, and beat 1 gains a bracket: "[He has broken a fleet of yours before. He has not forgotten, and neither have the crews.]" The Chronicle already records the loss, so the data exists.

**The Hollow Sun means six things and the player only ever hears one.** Each faction has its own reason to want the dead star (a beacon, an anchorage, a treasure fleet, old meat, an archive, a court). This is the best world-building idea in the document and it goes unused in the run, because the rival never says why he is there. His beat 3 hail should carry his faction's reason. Then every pairing of player faction and rival faction is a small collision of meanings (a Corsair hears a Deathless rival call the treasure fleet "the court's tithe"), and the shared map pays off.

### Pacing and length for a card read mid-run

150 words three times a run is tolerable but at the long end. FTL events run 40 to 80 words; Hades lines run one to three sentences; the Darkest Dungeon narrator says one line at the moment the mechanic bites. The cards here are at the long end because beat 1 does four jobs. Recommended targets: beat 1 under 110 words with the mission moved into the sector intro; beat 2 up to 130 (it carries the dilemma); beat 3 up to 130 with the rival line counted. Chorus cards should be the shortest in the game, as the header promises.

Where the text appears matters more than how long it is. The loss line and the win line are read once at the end, when the player is either elated or done; those can be the longest and most written lines (they are, and they are the best lines). The beat 2 card is read as a new sector map appears; it should get to the choice fast.

One timing idea the research supports: a single rival line at the moment the clock fills (his fight is next). Darkest Dungeon's narrator is strongest at the turn of the tide; this is Voidsworn's turn of the tide and it currently has no words.

### Replay value across many runs: do the beats need variants?

Yes. A player who likes the Hegemony will read "Pacification Order 41" identically on run 2 and run 20. The research gives two cures and the design should use both:

1. **Variant text.** Rival deed by his faction (six lines, shared). Rival hail, last words and gloat: two or three per faction, keyed to flags. Beat 2 situations: a second scenario per faction over time (an easy win is the auction becoming a card game, the column becoming a hospital ship, and so on). The FTL floor of three or four flavour texts per repeated encounter is the right ambition for the beats that repeat most.
2. **Self-awareness across runs.** The loss lines are already hooks ("Some later crew will hear the legend and come looking." "Within a month a new commander receives it."). Pay them off. If the Chronicle holds a prior loss for this faction, beat 1 gets a bracketed line: Corsair, "The dens say the last captain who went for the gold is still out there, frozen to the prize. Nobody says it to your face." Hegemony, "Order 41 has a previous holder. Their name has been blacked out of your copy." Ithar, "The elders do not mention the last voyage. The youngest captains have been told not to ask." That is the Hades lesson (acknowledge the cycle) and it costs twelve lines.

The Chronicle itself should be generated from the flags, one sentence per choice, so it reads like a record of what that run did rather than a fixed win or loss line. That is the Madden commentary model de Plater cited, and it makes the Career screen the place where the player's stories live.

### Anything derivative of Warhammer 40k?

The setting under the outlines already leans hard on 40k (data.js: astropath, warp storm, auspex, cogitator, wraithbone, shuriken, phylactery, scarabs, a hungering bio-swarm, a dying elder race, a machine necropolis dynasty, a gothic crusade). The outlines mostly stay inside that line but a few places step over it, where a 40k reader will recognise the exact phrase or the exact concept rather than the flavour:

- Ithar: "the younger races" is the Eldar's own term for everyone else. Replace. "Nothing is born to replace them" is the Eldar's central tragedy; keep the feeling, reword it ("every ship in this fleet is a line of a song that ends with it" is already the better, original version; lead with that).
- Deathless: "tomb-world," "dynasty," "wake in orderly ranks, tomb by tomb," a stolen crown, an "Overlord Nekhet the Undying" in data.js. This is Necron word for word. The outlines' own good ideas (the census, the court, the law of reclamation, "corrected") are not Necron and are better. Push the Deathless toward law and court, away from tombs and dynasties: vaults instead of tombs, the Bench or the Court instead of the dynasty, a seal or a writ instead of a crown.
- Voidsworn: "heretic," "confessor," "litanists," "reliquary," "hymn-ship" and "cathedral" wrecks are Imperium-adjacent but shared with a lot of gothic SF; the risk is lower, and the arc has enough of its own ideas (the chalk names, the Rite of Last Light, the hand). Fine, but do not add more.
- Chorus: "brood," "spawn," "the hunger" plus the current singing are generic enough. Moving to scent and taste (Part 1.4) also moves it further from the Tyranid hive-mind's psychic song.
- Hegemony and Corsairs: clear. The Admiralty-and-appendix voice is Voidsworn's own.
- Rival title "Dynast" in the sample name is a Necron title. Use "Overseer," "Warden," "Reeve," or "Justiciar" for Deathless commanders.

The short version: every faction has one original idea that is stronger than its borrowed costume (chalk names; the appendix; the shares and the airlock toast; the hunger that has never had to choose; four-century-old captains weeping; the court and the census). Write toward those and the derivative smell fades by itself.

---

## Part 3. Top 10 changes, ranked

1. **Give beat 3 a real decision.** All six are experience versus repairs with no story. Either make beat 3 the cash-in (spend credits on repairs at a rate, since nothing carries past the Hollow Sun) or lock and unlock beat 3 options by beat 1 and 2 flags so the last card is where choices come due.
2. **Make the rival's deeds match his faction, and fix his pronouns.** A `{rival_deed}` slot in each beat 1 filled from six shared lines by his faction, so he is not the same sadist in every run. `{he}` `{his}` tokens or pronoun-free prose: the sample names are already half women.
3. **Let the rival remember what you did.** Two or three beat 3 hail variants per rival faction keyed to the run's biggest flag, and his hail should name his faction's reason for wanting the Hollow Sun. This is the whole difference between a random name and a nemesis.
4. **Stop blue options being free and strictly best.** Give each blue a price (spend the relic, lose hull, break a law that locks a later reward), or give the other beat 1 path its own blue in beat 2.
5. **Stop handing out weakness reveals.** The run has two weaknesses and ordinary events already reveal them. Swap most story reveals for ships joining (the most felt reward available), relics, clock back, or an ambush in your favour.
6. **Make consequences arrive later, in story.** One bracketed line per flag in beat 3 and one variant win or loss line per arc keyed to the biggest choice. The Hegemony column's names on the listening-post list is the model.
7. **De-song the Chorus and give it scent, taste and teeth.** Three factions currently sing. Song belongs to the Ithar. Also write the Chorus cards in genuinely short lines, as the header promises, and make "teach the spawn" cost flesh.
8. **Add one outcome sentence after every option.** About 36 lines. The click should produce words, not only numbers.
9. **Trim and vary beat 1.** Move the Hollow Sun exposition into the sector intro, open each beat 1 on the rival's deed, and retire the shared "three sectors lie between you and" sentence. Give the Deathless the law-and-court voice instead of the Hegemony's bureaucracy joke.
10. **Pay off the loss lines across runs, and scrub the direct 40k lifts.** A bracketed beat 1 line when the Chronicle holds a prior loss for this faction (twelve lines), optionally a returning rival after a loss. Replace "the younger races," the Necron tomb-and-dynasty vocabulary, and the sample title "Dynast."

Smaller notes, not ranked: two severed hands in six arcs (Voidsworn altar, Corsair gift box), change the Corsair one; check whether credits at beat 3 are worth anything before offering them; "Setekh the Patient" in a sample name collides with the admiral "Khepra the Patient"; swap the Hegemony beat 3 rewards so names give experience and duty gives repairs.

---

## Sources

- Mega Crit on Slay the Spire 2 events: https://www.pcgamesn.com/slay-the-spire-2/events-redesign
- Bourassa and Sigman on Darkest Dungeon: https://gamesbeat.com/darkest-dungeon-designers-really-arent-sadists-were-realists/3/
- Darkest Dungeon narrator analysis: https://techraptor.net/gaming/features/darkest-dungeon-narrator
- Kashyap, meaningful decisions in branching narratives: https://gamedeveloper.com/design/meaningful-decisions-in-branching-narratives
- sub-Q, making interactive fiction, branching choices: https://sub-q.com/making-interactive-fiction-branching-choices/
- Subset Games forum on FTL event text lists and variants: https://subsetgames.com/forum/viewtopic.php?p=94011
- Justin Ma and Matthew Davis on FTL events: https://www.engadget.com/2012-09-19-the-joystiq-indie-pitch-ftl-faster-than-light.html
- Kasavin on Hades narrative (ScreenHub): https://www.screenhub.com.au/news-article/features/digital/jini-maxwell/hades-greg-kasavin-breaks-down-supergiants-unique-approach-to-narrative-262459
- Kasavin on roguelike narrative (GDC podcast page): https://gdconf.com/news/roguelikes-and-narrative-design-hades-creative-director-greg-kasavin-gdc-podcast-ep-16
- Loops and arcs in Hades: https://itch.io/blog/774695/to-hell-and-back-again-a-look-at-loops-and-arcs-in-hades
- Into the Breach tells its story through its characters: https://kotaku.com/into-the-breach-tells-its-story-through-its-characters-1824159682
- Narrative design of Tactical Breach Wizards and Into the Breach: https://www.gamedeveloper.com/design/let-s-compare-and-contrast-the-narrative-design-of-tactical-breach-wizards-and-into-the-breach
- de Plater on the Nemesis system: https://gamesbeat.com/shadow-of-mordors-nemesis-system-draws-from-burnout-football-and-an-architecture-book/
- Shadow of Mordor (Nemesis mechanics and critical reception): https://en.wikipedia.org/wiki/Middle-earth:_Shadow_of_Mordor
- Shadow of War Nemesis, personal battles: https://www.pcworld.com/article/406012/middle-earth-shadow-of-wars-unqiue-nemesis-system-makes-battles-even-more-personal.html
- Core system analysis of Shadow of War: https://www.gamedeveloper.com/design/core-system-analysis-of-middle-earth-shadow-of-war
- Sins of a Solar Empire 2 lore: https://www.sinsofasolarempire2.com/lore
- Harebrained Schemes on Battletech's story and Houses: https://gamingbolt.com/battletech-interview-the-biggest-battletech-game-yet
- Battletech Flashpoint review: https://gamecritics.com/steven-brown/battletech-flashpoint-review/
- RPG Codex review of Rogue Trader: https://rpgcodex.net/content.php?id=12918
