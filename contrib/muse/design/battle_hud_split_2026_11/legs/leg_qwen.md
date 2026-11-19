# Leg: Qwen (Qwen3.8-Max, selector verified before and header after; run Nov 17, 2026)

WATERLINE

Concept summary

I am adopting and refining seeded concept (a), LEDGER SPLIT. The change: the top bar carries only context you glance at (turn, objective, enemy, Nemesis), and the bottom bar carries everything you act on, laid out left to right in the exact decision order. The middle of the screen - the board - is untouched. I am calling it WATERLINE because the information sits at the two horizons of the frame and the play space is the open water between.

I considered concept (b), COMMAND DECK, and rejected it. A floating centre-bottom strip plus four corner cards fragments the reading order into five separate glances. The player's eye must jump from corner to corner to centre. That is hunting, not reading. WATERLINE keeps every decision item in one unbroken left-to-right sweep along the bottom edge, which is how the eye already wants to travel during a turn.

1. Placement table

Every numbered item from today's rail, plus the occasional items, placed.

1 - Turn header ("Round 1", "Your turn", "3 of 3 ships to act") - Top bar, left cluster. "Round 1" in Azeret Mono 17 px, "YOUR TURN" in Big Shoulders 28 px ember, ship count in Barlow 17 px. All on one line, left-aligned at x=40.
2 - Objective ("Objective: break their fleet") - Top bar, left cluster, second line under the turn header. Barlow 17 px.
3 - Ship name ("UNYIELDING OATH") - Bottom bar, section 1 (leftmost). Big Shoulders 32 px capitals.
4 - Ship class ("Vigil-class cruiser") - Bottom bar, section 1, directly under the name. Barlow 17 px.
5 - Hull and Move ("Hull 135/135", "Move 0 of 4") - Bottom bar, section 1, under class. Azeret Mono 17 px, one line.
6 - Shields (four-facing cross, Glacier) - Bottom bar, section 1, right of the hull line. The cross stays a cross but is drawn at 56 x 56 px, centred on a point, with the four numerals at 17 px in Glacier.
7 - Status line ("The enemy fleet is focusing its fire on this ship.") - Bottom bar, section 1, revealed on hover over the ship name or by pressing Tab while the ship is selected. SAY LESS: it is one hover away, never deleted. When shown, it appears as a single Barlow 17 px line under the shield cross, fading in over 150 ms.
8 - Guns table (three weapon rows) - Bottom bar, section 2. Three rows, Azeret Mono 17 px, each row: name, facing letter, range band, state. Stacked vertically, 20 px line height, 60 px block.
9 - Target ("Target FLEET MARSHAL PETRA VALK") - Bottom bar, section 2, under the guns table. "Target" in Barlow 17 px, the name in Big Shoulders 22 px. Nemesis red when the target is the Nemesis.
10 - Odds and damage split - Bottom bar, section 2, under the target. Two lines, Barlow 17 px for the sentence, Azeret Mono 17 px for the figures.
11 - The FIRE box ("FIRE THE OATH LANCE", key Enter) - Bottom bar, section 3 (centre). The one box. Ember outline, square corners, 220 x 48 px. Big Shoulders 22 px. Sits alone with 24 px clear space on each side so nothing crowds it.
12 - Orders row ("Brace B", "Concentrated fire", "Turn Q E") - Bottom bar, section 4. One horizontal row, Barlow 17 px, key letters in Azeret Mono.
13 - Command row ("Command", "Fire for effect C", "End ship Space") - Bottom bar, section 4, second row under Orders. Same styling.
14 - Fleet strip (three ships, name + hull, ember bar on acting ship) - Bottom bar, section 5 (rightmost before the log gap). Horizontal: three ship entries side by side, each name in Big Shoulders 17 px capitals (the minimum for display type at this density), hull figure in Azeret Mono 17 px, ember bar under the acting ship.

Top-right cluster (Menu Esc, enemy line, Heat 3, Nemesis panel) - Unchanged. Top bar, right side. The top bar's right end simply aligns with this existing cluster so they read as one band.
Log ("Log L", last three lines) - Unchanged. Bottom-right corner, above the bottom bar's right edge. The bottom bar's content stops at x=1540 and the veil fades out by x=1580, leaving the log in its own clear corner from x=1600 to x=1880, y from 952 to 1032.

Occasional items:
Tree prompt card - Centred in the open middle of the screen, roughly at y=420 to y=620, x centred on 960. It dims the board behind it with a radial veil (60% at centre, 0 at edges). The bottom bar stays visible underneath so the player can still see their ship. The card itself has no box - words on a darkened patch, square corners, per the existing style.
Retreat control - Bottom bar, section 4, appended to the Command row as a fourth entry: "Retreat R". It is always present but low-contrast (Barlow 17 px, dimmed to 60% opacity) until hovered.
Phase banner ("ENEMY TURN" etc.) - Centred in the open middle, Big Shoulders 48 px capitals, ember or white depending on phase. Fades in over 300 ms, holds 1.8 s, fades out. No bar, no box. It floats in the clear space and does not interact with either bar.

2. Geometry at 1920 x 1080 design

Top bar: Position x=0, y=0, full width, 72 px tall. Left cluster (turn + objective): x=40 to x=460, two lines (line 1 at y=18, line 2 at y=46). Right cluster (menu, enemy, Nemesis): x=1420 to x=1880, existing layout, unchanged, vertically centred in the 72 px. Middle (x=460 to x=1420): empty, no text, no veil. Veil: under the left cluster, fading from 75% opacity at x=0 to 0 at x=520. Under the right cluster, fading from 0 at x=1360 to 65% at x=1920. The middle 900 px has no veil at all.

Bottom bar: Position x=0, y=936 (1080 minus 144), full width, 144 px tall. Five sections, left to right, with 24 px gutters: Section 1 Ship (name, class, hull/move, shield cross, status on hover), x start 40, width 264. Section 2 Guns/Target/Odds, x start 328, width 320. Section 3 FIRE (the FIRE box, centred in its slot), x start 672, width 264. Section 4 Orders/Command (two rows of orders, two rows of command incl. Retreat), x start 960, width 300. Section 5 Fleet (three ship entries horizontal), x start 1284, width 256. Total content span: x=40 to x=1540. Log gap: x=1540 to x=1600 is clear (no veil, no text); the log sits in the corner beyond. Veil: fades from 70% opacity at x=0 to 0 at x=1580. The veil is 144 px tall. Under the FIRE box the veil is at its local strongest to give the ember outline contrast.

Screen share: Left veil band today: 30% of screen (576 px x 1080 px); WATERLINE: gone. Top bar veil: two patches totalling about 920 px x 72 px at about 40% avg opacity = about 26,500 px2 effective. Bottom bar veil: 1540 px x 144 px at about 45% avg opacity = about 99,800 px2 effective. Top-right + bottom-right corners: today 3% (about 62,200 px2); WATERLINE 3%, unchanged. Total touched: today about 33% of 2,073,600 px2; WATERLINE about 9% (about 188,500 px2 effective).

The board is clear from y=72 to y=936, a vertical span of 864 px (80% of the height), across the full width except the thin top and bottom veils. Today the left 30% is blocked for the full 1080 px height. In WATERLINE, no vertical strip is blocked at all. The unbroken visible field is roughly 1920 x 864 minus the two corner elements, versus today's 1344 x 1080 minus corners.

3. How the decision order reads

Today the eye travels top to bottom down the left rail: ship, hull, shields, guns, target, odds, FIRE, orders, Command. In WATERLINE the eye travels left to right along the bottom bar: ship (section 1), guns/target/odds (section 2), FIRE (section 3), orders/Command (section 4). The sequence is identical. The only axis change is vertical-to-horizontal, which matches the natural reading direction and means the player never has to look up and then back down mid-decision.
The turn header and objective (items 1 and 2) sit in the top bar. These are context, not decisions. The player reads them at the start of a round and then their eyes drop to the bottom bar for the entire action sequence. This is the same split Ryan's references show: status up top, commands on the bottom.
The fleet (item 14) is at the right end of the bottom bar. After pressing "End ship", the eye is already travelling rightward and lands on the next ship's name. The ember bar marker makes the acting ship obvious without a search.

4. 1440p and 4K under the scale law

The scale law multiplies all design-px values by k (1.33 at 1440p, 2.0 at 4K) and by the player's UI scale (0.8 to 1.4). Because every dimension scales together, the share of the screen covered is identical at every resolution. The top bar is always 72/1080 = 6.7% of the window height. The bottom bar is always 144/1080 = 13.3%. The proportions do not change.
What does change is headroom: at 1440p (k=1.33) the shield cross renders at 74 x 74 px and the 17 px text floor renders at 22.6 px; everything is comfortable. At 4K (k=2.0) the shield cross renders at 112 x 112 px and the text floor at 34 px; fine detail like the four shield numerals and the gun facing letters is easy to read at a distance, and the gutters between sections could widen by 50% without any layout change.
At the low end (k=0.6, a short or small window): the top bar renders at 43 px, the bottom bar at 86 px. The 17 px text floor is the binding constraint: the three gun-table rows at 17 px each plus 3 px leading need 60 px of the 86 px bar height, leaving only 26 px for the target and odds lines. This is tight. Mitigation: at k below 0.75, the odds damage-split line collapses behind a hover on the odds percentage, per SAY LESS. The primary number ("92% to hit") stays visible. This keeps the bar honest at the floor without deleting information.
No layout reflow is needed between resolutions. The existing ui_scale.gd handles it.

5. What gets worse, honestly

The shield cross loses presence. Today it sits in a quiet vertical column with nothing competing beside it. In the bottom bar it is 56 px tall, flanked by hull figures and the ship name. It is still readable, but it is no longer a moment of pause. A player who relies on quickly checking all four facings will need to look more carefully. I accept this trade because the cross is a reference, not an action - you check it, you do not click it.
The guns table is denser. Three rows in a 60 px block in a horizontal bar feel more compressed than three rows in a 380 px wide vertical rail. The facing letter, range band, and state are all on one line per weapon, which is the same as today, but the narrower column width (320 px versus 380 px) means the "out of range" state text is closer to the weapon name. At 17 px this still fits, but it is snug.
The FIRE box is less of a culmination. In the vertical rail, the FIRE box sits at the end of a top-to-bottom sequence, and the eye arrives at it after reading everything above. In the horizontal bar, it is one station among five in a left-to-right sweep. It still has its 24 px clear space on each side and it is still the only box, but the sense of "everything led to this" is softer. I think this is acceptable because the ember outline and the square shape still make it the loudest element in the bar.
The fleet loses its anchor. At the foot of the vertical rail, the fleet list is a clear terminus: you have finished with this ship, here are your ships. In the bottom bar, the fleet is the rightmost section, which works for the "end ship, look right, pick next" flow, but it no longer feels like a footer. It feels like another column. This is a small loss of hierarchy.
The bottom bar is a single point of failure for attention. Today, if the player's eyes drift from the rail, they are still in the left third of the screen and can find their way back. With a bottom bar, a player who looks at the centre of the board must drop their gaze to the bottom edge to re-engage. This is a longer eye movement than sliding up or down a side rail. In practice, tactics players spend most of a turn looking at the board and dipping to the bar, so this is probably fine, but it is a real change in attention geometry.

6. Occasional items in detail

Tree prompt card: a mid-battle decision (for example, "The enemy offers a parley. Accept or refuse?") appears centred in the open middle at roughly y=420, x=960. It is two to four lines of Barlow 17 px with option keys in Azeret Mono. Behind it, a soft radial veil dims the board to 60% so the text is legible. The top and bottom bars remain fully visible and interactive underneath. The card dismisses on selection. It does not overlap either bar.
Retreat: lives in the bottom bar, section 4, as the last entry in the Command row: "Retreat R". It is always present but rendered at 60% opacity (still above the 17 px floor) so it does not compete with "End ship" for attention. On hover it brightens to full. This keeps it one key away and visible without being loud.
Phase banner: "ENEMY TURN" or "MOVEMENT PHASE" appears centred in the open middle, Big Shoulders 48 px, ember or white. It fades in over 300 ms, holds for 1.8 s, fades out over 400 ms. It does not interact with either bar. During the enemy turn, the bottom bar remains visible (the player can review their fleet) but the FIRE box and orders row dim to 40% opacity to signal that they are not actionable.

7. Notes on the evidence pack

One item I want to flag: the pack says the veil "fades to nothing at 30% of the window width" and then states "about 30% of the screen's area is dimmed." Because the veil is a gradient from full to zero, the effective dimming (area times average opacity) is closer to 15% of the screen at full-equivalent opacity. The 30% figure is the geometric extent. I have used the geometric framing throughout this document to stay consistent with the pack, but the perceptual impact of today's veil is less severe than "30% dimmed" implies. This does not change the conclusion that splitting is a large improvement, but it is worth noting for anyone comparing before-and-after screenshots: the before will look less dramatic than the number suggests.
I also note that the pack lists the rail width as 380 px starting at x=40, putting the right edge of the text column at x=420, while the veil extends to x=576. That 156 px of veil beyond the text is purely atmospheric. In WATERLINE I have kept a similar overshoot (the veil extends about 60 px beyond the last text in each cluster) to preserve the softness of the edge without wasting screen.

8. Build cost

This is a layout move inside the existing HUD code. No new rendering systems, no new shaders, no new input handling. The work is: reposition the existing rail labels and containers from a vertical Column to two horizontal HBoxContainers (top bar, bottom bar); replace the single full-height veil gradient with two horizontal veil gradients (one per bar); move the fleet list from a VBox at the rail foot to an HBox in section 5; add a hover-reveal for the status line (item 7) and the odds damage split at low k; add the Retreat entry to the Command row; centre the tree prompt and phase banner in the viewport instead of anchoring them to the rail. Estimated scope (the leg's own framing): two to three days of layout work in the existing HUD scene tree, plus a half-day of QA at 1080p, 1440p, and 4K.

9. The pick

WATERLINE. It preserves the full decision order in a single left-to-right sweep, it cuts the veiled screen area from roughly 33% to roughly 9%, it gives the board an unbroken 80%-height field in the centre, and it costs a layout refactor rather than a new system. The seeded concept (b), COMMAND DECK, fragments the reading order across five islands and I do not recommend it. WATERLINE is the refined (a), and I believe it is what Ryan was pointing at when he said "some up top, some on bottom" and "more traditional for a reason."
