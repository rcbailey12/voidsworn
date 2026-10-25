# Tactical UI readability shelf (Gemini, Argon High, Oct 25, 2026)

Filed verbatim from a fresh Gemini chat at https://gemini.google.com/app/56dee9e616ef7658. Ran Oct 25, 2026, 3:40-3:50 PM CDT (runtime-measured).

Model verification: session already signed in as rcbailey12@gmail.com (Ryan Bailey, Pro); no sign-in flow needed. In the fresh chat, the mode picker showed "4 Argon - Complex tasks" already selected (checkmark in the picker menu). Thinking level was initially "Low - Quick and efficient"; changed to "High - Extra thorough". Verified before submitting: the picker button read "Open mode picker, currently Argon High" and the composer chip read "Argon High". Both Argon model and High thinking level confirmed. No usage-cap or payment prompt appeared at any point; no upgrade, no payment, no fallback. No other chat was opened, referenced, or reused (older Voidsworn and effects-shelf chats visible in the sidebar were not touched).

Reply status: complete, not truncated. All 8 requested sections plus the ending Sources section are present; response controls appeared and the "Stop response" control disappeared. Research only; nothing filed, bought, or posted by the run itself.

Chair note (not part of Gemini's shelf): this is a LEADS-ONLY idea shelf, not a specification. It does not override any existing effects sheet or design document, and it does not decide the engine call. See the screening note for the chair's flags. This shelf is one input for Opus and Ryan, not a verdict.

## Gemini reply, verbatim

This document is a tactical battle UI readability idea shelf only. It is NOT a specification, it does NOT override any existing effects sheet or design document, and it does NOT decide the engine call between Godot 4.7 and Babylon 9.30. Every item below is framed as a [Proposal] or lead for a human builder to test, and any reference to current UI behavior beyond the established baseline facts is tagged UNSURE.

1. Hex Board Readability at Battle Zoom

At full-board tactical zoom with around 18-22 ships (the leaning density of about 20 ships) on screen, the cyan hex grid must support fast spatial counting without turning into shimmering line noise under ships, shields, and weapon effects.

[Proposal] Corner-Weighted Cyan Hex Grid with Mid-Edge Falloff

Idea: Keep the standing cyan hex grid rule, but modulate alpha along each hex edge: render hex vertices and short corner ticks (covering 20-35% of each segment near the corners) at 35-55% opacity, while fading the center of each hex edge down to 10-20% opacity across empty board space.

Why it helps readability: Preserves the six-sided geometry needed to count hex distances at a glance while cutting high-frequency line shimmer and moire patterns by 50-70% when the camera pulls back to show the entire board.

[Proposal] Distinct Geometry and Stroke Weight for Hovered vs. Selected Hex

Idea: Whether hover and selection hex highlights currently exist is UNSURE. Propose differentiating them by shape rather than brightness alone: give the hovered hex an inset dashed or six-corner-bracket cyan outline at 2-3 px screen-space width and 60-80% opacity; give the selected hex a continuous 3-5 px solid outer cyan ring with tiny inward-pointing triangular notches at all six vertices and a soft 12-22% floor tint.

Why it helps readability: Allows the player to hover across a selected ship's hex or adjacent hexes without the two states merging into a single bright blob at full-board zoom.

[Proposal] Outer-Hull Perimeter Ribbon for Movement Range

Idea: Whether a movement range overlay currently exists is UNSURE. Instead of drawing full six-sided borders around every individual reachable hex, draw a single continuous outer perimeter ribbon (3-5 px wide in screen space) around the union of reachable hexes, and mark each valid interior destination hex with a small centered dot (2-4 px diameter) and a subtle 8-16% floor tint. If movement includes distinct action costs (UNSURE), separate standard movement from extended movement using a solid outer perimeter versus a dashed outer perimeter.

Why it helps readability: Eliminates an internal honeycomb of overlapping lines, letting the player read a ship's reachable footprint as one clean shape in 0.2-0.5 seconds.

[Proposal] Edge-Rail Firing Arcs with Outer Rim Cap

Idea: Whether firing arc overlays currently exist is UNSURE. Propose rendering firing arcs on demand (for the hovered or selected ship/weapon) using two crisp radial boundary rails (2-4 px screen-space width) extending from the ship's hex out to the weapon's maximum hex range, capped by a hex-stepped outer arc rim with only an 8-15% gradient wash along the inside of the rim.

Why it helps readability: Avoids filling large wedges of the board with translucent colour that would wash out the cyan hex grid and world-space faction shields, while keeping left and right arc limits razor-sharp.

[Proposal] Hex-Ring Bow Wedge for Ship Facing

Idea: Whether a hex-level facing indicator currently exists is UNSURE. Attach a flat, high-contrast forward prow wedge (spanning 20-30% of the front hex edge and protruding 4-7 px in screen space) to the base ring of every ship on the board, paired with two small stern notches on the rear hex edge.

Why it helps readability: 3D ship hulls can foreshorten at pitched tactical camera angles; a hex-plane bow wedge guarantees that facing direction is unmistakable across all 18-22 ships when zoomed out.

[Proposal] Screen-Space Thickness Clamping at Full-Board Zoom

Idea: Clamp active tactical geometry (selected hex ring, movement perimeter, active firing arc rails, and bow facing wedges) to a constant screen-space thickness of 2-5 px regardless of camera zoom distance, while letting passive interior hex grid lines fade down to 10-20% opacity at maximum zoom-out.

Why it helps readability: Prevents critical tactical lines from shrinking into sub-pixel flicker when viewing the whole battle board at once.

2. Ship Readability at a Glance

Without selecting a ship, a player scanning 18-22 vessels needs immediate answers on faction, allegiance, shield/hull state, physical damage rung, and carrier wing status.

[Proposal] Faction Crest Shapes and Base-Ring Border Motifs (Never Colour Alone)

Idea: Whether floating ship badges or base rings currently exist is UNSURE. Using the standing linear RGB faction values, pair each faction's colour with a unique icon silhouette and base-ring border pattern:

Voidsworn - weapon (1.0, 0.45, 0.15), shield (1.0, 0.46, 0.16), engine (1.0, 0.50, 0.16): Upward twin-chevron crest + solid double-notched base ring.

Hegemony - weapon (0.55, 0.82, 1.0), shield (0.38, 0.68, 1.0), engine (0.45, 0.72, 1.0): Hexagonal bastion shield crest + parallel double-line base ring.

Corsair - weapon (0.95, 0.22, 0.10), shield (0.85, 0.16, 0.10), engine (1.0, 0.38, 0.16): Jagged sawtooth diamond crest + diagonal slash-hatched base ring.

Chorus - weapon (0.85, 0.90, 0.30), no shield (hull hits), engine (0.80, 0.90, 0.28): Concentric harmonic-arc crest + dotted-triplet base ring.

Ithar - weapon (0.75, 1.0, 0.88), shield (0.72, 1.0, 0.86), engine (0.62, 1.0, 0.84): Four-point star-lattice crest + hollow diamond-inset base ring.

Deathless - weapon (0.20, 1.0, 0.38), no shield (hull hits), engine (0.15, 1.0, 0.35): Inverted obelisk/skull-wedge crest + inward-spiked base ring.

Why it helps readability: Separates factions whose linear RGB values sit close together in warm orange-red (Voidsworn vs. Corsair), cool blue-cyan (Hegemony vs. Ithar vs. cyan grid), or high-green yellow-lime (Chorus vs. Deathless), allowing instant identification at full-board zoom.

[Proposal] Split Status Micro-Plate with Structural Shield Absence for Chorus and Deathless

Idea: Whether world-space ship status bars currently exist is UNSURE. Propose a compact screen-space status plate (38-56 px wide, 8-14 px tall) anchored above or below each ship over a dark matte backplate (75-90% opacity):

For shielded factions (Voidsworn, Hegemony, Corsair, Ithar), render the top interface shield bar in cyan (per the standing rule that interface shield bars stay cyan while world-space shields use faction colours) at 3-5 px height, separated by a 1-2 px dark gutter from a 4-6 px hull bar rendered in high-contrast warm white/ivory blocks.

For Chorus and Deathless (which have no shield and take hull hits directly), completely omit the upper shield frame rather than drawing an empty dark slot, and render a single thicker hull bar (5-8 px tall) with reinforced side brackets.

Why it helps readability: Keeps cyan interface shields visually distinct from hull integrity while preventing players from mistaking an unshielded Chorus or Deathless vessel for a shielded ship whose shields have been stripped.

[Proposal] Trauma-Silhouette Hull Framing for the Six-Step Damage Ladder

Idea: The standing visual bar for damage is physical trauma (holes with streaming parts, fire, and structural breaks, not orange lines) across the six-step ladder: intact, scorched, dented, exposed structure, hull breach, and wreck. Because 3D hull holes and streaming debris can be small (20-40 px) when zoomed out, mirror the physical trauma directly in the silhouette of the ship's UI hull plate without using orange lines:

Intact: Clean, straight-edged hull bar frame.

Scorched: Stippled charcoal soot shading along 20-35% of the plate's outer bevel.

Dented: Visibly bent, concave top and bottom frame edges on the hull plate.

Exposed structure: Internal skeletal cross-ribs revealed inside the depleted portion of the hull bar track.

Hull breach: A physical gap splitting the hull bar frame into two uneven halves with 2-4 tiny drifting grey debris flecks in the break.

Wreck: Status plate collapses and disappears; only a dim (30-45% opacity), split-hull icon rests flat on the hex floor so live ships command 90-100% of foreground attention.

Why it helps readability: Reinforces the 3D physical trauma aesthetic at full-board zoom so the player can read the exact damage-ladder rung of any ship without selecting it and without relying on glowing orange lines.

[Proposal] Carrier Bay Chevrons and Wing Formation Badges

Idea: Whether carrier and wing UI indicators currently exist is UNSURE. On carrier status plates, tuck a row of 2-6 micro-chevrons (4-6 px wide each) directly beneath the hull bar: solid filled chevrons for wings docked/ready, hollow outlined chevrons for wings currently active on the board, and X-slashed notches for destroyed wings. Give deployed wings on the board a clustered multi-craft delta icon (instead of a single-hull bar frame) and reveal a faint 15-30% opacity dotted tether back to their parent carrier when either unit is hovered.

Why it helps readability: Lets the player tell at a glance which carriers still hold reserve strike power and which board contacts are wings versus independent warships.

3. Threat and Intent Readability

In a strictly turn-based battle with 18-22 ships, the player needs to connect the top bar's activation signals to the 3D board and read incoming torpedo and lance telegraphs without drowning the hex grid in overlapping rings.

[Proposal] On-Board Next-Actor Sequence Badges

Idea: Beyond the standing facts that the top bar shows enemy activation and there is an enemy-acting indicator, whether on-board turn-order numbers exist is UNSURE. Propose stamping the next one to three enemy ships scheduled to act with a high-contrast numeral tag (1, 2, 3 in 13-16 px bold text inside a dark-backed diamond pill) on their hex base ring, and giving the next-acting (1) enemy a slow, non-flashing breathing bracket (0.4-0.8 cycles per second).

Why it helps readability: Eliminates searching the board to figure out which specific enemy ship corresponds to the upcoming activation slot.

[Proposal] Top-Bar-to-Board Activation Tether and Threat Tip Highlight

Idea: Known UI facts establish that the top bar shows enemy activation, an enemy-acting indicator, and a Threat tip from round 2 (rounds 2-3 onward). Propose linking these existing elements to the hex board: when an enemy activates, draw a brief (300-500 ms) smooth-fading spotlight ring around its hex and lock a high-contrast side bracket onto its status plate until its action finishes. When the Threat tip appears from rounds 2-3 onward, allow hovering or focusing the Threat tip banner to outline the relevant threatening ship(s) and their projected attack lanes on the board at 80-100% opacity while dimming unrelated markers to 25-40%.

Why it helps readability: Bridges the top-screen HUD and the 3D hex board so the player immediately sees which ship is acting or generating the Threat tip.

[Proposal] Distinct Telegraph Geometry for Torpedoes (Two-Stage + 700-900 ms Ramp + Interception) vs. Lance Aiming

Idea: Keep torpedo telegraphs and lance aiming visually unmistakable by giving them contrasting geometry:

Torpedo Stage 1 (Trajectory & Lock): Render a segmented hex-to-hex track made of spaced directional chevrons (2-4 px thick) leading to hollow corner brackets on the threatened impact hexes.

Torpedo Stage 2 (700-900 ms Ramp to White): During the 700-900 ms (around 800 ms) ramp to white, confine the high-luminance white ramp to the inner core of the torpedo track and a 2-4 px inner bevel on the impact hex, always encased inside a 2-3 px dark charcoal outer border so the white ramp stays legible over bright cyan shields or pale Ithar hulls without triggering full-screen luminance flashes.

Torpedo Interception Call: Place a dedicated pill badge (a crosshair-over-chevron icon with a 3.5:1 to 6.0:1 contrast ratio) directly on the interceptable hex segment, paired with a thin dashed arc connecting from any allied ship or wing capable of executing the interception.

Lance Aiming: Render lance aiming as a continuous, unbroken razor corridor bounded by two solid parallel rail lines (2-3 px wide) with inward calibration ticks at each hex boundary and a locked diamond reticle on every hex in the beam's line of fire.

Why it helps readability: Segmented chevrons (torpedo) versus continuous parallel rails (lance) let the player distinguish an interceptable two-stage torpedo from a locked lance beam in 0.3-0.6 seconds, even while multiple telegraphs cross the same cluster of hexes.

[Proposal] Aim-Line Range Band Ticks Instead of Full-Board Concentric Circles

Idea: Whether range band rings currently exist is UNSURE. Instead of drawing concentric full-board hex rings for every weapon range tier (which creates visual spaghetti across 18-22 ships), display a single outer hex perimeter for the currently active weapon's maximum range, and mark intermediate range bands (UNSURE of exact range band counts) as perpendicular gate ticks along the active targeting line between the firing ship and the hovered hex.

Why it helps readability: Gives exact range-band feedback right where the player's cursor is aiming while keeping 85-95% of the hex board free of overlapping range circles.

4. Targeting and Orders

Issuing orders in a strictly turn-based roguelite requires unambiguous feedback on target validity, weapon state, Command cost, and order commitment.

[Proposal] Corner-Bracket Target Lock with Hatched Damage Preview

Idea: Whether target lock reticles or damage previews currently exist is UNSURE. When aiming a weapon at a valid enemy ship, snap four angled corner brackets (3-5 px thick) around the target's hex and preview the projected shield/hull damage on the target's status plate using a diagonal static hatch pattern (at 60-80% opacity) rather than a rapid blink.

Why it helps readability: Shows projected impact directly on the target's cyan shield bar and hull bar without violating flash limits or forcing the player to read a separate combat log.

[Proposal] Tri-State Weapon Cards and Coded Aiming Lines (Ready / Out of Range or Arc / Cooldown)

Idea: Whether a bottom weapon bar currently exists is UNSURE. Propose encoding weapon availability through three distinct card frames and aiming-line patterns:

Ready & In Range: Solid bright border, filled readiness pips, and a solid aiming line to the target.

Ready but Out of Range or Arc: Recessed frame with a dashed border, an inline badge showing the shortfall (e.g., +1 to +2 hexes or an arc-rotation arrow), and a wide-dashed aiming line on the board.

On Cooldown: Darkened card face (35-50% brightness), a radial conic clock-sweep overlay, and a bold numeric turn badge (1-3T in 14-18 px text) centered on the slot.

Why it helps readability: Eliminates guesswork when an attack cannot be ordered; the player immediately knows whether to move closer, rotate facing, or pick another weapon.

[Proposal] Persistent Command Token Cluster with Pre-Commit Cost Brackets

Idea: How Command availability is currently shown in the UI is UNSURE. Propose displaying available Command as discrete geometric tokens (6-10 px hexagonal pips with 2-4 px spacing) both in a fixed HUD anchor and mirrored above the active ship's order bar. When hovering any order that consumes Command, wrap the exact number of tokens to be spent in bright brackets and shift their fill to a diagonal hatch before the player clicks.

Why it helps readability: Prevents arithmetic errors during complex turns by showing both the cost of the hovered action and the exact Command remaining for other ships.

[Proposal] Ghost-Ship Post-Move Projection, Hazard Guardrails, and Optional Movement Undo Proposal

Idea: Do NOT assume an undo feature exists. To prevent costly misclicks in a turn-based roguelite:

Ghost-Ship Projection ([Proposal]): When hovering or staging a movement destination hex, render a 30-50% opacity ghost silhouette of the ship at the target hex and project its post-move firing arcs and valid target lines from that ghost position before the move is confirmed.

Two-Step / Hold-to-Confirm Guardrails ([Proposal]): If a staged move enters a telegraphed lance corridor or torpedo impact hex, or if the player clicks End Turn while ships still have unspent actions or Command, trigger a 350-600 ms hold-to-commit fill or an inline cursor-level confirm prompt stating the exact risk.

Single-Step Movement Undo Before Firing ([Proposal - New Feature, Not Assumed Existing]): As a purely optional design proposal for a builder to test, allow reverting a ship's movement back to its origin hex ONLY if no weapon has been fired, no interception has triggered, and no hidden board state has been revealed; lock the move permanently the instant an attack or reveal occurs.

Why it helps readability: Ghost projection lets the player verify firing arcs and range bands from a future hex before committing, cutting down on geometric miscalculations across the hex grid.

5. Information Hierarchy

When 18-22 ships, full weapon salvos, and physical trauma effects (holes, streaming debris, and fire) fill the screen, strict separation between persistent HUD, on-demand panels, and combat-phase decluttering keeps the interface calm.

UI Layer | Elements Included | Screen Footprint & Opacity Range
Always On Screen (Persistent) | Top bar enemy activation & enemy-acting indicator (known), Threat tip from rounds 2-3 onward (known), compact ship micro-plates ([Proposal]), active Command & weapon bar ([Proposal]) | Occupies 10-16% of total screen area; leaves 84-90% of the viewport open for the 3D hex board.
On Demand (Hover / Inspect) | Full numerical hull/shield values, detailed damage-ladder penalties (scorched through hull breach), weapon range/cooldown tables, carrier wing loadouts, and Rare (#62ccff) tags ([Proposal]) | Compact hover tooltip (150-300 ms delay, 180-260 px wide) or pinned side drawer (240-320 px wide) at 88-96% backplate opacity.
Combat Salvo Declutter Mode | Non-involved ship plates, passive interior hex grid lines, and secondary range markers ([Proposal]) | Automatically dims to 20-35% opacity during active weapon fire or torpedo resolution; involved ships stay at 90-100%.

[Proposal] Isolating Rare (#62ccff) Inside On-Demand Frames with a Rarity Glyph

Idea: Where the standing Rare colour (#62ccff) appears in the UI is UNSURE. Because #62ccff is a sky-cyan hex value that sits close to the cyan hex grid, cyan interface shield bars, and Hegemony linear RGB (0.55, 0.82, 1.0), restrict #62ccff to on-demand inspect cards, upgrade/loadout badges, and tooltip headers, and always pair it with a bevelled diamond rarity icon and a dark slate inner border (2-3 px wide).

Why it helps readability: Prevents players from confusing a #62ccff Rare badge with a cyan shield bar or Hegemony faction marker during battle.

[Proposal] Spring-Loaded Screen-Space Plate De-Collision and Matte Backplates

Idea: When 3-6 ships or wings cluster in adjacent hexes, apply a screen-space vertical separation offset (maintaining a 12-22 px gap between plates) connected by thin 1-2 px leader lines to each ship's hex center. Render all floating UI plates inside a dedicated 2D canvas layer above 3D fire and streaming debris particles, backed by an 80-92% opacity dark charcoal plate (luminance 0.02-0.05).

Why it helps readability: Guarantees that heavy hull-breach fire, streaming ship parts, and full-salvo explosions never bleed through status bars or cause adjacent ship labels to overlap into unreadable text soup.

6. Accessibility in the UI Layer

[Proposal] Colour-Blind-Safe Faction Coding Across All Six Linear RGB Palettes

Idea: Evaluating the game's six linear RGB palettes reveals three colour-vision collision zones:

Protanopia / Deuteranopia (Red-Green): Voidsworn (1.0, 0.45, 0.15) and Corsair (0.95, 0.22, 0.10) compress into similar warm browns/ambers, while Chorus (0.85, 0.90, 0.30) and Deathless (0.20, 1.0, 0.38) share high green values (0.90 vs. 1.0) and collapse into nearly identical yellow-greens.

Tritanopia (Blue-Yellow) & Cyan Collisions: Hegemony (0.55, 0.82, 1.0) and Ithar (0.75, 1.0, 0.88) sit close to the cyan hex grid, cyan interface shield bars, and Rare #62ccff.

Solution ([Proposal]): Never use colour alone. Enforce triple coding on every UI element: (1) unique faction crest icon, (2) distinct border stroke pattern (solid double-line for Hegemony, sawtooth slash for Corsair, dotted for Chorus, diamond-lattice for Ithar, spiked for Deathless, chevron-notched for Voidsworn), and (3) distinct outer container geometry for Allegiance (flat rectangular pill for friendly units vs. pointed bottom-chevron container for enemy units). Additionally, differentiate the two shieldless factions (Chorus and Deathless) by giving Chorus hull bars rounded pill ends and Deathless hull bars sharp 45-degree chamfered ends with vertical hash ticks.

Why it helps readability: A player with protanopia, deuteranopia, tritanopia, or full monochromacy can still distinguish all six factions, friend from foe, and shieldless from shielded ships in under 0.5-1.0 seconds.

[Proposal] PC Text Size and Luminance Contrast Ranges

Idea: Following WCAG 2.2 Contrast (Minimum) SC 1.4.3 and Non-Text Contrast SC 1.4.11 guidelines, target these ranges at a 1080p desktop baseline (with proportional scaling for 1440p/4K and a proposed 85-150% UI scale slider):

Tooltip and panel body text: 14-18 px regular/medium sans-serif, contrast ratio of 4.5:1 to 7.5:1 against dark UI panels.

World-space tactical numerals (turn order, cooldowns, hex distance): 13-16 px bold with a 1-2 px dark outline over an 80-92% dark backplate, maintaining 6.0:1 to 10.0:1 contrast.

Top-bar activation headers and Threat tip banners: 18-24 px bold, contrast ratio of 4.0:1 to 8.0:1.

Non-text UI components (hex selection rings, cyan shield segments, firing arc rails, faction crests): Contrast ratio of 3.0:1 to 4.5:1 against adjacent surfaces. Because Ithar (0.75, 1.0, 0.88) and Chorus (0.85, 0.90, 0.30) have very high relative luminance, never render white text over Ithar or Chorus fills; either use dark charcoal glyphs (luminance 0.02-0.05) inside those badges or place the bright faction-coloured icon over a dark slate container.

Why it helps readability: Prevents bright pastel/lime faction colours from washing out numbers and keeps tactical data crisp at desktop viewing distances.

[Proposal] High-Contrast Keyboard and Focus Ring Readability

Idea: Whether keyboard navigation is currently wired is UNSURE. Guided by WCAG 2.2 Focus Visible (SC 2.4.7), Focus Not Obscured (SC 2.4.11), and Focus Appearance (SC 2.4.13), give every focusable UI button and hex cursor a dual-layer focus ring: a 2-4 px solid high-luminance outer border paired with a 1-2 px dark inner separation gap, achieving a 3.5:1 to 6.0:1 contrast change between focused and unfocused states. Ensure on-demand tooltips anchor outside the focused element's bounding box so focus is never obscured.

Why it helps readability: Lets keyboard-driven tactical players track focus across weapon slots, top-bar Threat tips, and hex coordinates without losing the active selection in combat clutter.

[Proposal] UI Layer Coordination with the 1-3 Flashes-Per-Second Cap and Reduce-Flashing Option

Idea: Standing accessibility rules cap screen flashing at at most 3 flashes per second (1-3 flashes per second maximum) anywhere on screen, provide a reduce-flashing option, and keep camera shake and slow-motion optional and off by default. Aligning with WCAG 2.2 SC 2.3.1 / Technique G19:

Always-On Global UI Rate Limiter (1-3 Flashes Cap): Restrict all pulsing UI elements (enemy-acting indicators, threat warnings, target locks) to a smooth sinusoidal modulation of 0.5-1.5 Hz (0.5-1.5 cycles per second, well under the 1-3 flashes per second ceiling across any 0.8-1.0 second window). When multiple salvos land across 18-22 ships, stagger or clamp UI hit-markers so cumulative screen-space luminance transitions never stack above 1-2 transitions per second.

When Reduce-Flashing Option is Enabled ([Proposal]):

Convert the torpedo Stage 2 700-900 ms ramp to white from a brightness/luminance surge into a spatial progress fill: a constant-luminance matte white bar with a dark border that smoothly wipes outward to fill the indicator gauge over 700-900 ms, with zero end-of-ramp flash.

Replace all blinking/pulsing warning badges and shield/hull hit flashes with steady high-contrast borders and a smooth 400-700 ms directional alpha wipe.

Why it helps readability: Preserves the exact 700-900 ms tactical timing cue of the torpedo ramp and multi-ship salvo feedback while eliminating strobe triggers for photosensitive players.

7. Engine Implementation Notes (Short)

The main shelf above is engine-neutral. Below are short implementation leads for each candidate engine, separating stable capabilities from newer or pre-release versions.

Godot 4.7 Stable (with Distinctions from Godot 4.8 Beta)

Godot 4.7 Stable UI Nodes, Themes, and Viewports:

Screen-Space HUD & Ship Micro-Plates: Place persistent top-bar elements and floating ship status plates inside a CanvasLayer (Godot Docs: Viewport and canvas transforms) using Control (Godot Stable Docs: Control) containers. Use Camera3D.unproject_position (Godot Stable Docs: Camera3D) each frame (or on camera move) to map 3D ship hex positions to 2D screen coordinates so status plates and next-actor badges maintain a crisp, zoom-independent pixel size. If isolating 3D render resolution from crisp 2D UI, wrap the 3D battle scene in a SubViewportContainer (Godot Docs: SubViewportContainer) while rendering UI controls at native monitor resolution.

Centralized Accessibility & Styling: Use a global Theme resource (Godot Docs: Theme) to store StyleBox definitions for the 2-4 px high-contrast focus outlines, font sizes, and faction badge icons.

New in Godot 4.7 Stable (Godot 4.7 Release Notes, Xogot Godot 4.7 Summary):

Offset transforms for Control nodes allow translating, rotating, and scaling UI elements (such as enemy-activation callouts, Threat tip pulses, or order confirmation badges) without breaking the layout managed by parent containers.

DrawableTexture2D enables runtime procedural texture drawing and compositing without low-level rendering code, ideal for updating dynamic hex movement masks, firing-arc overlays, or progressive hull-trauma plate masks.

Conic gradients in 2D rendering directly support radial weapon cooldown sweeps and arc indicators.

Distinction from Godot 4.8 Beta (Pre-Release as of October 2026 - Do Not Confuse with 4.7 Stable):

Godot 4.8 beta 1 (Godot 4.8 Beta 1 Announcement, Godot 4.8 Dev 7 Snapshot, Godot 4.8 Beta Overview) is in pre-release feature freeze for testing, not stable production. Features exclusive to 4.8 beta include: a new default automatic focus strategy algorithm for Control nodes (GH-120631), auto-resizing text in Label and RichTextLabel plus pseudolocalization for layout stress-testing, built-in Theme sound items for UI events (GH-111455), fully animated 3D decals (GH-115653) and native Trail3D, and an experimental runtime CanvasItem manipulation toolbar with undo/redo. Note also that 4.8 beta C# builds require .NET 10 instead of .NET 8 in 4.7.

Babylon.js 9.30 Stable (with Distinctions from Babylon.js 8.20)

Babylon.js 9.30 Stable GUI and Interface Techniques:

Fullscreen 2D HUD & Mesh-Linked Ship Plates: Use @babylonjs/gui (Babylon.js NPM 9.30.0 Packages, Babylon.js Docs: The Babylon GUI) with AdvancedDynamicTexture.CreateFullscreenUI to render the top activation bar, Threat tips, tooltips, and ship status plates (Rectangle, StackPanel, Grid, TextBlock, Image). Attach root-level ship status plates and Line leader tethers to 3D ship meshes via control.linkWithMesh(shipMesh) with linkOffsetX and linkOffsetY so plates track ships in screen space without 3D perspective shrinking, while keeping useInvalidateRectOptimization enabled so only changed UI regions redraw across 18-22 ships. For flat world-space hex markers, AdvancedDynamicTexture.CreateForMesh(plane, width, height, false) disables costly pointer-move raycasts on world meshes.

Screen-Space-Width Hex Grid, Firing Arcs, and Telegraphs: Use CreateGreasedLine (Babylon.js Docs: Creating A GreasedLine) with sizeAttenuation: true, per-segment colors, and widths tables to render camera-facing hex borders, movement perimeters, parallel lance rails, and two-stage torpedo tracks that maintain a constant 2-5 px screen thickness when zoomed out.

Ship Outlines & Keyboard Accessibility: Use HighlightLayer (Babylon.js Docs: HighlightLayer) for hovered/selected ship silhouettes, and @babylonjs/accessibility (Babylon.js NPM 9.30.0 Packages) to generate HTML twin DOM elements for keyboard focus traversal and screen readers.

Specific to Babylon.js 9.30.0 Stable (Babylon.js 9.30.0 Release Notes Summary, Babylon.js What's New Changelog):

WebGPU canvas tone mapping and color space options added in 9.30.0 allow precise calibration between linear RGB 3D scene colours (the six faction weapon/shield/engine palettes) and sRGB 2D GUI elements (cyan shield bars and #62ccff Rare tags).

Includes recent 9.x stability fixes shipped up through 9.30.0, including GUI slider adaptive scaling pointer fixes (#17968), WebGPU selection outline layer fixes (#18080), BoundingBoxRenderer + EffectLayer fixes (#17863), and text shader fixes.

Distinction from Babylon.js 8.20:

In Babylon.js 8.20.0 (Babylon.js What's New Changelog, Babylon.js Overview), features centered on Node Material Editor's DepthSourceBlock (#16936) and sampler2dArray support while Frame Graph and WebGPU UI integrations (#15778) were still maturing in the 8.x cycle. By Babylon.js 9.30.0, the 9.0+ Frame Graph architecture, Clustered and Volumetric Lighting, Inspector v2, WebGPU selection outline fixes, and 9.30.0 WebGPU canvas color-space/tone-mapping controls are stable.

8. Playtest Checks (Worst-Case Readability Checklist)

Run these checks in a worst-case tactical snapshot: 18-22 ships on the board (the leaning density of about 20 ships), camera zoomed out to show the full hex board, a full salvo and active fire/streaming-debris trauma effects playing, and ships spread across all six damage-ladder states. All criteria are observable player outcomes.

Check Area | Test Scenario (Worst-Case Board) | Observable Pass Criterion (Player Outcome & Speed) | Observable Fail Criterion
1. Faction & Allegiance Without Colour | Apply a grayscale/monochrome display filter (or protanopia/deuteranopia/tritanopia filter) at full-board zoom with 18-22 ships. Point at 4-6 random ships without selecting them. | Tester correctly names the faction and friendly/enemy allegiance of each pointed-at ship within 1.0-2.5 seconds per ship using crest icons and frame shapes alone. | Tester takes longer than 2.5-3.5 seconds, clicks the ship to check, or confuses Voidsworn with Corsair, Hegemony with Ithar, or Chorus with Deathless.
2. Shielded vs. Shieldless & Cyan Separation | Include intact Chorus/Deathless ships alongside shield-depleted Hegemony/Ithar ships over the cyan hex grid. | Tester tells which ships naturally have no shields (hull hits only) versus which ships have lost their cyan interface shields within 1.0-2.0 seconds, and reads remaining cyan shield segments against the cyan grid without squinting. | Tester mistakes a Chorus or Deathless ship for a shield-broken vessel, or loses track of cyan interface shield bars over the cyan hex grid.
3. Damage-Ladder Triage at Full Zoom | Mix ships across intact, scorched, dented, exposed structure, hull breach, and wreck while fire and streaming parts are active. Ask tester to call out all ships at exposed structure or hull breach. | Tester spots every ship at exposed structure or hull breach within 2.0-4.0 seconds without selecting ships, and never issues an order or target lock onto a wreck. | Tester misses a breached ship due to particle clutter, needs to zoom in or click ships one by one, or tries to target a wreck.
4. Next-Actor & Threat Tip Trace | Trigger an enemy activation in the top bar and display the round 2 (rounds 2-3 onward) Threat tip while 18-22 ships are on screen. | Tester locates the exact activating/threatening enemy ship on the hex board and states its bow hex facing within 1.0-2.5 seconds. | Tester scans the board for more than 2.5-4.0 seconds hunting for which ship is acting or misreads the ship's bow facing by one or more hex edges.
5. Torpedo Two-Stage & Interception vs. Lance | Overlap two lance aiming corridors and two torpedo tracks (one in Stage 1, one entering Stage 2's 700-900 ms ramp to white with an interception call) across a 4-6 ship cluster. | Tester distinguishes lance rails from torpedo tracks within 0.5-1.5 seconds, identifies the Stage 2 ramp to white before impact, and points to the valid interception hex without prompting. | Tester tries to intercept a lance beam, misses the torpedo interception call, or loses the white ramp against bright shields or hull effects.
6. Order Readiness, Command & Error Prevention | Select a friendly ship with one weapon ready, one out of arc/range, and one on cooldown, with limited Command remaining. | Tester explains why each unavailable weapon cannot fire and states exact remaining Command after a hovered order within 1.0-2.0 seconds, with 0-1 accidental moves or premature turn-ends across a 20-40 minute playtest. | Tester clicks a disabled weapon repeatedly without knowing why it fails, miscalculates Command cost, or accidentally moves into a lance/torpedo zone without noticing the preview.
7. Salvo Clutter & Photosensitive Comfort | Fire a simultaneous multi-ship salvo across a tightly packed 5-8 hex cluster, tested once with standard settings (1-3 flashes per second cap) and once with Reduce-Flashing ON. | Zero ship status plates overlap into unreadable text; tester reads target hull drops within 1.0-2.0 seconds; tester reports comfortable viewing with no harsh strobing in either mode. | Status plates stack over each other, fire/debris obscures hull bars, or simultaneous hits produce rapid brightness spikes exceeding 1-3 flashes per second.

Sources

Godot Engine 4.7 Release Notes - Godot 4.7, Lights, Camera, Action!

Xogot Blog - Xogot Is Moving to Godot 4.7 (Control Offset Transforms, DrawableTexture2D, Conic Gradients)

Godot Engine Official Blog - Dev snapshot: Godot 4.8 beta 1

Godot Engine Official Blog - Dev snapshot: Godot 4.8 dev 7

GodotAwesome - Godot 4.8 Beta: What's New and What Breaks

Godot Engine Documentation (Stable) - Control Class

Godot Engine Documentation (Stable) - Camera3D Class

Godot Engine Documentation - Theme Class

Godot Engine Documentation - SubViewportContainer Class

Godot Engine Documentation - Viewport and Canvas Transforms

GameDev.net - Babylon.js 9.30.0 Released

NPM - Official @babylonjs 9.30.0 Packages (@babylonjs/core, @babylonjs/gui, @babylonjs/accessibility)

Babylon.js Documentation - What's New Changelog (8.20.0 through 9.x)

Babylon.js Documentation - The Babylon GUI (AdvancedDynamicTexture, linkWithMesh)

Babylon.js Documentation - Creating A GreasedLine

Babylon.js Documentation - HighlightLayer Class

WPDean - Babylon.js Architecture and 9.0 Feature Overview

W3C WAI WCAG 2.2 - Understanding SC 1.4.3: Contrast (Minimum)

W3C WAI WCAG 2.2 - Understanding SC 2.3.1: Three Flashes or Below Threshold

W3C WAI WCAG 2.2 - Technique G19: Ensuring that no component of the content flashes more than three times in any 1-second period

W3C WAI WCAG 2.2 - Understanding SC 2.4.7: Focus Visible

W3C WAI WCAG 2.4.11: Focus Not Obscured (Minimum)

W3C WAI WCAG 2.2 - Understanding SC 2.4.13: Focus Appearance

End of Gemini reply.
