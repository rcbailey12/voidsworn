# station_T2: provisional build sheet

Refs #373. Fleet station first. T2 damaged is the accepted concept (R206); this sheet is a draft awaiting the Board. No production build or live swap is approved.

CPU studio renders only. The camera170 images use the game radius, beta and vertical field of view, at 1280 x 720 without resizing. They are not in-game captures or frame-gate evidence.

## Design and scale

Design authority: `tools/blender/kits/hegemony_station/design.py`; Hegemony-only geometry in `parts.py`. The real BattleAPI scenario and Board.hex_world supply the seven blocked cells. No rules cells are changed. Blender uses X/Y for the plan and Z up; the OBJ comparison converts actual fitted ShipView geometry to that frame.

Overall span 51.590 x 37.544 units; height 52.129 units. The tallest of 30 loaded hulls, including all six flagships, is 51.129 units. Vertical fit factor 1.506117 is provisional and must be judged against the accepted concept. The four orthographic views share a 125.110-unit horizontal field and a 10-unit scale bar.

## Feature table

| ID | Kind | Purpose | Route | Inside triangles |
|---|---|---|---|---:|
| core_01 | deck_drum | command | hand-built, Hegemony station kit | 1580 |
| core_02 | deck_drum | medical | hand-built, Hegemony station kit | 1580 |
| core_03 | deck_drum | stores | hand-built, Hegemony station kit | 1580 |
| core_04 | deck_drum | power distribution | hand-built, Hegemony station kit | 1580 |
| core_05 | deck_drum | machinery | hand-built, Hegemony station kit | 1580 |
| core_06 | deck_drum | coolant plant | hand-built, Hegemony station kit | 1580 |
| core_07 | deck_drum | habitat support | hand-built, Hegemony station kit | 1580 |
| core_08 | deck_drum | stores | hand-built, Hegemony station kit | 1580 |
| core_09 | deck_drum | upper service deck | hand-built, Hegemony station kit | 1580 |
| bearing_00 | bearing_track | seized bearing slot; supports habitat module 1 | hand-built, Hegemony station kit | 0 |
| habitat_1_slot_00 | habitat_arc | habitat module 1; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| bearing_01 | bearing_track | seized bearing slot; supports habitat module 1 | hand-built, Hegemony station kit | 0 |
| habitat_1_slot_01 | habitat_arc | habitat module 1; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| bearing_02 | bearing_track | seized bearing slot; supports habitat module 2 | hand-built, Hegemony station kit | 0 |
| habitat_2_slot_02 | habitat_arc | habitat module 2; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| bearing_03 | bearing_track | seized bearing slot; supports habitat module 2 | hand-built, Hegemony station kit | 0 |
| habitat_2_slot_03 | habitat_arc | habitat module 2; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| bearing_04 | bearing_track | seized bearing slot; supports habitat module 3 | hand-built, Hegemony station kit | 0 |
| habitat_3_slot_04 | habitat_arc | habitat module 3; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| bearing_05 | bearing_track | seized bearing slot; supports habitat module 3 | hand-built, Hegemony station kit | 0 |
| habitat_3_slot_05 | habitat_arc | habitat module 3; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| bearing_06 | bearing_track | seized bearing slot; supports habitat module 4 | hand-built, Hegemony station kit | 0 |
| habitat_4_slot_06 | habitat_arc | habitat module 4; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| bearing_07 | bearing_track | seized bearing slot; supports habitat module 4 | hand-built, Hegemony station kit | 0 |
| habitat_4_slot_07 | habitat_arc | habitat module 4; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| bearing_08 | bearing_track | seized bearing slot; supports habitat module 5 | hand-built, Hegemony station kit | 0 |
| habitat_5_slot_08 | habitat_arc | habitat module 5; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| bearing_09 | bearing_track | seized bearing slot; supports habitat module 5 | hand-built, Hegemony station kit | 0 |
| habitat_5_slot_09 | habitat_arc | habitat module 5; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| bearing_11 | bearing_track | seized bearing slot; supports habitat module 6 | hand-built, Hegemony station kit | 0 |
| habitat_6_slot_11 | habitat_arc | habitat module 6; corridor, cross frames, equipment racks | hand-built, Hegemony station kit | 396 |
| spoke_1 | spoke | bearing support and service corridor | hand-built, Hegemony station kit | 192 |
| spoke_2 | spoke | bearing support and service corridor | hand-built, Hegemony station kit | 192 |
| spoke_3 | spoke | bearing support and service corridor | hand-built, Hegemony station kit | 192 |
| spoke_4 | spoke | bearing support and service corridor; buckled | hand-built, Hegemony station kit | 88 |
| arm_1 | docking_arm | dead berth corridor | hand-built, Hegemony station kit | 1004 |
| arm_2 | docking_arm | dead berth corridor | hand-built, Hegemony station kit | 1004 |
| arm_3 | docking_arm | dead berth corridor | hand-built, Hegemony station kit | 1004 |
| arm_4 | docking_arm | torn arm root; exposed deck and rack rows | hand-built, Hegemony station kit | 120 |
| tethered_arm | docking_arm | one passive moving section; no power | hand-built, Hegemony station kit | 896 |
| tethers | conduits | torn flexible conduits joining the loose arm to its stub | hand-built, Hegemony station kit | 0 |
| equipment_deck | platform | connected tower bases; services and blue emergency cluster | hand-built, Hegemony station kit | 0 |
| tower_1 | tower_cap | array; dead; whole machine on its module joint | hand-built, Hegemony station kit | 6320 |
| tower_2 | tower_cap | dishes; dead; whole machine on its module joint | hand-built, Hegemony station kit | 6320 |
| tower_3 | tower_cap | dome; dead; whole machine on its module joint | hand-built, Hegemony station kit | 6320 |
| tower_4 | tower_cap | crane; dead; whole machine on its module joint | hand-built, Hegemony station kit | 6320 |
| tower_5 | tower_cap | antenna; dead; whole machine on its module joint | hand-built, Hegemony station kit | 6320 |
| radiator_1 | radiator | cold grooved heat rejection bank, header and pump | hand-built, Hegemony station kit | 56 |
| radiator_2 | radiator | cold grooved heat rejection bank, header and pump | hand-built, Hegemony station kit | 56 |
| radiator_3 | radiator | cold grooved heat rejection bank, header and pump | hand-built, Hegemony station kit | 56 |
| radiator_4 | radiator | cold grooved heat rejection bank, header and pump | hand-built, Hegemony station kit | 56 |
| cargo_1 | cargo_pod | dead cargo pod; one clamped and one lodged | hand-built, Hegemony station kit | 0 |
| cargo_2 | cargo_pod | dead cargo pod; one clamped and one lodged | hand-built, Hegemony station kit | 0 |
| lodged_debris | debris | twelve irregular torn structural remnants; no orbiting particles | hand-built, Hegemony station kit | 0 |
| emergency_lights | lights | 90 implant-blue lights in seven clusters; five static dull battery strips | hand-built, Hegemony station kit | 0 |

Six habitat modules are subdivided over eleven occupied bearing slots; slot 10 is the open gap. Four attached arms include the torn stub. The fifth arm row is the tethered outer section. Five caps are a comm array, dish pair, dome, parked maintenance boom and antenna drum. All are dead. The ring is seized. One passive arm transform carries the only animation.

## INSIDE

Core drums carry annular decks, a service shaft, radial frames and equipment racks. Ring arcs have corridor decks, inner and outer walls, cross frames and racks. Spokes and arms carry corridor structure and service runs. Towers carry a cable trunk, frame rings and equipment. Radiator roots carry header channels. These are modelled objects, not flat closing faces. The inside view hides the skins and liners and lifts exposure 1.5 stops so the dark machinery can be inspected.

| Break intent | Position in fitted world frame | Exposed contents |
|---|---|---|
| Eight core bulkhead joints | Z = -4.669, -0.904, 2.862, 6.627, 10.392, 14.157, 17.923, 21.688 | Deck rings, frames, shaft and racks |
| Habitat modules | Twelve 30-degree bearing boundaries; slot 10 open | Corridor, frames and racks |
| Arm modules | Root, pressure collars and berth collar | Deck, racks and pipe runs |
| Tower modules | Base ring, mast rings, whole cap | Cable trunk and equipment |
| Radiator banks | Header manifold | Cold channels and pump |

Break intent and source module meshes exist. Production seam paths, torn piece export and a destruction capture proving matching insides are still pending. The review GLB joins static modules for cost inspection; it is not a destructible game asset.

## Fit and movement

Every sampled mesh vertex is inside the real seven-cell union. All 49 poses across 240 seconds have zero intersections between the moving arm triangles and static structure, and zero vertices outside the footprint. The intentional tether attachment is excluded from that intersection test. Discrete samples do not prove a continuous sweep or the fit of every static machine. Full fit review remains pending.

The animation is a 240-second passive rotation plus a 3-degree, 40-second swing. The ring and battery strips stay static. Board answers on issue 373: no weapons, T1 later, damage cause ambiguous to the player, dust and vented insulation under hits only. The lore bible supplies no station weapon layout; none has been invented.

## Paint stack and budget

`stack.py` currently supplies Hegemony preview materials and schematic ambient occlusion. This is not the production mask, trim and decal stack. Frost, dust, damaged edge wear and the required extra surface detail remain production work after the sheet passes.

325,900 triangles total: 270,808 exterior, 55,092 inside. Review GLB: 20 material primitives, 11 materials, 2 mesh nodes, 17,826,080 bytes. These are reported costs, not caps. Actual draw calls and milliseconds are unmeasured. The station-map scene gate at 1080p and 4K has not run.

## Changed from the picture

- The rules main station occupies seven cells (centre plus its six neighbours), not three cells. The plan is fitted inside their union; the full footprint is three hex columns wide.
- The secondary spokes are offset from the docking arms; each tower has a bridge to a spoke or the bearing deck.
- The drum stack rises above the ring, toward the accepted beauty silhouette. Nine drums share one service shaft; the station does not gain a second core.
- The upper arm is angled 60 degrees into a blocked outer cell; a straight 90-degree arm would enter the unblocked notch between two cells. The real footprint outranks the concept plan.
- The loose arm is the six-unit fallback from the pack. Its collar sweeps in an isolated corridor below the ring and outside the core, on two torn conduits. A complete swept-volume check is still required before approval.
- The ring has six habitat modules over twelve bearing slots; slot 10 is open in the lower-right plan quadrant.
- Radiators use dense grooves and root manifolds, without a solar-cell grid.
- The design carries no weapons. lore_bible_r8.md describes the Reach and Hegemony but gives no station battery layout. The live defend objective has rules batteries; it is not the abandoned T2 visual target.
- The cause of the write-off stays off the player-facing sheet. The damage is permanent, not a running fire effect.
- Height is fitted to actual loaded capital hulls rather than the pack's provisional 32 units. The resulting proportions require a Board call before further building.

## Review order

1. `sheet_camera170.png`, then `sheet_compare170.png`, at true pixel size.
2. `sheet_compare_low.png`, beside the actual cruiser geometry.
3. The true top, side, underside and end sheets at one scale, then the inside sheet.
4. Board design review against the accepted beauty and plan; the sheet has no approval yet.
5. After acceptance: AI shape reference, production recipe contract, full fit and paint bake, station-map game captures and scene gate, outside check, then Ryan look before install.
