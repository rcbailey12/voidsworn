# Accessibility review, Gemini Argon leg, 2026-10-26

Chair header: filed as the single reviews copy for the Gemini leg (house pattern). Model: Gemini 4 Argon, Thinking level High, verified in two places before submitting ("Argon High" on the picker button and the prompt bar dropdown). The leg waited out a stated Argon rate limit (options disabled until 3:10 PM CDT) before running, 2:45-3:20 PM CDT. Seven files attached (leg prompt, evidence pack, project.godot, main.gd, title.gd, fx API, look.gd). The leg states its guideline citations are from memory, not pages opened in session; the chair screening note records what that means for the synthesis. Model text follows verbatim.

---

# Accessibility Review: Voidsworn (Godot 4.7, Job 7, brief muse_2026-10-26c)

All game claims below cite the attached evidence pack and files. All external accessibility guideline claims (Xbox Accessibility Guidelines, Game Accessibility Guidelines, and W3C WCAG 2.1) and their URLs are cited from memory rather than pages opened during this session.

## 1. Colour-Blind Readability

**Verdict: PARTIAL** (Factions have strong non-colour channels in menus, HUD text, and combat animations, but board objective and danger zones rely on low-opacity red, green, and gold fills that collide under common colour vision deficiencies, with no colour-blind settings).

### Code and Pack Evidence

**No colour-blind settings:** Neither the default settings dictionary (main_gd.txt line 20) nor the settings panel (title_gd.txt lines 173-188) offers a colour-blind palette, high-contrast toggle, or zone pattern toggle (evidence_pack_job7.md, "The settings system").

**Faction identification (look_gd.txt, fx_api_md.txt, evidence_pack_job7.md):**

The game has six factions: "voidsworn", "hegemony", "corsair", "chorus", and "ithar", plus "deathless" (fx_api_md.txt section 2, line 40). Exact faction RGB tint values live in data files outside the pack and are UNSURE (evidence_pack_job7.md, "Colour: factions and danger").

On 3D hulls, faction readability leans on colour tint: look_gd.txt lines 10, 27-35, and 92-104 (HULL_FIX and LOOK.hull) apply a Fresnel rim in the faction tint and an albedo lift for dark hulls (chorus lift 1.35, deathless lift 1.3, others 1.0). Shields also keep faction colours (fx_api_md.txt section 2, line 44; section 3, line 78), while HUD shield bars and the base hex grid are cyan (evidence_pack_job7.md, "Colour: factions and danger").

**Non-colour faction channels:** Factions have distinct glyph crests drawn by godot/ui/career/crest.gd, admiral portraits, and text names for the Nemesis and admirals in HUD and campaign screens (evidence_pack_job7.md, "Colour: factions and danger"). In 3D combat, factions also differ by hull class meshes (fx_api_md.txt section 2, lines 41-42), engine trail behaviour (such as Corsair soot sputtering, fx_api_md.txt section 2, line 48), weapon projectile geometry (fx_api_md.txt section 3, lines 75-76), whether ships carry shields (chorus and deathless are unshielded by default, fx_api_md.txt section 2, line 44), and shield-break animations (Voidsworn tearing veil, Hegemony shattering hex cells, Corsair patchy sputter, Ithar folding sheet, fx_api_md.txt section 4, line 93).

**Same-moment parity gap:** While HUD text, crests, and active fire/shield animations provide non-colour differentiation, resting ships on the 3D board between animations rely on hull silhouette and rim tint (look_gd.txt lines 27-35). Whether the on-board ship selection ring or footprint marker (fx_api_md.txt section 2, line 41) renders faction crests or friend/foe icons directly on the board is UNSURE.

**Board danger and objective zones (board_gd.txt lines 169-176, 191, 203, quoted in evidence_pack_job7.md, "Colour: factions and danger"):**

- Exit edge: Green Color(0.49, 1.0, 0.61, 0.16) (#7dff9c at 16% opacity).
- Transport exit and station guard zones: Red Color(0.88, 0.48, 0.44, 0.16) (#e07a70 at 16% opacity).
- Hold/relay hex: Gold fill Color(0.82, 0.65, 0.29, 0.3) (#d1a64a at 30% opacity) with gold ring Color(1.0, 0.82, 0.4, 0.9) (#ffd166 at 90% opacity).
- Move hexes: Also use gold ("click a gold hex to move", hud_gd.txt line 470, quoted in evidence_pack_job7.md, "Input").
- Terrain and base grid: Nebula purple, debris tan, storm yellow, and base hex ring blue Color(0.45, 0.65, 1.0) at alpha 0.07 (board_gd.txt in evidence_pack_job7.md, "Colour: factions and danger"). Asteroid blockers (rock), debris fields, hulks, wrecks, and the dead-star black hole have distinct 3D geometry (fx_api_md.txt section 9, lines 140-141), and travelling torpedo lanes add directional chevrons and a pulsing impact marker (fx_api_md.txt section 3, line 84).

**Colour-deficiency collision:** Exit green Color(0.49, 1.0, 0.61, 0.16) and guard/transport-exit red Color(0.88, 0.48, 0.44, 0.16) have identical 0.16 alpha and opposite tactical meaning, yet under protanopia and deuteranopia (red-green deficiency), soft salmon-red, mint-green, hold/move gold, debris tan, and storm yellow compress into overlapping warm olive-tan hues. Under tritanopia (blue-yellow deficiency), nebula purple, base grid blue, and muted red/tan also lose separation. Whether board zones carry icons or text labels, and whether the R key threat map overlay encodes danger by colour alone, are UNSURE (evidence_pack_job7.md, "Colour: factions and danger").

### What the Guidelines Say (from memory)

Xbox Accessibility Guidelines (XAG) 104: Colorblindness (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/104, from memory) and WCAG 2.1 SC 1.4.1 Use of Color (Level A) (https://www.w3.org/TR/WCAG21/#use-of-color, from memory): Colour must not be used as the sole visual channel to convey information, distinguish teams, or mark danger/objective areas. Distinct shapes, patterns, borders, or icons must accompany colour cues at the exact moment and location the player reads them.

Game Accessibility Guidelines (GAG) Basic: "Ensure no essential information is conveyed by a colour alone" (https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/, from memory): Specifically warns against differentiating tactical states or zones solely by red, green, and amber/gold fills.

## 2. Flashing and Photosensitivity

**Verdict: PARTIAL** (Both brief claims are verified in the pack and the reduce_flashing mode is comprehensive, but the default mode's 0.12 s salvo merge window can let more than 3 physical luminance flashes occur inside 1 second if discrete pops within a salvo dip and re-peak).

### Verification of the Brief's Two Claims

**Claim 1 ("at most 3 flashes per second"):** Confirmed in the effects contract, with a salvo-counting caveat. fx_api_md.txt section 8, line 128 states: "At most 3 counted flashes per rolling second anywhere on screen (WCAG 2.3.2). Flashes landing within 0.12 s of each other (a salvo) count as one; over the budget, flashes draw as smoke and sparks without the bright core."

**Claim 2 ("a reduce-flashing option exists"):** Confirmed end-to-end across settings storage, UI, and FX wiring:

- Default key "reduce_flashing": false in main_gd.txt line 20, saved to user://settings.json (main_gd.txt lines 15, 122-135).
- Exposed in the settings menu as _toggle("Reduce flashing", "reduce_flashing") (title_gd.txt line 181).
- Passed to the battle FX node in main_gd.txt lines 161-162 (b.fx.reduce_flashing = bool(settings["reduce_flashing"])) and updated live when changed mid-battle (main_gd.txt lines 149-150, 167-169; FEATURES.md line 87 in evidence_pack_job7.md, "Flashing").

### Judgment of the Implementation

**The 0.12 s salvo merge risk (fx_api_md.txt section 8, line 128; evidence_pack_job7.md, "Flashing"):**

Under WCAG 2.3.1 Three Flashes or Below Threshold (Level A) and WCAG 2.3.2 Three Flashes (Level AAA) (https://www.w3.org/TR/WCAG21/#three-flashes-or-below-threshold and https://www.w3.org/TR/WCAG21/#three-flashes, from memory), a flash is a pair of opposing changes in relative luminance, and no more than 3 flashes may occur in any 1-second window (a minimum period of 0.333 s between flashes).

Because fx_api_md.txt line 128 counts multiple flashes landing within 0.12 s of each other as one counted flash, a rapid battery ripple (fx_api_md.txt section 3, line 80) that produces two distinct bright pops 0.10 s apart (a 10 Hz strobe, inside the peak photosensitive risk band of 10-25 Hz) increments the budget by only 1. Across 3 counted salvos in 1 rolling second (for example at 0.00 s and 0.10 s, 0.35 s and 0.45 s, and 0.70 s and 0.80 s), the screen can emit 6 or more distinct bright flashes in 1 second while obeying the "3 counted flashes" rule.

Merging flashes within a window only complies with WCAG 2.3.1/2.3.2 if either (a) the merged flashes coalesce into a single continuous luminance plateau with no dark dip between peaks, or (b) any flash arriving within 0.333 s of a previous flash suppresses its bright core (drawing as smoke and sparks) rather than rendering a second bright pop. Because godot/fx/fx.gd is not in the pack, how the shader/particle code handles intermediate luminance dips inside a 0.12 s salvo is UNSURE.

**What reduce_flashing = true changes (fx_api_md.txt section 8, line 129; section 14, line 198; look_gd.txt lines 9, 43, 48):**

- Removes all counted flashes ("no counted flashes at all").
- Replaces bright impact pops with expanding rings, particle bursts, and a gentle glow rise.
- Makes muzzle flashes smoke-forward, turns fire flicker into slow breathing, and halves effect camera shake.
- Scales hull breach damage_glow against exposure and flash rules (fx_api_md.txt section 14, line 198), while look_gd.txt lines 9, 43, and 48 lock tonemap_exposure = 1.0 with no auto-exposure so effects never pump screen brightness.

### What the Guidelines Say (from memory)

WCAG 2.1 SC 2.3.1 (Level A) and SC 2.3.2 (Level AAA) (https://www.w3.org/TR/WCAG21/#seizures-and-physical-reactions, from memory): Cap flashes at 3 per any 1-second period (<= 3 Hz).

Xbox Accessibility Guidelines (XAG) 118: Photosensitivity (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118, from memory) and GAG Basic: "Avoid flickering images and repetitive patterns" (https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/, from memory): Require keeping default flash rates at or below 3 flashes per second and providing a player-accessible setting to reduce or eliminate flashing effects.

## 3. Text Size and Contrast

**Verdict: FAIL** (All battle HUD base text sizes at 1080p sit below the 18 px PC guideline minimum, the k = 0.6 scaling floor shrinks HUD text to 7-9 px, there is no user text-scaling option, and the #7d7768 12 px controls help line fails contrast standards on dark UI panels).

### Code and Pack Evidence: Text Sizing and Fonts

**Window-height scaling without user control:** Both title.gd and hud.gd scale sizes via s(v) = int(round(v * k)) where k = clampf(get_viewport().get_visible_rect().size.y / 1080.0, 0.6, 2.2) (title_gd.txt lines 30-34; hud_gd.txt line 118 in evidence_pack_job7.md, "Text size and contrast"). No text size or UI scale setting exists in main_gd.txt line 20 or title_gd.txt lines 173-188. In title_gd.txt line 34, k is computed once in _ready() and is not recalculated if the window is resized while on the title screen.

**Base sizes at 1080p (k = 1.0) and at the k = 0.6 floor (~648 px height) (evidence_pack_job7.md, "Text size and contrast"; title_gd.txt):**

| UI Element | Source | Size at 1080p (k = 1.0) | Size at 720p (k = 0.67) | Size at Floor (k = 0.6) | Meets 18 px PC Guideline at 1080p? |
|---|---|---|---|---|---|
| Title header ("Voidsworn") | title_gd.txt line 58 | 110 px | 73 px | 66 px | Yes |
| Settings heading ("Settings") | title_gd.txt line 173 | 30 px | 20 px | 18 px | Yes |
| Title subtitle and menu buttons | title_gd.txt lines 61, 102 | 19 px | 13 px | 11 px | Yes (at 1080p only) |
| Settings row labels (_row) | title_gd.txt line 197 | 18 px | 12 px | 11 px | Yes (at 1080p only) |
| Title toast message (toast_lbl) | title_gd.txt line 82 | 17 px | 11 px | 10 px | No (below 18 px) |
| Battle HUD theme default | hud_gd.txt line 125 | 15 px | 10 px | 9 px | No |
| Battle HUD buttons and rich text | hud_gd.txt lines 148, 153-154 | 14 px | 9 px | 8 px | No |
| Battle log | hud_gd.txt lines 537-538 | 13 px | 9 px | 8 px | No |
| Controls help line (keys_text) | hud_gd.txt line 470 | 12 px | 8 px | 7 px | No |

**Font selection (title_gd.txt lines 35-37; evidence_pack_job7.md, "Text size and contrast"):**

Body UI uses Barlow Semi Condensed (Regular, Medium, SemiBold). Condensed letterforms have narrower horizontal apertures than regular-width sans-serif fonts, which compounds legibility loss at 12-14 px (and 7-8 px at k = 0.6).

Display headings use UnifrakturMaguntia-Book.ttf, a blackletter face (title_gd.txt lines 37, 58, 173). Blackletter fonts are harder to parse for players with dyslexia or low vision, though in the attached files it is restricted to the 110 px game title and 30 px "Settings" header. Whether campaign screens use UnifrakturMaguntia at smaller sizes is UNSURE.

### Code and Pack Evidence: Contrast Ratio Computations

Using the WCAG 2.1 relative luminance formula L = 0.2126 R_lin + 0.7152 G_lin + 0.0722 B_lin and contrast ratio (L1 + 0.05) / (L2 + 0.05):

**Controls help line #7d7768 at size 12 (hud_gd.txt line 470, in evidence_pack_job7.md, "Text size and contrast"):**

#7d7768 (R = 125, G = 119, B = 104) has relative luminance L = 0.1856.

The exact HUD bar background RGB in hud_gd.txt is not quoted in the pack (UNSURE), so here is #7d7768 tested against pure black and every dark background colour defined in title_gd.txt:

- Against pure black #000000 (L = 0.0000): 4.71 : 1 (theoretical maximum ceiling; barely passes WCAG AA 4.5:1, fails WCAG AAA / XAG 102 7.0:1).
- Against title dark shade Color(0.03, 0.04, 0.07) (title_gd.txt line 50, L = 0.00314): 4.43 : 1 (Fails WCAG AA 4.5:1).
- Against settings panel background Color(0.047, 0.07, 0.12) (title_gd.txt line 155, L = 0.00601): 4.21 : 1 (Fails WCAG AA 4.5:1).
- Against secondary button background Color(0.133, 0.176, 0.267) (title_gd.txt line 104, L = 0.02617): 3.09 : 1 (Fails WCAG AA 4.5:1).

Rendering essential control instructions at 12 px (7 px at the 0.6 floor) in #7d7768 (4.21:1 to 4.43:1 on the game's dark blue-black panels) fails both size and contrast expectations.

**Primary button hover/pressed state (title_gd.txt lines 112, 118):**

Font colour Color("#1c1405") (L = 0.00757) on hover/pressed background Color("#e2bb62") (L = 0.5259) yields 10.00 : 1 (Passes WCAG AA 4.5:1 and AAA 7.0:1).

**Gold border/hold tone Color(0.816, 0.651, 0.294) (title_gd.txt line 156; board_gd.txt in evidence_pack_job7.md):**

Has L = 0.4123. If HUD.GILT uses this same gold value, then #1c1405 text on HUD.GILT (title_gd.txt lines 104, 118) is 8.03 : 1, and HUD.GILT text on the settings panel Color(0.047, 0.07, 0.12) (title_gd.txt lines 155, 173) is 8.25 : 1.

**Unquoted HUD colour constants (UNSURE):**

Exact RGB values for HUD.GILT, HUD.GILT2, HUD.BONE, HUD.BONE2, HUD.IRON3, and HUD.EMBER (title_gd.txt lines 58, 61, 82, 105, 113, 118, 173, 197; hud_gd.txt line 651 in evidence_pack_job7.md) are defined inside godot/ui/battle/hud.gd and are UNSURE from this pack.

### What the Guidelines Say (from memory)

Xbox Accessibility Guidelines (XAG) 101: Text Display (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101, from memory) and GAG Basic/Intermediate: "Use an easily readable default font size" / "Allow the font size to be adjusted" (https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/, from memory): Recommend a minimum default body text size of 18 px at 1080p for PC monitor viewing distances, clear non-condensed/non-ornate fonts for functional UI, and independent text scaling.

WCAG 2.1 SC 1.4.3 Contrast (Minimum) (Level AA) (4.5:1 for normal text, https://www.w3.org/TR/WCAG21/#contrast-minimum, from memory), SC 1.4.6 Contrast (Enhanced) (Level AAA) (7.0:1, https://www.w3.org/TR/WCAG21/#contrast-enhanced, from memory), and XAG 102: Contrast (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102, from memory): Require at least 4.5:1 contrast for normal UI text and recommend 7.0:1 for small HUD labels.

## 4. Input Remapping

**Verdict: FAIL (Feature NOT PRESENT)** (No input remapping exists in settings or project.godot, zero InputMap actions are defined, and title.gd explicitly disables UI focus on buttons).

### Code and Pack Evidence

**Complete absence of InputMap and remapping:**

project_godot.txt (lines 1-58) has no [input] section and no custom actions.

Grep across main_gd.txt, title_gd.txt, hud_gd.txt, fx_api_md.txt, look_gd.txt, and board_gd.txt returns zero hits for InputMap, joypad, gamepad, or controller (evidence_pack_job7.md, "Input").

Neither main_gd.txt (line 20) nor title_gd.txt (lines 173-188) stores or displays keybindings.

**What this absence means for the documented control scheme (hud_gd.txt line 470, in evidence_pack_job7.md, "Input"):**

The scheme spreads 15+ inputs across the left keyboard (WASD pan, Q/E turn, 1-6 weapon select, B brace, Tab next ship, Esc cancel, T top-down, R threat map, F focus), the far right keyboard (Enter end activation, Home reset view), and a 3-button scroll mouse (left-click move/fire, left-drag pan, right-drag orbit, wheel zoom).

**Non-QWERTY layouts (AZERTY, QWERTZ, Dvorak):** If key polling inspects character keycodes rather than physical scancodes (whether battle.gd/hud.gd checks keycode or physical_keycode is UNSURE), WASD, Q/E, and 1-6 break spatially on AZERTY keyboards.

**Single-hand and limited-reach players:** Splitting frequent turn-end (Enter) and camera reset (Home) far from the WASD/Q/E cluster forces wide hand travel or two-handed reach. Left-handed mouse users cannot rebind WASD/Q/E to the right side of the keyboard.

**Missing keyboard equivalents for mouse wheel and right-drag:** There are no documented keys for wheel zoom or right-drag orbit (hud_gd.txt line 470 in evidence_pack_job7.md, "Input").

**Menu keyboard navigation is actively blocked in title_gd.txt:** In title_gd.txt lines 100 and 116, _button() sets b.focus_mode = Control.FOCUS_NONE and b.add_theme_stylebox_override("focus", StyleBoxEmpty.new()) on every title and settings button. This blocks Godot's built-in ui_up/ui_down/ui_accept keyboard and controller focus navigation across the title menu and settings screen.

**How the current code structure helps or blocks a minimum viable InputMap step in Godot:**

**What helps:** main_gd.txt already centralizes JSON persistence in user://settings.json (_load_settings() at lines 122-128, save_settings() at lines 130-135, _on_battle_option() at lines 167-169), and title_gd.txt builds the settings menu from compact row helpers (_row, _toggle, _choice, _slider at lines 195-253). Adding a "binds" dictionary to main.settings that serializes InputMap overrides to user://settings.json and applies them in _apply_settings() fits cleanly into main.gd.

**What blocks / needs refactoring:**

Because project_godot.txt has no [input] section, the battle scene (battle.gd/hud.gd, full code not attached, UNSURE) currently polls raw key/mouse events directly and must be refactored to check named InputMap actions (such as turn_left, turn_right, end_activation, zoom_in, zoom_out, orbit_left, orbit_right).

The hardcoded help string keys_text (hud_gd.txt line 470) must be built dynamically from InputMap.action_get_events() so rebound keys appear accurately on screen.

title_gd.txt lines 100 and 116 must change Control.FOCUS_NONE to Control.FOCUS_ALL and replace StyleBoxEmpty with a high-contrast focus border.

### What the Guidelines Say (from memory)

Xbox Accessibility Guidelines (XAG) 107: Input (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107, from memory) and GAG Basic: "Allow controls to be remapped" (https://gameaccessibilityguidelines.com/allow-controls-to-be-remapped/, from memory): Require remappable controls, keyboard/controller navigation across all menus with visible focus indicators (also WCAG 2.1 SC 2.1.1 Keyboard and SC 2.4.7 Focus Visible, https://www.w3.org/TR/WCAG21/#keyboard-accessible, from memory), and alternative mappings for mouse wheel or multi-button mouse actions.

## 5. Hold-vs-Toggle and Input Burden

**Verdict: PARTIAL** (Turn-based pacing with zero real-time input pressure, non-blocking hit pauses, WASD pan, and one-key T/F/Home camera shortcuts strongly reduce motor load, but right-drag orbit requires simultaneous hold-and-move with no toggle or key alternative, and keyboard-only targeting is UNSURE).

### Code and Pack Evidence

**Turn-based advantages and existing motor helpers (Credit where it matters):**

**Zero time pressure:** Voidsworn is strictly turn-based, resolving ship activations one at a time (evidence_pack_job7.md, "Input"). Players never face reaction-time windows or quick-time events.

**Hit pause never blocks input:** fx_api_md.txt section 7, line 124 guarantees that hit-pause slowdowns (fx.anim_speed()) never block player input.

**Single-tap camera shortcuts and keyboard pan:** Alongside left-drag pan, hud_gd.txt line 470 provides WASD pan plus single-press keys for T (top-down view), F (focus active/selected ship), and Home (reset view) (evidence_pack_job7.md, "Input"). In particular, pressing T for top-down view flattens perspective foreshortening, making hexes easier to click.

**Remaining hold-drag and precision burdens:**

**No hold-vs-toggle setting:** Neither main_gd.txt line 20 nor title_gd.txt lines 173-188 offers a drag-toggle or camera-latch option (evidence_pack_job7.md, "The settings system" and "Input").

**Simultaneous hold + move required for right-drag orbit (hud_gd.txt line 470 in evidence_pack_job7.md, "Input"):** Unlike panning (which has WASD), camera orbit is documented solely as right-drag orbit. Holding a secondary mouse button while moving the cursor is difficult or impossible for players using eye-gaze trackers, head mice, mouth sticks, trackpads, or single-switch clickers, or players with hand tremor/grip fatigue.

**Slider persistence tied to drag_ended (title_gd.txt lines 238-253):** In _slider(), value_changed updates main.settings[key] in memory (lines 249-250), but main.save_settings() (which calls _apply_settings() to update live music volume, main_gd.txt lines 130-146) is only connected to sl.drag_ended (line 251) or the "Done" button (line 190).

**Mouse-click spatial targeting (hud_gd.txt line 470 in evidence_pack_job7.md, "Input"):** Moving ("click a gold hex to move") and firing ("click an enemy to fire") rely on 3D mouse picking. Whether a keyboard-only path can cycle and confirm destination hexes and enemy targets to complete a full activation is UNSURE (evidence_pack_job7.md, "Input").

### What the Guidelines Say (from memory)

Xbox Accessibility Guidelines (XAG) 107: Input (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107, from memory) and GAG Basic: "Avoid/provide alternatives to requiring buttons to be held down" (https://gameaccessibilityguidelines.com/avoid-provide-alternatives-to-requiring-buttons-to-be-held-down/, from memory): Require toggle alternatives for hold interactions and discrete single-button/key alternatives for simultaneous hold-and-drag gestures.

## 6. Other Guideline Areas Evidenced in the Pack

**Verdict: PARTIAL** (Motion comfort controls, separate audio sliders/toggles, battle tips, and mid-battle AI difficulty switching are well-implemented, but captions are absent, there is no slower-than-normal animation speed, AI defaults to "veteran", and title toasts auto-hide after 3.0 seconds).

### Code and Pack Evidence

**Motion comfort (PASS - well-covered):**

**Screen shake (main_gd.txt lines 20, 163-164; title_gd.txt line 182; fx_api_md.txt section 7, line 123; section 8, lines 129-130):** Shake is positional only (cam.h_offset, cam.v_offset, no rotational roll), brief (0.15-0.30 s normally, 0.35-0.45 s on capital deaths), attenuated by distance, halved automatically by reduce_flashing, and configurable in Settings to Full (1.0), Reduced (0.5), or Off (0.0).

**Camera follow and Cut-ins (main_gd.txt lines 20, 158-159; title_gd.txt lines 183-184):** Players can turn "Follow enemy activations" (follow) Off to prevent automatic camera panning on enemy turns, and set "Cut-ins" (cine) to "Key moments", "Every attack", or "Off".

**Dead-star lensing (fx_api_md.txt section 1, line 29; section 9, line 140):** Dead-star maps render gravitational lensing and a turning accretion disc; running play_godot_safe.bat (Compatibility renderer) drops distortion and the lens, though there is no in-menu toggle for lensing on the Forward Plus renderer.

**Audio controls and captions (PARTIAL):**

**Separate Sound and Music controls (main_gd.txt lines 20, 81-86, 144-146, 153-155; title_gd.txt lines 174-177):** SFX and Music have separate On/Off toggles and 0.0-1.0 volume sliders.

**No captions or subtitles (evidence_pack_job7.md, "Audio information"):** Zero hits for caption or subtitle across all attached files and FEATURES.md.

**Audio-only cues (UNSURE):** FEATURES.md line 96 notes faction battle music with intensity layers (evidence_pack_job7.md, "Audio information"). Whether any spoken voice lines exist or whether any gameplay-critical cue is carried by audio alone is UNSURE (evidence_pack_job7.md, "Audio information"), though fx_api_md.txt sections 3-6 document distinct visual effects and floating damage numbers (impacts, line 81) for combat events.

**Game speed and timed UI text (PARTIAL):**

**Fast mode exists, Slow mode does not (main_gd.txt lines 20, 156; title_gd.txt line 178; evidence_pack_job7.md, "Input"):** Settings offers "Speed" as Normal (1.0) or Fast (0.45), with no slower-than-normal (Slow) option to give players with cognitive or visual processing impairments more time to read multi-hit volleys and floating damage numbers (fx_api_md.txt section 3, line 81).

**Fixed 3.0 s toast timeout (title_gd.txt lines 131-138):** toast(t) auto-fades after _toast_t = 3.0 seconds, which can expire before low-vision or dyslexic players finish reading.

**Difficulty and cognitive support (PARTIAL):**

**Adjustable AI (main_gd.txt lines 20, 157, 167-169; title_gd.txt line 179):** "Enemy AI" offers "Veteran" and "Standard" and can be changed from the in-battle menu (evidence_pack_job7.md, "The settings system"). However, "veteran" is the default in main_gd.txt line 20 rather than "standard".

**Tutorials and tips (main_gd.txt lines 20, 160; title_gd.txt lines 75, 185):** "Battle tips" defaults to true (On) and "How to play" is on the main menu.

**Permadeath pressure (title_gd.txt line 61; main_gd.txt line 214):** Non-boss campaign battles allow retreat (b.can_retreat, main_gd.txt line 214), but hull and captain loss are permanent (title_gd.txt line 61) with no documented setting to allow battle retries or disable permadeath.

### What the Guidelines Say (from memory)

Xbox Accessibility Guidelines (XAG) 117: Motion Sickness (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117, from memory) and GAG Intermediate: "Provide an option to turn off screen shake" (https://gameaccessibilityguidelines.com/provide-an-option-to-turn-off-screen-shake/, from memory).

XAG 105: Captions (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/105, from memory) and XAG 106: Audio Customization (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/106, from memory).

XAG 108: Game Difficulty (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/108, from memory) and GAG Basic: "Provide a wide range of difficulty levels" (https://gameaccessibilityguidelines.com/provide-a-wide-range-of-difficulty-levels/, from memory).

WCAG 2.1 SC 2.2.1 Timing Adjustable (https://www.w3.org/TR/WCAG21/#timing-adjustable, from memory).

## (a) Ranked Fixes (Ordered by Player Protection / Unblocking per Unit of Build Effort)

**1. Fix the 0.12 s salvo flash-budget loophole (fx_api_md.txt section 8, line 128; godot/fx/fx.gd):**

Change: Either raise the bright-core suppression window from 0.12 s to 0.333 s (so any second flash landing within 0.333 s of a counted flash suppresses its bright core and draws as smoke and sparks), or ensure salvos within 0.12 s hold a single continuous luminance envelope without dipping between shots.

Why #1: One constant/condition change in fx.gd protects photosensitive players in the default (reduce_flashing = false) state under WCAG 2.3.1/2.3.2 and XAG 118.

**2. Raise HUD base font sizes, raise the k floor, add a Text size setting, and brighten #7d7768 (title_gd.txt lines 30-34, 173-188; hud_gd.txt lines 118, 125, 148, 153-154, 470, 537-538):**

Change: Raise the controls help line (hud_gd.txt line 470) from #7d7768 (4.21:1 on settings panel) to HUD.BONE or #c8c2b4 (>= 7.0:1), lift HUD base sizes from 12-15 to 16-18 at 1080p, raise the k clamp floor from 0.6 to 0.85, recompute k on viewport size_changed, and add a "Text scale" choice (100% / 125% / 150%) in main.settings and title.gd that multiplies k.

Why #2: High-leverage change in s(v) and 6 theme lines in hud.gd/title.gd that immediately fixes illegible 7-15 px text and low contrast for all low-vision and small-window/Steam Deck players (XAG 101, XAG 102, WCAG 1.4.3).

**3. Re-enable UI button focus in title.gd (title_gd.txt lines 100, 116):**

Change: Change b.focus_mode = Control.FOCUS_NONE to Control.FOCUS_ALL and replace StyleBoxEmpty.new() on "focus" with a 2 px HUD.GILT border stylebox; also call main.save_settings() on HSlider.value_changed (or focus_exited) in _slider() (title_gd.txt lines 249-251).

Why #3: Two lines of code in title_gd.txt immediately unblock full keyboard and controller menu navigation on the title screen and settings panel (XAG 107, WCAG 2.1.1, WCAG 2.4.7).

**4. Add distinct stroke patterns and on-board icons/labels to board zones (board_gd.txt lines 169-176, 191, 203):**

Change: Differentiate exit green (alpha 0.16), guard/transport-exit red (alpha 0.16), and hold/relay gold (alpha 0.30 / ring 0.90) by geometry as well as hue: e.g., outward chevron border for exit hexes, cross-hatched or dashed inner border + shield/ skull icon for guard zones, and beacon icon for hold/relay hexes, plus shift exit/guard hues to a colour-blind-safe blue/orange-vermilion pair.

Why #4: Low-effort procedural drawing in board.gd eliminates the red/green/gold CVD collision on tactical objectives (XAG 104, WCAG 1.4.1).

**5. Add keyboard orbit/zoom keys and a drag-toggle setting (project_godot.txt; main_gd.txt line 20; title_gd.txt lines 173-188; hud_gd.txt line 470):**

Change: Add keyboard keys for camera orbit and zoom (e.g., Z/X or arrow keys to orbit, +/- or PgUp/PgDn to zoom) alongside WASD pan, and add a "Toggle camera drag" option in Settings so clicking right-mouse latches/releases orbit without holding the button down.

Why #5: Removes the simultaneous hold-and-move requirement of right-drag orbit and provides keyboard parity for wheel zoom (XAG 107, GAG Hold-Controls).

**6. Add a "Slow" battle speed option and change default AI to "standard" (main_gd.txt line 20; title_gd.txt lines 131-138, 178-179):**

Change: Expand "Speed" in title_gd.txt line 178 to [[1.5, "Slow"], [1.0, "Normal"], [0.45, "Fast"]], extend toast_lbl duration from 3.0 s to 6.0 s (lines 133-138), and consider defaulting "ai" in main_gd.txt line 20 to "standard".

Why #6: Trivial 3-line change in main.gd and title.gd that improves cognitive and visual accessibility (XAG 108, WCAG 2.2.1).

**7. Migrate hardcoded battle inputs to InputMap actions and add a key-remapping panel (project_godot.txt; main_gd.txt; title_gd.txt; hud_gd.txt line 470):**

Change: Define [input] actions in project.godot, replace raw key polling in battle.gd/hud.gd with InputMap checks, generate keys_text (hud_gd.txt line 470) dynamically from InputMap.action_get_events(), and add a key-rebind sub-panel in title.gd persisted under main.settings["binds"] in user://settings.json.

Why #7: Medium build effort across project.godot, battle.gd, hud.gd, and title.gd, unblocking AZERTY/Dvorak, left-handed, and adaptive-controller players (XAG 107, GAG Basic Remapping).

## (b) Consolidated UNSURE List

- Exact faction RGB tint values: Stored in data files outside the attached pack (evidence_pack_job7.md, "Colour: factions and danger").
- Board zone icons or text labels: Whether exit, guard, hold, or terrain hexes render 2D/3D icons or text labels on the board in the Godot build (evidence_pack_job7.md, "Colour: factions and danger").
- Threat map overlay (R key) visual channels: Whether the threat map encodes danger by colour alone or includes numbers, hatching, or outlines (evidence_pack_job7.md, "Colour: factions and danger").
- On-board ship selection ring and footprint marker details: Whether the selection ring and footprint marker (fx_api_md.txt section 2, line 41) show faction crests or friend/foe shapes on the 3D board.
- Internal fx.gd salvo luminance behaviour: How godot/fx/fx.gd implements the 0.12 s salvo merge window (fx_api_md.txt section 8, line 128), specifically whether multiple hits within 0.12 s dip and re-flash at high frequency or hold a continuous luminance plateau.
- Exact RGB values of HUD palette constants and HUD panel backgrounds: HUD.GILT, HUD.GILT2, HUD.BONE, HUD.BONE2, HUD.IRON3, HUD.EMBER, and the background behind #7d7768 in hud_gd.txt are defined in godot/ui/battle/hud.gd (not attached in full) (evidence_pack_job7.md, "Text size and contrast"; title_gd.txt lines 58-197).
- Whether hud.gd updates k on window resize and whether campaign UI uses UnifrakturMaguntia at small sizes: Full hud.gd and campaign_ui.gd sources are not in the pack (evidence_pack_job7.md).
- Keyboard-only battle activation path and raw keycode vs physical scancode polling: Whether a player can select movement hexes and enemy targets using only the keyboard, and whether battle.gd/hud.gd checks keycode or physical_keycode (evidence_pack_job7.md, "Input").
- Audio-only gameplay information and voice lines: Whether any gameplay-critical cue is carried by audio alone or whether spoken audio exists that would require captions (evidence_pack_job7.md, "Audio information").
- Campaign retry/save options and exact b.user_speed scaling in battle.gd: Full battle.gd and campaign.gd sources are outside the pack (main_gd.txt lines 156, 200-235).

## (c) One-Sentence Verdicts

**Area 1 (Colour-blind readability): PARTIAL** - Factions have non-colour crests, names, and distinct effect geometries, but board exit, guard, and hold zones rely on low-alpha green, red, and gold fills that collide for colour-blind players with no colour-blind settings.

**Area 2 (Flashing and photosensitivity): PARTIAL** - Both the counted-flash cap and the reduce_flashing mode are verified and wired end-to-end, but the default mode's 0.12 s salvo merge window risks allowing more than 3 actual luminance flashes per second if shots within a salvo dip and re-peak.

**Area 3 (Text size and contrast): FAIL** - All battle HUD base text sizes (12-15 px at 1080p, 7-9 px at the 0.6 scaling floor) fall below the 18 px PC guideline minimum with no user scaling option, and the 12 px #7d7768 controls help line fails WCAG AA 4.5:1 contrast on the game's dark blue-black UI panels.

**Area 4 (Input remapping): FAIL (NOT PRESENT)** - No input remapping or InputMap actions exist in project.godot or Settings, and title.gd disables focus on all buttons (Control.FOCUS_NONE), blocking keyboard and controller menu navigation.

**Area 5 (Hold-vs-toggle and input burden): PARTIAL** - Turn-based pacing with no timers, non-blocking hit pauses, WASD pan, and one-key T/F/Home camera views reduce motor burden, but right-drag orbit requires simultaneous hold-and-move with no toggle or keyboard orbit alternative.

**Area 6 (Other guideline areas): PARTIAL** - Motion comfort toggles (positional shake off/reduced, camera follow off, cut-ins off), separate audio sliders, battle tips, and mid-battle AI switching are strong, but captions and a slower animation speed are absent, AI defaults to "veteran", and title toasts expire in 3 seconds.

**Overall Verdict: PARTIAL** - Voidsworn has a thoughtful visual effects accessibility architecture (fixed exposure, a thorough reduce_flashing mode, positional-only shake controls, camera-follow and cut-in toggles, and turn-based pacing), but it currently fails core UI readability and input accessibility baselines due to 12-15 px low-contrast HUD text, red/green/gold board zone collisions, disabled button focus, and a total absence of InputMap remapping.
