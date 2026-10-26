# Voidsworn story outlines: six faction arcs (REVISED)

Status: **REVISED Oct 26**, after two blind reviews (contrib/claude_fable/story_review_2026_10_26.md, contrib/claude_sonnet/story_review_2026_10_26.md). Waiting for Ryan's approval before the arcs are built (plan B5 exit gate, R37). Ryan's earlier answers stand: finishing an arc pays a cosmetic reward and a hull unlock (godot/story/unlocks.md); the shared finale at the Hollow Sun stays.

Companion file: `outlines_variants.md` holds a second version of every beat (so a faction you play often does not repeat), the short "skim" cards for later runs, and the shared rival incidents.

## What changed

1. **The rival is a different person each run.** {He} is the run's Nemesis from stream B (faction, personality, scars, memory, R42). Beat 1's calling card is a `{rival_deed}` slot filled by **his faction and personality**: some deeds are cruel, some are a courtesy, a bribe, a notice or a joke, so not every arc opens on a grisly token (table A below). Pronoun tokens `{he}` `{him}` `{his}` follow the generated commander (he, she, or it for a Chorus mind), so rivals can be women.
2. **He remembers.** Every beat carries a `{rival_line}` picked from his pools (godot/story/data/rival_lines.json): first meeting, rematch, his scars, how you beat him last time. Beat 3 hails say what the Hollow Sun means to **him** and change with what you did (table B). Cards also use run facts: `{first_lost}` (your first lost ship), `{best_captain}` (your most experienced captain), `{fallen_name}` (a captain lost in an earlier run).
3. **Real dilemmas.** Every beat 1 choice is read again in beat 2 and beat 3 (no dead branches). Beat 3 is a story decision with a cost, and the win and loss lines change with your choices.
4. **Blue options cost something** (the relic, hull, credits, a refit, or a later reward they lock). None is a free superset.
5. **Fewer weakness reveals:** at most one per arc. Rewards lean on ships joining, relics, repairs, experience and the clock.
6. **Six registers.** Voidsworn speak in second-person liturgy and the debt of names. Hegemony in documents and numbers. Corsairs in jokes, names and money. Chorus in sentences under eight words, by taste, heat and smell, with two throats (Hunger and Memory) arguing; **the Chorus no longer sings**. Ithar in memory, light and glass, grief with a fussy archivist's humour (song belongs to them alone). The Court (Deathless) in law, record and polite contempt; no bureaucracy jokes, those are the Hegemony's.
7. **Further from Warhammer 40k.** No "younger races"; the Deathless story uses vaults, seals, writs and the Court instead of tombs, crowns and dynasties.
8. **Replay.** Two versions of every beat, a skim card for later runs, Chronicle callbacks across runs, and twelve shared rival incidents (in the variants file).

## How an arc works

- Three beats, one per sector, each a 100 to 150 word card with a choice. A one-line charge sits above beat 1.
- Every option shows its effect up front and gives one outcome sentence after the click.
- Effects used: credits, repairs, experience, a relic, a ship joining, a refit, hull damage, the Nemesis clock, one weakness reveal per arc at most, an ambush. Every choice writes a flag (the event system already does this) and may add to the shared counters stream B reads (mercy, greed, loud).
- Beat 3 is the Nemesis's last fight. Winning it finishes the arc: medal, Chronicle entry, arc title, flagship paint, hull unlock.
- `[brackets]` are lines that show only when their condition holds; at most two show on a card. The checker (`godot/story/test/check_outlines.py`) measures each card at its shortest and longest.

---

## 1. Voidsworn Crusade: "The Oath at the Hollow Sun"

Crest: a cracked halo over a sword. Register: second-person liturgy, imperatives, call and response. Motif: the debt of names, chalked on the flagship's hull.

Charge: *Relight the beacon of the Hollow Sun, where the first oath-fleet burned. Do not come home without it.*

### Beat 1 (sector I): The Saint's Hand

Stand at the rail. Hear the charge. The litanists read it on every deck while the fleet holds station over Saint Vesper's moon. Before you sail, every captain chalks one name on the flagship's hull: the one they refuse to let be forgotten. {best_captain} writes first. [Prior loss: two captains write {fallen_name}, from the crusade that did not come home.] The confessors bring a second matter. {rival} came here before you. {rival_deed} {He} left the saint's iron hand on the altar, untouched, with a line cut into the stone beneath it: I will come back for this. The keepers beg you to carry the hand. The quartermasters want it sold before it draws {him} down on the fleet.

- **Carry the hand into battle.** Gain a relic: the saint's hand. {He} hears that it has moved: the Nemesis clock moves on one. (flag `vs_hand`)
  *The keepers wrap the hand in oilcloth and pray over the casket. Somewhere, {rival} is told.*
- **Sell it to the pilgrims.** +60 credits. The litanists strike your name from the Rite until it is earned back. (flag `vs_sold`, greed)
  *The pilgrims pay in coin that smells of incense. The keepers do not look at you again.*

### Beat 2 (sector II): The Tolling Bell

The hymn-ship Ashen Vigil drifts out of the dark, bridge gutted, her great bell still tolling on a dead man's timer. The bell-code carries the last jump routes to the Hollow Sun. {rival} hung her in your path and waits in the debris beyond. {rival_line} Hear the confessor: recover the code first, and give {him} the hours. Hear the captains: strike now, and let the bell toll for no one. [If you carry the hand: the casket has grown warm, and the crew call it a sign.] [If you sold it: the pilgrims' coin is spent, and the bell sounds as if it knows.] The oath allows no answer that is both swift and holy. Choose which sin you will confess.

- **Recover the bell-code.** The routes save fuel: +50 credits. {He} is ready for you: the clock moves on one. (flag `vs_code`, mercy)
  *The code comes aboard as a list of numbers and one prayer. The bell stops. Nobody likes the silence.*
- **Strike now.** Every captain gains 15 experience. (flag `vs_strike`, loud)
  *You fall on {his} pickets before they form. Behind you the bell goes on tolling for no one.*
- Blue, needs the hand: **Ring the bell with the hand.** Lose the relic: the hand cracks in the striking. The clock goes back two and every captain gains 15 experience. (flag `vs_rang`)
  *One stroke. The old bell answers across the whole sector. The hand comes back to you in pieces.*
- Blue, needs the sale: **Pay the pilgrims to toll it for you (40 credits).** They recover the code while you strike: every captain gains 15 experience. (flag `vs_pilgrims`)
  *The pilgrims climb aboard the dead ship with candles. They do not ask for your blessing. They do not need it.*

### Beat 3 (sector III): Relight the Hollow Sun

The Hollow Sun fills the viewports, a black coal ringed in slow fire, the first oath-fleet still circling it as bleached iron. {rival} waits among the wrecks. {rival_line} Read the hull: every chalk name is still there. [If you lost ships: the crews have chalked {first_lost} beside them.] [If you carry the hand: {he} asks for nothing but the hand.] [If you sold it: the pilgrims send one word on the open channel: Forgiven. It does not help.] [If the hand cracked: the pieces sit in a cloth on the bridge.] Call it across the fleet, and hear the crews answer. Who lights the dark? We do. Who pays for it? We do. The confessor says the beacon can be lit two ways. With a relic, as the saints did. Or with a reactor, as the desperate did. The crusade will remember which.

- **Light it with the hand** (needs the hand, whole). Lose the relic. Every ship repairs 25%. (flag `vs_lit_saint`)
  *You set the casket in the firing chamber with your own hands. The chalk names seem brighter. That is the fire.*
- **Light it with a reactor.** Your largest ship takes 25% hull damage. Every captain gains 25 experience: they would follow you into the star. (flag `vs_lit_reactor`)
  *The engineers weep as they rig the reactor. Then they cheer. Then they get back to work.*
- Blue, needs the sale: **Buy back your name (60 credits).** The litanists sing it again: every ship repairs 15%. (flag `vs_bought`)
  *Your name goes back into the Rite, one line lower than it was before.*

Win: *{rival}'s flagship breaks against the old cathedrals and falls into the star. The beacon catches on the third attempt, and the Hollow Sun throws a light for the first time in a thousand years.* + saint: *The saint's hand burns away in it; the litanists say she was waiting.* / reactor: *The ship that gave its reactor limps home dark, and the crews chalk a new name on her: yours.* / bought back: *The litanists add a verse. Your name is in it, near the end.*

Loss: *The chalk names burn with the hull.* + carried the hand: *The hand goes into the star with the fleet, and the beacon stays dark.* / sold it: *Somewhere the pilgrims light a candle with your coin. It is the only light the crusade leaves.*

---

## 2. Hegemony Navy: "Pacification Order 41"

Crest: a wedge in a ring of five stars. Register: documents, numbers, understatement. Motif: the quiet horror of being counted.

Charge: *Secure the Hollow Sun as a fleet anchorage. Losses within acceptable limits. Appendix attached.*

### Beat 1 (sector I): Listening Post K-7

The Admiralty's orders arrive sealed, numbered and without courtesy. Pacification Order 41. Losses are to be held within acceptable limits; the definition of acceptable is attached as an appendix of nine pages. [Prior loss: Order 41 has a previous holder. Their name has been blacked out of your copy.] A second packet concerns Listening Post K-7, fourteen crew, last report overdue. {rival} reached it first. {rival_deed} Intelligence has a file on {him} and nothing in it that helps. The Admiralty requests that you not pursue without authorisation. Your intelligence officer asks, quietly, whether you would like the post's black box recovered anyway, on your own authority and off the record.

- **Recover the black box, off the record.** It holds the post's last refit: gain a random refit. The salvage crew is seen: the clock moves on one. (flag `hg_offbook`)
  *The box comes aboard in a crate marked laundry. The fourteen names are on a single sheet. You read it twice.*
- **Follow orders to the letter.** Admiralty commendation: +50 credits. (flag `hg_orders`)
  *The commendation arrives within the hour. K-7 is entered as lost with all hands, in the correct format.*

### Beat 2 (sector II): Acceptable Limits

A Navy supply column, eleven haulers and one escort, has been driven onto the gravity shoals of sector II. {rival} holds the only exit and has not fired. {rival_line} The Admiralty signal is precise: the column is within acceptable limits; proceed to the objective. Your flag captain hands you a second message, from the escort's commander, a lieutenant of nineteen: we will hold as long as we can. [If you went off the record: the black box gave you {his} patrol pattern.] [If you followed orders: the commendation hangs on your wall, framed by someone with initiative.] To break through is to disobey. To leave is to follow orders, and watch eleven crews die on schedule.

- **Disobey and break them out.** The lieutenant forms on your flagship: a Hegemony picket joins with a veteran captain. No bonus, and the clock moves on one. (flag `hg_broke`, mercy, loud)
  *Eleven haulers and one battered picket fall in behind you. The Admiralty acknowledges receipt of your report. Nothing else.*
- **Proceed to the objective.** Admiralty bonus: +80 credits. (flag `hg_left`, greed)
  *The column's last signal is logged at 0340. Your flag captain initials the log and does not look up.*
- Blue, needs the black box: **Run {his} patrol gap.** The column lives and the picket joins, unseen: no clock. Every ship takes 10% hull damage in the gap. (flag `hg_broke`, mercy)
  *You thread {his} pickets at a distance the manual calls reckless. The lieutenant calls it the best flying she has seen.*
- Blue, needs the commendation: **File for an exception (spend the commendation: 50 credits).** Six haulers are reclassified as essential and saved: every ship repairs 15%. Five are not. (flag `hg_split`)
  *The exception is approved for six hulls, by number. The remaining five are informed of their status.*

### Beat 3 (sector III): The Anchorage

The Hollow Sun is exactly as cold as the survey said. {rival} has dug in among the shattered buoys at the anchorage mouth. {rival_line} Authorisation arrives eleven days late, stamped in triplicate. [If you broke the column out: a reprimand is attached, unsigned. The lieutenant's picket holds station off your bow and has not asked for orders.] [If you left them: the list from K-7 has eleven new names on it. Your flag captain added them, in the correct format.] [If you filed the exception: the list has five.] The guns are synchronised. The column is formed on your flagship. Your flag captain asks if there are orders beyond the obvious, and waits. There is one tradition no appendix governs. Before a decisive engagement a commander speaks to the whole line on an open channel, unrecorded. Every ship hears it. Nobody writes it down.

- **Read the names on the list.** Every captain gains 25 experience: the crews fight for the dead. (flag `hg_names`)
  *You read every name, rank and number. It takes four minutes. Nobody on the channel speaks for a fifth.*
- **Speak of duty.** Every ship repairs 20%: the crews go back to work. (flag `hg_duty`)
  *You say the Hegemony does not need them to be brave, only correct. Damage control teams are already moving.*
- Blue, needs the column: **Give the lieutenant the first line.** Every captain gains 15 experience and every ship repairs 10%. Her picket goes in first. (flag `hg_lt`)
  *She says eleven words, one for each hauler. Then the column forms on her, not on you, and you allow it.*

Win: *The anchorage is secured at 0412 ship time.* + names: *Your report runs to a single line, followed by the list. The Admiralty files it and then, without precedent, frames it.* / duty: *Your report runs to a single line. The Admiralty files it.* / lieutenant: *She is promoted. Nobody can find the paperwork that authorises it, and nobody looks.*

Loss: *Order 41 is marked incomplete. Within a month a new commander receives it, sealed, numbered and without courtesy.* + read the names: *The new copy has a list attached. Your name is at the bottom, in the correct format.*

---

## 3. Ashfall Corsairs: "Saints' Gold"

Crest: a skull with a gear for a jaw. Register: gallows jokes, people's names, money. Recurring face: Old Mott.

Charge: *A treasure fleet went down at the Hollow Sun. Get there first. Get rich. Get out.*

### Beat 1 (sector I): The Last Fence

Word in the Ashfall dens is that a treasure fleet went down at the Hollow Sun, a dead star where nobody sane goes. Old Mott swears his grandmother saw the manifests: crowns, reactor cores, a hold of saints' gold. Nobody believes him and everybody is going. You are going first, which makes you either clever or dead. [Prior loss: the dens say the last captain who went for the gold is still out there, frozen to the prize. Nobody says it to your face.] Before you clear the docks, word comes about your last fence. {rival} got to him. {rival_deed} The quartermaster wants to send a reply, with a bomb in it. The bosun wants a party. Both have a point.

- **Send a reply, rigged.** The dens open a book on you: +40 credits. {He} takes it personally: the clock moves on one. (flag `cs_rigged`, loud)
  *The parcel goes out with a bow on it. The odds the dens give on your survival are insulting.*
- **Throw the party.** The crews swear to the last scrap: every captain gains 15 experience. (flag `cs_party`)
  *Two days. Mott tells everyone about his grandmother, then about an auctioneer at Rattlehold, then cries.*

### Beat 2 (sector II): The Rattlehold Auction

The treasure fleet's black box is up for sale at Rattlehold, a rock full of thieves in sector II. Every crew with a ship and a grudge has come to bid. {rival} is not bidding. {His} fleet is parked off the rock, waiting to see who walks out with it. {rival_line} The bidding climbs. Your quartermaster counts what you have and goes quiet. The knife crews say steal it, start a riot, run under cover of the burning docks. The bosun says pay what it costs and owe nobody. Nobody has ever called the bosun honest before, and he looks uneasy about it. [If you threw the party: Mott recognises the auctioneer from his own stories, and is still ashamed of what he said.] [If you rigged the parcel: the whole rock has heard about the parcel.]

- **Steal it and burn the docks.** The box, and whatever else was on the clamps: gain a relic. Your next fight starts as an ambush. (flag `cs_stole`, greed, loud)
  *Rattlehold burns for a week. Three crews swear you started it. Two of them are right.*
- **Pay full price (80 credits).** Rattlehold remembers an honest buyer: a Corsair raider crew signs on with you. (flag `cs_paid`)
  *The bosun pays in counted coin. A raider captain watching from the bar says she has never seen that before, and asks for a berth.*
- Blue, needs the party: **Let Mott talk to the auctioneer.** The box for 30 credits, and the auctioneer tells Mott a weakness of {rival}'s. Your flagship captain loses 15 experience matching them drink for drink. (flag `cs_mott`)
  *They were married once, briefly. Neither will say more. Your flag captain cannot say anything at all until morning.*
- Blue, needs the parcel: **Remind the room about the parcel.** Nobody bids against you: the box for 20 credits. {He} hears about it: the clock moves on one. (flag `cs_feared`, loud)
  *You mention the parcel once, conversationally. The room finds other things to bid on.*

### Beat 3 (sector III): Saints' Gold

The treasure fleet is real. A dozen haulers hang in the Hollow Sun's cold glow, locked together by ice and old harpoon lines, holds still sealed. Old Mott is weeping openly. {rival} got here first and has chained {his} fleet to the wrecks, daring you to shoot through the prize to reach {him}. {rival_line} [If you burned Rattlehold: half your crews still smell of its smoke.] [If you paid: the raider crew keep asking when they get their share.] [Prior loss: between two haulers, in the ice, a familiar hull. The paint still reads {prior_flagship}.] The crews are counting shares out loud already, which is bad luck. The Ashfall rule says the winner sets the split. Tonight you set it before the fight, out loud. Mott wipes his eyes and asks what you are going to say.

- **Promise double shares.** Every captain gains 20 experience. They will hold you to it. (flag `cs_double`)
  *The cheer carries across three ships. The quartermaster quietly starts a second ledger.*
- **Promise nothing, and spend the war chest now (60 credits).** Patch crews on every hull: every ship repairs 25%. (flag `cs_nothing`)
  *Nobody cheers. Everybody gets to work. The quartermaster looks at you like you just proposed marriage.*
- Blue, needs Mott's auction: **Let Mott make the speech.** Every captain gains 10 experience and every ship repairs 10%. (flag `cs_mottspeech`)
  *Mott talks about his grandmother for nine minutes. By the end, the hard cases are crying too.*

Win: *The holds open on the fourth cutting torch.* + double: *The split takes three days and one hanging offence. Mott signs for his grandmother's share and has it framed.* / nothing: *Nobody cheers. Everybody counts. Then the quartermaster buys the first round with his own money, which has never happened.* / Mott: *His grandmother was right about the crowns and wrong about the saints. Nobody minds.*

Loss: *Your hull joins the treasure fleet in the ice. Some later crew will hear the legend and come looking.* + double shares: *The crews never collect. The dens still argue over who inherits the promise.*

---

## 4. The Chorus: "Eat the Sun"

Crest: a ring of nine open mouths. Register: "we", sentences under eight words, taste, heat, smell, teeth. Two throats argue in every beat: Hunger and Memory. The Chorus does not sing.

Charge: *Something warm at the Hollow Sun's core. Old meat. The first meat. Eat it.*

### Beat 1 (sector I): The Split Node

We wake hungry. Every throat, one want. Far off, the Hollow Sun. Dead outside. Warm inside. Old meat. The first meat. We eat it, or we forget how to be many. [Prior loss: we have been here before. We remember the cold.] The first night, we find a brood-node. Split open. The young inside untouched. Left to spoil. Nothing hunts like that. Nothing wastes like that. {rival} did this. {rival_deed} We taste the wound. Hunger says: eat the dead. Grow. Memory says: leave them. Keep the smell. Then we know what to chase. Two throats. One swarm. The swarm waits for you.

- **Eat the dead.** Every ship regrows 30% of its hull. Hunger grows louder. (flag `ch_ate`)
  *We eat. It tastes of {him}. Hunger purrs.*
- **Keep the smell.** We know where {he} goes: the clock goes back one. Memory grows louder. (flag `ch_smell`)
  *We leave them. The smell stays in every throat. Memory is pleased.*

### Beat 2 (sector II): The Warm Shallows

A sea world. Shallow. Warm. Full of drifting spawn. Unclaimed. Ours, once. {rival} has seeded the shallows with mines. {He} waits above. {rival_line} Hunger says: dive. Eat. Take the losses. Come out heavier. Memory says: feed the spawn. Our own flesh. They rise. They fight beside us. [If we ate the dead: Hunger is louder since the node. Memory is hard to hear.] [If we kept the smell: the smell is here. Fresh. {He} passed an hour ago.] The heat comes off the water in waves. The mines tick. Tick. The spawn turn toward us, mouths open. The small ones cry out. They are hungry, like us. The hunger has never had to choose before. It does not like it.

- **Dive and eat.** Every ship regrows 30% of its hull. {He} hears the feeding: the clock moves on one.
  *We dive. We eat. The mines take some of us. We eat those too.*
- **Feed the spawn our flesh.** Every ship loses 5% of its hull. A Chorus drone joins the swarm. (flag `ch_spawn`)
  *We open. They drink. One of them grows teeth before the tide turns.*
- Blue, needs the smell: **Follow the fresh smell.** Every ship takes 8% hull damage in the chase. We catch {his} pickets unready: a Nemesis weakness is revealed. (flag `ch_hunted`)
  *We run {him} down through the shallows. {His} pickets taste of fear. We learn where {he} is soft.*
- Blue, needs the eating: **Let Hunger lead.** Eat the mines too: every ship takes 10% hull damage, then regrows 40%. Memory goes quiet for the rest of the hunt. (flag `ch_hunger`)
  *We eat the mines. They burn. We eat the burning. Memory stops talking.*

### Beat 3 (sector III): Eat the Sun

The sun is warm. Every throat feels it. Heat on the hide. A hum under the static. A smell like the first night. {rival} stands in front of it, between us and the meat. {rival_line} We do not answer in words. The meat is close. We smell it through the dark. Old. Sweet. Ours. {He} smells of fear and metal. Both taste good. [If we fed the spawn: the small ones from the shallows swim at our flanks, furious.] [If Hunger leads: only Hunger speaks now. Memory is a scar.] [If we hunted {him}: we know {his} soft places by taste.] Hunger says: open every mouth. Eat it all. Now. Memory says: taste first. Learn {him}. Then eat. Nine mouths. One answer. The heat rises. We are very hungry.

- **Open every mouth.** Every ship regrows 20% of its hull. (flag `ch_end_hunger`)
  *Every throat opens at once. The sound is not a sound. {He} hears it anyway.*
- **Taste first** (not if Hunger leads). Every captain gains 25 experience. (flag `ch_end_memory`)
  *We taste the air {he} came through. We learn the shape of {his} fear. Then we move.*
- Blue, needs the spawn: **Send the small ones first.** Every ship regrows 10% and every captain gains 15 experience. The small ones will not come back. (flag `ch_end_spawn`)
  *They go laughing, if it is laughing. {His} guns turn to them. We go through the gap.*

Win: *We close over the dead star like a hand.* + Hunger: *We eat until nothing warm is left. We are bigger than we have ever been. We are still hungry.* / Memory: *We eat slowly. We learn what the first meat knew. Memory has a new voice now.* / the small ones: *None come back. The swarm keeps a hollow where they were.*

Loss: *The hunger goes quiet. In the cold, the warm thing at the core waits for the next mouth.* + Hunger led: *Hunger was the last throat to stop.*

---

## 5. The Ithar: "The Grave of Houses"

Crest: a single sail over a falling star. Register: memory and past tense, light and glass, long sentences; grief, with an archivist's fussy humour. Song belongs to the Ithar alone.

Charge: *Bring the light-archive home from the Hollow Sun before the short-lived break it open for scrap.*

### Beat 1 (sector I): The Lamp-Buoy

The Hollow Sun was a lamp once, when your house still had a name worth lighting. The elders have sent you to fetch its archive home, and have reminded you, twice, to bring the index as well. They have not named a child in four hundred years, so they are particular about what they keep. [Prior loss: the elders do not mention the last voyage. The youngest captains have been told not to ask.] On the first night a lamp-buoy older than any living Ithar wakes and hums a warning in a dialect your archivist has only read about. {rival} passed this way. {rival_deed} The buoy offers what is left of its song. Taking it would end it. Your archivist would very much like to take it.

- **Take its song.** It knows {his} route: the clock goes back one. The buoy goes dark. (flag `it_song`)
  *The buoy gives the song gladly, which is worse. Your archivist files it under irreplaceable and does not speak for an hour.*
- **Let it sleep.** Your captains carry its warning instead: every captain gains 15 experience. (flag `it_mercy`, mercy)
  *The buoy hums itself back to sleep. Your archivist sulks, makes a note, and then a second note.*

### Beat 2 (sector II): The Glass Choir

In sector II the voyage passes the Glass Choir, a field of crystal wrecks that were songships once and still ring faintly when starlight touches them. {rival} has made the field a trap: every wreck {he} breaks screams, and the screams blind your sensors. {rival_line} Your captains are young as the Ithar count it, barely four centuries, and some are weeping at their stations; the archivist is logging every scream, in tears, with exact timings. The oldest seraph sang in this choir when it was whole. She says the lament would quiet it, if you can spare the time. [If you took the song: the buoy's song rises in your throat; it knows this place.] [If you let it sleep: the buoy's warning was about this field, and your captains know the path.]

- **Sing the lament.** The captains steady: every captain gains 20 experience. {He} sees you coming: the clock moves on one. (flag `it_lament`)
  *The wrecks hear their own lament and go quiet, one by one. The archivist records the order.*
- **Go dark through the screaming.** Every ship takes 5% hull damage. You catch {him} unready: a Nemesis weakness is revealed. (flag `it_dark`, loud)
  *You sail blind through the screaming glass. When the sensors clear, you are close enough to see {his} seams.*
- Blue, needs the song: **Sing the buoy's song.** The wrecks fall silent at once: no damage, and the clock goes back one. The song is spent; the archive will not have it. (flag `it_spent`)
  *The field goes quiet in a single breath. Your archivist crosses one line out of the index, very neatly.*
- Blue, needs the warning: **Take the warned path.** Slow and safe: no damage, no clock, and every captain gains 10 experience. (flag `it_path`)
  *The path is exactly where the buoy said. The archivist adds a footnote crediting it.*

### Beat 3 (sector III): The Grave of Houses

The Hollow Sun is a black pearl wrapped in a halo of dead light. At its heart the archive waits, every house that ever sang, filed in an order only the dead understood. {rival} has reached it first. {rival_line} Your sails catch the last of the glow. [If the buoy's song is still in your archive: it would open the core without a fight at the gate.] [If you lost ships: the {first_lost} is not with you; you will have to explain that to the elders, in writing.] Every ship in this fleet is a line of a song that ends with it, and nothing is coming after you to sing the rest. The archivist asks, very politely, which you mean to save if you cannot save both: the archive, or the fleet.

- **Save the archive.** Send the oldest ship ahead to open the core: one of your ships takes 25% hull damage. Every captain gains 25 experience. (flag `it_end_archive`)
  *The oldest ship lowers its shields and sails into the light. The archive answers it by name.*
- **Save the fleet.** The archive has waited an age; it can wait an hour. Every ship repairs 20%. (flag `it_end_fleet`)
  *You hold the line at the gate. The archivist says nothing, loudly.*
- Blue, needs the buoy's song: **Play the buoy's song to the core.** The song is spent: every ship repairs 10% and every captain gains 15 experience. (flag `it_end_buoy`)
  *The core opens to an old song like a door to a key. The buoy, wherever it is, would be pleased.*

Win: *The archive wakes in your hands like a held breath.* + archive: *On the voyage home your youngest captain learns a song nobody has sung in nine thousand years, and sings it badly, and the elders weep.* / fleet: *You bring every ship home. The elders receive the archive with polite disappointment and file your report under unusual.* / buoy: *The buoy's song goes back where it came from. The archivist writes returned in the margin and underlines it.*

Loss: *The last sail folds. The archive keeps its silence, and the Hollow Sun keeps the archive.* + saved the archive: *The oldest ship is still at the core with its lights on, guarding a door nobody will open.*

---

## 6. The Deathless: "The Court Restored"

Crest: a crowned eye over a sealed vault door. Register: law and record, polite contempt, no feeling words. Motif: a debt the Court cannot forgive.

Charge: *The first Court sleeps in its vault beneath the Hollow Sun. Clear the processional route. Resume the session.*

### Beat 1 (sector I): The Broken Seal

We wake by writ, rank by rank, as the law prescribes. The record lists what was lost in the long sleep: three sectors of the old holdings, occupied by the living, and beneath the Hollow Sun the vault of the first Court, its session adjourned ten thousand years ago. The session will resume. The occupants will be corrected. [Prior loss: the record notes a previous attempt. It does not note your name. That is a courtesy.] One entry troubles the record. A vault at the edge of the first sector was opened before your arrival, its warden dismantled with care, and his seal of office taken. {rival} did this. {rival_deed} The wardens request a writ of pursuit. The archivists recommend patience. The law permits either. It forgets neither.

- **Issue the writ of pursuit.** The legions are honed for it: every captain gains 20 experience. {He} sees you hunting: the clock moves on one. (flag `dd_writ`, loud)
  *The writ is read to the legions. It names {rival}, the hour of the offence, and the penalty. The penalty is very old.*
- **Be patient.** The vault's foundries mend the fleet while the archivists read what {he} left: every ship rebuilds 15%. (flag `dd_patient`)
  *The archivists take the warden's remains to a quiet room and read them like a ledger.*

### Beat 2 (sector II): A Seal on the Wrong Hand

In sector II the stolen seal surfaces, displayed by {rival} to every occupied world in range. {rival_line} Below your fleet lies a second vault, its legions sleeping, a reserve the law says may wake only to defend the Court in session. Waking it would bring more hulls to the field. It would also break a law older than most stars, and the Court will rule on it when it wakes. [If you were patient: the archivists have finished reading the warden, and they know where the seal's maker hid a flaw.] [If you issued the writ: it has been answered; {rival} has entered your name in {his} own list.] The Court cannot forgive a broken law. It cannot forgive a stolen seal. It has never been asked to choose.

- **Wake the reserve.** A Deathless jackal joins the fleet. The law is broken, and the clock moves on one. The Court's honour guard will not wake for you. (flag `dd_broke`)
  *The vault opens. The legions rise, read the date, and enter themselves in the record as irregular.*
- **Keep the law.** Nothing now. The Court will know. (flag `dd_lawful`)
  *You leave the vault sealed. The archivists note the restraint, and the date, and the reason.*
- Blue, needs patience: **Trigger the seal's flaw (costs a refit from the hold).** {He} is shamed before {his} fleet: a Nemesis weakness is revealed and the clock goes back one. (flag `dd_flaw`)
  *The seal cracks across {his} broadcast, mid-sentence. Every occupied world in range sees it.*

### Beat 3 (sector III): The Court Restored

The Hollow Sun turns overhead, black and enormous, its corona long since gone to ash. Beneath it the first Court waits for its session, and {rival} has drawn up across the processional route as if {he} had standing to be there. {rival_line} Your fleet takes the old formation without being ordered. The record finishes its count: every warden, every seal, every trespass, entered and weighed. [If you woke the reserve: the reserve stands at the formation's edge, listed as irregular. The rest of the fleet does not stand beside it.] [If you kept the law: the vault's honour guard has woken on its own and asks, formally, for its place in the line.] The law of reclamation is simple. The guns charge. The clerks wait. The question is what you will enter in the record first.

- **Enter a sentence of erasure.** No quarter, no record of {him}. Every captain gains 25 experience. (flag `dd_erase`)
  *The clerks prepare a blank line in the record, and wait to fill it with nothing.*
- **Enter a summons.** {He} will be tried before the Court, alive. Every ship rebuilds 15%. (flag `dd_summons`)
  *The summons is transmitted to {his} flagship, politely, with the date of the hearing.*
- Blue, needs the law kept: **Give the honour guard its place.** A Deathless scythe joins the fleet. (flag `dd_guard`)
  *The honour guard takes position at your flank. It does not acknowledge you. It acknowledges the law.*

Win: *The processional route is cleared. The Court rises and takes its seats, one by one, in perfect silence.* + erasure: *The record enters a blank where {rival}'s name was. The Court approves of the blank.* / summons: *{rival} is entered as the first case of the new session. The hearing is expected to take several centuries.* / reserve woken: *The Court's first ruling concerns the reserve you woke. It is forty pages long, and every page says the same word.*

Loss: *Your fleet returns to the dust it came from. The record notes the setback; it has noted setbacks before.* + reserve woken: *The Court never rules on the reserve. The debt stays open, which is worse.*

---

## Table A: the rival's calling card, `{rival_deed}` (his faction x his personality)

One sentence, written to fit any beat 1 that says "{rival} did this" or "{rival} got to him". Pronouns follow the generated commander. Personality ids are the proposal sent to stream B (R42).

| His faction | proud | cruel | cunning | zealous | cold | mocking |
|---|---|---|---|---|---|---|
| Voidsworn | {He} left a formal challenge nailed to the door, signed with {his} full name and every title. | {He} burned everything but one thing, so you would know it had been chosen. | {He} left the place untouched, except for a sermon on the comms that loops your name. | {He} declared the ground blessed and everyone on it a sinner. | {He} left a judgement, three lines long, with your name on the third. | {He} left an indulgence pardoning you in advance, for dying. |
| Hegemony | {He} left a notice of claim, numbered and countersigned. | {He} lined up what was left so it spelled {his} name. | {He} left a forwarding address that is a trap, and a polite note saying so. | {He} raised the Hegemony flag over it and saluted the empty hall. | {He} left an inventory of what was taken, and when {he} will return for the rest. | {He} left a bill, itemised, with a late fee. |
| Corsair | {He} painted {his} name over the door, very large, and spelled it right for once. | {He} took everything, then came back for the bolts. | {He} left a cut of the take behind, with your name on it, which is worse than a threat. | {He} swore an oath to the loot gods over the wreckage. | {He} took exactly what was worth taking, and nothing else. | {He} left a thank-you card. |
| Chorus | It ate everything but the bones, and stacked the bones neatly. | It ate slowly, so the rest could watch. | It left the doors open and the food out, and waited to see who came. | It fed in a perfect ring, facing inward, like a prayer. | It ate what it needed, and not one mouthful more. | It left one bite missing from everything. |
| Ithar | {He} left a single line of verse, flawless, in a language nobody living reads. | {He} stayed long enough for everything there to forget its own name. | {He} left everything exactly as it was, minus one thing nobody noticed for a week. | {He} lit a mourning lamp, for you, in advance. | {He} took nothing, and left a note of what {he} had chosen not to take. | {He} corrected the spelling on every sign, and left. |
| Deathless | {He} entered {his} claim in the record above yours. | {He} kept the defenders, and they are still in the record as {his}. | {He} filed a claim to the place a thousand years ago, and waited. | {He} recited the law of reclamation over it and called it a sentence. | {He} catalogued the place, and left the catalogue on the door with your name on the last page. | {He} left the warden standing, facing the door, with a guest book. |

## Table B: the rival's beat 3 hail (what the Hollow Sun means to him, and what he remembers)

Picked in this order: **remembers** (you beat him before, or he carries scars), **mercy** (your choices leaned merciful), **ruthless** (they leaned greedy or loud), else **the Sun to him**. More lines per moment live in rival_lines.json.

| His faction | The Sun to him | Remembers | Mercy | Ruthless |
|---|---|---|---|---|
| Voidsworn | "That coal is a reliquary and I am the last priest it has. Your hands are not clean enough to light it." | "You marked me {scars}. I kept every scar for this altar." | "You spared the weak on your way here. The saints call that pride." | "You came here with stolen coin and burning wakes. At least you will match the place." |
| Hegemony | "The survey says this anchorage holds nine fleets. It will hold one. Stand down and be counted." | "Our last engagement has been reviewed. The review recommends your removal." | "You stopped for stragglers. I read the report. I would not have." | "You left people behind for a bonus. I read that report too. We should not both be here." |
| Corsair | "Got here first, so it's mine. That's the whole law out here. Say hello to my chains." | "Last time you got lucky. I had the dents framed. Come and add one." | "Heard you went soft on the way in. Good. Soft ships open easy." | "Heard you burned your way here. Respect. Still mine, though." |
| Chorus | "It is warm in our mouths already. You are the part in the way." | "We remember the taste of you. We want the rest." | "You leave food on the plate. We do not." | "You eat like us. Good. We will eat you like us." |
| Ithar | "This was my house's lamp before your people learned fire. I came to see it put out properly." | "You scarred me {scars}. I had not been scarred in nine centuries. I have been thinking about you." | "You let an old thing sleep, once. That was kind. It will not save you." | "You broke old things to get here. Then we are alike, and I am sorry for you." |
| Deathless | "I held this ground before your kind had a word for sun. Kneel, and be entered as a guest." | "You delayed me. Delay is all the living ever manage." | "Your restraint is noted. It is not a defence." | "You broke laws to reach this place. The record has you down for each one." |

## Cross-run callbacks (from the Chronicle)

- Prior loss with this faction: each beat 1 carries a bracket line (above). Corsair beat 3 can show the last lost flagship frozen in the ice (`{prior_flagship}`); Voidsworn captains chalk `{fallen_name}` from the Hall of the Fallen.
- Prior win with this faction: a one-line nod in beat 1 instead (in the variants file).
- After an arc has been finished twice, its cards offer the skim version first (variants file), with "Read in full" one click away.
- A rival who beat you last run may come back (stream B's call): his beat 1 deed is replaced by "{rival} has broken a fleet of yours before. {He} has not forgotten, and neither have the crews."

## Word counts

Checked by `godot/story/test/check_outlines.py`: every card is at least 100 words without its conditional lines and at most 150 with its two longest, counting tokens at the length they render; no em dashes; skim cards 40 words or fewer.
