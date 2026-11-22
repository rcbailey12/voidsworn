# Embers of the Hollow Sun: six faction story arcs

Status: **human-voiced rewrite aligned with the Nov 21 2026 narrative, space-first, and IP audits** (`contrib/opus/compute/lore_bible_r8.md`). Three beats per faction, the rival is the run's Nemesis, every choice is read again later, beat 3 is a story decision with a cost, finishing an arc pays a cosmetic reward and a hull unlock (`unlocks.md`), and every faction's road ends at the Hollow Sun.

Companion file: `outlines_variants.md` holds a second version of every beat, the short "skim" cards for later runs, and the shared rival incidents.

Flag ids (`vs_hand`, `hg_offbook`, `cs_party`, `it_song`, `dd_writ` and the rest) are kept intact so nothing downstream has to change.

## What each faction wants at the Hollow Sun

| Faction | Arc | Why they go sunward |
|---|---|---|
| Sunward Crusade | The Oath at the Hollow Sun | Burn out the siphon relay stealing the Vesper Reach's light. |
| Meridian Directorate | Registry Order 41 | Secure the Hollow Sun orbital perimeter and catalog the surviving Lattice cores. |
| Ashfall Hullbreakers | Rook's Trail | Track down R-5 Rook in the wreck field and claim it: strongest keeps it. |
| The Chorus | Consume the Cores | Devour the surviving Lattice cores at Ardent's rim and finish the war Memory recalls. |
| The Glasswrights | The Last Lens | Recover the Lattice's last primary lens before Eclipse mounts it on a stolen star. |
| Eclipse | The Homecoming | Bring the remaining cores home and ignite Ardent's successor at the system's core. |

## How an arc works

- Three beats, one per sector, each a 100 to 150 word card with a choice. A one-line charge sits above beat 1.
- Every option shows its effect up front and gives one outcome sentence after the click.
- Effects used: credits, repairs, experience, salvage (the item type), a ship joining, a refit, hull damage, the Nemesis clock, one weakness reveal per arc at most, an ambush. Every choice writes a flag and may add to the shared counters stream B reads (mercy, greed, loud).
- Beat 3 is shown as sector III begins; the arc closes on the result of the sector III fight. Winning finishes the arc: medal, Chronicle entry, arc title, flagship paint, hull unlock. A win where the rival escapes still finishes the arc and adds one line in your faction's voice:
  - Sunward Crusade: *{rival} slipped clear into the dark. Chalk {his} hull code under the line.*
  - Meridian Directorate: *{rival} withdrew in good order. The dossier remains open.*
  - Ashfall Hullbreakers: *{rival} broke clamps and ran. We have {his} transponder signature now.*
  - The Chorus: *{He} fled into the cold. Our spores keep {his} drive signature.*
  - The Glasswrights: *{rival} withdrew along the glare line. There will be another pass.*
  - Eclipse: *{rival} broke contact. The Archive holds {his} last vector.*
- `[brackets]` are lines that show only when their condition holds; at most two show on a card. The checker (`godot/story/test/check_outlines.py`) measures each card at its shortest and longest.

**What a Chronicle entry records** (Career screen): the faction and arc, the rival's full name and faction, the three choices in their own words, whether you won, your first lost ship, and the title earned that run.

---

## 1. Sunward Crusade: "The Oath at the Hollow Sun"

Charge: *Push sunward, burn out whatever's draining Vesper's stars, and make sure the people who paid for the jump aren't forgotten.*

### Beat 1 (sector I): The Ember Shard
Your fleet holds orbit over Vesper's outer belt, where the core Seren drifted after the collapse and gave the Reach its first real plasma coils. Before the jump clocks hit zero, every captain chalks one name on the flagship's outer hull so nobody gets erased like Meridian erased the Reach. {best_captain} steps up first. [Prior loss: two captains chalk {fallen_name} from the last expedition lost.] Then the belt wardens hail with worse news: {rival} hit their forge station six hours ago. {rival_deed} They left one warm shard of Seren's casing sitting untouched on the loading bay, like a dare. The wardens want it carried sunward; your quartermasters want it sold before it pulls {rival} straight onto your wake.

- **Carry the shard sunward.** Gain salvage: the ember shard. {rival} tracks its thermal ping: Nemesis clock moves on 1. (flag `vs_hand`)
  *The wardens seal the warm shard inside a lead quench-box and bolt it into your flagship's bay.*
- **Sell it to the foundries.** +60 credits. The wardens scrape your name off the hull until you earn it back. (flag `vs_sold`, greed)
  *The foundry transfers hard credits within ten minutes. None of the belt wardens wave as you break orbit.*

### Beat 2 (sector II): The Dawn Horn
A shattered bastion from an older crusade tumbles out of the dark, its hull frozen solid while an automated dawn-watch beacon still broadcasts jump coordinates toward the Hollow Sun on an emergency battery. {rival} towed the wreck straight across your lane and waits behind the debris field. {rival_line} Your signals officer says pulling the full route table will buy clean lanes, though sitting still gives {him} time to form up. Your captains want to burn in hard right now and skip the codes. [If you carry the shard: Seren's casing is pulsing hot inside the bay, and {rival}'s scopes already have it tagged.] [If you sold it: the foundry money's spent, and {rival} just beamed a mocking receipt across open comms.] Every chalked name on that frozen bastion is still readable through the ice.

- **Pull the route codes.** Clean jump paths save fuel: +50 credits. {He} tightens {his} screen while you wait: clock moves on 1. (flag `vs_code`, mercy)
  *The coordinates finish downloading right as the bastion's dying battery finally cuts out.*
- **Burn in now.** Every captain gains 15 XP. (flag `vs_strike`, loud)
  *You hit {his} outer pickets mid-turn while the dead bastion keeps broadcasting into empty space behind you.*
- Blue, needs the shard: **Overcharge the beacon with Seren's shard.** Lose salvage; the shard cracks inside the dead reactor, yet the blast jams {his} grid: clock goes back 2 and every captain gains 15 XP. (flag `vs_rang`)
  *The surge blasts clean route tables across the whole sector and scrambles {his} pickets before the shard splits cold.*
- Blue, needs the sale: **Hire a belt salvage cutter to pull the codes (40 credits).** They cut the drive loose while you attack: every captain gains 15 XP. (flag `vs_pilgrims`)
  *The belt cutters weld onto the frozen hulk under fire and copy every crew name off its flank before jumping out.*

### Beat 3 (sector III): Break the Siphon
The Hollow Sun fills your forward viewports, a black disc wrapped in slow orange plasma while a dozen shattered expeditions from earlier generations drift around its gravity rim. Anchored right against the inner edge hangs Eclipse's siphon relay, pulling a thin blue-white ribbon of stolen stellar energy straight out of Vesper's dying stars. {rival}'s fleet forms directly across the only clean approach vector. {rival_line} [If the shard jammed {his} grid: {his} escorts are still struggling to hold interval after that sector-wide surge.] [If not: {rival} loops the dead bastion's crew roll across your bridge speakers.] [If you carry the shard: {he} hails once, demanding the casing.] [If you sold it: {he} broadcasts your foundry sale receipt on open fleet comms.] [If you lost ships: your crews already chalked {first_lost} onto the flagship flank.] Your gunners run final radiator checks while the bridge goes quiet. Either Seren's charge burns that relay straight down to slag, or your largest ship overdrives its own reactor past every safety limit.

- **Burn the relay with Seren's shard** (needs shard intact). Lose salvage; every ship repairs 25%. (flag `vs_lit_saint`)
  *You lock the quench-box into the firing chamber yourself, letting Seren's fire do the work your crews can't.*
- **Overdrive your flagship's reactor.** Largest ship takes 25% hull damage; every captain gains 25 XP. (flag `vs_lit_reactor`)
  *Engineering curses nonstop while bypassing the thermal safeties, then yells over comms when the surge holds.*
- Blue, needs the sale: **Buy back your standing (60 credits).** You wire supply credits back to the belt wardens: every ship repairs 15%. (flag `vs_bought`)
  *Your name goes back onto the flagship hull, one row lower than before, yet back on the line.*

---

## 2. Meridian Directorate: "Registry Order 41"

Charge: *Secure the Hollow Sun orbital perimeter and catalog all surviving Lattice cores. Projection: favorable. Attrition: acceptable.*

### Beat 1 (sector I): Listening Post M-14
Your sealed dispatch arrives after the standard two-note chime: Registry Order 41, accompanied by an eight-page appendix defining acceptable casualty limits for this deployment. [Prior loss: Order 41 previously belonged to another commander whose serial has already been closed out of your copy.] Attached is a secondary notice regarding Listening Post M-14, fourteen personnel, telemetry overdue by six hours. {rival} reached the station first. {rival_deed} Meridian's projection classifies an unscheduled detour as suboptimal and instructs you to proceed directly along the primary lane. Your intelligence officer switches her cortical link off for ten seconds and asks quietly whether you want to recover M-14's encrypted black box on your own authority.

- **Recover the black box off the record.** Gain a random refit from the station's locker. The detour trips local relays: clock moves on 1. (flag `hg_offbook`)
  *The black box arrives inside a crate labeled galley stock, taped beside a handwritten list of fourteen names.*
- **Execute Order 41 strictly.** Registry compliance bonus: +50 credits. (flag `hg_orders`)
  *Meridian transfers the commendation within the hour and closes M-14's personnel ledger cleanly.*

### Beat 2 (sector II): Acceptable Limits
A Directorate bulk supply column, twelve freighters and one battered picket, has been herded against a dense gravity shoal along the outer lane. {rival} seals the only safe jump exit and hasn't fired yet. {rival_line} Meridian's directive is unambiguous: the convoy's replacement cost falls within projected tolerances; stay on schedule. Then your flag captain hands over a raw unlinked hail from the picket's nineteen-year-old lieutenant promising to hold the shoal as long as her shields last. [If you recovered the black box: M-14's logs contain {his} patrol timing, and {he} knows the drive is missing.] [If you obeyed Order 41: {rival} bounced a copy of your compliance bonus straight onto your bridge display.] Breaking them out means overruling the Registry in front of every linked officer in your column.

- **Overrule the Registry and break them out.** A Directorate picket with a veteran lieutenant joins your fleet. No bonus, and clock moves on 1. (flag `hg_broke`, mercy, loud)
  *Twelve freighters slip clear behind your guns while the Registry logs your breach of orders without a single word of comment.*
- **Stay on schedule.** Meridian efficiency allocation: +80 credits. (flag `hg_left`, greed)
  *The picket's transponder cuts out at 0340. Your flag captain signs the shift log without looking up.*
- Blue, needs the black box: **Slip through {his} patrol gap.** The convoy escapes and the picket joins cleanly with no clock advance; every ship takes 10% hull abrasion cutting the rocks. (flag `hg_broke`, mercy)
  *You thread the gravity ridge at tolerances the Directorate manual prohibits, and the young lieutenant calls it the cleanest flying she's ever watched.*
- Blue, needs the compliance bonus: **File a priority exception (50 credits).** Six haulers are reclassified as essential and towed clear: every ship repairs 15%. Five are left behind. (flag `hg_split`)
  *Meridian approves salvage coverage for six hull numbers and transmits a formal closure notice to the remaining five.*

### Beat 3 (sector III): The Orbital Perimeter
The Hollow Sun turns cold and immense ahead of your bow, its outer orbital perimeter ringed with shattered Meridian survey beacons from earlier probes. {rival} holds the primary approach lane between two dead relay buoys, weapons already hot on your jump vector. {rival_line} [If you rescued the convoy: somebody leaked your formal reprimand to {rival}, who transmitted it back covered in red marks.] [If you left them: {rival} painted the lost freighters' hull codes across {his} flagship flank.] Meridian's formal engagement authorization finally arrives six days late, stamped with an exact casualty forecast to the nearest hull. [If you rescued them: the lieutenant's picket locks neatly onto your port bow without waiting for orders.] [If you left them: your flag captain quietly added twelve names to M-14's paper sheet.] Synchronized fire clocks lock green across the entire column. Before a decisive engagement, Directorate commanders hold one custom Meridian never records: switching off every cortical link for sixty unlogged seconds.

- **"Name, rank, and hull number. Every single one."** Read the paper list aloud. Every captain gains 25 XP. (flag `hg_names`)
  *Reading every name takes three full minutes, and nobody turns their link back on until you finish.*
- **"Check your firing solutions and hold spacing."** Keep it strictly professional: every ship repairs 20%. (flag `hg_duty`)
  *Damage-control crews double-check every seal before you finish speaking, steady and calm.*
- Blue, needs the convoy saved: **Hand the unlogged minute to the lieutenant.** Every captain gains 15 XP and every ship repairs 10%. (flag `hg_lt`)
  *She names every freighter that made it home, then nudges her battered picket straight to the front of your column.*
- Blue, needs Order 41 followed (and bonus unspent): **Call in your compliance credit (40 credits).** Meridian dispatches a fresh Directorate picket with a veteran officer. (flag `hg_support`)
  *The reinforcement drops out of jump alongside a digital receipt requiring your immediate signature.*

---

## 3. Ashfall Hullbreakers: "Rook's Trail"

Charge: *R-5 Rook's pulsing somewhere inside the Hollow Sun wreck field. Track it down, crack whoever's guarding it, and keep it.*

### Beat 1 (sector I): The Torn Den
Word across the Ashfall dens says the core R-5 Rook has started pinging from the wreck belt around the Hollow Sun, throwing a steady thermal tick where no live reactor should sit. Old Mott swears whoever bolts Rook into their flagship won't ever lose a fight again, though Mott says something like that after every third bottle. Either way, half the belt's spinning up drives, so you jump first or pick through someone else's scraps. [Prior loss: gossip in the dock bars says the last pack that chased Rook is still welded into the ice near the rim.] Before you clear orbit, word hits that {rival} raided your forward fuel depot. {rival_deed} Half your captains want to send back a booby-trapped trophy crate; the rest want a loud pre-hunt brawl and feast first.

- **Send a rigged trophy back.** The dock bookies start taking bets on your pack: +40 credits. {rival} takes it personally: clock moves on 1. (flag `cs_rigged`, loud)
  *The charge goes out bolted inside a stolen hull plate, and the odds Rattlehold posts on your survival are flat-out insulting.*
- **Throw a loud pre-hunt feast.** Every captain gains 15 XP. (flag `cs_party`)
  *Two loud days of brawling where Mott brags about his eighth challenger, slips up mentioning an old Rattlehold broker, and passes out on a cargo crate.*

### Beat 2 (sector II): The Rattlehold Auction
The full wake-log mapping Rook's drift sits inside Rattlehold, the meanest rock-den in sector II, and the den-boss holding it will hand it over to whoever pays top scrap or breaks his champion. Every pack with two guns and a grudge packed the docks. {rival} didn't bother coming inside; {his} fleet hangs cold off the outer rocks waiting to jump whoever walks out with the chart. {rival_line} Your breach gangs want to smash the docking bays and run dark under the chaos. Your quartermaster says pay the scrap price clean and avoid starting a three-way war. [If you feasted: Mott already knows the broker keeping the log and looks distinctly uncomfortable about it.] [If you sent the rigged crate: word of it kept {rival}'s escorts holding extra distance.]

- **Smash the docks and snatch the log.** Grab the chart plus loose hardware on the clamps: gain salvage. Your next fight starts as an ambush. (flag `cs_stole`, greed, loud)
  *Rattlehold's outer bays burn for four days, and three rival packs put bounties on your hull before the smoke clears.*
- **Pay the asking price (80 credits).** Paying fair at Rattlehold turns heads: a Hullbreaker raider crew signs onto your pack. (flag `cs_paid`)
  *Your quartermaster dumps counted scrap straight onto the counter, and an impressed raider captain asks to fly on your flank.*
- Blue, needs the feast: **Send Mott in to lean on the broker.** You get the log for 30 credits plus a Nemesis weakness; your flagship captain loses 15 XP to a brutal hangover. (flag `cs_mott`)
  *Mott and the broker ran the same belt twenty years back, and whatever they drank settling old business leaves your flag captain useless till morning.*
- Blue, needs the rigged crate: **Remind the hall what happened to your last rival.** Nobody bids against you: get the log for 20 credits, though word reaches {rival}: clock moves on 1. (flag `cs_feared`, loud)
  *You drop one scorched rivet on the table, and every rival captain suddenly remembers an urgent hull repair.*

### Beat 3 (sector III): Strongest Keeps It
Rook isn't dock-bar gossip after all. Out along the Hollow Sun's frozen debris ring, a ship-sized Starwright core spins slowly among cracked cruisers, glowing red-hot under a thick crust of rime. Even Old Mott shuts up when the thermal scope image sharpens on screen. {rival} beat you to the wreck belt and anchored {his} escorts straight around the core's casing, daring you to chew through the prize to get at {him}. {rival_line} [If {rival} lost face back at Rattlehold: every den knows it, and {he} fights like someone with something to prove.] [If {he} let you buy the chart cleanly: {he} wanted you to drag the map straight here.] [If you torched Rattlehold: your hulls still carry scorch streaks from the dock fight.] [Prior loss: half-buried between two wrecks sits {prior_flagship}, frozen dark.] Your captains are already snarling over loot shares and breach order; settle how this pack fights before the burn starts.

- **"Every claw gets a fair cut, and nobody shoots the core."** Fight wide around the wrecks: every captain gains 20 XP. (flag `cs_double`)
  *A ragged roar rolls across fleet comms while your quartermaster starts sharpening a new tally slate.*
- **"Shoot straight through the wrecks if they hide behind it!"** Strip spare plate off the outer debris first: every ship repairs 25%, though Rook takes hard hits. (flag `cs_through`)
  *Nobody cheers, yet the weld gangs pull fresh armor off the dead hulls fast while Mott curses under his breath.*
- Blue, needs the feast: **Give Mott the open band.** Every captain gains 10 XP and every ship repairs 10%. (flag `cs_mottspeech`)
  *Mott spends six filthy minutes comparing your enemies to the forty idiots who tried taking his chair, and half the pack is laughing by launch.*

---

## 4. The Chorus: "Consume the Cores"

Charge: *Five hot Lattice cores orbit the Hollow Sun. Memory still recognizes Ardent's ruins; Hunger intends to devour them.*

### Beat 1 (sector I): The Split Node
We wake starving across every chamber. Far ahead, Ardent's black hole holds five glowing cores that pulse straight through our sensory pits. Memory still recognizes that dead star from when our Fleshwright makers had hands and walked under its light. [Prior loss: our outer spores still carry the cold shock of an earlier brood failing on this lane.] On the first jump we find a severed Chorus nursery node sliced neatly open, its young left unconsumed to freeze in hard vacuum. Nothing living wastes good biomass like that. {rival} cut it open. {rival_deed} Hunger wants us to swallow the dead tissue immediately and thicken our hides. Memory wants us to sample the weapon residue and track {his} drive-burn instead. Two drives pull inside one swarm; choose which leads.

- **Consume the dead node.** Every hull regrows 30%. Hunger grows louder inside the swarm. (flag `ch_ate`)
  *We draw the frozen tissue back into our sacs, tasting the scorch of {his} weapons as the hides thicken.*
- **Sample the weapon trace and leave the dead.** Tracking {his} burn signature slows {his} ambush: clock goes back 1. Memory sharpens. (flag `ch_smell`)
  *We map the exact isotope trail left by {his} drives and slip cleanly onto {his} wake.*

### Beat 2 (sector II): The Warm Shallows
An oceanic moon turns warm beneath a low cloud deck, its shallow seas crowded with dormant Chorus spawn left over from an older migration. {rival} has seeded the orbital cloud layer with proximity mines and hangs waiting above the gravity well. {rival_line} Hunger urges us to dive straight through the blasts, gorge on the drifting biomass, and climb back heavier. Memory pushes us to feed our own cells down to the spawn so they mature fast and rise into orbit beside us. [If we consumed the dead node: Hunger's surge lit our thermal trail bright, and {he} packed the densest mine cluster right over the thickest spawn.] [If we mapped {his} trace: {his} picket engines are still hot from laying the grid an hour ago.] The young pulse upward through the water, waiting.

- **Dive and feed.** Every hull regrows 30%. {He} reads the massive thermal spike: clock moves on 1. (flag `ch_dove`, loud)
  *We drop straight through the mine detonations, swallowing fragments of steel and warm spawn alike.*
- **Seed the spawn with our own tissue.** Every hull sheds 5% mass; a fresh Chorus drone-spawn rises to join the swarm. (flag `ch_spawn`)
  *Our membranes split open over the warm tide, and a new brood-hull climbs into vacuum minutes later.*
- Blue, needs the tracked trace: **Cut off {his} mine-laying pickets.** Every hull takes 8% abrasion skimming atmosphere, yet we catch {his} flank off guard and expose a Nemesis weakness. (flag `ch_hunted`)
  *We surge out of the cloud cover behind {his} pickets and learn exactly where {his} shielding runs thin.*
- Blue, needs the dead node consumed: **Give full control to Hunger.** Every hull takes 10% mine damage, then regrows 40%. Memory goes silent for the rest of the run. (flag `ch_hunger`)
  *We swallow mines, burning plasma, and spawn together until the makers' old voices drown completely under raw appetite.*

### Beat 3 (sector III): Consume the Cores
Ardent's dead halo burns hot across every sensory pit as five surviving Lattice cores circle the black hole's gravity rim, pouring radiation straight through the cold dust. Memory whispers the star's old name one last time from deep inside our neural tissue while Hunger swells against our outer ribs. {rival} walls off the final orbit between our swarm and the cores, weapons fully charged. {rival_line} [If we ambushed {his} pickets: {his} command hull still carries fresh acid scars from the ocean moon.] [If not: {he} stripped our unguarded spawn-fields clean before jumping here.] We answer {his} comms hail only with rising thermal static and shifting spore clouds. [If Hunger silenced Memory: only raw predation guides the swarm now.] [If we raised the ocean spawn: the new brood-hulls dart eagerly along our flanks.] Hunger demands an immediate all-out surge; Memory urges one measured pass to read {his} weak seams first.

- **Surge with every brood at once.** Every hull regrows 20%. (flag `ch_end_hunger`)
  *Every propulsion sac flares simultaneously, turning the approach lane into a storm of acid and spores.*
- **Read {his} firing pattern first** (locked if Hunger silenced Memory). Every captain gains 25 XP. (flag `ch_end_memory`)
  *Memory matches {his} formation spacing against Fleshwright war-logs, pinpointing every blind arc before we strike.*
- Blue, needs the ocean spawn: **Send the young brood-hulls straight into {his} forward guns.** Every hull regrows 10% and every captain gains 15 XP. The young won't survive. (flag `ch_end_spawn`)
  *The newly hatched hulls rush straight into {his} main batteries, tearing a clean gap for our heavy broods to follow.*

---

## 5. The Glasswrights: "The Last Lens"

Charge: *Recover the Lattice's last primary lens from the Hollow Sun before Eclipse bolts it onto a stolen star.*

### Beat 1 (sector I): The Mirror-Buoy
The black hole ahead used to be Ardent, and your grandmothers polished the collectors that harvested its light before Eclipse killed the star. The Lens-keepers sent you to recover the last intact primary lens before your uploaded siblings seize it, and reminded you twice to bring its gimbal frame too. [Prior loss: nobody mentions the earlier voyage that never came home.] On your first jump, an ancient optical buoy rotates toward your flagship and flashes a sharp warning code. {rival} came through first. {rival_deed} The buoy offers to drain its thousand-year core of stored starlight to expose {his} route, though doing so leaves it dark forever. Your cataloger already pulses eager amber.

- **Draw the buoy's stored light.** Its logs reveal {his} lane: Nemesis clock goes back 1, and the buoy dims permanently. (flag `it_song`)
  *The buoy empties its core willingly, and your cataloger marks the entry irreplaceable in muted violet.*
- **Leave the buoy lit.** Your captains study its warning angles instead: every captain gains 15 XP. (flag `it_mercy`, mercy)
  *The buoy settles back onto its quiet orbit while your cataloger logs two stiff footnotes of protest.*

### Beat 2 (sector II): The Ringing Field
Sector II forces your formation across the Ringing Field, a drift of shattered Glasswright hulls from the collapse whose crystal fragments still flash blindingly whenever coherent light strikes them. {rival} turned the graveyard into a trap, deliberately cracking wrecks to flood your interferometers with glare. {rival_line} Your youngest captains, barely a century old, ripple pale grief across their inlays while the cataloger logs every destroyed hull number with shaking focus. Your eldest Mirror flew in this fleet when it was whole; she suggests pulsing one synchronized damping tone across all hulls to quiet the shards, though stopping gives {rival} time to maneuver. [If you drew the buoy's light: its resonance maps which shards {rival} intends to shatter next.] [If you left the buoy lit: its early warning marked an unmined corridor around the worst debris.]

- **Pulse the damping tone.** Your crews steady their focus: every captain gains 20 XP. {He} reads your position clearly: clock moves on 1. (flag `it_lament`)
  *The fractured hulls absorb the matched frequency and dim one by one as the cataloger records each hull code.*
- **Cut emissions and burn blind through the glare.** Every ship takes 5% debris damage, yet you catch {him} mid-turn and expose a Nemesis weakness. (flag `it_dark`, loud)
  *You fly purely on inertial drift through blinding shards, emerging close enough to read {his} shield seams.*
- Blue, needs the buoy's light: **Vent the stored light across the field.** Every shard goes dark instantly: zero damage and Nemesis clock back 1, though the light is spent. (flag `it_spent`)
  *The glare dies in half a second, and your cataloger draws one neat line through the inventory entry.*
- Blue, needs the buoy spared: **Thread the warned corridor.** Clean transit with zero damage, zero clock gain, and +10 XP per captain. (flag `it_path`)
  *The unmined lane holds true to the exact arc, and your cataloger adds a rare note of praise.*

### Beat 3 (sector III): The Last Lens
The Hollow Sun hangs dark inside a thin halo of dying plasma, and turning slowly along its rim sits the last great primary lens of the Lattice, wider than your entire cruiser line and still tracking a star that died a millennium ago. {rival} reached its gimbal mounting ahead of your formation and locked weapons on the rim. {rival_line} [If you ambushed {him} in the Ringing Field: {he} stopped smashing crystal wrecks, and clearly resents being forced onto the defensive.] [If not: {rival} mounted a jagged shard from the Ringing Field right across {his} prow.] [If the buoy's light is still aboard: its reserve can unlock the mounting cleanly without a close brawl.] [If you left the buoy lit: a faint pulse from three sectors back still flashes its beacon code toward the lens.] [If you lost ships: {first_lost}'s empty slot in formation will require a painful written accounting.] Every cruiser you brought into this orbit is irreplaceable ancestral craft. Your cataloger asks quietly whether you'll risk a hull to free the lens first or keep the fleet whole.

- **Send your oldest hull in to free the mounting.** One ship takes 25% hull damage; every captain gains 25 XP. (flag `it_end_archive`)
  *Your senior hull drops shields to match the mounting's lock frequency, and the massive lens slowly swings free.*
- **Hold formation and protect the fleet.** The lens waited ten centuries and can wait one more battle: every ship repairs 20%. (flag `it_end_fleet`)
  *You keep every ship tucked behind prism wards while the cataloger flashes stiff disapproval across the plot.*
- Blue, needs the buoy's light: **Channel the buoy's light into the gimbal lock.** The reserve spends itself freeing the lens: every ship repairs 10% and every captain gains 15 XP. (flag `it_end_buoy`)
  *The lens drinks the old starlight and releases its clamps cleanly without a single shot fired near its rim.*
- Blue, needs the buoy spared: **Relay the remote unlock code from the spared buoy.** The distant buoy flashes one last signal and goes dark forever: every ship repairs 10% and every captain gains 15 XP. (flag `it_end_mercy`)
  *Across three sectors the old mirror fires one final coherent beam, tripping the mounting locks cleanly.*

---

## 6. Eclipse: "The Homecoming"

Charge: *Recover the scattered Lattice cores, guard the siphon corridors, and ignite Ardent's successor at the heart of the dead system.*

### Beat 1 (sector I): The Broken Frame
Your fleet cycles awake on schedule, chassis by chassis, just as Eclipse has done every century since Ardent collapsed. The Archive summary is blunt: four cores still adrift across contested lanes, one stellar frame waiting dark at the system's core. [Prior loss: the Archive logs an earlier Homecoming attempt without listing your failure code, a rare gesture of restraint.] One urgent alert breaks the routine. An outer siphon relay was boarded before your jump, its keeper's chassis carefully stripped for its access ciphers. The keeper's last clean Archive stamp is eight years old. {rival} took the codes. {rival_deed} Your Shades urge immediate pursuit before the ciphers spread; your Umbras advise repairing hulls while dissecting what {he} left behind.

- **Pursue immediately.** Combat routines sharpen: every captain gains 20 XP. {He} reads your high-burn intercept: clock moves on 1. (flag `dd_writ`, loud)
  *Your pursuit order streams to every hull as the restored keeper wakes missing eight years and wondering why the fleet is armed.*
- **Repair and analyze the dismantled frame.** Repair swarms restore 15% hull across the fleet while your Umbras examine the tool marks. (flag `dd_patient`)
  *Your Umbras lay the stripped chassis across a quiet maintenance bay and trace every cut to find the cipher flaw.*

### Beat 2 (sector II): Stolen Ciphers
The stolen siphon codes resurface across sector II as {rival}'s flagship broadcasts them openly, tripping Eclipse relay locks one by one. {rival_line} Directly beneath your jump lane hangs a sealed pre-collapse hull yard full of uncrewed flare frames. You could upload fresh copies from the Archive to crew them immediately, yet every active mind in the Archive is already running somewhere; running two copies of a living mind simultaneously is the single prohibition the Upload never broke. [If you analyzed the keeper's chassis: your Umbras isolated a checksum flaw buried inside the stolen codes.] [If you pursued immediately: {rival} anticipated your chase and already tagged your hull codes across {his} net.] Choose whether to keep the Upload's one law or break it for extra hulls.

- **Break the law and upload duplicate minds.** An Eclipse flare joins your fleet, though the breach trips security alerts: clock moves on 1, and the sector III guard frames will refuse your hail. (flag `dd_broke`)
  *The newly awakened flare crews check the fleet roster, spot their own originals three hexes over, and cut open comms completely.*
- **Keep the Upload's prohibition.** No immediate hull gained; the Archive logs your restraint cleanly. (flag `dd_lawful`)
  *You leave the storage racks dark while your Umbras record the timestamp and the decision.*
- Blue, needs analysis: **Trigger the checksum flaw (costs one spare refit).** Every stolen relay slams shut in front of {his} fleet: Nemesis weakness revealed and clock back 1. (flag `dd_flaw`)
  *Half a dozen hijacked arrays lock {his} fleet out simultaneously, scattering {his} pickets in confusion.*

### Beat 3 (sector III): The Homecoming
Ardent's dead black hole turns massive above your hulls, cradling the dark skeletal ring of the new stellar frame waiting on the final cores to light. {rival} has formed {his} entire fleet straight across the ignition corridor, daring you to push through. {rival_line} [If you triggered the cipher flaw: every siphon array behind you has locked {him} out cleanly.] [If not: stolen Eclipse codes still flicker mockingly across {rival}'s flagship hull.] Before weapons unlock, every ship flashes the last optical capture of Ardent's afternoon light across its bridge; a thousand years of cold siphon engineering comes down to the next ten minutes, and every drone printer is already humming. [If you woke duplicate minds: the copied flare holds the far outer edge of formation, refusing to align beside its original.] [If you kept the law: lawful guard frames from the perimeter arrays request clearance to join your line.] The corona arcs finish charging across the line. Choose what record the Archive keeps of {him}.

- **Leave {him} unarchived.** Erase {his} telemetry completely after destruction: every captain gains 25 XP. (flag `dd_erase`)
  *The Archive opens a deliberately blank record for this engagement and holds it empty.*
- **Scan {his} bridge crew into cold Archive storage.** Every ship rebuilds 15% hull as the recovery swarms prepare. (flag `dd_summons`)
  *You transmit a formal preservation notice across open comms before locking corona arcs.*
- Blue, needs the law kept: **Accept the lawful guard frames.** An Eclipse mote joins your fleet at full hull. (flag `dd_guard`)
  *The perimeter guard vessel slides cleanly onto your flank, answering the Archive's authority if not yours.*

---

## Table A: the rival's calling card, `{rival_deed}` (faction x persona)

One sentence written to fit any beat 1 that says "{rival} got there first". Pronouns follow the generated commander (a Chorus mind is "it"). Live lines sit in `data/rival_lines.json` (`deed`).

| Faction | Persona: calling card |
|---|---|
| Sunward Crusade | **zealous:** {He} chalked every crew name from the station's manifest onto the exterior blast doors before torching the fuel bay. <br> **proud:** {He} burned {his} hull code and full command title across the main docking apron with a cutting lance. <br> **cruel:** {He} torched every storage bay except one medical locker, leaving a spare distress beacon taped to the handle. <br> **methodical:** {He} left a stamped manifest pinned to the airlock listing three overdue debts, with your flagship's name written third. |
| Meridian Directorate | **methodical:** {He} left an itemized receipt bolted to the docking clamp listing every crate confiscated and a timestamp for the next inspection. <br> **proud:** {He} posted an official Meridian seizure notice across the main airlock, stamped with {his} personal clearance seal. <br> **patient:** {He} welded the outer hatches shut and transmitted a printed timetable predicting the exact hour your fleet would arrive. <br> **cunning:** {He} left an open navigation beacon pointing straight into an unmapped minefield, accompanied by a polite compliance warning. |
| Ashfall Hullbreakers | **cunning:** {He} bolted a scorched hull plate from an earlier kill onto the outer airlock with your flagship's serial gouged straight through the center. <br> **greedy:** {He} stripped every gun mount, thruster coil, and bulk door off the depot, then came back to pry the copper out of the wiring. <br> **proud:** {He} tore three deep claw-gouges straight through the station's docking frame so every passing pack would recognize {his} mark. <br> **cruel:** {He} locked the station crew inside the outer airlock with the interior hatch welded shut and ten minutes left on the oxygen scrubbers. |
| The Chorus | **ravenous:** {He} dissolved every bulkhead, conduit, and pressure door inside the station, leaving only a hollow shell of scorched outer ribs. <br> **cruel:** {He} chewed through the station's life-support ring slowly while keeping the internal comms open so the outer docks could hear. <br> **cunning:** {He} left the station's docking lights green and its cargo bays unlocked, seeding dormant spore-sacs behind every bulkhead. <br> **patient:** {He} waited silently in the orbital shadow until the supply convoy finished unloading, then consumed only the loaded hulls. |
| The Glasswrights | **cunning:** {He} left the entire station untouched except for one precision optical relay removed so cleanly the crew didn't notice for six days. <br> **proud:** {He} mounted a single flawless hand-ground prism in the center of the docking bay, calibrated to a tolerance no human yard can match. <br> **patient:** {He} realigned every exterior solar mirror on the depot toward the distant Hollow Sun and powered down the station's clocks. <br> **cruel:** {He} bypassed the depot's emergency generators and stayed on station until every interior lamp faded out one sector at a time. |
| Eclipse | **patient:** {He} left a cold diagnostic counter running on the docking screen, ticking down to the exact minute your fleet exited jump. <br> **proud:** {He} hijacked every display bulkhead on the station to loop the last recorded minute of Ardent burning before the collapse. <br> **cruel:** {He} scanned the entire station crew into {his} mobile Archive and left their living bodies standing dazed at empty consoles. <br> **methodical:** {He} logged every weapon mount and power cell in the depot and left the survey pinned to the airlock with your hull code circled. |

## Table B: the rival's beat 3 hail (what the Hollow Sun means to them, and what they remember)

Picked in order: **remembers** (beaten before, or carries scars), **mercy**, **ruthless**, else **sun**. Live lines sit in `data/rival_lines.json` (`final_by`).

| Faction | The Sun | Remembers | Mercy | Ruthless |
|---|---|---|---|---|
| Sunward Crusade | "Right behind me sits the siphon killing Vesper's stars. Clear out or we burn straight through your hulls!" | "You scarred my flagship {scars} on the way here, and I dragged her all the way to the Hollow Sun just to pay you back." | "Heard you wasted fuel pulling stragglers out of the dark. Nice gesture, won't keep your bulkheads intact here." | "You looted and burned your way across three sectors just like the raiders we fight. Good, makes shooting you easier." |
| Meridian Directorate | "Registry Order 41 assigns sole orbital control of the Hollow Sun to the Meridian Directorate. Stand down now." | "Meridian completed its review of our earlier engagement. The conclusion recommends permanent removal of your fleet." | "Intelligence reports you diverted to rescue stranded crews along the way. Compassionate, though tactically expensive." | "You abandoned allied convoys and looted neutral depots to reach this rim. Even the Registry considers your record excessive." |
| Ashfall Hullbreakers | "Every warlord in the Ashfall belt wants the Hollow Sun's wrecks, and you brought a whole fresh fleet to the pile!" | "You dented my hull last time and let me walk away. Big mistake, {you}; come add another trophy to my bow!" | "Heard you stopped to play nursemaid for crippled ships on your way in. Soft captains make easy salvage!" | "Heard you tore through three sectors without blinking. Good! Finally somebody worth ripping apart!" |
| The Chorus | "Five Lattice cores pulse behind your ships, pouring heat into the dark. Move aside or be digested with them." | "Our newest tissue was grown from the burns you gave us before. Let us see whether your guns still cut." | "You left wounded hulls drifting instead of consuming them. Waste like that does not survive the deep void." | "You stripped and burned everything along your path just to reach the cores. Hunger recognizes a fellow predator." |
| The Glasswrights | "Our grandmothers built the Lattice and watched it kill our sun. Neither Eclipse nor your fleet will steal another core." | "No commander had scarred my hull in three centuries until you crossed my lane. I've been replaying that fight ever since." | "You spared an old relay back in the outer sectors. Rare restraint, though it won't let you pass this rim." | "You smashed everything in your path to reach this dead star. That's exactly how Ardent died the first time." |
| Eclipse | "Behind me hangs the stellar frame that will give Ardent back its noon. You won't keep a single core out of it." | "You cost me a chassis earlier, and all it bought you was a slower path to the same dark." | "We noticed your restraint along the way. We tried restraint once before Ardent collapsed; it didn't save our star." | "You broke everything in your path to get here, just like we did a thousand years ago. Look what it built us." |

## Cross-run callbacks (from the Chronicle)

- Prior loss with this faction: each beat 1 carries a bracket line (above). The Hullbreaker beat 3 can show the last lost flagship frozen into the wreck field (`{prior_flagship}`); Crusade captains chalk `{fallen_name}` from the Hall of the fallen.
- Prior win with this faction: a one-line nod in beat 1 instead (in `outlines_variants.md`).
- After an arc has been finished twice, its cards offer the skim version first (`outlines_variants.md`), with "Read in full" one click away.
- A rival who beat you last run may come back: their beat 1 deed is replaced by "{rival} broke a fleet of yours before. Neither side forgot."

## Word counts

Checked by `godot/story/test/check_outlines.py`: every card is at least 100 words without its conditional lines and at most 150 with its two longest, counting tokens at the length they render; no em or en dashes; skim cards 40 words or fewer.
