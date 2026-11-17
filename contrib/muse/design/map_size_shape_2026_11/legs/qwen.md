# Leg: Qwen (Qwen3.8-Max, selector verified before and header after, single answer, no A/B; run Nov 17, 2026)

Recommendation: map size, shape and layout (Voidsworn issue 1004)

Filed 18 Nov 2026. One direction, two alternatives, all grounded in the evidence pack unless marked as judgement.

Recommended direction: shape over size, hourglass leading

Keep the 30-by-22 canvas. Do not enlarge it. Shift the shape-weight table so that hourglass becomes the most common board shape for standard encounters (rout, hold, and the generic battle roll), with open dropping to a minority share. Keep strip deployment geometry as it is today (player columns 5 to 7, enemy columns 22 to 24, roughly 16 hexes apart).

Why this direction, point by point:

Pace. The hourglass measured identically to open on every pace number that matters: first contact median 1 activation, mean rounds 10.3 (against 10.0 for open), move-only share 13.4% (against 13.1%). The differences are within the noise of 24 paired battles. Nothing about the pinch slows the game down, because the fleets still start 16 hexes apart and the pinch sits between them, not behind them. By contrast, the only option that hurt pace was the bigger board, where first contact jumped to a median of 12 activations and move-only share nearly doubled to 19 to 24%. Even +2 speed on the big board only matched today's round count and still left contact waiting a full round. The data says plainly: size is the wrong knob.

Room to manoeuvre and flank. The hourglass gives two open lobes, each roughly the size of today's playable field divided between them. A fleet can swing wide inside its own lobe, contest the pinch directly, or split forces between both. This is more manoeuvre room than corridor (267 hexes, almost no vertical space to flank) and more structured than open (where flanking is possible but nothing on the board rewards it). The pinch is a place a player can choose to fight over or go around, which is a decision, not a constraint.

Cohesive and space-like, not empty or cluttered. This is judgement, but it follows from the geometry. The two lobes joined by a neck read as one place - a strait, a gap between debris fields, a gravitational bottleneck. The open board today is functional but has no focal point; the big board (609 hexes) is visibly emptier in the generator output and the numbers confirm the emptiness costs pace. The hourglass puts structure in the middle of the board where the eye goes, and leaves the lobes open enough that ships are not bumping into rocks every activation. Archipelago, by contrast, measured the highest move-only share of any shape (14.9%) because cover is everywhere and fights fragment into local duels; it is the most cluttered option tested.

Terrain interplay (storm, nebula, asteroids together). Not directly measured as a combined case; this is judgement built on the generator description. The hourglass pinch is a natural anchor for the station, the planet intrusion, or a dense asteroid band, because those features already want a centre. Nebula blobs in the lobes create approach uncertainty without blocking the whole field. Storm blobs sweeping across one lobe force a fleet to time its push through the pinch. On the belt map specifically, the diagonal asteroid band would cross the pinch or clip one lobe edge, giving the belt a different tactical read than it has on open. None of this requires new generator code; the terrain themes already scatter their features across the playable hexes, and the shape mask already clips them.

Defend and the station case. The 19-hex station ruling stands. On the strip today, defend ends at the 6-round clock with a 16.4% move-only share, the highest measured, because the attacker spends its early turns crossing open hexes to reach the station and its debris ring. Placing the station at or near the hourglass pinch (judgement, not measured) gives the attacker a defined approach corridor instead of a wide open transit. The defender's guns and debris band still cover the pinch edges. The attacker still has the option to swing wide through a lobe, but doing so costs time against the 6-round clock, which is a meaningful choice rather than a slog. This should lower the move-only share in defend by giving the attacker a reason to commit to an approach on turn one rather than repositioning. This specific interaction was NOT measured and should be tested before shipping.

Build cost. Shapes already exist in both the browser and Godot copies (genTerrain in battle.js and its Godot twin). Changing the shape-weight table in ENC_ARENA is a small data edit in each copy plus parity-scenario updates. No new generator branch is needed for hourglass; it is already implemented. This is the cheapest lever measured, and the only one that did not make pace worse.

Alternative 1: archipelago as a secondary shape for belt and graveyard encounters

Weight archipelago higher specifically when the map kind is belt or graveyard. Belt already scatters asteroids; graveyard already scatters hulks and debris. Archipelago's rock islands in clusters extend that logic into the board shape itself, so the terrain theme and the board shape reinforce each other instead of fighting.

Pace is acceptable: first contact median 1, mean rounds 10.9, move-only 14.9%. The move-only number is the highest of the shapes tested, but the extra repositioning is cover-based (ships ducking behind islands, re-angling for a shot) rather than empty transit. Rounds are 0.9 longer than open, which is noticeable but not the 11.5-round drag that lanes produced.

The risk is clutter. With a belt asteroid band, nebula blobs, and archipelago rocks all on one board, the playable channels could feel cramped. This is judgement. If playtesting shows the combined density is too high, drop archipelago back to its current weight and keep hourglass as the sole shape change.

Build cost is the same as the primary recommendation: a weight-table edit, no new code.

Alternative 2: corridor weighting for routs only

Routs are chase fights. The corridor shape (267 hexes, the shallowest field measured) removes vertical flanking room and forces head-on engagement. First contact median 1, mean rounds 10.7, move-only 12.6% - the lowest move-only of any shape tested, meaning ships are shooting almost every activation instead of repositioning. That is the right tempo for a rout, where one fleet is running and the other is catching it.

Today, ENC_ARENA gives rout a 30% strip / 35% square / 35% round split. The square-arena approach is the slowest measured configuration (first contact median 9 activations). Routing a share of routs onto corridor-shaped strips would cut that slow approach out of the rout experience entirely.

Build cost: again a weight-table edit. The corridor shape already exists. The only caveat is that corridor on a station or planet map is likely too cramped (the planet disc intruding from one edge into a 267-hex field leaves very little room). Restrict corridor weighting to belt, storm, and graveyard routs. This restriction is judgement.

What I am not recommending and why

Bigger board (38 by 26), with or without speed bumps. Every number in the pack argues against it. First contact tripled from 1 to 12 activations. Move-only share nearly doubled. +1 speed moved contact from 12.5 to 12.0 and cut move-only from 24.2% to 20.4%, which is not enough to recover the lost pace. +2 speed matched today's round count (9.8 vs 10.0) but still left contact at 12 and move-only at 19.2%. The bigger board made every battle start with a full round of pure approach, which is the exact feeling Ryan wants to avoid. It is also the most expensive change measured: both rule copies, deployment code, arena cuts, parity scenarios, and every balance sim.

Lanes as a primary shape. Lanes produced the longest mean rounds of anything tested (11.5) and the only 30-round timeout in 72 battles. The two gaps become gates that stall a fight. This is a texture some players may enjoy occasionally, but it is the wrong default for a game that should feel fast and spatial.

A blanket speed increase. Speed is a data.js number and cheap to change, but the pack shows it does not fix the problem it is aimed at. On the bigger board, +2 speed still left contact at 12. On today's board, speed is already 3 to 5 for most hulls and contact is 1 activation; there is nothing to fix. A fleet-wide speed change also interacts with torpedo speeds, ramming, admirals, and modules, making it expensive to balance for no measured gain.

Numbers I think are missing or worth checking

1. Hourglass plus station map, measured. The pack measures hourglass on belt, station, and storm pooled, but does not break out the station case alone. The defend recommendation above (station at the pinch) is judgement until it is simulated. Run 24 paired defend battles on hourglass-strip with the station at the pinch and compare move-only share and round outcomes against today's 16.4% and 6-round clock.

2. Square arena with shapes applied. The square-arena approach problem (first contact median 9) is the single slowest configuration measured. The shape tests in the pack all use the strip arena. If square-arena battles get an hourglass or corridor mask, does the approach problem persist? This matters because ENC_ARENA gives square a 35% weight in routs and it appears in holds.

3. Archipelago combined with belt terrain at full sector-condition density. The pack pools belt, station, and storm for the shape tests, but sector conditions add extra storm, nebula, and debris blobs on top. The combined density on an archipelago board at high sector conditions is unmeasured and is the main risk for alternative 1.

4. Deployment pulled inward on any shape. The pack notes this is possible but was not measured. On hourglass, starting fleets at columns 6 to 8 and 21 to 23 (one hex inward) would tighten the gap to roughly 14 hexes and might make the pinch contest start one activation earlier. This is a small code change in battle-start for both copies and worth a 24-battle paired test.

Summary

|  | Size | Shape | Pace effect | Build cost |
| Recommended | 30 by 22 (today) | Hourglass leading | Neutral (contact 1, move-only 13.4%) | Weight-table edit, both copies |
| Alt 1 | 30 by 22 | Archipelago for belt/graveyard | Slight drag (rounds 10.9, move-only 14.9%) | Weight-table edit |
| Alt 2 | 30 by 22 | Corridor for routs | Slight gain (move-only 12.6%) | Weight-table edit |
| Rejected | 38 by 26 | Any | Contact 12, move-only 19 to 24% | Most expensive change measured |

The map should feel like a place, not a parking lot. The hourglass makes one. It costs almost nothing to ship, it does not slow the game down, and it gives storm, nebula, and asteroid terrain something to hang off. Start there, measure the station case, and tune the weights from what the table returns.
