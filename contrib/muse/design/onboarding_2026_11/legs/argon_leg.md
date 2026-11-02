Chair header: Argon leg for Voidsworn Job 4 onboarding design. Model: Gemini Argon High. Gates verified before sending and after sending, with the picker and the prompt bar both reading Argon High. Relaunched after the Nov 2 1:10 AM rate limit reset. Reply captured in session without a reload.

1. Headline

Sector 1 onboarding teaches through live play across the first three battles and the campaign stops between them, letting the F1 bottom card guide button clicks while tip cards explain only the survival rules, hit chances, and campaign choices that the screen cannot show on its own. The single most important sequencing choice is withholding defensive facing, threat shading, close action, and reinforcement rules until after the player completes their first move and first shot in Battle 1, preventing a front-loaded pileup of cards on turn one and spacing advanced combat ideas across Battles 2 and 3. Every prompt uses plain words with exact numbers, retires only after the player completes the taught action rather than vanishing on first sight, and leaves Sector 1 enemy budgets and lethality untouched in full compliance with R62.

2. Prompt Schedule

The existing code in battle.gd ships 10 battle tips, while the wave 4 campaign assembly (contrib/muse/reviews/tutorial_assembled_2026_10_29.md) adds 16 campaign tips, creating 26 total prompts. Because the F1 turn-flow pass now provides the gold UP tag, the breathing gold ring, the three-step bottom card, the blue reachable-hex outline, the ghost move preview, the two-click firing preview, and the automatic end-of-turn handoff, three shipped battle tips (start, turns, and half of fired) duplicate what the screen already says every turn.

By cutting those F1 duplicates and merging overlapping campaign topics, the schedule below compresses 26 prompts down to 14 prompts across the first three battles and between-battle screens. Prompts 1 through 12 cover core combat and Sector 1 map flow. Prompts 13 and 14 exceed the baseline target of 12 and are explicitly justified at the end of this section.

Prompt 1: Moving, Facing, and Hit Chance (tip_move_face, replaces start and select)

Moment: Battle 1, Round 1, Player Activation 1.

Trigger condition: select (fires when Battle 1 opens and the F1 system hands the first ready ship to the player).

Where it appears: Battle tip card (hud.show_tipcard), paired with the persistent F1 bottom card sentence.

Exact prompt text: "Click any blue hex to plan a move for your active gold-ringed ship, and press Q or E to turn its nose before you confirm with Enter. Staying in the same hex makes your ship easier to hit (+10% enemy hit chance), while moving 3 or more hexes makes it harder to hit (-5% enemy hit chance). If you want to hold position, click Brace on the bottom card to cancel the +10% sitting-still penalty."

Prompt 2: Targeting and Weapon Control (tip_firing, replaces target)

Moment: Battle 1, Round 1, Player Activation 1 (Step 2: Fire).

Trigger condition: target (fires the first time a player ship has an enemy inside at least one weapon firing arc after confirming a move or before moving).

Where it appears: Battle tip card (hud.show_tipcard).

Exact prompt text: "A red ring marks an enemy you can shoot right now. Click the enemy once to preview your hit chance and expected damage without firing, then click a second time (or press Enter) to fire every ready gun that points at that target. Press number keys 1 through 6 if you want to fire one weapon at a time instead of all at once."

Prompt 3: Alternating Turns and Ending a Ship (tip_alternating, replaces fired)

Moment: Battle 1, Round 1, immediately after the player fires their first weapon.

Trigger condition: fired (fires once the first player weapon shot resolves in Battle 1, provided the ship either still has an action left or is about to hand off).

Where it appears: Battle tip card (hud.show_tipcard).

Exact prompt text: "Sides take turns moving and firing one ship at a time until every ship has acted once, then a new round begins. If your ship has nothing left to do, it ends its turn automatically; if you want to save remaining guns or movement, press Space (End ship) to pass control and let the enemy take their turn."

Prompt 4: Shields, Facings, and Hull Damage (tip_shields_hull, replaces move)

Moment: Battle 1, Round 1, start of Player Activation 2 (right after Enemy Ship 1 finishes acting).

Trigger condition: after_first_enemy_turn (new condition: round == 1 and enemy_activations_completed >= 1 and player ship is handed control).

Where it appears: Battle tip card (hud.show_tipcard).

Exact prompt text: "Four cyan shield bars wrap your ship (front, rear, left, and right); shields soak incoming shots and recharge every round. Once a shield side is empty, shots hit your amber hull bar, and hull damage stays until you pay for repairs at a shipyard. Use Q and E when moving so your fullest cyan shield faces the enemy guns."

Prompt 5: Enemy Threat Map and Full Grid (tip_threat, replaces threat)

Moment: Battle 1, Round 2, start of the first player activation in the round.

Trigger condition: threat (round >= 2 when a player ship is active at the start of the turn).

Where it appears: Battle tip card (hud.show_tipcard).

Exact prompt text: "Press R to toggle the threat map, which shades every hex that enemy guns can reach on their next turn (darker shading means more incoming damage waiting in that hex). You can also hold the grid key at any time to reveal the full hex board beyond your active ship."

Prompt 6: Post-Battle Rewards, Salvage, and Prize Ships (c_reward, combines c_credits, c_salvage, c_prize, and lint-corrected c_boon)

Moment: Between Battle 1 and Battle 2, on the Post-Battle Reward Screen.

Trigger condition: reward_screen_open (fires the first time the post-battle reward screen opens after winning a fight).

Where it appears: Campaign tip card anchored at the top-right of the Reward Screen.

Exact prompt text: "Victory pays out credits for shipyards, weapon or hull salvage upgrades, and sometimes a captured enemy prize ship. If you claim a prize ship when your command points are full, it goes into your reserve hold so you can swap it into your active fleet later. Reward rerolls are only available when an upgrade or event unlocks them, and each reroll costs credits."

Prompt 7: The Sector Map and Stop Types (c_map, combines lint-corrected c_map, c_nodes, and c_elite)

Moment: Between Battle 1 and Battle 2, upon entering the Sector 1 Map Screen.

Trigger condition: map_screen_open (fires when the campaign map screen initializes after Battle 1 rewards are closed).

Where it appears: Campaign tip card on the Sector Map Screen.

Exact prompt text: "Pick your next stop along the connected star lanes to work your way toward the sector boss at the end of the map. Stops along the way include ordinary fights, events, rest stops, shipyards, and at least one elite fight on a route you can choose. Elite fights pit you against tougher enemy fleets in exchange for stronger salvage, relics, and extra credits."

Prompt 8: The Nemesis Clock (c_clock)

Moment: Between Battle 1 and Battle 2, on the Sector 1 Map Screen right after Prompt 7 is dismissed.

Trigger condition: map_clock_ready (fires on the map screen once c_map is dismissed and the player hovers any reachable stop).

Where it appears: Campaign tip card near the top map clock readout.

Exact prompt text: "Every jump advances the pursuing enemy clock at the top of the map. Taking extra jumps to visit side stops lets you gather more credits and repairs, but if the clock runs out before you clear the sector, pursuit forces will catch and reinforce the fights ahead."

Prompt 9: Close Action: Ramming and Boarding (tip_close, replaces close)

Moment: Battle 2 (against Hullbreakers), when a player ship closes to point-blank range.

Trigger condition: close (fires when the active player ship can legally execute a ram dead ahead with X or board an adjacent enemy hex with G).

Where it appears: Battle tip card (hud.show_tipcard).

Exact prompt text: "At close range you have two physical attacks: press X to ram an enemy ship sitting dead ahead in your forward line, or press G to send boarding crews into an enemy ship in an adjacent hex. Winning a boarding action captures the enemy ship intact for the rest of the battle and lets you claim it afterward."

Prompt 10: Admiral's Command (tip_resolve, replaces resolve)

Moment: Battle 2 (or first time ready in Battle 1/2), during a player ship activation.

Trigger condition: resolve (fires in Battle 2 or later the first time the Admiral's Command button is charged and glowing gold).

Where it appears: Battle tip card (hud.show_tipcard).

Exact prompt text: "Your Admiral's Command button glows gold when ready and can be triggered once per battle. Its effect grows stronger for every round you wait before using it, and it also gains power if you lose a friendly ship during the fight."

Prompt 11: Shipyards, Rest Stops, Refit, and the Hold (c_shipyard, combines lint-corrected c_shipyard and c_regroup)

Moment: Between Battle 2 and Battle 3 (or whenever the player first visits a Shipyard or Rest Stop).

Trigger condition: shipyard_or_rest_open (fires the first time either the shipyard screen or rest stop screen opens).

Where it appears: Campaign tip card on the Shipyard or Rest Stop Screen.

Exact prompt text: "Shipyards and rest stops let you spend credits to repair amber hull damage before the next fight. Use Refit at a shipyard to swap weapons and hull upgrades between your ships, or use the Hold to move spare prize ships between reserve storage and your active combat fleet."

Prompt 12: Battle Objectives and Reinforcements (tip_objective_reinforce, combines objective and reinforcement warning)

Moment: Battle 3 (or first fight featuring a non-rout objective or scheduled reinforcements).

Trigger condition: objective_or_reinforce (fires at the start of Battle 3 when objective != rout, or the moment the first F1 reinforcement banner completes in Battle 2 or 3).

Where it appears: Battle tip card (hud.show_tipcard).

Exact prompt text: "Check the top bar for this fight's goal: when the goal is not simply destroying all enemies, completing that task wins the battle immediately even if enemy ships remain. Watch the map edges when the reinforcement banner flashes, as newly arrived ships enter at the marked edge and join the turn order on the next activation."

Prompt 13: Run Tally, Defeat, and Renown (c_loss, combines lint-corrected c_loss and c_renown)

Moment: End of Run 1 (upon defeat or victory at the Run Summary Screen).

Trigger condition: run_summary_open (fires when the run summary screen opens at the end of a run).

Where it appears: Campaign tip card on the Run Summary Screen.

Exact prompt text: "Sector 1 is built to be lethal, and losing your first run is an expected part of your faction's story. Your run results tally at the end of a run, converting every battle won and sector cleared into permanent Renown and admiral experience for your next launch."

Prompt 14: Skill Trees, Respec, and Heat (c_tree_heat, combines lint-corrected c_tree and c_heat)

Moment: Pre-Run 2 Setup (Admiral Skill Tree and Heat Selection Screen).

Trigger condition: admiral_setup_open_with_xp (fires the first time the player opens the pre-run admiral setup screen with unspent XP or unlocked Heat).

Where it appears: Campaign tip card on the Admiral Setup / Skill Tree Screen.

Exact prompt text: "Spend admiral experience between runs to unlock permanent skill tree perks, or pay to respec and reassign your points between runs. Raising Heat increases enemy difficulty for the run ahead and boosts your experience payout: each point of Heat grants +2 XP to the admiral you fly and +1 XP to your faction's shared shadow pool."

Justification for Prompts 13 and 14 (Exceeding 12 by 2 Prompts):
A roguelite intended to kill first-time players in Run 1 (per R62) has two distinct onboarding phases: surviving combat inside a run (Prompts 1 through 12) and understanding why a lost run still advances the account (Prompts 13 and 14). Cramming end-of-run tallying, skill tree respec timing, and exact Heat XP math (+2 XP to the flown admiral, +1 XP to the shadow pool) into Prompt 7 on the Sector 1 map would create a massive wall of text about meta-progression before the player has even fought Battle 2. Splitting meta-progression into two short cards at the exact moment Run 1 ends (Prompt 13) and Run 2 begins (Prompt 14) keeps every card under 60 words while fixing the lint errors in items 116 through 119.

3. Fade Rules

The current _tutorial() function in battle.gd marks a tip ID as seen inside user://battle_opts.json under the "tips" array the instant hud.show_tipcard displays it. That sight-only persistence is brittle: if a player accidentally clicks past a card or quits Battle 1 on turn one, they never see the tip again for the life of their profile.

1. Action-Gated Retirement (How Each Prompt Retires):
Instead of retiring when shown, each prompt transitions through two states: shown_this_session (preventing spam on the current turn) and retired (persisted to disk).

Action-verified battle prompts (tip_move_face, tip_firing, tip_alternating, tip_threat, tip_close, tip_resolve): Retire permanently in user://battle_opts.json only when the player either performs the taught action (confirms a move or Q/E rotation for tip_move_face; fires a shot for tip_firing; ends a ship with Space or auto-end for tip_alternating; presses R for tip_threat; uses X/G or finishes a close-range turn for tip_close; triggers Admiral's Command for tip_resolve) OR explicitly clicks the "Got it" dismiss button on the card. If a player closes the game mid-turn without clicking "Got it" or completing the action, the card re-triggers next session.

Observation battle prompts (tip_shields_hull, tip_objective_reinforce) and Campaign prompts (c_reward, c_map, c_clock, c_shipyard, c_loss, c_tree_heat): Retire permanently in user://battle_opts.json only when the player clicks "Got it" on the tip card or completes the screen action (picking a reward, selecting a map stop, leaving the shipyard, or starting Run 2).

2. Replacing the user://battle_opts.json Persistence Schema:
To fix the shipped naming trap where "move" holds shield text and "select" holds movement text, replace the flat "tips" array of old IDs with a dictionary mapping the new unambiguous IDs to completion Unix timestamps ("tips_seen": {"tip_move_face": 1793580000, ...}), alongside "last_played_ts". On load, a one-time migration maps old keys ("select" -> "tip_move_face", "move" -> "tip_shields_hull", "target" -> "tip_firing", "fired" -> "tip_alternating") so existing profiles do not lose their settings, while resetting only any tip whose new content was never completed.

3. Returning-Player Behaviour (14-Day Inactivity Refresh):
When the game boots and loads user://battle_opts.json, it compares the current Unix timestamp against "last_played_ts". If 14 or more days have passed since the player last launched a battle (and "tipsOff" is false), the system does not wipe all 14 prompts. Instead, it clears the retirement flag on just three high-friction reference prompts: tip_move_face (+10% still / -5% moving hit chance and Q/E facing), tip_shields_hull (four cyan shield facings vs permanent amber hull), and tip_threat (R key threat shading). The F1 bottom card already reminds returning players how to click Move, Fire, and End ship, so refreshing only those three cards restores the hidden math and hotkeys without replaying the entire campaign tutorial.

4. First Battle Setup

Every piece of Battle 1 is configured to isolate core movement, facing, and shooting while upholding R62 (full lethality, no scripted wins, no weakened enemies).

Enemy Faction Pick: Hegemony (hegemony) in Battle 1; Hullbreakers (corsair) in Battle 2.

Reason tied to evidence: Sector 1's enemy pool contains only Hullbreakers (corsair) and Hegemony (hegemony). Hegemony fleets fight as conventional gun-lines that rely on ranged weapon arcs and directional shield facings, whereas Hullbreakers close distance rapidly to ram and board. Locking Battle 1 to Hegemony lets the player learn movement, Q/E facing, hit-chance modifiers (+10% sitting still, -5% moving 3+ hexes), and shield facings (tip_move_face, tip_firing, tip_shields_hull) at ranged gunnery pace. Guaranteeing Hullbreakers in Battle 2 then naturally triggers tip_close (ramming with X and boarding with G) once the player already knows how to pilot their ships. Per R62, the Hegemony fleet in Battle 1 uses the full, unmodified enemy point budget.

Map Shape: Open Board with One Central Obstacle (single_cluster).

Reason tied to evidence: The Nov 1 owner ruling already sets cfg.noStar in Sector 1 (battle.js:311-312) to prevent the dead star map from appearing in the first sector. However, a completely featureless open grid gives a new player no spatial reference for flanking or turning, while a cluttered multi-hazard map recreates the R65 complaint where move hexes were hard to distinguish from terrain. Setting Battle 1's map generator to spawn an open board with one central non-blue asteroid/debris cluster between the two fleets gives the F1 bright-outlined blue move hexes unmistakable visual contrast against a single terrain feature while teaching line-of-sight and turn planning around a clear landmark.

Fleet Sizes: 2 to 3 Player Ships (4 to 7 Command Points) vs. 2 to 3 Scaled Hegemony Ships.

Reason tied to evidence: battle.js:146-150 scales the enemy budget directly against the player's starting fleet of 4 to 7 command points (2 to 4 ships). For Battle 1, the enemy generator should pick 2 to 3 Hegemony ships that fill the exact scaled budget rather than spawning a swarm of 5 tiny craft. Keeping both sides at 2 to 3 ships ensures Round 1 completes in four to six total activations, getting the player to Round 2 (tip_threat) in under two minutes while keeping the F1 violet enemy progress strip ("ship 1 of 3") brisk and readable.

Reinforcement Timing: Zero Reinforcements in Battle 1; First Reinforcements in Battle 2 or Battle 3.

Reason tied to evidence: R65 identified reinforcement arrival as one of the owner's three primary confusions. Although the F1 pass added a banner, ship name line, entry-hex flash, Arrived tag, camera nudge, and NEW tag, Battle 1 already teaches five core combat prompts across Rounds 1 and 2. Withholding wave reinforcements from Battle 1 (forcing all enemy budget onto the board at start) and scheduling the first reinforcement wave in Battle 2 or Battle 3 lets the F1 reinforcement announcement pair cleanly with Prompt 12 (tip_objective_reinforce) when the player has cognitive room to watch the board edge.

5. Between Battles

The firstrun audit identified the total absence of campaign-layer tip delivery as the game's single systemic teaching failure: all 16 campaign tips exist in contrib/muse/reviews/tutorial_assembled_2026_10_29.md, and 14 problem lines were corrected in contrib/opus/compute/content_lint_2026_11_01.md (items 106 to 119), but _tutorial() only runs inside battle.gd.

1. Which Campaign Texts Fire Where (Using Lint-Corrected Copy):

First Post-Battle Reward Screen (after Battle 1): Fires Prompt 6 (c_reward), combining the lint-corrected lines for c_credits, c_salvage, c_prize, and c_boon. Specifically, it removes the retired labels "boon" and "patron", states the lint-corrected rule that "Reward rerolls are only available when an upgrade or event unlocks them, and each reroll costs credits", and explains that captured "prize ships" exceeding active command points go into the "reserve hold".

First Sector Map Screen (between Battle 1 and Battle 2): Fires Prompt 7 (c_map) on screen open, followed by Prompt 8 (c_clock) when c_map is dismissed. Prompt 7 uses the lint-corrected plain words from items 106 to 108, replacing "node" and "node kinds" with "stops" and "connected star lanes", and quoting the exact lint-corrected elite guarantee: "ordinary fights, events, rest stops, shipyards, and at least one elite fight on a route you can choose".

First Shipyard or Rest Stop Screen (between Battle 2 and Battle 3): Fires Prompt 11 (c_shipyard), reusing the lint-corrected lines for c_shipyard and c_regroup that explicitly define "Refit" ("Use Refit at a shipyard to swap weapons and hull upgrades between your ships") and "Hold" ("use the Hold to move spare prize ships between reserve storage and your active combat fleet") alongside paying credits to repair amber hull damage.

First Run End and Pre-Run 2 Setup: Fires Prompt 13 (c_loss) at the Run Summary Screen using the lint-corrected timing rule ("Your run results tally at the end of a run, converting every battle won and sector cleared into permanent Renown and admiral experience") and Prompt 14 (c_tree_heat) at the Admiral Setup Screen using the lint-corrected respec and Heat rules ("pay to respec and reassign your points between runs" and "each point of Heat grants +2 XP to the admiral you fly and +1 XP to your faction's shared shadow pool").

2. Smallest Delivery Mechanism for Campaign-Screen Prompts:
Do not build a second tutorial framework for the campaign screens. Extract the tip persistence and lookup logic out of battle.gd into a lightweight helper function (or static method on the existing options/HUD autoload) called TipManager.try_show_tip(screen_node, tip_id) that reads and writes the same user://battle_opts.json file and instantiates the exact same hud.show_tipcard UI scene used in battle.gd. Calling TipManager.try_show_tip(self, "c_map") in the _ready() or _on_screen_shown() callback of the Map, Reward, Shipyard/Rest, Run Summary, and Admiral Setup screens requires fewer than 40 lines of code and zero new UI prefabs.

6. The Off Switch

The existing "Battle tips: on/off" toggle in the battle options menu (which flips "tipsOff" in user://battle_opts.json) is necessary but not sufficient on its own for two reasons: its label says "Battle tips" even though tips now span the campaign screens, and a veteran player starting a fresh profile cannot reach the battle options menu until they are already inside Battle 1 with Prompt 1 on screen.

Where the Toggle Must Appear:

Rename the label from "Battle tips: on/off" to "Tutorial tips: on/off" in the in-battle options menu.

Expose the exact same toggle (bound to "tipsOff" in user://battle_opts.json) in the Main Menu / Campaign Options menu so players can disable tips before starting a run.

Add a subtle secondary link or button on the bottom-left footer of the show_tipcard widget itself reading "Turn off all tips" next to the primary "Got it" button, allowing any player to silence all future teaching cards with a single click the moment Prompt 1 appears.

What "Off" Must Mean:
Setting "tipsOff": true suppresses only the 14 popup teaching cards (show_tipcard) across both battle and campaign screens. It must never disable the F1 turn-flow HUD elements: the gold UP tag, the three-step bottom card and its one-sentence action status, the Enemy Turn banner and violet progress strip, and the Reinforcement Arrived banner and entry-hex flash are permanent tactical readouts required to play the game at any skill level. Automated screenshot and test jobs continue to force "tipsOff": true as they do today.

7. Build List

Migrate user://battle_opts.json and extract TipManager (battle.gd, campaign state/autoload): Move the user://battle_opts.json read/write logic for "tips" and "tipsOff" into a shared script accessible by both battle.gd and campaign screens, upgrading "tips" to a timestamped dictionary "tips_seen" plus "last_played_ts" and migrating old IDs ("select" -> "tip_move_face", "move" -> "tip_shields_hull", "target" -> "tip_firing", "fired" -> "tip_alternating").

Add the 14-day returning-player check (TipManager load routine): On game boot, if current_time - last_played_ts >= 1209600 (14 days) and "tipsOff" is false, remove "tip_move_face", "tip_shields_hull", and "tip_threat" from "tips_seen" so those three cards refresh once in the next battle.

Update the hud.show_tipcard widget (hud.gd / tipcard scene): Ensure the tip card UI can be instantiated as a child overlay on both battle.gd and the campaign screen nodes, featuring a primary "Got it" button (which marks the current tip ID as retired in "tips_seen") and a secondary "Turn off all tips" button (which sets "tipsOff": true and closes the card).

Replace the shipped TIPS dictionary and conditions in battle.gd: Remove the redundant start and turns entries, update the 8 battle tip strings (tip_move_face, tip_firing, tip_alternating, tip_shields_hull, tip_threat, tip_close, tip_resolve, tip_objective_reinforce) to the exact plain-word strings in Section 2, and add the after_first_enemy_turn condition (round == 1 and enemy_activations_completed >= 1) so shield facings trigger right after the first enemy ship acts.

Wire action-gated retirement hooks in battle.gd: Hook TipManager.retire_tip() into move confirmation (tip_move_face), weapon fire resolution (tip_firing), ship turn end (tip_alternating), threat key R press (tip_threat), ram/board execution (tip_close), and Admiral's Command activation (tip_resolve) so tips only retire on action completion or "Got it" click rather than on initial display.

Lock Battle 1 encounter parameters (battle.js / campaign sector 1 generator): In the Sector 1 node generator, set Battle 1's enemy faction to hegemony, force Battle 1's map template to the single-central-obstacle preset (preserving cfg.noStar from battle.js:311-312), cap Battle 1 enemy ship count to 2 to 3 ships at full scaled budget (battle.js:146-150), and set Battle 1 reinforcements to zero while guaranteeing corsair (Hullbreakers) in Battle 2 and wave reinforcements by Battle 2 or 3.

Hook campaign prompts into the Reward, Map, and Shipyard/Rest screens (campaign UI scripts): Add TipManager.try_show_tip() calls to the Reward Screen (c_reward), Sector Map Screen (c_map on open, c_clock on c_map dismissal or route hover), and Shipyard/Rest Stop Screen (c_shipyard) using the exact lint-corrected strings from Section 2.

Hook meta-progression prompts into Run Summary and Pre-Run Setup (campaign UI scripts): Add TipManager.try_show_tip() calls to the End-of-Run Summary Screen (c_loss) and the Admiral Skill Tree / Heat Setup Screen (c_tree_heat) when the player finishes Run 1 and prepares for Run 2.

Sync the "Tutorial tips: on/off" toggle across menus (options UI scripts): Rename "Battle tips: on/off" to "Tutorial tips: on/off" in the battle options menu and expose the same toggle in the main/campaign options menu.

Log tutorial card events to the F1 play log (battle.gd play logger): Append tip display, "Got it" clicks, action-gated retirements, and "Turn off all tips" clicks into the existing F1 per-battle and campaign save play log so future playtests can verify exact reading time and dismissal rates.

8. Not Checked

Because this design relies strictly on pack.md, the following implementation details are not established in the pack and are assumed by this report:

Exact GDScript filenames for campaign screens: The pack names battle.gd, hud.show_tipcard, user://battle_opts.json, and battle.js:146-150 / battle.js:311-312, but does not list the exact .gd script filenames for the Sector Map, Reward, Shipyard, Rest Stop, Run Summary, or Admiral Setup screens.

Exact default hotkey for the R72 full-grid toggle: Section 5 notes under R72 that "a key shows the full grid", and Section 3 lists keys Q/E, Tab, Space, Enter, Esc, 1-6, X, G, and R, but the pack does not name the exact keybind bound to the full-grid toggle. Prompt 5 (tip_threat) refers to "the grid key" and should interpolate the bound key label at runtime.

Architecture of the battle.js to Godot 4.7 bridge: The pack cites both battle.gd (Godot) and battle.js / core.js. This report assumes campaign generation rules in core.js / battle.js (or their ported GDScript equivalents on main) expose battle index (battle_num == 1) to lock Hegemony, the single-obstacle map shape, and reinforcement suppression in Battle 1.
