# Issue 1006 round 2, Qwen leg (KEEL shelf polish review)

Model gate: Qwen, selector confirmed Qwen3.8-Max before the pack was pasted and the chat header confirmed Qwen3.8-Max after generation; new chat, pack pasted as text, no A/B choice appeared. Run Nov 17, 2026. Filed verbatim below; the raw answer contained 0 em or en dashes, normalized to hyphens per the repo rule. Its effort figures are stated in agent-hours, which the chair leaves as written.

1. Verdict on Ryan's Three Criticisms
    
    "The bottom row still seems super unpolished." Agree. The current shelf is a typeset paragraph laid across the screen. Every element is a run of words at roughly the same visual weight, so nothing declares hierarchy. The eye has no shape to grab, no bar to fill, no glyph to recognise at a glance. It reads like a debug console that someone set in a nice font. The reference games feel finished because their status is drawn, not written. KEEL's shelf is all writing.
    
    "Hull and shield aren't together and are approached differently." Agree, and this is the sharpest problem. Hull is a text figure ("Hull 135 / 135"). Shield is a text figure plus a slim bar. They sit in different positions, use different visual grammars (one is pure text, the other is text plus bar), and belong to different sentences in the layout. The player must read two separate notations for what is functionally one question: "How much can this ship still take?" The reference games treat ship durability as one stacked block. KEEL should too.
    
    "It's mostly just text instead of visual icons." Agree, with one qualification. Text is correct for names (ship name, target name, weapon names) and for the one contextual sentence (the status line). Text is wrong for everything that is actually a number, a state, or an action. Hull, shield, range, hit chance, damage estimate, orders, commands: these are all quantities or toggles. They should be bars, glyphs, or icon-plus-figure pairs. The current shelf writes them out as prose, which is slow to parse and looks like a placeholder.
    
    I do not disagree with any of the three points. The shelf needs a visual grammar overhaul, not a copy edit.
    
    2. Concrete Revised Shelf
    
    Overall frame
    
    1920 px wide, 216 px tall. Dark gradient veil, no panels. The fleet strip occupies the bottom 26 px of the shelf. The main content zone is therefore 190 px tall (including 10 px top padding). All corners square. All spacing in multiples of 4 px.
    
    The main content zone is divided into six columns, left to right, following the decision order. I give approximate widths. Gaps between columns are 24 px.
    
    Column A - Ship identity and vitals (hull + shield as one unit) - 340 px
    Column B - Guns - 340 px
    Column C - Target, odds, and damage estimate - 280 px
    Column D - FIRE box - 200 px
    Column E - Orders and Command - 300 px
    Column F - Log - 220 px
    Gaps - Five inter-column gaps at 24 px, plus margins - 140 px
    Total - 1920 px
    
    Column A: Ship identity and vitals (340 px)
    
    Top row (32 px tall): Ship name in the condensed display face, 32 px, ember orange if this is the acting ship, off-white otherwise. "UNYIELDING OATH".
    
    Second row (18 px tall): Class line in the semi-condensed sans, 18 px, muted grey. "Vigil-class cruiser". Move figure ("Move 0 of 4") moves behind hover on the ship glyph (see below). The standing surface does not need it during the firing decision.
    
    Third and fourth rows (56 px tall, the vitals block): This is the single unified unit Ryan asked for.
    
    At the far left of the block, a ship-silhouette glyph, 24 px wide by 40 px tall, drawn as a simple side-profile outline of the hull class (cruiser, frigate, carrier, etc.). This glyph is the visual anchor for "everything to its right is this ship's body." The glyph is off-white at full health, shifts toward the muted damage colour as hull drops. Move remaining is shown as a tiny row of four pips (filled squares, 4 px each) beneath the glyph. Hover on the glyph shows the full move readout.
    
    To the right of the glyph, two horizontal bars stacked with 4 px gap, both 220 px wide, both 16 px tall, both square-cornered.
    
    Top bar: Shield. Glacier blue fill on a dark track. Mono figure "80 / 80" right-aligned at the bar's right end, 17 px, Glacier blue.
    
    Bottom bar: Hull. Ember orange fill on a dark track (shifts to the muted damage colour as hull drops below 40%). Mono figure "135 / 135" right-aligned, 17 px, matching the bar's current colour.
    
    Both bars share identical geometry, identical figure placement, identical track style. One grammar. The only difference is the fill colour, which is already the standing rule (Glacier for shield, ember for hull).
    
    A small shield glyph (a flat hexagon, 12 px) sits at the left end of the shield bar. A small hull glyph (a flat rectangle with a keel line, 12 px) sits at the left end of the hull bar. These two glyphs plus the two bars plus the two figures form one visual group. The player reads "durability" as a single shape.
    
    The status line ("The enemy fleet is focusing its fire on this ship.") sits beneath the vitals block in the semi-condensed sans, 17 px, muted grey. It stays text. It is a sentence, and sentences are what text is for. It is the only sentence in this column.
    
    Column B: Guns (340 px)
    
    Three weapon rows, each 36 px tall, stacked with 6 px gaps. Each row, left to right:
    
    Weapon glyph, 20 px square. For the Sear battery: three short parallel horizontal lines (a battery volley). For the Oath lance: a single long thin triangle pointing right (a lance). The glyph is drawn in the weapon's state colour (see icon section below).
    
    Weapon name in the semi-condensed sans, 17 px, off-white. "Sear battery" or "Oath lance". No arc letter in text; the arc is shown by a small directional tick on the glyph itself (a 4 px notch on the glyph's edge pointing P for port, S for starboard, F for forward).
    
    Range track: a horizontal line 80 px wide, 4 px tall, with a filled portion showing the weapon's effective range band and a small diamond marker showing the current target's range within that band. If the target is out of range, the diamond sits past the end of the track and the track's fill dims to 30% opacity. This replaces the text "1-5" and "out of range."
    
    State figure: if the weapon can fire, the hit chance in mono, 17 px ("92%"). If it cannot fire, no figure; the dimmed glyph and track say enough. This replaces the text "out of range."
    
    No full sentences in this column. The old row "Sear battery P 1-5 out of range" becomes: battery glyph with port notch, dimmed, empty range track, no figure. The player reads "cannot fire" in half a second without parsing a sentence.
    
    Column C: Target, odds, damage (280 px)
    
    Three stacked rows:
    
    Row 1 (24 px): A crosshair glyph (two concentric squares with a gap, 16 px) followed by the target name in the condensed display face, 28 px. Red if the target is the Nemesis ("FLEET MARSHAL PETRA VALK"), off-white otherwise.
    
    Row 2 (20 px): Hit chance. The crosshair glyph repeats at 12 px, then a mono figure "92% to hit" in 17 px. Below the figure, a tiny horizontal bar (120 px wide, 6 px tall) filled to 92%, giving the percentage a visual weight beyond the number. The bar fill is ember orange.
    
    Row 3 (20 px): Damage estimate. Two small glyphs side by side: the shield hexagon (12 px, Glacier) with "7" beside it, and the hull rectangle (12 px, ember) with "8" beside it. Then a total: "About 16" in mono. This replaces the sentence "About 16 damage: 7 to shields, 8 to hull." The glyphs make the split instant.
    
    Column D: FIRE box (200 px)
    
    Unchanged. The single outlined box. Square corners. "FIRE THE OATH LANCE" in the condensed display face. This stays exactly as designed. Its isolation as the only box is strengthened by the fact that everything around it is now unboxed glyphs and bars.
    
    Column E: Orders and Command (300 px)
    
    Two rows of icon glyphs, each glyph 32 px square, with a 10 px label beneath in the semi-condensed sans at 17 px. Six glyphs total, three per row, spaced 40 px apart.
    
    Orders row: Brace, Concentrated fire, Turn.
    
    Command row: Command, Fire for effect, End ship.
    
    Each glyph sits directly on the veil. No box, no tile, no border. The glyph shape is the boundary. (See section 4 for the full glyph set and state treatment.) The labels beneath are always visible. They are the names, and names are text's job.
    
    Column F: Log (220 px)
    
    "Log" in the semi-condensed sans, 17 px, muted grey, as a header. Below it, the last two log lines in the same face at 17 px, truncated with ellipsis if they exceed the column width. This stays text. Log entries are sentences. They are also the least decision-relevant content on the shelf, so they sit at the far right and stay quiet.
    
    Fleet strip (full width, bottom 26 px of the shelf)
    
    Revised. At 14 ships, the current "name plus hull figure" text line is too dense. The revision:
    
    Each ship is represented by a small hull-silhouette glyph (12 px wide, 16 px tall, same profile shapes as the vitals glyph in Column A but smaller) followed by a micro hull bar (36 px wide, 4 px tall, ember fill). No name text on the strip. The glyph plus bar is the standing representation. Hover on any ship's glyph shows the name and exact hull figure as a tooltip.
    
    The acting ship's glyph glows ember orange and its micro bar is fully lit. Destroyed ships show the glyph at 20% opacity with an empty bar. Enemy ships (if shown) use the same glyph shapes but in a muted grey.
    
    At 14 ships: 14 glyphs at roughly 56 px each (glyph + bar + spacing) = 784 px, centred in the 1920 px strip. Plenty of room. At 6 ships the strip breathes more. This solves the density problem the current text line would hit at 14 ships.
    
    3. Reference Patterns: Borrow and Refuse
    
    Borrow from BattleTech (HBS):
    
    The principle that a ship's physical state is a picture, not a paragraph. The vitals block in Column A (silhouette glyph plus two stacked bars) is directly descended from the paper-doll-plus-bars idea, simplified because Voidsworn ships do not have per-location armour.
    
    The weapon checklist with icons and damage numbers at the right. Column B follows this: glyph, name, compact state. No sentences.
    
    Refuse from BattleTech:
    
    The multi-location armour diagram. Voidsworn has one hull pool and one shield pool. A paper doll with eight locations would be false detail.
    
    The heat and stability vertical bars. Voidsworn does not have these systems.
    
    Borrow from Battlefleet Gothic: Armada 2:
    
    The stacked, icon-headed bars for hull and shield in one status block. This is the closest model for the vitals block in Column A. BFG:A2 puts a small anchor icon before the hull bar and a shield icon before the shield bar. I adopt that pattern: glyph at the bar's left end, figure at the right end.
    
    The cooldown sweep on ability icons. I adapt this for orders and commands: an unavailable glyph dims rather than showing a sweep, because Voidsworn's orders are not on timers. They are contextually available or not. A sweep would imply a countdown that does not exist.
    
    Refuse from BFG:A2:
    
    The pictorial icon buttons with heavy chrome borders and background fills. Those are boxes. They violate the veil rule.
    
    The top resource bar with icon-plus-number pairs. Not relevant to the bottom shelf.
    
    Borrow from Sins of a Solar Empire 2:
    
    The discipline that every value is an icon plus a number or a bar, and text is reserved for names and tooltips. This is the governing principle of the entire revision.
    
    The small ship-card icons for fleet representation, adapted here into the fleet strip glyphs.
    
    Refuse from Sins 2:
    
    The tile-grid ability bar with distinct boxed slots. Again, boxes.
    
    The empire-resource panel density. Voidsworn's shelf is for one ship's firing decision, not an economy overview.
    
    The common pattern I borrow: Status is drawn. Actions are icons. Text carries names and sentences only.
    
    The common pattern I refuse: Chrome, tiles, borders, panel backgrounds. All of it. The glyphs and bars float on the veil. The veil is the only "container." This is the scoped answer to the tension Ryan's brief raises. Icons do not need boxes to read as icons. They need contrast, consistent size, and clear spacing. On a dark gradient veil, a 32 px ember glyph with 40 px of clear space around it reads as a distinct interactive element without any border. The FIRE box remains the single boxed element, and its uniqueness is reinforced by the unboxed field around it.
    
    4. Icon Set
    
    Every glyph is drawn in a flat, single-weight line style. Square corners. No rounded terminals. No gradients within glyphs. Glyphs are filled shapes, not outlined shapes, so they read at small sizes without anti-aliasing ambiguity.
    
    Vitals glyphs (Column A and Column C):
    
    Shield hexagon: a flat hexagon, 12 px. Glacier blue when shields are up. Dims to 40% opacity when shields are at zero. This glyph appears at the left of the shield bar and beside the shield damage figure in Column C.
    
    Hull keel: a flat rectangle with a horizontal line through its lower third (suggesting a keel), 12 px. Ember orange at full hull, shifting to the muted damage colour below 40%. Appears at the left of the hull bar and beside the hull damage figure in Column C.
    
    Ship silhouette: side-profile outline of the hull class, 24 px wide by 40 px tall in Column A, 12 px by 16 px in the fleet strip. One shape per class (frigate, destroyer, cruiser, carrier, battleship, etc.). Off-white at full hull, shifts toward muted damage colour as hull drops.
    
    Weapon glyphs (Column B), 20 px square:
    
    Battery: three short horizontal parallel lines. Represents a volley weapon.
    
    Lance: a single long thin triangle pointing right. Represents a focused beam or lance weapon.
    
    Arc notch: a 4 px square notch on one edge of the glyph. Left edge = port. Right edge = starboard. Top edge = forward. This replaces the text letter P, S, F.
    
    State: filled glyph = ready to fire and in range. Glyph at 30% opacity = out of range. Glyph at 10% opacity with a thin diagonal strike = destroyed or disabled. No colour change for state; opacity does the work. The glyph's base colour is off-white, keeping the ember and Glacier palette reserved for hull, shield, and accent.
    
    Crosshair glyph (Column C):
    
    Two concentric squares with a 3 px gap, 16 px outer, 12 px in the crosshair row, 12 px in the odds row. Off-white normally. Red only when the target is the Nemesis. This is the only glyph that changes colour for target identity.
    
    Order glyphs (Column E, top row), 32 px square:
    
    Brace: a shield hexagon (same shape as the shield glyph but larger) with two short horizontal brackets on either side. Meaning: defensive posture.
    
    Concentrated fire: three short lines converging to a single point on the right. Meaning: all weapons focus on one target.
    
    Turn: a right-angle arrow, the shaft horizontal, the head pointing up. Meaning: change heading.
    
    State: full opacity and ember tint = available. 30% opacity = not available this activation. A thin ember underline (2 px, the width of the glyph) = currently active or selected. No cooldown sweep; these are contextual, not timed.
    
    Command glyphs (Column E, bottom row), 32 px square:
    
    Command: a four-pointed star. Meaning: issue a command point action.
    
    Fire for effect: a six-line radial burst (like a small starburst). Meaning: all weapons fire at once.
    
    End ship: a rightward chevron with a vertical bar at its right (a "stop and move on" shape). Meaning: end this ship's activation.
    
    State: same opacity and underline treatment as orders.
    
    Fleet strip glyphs:
    
    Ship silhouettes at 12 px by 16 px, same shapes as Column A. Ember glow on the acting ship. 20% opacity for destroyed. Micro hull bar beside each.
    
    Colour discipline across all glyphs:
    
    Off-white is the default glyph colour for weapons, orders, commands, and fleet strip.
    
    Ember orange marks the acting ship, available-order underlines, hull bars, and the FIRE box.
    
    Glacier blue marks shield bars and the shield hexagon only.
    
    Red marks the Nemesis target name and crosshair only.
    
    Muted damage colour marks hurt hull figures and hull bars below 40%.
    
    No other colours enter the glyph set. State is shown through opacity (100%, 30%, 10%) and the presence or absence of the ember underline. This keeps the palette tight.
    
    5. Honest Costs and Risks
    
    Legibility at 1080p. The smallest elements are the fleet strip glyphs at 12 px by 16 px and the arc notches at 4 px. The 4 px notch is the riskiest item. At 1080p on a 24-inch monitor it is visible but small. Mitigation: the arc notch is secondary information. The player who needs to confirm an arc can hover the weapon row for a tooltip that spells out "Port arc" in text. The notch is a glance aid, not the sole carrier. If playtesting shows the notch is invisible, it can grow to 6 px without breaking the glyph's proportions. Everything else is at or above 12 px and should read cleanly.
    
    The mono figures at 17 px are at the floor of the size rule. They are legible in a mono face at 1080p but I would not push any figure below this. The "7" and "8" damage figures in Column C are 17 px mono and should be fine.
    
    Art and build effort. In agent terms:
    
    The ship silhouette set (five or six class profiles at two sizes, 24 px and 12 px) is roughly 2 agent-hours for clean vector shapes plus 1 agent-hour for the damage-colour tint variants. Call it 3 agent-hours.
    
    The weapon glyphs (battery, lance, plus the arc notch variants) are about 2 agent-hours.
    
    The order and command glyphs (six glyphs, three states each) are about 4 agent-hours because each glyph needs a full-opacity, dimmed, and underlined variant.
    
    The shield hexagon, hull keel, and crosshair glyphs are about 1 agent-hour.
    
    The fleet strip micro-glyphs reuse the silhouette set, so no additional drawing, but the bar-and-glyph layout code is roughly 2 agent-hours.
    
    The bar components (hull bar, shield bar, range track, hit-chance bar) are one shared visual pattern with different fill colours. Roughly 3 agent-hours to build the reusable bar node in Godot with colour, fill, and figure parameters.
    
    Total new art and component work: roughly 15 agent-hours. This is modest. It does not require animation, particles, or shader work.
    
    Fleet strip at 14 ships. The revised strip uses 14 glyphs at 56 px each, totalling 784 px. This fits comfortably in 1920 px. At 6 ships the strip uses 336 px and looks sparse. Mitigation: centre the strip and let the gaps breathe. Alternatively, at low ship counts, show the name text beside the glyph since there is room. I would keep the glyph-and-bar-only format for consistency and let hover carry the name at all fleet sizes.
    
    What the revision breaks.
    
    The status line ("The enemy fleet is focusing its fire on this ship.") is the last sentence in Column A. If the vitals block grows, this line may need to move behind hover. I would keep it visible for now because it is the only contextual sentence and it informs the firing decision. If it crowds the column, it is the first candidate to move to a hover tooltip.
    
    The "Move 0 of 4" figure is removed from the standing surface and placed behind hover on the ship glyph. If playtesting shows players need to see move remaining during the firing decision (I doubt it, since moving and firing are separate activation phases), it can be restored as a fourth row in Column A. For now, SAY LESS applies.
    
    The log loses one line. The current shelf shows "the last two or three log lines." At 220 px wide and 17 px per line, two lines fit cleanly. Three would crowd the column. I set it at two lines. The third is one scroll or hover away.
    
    Weapon names are shortened in the standing view. "Sear battery" not "Sear battery P 1-5." The arc and range are now visual. Players who learned the old text format will need one or two sessions to re-learn the glyph vocabulary. This is a short-term onboarding cost for a long-term readability gain.
    
    The no-boxes tension, priced. I am not requesting a scoped exception for icon tiles. The glyphs sit on the veil without boxes, borders, or background fills. They work because the veil is dark and the glyphs are light, and because consistent sizing and spacing do the work that borders do in the reference games. The risk is that without boxes, the glyphs may not read as "clickable" to players trained on boxed UIs. Mitigation: the hover state (a subtle ember glow, 2 px, around the glyph) provides the interactivity cue. The cursor change to a pointer provides the second cue. No box needed. If playtesting shows players cannot find the orders, the fallback is a 1 px ember underline on available glyphs, which I have already included in the active-state treatment. This costs nothing extra.
    
    6. One Thing KEEL Does Better Than the References
    
    The left-to-right decision sequence. In BattleTech, you look at the mech diagram, then drop your eyes to the weapon list, then look up at the target, then back down to the fire button. The path is a Z or a scatter. In BFG:A2, the ship panel is on the left, abilities are at the bottom, the target is somewhere in the 3D view. In Sins 2, the selection panel and the ability bar are in different screen regions.
    
    KEEL's shelf puts the entire decision chain in one horizontal sweep: ship, vitals, guns, target, odds, FIRE, orders, command, fleet. Your eye moves left to right through the exact sequence of questions the game is asking you, and the FIRE box sits at the physical climax of that sweep, two-thirds across the screen, where your gaze arrives naturally after reading the odds. No reference game does this. They arrange information by category (status here, weapons there, actions elsewhere). KEEL arranges information by decision order.
    
    My revision changes the visual grammar of every element in that sweep, but it does not change the sweep itself. The columns stay in the same order. The FIRE box stays in the same position. The fleet strip stays at the foot. The revision makes each stop along the sweep faster to read (glyphs and bars instead of sentences), but the sweep remains a single left-to-right motion. That is the thing the references do not have, and the thing this revision must not lose.
