# After-run screen: three mockups (issue 794, R260)

The current screen (docs/shots/debrief_92/ on PR 789) scrolls through two viewports of prose. These three flat layouts at 1920 by 1080 carry the same real content from the win capture (Sunward Crusade, Admiral Roderic Vex) under the orders sheet (docs/playbooks/screens.md section 2): one ember accent on the action box only, three text strengths, three faces, no panels, nothing under 17 px at 1080, a headline plus three to five key items, and every sentence from the current screen either on the mockup or named below with where it now lives. Nothing is deleted from the game.

One asset fact shaped all three: the heir candidates hold crests, not paintings. Admiral Vex has a painted portrait (godot/portraits/painted/vex.webp); Malek Draven, Sera Ashgrove and Oryn Thale are, in the game's own words on its portrait sheet, "admirals without a painting", and are shown by their crests (godot/portraits/crests/). The mockups use the real art the game has today. Commissioning three paintings is a Board call, not something these designs assume.

## DB1, The Ledger Page (chair's pick)

The battle sheet's pattern grown up: consolidation first, one screen, no scroll.
Headline and verdict line top left. The five recap figures as a big number band under it (6 battles won, 1 flagships destroyed, 24 enemy ships destroyed, 2 ships lost, 47m played). The run timeline full width under the band: three sector nodes, six battle ticks, the flagship kill ringed, the two losses as red crosses (NEM red is the loss mark; ember stays on the action only). Left column: WHAT IT BOUGHT, renown as two big figures (42 earned, 76 in the vault) over a vault meter with the Command authority I threshold ticked at 35 (now affordable) and the next at 87; Spend renown and View hull rewards as words with keys; the admiral's portrait, name, level and XP meter under that. Right column: HEIR TO THE LINE, the three crest cards in a row, each with name, rank, shadow meter and figure, the current heir's card hairlined; the one box under them reads CONFIRM HEIR, and becomes PLAY AS ASHFALL HULLBREAKERS once the heir is confirmed. Foot strip: the standout ship's picture with its name, class, captain and figures; captains lost; the three overlay keys (Core sync S, Nemesis lesson L, The record R); NEXT RUN with the faction name and the two exit words.

## DB2, The Portrait Hall

People first: the screen is about the line, so the line is the layout.
Left column: Vex's painted portrait large, his name, level, XP meter, then the renown figures and vault meter. Centre column: the three heirs as stacked crest rows (crest, name, rank, shadow meter, figure; the current heir's row hairlined) with the CONFIRM HEIR box under them. Right column: THE RUN as a two by two figure grid plus time, then the standout ship's picture large with its figures, captains lost, and the overlay keys. Foot: a compressed timeline strip (three sector nodes, the flagship ring) and the next run line. DB2 gives the admiral and the standout the biggest art of the three; its timeline is the weakest of the three, a strip rather than a story.

## DB3, The Voyage Chart

The run first: the timeline is the hero.
A full width chart under the headline: three sector spans divided by hairlines, six battle nodes, the line broken at the two losses with red crosses under, the flagship kill as the largest ringed node, and the Nemesis lesson pinned at that node (SEVENTH MAW BROKEN, WEAKNESS: POOR POINT DEFENSE), because that is where it happened. Under the chart, three columns: THE NUMBERS (the five figures stacked, victories so far folded into the last label), THE LINE (the admiral's meter, then the three heirs as compact crest rows, then the CONFIRM HEIR box), THE SPOILS (renown figures and vault meter, core sync as two icon and meter rows on screen, the standout's picture and figures). Foot: the next run line left, the overlay keys and exit words right. DB3 carries the most on one screen; its density is the risk, held by the 17 px floor and the three strengths.

## The chair's pick: DB1

DB1, for three reasons. It is the closest to the pattern the game already proved on the battle screen, so it is the cheapest honest build and the easiest to check with the readability test. It puts the screen's one permanent decision and the one box in a single eyeline on the right, with the numbers and the timeline, the two visuals that tell the run's story fastest, above everything. And it leaves the scene the most air of the three. Two borrowings are recommended whichever design Ryan picks: DeepSeek's scene side placement (the admiral's portrait and the standout render set large on the scene beside a narrower sheet) if he wants the art bigger than DB1 allows, and Qwen's two rules, which all three mockups already follow: the heir is gated first because it is the only irreversible choice on the screen, and in the loss state no slot is ever empty, each is filled with the true state, even zero (on a loss the standout slot becomes most damage taken or last ship standing, per Qwen).

## Where every sentence now lives (all three mockups, differences noted)

- Headline THE CRUSADE ENDURES and the verdict sentence: on screen, all three.
- The green arc line ("The arc line travels with the fleet..."): hover on the headline.
- "What this victory bought:" and the WHAT THIS RUN BOUGHT label: the renown block itself; the sentence is on the renown figures' hover.
- Renown breakdown (12 from battles, 4 from elites, 15 from flagships, 6 from kills, 5 for sectors reached): hover on the 42 earned figure.
- "and 11 more within reach": drawn on DB1 as the NEXT 87 tick on the vault meter; on DB2 and DB3, hover on the vault meter.
- Spend renown, View hull rewards: DB1 and DB2 on screen as words with keys; DB3 in the vault meter's hover.
- Admiral Vex +21 XP, Level 3, 31 of 50 XP, 19 to level 4: on screen in all three (name, level, meter, figures).
- View admiral line: hover on the admiral's portrait.
- The three officers' shadow gains this run (+10.5, +5.25, +5.25, with their levels): hover on each heir's crest. The figures on screen are their standing shadow XP (18.5, 10.25, 7.25), the numbers the heir choice actually turns on.
- Core sync, all four sentences: DB3 on screen as two meter rows (12 of 25 and 14 of 25 to Full), the two "crossed into Synced" sentences on each row's hover. DB1 and DB2: the Core sync overlay behind the S key, with the same rows.
- Nemesis lesson, both sentences: DB3 on the chart at the flagship node (the weakness), with "No weakness was taught this run" in the L overlay. DB1 and DB2: the Nemesis lesson overlay behind the L key.
- THE RECORD sentence: the Record overlay behind the R key, all three.
- The heir block (current heir, the naming question, the three candidate sentences, Keep current heir, Confirm heir): on screen in all three as the crest cards or rows and the one box. Keeping the current heir is the pre-selected state: Draven's card carries CURRENT HEIR, and confirming without changing the selection keeps him.
- The five recap figures: on screen in all three (band, grid, column).
- The standout sentence: on screen as name, class, captain and figures; the exact sentence on the ship name's hover.
- The fleet that finished it (the full roster): hover on the standout ship's picture opens the fleet list.
- Captains lost this run (Captain Ilse Marrow): on screen in DB1 and DB2; in DB3, hover on the 2 SHIPS LOST figure and in the L overlay.
- Victories so far: 2. DB3 on screen in the numbers column; DB1 and DB2 on the headline's hover.
- Won with: Sunward Crusade: the headline's context in all three; spelled out on the headline's hover in DB1 and DB2.
- NEXT RUN and the full Ashfall Hullbreakers description: the faction name is on screen in all three; the description paragraph is on the faction name's hover.
- Play as Ashfall Hullbreakers: the one box, after the heir is confirmed, all three.
- Pick a faction, Title screen: on screen as words, all three. Both stay inert until the heir is confirmed, so the run cannot be left with the heir unnamed (DeepSeek's and Qwen's shared point).

## Council record

Blind legs in the legs folder. DeepSeek (DeepThink and Search on, verified both ends) ranked the screens exactly as the chair did and designed a 760 px left sheet with the art placed on the scene; its relocation list is the most complete of the legs. Qwen (Qwen3.8-Max, verified both ends) agreed on the ranking and contributed the gating argument and the loss state rule adopted above. Flash (Flash-Lite, verified both ends) ranked Fleet and refits first and the after-run screen second; the chair did not adopt the swap, because R260 fixes the working order, and recorded the disagreement in audit.md; its second place verdict still named Fleet, so the queue after this screen is unanimous. Grok's seat was empty (bot wall, 43rd consecutive); nothing rests on it.

Leg slips the chair verified and did not adopt: Flash's ember warning indicator on a dimmed box (a second ember, against the one accent rule) and its lumping of unlike sentences into one relocation line; DeepSeek's double assignment of the H key (Change heir and View hull rewards) and a renown meter scaled to the 35 threshold, which reads full at a vault of 76; Qwen's ember filled XP meter (again a second ember, and 2 px tall), and a bottom strip called a timeline that carries the recap figures rather than the run's sequence. The heir portraits all three legs assumed do not exist; the game holds crests for these three officers, and the mockups use them.

## Build notes for whichever mockup is picked

All art already exists in the game (painted admiral portraits, crests, ship renders, the nemesis portrait pool); the new work is layout, the hover and key wiring, timeline and meter drawing, and a small icon set. States to cover: win, loss, first ever loss (the debrief_92 set has all three), an abandoned run, and a run with no standout ship. The readability test pattern from the battle screen (godot/ui/battle/test/ledger_readability_test.gd) applies unchanged: 17 px floor, three strengths, 4.5 to 1 over the brightest and darkest board, no overlaps at any name length.

## Owner pick (Ryan, Nov 15, 2026)

Ryan picked DB1, The Ledger Page. DB2 and DB3 were not picked; they stay in this folder as the record of the round. The build brief for the after-run screen starts from DB1 as drawn. The DeepSeek scene side variant (the admiral's portrait and the standout render set large on the scene beside a narrower sheet) stays an open build option for the Board to take or leave at build time; it does not change the pick. Per R260, the screens.md visuals line lands with this pick; that edit is the Board's step on docs/playbooks/screens.md. The pick unlocks stage 3 of issue 794: Fleet and refits, then the Career screen, get the same treatment (mockups first, owner pick, then build).
