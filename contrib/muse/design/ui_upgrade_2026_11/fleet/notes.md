# Fleet and refits, mockup round (issue 794, stage 3)

Screen: Fleet and refits (rank 2 on the audit list in ../audit.md). Evidence: the issue 644 capture campaign_map_after.jpg, read in full. Ryan picked DB1 for the after-run screen on Nov 15, 2026, which unlocked this round.

## The decision this screen holds

Which ships sail ready, which get repaired or refitted first, and which doctrine the fleet carries into the next battle. The comparison across twelve ships is the job of the screen; everything else is support.

## What the current screen does wrong

Twelve cards of about fifteen lines each, four across, scrolling. Ships never appear as pictures. Every captain is a Lieutenant at 0 of 30 to Commander with no perks yet, and that sentence is repeated twelve times. The one button is DONE. Two ships in the capture are damaged (Vigilant Ash at 25.5 of 85 hull, Cold Fury at 15 of 50) and nothing on the screen treats them differently from the ten whole ships.

## The three mockups

All three carry the same real content from the capture, follow the orders sheet system in docs/playbooks/screens.md, and keep DONE as the one action box. They differ on one real choice: how the comparison is laid out.

### FL1, The Muster Grid (chair's pick)

The current 4 by 3 grid, kept and rebuilt, no scroll. Each card: a ship picture strip, name and mark and class, a hull meter with its figures, the five stats as one icon and figure row (shields in glacier, the rest in bone), the ability as an icon and name with its rule on hover, one compact weapons line where the capture gives the weapons, the captain's name over the card's foot, and refit slots as squares that take a drag or a click. Damaged ships sort to the front, with the sort stated in joining words at the foot, and carry the word DAMAGED beside their hull figures. The doctrine is a strip above the grid: its name, its effect in one line, its cost as a figure, and Change as words with a key. The screen's rule line lives on hover over the FLEET headline.

Why this one: the decision is a comparison, and this is the only design that keeps all twelve ships fully comparable at a glance while still cutting every sentence off the cards. The council's sheet designs answer a different question (one ship, handled carefully) and the game already has places for that; this screen's scarcity is the side by side read.

### FL2, The Drydock Sheet

A list of the twelve ships at a fifth of the screen width, in fleet order, each row a name and a hull meter with figures. The selected ship fills the rest: a big picture, its full weapon sentences, its ability rule in words, its captain block with the XP meter, and its refit slots. Best of the three for one careful refit. Worst for the comparison, because eleven ships shrink to names and bars. DeepSeek and Flash both landed near this shape, and ChatGPT and Qwen both attached the same sheet to a grid; the sheet is the council's consensus piece of furniture, and the build can borrow it as the click state of FL1 without changing FL1's surface.

### FL3, The Ready Line

Readiness bands. READY with its count and six compressed cards, DAMAGED with its count and two wide cards that give the damaged ships the biggest hull figures on the screen, and a fold strip for the four ships below the capture's fold. The strongest story of the three and the weakest comparison: it invents a triage the game does not use, the bands move ships around as their state changes, and a ship's band tells the player less than its card did. Not the pick; it stays in the folder as the round's record.

## Where every removed sentence now lives (FL1; FL2 and FL3 follow the same homes)

- The five stat sentence on each card: the icon and figure row on the card; the full sentence on hover over that row.
- The ability rule sentence: hover over the ability name. The name and its icon stay on the card.
- Every weapon sentence: the compact weapons line on the card carries name and damage and range figures; the full sentence on hover, and in full on the ship sheet (FL2 shows the sheet form).
- The captain sentence (rank, 0 of 30 to Commander, no perks yet): the captain's name on the card; rank and the XP meter and the perks line on hover, and in full on the ship sheet.
- The REFITS heading and the empty slot lines: the slot squares on the card; the words Empty refit slot on hover over a square.
- The rule line under the title (refits move freely; mark upgrades and repairs at shipyards and drydocks): hover over the FLEET headline.
- The doctrine banner's full sentence: the strip carries the name, a one line effect, and the cost; the full sentence on hover over the strip, and the doctrine list opens in the ship sheet's place on a click, as ChatGPT proposed.
- DONE: unchanged, the one box, bottom right.

Nothing is deleted. Every line of the current screen is on the surface, on hover, or one click away in the sheet.

## Council record

Five external legs plus the blind Rey leg (legs/rey_blind.md). Legs ran Nov 15, 2026, on the cloud browser, each on its model gate.

- DeepSeek (DeepThink on, Search on, verified at both ends; chat https://chat.deepseek.com/a/chat/s/1ac5b10b-9ee5-4a08-b7e3-e882d10297d2): a twelve row roster with a one fifth side sheet for the selected ship, and the most complete relocation list of the round. Verdict: Keep names and hull figures.
- Qwen (Qwen3.8-Max, verified in the selector before and the header after; chat https://chat.qwen.ai/c/2ca34f81-f480-42b5-ba36-330b8042152e): a six by two grid of minimal cells with a hover layer and the same side sheet on click. Verdict: one card per ship.
- ChatGPT (chat, GPT-5.6 Sol at High, verified at both ends; its first council leg under Ryan's Nov 15, 2026 ruling; chat https://chatgpt.com/c/6af9d439-6dfc-83ea-b8ed-980d5aeb5671): a 4 by 3 berth field with the one fifth side sheet, DONE kept as exactly what DONE does today, and an explicit refusal to invent the four ships below the fold. Verdict: Keep the fleet decisions.
- Flash (Quick answers 3.5 Flash-Lite, verified at both ends; chat https://gemini.google.com/app/d143d526bc58a9a2): a two column list with a detail inspector. Verdict: Clear visual ship cards.
- Grok: empty seat, the 44th in a row. grok.com returned its bot wall on load and on one reload; the pack was never submitted. Recorded in legs/grok_leg.md; nothing in this round rests on it.

Where the council agreed: all twelve ships on one screen with no scroll (four of five legs and the blind leg); a selected ship sheet at about a fifth of the screen width (four legs); DONE stays the one box (ChatGPT and Qwen outright, the chair with them).

## Slips recorded, none adopted

- Qwen's headline figures invent data: 9 ready and 3 damaged, where the capture shows exactly two damaged ships, and a 24 CP budget the game does not have (CP is a per ship cost; the eight legible ships sum to 17). Its cells also drop hull figures entirely, against the headline numbers direction. The chair's mockups carry only figures the evidence supports.
- DeepSeek invents a READY and STANDBY toggle and a COMMIT FLEET action, and a REPAIR action on this screen, which contradicts the game's own rule line in the pack (repairs happen at shipyards and drydocks). ChatGPT offers a softer repair command on the same unsupported basis. Neither is adopted: on this screen, damaged is a state the player reads, not an action the screen sells.
- Flash's layout contradicts itself (a main view spanning the full width and a side sheet occupying the same band) and invents a credits count, a deployment tally, and repair buttons that appear nowhere in the evidence.
- DeepSeek and Qwen both rename the doctrine DAWN WATCH. The doctrine's name in the game is its sentence, Keep the dawn watch; the mockups keep it whole.
- ChatGPT's doctrine hover quote adds words the game does not have (Costs 40 credits per battle, for Costs 40 credits), and it states the name floor once as 14 px against the orders sheet's 17 px floor. Both verified against the pack and not adopted.

## Evidence limits the Board should know

- Four of the twelve ships sit below the capture's fold. Their names, classes, hull states, captains, and weapons are not in evidence. The mockups draw their cards with the same structure and class art and mark them as below the fold; the build fills them from game data. No leg invented them except where noted above, and the chair did not.
- Captains and full weapon lines are legible for the first four ships only (Wrath of Vesper, Vigilant Ash, Cold Fury, Oath Flame). The other four legible ships show their ability and stats on their FL1 cards, with weapons and captains in the hover and sheet homes the relocation list names.
- The Board's docs/shots/ui_audit_1115/ set had not landed when this round ran; it should confirm the fold ships before the Board schedules the build.

## Borrowings held for the build, whichever design Ryan picks

- The side sheet as FL1's click state (the council's consensus furniture), at a fifth of the screen, never more than a quarter.
- Qwen's refit move flow: click a filled slot, then click the target ship; the refit lands in its first empty slot.
- ChatGPT's ember discipline while a refit is held: ember shows on the refit being acted on and the slot it may enter, and nowhere else.
- ChatGPT's header counts, kept to the figures the game can state truthfully (ships, damaged), computed live at the build.
