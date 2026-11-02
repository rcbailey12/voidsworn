# Onboarding synthesis: teaching sector 1 without a wall of text

Chair synthesis of four legs (DeepSeek, Qwen, Argon, Rey) for Job 4 of the Nov 1, 2026 four-job commission. Qwen returned two complete responses; both are filed, and this synthesis follows its first response where they differ, for reasons given in section 7. Owner rulings R62 (teach, never soften) and R72 (board look) govern throughout. One chair code check was run against the shipped rules engine (battle.js on main) to settle a dispute between legs; it is reported in section 3.

## Verdict

GO WITH CONDITIONS. The shipped battle tips are good text in a weak order, the campaign tips are good text with no delivery mechanism, and the F1 turn-flow card already answers most of the R65 confusion inside a battle. The design below re-times the battle cards so each one is earned by an action or an event, adds exactly one new battle card (a reinforcement warning), gives the campaign cards a delivery path through one small shared helper, and fixes the off switch. Fifteen cards total across the whole first run, never more than one waiting at a time, and battle 1 carries five of them. Three chair calls are flagged for the owner at the end; none blocks the build.

## 1. The prompt schedule (final)

Battle cards use the shipped tip ids, unrenamed. Renaming resets who has seen what, and three of four legs refused to pay that cost; Argon's migration scheme is noted in section 7 and not adopted. Two shipped ids, start and turns, stop being cards: the F1 bottom card already says what start said, every turn, and the turns content moves into the fired card where it answers the question the player is actually asking at that moment. Both ids are marked shown for new profiles so nothing re-fires.

Battle 1 (Hegemony, see section 4):

1. select, "Moving and facing". Trigger: the first hand-over of battle 1, before the handed ship has moved. Text: "This is the ship that is up. Click a blue hex to plan its move, and turn it with Q and E before you confirm. A ship that stays in the same hex is easier to hit: enemy shots against it get +10 to their hit chance. Moving 3 or more hexes gives -5 instead. Or Brace: the ship stays put, takes less damage, and does not take the +10, but it cannot move or fire again this turn." (The brace sentence replaces the shipped tip's narrower claim; see section 3.)
2. target, "Firing". Trigger: the first time an enemy is in some player ship's firing set. Text: "The red ring means this enemy can be hit from where your ship sits. Click it once to see the hit chance and the damage expected. Click again to fire every gun that bears. Keys 1 to 6 fire one gun at a time."
3. fired, "Taking turns". Trigger: the first player weapon shot has resolved. Text: "Sides take turns, one ship at a time, until every ship has acted. That is one round. Press Space to end this ship early, or Tab for the next ship. A ship with nothing left to do ends itself."
4. move, "Shields and hull". Trigger: the first enemy activation of battle 1 completes. Text: "The cyan bars are shields, one for each side of the ship. Shields soak hits and come back each round. The amber bar is hull. Hull damage stays until you pay for repairs. Keep your strongest shield side facing the guns."
5. threat, "Threat map". Trigger: round 2 begins. Text: "Press R for the threat map. It shades every hex enemy guns can reach next turn. Darker means more damage waiting there."

Battle 2 (Hullbreakers):

6. reinforce_warn (new id), "More ships are coming". Trigger: the round before the first scheduled reinforcement in the run arrives. Text: "More enemy ships are on their way. They arrive at the map edge, and a banner will name the ship and flash where it came in. A new arrival acts in the turn order like any other ship." This is the one card the F1 pass cannot write itself, because it has to land before the event it explains.
7. close, "Close action". Trigger: the selected ship can ram or board for the first time. Text: "Up close you have two more attacks. Press X to ram an enemy dead ahead. Press G to board an enemy next to your ship. Win a boarding and the ship is yours for the rest of the fight."

Battle 3 or whenever first true:

8. resolve, "Admiral's Command". Trigger: the Command is ready (can_command) for the first time. Text: "Your admiral's Command is ready. It fires once per battle, and it grows stronger each round you wait, and when you lose a ship. The button glows gold while it is ready."
9. objective, "Objectives". Trigger: the first fight whose objective is not rout. Text: "The bar at the top shows this fight's goal. When the goal is not wiping the enemy out, doing the goal wins the fight even if enemy ships are left."

Campaign cards (new c_ ids, delivered by the helper in section 5; all copy follows the content lint's corrected lines, not the wave 4 originals):

10. c_map. Trigger: the first sector map screen opens. Text: "This is the sector map. Pick a stop on a connected lane and work toward the boss at the end. Stops are fights, events, rest stops, and shipyards. There is at least one elite fight on a route you can choose: harder enemies, better rewards. You cannot visit every stop, so choose."
11. c_clock. Trigger: c_map dismissed, same screen. Text: "Every jump moves the clock at the top. When it runs out, the Nemesis catches up and the fights ahead get harder. Side stops pay, but they cost jumps."
12. c_reward. Trigger: the first reward screen opens. Text: "Winning pays credits, and offers salvage: guns and parts you can fit at a shipyard. Sometimes you can claim a beaten enemy ship instead. If your fleet is full, a claimed ship is scrapped for credits on the spot. Rerolls are not free: when one is offered, it costs credits."
13. c_shipyard. Trigger: the first shipyard or rest stop opens. Text: "Here you spend credits to repair hull damage, refit (swap guns and parts between your ships), and buy ships. After a boss fight you also regroup here: repair, upgrade, or buy before the next sector."
14. c_loss. Trigger: the first run ends, on the run summary screen. Text: "The run is over, and that is expected. Losing teaches your faction: renown, core progress, and what your admiral learned all carry into the next run. Your ships and credits do not."
15. c_tree. Trigger: the admiral setup screen opens with experience to spend. Text: "Spend experience on your admiral's skill tree between runs. Heat is a difficulty you choose: each point of Heat gives +2 experience to the admiral you fly and +1 to your faction's shared pool, and makes the run harder."

## 2. Fade rules

1. Base rule stays the shipped one: a card shows once per profile, ever, recorded in user://battle_opts.json under "tips", beside "tipsOff" and "speed". No card ever waits behind another: the checker shows the first true condition, and conditions are ordered so a later card cannot queue while an earlier one is pending (the Rey leg's core fix; the shipped order lets turns be true from the first second and jump the queue).
2. Action-gated retirement (from the Argon leg, adopted): select, target, fired, and close are not retired by being dismissed. If the player closes one without doing the action, it stays eligible and can appear in the next battle. Doing the action retires the card even if it was never shown. Observation cards (move, threat, resolve, objective, and all campaign cards) retire on dismissal, as today.
3. Spacing: at most one card per activation in battle, and at most one card per campaign screen opening, c_clock after c_map on the same screen being the single exception because the clock is on that screen.
4. Returning players: if the profile has been idle 30 days or more, select re-arms once (Qwen's first response; Argon's 14-day, three-card refresh was judged too much machinery for the gain). Vetoable by the owner; it is one condition and one id.

## 3. The brace dispute, settled by code

DeepSeek's draft said a braced ship cannot fire this round; the shipped select tip says only that bracing cancels the sitting-still penalty. The chair checked the rules engine. DeepSeek is substantively right and the shipped tip is incomplete: canFire returns false for a braced ship (battle.js:635), the game itself explains "This ship is braced, so it holds fire this turn" (battle.js:898), and bracing marks every weapon fired and zeroes movement (battle.js:1047). The final select text in section 1 says all of it. Opus should also correct the shipped tip text wherever else it lives.

## 4. First battle setup

Enemy: Hegemony. Four of the five leg responses agree (DeepSeek, Rey, Argon, Qwen response 1). The reason that survives screening is the ranged one: Hegemony fights as a gun line at range, so battle 1 teaches moving, facing, and shields at gunnery pace. Qwen response 2 picked Hullbreakers from the faction's name; DeepSeek's stated reason (that Hullbreakers teach the close action) is backwards, since close actions are the player's choice, not the enemy's. Hullbreakers come in battle 2, where their closing speed makes the close card likely to trigger naturally.
Map: open, with one terrain feature at one edge (DeepSeek, Rey). Argon's single central cluster was rejected: a feature between the fleets can block the first firing lesson and recreates the R65 complaint about telling hexes from terrain. The dead star is already excluded from sector 1 by the owner's ruling (cfg.noStar, battle.js:311-312).
Fleets: generated as today, enemy budget scaling with the player's fleet (battle.js:146-150). No scripted sizes and no weakened enemies (R62). Argon's cap of 2 to 3 enemy ships is a soft script and is not adopted.
Reinforcements: none in battle 1. First in battle 2, preceded by the warning card (Qwen response 1, Argon). DeepSeek put the first arrival in battle 3; the chair takes battle 2 because the F1 banner now announces arrivals properly, so the lesson is the warning, not the surprise, and it should land while sector 1 is still teaching. Flagged as an owner call below.

## 5. Between battles: the delivery mechanism

Every leg converged on the same smallest mechanism, and the chair adopts it: a small campaign_tips helper (a shared script or autoload) that reads and writes the same user://battle_opts.json, reuses hud.show_tipcard unchanged, and is called from the map, reward, shipyard, run summary, and admiral setup screens when they open. One "tipsOff" value governs both battle and campaign cards. No second tutorial framework, no new card art. This closes the gap the firstrun audit called the one systemic teaching failure: the campaign copy exists, the lint already corrected it, and only the checker was missing outside battles.

## 6. The off switch

The existing battle options toggle is necessary and not sufficient. Final position (DeepSeek and Argon converge here): keep the toggle in battle options, relabel it "Teaching tips: on/off" (the cards are no longer battle-only), add the same toggle to the campaign map or pause menu so a player can silence cards between battles, and add a "Turn off all tips" link on the card itself (Argon) so the very first card carries its own exit. Off means teaching cards only. It never touches the F1 bottom card, the hand-over tag, the enemy turn strip, or the reinforcement banner; those are the game, not the teaching. Test and screenshot jobs keep forcing tips off exactly as today.

## 7. Screening notes

Argon: the strongest structural leg (action-gated retirement, the card-level off link, the map-clock pairing), with two factual errors screened out. Its reward card sent full-fleet prize ships to a "reserve hold"; the owner's capture ruling is that a full fleet scraps the extra ship on the spot (and the c_reward text in section 1 says so). Its proposal to rename all tip ids under a new timestamped schema was not adopted (section 1). Its Command description, which the chair first suspected, in fact matches the shipped resolve tip and stands.
Qwen: response 1 is the better draft and is followed (battle-number gating, battle 2 reinforcements with warning, 30-day re-arm). Response 2 defines refit as hull repair, which is wrong (refit swaps guns and parts; repair is separate and costs credits), and says rest stops repair for free, which nothing in the pack supports; both are excluded. Both responses agree with the consensus on Hegemony first, no battle 1 reinforcements, one terrain feature, the shared helper, and one tipsOff flag.
DeepSeek: correct on the brace fact (section 3), the three-state instinct, and the off-switch relabel; its Hegemony rationale and its rest-stop regroup wording were not used.
Rey: the ordering diagnosis is the synthesis's spine (cards must be earned by an action or event, never queued), and its schedule leads the campaign section with the corrected map texts.

## 8. Build list

1. battle.gd, TIPS and _tutorial(): reorder and re-time the conditions per section 1 (select at first hand-over, move after the first enemy activation, turns content folded into fired, start and turns marked shown for new profiles). Add the corrected brace sentence to select.
2. battle.gd: add the reinforce_warn tip (new id, new condition: a reinforcement is scheduled for next round and none has arrived yet in this run).
3. battle.gd: implement action-gated retirement for select, target, fired, close (retire on action completion as well as on dismissal-after-action; dismissal alone does not retire).
4. battle.gd: enforce the spacing rule (one card per activation; a pending card suppresses later conditions until shown).
5. New campaign_tips helper (shared script or autoload): try_show(id) reading and writing user://battle_opts.json, instantiating hud.show_tipcard, honouring the single tipsOff flag.
6. Campaign screens: call the helper on open: map (c_map, then c_clock), reward (c_reward), shipyard and rest stop (c_shipyard), run summary (c_loss), admiral setup (c_tree).
7. Sector 1 generation (campaign layer): pin battle 1 to Hegemony and battle 2 to Hullbreakers within the existing sector 1 pool, pin battle 1's map to the open-with-one-edge-feature shape, and suppress reinforcements in battle 1 while guaranteeing a scheduled arrival in battle 2. No budget, hull, or weapon numbers change.
8. Options UI: relabel the toggle "Teaching tips: on/off", mirror it in the campaign map or pause menu, and add the "Turn off all tips" link to the tip card.
9. Profile idle check: on load, if last played is 30 or more days ago, remove select from the shown set once.
10. Play log: record card shows, dismissals, and action retirements in the existing F1 play log so the next playtest can verify reading order against this schedule.

## 9. Owner calls

1. First reinforcements in battle 2 (chair, with Qwen and Argon) against battle 3 (DeepSeek). Either is buildable; battle 2 is in the build list.
2. The 30-day re-arm of the select card. One condition, easy to strike.
3. Retiring start and turns as cards. Their content survives (F1 card, fired card), but if the owner wants the two shipped cards kept verbatim, they can be re-timed instead of retired at the cost of two more cards in battle 1.

## Not checked

No leg played the current build; every trigger above is argued from the pack and the F1 hand-over notes, not from a live first run. Whether battle 2's generated fights reliably schedule reinforcements at all is a generation question the pack does not answer; step 7 of the build list guarantees it by construction rather than by measurement. The exact GDScript homes of the campaign screens are Opus's to name; the pack establishes the helper pattern, not the file names. Card reading time and dismissal rates are unmeasured until the play log in step 10 exists.
