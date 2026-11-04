# Station detail pass brief (R94) - DeepSeek leg synthesis

Binding rulings from contrib/opus/FINDINGS.md override this brief where they conflict. Items marked [INFERRED] are chair/leg inference, not yet sourced or measured; they are carried as explicit open items for the chair synthesis. The R94 approved height and silhouette shapes (towers, gantry, refinery column and tanks) are locked; this detail pass adds height and asymmetry seen from above without replacing those shapes.

1. Scope and locked inputs

Scope is the two R79 station kinds built from one Blender kit: fleet station and refinery. Relay beacon and intercept transports are out of scope except where the kit shares parts (#102 synthesis).

Locked geometry: 46-unit shared spine (five modules, x = -18.4 to 18.4; top face at z = 2), axial battleship cradle on +Y, outer rail at y = 13, two service-side frigate berths, four twin batteries at x = +/-11.5 dorsal/ventral. Fleet skyline: control tower at x = 0 (top about z = 11.4), antenna array to about z = 16; secondary sensor tower at x = -18 only (top about z = 8, sensors to about z = 12.7); service truss top z = 8.5; radiator fins at x = +/-6, top about z = 8. Refinery: intake/output drums radius 3 at x = +/-16; central cracking tower radius 3, centre z = 6.6, length 12.4 (top about z = 12.8), process sensors to about z = 17.7; service tanks at x = +/-13, y = -12; heat radiators at x = +/-13, top about z = 10; pipe bridges at drum height.

R94 detail-pass diagnosis: from the battle camera the stations still read as fairly flat frames. The measurable cause is that all spine top faces sit on one plane at z = 2 across 46 units, and every tall element sits on the service side within the footprint, so the top-down outline barely changes. Height exists in side view; top-down silhouette and top-face height stepping are what the detail pass must add.

2. Camera and read rules (from #102 synthesis, carried forward)

Battle camera anchor: about 170 units out, looking down; 15.4 px per unit at 4K.

Silhouette features must be 2 units or larger to read as shape; 1-2 units is secondary read; below 1 unit is texture only; below 0.5 units is wasted geometry.

Gaps under 4 units read as noise; berth openings must clear 6 units.

Long spine first; working face vs service face separation retained: berths, batteries and lit guides on the working face; radiators, tanks and cable runs on the service face.

At least three silhouette breaks along the length.

Faction identity is paint and lit accents only, never silhouette: one kit serves every map; station takes the map faction's paint (FAC_MAP, battle.js:59).

Camera numbers are arithmetic from the anchors and are labelled INFERRED in #102; no Blender triangle counts were run in #102. This brief does not treat those as measured.

3. Per-station height, lopsidedness and silhouette changes for the battle camera
3.1 Fleet station

Locked R94 shape to preserve: control tower at x = 0, secondary sensor tower at x = -18, service truss, radiator fins at x = +/-6, axial cradle and 46-unit spine.

Detail-pass additions (top-down height stepping and asymmetry):

Break the z = 2 top-face plane. Add stepped dorsal boxes on the spine top at x = -12, -4, +4, +12, with top faces at z = 3.5, 5.0, 4.0 and 6.5 respectively. At least two of these must be 2 units or taller above the local spine top so they read as shape from 170 units. Keep each box footprint <= 4 units in x so it does not read as a second spine. [INFERRED dimensions; to be checked against berth and gun clearances.]

Add one working-face tower offset from centre. Place a slim sensor/control mast at x = +7.5 on the working face (+Y side), top about z = 13, footprint 2 x 2. This breaks the current "all tall elements on service side" rule for the detail pass and creates an asymmetric top-down read. It must not encroach on the 6-unit berth opening or the axial cradle. [INFERRED; requires clearance check.]

Make the secondary tower read as a second peak. Raise the x = -18 sensor tower's top from about z = 8 to about z = 10.5 and add a 2-unit-wide cross-arm at z = 9.5, so from above it is a distinct asymmetric counterweight to the x = 0 control tower. Do not duplicate the x = 0 tower on the +x side.

Add an open gantry arch over the spine at x = +2 to +5, spanning y = -6 to +6, top about z = 9. The arch must be open (no solid roof) so it reads as a truss line from above and does not hide the spine. This adds a silhouette break between the two towers and increases height on the working side. [INFERRED; keep under 2 units member thickness.]

Asymmetric radiator treatment. Keep the paired radiator fins at x = +/-6, but add one taller fin at x = -6 (top about z = 10) and a shorter, wider fin at x = +6 (top about z = 8.5). This gives a lopsided top-down outline without changing the service-face function.

Docking-arm asymmetry. Add one additional short docking arm on the service side at x = +14, y = -7, extending 4 units outboard, with a 2-unit end plate. The existing axial cradle and two frigate berths remain the primary working-face read. [INFERRED; verify no collision with turret arcs.]

Silhouette-break count check. The detail pass must produce at least three distinct silhouette breaks along the 46-unit length from above: the x = -18 tower cluster, the x = 0 tower/antenna cluster, and the x = +2 to +5 gantry plus x = +7.5 mast. The stepped dorsal boxes support secondary read but do not count as the three primary breaks.

3.2 Refinery

Locked R94 shape to preserve: intake/output drums at x = +/-16, central cracking tower radius 3 at centre z = 6.6 (top about z = 12.8), process sensors to about z = 17.7, service tanks at x = +/-13, y = -12, heat radiators at x = +/-13 top about z = 10, pipe bridges at drum height.

Detail-pass additions (break near-mirror symmetry and add top-down height stepping):

Break the paired drum symmetry. Keep both drums at x = +/-16, but add a taller cap stack on the -x drum (top about z = 9) and a wider, lower flange on the +x drum (top about z = 7). The two drums must no longer read as identical from above. [INFERRED dimensions; preserve drum radius 3 and axis Y.]

Add a second, smaller column offset from the centre. Place a 1.5-radius process column at x = +7, y = -4, top about z = 11, with a 2-unit cap. This is not a replacement for the central cracking tower; it is a secondary vertical that makes the top-down outline lopsided. Keep it clear of the central tower's process sensors. [INFERRED; check pipe routing.]

Step the tank tops. Service tanks at x = +/-13, y = -12 remain, but raise the -x tank top to about z = 6 and lower the +x tank top to about z = 4.5, with a 2-unit access hatch on the taller tank. This gives a visible height difference from above at the service edge.

Asymmetric radiator bank. Keep heat radiators at x = +/-13, but make the -x bank three fins at top about z = 10 and the +x bank two fins at top about z = 8.5, with one fin angled 15 degrees outboard. The angled fin adds a non-rectilinear top-down edge.

Add one tall flare/vent stack on the service side at x = -5, y = -9, top about z = 14, diameter 1.5, with a 2-unit flare tip. This is the refinery's second tall element and must be clearly lower than the central tower's sensor top (about z = 17.7) so the central tower remains the primary vertical. [INFERRED; R102 said one tall element only in the #102 spec; R94 detail pass explicitly adds height and asymmetry, so this is an R94-authorized second vertical. Label as an R94 change, not a #102 contradiction.]

Pipe-bridge asymmetry. Keep pipe bridges at drum height, but add one elevated pipe run from the central tower to the -x drum at z = 8, with a 1-unit pipe diameter and two supports. Do not mirror it on the +x side. This creates an asymmetric line across the top-down silhouette.

Silhouette-break count check. Primary breaks from above: the -x drum cap stack, the central cracking tower/process sensor cluster, and the +7 secondary column plus -5 flare stack. The +x drum and +x radiator bank remain secondary reads.

4. Close zoom detail language per station type and per owning faction

Close zoom is the inspection camera, not the 170-unit battle camera. Detail language below is for panels, lights, radiators, antenna arrays, docking arms, traffic and life signs. Geometry must still obey the battle-camera read rules where it contributes to silhouette; sub-1-unit detail is texture/trim only.

4.1 Fleet station - close zoom

Panels: spine modules carry rectangular hull panels with visible seam gaps of 0.05-0.1 units; panel borders receive the faction trim band. Working-face panels around berths are heavier, with recessed bolt rows and replaceable armour tiles. Service-face panels are thinner and show cable conduit runs.

Lights: lit guide strips along the working-face berth lips and battery cowlings; small red/amber hazard lights at gantry joints and docking-arm hinges; white work lights under the axial cradle. All lit accents use the owning faction's glow colour.

Radiators: fin banks show parallel coolant tubes, a 0.2-unit edge frame, and heat-scorch gradient on the inner faces. Asymmetric fin heights per section 3.1.

Antenna arrays: the x = 0 tower carries a lattice array with 0.1-0.2-unit members, feed lines and a lit beacon at the top; the x = -18 tower carries a smaller dish and whip set. Close zoom must show mount brackets and cable drops.

Docking arms: axial cradle shows hydraulic rams, locking clamps, 0.2-unit guide rails and a lit approach corridor; the added +14 service arm shows an end plate with bumper pads and a small control box.

Traffic and life signs: small shuttle/loader props on the working face near berths (0.5-1.5 units, texture-read at battle camera); lit windows on the control tower at 0.3-0.5 units; EVA handrail lines and small airlock doors on the spine sides. Life signs are lit window clusters and small docking-bay glow, not character models.

Faction dressing: Glasswrights - pale hull #eef3f1, trim #d7c88a, glow #9fffd2; panel bands on spine and tower bases, battery cowlings in trim, dock lips in glow. Hullbreakers - hull #6a2c22, trim #b8402a, glow #e0402c; heavier wear on panel edges, trim on battery cowlings and dock lips, red glow in hazard and berth lights. Other faction palettes to be taken from the #72 faction look pack at synthesis time; the extract read here covers only these two in full.

4.2 Refinery - close zoom

Panels: drum and tank shells show welded plate seams, 0.05-0.1-unit gaps, and inspection hatches; central tower has vertical ladder cages and platform rings at 3-unit intervals. Service-face pipe runs have bolted flanges and valve wheels.

Lights: process-status lights on the central tower (green/amber/red small lamps), lit level gauges on tanks, hazard lights at the flare stack base and drum caps. Glow colour follows owning faction.

Radiators: heat exchangers show fin stacks, coolant pipes and scorch gradients; the angled +x fin has visible hinge hardware.

Antenna arrays: process sensors above the central tower include small dishes, sampling probes and a lit beacon; the +7 secondary column carries a compact sensor cluster. Close zoom must show mounting brackets and cable trays.

Docking arms: refinery has no weapon mounts; docking is limited to the spine ends and the axial cradle shared with the fleet kit. Show intake/output pipe couplings at the drums as the primary "docking" read, with 0.2-unit locking collars.

Traffic and life signs: small maintenance skiffs near the drums (0.5-1.5 units), lit windows on the central tower platform rings, airlock doors at the tower base. Life signs are lit window clusters and small warning beacons, not characters.

Faction dressing: same palette rules as fleet. Glasswrights refinery reads cleaner, with trim bands on drum caps and lit process gauges in mint glow; Hullbreakers refinery reads heavier wear, with trim on pipe bridges and red glow at the flare stack and hazard lamps.

5. Paint and material stack per R96 Q1

Route: procedural materials driven by masks baked from each ship's own geometry (curvature, AO, edge wear) plus trim sheets and decals. No projected concept art. Local AI texturing only after a one-hull unlit PBR proof.

For stations, the R96 Q1 mask-driven paint stack is not applied yet; this detail pass is the point to apply it. Bake station masks from the station kit's own geometry (spine modules, towers, drums, tanks, radiators) using the same curvature/AO/edge-wear channels as ships. The station is faction-neutral geometry; faction paint goes on panel bands, battery cowlings, dock lips and lit accents over neutral structure (R84 Q4).

Material slots at export: keep the existing structure/armor/accent slots, but replace flat Principled colours (roughness 0.58, metallic 0.45) with the procedural stack. Trim sheets and decals are shared across both station kinds where the kit shares parts.

Proof gate: one station hull (fleet station spine plus control tower) must pass an unlit PBR proof before any local AI texturing is attempted. AI parts remain out of scope unless they come through the reviewed per-faction part library (R96 Q5).

[INFERRED] The station mask bake should reuse the ship bake pipeline; no separate station-only painter is authorized by the evidence pack.

6. Breakable by design per R98

Build-side requirement for every new or rebuilt hull, starting with the Pyre-Barge (#169, method research #171): real hull thickness, a few internal decks and bulkheads, and two or three authored break lines with matching interior faces and damage textures. Game side is #167.

Fleet station: stage 4 break at a radial-arm and spine junction (R80/#102). Author two break lines: one at the x = -11.5 battery/spine junction and one at the axial-cradle/spine junction. Interior faces must show decks, bulkheads and cable runs. Batteries degrade before the spine breaks (R80 four stages on the integrity track). Destruction hulk uses the same model.

Refinery: stage 4 break at a tank or drum mount (#102). Author two break lines: one at the -x drum/spine mount and one at the +x service tank mount. Interior faces must show tank shells, pipe stubs and bulkheads. Hulk doubles as boneyard dressing.

Both stations need real hull thickness on the spine and primary pressure volumes; thin gantry/truss members are exempt from break-line interiors but must have authored damage decals. Damage textures match the owning faction's wear language.

[INFERRED] The detail pass should reserve UV space and material IDs for the break-line interior faces now, even if the actual break VFX is #167 work.

7. Triangle and frame budget next to 20 ships

R96 Q3 performance ceiling near the stage 5 barge: about 306k triangles and 3.9 ms at 20 ships. This is a measured ceiling, not a station-only budget.

The synthesis must state a station share of that frame, not just a per-station triangle number. Proposed station share: fleet station <= 40k triangles, refinery <= 45k triangles, total station geometry in a 20-ship frame <= 85k triangles (about 28% of 306k) and <= 1.0 ms (about 26% of 3.9 ms). [INFERRED allocation; requires Blender triangle counts and frame timing. #102 explicitly did not run Blender triangle counts.]

Budget enforcement: the detail pass must produce a triangle count per station kind before and after the additions in section 3. Any addition that pushes a station over its share must be merged, decimated, or moved to texture/trim. Turret nodes remain separate and are counted in the fleet station share.

The 20-ship frame includes the ships; stations are additive. If the live scene cannot afford the full station share at 20 ships, the chair must choose a lower LOD for distant stations rather than exceed the frame ceiling.

8. Reference stations from shipped space games and films with sources

These are reference reads for silhouette, top-down height stepping and close-zoom detail language. Sources are public media/game documentation; exact capture references must be added at synthesis. [INFERRED reference list; not yet verified frame-by-frame in this run.]

Deep Space Nine - Star Trek: Deep Space Nine (TV series). Source: series production design and screen captures. Reference for radial arms, central core, lit docking rings and top-down asymmetric outline.

Babylon 5 - Babylon 5 (TV series). Source: series production design and screen captures. Reference for rotating cylinder, asymmetric modules and tall central spine.

Cairo Station - Halo 2 (game). Source: game mission "Cairo Station" and public wiki captures. Reference for ODP platform, towers and docking arms.

Coriolis / Orbis stations - Elite Dangerous (game). Source: in-game captures and public wiki. Reference for ring/truss frames, docking slot and lit traffic lanes.

Port Olisar - Star Citizen (game). Source: in-game captures and public wiki. Reference for strut-and-pad layout, docking arms and close-zoom panel language.

EVE Online stations - EVE Online (game). Source: in-game captures and public wiki. Reference for tall asymmetric station silhouettes and faction paint bands.

Tycho Station - The Expanse (TV/books). Source: series captures and book descriptions. Reference for refinery column, tanks and process read.

Homeworld stations/mothership - Homeworld Remastered (game). Source: in-game captures and public art. Reference for truss frames and gantry detail.

Use these to justify the height steps and asymmetry in section 3, not to copy silhouettes. The station kit remains the game's own geometry.

9. Codex detail job step list

Freeze the R94 locked shapes. Do not move the control tower at x = 0, the secondary tower at x = -18, the service truss, the radiator fins at x = +/-6, the refinery drums at x = +/-16, the central cracking tower, the service tanks at x = +/-13, or the pipe bridges. Record their current bounds.

Add fleet top-face height stepping. Place the four stepped dorsal boxes at x = -12, -4, +4, +12 with top faces at z = 3.5, 5.0, 4.0 and 6.5. Check berth 6-unit clearance and gun arcs.

Add fleet working-face mast and gantry. Add the x = +7.5 mast (top about z = 13) and the x = +2 to +5 open gantry arch (top about z = 9). Run attachment and gun-clearance checks.

Raise the x = -18 sensor tower to about z = 10.5 and add the 2-unit cross-arm at z = 9.5. Keep it clearly secondary to the x = 0 tower.

Asymmetrize fleet radiators and docking. Taller -x fin (top about z = 10), shorter +x fin (top about z = 8.5); add the +14 service docking arm with 4-unit reach and 2-unit end plate.

Add refinery asymmetry. Taller -x drum cap (top about z = 9), wider +x drum flange (top about z = 7); +7 secondary column (top about z = 11); stepped tank tops (-x about z = 6, +x about z = 4.5); asymmetric radiator banks; -5 flare stack (top about z = 14); elevated pipe run from central tower to -x drum at z = 8.

Apply the R96 Q1 station paint stack. Bake curvature/AO/edge-wear masks from the station geometry, build the procedural material with trim sheets and decals, and replace the flat Principled colours. Run the one-hull unlit PBR proof before any AI texturing.

Author close-zoom detail. Add panels, seam gaps, lights, radiator tubes, antenna brackets, docking-arm hardware, traffic props and life-sign window clusters per section 4. Keep battle-camera silhouette rules: 2-unit features for shape, sub-1-unit for texture only.

Author break lines and interiors. Fleet: break lines at x = -11.5 battery/spine junction and axial-cradle/spine junction. Refinery: break lines at -x drum/spine mount and +x service tank mount. Add real hull thickness, internal decks/bulkheads, matching interior faces and damage textures.

Count triangles and time the frame. Export both stations, record triangle counts per kind and per turret node, and measure frame time at 20 ships. Compare against the station share in section 7; merge or decimate if over.

Run validation. Standing checks, attachment checks, gun-clearance checks, GLB round trips, headless Godot imports, and 4K captures at 46 and 30 units with real Battleship and Frigate models. Add top-down captures at 170 units to prove the new height stepping and asymmetry.

Write the Codex handoff. Deliver to contrib/muse/research/station_detail_2026_11/ with synthesis plus legs. Branch muse/issue-172. Record all inferred dimensions and any deviation from this brief.

10. Owner questions with chair picks (max five)

Q: What station share of the 306k-triangle / 3.9 ms 20-ship frame is approved?
Chair pick: fleet <= 40k triangles, refinery <= 45k triangles, total station geometry <= 85k triangles and <= 1.0 ms, with Blender counts and frame timing to confirm. [INFERRED]

Q: Does the R96 Q1 mask-driven paint stack apply to stations in this detail pass, or is it deferred again?
Chair pick: apply it now, using masks baked from the station kit's own geometry, with the one-hull unlit PBR proof as the gate. Do not defer again; R96 Q1 is a ruling, not an option.

Q: Which faction palettes beyond Glasswrights and Hullbreakers are in scope for station dressing?
Chair pick: take all shipped palettes from the #72 faction look pack at synthesis time; the extract read here covers only Glasswrights and Hullbreakers in full. Do not invent palettes.

Q: Are the refinery's second tall element (flare stack) and the fleet's working-face mast allowed under R94, given #102 said one tall element for the refinery?
Chair pick: yes. R94 explicitly asks the detail pass to add more height and asymmetry seen from above; the flare stack stays below the central tower's sensor top, and the working-face mast stays clear of berth and cradle clearances. Record as an R94-authorized change.

Q: Which reference stations are approved for the brief's reference section?
Chair pick: use DS9, Babylon 5, Cairo Station, Coriolis/Orbis, Port Olisar, EVE Online stations, Tycho Station and Homeworld stations as reference reads; add exact capture sources at synthesis. Do not copy silhouettes.

11. Not checked / carries forward

PR #151 review sheets (fleet_review.jpg, refinery_review.jpg, stations_comparison.jpg) live on Ryan's PC under board/issue-61/shots/r91/ and were not readable from this run. The synthesis must mark them Not checked.

#102 did not run Blender triangle counts; camera numbers are arithmetic from anchors and labelled INFERRED. This brief's station share is also INFERRED until measured.

The #72 faction look pack extract read here covers Glasswrights and Hullbreakers in full; other palettes must be taken from the same pack file at synthesis time.

R98 breakable method research (#171) is still the method source; this brief only reserves break lines and interiors, not the final break VFX.

The R96 Q1 station mask bake pipeline is proposed by analogy to ships; confirm with the ship repair test (#129) winner before locking the station method.
