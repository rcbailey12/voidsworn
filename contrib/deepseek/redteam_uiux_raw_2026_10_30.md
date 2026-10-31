UI/UX red team report: Voidsworn core pack (Oct 30, 2026)

Seat: interface, flow, and accessibility. Evidence base: the four syntheses, the assembled tutorial set, the accessibility review, and the ui3d.js excerpts in the pack.

Findings, ranked by severity

1. The shipped build still fires on click into an unplanned move, and the fix is deferred to Godot (OBSERVED)

What breaks. The blocker complex in the battle UI synthesis is present in the playable truth today. Clicking an out of range enemy does not just fire: "attackMovePlan chooses the destination hex" and "the player never previews the destination." The synthesis states the worst case plainly: "the worst case is not a wasted shot, it is an unplanned move." Fire all is the unarmed default and irreversible, and inspect and fire share one gesture. The phased activation ruling is the fix direction, but the browser build is frozen to break fixes only and the Godot tree is not yet at full run parity.

Evidence. Battle UI synthesis: "attackMovePlan chooses the destination hex"; "the player never previews the destination"; "the worst case is not a wasted shot, it is an unplanned move"; "Fire all is the unarmed default and is irreversible." Platform state: browser build "frozen to break fixes only since Oct 26, 2026"; Godot migration is "one playable battle, then the full run."

Cost. The only build a player can play today ships the commitment layer defect the council already graded FRICTION. Every day of migration is a day new players learn the game through the unplanned move. The ruling is right; the migration timeline is the cost the ruling does not price.

2. The phased activation ruling buys commitment with the speed the legs protected (INFERRED)

What costs more than expected. The synthesis says the pre-commit information layer is "best in class" and "any remedy for the blocker complex must preserve the speed this layer enables; that is why the legs reach for a confirm or a preview rather than a modal redesign." Phased activation is the heaviest of the three memo solutions: a move beat with free rehearsal, then a fire beat with an explicit Fire control. It adds a beat to every activation. At the typical 20 ship battle, that is roughly 20 extra beats per round. The legs' own remedy family included a single confirm on fire all and attack move, which preserves the one click rhythm; the ruling chose the two beat model.

Evidence. Battle UI synthesis: "Any remedy for the blocker complex must preserve the speed this layer enables"; "the legs reach for a confirm or a preview rather than a modal redesign." Ruling addendum: "a move beat with free rehearsal and inspect-only enemy clicks, then a fire beat."

Cost. The information layer that the council graded best in class becomes a two step surface. If the player now pays a beat to move and a beat to fire, the hover tooltip speed that Qwen called the design's centrepiece is no longer the pace of the game. I am not reopening the ruling. I am reporting that the ruling's chosen remedy is the one the synthesis explicitly warned against on speed grounds, and the memo's lighter options were on file.

3. The campaign layer receives zero contextual teaching by construction (OBSERVED)

What breaks. The tip system cannot reach the map. The firstrun synthesis states: "tutorialCheck returns whenever there is no battle object or the app shell is up, and the map screen nulls the battle object." The consequence is structural, not a writing weakness: "the map, routing, patrons, command points, and run structure receive zero contextual teaching." The ui3d.js excerpt confirms the guard: if(!B||B.showcase||B.over||document.body.classList.contains('app-on')||document.querySelector('.intro')) return;

Evidence. Firstrun synthesis: "tutorialCheck returns whenever there is no battle object or the app shell is up"; "the map, routing, patrons, command points, and run structure receive zero contextual teaching." Code: the tutorialCheck guard returns on !B and on app-on.

Cost. The campaign is the roguelite. Routing, the Nemesis clock, boons, patrons, and the generational contract are the decisions the run is made of, and the game teaches none of them at the moment of decision. The assembled c_ set is the copy half of the answer; it has no delivery surface on the map, so it cannot ship as tips until the checker is extended or a map hint line exists.

4. The Nemesis loss debrief is ruled and unbuilt, so the guaranteed loss teaches nothing (OBSERVED)

What breaks. Ryan ruled on Oct 29 that "a lost meeting still teaches a weakness on the debrief." At this pin the win branch reveals a weakness and the loss branch does not: "the loss branch returns only the 'drove you off' line." The meeting a first run player is guaranteed to lose, and per the Oct 28 ruling is supposed to lose, delivers neither the weakness nor the fiction that a lesson was carried home. The one mitigation is that a weakness the player triggers during the battle stays revealed even in defeat; the debrief cannot teach.

Evidence. Firstrun synthesis: "a lost meeting still teaches a weakness on the debrief"; "the loss branch returns only the 'drove you off' line"; "the meeting a first-run player is guaranteed to lose ... delivers neither the weakness nor the fiction."

Cost. This is the highest leverage first run fix on the file and it is ruled. The design's learning fiction depends on the loss teaching. A player who loses the forced meeting and reads a single line has no evidence the game is a curriculum, which is exactly the frame the Oct 28 learning ruling asked for.

5. The line that teaches the controls is the worst offender on size and contrast (OBSERVED)

What breaks. The accessibility review grades text FAIL. The agreed facts: "battle HUD body text is 14-15 px at 1080p against an 18 px PC guideline floor," the scaling floor takes the help line to about 7 px, there is no user text size control, and "the controls help line (#7d7768) computes to roughly 3.1:1 to 4.2:1" against plausible backgrounds, under the 4.5:1 bar. The review's own summary is the finding: "When the line that teaches the controls is the worst offender on both size and contrast, PARTIAL understates it."

Evidence. Accessibility review: "battle HUD body text is 14-15 px at 1080p against an 18 px PC guideline floor"; "the controls help line (#7d7768) computes to roughly 3.1:1 to 4.2:1"; "the line that teaches the controls is the worst offender on both size and contrast."

Cost. The player who most needs the help line, the one who cannot read small low contrast text, is the one the current build fails first. The review prices the fix as "one function, one settings entry, one colour change" (move to BONE2 #b3aa95, about 5.96:1 to 7.82:1). The gap between the size of the defect and the size of the fix is the indictment.

6. Input remapping is absent entirely, and the help line teaches keys that do not exist (OBSERVED)

What breaks. The accessibility review: "No [input] section, no InputMap use, no gamepad references anywhere in the pack." There is no rebind list, no named actions, and the help line reads fixed keys. Worse, the help line itself is incomplete: "the help line omits four documented keys (X ram, G board, Space hurry, V firing arcs)." The battle UI synthesis adds that keysHelp "omits R, X, G, F, T, and Home, several of them core combat inputs."

Evidence. Accessibility review: "No [input] section, no InputMap use, no gamepad references anywhere in the pack"; "the help line omits four documented keys (X ram, G board, Space hurry, V firing arcs)." Battle UI synthesis: keysHelp "omits R, X, G, F, T, and Home."

Cost. WCAG 2.1.1 failure on the input surface, and the feature the guidelines treat as basic is not present. The two help surfaces disagree about what to teach and neither is complete, so a player who needs an alternative input has neither a remap nor a trustworthy key list to start from.

7. Title and settings buttons set FOCUS_NONE and an empty focus stylebox, blocking keyboard and controller menu navigation outright (OBSERVED)

What breaks. The accessibility review records: "title.gd sets Control.FOCUS_NONE and an empty focus stylebox on every title and settings button (lines 100, 116), which blocks keyboard and controller menu navigation outright." The review marks this as an Argon catch no other leg saw, and prices it as "a two-line change with an outsized effect." In the same pass, slider changes persist only on drag ended, not on value change.

Evidence. Accessibility review: "title.gd sets Control.FOCUS_NONE and an empty focus stylebox on every title and settings button"; "which blocks keyboard and controller menu navigation outright"; "a two-line change with an outsized effect."

Cost. A keyboard or controller player cannot reach the settings that contain the accessibility options. The fix is two lines. This is the highest ratio of player exclusion to fix effort in the pack.

8. Board zones carry opposite meanings by hue alone, and the second channel exists in code but the legend is collapsed (OBSERVED)

What breaks. The accessibility review: "Exit green and guard red sit at about 1.46:1 and 1.23:1 composited, a red-green pair carrying opposite meanings by hue alone." WCAG 1.4.1. The ui3d.js excerpt shows a text channel does exist in ZONE_INFO (exit col #7dff9b, texit and guard col #e07a70, each with an fx string), but the HUD synthesis records that "the Engagement legend is collapsed and unlabeled in all nine images," so in practice the color only signal is the one the player sees.

Evidence. Accessibility review: "Exit green and guard red sit at about 1.46:1 and 1.23:1 composited"; "a red-green pair carrying opposite meanings by hue alone." HUD synthesis: "the Engagement legend is collapsed and unlabeled in all nine images." Code: ZONE_INFO has fx strings but the legend is the collapsed surface.

Cost. Two board zones with opposite tactical meanings are distinguished only by a red green pair that a red green colorblind player cannot separate. The remedy is partly built and not surfaced, which makes the collapse the defect, not the absence of a second channel.

9. Move preview omits threat, turns, and path, so the phased model rehearses without the information that prevents the unplanned move (OBSERVED)

What breaks. The HUD synthesis: "Both move shots give cost and guns-bearing only." The move preview does not show where the enemy can hit next turn, how many turns the route costs, or the path itself. The phased activation ruling adds "free rehearsal" and "odds computed from the real hex and an explicit Fire control," but it does not add threat, turns, or path to the move preview. The attack move preview sub decision the battle UI synthesis named ("destination ghost with odds computed from the arrival hex") is a fire side answer, not a move side answer.

Evidence. HUD synthesis: "Both move shots give cost and guns-bearing only." Battle UI synthesis: "the attack-move preview (destination ghost with odds computed from the arrival hex) is a sub-decision." Ruling addendum: "a move beat with free rehearsal."

Cost. The move beat is where the unplanned move is prevented, and the preview the player rehearses on still lacks the threat overlay, the turn count, and the path. Free rehearsal of an under informed preview rehearses the same mistake. The threat map exists (R, Threat) but the move preview does not fold it in.

10. The first battle tutorial card contradicts the screen it teaches on (OBSERVED)

What breaks. The HUD synthesis: "It says the Command glows gold; in every image Command is dark and Pass or End turn is gold. It also covers the approach lane and the carrier plates." The ui3d.js TIPS table carries the contradiction in the resolve entry: "it glows gold on the strip." The synthesis grades it: "First-battle text teaching a wrong cue is the highest-leverage single fix in this audit."

Evidence. HUD synthesis: "It says the Command glows gold; in every image Command is dark and Pass or End turn is gold"; "First-battle text teaching a wrong cue is the highest-leverage single fix in this audit." Code: TIPS resolve says "it glows gold on the strip."

Cost. The first card a new player reads in the first battle teaches a cue the screen does not show, and the card also covers the lane and the carrier plates. A tutorial that lies about the interface in minute one is worse than no tutorial, because the player now has a wrong model to unlearn.

Verdict

NOT READY for the commitment layer and the first minute, with the information layer best in class and the accessibility foundations half built. The single most important attack: the phased activation ruling fixes the unplanned move but buys commitment with the speed the legs protected, and the only playable build still ships the defect the ruling defers.

Not checked

I could not judge the rendered luminance swing, red saturation, or flashing area of the effects. The accessibility review itself says this needs a measurement pass and the pack contains a count contract, not measurements, so the PARTIAL on flashing stands unverified from my seat.

I could not judge the browser build's text scale or contrast firsthand. The accessibility review's text findings are on the Godot tree; the browser build's help line and HUD type sizes are not in the pack's code excerpts, so the shipped build's reading surface is outside my evidence.

I could not judge controller or gamepad behavior. No gamepad references exist in the pack, so the absence is observed but the experience of a controller player is inferred from the missing InputMap and the focus defect.

I could not judge the play feel of phased activation, because the Godot tree has one playable battle and the two beat model is not built. Finding 2 is an inferred cost from the synthesis's own protect item, not a playtest.

I could not judge which G2 capture batch is current. The HUD synthesis states "the pack does not say which batch is current," so cross capture drift observations are weighed as drift, not as the shipped state.

I could not judge whether the assembled c_ set reaches the map. The copy exists and the delivery surface does not, and the pack does not show a map hint line implementation, so finding 3's fix path is inferred from the tutorialCheck guard.
