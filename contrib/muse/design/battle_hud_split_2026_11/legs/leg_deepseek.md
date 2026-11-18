# Leg: DeepSeek (DeepThink ON and Search OFF, verified before and after; run Nov 17, 2026)

Code name: KEEL

I would adopt the seeded LEDGER SPLIT and improve it. KEEL splits the rail into a small top-left context cluster, the existing top-right cluster, and one bottom decision shelf. It avoids a full-width top bar and avoids COMMAND DECK's floating bottom-centre strip. The board keeps one clear middle field. No game code changes proposed.

Placement table

| Item | Where it goes in KEEL |
| 1. Turn header: Round 1, Your turn, 3 of 3 ships to act | Top-left veil, x=40 y=32 w=560 h=60. Round 1 on line one, Your turn in ember plus 3 of 3 on line two. |
| 2. Objective: break their fleet | Top-left veil, x=40 y=96 w=560 h=22, under the turn header. |
| 3. Ship name: UNYIELDING OATH | Bottom shelf column A, x=40 y=880 w=360 h=36, Big Shoulders at 34 px. |
| 4. Ship class: Vigil-class cruiser | Column A, x=40 y=918 w=360 h=18, Barlow. |
| 5. Hull 135 / 135, Move 0 of 4 | Column A, x=40 y=940 w=360 h=20, one line. |
| 6. Shield cross, four facings at 20 | Column A, x=40 y=964 w=360 h=40, Glacier blue only. |
| 7. Status line: enemy focusing fire | Column A, x=40 y=1008 w=360 h=36, two lines at 17 px. Hover or key shows the full sentence if it wraps. |
| 8. Guns table, three rows | Bottom shelf column B, x=416 y=880 w=340, rows at y=880, y=910, y=940, each h=26. |
| 9. Target: FLEET MARSHAL PETRA VALK | Column C, x=772 y=880 w=390 h=24. Nemesis red only when the target is the Nemesis. |
| 10. Odds and damage split | Column C, x=772 y=908 w=390 h=20 for 92% to hit; x=772 y=932 w=390 h=36 for the damage split. |
| 11. FIRE box: FIRE THE OATH LANCE, Enter | Column D, x=1200 y=880 w=320 h=64. This is the one box, ember outline. |
| 12. Orders: Brace B, Concentrated fire, Turn Q E | Column D, x=1180 y=984 w=360 h=22. |
| 13. Command: Command, Fire for effect C, End ship Space | Column D, x=1180 y=1010 w=360 h=22. |
| 14. Fleet: three ships, acting ship ember bar | Bottom-most strip, x=40 y=1040 w=1500 h=24, one horizontal line with three entries. Acting ship gets the ember bar before its name. |
| Tree prompt card | Occasional local veil under top-left: x=40 y=136 w=560 h=96. Question plus options, one key per option. Disappears after choice. |
| Retreat | Occasional low-emphasis text control above the log: x=1560 y=948 w=320 h=22, right aligned, one key. |
| Phase banner, for example enemy turn | Occasional top-centre veil: x=620 y=32 w=820 h=56. Centred phase text, no controls, temporary. |
| Hover detail / SAY LESS | Kept. Hover or key on a gun row shows full range and state detail. Hover on a shield facing shows exact value. Hover on a fleet entry shows ship summary. Nothing is deleted. |
| Enemy line, Heat, Menu Esc, Nemesis panel | Kept top right inside the existing cluster: x=1460 y=32 w=420 h=96. |
| Log L plus last three lines | Kept bottom right inside the bottom shelf: x=1560 y=984 w=320 h=72. |

Geometry at 1920 by 1080

Bottom veil: x=0 y=864 w=1920 h=216. It fades upward over 24 px above y=864. Words sit on the veil. No solid panel except the FIRE box.
Top-left veil: x=40 y=32 w=560 h=96.
Top-right veil: x=1460 y=32 w=420 h=96.
Middle clear field: roughly y=128 to y=840, full width, plus the top centre gap between the two top clusters.
Bottom shelf columns: A x=40 w=360; B x=416 w=340; C x=772 w=390; D x=1180 w=360; log x=1560 w=320. Fleet strip runs under A to D at y=1040.

Screen share

| Area | Hard veil | With 24 px fade | Today |
| Bottom shelf | 20.0% | about 22.2% | 0% |
| Top clusters | 4.5% | about 5.7% | about 3% corners |
| Total | about 24.5% | about 27.9% | about 33% |

So KEEL covers about 5 percentage points less effective screen than today, and more importantly it replaces the full-height left band with one clear middle field. The hard veil number is 24.5%; the fade number is the fair comparison to today's 30% faded left band plus corners.

How the decision order reads

The top-left cluster is context: turn, then objective. The eye then drops to the bottom shelf and travels left to right. Ship name, class, hull and move, shield cross, status line sit in column A, stacked in decision order. The eye moves right to the guns table. It moves right again to the target, then the odds and damage split. It moves right to the FIRE box. It drops down the same column to orders, then Command. The fleet strip is bottom-most, after Command, as the foot of the old rail. There is no hunting back to the left. The top-right enemy, Heat and Nemesis cluster and the bottom-right log stay peripheral, as today.

1440p and 4K

At 1440p, k=1.33. The bottom shelf becomes about 287 px high, the top clusters about 128 px high, and all column widths scale by 1.33. The share of the screen is unchanged: about 20.0% hard for the bottom shelf and about 4.5% hard for the top clusters. Text gets more headroom: 17 px design text becomes about 22.6 px, and the 34 px ship name becomes about 45 px.
At 4K, k=2.0. The bottom shelf becomes about 432 px high, top clusters about 192 px high. Share is still unchanged. Fine detail is easier: the shield cross is about 80 px high, and 17 px text becomes 34 px. No reflow is needed at 1440p or 4K.
At a small or short window near k=0.6, the 17 px text floor binds. KEEL would need a compact mode: either the bottom shelf grows taller in actual pixels, raising its share, or orders and Command move into a second small bottom-left veil. I would not pretend the two-tier shelf stays honest at k=0.6 without that fallback.

What gets worse, honestly

The bottom shelf blocks the lower board across the full width. Units or effects at the bottom edge may need a hover or camera nudge. Today the left flank is blocked full height instead; neither layout is free.
The bottom shelf is denser than the old rail. Long status, target and damage strings will wrap at 17 px, and the target name must stay short enough for column C.
The tree prompt under the top-left cluster covers upper-left board while it is open. It is temporary, but it is not free.
Retreat is deliberately low emphasis above the log. It is reachable in one key or hover, but less prominent than on the rail.
Build cost is moderate, not trivial: existing HUD widgets get reparented into two shelves, and the shield cross and guns table need reflow. It is still a layout move inside the existing HUD code, not a new system.

Occasional items

Tree prompt: opens as a local veil card directly under the top-left cluster, x=40 y=136 w=560 h=96. Question on the first line, up to three options below, one key each. It does not move the bottom shelf.
Retreat: right-aligned text control above the log at x=1560 y=948. One key or hover. It stays out of the decision order until needed.
Phase banner: temporary top-centre veil at x=620 y=32 w=820 h=56, centred text such as ENEMY TURN. It uses the clear top centre gap and does not push the top clusters.

Pick and seed comparison

Pick KEEL over both seeds. LEDGER SPLIT was close, but a full-width top bar dims the top of the board for no decision benefit. COMMAND DECK fragments the free space into a floating centre strip plus corner cards, and it puts ship, guns and FIRE far from the top context. KEEL keeps one clear middle field and one left-to-right decision shelf.

Pack flags

The pack's 30% left band is a faded area, not the 380 px column alone; the column is 19.8% of width. I compared effective fade area to effective fade area. Also, the pack says the top-right cluster and log are roughly 3% together; my top-right hard veil is about 1.9% and the log sits inside the bottom shelf, so there is no double count. Those are rounding differences, not errors.
