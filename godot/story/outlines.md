# Embers of the Hollow Sun: six faction story arcs (round 8)

Status: **rewritten Oct 31 2026 to the approved lore** (`contrib/opus/compute/lore_bible_r8.md`, Ryan "lore approved" Oct 27, FINDINGS R59). The arc structure Ryan approved in round 3 stands: three beats per faction, the rival is the run's Nemesis, every choice is read again later, beat 3 is a story decision with a cost, finishing an arc pays a cosmetic reward and a hull unlock (`unlocks.md`), and every faction's road ends at the Hollow Sun. What changed is the world: the factions, their reasons for going sunward, their voices and their words.

Companion file: `outlines_variants.md` holds a second version of every beat, the short "skim" cards for later runs, and the shared rival incidents.

Flag ids (`vs_hand`, `hg_offbook`, `cs_party`, `it_song`, `dd_writ` and the rest) are kept from the round 3 outlines so nothing downstream has to change, even where the story under them did.

## What each faction wants at the Hollow Sun

| Faction | Arc | Why they go sunward |
|---|---|---|
| Sunward Crusade | The Oath at the Hollow Sun | Break the siphon relay that is stealing the Vesper Reach's light. |
| Hegemony Navy | Registry Order 41 | Secure the Hollow Sun as an anchorage, because the Registry wants the cores. |
| Ashfall Hullbreakers | Rook's Trail | Run down R-5 Rook in the wreck fields and keep it: strongest keeps it. |
| The Chorus | Eat the Sun | Eat the other keys, reach the sun Memory still remembers, finish the war it was grown for. |
| The Glasswrights | The Last Lens | Bring the Lattice's last great lens home before Eclipse use it to steer their new sun. |
| Eclipse | The Homecoming | Bring the keys home and light a new sun at the heart of Ardent. |

## How an arc works

- Three beats, one per sector, each a 100 to 150 word card with a choice. A one-line charge sits above beat 1.
- Every option shows its effect up front and gives one outcome sentence after the click.
- Effects used: credits, repairs, experience, salvage (the item type, was relic), a ship joining, a refit, hull damage, the Nemesis clock, one weakness reveal per arc at most, an ambush. Every choice writes a flag and may add to the shared counters stream B reads (mercy, greed, loud).
- Beat 3 is shown as sector III begins; the arc closes on the result of his sector III fight. Winning it finishes the arc: medal, Chronicle entry, arc title, flagship paint, hull unlock. A Hullbreaker or Glasswright Nemesis can flee, any Nemesis can withdraw with his flagship intact, and an Eclipse one is restored once and comes back for a second fight (the arc then closes on that second fight). A win where he escapes still finishes the arc, and adds one line in your faction's voice:
  - Sunward Crusade: *{rival} slips away into the dark. Chalk {his} name on the hull, under the line. You will need it.*
  - Hegemony: *{rival} withdrew in good order. The file stays open.*
  - Hullbreakers: *{rival} cut {his} chains and ran. The pack has {his} scent now.*
  - Chorus: *{He} ran. We keep the smell.*
  - Glasswrights: *{rival} withdrew, the way light leaves a room. There will be another hour.*
  - Eclipse: *{rival} has gone dark for now. The Archive keeps {his} last position.*
- `[brackets]` are lines that show only when their condition holds; at most two show on a card. The checker (`godot/story/test/check_outlines.py`) measures each card at its shortest and longest.

**What a Chronicle entry records** (Career screen): the faction and arc, the rival's full name and faction, the three choices in their own words, whether you won, your first lost ship, and the title earned that run.

---

## 1. Sunward Crusade: "The Oath at the Hollow Sun"

Crest: a half sun, its lower half black, over a broken link. Register: spoken oaths, short imperatives, call and response. Motif: the names chalked on the flagship's hull, and the debt the Registry wrote off.

Charge: *Go sunward. Find what is stealing the light. Burn it out, and pay for it with names.*

### Beat 1 (sector I): The Ember Shard

The fleet holds station over Vesper's outer belt, where the core Seren drifted after the collapse and where the Crusade learned to make fire. Before you jump, every captain chalks one name on the flagship's hull: the one they refuse to let be written off. {best_captain} writes first. [Prior loss: two captains write {fallen_name}, from the crusade that did not come home.] The belt wardens bring a second matter. {rival} came through before you. {rival_deed} {He} left one thing untouched on the forge deck: a shard of Seren's own casing, still warm a thousand years on, as plain as a promise. I will come back for this. The wardens want the shard carried sunward. The quartermasters want it sold to the foundries before it draws {him} down on the fleet.

- **Carry the shard sunward.** Gain salvage: the ember shard. {He} hears that it has moved: the Nemesis clock moves on one. (flag `vs_hand`)
  *The wardens wrap the shard in quench-cloth and chalk its name on the casket. Somewhere, {rival} is told.*
- **Sell it to the foundries.** +60 credits. The wardens strike your name from the hull until it is earned back. (flag `vs_sold`, greed)
  *The foundry pays in hard coin. The wardens do not look at you again.*

### Beat 2 (sector II): The Dawn Horn

A bastion from the last crusade drifts out of the dark, decks gutted and frozen, its dawn horn still sounding on a dead watch officer's timer. The horn-code carries the last jump routes to the Hollow Sun. {rival} hung the wreck in your path and waits in the debris beyond. {rival_line} The watch officer says: recover the code, and give {him} the hours. The captains say: strike now, and let the horn sound for no one. [If you carry the shard: it has grown hot in its casket, and {rival} knows where it rides.] [If you sold it: the foundry coin is spent, and {rival} has sent you {his} thanks for it.] Every name on that bastion's hull is still legible under the frost. The oath allows no answer that is both swift and paid in full.

- **Recover the horn-code.** The routes save fuel: +50 credits. {He} is ready for you: the clock moves on one. (flag `vs_code`, mercy)
  *The code comes aboard as a list of numbers. The horn stops. Nobody likes the silence.*
- **Strike now.** Every captain gains 15 experience. (flag `vs_strike`, loud)
  *You fall on {his} pickets before they form. Behind you the horn goes on sounding the dawn for no one.*
- Blue, needs the shard: **Wake the horn with the shard.** Lose the salvage: the shard cracks in the horn's reactor. The clock goes back two and every captain gains 15 experience. (flag `vs_rang`)
  *One blast. The old horn sounds across the whole sector, louder than it ever did. The shard comes back to you in pieces.*
- Blue, needs the sale: **Pay a salvage crew to pull the code (40 credits).** They recover it while you strike: every captain gains 15 experience. (flag `vs_pilgrims`)
  *The salvage crew climbs aboard the frozen wreck with cutting torches. They chalk the dead's names on their own hull before they leave.*

### Beat 3 (sector III): Break the Siphon

The Hollow Sun fills the viewports, a black hole ringed in slow fire, the wrecks of a dozen crusades still circling it. At its rim hangs the siphon relay: the gate that takes Vesper's light and pours it into the dark. {rival} waits before it. {rival_line} [If the horn answered you: {rival}'s line has not formed cleanly since; {he} heard it across the sector.] [If it did not: the bastion's horn now sounds from {rival}'s line, for {him}.] [If you carry the shard: {he} asks for nothing but the shard.] [If you sold it: {rival} reads your name off the foundry ledger on the open channel.] Read the hull: every chalk name is still there. [If you lost ships: the crews have chalked {first_lost} beside them.] Call it across the fleet. Who carries the dawn? We do. Who pays for it? We do. The relay can be burned two ways. With Seren's fire, or with a reactor run past its limits.

- **Burn it with the shard** (needs the shard, whole). Lose the salvage. Every ship repairs 25%. (flag `vs_lit_saint`)
  *You set the casket in the firing chamber with your own hands. The chalk names seem brighter. That is the fire.*
- **Burn it with a reactor.** Your largest ship takes 25% hull damage. Every captain gains 25 experience: they would follow you into the star. (flag `vs_lit_reactor`)
  *The engineers swear as they rig the reactor. Then they cheer. Then they get back to work.*
- Blue, needs the sale: **Buy back your name (60 credits).** The wardens chalk it again: every ship repairs 15%. (flag `vs_bought`)
  *Your name goes back on the hull, one line lower than it was before.*

Win: *{rival}'s flagship breaks against the old wrecks and falls into the dark. The relay burns for an hour, and far behind you, for the first time in ninety years, Vesper rises a little brighter.* + shard: *Seren's fire goes into the relay and does not come back; the wardens say that was always where it was going.* / reactor: *The ship that gave its reactor limps home dark, and the crews chalk a new name on her: yours.* / bought back: *The wardens add your name to the Roll of Vesper, near the bottom, where the living go.*

Loss: *The chalk names burn with the hull.* + carried the shard: *The shard goes into the dark with the fleet, and the relay keeps drinking.* / sold it: *Somewhere a foundry lights its forge with your coin. It is the only fire the crusade leaves.*

---

## 2. Hegemony Navy: "Registry Order 41"

Crest: a wedge in a ring of five linked nodes. Register: documents, numbers, projections, understatement; the Registry speaks after a two-note chime. Motif: the quiet horror of being counted.

Charge: *Secure the Hollow Sun as a fleet anchorage. Projection: favourable. Losses: acceptable. Appendix attached.*

### Beat 1 (sector I): Listening Post M-14

The orders arrive after the two-note chime, numbered and without courtesy. Registry Order 41. Losses are to be held within acceptable limits; the definition of acceptable is attached as an appendix of nine pages. [Prior loss: Order 41 has a previous holder. Their entry has been closed out of your copy.] A second packet concerns Listening Post M-14, fourteen crew, last report overdue. {rival} reached it first. {rival_deed} The Registry has a file on {him} and nothing in it that helps. It projects that pursuit without authorisation would be suboptimal. Your intelligence officer switches off her link for a moment and asks, quietly, whether you would like the post's black box recovered anyway, on your own authority and off the record.

- **Recover the black box, off the record.** It holds the post's last refit: gain a random refit. The recovery team is logged: the clock moves on one. (flag `hg_offbook`)
  *The box comes aboard in a crate marked laundry. The fourteen names are on a single sheet. You read it twice.*
- **Follow the Order to the letter.** Registry commendation: +50 credits. (flag `hg_orders`)
  *The commendation arrives within the hour. M-14 is closed out of the projection with all hands, in the correct format.*

### Beat 2 (sector II): Acceptable Limits

A Navy supply column, eleven haulers and one escort, has been driven onto the gravity shoals of sector II. {rival} holds the only exit and has not fired. {rival_line} The Registry is precise: the column is within acceptable limits; proceed to the objective. Your flag captain hands you a second message, from the escort's commander, a lieutenant of nineteen: we will hold as long as we can. [If you went off the record: the black box gave you {his} patrol pattern, and {he} knows it is missing.] [If you followed the Order: {rival} has sent your commendation back to you, unsigned.] To break through is to overrule the Registry. To leave is to follow the projection, and watch eleven crews closed out on schedule.

- **Overrule and break them out.** The lieutenant forms on your flagship: a Hegemony picket joins with a veteran captain. No bonus, and the clock moves on one. (flag `hg_broke`, mercy, loud)
  *Eleven haulers and one battered picket fall in behind you. The Registry acknowledges receipt of your report. Nothing else.*
- **Proceed to the objective.** Registry allocation: +80 credits. (flag `hg_left`, greed)
  *The column's last signal is logged at 0340. Your flag captain initials the log and does not look up.*
- Blue, needs the black box: **Run {his} patrol gap.** The column lives and the picket joins, unseen: no clock. Every ship takes 10% hull damage in the gap. (flag `hg_broke`, mercy)
  *You thread {his} pickets at a distance the manual calls reckless. The lieutenant calls it the best flying she has seen.*
- Blue, needs the commendation: **File for an exception (spend the commendation: 50 credits).** Six haulers are reclassified as essential and saved: every ship repairs 15%. Five are not. (flag `hg_split`)
  *The exception is approved for six hulls, by number. The remaining five are informed of their status.*

### Beat 3 (sector III): The Anchorage

The Hollow Sun is exactly as cold as the survey projected. {rival} has dug in among the shattered buoys at the anchorage mouth. {rival_line} [If you broke the column out: somebody leaked your reprimand to {rival}; {he} sent you a copy, annotated.] [If you did not: {rival}'s flagship carries the column's registry numbers along its flank.] Authorisation arrives eleven days late, stamped and countersigned, with a projection of your losses to the nearest hull. [If you broke the column out: the lieutenant's picket holds station off your bow and has not asked for orders.] [If you left them: the list from M-14 has eleven new names. Your flag captain added them.] [If you filed the exception: the list has five.] The guns are synchronised. The column is formed on your flagship. Your flag captain asks if there are orders beyond the obvious, and waits. There is one tradition the Registry never logs. Before a decisive engagement a commander switches off the link for one minute and speaks to the whole line, unrecorded.

- **"Name, rank and number. All of them."** Read the list. Every captain gains 25 experience: the crews fight for the dead. (flag `hg_names`)
  *You read every name, rank and number. It takes four minutes. The link comes back on after five.*
- **"You are not required to be brave. Only correct."** Every ship repairs 20%: the crews go back to work. (flag `hg_duty`)
  *Damage control teams are moving before you finish the sentence. That is the correct response.*
- Blue, needs the column: **Give the lieutenant the minute.** Every captain gains 15 experience and every ship repairs 10%. Her picket goes in first. (flag `hg_lt`)
  *She says eleven words, one for each hauler. Then the column forms on her, not on you, and you allow it.*
- Blue, needs the Order followed in sector I (and the commendation not spent): **Call in the commendation (40 credits).** The Registry allocates what an obedient commander is owed: a Hegemony picket joins with a veteran captain. (flag `hg_support`)
  *A picket arrives with a form to sign. It is the first thing the Registry has sent on time.*

Win: *The anchorage is secured at 0412 ship time.* + names: *Your report runs to a single line, followed by the list. The Registry files it and then, without precedent, keeps the list open.* / duty: *Your report runs to a single line. The Registry files it.* / lieutenant: *She is promoted. Nobody can find the entry that authorises it, and nobody looks.* / commendation: *The Registry notes your record: every order followed, every projection met. It is the most frightening sentence in your file.* + went off the record: *The inquiry opened over the black box is quietly closed.*

Loss: *Order 41 is marked incomplete. Within a month a new commander receives it, numbered and without courtesy.* + read the names: *The new copy has a list attached. Your name is at the bottom, in the correct format.* / went off the record: *The inquiry over the black box proceeds in your absence. It finds against you.*

---

## 3. Ashfall Hullbreakers: "Rook's Trail"

Crest: a ring of welded scrap teeth around three claw slashes. Register: short, flat, brutal; trails, sound, kills, the pack; a growl under every word. Recurring face: Old Mott, who has outlived forty captains.

Charge: *Rook drifts in the wreck fields round the Hollow Sun. Run it down. Strongest keeps it.*

### Beat 1 (sector I): The Torn Den

Word in the Ashfall dens is that the core Rook, the Breaker, has been heard in the wreck fields around the Hollow Sun: a slow tick of engine noise where no engine is. Old Mott says whoever holds Rook cannot be stopped. He has said that about forty things. This time the whole belt is listening. You go first, which makes you strong or dead. [Prior loss: the dens say the last captain who went for Rook is still out there, frozen into the wreck field. Nobody says it to your face.] Before you clear the den, word comes about your forward camp. {rival} got there first. {rival_deed} The pack wants an answer, with a charge in it. The others want a feast and a howl before the hunt. Both are old ways.

- **Send an answer, rigged.** The dens start betting on you: +40 credits. {He} takes it personally: the clock moves on one. (flag `cs_rigged`, loud)
  *The answer goes out wrapped in trophy plate. The odds the dens give on your survival are insulting.*
- **Feast and howl.** The pack swears on the hunt: every captain gains 15 experience. (flag `cs_party`)
  *Two days. Mott tells everyone how he killed his ninth captain, then his twelfth, then about a broker at Rattlehold, then falls asleep.*

### Beat 2 (sector II): The Rattlehold Challenge

The wake-log of Rook's drift, a thousand years of ion trail, is held at Rattlehold, the biggest den in sector II. Any pack can claim it the old way: challenge the den-boss who holds it, or pay. Every crew with a ship and a grudge is here. {rival} is not bidding. {His} pack waits off the rock, listening for who walks out with it. {rival_line} The knife crews say take it, start a fight, run dark under the noise. The quartermaster says pay what it costs and owe nobody. [If you feasted: Mott knows the broker who keeps the log from his own stories, and is still ashamed of what he said.] [If you rigged your answer: {rival} heard about it; {his} pack keeps its distance.] Rattlehold respects both. It only remembers one.

- **Take it and wreck the docks.** The log, and whatever else was on the clamps: gain salvage. Your next fight starts as an ambush. (flag `cs_stole`, greed, loud)
  *Rattlehold burns for a week. Three packs swear you started it. Two of them are right.*
- **Pay full price (80 credits).** Rattlehold remembers a pack that paid: a Hullbreaker raider crew signs on with you. (flag `cs_paid`)
  *The quartermaster pays in counted scrap. A raider watching from the back says she has never seen that before, and asks to run with you.*
- Blue, needs the feast: **Let Mott talk to the broker.** The log for 30 credits, and the broker tells Mott a weakness of {rival}'s. Your flagship captain loses 15 experience to the drinking. (flag `cs_mott`)
  *They hunted together once, briefly. Neither will say more. Your flag captain cannot say anything at all until morning.*
- Blue, needs the rigged answer: **Remind the room about your answer.** Nobody contests you: the log for 20 credits. {He} hears about it: the clock moves on one. (flag `cs_feared`, loud)
  *You mention the answer once, quietly. The room finds other things to fight about.*

### Beat 3 (sector III): Strongest Keeps It

Rook is real. In the cold glow of the Hollow Sun a ship-sized core turns among a dozen dead hulls, still ticking, still hot. Old Mott goes very quiet. {rival} got here first and has chained {his} pack to the wrecks around the core, daring you to shoot through the prize to reach {him}. {rival_line} [If {rival} lost face at Rattlehold: every pack in the dens knows it, and {he} knows they know.] [If {he} let you buy the log: {he} wanted you to bring it here.] [If you wrecked Rattlehold: your crews still smell of its smoke.] [Prior loss: in the ice between two wrecks, a familiar hull. The plate still reads {prior_flagship}.] The crews are already arguing over who gets first pick of the core and the wrecks around it, which is bad luck. Tonight you tell them what kind of pack they are. Mott wipes his muzzle and waits.

- **"First pick for every claw. We go round the core."** Fight clear of the wrecks. Every captain gains 20 experience. They will hold you to it. (flag `cs_double`)
  *The howl carries across three ships. The quartermaster quietly starts a second tally.*
- **"Shoot through it."** Strip plate from the outer wrecks first: every ship repairs 25%. Rook takes damage it may never shake. (flag `cs_through`)
  *Nobody howls. The cutting crews go to work on the outer hulls. Mott starts swearing and does not stop.*
- Blue, needs the feast: **Let Mott speak to the pack.** Every captain gains 10 experience and every ship repairs 10%. (flag `cs_mottspeech`)
  *Mott talks about his forty captains for nine minutes. By the end, the hard cases are howling with him.*

Win: *{rival}'s chains part, and the pack closes on the core.* + first pick: *The claims take three days and two challenges. Mott takes nothing, which frightens everyone.* / through: *Rook still ticks, slower now. The crews will tell this one for years, and not kindly. Then the quartermaster gives away his own share, which has never happened.* / Mott: *Mott lays one claw on Rook and says it is warmer than he thought. Nobody argues.* + rigged answer: *Somebody sends {rival}'s wreck one last answer, wrapped in trophy plate. Nobody owns up.*

Loss: *Your hull joins the wreck field around Rook. Some later pack will hear the legend and come looking.* + first pick: *The crews never collect. The dens still fight over who inherits the claim.* / feasted: *The dens hold a second feast, for you. It is quieter.*

---

## 4. The Chorus: "Eat the Sun"

Crest: a ring of nine open mouths. Register: "we", sentences of nine words or fewer, taste, heat, smell, teeth. Two throats argue in every beat: Hunger, which is the swarm, and Memory, which is what is left of the Fleshwrights it ate. The Chorus never sings.

Charge: *Five warm keys circle the Hollow Sun. Memory knows the place. Eat them.*

### Beat 1 (sector I): The Split Node

We wake hungry. Every throat, one want. Far off, the Hollow Sun. Dead outside. Warm inside. Keys, humming with old heat. Memory knows that star. It circled it, once, with hands. [Prior loss: we have been here before. We remember the cold.] The first night, we find a node. Split open. The young inside untouched. Left to spoil. Nothing hunts like that. Nothing wastes like that. {rival} did this. {rival_deed} We taste the wound. Hunger says: eat the dead. Grow. Memory says: leave them. Keep the smell. Then we know what to chase. Two throats. One swarm. The swarm waits for you.

- **Eat the dead.** Every ship regrows 30% of its hull. Hunger grows louder. (flag `ch_ate`)
  *We eat. It tastes of {him}. Hunger purrs.*
- **Keep the smell.** We know where {he} goes: the clock goes back one. Memory grows louder. (flag `ch_smell`)
  *We leave them. The smell stays in every throat. Memory is pleased.*

### Beat 2 (sector II): The Warm Shallows

A sea world. Shallow. Warm. Full of drifting spawn. Unclaimed. Ours, once. {rival} has seeded the shallows with mines. {He} waits above. {rival_line} Hunger says: dive. Eat. Take the losses. Come out heavier. Memory says: feed the spawn. Our own flesh. They rise. They fight beside us. [If we ate the dead: Hunger is louder since the node. {He} knows. {He} left the mines where hungry things dive.] [If we kept the smell: the smell is here. Fresh. {He} passed an hour ago.] The heat comes off the water in waves. The mines tick. Tick. The spawn turn toward us, mouths open. The small ones cry out. They are hungry, like us. Hunger has never had to choose before. It does not like it.

- **Dive and eat.** Every ship regrows 30% of its hull. {He} hears the feeding: the clock moves on one. (flag `ch_dove`, loud)
  *We dive. We eat. The mines take some of us. We eat those too.*
- **Feed the spawn our flesh.** Every ship loses 5% of its hull. A Chorus drone-spawn joins the swarm. (flag `ch_spawn`)
  *We open. They drink. One of them grows teeth before the tide turns.*
- Blue, needs the smell: **Follow the fresh smell.** Every ship takes 8% hull damage in the chase. We catch {his} pickets unready: a Nemesis weakness is revealed. (flag `ch_hunted`)
  *We run {him} down through the shallows. {His} pickets taste of fear. We learn where {he} is soft.*
- Blue, needs the eating: **Let Hunger lead.** Eat the mines too: every ship takes 10% hull damage, then regrows 40%. Memory goes quiet for the rest of the hunt. (flag `ch_hunger`)
  *We eat the mines. They burn. We eat the burning. Memory stops talking.*

### Beat 3 (sector III): Eat the Sun

The keys are warm. Every throat feels them. Heat on the hide. A hum under the static. Memory says a name for this place. Ardent. {rival} stands in front of it. Between us and the heat. {rival_line} [If we hunted {him}: {he} limps. We bit {him} in the shallows. {He} remembers our teeth.] [If we did not: {he} is fat from the shallows. {He} ate what we left.] We do not answer in words. The keys are close. We smell them through the dark. Old. Sweet. Ours. {He} smells of fear and metal. Both taste good. [If Hunger leads: only Hunger speaks now. Memory is a scar.] [If we fed the spawn: the small ones from the shallows swim beside us. Furious.] Hunger says: open every mouth. Eat it all. Now. Memory says: taste first. Learn {him}. Then eat. Nine mouths. One answer. The heat rises.

- **Open every mouth.** Every ship regrows 20% of its hull. (flag `ch_end_hunger`)
  *Every throat opens at once. The sound is not a sound. {He} hears it anyway.*
- **Taste first** (not if Hunger leads). Every captain gains 25 experience. (flag `ch_end_memory`)
  *We taste the air {he} came through. We learn the shape of {his} fear. Then we move.*
- Blue, needs the spawn: **Send the small ones first.** Every ship regrows 10% and every captain gains 15 experience. The small ones will not come back. (flag `ch_end_spawn`)
  *They go laughing, if it is laughing. {His} guns turn to them. We go through the gap.*

Win: *We close over the dead star like a hand.* + Hunger: *We eat until nothing warm is left. We are bigger than we have ever been. We are still hungry.* / Memory: *We eat slowly. Memory knows this light. For a moment it speaks in a Fleshwright's voice, and says thank you.* / the small ones: *None come back. The swarm keeps a hollow where they were.* + ate the dead in sector I: *The split node tasted of {him}. So does this. Good.* / kept the smell: *The smell from the split node fades at last. We do not need it now.*

Loss: *The hunger goes quiet. In the cold, the warm keys wait for the next mouth.* + Hunger led: *Hunger was the last throat to stop.* / kept the smell: *Memory keeps the smell. Some other swarm will find it.*

---

## 5. The Glasswrights: "The Last Lens"

Crest: a cracked lens with one beam of light passing through. Register: quiet, precise, mournful; light, reflection, focus, what we built; they apologise and mean it. A fussy cataloguer supplies the humour. No faction sings: the Glasswrights' sound is one clear tone, like struck glass.

Charge: *The Lattice's last great lens lies at the Hollow Sun. Bring it home before our siblings use it to steer a stolen sun.*

### Beat 1 (sector I): The Mirror-Buoy

The Hollow Sun was Ardent once, and your grandmother's grandmother ground the lenses that harvested it. The Lens-keepers have sent you to bring home the last great lens of the Lattice before Eclipse fit it to their new sun. They have reminded you, twice, to bring its mounting as well. [Prior loss: the Lens-keepers do not mention the last voyage. The youngest captains know not to ask.] On the first night a mirror-buoy older than any living Glasswright turns toward your fleet and flashes a warning in a light-code your cataloguer has only read about. {rival} passed this way. {rival_deed} The buoy offers the light it has stored for a thousand years. Taking it would leave it dark for good. Your cataloguer would very much like to take it.

- **Take its stored light.** It holds {his} route: the clock goes back one. The buoy goes dark. (flag `it_song`)
  *The buoy gives its light gladly, which is worse. Your cataloguer files it under irreplaceable and does not speak for an hour.*
- **Let it keep its light.** Your captains carry its warning instead: every captain gains 15 experience. (flag `it_mercy`, mercy)
  *The buoy dims itself back to rest. Your cataloguer sulks, makes a note, and then a second note.*

### Beat 2 (sector II): The Ringing Field

In sector II the voyage crosses the Ringing Field, crystal wrecks of the old fleet that still ring when light strikes them. {rival} has made the field a trap: every wreck {he} breaks flares, and the flares blind your sensors. {rival_line} Your captains are young as Glasswrights count it, barely a century, and some are weeping at their stations; the cataloguer is logging every flare, in tears, with exact timings. Your oldest Mirror flew in this fleet when it was whole. She says one mourning tone, struck through every hull, would quiet the field, if you can spare the time. [If you took the stored light: it answers the flares; {rival} breaks the wrecks in the order it remembers.] [If you let the buoy rest: its warning was about this field; your captains know the path {rival} did not mine.]

- **Strike the mourning tone.** The captains steady: every captain gains 20 experience. {He} sees you coming: the clock moves on one. (flag `it_lament`)
  *The wrecks hear their own tone and go still, one by one. The cataloguer records the order.*
- **Go dark through the flares.** Every ship takes 5% hull damage. You catch {him} unready: a Nemesis weakness is revealed. (flag `it_dark`, loud)
  *You fly blind through the flaring glass. When the sensors clear, you are close enough to see {his} seams.*
- Blue, needs the stored light: **Release the buoy's light.** The wrecks fall still at once: no damage, and the clock goes back one. The light is spent; you will not bring it home. (flag `it_spent`)
  *The field goes dark in a single breath. Your cataloguer crosses one line out of the inventory, very neatly.*
- Blue, needs the warning: **Take the warned path.** Slow and safe: no damage, no clock, and every captain gains 10 experience. (flag `it_path`)
  *The path is exactly where the buoy said. The cataloguer adds a footnote crediting it.*

### Beat 3 (sector III): The Last Lens

The Hollow Sun is a black pearl in a halo of dead light. At its rim hangs the lens: a disc of crystal wider than your fleet, still turning to follow a sun that is not there. {rival} has reached it first. {rival_line} [If you caught {him} in the Ringing Field: {rival} stopped breaking glass, and has not forgiven you for making {him} stop.] [If you did not: {rival}'s flagship carries one shard of the Ringing Field on its prow, still ringing faintly.] Before battle every ship turns its mirrors toward the Sun, as your people have for a thousand years. [If the buoy's light is still aboard: it would wake the lens without a fight at its mounting.] [If you let the buoy rest: far behind you it still turns its warning toward the lens.] [If you lost ships: the {first_lost} is not with you; you will have to explain that to the Lens-keepers, in writing.] Every ship in this fleet is a light that will not be lit again. Your cataloguer asks, very politely, which you mean to save if you cannot save both: the lens, or the fleet.

- **Save the lens.** Send the oldest ship ahead to free its mounting: one of your ships takes 25% hull damage. Every captain gains 25 experience. (flag `it_end_archive`)
  *The oldest ship lowers its shields and flies into the light. The lens turns to follow it.*
- **Save the fleet.** The lens has waited a thousand years; it can wait an hour. Every ship repairs 20%. (flag `it_end_fleet`)
  *You hold the line at the mounting. The cataloguer says nothing, loudly.*
- Blue, needs the buoy's light: **Pour the buoy's light into the lens.** The light is spent: every ship repairs 10% and every captain gains 15 experience. (flag `it_end_buoy`)
  *The lens drinks the old light and wakes like an eye opening. The buoy, wherever it is, would be pleased.*
- Blue, needs the buoy spared: **Ask the buoy to wake the lens.** It turns once more, from afar, and goes dark for good: every ship repairs 10% and every captain gains 15 experience. (flag `it_end_mercy`)
  *Across three sectors an old mirror flashes one last line. The lens sees it and wakes. Your cataloguer does not sulk.*

Win: *The lens comes free of its mounting and turns, for the first time in a thousand years, toward something other than the dark.* + lens: *On the voyage home your youngest captain learns to read the light ground into its rim, slowly, and the Lens-keepers weep.* / fleet: *You bring every ship home. The Lens-keepers receive the lens with polite disappointment and file your report under unusual.* / buoy: *The buoy's light goes home inside the lens. The cataloguer writes returned in the margin and underlines it.* / the spared buoy: *On the way home you pass its mirror, dark now. The whole fleet dims its running lights for it.*

Loss: *The last vane folds. The lens keeps turning, and Eclipse comes for it.* + saved the lens: *The oldest ship is still at the mounting with its lights on, guarding a lens nobody will carry home.*

---

## 6. Eclipse: "The Homecoming"

Crest: an eclipsed sun, a black disc with a thin white-gold ring. Register: cold, exact, quietly grieving; counted years, worn bodies, the warmth they remember and can no longer feel; sentences that start to doubt the Upload and stop. Motif: the Archive, where every mind is backed up and nothing is forgotten.

Charge: *The keys are scattered. The new sun waits for them at the heart of Ardent. Bring them home.*

### Beat 1 (sector I): The Broken Frame

We wake by schedule, frame by frame, as we have every century for a thousand years. The Archive lists what remains to be done. Six keys, four still scattered. One new sun, unlit, at the heart of Ardent. The Homecoming begins again. [Prior loss: the Archive notes a previous attempt. It does not note your name. That is a courtesy.] One entry troubles the Archive. A siphon array at the edge of the first sector was entered before your arrival, its keeper's frame dismantled with care, and the keeper's key codes taken. The keeper's last backup is nine years old. {rival} did this. {rival_deed} Your Shades ask leave to pursue. Your Umbras recommend patience. The Archive permits either. It forgets neither.

- **Pursue at once.** The frames are honed for it: every captain gains 20 experience. {He} sees you hunting: the clock moves on one. (flag `dd_writ`, loud)
  *The order is copied to every frame. It names {rival}, the hour, and the keeper who lost nine years. The keeper is restored and does not remember why everyone is angry.*
- **Be patient.** The array's repair swarms mend the fleet while your Umbras read what {he} left: every ship rebuilds 15%. (flag `dd_patient`)
  *The Umbras take the keeper's dismantled frame to a quiet bay and read it like a ledger.*

### Beat 2 (sector II): A Key in the Wrong Hands

In sector II the stolen key codes surface, broadcast at the head of {rival}'s fleet to every array in range, unlocking them one by one. {rival_line} Below your fleet lies a dormant hull yard, its frames stored without minds. You could wake them with copies from the Archive. But every mind in the Archive is already awake somewhere; to run a second copy of a living mind is the one thing the Upload forbade. [If you were patient: the Umbras finished reading the keeper's frame, and know where its codes hide a flaw.] [If you pursued: {rival} answered; {he} has entered your name in {his} own records.] The Archive cannot permit a doubled mind. It cannot permit a stolen key. It has never been asked to choose.

- **Wake the copies.** An Eclipse flare joins the fleet, crewed by minds that are also elsewhere. The rule is broken, and the clock moves on one. The array's guard frames will not wake for you. (flag `dd_broke`)
  *The frames rise, meet themselves on the open channel, and agree never to speak of it.*
- **Keep the rule.** Nothing now. The Archive will know. (flag `dd_lawful`)
  *You leave the yard dormant. The Umbras note the restraint, and the date, and the reason.*
- Blue, needs patience: **Trigger the flaw in the codes (costs a refit from the hold).** {He} is shamed before {his} fleet: a Nemesis weakness is revealed and the clock goes back one. (flag `dd_flaw`)
  *Every array {he} unlocked locks again at once, in plain view of {his} fleet.*

### Beat 3 (sector III): The Homecoming

Ardent turns overhead: the Hollow Sun, black and enormous, and at its heart the frame of the new sun, dark, waiting for its keys. {rival} has drawn up across the approach as if {he} had any right to be there. {rival_line} [If the codes failed {him}: {rival} no longer broadcasts the key; every array between here and sector I has locked {him} out.] [If they did not: the stolen codes still flicker across {rival}'s flagship's hull, where every frame can see them.] Every ship shows the last recorded image of Ardent at noon. Nobody aboard can feel its warmth. Everybody aboard remembers it. [If you woke the copies: they hold the formation's edge, and will not look at themselves.] [If you kept the rule: the array's guard frames, lawfully woken, ask formally for their place in the line.] We remember noon. The new sun needs every key, and {rival} is holding the door. The arcs charge. The question is what you will enter in the Archive first.

- **Enter nothing.** No copy of {him}, no record. Every captain gains 25 experience. (flag `dd_erase`)
  *The Archive prepares a blank line, and waits to fill it with nothing.*
- **Enter {him}.** {He} will be copied into the Archive and kept, forever. Every ship rebuilds 15%. (flag `dd_summons`)
  *The notice is sent to {his} flagship, politely: {he} will be preserved. We consider this a kindness.*
- Blue, needs the rule kept: **Give the guard frames their place.** An Eclipse mote joins the fleet. (flag `dd_guard`)
  *The guard frames take position at your flank. They acknowledge the Archive, not you.*

Win: *The approach is cleared. One by one the keys are carried in, and the frame of the new sun begins, very faintly, to warm.* + nothing: *The Archive holds a blank where {rival} was. It is the only blank in a thousand years.* / copied: *{rival} wakes in the Archive and asks what year it is. Nobody answers for a long time.* / copies woken: *The doubled minds are folded back into one. Both remember it, which should not be possible.* + pursued in sector I: *The keeper's nine lost years are entered as paid.* / were patient: *The keeper's old frame is set at the foot of the new sun, facing it.*

Loss: *We go dark here. The Archive keeps our last copies, and the frame of the new sun stays cold.* + copies woken: *Somewhere a doubled mind keeps running, alone, and nobody can tell which one it is.* / pursued: *The keeper's nine lost years stay open in the Archive. We are patient.*

---

## Table A: the rival's calling card, `{rival_deed}` (his faction x his persona)

One sentence, written to fit any beat 1 that says "{rival} did this" or "{rival} got there first". Pronouns follow the generated commander (a Chorus mind is "it"). The four personas per faction are stream B's own (data.js `NEM_FAC[fac].personas`, R42). The live lines are in `data/rival_lines.json` (`deed`).

| His faction | Persona: calling card |
|---|---|
| Sunward Crusade | **zealous:** {He} chalked every name in the place on the walls, then burned it, so the names would be the last thing standing. <br> **proud:** {He} left a formal challenge chalked across the door, signed with {his} full name and every title. <br> **cruel:** {He} burned everything but one thing, so you would know it had been chosen. <br> **methodical:** {He} left a reckoning, three lines long, with your name on the third. |
| Hegemony | **methodical:** {He} left an inventory of what was taken, and when {he} will return for the rest. <br> **proud:** {He} left a notice of claim, numbered and countersigned. <br> **patient:** {He} sealed the doors and left a timetable on them: the hour {he} expects you, to the minute. <br> **cunning:** {He} left a forwarding address that is a trap, and a polite note saying so. |
| Hullbreakers | **cunning:** {He} left one trophy plate behind, with your name scratched in it, which is worse than a threat. <br> **greedy:** {He} stripped everything, then came back for the bolts. <br> **proud:** {He} clawed {his} mark into the door, very deep, where the whole pack could see it. <br> **cruel:** {He} left the crew alive, in the airlock, with the outer door ajar. |
| Chorus | **ravenous:** {He} ate everything, the walls included, and left the hole. <br> **cruel:** {He} ate slowly, so the rest could watch. <br> **cunning:** {He} left the doors open and the food out, and waited to see who came. <br> **patient:** {He} waited until the young were fat, then ate only those. |
| Glasswrights | **cunning:** {He} left everything exactly as it was, minus one thing nobody noticed for a week. <br> **proud:** {He} left a single flawless lens on the floor, ground to a focus nobody living can match. <br> **patient:** {He} turned every mirror in the place toward the Hollow Sun, and left them to wait. <br> **cruel:** {He} stayed long enough for every light there to burn out, one by one. |
| Eclipse | **patient:** {He} left a counter running on the wall, and it was counting down to you. <br> **proud:** {He} left the last recorded image of Ardent burning on every screen, so you would know what {he} had lost. <br> **cruel:** {He} copied the crew into {his} Archive and left their bodies standing at their stations. <br> **methodical:** {He} catalogued the place, and left the catalogue on the door with your name on the last page. |

## Table B: the rival's beat 3 hail (what the Hollow Sun means to him, and what he remembers)

Picked in this order: **remembers** (you beat him before, or he carries scars), **mercy** (your choices leaned merciful), **ruthless** (they leaned greedy or loud), else **the Sun to him**. The live lines are in `data/rival_lines.json` (`final_by`).

| His faction | The Sun to him | Remembers | Mercy | Ruthless |
|---|---|---|---|---|
| Sunward Crusade | "Behind me is the thing stealing the light from forty worlds. You will not stand between me and it." | "You marked me {scars}. I kept every scar for this reckoning." | "You spared the weak on your way here. The cold will not." | "You came here with stolen coin and burning wakes. At least you will match the place." |
| Hegemony | "The Registry projects one fleet in this anchorage. It will not be yours. Stand down and be counted." | "Our last engagement has been reviewed. The review recommends your removal." | "You stopped for stragglers. I read the report. I would not have." | "You left people behind for a bonus. I read that report too. We should not both be here." |
| Hullbreakers | "The biggest fight in known space, and you came to it. Good. Now I find out what you are worth." | "Last time you were stronger. I kept your dents as trophies. Come and add one." | "I heard you went soft on the way in. Soft ships open easy." | "I heard you burned your way here. Strong. I will still take it." |
| Chorus | "It is warm in our mouths already. You are the part in the way." | "We remember the taste of you. We want the rest." | "You leave food on the plate. We do not." | "You eat like us. Good. We will eat you like us." |
| Glasswrights | "We built the light. We will not let it be stolen again. Not by them, and not by you." | "You scarred me {scars}. I had not been scarred in three centuries. I have been thinking about you." | "You let an old thing rest, once. That was kind. It will not save you." | "You broke old things to get here. Then we are alike, and I am sorry for you." |
| Eclipse | "Behind me is the frame of a new sun. It needs every key. You will not be the one who keeps one." | "You delayed me. Delay is all the warm ever manage." | "Your restraint is noted. We were restrained once. It did not save the sun." | "You broke things to reach this place. So did we, a thousand years ago. Look where it led." |

## Cross-run callbacks (from the Chronicle)

- Prior loss with this faction: each beat 1 carries a bracket line (above). The Hullbreaker beat 3 can show the last lost flagship frozen into the wreck field (`{prior_flagship}`); Crusade captains chalk `{fallen_name}` from the Hall of the fallen.
- Prior win with this faction: a one-line nod in beat 1 instead (in the variants file).
- After an arc has been finished twice, its cards offer the skim version first (variants file), with "Read in full" one click away.
- A rival who beat you last run may come back (stream B's call): his beat 1 deed is replaced by "{rival} has broken a fleet of yours before. {He} has not forgotten, and neither have the crews."

## Word counts

Checked by `godot/story/test/check_outlines.py`: every card is at least 100 words without its conditional lines and at most 150 with its two longest, counting tokens at the length they render; no em dashes; skim cards 40 words or fewer.
