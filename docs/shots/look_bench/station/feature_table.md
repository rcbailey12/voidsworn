# station_T2: run 3 damage review

Refs #373. Fleet station first. Review only; production paint and live swap remain pending.

Method: the Hegemony station kit builds the design in design.py. Review.py applies one uniform scale from docs/playbooks/scale.md, exports the review GLB, measures its actual meshes and renders the CPU sheets. Capture.gd uses real ShipView hulls and the game camera for the class comparisons.

## Scale and cost

Span 99.200 x 70.201 units; height 65.185. Uniform scale 1.922853 on every axis. Tallest of 30 real loaded hulls: 51.129 units. No vertical fit or axis stretch.

519,028 triangles: 408,048 exterior and 110,980 inside. 14 GLB material primitives, 11 materials, 2 mesh nodes. Triangles are reported, never capped. GPU draws and station-map frame time remain unmeasured.

The source plan fits the real seven-cell union. Uniform R247 scale overhangs that old footprint; live footprint integration remains open. Board.gd STATION constants and scale_check KNOWN rows are unchanged.

## T2 damage inventory

- Ring: 40-degree gap centred at 270 degrees over the stub arm, seized 30 degrees from service. Five sprung joint plates.
- Three service spokes; the southeast tube buckles inward and below the track.
- Four docking arms: three intact with deep collars, one bent half arm with exposed ribs and no collar.
- Three held cargo pods: two in an arm cradle, one against the ring. One thick torn plate folded over a walkway.
- Nine core drums: four shell holes plus one torn top edge. Rays through the built shell test all five apertures.
- Five dead caps: cracked dome, three pitted dishes, dark beacon, frozen raised crane, buckled landing pad. Tallest leans five degrees.
- Four cold grooved radiator banks. Radiator 4 hangs 27 degrees open on one hinge and swings +/-3 degrees over 240 seconds.
- 90 blue emission markers in six jittered two-dimensional clusters and five dull orange battery strips. No red.

## INSIDE and break intent

Whole core drums have annular decks, shaft, radial frames and equipment racks. Ring arcs have corridor decks, inner walls and cross frames. Arms and spokes contain decks and racks; the stub strips back to ribs. Towers have trunk frames and racks, radiators have manifold channels. Shell holes remove the liner too. Eight core module joints, habitat sector joints, arm collars and tower roots remain authored. The review export joins static modules; production seam paths and tear validation remain open.

| ID | Kind | Purpose | Inside triangles |
|---|---|---|---:|
| core_01 | deck_drum | command | 8068 |
| core_02 | deck_drum | medical | 8068 |
| core_03 | deck_drum | stores | 7756 |
| core_04 | deck_drum | power distribution | 8068 |
| core_05 | deck_drum | machinery | 7696 |
| core_06 | deck_drum | coolant plant | 8068 |
| core_07 | deck_drum | habitat support | 7804 |
| core_08 | deck_drum | stores | 7732 |
| core_09 | deck_drum | upper service deck | 7588 |
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
| equipment_deck | platform | connected tower bases; services and blue emergency cluster | 0 |
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

## Checks and limits

All 49 sampled poses test the moving radiator against the fixed structure, excluding its own hinge contact. These samples do not certify a continuous sweep or full static fit. The scale check reads the table independently and measures the exported GLB; range_selftest alters actual GLB scales and proves rejection. Godot GPU comparisons use the real camera radius 170 and actual hulls, with two runs keeping the second. They are isolated studio evidence, not a station-map gate.

## Changes from prior sheet and concept

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
- The core radius is widened to show real open deck structure. Five caps keep their existing tower heights; the prior array and antenna caps become the concept landing pad and dark beacon. Preview material only; production paint is deliberately pending.

## Review order

Camera 170 class pictures first at native size, then T2_beauty_compare.png and T2_plan_compare.png, then the low camera and inside sheet. Ryan has not looked during this run. Outside check and Ryan look precede production installation.
