# Leg: Flash (Gemini, "Quick answers 3.5 Flash-Lite" selected and verified before and after; run Nov 17, 2026, signed in)

Concept Proposal: HORIZON DECK (An Evolution of Command Deck)

After evaluating the seeded options against the Voidsworn layout constraints, I propose HORIZON DECK. This concept adapts the bottom-centre floating island approach of Command Deck but anchors it cleanly to the bottom edge as an integrated, low-profile command strip.

Splitting the interface horizontally frees up the left flank entirely, opening up the tactical board where most combat positioning takes place, while keeping all core decision-making elements within a natural left-to-right scanning path along the lower screen.

1. Placement Table: Where Every Item Goes

| Item | Today's Location | Horizon Deck Location |
| 1. Turn Header | Top of left rail | Top-left slim pill (alongside objective) |
| 2. Objective | Top of left rail | Top-left slim pill (beside turn header) |
| 3. Ship Name | Upper-middle left rail | Bottom-left zone (primary display) |
| 4. Ship Class | Upper-middle left rail | Bottom-left zone (directly under ship name) |
| 5. Hull and Move | Upper-middle left rail | Bottom-left zone (alongside shields) |
| 6. Shields Cross | Middle left rail | Bottom-left zone (Glacier blue cross, compact) |
| 7. Status Line | Middle left rail | Hover / Tooltip on ship status or secondary read-out |
| 8. Guns Table | Lower-middle left rail | Bottom-centre strip (collapsible secondary view or tabbed card) |
| 9. Target | Lower-middle left rail | Bottom-centre strip (adjacent to guns table) |
| 10. Odds and Damage | Lower-middle left rail | Bottom-centre strip (paired directly with target) |
| 11. The FIRE Box | Lower-middle left rail (Ember box) | Bottom-right anchor of the central strip (prominent Ember outline, key Enter) |
| 12. Orders Row | Lower rail | Bottom-centre strip (secondary action buttons) |
| 13. Command Row | Lower rail | Bottom-centre strip (Command, Fire for effect, End ship) |
| 14. Fleet Strip | Foot of left rail | Bottom-extreme-left anchor (horizontal portrait and hull row) |
| Occasional: Tree Prompt | Center or rail overlay | Modal overlay card anchored just above the bottom strip, centred |
| Occasional: Retreat | Rail or menu | Bottom-right utility cluster (beside the log) |
| Occasional: Phase Banner | Top/Center | Top-centre slim banner (fades in during enemy turn or phase changes) |
| Static: Top-Right (Menu, Enemy, Heat, Nemesis) | Top right | Remains top right (unchanged from today) |
| Static: Log | Bottom right | Remains bottom right (unchanged from today) |

2. Geometry and Screen Share (at 1920 by 1080)

Bottom Strip: Runs horizontally from x = 240 to x = 1680 (width 1440 px, height 130 px), anchored at the bottom edge (y = 920 to y = 1050).
Top-Left Pill: A slim info pill at x = 40, y = 40 (width 320 px, height 50 px) containing Turn and Objective.
Fleet Strip Anchor: Docked horizontally at the bottom-left corner (x = 40, y = 970, width 180 px, height 80 px).

Veil Coverage: Instead of a massive vertical 30% width bar covering the entire left side of the board, Horizon Deck uses a low-opacity, horizontal veil just behind the bottom strip and a small veil behind the top-left pill. The rest of the board is fully unobstructed.

Screen Share Comparison:
Today: ~30% screen area dimmed on the left + 3% corners = ~33% total coverage.
Horizon Deck: Top-left pill (~1.5%) + bottom strip (~12%) + bottom-left fleet strip (~1.5%) + corners (~3%) = ~18% total coverage.
Gain: Almost 15% more visible board area on the left flank, completely freeing up the primary tactical area.

3. Decision Order Across the Split

The reading flow is redesigned to follow a natural left-to-right Western reading pattern along the bottom:
Context (Top-Left): Glance up-left to confirm Turn and Objective before engaging.
Identity and State (Bottom-Left): Read ship name, class, hull, move, and shields cross.
Capability (Bottom-Centre): Scan weapons table, current target, and hit odds.
Action (Bottom-Right of Strip): Strike the prominent FIRE box (or press Enter), backed by Orders and Command shortcuts.
Fleet Context (Bottom-Left Edge): Companion fleet ships sit horizontally adjacent to the active ship, keeping fleet health visible without vertical scrolling.

4. Behavior Under the Scale Law (1440p and 4K)

At 1440p (k = 1.33): The bottom strip scales proportionally to height (~173 px tall), maintaining identical relative screen coverage. Text sizes increase proportionally, keeping the 17 px text floor well clear and preserving legibility.
At 4K (k = 2.0): The bottom strip scales to ~260 px tall. Pixel density allows the four-facing Glacier shield cross and fine weapon details to render crisply, with ample headroom for the Big Shoulders Display font at 28 px+ for ship names.
The 17 px Text Floor: Because the horizontal layout provides plenty of width (1440 px across), font sizes are not constrained by narrow columns. Even at the minimum scale factor (k = 0.6 on short windows), the bottom strip has enough vertical space (130 px) to maintain the 17 px floor for all core text, with secondary details tucked behind hover tooltips rather than shrinking text.

5. What Gets Worse (Honest Trade-offs)

Horizontal Scanning Distance: Moving from a single vertical rail where eyes travel down a straight line to a split horizontal layout increases the distance the eye must travel from the top-left turn indicator to the bottom-right FIRE box. This could add a small cognitive load during fast turns.
Guns Table Density: With multiple weapons equipped, the horizontal weapon table in the central strip risks feeling cramped compared to the vertical list. This is mitigated by the collapsible secondary view, but a 4-weapon loadout will require more careful spacing to avoid clutter.
Mouse Travel: The distance from checking the fleet status (bottom-left) to clicking the FIRE box (bottom-right) is longer than in a vertical rail. Keyboard shortcuts (Enter, Space, Q, E) completely bypass this.

6. Handling Occasional Items

Tree Prompt Card: Pops up as a clean, square-cornered modal card anchored directly above the centre of the bottom strip (x = 640 to x = 1280, y = 650 to y = 900), keeping the active combat units in view above it.
Retreat Control: Placed discreetly in the bottom-right utility zone right next to the battle log panel, ensuring it is always one click away without cluttering the main command strip.
Phase Banner: Appears as a sleek, centered overlay banner sliding down from just beneath the top-left pill (x = 0, y = 40, centered horizontally), using Barlow Semi Condensed text in ember/white to announce turn shifts without blocking the centre board.
