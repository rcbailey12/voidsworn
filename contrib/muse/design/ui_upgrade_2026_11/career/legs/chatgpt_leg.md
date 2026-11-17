# ChatGPT leg, Career round (issue 794)

Run Nov 15, 2026, about 10:33 to 10:41 CST. ChatGPT chat (not Work), GPT-6 at High thinking, picker verified before sending and after the answer finished. Chat: https://chatgpt.com/c/6af9df24-fba0-83ea-a491-732d344dfbcf
Pack: design_pack_career.txt. Answer below is verbatim.

---

1. THE SCREEN

Design: A service roll with a record inspector.

Keep the Fleet screen's manifest and inspector logic, but change the emphasis. Fleet is about choosing and preparing ships. Career is about seeing what has been accomplished. The lifetime figures and earned identities must be visible without selection. The inspector holds the full history of one admiral.

Use three faction columns, four admirals per column, and a narrow inspector on the right. All twelve admirals fit at 1920 by 1080 without scrolling. The three who have served are visually prominent. The nine who have not remain visible but quieter.

Layout at 1920 by 1080

1. Header, y 40 to 128

- Left: CAREER in the display face, 52 px, full strength.
- Right: Close, with Esc following it in the mono face at second strength. This is the screen's one outlined rectangle, 140 by 52 px.
- Remove the permanent explanatory sentence. Keep its complete wording available by hovering over Career.
- Background is the scene under a smooth darkening, with no header panel.

2. Lifetime figure band, y 145 to 276

Seven evenly spaced columns across the 1792 px content width. Figures use the mono face at 56 px, with labels in the text face at 18 px. No boxes.

Figure Label
4 RUNS
2 VICTORIES
27 BATTLES
135 ENEMY SHIPS DESTROYED
9 FLAGSHIPS DESTROYED
9 PRIZES TAKEN
3 SHIPS LOST

Make Victories and Runs the first two figures because they define the career's overall result. The other five stay in the recorded order. All figures stay on one baseline, and the layout must survive a two-digit value such as 27 without pushing a label to a second line.

Use neutral text for Ships Lost, not red. Losses are part of the record, not a Nemesis warning. Separate the figure band from the tab row with a faint horizontal rule.

3. Tab row, y 298 to 354

Records, Medals, Titles, History, Chronicle.

Use the text face at 21 px. The active tab is full strength with a thin neutral underline. The other four are at second strength. Do not use a filled pill for the active tab. There is no gap between the tab text and the vertical start of the admiral roll at y 395.

There is no ember orange here. The screen has no required next action, and orange must not become a general accent.

4. Admiral roll, y 395 to 1015

The left 1410 px contains three faction columns, each roughly 450 px wide, separated by 30 px gaps. All twelve admirals are visible without scrolling. The roll is a record of service, not a set of portraits.

Each column starts with its faction crest and name in the display face at 30 px. Below it are four stacked entries, each about 130 px tall, with about 20 px of space between them. Each entry has a name at 28 px and one or two lines of supporting text at 17 px. At this scale, a row reads like a line in a manifest, not a character card.

The three served admirals receive full-strength names and an earned title directly beneath them. The served entries retain their full name, earned title, runs, wins and best sector in the roll.

The nine unserved admirals receive second-strength names, their known doctrine description where available, and No service yet. An unserved admiral must not look like an empty slot. Keep the name and known doctrine visible; do not reduce the entry to a placeholder.

The visible structure is:

SUNWARD CRUSADE
RODERIC VEX
the Surgeon
1 run · 0 won · Sector I
MALEK DRAVEN
Hunter-killer
No service yet
SERA ASHGROVE
Carrier doctrine
No service yet
ORYN THALE
Iron doctrine
No service yet

HEGEMONY NAVY
ILSA KASSAR
the Battery Master
1 run · 1 won · Sector III
DACE VORN
Precision fire
No service yet
CORIN REYES
Strike group
No service yet
OSKAR MAREN
Armored column
No service yet

ASHFALL HULLBREAKERS
GRAX IRONMAW
the Render
1 run · 1 won · Sector III
SABLE
Knife work
No service yet
ADMIRAL 3
Actual name from game data
No service yet
ADMIRAL 4
Actual name from game data
No service yet

Structural illustration only. Production names use the display face at 28 to 30 px. Ashfall slots 3 and 4 are reserved entries, populated from game data.

This is a roll of service, not a collection of character cards. No row gets a filled background. Use a faint horizontal rule between entries. Do not add portraits, frames or extra action buttons to the roll.

Keep ranks in the inspector rather than repeating them in the roll. A rank must not crowd out the name and service line.

For the third Ashfall admiral, the evidence only includes the fragment "the Collector". The production roll must not display that fragment as if it were the admiral's full name. It must use the actual name from game data, and reserve the entry if that name is not available.

5. Record inspector, x 1520 to 1856, y 395 to 1015

Width 336 px, or 17.5% of the screen. Separate it from the roll with a faint vertical rule. No enclosed panel, no buttons and no large image area.

When an admiral is selected, show:

- Full rank, name, earned epithet and any other known name elements.
- Runs and victories.
- Best sector, battles, kills and ships lost.
- Titles with their recorded counts.
- Flagship name.
- For an unserved admiral, their known doctrine description and "No service yet", without manufacturing a service history.

The selected name uses the display face at 32 px. The rest uses the text face at 18 to 20 px and mono for figures. The inspector keeps every selected admiral's supported details in one place.

Do not assume portraits exist. Use the existing faction crest as the common visual identity. Roderic Vex's appearance must not be assumed from his title.

Initially, the sheet can say "Select an admiral to view their service record." It does not need to select an admiral by default.

Relocation list: every current Records element

Current element | New location
Career title | Header, left
Full explanatory subtitle | Career heading hover explanation
Close button | Header, right, sole outlined action
Records, Medals, Titles, History, Chronicle pills | Plain text tab row
4 Runs | Lifetime figure band
2 Victories | Lifetime figure band
27 Battles | Lifetime figure band
135 Enemy Ships Destroyed | Lifetime figure band
9 Flagships Destroyed | Lifetime figure band
9 Prizes Taken | Lifetime figure band
3 Ships Lost, red | Lifetime figure band, neutral
Three faction crests and names | Heads of the three roll columns

Sunward Crusade

- Admiral Roderic Vex the Surgeon: RODERIC VEX and "the Surgeon" remain visible in the roll, alongside 1 run, 0 won, and Sector I. The inspector adds his full rank, Oath-Captain.
- Oath-Captain Malek Draven: Name, Hunter-killer and No service yet in the roll. Full rank and doctrine remain available in the inspector.
- Commodore Sera Ashgrove: Name, Carrier doctrine and No service yet in the roll. Full rank and doctrine in the inspector.
- High Admiral Oryn Thale: Name, Iron doctrine and No service yet in the roll. Full rank and doctrine in the inspector.

Hegemony Navy

- First Admiral Ilsa Kassar the Battery Master, Holder of the Anchorage: ILSA KASSAR, "the Battery Master", 1 run, 1 won, and Sector III remain visible in the roll. The inspector preserves her full name, "Holder of the Anchorage", and her recorded flagship, Invictus.
- Commodore Dace Vorn: Name, Precision fire and No service yet in the roll. Full rank and doctrine in the inspector.
- Fleet Marshal Corin Reyes: Name, Strike group and No service yet in the roll. Full rank and doctrine in the inspector.
- Line Admiral Oskar Maren: Name, Armored column and No service yet in the roll. Full rank and doctrine in the inspector.

Ashfall Hullbreakers

- Warlord Grax Ironmaw the Render: GRAX IRONMAW, "the Render", 1 run, 1 won, and Sector III remain visible in the roll. The inspector preserves his full name, "the Render", and his recorded flagship, Ashfall.
- Sable the Smiling Knife: SABLE, Knife work and No service yet in the roll. The inspector preserves the full name "Sable the Smiling Knife".
- Third admiral: The roll reserves a full entry populated from actual game data. The visible fragment "the Collector" is not treated as a complete name.
- Fourth admiral: The roll reserves a full entry populated from actual game data. The captured record supplies no identifying name for this slot.

All twelve entries remain present. None of the supported text is deleted. Only its initial visibility changes: earned titles stay in the roll, while ranks, flags and fuller name elements move into the inspector.

Other four tabs

Medals: Retain the same header, figure band and tab row. Replace the admiral roll with a medal-focused listing. Use the same inspector width, vertical rule and typography, with the inspector holding the details of one medal.

Titles: Use the same structure to present the actual recorded titles and counts, with the inspector giving the details of one title.

History: Use a run-focused manifest and the same narrow inspector for whatever run details the game actually records.

Chronicle: Use the same darkened scene and typography, with chronicle text as the main reading area and a side panel for entries and excerpts.

All four tabs retain Close in the same position. The figure band stays as the persistent career summary.

System rules

Every surface follows the same rules: no filled panels, no pills, no glow or shadow, square corners, no ember orange, no large pictures and no decorative bars. The screen should read as a service record, not a dashboard.

All visible text is at least 17 px with a minimum contrast of 4.5 to 1. No cut-off sentences. At this scale, nothing overflows its column.

The design deliberately does not copy Fleet's large picture workspace. Career has nothing to manipulate. Its job is to make lifetime totals and earned identities visible at a glance, with the inspector available for full detail.

2. RISKS

Risk 1: The manifest becomes too tidy and stops celebrating accomplishments.

A clean list can make a victorious admiral look nearly identical to one who has never been played. If the roll hides earned titles, the only visible difference becomes the count line. The accomplishment then becomes quieter than the career the screen is meant to celebrate.

The answer is to keep earned titles visible on the roll itself, alongside runs, wins and best sector. They are what distinguishes an admiral who has won from one who has not yet served. Names, titles and service counts must remain legible at a glance. The inspector should add depth, not carry the celebration.

A player should be able to glance at the screen and recognize Roderic's title, Ilsa's victory and Grax's victory, without selecting anyone.

Risk 2: The record cannot be trusted because the totals do not clearly reconcile.

The captured lifetime total is four runs, but the three served admiral records shown account for only three runs. The remaining run must be explained by the actual game data, or flagged as a discrepancy. The totals and the individual records must reconcile, or the reason for the difference must be visible.

The redesign must keep lifetime totals and individual records distinct. It must preserve the reported lifetime figures and preserve each served admiral's reported run total. A player should not have to add admiral rows to check whether the career total is correct.

The interface should make this comparison easy because the aggregate figures and the served admiral records are presented on the same screen.

Verdict: Faction crests, lifetime figures, records.
