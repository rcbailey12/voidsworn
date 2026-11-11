# Campaign orders sheet, issue 441

The campaign map now uses Ryan's picked R2 orders sheet. The rail is unboxed, with an ember action and route accent, Big Shoulders names, Barlow sentences and Azeret figures. The selected route expands in number order. The fleet has separate name and hull columns. The faction purchase is at the top of Fleet and refits.

Files: godot/ui/campaign/campaign_ui.gd, map3d.gd and rail_orders_shots.gd; godot/ui/theme/glass_shell.gd and fonts/; contrib/opus/briefs/ui_style.md; contrib/opus/tools/ui_spec_tests.js; godot/campaign/test/map_travel_test.gd; both rail_r2 capture folders. The travel test's obsolete lime assertion now checks the shared ember token, with its reachability and flight checks retained.

## Ryan's pictures

[Before and after](../../../docs/shots/ui_redesign/briefing/rail_r2_1080/before_after.png), then [sector I](../../../docs/shots/ui_redesign/briefing/rail_r2_1080/sector_1.png), [sector II](../../../docs/shots/ui_redesign/briefing/rail_r2_1080/sector_2.png), [sector III](../../../docs/shots/ui_redesign/briefing/rail_r2_1080/sector_3.png).

Board mirror: C:/Users/rcbai/Downloads/voidsworn_test/board/issue-441/shots/. It contains rail_r2_1080/, rail_r2_1440/, before_after.png and this report. Each capture folder's README describes every picture and the repeat command. The full captures are 1920x1080 and 2560x1440, Forward+ on the RTX 5080, high map detail, UI scale 1.0 and 1.3333 respectively.

## Readability figures

| Capture | Sector I minimum | Sector III minimum | Filled action |
|---|---:|---:|---:|
| 1080 | 6.54:1 | 6.58:1 | 8.30:1 |
| 1440 | 6.54:1 | 6.50:1 | 8.30:1 |

The requirement is 4.5:1. The weakest item is the joining word Pays, using TEXT3. Supporting condition sentences measure at least 10.87:1; captured hull figures at least 10.88:1. Measurements compare the theme foreground color with every pixel under its text allocation on a capture with the rail hidden and the scene and gradient retained. The worst pixel is reported for each item in contrast.json. Anti-aliased glyph edges are not treated as the foreground color. The action's captured solid fill is RGB 255,138,58 with RGB 16,12,8 words.

The smallest captured text is 17 design pixels. Big Shoulders stays at least 28 at 1080 and is reserved for names, route numerals and the action. There are no capitalized body sentences, rounded rail cards, key badges or text glows. The scene veil is 96% black at the left, 94% beneath the rail, fading to clear at 43% of the screen. It sits below map labels so it cannot dim them. The 540 px text area has 40 px margins; the map framing reserves the same width.

There are 17 measured rail states at each resolution, with zero overlapping visible text allocations. The longest cases are Asteroid frontier, Unknown signal, Warden of the Roll Berthold Harrowgate the Frost-Scarred, and Resolve of the Reach. These are measured from the game's tables, including every generated Nemesis title/name/scar combination. Long names wrap whole words and do not use ellipses. The seven- and twelve-ship stress pictures are explicit fixtures, not claims about a legal fleet or campaign outcome.

| State | Visible fleet rows at 1080 | At 1440 |
|---|---:|---:|
| Simple stop, seven long ship names | 7 | 7 |
| Sector I, three routes | 3 | 3 |
| Four-route fork | 2 | 3 |
| Four routes plus all longest names, seven or twelve ships | 1 | 1 |

Routes receive their full height first. The fleet then uses whole 36 px rows, up to seven, and scrolls for the remainder. The last ship is captured after scrolling. The route group also supports scrolling for names longer than the shipped cases. The four routes remain in order, with each picked in turn at seed 2's real fork. Mouse hover and keyboard focus both fill the action.

## Checks and impact

- node contrib/opus/tools/run_all_checks.js: exit 0, no new failures. Existing baseline: seven findings IDs and twelve constant differences remain KNOWN.
- ui_spec_tests.js: 125/125 PASS, including fonts, font jobs, text floor, ember, no lime and square rail styling.
- Godot map_readonly_test.gd: 42/42 PASS, including missing commander records and unchanged run, save, profile and random stream.
- Godot map_travel_test.gd: PASS, including route states, three sector layouts, 30/60/144 fps flight, arrival and skips.
- Godot load_all.gd: 154 scripts and 11 scenes, zero failures.
- Six-faction purchase exercise: 24/24 PASS. Building the row changes no state; the same factionVerb action spends its original price and disables the purchase as Used this sector.
- Native captures at both resolutions: exit 0, zero SCRIPT ERROR lines, overlap checks PASS, all required PNGs present at the correct size.
- git diff --check and the changed-text em dash scan: PASS.

No campaign rules, tables, JS oracle, saves or random streams changed. Glass Shell's existing colors and faces remain for other screens. marker() is used only by the map and its key. Shared shipyard readouts retain their existing behavior. The new font files came from google/fonts ofl/bigshouldersdisplay and ofl/barlow, with both OFL texts.

Moved detail: full conditions and run notes stay in Map key; objective and fight details remain on route hover; Nemesis traits and persona remain in Dossier; ship classes, captains and refits remain in Fleet; fleet repair advice is on the Fleet and refits hover. The Map key now correctly says flown routes are hidden.

No commit or push. Battle parity, a bot battle and the battle performance bench were not repeated: this change is map presentation and the moved fleet button, and the battle code and its theme values are unchanged. Native capture logs include sandbox denials for the Windows certificate store and optional user shader/world-bake cache writes; captures completed successfully using the in-memory bakes. No Board ruling is required; the one-row extreme fleet case is shown explicitly for review.
