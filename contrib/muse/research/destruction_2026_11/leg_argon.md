# Argon leg (filed with chair header)



Model: Gemini Argon, thinking level High. Gates: picker and prompt bar both read Argon High before sending, and the prompt bar still read Argon High while the answer generated. Files attached: pack.md and leg_prompt.md. Conversation: https://gemini.google.com/app/2922827adea7702b

Run: Nov 1, 2026. The report below is the model's reply, verbatim; Gemini UI citation chips and navigation text are not part of the reply and were excluded by the runner.

---

1. Per game
Homeworld 3

(a) Accumulating hull damage:

Far tactical camera: At tactical zoom, accumulating damage reads through persistent dark grey smoke ribbons trailing behind moving ships, small orange surface fires, and a gradual dulling of clean fleet paintwork (Homeworld 3 gameplay, observation). The game relies on particle trails and silhouette contrast rather than fine texture detail at distance (Homeworld 3 gameplay, observation).

Close camera: Looking close reveals a real-time directional battle-scar system driven by actual weapon impact locations on the hull mesh (Blackbird Interactive dev blog on ship damage, developer blog) [UNVERIFIED]. Kinetic impacts stamp localized crater normal maps and dark soot masks, while beam weapons paint continuous glowing thermal trench lines across the armour shader that slowly cool from bright orange to charred black (Homeworld 3 gameplay, observation).

(b) Breaches and internal damage:

Far tactical camera: Breaches read only as brighter venting jets of gas and fire erupting from scarred hull zones (Homeworld 3 gameplay, observation).

Close camera: The game does not carve real 3D geometry holes into walk-through room interiors during live combat (Homeworld 3 gameplay, observation). Instead, deep scars use parallax occlusion or layered interior-mapping shaders inside the hull material to fake recessed dark structural ribs and glowing hot metal beneath stripped plating, backed by solid opaque darkness so the ship never looks hollow (Homeworld 3 gameplay, observation) [UNVERIFIED].

(c) The kill and break-up:

Far tactical camera: Strike craft play a brief out-of-control death spiral, corkscrewing off their flight path with a thick smoke ribbon for roughly half a second before snapping in a sharp fireball (Homeworld 3 gameplay, observation). Capital ships and frigates use staged timing over several seconds: internal blasts ripple along the hull, engines and running lights die, a main core detonation fires a shockwave ring, and the ship splits into persistent 3D wreck chunks that stay in the battlespace as physical obstacles and cover (Homeworld 3 gameplay, observation).

Close camera: Capital ships swap from their intact mesh to pre-broken wreck variants split along authored seams (Homeworld 3 gameplay, observation) [UNVERIFIED]. The exposed break faces are capped with solid, dark, jagged bulkhead geometry and cooling slag shaders so every drifting chunk reads as solid industrial mass (Homeworld 3 gameplay, observation).

Sins of a Solar Empire 2

(a) Accumulating hull damage:

Far tactical camera: Accumulating hull damage is weak at the far camera and relies mostly on UI shield and hull bars, shield hit ripples, and a few looping fire and smoke particle emitters attached to hardpoints once hull integrity drops below set thresholds (Sins of a Solar Empire 2 gameplay, observation).

Close camera: Zooming in shows modest scorch shader overlays and localized fire particle loops on the outer skin while individual turrets continue tracking cleanly, with no geometric deformation of the hull (Sins of a Solar Empire 2 gameplay, observation).

(b) Breaches and internal damage:

Far tactical camera: Not visible at distance beyond general damage smoke emitters (Sins of a Solar Empire 2 gameplay, observation).

Close camera: The game does this weakly or not at all in 3D space (Sins of a Solar Empire 2 gameplay, observation). There are no cut-open hull breaches or modelled internal rooms during combat; internal damage is handled as a mechanical subsystem debuff in the UI rather than a visual cavity in the mesh (Sins of a Solar Empire 2 gameplay, observation).

(c) The kill and break-up:

Far tactical camera: Frigates pop in a quick fireball with a small debris burst, which can feel understated in large fleet scrums (Sins of a Solar Empire 2 gameplay, observation). Capital ships play a multi-second chain of surface flashes followed by a main shockwave ring and separation into several large drifting debris chunks that slowly sink and fade out (Sins of a Solar Empire 2 gameplay, observation).

Close camera: At the moment of death, the intact hull swaps to a set of pre-sliced rigid debris pieces pushed apart by radial impulse (Sins of a Solar Empire 2 gameplay, observation) [UNVERIFIED]. The cut faces of these chunks are sealed with simple flat or lightly bumpy dark charred caps and trailing fire emitters, avoiding a hollow-shell look by keeping the cross-section opaque and dark rather than modelling detailed interior decks (Sins of a Solar Empire 2 gameplay, observation) [UNVERIFIED].

Battlefleet Gothic: Armada 1

(a) Accumulating hull damage:

Far tactical camera: Damaged ships read strongly across the tactical plane because they trail thick black oil-smoke ribbons, vent bright plasma plumes, and sprout high-contrast orange deck fires along their dorsal spines and broadsides (Battlefleet Gothic: Armada 1 gameplay, observation).

Close camera: The hull material blends in heavy soot and burn masks tied to local health, while destroyed weapon batteries and subsystem nodes swap to blackened, mangled hardpoint meshes (Battlefleet Gothic: Armada 1 gameplay, observation) [UNVERIFIED].

(b) Breaches and internal damage:

Far tactical camera: Critical hits and breaches read through sudden geysers of fire and floating subsystem-destruction icons rather than visible holes (Battlefleet Gothic: Armada 1 gameplay, observation).

Close camera: Breaches use projected crater decals combined with emissive magma-orange crack masks and continuous spark/smoke venting (Battlefleet Gothic: Armada 1 gameplay, observation). There are no multi-deck 3D room interiors cut into the mesh; the crater interior is painted pitch-black with glowing orange fissures, which tricks the eye into seeing deep charred armour without ever opening the single-skin mesh (Battlefleet Gothic: Armada 1 gameplay, observation).

(c) The kill and break-up:

Far tactical camera: Kills use theatrical staged timing and persistent wrecks (Battlefleet Gothic: Armada 1 gameplay, observation). A dying cruiser shudders through a chain of secondary blasts running down its keel for two to three seconds, loses steering, and either settles into a blackened, burning intact derelict that drifts across the map as a ramming hazard or cracks in half in a plasma fireball (Battlefleet Gothic: Armada 1 gameplay, observation).

Close camera: When a ship breaks apart, it splits along authored fracture seams into two or three massive hulk sections with solid, jagged, soot-blackened cap geometry and glowing molten edges that slowly dim (Battlefleet Gothic: Armada 1 gameplay, observation) [UNVERIFIED].

Battlefleet Gothic: Armada 2

(a) Accumulating hull damage:

Far tactical camera: Because the sequel pulls the tactical camera further back to fit larger fleets, accumulating damage relies on brighter orange fire plumes, long black smoke trails, and UI status badges above the ship (Battlefleet Gothic: Armada 2 gameplay, observation).

Close camera: A progressive damage shader spreads blackened scorch masks and glowing red-orange hull cracks across damaged zones, supplemented by localized fire and spark emitters on crippled turrets (Battlefleet Gothic: Armada 2 gameplay, observation) [UNVERIFIED].

(b) Breaches and internal damage:

Far tactical camera: Read only through venting fire plumes and critical-hit UI callouts (Battlefleet Gothic: Armada 2 gameplay, observation).

Close camera: Like the first game, it avoids 3D room geometry inside breaches and instead uses high-contrast dark scorch decals with deep normal-mapped craters and bright molten fissure emissives (Battlefleet Gothic: Armada 2 gameplay, observation). Because the crater floor is completely opaque and black around the embers, it never exposes the inside of the mesh shell (Battlefleet Gothic: Armada 2 gameplay, observation).

(c) The kill and break-up:

Far tactical camera: Kills read clearly at extreme zoom via faction-coloured core detonations (blue-white Imperial plasma, green Necron gauss, bio-acid bursts for Tyranids), an expanding shock ring, and a persistent drifting wreck hulk that remains on the battlefield (Battlefleet Gothic: Armada 2 gameplay, observation).

Close camera: Pre-broken wreck sections separate along authored cuts with dark, solid-capped cross-sections, while smaller secondary explosions continue popping along the broken spine for several seconds after the main split (Battlefleet Gothic: Armada 2 gameplay, observation) [UNVERIFIED].

Star Wars: Squadrons

(a) Accumulating hull damage:

Far tactical camera (500m to 2,000m combat range): Damaged starfighters trail thick black smoke and stuttering blue ion sparks that visibly alter their flight trace, while damaged capital ships send up huge localized fire plumes and electrical arcs over crippled subsystems (Star Wars: Squadrons gameplay, observation).

Close camera (close dogfight pass and kill camera): Laser hits stamp persistent directional scorch decals that cool from bright orange to soot black along the hull skin, paired with localized spark emitters and sputtering cockpit or hull fires (Star Wars: Squadrons gameplay, observation).

(b) Breaches and internal damage:

Far tactical camera: Breaches on capital ships read as large glowing orange cavities pouring thick black smoke plumes into space (Star Wars: Squadrons gameplay, observation).

Close camera: On starfighters, breaches are surface decals and spark emitters only (Star Wars: Squadrons gameplay, observation). On capital ships and flagships, destroyed weak points and hull breaches swap an outer hull panel for a pre-authored recessed interior box mesh packed with dark pipes, structural girders, flickering fire sprites, and heavy black smoke, backed by a solid dark inner wall so no skybox ever leaks through (Star Wars: Squadrons gameplay, observation) [UNVERIFIED].

(c) The kill and break-up:

Far tactical camera: This game is a benchmark for making small-ship deaths read at distance without giant flashes (Star Wars: Squadrons gameplay, observation). A killed starfighter rarely pops on the spot: instead, it enters a 0.5 to 1.5 second death spiral, snapping into a violent roll or yaw corkscrew off its trajectory while painting a thick helical ribbon of black smoke and fire across space before detonating into three or four distinct spinning wing and fuselage pieces (Star Wars: Squadrons gameplay, observation). Capital ships die in a long staged sequence where chained internal blasts walk the hull, running lights die, and the ship lists heavily before splitting (Star Wars: Squadrons gameplay, observation).

Close camera: The kill camera follows the spiraling fighter as a wing tears off at an authored joint emitting sparks and flame, then watches the fuselage explode into solid, dark-capped debris pieces (Star Wars: Squadrons gameplay, observation) [UNVERIFIED].

EVE Online

(a) Accumulating hull damage:

Far tactical camera: At standard fleet-fight zoom where ships are tiny silhouettes or tactical brackets, accumulating mesh damage is barely visible; readability comes from shield/armour impact flashes, smoke trails on larger hulls, and UI brackets (EVE Online gameplay, observation).

Close camera: CCP's V5++ shader pipeline uses a multi-layer procedural damage shader across shield, armour, and hull structure states (CCP Games dev blog on ship damage and explosions, developer blog). As armour and structure drop, the shader peels back the outer paint and armour texture to reveal a dark, recessed under-layer of charred metal and glowing orange ember spots using parallax depth offsets rather than extra geometry (CCP Games dev blog, developer blog) [UNVERIFIED].

(b) Breaches and internal damage:

Far tactical camera: Not visible at tactical range (EVE Online gameplay, observation).

Close camera: Handled entirely inside the hull shader and particle system with zero cut-in 3D compartment geometry (EVE Online gameplay, observation). Because the revealed under-structure texture is pitch-black with high-contrast ember flecks and a darkened ambient-occlusion rim around the peeled armour edge, it convinces the eye that a solid, burnt core sits underneath the skin (EVE Online gameplay, observation).

(c) The kill and break-up:

Far tactical camera: Deaths follow a strict multi-stage rhythm scaled by hull class: rapid internal flashes ripple beneath the skin, the ship's emissive windows and thrusters shut off, and a final core shockwave flash leaves behind a persistent wreck icon and 3D wreck silhouette (EVE Online gameplay, observation).

Close camera: During the peak of the core explosion flash, the client swaps the intact ship mesh for a bespoke pre-authored wreck model (twisted, blackened, solid hulk geometry) while spawning secondary tumbling debris pieces and lingering gas clouds (CCP Games dev blog on ship damage and explosions, developer blog) [UNVERIFIED].

Nebulous: Fleet Command

(a) Accumulating hull damage:

Far tactical camera: At tactical zoom, ships are small silhouettes framed by incoming tracer lines, bright impact spark showers, and long dark smoke plumes trailing from damaged sections (Nebulous: Fleet Command gameplay, observation).

Close camera: Every penetrating shell or beam stamps a projected damage decal onto the hull mesh: a jagged dark hole or scorch patch with an emissive orange-white core that cools over time to a pitch-black crater, paired with venting gas or fire particles (Nebulous: Fleet Command devlog, developer blog) [UNVERIFIED].

(b) Breaches and internal damage:

Far tactical camera: Not directly visible on the exterior mesh; players read internal state via UI status or the tactical X-ray view (Nebulous: Fleet Command gameplay, observation).

Close camera: Despite having the deepest compartment-by-compartment damage simulation in space tactics, the game does not cut 3D geometric holes into the hull mesh or render literal room decks and ceilings inside craters (Nebulous: Fleet Command gameplay, observation). Exterior breaches are purely opaque black-and-ember decals on the hull skin, while players who want to inspect internal rooms toggle an X-ray wireframe overlay showing colour-coded compartment boxes inside the hull (Nebulous: Fleet Command gameplay, observation). This proves a vital design lesson: opaque black decals look more solid on a single-skin mesh than cutting open the shell.

(c) The kill and break-up:

Far tactical camera: Many kills are quiet mission-kills where a ship's thrusters, sensors, and running lights go completely dark, leaving a dead, smoke-trailing hulk drifting on its last vector (Nebulous: Fleet Command gameplay, observation). Magazine or reactor kills trigger a sharp flash and an expanding grey-white dust and shrapnel ring that reads cleanly against dark space (Nebulous: Fleet Command gameplay, observation).

Close camera: A dead ship either stays in one blackened piece covered in crater decals and venting atmosphere, or splits into large pre-defined hull chunks with dark, opaque cross-sections upon reactor detonation (Nebulous: Fleet Command gameplay, observation) [UNVERIFIED].

Highfleet

(a) Accumulating hull damage:

Far tactical camera (full-screen 2D combat view): Accumulating damage reads with extraordinary clarity across the whole screen through thick, rising columns of black oil smoke, roaring orange fuel fires, cascading spark showers, and chunks physically missing from the ship's silhouette (Highfleet gameplay, observation).

Close camera (zoomed combat and repair dock view): Because ships are assembled from discrete 2D structural, armour, fuel, and weapon tiles, damaged areas show blackened soot sprites over adjacent intact blocks and bent or missing frame struts (Highfleet gameplay, observation).

(b) Breaches and internal damage:

Far tactical camera: Breaches read immediately as ragged bites out of the outer armour outline with fire and black smoke pouring from the interior cavity (Highfleet gameplay, observation).

Close camera: Blowing away outer armour blocks exposes the dark grey and soot-blackened internal skeleton lattice and machinery blocks underneath (Highfleet gameplay, observation). Because a dark backing chassis layer sits behind the foreground blocks, a breached ship never shows empty sky through its middle until the backing structure itself is pulverized (Highfleet gameplay, observation) [UNVERIFIED].

(c) The kill and break-up:

Far tactical camera: Small and medium ship kills are monumental even without screen-strobing flashes (Highfleet gameplay, observation). An ammo or fuel detonation shoots a long, high-velocity directional cone of shrapnel streaks and smoke ribbons across a third of the screen, kills thrust on one side so the burning wreck cartwheels violently off course, and breaks the hull into heavy tumbling chunks trailing dense black smoke lines (Highfleet gameplay, observation).

Close camera: Individual structural blocks and weapons shear off as physical rigid bodies trailing sparks and black smoke while secondary magazine pops continue inside the falling main carcass (Highfleet gameplay, observation).

2. What transfers to this game

Given the hard constraints of Embers of the Hollow Sun (Godot 4.7 Forward+, 36 ships baked as one AI-generated surface mesh per hull, no authored interiors or break seams, runtime generation only, 20 ships on screen, 40+ fps 1% low at 1080p on an RTX 5080 with 4K already near 40 fps, and an absolute limit of 3 large flashes per second), techniques from the reference games divide cleanly into what dies and what survives.

Techniques that die

Pre-broken wreck variants and splitting along authored seams (Homeworld 3, Armada 1 and 2, EVE Online, Squadrons): Dies immediately because there are 36 single-surface AI-generated meshes with no authored seams or separate wreck models, and everything must be generated at runtime.

Literal multi-room interior compartments with clean lit ceiling strips inside unbacked hull openings (current godot/fx/ pass): Dies conceptually. As Nebulous: Fleet Command, EVE Online, and Battlefleet Gothic: Armada demonstrate, cutting open a single-surface mesh and sticking lit room geometry inside without a pitch-black opaque backing cavity and watertight cross-section caps exposes the thin outer skin and makes the interior look like doll-house set dressing floating inside a hollow shell.

High-frequency chain-flash strobing on capital ship deaths: Dies under the hard photosensitivity rule of at most 3 counted large flashes per second and the reduce-flashing toggle. Staged deaths must be driven by thermal glow, power-down darkness, structural motion, and smoke/debris silhouettes rather than rapid bright flashes.

Heavy screen-space or per-ship real-time boolean CSG (CSGMesh3D) and hundreds of Decal nodes: In Godot 4.7 Forward+, runtime CSGMesh3D boolean subtraction on dense AI-generated meshes spikes CPU frame time by 5 to 20 ms per cut (causing severe hitches below 40 fps), and spawning dozens of Forward+ Decal nodes per ship adds clustered decal rendering overhead at 4K where frame budget is already tight.

Techniques that survive (and their Godot 4.7 implementation and cost)

Shader-driven dark cavity masking with parallax/recessed slag (fx_hull.gd and fx_breach.gd, from EVE Online and Homeworld 3):

Godot approach: A single custom ShaderMaterial on the hull mesh holding a small uniform ring-buffer array of hit spheres (uniform vec4 breach_spheres[16], storing local XYZ position and radius) plus a triplanar noise texture. Inside each sphere radius, the fragment shader darkens albedo to near-black soot (vec3(0.02)), writes a radial normal-map bevel at the rim, and uses view-ray parallax offset (depth_draw_opaque) to sample a dark charred girder/ember pattern recessed inward.

Cost: Roughly 0.03 ms GPU total across 20 ships at 4K, with zero extra draw calls or geometry allocation.

Opaque black backing hull shell + dark-first recessed breach pockets (fx_breach.gd, from Squadrons and Armada):

Godot approach: Where fx_breach.gd already generates procedural compartment geometry, wrap the compartment pocket in a closed, watertight, pitch-black opaque backing box (StandardMaterial3D with shading_mode = SHADING_MODE_UNSHADED, albedo_color = Color(0.01, 0.01, 0.01)) recessed behind the hull surface, and discard the outer hull shader pixels strictly inside the pocket mouth using the breach_spheres mask.

Cost: Less than 0.02 ms GPU per active breach; uses the existing procedural compartment budget.

Planar cross-section capping (SurfaceTool / ArrayMesh) on runtime mesh cuts (fx_death.gd, from Sins 2 and Armada):

Godot approach: When fx_death.gd splits the hull mesh along a cutting plane into Jolt RigidBody3D pieces, collect the boundary edge loop where the plane intersects the mesh triangles, triangulate that boundary loop into a flat or noise-displaced polygon cap (SurfaceTool), assign it a dark slag material, and set the hull piece material to cull_disabled with backface darkening in the fragment shader (if (!FRONT_FACING) { ALBEDO = vec3(0.02); ROUGHNESS = 1.0; }).

Cost: About 0.2 to 0.4 ms one-time CPU cost on the kill frame when slicing a ship, and 0.01 ms GPU per frame thereafter.

Death spirals and high-aspect-ratio debris streamer ribbons (fx_death.gd, from Squadrons and Highfleet):

Godot approach: Before detonating a small ship, apply an off-centre angular impulse (RigidBody3D.apply_torque_impulse) and linear lurch for 0.45 seconds while trailing a GPUParticles3D ribbon (RibbonTrailMesh with use_trails = true, unshaded dark smoke with a hot orange core at the head). On detonation, fire 3 to 5 fast directional RibbonTrailMesh shrapnel streamers outward to 5x the ship's bounding radius.

Cost: Under 0.04 ms GPU per dying ship using a single GPUParticles3D draw call with hardware trail meshes.

Multi-second staged capital death sequence with power-down and delayed split (fx_death.gd, from Homeworld 3, EVE Online, and Armada):

Godot approach: Use a coroutine/tween in fx_death.gd over 2.2 seconds: (Phase 1, 0.0s to 1.0s) flicker and extinguish hull emissives while erupting 3 localized venting jets along the future cut plane and rolling the ship 15 degrees; (Phase 2, 1.0s to 1.4s) draw a glowing thermal fracture line along the cut plane and split the hull into 2 primary Jolt RigidBody3D hulk sections that heave apart slowly; (Phase 3, 1.4s to 2.2s) detonate the single counted core flash and shock ring inside one section while the other section stays intact as a blackened drifting derelict.

Cost: Spreads CPU slicing work and GPU particle bursts across 130 frames instead of frame 0, keeping cost under 0.05 ms per frame and using only 1 counted flash over 2.2 seconds.

3. The three named problems
(a) A breach that shows a burnt interior rather than a surface mark

Why the current pass fails: The current fx_breach.gd generates compartments with decks, ceilings with light strips, frame ribs, red room lighting, and glowing cut edges, yet the player reports that a breach looks much the same before and after and reads as an empty shell when zoomed in. Two things cause this: first, placing compartment geometry onto or inside a single-surface mesh without discarding the outer hull pixels inside the breach mouth (or without sealing the back of the hole with an opaque pitch-black cavity box) either leaves the outer skin covering the hole so it looks like a surface sticker, or lets the camera see past the sparse ribs to the culled backfaces of the far hull wall (empty space). Second, lighting the breached compartments with clean ceiling light strips and bright red room lights flattens the depth contrast so the breach blends into the pre-breach hit glow instead of reading as a deep, charred hole punched into the ship.

Cheapest convincing method:

In fx_hull.gd and fx_breach.gd, pass each breach's local position and radius into the hull shader and call discard on outer hull pixels inside the inner 70% of the breach radius, while darkening the outer 30% collar to pitch-black soot (albedo = vec3(0.02)) with a steep inward normal bevel.

Behind that discarded opening, place an inverted, watertight opaque box or hemisphere cap (cull_front, unshaded Color(0.01, 0.01, 0.01)) recessed 1.5x the breach radius inside the hull so it is physically impossible to see through the ship to the stars or empty interior.

Inside that pitch-black recess, keep the existing generated deck plates and bent frame ribs, but turn off the clean ceiling light strips completely; colour all internal surfaces soot-black (Color(0.03, 0.03, 0.03)) and light them only from deep inside the back wall with a small dying orange ember shader pulse so the silhouettes of blackened, bent ribs stand out in dark relief against a recessed ember glow.

Why it fixes the exact complaint: Discard-cutting the outer hull skin plus sealing the cavity with an unshaded black backing box guarantees a real 3D hole with zero hollow shell bleed-through from any camera angle, while replacing bright ceiling strips with dark silhouetted ribs over a recessed ember floor creates an unmistakable before-and-after change from intact armour to a deep, burnt-out cavity.

(b) A break-up whose pieces read as solid, not shell

Why the current pass fails: When a ship explodes, fx_death.gd breaks the single surface mesh into Jolt physics pieces and populates openings with generated decks, ceilings, and bulkheads, yet the player immediately sees that "it's just empty inside so it's clearly a shell". When a single-sided outer hull mesh is sliced into fragments, each fragment is an open curved sheet of triangles with backface culling enabled (cull_back). Adding flat deck planes or ribs inside that curved sheet does not fill the volume: as the piece tumbles in zero gravity, the camera looks past the decks or at the underside of the outer skin and sees straight through the invisible backfaces to the background skybox, exposing the paper-thin shell.

Cheapest convincing method:

In fx_death.gd, when slicing or fracturing the hull mesh into Jolt RigidBody3D pieces, generate a watertight Planar Slag Cap across 100% of every cut cross-section using SurfaceTool: take all cut-plane intersection vertices, triangulate the closed cross-section polygon, displace interior vertices slightly with 3D noise so the break face looks uneven and jagged, and assign a matte dark slag material (albedo = Color(0.03, 0.03, 0.03), roughness = 0.95, with cooling orange ember veins driven by a 3D noise shader).

On the hull material of every broken piece, enable two-sided rendering (cull_disabled) and add one line to the fragment shader: if (!FRONT_FACING) { ALBEDO = vec3(0.02); METALLIC = 0.2; ROUGHNESS = 0.95; EMISSION = vec3(0.0); }. Even if a small gap exists in a complex concave cut, the inner wall of the hull skin renders as solid pitch-black iron rather than invisible air.

Layer the existing generated bulkhead ribs and torn deck edges so they protrude 0.2 to 0.5 metres outward from the solid Planar Slag Cap rather than floating inside an open cavity, and cut off all intact white ceiling light strips on broken debris pieces.

Why it fixes the exact complaint: Every tumbling piece is now a closed, opaque solid polyhedron whose cut face is completely sealed by dark, jagged metal and protruding structural ribs, making it geometrically impossible for the camera to ever see an empty hollow shell.

(c) A small-ship kill that reads from the far battle camera

Why the current pass fails: Currently, fx_death.gd scales the kill core flash and shock ring by ship class. At the far tactical camera where players spend most of their time, a small ship covers only a tiny cluster of pixels, so a class-scaled flash and shock ring is physically small and lasts only a fraction of a second, reading as "a small pop at the battle camera". Simply making the flash giant would blur ship-class hierarchy and risk tripping the 3-flashes-per-second photosensitivity limit.

Cheapest convincing method:

Borrow the Death Spiral + High-Aspect Shrapnel Cross from Star Wars: Squadrons and Highfleet: when a small ship is killed in fx_death.gd, delay the final break-up by 0.45 seconds. During those 0.45 seconds, apply a sharp off-axis Jolt impulse and roll torque so the ship snaps 2 to 3 ship-lengths off its hex centre in a violent corkscrew spin while emitting a thick, high-contrast smoke-and-ember ribbon trail (GPUParticles3D with RibbonTrailMesh).

When it detonates at the end of the 0.45-second spiral, instead of relying on a small spherical pop, fire 4 fast directional shrapnel streamer ribbons (RibbonTrailMesh, bright orange tips fading into persistent dark grey smoke lines) shooting asymmetrically outward to 5x the ship's hull length in screen space, creating a spiky starburst silhouette that is wide on screen without being a bright area flash.

Leave the largest spinning hull chunk drifting and trailing a thin dark smoke plume for 4 seconds so the hex visually registers a dead wreck after the burst clears.

Why it fixes the exact complaint: Human peripheral vision at a far tactical camera detects sudden motion off the grid (the 0.45s corkscrew lurch) and long linear spikes (the 5x radius shrapnel ribbons) far better than a tiny spherical flash, turning a forgettable pop into a kinetic kill sequence while adding zero counted large flashes to the photosensitivity budget.

How big-ship staged break-up ties in (bonus fix for Failure 2)

To fix the second named failure ("A big ship's death is one fireball; there is no staged break-up"), fx_death.gd should stop firing the core flash, shock ring, and full piece shatter simultaneously at t = 0.0. Instead, sequence a capital kill across 2.2 seconds:

0.0s to 0.9s: Ship shudders in place, running lights and engine glow die to black, and 3 directional plasma blow-out jets erupt along the primary waist cut plane.

0.9s to 1.4s: A bright orange thermal crack line draws across the waist cut plane; the hull slices into just two massive Jolt hulk sections (each capped with the solid Planar Slag Cap above) that heave apart by 15 degrees with venting gas.

1.4s to 2.2s: The reactor inside one hulk section detonates (using the single class-scaled core flash and shock ring, or a non-flashing thermal wave when reduce-flashing is active), shattering that half into smaller burning pieces while the other massive half remains intact as a drifting, blackened hulk.

4. Your ranked plan

Seal all break-up cut planes and backfaces (godot/fx/fx_death.gd, godot/fx/fx_hull.gd): Generate a triangulated, noise-displaced dark Planar Slag Cap (SurfaceTool) across every runtime mesh slice, set piece materials to cull_disabled with pitch-black backface shading in the fragment shader, and turn off white ceiling light strips on broken pieces. The player immediately stops seeing through hollow shells when ships explode close up; every tumbling chunk reads as solid, heavy, jagged metal with ribs sticking out of a sealed dark core.

Punch real shader holes and add opaque black backing cavities to breaches (godot/fx/fx_breach.gd, godot/fx/fx_hull.gd): Pass breach spheres to fx_hull.gd to discard outer hull pixels inside the crater mouth with a blackened soot rim, place a closed unshaded pitch-black backing box behind the opening in fx_breach.gd, and replace clean ceiling light strips with dark soot-stained ribs silhouetted against a recessed dying-ember back wall. Zooming in on a damaged ship now reveals deep, charred holes punched into dark smoking guts rather than flat surface decals or empty shells.

Add the 0.45s death spiral and 5x shrapnel ribbon cross to small-ship kills (godot/fx/fx_death.gd): On small-ship deaths, apply a 0.45-second off-axis Jolt torque/linear lurch with a corkscrew smoke-and-fire RibbonTrailMesh before detonation, then fire 4 long asymmetric shrapnel streamer ribbons out to 5x hull length. At the far tactical camera, small ships no longer vanish in a tiny pop; they violently veer out of formation and burst into a wide, spiky shrapnel cross that reads across the whole battlefield without adding bright flashes.

Sequence big-ship deaths into a 3-phase split over 2.2 seconds (godot/fx/fx_death.gd): Replace the single-frame capital fireball with a 2.2-second sequence: a 0.9s power-down and seam-venting phase, a 0.5s primary split into two massive capped hulk halves along a glowing thermal seam, and a delayed reactor detonation at 1.4s that shatters one half while leaving the other half drifting as a dark wreck. Big ship kills transform from a single instant fireball into a heavy, cinematic break-up where the player watches the hull crack in two before the core blows.

Kill emissive running lights and engine glow progressively on damaged and dying hulls (godot/fx/fx_hull.gd, godot/fx/fx_death.gd): Modulate the ship's emissive texture channel downward in fx_hull.gd around breached zones, and flicker then extinguish all ship lights and thruster flares during the opening 0.8 seconds of fx_death.gd. The player sees crippled sections and dying hulls visibly lose power and go dark, making internal ember fires and venting plasma stand out sharply at both far and close camera distances.

Add persistent dark smoke ribbons and hull soot accumulation (godot/fx/fx_hull.gd): Blend a cumulative world-space soot/scorch mask across the hull shader as HP drops and attach 1 to 2 low-cost unshaded dark smoke RibbonTrailMesh emitters to major breaches that persist across turns. At the far tactical camera, the player can read which ships are badly mauled at a glance without checking health bars, and damaged ships look battle-worn before they ever break apart.
