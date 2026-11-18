# Evidence pack: split the battle HUD rail into top and bottom bars (Voidsworn issue 1006)

## The ask

Ryan, Nov 17, 2026: "the sidebar on the UI still feels large. can we have muse draft up some concepts where it's split vertically? so some up top, some on bottom? that way we dont block the screen as much. i feel like that's more traditional for a reason. i want to keep the general approach to the UI as is for now but evolve it."

He shared three screenshots of other tactics games as layout references (not to copy their look): a turn and round label top left with objectives under it and menu buttons top right; a bottom strip with the selected unit's card at the left, the fleet as a row of portraits in the middle with numbered action buttons under it, and the weapon table at the right; slim top resource bars and small side lists; a minimap top right and grouped command buttons along the bottom.

Deliverable: two or three concepts, each drawn as a mockup over a real battle screenshot at 1080p, with a table of where every item on today's rail goes, the share of the screen covered versus today, notes for 1440p and 4K, and a pick. Concepts only, no game code changes.

## Today's battle screen (the E1 Ledger, FINDINGS R210 as built, narrowed by R218)

The look (keep all of this): no panels or boxes except one, the FIRE box. Words sit on a darkened edge of the scene (a veil). The Hollow Sun's ember is the one accent colour. Square corners. Faces: Big Shoulders Display for names in capitals (never under 28 px at 1080), Barlow Semi Condensed for sentences, Azeret Mono for figures. Three text strengths only. Colours with fixed meanings: EMBER for the accent and the ready action, GLACIER pale blue (#92b8e8) for shield readouts and nothing else, a red reserved for the Nemesis only, a damage colour for a hurt hull figure. Text floor: nothing under 17 px at the 1080 design height.

The left rail today, in the decision order R210 fixed (ship, hull, shields, guns, target, odds, FIRE, orders, Command), with the values from the reference capture (docs/shots/ui_battle_ember/full_1080/E1_ledger_1080.png, the Board's own 1080p battle picture):

1. Turn header: "Round 1", "Your turn" (ember), "3 of 3 ships to act".
2. Objective: "Objective: break their fleet".
3. Ship name: "UNYIELDING OATH" (large display type).
4. Ship class: "Vigil-class cruiser".
5. Hull: "Hull 135 / 135". Move: "Move 0 of 4".
6. Shields: a four-facing cross (prow, starboard, stern, port), each "20", in Glacier blue.
7. Status line: "The enemy fleet is focusing its fire on this ship."
8. Guns table: one row per weapon with facing and range band and state: "Sear battery P 1-5, out of range", "Sear battery S 1-5, out of range", "Oath lance F 1-7, 92%".
9. Target: "Target FLEET MARSHAL PETRA VALK" (the name in the Nemesis red when the target is the Nemesis).
10. Odds: "92% to hit with the Oath lance", and the damage split "About 16 damage: 7 to its prow shield, 8 to hull."
11. The FIRE box: "FIRE THE OATH LANCE", with its key "Enter". The one box on the screen, ember outline.
12. Orders row: "Brace B", "Concentrated fire", "Turn Q E".
13. Command row: "Command", "Fire for effect C", "End ship Space".
14. The fleet at the foot of the rail: one line per ship, name and hull figure, the acting ship marked with an ember bar: "UNYIELDING OATH 135", "UNPAID DEBT 85", "IRON DUSK 50".

Occasional items that also live on or near the rail: a tree prompt card (a question with options, mid-battle decisions), a Retreat control, a phase banner (for example the enemy turn banner), and hover detail (secondary detail is one hover or one key away, never deleted; that is the SAY LESS rule, R177).

Not on the rail, and the brief says keep them: top right, the menu ("Menu Esc"), the enemy line ("Hegemony Navy, 2 ships", "Heat 3"), and the Nemesis panel ("Nemesis, Fleet Marshal Petra Valk, Dossier"). Bottom right: the log ("Log L" plus the last three lines; the full log opens on a key).

## Today's geometry and screen share (at the 1920 by 1080 design size)

- The rail's text column is 380 px wide starting at x=40: 19.8% of the screen width, running the full height (top margin 40, bottom margin 48).
- Behind the words, a dark veil covers the left edge at near-full strength and fades to nothing at 30% of the window width. So about 30% of the screen's area is dimmed, in one unbroken full-height band on the left, and the board's left flank is behind it for the whole battle.
- The top-right cluster and the bottom-right log together cover roughly 3% more, in the corners.
- Total touched today: about a third of the screen, all of it on the left and in two corners. The middle and right of the board are clear.

## The scale law (godot/ui/ui_scale.gd)

Every UI size is written at the 1080 design height and scaled by k = clamp(window height / 1080, 0.6, 2.2) times the player's own UI scale (0.8 to 1.4). At 1440p, k is 1.33; at 4K, k is 2.0. Consequences for any concept: bar heights written in design px scale with the window, so a concept's share of the screen is the same at 1080p, 1440p and 4K; what changes is headroom (at 4K everything is twice the pixels, so fine detail like the shield cross gets easier, and on a small or short window at k near 0.6 the 17 px text floor becomes the binding constraint, since text may not shrink below it).

## Rules every concept must obey

- Keep the approach: ember palette and the three faces, the colour meanings (Glacier for shields only, red for the Nemesis only), square corners, no panels except the FIRE box, words on darkened scene edges (veils), not on solid slabs.
- Keep the decision order readable as an order even when it is split across two bars: a player's eye should still travel ship, hull, shields, guns, target, odds, FIRE, orders, Command without hunting.
- Every rail item must be placed, including the occasional ones (tree prompt, Retreat, phase banner). Nothing may be deleted; secondary detail may sit behind one hover or one key, as today.
- Keep the enemy and Nemesis panel and the log where they are (top right, bottom right), or say exactly why a concept moves them.
- Every item reachable in at most one hover or key.
- Judge by: how much of the board is visible and how usable the free space is (one clear field versus fragments), whether the split reading order works, whether the bars stay honest at the 17 px text floor, and build cost (this is a layout move inside the existing HUD code, not a new system).

## Two seeded concepts (from the Board's brief; improve them or beat them)

(a) LEDGER SPLIT. A top bar carries the turn header, the objective, and joins the existing top-right cluster (menu, enemy, Heat, Nemesis). A bottom bar carries the selected ship (name, class, hull, move, shield cross), the guns table, the target and odds, the FIRE box, the orders and Command rows, and the fleet as a horizontal strip.

(b) COMMAND DECK. A bottom-centre command strip carries the ship, guns, target, odds, FIRE, orders and Command, floating over the board's lower middle. Slim corner cards carry the rest: turn and objective top left, enemy and Nemesis top right (as today), the fleet as a small card bottom left, the log bottom right (as today).

## What your leg must do

Propose ONE concept and give it a short code name. For it, provide: (1) a placement table covering every numbered rail item above plus the occasional items, saying exactly where each goes; (2) its geometry in design px at 1920 by 1080 (bar heights, widths, positions) and the share of the screen it covers, compared with today's roughly 30% veil band plus 3% corners; (3) how the decision order reads across the split; (4) what it means at 1440p and 4K under the scale law; (5) what gets worse, honestly; (6) how the tree prompt, Retreat and phase banner appear. You may adopt a seeded concept and improve it, or propose your own. If you think a seeded concept is better than yours, say so and why. Ground claims in the geometry above; flag anything in this pack you think is wrong.

Write in plain language. Use only plain hyphens, never em dashes or en dashes (the repo forbids them in filed documents).
