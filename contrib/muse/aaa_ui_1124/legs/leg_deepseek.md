# Leg: DeepSeek (DeepThink on, Search off), issue 2030

Gate record: New chat. DeepThink ON and Search OFF verified visually before submitting (DeepThink blue, Search grey) and still so after generation. Brief pasted as plain text (the first paste became a .txt chip; the browser used DeepSeek's "Paste original" to replace it with plain text and verified no attachment before sending). Thinking took 102 seconds; the collapsed thinking trace is not part of the answer and is not reproduced. Chat: "AAA design pack", https://chat.deepseek.com/a/chat/s/4851abdc-1ac4-4010-8a7b-88ed08dda79e

Response verbatim:

Screen 1: Shipyard with the ships

a) Design

Reference resolution 1920x1080. Keep the dark ember panels, thin 1 px borders and KEEL HUD grammar. The shipyard becomes three columns.

Layout

- Top bar: 64 px tall. Left: back button 40x40. Center: title "SHIPYARD". Right: salvage total, 180x32.
- Left ship list: x=16, y=80, w=360, h=984. Scroll container. Each ship row is 344x100, 8 px gap. Row shows name 13 px, class 10 px, hull bar 344x6, captain face 32x32, and a 2 px ember border when selected. This is a compact index, not the full card.
- Center model bay: x=392, y=80, w=880, h=720. SubViewportContainer inset 16 px, so 848x688. Dark ember panel, 1 px border. 3D ship model centered. Camera at local (0, 1.2, 4.5), looking at (0, 0.8, 0), FOV 35. Warm key light 1.2, cool fill 0.4, ember rim 0.8. Ship turns around Y at 8 degrees per second. Bay floor grid at y=0. Bottom left of bay: ship name and class plate, 320x48.
- Right inspector: x=1288, y=80, w=616, h=984. Sections: header 88 px, stat block 240 px, weapons 160 px, captain row 72 px, refits line 60 px, action area 140 px. Stat rows are 32 px tall. Hull bar is 616x14.
- Action area: buttons 180x48. Row 1: Repair, Mk II, Refit. Row 2: New Hull, Decommission. Disabled buttons use 40 percent alpha and show the reason in 10 px red text above the button.

Elements and exact data

- Header: ship name 20 px, class 12 px, Mk level 11 px.
- Hull bar: current and max, example "78 / 100".
- Stat lines: Shields, Armor, Speed, Turns, Evasion. Shields are one pool only. Example "Shields 42 / 60". Never show facings or arcs.
- Weapons list: slot label, weapon name, section tag. Example "W1 Lance, Prow". Rows 24 px.
- Captain row: portrait 48x48, name 12 px, callsign 10 px amber, trait line 10 px, max two lines, XP line 9 px.
- Refits line: comma list, 10 px, wraps to two lines.
- New Hull flyout: 460x220, opens above the New Hull button. Three hull chips 140x72. Each chip shows name, class, cost, and one key stat. Hovering a chip previews that hull against the selected ship.

Interactions

- Hovering Repair computes candidate hull = hull max. Hull bar shows a green ghost segment for the gain. If hull is full, button is disabled and hover text says "Hull full".
- Hovering Mk II reads the upgrade table and writes deltas onto every changed stat row. Better values get green "+X" or green "-X" if lower is better, worse values get red. Weapon list shows added weapon in green with "+", removed weapon in red with "-".
- Hovering Refit shows stat deltas plus refit line preview in green or red.
- Hovering New Hull opens the flyout. Hovering a hull chip previews that hull's stats against the selected ship. Cost is shown red if unaffordable. Commit on click if valid.
- Preview is visual only. No state changes until click. Commit must call the same PreviewOp function used for preview so numbers cannot diverge.
- Preview updates on mouse_entered immediately. It clears 80 ms after mouse_exit. Model rim light increases 0.2 over 150 ms on any action hover.

Data sources
Ship: id, name, class, hull_current, hull_max, shield_pool, shield_max, armor, speed, turns, evasion, weapons[].slot_label/name/section, captain.portrait/callsign/trait/xp, refits[]. PreviewOp returns: stat_key, old, new, delta, is_better, cost, disabled_reason.

Edge cases

- Selected ship decommissioned: clear preview, select next row, show 2 second toast.
- Repair at full hull: disabled, no green preview.
- Insufficient salvage: button disabled, cost red, preview still explains gain.
- Mk II at max: disabled, "Mk III locked".
- Refit has no slots: disabled, "No refit slot".
- New hull flyout has no candidates: show "No hulls available" and keep button disabled.
- Missing 3D model: show flat silhouette in bay and text "Model unavailable". Do not block other actions.
- Multiple hovers: last hover wins. Do not stack previews.

b) Least sure
Whether compacting the left list to 344x100 rows is enough. The old card carried all text, and moving detail to the right inspector may slow comparison between ships.

c) Biggest risk
Preview and commit using different calculation paths. That would make the shipyard untrustworthy. Mitigation: one PreviewOp function, one commit path, unit tests on every stat delta.

Screen 2: Ship state plate on the board

a) Design

Each ship gets one screen-space plate, not a 3D label. Plate base size is 168x84 at 1920x1080 and camera distance 170. Scale by project stretch. Plate is a CanvasLayer Control with 1 px border, dark ember fill, and 10 px corner radius.

Plate layout

- Top row, height 22: faction pin 8x8 at x=8, ship name 11 px truncated at 14 characters, shield chip 58x18 at right.
- Hull bar, height 6, width 152, with "H 78/100" at 9 px above or beside it.
- Section row, height 40: three chips 52x40. Each chip has letter P, M or E at 10 px, a 3 px status strip, and a systems label at 9 px over two lines.
- Shield chip shows one icon and one number, example "SH 42/60". No facings anywhere.
- Selected plate gets 2 px ember border and four 10 px L corner brackets around the plate itself.
- Hovered plate gets 1 px amber border.
- Non-selected plates have no ring and no bracket.

Section loss text
Read from ship.sections[section].disabled_systems. Use each system short_label. Examples:

- Prow intact: dim "W1 W2"
- Prow lost: red "LOST W1 W2"
- Mid lost: red "LOST W3 W4"
- Engines lost: red "LOST ENG 0 SHLD"
- If no systems: "none"
- If more than six short labels, plate height grows to 108 and uses three lines. If still more, show first five plus "+N" and a hover expansion with full names. The hover expansion is 220x120 and does not pause.

Overlapping marks solution
All ownership marks move to the plate. Pins live on the plate. Brackets surround the selected plate. Selection ring is drawn only for the selected ship at the waterline. Non-selected ships have no ring and no bracket. Hovered ships only get an amber plate border. This removes crossing rings and brackets.

Adjacent ship behavior

- Desired plate position: project ship root to screen, then plate bottom center is 120 px above that point.
- Sort plates by priority: selected, hovered, currently firing, then screen x.
- For each plate, test against placed plate rects inflated by 8 px and against the bottom fire controls safe rect y=920 to 1080. Try offsets in this order: (0,12), (0,24), (0,36), (24,0), (-24,0), (48,0), (-48,0).
- If no offset is clear, place plate in right screen rail at x=1736, y=120 + slot*96, max 6 slots. Then left rail. Draw a 1 px leader line from the plate edge nearest the ship to the ship anchor. Leader alpha 0.55. Hide leader if plate is within 8 px of anchor.
- When two ships are within 96 px on screen, they enter linked mode: selected plate stays nearest its anchor, other plate shifts vertically first, both use leader lines. Selection ring stays only under selected ship.
- If selected ship is adjacent to another, the other plate moves, not the selected ring. Brackets never move to the ship silhouette.

Interactions
Click plate selects ship. Hover expands full section text if truncated. Section loss pulses red for 180 ms and updates text in the same frame. Shield break flashes shield chip for 120 ms.

Edge cases

- Offscreen ship: clamp plate to 16 px margin with arrow icon and no leader.
- Ship destroyed: plate fades 250 ms then removed.
- Plate would enter bottom fire controls safe rect: move up first, then rail.
- Two plates still overlap after all offsets: rail fallback wins.
- Long ship name: truncate with ellipsis, full name on hover.

b) Least sure
168x84 may still be too large in a six ship fight. The rail fallback is robust but reduces spatial association.

c) Biggest risk
Loss text length jitter. Fixed width plus short labels plus plate height growth must be enforced, or plates will pop and overlap.

Screen 3: Captains and admirals

a) Design

Portrait banner
Banner is a CanvasLayer Control, 460x72, at top center x=(viewport_width-460)/2, y=12. It never pauses, never takes input, mouse_filter IGNORE, and never covers the selected ship or fire controls.

Banner layout: portrait 56x56 at x=8, y=8. Event label 10 px uppercase at x=72, y=8. Speaker name and callsign 13 px at x=72, y=22. Trait line 10 px at x=72, y=40. Event line 11 px at x=72, y=54.

Timings: slide in from y=-80 to y=12 over 180 ms ease out. Hold 2600 ms. Slide out to y=-80 over 160 ms. Queue max 3. Priorities: admiral command 0, hail 1, section loss 2, kill 3. Higher priority preempts current with 120 ms out. Same priority is FIFO.

Safe placement
Before showing, compute banner rect. Candidate slots: top center, top left x=16 y=12, top right x=viewport_width-476 y=12, bottom left above fire controls. Choose first that does not intersect selected ship screen rect expanded by 24 px and does not intersect fire controls rect. If none are safe, show a 24x24 icon at top right with tooltip and queue the full banner until a safe slot opens.

Event data
Hail: speaker portrait, label "HAIL", text from event. Admiral command: admiral portrait, label "ADMIRAL", text from command. Section loss: captain portrait, red border, label "SECTION LOST", text example "Prow lost: W1, W2". Kill: captain portrait, ember border, label "KILL", text example "Enemy frigate broken".

Captain identity on ship card and fallen roll
Ship card adds a captain row below the header: 48x48 portrait, name 12 px, callsign 10 px amber, trait line 10 px max two lines, XP line 9 px. Fallen roll rows are 72 px: 56x56 portrait, name, callsign, trait, and "Lost to <enemy ship> by <weapon>" when killmail data exists. Missing portrait uses a dark silhouette placeholder.

Edge cases

- Multiple section losses same frame: coalesce by ship into one banner.
- Multiple kills by same captain within 1 second: coalesce into "2 kills".
- Battle ends: clear queue and hide banner.
- Long trait: ellipsis at two lines, full text in captain card.
- Missing portrait: placeholder, banner still shows.

b) Least sure
The safe slot algorithm may still find no safe slot in a crowded top center fight. The 24x24 icon fallback preserves the hold but weakens communication.

c) Biggest risk
Banner noise. Section losses and kills can flood the queue. Coalescing by ship and by captain is mandatory.

Screen 4: After-action report

a) Design

Full-screen overlay. Panel 1280x820 centered at x=320, y=100. Dark ember fill, 1 px border. Header 64 px: "AFTER ACTION", outcome, total salvage. Main per-ship table 1200x560 at x=40, y=80. Row height 56, scroll if more than 8 ships.

Per-ship table columns
Ship 240 px, Captain 200 px, Kills 80 px, Damage dealt 140 px, Damage taken 140 px, Captain XP 120 px, MVP 80 px. Row shows ship name 12 px, class 9 px, captain face 32x32, callsign 9 px. Lost ships use 60 percent alpha and a "LOST" tag.

Sort by damage dealt descending. MVP badge is a 24x24 ember seal on one row. MVP score tuning start: damage_dealt + 0.25 * damage_taken + 150 * kills + 50 * sections_lost_by_enemy. Tie break: kills, then damage_dealt, then captain XP. Damage taken counts applied damage only, not overkill.

Footer: compact salvage pick strip 1200x120 at x=40, y=660. Three wreck cards 240x96 and a Continue button 180x48. This keeps the old salvage choice but removes the summary paragraph and separate XP lines.

Killmail card
On the run timeline, each lost ship node is clickable. Click opens a 300x140 killmail card anchored beside the node. Card title "KILLMAIL". Shows lost ship name and class, killer enemy ship name and class, weapon name, time, and primary damage type if present. If multiple attackers, show primary killer and "Assist: X" if known. Click elsewhere closes. Card does not pause.

Data sources
battle_stats per ship: kills, damage_dealt, damage_taken, captain_xp_gained, sections_lost, survived. run.timeline_events ship_lost: lost_ship_id, killer_ship_id, weapon_id, time, assist_ids.

Edge cases

- No kills: show 0, not blank.
- Ship lost but MVP: keep badge, row grey, MVP still named.
- Unknown killer: "Unknown attacker". Unknown weapon: "Unknown weapon".
- Environmental loss: weapon line "Hull breach" or event reason.
- Long names: wrap to two lines, row grows to 64 px.
- Many ships: table scrolls, header stays fixed.

b) Least sure
Keeping the salvage pick strip in the footer. The brief says replace the old panel, and this may feel like one leftover. It is easy to hide if the council wants a pure report.

c) Biggest risk
Stats credibility. If damage taken includes overkill or shields and hull double count, players will distrust the MVP. Define damage taken as applied damage only.

Single strongest objection to the brief

The Screen 2 hold asks every plate to name the actual systems disabled by each section at standard battle camera distance 170, while also showing hull, one shield pool, three sections and ownership marks. That is too much text for a fleet battle. The brief should allow full loss text on selected or hovered plates and section color plus short system count on non-selected plates. Otherwise the plate either becomes unreadably small or becomes a large screen-space object that hides the board.
