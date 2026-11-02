Chair header (Rey): Argon leg for issue #28 (progression step 12, story beat 3 pieces), run Nov 2, 2026, Gemini "4 Argon" with Thinking level High; both gates passed (model picker button and prompt bar read "Argon High" before submitting, prompt bar still "Argon High" after sending). Filed as a record and screened hard per standing practice: nothing from this leg enters the deliverable unless the pack or the lore bible backs it. Model text follows verbatim.

---

Sunward Crusade
Core decision: What Is Owed

Scene purpose: The crusade must decide what price it will pay before engaging the siphon crews, choosing between taking Seren's protocols deep into the flagship at the cost of its hull or entering the fight whole but ordinary.

Node:
id:'arc_vs_owed', t:'What Is Owed', fight:false,
o:[
 {t:'Burn deep: take Seren fire into the flagship', r:{dmgFlag:.25, power:1}, tx:'Seren fire runs in the flagship guns for one battle and eats a quarter of its hull to do it. The crews chalk nothing. There is no room left on the hull near the guns.'},
 {t:'Burn clean: refuse the deep burn', r:{repair:.15}, tx:'You refuse. The yards along the Cinder Line patch what they can, and the fleet goes in whole and ordinary. The Roll-master approves. The gunners do not.'}
]

Text lines:

Roll-master: "Seren offers. Seren always offers. The last crusade took the deep burn at this exact dark."

Captain: "Did it save them?"

Roll-master: "It saved the route. Read the Roll. Their names end here, and the route goes on. That is the whole of the bargain, every time."

Debrief: "The choice is chalked where the crews can read it from their stations."

Learning payoff: "Win or lose, the next crusade stands at this same dark and reads what you chose, in chalk, before it chooses."

Admiral spotlights

Admiral Roderic Vex: "Vex walks the gun decks before the dawn watch and chalks one name by hand, in silence, every time. The crews have stopped asking whose."

Oath-Captain Malek Draven: "Malek counts torpedoes the way other captains count debts. 'Every one of these is a name the other side will have to learn.'"

Commodore Sera Ashgrove: "Ashgrove launches her wings and says only, 'Bring them home or do not come back empty.' Her wings have never once come back empty."

High Admiral Oryn Thale: "Thale reads the Roll before the battle plot, every time. 'The arithmetic was done on us once. We keep the Roll.'"

Flags

Admiral Roderic Vex spotlight: the source line uses the pronoun "himself" ("chalks one name himself"), breaking the lint list pronoun rule that spotlight lines name the admiral and allow only she/her for Commodore Sera Ashgrove and Tamsa of the Clear Aperture; replaced with "by hand".

High Admiral Oryn Thale spotlight: the source line ends with "We do the remembering", encroaching on the memory motif owned by Eclipse (bible 1.3, where memory belongs to Eclipse with the single Chorus exception); replaced with "We keep the Roll" to hold to Crusade motif ownership.

Context extract (Charge and Rivalry beat): the Crusade charge uses "light" ("what is stealing the light", whereas light belongs to the Glasswrights under bible 1.3) and the sector 2 rivalry beat uses "Registry" ("your Registry deleted them", whereas the Registry belongs to the Hegemony under bible 1.3).

Hegemony Navy
Core decision: The Unlogged Minute

Scene purpose: The unlogged one-minute address before the decisive engagement becomes a priced tactical choice: switching the links off to read the names of the lost costs the fleet its opening formation sync, while staying linked preserves the formation bonus at the cost of the crews' morale.

Node:
id:'arc_hg_minute', t:'The Unlogged Minute', fight:false,
o:[
 {t:'Switch the links off. Speak for one minute', r:{xp:25, syncDown:1}, tx:'One minute of silence on the link, the first in the fleet record. The formation bonus will not answer at the first volley. What you say in the minute is not logged, not projected, and not repeatable. Every captain repeats it anyway.'},
 {t:'Stay linked. Fight the projection', r:{credits:40}, tx:'The links stay lit. The Registry pays a compliance credit and the formation holds its shape. The flag captain folds the paper list smaller and says nothing at all.'}
]

Text lines:

Flag captain: "Admiral. Before the decisive engagement, commanders switch off their links for one minute. It is the only thing the Registry never logs."

Admiral: "What do they say in the minute, Captain?"

Flag captain: "The names, Admiral. Rank and number. All of them. It takes the whole minute."

Debrief: "The Registry projection for the coming fight has been revised twice in one hour. It does not say why."

Learning payoff: "Whether you spoke or stayed linked, win or lose, the doctrine file gains an entry with no author. Couriers are already carrying it: it will reach the next fleet one sector behind where it was needed, and it will still be the best projection on the link."

Admiral spotlights

First Admiral Ilsa Kassar: "Kassar runs the synchronized volley drill until the fleet fires as one instrument. 'Discipline is a form of mercy. It shortens the dying.'"

Commodore Dace Vorn: "Vorn marks interception courses on the plot in red, then deletes the ones that merely work. 'We take the ones that end it.'"

Fleet Marshal Corin Reyes: "Reyes launches the strike group and reads the loss projection aloud as the wings form up, so the squadrons hear the number the strike group intends to embarrass."

Line Admiral Oskar Maren: "Maren walks the column before battle and checks every deflector reading personally. 'The Registry counted these crews once. I count them every day.'"

Flags

Learning payoff line: the source line ("Whether you spoke or stayed linked, the doctrine file gains an entry with no author. Couriers are already carrying it.") omits the mandatory travel lag and win-or-lose framing required by R62 and the settled Hegemony learning fiction (doctrine travels at courier speed, reaching the next fleet late, one sector behind where it was needed, with no exceptions to the lag); expanded to state the courier lag and win-or-lose outcome explicitly.

Fleet Marshal Corin Reyes spotlight: replaced plural pronouns "they" in "as they form up, so the wings hear the number they intend to embarrass" with explicit nouns ("the wings", "the squadrons", "the strike group") to ensure strict compliance with the spotlight pronoun rule.

Line Admiral Oskar Maren spotlight: the source line uses "shield reading", whereas shared vocabulary (bible 1.2) specifies "deflectors (Hegemony)" for Hegemony shields; updated to "deflector reading".

Ashfall Hullbreakers
Core decision: Rook

Scene purpose: With the core Rook carried inside the opposing flagship's prize hold, the pack must choose between boarding with claws to take the core intact at the cost of flagship hull damage or fighting without restraint to destroy the flagship and everything inside it.

Node:
id:'arc_hb_rook', t:'Rook', fight:false,
o:[
 {t:'Hunt the core: board for Rook', r:{dmgFlag:.15, core:1}, tx:'Boarding claws only, no broadsides into the prize hold. The flagship takes the hits that the hold cannot. If the pack wins this, Rook comes home in chains of welded plate.'},
 {t:'Hunt the kill: break it all', r:{xp:25}, tx:'No holding back for cargo. The pack fights clean and total, and Rook breaks with the flagship if it breaks. Kills are trophies too. The biggest ones leave only scrap.'}
]

Text lines:

Howler: "The prize hold, Warlord. We can hear the core through the hull. It sounds like a heart that has never been afraid."

Warlord: "Everything with a heart can be afraid. Claws out."

Debrief: "The pack does not cheer. It counts. Kills first, then trophies, then the missing."

Learning payoff: "Win or lose, whatever the pack takes from this fight goes home bolted to a hull and told flat in the dens, where the next litter learns the trail from the dark."

Admiral spotlights

Warlord Grax Ironmaw: "Grax takes the flagship in claws-first and laughs over open comms while the grapples tear plate. The pack howls back. It is not joy. It is agreement."

Sable the Smiling Knife: "Sable comes in out of the dark, quiet for a Hullbreaker, with a blade-thin smile. 'The rear plate is where strong ships keep their manners.'"

Old Mott: "Old Mott has outlived forty captains. The pack steps aside when Mott crosses the bay, the way crews step aside for weather."

Vesh the Collector: "Vesh walks the prize after the fight, touching plates, naming where each one will ride. 'Nothing strong is ever wasted. It is only waiting.'"

Flags

Warlord Grax Ironmaw spotlight header: the source header reads "Warlord Grax Steelgrin", which conflicts with the shipped data.js display name "Warlord Grax Ironmaw" under Owner Ruling 3 and the Admiral table; updated to "Warlord Grax Ironmaw".

Node option 2 (arc_hb_rook): the source option label and result text use sea-ship metaphors ("Hunt the kill: sink it all", "goes down with the flagship", "The biggest ones sink"), violating the lint list rule "Space, not sea, for ships" and naval metaphor ban; replaced with Hullbreaker breaking/scrap idiom ("Hunt the kill: break it all", "breaks with the flagship if it breaks", "The biggest ones leave only scrap").

Warlord Grax Ironmaw and Sable the Smiling Knife spotlights: the source lines use "teeth-first", "while the claws bite", and "smiling with every tooth", violating motif ownership (bible 1.3, which assigns "teeth" and hungry bite imagery to the Chorus only); Sable's line also uses "from behind the light", violating Glasswright ownership of "light" (bible 1.3) and missing her dark motif ("Knife in the dark"); updated both lines to use Hullbreaker motifs.

Learning payoff line: sharpened the source line to explicitly cover both win and loss and include the dens/trail from the settled Hullbreaker learning fiction alongside trophies bolted to hulls (R62, R63, and settled learning fictions).

The Chorus
Core decision: The Second Throat

Scene purpose: With Crucible in range, the swarm must choose between letting Memory speak to the core in the makers' voices to claim its protocols at the cost of Hunger's hesitation in battle, or closing Memory to fight as a single hungry throat.

Node:
id:'arc_ch_crucible', t:'The Second Throat', fight:false,
o:[
 {t:'Let Memory speak to the core', r:{core:1, dmgPctDown:1}, tx:'Memory speaks to Crucible in the voices of our makers, and the core answers an old name. Protocols come like remembered food. But Hunger hesitates at the kill now, listening for a voice under the hunger. We will hesitate in the fight.'},
 {t:'Close the second throat', r:{dmgPctUp:1}, tx:'We close Memory for the fight. The swarm is one throat, one want, nothing wasted. We are faster and emptier. Something that knew our name is quiet, and the quiet is also a kind of food.'}
]

Text lines:

Memory: "We were made to kill the sun-thieves. We remember their faces. They had our faces."

Hunger: "Faces are meat. Throats are meat. Choose."

The swarm: "We choose what the next brood keeps."

Debrief: "Every throat in the swarm tastes the decision. The young taste it first."

Learning payoff: "Win or lose, the next generation is grown from this choice in its flesh. Broods after this one will be born knowing whether the swarm feeds its memory or eats it."

Admiral spotlights

The Matriarch of Nine Throats: "The Matriarch opens all nine throats before the fight, tasting the dark in every direction at once. The swarm goes still. Prey is near."

Razormaw: "Razormaw goes first and comes back last, trailing torn plate between hot teeth. Hunger approves. Memory counts the missing and approves of nothing."

The Mending Throng: "The Mending Throng knits the swarm closed between volleys, patient as weather. 'We are not finished,' the Throng says, in many voices. 'We are never finished.'"

Voice of the Deep: "The Voice speaks from the dark under the brood, where the voices of our makers pool. Every throat answers the Voice without deciding to. 'Deeper,' the Voice says. 'The warm thing is deeper.'"

Flags

Node option 1 (arc_ch_crucible) and Voice of the Deep spotlight: the source uses unpunctuated "makers voices" to avoid breaking single-quoted strings and omits the "we" register in o[0].tx ("It will hesitate in the fight"); rephrased to "the voices of our makers" and "We will hesitate in the fight" to maintain grammatical precision and the mandatory "we" register (bible 5.2).

Razormaw, The Mending Throng, and Voice of the Deep spotlights: the source lines use pronouns "its" and "it" for the admirals ("in its teeth", "'We are not finished,' it says", "Every throat answers it... 'Deeper,' it says"), violating the lint list rule that spotlight lines name the admiral and allow only she/her for Commodore Sera Ashgrove and Tamsa of the Clear Aperture; replaced pronouns with the admirals' names or direct nouns.

Voice of the Deep spotlight: the source line uses "from the cold under the fleet", whereas "cold" is a Sunward Crusade motif (bible 1.3) and Chorus text uses broods (bible 5.2); changed to "from the dark under the brood".

Learning payoff line: added "Win or lose" and "in its flesh" so the line speaks the settled Chorus learning fiction ("born already knowing in its flesh") and lands explicitly after both wins and losses (R62, R63).

Context extract (Nemesis introduction and Rivalry beat): the Chorus finale context uses fixed pronouns "It", "it", and "its" for the Nemesis instead of the required tokens {rival}, {He}, {his} (Owner Ruling 2 and lint list) and uses the word "lights" (Glasswright motif, bible 1.3).

The Glasswrights
Core decision: The Killing Flaw

Scene purpose: The forge transmits a full-fidelity optical replay recovered from a shard-field that died on this exact approach three centuries ago, forcing the fleet to choose between flying the slower corrected line in full view of {rival} or keeping the fast approach and its fatal flaw.

Node:
id:'arc_gw_flaw', t:'The Killing Flaw', fight:false,
o:[
 {t:'Fly the corrected approach', r:{weak:1, clock:1}, tx:'The fleet re-forms on the corrected line the dead fleet paid for. It is slower and it is seen coming. {rival} watches you take the long way around a grave only you can see.'},
 {t:'Keep the fast approach', r:{xp:20}, tx:'You keep the fast line and the surprise, and you fly it knowing exactly where the old fleet died on it. Your captains are very quiet at their stations. Precision is a kind of courtesy, for the Glasswrights. They pay it at speed.'}
]

Text lines:

Lens-keeper: "The replay is clear, Captain. At full fidelity. We watched them die at the turn, in light, three hundred years late and exactly on time."

Captain: "Then we owe them a different ending."

Lens-keeper: "We owe them a read that matters. Endings are your department. Forgive me. That was almost a joke. Grief makes us imprecise."

Debrief: "Every ship in the fleet has seen the replay now. The mirrors hold it a moment longer than the light requires."

Learning payoff: "Whether this fleet returns through the light or drifts as a shard-field until the gatherers find it, the forge will read the optical replay and recast the next fleet in the procession with the killing flaw corrected, long after everyone who loved this one is gone. That is not comfort. It is focus, which is the Glasswright word for it."

Admiral spotlights

Tamsa of the Clear Aperture: "Tamsa sends her starling wings out in a fan of light and reads the whole battle in their reflections. 'Forgive me,' she tells the enemy flagship, almost gently, a moment before the volley."

Saro of Long Focus: "Saro holds focus through three volleys without speaking. When Saro finally speaks it is one word, the range, and the lances are already away."

Vell of the Third Mirror: "Vell scatters the fleet's light until the enemy fire walks through reflections and finds nothing honest. 'We built the light,' Vell says. 'It holds our shape.'"

Brin of the Fourth Lens: "Brin raises the prism ward and the fleet stands inside a held rainbow, fragile and exact. 'Light, stored kindly. Light, returned.'"

Flags

Learning payoff line: the source line ("If this fleet falls here...") only addresses a lost run, omits the parallel procession / optical memory recasting for a returning fleet (settled Glasswright learning fiction and R62), and uses "ash" (a Sunward Crusade motif under bible 2.4); updated to cover both returning and falling fleets, name the parallel procession and optical replay, and replace "ash" and Eclipse's "continuity" with Glasswright vocabulary.

Vell of the Third Mirror spotlight: the source line ends with "'It remembers us.'", using the memory motif owned by Eclipse (bible 1.3); replaced with "'It holds our shape.'".

Eclipse
Core decision: The Count of Years

Scene purpose: Before the final engagement, the fleet must allocate its last Archive window, choosing between giving the full backup pass to the commanding admiral so that mind can be restored whole if lost, or spending the restoration pass across every hull in the fleet while the admiral fights on an older backup.

Node:
id:'arc_ec_count', t:'The Count of Years', fight:false,
o:[
 {t:'Spend the Archive window on the admiral', r:{xp:25}, tx:'The last full backup window before the fight goes to the admiral alone. If the admiral falls, the restoration will be whole. The rest of the fleet fights with gaps in its continuity and knows it.'},
 {t:'Spend the window on the fleet', r:{repair:.25}, tx:'Every hull gets its restoration pass and the admiral goes into the fight with an old backup and a quiet expression. "If I come back missing the last year," the admiral says, "tell me we won it. Tell me slowly."'}
]

Text lines:

Admiral: "I have worn nine bodies and outlived my sun by a thousand years. Permanence is very long, Captain. Let us spend some of it correctly."

Debrief: "The fleet shows the last image of Ardent once more. This time, several ships hold it a moment past the minute."

Learning payoff: "Win or dark, the Archive keeps this fight in full. Eclipse does not send a new fleet out of the dark: it sends this same one again, its minds restored from the Archive with every lesson and correction intact."

Admiral spotlights

Nadir Aurex, Ninth Frame: "Aurex speaks last in every council and first in every battle. 'We remember noon,' Aurex says, and the great ring of plates around the core turns, very slightly, toward the enemy."

Umbra Vessane, Third-Housed: "Vessane counts the enemy fleet aloud, hull by hull, in the voice of an archivist reading a list of known dead. In a sense, Vessane is."

Ostrel of the Long Copy: "Ostrel has been copied more times than any mind in the fleet and has lost the least. 'Continuity is a discipline,' Ostrel says. 'Regret is what happens when you skip it.'"

Seveth, Twice-Restored: "Seveth went dark once, for eleven minutes, and came back. Seveth does not discuss the eleven minutes. The fleet does not ask. Some restorations are private."

Flags

Node option 2 (arc_ec_count): the source tx string contains unescaped inner single quotes ('If I come back missing the last year,' the admiral says, 'tell me we won it. Tell me slowly.'}) and a missing closing delimiter, breaking the single-quoted node literal; changed inner dialogue marks to double quotes so the node parses cleanly.

Learning payoff line: the source line ("The next fleet out of the dark will fly with this one's lessons under its plates, and will not know the names of the minds that paid for them.") directly contradicts the settled Eclipse learning fiction in the pack ("every mind is backed up in the shared Archive with its lessons intact. Eclipse does not send a new crusade; it sends the same one, corrected"); rewritten to state that Eclipse sends the same fleet again, restored from the Archive with its lessons and corrections intact.

Umbra Vessane, Third-Housed spotlight: the source line uses "someone reading a list of the dead they once knew", which uses a pronoun ("they") for an unnamed character ("someone"), breaking the lint list pronoun rule ("none for unnamed characters"); replaced with "an archivist reading a list of known dead".

Ostrel of the Long Copy spotlight: the source line uses "Grief is what happens when you skip it", breaking motif ownership (bible 1.3: "Light, glass, reflections, grief, what was taken: Glasswrights only" and "the Glasswrights mourn, Eclipse regret"); replaced "Grief" with "Regret".

Context extract (Finale mechanic and Nemesis introduction): the finale mechanic description says "its crew's minds", violating bible 7.2 ("Eclipse text has minds, bodies and backups, not crews"), and the Nemesis introduction uses "light" ("plate over trapped light", whereas light belongs to the Glasswrights under bible 1.3).
