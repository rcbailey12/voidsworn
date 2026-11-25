# AAA design pack: shipyard bay, ship state plate, captain comms, after-action report

Issue 2030, run 1. Owner: muse. Chaired by Rey from five legs: blind Rey, DeepSeek (DeepThink on, Search off), Qwen (Qwen3.8-Max), Gemini on Hydrogen (the Flash seat), and Grok (seat empty, bot wall on the cloud browser, nothing submitted; record in legs/leg_grok.md). Leg files sit beside this doc in legs/. Every number below is a tuning starting point, not a rule. Holds from the brief and R450 apply throughout: shields are ONE pool and no shield facings appear anywhere; the ember menu look and the KEEL battle HUD grammar stay; no em dashes.

## Step 0, before any screen is built: freeze the two data schemas

Two legs objected to the brief on the same ground, independently (Qwen, Gemini), and DeepSeek's data-source lists point the same way: screens 3 and 4 read data the game does not yet record in a clean shape, and screen 1's previews need one calculation path. The chair adopts the objection as a build prerequisite, not a reason to stop the design:

1. CaptainData: captain_id, portrait_id, full_name, callsign, rank, xp, trait_line. Today a captain is a name and an XP integer; this record replaces that pair everywhere (shipyard card, KEEL ship panel, banner, fallen roll, after-action report).
2. CombatEvent and its rollups: on every hit, (attacker_ship_id, attacker_name, attacker_class, weapon_id, weapon_name, target_ship_id, damage_applied, is_killing_blow, round, timestamp). Damage counts applied damage only: shield plus hull damage actually inflicted, never overkill, never double counted. Per-ship battle totals (kills, damage dealt, damage taken, captain XP) roll up from these events. On a kill, the fatal event is serialized BY VALUE into a LostShipRecord (victim ship and captain, killer ship and class, weapon name, round, battle, final damage, up to two assist ships with damage share, or the hazard name for an environmental kill) and written to the run timeline at the moment of the kill, never reconstructed later from freed nodes.
3. PreviewOp (shipyard): one function returns, for any candidate action (repair, Mk II, refit, new hull), the list of (stat_key, old, new, delta, is_better, cost, disabled_reason). Hover preview renders its output; the commit path executes the same output. Preview and commit never calculate separately.

## Screen 1: Shipyard with the ships

Picture: mocks/01_shipyard_after.png (the before state is the current screen, docs/shots/late_run_1178/L1178_late_market.png: text cards only, no ship picture anywhere).

Layout (1920x1080 reference, current frame, credits and command points, and LEAVE SHIPYARD kept): three columns under the market row.

- Left roster (about 360 px): one compact row per ship (name, class, Mk, thin hull bar, captain face 32 px, warning pip when damaged). Clicking a row selects the ship. The roster thumbnails are static snapshots rendered once when the shipyard opens or the fleet changes, never per frame (Qwen and Gemini agree; only the bay renders live).
- Center bay (about 880 px): the selected ship in the existing flagship podium scene (godot/ui/campaign/flagship_podium.gd), on a dark gantry floor, one warm key light from forward port above plus a cool rim. It turns at 6 degrees per second; drag orbits by hand (pitch clamped), release resumes turning after about 2.5 seconds. Camera distance scales from the hull's longest axis so a dreadnought and a corvette both fill the bay. The ship renders with its real damage state: scorch and section cutouts show until repaired.
- Right inspector (about 616 px): the current card, evolved. Header (name, class, Mk), captain block (portrait, callsign, name, XP bar, trait line, per screen 3), hull and shield bars, stat rows (shields as ONE pool, armor, speed, turns, evasion), weapons list with section tags, refits line, and the action area (Repair, Mk II, Refit, New Hull, Decommission) with disabled reasons written above a disabled button instead of a bare grey.

Hover previews (the core interaction, all four legs agree on the shape): hovering Repair, Mk II, a refit or a new hull writes the PreviewOp deltas onto the inspector: new value with the delta in parentheses, green when better, red when worse, with "lower is better" stats colored by benefit, not by sign. Hull and shield bars grow a translucent green ghost segment for a gain and a hatched red segment for a loss. The model answers too: Repair hover fades the damage dressing toward clean; a new hull hover cross-fades the bay model to the candidate hull (Qwen flags the cross-fade for a short art test; a hologram tint on the candidate is the fallback); a refit with a visible external module fades that module in. Unchanged stat lines dim so the eye skips them. Preview is visual only, last hover wins, and clicking is the only commit.

Edge cases: full hull disables Repair with its reason; the flagship and the last ship cannot be decommissioned (button disabled, reason shown); an unaffordable action shows its cost in red and still previews; a missing model shows a flat silhouette and "Model unavailable" without blocking the inspector.

Chair notes: the market row shrinks to one shortened row to buy the bay its height (blind Rey); roster rows keep today's hull bar size so ships stay comparable at a glance (DeepSeek's least-sure, accepted as a constraint).

## Screen 2: Ship state plate, and the overlapping marks

Pictures: mocks/02_plate_before.png (the problem, in plain words) and mocks/02_plate_after.png (the fix).

The plate is two-tier. This is the chair's answer to the tension DeepSeek and the blind leg both raised: the brief asks the plate to name what each loss disables AND to stay readable at camera 170, and full sentences on every plate at 170 either shrink to nothing or grow until the plates cause the overlap this same screen must solve.

Standing plate (every ship, about 150x56 px at 1080p, fixed screen size at camera 170, dark ember fill, faction color on the left edge, red edge for enemies):
- Row 1: short ship name; enemy plates show class and number.
- Row 2: ONE shield bar (pale blue) with the pool value on hover or selection. The bar never vanishes at zero: it sits as an empty track, hatched when shield generation is lost so "depleted" and "not regenerating" read differently (Gemini).
- Row 3: one hull bar segmented into three blocks, prow, mid, engines, each block filled by that section's health, ember under 30 percent, hollow when lost.
- Row 4: three section cells under their blocks. Intact: dim label. Damaged: amber. Lost: dark red with the primary disabled system in short form plus a count, e.g. "LANCE +1 OFF", "SHLD GEN LOST", "THRUST 0". The short labels come from the ship's own disabled_systems list, never from flavor text.

Expanded plate (the selected ship, and any plate on hover): grows to show each lost section's full sentence, e.g. "Prow lost: Oath lance, Sear battery disabled", read from the same disabled_systems data (Qwen's rows, DeepSeek's data source). The KEEL ship panel carries the same sentences standing.

Overlapping marks, one system instead of three: (all four legs converge here; this is the chaired stack)
1. Plates de-conflict, ships do not move. When plates would overlap on screen, they stack with a small gap, nearest ship's plate lowest, each displaced plate tied to its ship by a 1 px leader line. Offsets try up, then sideways; if nothing clears, the plate goes to a screen rail slot with its leader line (DeepSeek's fallback). Reordering uses hysteresis so plates do not swap sides during a pan (Gemini).
2. Brackets belong to the targeted enemy only, four corners on its screen box. The selected friendly ship never wears brackets, so the two mark types can never cross (Qwen).
3. The selection ring sits on the ground plane under the selected ship only. Other ships keep their own smaller ring and plate; where two ground rings overlap, the non-selected ring is suppressed (Qwen).
4. Pins ride on the plate, not the hull, so pins inherit the plate's de-conflicted position (Qwen, DeepSeek).
5. Faction color on the ring and the plate's left edge, so ownership survives a visual crossing (blind Rey). Gemini's ring merge shader is recorded as a stretch idea, not in this build spec.

Zoom behavior: past about distance 220 the section cells collapse to the segmented hull bar alone (selected and hovered plates keep full form); closer than 100 the plate scales down toward 70 percent so it does not cover the model (Qwen).

## Screen 3: Captains and admirals

Picture: mocks/03_comms_after.png (banner, plus the fallen roll strip).

Captain identity (CaptainData, step 0): face from the painted portrait pipeline that produced the admirals (issue 1897 set; godot/portraits/index.json), assigned without replacement so a fleet never repeats a face (Gemini's pool rule); callsign; one trait line. The trait line writes the captain's existing perk as one mechanical line (blind Rey); it is NOT a new stat modifier layer. Qwen proposed inventing trait modifiers (for example +10 percent damage, -5 percent evasion) and then flagged that as its own least-sure decision; the chair cuts it. Callsigns launch from a per-faction pool (Qwen, Gemini); deed-earned callsigns are a pick for Ryan below, because they are a system, not a display.

Where identity shows: the shipyard inspector captain block (screen 1), the KEEL ship panel, the banner, and the fallen roll. The fallen roll row: desaturated portrait, name, callsign, trait line as the epitaph line, ship name, and the loss line (battle, round, killer and weapon, from the LostShipRecord).

The banner: fixed home top-left, below the top bar (about 420x80 px): portrait left (admiral art for admiral events, the ship's captain for ship events), event tag (HAIL, COMMAND, SECTION LOST, KILL), speaker name and callsign, one line of text. It slides in over about 200 ms, holds about 3.5 seconds, slides out. mouse_filter IGNORE across the whole banner: clicks pass through to ships and orders underneath; it never pauses, never takes focus, never covers the bottom fire controls. Placement is fixed on purpose (three legs each picked a different corner; DeepSeek's safe-slot search is the alternative, and the chair judges a home the player learns by heart worth more than a banner that wanders; the top-left under the turn bar is the emptiest corner in the KEEL layout).

Queue discipline (all legs agree spam is the risk): one banner at a time, queue capped at 3. Priority: a section loss on the selected ship first, then kills, then admiral commands, then hails. Same-ship section losses in one volley coalesce into one banner; repeated kills by one captain within a second coalesce ("2 kills"). When the queue overflows, hails drop first. Battle end clears the queue.

## Screen 4: After-action report and killmail

Picture: mocks/04_aar_after.png (report with the killmail card open).

The VICTORY panel (current state: docs/shots/issue-1177-codex/V1177_victory.png) is replaced in the same footprint and grammar:

- Header: outcome (VICTORY or DEFEAT), rounds, credits, field repairs, weakness confirmed: the lines that work today, kept.
- MVP strip: the MVP ship and captain lit across the top of the table, with the reason in words ("MVP: 3 kills, 1,420 damage dealt").
- Per-ship table, one row per fleet ship, six columns at most: ship and captain, kills, damage dealt, damage taken, hull remaining, captain XP gained (with the promotion marker where a rank was earned, replacing today's loose XP lines at the panel's foot). Damage columns carry a faint proportional bar behind the number (Gemini). Lost ships stay in the table, red tinted, with a View killmail button. Defeat gets the same table.
- MVP score, printed in a footnote so the tag never looks arbitrary: 150 per kill, plus damage dealt, plus a quarter of damage taken (tuning start; DeepSeek's weights, Gemini's tie-break order: kills, then damage dealt, then damage taken, then flagship). Damage is applied damage only (step 0), which is what makes the numbers trustworthy (DeepSeek and Gemini both name this as the credibility risk).
- Salvage stays, after the table: the record first, the spending decision second (all four legs keep salvage; DeepSeek's least-sure is noted and answered this way).

Killmail: clicking a lost ship on the run timeline (or View killmail in the report) opens a card (about 420x300 px, closes on outside click or Esc): victim portrait, name, callsign, ship and class; "Killed by" the enemy ship name and class; the killing weapon by its in-game name; round and battle; final blow damage; up to two assist ships with damage share; for an environmental loss, the hazard named instead of a killer (Gemini, Qwen). Every field comes from the LostShipRecord written at the kill (step 0).

## Picks for Ryan

1. The two-tier plate (screen 2): standing plates carry the lost section's primary system in short form, the full disabled-systems sentence lives on the selected and hovered plate and in the KEEL panel. DeepSeek's objection says the brief's literal reading (full text on every plate at 170) cannot hold; the chair agrees. Confirm this reading, or the plate grows and the overlap problem gets worse.
2. Callsigns: pool-drawn at captain creation now (in this design), or hold callsigns until a deed-earned system exists (first kill, a ram kill, surviving under 10 percent hull)? The display work is identical either way; only the source differs.
3. MVP values damage taken at a quarter weight. If MVP should be purely offensive, the taken term drops; the formula is printed either way.
4. Portrait count: captains need their own painted faces in the admiral style (Qwen's biggest risk is asset volume: about 20 to 30 faces so a long run never repeats). That is an art pipeline ask riding on this pack; the UI works with a silhouette placeholder where a face is missing, but the placeholder will read cheap next to the painted admirals.

## Council record

- Blind Rey: three-zone split with the market row shrunk; glyph plus icon plate with sentences on hover; bottom-left banner; report with salvage after the table; objection: the plate brief's two asks fight at camera 170.
- DeepSeek: three columns with exact geometry; PreviewOp as one function for preview and commit; plate with short system labels and a rail fallback; top-center banner with safe-slot search; objection: full loss text on every plate at 170 is too much text (adopted by the chair as the two-tier plate).
- Qwen: bay left with a bottom roster strip; plate rows with LOST text expanding in place; top-right banner; cosmetic callsign pools, mechanical traits (its trait modifiers cut by the chair, its own least-sure); objection: the brief needs a fifth deliverable, a combat event schema, sequenced first (adopted as step 0).
- Gemini on Hydrogen: three zones with an inspector column; segmented hull bar plate with spring de-confliction and hysteresis; top-left banner with event accent colors and coalescing; MVP spotlight strip and proportional damage bars; objection: screens 3 and 4 are data plumbing before they are UI (adopted into step 0).
- Grok: seat empty, bot wall, nothing submitted (legs/leg_grok.md).
