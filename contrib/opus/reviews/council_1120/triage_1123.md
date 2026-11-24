# Council audit issues 1401 to 1407: triage on main 9afbc41d (Nov 23 2026)

Worker thread "Triage the Council audit issues". Each ranked item from `draft_ranked_list.md` (final at c242e442) was
checked against main 9afbc41d, the open PRs and the Nov 23 Neon audit and its Fable and Astra synthesis
(`/mnt/project-files/board/neon_1123/synthesis_1123.md`). Not a ruling. Godot only (R405): no item here touches the frozen
browser files. Below-the-line rows were not re-checked one by one.

Status words: **Fixed** (on main or on branch opus/issue-1401), **Partly** (what is left is named), **Open**, **Owned** (another
open issue or PR already carries it: fold it there, do not run it twice), **Ryan** (taste or a reopened ruling: Pick Sheet).

## 1401 Battle HUD words and buttons

| # | Status | What main shows now | Next |
|---|---|---|---|
| 1 | Partly | Plan-then-commit (RULEBOOK 9.17a) and PRs 1759, 1846 rewrote the flow: the target hover now says "Out of reach from here. Planned: burn N movement to the ghost and fire N weapons". The "No ready gun can reach it." toast still exists for a click with no attack move | One recapture of the old still 03 case; close if it reads once |
| 7 | Fixed | "ghost" is now the taught word (9.17a, the plan card explains it), so it stays. "now 0" and the flak "Out" are fixed on opus/issue-1401 | |
| 8 | Partly | The log line still trims before the damage number, but hovering it shows the whole line and L opens the history | Wrap the newest entry to two lines (slice B) |
| 13 | Partly | Order cells still follow list order (ledger.gd `_orders`). "Reload torpedoes" shows as "Reload" on opus/issue-1401 | Fixed slots for End ship and Next ship (slice B) |
| 14 | Open | hud.gd still puts the notice at s(96) through the banner at s(72) | One message slot (slice B, after PR 1445, which edits hud.gd) |
| 24 | Partly | The "red ring" hint now shows only when such a target exists. The nebula swatch is still violet (#b07cff, line_style.gd edge_neb, board.gd ZONE_TINT) against a rose board | Key name and swatch colour (slice B); check the colour against World Sky V2 (1766) first |
| 29 | Fixed | opus/issue-1401: "Blocked by the marked asteroid" (count and kind, no hex numbers); hovering a blocked hex says "Blocked by the asteroid on this hex." | |
| 33 | Partly | The Bulwark Frame sentence is finished on opus/issue-1401. The other untaught words (cores, "pool, side, catches", Braced vs Fired) are open | Fold into Wave 3 first-run friction (Neon G10) |

## 1402 End, reward and loot cards

| # | Status | What main shows now | Next |
|---|---|---|---|
| 2 | Open | battle.gd `_end_flow` body is still counts only | Cause line on the end card, after PR 1809 (end card and Esc) merges |
| 12 | Open | Reward dialogs still use `shell_panel` (campaign_ui.gd:2330) | Look change: mock-up to Ryan before building; after PRs 1810 and 1811 (campaign_ui.gd) |
| 19 | Open | Victory card prints "Lost: the ship and Captain" (campaign_ui.gd ~2408) while campaign.gd ~3981 sends the captain to the reserve 60% of the time | Truthful line now; whether the lifepod stays is Ryan's |
| 20 | Owned | Three "Scrap it" buttons still (campaign_ui.gd:2525) | Neon D5 loot text (Wave 2): same finding, Neon section 7 |
| 21 | Owned | Stripped refits still drop to the hold with one toast | Neon D5 quick-fit (Wave 2) |
| 30 | Owned | Nothing priced on the card | D5 or D7, one lever at a time |
| 39 | Open | "long-range penalty" still in the promotion text (both table files) | Small words job with 19 |

## 1403 First battles teach turns and goals

| # | Status | What main shows now | Next |
|---|---|---|---|
| 10 | Open | TIPS card 1 unchanged, still ends "Glasswright ships cannot Brace." | Fold into Wave 3 first-run friction (Neon section 10 says the same) |
| 16 | Ryan | Battle 1 layout unchanged | Pick Sheet |
| 18 | Open | "Taking turns" is still retired by End ship before it ever shows (battle.gd `_tip_retire("fired", "end_ship")`) | Small bug job |
| 23 | Partly | PR 1561 put the Navy Relay model on the hold hex. No label, key row or hover rule yet | Same job as 18 |
| 25 | Owned | map_intel.gd pips unchanged | Issue 1857 (D2 curve) owns map_intel.gd and makes the map read the real budget; price the reinforcements in its follow-up, not before |

## 1404 Cut-ins and the enemy turn

| # | Status | What main shows now | Next |
|---|---|---|---|
| 3 | Partly | Issue 1559 items 12 and 19: the sheet, log, legend, hover tip and tip card now leave the cut-in. Grid, rings and labels still sit on the ship | Fade board lines in cut-ins through line_style.gd, after PR 1445 (edits line_style.gd and board.gd) |
| 5 | Open | camera_rig.gd margin still ignores the shelf and the Log; no off-screen markers | Camera job after PR 1809 (edits camera_rig.gd) |
| 11 | Open | Same cause as 5 | Same job as 5 |
| 15 | Owned | `_cine_wants` still returns true for every lance, torpedo and nova | Issue 1871 (D3 opt-in brisk camera). R430 keeps today's default, so changing the default is Ryan's |
| 31 | Open | Enemy-turn card still shows my spent ship | Same job as 5 |
| 41 | Open | Cause still unknown | Clean frame first, then fix |

## 1405 Load screens, title and first launch

| # | Status | What main shows now | Next |
|---|---|---|---|
| 4 | Ryan | Title camera clamp unchanged | Two mock-ups for the Pick Sheet |
| 9 | Open | load_screen.gd is still one plain label, no theme font | After PR 1445 (changes the battle cover) |
| 26 | Open | project.godot has no icon or boot splash; export icon empty | Which crest is the game icon is Ryan's; the splash colour is not |
| 32 | Owned | | Issue 1434, PR 1445 (title backdrop load) |
| 34 | Owned | | Issue 1434, PR 1445 (battle load) |
| 35 | Open | Admiral cards unchanged | After PRs 1810 and 1811 |

## 1406 Ships read at the battle camera

| # | Status | What main shows now | Next |
|---|---|---|---|
| 6 | Owned | Fleet lighting (1679, PRs 1704 and 1863) and Chorus recess glow (1683) merged; Ship Exteriors V2 (PR 1786) waits on R431 | Re-check at camera 170 after 1786 lands, then close or re-scope |
| 22 | Owned | | PR 1782 (1361 Asteroids V2): its review should test the Council lines (no rock lighter than the lightest hull at c170; rocks fade in cut-ins) |
| 28 | Ryan | Seven faces still | Pick Sheet |
| 37 | Open | Flagship pick lighting unchanged | Picture options for Ryan |
| 38 | Owned | | Issue 1766 (World Sky V2: no purple or mustard); the Chorus hard edge is a bug to check there |

## 1407 Rival voice and memory lines

| # | Status | What main shows now | Next |
|---|---|---|---|
| 27 | Likely fixed | battle_voice.gd `opening()` has one Nemesis hail path (rival.gd `opening`); the old data.js voice is retired (R405) | One Nemesis battle log to confirm, then close |
| 40 | Ryan | rival.gd still needs beaten or scars before memory lines play | Reopen of R85: Ryan's call, low priority |

## Proposed order (each its own opus/ branch, one run each unless said)

1. **1401 slice A** (branch opus/issue-1401): items 7, 13 (label), 29, 33 (Bulwark). Words only, no rules change.
2. **1402 truth lines** after PRs 1809, 1810, 1811 merge: 2 (end card cause line), 19 (lifepod line), 39 (perk words).
3. **1403 small fixes** after PR 1445: 18 (Taking turns card), 23 (relay label, key row, hover).
4. **1401 slice B** after PR 1445: 14, 8, 13 (fixed slots), 24 (key name and colour).
5. **1404 camera** after PR 1809: 5, 11, 31. One to two runs, pictures to Ryan before merge.
6. **1404 cut-in board fade** (3) after PR 1445, then 41 after a clean frame.

Folded elsewhere: 20, 21, 30 to the Wave 2 D5 job; 25 to 1857's follow-up; 15 to 1871; 32 and 34 to 1445; 22 to 1782;
38 to 1766; 6 re-check after 1786; 10 and the rest of 33 to Wave 3 first-run friction.

For the Pick Sheet (pictures first): 4 title picture, 16 Battle 1 distance, 19 does the lifepod stay, 26 which crest is the
icon, 28 typefaces, 37 flagship pick look, 40 sector hunter returns, 12 reward card look.
