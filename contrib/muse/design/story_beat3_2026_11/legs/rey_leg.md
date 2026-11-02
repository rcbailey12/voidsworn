## Sunward Crusade

### Core decision: What Is Owed

Scene purpose: At the sector 3 opening, Seren is in range and offering protocols, and the deep burn has a hull price. The fleet must choose whether the flagship burns deep for one battle or refuses and goes in whole and ordinary.

Node:
```
id:'arc_vs_owed', t:'What Is Owed', fight:false,
o:[
 {t:'Burn deep: take Seren fire into the flagship', r:{dmgFlag:.25, power:1}, tx:'Seren fire runs in the flagship guns for one battle and eats a quarter of its hull to do it. The crews chalk nothing. There is no room left on the hull near the guns.'},
 {t:'Burn clean: refuse the deep burn', r:{repair:.15}, tx:'You refuse. The yards along the Cinder Line patch what they can, and the fleet goes in whole and ordinary. The Roll-master approves. The gunners do not.'}
]
```

Text lines:
- Roll-master: "Seren offers. Seren always offers. The last crusade took the deep burn at this exact dark."
- Captain: "Did it save them?"
- Roll-master: "It saved the route. Read the Roll. Their names end here, and the route goes on. That is the whole of the bargain, every time."

Debrief: "The choice is chalked where the crews can read it from their stations."

Learning payoff: "Win or lose, the next crusade stands at this same dark and reads what you chose, in chalk, before it chooses."

### Admiral spotlights

- Admiral Roderic Vex: "Vex walks the gun decks before the dawn watch and chalks one name, in silence, every time. The crews have stopped asking whose."
- Oath-Captain Malek Draven: "Malek counts torpedoes the way other captains count debts. 'Every one of these is a name the other side will have to learn.'"
- Commodore Sera Ashgrove: "Ashgrove launches her wings and says only, 'Bring them home or do not come back empty.' Her wings have never once come back empty."
- High Admiral Oryn Thale: "Thale reads the Roll before the battle plot, every time. 'The arithmetic was done on us once. We do the remembering.'"

### Flags

- The source spotlight for Admiral Roderic Vex used a gendered pronoun for the named admiral. The pack spotlight rule allows gendered pronouns only for Commodore Sera Ashgrove and Tamsa of the Clear Aperture, so the line is revised to carry Vex by name with no gendered pronoun.

## Hegemony Navy

### Core decision: The Unlogged Minute

Scene purpose: At the sector 3 opening, the fleet reaches the one tradition the Registry never logs. The admiral must choose whether to switch the links off and speak the names unrecorded, at a formation cost, or stay linked and keep the formation intact.

Node:
```
id:'arc_hg_minute', t:'The Unlogged Minute', fight:false,
o:[
 {t:'Switch the links off. Speak for one minute', r:{xp:25, syncDown:1}, tx:'One minute of silence on the link, the first in the fleet record. The formation bonus will not answer at the first volley. What you say in the minute is not logged, not projected, and not repeatable. Every captain repeats it anyway.'},
 {t:'Stay linked. Fight the projection', r:{credits:40}, tx:'The links stay lit. The Registry pays a compliance credit and the formation holds its shape. The flag captain folds the paper list smaller and says nothing at all.'}
]
```

Text lines:
- Flag captain: "Admiral. Before the decisive engagement, commanders switch off their links for one minute. It is the only thing the Registry never logs."
- Admiral: "What do they say in the minute, Captain?"
- Flag captain: "The names, Admiral. Rank and number. All of them. It takes the whole minute."

Debrief: "The Registry projection for the coming fight has been revised twice in one hour. It does not say why."

Learning payoff: "Whether you spoke or stayed linked, the doctrine file gains an entry with no author. Couriers carry it at courier speed, and it reaches the next fleet late, one sector behind where it was needed, still the best map that fleet has."

### Admiral spotlights

- First Admiral Ilsa Kassar: "Kassar runs the synchronized volley drill until the fleet fires as one instrument. 'Discipline is a form of mercy. It shortens the dying.'"
- Commodore Dace Vorn: "Vorn marks interception courses on the plot in red, then deletes the ones that merely work. 'We take the ones that end it.'"
- Fleet Marshal Corin Reyes: "Reyes launches the strike group and reads the loss projection aloud as they form up, so the wings hear the number they intend to embarrass."
- Line Admiral Oskar Maren: "Maren walks the column before battle and checks every shield reading personally. 'The Registry counted these crews once. I count them every day.'"

### Flags

- The source learning line had couriers carrying the doctrine entry but did not state the courier speed lag. The settled Hegemony fiction and R62 require the lag with no exceptions, so the revised line states that the entry reaches the next fleet late, one sector behind where the entry was needed.

## Ashfall Hullbreakers

### Core decision: Rook

Scene purpose: At the sector 3 opening, Rook, the core the pack believes makes a holder unstoppable, sits in the prize hold of the enemy flagship. The pack must choose the core at a hull price or the clean kill, and let Rook go down with the enemy flagship.

Node:
```
id:'arc_hb_rook', t:'Rook', fight:false,
o:[
 {t:'Hunt the core: board for Rook', r:{dmgFlag:.15, core:1}, tx:'Boarding claws only, no broadsides into the prize hold. The flagship takes the hits that the hold cannot. If the pack wins this, Rook comes home in chains of welded plate.'},
 {t:'Hunt the kill: sink it all', r:{xp:25}, tx:'No holding back for cargo. The pack fights clean and total, and Rook goes down with the flagship if it goes. Kills are trophies too. The biggest ones sink.'}
]
```

Text lines:
- Howler: "The prize hold, Warlord. We can hear the core through the hull. It sounds like a heart that has never been afraid."
- Warlord: "Everything with a heart can be afraid. Claws out."

Debrief: "The pack does not cheer. It counts. Kills first, then trophies, then the missing."

Learning payoff: "What the pack killed, and what killed the pack, is carried in the open: trophies bolted to hulls, the story told flat in the dens, and the next litter raised on both."

### Admiral spotlights

- Warlord Grax Ironmaw: "Grax drives the flagship in head-on and laughs over open comms while the boarding claws bite. The pack howls back. It is not joy. It is agreement."
- Sable the Smiling Knife: "Sable comes in from the blind side, quiet for a Hullbreaker, with a closed smile. 'The rear plate is where strong ships keep their manners.'"
- Old Mott: "Old Mott has outlived forty captains. The pack steps aside when Mott crosses the bay, the way crews step aside for weather."
- Vesh the Collector: "Vesh walks the prize after the fight, touching plates, naming where each one will ride. 'Nothing strong is ever wasted. It is only waiting.'"

### Flags

- The story pack spotlight header names Warlord Grax Steelgrin. Owner ruling 3 and the admiral table give the shipped display name as Warlord Grax Ironmaw, so Ironmaw is used and the story pack line is flagged here as required.
- The source spotlights for Grax and Sable used the teeth motif. Motif ownership gives teeth to the Chorus only, so both lines are revised.
- The source spotlight for Sable placed Sable behind the light. Motif ownership gives light to the Glasswrights only, so the line is revised.
- The source learning line covered what the pack takes from a fight but not what killed the pack. The settled Hullbreaker fiction carries both in the open, and R62 requires the learning to land after a loss, so the revised line covers both.

## The Chorus

### Core decision: The Second Throat

Scene purpose: At the sector 3 opening, Crucible, the Hunger Below, is in range, and Memory can speak to the core. The swarm must choose whether Memory speaks and Hunger loses edge in the fight, or the second throat closes and the swarm fights stronger and smaller.

Node:
```
id:'arc_ch_crucible', t:'The Second Throat', fight:false,
o:[
 {t:'Let Memory speak to the core', r:{core:1, dmgPctDown:1}, tx:'Memory speaks to Crucible in the makers' voices, and the core answers an old name. Protocols come like remembered food. But Hunger hesitates at the kill now, listening for a voice under the hunger. It will hesitate in the fight.'},
 {t:'Close the second throat', r:{dmgPctUp:1}, tx:'We close Memory for the fight. The swarm is one throat, one want, nothing wasted. We are faster and emptier. Something that knew our name is quiet, and the quiet is also a kind of food.'}
]
```

Text lines:
- Memory: "We were made to kill the sun-thieves. We remember their faces. They had our faces."
- Hunger: "Faces are meat. Throats are meat. Choose."
- The swarm: "We choose what the next brood keeps."

Debrief: "Every throat in the swarm tastes the decision. The young taste it first."

Learning payoff: "The next generation is grown from this choice. Broods after this one will be born knowing whether the swarm feeds its memory or eats it."

### Admiral spotlights

- The Matriarch of Nine Throats: "The Matriarch opens all nine throats before the fight, tasting the dark in every direction at once. The swarm goes still. Prey is near."
- Razormaw: "Razormaw goes first and comes back last, trailing torn plate in its teeth. Hunger approves. Memory counts the missing and approves of nothing."
- The Mending Throng: "The Mending Throng knits the swarm closed between volleys, patient as weather. 'We are not finished,' it says, in many voices. 'We are never finished.'"
- Voice of the Deep: "The Voice speaks from the cold under the fleet, where the makers' voices pool. Every throat answers it without deciding to. 'Deeper,' it says. 'The warm thing is deeper.'"

### Flags

none

## The Glasswrights

### Core decision: The Killing Flaw

Scene purpose: At the sector 3 opening, the fleet receives the forge read of a recovered shard-field: a replay, at full fidelity, from a fleet that died on this exact approach three centuries ago, naming the killing flaw in the approach. The fleet must choose the corrected approach and lose surprise, or keep the fast approach and fly the flaw knowingly.

Node:
```
id:'arc_gw_flaw', t:'The Killing Flaw', fight:false,
o:[
 {t:'Fly the corrected approach', r:{weak:1, clock:1}, tx:'The fleet re-forms on the corrected line the dead fleet paid for. It is slower and it is seen coming. {rival} watches you take the long way around a grave only you can see.'},
 {t:'Keep the fast approach', r:{xp:20}, tx:'You keep the fast line and the surprise, and you fly it knowing exactly where the old fleet died on it. Your captains are very quiet at their stations. Precision is a kind of courtesy, for the Glasswrights. They pay it at speed.'}
]
```

Text lines:
- Lens-keeper: "The replay is clear, Captain. At full fidelity. We watched them die at the turn, in light, three hundred years late and exactly on time."
- Captain: "Then we owe them a different ending."
- Lens-keeper: "We owe them a read that matters. Endings are your department. Forgive me. That was almost a joke. Grief makes us imprecise."

Debrief: "Every ship in the fleet has seen the replay now. The mirrors hold it a moment longer than the light requires."

Learning payoff: "Win or fall, the glass has this battle at full fidelity, and the forge will read it. If this fleet falls here, its shard-field will drift until the uncrewed gatherer hulls find it, and the forge will correct this in a fleet cast long after everyone who loved this one is ash. That is not comfort. It is continuity, which is the Glasswright word for it."

### Admiral spotlights

- Tamsa of the Clear Aperture: "Tamsa sends her starling wings out in a fan of light and reads the whole battle in their reflections. 'Forgive me,' she tells the enemy flagship, almost gently, a moment before the volley."
- Saro of Long Focus: "Saro holds focus through three volleys without speaking. When Saro finally speaks it is one word, the range, and the lances are already away."
- Vell of the Third Mirror: "Vell scatters the fleet's light until the enemy fire walks through reflections and finds nothing honest. 'We built the light,' Vell says. 'It remembers us.'"
- Brin of the Fourth Lens: "Brin raises the prism ward and the fleet stands inside a held rainbow, fragile and exact. 'Light, stored kindly. Light, returned.'"

### Flags

- The source learning line was framed for a fallen fleet only. R62 requires learning lines to land just as fully after a win as after a loss, so the revised line opens with the win case and keeps the fallen fleet case in full.

## Eclipse

### Core decision: The Count of Years

Scene purpose: At the sector 3 opening, one full backup window remains before the fight. The admiral must spend the window on the admiral alone, so a restoration after a fall is whole, or spend the window on every hull and go into the fight with an old backup.

Node:
```
id:'arc_ec_count', t:'The Count of Years', fight:false,
o:[
 {t:'Spend the Archive window on the admiral', r:{xp:25}, tx:'The last full backup window before the fight goes to the admiral alone. If the admiral falls, the restoration will be whole. The rest of the fleet fights with gaps in its continuity and knows it.'},
 {t:'Spend the window on the fleet', r:{repair:.25}, tx:'Every hull gets its restoration pass and the admiral goes into the fight with an old backup and a quiet expression. 'If I come back missing the last year,' the admiral says, 'tell me we won it. Tell me slowly.'}
]
```

Text lines:
- Admiral: "I have worn nine bodies and outlived my sun by a thousand years. Permanence is very long, Captain. Let us spend some of it correctly."

Debrief: "The fleet shows the last image of Ardent once more. This time, several ships hold it a moment past the minute."

Learning payoff: "Win or dark, the Archive will know this fight in full. The same fleet goes out of the dark again, corrected, with this fight's lessons under its plates, and the next deployment begins already knowing them. The names of the minds that paid stay in the Archive. The corrections go with the fleet."

### Admiral spotlights

- Nadir Aurex, Ninth Frame: "Aurex speaks last in every council and first in every battle. 'We remember noon,' Aurex says, and the great ring of plates around the core turns, very slightly, toward the enemy."
- Umbra Vessane, Third-Housed: "Vessane counts the enemy fleet aloud, hull by hull, in the voice of someone reading a list of the dead they once knew. In a sense, Vessane is."
- Ostrel of the Long Copy: "Ostrel has been copied more times than any mind in the fleet and has lost the least. 'Continuity is a discipline,' Ostrel says. 'Grief is what happens when you skip it.'"
- Seveth, Twice-Restored: "Seveth went dark once, for eleven minutes, and came back. Seveth does not discuss the eleven minutes. The fleet does not ask. Some restorations are private."

### Flags

- The source learning line framed the corrected deployment as a new fleet. The settled Eclipse fiction says the Archive sends the same fleet out corrected, so the revised line uses that framing.
