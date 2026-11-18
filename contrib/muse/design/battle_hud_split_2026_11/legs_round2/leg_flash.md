# Issue 1006 round 2, Flash leg (KEEL shelf polish review)

Model gate: Gemini, "Quick answers 3.5 Flash-Lite" selected in the picker before the pack was pasted and verified still selected after the answer completed; new chat, signed in, pack pasted as text. Run Nov 17, 2026. Filed verbatim below; the raw answer contained 2 em dashes, normalized to hyphens per the repo rule.

1. Verdict on Ryan's Three Criticisms
    
    The bottom row is unpolished: Agree. The current bottom shelf reads like a developer debug log or a raw text dump rather than a tactical command interface. Strings like "Sear battery P 1-5 out of range" and unformatted sentences clutter the visual field, forcing the player to read paragraphs instead of scanning status at a glance.
    
    Hull and shield are treated differently and apart: Agree. Separating hull (left side as a text figure) from shield (middle-right with a slim bar) breaks visual grouping. They represent the defensive integrity of the same machine and must occupy a single, unified health-and-defense block using a shared visual grammar.
    
    Too much text instead of visual icons: Agree. Core tactical data - such as weapon arcs, range bands, hit chances, and action types - are currently spelled out in long words. Strategy games communicate state through spatial position, glyphs, and segmented bars, reserving text for proper nouns and tooltips.
    
    2. Concrete Revised Shelf: Layout and Element Accounting
    
    The bottom shelf spans 1920 pixels wide by 216 pixels high at the base of the screen, resting on a dark gradient veil with no container panels. It is divided into four main operational columns from left to right, anchored by a full-width fleet strip at its base.
    
    Column Layout (1920x216 Design Space)
    
    Column 1: Identity and Defense (Width: ~420 px)
    
    Top row: Ship name in condensed display face ("UNYIELDING OATH") with class line directly beneath ("Vigil-class cruiser, Move 0 of 4").
    
    Bottom block: A unified integrity pill combining hull and shield into a single visual unit. A segmented Glacier blue bar (shields) over a solid ember and dark gray hull bar, with mono figures overlaid ("Hull 135/135 | Shd 80/80").
    
    Column 2: Armament and Target State (Width: ~560 px)
    
    Weapons row: Three compact weapon strips replacing the text rows. Each strip uses a gun glyph, arc indicator (P, S, F), range band pill (1-5, 1-7), and a mini status state (dimmed when out of range, bright ember when ready).
    
    Target and Odds row: Target name ("FLEET MARSHAL PETRA VALK" in red) paired with a clean probability readout (92% HIT | ~16 DMG: 7 Shd / 8 Hull).
    
    Column 3: Action Execution (Width: ~380 px)
    
    FIRE Box: The single permitted framed box on the screen. A stark, solid-bordered ember box containing the text "FIRE THE OATH LANCE".
    
    Orders and Command row: Icon buttons with short text labels for secondary commands (Brace, Concentrated Fire, Turn, Command, End Ship).
    
    Column 4: Tactical Log (Width: ~560 px)
    
    Log feed: A clean, two-line scrolling text feed displaying the most recent event outcomes at the right edge of the shelf, preserving log history without clutter.
    
    Line-by-Line Item Accounting
    
    Ship name and class: Stays text (Condensed display face).
    
    Hull line (text figure): Upgraded to a unified graphical bar block paired with shields.
    
    Shield readout ("Shield 80/80" + slim bar): Merged into the unified defensive integrity block alongside hull.
    
    Guns table (3 text rows): Converted into compact, icon-driven weapon strips showing arc, range, and status.
    
    Status line ("The enemy fleet is focusing its fire..."): Cut from the standing surface; moved behind hover on the ship name/status icon as a tooltip.
    
    Target and odds (text paragraphs): Converted into a high-density, icon-and-mono-figure indicator line.
    
    FIRE box: Retained as the sole permitted boxed element, enhanced with crisp structural borders.
    
    Orders and command rows: Upgraded from bare text lines to compact icon-button arrays.
    
    Log lines: Retained as clean mono/sans text at the shelf's right edge.
    
    Fleet strip (foot of the shelf): Retained as a single horizontal line of ships, marking the acting ship with a prominent ember bar.
    
    3. Reference Patterns: Borrowed vs. Refused
    
    What we borrow from Battlefleet Gothic: Armada 2 and BattleTech:
    
    Stacked defensive bars: Combining hull and shields into a unified vertical or horizontal dual-bar graphic for instant status scanning.
    
    Icon-driven weapon arrays: Using small glyphs for weapon types, arcs, and status rather than full sentences.
    
    What we refuse from the reference UIs:
    
    Heavy panel chrome and inset boxes: Sins of a Solar Empire and BattleTech rely on heavy metallic or stone frames that violate Voidsworn's strict no-panel veil rule. Our icons sit directly on the gradient veil with no background tile.
    
    Complex paper-doll body part diagrams: BattleTech's mech damage diagram is too granular for fleet tactics. It requires constant micro-management of limbs, which distracts from alternating activation decision flow.
    
    Dense resource counters: Sins of a Solar Empire's empire-wide resource bars are irrelevant to Voidsworn's per-activation tactical tempo and would clutter the bottom bar with out-of-context numbers.
    
    4. The Icon Set
    
    All icons adhere strictly to the game's color discipline: neutral light gray for idle/ready states, Glacier blue reserved exclusively for shield-related values, ember for active/ready actions, and muted dark gray for unavailable or spent states.
    
    | Glyph Name | Visual Form | Meaning | State Indication |
    | Integrity Pill | Dual horizontal bars | Combined hull and shield status | Glacier blue fill for shields; solid ember transitioning to muted gray for hull damage. |
    | Sear Battery | Dual stacked barrel glyph | Medium energy broadside weapon | Bright ember when in range and loaded; dimmed gray when out of range or spent. |
    | Lance | Linear spearhead glyph | Heavy forward piercing weapon | Bright ember with a targeting Reticle when firing solution is locked (92%). |
    | Arc Indicator | Minimal directional wedge (P, S, F) | Weapon firing arc (Port, Starboard, Forward) | Solid white when facing target sector; dimmed when target is outside arc. |
    | Probability Reticle | Crossed targeting brackets | Hit chance percentage | Amber text for standard targets; bold red when locked onto the Nemesis. |
    | Command Action | Outline hexagon tile | Fleet or ship order button | Ember border and fill on hover/activation; dark neutral when inactive. |
    
    5. Honest Costs, Risks, and Constraints
    
    Legibility at 1080p: Compressing weapon stats, arcs, and probabilities into icon strips requires strict minimum sizes (17 px for figures, 28 px for names). The integrity pill's dual bars will be readable, but the mono figures overlaid on the bars risk becoming cramped if hull values exceed three digits.
    
    Art and Build Effort: Moderate frontend implementation cost in Godot. Requires building reusable UI components for the weapon strips, icon glyphs, and unified integrity pill, plus a hover tooltip system. This is a contained layout refactor, not a new system, but it demands careful vector or raster asset creation for each glyph.
    
    Fleet Strip Scaling at 14 Ships: With up to 14 ships in a fleet, the foot strip must compress ship names into tight, 3-letter abbreviations (UNY, VAL, etc.) on hover when fleet size reaches maximum capacity.
    
    What it breaks: The old linear text parsing habit of the player. Players accustomed to reading sentences will need to learn the new glyph language, which may cause a brief learning curve as they map icons to weapon types and arcs.
    
    6. What Current KEEL Does Better Than Reference UIs
    
    The current KEEL shelf maintains a complete absence of visual clutter by keeping text direct and flat, with no ornamental frames or distracting chrome. This preserves the game's distinctive "veil" aesthetic, where information floats cleanly over the battlefield without blocking the view. The revision must not lose this clarity: even as icons replace text, the layout must remain sparse, low-contrast, and free of heavy panels.
