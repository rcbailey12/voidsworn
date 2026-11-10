# Known-failure list, sorted (issue 355, Board, Nov 10 2026)

The checks table prints "findings_tests PASS" over 47 failing tests because their ids sit on a list of accepted failures recorded Nov 1 (outside audit pass 1, finding 4). The outside check asked for the list to be sorted before any rule makes it shrink (FINDINGS R160). This is that sort. Nothing is repaired here.

Measured at main 8326e78 with `node contrib/muse/tools/findings_tests/findings_tests.js`: 80 tests, 33 pass, 47 fail. The list had 50 ids; 3 pass today (ADM-5, ADM-6, EVT-3) and leave the list.

| Tag | Count | What happens next |
|---|---:|---|
| bug | 13 | four repair jobs, grouped by the files they touch: issues 384 (Nemesis rules), 385 (campaign and rewards), 386 (battlefield generation), 387 (wing selection in the Godot battle screen). Filed blocked; released one at a time behind the tree lane |
| ruled-not-built | 3 | stay listed; each is built when its ruling's job comes up |
| stale | 5 | the test no longer matches the game as ruled; named for removal from the gate in issue 358 |
| opinion | 26 | the test asserts Muse's own proposal (balance, roster, AI quality); named for removal from the gate in issue 358; kept as a reading list for the balance pass |

How sure: each tag was judged from the test's own failure output. For UI-5, UI-8, KIT-3, MOD-2, NEM-4 and ADM-2 the Board also opened the code. The Board did NOT read every function behind the 13 bugs, so each repair job starts by confirming the defect against the code and the rulings, and may send one back as intended with its reason. Where a call was close the Board tagged bug, not opinion, because an opinion tag takes a test out of the gate for good. A Muse second read is welcome (the suite is Muse work).

ADM-2, explained: it passed at the audit pin da01a7a and fails now with no signal. Cause: Vorn's Command became Interdiction strike by ruling R145, so his Command text no longer promises the torpedo reload the other three hunt admirals do. The test predates the ruling. Tag: stale. The silent flip itself is what issue 358 repairs (a listed id that changes state must show).

## bug (13)

| Id | Why | Job |
|---|---|---|
| BF-1 | ambush deployment clears most of the rock that defines the ring and lanes shapes | issue 386 |
| BF-8 | enemy reinforcements spawn on the wrong side of round arenas | issue 386 |
| ECO-4 | prize ransom skips the shop price multiplier | issue 385 |
| EVT-1 | the defector flag records presence, not the option that wrote it | issue 385 |
| MOD-2 | cogitator is a key in both MODULES and RELICS (the collision half; the duplicate-perk half is opinion) | issue 385 |
| NEM-3 | two adaptations granted in one sector visit; the cap compares a cumulative budget | issue 384 |
| NEM-4 | nemStrike does nothing for four factions; only raid and tithe are built | issue 384 |
| NEM-5 | the raid warning and the strike disagree on what can be taken | issue 384 |
| NEM-6 | a no-retreat Nemesis flagship kill in sectors 1 and 2 never registers and the debrief says he escapes | issue 384 |
| PP-2 | a pure-hive fleet counts as zero carriers for the point-defence adaptation | issue 384 |
| PROG-6 | newRun launches an unowned admiral; only the screen checks ownership | issue 385 |
| RWD-2 | six core protocols ignore the rarity multiplier and two cap at Rare | issue 385 |
| UI-5 | a selected wing stays armed after cancel; the test reads the frozen browser screen, the Godot screen has the same field and is checked in the job | issue 387 |

## ruled-not-built (3)

| Id | Why | Job |
|---|---|---|
| KIT-1 | the approved Chorus shipyard repair prohibition is coded nowhere |  |
| KIT-3 | Eclipse still carries the banned green tomb styling in data.js; colours are settled with the concept redo (issue 276) |  |
| ROS-9 | ruled: spread focus, ionpulse and frenzy beyond one hull |  |

## stale (5)

| Id | Why | Job |
|---|---|---|
| ADM-2 | Vorn's Command became Interdiction strike by ruling R145 (Hegemony has no torpedoes), so its text rightly drops the torpedo reload; the test predates the ruling, which is why it flipped from pass to fail with no signal |  |
| AI-1 | the test can no longer build its scenario (the ship fires on the move, after which brace is not legal) |  |
| BF-3 | browser terrain colours; the Godot game draws terrain as models |  |
| DRIFT-5 | touch wording in the frozen browser screen; the game is PC only (owner ruling, Oct 24) |  |
| UI-7 | the browser help line; the Godot battle screen was rebuilt (PR 314) |  |

## opinion (26)

| Id | Why | Job |
|---|---|---|
| ADM-1 | duplicate admiral passives are a design proposal; the trees now set admirals apart |  |
| AI-3 | AI quality proposal: death-cliff weight by ship value |  |
| AI-4 | AI quality proposal: a ship with only a reloading torpedo should kite |  |
| AI-5 | AI quality proposal: wing launch should weigh the launch hex threat |  |
| BF-10 | rout lists archipelago twice, which doubles its weight; may be intended, a data tidy at most |  |
| BF-2 | boss boards delete 45 percent of rock on purpose (code in startBattle); changing it is a design call |  |
| BF-6 | hold never rolls a strip arena: a design proposal |  |
| BF-7 | the lanes barrier runs along the advance: that is what makes lanes; a design proposal |  |
| BF-9 | debris against nebula numbers: balance |  |
| BN-1 | three ram protocols share one job: design |  |
| BN-2 | legendary explosion against the epic: balance |  |
| BN-5 | the hunger patron sits in one duo: content proposal |  |
| ECO-2 | brood carrier price: balance |  |
| ECO-3 | decommission pays by template, not hull condition: economy design |  |
| KIT-2 | ionpulse does nothing against two shieldless factions: balance and roster design |  |
| KIT-4 | lance in the name of a battery-kind weapon: naming |  |
| MOD-4 | damcon against prow on price: balance |  |
| ROS-4 | the Eclipse boss as a rescaled harvester: roster design, goes with the concept redo |  |
| ROS-5 | three variants with no trade: balance |  |
| ROS-6 | warden and picket nearly the same ship: roster design |  |
| RWD-5 | credit node against declining a boon: balance arithmetic |  |
| RWD-7 | four modules never drop as salvage (they are sold in the shop): content proposal |  |
| SQ-1 | spore wing close to the bomber: roster design |  |
| UI-8 | auto-facing ignores shield strength on a tie: a quality proposal for the facing helper (also present in the Godot screen) |  |
| WPN-2 | turbo and gauss share a damage line: weapon design |  |
| WPN-5 | a Rear arc name no weapon uses and an overwritten evMult: dead data, harmless |  |

## For issue 358 (the checks table)

Take out of the gate: the 26 opinion ids and the 5 stale ids above. Keep in the gate as KNOWN, with a list that can only shrink: the 13 bug ids and the 3 ruled-not-built ids.
