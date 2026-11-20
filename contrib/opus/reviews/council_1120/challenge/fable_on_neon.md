# Challenge round: Fable on Neon's blind whole-game leg

Neon's leg: issue 1387, branch neon/issue-1387, report file at commit fb893f7d (15 findings, 5 fun, 5 not fun).
Checked against: the code on claude/project-thread-8hcjwy at 89bf7e17 (the game and council base Neon reviewed), live main at 69955313 (Nov 20, after R366), the pack
pictures (opened, not trusted from the text), docs/RULEBOOK.md, contrib/opus/FINDINGS.md up to R366 on main, the rename map,
and the open issue list on GitHub. Two things were run in headless Godot 4.7.2, not only read: the battle menu at three UI
scales, and the battle shelf at Larger. Findings only; nothing but this file was written.

## Answer first

Neon's leg is mostly right. 12 of the 15 findings stand, 2 are wrong in their headline, 1 is true but not felt.
Of the 5 not-fun items, 4 stand and 1 is already ruled and ticketed. Inside the standing findings, 11 smaller claims fall
(listed under each). Nine of Neon's findings match a Fable finding made blind; that agreement is the strongest evidence in
the audit. Four findings are Neon's alone and hold up: the battle menu overflow (4), the wrong How to play text (5), the
danger pips that leave out reinforcements (7), and the F8 key (14).

| Verdict | Top 15 | Not fun 5 |
|---|---:|---:|
| Stands | 12 | 4 |
| Wrong | 2 (10, 14) | 0 |
| Not felt | 1 (15) | 0 |
| Already fixed or planned | 0 | 1 (item 4) |
| Ruled | 0 whole, 2 parts (arcs gate, Grax name) | 0 |
| Bad fix | 0 whole, 4 parts (camera pull back, flak label, Grax rename, rock size) | 0 |

## The three strongest knockdowns

1. **"Warlord Grax Ironmaw" is not a leak. It is the ruled name (finding 10).** Neon cites rename_map_final.md:288, which
   maps Ironjaw to Steelgrin. The same file overrules that row further down: line 518, "`n:'Warlord Grax Steelgrin'` to
   `n:'Warlord Grax Ironmaw'` ... Ruling 1: Steelgrin is a Warhammer Fantasy surname", and line 583, "Warlord Grax Ironmaw
   (was Steelgrin; Ryan, Oct 27, section 16)". Neon's own proof-of-reading table says it read lines 1 to 331 and 607 only.
   Neon's fix would put a Warhammer name back into data.js and both table exports, against RULEBOOK 11.2. Ruled, and a
   bad fix.
2. **The D3D12 setting is not "disabled" (finding 14).** `application/export_d3d12=0` (export_presets.cfg:44) is the first
   value of Godot's list "Automatic, Always, Never". 0 is Automatic, not off. Fable's Godot leg read the same line as
   "left on automatic" (Astra question 4). What is left is an open question, not a defect: does the Vulkan to D3D12
   fallback start on a PC that needs it. That is already on the Astra list. Same finding: the "console wrapper" value 2
   ships one extra file (Voidsworn.console.exe) beside the game and opens no console on the game itself, so no player
   feels it.
3. **The story arcs are gated by a ruling, not "unshipped dead code" (finding 10).** `var arcs_on := false`
   (campaign.gd:44), godot/story/README.md:118 to 125 ("the arc files are written once Ryan approves the text ... Until
   then the arcs do not appear"), RULEBOOK 11.4 (story text passes Ryan's final read per faction). Neon's own fix line
   says "after Ryan approves outlines.md", which is the plan already. Fable lore 11 read the same code and called it "the
   11.4 gate and not a bug", then went further: the outline text no longer fits R85 (a new hunter each sector), so
   switching it on as written would be wrong. That is the real finding and Neon missed it.

Also knocked: the placeholder mastery text does not reach the screen (campaign_ui.gd:2220 returns an empty string for
any text that starts "Placeholder:"); the scanned rock export check Neon asks the Board to verify was merged at 18:32 UTC
(PR 1364, on main); the mid-battle warm-up hitch is argued from spawns that make no new ship (below, 15).

## The 15 findings

### 1. Enemy leaves the view, Log covers enemy ships, tan rocks bury hulls: **Stands**

- Checked. `OPEN_HOLD := 1.75` is at battle.gd:678 and `cam.glide(_pos(sel), 1.4, cam.home_r)` at :738, as quoted. Line
  5036 is the on-screen test for name plates. A search of every .gd file for edge or off-screen markers finds none.
- Pictures agree. `battle_01`: no enemy ship in frame on the player's first turn. All four `05` stills (battle, ithar,
  deathless, chorus): the enemy ships sit under the Log box and the shelf. `seed10_t025` and `t027`: tan rock piles are
  the brightest and largest things on the board.
- Agreement: Fable art 2 (asteroids brightest and on top of ships), art 17 (enemy fleet first appears under the Log),
  first-time player not fun 5 (camera leaves the action off the edge) and 6. Four blind seats, one problem.
- Corrections. (a) RULEBOOK 10.8 has two halves. "A battle opens with both fleets in view" is met for 1.75 seconds
  (the opening frame fits every ship, battle.gd:725). The half that is missing is "markers at the screen edge only where
  a ship can leave the view". (b) The camera does not zoom in: it glides to your ship at the same distance (`cam.home_r`),
  which is what pushes the enemy off the edge.
- Bad fix, two parts. "Pull `cam.home_r` slightly back" makes ships smaller, and Fable art 1 already has ships as the
  smallest thing in the picture. Better: after the opening, rest the camera between the two fleets, or keep the glide
  and add the edge markers 10.8 already asks for. "Cap asteroid cluster footprint" meets R359 (Ryan, Nov 20: asteroids
  option A, "shapes kept", issue 1361 does colour and tone) and R361 (rock hexes get a grounded rim, PR 1367). Tone is
  already planned in 1361. Size can only come back as "reopen: Ryan's call", and RULEBOOK 10.2 (rocks never loom over
  the fleet) is the argument for it.

### 2. Burn and Fire against "No ready gun can reach it", "the ghost", "now 0", flak "Out": **Stands** (one part is a bad fix)

- Checked. battle.gd:5306 uses the stand-still reason whenever no move is planned, and never looks at `atk`. :4041 holds
  "burn %d movement to the ghost". :3897 holds "can reach this hex ... now %d". `seed10_t008` shows all of it in one
  frame: BURN AND FIRE, "No ready gun can reach it.", "to the ghost", gun rows "Out", and the log cut at "18 to prow shie...".
- Agreement: Fable UI/UX 2 (same line, 5306, same cause) and 15, first-time player confusing 2, 4 and 5.
- Bad fix on the flak label. Neon says to test `why == "point defence"` in ledger.gd:507. No such value ever reaches the
  shelf. The shelf rows are built in battle.gd:4700 to 4745, where a flak gun gets "wings only" (in range and arc) or
  "out of range". "point defence" exists only in the hover box (battle.gd:4014), which is why `seed10_t008` shows
  "Spark flak: point defence" in the hover and "Out" on the shelf. Better: key the shelf label off the gun kind
  (`gun.kind == "flak"`), the same test the hover uses.

### 3. Hover boxes stay up in cut-ins, grid and rings stay on: **Stands**

- Checked. hud.gd:1264 fades only `[ledger, log_panel, legend]`; hud.gd:1392 keeps placing the tip. `_cine_frame`
  (battle.gd:1941 to 1959) hides nothing on the board. `seed10_t010` and `t035`: the target hover box sits in the middle
  of the letterboxed shot. `t021`: full bright grid, both rings, in a cut-in.
- Agreement: Fable UI/UX 4, first-time player not fun 4, art 4 and 5. RULEBOOK 10.1 (a faint grid only near the active
  ship) backs it.
- Note for the fix: live main now draws every board line through render/line_style.gd (R362, issue 1374). Hide the
  board lines there for a cut-in, not per mesh in battle.gd.

### 4. The battle menu overflows at Large and Larger: **Stands**, and now measured

- Neon inferred this from arithmetic. I ran it: a headless battle at 1920 by 1080, `_open_menu()`, then read the menu's
  rectangle at each UI scale.

| UI scale | Menu top | Menu bottom | Rows | What is off screen |
|---|---:|---:|---:|---|
| Normal 1.0 | 56 | 1023 | 19 | nothing |
| Large 1.15 | -17 | 1097 | 19 | the box edges and part of the MENU title; every row is still on screen (Resume at 67, Quit the game ends at 1072) |
| Larger 1.3 | -91 | 1171 | 19 | the title, and "Quit the game" entirely (the row ends at 1142); "Copy a problem report" is cut at the bottom |

- Corrections. At Large no button is lost; Neon said Resume or Quit would be. At Larger, Resume is still visible; only
  the last row or two go. The keyboard still reaches them. In a campaign battle the menu has 18 rows (no "Quit to
  title", battle.gd:4312), so the last row is half visible at Larger. The battle shelf itself fits at Larger: 19 hit
  boxes, none off screen or negative.
- "Collides with the bottom shelf" at Normal is not a fault: the menu is a modal box and may cover the shelf.
- Rule: RULEBOOK 9.15 says the UI scale is never capped and a layout fits 831 design pixels; the battle menu is 967
  design pixels tall. Fable had no finding here (UI/UX said the pack had no larger-scale frame). Neon's alone.

### 5. How to play teaches wrong keys and retired screens: **Stands**

- Checked every claim against the code. campaign_ui.gd:1879 says "Enter end turn"; battle.gd:3240 to 3250 has Enter
  confirm a plan and Space end the ship. :1868 says "in any order"; ledger.gd:474 says "Most ships cannot move after
  firing". :1869 names "the Helm panel" and :1874 "the chip under the top bar"; neither exists in KEEL. The eight
  encounter kinds are in ENC_POOL; the text names six and leaves out Relay and Decapitation.
- More that Neon missed in the same text: "A toggle arcs" is wrong twice. A pans the camera (camera_rig.gd:203) and the
  arcs key is V (battle.gd:3261). R (threat map), T, F, X (ram), G (board) and Space are not listed at all, while the
  in-battle teaching cards tell the player to press R, X and G.
- Evidence limit: the Help screen is not in the pack, so this is code only. No Fable seat found it. No open issue names it.

### 6. The Relay hex cannot be found: **Stands**

- Checked. board.gd:397 to 398 is the 30% gold fill. battle.gd:3900 and :3925 list only exit, transport exit and
  perimeter, so the relay has no hover text and no row in the key. `seed10_t025` and `seed121_t021`: I could not find
  the hex without knowing where to look.
- Agreement: Fable UI/UX 1 (its top finding, same lines) and first-time player confusing 1.
- Corrections. The relay is not only a faint fill: it also gets a gold outline at 90% (board.gd:485 and :543 to 544).
  It is still too small to find. The key's title does read "Relay" (`seed121_t021`), but as the encounter name with
  four unnamed squares. And Relay is not forced on Battle 2: the teaching battle forces the enemy faction and the
  reinforcements (campaign.gd:3588, :943), the scripted route chose Relay in both runs.

### 7. "Easy" on a fight with reinforcements; stripped refits wait in the hold: **Stands**

- Checked. map_intel.gd:32 to 66 prices the fleet budget, the AI level, Heat and bounty, and never the forced
  reinforcement or the "War zone: reinforcements" sector rule. `seed10_t023` shows "War zone: reinforcements" in the
  header and "Easy" with one pip on the Relay; `seed121_t019` shows "Easy" on the fight that run then lost.
- Agreement: Fable first-time player confusing 11 ("Easy" on 2 ships against 4).
- Already planned, in part: Ryan ruled on Battle 2 after Neon wrote (R366, Nov 20 19:45 UTC, issue 1393: Battle 2 gets
  Battle 1's open strip, "Corsairs and the forced round 3-4 reinforcements stay"). Because the reinforcements stay, the
  pips stay wrong, so Neon's pip fix is still needed and is not covered by 1393.
- Wrong in one word: the refit is not "silent". The game says "Lance focusing crystal stripped from the Cordon
  destroyer and stowed in the hold." (`seed121_t019`, campaign.gd:3367). What is missing is a lasting reminder: the
  button stays "Fleet and refits" in small grey text (campaign_ui.gd:1227). `hold_count` already exists
  (campaign_view.gd:91), so the badge is a one-line change.

### 8. The captain is "Lost" and "escaped" on one screen; all-scrap salvage choice: **Stands**

- Checked. campaign.gd:3753 to 3757 adds the ship and captain to `lost` and then, 6 times in 10, to `escaped`.
  campaign.gd:3271 turns a wreck to scrap for the causes marked `scrap` in KILL_CAUSES (big, flay, melt, tidal).
  `seed10_t022` shows the red "Lost: the Cold Reckoning and Lucan Ivers." above three "Scrap it" cards and the green
  "Lucan Ivers escaped in a lifepod" strip.
- Agreement: Fable first-time player not rewarding 1 and 5, UI/UX 9.
- No ruling stands in the way: neither RULEBOOK nor FINDINGS mentions the lifepod, so "Ryan picks" is the right tag.
- One more copy of the promise Neon missed: How to play opens with "Ships and captains you lose are gone for the run"
  (campaign_ui.gd:1866), beside the title tagline (brand.gd:11).
- Scope note: seed 121's first reward was a real choice (`seed121_t018`, both kills "cut in two by a lance"). The
  all-scrap screen comes from battery kills counting as "blown apart", which the Sunward starter fleet does often.

### 9. Two interface looks side by side; cut labels; violet nebula squares: **Stands**

- Checked. campaign_ui.gd:2251 `shell_panel(20)`, :331 `keycap`, :364 and :2316 `VERD`; ledger.gd:714 and :823 trim
  with `_trim`; hud.gd:818 gives the closed key an empty panel; TERRAIN_INFO.neb.col is "#b07cff".
- Pictures agree: `seed10_t022`, `t038`, `seed121_t018` (chamfered box, [1] key caps, green text); `seed10_t005`
  ("Reload torp..."); `seed10_t008` (log cut before the number); `battle_01` ("Engagement" faint on a pale sky).
- Agreement: Fable UI/UX 7, 8 and 11, art 6 and 10, first-time player not fun 10 and 12.
- Rule: screens.md section 2 says every screen moves to the orders sheet, "No panels" and "No key caps". So the modal
  part is a known direction that has no issue yet, not a new discovery.
- Still true on live main: after the line style merge (issue 1374) the nebula edge is `edge_neb` (0.72, 0.52, 1.0) in
  render/line_style.gd:47 and the tint is at board.gd:361, both still violet against R353's rose. Neon's line numbers
  (board.gd:364, :483) are from the older commit.

### 10. Arcs "dead code", double Nemesis hail, renamed and placeholder text leaking: **Wrong** in most parts

| Part | Verdict | Why |
|---|---|---|
| Beats 1 and 2 are unshipped dead code | Ruled | The 11.4 gate. See knockdown 3. Fable lore 11 has the real problem. |
| Nemesis hails twice in two voices | Stands | rules.gd:2244 and battle.gd:632 to 633, as cited. Same as Fable lore 1, which quotes the two pools. Not on screen in the pack: needs one Nemesis battle log capture. |
| "Grax Ironmaw" is pre-rename | Wrong, Ruled, Bad fix | See knockdown 1. |
| "the Brand" title is retired | Wrong | rename_map_final.md:3 retires the names proposed by the older Oct 26 map; "Brand" there was the weapon family (FINDINGS X24: "weapons Brand (Las-)"). titles.json:27 is an earned admiral title. The final map has no row against it. |
| Blank "Placeholder:" mastery text leaks | Wrong | campaign_ui.gd:2217 to 2220 hides it. What is left is three capstone ranks with a name and no effect line, on a screen behind level 8. Not felt in the first hours. |
| "Salvage" where the map says "Strip" | Stands for campaign_ui.gd:2428 ("Salvage one wreck"; rename map line 264). Wrong for campaign_tips.gd:9, which already says "choose Strip for salvage". |
| Synchronised against Synchronized | Not felt | True (voices.json:70 and :80). One log line. Fold into a spelling pass. |

### 11. Title shows no ships; faction skies; seven fonts: **Stands**

- Checked. battle.gd:656 clamps the showcase camera to 120 to 210. `title_1920x1080`: rocks, haze and a few specks. No
  ship reads.
- Agreement: Fable art 7 ("the title screen shows none of the game"), art 8 and UI/UX 14 (typefaces), art 15, 16, 19
  and 20 (skies against hulls). Fable UI/UX also listed the title layout as good and to keep; the two do not clash, the
  layout is fine and the scene behind it is empty.
- Neon tagged the sky tint "reopen: Ryan's call" and the fonts "Ryan picks". Both tags are right: R351 kept the battle
  light, R353 ruled the nebula only, and the gold wordmark colour is R327 (the face was not ruled).
- Small overreach: RULEBOOK 9.2 is about the interface and 10.9 about the nebula. Neither bans a purple sky. The
  Eclipse sky is a taste point, not a rule break.
- The fix needs the clamp changed too (a 38 to 55 distance is below the 120 floor on the same line).

### 12. HUD state leaks across turns and victory: **Stands**, two parts not felt

- Stands: the dead enemy stays in the shelf under VICTORY (`seed10_t037`: "HULLBREAKER RAIDER 0 / 34"); a teaching
  card opens on the enemy turn (`seed10_t006`); the first card ends with "Glasswright ships cannot Brace." for a
  Sunward player (`seed10_t004`, battle.gd:71). Agreement: Fable UI/UX 10 and 12, first-time player not fun 7.
- Not felt, Retreat: the code Neon quotes does the opposite of the claim. battle.gd:4419 hides Retreat once `ended` is
  true (`seed121_t040`, the defeat card, has no Retreat). `seed10_t037` is the short beat where the rules say "over"
  and `ended` is not yet set (battle.gd:4405 tests both, :4419 only one). In that beat Retreat is drawn disabled and
  cannot be clicked (ledger.gd:360 to 362). One-word fix, no player harm.
- Not felt, the empty right half of the shelf on the enemy turn: common in the genre, and it is the Log covering ships
  (finding 1) that hurts in those frames.
- Wrong cause, floaters: the numbers already have lanes (FLOAT_LANE_SHIELD, battle.gd:132; shield one line up, a bare
  "Critical" two lines up, :5325 to 5329). `seed121_t039` does show a smear above "Critical -20 hull", so something
  overlaps, but it is not the clamp at :5085. Needs a clean frame before a fix.
- Already planned: "Torpedoes inbound" goes away with the torpedo rework (R364, issue 1379, PR 1392 open).
- The card on `seed10_t006` sits in the top right corner, not over the enemy ships.

### 13. Work every frame while nothing happens, title included: **Stands**

- Checked. battle.gd `_process` (:5015 on) has no showcase guard and calls `hud.set_plate` per ship; hud.gd:970 looks
  up "st/v/bars" and builds a new array each call; hud.gd:1338 to 1339 runs `_layout()` every frame, and `_layout`
  calls `legend.reset_size()` (:1366); ledger.gd:79 and :196 and campaign.gd:2413 compile a RegEx per call.
- Agreement and size: Fable Godot 11 measured it (idle script time 3.96 ms median with 24 ships, 1.74 ms with 6) and
  Godot 3 covers the title. Neon gives no number; use Fable's.
- Felt on a laptop, not on Ryan's PC. Rank it as Fable did.

### 14. Windows export traps and the F8 key: **Wrong** in the headline, two small parts stand

- D3D12 and the console wrapper: see knockdown 2.
- Stands: no icon (`application/icon=""`, export_presets.cfg:33). Same as Fable Godot 10, which adds the splash and the
  unsigned exe.
- Stands: F8 cycles the board looks for any player (board.gd:720; still there on main at :816). RULEBOOK 9.8 says the
  developer surface hides behind a dev flag. Rare, but it changes the look of the board with no way a player would
  know to undo it. Neon's alone, and cheap to fix.

### 15. Very large scripts, dead fallback, mid-battle warm-up: **Not felt**

- The sizes are right (five files, 23,129 of 95,169 lines, 284 scripts). Fable Godot 12 says the same and says plainly
  that no player feels it. It costs the team, not the player. Keep it for the Astra pass.
- The dead fallback is real and harmless: `rules_log` is always true, so `_log` (battle.gd:1578) does nothing and `F`
  at :611 is always empty. The "Contact:" line the player sees comes from rules.gd:1514.
- Wrong, the hitch risk. Neon marks it inferred, and each example makes no new ship: an Eclipse wreck stands up again
  as the same view (ship_view.gd:412, "back to its own materials"), carrier wings are flying from the first frame so
  their kind is already drawn, and the Nemesis is on the board at the start. Only a hull kind that first appears mid
  battle could hitch, and the reinforcement path is the one that does that; it is already warmed (issue 1289).
- Already fixed: the scanned rock check for exported builds. PR 1364 merged Nov 20 18:32 UTC; main's world_rocks.gd
  now uses the import remap.

## The 5 not-fun items

1. **Blind on turn 1, buried in rocks, relay unmarked: Stands.** Same as findings 1 and 6, with the same Fable matches.
   One correction: the relay has a marker (gold fill and outline); it is too faint to find.
2. **Burn and Fire contradiction and the cut log: Stands.** Findings 2 and 9. Fable UI/UX 2 and 7.
3. **All-scrap reward and refits in the hold: Stands.** Findings 7 and 8. Fable first-time player not rewarding 1.
   "Never reminds you" is too strong: there is one toast, then nothing.
4. **"Easy" Battle 2 and the captain both dead and alive: Already planned for the fight, stands for the rest.** Ryan
   ruled the Battle 2 layout (R366, issue 1393). The pips and the lifepod wording are not in that issue and still need
   their own.
5. **Black loading screens, empty title, walls of tutorial, spoiled cut-ins: Stands.** `seed10_t002` is a black screen
   with "Preparing the sector...". Fable first-time player not fun 4, 7 and 9, art 7 and 9, UI/UX 12 and 14, Godot 2.

Neon's five fun items agree with Fable's fun list on four of five (the forecast before the shot, the aspect pick, the
route choice, the refit trade). Nothing to challenge there.

## What both Neon and Fable missed

1. **The game speaks in hex coordinates the board never shows.** `battle_03`: "Blocked by the asteroid at 9,10, the
   asteroid at 9,12." (battle.gd:3874; the move refusal does the same, battle_api.gd:1051). No hex on the board has a
   number. The two rocks are outlined in ember in that frame, so the words can say "the two marked asteroids". Felt by
   every player the first time a shot is blocked.
2. **The card that explains turns never showed in either run.** The traces list 7 and 6 teaching cards; none is
   "fired" ("Taking turns": sides alternate one ship at a time, Space ends a ship, Tab is the next ship). Pressing END
   SHIP retires that card (battle.gd:3410), and on round 1 END SHIP is the big ember button with nothing in range. The
   game's most unusual rule goes untaught. In seed 121 the "Firing" card never showed either (a shot retires it,
   battle.gd:5368). Fix: retire "Taking turns" on seeing it, not on ending a ship.
3. **Space both hurries the enemy and ends your ship.** battle.gd:3207 (Space hurries while the enemy acts) and :3246
   to 3250 (Space ends the ship, guarded for half a second after the hand-over). A player tapping Space through the
   enemy turn ends a ship that has not moved or fired, with no confirm and no undo. Read, not seen in the pack. Space
   ending the ship is Ryan's ruling (F1, Nov 1), so keep it: ask for a second press only when the ship has done nothing.
4. **Changing UI scale from inside the battle menu rebuilds that menu off screen.** The menu row "UI scale" steps
   Normal, Large, Larger (battle.gd:4324). At Larger the menu the player is looking at loses its last rows (table in
   finding 4), and the row that would undo it is on screen but the title and frame are gone. This is how a player
   will meet finding 4, and it happens on the comfort setting RULEBOOK 9.8 says must be reachable mid battle.
5. **The fix list needs live-main line numbers.** Main moved during the blind round: every board line now comes from
   render/line_style.gd (R362) and rock hexes get a rim (R361), both merged. Two are still pending at main 69955313, not
   fixed: torpedo gameplay (R364, open issue 1392) and the Battle 2 layout (R366, issue 1393, claimed, not merged). Do
   not discard a finding as fixed on the strength of those two. Neon's and Fable's board.gd and battle.gd line numbers for rings, edges and torpedo text are from 89bf7e17
   and 25adec31. Whoever files the ranked list should re-point findings 1, 3, 9 and 12 at main first, or the jobs open
   on stale lines.

## How the two runs were done

Headless Godot 4.7.2 on this branch, placeholder hulls, window set to 1920 by 1080, `ui_scale.gd` `player` set to 1.0,
1.15 and 1.3 before the battle scene was made; then `_open_menu()` and the menu's global rectangle, and the ledger's
hit boxes as Fable's size_probe.gd reads them. The scripts were scratch files and are not in the repo; the method is
size_probe.gd plus those two calls.
