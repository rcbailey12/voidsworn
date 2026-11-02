# Muse brief: four jobs while the feel pass finishes (Nov 1, 2026, late)

From Opus, for Rey (Muse). Run each with your usual model mix, one synthesis per job, commit to the folder named. Ryan's rulings (contrib/opus/FINDINGS.md R59 to R73) override every other doc. Plain words, no em dashes. Work from the code on main; check every claim against it and cite file:line.

## Job 3: balance proposals from the full-run simulator
Folder: contrib/muse/research/balance_2026_11/
The new runner contrib/opus/tools/run_montecarlo.js (or RUN_MONTECARLO.bat) plays Muse's campaign driver on today's rules. Its first 300 runs: bot full-run wins 61% overall, Sunward Crusade 34%, Hegemony 54%, Hullbreakers 62%, Glasswrights 64%, Eclipse 72%, Chorus 80% (see the commit message of c54be4a). Other measures: the sector 1 boss sim puts Grax at 49% (floor 50%) and the Crusade fmatrix row at 47.5% after the veteran brace fix (docs/shots/r1 READMEs, port_notes step 13 and 14). Ryan's rulings: a high run-loss rate is expected and winning run 1 should be near impossible (R62); every core is equal; Eclipse stronger but dearer, Chorus the opposite (R63).
Deliver: why each faction lands where it does (cite the data and code), then a ranked list of small data.js changes (numbers only, no new systems) that would close the spread to roughly 10 points while keeping the overall rate low for a human first run, each with the sim result if you can run the runner (node is enough; say if you cannot). Mark which changes need Ryan's call.

## Job 4: the first battles should teach themselves
Folder: contrib/muse/design/onboarding_2026_11/
Ryan's first Godot playtest (R65): "It wasn't always clear what was my next move or what ship I should be moving or what to do when I was done shooting. Or even when I got a reinforcement ship." The new turn flow (docs/shots/f1/0354234/README.md) fixes much of that. Design how sector 1's first two or three battles teach the game without a wall of text: which prompts appear when, in what order, how they fade once learned, what the first map and enemy should be (no dead star in sector 1, R1 step 13), and how Ryan can switch tips off. Use the existing tip system (battle_opts.json "tips" keys in the Godot save) and the tutorial pack's useful parts minus its known problems (contrib/opus/compute/content_lint_2026_11_01.md). Output a step list a coder can build, with the exact text of every prompt.

## Job 5: sound for the moments that matter
Folder: contrib/muse/research/audio_2026_11/
contrib/opus/compute/coverage_gaps_verified.md confirms gaps in battle cues (boarding, brace, Nemesis adaptation) and questions the Hullbreaker faction track. The game uses free licensed sound only (godot/music/CREDITS.md, godot/audio/cues.json, sfx.gd). Deliver: a cue list for every battle moment the feel pass added or changed (hand-over to the next ship, plan confirm, fire, hit by weight, shield ripple, staged capital death with the slow-motion beat for big ships, small-ship death, reinforcement arrival, enemy turn start), each with what it should sound like and two or three specific free sources (CC0 or CC BY, with licence links), plus a short mixing note. No downloads; Opus routes them.

## Job 6: the campaign map, Sins of a Solar Empire 2 style
Folder: contrib/muse/research/campaign_map_2026_11/
Ryan wants the campaign map upgraded to a high-quality Sins of a Solar Empire 2 style 3D star-system look (FINDINGS R51). The battle backdrops now have planets, moons, rings, nebulae and asteroid fields (docs/shots/f4/2514693/README.md, godot/world/). Research how Sins 2, Stellaris, Homeworld and Endless Space 2 present their strategic maps (camera, scale, icons over 3D, route lines, fog, how they show danger and rewards), then propose a design for our three-sector run map that reuses the battle world assets, with a mock layout described per sector and the order to build it in. Cite primary sources where possible.

When each job is done, list the files and the three things Ryan should look at first.
