# Council 1120, sci-fi lore seat: Fable leg (blind round)

Read from the repo checkout only: godot/story/ (README, outlines, variants, data, rival.gd, battle_voice.gd), data.js (the
source of godot/campaign/data/campaign_tables.json, which is one line and cannot be cited by line), godot/campaign/campaign.gd,
godot/rules/rules.gd, godot/ui/campaign/campaign_ui.gd (help), lore_bible_r8.md, rename_map_final.md, docs/words/,
RULEBOOK section 11 and FINDINGS R37 to R101 and R300 to R357.

Limits of this leg: no pictures or clips were in the pack folder when I wrote, so nothing here was seen on screen. Every
finding is traced in text and code. Where a finding depends on what the battle log shows, I say so, and the Board should
confirm it with one capture before filing.

Rulings I checked against and do not contest: the lore is lore_bible_r8.md (RULEBOOK 11.1), nothing echoing 40k (11.2),
Ryan's read per faction gates story text (11.4), a hunter drawn per story point (R85), the Nemesis writing adopted as is
(R101), faction display names (R59), the R78 faction rulings.

## Findings, worst first

### 1. The Nemesis opens his battle twice, in two different voices

Two separate line systems both speak at the start of every Nemesis battle, and nothing stops the second.

- The rules log his campaign line: `if jt(line): logm(String(fl["name"]) + ": \"" + String(line) + "\"", "e")`
  (godot/rules/rules.gd:2244), fed by `"line": nemOpenLine(N)` (godot/campaign/campaign.gd:2518), which reads NEM_VOICE.
- Then the story voice adds its own hail from rival_lines.json: `for l in voice.opening(): hud.add_log(l["text"], l["kind"])`
  (godot/scenes/battle/battle.gd:632 to 633; the rules line reaches the same log at battle.gd:1299 to 1300).

The two pools were written a month apart by different hands and do not sound like the same person:

- Hegemony: "Registry entry confirmed. Your approach is already in the plan." (data.js:682) then "You have been designated
  a priority target. Comply by dying." (godot/story/data/rival_lines.json:95).
- Glasswrights: "This duel is already framed. Hold still." (data.js:846) then "I have watched your fleet for three systems.
  I am sorry it has come to this." (rival_lines.json:335). One is cold, one grieves.
- Chorus: "Hunger. The fleet smells close." (data.js:786) then "We followed your scent across the stars. Now we feed."
  (rival_lines.json:255). One says "the fleet", one says "we".

What is wrong: the one named character the run is built around introduces himself twice and contradicts his own manner. A
meeting is certain in sector I, so a new player sees it in the first hour.

Fix: one speaker per moment. When the campaign sends a line (cfg.nemesis.line), battle_voice.gd skips its own Nemesis hail
and speaks only your admiral's reply. Keep rival_lines.json for the moments NEM_VOICE has no line for (first ship killed,
his last words, his gloat on the end card). Which pool owns the hail is a taste pick: Ryan picks. Not seen on screen: confirm
with one Nemesis battle log capture.

### 2. The words still tell a one-rival story; the game now sends a new hunter each sector

R85 is the rule: `drawNemAssign` draws three hunters, never the same faction twice running (campaign.gd:2248 to 2253), and
the map says so: "That meeting is done; the next sector brings the next hunter." (campaign.gd:2512). The story text was
written before R85 and never caught up:

- "'s flagship breaks apart, but he escapes, scarred and furious. He will be back." (campaign.gd:2645). The sector II hunter
  can never be back, and the sector I hunter returns one run in four.
- His own parting lines promise the same: "This is a debt, not a defeat. I will come back to collect it."
  (rival_lines.json:30); "Not today. I know your wake now. I will be behind you." (rival_lines.json:190).
- Your admiral greets a stranger as an old enemy: "{rival} again. My pilots have been waiting for a rematch."
  (godot/story/data/voices.json:108); "{rival}. I have read every report on you twice." (voices.json:28); "{rival}. I
  chalked your name on the hull the day we launched." (voices.json:12).
- In sector III the story voice always uses the "final" pool, met or not (`if sector >= 3:`, godot/story/rival.gd:160), so
  a commander you first see in sector III can say "I tracked you across three sectors to get here first."
  (rival_lines.json:186). The campaign then closes with "is dead. The feud is over." (campaign.gd:2642) on a first meeting.
- The behaviour cards describe repeat meetings that R85 mostly removed: "He flees a fight he is losing and comes back
  richer, with an extra ship each time." (data.js:641).

A side effect: the rematch writing is close to unreachable. The "again", "scar" and "memory" pools (rival_lines.json:19 to
22, 49 to 61 and the same blocks for the other five factions) only fire on a later meeting before sector III
(rival.gd:162 to 171), and R85 gives one meeting per sector with a new hunter. The lean-based hails ("final_by",
rival_lines.json:86 to 91) are only called from the arc engine (godot/story/arc.gd:126), and arcs are off. That is roughly
90 written lines no player can see. I could not find a path that reaches them; the challenge side should try.

Fix, keeping R85: (a) sector I and II defeat text hands over instead of promising a return, for example campaign.gd:2645
becomes "...'s flagship breaks apart. He is out of this hunt. Others are not."; "He will be back." shows only when the draw
has him at story point 3. (b) Admiral "nemesis" lines that assume history get a first-meeting version: Reyes, "{rival}. New
name on the board. Strike group, learn it." (c) Drop "three sectors" from the final pools. (d) On the one-in-four return, let
rival.gd use "again", "scar" and "memory" in sector III too, so the memory writing is seen at least then.

Reopen: Ryan's call. R85 traded the story's best idea, a rival who remembers you, for variety. A rule of "the sector I
hunter always returns in sector III" would keep three faces and make the memory lines fire every run.

### 3. The Nemesis does not know who you are: several hails are false against some player factions

His lines are keyed by his faction only (rival.gd:66 to 67). The Nemesis is never your own faction, but any of the other
five can be the player, and some lines only make sense against humans:

- Glasswright, proud: "My family ground the lenses of the Lattice. Yours had not yet learned to make glass."
  (rival_lines.json:388). Said to an Eclipse player this is nonsense: Eclipse are "Our siblings. They took our light to
  become machines" (contrib/opus/compute/lore_bible_r8.md:429), the same people, from the same Lattice.
- Glasswright, patient: "I watched your grandparents' grandparents learn to jump." (rival_lines.json:392), to a Chorus swarm
  or a thousand-year Eclipse mind.
- Chorus: "Meat that thinks. Meat that runs. Meat that screams when it breaks." (rival_lines.json:256), to Eclipse machine
  bodies. The bible has the Hullbreakers say of Eclipse "No smell, no blood. Dead metal" (lore_bible_r8.md:291).
- Eclipse, cruel: "I withdraw to your colonies. Their stars are small. I will start there." (rival_lines.json:473), and
  Chorus, cruel: "We will eat your colonies while you chase us." (rival_lines.json:309), to a Chorus player (no colonies) or
  to a Glasswright player, whose "fleet has wandered ever since" (lore_bible_r8.md:411).

What is wrong: the sibling quarrel (Glasswrights, Eclipse, and the Chorus made to kill Eclipse) is the heart of the setting
and the game never lets the three recognise each other.

Fix, and the fiction is already written and unused: every faction's "What they think of the others" block in the bible
(lore_bible_r8.md:173 to 179, 233 to 239, 285 to 291, 356 to 362, 423 to 429, 487 to 493) is 30 pair lines that appear
nowhere in the game. Add one optional `vs` pool per faction keyed by the player's faction, checked first for the hail, for
example Glasswright against Eclipse: "You were there when it broke. So was my grandmother. Turn back." Mark the four lines
above as not for the factions they misfire on.

### 4. Commanders say interface words out loud: clock, sector, hex

These are shown as his speech, in quotes after his name (`nemFull(N) + ": \"" + nemSay(t, N) + "\""`, campaign.gd:2594):

- "My clock runs at half speed. I have time you do not. Approach." (data.js:890)
- "Even the last sector is not an ending. Once more, and then the archive closes." (data.js:894)
- "Tight formation is set. Synchronized fire reaches one hex further." (data.js:719)
- "Hunger. Ships regrow 3 more hull each turn." (data.js:823)
- "Fervour is up. Guns deal 8% more damage." (data.js:983)

What is wrong: a thousand-year machine mind knows about the player's clock widget; a swarm quotes its own tooltip. This is
the plainest "tells instead of shows" in the live text.

Fix: his sentence stays in the fiction and the rule stays on the line under it, which the card already prints
(NEM_ADAPT_FAC, data.js:660 to 665). Rewrites: "I am in no hurry. I have not hurried in a thousand years. Approach." /
"Even here, at the Sun, this is not an ending. Once more." / "The formation is tighter now. You taught us that." / "We
grew. You fed us." / "The oath is sworn again. The guns answer it."

Reopen: Ryan's call. R101 adopted this table as is, including "adaptation lines spoken through nemSay". The pick to speak
them can stand; the ask is only that the spoken half carries no numbers.

### 5. The adopted Nemesis table drifts from the bible's voices; Hegemony and Eclipse blur

The bible gives each motif one owner: "Memory, the archive, the lost sun, warmth remembered | Eclipse | the Hegemony keeps
data, not memory" and "Data, projections, the Registry ... | Hegemony | Eclipse get no networks or projections"
(lore_bible_r8.md:99 to 100). In NEM_VOICE the two commanders trade words:

- Eclipse talks like a clerk: "Your wounded will be filed as destroyed before the healthy are addressed." (data.js:908); "I
  rise once more to close your file instead." (data.js:912); "Victory, filed under the flagship." (data.js:900).
- Hegemony talks about remembering: "The standard has not forgotten." (data.js:695); "The record is not erased."
  (data.js:687). Next to "The Registry closes this file." (data.js:685) the two factions are one voice.
- None of the sixteen Eclipse persona lines (data.js:889 to 923) mentions noon, warmth, bodies worn or doubt, which is the
  whole Eclipse register (lore_bible_r8.md:463). "the archive" is lower case here and "the Archive" everywhere else
  (data.js:1006).
- The Chorus never says "we": "The fleet feeds. The heat rises." (data.js:787). Bible: "'We'. Short sentences."
  (lore_bible_r8.md:332).
- The Glasswright commander never apologises or grieves: "A precise finish. The glass is clean." (data.js:863). Bible:
  "They apologise often and mean it." (lore_bible_r8.md:398).
- Hullbreakers chase wealth: "Not worth the teeth. The pack comes back richer." (data.js:736). Bible: "They don't want
  riches; they want to be the strongest thing in the dark." (lore_bible_r8.md:257).

What is wrong: X21's "factions blur" was fixed for the singing motif and has come back through this table.

Fix: a voice pass on NEM_VOICE only, same slots, same count. Samples: Eclipse cruel meet, "Your wounded go dark first. We
will remember each one. You will not." Hegemony proud remember, "Last time you won with {beat}. It is on page one of your
file." Chorus ravenous win, "We fed. We are warmer. We want more." Glasswright cruel win, "The damaged ones broke first. I
am sorry. It was the clean way." Hullbreaker cunning flee, "Not worth the teeth. The pack comes back stronger."

Reopen: Ryan's call. R101 adopted the text as is; RULEBOOK 11.1 says the bible is the lore. The two disagree here.

### 6. The live beat 3 card casts fixed speakers that contradict the admiral you picked

The card prints the same dialogue for every admiral, then appends that admiral's spotlight (campaign.gd:3125 to 3126).

- Hullbreakers: "Howler: \"The prize hold, Warlord. ...\"" and "Warlord: \"Everything with a heart can be afraid. Claws
  out.\"" (data.js:3464 to 3465). Only Grax is a Warlord ("Warlord Grax Ironmaw", data.js:238). Play Old
  Mott (data.js:240) and the card has a Warlord giving orders, then says "Old Mott has outlived forty captains."
  (data.js:3472). Who is commanding?
- Eclipse: "Admiral: \"I have worn nine bodies and outlived my sun by a thousand years.\"" (data.js:3567). Only Aurex is
  "Ninth Frame" (data.js:250). Seveth is "Twice-Restored" (data.js:253) and says so: "I have been restored twice."
  (voices.json:373). Vessane is "Third-Housed" (data.js:251), yet also says "I have broken greater, three bodies ago."
  (voices.json:347). "Nine bodies" is also every Eclipse rival's line (rival_lines.json:416, 446), so the one detail that
  made Aurex particular is now everyone's.
- "Captain" is used as an address in factions that have no such rank: "Lens-keeper: \"The replay is clear, Captain.\""
  (data.js:3533) and "Permanence is very long, Captain." (data.js:3567). Glasswright ranks are "Glimmer, Glint, Facet,
  Mirror, Lens-keeper" and Eclipse "Shade, Gloam, Umbra, Midnight, Nadir" (data.js:1026 to 1027). Lens-keeper is the top
  Glasswright rank and here it reports to a "Captain".

Fix: speaker labels become tokens filled from the picked admiral ("{admiral_short}:" for the commander, the faction's own
rank for the junior voice: "Mirror:", "Umbra:"). Eclipse line: "I have outlived my sun by a thousand years. Permanence is
very long. Let us spend some of it correctly." Vessane's boss line: "I have broken greater, a body ago." The text is
approved; this is a continuity fix inside it, not a rewrite.

### 7. Event cards whose outcomes do not follow the fiction

The deck was written for a human crew. Chorus and Eclipse got nine re-voiced cards (data.js:440 to 583); the rest, and all
cards for Hullbreakers and Glasswrights, show the human text.

- The Chorus escorts merchants for pay: "Open a path through the swarm" / "+45 credits for safe passage." (data.js:543),
  and bids at auction: "Pulse a bid of 120 credits" (data.js:557). Bible: "Captives: food, or new flesh for the swarm."
  (lore_bible_r8.md:353); "one swarm with one appetite" (lore_bible_r8.md:328). The base "Offer aid" to a Hegemony tender
  (data.js:298) has no Chorus version at all.
- Hullbreakers get "Mutters below decks" with "Pay a bonus (50 credits)" and "Send your most senior captain to talk"
  (data.js:391 to 394). Their whole society answers this already: "Ritual: the challenge. Any raider can fight the captain
  for the ship." (lore_bible_r8.md:297).
- Hullbreakers and Glasswrights hire "A scarred destroyer captain ... she wants a new cause, for a price." and receive "A
  destroyer of your own kind" (data.js:304 to 305): a human mercenary turns into a Glasswright lancet.
- A Chorus or Eclipse card still offers "Offer the Sunward oath" (data.js:446, 453, 510, 517).

Fix (words only, same effects): Chorus convoy, "Let them pass. The swarm takes the slowest barge as its price. +45
credits of metal."; Chorus auction, "Take the taste, leave 120 credits of scrap in the dock." Hullbreaker mutiny, title
"A challenge below decks": "Let it be fought (50 credits of trophies to the loser's kin)" / "Fight it yourself" / "Send
your oldest Ripper to remind them who wins". Hullbreaker merc: "A raider with no pack wants a place, and a share." Hide the
Sunward-only option from factions that can never take it. The nine existing Chorus and Eclipse cards are the model: keep
that method and finish the other two alien factions.

### 8. The wall of names works like a shrine: pay an offering, the fleet heals

"A memorial station hangs over a dead world, its walls chalked with the names of a crusade that never came home. Your
crews ask to leave an offering." Options: "Offer 50 credits" gives "Every ship repairs 30% hull."; "Chalk your names and
hope" gives "Even odds: repair 30%, or nothing." (data.js:319 to 321). The Hegemony version adds "Spacers are a
superstitious lot" (data.js:319).

What is wrong: nothing in the fiction says why money left at a memorial mends hulls, so it reads as prayer answered. The
bible is firm on this one faction: "The chalked names are an answer to the Registry, not a religious rite."
(lore_bible_r8.md:140) and lists "saints, relics" as not allowed (lore_bible_r8.md:156). The event id is still `shrine`
and it plays most for the Sunward Crusade, the faction a new player starts on. It is the clearest 40k echo left in a card.

Fix: the station has keepers and a yard. "The keepers of the wall still run its dock. They mend any fleet that adds to
the Roll." Options: "Pay the keepers (50 credits)", "Chalk your names and ask for dock time" (even odds: "they have the
plate, or they do not"), "Leave salvage for the dock". Same numbers, a reason for each.

### 9. Borrowed Hades vocabulary survived the rename

The Oct 27 rename moved patron, boon, sigil and favour to core, protocol, signal and sync. The rest of that set is still on
screen:

- "Lose a run to unlock Heat: optional rules that make runs harder and pay more renown." (godot/ui/campaign/campaign_ui.gd:913)
- "Aspect of the Spear", "Aspect of the Brood", "Aspect of the Ram" (data.js:3361 to 3363), picked for the flagship at run
  start (campaign_ui.gd:1877).
- Duo and Legendary protocols (data.js:3289, campaign_ui.gd:1877), and protocol names that are still god gifts, not
  something "A core can push ... into a fleet's systems" (lore_bible_r8.md:118): "Feast on the Fallen", "Funeral Pyre",
  "Marked for Death", "Pyre of Stars" (data.js:3316 and the BOONS block from data.js:3298).

What is wrong: Heat (stacked optional hard rules for more reward), "Aspect of the X" and Duo are Hades's own terms in
Hades's own sense. Bible rule: "no name lifted from ... another known franchise. Common English words are fine unless a
franchise owns them in this exact sense" (lore_bible_r8.md:108). It also wastes free fiction.

Fix, Ryan picks (taste): Heat becomes "the Dimming" (the Siphoning deepens; each level the sectors are darker and the
enemy stronger), which explains the mode with the setting's own threat. Aspects become flagship "fits": Spear fit, Carrier
fit, Ram fit, Bulwark fit, Storm fit, Flag fit. Protocol names get hardware words: "Wreck reclaim" for Feast on the
Fallen, "Chain ignition" for Funeral Pyre, "Target lock" for Marked for Death.

### 10. Nobody agrees where the six cores are

The bible fixes them: Kharon "Never left the dead Ardent system", Vyre "Captured 25 years ago" by the Hegemony, Crucible
inside the Chorus, Astra flown by the Glasswrights, Rook "Adrift in the wreck fields", Seren "Drifted to Vesper's outer
belt" (lore_bible_r8.md:34 to 39). A core is "a ship-sized power core" (lore_bible_r8.md:118).

- Live, Hullbreaker beat 3: Rook is cargo. "The prize hold, Warlord. We can hear the core through the hull."
  (data.js:3464); "Boarding claws only, no broadsides into the prize hold." (data.js:3453). A ship-sized core is in the
  hold of whichever flagship the run drew, every run.
- Waiting for Ryan's read: the Chorus charge, "Five warm keys circle the Hollow Sun." (godot/story/outlines.md:179). Only
  Kharon and Rook are there. The Eclipse arc opens "Six keys, four still scattered." (outlines.md:275) and wins with "One
  by one the keys are carried in" (outlines.md:304) after beating one fleet that held none of them.
- Rook leaves "a thousand years of ion trail" (outlines.md:147), but "the cores have no drive" (lore_bible_r8.md:15).

Fix: Hullbreaker card, "The wreck, Warlord. Their flagship is moored to it. We can hear the core through the ice." and
"Boarding claws only, no broadsides toward the core." Chorus charge: "Five warm keys. Memory knows where each one went.
The Sun first." Eclipse win: "The approach is cleared. The first key is carried in, and the frame of the new sun begins,
very faintly, to warm." Rook's log: "a thousand years of listening-array record".

### 11. The six arcs cannot be switched on as written

Status: `var arcs_on := false` (campaign.gd:44), no `data/arcs/<faction>.json` exists, and the README says "Until then the
arcs do not appear." (godot/story/README.md:125). That is the 11.4 gate and not a bug. But the text waiting at the gate no
longer fits the game around it:

- Its premise is "the rival is the run's Nemesis" across three beats (outlines.md:3). Under R85 the beat 1 hunter is never
  the beat 2 hunter. Every "[If you ...: {rival} ...]" callback (for example outlines.md:55, 68) would name the wrong person.
- Beat 3 already has a different, live, approved story per faction (STORY_BEAT3, data.js:3371). The Crusade outline ends
  on "Break the Siphon" with the shard (outlines.md:66 to 75); the live card is "What Is Owed" with Seren fire
  (data.js:3374 to 3390). Two endings for one arc.
- Old Mott is a side character who talks to you, "Mott wipes his muzzle and waits." (outlines.md:160), and also a
  playable admiral (data.js:240). Pick Mott and the arc has Mott advising Mott.
- Three admiral lines already refer to arc scenes no player has seen: "{rival}. You spoiled our young. Now you feed
  them." (voices.json:204), "{rival}. The mirror-buoys flashed your name." (voices.json:268), "{rival}. You broke our glass
  once." (voices.json:284).

Fix, Ryan's call (11.4): before his read, rework beats 1 and 2 to R85 (each beat's `{rival}` is that sector's hunter, and
callbacks to an earlier beat name what happened, not who did it), retire the outline beat 3 in favour of the live card,
swap Mott for another den elder when Mott is the admiral, and soften the three admiral lines until arcs ship ("{rival}. You
are between us and the warm thing.").

### 12. Small term slips, one pass

- Shields. Bible: "shields, screens (Sunward Crusade), deflectors (Hegemony)" (lore_bible_r8.md:83). The data follows it
  ("Deflector capacitor", data.js:278; "I have doubled my screens since.", rival_lines.json:54). The admirals
  do not: Thale, "Shields to full." (voices.json:56); Maren, "Armour forward. Shields up. Advance." (voices.json:120).
- One role, four names: "your Nemesis" (rules.gd:2231), "the next hunter" (campaign.gd:2512), "the enemy commander"
  (data.js:369), "rival" (story files). With three of them per run, "Nemesis" now means "this sector's hunter". Pick one
  word for the role and one for the clock.
- A Sunward rival sneers "You hid behind torpedoes last time. A coward's weapon." (rival_lines.json:55). Torpedoes are the
  Crusade's own gift from Seren ("the Crusade's weapons came from it", lore_bible_r8.md:125) and a Crusade admiral's whole
  doctrine (data.js:223). Rewrite: "You burned me with torpedoes last time. I know that fire. It was ours first."
- Vex: "Today I rub it out." (voices.json:12). The Crusade exists because the Registry deleted names; "Records by hand
  ... the Crusade chalks every name on the hull" (lore_bible_r8.md:140). A Crusade admiral does not erase. Rewrite: "Today
  I draw the line over it."
- Glasswright generations: "only two or three generations on ... people their grandmothers knew" (lore_bible_r8.md:394)
  against "your grandmother's grandmother ground the lenses" (outlines.md:228) and rival_lines.json:346. Use "your
  grandmother".
- Church and tribunal words still in view: Eclipse's strike is "a tithe on a half-speed clock" (data.js:941; the rename
  map already ruled "Tithe is a church word", rename_map_final.md:61); "Purge the moon" (data.js:317); "Face judgment."
  (data.js:668); ship names "Bright Censure" and "Judgement Bell" (data.js:271); Malek, renamed Oath-Captain, still speaks
  as an inquisitor: "Every trader here is lying to me, and I will learn why." (voices.json:22), "Burn the rest."
  (voices.json:33).
- The Glasswright apology is a good trait worn thin: six "I am sorry" in one rival pool (rival_lines.json:335, 354, 358,
  363, 397, 410). Keep two; let the others grieve some other way ("Mourn them, if you know how." already does).

## X21, item by item

| X21 flag | Now |
|---|---|
| Sadist rival with no memory of the player | Fixed on paper, mostly not in play. Six personas, scars, seven memory lines and lean-based hails exist (rival_lines.json), but R85 and arcs being off leave most of them unreachable (finding 2). In play he remembers you at most one run in four, through NEM_VOICE "again" and "remember". |
| Dead flag branches | Fixed in the outline text (every beat 1 flag is read in beats 2 and 3). Not in the game: arcs are off, and the live beat 3 card reads no earlier choice. |
| Too many weakness reveals | Fixed in the arcs (at most one each: outlines.md:153, 198, 241, 290). Still seven events in the live deck that reveal one (data.js:341, 348, 370, 384, 404, 408, 424). With a new hunter each sector this matters less than it did. |
| Factions that blur | The singing blur is gone: no song word in any display string I could find. A new blur came in with NEM_VOICE: Hegemony and Eclipse, and a Chorus that says "the fleet" (finding 5). |
| 40k echoes | Names are clean (Phaeron, Dynast, Inquisitor, saint, heretic: zero display hits). Left: the wall of names offering (finding 8), tithe, purge, judgment, Censure, Malek's manner (finding 12). The Egyptian and tomb words survive only as ids, which never show. |

## Good, and must be kept

1. **The Crusade as an answer to arithmetic, not a church.** "Who carries the dawn? We do. Who pays for it? We do."
   (outlines.md:68) and "The arithmetic was done on us once. We keep the Roll." (data.js:3404). Chalk against deletion is
   what separates this faction from every space crusade before it.
2. **The Hegemony's unlogged minute.** "It is the only thing the Registry never logs." / "The names, Admiral. Rank and
   number. All of them. It takes the whole minute." (data.js:3429 to 3431). Quiet horror with no villain speech, and the
   choice costs the faction's own mechanic (sync). The best match of fiction and rule in the game.
3. **The Chorus's two throats.** "We close Memory for the fight ... Something that knew our name is quiet, and the quiet
   is also a kind of food." (data.js:3494). It makes a swarm a character. Never let a Chorus line lose "we".
4. **Each faction's "learning" line explains the roguelite for free.** Eclipse: "it sends this same one again, its minds
   restored from the Archive with every lesson and correction intact." (data.js:3570); Crusade: "the next crusade stands
   at this same dark and reads what you chose, in chalk" (data.js:3399). The How to play text (campaign_ui.gd:1866 to
   1867) should borrow one sentence of this.
5. **Fiction in the rules where it is cheap.** Chorus biomass ("The Chorus regrow with biomass", campaign_ui.gd:1663),
   Glasswright cullet (campaign_ui.gd:2322), the Chorus eating a core (R78 Q15), and the nine re-voiced Chorus and Eclipse
   event cards ("A divergent copy ... Two copies of its mind are issuing incompatible orders.", data.js:466 to 467). This
   is the method findings 7 and 9 ask to extend.
