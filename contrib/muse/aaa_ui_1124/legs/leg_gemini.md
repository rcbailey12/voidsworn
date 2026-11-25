# Leg: Gemini on Hydrogen (Flash seat), issue 2030

Gate record: signed in to Gemini as Ryan Bailey with the saved Google login, no phone tap needed. New chat, model picker set to "Everyday help - 4 Hydrogen" and verified showing Hydrogen before the brief was pasted as plain text. After generation the picker still showed Hydrogen. Chat: "Voidsworn Fleet UI Redesign Brief", https://gemini.google.com/app/4c168b961382b894

Response verbatim:

Screen 1: Shipyard with the Ships

Layout & Elements
Divide the screen into three vertical zones inside the existing dark ember frame (#120E0D background, 1px solid #4A3831 borders) at 1920x1080 reference resolution:

Left Fleet Roster (360px wide): Vertical scrollable list of compact ship strips (72px tall each). Each strip shows a 48x48px live-rendered portrait thumbnail, ship name, hull class badge, a thin horizontal hull bar (4px tall), and a warning pip if damaged or if a refit slot is empty. Clicking a strip selects that ship. Below the fleet list sits a fixed "Commission New Hull" button (48px tall) that toggles the left list into a roster of purchasable hulls.

Center 3D Bay Viewport (980px wide): A SubViewport rendering a dark, gantry-lit drydock scene. The selected ship mesh sits at origin (0, 0, 0), scaled dynamically so its bounding sphere fills 65% of the viewport height. A key directional light (warm amber #FF9E5E, intensity 1.8) hits from top-front-right; a cool rim light (#4A6B82, intensity 1.2) outlines the silhouette from back-left. By default, the ship rotates on its Y-axis at 6 deg/sec.

Right Inspector & Action Column (580px wide): Retains the existing card grammar.

Header (88px): Ship Name, Class, and the Captain block (48x48px captain portrait, Callsign, Name, XP bar current/next, and one-line trait).

Hull & Shield Bars (64px): Current/Max Hull bar (amber #E07A38) and Current/Max Shield pool bar (cyan #4DA6FF). No directional arcs or facings.

Stats Grid (160px): Two columns of stat rows (Shield Pool, Armor, Max Speed, Turn Rate, Evasion, Shield Regen). Format: Label on left, Base Value on right.

Section Breakdown (140px): Three horizontal strips labeled PROW, MID, ENGINES. Each strip lists its mounted weapon slots and system tags (e.g., PROW: Railgun Mk I, Point Defense).

Refit Slots (120px): Interactive slot buttons showing installed modules or [Empty Slot]. Clicking opens an inline dropdown of available inventory refits.

Action Bar (Bottom, 110px): Four buttons in a 2x2 grid: Repair (Cost), Upgrade to Mk II (Cost), Swap Refit, and Decommission (or Commission Hull when browsing new hulls).

Interactions & Stat Preview

3D Bay Orbit: Left-click and drag inside the Center Viewport pauses auto-rotation and orbits the camera manually (pitch clamped -35 deg to +45 deg, zoom clamped 0.6x to 1.5x bounding radius). Releasing resumes auto-rotation after 2.5s of inactivity.

Hover Stat Diffs: Hovering Repair, Upgrade to Mk II, a refit option in the dropdown, or a new hull in the commission list triggers a preview state:

Numeric Stats: Appends a delta right next to the current value: e.g., 120 (+30) in #4ADE80 (green) for improvements, or 45 (-5) in #F87171 (red) for penalties. Hull and Shield bars render a translucent green extension segment on the right end of the bar for gains, or a hatched red overlay on the portion lost.

System/Weapon Changes: On Mk II hover, any upgraded weapon or unlocked slot text pulses #4ADE80. On New Hull hover, the 3D bay swaps to a wireframe hologram shader (#FF9E5E fresnel) of the candidate hull, and all stats display absolute deltas compared to the currently selected ship.

Cost Check: If the player lacks scrap/currency, the button text turns #F87171, the hover preview still works, and clicking plays an error thud without executing.

Edge Cases

Empty Fleet / Last Ship: Decommission is disabled with tooltip "Cannot decommission last active vessel".

Oversized vs. Tiny Hulls: Camera distance derives from mesh_aabb.get_longest_axis() * 1.45 so dreadnoughts never clip the inspector panel and corvettes are not specks.

Damaged Section on Ship: If a ship enters the shipyard with a destroyed section (e.g., ENGINES at 0 HP), that section's 3D sub-mesh renders charred/sparking in the bay until Repair is hovered (which previews clean geometry) or clicked.

Least Sure Decision & Biggest Risk

Least sure: Auto-resuming Y-axis rotation after 2.5s of manual drag. Some players want to freeze a ship at a specific angle to inspect weapon hardpoints, though a manual pause toggle adds UI clutter.

Biggest risk: Rendering a full 3D SubViewport alongside 48x48px live roster portraits can cause frame drops on low-end GPUs if all roster thumbnails update every frame. Roster thumbnails must render once on ship load/upgrade into static ViewportTexture snapshots, leaving only the active bay ship rendering per frame.

Screen 2: Ship State Plate on the Board

Layout & Elements
Each ship projects a 2D HUD plate anchored to its screen-space bounding box top-center (offset_y = -28px at camera distance 170). Plate dimensions: 136px wide by 54px tall, dark ember fill (rgba(18, 14, 13, 0.88)), 1px border (#4A3831 neutral, #4ADE80 friendly selected, #F87171 hostile targeted).

Top Row (14px tall): Ship Name (left, 11px bold uppercase, truncated at 12 chars) and Captain Callsign or Ship Class icon (right).

Shield Bar (6px tall): Single full-width horizontal cyan bar (#4DA6FF). Displays numeric current/max on hover or when selected. Never split into arcs or facings.

Hull Bar (8px tall): Full-width amber bar (#E07A38), segmented visually into three equal 44px blocks by 1px vertical dividers representing PROW (left), MID (center), and ENGINES (right).

Section Status Strip (22px tall): Three horizontal cells (44px wide each) directly beneath their corresponding hull block:

Intact (>50% section HP): Dark fill, muted label PRW / MID / ENG in #8C7A70.

Damaged (1% to 50% section HP): Amber border #FBBF24, label pulses slowly (0.8 Hz).

Disabled (0% section HP): Solid dark red fill #451414, text switches to a 2-line 9px uppercase readout naming the exact disabled system pulled from that section's active equipment data, e.g., RAILGUN OFFLINE, SHIELD GEN LOST, or THRUST -60%. If multiple systems occupy a disabled section, it shows the primary weapon/system name plus +1 (e.g., LANCE +1 OFF).

Solving Overlapping Marks in Close Quarters
When ships move within 18 world units of each other, overlapping selection rings and floating plates create visual noise. Solve this with three coordinated rules:

Tethered Plate Repulsion: Plates run a lightweight 2D spring-repulsion pass each frame (min_padding = 6px). If two plates intersect, they push apart horizontally and vertically, drawing a 1px angled leader line (#8C7A70, 60% opacity) from the plate's bottom center directly to the ship's center-of-mass pivot on the board.

Focus Elevation & Dimming: Hovering or selecting a ship brings its plate to z_index = 100, scales it to 1.08x, brightens its leader line to 100% white/amber, and drops all non-selected plates within 120px screen radius to 0.45 opacity.

Segmented Floor Ring Occlusion: Instead of solid overlapping circles on the tactical plane, each ship's base ring (radius = ship_footprint) is rendered with a shader that performs a boolean union/cutout against adjacent ships: friendly rings merge outlines cleanly, while an enemy ring intersecting a friendly ring breaks cleanly 4px before the friendly ring's edge rather than crossing over it. A small directional chevron (8px) on the ring perimeter always points directly toward the ship's root transform so ownership is unambiguous even when hulls touch.

Edge Cases

Camera Zoom Extremes: At zoom distance > 220 (strategic overview), the 22px Section Status Strip collapses automatically, shrinking the plate to 110x28px (Name + Shield + Hull only) unless the ship is selected or hovered.

Unshielded / Shield-Broken Ships: When shield_current == 0, the Shield Bar does not vanish (which causes layout jitter); it stays at 6px height as a dark recessed track with a subtle dashed cyan outline while recharging, or solid gray if SHIELD GEN LOST is active on a section.

Least Sure Decision & Biggest Risk

Least sure: Fitting real system names (e.g., "HEAVY PLASMA") inside a 44px wide section cell at camera distance 170 without aggressive abbreviation that hurts readability.

Biggest risk: 2D spring-repulsion on plates during fast camera pans or ship maneuvers can cause plates to jitter or swap sides rapidly if damping is too low. Requires velocity clamping and hysteresis so plates only reorder when centers cross by at least 12px.

Screen 3: Captains and Admirals

Captain Identity Data (Ship Card & Fallen Roll)
Every captain data record expands from {name, xp} to:

portrait_id: Index into the painted portrait atlas (cropped to square head-and-shoulders framing).

callsign: Short 1-word moniker in quotes, e.g., "Vesper", "Ironjaw", "Null".

full_name: Given and family name, e.g., Lt. Mara Vance.

xp / rank: Current XP, next threshold, and rank title.

trait: A single mechanical trait line (max 42 characters), e.g., +15% Railgun reload when Shields < 25%.

Placement:

Shipyard Card: Top-right of the inspector header displays the 56x56px painted portrait framed in 1px solid #4A3831, with Callsign (14px amber bold), Name + Rank (12px bone white), XP bar, and the single trait line in #A89990 directly underneath.

Fallen Roll: Each lost ship entry displays the captain's portrait desaturated to 80% grayscale with a subtle ember vignette, Callsign, Name, Ship Name, Cause of Death summary, and the trait line preserved as an epitaph.

Non-Blocking Comms Banner (Tactical HUD)

Position & Size: Anchored top-left of the battle screen (x = 24px, y = 84px, directly below the top resource/turn bar), 380px wide by 76px tall. This keeps it completely clear of the center playfield, bottom-center ship command bar, and bottom-right fire controls.

Visual Structure:

Left: 64x64px painted admiral or captain portrait (6px padding).

Top-right: Speaker Rank, Callsign, and Ship Name (11px uppercase #E07A38), plus an event tag pill (HAIL, COMMAND, HULL BREACH, KILL).

Bottom-right: Two lines of dialogue (13px #F2EAE4, max 85 characters total) with a 2px vertical accent bar on the left edge colored by event type (cyan for hails/commands, amber for section loss, green for kills, red for ship destroyed).

Timing & Queue Behavior:

Slides in from left (180ms ease-out), holds for 3.6s, fades out (250ms).

Zero Input Capture: mouse_filter = IGNORE across the entire banner hierarchy. Clicking through it selects ships or issues move/fire orders underneath without interruption. Never pauses the simulation or opens a modal.

Priority Queue (Max Depth 2): High-priority events (SECTION LOSS, KILL, ADMIRAL COMMAND) immediately replace a low-priority HAIL after a 0.6s minimum display floor. Duplicate triggers within 4.0s (e.g., two point-defense kills at once) coalesce into a single banner ("Double kill confirmed, Admiral.").

Edge Cases

Admiral vs. Ship Captain: Admiral commands use the Admiral's portrait and a gold #FBBF24 border; ship-specific callouts (section loss, kill) use that specific ship's captain portrait so the player visually connects the voice to the vessel.

Rapid Multi-Ship Damage: If three ships lose sections in the same volley, only the player's currently selected ship or the highest-tier flagship fires a banner; the others rely on their Ship State Plate red alerts to avoid banner spam.

Least Sure Decision & Biggest Risk

Least sure: mouse_filter = IGNORE means players cannot click the banner to jump the camera to the speaking ship, which feels intuitive, though making it clickable violates the strict non-blocking feel if a player accidentally clicks there while panning.

Biggest risk: Portrait pool exhaustion. If a player recruits 12 captains in a long run and only 8 painted portraits exist, duplicate faces break immersion. The portrait picker must sample without replacement from unused portraits first, and apply subtle uniform/color-grade variants if the pool wraps.

Screen 4: After-Action Report (AAR)

Layout & Elements
Replaces the current VICTORY modal with a structured 1120px x 720px dark ember panel centered over the darkened battle scene, preserving the existing salvage choices and bottom action button while upgrading the core body:

Header Bar (64px): VICTORY (or PYRRHIC VICTORY if any player ship was lost) in 24px uppercase serif/display font, mission sector name, battle duration (MM:SS), and total fleet salvage/scrap earned.

MVP Spotlight Strip (88px): Full-width highlighted row (1px solid #FBBF24 border, warm subtle gradient #261B14). Displays the MVP ship's 48x48px thumbnail, Captain portrait, Ship Name, Captain Callsign, and an auto-generated distinction tag based on highest weighted score (e.g., MVP: MOST DAMAGE DEALT (1,420) or MVP: 3 KILLS).

Spotlight note from the chair: Gemini wrote PYRRHIC VICTORY for a win with losses. The word pyrrhic does not appear in the game's current outcome vocabulary as evidenced; the chair treats the header as VICTORY or DEFEAT with a losses line, and flags the label as Gemini's coinage, not game text.

Per-Ship Performance Table (280px, scrollable if >5 ships):

Columns: Ship & Captain (260px), Status (110px: Intact / Damaged / Lost), Kills (80px), Dmg Dealt (120px), Dmg Taken (120px), Captain XP (230px).

Data Visualization: Dmg Dealt and Dmg Taken show exact numbers paired with a subtle background proportional bar relative to the fleet's highest performer so relative contribution scans in under a second.

Captain XP Column: Shows +XP gained, an animated fill bar (0.8s fill on open), and a gold RANK UP badge if a threshold was crossed.

Lost Ships in Table: Ships destroyed during the battle remain in the table with a dark red tint, LOST status badge, and a clickable [View Killmail] button.

Salvage Selection Row (140px): Preserves the existing salvage-one-wreck card choices directly below the table so the player claims rewards in the same flow.

Footer Bar (56px): Continue button (right-aligned, disabled until a salvage option is picked if salvage is available).

Killmail Card (Run Timeline & AAR)
Clicking a lost ship either in the AAR table or on the Run Timeline opens a 420px x 320px floating Killmail Card anchored near the clicked node (dismissible via clicking outside or ESC):

Header: KILLMAIL // [LOST SHIP NAME] in #F87171, plus battle timestamp (T+02:44) and sector node name.

Victim Block: Desaturated captain portrait, Callsign, Ship Class, and the final fatal section status (e.g., MID SECTION BREACHED).

Killer Block: Enemy Ship Name, Enemy Hull Class, and the exact Killing Blow Weapon icon + name (e.g., Sun-Lance Heavy Beam), followed by final hit damage and overkill amount (e.g., 185 DMG (42 Overkill)).

Damage Contributors Line: Lists up to two assisting enemy ships with percentage share (e.g., Assisted by: Ash-Cutter (38% dmg)).

Data Source Requirements
The combat damage resolver must log a lightweight CombatEvent struct on every hull/shield hit (attacker_ship_id, attacker_name, attacker_class, weapon_id, weapon_name, target_ship_id, damage_amount, is_killing_blow, timestamp). These roll up into per-ship totals at battle end and serialize the fatal event into the LostShipRecord saved to the run timeline.

Edge Cases

Environmental / Hazard Kill: If a ship dies to a solar flare or minefield rather than an enemy ship, the Killer Block displays ENVIRONMENTAL HAZARD and the hazard name (e.g., Corona Flare) with no empty enemy ship fields.

All Ships Tied at 0 Kills (Pacifist/Escort Objective): MVP tie-breaker falls back cleanly in order: Kills > Damage Dealt > Damage Taken (Tanked) > Flagship.

Least Sure Decision & Biggest Risk

Least sure: Showing both Dmg Dealt and Dmg Taken as raw numbers without separating shield damage from hull damage. Shield-stripping ships might look weak on raw numbers if shield damage isn't counted, so Dmg Dealt must sum both shield and hull damage inflicted.

Biggest risk: Failing to persist weapon_name and attacker_class strings by value into the LostShipRecord when the enemy ship node is freed on death. If the killmail holds a node reference instead of a serialized dictionary, opening the killmail from the run timeline 20 minutes later will crash or show blank strings.

Strongest Objection to the Brief

Combining the Captain Roster/Portraits (Screen 3) and the Killmail Timeline Feature (Screen 4) into the same sprint as the 3D Shipyard and Battle State Plate risks shipping shallow data plumbing. Right now, captains are just a string and an integer, and battle damage does not track per-weapon killing blows or per-ship damage attribution across turns. Building the UI for Screens 3 and 4 is straightforward, but retrofitting the combat resolver to attribute every point of damage and every killing blow to a specific ship and weapon, plus generating and persisting captain identities across save files, is backend state work that should be locked and tested before the UI layer is wired up. If built simultaneously by separate agents without a frozen CombatStats and CaptainData schema first, the UI will end up mocking fields that the combat engine does not record.
