# First-time player leg: Fable

Build 25adec31, council pack of Nov 20 2026. I have never played the game and did not read its code. I looked at all 8
stills, all 38 frames of seed 10, all 40 frames of seed 121, and both traces.

How I cite: `s10 t022` means `pack/run_seed10/PT25adec3_seed10_t022.jpg`; `s121 t040` means
`pack/run_seed121/PT25adec3_seed121_t040.jpg`; `still 03` means `pack/stills/PT25adec3_battle_03_3_enemy_clicked.jpg`.
Trace times assume 30 frames a second (the end cards line up with the frames that way).

Limits of what I saw. The moves are a script's, so I judge the screens, not the tactics. Frames are 8 seconds apart, so
the name-your-flagship card, the map cards (c_map, c_clock), the protocol pick after Battle 1 in seed 10 and the screen
after "Continue" on defeat were never in a frame: I say nothing about them. Some frames are blocky (s10 t026, t030, t033;
s121 t024, t025). I am guessing that is video compression, not the game, and I do not count it. No front-end or help
screens were in the pack. Sound not judged.

One ruling I touch: R74 (first reinforcements arrive in Battle 2). I do not call it a bug; see Not fun 2, marked reopen.
R328 item 4 says the cut-in policy waits on this recording, so Not fun 3 is evidence for that open call, not a new ask.

## 1. Fun

1. **The shot forecast tells me the result before I commit.** s10 t012: "76%, about 11 damage, 11 to shields, 0 to hull"
   beside a button that reads "FIRE THE SEAR REPEATER". s10 t035: "Expected: about 11 shield and 23 hull damage... fire 2
   weapons". Pattern: Battletech and XCOM players praise a hit chance and damage preview they can trust, and Into the
   Breach reviews single out knowing the outcome before you act.
2. **Facing matters and the screen says so.** The move preview counts guns: "0 of 3 guns bear on an enemy from here"
   (still 02, s10 t004) against "2 of 3 guns bear" (s10 t032) and "3 of 3" (s10 t034). When the cruiser finally gets a
   broadside plus the lance on one target the forecast jumps from about 14 damage (s10 t010) to about 34 (s10 t035). That
   is the "my positioning paid off" moment Armada players talk about. The arc wedges on the board (still 01) help.
3. **One big button that changes with what I am about to do.** MOVE HERE (s10 t004), BURN AND FIRE (s10 t008), FIRE THE
   SEAR REPEATER (s10 t012), FIRE 2 WEAPONS (s10 t033), END SHIP (s10 t005). I never have to hunt for the main action.
   "Burn and fire" (close and shoot in one order) removes the fiddly step that hex games usually have.
4. **Ships break in pieces, not just in numbers.** Log lines "midships destroyed. Broadsides and shield..." (s10 t012),
   "prow destroyed. Forward weapons silenced" (s121 t011), "engines destroyed. Engines crippled" (s121 t014), and the ship
   outline on my card filling red from the stern (s10 t012, s121 t030). Pattern: FTL and Battletech reviews love knocking
   out a system instead of grinding a health bar.
5. **Named ships, named captains, and an admiral with a voice.** Each run gets new names (Vigilant Ash in s10 t001, Bright
   Censure in s121 t001). "A ship of the line is gone. Chalk her name." (s10 t018 log) and the defeat line "Add my name to
   the wall, under the others" (s121 t040) land well. Pattern: Darkest Dungeon and XCOM reviews are full of stories about
   named people who died.
6. **The sector map offers a real route choice with the stakes printed.** s10 t023: four jumps (Ambush, Decapitation,
   Unknown signal, Relay), each with difficulty and what it pays, plus a Nemesis hunt clock ticking at "0.5 of 4".
   Pattern: Slay the Spire's map and FTL's pursuing fleet, where every jump is a decision under a clock.
7. **The aspect pick is three big, clear, different promises.** s10 t001 and s121 t001: +60% ram damage, +70% hull and
   shields, forward guns +50%. The offer differs per run (Spear in one, Bulwark in the other). Pattern: Hades players
   praise a starting choice that changes how the whole run plays.
8. **A salvage choice that is a real trade.** s121 t018: strip the destroyer for "Lance damage +25%" or the picket for
   "Battery weapons fire +1 shot", or take credits. The wreck even remembers how it died ("cut in two by a lance by the
   Bright Censure"). That is a build decision after the first fight, which is the Slay the Spire card-reward hook.

## 2. Not fun

1. **Defeat does not tell me why I lost or what I got.** s121 t040: "DEFEAT. 2 enemy ships destroyed, 2 of yours lost, in
   7 rounds", a quote, and Continue. The objective counter beside it reads "hold the relay 2/3 (them 0/3)": I was one
   round from winning and the card does not mention it.
   Reviewer: "Lost my first run on fight two and the game just said DEFEAT. No idea what I did wrong."
   Fix: put one plain cause line on the card ("You were 1 round from holding the relay. It was contested from round 5."),
   the top source of damage taken, and anything the run earned. Pattern: Hades and Slay the Spire make a death show what
   you learned and what you keep; that is what sells the next run.
2. **Battle 1 costs a ship in both runs, and the run then looks like a slide.** Both seeds lose the frigate in the fight
   marked "Easy" (s10 t018 and t022; s121 t016 and t018). The fleet goes into Battle 2 with 2 ships against 4 (s10 t025)
   or 3 plus a jump-in (s121 t021, arrival in the trace at round 2 to 3), also marked "Easy" (s10 t023, s121 t019), and
   seed 121 loses the run there. The script flew the frigate forward, so a person may do better, but no frame showed a
   chance to replace the hull between fights.
   Reviewer: "Lose one ship in the tutorial and fight two is already unwinnable. Death spiral."
   Fix (pick one): make the Battle 1 enemies spread their fire so a first-timer's frigate usually limps out; or offer a
   replacement hull before Battle 2; or scale Battle 2 to the ships I have left. Reopen, Ryan's call: R74 puts the first
   reinforcements in Battle 2; I would keep them but not when the player arrives a ship down. Pattern: FTL and Darkest
   Dungeon get their worst reviews for early losses that snowball with no way back.
3. **The same lance cut-in plays again and again.** Trace, seed 10 Battle 1: 12 cut-ins, 8 of them the same lance shot,
   29 seconds of a 140 second fight (21%). Seed 121: 5 lance cut-ins in Battle 1, 10 cut-ins in Battle 2. The frames
   show it: s10 t010, t013, t015; s121 t015, t017, t037, t038. The setting says "key moments" (still 06) but a routine
   shot from the flagship counts as one.
   Reviewer: "Cool camera the first three times. By battle two I wanted to turn it off."
   Fix: cut-ins for kills, first shot of a battle and command orders only (R328 already leans this way). Pattern:
   Battletech's launch reviews hammered slow repeated attack cameras until speed options came in; XCOM kill-cams the same.
4. **The cut-in keeps the planning tooltip on screen.** s10 t010, t013, t015, t035 and s121 t015, t037, t038 show the
   letterboxed shot with the "Targeted. Click again or Enter to fire 1 weapon" box still sitting on it, and the HUD gone.
   Reviewer: "The cinematic shots have a tooltip stuck over them."
   Fix: hide the target tooltip when the cut-in starts; show the result number instead (hit, damage dealt).
5. **The camera leaves the action in a corner or off the edge.** s10 t008, t011, t012, t014: my ship and its target are
   at the right edge, most of the screen is empty space. s121 t014: the acting ship is in the top right corner and its
   tooltip runs off the screen. s10 t032: the ship is at the far left edge. s121 t032: the fight is a small cluster top
   right under four stacked labels.
   Reviewer: "I spent half the fight dragging the camera back to my own ships."
   Fix: when a ship becomes active, centre the view on the ship and its nearest enemy and zoom so both fit. Pattern:
   Into the Breach keeps the whole board in view; Homeworld gets praised for a focus key that always frames the fight.
6. **At normal zoom the ships are dark slivers; the rings do all the work.** s10 t005, t009, t017, s121 t012: I can tell
   mine (teal ring) from theirs (purple brackets) only by the ring, and cannot tell a cruiser from a frigate. The big
   planet takes more screen than the whole fleet (s121 t004, t006).
   Reviewer: "Lovely ship models that you only see in cutscenes. In play it is coloured circles."
   Fix: a slightly closer default battle camera, a class pip or size-scaled ring, and a rim light or engine glow in the
   side colour. Pattern: Homeworld reviews praise ships you can read by silhouette and trail at any distance.
7. **Teaching cards are small walls of text about things I cannot use yet.** s10 t004 "MOVING AND FACING" packs six
   lines and four numbers (+10, 3 or more hexes, -5, Brace) and ends "Glasswright ships cannot Brace", a faction I have
   not met. The "REWARDS" card (s10 t022) explains captured ships, command point limits, Strip, Ransom and protocol
   rerolls while the screen offers only "Scrap it". The cards also sit there through enemy turns (s10 t006).
   Reviewer: "The tutorial is pop-up paragraphs. I clicked Got it and learned by losing."
   Fix: one idea per card, tied to the click I am about to make, and only for what is on screen now. Move the rest to
   the first time it appears. Pattern: Into the Breach and Slay the Spire teach one rule at the moment it matters.
8. **Round 1 of the first battle has nothing to shoot.** s10 t004 "0 of 3 guns bear", s10 t005 "No gun bears from here
   yet", s10 t007 "0 of 1 guns bear"; still 03 shows the target at 21 hexes with guns that reach 5 and 7. The first
   turn is three approach moves and the admiral saying "Let them come to the broadsides".
   Reviewer: "First turn of the first fight: move, move, move, end turn."
   Fix: start Battle 1 with the fleets about 7 hexes apart so the first order of the game is a shot. Pattern: Into the
   Breach starts every fight already in contact.
9. **Two black loading screens with nothing on them, in two different styles.** s10 t002 and s121 t002 "Preparing the
   sector..." in a small plain font; s10 t024 and s121 t020 "PREPARING THE BATTLE" in the display font. Trace: about 5
   seconds before Battle 1, 11 to 14 seconds before Battle 2 (seed 10 frames 5474 to 5880, seed 121 4449 to 4788).
   Reviewer: "A black screen for 12 seconds before every fight on an SSD."
   Fix: one loading screen style showing the enemy fleet list, the objective and one tip, so the wait is the briefing.
10. **The log that explains what happened is three cut-off lines.** s10 t008 "Cordon destroyer fires Ion cannon at Cold
    Reckoning: 18 to prow shie..."; s10 t037 "Hullbreaker raider rams Everwatch at full speed: 34 to its prow. 18 ba...";
    s121 t040 "The wreck of Bright Censure drifts in place, blocking movement and...". The numbers I need are past the dots.
    Reviewer: "The combat log truncates the one line that tells you why your ship died."
    Fix: wrap log lines instead of cutting them, and open the log taller during the enemy turn.
11. **Banners and hints print on top of each other.** s121 t010: "Click Command again to give the order: Fire for
    effect" overlaps the FIRE FOR EFFECT banner. s121 t016: "The Ashen Vigil has nothing left to do this round: next
    ship." overlaps ENEMY TURN. s121 t032: four floating labels stack on one hex.
    Reviewer: "Text on top of text at the exact moment something important happens."
    Fix: one slot for the banner, one for the hint, never both in the same place; queue floating damage labels.
12. **The action row grows to nine small buttons in the first hour, one of them cut off.** s10 t031: Brace, Reload
    torp..., Turn, Board, Fire for effect, End ship, Next ship, Cancel, plus the main button. Board and Evasive burn
    (s10 t007) appear with no card. "Reload torp..." is truncated in every frame it shows (s10 t005, s121 t005).
    Reviewer: "Lots of buttons, no idea when Board or Brace is the right call."
    Fix: fit the label, and give each ability a one-line hover that says when to use it. I am guessing the hover does
    not exist; no frame showed one.

## 3. Not rewarding

1. **Seed 10's first reward is three copies of the same button.** s10 t022: "Scrap it +36", "Scrap it +25", "Scrap it
   +25". There is nothing to decide; I take the biggest number. Seed 121 got a real choice from the same fight (s121
   t018), I guess because of how the wrecks died ("blown apart" against "cut in two by a lance"), which the screen never
   says.
   Reviewer: "My first loot screen was pick 36, 25 or 25 credits."
   Fix: always offer at least one strip option after Battle 1, or say on the wreck line "blown apart: nothing to strip.
   Lance or boarding kills leave parts." so the flat reward teaches something. Pattern: Slay the Spire never shows a
   reward screen without a real pick.
2. **Credits with nothing to want yet.** s10 t022 pays +44 and +36; the map then shows "Credits 200" (s10 t023) with no
   price in sight. I lost a frigate and a command point (6/10 to 5/10) and got a number.
   Reviewer: "Won the fight, lost a ship, got 80 credits and no idea what 80 credits buys."
   Fix: on the reward card show what the total can now buy ("200 credits: enough to repair X or refit Y"), or put one
   priced item on the first map screen. Pattern: FTL scrap feels good because the store price list is in your head by
   the second jump.
3. **Victory in Battle 2 passes in a blink and for a different reason than the goal.** s10 t037: VICTORY while the
   objective reads "hold the relay 0/3 (them 1/3)"; the log says the enemy fleet broke and fled. I won without touching
   the objective and the screen does not say which rule won it. No frame shows a summary before the promotions card.
   Reviewer: "I won a hold-the-point mission without ever holding the point. OK?"
   Fix: the victory banner names the cause ("Enemy fleet routed" or "Relay held") and one line of what the win earned.
4. **The promotion perks are small print.** s10 t038: "Steady hand: ignore the first 2 hexes of long-range penalty" or
   "Rapid cycling: ability cooldowns -1". No frame taught a long-range penalty, so the first perk means nothing to me;
   the second I can feel (torpedo cooldown 2 to 1, s10 t029).
   Reviewer: "Level-up perks are plus-two-percent stuff. No build excitement."
   Fix: say the perk in terms of the ship ("Everwatch torpedoes reload in 1 round, not 2") and make first promotions
   the kind that change a habit. Pattern: Hades boons and Slay the Spire relics get named in reviews because each one
   changes how you play, not a number.
5. **The loss notice contradicts itself, which blunts both the sting and the relief.** s10 t022 says in red "Lost: the
   Cold Reckoning and Lucan Ivers", and the strip at the bottom of the same screen says "Lucan Ivers escaped in a
   lifepod, wounded, and will take command of your next hull". The title promises "Every hull you lose stays lost, and
   so does its captain" (title still).
   Reviewer: "The game told me my captain was dead and alive on the same screen."
   Fix: one line: "Lost: the Cold Reckoning. Captain Lucan Ivers escaped, wounded." Keep "lost" for real deaths.
6. **The first battle win is flat because the admiral says the same line whatever happened.** "The line held. It always
   holds." after a win that cost a ship (seed 10 trace, Battle 1) and after a clean win (Battle 2). "Fire for effect.
   Every gun, every deck, now." is word for word the same in all four battles.
   Reviewer: "Great voice lines, about six of them."
   Fix: a costly-win line and two or three variants per bark. Taste item: Ryan picks.

## 4. Confusing

1. **Where is the relay, and why did my count stop?** The objective reads "hold the relay 0/3 (them 0/3)" (s121 t021).
   The board has pale outlined hex patches (s121 t026 bottom left, s121 t021 top) and a "Relay" key with four coloured
   squares (s121 t021), but nothing on the board is labelled Relay. My count went 1/3 (s121 t029), stayed 1/3 with "The
   relay is contested" once in the log (s121 t032), reached 2/3 (s121 t035) and never moved again through round 7 (s121
   t038, t040). I could not work out which hexes count or what "unopposed" needs.
2. **"1 enemy can reach this hex now 0"** (s10 t007), "4 enemies can reach this hex now 0" (s10 t027), "now 4" (s10
   t031). I guess the first number is after the enemy moves and "now" is this instant, but it reads like a typo.
3. **"Hits the prow shield (pool 26/26, this side catches 22)"** (still 03, s10 t010). Pool, side and catches are three
   new words in one line. The Shields card (s10 t006) says "all four sides share it", which made it harder, not easier.
4. **"burn 3 movement to the ghost"** (s10 t008, s121 t009). What ghost? I guess it is the preview outline of my ship.
5. **The weapon rows.** Letters P, S, F, T, a thin line with a diamond on it, then Ready, Out, No shot, Fired, CD 2 or
   Offline (s10 t008, t009, t028). I do not know what the line measures or how "Out" differs from "No shot". After
   Brace, all three guns say "Fired" though none fired (s10 t026).
6. **"Heat 0"** in the top right of every battle (s10 t004) and the small coloured squares after "Engagement" and
   "Relay" (s10 t025). Never explained in any frame; the squares turn out to be a terrain key only if clicked (still 04).
7. **Cores, signals, protocols.** The aspect screen ends "Cores in range: V-2 Vyre, the Storm Queen, R-5 Rook, the
   Breaker... Win battles carrying their signal to earn their protocols" (s10 t001) and map nodes "Pay Signal of Rook"
   (s10 t003). Three stacked terms before my first click, and I was never shown a protocol in any frame.
8. **The map symbols.** Diamonds, squares, dotted circles, crossed circles and small red marks (s10 t003, s10 t023) with
   a "Map key" link in the corner. I could guess fights and stations, not the rest. "War zone: reinforcements; fights
   pay 20% more" and "Ion season: shields recharge 25% slower" (s121 t003) are clear and good.
9. **The ram.** s10 t037 log: "Hullbreaker raider rams Everwatch at full speed: 34 to its prow". The destroyer went
   from 76 to 42 hull in one enemy move. No frame warned me a ram was coming or told me I could have dodged it. I am
   guessing there is no warning; if there is one it was between frames.
10. **Reward text for another faction.** "tow an eligible hull if you fly with the Hullbreakers" (s10 t022, s121 t018).
    I fly the Sunward Crusade. Is this telling me I am missing out?
11. **"Easy" with one of four pips** on a fight that puts 2 ships against 4 (s10 t023, s10 t025). I do not know what
    the rating counts.

## 5. Your review

**Thumbs up, barely.** Under the pop-ups is a sharp broadside tactics game: facing matters, the damage preview is honest,
ships lose prows and engines, captains have names. But the first hour fights you. Tiny ships, a wandering camera, the same
lance cutscene on repeat, a tutorial fight that eats your frigate, and a DEFEAT card that explains nothing after I sat one
round from winning. Fix the camera and tell me why I lost and this is an easy recommend.
