---
paths:
  - "godot/{ui,main,scenes/campaign}/**"
  - "godot/scenes/battle/battle.gd"
  - "docs/playbooks/screens.md"
---

Read the [screens playbook](../../docs/playbooks/screens.md) for layouts and picture checks.

## 9. Screens and interface

9.1 **One interface for the whole game: the ember orders sheet; lime is retired.** Words on a smooth darkening of the scene, no
panels, square corners, one accent (ember #ff8a3a) for the next action, NEM red for the Nemesis only. Why: "The whole thing
clearly reads as a Claude based UI." (R137); "the faction specific views went wayyyy too hard. We still need one specific UI
for the game that is consistent." (R141); "Retire lime" (R191). Set: Ryan (R137, R141, R176, R191). Ids: R137b, R141, R149,
R176a, rail-01, rail-04. Detail: docs/playbooks/screens.md.

9.2 **Avoid the AI-made look**: neon accent on dark slate, glass or frosted panels, pill buttons, identical cards, indigo to
purple gradients, glowing blurs. Why: "I really like the concept but it's getting pretty busy and it also reads as AI generated
still" (R164); his list (R174). Set: Ryan. Ids: R164c, R174c.

9.3 **Say less**: a screen holds only what its decision needs; the rest is one hover or key away; nothing is deleted from the
game, and the pull request lists every moved item. Why: "We don't need to over explain EVERYTHING in this one UI." (R177).
Set: Ryan. Ids: R177, screens-06, briefing-05, rail-05.

9.4 **Readable: nothing read below 17 px at 1080, 4.5 to 1 contrast over the brightest and darkest board, no overlaps at any
fleet size.** One floor, 17 (the old 12 px floor is retired). Why: Ryan asked for a readability pass (R176); text overlapped
the flagship name (R177). Set: Ryan (R176); one floor Board. Ids: rail-06, uispec-02, R136b.

9.5 **Battle screen: KEEL, the bottom shelf and two corner blocks.** Ryan picked KEEL v5 on Nov 17 (issue 1021) to open up
the board, replacing the E1 Ledger rail. **Glacier #92b8e8 is for shield readouts only, on every screen; the shields drawn in
space keep faction colours.** Set: Ryan, Nov 11 (R210: "Glacier pale blue", "Yes, that's right"). Replaces R3's "interface
shield bars stay cyan". Ids: R3b, plan-02. See docs/playbooks/screens.md for the layout.

9.6 **In battle, faction colour never touches names, plates, bars or panels; the enemy faction is its crest and plain name.**
Why: one UI with faction colour only as a small accent (R141). Set: Board (R125). Ids: R125b, uistyle-06.

9.7 **One UI scale law, k = clamp(height / 1080, 0.6, 2.2) times the player's UI scale, in ui_scale.gd only.** Why: six copies
disagreed. Set: Board (R136). Ids: R136a, uispec-01.

9.8 **Comfort settings (UI scale, reduce motion, reduce flashing) are reachable mid-battle; the developer surface hides behind
a dev flag.** Set: Board (R125). Id: R125a.

9.9 **Opening a screen never changes the run or the save.** Why: Muse found a draw call that created a record (PR 349). Set:
Board. Id: screens-11.

9.10 **Options first, then build**: anything new in look is shown as two or three options, Ryan picks, then it is built.
Why: "Options first, then build" (R167); "every step" of the redesign shows distinct options (R137c). Set: Ryan. Ids: R137c,
program-01.

9.11 **Torpedoes fire now: they fly and land in the same activation as any gun, after a heavy flight of about 1.5 s, and
show their hit chance like any gun.** No lane on the board, no hex aim, no parked torpedo and no strike at the next turn; point
defence and screening wings still get their chance to shoot a salvo down. Why: "i really dont like the way torpedoes look today
and how they act. the arrow lines, the delay, etc. it's not intuitive, it doesnt fit the vibe, UI or graphics of the rest of
the game" (Nov 20, 17:59 UTC); he picked TP-B "Fire now" over a lock-on and a cleaner lane (18:46 UTC). Set: Ryan, Nov 20.
Id: R364 (replaces R76b's lane and next-turn strike; the visible flight and the clear hit or miss stay).

9.12 **The run debrief shows, in order: headline, first loss, what this run bought, the heir, the recap, the next run, exits.**
Why: a run is meant to be lost; the debrief names what the death bought (contrib/opus/briefs/debrief_spec.md). Set: Ryan
(R137a). Id: debrief-01.

9.13 **After a battle: one prize screen, one confirm; a prize may open for detail before the confirm.** Set: Ryan (R23, R216).

9.14 **Keep every ship reachable from the battle HUD when the fleet outgrows its space.** KEEL pages the fleet strip when it
fills; hover gives the full name and health. This replaces E1's "and N more" hover (R220, Ryan: "yes that's fine"). Why: a
large fleet can outgrow the available space, but the strip is also how the player picks a ship. See issue 1021.

9.15 **The start screens (title, Settings, Credits, faction and admiral, flagship aspect, Progression, Lineage, Help) build
from one kit, godot/ui/theme/orders_kit.gd, on glass_shell's orders sheet.** One font set (Big Shoulders Display heads,
Barlow words, Azeret Mono figures), one ember primary per screen with quiet secondaries, labels that wrap inside their
container, rows with one control column, cards whose actions line up, the Back left and the primary right, and the ui_*
sounds on hover, press, back and confirm. Esc goes Back on every start page. The player's UI scale is never capped: a layout
fits 831 design pixels tall (Larger at any 16:9 window) instead. Why: the start flow mixed three font sets and every screen
built its own widgets (Neon front-end audit, Nov 19; R333 cohesion), and Ryan: "the title screen is SUPER basic,
faction/admiral selection is also very basic and also formatting looks odd and not lined up". Set: Board under R333 (issue
1217). Detail: docs/playbooks/screens.md section 2.

9.16 **The game is mouse and keyboard only: no controller play in battle or on the map.** Menus may keep their arrow-key and
Enter focus. Why: Neon's player audit (Nov 21) found menus promise controller focus while battle and map have no gamepad
input; Ryan scoped the game to mouse and keyboard. Key rebinding, a colorblind mode and an in-game rules reference are later
work (issue 1454). Set: Ryan (R380).

9.17 **A ship's move and turn can be undone until it does something that cannot be taken back** (fires, rams, boards, uses
an ability, leaves by an exit edge, or ends its activation). Why: a misclick in a permadeath game should not cost a ship
(Neon player audit, Nov 21). Both rules copies (3.1). Set: Ryan (R376, issue 1450).

9.17a **A player ship's turn is planned on its ghost, then committed, and plays out as one event.** Clicking a blue hex moves
the ghost there, Q and E turn it, and clicking an enemy aims every free gun that bears from the ghost (a second enemy takes
the guns still free). Nothing reaches the rules until the commit (Enter, or a second click on the hex or a target); then the
move and every planned volley go as one command and play as one event, with the guns turning onto the first target while
the hull brakes (issue 1581). Backspace takes back the plan's last step; with no plan open it still undoes a move already
made (9.17). A turn in place commits through the rules' own rotate (so a skill's free turn or a free pivot is spent
there, at the commit), a move through the rules' move. A shot the move made impossible is dropped with a message, never silently. Each ship plays out right after its
commit (not the whole fleet at the end of the turn); the old instant move-and-shoot is gone; enemy activations play the same
way. UI only: no rule changes, and firing still ends movement for every ship except Glasswrights (R396). Why: Ryan, Nov 22
2026: "you see the firing options at your destination and make your firing decisions ... then it actually moves and
happens", "Which lines up with undo"; picks 1a, 2a, 3b, 4b, 5a ("Maybe we test 1b down the line but not now"). Set: Ryan
(issue 1589). Detail: docs/playbooks/screens.md, "Planning a ship's turn".

9.18 **A campaign battle saves at the start of each round and resumes there**, with Save and Quit to title in the battle
menu; the snapshot clears when the battle ends. Why: a crash or a real-life interruption sent a 20 minute boss fight back to
round 1 (Neon player audit, Nov 21). Set: Ryan (R378, issue 1451).

9.19 **New boss and build-variety content is options first** (9.10): bosses get a second phase at half health from an
options sheet Ryan picks (issue 1452); capstone perks, relics, admiral command twists and own Glasswright and Chorus abilities
come as a design pack first (issue 1453). Set: Ryan (R377, R379).
