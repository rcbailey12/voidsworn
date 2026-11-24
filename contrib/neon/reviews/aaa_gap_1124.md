# Embers of the Hollow Sun: AAA Gap Audit (Neon)

Date: Nov 24, 2026
Repo head checked: `main` (`f3437dc83`), open GitHub issues (63), open pull requests (35), `docs/RULEBOOK.md`, `.claude/rules/` (`ships.md`, `godot-battle.md`, `godot-ui.md`), `contrib/opus/FINDINGS.md`, `contrib/opus/LOOP.md`, `docs/playbooks/PROGRAM.md`, `docs/playbooks/factions.md`, `docs/playbooks/screens.md`, `docs/playbooks/sound.md`, `docs/ship_pipeline/FLEET.md`, real game stills, video clips, and audio assets in `docs/shots/` and `godot/audio/`, and live Godot source code.
Benchmarks: BattleTech, Sins of a Solar Empire II, Battlefleet Gothic: Armada, EVE Online.

**Bottom line:** The game already has an AAA backbone in its six distinct ship factions, plan-then-commit hex turns, clean editorial debrief and fleet screens (`DB1`, `FL5`, `CR4`), and the new Gate 2 weapon and death sound effects. What still separates it from BattleTech, Sins of a Solar Empire II, Battlefleet Gothic: Armada, and EVE Online is **in-battle tactical readability, dynamic presentation in motion, and between-battle dockyard craft**: no directional shield or hull-section schematic on the HUD, bare wireframe weapon arcs with no live aim sightlines, silent text-only fleet comms buried in the log, a text-spreadsheet Shipyard with no 3D bay, zoomed-out letterboxed cut-ins, an already-built called-shot system hidden from players and AI, single-layer beam/plume/shield effects, a bare double-titled post-battle modal, no pre-battle formation setup, and flat unpooled spatial audio.

---

## 1. Top 10 Gaps (Ranked by Impact on AAA Quality)

### 1. No Directional Shield Quadrant or 3-Section Hull Schematic on the Battle HUD
- **Area:** UI/UX
- **What a player sees today:** In `docs/shots/issue-1021-openai/keel_target_1080.png`, `docs/shots/player_path_1119/navy-b1.jpg` (00:55.4), `docs/shots/player_path_1119/hullbreakers-b2.jpg` (00:27.9), `docs/shots/undo_1450/UNDO-1_after_move.jpg`, and `godot/ui/battle/ledger.gd`, the KEEL bottom shelf shows a flat solid-white ship silhouette above one flat Shield bar and one flat Hull bar. Even though the rules track 4 directional shield facings with power routing (`godot/rules/rules.gd:309, 3301-3328`) and 3 destructible hull sections (prow, mid, engines) that disable specific guns or drives, players have to read hover prose to tell which side is exposed, routed, or broken. Planned `#1741` adds 3D hull wounds on the ship mesh, but no open issue adds a live directional schematic to the ship or target HUD.
- **What the benchmark game does:** **BattleTech** shows an unmistakable Mech paper-doll for both your unit and target with per-location armor and internal structure health; **Battlefleet Gothic: Armada** and **EVE Online** wrap directional shield arcs and subsystem state directly around the ship display.
- **Fix:** Replace the flat white KEEL silhouette (and add a matching mini-schematic in the target block) with a clean orders-sheet top-down hull diagram that tints the 3 hull sections by health and wraps 4 Glacier shield arc segments showing live coverage, routed sides, and open gaps.
- **Size:** M (2 to 4 runs: view-model binding, schematic renderer in `ledger.gd`, target-block twin, HUD readability checks)
- **Confidence:** OBSERVED (`keel_target_1080.png`, `navy-b1.jpg`, `hullbreakers-b2.jpg`, `UNDO-1_after_move.jpg`, `godot/ui/battle/ledger.gd`)

### 2. No Live Firing Sightlines, Flat Wireframe Arcs, and Prose-Wall Hover Tooltips
- **Area:** UI/UX
- **What a player sees today:** In `docs/shots/player_path_1119/navy-b1-p01.mp4` (00:08 to 00:44), `docs/shots/player_path_1119/hullbreakers-b2.jpg` (00:27.9, 01:10.8), `docs/shots/issue-1021-openai/keel_target_1080.png`, and `docs/shots/1359/pc/boneyard_graveyard_1359_1_cine_no_hover_c170.jpg`, weapon arcs draw as giant flat beige wireframe loops across half the board (`godot/scenes/battle/battle.gd:3505-3535` uses a barely visible `0.045` alpha fill), planning a move draws zero sightlines from the move ghost to targets, and hovering a hex or enemy pops a 6-to-8-line black prose paragraph right over the ships. Planned `#1401` cleans up button/hover wording and `#1991` fixes blocker outlines, but neither adds firing sightlines, soft shaded range cones, or compact visual hover cards.
- **What the benchmark game does:** **BattleTech** projects color-coded firing sightlines straight from the move ghost to every in-arc enemy (clear, obstructed, rear-arc) before you commit; **Battlefleet Gothic: Armada** renders soft gradient-shaded firing cones with distinct optimal vs max range bands and crisp lock-on reticles.
- **Fix:** Draw crisp color-coded sightlines from the move ghost to eligible or aimed targets (showing clear, nebula/debris-obscured, and rear-arc shots), upgrade flat wireframe arcs into soft optimal/max gradient cones, and replace prose hover paragraphs with compact icon-and-bar tactical cards.
- **Size:** M (2 to 4 runs: 3D sightline and shaded-arc renderer in `battle.gd`, structured hover card in `hud.gd`, visual checks)
- **Confidence:** OBSERVED (`navy-b1-p01.mp4`, `hullbreakers-b2.jpg`, `keel_target_1080.png`, `boneyard_graveyard_1359_1_cine_no_hover_c170.jpg`, `godot/scenes/battle/battle.gd:3505-3535`)

### 3. Silent, Buried Fleet Comms With No Portrait Transmission Banner or Vox Telemetry
- **Area:** UI/UX / Sound and Music / Presentation
- **What a player sees today:** In `docs/shots/player_path_1119/navy-b1-p01.mp4` (00:06 to 00:47), `docs/shots/issue-1021-openai/keel_target_1080.png`, and `godot/story/battle_voice.gd`, Admiral Roderic Vex, enemy flagships, and Nemesis commanders speak only as tiny grey truncated lines inside the bottom-right `Log` box (`Fleet Marshal Petra Valk: "Every move you can make has been planne...`). There is no speaker portrait transmission toast, no radio squelch or vox click, and no audible reaction when ships accept orders, lose a shield, or kill a capital. Planned `#1990` expands written hail text and `#1897` draws new portraits, while R37 keeps the 3-beat story text-only, but no open issue brings battle comms out of the log box with portrait banners and radio audio cues.
- **What the benchmark game does:** **BattleTech** pairs orders, breaches, and enemy taunts with a crisp non-blocking portrait comm banner and radio static squelch; **Battlefleet Gothic: Armada** sells flagship scale with unmistakable vox transmission callouts on critical battle beats.
- **Fix:** Add a brief, non-blocking portrait comm banner (using the new `#1897` portraits + short 1-line subtitle + faction-tuned radio squelch/vox telemetry click) for flagship hails, Admiral Commands, section losses, and Nemesis taunts; keep story beats text-only per R37, and optionally test short radio-filtered combat barks only if Ryan asks for voiced callouts later.
- **Size:** M (2 to 4 runs for portrait comm banner + faction vox/telemetry SFX; L if optional voiced battle barks are later approved)
- **Confidence:** OBSERVED (`navy-b1-p01.mp4`, `keel_target_1080.png`, `godot/story/battle_voice.gd`)

### 4. Shipyard Is a Text Spreadsheet With No Live 3D Dockyard Bay or Stat-Delta Preview
- **Area:** UI/UX / Progression
- **What a player sees today:** In `docs/shots/late_run_1178/L1178_late_market.png`, `docs/shots/chorus_biomass_1484/CHO-1_chorus_late_market.png`, and `godot/ui/campaign/campaign_ui.gd`, the Shipyard is a flat vertical stack of dark text cards with zero ship models, a cramped `Refits` button wedged beside the CP counter, and zero visual stat-delta bars when comparing a Mark upgrade, refit, or new hull. The game already renders crisp live 3D ships on the Flagship Aspect screen (`godot/ui/campaign/flagship_podium.gd`) and Fleet Manifest (`docs/shots/ui/fleet_fl5/FL5_1080.jpg`), yet the Shipyard where players spend their run's money shows none of it. No open issue redesigns the Shipyard.
- **What the benchmark game does:** **BattleTech** (the Argo MechBay) and **EVE Online** (the Fitting Window) center a live rotating 3D model of your ship while you repair, refit, and shop, with instant green/red stat delta bars on hover.
- **Fix:** Rebuild the Shipyard around a live interactive 3D dockyard bay (reusing `flagship_podium.gd` / `fleet_portrait.gd` with orbit and zoom) for the selected or hovered ship, paired with weapon icons and live green/red stat delta previews when hovering Mark upgrades, refits, or hulls for sale.
- **Size:** M (2 to 4 runs: split dockyard layout in `campaign_ui.gd`, reusable 3D bay view, hover-delta preview logic, UI checks)
- **Confidence:** OBSERVED (`L1178_late_market.png`, `CHO-1_chorus_late_market.png`, `FL5_1080.jpg`, `godot/ui/campaign/campaign_ui.gd`, `godot/ui/campaign/flagship_podium.gd`)

### 5. Combat Cut-Ins Are Zoomed-Out Letterboxed Board Shots Instead of Dynamic Action Cameras
- **Area:** Physics and Motion / Camera
- **What a player sees today:** In `docs/shots/player_path_1119/navy-b1-p01.mp4` (00:37), `docs/shots/player_path_1119/navy-b1.jpg` (00:37.3), `docs/shots/player_path_1119/hullbreakers-b3.jpg` (00:18.8), and `godot/scenes/battle/battle.gd:2370-2404`, `_cine_frame()` adds letterbox bars to a single wide midpoint side-on angle that leaves both ships tiny on opposite edges of the frame, leaves hex grids, rings, and floating text visible underneath, holds for less than a second, and snaps abruptly back. Planned `#1404` cleans up HUD overlap and enemy visibility, and `#1779` adds opt-in kill-cam DoF, but neither replaces the single static side shot with multi-angle combat camera choreography.
- **What the benchmark game does:** **BattleTech** shoots major attacks from low over-the-shoulder angles that track salvos into a tight impact close-up with all tactical grid chrome hidden; **Battlefleet Gothic: Armada** frames broadsides and torpedo runs from dramatic low hull-skimming angles that make ships feel colossal.
- **Fix:** Replace the single midpoint cut-in with 3 choreographed action presets (low over-the-shoulder broadside, nose-to-target lance/torpedo chase, and tight impact hold), fade out hex grids, rings, and tooltips during cut-ins, and smoothly ease back to the tactical camera on release.
- **Size:** M (2 to 4 runs: multi-angle camera choreography in `battle.gd` and `camera_rig.gd`, tactical chrome fade, player-path clip proof)
- **Confidence:** OBSERVED (`navy-b1-p01.mp4`, `navy-b1.jpg`, `hullbreakers-b3.jpg`, `godot/scenes/battle/battle.gd:2370-2404`)

### 6. Subsystem Targeting (Called Shots) Is Built Into the Rules Engine but Hidden From Players and AI
- **Area:** Tactical Depth and AI
- **What a player sees today:** `godot/rules/rules.gd:3384, 3424-3473, 3835-4070` already implements full 3-section damage (prow silences forward guns, mid kills broadsides and shield generator, engines cripple speed, turns, and evasion) AND a `called` shot mechanic (`+15` crit, routes damage to the chosen section, forces system damage). Yet `godot/scenes/battle/battle.gd` has zero player UI or command path for called shots, and `aiVolley` hardcodes `{"called": null}` (`godot/rules/rules.gd:7650`). Players cannot intentionally shoot out an escaping Hunt flagship's engines or a dreadnought's shield generator. No open issue exposes this system.
- **What the benchmark game does:** **Battlefleet Gothic: Armada** makes Priority Subsystem Targeting (Engines, Generators, Weapons, Deck) the core tactical decision of every ship duel; **BattleTech** lets players spend resolve on Precision Strikes to surgically cripple dangerous weapons or legs.
- **Fix:** Expose a clean 3-button Priority Target toggle (Weapons / Midship & Shields / Engines) in the plan-commit target bar with a balanced trade-off (modest aim penalty or per-ship cooldown), and teach Veteran AI to target engines on runners and weapons on top threats.
- **Size:** M (2 to 4 runs: rules cost/balance tuning + saved-results update, KEEL selector UI, Veteran AI logic, tests)
- **Confidence:** INFERRED (`godot/rules/rules.gd:3835-4070, 7650`; zero called-shot UI references in `godot/scenes/battle/battle.gd`)

### 7. Single-Layer Lance Beams, Flat Stretched Engine Plumes, and Full-Hull Uniform Shield Flashes
- **Area:** Effects / Graphics
- **What a player sees today:** In `docs/shots/look_bench/kit/round3/lance.png`, `docs/shots/player_path_1119/navy-b1-p01.mp4` (00:37), `docs/shots/battle_baseline_1118/BATTLE1076_storm_01.jpg`, and `docs/shots/battle_baseline_1118/BATTLE1076_IM5_c170_standard.jpg`, lance beams draw as single soft solid bars without layered hot cores, crackling energy sheaths, or muzzle charge-up; engine plumes behind capital bells look like flat blurred horizontal stripes; and a `Fitted shield hit` lights up the entire ship's hex-grid shell uniformly instead of blooming tightly around the impact point. Planned `#1778` upgrades hull PBR paint and `#2018` upgrades sparks, but no open issue upgrades beam shaders, volumetric engine plumes, or localized shield hit ripples.
- **What the benchmark game does:** **EVE Online** sells massive sci-fi energy with volumetric mach-diamond engine cones, multi-layer beams, and tight expanding impact ripples on shields; **Sins of a Solar Empire II** pairs razor-bright beam cores with energy jackets and clear muzzle charge telegraphs.
- **Fix:** Upgrade weapon beam and engine shaders in `fx_weapons.gd`/`fx_shaders.gd` to layer bright cores, animated energy sheaths, muzzle charge-up, and volumetric throttle-reactive engine cones, and tighten shield-hit falloff so impacts ripple outward from the exact hit point rather than flashing the entire hull evenly.
- **Size:** L (5 or more runs: beam shader pass, volumetric engine plume pass, localized shield ripple shader, look-bench captures across factions)
- **Confidence:** OBSERVED (`lance.png`, `navy-b1-p01.mp4`, `BATTLE1076_storm_01.jpg`, `BATTLE1076_IM5_c170_standard.jpg`)

### 8. Bare Post-Battle Victory Popup With Duplicate Title and Zero Per-Ship Combat Breakdown
- **Area:** UI/UX / Progression
- **What a player sees today:** In `docs/shots/player_path_1119/navy-b1.jpg` (02:59.3), `docs/shots/player_path_1119/navy-b2.jpg` (01:22.7), `docs/shots/player_path_1119/hullbreakers-b1.jpg` (01:36.8), `docs/shots/player_path_1119/hullbreakers-b3.jpg` (02:12.7), and `godot/scenes/battle/battle.gd:3214`, winning a battle stacks a floating orange `VICTORY` banner directly above a plain black box that prints `VICTORY` a second time, with just two summary lines and a `Continue` button. Players get no per-ship breakdown of damage dealt, kills, damage absorbed, captain XP gained, or battle MVP (while `DB1` only runs at end-of-run, and PR `#1962` only updated cause lines and button labels).
- **What the benchmark game does:** **BattleTech** opens a crisp Mission Action Report showing every unit's kills, damage dealt, hull/armor lost, and pilot XP earned before salvage; **Sins of a Solar Empire II** and **Battlefleet Gothic: Armada** present a clean per-ship performance ledger after every engagement.
- **Fix:** Remove the duplicate `VICTORY` banner and upgrade `hud.show_end()` into a compact orders-sheet After-Action Report listing each ship's kills, damage dealt, hull/shield damage taken, captain XP bar, and battle MVP before moving into salvage and rewards.
- **Size:** S to M (1 to 2 runs: per-ship combat tally in `rules.gd`/`battle.gd`, KEEL-styled summary card in `hud.gd`, UI checks)
- **Confidence:** OBSERVED (`navy-b1.jpg`, `navy-b2.jpg`, `hullbreakers-b1.jpg`, `hullbreakers-b3.jpg`, `godot/scenes/battle/battle.gd:3214`)

### 9. No Pre-Battle Tactical Deployment or Formation Setup Phase
- **Area:** Tactical Depth and AI
- **What a player sees today:** In `docs/shots/map_eval_1118/ME-BOSS1-ROUT.png` and `godot/scenes/battle/battle.gd:491`, `interactive_deployment` only prompts for pre-battle admiral tree skill picks. Every fleet spawns in a fixed auto-placed formation with no way to put brawlers in front, tuck carriers behind asteroid cover, angle broadside cruisers, or counter an ambush setup before Round 1 starts. No open issue adds pre-battle placement.
- **What the benchmark game does:** **Battlefleet Gothic: Armada** gives every fight a fast pre-battle deployment zone to arrange escorts, capitals, and carriers around gas clouds and rocks; **Sins of a Solar Empire II** offers explicit fleet formation roles (vanguard, line, support, carrier).
- **Fix:** Add a fast optional pre-battle deployment step (with a one-click "Launch Battle" default using today's smart layout) that highlights friendly deployment hexes so players can swap ship positions and starting facings before Round 1 begins.
- **Size:** M (2 to 4 runs: rules pre-round swap/facing action, deployment zone overlay in `battle.gd`, saved-results and bot compatibility)
- **Confidence:** OBSERVED and INFERRED (`ME-BOSS1-ROUT.png`, `godot/scenes/battle/battle.gd:491`)

### 10. Flat Spatial Audio Mix: Disabled 3D Attenuation, Unpooled Voices, and One Ambient Bed Across All Biomes
- **Area:** Sound and Music / Performance
- **What a player sees today:** In `godot/audio/sfx.gd:152-167, 336-400`, every 3D sound explicitly disables native distance attenuation (`ATTENUATION_DISABLED`), compresses distance into a flat `0.5..1.0` volume clamp, shares one fixed reverb effect across all buses, instantiates and frees new `AudioStreamPlayer3D` nodes on every shot, and plays the same static ambient bridge bed regardless of whether the battle sits beside the Hollow Sun, inside an ion storm, or in a rose nebula. Planned `#1752` Gate 3 adds a slow-mo low-pass filter and 4-stem adaptive battle music, and `#1995` caches catalog loading, but no open issue adds zoom-reactive audio depth, biome soundscapes, or audio node pooling.
- **What the benchmark game does:** **EVE Online** shifts the mix dynamically with camera zoom (crisp mechanical hull, turret, and capacitor detail up close; deep weighty rumble zoomed out); **Sins of a Solar Empire II** layers distinct environmental soundscapes for stars, storms, and nebulae.
- **Fix:** Pool `AudioStreamPlayer` and `AudioStreamPlayer3D` voices in `sfx.gd`, couple a subtle bus EQ/presence curve and distance falloff to camera zoom radius `cam._cr`, and add 3 low-level biome ambient beds (Hollow Sun gravity rumble, ion storm crackle, nebula hum) that duck cleanly under combat peaks.
- **Size:** M (2 to 4 runs: voice pooling and zoom-reactive spatial mix in `sfx.gd`, 3 biome ambient beds, audio soak test)
- **Confidence:** OBSERVED and INFERRED (`navy-b1-p01.mp4`, `godot/audio/sfx.gd:152-167, 336-400`)

---

## 2. Per-Area Further Gaps (Beyond the Top 10)

### 2.1 Graphics (Art Director)

#### G1. Sparse 3D Campaign Star-System Scene
- **Area:** Graphics
- **What a player sees today:** In `docs/shots/ui_redesign/briefing/rail_r2_1080/sector_3.png` and `docs/shots/ui_redesign/briefing/1080/01_map_jump0.jpg`, the Hollow Sun black hole anchors the right side well, but the rest of the 3D campaign space is tiny ship clusters floating in empty pitch-black space along thin curves. There are no orbital dust belts, glowing jump-gate beacons, faction-held station rings, or subtle distant star-system parallax.
- **What the benchmark game does:** **Sins of a Solar Empire II** makes every star system feel alive with orbital asteroid belts, glowing phase-lane anchors, planet gravity wells, and ambient trade/patrol traffic around landmarks.
- **Fix:** Enrich `godot/ui/campaign/map3d_props.gd` and `map3d_system.gd` with faint orbital dust arcs, glowing jump-node beacons at service/boss stops, and faction-tinted territory light rings around key landmarks while keeping the orders-sheet rail uncluttered.
- **Size:** M (2 to 4 runs: 3D system props and orbital dust shaders in `map3d_*`, sector 1 to 3 comparison captures)
- **Confidence:** OBSERVED (`sector_3.png`, `01_map_jump0.jpg`, `02_map_three_routes.jpg`)

#### G2. Zero Moving Mechanical or Organic Hull Sub-Parts Across the Fleet
- **Area:** Graphics
- **What a player sees today:** In `docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg`, `BATTLE1076_IM5_c170_standard.jpg`, and `godot/fx/fx_idle.gd:38-59`, capital ships sit as rigid static statues between moves. Planned `#1685` (currently off by default) adds only tiny soft pulsing sprites (`radar_sweep`, vent dots) rather than real moving geometry, and only Chorus C14 has hinged bay doors.
- **What the benchmark game does:** **EVE Online** and **Sins of a Solar Empire II** sell colossal living vessels with slowly rotating radar dishes, spinning station habitat rings, pulsing radiator shutters, and animated hangar/bay doors.
- **Fix:** Add 1 to 2 lightweight vertex-animated or node-rotated sub-parts per faction kit (rotating Directorate radar arrays, Sunward radiator shutters, Hullbreaker wobbling scoop dishes, Eclipse floating orbit rings, Chorus breathing pore rims) driven cheaply on the GPU.
- **Size:** L (5 or more runs: shared kit sub-part convention, per-faction animated parts, export verification)
- **Confidence:** OBSERVED (`BATTLE1076_A16_c26_standard.jpg`, `BATTLE1076_IM5_c170_standard.jpg`, `godot/fx/fx_idle.gd:38-59`)

#### G3. Flat Nebula and Ion-Storm Patches Lack True 3D Depth and Weapon-Light Reaction
- **Area:** Graphics
- **What a player sees today:** In `docs/shots/1359/pc/boneyard_graveyard_1359_1_cine_no_hover_c170.jpg` and `docs/shots/battle_baseline_1118/BATTLE1076_storm_01.jpg`, rose nebulae and teal ion storms read as flat painted smudges pinned near the hex plane with faint diagonal hatching lines over them, never catching the glow of passing lances or explosions.
- **What the benchmark game does:** **Battlefleet Gothic: Armada** and **EVE Online** build gas clouds as multi-layered parallax wisps that softly catch nearby weapon flashes and capital explosions while keeping ships inside readable (matching RULEBOOK 10.4).
- **Fix:** Layer 2 to 3 offset parallax gas strata in `godot/world/world_living.gd` with subtle dynamic light-scatter from nearby weapon and death flashes while preserving crisp ship silhouettes inside the cloud.
- **Size:** M (2 to 4 runs: layered cloud shader and point-light scatter hook in `world_living.gd`, frame-time gate check)
- **Confidence:** OBSERVED (`boneyard_graveyard_1359_1_cine_no_hover_c170.jpg`, `BATTLE1076_storm_01.jpg`)

#### G4. Bare Backdrop Planets Without Orbital Scale Anchors or Night-Side Detail
- **Area:** Graphics
- **What a player sees today:** In `docs/shots/issue-1765/PV2_board_c170.jpg`, `docs/shots/player_path_1119/navy-b1.jpg`, and `docs/shots/1361/AC1361_comets_wide.jpg`, the new V2 planet surfaces look much sharper, but planets still hang as solitary spheres with no orbital defense rings, distant station silhouettes, terminator atmospheric scattering rim, or subtle night-side settlement/volcanic glow.
- **What the benchmark game does:** **Sins of a Solar Empire II** and **EVE Online** anchor planetary scale with glowing atmospheric terminators, subtle night-side city or magma pinpoints, and thin orbital structures catching the starlight.
- **Fix:** Add an optional terminator atmospheric-scatter Fresnel rim and biome-specific night-side detail mask (subdued volcanic fissures, Directorate orbital grid lights, or dead-star eclipse glint) inside `godot/world/world_planet.gd`.
- **Size:** S to M (1 to 2 runs: planet shader update in `world_planet.gd`, 5-biome capture check)
- **Confidence:** OBSERVED (`PV2_board_c170.jpg`, `navy-b1.jpg`, `AC1361_comets_wide.jpg`)

---

### 2.2 Effects (VFX Lead)

#### E1. No Faction-Distinct Warp-In or Reinforcement Arrival Visuals
- **Area:** Effects
- **What a player sees today:** In `docs/shots/player_path_1119/hullbreakers-b2.jpg` (01:03.6) and `docs/shots/player_path_1119/navy-b2.jpg` (01:03.6), enemy reinforcements simply pop onto the board beside a tiny plain text word `Arrived`. The game already wired a warp-in sound cue (`godot/audio/clips/evt_fleet_warp_in_0.ogg`), yet visually ships appear without a jump flash or deceleration streak.
- **What the benchmark game does:** **Sins of a Solar Empire II** and **Battlefleet Gothic: Armada** turn every fleet arrival into a dramatic event with directional phase-jump flashes, stretched light streaks, and faction-colored entry wakes.
- **Fix:** Add a 0.8 s faction-colored jump-in effect (directional light tear, brief stretched hull slide-in, and fading wake ring) triggered on reinforcement spawns and battle start, synced to `evt_fleet_warp_in_0.ogg`.
- **Size:** M (2 to 4 runs: warp-in FX shader/helper in `godot/fx/`, reinforcement hook in `battle.gd`, look-bench clip)
- **Confidence:** OBSERVED (`hullbreakers-b2.jpg`, `navy-b2.jpg`, `godot/audio/clips/evt_fleet_warp_in_0.ogg`)

#### E2. Plain, Undersized Floating Combat Numbers With No Hit-Quality Hierarchy
- **Area:** Effects / UI/UX
- **What a player sees today:** In `docs/shots/player_path_1119/navy-b1-p01.mp4` (00:37), impacts spawn tiny plain white text (`-2 hull`, `-10 shield`) that barely stands out against beams and hex lines, with no visual distinction between a glancing hit, a heavy armor penetration, a critical hit, or a silenced weapon.
- **What the benchmark game does:** **BattleTech** pops crisp color-coded floating combat callouts (`ARMOR`, `STRUCTURE`, `CRIT`, `DESTROYED`, `EVADED`) scaled to impact weight so players read every volley without touching the combat log.
- **Fix:** Style floating combat callouts in `battle.gd`/`hud.gd` using the orders-sheet palette (Glacier for shield absorb, Ember for hull/crit, bone for miss/evade, red badge for section/weapon knockout) with subtle pop-and-drift motion scaled by damage tier.
- **Size:** S (1 run: floating combat text hierarchy in `hud.gd`/`battle.gd`, player-path verification)
- **Confidence:** OBSERVED (`navy-b1-p01.mp4` at 00:37)

#### E3. No Barrel Recoil, Weapon Heat Flare, or Dense Point-Defense Flak Curtains
- **Area:** Effects
- **What a player sees today:** In `docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg`, `docs/shots/hit_fragments/hull_fragments_c170.png`, and `godot/fx/fx_weapons.gd:58`, firing rocks the ship slightly (`SHOOTER_RECOIL`), but turret barrels never physically kick back into their housings, heavy lance or radiator vents never brighten briefly from firing heat, and flak interception reads as sparse isolated bursts rather than a tight defensive curtain.
- **What the benchmark game does:** **Sins of a Solar Empire II** and **EVE Online** animate physical barrel recoil, brief thermal barrel/vent glow after capital volleys, and crisp point-defense tracer curtains intercepting incoming ordnance.
- **Fix:** Add a brief local-Z recoil kick on fired turret barrel nodes in `fx_weapons.gd`/`fx_hull.gd`, pulse a short post-shot emissive heat decay on heavy weapon muzzles, and tighten point-defense tracer streams toward intercepted torpedoes and wings.
- **Size:** M (2 to 4 runs: turret barrel recoil + muzzle heat pulse + flak tracer pass, look-bench close-up capture)
- **Confidence:** OBSERVED and INFERRED (`BATTLE1076_A16_c26_standard.jpg`, `godot/fx/fx_weapons.gd:58, 245-282`)

#### E4. Capital Ship Explosions Do Not Disturb Nearby Nebula Gas or Loose Debris
- **Area:** Effects / Physics and Motion
- **What a player sees today:** In `docs/shots/battle_baseline_1118/BATTLE1076_IM5_c170_standard.jpg`, `godot/fx/fx_death.gd`, and `godot/world/nebula_wake.gd`, ship movement already parts nebula clouds (`nebula_wake.gd`), yet a massive battleship or flagship detonation emits no expanding pressure wave into the nebula wake field or nearby floating debris.
- **What the benchmark game does:** **EVE Online** and **Sins of a Solar Empire II** sell capital destruction with an expanding shockwave ring that briefly pushes nearby space dust, gas clouds, and small debris outward.
- **Fix:** Feed capital death blasts into `nebula_wake.gd` as a radial impulse ring and apply a gentle damped radial nudge to nearby sleeping debris plates in `fx_death.gd` (staying inside RULEBOOK 6.2 flash comfort limits).
- **Size:** S to M (1 to 2 runs: shockwave impulse hook between `fx_death.gd` and `nebula_wake.gd`, look-bench clip)
- **Confidence:** INFERRED (`godot/fx/fx_death.gd`, `godot/world/nebula_wake.gd`)

---

### 2.3 Physics and Motion (Technical Animator and Physics)

#### P1. Turrets Only Slew at Commit Instead of Tracking Hovered and Planned Targets Live
- **Area:** Physics and Motion
- **What a player sees today:** In `docs/shots/player_path_1119/navy-b1-p01.mp4` and `godot/fx/fx_weapons.gd:246`, articulated turrets wait until a committed move finishes braking (`#1581`) before turning toward a target, leaving guns pointing straight ahead while the player aims and hovers enemies on the board.
- **What the benchmark game does:** **Sins of a Solar Empire II** and **EVE Online** visibly slew turrets toward locked targets before firing, giving immediate tactile confirmation that guns are bearing on the enemy.
- **Fix:** Feed the currently hovered or planned target position into `ship_view.gd` so eligible turrets smoothly slew within their firing arcs while planning, and smoothly return to neutral rest when planning clears.
- **Size:** S (1 run: live aim-preview hook from `battle.gd` into `fx_hull.gd` turret traverse, turret check update)
- **Confidence:** OBSERVED and INFERRED (`navy-b1-p01.mp4`, `godot/fx/fx_weapons.gd:246`, `godot/render/ship_view.gd`)

#### P2. Camera Lacks Zoom-Linked Pitch Tilt, Smooth Follow-Cam Toggle, and Dynamic Fleet Framing
- **Area:** Physics and Motion / Camera
- **What a player sees today:** In `godot/render/camera_rig.gd:166-275`, zooming in or out moves strictly along a fixed straight ray at the current pitch angle `b`, forcing players to manually right-drag tilt every time they zoom close to inspect a hull; there is also no optional follow-cam toggle for watching a flagship move and no smooth pullback when large 20-ship Sector 3 engagements spread wide.
- **What the benchmark game does:** **Sins of a Solar Empire II** and **EVE Online** subtly ease camera pitch lower when zooming in close to ships (and higher toward tactical overview when zooming out) plus offer a single-key ship-follow lock.
- **Fix:** Add an opt-in gentle zoom-pitch curve (flatter tactical view when zoomed out, hero three-quarter angle when zoomed in under radius 70) and a `Follow Ship` lock toggle in `camera_rig.gd` without overriding manual right-drag orbit.
- **Size:** S to M (1 to 2 runs: zoom-pitch easing and follow lock in `camera_rig.gd`, camera regression test)
- **Confidence:** INFERRED (`godot/render/camera_rig.gd:166-275`)

#### P3. Uniform Strike-Craft Attack Choreography Lacks Dogfight Weaving and Formation Attrition
- **Area:** Physics and Motion
- **What a player sees today:** In `docs/shots/issue-1021-openai/keel_target_1080.png` and `godot/render/squadron_wing.gd`, strike craft fly in tight uniform patrols and use one shared dive-and-climb pass (`#1874`) whether fighters are intercepting enemy wings or bombers are making an anti-capital run, and damaged wings lack broken-formation straggling or trailing smoke ribbons on individual craft.
- **What the benchmark game does:** **Sins of a Solar Empire II** differentiates darting fighter dogfight weaves from low hull-skimming bomber runs, with damaged craft breaking formation and trailing smoke.
- **Fix:** Split `squadron_wing.gd` attack paths into two distinct motion profiles (weaving high-angle fighter dogfight passes vs low belly/flank bomber torpedo runs) and drop individual craft visibly out of formation as wing HP falls (respecting Reduce Motion).
- **Size:** M (2 to 4 runs: dual attack-run splines and per-craft HP loss cues in `squadron_wing.gd`, clip capture)
- **Confidence:** OBSERVED and INFERRED (`keel_target_1080.png`, `godot/render/squadron_wing.gd`)

#### P4. Broken Wreck Halves Drop Out of Physics Early and Never React to Passing Hulls or Blasts
- **Area:** Physics and Motion
- **What a player sees today:** In `godot/fx/fx_death.gd:19-26`, wreck pieces leave Jolt physics after `WRECK_PHYS_S` and debris plates permanently sleep after `DEBRIS_REST_S`, so later broadsides, rams, or passing capitals clip or ignore nearby floating scrap completely.
- **What the benchmark game does:** **Battlefleet Gothic: Armada** and **EVE Online** keep battlefield wreckage feeling physically present, with small scrap nudged aside by passing ships and secondary blasts without hurting frame rate.
- **Fix:** Keep sleeping debris plates wakeable on close hull proximity or nearby explosion impulses (with a tight per-frame wake budget and quick re-damping per R393) so flying through a fresh kill field gently parts the floating scrap.
- **Size:** S to M (1 to 2 runs: proximity wake budget in `fx_death.gd`, 20-ship frame-time check)
- **Confidence:** INFERRED (`godot/fx/fx_death.gd:19-26, 480-545`)

---

### 2.4 UI/UX (UX Lead)

#### U1. Modal Teaching-Card Spam Interrupts the First Minute of Play
- **Area:** UI/UX
- **What a player sees today:** In `docs/shots/player_path_1119/navy-b1-p01.mp4` (00:08, 00:19, 00:38, 00:45), four separate tall teaching boxes (`MOVING AND FACING`, `SHIELDS AND HULL`, `FIRING`, `THREAT MAP`) pop up in the first 45 seconds of Battle 1, covering the upper-right battlefield while a second black hover tooltip sits over the ships. Planned `#1403` adjusts Battle 1 spacing and relay labels, but keeps the modal card pattern.
- **What the benchmark game does:** **BattleTech** teaches first-mission controls with lightweight anchored callout highlights tied to the exact button or hex the player needs next, never stacking multi-paragraph modal boxes over live combat.
- **Fix:** Replace the 4 early-battle paragraph boxes with short 1-to-2-line anchored callouts pointing at the live control (move hex, target ring, threat toggle) that dismiss automatically when the player performs the action.
- **Size:** M (2 to 4 runs: contextual callout controller in `hud.gd`, player-path Battles 1 to 3 recapture)
- **Confidence:** OBSERVED (`navy-b1-p01.mp4` at 00:08, 00:19, 00:38, 00:45; `navy-b1.jpg`)

#### U2. Shield Power Routing Is Buried in Prose With No Interactive Facing Readout
- **Area:** UI/UX
- **What a player sees today:** In `godot/scenes/battle/battle.gd:3479-3498` and `godot/ui/battle/ledger.gd`, the lossy shield-routing mechanic (`+20%` facing coverage at `+30%` pool drain after taking a hit on a side) exists only as a hidden tooltip paragraph; nothing on the ship's KEEL card or board ring visually distinguishes a routed high-drain facing from a standard facing.
- **What the benchmark game does:** **Battlefleet Gothic: Armada** and **EVE Online** make shield stress and power routing unmistakable at a glance with pulsing arc highlights and clear efficiency callouts.
- **Fix:** Highlight routed shield arcs in bright Glacier pulse on the new KEEL schematic (Top 10 #1) and on the hovered 3D shield rim, with a crisp 1-line icon badge (`PROW ROUTED +20% COV / +30% DRAIN`).
- **Size:** S (1 run: routed-side highlight in `ledger.gd` and `ship_view.gd`, readability check)
- **Confidence:** INFERRED (`godot/scenes/battle/battle.gd:3479-3498`, `godot/ui/battle/ledger.gd`)

#### U3. Non-Interactive Combat Log Truncates Mid-Sentence and Hides Damage Math
- **Area:** UI/UX
- **What a player sees today:** In `docs/shots/issue-1021-openai/keel_target_1080.png` and `docs/shots/player_path_1119/navy-b1-p01.mp4`, the bottom-right log clips lines with ellipses (`...has been planne...`), cannot be clicked to jump the camera to the ship or hit, and gives no expandable hit-chance or damage breakdown after a surprising miss or massive crit. (`#1401` wraps only the single newest line.)
- **What the benchmark game does:** **EVE Online** and **BattleTech** let players inspect exact combat rolls (base hit, range, evasion, nebula, armor, shield absorb) and click log events to locate units on the field.
- **Fix:** Make combat log entries clickable to focus the camera on the acting ship/target, and add a hover breakdown on any fired volley entry showing the exact hit-chance and shield/armor/hull math.
- **Size:** S to M (1 to 2 runs: structured log entries and click-focus hook in `hud.gd`/`battle.gd`, UI check)
- **Confidence:** OBSERVED (`keel_target_1080.png`, `navy-b1-p01.mp4`)

#### U4. Bare Text-Only Event Cards With Zero Scene Art or Risk/Reward Clarity
- **Area:** UI/UX / Presentation
- **What a player sees today:** In `docs/shots/issue-1084-openai/EVENT.png` and `docs/shots/issue-1084-openai/SECTOR_BRIEF.png`, narrative events and sector briefings render as plain black text boxes with zero scene art, no speaker portrait, and uneven risk previews (`Offer aid` gives vague prose while `Seize the cargo` gives exact numbers).
- **What the benchmark game does:** **BattleTech** pairs every Argo event with atmospheric header art, crew portraits, and clean tags showing cost/risk categories before you commit.
- **Fix:** Add a framed atmospheric header banner (reusing faction/biome artwork or the `#1897` admiral/Nemesis portraits) and consistent icon tags (Credits, Hull, Nemesis Clock, Ambush Risk, Unlock Requirement) to campaign event cards in `campaign_ui.gd`.
- **Size:** M (2 to 4 runs: event card art header and outcome-tag pass in `campaign_ui.gd`, UI checks)
- **Confidence:** OBSERVED (`EVENT.png`, `SECTOR_BRIEF.png`)

#### U5. Essential PC Graphics and Comfort Controls Exist in Code but Are Missing From Settings
- **Area:** UI/UX / Loading and Performance
- **What a player sees today:** In `docs/shots/settings/settings_ui_scale_reduce_motion.png` and `godot/main/main.gd:21, 279-296`, `main.gd` already supports `render_scale`, `fps_cap`, `vsync`, and `#1779` adds opt-in LUT/DoF/SSR toggles, yet the Settings screen hides all of them behind one coarse `Graphics` (`Max`/`Low`) switch and a `Temporal AA` button, with no resolution selector, window mode (`Borderless`/`Windowed`/`Fullscreen`), camera pan speed, or separate UI/SFX/Ambience audio sliders.
- **What the benchmark game does:** **Sins of a Solar Empire II** and **BattleTech** give PC players clean Display, Graphics, Audio (Master/SFX/Music/Ambience/UI), and Camera Speed controls right in Settings.
- **Fix:** Expand the `orders_kit.gd` Settings menu into clean tabs (Display & Graphics, Audio, Controls & Camera, Comfort) exposing `render_scale`, `fps_cap`, `vsync`, borderless/windowed modes, post-FX toggles, camera speed, and separate Ambience/UI volume sliders.
- **Size:** M (2 to 4 runs: tabbed Settings layout in `campaign_ui.gd`/`main.gd`, persistence tests, 1080p/4K UI shots)
- **Confidence:** OBSERVED (`settings_ui_scale_reduce_motion.png`, `godot/main/main.gd:21, 279-296`)

---

### 2.5 Loading and Performance (Performance Engineer)

#### L1. Stark Five-Second Black Load Screen With Frozen `SHIPS READY 0/0` Counter
- **Area:** Loading and Performance / UI/UX
- **What a player sees today:** In `docs/shots/player_path_1119/navy-b1-p01.mp4` (00:00 to 00:05), entering a battle sits on a solid black screen reading `PREPARING THE BATTLE` (`SHIPS READY 0/0`, which vanishes to blank black for 4 seconds). While `#1434`/`#1995` cut total load time and `#1405` item 9 notes a future load cover, no issue builds a responsive, informative pre-battle tactical brief screen with live progress ticks.
- **What the benchmark game does:** **BattleTech** and **Sins of a Solar Empire II** mask loading behind a rich mission briefing screen showing enemy faction intel, objective summary, and a smooth progress bar.
- **Fix:** Replace the blank black load veil with an orders-sheet Battle Briefing cover showing the sector backdrop, enemy fleet intel, objective reminder, and a real per-stage progress bar driven by the `#1434` sliced loader.
- **Size:** S to M (1 to 2 runs: briefing load overlay wired to `#1434` progress ticks, load-capture check)
- **Confidence:** OBSERVED (`navy-b1-p01.mp4` 00:00 to 00:05)

#### L2. Per-Shot `AudioStreamPlayer3D` and Tween Allocation Churn in Heavy Battles
- **Area:** Loading and Performance / Sound and Music
- **What a player sees today:** In `godot/audio/sfx.gd:368-401`, every individual layer of every weapon shot, hit, and explosion calls `AudioStreamPlayer3D.new()`, adds it to the scene tree, spawns up to two `Tween` objects, and frees them afterward. In 20-ship Sector 3 fights with multi-gun broadsides and flak, this creates hundreds of node add/remove cycles per minute. Neither `#1780` nor `#1995` pools audio nodes.
- **What the benchmark game does:** **Sins of a Solar Empire II** and **EVE Online** pre-allocate fixed audio voice pools so massive fleet salvos produce zero allocation spikes or GC hitches.
- **Fix:** Replace dynamic node creation in `sfx.gd` with a pre-allocated pool of `AudioStreamPlayer3D` and `AudioStreamPlayer` nodes (matching `max_voices`) and manual envelope stepping in `_process()`.
- **Size:** S (1 run: voice pool refactor in `godot/audio/sfx.gd`, `audio_check.gd` and stress check)
- **Confidence:** INFERRED (`godot/audio/sfx.gd:368-401`)

#### L3. No Runtime VRAM Residency Budget or Texture Mip-Bias Scaling for Mid-Range GPUs
- **Area:** Loading and Performance
- **What a player sees today:** Under RULEBOOK 5.18 (`#1908`), flagships and battleships ship 4096 PBR texture sets and planets use 8K maps. While `#1780` adds BC7 world compression and `#1439` measures peak VRAM on Ryan's 16 GB RTX 5080, there is no automatic texture-quality tier (`High`/`Medium` mip bias or ship-cache LRU eviction between campaign battles) to prevent VRAM paging stutters on 8 GB to 12 GB Steam PCs.
- **What the benchmark game does:** **Sins of a Solar Empire II** and **EVE Online** expose a Texture Detail setting and evict unused faction textures between scenes to stay smoothly inside 8 GB VRAM cards.
- **Fix:** Add a Texture Detail setting (`4K`/`2K`/`1K` max ship/planet mip cap) and evict non-present faction hull caches between sectors so VRAM stays predictable across multi-sector runs on 8 GB to 16 GB cards.
- **Size:** M (2 to 4 runs: texture mip cap and between-sector cache eviction in `ship_loader.gd`/`world_planet.gd`, memory sampler check)
- **Confidence:** INFERRED (`docs/RULEBOOK.md` 5.18, `godot/render/ship_loader.gd`)

#### L4. No Lightweight Performance HUD or Hardware Preset Auto-Check
- **Area:** Loading and Performance / UI/UX
- **What a player sees today:** `godot/main/main.gd` has internal timing prints for PC test harnesses, but a real player has no opt-in FPS/frame-time corner readout or automatic first-launch graphics check to match their monitor (1080p vs 1440p vs 4K) to the 60 fps target (RULEBOOK 3.9).
- **What the benchmark game does:** **Sins of a Solar Empire II** and **Battlefleet Gothic: Armada** provide a clean opt-in FPS readout and first-launch hardware preset selection.
- **Fix:** Add an opt-in minimal FPS / GPU frame-time toggle in Settings (rendered in Azeret Mono) plus a quick first-launch GPU tier check that picks a sensible default preset and render scale.
- **Size:** S (1 run: lightweight FPS readout and first-launch preset probe in `main.gd`/`hud.gd`)
- **Confidence:** INFERRED (`godot/main/main.gd`, `docs/shots/settings/settings_ui_scale_reduce_motion.png`)

---

### 2.6 Sound and Music (Audio Director)

#### A1. Live Battle Soundtrack Clashes With the Dark Sci-Fi Setting and Lacks Per-Faction Musical Identity
- **Area:** Sound and Music
- **What a player sees today:** Heard directly in `docs/shots/player_path_1119/navy-b1-p01.mp4` (00:08 to 00:47) and verified in `godot/music/music.json`, the live CC0 battle music (`fac_hegemony` / `hot_pursuit`) sounds like a bright, cheerful adventure brass march rather than grim hollow-star warfare, and `fac_corsair.ogg` loops every `14.5 s`. Planned `#1752` Gate 3 replaces battle music with one 4-stem adaptive loop (`M2`), but does not yet cover cohesive per-faction musical leitmotifs or a signature flagship/boss theme at that same quality bar.
- **What the benchmark game does:** **BattleTech** pairs dark brooding cello and tactical percussion with memorable tension escalation; **Sins of a Solar Empire II** and **Battlefleet Gothic: Armada** give every faction its own unmistakable musical signature (cathedral brass, cold machine pulses, alien bio-drones).
- **Fix:** After `#1752` Gate 3 proves the 4-stem `AudioStreamInteractive` battle system, produce 1 signature faction stem overlay per faction (6 short bar-locked stems) plus a dedicated Sector 3 Boss / Hollow Sun finale theme so battles sound unmistakably tied to who you are fighting.
- **Size:** M (2 to 4 runs: 6 bar-locked faction stems + boss theme generation and wiring in `music_player.gd`)
- **Confidence:** OBSERVED (`navy-b1-p01.mp4` audio track, `godot/music/music.json`, `godot/music/music_player.gd`)

#### A2. Single-Take Repetition on Newly Wired Gate 2 Faction Weapons and Impacts
- **Area:** Sound and Music
- **What a player sees today:** In `godot/audio/clips/` and `godot/audio/cues.json`, most newly wired Gate 2 weapon and impact keepers (`wep_sunward_lance_beam_0.ogg`, `wep_directorate_ion_beam_0.ogg`, `wep_hullbreaker_junk_gun_0.ogg`, `wep_ithar_pulsar_0.ogg`, `imp_metal_light_0.ogg`, `shd_hit_absorb_0.ogg`) have only 1 audio file (`_0.ogg`). Even with pitch jitter, firing 4 identical batteries in a round sounds noticeably repetitive against RULEBOOK 8.4's 4-take target. Wave F (`#1752`) adds takes to a subset of core SFX, not all 26 faction weapons and material impacts.
- **What the benchmark game does:** **BattleTech** and **Battlefleet Gothic: Armada** round-robin 3 to 5 distinct takes per frequent weapon and impact with subtle transient layering so long multi-ship battles never sound robotic.
- **Fix:** Expand every frequent weapon fire, shield absorb, and hull impact cue to at least 3 distinct round-robin takes (building on Wave F) and verify zero back-to-back repeats in `audio_check.gd`.
- **Size:** M (2 to 4 runs: targeted multi-take ElevenLabs generation + mastering + wiring)
- **Confidence:** OBSERVED (`godot/audio/clips/` file listing, `godot/audio/cues.json`, `wep_sunward_lance_beam_0.ogg`)

#### A3. Missing Micro-Tactile Planning, Targeting, and Warning Audio on the Battle Board
- **Area:** Sound and Music / UI/UX
- **What a player sees today:** In `docs/shots/player_path_1119/navy-b1-p01.mp4` and `godot/audio/cues.json`, moving the ghost across hexes, rotating facing with `Q`/`E`, locking weapons onto an enemy, stepping into an ion storm, or pressing Backspace to undo a planned step produces almost no tactile audio feedback compared to standard menu clicks.
- **What the benchmark game does:** **EVE Online** and **BattleTech** give players unmistakable micro-audio cues: crisp target-lock chirps, soft rangefinder ticks when sweeping hexes, muted mechanical unwind on undo, and subtle hazard hums when hovering dangerous terrain.
- **Fix:** Wire 5 subtle, dry tactical UI cues in `battle.gd` (hex-step tick, `Q`/`E` pivot click, enemy target-lock chime when guns bear, Backspace undo unwind, and ion-storm/gravity-well hover warning) kept soft and non-fatiguing per RULEBOOK 8.1.
- **Size:** S (1 run: 5 clean tactical UI cues + wiring in `battle.gd` and `cues.json`)
- **Confidence:** OBSERVED (`navy-b1-p01.mp4`, `godot/audio/cues.json`)

#### A4. No Dynamic Priority Sidechaining During Overlapping Multi-Ship Volleys
- **Area:** Sound and Music
- **What a player sees today:** In `godot/audio/sfx.gd:126-226`, dynamic ducking (`mix_duck`, `death_beat`) fires only on capital death beats, leaving dense 10-to-20-ship broadside exchanges, flak storms, and shield breaks competing evenly against the single master compressor.
- **What the benchmark game does:** **Battlefleet Gothic: Armada** and **Sins of a Solar Empire II** carve brief micro-ducking pockets around hero weapons (lances, torpedoes, shield collapses) so critical hits punch cleanly through dense combat noise.
- **Fix:** Trigger short priority micro-ducks (-2 to -4 dB for 0.25 s on lower-priority weapon/ambient buses) when a capital lance, torpedo hit, or shield break lands in `sfx.gd`.
- **Size:** S (1 run: priority transient ducking in `godot/audio/sfx.gd`, `sound_weight_check.gd` update)
- **Confidence:** INFERRED (`godot/audio/sfx.gd:126-226`)

---

### 2.7 Progression and Campaign (Game Designer: Campaign and Progression)

#### C1. Non-Flagship Ships Have Only One Refit Slot and Zero Swappable Weapon Pods
- **Area:** Progression and Campaign
- **What a player sees today:** In `godot/rules/data/tables.json` (`FIT_SLOTS`) and `docs/shots/late_run_1178/L1178_late_market.png`, only the flagship gets a swappable weapon pod, module, and section trim; every other frigate, destroyer, cruiser, and battleship has 1 refit slot and fixed weapons for the whole run.
- **What the benchmark game does:** **BattleTech** and **EVE Online** let players refit every unit in the roster with distinct weapon and utility loadouts (turning a standard cruiser into a flak escort, sniper, or close-range brawler).
- **Fix:** Give cruisers and capitals a second refit slot (or one swappable secondary weapon pod) at Sector 2 to 3 shipyards so players can specialize their entire line, not only the flagship.
- **Size:** M (2 to 4 runs: rules slot expansion, Shipyard fitting UX, Godot balance sim recheck)
- **Confidence:** OBSERVED and INFERRED (`L1178_late_market.png`, `godot/rules/data/tables.json` `FIT_SLOTS`)

#### C2. Static Linear 7-Jump Sector Graph Lacks Living Strategic Pressure
- **Area:** Progression and Campaign
- **What a player sees today:** In `docs/shots/issue-1176-codex/route-1176-01.png` and `docs/shots/ui_redesign/briefing/rail_r2_1080/sector_3.png`, each sector is a static 7-column left-to-right funnel where stops sit frozen until clicked and the only strategic clock is the 4-pip Nemesis bar.
- **What the benchmark game does:** **BattleTech** (time, finances, shifting faction reputation, timed contracts) and **Sins of a Solar Empire II** (shifting front lines and enemy fleet movements) make every jump on the map feel like a strategic race against a living enemy.
- **Fix:** Add 1 to 2 lightweight dynamic map elements per sector (such as a timed distress convoy that disappears after 2 jumps, or a roaming enemy hunter fleet that shifts one stop per jump) so route planning responds to a living sector.
- **Size:** M (2 to 4 runs: dynamic map state in `campaign.gd`, 3D indicator in `map3d.gd`, campaign parity update)
- **Confidence:** OBSERVED (`route-1176-01.png`, `sector_3.png`)

#### C3. Flat-Stat Captain Perks Without Crew Personalities or Memorable Ship Service Histories
- **Area:** Progression and Campaign
- **What a player sees today:** In `docs/shots/late_run_1178/L1178_late_market.png` and `godot/rules/data/tables.json` (`PERKS` = 14), ship captains are a random name plus 1 to 2 flat stat bumps (`+aim`, `+armor`, `+evasion`) with no callsign, service medals, or personality quirks; losing a veteran ship stings mathematically, not personally.
- **What the benchmark game does:** **BattleTech** turns pilots into memorable veterans with callsigns, personal traits, injuries, kill tallies, and ship-level service ribbons that make permadeath unforgettable.
- **Fix:** Give surviving captains earned combat epithets/callsigns (tied to kills, survived breaches, or flagship assists), a visible kill-mark strip on the ship card, and 6 to 8 high-identity specialization perks (such as "Point-Blank Gunnery" or "Damage Control Ace") instead of purely flat stats.
- **Size:** M (2 to 4 runs: captain traits/service record in `campaign.gd`/`rules.gd`, Fleet Manifest and Shipyard display)
- **Confidence:** OBSERVED and INFERRED (`L1178_late_market.png`, `FL5_1080.jpg`, `godot/rules/data/tables.json` `PERKS`)

#### C4. Protocol Offer Cards Lack Synergy Tags and Build-Direction Feedback
- **Area:** Progression and Campaign / UI/UX
- **What a player sees today:** In `docs/shots/issue-1084-openai/REWARD_OFFER.png`, Core Protocol offers show 3 plain text blocks with rarity words (`COMMON`, `EPIC`) and no visual cue showing which protocols actually trigger on your current fleet's weapons, wings, or faction mechanics, or how close you are to the next Core Sync tier.
- **What the benchmark game does:** **Sins of a Solar Empire II** (research tree clarity) and top tactical roguelites highlight exact build synergies, affected ship counts (`Applies to 3 of 4 ships`), and sync-tier progress right on the reward choice.
- **Fix:** Add compact affected-ship counts (`3 ships have lances`) and a mini Core Sync progress pip bar directly on the `REWARD_OFFER` protocol cards so players can make fast, informed build choices.
- **Size:** S (1 run: fleet-applicability check and sync pip bar in `campaign_ui.gd`, UI checks)
- **Confidence:** OBSERVED (`REWARD_OFFER.png`)

---

### 2.8 Tactical Depth and AI (Game Designer: Combat and AI)

#### T1. Only One Universal Ship Order (`Brace`) Limits Commander Decision Depth
- **Area:** Tactical Depth and AI
- **What a player sees today:** In `godot/rules/data/tables.json` (`ORDERS`) and `docs/shots/issue-1021-openai/keel_target_1080.png`, every ship shares only one universal tactical order (`Brace for impact`: -40% hull damage instead of firing). Every other ship turn reduces to "move, fire, or brace" unless a cooldown ability happens to be ready.
- **What the benchmark game does:** **Battlefleet Gothic: Armada** gives every vessel a crisp suite of universal fleet orders (Lock On for accuracy/crit at reduced evasion, All Ahead Full for burst speed with no weapons, Brace for Impact, Reload Ordnance) that turn every activation into a real trade-off.
- **Fix:** Add 2 clean universal orders beside `Brace` (for example, `Lock On`: +15 aim/+10 crit this turn while losing evasion/movement; and `Emergency Burn`: +2 movement with weapons offline) with full Veteran AI usage and balance-sim verification.
- **Size:** M (2 to 4 runs: 2 new orders in `rules.gd` and `tables.json`, KEEL order shelf buttons, AI logic, Godot balance sim)
- **Confidence:** OBSERVED and INFERRED (`keel_target_1080.png`, `godot/rules/data/tables.json` `ORDERS`)

#### T2. Under-Exploited Tactical Terrain and Hollow Sun Gravity-Well Mechanics
- **Area:** Tactical Depth and AI
- **What a player sees today:** In `godot/rules/data/tables.json` (`TERRAIN_INFO`, `BEVENTS`) and `docs/shots/1359/pc/boneyard_graveyard_1359_1_cine_no_hover_c170.jpg`, battle terrain is limited to solid LOS blockers plus 3 flat stat modifiers (`neb` -15 hit, `debris` -10 hit, `storm` -10 shield/turn). The Hollow Sun's gravity well pulls ships inward (`WELL_PULL`), yet there are no true stealth gas clouds, destructible unstable wrecks/fuel depots, or gravity-slingshot movement lanes.
- **What the benchmark game does:** **Battlefleet Gothic: Armada** uses gas clouds to break target locks and ambush fleets; **BattleTech** rewards players for detonating environmental hazards and managing heat/cover terrain dynamically.
- **Fix:** Deepen 2 existing terrain types without cluttering rules: let dense Nebulae block long-range locks beyond 5 hexes (turning gas into true ambush cover) and add 1 interactive hazard tile per biome (such as an unstable ammo hulk that can be detonated or a gravity-well slingshot rim giving +1 free move along the orbit).
- **Size:** M (2 to 4 runs: rules + visual tells + Veteran AI awareness + saved-results update)
- **Confidence:** OBSERVED and INFERRED (`boneyard_graveyard_1359_1_cine_no_hover_c170.jpg`, `godot/rules/data/tables.json`)

#### T3. Single-Ship Greedy AI Lacks Multi-Ship Fleet Coordination and Shield-Screening Discipline
- **Area:** Tactical Depth and AI
- **What a player sees today:** In `godot/rules/rules.gd:7451-7935`, Veteran AI scores each ship well individually (`aiRefreshFocus`, `aiRearScore`, `aiStormCost`, `evalThreatVet`), but each activation decides in isolation (`aiUnit`). Enemy fleets do not intentionally sequence an ion-stripping ship before a lance sniper on the same focus target, screen fragile carriers behind fresh brawlers, or rotate a fresh shield arc forward when holding a choke point.
- **What the benchmark game does:** **BattleTech** and **Sins of a Solar Empire II** coordinate fleet roles: shield-strippers and flankers open lanes before heavy finishers fire, and escorts screen high-value capitals.
- **Fix:** Upgrade `aiPickActivation` and `aiUnit` on Veteran AI to (1) activate shield-stripping ion/anti-shield ships before high-hull lance finishers when both can reach `aiFocus`, (2) give escorts a light bodyguard bonus for positioning between player brawlers and friendly carriers, and (3) factor shield-facing freshness into ending-facing selection.
- **Size:** M (2 to 4 runs: Veteran AI activation ordering and facing/screening weights in `rules.gd`, balance sim & saved-results check)
- **Confidence:** INFERRED (`godot/rules/rules.gd:7545-7935`)

#### T4. Narrow Encounter Objective Variety Across Three Sectors
- **Area:** Tactical Depth and AI / Progression
- **What a player sees today:** In `godot/rules/data/tables.json` (`ENCOUNTERS` = 8), only 8 encounter types span all 3 sectors, and most early/mid battles resolve as standard fleet-break fights (`rout`) or simple 3-round relay holds (`hold`).
- **What the benchmark game does:** **BattleTech** and **Battlefleet Gothic: Armada** vary tactical pacing with distinct objective structures: escorting a damaged friendly ship across a contested zone, destroying multiple orbital relay pylons under reinforcement pressure, or disabling and boarding a fleeing courier.
- **Fix:** Add 2 to 3 fresh high-drama encounter templates (Friendly Escort through an asteroid gauntlet, Multi-Pylon Destruction before a reinforcement wave, and Data-Vault Boarding Raid) wired into Sector 2 and 3 pools.
- **Size:** M (2 to 4 runs: encounter rules in `rules.gd`/`campaign.gd`, objective HUD/board markers, balance sim check)
- **Confidence:** INFERRED (`godot/rules/data/tables.json` `ENCOUNTERS`)

---

### 2.9 Skirmish, Replayability, and Presentation Polish (Added Area)

#### X1. No Custom Skirmish or Fleet Builder Mode
- **Area:** Replayability / UI/UX
- **What a player sees today:** In `godot/main/main.gd:500-515` and `docs/shots/frontend_1217_p2/F2_title_normal.png`, clicking `Quick battle` launches one hardcoded `start_default()` battle with zero option to choose factions, point budgets, ships, admirals, AI level, or arena biome.
- **What the benchmark game does:** **BattleTech**, **Sins of a Solar Empire II**, and **Battlefleet Gothic: Armada** all offer a clean Skirmish lobby so players can build custom fleets, stage dream faction matchups, or practice counter-tactics outside the roguelite campaign.
- **Fix:** Turn `Quick battle` into a compact orders-sheet Skirmish Setup screen (Pick Player Faction & Fleet Points, Enemy Faction & AI Level, Arena & Biome, plus a "Random Clash" instant-start button).
- **Size:** M (2 to 4 runs: Skirmish setup screen in `campaign_ui.gd` using `orders_kit.gd`, custom battle launcher in `main.gd`, UI checks)
- **Confidence:** OBSERVED and INFERRED (`F2_title_normal.png`, `godot/main/main.gd:500-515`)

#### X2. No Photo Mode / Hide-HUD Toggle or End-of-Battle Kill Replay
- **Area:** Presentation Polish / Camera
- **What a player sees today:** Despite huge visual investment in 4K ship hulls, modeled interiors, wounds, and multi-beat deaths, `godot/scenes/battle/battle.gd` offers no `Hide HUD` photo-mode key during pause or slow-mo kills and no option to replay a flagship kill or favorite turn from a free close-up camera.
- **What the benchmark game does:** **EVE Online** (`Ctrl+F9` clean cinematic view) and **Sins of a Solar Empire II** / **Battlefleet Gothic: Armada** let players hide all UI cleanly to watch or screenshot fleet clashes, and review decisive battle moments.
- **Fix:** Add a one-key `Hide HUD / Photo Mode` toggle (`H`) that hides tactical grids, rings, and KEEL cleanly while allowing free camera orbit during battle pause or slow-mo kills, and consider a lightweight battle-replay seed playback option later.
- **Size:** S (1 run for `Hide HUD / Photo Mode`; M for full battle replay playback)
- **Confidence:** INFERRED (`godot/scenes/battle/battle.gd`, `godot/render/camera_rig.gd`)

#### X3. Leftover Lore Name Drift (`Hegemony Navy`) and Flat Ship Previews on Start Screens
- **Area:** Presentation Polish / UI/UX
- **What a player sees today:** In `docs/shots/frontend_1217_p3/F3_setup_normal.png`, `docs/shots/issue-1021-openai/keel_target_1080.png`, and `docs/shots/player_path_1119/navy-b1.jpg`, the display name `Hegemony Navy` still appears across the faction select tab, top-right battle HUD, and combat log even though the approved display name in `AGENTS.md` and `rename_map_final.md` is `Meridian Directorate` (`hegemony` is the internal ID only). On `F3_setup_normal.png`, starting-fleet silhouettes also give no hover stat breakdown, and on `F4_flagship_voidsworn.png` the flagship renders as a flat backlit silhouette (C37 `#1406` / R436 partially addresses C37 lighting, not the faction rename sweep or fleet-preview hovers).
- **What the benchmark game does:** **BattleTech** and **Sins of a Solar Empire II** keep faction naming 100% consistent across every menu and battle header and let players inspect every starting unit before clicking Launch.
- **Fix:** Sweep remaining user-facing `Hegemony Navy` strings to `Meridian Directorate` (keeping internal ID `hegemony` unchanged per RULEBOOK 11.1) and add compact ship-stat hover cards to the starting fleet silhouettes on the faction/admiral desk.
- **Size:** S (1 run: display-string sweep + starting-fleet hover tips in `campaign_ui.gd`, UI checks)
- **Confidence:** OBSERVED (`F3_setup_normal.png`, `F4_flagship_voidsworn.png`, `keel_target_1080.png`, `navy-b1.jpg`)

---

## 3. What Already Holds Up to AAA (Protect and Keep)

- **Six Unmistakable Faction Ship Identities and Hull Craft:** The rebuilt hulls (`C19_51` Pyre-Barge in `BATTLE1076_A16_c26_standard.jpg`, `H4_11` Iron Mandate in `BATTLE1076_IM5_c170_standard.jpg`, `D22_23` Unsetting in `BATTLE1076_E11_c26_standard.jpg`, `I8_37` Unfinished pearl-and-stained-glass Ark in `CD5_r5c_camera170.jpg`, and `B22_11` Chorus Brood-sac in `C14_runH_concept_vs_ingame.jpg`) have zero generic sci-fi sameness and read clearly at battle distance under Ship Look V2 (`R426`, `R433`).
- **Planets V2 and Comets/Asteroids V2:** The remixed high-relief rocky, terran, barren, and volcanic worlds (`docs/shots/issue-1765/PV2_board_c170.jpg`) and the pale-frost ice belts plus dark twin-tail comets (`docs/shots/1361/AC1361_comets_wide.jpg`, `R445`) already rival Sins of a Solar Empire II backdrop fidelity.
- **Editorial Orders-Sheet UI Identity (DB1, FL5, CR4, Campaign Rail):** The after-run Debrief Ledger (`docs/shots/issue-1051-codex/DB1_win.png`), Fleet Manifest with live 3D ship viewport (`docs/shots/ui/fleet_fl5/FL5_1080.jpg`), Career Honours Board (`docs/shots/ui/career_cr4/CR4_compare_1920x1080.jpg`), and the ember campaign rail (`docs/shots/ui_redesign/briefing/rail_r2_1080/sector_3.png`) look genuinely human-designed, cohesive, and distinct from generic indie sci-fi UI.
- **Plan-Then-Commit Tactical Turn Flow With Undo:** Moving a ghost ship, rotating with `Q`/`E`, targeting enemies from the destination, stepping back with Backspace, and watching move-and-fire resolve as one continuous event (`RULEBOOK 9.17a`, `UNDO-1_after_move.jpg`) feels cleaner and more modern than many full-price turn-based tactics games.
- **Gate 2 Mastered Weapon and Death SFX Plus Death-Beat Audio Ducking:** Directly listening to `godot/audio/clips/wep_sunward_lance_beam_0.ogg` and `godot/audio/clips/death_sunward_magazine_0.ogg` confirms weighty, dark, non-arcade sci-fi sound design; the master limiter/compressor and capital-death near-silence ducking in `godot/audio/sfx.gd` are strong studio-grade fundamentals.
- **Deep Faction Rule Asymmetry and Roguelite Build Backbone:** Six genuinely distinct faction economies and rules (Chorus biomass + core eating, Glasswright post-fire fade + cullet refunds, Eclipse core regrow + Fold skip, Hullbreaker boarding/raiding, Sunward line-of-battle broadsides, Directorate sync fire), combined with 24 admirals with unique Command riders, lineage trees, capstone mastery, 24 relics, 48 Core protocols, and a persistent Nemesis rival, already match or exceed genre peers on paper.

---

## 4. Already Planned (Not Counted as New Gaps)

The items below are already tracked by live open issues or pull requests on `rcbailey12/voidsworn`. Where an open issue only closes part of the AAA bar, the final column notes what remains open.

| Gap / Area | Open Issue or PR | Still Missing / Partial Note |
|---|---|---|
| Remaining old hulls, rebuilds, and faction repaints (Sunward Bastion/Hearth, Directorate Picket/Cordon/Vanguard, Eclipse violet + Totality, Chorus rebuilds, strike craft & torpedoes) | `#1145`, `#1146`, `#1412` (PR `#1725`), `#1422`, `#1423`, `#1153`, `#1291`, `#1373`, `#1943` (shelved), `#1988` (shelved) | `#1943` and `#1988` (strike craft and torpedo bodies) are currently shelved to backlog; Eclipse strike craft have no concept slot yet. |
| Ship PBR material separation, 4K hero rebakes, Material Maker plating, and R411 fleet rollout | `#1778`, `#1681`, `#1684`, `#1908`, `#2001` (PR `#2017`), `#1889` (PR `#1910`/`#1925`) | Covers hull exterior PBR and plating; does not add animated mechanical sub-parts (Section 2.1 G2). |
| Real mid-battle 3D hull wounds, lit authored interiors, and capability-loss visual coupling | `#1741` (PR `#1755`/`#1997`), `#1743` (PR `#1763`), `#1991` (PR `#2007`) | Covers 3D mesh damage; does not add a 2D HUD directional shield/section schematic (Top 10 #1). |
| Multi-piece wrecks, full faction deaths, acid/gauss deaths, big-hull cook-offs, and kit-derived debris | PR `#1737` (`#1236`), `#1399`, `#1394` (PR `#1858`), `#1875`, `#1362` | Covers break geometry and faction death colors; does not add blast shockwaves into nebula/debris (Section 2.2 E4) or proximity scrap wake (Section 2.3 P4). |
| Grounded Cinematic Space sky (400 stars), sky banding, gas floor, Blender storm lightning, and World Props V2 (stations, outpost, Chorus/Glasswright hulks) | `#1766`, `#1502`, `#1328`, `#1360` (PR `#1986`), `#1767` (PR `#1772`), `#1791` (PR `#1998`), `#2003` | Covers battle backdrop props and sky; does not enrich the 3D campaign map star-system scenery (Section 2.1 G1). |
| Effects polish: shared high-quality spark, standalone hits on shields, slow-mo effect clock sync, persistent acid/ion/low-shield strain, Chorus Acid Thorns, and 4 new look options | `#2018`, `#1974` (PR `#1980`), `#1970` (PR `#1976`), `#1971` (PR `#1975`), `#1693`, `#1877` (PR `#1904`), `#1463` (PR `#2000`) | Does not cover multi-layer lance beam shaders, volumetric engine plumes, localized shield impact ripples (Top 10 #7), or warp-in arrival FX (Section 2.2 E1). |
| Cinematic Post-FX (per-region 3D LUT, kill-cam DoF, selective SSR, CompositorEffect, Decals) | `#1779` (merged opt-in, capture pending) | Settings UI does not yet expose post-FX/display toggles to players (Section 2.4 U5). |
| Battle load freeze, battle-to-title speed, parallel death-cut precompute, cached SFX catalog, shader cache, BC7 world VRAM, FSR 2.2, Round 2/4 frame hitches, close-during-load, safe-mode launcher | `#1434` (PR `#1445`), `#1519` (PR `#1950`), `#1995` (PR `#2010`), `#1780` (PR `#1960`), `#1843` (PR `#1852`), `#1982`, `#1645`, `#1518`, `#1439` (PR `#1442`), `#1436`, `#1542` | Does not pool per-shot `AudioStreamPlayer3D` nodes (Top 10 #10 / L2) or add a runtime texture-tier VRAM cap for 8 GB GPUs (Section 2.5 L3). |
| Council UI fixes: HUD wording/buttons, first-battle spacing/relay label, cut-in HUD overlap, Hollow Sun title screen & icon, battle-camera readability | `#1401`, `#1403`, `#1404`, `#1405`, `#1406` (PR `#1964`) | `#1404` cleans up UI on cut-ins but does not add multi-angle over-the-shoulder/chase cut-in cameras (Top 10 #5); `#1403` does not replace modal teaching boxes with anchored callouts (U1); `#1405` defers the battle load cover (L1). |
| Admiral portraits (Codex style), story Beat 3, run endings, flagship hails, and Hullbreaker body wording | `#1897` (PR `#1903`), `#1990` (PR `#2020`) | Expands written hails and portrait art, but hails still print silently inside the tiny log box without a portrait comm banner or radio squelch (Top 10 #3). |
| Gate 3 audio and adaptive music (beam loop points, Wave F takes, 4-stem `AudioStreamInteractive` battle music, slow-mo low-pass) | `#1752` | Covers one shared 4-stem adaptive battle loop and core SFX fixes; does not cover per-faction musical stems (Section 2.6 A1), 3+ takes across all 26 faction weapons (A2), zoom-reactive spatial audio/biome beds (Top 10 #10), or tactical board UI ticks (A3). |
| Key rebinding, colorblind mode, and in-game rules reference | `#1454` | Tracked for later; mouse and keyboard only per RULEBOOK 9.16. |
| Build variety event chains, faction win-rate balance, 5-notch difficulty dial, per-faction economy spike, hull ability spread, and release `playtest_default` flip | `#1453`, `#1652` (Part F blocked), `#1992`, `#1940`, `#1941`, `#1510`, `#1508` | Does not add non-flagship customization slots (C1), dynamic map pressure (C2), custom Skirmish mode (X1), universal fleet orders (T1), or pre-battle deployment (Top 10 #9). |

---

## 5. Not Checked

- **Live interactive GPU play session:** Per `R429` worktree scope and `RULEBOOK 3.4` (an active GPU job queue was running on Ryan's RTX 5080 during this audit), this audit did not launch a live interactive Godot GPU window or run new GPU captures. All visual and audio observations come from real in-game stills, recorded player-path MP4 clips (`docs/shots/player_path_1119/`), look-bench sheets, campaign/UI captures, live audio `.ogg` assets, and current `main` (`f3437dc83`) GDScript and JSON tables.
- **Unmerged PR renders on the private relay repo (`rcbailey12/voidsworn-relay`):** Pictures for open look PRs (such as `PR #1755` Wounds V2, `PR #1763` Interior Kit V2, `PR #1737` Wrecks round 4, `PR #1903` Codex portraits, `PR #1986` Blender storm lightning, and `PR #1904` Chorus Acid Thorns) were not pulled from the private relay repo; those items are properly accounted for in Section 4 as planned work.
- **Full human 3-sector campaign playthrough and late-game 20-ship frame pacing by eye:** Late-sector combat feel, 20-ship battle cadence, and Sector 3 boss pacing were evaluated from rules code (`godot/rules/rules.gd`), campaign tables (`campaign_tables.json`), and recorded Battles 1 to 3 clips rather than a live 45-minute human run.
- **Other seats' Nov 24 AAA audits (`#2015` Astra, `#2016` Fable / PR `#2019`):** Intentionally unread per the independent-audit brief.
