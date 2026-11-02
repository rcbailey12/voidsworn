## 1. Headline

Sector 1 teaches one loop at a time: first map choice, then battle 1 move and fire and end ship, then battle 1 round, then reward, then shipyard or rest, then battle 2 and 3 only for close action, Admiral's Command, and reinforcements. The first battle is not a tutorial level and is not weakened. It is a small, real battle with a single clear goal, and the player learns by doing the actions the battle already requires.

## 2. Prompt schedule

I use 11 prompts. That is under 12, so there is no over-12 justification. Conditional prompts 9 and 10 appear only if their condition occurs; they are not guaranteed. No prompt is tied to a timer, and no prompt interrupts a player action. Each prompt appears on the tip card, not as a modal, and each prompt is shown once in the first run unless its fade rule says otherwise.

1. Moment: first map screen, before battle 1. Trigger: first_sector1_map_screen opens. New condition. Where: map screen tip card. Text: "Pick a connected place to travel to. A line between two places is a route. A hard fight, called an elite fight, is on a route you can choose. It is harder than an ordinary fight and gives a better reward."

2. Moment: battle 1 start. Trigger: existing start plus new first_battle. Where: battle tip card. Text: "The top bar states this fight's goal. Read it before you move. If you lose every ship, this attempt ends."

3. Moment: battle 1, first time a usable ship is selected. Trigger: existing select plus first_battle. Where: battle tip card. Text: "Moving 3 or more hexes lowers the enemy's chance to hit this ship by 5. Staying in the same hex raises the chance that an enemy will hit this ship. Brace makes this ship harder to hit, but it cannot fire this round."

4. Moment: battle 1, after the first player move. Trigger: existing move plus first_battle. Where: battle tip card. Text: "After moving, look for a red ring around an enemy. Red means at least one gun can hit it. Click once to target it. Clicking once does not fire."

5. Moment: battle 1, after the first player weapon fires. Trigger: existing fired plus first_battle. Where: battle tip card. Text: "Firing does not end this ship. If it still has movement, you can move. Keys 1 to 6 fire one gun at a time."

6. Moment: battle 1, start of round 2. Trigger: new round_start with round equal to 2, plus first_battle. Where: battle tip card. Text: "A round ends when every ship on both sides has acted once. Then a new round starts and every ship gets a fresh set of actions. A ship that has nothing left to do ends by itself, and the next ship is handed to you."

7. Moment: first reward screen after battle 1. Trigger: new first_reward_screen. Where: reward screen tip card. Text: "Pick one reward. You do not get the other offers. Credits are money; you spend them at shipyards and on some reward screens. A reroll is paid, not free, and it replaces the offers you see."

8. Moment: first shipyard or first rest stop, whichever opens first. Trigger: new first_shipyard_screen or first_rest_screen. Where: shipyard or rest stop tip card. Text if shipyard: "A shipyard repairs ships, lets you refit them, and sells new ships. Refit means change a ship's guns and parts." Text if rest stop: "A rest stop repairs some damage and lets you regroup. Regroup means change which ships are in your fleet and which ships are held in reserve."

9. Moment: battle 2 or 3, first time the selected ship can ram or board. Trigger: existing close. Where: battle tip card. Text: "Ram with X when an enemy is directly ahead. Board with G when an enemy is next to you. If you win, the enemy ship becomes yours if there is room in your fleet."

10. Moment: battle 2 or 3, first time Admiral's Command is ready. Trigger: existing resolve. Where: battle tip card. Text: "Admiral's Command is ready once per battle. It grows stronger each round you wait and when you lose a ship. It is ready now, but you can wait."

11. Moment: battle 3 start, before the first reinforcement can arrive. Trigger: new first_reinforcement_battle_start. Where: battle tip card. Text: "Enemy ships can arrive after this fight starts. When one does, a banner names it and the hex where it appears is marked. Watch the banner, not the whole map."

I do not add a battle 2 start prompt. The F1 bottom card already names the ship, steps, and next action. Adding a battle 2 start card would duplicate that card and add a prompt with no new action. Battle 2 still teaches by doing: the close and resolve prompts appear only when those actions are actually available.

## 3. Fade rules

Each onboarding prompt should have three states: unseen, shown, and done. A prompt becomes shown when its card appears. It becomes done when the player performs the action, dismisses the card, or the teaching moment passes with the action no longer available. A prompt that is done never appears again in that profile. A prompt that is shown but not done may appear once more at its next valid trigger, but only in the same first run and only if the action is still available.

The existing once-ever persistence in user://battle_opts.json under "tips" should remain for general reference tips, but it should not be the persistence for this first-run lane. This lane needs its own "onboarding" entries with the three states above. The shipped tip ids select and move are misnamed: select carries moving text and move carries shields text. I would add new ids for the first-run lane, b1_move_brace and b1_shields, and leave the old ids alone. Renaming the old ids would reset who has seen them for existing players, and that reset is not justified by a first-run fix.

No prompt should reappear because time passed. A returning player who has completed onboarding gets no onboarding cards. A returning player who has not completed onboarding gets no timed popup on return. The next time a valid trigger occurs in normal play, the next unseen prompt in order appears, and no missed prompt is shown out of order or in a batch.

## 4. First battle setup

Enemy faction: Hegemony. Sector 1 legally contains only Hullbreakers and Hegemony. I pick Hegemony because battle 1 should avoid close action, and the pack's close-action text is tied to ram and board. Hegemony is the gun-line choice for a first fight that teaches move, fire, and end ship before close action.

Map shape: an open map with one large terrain feature at one edge, not between the starting fleets. No dead star is required by cfg.noStar in sector 1, but the design still needs a positive shape. An open map with one edge feature gives a clear first move, a visible terrain choice, and no blocked first turn.

Fleet sizes: use the player's starting fleet as generated, 2 to 4 ships and 4 to 7 command points. Use the existing enemy budget scaling in battle.js:146-150. Do not hand weaken the enemy. Expect a small first fight, about 2 to 3 ships per side, because starting fleets are small, but do not force that count by changing the budget.

Reinforcements: first appear in battle 3, not battle 1 or battle 2. Battle 1 teaches the core loop. Battle 2 adds the reward and map choice between battles. Battle 3 is the first time the player must also watch for a new ship, after the core loop is already practiced.

## 5. Between battles

First map: use the corrected map and elite lines. My exact card text is prompt 1: "Pick a connected place to travel to. A line between two places is a route. A hard fight, called an elite fight, is on a route you can choose. It is harder than an ordinary fight and gives a better reward." The map line must not promise a route that is not connected, and the elite line must not present an elite fight as required.

First reward: use prompt 7. It reuses the corrected credits and reroll points: credits are money, and "a reroll is paid, not free." It also states the key reward rule in plain words: pick one, the other offers are lost.

First shipyard or rest stop: use prompt 8. The shipyard line explains refit in plain words. The rest line explains regroup in plain words. Neither line should list every shop option; the screen itself shows the options, and the card only defines the two words the player needs to choose.

Smallest delivery mechanism: add a campaign_tips.gd helper or autoload. It holds the campaign prompt ids and texts, reads the same battle_opts.json state, and calls the existing tip card scene. Each campaign screen calls campaign_tips.show("first_map") or campaign_tips.show("first_reward") after its layout is ready. This is smaller than moving the whole battle checker out of battle.gd, and it gives map, reward, shipyard, and rest screens one shared path. Store campaign state under "campaign_tips" in battle_opts.json, with tipsOff shared.

## 6. The off switch

The existing battle options toggle is not enough. A player can turn tips off inside a battle and still meet campaign cards on the map, reward, shipyard, and rest screens. The toggle must be added to the map or pause menu, and it must read and write the same tipsOff value. The label should become "Teaching tips: on/off" if the UI can change it without a large rewrite. If the label cannot change, the existing label can stay, but the value must still control all screens.

Off means no optional teaching cards and no optional teaching sentences. It does not mean hiding game information. The top bar goal, the F1 bottom card, the enemy turn banner, and the reinforcement banner stay on, because they are not optional teaching text. Turning tips back on resumes the first-run lane at the next unseen prompt; it does not restart the lane or replay done prompts.

## 7. Build list

1. Extend user://battle_opts.json with an "onboarding" dictionary mapping prompt ids to "unseen", "shown", or "done". Keep the existing "tips" and "tipsOff" keys.

2. Extract the existing tip card into a reusable scene or helper, then add campaign_tips.gd with show(id). It checks tipsOff, checks onboarding state, shows the card, and records shown.

3. In battle.gd, add the new conditions first_battle, round_start(2), and first_reinforcement_battle_start. Reuse the existing start, select, move, fired, close, and resolve conditions where they fit.

4. In battle.gd _tutorial(), suppress the shipped start, select, target, and fired cards during the first-run lane so they do not duplicate prompts 2 to 5. Register the new first-run ids in the same checker.

5. Hook the map screen to call campaign_tips.show("first_map") once, and include the corrected elite line. Hook the reward screen for prompt 7.

6. Hook the shipyard and rest stop screens for prompt 8. Use one shared first-between-screen id so only the first of the two appears.

7. Add the sector 1 first battle setup: Hegemony, open map with one edge terrain feature, no reinforcements in battles 1 and 2, first reinforcement battle in battle 3. Do not change the existing enemy budget scaling.

8. Add the teaching tips toggle to the map or pause menu, reading and writing the same tipsOff value. Make campaign_tips.gd and battle.gd both honor it.

9. Add a first-run test script that plays battle 1 and checks prompt order, checks that F1 bottom card text is not duplicated, checks that tips off suppresses optional cards but keeps the enemy turn and reinforcement banners, and checks that a returning player gets no timed popup.

## 8. Not checked

The pack summarizes the lint corrections but does not print all 16 corrected campaign lines. The campaign lines quoted above are my plain-word restatements of the corrections, not guaranteed verbatim originals. I assume the first run opens on a map screen before battle 1; if it opens directly in battle 1, prompt 1 moves to the first map after battle 1. I assume Hegemony is the safer first fight because battle 1 should avoid close action; if Hullbreakers are the gun-line faction and Hegemony are the ram faction, the faction pick should flip. I assume the existing enemy budget scaling already produces a small first battle; I do not propose changing it. I assume the existing tip card can be reused on campaign screens without a new UI scene. I assume battle_opts.json is available outside battles; if it is battle-only, the state needs a small campaign save shim.
