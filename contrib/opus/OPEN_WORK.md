# Open work ledger (FINDINGS R194)

Kept by the Board. One row for every open issue and every parked pull request. Read at every board check. Rows were written after reading each issue, its comments and the state of every issue it waits on (Nov 11 2026, 21:10 UTC, first Opus 5.5 Board thread; updated 21:50 UTC after Ryan's picks, R201 and R202). Ryan: "The station is a good example of something we already aligned on but is still sitting there. I don't want to lose prior work because of everything else going on."

Verdicts: START NOW (agreed, nothing real in the way); WAITING ON (the named thing, checked true today); FOLD INTO (another issue); CLOSE (done or superseded, by what); STANDING (stays open on purpose).

Counts today: 44 open issues, 4 open pull requests. Most rows in the first table still carry a "blocked" label whose reason has lapsed; the Board removes the label when each job is launched.

## Running now (21:50 UTC Nov 11)

| # | Seat | What |
|---|---|---|
| 461 | Opus worker | Hits (brief rewritten: absorbs 507 build 2 and its four carried items) |
| 521 | Opus worker | Kill moment held with slow motion, and the main engine for long moves (R195); new issue from 507 |
| 363 | DeepSeek workhorse | Hard point contract |
| 520 | Codex | Finish PR 286 with its PC motion capture and R191's rock-cap wording; new issue |
| 517, 522, 523 | Muse (Ryan starts, in this order) | Round 8b; round 8c (S10, E11, E12, G18: Ryan passed only A16 and A17, R201); the station concept (feeds 373) |
| 256 | Muse | Outside checks of PRs 513, 512, 491, 474 (after the three above) |

Closed with Ryan's yes (R201): 365, 366, 193, 194, PRs 291 and 301. The rows below for those are history.

## Agreed and waiting: blocker lapsed, start now (in the Board's order)

| # | What | Ryan's calls | Built so far | Was waiting on (now) | Next step |
|---|---|---|---|---|---|
| 507 + 461 | Hits: one recipe per weapon family, sized by the gun, wounds that cool and stay, light on neighbours, thrown matter with its own lives | R193 ("flame only": the 0.70 s cap is for flame; sparks, debris, gas, embers live longer), R170, R171 | explosions rebaked (426), flash counter merged (504, limit 15,606 px2) | issue 504 (MERGED) | 461 is the hit ladder and 507 build 2 is the same job: rewrite 461 to R193 and the new flash limit, fold in 507's comments (round core-flash ring, lance cuts, dim bow piece, engine flicker 0.85 to 0.95), launch one Opus worker |
| 507 | Kill moment: the kill camera holds through the core flash, slow motion on cruiser and up | R193 ("Hold and slow"), replaces R123 | death_slowmo exists, never called | issue 505, battle.gd (MERGED) | file and launch with the movement follow-up below (same files) |
| 507 | Movement follow-up: long runs flown nose first on the main engine; a thruster slide is for one hex | R195 ("for one tile over, it tracks but not when they're going like 3-10 tiles down"), R189 | movement build merged (505) | nothing | one Opus worker with the kill moment; also carry 505's notes (cruiser 2.9 s to reach speed, small frigate jets, enemy turn 5.3 to 6.5 s, the Godot shutdown crash at battle.gd _overlay) |
| 463 | Small-ship deaths (frigate, destroyer, wings) | R186 (blown apart, not sliced), R170 | cruiser and capital deaths (462), wrecks (484) | 366b, issue 462 (MERGED); Codex parked (UN-PARKED R170) | Codex, after the hits job lands (both edit godot/fx); rewrite to R186 and R193 first |
| 363 | Hard point contract: breach anchors by class and faction, not six on every hull | R164 ("It should vary by size of ship, faction, etc.") | full spec in the Nov 11 comment | issues 374 and 385 (BOTH CLOSED) | DeepSeek workhorse now |
| 373 | The station as one built set piece through the ship recipe | R109 ("it looks super plain"), R194 (the example of agreed work left sitting) | brief only | issue 209 recipe (PROVEN, PR 401); 363 (still open) | needs a concept picture in the R197 style first (R192: edit a liked picture); 363 runs in parallel; then an Opus worker builds it. Ryan's pick asked |
| 230 / PR 286 | Environment reconciliation and nebula motion spec | R139, R191 (rock cap is a tuning value) | draft PR 286 (Nov 9) | the PC motion capture and Muse's outside check, never run | bring main in, swap the asserts it keeps to R191's wording, run the PC capture (Codex job), outside check, merge. Unblocks 368 and 100 |
| 357 | Three known traps removed in code (line endings, closing words, Node version, .import restore) | none needed (Board-written) | nothing | nothing | DeepSeek workhorse after 363 |
| 377 | Runner 2: a failed run opens no PR, refuse list, safe push | none needed | nothing | 356 (CLOSED) and 357 (open) | after 357 |
| 376 | Late shader log | none needed | nothing | 351 bench (CLOSED) | workhorse filler, one short PC trace |
| 369 | Board planet and rocks from real data | R163 ("really remix. Shouldn't be obvious planets we know") | nothing | 351 (CLOSED); Ryan's route word (GIVEN, R163) | option sheet owed to Ryan first (HANDOFF section 0); a worker slot |
| 305 | Admiral tree skills work in battle | R145 (his answers to the five questions) | jobs 7a and 7b merged; 7 rows wait | the plan (DONE) | file one Opus job: choice prompts for the "may" rows and the kill-then-retarget hook, with the Godot screen. Label "blocked" is stale |
| 41, 42, 43, 44 | Run 3 to 5 story content (captured hulls, Chorus core eating, Eclipse portraits, finale sun) | R78 Q9, Q15, Q17, Q18 | nothing | progression steps (ALL 14 CLOSED) | rewrite each brief to current rules (43 is art: follow R197's realism), then workhorse or Codex one at a time. Lowest priority of the agreed items |
| 92 | Debrief screen to the Muse design | R85 Q3; R191 (every screen moves to the ember look when next built) | data and a working panel (#91) | #24 and #122 (BOTH CLOSED) | WAITS ON the battle screen's ember look being accepted (R191 order: map, then battle screen, then the rest); brief rewritten to ember |
| 362 | Battle camera readability: every faction readable at true size | none needed | nothing | 351 bench (CLOSED) | an Opus worker slot after hits; GPU window |
| 221 | Scene gate binder: trim per-ship per-frame work | R115, R116 | profile numbers in bench207 | nothing | an Opus worker slot; becomes urgent before 20-ship fights get richer |
| 238 | Reporting scripts (station timing, star count, log soak, sound defer, danger bands, pace per round) | none needed | nothing | #227 (CLOSED) | workhorse filler; reports only |
| 234 | Destruction probe and ram Monte Carlo | none needed | nothing | #227 (CLOSED) | rewrite against the new wreck code (484), then workhorse filler |

## Owed to Ryan (he waits on the Board for these)

| # | What | State |
|---|---|---|
| 515 | Round 8 concepts, six ships | DELIVERED on muse/issue-515 (20:36 UTC). The Board's read is in LOOP.md. Named pictures to Ryan, he judges the style |
| 271 | The battle screen in the ember orders-sheet look, as a picture first | PR 314 built Lime Tactical (merged Nov 9); R191 retired lime. Rewrite 271 as the ember battle screen, picture first, and the one shield colour (R191) |
| 371, 372 | Shields: model, then surface look | Ryan picked the resting look (R163: invisible at rest, faint edge glow, down side a dark gap). Still owed: the options sheet for how a shield answers a hit (audit item 3). 371 waits on 363 (contract); 372 waits on 371 |
| 507 | Sound weight and the listening page | file after hits; the listening page comes first (docs/playbooks/sound.md) |
| 368 | Nebula and storm hexes: two routes measured, Ryan picks | waits on PR 286; 351 is CLOSED |
| 369 | Planet option sheet | see above |
| 276 | Fleet sheets, Sunward and Eclipse first | waits on Ryan accepting their round 8 pictures. Rewrite 276 as the fleet-sheet job (it was the concept redo, now done by rounds 1 to 8) |
| 492 | His own old calls, in short batches | the rulebook job (below) |

## Waiting on, and still true

| # | What | Waits on |
|---|---|---|
| 517 | Round 8b: Hegemony H12, Chorus C10 and C11 | round 8 delivered (TRUE NOW): Ryan starts Muse |
| 370 | Attach point service in the game | 363 (the contract). The recipe ship (PR 401) and the bench are in |
| 367 | One kit of trails, beams and flares (audit item 12) | the hits job (same files); 365's left-over muzzle gas folds in here |
| 100 | Terrain effects 2 | PR 286 and the 368 route pick; its brief (Nov 3) predates 368, 369 and R191: rewrite before it runs |
| 209 | The ship recipe's home | stays open until the next ship runs through the recipe; carries "twin bow guns move back onto the hood" for the C15s cruiser's next bake |
| 250 | Glasswright species concept sheet (people, not ships) | after the ship concepts settle; scope questions to Ryan first (its own brief) |
| 211 | Generated Foley probe (Ryan: "US only is fine") | the sound listening page (507 sound weight) |

## Fold into, or close

| # | Verdict |
|---|---|
| 365 | CLOSE: done by issue 426 (PR 455) for every hit and death flash; the muzzle gas it left moves to 367 |
| 366 | CLOSE: done by 462 (three beats) and 484 (wrecks); wounds and light on neighbours are in 461, small ships in 463 |
| PR 291, PR 301 | CLOSE: Lime-era battle screen mockups; the build merged as PR 314 and R191 retired lime. Kept readable |
| 194 | CLOSE (Board's call): five pipeline ideas from Nov 5, overtaken by the proven recipe (209, PR 401) and the concept style (R197) |
| 193 | ASK RYAN: his Nov 4 request for a Tripo high-poly test. The recipe route is proven; the Board would close it |
| 216 | FOLD INTO 492: stale state documents (NEXT.md, PROGRESS.md, BACKLOG.md still at the root) and doubled rulings are exactly the rulebook's archive step |

## Standing and umbrella

| # | Why open |
|---|---|
| 492 | The rulebook and the issue-board clean-up. The Board's own first job, run in the Board thread |
| 405 | The program umbrella: one finished battle (Sunward against Eclipse) plus a playbook per area. Its Models line names Fable: reword in 492 |
| 256 | Muse's standing outside check of Opus-built work. Owed now: PRs 474 (death beats), 491 (wrecks), 512 (flash counter), 513 (movement). Ryan starts Muse |
| PR 518 | HANDOFF.md fix (round 8 is six ships in 515, three in 517). Diff checked; merge when GitHub's checks run (stalled for the whole repo since 20:34 UTC) |
