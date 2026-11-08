CHAIR HEADER (Rey): Gemini Flash ideation leg for the UI and campaign map audit. Run Nov 6, 2026, 16:39 to 16:41 CST. Model: Flash (prompt bar read "Flash" before and after generation; the account's Google AI Pro lapsed Nov 5, 2026, so Argon could not be selected). This leg ran in the IDEATION seat under the owner's Nov 6, 2026 ruling: ideas and challenges only, never reviewer or screening. Everything below is an unverified lead, not evidence. Single generation, no retry. Chat: https://gemini.google.com/app/10f724ab42dce0ff. PACK.md attachment confirmed present before sending. Filed verbatim.

---

Flash Ideation Leg: UI, Menu, and Campaign Map Gates

All claims, mechanisms, and critiques below are SPECULATION generated as unverified leads and alternative framings, per the Flash ideation leg instruction.

1. Ideas

Speculative idea 1: Screen-space bounding-box proxy scaling for nameplates (HD7, HD8, X3).
Replace the fixed-pixel bar scaling law entirely by anchoring plate screen bounds to the projected 3D ship bounding sphere clamped between min/max readable margins.
What it changes: Resolves the plate-to-ship proportion inversion across zoom levels dynamically without needing bespoke per-zoom breakpoint tables.
Cost: 1 Codex run to implement projection clamping logic, 1 owner review round.

Speculative idea 2: Semantic color tokens decoupled from faction identity (IC7, IC8, MP3, MP11, H6).
Introduce a four-role functional token tier (Threat, Opportunity, Patron, Telemetry) layered over faction glow variables, where faction themes only tint UI trim and never core gameplay state vectors.
What it changes: Eliminates accidental one-off hex values by making it mechanically impossible for enemy lavender, nemesis red, or ally green to collide with faction identity palettes.
Cost: 1 Opus run to design token hierarchy, 1 Codex run to refactor styles.

Speculative idea 3: Procedural danger-band auto-calibration from combat sim logs (MP8).
Instead of human-curated band cut points (0.8, 1.05, 1.4), bind band definitions to empirical win-rate quartiles harvested directly from unattended headless bot runs.
What it changes: Turns danger estimation into an exact reflection of actual fleet survival probabilities rather than an assumed budget ratio.
Cost: 1 one-time script build to parse sim logs into JSON thresholds, 0 owner review rounds.

Speculative idea 4: Contextual radial pie/reticle HUD anchored to selection rather than pinned screen docks (HD4, HD5).
Collapse the 316 px/340 px fixed side panel into an on-board radial ring around the active target, reserving screen borders strictly for fleet roster state.
What it changes: Drastically reduces eye travel across 4K displays and eliminates horizontal width crowding on wide aspect ratios.
Cost: 2 Codex runs, 1 owner review round.

Speculative idea 5: Audio-first and haptic redundant cues for target lock and critical low-hull (AC1, HD9, IC5).
Address colorblindness and visual overload by tying low hull and targeted tags to distinct audio tones and subtle controller rumble triggers rather than visual tags alone.
What it changes: Gives immediate multi-channel tactical feedback without adding clutter to crowded nameplates.
Cost: 1 Codex run, 1 owner review round.

Speculative idea 6: Interactive tactical pause ledger acting as combat debrief and control card (MN8, TY7, HD6).
Merge combat log history, keyboard help, and post-battle stats into a single unified full-screen modal accessible both during tactical pause and post-match.
What it changes: Solves the missing debrief screen, uncapped log growth, and dense 30-input help text block in one integrated layout.
Cost: 1 Opus run for screen architecture, 1 Codex run for implementation, 1 owner review round.

Speculative idea 7: Orrery node projection with automatic camera planar bill-boarding (MP6, IC1).
Keep the 3D orrery geometry but render encounter markers and node paths as screen-space bill-boarded HUD decals projected on top of the 3D plane rather than in-world unlit meshes.
What it changes: Retains the cinematic visual depth of the 3D map while completely restoring the crisp legibility and iconography of the 2D SVG map.
Cost: 1 Codex run, 1 owner review round.

2. Challenges

Speculative challenge to domain separation of HD, MN, and TY (HD1, HD2, MN1, TY3, TY4):
The pack treats HUD scaling, menu sizing, and typography scaling as separate domain questions, leading to fragmented audit entries. In reality, these are all symptoms of a single missing unified design token and layout engine. Auditing them as independent gates causes redundant capture runs when a single root layout rule governs them all.

Speculative challenge to H1 (Transcription drift hypothesis, PACK section 10):
The chair frames the differences between the JS and Godot builds (e.g., nameplate 54 px vs 90 px, panel 340 px vs 316 px) as accidental transcription errors by eye. An alternative speculation is that Godot UI nodes were adapted for different physical viewing distances or controller targets. Treating every divergence as an accidental bug that must be diffed back to the web baseline risks reverting deliberate ergonomics adjustments made during engine migration.

Speculative challenge to H2 and the 1080p height law framing (HD1, TY4, TY5, H2):
The pack treats height-denominated scaling as an inherent disease comparable to an arbitrary performance cap. However, vertical viewport reference sizing is the standard industry practice in AAA engine UI (such as Unreal Canvas and Godot root viewport scaling) because horizontal aspect ratios vary wildly (16:9, 16:10, 21:9, 32:9) while vertical FOV remains relatively constant. The real failure is not height-scaling itself, but the arbitrary clamp bounds (0.6, 2.2) and the absence of a player-facing scale offset multiplier (AC2).

Speculative challenge to H3 (3D map scene vs SVG visual language, MP1-MP6):
The pack frames the transition from 2D SVG to 3D map as a loss of visual language requiring re-specification. The challenge: attempting to replicate 2D diagrammatic iconography inside a lit 3D perspective space is an anti-pattern. A 3D orrery communicates spatial hierarchy, depth, and physical journey; forcing 2D flat-badge semantics onto it will make the 3D map look like a cluttered CAD overlay rather than a diegetic bridge display.

Speculative challenge to AC classification and provenance (AC1 to AC7, Section 1.2):
Classifying missing features (such as absent UI scaling or absent colorblind modes) as ASSUMED numeric design gates stretches the audit taxonomy. An omission is a scope backlog gap, not a tuned numeric constraint. Lumping absent features in with misconfigured engine constants obscures actionable engineering debt behind red-team terminology.

Speculative challenge to H7 (Text density and word budgeting, TY7, TY8, MN8):
The chair proposes a structured text budget specification. Speculatively, the issue in combat controls (TY7) and teaching cards (TY8) is not total word volume, but information architecture. A dense control block requires contextual input rebinding and on-demand input prompts (action-to-key glyph tags on the HUD itself), not an edited or word-budgeted paragraph.

3. Cheaper Settlements

Item HD7, HD8 (Nameplate geometry and shield bars):
Pack settlement: Multi-resolution capture rounds during the camera calibration sitting plus owner review rounds.
Cost: Riding calibration sitting (issue 212) + 1 owner review round.
Speculative cheaper/higher-information alternative: A one-time interactive debug slider harness rendered inside the running build where the owner adjusts plate width, pip count, and font live in-game at 1440p and 4K, dumping the chosen parameters directly to a JSON config.
Cost: 1 Codex run to build the runtime debug slider, 1 owner review round (replaces static capture rounds with live feel calibration).

Item MP8 (Danger bands):
Pack settlement: Monte Carlo simulation runs against existing bot harness, one-time script build, then manual rule setting.
Cost: 1 one-time script build.
Speculative higher-information alternative: Keep the one-time script build, but let the script directly fit logistic regression cutoffs onto raw fleet battle outcome logs, outputting calibrated band brackets automatically without requiring downstream human re-ruling.
Cost: 1 one-time script build, 0 owner review rounds.

Item AC1 (Color-vision support and palette collisions):
Pack settlement: A post-capture CVD simulation pass using an image-filtering script over static screenshot captures, followed by owner review of failing assets.
Cost: 1 one-time script build, 1 owner review round.
Speculative cheaper/higher-information alternative: Implement a full-screen shader toggle directly in Godot running Daltonization/CVD matrix transforms across the active viewport. This tests both 3D world readability and 2D UI elements simultaneously across live play instead of static frames.
Cost: 1 Codex run, 0 owner review rounds (replaces external asset scraping with engine-level validation).

Item HD6 (Uncapped battle log DOM/RichText):
Pack settlement: Long-battle soak capture run plus line counting via Codex.
Cost: 1 Codex run.
Speculative cheaper alternative: Enforce a circular ring buffer of 200 items in code directly via a 5-line diff in hud.gd, mirroring the JS build constraint without conducting a soak capture test.
Cost: 1 Codex run (direct code patch without running a soak capture).

Item H1 Diff & Palette Consolidation (H1, H6, MP3, IC8, HD9):
Pack settlement: An Opus run to draft a consolidated UI spec, an owner question, plus multiple per-screen capture reviews.
Cost: 1 Opus run, 1 owner review round, plus capture review passes.
Speculative cheaper alternative: Run a static AST analysis script over both repositories (head.html, ui3d.js, hud.gd, campaign_ui.gd) that extracts all hardcoded hex values and numeric layout literals into a single Markdown table. The owner conducts one single-pass review checking keep/drop boxes.
Cost: 1 one-time script build, 1 owner review round.

4. Not Checked

All entries below are unverified and were not inspected for this report:

The actual Godot scene trees (battle.tscn, campaign.tscn, main.tscn, title.tscn) and any layout overrides, container anchors, or margins defined inside them rather than in GDScript.

The contents and logic of godot/scenes/battle/battle.gd (4,707 lines), including combat event emission rates, floating text handling, and whether battle log array pruning is handled at the data layer.

The campaign scene router godot/main/campaign_host.gd and the exact trigger conditions determining when campaign_fallback_ui.gd is displayed instead of map3d.gd.

The per-faction map lookups and hex values inside godot/ui/campaign/map3d_system.gd (LOOKS dictionary).

The procedural map generator implementation in the JS build (campaign_run.js / campaign_meta.js) and how its node positioning compares to Godot's 3D orrery math.

Patron color definitions and reward data tables in data.js or external JSON assets.

Real-world rendering performance and GPU draw-call spikes caused by Godot Control node canvas item redraws or theme stylebox allocation.

The CSS transitions, CSS transforms, and CSS animation performance in head.html and voidsworn-3d.html on low-end hardware.

The state classes governing nameplate visibility and opacity fade transitions in ui3d.js.

Any existing rulings or precedent in FINDINGS.md and LOOP.md that may already constrain UI design decisions.

How Godot handles high-DPI scaling across different operating system display scaling settings (e.g., Windows 125%, 150%, 200% display scaling at 4K).

Controller navigation behavior, UI sound hookups, and focus grab routines outside of title.gd.
