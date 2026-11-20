# UI/UX seat, Fable leg (council Nov 20 2026, build 25adec31)

Findings only. Nothing was edited.

## What I looked at

- All 8 stills in pack/stills/.
- run_seed10: frames t001 to t010, t012, t014, t016, t018, t020 to t025, t027, t029, t031, t033, t035 to t038.
- run_seed121: frames t001 to t004, t006, t008, t010, t012, t014, t016, t018 to t020, t022, t024, t026, t028, t030, t032,
  t034, t036, t038 to t040.
- Both traces, docs/playbooks/screens.md, RULEBOOK section 9, the Neon front-end audit, and the godot/ui and
  scenes/battle code lines cited below.

Picture names are short: "s10 t008" is pack/run_seed10/PT25adec3_seed10_t008.jpg, "s121 t016" is the same in run_seed121,
"still 03" is pack/stills/PT25adec3_battle_03_3_enemy_clicked.jpg.

Not judged, and why:

- Larger text. The pack has no frame at a larger UI scale, and the front-end set (setup, faction desk, settings, help,
  progression) failed to capture. I make no claim about them. Neon's larger-text items stand as written until the rerun.
- The script's moves. Where a finding could be the script and not the screen, it says so.
- Video frames are compressed. I only quote text I could read in at least one clean frame.

## Findings, worst first

### 1. Battle 2 asks you to "hold the relay" and never shows where the relay is

- Screen: Battle 2, the whole fight. Pictures: s121 t022, s10 t025, s121 t032, s121 t040.
- What is wrong: the goal is one small grey line at top left, "Objective: hold the relay 0/3 (them 0/3)". The relay is one
  hex with a 30% gold fill (godot/render/board.gd:395 to 396). It has no label on the board, no row in the terrain key
  (battle.gd:3924 lists only exit, transport exit and perimeter), and no hover name (battle.gd:3900 only names those same
  three zones). I could not find the gold hex in any Battle 2 frame. The "Objectives" teaching card (s121 t022) points at
  the text line, not at the hex: "Look beside the round counter at the top left for this fight's goal." "Unopposed" on
  the map rail (s10 t023) and "(them 1/3)" are never explained, and the enemy's count is the same grey as the rest.
- Who feels it, when: every new player, second fight of every run. Seed 121 lost this fight at 2/3 (s121 t040).
- Fix: label the hex on the board ("Relay", same style as a ship name), give it a row in the key and a hover that says the
  rule in one sentence, and have the Objectives card glide the camera to it once. Show "them 1/3" in the damage colour
  when the enemy is ahead.

### 2. The target block says "No ready gun can reach it" while the action box says BURN AND FIRE

- Screen: battle shelf with an out-of-reach enemy picked. Pictures: s10 t008, s10 t014, s10 t018.
- What is wrong: three texts disagree at once. Under the target name: "No ready gun can reach it." Left of it: "Out of
  reach: it burns 3 movement and fires 1 of 1 guns on the way." The ember box: BURN AND FIRE. The gun rows say "Out". The
  cause is that the target line always uses the stand-still reason (battle.gd:5306) even when an attack move is planned
  (battle.gd:4532 to 4533). In still 03 the plain "cannot reach" case prints the same sentence three times (top centre,
  hover box, shelf).
- Who feels it, when: every player, most turns in the first rounds, because fights open out of range.
- Fix: when an attack move exists, the target line reads "In reach after a 3 hex burn: 1 of 1 guns" and the gun rows show
  the odds from the stop hex. When nothing can reach, say it once, on the shelf.

### 3. Retreat is one click, next to Menu, with no confirm and no cost shown

- Screen: battle, top right. Pictures: s10 t004 (Retreat sits about 50 px left of Menu). Code: ledger.gd:361 to 362 sends
  "retreat"; battle.gd:4182 to 4187 ends the battle at once.
- What is wrong: the most costly button on the screen has the same weight as Menu, sits beside it, and fires on a single
  click. Its hover only says "Pull the fleet out of this battle." Nothing says what a retreat costs the run. The same
  goes for "Quit the game" in the battle menu (still 06; battle.gd:4193), which sits one row under "Copy a problem
  report".
- Who feels it, when: anyone who misses Menu by a few pixels. Rare, but it throws away a fight, and a new player cannot
  know what else it throws away.
- Fix: move Retreat into the Menu (screens.md already says the menu holds "retreat and quit", ledger.gd:357), or keep it
  and open the standard near-black dialog: what it costs, Retreat, Stay.

### 4. The hover box stays up through cut-ins, sits on top of ships, and repeats the shelf

- Screen: battle, target and move hover box. Pictures: s10 t010, s10 t035, s121 t038 (box still up inside the letterbox,
  still saying "Click again or Enter to fire" while the shot plays); s10 t008 (box covers the acting ship's name); s121
  t030 (box covers the acting ship and the fight); s10 t036 (box is 12 lines and runs down into the shelf).
- What is wrong: letterbox() hides the shelf, the log and the key but not the hover box (hud.gd:1267 to 1269). After a
  click the box keeps the full target sheet on the board while the shelf's Target block already shows the same odds and
  damage (s10 t012: 76% and "11 to shields, 0 to hull" in both). In s10 t036 it also carries a three line lesson ("More
  evasion means a lower hit chance; point defence can stop shots...").
- Who feels it, when: every player, every shot.
- Fix: hide the box when a cut-in starts. Once a target is picked, let the shelf carry it and drop the box, or shrink it
  to the two lines the shelf does not have. Never place it over the ship that is up or the target. Move the lesson text
  to the gun's own hover.

### 5. Two messages are drawn on top of each other at the top centre

- Screen: battle, top centre. Pictures: s121 t016 ("ENEMY TURN" with "The Ashen Vigil has nothing left to do this round:
  next ship." printed across it), s121 t010 ("FIRE FOR EFFECT" with "Click Command again to give the order: Fire for
  effect" across it, both half under the letterbox bar), s10 t016 ("ROUND 5" touching the bar).
- What is wrong: the big banner and the small notice share one spot (the notice is fixed at 124 px, hud.gd:622) and
  nothing stops both showing. Neither is hidden by the letterbox. This breaks RULEBOOK 9.4, "no overlaps".
- Who feels it, when: every player, at most turn changes and at every Command.
- Fix: one message slot with a queue, or put the notice under the banner's box. Hide both in cut-ins.

### 6. The order buttons change place and size from one state to the next

- Screen: battle shelf, right block. Pictures: s10 t005 (End ship is the big box; Brace, Reload, Turn; Fire for effect,
  Next ship), s10 t004 (Move here is the big box; End ship is now row 2, middle; Cancel added on row 3), s10 t007 (End
  ship row 2, middle; Next ship gone), s10 t031 (three rows of small text: Board appears and pushes Fire for effect, End
  ship and Next ship along one place each).
- What is wrong: the grid is filled in list order (ledger.gd:694 to 697), so each new order shifts every later one, and a
  longer list drops to a smaller glyph and tighter rows. "Reload torp..." is cut with dots in every frame it appears
  (s10 t005, s10 t014), which screens.md section 5 lists as a trap. Cancel is back as a button though screens.md moved
  it to Esc.
- Who feels it, when: every player, every ship, every turn. The pointer cannot learn where End ship is.
- Fix: fixed slots. End ship and Next ship always in the same two cells, the ship's own orders always in the same row,
  empty cells left empty. Write "Reload" (the hover has the rest).

### 7. Almost every log line is cut off before the number

- Screen: battle log, three lines. Pictures: s10 t008 ("...18 to prow shie..."), s10 t014, s10 t020, s121 t030, s121
  t040 ("19 hull, critica...").
- What is wrong: the log is the only place the enemy's turn is told in words, and its lines end in dots just where the
  damage and the result are. screens.md section 5: "Cut-off sentences with dots. Give text its room or write it shorter."
- Who feels it, when: every player, every enemy turn.
- Fix: shorter sentences built for the width ("Cordon destroyer: ion cannon, Cold Reckoning, 18 shield"), or wrap to two
  lines for the newest entry only.

### 8. The cards between fights are still in the retired look

- Screen: Victory, Promotions. Pictures: s10 t022, s121 t018, s10 t038.
- What is wrong: every in-run dialog is built on shell_panel, "chamfers, scanline, bevel, brackets"
  (campaign_ui.gd:2251), with a wide-spaced title face, boxed key badges [1] [2], green and red text. The battle before
  it and the map after it are orders sheet. RULEBOOK 9.1 says one interface; screens.md says no key badges and "dialogs
  are near-black squares with a hairline edge". The Defeat card (s121 t040) is already in the right style, so the two
  end cards of one fight do not match. Neon's audit and issue 1217 covered the start screens only; this is the same
  fault one step later.
- Who feels it, when: every player after every won fight. It is the reward moment.
- Fix: rebuild the modal shell from the orders kit: square near-black dialog, Big Shoulders head, keys after words in
  the figure face, one ember box.
- Check, not a claim: trace seed-10 shows three separate picks after Battle 1 (takeSalvage, takeBoon, takePerk at frames
  5239, 5283, 5327). RULEBOOK 9.13 says "one prize screen, one confirm". Issue 1177 may have changed that on purpose; the
  Board should say which holds.

### 9. The Victory card buries the loss, offers a choice that is not one, and talks about things that are not there

- Screen: Victory card. Pictures: s10 t022, s121 t018.
- What is wrong:
  - "Lost: the Cold Reckoning and Lucan Ivers." is one small red line under the credits. The title screen promises
    "Every hull you lose stays lost, and so does its captain" (title still); the card gives the loss less room than a
    25 credit scrap.
  - In s10 t022 all three wrecks offer only "Scrap it" for 36, 25 and 25 credits. That is three buttons for one answer.
  - The intro says "tow an eligible hull if you fly with the Hullbreakers" to a Sunward player. The Rewards tip card
    beside it explains protocols, refit modules, captured ships, the command point limit, Strip, Ransom and rerolls;
    none of them are on the card. RULEBOOK 9.3, say less.
  - The rewards have no words for what they change: "Battery loaders stripped ... and stowed in the hold" (s10 t038
    foot) never says how to fit them.
- Who feels it, when: every new player, first win.
- Fix: loss first, as a named row with the ship and captain. When only scrap is on offer, take the best one and show it
  as a line. Only describe options that are on this card. End the strip line with where the part goes ("fit it at a
  shipyard").

### 10. The end of a battle does not say why it ended, and the shelf shows the wrong ship

- Screen: battle end. Pictures: s10 t037, s121 t040.
- What is wrong: in s10 t037 the fight ends by rout while the goal line still reads "hold the relay 0/3 (them 1/3)"; only
  the log says "The enemy fleet breaks and flees." The shelf has switched to a destroyed enemy raider (hull 0/34) with a
  live hint, "Torpedoes inbound: move 3 or more hexes from its marked hex to dodge." In s121 t040 the Defeat card gives
  counts and a quote but not the cause (fleet destroyed, with the relay at 2/3) and not what Continue leads to. The shelf
  shows an enemy gutship.
- Who feels it, when: every player, every fight end; worst on the first loss.
- Fix: one reason line on the end card ("Their fleet broke and fled", "Your last ship was destroyed"). On Defeat, say
  what comes next ("Continue to the run record"). Clear the shelf at battle end.

### 11. The terrain key is three colour squares with no words, and its colours do not match the board

- Screen: battle, top right key. Pictures: still 01 (closed: "Engagement" and three squares), still 04 (open), s10 t025.
- What is wrong: closed, the key is a title that sounds like a status ("Engagement", "Relay") and unlabelled squares;
  nothing says it can be clicked. Open, the violet square is "Nebula" while the nebula on the board is rose red (still
  04, s10 t029). Enemy brackets are also violet (s121 t012). The shelf hint says "Click an enemy with a red ring to
  target it" (s121 t006, battle.gd:4568) when no enemy is in reach, and the only red ring in the pack is around the
  player's own cruiser while it is being shot (s121 t028, s121 t034). Check: I could not confirm from pictures what ring
  a hittable enemy gets.
- Who feels it, when: new players in the first two fights, when they try to learn what the colours mean.
- Fix: closed state reads "Terrain key" with the names beside the squares if they fit, or a caret. Take the square
  colour from what the board draws. Make the hint match the ring and only show it when a target exists.

### 12. The first teaching card is five rules in one box, and cards open while the enemy is moving

- Screen: battle teaching cards. Pictures: s10 t004 and s121 t004 ("Moving and facing"), s10 t006 ("Shields and hull"
  during "Enemy turn"), still 04.
- What is wrong: "Moving and facing" (battle.gd:71) is about 60 words: plan a move, turn keys, +10 for standing still, -5
  for moving 3, Brace and its three effects, and "Glasswright ships cannot Brace" to a Sunward player on turn one. It
  sits top right, away from the hexes it talks about. "Shields and hull" appears during the enemy's turn (s10 t006),
  when the player is watching ships, and describes bars at the far bottom left. Neon skipped the cards because issues
  1144 and 1147 were in flight; this is the result as built on Nov 20.
- Who feels it, when: every new player, first three minutes.
- Fix: one rule per card, shown when it matters (the Brace rule the first time Brace is worth using), and placed next to
  the thing it names. Drop the other-faction sentence. Hold a card until the player's own turn.

### 13. Flagship aspect screen: a cut-off sentence, four extra colours and words nobody has met

- Screen: Choose its aspect. Pictures: s10 t001, s121 t001.
- What is wrong: Bulwark ends "enemy ships within 4 hexes that can fire on it must." (s121 t001; the text is that way in
  rules/data/tables.json), which reads as a sentence that lost its end. "Cores in range" lists four names in four
  colours (cyan, red, violet, gold) with "Win battles carrying their signal to earn their protocols": cores, signals and
  protocols have not been introduced, and the orders sheet allows one accent. The three aspect cards do not look
  clickable (no hover or key shown) and the only button on screen is the disabled "Pick an aspect to launch".
- Who feels it, when: every new player, the first decision of the first run.
- Fix: finish the sentence ("must fire on it"). Move the cores line behind a hover or to the map where signals first
  pay out. Give the cards keys 1 to 3 and a visible hover.
- The patron colours may be Ryan's choice: if so, "reopen: Ryan's call".

### 14. The two loading screens and the title wordmark use other typefaces

- Screen: loading and title. Pictures: s10 t002 ("Preparing the sector..." in the engine's default face, sentence case,
  three dots; main/load_screen.gd:20 to 21 sets no font), s10 t024 ("PREPARING THE BATTLE" in Big Shoulders;
  hud.gd:1280), title still (gold wide-spaced wordmark over an ember button).
- What is wrong: two covers seen a few seconds apart do not match. On the title, Neon's point 1.2.2 (gold wordmark
  against the ember button) is still true in this build after the kit rebuild, and the Credits still list seven font
  families (credits still).
- Who feels it, when: every player, every run start. Small, but it is the first and second thing seen.
- Fix: load_screen.gd takes the kit's heading face and the same words pattern. The wordmark colour and face: Ryan picks.

### 15. Small text faults that read as bugs

- "4 enemies can reach this hex now 0" (s10 t027, s10 t031; battle.gd:3897). "now 0" means the count at the ship's
  present hex, but nothing says so. Fix: "4 enemies can reach this hex (0 where you are)".
- "Move 6 / 5" on the shelf (s10 t036, compressed frame; check on the PC). If a bonus lifts the pool, show "6 / 6" or
  "5 +1".
- Map: "Pays Signal of Rook" and "Hunt clock 0.5 of 4" (s10 t003, s10 t023) give a new player two unknown words and a
  half tick with no hover hint in view. The trace shows the c_map and c_clock cards fire, but neither is in a frame, so
  I only flag the wording on the rail.
- Who feels it, when: new players, first run.

## Good, keep these

1. **The shelf's Target block.** Big ember odds, "About 11 damage", then "11 to shields, 0 to hull" in words, and the
   action box renamed to the act itself, "FIRE THE SEAR REPEATER" (s10 t012, s121 t030). This is the clearest thing in
   the game.
2. **Plan, then confirm.** The move box says the cost, "0 of 3 guns bear on an enemy from here" and "Click to plan the
   move (nothing moves yet)" (still 02). A new player cannot waste a move by a stray click.
3. **The map rail.** Numbered routes on the left match numbered tags on the map, the picked route grows, one ember box
   with its key, difficulty in words, fleet hull at the foot (s10 t023, s121 t019).
4. **The fleet strip.** Silhouette, name, bars, a hull figure that turns the damage colour, and a plain "Lost" (s10
   t018, s121 t040).
5. **The title screen after the kit rebuild.** Left column, one ember box, quiet links, the scene left open, and a
   two-line promise of what the game is (title still). Neon's main complaint there is fixed.

## Addendum: front-end screens (evidence only)

Added after the blind leg, which is unchanged above. Source: pack/frontend/, all 39 pictures viewed (35 screens and the
four F2 to F5 sheets). These are a Godot checkout capture at b557adc85, not the packaged 25adec31 build, so a fault here
is "true at b557adc85". Picture names are short: "F3_setup_larger" is pack/frontend/FE_b557adc85_F3_setup_larger.jpg.
The capture stamp covers the bottom left of every picture, so I make no claim about Back buttons or anything in that
corner. Neon's audit is taken as read; each item says what it adds.

### What these pictures do to the leg above

- **"Not judged: larger text" is now partly judged.** Title, Settings, the desk, the flagship page, Lineage and
  Progression hold at Larger with no overlap and no clipped button (F2_title_larger, F2_settings_larger,
  F3_setup_larger, F4_flagship_larger, F5_lineage_larger, F5_progression_larger). Neon's larger-text breaks (1.2.4,
  1.3.1, 1.4.1 orphan card, 1.6.4 lineage wrap) are not in these pictures. The one cost is finding A3 below.
- **Finding 13 confirmed and narrowed.** Confirmed: Bulwark still ends "...that can fire on it must."
  (F4_flagship_hegemony), and the four-colour "Cores in range" line is on every faction's page (F4_flagship_chorus,
  F4_flagship_ithar). Weakened: the picked state is clear (F4_flagship_picked: outline, "PICKED", and the button becomes
  "Launch with Aspect of the Ram"). So "the cards do not look clickable" shrinks to "nothing invites the first click".
- **Finding 14 confirmed.** Gold wide wordmark over the ember box at both sizes (F2_title_normal, F2_title_larger);
  Credits still list seven font families (F2_credits_normal).
- **Finding 8 strengthened.** The start screens are now one kit: square cards, hairlines, one ember box
  (F3_desk_voidsworn, F5_progression_legacy). That makes the chamfered Victory and Promotions cards (s10 t022, s10 t038)
  the odd ones out in the whole run, not one of several.
- Nothing here touches findings 1 to 7, 9 to 12 or 15.

### A1. How to play tells the player rules the battle screen does not follow

- Screen: How to play. Pictures: F5_help, F5_help_larger. Text: campaign_ui.gd:1869 to 1872.
- What is wrong: three statements disagree with the battle as built.
  - "Click an enemy to fire everything that can reach it". In battle the first click only targets and the box says
    "Click again or Enter to fire" (s10 t012; teaching text battle.gd:72).
  - "Every ship can move, turn and fire each of its weapons once per turn, in any order". The battle hint says "(ships
    move, then fire)" (battle.gd:4565).
  - "see the Helm panel". The KEEL shelf has no Helm panel; ledger.gd and hud.gd do not use the word, and screens.md
    moved those facts to the ship name's hover.
  Check, not a claim: "amber for the prow, teal for broadsides" for gun reach; the arcs in still 01 are one pale colour.
  The page is also one grey column of prose with no picture, and the section list on the left does not mark where you
  are. At Larger the last line is cut through the middle with no scroll cue (F5_help_larger).
- Who feels it, when: the new player who does the right thing and reads the help first, then finds the first click does
  not fire.
- Fix: correct the three sentences from the battle's own strings so they cannot drift (one source for both). One small
  picture per section. Mark the current section. Neon covered this page's layout only (1.6.1), not its words.

### A2. Lineage shows six live ember boxes while saying "0 branch picks ready"

- Screen: Lineage of Vex on a fresh profile. Pictures: F5_lineage, F5_lineage_larger. Code: campaign_ui.gd:2182 to
  2183, 2192.
- What is wrong: at Mastery 0/8 the page says "0 branch picks ready" and "One pick at each of levels 5, 6 and 7", yet
  every tier 1 skill carries an ember-outlined "Choose this skill" button that looks live. Six ember boxes on one page
  also breaks "one box per screen". The column heads read like debug text: "[+] Command: The Inherited Line", "[=]
  Fleet: Fleet", "[*] Flagship and line: Flagship and line".
- Who feels it, when: any player who opens Lineage from an admiral card before level 5, which is every new player.
- Fix: until a pick is ready, the button reads "Opens at level 5" in the quiet style. When a pick is ready, only the
  skills it can buy are ember. Heads become "Command", "Fleet", "Flagship".

### A3. Larger text removes the Command description from the admiral cards

- Screen: faction and admiral desk at Larger. Pictures: F3_setup_larger against F3_setup_normal. Code:
  campaign_ui.gd:654, 759 to 760.
- What is wrong: at Larger each card shows only "Command: Fire for effect"; the sentence that says what it does moves to
  an engine hover tip. The same pictures show a third of each card empty below the fleet row, so the words would fit.
  The players who ask for bigger text get less of it, and a keyboard or controller player cannot hover.
- Who feels it, when: anyone on Larger, at the main choice of the run.
- Fix: keep the sentence when it fits the card's height (it does here); only fall back to the hover when it does not,
  and make that fallback reachable by focus.

### A4. The 24 admiral cards are hard to tell apart, and each carries a meter a new player cannot read

- Screen: the six faction desks. Pictures: F3_desk_voidsworn, F3_desk_hegemony, F3_desk_corsair, F3_desk_chorus,
  F3_desk_ithar, F3_desk_deathless.
- What is wrong:
  - Every card shows "Mastery 0/8 0/6: next alternate fleet" and an empty bar. On a first run that is 24 empty meters
    and a phrase nobody has met.
  - The Command line is long and often the same words under a new name. "Every ship fires a free extra volley right now
    at the best target in range. Its normal shots this round still happen." appears as Fire for effect, Synchronized
    broadside, Spitting volley, Noon volley and Burning glass. The eye has to read 24 paragraphs to find the few real
    differences.
  - The line that does differ, the passive ("Broadside weapons deal +15% damage"), is the same size and weight as the
    rest.
  - Small things: the admiral quote under the cards is teal, a colour the orders sheet does not have; "SELECTED" takes
    the faction colour, which for the Hegemony is a pale blue next to glacier's shields-only blue (F3_desk_hegemony);
    the Sunward rule ends in designer wording, "Carrier base prices have a 10% premium before rounding".
- Who feels it, when: every new player at the first screen with a real choice. Neon asked for crests, portraits and
  blurbs (now in); this is what is left once they are there.
- Fix: hide the mastery row until the admiral has any mastery. Make the passive the card's one bright line. Shorten the
  Command to its name plus five or six words, full text on hover and focus. Quote in the second text strength.

### A5. Run options opens on a test switch with a checkbox that can barely be seen

- Screen: Run options drawer. Pictures: F3_run_options, F3_run_options_keys. Code: campaign_ui.gd:877 to 879.
- What is wrong: on a first run the drawer holds two things. The first is "Test new battle maps, faster ships and
  longer gun ranges", a trial switch that changes the rules of the whole run, shown to a player who has not seen the
  normal rules. Its box is a dark square on a dark panel: I cannot tell on from off in either picture. It is still the
  raw engine CheckBox Neon flagged (1.4.5) and the only control here not built from the kit. The second, Heat, is locked
  and its sentence is the dimmest text in the set.
- Who feels it, when: any new player who opens the drawer; the risk is switching the trial on without knowing.
- Fix: a kit row with an On/Off button like Settings uses (F2_settings_normal), labelled as a trial, and off the first
  run's path until one run is finished. Whether the trial is offered to new players at all: Ryan's call.

### A6. Leftovers: card title face, Credits noise, and six patron colours

- Card titles on Progression and Lineage ("Carrier hulls", "Ledger of Arcs", "Level 1: Alternate fleet") and the stat
  heads ("RUNS LAUNCHED") are in a squarer face than the Barlow names on the desk cards (F5_progression_legacy,
  F5_lineage, against F3_desk_voidsworn). The primary button uses a third, wide face ("New run", "LAUNCH THE CRUSADE",
  "Done"). RULEBOOK 9.15 names one font set. Check on the PC which faces these are; I am reading them from pictures.
- Credits print every track twice, once as a headed line and again as a quoted line with two full web addresses
  (F2_credits_normal). At Larger the list is cut through a line at the bottom with no scroll cue (F2_credits_larger).
- Core sync shows six patrons in six text colours, with a "Listening 0 / 4" in each colour (F5_progression_favour). With
  the cores line on the flagship page that is the same many-colour habit on two screens. If the patron colours are
  Ryan's pick: "reopen: Ryan's call".
- Who feels it, when: everyone, lightly. These are polish, ranked last on purpose.

### Good here, keep

- Settings: four plain groups, one control column, one ember Done, nothing cut at Larger (F2_settings_normal,
  F2_settings_larger). Neon's 17-row wall is gone.
- The desk: equal cards, buttons on one line, ship silhouettes for the starting fleet, the faction's rule in two
  sentences, one launch box named for the faction (F3_desk_corsair).
- The flagship page: the ship is the picture, and the button names what you picked (F4_flagship_picked).
