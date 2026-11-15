# Flash leg, issue 794 stage 3 Fleet (Gemini, Quick answers 3.5 Flash-Lite, verified in the picker before and after)

Chat: https://gemini.google.com/app/d143d526bc58a9a2
Ran Nov 15, 2026, 09:46 to 09:48 CST (runtime measured). Pack attached as design_pack_fleet.txt, file chip confirmed before the prompt was sent.

## Full answer, verbatim

THE SCREEN. The screen holds the decision of which ships to repair, refit, ready for battle, and which doctrine to set.

Top bar at y equals zero to eighty pixels, spanning full width. Left side shows the doctrine headline and description in Barlow font at TEXT strength, paired with an action key to cycle doctrines. Right side shows the active deployment tally and credits count in Azeret Mono at TEXT2 strength.

Central main view at y equals ninety to nine hundred eighty pixels, spanning full width. It displays a scrollable list of all twelve ships in two side by side columns of six cards each. Each ship card shows its name in Big Shoulders Display capital letters at TEXT strength, its class and command point cost in Barlow at TEXT2 strength, and its hull status bar with numeric figures in Azeret Mono at TEXT2 strength. A thumbnail ship picture sits beside each name. The first viewport guarantees visibility of the first six ships, while the remaining six ships require a simple vertical scroll.

Right side sheet from x equals fourteen hundred forty to nineteen twenty pixels, spanning y equals ninety to nine hundred eighty pixels. This fifth of the screen acts as the detail inspector. When a ship card is clicked, this sheet displays its full weapon loadout, captain name, rank, experience progress, ability details, and refit slots. Refits move freely between ships by dragging a refit icon from one ship card onto another ship or into this inspector sheet.

Bottom action box at x equals fourteen hundred forty to nineteen twenty pixels, spanning y equals nine hundred ninety to ten eighty pixels. It features a two pixel square ember outline, fifty six pixels tall, containing the word DONE and the corresponding key on the right, with a filled ember background under the pointer.

Relocation list for items moved off the main screen:

Specific weapon stats, ranges, and reload numbers move to a hover tip over the ship weapon icons.

Captain names, ranks, and experience bars move to a hover tip over the ship captain portraits.

Ability rule sentences move to a hover tip over the ship ability icons.

Empty refit slot text lines move to the right side detail inspector sheet, accessed by clicking any ship card.

The doctrine cost text and repair rules move to hover tips on the doctrine banner and repair buttons.

RISKS.

Density overload from packing twelve ships and their stats into two columns. The design answers this by using thumbnail pictures instead of text blocks, pushing deep stats into hover tips, and utilizing the right side sheet for overflow.

Forgetting the refit mechanics between ships. The design answers this by ensuring refits can be dragged directly between ship cards or managed inside the right side detail inspector sheet, preserving full freedom of movement.

Verdict: Clear visual ship cards.

## Chair notes on this leg (not part of the leg)

- Layout contradiction: the central view is specified as spanning the full width at the same y band where the right side sheet sits (x 1440 to 1920); both cannot hold. The chair reads the intent as a list plus inspector (the FL2 shape), not a grid.
- Invented content: an "active deployment tally and credits count" on the top bar and "repair buttons" appear nowhere in the pack's evidence; the current screen has neither a credits readout nor repair buttons (repairs happen at shipyards per the rule line). Not adopted.
- The relocation list again lumps by category rather than naming each line's home, and its card never shows weapon icons for the weapon hover to hang on.
- Sound parts: DONE stays the one box; refits drag directly between cards, which matches the game's free movement rule and is adopted into the chair's thinking.
