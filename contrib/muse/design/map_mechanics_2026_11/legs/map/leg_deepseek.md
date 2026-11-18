# Leg: DeepSeek (DeepThink ON, Search OFF at submission, both verified after)
# Whole-map design round, Nov 17, 2026. Answer reproduced verbatim as returned.

1. Diagnosis: The map does not matter because every encounter still defines value as one attractor: one fleet to kill, one station, one relay, one exit edge, one interception lane. Deployment is a line on one axis, and the bot's objective term pulls both sides toward the same point. Speed and range are then local modifiers on the same convergence; they cannot create a second place worth being. Bigger maps only add empty margin before that convergence. The probe evidence supports this: intercept's combined coverage is above rout on 38x26, but player coverage is only 0.063, so it is one forced enemy march, not map use. Chair's reading is mostly right; I would only say intercept is the exception that proves the rule.

2. Design principles:

- No single point of value. Every encounter must present either 2+ simultaneous sites or a moving site/route with partial progress.
- Speed must buy tempo between places; range must buy lane/zone denial, not just more plinking. Measure coverage, second contact, site flips, and move-only activations.
- Deployment must be commitment under uncertainty, not a free optimal band.
- Reuse objective/deployment/reserve/terrain data first. Any bot change should be one objective-distance term, not a new AI.

3. Proposals, smallest first:

- Terrain lane curation, data-only. Change map data so each existing site has 2-3 separated approach lanes and terrain between sites, not just terrain near the site. Reuses terrain. Testable now. Expected effect alone: coverage +0.01-0.02, move-only +2-4 points; first contact unchanged. Speed/range feel local only. Size: 1 pass, 1-2 map-data files. This is support, not the fix.
- Rout/ambush delayed reserve wave, deployment + reserves. Put 1-2 ships per side in reserve and commit them at round 3 from a lateral edge, not both close-in like current ambush. Reuses reserves and ambush split deployment. Needs one bot term: reserve destination = nearest uncontested site/threat. Expected: coverage +0.02-0.04, move-only +3-8 points, a real second contact. Speed lets you defeat in detail; range lets you engage before waves merge. Testable with one stated bot term. Size: 1-2 passes, 2 files plus parity data.
- Plural objective sites, objective data + one bot term. Add sites[] and "control/destroy N of M" scoring. Apply first to hold as 3 relays, defend as station + outposts, intercept as 2-3 transport groups on separate lanes, break as 2 exit gates. Reuses existing objective progress logic. Bot term: objective score = sum over active sites of weighted distance, so different ships can choose different sites. Expected: +0.03-0.06 absolute coverage on 38x26, both sides' coverage up, move-only +5-10 points; first contact unchanged or earlier. Speed becomes reinforcement/switch tempo; range becomes lane denial. Testable with one bot term. Size: 2 passes, 3-4 files including parity.
- Patrol/moving relay, small new rule. Hold/defend relay moves among 3 hexes every 3 rounds. Reuses hold. Bot already retargets current objective, so testable now. Expected: coverage rises over battle time, move-only up; first contact at first site. Speed is rotation tempo; range is covering the route. Size: 1-2 passes, 2 files.

4. Deployment: Yes, but only after plural sites; otherwise it is a solved band-depth choice. Form: 2-3 simultaneous hidden packages combining depth band, lateral split, and reserve timing. Example: near/left, far/right, center/reserve-heavy. What stops dominance: objective geometry makes near good for one site and far good for another; enemy package is hidden until commit; reserves are a timed commitment. Test with one bot package-evaluation term. Without plural sites, I would refuse deployment choice as the main fix.

5. Hunt: The smallest defensible fix is deployment + retreat rule. Deploy the flagship on the far edge, out of immediate reach, with 2 escorts; until round 6 it moves at full speed away from the nearest hunter toward its exit. Reuse hunt's existing jump-out timer and intercept-style movement. Needs one bot term: quarry survival/exit distance. Expected: first shot activation 6-10 instead of 0, rounds 5-7 instead of 2-3, hunter win rate 6-9/12 instead of 12/12, coverage above 0.08. Size: 1 pass deployment + 1 small bot term.

6. Refusals:

- No bigger maps or global speed/range buffs; the sweeps show they change closing phase, not spatial value.
- No terrain-only fix; one site remains one attractor.
- No free deployment bands without hidden/opposed choice; they solve to one dominant package.
- No new morale/supply/fog subsystem before plural sites; parity cost and bot untestable.
- No random events as structure; owner ruled it out and it would not make value spatial.

7. Your single first build: Plural objective sites. Add sites[] and the summed objective-distance bot term, then apply it to hold as 3 relays and intercept as 2 transport lanes. It worked if on 38x26 hold/intercept median combined coverage is at least 0.16, both sides exceed 0.08, move-only is at least 28%, and asymmetric-speed win rates sit around 6-8/12 rather than 12/12. If only enemy coverage rises, it is intercept again and I would reject it.
