# DeepSeek leg, issue 794 stage 3 Fleet (DeepThink on, Search on, both verified visibly before and after)

Chat: https://chat.deepseek.com/a/chat/s/1ac5b10b-9ee5-4a08-b7e3-e882d10297d2
Ran Nov 15, 2026, 09:46 to 09:50 CST (runtime measured). Pack attached as design_pack_fleet.txt and shown in the sent message. Thought for 80 seconds. The runner noted the toggles' accessibility state read unchecked while both buttons were visibly blue-filled on; the visual check is the gate used throughout, and it passed at both ends.

## Full answer, verbatim

Decision: Which ships to repair, which to refit, which are ready for the next battle, and which doctrine to set.

THE SCREEN

All twelve ships are scannable on one 1920 by 1080 screen. No scroll. The screen sits on a full-bleed dock scene with a smooth 94 percent black darkening under all words. No panels, no pills, no glows, no shadows. The only outlined box is the action box.

Top left, headline. x 64, y 40. "FLEET" in Big Shoulders Display, 64 px, capitals, TEXT.

Doctrine strip. x 64, y 120, w 1320, h 72. Text sits directly on the darkening. "DAWN WATCH" in Big Shoulders Display 32 px capitals TEXT. "40 CR" in Azeret Mono 24 px TEXT2. "ALLY ADJACENCY 15% HULL" in Barlow 22 px TEXT2. Hover over the strip opens a near-black hairline hover tip with the full current doctrine sentence. Click opens the Doctrine dialog.

Roster header. x 64, y 216, w 1320, h 28. Labels "SHIP", "HULL", "CP", "READY", "REFITS" in Barlow 18 px TEXT2.

Roster, twelve rows. x 64, y 252, w 1320, h 52 per row, 4 px gap. Rows 1 to 8 are the named ships from the capture. Rows 9 to 12 are the four lower ships with the same structure. Each row shows:

- Ship silhouette icon, 44 by 44, x 64, y plus 4. Hover shows class.
- Ship name in Big Shoulders Display 28 px capitals TEXT, x 120. Mark "MK I" in Azeret Mono 18 px TEXT2 on the second line under the name.
- Hull figure, Azeret Mono 22 px TEXT, x 520. Segmented hull meter, 110 by 6, x 520, y plus 36, neutral gray.
- CP figure, Azeret Mono 20 px TEXT2, x 660.
- Readiness word, Barlow 20 px TEXT2, x 740. Click toggles READY and STANDBY. Damaged ships show REPAIR until repaired.
- Refit slot icons, small neutral squares at x 880 and x 900. Hover gives "Empty refit slot" or the refit name. Click opens the Refit Tray.
The selected row gets an ember underline under the ship name only. That ember marks what the action box acts on. Nothing else in the roster is orange.

Selected ship side sheet. x 1480, y 120, w 376, h 820. This is about one fifth of screen width and under the quarter cap. Smooth darkening, no panel border. Contents:

Ship picture, 376 by 150, at top.

Ship name in Big Shoulders Display 36 px capitals TEXT, y 280.

Mark and class, Azeret Mono 20 px and Barlow 20 px TEXT2, y 324.

Hull big figure, Azeret Mono 72 px TEXT, y 368, with "/135" in Azeret Mono 28 px TEXT2. Segmented hull meter, 320 by 10, y 448.

Shield readout in glacier only, Azeret Mono 20 px, y 476, with glacier shield meter, 320 by 8, y 502.

Compact stat line, Azeret Mono 18 px TEXT2, y 526: "ARM 20% SPD 4 TRN 2 EVA 5". Hover on this line gives the full five-stat sentence exactly.

CP figure, Azeret Mono 24 px TEXT2, y 562.

Captain line, Big Shoulders Display 28 px capitals TEXT, y 596, with rank in Barlow 20 px TEXT2 below. Hover gives the exact progress sentence and perks line.

Ability name, Big Shoulders Display 28 px capitals TEXT, y 660. Hover gives the exact ability rule sentence.

Weapons line, Azeret Mono 18 px TEXT2, y 704: "WEAPONS 3". Hover gives every weapon sentence exactly as in the current card.

REFITS heading, Barlow 20 px TEXT2, y 744. Slot rows at y 772 and y 804, Barlow 20 px TEXT2, for example "SLOT 1 EMPTY". Hover gives "Empty refit slot" or the full refit rule. Click opens the Refit Tray.

Action box. x 1480, y 960, w 376, h 56. One box only. 2 px square ember outline, 56 px tall, key on the right in Azeret Mono TEXT2. Label in Barlow TEXT. Default label "COMMIT FLEET C". When a damaged ship is selected, label becomes "REPAIR VIGILANT ASH R". When a refit is held, label becomes "MOVE REFIT M". Fill is ember under the pointer only. This box commits the fleet, repairs the selected damaged ship at the shipyard or drydock, or confirms a refit move.

Doctrine dialog. Near-black square with hairline edge, about 480 by 420, opened by clicking the doctrine strip. It lists doctrines by name in Big Shoulders 28 px capitals, cost in Azeret Mono, and hover shows the full effect sentence. Click a doctrine row to set it immediately. Escape closes. No second action box appears.

Refit Tray dialog. Near-black square with hairline edge, about 480 by 520, opened by clicking any refit slot. It lists every installed refit in the fleet with source ship and slot. Hover gives the full refit rule. Click a refit row to pick it up. The source slot is marked pending, the action box becomes "MOVE REFIT M", you select the target ship, click an empty slot, then press the action box. Escape cancels. Refits still move freely between ships.

Relocation list, nothing deleted.

Ship name and mark: roster row and side sheet.

Class: hover on the ship silhouette or name.

Hull figures and segmented bar: roster hull figure and meter, plus side sheet big hull figure and meter.

Command point cost: roster CP column and side sheet CP.

Five stats: shields on the side sheet glacier readout and meter; armor, speed, turns, evasion on the compact stat line; full five-stat sentence on hover over that line.

Ability name and full rule sentence: ability name on the side sheet, full rule sentence on hover over the ability name.

Every weapon sentence: side sheet "WEAPONS 3" line, full weapon sentences on hover.

Captain name and rank: side sheet captain line; progress sentence and perks on hover over the captain line.

REFITS heading and one line per slot: side sheet REFITS heading and slot rows; empty slot text on hover; click opens Refit Tray.

Rule line under title: hover on REFITS heading and header of Refit Tray.

Doctrine banner full sentence: hover on doctrine strip and Doctrine dialog rows.

DONE button: replaced by the action box, default "COMMIT FLEET C".

RISKS

Density risk. Twelve rows plus a side sheet can become a wall of figures. The design answers by keeping the roster to name, hull figure and meter, CP, readiness word, and refit icons only. All sentences move to hover or click. The side sheet holds only five key items: picture and name, hull, shields and stats, captain, refits. Ability and weapons are hover only.

State and rule risk. The context action box plus Refit Tray plus Doctrine dialog adds state, and orange could leak into damaged ships or meters. The design answers with one action box state machine: COMMIT, REPAIR, MOVE. Escape cancels a held refit. Commit is disabled while a refit is held. Hull meters stay neutral, shields use glacier only, and ember appears only on the action box outline and the selected target underline. The side sheet is 376 px wide, under the quarter cap, and no panels or rounded corners are used.

Verdict: Keep names and hull figures.

## Chair notes on this leg (not part of the leg)

- Strongest structure in the round so far: a twelve row roster (the comparison survives) with a one-fifth side sheet for the selected ship, and the most complete relocation list of the legs, as on the debrief round.
- Inventions the chair does not adopt: a READY/STANDBY toggle and a COMMIT FLEET action (the current screen has no readiness toggle; readiness is read off hull state, and its only commit is DONE); a REPAIR action on this screen, which contradicts the game's own rule line in the pack (repairs happen at shipyards and drydocks); the doctrine renamed to DAWN WATCH (the pack's doctrine is "Keep the dawn watch").
- Borderline but defensible: the ember underline on the selected row, since the orders sheet lets ember mark what the action acts on; the chair's mockups keep selection to a hairline and reserve ember for the box, and note the difference.
