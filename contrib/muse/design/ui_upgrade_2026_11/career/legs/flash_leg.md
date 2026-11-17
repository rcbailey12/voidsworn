# Flash leg, Career round (issue 794)

Run Nov 15, 2026, about 10:33 to 10:35 CST. Gemini, "Quick answers 3.5 Flash-Lite", picker verified before sending and after the answer finished. Chat: https://gemini.google.com/app/fe86a8c1ecc44a6c
Pack: design_pack_career.txt. Answer below is verbatim.

---

1. THE SCREEN

The redesign adapts the manifest plus inspector shape used on the Fleet screen to fit a recognition screen. At 1920 by 1080, the screen uses a smooth dark background with square corners and no filled panels, pills, glows, or shadows. One outlined box marks the close action at the top right.

Layout Regions

Top Bar (Y 0 to 120, Full Width):

Headline and Subtitle: Display face in capitals for the title Career at 32 px, second strength. Text face for the subtitle at 18 px, third strength.

Close Action: Outlined box in the top right corner containing the close key.

Tab Row: Five text links for Records, Medals, Titles, History, and Chronicle. The active tab uses ember orange for its text, while inactive tabs use second strength.

Headline Figure Band (Y 140 to 220, Full Width):

A single horizontal strip displaying lifetime totals: 4 Runs, 2 Victories, 27 Battles, 135 Enemy Ships Destroyed, 9 Flagships Destroyed, 9 Prizes Taken, and 3 Ships Lost.

Figures use the mono face in second strength, with keys placed after the words. The loss figure drops the red violation and matches the neutral mono face.

Main Content Area (Y 240 to 1080):

Left Manifest (X 0 to 1400): Displays the three factions (Sunward Crusade, Hegemony Navy, Ashfall Hullbreakers) headed by a crest and the faction name. Under each faction are four admiral rows in a single column manifest.

Right Inspector Sheet (X 1400 to 1920): Takes up roughly one quarter of the screen width (520 pixels) to display full details for the selected admiral.

Admiral Manifest and Handling

Each faction lists all four admirals in clean text rows rather than filled cards:

Admirals with Service (Roderic Vex, Ilsa Kassar, Grax Ironmaw): Listed with their name in display capitals, doctrine, and summary stats.

Admirals without Service (Nine unplayed admirals, including the fourth Ashfall admiral and the cut-off name resolved to standard bounds): Listed in third strength text reading "No service yet" next to their name and doctrine, keeping them visible without crowding the view.

Relocation List

Title and Subtitle: Moved to the top bar.

Lifetime Figures: Moved to the headline figure band beneath the top bar.

Faction Groupings and Admiral Lines: Moved to the left manifest region.

Individual Admiral Stats, Titles, and Flagships: Moved into the right inspector sheet when an admiral is selected.

Loss Figure: Moved into the headline figure band, rendered in neutral mono face instead of red.

Admiral Selection

Selecting an admiral in the manifest populates the right inspector sheet with their full service record, specific titles earned with counts, and designated flagships. If a painted portrait exists in the game files (such as for Roderic Vex), it appears at the top of the inspector; otherwise, the space remains clean text and crests.

Other Tabs

Each of the other four tabs (Medals, Titles, History, and Chronicle) follows the same manifest plus inspector shape, replacing the admiral list with medals, title categories, run entries, or chronicle logs while maintaining identical typography and layout rules.

2. RISKS

Risk One: The manifest layout might make unplayed admirals feel invisible or neglected due to their lack of service data. Answer: The design lists all twelve admirals clearly within their factions, using third strength text for unplayed entries so the player can still scan the complete roster of the service record.

Risk Two: Moving detailed stats into a side inspector might hide recognition information behind too many clicks. Answer: The left manifest displays core doctrines and basic status at a glance, ensuring recognition is immediate while keeping deeper stats one click away in a consistent inspector sheet.

Verdict: Clean manifest plus inspector layout.
