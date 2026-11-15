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

## Ryan's response (Nov 15, 2026, about 10:04 CST)

Ryan: FL1 and FL2 are the closest, but FL1 is too busy and FL2 is a bit too much. He also raised the pictures: the concepts have evolved in the actual builds, so the mockups should find a way to use different art, worked on with Opus maybe, possibly live stylistic renders from the game, or an artistic version.

Chair's read of the direction: the hybrid these notes already flagged. FL1's grid, with the card cut down (the weapons line and the captain come off the card surface; both already live in the hover and the sheet), and FL2's sheet as the click state, itself trimmed, since the sheet is where the full sentences belong. No final pick recorded yet.

On the pictures: the mockup strips use concept art (the Sunward S8, S9 and S10 pieces and the squadron concepts) that predates the built hulls, and Ryan is right that they no longer match what the ships became. The layout does not depend on the choice: the picture slots are fixed shapes in all three designs. The art itself is Board work, since the builds and their renders sit with Opus (R205). The two routes Ryan named, for the Board to settle: capture stylistic renders from the game itself, or commission an artistic version of each built ship in the game's look. Either way the pictures should be drawn from the built hulls, not from the concept rounds.

## The hybrid: FL4, The Muster Sheet (built Nov 15, 2026, at Ryan's direction)

Ryan directed the hybrid be built now, with the same art. FL4 keeps FL1's grid and damaged first order, and cuts the card down to what the comparison needs: a taller picture strip, name and mark and class, the hull meter with figures, the five stat row, the ability as icon and name, and the refit slots. The weapons line and the captain are off the card surface; both live on hover and in the sheet, as the relocation list already provided. FL4S shows the second state: a ship clicked, Wrath of Vesper in the picture, with the trimmed sheet overlaid at the right edge at a fifth of the screen width. The sheet carries the full sentences (ability rule, every weapon line, captain with the XP meter, refit slots) so the cards never have to. Selection is a hairline on the card, not ember; DONE stays the one box and stays on top of the sheet.

FL4 and FL4S sit in this folder beside FL1 to FL3. If Ryan settles FL4, it supersedes the FL1 pick as the chair's recommendation of record for this screen; the art question stands as flagged above for the Board.

## The calm round: FL5, The Manifest (Nov 15, 2026)

Ryan's verdict on FL4: still a lot, cluttered, hard to read. He directed a look at similar screens in other games and at UI and UX best practice, with ChatGPT on the round. Two inputs came back.

The research (web pass over Sins of a Solar Empire, EVE Online, Stellaris, Endless Space 2, Homeworld, FTL and Battlestar Galactica Deadlock, plus the NN/g literature) found one pattern everywhere: at rest a unit is a picture plus at most two to four glanceable values; all detail is hover or selection; identical units collapse into stacks or counts; density is a user toggle. Sins runs its empire tree on icons alone and shows exactly three numbers on selection. Stellaris manages fleets as templates. The NN/g work adds the structure: two disclosure levels at most, chunk twelve into headed groups, icons always carry a visible label, and judge a redesign by how fast the damaged ship is found.

The ChatGPT leg (GPT-6 at High, its second council leg, filed at legs/leg_chatgpt_calm.md) proposed the Fleet Manifest: one line per ship, grouped DAMAGED and FULL HULL, a selected ship workspace in the middle, and a detail sheet at a fifth of the width. The chair adopts that shape with four corrections. The leg invented a SAIL and RESERVE deployment toggle, a fleet command point limit, and a credits total, none of which exist in the capture or the game data; all three are dropped. It also dropped ship pictures entirely, which conflicts with Ryan's own R260 pick of portraits and ship pictures, so each manifest row keeps a small picture strip for recognition. Its hull percentages check out (both damaged ships sit at 30 percent), and the exact figures stay on the damaged rows beside a slim bar, because the acceptance test is finding and judging the damage. DONE keeps the standard box size.

FL5, in this folder: the manifest at the left (picture strip, name, class in second strength, CP at the right; damaged ships first under their own heading with figures and a bar; the four fold ships as marked rows), the selected ship large in the middle with its refit slots and the free refit rule at the point of use, and the sheet at the right carrying the full specification for the one selected ship, ending with the shipyard line where it belongs. The doctrine keeps its name, cost and Change on the header line; its effect sentence moves to the doctrine chooser and to hover. Element budget at rest: four elements for a damaged ship, three for a whole one. Everything from the capture is relocated, nothing deleted; the relocation table is in the ChatGPT leg, as amended by the corrections above.

If Ryan settles FL5, it supersedes FL4 and FL1 as the recommendation of record for this screen.
