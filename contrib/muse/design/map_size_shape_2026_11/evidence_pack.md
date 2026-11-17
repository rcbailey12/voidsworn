# Evidence pack: map size and shape (Voidsworn issue 1004)

## The question

Ryan (Nov 17, 2026, after the 19-hex station made the defend map harder): he wants maps that feel cohesive and space-like, without so much room that it takes ages to do anything. He floated a bigger map with faster ships, or different shapes and designs, especially once storms, nebulas and asteroids are all in play. This is a direction to explore, not a decision. The deliverable is one recommended direction and at most two alternatives for map size, shape and layout, each with measured numbers and a top-down picture.

## How maps work today (code at main db4885e1, read Nov 17)

- One canvas, 30 wide by 22 tall hexes (battle.js: `const BW=30, BH=22`). Each battle cuts an arena out of it:
  - strip: margins top 3, bottom 3, left 1, right 1 (about 361 playable hexes). Fleets deploy in lines at the left and right edges, facing each other.
  - square: margins 0/0/4/4. Fleets deploy by angle around the centre (approaches: diagonal or cross).
  - round: a ragged circle of radius 11. Approaches: head-on, cross, or pincer.
- Which arena a battle gets is weighted by encounter (battle.js ENC_ARENA): a rout is strip 30%, square 35%, round 35%. Hold is round/square only. So most standard battles do NOT play on the strip.
- Terrain themes (map kinds) rolled per battle: belt (a diagonal asteroid band with gaps, plus nebula blobs), station (a station at the centre with a debris ring), planet (a planet disc intruding from one edge), storm (storm and nebula blobs), graveyard (hulks with debris). Sector conditions add more storm, nebula or debris blobs on top.
- Board shapes that reshape the playable area: open, corridor (top and bottom cut away, a wide shallow field), lanes (a rock wall across the middle with two gaps), ring, dense, compact, deadstar (a hole in the middle), rift, shoals, hourglass (pinched middle, two lobes), archipelago (rock islands in clusters), colossus.
- Deployment on the strip: player ships start in columns 5 to 7, enemy in columns 22 to 24 (of 30), so the fleets open about 16 hexes apart. On square and round arenas, deployment is by angle at about 0.68 to 0.74 of the field radius from the centre.
- Ship speed (data.js hull `sp`, hexes per turn): ranges 1 to 7, most hulls 3 to 5. Movement points each round equal speed. Weapon ranges are fixed per weapon; the longest guns reach roughly a third of the board width.
- The big station (FINDINGS R314, ruled Nov 17): on station maps the station blocks every hex within 2 of its centre, 19 hexes, in both rule copies, and the defend objective, station guns and debris band are measured from its edge. This ruling stands whatever this study recommends.

## Method (all numbers below)

- The game's own simulator (sim3d.js) at main db4885e1, battles played bot against bot with alternating activations, the way the game plays by default.
- Mirror fleets, 6 against 6, same Hegemony list both sides (Vanguard, 2 Interdictors, 2 Pickets, Dominion), sector 2, so the only differences between runs are the map settings.
- Paired seeds 1000 to 1023 (24 battles per configuration); the same seed set is used for every configuration, so comparisons are paired.
- Metrics:
  - Turns to first contact: capital-ship activations completed before the first shot of the battle (0 means a ship fires on the very first activation; 12 means a full round of 6 against 6 passes first). Reported as the median.
  - Mean battle rounds: rounds until one side wins, capped at 30.
  - Move-only share: the share of capital-ship activations in which the ship moved and never fired a weapon.
- Limits: bots, not humans; one fleet pairing at one sector size; the player bot and the enemy AI are different pilots, so win rates are not a design signal and are not used below. Human players will manoeuvre more deliberately, which would raise the move-only share everywhere, but the comparisons between options are paired and should hold in direction.

## Baseline: today, by map kind (strip arena, shape open, 24 battles each)

| Map kind | First contact (median activations) | Mean rounds | Move-only share |
|---|---|---|---|
| belt | 1 | 10.7 | 15.4% |
| station | 2 | 9.8 | 14.0% |
| planet | 1 | 9.7 | 9.3% |
| storm | 1 | 9.6 | 9.9% |
| graveyard | 0.5 | 10.0 | 10.0% |

Same fleets on the other arenas (belt): square arena, first contact median 9 activations, 10.4 rounds, move-only 11.9%. Round arena: first contact median 0, 10.1 rounds, move-only 10.3%.

Defend on the station map (strip, mirror fleets): battles end at the 6-round objective clock, first contact median 1, move-only share 16.4%, the highest of anything measured. The attacker spends a large share of its turns crossing to the 19-hex station and its debris band.

Reading of the baseline: on the strip, contact is nearly instant (a ship moves once and is in range of something), because the opening gap of about 16 hexes is roughly one move plus one long gun. The slow-feeling parts of today's game are concentrated: (1) square-arena approaches, where a full round of closing can pass before contact (median 9 activations); (2) defend, where the move-only share is highest; (3) the roughly 1 in 8 activations everywhere that are spent only moving, mostly slower ships repositioning after contact.

## Options tested (belt, station and storm pooled, 72 paired battles each, strip arena)

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

Notes on the size test: on the bigger canvas the fleets deploy at the edges as today, so the opening gap grows from about 16 to about 24 hexes. First contact then waits for a full round of activations (median 12) at every speed tested: +1 and +2 speed barely move contact at all, and the extra speed mostly turns into repositioning (move-only stays 19 to 24%, against 13.1% today). Rounds do not shorten except at +2, which only matches today's length. Nothing in the size test made a battle faster or snappier; it made every battle start with a round of pure approach.

Notes on the shapes (all on today's canvas): pace is a wash against open (contact 1, move-only 12.6 to 14.9%, rounds 10.3 to 11.5). What changes is texture, not tempo:
- Corridor: the shallowest field (267 hexes). Head-on fights, little vertical room to flank, fights develop fast across the whole front.
- Hourglass: two open lobes joined by a pinched middle. A fleet can contest the pinch or swing wide in its own lobe; the pinch is a natural chokepoint for the station and planet maps too.
- Lanes: a rock wall across the middle with two gaps. The longest battles measured (11.5 rounds, one 30-round timeout in 72): the gaps are gates that fleets fight over; crossing late means fighting through a defended gap.
- Archipelago: rock islands scattered in clusters with open channels. The most repositioning of the shapes (move-only 14.9%): cover is plentiful and fights break into local duels around islands.

## Pictures (drawn from the real generator output, seed 1000, belt map, strip deployment)

- today_open.png: today's board. The belt's asteroid band runs diagonally between the fleets; both fleets deploy in line at the edges.
- big_field.png: the 38 by 26 canvas. Same generator, visibly emptier; the fleets sit much farther apart with open space above and below the band.
- corridor.png: the shallow corridor field.
- hourglass.png: two lobes and the pinched middle.
- lanes.png: the rock wall and its two gaps.
- archipelago.png: clustered rock islands and channels.

Blue dots are the player fleet, red dots the enemy fleet. Brown is rock, grey is debris, purple is nebula.

## Build cost sketch (for judging, not a plan)

- Changing canvas size touches both rule copies (browser and Godot), the deployment code, the arena cuts, the parity scenarios that assume today's board, and every balance sim tuned on today's sizes. It is the most expensive knob measured and the only one that made pace worse.
- Shapes already exist in both copies (genTerrain in battle.js and its Godot twin); changing which shapes roll for which encounters, or their weights, is a small change by comparison. New shapes cost one generator branch in each copy plus parity scenarios.
- Speed is a data.js number per hull and flows into the Godot tables by export; a fleet-wide speed change is cheap to make and expensive to balance (it interacts with turn counts, torpedo speeds, ramming and every admiral and module that grants speed).
- Deployment geometry (where fleets start, arena approach weights) is battle-start code in both copies; moving deployment inward on a bigger board is possible but was NOT measured here.

## What your leg must do

Recommend ONE direction for map size, shape and layout, and name at most two alternatives. Ground every claim in the numbers above or say plainly that it is judgement. Cover: pace (first contact and move-only share), room to manoeuvre and flank, whether the field feels cohesive and space-like rather than empty or cluttered, how the direction behaves once storm, nebula and asteroid terrain are all in play together, the defend and station case, and build cost. If you think a hybrid beats every single option above, propose it and say what it borrows from each. If you think any number in this pack is wrong or a needed measurement is missing, say so by name.

Write in plain language. Use only plain hyphens, never em dashes or en dashes (the repo forbids them in filed documents).
