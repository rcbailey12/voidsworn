CHAIR HEADER (Rey, Nov 6, 2026)
Leg: Gemini Flash IDEATION leg (gemini.google.com, 3.8 Flash; the picker offered 3.5 Flash-Lite, 3.8 Flash, 3.1 Pro, 4 Argon; no 3.6 Flash exists; prompt bar read "Flash" before and after generation; chat https://gemini.google.com/app/1ad9553a6d19586a). This leg exists because Ryan's Google AI Pro subscription lapsed Nov 5, 2026, making the commissioned Argon review leg impossible; Ryan ruled Nov 6, 2026 that Flash runs in the IDEATION seat instead. It is NOT a reviewer leg: it did not screen the writer legs, its claims are leads only and are not evidence, and the chair synthesis treats it accordingly. Filed verbatim below with typographic symbols normalized to ASCII per filing convention.

--- BEGIN FLASH IDEATION LEG (verbatim, symbols normalized) ---

Ideation Report: Destruction, Physics Feel, and Camera Gates

Context: Analysis of PACK.md and the three writer legs (rey_blind.md, deepseek.md, qwen.md). This report provides unvoiced technical options, challenges to underlying framing, and settlement methods priced strictly in agent terms.

1. Unvoiced Ideas, Options, and Approaches

The three writer legs converged heavily on a standard playbook: run probes, capture side-by-side video, let the owner rule on constants, or delete dead code. The following technical and architectural options were bypassed by all three legs:

DS4 / DS6: Body Sleeping and Kinematic Handoff Architecture (Physics Step Decoupling)

Option: Instead of debating whether 360 rigid bodies overtax Jolt or dropping the body count, implement an explicit lifecycle state machine:

Spawn as active RigidBody3D with linear damp 0.2 and angular damp 0.4.

Once linear velocity drops below 0.2 u/s and angular velocity drops below 0.1 rad/s (or after a fixed 3.0 s envelope), freeze the body (freeze = true, switching to kinematic/static sleep).

For loose cosmetic shards, reparent them from Jolt bodies to a single multi-mesh instance (MultiMeshInstance3D) on sleep.

Why it matters: This eliminates the quadratic collision pair checks flagged by Qwen without sacrificing R88's momentum-keeping debris. Active collision cost drops to zero within seconds of a death event.

DS7 / DS8: Hull Break Inversion Fix via Pure Visual Kinematics (No Physics Solver Overhead)

Option: Capital ship chunks do not need Jolt rigid body simulation to avoid looking like statues. Replace Jolt rigid body instantiation for capitals with deterministic, keyframed visual drift (authored separation vectors along the transverse cut normal, decaying over time via tweening or an animation curve).

Why it matters: Capitals have huge bounding boxes; putting them into Jolt risks broadphase overlap hiccups and massive collision bounds with small debris. Authoring separation as a purely transform-based visual drift guarantees deliberate staging, prevents freezing, and costs 0.0 ms in Jolt narrowphase.

DS1 / DS2: The Visual "Ghost Wreck" Shader Handoff

Option: Decouple the mesh from the blocking hex without popping. When a wreck is evicted from the active 24-wreck visual budget (DS1) while its hex remains a blocking hulk (DS2), do not call free() on the visual node immediately. Instead, bake or swap it into a low-cost, unlit, cold-hull silhouette shader (or an impostor / decimation lod) that shares a single draw call batch across all old hulks.

Why it matters: Solves the "invisible wall" complaint while respecting Godot node/draw limits.

PF1 / PF7 / PF10: The Single Normalized "Tonnage / Impulse Bus" (Unifying Mass)

Option: Unify the three disjointed mass definitions (PACK H5: REACT_MASS up to 12.0, triangle count / 400, and ship_view 0-to-1 mass) into a single property on the ship definition: tonnage_class (or mass in standard engine units). Derive camera trauma, hit shove, kinematic move settle, and bystander shockwave displacement from this single scalar using power curves (M^0.5 or log M).

Why it matters: Eliminates manual retuning of four separate tables every time a ship's visual weight feels off.

PF7 / DS10: Directional Shockwave / Hull Wash VFX without Hex Mutation

Option: Treat capital death impulse on bystanders purely as an angular torque and particle wash rather than a linear translation. Live ships caught within 2 hexes of an exploding capital play an involuntary attitude shudder (rolling away along the explosion vector by 2-5 degrees and recovering via PF2's critically damped spring) without moving off their hex center.

Why it matters: Completely sidesteps rules-layer hex occupancy collisions (PF8) while delivering the physical causal force missing from R88.

CM4 / CM9: Dynamic Asymmetric Frustum Offsetting (Tactical UI Compensation)

Option: Rather than hardcoding fixed margins (sees() margin 0.22) or clipping behind HUD panels, implement camera frustum sensor offsetting (Camera3D.set_frustum_offset).

Why it matters: When side panels or bottom fleet bars expand, shift the optical center of the projection matrix instead of physically panning the camera target. The hex board remains centered in the visible aperture without camera drift.

CM1 / CM13: Resolution-Independent Framing Denominator (Vertical FOV-Span Units)

Option: Replace fixed world-distance radius (170) with a target Hex-Span Metric: define camera home as "18 hex diameters across the vertical viewport." Compute camera distance D dynamically from the vertical FOV:

D = Target Visible World Height / (2 * tan(FOV/2))

Why it matters: Decouples readability standards permanently from arbitrary camera heights, screen resolutions, or FOV tweaks.

2. Challenges to the Pack's Framing and Hypotheses

Challenge to H1 (The 170-unit radius as a "Stage 5 / 306k" Anchor):

Counter-angle: The pack frames the 170-unit distance as an unexamined ported accident that corrupts readability standards downstream. This misdiagnoses the true culprit. The issue is not that 170 units is arbitrary; it is that pixel-per-unit standards were hardcoded against a perspective camera without locking FOV and screen resolution. In perspective projection, world units per pixel change continuously from screen center to screen edge. The flaw was attempting to enforce texture and mesh detail standards using 2D screen-pixel density on a perspective 3D camera. Treating 170 as an anchor to re-measure still leaves the fundamental mathematical flaw in place.

Challenge to H3 & DS7 (The Capital Freeze as an "Accidental Inversion"):

Counter-angle: The pack and writer legs treat the capital freeze (death_big and not organic => freeze = true) as a bizarre oversight or mistake that inverts the spectacle. It was almost certainly an intentional safeguard against catastrophic physics penetration jitter. When two massive capital chunks with complex convex or trimesh colliders separate at slow speeds (0.7 u/s), Jolt's contact solver will violently repel or interpenetrate them if inertia tensors are large. Unfreezing them without changing the separation algorithm will likely produce chaotic rubber-banding or piece clipping, not majestic cinematic drift.

Challenge to H4 & DS1/DS2 (Rules vs. Visual Wrecks as an Unintended Bug):

Counter-angle: The pack treats the divergence between permanent rules hulks (DS2) and the visual 24-wreck cap (DS1) as an accidental bug that causes invisible walls. In turn-based tactical games, board readability requires that dead hulls eventually stop drawing the eye as active targets. The problem is not that visual wrecks vanish; it is that the rules layer made hulks permanent blocking terrain forever. In a fleet engagement, 20 blocking obstacles choke the tactical grid. The correct fix is adding a rules-layer breakdown mechanic (e.g., hulks degrade to passable scrap debris after 2 turns), rather than forcing the visual engine to render an ever-growing graveyard of 50 dead ships.

Challenge to H6 (R88 "Sudden and Jerky" as a Physics/Impulse Deficit):

Counter-angle: The pack hypothesizes that deaths feel sudden and jerky because nearby ships don't move (PF7) and main pieces drift at only 0.7 u/s (DS8). This overlooks temporal interpolation and frame pacing. Godot 4's default physics step runs at 60 Hz fixed, while rendering may run at 120+ Hz or uncapped on an RTX 5080. If rigid body transforms lack physics interpolation (physics_jitter_fix or Godot 4.3+ 3D physics interpolation), physics-driven debris will stutter and hitch against smoothly rendering particles. The jerkiness is almost certainly transform sampling jitter, not an impulse tuning issue.

3. High-Information, Lower-Cost Settlement Ideas (Agent Terms Only)

The writer legs leaned heavily on multi-stage video captures and human review rounds. The settlement workflows below maximize automated information yield, minimize review fatigue, and are priced strictly in agent terms.

Settlement Action | Workflow & Instrumentation | Total Cost
1. The Headless "Physics Cliff" Automated Sweep (DS4, DS6, DS15) | One-time script extending test probe: spawns 1 to 500 debris bodies at 4K headless; dumps step ms, contact count, and narrowphase time to CSV. Replaces visual speculation with hard curves. | One-time: 1 Codex run. Recurring: 0 rounds (pure data dump).
2. The Deterministic Monte Carlo Damage Matrix Sim (PF4, PF5, PF6) | Headless Python/JS batch script: runs 50,000 ram combinations across all ship classes, armor ratings, and angles. Emits heatmaps of one-shot probability and recoil mortality. | One-time: 1 Codex run. Recurring: 1 Opus run for parameter bounds. Review: 0 owner rounds.
3. The 9-Way "Single Contact Sheet" Video Capture (DS7, DS8, PF1, PF2, PF7) | One scripted test scene with 9 viewport splits (1 video file, 15 seconds): columns = classes (Frigate, Cruiser, Capital); rows = reactions & unfreezes. | One-time: 1 Codex run. Review: Exactly 1 owner review round (replaces 5 separate rounds).
4. Interactive "Goldilocks" Camera Slider Session (CM1, CM2, CM3, CM4) | Small debug UI overlay in test harness: owner drags camera radius/FOV in real time; on exit, rig prints exact (r, fov, polar) JSON values to console log. | One-time: 1 Codex run. Review: 1 owner play session (replaces all Opus re-derivations).
5. Automated AST Static Check & Code-Ghost Exorcism (PF9, PF10, PF12) | 20-line regex/AST script: sweeps repo for WELL_, gravity, and tidal, emits diff removing dead hooks from fx.gd, fx_death.gd, and rules. | One-time: 1 Opus run. Review: 0 owner rounds.

Detailed Breakdown of High-Efficiency Settlements

The Headless Physics Cliff Sweep (DS4, DS6, DS15)

Approach: Do not ask the owner to evaluate performance visually. Extend destruction_fleet_probe via a single Codex run to run a 60-second headless stress test simulating 5 simultaneous fleet deaths. Increment body counts from 50 to 500 in steps of 50, with damp at 0.0 vs 0.3. Output a markdown table plotting Jolt physics step time in ms.

Cost: One-time: 1 Codex run. Zero owner rounds. Yields the exact ceiling where physics step exceeds 4.0 ms.

The Deterministic Monte Carlo Ramming Heatmap (PF4, PF5, PF6)

Approach: Avoid qualitative reviews of whether rams "feel right." Build a headless simulator that executes all possible fleet ram combinations across hull sizes, shield facings, and faction modifiers. Output a markdown matrix showing: (a) % of encounters where ramming results in target kill, (b) % of encounters where rammer destroys itself via recoil, (c) distribution of surviving target hull %.

Cost: One-time: 1 Codex run to construct and execute the sim; 1 Opus run to analyze results and tune constants to match the design spec ("finisher, not opener"). Zero owner rounds.

The Consolidated 9-Way Contact Sheet Matrix (DS7, DS8, PF1, PF2, PF7)

Approach: The writer legs proposed separate review rounds for hit reactions, capital freeze, separation speeds, and bystander impulse. Consolidate this into a single 3x3 grid video capture rendered in one pass:

Columns: Small, Medium, Capital hull.

Rows: Baseline shipped behavior, Unfrozen + bystander shockwave, Alternative timing/damp.

Cost: One-time: 1 Codex run to script the camera grid; 1 owner review round to approve the surviving row. Eliminates at least four owner review cycles.

Interactive "Goldilocks" Camera Calibration Harness (CM1, CM2, CM3, CM4)

Approach: Instead of generating multiple videos at arbitrary camera radii (170 vs 220 vs 260) and having the owner guess, build a simple runtime debug hook into the Godot camera rig that exposes mouse-wheel zoom, FOV slider, and polar angle readout. The owner runs the build once, frames the battle to their aesthetic preference, and hits Spacebar to dump the exact transform and projection parameters to user://camera_preference.json.

Cost: One-time: 1 Codex run. 1 owner calibration session. Standards are re-denominated directly from the logged JSON.

Speculation Notice

Statements regarding Godot 4 Jolt contact solver behavior with large bounding boxes, performance cliff thresholds under broadphase pair checks, and transform jitter resulting from physics tick interpolation are technical inferences based on engine architecture and are labeled as speculation pending probe execution.

--- END FLASH IDEATION LEG ---
