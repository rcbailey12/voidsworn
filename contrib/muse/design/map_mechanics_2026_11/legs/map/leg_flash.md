# Leg: Flash (Gemini, "Quick answers 3.5 Flash-Lite", signed in)
# Whole-map design round, Nov 17, 2026. Gate verified before and after by the browser runner.
# Answer reproduced verbatim as returned.

1. Diagnosis

The map does not matter today because of monolithic value convergence. Every existing encounter funnels all tactical value into a single spatial singularity (one station, one relay, one flagship, or the mutual center of the enemy fleet). Because the bot's evaluation function scores position strictly relative to the nearest active value point, and because opposing fleets start on parallel lines pointing directly at that point, the shortest vector is mathematically dominant. Speed and range are compressed because ships have zero incentive to diverge from the direct collision vector; the "empty margin" is simply the penalty of an oversized board that lacks lateral or multi-point pulling mechanics.

1. Design principles

- Distributed Value (Multi-Locus Objectives): No battle should feature a single point of decision. Victory must require holding or contesting at least two non-adjacent spatial zones simultaneously.
- Geometric Friction: The direct center vector between deployments must be the worst tactical route (via terrain, hazards, or denial zones), forcing fleets to deploy outward into the margins.
- Asymmetric Temporal Staging: Fleets must arrive in echelons rather than all-at-once blocks, preventing immediate turn-1 kinetic convergence.

1. Proposals, smallest first

- Proposal A: Tri-Relay Grid (Data/Objective Change)
  - What changes: Split the single objective (e.g., hold or intercept) into 3 distinct scoring points configured in a triangular or wide lateral spread across the map, using existing objective hexes.
  - Impact: Forces fleets to split forces or maneuver laterally. Coverage on 38x26 maps rises toward 0.20+, first contact is staggered across multiple vectors, and move-only activations increase temporarily as fleets reposition to the spread points - but they are now purposeful repositioning moves, not dead approach time.
  - Feel: Speed becomes the ability to contest two nodes at once; range becomes the ability to project threat across nodes without committing to them.
  - Sim status: Testable now in sim (uses existing objective scoring routines).
- Proposal B: Hazard Lanes / Nebula Chokes (Terrain Data Change)
  - What changes: Place a longitudinal strip of heavy terrain/hazard hexes down the exact center 30% of the map, forcing a split into two flank lanes using existing terrain generation.
  - Impact: Eliminates the dead-center death ball. Pushes deployment and movement to the outer flanks, immediately increasing lateral coverage. First contact is delayed by 1-2 activations as fleets route around the choke, but move-only activations are reduced because the flanking routes are shorter and more direct.
  - Feel: Speed is felt as the ability to outflank through a lane; range is felt as cross-lane fire over the hazard.
  - Sim status: Testable now in sim (uses current terrain data and bot pathfinding weights).
- Proposal C: Echeloned Reserves (Rules & Deployment Change)
  - What changes: Force fleet composition to split: 50% vanguard deployed forward, 50% reserved to enter from a rear or flank edge at round 2-3, reusing the existing reserve flag.
  - Impact: Smooths out the first-contact spike, creates shifting tactical fronts, and rewards speed/range as the second wave arrives to exploit the first wave's position. Coverage rises as the reserve wave enters from a different vector.
  - Feel: Speed is felt as the second wave's ability to arrive in time; range is felt as the vanguard's ability to hold until reinforcements arrive.
  - Sim status: Testable with one stated bot term (bot evaluation weights prioritizing reserve entry hexes as secondary objectives).

1. The deployment question specifically

Yes, deployment must become an active strategic choice.
- Form: Players select from three deployment templates per scenario before loading: Line Vanguard (standard), Flank Split (two groups on opposite edges), and Deep Reserve (50% held back to enter later). Each template has fixed hex assignments, so it is a data choice, not a free-form placement UI.
- What stops a dominant choice: Objective design. If objectives are multi-locus (Proposal A), Line Vanguard cannot cover all points, Flank Split cannot concentrate force, and Deep Reserve risks losing early nodes. The correct template depends on the objective layout and enemy composition, preventing a single solved choice.

1. The hunt problem fix

Fix the degenerate chase with the smallest possible change: Quarry Lead & Escort Screen. Deploy the enemy flagship at the far edge with a minimum 10-hex lead from the player's deployment line, and place 2 escorts directly in front of it. Add one rule: the flagship cannot be targeted until round 3, forcing the player to fight through the screen first. This is a data change to deployment coordinates plus a single targeting gate; it creates a real chase without changing hunt's win condition or timer.

1. Refusals

- Global Speed/Range Buffs: Refused. The sweeps proved they only compress combat duration and ranges, leaving coverage unchanged.
- Random Weather / Dynamic Events: Refused. Introduces non-deterministic noise that breaks the balance sim and violates the owner's constraint.
- Bigger Maps: Refused. Per owner constraint; larger maps without distributed value only expand the empty margin.

1. Your single first build

The First Build: The Tri-Relay Distributed Objective layout (Proposal A), setting 3 scoring nodes in a triangular spread across the map.
- Success Metric: Mean map coverage on 38x26 maps rising from the current baseline (~0.12) to above 0.20, with first contact staggered across at least 2 distinct vectors and move-only activations remaining below 25%.
