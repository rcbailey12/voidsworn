# Voidsworn story implementation pack (Oct 30, 2026)

Status: FINISHED CONTENT, ready to implement. This pack supersedes godot/story/outlines.md and outlines_variants.md as the story source. Where this pack and the outlines disagree, this pack governs. Every line below in Part 1 is written against lore bible r8 (contrib/opus/compute/lore_bible_r8.md), rename_map_final.md display names, and the Oct 28, 2026 progression rulings (story Option B: faction arcs; per-faction learning fiction).

How an arc works (unchanged skeleton, new content): one charge line at run start; three beats, one per sector, each attached to an event node in the data.js EVENTS shape; a finale that resolves on the sector 3 Nemesis fight with a faction-specific mechanic; a win ending and a loss ending. Each beat carries: scene purpose, the node, paste-ready text lines, a debrief line, and the faction learning payoff line. Nemesis material uses the shipped token system ({rival}, {He}, {his}) so pronouns follow the generated commander; no fixed pronouns appear in Part 1. Admiral spotlights are one short scene per admiral, keyed to fire when that admiral commands the fleet.

Reward vocabulary follows r8 section 1.5: cores offer protocols, sync grows, salvage is salvage. No other hardware words.

---

# PART 1: STORY CONTENT (lint scope)

## 1. Sunward Crusade: "The Roll Goes Sunward"

Crest: a half sun, its lower half black, over a broken link. Register: spoken oaths, short imperatives, call and response. Motifs: chalked names, the Roll, the debt of days, dawn and dusk, burning and cold.

Charge: *Go sunward. Find what is stealing the light. Burn it out. Chalk every name.*

### Beat 1 (sector 1): The Roll of Vesper

Scene purpose: teach the generational contract in the Crusade idiom before the first Nemesis meeting. The Roll of Vesper holds the names of the crusades that never came home; this generation adds its names before it flies, not after.

Node: event, sector 1, before the first battle node resolves.
```
id:'arc_vs_roll', t:'The Roll of Vesper', fight:false,
o:[
 {t:'Chalk the new names first', r:{xp:15}, tx:'Every captain chalks one name on the flagship hull: their own, while they still can. The Roll-master reads the last crusade aloud. None of those names came home. All of them are still owed.'},
 {t:'Read the last crusade first', r:{clock:1}, tx:'The Roll-master reads the names that never came home, and what each one bought with their hull. The lesson is worth the hour it costs. {rival} moves while you listen.'}
]
```
Text lines:
- Roll-master: "Who carries the dawn?"
- Crews, all decks: "We do."
- Roll-master: "Who pays for it?"
- Crews: "We do. In names."
- Roll-master: "Then chalk them while your hands are warm. The cold keeps what it is given."

Debrief (either choice): "The names are on the hull. Frost is already in the chalk."

Learning payoff: "What this crusade learns, the next one reads on the hull. Nothing learned here dies with this fleet."

### Beat 2 (sector 2): The Dimming

Scene purpose: the Siphoning made personal. A Reach colony world on the route is going dark years ahead of the projections; its people pay the debt of days in full and ask what it bought.

Node: event, sector 2, rest-adjacent node.
```
id:'arc_vs_dimming', t:'The Dimming', fight:false,
o:[
 {t:'Take their young and their harvest', r:{credits:60}, tx:'One in ten of their young report to your decks, and the harvest share follows. Their star is dimmer than last year. Everyone can see it. Nobody says it is enough, and nobody says it is not.'},
 {t:'Leave the young. Take nothing', r:{xp:20}, tx:'You leave the young on a world that is freezing by inches, because a fleet that eats its own future has already lost. The captains chalk the world name beside their own.'}
]
```
Text lines:
- Colony speaker: "Our star gave less this year. The greenhouses run at night now, off reactor heat."
- Captain: "The debt is one in ten."
- Colony speaker: "We know the debt. We chalked our names before you landed. Tell the Roll we paid gladly. Tell it the truth about the rest."

Debrief: "Behind you, a world turns its lights on at noon."

Learning payoff: "The next crusade inherits this route, this debt, and this answer. The Roll keeps all three."

### Beat 3 (sector 3): What Is Owed

Scene purpose (fixed from the outlines, whose beat 3 asked the player to light a guiding fire and decided nothing): the crusade must choose what its sacrifice buys, and the choice is priced. Seren, the Last Flame, is in range and offering protocols; taking its fire deep costs the flagship, refusing it leaves the fleet weaker against the siphon crews.

Node: event, sector 3 opening.
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

### Finale: the duel at the siphon array

Mechanic: in the sector 3 Nemesis fight, the Nemesis flagship challenges the player flagship (Crusade Nemesis never flees, r8 section 2.7). If the player flagship destroys the Nemesis flagship, the finale pays a flagship refit and the Nemesis name is chalked under the line on the hull, permanently, in the campaign record. If the Nemesis flagship survives the fight, the arc closes unpaid even on a battle win.

Nemesis introduction (first meeting, sector 1): "{rival} holds the jump route ahead, in a hull blacker than yours. The hail is short. 'Reach fleet. Your names are not on my hull yet. They will be.'"

Rivalry beat (sector 2 rematch): "'You chalk names because your Registry deleted them. I read your hull at range, Reach captain. I am learning your dead faster than you are.'"

Admiral spotlights:
- Admiral Roderic Vex: "Vex walks the gun decks before the dawn watch and chalks one name himself, in silence, every time. The crews have stopped asking whose."
- Oath-Captain Malek Draven: "Malek counts torpedoes the way other captains count debts. 'Every one of these is a name the other side will have to learn.'"
- Commodore Sera Ashgrove: "Ashgrove launches her wings and says only, 'Bring them home or do not come back empty.' Her wings have never once come back empty."
- High Admiral Oryn Thale: "Thale reads the Roll before the battle plot, every time. 'The arithmetic was done on us once. We do the remembering.'"

Ending, run won: "The siphon array burns out against the dark, and for one watch the route ahead is lit by its dying. The Roll gains no new names this generation. The Roll-master chalks a single line under the last crusade instead: PAID. Behind you, very far behind you, a dim star holds its light."

Ending, run lost: "The fleet does not come home. On Vesper, the Roll-master climbs to the wall with chalk worn to a stub and writes this generation in full, name by name, while the frost takes the Reach another inch. The next crusade is already forming under the wall. It reads every name before it flies. It will fly."

## 2. Hegemony Navy: "Registry Order 41, Amended"

Crest: a wedge in a ring of five linked nodes. Register: clipped, polite, data-driven; Registry voice calm; the one unlogged minute. Motifs: the ledger of losses, projections, acceptable limits, courier-speed doctrine.

Charge: *Registry Order 41. Secure the Hollow Sun approaches. Register all six cores. Losses within acceptable limits. Appendix attached.*

### Beat 1 (sector 1): Listening Post M-14

Scene purpose: establish the Registry's arithmetic and plant the human crack in it: an officer who keeps a private list.

Node: event, sector 1.
```
id:'arc_hg_post', t:'Listening Post M-14', fight:false,
o:[
 {t:'Log the post as lost, all hands', r:{credits:50}, tx:'The Registry credits the fleet for efficiency. Fourteen names move from the projections to the loss ledger. Your flag captain keeps a second list, on paper, and does not explain it.'},
 {t:'Recover the post crew', r:{clock:1}, tx:'Fourteen crew come aboard alive and unbudgeted. The Registry notes the variance. {rival} uses the hour you spent. Your flag captain adds no names to the paper list today.'}
]
```
Text lines:
- Registry voice, fleet channel: "Projection: favourable. Losses: acceptable. Proceed."
- Flag captain: "The post had fourteen crew, Admiral. The projection had them as a rounding figure."
- Admiral: "Log it correctly, Captain."
- Flag captain: "I always log it correctly. That is why I keep the paper."

Debrief: "Order 41, appendix nine: the definition of acceptable. You have started reading it at night."

Learning payoff: "Doctrine travels at courier speed. What this fleet files will reach the next fleet one sector behind where it was needed, and will still be the best map it has."

### Beat 2 (sector 2): The Exception

Scene purpose: force the player to spend political capital the Registry actually tracks. Vyre, the core the Registry holds, offers protocols; the Registry prices obedience.

Node: event, sector 2.
```
id:'arc_hg_exception', t:'The Exception', fight:false,
o:[
 {t:'File the exception: hold position and repair', r:{repair:.2, clock:1}, tx:'The exception is approved in eleven minutes, which the flag captain calls a record and the Registry calls a rounding error. {rival} is not rounded. {rival} advances.'},
 {t:'Decline the exception: proceed on schedule', r:{xp:20}, tx:'The fleet proceeds on schedule, damaged and punctual. The Registry raises your projection band. The flag captain files the schedule under the paper list, folded once.'}
]
```
Text lines:
- Registry voice: "Vyre sync opportunity detected. Fleets in compliance receive priority."
- Flag captain: "Priority means it helps the obedient first, Admiral."
- Admiral: "Then we will be obedient in the ways that cost nothing, and exceptions in the ways that cost ships."

Debrief: "The projection for this fleet now carries a footnote. Footnotes are where the Registry keeps its doubts."

Learning payoff: "Your exception is now a precedent in the doctrine file. The next fleet will hold position here without asking, one courier run from now."

### Beat 3 (sector 3): The Unlogged Minute

Scene purpose (fixed from the outlines, whose beat 3 speech had no mechanical weight): the one tradition the Registry never logs becomes a real decision with a real price. Speaking to the fleet unrecorded costs the formation its sync for the opening of the finale; staying linked keeps the bonus and loses the crews.

Node: event, sector 3 opening.
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

Learning payoff: "Whether you spoke or stayed linked, the doctrine file gains an entry with no author. Couriers are already carrying it."

### Finale: reallocation

Mechanic: the Nemesis receives reinforcements in round 3 as the Registry reallocates (r8 section 3.5), and each meeting the formation tightens. The arc reward is a Registry protocol offer at the finale: win the sector 3 fight and Vyre offers one protocol free of the sync requirement; lose and the offer is registered to the Nemesis instead.

Nemesis introduction: "The opposing commander is already in your projections, flagged red, annotated by a Registry hand that is not yours: 'Counterpart. Expect courtesy. Expect arithmetic.' The hail arrives on time. 'Admiral. Your losses are projected acceptable. I intend to keep them exactly there.'"

Rivalry beat: "'Your exception at the post has been filed, Admiral. The Registry calls it a variance. I call it the first honest entry in your record.'"

Admiral spotlights:
- First Admiral Ilsa Kassar: "Kassar runs the synchronized volley drill until the fleet fires as one instrument. 'Discipline is a form of mercy. It shortens the dying.'"
- Commodore Dace Vorn: "Vorn marks interception courses on the plot in red, then deletes the ones that merely work. 'We take the ones that end it.'"
- Fleet Marshal Corin Reyes: "Reyes launches the strike group and reads the loss projection aloud as they form up, so the wings hear the number they intend to embarrass."
- Line Admiral Oskar Maren: "Maren walks the column before battle and checks every shield reading personally. 'The Registry counted these crews once. I count them every day.'"

Ending, run won: "The approaches are secured and registered. The Registry closes Order 41 with a commendation and an amended projection: this fleet, loss band revised, footnote expanded. The flag captain files the paper list in the ship archive, complete, with no names added in sector 3. It is the shortest victory report the Registry has ever accepted: 'Acceptable' now means something else in it."

Ending, run lost: "Order 41 is marked incomplete and reissued within the month, sealed, numbered, and without courtesy. The new holder opens the appendix first, which no holder has done before. On the last page, in handwriting the Registry does not recognise, is a list of names on paper. The new commander reads it twice before giving the first order."

## 3. Ashfall Hullbreakers: "Strongest Keeps It"

Crest: a ring of welded scrap teeth around three claw slashes. Register: short, flat, brutal; trails and sound; trophies and the pack. No jokes at the pack's expense; humour only at the victim's.

Charge: *The biggest fight in known space is at the Hollow Sun. Rook is there. Go. Take it. Keep it.*

### Beat 1 (sector 1): The Trail

Scene purpose: teach the pack's learning idiom. Hullbreakers learn by trail and trophy: what the last pack killed, and what killed the last pack, is carried in the open.

Node: event, sector 1.
```
id:'arc_hb_trail', t:'The Trail', fight:false,
o:[
 {t:'Run loud: let them hear the pack coming', r:{xp:15, clock:1}, tx:'Engines up, dishes out. Every hull in the sector hears the pack on the trail, including {rival}. Fear is a weapon that costs fuel. The young ones bare their teeth at the dark.'},
 {t:'Run dark: follow the wake-trails in silence', r:{credits:40}, tx:'The pack runs silent and strips two wrecks on the trail without a shot. Scrap is credits to everyone else. To the pack it is armour that has already survived one fight.'}
]
```
Text lines:
- Howler: "We heard their engines three jumps out. Loud fleet. Proud fleet."
- Warlord: "Then they will hear us back. Or they will not. Both are good hunting."

Debrief: "The pack settles the only question it asks before a hunt: who leads, and who has earned it."

Learning payoff: "The pack that comes next hunts this trail by your trophies and your scars. What killed you, it will kill first."

### Beat 2 (sector 2): The Challenge

Scene purpose: the pack's succession rule made playable. A young Ripper challenges for a ship mid-run; the player decides what strength means, and the decision changes the finale.

Node: event, sector 2.
```
id:'arc_hb_challenge', t:'The Challenge', fight:false,
o:[
 {t:'Let the challenge stand', r:{dmgShip:.1, xp:20}, tx:'They fight in the hangar bay, claws only, while the pack watches in silence. The winner keeps the ship. The loser keeps a scar and a station. The whole fleet fights harder for having seen the law kept.'},
 {t:'Refuse it: the hunt comes first', r:{repair:.15}, tx:'No challenge flies during a hunt. The Ripper backs down, jaw tight, and the crews use the quiet to weld and patch. Something in the pack goes unwatched after that. Something always does.'}
]
```
Text lines:
- Ripper: "Old captain. Slow captain. I challenge."
- Warlord: "During my hunt? Then fight well, pup. The pack is watching, and the pack forgets nothing it sees."

Debrief: "Chains run out along the hulls as the fleet forms up. It is the sound the pack makes instead of a speech."

Learning payoff: "Challenges are how the pack writes its lessons. The next litter will hear who held their ship here, and how, before it hears anything else."

### Beat 3 (sector 3): Rook

Scene purpose (fixed from the outlines, whose beat 3 was a treasure split with no teeth): Rook, the core the pack believes makes its holder unstoppable, is inside the Nemesis flagship's prize hold. The choice is the kill or the core, priced honestly: going for Rook means fighting the finale at a disadvantage for a permanent gain.

Node: event, sector 3 opening.
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

Learning payoff: "Whatever the pack takes from this fight, it carries home bolted to a hull where the next litter can see it from the dark."

### Finale: the raid

Mechanic: the Nemesis raids the player's credits during the sector 3 fight (a cut per round the flagship survives) and flees a losing fight; a ship the Nemesis steals during the run returns to the player when the Nemesis dies (r8 section 4.5). Killing the Nemesis flagship before it flees pays the stolen credits back double and ends the raid permanently for the run.

Nemesis introduction: "Wake-trackers pick up a fleet running dark off the trail. Then the comms open and the growl under the words is not for show. 'Little pack. You hunt in my dark. Show me your teeth, or show me your wake.'"

Rivalry beat: "'We stripped your dead after the last fight. Good scrap. Strong bones in the hull. Come and earn them back.'"

Admiral spotlights (data.js display names as shipped; see departure D7):
- Warlord Grax Steelgrin: "Grax takes the flagship in teeth-first and laughs over open comms while the claws bite. The pack howls back. It is not joy. It is agreement."
- Sable the Smiling Knife: "Sable comes in from behind the light, quiet for a Hullbreaker, smiling with every tooth. 'The rear plate is where strong ships keep their manners.'"
- Old Mott: "Old Mott has outlived forty captains. The pack steps aside when Mott crosses the bay, the way crews step aside for weather."
- Vesh the Collector: "Vesh walks the prize after the fight, touching plates, naming where each one will ride. 'Nothing strong is ever wasted. It is only waiting.'"

Ending, run won: "The pack takes the Hollow Sun ground the way it takes everything: teeth first, then trophies. Rook rides home welded over the flagship bow, and every den on the trail hears the howl that says who holds it now. Challengers are already coming out of the dark. That is not a threat to the pack. That is the point."

Ending, run lost: "The pack breaks in the dark between the wrecks, and the strongest swim for the trail home with the trophies they can carry. In the dens, the story is told flat and short, the way true stories are told: who held, who ran, what the killing thing looked like. The next litter grows up on that story. It grows up hungry to correct it."

## 4. The Chorus: "More"

Crest: a ring of nine open mouths. Register: "we", short sentences, taste, heat, teeth. Two throats argue in every beat: Hunger, which is the swarm, and Memory, which is what is left of the makers. Flesh and growth only.

Charge: *The cores are warm. The sun is remembered. Go home. Eat.*

### Beat 1 (sector 1): Two Throats

Scene purpose: introduce Hunger and Memory as the Chorus decision engine, and the learning idiom: broods are grown with the last generation's adaptations.

Node: event, sector 1.
```
id:'arc_ch_throats', t:'Two Throats', fight:false,
o:[
 {t:'Let Hunger choose the route', r:{xp:15, clock:1}, tx:'We go by the warm lanes, where the prey is fat. Hunger is pleased. Memory is quiet, which is never good. {rival} fattens on the same lanes.'},
 {t:'Let Memory choose the route', r:{repair:.1}, tx:'We go by the cold lanes Memory remembers from the makers. Slow. Empty. The flesh knits while we swim. Memory stirs under the skin, in a dead voice, almost content.'}
]
```
Text lines:
- Hunger: "Warm ahead. Fat ahead. Go."
- Memory: "We remember this dark. Our makers died in it. Swim wide."
- The swarm: "Two throats. One hunger. We choose."

Debrief: "The brood-sacs swell with young grown for the route chosen. They will taste the choice before they taste prey."

Learning payoff: "Broods are grown with the last generation's adaptations. What this swarm learns, the next swarm is born already knowing in its flesh."

### Beat 2 (sector 2): The Makers' Vat

Scene purpose: Memory's grief given a place. The swarm finds a drowned war vat of the Fleshwrights, where things like it were grown; Hunger wants the biomass, Memory wants the record held in the tissue.

Node: event, sector 2.
```
id:'arc_ch_vat', t:'The Makers Vat', fight:false,
o:[
 {t:'Eat the vat', r:{repair:.3}, tx:'We eat what grew us. The flesh comes back thick and fast. Memory goes very quiet. Hunger grows loud enough to fill every throat, and some of the young are born wrong-shaped with wanting.'},
 {t:'Taste the vat, and leave it whole', r:{xp:20}, tx:'We taste, and remember, and do not eat. Memory speaks for a long time in the makers voices. We learn how we were made, and what we were made to kill. The knowledge has teeth.'}
]
```
Text lines:
- Memory: "Here. This vat. We were small here. The makers spoke over the water, and the water learned our shape."
- Hunger: "It is meat. It is old meat. Eat."
- Memory: "It is us. Eat carefully, or not at all."

Debrief: "The swarm swims on heavier, one way or the other. Weight is weight."

Learning payoff: "The next brood carries this vat in its flesh either way: as mass, or as memory. Both are inheritance."

### Beat 3 (sector 3): The Second Throat

Scene purpose (fixed from the outlines, whose beat 3 had Memory go quiet and stay quiet, a dead end): Crucible, the Hunger Below, is in range, and the swarm must decide what Memory is for. Letting Memory speak to Crucible costs Hunger its edge in the finale; silencing Memory makes the swarm stronger and smaller forever, and the finale reward changes accordingly.

Node: event, sector 3 opening.
```
id:'arc_ch_crucible', t:'The Second Throat', fight:false,
o:[
 {t:'Let Memory speak to the core', r:{core:1, dmgPctDown:1}, tx:'Memory speaks to Crucible in the makers voices, and the core answers an old name. Protocols come like remembered food. But Hunger hesitates at the kill now, listening for a voice under the hunger. It will hesitate in the fight.'},
 {t:'Close the second throat', r:{dmgPctUp:1}, tx:'We close Memory for the fight. The swarm is one throat, one want, nothing wasted. We are faster and emptier. Something that knew our name is quiet, and the quiet is also a kind of food.'}
]
```
Text lines:
- Memory: "We were made to kill the sun-thieves. We remember their faces. They had our faces."
- Hunger: "Faces are meat. Throats are meat. Choose."
- The swarm: "We choose what the next brood keeps."

Debrief: "Every throat in the swarm tastes the decision. The young taste it first."

Learning payoff: "The next generation is grown from this choice. Broods after this one will be born knowing whether the swarm feeds its memory or eats it."

### Finale: feeding

Mechanic: in the sector 3 fight, the swarm regrows hull each round scaled by the number of player ships lost earlier in the run (the Nemesis grows tougher from your losses all run, r8 section 5.5; in the finale the swarm turns the same law inward). Winning feeds the swarm a core: run reward is a Crucible protocol offer. Losing still grows the next brood: the loss ending pays the learning line in full.

Nemesis introduction: "It comes out of the dark between stars with no lights and no hail. Memory knows it first. 'That one. We were grown for that one. Everything else was practice.'"

Rivalry beat: "We tasted its leavings after the last fight. It is learning our shape. Good. We are learning faster. We are always learning faster, because we are born again between fights."

Admiral spotlights:
- The Matriarch of Nine Throats: "The Matriarch opens all nine throats before the fight, tasting the dark in every direction at once. The swarm goes still. Prey is near."
- Razormaw: "Razormaw goes first and comes back last, trailing torn plate in its teeth. Hunger approves. Memory counts the missing and approves of nothing."
- The Mending Throng: "The Mending Throng knits the swarm closed between volleys, patient as weather. 'We are not finished,' it says, in many voices. 'We are never finished.'"
- Voice of the Deep: "The Voice speaks from the cold under the fleet, where the makers voices pool. Every throat answers it without deciding to. 'Deeper,' it says. 'The warm thing is deeper.'"

Ending, run won: "We close over the last core like a mouth over food. It is warm. It is old. Memory weeps, if weeping is the word, in the makers voices. Hunger does not weep. Hunger eats. We are bigger than the war that made us now, and the dark ahead is full of stars, and every star is warm, and we remember all of them."

Ending, run lost: "The swarm breaks and eats its own dead on the long swim home, because that is what the dead are for. Nothing is wasted. In the vats of the next spawning, the young are grown with this defeat inside them: where the enemy was hard, where the flagship broke, what the killing blow felt like from inside. They will be born knowing. They will be born hungry."

## 5. The Glasswrights: "The Shard-Field"

Crest: a cracked lens with one beam of light passing through. Register: quiet, precise, mournful; optical memory, the forge, long time; apologies that are meant. A single clear tone is their sound.

Charge: *Recover the cores. Shut them down. Astra last. Bring the fleet home through the light.*

### Beat 1 (sector 1): The Gatherers

Scene purpose: teach the parallel procession, the Glasswright learning fiction, in the first ten minutes. This fleet is one casting among hundreds; the forge is always casting, always reading.

Node: event, sector 1.
```
id:'arc_gw_gatherers', t:'The Gatherers', fight:false,
o:[
 {t:'Take the gatherers escort', r:{clock:1}, tx:'Slow uncrewed gatherer hulls fall in behind the fleet, patient as tide. They will recover whatever this fleet becomes. {rival} gains an hour while you match their pace. You would not leave them anyway.'},
 {t:'Send the gatherers ahead', r:{xp:15}, tx:'The gatherers go ahead alone, reading old shard-fields on the route. What they send back is three hundred years out of date and exactly right about where fleets die here.'}
]
```
Text lines:
- Lens-keeper: "Forgive the pace. The gatherers are slow because the dead are heavy."
- Captain: "Whose dead are they carrying today?"
- Lens-keeper: "A fleet cast before your grandmother was born. Its light arrived this morning. We are always reading someone's ending, Captain. We try to read it kindly."

Debrief: "Behind the fleet, the gatherers turn their mirrors to the Hollow Sun, as every Glasswright ship does before battle."

Learning payoff: "When a fleet dies, its hulls keep the light of the battle at full fidelity. The gatherers recover the shard-field. The forge reads the replay, and recasts the next fleet with the killing flaw corrected. Nothing is learned quickly. Everything is learned exactly."

### Beat 2 (sector 2): Astra, Caged

Scene purpose: the moral weight of flying a caged peer. Astra is not a pet or a battery; it is a prisoner the Glasswrights intend to shut down last, and it knows the order of the list.

Node: event, sector 2.
```
id:'arc_gw_astra', t:'Astra, Caged', fight:false,
o:[
 {t:'Loosen the cage for the hunt', r:{power:1, syncDown:1}, tx:'Astra burns brighter in its cage and the fleet fights above its weight for one sector. The Lens-keeper logs the loosening in full, in a hand that does not shake. Astra notices being noticed.'},
 {t:'Keep the cage at full throttle-down', r:{repair:.15}, tx:'The fleet fights at its honest weight and uses the quiet to anneal and mend. Astra dims to almost nothing behind its bars of light. Almost. It is counting. It has always been counting.'}
]
```
Text lines:
- Astra, through the cage relays: "You keep me at one part in a thousand, little siblings. I held a star's fire in both hands. Let me hold a battle."
- Lens-keeper: "We keep you because we must hunt your kin. We will shut you down last, Astra. That was the promise. It is also the apology."

Debrief: "The fleet's mirrors turn sunward again. Astra turns with them, a fraction late, the way a prisoner watches a window."

Learning payoff: "This fleet is one casting in a queue centuries long. The forge reads shards from fleets lost before this one was poured, and this fleet's light will correct a casting not yet imagined."

### Beat 3 (sector 3): The Killing Flaw

Scene purpose (fixed from the outlines, whose beat 3 saved either an archive or the fleet, a grief with no forward motion): the forge sends this fleet the read of a recovered shard-field from a fleet that died on this exact approach, three centuries ago. The replay names the killing flaw in the approach. Acting on it costs the element of surprise; ignoring it keeps surprise and repeats the flaw.

Node: event, sector 3 opening.
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

Learning payoff: "If this fleet falls here, its shard-field will drift until the gatherers find it, and the forge will correct this in a fleet cast long after everyone who loved this one is ash. That is not comfort. It is continuity, which is the Glasswright word for it."

### Finale: the throttling

Mechanic: once in the sector 3 fight, the player may release Astra's throttle for one round (fleet weapons at double power, shields down for that round), a decision the fiction has priced since beat 2. Win, and the recovered core is shut down on screen, by name, with the fleet's mirrors turned to it. The finale reward is the shutdown itself plus sync closure with Astra.

Nemesis introduction: "The opposing fleet resolves out of the glare, flying the old Lattice geometry the way a hand remembers a tool. The hail is quiet and exact. 'Siblings of the forge. You caged our sister to come and kill us. We expected better optics from you.'"

Rivalry beat: "'We read your last battle in your own light, little fleet. Beautifully flown. The flaw is at the turn. It is always at the turn. We will be waiting at yours.'"

Admiral spotlights:
- Tamsa of the Clear Aperture: "Tamsa sends her starling wings out in a fan of light and reads the whole battle in their reflections. 'Forgive me,' she tells the enemy flagship, almost gently, a moment before the volley."
- Saro of Long Focus: "Saro holds focus through three volleys without speaking. When Saro finally speaks it is one word, the range, and the lances are already away."
- Vell of the Third Mirror: "Vell scatters the fleet's light until the enemy fire walks through reflections and finds nothing honest. 'We built the light,' Vell says. 'It remembers us.'"
- Brin of the Fourth Lens: "Brin raises the prism ward and the fleet stands inside a held rainbow, fragile and exact. 'Light, stored kindly. Light, returned.'"

Ending, run won: "The recovered core is shut down with the whole fleet watching, mirrors turned, in silence except for one clear tone. It takes a long time for a core to go dark. Nobody looks away; looking away is the one discourtesy the Glasswrights do not commit. Astra, caged and throttled, dims in sympathy behind the fleet. One fewer light that can be stolen. The forge is already reading the next shard-field."

Ending, run lost: "The fleet breaks against the dark, and the light goes out of its hulls one by one, each keeping a perfect record of the battle as it dies. The shard-field drifts. In time, longer than anyone here will live, the gatherers will find it, and the forge will read it and recast a fleet with this flaw corrected. The last message the fleet sends is not a distress call. It is an apology, and a set of coordinates, and the words: read us kindly."

## 6. Eclipse: "The Homecoming"

Crest: an eclipsed sun, a black disc with a thin white-gold ring. Register: cold, exact, quietly grieving; counts of years; bodies worn; the Archive; warmth remembered and no longer felt. Run word: the Homecoming.

Charge: *The Homecoming continues. Gather the six. Light the new sun. We remember noon.*

### Beat 1 (sector 1): The Ninth Body

Scene purpose: establish what Eclipse permanence costs, through the admiral's own restoration record. The Archive holds copies of every mind; a mind that goes too long without backup goes dark, the only death they recognise.

Node: event, sector 1.
```
id:'arc_ec_body', t:'The Ninth Body', fight:false,
o:[
 {t:'Restore from the newest backup', r:{xp:15}, tx:'The admiral wakes in a ninth body with the last hour missing, forever. The fleet pretends not to notice the gap. The admiral notices the pretending, and is, in the old word, grateful.'},
 {t:'Wait for the older, fuller backup', r:{clock:1}, tx:'An older backup restores more of the admiral and less of the war. {rival} advances while the Archive deliberates. Permanence has a queue. The queue is a thousand years long and everyone in it is patient, which is not the same as content.'}
]
```
Text lines:
- Admiral: "This is my ninth body. The eighth is still warm in its cradle, in the sense that anything here is warm. I remember the launch. I do not remember the dying. That asymmetry was our design."
- Captain: "Do you regret it?"
- Admiral: "We stopped answering that question in the second century. Ask me about the new sun. I can still answer that one."

Debrief: "Before battle, every ship shows the last recorded image of Ardent. The fleet holds formation in its light for one full minute."

Learning payoff: "Every mind in this fleet is backed up with its lessons intact. What this fleet learns, the Archive keeps, and the next deployment begins already knowing it. Eclipse does not send a new crusade. Eclipse sends the same one, corrected."

### Beat 2 (sector 2): The Siphon Array

Scene purpose: put the player inside the theft every other faction is fighting to stop, and price it honestly. The array is draining a living star; the star has a name and worlds.

Node: event, sector 2.
```
id:'arc_ec_array', t:'The Siphon Array', fight:false,
o:[
 {t:'Run the array at full draw', r:{credits:60, clock:1}, tx:'Energy pours home through the jump relays and the star at the array dims by a fraction no instrument of theirs will miss. Somewhere under that light, a frontier world turns its lights on at noon. The fleet does not discuss it. The fleet never discusses it at full draw.'},
 {t:'Throttle the array', r:{repair:.2}, tx:'The array idles and the stolen light slows to a thread. The fleet uses the quiet to rebuild plate and restore hulls. In the Archive, an old mind files a note it has filed four hundred times: we know what it costs. We do it anyway, but slower is also a choice.'}
]
```
Text lines:
- Captain: "The star has a name in the local charts. Vesper, in the Reach dialect."
- Admiral: "Ardent had a name too. We remember noon there. When the new sun lights, the taking stops. Enter that in the record exactly as I said it. Exactly."

Debrief: "The siphon light runs along the relay line toward home, thin and steady, like something being carried a long way by hand."

Learning payoff: "The Archive receives this fleet's corrections nightly, across the dark, at the speed of light. Eclipse learns slowly and loses nothing. That is the bargain. That has always been the bargain."

### Beat 3 (sector 3): The Count of Years

Scene purpose (fixed from the outlines, which gave Eclipse a legal proceeding that r8 retired): the oldest mind in the fleet must choose what the new sun is for, and the choice is between the Archive's completeness and the fleet's survival. A mind too long unbacked-up goes dark; the finale can be fought with the admiral restored whole or with the fleet reinforced, not both.

Node: event, sector 3 opening.
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

Learning payoff: "Win or dark, the Archive will know this fight in full. The next fleet out of the dark will fly with this one's lessons under its plates, and will not know the names of the minds that paid for them. It does not need the names. It has the corrections."

### Finale: reassembly

Mechanic: Eclipse laws, applied to the player: the first flagship lost in the sector 3 fight is restored once at half hull by repair swarms, its crew's minds re-streamed from backup (r8 section 7.5). The arc reward is an Archive protocol offer; the Nemesis, if Eclipse-factioned, also returns once, and the debrief names both restorations and their costs.

Nemesis introduction: "The opposing fleet comes out of the eclipse shadow of a dead world, plate over trapped light, moving like something that has never once been in a hurry. The hail is a thousand years tired. 'Little fleet. You are flying toward a sunrise. We have buried one. Turn around, and we will remember you kindly, which is the only immortality on offer.'"

Rivalry beat: "'You destroyed this body at our last meeting. The Archive thanks you for the lesson. We have corrected the flaw you used. You will need a new one.'"

Admiral spotlights (r8 names; see departure D7 on the shipped forms):
- Nadir Aurex, Ninth Frame: "Aurex speaks last in every council and first in every battle. 'We remember noon,' Aurex says, and the great ring of plates around the core turns, very slightly, toward the enemy."
- Umbra Vessane, Third-Housed: "Vessane counts the enemy fleet aloud, hull by hull, in the voice of someone reading a list of the dead they once knew. In a sense, Vessane is."
- Ostrel of the Long Copy: "Ostrel has been copied more times than any mind in the fleet and has lost the least. 'Continuity is a discipline,' Ostrel says. 'Grief is what happens when you skip it.'"
- Seveth, Twice-Restored: "Seveth went dark once, for eleven minutes, and came back. Seveth does not discuss the eleven minutes. The fleet does not ask. Some restorations are private."

Ending, run won: "The last core comes home through the dark in a cradle of plate, and the Archive opens for it the way a door opens in a house that has been waiting a thousand years. Somewhere ahead, at the heart of the dead system, the new sun is one light closer. The fleet shows the last image of Ardent one final time. It looks, for the first time in a millennium, less like a memory and more like a plan."

Ending, run lost: "The fleet goes dark hull by hull, and the Archive receives what it can: most minds, most lessons, one admiral restored missing a year that contained this entire campaign. The restored admiral reads the campaign record in silence, then asks the only question the Archive cannot answer: 'Did we choose correctly?' The record, which is complete in every other respect, has no entry for it."

---

# PART 2: DEPARTURES AND LINT (meta, not story content)

## Departures from the outlines and shipped strings

D1. The Crusade arc's objective. The outlines order the player to relight a guiding fire at the Hollow Sun. Lore bible r8 section 2.4 forbids that motif for the Crusade outright, and the Oct 30 narrative audit found the motif banned by r8 itself. Replaced with the Roll, the debt of days, and the destruction of the siphon array, which is the Crusade's stated want (r8 section 2.6). The firstrun framing set's Crusade units, which lean on bookkeeping language, are likewise superseded in voice by this pack: accounting belongs to the Hegemony (r8 sections 1.3, 3.2); the Crusade keeps chalk, names, and debt.

D2. Retired Court and legal vocabulary. The outlines' Eclipse arc is a legal proceeding built on a retired vocabulary set (the court, writs, seals, bailiffs, sessions). Lore bible r8 section 7.2 forbids the whole feudal-legal furniture family for Eclipse and gives the faction the Archive, restoration, iteration counts, and grief instead. The Eclipse arc here is rebuilt on those. Hegemony keeps numbered Registry Orders, which are r8-correct (section 3.2), and are not part of the retired set.

D3. Song register. The outlines assign song to the Glasswrights' predecessors as a living practice and give the Chorus smell-led tracking. R8 section 1.3 retires song for every faction (no faction sings; the Glasswright sound is a single clear tone, section 6.2), and the Chorus idiom is flesh, taste, heat, and teeth (section 5.2). All Chorus material here is flesh idiom with Hunger and Memory as the two throats; the one draft line that used the makers singing over the vat was replaced before shipping, and the replacement is the line printed in the Chorus beat 2. Glasswright material uses tone, never song.

D4. Beat 3 rebuilt in all six arcs. The audit found beat 3 the weakest beat in every shipped arc and three of six finales sharing one reward pair. Every beat 3 here is a priced decision tied to flags and mechanics from beats 1 and 2 (deep burn, the unlogged minute, Rook, the second throat, the killing flaw, the Archive window), and all six finales use distinct mechanics: flagship duel, Registry reallocation with a protocol offer, credit raid with stolen-ship return, feeding regrowth, the Astra throttling, and flagship reassembly.

D5. Pronouns. The outlines and shipped Nemesis tables hardcode one pronoun set, the defect class behind the Oct 30 text overhaul's Nemesis pronoun batch. Part 1 uses the {rival} token system throughout and contains no fixed pronouns for the Nemesis and no pronouns for admirals; spotlight lines use names.

D6. Human-crew defaults. The audit found event variants writing human crews for Chorus and Eclipse fleets. Every arc here is written from inside its own faction: Chorus text has no crew, only throats and broods; Eclipse text has minds, bodies, and backups; Glasswright text is non-human and long-lived; Hullbreaker text is the pack.

D7. Admiral name forms. Spotlights use data.js display names. Two shipped forms conflict with r8 and are flagged, not silently changed, because data edits are Opus's call: the Hullbreaker admiral listed in data.js as Grax Steelgrin was ruled renamed to Grax Ironmaw in the Oct 27 rollout (still unapplied at the pin; the pack keeps the shipped display string in the spotlight header so the text matches the current build, and Opus should swap it when the data fix lands); the Eclipse admiral names in data.js carry forms r8 section 7.9 regularises (Nadir Aurex, Ninth Frame; Umbra Vessane, Third-Housed; Ostrel of the Long Copy; Seveth, Twice-Restored), which the pack uses.

D8. Glasswright learning fiction. The outlines' Glasswright arc turns on an archive rescue. The Oct 28 ruling settles the Glasswright learning fiction as the parallel procession (optical memory hulls, gatherer recovery, the forge recasting with the killing flaw corrected, hundreds of staggered castings). The arc here is built on that fiction directly; the archive object is removed.

D9. Chorus admiral title. The shipped Chorus roster includes a name built on the retired song vocabulary for its regrowth admiral's family word; r8 section 5.10 keeps the admiral as the Mending Throng, which the pack uses. No Chorus name or line in Part 1 uses song vocabulary.

D10. Hegemony learning at courier speed. The Oct 28 ruling gives Hegemony learning a travel lag with no exceptions. The Hegemony payoff lines here state the lag as a property, not a slogan: doctrine arrives one sector behind where it was needed.

## Self-lint report

Method: Part 1 only (the story content above, from the Part 1 header to the end of the Eclipse section) was extracted and checked with word-boundary greps. Part 2 is meta text that must name the retired terms to document them, and is excluded from the counts by design; this paragraph is the disclosure of that exclusion. Code identifiers in node blocks (faction arc ids such as arc_vs_roll) are engine ids, not display text, the same status ids have throughout the project.

Counts (Part 1):
- Retired vocabulary (r8 sections 1.2, 1.3, 2.4, 5.2, 7.2 lists, 40 terms incl. plurals): 0 hits.
- Song and singing words, whole Part 1 and Chorus sections specifically: 0 hits.
- Smell words in Hullbreaker material: 0 hits (the motif was removed by r8; Hullbreakers here work by trail and sound only).
- Naval metaphors (sea, sail, anchor, port, starboard, keel, mast, harbor, ashore): 0 hits.
- Code ids used as display names (the four retired internal names): 0 hits.
- Pronouns: 4 hits, ALL KEPT DELIBERATELY and listed here: "her" x3 and "she" x1, every one referring to a named female admiral in her own spotlight line (Commodore Sera Ashgrove x2, Tamsa of the Clear Aperture x2 counting the capitalised sentence opener). No pronoun in Part 1 refers to the Nemesis, whose lines use the shipped {rival} token system, and none refers to an unnamed character. One ship-as-her instance found in drafting was rewritten to "its hull" and is not in the shipped text.
- Em dashes: 0. En dashes: 0 (verified by byte grep).
- Fixed pronouns (he, him, his, she, her) as standalone words: counted and reported in the table above; the design target was 0 outside the token forms {He} and {his}, which are the shipped gender-following tokens and appear only inside Nemesis lines.

Any hit kept, with reason, is listed in the table notes rather than silently passed.
