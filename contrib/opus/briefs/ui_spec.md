# Consolidated UI specification (issue #231)

**Status Nov 11 2026 (issue 492 clean-up):** live for the scale law (4.1), the focus ring (6), settings (7), the faction colour
rule (5.4) and the debrief order (10). Superseded: the gold and Lime palettes and fonts (the look is the orders sheet,
docs/playbooks/screens.md section 2 and RULEBOOK 9.1). The floor is 17 px (RULEBOOK 9.4; raised from 12 in issue 644). Where this file
and the rulebook disagree, the rulebook wins.

Opus, Nov 8 2026. FINDINGS R136. This is settlement U-B of the Nov 6 UI and campaign map audit (contrib/muse/reviews/ui_audit_2026_11/, synthesis section 6, the blind Rey table at legs/rey_blind.md section 5, owner rulings R1 to R3 in synthesis section 9 and issue #215). It also carries the U-E pieces #231 names: the MN10 host read, the MP9 precedence read, the MN3 defaults block, and the MN8 debrief spec (with MN9 folded in), which lives in its own file: [debrief_spec.md](debrief_spec.md).

**R137 (Ryan, Nov 8 16:53 CST):** the whole UI gets a redesign from scratch (warship-console look, battle screen first, #270 and #271). The redesign changes the look and the layouts; this spec's scale law, focus ring, text floor, colour meanings and content rules stay underneath it. Where a section here names a shipped layout value (a panel width, a banner size), the redesign's style guide replaces it.

How to use it: a coding job that touches UI reads this file first. The generated table of both builds' literals is written on demand by `node contrib/opus/tools/ui_constants_diff.js` (to contrib/opus/briefs/ui_spec_constants.md; the Nov 8 snapshot is archived at docs/archive/briefs/ui_spec_constants.md). The standing checks in contrib/opus/tools/ui_spec_tests.js keep the code-structure rules below true on every PR.

Values marked **provisional** are this spec's picks pending a capture round: U-A (the calibration sitting, #235, Ryan at 1440p and 4K), U-C (the campaign capture round, #237) or U-D (the danger-band Monte Carlo and the colour-vision pass, #238). A provisional value is the rule until its round lands; the round changes it here, in one place. Nothing here is a performance gate (R111, R121); the scene gate (R116) is the only one.

## 1. What this PR changed in the game

| Change | Where | What the player sees |
|---|---|---|
| One shared UI scale law (TY4) | new godot/ui/ui_scale.gd; hud.gd, title.gd, campaign_ui.gd, map3d.gd labels, campaign_fallback_ui.gd, career_screen.gd, rename_dialog.gd, load_screen.gd | Nothing at 1080, 1440 or 2160 lines (all six old copies agreed there). Above 2376 lines the campaign screens stop growing with the battle HUD (their ceiling was 2.5); above 2160 the career screen and rename dialog keep growing to 2.2 (theirs was 2.0). The loading line now scales (it was a fixed 24 at every size, so tiny at 4K). |
| Player UI scale hook (R2) | ui_scale.gd `player`, main.gd `_apply_settings` | Nothing yet: it reads `settings["ui_scale"]`, missing means 1.0. The settings entry is follow-up job A (section 11). |
| Visible battle focus ring (AC5) | hud.gd `_theme` | The battle menu (Esc) and the end card now take keyboard focus and show the title screen's bone ring. Board-time buttons are unchanged (section 6). |
| Text floor (TY6) | ui_scale.gd MIN_TEXT 12; three campaign side panel small-caps labels 11 to 12 | Three small labels on the map's side panel one point larger. |
| One hull-low line (HD9) | hud.gd roster bar and nameplate bar 0.34 to 0.35 | Invisible (the browser and the campaign bars already used 0.35). |
| Menu keyboard check | ui_shots.gd moment 7 | Nothing (a test): the menu takes focus, keeps it on a toggled row, and Esc gives the keys back. |
| Debrief mock | godot/campaign/test/debrief_mock_shots.gd | Nothing (a capture script for Ryan's review round). |

## 2. Rulings applied

- R1 (developer surface, HD14, MN2): the shipped game hides developer tools behind a dev flag; comfort settings stay reachable mid-battle in one settings architecture. Section 7.
- R2 (UI scale and reduce-motion, AC2, AC7): both in scope, on the shared scale function. Sections 4.4 and 7.6.
- R3 (faction colour, IC7, MP12): map keeps faction colour under a stated rule with the station muting recorded; battle UI keeps friend or foe only, enemy faction by crest and name. Section 5.
- R115 and R116 (#207): the scene gate is 12.5 ms on the frame median at 1080p and on 4K GPU ms; the gate scene runs at the Max graphics tier and measured 6.9 ms (6.0 ms after #220) and 5.4 ms. Sections 7.4 and 7.5.
- R123 (#212): the camera is never taken for a capital death. Section 8, MN6.
- R131 (#228): movement feel lives in contrib/opus/briefs/movement_spec.md; this spec only names the settings choices.
- Owner rulings Oct 24 and lore round 8 (R59): PC only; faction looks follow lore_bible_r8.md.

## 3. The two-build constant diff (H1, settlement U-B form)

The audit's hypothesis H1 was that the port transcribed the browser UI by eye. The script reads both builds and writes every named pair, every hex and float colour and every text size literal into ui_spec_constants.md. A difference is a question, not an automatic reversion (audit synthesis 5.3). The choice for each named pair:

| Item | Browser | Port | Recorded choice |
|---|---|---|---|
| HD2 body and button text | 15, 14 | 15, 14 | SAME. Kept. |
| HD3 top bar height | 52 | 52 | SAME. Kept. |
| HD3 top bar title | 28 blackletter | 21 display face | Port kept: the face changed in lore round 5 (TY1) and Michroma at 28 crowds the bar. **Provisional**, judged on the U-A side-by-side. |
| HD4 fleet roster width | 236 | 250 | Port kept: its rows carry the captain line the browser shows on hover. **Provisional**, judged on the U-A 20-ship roster capture. |
| HD5 ship panel width | 340 | 340 | SAME. The audit compared the browser's outer 340 with the port's s(316), which is the scroll area inside the port's 340 panel (hud.gd `_build_panel`). No disagreement. |
| HD6 log size | 430 x 126 | 430 x 126 | SAME geometry. The entry cap is the HD6 soak's question (#238), not this table's. |
| HD7 plate bar | 54 | 90 | Open, the audit's largest gap. Port kept until the U-A plate-at-zoom captures at the standard radius and the effects zoom; Ryan picks there. |
| HD7 plate name | 12 | 14 | Port kept (the browser's 12 sits on the text floor; the port's 14 is above it). Rides HD7. |
| HD9 hull-low line | 0.35 | 0.34 battle, 0.35 campaign | **Applied: 0.35 everywhere.** No measurement could earn either value; one line is the fix. |
| HD10 friend and foe names | #8ff0a0, #c9a2ff | #8ff0a1, #c9a3ff (float transcription) | KEEP (adopted table). One step in one channel, invisible. The next edit to hud.gd's colour block writes them as hex. |
| HD11 round banner | 84 blackletter | 46 display face | Open. One display scale for banner, end card and title (HD11, MN7, MN1) is set on the U-A frames. |
| HD13 hover tip width | 330 | 300 | Port kept. **Provisional**, judged on the U-A frames. |
| MN7 end card heading | 64 | 34 | Rides HD11. |
| TY3 campaign body | 16 | 18 (17 for rich text and buttons) | Section 4.2. |
| TY4 scale law | none (fixed px) | one law, ceiling 2.2 | Section 4.1. |
| AC5 focus ring | 2 px gilt outline | 2 px bone ring (this PR) | Section 6. |
| H6 blood text | #e27f74 (class) | #e27f74 | SAME. The browser's `--blood` variable (#d0493f) is dead: no text uses it. The palette's BLOOD is #e27f74. |

## 4. Size rules

### 4.1 One scale law (TY4, HD1, TY5)

```
k = clamp(window height / 1080, 0.6, 2.2) x player UI scale
```

- It lives in godot/ui/ui_scale.gd (`k_for`, `px`) and nowhere else. Every screen calls `k_for(viewport size)`; ui_spec_tests.js fails any .gd under godot/ui or godot/main that keeps its own height / 1080 clamp. The map's label overlay reads the campaign UI's k with no second clamp.
- 1080 is the design height: every size in UI code is written as it looks at 1920x1080. One layout, authored at 1080 values, with no separate 4K design (the debrief design's own rule, now the rule for every screen).
- Floor 0.6 and ceiling 2.2 are **provisional** (HD1): U-A sets them. Today the floor binds below 648 lines and the ceiling above 2376, so neither binds at Ryan's 1440p or 4K.
- Height only (TY5): width never changes k. Kept **provisionally**; if the U-A small-window capture shows text crowding or stranded, the replacement is specified here.
- The battle HUD and the title rebuild themselves when the window changes size; the campaign screens rescale on `size_changed`. Any new screen does one of the two.

### 4.2 Base sizes (TY3)

Two bases, by reading distance, written at the 1080 design height:

- Battle HUD and battle overlays: body 17, buttons 19, rich text 18 (issue 644; the orders sheet itself, ledger.gd, sets its own sizes from 17 up).
- Campaign, menus and the debrief: body 17 (rich text and buttons at 17 today); the campaign theme's default label size 18 drops to 17 on the next touch of `_make_theme` (it only reaches labels built without a size).
- Steps above the base: 20 sub-head, 24 panel title, 34 end card title, 46 banner, 62 page title, 84 game title (shipped values). Below: 17, the floor (issue 644 moved the old 12 to 16 sizes onto it).
- The fallback campaign UI (15, 16) is a development scaffold (section 9) and is held to nothing beyond the scale law.
- **Provisional**: U-A judges both bases at 1440p and 4K.

### 4.3 Minimum text size (TY6, TY9)

- No text below 17 at the design height (17 px at 1080 lines, 34 at 4K; RULEBOOK 9.4, issue 644). `MIN_TEXT` in ui_scale.gd; ui_spec_tests.js scans every font size literal in godot/ui and godot/main. A one-glyph ornament (the side panel's gilt diamond) is not text and is exempt. The frozen browser build has seven sizes under it (10 to 11.5 px, listed in ui_spec_constants.md section 6); recorded, not changed.
- Issue 644 raised every size under 17 on the campaign pages, the battle HUD, the Career screen, the shared theme and the title to 17 or more, then raised `MIN_TEXT` to 17. The type scale per screen is in the issue 644 pull request.
- TY9: brand.gd `fit_size` stops shrinking at 17 absolute pixels (issue 644; its two users, the title and the battle banner, never reach it). The floor should scale: on the next touch, `fit_size` takes its floor as `px(MIN_TEXT, k)`, and a title that would go below it breaks onto two lines, as title.gd already does for a narrow window (MN1 interaction).
- **Provisional**: U-A can raise the floor; it cannot be lowered without a capture that shows smaller text reading.

### 4.4 Player UI scale (R2, AC2)

- Settings key `ui_scale`, a number. Choices: Small 0.9, Normal 1.0, Large 1.15, Larger 1.3 (**provisional** steps, judged in U-A). It multiplies the window law after the clamp and is held inside 0.8 to 1.4 by `set_player`.
- main.gd hands it to ui_scale.gd every time settings are applied; an old settings.json without the key reads 1.0, so nothing changes for an existing player.
- The entry sits in Settings on the title screen and in the battle menu (a comfort setting, R1). Changing it rebuilds the current screen at once: the HUD's `_rebuild`, the title's `_rebuild`, the campaign's `_rescale`. That application is follow-up job A.

### 4.5 Line height (TY10)

The port sets no line spacing (the font's own); the browser uses 1.4 for body and 1.45 for the log. **Provisional** rule: keep the font's spacing; if the U-A captures show Barlow Semi Condensed reading tight in the log or the ship panel, rich text bodies take a theme line separation of round(0.2 x size).

## 5. Colour rules

### 5.1 The palette (MP3, MP11, IC5, IC8, H6)

Every UI colour is a named palette entry. A new colour in UI code is either one of these or added here first with its meaning. ui_spec_constants.md lists every off-palette literal; existing ones move onto the palette when their file is next touched (no sweep job: most are scene and lighting colours, not UI).

| Name | Hex | Means |
|---|---|---|
| INK, IRON, IRON2, IRON3 | #0f1626, #182133, #222d44, #2d3a56 | grounds and borders |
| BONE, BONE2, BONE3 | #e6dcc4, #b3aa95, #7d7768 | text: primary, secondary, dim and disabled |
| GILT, GILT2 | #d0a64b, #8c6d2c | the player's own: gains, rewards, the current step, the primary action, names worth reading |
| GILT_HOVER | #e2bb62 | a gilt button under the pointer |
| ON_GILT | #1c1405 | text on a gilt button |
| VERD | #5fb3a6 | calm information: the next run, neutral panels |
| BLOOD | #e27f74 | threat and loss in text: losses, the enemy's archetype line, elite and boss names in lists |
| ALERT | #ff6b5a | the one alarm red: the Nemesis tag (MP3) and the Targeted tag when it returns (IC5; the browser's #ff7466 reads the same) |
| EMBER | #f0b35a | heat, fire and warning accents |
| SHIELD, HULL, HULL_LOW | #62ccff, #ffae42, #ff5a3c | bars only |
| BAR_TRACK | #3a1d1d | the empty part of a hull bar |
| BLUE | #62a8ff | B4 blue event options |
| FRIEND | #8ff0a0 | the player's side in battle: names, plate rings |
| FOE family | #c9a2ff names; #a64dff rings and chip borders; #e2d2ff text on the enemy chip; #b98cff the enemy phase bar | the enemy side in battle: its names, its turn, its AI's state (IC8, adopted with this meaning) |
| DANGER 1 to 4 | #7ddc6a, #d0a64b, #f0883a, #e2453a | map danger bands Easy, Even, Hard, Deadly (MP8; cut points re-ruled by the U-D Monte Carlo) |
| core colours | PATRONS col (data) | a core's own name and its sync lines |
| faction colours | section 5.4 | campaign map and crests only |
| SHELL, SHELL_EDGE | #0a0d0a at 80%; lime at 20% | #271 Lime Tactical (retired, R191): the matte panel and its edge (docs/archive/briefs/ui_style_lime_tactical.md) |
| WELL, WELL_EDGE | #080a08 (93% in a panel, 88% as a strip); lime at 35% | #271: the solid backing under every line of text, and its 2 px left bar |
| SHIELD_TRACK | #1b2a2e | #271: the empty part of a shield bar |

**Lime Tactical values (R149, #271).** The battle HUD now draws from godot/ui/theme/glass_shell.gd, which keeps these
names and meanings with new values: the grounds black-olive, the text family pale sage, GILT neon lime #c8f53a (still
"the player's own and the next action"), ALERT #ff4433 (still the one alarm red), FRIEND mint #52f0c4 (moved off green
so it never reads as the lime). The full table is section 5 of docs/archive/briefs/ui_style_lime_tactical.md (Lime is retired, R191). The hex values in the table above stay true
for the screens not yet rebuilt (title, campaign, career, menus); each moves to the glass_shell.gd values when it is.

Recorded decisions:
- The browser's `--blood` #d0493f is dead (H6) and stays out of the palette.
- #7f8fa6 (browser map name label) and #bfb6a0 (browser reward line with no core; also map3d.gd's reward line) are replaced by BONE3 and BONE2 (distances 48 and 20; #bfb6a0 already reads as BONE2).
- #e07a70 (campaign) is BLOOD (distance 7). #f2c063, #ffd27a, #e0b85c, #e0b04a in UI text are GILT or GILT_HOVER on next touch; #e0b04a in data is Kharon's core colour and stays.
- IC8: the lavender family is adopted as the enemy side's colour in battle. It never meets a faction colour in battle (R3). On the map, Eclipse's hull look is violet but its name colour is gold (#f0d690), so no map label reads lavender. Whether green and lavender stay apart for colour-blind players is the U-D colour-vision pass's question (AC1).
- Collision to watch: DANGER 1 green #7ddc6a is also Crucible's core colour and the repair tender's work light on the map. The U-D pass judges it; if it confuses, Easy takes a second channel (section 5.2) rather than a new colour.

### 5.2 Redundant encoding (AC1, MP4)

The browser map's route lines (MP4: colour, width and dash together) are the standard. Any state carried by colour also carries a second channel: width, dash, shape, a label or position. Today: IFF rides colour plus position and context only (the plate ring and the name are both colour), which is the audit's main AC1 worry; hull-low rides colour plus the bar's length; danger bands ride colour plus the band's word. The U-D colour-vision pass (deuteranopia, protanopia, tritanopia over the U-A and U-C captures) names any that fail; each failure is specified here as a second channel on this precedent, and Ryan rules on failures in the U-A and U-C rounds.

### 5.3 Panels over bright scenery (HD15)

Port panels are flat fills (GLASS at 0.80 alpha); the browser's are blurred glass. **Provisional**: flat stays. If the U-A panel-over-nebula capture shows text failing there, the panel fill alpha rises (not a blur) and the value is recorded here.

### 5.4 Faction colour rule (R3, IC7, MP12, IC6)

- One source for faction colour in UI: the map's faction looks, `map3d_system.gd LOOKS` (lore round 8), read through `System.text_col` (campaign_ui `fac_col`). data.js hull, trim and glow colours are ship paint (X4) and do not enter UI.
- Where faction colour may appear: the campaign map and its screens (the sector's holder name, the fight card's accent strip and head, hostile presence and rival raider names, map stop looks), and crests on any screen.
- Where it may not: battle nameplates, roster names, the ship panel, the friend and foe channel. In battle the enemy's faction is carried by the crest in the top bar and the faction name in plain text (BONE).
- Station muting on the map (MP12), recorded as the rule: a station prop's base colour is lerped 85% toward a warm grey (#999691) and its accent 40% toward mid grey (#808080), so stations read as neutral places and do not compete with the stop markers (map3d.gd, the station prop). **Provisional**: the U-C round shoots one unmuted variant; Ryan keeps, changes or removes the muting there.
- IC6 diff, done: the two crest files differ. godot/ui/campaign/crest.gd draws the lore round 8 crests in the LOOKS colours; godot/ui/career/crest.gd (career screen and rename dialog) still draws the older designs (a cracked halo over a sword, a skull with a gear jaw, a sail over a falling star, an eye over a vault door) in data.js glow colours. The career screen shows the wrong crests. Follow-up job C moves both career screens onto the campaign crest and keeps the career file's medal mode.

## 6. Focus and keyboard (AC5)

- The focus ring for every screen is the title screen's: no fill, a BONE border at least 2 px (s(2), min 2), corner radius s(4), drawn 3 px outside the button. Bone, not gilt, so it shows on the gilt primary buttons.
- Battle (this PR): the battle theme's focus stylebox was empty; it is now that ring. Which battle buttons take keyboard focus:
  - the Esc menu and the end card: yes. The menu's first row takes focus when the menu opens, a toggle keeps focus on its row, and Esc closes the menu and hands the keys back. The end card takes focus 0.75 s after it appears, so a Space still held to hurry the last enemy turn cannot press Continue (the battle's own 0.5 s Space guard).
  - the top bar, the activation card, the ship panel's orders and the tip card: no. On the board, Space, Enter, Tab, the arrows and the letter keys are the battle's controls (F1 key scheme, battle.gd `_on_key`); a focused button would take Space and Enter from them. Most top bar actions have a key (End activation is Space, Threat R, Top-down T, Grid Z, Menu Esc) or sit in the Esc menu (Speed). Two do not: **Command and Retreat are mouse-only today**, so a keyboard player cannot reach them. Follow-up job G gives Command a key (C is free) and puts Retreat in the Esc menu, where a stray key cannot end the battle.
- Campaign and career screens draw a gilt focus ring (2 px with a glow in the campaign theme, 1 px on the career screen); on gilt primary buttons it barely shows. Next touch of those themes takes the bone ring (follow-up job F).
- The browser's 2 px gilt outline (focus-visible) is the frozen baseline.

## 7. Settings architecture (R1, MN2, AC6, MP9, MN4, MN3, AC3, AC7)

### 7.1 One store, two surfaces

- One settings dictionary: main.gd `settings`, saved to user://settings.json, loaded over the defaults key by key (so a missing key keeps its default and an old file never breaks).
- Two surfaces over it: Settings on the title screen (every entry) and the battle menu (the comfort subset, mid-battle). R1's comfort clause is already met in the port: the battle menu carries sound, speed, movement, follow, cut-ins, tips, reduce flashing, shake, threat map and firing arcs, and its choices write through `option_changed` into the same dictionary.
- A setting is never stored outside it. The map's own quality toggle is the one exception today (7.3).

### 7.2 The dev flag (R1, HD14)

- `dev` is true when the build is a debug build (`OS.is_debug_build()`), or the command line has `--dev`, or user://dev.flag exists. Playtest exes count as dev builds: the playtest exe recipe (LOOP.md) adds `--dev` to its launcher. A release export without the flag is the player's game.
- Behind it: the battle menu's "Copy a problem report", the browser's Report a problem, Copy report and Diagnostics if they are ever ported, the test-hull toggle, and any debug overlay or console.
- The playtest unlock switch (R69) is a player-visible switch while R69 holds; when Ryan ends the playtest phase it moves behind the dev flag.
- Applying the flag is follow-up job A.

### 7.3 MP9 precedence (read, AC6)

Today (campaign_ui.gd `_load_map_quality`): the map's own button writes user://campaign_map.json, and once that file exists it wins over the Graphics setting; without it, Graphics Low gives a low map and Max or High a high one. The sector backdrop bake always follows Graphics. So the two controls can disagree and the map file is invisible from Settings.

Rule: the map toggle joins the settings dictionary as `map_detail`: `auto` (default: follows Graphics, Low gives low) or `high` or `low`. The map button cycles it and writes the settings key; Settings shows it under Graphics. An existing campaign_map.json is read once as the starting value and then ignored. Follow-up job A.

### 7.4 Tier names (MN4)

- Graphics tiers are Max, High and Low, everywhere: Settings, the map's detail entry (as Auto, High, Low), docs, and talk about benchmarks.
- Max is the measured tier: the #207 gate scene runs at Max (bench/scene_gate.gd sets quality max) and reads 6.0 ms frame median at 1080p (after #220) and 5.4 ms 4K GPU against the 12.5 ms gate (R116). High and Low have no gate reading yet; their first measurement is recorded here when a job takes it (#221 or later).
- The browser build's Ultra, High, Medium and its "tuned for phones" line are a frozen PC-only leftover (section 1.6 of the audit pack); not changed.

### 7.5 The defaults block (MN3, AC3, AC4, MN5, MN6), re-ruled now that #207 has reported

For Ryan's review round (the Board routes it). Pick is Opus's; "keep" means the shipped default stands.

| Setting | Default today | Pick | Why |
|---|---|---|---|
| Graphics | Max | keep Max | the gate scene at Max uses under half the 12.5 ms gate at 1080p and 5.4 ms on 4K GPU |
| Full screen | on (the project boots maximised until settings apply) | keep on | the boot window and the default describe the same game a moment later; no change needed |
| Temporal AA | off | keep off | softer motion; no capture argues for it yet |
| Reduce flashing (AC3) | off | keep off | the WCAG 2.3.1 flash cap (3 a second, fx.gd FLASH_CAP) is always on whatever the setting; the setting goes further. Re-rule if the #232 salvo flash test shows the capped salvo still failing |
| Screen shake (AC4) | Full | keep Full | judged in U-A play (#235); steps Full 1.0, Reduced 0.5, Off 0 stay until then |
| Speed (MN5) | Normal 1.0, Fast 0.45 | keep | judged in U-A play |
| Movement | Cinematic | keep | R131 |
| Enemy AI | Standard | keep | onboarding fix 1 |
| Cut-ins (MN6) | Key moments | keep, minus capital kills | see section 8, MN6 |
| Follow enemy activations | on | keep | |
| Teaching tips | on | keep | TY8 rides the playtest checklist route |
| Volume, music volume | 0.8, 0.7 | keep | S15 listen pass owns sound |
| UI scale (new) | Normal 1.0 | Normal | R2 |
| Reduce motion (new) | off | off | R2; the switch exists for players who need it |
| Map detail (new) | Auto | Auto | 7.3 |

### 7.6 Reduce motion (R2, AC7)

Settings key `reduce_motion`, default off, in Settings and the battle menu. When on, UI animation stops but every state stays visible:
- the map's available-stop pulse (map3d.gd, the scale wobble on each stop you can reach) holds still at full size;
- the map's ambient drones, patrol ships and spinning station rings stop where they are;
- floating combat text appears in place and fades without rising or scaling;
- the round banner appears and fades without moving.
It does not cover battle choreography (the movement spec owns that and has its own Brisk choice), screen shake (its own setting) or flashes (reduce flashing). Follow-up job A.

## 8. One-line recordings (the adopted table)

- HD5: no disagreement (section 3).
- HD9: one hull-low line at 0.35, applied.
- HD10: KEEP; float transcription noted.
- HD12: floating text is battle.gd's `floats` (19 px in the browser); its size is judged in the fx salvo round (#232).
- HD14 and MN2: section 7.
- MN6: conflict found. battle.gd `_cine_wants` gives a cut-in under Key moments for every kill of a ship size 0.6 or larger and every flagship kill, which takes the camera for a capital death against R123. Recommended: Key moments drops the capital kill case (lances, torpedoes, novas and capital volleys stay); Every attack keeps it as the player's own choice. Follow-up job D, after the #233 death captures confirm deaths read without it.
- MN11: the credits screen's font licence lines are the typography record; kept.
- TY1: the browser's blackletter is the frozen incumbent; the cutover to the port is the change point for the display face. No other date.
- TY2: Barlow Semi Condensed is the body face on every screen; Michroma for display, Oxanium small caps for section heads (brand.gd). A new screen loads faces only through brand.gd.
- TY7: the battle help line stays one paragraph until Ryan reads it in U-A; then it becomes grouped lines (orders, camera, turn).
- TY8: the shared tips switch is recorded; splitting battle and campaign tips is decided on the playtest checklist route.
- TY9 and TY10: section 4.
- IC3: the flagship star is presentation. It is added when a label is built (hud.gd roster, panel, plate, card); ship names in saves and logs carry no star. A screen reader reads the star as part of the label text, which is the intent.
- IC4 and IC5: the elite suffix and the Targeted tag are absent from the port's plates. U-A checks the plates in both builds; if Ryan wants them back, they return as named additions (Targeted in ALERT).
- IC6: section 5.4.
- IC7: section 5.4.
- MP4: the redundant encoding precedent (5.2).
- MP8: the band colours are DANGER 1 to 4; cut points and labels wait on the U-D Monte Carlo.
- MP10 and IC1: icon chips and stop-type recognition are U-C's.

## 9. MN10: which campaign presentation ships (host read)

campaign_host.gd `start` loads res://ui/campaign/campaign_ui.gd (the 3D map and the campaign screens) whenever that file exists, and only otherwise draws campaign_fallback_ui.gd (a title, the facts and one button per act). The export preset exports every resource except test folders, so every build the player can run has campaign_ui.gd and never shows the fallback. **The 3D campaign UI ships.** The fallback is a development scaffold: it stays in the repo for runs on a partial checkout, it is not a maintained player surface, and no UI rule beyond the shared scale law (already on it) applies to it. Nothing for Ryan to see changes, so no owner question is raised; the Board can still ask him to confirm with the next sheet.

## 10. The debrief (MN8, MN9)

[debrief_spec.md](debrief_spec.md): what the run debrief and the battle debrief must show and in what order, against the shipped text and the owner-ruled Nov 2 debrief design, plus the loading cover. Ryan reviews one mock capture (docs/shots/ui231/). It feeds #92.

## 11. Follow-up jobs (for the Board to file)

- A. Settings application (workhorse, one run): the `ui_scale` entry and rebuild-on-change (4.4), `reduce_motion` (7.6), `map_detail` with the campaign_map.json migration (7.3), the dev flag and "Copy a problem report" behind it (7.2). Done when: each entry in Settings and, for the comfort ones, the battle menu; an old settings.json and an old campaign_map.json load with no change; captures of Settings at 1080 and 4K at Normal and Larger.
- B. Palette on touch (no job): files take palette names when next edited (5.1).
- C. Crest consolidation (workhorse, small): career_screen.gd and rename_dialog.gd draw factions with ui/campaign/crest.gd; career crest.gd keeps medal mode only. Done when: a career screen capture shows the round 8 crests.
- D. Cut-ins and capital deaths (workhorse, small, after #233): MN6 in section 8.
- E. #92 builds the debrief from debrief_spec.md after Ryan's mock round.
- F. Campaign and career focus ring onto the bone ring (6), with the next campaign theme touch.
- G. Keyboard reach in battle (workhorse, small): a Command key (C) and a Retreat row in the Esc menu (6). Done when: ui_shots.gd reaches both from the keyboard.
- Capture rounds already filed: U-A in #235, U-C in #237, U-D in #238. Each one updates the provisional values here.

## 12. Not checked

- Godot was not run in the cloud sandbox; the parse check, the debrief mock and the battle UI check (with the new menu moment) ran on Ryan's PC (tools/pc/jobs/ui231_shots.bat, results in the PR).
- The CVD pass, the plate-at-zoom judgement and every provisional value: their capture rounds.
- The browser build was read, not run; it is frozen and was not changed.
- Scene (.tscn) files were not scanned for UI literals; the UI is built in code, and main.tscn and battle.tscn hold no sized controls the HUD does not rebuild.
