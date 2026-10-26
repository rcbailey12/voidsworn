Accessibility review: Voidsworn (Godot 4.7, PC)

Scope and method. I worked only from evidence_pack_job7.md and the files it attaches. Guideline claims come from Xbox Accessibility Guidelines (XAG), Game Accessibility Guidelines (GAG), and WCAG pages that I opened during this review. Where I rely on memory rather than a page I opened, I say so. Every game claim cites the pack section and, through it, the underlying file and line.

1. Colour-blind readability of factions and danger bands

Verdict: PARTIAL

What the pack shows. Faction identity on hulls “leans on tint”: the per-faction hull fix gives dark hulls a Fresnel rim in the faction tint plus an albedo lift (evidence_pack_job7.md, “Colour: factions and danger” section, citing look_gd.txt lines 10 and 27-28). Factions also have glyph crests, portraits and names in text (crest.gd, admiral portraits, HUD names). So there is some non-colour channel for factions. But the pack does not establish that the crest or name is visible on the board at the same moment as the hull tint, when a player is deciding what to shoot. That is the moment the information is needed. The pack tags this UNSURE (evidence_pack_job7.md, “Colour” section: “whether zone hexes also carry icons or text labels” and “whether the threat map overlay (R key) encodes danger by colour alone”).

Board zones are colour-coded: exit green Color(0.49, 1.0, 0.61, 0.16), guard/transport red Color(0.88, 0.48, 0.44, 0.16), hold gold Color(0.82, 0.65, 0.29, 0.3), terrain purple/tan/yellow, base ring blue (board_gd.txt lines 169-176, 191, 203, quoted in evidence_pack_job7.md). Green against red is the classic red-green confusion pair. Without a non-colour marker on the hex itself, a player with deuteranopia or protanopia may not reliably tell an exit band from a guard band at a glance.

What the guidelines say. GAG “Ensure no essential information is conveyed by a fixed colour alone” says colour should be a back-up for text, symbol, pattern or shape, and that red-green confusion affects around 8 to 10 percent of males. It recommends presets for common types plus a custom palette option (https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-fixed-colour-alone/). XAG 102 says red and green together commonly fail for common colour blindness and should be paired with shape or text; XAG 103 covers additional channels (https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-102-contrast). WCAG 1.4.1 (Use of Colour) is the same principle: colour is not used as the only visual means of conveying information (from memory; I did not open the 1.4.1 page for this review).

Assessment. Factions have a possible non-colour path through crests and names, but the pack does not prove it is present at decision time. Zones have no proven non-colour channel. The result is PARTIAL: some support exists, but the most time-critical information (which hex is dangerous, which is the exit) may still be colour-only.

2. Flashing and photosensitivity

Verdict: PARTIAL

What the pack shows. The brief claims “at most 3 flashes per second” and that a reduce-flashing option exists. The pack confirms both claims in words: fx_api_md.txt section 8 says “At most 3 counted flashes per rolling second anywhere on screen (WCAG 2.3.2). Flashes landing within 0.12 s of each other (a salvo) count as one; over the budget, flashes draw as smoke and sparks without the bright core” (evidence_pack_job7.md, “Flashing” section). reduce_flashing = true removes counted flashes entirely and replaces them with rings, particles, glow and slower fire flicker; effect shake halves. The setting is exposed in the options panel as “Reduce flashing” (title_gd.txt lines 173-188, quoted in the pack).

The problem is the merge window. The implementation merges flashes only when they land within 0.12 seconds of each other. WCAG 2.3.2 says content must not flash more than three times in any one second period, regardless of brightness or size. A 0.12-second merge window means flashes spaced at, say, 0.13 seconds are counted separately. Seven flashes at 0.13-second spacing would still be about 7.7 flashes per second, and the counter could allow more than three before the budget bites. The earlier recommendation cited in the pack was a 0.33-second merge window (chair note in the pack, “Flashing” section). The 0.12-second window is too narrow to guarantee the stated 3-per-second cap. The cap may work for salvos that are tightly grouped, but it does not cover the whole second.

What the guidelines say. WCAG 2.3.1 (Level A) and 2.3.2 (Level AAA) both prohibit more than three flashes in any one-second period; 2.3.1 allows an exception if the flash is below the general flash and red flash thresholds, while 2.3.2 has no brightness or size exception (https://www.w3.org/WAI/WCAG21/Understanding/three-flashes-or-below-threshold; https://www.w3.org/WAI/GL/2012/WD-UNDERSTANDING-WCAG20-20120726/complete.html#14). XAG 118 sets the failure criteria at more than about three flashes per second, or flashes covering about 20 percent or more of the screen, and also flags sustained lower-intensity flashing (https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-118-photosensitivity). GAG “Avoid flickering images and repetitive patterns” uses the same more-than-three-per-second and 25-percent-screen thresholds and recommends an option to disable flashing effects (https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/).

Assessment. The reduce-flashing option is real and substantial, so the game gives photosensitive players a genuine off-ramp. But the core counted-flash budget does not reliably deliver the claimed 3-per-second cap because the merge window is too short. The pack does not give the screen area of the flashes, so I cannot judge the 20-percent criterion. Verdict PARTIAL: the option is good, the default budget is not proven safe.

3. Text size and contrast

Verdict: FAIL on size; PARTIAL on contrast

Size. Every size is scaled by s(v) = round(v * k), where k = clamp(viewport height / 1080, 0.6, 2.2) (title_gd.txt lines 30-34; hud_gd.txt line 118, quoted in the pack). At 1080p, base sizes are: theme default 15, buttons 14, rich text 14, battle log 13, controls help line 12, settings row labels 18 (evidence_pack_job7.md, “Text size and contrast” section). At the k floor of 0.6, the 12-unit help line renders at about 7 px and the log at about 8 px. There is no user-facing text size setting.

WCAG 1.4.4 (Level AA) requires text to be resizable up to 200 percent without loss of content or functionality (https://www.w3.org/WAI/GL/2013/WD-UNDERSTANDING-WCAG20-20130314/visual-audio-contrast-scale#1). This game does the opposite at small window heights: the floor lets text shrink to 60 percent of base. A 7 px help line is far below any reasonable reading size. GAG “Allow the font size to be adjusted” says there is no single size that suits everyone and recommends a player-chosen font size (https://gameaccessibilityguidelines.com/allow-the-font-size-to-be-adjusted/). The Xbox guidelines also treat text display and scaling as a core area (XAG 101, referenced in the XAG index at https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-102-contrast). On size, this is a clear FAIL.

Contrast. The pack gives one concrete text colour: the controls help line is #7d7768 at size 12 on “the game's dark background” (hud_gd.txt line 470, quoted in the pack). The exact HUD background is not given, so I calculated against two plausible backgrounds. #7d7768 has relative luminance about 0.185. Against pure black it gives about 4.7:1, which passes the 4.5:1 normal-text threshold. Against the settings-panel background Color(0.047, 0.07, 0.12, 0.95) (approximately #0c121f), it gives about 4.2:1, which fails 4.5:1 for normal text. Since 12 px at 1080p is normal text, not large text (large text starts at 36 px on PC 1080p under XAG 102, or 18 pt / 24 px under WCAG), the dark-blue case fails. The exact HUD background is UNSURE, so I cannot give a final pass or fail on this one line. Other HUD text uses a bone tone (BONE2), but the pack does not give its hex, so those ratios are UNSURE.

WCAG 1.4.3 requires 4.5:1 for normal text and 3:1 for large text (https://www.w3.org/TR/2018/CR-WCAG21-20180130/#2). XAG 102 uses the same ratios and adds that text on inactive elements needs 3:1 and high-contrast mode needs 7:1 (https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-102-contrast). GAG “Provide high contrast between text/UI and background” is the same principle.

Assessment. The size system is the bigger failure: the game can make text smaller than a readable minimum and gives the player no way to make it larger. Contrast is marginal and depends on a background the pack does not specify.

4. Input remapping

Verdict: FAIL

What the pack shows. project_godot.txt has no [input] section: no custom input actions are defined at project level (evidence_pack_job7.md, “Input” section; project_godot.txt complete). There is no InputMap use and no joypad, gamepad or controller references anywhere in the attached code. The settings panel offers no remapping option (title_gd.txt lines 173-188). The controls are documented in-game as hard-coded keys: click a gold hex to move, click an enemy to fire; Q/E turn, 1-6 pick a weapon, B brace, Tab next ship, Enter end activation, Esc cancel; right-drag orbit, left-drag or WASD pan, wheel zoom, T top-down, R threat map, F focus, Home reset view (hud_gd.txt line 470, quoted in the pack).

What the guidelines say. XAG 107 says games should provide in-game remapping of all controls, regardless of platform-level remapping, including analog and digital controls, and that remapped bindings should update hints and tutorials (https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-107-input). GAG “Allow controls to be remapped / reconfigured” calls remappable controls “one of the best value accessibility features” and says in-game remapping has benefits over system-level remapping, including prompts that reflect the current mapping (https://gameaccessibilityguidelines.com/allow-controls-to-be-remapped-reconfigured/). The minimum viable step in Godot is straightforward: define actions in InputMap, replace raw key checks with Input.is_action_pressed / is_action_just_pressed, add a remapping screen that calls InputMap.action_erase_events and InputMap.action_add_event, and save the bindings in settings.json. The current structure does not help: there is no [input] section and no evidence of an input abstraction, so the battle code likely checks raw key codes. That means the refactor is real work, but it is not blocked by the engine.

Assessment. This is a straight FAIL. For a turn-based tactics game with many hotkeys, the absence of remapping excludes players with motor impairments, different keyboard layouts, or one-handed play. It is also the highest-value fix in this review.

5. Hold-versus-toggle and input burden

Verdict: PARTIAL

What the pack shows. Orbit and pan are hold-drags: right-drag to orbit, left-drag or WASD to pan (hud_gd.txt line 470, quoted in the pack). No toggle alternative is offered in settings (title_gd.txt lines 173-188). Targeting is mouse-click driven; the pack is UNSURE whether any keyboard-only path can complete a full activation (evidence_pack_job7.md, “Input” section). The game is turn-based, and battles resolve activations one at a time, with a follow-camera that can be turned off.

What the guidelines say. XAG 107 says to avoid requiring key or button holds for extended periods and to provide toggles or auto-holds where holds are unavoidable (https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-107-input). The same page also says to avoid requiring simultaneous button presses and to provide digital alternatives to analog or pointer input. GAG’s motor section includes “Avoid / provide alternatives to requiring buttons to be held down” (listed in the GAG motor guidelines; the direct page did not load for this review, so this specific wording is from the GAG index and search results, not an opened page). GAG also recommends ensuring the whole UI can be used with the same input method as gameplay.

Assessment. The turn-based structure is a genuine credit: there is no twitch timing and no need to hold a button while also aiming under time pressure. But camera orbit and pan still demand sustained dragging, and targeting is click-only. A player who cannot hold a drag, or who cannot use a mouse precisely, is stopped at the camera and at target selection. PARTIAL: the turn-based pace helps, but the control scheme still imposes hold and precision demands that a toggle and keyboard path would remove.

6. Other guideline areas with evidence in the pack

Captions and audio-only information: FAIL. There is no caption or subtitle system: grep across all attached files returns zero hits, and FEATURES.md does not document one (evidence_pack_job7.md, “Audio information” section). Sound and music have separate toggles and volume sliders, but that is mix control, not captions. XAG 106 (Captions) and GAG’s caption guidelines expect captions for meaningful audio, including gameplay-critical sound cues. The pack is UNSURE whether any gameplay-critical information is carried by audio alone, so the practical harm is UNSURE, but the absence of a caption system is a definite gap.

Motion comfort: PARTIAL. Screen shake is a positional trauma model that can be set to Full, Reduced (0.5) or Off (fx_api_md.txt section 7, line 123; title_gd.txt lines 173-188). Follow-camera can be toggled off. Cut-ins can be set to Key moments, Every attack or Off. That is good coverage for shake and camera follow. There is no option to reduce general camera motion beyond follow, and no field-of-view or motion-blur control is in the pack. XAG 113 (Motion) and GAG’s motion-comfort guidance would credit the shake and follow options but might ask for broader motion control. I did not open the specific XAG motion page for this review, so that guideline point is from memory.

Game speed: PARTIAL. Speed can be set to Fast (0.45), but there is no slower-than-normal option (title_gd.txt lines 173-188; evidence_pack_job7.md, “Input” section). For a turn-based game, fast speed is a convenience, not an accessibility necessity. But XAG 107 explicitly lists game-speed reduction as an input-burden accommodation for players using switch access or other slower input methods (https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-107-input). A slower option would help players who need more time to read the board and issue orders. PARTIAL: faster is present, slower is not.

Difficulty options as accessibility: PARTIAL. Enemy AI can be Veteran or Standard (title_gd.txt lines 173-188). That changes opponent behaviour, but it is not an assist mode: it does not reduce damage taken, add aim assistance, or let the player skip a fight. GAG and XAG both distinguish difficulty from accessibility options. The pack does not show any assist mode. PARTIAL at best.

Ranked fixes

Ordered by how much they unblock or protect players per unit of build effort.

Add in-game input remapping. Define actions in InputMap, replace raw key checks with action calls, add a remapping screen, and save bindings to settings.json. This protects motor-impaired players, one-handed players and non-QWERTY keyboard users. It is the highest-value gap in the review. The engine supports it directly; the work is in refactoring the battle input code.

Fix the flash merge window and prove the 3-per-second cap. Change the salvo merge window from 0.12 s to at least 0.33 s, and add a test or counter that logs counted flashes over a rolling second. The current window can let more than three separate flashes through in a second. This protects photosensitive players and makes the “at most 3” claim true.

Add a text size option and raise the floor. Let the player choose a text scale, and stop the 0.6 floor from shrinking the help line and battle log to 7 or 8 px. At minimum, clamp the floor at 1.0 for body text. This protects low-vision players and anyone playing at a distance or on a small window.

Add non-colour identifiers to zone bands and a colour-blind option. Put an icon, pattern or short label on exit, guard, hold and terrain hexes, and add a preset palette or custom colour option for factions and zones. This protects red-green and blue-yellow players at the moment of decision.

Offer hold-to-toggle for orbit and pan, and a keyboard-only targeting path. A toggle removes the sustained drag; a keyboard path removes the precision mouse requirement. This protects players with tremor, fatigue or one-handed play.

Add captions for any gameplay-critical audio, and a slower game-speed option. Captions protect Deaf and hard-of-hearing players; a slower speed protects players who need more time to read and act.

UNSURE list

The exact HUD background colour behind the controls help line. The contrast ratio of #7d7768 is about 4.7:1 against black but about 4.2:1 against the settings-panel dark blue.

Whether zone hexes carry icons or text labels in the Godot build.

Whether the threat-map overlay (R key) encodes danger by colour alone.

Whether any gameplay-critical information is carried by audio alone.

Whether a keyboard-only path can complete a full activation.

The exact faction tint values (they live in data the pack does not include).

The screen area taken up by counted flashes, so the 20-percent XAG 118 criterion cannot be judged.

Whether faction crests or names are visible on the board at the same moment as the hull tint, when targeting decisions are made.

One-sentence verdict per area, plus overall

Colour-blind readability: PARTIAL. Factions have some non-colour backup through crests and names, but zone bands may still be colour-only at the moment of decision.

Flashing and photosensitivity: PARTIAL. The reduce-flashing option is real and substantial, but the 0.12-second merge window does not reliably enforce the claimed 3-per-second cap.

Text size and contrast: FAIL on size, PARTIAL on contrast. The scaling floor can shrink body text to 7 px and there is no player text-size control; contrast is marginal and depends on an unspecified background.

Input remapping: FAIL. No remapping exists, and the absence of InputMap actions means the work to add it is real but not blocked by the engine.

Hold-versus-toggle and input burden: PARTIAL. Turn-based pacing helps, but orbit and pan are sustained hold-drags and targeting is mouse-click only, with no toggle or proven keyboard path.

Other guideline areas: PARTIAL overall. Shake and follow options are good, but captions are absent, speed only goes faster, and difficulty is not an assist mode.

Overall verdict: PARTIAL. The game has meaningful accessibility work in reduce-flashing, shake control and camera follow, but it fails on input remapping and text scaling, and its flash budget and colour-only zone information need correction before the brief’s accessibility claims can be trusted.
