# Accessibility pass, Rey audit (Job 7, brief muse_2026-10-26c)

Chair note: Rey's own blind audit leg for Job 7, written from the evidence pack and the guideline pages linked inside (this leg opened its sources; the model legs cited guidelines from memory). Filed as written. The chair synthesis is accessibility_review.md in this folder. One panel-wide note: this draft was written before the fx implementation audit established from the fx code that the counted-flash cap binds the gated set regardless of the merge window; section 2's area question remains open and is carried in the synthesis.

---

# Rey chair audit, Job 7: accessibility pass (brief muse_2026-10-26c)

Blind leg. Worked from the evidence pack and the attached evidence files only, plus the guideline sources linked below. No other model's review of this job was read. Every claim about the game cites the pack file and line or section. Anything the pack does not establish is tagged UNSURE.

Method note on contrast: ratios use the standard WCAG formula. For each sRGB channel, divide by 255, then linearize: c / 12.92 if c is at most 0.04045, otherwise ((c + 0.055) / 1.055) ^ 2.4. Relative luminance L = 0.2126 R + 0.7152 G + 0.0722 B. Ratio = (lighter L + 0.05) / (darker L + 0.05). Translucent board colours are composited over the dark base before comparing, and the rendered background varies, so board ratios are estimates, not measurements of a live frame.

## 1. Colour-blind readability

Verdict for this area: PARTIAL, leaning FAIL on the board.

What the pack shows:

- Faction identity on hulls leans on tint. look_gd.txt lines 10 to 12 and 27 to 35 give dark hulls a Fresnel rim plus an albedo lift so they read against black space. The HULL_FIX values are [rim amount, rim tint, albedo lift], not RGB tint values: chorus [0.45, 0.55, 1.35], deathless [0.4, 0.5, 1.3], corsair [0.15, 0.3, 1.0], voidsworn [0.12, 0.3, 1.0], hegemony [0.08, 0.2, 1.0], ithar [0.1, 0.25, 1.0]. The hull function applies them at look_gd.txt lines 93 to 107. So the pack does not give the exact faction tint colours. Whether two factions stay separable under red-green deficiency cannot be computed from this pack. UNSURE.
- A standing rule from the design record, not from these files, says shields keep faction colours, interface shield bars are cyan, and the hex grid is cyan (evidence_pack_job7.md, Colour section). That means the shield bar and the grid share one colour family by design. Colour is doing identification work in at least two places at once.
- Non-colour identifiers do exist. crest_gd.txt line 9 gives crest glow colours: voidsworn #ff7a2a, hegemony #5fa0ff, corsair #e0402c, chorus #d6d24a, ithar #9fffd2, deathless #3dff6a. Lines 6 to 7 describe distinct shapes: Voidsworn a cracked halo over a sword, Hegemony a wedge in a ring of five stars, Corsairs a skull with a gear for a jaw, Chorus a ring of nine open mouths, Ithar a sail over a falling star, Deathless a crowned eye over a tomb door. The drawing code is at crest_gd.txt lines 45 to 91. Names and admiral portraits are also named in the pack as identifiers (evidence_pack_job7.md, Colour section).
- The timing gap is the problem. crest_gd.txt sits in godot/ui/career/. The pack does not establish that crests appear on the battle board, on the selected ship, or at the moment a player must tell factions apart under time pressure. A shape that lives on a career screen does not carry the same information at the moment it is needed in battle. UNSURE whether any shape channel is present in battle at all.
- Board zones are colour fills at low alpha. board_gd.txt lines 169 to 176: nebula Color(0.69, 0.49, 1.0, 0.16), debris Color(0.83, 0.75, 0.53, 0.12), storm Color(1.0, 0.91, 0.4, 0.13). BASE_FILL is Color(0.04, 0.06, 0.09, 0.18) and BASE_RING is Color(0.45, 0.65, 1.0, 0.07) at board_gd.txt line 176 area. Objective zones: exit Color(0.49, 1.0, 0.61, 0.16), transport exit Color(0.88, 0.48, 0.44, 0.16), guard Color(0.88, 0.48, 0.44, 0.14). The hold hex fill is Color(0.82, 0.65, 0.29, 0.3) at board_gd.txt line 191. The hover ring is Color(1.0, 0.82, 0.4, 0.9) at line 203.
- Composited over the dark base (about RGB 10, 15, 23), the zone fills land at roughly: exit 1.46:1, transport exit and guard red 1.23:1, hold gold 1.77:1, nebula 1.24:1, debris 1.23:1, storm 1.34:1, each measured against the base fill beside them. These are luminance separations, not colour differences. At these levels the zones read mainly by hue, which is exactly the channel that fails first for colour vision deficiency. The red guard and transport exit zones and the green exit zone are the classic red-green pair. Under deuteranopia or protanopia those two hues move toward each other while their luminance stays close (1.23:1 against 1.46:1), so the distinction between leave here and danger here rests on a weak signal.
- The pack lists as UNSURE whether zone hexes also carry icons or text labels in the Godot build, and whether the threat map overlay reached with the R key encodes danger by colour alone (evidence_pack_job7.md, Colour section). Both gaps matter and neither is filled by this pack.
- Settings offer no help here. The settings dictionary at main_gd.txt line 20 and the panel at title_gd.txt lines 173 to 185 contain no colour-blind mode, no palette option, and no high contrast mode. Observed by absence.

What the guidelines say:

- Xbox Accessibility Guideline 103 says colour alone should never be used to represent information, and critical information expressed through colour needs at least one more signifier such as shape, pattern, iconography, or a text label. If colour reliance is unavoidable, players should be able to assign their own colours. Source: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103
- The Game Accessibility Guidelines page on colour says to use colour as a backup to text, a symbol, a pattern, or a shape, notes that red-green difficulty affects about 8 to 10 percent of males, and asks for customisation where extra signifiers are not enough. Source: https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-fixed-colour-alone/
- Xbox Accessibility Guideline 102 sets 4.5:1 for standard size text and visual elements and 3:1 for large scale elements. The zone fills are visual elements carrying gameplay meaning, and at 1.2:1 to 1.8:1 composited they sit far under either bar, even allowing that a translucent tint over a 3D scene is not the same case as flat UI. Source: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102

Judgement: the crest shapes are a real second channel and the strongest point in this area, but the pack places them in the career UI, not proven in battle. Faction hulls, shields, and board zones still lean on colour at the moment of decision, with no palette option and no confirmed labels. PARTIAL overall, FAIL for board zone reading by colour alone on the evidence given.

## 2. Flashing and photosensitivity

Verdict for this area: PARTIAL, the strongest area in the pack.

What the pack shows:

- fx_api_md.txt section 8, lines 128 to 130: "At most 3 counted flashes per rolling second anywhere on screen (WCAG 2.3.2). Flashes landing within 0.12 s of each other (a salvo) count as one; over the budget, flashes draw as smoke and sparks without the bright core." The brief's claim of at most 3 flashes per second is therefore supported as a stated contract in the effects layer's own document.
- With reduce_flashing = true, the same section says there are no counted flashes at all. Bright pops become expanding rings, particle bursts, and a gentle glow rise. Muzzle flashes become smoke-forward. Fire flicker becomes slow breathing. Effect shake halves.
- The setting is real and wired. main_gd.txt line 20 includes reduce_flashing false in the defaults. title_gd.txt lines 173 to 185 include a Reduce flashing toggle in the panel. main_gd.txt lines 149 to 164 pass reduce_flashing to fx in _settings_to_battle. features_md.txt line 87 records "Reduce flashing (WCAG) | done (G4; the setting reaches fx)". The brief's second claim, that a reduce-flashing option exists, is supported.
- Shake is a trauma model, positional only, at fx_api_md.txt section 7, line 123. Durations are 0.15 to 0.30 s normally and 0.35 to 0.45 s only for capital deaths. The settings slider scales shake from 0 to 1 through fx.shake_scale (main_gd.txt lines 149 to 164).

Where it falls short of a clean pass:

- A counted flash is a bookkeeping unit, not a WCAG flash. WCAG defines a general flash as a pair of opposing changes in relative luminance of 10 percent or more where the darker image is below 0.80 relative luminance, and a red flash by saturated red. Source: http://w3c.github.io/wcag/understanding/three-flashes.html
- Xbox Accessibility Guideline 118 uses the same shape of test: a flash is about a 10 percent luminance change with the darker value below 0.8, failure at about more than three per second or about 20 percent or more of the screen, with a separate red flash test and a spatial pattern test. Source: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118
- The pack gives no luminance swing, no red saturation figures, and no flashing area measurements for any effect. So the count cap matches the WCAG count on its face, but whether any single effect, or a merged salvo drawn together, crosses the luminance, red, or area thresholds is UNSURE from this pack. Compliance of the rendered game cannot be confirmed from documents alone. A Harding style test or a frame capture pass on the busiest salvo would be needed.
- The salvo merge window deserves an honest note. The implementation merges flashes within 0.12 s into one counted flash (fx_api_md.txt section 8). The chair context in the pack records that an earlier commissioned review recommended a 0.33 s merge window with the same cap. A narrower window counts more salvos against the budget, which is the safer direction for the count, since fewer real flashes hide inside one counted unit. The risk runs the other way: effects merged into one counted flash still draw together on screen, so the merged group can present a larger bright area than any single flash. Area, not count, is where the 0.12 s window could matter, and area is exactly what the pack does not measure. UNSURE.
- Reduce mode is well specified on paper, and its fallback language (rings, smoke, slow breathing) shows the degraded forms were designed, not just dimmed. That is above the usual standard for an indie build. The remaining gap is verification, not design.

Judgement: the architecture is sound and the setting reaches the effects layer, which many games fail at. The verdict stays PARTIAL because rendered compliance (luminance, red, area) is unproven on this evidence, and the audit should not upgrade a contract document into a measured pass.

## 3. Text size and contrast

Verdict for this area: FAIL.

What the pack shows:

- Every size in both hud_gd.txt and title_gd.txt scales through s(v) = round(v * k), where k = clamp(viewport height / 1080, 0.6, 2.2). See title_gd.txt lines 30 to 35 and hud_gd.txt lines 71 and 118 to 119. Text scales with window height only. There is no user-facing text size setting anywhere in the panel (title_gd.txt lines 173 to 185) or the settings dictionary (main_gd.txt line 20).
- Base sizes at k = 1, a 1080p-high window: theme default 15 (hud_gd.txt line 125), buttons 14 (line 148), rich text 14 (lines 153 to 154), battle log 13 (lines 537 to 538), controls help line 12 (line 470), weapon descriptions 12 (line 512), persistent hint line 13 (line 651), settings row labels 18 (title_gd.txt line 197), settings title 30 (title_gd.txt line 172).
- At the k floor of 0.6, a window about 650 px tall, the 12-unit help line renders at about 7 px and the log at about 8 px (evidence_pack_job7.md, Text size section). The clamp protects layout, not the reader. A player on a small window or a split screen gets text far below any guideline floor with no way to raise it.
- Fonts are Barlow Semi Condensed in Regular, Medium, and SemiBold for UI text, and UnifrakturMaguntia, a blackletter display face, for headings, both in godot/ui/battle/fonts/ with OFL licences. The settings title uses the blackletter face at size 30. A condensed face at small sizes and a blackletter face for headings both trade readability for flavour. At 30 the settings title is a heading, not body text, so the cost is modest there. UNSURE whether blackletter appears anywhere at small sizes.

Contrast arithmetic:

- INK #0f1626: channels 15, 22, 38. Linearized about 0.0046, 0.0060, 0.0193. L = 0.2126 x 0.0046 + 0.7152 x 0.0060 + 0.0722 x 0.0193 = about 0.0082.
- IRON2 #222d44: channels 34, 45, 68. L = about 0.0263.
- BONE3 #7d7768, the help text colour: channels 125, 119, 104. Linearized about 0.209, 0.185, 0.145. L = 0.2126 x 0.209 + 0.7152 x 0.185 + 0.0722 x 0.145 = about 0.1855.
- Help text against INK: (0.1855 + 0.05) / (0.0082 + 0.05) = 0.2355 / 0.0582 = about 4.05:1.
- Help text against IRON2, close to the button panel background Color(0.133, 0.176, 0.267, 0.85) at hud_gd.txt line 127: (0.1855 + 0.05) / (0.0263 + 0.05) = 0.2355 / 0.0763 = about 3.09:1.
- Help text against the GLASS panel colour Color(0.047, 0.07, 0.12, 0.80) at hud_gd.txt lines 9 to 26, composited over INK: about 4.16:1. GLASS has alpha 0.80 over a varying 3D scene, so the true background behind any given line is not fixed, and the honest figure is a range of about 3.1:1 to 4.2:1 depending on what sits behind the panel.
- The help line at hud_gd.txt line 470 is #7d7768 at size 12, the same value as BONE3. One log category at hud_gd.txt line 542 also uses #7d7768, at log size 13.
- For comparison, BONE2 #b3aa95 (channels 179, 170, 149, L about 0.405), used for the persistent hint line at hud_gd.txt line 651 at size 13, gives (0.405 + 0.05) / (0.0082 + 0.05) = about 7.82:1 against INK and about 5.96:1 against IRON2. BONE #e6dcc4 (L about 0.720) gives about 13.24:1 against INK and about 10.09:1 against IRON2. The palette already contains colours that pass easily at the same sizes. The failing element is a choice, not a palette limit.

What the guidelines say:

- Xbox Accessibility Guideline 102 requires 4.5:1 for standard size text, 3:1 for large scale text, 3:1 for inactive element text, and 7:1 in a high contrast mode. Source: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102
- Xbox Accessibility Guideline 101 sets the PC default font floor at 18 px body height at 1080p and 36 px at 4K, says players should be able to scale text up to 200 percent of the minimum, and says platform screen magnification is not an appropriate mitigation for small text. Source: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101
- The Game Accessibility Guidelines page on font size calls a choice of font size the ideal, a large default the first step, and cites 28 px at 1080p from 10-foot UI guidance as a floor to treat as a minimum, not a target. Source: https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/

Judgement: the main body text at 14 to 15 sits under the XAG 101 PC floor of 18 px at 1080p even at full window height, and the help line and log sit further under it. The help line also fails the XAG 102 standard text bar of 4.5:1 on every plausible background in the pack (3.09:1 to 4.16:1), and it is the line that teaches a new player the controls, which is the worst line to mute. Because all sizes already flow through one s(v) function in both files, this is also the cheapest structural fix in the whole audit. FAIL on both size and the help text colour, with the note that BONE and BONE2 prove the palette can pass.

## 4. Input remapping

Verdict for this area: NOT PRESENT, which scores as FAIL against the guidelines.

What the pack shows:

- project_godot.txt has these sections only: [application] line 4, [debug] line 10, [display] line 30, [rendering] line 37, [physics] line 48, [importer_defaults] line 52. There is no [input] section and no [gui] section.
- Grep across the attached code found no InputMap use and no joypad, gamepad, or controller references (evidence_pack_job7.md, Input section).
- The settings panel at title_gd.txt lines 173 to 185 offers no remapping entry, and the settings dictionary at main_gd.txt line 20 holds no binding data.
- The documented scheme (hud_gd.txt line 470) is a fixed keyboard and mouse layout: Q/E turn, 1 to 6 pick a weapon, B brace, Tab next ship, Enter end activation, Esc cancel, plus mouse click targeting and drag camera control. features_md.txt adds X ram and G board at line 56, Space to hurry enemy turns at line 61, and V for firing arcs at line 63, none of which appear in the in-game help line. A fixed layout that is not even fully documented in its own help text leaves a player who cannot use that layout with no route in.

What the guidelines say:

- Xbox Accessibility Guideline 107 says players should be able to remap all controls inside the game itself, regardless of platform level remapping, including analogue and digital controls, per-stick axis inversion, and the Esc key on PC, and that remapped labels must update across hints, tips, tutorials, and control schemes. Source: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107
- The Game Accessibility Guidelines call remappable controls one of the best value accessibility features and recommend presets plus a custom option allowing full remapping. Source: https://gameaccessibilityguidelines.com/allow-controls-to-be-remapped-reconfigured/

Minimum viable step in Godot, judged from the structure in the pack: define named actions in the project [input] section and read input through InputMap action checks instead of fixed key checks, store overrides in the existing settings file flow (main_gd.txt lines 122 to 146 already save and load a settings dictionary to user://settings.json), and expose a small rebinding list in the existing settings panel. The current structure helps in one way: settings persistence and the panel already exist, so bindings have a home. It blocks in one way: with no [input] section and no InputMap use anywhere, every fixed key check in the game code has to be found and converted, and the pack does not show how input is read inside the battle code, so the size of that conversion is UNSURE. Controller support is a separate, larger step. The pack shows no controller references at all, so adding pad input means new bindings and menu navigation work, not just remapping. UNSURE whether menus are fully keyboard navigable today.

## 5. Hold-vs-toggle and input burden

Verdict for this area: PARTIAL. The turn-based structure earns real credit. The camera drags do not.

What the pack shows:

- Orbit is right-drag and pan is left-drag or WASD (hud_gd.txt line 470; features_md.txt line 50 confirms right-drag orbit, left-drag or WASD pan, wheel zoom, T top-down, Home reset view, F focus). Orbit and pan are hold-drag interactions. No toggle alternative is offered in settings (evidence_pack_job7.md, Input section; panel at title_gd.txt lines 173 to 185).
- Targeting is mouse-click driven per the help text: click a gold hex to move, click an enemy to fire (hud_gd.txt line 470). Whether any keyboard-only path can complete a full activation is UNSURE from the pack. Tab cycles ships and Q/E turn the selected ship, which suggests partial keyboard support, but selection of a destination hex and a target by keyboard alone is not documented.
- The Admiral's Command uses a top-bar button with two clicks to confirm (features_md.txt line 59). Two single clicks are a low burden and the confirm step protects against slips. That is good design for motor accessibility, worth naming.
- Speed offers Normal and Fast 0.45 only (title_gd.txt lines 173 to 185). There is no slower-than-normal option. Against that, the game is turn-based and battles resolve activations one at a time (evidence_pack_job7.md, Input section), so there is no reaction timer on the player's own decisions. Follow enemy activations can be turned off, and Space hurries enemy turns (features_md.txt line 61), which cuts waiting without adding pressure.
- No simultaneous key chords are documented in the scheme. The burden items are sustained drag, pointer precision on hexes and ships, and wheel zoom. Wheel zoom has no documented keyboard alternative in the help line. UNSURE whether plus and minus keys zoom.

What the guidelines say:

- Xbox Accessibility Guideline 107 states there is no instance where multiple buttons should be pressed simultaneously or held down to complete actions, and covers toggles and auto holds as the alternative pattern. It also asks that content be operable without path-based gestures such as click and drag, or by another method. Source: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107
- The Game Accessibility Guidelines page on held buttons says holding requires much greater motor ability than pressing, and where a hold could be a toggle, offer the player the choice. Source: https://gameaccessibilityguidelines.com/avoid-provide-alternatives-to-requiring-buttons-to-be-held-down/
- The Game Accessibility Guidelines full list places alternatives to holding buttons, and no required click-and-drag except as a supplementary method, in its intermediate motor items. Source: https://gameaccessibilityguidelines.com/full-list/

Judgement: a click-and-drag camera as the only orbit route is a direct hit on the held-input guidance, softened by the fact that WASD pan, T top-down, F focus, and Home reset already provide digital alternatives for part of the camera. Orbit is the exposed piece. A toggle-drag mode (click to start orbit, move, click to stop) or keyboard orbit keys would close most of it. The turn-based core, the two-click Command confirm, and the absence of timers or chords keep this at PARTIAL rather than FAIL.

## 6. Other evidence: captions, audio, motion, speed, difficulty

Verdicts inside this area: captions NOT PRESENT. Audio channels PARTIAL. Motion comfort PARTIAL. Game speed PARTIAL. Difficulty as accessibility PARTIAL.

What the pack shows:

- Captions: grep for caption or subtitle across all attached files returns zero hits, and no captions system is documented in features_md.txt (evidence_pack_job7.md, Audio section). The settings dictionary at main_gd.txt line 20 and the panel at title_gd.txt lines 173 to 185 hold no subtitles entry.
- Whether any gameplay-critical information is carried by audio alone is UNSURE from this pack. No speech or dialogue channel is evidenced in the pack either. If the game has no spoken content, the subtitle duty shrinks to captioning meaningful sound cues, which is a smaller job. features_md.txt line 93 covers the sound cue table and synth cues, line 94 covers buses, compressor, limiter, reverb, voice caps, and salvo thinning, and line 96 says battle music varies by faction with intensity layers. Music that varies by faction is an audio identification channel for factions. For a deaf player that channel is absent, which loops back to section 1: the visual channel has to carry faction identity on its own, and the pack does not prove that it does in battle.
- Audio controls are a genuine strength. Sound effects and music have separate toggles and separate volume sliders (main_gd.txt line 20; title_gd.txt lines 173 to 176; applied separately at main_gd.txt lines 149 to 164). That matches the guideline ask for separate volume controls per audio type. There is no separate dialogue slider, but no dialogue channel is evidenced. UNSURE.
- Motion comfort: shake is positional only, trauma based, short (0.15 to 0.30 s, 0.35 to 0.45 s for capital deaths), scaled by a Full / Reduced 0.5 / Off setting, and halved again in reduce-flashing mode (fx_api_md.txt section 7 line 123 and section 8; title_gd.txt lines 173 to 185). Follow enemy activations can be turned off (main_gd.txt line 20, follow true). Cut-ins can be set to Key moments, Every attack, or Off (cine "key" in the dictionary; panel rows at title_gd.txt lines 173 to 185). Those three controls together cover the main motion sources the pack evidences. What is missing is any camera-motion option beyond Follow and shake, observed by absence in the pack. Direct evidence on Xbox Accessibility Guideline 117 (visual distractions and motion settings) was not opened for this leg, so any claim about its specific wording would be from memory and is not relied on here. The judgement above rests on the pack evidence and the general pattern in XAG 107 and the Game Accessibility Guidelines basic list, which includes adjusting game speed and motion related comfort options. Sources: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107 and https://gameaccessibilityguidelines.com/basic/
- Game speed: the only options are Normal 1.0 and Fast 0.45 (title_gd.txt lines 173 to 185). Fast helps players who want shorter enemy phases. There is no slower-than-normal setting. The Game Accessibility Guidelines page on game speed says slowing the whole game down helps players with precise-timing issues and players who need more time to process what is happening. Source: https://gameaccessibilityguidelines.com/include-an-option-to-adjust-the-game-speed/ In a turn-based game the processing pressure is low on the player's own turn, but enemy phases, cut-ins, and effects still play at fixed speed, so a slow option has real if modest value here.
- Difficulty: Enemy AI offers Veteran and Standard only (title_gd.txt lines 173 to 185; ai "veteran" at main_gd.txt line 20). Xbox Accessibility Guideline 108 asks for multiple difficulty presets, ideally four or more across a wide range, changeable at any time without losing progress. Source: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/108 Two levels, with no evidence in the pack about whether the setting can be changed mid-run or what Standard actually softens, is thin as an accessibility lever. UNSURE whether AI level changes anything beyond enemy play quality, such as damage taken.

Additional guideline sources used in this area:

- Xbox Accessibility Guideline 104, subtitles and captions: subtitles for all spoken content, speaker identification, and colour never as the only speaker distinguisher. https://learn.microsoft.com/en-gb/gaming/accessibility/xbox-accessibility-guidelines/104
- Xbox Accessibility Guideline 105, audio accessibility: separate volume controls for each type of audio output so speech and key cues are not buried. https://learn.microsoft.com/en-gb/gaming/accessibility/xbox-accessibility-guidelines/105
- Game Accessibility Guidelines basic list: no essential information by sounds alone, separate volume controls or mutes for effects, speech, and music, subtitles for all important speech, settings saved and remembered, a wide choice of difficulty levels. https://gameaccessibilityguidelines.com/basic/ Settings are saved and remembered here (main_gd.txt lines 122 to 146), which the pack does support and which deserves credit.

## Ranked fixes

Ordered by how much each unblocks or protects players per unit of build effort.

1. Add a user text scale that multiplies inside the existing s(v) function in hud_gd.txt and title_gd.txt, and raise the default base sizes toward the 18 px PC floor. Every size already flows through one function in both files, so this is the highest value, lowest effort fix in the audit. In the same pass, move the controls help line (hud_gd.txt line 470) and the muted log category (line 542) from #7d7768 to BONE2 #b3aa95, which already passes at about 5.96:1 to 7.82:1. One line colour change fixes the game's teaching text.
2. Put a second channel on board zones: a small icon or short label on exit, guard, transport exit, and hold hexes, and an edge pattern difference between the green exit and the red guard zones. The fills sit at 1.23:1 to 1.77:1 composited, so colour is carrying meaning it cannot carry alone. Art and a draw call per zone type, no systems work.
3. Bring the crest shapes into battle: draw the faction crest on the selected ship panel and on ship markers, so the shape channel that already exists in crest_gd.txt works at the moment of decision, not only in the career UI. The shapes and colours are already built.
4. Run a rendered photosensitivity check on the busiest salvo and capital death, measuring luminance swing, red saturation, and flashing area against WCAG 2.3.1 and XAG 118, and record the numbers in fx/API.md next to the section 8 contract. The design looks right. What is missing is proof, and proof is a test pass, not a rebuild.
5. Add InputMap actions for the documented keys and a basic rebind list in the settings panel, stored through the existing settings save flow. Medium effort, since every fixed key check must be converted, but it is the single feature the guidelines treat as basic and the game has none of it. Include the undocumented keys (X, G, Space, V) in the help line at the same time, and make help text read from the live bindings once remapping exists, per XAG 107.
6. Add a toggle-drag camera option: click to begin orbit or pan, move without holding, click to end. Plus keyboard orbit keys to sit beside the existing WASD pan, T, F, and Home controls. Small, contained, and it removes the only sustained hold in the scheme.
7. Add a slower speed option (for example 1.5 or 2.0 as a duration multiplier alongside Normal and Fast 0.45) and widen Enemy AI beyond Veteran and Standard, or state plainly what Standard changes. Both are settings surface work on systems that already exist.
8. If any sound cue carries gameplay information on its own, add a caption or log line for it. The battle log already exists at hud_gd.txt lines 537 to 538, so routing key cues into text is cheaper than building a captions system. First step is an inventory, since the pack leaves audio-only information UNSURE.

## UNSURE list

1. The exact faction tint values. They live in data the pack does not include, so faction separability under specific colour vision deficiencies could not be computed.
2. Whether zone hexes carry icons or text labels in the Godot build (pack-stated UNSURE).
3. Whether the threat map overlay on the R key encodes danger by colour alone (pack-stated UNSURE).
4. Whether crests, portraits, or any shape identifier appear in battle at the moment of identification, since crest_gd.txt sits in the career UI folder.
5. Whether any single effect or merged salvo crosses WCAG luminance, red flash, or flashing area thresholds. The pack gives a count contract and no measurements.
6. Whether the 0.12 s salvo merge window creates a flashing area problem when merged flashes draw together. Area is unmeasured.
7. Whether a keyboard-only path can complete a full activation, including picking a destination hex and a target (pack-stated UNSURE).
8. Whether menus are fully navigable by keyboard alone, and whether wheel zoom has a keyboard alternative.
9. How input is read inside the battle code, so the size of an InputMap conversion cannot be estimated from this pack.
10. Whether any gameplay-critical information is carried by audio alone (pack-stated UNSURE), and whether any spoken content exists that would trigger a full subtitle duty.
11. Whether blackletter type appears anywhere at small sizes, and whether the Enemy AI setting can be changed mid-run or changes anything beyond enemy play quality.

## Per-area verdicts

- Colour-blind readability: PARTIAL. Crests give a real shape channel, but factions and board zones still lean on colour at the moment of decision, zone fills sit at 1.23:1 to 1.77:1, and no palette option exists.
- Flashing and photosensitivity: PARTIAL. The 3 per second counted cap and a wired reduce-flashing mode match the contract the brief claimed, but rendered luminance, red, and area compliance is unmeasured.
- Text size and contrast: FAIL. Body text sits under the 18 px PC floor at full height and far under it at the size clamp floor, there is no text scale, and the controls help line fails 4.5:1 on every plausible background at 3.09:1 to 4.16:1.
- Input remapping: NOT PRESENT. No [input] section, no InputMap use, and no settings entry, against a basic-level guideline expectation.
- Hold-vs-toggle and input burden: PARTIAL. The turn-based core, two-click Command confirm, and lack of timers or chords earn credit, while drag-only orbit with no toggle route is a direct gap.
- Other evidence (captions, audio, motion, speed, difficulty): PARTIAL. Separate sound and music controls, shake scaling, follow and cut-in controls, and saved settings are real strengths, set against no captions, no slow speed, and only two AI levels.

Overall verdict: PARTIAL, with one FAIL that is cheap to fix. The safety and comfort settings (flashing, shake, follow, cut-ins, separate audio) are built like someone read the guidelines. The reading and input foundations (text size, help text contrast, remapping, colour-only board meaning) are not yet at that standard, and the single highest value move is the text scale plus help line colour, because the structure for it already exists.
