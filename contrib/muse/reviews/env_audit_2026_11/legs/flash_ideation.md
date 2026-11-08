CHAIR HEADER (Rey, Nov 6, 2026)
Leg: Gemini Flash IDEATION leg (gemini.google.com, 3.8 Flash; the picker offered 3.5 Flash-Lite, 3.8 Flash, 3.1 Pro, 4 Argon; no 3.6 Flash exists; prompt bar read "Flash" before and after generation; chat https://gemini.google.com/app/d8f0e0697dba4281). This leg exists because Ryan's Google AI Pro subscription lapsed Nov 5, 2026, making the commissioned Argon review leg impossible; Ryan ruled Nov 6, 2026 that Flash runs in the IDEATION seat instead. It is NOT a reviewer leg: it did not screen the writer legs, its claims are leads only and are not evidence, and the chair synthesis treats it accordingly. Filed verbatim below with typographic symbols normalized to ASCII per filing convention.

--- BEGIN FLASH IDEATION LEG (verbatim, symbols normalized) ---

Ideation Report: Environment and Backdrop Stack Red Team

1. Novel Ideas, Options, and Approaches

None of the three writer legs (blind Rey, DeepSeek, Qwen) moved beyond item-by-item parameter sweeping, documentation reconciliations, or simple contact sheet passes. The following architectural, systemic, and pipeline options address the underlying technical and artistic stack without violating standing constraints.

1.1 Structural De-Coupling of Looming Rocks from Planar Framing

The legs treat the looming rock constraint (AS1, AS8, PL8) purely as an angle threshold dial (sweeping 0.05 up to 0.14 rad).

The Off-Axis Loomer Anchor: Allow rocks to subtend larger angles (e.g., 0.15-0.25 rad) strictly outside the central gameplay frustum cone (e.g., beyond 25 degrees off the battle camera's look-at axis) or elevated along positive Y (above the board horizon). This decouples looming silhouette drama from central board readability and preserves the clean stage without an arbitrary global angular clamp across the entire backdrop.

Angular-to-Distance Remapping: Replace the static angular assert BACKDROP_ROCK_ANGLE with depth-banded angular clamps. Near-edge rocks are permitted high angular size with high motion parallax, while rocks near the DIST 3300 band are constrained, restoring perceived three-dimensional volume to the asteroid belt rather than flat shell geometry.

1.2 Deterministic Multi-Pass Sky System

The stack currently forces a false choice between a single static procedural sky bake (BD1, PL12) and volumetric FogVolumes (NB1, NB9) that fight fill-rate.

Dual-Dome Parallax Skybox: Render the sky as two concentric spherical shells: an outer far-bake (starfield BD6, galaxy band BD7, deep nebulae at 4096) and an inner mid-ground shell (wisps BD13, local dust veils) with a slow relative rotational offset driven by camera translation. This provides genuine parallax depth to the sky itself without spawning thousands of particle nodes or FogVolumes.

Palette LUT Inversion for Gas Variety (Solving NB6/BD10): Instead of authoring brand-new procedural noise shaders for non-violet nebulae, retain the existing four-stop procedural intensity bakes and map them through a 1D gradient Look-Up Table (LUT) keyed to the region table (BD10). This unlocks infinite colour families (amber dead-star accretion, cyan ion rifts, emerald toxic belts) across campaigns at zero incremental shader math cost.

1.3 Procedural Asymmetric Kitbash Synthesis for Stations (ST1, ST9)

The legs frame station variety as a zero-sum trade: either polish the existing 2 variants (ST9) or rebuild a 3rd variant from scratch, bound by the additions-only doctrine (ST1).

Graph-Grammar / Seeded Kitbash Assembler: The Blender script (station_kit.py) already contains locked primitives and ship parts. Replace manual variant authoring with a rule-based module graph: a rigid backbone spine with N procedural mounting sockets where functional modules (refinery tanks, drydocks, comm arrays, habitat rings) attach based on seed.

Symmetry-Breaking Silhouette Wings: ST2 and ST6 restrict tall elements and additions. Instead of vertical "spikes" that violate ST6, introduce horizontal outriggers and solar sails that extend across the X/Y board plane. This changes the silhouette drastically at the battle camera (170 units out) without violating dorsal/vertical height boundaries or obstructing ship hexes.

1.4 Unified Virtual Currencies for Spatial Scaling

The stack currently denominates space in three incompatible currencies: board units (AS16, AS17, PL9), hex radii (AS18, NB11), and backdrop steradian/angular radians (AS1, PL1, PL2).

Camera-Screen Projection Contract: Define a single conversion table or function mapping world units at standard battle elevation to normalized screen-height percentage (S_vh). If an element is specified as "reads as 2% screen height," it automatically scales whether it is placed on the board, at mid-depth, or on the backdrop shell, eliminating unit-clash spec bugs (e.g., AS16 vs AS18, AS17).

2. Challenges to Pack Framing and Hypotheses

2.1 Challenge to H1: AS1 is Not the Sole Root of the "Hollow Asteroid" Verdict

The Framing Flaw: Pack H1 and all three legs point to the 0.05 rad cap (AS1) as the primary culprit for R88 ("asteroids look hollow, as if seen from inside").

The Better Angle: The hollow shell feeling is primarily a lighting and normal deficiency, compounded by negative-Y height clumping (AS5), not just maximum angular size.

In AS5, near rocks sit entirely below the far rocks (y -140 to -90 vs -40 to 12). The battle camera looks downward at the board; having near rocks strictly beneath means they are front-lit or rim-lit from the same unvarying top-down sky lamps (BD4).

Without grazing rim lights or local self-shadowing normals, large or small rocks lack volumetric phase function (they don't display crescent phases or self-occlusion). If a 0.14 rad rock is rendered with flat ambient wash, it will not read as a looming mountain - it will read as a larger flat decal sticker. The audit should focus on lighting phase angles and vertical positioning rather than solely relaxing the angular clamp.

2.2 Challenge to H6: Variety is an Asset Distribution Problem, Not Just a Count Gate

The Framing Flaw: H6 argues that 8 planet looks (PL4) and 2 stations (ST9) constrict the game because the raw counts are too low.

The Better Angle: In tactical games, repetition is felt when assets appear in predictable, coupled combinations.

The pack documents rigid couplings: BD4 couples sky lamps directly to the region nebula factor; BD5 couples galaxy counts inversely to nebula cover; PL1 locks planet elevation below the horizon; PL6 enforces a strict 65/35 barren split.

Even with 20 planet looks, if every planet is locked to elevation -0.17 to -0.22 with the same two moons at fixed margin bands, players will perceive sameness. Variety can be dramatically expanded without creating dozens of new models simply by uncoupling composition parameters (randomizing orbital plane inclinations, multi-sun illumination vectors, and distinct atmosphere/cloud rotation deltas).

2.3 Challenge to H7: "Interim" Code (BD15) vs. "Frozen" Asserts (ST3) Are Not Symmetrical

The Framing Flaw: H7 equates BD15 (interim dressing still shipping) and ST3 (frozen asserts) as identical failures of inertia.

The Better Angle: They have fundamentally opposite failure modes in production:

ST3 is active gatekeeping: it aggressively halts builds and prevents exploration.

BD15 is passive scaffolding: it works reliably, produces functional scenes, and scales dynamically with board size (R0 = board bounds * 0.62 + 40).

Trying to discard BD15 in favor of complex authored placement runs counter to the project's agentic model. Instead of replacing BD15 with static assets, the dynamic board-scaling formula of BD15 should be embraced, cleaned of hardcoded magic constants, and parameterized as the engine's standard responsive backdrop system.

3. High-Information, Low-Cost Settlement Ideas

(Priced strictly in agent terms: one-time script builds, per-run costs, and owner review rounds. Never human time.)

Settlement Action | Scope / Items Settled | Agent Build Cost | Owner Review Cost
1. The "Panoptic Matrix" Contact Sheet Generator | BD10, PL4, PL6, PL7, NB4, NB6, AS2, BD4 | 1 script build (one-time) | 1 review round (high information)
2. Headless Asset & Timing Batch Audit Script | ST4, ST5, PL10, PL12, AS11, BD1, BD2, BD18 | 1 script build (one-time) | 0 review rounds (pure data)
3. Single-Pass Lexicon & Range Reconciliation Merge | AS14, AS16, AS18, BD8, BD16, NB11, ST3, ST10 | 1 Opus run (one-time) | 0 review rounds (pure code/doc)
4. Multi-Variant Frustum Capture Turntable Run | AS1, AS5, AS8, PL1, PL2, PL8, ST2 | 1 Codex run (one-time) | 1 review round (visual decision)

3.1 The "Panoptic Matrix" Contact Sheet Generator

The Idea: Instead of executing individual sheet runs for planets (PL4), regions (BD10), asteroid densities (AS2), and nebula colours (NB4, NB6), write a single headless Godot test script that cycles through the 6 regions along the Y-axis and 3 lighting/camera yaw states along the X-axis, capturing composite thumbnail matrices.

Information Yield: Directly settles BD10 (regions), PL4 (look variety), PL6 (moon distributions), PL7 (rings), NB4/NB6 (colour stops and families), BD4 (lamp counts), and AS2 (counts) on a single high-density contact sheet.

Cost:

One-time: 1 script build (Godot viewport rasterizer).

Recurring: 1 unattended run per generation.

Owner cost: 1 review round to evaluate the entire macro-aesthetic of the game.

3.2 Headless Asset & Timing Batch Audit Script

The Idea: Execute a non-graphical engine profiling pass across the test fixtures and main scenes to capture raw metrics without human or subjective review.

Information Yield:

Automatically counts current station triangles and draw calls (settles ST4).

Asserts whether the station triangle ceiling check is active and comments it out if violated (settles ST5).

Analyzes close-zoom curvature deviation on the 96x48 sphere mesh (settles PL10).

Executes cold bakes across 10 randomized seeds to output min/max/mean bake times (settles PL12 against E23).

Compares shader bytecode instruction counts between 26, 40, and 64 steps (settles BD2).

Cost:

One-time: 1 script build (tools/audit/audit_environment_metrics.py or .gd).

Recurring: None.

Owner cost: 0 review rounds (deterministic data output).

3.3 Single-Pass Lexicon & Range Reconciliation Merge

The Idea: Five separate items in the inventory represent text/code desynchronizations between adopted syntheses and shipped constants: AS14 (tumble rates), AS16 vs AS18 (wreck size vs hex cap), BD8 vs E18 (star dimming), BD16 (zone tints), and NB11 (units vs hexes). The legs proposed multiple isolated Opus runs. Instead, bundle all spec contradictions, assert removals (ST3, ST5), and doc cleanups (ST10) into a single unified Opus patch.

Information Yield: Completely cleans the backlog of "dead-letter" specifications and aligns code constants with FINDINGS in a single commit.

Cost:

One-time: 1 Opus run.

Recurring: None.

Owner cost: 0 review rounds (procedural alignment to existing owner FINDINGS).

3.4 Multi-Variant Frustum Capture Turntable Run

The Idea: Address all spatial scale and framing questions simultaneously by rendering a single battle scene with a turntable camera sweep across 3 discrete parameter profiles:

Profile A (Current Strict): AS1 at 0.05 rad, PL8 at 4.4x, PL1 current elevation, ST2 at 2 units.

Profile B (Relaxed Depth): AS1 at 0.10 rad, PL8 at 2.5x, PL1 elevated +0.1 rad, ST2 at 4 units.

Profile C (Uncapped Monumental): AS1 at 0.16 rad, PL8 at 1.5x, PL1 horizon-straddling, ST2 at 6 units.

Information Yield: Decides the scale hierarchy of the entire game (AS1, AS8, PL1, PL2, PL8, ST2) in motion, revealing whether larger rocks cause clutter or deliver true monumentality.

Cost:

One-time: 1 Codex run.

Recurring: None.

Owner cost: 1 review round.

4. Speculative Risk Assessment

(Labeled as speculation pursuant to audit instructions)

[SPECULATION] The True Root of "Hollow Asteroids": It is speculated that the hollow look noted in playtest R88 is an optical illusion caused by Godot 4's directional shadow mapping distance cutoffs. If backdrop asteroids fall outside the cascade shadow map split distance, they receive zero directional shadows and are lit entirely by ambient radiance (BD3) and sky lamps (BD4). Without shadow terminators, a rocky body appears concave or translucent regardless of its angular size.

[SPECULATION] FogVolume Fill-Rate Cliff at 4K: It is speculated that issue 139's volumetric fog approach will trigger severe GPU fill-rate throttling on cards below the RTX 5080 if camera-intersecting gas puffs (y 0 to 3, NB1) are rendered using Godot's built-in FogVolume nodes rather than custom raymarched depth-aware impostors.

[SPECULATION] Station Kitbash Aesthetic Barrier: It is speculated that no amount of surface detail (issue 199) or proud gantry additions (ST2) will satisfy the owner's demand for high quality (R109) so long as the underlying silhouettes rely on primitive primitives (cylinders, boxes) without angled chamfers, beveled silhouette silhouettes, and inset docking cavities.

--- END FLASH IDEATION LEG ---
