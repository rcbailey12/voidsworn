# CR4, The Honours Board

Issue 869, Ryan R286. Built from the settled notes and CR4.png at design revision 609262f9 on muse/issue-794.
Each picture burns in its actual source revision, working diff digest and stage. The game pictures use the RTX 5080
through the shared GPU watchdog. They are synthetic test profiles, never Ryan's save. Every review picture is at most
720 px tall. The matching provenance sidecars retain the source records and the pixels under the stamp.

| Picture | What it proves |
|---|---|
| [CR4 beside the 1080p build](CR4_compare_1920x1080.jpg) | The 12-admiral reference profile, all nine unserved visible, same lifetime figures and three honours blocks |
| [CR4 beside the 4K build](CR4_compare_3840x2160.jpg) | Actual 3840x2160 viewport, same layout and readable scale |
| [Fourth served at 1080p](CR4_four_served_1920x1080.jpg) | First row, then the fourth admiral and six figures on the second row |
| [Fourth served at 4K](CR4_four_served_3840x2160.jpg) | Same second-row behaviour at 3840x2160 |
| [Full roster, top](CR4_roster_1920x1080.jpg) | Three served and all six factions in the current 24-admiral game |
| [Full roster, lower](CR4_roster_lower_1920x1080.jpg) | Remaining unserved factions stay reachable by scrolling |
| [4K roster, top](CR4_roster_3840x2160.jpg) | Current roster at 4K |
| [4K roster, lower](CR4_roster_lower_3840x2160.jpg) | Current roster's lower groups at 4K |
| [Empty career](CR4_empty_1920x1080.jpg) | No invented service records; all unserved admirals retained |
| [Long record](CR4_long_1920x1080.jpg) | Wrapped name, multiple flagship names, seven-digit kill figure |
| [Close hover](CR4_close_hover_1920x1080.jpg) | The one ember action box and dark text on hover |
| [Medals](CR4_medals_1920x1080.jpg) | Existing medal contents in the new frame |
| [Titles](CR4_titles_1920x1080.jpg) | Existing earned-title rules and counts remain reachable |
| [History](CR4_history_1920x1080.jpg) | Existing empty-history state remains reachable |
| [Chronicle](CR4_chronicle_1920x1080.jpg) | Existing faction arc content and actions remain reachable |

The reference test profile deliberately limits the roster to CR4's original three factions. It uses real current names
for the two Ashfall entries the concept could not read. Its legacy lifetime totals are copied from the concept, including
the already documented difference between aggregate totals and the named records. The full-roster pictures show all 24
current admirals. No rules or save formats changed.

Differences from the picture: unserved entries keep their full rank and name in Barlow with doctrine beneath, instead of
the concept's smaller display type and inline doctrine. This keeps the full names readable at the 17 px floor. All earned
title counts stay visible. The background is a quiet opaque page; the decorative star speckles are omitted. Vex uses the
existing painting with a wide face crop. Kassar and Grax carry their actual recorded flagship names in the picture bands.
Extra factions and additional hero rows scroll below the fixed heading, tabs and lifetime band.

Generate: run res://ui/career/test/career_honours_test.gd with a renderer and -- --shots DIR. Without --shots it runs
headless. The separate career_readability_test.gd measures contrast on the actual composited backings.
