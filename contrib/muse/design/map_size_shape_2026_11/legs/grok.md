# Leg: Grok (Fast mode, verified before and after; run Nov 17, 2026)

Note: en dashes in numeric ranges in the model's answer were normalized to hyphens when filing, per the repo no-dash rule. Nothing else was changed.

Recommended direction: Keep the current 30-by-22 canvas and open strip deployment. Bias the shape table toward hourglass and corridor (with archipelago as a secondary option). Leave ship speeds alone.

This keeps the measured pace of today while giving maps more coherent structure and natural focal points once terrain is in play.

Why this direction

Pace stays close to the baseline numbers that already work. On the current board with open shape the pooled runs gave median first contact of 1 activation, mean 10.0 rounds, and 13.1% move-only. The shape variants on the same canvas stayed in the same band: contact still median 1, rounds 10.3-11.5, move-only 12.6-14.9%. Nothing in the data suggests the current size is the problem.

Bigger boards make the problem Ryan described worse. Moving to 38-by-26 (609 hexes) pushed first contact to a full round of activations (median 12-12.5) at every speed tested. Even +2 speed on every hull left move-only share at 19.2% and did not shorten battles below today's length. The extra space mostly became empty approach time rather than interesting manoeuvre. That directly contradicts the goal of maps that do not take ages to do anything.

The shapes add texture without costing tempo. Hourglass creates two lobes joined by a pinched middle that acts as a natural chokepoint; it works especially cleanly with station and planet maps because the pinch sits near the objective. Corridor produces a shallow, wide field that forces head-on pressure and leaves little room for pure flanking loops. Both keep the field feeling occupied rather than empty. Archipelago scatters rock islands into clusters with channels; it raises repositioning a little (14.9% move-only) but breaks fights into local duels that feel more space-like once nebula and debris are layered on top.

With storms, nebulas and asteroids all active the current canvas still has enough room for the terrain generators to place meaningful features without the board feeling sparse. The bigger canvas looked emptier in the seed-1000 renders even before extra blobs were added. Defend and the 19-hex station remain as ruled: the attacker still has a measured crossing to make, but the hourglass pinch or corridor edges give the defender clearer places to hold without stretching the board.

Build cost is low. Canvas size, deployment columns and arena cuts stay untouched. Shapes already exist in both rule copies; the change is only which ones roll and at what weights. No speed table changes, no parity scenario rewrites, no balance cascade.

How it feels in play

Fleets still open roughly 16 hexes apart and make contact after one move plus long-gun range. The map is no longer a featureless rectangle; the pinch or the shallow corridor gives both sides a clear geographic problem to solve while the terrain blobs (asteroid band, nebula, debris) sit inside a space that still feels dense enough to be a battlefield rather than open void. Room to flank exists inside each lobe or along the corridor edges, but pure circling is limited, which keeps the game moving.

Alternatives (at most two)

1. Same canvas and speeds, but weight lanes higher instead of (or alongside) hourglass.
Lanes produced the longest measured battles (11.5 mean rounds) because the two gaps become contested gates. This is a deliberate slower, more positional feel. It still avoids the empty approach of a bigger board. Use only if the design wants more "fight for the choke" than the lobe structure of hourglass.

2. Keep current size and shapes, but move strip deployment columns inward by 2-3 hexes on both sides (opening gap ~12 instead of ~16).
This was not measured in the pack. It is the cheapest possible tweak that shortens the already-short approach without touching canvas size or speeds. It would only be worth testing if human play still feels the opening is too long after the shape weights are adjusted. Do not combine it with a bigger board; the data already shows extra space is the wrong direction.

The size experiments are conclusive enough: bigger maps plus faster ships do not deliver snappier battles. Stick with the canvas that already produces contact in one activation, use the existing shape generators to give the board structure, and keep the station ruling untouched. That is the lowest-cost path that matches the measured numbers and the stated design goals.
