# Leg: Flash (Gemini, "Quick answers 3.5 Flash-Lite" selected and verified before and after; run Nov 17, 2026, signed in)

Recommendation Summary

Ryan floated a larger map combined with faster ships as a way to give battles more breathing room. However, the simulation data shows that expanding the canvas size fails to achieve a faster or snappier game, pushing move-only shares up to 24% and forcing a mandatory round-one approach delay.

Recommended Direction: Keep today's canvas dimensions (30 by 22 hexes) to preserve tactical pacing, but shift the design focus to shape and layout reweighting, specifically adopting the Hourglass shape as the standard layout.

Alternative 1: Corridor (for tight, direct engagements with minimal repositioning overhead).
Alternative 2: Archipelago (for decentralized duels with high tactical maneuvering room around asteroid clusters).

Detailed Analysis Across Core Criteria

1. Pace (First Contact and Move-Only Share)

The Bigger Board Failure: Testing a 38 by 26 canvas (609 hexes) caused median first contact to jump from 1 activation up to 12 activations. Giving all ships +1 or +2 speed did not fix this; instead of closing the gap faster, the extra speed dissipated into repositioning, keeping move-only shares high at 19% to 24% (compared to 13.1% today).

Shape Performance: All tested shapes on today's canvas maintain rapid contact (median first contact at 1 activation) while keeping move-only shares between 12.6% and 14.9%, matching baseline rhythm without empty setup turns.

2. Room to Manoeuvre and Flank

Hourglass: Features two open lobes joined by a pinched middle. This creates natural tactical choices: fleets can contest the narrow pinch directly or split to flank through the open lobes.

Corridor: Offers a shallow field (267 hexes) with minimal vertical room, leading to head-on clashes where flanking is restricted.

Archipelago: Provides scattered rock clusters, breaking battles into localized engagements and rewarding careful maneuvering around islands (reflected in its slightly higher move-only share of 14.9%).

3. Cohesion and Space-Like Feel

Avoiding Empty Space: The 38 by 26 bigger board felt visibly emptier, stretching fleets across dead zones.

The Shape Advantage: Working within today's 30 by 22 canvas keeps the arena dense enough to feel cohesive. The Hourglass shape provides open breathing room inside the lobes while introducing structured bottlenecks, avoiding both claustrophobic clutter and empty drift.

4. Interaction with Storms, Nebulas, and Asteroids

When sector conditions add storm, nebula, and debris blobs, a massive board exacerbates random dead zones.

The Hourglass and Archipelago layouts integrate terrain naturally: the pinched middle of the Hourglass acts as a natural crucible for nebulas or asteroid belts, while Archipelago clusters turn terrain into organic islands for cover and ambush tactics.

5. Defend and Station Case

On station defend maps, battles currently hit a 6-round objective clock with a high move-only share (16.4%) as attackers cross to the 19-hex station and its debris band.

Keeping today's canvas ensures attackers reach the station engagement zone efficiently. The Hourglass shape is particularly effective here, allowing defenders to control the pinched approach while attackers choose which lobe to push through.

6. Build Cost

Canvas Expansion (High Cost): Changing canvas size touches browser and Godot rule copies, deployment code, arena cuts, parity scenarios, and balance tuning.

Shape Reweighting (Low Cost): Shapes already exist in code (genTerrain in battle.js and its Godot twin). Adjusting encounter weights or introducing new shape branches requires minimal code changes and preserves existing balance simulations.

Comparison of Recommended Options

| Option | Board Shape and Size | First Contact (Median) | Move-Only Share | Primary Strategic Feel |
| Recommended: Hourglass | Pinched middle, two open lobes (326 hexes) | 1 activation | 13.4% | Balanced choice between direct chokepoint clashes and wide flanking lobes. |
| Alternative 1: Corridor | Shallow, wide field (267 hexes) | 1 activation | 12.6% | Direct, fast frontal engagements with restricted vertical movement. |
| Alternative 2: Archipelago | Scattered rock clusters (330 hexes) | 1 activation | 14.9% | Fragmented, tactical skirmishing with heavy emphasis on cover. |
