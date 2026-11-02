# Argon leg: Job 6 (campaign map)
Model: Gemini 4 Argon, Thinking level High
Date: 2026-11-02
Chat: https://gemini.google.com/app/0f31b24a33e904ec
Gates verified: picker read Argon High before submit, prompt bar read Argon High before submit, and prompt bar read Argon High after submit. Both gates passed.

1. Headline

To meet the R51 visual bar and R72 cinematic register, the campaign map should unify its 3D star system with the F4 battle world (world_bake.gd, world_planet.gd, world_rocks.gd, world_living.gd, and board_look.gd) while replacing flat sidebars and floating text with a diegetic, two-tier tactical interface. The single most important technique from our four-game research is the dual-layer semantic zoom and Scan View model from Homeworld and Endless Space 2, which keeps the 3D star system clean and atmospheric at rest while projecting crisp vector leader lines, route scarcity comparisons, and reward tags only on hover or lens toggle. By arranging the three sectors as successive orbital arcs spiraling inward around the shared Hollow Sun, the map turns a three-act roguelite run into one continuous, high-craft voyage toward the dead star's core.

2. Research Notes per Game

Sins of a Solar Empire 2

Primary sources: Stardock and Ironclad Games official game overview (https://www.sinsofasolarempire2.com) and Steam developer diaries covering dynamic planetary orbits, the 64-bit engine lighting pipeline, and UI scaling (https://store.steampowered.com/news/app/1575940). Fine details on cursor hover timing and line shaders noted below are my own impression from the release build.

Camera model: Uses a continuous, free-panning strategic zoom that transitions smoothly from an entire multi-star gravity network down to the hull plating of an individual corvette without a loading cut (https://www.sinsofasolarempire2.com). At maximum zoom-out, the camera locks to a high oblique angle above the ecliptic plane; zooming in releases the pitch constraint so the player can orbit around planets and stations (my impression).

Scale tricks: Planets and stars are compressed to roughly 1:100 of real astronomical spacing, but each gravity well has a visible circular boundary ring on the orbital plane (https://store.steampowered.com/news/app/1575940). Asteroids, moons, and orbital structures sit inside that well boundary and rotate on real-time orbital tracks, making the system feel vast through motion and layered parallax rather than empty distance (https://www.sinsofasolarempire2.com).

Icons over 3D: As the camera pulls back, 3D ship meshes cross-fade into crisp 2D tactical silhouettes stacked into fleet banners above the gravity well (https://store.steampowered.com/news/app/1575940). Crucial status pills (shield bars, fleet supply weight, and planet level) dock neatly onto a single anchor point per planet rather than floating over every individual structure (my impression).

Route lines: Phase lanes are drawn as luminous, animated plasma conduits that curve along orbital paths and dynamically re-link as planets move (https://www.sinsofasolarempire2.com). Ownership colors the phase lane endpoints in the holding faction's hue, while an incoming enemy fleet sends a pulsing directional warning chevron along the lane well before arrival (https://store.steampowered.com/news/app/1575940).

Fog and information hiding: Unexplored gravity wells show their physical planet silhouette and orbital ring in desaturated, unlit shadow (https://store.steampowered.com/news/app/1575940). Once scouted, the planet retains a last-known snapshot of stationary structures while hiding transient fleet icons behind a dimmed sensor shroud until active vision returns (my impression).

Danger and reward advertising: Hovering a gravity well brings up a compact tactical tooltip showing total hostile fleet supply badge icons, planetary resource asteroid counts (metal and crystal extractors), and neutral militia strength before the player orders a phase jump (https://store.steampowered.com/news/app/1575940).

Stellaris

Primary sources: Paradox Interactive official Stellaris Wiki covering User Interface, Exploration, and FTL travel (https://stellaris.paradoxwikis.com/User_interface, https://stellaris.paradoxwikis.com/Exploration, https://stellaris.paradoxwikis.com/FTL). Observations on shader glow and camera easing are my own impression.

Camera model: Splits presentation into two separate views: a galaxy map and an individual system view (https://stellaris.paradoxwikis.com/User_interface). Both use a constrained orbit-and-pan camera angled at roughly 35 to 60 degrees above a flat ecliptic plane, with a toggle button or scroll boundary that snaps between the system's outer hyperlane ring and the galaxy map (https://stellaris.paradoxwikis.com/User_interface).

Scale tricks: Inside a system view, the central star is oversized and sits at the origin, while planets sit on thin concentric etched rings with exaggerated sizes relative to their orbits (https://stellaris.paradoxwikis.com/User_interface). Deep-space nebula backdrops are painted onto a distant skybox with two layers of slow-drifting star dust below the ecliptic plane to create depth (my impression).

Icons over 3D: Every celestial body projects a vertical pin down to the orbital plane and attaches a flat nameplate directly below the object (https://stellaris.paradoxwikis.com/User_interface). Holding the Alt key toggles detailed map mode, expanding compact resource icons into full numerical yields, while normal view hides empty orbital yields to reduce clutter (https://stellaris.paradoxwikis.com/User_interface).

Route lines: Hyperlanes appear on the galaxy map as straight glowing lines between star systems, colored cyan for safe passable routes, red for blocked or hostile FTL inhibitors, and dashed amber for queued fleet paths (https://stellaris.paradoxwikis.com/FTL). Inside the system view, hyperlane exits sit on the outer perimeter ring as directional chevron gates pointing toward neighboring stars (https://stellaris.paradoxwikis.com/FTL).

Fog and information hiding: Unvisited systems have gray names and hidden resource tags on the galaxy map (https://stellaris.paradoxwikis.com/Exploration). Low-intel systems show a question-mark icon over fleet banners and hide planet class icons until a science ship or sensor array reaches the required intel threshold (https://stellaris.paradoxwikis.com/Exploration).

Danger and reward advertising: Hostile leviathans, space fauna, and enemy fleets display a red skull badge or numerical military power rating alongside the system nameplate (https://stellaris.paradoxwikis.com/User_interface). Anomalies, archaeological sites, and strategic resources appear as distinct gold or purple hexagonal badges next to the star name so the player can weigh risk against reward from the high map (https://stellaris.paradoxwikis.com/Exploration).

Homeworld (Homeworld Remastered Collection and Homeworld 3)

Primary sources: Gearbox and Blackbird Interactive official site and developer blogs (https://www.homeworlduniverse.com), Steam developer updates on the Sensors Manager and terrain megastructures (https://store.steampowered.com/news/app/1840080), and Blackbird Interactive GDC presentations on Homeworld visual design (https://www.gdcvault.com). Specific line-weight observations are my own impression.

Camera model: Full 3D spherical orbit camera centered on any selected squadron, asteroid, or objective marker, paired with an instant toggle (Spacebar) into the Sensors Manager (https://store.steampowered.com/news/app/1840080). Pressing Spacebar pulls the camera rapidly upward to a macro tactical overview while keeping the 3D scene alive underneath (https://www.homeworlduniverse.com).

Scale tricks: Homeworld sells immense scale by contrasting tiny ships against monolithic background megastructures, wreckage slabs, and painted nebula walls lit by a single harsh directional sun (https://www.gdcvault.com). In the Sensors Manager, a circular holographic range disc with degree ticks and altitude stalks grounds 3D positions onto a readable reference plane (https://store.steampowered.com/news/app/1840080).

Icons over 3D: In the normal battle camera, HUD markers are minimal geometric brackets (diamonds for fighters, triangles for corvettes, rectangles for frigates and capitals) that stay completely hidden until hovered or box-selected (https://www.homeworlduniverse.com). Entering Sensors Manager replaces ship models with bright vector pips, wireframe sensor spheres, and clean 45-degree leader lines leading to crisp monospace labels (my impression).

Route lines: Movement orders draw a precise 3D vector line along the horizontal plane coupled with a vertical drop-line to show elevation, terminating in a target ring (https://store.steampowered.com/news/app/1840080). Waypoint paths use crisp nodes that change from green (move) to red (attack move) or yellow (dock/salvage) (https://www.homeworlduniverse.com).

Fog and information hiding: Active sensor coverage is rendered as a translucent blue wireframe dome around friendly craft (https://store.steampowered.com/news/app/1840080). Outside those domes, the map shows static terrain silhouettes (dust clouds, megaliths, and debris trenches) and pulsing red distortion pings for unverified gravitic signatures (https://store.steampowered.com/news/app/1840080).

Danger and reward advertising: Resource pockets (RU asteroid clusters and salvageable hulks) glow with amber points in Sensors Manager, while dangerous ion storms or radiation clouds are outlined with hazard boundary brackets and crackling particle volumes before ships enter them (https://store.steampowered.com/news/app/1840080).

Endless Space 2

Primary sources: Amplitude Studios community developer blogs on the Galaxy Map and Scan View (https://community.amplitude-studios.com), official Steam developer logs (https://store.steampowered.com/news/app/392110), and the Endless Space 2 Wiki (https://endless-space-2.fandom.com/wiki/Endless_Space_2_Wiki). Notes on glass blur opacity and transition curves are my own impression.

Camera model: A top-down tilted strategic camera that glides over a 3D galaxy table, paired with a mouse-wheel zoom into an angled planetary orbit view and a Spacebar "Scan View" toggle (https://store.steampowered.com/news/app/392110). Scan View does not move the camera; instead, it dims the background nebula by roughly 50 percent and switches on high-contrast data overlays (https://community.amplitude-studios.com).

Scale tricks: Star systems sit inside a dark, volumetric dust cloud sculpted like an island archipelago, with deep parallax starfields far below the play plane (https://store.steampowered.com/news/app/392110). Zooming into a system swings the camera from top-down to a dramatic low cinematic angle where planets rotate in front of a massive star, using depth-of-field blur to make the background look miles away (my impression).

Icons over 3D: Amplitude uses ultra-clean flat vector typography anchored to 3D nodes via thin leader lines with 45-degree bends (https://community.amplitude-studios.com). System plates use dark frosted glass with a 1-pixel bright accent border matching the owning empire's color, showing only the name, curiosity count, and fleet shield icon until hovered (https://endless-space-2.fandom.com/wiki/Endless_Space_2_Wiki).

Route lines: Star lanes are drawn as sleek double-line filaments connecting system rings (https://endless-space-2.fandom.com/wiki/Endless_Space_2_Wiki). When a fleet plots a move, the lane fills with glowing white-cyan ticks showing exactly how many turns the transit takes, and hostile blockades put a pulsing red ring around the destination node (https://store.steampowered.com/news/app/392110).

Fog and information hiding: Unexplored star lanes fade into dotted trails entering dark, unlit dust banks (https://endless-space-2.fandom.com/wiki/Endless_Space_2_Wiki). Unsearched "Curiosities" (events and ruins) show up as pulsing circular sonar rings on a planet's orbit, telling the player what category of discovery awaits (military, science, or lifeform) without spoiling the outcome (https://endless-space-2.fandom.com/wiki/Endless_Space_2_Wiki).

Danger and reward advertising: Hovering a system or toggling Scan View splits a planet's badge into FIDSI resource dots, curiosity tier icons, and strategic resource crystals (Titanium, Hyperium), while hostile fleets display a shield badge whose size and notch count scale with military strength (https://community.amplitude-studios.com).

3. Steal and Avoid

Because Embers of the Hollow Sun is a three-sector roguelite with a single player fleet, forward-only lanes, and route choice under scarcity as its core decision, 4X empire-management conventions must be filtered aggressively.

Technique | Source Game | Verdict | Why (Tied to Section 4 Facts & R51/R72)
Scan View lens (dimmed 3D + crisp vector overlay on demand) | Endless Space 2 / Homeworld | Steal | Directly fulfills R72 (cinematic first, information layered on demand rather than a permanent spreadsheet look) while solving R51's cheap panel complaint.
45-degree angled leader lines with frosted hairline pills | Endless Space 2 / Homeworld | Steal | Replaces floating text over 3D stops with anchored precision UI that never collides with shipyards, planet limbs, or threat diamonds.
Curved orbital phase conduits with directional pulse chevrons | Sins of a Solar Empire 2 | Steal | Reinforces that the player moves only forward along orbital arcs around the Hollow Sun and makes safest/richest route comparisons read immediately.
Gravity-well circular boundary rings on the orbital plane | Sins of a Solar Empire 2 | Steal | Grounds each stop (planet, shipyard, drydock, graveyard) inside its own miniature orbital diorama and gives altitude stalks a clear floor.
Sonar curiosity rings for unknown signals and cores | Endless Space 2 | Steal | Advertises unknown signal events and the four active Lattice cores in range without cluttering the map with verbose text boxes.
Multi-tier galaxy-to-system zoom transitions | Stellaris | Avoid | A run is only three sectors with one screen per sector and one fleet; a separate galaxy map level wastes clicks and breaks the Hollow Sun's constant presence.
Real-time moving planetary orbits that alter lane connections | Sins of a Solar Empire 2 | Avoid | Route choice under scarcity requires a deterministic forward-only DAG (directed acyclic graph); moving nodes that break lanes would violate core roguelite planning.
Sensor fog-of-war domes and scouting intel tiers | Stellaris / Homeworld | Avoid (Mechanic) / Adapt (Visual) | No new mechanics allowed. Instead of scouting fog, use visual dimming exclusively for burned stops behind the player and unreachable branches after a forward choice.
Empire resource ribbons and persistent multi-fleet outliners | Stellaris / Endless Space 2 | Avoid | The player controls one fleet, owns no territory, and obeys R72 against permanent spreadsheet sidebars.

4. The Design: Next Step from G3 State

The G3 stream (rounds 1 to 4) already established a real 3D star system, distinct 3D stop models, camera zoom, route lighting on hover, threat diamonds, and a Low quality setting. The remaining gap is that the F4 battle world has leaped ahead in lighting, sky baking, planet shaders, and rock rendering, while the map's panels and text remain the least rebuilt part from the R51 cheap list. This design upgrades the map to F4 visual parity and rebuilds the UI layer around R72.

4.1 System View (Reusing F4 Battle World Assets)

Shared Sector Sky Bake (world_bake.gd): Replace the current G3 campaign background with the exact world_bake.gd pipeline from F4. When the player enters a sector, the map generates or loads that sector's painted nebula skybox, pin-sharp starfield, and galaxy band, and passes that same baked sky texture into every battle within that sector. Transitioning from the sector map into a battle page (which already sits over the dimmed star system in G3) now shares identical nebula colors and star positions, eliminating visual seam between map and combat.

Unified Hollow Sun (world.gd + G3 Black Hole): Merge the F4 battle world's dead star (world.gd) with the G3 campaign black hole. Keep G3's photon ring and subtle Doppler beaming (brighter on the approaching side), and upgrade its accretion disc to F4's two-part structure: a blazing, dense inner ring and a see-through outer gas sheet with true background sky lensing and the bent far side of the disc arching over the central shadow.

Volumetric Depth and Floor (world_living.gd and board_look.gd): Bring world_living.gd directly into the campaign camera. Add near-camera drifting dust specks that react to camera pan and zoom, middle-distance translucent gas wisps drifting along the orbital arcs, and board_look.gd's dark floor beneath the system ecliptic so that stop rings, lane conduits, and threat diamonds pop against controlled dark values rather than getting lost against bright nebula patches.

4.2 The Lanes (Forward-Only Orbital Phase Conduits)

Curved Orbital Conduits: Instead of straight point-to-point rulers, draw jump lanes as gently curved phase splines that follow the orbital flow around the Hollow Sun, inspired by Sins of a Solar Empire 2 (https://www.sinsofasolarempire2.com). Each lane consists of a thin, crisp core filament wrapped in a soft directional plasma pulse moving forward toward the sector flagship.

Four Visual Lane States (Presentation Only):

Visited / Burned Path Behind Player: Once the fleet moves forward, the lane and stop behind it cool into a fractured, dark-amber ash trace with drifting cinders, visually communicating "no going back" without text warnings.

Unreachable / Bypassed Branches: Forward stops that become mathematically unreachable because the player took a diverging branch fade to 20 percent opacity gray-blue ghost filaments with desaturated stop models, keeping the player's eyes focused only on valid future choices.

Reachable Forward Routes (At Rest): Rendered in clean silver-blue hairlines with subtle directional chevrons advancing away from the player's fleet token.

Route Comparison on Hover: Retain G3's safest and richest route lighting when hovering a fight or future node, upgrading the shader to Endless Space 2 style double-rail conduits: cool cyan-teal rails for the safest path (lowest cumulative threat diamonds) and warm burnished gold rails for the richest path (highest reward and core density).

4.3 Stop Presentation (Side-Lit Dioramas and Gravity Wells)

Directional Side-Lighting from the Hollow Sun (world.gd and board_look.gd): Every stop in the sector map must be lit primarily by a point/directional light source aligned with the Hollow Sun's inner accretion disc, plus a faint cool rim light from the sector's world_bake.gd nebula sky. This gives every planet, station, shipyard, and asteroid a bright lit face toward the center of the system, a soft terminator edge, and a true dark side facing outer space.

Upgraded Planet-Edge Stops (world_planet.gd): Replace the older, flatter G3 planet stop with the full F4 world_planet.gd implementation. Depending on the sector and stop seed, spawn one of the six F4 planet classes (gas giant, ice giant, terran, volcanic, barren, or ice world) complete with atmosphere limb glow, cloud layers, night-side city or fissure lights on the dark hemisphere, planetary rings, and an orbiting moon.

Upgraded Asteroid Belt and Ship Graveyard Stops (world_rocks.gd): Replace the G3 displaced rocks with world_rocks.gd's five regional rock kinds (stone, iron, carbon, ice, crystal) featuring shader-drawn craters, true dark sides, and slow tumbling motion. For asteroid belt stops, curve a miniature world_rocks.gd belt stream inside the stop's boundary ring; for ship graveyards, mix G3's hull death pieces with slow-tumbling iron or carbon rocks and faint volumetric gas wisps (world_living.gd).

Stations, Shipyards, Drydocks, Tenders, Unknown Signals, and Flagships: Keep the readable G3 3D meshes (plated orbital station with window strips, shipyard gantry with crane and floodlights, drydock clamps and work drones, field repair tender, unknown signal beacon, and sector flagship). Place each inside a Sins of a Solar Empire 2 style circular gravity-well ring on the ecliptic plane (tinted by stop kind as in G3), add a subtle vertical altitude stalk down to the ring, and increase emissive contrast on window strips, welding arcs, and floodlights against their new dark sides.

4.4 Panels and Text (Fixing the R51 Cheap List under R72)

Retiring the Permanent Spreadsheet Sidebar: In compliance with R51 and R72, remove opaque rectangular sidebars and floating multi-line text stacks. At rest, the screen shows over 90 percent unobstructed 3D space: the Hollow Sun, the orbital stops, the fleet token, and a minimal top HUD bar.

Homeworld / Endless Space 2 Precision Stop Tags: Each reachable stop projects a single thin, 45-degree angled vector leader line from its base ring to a compact dark-glass pill (80 percent dark slate opacity, subtle backdrop blur, 1-pixel hairline border tinted by the holding faction's color).

At Rest (Default Cinematic View): The pill shows only three items: a crisp vector icon for stop kind, the faction crest badge, and the holographic threat diamonds (or a gold core ember badge if a Lattice core sits there). This keeps the G3 zoom-priority rule (hiding labels that would run under open panels) while making crowded stacks effortless to read.

On Hover or Tactical Lens Hold (Spacebar / Tab): Holding Spacebar or hovering a node activates the Endless Space 2 style "Scan View". The 3D star system dims slightly by 30 percent, reachable lanes brighten, and every reachable stop pill smoothly expands horizontally to reveal the stop name, place type, exact reward tags (salvage, hull repair, shipyard tier, core name), and safest/richest route indicators.

Briefing and Detail Drawer: Clicking or hovering a stop to inspect its full briefing opens a sleek, angled glass card anchored to the right margin (occupying less than 22 percent of screen width) with a chamfered corner, a prominent Hegemony or faction watermark crest in the header, high-contrast sans-serif headers with generous letter tracking, and tabular numerals for threat and reward breakdowns.

4.5 Sector Transitions (Three Sectors Ringing the Hollow Sun)

Story Geometry Made Visible: Lore bible r8 states that the three sectors ring the Hollow Sun. Rather than cutting to an unrelated star system between sectors, all three sectors inhabit different orbital quadrants and radial distances around the same central Hollow Sun:

Sector I (Outer Rim Perimeter): Wide orbital radius, camera angled at 30 degrees looking inward across the outer accretion disc toward the distant Hollow Sun in the upper-left quadrant.

Sector II (Mid-Disc Shear Zone): Closer orbital radius on the opposite side of the black hole, camera angled at 38 degrees where the see-through outer gas disc sweeps directly beneath the lanes.

Sector III (Inner Horizon / Photon Precipice): Tightest orbital arc right against the dense inner accretion ring and lensed shadow, camera pitched steeply at 45 degrees over the glaring inner horizon.

Seeing Sector II and III Coming: Beyond the Sector I flagship boss node, two distant, out-of-focus orbital highway beacons and faint stop silhouettes are visible across the curvature of the accretion disc, labeled in dim holographic text as "Sector II: Chorus / Glasswrights Transit" and "Sector III: Inner Eclipse". When the player defeats the Sector I flagship, the camera does not fade to black; it executes a smooth 3.5-second orbital whip-pan around the Hollow Sun's photon ring as the world_bake.gd nebula cross-fades into Sector II's regional palette.

4.6 The Information Layer (Cores, Nemesis Clock, Danger, and Rewards)

Top Telemetry Bar (Integrated Diegetic Header): A single, slim top-center glass strip holds the two macro run trackers so they never require a sidebar:

The Nemesis Clock: Positioned dead center at the top as a circular eclipse dial modeled after the Hollow Sun's photon ring. As the player wins fights and makes loud choices, segments of the dial ignite in molten crimson-gold. Hovering the dial shows the exact actions that filled it and the imminent Nemesis modifier; when full, the dial's outer ring pulses in sync with a subtle crimson rim-light added to every fight stop on the map (preserving G3's full-state fight presentation change).

Six Lattice Cores ("Cores in Range"): Positioned directly flanking the Nemesis dial are six small hexagonal socket slots representing the six Lattice cores (embers) from lore bible r8. The two out-of-range cores for the current run sit dark and shuttered; the four active "Cores in range" glow amber and list their names on hover. Furthermore, whichever stop in the sector actually holds or leads to an in-range core projects a pulsing golden Endless Space 2 sonar ring around its gravity well on the 3D map, linking the HUD slot directly to the physical route choice.

Danger and Rewards: Danger retains G3's holographic threat diamonds floating above fight stops in the danger band's color (teal for low, amber for medium, crimson for elite/boss), paired with a distinct skull-chevron frame around the mandatory reachable elite stop. Rewards appear as color-coded micro-badges inside the stop's glass pill (wrench icon for hull repair, anvil/crane for shipyard modules, ember icon for Lattice core, credit/salvage pips for currency).

5. Mock Layout per Sector

Sector 1: The Outer Rust Perimeter (Hullbreakers and Hegemony)

Faction & World Palette: Held by Hullbreakers and the Hegemony. world_bake.gd sky bake uses dusty rust-ochre and bruised slate-blue nebula clouds with a crisp, cold white galactic band. world_planet.gd spawns a scarred Barren world and a banded Gas Giant with industrial night lights. world_rocks.gd uses stone and iron rock kinds (warm grays and oxidized rust-browns). Faction UI accents use Hegemony brass-gold and Hullbreaker industrial hazard-orange.

Hollow Sun & Lane Geometry: The Hollow Sun sits in the upper-left background (roughly 20 percent from top, 22 percent from left), occupying about a sixth of the screen width, casting warm golden-white side light from upper-left to lower-right across all stops. Lanes sweep in a broad clockwise arc from bottom-left (entry) to upper-right (flagship exit) across five columns of depth.

What the Player Sees:

On Arrival: The camera frames the player's fleet token docked at an outer Hegemony orbital beacon in the bottom-left foreground, with world_living.gd dust specks drifting past the lens. Ahead, two initial lanes split toward an asteroid belt fight (tumbling iron rocks with two amber threat diamonds) and a planet-edge fight above a side-lit barren world.

At Mid-Sector: The burned path behind the fleet glows like cooled charcoal. The player faces the classic scarcity fork: an upper inner lane closer to the Hollow Sun's glare leading through a Hullbreaker ship graveyard elite fight (three crimson threat diamonds and a pulsing golden Lattice core sonar ring) followed by a drydock, versus a safer outer lane passing an unknown signal event and a field repair tender.

Facing the Boss: At the upper-right convergence sits the Sector 1 Hegemony/Hullbreaker Flagship anchored beside a floodlit shipyard and a ringed gas giant. Beyond the flagship's gravity well, the orbital phase conduit curves inward toward the accretion disc where Sector 2's distant beacon glimmers.

Sector 2: The Glass Shear (Adding Chorus and Glasswrights)

Faction & World Palette: Adds the Chorus and the Glasswrights alongside surviving Sector 1 presences. world_bake.gd sky bake shifts to bioluminescent teal, deep violet, and prism-cyan nebula sheets. world_planet.gd features an Ice Giant with wide crystalline rings and a Terran or Ice world with geometric Glasswright orbital mirrors. world_rocks.gd uses ice and crystal rock kinds that catch specular highlights from the accretion disc. Faction UI accents add Chorus iridescent cyan and Glasswright prismatic silver.

Hollow Sun & Lane Geometry: After the orbital camera transition, the Hollow Sun sits larger and lower in the upper-center of the frame (30 percent of screen width), with the see-through outer gas of F4's two-part accretion disc swirling directly underneath the mid-sector stops. Lanes run left-to-right in a tighter, braided double-helix arc across the glowing outer gas sheet.

What the Player Sees:

On Arrival: The fleet arrives on the left flank above a stream of world_rocks.gd ice and crystal asteroids. The Nemesis clock at top-center is now half-lit, and two more "Cores in range" pulse on the map.

At Mid-Sector: Stops sit inside pockets of world_living.gd violet gas wisps and ion-storm nebula pockets. The player must weigh a Glasswright shipyard and high-reward Chorus elite node (surrounded by refracting crystal rocks) against a lower-threat route through a drydock and unknown signal.

Facing the Boss: On the right edge, framed directly against the bent far side of the Hollow Sun's accretion disc, waits the Sector 2 Flagship. If the Nemesis clock filled during the sector, crimson arc-lightning dances along the flagship's gravity ring and top HUD dial.

Sector 3: The Inner Eclipse (Adding the Eclipse)

Faction & World Palette: Adds the Eclipse faction at the edge of the dead star Ardent. world_bake.gd sky bake is stark obsidian-black and deep crimson-ash, letting the Hollow Sun dominate the dynamic range. world_planet.gd spawns a tidally locked Volcanic world with glowing magma cracks on its dark hemisphere. world_rocks.gd uses carbon and crystal rocks (matte obsidian slabs with razor-sharp specular rims). Faction UI accents use Eclipse void-violet and coronal gold-white.

Hollow Sun & Lane Geometry: The Hollow Sun fills the entire upper-right quadrant and background horizon (nearly 45 percent of the frame), its dense inner accretion ring, sky lensing, photon ring, and bright approaching-side Doppler beaming casting dramatic, high-contrast side lighting across every stop. Lanes spiral steeply from bottom-left inward toward the photon ring at center-right.

What the Player Sees:

On Arrival: The fleet emerges over a shattered carbon-rock belt (world_rocks.gd) and a cracked volcanic moon (world_planet.gd). Every shadow is pitch-black (board_look.gd dark floor), and every lit hull face gleams with intense amber-white rim light.

At Mid-Sector: With the Nemesis clock near or at full capacity, the remaining reachable lanes cut across an Eclipse orbital station, a final desperate drydock, and the last reachable Lattice core guarded by an Eclipse elite detachment. Bypassed lanes dissolve into dark ash.

Facing the Boss: The Sector 3 Flagship sits right on the precipice of the Hollow Sun's photon ring, silhouetted against the lensed starfield and blazing inner disc, delivering the Star Wars / Sins of a Solar Empire 2 / EVE Online cinematic climax requested in R51.

6. Build Order

Each step is ordered so that visual foundation lands before UI polish, keeping the game playable at every commit and maintaining the RTX 5080 performance bar (60 fps locked with no frame over 16.8 ms, ~200 fps average uncapped, 45 fps 1% low).

Hook world_bake.gd and board_look.gd into the Sector Map Scene

Implementation: Replace the G3 campaign sky background with the sector's world_bake.gd nebula/star bake and add board_look.gd's dark floor plane and directional light aligned to the Hollow Sun's position. Cache the baked Cubemap/Texture so battles in the same sector reuse it without re-baking.

What the owner sees in screenshots: The map immediately loses its flat space background; deep painted regional nebulae and pin-sharp stars match the F4 battle shots, and all 3D stops gain dramatic side-lighting with true dark sides against a rich dark floor.

Low quality fallback: Bake the sky texture at half resolution (e.g., 1024x1024 instead of 2048x2048) and disable real-time shadow casting on the directional sun light, keeping only shader N dot L side lighting.

Unify the Hollow Sun with F4's Two-Part Accretion Disc (world.gd) and Add world_living.gd Depth

Implementation: Swap the G3 black hole disc mesh/shader for F4's two-part accretion disc (dense inner ring, see-through outer gas, background sky lensing, bent far side over the shadow) while preserving G3's photon ring and Doppler beaming parameters. Instance world_living.gd camera dust specks and mid-distance gas wisps along the lane plane.

What the owner sees in screenshots: The Hollow Sun looks massive, physically grounded, and identical in quality to F4 combat; subtle dust specks and gas wisps give the map immediate 3D depth and scale.

Low quality fallback: Disable screen-space sky lensing distortion (fall back to a static pre-bent inner ring texture), halve the raymarch/layer steps on the outer gas disc, and reduce world_living.gd particle counts by 75 percent (matching G3's existing Low tier rule).

Upgrade Planet, Asteroid, and Graveyard Stops to world_planet.gd and world_rocks.gd

Implementation: Replace the G3 planet-edge stop mesh with world_planet.gd (spawning gas giant, ice giant, terran, volcanic, barren, or ice worlds per sector palette with atmosphere limb, clouds, night lights, rings, and orbiting moon). Replace G3 asteroid belt and graveyard rocks with world_rocks.gd (stone, iron, carbon, ice, crystal by sector) with shader craters and slow tumble. Add circular gravity-well base rings and altitude stalks to all stops.

What the owner sees in screenshots: Every stop looks like a miniature F4 battle diorama rather than a placeholder token; planets have glowing terminators and night lights, and asteroid stops tumble with regional rock varieties inside crisp tactical rings.

Low quality fallback: Disable procedural cloud-shadow layers on world_planet.gd, reduce world_rocks.gd MultiMesh instance counts per stop from 40+ down to 12 rocks, and freeze rock tumbling animations outside the hovered stop.

Rebuild Jump Lanes as Curved Orbital Conduits with Four Visual States

Implementation: Convert straight lane lines into curved Bezier splines following the orbital arc around the Hollow Sun. Implement the four shader states: cooled ember-ash for visited stops behind the player, 20 percent ghost lines for unreachable bypassed branches, silver-blue forward conduits with directional pulse chevrons for reachable routes, and double-rail cyan (safest) / gold (richest) highlights on hover.

What the owner sees in screenshots: The sector reads as a natural orbital system rather than a flat flow-chart; burned paths behind the fleet and forward route scarcity are unmistakable at a glance.

Low quality fallback: Replace animated multi-pass glow shaders on lanes with a single unlit scrolling UV strip and disable particle cinders on burned lanes.

Replace Cheap Panels and Floating Text with the Two-Tier Diegetic HUD (R51 & R72)

Implementation: Remove permanent sidebars. Build the top-center glass telemetry bar housing the circular Nemesis eclipse dial and the six Lattice core hexagonal sockets (highlighting the four in range and projecting gold sonar rings onto matching map stops). Replace floating stop labels with 45-degree leader lines and frosted hairline pills that show compact icons (kind, faction crest, threat diamonds) at rest and expand on hover or Scan View hold (Spacebar/Tab). Restyle the right-hand briefing card with dark glass blur, chamfered borders, and high-contrast typography.

What the owner sees in screenshots: The "cheap panels and text" from R51 are completely gone; at rest the map looks like a cinematic frame from Sins of a Solar Empire 2 or Homeworld, and holding Scan View or hovering a stop presents crystal-clear tactical telemetry.

Low quality fallback: Replace real-time BackBufferCopy frosted glass blur behind UI pills and panels with a solid 90 percent opacity dark-slate color fill.

Implement Per-Sector Orbital Framing and Distant Sector Beacons

Implementation: Configure the three sector camera presets (Sector 1 outer rim at 30 degrees, Sector 2 mid-disc shear at 38 degrees, Sector 3 inner horizon at 45 degrees), place distant parallax beacons for upcoming sectors beyond the flagship node, and animate the camera along an orbital spline around the Hollow Sun on sector clear.

What the owner sees in screenshots: Shots of Sector 1, Sector 2, and Sector 3 each have an unmistakable silhouette, color palette, and Hollow Sun scale progression, proving that the three sectors physically ring the dead star.

Low quality fallback: Replace the continuous 3D orbital camera transition with a short 0.5-second cross-dissolve cut between sector camera presets so no dual-sector assets stay in VRAM simultaneously.

7. Not Checked

The evidence pack does not establish the following implementation details, which this proposal assumes:

Exact G3 campaign GDScript filenames and node tree: The pack names the F4 scripts in godot/world/ (world.gd, world_planet.gd, world_rocks.gd, world_living.gd, world_bake.gd, board_look.gd) and cites docs/shots/g3_campaign/README.md, but does not list the exact script paths or Control node names for the G3 campaign map scene.

Exact node count and graph dimensions per sector: This layout assumes roughly 10 to 16 stops arranged across 4 to 6 forward columns per sector; if a sector generates 25+ stops, leader-line length and gravity-well ring radius will need a smaller scalar.

Whether "Cores in range" are tied to specific stops or sector completion: The pack states that the map already shows "Cores in range" with their names (four of six per run). If a core is awarded only by specific elite/event/boss stops, the golden sonar ring attaches to those stops; if cores are sector-wide modifiers, the sonar ring attaches to the sector flagship and top HUD sockets.

Font assets currently in the repository: The UI upgrade assumes a clean geometric sans-serif font and a tabular monospace font are already imported in godot/ or can be configured via Godot 4.7 FontVariation (tracking and OpenType tabular numerals) without adding external dependencies.
