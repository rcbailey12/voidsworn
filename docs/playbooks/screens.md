# Playbook: screens

Issue 405. Written by the Board (Fable 5.2), Nov 11 2026. Format: docs/playbooks/PROGRAM.md. Use this to design or rebuild one
screen. The worked example is the campaign map's Briefing layout.

## 1. Target

- Ryan, Nov 10, on the first Lime Tactical map: "it's getting pretty busy and it also reads as AI generated still, rather than
  a clear and consistent human designer." His pick from three options: "Briefing is it but I want that merged with the
  graphical quality of the original map, minus clutter and noise of it."
- What he named as the tells of a machine-made screen: too many colours and glows, everything in a box or tag, uneven type and
  spacing. The cure is restraint and one system.

## 2. The system (what every screen shares): the orders sheet

Lime Tactical is retired (R191). Every screen moves to the orders sheet, the look Ryan passed on the campaign map's rail
(R176, contrib/opus/briefs/campaign_rail_orders_sheet.md) and picked again for the battle screen (E1 LEDGER, R210). The
battle screen (godot/ui/battle/ledger.gd) is the second screen built in it; build the next ones from this section.

- **One accent, the ember (#ff8a3a, glass_shell.gd MAP_EMBER).** It marks the next action and what it acts on: the action
  box, the odds, "Your turn", the ship that is up (its name on the board and its ring), the hovered hex. Nothing else is
  orange. NEM (#ff6050) is the Nemesis only. **Glacier (#92b8e8, GLACIER) is shield readouts only** (R210); the shields drawn
  around ships in space keep their faction colours. A damaged hull figure takes the game's damage colour (HULL_LOW).
- **Three text strengths**: TEXT for what the player must read, TEXT2 for supporting sentences, TEXT3 for joining words only
  ("Hull", "Target", "Heat", "Dossier"), never a sentence.
- **Three faces, one job each**: Big Shoulders Display for names in capitals (never under 28 px at 1080, never a sentence),
  Barlow for every sentence and joining word, Azeret Mono for figures and keys.
- **No panels.** Words sit on a smooth darkening of the scene (about 94% black, full strength under the words, fading to
  nothing), never on a filled rectangle with an edge. Square corners. No pills, key badges, glows or shadows.
- **One box per screen**: the action, a 2 px square ember outline 56 px tall with its key on the right, filled ember under the
  pointer. Dialogs (the menu, the end card) and hover tips are near-black squares with a hairline edge.
- **Width follows the decision (R218).** Sheet and panel widths are set by the decision the screen holds, not by how much
  data exists, and the scene keeps most of the screen. When Ryan rules a width on one screen, it is written here as the rule
  for every sheet. Ryan, Nov 11 2026: "the side left panel takes up a ton of the screen. It's like 30-40% of the screen and
  blocking a lot that's going on."
- **Keys after words**, in the figure face and the second strength: "Brace B", "End ship Space". No key caps.
- **Say less (R177).** Only what the screen's decision needs is on it; the rest is one hover or one key away, and the pull
  request lists every moved item and how it is reached. Nothing is deleted from the game.
- **Readability, checked by a test**: nothing under 17 px at 1080, three strengths, 4.5 to 1 over the brightest and darkest
  board, no overlaps at any fleet size or name length (the battle screen's check, godot/ui/battle/test/ledger_readability_test.gd,
  composites the screen's own darkening over pure white and black, so a pass holds over any backdrop).
- **One small type scale per screen** (issue 644, all at 1080): campaign pages 17 small, 18 body, 19 to 20 card titles and
  sub-heads, 24 and up for heads; Career 17 detail, 18 to 19 names, 34 and 40 figures and title; title screen 17 body, 18 to 19
  menu, 24 and 84; battle HUD 17 keys, 18 tips and log, 19 buttons, 21 and up for heads; the shared theme's own defaults 17.
  A new size goes onto its screen's scale, never between two steps. Where 17 does not fit, the words get shorter or move to a
  hover; they are never squeezed.
- **Board colours follow**: no lime on the 3D board either (the ring under the ship that is up and the hovered hex are ember);
  the threat map and the reach hatching are bone (TEXT), because red is the Nemesis alarm's and purple is on Ryan's list.
- **The start screens use the orders kit (godot/ui/theme/orders_kit.gd, issue 1217, RULEBOOK 9.15 and 2.17).** Title,
  Settings, Credits, the faction and admiral desk, the flagship aspect, Progression, Lineage and Help take their fonts,
  buttons (Kit.button: primary, quiet, back; Kit.link), labels (Kit.label, Kit.wrap_safe: a label never widens its
  container; Kit.fit_words: a name in a narrow tile shrinks a step instead of breaking mid-word), side drawers (Kit.drawer), rows (Kit.row: one control column of one width), section heads, cards (Kit.card plus Kit.equal_heights) and the
  action bar (Back left, primary right) from it, and every kit button plays the ui_* cues through main.gd's front-end sound
  node (Kit.sound). A fix to any of these goes into the kit, never into one screen. Esc goes Back on every start page
  (campaign_ui.gd ESC_BACK). The UI scale is never capped; each layout fits 831 design pixels tall. Progression, Lineage and How to play sit in the
  desk's frame (campaign_ui.gd _kit_page: ledger veil, one centred column, a fixed bar with Back) and their card rows are
  kit grids (Kit.card_grid: one width, one height per row, actions at the foot); tab strips use Kit.tab_button. Checked by
  godot/ui/test/front_end_test.gd; pictures by godot/ui/test/front_end_shots.gd (--only=F5 keeps one group, --expect=WxH
  fails a frame of the wrong size: Godot hides --resolution from the script); contact sheets by
  godot/tools/front_end_sheet.gd; on the PC, tools/pc/jobs/frontend_ui_check.bat runs all three at 1080p and 4K. An open
  drawer on a page (Run options) holds keyboard and controller focus (campaign_ui.gd _trap_focus) and closing it gives the
  focus back to the button that opened it (issue 1261).
- Palette and faces come from godot/ui/theme/glass_shell.gd (MAP_EMBER, TEXT, TEXT2, TEXT3, NEM, GLACIER, sheet_name,
  sheet_body, sheet_medium, num). A screen adds what is missing to the theme, never loose numbers of its own.

### The battle screen (KEEL, issue 1021)

Use `contrib/muse/design/battle_hud_split_2026_11/mockups/keel_v5.png` as the layout reference. Turn and objective sit at
top left, fleet and Heat, Nemesis, and Menu at top right. The board is sharp and centred. The 248 px bottom shelf at 1080p
reads left to right: ship, one shield pool and one hull bar, weapon checklist, target and damage in words, then the main
action and orders. The fleet strip shows names, hull and shield bars, and each ship's own silhouette. It pages in a narrow
window or when the whole fleet cannot fit. The floating log above the shelf is about half as dark as the shelf. It starts
with three lines; click Log to show only the latest, or switch it off in Menu > Controls. The L key opens the full history.
Shortcut labels stay off the shelf. Read the ship asset code from the same ShipView that draws the board. Rebuild icons from
the reviewed GLBs with `godot/ui/battle/icons/make_silhouettes.gd` when the installed ship set changes.

What moved behind a hover or a key (all still reachable):

| Was on the screen | Now |
|---|---|
| captain, armour, evasion, turns, sections, perks, the key list | hover the ship's name |
| a gun's damage, cost, reload, arc words | hover the gun; click it or press its number to arm it alone |
| the target's hull, shield pool and side coverage | hover the target's name |
| the Nemesis block (aboard, flees when, adaptations, weakness) | hover the Nemesis line |
| Heat gauge | "Heat 3"; hover for the rules behind it |
| the unacted set, who the enemy can reach first | the count in the top line; hover it |
| fleet status, exact health, NEW and danger | hover a fleet slot (click picks the ship) |
| orders that cannot be given now | muted, with cooldown shown where it applies; Ram and Board appear when available |
| the step hints (Move, Fire, End) | one short sentence; the full hint on the action's hover |
| Cancel button | Esc |
| speed, threat map, top-down, grid buttons | Esc menu (and R, T, Z keys) |
| the key line along the bottom | Menu > Controls, and the ship name's hover |
| nameplates with bars on every ship | hover a ship |
| the old log | three lines or a one-line ticker above the shelf; L opens the full history |
| the status line's state words | hover the status line for their definitions |

### The after-run screen (DB1, issue 805)

Ryan picked DB1, The Ledger Page (R260 and R261). Build from
contrib/muse/design/ui_upgrade_2026_11/debrief/DB1.png and notes.md. The decision is to confirm the heir, then choose the
next run. Keep its figures, timeline, meters, painted admiral, three heir crests and live flagship portrait in one page at
1920x1080. The five headline figures read the paid run's battle, flagship, kill, loss and time data; a run with no recorded
time has four. The timeline reads this run's battle_end events, partitioned by sector, with a ring for a won flagship battle
and a loss mark for a battle with losses. Its hover gives the counts. Older logs without a sequence say so; never invent
the order from aggregate totals.

The only ember box is Confirm heir. The current heir is selected when eligible, with a visible CURRENT HEIR label; selecting
a different crest is local until confirmation. Confirm once, then the box becomes Play as the suggested faction (or Pick
the next faction). Pick a faction and Title screen stay inert until confirmation. Opening doctrine, hull rewards or the
lineage tree carries a Back to ledger route, including after a purchase, so those screens cannot bypass the heir decision.
The capture of a lost flagship uses the last real ship dictionary retained by the UI while the run was active. Label it LOST;
if no ship record exists, show the true empty fleet state. The small viewport uses render/ship_view.gd and the installed hull
selected from the actual flagship's template. Missing installed hulls show an explicit unavailable state, never concept art
or a placeholder block. Do not add generated ship art or heir paintings.

The scale is 17 detail and keys, 18 links, 20 supporting figures, 23 verdict, 28 to 30 names, 32 detail heads, 52 to 60 headline figures,
84 result title, all at 1080. Use the three orders-sheet faces and strengths. The page-wide smooth veil is at least 94%
black beneath every word; the primary hover uses ON_EMBER. Portrait and crest colours are art, not extra interface accents.
Long names wrap; the flagship name has the foot strip's full name line. Extra fleet entries and captain names stay in the
full roster rather than increasing the main page height.

Every moved item and its route:

| Item | Route from DB1 |
|---|---|
| Arc line, victory count, factions already won | headline hover; The record R |
| Original next-run teaching card, first-loss paragraph, story payoff, best sector, eaten core | The record R; the first-loss kicker remains on the page |
| Renown breakdown, Heat multiplier, zero earnings, affordable reward list and extra rewards within reach | earned figure and vault hover; full receipt B |
| Spend renown | P, or the words beside the meter; opens actual doctrine spending |
| View hull rewards | V, or the words beside the meter; opens actual hull rewards |
| Locked admiral rewards and unlocking them | receipt B, View admirals; purchases return to the ledger |
| Admiral XP gain, exact progress, cap, recorded skills, earned perks and pending choices | portrait hover; admiral line A, with the existing tree action |
| Shadow gains and levels, total XP, next threshold and double-rate status | each heir crest hover; admiral line A |
| Overflow XP, banked shadow XP and Heat XP | admiral line A |
| Core protocol counts, next sync tier and every crossed-tier sentence | Core sync S, with meters |
| Nemesis lessons, adaptations, raids, deaths, and no-meeting/no-weakness cases | Nemesis lesson L |
| Current heir, candidate ranks, standing shadow XP, keep current and confirm | crest cards; current heir preselected; Confirm heir Enter |
| Exact standout sentence, complete surviving roster, captain ranks and ship figures | flagship-name and picture hovers; full fleet F |
| Captains lost | foot strip, loss-figure hover, and full fleet F |
| Next faction description | next-faction name hover |
| Next run, Pick a faction, Title screen | one action box and exit words, gated by heir confirmation |

R was drawn twice in DB1. The record keeps R; Spend renown uses P. B opens the full receipt, A the admiral details, and F the
fleet. Esc closes a detail view. Keys 1 to 3 select an heir; Enter confirms once, then advances. The browser template and the
campaign payout, progression and save functions stay unchanged.

Check: godot --headless --path godot --script res://ui/campaign/test/debrief_ledger_test.gd. It builds the real UI, tests
read-only drawing, moved-content routes, progression returns and heir gates, and measures glyph bounds and contrast at
1080 and 1440 across all factions, the long flagship name and a 20-ship fleet. The optional --shots DIR arguments capture
the same scenarios with a renderer. Keep 1920x1080 originals in the issue's shots folder and comparison sheets at no taller
than 720 px in docs/shots/debrief_db1/. Stage the installed model cache before captures; a missing model fails the capture.

### Between-fight cards (issue 1177, R335)

The victory card lists the wrecks and lets the player work one directly. If there are captured ships, deal with the batch
of prizes before selecting a wreck so prize decisions get first claim on command points. Put all captains with a pending
perk on one promotions card and keep it open until their picks are made. A reload restores the current reward stage.

Drydock and field repair cards show the fleet hull and credit gain for both choices before applying either. The full
service keeps the previous free repair rate. The lighter service adds a credit stipend. If the Nemesis holds a shipyard,
drydock, field repair or event, the route says “You fight him here, then use the stop.” Winning opens that stop after the
battle rewards. See [the seeded check and picture list](../shots/after_win_1177/README.md).

### Late market and faction purses (issue 1178, R335)

Sector 3 shipyards add a Late market: two relics (picked from the run's useful, unowned relics without touching the random
stream; never the Smuggler's ledger, the logbook or the Scrap rig, which cannot earn back 120 that late, LATE_SHOP.skip, issue 1290) and one Command expansion (+1 command point, at most two a run), all paid in credits. Paid repair prices never
change (Oct 29 ruling). Three factions show their own money on the shipyard, the map purse and the victory card:

- Chorus: hull work (repairs, new hulls, Marks) is paid in biomass, earned flat per win like credits plus 8 per kill, at
  most 50 a battle (BIO_KILL in core.js). Refits, class refits, protocol rerolls and the late market take biomass when it covers the price, otherwise credits (R382, issue 1484: a Chorus run still collects credits from repair stipends, ransoms, scrap and declined protocols, so both purses spend). Credits alone pay for events. Every price button names the purse that will pay, and decommissioning pays biomass too (issue 1290).
- Glasswrights: a win refunds cullet credits for the fleet's own lost hulls by class (25, 45, 70, 85, 100, about 25% of
  the price and still under the 35% decommission value), at most 100 a battle (issue 1290).
- Eclipse: a win recovers the core of the most valuable ship lost; a shipyard regrows it at Mk I for 20% of its value. A regrown ship
  decommissions for 0 until it has fought a battle (issue 1290), and after that for at most what its regrow cost, so regrow,
  fight once, sell is not free money either (issue 1384).

Check: godot --headless --path godot --script res://campaign/test/late_run_shots.gd builds all four pages; with a display
and an output folder it saves L1178, B1178, E1178 and C1178.
res://campaign/test/late_fixes_1290.gd checks the issue 1290 rules and saves D1290 and B1290 (the two decommission dialogs). Numbers and pictures: [the late run README](../shots/late_run_1178/README.md).

### Career (CR4, issue 869)

Ryan settled CR4, The Honours Board (R286). Its source notes and CR4.png are on the design branch muse/issue-794 at
609262f9, under contrib/muse/design/ui_upgrade_2026_11/career/. Review pictures live in docs/shots/ui/career_cr4/.
Recognition is the page's job: seven lifetime figures without boxes, served admirals first, then the unserved roster.
Every served admiral has a picture band and six labelled figures: runs, won, best sector, battles, kills and ships lost.
Vex uses his chosen portrait; other bands carry the recorded flagship name in display type until flagship art exists.
All earned titles and counts, arc honours and flagship names stay on the surface. The unserved Sunward admirals use the
same crests as the debrief's heirs. Other unserved admirals remain text, with their doctrine under their full name.

The hero grid has three columns and grows by rows. A fourth served admiral starts the next row. The original 12-admiral
reference profile fits on one page; the current six-faction, 24-admiral roster and longer careers scroll below the fixed
heading, word tabs and lifetime band. No admiral or faction is dropped. Tabs use 1 to 5 and a neutral active underline;
Close is the one ember box, with Esc on the right. The other four tabs retain their existing content and actions in the
same neutral orders-sheet frame. The scale is 17 detail and keys, 18 links and unserved names, 28 section heads and honours,
34 admiral and flagship names and service figures, 40 lifetime figures, 52 page title, all at 1080.

Check: godot --headless --path godot --script res://ui/career/test/career_honours_test.gd, plus career_readability_test.gd
and story/test/story_test.gd. The new check opens through Story, browses all five tabs, verifies figures against the saved
record, checks the fourth row and the full roster, measures bounds at 1080, 1440 and 2160, and proves browsing leaves the
profile, campaign run and meta unchanged without writing a save. For GPU captures, omit --headless and add -- --shots DIR.
Capture the original 12-admiral reference, current roster, fourth row, long names, empty state, tabs and Close hover. Rules
and save data are unchanged.

## 3. Steps

1. **Name the decision.** One sentence: what does the player decide on this screen? Everything is ranked by how much it
   helps that decision.
2. **Options.** Two or three flat mockups at 1920 by 1080 that differ on real choices (where the list sits, how much is in
   boxes, how many colours), with the same real content in each. The Board makes these on a Design canvas; the generator for
   the map's three is contrib/opus/ui_map_design/mockup_gen.py.
3. **Pick.** Ryan picks, or mixes. Ask what to keep from the present screen before building.
4. **Brief.** One file in contrib/opus/briefs/: his words, the layout with sizes, what stays, what leaves and where it goes,
   the done test. docs/archive/briefs/campaign_map_briefing.md is the pattern.
5. **Build** in the game from the brief, theme first.
6. **Capture** on the PC at 1080 and 1440: the plain state, a busy state, each overlay, a hover, and a damaged or edge case.
   Look at them at full size against the mockup: alignment to the grid, no overlaps, the ember only where it should be.
7. **One image to Ryan**: the new screen beside the old one.

## 4. The checks that prove it

- contrib/opus/tools/ui_spec_tests.js and the standing checks pass; the screen's own read-only test passes (opening a screen
  never changes the run or the save: test the property, not the spelling of a call).
- The "Godot game checks" job loads every script and scene and plays a bot battle.
- Captures exist for every state in step 6, from the final commit.
- The pull request lists every moved item and where it lives, and carries the impact sweep (callers, saves, twins, every UI
  path, which tests ran).

## 5. Traps

- A screen that only reads up close. Ryan, on the map's first in-game capture: "It's hard to read all the stops after the
  first. I'm okay with no text but it's hard to even see the icons right now." Quiet does not mean invisible: dimmed things
  still need an icon that reads (R170).
- A screen that never changes. Same capture: "There's no change when you're going to a new system or getting closer in round
  2 or 3 to the star?" A screen the player sees many times must show where they are in the run (issue 420).
- Cut-off sentences with dots. Give text its room or write it shorter.
- "Only reads" claims that are not true: a draw call that creates a record (Muse's check of PR 349). Use the read-only
  lookups (C.nemRead).
- Captures that are staged but never committed: the picture Ryan judged must be in docs/shots/ from the final commit.

## 6. Worked examples

The battle screen: three layouts captured over the real battle (issue 271 step 1, contrib/opus/reviews/battle_screen_ember_options.md),
Ryan's pick E1 (R210), the build (step 2, contrib/opus/reviews/battle_screen_ember_build.md, pictures in
docs/shots/ui_battle_ember/build/).

The campaign map: three options (contrib/opus/ui_map_design/), the brief (docs/archive/briefs/campaign_map_briefing.md), the
build on opus/issue-344 (pull request 349), the finish (issue 418) and round 3 (issue 420: the approach to the star across
three sectors, and stops ahead readable by icon).

## 7. Job template (one screen from a brief)

```
Owner: codex (or an Opus helper at medium effort while Codex is busy)
Brief: contrib/opus/briefs/SCREEN.md; docs/playbooks/screens.md; contrib/opus/briefs/ui_style.md and ui_spec.md
Deliver to: godot/ui/SCREEN/, godot/ui/theme/ (only what the theme lacks), docs/shots/ui_redesign/SCREEN/
Branch: codex/issue-<number>
Effort (Codex): high
Done when: the checks pass with a read-only test for the screen; captures at 1080 and 1440 of every state the brief lists are committed from the final commit; the report lists every moved item and where it lives. What Ryan will see: the new screen beside the old one.
```

One screen is one or two build runs and one or two capture runs, plus one Ryan look.

## 8. Open question for Ryan

Settled: the battle HUD takes the orders sheet (R210, E1 LEDGER). Open: the enemy's violet markers and the acting enemy's
lavender ring on the 3D board, and the mint ring under your other ships, are board colours this rollout did not change.

## 9. Seat

The Board designs the options, writes the brief and judges the captures. Codex or an Opus helper builds. DeepSeek does the
well-specified follow-ups (a string, a test, a moved fact). Muse checks from outside before or straight after the merge.
