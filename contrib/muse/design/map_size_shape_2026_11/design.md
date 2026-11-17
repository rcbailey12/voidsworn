# Map size and shape: design study (issue 1004)

Owner: muse. Code measured at main db4885e1632f78ebed9fd54535c49e8678072da3 (Nov 17, 2026). Council: blind Rey leg first, then DeepSeek, Qwen, Grok and Flash legs, all run under their model gates on Nov 17, 2026 (DeepSeek DeepThink on and Search off, Qwen selector Qwen3.8-Max before and header after, Grok Fast, Gemini "Quick answers 3.5 Flash-Lite" selected, each verified at both ends). Chair: Rey. Legs are filed in legs/ and were written from the evidence pack alone (evidence_pack.md). Two follow-up measurements the legs asked for were run by the chair after the legs were written; they are marked as chair follow-ups where they appear, and the legs did not see them.

## The answer in one paragraph

Do not make the board bigger and do not make ships faster. Both were measured and both fail on the terms Ryan set: a 38 by 26 board adds a full round of pure approach to every battle (first contact goes from 1 activation to 12) and speed rises of +1 and +2 do not buy it back. The room Ryan wants is already available as shape: the shaped fields that exist in the generator today (hourglass, corridor, archipelago) cost nothing in pace and give each map a geography. The recommendation is to keep the 30 by 22 canvas and today's speeds, and spend the change on the shape and arena mix. The one measured way to have a genuinely bigger field is to deploy the fleets inward on it (Alternative 2), and it is priced honestly below.

## Method

The game's own simulator (sim3d.js) at the code state above, bot against bot with alternating activations, the way the game plays by default. Mirror fleets, 6 against 6 (Vanguard, 2 Interdictors, 2 Pickets, Dominion), sector 2, paired seeds 1000 to 1023 (24 battles per configuration, 72 per pooled option). Metrics: turns to first contact (capital activations completed before the first shot; 12 is a full round at 6 against 6), mean battle rounds, and move-only share (activations that moved and never fired, as a share of all capital activations). Win rates are not used: the two bots are different pilots. Limits: bots, not humans; one fleet pairing; human play would raise move-only shares everywhere, but the comparisons are paired and should hold in direction. Proposals only: nothing in battle.js, rules.gd or the game was changed; size and deployment variants were tested in local copies changing board settings only.

## Baseline: today

Strip arena, shape open, by map kind (24 battles each): belt, first contact median 1 activation, 10.7 rounds, move-only 15.4%. Station: 2, 9.8, 14.0%. Planet: 1, 9.7, 9.3%. Storm: 1, 9.6, 9.9%. Graveyard: 0.5, 10.0, 10.0%.

The other arenas matter more than the strip: a rout rolls strip 30%, square 35%, round 35% (ENC_ARENA). On belt, the square arena's approach is the slowest standard configuration measured (first contact median 9 activations, 10.4 rounds, move-only 11.9%); the round arena is instant (median 0, 10.1 rounds, 10.3%).

Defend on the station map (strip): battles end at the 6-round objective clock, first contact median 1, move-only share 16.4%, the highest of anything measured. The attacker spends its turns crossing to the 19-hex station (R314) and its debris band.

Reading: contact on the strip is nearly instant because the opening gap of about 16 hexes is roughly one move plus one long gun. The slow-feeling parts of today's game are the square approach, defend's crossing, and the roughly 1 in 8 activations everywhere spent only moving.

## Options measured (belt, station and storm pooled, 72 paired battles each, strip arena)

| Option | Board hexes | First contact (median) | Mean rounds | Move-only share |
|---|---|---|---|---|
| Today (30 by 22) | 361 | 1 | 10.0 | 13.1% |
| Bigger board only (38 by 26) | 609 | 12.5 | 11.6 | 24.2% |
| Bigger board, all ships +1 speed | 609 | 12.0 | 10.4 | 20.4% |
| Bigger board, all ships +2 speed | 609 | 12.0 | 9.8 | 19.2% |
| Corridor shape (today's canvas) | 267 | 1 | 10.7 | 12.6% |
| Hourglass shape (today's canvas) | 326 | 1 | 10.3 | 13.4% |
| Lanes shape (today's canvas) | 361 | 1 | 11.5 | 13.8% |
| Archipelago shape (today's canvas) | 330 | 1 | 10.9 | 14.9% |

## Recommendation: SHAPED FIELDS (keep the canvas, curate the shapes and arenas)

Picture: pictures/hourglass.png (the hourglass field, seed 1000, belt).

Keep the 30 by 22 canvas, today's hull speeds and today's deployment gap. Change what rolls:

1. Hourglass becomes a standard shape alongside open, not a rare roll: two lobes and a pinched middle give every map a focal point and a flank-or-choke decision at zero pace cost (contact 1, rounds 10.3, move-only 13.4%, against open's 1, 10.0, 13.1%).
2. Shape by encounter flavour: corridor weighted for routs (the shallowest field, lowest move-only at 12.6%, head-on tempo suits a chase), archipelago weighted for belt and graveyard (islands extend what those maps already do; accept its 14.9% move-only as cover play, not transit).
3. Cut the square arena's weight for standard routs and give the share to strip and round. The square approach (contact median 9) is the one measured delay in the standard game; round and strip start at 0 and 1.
4. Lanes stays a rare variant only. It produced the longest battles (11.5 rounds) and the study's only 30-round timeout; as a staple it drags, and a defended gap is a poor fit for defend.

All five legs land here in substance. DeepSeek and the blind Rey leg both name the square approach as the real pace problem; Qwen, Grok and Flash all lead with hourglass on the current canvas; nobody defends the bigger board or a speed rise. Build cost is the lowest of anything studied: shape weights and arena weights in both rule copies, plus parity scenarios. No canvas, deployment or speed-table change. The 19-hex station ruling (R314) is untouched.

## Alternative 1: OPEN PLUS (the conservative subset)

Picture: pictures/today_open.png (today's board).

Open stays the default shape; hourglass is added as the one standard alternate; only the arena weights shift (square down for routs). This is DeepSeek's recommended form. It buys most of the texture gain for the smallest possible diff, and it is the right pick if the Board wants one change at a time: per-encounter shape weighting (corridor for routs, archipelago for belt and graveyard) can follow once hourglass has bedded in. Numbers are the open and hourglass rows above.

## Alternative 2: WIDE FIELD, INWARD START (the bigger board, done the measured way)

Picture: pictures/big_field_inward.png (38 by 26 canvas, fleets deployed inward at today's gap).

Chair follow-up measurement (the legs asked for this run; it was not in their pack): the 38 by 26 canvas with both fleets deployed inward so the opening gap stays at about 16 hexes, belt, station and storm pooled, 72 paired battles. First contact median 0 activations, 9.8 rounds, move-only share 5.3%, the best pace numbers in the whole study. The extra room stops being approach distance and becomes manoeuvre room: ships spend their moves getting to firing positions instead of crossing.

This is the only honest route to a bigger-feeling map, and its costs are real: the full canvas change in both rule copies (deployment code, arena cuts, parity scenarios, balance sims), plus an aesthetic risk the sim cannot judge, which is that the outer rim reads as empty margin around the fight (visible in the picture). It should not be adopted on bot numbers alone; it wants a human playtest. If Ryan's underlying want is genuinely more room rather than more structure, this is the option to prototype.

## Rejected, with numbers

- Bigger board with edge deployment, at any speed (picture: pictures/big_field.png). Contact 12 to 12.5 activations, move-only 19.2 to 24.2%. The dose-response is flat (+0, +1, +2 speed all land at about 12), so the approach round is structural, not a speed problem.
- Bigger board for big battles. Chair follow-up: a crowded battle (7 against 14, belt, strip) on today's canvas gives contact 1 and move-only 27.1%; on the big canvas with edge deployment it gives contact 23 (a full round of 21 ships) and move-only 40.3%. Crowding makes the big board worse, not better. If sector-3 crowding is a concern, it argues for Alternative 2's inward deployment, not for edge deployment.
- A fleet-wide speed rise on today's canvas. Contact is already 1 activation; there is nothing to fix, and the balance tax (torpedoes, ramming, speed-granting admirals and modules) is paid for no measured gain.
- Lanes as a default shape (longest rounds, the only timeout, gate stalls).

## Follow-ups for the Board (named by the legs, not measured here)

1. Defend on hourglass, with the station at the pinch. Qwen proposes it as a defend improvement; DeepSeek warns the pinch could crowd the 19-hex station and its debris band. Both are judgement until simulated: run paired defend battles, hourglass against open, and compare move-only share against today's 16.4%.
2. Shapes on the square and round arenas. Every shape number above is from the strip. If the square arena keeps any weight, its approach should be re-measured with the standard shapes applied.
3. Archipelago at full sector-condition density (storm, nebula and debris stacked on a belt board). The clutter risk behind Alternative 1's caution is unmeasured.

## Leg record and chair notes

- Gates: all four external legs ran on the cloud browser under their model gates, verified before and after (see the header of each leg file). The Flash seat ran signed in as "Quick answers 3.5 Flash-Lite". The blind Rey leg was written from the pack before the external legs ran.
- The legs were unanimous against enlarging the board and against speed rises, and unanimous that shape is the cheap, effective lever. They differ only in how much curation to do at once; the recommendation takes Qwen and Grok's fuller curation, Alternative 1 keeps DeepSeek's smaller step.
- Slips recorded, nothing rests on them: Qwen's leg says first contact "tripled" from 1 to 12 (it rose about twelvefold), names ENC_ARENA as the shape-weight table (ENC_ARENA is the arena table; shape weights live in the genTerrain shape roll), and dates itself 18 Nov (its timezone). Grok's numeric ranges were normalized from en dashes to hyphens when filing, per the repo no-dash rule. Flash's leg names no missing measurement; the other three legs and the blind leg name the same gaps, which became the follow-ups above.
- Pictures were drawn from real generator output (seed 1000, belt, strip deployment) by rendering startBattle boards; blue is the player fleet, red the enemy, brown rock, grey debris, purple nebula. All pictures are under 720 px tall.
