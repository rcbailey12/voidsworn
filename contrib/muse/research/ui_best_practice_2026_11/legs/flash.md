# #292 search leg: Flash (Gemini 3.8 Flash, ideation/research seat)

Run Nov 8, 2026, 21:36-21:40 CST (browser-measured). Model gate verified by the runner before and after: picker showed "Selected 3.8 Flash" checked, prompt bar read "Flash", both times. Chat: https://gemini.google.com/app/de51028923eeb291

Chair note on coverage: 17 games (6 tactics, 6 strategy/fleet, 5 roguelikes). Stellaris and Sins of a Solar Empire 2, both named by Ryan in R142, are NOT covered by this leg; the chair must make sure the pool covers them (Grok leg pending; otherwise a chair supplement). Leg text below is verbatim, including its em dashes; the delivery copy will be scrubbed of em dashes per repo CI.

---

Shipped Game Case Studies
Genre 1: Turn-Based Tactics

Into the Breach

What it does best for the next action: It completely eliminates RNG through deterministic telegraphing: enemy intent, movement paths, attack targets, and exact resulting damage (including environmental splash and collision damage) are visually pinned directly to the grid before the player commits an action. The end-turn safety is fortified by explicit "Undo Move" support and a persistent turn-reset button.

Criticisms / Shortcomings: The absolute reliance on minimalist overhead pixel clarity breaks down when cascading displacement attacks interact with complex hazards simultaneously, requiring meticulous step-by-step mental simulation without a native multi-step action forecast.

References: Subset Games Design Breakdown / Steam Store Page: https://store.steampowered.com/app/590380/Into_the_Breach/

BattleTech (Harebrained Schemes)

What it does best for the next action: Movement and positioning directly project tactical math: moving along the nav-line dynamically calculates facing cones, sight lines, direct vs. indirect ballistic fire, and evasion pip generation. Targeting automatically breaks out weapon clusters, hit odds per hardpoint, heat generation delta, and heat threshold warnings before firing.

Criticisms / Shortcomings: Information density causes cognitive drag; managing targeted component caller shots and reading critical hit damage across paper-doll vehicle armor requires parsing oversized modal target overlays that cover critical parts of the tactical board.

References: Paradox Interactive / Steam Store Page: https://store.steampowered.com/app/637090/BATTLETECH/

Warhammer 40,000: Rogue Trader (Voidship Battles)

What it does best for the next action: Provides strict quadrant-based spatial management: ship maneuvering paths are rendered with rigid turning radii, hull facing shields (fore, aft, port, starboard), and weapon firing arcs highlighted directly on the spatial plane. Ability bars cleanly split standard ship propulsion from specialized officer post abilities and battery salvos.

Criticisms / Shortcomings: Players widely criticize the void combat camera tracking and obtuse line-of-sight/firing-arc readability around colossal vessel collision envelopes and spatial debris.

References: Owlcat Games / Steam Store Page: https://store.steampowered.com/app/2186680/Warhammer_40000_Rogue_Trader/

XCOM 2

What it does best for the next action: The "Target Preview" crosshair system on the unit movement grid shows exactly which enemies will enter line-of-sight and weapon range at the cursor's destination before committing a move. The weapon HUD gives a clear breakdown modal of base aim, cover deductions, elevation bonuses, and crit odds.

Criticisms / Shortcomings: Line-of-sight calculations occasionally suffer from visual misalignments with actual tile geometry, leading to perceived "shot through solid walls" frustations and unpredictable activation of enemy pods.

References: 2K Games / Steam Store Page: https://store.steampowered.com/app/268500/XCOM_2/

Gears Tactics

What it does best for the next action: Its action-point path preview subdivides the movement trajectory line into remaining AP segments, visually displaying precise overwatch cones, hit chances, and skill-use radii along the path prior to execution.

Criticisms / Shortcomings: Cluttered visual telegraphing when multiple overlapping overwatch cones intersect, making it difficult to decipher the specific firing threshold of individual hostiles.

References: Xbox Game Studios / Steam Store Page: https://store.steampowered.com/app/1184050/Gears_Tactics/

Phoenix Point

What it does best for the next action: Manual free-aiming reticle displays internal and external targeting circles, communicating that 50% of shots land within the inner ring and 100% within the outer ring, which instantly clarifies anatomical body-part damage potential without relying on single-roll abstraction.

Criticisms / Shortcomings: Line-of-sight raycasts from barrel geometry can cause weapons to unexpectedly collide with low terrain obstacles despite the reticle indicating a clean path.

References: Snapshot Games / Steam Store Page: https://store.steampowered.com/app/839770/Phoenix_Point/

Genre 2: Strategy and Fleet

Battlefleet Gothic: Armada 2

What it does best for the next action: Quadrant shields and directional hull armor are rendered directly onto the ship's tactical water-line ring. Firing arcs (prow, broadside, turret 360°) and stance management (e.g., Reload, Brace for Impact, Lock On) are toggled through high-contrast radial/tray matrices pinned to ship selection.

Criticisms / Shortcomings: Roster management at fleet scale suffers during high-speed engagements; tracking weapon cooldowns, boarding statuses, and subsystem casualties across dozens of capital ships induces severe informational overload.

References: Focus Home Interactive / Steam Store Page: https://store.steampowered.com/app/573100/Battlefleet_Gothic_Armada_2/

Nebulous: Fleet Command

What it does best for the next action: Radar cross-section, electronic warfare (EW) noise floors, and active target locks are cleanly integrated into directional vector ribbons. Point-defense envelopes, munition trajectories, and discrete module damage statuses (mounts, drives, DC tracks) are shown with engineering-grade data fidelity.

Criticisms / Shortcomings: A punishingly steep UI learning curve; reading nested tactical menus and orientation 3D widgets requires extensive manual parsing and camera manipulation.

References: Hooded Horse / Steam Store Page: https://store.steampowered.com/app/887570/NEBULOUS_Fleet_Command/

Battlestar Galactica Deadlock

What it does best for the next action: WEGO simultaneous execution interface features a timeline posture scrubber, distinct directional posture settings (offensive, balanced, defensive), and directional posture planning projections that depict projected collision and firing paths prior to ending the turn.

Criticisms / Shortcomings: Vertical axis planning and trajectory line clutter can make large fleet coordination difficult to visually untangle in tight formation battles.

References: Slitherine Software / Steam Store Page: https://store.steampowered.com/app/544610/Battlestar_Galactica_Deadlock/

Endless Space 2

What it does best for the next action: Employs the "SCAN" tactical overlay mode (holding Spacebar) which wipes away decorative graphics to display clean, abstract data layers: fleet compositions, health pips, range profiles (long, medium, short), and targeted lane trajectory assignments.

Criticisms / Shortcomings: Heavy reliance on abstract symbolic iconography often forces players to dig through multiple nested tooltips to find the exact numerical damage values of modular weapon loadouts.

References: Amplitude Studios / Steam Store Page: https://store.steampowered.com/app/392110/Endless_Space_2/

Homeworld Remastered / Homeworld 3

What it does best for the next action: The tactical Sensors Array mode scales seamlessly from macro fleet command down to individual strike craft formations, utilizing standardized tactical silhouettes and clear geometric movement disc projections.

Criticisms / Shortcomings: Tactical sub-targeting (e.g., sniping engines or weapon hardpoints) is cumbersome on modern high-resolution screens due to finicky sub-module selection hitboxes.

References: Gearbox Publishing / Steam Store Page: https://store.steampowered.com/app/244160/Homeworld_Remastered_Collection/

Starsector

What it does best for the next action: Tactical map fleet command utilizes standardized fleet doctrine orders, explicit fleet role assignments, and ship status callouts showing flux levels (soft vs. hard flux), weapon disable timers, and shield arc orientation in real-time.

Criticisms / Shortcomings: High reliance on custom hotkeys and manual weapon grouping setups that are not immediately transparent to new players.

References: Fractal Softworks Official Hub: https://fractalsoftworks.com/

Genre 3: Roguelikes

FTL: Faster Than Light

What it does best for the next action: Subsystem power distribution, weapon charge bars, projectile target lines, and spatial hull breach/fire hazards are co-located directly on the ship compartment diagram. The player can immediately evaluate both their offensive readiness and their defensive vulnerabilities in one eye sweep.

Criticisms / Shortcomings: Micromanagement of crew repair assignments during dual breaches/boarders can lead to frantic cursor hunting, exacerbated by minimal automated crew pathing feedback.

References: Subset Games / Steam Store Page: https://store.steampowered.com/app/212680/FTL_Faster_Than_Light/

Cobalt Core

What it does best for the next action: Spatial 2D lane-based timeline intent: each card directly previews the ship's horizontal lane shift, the exact trajectory of outgoing and incoming missile/cannons, shield increments, and heat accumulation prior to spending energy.

Criticisms / Shortcomings: Complex mid-turn drone deployments and multiple collision modifiers can occasionally push key spatial intents outside the primary visual focal area.

References: Brace Yourself Games / Steam Store Page: https://store.steampowered.com/app/2179850/Cobalt_Core/

Monster Train

What it does best for the next action: The "End of Turn Math Resolver" previews the combat outcome of every unit on every floor before the turn button is pressed, highlighting which units will die, exact remaining HP values, and status degradation with pulsing health bars.

Criticisms / Shortcomings: Floor-to-floor vertical separation can make tracking global relic triggers and multi-floor spell interactions visually fragmented.

References: Good Shepherd Entertainment / Steam Store Page: https://store.steampowered.com/app/1105220/Monster_Train/

Darkest Dungeon II

What it does best for the next action: Deterministic token economy: all statuses, buffs, debuffs, and target markers are standardized as readable, finite tokens beneath unit sprites, removing hidden probability formulas and clarifying turn-action trade-offs.

Criticisms / Shortcomings: High token stacking during extended boss fights can clutter unit status zones and require frequent tooltip inspection.

References: Red Hook Studios / Steam Store Page: https://store.steampowered.com/app/1940340/Darkest_Dungeon_II/

Slay the Spire

What it does best for the next action: Overhead intent badges above enemies communicate upcoming attack values, multi-attacks, debuffs, or defensive posture changes, allowing players to calculate exact block-to-damage ratios instantly.

Criticisms / Shortcomings: Lack of a native integrated turn action history or undo function for non-random card plays can lead to immediate misclick penalties.

References: MegaCrit / Steam Store Page: https://store.steampowered.com/app/646570/Slay_the_Spire/

Ranked UI Patterns for a 20-Ship Turn-Based Hex Fleet Roguelite

Deterministic Resolution Preview (Monster Train, Cobalt Core, Into the Breach)

Before committing the final attack or movement action, display the exact calculated aggregate damage, shield depletion per facing, and hull impact directly over both the actor and the target. This eliminates mental arithmetic errors and anchors decision-making around known consequences.

Dynamic World-Space Line-of-Sight & Arc Overlay (BattleTech, XCOM 2, Rogue Trader)

Project valid weapon arcs, hex path costs, and target line-of-sight directly onto the tactical hex grid relative to cursor position prior to confirming ship movement. Players should never commit a move only to realize their broadside misses an arc by one hex.

Aggregated Roster Status Triage (Battlefleet Gothic 2, Starsector)

For fleets numbering ~20 ships, condense the roster into glanceable, high-contrast operational states (Ready, Shield Broken, Critical Heat, Target Locked) with batch selection and quick-jump navigation, preventing edge-of-screen tunnel vision.

Direct Spatial Threat Vectors (Into the Breach, Slay the Spire)

Project visible hostile engagement threats, especially Nemesis hunter intentions and firing solutions, directly onto friendly ships on the battlefield rather than burying threat levels solely in a numerical sidebar.

Two-Stage Action Confirmation / Undo Buffer (Into the Breach, Gears Tactics)

Separate ship navigation from weapon discharge; allow full, penalty-free movement undos within the active turn up until an irreversible action (firing, consumable expenditure, or radar ping) is initiated.

Concrete Modifications for Mockup 2B ("Action Column Bold")

KEEP: Top-to-Bottom Decision Hierarchy in the Right Column
Rationale: The structured read order (Active Ship → Move → Fire → Target → End) enforces an intuitive mental flow that mirrors tactical step-by-step resolution. (Proved by BattleTech, FTL).

KEEP: Aggregate Attack Preview ("Both bearing guns, about 31 damage, facing down")
Rationale: Consolidating individual weapon hardpoints into a single aggregate damage prediction line eliminates tedious micro-calculations and speeds up combat rounds across a 20-ship fleet. (Proved by Monster Train, Into the Breach).

KEEP: Left Fleet Roster Glanceable State Chips (Ready, Done, LOW, Braced)
Rationale: Single-word state flags paired with slim health pips allow swift scanning of fleet readiness without opening sub-menus. (Proved by Battlefleet Gothic: Armada 2).

CHANGE: Move & Arc Projection from Pure Text to Grid-Overlay Projection
Rationale: Mockup 2B presents weapon arc and range as descriptive text in the column. Replace or augment this with physical hex highlights showing active broadside/prow arcs emanating from the target hex during movement planning. (Proved by Warhammer 40,000: Rogue Trader, BattleTech).

CHANGE: Nemesis Panel from Static Header to Active Threat Broadcaster
Rationale: Instead of a purely informative header block at the top of the action column, link the Nemesis panel to interactive targeting lines that physically project onto the hex grid toward threatened ships (especially the flagship). (Proved by Slay the Spire, Into the Breach).

ADD: Projected Heat Delta Visualizer on the Action Bar
Rationale: Heat is currently a static number on the top bar. Add a ghosted "+Heat" delta segment to the heat gauge whenever hovering over high-output weapons or thruster maneuvers, preventing accidental reactor shutdown or thermal damage. (Proved by BattleTech, Cobalt Core).

ADD: Two-Step Action Undo / Soft Move Commit
Rationale: Explicitly distinguish the "Move" phase as soft-locked until a weapon or ability fires. Allow players to step back hex movement if they notice their firing arcs do not cover the intended target. (Proved by Into the Breach, Gears Tactics).

CUT: Redundant Weapon-Level Arc/Range Text in Fire Step
Rationale: When a ship is bearing on an enemy, listing raw mechanical text ("Arc: Port 90°, Range: 1-4") inside every weapon item card causes text fatigue across multiple activations. Collapse individual weapon text once an aggregate target solution is generated, highlighting only the weapon name, keycap, and status pip. (Proved by XCOM 2, Monster Train).

Implications for Campaign Map and End-of-Run Screens

Campaign Map Screen: The campaign map must reflect the deterministic intent and relentless pressure seen in FTL and Slay the Spire. The Nemesis hunting clock and adaptation progress should be projected as an encroaching front across the hex node network, letting the player weigh sector fuel/heat rewards against the risk of an ambush. Node icons must use the same high-contrast, dual-channel visual language established in battle (clear shapes and badges, not color alone), with comprehensive hover tooltips detailing node hazards, local fleet modifiers, and available repair facilities before jumping.

End-of-Run Screen: Drawing from Monster Train and Into the Breach, the run summary should avoid walls of raw narrative text and instead supply an analytical breakdown: fleet attrition timelines, Nemesis damage dealt/received, heat expenditure efficiency, and a visual ledger of ship hull/crew losses. Presenting key decision forks (e.g., node pathing choices, adaptation counterplay successes) reinforces mechanical learning and encourages another run through clear tactical causality. (INFERRED)
