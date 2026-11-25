# Leg: blind Rey (issue 2030, AAA design pack)

Written from the brief and repo evidence alone, before any external leg ran. Evidence used: the current shipyard screenshot (docs/shots/late_run_1178/L1178_late_market.png), the current victory panel (docs/shots/issue-1177-codex/V1177_victory.png), the battle camera sheets (docs/shots/board/8cbf40c/all_battle_camera.jpg), the painted admiral portraits index (godot/portraits/index.json), the battle rules on section damage (.claude/rules/godot-battle.md 6.14), and R450.

## Screen 1: Shipyard with the ships

Layout: keep the current screen's frame (title, credits and command points top right, market row, LEAVE SHIPYARD bottom right) and split the lower two thirds. Left half: the bay. Right half: the ship list as compact rows (name, class, Mk, hull bar, captain name), one row per ship, the selected row lit. The market cards stay a single row across the top of the lower section, shortened, because the bay needs the height.

The bay: the selected ship rendered by the existing flagship podium scene, lit by one warm key light from forward port above (the concept sheet light), turning slowly at about 6 degrees a second, pausing while the pointer is over it, drag to turn by hand. Under the model, a deck plate with the ship's name, class and Mk. Switching ships crossfades the model in about 300 ms; no loading hitch is acceptable because the podium scene already exists.

Hover previews: hovering Repair, Mk II, a refit card or a new hull card does two things. (1) The stat block under the bay (hull, shields, armor, speed, turns, evasion, damage summary) shows the change inline: new value in green when better, red when worse, with the delta in parentheses, e.g. Hull 94/135 to 135/135 (+41) in green; a Mk II shows hull and shields up 20 percent and damage up 15 percent, all green because a Mk II has no downside; a refit that trades speed for armor shows speed red and armor green on the same card. (2) The model answers too: hovering Repair fades the damage cutouts and scorch marks out; hovering Mk II or a new hull swaps the model to the target hull for as long as the hover lasts. If the model swap is too costly, the stat preview alone still satisfies the brief, but the repair fade is cheap (it is the damage dressing opacity) and should be in.

New hulls: the market's new hull offer gets a "view" hover that loads that hull into the bay with its base stats against the selected ship's, delta colored. Buying never happens from the bay; the card buttons stay the only commit points, so a hover can never spend credits.

Least sure: whether the podium scene can render an arbitrary fleet ship with its damage state, or only the flagship fit. If damage state cannot ride along, the repair fade dies and repair preview is numbers only.

Biggest risk: the bay eats the screen and the ship rows get too small to compare hull bars at a glance. Guard: rows keep the hull bar and numbers at today's size; the market row is what shrinks.

## Screen 2: Ship state plate and the overlapping marks

The plate: a small horizontal plate anchored above each ship, billboarded, fixed screen size at camera 170 (about 150 by 34 px at 1080p, a tuning start). Contents, left to right: a three-segment hull glyph (prow, mid, engines blocks in the ship's facing direction) where each segment fills by section health and turns ember red under 30 percent and hollow black when the section is lost; one shield bar (single pool, pale blue) above one hull bar (amber), both with no numbers at this zoom; the ship's short name in 11 px under the bars only for the selected ship and for ships that took damage in the last 3 seconds. A lost section shows its cost as a tiny icon row under the glyph: a crossed gun for lost weapon slots, a crossed nozzle for engine loss, a crossed ring for shield generation loss. The full sentence ("Prow lost: Oath lance and Sear battery disabled") belongs to the hover card and to the KEEL ship panel, not the plate; at 170 the plate's job is state at a glance, and the icons carry the disable fact.

Enemy plates: same grammar, red-tinted name, no section glyph detail beyond fill (their sections still show, because targeting a crippled section is a real decision).

Overlapping marks, the actual fix: marks stop being three independent systems. One mark stack per ship with a strict draw order and a separation rule:
1. When two ships' plates would overlap on screen, the plates stack vertically with a 2 px gap, ordered by distance to camera, connected to their ship by a 1 px leader line to the ship's ring center. The rings themselves never move; only the plates de-conflict.
2. Selection brackets belong to the selected ship only. Other ships get their ring and plate, never brackets, so brackets can never cross between ships.
3. Pins (objective and waypoint pins) yield: a pin that falls inside another ship's plate area fades to 40 percent until the ships separate.
4. Faction color is carried by the ring and the plate's left edge, so even where rings visually cross at a hex edge, the plate edge tells you whose ring you are looking at.

Before picture: the current battle camera at a close pair, rings and brackets crossing, captioned in plain words with what cannot be told apart. After picture: the same framing with stacked plates, leader lines and single-ship brackets.

Least sure: plate stacking order when three or more ships cluster (a melee). Order by screen height of the ship's base may read better than distance; needs a look test with three ships.

Biggest risk: leader lines become their own spaghetti in a six ship brawl. Cap: leader lines draw only when plates actually displaced; undisplaced plates need none.

## Screen 3: Captains and admirals

The banner: bottom left, above the log corner, a horizontal strip about 420 by 84 px: portrait (the painted admiral art, cropped square) left, then name and callsign, then one line of text. It slides in over 200 ms, holds about 3.5 seconds, slides out. It queues: at most one banner visible, the queue capped at 3, and a kill outranks a hail outranks a section loss (a section loss on the selected ship outranks everything, because it changes the current decision). It never takes focus, never pauses, and clicking it does nothing (clicks pass through). Admiral commands use the admiral's portrait; hails use the hailing captain's face; section losses and kills use the affected ship's captain.

Captains: today a captain is a name and an XP line. Give each captain a generated face from the same painted portrait pipeline as the admirals (issue 1897 set the style), a callsign drawn from their record (their ship's name is not a callsign; the callsign is a short earned tag, e.g. "the Banked Fire" pattern already used for ships in the victory text suggests captains earn epithets from deeds), and one trait line that is mechanical, not flavor only: the trait is the perk the captain already grants or earns, written as one line ("Reload drills: torpedo reload one turn faster"). Face, callsign and trait line appear in three places: the ship card (shipyard row expands on selection, and the KEEL ship panel in battle), the banner, and the fallen roll.

The fallen roll: the run's record of lost ships gains a row per loss: face, name, callsign, trait, ship name, and the loss line (battle, round, killer). This is the same data the killmail card in screen 4 needs, so build one loss record and render it twice.

Least sure: callsigns. If they are random decoration they will feel cheap within one run. Earning them from deeds (first kill, surviving at under 10 percent hull, a ram kill) makes them land, but that is a system, not just UI, and the brief only asks for the display. My design displays a callsign slot and proposes deed-earned callsigns as the source, flagged for Ryan.

Biggest risk: banner fatigue. Hails plus commands plus section losses plus kills in a big battle could chain banners for 15 seconds. The queue cap and the 3.5 second hold are the guard; a battle with more than 3 queued events drops the oldest hail first.

## Screen 4: After-action report and killmail

Replace the VICTORY panel with a report in the same panel footprint, ember grammar kept. Top: the outcome line (VICTORY or DEFEAT, rounds, credits, field repairs, weakness confirmed) exactly as today, because that part works. Below it, one row per ship in your fleet, columns: ship name and captain, kills, damage dealt, damage taken, hull remaining, captain XP gained, promotion marker where earned. The MVP row is lit and tagged MVP; MVP is the highest combined score of kills weighted first, then damage dealt, and the formula is printed in a footnote so the tag never looks arbitrary. Salvage keeps its place under the table (it is a decision, the report is a record; the decision goes after the record so the player reads the battle before spending its wreck). Defeat gets the same table; a report that only exists on victory teaches nothing.

Killmail: every loss (yours and the enemy's, if the timeline tracks both) writes a loss record at the moment of the kill: victim ship and captain, killer ship, killing weapon, round, and the final blow damage. On the run timeline, lost ships show as markers; clicking one opens a card (right side panel, same grammar as the banner but persistent until closed): the victim's face and ship, "killed by" the enemy ship name and class, the weapon by its in-game name (Oath lance, Cinder torpedo), round and battle name, and the victim captain's fate line where the game has one. Your own losses link from the fallen roll to the same card.

Data honesty: damage dealt and taken per ship must come from the battle log the game already keeps for float text and the debrief; if per-ship damage is not currently totalled, that is a small instrumentation ask for Codex, named in the design doc, not something the UI can fake.

Least sure: whether the run timeline already exists as a clickable surface. The brief says "on the run timeline", so I take it as existing; if it is only a list, the killmail card hangs off the fallen roll instead and the timeline marker is a later step.

Biggest risk: the report becomes a spreadsheet the player skips. Guard: six columns maximum, one screen, no scrolling on a standard fleet of six, and the MVP and promotion markers give the eye a reason to stop.

## Strongest objection to the brief

Screen 2 asks the plate to show "what each loss disables" and to be readable at camera 170. Taken literally (sentences on the plate) those two asks fight: sentences at 170 are either too small to read or so big they cause the overlap problem the same screen must solve. The icon row plus hover sentence split is my answer, but the Board should confirm it accepts icons as "showing what each loss disables" at plate zoom, with the sentence one hover away.
