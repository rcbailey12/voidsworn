# ChatGPT leg, issue 794 stage 3 Fleet (ChatGPT chat, GPT-5.6 Sol at High thinking, verified in the picker before and after)

Chat: https://chatgpt.com/c/6af9d439-6dfc-83ea-b8ed-980d5aeb5671
Ran Nov 15, 2026, 09:46 to 09:50 CST (runtime measured). First council leg under Ryan's Nov 15, 2026 ruling (chat, not Work). Pack attached as design_pack_fleet.txt. The picker showed "5.6 High" before sending and GPT-5.6 Sol was still checked with High shown after the answer completed.

## Full answer, verbatim

The screen decides which ships to repair, how refits are assigned, which ships are ready, and which doctrine the fleet takes into the next battle.

1. THE SCREEN

Overall layout

Use a flat 1920 by 1080 composition with no card boxes and no persistent panel borders. The fleet sits over the normal scene under the required smooth near-black darkening. The composition has three parts: a compact ledger-style header, a 4 by 3 fleet field showing all twelve ships, and a 384 px side sheet for the currently selected ship or doctrine. The side sheet is exactly one fifth of the screen width and never grows. This keeps the visual language in the same family as the chosen after-run ledger while following the Orders Sheet rules on color, type, minimum size, and panels.

All twelve ships are scannable without scrolling. That is important here because refits move between ships freely and repair readiness is fundamentally a comparison problem. A user should never have to remember what was above or below the fold while deciding where a refit belongs.

Region 1: Fleet ledger header

Position: x 64 to 1496, y 40 to 196.

At x 64, y 40:

FLEET

Big Shoulders Display, 36 px, TEXT, all capitals.

Directly beneath it is the headline figure:

12 SHIPS

Azeret Mono, 46 px, TEXT.

To its right are three live fleet summaries in Azeret Mono, 22 px, with short Barlow 17 px TEXT2 labels:

READY [live count] / 12
REPAIR [live count]
REFITS [occupied / available]

These are derived summaries, not new rules. Their job is to tell the owner what needs attention before the owner reads any individual ship.

Below them, at y about 152, is one doctrine line:

DOCTRINE KEEP THE DAWN WATCH 40 CR

The doctrine name is Big Shoulders Display, 28 px, TEXT. The cost is Azeret Mono, 18 px, TEXT2. Beneath it is a plain, one-line rule summary, in Barlow, 17 px, TEXT2:

Adjacent ships take 15% less hull damage next battle.

The full current wording is preserved in its hover tip:

"Keep the dawn watch. Next battle, ships next to an ally take 15% less hull damage. Costs 40 credits per battle."

The doctrine line is clickable. Clicking it replaces the ship detail in the right side sheet with the doctrine details described in Region 3. It is not a second mode or screen. The sheet does not change its size or position.

The current general rule line about refits, marks, repairs, shipyards, and drydocks leaves the permanent surface. Its full current text is kept in a hover tip over the FLEET heading. This keeps the general rule retrievable without keeping a dense line on the permanent surface.

Region 2: Twelve-ship fleet field

Position: x 64 to 1496, y 220 to 948.

Four columns, three rows.

Each berth is 340 px wide and about 226 px high, with 24 px between columns and about 17 px between rows.

Each berth contains:

A ship picture across the upper portion, about 340 by 88 px. It should be a clean side or three-quarter view that reads as that ship alone, with no overlapping card, tag, or HUD decoration.

Below it:

SHIP NAME, MK I

Big Shoulders Display, 28 px, TEXT. Two lines are reserved so long names never need to be shrunk below the Orders Sheet minimum of 14 px, or clipped.

Next:

Vigil-class cruiser

Barlow, 17 px, TEXT2.

Then one compact readiness line:

HULL 135 / 135

followed by the segmented hull meter, then

3 CP

Figures use Azeret Mono, 18 px. "HULL" and "CP" use Barlow, 17 px, TEXT2. The hull value becomes TEXT2 when it is not at maximum, and the hull meter shows both total capacity and current damage, so readiness can be judged at a glance. The meter does not need a percent label. Damaged ships also receive a plain text repair command in this berth, using the same repair action and cost already in the pack.

The final line shows refit occupancy graphically:

REFITS

plus one or two square slot icons, according to that ship's actual slots.

The icons are neutral when empty. An installed refit uses its own small monochrome icon. Hovering an installed refit gives its name and full rule. Hovering an empty slot gives:

Empty refit slot.

That is enough information to scan the four fleet decisions without turning each berth back into the current crowded card.

The first eight berths, in current fleet order, are:

1. WRATH OF VESPER, MK I, Vigil-class cruiser, hull 135/135, 3 CP, two empty refit slots.
2. VIGILANT ASH, MK I, Harrow-class destroyer, hull 25.5/85, 2 CP, with its shown empty refit slot.
3. COLD FURY, MK I, Warden-class frigate, hull 15/50, 1 CP, with its shown empty refit slot.
4. OATH FLAME, MK I, Vigil-class cruiser, hull 135/135, 3 CP, two empty refit slots.
5. RESOLVE OF THE REACH, MK I, Harrow-class destroyer, hull 85/85, 2 CP.
6. CINDER VOW, MK I, Warden-class frigate, hull 50/50, 1 CP.
7. BURNING SPIRE, MK I, Vigil-class cruiser, hull 135/135, 3 CP.
8. UNYIELDING OATH, MK I, Warden-class destroyer, hull 85/85, 2 CP.

Berths 9 through 12 hold the four ships that are below the current capture's fold. The pack does not give their names, classes, hull values, CP values, or refit slots, so I am not inventing those values. Their berths use exactly the same layout as the first eight, with their real names, classes, hull values, CP values, and refit slots shown when the implementation supplies them. Berths are populated in the same current fleet order and no ship is rearranged to fill the first row.

Region 3: Selected ship side sheet

Position: x 1536 to 1920, full height. Width 384 px.

The sheet uses the same smooth black scene darkening as the rest of the screen. It is not drawn as a card with a border or a boxed panel. It starts dark and stays dark.

Clicking any ship makes that ship the subject of this sheet. The selected berth does not gain an orange border or an outlined box. It remains in the same grid and keeps its same picture, name, class, hull, CP, and refit slots. The side sheet alone is the selection signal.

At x 1568, y 48:

WRATH OF VESPER

Big Shoulders Display, 30 px, TEXT.

Below:

MK I · Vigil-class cruiser

Barlow, 17 px, TEXT2.

The sheet then holds four compact information groups.

Readiness, y about 120 to 270

Azeret Mono figures at 20 px with Barlow 17 px labels:

HULL 135 / 135

with segmented meter

SHIELDS 20 +8/TURN
ARMOR 20%
SPEED 4 TURNS 2 EVASION 5
3 CP

Shield figures alone may use Glacier#92b8e8. Everything else uses the normal text strengths.

For a damaged ship, a plain text repair command appears directly beneath the hull meter when repair is available. It uses the same repair action and cost already in the pack. It is not an orange button.

Combat, y about 292 to 470

Ability name in Barlow, 18 px, TEXT:

CONCENTRATED FIRE

Its full rule appears on hover over the ability name.

Below are compact weapon entries using the weapon name plus arc icon:

SEAR BATTERY PORT
SEAR BATTERY STARBOARD
OATH LANCE PROW

Names use Barlow 17 px TEXT. Arc labels use Azeret Mono 17 px TEXT2.

Hovering each weapon reveals its complete current sentence, including shot count, damage, range, reload, and arc, so no combat number is lost. Hovering the ability name reveals its complete current rule.

This keeps the combat identity available without forcing weapon prose into every one of the twelve fleet berths.

Captain, y about 492 to 650

A single captain portrait sits at about 88 by 88 px.

Beside it:

GARRICK VANE

Big Shoulders Display, 28 px, TEXT.

Lieutenant

Barlow 17 px, TEXT2.

Below:

0 / 30 TO COMMANDER

Azeret Mono 18 px, TEXT2, with a simple progress meter.

Then:

NO PERKS YET

Barlow 17 px, TEXT2.

When a captain has perks, their compact icons occupy this same line. Hover opens their full rules.

Refits, y about 676 to 886

REFITS

Big Shoulders Display, 28 px, TEXT.

Each actual refit slot is shown as a square slot glyph with its refit name beside it. Empty slots read:

EMPTY

Barlow 17 px, TEXT2.

An occupied refit shows icon, name, and the ship currently carrying it.

Refits still move freely between ships. The player grabs an occupied refit slot from either the selected ship sheet or a fleet berth and drops it onto a valid empty slot in either place. Empty slots in both places are valid drop targets. A ship's one or two real slots are shown in both places, so the player never has to guess where a refit lives.

While a refit is being moved, Ember#ff8a3a is used only on the refit currently being acted on and the valid slot it may enter. The color is used for immediate action feedback only. It does not add a permanent outline or an accent frame.

Region 4: The one action box

Position: x 1600 to 1888, y 976 to 1032. Height 56 px.

There is exactly one outlined box:

DONE
[current key]

Two-pixel square Ember outline. Barlow for DONE, Azeret Mono for the key. Under the pointer it fills Ember as required.

It does exactly what the current screen's DONE button does: leave the fleet screen after the user has made the fleet choices. It does not save a loadout, confirm a doctrine, or open another step.

Relocation list

Nothing from the current ship cards or screen is deleted.

For the real ships whose detailed combat data is supplied, that means Wrath of Vesper's Concentrated Fire and its three named weapons move to the selected ship side sheet, in the form described in Region 3. All other ships' weapons, abilities, and other detailed data stay where they are in the pack and are covered by the same relocation rule: they move to the side sheet when that ship is selected. Their ship-card lines do not change. Their fleet picture slot, name, class, hull and CP, and refit slots do not change.

The current general rule line about refits, marks, repairs, shipyards, and drydocks moves from the permanent surface into a hover tip over the FLEET heading.

The doctrine rule moves from its current position into the top line of Region 1 and into the doctrine detail in the side sheet.

The ship weapons, abilities, and other detailed data move from the crowded fleet cards into the side sheet for the selected ship only.

The current DONE button moves from its present position into the one fixed action box in Region 4.

2. RISKS

Risk 1: Hiding the numbers could make comparison slower

The current screen is ugly and dense, but it does expose nearly every statistic simultaneously. Moving detailed ship data into the side sheet and behind hover states could slow the first comparison, because a player who used to scan one card would now need to select a ship or hover a name to see its weapons and ability. That risk is real. The answer is to keep the numbers that actually drive this screen's decisions visible across all twelve berths: hull, CP, refit occupancy, and live readiness counts. Those are the comparisons a player makes before selecting anything. The deeper data is then one selection away, and it is shown in the same place every time, so the cost is a single click, not a search. Because that click also gives the player the repair command, the refit slots, and the captain, the selection becomes a useful step rather than a tax. Keep the fleet decisions.

Risk 2: Twelve ship pictures could turn the redesign into an art-production project

The design depends on ship recognition pictures, and adding twelve bespoke illustrations plus captain portraits could turn a layout cleanup into a large art task. The pack supplies no ready art for the four ships below the fold, and it supplies no captain portrait asset. The layout cannot wait for that art, and it must not invent the missing ships. The answer is to make the layout require a picture slot, not require twelve bespoke paintings. Each ship gets the same clean 340 by 88 px slot, filled with a simple side or three-quarter silhouette in its class shape and color, with the ship name beneath it in the same position every time. That silhouette can be replaced later by a finished illustration without changing the layout, spacing, or text. The captain portrait uses the same approach: a simple portrait placeholder in the same 88 by 88 px position. This keeps recognition working at the fleet scale while the finished art can arrive later. Keep the fleet decisions.

Verdict: Keep the fleet decisions.

## Chair notes on this leg (not part of the leg)

- First ChatGPT council leg; gate clean at both ends. Its structure (4 by 3 berth field plus an exactly one-fifth side sheet, DONE kept as the one box doing exactly what DONE does today) is the closest match to the chair's FL1 lean with an FL2 sheet attached, and it is the only leg that refused to invent the four below-fold ships.
- Slips, verified against the pack: the doctrine hover quote adds words the game does not have ("Costs 40 credits per battle"; the pack reads "Costs 40 credits"). The name floor is misstated once as 14 px (the orders sheet floor is 17 px, names 28 px). The berth and sheet both offer a "repair command using the same repair action and cost already in the pack"; the pack contains no repair action or cost, and its rule line puts repairs at shipyards and drydocks, so the chair does not adopt an on-screen repair action. The verdict phrase "Keep the fleet decisions" also leaks into both risk paragraphs; the verdict itself is within the five word limit.
- Adopted by the chair: the header's live counts (ready, repair, refits) as derived figures; the doctrine living in the side sheet when clicked; ember used only as drag feedback while a refit is held (the orders sheet's "what it acts on" reading), never as a standing frame.
