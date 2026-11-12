# Issue 529: the last seven tree rows and the "you may" prompts

Opus 5.5 worker, Nov 11 2026. Branch opus/issue-529. Refs #529, #305.

## What each row now does in battle

| Row | What happens | Parity fixture | Behaviour check (tree_last_rows_test.js) |
|---|---|---|---|
| matriarch:B:0:0, razormaw:B:0:0, mending:B:0:0, voice:B:0:0 Roles Assigned at Hatching | Every ship gets a role at battle start: strike (+10 aim), screen (+10 evasion, inside the 45 evasion cap), mend (per-round hull regrowth, feeding and biting regrowth, and the Regrowth tide Command 10% stronger). Strike by default (the bot and any unanswered ship). The screen asks each ship once at battle start; each ship may change its role once per battle (a Role order on the ship panel). | t529_roles_strike (default strike), t529_roles_screen (both ships answer screen), t529_roles_mend (both answer mend, with the Regrowth tide), t529_roles_change (the change-role action in round 2) | hit chance 74 to 64 when the ship leaves strike; enemy odds on it 90 to 80 as a screen; round regrowth 13 to 14 and Regrowth tide 45 to 50 on a mend ship; a second change is refused; the prompt asks each ship once with three choices |
| matriarch:A:1:1 Spawned Before the Strike | A brood that moved this round gives the extra swarms it releases +15% damage (the mirror of Every Throat Opens). | t529_spawned (the brood moves, then Spawning surge; new fixture field cmdAfterMove) | an extra swarm hits for 21.00 against 18.75 without the pick |
| matriarch:cap:1 The Brood Does Not Stop | An extra swarm that destroys its target strikes the best other enemy it can reach at half damage, once a round, right after its strike. | t529_nostop | the follow-up strike deals 19.2 where the same full strike, same dice, deals 37.0 |
| razormaw:A:1:1 Scent in the Dark | A kill during the frenzy marks the ship; its next shot, at any other target, gains +10 aim (shown in the odds preview too), then the mark is spent. | t529_scent | the next shot goes from 67 to 77 to hit; without the pick nothing changes |

WAITING in tree_table_walk_test.js is empty: 288 of 288 rows reach B.tree through lineagePick, newRun and startBattle.

## The "you may" prompts

Ten picked skills whose text says "you may" now ask yes or no when the Command is given (data.js TREE_MAY, one line and two buttons each): Held in the Account, Debt Comes Due, Salvo in Two Hands, Held in Reserve, Second Wave on Schedule, Screens Where the Debt Falls, Plates over Shadow, Weld What Matters, Scrap to the Front, Grow Where It Hurts. Yes does what the pick did before; no plays the Command as if the skill were not picked. The bot (command()) and every test without an answer take yes, so seeded bot battles are unchanged.

- Fixtures: t529_may_debt_no (Debt Comes Due answered no: the volley fires at once) and t529_may_grow_no (Grow Where It Hurts answered no). New fixture field treeMay holds the answers.
- Save and load: neither twin saves a battle mid-fight today. The open prompt is plain data in the rules state (B.treeAsk; answers in B.treeMay), and the screen draws it from view().ask on every refresh, so a battle restored from its state comes back to the same prompt. The JSON round trip is checked in both twins.
- Godot: battle_api.gd command_or_ask(), ask(), answer(opt), roles_open(), change_role(id), can_change_role(id), role_of(id); view().ask and per-unit role and canRole (API.md). The screen shows the prompt in the menu's panel style, keys 1 to 3 answer, clicks on the board wait until it is answered. godot/rules/test/tree_prompt_test.gd checks the API (listed in godot_checks.txt).

## Proof that nothing else moved

All 271 goldens that existed on main were run on main and on this branch: 0 differ (every record hash identical). New B or unit fields appear only in battles with these picks or answers.

## Questions for the Board

1. Sekhmar's Noon Is a Choice (sekhmar:A:0:1) says "you may fire the volley at the start of the round, before movement, at +15% damage". The choice is when the player gives the Command, which the game already lets them do; a yes or no after the click would only ask "take the bonus?". I left it without a prompt. Confirm, or say what the prompt should ask.
2. The other "may" texts are per-ship permissions ("a ship may", "every ship may"), not a choice for the player. They keep their automatic default. Say if any of them should become a prompt.
3. Roles default to strike for every ship when unanswered (the bot, the sims). Say if a Mending Throng fleet should default to mend instead.
4. The ship picks inside the yes answers (which ship holds its volley, which ship takes the weld) still use each skill's default picker; only yes or no is asked.
