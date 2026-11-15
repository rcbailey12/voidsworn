# Qwen leg, issue 794 stage 3 Fleet (Qwen3.8-Max, verified in the selector before and in the chat header after)

Chat: https://chat.qwen.ai/c/2ca34f81-f480-42b5-ba36-330b8042152e
Ran Nov 15, 2026, 09:46 to 09:53 CST (runtime measured). Pack attached as design_pack_fleet.txt; the first send was blocked while the file parsed, the runner waited and sent the same prompt once. Single response, no A/B choice offered, nothing selected.

## Full answer, verbatim

Task 1: THE SCREEN

The screen's decision in one sentence:
The player reviews the fleet at a glance, decides which damaged ships to flag for repair, moves refits between ships if desired, and confirms the fleet to proceed. Everything else is a detail reachable in one hover or one click.

Layout, region by region, at 1920 × 1080
The background is the game scene dimmed to roughly 94 percent black under all text and art. Square corners everywhere. The dimmed art is faint enough that no detail competes with the fleet data. Nothing else is visible on the screen: no side navigation, no left column, no bottom bar, no extra buttons, no counts outside the headline figures.

Region A: Headline band (y 32 to 108, full width)
Left side: the word FLEET set in Big Shoulders Display, all capitals, 52 px, TEXT strength, white. No rule line under it; the refit rule lives in a hover tooltip on the FLEET headline (see the relocation list). Right side, same vertical band: four big headline figures in Azeret Mono, 40 px, TEXT strength, spaced across the width, one for each figure:
• 12 SHIPS
• 9 READY
• 3 DAMAGED
• 24 CP BUDGET
The numbers are the large elements; the labels (SHIPS, READY, DAMAGED, CP BUDGET) sit beneath each number in Barlow, 17 px, TEXT3. These four figures are the only fleet totals on the screen. There is no total CP cost shown for the fleet, and there is no per-ship cost total anywhere else on the screen.

Region B: Doctrine row (y 124 to 180, full width, 56 px tall)
A single horizontal line, left-aligned, vertically centered in its band.
• Doctrine name: DAWN WATCH in Big Shoulders Display, capitals, 28 px, TEXT strength.
• One-line effect beside it: "Allies adjacent to another ship take 15 % less hull damage" in Barlow, 17 px, TEXT2.
• Cost at the right end of the row: 40 CR in Azeret Mono, 17 px, TEXT2.
• Key hint after the cost: C in Azeret Mono, 17 px, TEXT2 (reads "Change C").
The row is clickable. Clicking it opens the doctrine side sheet (described below). The row itself is not ember-outlined; it is plain text on the dark field. Ember is reserved for the one action box in Region D.
The old full-width doctrine banner with its rule sentence is gone from the surface. The full rule text is in a hover tooltip on this row (see the relocation list).

Region C: Ship grid, all twelve on one screen (y 200 to 900)
No scroll. Six columns, two rows. Every ship is visible and scannable without any interaction.
Column math: 48 px left margin, 48 px right margin, 16 px gaps between columns. Usable width 1920 − 96 = 1824 px. Six columns of 290 px each take 1740 px; five gaps of 16 px take 80 px; 1740 + 80 = 1820 px, leaving 4 px of slack distributed in the outer margins.
Row math: two rows of 340 px each, 20 px gap between them. Total grid height 700 px (y 200 to 900).
Each cell (290 × 340 px) contains, top to bottom:
1. Ship picture. A side-on silhouette illustration of the hull, 200 px wide, 80 px tall, centered. This is the visual anchor of the cell; it is the only picture on the cell.
2. Ship name. Big Shoulders Display, capitals, 28 px, TEXT strength, centered. Maximum two lines. "WRATH OF VESPER" fits on one line; "RESOLVE OF THE REACH" is the longest name and wraps to two lines (see Risk 1).
3. Class label. Barlow, 17 px, TEXT3, centered. "Vigil-class cruiser." This is a joining label, not a sentence, so TEXT3 keeps it quiet. No period is needed after the class label; it is a label, not a sentence.
4. Hull meter. A horizontal segmented bar, 220 px wide, 10 px tall, centered. Filled segments in warm white; empty segments are hairline outlines. The count of filled segments is the only hull signal on the cell. There is no hull number, no percentage, and no "3 / 4" text on the cell.
5. Bottom row of the cell. Left side: CP cost in Azeret Mono, 17 px, TEXT2 ("3 CP"). Right side: refit slot icons. Each slot is a 16 px square; a filled slot is solid, an empty slot is a hairline outline. No refit names or text on the cell.
What is NOT on the cell: stats (shields, armor, speed, turns, evasion), the ability name and rule sentence, weapon lines, captain block, ship mark, XP, perks, the word REFITS, and any rule sentence. Those live in the hover tooltip or the click side sheet below.
Damaged ships: the hull meter gap is the signal. No color change, no icon. The player sees three gapped bars among the twelve cells and knows at a glance that three ships are damaged. The headline figure "3 DAMAGED" in Region A confirms the count.

Region D: One action box (y 932 to 988, right-aligned with 48 px right margin)
The single ember-outlined box on the screen.
• 2 px square ember (#ff8a3a) outline, 56 px tall, roughly 200 px wide.
• Text: DONE in Barlow, 20 px, TEXT strength, left inside the box.
• Key: D in Azeret Mono, 17 px, TEXT2, right inside the box. Reads "DONE D."
• Under the pointer the box fills with solid ember; the text switches to near-black for contrast.
• This confirms the fleet composition, any queued repairs, any refit moves, and the selected doctrine, and proceeds to the next screen.
No other element on the screen carries the ember outline.

Hover tooltip (any ship cell)
A near-black square with a 1 px hairline edge, appearing beside the pointer. Contents, top to bottom:
• Ship name and mark: "WRATH OF VESPER, MK I" in Big Shoulders Display, 28 px, capitals.
• Five stats in two columns, Azeret Mono for figures, Barlow for labels, 17 px, TEXT2. Shield value in Glacier #92b8e8 (the only place Glacier appears on this screen): "Shields 20, +8 / turn." Armor, Speed, Turns, Evasion in TEXT2.
• Ability name in Barlow bold, 17 px, TEXT. Rule sentence beneath in Barlow, 17 px, TEXT2.
• Captain name and rank: "Lieutenant Garrick Vane" in Barlow, 17 px, TEXT2.
The tooltip is the "one hover" layer. It carries everything the old card showed except weapons, captain XP and perks, and the refit text. Those three live in the click side sheet.

Click → Ship side sheet (any ship cell)
A side sheet opens on the right edge, 384 px wide (one-fifth of 1920), never exceeding 480 px. Near-black, square corners, 1 px hairline edge on its left side. It overlays the grid; it does not reflow it.
Contents of the sheet, top to bottom, scrollable within the sheet if needed:
• Larger ship picture, 320 × 120 px.
• Name, class, mark.
• Full stat block with small meters for shields (Glacier), armor, speed, turns, evasion.
• Ability name and full rule sentence.
• Weapon list: each weapon as a line. Name in Barlow 17 px TEXT; arc, damage, range in Azeret Mono 17 px TEXT2. Example: "Sear battery. Port broadside 4×6, range 5."
• Captain block: name, rank, XP progress ("0 / 30 to Commander") in Azeret Mono, perk list or "No perks" in Barlow 17 px TEXT2.
• Refit slots, interactive.
• Close key: ESC in Azeret Mono, TEXT2, top-right of the sheet.

How refits move between ships
Inside the ship side sheet, the player clicks a filled refit slot. The slot gains a 2 px ember outline, marking it as selected. The player then clicks another ship in the grid. The refit moves to that ship's first empty slot, and the side sheet updates. If the target ship has no empty slot, the move does not happen and the selected slot stays selected; no error message is shown, because the target's slot icons are visible in the grid behind the sheet.
Alternative path: within the side sheet, a "MOVE TO" list names every other ship in Barlow 17 px TEXT2, with its empty slot count in Azeret Mono. Clicking a ship name in that list moves the selected refit there directly, without clicking in the grid.
This preserves the rule that refits move freely between ships. The old rule sentence ("Refits can be moved between ships freely…") is no longer on the surface; it is in the hover tooltip on the FLEET headline (see the relocation list).

How doctrine is set
Clicking the doctrine row (Region B) opens a doctrine side sheet, same 384 px width, same visual treatment. It lists every available doctrine:
• Name in Big Shoulders Display, 28 px, capitals.
• One-line effect in Barlow, 17 px, TEXT2.
• Cost in Azeret Mono, 17 px, TEXT2.
The currently active doctrine is marked with a small filled square to its left. Clicking a different doctrine selects it, updates the doctrine row, and closes the sheet. The full rule text for the selected doctrine is in the hover tooltip on the doctrine row, not in the sheet.

Relocation list (every line from the current card not on the redesigned cell)
Current card content | Where it now lives
Ship mark ("MK I") | Hover tooltip on the ship cell
Five stats as a sentence ("Shields 20, +8/turn. Armor 20 %. Speed 4. Turns 2. Evasion 5.") | Hover tooltip on the ship cell; full meters in the click side sheet
Ability name and full rule sentence | Hover tooltip (name + sentence); click side sheet repeats it with weapons context
Every weapon line ("Sear battery. Port broadside 4×6, range 5.") | Click side sheet, weapon list section
Captain name, rank, XP sentence, perks sentence | Hover tooltip shows name and rank; click side sheet shows XP bar and perk list
REFITS heading and per-slot text ("Empty refit slot.") | Cell shows slot icons (visual); click side sheet shows slot names and interactive management
Rule line under FLEET title ("Refits can be moved between ships freely…") | Hover tooltip on the FLEET headline in Region A
Doctrine banner full rule sentence | Hover tooltip on the doctrine row (Region B)
Nothing is deleted. Every sentence and figure from the current card is reachable within one hover or one click, and the tooltip and side sheet together hold every relocated line.

Task 2: RISKS

Risk 1: Name overflow at 28 px in a 290 px column.
Big Shoulders Display at 28 px in capitals is wide. The longest name in the fleet, RESOLVE OF THE REACH, is 20 characters including spaces. At 28 px, that name measures roughly 330 px wide on one line, which exceeds the 290 px cell width and the 220 px picture width. If the name were forced to one line, it would clip at the cell edges or shrink the font, breaking the 28 px rule.
Answer. The cell allows the name to wrap to two lines. "RESOLVE OF" on line one, "THE REACH" on line two. The cell height budget (340 px) absorbs the extra line without compressing anything else. I verified the next-longest names (WRATH OF VESPER, UNYIELDING OATH, BURNING SPIRE) and they fit on one line. The two-line case is the worst case and it still fits. No name in the current fleet exceeds two lines at 28 px in 290 px.

Risk 2: Refit-move interaction is hidden inside a click and could stall the player.
The current screen puts the word REFITS on every card, so the player knows refits exist. In the redesign, refit slots are small 16 px squares on the cell and the full interaction lives inside the side sheet. A player who never clicks a ship might not realize they can move refits at all, or might not understand the select-then-click-target flow. This risks a soft lock where the player skips refit management every run because they never discover it.
Answer. Two safeguards. First, the refit slot squares on each cell are always visible; an empty slot is a hairline square that reads as "something goes here," and a filled slot is a solid square that reads as "something is here." The visual gap in the grid is a quiet prompt. Second, the first time the player opens a ship side sheet in a run, a single line of TEXT2 in Barlow appears at the top of the refit section: "Click a refit, then click another ship to move it." This is a one-time contextual hint, not a permanent sentence, so it respects the say-less rule. The alternative MOVE TO list in the side sheet gives a second, more explicit path for players who prefer a menu over clicking across the grid.

Verdict: one card per ship

## Chair notes on this leg (not part of the leg)

- Invented figures, verified against the pack: the headline band claims 9 READY and 3 DAMAGED, but the capture shows exactly two damaged ships (Vigilant Ash at 25.5/85 and Cold Fury at 15/50), so the ready count is 10 of the 12 with the four below the fold unknown; and "24 CP BUDGET" invents a budget the game does not show (CP is a per-ship cost; the eight legible ships sum to 17). The leg then repeats its own invented damage count ("three gapped bars", "three ships are damaged"). None of it is adopted; the chair's mockups carry only figures the evidence supports (12 ships, 2 damaged, and no CP total).
- The cell drops hull figures entirely (meter only), which cuts against the headline-numbers direction Ryan picked in R260; the chair keeps figures on every card.
- Sound parts adopted in spirit: the complete tabular relocation list; the click-a-refit then click-the-target-ship move flow; the doctrine opening in the same side sheet rather than a second surface.
- Minor: the doctrine is renamed DAWN WATCH (as DeepSeek also did); DONE is given the key D, which the current screen does not state.
