# Leg: Grok (Fast mode, verified before and after; run Nov 17, 2026)

Concept name: LEDGER SPLIT (improved)

This is the seeded concept (a), tightened. Top bar takes the turn/objective status and absorbs the existing top-right cluster so the left edge is fully cleared. Bottom bar becomes a single continuous action deck that keeps the decision order readable left-to-right then down. The board middle and most of the left flank stay open. No new panels, no solid slabs, only edge veils and the single FIRE box.

1. Placement table
Item	Placement
1. Turn header ("Round 1", "Your turn", "3 of 3 ships to act")	Top bar, left third
2. Objective	Top bar, immediately under or beside turn header
3. Ship name	Bottom bar, far left, large display type
4. Ship class	Bottom bar, under ship name
5. Hull + Move	Bottom bar, under class
6. Shields (four-facing cross)	Bottom bar, right of hull block
7. Status line	Bottom bar, under shields or as a short secondary line under the ship block
8. Guns table	Bottom bar, centre-left, vertical stack of rows
9. Target	Bottom bar, centre, under or beside guns
10. Odds + damage split	Bottom bar, under target
11. FIRE box	Bottom bar, centre-right, the single ember-outlined box
12. Orders row	Bottom bar, right of FIRE, single horizontal row
13. Command row	Bottom bar, under orders
14. Fleet strip	Bottom bar, full-width footer under everything else (horizontal portraits / name+hull, acting ship marked with ember bar)
Occasional: tree prompt card	Overlay, centred or slightly above the bottom bar; same card treatment as today
Occasional: Retreat	Bottom bar, far right of the Command row (or one key away as today)
Occasional: phase banner	Top bar, replaces or sits over the turn header for the duration of the phase
Top-right cluster (Menu, enemy line, Heat, Nemesis panel)	Top bar, right third (unchanged position relative to screen)
Bottom-right log	Stays exactly where it is

Secondary detail stays one hover or one key away (SAY LESS rule unchanged).

2. Geometry at 1920 x 1080 design size
Top bar: height 72 px, full width, top margin 24 px. Veil fades downward from the top edge to roughly 90-100 px. Contains turn/objective on the left and the existing top-right cluster on the right.
Bottom bar: height 220 px, full width, bottom margin 24 px. Veil fades upward from the bottom edge to roughly 240-260 px. Internal layout left-to-right: ship block (name/class/hull/move/shields) ~320 px, guns table ~280 px, target+odds ~260 px, FIRE box ~200 px, orders+Command ~280 px, with the fleet strip as a 48 px high footer across the whole bar.
Cleared zone: the entire left flank of the board is now free. No full-height rail, no 380 px text column, no unbroken 30% veil band.
Screen share: top veil + bottom veil together cover roughly 18-20% of the screen area (plus the unchanged ~3% corner elements). Net reduction of about 10-12 percentage points versus today's ~33%. The middle and most of the left and right of the board form one continuous clear field.

3. Decision order across the split
Eye starts at the top bar for context (round, turn, objective). Then drops to the bottom-left ship block and travels rightward: ship, hull/move, shields, guns, target, odds, FIRE, orders, Command. The fleet strip sits under that line as the final "who is left" check. The sequence remains linear; the player does not hunt vertically on a tall rail.

4. Scale at 1440p and 4K
Under the existing scale law (k = clamp(height/1080, 0.6, 2.2) x player UI scale): at 1440p (k about 1.33) and 4K (k = 2.0) the bar heights and all text sizes scale proportionally. Screen-share percentages stay identical. Headroom improves: the shield cross and guns table gain pixels, so the 17 px floor is less binding. On short or low-DPI windows near the 0.6 floor the bottom bar remains usable because its internal stacking is shallower than the old full-height rail.

5. What gets worse
Vertical space for the guns table is tighter; long weapon lists will need the existing hover/key secondary detail more often.
The bottom bar is denser than the old single-column rail, so first-time players may take a moment to learn the left-to-right flow.
Full-width bottom veil covers a thin strip of the lower board that was previously clear (trade-off for removing the tall left veil).
Phase banners and tree prompts must be careful not to collide with the top bar; they become short-lived overlays rather than rail residents.
None of these break the decision order, the colour rules, the font floors, or the "one box only" rule.

6. Tree prompt, Retreat, phase banner
Tree prompt: appears as a floating card (same visual language as today) centred or slightly elevated above the bottom bar so it does not fight the action deck. Dismisses cleanly.
Retreat: sits at the far right of the Command row inside the bottom bar (or remains one key away if space is tight).
Phase banner: temporarily replaces the turn header content inside the top bar (or overlays it). Same duration and weight as today's enemy-turn banner.

This layout keeps the original visual language, clears the left board, reduces total veiled area, and preserves a readable decision path. It is a pure layout move inside the existing HUD code.
