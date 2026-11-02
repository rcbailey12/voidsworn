Sunward Crusade
Core decision: What Is Owed
Scene purpose: The crusade must price its bargain with Seren, the Last Flame: taking Seren fire deep into the flagship costs a quarter of its hull for one battle's power, while refusing leaves the fleet whole but ordinary against the siphon crews ahead.
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
Admiral Roderic Vex: "Vex walks the gun decks before the dawn watch and chalks one name, in silence, every time. The crews have stopped asking."
Oath-Captain Malek Draven: "Malek counts torpedoes the way other captains count debts. 'Every one of these is a name the other side will have to learn.'"
Commodore Sera Ashgrove: "Ashgrove launches her wings and says only, 'Bring them home or do not come back empty.' Her wings have never once come back empty."
High Admiral Oryn Thale: "Thale reads the Roll before the battle plot, every time. 'The arithmetic was done on us once. We do the remembering.'"
Flags
None.
Hegemony Navy
Core decision: The Unlogged Minute
Scene purpose: The fleet's one tradition the Registry never logs becomes a priced choice: speak the names of the dead off-record and lose formation sync for the opening volley, or stay linked, keep the bonus, and leave the crews unnamed.
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
Learning payoff: "Whether you spoke or stayed linked, the doctrine file gains an entry with no author. Couriers are already carrying it."
Admiral spotlights
First Admiral Ilsa Kassar: "Kassar runs the synchronized volley drill until the fleet fires as one instrument. 'Discipline is a form of mercy. It shortens the dying.'"
Commodore Dace Vorn: "Vorn marks interception courses on the plot in red, then deletes the ones that merely work. 'We take the ones that end it.'"
Fleet Marshal Corin Reyes: "Reyes launches the strike group and reads the loss projection aloud as they form up, so the wings hear the number they intend to embarrass."
Line Admiral Oskar Maren: "Maren walks the column before battle and checks every shield reading personally. 'The Registry counted these crews once. I count them every day.'"
Flags
None.
Ashfall Hullbreakers
Core decision: Rook
Scene purpose: Rook, the core the pack believes makes its holder unstoppable, sits inside the enemy flagship's prize hold, and the pack must choose between the core and the kill: boarding for Rook costs the flagship in the fight ahead, while sinking everything wins the hunt clean but loses the prize forever.
Node:
id:'arc_hb_rook', t:'Rook', fight:false,
o:[
{t:'Hunt the core: board for Rook', r:{dmgFlag:.15, core:1}, tx:'Boarding claws only, no broadsides into the prize hold. The flagship takes the hits that the hold cannot. If the pack wins this, Rook comes home in chains of welded plate.'},
{t:'Hunt the kill: sink it all', r:{xp:25}, tx:'No holding back for cargo. The pack fights clean and total, and Rook goes down with the flagship if it goes. Kills are trophies too. The biggest ones sink.'}
]
Text lines:
Howler: "The prize hold, Warlord. We can hear the core through the hull. It sounds like a heart that has never been afraid."
Warlord: "Everything with a heart can be afraid. Claws out."
Debrief: "The pack does not cheer. It counts. Kills first, then trophies, then the missing."
Learning payoff: "Whatever the pack takes from this fight, it carries home bolted to a hull where the next litter can see it from the dark."
Admiral spotlights
Warlord Grax Ironmaw: "Grax takes the flagship in teeth-first and laughs over open comms while the claws bite. The pack howls back. It is not joy. It is agreement."
Sable the Smiling Knife: "Sable comes in from behind the light, quiet for a Hullbreaker, smiling with every tooth. 'The rear plate is where strong ships keep their manners.'"
Old Mott: "Old Mott has outlived forty captains. The pack steps aside when Mott crosses the bay, the way crews step aside for weather."
Vesh the Collector: "Vesh walks the prize after the fight, touching plates, naming where each one will ride. 'Nothing strong is ever wasted. It is only waiting.'"
Flags
Story pack spotlight header reads "Warlord Grax Steelgrin." Shipped data.js display name is "Warlord Grax Ironmaw" (Oct 27 rename). Ironmaw used here per the owner ruling. Story pack line flagged for correction.
Sable spotlight uses "behind the light." Bible 1.3 assigns light, glass, and reflections to the Glasswrights only. In context this reads as a spatial descriptor (the bright direction, glare) rather than a Glasswright identity motif, but flagging for chair review.
The Chorus
Core decision: The Second Throat
Scene purpose: Crucible is in range, and the swarm must decide what the second throat is for: letting Memory speak gains the core's protocols but dulls Hunger's killing edge, while closing Memory makes the swarm faster and emptier forever.
Node:
id:'arc_ch_crucible', t:'The Second Throat', fight:false,
o:[
{t:'Let Memory speak to the core', r:{core:1, dmgPctDown:1}, tx:'Memory speaks to Crucible in the makers voices, and the core answers an old name. Protocols come like remembered food. But Hunger hesitates at the kill now, listening for a voice under the hunger. Hunger will hesitate in the fight.'},
{t:'Close the second throat', r:{dmgPctUp:1}, tx:'We close Memory for the fight. The swarm is one throat, one want, nothing wasted. We are faster and emptier. Something that knew our name is quiet, and the quiet is also a kind of food.'}
]
Text lines:
Memory: "We were made to kill the sun-thieves. We remember their faces. They had our faces."
Hunger: "Faces are meat. Throats are meat. Choose."
The swarm: "We choose what the next brood keeps."
Debrief: "Every throat in the swarm tastes the decision. The young taste it first."
Learning payoff: "The next generation is grown from this choice. Broods after this one will be born knowing whether the swarm feeds its memory or eats it."
Admiral spotlights
The Matriarch of Nine Throats: "The Matriarch opens all nine throats before the fight, tasting the dark in every direction at once. The swarm goes still. Prey is near."
Razormaw: "Razormaw goes first and comes back last, torn plate trailing between teeth. Hunger approves. Memory counts the missing and approves of nothing."
The Mending Throng: "The Mending Throng knits the swarm closed between volleys, patient as weather. 'We are not finished,' the Throng says, in many voices. 'We are never finished.'"
Voice of the Deep: "The Voice speaks from the deep under the fleet, where the makers voices pool. Every throat answers without deciding to. 'Deeper,' the Voice says. 'The warm thing is deeper.'"
Flags
Source Voice of the Deep spotlight reads "the cold under the fleet." Bible 1.3 assigns cold to the Sunward Crusade only. Changed to "the deep under the fleet" to clear the motif conflict.
Source Razormaw spotlight uses "its teeth" (pronoun). Source Mending Throng spotlight uses "it says" (pronoun). Source Voice of the Deep spotlight uses "answers it" (pronoun). Source Chorus option 1 result text uses "It will hesitate" (pronoun). All replaced with named nouns per the pronoun rule.
The Glasswrights
Core decision: The Killing Flaw
Scene purpose: The forge delivers a shard-field replay from a fleet that died on this exact approach three centuries ago, naming the killing flaw in the line. Correcting the approach costs the element of surprise; keeping the fast line means flying into a known death with open eyes.
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
Learning payoff: "If this fleet falls here, its shard-field will drift until the gatherers find it, and the forge will correct this in a fleet cast long after everyone who loved this one is ash. That is not comfort. It is continuity, which is the Glasswright word for it."
Admiral spotlights
Tamsa of the Clear Aperture: "Tamsa sends her starling wings out in a fan of light and reads the whole battle in their reflections. 'Forgive me,' she tells the enemy flagship, almost gently, a moment before the volley."
Saro of Long Focus: "Saro holds focus through three volleys without speaking. When Saro finally speaks it is one word, the range, and the lances are already away."
Vell of the Third Mirror: "Vell scatters the fleet's light until the enemy fire walks through reflections and finds nothing honest. 'We built the light,' Vell says. 'It remembers us.'"
Brin of the Fourth Lens: "Brin raises the prism ward and the fleet stands inside a held rainbow, fragile and exact. 'Light, stored kindly. Light, returned.'"
Flags
None.
Eclipse
Core decision: The Count of Years
Scene purpose: The last backup window before the fight must be spent on either the admiral's full restoration or the fleet's hull repairs, and the choice is final: a mind too long without a backup goes dark, and the fleet cannot have both.
Node:
id:'arc_ec_count', t:'The Count of Years', fight:false,
o:[
{t:'Spend the Archive window on the admiral', r:{xp:25}, tx:'The last full backup window before the fight goes to the admiral alone. If the admiral falls, the restoration will be whole. The rest of the fleet fights with gaps in its continuity and knows it.'},
{t:'Spend the window on the fleet', r:{repair:.25}, tx:'Every hull gets its restoration pass and the admiral goes into the fight with an old backup and a quiet expression. 'If I come back missing the last year,' the admiral says, 'tell me we won it. Tell me slowly.''}
]
Text lines:
Admiral: "I have worn nine bodies and outlived my sun by a thousand years. Permanence is very long, Captain. Let us spend some of it correctly."
Debrief: "The fleet shows the last image of Ardent once more. This time, several ships hold it a moment past the minute."
Learning payoff: "Win or dark, the Archive will know this fight in full. The next fleet out of the dark will fly with this one's lessons under its plates, and will not know the names of the minds that paid for them. It does not need the names. It has the corrections."
Admiral spotlights
Nadir Aurex, Ninth Frame: "Aurex speaks last in every council and first in every battle. 'We remember noon,' Aurex says, and the great ring of plates around the core turns, very slightly, toward the enemy."
Umbra Vessane, Third-Housed: "Vessane counts the enemy fleet aloud, hull by hull, in the voice of one reading a list of the long-known dead. In a sense, Vessane is."
Ostrel of the Long Copy: "Ostrel has been copied more times than any mind in the fleet and has lost the least. 'Continuity is a discipline,' Ostrel says. 'Grief is what happens when you skip it.'"
Seveth, Twice-Restored: "Seveth went dark once, for eleven minutes, and came back. Seveth does not discuss the eleven minutes. The fleet does not ask. Some restorations are private."
Flags
• Source Vessane spotlight uses "they once knew" (pronoun for an unnamed character). Replaced with "the long-known dead" per the pronoun rule.
• Source Vex spotlight (Crusade) uses "himself" and "whose" (pronouns). Corrected in the Crusade section above. Flagging here for completeness of pronoun-rule changes made across the pack.
