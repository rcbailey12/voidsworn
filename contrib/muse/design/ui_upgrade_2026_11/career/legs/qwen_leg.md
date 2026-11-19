# Qwen leg, Career round (issue 794)

Run Nov 15, 2026. First attempt 10:33 to 10:55 CST: the pack was attached as design_pack_career.txt, the upload showed "Parsing failed", a retry appeared to succeed, but Qwen replied it could see only the filename and asked for the pack text pasted directly. No answer was given in that run and nothing in this round rests on it. Chat: https://chat.qwen.ai/c/c70048f8-c701-4273-876e-d99ed611f08e

Resend 10:58 to 11:03 CST (runtime measured): new chat on the cloud browser, pack pasted into the message body, no attachment. Qwen3.8-Max gate verified at both ends: the new chat defaulted to Qwen3.7-Plus, the selector was switched to Qwen3.8-Max and verified before sending, and the chat header still showed Qwen3.8-Max after the answer finished. No CAPTCHA appeared on the resend. Single response, no A/B choice presented. Chat: https://chat.qwen.ai/c/8ba50f05-bf05-454c-b14f-b77c6f8ebdfa
Pack: design_pack_career.txt (pasted verbatim). Answer below is verbatim.

---

1. THE SCREEN

Overall shape
The screen borrows the Fleet screen's manifest-plus-inspector skeleton and bends it toward looking back rather than preparing. The left four-fifths carry a grouped list (the manifest of admirals). The right fifth is a side sheet that fills when you select an admiral. The difference from Fleet: there is nothing to configure, load or confirm in the sheet. It only shows what was earned. The tone is a service record read after the fact, not a pre-battle checklist.
The whole screen sits on a smooth darkening of the scene behind it. No filled panels anywhere. All corners are square. The single outlined box on the screen goes around the Close action, top right.

Region by region
Title strip, 1920 by 72 px, top edge.
Left: the word CAREER in the display face, capitals, 36 px, full strength. Beneath it, one line in the text face, 18 px, second strength: "Your service across every run: records per admiral, medals, titles, and the runs behind them." (Trimmed from the current subtitle; the list of tab names is redundant once the tabs are visible.) Right edge: the word Close in the text face, 18 px, second strength, followed by the key Esc in the mono face, 17 px, second strength, no key cap brackets. This pair sits inside the one outlined box, square corners, 1 px stroke.

Tab row, 1920 by 44 px, directly below the title strip.
Five text labels in the text face, 18 px, spaced 48 px apart, left-aligned under the title: Records, Medals, Titles, History, Chronicle. No pills, no boxes, no underlines by default. The active tab (Records on first open) is set in full strength and in ember orange. The four inactive tabs are second strength, neutral. Switching tabs swaps the content below; the row itself never changes shape.

Headline figure band, 1920 by 110 px, below the tab row.
Seven figures spaced evenly across the width. Each is a number in the mono face, 40 px, full strength, with a two-word label beneath it in the text face, 17 px, second strength, capitals. The seven, left to right:
4 RUNS. 2 VICTORIES. 27 BATTLES. 135 ENEMY SHIPS DESTROYED. 9 FLAGSHIPS DESTROYED. 9 PRIZES TAKEN. 3 SHIPS LOST.
No filled boxes behind them. No color coding. The loss figure is the same neutral tone as every other figure; the word LOST carries the meaning. Red stays reserved for the Nemesis.

Admiral manifest, 1536 by roughly 740 px, below the figure band, left side.
Three faction groups stacked vertically. Each group opens with a crest icon (32 by 32 px) and the faction name in the display face, capitals, 28 px, second strength. Under each header, four admiral entries in a single column, each entry two lines tall (about 56 px), separated by 12 px of space.
The three admirals with service (Vex, Kassar, Ironmaw) show:
Line one, display face, capitals, 28 px, full strength: the full name and epithet.
Line two, text face, 18 px, second strength: a short service summary. For Vex: "1 run, 0 won." For Kassar: "1 run, 1 won." For Ironmaw: "1 run, 1 won." That is all that appears on the surface. Best-sector detail, kill counts, titles and flagship names live in the side sheet.
The nine admirals without service show:
Line one, display face, capitals, 28 px, full strength: the name.
Line two, text face, 17 px, second strength: the role descriptor only ("Hunter-killer," "Carrier doctrine," "Precision fire," and so on). No "No service yet" sentence. The absence of a service line against the three who have one is the message. Nothing is deleted from the data; the "no service" state is simply expressed by showing nothing further.
All twelve entries are fully visible. The layout does not scroll at 1920 by 1080 on the Records tab. No entry is cut off. The Ashfall third and fourth admirals, whose names the capture could not confirm, occupy their two rows with whatever name and role descriptor the data holds; the layout does not depend on knowing them in advance.

Side sheet, 384 px wide (one fifth of 1920), right edge, full height below the tab row.
Empty (just the darkened scene) until an admiral is selected. When one is selected, the sheet fills top to bottom with that admiral's record:
Name in display face, capitals, 28 px, full strength.
For the three with service, below the name:
Run line: "1 run, 1 won" in text face, 18 px, full strength.
Best line: "Best: sector III, 9 battles, 45 kills, 1 ship lost" in text face, 18 px, second strength, with the numbers in mono.
Titles line: "Titles: the Battery Master (1)" in text face, 18 px, second strength.
Flagship line: "Flagships: Order Forty-One" in text face, 18 px, second strength. Ship name in capitals.
For the nine without service:
Name, then the role descriptor, then nothing else. The sheet is short and quiet.
The selected admiral's name in the manifest turns ember orange to mark what the sheet is acting on.

What selecting an admiral shows
Selecting any of the twelve admirals opens or updates the side sheet. For the three with service it shows the full best-run breakdown, earned titles with counts, and flagship names. For the nine without service it shows the name and role descriptor only. There is no button, no confirm, no equip. You read and you deselect.

Relocation list (every current line, where it goes)
Title "Career" - Title strip, display face 36 px
Subtitle sentence - Title strip, text face 18 px, second strength, trimmed
Close button top right - Same position, gains the one outlined box and a key hint
Five pill tabs - Tab row, plain text labels, no pills
Seven figures in filled boxes - Figure band, mono face, no boxes
Red on the loss figure - Removed; same neutral tone as all other figures
Faction crest and name headers - Group headers in the manifest, display face 28 px
Admiral cards in two columns - Single-column manifest entries
Service sentence ("1 run, 0 won. Best: sector I, 3 battles, 15 kills, 0 ships lost.") - Split: run count and wins stay on the manifest line; sector, battles, kills, ships lost move to the side sheet
"Titles: the Surgeon (1)" - Side sheet, second strength
"Flagships: Wrath of Vesper" - Side sheet, second strength
Role descriptors ("Hunter-killer," "Carrier doctrine," etc.) - Manifest line two, second strength
"No service yet" - Removed as text; expressed by the absence of a service line. State preserved in data.
Cut-off third Ashfall admiral - Full entry in the manifest; no cut-off permitted
Fourth Ashfall admiral below the fold - Full entry in the manifest; no fold needed

The other four tabs in the same system
Medals: the manifest area lists earned medals grouped under their faction or tier (contents unknown and not invented); selecting one fills the side sheet with its name, citation and the run that earned it.
Titles: the manifest lists earned titles with their count; the side sheet shows which admiral holds the title and in which run it was granted.
History: the manifest lists runs in reverse order, one line per run showing admiral, result and sector reached; the side sheet expands a selected run into its full battle sequence.
Chronicle: the manifest becomes a single scrolling column of dated entries in the text face; the side sheet is not used, and the full text of each entry reads in place at full width when selected.
All five tabs share the title strip, tab row, figure band and the rule set. Only the manifest content and the side sheet payload change.

2. RISKS

Risk one: the three who served drown in the nine who did not.
Twelve entries in a single column can flatten the hierarchy. If every admiral row looks the same height and weight, the player scans twelve names and the eye treats them as equals. Recognition fails because the earned records get no visual priority over the empty ones.
How the design answers it: information density does the sorting. The three served admirals carry a second line with concrete numbers ("1 run, 1 won"), while the nine carry only a short role tag. The contrast between a line that has figures and a line that does not pulls the eye to the figures without any color, glow or size change. The headline band above also front-loads the career's weight (27 battles, 135 kills) so the player registers substance before reaching the list.

Risk two: the side sheet makes recognition feel like homework.
If the titles, flagships and best-run detail are all locked behind individual clicks on three separate admirals, the player must perform three small tasks to feel the career's shape. Recognition becomes a chore rather than a moment, and the screen's job of letting the player see what things amounted to is delayed by interaction cost.
How the design answers it: the surface already carries enough for the top-level recognition. The seven headline figures give the career totals in one glance. The three service lines on the manifest confirm which admirals actually sailed and whether they won. The side sheet adds depth (which flagship, which title, which sector) but does not gate the core feeling of "I did this, and these three carried it." A player who never clicks an admiral still walks away with the full career shape. A player who wants the specifics clicks once and gets them in a focused 384 px column without losing their place in the list.

Verdict: the seven headline figures.
