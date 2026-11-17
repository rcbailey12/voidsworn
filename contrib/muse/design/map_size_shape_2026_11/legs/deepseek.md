# Leg: DeepSeek (DeepThink ON and Search OFF, verified before and after; run Nov 17, 2026)

Recommendation: keep the current canvas, curate shape and arena mix

Do not enlarge the board. Keep the 30 by 22 canvas and the current deployment gap of about 16 hexes. Use open as the default shape, add hourglass as the main standard alternate, and shift standard arena weights away from square toward round and strip. This is a hybrid, not one tested cell, but every part is measured separately and it avoids the one change that clearly made pace worse.

Recommended direction

| Item | Recommendation | Measured numbers |
| Size | Keep 30 by 22, open strip 361 hexes | Open: first contact median 1, 10.0 rounds, 13.1% move-only |
| Shape | Open default, hourglass standard alternate | Hourglass: 326 hexes, first contact median 1, 10.3 rounds, 13.4% move-only |
| Layout | Cut square arena weight for standard rout battles, raise round and strip | Square belt: first contact median 9, 10.4 rounds, 11.9% move-only. Round belt: first contact median 0, 10.1 rounds, 10.3% move-only. Strip belt: first contact median 1 |
| Deployment | Keep today's opening gap, do not move fleets inward on a bigger board | Inward deployment on a bigger board was not measured, so it is not recommended |

Top-down picture: use today_open.png as the default picture and hourglass.png as the standard alternate. The open board has the belt running diagonally between two edge lines of fleets. The hourglass has two open lobes joined by a pinched middle, so fleets can swing wide in their own lobe or fight over the pinch.

Why this direction

- Pace: open and hourglass both put first contact at median 1 activation, with move-only at 13.1% and 13.4%. The slow outlier in today's game is the square arena at median 9 activations, so cutting its weight attacks the real pause without enlarging the field.
- Room and flank: hourglass gives room to manoeuvre in two lobes and a natural chokepoint in the middle. Corridor is shallower and reduces vertical flanking. Lanes creates gate fights. Archipelago creates the most repositioning at 14.9% move-only, but fights break into local duels around islands.
- Cohesive and space-like: a bigger board is visibly emptier and makes the fleets start about 24 hexes apart instead of about 16. Hourglass reads as one coherent region with a pinch. Archipelago and lanes risk feeling cluttered or artificial when terrain is stacked on top.
- Storm, nebula and asteroid terrain together: the shape tests pooled belt, station and storm map kinds, so terrain is present, but the pack does not measure a battle with storm, nebula and asteroid terrain all at once. Judgement: keep shapes sparse when sector conditions add terrain. Open and hourglass tolerate extra blobs better than archipelago or lanes. Do not make archipelago or lanes the default when all three terrain layers are in play.
- Defend and station: the 19-hex station ruling stands. Defend on the station strip already has first contact median 1 and the highest move-only share measured at 16.4%, ending at the 6-round objective clock. A bigger board would make the attacker cross more empty space, so it is the wrong lever. Hourglass may help the defender by creating a pinch, but the station sits at the centre and the pinch could crowd the 19-hex station and debris band. That needs a defend test before shipping. If it crowds, keep station maps open.
- Build cost: canvas size is the most expensive knob and the only one that made pace worse. Speed changes are cheap to enter but expensive to balance, and +1 or +2 speed did not fix first contact on the bigger board. Shape weights and existing generator branches are a small change by comparison. Arena weight changes are battle-start code in both copies, so they need parity checks but are cheaper than a canvas resize.

Rejected: bigger board, with or without speed

Bigger board only, 609 hexes: first contact median 12.5, 11.6 rounds, 24.2% move-only. Bigger board with all ships +1 speed: 12.0, 10.4, 20.4%. Bigger board with +2 speed: 12.0, 9.8, 19.2%. The +2 case only matches today's 10.0 rounds while nearly doubling move-only. This is not snappier; it is a full round of pure approach.

Alternative 1: Corridor as the standard shape

Corridor: 267 hexes, first contact median 1, 10.7 rounds, 12.6% move-only.

Top-down picture: corridor.png, a wide shallow field with top and bottom cut away.

This is the fastest-feeling shape by move-only share and it forces head-on fighting across the whole front. The cost is room: very little vertical space to flank, and a risk of feeling like a trench rather than open space. It may also become cramped when storm, nebula and asteroid terrain are stacked. Use it if the goal is quick head-on battles, not as the default for every encounter.

Alternative 2: Lanes as the standard shape

Lanes: 361 hexes, first contact median 1, 11.5 rounds, 13.8% move-only, with one 30-round timeout in 72 battles.

Top-down picture: lanes.png, a rock wall across the middle with two gaps.

This gives room and clear gate fights, but it produced the longest battles measured and the wall reads as artificial rather than space-like. It is a poor default when extra terrain is in play, and it is a poor fit for defend because a defended gap can stall the attacker. Keep it as a rare variant, not the main direction.

Numbers I would flag as missing, not wrong

No number in the pack looks wrong. The important gaps are:

- The options table tests shapes only on the strip arena, while the pack itself says most standard battles do not play on the strip. Shape effects on square and round arenas, especially square, are missing.
- Shape effects on defend and station maps are not measured separately. The station defend baseline is measured, but not with corridor, hourglass, lanes or archipelago.
- A battle with storm, nebula and asteroid terrain all active at once is not measured. The pooled belt, station and storm numbers are not the same thing.
- Moving deployment inward on a bigger board was not measured, so it cannot be recommended as a fix for the bigger-board pace problem.
