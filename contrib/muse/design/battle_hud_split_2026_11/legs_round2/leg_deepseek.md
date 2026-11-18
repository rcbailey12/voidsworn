# Issue 1006 round 2, DeepSeek leg (KEEL shelf polish review)

Model gate: DeepSeek, DeepThink ON and Search OFF verified by toggle state before the pack was pasted and again after the answer completed; new chat, pack pasted as text inline (the browser worker used the paste-original control, no file uploaded). Run Nov 17, 2026. Filed verbatim below; the raw answer contained 0 em or en dashes, normalized to hyphens per the repo rule.

1. Verdict on Ryan's three criticisms
    
    - Unpolished bottom row: agree. The shelf is not ugly because it is text. It is unpolished because most items have the same visual weight and no anchors. Ship name, hull, shield, guns, status, target, odds, orders, Command, and log all read as adjacent text runs. The eye has no fast route through the decision. KEEL needs a stronger visual rhythm, not a new concept.
    
    - Hull and shield treated differently and apart: agree, strongly. Hull is a text figure, shield is text plus a bar. That is the clearest inconsistency in the shelf. They must become one integrity unit with one grammar: same icon slot, same label slot, same mono figure slot, same track geometry, two stacked rows.
    
    - Text where icons should be: partly agree. State and action elements should become glyph plus short label. Names, target identity, odds, and damage numbers should stay text or mono, because exact values and names are the decision. Icon-only would hurt an alternating activation game where players decide every few seconds. The fix is not "replace text with icons"; it is "draw status, use glyphs for actions, keep names and exact figures legible."
    
    2. Revised shelf
    
    At 1920 by 1080, keep the shelf 216 px tall. Use a main band from 12 to 156 px and the fleet strip from 168 to 208 px. Left margin 32, right margin 32. No panels. No new boxes except FIRE.
    
    Columns, left to right:
    
    - Ship block, x 32, width 300. Ship name, class line, move icon plus figure, focused fire status.
    - Integrity block, x 348, width 260. One unit, two stacked rows: hull above shield.
    - Guns block, x 624, width 400. Three weapon checklist rows.
    - Target and odds block, x 1040, width 280. Red target name, large odds figure, damage split.
    - Actions block, x 1336, width 360. FIRE box at top, orders row below, Command row below that.
    - Log block, x 1712, width 176. Small log glyph plus one last line; full log on hover.
    - Fleet strip along the foot, x 32 to 1888, height 40. Compact slots with ship glyph, truncated name, mini hull bar, acting ship ember bar.
    
    The integrity unit is the key change. Hull and shield become two rows of the same component. Each row has a 20 px icon slot, a 17 px label, a 22 px mono figure at the right, and a 10 px track under it. Hull uses a neutral fill; missing hull uses the muted damage colour. Shield uses Glacier blue fill and Glacier figure. Same height, same spacing, same figure position. Per-side shield coverage stays behind hover.
    
    Line by line:
    
    - Ship name: stays text, display face, 32 px or larger. Keep.
    - Class line: stays text at 18 px. Split off Move as a hex arrow glyph plus mono "0/4". Keep class name as text.
    - Hull line: becomes the top row of the integrity unit. Icon, "HULL", mono figure, bar. No separate sentence.
    - Shield readout: becomes the second row of the same integrity unit. Icon, "SHIELD", mono figure, Glacier bar. No separate bar floating to the right.
    - Guns table: becomes a weapon checklist. Each row gets a weapon glyph, weapon name text, arc wedge glyph with P/S/F letter, range band in mono, and state or hit chance. Out of range dims the row to about 60 percent and uses a blocked glyph. Hit chance stays mono, for example "92%".
    - Status line: becomes a focused fire glyph plus short label "FOCUSED FIRE" at 17 px. The full sentence moves to hover. This is the one important sentence that can compress, because the glyph carries the warning.
    - Target: stays red text, with a small red Nemesis diamond or crown glyph. Red remains Nemesis only.
    - Odds: becomes a large mono "92%" with a lance glyph and small "Oath lance" label. The sentence "92% to hit with the Oath lance" is cut. Damage split becomes shield glyph plus "7" and hull glyph plus "8", with total "16" nearby. No sentence.
    - FIRE box: stays the single outlined box. Text remains "FIRE THE OATH LANCE".
    - Orders row: becomes three bare glyph plus label actions: Brace, Focus fire, Turn. No boxes, no tiles, no shortcut labels. Use invisible hit areas on the veil. "Concentrated fire" shortens to "Focus fire" on the standing surface; full name on hover.
    - Command row: becomes three bare glyph plus label actions: Command, Fire for effect, End ship. Same no-box treatment.
    - Log: becomes a small log glyph plus one last line at 17 px. The full two or three lines move to hover. This reduces the right end's text weight.
    - Fleet strip: becomes one compact slot per ship, roughly 128 px at 14 ships. Each slot has a mini ship glyph, truncated name at 17 px, and a mini hull bar. The acting ship gets an ember bar at the foot of its slot. Full names on hover. At 6 ships the slots widen; at 14 they compress but remain one line.
    
    3. Reference patterns to borrow and refuse
    
    - Borrow from Battlefleet Gothic: Armada 2: the stacked icon-headed hull and shield bars in one status block. That is exactly the grammar this shelf needs. Borrow its cooldown sweep idea for action glyphs, but draw the sweep as a thin arc on the glyph, not a tile.
    - Borrow from BattleTech: the weapon checklist with icons and numbers at the right. Keep the checklist discipline. Refuse the paper-doll and per-location diagram. Voidsworn has pooled shields and the ruling already removed facing shields, so a location diagram would add false detail.
    - Borrow from Sins of a Solar Empire 2: icon plus number pairs and compact ship cards. Use that for damage split and fleet slots. Refuse its dense always-on icon tiles and boxed chrome. This game has no boxes, and icon tiles would become panels by another name.
    - Refuse icon-only actions. Alternating activations mean a player must read the shelf quickly and repeatedly. Glyph plus label is faster than glyph alone for orders and Command. Refuse full modal panels or nested tooltips for the firing decision. The target, odds, damage split, and FIRE must stay in one continuous strip.
    
    4. Icon set
    
    - Hull glyph: chevron ship cross-section. Neutral. Damaged figures use muted damage colour.
    - Shield glyph: simple arc. Glacier blue only.
    - Move glyph: hex with arrow. Neutral.
    - Battery glyph: three short barrels or dots. Neutral.
    - Lance glyph: spear. Neutral.
    - Arc wedge: small wedge with P, S, or F letter. Neutral.
    - Blocked or out of range glyph: broken bracket with slash. Neutral, dimmed with row.
    - Focused fire status glyph: crosshair over a hull. Ember only when active.
    - Nemesis glyph: red diamond or crown. Red only, Nemesis only.
    - Brace glyph: shield with brace bars. Neutral.
    - Focus fire action glyph: two stacked crosshairs. Neutral ready, ember active.
    - Turn glyph: rotate arrow. Neutral.
    - Command glyph: chevron or small flag. Neutral.
    - Fire for effect glyph: burst. Neutral ready, ember active.
    - End ship glyph: anchor or stop bar. Neutral.
    - Log glyph: three short lines. Neutral.
    - Fleet ship glyph: mini hull. Neutral.
    
    State rules without colour chaos: ready is full opacity neutral glyph and label. Hover brightens the label and shows a 1 px ember baseline under the glyph. Active uses an ember glyph plus a 2 px ember underline under the label. Unavailable is 35 percent opacity with no underline. Cooling down is 35 percent opacity plus a thin ember arc on the glyph perimeter and a small mono number for turns remaining. Glacier is used only for shield readouts. Red is used only for Nemesis. Muted damage colour is used only for hurt hull figures and missing hull segments.
    
    5. Costs and risks
    
    - Legibility at 1080p: the 17 px floor is workable for labels, but action labels must stay short. "Concentrated fire" becomes "Focus fire" on the standing surface. The 10 px bars are the minimum; thinner bars will read as lines, not status. Long localisation strings will break the action rows first.
    - Art and build effort in agent terms: one agent pass for the glyph atlas, one for the integrity component and bar grammar, one for the action state component, one for fleet slot layout, one for data bindings and hover tooltips, and one QA pass at 1920 and a narrower fallback. This is not a large art bid, but it is a real UI refactor because hull and shield become one bound component and actions gain state logic.
    - Fleet strip at 14 ships: 128 px per slot is tight. Names will truncate. The acting ship ember bar and mini hull bar must carry recognition. Full names on hover are acceptable, but players who rely on names at a glance will feel the compression. If 14 long names become unreadable, the fallback is to show full names for the acting ship and hovered ship only, with truncated names elsewhere.
    - What this breaks: the full focused fire sentence and full log move behind hover, so a player may miss why a ship is under pressure. Icon literacy needs onboarding. Bare glyph hit areas on the veil need careful hover and click bounds. The log becomes less useful at a glance. The shelf becomes more scannable but less self-explanatory on first contact.
    
    6. One thing KEEL does better than the reference UIs
    
    KEEL keeps the entire firing decision in one continuous strip on the battlefield: ship, hull, shields, guns, target, odds, damage split, and FIRE. The reference UIs often split that across selected-unit panels, nested tiles, and tooltips. That plain-language firing sequence at the point of decision is better than their chrome. The revision must not lose it.
