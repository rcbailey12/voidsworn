Accessibility Pass: Voidsworn (Job 7)
Reviewer leg: blind review, accessibility focus.
Date: 2026-10-27.
Evidence pack: muse_2026-10-26c (files and line numbers as cited below).
Guidelines consulted: Xbox Accessibility Guidelines (XAG) at learn.microsoft.com/en-us/gaming/accessibility/guidelines; Game Accessibility Guidelines (GAG) at gameaccessibilityguidelines.com; WCAG 2.1 at w3.org/TR/WCAG21. All guideline citations in this review are from my training knowledge of those documents, not from pages opened during this session. I flag this so the editor knows to verify exact wording and section numbers before publication.

1. Colour-blind readability
Verdict: PARTIAL
What the pack shows
Faction identity on ship hulls is carried primarily by tint. look_gd.txt lines 10 and 27-28 describe a per-faction hull fix that gives dark-hulled factions (Chorus, Deathless named) a Fresnel rim in the faction tint plus an albedo lift. The design record (quoted in the pack, not from these files) says shields keep faction colours, interface shield bars are cyan, and the hex grid is cyan.
Non-colour identifiers do exist: glyph crests per faction (godot/ui/career/crest.gd draws crest shapes), admiral portraits, and names in text on HUD and campaign screens. These are listed in the pack under "Factions also have non-colour identifiers."
Board zone colours are defined in board_gd.txt lines 169-176, 191, 203:
Exit edge, Green, (0.49, 1.0, 0.61), Alpha 0.16
Guard / transport exit, Red, (0.88, 0.48, 0.44), Alpha 0.16
Hold / relay hex, Gold, (0.82, 0.65, 0.29) fill; (1.0, 0.82, 0.4) ring, Alpha 0.3 / 0.9
Nebula terrain, Purple, not specified, UNSURE
Debris terrain, Tan, not specified, UNSURE
Storm terrain, Yellow, not specified, UNSURE
Base hex ring, Blue, (0.45, 0.65, 1.0), Alpha 0.07
The pack explicitly lists three UNSURE items here: whether zone hexes also carry icons or text labels in the Godot build; whether the threat-map overlay (R key) encodes danger by colour alone; and the exact faction tint values (they live in data files the pack does not include).
What the guidelines say
XAG 105 ("Use more than color to convey information," learn.microsoft.com/en-us/gaming/accessibility/guidelines) states that colour should not be the sole means of conveying information, and that shape, pattern, text, or audio should provide a parallel channel. GAG's basic-level item "Use more than one cue to convey information" (gameaccessibilityguidelines.com, under the "Colour" section) makes the same point for games specifically. WCAG 1.4.1 (Use of Color) applies the same principle to web content.
The most common colour-vision deficiencies are deuteranopia and protanopia (red-green confusion), affecting roughly 8% of males and 0.5% of females. The exit (green) and guard (red) zones are the pair most at risk. At alpha 0.16, both are very translucent overlays, which reduces the saturation signal further and makes them harder to separate even for typical vision.
Assessment
Factions are in reasonable shape. Crests, portraits, and names provide non-colour channels that are present at the same moment the faction identity matters (the HUD, the campaign map, the battle screen). The hull tint is supplementary. This satisfies the "more than one cue" requirement for faction identity, provided the crests and names are visible during the same gameplay moment the tint is the distinguishing feature. The pack does not confirm whether crest glyphs appear on the battle board itself or only on campaign/UI screens, so that is a minor gap.
Board zones are the weak point. The pack shows colour definitions for exit, guard, hold, terrain, and base hexes but does not show any icon, label, or pattern overlay on those hexes. The three UNSURE items the pack flags are exactly the right ones: if there are no labels or icons, then a deuteranope cannot reliably tell exit from guard, and a tritanope (blue-yellow confusion, rarer) would struggle with the gold-vs-storm-yellow and blue-base-vs-nebula-purple pairs. The very low alpha values (0.16 for exit and guard, 0.07 for base) make colour-only identification even harder.
The threat-map overlay (R key) is UNSURE. If it encodes danger level by colour gradient alone, that is a second colour-only channel.
What would move this to PASS: confirm whether zone hexes carry any non-colour marker (icon, letter, border pattern). If they do not, add one. A small text label ("EXIT," "GUARD," "HOLD") or a distinct border dash pattern per zone type would cost little in a hex-grid renderer. Adding a colour-blind palette toggle to the settings dictionary (currently absent, confirmed by the pack's "NOT in the settings list" section) would be a secondary improvement.

2. Flashing and photosensitivity
Verdict: PASS (with one advisory note)
What the pack shows
fx_api_md.txt section 8, lines 128-130, states:
"At most 3 counted flashes per rolling second anywhere on screen (WCAG 2.3.2). Flashes landing within 0.12 s of each other (a salvo) count as one; over the budget, flashes draw as smoke and sparks without the bright core."
reduce_flashing = true: "no counted flashes at all. Bright pops become expanding rings, particle bursts and a gentle glow rise; muzzle flashes become smoke-forward; fire flicker becomes slow breathing; effect shake halves."
FEATURES.md line 87 confirms: "Reduce flashing (WCAG) | done (G4; the setting reaches fx)." The settings panel (title_gd.txt lines 173-188) includes the "Reduce flashing" toggle. The default is false (main_gd.txt line 20).
The shake model is trauma-based and positional only (fx_api_md.txt section 7, line 123), scaled by the settings slider 0 to 1. The settings panel offers Full, Reduced (0.5), and Off.
The chair note records that an earlier commissioned review (Job A) recommended a 0.33 s salvo merge window. The implementation uses 0.12 s.
What the guidelines say
WCAG 2.3.1 (Level A, "Three Flashes or Below Threshold"): no content flashes more than three times in any one-second period, with an exception for flashes below the general flash and red flash thresholds (small area, low contrast). WCAG 2.3.2 (Level AAA, "Three Flashes"): same three-per-second cap but with no exceptions. The game's code comment cites 2.3.2, which is the stricter standard and appropriate for a full-screen game where "small area" exceptions are hard to apply.
XAG 116 ("Photosensitivity," learn.microsoft.com) requires games to avoid flashing where possible, to provide a setting to reduce or disable flashing, and to warn players if flashing cannot be fully removed. GAG's "Include a setting to disable flashing" item (Basic level) aligns.
Assessment
The 3-per-second cap matches WCAG 2.3.1 and 2.3.2. The over-budget fallback (smoke and sparks without the bright core) is a sensible degradation rather than a hard cut, and it keeps the player informed that something happened without the flash. The reduce_flashing = true mode removes all counted flashes and replaces them with non-flashing alternatives (rings, particles, glow, smoke, slow breathing), which goes beyond the minimum. The setting is reachable from the settings panel and from the in-battle menu (FEATURES.md line 13). The default being false is acceptable as long as the option is easy to find, though GAG and some Xbox guidance encourage defaulting protective settings to on, or at least prompting on first launch. The pack does not indicate whether any first-launch prompt exists, so that is UNSURE.
On the merge window: 0.12 s versus the earlier recommendation of 0.33 s. With a 0.12 s window, flashes 0.13 s apart count as separate. You could get three counted flashes at t = 0, 0.13, 0.26 s, all within a quarter-second. That is within the letter of WCAG (3 in one second), but it is a denser burst than the 0.33 s window would allow (which would merge all three into one). The 0.33 s window was more conservative and closer to the spirit of the guideline. The 0.12 s window is not a violation, but it is a weaker safeguard. I note it as advisory, not a fail.
The shake reduction in reduce mode (halving) is a good secondary measure, since large-amplitude screen shake can be a vestibular trigger even without a luminance flash.
Advisory: consider widening the salvo merge window toward 0.33 s, and consider defaulting reduce_flashing to true or adding a first-launch prompt. Neither is required for a PASS verdict under current guidelines.

3. Text size and contrast
Verdict: PARTIAL
What the pack shows
All UI text is scaled through s(v) = round(v * k), where k = clamp(viewport_height / 1080, 0.6, 2.2). This is in title_gd.txt lines 30-34 and hud_gd.txt line 118. There is no user-facing text size setting (confirmed by the pack's "NOT in the settings list" section).
Base sizes at k = 1 (1080p):
Theme default, 15, hud_gd.txt line 125
Buttons, 14, hud_gd.txt line 148
Rich text, 14, hud_gd.txt lines 153-154
Battle log, 13, hud_gd.txt lines 537-538
Controls help line, 12, hud_gd.txt line 470
Settings row labels, 18, title_gd.txt, _row
Settings title, 30, title_gd.txt
At the k floor of 0.6 (window about 650 px tall), the 12 px help line renders at about 7 px and the 13 px log at about 8 px.
Colours given: the controls help line is #7d7768 (a muted grey-tan) at size 12 on the game's dark background (hud_gd.txt line 470). Other HUD text uses a bone tone (BONE2) for the persistent hint line (hud_gd.txt line 651). The pack does not give the hex value for BONE2 or for the dark background, so I can compute only for #7d7768.
Fonts: Barlow Semi Condensed (Regular, Medium, SemiBold) for UI text; UnifrakturMaguntia (a blackletter display face) for headings. Both in godot/ui/battle/fonts/ with OFL licences. The settings title uses the blackletter face at size 30.
Contrast computation for #7d7768
RGB: (125, 119, 104).
Relative luminance (WCAG formula):
R: 125/255 = 0.4902; linearised: ((0.4902 + 0.055)/1.055)^2.4 ≈ 0.2051
G: 119/255 = 0.4667; linearised: ((0.4667 + 0.055)/1.055)^2.4 ≈ 0.1845
B: 104/255 = 0.4078; linearised: ((0.4078 + 0.055)/1.055)^2.4 ≈ 0.1441
L_text = 0.2126(0.2051) + 0.7152(0.1845) + 0.0722(0.1441) = 0.0436 + 0.1320 + 0.0104 = 0.1860
The pack says "the game's dark background" without giving a hex. If the background is pure black (L = 0):
Contrast = (0.1860 + 0.05) / (0 + 0.05) = 0.236 / 0.05 = 4.72 : 1
If the background is a typical dark UI grey, say #1a1a1a (L ≈ 0.0104):
Contrast = (0.186 + 0.05) / (0.0104 + 0.05) = 0.236 / 0.0604 ≈ 3.91 : 1
WCAG 1.4.3 (Contrast, Minimum, Level AA) requires 4.5:1 for normal text and 3:1 for large text (at least 18 pt / 24 px, or 14 pt bold / 18.67 px). At 12 px rendered size, this is normal text. Against pure black it scrapes past 4.5:1. Against any background lighter than pure black, it drops below 4.5:1. At k = 0.6 the text is 7 px, well below any "large text" threshold, so the 4.5:1 requirement applies.
I cannot compute the BONE2 contrast because the pack does not give its hex value. UNSURE.
What the guidelines say
XAG 107 ("Text should be easy to read," learn.microsoft.com) recommends a minimum text height of 28 pixels at 1080p for body text (roughly 1.5% of screen height) and calls for a text-size option. GAG's "Provide options to adjust text size" item sits at the Intermediate level. WCAG 1.4.4 (Resize Text, Level AA) requires text to be resizable up to 200% without loss of content or function.
The 28 px recommendation at 1080p is a soft guideline, not a hard floor, but it gives a benchmark. The game's largest common text is 15 px (theme default) and 14 px (buttons, rich text), well below 28 px. The 12 px help line and 13 px battle log are smaller still. At k = 0.6, 7 px and 8 px are effectively unreadable for most players.
Assessment
The window-height scaling is a reasonable engineering choice and handles the common case (fullscreen at native resolution) well. The clamp range 0.6 to 2.2 covers 650 px to 2376 px window heights. The problem is the floor: at 0.6, the smallest text becomes 7 px. A minimum-size clamp per element (say, never below 12 px rendered) would fix the worst case without changing the scaling model.
The absence of a user text-size override is the bigger gap. A player on a 1080p monitor who finds 14 px too small has no recourse. XAG 107 and GAG both call for this.
The #7d7768 help-line colour is borderline. Against a pure black background it passes 4.5:1 by a thin margin (4.72:1). Against any slightly lighter dark background it fails. The pack does not pin down the background colour, so the exact result is UNSURE, but the margin is uncomfortably small. The blackletter display font (UnifrakturMaguntia) at size 30 for the settings title is a legibility concern for a decorative face, but at 30 px it is large enough that the risk is low.
What would move this to PASS: add a user text-size multiplier to the settings dictionary (even a simple Small / Normal / Large toggle that adjusts k or the base sizes); clamp the minimum rendered size at 12 px; verify and if needed lighten the help-line colour against the actual background hex.

4. Input remapping
Verdict: NOT PRESENT
What the pack shows
project_godot.txt has no [input] section: no custom input actions are defined at project level. No InputMap use appears anywhere in the attached code. No joypad, gamepad, or controller references exist in main_gd, title_gd, hud_gd, fx_api_md, look_gd, or board_gd (the pack records a grep with zero hits). The settings dictionary (main_gd.txt line 20) and the settings panel (title_gd.txt lines 173-188) contain no remapping UI.
The controls are documented in hud_gd.txt line 470 (keys_text): click a gold hex to move, click an enemy to fire, Q/E turn, 1-6 pick a weapon, B brace, Tab next ship, Enter end activation, Esc cancel; right-drag orbit, left-drag or WASD pan, wheel zoom, T top-down, R threat map, F focus, Home reset view.
What the guidelines say
XAG 101 ("Support remapping of controls," learn.microsoft.com) requires that all input bindings be remappable unless there is a core gameplay reason not to, and that remapping be available in-game without editing config files. GAG lists "Remappable controls" as a Basic-level guideline for most game types.
Assessment
There is no remapping of any kind. The controls are fixed. The pack confirms this by the absence of any remapping entry in the settings dictionary and the settings panel.
The code structure is relevant to how hard a fix would be. In Godot 4, the standard route for remappable input is the InputMap system: you define named actions in the project settings ([input] section of project.godot), bind physical keys to those actions, and then query them in code with Input.is_action_pressed("action_name") or Input.is_action_just_pressed("action_name"). The player-facing remapping UI then rewrites the bindings via InputMap.action_erase_events and InputMap.action_add_event.
The pack states there is no [input] section and no InputMap use. This means the current code almost certainly uses direct key checks (Input.is_key_pressed(KEY_Q), etc.) or _input/_unhandled_input event matching on specific keys. That structure is a blocker for easy remapping: every hardcoded key reference would need to be converted to an InputMap action before a remapping UI could work. It is not a fundamental architectural problem, but it is a refactor that touches every input handler.
The minimum viable step would be:
Add an [input] section to project.godot defining named actions for each control (move_select, fire, turn_cw, turn_ccw, weapon_1 through weapon_6, brace, next_ship, end_activation, cancel, orbit, pan, zoom, top_down, threat_map, focus, reset_view).
Replace direct key checks in hud.gd and title.gd with Input.is_action_pressed / is_action_just_pressed calls.
Add a remapping screen to the settings panel that lists each action and lets the player press a new key.
Persist the bindings in user://settings.json alongside the existing settings.
This is a moderate-effort task in Godot 4 but the current code structure (no InputMap, direct key references) means it is a refactor, not a bolt-on.

5. Hold-vs-toggle and input burden
Verdict: PARTIAL
What the pack shows
Orbit is right-drag (hold). Pan is left-drag (hold) or WASD (hold). No toggle alternative for either is offered in settings (confirmed by the pack's "NOT in the settings list" section: "any hold-vs-toggle option"). Targeting (which hex, which enemy) is mouse-click driven per the help text. The pack marks it UNSURE whether any keyboard-only path can complete a full activation.
All other inputs are single-press: Q/E turn, 1-6 weapon select, B brace, Tab next ship, Enter end activation, Esc cancel. No simultaneous key combinations are documented. No time-limited inputs are documented.
The game is turn-based. Battles resolve activations one at a time. The follow-camera option can be turned off.
What the guidelines say
XAG 102 ("Provide alternatives to holding buttons," learn.microsoft.com) asks for a toggle or sticky option wherever a control requires a sustained hold, especially for camera, movement, or aim. GAG's "Provide options to reduce the number of simultaneous inputs required" and "Provide options to change held buttons to toggles" items (Basic and Intermediate levels) cover the same ground.
XAG 109 and GAG also note that turn-based games inherently reduce time-pressure burden, and this should be credited.
Assessment
The turn-based structure is a significant accessibility credit. There is no time limit on decisions, no reaction-speed requirement, and no need to perform actions while under pressure. This addresses the largest class of input-burden concerns (speed, timing, dual-tasking) by design.
The hold-drags for orbit and pan are the main issue. A player with limited grip strength, a tremor, or a one-handed setup must sustain a mouse button press while moving the mouse. For camera controls specifically, this is a common pain point. The WASD pan alternative is also hold-based (you hold W while pressing A or D), so it does not remove the hold requirement; it just moves it to the keyboard.
Mitigating factors: orbit and pan are camera controls, not gameplay-critical actions. The player can stop orbiting or panning at any time without losing their turn or their ship. The turn-based structure means there is no penalty for pausing the drag. The pack does not describe any input that requires holding a key while pressing another key simultaneously, and no input that requires precision timing.
The UNSURE item about keyboard-only activation is important. If the player cannot complete a move-and-fire sequence without the mouse (because hex selection and enemy targeting are click-only), then a player who cannot use a mouse at all is locked out of core gameplay. The keyboard commands (Q/E, 1-6, B, Tab, Enter) handle ship orientation, weapon selection, bracing, ship cycling, and activation ending, but the pack does not confirm that hex selection and enemy targeting have keyboard equivalents. This is the single most important UNSURE in the input section.
What would move this to PASS: add a toggle mode for orbit and pan (click to start, click to stop, or a modifier-key toggle); confirm and if needed implement a keyboard-only targeting path; consider adding the hold-vs-toggle option to the settings panel.

6. Other findings
6a. Captions and audio-only information
Verdict: PARTIAL (structural gap), with a critical UNSURE
The pack records a grep for "caption" and "subtitle" across all attached files with zero hits. No captions system is documented in FEATURES.md. Sound and music have separate on/off toggles and volume sliders (settings dictionary, main_gd.txt line 20; settings panel, title_gd.txt lines 173-188). FEATURES.md line 96 notes battle music varies by faction with intensity layers.
The critical UNSURE from the pack: "Whether any gameplay-critical information is carried by audio alone is UNSURE from this pack."
XAG 108 ("Provide captions for dialogue and audio cues," learn.microsoft.com) and GAG's "Subtitles for all speech" (Basic level) require captions for any information conveyed by audio. If a weapon firing sound, a shield-break audio cue, or a faction-identification sting is the only signal, a deaf or hard-of-hearing player misses it.
The separate sound and music toggles are good (they let a player keep music but disable SFX, or vice versa, which helps players with auditory processing difficulties). But without captions or visual equivalents for audio cues, the system is incomplete. The pack cannot confirm or deny the existence of audio-only information, so I tag the gameplay-critical question as UNSURE.
6b. Motion comfort (shake, camera follow, cut-ins)
Verdict: PASS
The pack shows three independent motion-comfort controls:
Screen shake: Full / Reduced (0.5) / Off (settings panel; trauma model per fx_api_md.txt section 7, line 123).
Follow enemy activations: toggle on/off (settings panel; default true per main_gd.txt line 20).
Cut-ins: Key moments / Every attack / Off (settings panel; default "key" per main_gd.txt line 20).
XAG 116 and GAG's "Provide options to reduce or remove shaking" and "Provide options to reduce camera movement" items are addressed. The three-level shake control (full, half, off) is better than a binary toggle. The cut-in control lets a player who is sensitive to rapid camera cuts reduce them to key moments only or disable them entirely. The follow toggle stops the camera from tracking enemy turns, which removes an involuntary camera motion.
The reduce_flashing mode also halves effect shake (fx_api_md.txt section 8), providing a secondary shake reduction path.
This is well-implemented. No gaps found in the pack.
6c. Game speed control
Verdict: PARTIAL
The speed setting offers Normal (1.0) and Fast (0.45, meaning animations play at 0.45x duration, i.e. faster). There is no slower-than-normal option (confirmed by the settings panel listing only "Normal / Fast 0.45").
XAG 112 ("Provide options to adjust game speed," learn.microsoft.com) and GAG's equivalent item note that some players need more time, not less. A slower speed (say 1.5x or 2.0x animation duration) would help players with cognitive load, reading speed, or motor-speed concerns. The game is turn-based, which already removes time pressure on decisions, but animation speed still affects how quickly results resolve and how much time the player has to read battle-log entries or observe what happened.
The pack does not indicate whether the Fast setting affects the player's decision phase or only animation playback. If it is animation-only, the turn-based structure already protects the player. UNSURE.
6d. Difficulty options as accessibility
Verdict: PARTIAL
The AI difficulty setting offers Veteran and Standard (settings panel; default "veteran" per main_gd.txt line 20). The pack does not describe what Standard changes relative to Veteran (damage values, AI decision quality, fog of war, etc.), so I cannot assess whether it functions as an effective accessibility ramp.
XAG 111 ("Provide difficulty options," learn.microsoft.com) and GAG's difficulty item note that difficulty settings can serve players who need reduced cognitive or mechanical load. Two options is a start. The pack does not indicate whether there is a tutorial, a practice mode, or a "story mode" that further reduces challenge. UNSURE.
The Battle tips toggle (default true) is a small but useful accessibility feature: it provides contextual guidance that the player can leave on or turn off. The pack does not describe what the tips contain. UNSURE.
6e. Fullscreen and graphics quality
The fullscreen toggle and graphics quality setting (Max / High / Low) are present. The pack notes that graphics quality "is stored but does nothing yet" (FEATURES.md line 13). This is not an accessibility defect per se, but the non-functional quality setting could mislead a player into thinking they have reduced visual complexity when they have not. Minor note, not scored.

(a) Ranked fixes
Ordered by how much they unblock or protect players per unit of build effort.
Add non-colour markers to board zones (exit, guard, hold, terrain). A text label or distinct border pattern per zone type. This unblocks the most common colour-vision deficiency (red-green) for the most gameplay-critical spatial information. Low build effort in a hex-grid renderer. Addresses XAG 105, GAG colour item.
Add a user text-size multiplier to settings. Even a three-step toggle (Small / Normal / Large) that scales the k multiplier or the base sizes. This unblocks low-vision players on any resolution. Moderate build effort, mostly UI plumbing. Addresses XAG 107, GAG text-size item, WCAG 1.4.4.
Clamp minimum rendered text size at 12 px. Prevents the 7 px and 8 px floor cases. Very low build effort (change the clamp in the s() function or add a per-element floor). Addresses XAG 107.
Implement InputMap actions and a remapping screen. Refactor direct key checks to InputMap actions, add a remap UI to the settings panel, persist bindings. Moderate-to-high build effort due to the refactor, but it is the standard Godot pattern and unblocks any player whose default key layout conflicts with their setup or physical ability. Addresses XAG 101, GAG remappable controls.
Confirm and implement a keyboard-only targeting path. If hex selection and enemy targeting are mouse-only, add keyboard equivalents (Tab-cycle targets, arrow-key hex selection, Enter to confirm). This unblocks players who cannot use a mouse at all. Effort depends on how deeply mouse-click is woven into the targeting flow. Addresses XAG 101, GAG.
Add a hold-vs-toggle option for orbit and pan. A settings toggle that changes right-drag orbit and left-drag pan to click-to-start / click-to-stop. Low build effort. Addresses XAG 102, GAG held-input item.
Verify and fix the help-line contrast. Determine the actual background hex. If #7d7768 falls below 4.5:1 against it, lighten the text colour. Very low build effort. Addresses WCAG 1.4.3.
Add a slower game speed option (e.g. 1.5x or 2.0x animation duration). Low build effort if the speed multiplier is already a single variable. Addresses XAG 112, GAG speed item.
Widen the salvo merge window from 0.12 s toward 0.33 s. One-line change in the effects layer. Does not change WCAG compliance but provides a more conservative photosensitivity safeguard. Addresses the spirit of XAG 116.
Investigate audio-only information and add captions or visual equivalents if found. Cannot be scoped until the UNSURE is resolved. Addresses XAG 108, GAG subtitles item.

(b) UNSURE list
These are items the pack does not establish, carried forward from the pack's own UNSURE tags plus any I identified during review.
Whether zone hexes carry icons or text labels in the Godot build (pack, Colour section).
Whether the threat-map overlay (R key) encodes danger by colour alone (pack, Colour section).
The exact faction tint values; they live in data files not included in the pack (pack, Colour section).
Whether any gameplay-critical information is carried by audio alone (pack, Audio section).
Whether any keyboard-only path can complete a full activation (pack, Input section).
The hex value of the dark background used behind the controls help line, needed for a definitive contrast ratio (my note; the pack gives the text colour but not the background).
The hex value of BONE2 used for the persistent hint line (my note; pack names it but does not give the value).
Whether a first-launch prompt for the reduce-flashing setting exists (my note; not addressed in the pack).
Whether the Fast speed setting affects the player's decision phase or only animation playback (my note).
What the Standard AI difficulty changes relative to Veteran, and whether it functions as an accessibility ramp (my note).
What the Battle tips toggle controls in practice (my note).
Whether crest glyphs appear on the battle board itself or only on campaign/UI screens (my note; the pack says crest.gd draws them but does not say where they are displayed during battle).

(c) Verdicts
Colour-blind readability: PARTIAL. Factions have crests, portraits, and names as non-colour channels, which is good; board zones appear to rely on colour alone, with the critical exit-green vs guard-red pair sitting at very low alpha, and the pack's own UNSURE items about zone icons and the threat map prevent a PASS.
Flashing and photosensitivity: PASS. The 3-per-second cap matches WCAG 2.3.1/2.3.2, the reduce-flashing mode removes all counted flashes and substitutes non-flashing effects, the setting is reachable from both the title screen and the in-battle menu, and the over-budget fallback degrades gracefully; the 0.12 s merge window is tighter than the earlier 0.33 s recommendation but does not violate the guideline.
Text size and contrast: PARTIAL. The window-height scaling is sound and the clamp range is wide, but the 0.6 floor produces 7 px text, there is no user text-size override, and the #7d7768 help-line colour is at or below the 4.5:1 threshold depending on the (unspecified) background.
Input remapping: NOT PRESENT. No InputMap actions, no remapping UI, no controller support; the code's direct-key-check structure is a refactor blocker for the standard Godot remapping path.
Hold-vs-toggle and input burden: PARTIAL. Orbit and pan are hold-drags with no toggle alternative, but the turn-based structure removes all time pressure, the non-camera inputs are single-press, and no simultaneous inputs are documented; the keyboard-only targeting path is UNSURE and is the most important open question.
Other findings: PARTIAL overall. Motion comfort is well covered (shake, follow, cut-ins all have player controls, PASS). Captions are absent and audio-only information is UNSURE (PARTIAL). Speed goes faster but not slower (PARTIAL). Difficulty has two tiers but their accessibility function is UNSURE (PARTIAL).
Overall verdict: PARTIAL. Voidsworn has a thoughtful accessibility foundation (flashing budget, reduce mode, shake/cut-in/follow controls, turn-based structure, faction crests) but has significant gaps in colour-blind board readability, text sizing, input remapping, and hold-vs-toggle options that prevent a PASS. The highest-impact, lowest-effort fixes are non-colour zone markers, a text-size setting, and a minimum text-size clamp.
