# The Fable program: one finished battle, and playbooks other models can run

Issue 405. FINDINGS R167. Written by the Board (Fable 5.2), Nov 10 2026.

## What Ryan asked for

"I still have another full fable reset, so we can use fable on the really key stuff. Design, graphics, effects, etc. let's do
everything we can to use the fable resets smart here. Playbooks or recipes, deep reviews and redesign, etc. codebase is yours
with my direction and vision, you bring it to life with the decisions needed from me. I want this to end with something that
opus or other models can run from" (Nov 10 2026, 08:42 CST).

His scope answers:
- Focus, in this order of weight: battle effects, ships, space and the board. Screens and sound still get a playbook, lighter.
- End state: "One finished battle + playbooks".
- Steering: "Options first, then build". He sees two or three options, picks one, then it is built.
- Decisions: "As they come". Two lines and one image, whenever a pick is ready.

## The end state

1. **One finished battle.** A single fight that looks and reads final from the first shot to the last wreck, at the camera the
   game is really played at (camera 170 on the look bench). It is the proof that the recipes work and the reference every
   later job is judged against.
2. **A playbook per area**, written from what that battle needed, so another model can do the next ship, effect, hex or
   screen without asking: docs/playbooks/effects.md, ships.md, space.md (not written yet; until it is, the space rules are
   RULEBOOK section 10), screens.md, sound.md.
3. **The front door**: HANDOFF.md section 0 and AGENTS.md point at the playbooks, and the job board holds the remaining items
   as ready jobs written from each playbook's job template.

## The finished battle (what "final" means here)

- **Board**: the dead-star gravity-well board (owner ruling, Oct 24).
- **Fleets**: about six to eight ships a side. **Sunward Crusade against Eclipse** (Ryan, Nov 11 2026, R180; this replaces the
  first plan of the Hullbreakers plus one other). Both have a settled flagship (docs/playbooks/factions.md) and look nothing
  alike. Each fleet needs one capital, one cruiser or destroyer and one escort through the ship recipe.
- **Ships**: built by tools/recipe with real thickness and comprehensive insides (R98, R209, R215), hard points by hull class
  and faction theme (R164 item 4, issue 363), from an accepted concept in the one style (R197) and an Opus build sheet that
  passes the concept standard (R203, R205, R207; docs/playbooks/ships.md).
- **Effects**: every big moment staged to Muse's table (contrib/muse/design/hit_staging_2026_11/synthesis.md): explosions by
  the picked route (issues 353, 365), deaths in three beats (366), one kit of trails, beams and flares (367), effects that
  start on the ship (370), shields that hug the hull with one shield pool, per-side coverage and lossy power routing, resting as Rim and Gap (R246 replaces R163 item 2's four strengths and invisible rest; 371 rules first, then 372 the look; design in contrib/muse/design/shields_2026_11/).
- **Space**: nebula and ion storm hexes with depth (368), a board planet and rocks from real data, remixed past recognition
  (R163 item 3; 369), the black hole and sky calm enough that ships and effects win.
- **Screen**: the battle screen in the ember orders-sheet look, layout E1 Ledger, shield readouts in Glacier #92b8e8 (Ryan,
  Nov 11: "Retire lime", R191; "E1 Ledger" and "Glacier pale blue", R210). Being built: issue 271 step 2.
- **Sound**: scoped (R171: weapons, hits and deaths, buttons and menus, ambience, music; "Clean and tactical"). Routing is in
  (issue 506); sound weight is next (R193 (4)); the redo follows the listening page.
- **Done**: a capture of the whole fight and its look bench sheet, and Ryan says yes.

## How every item flows

1. **Options.** Fable makes two or three options: a bench sheet of real captures where the thing exists, a flat mockup where
   it does not. Cheap, fast, and never more than one sheet per decision.
2. **Pick.** Ryan picks, with one image and two lines in front of him. The pick is recorded in FINDINGS with his words.
3. **Build.** The seat the table below names builds it. One worked example first, never the whole set.
4. **Proof.** The look bench before and after, at camera 170 first (bench a commit twice, keep the second run), plus the
   area's own check. Fable looks at the pictures, not the claim.
5. **Recipe.** What worked is written into the area's playbook the same day: target, steps, check, traps, job template.
6. **Roll out.** The rest of that kind (the other 34 hulls, the other weapons, the other hexes) becomes jobs written from the
   playbook's template, for DeepSeek, Codex or Opus. Fable only reviews their pictures.

Standing rules for every flow (Nov 16 2026, issue 880): the run brief lives in the issue body, one current instruction
(R281); an open issue is not proof of undone work, and a merge closes its issue in the same step when its scope is done
(R288); every picture carries its revision and stage; and visual work is compared with its concept and ruling, with the
misses stated plainly, before it merges (RULEBOOK 2.3 and 2.4).

## Who does what (rewritten Nov 11 2026 evening; the live list is contrib/opus/LOOP.md "The seats")

Ryan, Nov 11, 06:43 CST: "I just used the final fable reset, so let's cool it on fable usage outside of this chat. Opus worker
threads only going forward" (R180). And 15:07 CST: "you own the codebase and github. you are my orchestrator and control the
building" (R202). And 17:45 and 17:48 CST: "I think builds in blender should come from Opus... Codex and deepseek should do
other work to free you up on these crucial items" (R205, R206). So "Fable" in the track tables below reads as the Board
(options sheets, reviews, picks) or an Opus worker (builds).

| Work | Seat |
|---|---|
| Options sheets, art direction, faction sheets, picture reviews, the playbooks, picks put to Ryan, merges | The Board (one Claude thread, Opus 5.5 since Nov 11, R194) |
| Every ship model in Blender (blockouts, build sheets, hulls, kits, the station), hard or visual builds, read-only code audits | Opus 5.5 worker threads, not capped while Ryan's plan clears the backlog (Ryan, Nov 19; R205; RULEBOOK 2.6, LOOP.md duties item 9) |
| Well-specified code: services, checks, tables, wiring, screens and builds to a spec | DeepSeek workhorse on the PC |
| Captures, benches, look-bench runs, scripted pipeline steps that shape no ship, code, image-tool jobs | Codex on the PC, up to six local lanes, one job per lane: GPU jobs on the main lane, Godot UI and lighter captures on lane B, lanes C to F code only, no GPU (RULEBOOK 2.7, issue 2057) |
| Concept pictures by image to image, research, design text, outside checks of Opus-built changes | Muse (Ryan starts every run) |
| Picks, looks, money | Ryan |

No Fable helpers (R180). The Board starts agreed work on its own and asks Ryan only for design, key decisions, reviews of what
he will see, and conflicts (R202).

PC runner starts and restarts (issue 687, Ryan's Nov 14 approval): both runners fetch one shared local bare mirror under
Downloads\voidsworn_test, clone from disk, retry failed clone/fetch steps three times total with two-minute gaps, and make
a tiny call to the selected model before agent work. They merge the issue and arm's -partial branch by default and name it
in the task. Chain jobs through tools/pc/chain_issue.bat and the predecessor run's status.json; only a confirmed non-partial
real push with passing runner checks releases the next job. A failed, partial, unchanged or dry run stops the chain.
The one-page Board note, deployment files and free Windows proof are in tools/pc/work/README.md, "Reliable starts and restarts".

## The tracks, in order

### 1. Battle effects (first)

| Step | Job | Seat | Waits on |
|---|---|---|---|
| Explosion route A or B on one sheet | 353 | Fable helper (running) | nothing |
| Ryan's pick of the route | decision 1 | Ryan | 353 |
| Effects start on the ship: attach point service | 370 | DeepSeek | nothing |
| Rebake every explosion by the picked route | 365 | Codex (GPU) | decision 1 |
| Shield options sheet | DONE: Muse design PR 699 (merged Nov 14); Ryan picked Rim and Gap and one pool (R246) | Muse | nothing |
| Shield model (371, rules and balance first) then surface (372) | DONE: 371 and 372 closed | DeepSeek for 371 (moved from Kimi, no longer a seat, R257); Codex or an Opus worker for 372 | nothing: R246 ruled |
| Trails, beams and flares: options sheet, then one kit | 367 | Fable options, then DeepSeek | decision on the sheet |
| Deaths in three beats to the staging table | 366 | DeepSeek build, Fable review | 365, 370 |
| Every faction readable at the played camera | 362 | Fable helper | the above, last |

Playbook: docs/playbooks/effects.md, started when the explosion route is picked. It holds the staging table's numbers, the
bake route, the bench rows for each moment, and the job template for "one more weapon" and "one more death".

### 2. Ships

| Step | Job | Seat | Waits on |
|---|---|---|---|
| Three-view concept standard, tried on C15s | 398 | Muse | nothing |
| Hard point contract: counts by hull class, break lines by faction theme | 363 | DeepSeek, to a Fable spec | nothing |
| Faction theme sheets: one page per faction (shape language, where guns sit, where it breaks, what it never has) | new | Fable (Board) | nothing |
| Ryan's pick of the second fleet for the finished battle | decision 2 | Ryan | the theme sheets |
| Concepts in three views for the finished battle's hulls | 276 | Muse's image models, Fable art direction | 398, decision 2 |
| Build sheets, then hulls through the recipe | tools/recipe, docs/playbooks/ships.md | Opus workers (R205); Codex for captures | an accepted concept (R203) |
| Blob sweep of each hull, as pictures | docs/ship_pipeline/BLOB_SWEEP.md | Fable reviews, Ryan's eye | each hull |
| The station as a built set piece | 373 | Opus worker (R205) | its build sheet from concept T2 (R206) |

Playbook: docs/playbooks/ships.md. It starts from tools/recipe and PR 401, adds the concept standard, the hard point
contract and the theme sheets, and ends with the job template for "the next hull". The ship queue (36 hulls) is rolled out
from it by Opus workers (every Blender step, R205), with Codex on captures and the Board reviewing sweeps.

### 3. Space and the board

| Step | Job | Seat | Waits on |
|---|---|---|---|
| Sky and backdrop strength: one sheet at half, as now, and near black, with ships and effects in frame | new | Fable (Board), from bench captures | nothing |
| Nebula and ion storm hexes with depth: two routes measured against the frame gate | 368 | Fable helper, PC | the sheet |
| Planet and rocks from real data, remixed: three options | 369 | Fable options, Codex build | nothing |
| Environment reconciliation and nebula motion | 230 | DeepSeek, to the picked look | 368 |

Playbook: docs/playbooks/space.md, not written yet; until it is, the space rules are RULEBOOK section 10. It is to hold the
frame gate numbers, the data sources and the remix rules ("Shouldn't be obvious planets we know").

### 4. Screens (lighter)

The campaign map and its rail are built (R165, R176, R177); docs/playbooks/screens.md is written from them. Lime is retired
(R191): every screen takes the ember orders-sheet look as it is next built. The battle HUD question is settled: E1 Ledger
(R210), built in issue 271 step 2. Then debrief and the other screens, from screens.md's template.

### 5. Sound (lighter)

Ryan: "The sounds that I've heard from the game so far are bad" (R163). Scoped (R171) and written up in
docs/playbooks/sound.md; routing done (issue 506); sound weight, the listening page and the redo follow.

## The playbook format (every playbook, same headings)

1. **Target**: the pictures to match and Ryan's own words about them.
2. **Inputs**: what must exist before you start.
3. **Steps**: numbered, with the exact job files and commands.
4. **The check that proves it**: bench rows, cameras, numbers, and what a pass looks like.
5. **Traps**: what went wrong before, each with its FINDINGS row.
6. **Worked example**: the pull requests that did it once.
7. **Job template**: the issue block to copy for the next item of this kind.
8. **Seat**: who runs it, and when to hand a picture back to the Board.

A playbook is done when a model that has never seen this repo ships the next item from it and the Board changes nothing.

## Pick Sheets (Ryan, Nov 22 2026; RULEBOOK 1.8, R408)

Ryan's non-urgent product and visual calls wait for one of two sheets a day. The Board compiles each one in its own
thread and the coordinator carries it to the project chat with the pictures attached.

- **When.** Morning sheet by 8 AM Central, Evening sheet by 6 PM Central. An empty sheet is not sent.
- **What goes on it.** Picks that change what Ryan sees, hears or plays, money, and anything only he can approve. Never
  status, never a technical choice the Board can make itself (RULEBOOK 2.1).
- **Outside the sheets** the Board interrupts him only for: PC disk under 75 GB, a key to paste, or a stuck job to kill.
- **Format.** A title line, then numbered items. Each item is one question in plain words, two to four lettered options
  with what each means for what he will see, the Board's pick and why in one line, and one current picture with its code
  name on it (no taller than 720 px). A yes or no item says so. He answers on one line, `1=B, 2=Yes, 3=skip`; a skipped
  or unanswered item rolls to the next sheet once, then the Board decides it with its pick and says so.

```
Evening Pick Sheet, Nov 22 (3 picks)

1. Hit sparks on Glasswright glass: which look? (picture: GH2_sheet)
   A. White glints only   B. White glints plus a short blue crack   C. Keep today's
   Pick: B, it reads as glass at battle distance.
2. Run the ElevenLabs sound pilot tonight (about 2,200 credits)? Yes or No.
   Pick: Yes, it is the last step before you can hear the new sounds.
3. ...

Answer like: 1=B, 2=Yes
```

## Budget and pacing (rewritten Nov 11 2026 evening)

- Ryan's Fable resets are all used (R180). The Board and Opus workers draw the Claude plan: Opus workers are not capped while
  Ryan's plan clears the backlog (Ryan, Nov 19; LOOP.md duties item 9); the earlier cap of two followed the five-hour limit
  hit on Nov 11 with three.
- Codex gives about 100 minutes of work per five-hour window; one Codex job per lane; GPU work sized to the job (RULEBOOK 3.4, R293).
- If a limit is hit, nothing stops: DeepSeek, Muse and Codex keep running the rows that are theirs, and the Board's picks wait
  in LOOP.md.

## Decisions: made, and still owed (Nov 11 2026 evening)

Made (his words are in FINDINGS):
1. Explosions: route B with flash plus hot core (R170). "Explosions are looking much better" (R180).
2. The finished battle's fleets: Sunward against Eclipse (R180).
3. The campaign map: the Briefing layout over the real 3D scene, the approach to the star, routes only, fight stops show the
   enemy, regions as scenery (R165, R170, R174, R181). Rocks turn slowly by default (R212: "Nah, I like the rotation of
   asteroids").
4. The interface look: the ember orders sheet everywhere, lime retired (R176, R177, R191). Battle screen E1 Ledger, Glacier
   for shield readouts only, 3D shields keep faction colours (R210).
5. Sound scope (R171); the cinematic audit and its build order: flash counter, hits, movement, sound, kill moment (R193).
6. Movement: smooth, never sudden, feels like space (R189); the main engine does the travelling (R195).
7. Deaths: blown apart, never sliced (R186); flame only for the 0.70 s cap; kill moment held and slowed (R193); hits pushed
   harder, torpedo 140 px (R208).
8. Concepts: one style (R197); accepted build references A16, A17, C10, C11, E11, E12 and the station T2 (R201, R204, R206);
   Sunward (S8 shape), Hegemony (H10 shape) and Glasswrights (G15 shape) go through the Opus build-sheet route (R204, R206).
9. Builds: build sheet first (R203), the concept guides (R207, R213), Opus builds in Blender (R205), insides comprehensive
   (R209, R215), the method binding in the working documents (R214).

Owed, in the order they will arrive:
1. Hullbreaker build sheets round 2 (A16, A17; issue 532), then the other accepted ships' sheets and Sunward, Hegemony and
   Glasswright sheets by the shape-locked route.
2. The battle screen built in E1 Ledger (issue 271 step 2), shown before it merges.
3. Hits pass 2 (issue 538); small-ship deaths (463); sound weight (507).
4. The rulebook's batches of Ryan's own old calls (issue 492).
5. Shield look (from a shield options sheet). 6. Backdrop strength for battles (sky sheet). 7. Planet. 8. Trails, beams and
   flares. 9. The sound listening page. 10. The Sunward and Eclipse fleet sheets.
