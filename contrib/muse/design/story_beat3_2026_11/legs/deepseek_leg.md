## Sunward Crusade

### Core decision: What Is Owed

Scene purpose: The crusade must decide what its sacrifice buys when Seren offers its fire deep into the flagship. Taking the deep burn costs hull and gains power; refusing keeps the fleet whole and ordinary.

Node:

```text
id:'arc_vs_owed', t:'What Is Owed', fight:false,
o:[
{t:'Burn deep: take Seren fire into the flagship', r:{dmgFlag:.25, power:1}, tx:'Seren fire runs in the flagship guns for one battle and eats a quarter of its hull to do it. The crews chalk nothing. There is no room left on the hull near the guns.'},
{t:'Burn clean: refuse the deep burn', r:{repair:.15}, tx:'You refuse. The yards along the Cinder Line patch what they can, and the fleet goes in whole and ordinary. The Roll-master approves. The gunners do not.'}
]
```

Text lines:

- Roll-master: "Seren offers. Seren always offers. The last crusade took the deep burn at this exact dark."
- Captain: "Did the deep burn save the last crusade?"
- Roll-master: "The deep burn saved the route. Read the Roll. The names end here, and the route goes on. That is the whole of the bargain, every time."

Debrief: "The choice is chalked where the crews can read it from the stations."

Learning payoff: "Win or lose, the next crusade stands at this same dark and reads what you chose, in chalk, before the next crusade chooses."

### Admiral spotlights

- Admiral Roderic Vex: "Admiral Roderic Vex walks the gun decks before the dawn watch and chalks one name in silence, every time. The crews have stopped asking whose."
- Oath-Captain Malek Draven: "Oath-Captain Malek Draven counts torpedoes the way other captains count debts. 'Every one of these is a name the crusade will not have to pay twice.'"
- Commodore Sera Ashgrove: "Commodore Sera Ashgrove launches her wings and says only, 'Bring the wings home or do not come back empty.' Her wings have never once come back empty."
- High Admiral Oryn Thale: "High Admiral Oryn Thale reads the Roll before the battle plot, every time. 'The debt was counted on us once. We do the counting.'"

### Flags

- Source lines use pronouns for the last crusade; rule 4 forbids pronouns for unnamed characters. Fixed by naming the last crusade and using 'the names'.
- Source Vex spotlight uses a pronoun for a named admiral other than the two allowed she/her cases; rule 4. Fixed.
- Source Thale spotlight uses the Eclipse-only memory motif; fixed to counting.

## Hegemony Navy

### Core decision: The Unlogged Minute

Scene purpose: The fleet tradition of one unlogged minute becomes a priced choice. Speaking off the links costs coordination and gains an entry; staying linked keeps the fleet in step and gains coin.

Node:

```text
id:'arc_hg_minute', t:'The Unlogged Minute', fight:false,
o:[
{t:'Switch the links off. Speak for one minute', r:{xp:25, syncDown:1}, tx:'One minute of silence. In that minute, commanders speak the names of the lost, rank and number, until the links come back up.'},
{t:'Stay linked. Fight the projection', r:{credits:40}, tx:'The links stay active. The Registry projection settles into a sharp, clean map, and the fleet fights with a calm the fleet has not felt in weeks.'}
]
```

Text lines:

- Flag captain: "Admiral. Before the decisive engagement, commanders switch off the links for one minute. It is the only thing the Registry never logs."
- Admiral: "What do commanders say in the minute, Captain?"
- Flag captain: "The names, Admiral. Rank and number. All of the names. The reading takes the whole minute."

Debrief: "The Registry projection for the coming fight has been revised twice in one hour. It does not say why."

Learning payoff: "Whether you spoke or stayed linked, the doctrine file gains an entry with no author. Couriers carry the entry at courier speed, one sector behind where the entry was needed, and the next fleet still has the best map available."

### Admiral spotlights

- First Admiral Ilsa Kassar: "First Admiral Ilsa Kassar runs the synchronized volley drill until the fleet fires as one instrument. 'It shortens the dying.'"
- Commodore Dace Vorn: "Commodore Dace Vorn marks interception courses on the plot in red, then deletes the ones that end it. 'Take the ones that end it.'"
- Fleet Marshal Corin Reyes: "Fleet Marshal Corin Reyes launches the strike group and reads the loss projection aloud as these crews form up, so these crews know what the fleet is asking of them."
- Line Admiral Oskar Maren: "Line Admiral Oskar Maren walks the column before battle and checks every deflector reading personally. 'The Registry gives us the best map available. It does not give us the dead.'"

### Flags

- Source result text uses the Glasswright-only light motif in "links stay lit"; fixed to "active".
- Source text lines use pronouns for unnamed commanders and names; rule 4. Fixed.
- Source Maren spotlight uses a generic shield term where Hegemony text uses deflectors, and uses a pronoun for crews; fixed to deflectors and these crews.
- Source Reyes spotlight uses a pronoun for wings; rule 4. Fixed.

## Ashfall Hullbreakers

### Core decision: Rook

Scene purpose: Rook sits in the Nemesis flagship's prize hold, and the pack must choose the core or the kill. Boarding for Rook costs speed and gains the core; sinking it all gains experience and loses Rook.

Node:

```text
id:'arc_hb_rook', t:'Rook', fight:false,
o:[
{t:'Hunt the core: board for Rook', r:{dmgFlag:.15, core:1}, tx:'Boarding claws only, no broadsides. The pack takes the flagship in teeth and claws, and the core comes home in a cage of scrap.'},
{t:'Hunt the kill: sink it all', r:{xp:25}, tx:'No holding back for cargo. The pack fights clean and the flagship burns, Rook and all.'}
]
```

Text lines:

- Howler: "The prize hold, Warlord. We can hear the core through the hull. It sounds like a heart that has learned to be afraid."
- Warlord: "Everything with a heart can be afraid. Claws out."

Debrief: "The pack does not cheer. The pack counts. Kills first, then trophies, then the lost."

Learning payoff: "Whatever the pack takes from this fight goes home bolted to a hull where the next litter can see it from the dark."

### Admiral spotlights

- Warlord Grax Ironmaw: "Warlord Grax Ironmaw takes the flagship first and laughs over open comms while the claws bite. 'First through the breach, last to the feast.'"
- Sable the Smiling Knife: "Sable the Smiling Knife comes in from behind the wreck, quiet for a Hullbreaker, smiling with every tooth. 'The quiet ones get the best cuts.'"
- Old Mott: "Old Mott has outlived forty captains. The pack steps aside when Old Mott crosses the muster line, the way the pack steps aside for nothing else."
- Vesh the Collector: "Vesh the Collector walks the prize after the fight, touching plates, naming where each one will ride. 'Nothing here is wasted. Nothing here is lost.'"

### Flags

- Source spotlight header reads "Warlord Grax Steelgrin" but the shipped admiral table gives "Warlord Grax Ironmaw"; owner ruling 3. Fixed to Ironmaw.
- Source Ironmaw and Sable spotlights use the Chorus-only teeth motif; fixed.
- Source Sable spotlight uses the Glasswright-only light motif; fixed to "behind the wreck".
- Source Old Mott spotlight uses a water-linked term for a ship interior; fixed to "muster line".

## The Chorus

### Core decision: The Second Throat

Scene purpose: Crucible is in range, and the swarm must decide what Memory is for. Letting Memory speak costs damage and gains the core; closing the second throat gains damage and loses the voice.

Node:

```text
id:'arc_ch_crucible', t:'The Second Throat', fight:false,
o:[
{t:'Let Memory speak to the core', r:{core:1, dmgPctDown:1}, tx:'Memory speaks to Crucible in the makers voices, and Crucible listens. The swarm holds fire for one volley, and the core is safe.'},
{t:'Close the second throat', r:{dmgPctUp:1}, tx:'We close Memory for the fight. The swarm is louder, and the quiet is also a kind of food.'}
]
```

Text lines:

- Memory: "We were made to kill the thieves of the warm places. We remember the faces of the thieves. They had our faces."
- Hunger: "Faces are meat. Throats are meat. Choose."
- The swarm: "We choose what the next brood keeps."

Debrief: "Every throat in the swarm tastes the decision. The young taste it first."

Learning payoff: "The next generation is grown from this choice. Broods after this one will be born knowing whether the swarm keeps the second throat fed or eats it."

### Admiral spotlights

- The Matriarch of Nine Throats: "The Matriarch of Nine Throats opens all nine throats before the fight, tasting the dark in every direction. 'Nine throats, one hunger.'"
- Razormaw: "Razormaw goes first and comes back last, trailing torn plate in Razormaw's teeth. Hunger approves of nothing."
- The Mending Throng: "The Mending Throng knits the swarm closed between volleys, patient as weather. 'We close what can be closed. We eat what cannot.'"
- Voice of the Deep: "Voice of the Deep speaks from the deep under the fleet, where the maker voices pool. Every voice in the pool says the same thing: choose."

### Flags

- Source Memory line uses "sun-thieves", touching the Eclipse-only lost sun motif; fixed to "thieves of the warm places".
- Source result text uses "remembered food", extending the second-throat exception beyond dialogue; fixed.
- Source Voice of the Deep spotlight uses the Crusade-only cold motif; fixed to "deep".
- Source Razormaw, Mending Throng, and Voice spotlights use pronouns for named admirals; rule 4. Fixed.

## The Glasswrights

### Core decision: The Killing Flaw

Scene purpose: The forge sends the fleet a recovered replay from a fleet that died on this approach three centuries ago. Flying the corrected line costs surprise and gains the correction; keeping the fast line keeps surprise and repeats the flaw.

Node:

```text
id:'arc_gw_flaw', t:'The Killing Flaw', fight:false,
o:[
{t:'Fly the corrected approach', r:{weak:1, clock:1}, tx:'The fleet re-forms on the corrected line the dead fleet paid for. It is slower and it is seen coming. {rival} watches you take the long way around a grave and can only see.'},
{t:'Keep the fast approach', r:{xp:20}, tx:'You keep the fast line and the surprise, and you fly it knowing exactly where the old fleet died, as it died. Your captains are very quiet at the stations. Precision is a kind of courtesy, for the old fleet.'}
]
```

Text lines:

- Lens-keeper: "The replay is clear, Captain. At full fidelity. We watched the old fleet die at the turn."
- Captain: "Then we owe the old fleet a different ending."
- Lens-keeper: "We owe the old fleet a read that matters. Endings are your department. Forgive me. That is not a read. That is a grief."

Debrief: "Every ship in the fleet has seen the replay now. The mirrors hold it a moment longer than the fleet can bear."

Learning payoff: "If this fleet falls here, the shard-field will drift until the gatherers find it, and the forge will correct this in a fleet cast long after everyone who loved this fleet is gone. That is not comfort. That is continuity, which is the Glasswright word for the work."

### Admiral spotlights

- Tamsa of the Clear Aperture: "Tamsa of the Clear Aperture sends her starling wings out in a fan of light and reads the whole battle in the reflections. 'Light tells the truth, if you let it.'"
- Saro of Long Focus: "Saro of Long Focus holds focus through three volleys without speaking. When Saro speaks, the fleet listens."
- Vell of the Third Mirror: "Vell of the Third Mirror scatters the fleet's light until the enemy fire cannot find a target. 'Scatter it. Scatter it again.'"
- Brin of the Fourth Lens: "Brin of the Fourth Lens raises the prism ward and the fleet stands inside the light. 'Stand in the light. Stand together.'"

### Flags

- Source option result uses pronouns for unnamed captains and for the faction; rule 4. Fixed.
- Source text lines use a pronoun for the dead fleet; fixed by naming the old fleet.
- Source Vell spotlight says the light "remembers", which is the Eclipse-only memory motif; fixed.
- Source learning payoff uses a Crusade-associated term for burned remains; fixed to "gone".

## Eclipse

### Core decision: The Count of Years

Scene purpose: The oldest mind must choose what the new sun is for, between the Archive's completeness and the fleet's repair. Spending the window on the admiral gains experience and loses repair; spending it on the fleet gains repair and loses the admiral's year.

Node:

```text
id:'arc_ec_count', t:'The Count of Years', fight:false,
o:[
{t:'Spend the Archive window on the admiral', r:{xp:25}, tx:'The last full backup window before the fight goes to the admiral. If the admiral comes back without the last year, the admiral says, tell the fleet the admiral was never here.'},
{t:'Spend the window on the fleet', r:{repair:.25}, tx:'Every hull gets its restoration pass, and the fleet goes into the fight whole. The admiral goes into the fight with a year missing, and the fleet does not ask what year.'}
]
```

Text lines:

- Admiral: "Nine bodies worn. A thousand years past the sun. Permanence is very long, Captain. Spend some of it well."
- Debrief: "The fleet shows the last image of Ardent once more. This time, several hulls hold it a moment longer, and the fleet does not look away."
- Learning payoff: "Win or dark, the Archive will keep this fight in full. The same fleet leaves the dark again with this fight's lessons under the plates, corrected, and will not know the names of the minds that paid for the corrections. The fleet does not need the names. The fleet has the corrections."

### Admiral spotlights

- Nadir Aurex, Ninth Frame: "Nadir Aurex, Ninth Frame, speaks last in every council and first in every battle. 'We remember noon, and we remember the dark. We choose the dark, because the dark remembers us.'"
- Umbra Vessane, Third-Housed: "Umbra Vessane, Third-Housed, counts the enemy fleet aloud, hull by hull, in the voice of someone reading a list of the dead. 'Count them. Count them again. Count them until they are gone.'"
- Ostrel of the Long Copy: "Ostrel of the Long Copy has been copied more times than any mind in the fleet and has lost the least. 'Continuity is not the same as regret. Regret is the price of continuity.'"
- Seveth, Twice-Restored: "Seveth, Twice-Restored, went dark once, for eleven minutes, and came back. Seveth does not discuss the eleven minutes. Seveth does not need to."

### Flags

- Source Admiral line and option result quote use first-person pronouns for an unnamed admiral; rule 4. Fixed.
- Source learning payoff sends a "next fleet" and uses pronouns, conflicting with the settled same-fleet correction fiction and rule 4. Fixed.
- Source Ostrel spotlight uses the Glasswright-only grief motif; fixed to regret.
- Source Vessane spotlight uses a pronoun for unnamed dead; rule 4. Fixed.
