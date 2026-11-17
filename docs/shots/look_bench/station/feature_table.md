# station_T2: production paint and preserved feature inventory

Issue 975 changes the finish and installation route, preserving PR 700's complete shape and working fittings.
The accepted design remains `tools/blender/kits/hegemony_station/design.py`; neither it nor `parts.py` changes.
The production route is `tools/recipe/station_paint.bat`, using `production.py`, `production_check.py` and `install.gd`.
The [current paint method, measurements and review evidence](README.md) describe the delivered finish.

| Production measurement | Value |
|---|---|
| Evaluated triangles retained | 697,088, including 110,428 inside |
| Exported surfaces / materials / mesh nodes | 12 / 9 / 2 |
| Uniform scale and dimensions | 1.919133; 99.200 x 70.211 x 69.281 game units |
| PBR detail tiles | Five 2048 sets; two game units per repeat |
| Lowest material mean texture density | 862.88 texels per game unit |
| Actual C15s_23 comparison cruiser | 42.30 mean; 191.86 finest triangle, texels per game unit |
| Smallest new surface features | Vent slots, flush screw slots and cover seams in normal/roughness |
| Existing silhouette fittings | Hatches, rails, pipes, window frames, docking jaws and tower arrays retained |
| Local wear | Real mesh cavity rays, bevel normals and damaged-side grime; no rust added |
| Measured station visible draw-call delta | 12, by hiding the station in the GPU studio |
| Station-map 1080p frame medians | 4.112 / 4.113 / 4.143 ms |
| Station-map 4K GPU medians | 6.639 / 6.569 / 6.565 ms |
| Additional lit glazing | Six existing outer window faces beside the authored core light clusters |
| Accepted-export shape comparison | Every world-space triangle matches PR 700 at 0.0001-unit precision |

## PR 700 shape inventory, before production paint

The run 5 inventory below remains the record of the approved geometry. Its pending-paint and review-only wording
describes that earlier stage; issue 975 authorizes production paint and local installation.

## station_T2: run 5 purposeful station systems

Refs #373. Fleet station first. Review only; production paint and live swap remain pending.

Method: the Hegemony station kit builds the design in design.py. Review.py applies one uniform scale from docs/playbooks/scale.md, exports the review GLB, measures its actual meshes and renders the CPU sheets. Capture.gd uses real ShipView hulls and the game camera for the class comparisons.

## Scale and cost

Span 99.200 x 70.211 units; height 69.281. Uniform scale 1.919133 on every axis. Tallest of 30 real loaded hulls: 51.129 units. No vertical fit or axis stretch.

697,088 triangles: 586,660 exterior and 110,428 inside. 16 GLB material primitives, 13 materials, 2 mesh nodes. Triangles are reported, never capped. GPU draws and station-map frame time remain unmeasured.

The source plan fits the real seven-cell union. Uniform R247 scale overhangs that old footprint; live footprint integration remains open. Board.gd STATION constants and scale_check KNOWN rows are unchanged.

## T2 damage inventory

- Run 5, Ryan R290: all five towers upright, on the spread bridges and varied heights from run 4. Exported axis nodes measure their tilt.
- Nine drums have varied heights and radii, recessed window bands, stepped shoulders and small plant fittings.
- Exactly one broad observation pane. The other window bands are dark; 90 small emission markers stay sparse.
- Generic pallet blocks removed. Occupied drums and ring carry wheel hatches, framed EVA airlocks and connected supply/return runs.
- Arms carry corridor collars, pressure hatches and handrails. Berth ends carry clamp jaws, dark guide lenses and recessed pressure doors.
- Docking-arm cranes have trussed jibs and grapples. A segmented recessed cargo bay door is on the wide docking arm.
- Tower sensors have crossed dipoles and stand-offs; the communications tower carries pitted dishes and feed struts.
- Six ring outriggers are triangular trusses: three solar wings, three cold radiator combs. Four main radiator banks remain.
- Four attitude-control quads mount directly on the outer ring. Each has four open cold nozzles, separate lips and recessed throats.
- No debris field. The three held pods and folded plate from run 3 remain attached to the structure.
- Ring: 40-degree gap centred at 270 degrees over the stub arm, seized 30 degrees from service. Five sprung joint plates.
- Three service spokes; the southeast tube buckles inward and below the track.
- Four docking arms: three intact with deep collars, one bent half arm with exposed ribs and no collar.
- Three held cargo pods: two in an arm cradle, one against the ring. One thick torn plate folded over a walkway.
- Nine core drums: four shell holes plus one torn top edge. Rays through the built shell test all five apertures.
- Five dead caps: cracked dome, three pitted dishes, dark beacon, frozen raised crane, buckled landing pad. All towers upright.
- Four cold grooved radiator banks. Radiator 4 hangs 27 degrees open on one hinge and swings +/-3 degrees over 240 seconds.
- 90 blue emission markers in six jittered two-dimensional clusters and five dull orange battery strips. No red.

## INSIDE and break intent

Whole core drums have annular decks, shaft, radial frames and equipment racks. Ring arcs have corridor decks, inner walls and cross frames. Arms and spokes contain decks and racks; the stub strips back to ribs. Towers have trunk frames and racks, radiators have manifold channels. Shell holes remove the liner too. Eight core module joints, habitat sector joints, arm collars and tower roots remain authored. The review export joins static modules; production seam paths and tear validation remain open.

| ID | Kind | Purpose | Inside triangles |
|---|---|---|---:|
| core_01 | deck_drum | command | 8068 |
| core_02 | deck_drum | medical | 8068 |
| core_03 | deck_drum | stores | 7792 |
| core_04 | deck_drum | power distribution | 8068 |
| core_05 | deck_drum | machinery | 7708 |
| core_06 | deck_drum | coolant plant | 7636 |
| core_07 | deck_drum | habitat support | 7768 |
| core_08 | deck_drum | stores | 7660 |
| core_09 | deck_drum | upper service deck | 7528 |
| observation_window | viewport | one large lit curved observation pane in its pressure-frame reveal | 0 |
| bearing_00 | bearing_track | seized bearing slot; supports habitat module 1 | 0 |
| habitat_1_slot_00 | habitat_arc | habitat module 1; corridor, cross frames, equipment racks | 396 |
| bearing_01 | bearing_track | seized bearing slot; supports habitat module 1 | 0 |
| habitat_1_slot_01 | habitat_arc | habitat module 1; corridor, cross frames, equipment racks | 396 |
| bearing_02 | bearing_track | seized bearing slot; supports habitat module 2 | 0 |
| habitat_2_slot_02 | habitat_arc | habitat module 2; corridor, cross frames, equipment racks | 396 |
| bearing_03 | bearing_track | seized bearing slot; supports habitat module 2 | 0 |
| habitat_2_slot_03 | habitat_arc | habitat module 2; corridor, cross frames, equipment racks | 396 |
| bearing_04 | bearing_track | seized bearing slot; supports habitat module 3 | 0 |
| habitat_3_slot_04 | habitat_arc | habitat module 3; corridor, cross frames, equipment racks | 396 |
| bearing_05 | bearing_track | seized bearing slot; supports habitat module 3 | 0 |
| habitat_3_slot_05 | habitat_arc | habitat module 3; corridor, cross frames, equipment racks | 396 |
| bearing_06 | bearing_track | seized bearing slot; supports habitat module 4 | 0 |
| habitat_4_slot_06 | habitat_arc | habitat module 4; corridor, cross frames, equipment racks | 396 |
| bearing_07 | bearing_track | seized bearing slot; supports habitat module 4 | 0 |
| habitat_4_slot_07 | habitat_arc | habitat module 4; corridor, cross frames, equipment racks | 396 |
| bearing_08 | bearing_track | seized bearing slot; supports habitat module 5 | 0 |
| habitat_5_slot_08 | habitat_arc | habitat module 5; corridor, cross frames, equipment racks | 396 |
| bearing_09 | bearing_track | seized bearing slot; supports habitat module 5 | 0 |
| habitat_5_slot_09 | habitat_arc | habitat module 5; corridor, cross frames, equipment racks | 396 |
| bearing_10 | bearing_track | seized bearing slot; supports habitat module 6 | 0 |
| habitat_6_slot_10 | habitat_arc | habitat module 6; corridor, cross frames, equipment racks | 396 |
| spoke_1 | spoke | bearing support and service corridor | 192 |
| spoke_2 | spoke | bearing support and service corridor | 192 |
| spoke_3 | spoke | bearing support and service corridor; buckled | 88 |
| arm_1 | docking_arm | dead berth corridor | 1004 |
| arm_2 | docking_arm | dead berth corridor | 1004 |
| arm_3 | docking_arm | dead berth corridor | 1004 |
| arm_4 | docking_arm | torn arm root; exposed deck and rack rows | 468 |
| service_finger_1 | service_finger | trussed solar cell wing | 0 |
| service_finger_2 | service_finger | trussed cold radiator comb | 0 |
| service_finger_3 | service_finger | trussed solar cell wing | 0 |
| service_finger_4 | service_finger | trussed cold radiator comb | 0 |
| service_finger_5 | service_finger | trussed cold radiator comb | 0 |
| service_finger_6 | service_finger | trussed solar cell wing | 0 |
| ring_attitude_control | thruster_quad | four ring-mounted attitude quads, dark deep nozzles; no main engine axis | 0 |
| equipment_deck | platform | five separate radial tower bridges with core and ring connections | 0 |
| tower_1 | tower_cap | pad; dead; whole machine on its module joint | 6320 |
| tower_2 | tower_cap | dishes; dead; whole machine on its module joint | 6320 |
| tower_3 | tower_cap | dome; dead; whole machine on its module joint | 6320 |
| tower_4 | tower_cap | crane; dead; whole machine on its module joint | 6320 |
| tower_5 | tower_cap | beacon; dead; whole machine on its module joint | 6320 |
| radiator_1 | radiator | cold grooved bank and header | 56 |
| radiator_2 | radiator | cold grooved bank and header | 56 |
| radiator_3 | radiator | cold grooved bank and header | 56 |
| radiator_4 | radiator | cold grooved bank; single surviving hinge | 56 |
| cargo_1 | cargo_pod | held dead cargo: arm cradle | 0 |
| cargo_2 | cargo_pod | held dead cargo: arm cradle | 0 |
| cargo_3 | cargo_pod | held against ring outer face | 0 |
| folded_plate | debris | one torn plate folded over arm walkway; two thick bent leaves | 0 |
| emergency_lights | lights | 90 implant-blue markers in six scattered clusters; five dull battery strips | 0 |

## Detail inventory

Each row below accumulates actual vertices, faces and bounds emitted by a named kit helper. Triangle subtotals are before bevel modifiers. The overall cost above includes the evaluated bevels. Label anchors project emitted face centres into each native camera-60 view, rejecting occluded anchors by rays against the loaded station mesh. A label is a viewing aid; purpose and placement still need visual review.

| Fitting | Instances | Base triangles | Function |
|---|---:|---:|---|
| airlock | 61 | 21,716 | habitat EVA airlock; twin pressure leaves, frame, hinges and wheel |
| cargo_crane | 2 | 1,336 | docking-arm cargo manipulator; trussed jib, winch and capture grapple |
| cargo_pod | 3 | 216 | held cargo container with structural transport ribs |
| cold_radiator | 3 | 528 | grooved cold radiator fins with a connected supply and return header |
| coolant_manifold | 4 | 2,016 | radiator header, flanged circulation pump and paired pipes into the lower core |
| dish_array | 3 | 2,076 | tower parabolic communications dish, feed struts and pitted reflector |
| docking_port | 36 | 864 | berth clamp jaw and unpowered blue guide lens at arm end |
| handrail | 22 | 12,424 | paired ring walkway rails, posts and EVA tether points |
| hangar_door | 1 | 168 | closed cargo handling bay; recessed segmented pressure door and lintel tracks |
| hanging_radiator | 1 | 476 | cold thermal panel, longitudinal coolant channels and edge frame |
| maintenance_hatch | 58 | 37,120 | round pressure hatch with handwheel and hinge pair |
| maintenance_truss | 15 | 2,520 | triangulated panel outrigger with supply lines to ring |
| radiator | 3 | 1,428 | cold thermal panel, longitudinal coolant channels and edge frame |
| sensor_mast | 5 | 960 | tower-mounted crossed dipole antennas on visible stand-offs |
| service_pipe | 31 | 17,336 | core drum service risers, return elbows and shoulder manifolds |
| solar_panel | 3 | 1,368 | dark solar cells on paired triangulated outrigger supports |
| thruster_quad | 4 | 6,384 | ring attitude-control quad; four recessed cold nozzles on a bolted mount |
| viewport | 1 | 516 | one continuous observation pane and its sealed pressure-frame reveal |

## Checks and limits

All 49 sampled poses test the moving radiator against the fixed structure, excluding its own hinge contact. These samples do not certify a continuous sweep or full static fit. The scale check reads the table independently and measures the exported GLB; range_selftest alters actual GLB scales and proves rejection. Godot GPU comparisons use the real camera radius 170 and actual hulls, with two runs keeping the second. They are isolated studio evidence, not a station-map gate.

## Changes from prior sheet and concept

- Run 5 follows Ryan R290: all five towers are upright, retaining the spread bridges, distinct heights and caps from R284.
- Nine core drums now vary in height and radius, with stepped shoulders, dark glazing bands and sparse lit markers. The four torn holes and torn top stay open. One continuous large observation pane faces the damage-side camera.
- Generic service pallets and unexplained raised blocks are removed. Habitat modules carry framed airlocks, wheel hatches and connected service pipes; docking arms carry cargo handling, a recessed hangar door and berth gear; towers carry sensors and cable trunks. The inventory records each fitting and its measured geometry.
- Six short trussed ring fingers carry three cold radiator combs and three solar wings. Four ring thruster quads have open nozzles; docking collars carry dark guide lenses and clamps. Maintenance routes have handrails. The four main radiators and attached run 3 damage remain. No debris field added.
- The rules main station occupies seven cells (centre plus its six neighbours), not three cells. The source plan fits inside their union; the source footprint is three hex columns wide. R247 uniform review scaling now exceeds that live union; footprint integration remains open before a swap.
- The secondary spokes are offset from the docking arms; each tower has a bridge to a spoke or the bearing deck.
- The drum stack rises above the ring, toward the accepted beauty silhouette. Nine drums share one service shaft; the station does not gain a second core.
- The upper arm is angled 60 degrees into a blocked outer cell; a straight 90-degree arm would enter the unblocked notch between two cells in the source plan. The larger review still needs a matching live footprint.
- Run 3 replaces the old tethered arm animation with radiator 4 on one surviving hinge. The torn arm has no berth collar.
- The ring gap is 40 degrees centred on the stub arm at 270 degrees, seized 30 degrees from its service angle. Eleven bearing sectors occupy the remaining 320 degrees; five joint plates are sprung open.
- The concept inventory governs run 3: three spokes, one bent stub, three held pods, four side holes plus a torn top drum, five dead caps, four cold radiators and six scattered light clusters. The older pack called for four spokes and a tethered arm.
- Radiators use dense grooves and root manifolds, without a solar-cell grid.
- The design carries no weapons. lore_bible_r8.md describes the Reach and Hegemony but gives no station battery layout. The live defend objective has rules batteries; it is not the abandoned T2 visual target.
- The cause of the write-off stays off the player-facing sheet. The damage is permanent, not a running fire effect.
- Core drum dimensions, tower positions and heights and the observation pane are retained from run 4. The run 3 breaks, source footprint, uniform scale and slow radiator motion are preserved. Preview material only; production paint is deliberately pending.

## Review order

Camera 170 class pictures first at native size, then T2_beauty_compare.png and T2_plan_compare.png, then the five game_detail60*_labelled.png views at actual game zoom radius 60, the low camera and inside sheet. Ryan has not looked during this run. Outside check and Ryan look precede production installation.
