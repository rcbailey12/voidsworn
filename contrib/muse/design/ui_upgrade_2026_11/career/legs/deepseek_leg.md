# DeepSeek leg, Career round (issue 794)

Run Nov 15, 2026, about 10:33 to 10:36 CST. DeepThink on, Search on, verified before sending and after the answer finished. Chat: https://chat.deepseek.com/a/chat/s/deefd8a2-22f2-4208-a46a-d920c95975d8
Pack: design_pack_career.txt. Answer below is verbatim.

---

1. THE SCREEN

Canvas: 1920 by 1080. Margins 64. Background is the live Career scene under a smooth vertical darkening. No filled panels, no pills, no glows, no shadows, square corners. All text meets 4.5 to 1 contrast and no text is under 17 px. The only ember orange is the single outlined action. Red is not used for ships lost. Glacier blue is not used.

Header, y 56 to 160

- Title: "CAREER" at x 64, y 56, display face, 44 px, capitals, full strength.
- Subtitle: current sentence at x 64, y 112, text face, 20 px, second strength, max width 1180.
- Close: outlined square box 176 by 48 at x 1680, y 56. One px ember orange outline. Label "Close" in text face 20 px full strength, key "Esc" after it in mono face 17 px second strength. No key cap. This is the only outlined box and the only ember orange on the screen.

Tab row, y 184 to 224

- Five text tabs at x 64: Records, Medals, Titles, History, Chronicle. Text face 20 px, 32 px gaps, no pills, no boxes.
- Active tab "Records" is full strength with a two px full strength underline. Inactive tabs are second strength. No accent is used on tabs.

Headline figure band, y 240 to 384

- Full content width x 64 to 1856, smooth darkening only, no boxes.
- Seven equal columns, 256 px wide. Figure numbers in mono face 52 px full strength. Labels in text face 17 px second strength, wrapping to at most two lines.
- Figures: 4 RUNS, 2 VICTORIES, 27 BATTLES, 135 ENEMY SHIPS DESTROYED, 9 FLAGSHIPS DESTROYED, 9 PRIZES TAKEN, 3 SHIPS LOST.
- "3 SHIPS LOST" stays in full strength figure and second strength label. No red.

Main roster and side sheet, y 416 to 1016

- Roster: x 64 to 1472, width 1408.
- Side sheet: x 1504 to 1856, width 352, about 18 percent of screen, under the quarter limit. Smooth darkening only, no outline and no box.
- Roster has three faction blocks stacked with 24 px gaps. Each faction block has a crest 28 px square and a faction name in display face 28 px capitals full strength.
- Service rows are 96 px tall. No service rows are 56 px tall. Each faction uses one 96 px row and one 56 px row for its first two rows, then continues with 56 px rows, so the known service admirals stay on the surface.
- Service admiral row: name in display face 28 px capitals full strength, up to two lines. Surface line two is "1 run, 0 won", "1 run, 1 won", or "1 run, 1 won" in text face 17 px second strength. Surface line three is "Title: the Surgeon (1)" or "Title: the Battery Master, Holder of the Anchorage (1)", or "Title: the Render (1)" in text face 17 px second strength.
- No service admiral row: name in display face 28 px capitals full strength, one line. Second line "No service yet" in text face 17 px second strength. Doctrine is not on the surface.
- Selected row gets a two px full strength left rule. No accent is used for selection.
- Ashfall rows: Grax Ironmaw and Sable are shown as above. The cut off Ashfall row carries only the known title fragment "the Collector" in text face 17 px second strength, with no invented name. A fourth Ashfall row is a reserved data row with no invented content.

Side sheet behavior

- Default side sheet is quiet: faction crest and "Select an admiral" in text face 17 px second strength.
- Selecting a service admiral shows faction crest, name in display face 28 px capitals full strength, full service sentence in text face 17 px second strength, then "Title: the Surgeon (1)", "Title: the Battery Master, Holder of the Anchorage (1)", or "Title: the Render (1)", then "Flagship: Wrath of Vesper", "Flagship: Valiant Dawn", or "Flagship: Grim Tooth".
- Selecting a no service admiral shows doctrine line and "No service yet". No titles or flagships.
- Selecting the unresolved Ashfall row shows only the known fragment "the Collector". No name is invented.
- There is no buy, equip, confirm or other action. The only action is Close.

Relocation list for current Records tab lines

- "Career." moves to the 44 px display title.
- Subtitle sentence moves to the 20 px header line, second strength.
- Close button moves to the single outlined Close action, top right.
- Five tabs move to the text tab row, active tab underlined, no pills.
- Seven figures move to the figure band, numbers in mono 52 px, labels in text 17 px, loss figure not red.
- Three faction headers move to roster faction headers with crests and display 28 px capitals.
- All known admiral names move to roster rows and side sheet: Vex, Draven, Ashgrove, Thale, Kassar, Vorn, Reyes, Maren, Grax, Sable.
- Vex, Kassar and Grax full service sentences move to their side sheets. Roster surface keeps run and won count.
- Vex, Kassar and Grax titles lines move to side sheets. Roster surface keeps title count.
- Vex, Kassar and Grax flagships lines move to side sheets.
- Draven, Ashgrove, Thale, Vorn, Reyes, Maren and Sable doctrine lines move to side sheets. Roster surface keeps only "No service yet".
- "the Collector" fragment moves to the unresolved Ashfall row title slot and its side sheet.
- The fourth Ashfall admiral is a reserved data row. No name or content is invented.

Other tabs, same system, no invented contents

- Medals: same header, tab row, roster and side sheet shape. Content is a headed list of medal entries from data. The side sheet carries full medal detail.
- Titles: same roster and side sheet shape, with title entries and counts from data. Selecting a title shows its admiral and run detail in the side sheet.
- History: same header, tab row and side sheet shape, with one line per run entry from data. The side sheet carries full run detail.
- Chronicle: same header and tab row. Content area is a reading column with the same side sheet for selected entries.

2. RISKS

Risk one: the roster reads as mostly empty.
Nine of twelve admirals have no service, so the screen can fail to show what the career has amounted to. The design answers with compact no service rows, a full headline figure band and service rows at 96 px. This keeps the three service records visible at the top of each faction and keeps the totals visible as the career record.

Risk two: the side sheet makes one admiral dominate and turns recognition into inspection.
A large inspector could hide the whole career behind one selection. The design answers with a narrow side sheet at 352 px, under the quarter limit, and no detail on the surface except run and won count and title count. This keeps recognition across admirals on the roster and makes selection a check, not a new screen.

Verdict: Keep per-admiral service records
